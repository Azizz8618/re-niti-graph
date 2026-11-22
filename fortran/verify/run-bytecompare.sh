#!/bin/bash
# Byte/word comparison of the FOREX 4.12 Fortran port with library 22 originals.
#
# For each module NAME:
#   1. compile fortran/NAME.FTN with live FOREX 4.12 (*TRANS:FOREX3*,,411550)
#      into a PERSO library (disk 2348, zone 0o2400);
#   2. dump the object words;
#   3. compare them with madlen/bin/NAME.bin using compare_dms.py.
#
# Usage: run-bytecompare.sh [NAME ...]   (default: SIZLIN ABUFF DDIST COMPDT)
set -u

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
DISPAK=${DISPAK_BIN:-/home/azizz/Yandex.Disk/dispak/build/dispak/dispak}
DISKDIR=/home/azizz/Yandex.Disk/dispak/build/dispak
REF2148=/usr/local/share/besm6/2148
REF2348=/usr/local/share/besm6/2348
WORK=$(mktemp -d "${TMPDIR:-/tmp/.private/azizz/opencode}/grafcmp.XXXXXX") || exit 1
if [ -z "${KEEP_WORK:-}" ]; then trap 'rm -rf "$WORK"' EXIT; fi

MODULES=("$@")
[ $# -eq 0 ] && MODULES=(SIZLIN ABUFF DDIST COMPDT)

for f in "$DISPAK" "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" \
         "$REF2148" "$REF2348"; do
    [ -f "$f" ] || { echo "FAIL: missing $f" >&2; exit 1; }
done
mkdir -p "$WORK"
cp "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" "$REF2148" "$WORK/"
cp "$REF2348" "$WORK/2348"
# The deck card "2348-wr" means disk 2348 opened writable: dispak looks for
# the file named 2348, not 2348-wr (see re-forex/tests/run-f77-runtime.sh).
cp "$DISPAK" "$WORK/dispak" && chmod +x "$WORK/dispak"

echo "=== FOREX 4.12 byte comparison ==="
echo "workdir: $WORK"
for NAME in "${MODULES[@]}"; do
    SRC="$ROOT/fortran/$NAME.FTN"
    ORIG="$ROOT/madlen/bin/$NAME.bin"
    if [ ! -f "$SRC" ] || [ ! -f "$ORIG" ]; then
        echo "SKIP $NAME (missing source or original)" ; continue
    fi
    SHORT=$(printf '%s' "$NAME" | tr -cd 'A-Z0-9' | cut -c1-6)
    {
        printf 'шифр 419999 зс5^\n'
        printf 'DIS 41(2148)^\n'
        printf 'лен 60(2348-wr)^\n'
        printf 'ееВ1а3\n'
        printf '*name C%s\n' "$SHORT"
        printf '*call yesmemory\n'
        printf '*TRANS:FOREX3*,,411550\n'
        printf '*full list\n'
        cat "$SRC"
        printf '*to perso:602400\n'
        printf '*end file\n``````\nеконец\n'
    } > "$WORK/$NAME.deck"
    ( cd "$WORK" && BESM6_PATH="$WORK" timeout 180 ./dispak -l "$NAME.deck" \
        > "$NAME.out" 2> "$NAME.err" )
    if ! grep -aq '4\.12' "$WORK/$NAME.out"; then
        echo "FAIL $NAME: no 4.12 banner"; tail -5 "$WORK/$NAME.out"; continue
    fi
    if grep -aqE 'ОШИБКА|ERR [0-9]+|НЕДОПУСТИМ' "$WORK/$NAME.out"; then
        echo "FAIL $NAME: compiler error"; continue
    fi
    ( cd "$WORK" && BESM6_PATH="$WORK" besmtool dump 2348-wr \
        --start=02400 --length=3 --to-file="$NAME.obj" > /dev/null 2>&1 )
    echo "--- $NAME ---"
    python3 "$ROOT/fortran/verify/compare_dms.py" "$ORIG" "$WORK/$NAME.obj" 2048
done
