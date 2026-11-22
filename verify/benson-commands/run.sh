#!/bin/bash
# Проверка бэкенда команд БЕНСОНА по NASA TM-76182.
# Это аналог NASA для БЕНСОН-501, а не протокол НИТИ/БЭСМ-6.
# Дека verify/C1-line.b6 прогоняется дважды, сравниваются SHA plot.dat,
# benson.out и benson.svg. ctest намеренно не вызывается: его запускает lead.
# Переменные: DISPAK_BIN, NITI_2348, TMPDIR, KEEP_WORK, REF2148, TIMEOUT, VERBOSE.
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)

DISPAK=${DISPAK_BIN:-/home/azizz/Yandex.Disk/dispak/build/dispak/dispak}
DISKDIR=$(dirname "$DISPAK")
REF2148=${REF2148:-/usr/local/share/besm6/2148}
NITI_2348=${NITI_2348:-$HOME/.besm6/2348}
TMP_BASE=${TMPDIR:-/tmp/.private/azizz/opencode}
TIMEOUT=${TIMEOUT:-240}
DECK=$ROOT/verify/C1-line.b6

EXP_SUMMARY='NITI: summary schemes=2 frames=2 words=128 active=1 scheme=1210'
# Новый формат кадра (Fortran /PDEVXY/ -> PDEV -> ЭК 1210/1211):
# word0=X, word1=Y, word2=перо, слова 3..63 = 0.
EXP_PLOT_SHA=7b362ec4efd79e11fe0cbaebfc6de10194fa24dc7eaa76fb989f0bd445472d4c
EXP_OUT_SHA=cf84d96a8bf6c845f86ae136aeec66aea5060b854bb159fabe0d9988f9e9284e
EXP_SVG_SHA=e505aba4e4d494ac9f9099f27160494602b6909f8309d51cb9df7bfc48748a68
MARKER='[аналог NASA'

for f in "$DISPAK" "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" \
         "$REF2148" "$NITI_2348" "$DECK"; do
    [ -f "$f" ] || { echo "FAIL: нет обязательного файла: $f" >&2; exit 2; }
done

# Честная проверка готовности. Без собранного бэкенда результаты benson.out
# и benson.svg не выдумываются, раннер сразу печатает FAIL.
if ! grep -a -q -F 'BESM6_DUDKA_PLOT' "$DISPAK"; then
    echo "FAIL: бэкенд БЕНСОН ещё не собран в $DISPAK"
    echo "  в бинарнике нет маркера BESM6_DUDKA_PLOT"
    echo "  ожидается: dispak читает BESM6_DUDKA_PLOT=benson и пишет"
    echo "  benson.out (коды 06501/06502/06504/06511/06512/06514, пометка аналога)"
    echo "  и benson.svg через проверенный бэкенд plotter.cpp"
    echo "  прогон остановлен до пересборки, результаты не выдумываются"
    exit 3
fi

mkdir -p "$TMP_BASE" || exit 2
WORK=$(mktemp -d "$TMP_BASE/benson-commands.XXXXXX") || exit 2
if [ -z "${KEEP_WORK:-}" ]; then trap 'rm -rf "$WORK"' EXIT; fi
mkdir -p "$WORK/disks" "$WORK/sha" "$WORK/run"

cp "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" "$REF2148" "$WORK/disks/"
cp "$NITI_2348" "$WORK/disks/2348"

echo "=== Проверка команд БЕНСОНА: benson.out / benson.svg ==="
echo "dispak   : $DISPAK"
echo "disk2348 : $NITI_2348"
echo "deck     : $DECK"
echo "env      : BESM6_DUDKA_PLOT=benson BESM6_DUDKA_TEST=1 BESM6_DUBNA_PLOT_KEEP=1"
echo "workdir  : $WORK"
echo "note     : [аналог NASA, БЕНСОН-501], не протокол НИТИ/БЭСМ-6"
echo

FMT='%-6s %-5s %-4s %-4s %-6s %-6s %-5s %-13s %-5s %-5s %s'
printf "$FMT\n" ROUND SUMMARY PLOT OUT SVG 06511 06502 MARK OUT-SHA-12 SVG RESULT > "$WORK/rows"
printf "$FMT\n" ------ ------- ---- --- --- ----- ----- ---- ------------- ---- ------ >> "$WORK/rows"
: > "$WORK/details"

declare -A OK SUM PLOTF OUTF SVGF C1 C2 MARKF

passed=0
failed=0

for round in 1 2; do
    rundir=$WORK/run/C1-line-r$round
    mkdir -p "$rundir"
    cp "$DISPAK" "$rundir/dispak" && chmod +x "$rundir/dispak"
    cp "$DECK" "$rundir/C1-line.b6"

    if command -v timeout >/dev/null 2>&1; then
        cmd=(timeout "$TIMEOUT" ./dispak -l C1-line.b6)
    else
        cmd=(./dispak -l C1-line.b6)
    fi
    ( cd "$rundir" && BESM6_PATH="$WORK/disks" \
        BESM6_DUDKA_PLOT=benson BESM6_DUDKA_TEST=1 \
        BESM6_DUBNA_PLOT_KEEP=1 \
        "${cmd[@]}" > out.txt 2>&1 )
    rc=$?
    out=$rundir/out.txt
    why=""

    sum=N
    if grep -a -q -F "$EXP_SUMMARY" "$out"; then
        sum=Y
    else
        why="$why [ нет строки '$EXP_SUMMARY' ]"
    fi

    plot=N
    if [ -f "$rundir/plot.dat" ]; then
        sha=$(sha256sum "$rundir/plot.dat" | cut -d' ' -f1)
        printf '%s\n' "$sha" > "$WORK/sha/C1-line-plot-r$round.txt"
        if [ "$sha" = "$EXP_PLOT_SHA" ]; then
            plot=Y
        else
            why="$why [ plot.dat SHA $sha != ${EXP_PLOT_SHA:0:12} ]"
        fi
    else
        why="$why [ нет plot.dat ]"
    fi

    outf=N
    outsha=-
    if [ -s "$rundir/benson.out" ]; then
        outf=Y
        outsha=$(sha256sum "$rundir/benson.out" | cut -d' ' -f1)
        printf '%s\n' "$outsha" > "$WORK/sha/C1-line-out-r$round.txt"
        if [ "$outsha" != "$EXP_OUT_SHA" ]; then
            why="$why [ benson.out SHA $outsha != ${EXP_OUT_SHA:0:12} ]"
        fi
    else
        why="$why [ нет или пуст benson.out ]"
    fi

    svf=N
    svsha=-
    if [ -s "$rundir/benson.svg" ]; then
        svf=Y
        svsha=$(sha256sum "$rundir/benson.svg" | cut -d' ' -f1)
        printf '%s\n' "$svsha" > "$WORK/sha/C1-line-svg-r$round.txt"
        if [ "$svsha" != "$EXP_SVG_SHA" ]; then
            why="$why [ benson.svg SHA $svsha != ${EXP_SVG_SHA:0:12} ]"
        fi
    else
        why="$why [ нет или пуст benson.svg ]"
    fi

    # Код может быть записан как 6511 или как 06511, оба вида восьмеричные.
    c1=N
    if [ -s "$rundir/benson.out" ] && \
       grep -a -E -q '(^|[^0-9])0?6511([^0-9]|$)' "$rundir/benson.out"; then
        c1=Y
    else
        why="$why [ в benson.out нет кода 06511/6511 (UP) ]"
    fi

    c2=N
    if [ -s "$rundir/benson.out" ] && \
       grep -a -E -q '(^|[^0-9])0?6502([^0-9]|$)' "$rundir/benson.out"; then
        c2=Y
    else
        why="$why [ в benson.out нет кода 06502/6502 (+X) ]"
    fi

    mark=N
    if grep -a -q -F "$MARKER" "$rundir/benson.out" 2>/dev/null || \
       grep -a -q -F "$MARKER" "$out" 2>/dev/null; then
        mark=Y
    else
        why="$why [ нет пометки $MARKER ]"
    fi

    ok=1
    [ -z "$why" ] || ok=0
    OK[$round]=$ok
    SUM[$round]=$sum
    PLOTF[$round]=$plot
    OUTF[$round]=$outf
    SVGF[$round]=$svf
    C1[$round]=$c1
    C2[$round]=$c2
    MARKF[$round]=$mark

    if [ "$ok" -eq 1 ]; then result=PASS; else result=FAIL; fi
    printf "$FMT\n" "r$round" "$sum" "$plot" "$outf" "$svf" "$c1" "$c2" \
        "$mark" "${outsha:0:12}" "${svsha:0:12}" "$result" >> "$WORK/rows"
    printf 'r%s rc=%s out=%s why=%s\n' "$round" "$rc" "$out" "$why" >> "$WORK/details"
done

det=N
if [ -f "$WORK/sha/C1-line-plot-r1.txt" ] && [ -f "$WORK/sha/C1-line-plot-r2.txt" ] && \
   [ -f "$WORK/sha/C1-line-out-r1.txt" ] && [ -f "$WORK/sha/C1-line-out-r2.txt" ] && \
   [ -f "$WORK/sha/C1-line-svg-r1.txt" ] && [ -f "$WORK/sha/C1-line-svg-r2.txt" ] && \
   cmp -s "$WORK/sha/C1-line-plot-r1.txt" "$WORK/sha/C1-line-plot-r2.txt" && \
   cmp -s "$WORK/sha/C1-line-out-r1.txt"  "$WORK/sha/C1-line-out-r2.txt" && \
   cmp -s "$WORK/sha/C1-line-svg-r1.txt"  "$WORK/sha/C1-line-svg-r2.txt"; then
    det=Y
fi

case_ok=1
[ "${OK[1]}" -eq 1 ] && [ "${OK[2]}" -eq 1 ] || case_ok=0
[ "$det" = Y ] || case_ok=0

if [ "$case_ok" -eq 1 ]; then
    result=PASS
    passed=1
else
    result=FAIL
    failed=1
    if [ "$det" != Y ]; then
        printf 'SHA между r1 и r2 не совпали (determ=%s)\n' "$det" >> "$WORK/details"
    fi
fi
printf "$FMT\n" 'r1=r2' "${SUM[1]}/${SUM[2]}" "${PLOTF[1]}/${PLOTF[2]}" \
    "${OUTF[1]}/${OUTF[2]}" "${SVGF[1]}/${SVGF[2]}" \
    "${C1[1]}/${C1[2]}" "${C2[1]}/${C2[2]}" "${MARKF[1]}/${MARKF[2]}" \
    '-' "$det" "$result" >> "$WORK/rows"

cat "$WORK/rows"
if [ "$failed" -ne 0 ] || [ -n "${VERBOSE:-}" ]; then
    echo
    echo "Детали:"
    cat "$WORK/details"
fi

echo
echo "Summary: $passed PASS, $failed FAIL (of 1 cases)"
echo "ctest не запускался: его запускает lead."
[ "$failed" -eq 0 ]
