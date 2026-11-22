#!/bin/bash
# Low-level NITI extract-code tests (B2 functional layer) for the dispak emulator.
# Complements the stage-C FOREX tests verify/C1-C5: these decks call E50
# extract codes 01210/01216/01217 (scheme select) and 01211 (frame writer)
# directly from MADLEN, without the Fortran PERSO library.
#
# Overrides: DISPAK_BIN, DISKDIR, REF2148, TMPDIR, KEEP_WORK=1, TIMEOUT, VERBOSE=1.
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
DISPAK=${DISPAK_BIN:-/home/azizz/Yandex.Disk/dispak/build/dispak/dispak}
DISKDIR=${DISKDIR:-$(dirname "$DISPAK")}
REF2148=${REF2148:-/usr/local/share/besm6/2148}
TMP_BASE=${TMPDIR:-/tmp/.private/azizz/opencode}
TIMEOUT=${TIMEOUT:-240}

# Dispak prints some monitor diagnostics in Latin transliteration of Cyrillic
# ("OTCYTCTBYET" = "ОТСУТСТВУЕТ"), so both spellings are fatal here.
FATAL_RE='ОШ|ОШИБКА|ОТСУТСТВУЕТ|НЕДОПУСТИМ|НЕТ ТАКОЙ|БЫЛИ ОШИБКИ|ERR [0-9]+|OTCYTCTBYET|OWIBKA|HET TAKO'

CASES=(
    t01-select-1210.b6
    t02-frame.b6
    t03-two-frames.b6
    t04-scheme-1216.b6
    t05-scheme-1217.b6
    t06-legacy-71717.b6
)

# Expected scheme line (empty for the legacy path), exact summary line,
# plot.dat expectation "lines:bytes:sha256" or "absent".
expect() {
    case "$1" in
        t01-select-1210)
            EXP_SCHEME='1210'
            EXP_SUMMARY='NITI: summary schemes=1 frames=0 words=0 active=1 scheme=1210'
            EXP_PLOT='absent' ;;
        t02-frame)
            EXP_SCHEME='1210'
            EXP_SUMMARY='NITI: summary schemes=1 frames=1 words=64 active=1 scheme=1210'
            EXP_PLOT='64:1600:27440f92e4c5039ed011d678d0fe2fbbab945fde8f05d4d415c8eba6c80db498' ;;
        t03-two-frames)
            EXP_SCHEME='1210'
            EXP_SUMMARY='NITI: summary schemes=1 frames=2 words=128 active=1 scheme=1210'
            EXP_PLOT='128:3200:0ef90c9dfd06f24a4fdf21be4c4f616b938a17bdbec1a36bc80dbd7042ddb8a2' ;;
        t04-scheme-1216)
            EXP_SCHEME='1216'
            EXP_SUMMARY='NITI: summary schemes=1 frames=1 words=64 active=1 scheme=1216'
            EXP_PLOT='64:1600:27440f92e4c5039ed011d678d0fe2fbbab945fde8f05d4d415c8eba6c80db498' ;;
        t05-scheme-1217)
            EXP_SCHEME='1217'
            EXP_SUMMARY='NITI: summary schemes=1 frames=1 words=64 active=1 scheme=1217'
            EXP_PLOT='64:1600:27440f92e4c5039ed011d678d0fe2fbbab945fde8f05d4d415c8eba6c80db498' ;;
        t06-legacy-71717)
            EXP_SCHEME=''
            EXP_SUMMARY='NITI: summary schemes=0 frames=1 words=64 active=0 scheme=0000'
            EXP_PLOT='64:1600:645a196a44165dad84b491dcab8467dd628519269f1adb661d1e0927b7b44d6b' ;;
    esac
}

for f in "$DISPAK" "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" "$REF2148"; do
    [ -f "$f" ] || { echo "FAIL: missing prerequisite: $f" >&2; exit 2; }
done

mkdir -p "$TMP_BASE" || exit 2
WORK=$(mktemp -d "$TMP_BASE/niti-lowlevel.XXXXXX") || exit 2
if [ -z "${KEEP_WORK:-}" ]; then trap 'rm -rf "$WORK"' EXIT; fi

mkdir -p "$WORK/disks"
cp "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" "$REF2148" "$WORK/disks/"

echo "=== NITI low-level extract-code tests ==="
echo "dispak : $DISPAK"
echo "disks  : $DISKDIR (2048/2053/2099), $REF2148 (2148)"
echo "workdir: $WORK"
echo

printf '%-22s %-7s %-5s %-5s %-4s %-6s %-8s %-12s %s\n' \
    CASE SCHEME SUMMARY PLOT END NOERR BYTES SHA256-12 RESULT
printf '%-22s %-7s %-5s %-5s %-4s %-6s %-8s %-12s %s\n' \
    ---------------------- ------- ----- ----- ---- ------ -------- ------------ ------

passed=0
failed=0
for deck in "${CASES[@]}"; do
    name=${deck%.b6}
    expect "$name"
    rundir="$WORK/run/$name"
    mkdir -p "$rundir"
    cp "$DISPAK" "$rundir/dispak" && chmod +x "$rundir/dispak"
    cp "$HERE/$deck" "$rundir/"

    if command -v timeout >/dev/null 2>&1; then
        cmd=(timeout "$TIMEOUT" ./dispak -l "$deck")
    else
        cmd=(./dispak -l "$deck")
    fi
    ( cd "$rundir" && BESM6_PATH="$WORK/disks" "${cmd[@]}" > out.txt 2>&1 )
    rc=$?
    out="$rundir/out.txt"

    scheme=N; summary=N; plot=N; end=N; noerr=Y; ok=1

    if [ -n "$EXP_SCHEME" ]; then
        if grep -a -q -F "NITI: scheme $EXP_SCHEME selected" "$out"; then scheme=Y; else ok=0; fi
    else
        if grep -a -q 'NITI: scheme [0-7]* selected' "$out"; then scheme=BAD; ok=0; else scheme=NA; fi
    fi

    if grep -a -q -F "$EXP_SUMMARY" "$out"; then summary=Y; else ok=0; fi
    grep -a -q 'КОНЕЦ ЗАДАЧИ' "$out" && end=Y || ok=0
    if grep -a -q -E "$FATAL_RE" "$out"; then noerr=N; ok=0; fi

    exp_lines=${EXP_PLOT%%:*}
    rest=${EXP_PLOT#*:}
    exp_bytes=${rest%%:*}
    exp_sha=${rest##*:}
    bytes=-; sha=-
    if [ "$EXP_PLOT" = absent ]; then
        if [ -e "$rundir/plot.dat" ]; then plot=BAD; ok=0; else plot=NA; fi
    else
        if [ -f "$rundir/plot.dat" ]; then
            bytes=$(stat -c %s "$rundir/plot.dat" 2>/dev/null || echo '?')
            sha=$(sha256sum "$rundir/plot.dat" 2>/dev/null | cut -d' ' -f1)
            lines=$(wc -l < "$rundir/plot.dat" 2>/dev/null || echo '?')
            # Every frame line must be eight two-digit octal groups.
            struct=$(awk 'BEGIN{ok=1} {if (NF!=8) ok=0; for(i=1;i<=NF;i++) if ($i !~ /^[0-7][0-7]$/) ok=0} END{print ok?"Y":"N"}' "$rundir/plot.dat")
            if [ "$bytes" = "$exp_bytes" ] && [ "$sha" = "$exp_sha" ] &&
               [ "$lines" = "$exp_lines" ] && [ "$struct" = Y ]; then
                plot=Y
            else
                plot=N; ok=0
            fi
        else
            plot=N; ok=0
        fi
    fi

    if [ "$ok" -eq 1 ]; then result=PASS; passed=$((passed+1)); else result=FAIL; failed=$((failed+1)); fi
    printf '%-22s %-7s %-5s %-5s %-4s %-6s %-8s %-12s %s\n' \
        "$name" "$scheme" "$summary" "$plot" "$end" "$noerr" "$bytes" "${sha:0:12}" "$result"

    if [ "$ok" -ne 1 ] || [ -n "${VERBOSE:-}" ]; then
        echo "    rc=$rc out=$out plot=$rundir/plot.dat"
        echo "    expected: scheme='${EXP_SCHEME:-none}' summary='$EXP_SUMMARY' plot='$EXP_PLOT'"
        grep -a -E 'NITI:|КОНЕЦ ЗАДАЧИ' "$out" 2>/dev/null | head -5 | sed 's/^/    /'
        grep -a -E "$FATAL_RE" "$out" 2>/dev/null | head -5 | sed 's/^/    /'
    fi
done

echo
echo "Summary: $passed PASS, $failed FAIL (of ${#CASES[@]} cases)"
[ "$failed" -eq 0 ]
