#!/bin/bash
# Проверка подключаемого бэкенда графики Дубны в dispak.
# Две существующие деки прогоняются дважды, сравниваются SHA plot.dat,
# calcomp.out и calcomp.svg. ctest намеренно не вызывается: его запускает lead.
# Переменные: DISPAK_BIN, NITI_2348, TMPDIR, KEEP_WORK, REF2148, TIMEOUT, VERBOSE.
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)

DISPAK=${DISPAK_BIN:-/home/azizz/Yandex.Disk/dispak/build/dispak/dispak}
DISKDIR=$(dirname "$DISPAK")
REF2148=${REF2148:-/usr/local/share/besm6/2148}
NITI_2348=${NITI_2348:-$ROOT/fortran/verify/2348-niti.img}
TMP_BASE=${TMPDIR:-/tmp/.private/azizz/opencode}
TIMEOUT=${TIMEOUT:-240}

DECK_C1=$ROOT/verify/C1-line.b6
DECK_T02=$ROOT/verify/niti-lowlevel/t02-frame.b6

for f in "$DISPAK" "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" \
         "$REF2148" "$NITI_2348" "$DECK_C1" "$DECK_T02"; do
    [ -f "$f" ] || { echo "FAIL: нет обязательного файла: $f" >&2; exit 2; }
done

# Честная проверка готовности. Без собранного моста никакие результаты
# calcomp.out / calcomp.svg не выдумываются, раннер сразу печатает FAIL.
if ! grep -a -q 'DUBNA-PLOT' "$DISPAK" || \
   ! grep -a -q 'calcomp' "$DISPAK" || \
   ! grep -a -q 'proven' "$DISPAK"; then
    echo "FAIL: бэкенд Дубны ещё не собран в $DISPAK"
    echo "  в бинарнике нет маркеров DUBNA-PLOT / calcomp / proven"
    echo "  примечание: имя calcomp.out собирается динамически и в бинарнике отсутствует"
    echo "  ожидается: C ABI мост к plotter.cpp и режим BESM6_NITI_DECODE=proven в dispak/extra.c"
    echo "  прогон остановлен до пересборки, результаты не выдумываются"
    exit 3
fi

mkdir -p "$TMP_BASE" || exit 2
WORK=$(mktemp -d "$TMP_BASE/dubna-bridge.XXXXXX") || exit 2
if [ -z "${KEEP_WORK:-}" ]; then trap 'rm -rf "$WORK"' EXIT; fi
mkdir -p "$WORK/disks" "$WORK/sha" "$WORK/run"

cp "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" "$REF2148" "$WORK/disks/"
cp "$NITI_2348" "$WORK/disks/2348"

echo "=== Проверка моста Дубна: calcomp.out / calcomp.svg ==="
echo "dispak   : $DISPAK"
echo "disk2348 : $NITI_2348"
echo "decode   : BESM6_NITI_DECODE=proven, BESM6_DUDKA_TEST=1, BESM6_DUBNA_PLOT_KEEP=1"
echo "workdir  : $WORK"
echo

FMT='%-10s %-6s %-7s %-5s %-6s %-5s %-5s %-13s %-5s %s'
printf "$FMT\n" CASE ROUND SUMMARY PLOT DEV OUT SVG OUT-SHA-12 DET RESULT > "$WORK/rows"
printf "$FMT\n" ---------- ------ ------- ----- ------ ----- ----- ------------- ----- ------ >> "$WORK/rows"
: > "$WORK/details"

expect_for() {
    case "$1" in
        C1-line)
            EXP_SUMMARY='NITI: summary schemes=2 frames=2 words=128 active=1 scheme=1210'
            EXP_PLOT_SHA=7b362ec4efd79e11fe0cbaebfc6de10194fa24dc7eaa76fb989f0bd445472d4c ;;
        t02-frame)
            EXP_SUMMARY='NITI: summary schemes=1 frames=1 words=64 active=1 scheme=1210'
            EXP_PLOT_SHA=27440f92e4c5039ed011d678d0fe2fbbab945fde8f05d4d415c8eba6c80db498 ;;
    esac
}

declare -A OK SUM PLOT DEV OUTP SVP

passed=0
failed=0

for name in C1-line t02-frame; do
    expect_for "$name"
    case "$name" in
        C1-line)   deck=$DECK_C1 ;;
        t02-frame) deck=$DECK_T02 ;;
    esac
    deckbase=$(basename "$deck")

    for round in 1 2; do
        rundir=$WORK/run/$name-r$round
        mkdir -p "$rundir"
        cp "$DISPAK" "$rundir/dispak" && chmod +x "$rundir/dispak"
        cp "$deck" "$rundir/$deckbase"

        if command -v timeout >/dev/null 2>&1; then
            cmd=(timeout "$TIMEOUT" ./dispak -l "$deckbase")
        else
            cmd=(./dispak -l "$deckbase")
        fi
        ( cd "$rundir" && BESM6_PATH="$WORK/disks" \
            BESM6_NITI_DECODE=proven BESM6_DUDKA_TEST=1 \
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
            printf '%s\n' "$sha" > "$WORK/sha/$name-plot-r$round.txt"
            if [ "$sha" = "$EXP_PLOT_SHA" ]; then
                plot=Y
            else
                why="$why [ plot.dat SHA $sha != ${EXP_PLOT_SHA:0:12} ]"
            fi
        else
            why="$why [ нет plot.dat ]"
        fi

        dev=N
        if grep -a -q -F 'DUDKA: DUBNA-PLOT device=calcomp' "$out"; then
            dev=Y
        else
            why="$why [ нет строки DUDKA: DUBNA-PLOT device=calcomp ]"
        fi

        outf=N
        outsha=-
        if [ -s "$rundir/calcomp.out" ]; then
            outf=Y
            outsha=$(sha256sum "$rundir/calcomp.out" | cut -d' ' -f1)
            printf '%s\n' "$outsha" > "$WORK/sha/$name-out-r$round.txt"
        else
            why="$why [ нет или пуст calcomp.out ]"
        fi

        svf=N
        if [ -s "$rundir/calcomp.svg" ]; then
            svf=Y
            sha=$(sha256sum "$rundir/calcomp.svg" | cut -d' ' -f1)
            printf '%s\n' "$sha" > "$WORK/sha/$name-svg-r$round.txt"
        else
            why="$why [ нет или пуст calcomp.svg ]"
        fi

        ok=1
        [ -z "$why" ] || ok=0
        OK[$round]=$ok
        SUM[$round]=$sum
        PLOT[$round]=$plot
        DEV[$round]=$dev
        OUTP[$round]=$outf
        SVP[$round]=$svf

        if [ "$ok" -eq 1 ]; then result=PASS; else result=FAIL; fi
        printf "$FMT\n" "$name" "r$round" "$sum" "$plot" "$dev" "$outf" "$svf" \
            "${outsha:0:12}" - "$result" >> "$WORK/rows"
        printf '%s r%s rc=%s out=%s%s\n' "$name" "$round" "$rc" "$out" "$why" >> "$WORK/details"
    done

    det=N
    if [ -f "$WORK/sha/$name-out-r1.txt" ] && [ -f "$WORK/sha/$name-out-r2.txt" ] && \
       [ -f "$WORK/sha/$name-svg-r1.txt" ] && [ -f "$WORK/sha/$name-svg-r2.txt" ] && \
       [ -f "$WORK/sha/$name-plot-r1.txt" ] && [ -f "$WORK/sha/$name-plot-r2.txt" ] && \
       cmp -s "$WORK/sha/$name-out-r1.txt"  "$WORK/sha/$name-out-r2.txt" && \
       cmp -s "$WORK/sha/$name-svg-r1.txt"  "$WORK/sha/$name-svg-r2.txt" && \
       cmp -s "$WORK/sha/$name-plot-r1.txt" "$WORK/sha/$name-plot-r2.txt"; then
        det=Y
    fi

    case_ok=1
    [ "${OK[1]}" -eq 1 ] && [ "${OK[2]}" -eq 1 ] || case_ok=0
    [ "$det" = Y ] || case_ok=0

    if [ "$case_ok" -eq 1 ]; then
        result=PASS
        passed=$((passed+1))
    else
        result=FAIL
        failed=$((failed+1))
        printf '%s: SHA между r1 и r2 не совпали (determ=%s)\n' "$name" "$det" >> "$WORK/details"
    fi
    printf "$FMT\n" "$name" 'r1=r2' "${SUM[1]}/${SUM[2]}" "${PLOT[1]}/${PLOT[2]}" \
        "${DEV[1]}/${DEV[2]}" "${OUTP[1]}/${OUTP[2]}" "${SVP[1]}/${SVP[2]}" \
        - "$det" "$result" >> "$WORK/rows"
done

cat "$WORK/rows"
if [ "$failed" -ne 0 ] || [ -n "${VERBOSE:-}" ]; then
    echo
    echo "Детали:"
    cat "$WORK/details"
fi

echo
echo "Summary: $passed PASS, $failed FAIL (of 2 cases)"
echo "ctest не запускался: его запускает lead."
[ "$failed" -eq 0 ]
