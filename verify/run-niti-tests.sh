#!/bin/bash
# Stage C control cases: run the five NITI decks through live FOREX 4.12 in dispak.
# All work happens in a temporary directory; no repository file is modified.
# Overrides: DISPAK_BIN, DISKDIR, REF2148, NITI_2348, NITI_LINES=0|1, KEEP_WORK=1.
set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd)
DISPAK=${DISPAK_BIN:-/home/azizz/Yandex.Disk/dispak/build/dispak/dispak}
DISKDIR=${DISKDIR:-/home/azizz/Yandex.Disk/dispak/build/dispak}
REF2148=${REF2148:-/usr/local/share/besm6/2148}

# The PERSO library built in stage A lives on a working copy of disk 2348.
if [ -n "${NITI_2348:-}" ]; then
    DISK2348=$NITI_2348
elif [ -f "$HOME/.besm6/2348" ]; then
    DISK2348=$HOME/.besm6/2348
elif [ -f "$DISKDIR/2348" ]; then
    DISK2348=$DISKDIR/2348
elif [ -f "$ROOT/fortran/verify/2348" ]; then
    DISK2348=$ROOT/fortran/verify/2348
else
    DISK2348=/usr/local/share/besm6/2348
fi

CASES=(C1-line.b6 C2-circle.b6 C3-text.b6 C4-page.b6 C5-counters.b6)

# Dispak prints part of the monitor diagnostics in a Latin transliteration of
# Cyrillic ("OTCYTCTBYET" = "ОТСУТСТВУЕТ"), so both spellings are fatal.
FATAL_RE='ОШ|ОШИБКА|ОТСУТСТВУЕТ|НЕДОПУСТИМ|НЕТ ТАКОЙ|БЫЛИ ОШИБКИ|ERR [0-9]+|OTCYTCTBYET|OWIBKA|HET TAKO'

for f in "$DISPAK" "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" "$REF2148" "$DISK2348"; do
    [ -f "$f" ] || { echo "FAIL: missing prerequisite: $f" >&2; exit 2; }
done

WORK=$(mktemp -d "${TMPDIR:-/tmp/.private/azizz/opencode}/niti-verify.XXXXXX") || exit 2
if [ -z "${KEEP_WORK:-}" ]; then trap 'rm -rf "$WORK"' EXIT; fi

mkdir -p "$WORK/disks"
cp "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" "$REF2148" "$WORK/disks/"
cp "$DISK2348" "$WORK/disks/2348"

# Stage B2 may emit "NITI:" trace lines. Only require them when the tracing
# is actually present in the sources or in the binary being tested.
NITI_READY=0
SRCDIR=${DISPAK_SOURCE_DIR:-$(dirname "$(dirname "$DISPAK")")/dispak}
case "${NITI_LINES:-auto}" in
    1) NITI_READY=1 ;;
    0) NITI_READY=0 ;;
    *)
        if [ -d "$SRCDIR" ] && grep -R -q -s 'NITI:' "$SRCDIR" --include='*.c' --include='*.h'; then
            NITI_READY=1
        fi
        if grep -a -q 'NITI:' "$DISPAK"; then NITI_READY=1; fi
        ;;
esac

echo "=== NITI stage C control cases ==="
echo "dispak : $DISPAK"
echo "disk2348: $DISK2348"
echo "NITI: lines: $([ "$NITI_READY" -eq 1 ] && echo required || echo 'n/a (stage B not instrumented)')"
echo "workdir: $WORK"
echo

printf '%-15s %-7s %-4s %-7s %-6s %-6s %-9s %-12s %s\n' \
    CASE BANNER END NOERR PLOT NITI BYTES SHA256-12 RESULT
printf '%-15s %-7s %-4s %-7s %-6s %-6s %-9s %-12s %s\n' \
    --------------- ------- ---- ------- ------ ------ --------- ------------ ------

passed=0
failed=0
for deck in "${CASES[@]}"; do
    name=${deck%.b6}
    rundir="$WORK/run/$name"
    mkdir -p "$rundir"
    cp "$DISPAK" "$rundir/dispak" && chmod +x "$rundir/dispak"
    cp "$ROOT/verify/$deck" "$rundir/$deck"

    if command -v timeout >/dev/null 2>&1; then
        cmd=(timeout "${TIMEOUT:-240}" ./dispak -l "$deck")
    else
        cmd=(./dispak -l "$deck")
    fi
    ( cd "$rundir" && BESM6_PATH="$WORK/disks" "${cmd[@]}" > out.txt 2>&1 )
    rc=$?
    out="$rundir/out.txt"

    banner=N; end=N; noerr=Y; plot=N; niti=NA; ok=1
    grep -a -q '4\.12' "$out" && banner=Y || ok=0
    grep -a -q 'КОНЕЦ ЗАДАЧИ' "$out" && end=Y || ok=0
    if grep -a -q -E "$FATAL_RE" "$out"; then noerr=N; ok=0; fi
    if [ -s "$rundir/plot.dat" ]; then plot=Y; else ok=0; fi

    ncnt=$(grep -a -c 'NITI:' "$out" 2>/dev/null || true)
    [ -n "$ncnt" ] || ncnt=0
    if [ "$NITI_READY" -eq 1 ]; then
        if [ "$ncnt" -gt 0 ]; then niti=$ncnt; else niti=N; ok=0; fi
    elif [ "$ncnt" -gt 0 ]; then
        niti=$ncnt
    fi

    bytes=-; sha=-
    if [ -s "$rundir/plot.dat" ]; then
        bytes=$(stat -c %s "$rundir/plot.dat" 2>/dev/null || echo '?')
        sha=$(sha256sum "$rundir/plot.dat" 2>/dev/null | cut -c1-12)
    fi

    if [ "$ok" -eq 1 ]; then result=PASS; passed=$((passed+1)); else result=FAIL; failed=$((failed+1)); fi
    printf '%-15s %-7s %-4s %-7s %-6s %-6s %-9s %-12s %s\n' \
        "$name" "$banner" "$end" "$noerr" "$plot" "$niti" "$bytes" "$sha" "$result"

    if [ "$ok" -ne 1 ] || [ -n "${VERBOSE:-}" ]; then
        echo "    rc=$rc out=$out plot=$rundir/plot.dat"
        grep -a -E "$FATAL_RE" "$out" 2>/dev/null | head -5 | sed 's/^/    /'
        grep -a 'NITI-C' "$out" 2>/dev/null | grep -a -v 'FORMAT(' | head -2 | sed 's/^/    /'
    fi
done

echo
echo "Summary: $passed PASS, $failed FAIL (of ${#CASES[@]} cases)"
[ "$failed" -eq 0 ]
