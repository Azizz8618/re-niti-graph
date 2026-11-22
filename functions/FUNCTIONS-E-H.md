# Library 22 (ГРАФОР-СУД): function of every E*, F*, G*, H* module

**Count and source.** The assigned range contains **29 distinct module names** (the task
header says 30, but the explicit list holds 29; all 29 are described below). Every
statement is based on the **dtran MADLEN disassembly of BESM-6 system library 22
(ГРАФОР-СУД), volume 2048** (`/home/azizz/Yandex.Disk/dtran/dtran -F dms`), catalog zone
`0o1100`, bodies in zones `0o1105..0o1162`; the 29 `.mad` files in
`../madlen/<name>.mad`. Evidence references are **1-based line numbers inside those
`.mad` files**. Where the disassembly does not prove intent, the conclusion is tagged
`[I]` (inference). Supporting audits `../madlen/AUDIT/IO-MODULES.md` and
`OVERLAY-HINT.md` were used only for cross-checking the low-level exchange paths.

## How to read the listings (dtran MADLEN notation)

* `14,VTM,*0001B` - set index register R14 to the address of label `*0001B`;
  `,ATI,9` / `,ITA,14` move accumulator to/from an index register;
  `,ITS,14` also pushes the old accumulator on the stack; `,STI,14` pops it back.
* `,WTC,<cell>` followed by `,XTA,` / `,ATX,` reads / writes the word whose address is
  held in `<cell>`; `,UTC,<cell>` sets the address modifier directly to `<cell>` `[I]`.
* `7,XTA,n` / `7,ATX,n` - read / write frame slot `n` (R7 is the frame pointer);
  negative slots (`-1`, `-5`) are local temporaries below the frame.
* `13,VJM,<name>` - subroutine call with the return-address stack in R13;
  `14,VTM,<arg>` + `,ITS,14` builds the argument list in R14;
  `13,VJM,` with an empty operand is an **indirect** call through the modified address.
* Standard prologue: `7,MTJ,8 / 14,MTJ,10 / 7,VTM,<frame> / 7,STX,<n> ... /
  ,ITS,13 / ,ITS,8 / ,ITS, / ,NTR,3 / ,NTR,2 / 10,UJ,`; the mirror epilogue
  `,STI, / ,STI,7 / ,STI,8 / 8,UJ,` restores R13/R7/R8.
* `,NTR,3` / `,NTR,22B` bracket the sign-sensitive tests (`,ASN,64-7` + `,UZA,`,
  `,ARX,` + `,UZA,`).
* `,*50,105B`, `,*70,`, `,*72,`, `,*74,` are dtran tokens for BESM-6 extract codes
  Э50 (УВВ / device exchange), Э70 (zone exchange), Э72, Э74 (STOP) `[I]`.

## Alphabetical master table

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| E70 | 11/0 | Э70-entry wrapper: calls `*70` and `NEXTZN` in sequence | `*70`, `NEXTZN` (VJM) | E70.mad:13-31 |
| ELIPS | 223/6 | Draws an ellipse from centre/axes/angle by stepping and emitting points | `ABS,SIN,COS,SQRT,MOVE,RDB,R*ST*I` | ELIPS.mad:13-19,25-275 |
| ELPS | 50/3 | Thin wrapper: prepares `*GFBFTR*` frame values and calls `ELIPS` | `COS,SIN,MOVE,ELIPS` | ELPS.mad:13-18,21-77 |
| ENDLEV | 102/13 | Closes a nesting level of a GRAFOR description; checks bracket balance | `MTMPL,FT*571,FT*003,STOP*` | ENDLEV.mad:13-44,47-152 |
| EXTREM | 141/1 | Scans points via XPOL/YPOL and accumulates X/Y extrema | `XPOL,YPOL` | EXTREM.mad:13-14,17-172 |
| FATARC | 122/7 | Draws a thick (fat) arc: two boundary arcs plus end caps | `RDB,ARCANG,ARCIA,R*DI*I,MOVA,ABS,SIGN,MOVE` | FATARC.mad:13-22,25-158 |
| FATLIN | 110/10 | Draws a thick (fat) line: parallel edges and caps | `RDB,ANGLER,SQRT,MOVE,R*DI*I,MOVA` | FATLIN.mad:13-20,23-140 |
| FCATBD | 1/0 | One-instruction stub: `,STI,` (accumulator to index register + stack pop), return via R13 | none | FCATBD.mad:13-14 |
| FNROOT | 423/4 | Root finder: bracket refinement plus ITPLBV interpolation | `ITPLBV,R*DI*I` | FNROOT.mad:13-20,23-516 |
| FOPEN | 37/10 | Low-level file open / descriptor builder; calls MDBUFF, Э74 STOP path | `MDBUFF`; `,*74,` | FOPEN.mad:13-74 |
| FORFIT | 164/7 | Outputs a fitted/smoothed curve through input points | `IRDB,R*DI*I,ABS,IABS,SIN,COS,TMF,MOVE,I*MU*I` | FORFIT.mad:13-21,24-212 |
| FORIF | 142/11 | Implicit-function curve plotting with two caller-supplied callbacks | `SIN,COS,I*MU*I`, 2 indirect `13,VJM,` | FORIF.mad:13-15,18-180 |
| FORIT | 136/10 | Iterative companion of FORIF: parameter/coordinate iteration | `SIN,COS,I*MU*I` | FORIT.mad:13-15,18-176 |
| GDISC | 16/1 | Disk-exchange primitive: Э50 with function codes 105B/115B/116B | none (extops only) | GDISC.mad:13-37 |
| GFFALS | 71/57 | GRAFOR error reporter: 8 ISO messages selected by an error code | `FT*571,FT*003,FT*002,ENDPG` | GFFALS.mad:13-21,24-101 |
| GIVENZ | 37/5 | Bitmap scan that allocates/returns a free zone number | none | GIVENZ.mad:13-73 |
| GIVZON | 46/1 | Full zone-allocation chain GDISC→RCATAL→GIVENZ→SETREF→WCATAL→FDISC | `GDISC,RCATAL,GIVENZ,SETREF,WCATAL,FDISC` | GIVZON.mad:13-18,21-89 |
| GOBSEK | 252/7 | Object/section processor: bank/scale computation and error reporting | `GFFALS,FLOAT,ABS,SQRT,I*DI*I,I*MU*I` | GOBSEK.mad:13-30,34-322 |
| GRID | 114/2 | Draws a coordinate grid by repeated MOVE in two directions | `FLOAT,MOVE` | GRID.mad:13-14,17-138 |
| HCIND | 45/1 | Maintains/returns the hidden-line index | none | HCIND.mad:13-82 |
| HCINV | 323/10 | Inverts the 4x4 homogeneous matrix in `*GFMATR*` | `I*MUI*,R*PO*I` | HCINV.mad:13-19,38-451 |
| HCLINE | 22/0 | Hidden-line-aware line: calls LINEO only if enabled | `LINEO` | HCLINE.mad:13-31 |
| HCMULT | 127/6 | Multiplies the 4x4 homogeneous transformation matrix | `I*MUI*` | HCMULT.mad:13-131 |
| HCNCRD | 63/0 | Transforms 3D coordinates by `*GFMATR*` and applies the w-divide | none | HCNCRD.mad:37-118 |
| HCPRSP | 21/1 | Perspective setup: normalise a matrix row and call HCMULT | `HCUNIT,HCMULT` | HCPRSP.mad:13-35 |
| HCROT1 | 143/5 | Builds a rotation from a direction vector using ATAN2 and TDROT | `ABS,SQRT,ATAN2,TDROT` | HCROT1.mad:16-182 |
| HCSURF | 224/6 | Draws a hidden-line surface as a sequence of sections | `IABS,ISIGN,I*MU*I,I*MUI*,TDSECT` | HCSURF.mad:25-294 |
| HCUNIT | 61/5 | Normalises a 3-vector to unit length | `I*MUI*` | HCUNIT.mad:13-80 |
| HISTGM | 434/6 | Draws a histogram with automatic scaling | `IRDB,ABS,MOVE,TMF,R*ST*I` | HISTGM.mad:13-17,20-518 |

## 1. Low-level exchange / library layer (E70, GDISC, GIVENZ, GIVZON, FOPEN, FCATBD)

These six modules are the ones relevant to the question whether library 22 could serve
the monitor's OVERLAY* worker. **Observed:** the Э70 entry (`E70`, `*70`), the Э50
exchange primitive (`GDISC`) and the zone/catalog chain (`GIVZON` via `GIVENZ`) are all
present and intact in this library. **Inference `[I]`:** no `.mad` file names OVERLAY,
FIND0, IO1 or IO3, so no resolved call edge exists in this corpus; a worker doing
"find module in catalog + copy body" would functionally match `RCATAL`/`RZON`/
`E70`/`*70`/`GDISC` (see `OVERLAY-HINT.md`). Two readings remain: the worker calls
this GRAFOR layer through REDAKT's link map, or it uses the monitor's own Э70 and
merely loads library-22 modules. The disassembly cannot decide between them.

### E70 (11 commands, 0 constants, 0 BSS) - Э70 wrapper
*Purpose.* Thin catalog-facing wrapper for the Э70 exchange: it declares `*70` and
`NEXTZN` as external subprograms and calls them in that order `[I]`.
*Algorithm / registers.* `,ITS,7` and `,ITS,9` save R7/R9; `*0001B:,ITS,13` saves the
return stack pointer; `7,VTM,*0001B`, `,XTS,` and `15,XTA,-4` fetch the caller's
argument word from frame slot `-4` into R15; `,ATI,9` copies it to R9; then
`13,VJM,*70` (line 23) and `13,VJM,NEXTZN` (line 25) are the two calls. Epilogue
`,STX, / ,STI,13 / ,STI,9 / ,STI,7 / ,STX, / 13,UJ,` (lines 26-31) restores the
registers and returns through R13.
*Notable.* No extop in E70 itself - the actual Э70/Э50 instructions live in `*70`
(`_s70.mad`: `,*50,1206B` line 68, `,*50,115B` line 82, `9,*72,` line 83,
`,*50,116B` line 85). E70 contains the literal `15,XTA,-4` (frame-slot argument fetch)
and uses R7/R9/R13/R15 only. Evidence: E70.mad:13-31.
*OVERLAY relevance `[I]`.* This is the named Э70 entry point; if the failing exchange is
the GRAFOR Э70, E70 (or `*70` directly) is the module to inspect.

### GDISC (16 commands, 1 constant) - low-level disk exchange
*Purpose.* The small Э50-based disk primitive of library 22; three `,*50,` exchanges
with function/device operands `105B`, `115B`, `116B` `[I]`.
*Registers / cells.* R3 (set to literal `71717B`, line 20), R8 (masks with `15B`,
`46B`, `47B` at lines 19/34/37), R9 (holds the control word read from frame slot 4:
`9,XTA,4` lines 22/25/28/36, shifted right 18 bits by `,ASN,64-18` line 23 and by
12 bits at lines 31/43-44), R12 (loop/attempt counter, tested by `12,V1M,*0013B`
line 27 and reset by `12,VTM,1` line 35), R13 (return stack, saved/restored lines
17/30/32) and R15 (exchange word: `15,AOX,` / `15,ATX,` / `15,*70,-1` in the sibling
`*70`). Only constant is `,LOG,770000` (line 37), the mask used by R8.
*Algorithm.* After prologue (lines 13-21) the control word is tested; if the masked
pattern matches, `,*50,105B` is issued (line 26); otherwise the branch at line 24
goes to `12,V1M,*0013B`. Path `,*50,115B` (line 28) then `,*50,116B` (line 33)
forms the second/third exchange; both converge on the shared epilogue at line 29.
The `12,VTM,1` / `,UJ,*0001B` pair (lines 35-36) is a re-entry stub that restarts the
exchange with R12 = 1.
*Notable.* No named `VJM` calls - all I/O is done by extops. Evidence: GDISC.mad:13-37.
*OVERLAY relevance `[I]`.* A disk open/read/close triplet, exactly the primitive an
overlay loader's catalog/body read would ultimately reach; it does not itself touch
the catalog.

### GIVENZ (37 commands, 5 constants) - free-zone bitmap scan
*Purpose.* Allocates a zone number by scanning a bit map, setting a bit and returning
the new value `[I]` ("GIVE N(ew) Z(one)").
*Registers / cells.* R8 (base + masks `8,AAX,43B` lines 32/35), R9 (address of the
frame argument: `9,XTA,12B` line 16, `9,XTA,14B` line 25), R11 (bitmap pointer,
`11,XTA,1` / `11,XTS,1` lines 31/33 and `11,UTM,1` lines 50/56), R12 (second pointer,
`12,UTM,1` lines 53/59), R14 (candidate value, seeded with literal `1000B` at line 46
and incremented at line 60), R15 (accumulator for XOR/OR, lines 29/36/68).
*Constants.* `,LOG,1` (74), `,LOG,4000000000000000` (75, high/sign bit), `,INT,0`
(76), `,LOG,77777` (77, 0o77777), `,LOG,777` (78, 0o777) - the last two are the
zone/bank bit masks.
*Algorithm.* Prologue lines 13-14 saves R10 and takes the argument in R9. Lines
16-24 select one of two modifier setups depending on frame slot 12. Lines 25-40
read frame slot 14, rotate (`ASN 64-1`), XOR with the mask and branch on equality.
The scan at `*0022B` (lines 48-61) walks R11/R14 until `VZM`/`UZA` succeeds, then sets
a bit with `14,AOX,` (line 68) and writes it back with `14,ATX,` (line 69). The
alternate path at `*0016B` (lines 41-47) uses shifts 20/39 and mask `42B` for a
different field. Exits at lines 62-72 return either the raw word, the masked word
(ORed with `40B`) or a flag; `10,STX, / 13,UJ,` restores the caller.
*OVERLAY relevance `[I]`.* Pure in-memory allocator; reached from `GIVZON`, not an
exchange itself.

### GIVZON (46 commands, 1 constant, 3 BSS) - zone allocation chain
*Purpose.* The complete "give zone" transaction: open disk, read catalog, choose a
zone via GIVENZ, optionally set a reference, write catalog, close disk.
*Registers / cells.* R14 is the argument-list pointer (`14,VTM,*0047B` with
`,ITS,14` at lines 32-33 and 50-51); R13 is the return stack; R7/R8 are saved in the
entry stub `*0036B` (lines 75-85). BSS cells: `*0047B` (argument/zone number),
`*0050B` and `*0051B` (parameter words written via `,WTC,` + `,ATX,`).
*Call sequence.* `13,VJM,GDISC` (24), `13,VJM,RCATAL` (28), `13,VJM,GIVENZ` (34),
then a flag comparison using `,NTR,3`, `,ITS,`, `7,XTA,1`, `15,AEX,` (lines 35-41).
On equality (`*0015B`) it calls `13,VJM,SETREF` (52), writes cell `*0051B` (56-57),
then `13,VJM,WCATAL` (63) and `13,VJM,FDISC` (67). On inequality it jumps to
`*0033B` (43) which writes cell `*0051B` and joins the WCATAL/FDISC tail at
`*0030B` (64-68). Epilogue lines 86-89 restores R13/R7/R8 and returns via R8.
*Notable.* `,NTR,3` / `,NTR,22B` pairs (35-36, 53-54, 58-59, 62-63, 72-73) surround
each cell write; constant `,LOG,0` at line 90.
*OVERLAY relevance `[I]`.* This is the natural analogue of an overlay "COPY" step
that must obtain a zone before moving a module body.

### FOPEN (37 commands, 10 constants) - file open / descriptor builder
*Purpose.* Low-level GRAFOR file-open routine: builds a descriptor word from the
caller's parameters, writes it to several output cells and calls MDBUFF, with an
Э74 (STOP) on the failure path `[I]`.
*Registers / cells.* R6 is the descriptor word, repeatedly shifted and masked
(`,ASN,64+40` line 29, `64-8` line 34, `64+32` line 41, `64+12` line 51, `64-18`
line 43; `6,APX,40B/41B` lines 40/68, `6,AAX,36B/44B/45B` lines 45/71/50,
`6,AEX,45B` line 48, `6,ARX,37B` line 49, `6,AUX,42B` line 69, `,YTA,` line 52).
R10 is the output buffer/pointer (`10,ATX,3/16B/4/5/1/12B` lines 28,42,54,58-60;
`10,WTC,` line 61). R11 holds the source pointer (`11,XTS,` lines 27,47; `11,XTA,`
lines 33,39,67). R12 is the stack pointer; R13 is a loop counter tested by
`13,V1M,*0036B` (32) and `13,V1M,*0033B` (38). R15 fetches the return address from
frame slot `-4` (`15,XTA,-4` line 17) and accumulates with `15,ARX,` (46).
*Call.* `13,VJM,MDBUFF` (line 56) with the argument block prepared in R14.
*Constants.* `,LOG,7777` (75), `,LOG,1` (76), `,LOG,340701603407` (77),
`,LOG,1703607417` (78), `,LOG,770777` (79), `,INT,1` (80), `,LOG,777` (81),
`,LOG,1777` (82); `,*74,` at line 74 is an Э74 STOP, reached from the error path
at line 33/67 `[I]`.
*OVERLAY relevance `[I]`.* File-open is not the catalog/zone lookup that FIND0/COPY
perform, but its STOP path matches an "exchange fails before device is mounted"
symptom if the worker opens a file to locate the overlay.

### FCATBD (1 command, 0 constants) - stack/register stub
*Purpose.* A one-command entry point: `,STI,` stores the accumulator into the
register named by the address field and pops the stack, then `13,UJ,` returns via
R13 (lines 13-14). Functionally a "set catalog-block descriptor register and
return" trampoline `[I]`. No extops, no calls, no cells. Evidence: FCATBD.mad:13-14.
*OVERLAY relevance `[I]`.* Only if the worker uses it as a register-setting alias;
there is no disk or catalog operation in the body.

## 2. E/G geometry, fitting and diagnostics

### ELIPS (223/6, 32 BSS)
Draws an ellipse. It takes the half-axes and rotation, calls `ABS` on both (25,30),
computes `sin`/`cos` of the rotation (50,58), takes `SQRT` of the derived quantity
(67), then iterates over the parameter angle: each step recomputes `sin`/`cos`
(80/91, 205/214), forms the two coordinates (84-96 and 208-217), emits the point
through `MOVE` (121, 224, 275) and reads back the current pen position with `RDB`
(124, 128). `R*ST*I` (153) finalises the stroke; `NTR` sign tests at 158-175 and
`X-A` convergence tests at 233, 276 control the loop. Constants: three packed real
words at lines 298-300; BSS scratch arrays `*0231B`(3), `*0235B`(10),
`*0247B`(3) plus scalars. Evidence: ELIPS.mad:13-19,25-275.

### ELPS (50/3, 11 BSS)
Ellipse wrapper for the active graphic frame. It reads the 2-word common block
`*GFBFTR*` and its `+1` word (`GAK/2`) with `UTC`+`XTA` into frame slots 4/5
(lines 21-26), forms the rotated centre with `COS`/`SIN` (33, 40), calls `MOVE`
(51) to position the pen, then sets up an argument list in R14 (`*0050B`, `*0052B`,
`*0054B`, `*0055B`, `*0056B`, `*0057B`, `*0060B`, `*0061B`, `*0062B`, `*0063B`)
and calls `ELIPS` (line 69), followed by a second `MOVE` (76) to restore.
Notable constant `,LOG,3550737215211226` (95) and `,TEXT, 8HDK0` (96).
Evidence: ELPS.mad:13-18,21-77.

### ENDLEV (102/13, 2 BSS)
Ends a GRAFOR nesting level. It declares the 115-word common block `*GFATRM*`
with symbolic offsets `GAL/1..7`, `GAM/0..7`, `GAN/0..7`, `GAO/0`, `GAK/2,3,4`
(lines 13-44), loads 17 of those words into the R14 argument list (47-82) and
calls `MTMPL` (83). Two loops (88-100 and 105-117) use R1 as counter and `UTC`
indirect reads of `GAN/1`, `GAN/2`, `GAM/3` to accumulate into frame slot 7; lines
118-141 write the results back into `GAN/3..7` and `GAO/0`; line 136-141 decrements
`GAK/2` via `UTC`. On zero it calls `FT*571`, `FT*003`, `STOP*` (150-152) with the
ISO message at lines 169-173, which decodes as
`(10X,2HНЕВЕРНОЕ ЧИСЛО СКОБОК)` - "wrong number of brackets". Evidence:
ENDLEV.mad:13-44,47-152,169-173.

### EXTREM (141/1, 16 BSS)
Computes extreme X/Y values of a graphical object. It copies the current bounds
between cells `*0147B`, `*0150B`, `*0153B`, `*0155B`, `*0157B` (17-24), and if the
new point is outside (`ASN 64-7` + `UZA` at 30-33) calls `XPOL` (41, 103) and `YPOL`
(50, 113) to obtain the next coordinates. R1/R2 are loop counters read with `UTC,-1`
(lines 74/79, 94/100); each candidate is compared with frame slots 4/5 and the
min/max cells `*0153B..*0156B` are updated (115-156). Frame slots 2/3 count the
accepted extrema (157-172). Evidence: EXTREM.mad:13-14,17-172.

### FATARC (122/7, 15 BSS)
Thick-arc drawing. Reads the line half-width from `*GFBFTR*`+1 into frame slots
11/12 (25-30), gets the two arc endpoints with `RDB` (33, 37), computes `radius²`
with frame slot 13 (39-41), forms the centre from the squared coordinates (42-57),
takes no SQRT here but uses `ARCANG` (64) and `ARCIA` (72, 122, 148) to draw the
two boundary arcs. `R*DI*I` (77, 100) scales offsets, `ABS` (94) and `SIGN` (111)
fix signs, `MOVA` (90, 135) and `MOVE` (157) connect the caps. Constants: four
packed real words (180-183), including `4413200000000000`,
`3557270243656050`, `3654631463146314`. Evidence: FATARC.mad:13-22,25-158.

### FATLIN (110/10, 12 BSS)
Thick-line drawing. Reads half-width from `*GFBFTR*`+1 (23-28), reads the two
endpoints with `RDB` (31, 35), computes the squared length in frame slot 14
(37-39), obtains the direction angle with `ANGLER` (52), the perpendicular offset
with `SQRT` (69) and the scaled offsets with `R*DI*I` (84). It then draws the two
parallel edges and caps with `MOVA` (97, 107, 123, 130) and `MOVE` (79, 139).
Constants mirror FATARC (160-164) plus `,TEXT, 8HCK0` (163). Evidence:
FATLIN.mad:13-20,23-140.

### FNROOT (423/4, 50 BSS)
Numerical root finder. Two common blocks, `*DRINFN*` (3 words, offsets `GAK/2,3`)
and `*DRFN*` (3 words, offsets `GAK/5,6`), hold the interval and tolerance
(lines 13-18). The routine has two symmetric branches (`*0001B..*0207B` and
`*0211B..*0406B`) that expand/contract the bracket by repeatedly adding and
subtracting `GAK/2` to frame slot 6 (54-58, 105-108, 303-307, 344-347), call
`R*DI*I` to scale (71, 74, 290, 313), and call `ITPLBV` (134, 225, 373, 464) with
nine-word argument lists built from cells `*0451B..*0455B`, `GAK/6`, `*0460B`,
`*0465B`, `*0472B`. The result is compared with `GAK/5` (246-248, 485-487); the
trial counter in cell `*0456B` is incremented (249-254, 488-493) and the interval
endpoints `GAK/6` / `*0457B` are updated (255-260, 494-499). Constant
`,LOG,4010000000000000` = 0.5 (542) `[I]`. Evidence: FNROOT.mad:13-20,23-516.

### FORFIT (164/7, 30 BSS)
Fitted-curve output. Reads two integer parameters with `IRDB` (26, 36); a
mismatch branches to the error epilogue (33/`*0150B`). It then reads the step from
`*0215B` (43-47), the two offsets from `*0222B` (52-61, with `IABS` at 67) and
calls `R*DI*I` (82, 87) to build the scaling factors. A loop (101-161) steps the
curve, computes `sin`/`cos` corrections (140, 149), updates the accumulator cell
`*0220B` and emits through `TMF` (188) and `MOVE` (195); `I*MU*I` (206) finishes
the scaling. Constants `,LOG,4114441767013025` and `,LOG,4110000000000000`
(239-240). There is a self-loop `*0146B:,UJ,*0146B` (211) after `,WTC,*0207B`
(210), i.e. a trap/halt path `[I]`. Evidence: FORFIT.mad:13-21,24-212.

### FORIF (142/11, 26 BSS)
Implicit-function curve plotting `[I]`. A flag in cell `*0175B` selects between
two parameter sets (23-35, 36-51); frame slots 11/12/13 are derived by
`SIN`/`COS` (68, 72) and `I*MU*I` (95). The main loop `*0053B` (98-124) converges
on a step, using `7,ATX,23B/24B` swapping and an `ASN`+`UZA` test. Two **indirect**
calls `13,VJM,` (86 and 105), with the target built through `*0173B`, indicate
caller-supplied callbacks (function value / point output) `[I]`. Final cell
`*0176B` is written with `ATX,-1` (175-179). Constants: 4000000000000000,
4114441767013025, 4010000000000000, 4050000000000000, 4110000000000000
(lines 202-209). Evidence: FORIF.mad:13-15,18-180.

### FORIT (136/10, 25 BSS)
Iterative companion of FORIF `[I]`. Same flag-test structure on cell `*0167B`
(23-51), same trig pair (68, 72) and `I*MU*I` (92), but the loop at `*0044B`/`*0052B`
(85-120) updates cells `*0170B` and `*0171B` with `ATX,-1` (126-134) and writes
computed coordinates back to frame slots 10/16/17 (121-169). No indirect calls.
Constants identical to FORIF (201-204). Evidence: FORIT.mad:13-15,18-176.

### GFFALS (71/57, 2 BSS)
Central GRAFOR error reporter. It declares the 20-word common block `*GFGOBS*`
with offsets `GAK/2..5` (13-17) and the print routines `FT*571`, `FT*003`,
`FT*002`, `ENDPG` (18-21). It reads the error code from cell `*0151B`, adds frame
slot 2 (24-28) and dispatches through a jump table at lines 31-39 to eight ISO
message blocks (102-146):

| Code target | Message (decoded) | Lines |
|---|---|---|
| `*0015B` | `(6X,20НЕЛИШКОМ МНОГО СКОБОК)` - too many brackets | 102-106 |
| `*0021B` | `(6X,21НЕВЕРНОЕ ЧИСЛО СКОБОК)` - wrong bracket count | 107-111 |
| `*0027B` | `(6X,11НБАНК НОМЕР ,I2,7H ЛОПНУЛ)` - bank number overflowed | 112-117 |
| `*0036B` | `(6X,32НЧИСЛО ЭКРАНОВ БОЛЬШЕ ДОПУСТИМОГО)` - too many screens | 118-124 |
| `*0042B` | `(6X,31НЧИСЛО БАНКОВ БОЛЬШЕ ДОПУСТИМОГО)` - too many banks | 125-131 |
| `*0046B` | `(6X,15ННЕТЕ ПАРАМЕТРЫ)` - no parameters | 132-135 |
| `*0052B` | `(6X,29ННЕТО ГЕОМЕТРИЧЕСКИЙ ЭЛЕМЕНТ)` - no geometric element | 136-142 |
| `*0056B` | `(6X,16НВСЕ ТОЧКИ ВЫДАНЫ)` - all points issued | 143-146 |

Each branch passes a message address via `14,VTM,` + `,ITS,14` and calls `FT*571`
then `FT*003` (one also `FT*002`), and the `*0021B` branch calls `ENDPG` (51).
Final constant `,ISO, 6HGFFALS` (148) is the module-name literal. Evidence:
GFFALS.mad:13-21,24-101.

### GOBSEK (252/7, 15 BSS)
Object/section processor `[I]`. Declares `*GFNTCH*` (51 words, offsets
`GAK/2..6`) and `*GFGOBS*` (20 words, `GAL/0..3`), plus `GFFALS`, `FLOAT`, `ABS`,
`SQRT`, `I*DI*I`, `I*MU*I` (13-30). It validates a bank number by integer division
`I*DI*I` with divisors 0/1/2/4/8 stored at lines 359-364 and compares it with the
fields of `*GFNTCH*` (36-141). It computes a scale from the squared difference of
two coordinates using `SQRT` (161) and `ABS` (166), then rewrites fields
`GAM/0..GAK/6` of `*GFNTCH*` (188-226) and converts results with `FLOAT` (245,
257, 281, 291). On error it calls `GFFALS` with the literal `2` at `*0255B` (lines
320-322, 362). Evidence: GOBSEK.mad:13-30,34-322.

### GRID (114/2, 15 BSS)
Draws a coordinate grid. It reads the grid limits from cells `*0126B`, `*0132B`,
`*0131B` and the step from `*0125B` (17-37), converts the step with `FLOAT` (29,
92) and emits grid lines with `MOVE` (46, 58, 65, 113, 120). Two symmetric loops
at `*0024B` (52-82) and `*0061B` (107-137) walk the two axes; frame slots 3/4/5/6/7
hold the counters and swapped coordinates, `*0127B` and `*0130B` the increments.
Evidence: GRID.mad:13-14,17-138.

## 3. H C* - hidden-line / three-dimensional graphics

These modules share the common blocks `*GFMATR*` (34-word homogeneous 4x4
transformation matrix), `*GFCRD*`, `*GFSUR*`, `*GFLIM*`, and use R7-frame slots plus
R1..R5 as loop indices. They form one coherent pipeline: build/rotate/invert the
matrix, transform coordinates, draw lines/surfaces when visible.

### HCIND (45/1, 7 BSS)
Maintains the hidden-line element index. Reads a flag from cell `*0053B` (15-19),
a limit from `*0052B` (20-22), then loops at `*0006B` (25-45) comparing with cell
`*0051B` (28-30, 38-40) using sign tests. On match it copies frame slot 2 to slot 1
(46-49); otherwise it increments slot 2 (51-55). The convergence test `7,X-A,1`
(56-57) ends the loop and the result is stored into cell `*0050B` with
`,UTC,*0050B` + `,XTS,` (80-81) before the R8 return. No external calls.
Evidence: HCIND.mad:13-82.

### HCINV (323/10, 37 BSS)
Inverts the 4x4 homogeneous matrix `*GFMATR*` (13-35 map its 34 words to
`GAK/2`, `GAK/6`, `GAL/0..7`, `GAM/0..7`). Uses `R*PO*I` (222) and `I*MUI*` (339,
365, 391, 396). Three search loops (`*0004B`, `*0017B`, `*0077B` regions, lines
38-179) select pivot rows via cells `*0323B..*0326B` and `*0351B`, `*0352B`.
Lines 180-211 compute a determinant-like six-term sum of triple products of frame
slots 27..37; line 212-223 negates slot 3, forms slot 6 from slot 7+slot 10 and
calls `R*PO*I` with literal `1` (`*0334B`) and the 10-word block `*0335B`, then
multiplies by slot 4. Lines 245-326 recompute each matrix row by multiplying the
temporaries `*0350B..*0352B` by `GAL/1..GAM/7`, adding the translation term and
dividing by slot 14 (`7,A/X,14B`), writing to `*0353B..*0355B`. Evidence:
HCINV.mad:13-19,38-451.

### HCLINE (22/0, 4 BSS)
Hidden-line-aware line drawing. Reads the enable flag from cell `*0025B` (16-21);
if zero it skips to the epilogue (32). Otherwise it passes cells `*0023B`,
`*0024B`, `*0025B` as the argument list via R14 (22-30) and calls `LINEO` (31).
Evidence: HCLINE.mad:13-31.

### HCMULT (127/6, 15 BSS)
Matrix multiplication for the 3D pipeline. Declares `I*MUI*` (13) and uses four
internal helpers: `*0064B`, `*0077B`, `*0106B` plus the counter-update stub
`*0056B` (96-106). Two nested loops (16-65 and 71-94) use frame slots 3/4/5 as
counters and cells `*0127B`, `*0130B`, `*0131B`, `*0136B` (5 words), `*0143B`,
`*0144B`, `*0145B` (5 words) as matrix/accumulator temporaries; `I*MUI*` is
called at 131 and 144. Constants 0/1/4 at lines 174-179. Evidence:
HCMULT.mad:13-131.

### HCNCRD (63/0, 5 BSS)
Coordinate transformation with perspective divide. Declares `*GFMATR*`,
`*GFCRD*` and their offsets (13-34). For each of three input coordinates read from
cells `*0065B`, `*0066B`, `*0067B`, it multiplies by the corresponding matrix
column (`UTC,GAL/0`, `UTC,*GFMATR*`, `UTC,GAL/7`, etc.) and accumulates (37-55,
56-74, 77-97, 98-118). Row 4 (`GAL/0..GAL/3`) gives the homogeneous w, stored in
frame slot 1 (41-55); rows 1-3 are divided by it (`7,A/X,1`, lines 74, 95, 116)
and written to `*GFCRD*`, `GAK/6`, `GAK/7`. Evidence: HCNCRD.mad:37-118.

### HCPRSP (21/1, 1 BSS)
Perspective-matrix setup. Calls `HCUNIT` on `GAK/2` (`*GFMATR*`+16) to normalise a
vector (22-24), reads frame slot 0, divides it by the cell `*0022B` (25-28) and
stores the quotient into `GAK/7` = `GAK/2+13` (29-30). It then calls `HCMULT` with
`*GFMATR*` and `GAK/2` as the two arguments (31-35). Evidence: HCPRSP.mad:13-35.

### HCROT1 (143/5, 16 BSS)
Constructs a rotation from a direction vector. Takes `ABS` of the three components
from cells `*0163B`, `*0164B`, `*0165B` (22-36), squares and sums them (41-57),
takes `SQRT` twice (58-65), and computes two angles with `ATAN2` (96, 151) using
constants `*0151B`, `*0152B`, `*0153B`, `*0157B` and sign corrections driven by
the component signs (98-146, 153-162). Finally it calls `TDROT` twice (172, 182)
with the two angle values to build the rotation matrices, negating the second
angle for one of them (173-176). Constants `4110000000000000` and
`4114441766520421` (203-204). Evidence: HCROT1.mad:16-182.

### HCSURF (224/6, 36 BSS)
Hidden-line surface drawing. Reads integer limits with `IABS` (35, 42), checks
flags in cells `*0263B`, `*0264B`, `*0256B`, `*0260B` (48-89), computes a scale with
`I*MU*I` (124) and internal helpers `*0173B`/`*0200B` (131, 134, 158, 161).
`ISIGN` (181) fixes the sign and the surface is emitted by repeated `TDSECT`
calls (219) with an argument list assembled from cells `*0235B`, `*0236B`,
`*0246B`, `*0251B..*0253B`, `*0265B`, `*0266B` and frame slot 12 (188-219).
The trap loop `*0147B:,UJ,*0147B` (222-223) follows a `,WTC,*0242B` and is an
error/halt path `[I]`. Evidence: HCSURF.mad:25-294.

### HCUNIT (61/5, 6 BSS)
Unit-vector normalisation. Takes frame slot 1 into slot 5 (16-17), runs two
internal subroutines at `*0037B` and `*0043B` (19, 24, 49, 57) which decrement
temporary slots `-1`, `-5` and call `I*MUI*` (80). It halves components with
`ASN` (line 67 area) and compares frame slots 5/6 before choosing which temporary
to write (35-44). Used by HCPRSP. Evidence: HCUNIT.mad:13-80.

### HISTGM (434/6, 36 BSS)
Histogram plotting. Reads two integer parameters with `IRDB` (22, 33) and rejects
a mismatch (26-30). It sets up the scaling via `TMF` (48, 85, 105, 122, 157, 174,
192, 208) and `MOVE` (55, 92, 112, 129, 164, 181, 199, 215), takes `ABS` (62),
scales with `R*ST*I` (64, 228, 236), and loops over bars with counter frame slot 33
and step cell `*0474B` (216-287, 467-473). For each bar it emits up to four
rectangular strokes through `TMF`/`MOVE` using templates `*0435B` (0), `*0436B`
(1), `*0445B` (2), `*0450B`, `*0453B`, `*0455B` (13 words), with branches for
zero/positive/negative bar heights (288-466). Evidence: HISTGM.mad:13-17,20-518.

## Summary of low-level / OVERLAY-relevant findings

| Module | Zone exchange (Э70) | Э50 extops | Catalog/zone cells | Could OVERLAY* call it? `[I]` |
|---|---|---|---|---|
| E70 | via called `*70` | none in body | R7/R9/R13/R15, frame slot `-4` | Yes - named Э70 entry |
| GDISC | no | `105B`, `115B`, `116B` | R3=71717B, R8 masks, R9 slot 4, R12 counter | Yes - disk primitive |
| GIVENZ | no | none | R8/R11/R12/R14/R15; masks 77777, 777 | Indirectly, via GIVZON |
| GIVZON | via GDISC/RCATAL/GDISC chain | via GDISC | BSS `*0047B`,`*0050B`,`*0051B`; R14 arg list | Yes - zone allocation |
| FOPEN | no | none; `,*74,` STOP | R6/R10/R11/R12/R13/R15; 10 constants | Only for file open |
| FCATBD | no | none | stack/R13 only | Unlikely - 1-instruction stub |

The strongest inference `[I]`: if the OVERLAY* failure is the *GRAFOR library's* Э70
exchange, the chain to inspect is `E70 -> *70 -> Э50`, bracketed by
`GDISC`/`FDISC` and driven by `GIVZON`/`RCATAL`; if the worker uses the monitor's own
Э70, all six modules above are library-side equivalents that OVERLAY merely loads.
