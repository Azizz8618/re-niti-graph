#!/bin/bash
# Стресс- и отрицательные тесты графопостроителя (БЕНСОН-501, [аналог NASA]).
# Каждая дека прогоняется дважды; сравниваются SHA256 benson.out/benson.svg.
# s01 - границы координат, s02 - длинная программа, s04 - минимальные шаги,
# s03 - отрицательный контроль: кадр с X=6000 должен быть отброшен с логом.
# Ничего не пишется в репозиторий: все артефакты живут в TMPDIR (/var/tmp).
# Переменные: DISPAK_BIN, NITI_2348, TMPDIR, KEEP_WORK, REF2148, TIMEOUT, VERBOSE.
# Git commit/push не выполняются.
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)

DISPAK=${DISPAK_BIN:-/home/azizz/Yandex.Disk/dispak/build/dispak/dispak}
DISKDIR=$(dirname "$DISPAK")
REF2148=${REF2148:-/usr/local/share/besm6/2148}
NITI_2348=${NITI_2348:-$HOME/.besm6/2348}
TMP_BASE=${TMPDIR:-/var/tmp}
TIMEOUT=${TIMEOUT:-240}

# Dispak печатает часть диагностики латиницей; оба написания считаются фатальными.
FATAL_RE='ОШ|ОШИБКА|ОТСУТСТВУЕТ|НЕДОПУСТИМ|НЕТ ТАКОЙ|БЫЛИ ОШИБКИ|ERR [0-9]+|OTCYTCTBYET|OWIBKA|HET TAKO'
MARKER='[аналог NASA, БЕНСОН-501]'

CASES=(s01-limits s02-long s03-out-of-range s04-tiny-steps)

# Ожидаемые значения зафиксированы по реальным прогонам, см. EXPECTED.md.
# PATHS для s01 и s04 меньше числа PLOT: кадр в текущей точке пера
# (старт (0,0) и два повтора в s04) не даёт элемента <path>.
declare -A KIND=( [s01-limits]=limits [s02-long]=long \
                  [s03-out-of-range]=negative [s04-tiny-steps]=tiny )
declare -A EXP_PLOTS=( [s01-limits]=5 [s02-long]=32 \
                       [s03-out-of-range]=5 [s04-tiny-steps]=18 )
declare -A EXP_PATHS=( [s01-limits]=4 [s02-long]=32 \
                       [s03-out-of-range]=4 [s04-tiny-steps]=16 )
declare -A EXP_W=( [s01-limits]=5001 [s02-long]=4802 \
                   [s03-out-of-range]=402 [s04-tiny-steps]=114 )
declare -A EXP_H=( [s01-limits]=7501 [s02-long]=6301 \
                   [s03-out-of-range]=501 [s04-tiny-steps]=109 )

BENSON_ALPHABET='6501 6502 6504 6511 6512 6514'

for f in "$DISPAK" "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" \
         "$REF2148" "$NITI_2348"; do
    [ -f "$f" ] || { echo "FAIL: нет обязательного файла: $f" >&2; exit 2; }
done
for name in "${CASES[@]}"; do
    [ -f "$HERE/$name.b6" ] || { echo "FAIL: нет деки: $HERE/$name.b6" >&2; exit 2; }
done
if ! grep -a -q -F 'BESM6_DUDKA_PLOT' "$DISPAK"; then
    echo "FAIL: в $DISPAK нет маркера BESM6_DUDKA_PLOT"
    echo "  бэкенд БЕНСОН не собран; результаты не выдумываются"
    exit 3
fi

mkdir -p "$TMP_BASE" || exit 2
WORK=$(mktemp -d "$TMP_BASE/plotter-figure-stress.XXXXXX") || exit 2
if [ -z "${KEEP_WORK:-}" ]; then trap 'rm -rf "$WORK"' EXIT; fi
mkdir -p "$WORK/disks" "$WORK/rows" "$WORK/run"
cp "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" "$REF2148" "$WORK/disks/"
cp "$NITI_2348" "$WORK/disks/2348"

echo "=== Стресс-тесты графопостроителя (figure stress) ==="
echo "dispak   : $DISPAK"
echo "disk2348 : $NITI_2348"
echo "decks    : $HERE"
echo "env      : BESM6_DUDKA_PLOT=benson BESM6_DUDKA_TEST=1 BESM6_DUBNA_PLOT_KEEP=1"
echo "workdir  : $WORK"
echo "note     : $MARKER, не протокол НИТИ/БЭСМ-6"
echo

FMT='%-17s %-8s %-4s %-4s %-4s %-6s %-5s %-4s %-4s %-4s %-5s %-10s %-12s %-12s %s'
printf "$FMT\n" CASE KIND SUM END ERR NPLOT FRAMES OUT SVG DET PATHS SIZE OUT-SHA-12 SVG-SHA-12 RESULT
printf "$FMT\n" ---- ---- --- --- --- ----- ------ --- --- --- ----- ---- ----------- ----------- ------

declare -A A_SUM A_END A_ERR A_NPLOT A_FRAMES A_OUT A_SVG A_DET A_PATH A_SIZE A_OSHA A_SSHA A_OK
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

        [ "$rc" -eq 0 ] || why="$why [r$round: rc=$rc]"
        grep -a -q -F 'NITI: summary' "$out" || why="$why [r$round: нет NITI: summary]"
        grep -a -q -F 'КОНЕЦ ЗАДАЧИ' "$out" || why="$why [r$round: нет КОНЕЦ ЗАДАЧИ]"
        if grep -a -q -E "$FATAL_RE" "$out"; then
            why="$why [r$round: ОШ/ERR в логе]"
        fi
        grep -a -q -F "$MARKER" "$out" || why="$why [r$round: нет пометки аналога]"

        nplot=$(grep -a 'NITI-STRESS NPLOT=' "$out" 2>/dev/null | grep -a -v FORMAT \
                | tail -1 | sed -n 's/.*NPLOT= *\([0-9]*\).*/\1/p')
        frames=$(grep -a -m1 'NITI: summary' "$out" 2>/dev/null \
                 | sed -n 's/.*frames=\([0-9]*\).*/\1/p')
        [ "${nplot:-?}" = "${EXP_PLOTS[$name]}" ] || \
            why="$why [r$round: NPLOT=${nplot:-?} != ${EXP_PLOTS[$name]}]"
        [ "${frames:-?}" = "${EXP_PLOTS[$name]}" ] || \
            why="$why [r$round: frames=${frames:-?} != ${EXP_PLOTS[$name]}]"
        printf '%s\n' "${nplot:-?}/${frames:-?}" > "$WORK/rows/$name-count-r$round"

        # Отрицательный контроль требует ровно одну строку отбрасывания.
        oor=$(grep -a -c 'DUDKA: BENSON coords out of range X=6000 Y=400' \
              "$out" 2>/dev/null || true)
        [ -n "$oor" ] || oor=0
        if [ "${KIND[$name]}" = negative ]; then
            [ "$oor" -eq 1 ] || why="$why [r$round: out-of-range log=$oor != 1]"
        else
            [ "$oor" -eq 0 ] || why="$why [r$round: неожиданный out-of-range log=$oor]"
        fi
        printf '%s\n' "$oor" > "$WORK/rows/$name-oor-r$round"

        if [ -s "$rundir/benson.out" ]; then
            printf '%s\n' "$(sha256sum "$rundir/benson.out" | cut -d' ' -f1)" \
                > "$WORK/rows/$name-out-r$round"
            # Алфавит команд БЕНСОНа проверяется на s01 (самая длинная история шагов).
            if [ "${KIND[$name]}" = limits ]; then
                codes=$(awk '{print $1}' "$rundir/benson.out" | sed 's/^0*//' | sort -u \
                        | tr '\n' ' ')
                [ -n "$codes" ] || why="$why [r$round: пустой алфавит benson.out]"
                for c in $codes; do
                    case " $BENSON_ALPHABET " in
                        *" $c "*) ;;
                        *) why="$why [r$round: команда 0$c вне алфавита 065xx]" ;;
                    esac
                done
                printf '%s\n' "$codes" > "$WORK/rows/$name-alphabet-r$round"
            fi
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
            [ "$np" -eq "${EXP_PATHS[$name]}" ] || \
                why="$why [r$round: paths=$np != ${EXP_PATHS[$name]}]"
            printf '%s\n' "$(sha256sum "$svg" | cut -d' ' -f1)" \
                > "$WORK/rows/$name-svg-r$round"
            if [ "$round" -eq 1 ]; then
                svgline=$(grep -a -m1 '<svg' "$svg")
                w=$(printf '%s\n' "$svgline" | sed -n 's/.* width="\([0-9][0-9]*\)".*/\1/p')
                h=$(printf '%s\n' "$svgline" | sed -n 's/.* height="\([0-9][0-9]*\)".*/\1/p')
                # Допуск +/-2: r1 дал 5003x7501 при ожидаемых ~5001x7501.
                if [ -z "$w" ] || [ -z "$h" ] || \
                   [ "$(( ${w:-0} - ${EXP_W[$name]} ))" -gt 2 ] 2>/dev/null || \
                   [ "$(( ${EXP_W[$name]} - ${w:-0} ))" -gt 2 ] 2>/dev/null || \
                   [ "$(( ${h:-0} - ${EXP_H[$name]} ))" -gt 2 ] 2>/dev/null || \
                   [ "$(( ${EXP_H[$name]} - ${h:-0} ))" -gt 2 ] 2>/dev/null; then
                    why="$why [r1: размер SVG ${w:-?}x${h:-?} вне +/-2 от ${EXP_W[$name]}x${EXP_H[$name]}]"
                fi
                A_PATH[$name]=$np
                A_SIZE[$name]=${w:-?}x${h:-?}
                grep -a '<path' "$svg" > "$WORK/rows/$name-paths"
                cp "$svg" "$WORK/rows/$name.svg"
            fi
        else
            why="$why [r$round: нет или пуст benson.svg]"
        fi
    done

    s1=Y; e1=Y; err1=Y
    grep -a -q -F 'NITI: summary' "$WORK/run/$name-r1/out.txt" || s1=N
    grep -a -q -F 'КОНЕЦ ЗАДАЧИ' "$WORK/run/$name-r1/out.txt" || e1=N
    grep -a -q -E "$FATAL_RE" "$WORK/run/$name-r1/out.txt" && err1=N
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

    A_SUM[$name]=$s1; A_END[$name]=$e1; A_ERR[$name]=$err1
    A_OUT[$name]=$o1; A_SVG[$name]=$v1; A_DET[$name]=$det
    A_OSHA[$name]=$(cut -c1-12 "$WORK/rows/$name-out-r1" 2>/dev/null || echo -)
    A_SSHA[$name]=$(cut -c1-12 "$WORK/rows/$name-svg-r1" 2>/dev/null || echo -)
    [ -n "${A_OSHA[$name]}" ] || A_OSHA[$name]=-
    [ -n "${A_SSHA[$name]}" ] || A_SSHA[$name]=-

    if [ -z "$why" ]; then ok=1; result=PASS; passed=$((passed+1))
    else ok=0; result=FAIL; failed=$((failed+1)); fi
    A_OK[$name]=$ok

    count=$(cat "$WORK/rows/$name-count-r1" 2>/dev/null || echo '?/?')
    nplot1=${count%/*}
    frames1=${count#*/}
    printf "$FMT\n" "$name" "${KIND[$name]}" "$s1" "$e1" "$err1" \
        "$nplot1" "$frames1" \
        "$o1" "$v1" "$det" "${A_PATH[$name]:-?}" "${A_SIZE[$name]:-?}" \
        "${A_OSHA[$name]}" "${A_SSHA[$name]}" "$result"
    printf '%s|%s|%s|%s|%s|%s|%s|%s|%s\n' "$name" "${KIND[$name]}" \
        "$s1" "$e1" "$err1" "$det" "${A_PATH[$name]:-?}" \
        "${A_SIZE[$name]:-?}" "$result" >> "$WORK/summary.csv"
    printf '%s: %s\n' "$name" "$why" > "$WORK/rows/$name-why"
done

echo
echo "=== Детали ==="
for name in "${CASES[@]}"; do
    printf '%-17s kind=%-8s oor=%s/%s paths=%s ( ожидалось %s ) svg=%s out=%s svg-sha=%s\n' \
        "$name" "${KIND[$name]}" \
        "$(cat "$WORK/rows/$name-oor-r1" 2>/dev/null || echo ?)" \
        "$(cat "$WORK/rows/$name-oor-r2" 2>/dev/null || echo ?)" \
        "${A_PATH[$name]:-?}" "${EXP_PATHS[$name]}" "${A_SIZE[$name]:-?}" \
        "$(cat "$WORK/rows/$name-out-r1" 2>/dev/null || echo -)" \
        "$(cat "$WORK/rows/$name-svg-r1" 2>/dev/null || echo -)"
    if [ "${KIND[$name]}" = limits ]; then
        printf '  alphabet: %s (06501/06502/06504/06511/06512/06514)\n' \
            "$(cat "$WORK/rows/$name-alphabet-r1" 2>/dev/null || echo ?)"
    fi
    if [ "${A_OK[$name]}" -ne 1 ] || [ -n "${VERBOSE:-}" ]; then
        printf '  why: %s\n' "$(cat "$WORK/rows/$name-why")"
        if [ -f "$WORK/rows/$name-paths" ]; then
            sed 's/^/  /' "$WORK/rows/$name-paths"
        fi
    fi
done

echo
echo "Summary: $passed PASS, $failed FAIL (of ${#CASES[@]} decks)"
echo "Критерий: s01/s02/s04 PASS; s03 PASS как отрицательный контроль"
echo "workdir: $WORK"
[ "$failed" -eq 0 ] && [ "$passed" -eq "${#CASES[@]}" ]
