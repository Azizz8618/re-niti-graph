#!/bin/bash
# Rebuild the working disk 2348 with the whole Fortran port in free PERSO
# zones starting at 0o2410 (see ZONES below) and the MADLEN NITI bridge PDEV
# in the last group zone plus the next free zone.  The pristine image is used
# as the base, so FOREX runtime 0o2400, GOSTLIB 0o2500/0o2560, Pascal runtime
# 0o2570..0o2620 and the Glissada-6 trainer 0o2700 stay intact.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
FORTRAN=$ROOT/fortran
DISPAK=${DISPAK_BIN:-/home/azizz/Yandex.Disk/dispak/build/dispak/dispak}
DISKDIR=${DISKDIR:-/home/azizz/Yandex.Disk/dispak/build/dispak}
REF2148=${REF2148:-/usr/local/share/besm6/2148}
REF2348=${REF2348:-/usr/local/share/besm6/2348}
OUT=$FORTRAN/verify/2348-niti.img
MANIFEST=$FORTRAN/verify/perso-manifest.txt
PDEV=$FORTRAN/verify/PDEV.mad

for f in "$DISPAK" "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" \
         "$REF2148" "$REF2348" "$PDEV"; do
    [ -f "$f" ] || { echo "FAIL: missing $f" >&2; exit 2; }
done

WORK=$(mktemp -d "${TMPDIR:-/tmp/.private/azizz/opencode}/niti-disk.XXXXXX") || exit 2
if [ -z "${KEEP_WORK:-}" ]; then trap 'rm -rf "$WORK"' EXIT; fi
echo "workdir: $WORK" >&2

cp "$DISKDIR/2048" "$DISKDIR/2053" "$DISKDIR/2099" "$REF2148" "$WORK/"
cp "$REF2348" "$WORK/2348"
cp "$DISPAK" "$WORK/dispak" && chmod +x "$WORK/dispak"

# Groups are pre-balanced by the number of catalog names per zone (max 31).
# The first group starts with PLOTSTUB and MOVE1 so the early zones supply
# PAGE/ENDPG/MOVE; see perso-groups.txt.
GROUPS_FILE=$FORTRAN/verify/perso-groups.txt
EXPECTED_NAMES=$FORTRAN/verify/expected-names.txt
[ -f "$GROUPS_FILE" ] || { echo "FAIL: no $GROUPS_FILE" >&2; exit 2; }
mapfile -t PGROUPS < "$GROUPS_FILE"
for ((g=0; g<${#PGROUPS[@]}; g++)); do
    for name in ${PGROUPS[$g]}; do
        [ -f "$FORTRAN/$name" ] || { echo "FAIL: missing $name" >&2; exit 2; }
    done
done

FATAL='ОШИБКА|ERR [0-9]+|НЕДОПУСТИМ|ОТСУТСТВУЕТ|НЕТ ТАКОЙ|БЫЛИ ОШИБКИ|БЫЛИ OШИБKИ|OTCYTCTBYET|OWIBKA'
NGROUPS=${#PGROUPS[@]}

# Zones free on the pristine 2348 image (verified by catalog dump), starting
# at 0o2410 in ascending order.  Occupied zones that must stay intact:
# 0o2400 FOREX runtime, 0o2500/0o2560 GOSTLIB, 0o2570..0o2620 Pascal runtime
# (needed by the Glissada-6 trainer in 0o2700), 0o2700..0o2710 trainer.
ZONES=(
    3050 3060 3070 3100 3110 3120 3130 3140
    3150 3160 3170 3200 3210 3220 3230 3240
)
if [ "${#ZONES[@]}" -lt "$NGROUPS" ]; then
    echo "FAIL: need $NGROUPS free zones, have ${#ZONES[@]}" >&2
    exit 2
fi
LAST_GROUP=${ZONES[$((NGROUPS - 1))]}
PDEV_ZONE=$LAST_GROUP

run_deck() {  # $1 deck name
    local deck=$1
    ( cd "$WORK" && BESM6_PATH="$WORK" timeout 300 ./dispak -l "$deck" \
        > "${deck%.b6}.out" 2> "${deck%.b6}.err" )
    grep -a -q 'КОНЕЦ ЗАДАЧИ' "$WORK/${deck%.b6}.out" || {
        echo "FAIL $deck: no end" >&2; tail -20 "$WORK/${deck%.b6}.out" >&2; exit 1; }
    if grep -a -q '\*TRANS' "$WORK/$deck"; then
        grep -a -q '4\.12' "$WORK/${deck%.b6}.out" || {
            echo "FAIL $deck: no 4.12 banner" >&2; tail -20 "$WORK/${deck%.b6}.out" >&2; exit 1; }
    fi
    if grep -a -q -E "$FATAL" "$WORK/${deck%.b6}.out"; then
        echo "FAIL $deck: translation error" >&2
        grep -a -E "$FATAL" "$WORK/${deck%.b6}.out" | head -10 >&2
        exit 1
    fi
    grep -a -q 'ДЛИНА LIBRARY\|ДЛИHA LIBRARY' "$WORK/${deck%.b6}.out" || {
        echo "FAIL $deck: *to perso wrote no library" >&2; exit 1; }
}

for ((g=0; g<NGROUPS; g++)); do
    zone=${ZONES[$g]}
    deck="lib$(printf '%02d' "$g").b6"
    {
        printf 'шифр 419999 зс5^\nDIS 41(2148)^\nлен 60(2348-wr)^\nееВ1а3\n'
        printf '*name L%03d\n*call yesmemory\n' "$g"
        if [ "$g" -eq $((NGROUPS-1)) ]; then
            printf '*perso:602300\n*assem\n'
            cat "$PDEV"
            printf '*TRANS:FOREX3*,,411550\n*full list\n'
        else
            printf '*TRANS:FOREX3*,,411550\n*full list\n'
        fi
        for name in ${PGROUPS[$g]}; do cat "$FORTRAN/$name"; done
        printf '*to perso:60%s\n*end file\n``````\nеконец\n' "$zone"
    } > "$WORK/$deck"
    run_deck "$deck"
    echo "PERSO 0o$zone: OK"
done

BESM6_PATH="$WORK" python3 - "$WORK" "$MANIFEST" "$NGROUPS" \
    "$LAST_GROUP" "$PDEV_ZONE" "$EXPECTED_NAMES" "${ZONES[@]}" <<'PY'
import os, sys, subprocess
from pathlib import Path
work, manifest, ngroups = Path(sys.argv[1]), Path(sys.argv[2]), int(sys.argv[3])
last_group, pdev_zone = sys.argv[4], sys.argv[5]
expected = set(Path(sys.argv[6]).read_text().split())
zones = sys.argv[7:]
if len(zones) < ngroups:
    raise SystemExit('zone list too short')
TEXT = [" ", ".", "Б", "Ц", "Д", "Ф", "Г", "И", "(", ")", "*", "Й",
        "Л", "Я", "Ж", "/", "0", "1", "2", "3", "4", "5", "6", "7",
        "8", "9", "Ь", ",", "П", "-", "+", "Ы", "З", "A", "B", "C",
        "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O",
        "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "Ш",
        "Э", "Щ", "Ч", "Ю"]
def dec(x):
    return ''.join(TEXT[(x >> (42 - 6*i)) & 0x3F] for i in range(8)).rstrip()
lines = []
for zone in zones[:ngroups]:
    raw = work / f'cat-{zone}.bin'
    subprocess.run(['besmtool', 'dump', '2348', f'--start={int(zone,8)}',
                    '--length=4', f'--to-file={raw}'], cwd=work,
                   env=os.environ, check=True, stdout=subprocess.DEVNULL,
                   stderr=subprocess.DEVNULL)
    d = raw.read_bytes()
    w = lambda i: int.from_bytes(d[i*6:i*6+6], 'big')
    names = []
    for i in range(2, 64, 2):
        n = dec(w(i))
        if not n: break
        names.append(n)
    if not names:
        raise SystemExit(f'empty catalog at 0o{zone}')
    lines.append(f'0o{zone}: ' + ' '.join(names))
    if any(n == 'PDEV' for n in names) and zone not in (last_group, pdev_zone):
        raise SystemExit(f'unexpected PDEV at 0o{zone}')
for zone in (last_group, pdev_zone):
    if not any(f'0o{zone}:' in l and 'PDEV' in l for l in lines):
        raise SystemExit(f'PDEV missing in catalog 0o{zone}')
present = set()
for line in lines:
    present.update(line.split()[1:])
missing = sorted(expected - present)
if missing:
    raise SystemExit(f'missing {len(missing)} catalog names: ' + ' '.join(missing[:20]))
manifest.write_text('\n'.join(lines) + '\n')
print('catalogs checked:', len(lines), 'names:', len(present))
PY

cp "$WORK/2348" "$OUT"
echo "disk: $OUT"
echo "manifest: $MANIFEST"
