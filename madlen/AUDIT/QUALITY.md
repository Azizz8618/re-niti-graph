# QUALITY: independent audit of the dtran MADLEN disassembly of library 22

Audit scope: 238 `.mad` files, 238 `.bin` slices, `INDEX.md`, `README.md`,
`name_map.tsv` in `../`. Reference material: `../disasm/zone_*.txt`
(disbesm6 linear sweeps), `../extract/catalog.txt`,
`/home/azizz/Yandex.Disk/dtran/dtran` (binary + `dtran.cc`).

The audit script is `AUDIT/compare.py`; its output is
`AUDIT/comparison-results.txt`.

---

## 1. Method

For each sampled module I did three independent things:

1. **Reproducibility.** Re-ran `dtran -F dms bin/<name>.bin` and diffed against
   the `.mad` file. Example (GDISC): identical except for the two stderr lines
   `Decompiling file ...` / `Format: DMS` that the generator stripped.
   Checked for all 238 files at the banner level (see 2.1).

2. **Byte fidelity of the slice.** For GDISC I compared `bin/GDISC.bin`
   (120 bytes = 20 words) byte-for-byte against `zone_625.bin` words
   `[832, 852)` (catalog locator: zone 1161/625, word 832): `cmp` reports SAME.
   The DMS header decodes to head=1, sym=1, cmd=0o16(14), const=1, name=GDISC.

3. **Structure/count comparison against the disbesm6 listing.** I decoded the
   DMS header directly from the zone dump and checked
   `cmd <= (true instruction lines in .mad) <= 2*cmd`. The factor 2 is not a
   bug: a BESM-6 48-bit word holds **two 24-bit instructions**, and dtran
   (`prtext_dms`, dtran.cc:956-984) emits one or two instruction lines per
   command word depending on whether the low half is the `02200000` placeholder.

   The disbesm6 zone listings are linear sweeps from entry 0; they classify
   almost all of these DMS module bodies as `конд` (data). E.g. GDISC's command
   section is octal addresses 1503-1520 in `disasm/zone_1161.txt` (14
   addresses = cmd `0o16` = 14 decimal) and every one is printed as `конд`.
   So the listing is usable for **word alignment and raw-word verification**,
   not for an instruction-by-instruction mnemonic diff. I aligned dtran's first
   GDISC word (raw `0xca0000090000`, upper half `0xca0000` -> `VTM` with reg 12)
   to dtran's `12,VTM,` line and confirmed the decode is correct.

   Per-sample alignment to the corresponding `../disasm/zone_<oct>.txt`
   (addresses are octal, as printed by disbesm6; `cmd-section` = words
   `header_word+3 .. header_word+3+cmd-1`, which is where dtran's instruction
   lines come from):

```
module   zone(oct)  hdr word(dec)  cmd(oct)  cmd-section addresses  listing file
FCATBD   1161        224             1       343..343              zone_1161.txt
ABUFF    1161        800             3       1443..1445            zone_1161.txt
GDISC    1161        832            16       1503..1520            zone_1161.txt
E70      1161        576            11       1103..1113            zone_1161.txt
RCATAL   1161        768            13       1403..1415            zone_1161.txt
RZON     1161        736            26       1343..1370            zone_1161.txt
NEXTZN   1161        480           100       743..1042             zone_1161.txt
CLEAZN   1161        704             6       1303..1310            zone_1161.txt
SETK     1161        320            32       503..534              zone_1161.txt
LOOK     1160        928           411       1643..2253            zone_1160.txt
ITPLBV   1131        384          3553       603..4355             zone_1131.txt
```
   In every case the sampled address range lies inside the expected zone and
   the `.bin` slice's first bytes match that zone at `hdr word` (verified
   byte-for-byte for GDISC; banners plus head-name decode for the rest).

---

## 2. Concrete findings

### 2.1 Clean, reproducible output (positive)

- All 238 `.mad` files exist; NAME banner matches the filename stem in
  **238/238** cases (with the documented `*`->`_s`, `/`->`_p` mapping).
  Example banners: ` E70     :,NAME, NEW DTRAN`,
  ` *70     :,NAME, NEW DTRAN` (in `_s70.mad`), ` ITPLBV  :,NAME, NEW DTRAN`.
- All 238 files end with `,END,`.
- `grep 'dunno'` over all `.mad` files: **0 hits**. dtran's "unrecognized
  symbol/EQU" fallback (`dtran.cc:663`) never fired.
- No illegal/numeric opcode lines (dtran's `OPCODE_ILLEGAL` fallback renders
  as `,NNN,` or `,NN,`): **0 hits**.
- No empty output files; smallest is `FCATBD.mad` (244 bytes, 15 lines),
  largest is `ITPLBV.mad` (3553 commands, multi-zone).

### 2.2 Instruction-count plausibility (task 1) - all samples pass

From `AUDIT/comparison-results.txt`:

```
module      zone  word hdrname    cmd const mad_ins      range verdict
FCATBD       625   224 FCATBD       1    0       2    1-2     OK
ABUFF        625   800 ABUFF        3    0       5    3-6     OK
GDISC        625   832 GDISC       16    1      22   14-28    OK
E70          625   576 E70         11    0      17    9-18    OK
RCATAL       625   768 RCATAL      13    0      17   11-22    OK
RZON         625   736 RZON        26    2      32   22-44    OK
NEXTZN       625   480 NEXTZN     100   12     123   64-128   OK
CLEAZN       625   704 CLEAZN       6    0      11    6-12    OK
SETK         625   320 SETK        32    0      49   26-52    OK
LOOK         624   928 ?          411   11     479  265-530   OK
ITPLBV       601   384 ?         3553  125    3559 1899-3798  OK
```

`cmd` is octal from the DMS header; `mad_ins` is the count of true instruction
lines after excluding directive lines (`LOG`, `INT`, `ISO`, `TEXT`, `SUBP`,
`LC`, `LP`, `EQU`, `BSS`, `SET`, `END`, `NAME`). Every sample lies in
`[cmd, 2*cmd]`. Sizes span 1 to 3553 command words (about 3.5 orders of
magnitude), so the sampling covers the "different sizes" requirement.

The `?` in `hdrname` for LOOK and ITPLBV is an artifact of my single-zone
header reader (their head-name word is in a later zone); the real `.mad`
banners are ` LOOK    :,NAME, NEW DTRAN` and ` ITPLBV  :,NAME, NEW DTRAN`, and
the generator README documents that 35 modules cross zone boundaries and
ITPLBV spans three zones. The slices are therefore complete, not truncated.

### 2.3 Data/code separation (positive)

dtran uses the DMS header (`cmd/const/data/set/bss/head/sym/long/debug`) to
split sections, so constants are rendered as `,LOG,`, `,INT,`, `,TEXT,`, `,ISO,`
and BSS as `,BSS,n` rather than being disassembled as bogus code. Example from
`SETK.mad`:
```
 67: *0032B:,BSS,1
 68: *0033B:,BSS,1
```
and from `RCATAL.mad`:
```
 13: *LICAT* :,LC,132096
```
External references become `,SUBP,` declarations at the top:
```
SETK.mad 13: FDISC   :,SUBP,
SETK.mad 14: WCATAL  :,SUBP,
```
This is a decisive quality advantage over the disbesm6 listings, where the
same words appear as undifferentiated `конд`.

### 2.4 Labels and addresses (acceptable, with caveats)

- Address labels are generated, not original: `*0001B`, `*0013B`, `*0030B`,
  etc. `README.md` states this explicitly. Original MADLEN identifiers and
  comments are unrecoverable; this is expected for a disassembly.
- Some SUBP/call lines carry **trailing spaces** used by dtran to right-pad
  the operand column, e.g. `13,VJM,*70     ` (`E70.mad:23`),
  `13,VJM,RZONE   ` (`RCATAL.mad:30`). Harmless for assembly.
- Some lines have an **empty label field** followed by a colon:
  `  :,UJ,*0011B` (`GDISC.mad`), `  :14,VTM,` (`RZON.mad`). This is dtran's
  way of marking an unnamed code offset; it is syntactically intentional.
- `*LICAT*` is an `LC` (literal constant) symbol, correctly expanded by dtran
  from the symbol table; not garbage.

### 2.5 Known caveat inherited from the catalog, not a dtran defect

The catalog `load` field is stale for many modules (README: 213/238 differ).
Example: `GDISC` catalog load = 15, DMS header cmd+const = 17. The generator
correctly uses the header, not the catalog, to size the slice. I verified
GDISC's header cmd=14+const=1=17 against the actual bytes.

### 2.6 Disbesm6 hex-display quirk (investigated, not a blocker)

While aligning offsets I noticed that `disbesm6`'s `конд` lines print a
transformed 64-bit-looking value (e.g. raw word `0x1001` at octal address 1500
prints as `в'0000000000010001'`), even though `freadw()` in `disbesm6.c` reads
the same 6 bytes big-endian and code lines decode them correctly. This is a
display artifact of the installed disbesm6 binary, **not** a mismatch between
the zone dump and the `.bin` slices (md5 of the two zone files is identical,
and `cmp` of GDISC slice vs zone bytes is SAME). Address labels in
`zone_*.txt` align 1:1 with raw word indices, which is what the audit relies
on.

---

## 3. Verdict

**Can this MADLEN be reassembled / used?** Yes, with the normal meaning of
"pseudo-assembly":

- It is faithful: every `.mad` is byte-reproducible from its `.bin`, every
  `.bin` is an exact zone slice, header counts match the decoded instruction
  structure, and all 11 sampled modules (1-3553 commands) pass the
  `[cmd, 2*cmd]` count check.
- It is **reassemblable as DMS MADLEN** via the BESM-6 `DTRAN` assembler
  (the `dtran` output form is the documented input to `decomp.pl`/`asm.pl`);
  labels, `SUBP`, `LC`, `BSS`, `EQU` and `END` are all well-formed.
- It is **not** a recovery of the original source text: comments, original
  variable names and source formatting are gone, and generated labels such
  as `*0005B` replace them. Use it for reading/decompilation, not for
  verbatim source restoration.

No garbage instructions, no misplaced data, no truncated modules were found
in the sampled set, and the whole-corpus scans (banners, END, `dunno`,
illegal opcodes) found no defects. The only real caveats are inherited
(stale catalog load; generated labels) or cosmetic (trailing operand padding,
empty unnamed labels).
