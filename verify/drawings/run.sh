#!/bin/bash
# Test drawings for the NITI/BENSON plotter stand.
# PLOTSTUB passes FRAME(1) to PDEV, so /PDEVXY/ may sit at any address the
# FOREX linker picks: decks can use any number of distinct coordinates and
# any number of MOVE/PLOT pairs. The /PDEVXY/ address is reported for
# information only; the pass criterion is the rendered result: a non-empty
# benson.out and a benson.svg with at least one <path>.
# Every deck is run twice; benson.out/benson.svg SHA must match between rounds.
# Overrides: DISPAK_BIN, NITI_2348, TMPDIR, KEEP_WORK, REF2148, TIMEOUT, VERBOSE.
# All temporary files live under TMPDIR (default /var/tmp). No repository file
# other than this directory is written.
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)

DISPAK=${DISPAK_BIN:-/home/azizz/Yandex.Disk/dispak/build/dispak/dispak}
DISKDIR=$(dirname "$DISPAK")
REF2148=${REF2148:-/usr/local/share/besm6/2148}
NITI_2348=${NITI_2348:-$HOME/.besm6/2348}
TMP_BASE=${TMPDIR:-/var/tmp}
TIMEOUT=${TIMEOUT:-240}

# Both spellings are fatal: dispak prints some monitor diagnostics in a Latin
# transliteration of Cyrillic.
FATAL_RE='ОШ|ОШИБКА|ОТСУТСТВУЕТ|НЕДОПУСТИМ|НЕТ ТАКОЙ|БЫЛИ ОШИБКИ|ERR [0-9]+|OTCYTCTBYET|OWIBKA|HET TAKO'

CASES=(d01-horizontal d02-vertical d03-diagonal d04-rectangle \
       d05-zigzag d06-steep d07-shallow d08-tiny d09-triangle d10-quad)

for f in "$DISPAK" "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" \
         "$REF2148" "$NITI_2348"; do
    [ -f "$f" ] || { echo "FAIL: нет обязательного файла: $f" >&2; exit 2; }
done
for name in "${CASES[@]}"; do
    [ -f "$HERE/$name.b6" ] || { echo "FAIL: нет деки: $HERE/$name.b6" >&2; exit 2; }
done

# Honest readiness check: without the compiled BENSON backend there are no
# benson.out / benson.svg artifacts, so do not invent results.
if ! grep -a -q -F 'BESM6_DUDKA_PLOT' "$DISPAK"; then
    echo "FAIL: в $DISPAK нет маркера BESM6_DUDKA_PLOT"
    echo "  бэкенд БЕНСОН не собран; прогон остановлен, результаты не выдумываются"
    exit 3
fi

mkdir -p "$TMP_BASE" || exit 2
WORK=$(mktemp -d "$TMP_BASE/plotter-drawings.XXXXXX") || exit 2
if [ -z "${KEEP_WORK:-}" ]; then trap 'rm -rf "$WORK"' EXIT; fi
mkdir -p "$WORK/disks" "$WORK/rows"
cp "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" "$REF2148" "$WORK/disks/"
cp "$NITI_2348" "$WORK/disks/2348"

echo "=== Тестовые рисунки графопостроителя (BENSON) ==="
echo "dispak   : $DISPAK"
echo "disk2348 : $NITI_2348"
echo "decks    : $HERE"
echo "env      : BESM6_DUDKA_PLOT=benson BESM6_DUDKA_TEST=1 BESM6_DUBNA_PLOT_KEEP=1"
echo "workdir  : $WORK"
echo "adres    : /PDEVXY/ передаётся аргументом; адрес из кросс-ссылки только для справки"
echo

FMT='%-16s %-4s %-4s %-4s %-5s %-4s %-4s %-4s %-9s %-5s %-13s %-13s %s'
printf "$FMT\n" CASE SUM END NOERR ADR OUT SVG DET SVG-WxH PATHS OUT-SHA-12 SVG-SHA-12 RESULT
printf "$FMT\n" ---- --- --- ----- --- --- --- --- ------ ----- ------------ ------------ ------

declare -A A_SUM A_END A_ERR A_ADR A_OUT A_SVG A_DET A_W A_H A_PATH A_OSHA A_SSHA A_OK
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

        # r1 is authoritative for the banner/error checks; r2 is checked too.
        grep -a -q -F 'NITI: summary' "$out" || why="$why [r$round: нет NITI: summary]"
        grep -a -q -F 'КОНЕЦ ЗАДАЧИ' "$out" || why="$why [r$round: нет КОНЕЦ ЗАДАЧИ]"
        if grep -a -q -E "$FATAL_RE" "$out"; then
            why="$why [r$round: ОШ/ERR в логе]"
        fi
        # Informational only: the address now arrives as an argument, so a
        # different address is expected for decks with a longer constant pool.
        adr=$(awk '/\*PDEVXY\*/ && / C / {for (i=1; i<NF; i++) \
              if ($i == "C") {print $(i+1); exit}}' "$out")
        [ -n "$adr" ] || adr='?'
        [ "$round" -eq 1 ] && A_ADR[$name]=$adr

        if [ -s "$rundir/benson.out" ]; then
            printf '%s\n' "$(sha256sum "$rundir/benson.out" | cut -d' ' -f1)" \
                > "$WORK/rows/$name-out-r$round"
        else
            why="$why [r$round: нет или пуст benson.out]"
        fi

        if [ -s "$rundir/benson.svg" ]; then
            svg="$rundir/benson.svg"
            if [ "$(head -n 1 "$svg" | cut -c1-5)" != '<?xml' ]; then
                why="$why [r$round: benson.svg не начинается с <?xml]"
            fi
            np=$(grep -a -c '<path' "$svg" 2>/dev/null || true)
            [ -n "$np" ] || np=0
            if [ "$np" -lt 1 ]; then
                why="$why [r$round: в benson.svg нет <path]"
            fi
            printf '%s\n' "$(sha256sum "$svg" | cut -d' ' -f1)" \
                > "$WORK/rows/$name-svg-r$round"
            if [ "$round" -eq 1 ]; then
                svgline=$(grep -a -m1 '<svg' "$svg")
                w=$(printf '%s\n' "$svgline" | sed -n 's/.* width="\([0-9][0-9]*\)".*/\1/p')
                h=$(printf '%s\n' "$svgline" | sed -n 's/.* height="\([0-9][0-9]*\)".*/\1/p')
                if [ -z "$w" ] || [ -z "$h" ] || [ "${w:-0}" -lt 2 ] || [ "${h:-0}" -lt 1 ]; then
                    why="$why [r1: неразумные размеры SVG ${w:-?}x${h:-?}]"
                fi
                A_W[$name]=${w:-?}
                A_H[$name]=${h:-?}
                A_PATH[$name]=$np
                grep -a '<path' "$svg" > "$WORK/rows/$name-paths"
                cp "$svg" "$WORK/rows/$name.svg"
            fi
        else
            why="$why [r$round: нет или пуст benson.svg]"
        fi

        nplot=$(grep -a 'NITI-C1 NPLOT=' "$out" 2>/dev/null | grep -a -v FORMAT | tail -1 \
                | sed -n 's/.*NPLOT= *\([0-9]*\).*/\1/p')
        printf '%s\n' "${nplot:-?}" > "$WORK/rows/$name-nplot-r$round"
        printf 'rc=%s nplot=%s out=%s\n' "$rc" "${nplot:-?}" "$out" \
            > "$WORK/rows/$name-meta-r$round"
    done

    # Banner / end / error flags for the table are from r1.
    s1=Y; e1=Y; err1=Y
    grep -a -q -F 'NITI: summary' "$WORK/run/$name-r1/out.txt" || s1=N
    grep -a -q -F 'КОНЕЦ ЗАДАЧИ' "$WORK/run/$name-r1/out.txt" || e1=N
    grep -a -q -E "$FATAL_RE" "$WORK/run/$name-r1/out.txt" && err1=N
    adr=${A_ADR[$name]:-?}
    o1=N; v1=N
    [ -f "$WORK/rows/$name-out-r1" ] && o1=Y
    [ -f "$WORK/rows/$name-svg-r1" ] && v1=Y

    det=N
    if [ -f "$WORK/rows/$name-out-r1" ] && [ -f "$WORK/rows/$name-out-r2" ] && \
       [ -f "$WORK/rows/$name-svg-r1" ] && [ -f "$WORK/rows/$name-svg-r2" ] && \
       cmp -s "$WORK/rows/$name-out-r1" "$WORK/rows/$name-out-r2" && \
       cmp -s "$WORK/rows/$name-svg-r1" "$WORK/rows/$name-svg-r2"; then
        det=Y
    else
        why="$why [SHA r1 != r2]"
    fi

    A_SUM[$name]=$s1; A_END[$name]=$e1; A_ERR[$name]=$err1; A_ADR[$name]=$adr
    A_OUT[$name]=$o1; A_SVG[$name]=$v1; A_DET[$name]=$det
    A_OSHA[$name]=$(cat "$WORK/rows/$name-out-r1" 2>/dev/null | cut -c1-12)
    [ -n "${A_OSHA[$name]}" ] || A_OSHA[$name]=-
    A_SSHA[$name]=$(cat "$WORK/rows/$name-svg-r1" 2>/dev/null | cut -c1-12)
    [ -n "${A_SSHA[$name]}" ] || A_SSHA[$name]=-

    if [ -z "$why" ]; then ok=1; result=PASS; passed=$((passed+1))
    else ok=0; result=FAIL; failed=$((failed+1)); fi
    A_OK[$name]=$ok

    printf "$FMT\n" "$name" "$s1" "$e1" "$err1" "$adr" "$o1" "$v1" "$det" \
        "${A_W[$name]:-?}x${A_H[$name]:-?}" "${A_PATH[$name]:-?}" \
        "${A_OSHA[$name]}" "${A_SSHA[$name]}" "$result"
    printf '%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n' "$name" "$s1" "$e1" "$err1" \
        "$adr" "$o1" "$v1" "$det" "${A_W[$name]:-?}" "${A_H[$name]:-?}" \
        "${A_PATH[$name]:-?}" >> "$WORK/summary.csv"
    printf '%s: %s\n' "$name" "$why" > "$WORK/rows/$name-why"
done

echo
echo "=== Детали (SHA256, геометрия) ==="
for name in "${CASES[@]}"; do
    printf '%-16s out=%s  svg=%s  nplot=%s/%s  paths=%s  svg=%sx%s\n' \
        "$name" \
        "$(cat "$WORK/rows/$name-out-r1" 2>/dev/null || echo -)" \
        "$(cat "$WORK/rows/$name-svg-r1" 2>/dev/null || echo -)" \
        "$(cat "$WORK/rows/$name-nplot-r1" 2>/dev/null || echo ?)" \
        "$(cat "$WORK/rows/$name-nplot-r2" 2>/dev/null || echo ?)" \
        "${A_PATH[$name]:-?}" "${A_W[$name]:-?}" "${A_H[$name]:-?}"
    if [ "${A_OK[$name]}" -ne 1 ] || [ -n "${VERBOSE:-}" ]; then
        printf '  why: %s\n' "$(cat "$WORK/rows/$name-why")"
        if [ -f "$WORK/rows/$name-paths" ]; then
            sed 's/^/  /' "$WORK/rows/$name-paths"
        fi
    fi
done

echo
echo "Summary: $passed PASS, $failed FAIL (of ${#CASES[@]} decks)"
echo "Критерий: все ${#CASES[@]} дек PASS (в том числе 3/4-точечные d09/d10)"
echo "workdir: $WORK"
[ "$failed" -eq 0 ] && [ "$passed" -eq "${#CASES[@]}" ]
