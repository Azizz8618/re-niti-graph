# Library 22 (ГРАФОР-СУД) extraction, volume 2048

## Source

- Image: `/usr/local/share/besm6/2048` (byte-identical to `/home/azizz/Yandex.Disk/simh/BESM6/MD/2048` in the relevant zones).
- Catalog: logical zone `0o1100` (decimal `576`), entry `*LIBRARY:22 /ГРАФОР-СУД/ 1201 10.12.91`.
- Catalog structure: `w0` service/date word (`0000000002244600`), `w1=0`, then 255 pairs (name, info word) in `w2..w511`, terminator `w512 = 0o7777777777777777`.
- There is **no second catalog zone**: zone `0o1101` is empty (all 1024 words zero).

## Info-word decoding

Calibrated BESM-6 DMS format (see `re-siprod/pascal/README/ПЛАН-ОЗУ.md`, item 7):

```
[A:12][B:6][C:18][D:12], D=0
A = 0o2000 + carry + word + 8     (base 0o2000: personal/general library on 2048)
B = (relzone + 0o40) & 0o77       carry = 1 if relzone >= 0o40
C = load * 8
body_zone = catalog_zone + relzone
```

`word` is the logical word of the DMS header inside the body zone (`+8` in the formula accounts for the 8-word file-zone header). The module head name follows the header plus cmd/const/data/set sections; all 238 decoded names were located and matched there.

## Zone range

- Catalog: `0o1100` (dec 576).
- Body zones pointed to by the catalog: `0o1105..0o1162` (dec 581..626), 46 zones, all dumped.
- `0o1102..0o1104` contain non-DMS data and are **not** referenced by the catalog; they were not dumped.
- `0o1101` is empty; `0o1132` has no catalog start but is fully spanned by the large `ITPLBV` body beginning in `0o1131`, so it is included in the dump.

## Extraction commands

```sh
# catalog zone
besmtool dump 2048 --start=576 --length=1 --to-file=bin/zone_576.bin
# body zones, e.g. 0o1105 = 581 ... 0o1162 = 626
for z in $(seq 581 626); do
  besmtool dump 2048 --start=$z --length=1 --to-file=bin/zone_$z.bin
done
```

Each `.bin` is 6144 bytes = 1024 words x 6 bytes (big-endian 48-bit words), suitable for `disbesm6`. File names use the **decimal** `--start` zone; `manifest.json` records both octal and decimal zone numbers.

## Verification

- Decoded all 255 catalog entries: 238 modules + 17 reference records; head names verified for **238/238** modules.
- Re-dumped zone `0o1162` (dec 626) to a temporary file: byte-identical to the stored dump (6144 bytes, md5 `7f39ecd060687adbcb083b52f79e0bef`).
- MD5 of every `.bin` is in `manifest.json` under `zones[]`.

## Caveats / inconsistencies

- 17 entries have a small info word with no body (GETIND, AFTZN, CRDUM, SWCAT, FDISC, WCATAL, WZON, RZONE, WZONE, SETR, SETW, GETXY, NOTCH1, BLANCA, MOVBL3, MOVBL1, IBCD). They are reference/entry-point records; their small value is recorded as `ref` in the manifest. No corresponding head name exists in any body zone.
- The catalog `load` field disagrees with the module header's `cmd+const` for 213 of 238 modules (e.g. SETK: catalog 30, header 26; DRACON: catalog 524, header 437). The repo notes this as a known stale-catalog artifact; both values are recorded in `catalog.txt` and `manifest.json`. Zone/word pointers themselves are confirmed by head names.
- Zone `0o1101` is empty; no second catalog zone exists.
- Modules may span zone boundaries (notably `ITPLBV` starting at `0o1131` word 384 and covering `0o1132`); the dump covers the whole contiguous body range.

## Files

- `bin/zone_<dec>.bin` - 47 zone dumps (1 catalog + 46 body).
- `catalog.txt` - full decoded catalog table.
- `manifest.json` - same data as JSON, with per-file MD5.
- `decode_catalog.py`, `extract_all.py` - extraction scripts (kept for reproducibility).
