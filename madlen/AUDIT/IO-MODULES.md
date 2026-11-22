# IO-MODULES: low-level GRAFOR / disk-exchange modules in the dtran MADLEN

Audit scope: all **238** `.mad` files in `../` (library 22, ГРАФОР-СУД, volume 2048).
Search was performed with `grep -rniE` over the `.mad` files. All line numbers below
are **1-based line numbers inside the named `.mad` file**, exactly as emitted by
`/home/azizz/Yandex.Disk/dtran/dtran -F dms` (the two stderr banner lines
`Decompiling file ...` / `Format: DMS` were stripped by the other agent).

## 0. Keyword translation: what to grep for in dtran output

dtran does **not** print Cyrillic экстракод mnemonics. Its opcode table
(`dtran.cc` lines 105-129) renders:

| Disbesm6 / MADLEN mnemonic | dtran token |
|---|---|
| Э50 .. Э74 | `*50` .. `*74` |
| Э75 (CTX) | `CTX` |
| Э76, Э77 | `*76`, `*77` |
| (no literal `э70`, `увв`, `чт`, `зп` strings appear) | - |

Therefore `grep 'э70'` on `.mad` files yields **nothing**; the equivalent
searches are `\*70`, `,\*[0-7][0-7],` and the disk-routine **symbol names**
(SUBP declarations and VJM/UJ call sites), which are preserved verbatim.

Observed extop tokens across all 238 files (exact counts):

```
      6  ,*50,      (= Э50, ВН/ввод-type disk I/O)
      1  ,*70,      (= Э70, used as an operand inside module *70)
      1  ,*72,
      2  ,*74,      (= STOP)
```
Files containing at least one `,NN,` extop: `FOPEN.mad`, `GDISC.mad`,
`_s70.mad`, `SETEND.mad`.

---

## 1. The Э70 exchange path itself (highest relevance)

### 1.1 `E70.mad`  (catalog entry 26, zone 1161/625, word 576)

```
  1: E70     :,NAME, NEW DTRAN
 13: *70     :,SUBP,
 14: NEXTZN  :,SUBP,
 23: 13,VJM,*70
 24: ,ITS,9
 25: 13,VJM,NEXTZN
```
Observed: `E70` is a thin wrapper. It declares `*70` and `NEXTZN` as external
subprograms and calls them with `VJM` (jump via index register 13). It contains
**no** extop of its own.

### 1.2 `_s70.mad` - this is the module named `*70` (filename `*` -> `_s`)

Catalog entry 25 is literally `*70` (zone 1161/625, word 608, load 46).
Module size: 51 commands + 5 constants. Exact I/O excerpts:

```
  1: *70     :,NAME, NEW DTRAN
 52: 15,*70,-1
 68: ,*50,1206B
 82: ,*50,115B
 83: 9,*72,
 85: ,*50,116B
```
Observed: this is the only module that both has the name `*70` and issues
`*50` (Э50) / `*72` extops. It also uses `*70` as an operand at line 52.
This is the concrete Э70 handler body in library 22.

### 1.3 `RZON.mad` - read-zone routine that reaches Э70

```
  1: RZON    :,NAME, NEW DTRAN
 13: E70     :,SUBP,
 14: *70     :,SUBP,
 32: ,UJ,E70
 33: *0011B:,UJ,*70
```
Observed: `RZON` declares **both** `E70` and `*70` and transfers to each.

---

## 2. Disk / zone / catalog primitives and their callers

Exact line excerpts (all from `../<name>.mad`):

### `GDISC.mad` (zone 1161/625, word 832; 16 cmd + 1 const)
```
  1: GDISC   :,NAME, NEW DTRAN
 26: ,*50,105B
 28: ,*50,115B
 33: *0013B:,*50,116B
```
Contains Э50 extops with small operands `105B`, `115B`, `116B` (device/function
codes). This is the low-level disk exchange primitive.

### `RCATAL.mad` (zone 1161/625, word 768; 13 cmd)
```
  1: RCATAL  :,NAME, NEW DTRAN
 13: *LICAT* :,LC,132096
 14: RZONE   :,SUBP,
 15: WZONE   :,SUBP,
 25: 14,VTM,*LICAT*
 30: ,UJ,RZONE
 31: *0011B:,UJ,WZONE
```
Catalog read: loads an `LC` constant (132096 = 0o400140) and dispatches to
`RZONE` / `WZONE`. The bodies of `RZONE` and `WZONE` live inside this module
(they are catalog REFERENCE entries with no separate body).

### `SETK.mad` (zone 1161/625, word 320; 32 cmd + 4 BSS)
```
  1: SETK    :,NAME, NEW DTRAN
 13: FDISC   :,SUBP,
 14: WCATAL  :,SUBP,
 15: SETEND  :,SUBP,
 16: RCATAL  :,SUBP,
 17: GDISC   :,SUBP,
 23: 13,VJM,GDISC
 27: 13,VJM,RCATAL
 44: 13,VJM,WCATAL
 48: 13,VJM,FDISC
```
The full open/setup chain: GDISC -> RCATAL -> SETEND -> WCATAL -> FDISC.

### `GIVZON.mad` (zone 1161/625, word 256; 46 cmd + 1 const + 3 BSS)
```
  1: GIVZON  :,NAME, NEW DTRAN
 13: FDISC   :,SUBP,
 14: WCATAL  :,SUBP,
 15: SETREF  :,SUBP,
 16: GIVENZ  :,SUBP,
 17: RCATAL  :,SUBP,
 18: GDISC   :,SUBP,
 24: 13,VJM,GDISC
 28: 13,VJM,RCATAL
 34: 13,VJM,GIVENZ
 52: 13,VJM,SETREF
 63: 13,VJM,WCATAL
 67: 13,VJM,FDISC
```
Zone-allocation chain; calls `SETREF` and `GIVENZ` in addition to the disk pair.

### `NEXTZN.mad` (zone 1161/625, word 480; 100 cmd + 12 const)
```
 13: GDISC   :,SUBP,
 14: FDISC   :,SUBP,
 46: 13,VJM,GDISC
127: 13,VJM,FDISC
```

### `WCATWO.mad` (zone 1162/626, word 64; 123 cmd)
```
 14: RZONE   :,SUBP,
 15: WZON    :,SUBP,
188: 13,VJM,RZONE
198: 13,VJM,RZONE
200: 13,VJM,WZON
```

### `SETEND.mad` (zone 1161/625, word 896; 55 cmd)
```
 14: RZONE   :,SUBP,
 81: 13,VJM,RZONE
 89: 13,VJM,RZONE
101: ,*74,        (Э74 / STOP)
```

### `FOPEN.mad` (zone 1161/625, word 416; 39 cmd)
```
 74: ,*74,        (Э74 / STOP)
```

### `CLEAZN.mad` (zone 1161/625, word 704; 6 cmd), `FCATBD.mad` (word 224; 1 cmd)
Both are tiny low-level helpers; their NAME banners are the only keyword hits
in the `.mad` text:
```
CLEAZN.mad  1: CLEAZN  :,NAME, NEW DTRAN
FCATBD.mad  1: FCATBD  :,NAME, NEW DTRAN
```

---

## 3. Modules whose NAME alone matches the requested keyword list

These have a body and a `.mad` file, but their code does not contain a further
literal keyword hit (the name is the identifying evidence):

```
SETIND.mad  1: SETIND  :,NAME, NEW DTRAN
SETREF.mad  1: SETREF  :,NAME, NEW DTRAN
SETZON.mad  1: SETZON  :,NAME, NEW DTRAN
GIVENZ.mad  1: GIVENZ  :,NAME, NEW DTRAN
E70.mad     1: E70     :,NAME, NEW DTRAN
_s70.mad    1: *70     :,NAME, NEW DTRAN
GDISC.mad   1: GDISC   :,NAME, NEW DTRAN
RCATAL.mad  1: RCATAL  :,NAME, NEW DTRAN
RZON.mad    1: RZON    :,NAME, NEW DTRAN
GIVZON.mad  1: GIVZON  :,NAME, NEW DTRAN
```

## 4. Catalog REFERENCE-only entries (no `.mad` exists)

From `../extract/catalog.txt`, these 17 entries have a small info word and no
body; the other agent correctly produced no `.mad` for them:
`GETIND, AFTZN, CRDUM, SWCAT, FDISC, WCATAL, WZON, RZONE, WZONE, SETR, SETW,
GETXY, NOTCH1, BLANCA, MOVBL3, MOVBL1, IBCD`.

Caveat: `RZONE`/`WZONE` have no standalone body but **do** appear as `SUBP`
symbols and `UJ` targets inside `RCATAL.mad` (lines 14, 15, 30, 31), i.e. their
code is embedded in `RCATAL`. `FDISC`/`WCATAL` are similarly `SUBP`/`VJM`
targets in `SETK.mad`, `GIVZON.mad`, `NEXTZN.mad` even though they have no
separate `.mad`.

## 5. Summary verdict for task 2

Observed: library 22's dtran MADLEN contains a complete low-level GRAFOR disk
stack: the Э70 entry (`E70`) and its handler (`*70`), the Э50-based disk
primitives (`GDISC`, `_s70`), zone read/catalog routines (`RZON`, `RCATAL`,
`RZONE`/`WZONE` inside it, `GIVZON`, `WCATWO`, `SETEND`), and their callers
(`SETK`, `NEXTZN`, `SETREF`, `SETIND`, `GETIND` as a reference entry).
No module contains a literal `э70` string; the identification is via the
`*70`/`*50` extop tokens and preserved disk-routine symbol names.
