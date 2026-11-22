# Library 22 (ГРАФОР-СУД): modules A and B

**Coverage: 31 modules** (ABUFF, ADDLEV, ANGLER, APPOLY, ARCANG, ARCC1, ARCELA,
ARCELB, ARCIA, ARCIB, ARCIC, ARCID, ARCOCC, ARCOLC, ARCOLL, AREB1, ARROW,
ASTEP, ATRAN2, AXES, AXISC, AXONOM, BAR, BARS, BCD, BEGLEV, BITA, BLANC,
BLANCH, BOX, BUFL).

Source: **dtran MADLEN disassembly of library 22 from volume 2048**
(`madlen/<NAME>.mad`, generated with `dtran -F dms`). Line numbers in the
Evidence column refer to those `.mad` files. Zone/word and load figures come
from `madlen/INDEX.md`. The listings contain no source comments, so purpose
is reconstructed from instruction structure, call graph, GRAFOR common-block
symbols (`*GFATRN*`, `*GFBFTR*`, `*GFGEL*`, `*GFL*`, `*GFBLAN*`, ...) and
literal strings. Inferences that are not directly provable from the code are
marked **[I]**.

---

## 1. Service, buffers and coordinate transforms

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| ABUFF | 3 / 0 | Tiny GRAFOR disk-buffer helper: saves index register 10, loads index register 11 from the accumulator, then stores a word at address `(IR11)+6` and jumps via IR13. Purpose inside the buffer manager is opaque from 3 commands **[I]**. | none | `,STI,10`; `,ATI,11`; `,ITA,10`; `11,STX,6`; `13,UJ,` (lines 13-17). Index in `INDEX.md`: zone 625, word 800. |
| BUFL | 66 / 0 | Line-buffer flush/clip: tests clipping status flags in the GRAFOR line common `*GFL*` (GAK/3, GAK/5, GAK/6), copies four coordinate words through indirect pointers and recursively calls `LININT` to insert interpolated clip points before flushing. | `LININT` (entry symbol of this module, called recursively at lines 78 and 105) | `LININT :,SUBP,` (line 21); flag tests `,UTC,GAK/5 / ,ASN,64-7 / ,ARX` (24-41); coordinate copies (49-61); `13,VJM,LININT` (78, 105). `SEARCH.mad:310` and `PATCH.mad:296,636` call `BUFL` right after `INTRSC`, confirming buffer-flush role. |
| BCD | 117 / 73 | Two-entry (0000B, 0065B) binary/decimal formatting routine for GRAFOR numeric labels: shifts and masks packed words (`ASN,64-8`, `AAX`, `AOX`, `AVX`), multiplies and divides, and emits packed-decimal/ISO output. Exact direction (real→text vs. text→internal) is **[I]**, but callers show it formats tick labels. | internal `VJM` to code blocks at 0062B, 0107B, 0113B, 0127B (these are instruction words in the data area, not plain constants) | Entries `*0000B` / `*0065B` (lines 13, 16, 111); `,RTE,77B`; `,ASN,64-8`; `8,AAX,176B`; `8,AVX,164B`; packed constants `3654631463146317` etc. (201-213); ISO `6H    **` (190). `AXES.mad:611,919`, `XAXIS.mad:525`, `YAXIS.mad:525` call `BCD`. |
| BEGLEV | 76 / 21 | "Begin level" of nested affine transformations: checks the blanking/attribute flag `GAL/1` of `*GFATRN*`, copies the current transform into `*GFATRM*` (GAK/2..6 → GAL/7, GAM/0..3), increments the nesting counter, compares it with parameter 2 and, on overflow, prints an error and stops. | `FT*571`, `FT*003`, `STOP*` (error path) | `,UTC,*GFATRN*` → `,UTC,*GFATRM*` copies (42-65); counter increment and limit test `7,A+X,1 / 7,A-X,2 / ,ASN,64-7 / ,ARX` (71-82); `13,VJM,FT*571 / FT*003 / STOP*` (85-87). ISO text decodes to FORMAT `(10X,47HСЛИШКОМ МНОГО СКОБОК В АФФИНЫХ ПРЕОБРАЗОВАНИЯ X)` (lines 150-159), i.e. "too many brackets in affine transformations". |
| ATRAN2 | 156 / 4 | Affine transformation composition: multiplies the 6×6-padded homogeneous transformation matrix in `*GFATRM*` by the one in `*GFATRN*` using nested loops and integer multiplication, then writes the product back to `*GFATRN*` (GAK/4 and GAK/6..GAL/3). The 147-word DATA block holds the identity-like scaling constants (`4050000000000000` = 1.0, zeros). | `MTMPL`, `I*MUI*` (both internal code blocks) | `*GFATRM*:,LC,115` / `*GFATRN*:,LC,7` (13, 17); six index-register setups + `13,VJM,MTMPL` (46-88); nested loops (94-182); result copy (183-209); `,DATA,` and 1.0/zero patterns (255-357); `,END,` relocations to `*GFATRM*`, `GAK/2` (359-362). Called by `ROTATE.mad:68`, `RESET.mad:55`, `PSCALE.mad:41`, `LSCALE.mad:78,137`, `SHIFT.mad:30`. |
| AXONOM | 24 / 4 | Axonometric projection matrix update: `HCROT1` reads a rotation factor from GAK/2 of `*GFMATR*` and applies it (via three modifier cells *0025B..*0027B and a recursive `13,VJM,HCROT1`) to the 34-word graphics matrix, i.e. generates/updates the axonometric transformation **[I: exact matrix layout not shown]**. | `HCROT1` (itself, recursive) | `*GFMATR*:,LC,34`; `GAK/2 = *GFMATR*+32` (13-15); `,UTC,GAK/2 / ,XTA / 7,ATX,` (19-22); `13,VJM,HCROT1` (33); `,WTC,*0025B..*0027B` (23-31). |

**Notes.** BUFL's file header names the entry `LININT`, the same symbol as the
standalone library module LININT; its own body calls that symbol recursively
after testing `*GFL*` clipping flags. External callers (`SEARCH`, `PATCH`)
reference it as `BUFL`, so the module is the line-buffer flush/clipping
front-end rather than a plain linear interpolator. ABUFF is a 3-command
primitive inside the disk/catalog zone; no call sites for it were found in the
MADLEN set.

---

## 2. Levels, approximation and axes scaling

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| ADDLEV | 55 / 1 | "Add level": integer/fixed-point arithmetic over GRAFOR level arrays held through modifier cells; two nested loops add increments (parameter/register 5) to counters 3 and 4 and combine them with a multiplier, returning two updated values. Sits with `LEVFUN`, `LEVMAP`, `SUPLIN` (contour/level subsystem) **[I: exact data meaning]**. | `I*MU*I` (internal, at line 31) | entry `I*MU*I :,SUBP,` (line 13); loop bodies (24-45, 58-70); `13,VJM,I*MU*I` (31); `7,A/X,2 / 7,A*X,5` (49-50); `13` BSS words at *0055B..*0067B (80-87); `INDEX.md` zone 624 word 0. |
| APPOLY | 271 / 7 | Polynomial approximation of tabulated data: accumulates powers/products (`I*MU*I`), evaluates the polynomial with `PVAL`, computes a residual/RMS error (`SQRT`), and prints a result table using FORMAT `(I6,6E15.2)` via FT* I/O routines. | `FT*571`, `FT*002`, `FT*003`, `SQRT`, `PVAL`, `IABS`, `I*MU*I` | `13,VJM,PVAL` (83, 163); `13,VJM,SQRT` (123); repeated `13,VJM,FT*571/002/003` (111-120, 198-212); ISO `6H(I6,6E` / `6H15.2)` (364-365). Three coefficient-accumulation loops at 22-107, 149-197, 239-238. |
| ASTEP | 323 / 31 | Computes an "axis step": reads a scale value with `IRDB`, scales it by powers of ten (`R*PO*I`), compares against maxima with `AMAX1`, rounds with `AINT`, and iteratively adjusts a candidate step (1/2/5-like sequence) until it fits the range; returns three results. Listed with `AXES` in GRAFOR data zones. | `AMAX1`, `AINT`, `ABS`, `IRDB`, `R*PO*I` | `13,VJM,IRDB` (22); `13,VJM,R*PO*I` (29, 121, 260, 387); `13,VJM,ABS` (35, 143, 148); `13,VJM,AMAX1` (155); `13,VJM,AINT` (169, 190, 211, 230, 287, 336, 353); packed decimal constants and TEXT `+KA1ZX4+`, `E/H`, `AN` (411-428). |

**Notes.** ASTEP's three output words (registers 40B/41B/43B are written at
lines 194-196, 219-221, 315-317, 346-348, 374-382) are consistent with
"step size, first tick, decimal exponent" for axis labelling **[I]**. Its
caller relationship to AXES is supported by `disasm/INDEX.md` zone 1110/1113,
which lists ASTEP together with AXES/CIRCLE/NUMBER/SIGNA.

---

## 3. Arcs, angles and arrows

All ARC* modules share the GRAFOR geometric-element common `*GFGEL*` (LC 28)
and/or the buffer-former common `*GFBFTR*` (LC 2, GAK/2 = +1). They use
indirect addressing (`WTC,*xxxxB`) for parameter lists and VJM calls to
share math helpers (`ANGLER`, `ARCIA`, `ARCANG`, `SIN`, `COS`, `ATAN`, `ABS`,
`SQRT`, `SIGN`, `R*DI*I` radians→degrees, `R*ST*I`, `IVEST` visibility test,
`GFFALS` false-flag). Constants `LOG,2312571435610604` (= DK0/CK0 marker),
`LOG,4413200000000000`, `LOG,4114441766521041` and TEXT `DK0` / `CK0` recur
throughout this family.

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| ANGLER | 72 / 5 | Polar angle (atan2-like) of a vector from two indirect words: divides parameter 3 by 2, takes ABS of dx/dy, computes `ATAN` of their ratio and applies quadrant corrections by adding/subtracting π. Returns the angle in register 10B (also stored to 11B). | `ATAN`, `ABS` | entry `ATAN :,SUBP,`, `ABS :,SUBP,` (13-14); `7,XTA,3 / 7,A/X,2 / 7,ATX,6` (21-23); sign tests `,ASN,64-7 / ,ARX` (30-35 etc.); `13,VJM,ATAN` (48, 74, 84, 116, 148); `7,A*X,6 / ,X-A, / 7,A+X,1` quadrant fix (50-53); `7,XTA,10B / 7,ATX,11B` (120-121); π-like LOG constants (126-128). |
| ARCANG | 275 / 11 | Converts a circular/elliptic arc description into angle endpoints: uses center coordinates from `*GFGEL*`/indirect cells, side lengths via `SQRT`, `ATAN` and `R*DI*I`, branches on eight sign/quadrant cases (tests at 0056B-0172B), applies `IVEST` clipping and `SIGN` to write two result angles (WTC cells 0326B/0327B). | `SIGN`, `ATAN`, `IVEST`, `SQRT`, `ABS`, `R*DI*I` | `7,XTA,3 / 7,A/X,5` (21-22); two radius computations (33-43, 74-81); `13,VJM,ATAN` (84, 191); angle sum/difference (194-199); eight case branches (200-244); `13,VJM,IVEST` (99, 116, 152, 170, 295, 321); results via `,WTC,*0326B/*0327B` (274-278, 280-287). |
| ARCC1 | 210 / 7 | Computes the circle through three points (circumcircle): takes two points from `*GFBFTR*`/GAK/2 and one indirect point, forms squared side lengths with `SQRT`, applies a Heron-type expression (16·(16−a)·(16−b)·...), converts with `R*DI*I`, obtains an angle with `ATAN`, and returns center/radius or angles through six WTC pointers. | `ATAN`, `IVEST`, `SQRT`, `R*DI*I` | three `13,VJM,SQRT` (42, 61, 89); Heron-style products (91-107); `13,VJM,R*DI*I` (95, 242); `13,VJM,ATAN` (155); `IVEST` checks (69, 114, 165, 210); results stored via `*0240B..*0242B` (216-238). |
| ARCELA | 77 / 3 | Ellipse-arc variant A: reads the current point (`*GFBFTR*`, GAK/2), takes absolute values of two parameters, calls `IVEST` on a transformed point, chooses one of four quadrant cases from the signs of the coordinate differences and calls `ELIPS` with the selected arguments; otherwise `GFFALS`. | `GFFALS`, `ELIPS`, `IVEST`, `ABS` | `13,VJM,ABS` (30, 39); `13,VJM,IVEST` (47); sign branches 48-96; `13,VJM,ELIPS` (113); `13,VJM,GFFALS` (117); 15 BSS parameter cells *0102B..*0115B (140-151). |
| ARCELB | 105 / 3 | Ellipse-arc variant B: computes differences from center, multiplies by a scale factor (`7,A*X,2`), converts a parameter with `R*DI*I`-family helper `R*ST*I`, obtains rotated coordinates via `SIN`/`COS`, then delegates to `ARCANG`, `AREB1` and `ARCELA`. | `ARCELA`, `AREB1`, `ARCANG`, `SIN`, `COS`, `ABS`, `R*DI*I`, `R*ST*I` | `13,VJM,COS` (58, 76); `13,VJM,SIN` (63, 69); `13,VJM,R*DI*I` (89); `13,VJM,R*ST*I` (91); `13,VJM,ARCANG` (109); `13,VJM,AREB1` (122); `13,VJM,ARCELA` (135). |
| ARCIA | 165 / 10 | Principal arc interpolator: checks visibility with `IVEST`, selects quadrant endpoints, reads two radii via `RDB`, computes angle and step with `ABS`/`R*ST*I`, then emits a sequence of points by repeatedly calling `MOVE` (pen move) until the angle counter saturates; error path `GFFALS`. | `GFFALS`, `MOVE`, `RDB`, `IVEST`, `ABS`, `R*ST*I`, `SIN`, `COS` | `13,VJM,IVEST` (51); `13,VJM,RDB` (109, 113); `13,VJM,ABS` (34, 43, 142); loop with `13,VJM,MOVE` (191, 217) and terminator `7,X-A,27B / ,UZA,*0117B` (197-198); `13,VJM,GFFALS` (221). |
| ARCIB | 36 / 12 | Thin wrapper for arc variant B: forms dx/dy from `*GFBFTR*` and two indirect parameters, calls `ARCANG` for the angle range and then `ARCIA` to draw the arc. | `ARCIA`, `ARCANG` | `13,VJM,ARCANG` (47); `13,VJM,ARCIA` (55); parameter arithmetic 19-32. |
| ARCIC | 51 / 15 | Arc variant C wrapper: same dx/dy setup as ARCIB, then calls `ARCC1` (circle geometry), `ARCANG` (angles) and `ARCIA` (drawing) in sequence. | `ARCIA`, `ARCANG`, `ARCC1` | `13,VJM,ARCC1` (53); `13,VJM,ARCANG` (68); `13,VJM,ARCIA` (77); 15 BSS cells at 97-108. |
| ARCID | 46 / 13 | Arc variant D: computes the radius as `SQRT(dx²+dy²)`, obtains the direction with `ANGLER`, tests a sign flag and calls `ARCIA` with either the direct or the complemented arguments. | `ARCIA`, `ANGLER`, `SQRT` | dx/dy squares `7,A*X,3 / 7,A*X,4 / 7,A+X` (34-40); `13,VJM,SQRT` (43); `13,VJM,ANGLER` (49); sign branch 54-60; `13,VJM,ARCIA` (71). |
| ARCOCC | 722 / 20 | Large arc cooker for `*GFGEL*` (variant "CC"): checks element flags, extracts center/size from GAL/3..GAL/7 and GAM/0..GAM/1, computes radius with `SQRT` and angle with `ANGLER`/`ATAN`, handles up to four quadrant/mirror cases with `IVEST` clipping, and outputs six computed words through WTC pointers 0772B..0777B (center, radii, endpoints). | `GFFALS`, `SIGN`, `SIN`, `COS`, `ATAN`, `IVEST`, `SQRT`, `ANGLER`, `ABS`, `R*DI*I` | flag tests (34-51); `13,VJM,ANGLER` (68, 280); `13,VJM,SQRT` (79, 205); `IVEST` (87, 101, 170); quadrant branches 0072B-0173B, 0226B-0362B; result stores via `,WTC,*0772B..*0777B` (e.g. 287-311); `GFFALS` exits 703-708. |
| ARCOLC | 665 / 15 | Arc drawing routine "LC" using `*GFGEL*` + `*GFBFTR*`: chooses one of two coordinate sets according to GAM/0, computes an angle with `ANGLER`, radii with `SQRT`, visibility with `IVEST`, then uses `SIGN`/`ATAN`/`SIN`/`COS` and `CIRTAC` plus `MOVE`/`STRMOD` to emit the circle-arc stroke; converts scales with `R*ST*I` and integer division `I*DI*I`. | `GFFALS`, `CIRTAC`, `STRMOD`, `MOVE`, `SIN`, `COS`, `ATAN`, `SIGN`, `IVEST`, `SQRT`, `ANGLER`, `ABS`, `I*DI*I`, `R*ST*I` | element flag branches 45-75; `13,VJM,ANGLER` (161); `13,VJM,SQRT` (172, 272, 297); `13,VJM,IVEST` (180, 218, 243, 283); `13,VJM,MOVE` (348); `13,VJM,STRMOD` (351); `13,VJM,CIRTAC` (380); `GFFALS` exits 644-650. |
| ARCOLL | 225 / 11 | Arc of a rotated ellipse from `*GFGEL*` parameters: forms a determinant-like denominator from GAL/1, GAL/2, GAL/5, GAL/6, solves for two coordinates, computes angles of two points with `ANGLER`, applies visibility tests and `GAM/7` scaling, then evaluates four endpoint coordinates with `SIN`/`COS` and writes them via WTC pointers. | `GFFALS`, `SIN`, `COS`, `ABS`, `IVEST`, `ANGLER`, `R*DI*I` | determinant construction (53-94); two `13,VJM,ANGLER` (109, 125); `IVEST` (137, 152, 170, 295, 321); angle difference and `13,VJM,R*DI*I` (236-240); four SIN/COS endpoint stores (245-289); `GFFALS` (293, 297). |
| AREB1 | 140 / 11 | Ellipse/arc bounding-angle helper: scales two coordinates by parameter 3, iteratively compares them against four limits (registers 2, 10B, 7, 6), and for each branch computes `SIN`, `COS`, the ratio and `ATAN` to produce a corrected angle; picks one of two output cells (0166B/0167B) and loops until stable. | `ATAN`, `COS`, `SIN` | `7,A*X,3` scaling (20-25); four comparison branches (34-129); `13,VJM,SIN` (43, 75, 109, 135); `13,VJM,COS` (49, 81, 115, 141); `13,VJM,ATAN` (56, 88, 122, 148); loop back `,UJ,*0011B` (170). |
| ARROW | 270 / 12 | Draws an arrow: reads two points with `RDB`, obtains an angle from `ANGLER` and a length from `SQRT`, calls `MOVE` to place the shaft, then draws either two slanted head lines via `MOVA` or a curved head via `ARCIA`, depending on `*GFGEL*` flags; changes pen style with `STRMOD` and checks visibility with `IVEST`. | `GFFALS`, `ARCIA`, `SIN`, `COS`, `MOVA`, `MOVE`, `ANGLER`, `SQRT`, `IVEST`, `ABS`, `STRMOD`, `RDB`, `R*ST*I` | `13,VJM,RDB` (46, 51); `13,VJM,STRMOD` (63, 363); `13,VJM,ANGLER` (127); `13,VJM,MOVE` (135, 175, 197, 236, 313); two `13,VJM,MOVA` head strokes (155, 168, 216, 229); `13,VJM,ARCIA` (335); `13,VJM,GFFALS` (354). |

**Notes.** The ARC* family divides into *geometric solvers* (ARCC1, ARCANG,
ARCOCC, ARCOLC, ARCOLL, AREB1, ANGLER, ARCELA/ARCELB) and *thin dispatchers*
that assemble arguments and call them (ARCIB, ARCIC, ARCID, ARCELA/B also
delegate). ARCIA is the one that actually emits points with `MOVE`. Shared
`LOG,2312571435610604` and TEXT `DK0`/`CK0` are likely the π/2 and π constants
plus debug tags **[I]**. The large ARCOCC/ARCOLC bodies are mostly long chains
of sign tests (ASN,64-7 / ARX) implementing the eight quadrants; no floating
I/O or disk access appears in them.

---

## 4. Axes and tick labels

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| AXES | 1351 / 33 | Main axis drawer: reads axis parameters with `IRDB`/`RDB`, chooses tick steps via `ASTEP`, computes label values with `AMOD`, `AINT`, `R*PO*I`, `R*DI*I` and renders tick marks and numeric labels using `IBCD`/`BCD` (number→characters) and `SYMBOL` (character plotting) plus `MOVE` for line segments. Handles two coordinate directions and a secondary label set. | `MAX0`, `MIN0`, `AMIN1`, `IABS`, `BCD`, `SYMBOL`, `IBCD`, `AMOD`, `MOVE`, `ABS`, `AINT`, `ASTEP`, `RDB`, `IRDB`, `R*PO*I`, `R*DI*I`, `R*ST*I`, `I*DI*I` | 18 `SUBP` declarations (13-30); parameter reads (35-104); `13,VJM,ASTEP` (213); label chains `IBCD → SYMBOL → BCD → SYMBOL` (579-637, 886-946, 1128-1172, 1236-1256); many `13,VJM,MOVE` (646-816, 955-978); packed decimals `3714631463146314`, `4054000000000000` (1415, 1433) and ISO `6H *10` (1438). |
| AXISC | 267 / 45 | Calendar/time axis drawer: same parameter reads and `MOVE`/`SYMBOL` rendering as AXES, but the literal table holds all twelve Russian month abbreviations (ЯНВ, ФЕВ, МАР, АПР, МАЙ, ИЮН, ИЮЛ, АВГ, СЕН, ОКТ, НОЯ, ДЕК); it converts a month number into the corresponding string via indexed ISO constants and draws calendar ticks. | `SYMBOL`, `ABS`, `AMIN1`, `MOVE`, `RDB`, `IABS`, `IRDB`, `R*DI*I`, `I*MU*I` | `13,VJM,IRDB` (26, 37); parameter copies to 103B..116B (39-53); `13,VJM,SYMBOL` (283, 345); ISO month literals (370-404): `6HMAP`, `6HMAЙ`, `6HOKT`, `6HИЮH`, `6HИЮЛ`, `6HCEH`, `6HДEK`, `6HФEB`, `6HЯHB`, `6HHOЯ`, `6HAПP`, `6HABГ`. |

**Notes.** AXES' second label block (around lines 990-1290) recomputes limits
using `RDB`+`MAX0`/`AMIN1` and `I*DI*I`, so it is most likely the
secondary/alternate axis scale **[I]**. AXISC has no `ASTEP` or `BCD` calls:
the month table replaces numeric label generation.

---

## 5. Bars, boxes, blanking and bit arrays

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| BAR | 402 / 6 | Draws a bar (e.g. histogram/hatched rectangle): reads two coordinates with `IRDB`, transforms them with `TMF`, outlines the rectangle via `MOVE`, then computes a hatch count with `R*ST*I` and repeats diagonal hatch strokes in a loop until the counter reaches the limit. | `MOVE`, `TMF`, `IRDB`, `R*ST*I` | `13,VJM,IRDB` (21, 32); first outline TMF/MOVE sequence (50-81); second outline (85-141); hatch setup `13,VJM,R*ST*I` (279, 288); hatch loop at 0260B with repeated TMF/MOVE (341-471) and `7,X-A,40B / ,UZA,*0260B` (472-473). |
| BARS | 45 / 2 | Repeated-bar driver: saves two coordinates, sets up pointer cells *0050B..*0057B, calls `BAR` once, then advances x by a step from *0056B and y by 1 each iteration until a counter at *0055B expires. | `BAR` (itself; entry symbol `BAR`, recursive call) | `BAR :,SUBP,` (13); `13,VJM,BAR` (50); increment `7,XTA,2 / ,WTC,*0056B / ,A+X,` (51-54) and `7,A+X,1` (56-58); loop test `,WTC,*0055B / ,X-A,` (60-62). |
| BITA | 346 / 12 | Integer bitmap/array index engine: operates on five or six integer arrays via WTC-indirect pointers; nested loops (limits at *0410B..*0412B) compute linear indices using multipliers 0, 1, 2, 10, -1 (`I*MUI*`, `I*MU*I`) and write results into neighbour cells at offsets -1..-5. Looks like rasterisation/bit-array addressing with stride 10 **[I: exact host data structure not visible]**. | `IABS`, `I*MUI*`, `I*MU*I` (external library helpers) | `13,VJM,I*MU*I` (68, 210, 330, 335, 344, 354); `14,VJM,I*MUI*` (308, 330, 344, 354, 403, 410, 416, 423, 430); `13,VJM,IABS` (171, 175); constants `0,0,0,0,0,0,1,2,10,-1` (441-450); nested loops 18-98, 115-244, 257-278. |
| BLANC | 135 / 15 | "Begin blanking" state save: uses `*GFBLAN*` (LC 11), `*GFATBL*` (LC 6) and `*GFATRN*` (LC 7); toggles a blanking flag with XOR (`AEX`) against masks 16/17, then saves/restores eight groups of 16-word tables (at *0151B, *0171B, *0211B, *0231B, *0251B, *0271B, *0311B, *0331B, *0351B, *0371B) indexed by GAM/5, before calling `BLANCH`. | `GFFALS`, `BLANCH` | state pointers (13-36); `,AEX,` and `,U1A,*0013B` (54-55); eight indexed table copies (69-113, 114-155); `13,VJM,GFFALS` (171); `13,VJM,BLANCH` (215); tables *0153B..*0373B (233-261). |
| BLANCH | 642 / 7 | "Blanking change": recomputes the blanking/window transformation when a viewport or window changes; compares old/new coordinate pairs (GAK/2..GAL/2 of `*GFBLAN*`), computes scale and rotation with `ATAN2`, `SIN`, `COS`, updates `*GFBLAW*` (LC 4), calls `MOVBL1` to move blanking limits and `STOP*` on invalid (zero/degenerate) input; uses `R*DI*I`/`R*ST*I` for angle and scale conversions. | `STOP*`, `MOVBL1`, `COS`, `SIN`, `ATAN2`, `R*DI*I`, `R*ST*I` | `13,VJM,ATAN2` (112), `SIN` (116), `COS` (120); `*GFBLAW*` constants (31, 457, 500); `13,VJM,R*DI*I` (472) and `R*ST*I` (474); `13,VJM,STOP*` (484); `13,VJM,MOVBL1` (715, 772); final state update (808-815). |
| BOX | 46 / 2 | Draws a rectangle by five calls to `MOVE`, walking the four corners built from two base addresses (INT 0 / INT 1) and two delta words; used by REGION to frame a region **[I: corner order]**. | `MOVE` | entry `MOVE :,SUBP,` (13); five `13,VJM,MOVE` (34, 42, 49, 57, 66); `*0046B:,INT,0 / *0047B:,INT,1` (85-86); `REGION.mad:167` calls `BOX`. |

**Notes.** `BARS` calls the symbol `BAR`, which is also the name of the
separate library module; both files define `BAR :,SUBP,`, so BARS is a
multiple-bar driver that relies on the same entry symbol. `BITA` contains no
floating-point code at all: all arithmetic is integer (`IABS`, `I*MUI*`,
`I*MU*I`, shifts via `ASN`), which distinguishes it sharply from the geometric
modules. It probably prepares bit-mapped hatch/shading data **[I]**.
`BLANC` + `BLANCH` are the only modules in this range that manipulate the
blanking state blocks; `BLANCH`'s `STOP*` path is taken when a computed scale
or count is invalid.

---

## 6. Alphabetical master table

| Module | Zone / word (dec) | Size cmds/const (BSS) | Function (summary) |
|---|---|---|---|
| ABUFF | 625 / 800 | 3 / 0 (0) | 3-command index-register/buffer-address helper. |
| ADDLEV | 624 / 0 | 55 / 1 (13) | Adds increments to GRAFOR level arrays (contour levels). |
| ANGLER | 609 / 896 | 72 / 5 (7) | atan2-style polar angle with quadrant correction. |
| APPOLY | 595 / 768 | 271 / 7 (32) | Polynomial approximation of tabulated data with error table. |
| ARCANG | 609 / 992 | 275 / 11 (22) | Computes arc angle endpoints and mirror/quadrant cases. |
| ARCC1 | 610 / 192 | 210 / 7 (24) | Circle through three points (center, radius, angle). |
| ARCELA | 610 / 352 | 77 / 3 (14) | Ellipse arc, variant A: quadrant selection then `ELIPS`. |
| ARCELB | 610 / 448 | 105 / 3 (25) | Ellipse arc, variant B: sin/cos rotation then ARCANG/AREB1/ARCELA. |
| ARCIA | 610 / 544 | 165 / 10 (24) | Principal arc interpolator emitting points with `MOVE`. |
| ARCIB | 610 / 704 | 36 / 0 (12) | Arc wrapper: ARCANG then ARCIA. |
| ARCIC | 610 / 768 | 51 / 0 (15) | Arc wrapper: ARCC1, ARCANG, ARCIA. |
| ARCID | 610 / 832 | 46 / 0 (13) | Arc wrapper: radius via SQRT, angle via ANGLER, then ARCIA. |
| ARCOCC | 610 / 896 | 722 / 20 (36) | Large `*GFGEL*` arc cooker: center/radius/angles with clipping, six outputs. |
| ARCOLC | 611 / 384 | 665 / 15 (34) | Arc drawing from `*GFGEL*` with CIRTAC, MOVE, STRMOD. |
| ARCOLL | 611 / 896 | 225 / 11 (22) | Rotated-ellipse arc: solves coordinates and rotates endpoints. |
| AREB1 | 612 / 64 | 140 / 11 (17) | Ellipse arc angle refinement via SIN/COS/ATAN over four limits. |
| ARROW | 612 / 192 | 270 / 12 (24) | Arrow drawing (shaft + straight or curved head). |
| ASTEP | 583 / 544 | 323 / 31 (20) | Axis tick-step computation (powers of ten, rounding). |
| ATRAN2 | 591 / 800 | 156 / 4 (12) | Composes two homogeneous affine transformation matrices. |
| AXES | 583 / 800 | 1351 / 33 (100) | Draws axes, tick marks and numeric labels (BCD/SYMBOL). |
| AXISC | 591 / 384 | 267 / 45 (54) | Draws calendar axis with Russian month labels. |
| AXONOM | 599 / 0 | 24 / 4 (0) | Axonometric matrix rotation (`HCROT1`, `*GFMATR*`). |
| BAR | 591 / 96 | 402 / 6 (65) | Draws a hatched bar/rectangle (TMF + MOVE). |
| BARS | 591 / 32 | 45 / 2 (12) | Repeated-bar driver calling BAR with stepped coordinates. |
| BCD | 581 / 0 | 117 / 73 (0) | Two-entry binary/decimal conversion for numeric labels. |
| BEGLEV | 592 / 96 | 76 / 21 (4) | Begins nested affine-transform level; error on excessive nesting. |
| BITA | 624 / 384 | 346 / 12 (40) | Integer bit-array/raster index arithmetic (stride 10). |
| BLANC | 594 / 416 | 135 / 15 (240) | Saves blanking state; toggles blanking flags; calls BLANCH. |
| BLANCH | 592 / 672 | 642 / 7 (30) | Recomputes blanking/window transform (ATAN2/SIN/COS, MOVBL1). |
| BOX | 582 / 128 | 46 / 2 (7) | Rectangle outline via five MOVE calls. |
| BUFL | 620 / 736 | 66 / 0 (13) | Line-buffer flush with clipping via recursive LININT. |
