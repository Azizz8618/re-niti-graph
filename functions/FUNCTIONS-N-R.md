# FUNCTIONS N-R: library 22 (ГРАФОР-СУД), volume 2048

**Count: 40 of 40 modules described.** All 40 `.mad` files in the assigned range were read in full.
Source: dtran MADLEN disassembly of BESM-6 system library 22 (ГРАФОР-СУД), volume 2048, produced by
`/home/azizz/Yandex.Disk/dtran/dtran -F dms`. Inputs: `../madlen/INDEX.md`, the 40 individual
`../madlen/<name>.mad` listings, `../madlen/AUDIT/IO-MODULES.md`,
`../madlen/AUDIT/OVERLAY-HINT.md`, `../extract/catalog.txt`, `../disasm/INDEX.md`.

Size in the tables below is taken from the dtran header lines `C Commands:` / `C Constants:` of each
`.mad` (it can differ from the "Load cat/hdr" column of INDEX.md, which counts catalog header words).
All line numbers are 1-based lines inside the named `.mad` file. Statements marked **[I]** are
inferences; everything else is directly observed in the listing.

Key negative observation (important for the OVERLAY question): **none** of the 40 modules in this
range contains an Э50/Э72/Э74 extop token (`,*50,`, `,*72,`, `,*74,`) or a `,CALL,` instruction.
The only disk-exchange access in this range is indirect: `NEXTZN` calls `GDISC`/`FDISC` via `VJM`,
`RCATAL` dispatches to `RZONE`/`WZONE` via `UJ`, and `RZON` transfers to `E70`/`*70` via `UJ`.
The actual `*50`/`*72` extops live in `GDISC.mad` and `_s70.mad` (outside this range), see
`AUDIT/IO-MODULES.md`. The modules named `RD*` are **not** disk readers: they are GRAFOR
graphic-element record helpers over the `*GFGEL*` (LC,28) workspace.

---

## 1. Alphabetical master table (all 40 modules)

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---:|---|---|---|
| NEXTZN | 100/12 | Advance/allocate the next free catalog zone; brackets the operation with GDISC/FDISC (disc open/close) | GDISC L46, FDISC L127 | L13-14 SUBP; L46, L127 VJM; L52 `13,UTM,1000B`; L80-88 descriptor loop; L138-147 masks |
| NOTCH | 71/6 | Hatch (штриховка) fill of a region using a 51-word notch pattern and blanking table | GOBSEK L143, GFFALS L116 | L13-35 tables `*GFNTCH*`/`*GFGOBS*`/`*GFBLAN*`; L64-100 segment setup; L143 VJM GOBSEK |
| NUMBER | 323/23 | Format a floating number as a plotted character string (sign, zero, exponent, decimal) via SYMBOL | SYMBOL L62,L90,L133,L218,L254,L354; ALOG10 L142,L316; IBCD L233,L371 | L13-23 SUBP list; L422-432 strings `**`, `-`, `.`, `0`, `000000`; L219-228 exponent path |
| NUMLIN | 22/2 | Store line-number/format fields into the 4-word `*GFLMN*` graphics field | none | L13-16 EQU GFLMN+1..+3; L19-33 stores; L52 `,INT,666` |
| OPER | 161/15 | Diagnostics/error report "ERROR DETECTED IN ROUTINE OPER/)" with numeric conversion | FT*571 L199, FT*003 L200 | L13-14 SUBP; L225-233 ISO diagnostic text; L237 `,LOG,4050000000000000`; L238-247 BSS parameters |
| PATCH | 560/6 | Piecewise-linear curve patching: clip an incoming polyline against the frame and draw the visible pieces | LININT L142, SEARCH L229,L413, BUFL L296,L636, MOVE L312,L326,L343,L599,L694, RDB L51,L76 | L13-31 tables `*GFL*`/`*GFXY*`/`*GFB*`; L40-80 internal coordinate helper; L118-160 clipping branches |
| POLG | 77/7 | Draw a regular polygon: divide 2*pi by N, step angle with SIN and MOVA | MOVA L51,L61,L91,L116; SIN L38,L64; R*DI*I L22,L75 | L13-16 SUBP; L137 `,LOG,4413200000000000`; L138/L140 `DK0`/`CK0` |
| POLINE | 262/5 | Draw a clipped polyline with optional markers at vertices | IRDB L27,L38; TPF L141,L164,L291; MOVE L238,L300,L330; MARKER L266,L317 | L13-22 SUBP; L80-99 sign/multiply; L167-231 extent checks; L354 `,LOG,4000000000000000` |
| POLREG | 331/22 | Draw a regular polar grid/diagram with rings, radii and labelled ticks | CIRCLE L214,L262,L314,L346; SYMBOL L419; MOVE L176,L195,L237; IRDB/RDB/IWDB/WDB L27-111 | L13-22 SUBP; L452-458 float constants; L453/457 `DK0`/`CK0` |
| POLYG | 130/5 | Draw a polygon from centre, radius, number of sides and rotation using SIN/COS + MOVE | MOVE L42,L86,L110,L151; SIN/COS L68-103; R*DI*I L52,L124 | L13-16 SUBP; L183-185 float constants |
| PRJT | 477/10 | Project a 3D object (vertex list) onto the plot through TMF/MAP and draw visible edges with MOVE | TMF L132,L220,L297,L364; MAP L99,L203,L287,L347; MOVE L157,L166,L234,L243,L316,L377,L418,L426 | L13-18 SUBP; L19-18 `*GFVP*`; L466-540 internal index/stack helpers; L597-604 constants |
| PRSP | 1116/5 | Perspective drawing of a 3D object; sequence of 16-argument CORNL calls for each face/edge | CORNL L297,L341,L385,L429,L511,L555,L637,L681,L778,L822,L867,L912,L1009,L1053,L1098,L1143; RDB L71 | L13-24 tables `*GFXY*`/`*GFVP*`/`*GFKJ*`; L69-125 RDB-driven limits; L1172-1176 constants |
| PSCALE | 27/2 | Build a scaling affine transformation and apply it through ATRAN2 | ATRAN2 L41 | L13 SUBP; L16-26 scale computation; L59-60 `LOG 0` / `4050000000000000` (1.0) |
| PUTXY | 14/3 | Pack/unpack an X,Y plotter coordinate word (two entry points) | none (13,UJ return L24,L36) | L13-24 pack entry; L25-36 unpack entry; L37-39 masks `177`, `377`, `77600` |
| PVAL | 33/2 | Scale/fill a caller array cell by cell in a decrementing loop | none | L15-22 arg capture; L23-43 loop `WTC/XTA/A*X/ATX`; L64-65 `LOG 0`, `INT 1` |
| QUADRA | 163/7 | Integer double-loop accumulation of products of two arrays into two running sums (quadratic form / quadrature) [I] | I*MU*I L86,L165; I*MUI* L193,L505,L526,L571,L578,L585; internal L118,L124 | L13-14 SUBP; L22-114 first loop; L68-114 second loop; L183/L190 `13,VJM` local helpers; L232-238 constants |
| RAND | 33/3 | Pseudo-random number generator (multiplicative congruential) [I] | I*MU*I L20,L32; I*DI*I L27 | L13-14 SUBP; L17-48 recurrence; L67-69 `INT 67108864` (2^26), `TEXT 8HMH`, `INT 3125` (5^5) |
| RAXES | 447/20 | Draw axes with tick marks, signs and numeric labels (radial/polar option via CIRCLE) | SIGNA L123; TPF L146,L301; NUMBER L427; CIRCLE L482,L507,L535; MOVE L195,L308,L363,L372,L544; IRDB/RDB L31,L62 | L13-26 SUBP list; L55-73 loop; L249-326 tick/label computation; L584-599 constants |
| RCATAL | 13/0 | Catalog read/write dispatcher: load `*LICAT*` descriptor and jump to RZONE or WZONE | RZONE (UJ) L30, WZONE (UJ) L31 | L13 `*LICAT* :LC,132096`; L14-15 SUBP; L18-27 register setup; L29 `10,VZM`; L30-31 UJ |
| RDACA | 75/3 | GFGEL arc record, variant A: compute circular-arc geometry and store element fields | STRMOD L37,L117; GFFALS L108; ABS L40; R*ST*I L42,L51; SIN/COS L74,L87 | L13-27 `*GFGEL*`/EQU offsets; L29-36 mode test; L60-104 field stores; L139-149 `INT 0/2`, `INT 6` |
| RDACB | 147/5 | GFGEL arc record, variant B: two-radius/two-angle arc with endpoint selection | STRMOD L37,L197; GFFALS L188; SIN/COS L83,L96,L109,L122; R*ST*I L42,L51 | L13-26 offsets; L67-127 geometry; L128-173 endpoint branches; L223 `LOG 4413200000000000` |
| RDACC | 114/3 | GFGEL arc record, variant C: radius via R*DI*I and three COS/SIN pairs | STRMOD L38,L148; GFFALS L139; R*DI*I L76; COS/SIN L85-129 | L25 R*DI*I SUBP; L66-77 radius; L83-133 stores; L170-172 `INT 0/2/6` |
| RDACD | 76/3 | GFGEL arc record, variant D: compact two-trig arc | STRMOD L37,L119; GFFALS L110; SIN/COS L82,L95 | L13-26 offsets; L60-106 field stores; L141-143 `INT 0/2` |
| RDAEA | 131/4 | GFGEL ellipse-arc record, variant A: SQRT-based ellipse geometry | STRMOD L40,L173; GFFALS L164; SQRT L132; SIN/COS L116,L123,L144,L155 | L30-37 mode test; L114-160 geometry; L195-198 `INT 0/2`, `INT 20` |
| RDAEB | 157/4 | GFGEL ellipse-arc record, variant B: two SQRT values, four output coordinates | STRMOD L40,L213; GFFALS L204; SQRT L128,L151; SIN/COS L113-199 | L13-29 offsets `GAL/0..GAM/1`; L111-156 radii; L166-200 stores; L235-238 `INT 0/2`, `INT 20` |
| RDCRC | 54/3 | GFGEL circle record: centre/radius conversion and three result words | STRMOD L32,L81; GFFALS L72; ABS L35; R*ST*I L37,L46 | L13-21 offsets; L24-36 conversion; L57-68 stores |
| RDELP | 62/3 | GFGEL ellipse record: centre/axes conversion and five result words | STRMOD L34,L92; GFFALS L83; R*ST*I L39,L48 | L13-23 offsets; L26-36 conversion; L60-79 stores |
| RDMVA | 71/2 | GFGEL move/vector record A: length via SQRT and direction via ANGLER | STRMOD L35,L109; GFFALS L100; SQRT L87; ANGLER L94 | L13-24 offsets; L58-96 geometry; L130-131 `INT 0/6` |
| RDMVB | 60/2 | GFGEL move/vector record B: four result words, no trigonometry | STRMOD L33,L90; GFFALS L81; R*ST*I L38,L47 | L13-22 offsets; L56-77 stores; L111-112 `INT 0/6` |
| RDMVC | 76/3 | GFGEL move/vector record C: R*DI*I division and SQRT for two endpoints | STRMOD L35,L116; GFFALS L107; R*DI*I L80,L87; SQRT L101 | L13-24 offsets; L58-103 geometry; L138-140 `INT 0/2/6` |
| RDMVE | 56/2 | GFGEL move/vector record E: simplest four-word variant | STRMOD L33,L86; GFFALS L77; R*ST*I L38,L47 | L13-22 offsets; L56-74 stores; L107-108 `INT 0/6` |
| RDSTR | 23/2 | GFGEL string record: copy/convert length-delimited character data | none | L13-14 `GAK/3 = *GFGEL*-32767`; L17-33 loop; L51-52 `INT 1`, `INT 28` |
| REBLAN | 47/2 | Insert/remove blanking intervals in `*GFBLAN*` (11 words) using MOVE | MOVE L82 | L13-30 tables `*GFATRN*`/`*GFBLAN*`; L34-90 logic; L105-107 `INT 0/1` |
| RECT | 70/3 | Draw a (possibly rotated) rectangle by SIN/COS and five MOVE calls | MOVE L38,L58,L75,L94,L103; SIN/COS L24,L28 | L13-15 SUBP; L18-103 geometry; L123-125 `INT 0/1`, `LOG 4316245671430770` |
| REGION | 156/16 | Compute/draw a labelled region frame: read parameters, scale, draw BOX and SYMBOL | IRDB L26; RDB L33,L37,L88,L106; WDB L134,L140,L145,L150; BOX L167; SYMBOL L194; IWDB L199,L205; FLOAT L48; AMIN1/AMAX1 L55,L66 | L13-21 SUBP; L39-129 scaling; L225-238 constants `INT 1..17`, floats |
| RENTCH | 73/5 | Renumber/re-index the `*GFGOBS*` (20-word) object table using division/multiplication by 8 and 4 | I*DI*I L68,L73; I*MU*I L81 | L13-26 tables; L30-124 search/update; L143-144 `INT 4`, `INT 8`; L147-168 16-word DATA table |
| RENUM | 13/1 | Set the line-number field `*GFLMN*+3` from the argument | none | L13-16 EQU; L19-23 store; L38 `INT 0` |
| RESET | 31/2 | Reset the affine transformation to identity via ATRAN2 | ATRAN2 L55 | L13-22 `*GFATRM*` offsets; L25-42 zeroing; L70-71 `LOG 0`, `LOG 4050000000000000` |
| ROTATE | 44/3 | Build a rotation matrix from an angle (SIN/COS) and apply it via ATRAN2 | SIN L29, COS L25, ATRAN2 L68 | L18-30 angle scaling; L31-55 matrix; L86-88 constants (`pi/180`-like, `2*pi`, `1.0`) |
| RZON | 26/2 | Zone read: test zone descriptor, loop over words, transfer to the Э70 path (E70 / *70) | E70 (UJ) L32, *70 (UJ) L33 | L13-14 SUBP; L19-35 descriptor tests `ASN 64-36/64-39`; L26-31 U1M loop; L52-53 `LOG 6200000000000000`, `LOG 770000` |

---

## 2. Disk / catalog / zone stack (OVERLAY-relevant): NEXTZN, RCATAL, RZON

### 2.1 NEXTZN (100 commands, 12 constants)
Purpose: "next zone" manager of the GRAFOR disk workspace. It opens the disk through `GDISC`,
walks/updates the zone descriptor chain and closes the disk through `FDISC` **[I: the exact meaning
of the returned descriptor is not documented, but the open/close bracket and the descriptor loop are
directly visible]**.

Algorithm:
1. Prologue saves return links in R7/R14 and builds the R13 link register (L15-22).
2. `14,VTM,*0004B` / `14,VLM,*0004B` (L23-24) and `3,XTA,12B` / `7,ARX,103B` (L26-29) decode the
   incoming zone/flags against octal masks.
3. `13,VJM,GDISC` (L46) obtains the disc/catalog context; `13,UTM,1000B` (L52) offsets a pointer by
   0o1000 = 512 words, consistent with a 512-word zone buffer **[I]**.
4. L53-78 compare descriptor codes (`106B`, `102B`, `100B`, `104B`, `110B`) via `ASN`/`AAX`/`ARX` and
   choose the branch; L80-88 copy a chain of descriptors with `STI`/`STX` and `14,V1M,*0042B`.
5. Error exits converge on `*0077B` (L98, L130, L136-137).
6. `13,VJM,FDISC` (L127) closes/commits before return.
Constants L138-147: `100000`, `40`, `10000000000000`, `400000`, `1`, `10000`, `1000000000000`,
`770000`, `77777`, `777` - octal field masks used by the descriptor tests.
Caller: `E70.mad` declares `NEXTZN` as SUBP (L14) and calls it with `13,VJM,NEXTZN` (L25).
This makes NEXTZN part of the Э70 entry path, not a DISPAK monitor routine itself.

### 2.2 RCATAL (13 commands, LC constant `*LICAT*`)
Purpose: read/write dispatcher for the GRAFOR catalog zone. It loads the catalog descriptor
`*LICAT* :LC,132096` (0o400140) into R14 (L25), copies parameters into R9/R5/R7/R1/R6 (L18-27),
tests a word with `10,VZM,*0011B` (L29) and jumps to `RZONE` (L30) or `WZONE` (L31).
`RZONE` and `WZONE` are catalog reference entries with no `.mad` body of their own: their code is
embedded in this module (see `AUDIT/IO-MODULES.md` section 4 and `extract/catalog.txt`).
Callers: `SETK.mad` (SUBP L16, `13,VJM,RCATAL` L27) and `GIVZON.mad` (SUBP L17, VJM L28).
OVERLAY relevance **[I]**: "find module in catalog by name" (FIND0) is functionally this path
(`RCATAL -> RZONE/RZONE`), but no direct call edge from OVERLAY* to RCATAL exists in this corpus.

### 2.3 RZON (26 commands, 2 constants)
Purpose: low-level zone read. It checks the caller's zone descriptor word: `9,XTA,4`,
`8,AAX,26B` (L19-20), `ASN,64-36` (L23) and `ASN,64-39` (L35) select two modes; L25-31 form an
address loop (`10,V1M,*0007B`, `10,V1M,*0011B`); the two exits are `,UJ,E70` (L32) and
`,UJ,*70` (L33). Constants: `,LOG,6200000000000000` (L52) and `,LOG,770000` (L53), the latter a
typical octal field mask (0o770000) used with `AOX`/`ASN` to extract a zone number **[I]**.
No `VJM` call site naming `RZON` was found in this corpus. Note that the `UJ` targets inside
`RCATAL` are the separate catalog reference entries `RZONE`/`WZONE`, whose code is embedded in
`RCATAL`, not this standalone module. `E70` is the catalog-facing wrapper and `*70` (`_s70.mad`)
is the actual Э70 handler that issues `*50` (1206B, 115B, 116B) and `*72` extops.

### 2.4 Verdict on the OVERLAY* worker (question from the parent audit)
- **Directly observed in this range:** `NEXTZN` calls `GDISC`/`FDISC`; `RCATAL` dispatches to
  `RZONE`/`WZONE`; `RZON` transfers to `E70`/`*70`. No other module in N-R touches catalogs or zones.
- **[I, medium confidence]** If the failing OVERLAY* exchange goes through library 22, the modules
  to inspect are `RCATAL` (catalog lookup analogue of FIND0), `RZON` (zone body read analogue of
  COPY), `NEXTZN` (zone walk with GDISC/FDISC), and, outside this range, `E70`/`*70`/`GDISC` where
  the real `*50`/`*72` extops are issued.
- **[I, important qualification]** The OVERLAY* body itself is at zone 0o1457 word 448 on volume
  2048, not in library 22, and no `.mad` in this range mentions OVERLAY, FIND0, IO1, IO3, REDAKT or
  STLOAD. The identification is a functional match, not a resolved cross-reference. See
  `AUDIT/OVERLAY-HINT.md` for the full argument and the two competing readings (a) and (b).

---

## 3. GFGEL graphic-element record I/O: the RD* family (and its WR* twins)

All 13 `RD*` modules in this range share one skeleton:

* `*GFGEL* :,LC,28` defines a 28-word graphic-element record base (L13 in each file).
* Named offsets are `EQU` expressions on that base, for example `GAK/7 = *GFGEL*+8`,
  `GAL/1 = *GFGEL*-32767`, `GAL/3 = *GFGEL*+27` (RDACA L19-26). The `-32767` form is a 15-bit
  wrap that denotes base+1 **[I]**.
* Common SUBP set: `GFFALS` (error/false flag), `STRMOD` (mode/record setup), `ABS`, `R*ST*I`
  (real-to-integer scaling); geometry members add `SIN`, `COS`, `SQRT`, `R*DI*I` (integer divide),
  `R*PO*I`, `ANGLER`.
* Entry prologue `7,MTJ,8 / 14,MTJ,10`; parameter/return handling via R1..R7 and the R13/R14 link
  registers; invalid input branches to `VJM,GFFALS`; every path ends by re-establishing `STRMOD`.
* Results are written into module-local BSS cells (`WTC,*nnnnB` + `ATX`) that form the element
  payload. No `,CALL,`, no extops, no catalog or zone access.

The `WR*` modules in the library (outside this range) use the same `*GFGEL*` base and the same
EQU-offset scheme. `RDSTR.mad` and `WRSTR.mad` differ essentially only in `1,XTA,-1` vs `1,ATX,-1`
(L24-26) and in using `GAK/3` vs `GAK/2`, which supports the reading that **RD* fetch/compute an
element record and WR* store one back** **[I]**. Callers found in this corpus: `DIMDRO.mad` uses
`RDSTR`, `RDACB`, `RDACA`, `RDMVA` (SUBP lines 16-27); `LITAN.mad` uses `RDCRC` (L23).

| Module | Record produced | Distinctive computation / constants | Evidence |
|---|---|---|---|
| RDSTR | string component | pointer/length loop, `GAK/3` (= base+2), 28 | L17-33, L51-52 |
| RDCRC | circle (centre, radius, 3 fields) | `R*ST*I` twice, stores from `*GFGEL*`, `GAL/0`, `GAL/1` | L37-68 |
| RDELP | ellipse (centre, two axes, 5 fields) | `A+X` radius path, `GAL/0..GAL/3` | L51-79 |
| RDACA | circular arc A | `GAL/2*GAL/3`, `COS`/`SIN` with `*GFGEL*`+`GAL/4/5`, 7 stores | L62-104 |
| RDACB | circular arc B | `GAL/4*GAL/3` twice, two radii (`+6`,`+2`), endpoint swap branches | L67-173, L223 |
| RDACC | circular arc C | `R*DI*I`, three `COS`/`SIN` pairs, `GAL/6`, `GAL/7` | L76-133 |
| RDACD | circular arc D | compact two-`COS`/`SIN` path | L67-106 |
| RDAEA | elliptical arc A | `SQRT` of `sin^2+cos^2`-style sum, `GAM/0=+6`, `GAM/1=+1` | L114-160 |
| RDAEB | elliptical arc B | two `SQRT` radii, four output coordinates | L111-200 |
| RDMVA | vector A | `SQRT(dx^2+dy^2)` then `ANGLER` | L78-96 |
| RDMVB | vector B | four-word store, no trigonometry | L56-77 |
| RDMVC | vector C | `R*DI*I` twice + `SQRT`, two endpoints | L78-103 |
| RDMVE | vector E | shortest four-word variant | L56-74 |

---

## 4. Graphics primitives and drawing

### 4.1 Polylines and polygons
* **PATCH** (560/6) is the largest curve module here. Internal helper at `*0001B` converts a value
  from `RDB` and `FLOAT` into plot coordinates scaled by `GFXY+3` (L47-57). The main path uses
  `LININT` (L142) for linear interpolation at a frame edge, `SEARCH` (L229, L413) to locate a
  segment, `BUFL` (L296, L636) to stage an output line, and `MOVE` (L312, L326, L343, L599, L694)
  to emit it. Tables: `*GFL*` (8), `*GFXY*` (5), `*GFB*` (7) (L13-31). Many `ASN/UZA` pairs test
  the four frame boundaries (L118-208, L344-388). Constants LOG 0, 1.0, 1.05 (L734-739).
  Caller: `CORNL.mad` declares PATCH as SUBP.
* **POLINE** (262/5) draws a clipped polyline; it reads integers with `IRDB` (L27, L38), uses
  `IABS`, `WHERE`, `ISIGN`, `I*MU*I` for extents (L47-99), calls `TPF` three times (L141, L164,
  L291) to transform endpoints, `MOVE` (L238, L300, L330) to draw, and `MARKER` (L266, L317) when a
  point marker is requested. Constant `LOG 4000000000000000` at L354.
* **POLYG** (130/5) and **POLG** (77/7) are the polygon pair. POLYG divides an angle with `R*DI*I`
  (L52, L124), steps with `COS`/`SIN` (L68-103) and emits four/five sides via `MOVE`; POLG uses
  `SIN` and `MOVA` (L38, L51, L64, L91, L116) with `DK0`/`CK0` text constants (L138, L140).
  POLG is called by `STAR.mad`.
* **POLREG** (331/22) reads a polar specification through `IRDB`/`RDB`/`IWDB`/`WDB` (L27-111),
  then draws ring arcs with `CIRCLE` (L214, L262, L314, L346), connectors with `MOVE` and labels
  with `SYMBOL` (L419). Float constants at L452-458 include `DK0`/`CK0`, `1.0`, etc. **[I: "regular
  polar grid/diagram" is inferred from CIRCLE + SYMBOL + radial arithmetic, not from a title.]**

### 4.2 3D drawing
* **PRJT** (477/10) reads projection parameters into `*GFVP*` (L25-48), loops over a vertex/edge
  list using internal helpers `*0402B`/`*0414B`/`*0424B`/`*0430B`/`*0435B` (L484-540) with
  `I*MUI*` index arithmetic, applies `MAP` (L99, L203, L287, L347) and `TMF` (L132, L220, L297,
  L364) to transform coordinates, and draws the result with `MOVE`. **[I: "3D projection" follows
  from MAP+TMF+vertex loop; no literal title is present.]**
* **PRSP** (1116/5) is the perspective counterpart. It fetches limits/parameters with `RDB` (L71)
  and then issues a long, fixed sequence of 16-argument `CORNL` calls (L297, 341, 385, 429, 511,
  555, 637, 681, 778, 822, 867, 912, 1009, 1053, 1098, 1143), with branches that select which
  edges of a box/polyhedron are visible (L152-180, L433-469, L685-731, L916-955). Tables `*GFXY*`
  (5), `*GFVP*` (6), `*GFKJ*` (2) at L13-25. **[I: object type inferred from the repeated corner
  patterns.]**

### 4.3 Axes, regions, filled areas
* **RAXES** (447/20) draws axes with ticks and numeric labels. It validates two `IRDB` values
  (L31-50), loops over axis positions (L55-73), calls `SIGNA` (L123) for the sign axis, `TPF`
  (L146, L301) for transforms, `NUMBER` (L427) for tick labels, `CIRCLE` (L482, L507, L535) for
  the radial/polar option and `MOVE` for axis segments. Tick spacing uses `AMOD`, `AMIN1`, `SIGN`,
  `ABS`, `R*PO*I` (L249-326). Constants at L584-599 include `pi/2`-like and `2*pi` floats.
* **REGION** (156/16) reads an integer mark and two reals through `IRDB`/`RDB` (L26-38), derives a
  scale factor (L39-129), writes back parameters with `WDB` (L134-150), draws a frame with `BOX`
  (L167) and a label with `SYMBOL` (L194), and restores state with `IWDB` (L199, L205).
* **NOTCH** (71/6, BSS 131) hatches a region: `*GFNTCH*` is a 51-word notch/pattern table with
  offsets +16/+32/+48/+49/+50 (L13-18), `*GFGOBS*` (20) holds the object and `*GFBLAN*` (11) the
  blanking data (L19-34). L64-100 build five local segment arrays (16, 16, 16, 16, 19 words),
  L143 calls `GOBSEK` (intersection) and L116 reports invalid input via `GFFALS`.
* **RECT** (70/3) computes `SIN`/`COS` of a rotation angle (L22-29) and emits a closed rectangle
  with five `MOVE` calls (L38, 58, 75, 94, 103); constant `LOG 4316245671430770` (L125).
* **REBLAN** (47/2) maintains blanking intervals in `*GFBLAN*` (11 words) and the transform area
  `*GFATRN*` (7 words) (L13-30), using `MOVE` (L82) to shift the interval table.
* **RENTCH** (73/5) re-indexes the `*GFGOBS*` (20-word) object table: it divides an index by 8 and
  by 4 with `I*DI*I` (L68, L73), multiplies back with `I*MU*I` (L81), and consults a 16-word
  `DATA`/`SET` table at `*0100B`..`*0120B` (L147-168). **[I: renumbering/searching an index table.]**

### 4.4 Transformation, numbering and text
* **RESET** (31/2) zeroes the `*GFATRM*` (LC,115) fields +1..+5 (L25-42), loads 0.0 and 1.0
  (L70-71) and calls `ATRAN2` (L55) to install the identity transform.
* **ROTATE** (44/3) scales the input angle (L18-22), computes `COS`/`SIN` (L25-30), forms the
  2x2 rotation block (L31-55) and passes six arguments to `ATRAN2` (L56-68). Constants at L86-88
  include `4050000000000000` (=1.0), `4413200000000000` and `4114441766517106` (angle conversion).
* **PSCALE** (27/2) computes `1 - arg` (L16-26) and calls `ATRAN2` (L41) with a scale matrix
  assembled from constants LOG 0 / 1.0 (L59-60).
* **NUMLIN** (22/2) writes four fields `*GFLMN*`+0..+3 (L19-33) from two arguments and the constant
  `INT 666` (L52); **RENUM** (13/1) writes only +3 (L19-23). Both operate on the `*GFLMN*` (LC,4)
  graphics field.
* **NUMBER** (323/23) formats a real into plotted characters. It handles sign/zero (L26-46), emits
  sign and decimal-point symbols with `SYMBOL` (L62, L90, L133), computes the decimal exponent via
  `FLOAT` + `ALOG10` + `R*ST*I` (L135-149), chooses fixed vs exponential notation (L168-228),
  builds digits with `R*PO*I`, `IBCD`, `MOD`, `INT`, `MIN0` (L182-228, L309-392) and finalises with
  `SYMBOL`. Strings: `**` (L422), `-` (L424), `.` (L425), `0` (L429), `000000` (L432), `J/0D`
  (L430).
* **PUTXY** (14/3) has two entry points: L13-24 packs an X,Y pair (using `AAX 15B/14B`, `AOX`,
  `ASN 64-7`) into one word returned via `9,STX` / `13,UJ`; L25-36 unpacks it back into R9/R10.
  Constants `177`, `377`, `77600` (L37-39) are the field masks **[I: plotter coordinate word]**.

---

## 5. Utilities, numerics and diagnostics

* **OPER** (161/15): built-in error reporter. On a failed conversion/comparison (L23-26, L124-128,
  L187-195) it branches to L197 and calls `FT*571` then `FT*003` (L199-200) with a 9-word ISO
  message assembled from L225-233. Decoded 6-character groups read:
  ` (/9HLR` + ` P1 LE ` + `1/32HE` + `RROR D` + `ETECTE` + `D IN R` + `OUTINE` + `   OPE` + `R/)`,
  i.e. "(/9HLR P1 LE 1/32HERROR DETECTED IN ROUTINE   OPER/)" **[I: concatenation and spacing]**.
  The main body performs divisions (`7,A/X,4`, L50, L117, L173, L179) and array updates through
  BSS cells `*0201B`..`*0215B`. Caller: `SMTBVF.mad` declares OPER as SUBP.
* **PVAL** (33/2): captures two arguments (L15-22), then repeatedly multiplies an accumulator by
  the factor in `*0042B`, adds `*0041B`/`-1`, and stores through the pointer in R3 (L23-43).
  Callers: `APPOLY.mad`, `LSFIT.mad`, `SINCL.mad`.
* **QUADRA** (163/7): nested integer loops over two indexed arrays. The outer loop (L22-62) builds
  one index, the inner loop (L68-114) computes a product via `I*MU*I` (L86) and accumulates it.
  The second pair of loops (L115-181) uses `I*MUI*` (L165) and internal helpers at `*0131B`/`*0135B`
  (L183, L190) to accumulate two signed sums R20/R21; the finalisation at L557-588 multiplies the
  sums by a third array through `I*MUI*`. **[I: a quadratic form / quadrature computation; the
  arithmetic and loop structure are observed, the mathematical name is not.]**
* **RAND** (33/3): pseudo-random generator. It calls `I*MU*I` (L20, L32) and `I*DI*I` (L27), with
  constants `INT 67108864` = 2^26 (L67), `TEXT 8HMH` (L68) and `INT 3125` = 5^5 (L69); the state
  is kept in `*0042B`. This is the classic multiplicative congruential shape
  x' = (a*x + c) mod 2^26 **[I: exact a/c assignment requires tracing the double-length multiply].**

---

## 6. Observed register and coding conventions (for all modules above)

* Prologue `7,MTJ,8` / `14,MTJ,10` saves the two return links; epilogue restores `STI,7/8/13...`
  and returns with `8,UJ`. Parameters arrive in R1..R7; R13/R14 are used as link registers for
  `VJM` calls and as temporary address registers.
* `13,VJM,<name>` is the normal call; `,UJ,<name>` is a tail transfer (used by RCATAL and RZON).
* `*NAME*,LC,n` defines an absolute graphics-field cell; `X:,EQU,*NAME*+k` defines a field offset,
  with `*NAME*-32767` being base+1 under 15-bit wrap **[I]**.
* `WTC,<cell>` followed by `ATX` writes a computed value into a BSS result cell; `UTC,<cell>` adds
  a field value to the accumulator; `ASN,64+n` / `UZA` / `ARX` implement sign/magnitude tests.
* No module in this range issues a raw extop or `,CALL,`; all disc access is delegated to GDISC /
  FDISC / E70 / *70 outside the range.

---

## 7. Coverage checklist (40/40)

NEXTZN, NOTCH, NUMBER, NUMLIN, OPER, PATCH, POLG, POLINE, POLREG, POLYG, PRJT, PRSP, PSCALE,
PUTXY, PVAL, QUADRA, RAND, RAXES, RCATAL, RDACA, RDACB, RDACC, RDACD, RDAEA, RDAEB, RDCRC,
RDELP, RDMVA, RDMVB, RDMVC, RDMVE, RDSTR, REBLAN, RECT, REGION, RENTCH, RENUM, RESET, ROTATE,
RZON.
