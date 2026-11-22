#!/bin/bash
# Честное A/B-сравнение родной библиотеки 22 ГРАФОР и Фортран-порта.
#
# Для каждой пары «родная дека / дека порта» обе деки прогоняются через один и
# тот же dispak с одним и тем же окружением БЕНСОНа. Собираются plot.dat,
# benson.out, benson.svg, считаются SHA256, размеры, число кадров и <path>.
# Обязательные инварианты (формат кадра, алфавит команд БЕНСОН,
# детерминированность) сравниваются; координаты, порядок шагов X/Y, число
# кадров и SHA сравнить НЕЛЬЗЯ (разные программы) и не требуется.
#
# Родная сторона не объявляется готовой по умолчанию. Пока SHIM.mad пишет кадр
# из неинициализированного BSS, а в логе есть «ВЫВОД ЗАПРЕЩЕН», раннер печатает
# НЕ ГОТОВО и объясняет причину. Артефакты субагентов A/B ищутся в
# verify/native-decks/ и перекрывают legacy-деку verify/native/native-final.b6.
#
# Все временные файлы живут в /var/tmp. Наследуемый TMPDIR намеренно игнорируется.
# Переменные: DISPAK_BIN, DISKDIR, REF2148, NITI_2348, NATIVE_2348,
# NATIVE_SHIM_B6, NC_TMPDIR, KEEP_WORK, TIMEOUT, VERBOSE.
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)

DISPAK=${DISPAK_BIN:-/home/azizz/Yandex.Disk/dispak/build/dispak/dispak}
DISKDIR=${DISKDIR:-$(dirname "$DISPAK")}
REF2148=${REF2148:-/usr/local/share/besm6/2148}
PORT_2348=${NITI_2348:-$ROOT/fortran/verify/2348-niti.img}
NATIVE_2348=${NATIVE_2348:-/usr/local/share/besm6/2348}
TMP_BASE=${NC_TMPDIR:-/var/tmp}
TIMEOUT=${TIMEOUT:-240}

# Известный SHA кадра из неинициализированного BSS (verify/native/plot.dat,
# подтверждён повторными прогонами 2026-11-22). Сам по себе не тест, а метка
# «родная дека ещё не обновлена».
PLOT_SHA_GARBAGE=15450e0b433bfbc2c2cac11d2528e7a9626f444a0d60b2290c6b325ddff25b2d

# Диспак печатает часть диагностики латиницей: обе транслитерации фатальны.
FATAL_RE='ОШ|ОШИБКА|ОТСУТСТВУЕТ|НЕДОПУСТИМ|НЕТ ТАКОЙ|БЫЛИ ОШИБКИ|ERR [0-9]+|OTCYTCTBYET|OWIBKA|HET TAKO'

DEFAULT_CASES=(C1-line C2-circle C3-text C4-page C5-counters)

usage() {
    cat <<'EOF'
Использование: ./run.sh [КЛЮЧ ...]

Без аргументов прогоняются пары C1-line C2-circle C3-text C4-page C5-counters.
КЛЮЧ - имя деки порта (например C1-line); родная дека ищется в
  verify/native-decks/<ключ>.b6
  verify/native-decks/<ключ>-native.b6
  verify/native-decks/native-<ключ>.b6
и только для C1-line - legacy verify/native/native-final.b6.

Переменные окружения:
  DISPAK_BIN, DISKDIR, REF2148, NITI_2348, NATIVE_2348,
  NATIVE_SHIM_B6, NC_TMPDIR, KEEP_WORK, TIMEOUT, VERBOSE
EOF
}

case "${1:-}" in
    -h|--help) usage; exit 0 ;;
esac

CASES=("$@")
[ "${#CASES[@]}" -gt 0 ] || CASES=("${DEFAULT_CASES[@]}")

for f in "$DISPAK" "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" \
         "$REF2148" "$PORT_2348" "$NATIVE_2348"; do
    [ -f "$f" ] || { echo "FAIL: нет обязательного файла: $f" >&2; exit 2; }
done

# Честная проверка бэкенда: без собранного БЕНСОНа benson.out/benson.svg не пишутся
# и результаты не выдумываются.
if ! grep -a -q -F 'BESM6_DUDKA_PLOT' "$DISPAK"; then
    echo "FAIL: в $DISPAK нет маркера BESM6_DUDKA_PLOT" >&2
    echo "  БЕНСОН-бэкенд не собран, прогон остановлен" >&2
    exit 3
fi
for deck in "${CASES[@]}"; do
    [ -f "$ROOT/verify/$deck.b6" ] || {
        echo "FAIL: нет деки порта: $ROOT/verify/$deck.b6" >&2; exit 2; }
done

mkdir -p "$TMP_BASE" || exit 2
WORK=$(mktemp -d "$TMP_BASE/native-compare.XXXXXX") || exit 2
if [ -z "${KEEP_WORK:-}" ]; then trap 'rm -rf "$WORK"' EXIT; fi
mkdir -p "$WORK/disks-port" "$WORK/disks-native" "$WORK/rows" "$WORK/run"

cp "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" "$REF2148" "$WORK/disks-port/"
cp "$PORT_2348" "$WORK/disks-port/2348"
cp "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" "$REF2148" "$WORK/disks-native/"
cp "$NATIVE_2348" "$WORK/disks-native/2348"

# --- разрешение путей -------------------------------------------------------

NATIVE_DECK=
LEGACY=0
resolve_native() {
    key=$1
    local c
    for c in "$HERE/native/$key.b6" \
             "$HERE/native/$key-native.b6" \
             "$ROOT/verify/native-decks/$key.b6" \
             "$ROOT/verify/native-decks/$key-native.b6" \
             "$ROOT/verify/native-decks/native-$key.b6"; do
        if [ -f "$c" ]; then NATIVE_DECK=$c; LEGACY=0; return 0; fi
    done
    if [ "$key" = C1-line ] && [ -f "$ROOT/verify/native/native-final.b6" ]; then
        NATIVE_DECK=$ROOT/verify/native/native-final.b6
        LEGACY=1
        return 0
    fi
    NATIVE_DECK=
    LEGACY=0
    return 1
}

SHIM_B6=${NATIVE_SHIM_B6:-}
if [ -z "$SHIM_B6" ]; then
    for c in "$ROOT/verify/native-decks/shim.b6" "$ROOT/verify/native/shim.b6"; do
        if [ -f "$c" ]; then SHIM_B6=$c; break; fi
    done
fi
SHIM_MAD=$ROOT/verify/native/SHIM.mad
[ -f "$SHIM_MAD" ] || SHIM_MAD=

shim_writes_coords() {
    # Эвристика готовности исходника: обновлённый SHIM должен либо хранить
    # координаты в BUFPL, либо явно помечать это в исходнике.
    local f=$1
    grep -a -q -E '(ATX|STX|BS|VTM)[^ ]*.*BUFPL|БУФЕР КООРДИНАТ|COORD|КООРДИНАТ' "$f"
}

# --- прогон одной деки ------------------------------------------------------

run_deck() {
    local rundir=$1 deck=$2 disks=$3
    mkdir -p "$rundir"
    cp "$DISPAK" "$rundir/dispak" || return 2
    chmod +x "$rundir/dispak"
    local base
    base=$(basename "$deck")
    cp "$deck" "$rundir/$base" || return 2
    # Сопутствующие МАДЛЕН/деки (если A/B разложили их рядом).
    local d
    d=$(dirname "$deck")
    for f in "$d"/*.b6 "$d"/*.mad; do
        [ -f "$f" ] || continue
        [ "$(basename "$f")" = "$base" ] && continue
        cp "$f" "$rundir/" 2>/dev/null || true
    done
    if command -v timeout >/dev/null 2>&1; then
        cmd=(timeout "$TIMEOUT" ./dispak -l "$base")
    else
        cmd=(./dispak -l "$base")
    fi
    ( cd "$rundir" && BESM6_PATH="$disks" \
        BESM6_DUDKA_PLOT=benson BESM6_DUDKA_TEST=1 \
        BESM6_DUBNA_PLOT_KEEP=1 \
        "${cmd[@]}" > out.txt 2>&1 )
    echo $? > "$rundir/rc"
}

# --- сбор метрик в $WORK/rows/<key>-<side>-r<round>.metrics ---------------------

collect() {
    local key=$1 side=$2 round=$3 rundir=$4
    local out=$rundir/out.txt m=$WORK/rows/$key-$side-r$round
    local rc=-
    [ -f "$rundir/rc" ] && rc=$(cat "$rundir/rc")
    local ran=N
    [ "$rc" != 99 ] && ran=Y

    local end=N fatal=N forbidden=N summary=-
    grep -a -q -F 'КОНЕЦ ЗАДАЧИ' "$out" 2>/dev/null && end=Y
    grep -a -q -E "$FATAL_RE" "$out" 2>/dev/null && fatal=Y
    grep -a -q -F 'ВЫВОД ЗАПРЕЩЕН' "$out" 2>/dev/null && forbidden=Y
    summary=$(grep -a -m1 'NITI: summary' "$out" 2>/dev/null | sed 's/^ *//')
    [ -n "$summary" ] || summary=-

    local plot_sha=- plot_bytes=- plot_lines=- frames=- fmt_ok=N zero_frames=0
    if [ -s "$rundir/plot.dat" ]; then
        plot_bytes=$(stat -c %s "$rundir/plot.dat")
        plot_sha=$(sha256sum "$rundir/plot.dat" | cut -d' ' -f1)
        plot_lines=$(wc -l < "$rundir/plot.dat")
        fmt_ok=Y
        if [ $((plot_lines % 64)) -ne 0 ]; then fmt_ok=N; fi
        local bad
        bad=$(grep -a -v -E '^([0-7]{2} ){7}[0-7]{2} *$' "$rundir/plot.dat" | wc -l)
        [ "$bad" -eq 0 ] || fmt_ok=N
        if [ "$fmt_ok" = Y ]; then
            frames=$((plot_lines / 64))
            zero_frames=$(awk 'NR%64==1{f=1;z=1} /[1-7]/{z=0} NR%64==0{if(z)zf++} END{print zf+0}' \
                "$rundir/plot.dat")
        else
            frames=BAD
        fi
    fi

    local out_sha=- out_bytes=- out_lines=0 out_codes=- out_ok=N
    if [ -s "$rundir/benson.out" ]; then
        out_sha=$(sha256sum "$rundir/benson.out" | cut -d' ' -f1)
        out_bytes=$(stat -c %s "$rundir/benson.out")
        out_lines=$(wc -l < "$rundir/benson.out")
        out_codes=$(awk '{print $1}' "$rundir/benson.out" | sort -u | tr '\n' ',' | sed 's/,$//')
        out_ok=Y
        local badcode badmark
        badcode=$(grep -a -v -E '^0?65[0-9][0-9] ' "$rundir/benson.out" | wc -l)
        badmark=$(grep -a -v -F '[аналог NASA' "$rundir/benson.out" | wc -l)
        [ "$badcode" -eq 0 ] && [ "$badmark" -eq 0 ] || out_ok=N
    fi

    local svg_sha=- svg_bytes=- svg_paths=0 svg_w=? svg_h=? svg_ok=N
    if [ -s "$rundir/benson.svg" ]; then
        svg_sha=$(sha256sum "$rundir/benson.svg" | cut -d' ' -f1)
        svg_bytes=$(stat -c %s "$rundir/benson.svg")
        svg_paths=$(grep -a -c '<path' "$rundir/benson.svg" 2>/dev/null || true)
        [ -n "$svg_paths" ] || svg_paths=0
        local line
        line=$(grep -a -m1 '<svg' "$rundir/benson.svg")
        svg_w=$(printf '%s\n' "$line" | sed -n 's/.* width="\([0-9][0-9]*\)".*/\1/p')
        svg_h=$(printf '%s\n' "$line" | sed -n 's/.* height="\([0-9][0-9]*\)".*/\1/p')
        [ -n "$svg_w" ] || svg_w=?
        [ -n "$svg_h" ] || svg_h=?
        svg_ok=N
        if [ "$(head -n 1 "$rundir/benson.svg" | cut -c1-5)" = '<?xml' ] && [ "$svg_paths" -ge 1 ]; then
            svg_ok=Y
        fi
    fi

    {
        echo "rc=$rc"
        echo "ran=$ran"
        echo "end=$end"
        echo "fatal=$fatal"
        echo "forbidden=$forbidden"
        echo "summary=$summary"
        echo "plot_sha=$plot_sha"
        echo "plot_bytes=$plot_bytes"
        echo "plot_lines=$plot_lines"
        echo "frames=$frames"
        echo "fmt_ok=$fmt_ok"
        echo "zero_frames=$zero_frames"
        echo "out_sha=$out_sha"
        echo "out_bytes=$out_bytes"
        echo "out_lines=$out_lines"
        echo "out_codes=$out_codes"
        echo "out_ok=$out_ok"
        echo "svg_sha=$svg_sha"
        echo "svg_bytes=$svg_bytes"
        echo "svg_paths=$svg_paths"
        echo "svg_w=$svg_w"
        echo "svg_h=$svg_h"
        echo "svg_ok=$svg_ok"
    } > "$m.metrics"
}

metric() {
    local f=$1 k=$2
    grep -a -m1 "^$k=" "$f" 2>/dev/null | cut -d= -f2-
}

det_for() {
    local key=$1 side=$2
    local a=$WORK/rows/$key-$side-r1.metrics b=$WORK/rows/$key-$side-r2.metrics
    local k
    [ "$(metric "$a" ran)" = Y ] && [ "$(metric "$b" ran)" = Y ] || { echo N; return; }
    for k in plot_sha out_sha svg_sha; do
        [ "$(metric "$a" "$k")" = "$(metric "$b" "$k")" ] || { echo N; return; }
    done
    echo Y
}

# --- заголовок --------------------------------------------------------------

echo "=== Родная библиотека 22 vs Фортран-порт: честное сравнение ==="
echo "dispak      : $DISPAK"
echo "native 2348 : $NATIVE_2348"
echo "port   2348 : $PORT_2348"
echo "shim        : ${SHIM_B6:-НЕТ}"
echo "env         : BESM6_DUDKA_PLOT=benson BESM6_DUDKA_TEST=1 BESM6_DUBNA_PLOT_KEEP=1"
echo "workdir     : $WORK"
echo "пары        : ${CASES[*]}"
echo

# Сборка прослойки в PERSO 0o2700 на родном диске (один раз на весь прогон).
SHIM_READY=N
if [ -z "$SHIM_B6" ] || [ ! -f "$SHIM_B6" ]; then
    echo "FAIL: нет деки сборки SHIM (нативная shim.b6); родная сторона не готова"
else
    cp "$SHIM_B6" "$WORK/shim.b6"
    cp "$DISPAK" "$WORK/dispak-shim" && chmod +x "$WORK/dispak-shim"
    if command -v timeout >/dev/null 2>&1; then
        shimcmd=(timeout "$TIMEOUT" ./dispak-shim -l shim.b6)
    else
        shimcmd=(./dispak-shim -l shim.b6)
    fi
    ( cd "$WORK" && BESM6_PATH="$WORK/disks-native" "${shimcmd[@]}" \
        > shim-build.log 2>&1 )
    if [ "$?" -eq 0 ] && grep -a -q -F 'КОНЕЦ ЗАДАЧИ' "$WORK/shim-build.log"; then
        SHIM_READY=Y
    else
        echo "FAIL: сборка SHIM в PERSO 0o2700 не удалась, см. $WORK/shim-build.log"
    fi
fi

FMT='%-11s %-7s %-4s %-5s %-5s %-5s %-13s %-7s %-9s %-13s %-5s %-9s %-3s %s'
hdr() { printf "$FMT\n" "$@"; }
hdr PAIR SIDE ROUND END ERR FORB PLOT-SHA-12 FRAMES PLOT-B OUT-SHA-12 CMDS SVG-PATHS DET RESULT
hdr ----------- ------- ------ ----- ----- ----- ------------- ------- --------- ------------- ----- --------- --- ------

total=0; compatible=0; notready=0; mismatch=0

for key in "${CASES[@]}"; do
    resolve_native "$key" || NATIVE_DECK=
    port_deck=$ROOT/verify/$key.b6

    for side in native port; do
        deck=$port_deck; disks=$WORK/disks-port
        [ "$side" = native ] && { deck=$NATIVE_DECK; disks=$WORK/disks-native; }
        for round in 1 2; do
            rundir=$WORK/run/$key-$side-r$round
            if [ "$side" = native ] && { [ "$SHIM_READY" != Y ] || [ -z "$deck" ]; }; then
                # Не запускаем: честно помечаем отсутствие артефакта.
                mkdir -p "$rundir"; : > "$rundir/out.txt"; echo 99 > "$rundir/rc"
            else
                run_deck "$rundir" "$deck" "$disks" || true
            fi
            collect "$key" "$side" "$round" "$rundir"
            det=$(det_for "$key" "$side")
            f=$WORK/rows/$key-$side-r$round.metrics
            if [ "$round" -eq 1 ]; then
                side_ok=N
                if [ "$(metric "$f" end)" = Y ] && [ "$(metric "$f" fatal)" = N ] && \
                   [ "$(metric "$f" fmt_ok)" = Y ] && [ "$(metric "$f" out_ok)" = Y ] && \
                   [ "$(metric "$f" svg_ok)" = Y ]; then side_ok=Y; fi
                n1=$side_ok
            else
                side_ok=$n1
                [ "$det" = Y ] || side_ok=N
            fi
            psha=$(metric "$f" plot_sha); [ "$psha" = - ] || psha=${psha:0:12}
            osha=$(metric "$f" out_sha); [ "$osha" = - ] || osha=${osha:0:12}
            det_str=-; [ "$round" -eq 2 ] && det_str=$det
            hdr "$key" "$side" "r$round" \
                "$(metric "$f" end)" "$(metric "$f" fatal)" "$(metric "$f" forbidden)" \
                "$psha" "$(metric "$f" frames)" "$(metric "$f" plot_bytes)" "$osha" \
                "$(metric "$f" out_lines)" "$(metric "$f" svg_paths)" "$det_str" "$side_ok"
        done
    done

    # --- вердикт по паре -----------------------------------------------------

    nf=$WORK/rows/$key-native-r1.metrics
    pf=$WORK/rows/$key-port-r1.metrics
    nready=Y; why=""
    if [ -z "$NATIVE_DECK" ]; then
        nready=N; why="$why; нет родной деки для $key"
    fi
    if [ "$SHIM_READY" != Y ]; then
        nready=N; why="$why; SHIM не собран в 0o2700"
    fi
    if [ "$LEGACY" -eq 1 ]; then
        if [ -n "$SHIM_MAD" ] && grep -a -q -F 'BSS,64' "$SHIM_MAD" && \
           ! shim_writes_coords "$SHIM_MAD"; then
            nready=N; why="$why; SHIM.mad всё ещё BSS-only (координаты не пишутся в кадр)"
        fi
    fi
    if [ "$(metric "$nf" forbidden)" = Y ]; then
        nready=N; why="$why; ВЫВОД ЗАПРЕЩЕН в логе родной деки"
    fi
    if [ "$(metric "$nf" plot_sha)" = "$PLOT_SHA_GARBAGE" ]; then
        nready=N; why="$why; plot.dat = SHA неинициализированного BSS"
    fi
    if [ "$(metric "$nf" zero_frames)" != 0 ] && [ "$(metric "$nf" zero_frames)" != - ]; then
        nready=N; why="$why; кадр(ы) из нулей в plot.dat"
    fi
    ndet=$(det_for "$key" native); pdet=$(det_for "$key" port)
    if [ "$ndet" != Y ] && [ "$(metric "$nf" ran)" = Y ]; then
        nready=N; why="$why; родная сторона недетерминирована"
    fi
    [ "$pdet" = Y ] || why="$why; порт недетерминирован"
    if [ "$(metric "$pf" out_ok)" != Y ]; then
        why="$why; у порта нет корректного benson.out"
    fi
    if [ "$(metric "$pf" svg_ok)" != Y ]; then
        why="$why; у порта нет benson.svg с <path>"
    fi

    fmtcmp=N
    if [ "$(metric "$nf" fmt_ok)" = Y ] && [ "$(metric "$pf" fmt_ok)" = Y ]; then fmtcmp=Y; fi
    ncodes=$(metric "$nf" out_codes); pcodes=$(metric "$pf" out_codes)
    if [ "$(metric "$nf" out_ok)" != Y ] && [ "$(metric "$pf" out_ok)" != Y ]; then
        cmdcmp='N/A'
    elif [ -n "$ncodes" ] && [ "$ncodes" != - ] && [ "$ncodes" = "$pcodes" ]; then
        cmdcmp=Y
    else
        cmdcmp=N
    fi

    port_ok=N
    if [ "$(metric "$pf" end)" = Y ] && [ "$(metric "$pf" fatal)" = N ] && \
       [ "$(metric "$pf" fmt_ok)" = Y ] && [ "$(metric "$pf" out_ok)" = Y ] && \
       [ "$(metric "$pf" svg_ok)" = Y ] && [ "$pdet" = Y ]; then port_ok=Y; fi

    if [ "$nready" != Y ]; then verdict='НЕ ГОТОВО'; notready=$((notready+1))
    elif [ "$port_ok" = Y ] && [ "$fmtcmp" = Y ] && [ "$cmdcmp" = Y ] && [ "$ndet" = Y ]; then
        verdict='СОВМЕСТИМО'; compatible=$((compatible+1))
    else
        verdict='РАСХОЖДЕНИЕ'; mismatch=$((mismatch+1))
    fi
    total=$((total+1))

    printf '%-11sNATIVE-READY=%-3s FMT=%s CMD=%s DET(n/p)=%s/%s PORT-OK=%s NATIVE-SHA=%-13s PORT-SHA=%-13s %s\n' \
        "$key" "$nready" "$fmtcmp" "$cmdcmp" "$ndet" "$pdet" "$port_ok" \
        "$(metric "$nf" plot_sha | cut -c1-12)" "$(metric "$pf" plot_sha | cut -c1-12)" "$verdict"
    if [ "$verdict" != 'СОВМЕСТИМО' ]; then
        why2=${why#; }
        [ -n "$why2" ] || why2="см. колонки таблицы выше; алфавит команд n=$ncodes p=$pcodes"
        printf '  why:%s\n' "$why2"
    fi
    if [ -n "${VERBOSE:-}" ]; then
        printf '  native: %s\n' "$(metric "$nf" summary)"
        printf '  port  : %s\n' "$(metric "$pf" summary)"
    fi
done

echo
echo "Summary: $compatible СОВМЕСТИМО, $notready НЕ ГОТОВО, $mismatch РАСХОЖДЕНИЕ (всего $total)"
echo "Не требуются равными: координаты, порядок шагов X/Y, число кадров, SHA256, размер SVG."
echo "workdir: $WORK"
[ "$notready" -eq 0 ] && [ "$mismatch" -eq 0 ]
