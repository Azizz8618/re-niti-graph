# Library 22 (ГРАФОР-СУД) module functions: names C..D

**Coverage: 25 of 25 modules** in the assigned range
(CABIN CELL CHENSP CIRC CIRCLE CIRTAC CIRTAL CLEAZN CMGRID COMPDT CONDEK
COORD COPDCB CORNL CROSS CUBPOL DASHP DDIST DERIV5 DIMDRO DIMET DIST DRACON
DRALIM DRFRAM).

**Source:** dtran MADLEN disassembly of BESM-6 system library 22 (ГРАФОР-СУД),
disk volume 2048, catalog zone 0o1100; `.mad` files under `../madlen/`.
Line numbers below refer to the corresponding `<NAME>.mad` file.
Sizes in the table are `Commands/Constants` from the dtran header
(`C Commands:` / `C Constants:`), which differ from the stale catalog `load` field.
`[I]` marks an inference that is not proven by the listing alone.

## Alphabetical master table

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| CABIN | 31/4 | Sets up a "cabinet" (oblique) 3-D projection in the GRAFOR matrix | SHEAR (x2) | lines 16, 32-45; *GFMATR*, GAK/2, GAK/3, INT 1,2,3 |
| CELL | 223/7 | Updates/clips a 9-word GRAFOR "cell" rectangle record | MOD, I*MUI* | lines 13-21, 24-117, 184-220; 4 mode branches at 29-33 |
| CHENSP | 204/6 | Generates a cosine-spaced point/number sequence (Chebyshev-like spacing [I]) | COS, R*DI*I | lines 13-14, 38-39, 64-66, 184-186; INT 1,2; LOG 4114441766517106 |
| CIRC | 32/3 | Small circle/arc segment emitter using the GRAFOR buffer | ARCIA, MOVE | lines 15-16, 35, 43, 50; *GFBFTR*, GAK/2, TEXT 8HDK0 |
| CIRCLE | 165/10 | Draws a circle/ellipse parametrically by stepping an angle | SIN, COS, ABS, RDB, MOVE, R*ST*I | lines 13-18, 41-49, 82-115, 142-159, 173-184; 2 angle constants at 239-243 |
| CIRTAC | 264/7 | Generates circle/arc point coordinates into the GFGEL element | STRMOD, ABS, R*ST*I, IVEST, SQRT, ANGLER, ATAN, SIN, COS, SIGN, GFFALS | lines 13-32, 92-102, 186-335; GAM/4=*GFGEL*+27 |
| CIRTAL | 203/6 | Variant of CIRTAC with an extra GFGEL field (GAM/3) in the coordinate formulas | same call set as CIRTAC | lines 13-32, 99-103, 127-131, 279-281; GAM/1=+2, GAM/2=+3 vs CIRTAC +1/+2 |
| CLEAZN | 6/0 | Low-level "clear zone": fills a disk/zone command buffer with octal 76001 and writes it out [I] | (none named; STX) | lines 13-23; `12,VTM,76001B`, `*0003B:14,ATX,`, `14,VLM,*0003B`, `,STX,` |
| CMGRID | 670/5 | Draws a scaled coordinate grid (Cartesian + polar) with numeric tick labels | MOVE, NUMBER, SIN, COS, ATAN2, FLOAT, MOD, TMF, XPOL, YPOL, IABS | lines 13-23, 94-114, 217-237, 281-348, 609-740; loops at 436, 821 |
| COMPDT | 14/2 | Compares a two-word packed data field (likely catalog name/key [I]) | (none) | lines 13-14, 15-37; `DATA* :,LC,2`, ASN shifts 8/11/15, masks 740000000000 / 60740000207400 |
| CONDEK | 514/12 | Builds a DEK contour record: finds boundary crossings by root finding and inserts points | INSDEK, FNROOT (x3), MOD, TFM, WHERE, R*ST*I, R*DI*I, I*DI*I | lines 13-45, 54, 242, 268, 298, 399, 481, 564, 638; DATA 713-722 |
| COORD | 52/3 | Maps a data coordinate to a logarithmic plotting coordinate | RDB (x2), AMIN1, ALOG10 (x2) | lines 13-15, 29-39, 63-76; INT 11,13, LOG 4000000000000000 |
| COPDCB | 14/1 | Low-level copy of a disk/device control block between two areas [I] | (none named; VLM loop) | lines 13-35; `,STI,10`/`,ATI,9`, copies at +0/+1/+3/+4, mask `7777177777777777` |
| CORNL | 1250/15 | Draws/clips corners and line contours via viewport and boundary records | PATCH, MOVE, TMF, MAP, RDB, I*MUI*, R*ST*I | lines 13-47, 59, 221-344, 1066-1101; *GFVP*, *GFKJ*, *GFXY*, *GFL*, *GFB* |
| CROSS | 1330/14 | Computes intersection points ("crossings") of graphic elements | GFFALS, ATAN, ANGLER, SIN, COS, ABS, SQRT, IVEST, R*ST*I, R*DI*I | lines 13-43, 414-447, 499-532, 753-837; results in GAM/1,GAM/2 and *1410B..1412B |
| CUBPOL | 121/4 | Evaluates/builds a cubic polynomial by Horner-type arithmetic | (pure arithmetic) | lines 15-155; 7 WTC cells *0134B..*0142B, INT 1,2,3,6 |
| DASHP | 177/11 | Draws dashed (broken) lines between two points | MOVA, MOVE, ANGLER, SQRT, RDB | lines 13-19, 28-63, 92-156, 199-242; *GFBFTR*, GAK/2, INT 17 |
| DDIST | 16/0 | Installs two GFGEL scratch pointers used by DIST [I] | (indirect calls through GAK/2, GAK/3) | lines 13-15, 18-25, 27-41; GAK/2=*GFGEL*+18, GAK/3=+19 |
| DERIV5 | 226/17 | Five-point finite-difference derivative (orders 1..4 [I]) | (pure arithmetic) | lines 15-149, 150-280; coefficient table INT 1,2,3,4,6,8,9,11,12,18,21,22,24,36 |
| DIMDRO | 613/20 | Draws dimension lines with extension lines, arrowheads and text | ARROW, MOVA, MOVE, RDACA, RDACB, WRACA, ARCIA, RDSTR, WRSTR, RDMVA, WRMVA, SIGN, ABS, IABS, GFFALS | lines 13-37, 47-79, 111-379, 747-752; TEXT 8HCK0, GFFALS 6,10 |
| DIMET | 26/4 | Sets up a dimetric 3-D projection matrix | TDROT (x2) | lines 16, 34, 39; *GFMATR*, GAK/2=+32, GAK/3=+33, INT 1,2,3, TEXT 8HBJ |
| DIST | 634/11 | Computes distances between graphic elements (point/line/circle/arc) | AREB1, SIN, COS, ANGLER, IVEST, SQRT, SECANT, ABS, STRMOD, R*ST*I, R*DI*I | lines 13-37, 95-109, 284-291, 300-430; INT 6283, INT 1000, TEXT 8HE/H, 8HCK0 |
| DRACON | 650/15 | Draws contour lines by root finding and inside/outside tests | INSIDE, SQRT, TMF, FNROOT (x3), MOD, WHERE, R*ST*I, I*DI*I | lines 13-46, 62, 160, 186, 221, 323-358; DATA 916-925 |
| DRALIM | 152/3 | Computes/updates DR drawing limits (bounds) in a 4-word record [I] | (WTC-based indirect calls) | lines 13-16, 19-44, 97-140, 175-188; *DRLM*, GAK/2..4, INT 0,1 |
| DRFRAM | 136/6 | Draws a rectangular frame/title block around a drawing | MOVE, TMF | lines 13-14, 22-35, 51-66, 137-166; DATA/SET 214-225, BSS 37 |

## Low-level disk and catalog I/O

### CLEAZN (6 commands)
The smallest module in the range. It prepares and writes a zone/erase command
buffer. The incoming argument is loaded into index 9 (`,ATI,9`, line 14) and a
modifier is set (`,9,WTC,6`, line 15); index 14 is zeroed and index 12 is loaded
with octal `76001B` (lines 16-17). The loop at lines 18-21
(`,XTA,` / `*0003B:14,ATX,` / `14,UTM,1` / `12,VLM,*0003B`) stores successive
words, and `,STX,` (line 22) writes the prepared block out. `,13,UJ,` returns.
No explicit `E70`/`*70` call appears in the body; the `76001B` constant is in
the same family as the disk command masks `770000` / `6200000000000000` seen in
GDISC and RZON, so CLEAZN is most likely the "clear zone" helper that fills a
disk command area before it is handed to the э70 disk-exchange path [I].

### COMPDT (14 commands, 2 constants)
Declares a two-word data field `DATA* :,LC,2` with `GAK/2 = DATA*+1` (lines 13-14),
i.e. a 2-word packed value (typical for a 12-character name/key). It shifts its
argument right by 8 bits (`,ASN,64-8`, line 19), branches on zero (line 20), then
compares/accumulates the two words using `APX` (lines 22, 24), left shift 11
(`,ASN,64+11`, line 25), `AOX` (line 26) and right shift 15 (line 27) before
storing a result through index 9 (line 29). The alternate branch at lines 31-36
copies `DATA*` and `GAK/2` into words 10 and 10+1. Constants:
`LOG 740000000000` and `LOG 60740000207400` (lines 38-39). Function:
compare a supplied packed key against a stored two-word catalog-style record
[I]. It sits in zone 625 next to the catalog/zone routines.

### COPDCB (14 commands, 1 constant)
"Copy DCB": copies a control block from the area addressed by index 9 to the
area addressed by index 10. Lines 13-20 set `,STI,10` / `,ATI,9` and copy words
at offsets 0, 1 and 3 (`9,XTA,` / `10,ATX,`, then `,1` and `,3` forms). A five-word
block is copied by `14,VTM,-5` ... `14,ATX,14B` ... `14,VLM,*0005B` (lines 21-25),
extra fields at `14B` and `15B` are copied at lines 30-33, and the last word uses
a masked copy: `9,XTA,4` / `10,UTC,*0014B` / `,AAX,` / `10,ATX,4` (lines 26-29),
where `*0014B:,LOG,7777177777777777` clears selected bit fields. The module
returns with `13,UJ,` (line 36). Located in zone 626 together with SETIND,
SETREF, WCATWO and GIVENZ, so it is part of the disk/catalog setup layer [I].

## Curves, arcs and intersections

### CIRC, CIRCLE, CIRTAC, CIRTAL
- **CIRC** is a thin driver over `ARCIA` and `MOVE`: it reads the GRAFOR buffer
  `*GFBFTR*` and its second word `GAK/2` (lines 19-24), forms an address with
  `WTC,*0040B` + `A+X` (lines 26-28) and issues `MOVE`, `ARCIA`, `MOVE`
  (lines 35, 43, 50) with three parameter triples built from BSS cells
  `*0032B..*0037B`. Constants `LOG 0`, `INT 0`, `TEXT 8HDK0` (lines 66-68).
- **CIRCLE** is a full parametric circle/ellipse plotter. It reads two values
  with `RDB` (lines 42-49), forms a scale `(x1-x0)*(y1-y0)` (lines 50-53), takes
  absolute values with `ABS`, reads step/angle parameters at offsets 17, 1, 5,
  6, 7 (lines 64-81), then loops (lines 142-193) computing
  `x = cx + r*cos(t)`, `y = cy + r*sin(t)` and emitting each point with `MOVE`
  (lines 184, 214). Two different angle constant sets are used at
  `*0207B` and `*0210B` (lines 240-243).
- **CIRTAC** and **CIRTAL** generate the same coordinates into the 28-word
  `*GFGEL*` element. Both compute a distance as `SQRT(dx^2+dy^2)` (CIRTAC lines
  92-102; CIRTAL lines 132-142), derive an angle with `IVEST`/`ANGLER` and
  `ATAN` (CIRTAC 103-119, 305-335; CIRTAL 143-155, 191-235), and write
  `center + r*cos/sin` back through the WTC fields (CIRTAC 322-335;
  CIRTAL 221-234). Both use `GAM/4 = *GFGEL*+27` and
  `LOG 2312571435610604`; CIRTAL additionally uses `GAM/3 = *GFGEL*+4`
  (lines 31, 99-103, 127-131, 279-281), so it is a layout variant [I].
  `GFFALS` is called with codes 5, 6 or 7 on degenerate cases
  (CIRTAC 337-352; CIRTAL 243-259).

### DASHP (177 commands)
Draws broken/dashed segments. It reads the two endpoints with `RDB`
(lines 28-35), computes `dx^2+dy^2` and `SQRT` for the total length (lines 47-57),
and a direction with `ANGLER` (lines 58-63). The loop at `*0046B` (lines 92-156)
alternates `MOVE` (pen down) and `MOVA` (pen up/advance) runs whose lengths come
from parameters 3, 4, 5, 6 and 7; a second, mirrored loop handles the other
direction (lines 164-242). Endpoints at `WTC,*0177B` (line 259) and the numeric
constants at lines 262-267 supply dash/gap scale factors.

### CROSS (1330 commands)
The largest geometry module. It reads a 28-word `*GFGEL*` record with 18 named
field offsets (lines 13-42) and calls `IVEST` repeatedly to enumerate candidate
intersections (lines 84, 409, 494, 763, 1219). For line/circle cases it solves a
quadratic: e.g. lines 414-447 form the discriminant, take `SQRT`, and produce two
solutions in `GAM/1`, `GAM/2` / `GAN/1`, `GAN/2`; lines 499-532 do the same for
the other axis. Cases are dispatched by tests on `GAL/2`, `GAL/3`, `GAL/4`,
`GAL/5` (lines 52-65, 380-386, 465-471). The two resulting coordinates are
stored in `GAM/1`, `GAM/2` and copied to `*1410B`, `*1411B`, with a case index in
`*1412B` (lines 1161-1168, 1122-1144). Invalid geometry reports code 5, 6 or 7
through `GFFALS` (lines 1408-1419). Entry saves 3 registers (lines 1420-1436).

### CORNL (1250 commands)
Operates on five GRAFOR common areas: `*GFVP*` (viewport, 6 words),
`*GFKJ*` (2), `*GFXY*` (current point, 5), `*GFL*` (line, 8) and `*GFB*`
(boundary, 7) (lines 13-40). It reads coordinate data with `RDB` (line 59),
dispatches on mode fields into four corner cases (lines 158-220), transforms
points with `MAP`/`TMF` (lines 240-275), and emits the resulting contour with
`PATCH` (lines 343, 481, 1101) and `MOVE` (lines 321, 411). Five small internal
helpers at `*1126B`..`*1171B` (lines 1126-1216) perform integer-multiply scaling
by the `*1331B` factor; `I*MUI*` is used for this throughout. Entry saves 21
words (lines 1217-1247), the largest save area in the range. Function: build and
clip corner/contour linework to the drawing viewport [I].

## Dimensioning, distances and coordinate transforms

### DIMDRO (613 commands)
The dimensioning driver. It reads a value with `RDB` (lines 48-53), writes a
text string with `WRSTR` (line 59) and reads one back with `RDSTR` (lines 750-752),
and reads/writes arcs/circles with `RDACA`, `RDACB`, `WRACA`, `ARCIA`
(lines 390-403, 728-738). Dimension lines and arrowheads are produced by
`MOVA`/`MOVE` and `ARROW` (lines 144-151, 227-234, 299-302, 346-349, 370-378).
`SIGN` (lines 165-170, 185-191) and `ABS`/`IABS` choose the side/direction of the
dimension. Text marker `TEXT 8HCK0` (line 786) and error codes 6, 10 via
`GFFALS` (lines 747-749, 775-776). Deliberately uses the `WRMVA`/`RDMVA`
word-vector string I/O rather than the plotting primitives alone.

### DIST (634 commands) and DDIST (16 commands)
DIST computes the distance between two graphic elements stored in `*GFGEL*`.
It reads buffer words (lines 40-45), uses `SECANT` (lines 86-94), `SQRT` on sums
of squares (lines 95-109, 284-291), and `IVEST` to restrict computations to a
valid interval (lines 151, 192, 231). Multiple shape cases are separated by
tests on `GAL/5` and the `GAM/*` fields (lines 46-51, 72-81, 377-386); angles and
projections use `ANGLER`, `SIN`, `COS`, `R*DI*I` (lines 319-336, 399-426, 776-792).
Constants: `INT 6283` and `INT 1000` (line 815, 817), consistent with angles in
milliradians (6283 ≈ 2π·1000); `TEXT 8HE/H` (line 816) and `TEXT 8HCK0`
(line 820).
DDIST is the small companion that installs two GFGEL scratch pointers:
`GAK/2 = *GFGEL*+18` and `GAK/3 = *GFGEL*+19` (lines 13-15), stores their
addresses into BSS cells `*0016B`/`*0017B` (lines 18-25), then calls through them
via `MTJ`/`UJ` (lines 27-41) with two integer mode arguments.

### CABIN (31 commands) and DIMET (26 commands)
These two short modules initialize the 34-word GRAFOR transformation matrix
`*GFMATR*` (fields GAK/2 = +32, GAK/3 = +33). CABIN calls `SHEAR` twice
(lines 38, 45) with parameter triples built from INT 1,2,3 and a BSS cell;
DIMET calls `TDROT` twice (lines 34, 39) with triples 14/13B/32B/31B and
similar. Both switch to fixed-point mode (`NTR,3`, `NTR,22B`), use a `LOG`
scale constant (CABIN line 69: `4050000000000000`; DIMET uses `TEXT 8HBJ`
line 62), and restore GAK/2 on exit. By name and structure they are the
"cabinet" (oblique) and "dimetric" members of the GRAFOR 3-D projection family
alongside ISOMET, AXONOM and SHEAR [I].

### COORD (52 commands)
Reads two reference values with `RDB` (lines 29, 39), takes their minimum with
`AMIN1` (line 48) and their base-10 logarithms with `ALOG10` (lines 65, 69).
The final mapping at lines 71-76 is
`result = (x - min) * log_denominator / log_numerator + min`, i.e. logarithmic
axis interpolation; a linear shortcut is taken when the OR/shift tests at
lines 49-53 succeed. Constants `LOG 4000000000000000`, `INT 11`, `INT 13`
(lines 95-97).

### DRFRAM (136 commands) and DRALIM (152 commands)
DRFRAM draws a frame/title block. It reads two parameters with WTC-based loads
(lines 17-29), calls `TMF` four times with different argument tables
(lines 51-66 and 137-152), draws connecting lines with `MOVE` (lines 81, 128,
145, 152), and loops with a step of 2 until a limit (lines 158-166). The trailing
`DATA`/`SET` block (lines 214-225) initializes two 4-word tables at `*0144B`
and `*0150B`; entry saves 6 registers.
DRALIM maintains a four-word limits record `*DRLM*` (lines 13-16). It initializes
four fields from the input parameters (lines 28-44, 60-96), then repeatedly
compares candidate values with the stored bounds using `ASN,64-7` / `ARX` and
replaces the bound when the sign tests at lines 100-140 fail. Lines 175-188 form
a difference/ratio from two bounds and store it into `GAK/3`/`GAK/4`. Calls are
made indirectly through WTC-modified addresses (lines 27, 40, 79, 95); entry
saves 7 registers (lines 190-205). Its interpretation as a "drawing limits"
calculator follows from the name and the `*DRLM*` record [I].

## Grids and cells

### CMGRID (670 commands)
Draws a graduated coordinate grid with labels. It reads the counts and scale
parameters at entry (lines 26-51), converts data points to plot coordinates with
`XPOL`/`YPOL` (lines 94-105, 193-216, 384-407, 585-608), decides which ticks get
a label with `MOD` (lines 119-130, 517-536, 663-672), computes polar tick
endpoints with `ATAN2`, `COS`, `SIN` (lines 226-260, 624-652), writes labels with
`NUMBER` (lines 304, 348, 696, 740) and draws the grid lines with `MOVE`
(lines 349-355, 741-747, 813-815, 823). `TMF` sets the text mode before drawing.
The four-way structure (two axis families x two label positions) and the
`*GFGEL*`-style BSS pool make this the "cm" (graduated) grid routine [I].

### CELL (223 commands)
Maintains the 9-word cell record `*GFCELL*` (lines 13-21). A mode word selects
one of four entry branches (lines 29-33 → 34, 55, 76, 97); each branch applies
`+` or `-` adjustments to the fields GAK/2..GAK/7 and GAL/0..GAL/1, using small
internal helpers at `*0154B`, `*0161B`, `*0165B`, `*0172B` (lines 222-253).
It multiplies two extents (lines 131-137), tests their product (lines 138-143),
and either writes the updated rectangle back to `*GFCELL*` (lines 145-165) or
takes a wrapped/rotated path using `MOD` (lines 184-195, 210-220). `I*MUI*`
supplies integer multiplication; `LOG 2150456027640466` is a field constant.
The routine therefore computes the intersection/clipping of a rectangular cell
against the drawing field [I].

## Numerical methods

### CUBPOL (121 commands)
A self-contained polynomial evaluator working on seven pointer cells
`*0134B..*0142B` and four input scalars (parameters 1, 2, 3, 6; lines 175-178).
The body (lines 15-155) is a chain of `A*X`, `A/X`, `X-A` operations that forms
the cubic coefficients, and writes results into output parameters 1, 2, 3
(lines 122, 144, 155). Given its neighbours in zone 595 (APPOLY, SPLINT,
TRIDIG, LESQ), CUBPOL is a cubic-polynomial interpolation/evaluation kernel [I].

### DERIV5 (226 commands)
Computes finite differences from five tabular values. The decision tree at
lines 15-149 branches on two integer arguments (1 and 3) and selects one of
several stencils; lines 150-275 assemble the weighted sum with multipliers
`0, -1, -2, -3, -4` applied through `1,A*X,-N` sequences; lines 276-280 divide
by the normalizing coefficient in `*0250B` and store the derivative. The
coefficient table at lines 303-316 is
`1, 2, 3, 4, 6, 8, 9, 11, 12, 18, 21, 22, 24, 36`, the standard denominators
of 5-point derivative formulas (orders 1..4) [I]. Entry saves 4 registers.

### CHENSP (204 commands)
Generates a sequence of values using `COS` and integer rounding `R*DI*I`
(lines 38-40, 64-67, 184-187). Two loops (counters at param 7, lines 142-143,
and at param 26, lines 237-238) accumulate weighted sums with `A*X` and
`ATX,-1` updates into a pointer-defined output area (`WTC,*0216B`,
`WTC,*0222B..*0240B`). Constants `LOG 4114441766517106`,
`LOG 4010000000000000`, `LOG 4050000000000000`, `INT 1,2` (lines 260-265).
The cosine-of-uniform-angle pattern plus its placement among the fitting
routines suggests Chebyshev node/weight spacing [I].

## Contour construction (DEK family)

### CONDEK (514 commands) and DRACON (650 commands)
These two modules share the same GRAFOR "DR" parameter blocks:
`*DRITP*` (1 word), `*DRINFN*` (3), `*DRFN*` (3) and `*DRIN*`
(26 words in CONDEK, 27 in DRACON), with named fields GAL/1..GAN/0
(CONDEK lines 13-45; DRACON lines 13-46). Both:
1. read the current position with `WHERE` (CONDEK line 54; DRACON line 62);
2. compute step/index values with `MOD` (CONDEK 189-193; DRACON 114-118);
3. call `FNROOT` three times with three different function-entry addresses to
   locate parameter values where the curve meets a boundary
   (CONDEK 242, 268, 298 with `*0545B`, `*0546B`, `*0547B`; DRACON 160, 186,
   221 with `*0675B`, `*0676B`, `*0701B`);
4. write the resulting points back into the record with `INSDEK` (CONDEK 399,
   481, 564, 638) or `INSIDE` plus field updates (DRACON 359-470);
5. set the same control constants in the trailing DATA block:
   `*DRITP* = 17321`, `GAK/7 = 4`, `GAK/6 = 15`
   (CONDEK 713-722; DRACON 916-925).

DRACON additionally uses `SQRT` on coordinate differences (lines 383-434) and
calls `TMF` four times (lines 323-358) to prepare text/transform state;
CONDEK uses `TEXT 8HA*` (line 686) as a label and `I*DI*I` (line 379).
Together with INSDEK they form the contour/DEK subsystem of ГРАФОР-СУД [I].
