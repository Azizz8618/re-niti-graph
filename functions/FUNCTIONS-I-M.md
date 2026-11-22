# Library 22 (ГРАФОР-СУД): functions of modules I*, K*, L*, M*

**Count: 41 catalog names in the requested range.** Source: `dtran` MADLEN disassembly of BESM-6 system library 22 (ГРАФОР-СУД), volume 2048, as stored in `../madlen/*.mad` (see `../madlen/INDEX.md` and `../madlen/README.md`). 38 modules have a real body and a `.mad` file and were read in full or in targeted chunks. 3 names (MDBUFF, MOVBL1, MOVBL3) are reference/entry-only records with no body on the volume, so no `.mad` exists for them; they are described from catalog/disassembly evidence and marked `[I]` where function is inferred.

Evidence format: `NAME.mad:NN` is a 1-based line number in the corresponding file. Statements tagged `[I]` are inference from call graph, buffer names and constants, not literal source text.

## Conventions observed in this library (applies to every module below)

- External calls in dtran output are `13,VJM,<SYMBOL>` (occasionally `14,VJM,<SYMBOL>`), i.e. jump via index register 13/14 used as the return link. The literal tokens `,CALL,` and `B n,` do **not** occur in these `.mad` files; `13,VJM,` is the call syntax to look for.
- A DMS "complex" module declares one or more entry points with `,<name>:,SUBP,`. Bodies are reached through a standard two-part trampoline: a prologue `14,VTM,*0001B / ,UJ,*00NNB` and a launcher of the form `7,MTJ,8`, `14,MTJ,10`, `7,VTM,*....`, `,ITS,13/1/8`, `10,UJ,` followed by the epilogue `,STI, ... ,STI,7/8`, `8,UJ,`. Variants with `9,VTM,n / 9,UTM,-1 / 9,UTC / 9,V1M,*loop` copy a parameter/argument block before transferring control.
- `*GFxxxx*` names are common (GRAPHOR) data buffers declared with `,LC,n`; `GAK/n`, `GAL/n`, `GAM/n`, `GAN/n` are `,EQU,` offsets inside them. Important buffers in this range: `*GFMATR*` (INIT), `*GFBFTR*` (MOVA, LITAN, MOVE1/2/3), `*GFAFTR*`, `*GFATRN*` (7-word affine transform), `*GFBLAN*` (11-word blanking/pen state), `*GFNTCH*` (51-word notch table), `*GFGOBS*` (20-word observed/gap table), `*GFCELL*` (9-word grid cell), `*GFINT*`, `*GFLOOK*`, `*GFISOL*`, `*GFVP*` (6 words), `*GFLMN*`, `*GFGEL*` (28 words), `*GFLSZ*`, `*DRIN*`/`*DRINFN*` (geometry/region state), `*DRITP*` (interpolation table state). Writing into these buffers is the main interface between modules; many modules also initialize them through trailing `,DATA,` / `1,SET,` records (MOVE1/2/3).
- `,WTC,addr` + `,UTC,`/`,XTA,` are the typical parameter fetch/store idioms; `,A*X,`, `,A/X,`, `,ASN,64-7` + `,ARX,` implement multiply, divide and sign tests (floating point). `,LOG,` and `,INT,` in the constant area are BESM octal words; recurring ones are `4000000000000000` (unity-like scale), `4050000000000000` (half-step), `0`, `1`, `2`, `3`, `-1`, `999` (sentinel).

## Group 1: line drawing and line arithmetic

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| LINEC | 127/11 | Draw a clipped straight line from integer point counts and real endpoints read from the data buffer; clips against drawing limits via AMAX1/AMIN1. | IRDB, RDB, IABS, TMF, AMAX1, AMIN1, MOVE | `LINEC.mad:13-19` SUBPs; `:22-60` two IRDB ints + four RDB reals; `:85` TMF; `:97,104,111,118` AMAX1/AMIN1; `:139,158` MOVE |
| LINEO | 203/11 | Same line plotter with an extra `WHERE` pen-position check and explicit absolute-value limit testing before clipping. | IRDB, RDB, WHERE, IABS, ABS, TMF, AMAX1, AMIN1, MOVE | `LINEO.mad:26,36` IRDB; `:47-61` four RDB; `:76` WHERE; `:96-107,132-143` ABS+AMAX1; `:183,229` MOVE |
| LINEMC | 156/11 | Line plotter that places a marker (tick/character) at each plotted point; no `WHERE` check. | IRDB, RDB, IABS, TMF, AMAX1, AMIN1, MOVE, MARKER | `LINEMC.mad:24,35` IRDB; `:46-60` RDB; `:109` TMF; `:179` MARKER; `:163,200` MOVE |
| LINEMO | 232/11 | Line plotter combining clipping, `WHERE` visibility test and markers at data points. | IRDB, RDB, IABS, WHERE, ABS, TMF, AMAX1, AMIN1, MOVE, MARKER | `LINEMO.mad:27,37` IRDB; `:48-62` RDB; `:98` WHERE; `:109,145,205` TMF; `:251,267,285` MOVE/MARKER |
| LGLINE | 233/5 | Logarithmic-scale line plotter: transforms coordinates with TMLGF, then clips and draws/marks the polyline. | IRDB, IABS, WHERE, TMLGF, ABS, AMAX1, MOVE, MARKER | `LGLINE.mad:25,36` IRDB; `:54` WHERE; `:101,122,247` TMLGF; `:194,254,284` MOVE; `:222,271` MARKER |
| INCLIN | 321/12 | Draw an inclined (tilted) line/hatching using a direction computed from R*ST*I and a step from integer parameters; clips and optionally marks points. | IRDB, RDB, IABS, WHERE, R*ST*I, TMF, ABS, AMAX1, AMIN1, MOVE, MARKER | `INCLIN.mad:28,39` IRDB; `:57` WHERE; `:60-74` RDB; `:114` R*ST*I; `:153,166,330` TMF; `:282,371` MOVE; `:313,388` MARKER |
| LINFIL | 115/3 | Pure arithmetic "fill between lines" routine: computes successive interpolated fill coordinates in arrays, no external calls. | none (only trampoline) | `LINFIL.mad:15-46` loop setup; `:73-115` inner accumulation; `:125-133` final store to `,WTC,*0122B` |
| LININT | 264/1 | Pure arithmetic linear interpolation/iteration over two arrays, duplicated for increasing and decreasing abscissa order; no external calls. | none (only trampoline) | `LININT.mad:15-35` first pass; `:48-70` interpolation `y0+(y1-y0)*(x-x0)/(x1-x0)`; `:174-232` mirrored second pass |
| LINT | 101/2 | Compute the intersection of a line with the current grid cell (`*GFCELL*`) and write it to `*GFINT*`; uses polynomial coordinate evaluators. | XPOL, YPOL | `LINT.mad:13-22` `*GFCELL*`/`*GFINT*`; `:33-58` ratio computation; `:108` XPOL; `:117` YPOL; `:146` `LOG,4050000000000000` |

Notes on the line family: LINEC/LINEO/LINEMC/LINEMO all read **two integers then four reals** (`:22-60` etc.) and use `TMF` as the loop/test routine; the four variants differ only in the extra visibility (WHERE), marker (MARKER) and clipping code. LINEO and LINEMO share almost identical bodies (`LINEO.mad:83-144` matches `LINEMO.mad:87-166`). LGLINE substitutes TMLGF for TMF, indicating a log-transformed coordinate system.

## Group 2: fitting, interpolation and numerical helpers

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| LESQ | 263/4 | Least-squares solver: builds normal equations from data arrays, inverts the symmetric matrix with SMINV and accumulates coefficients; large internal matrices. | SMINV, IABS, I*MU*I | `LESQ.mad:13-15` SUBPs; `:21,28` IABS; `:33,38,290` I*MU*I; `:171-177` setup + `13,VJM,SMINV`; `:347,350` `LOG,4050000000000000`; `:364` `BSS,35`, `:365` `BSS,11` |
| LSFIT | 314/31 | Least-squares polynomial fit of data read from the buffer; optionally fits logarithms (power law), checks polynomial degree, evaluates and plots the fitted curve, prints diagnostics on bad data. | IRDB, IABS, ALOG10, MINMAX, FT*571, FT*002, FT*003, ISIGN, LESQ, PVAL, ABS, TMF, MOVE, I*MU*I | `LSFIT.mad:31,41` IRDB; `:67,83,87,111` ALOG10; `:78,106` MINMAX; `:171-182` FT* routines; `:189` ISIGN; `:209` LESQ; `:238,325` PVAL; `:361` MOVE; `:399-410` ISO `"SUBROUTINE LSFIT DEGREE OF THE POLYNOMIAL IS DECREASED N=,I3)"`; `:411-416` ISO `"ERROR SUBROUTINE LSFIT DATA)"` |
| LSCALE | 110/4 | Coordinate scaling by a rotation: computes an angle with ATAN2, applies ROTATE and an affine transform ATRAN2; contains forward and inverse branches. | ATAN2, ROTATE, ATRAN2 | `LSCALE.mad:53,106` ATAN2; `:64,116` ROTATE; `:78,137` ATRAN2; `:157-160` `LOG,0`, `LOG,4114441766517106`, `LOG,4413200000000000`, `LOG,4050000000000000` |
| LITAN | 101/6 | Construct a tangent line to a circle/arc: reads circle parameters from `*GFBFTR*`, computes centre-to-point vector, angle (ANGLER, ATAN) and radius, emits SIN/COS endpoint. | RDCRC, ABS, IVEST, SQRT, ANGLER, ATAN, COS, SIN, GFFALS | `LITAN.mad:13-14` `*GFBFTR*`; `:38` RDCRC; `:67` IVEST; `:74` SQRT; `:80` ANGLER; `:87` ATAN; `:110,117` COS/SIN; `:125` GFFALS; `:148` `TEXT 'CK0'` |
| LICON | 363/13 | Compute line/conic (circle/ellipse) intersection points: reads 28-word `*GFGEL*` element block, handles multiple sign cases, writes up to four result points into the output buffer. | ABS, ANGLER, SQRT, IVEST, ATAN, COS, SIN, GFFALS | `LICON.mad:13-29` `*GFGEL*`/GAL/GAM offsets; `:56,60` ABS; `:66` ANGLER; `:77,184,213` SQRT; `:88,109,124,136,324` IVEST; `:191,220,392` ATAN; `:254-283,432-459` COS/SIN; `:463,467` GFFALS; `:258-266,437-458` stores to `*0422B..*0425B`; `:497` `TEXT 'CK0'` |
| IVEST | 37/2 | Small numeric selector using ABS and sign tests: returns one of two values (0/1-like) depending on magnitude, used by LICON/LITAN/LICON-style geometry. `[I]` exact math depends on the ABS call contract. | ABS | `IVEST.mad:13` SUBP ABS; `:23` call; `:24-37` `ASN,64-7`/`ARX` sign tests; `:39-54` two result branches; `:73-74` `INT,0`, `INT,1` |
| INTRSC | 64/0 | Compute the intersection of two straight lines by cross-product determinants and a final division; stores both coordinates, no external calls. | none (only trampoline) | `INTRSC.mad:15-36` line1/line2 direction vectors; `:59-75` determinants; `:75,95` `A/X`; `:76,96` stores to `*0104B`,`*0105B`; `:99-116` parameter-block copy loop |
| ITPLBV | 3553/125 | Table interpolation engine for INSIDE/INSDEK: checks table validity (interval counts, monotone X and Y, no duplicate abscissae), searches the interval and interpolates; prints detailed FORMAT diagnostics on error. | FT*571, FT*003, FT*002, ABS, I*DI*I, I*MU*I | `ITPLBV.mad:13` `*DRITP*`; `:14-19` SUBPs; `:193,278` I*DI*I; `:194,472,486,501` I*MU*I; `:3592-3634` ISO errors `"*** LX=1 OR LESS."`, `"*** LY=1 OR LESS."`, `"*** N = 0 OR LESS."`, `"*** IDENTICAL X VALUES."`, `"*** X VALUES OUT OF SEQUENCE."`, `"*** IDENTICAL Y VALUES."`, `"*** Y VALUES OUT OF SEQUENCE."`, `"36H ERROR DETECTED IN ROUTINE ITPLBV)"`; `:3612-3634` debug formats `IX =,I6 ... X(IX) =,E12.3`, `IY = ...`, `LX=...,LY=...,N=`; `:3667-3673` constants incl. `INT,17321` |
| ITPLBV note | - | At 3553 commands this is the largest module in the whole library (INDEX.md lists it spanning three zones). Its size is dominated by inlined validation/print code and the FORMAT call sequences, not by the interpolation core. | - | `ITPLBV.mad:2-11` header; `../extract/README.md:29` note about zones 0o1131/0o1132 |
| MINMAX | 43/3 | Two-entry dispatcher implementing element-wise max/min selection; calls the two primitive routines in MINMAX's own pair. | AMAX1, AMIN1 | `MINMAX.mad:13-14` SUBPs AMAX1/AMIN1; `:38` AMIN1; `:45` AMAX1; `:81-83` `LOG,4000000000000000`, `INT,1`, `INT,2` |
| LEVFUN | 52/1 | Evaluate a piecewise-linear "level function": finds the bracketing interval with MINMAX, then computes `y = slope*(x-x0)+y0` with integer-index arithmetic. | I*MU*I, MINMAX | `LEVFUN.mad:21` I*MU*I; `:34` MINMAX; `:42-60` interpolation formula; `:70-72` loop test; `:94` `INT,1` |
| LEVMAP | 50/1 | Map/interpolate values into a level map using two nested index loops and scaled differences; no external calls. | none | `LEVMAP.mad:15-33` outer loop; `:45-64` inner loop; `:58-64` accumulate and store; `:89` `INT,1` |
| LIMITS | 54/6 | Adjust and store drawing limits: reads the current limits from BSS, compares/swaps pairs with AMAX/AMIN arithmetic and writes them out through WDB/IWDB. | WDB, IWDB | `LIMITS.mad:13-14` SUBPs; `:17-53` limit pair comparisons; `:57,62,67,72` four `13,VJM,WDB`; `:77` `13,VJM,IWDB`; `:96-101` `INT,1,3,11,12,13,14` |
| MNMX | 461/4 | Determine min/max of X and Y data arrays, compute the X/Y scale ratio and pass the resulting viewport to LIMITS and MAP; includes two private index-advance routines. | LIMITS, MAP, I*MUI* | `MNMX.mad:13` `*GFVP*`; `:19-21` SUBPs; `:348,354,453,462` calls to `*0426B`,`*0433B` (index steps); `:375` MAP; `:524` LIMITS; `:531-534` scale `A/X` + store; `:536-551` private stride routines |
| KEYPO | 134/6 | Place markers and numeric labels at key points along a curve: evaluates X/Y through XPOL/YPOL, steps with private stride routines *0102B/*0106B, draws with TMF/MOVE/MARKER/NUMB. | XPOL, YPOL, TMF, MOVE, MARKER, NUMB, R*DI*I, I*MUI* | `KEYPO.mad:26,32,129,139` private strides; `:67,77` XPOL/YPOL; `:87` TMF; `:94` MOVE; `:98` MARKER; `:102` R*DI*I; `:123` NUMB; `:145-160` stride code |

## Group 3: contours, grid search, region containment and extremum labelling

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| LOOK | 411/11 | Grid-cell lookup engine for contouring: uses cell geometry `*GFCELL*` and flags `*GFINT*`/`*GFLOOK*`, applies MOD and integer strides to find cell entries, calls CELL/LINT/LINNUM and writes results with ZAPIT. | LINNUM, CELL, LINT, ZAPIT, MOD, I*MUI*, I*MU*I | `LOOK.mad:13-23` buffers; `:81,98,123,140,286,303,328,345` MOD; `:55,108,150,313,355` I*MU*I; `:165,370,413` ZAPIT; `:196,239` LINT; `:213` CELL; `:391,402` LINNUM; `:416-475` private stride routines; `:526` `LOG,4050000000000000` |
| ISOLIN | 601/14 | Isoline (contour) generator: marches through grid cells using LOOK for cell lookup, LINT/LINEO for segment geometry and XPOL/YPOL for coordinates, advances row/column indices with six private stride routines and updates the `*GFISOL*` counter. | LOOK, LINEO, XPOL, YPOL, IABS, I*MUI* | `ISOLIN.mad:13-23` `*GFCELL*`/`*GFISOL*`; `:41,48` IABS; `:113,122` XPOL/YPOL; `:179,195,206` LINEO; `:453,594` LOOK; `:456,597` `*0476B` secondary launcher; `:638-689` private strides; `:757` `LOG,2150456027640466`; `:780,782` 49- and 50-word row buffers |
| INSIDE | 414/10 | Point-in-region test/drawing for the `*DRIN*` (27-word) region descriptor: tests bit flags with `15,AEX`, interpolates region boundaries through ITPLBV, uses two 50-word coordinate buffers, and draws/labels accepted points. | ITPLBV, NUMBER, MOVE, TMF, ABS | `INSIDE.mad:13-32` `*DRINFN*`/`*DRIN*` layout; `:44-84` `15,AEX` flag tests; `:295` ITPLBV; `:191` NUMBER; `:160,282,371,395,434` MOVE; `:101,115` ABS; `:546,547` two `BSS,50` arrays; `:530-531` `LOG,3711463146314631`, `LOG,3751463146314631` |
| INSDEK | 370/7 | Near-duplicate of INSIDE for a 26-word `*DRIN*` layout (Cartesian/`DEK` variant `[I]`): same region flags, ITPLBV interpolation, 50-word buffers, MOVE/TMF/NUMBER drawing. | ITPLBV, NUMBER, MOVE, TMF, ABS | `INSDEK.mad:13-32` buffers (`*DRIN*` length 26); `:43-84` `15,AEX` tests; `:246` ITPLBV; `:346` NUMBER; `:138,323,353,381,426` MOVE; `:104,108` ABS; `:506,507` two `BSS,50`; `:492-493` tolerance LOG constants |
| LINNUM | 420/17 | Label isolines with their numeric values: follows the broken contour from BRLINE, computes segment directions with ATAN2/SQRT and places NUMBER texts at safe positions using spacing constants. | NUMBER, COS, SIN, BRLINE, ABS, ATAN2, SQRT, TMF, FLOAT, R*DI*I | `LINNUM.mad:13-20` `*GFLSZ*`,`*GFLOOK*`,`*GFLMN*`,`*GFISOL*`; `:65` FLOAT; `:136,385` SQRT; `:243,255,403` ATAN2; `:332,524` BRLINE; `:407,416,442,452` SIN/COS; `:411,420,446,456` R*DI*I; `:471` NUMBER; `:553-562` `INT,180`, `333`, `666`, `999`, `TEXT 'AH'` |
| LOCEXT | 265/15 | Find and mark local extrema of a tabulated function read through XPOL/YPOL: tests sign products of neighbouring differences, moves the pen to the extremum, draws a marker and prints the value with NUMBER. | XPOL, YPOL, TMF, MOVE, MARKER, R*DI*I, NUMBER, I*MUI* | `LOCEXT.mad:13` `*GFLMN*`; `:89-130` sign tests of products; `:179,189` XPOL/YPOL; `:199` TMF; `:206` MOVE; `:209` MARKER; `:232` R*DI*I; `:247` NUMBER; `:277-310` private strides; `:376-377` `LOG,3751463146314631`, `INT,999` sentinel |

## Group 4: transformations, 3D projection and the MOVE/plot family

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| INIT | 17/1 | Initialise the GRAFOR matrix area `*GFMATR*` and expose the `HCUNIT` subprogram; sets GAK/2..4 offsets relative to the matrix buffer. | HCUNIT (own SUBP) | `INIT.mad:13-16` `*GFMATR*`/GAK offsets; `:17` `HCUNIT:,SUBP,`; `:30` `13,VJM,HCUNIT`; `:32-44` launcher/epilogue |
| ISOMET | 26/5 | Set up an isometric 3D projection by applying two successive TDROT rotations with fixed angle constants; uses a 2-word scratch area. | TDROT | `ISOMET.mad:13-16` `*GFMATR*`; `:17` `TDROT:,SUBP,`; `:35,40` two `13,VJM,TDROT`; `:60-64` `INT,1/2/3` and `LOG,4310600000000000`, `LOG,4313200000000000`; `:65` `BSS,2` |
| MOVA | 33/1 | "Move along arc": reads arc centre from `*GFBFTR*`, steps an angle (LOG step) and calls COS/SIN plus MOVE to trace the arc. | MOVE, SIN, COS | `MOVA.mad:13-14` `*GFBFTR*`; `:32,39` COS/SIN; `:51` MOVE; `:69` `LOG,3550737215211226` (angle step) |
| MOVE1 | 275/10 (data 20+set 20) | General polyline plotter with affine transform `*GFATRN*` and blanking/pen state `*GFBLAN*`: reads data with RDB, rescales with AMAX1/AMIN1/INT, draws with PLOT and handles blanking with BLANCA; initialises common buffers in its DATA/SET section. | BLANCA, INT, PLOT, AMAX1, RDB, AMIN1 | `MOVE1.mad:13-34` buffers; `:133,151,184` RDB; `:140,147,158,165` AMAX1/AMIN1; `:194,198` INT; `:206` PLOT; `:319` BLANCA; `:401-450` `,DATA,` and `1,SET,` assignments into `*GFBLAN*`/`*GFATRN*` |
| MOVE2 | 324/11 (data 12+set 12) | Polyline plotter variant adding notch/gap handling via the 51-word `*GFNTCH*` and 20-word `*GFGOBS*` buffers; uses integer divide/multiply for notch spacing. | INT, PLOT, RDB, AMIN1, AMAX1, NOTCH1, I*DI*I, I*MU*I | `MOVE2.mad:13-44` buffers; `:153,158,172,177,183` I*DI*I/I*MU*I; `:203,364` NOTCH1; `:397,401` INT; `:409` PLOT; `:467-485` `1,SET,` initialising `*GFATRN*`, `*GFGOBS*` |
| MOVE3 | 540/11 (data+set 22) | Combined MOVE1/MOVE2 plotter: manages both blanking state and notch/gap tables, calls BLANCA and NOTCH1, initialises all four common buffers. | BLANCA, NOTCH1, INT, PLOT, RDB, AMIN1, AMAX1, I*DI*I, I*MU*I | `MOVE3.mad:13-45` buffers; `:312,418,431,651` NOTCH1; `:480` BLANCA; `:517,521` INT; `:529` PLOT; `:252,271,381,563,680` RDB; `:733-770` DATA/SET assignments into `*GFBLAN*`, `*GFATRN*`, `*GFGOBS*` |

The three MOVE modules share the same data path but initialise different subsets of the common buffers: MOVE1 initializes `*GFBLAN*` and `*GFATRN*` (`MOVE1.mad:418-450`), MOVE2 only `*GFATRN*` plus notch/gap words (`MOVE2.mad:467-485`), MOVE3 all of `*GFBLAN*`, `*GFATRN*`, `*GFGOBS*` (`MOVE3.mad:733-770`). They also contain a second entry path (a second `14,VTM,...` prologue, e.g. `MOVE1.mad:43-44`) selecting a different scaling mode.

## Group 5: buffer / disk-exchange and reference-only entries

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| MDBUFF | no body (secondary catalog entry) | Low-level GRAFOR-SUD directory name for a disk/buffer manager; appears only as an entry name in the sparse secondary catalog in zone 0o1163 (dec 627) and as a referenced name in zones 0o1161/0o1162. `[I]` no disassembled body, no buffer or disk routine can be attributed from code. | unknown / not recoverable | `../disasm/INDEX.md:72` (0o1163 sparse catalog lists `MDBUFF, PLOT, ONOFF, PEN, FRAME, ...`), `:103-107` ("нижний уровень графора" routines); `../disasm/INDEX.md:70-71` zones 0o1161/0o1162 reference MDBUFF; absent from `../madlen/INDEX.md` module table and from `../extract/catalog.txt` |
| MOVBL1 | no body (catalog REF, info word `0000000000000001`) | Entry point for a block-move primitive (name suggests "move block" variant 1); no code on this volume, so register conventions and destination/source buffers are unknown. `[I]` | unknown / not recoverable | `../extract/catalog.txt:200` `193 MOVBL1 0000000000000001 ... REF -> 1`; `../madlen/INDEX.md:268` skipped reference/entry-only records; `../madlen/AUDIT/IO-MODULES.md:207-208` lists MOVBL1 among the 17 bodyless references |
| MOVBL3 | no body (catalog REF, info word `0000000000000001`) | Entry point for block-move variant 3; referenced from the data region of zone 0o1121 (dec 593) together with BLANCH/MOVE1/MOVE2. `[I]` no code available. | unknown / not recoverable | `../extract/catalog.txt:198` `191 MOVBL3 0000000000000001 ... REF -> 1`; `../disasm/INDEX.md:65` zone 0o1121 TABLES/DATA lists `BLANCH, MOVBL1, MOVE2, ... MOVE1`; `../madlen/AUDIT/IO-MODULES.md:207-208` |

Buffer/disk-exchange note: within the 38 real modules in this range, **none** issues an Э50/Э70/Э74 extop (`*50`, `*70`, `*74`) and none calls the disk primitives GDISC/SETK/GIVZON/E70. Disk exchange is confined to the low-level library part outside this range; the modules here exchange data exclusively through the `*GF...*` common buffers and via RDB/IRDB (real/integer data-buffer reads) and WDB/IWDB (LIMITS) and ZAPIT (LOOK). MDBUFF belongs to that low-level part but has no body on the volume.

## Alphabetical master table (all 41 modules)

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| INCLIN | 321/12 | Draw inclined/hatched lines with clipping and optional markers | IRDB, RDB, WHERE, R*ST*I, TMF, AMAX1, AMIN1, MOVE, MARKER | `INCLIN.mad:114,153,282,313` |
| INIT | 17/1 | Initialise `*GFMATR*` matrix buffer, HCUNIT entry | HCUNIT | `INIT.mad:13-17,30` |
| INSDEK | 370/7 | Point-in-region test/draw (`*DRIN*`, 26 words, Cartesian variant `[I]`) with ITPLBV interpolation | ITPLBV, NUMBER, MOVE, TMF, ABS | `INSDEK.mad:16,246,346,506-507` |
| INSIDE | 414/10 | Point-in-region test/draw (`*DRIN*`, 27 words) with ITPLBV interpolation | ITPLBV, NUMBER, MOVE, TMF, ABS | `INSIDE.mad:16,295,191,546-547` |
| INTRSC | 64/0 | Line-line intersection by determinants | none | `INTRSC.mad:28-35,75-96` |
| ISOLIN | 601/14 | Isoline/contour tracing over grid cells | LOOK, LINEO, XPOL, YPOL, IABS, I*MUI* | `ISOLIN.mad:179,453,638-689` |
| ISOMET | 26/5 | Isometric 3D projection via two TDROT rotations | TDROT | `ISOMET.mad:35,40,60-64` |
| ITPLBV | 3553/125 | Table interpolation with validation and FORMAT error messages | FT*571, FT*003, FT*002, ABS, I*DI*I, I*MU*I | `ITPLBV.mad:3592-3634,3673` |
| IVEST | 37/2 | ABS/sign-based selector used by geometry routines | ABS | `IVEST.mad:23-54` |
| KEYPO | 134/6 | Mark and number key points on a curve | XPOL, YPOL, TMF, MOVE, MARKER, NUMB, R*DI*I | `KEYPO.mad:67,94,98,123` |
| LESQ | 263/4 | Least-squares normal equations + symmetric matrix inversion | SMINV, IABS, I*MU*I | `LESQ.mad:177,347-365` |
| LEVFUN | 52/1 | Piecewise-linear level-function evaluation | I*MU*I, MINMAX | `LEVFUN.mad:21,34,42-60` |
| LEVMAP | 50/1 | Nested-loop level map interpolation | none | `LEVMAP.mad:15-64` |
| LGLINE | 233/5 | Logarithmic-scale line plotter | IRDB, IABS, WHERE, TMLGF, MOVE, MARKER | `LGLINE.mad:54,101,194,222` |
| LICON | 363/13 | Line/conic intersection from `*GFGEL*` element data | ABS, ANGLER, SQRT, IVEST, ATAN, COS, SIN, GFFALS | `LICON.mad:56,77,191,258-266,497` |
| LIMITS | 54/6 | Set/store drawing limits through WDB/IWDB | WDB, IWDB | `LIMITS.mad:57-77` |
| LINEC | 127/11 | Clipped straight-line plotter | IRDB, RDB, IABS, TMF, AMAX1, AMIN1, MOVE | `LINEC.mad:22-60,97,139` |
| LINEMC | 156/11 | Line plotter with point markers | IRDB, RDB, TMF, AMAX1, AMIN1, MOVE, MARKER | `LINEMC.mad:109,163,179` |
| LINEMO | 232/11 | Line plotter with visibility test and markers | IRDB, RDB, WHERE, TMF, MOVE, MARKER | `LINEMO.mad:98,109,251,267` |
| LINEO | 203/11 | Clipped line plotter with WHERE test | IRDB, RDB, WHERE, ABS, TMF, MOVE | `LINEO.mad:76,96-143,183` |
| LINFIL | 115/3 | Arithmetic fill between arrays | none | `LINFIL.mad:73-133` |
| LININT | 264/1 | Arithmetic linear interpolation over arrays | none | `LININT.mad:48-70,174-232` |
| LINNUM | 420/17 | Label isolines with numeric values | NUMBER, BRLINE, ATAN2, SQRT, SIN, COS, R*DI*I, FLOAT, TMF | `LINNUM.mad:136,332,407,471` |
| LINT | 101/2 | Line/cell intersection into `*GFINT*` | XPOL, YPOL | `LINT.mad:27,108,117` |
| LITAN | 101/6 | Tangent line to circle from `*GFBFTR*` | RDCRC, ABS, IVEST, SQRT, ANGLER, ATAN, COS, SIN, GFFALS | `LITAN.mad:38,67,80,110` |
| LOCEXT | 265/15 | Find/mark local extrema of a tabulated function | XPOL, YPOL, TMF, MOVE, MARKER, NUMBER, R*DI*I | `LOCEXT.mad:89-130,179,206,247` |
| LOOK | 411/11 | Grid-cell lookup for contouring | LINNUM, CELL, LINT, ZAPIT, MOD, I*MUI*, I*MU*I | `LOOK.mad:81,165,196,213,391,416-475` |
| LSCALE | 110/4 | Rotation-based coordinate scaling (forward/inverse) | ATAN2, ROTATE, ATRAN2 | `LSCALE.mad:53,64,78,106,116,137` |
| LSFIT | 314/31 | Least-squares polynomial fit with diagnostics and plotting | IRDB, IABS, ALOG10, MINMAX, LESQ, PVAL, FT*571/002/003, MOVE | `LSFIT.mad:67,171-182,209,238,399-416` |
| MDBUFF | no body | Secondary-catalog low-level GRAFOR buffer/disk name `[I]` | unknown | `disasm/INDEX.md:72,103-107` |
| MINMAX | 43/3 | Element-wise max/min dispatcher | AMAX1, AMIN1 | `MINMAX.mad:38,45` |
| MOVA | 33/1 | Move pen along circular arc | MOVE, SIN, COS | `MOVA.mad:32,39,51,69` |
| MOVBL1 | no body (REF 1) | Block-move variant 1 entry `[I]` | unknown | `catalog.txt:200` |
| MOVBL3 | no body (REF 1) | Block-move variant 3 entry `[I]` | unknown | `catalog.txt:198` |
| MOVE1 | 275/10 | Polyline plotter with affine transform and blanking | BLANCA, INT, PLOT, RDB, AMAX1, AMIN1 | `MOVE1.mad:133,194,206,319,401-450` |
| MOVE2 | 324/11 | Polyline plotter with notches/gaps | NOTCH1, INT, PLOT, RDB, I*DI*I, I*MU*I | `MOVE2.mad:153,203,397,409,467-485` |
| MOVE3 | 540/11 | Combined blanking + notch polyline plotter | BLANCA, NOTCH1, INT, PLOT, RDB, I*DI*I | `MOVE3.mad:312,418,480,517,529,733-770` |
| MNMX | 461/4 | Min/max scan and viewport scaling via LIMITS/MAP | LIMITS, MAP, I*MUI* | `MNMX.mad:375,524,531-534,536-551` |

## Remote cross-references worth noting

- The isoline stack is LOOK (cell search) -> LINT / CELL -> LINNUM (labelling) and ISOLIN (marching driver) -> LOOK + LINEO + LINT, with LITAN, LICON, INTRSC, LININT and LINFIL as geometry/math helpers used from the same family.
- INSIDE/INSDEK call ITPLBV for boundary interpolation; KEYPO and LOCEXT use XPOL/YPOL to evaluate curves; MNMX and MINMAX provide scaling/minmax primitives to that stack.
- INIT/ISOMET/MOVA operate on the `*GFMATR*`/`*GFBFTR*` common areas; the MOVE1/2/3 data-and-set records are the place where the affine-transform and blanking buffers receive their defaults, so any change to those defaults must be checked in all three modules.
