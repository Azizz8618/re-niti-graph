#!/bin/bash
# Complex-figure tests for the NITI/BENSON plotter stand.
# Every deck uses explicit MOVE(x,y)/PLOT pairs with precomputed numbers.
# PLOTSTUB passes FRAME(1) to PDEV, so the /PDEVXY/ address is irrelevant and
# any program length / number of distinct coordinates is allowed.
# Each deck is run twice (r1, r2); plot.dat, benson.out and benson.svg must
# have identical SHA256 in both rounds.
# Overrides: DISPAK_BIN, NITI_2348, TMPDIR, KEEP_WORK, REF2148, TIMEOUT, VERBOSE.
# All temporary files live under TMPDIR (default /var/tmp). No repository file
# other than this directory is written. No git commit/push is performed.
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)

DISPAK=${DISPAK_BIN:-/home/azizz/Yandex.Disk/dispak/build/dispak/dispak}
DISKDIR=$(dirname "$DISPAK")
REF2148=${REF2148:-/usr/local/share/besm6/2148}
NITI_2348=${NITI_2348:-$HOME/.besm6/2348}
TMP_BASE=${TMPDIR:-/var/tmp}
TIMEOUT=${TIMEOUT:-240}

# Both spellings are fatal: dispak transliterates some monitor diagnostics.
FATAL_RE='ОШ|ОШИБКА|ОТСУТСТВУЕТ|НЕДОПУСТИМ|НЕТ ТАКОЙ|БЫЛИ ОШИБКИ|ERR [0-9]+|OTCYTCTBYET|OWIBKA|HET TAKO'

# Every non-empty benson.out line must be one of the six NASA-analog command
# codes, with the mandatory [аналог NASA, БЕНСОН-501] annotation.
CMD_RE='^[[:space:]]*$|^0?65(01|02|04|11|12|14) (DOWN|UP|\+X|\-X|\+Y|\-Y) X=[0-9]{5} Y=[0-9]{5} \[аналог NASA, БЕНСОН-501\][[:space:]]*$'

CASES=(f01-star f02-circle f03-spiral f04-sine f05-grid f06-sawtooth)

for f in "$DISPAK" "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" \
         "$REF2148" "$NITI_2348" "$HERE/expected.tsv"; do
    [ -f "$f" ] || { echo "FAIL: нет обязательного файла: $f" >&2; exit 2; }
done
for name in "${CASES[@]}"; do
    [ -f "$HERE/$name.b6" ] || { echo "FAIL: нет деки: $HERE/$name.b6" >&2; exit 2; }
done

# Honest readiness check: without the compiled BENSON backend there are no
# benson.out / benson.svg artifacts. Do not invent results.
if ! grep -a -q -F 'BESM6_DUDKA_PLOT' "$DISPAK"; then
    echo "FAIL: в $DISPAK нет маркера BESM6_DUDKA_PLOT"
    echo "  бэкенд БЕНСОН не собран; прогон остановлен, результаты не выдумываются"
    exit 3
fi

# Expected geometry comes from gen_decks.py via expected.tsv:
# name, points, maxX, maxY, expected width (maxX+2), expected height (maxY+1).
declare -A EXP_POINTS EXP_W EXP_H
while IFS=$'\t' read -r nm pts mx my ew eh rest; do
    case "$nm" in ''|\#*) continue ;; esac
    EXP_POINTS[$nm]=$pts; EXP_W[$nm]=$ew; EXP_H[$nm]=$eh
done < "$HERE/expected.tsv"
for name in "${CASES[@]}"; do
    [ -n "${EXP_POINTS[$name]:-}" ] || { echo "FAIL: нет expected-строки: $name" >&2; exit 2; }
done

mkdir -p "$TMP_BASE" || exit 2
WORK=$(mktemp -d "$TMP_BASE/plotter-figures.XXXXXX") || exit 2
if [ -z "${KEEP_WORK:-}" ]; then trap 'rm -rf "$WORK"' EXIT; fi
mkdir -p "$WORK/disks" "$WORK/rows"
cp "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" "$REF2148" "$WORK/disks/"
cp "$NITI_2348" "$WORK/disks/2348"

echo "=== Сложные фигуры графопостроителя (BENSON) ==="
echo "dispak   : $DISPAK"
echo "disk2348 : $NITI_2348"
echo "decks    : $HERE"
echo "env      : BESM6_DUDKA_PLOT=benson BESM6_DUDKA_TEST=1 BESM6_DUBNA_PLOT_KEEP=1"
echo "workdir  : $WORK"
echo "note     : [аналог NASA, БЕНСОН-501], не протокол НИТИ/БЭСМ-6"
echo "bbox     : width=maxX+2, height=maxY+1; допуск ±2"
echo

FMT='%-16s %-4s %-4s %-5s %-5s %-4s %-4s %-5s %-5s %-9s %-3s %-13s %-13s %-13s %s'
printf "$FMT\n" CASE SUM END NOERR PLOT OUT SVG CMD PATH BBOX DET PLOT-SHA-12 OUT-SHA-12 SVG-SHA-12 RESULT
printf "$FMT\n" ---- --- --- ----- ---- --- --- --- ---- ---- --- ------------ ------------ ------------ ------

within() { # $1 value, $2 expected, tolerance ±2
    local v=$1 e=$2
    case "$v$e" in *[!0-9]*) return 1 ;; esac
    [ "$v" -ge "$((e-2))" ] && [ "$v" -le "$((e+2))" ]
}

declare -A A_SUM A_END A_ERR A_PLOT A_OUT A_SVG A_CMD A_PATH A_W A_H A_DET A_OK
declare -A A_PSHA A_OSHA A_SSHA
passed=0
failed=0

for name in "${CASES[@]}"; do
    why=""
    for round in 1 2; do
        rundir="$WORK/run/$name-r$round"
        mkdir -p "$rundir"
        cp "$DISPAK" "$rundir/dispak" && chmod +x "$rundir/dispak"
        cp "$HERE/$name.b6" "$rundir/$name.b6"

        if command -v timeout >/dev/null 2>&1; then
            cmd=(timeout "$TIMEOUT" ./dispak -l "$name.b6")
        else
            cmd=(./dispak -l "$name.b6")
        fi
        ( cd "$rundir" && BESM6_PATH="$WORK/disks" \
            BESM6_DUDKA_PLOT=benson BESM6_DUDKA_TEST=1 \
            BESM6_DUBNA_PLOT_KEEP=1 \
            "${cmd[@]}" > out.txt 2>&1 )
        rc=$?
        out="$rundir/out.txt"

        grep -a -q -F 'NITI: summary' "$out" || why="$why [r$round: нет NITI: summary]"
        grep -a -q -F 'КОНЕЦ ЗАДАЧИ' "$out" || why="$why [r$round: нет КОНЕЦ ЗАДАЧИ]"
        grep -a -q -E "$FATAL_RE" "$out" && why="$why [r$round: ОШ/ERR в логе]"

        if [ -s "$rundir/plot.dat" ]; then
            sha=$(sha256sum "$rundir/plot.dat" | cut -d' ' -f1)
            printf '%s\n' "$sha" > "$WORK/rows/$name-plot-r$round"
            [ "$round" -eq 1 ] && A_PSHA[$name]=${sha:0:12}
        else
            why="$why [r$round: нет или пуст plot.dat]"
        fi

        if [ -s "$rundir/benson.out" ]; then
            bad=$(grep -a -c -v -E "$CMD_RE" "$rundir/benson.out" 2>/dev/null || true)
            [ -n "$bad" ] || bad=0
            if [ "$bad" -ne 0 ]; then
                why="$why [r$round: $bad несоответствующих строк в benson.out]"
            fi
            sha=$(sha256sum "$rundir/benson.out" | cut -d' ' -f1)
            printf '%s\n' "$sha" > "$WORK/rows/$name-out-r$round"
            [ "$round" -eq 1 ] && A_OSHA[$name]=${sha:0:12}
            [ "$round" -eq 1 ] && cp "$rundir/benson.out" "$WORK/rows/$name.out"
        else
            why="$why [r$round: нет или пуст benson.out]"
        fi

        if [ -s "$rundir/benson.svg" ]; then
            svg="$rundir/benson.svg"
            [ "$(head -n 1 "$svg" | cut -c1-5)" = '<?xml' ] || \
                why="$why [r$round: benson.svg не начинается с <?xml]"
            grep -a -q '<svg' "$svg" || why="$why [r$round: в benson.svg нет <svg]"
            np=$(grep -a -c '<path' "$svg" 2>/dev/null || true)
            [ -n "$np" ] || np=0
            if [ "$np" -ne "${EXP_POINTS[$name]}" ]; then
                why="$why [r$round: <path>=$np, ожидалось ${EXP_POINTS[$name]}]"
            fi
            sha=$(sha256sum "$svg" | cut -d' ' -f1)
            printf '%s\n' "$sha" > "$WORK/rows/$name-svg-r$round"
            if [ "$round" -eq 1 ]; then
                A_SSHA[$name]=${sha:0:12}
                A_PATH[$name]=$np
                svgline=$(grep -a -m1 '<svg' "$svg")
                w=$(printf '%s\n' "$svgline" | sed -n 's/.* width="\([0-9][0-9]*\)".*/\1/p')
                h=$(printf '%s\n' "$svgline" | sed -n 's/.* height="\([0-9][0-9]*\)".*/\1/p')
                within "${w:-x}" "${EXP_W[$name]}" || \
                    why="$why [r1: width=${w:-?} вне ${EXP_W[$name]}±2]"
                within "${h:-x}" "${EXP_H[$name]}" || \
                    why="$why [r1: height=${h:-?} вне ${EXP_H[$name]}±2]"
                A_W[$name]=${w:-?}
                A_H[$name]=${h:-?}
                cp "$svg" "$WORK/rows/$name.svg"
            fi
        else
            why="$why [r$round: нет или пуст benson.svg]"
        fi

        nplot=$(grep -a 'NITI-C1 NPLOT=' "$out" 2>/dev/null | grep -a -v FORMAT | tail -1 \
                | sed -n 's/.*NPLOT= *\([0-9]*\).*/\1/p')
        printf 'rc=%s nplot=%s out=%s\n' "$rc" "${nplot:-?}" "$out" \
            > "$WORK/rows/$name-meta-r$round"
    done

    # r1 flags are authoritative for the summary table.
    s1=Y; e1=Y; err1=Y; p1=N; o1=N; v1=N; c1=N
    r1="$WORK/run/$name-r1"
    grep -a -q -F 'NITI: summary' "$r1/out.txt" || s1=N
    grep -a -q -F 'КОНЕЦ ЗАДАЧИ' "$r1/out.txt" || e1=N
    grep -a -q -E "$FATAL_RE" "$r1/out.txt" && err1=N
    [ -s "$r1/plot.dat" ] && p1=Y
    [ -s "$r1/benson.out" ] && o1=Y
    [ -s "$r1/benson.svg" ] && v1=Y
    if [ -s "$r1/benson.out" ] && \
       [ "$(grep -a -c -v -E "$CMD_RE" "$r1/benson.out" 2>/dev/null || true)" = 0 ]; then
        c1=Y
    fi

    det=Y
    for art in plot out svg; do
        if ! cmp -s "$WORK/rows/$name-$art-r1" "$WORK/rows/$name-$art-r2"; then
            det=N
            why="$why [SHA $art r1 != r2]"
        fi
    done

    A_SUM[$name]=$s1; A_END[$name]=$e1; A_ERR[$name]=$err1
    A_PLOT[$name]=$p1; A_OUT[$name]=$o1; A_SVG[$name]=$v1; A_CMD[$name]=$c1
    A_DET[$name]=$det

    if [ -z "$why" ]; then ok=1; result=PASS; passed=$((passed+1))
    else ok=0; result=FAIL; failed=$((failed+1)); fi
    A_OK[$name]=$ok

    printf "$FMT\n" "$name" "$s1" "$e1" "$err1" "$p1" "$o1" "$v1" "$c1" \
        "${A_PATH[$name]:-?}/${EXP_POINTS[$name]}" \
        "${A_W[$name]:-?}x${A_H[$name]:-?}" "$det" \
        "${A_PSHA[$name]:-}" "${A_OSHA[$name]:-}" "${A_SSHA[$name]:-}" "$result"
    printf '%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n' \
        "$name" "$s1" "$e1" "$err1" "$p1" "$o1" "$v1" "$c1" \
        "${A_PATH[$name]:-?}" "${A_W[$name]:-?}" "${A_H[$name]:-?}" "$det" \
        "${A_PSHA[$name]:-}" "${A_OSHA[$name]:-}" "${A_SSHA[$name]:-}" >> "$WORK/summary.csv"
    printf '%s: %s\n' "$name" "$why" > "$WORK/rows/$name-why"
done

echo
echo "=== Полные SHA256 (r1 = r2) ==="
for name in "${CASES[@]}"; do
    printf '%-16s plot=%s\n' "$name" "$(cat "$WORK/rows/$name-plot-r1" 2>/dev/null || echo -)"
    printf '%-16s out =%s\n' '' "$(cat "$WORK/rows/$name-out-r1" 2>/dev/null || echo -)"
    printf '%-16s svg =%s\n' '' "$(cat "$WORK/rows/$name-svg-r1" 2>/dev/null || echo -)"
    if [ "${A_OK[$name]}" -ne 1 ] || [ -n "${VERBOSE:-}" ]; then
        printf '  why: %s\n' "$(cat "$WORK/rows/$name-why")"
        [ -f "$WORK/rows/$name.svg" ] && grep -a '<path' "$WORK/rows/$name.svg" | sed 's/^/  /'
    fi
done

echo
echo "Summary: $passed PASS, $failed FAIL (of ${#CASES[@]} decks)"
echo "Критерий: минимум 6 PASS с детерминированными SHA и осмысленными SVG"
echo "workdir: $WORK"
[ "$failed" -eq 0 ] && [ "$passed" -ge 6 ]
