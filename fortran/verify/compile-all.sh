#!/bin/bash
# Compile every .FTN file of the port with live FOREX 4.12, in chunks.
# Reports per-chunk errors; no object output is kept.
set -u
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
DISPAK=${DISPAK_BIN:-/home/azizz/Yandex.Disk/dispak/build/dispak/dispak}
DISKDIR=/home/azizz/Yandex.Disk/dispak/build/dispak
REF2148=/usr/local/share/besm6/2148
WORK=$(mktemp -d "${TMPDIR:-/tmp/.private/azizz/opencode}/grafcompile.XXXXXX") || exit 1
if [ -z "${KEEP_WORK:-}" ]; then trap 'rm -rf "$WORK"' EXIT; fi
echo "workdir: $WORK" >&2
cp "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" "$REF2148" "$WORK/"
cp /usr/local/share/besm6/2348 "$WORK/"
cp "$DISPAK" "$WORK/dispak" && chmod +x "$WORK/dispak"
mapfile -t FILES < <(find "$ROOT/fortran" -maxdepth 1 -name '*.FTN' | sort)
CHUNK=30
TOTAL_ERR=0
for ((start=0; start<${#FILES[@]}; start+=CHUNK)); do
    n=$((start/CHUNK+1))
    if [ -n "${ONLY_CHUNK:-}" ] && [ "$n" != "$ONLY_CHUNK" ]; then continue; fi
    sliced=("${FILES[@]:start:CHUNK}")
    cnt=${#sliced[@]}
    {
        printf 'шифр 419999 зс5^\nDIS 41(2148)^\nлен 60(2348)^\nееВ1а3\n'
        printf '*name GC%03d\n*call yesmemory\n*TRANS:FOREX3*,,411550\n*full list\n' "$n"
        for f in "${sliced[@]}"; do cat "$f"; done
        printf '*end file\n``````\nеконец\n'
    } > "$WORK/c$n.deck"
    ( cd "$WORK" && BESM6_PATH="$WORK" timeout 300 ./dispak -l "c$n.deck" > "c$n.out" 2> "c$n.err" )
    rc=$?
    banner=$(grep -ac '4\.12' "$WORK/c$n.out" || true)
    errs=$(grep -acE 'ОШИБКА|ERR [0-9]+|НЕДОПУСТИМ|ЧИCЛO OШИБOK 0*[1-9]' "$WORK/c$n.out" || true)
    progs=$(grep -ac 'ДЛИHA ПOДПPOГPAMMЫ\|ДЛИНА ПОДПРОГРАММЫ' "$WORK/c$n.out" || true)
    printf 'chunk %02d: files %3d-%3d rc=%d banner=%s errors=%s programs=%s\n' \
        "$n" "$((start+1))" "$((start+cnt))" "$rc" "$banner" "$errs" "$progs"
    TOTAL_ERR=$((TOTAL_ERR+errs))
done
echo "TOTAL suspicious error lines: $TOTAL_ERR"
