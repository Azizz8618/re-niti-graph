# Library 22 (ГРАФОР-СУД): modules S, T, V, W, X, Y, Z

**Coverage: 71 modules** (SAVETR, SDPG, SEARCH, SECANT, SETEND, SETIND, SETK,
SETREF, SETTR, SETWGR, SETZON, SFCFIT, SHADE, SHEAR, SHIFT, SIGNA, SINCL,
SIZLIN, SIZNUM, SMINV, SMTBVF, SMTONE, SMTSIM, SPIRAL, SPLINE, SPLINT, STAR,
STRMOD, SUPLIN, SYMTAB, TCALC, TDLIM, TDLIML, TDLINE, TDMP, TDROT, TDSCAL,
TDSECT, TDTRAN, TFM, THAXES, THREED, TMF, TMLGF, TPF, TRIDIG, VIEW, WCATWO,
WHERE, WHERP, WRACA, WRACB, WRACC, WRACD, WRAEA, WRAEB, WRCRC, WRELP, WRMVA,
WRMVB, WRMVC, WRMVE, WRSTR, XAXIS, XLGAX, XPOL, YAXIS, YLGAX, YPOL, ZAPIT,
ZINT).

Source: **dtran MADLEN disassembly of library 22 (ГРАФОР-СУД) from volume 2048**
(`madlen/<NAME>.mad`, generated with `dtran -F dms`; name map: `*`→`_s`, `/`→`_p`).
All 71 `.mad` files in the range were examined. Line numbers in the Evidence
column are 1-based lines inside the named `.mad` file; sizes are the `C
Commands` / `C Constants` header values (BSS shown where relevant). The
listings carry no source comments, so purposes are reconstructed from the
instruction structure, the VJM call graph, GRAFOR common-block symbols
(`*GFGEL*`, `*GFBFTR*`, `*GFMATR*`, `*GFCRD*`, `*GFLIM*`, `*GFVIEW*`,
`*GFSHAD*`, `*GFCELL*`, `*GFL*`, `*GFXY*`, `*GFLMN*`, ...) and literal ISO/TEXT
strings. Reconstructions not directly provable from the code are marked
**[I]**. Cross-module context is taken from `madlen/AUDIT/IO-MODULES.md` and
`madlen/AUDIT/OVERLAY-HINT.md` (both read-only audits of the same corpus).

---

## 1. Low-level catalog / zone / disk routines and the OVERLAY* question

This is the most important group for the parent session's question. It contains
the GRAFOR library's own disk-exchange and catalog layer. The primitive chain
established by the adjacent audit (`IO-MODULES.md`, `OVERLAY-HINT.md`) is:

```
GDISC --*50--> disk open/driver        RCATAL --UJ--> RZONE / WZONE
E70   --VJM--> *70 and NEXTZN          RZON  --UJ--> E70 and *70
*70   --*50,*72--> disk I/O            SETK  --VJM--> GDISC, RCATAL, SETEND, WCATAL, FDISC
GIVZON --VJM--> GDISC, RCATAL, GIVENZ, SETREF, WCATAL, FDISC
WCATWO --VJM--> RZONE, WZON, CLEAZN, ISO*TEX*
SETEND --VJM--> RZONE, then *74 (STOP) on "НЕТ ТАКОЙ ЗАПИСИ"
```

**Register / cell conventions observed in this group.** `13,VJM,<name>` is the
standard call: index register 13 holds the return address. `14,VTM,<cell>` /
`,ITS,14` saves the caller's return link in a BSS cell before a chain of calls;
`8,VTM,...` and `7,VTM,...` save alternate links for re-entrant inner loops.
`WTC,<cell>` writes the accumulator into a parameter/indirect cell and
`UTC,<cell>` / `,XTA` reads it back; this is how parameters are passed through
modifier cells rather than a stack. `,STI,n`, `,ATI,n`, `,ITA,n` save, index and
restore index registers; `9,XTA,k` / `10,STX,k` are indexed memory accesses.
`VZM`/`V1M`/`UTM`/`UZA`/`U1A` are the conditional branches; `,ASN,64-n` and
`,ASN,64+n` are left/right arithmetic shifts used as bit-field masks.
`NTR,3` / `NTR,22B` mark fixed-point / flag setup. `DATA*`, `*LICAT*` are
local long constants (LC). Disk extops are `*50` (Э50), `*72`, `*74` (STOP).

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| SETEND | 55 / 12 | Finalises/updates the catalog "end" record. Reads a zone with `RZONE`, merges the record and writes it back; on failure prints the Russian message "НЕТ ТАКОЙ ЗАПИСИ" ("no such entry") through `PRINT8` and executes `*74` (STOP). Uses `DATA*` (LC 2), IR9–IR15, bit masks `3777775777777777`, `60740000000000`, `3740000000000000`, `1777`. | `RZONE`, `PRINT8`, `*74` | `RZONE :,SUBP,` / `PRINT8 :,SUBP,` (14-15); `13,VJM,RZONE` (81, 89); `13,VJM,PRINT8` (100); `,*74,` (101); ISO `6HHET TA` / `6HKOЙ ЗA` / `6HПИCИ` (102-104); masks (108-111). |
| SETIND | 32 / 2 | Sets/updates an **index-table** entry in a GRAFOR descriptor array: takes an index in IR9/IR12/IR13, packs/unpacks fields with shifts (`ASN,64±15`, `±9`), compares against limits using `VZM` and `J+M`, and writes several result words via `,STX,` / `13,STX,`. No external calls; pure table manipulation. Constants `77777000`, `7777777700000777` are field masks. **[I: exact table semantics]** | none (internal only) | `,STI,12 / ,STI,13 / ,XTS,` (16-18); `,ASN,64-15` / `14,VZM,*0015B` (32-36); `,LOG,77777000` / `,LOG,7777777700000777` (63-64). |
| SETK | 32 / 0 (BSS 4) | "Set catalog": the main catalog open/setup chain. Saves IR7/IR8 and the return link in four BSS cells, then calls in order `GDISC` (open disk), `RCATAL` (read catalog), `SETEND` (verify/update end), `WCATAL` (write catalog), `FDISC` (close disk). This is the disk-catalog entry point used before any GRAFOR file work; a monitor `FIND0`-like worker would naturally reach it **[I]**. | `GDISC`, `RCATAL`, `SETEND`, `WCATAL`, `FDISC` | SUBP declarations (13-17); `13,VJM,GDISC` (23), `RCATAL` (27), `SETEND` (40), `WCATAL` (44), `FDISC` (48); cold-start save `7,MTJ,8 / 14,MTJ,10 / 7,STX,3..` (50-65); BSS `*0032B..*0035B` (67-70). |
| SETREF | 45 / 6 | Sets/updates a **reference-table** entry: similar structure to SETEND but with no disk call. Walks an array indexed by IR10/IR11, tests a reference word against `100000`, `1`, `7777700077777777`, `77777`, `777`, uses `V1M` branches, `AAX`/`ARX`/`AEX` arithmetic and stores the patched word. **[I: reference table meaning]** | none (internal only) | `,STI,11 / ,STI,10 / ,ATI,9` (16-18); `14,V1M,*0014B` (28); `13,UTM,1000B / 10,J+M,13` (50-51); constants `,LOG,100000` / `1` / `7777700077777777` / `77777` / `777` (83-88). |
| SETTR | 30 / 2 (BSS 2) | "Set transformation": loads a 3-D affine/homogeneous matrix into the common `*GFMATR*` (LC 34) and sets a flag in `*GFTR*` (LC 2). Loops over the 16 matrix words with `NTR,3` / `NTR,22B` and `IABS`, writing through indirect offsets `GAK/2=+16`, `GAK/3=+32`, `GAK/4=+33`, `GAK/6=*GFTR*+1`, `GAL/0=*GFMATR*-32767`. Counterpart of SAVETR. | none (uses local code blocks) | LC/EQU block (13-19); copy loop `7,XTA,2 / 7,ATX, / ,NTR,3 / ,NTR,22B / 7,A+X / 7,ATX,2` (21-31); `,UTC,*GFTR*` / `,UTC,GAK/6` stores (39-47); return/restores (48-69). |
| SETWGR | 7 / 2 | Sets a "writer-group"/descriptor field (name is opaque) **[I]**. Forms an index in IR9, reads `mem[IR9+4]`; if non-zero it adds the constant `10B` (octal 10) and tests bit 1 (`U1A`); it then stores either `mem[IR8+7]` or `mem[0]` into `mem[IR9+2]`. IR8 holds a caller-supplied pointer; returns via IR13. Constants `6200000000000000` and `770000` are masks/flags. | none | `8,VTM,*0000B / ,ATI,9 / 9,XTA,4` (14-16); `,UZA,*0005B / 8,AAX,10B / ,U1A,*0005B` (17-19); `8,XTA,7 / 9,STX,2 / 13,UJ,` (20-22); `,LOG,6200000000000000 / ,LOG,770000` (25-26). |
| SETZON | 4 / 0 | Zone-descriptor field setter: `,STI,9` and `,ATI,10` take an index/offset from the accumulator, reads `mem[IR9]`, normalises it with `ASN,64-9` then `ASN,64+9` (extract/sign-extend a field), stores it to `mem[IR10+5]`, returns via IR13. A primitive for copying a zone number between descriptor arrays. | none | `,STI,9 / ,ATI,10 / 9,XTA, / ,ASN,64-9 / ,ASN,64+9 / 10,STX,5 / 13,UJ,` (13-19). |
| WCATWO | 160 / 13 | "Write catalog entry, version TWO": converts an ISO/TEXT name with `ISO*TEX*`, then inserts a catalog record by reading the target zone with `RZONE`, rewriting it with `WZON` and clearing scratch with `CLEAZN`. Heavy bit packing (`AAX`, `AOX`, `ARX`, `ASN`) of name and descriptors; uses IR7/IR9–IR14 and constants `1000000000000000`, `4000000000000000`, `7000000000000000`, `3777777776000777`, `77777`, `1777`. | `ISO*TEX*`, `RZONE`, `WZON`, `CLEAZN` | SUBPs 13-16; `13,VJM,ISO*TEX*` (77); `13,VJM,RZONE` (188, 198); `13,VJM,WZON` (200); `13,VJM,CLEAZN` (203); masks/constants (230-239). |
| WHERE | 24 / 2 (BSS 5) | Computes the current position/record pointer in **file A** (`*GFAFTR*`, LC 2; `GAK/2=+1`): calls `RDB` twice, divides the two readings (`7,A/X,3`), writes the result into the work cell `*0032B` and returns it. Companion of WHERP. | `RDB` (twice) | `*GFAFTR*:,LC,2 / GAK/2` (13-14); `13,VJM,RDB` (28, 32); `7,XTA,2 / 7,A/X,3 / ,WTC,*0032B` (36-39). |
| WHERP | 24 / 2 (BSS 5) | Same algorithm as WHERE but for **file B** (`*GFBFTR*`, LC 2); two `RDB` calls, divide, store result in `*0032B`. The pair likely answers "where is the current pointer" for the two GRAFOR files **[I]**. | `RDB` (twice) | `*GFBFTR*:,LC,2 / GAK/2` (13-14); `13,VJM,RDB` (28, 32); `7,XTA,2 / 7,A/X,3 / ,WTC,*0032B` (36-39). |

**Detailed reading of the low-level routines.**

- `SETK.mad:21-49` is a straight-line macro: after saving the link, each
  `13,VJM,<primitive>` is preceded by `,WTC,*0032B / 14,VTM, / ,ITS,14`, i.e.
  the primitive is called with a pointer in a work cell and the caller's link
  is re-saved before the next call. The four BSS words `*0032B..*0035B` are the
  save cells for GDISC/RCATAL/SETEND/WCATAL/FDISC. The alternate entry
  `*0021B` (lines 50-66) is the "cold start" path: it saves IR7, IR8 and IR0,
  clears `*0032B..*0035B` and restores them on exit. This is a classic DMS
  entry stub, and it is why SETK is the natural library-22 analogue of a
  monitor worker's "open catalog" step **[I]**.

- `SETEND.mad:66-101` tests a word fetched through `UTC,DATA*`; the bit tests
  (`ASN,64-7`, `ARX`, `UZA`) select one of two `13,VJM,RZONE` calls (81, 89) that
  read the zone containing the catalog end marker. `,ASN,64-3` / `,UZA,*0050B`
  (72-75) distinguishes "found" from "not found"; the "not found" branch calls
  `PRINT8` (100) with the three ISO strings "НЕТ ТА / КОЙ ЗА / ПИСИ" (102-104)
  and then `,*74,` (101) stops. So SETEND is both an updater and a fatal-error
  checker on catalog lookup.

- `WCATWO.mad:44-120` is the name/field packing loop: `,XTS,` reads a name
  character through IR9, `7,AAX,163B`/`165B`/`157B` add packed ASCII constants
  and `15,AOX,` ORs them into the catalog word at `9,ATX,1`. It calls
  `ISO*TEX*` (77) to convert text to the internal ISO representation, then at
  lines 162-205 handles the zone side: read (`RZONE` 188, 198), conditional
  write (`WZON` 200), clear (`CLEAZN` 203), and `,ATX,1776B` writes a marker.

**Could the monitor OVERLAY* worker call these? [I, high confidence]**
`madlen/AUDIT/OVERLAY-HINT.md` establishes that the worker named in the link
map lives at zone `0o1457` on volume 2048, **not** in library 22, and that its
sub-steps are FIND0 (catalog lookup by name), COPY (move body), PROC (build
segment catalog). Those three operations map one-to-one onto this group:
FIND0 → `RCATAL`/`SETEND`/`RZONE`/`WCATWO` (catalog search and "no such entry"
error), COPY → `RZONE`/`E70`/`*70`/`GDISC` (zone read via the Э70 path),
PROC → `WCATWO`/`WZON`/`CLEAZN` (write catalog/segment entries).
`RCATAL` already dispatches to `RZONE`/`WZONE`, `RZON` transfers to `E70` and
`*70`, and `*70` is the only module in the library with the name `*70` that
issues `*50`/`*72` disk extops. Therefore the most likely library-22 entry
points an OVERLAY worker would hit are `RCATAL`, `RZONE`, `E70`/`*70`,
`GDISC`/`FDISC`, and `WCATWO`/`SETEND`. **Important qualification [I]:** no
`.mad` file mentions OVERLAY, FIND0, IO1, IO3, REDAKT or STLOAD, so there is no
resolved cross-reference. Either (a) the worker calls this GRAFOR layer through
REDAKT's link map, in which case library 22 does hold the failing exchange, or
(b) it uses the DISPAK monitor's own Э70 and merely loads library-22 modules,
in which case these are an equivalent but unused copy. The disassembly alone
cannot decide; resolving the external symbol table of the OVERLAY* DMS module
at zone `0o1457` word 448 would. (The `REDAKT`-link-map link map printed
REDAKT and Pascal runtime names; this fits (a), but is not proof.)

---

## 2. Graphic-element output: the WR* family and friends

All WR* modules write one graphic element into the GRAFOR element buffer
`*GFGEL*` (LC 28, 28 words) using the file pointer common `*GFBFTR*` (LC 2,
`GAK/2 = +1`, `GAK/3 = +2`). They take parameters through indirect cells
(`,WTC,*nnnnB` then `1,XTA,-1`, `2,ATX,-1`, ...), compute the element geometry
with `SIN`/`COS`/`SQRT`/`ABS`/`ANGLER`, call `R*ST*I` to record element-start
information, and finish with `STRMOD` (which stores the modified 28-word
element into the output stream: `STRMOD.mad:150-175`, ending with `28,SET,*0125B`
and the relocation `1,,*GFGEL*`). `GFFALS` is the "invalid element / false"
exit. `TEXT 8HDK0` / `8HCK0` and `LOG,4354400000000000`, `LOG,3550737215211226`
are recurring element-type markers. Variants A/B/C/D denote different input
specifications for the same primitive.

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| WRACA | 70 / 4 | Writes a **circular arc** (variant A) into `*GFGEL*`: reads centre/radius from `*GFBFTR*`, takes ABS of the radii, computes start/end coordinates with `COS`/`SIN` of the two angles, fills the GAL/GAM fields of the element and emits it. | `ABS`, `R*ST*I`, `COS`, `SIN`, `STRMOD`, `GFFALS` | SUBPs 16-24; `13,VJM,ABS` (50, 59); `13,VJM,R*ST*I` (61); `13,VJM,COS` (74); `13,VJM,SIN` (82); `13,VJM,STRMOD` (108); `13,VJM,GFFALS` (112); `,LOG,4354400000000000` (135). |
| WRACB | 36 / 0 | Arc **variant B** wrapper: derives dx/dy from `*GFBFTR*` and two indirect parameters, calls `ARCANG` to get the angle range and delegates to `WRACA`. | `ARCANG`, `WRACA` | SUBPs 15-16; `13,VJM,ARCANG` (47); `13,VJM,WRACA` (55); WTC/ATX parameter setup 19-33. |
| WRACC | 51 / 0 | Arc **variant C** wrapper: calls `ARCC1` (circle through three points), then `ARCANG` for the angles, then `WRACA` to write the element. | `ARCC1`, `ARCANG`, `WRACA` | `13,VJM,ARCC1` (53); `13,VJM,ARCANG` (68); `13,VJM,WRACA` (77). |
| WRACD | 73 / 3 | Arc **variant D**: computes radius with `SQRT(dx²+dy²)`, direction with `ANGLER`, takes ABS, calls `R*ST*I`, packs the element and calls `STRMOD`. | `SQRT`, `ANGLER`, `ABS`, `R*ST*I`, `STRMOD` | `13,VJM,SQRT` (56); `13,VJM,ANGLER` (62); `13,VJM,ABS` (79); `13,VJM,R*ST*I` (81); `13,VJM,STRMOD` (117). |
| WRAEA | 122 / 4 | Writes an **elliptic arc** (variant A): takes centre and two semi-axes from `*GFBFTR*`, uses `ABS`, `SIN`, `COS` and `SQRT` to derive the parameter ratio, `R*ST*I`, then packs five GAM fields and emits via `STRMOD`. | `ABS`, `SIN`, `COS`, `SQRT`, `R*ST*I`, `STRMOD`, `GFFALS` | `13,VJM,ABS` (68, 97); `SIN` (72); `COS` (79); `SQRT` (88); `R*ST*I` (99); `COS`/`SIN` (115, 126); `STRMOD` (160); `GFFALS` (164). |
| WRAEB | 105 / 3 | Elliptic-arc **variant B**: ABS of centre differences, rotated coordinates via `SIN`/`COS`, `R*DI*I`, `R*ST*I`, then `ARCANG` and `AREB1` to derive angles and `WRAEA` to emit. | `ABS`, `SIN`, `COS`, `R*DI*I`, `R*ST*I`, `ARCANG`, `AREB1`, `WRAEA` | `13,VJM,ABS` (34, 39, 83); `COS`/`SIN` (58, 63, 69, 75); `R*DI*I` (89); `R*ST*I` (91); `ARCANG` (109); `AREB1` (122); `WRAEA` (135). |
| WRCRC | 45 / 4 | Writes a **circle** element: reads centre/radius, takes `ABS`, calls `R*ST*I`, packs the `*GFGEL*` fields (GAL/1, GAL/2, GAL/3, GAL/4, GAL/5) and emits with `STRMOD`. | `ABS`, `R*ST*I`, `STRMOD` | `13,VJM,ABS` (39); `R*ST*I` (41); `STRMOD` (77); `,TEXT, 8HDK0` (97); `,LOG,4354400000000000` (98). |
| WRELP | 51 / 5 | Writes an **ellipse** element: same shape as WRCRC but fills seven GAL fields (semi-axes and centre) before `STRMOD`. | `ABS`, `R*ST*I`, `STRMOD` | `13,VJM,ABS` (41); `R*ST*I` (43); field stores 45-83; `STRMOD` (86); `,TEXT, 8HDK0` (109). |
| WRMVA | 32 / 0 | Vector/marker element from an **angle**: multiplies a scale by `COS`/`SIN` of the angle and passes the resulting dx/dy to `WRMVE`. | `COS`, `SIN`, `WRMVE` | `13,VJM,COS` (35); `SIN` (42); `13,VJM,WRMVE` (51); `GAK/7 = *GFGEL*+27` (19). |
| WRMVB | 24 / 0 | Vector element from **coordinate deltas**: adds current-point offsets to form two endpoint coordinates and calls `WRMVE`. | `WRMVE` | parameter adds 19-33; `13,VJM,WRMVE` (36). |
| WRMVC | 42 / 0 | Vector element from a **normalised delta**: computes `SQRT(dx²+dy²)`, divides dx/dy by it and calls `WRMVE`. | `SQRT`, `WRMVE` | `13,VJM,SQRT` (42); `7,A*X,3 / 7,A/X,5 / 7,A+X,1` (46-48); `13,VJM,WRMVE` (64). |
| WRMVE | 117 / 4 | The common vector-element writer ("E" = general form): takes `ABS` of a scale, calls `R*ST*I`, then uses `IVEST` (visibility/sign) and several branches to choose the endpoint form, packs the element and calls `STRMOD`. | `ABS`, `R*ST*I`, `IVEST`, `STRMOD` | `13,VJM,ABS` (42); `R*ST*I` (44); `IVEST` (77); `STRMOD` (161); constants `2312571435610604`, `4354400000000000` (182-183). |
| WRSTR | 23 / 2 | Writes a **text string** into the 28-word `*GFGEL*` element: loops over a user word array with `A+X`/`X-A` and `NTR,3`/`NTR,22B`, using `GAK/2 = *GFGEL*-32767` and the count `28` (`INT,28`), then stores the element via an internal routine **[I: no external call visible]**. | none (internal code blocks) | `*GFGEL*:,LC,28 / GAK/2 = *GFGEL*-32767` (13-14); copy loop `7,XTA,2 / ,WTC,*0025B / 1,ATX,-1 / 7,A+X / 7,X-A,1` (19-29); `,INT,1 / ,INT,28` (31-32). |
| STRMOD | 117 / 6 | "Store/modify element": the back-end shared by every WR* module. Tests element flags (`GAK/4`, `GAK/5`, `GAK/6`), calls `ABS`/`SIGN` to fix signs of the scale fields, handles several element-type cases in a 100-instruction decision tree, accumulates a 28-word DATA block, and relocates it to `*GFGEL*`. | `ABS`, `SIGN` (internal) | SUBPs 13-18; `13,VJM,ABS` (24); `13,VJM,SIGN` (46, 61); DATA block and `28,SET,*0125B / 1,,*GFGEL*` (150-175); constants `4050000000000000`, `3550737215211226` (165-170). |
| STAR | 237 / 11 | Draws a **star/asterisk marker**: reads position and size from `*GFBFTR*`, uses `R*DI*I`, `IVEST`, `ABS`, `SIN`/`COS` to compute radial endpoints, repeatedly calls `MOVA`/`MOVE` to draw the rays, and can close the outline with `POLG`. | `POLG`, `MOVE`, `MOVA`, `SIN`, `COS`, `ABS`, `IVEST`, `R*DI*I` | SUBPs 13-20; `13,VJM,IVEST` (47); `SIN`/`COS` (57, 63); `13,VJM,MOVA` (75, 90, 130, 145); two ray loops (63-102, 134-171); `13,VJM,POLG` (222). |
| ZAPIT | 114 / 5 | Russian "записать" = write/record. Updates the 9-word cell common `*GFCELL*` (LC 9) through four internal helpers that decrement counters and multiply by `I*MUI*`; writes the resulting cell record to the output. **[I: exact output medium]** | `I*MUI*` plus four internal helpers | `*GFCELL*:,LC,9` and GAK/2..GAL/1 EQU (13-22); four helper blocks `*0045B`, `*0052B`, `*0056B`, `*0063B` (52-63); `13,VJM,I*MUI*` (40, 76, 96); called from cold start with IR12/IR13 setup (68-115). |

---

## 3. Fitting, interpolation and numerical mathematics

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| SFCFIT | 1626 / 172 | Fortran-compiled **surface fitting** over a rectangular grid: parameters `LX, LY, MX, MY, NU, NV` are read from indirect cells and validated; X/Y arrays are checked for strict monotonicity; then a large nested-loop computation fits the surface. Error messages are printed via `FT*571`/`FT*003`/`FT*002`. | `ABS`, `I*MU*I`, `I*MUI*`, `FT*571`, `FT*003`, `FT*002` | parameter loads `,WTC,*2162B` etc. (20-45); validation jumps (50-72); `13,VJM,I*MU*I` (89, 101); error-call blocks (1390-1420); ISO `6H   LX= 1 OR LESS`, `6H   LY=`, `6H   MX`, `6H   MY`, `6H   X VALUES OUT OF SEQUENCE`, `6H ERROR DETECTED IN ROUTINE SFCFIT` (1703-1765). |
| SMTBVF | 2154 / 117 | Large Fortran **2-D vector-field fitting**: parameters `N, LX, LY` and arrays `X, Y, U, V` are checked (including `LX`, `LY` ≥ `LP0+2` and `X(I)=X(I+1)` / `X(I)>X(I+1)` errors), then a big coefficient computation uses `OPER`. | `FT*571`, `FT*002`, `FT*003`, `OPER`, `I*MUI*` | parameter loads `,WTC,*2411B..*2416B` (19-27); many internal helper calls `*1621B` etc. (96-231); `13,VJM,OPER` (660, 848); ISO `6H('47'N='47',I2)` (2097), `6H('47'LX='47',I3,...LESS LP0+2...)` (2099), `6H('47'U('47',I3...)` / `V(...)` (2210, 2214), Cyrillic `6H  OШИБKA B ПOДПPOГAMME SMTBVF` (2220-2225). |
| SMTONE | 2067 / 145 | Fortran **2-D surface approximation, method "ONE"**: checks `LX ≥ 3`, `LY ≥ 3`, monotone X and Y, `MX,MY ≥ 2`, and `NU = (LX-1)*NX+1`, `NV = (LY-1)*NY+1`; computes the surface coefficients with integer arithmetic and `R*DI*I`. | `FT*571`, `FT*003`, `I*MU*I`, `I*MUI*`, `R*DI*I` | `,WTC,*2402B` etc. (19-45); `13,VJM,I*MU*I` (86, 98); `13,VJM,R*DI*I` (176, 245); ISO `6H** LX LESS 3`, `6H** ERROR DETECTED IN ROUTINE SMTONE`, `6H** X(I) EQUAL X(I+1)`, `6H** NU NOT EQUAL (LX-1)*NX+1` (2067-2159). |
| SMTSIM | 1720 / 142 | Fortran **2-D surface approximation, method "SIM"**: checks `N ≥ 1`, `LX,LY ≥ 3`, monotone X/Y, and that `U(I)`/`V(I)` lie inside `F(X(1),X(LX))` / `F(Y(1),Y(LY))`; then performs the approximation. | `FT*571`, `FT*003`, `I*MUI*`, `I*DI*I` | `,WTC,*2205B` etc. (19-45); `13,VJM,I*DI*I` (148, 218); ISO `6H** N LESS ONE`, `6H** U(I) OUTSIDE OF (X(1),X(LX))`, `6H** V(I) OUTSIDE OF (Y(1),Y(LY))`, `6H** ERROR DETECTED IN ROUTINE SMTSIM` (1720-2008). |
| SMINV | 167 / 1 | **Matrix inversion** (Gauss-Jordan style): nested row/column loops using `I*MU*I` for index arithmetic, division `,A/X,`, accumulation `,A+X,` and pivoting via `ASN,64-7`/`ARX` sign tests; returns the inverted matrix in the working arrays. | `I*MU*I` | `I*MU*I :,SUBP,` (13); `13,VJM,I*MU*I` (26, 46, 70, 107, 132); pivot test `,ASN,64-7 / ,UZA,*0016B` (29-31); division loops (87-90, 123-126). |
| SPLINE | 204 / 11 | Cubic **spline** construction/drawing: calls `TDMP` and `TRIDIG` (tridiagonal matrix preparation and solve) for the spline coefficients, then evaluates/outputs them via Fortran I/O (`FT*571`, `FT*002`, `FT*003`). | `TDMP`, `TRIDIG`, `FT*571`, `FT*003`, `FT*002` | SUBPs 13-17; `13,VJM,TDMP` (34), `13,VJM,TRIDIG` (45); `FT*` calls (115-130); ISO `6H(3X,4H`, `6HIER=,I`, `6H2)` (204-206); constants `4054000000000000`, `4110000000000000`, `4114000000000000`. |
| SPLINT | 104 / 2 | **Spline interpolation / integration**: evaluates a cubic polynomial at successive points in a loop (`7,A*X,4` triple Horner with four coefficient cells), calls `R*DI*I` once to convert an angle, accumulates two sums and writes results into indirect cells. **[I: interpolation vs. integration]** | `R*DI*I` | `13,VJM,R*DI*I` (61); Horner-style `7,A*X,4 / ,A+X,` (35-48); two accumulation loops (27-54, 73-105); many `,WTC,*011xB..*0123B` coefficient cells. |
| SINCL | 221 / 10 | Draws a **smooth curve** through tabulated points: reads points with `IRDB`/`RDB`, computes five-point derivatives (`DERIV5`), fits a cubic (`CUBPOL`), evaluates it repeatedly with `PVAL` in a step loop, scales with `TMF` and emits pen moves with `MOVE`. **[I: exact curve semantics]** | `IRDB`, `TMF`, `MOVE`, `RDB`, `DERIV5`, `CUBPOL`, `PVAL`, `SQRT`, `R*ST*I` | SUBPs 13-21; `13,VJM,IRDB` (26, 37); `13,VJM,TMF` (49, 82); `13,VJM,MOVE` (55, 89); `13,VJM,DERIV5` (100, 116); `13,VJM,CUBPOL` (123); loop terminator `7,X-A,30B / ,UZA,*0153B` (158-159); `13,VJM,PVAL` (166). |
| SECANT | 112 / 4 | Draws a **secant/tangent** construction on a curve: reads a vector with `RDMVA`, uses `IVEST` and `COS`/`SIN` to get a direction, writes a marker with `WRMVA`, computes two intersection points from four `*GFGEL*` fields, writes a label with `WRSTR`, and falls back to `GFFALS`/`RDSTR`. | `RDMVA`, `IVEST`, `COS`, `SIN`, `WRMVA`, `WRSTR`, `RDSTR`, `GFFALS`, `ABS` | SUBPs 13-27; `13,VJM,RDMVA` (42); `13,VJM,IVEST` (55); `COS`/`SIN` (65, 73); `13,VJM,WRMVA` (85); `13,VJM,WRSTR` (74-75); `,TEXT, 8HB*` (114). |
| TRIDIG | 217 / 5 | **Tridiagonal linear-system solver** (the back-end of SPLINE): three forward-elimination loops over indirect coefficient arrays with `,A/X,` and `,A*X,`, then back-substitution; sign tests `ASN,64-7`/`ARX` handle zero pivots. | none (internal code blocks) | two triangular loops (15-54, 74-103) and one (111-154); `7,A*X,15B / ,A/X,` (32-34); pivot tests (45-48); constants `LOG,0 / 1 / 2 / 4050000000000000` (217-221). |
| TDMP | 167 / 6 | **Tridiagonal matrix preparation** for `TRIDIG`: reads coefficient arrays through many WTC/indirect cells, computes recurrence terms (`7,A*X,12B / 7,A/X,14B / 7,A+X,6`), works through three sign cases and stores the prepared arrays. | none (internal code blocks) | parameter setup 17-34; recurrence loop (35-52); three case branches `*0062B`, `*0072B`, `*0077B`, `*0124B`; constants `4050000000000000`, `4110000000000000`, `4114000000000000` (219-223). |
| ZINT | 33 / 0 | Small **interval interpolation** helper: reads three indirect words, forms differences, computes `(a-b)/(c-b)` style ratio and stores the result; used repeatedly by `TDSECT` (calls at 783, 1237, 1395, 1702, 1746). | none | `,WTC,*0040B / ,A-X,` (13-17); `7,A*X,1 / ,A/X,` (20-25); `7,A/X,1 / 7,ATX,3` (31-33). |
| TCALC | 62 / 4 | Computes **tangent/angle parameters** from two points: forms dx/dy (`7,A-X,5`, `7,A-X,6`), squares and sums them, calls `SQRT`, divides by the point count and iterates; used by `THAXES`. | `SQRT` | `13,VJM,SQRT` (52); dx/dy squares (23-32); iterative division loop `7,A/X,7` (49); constants `4050000000000000`, `4110000000000000` (215-216). |

**Notes.** The four SMT*/SFCFIT modules are plainly compiled Fortran: they
share the same error-printing pattern (`FT*571` → `FT*003`/`FT*002` with an ISO
FORMAT string) and validate the same family of parameters. Their names encode
the method: `SFCFIT` surface fit, `SMTBVF` bivariate/vector variant, `SMTONE`
and `SMTSIM` alternatives **[I: expansion of the abbreviations]**. `TDMP` →
`TRIDIG` is the coefficient path called by `SPLINE.mad:34,45`. ZINT is the
small interpolation primitive reused by TDSECT.

---

## 4. Three-dimensional graphics and coordinate transforms

The 3-D group operates on the 34-word homogeneous transform matrix
`*GFMATR*` (LC 34; `GAK/2=+16` translation column, `GAK/3=+32`, `GAK/4=+33`),
the 3-word current point `*GFCRD*`, the 4-word surface description `*GFSUR*`,
the 4-word limits `*GFLIM*` / `*GFLIML*`, and the 23-word view block
`*GFVIEW*`. Matrix helpers `HCUNIT` (identity), `HCMULT` (multiply),
`HCNCRD` (transform coordinates), `HCINV` (invert), `HCROT1` (rotate),
`HCSURF` (surface), `HCIND`, `HCLINE`, `HCPRSP` (perspective) recur.

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| SAVETR | 30 / 2 | "Save transformation": copies the 34-word `*GFMATR*` back into caller cells and stores flags in `*GFTR*`; exact mirror of SETTR. Uses the same EQU offsets (`+16`, `+32`, `+33`, `*GFTR*+1`, `*GFMATR*-32767`). | none | LC/EQU block (13-18); copy loop (19-38); result stores `,UTC,GAK/3 / ,UTC,*GFTR*` (39-45); constants `INT 1 / INT 16` (217-218). |
| SETTR | 30 / 2 | See section 1: loads the 3-D transform matrix into `*GFMATR*` and sets the flag in `*GFTR*`. | none | see section 1. |
| SHEAR | 50 / 3 | Applies a **shear** to the homogeneous matrix: builds an identity with `HCUNIT`, multiplies it by `*GFMATR*` with `HCMULT`, and modifies rows 2/3 via `I*MUI*` (integer multiply) through internal helpers. | `HCUNIT`, `HCMULT`, `I*MUI*` | SUBPs 13-17; `13,VJM,HCUNIT` (25); `13,VJM,HCMULT` (33); helpers `*0024B`/`*0031B` (37-63); `14,VJM,I*MUI*` (52). |
| SHIFT | 22 / 2 | Thin **translation** wrapper: calls `ATRAN2` with a zero vector and the constant `1.0` (`LOG,4050000000000000`) plus two indirect offset cells, i.e. shifts the current affine transform. | `ATRAN2` | `ATRAN2 :,SUBP,` (13); `13,VJM,ATRAN2` (30); `,LOG,0 / ,LOG,4050000000000000` (47-48). |
| TDTRAN | 27 / 1 | **3-D translation**: forms identity with `HCUNIT`, writes three translation components into matrix columns `GAK/2+3`, `+7`, `+11`, then composes with `HCMULT`. | `HCUNIT`, `HCMULT` | EQU offsets (13-18); `13,VJM,HCUNIT` (24); stores `*0030B..*0032B` (26-31); `13,VJM,HCMULT` (36). |
| TDSCAL | 50 / 5 | **3-D scaling**: optionally divides a parameter by `*GFMATR*` word, forms identity, packs a scale factor with `I*MUI*` into the matrix diagonal via helper `*0031B`, and composes with `HCMULT`. | `HCUNIT`, `HCMULT`, `I*MUI*` | `13,VJM,HCUNIT` (22); `13,VJM,HCMULT` (28); helper with `14,VJM,I*MUI*` (44-50); constants `LOG,4050000000000000`. |
| TDROT | 130 / 13 | **3-D rotation** by an integer/number of degrees: takes ABS of the angle, converts degrees to radians with `I*MUI*` and `5/6`-type constants, computes `COS`/`SIN`, builds the rotation matrix through two internal helpers (`*0073B`, `*0104B`) and composes with `HCMULT`. | `IABS`, `COS`, `SIN`, `HCUNIT`, `HCMULT`, `I*MUI*` | SUBPs 13-21; `13,VJM,IABS` (32); `COS` (49), `SIN` (80); helpers `13,VJM,*0073B` (53), `*0104B` (90); `13,VJM,HCMULT` (95); constants `4114441766517106`, `4413200000000000` (206-207). |
| TDLIM | 256 / 5 | 3-D **limit clipping** with integer arithmetic: reads `*GFCRD*`/`*GFLIM*`, clamps X/Y/Z against limits via `AMIN1`/`AMAX1`, calls `LIMITS` and `HCNCRD`, and maintains three counters with `I*MUI*`. | `LIMITS`, `HCNCRD`, `AMAX1`, `AMIN1`, `IABS`, `I*MUI*` | SUBPs 13-22; coordinate setup 23-42; `13,VJM,HCNCRD` (55); limit calls (80-100); `13,VJM,LIMITS` (150); `13,VJM,I*MUI*` (115, 224). |
| TDLIML | 150 / 3 | Simpler variant of TDLIM (no `I*MUI*`), clipping a single **line** against `*GFLIML*`: `HCNCRD` transform, AMAX/AMIN clamps, `LIMITS`, and a computed ratio `3 / 4` stored to `*0167B`. | `LIMITS`, `HCNCRD`, `AMAX1`, `AMIN1`, `IABS` | SUBPs 13-20; `13,VJM,HCNCRD` (36); limit clamps (70-95); `13,VJM,LIMITS` (119); `7,A/X,4 / ,WTC,*0167B` (159-160). |
| TDLINE | 62 / 3 | Draws a 3-D **line** between two points: transforms both endpoints with `HCNCRD`, applies `TMF` scaling, emits pen moves with `MOVE`, and loops until an endpoint counter expires. | `HCNCRD`, `TMF`, `MOVE` | SUBPs 13-15; `13,VJM,HCNCRD` (28, 53); `13,VJM,TMF` (36, 61); `13,VJM,MOVE` (42, 67); loop end `,WTC,*0074B / ,X-A, / ,UZA,*0022B` (69-71). |
| TDSECT | 1715 / 13 | Draws a 3-D **section/cross-section** of a surface: checks parameters with `IABS`, transforms points with `HCNCRD`, interpolates with `ZINT` (5 call sites), clips with `ABS`, maintains indices via `I*MU*I`, and emits output with `R*ST*I`/`HCLINE`. | `IABS`, `HCNCRD`, `ZINT`, `ABS`, `HCLINE`, `I*MU*I`, `R*ST*I` | SUBPs 13-25; `13,VJM,ZINT` (783, 1237, 1395, 1702, 1746); `13,VJM,HCLINE` (947); `13,VJM,R*ST*I` (1571); constants `4010000000000000`, `4050000000000000`, `4110000000000000` (1801-1803). |
| THAXES | 451 / 23 | Draws the **three-dimensional axes** with ticks and labels: reads axis parameters with `IRDB`/`RDB`, formats tick labels through `SIGNA` and `TPF`, computes tick spacing with `AMOD`/`AMIN1`/`AMAX1`, draws tick circles with `CIRCLE` and positions with `MOVE`, and numbers points with `NUMBER`. | `IRDB`, `RDB`, `SIGNA`, `TPF`, `AMOD`, `AMIN1`, `AMAX1`, `ABS`, `CIRCLE`, `MOVE`, `NUMBER`, `R*DI*I`, `R*PO*I` | SUBPs 13-26; `13,VJM,SIGNA` (99); two `13,VJM,TPF` (107, 136); `13,VJM,CIRCLE` (165, 307); constants and strings `,TEXT, 8HB*`, `,TEXT, 8HCK0` (469, 474). |
| THREED | 774 / 13 | **Three-dimensional surface plotting** with hidden-line removal: reads `*GFMATR*`, `*GFCRD*`, `*GFSUR*`, `*GFLIM*`, `*GFVIEW*`; computes grid indices with `IABS`/`MAX0`/`ISIGN`, transforms with `HCNCRD`/`HCSURF`, tests visibility with `HCIND`, and emits visible strokes via `R*ST*I`/`I*MU*I`. | `IABS`, `MAX0`, `ISIGN`, `SIN`, `HCNCRD`, `SQRT`, `HCSURF`, `HCIND`, `R*ST*I`, `I*MU*I` | SUBPs 13-45; `13,VJM,HCSURF` (442, 948); `13,VJM,HCIND` (559, 678, 819); `13,VJM,R*ST*I` (561, 680, 821); strings `,TEXT, 8HAJ` (1007); constants `4413200000000000`, `4050000000000000`, `4114441765762130` (1006-1008). |
| VIEW | 61 / 1 | Computes the **perspective viewing matrix**: takes rotation/scale words from `*GFMATR*`/`*GFVIEW*`, inverts and rotates a vector with `HCINV`/`HCROT1`, normalises it with `SQRT`, applies `HCPRSP` (perspective), and stores the result back into `*GFMATR*` word 32. | `HCINV`, `HCROT1`, `SQRT`, `HCPRSP` | SUBPs 13-16; `13,VJM,HCINV` (42); `HCROT1` (48); `SQRT` (63); `HCPRSP` (65); `,UTC,GAK/2 / ,ATX,` final store (66-68). |

---

## 5. Axes, scales, labels and polar helpers

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| XAXIS | 755 / 33 | Draws the **linear X axis**: reads axis parameters with `IRDB`/`RDB`, computes the tick step with `ASTEP`, scales with `TMF`, positions with `MOVE`, formats and draws labels with `BCD`/`IBCD`/`SYMBOL` and `R*PO*I`/`R*DI*I`, and writes element data with `R*ST*I`; handles a `*10` exponent notation. | `IRDB`, `RDB`, `IABS`, `R*PO*I`, `MAX0`, `ASTEP`, `AINT`, `ABS`, `TMF`, `MOVE`, `R*DI*I`, `AMIN1`, `AMOD`, `BCD`, `IBCD`, `SYMBOL`, `R*ST*I`, `I*DI*I` | SUBPs 13-30; `13,VJM,IRDB` (35, 45, 94); `13,VJM,ASTEP` (163); `13,VJM,TMF` (244); `13,VJM,MOVE` (251, 347, 357, 364, 385, 392); ISO `6H *10` (1005); `,TEXT, 8HB*` (1002). |
| YAXIS | 755 / 32 | Same as XAXIS for the **Y axis** (near-identical code, 1 fewer constant). | same set as XAXIS | SUBPs 13-30; `13,VJM,IRDB` (35, 45, 94); `13,VJM,ASTEP` (163); `13,VJM,MOVE` (251, 347, ...); `13,VJM,R*ST*I` (487). |
| XLGAX | 531 / 37 | Draws a **logarithmic X axis**: reads parameters via `IRDB`/`RDB`, sets decade boundaries with `TMLGF` and `ALOG10`, uses `SIGN`/`AMIN1`/`AMOD`/`ABS` to place minor ticks, and labels decades with `SYMBOL`/`NUMBER` and `MOVE`. | `IRDB`, `RDB`, `IABS`, `TMLGF`, `I*MU*I`, `ALOG10`, `SIGN`, `AMIN1`, `AMOD`, `ABS`, `R*PO*R`, `SYMBOL`, `NUMBER`, `MOVE`, `R*DI*I`, `I*PO*I` | SUBPs 13-28; `13,VJM,TMLGF` (79); `13,VJM,ALOG10` (129, 133); `13,VJM,SYMBOL` (331, 362); `13,VJM,NUMBER` (382); `13,VJM,MOVE` (393, 441, 534). |
| YLGAX | 536 / 41 | Same as XLGAX for the **Y axis**. | same set as XLGAX | SUBPs 13-28; `13,VJM,TMLGF` (80); `13,VJM,ALOG10` (130, 134); `13,VJM,SYMBOL` (336, 367); `13,VJM,NUMBER` (384); `13,VJM,MOVE` (395, 443). |
| XPOL | 16 / 0 | Polar→Cartesian X helper: calls `COS`, multiplies by a radius from an indirect cell (`WTC,*0020B`), stores into `*0017B` and returns the value (also copies it to `*0016B`). | `COS` | `13,VJM,COS` (19); `,WTC,*0017B / ,A*X,` (20-21); `,UTC,*0016B / ,XTS,` (31-32). |
| YPOL | 16 / 0 | Polar→Cartesian Y helper, identical structure with `SIN`. Used by `SUPLIN.mad:46,52`. | `SIN` | `13,VJM,SIN` (19); `,WTC,*0017B / ,A*X,` (20-21); `,UTC,*0016B / ,XTS,` (31-32). |
| SIGNA | 237 / 17 | Generates axis **tick-label signatures**: reads parameters with `RDB`, computes a "nice" step with `ASTEP`, determines the decimal exponent with `ALOG10`/`R*PO*I`, formats numbers with `FLOAT`/`NUMBER`/`SYMBOL`, applies `SIGN`/`IABS` and `I*MU*I`, and emits the label strings; constants include `*10`, `CK0`, `B*`. | `ASTEP`, `RDB`, `SIGN`, `IABS`, `I*MU*I`, `R*DI*I`, `R*PO*I`, `ABS`, `ALOG10`, `AMAX1`, `FLOAT`, `SYMBOL`, `NUMBER` | SUBPs 13-28; `13,VJM,ASTEP` (45); `13,VJM,ALOG10` (96); ISO `6H*10    ` (255), `6HCK0`, `,TEXT, 8HB*` (252). |
| SYMTAB | 25 / 725 | **Symbol/glyph lookup table**: a short search routine over a huge 725-word read-only constant table. Saves IR9–IR12, bounds-checks an index against cells `745B/746B`, uses `ASN,64-8`/`ASN,64+40` to extract packed fields and returns the table word. The table contains many `LOG` glyph words and ISO/TEXT fragments (e.g. `6H2ED`, `6H8GE47'47'`, `6HHG6EC2`, `6H104`). **[I: exact symbol class]** | none (internal table) | entry `8,VTM,*0000B` (13); `,STI,12 / ,STI,9 / ,STI,10 / ,STI,11` (17-20); bounds tests `8,A-X,745B / 8,UZA,16B` and `746B` (37-46); 725 constants (60-757). |
| SIZLIN | 22 / 1 | Copies the four words of the **linear-size common** `*GFLMN*` (LC 4) into four indirect output cells (`*0023B..*0025B` and the accumulator), default constant `999`. | none | `*GFLMN*:,LC,4` and GAK/2..GAK/4 EQU (13-16); `,UTC,*GFLMN*` / `,UTC,GAK/2` / `,UTC,GAK/3` / `,UTC,GAK/4` (20-30); `,INT,999` (217). |
| SIZNUM | 25 / 1 | Copies the **numeric-label size** common: `*GFLMN*` (4 words) plus `*GFLSZ*` (LC 1) into four output cells; default constant `333`. | none | LC/EQU block (13-19); `,UTC,*GFLSZ*` (25); `,UTC,GAK/2..4` (28-35); `,INT,333` (217). |
| TMLGF | 135 / 7 | Formats a **logarithmic tick label**: uses `RDB` to read parameters, `ALOG10`, `I*PO*I`, `I*MU*I`, `AMIN1`/`AMAX1` to find a decade exponent and normalise the mantissa, iterating until a bound is reached. Called by XLGAX/YLGAX. | `ALOG10`, `AMIN1`, `AMAX1`, `RDB`, `I*PO*I`, `I*MU*I` | SUBPs 13-18; `13,VJM,RDB` (28, 39); `13,VJM,AMAX1` (34); `13,VJM,ALOG10` (70, 72, 75); loop terminator `7,X-A,2 / ,UZA,*0005B` (140-141). |
| TPF | 177 / 12 | Computes **tick parameters / polar tick positions** for THAXES: reads integer and real parameters with `IRDB`/`RDB`, normalises angles with `AMOD`, clamps with `AMIN1`/`AMAX1`, and computes two coordinates with `COS`/`SIN`; constants include `TEXT 8HDK0`. | `IRDB`, `RDB`, `IABS`, `AMOD`, `AMIN1`, `AMAX1`, `COS`, `SIN` | SUBPs 13-20; `13,VJM,IRDB` (24, 30); `13,VJM,AMOD` (92, 128); `13,VJM,COS` (177), `SIN` (184); `,TEXT, 8HDK0` (206). |
| TMF | 53 / 10 | **Transform-from-file**: reads four words with `RDB`, forms dx/dy differences, divides them (scale ratio), reads two more words and computes two offsets. Used by XAXIS/YAXIS/TDLINE/SINCL to convert data coordinates to plot coordinates. | `RDB` (8 calls) | `RDB :,SUBP,` (13); `13,VJM,RDB` (26, 32, 40, 51, 56, 62, 66, 72); `7,A/X,11B` (40); constants `INT 7..14` (195-202). |
| TFM | 57 / 10 | Mirror of TMF with **floating-point formatting**: same RDB reads and dx/dy division, but calls `ABS` and `FLOAT` to produce real-valued scale factors for two axes. | `ABS`, `FLOAT`, `RDB` | SUBPs 13-15; `13,VJM,RDB` (22, 30, 49, 57); `13,VJM,FLOAT` (44, 70); `13,VJM,ABS` (26, 52). |

---

## 6. Curves, clipping, shading and other drawing utilities

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| SDPG | 363 / 11 | Draws a **shaded/segmented polygon or surface patch** from two points: reads them with `RDB`, computes an angle step with `SIN`/`COS`, clamps intersections with `AMIN1`/`AMAX1`, computes a ratio with `R*ST*I`, and emits two pen moves per iteration; loops over a counter. **[I: exact primitive]** | `RDB`, `SIN`, `COS`, `AMIN1`, `AMAX1`, `R*ST*I`, `MOVE` | SUBPs 13-19; `13,VJM,RDB` (25, 30); `SIN`/`COS` (35, 39); `AMIN1`/`AMAX1` (100, 108); two `13,VJM,MOVE` (330, 344); constants `4413200000000000`, `3012370553043433`. |
| SEARCH | 446 / 5 | **Line-clipping search**: uses `*GFL*` (8-word line common) and `*GFXY*` (5-word point common), interpolates endpoints with `FLOAT`/`RDB`, finds window intersections with `INTRSC` (three variant call sites), flushes the visible portion with `BUFL`, and positions the pen with `MOVE`. | `FLOAT`, `RDB`, `INTRSC`, `BUFL`, `MOVE` | SUBPs 13-21; `13,VJM,FLOAT` (26); `13,VJM,RDB` (33); `13,VJM,INTRSC` (158, 184, 196); `13,VJM,BUFL` (226); `13,VJM,MOVE` (252, 264, 274, 288). |
| SHADE | 1640 / 15 | **Hatched shading / area fill**: `*GFSHAD*` is a 1000-word common (five 200-word arrays at +0/+200/+400/+600/+800). Reads four corners with `RDB`, transforms them with `TFM`, computes the edge angle with `ABS`/`SIN`/`COS`, takes `SQRT` of a normal, and sweeps thousands of scan lines with integer `I*DI*I`/`I*MU*I`, emitting strokes with `LINEO`; fatal path calls `STOP*`. | `RDB`, `TFM`, `ABS`, `SIN`, `COS`, `SQRT`, `I*DI*I`, `I*MU*I`, `R*ST*I`, `LINEO`, `STOP*` | SUBPs 13-29; `13,VJM,TFM` (72, 81); `SIN` (110), `COS` (114), `SQRT` (129); `13,VJM,LINEO` (1068); `13,VJM,STOP*` (1775); common `,LC,1000` (13). |
| SUPLIN | 140 / 3 | Draws **supplementary/parallel lines** in polar coordinates: computes a radius/angle range with `MOD`, converts each step with `XPOL`/`YPOL`, and chooses one of three line primitives `LINEMC`, `LINEMO`, `BRLINE` from sign tests on two parameters. | `MOD`, `XPOL`, `YPOL`, `LINEMC`, `LINEMO`, `BRLINE` | SUBPs 13-18; `13,VJM,MOD` (31); `13,VJM,XPOL` (52), `YPOL` (60); `13,VJM,LINEMC` (93), `LINEMO` (128), `BRLINE` (143). |
| SPIRAL | 30 / 1 | Thin **spiral** wrapper: reads a start radius/angle and six parameters via WTC indirect cells and calls `CIRCLE` with them, i.e. a circle drawn with a monotonically changing radius **[I]**. | `CIRCLE` | `CIRCLE :,SUBP,` (15); `13,VJM,CIRCLE` (59); WTC/parameter setup (29-55). |

---

## 7. Alphabetical master table (all 71 modules)

| Module | Size (cmds/const) | Purpose | Key calls | Evidence |
|---|---|---|---|---|
| SAVETR | 30 / 2 | Save 3-D transform matrix `*GFMATR*` and flags to caller cells (inverse of SETTR) | internal | `SAVETR.mad:13-70`, `,UTC,GAK/3` (39) |
| SDPG | 363 / 11 | Shaded/segmented patch drawing from two points with angle stepping | RDB, SIN, COS, AMIN1, AMAX1, R*ST*I, MOVE | `SDPG.mad:13-507`, calls 25-39, 330, 344 |
| SEARCH | 446 / 5 | Line/window clipping search: intersect, flush via BUFL, move pen | FLOAT, RDB, INTRSC, BUFL, MOVE | `SEARCH.mad:13-610`, INTRSC 158/184/196, BUFL 226 |
| SECANT | 112 / 4 | Draw secant/tangent marker and label on a curve | RDMVA, IVEST, WRMVA, WRSTR, RDSTR, GFFALS | `SECANT.mad:13-185`, calls 42-85, TEXT B* 114 |
| SETEND | 55 / 12 | Finalise catalog end record via RZONE; error "НЕТ ТАКОЙ ЗАПИСИ" + *74 STOP | RZONE, PRINT8, *74 | `SETEND.mad:13-111`, calls 81/89/100, ISO 102-104 |
| SETIND | 32 / 2 | Set/pack an index-table descriptor entry (bit masks) | internal | `SETIND.mad:13-65`, ASN masks 32-36, LOG 63-64 |
| SETK | 32 / 0 | Main catalog open chain GDISC→RCATAL→SETEND→WCATAL→FDISC | GDISC, RCATAL, SETEND, WCATAL, FDISC | `SETK.mad:13-71`, calls 23/27/40/44/48 |
| SETREF | 45 / 6 | Set/patch a reference-table entry (masks 100000, 77777) | internal | `SETREF.mad:13-89`, V1M 28, LOG 83-88 |
| SETTR | 30 / 2 | Load 3-D transform matrix into `*GFMATR*`, set `*GFTR*` flag | internal | `SETTR.mad:13-70`, loop 21-31 |
| SETWGR | 7 / 2 | Set writer-group descriptor field indexed by IR9 | internal | `SETWGR.mad:13-27`, XTA/STX 16-21, LOG 25-26 |
| SETZON | 4 / 0 | Copy/extract zone-descriptor field to `mem[IR10+5]` | internal | `SETZON.mad:13-19` (whole body) |
| SFCFIT | 1626 / 172 | Fortran surface fitting over X/Y grid (LX,LY,MX,MY,NU,NV) | FT*, I*MU*I, ABS | `SFCFIT.mad:13-1860`, ISO 1703-1765 |
| SHADE | 1640 / 15 | Hatched shading of a 3-D patch (`*GFSHAD*` 1000 words) | RDB, TFM, SIN, COS, SQRT, LINEO, STOP* | `SHADE.mad:13-1861`, LINEO 1068, STOP* 1775 |
| SHEAR | 50 / 3 | Apply shear to homogeneous transform matrix | HCUNIT, HCMULT, I*MUI* | `SHEAR.mad:13-99`, calls 25/33/52 |
| SHIFT | 22 / 2 | Translate current affine transform by (0,1) via ATRAN2 | ATRAN2 | `SHIFT.mad:13-51`, call 30 |
| SIGNA | 237 / 17 | Generate axis tick-label signatures ("*10" exponent) | ASTEP, ALOG10, NUMBER, SYMBOL, FLOAT | `SIGNA.mad:13-377`, ASTEP 45, ALOG10 96 |
| SINCL | 221 / 10 | Draw smooth cubic curve through tabulated points | IRDB, TMF, MOVE, DERIV5, CUBPOL, PVAL, SQRT | `SINCL.mad:13-320`, DERIV5 100, CUBPOL 123 |
| SIZLIN | 22 / 1 | Copy `*GFLMN*` linear-size words to outputs (default 999) | internal | `SIZLIN.mad:13-57`, UTC 20-30 |
| SIZNUM | 25 / 1 | Copy `*GFLMN*`+`*GFLSZ*` numeric-label sizes (default 333) | internal | `SIZNUM.mad:13-64`, UTC 25-35 |
| SMINV | 167 / 1 | Matrix inversion by Gauss-Jordan elimination | I*MU*I | `SMINV.mad:13-253`, calls 26/46/70/107/132 |
| SMTBVF | 2154 / 117 | Fortran 2-D vector-field fitting (N,LX,LY,X,Y,U,V) | FT*, OPER, I*MUI* | `SMTBVF.mad:13-2217`, ISO 2097-2225 |
| SMTONE | 2067 / 145 | Fortran 2-D surface fit method ONE (LX,LY,MX,MY,NU,NV) | FT*, I*MU*I, R*DI*I | `SMTONE.mad:13-2150`, ISO 2067-2159 |
| SMTSIM | 1720 / 142 | Fortran 2-D surface fit method SIM (N,LX,LY,U,V bounds) | FT*, I*MUI*, I*DI*I | `SMTSIM.mad:13-1945`, ISO 1720-2008 |
| SPIRAL | 30 / 1 | Spiral/circle drawing wrapper | CIRCLE | `SPIRAL.mad:13-68`, call 59 |
| SPLINE | 204 / 11 | Cubic spline construction via tridiagonal solve + Fortran output | TDMP, TRIDIG, FT* | `SPLINE.mad:13-295`, calls 34/45 |
| SPLINT | 104 / 2 | Cubic spline interpolation/evaluation loop | R*DI*I | `SPLINT.mad:13-161`, call 61, Horner 35-48 |
| STAR | 237 / 11 | Star/asterisk marker via radial MOVA/MOVA and POLG | POLG, MOVE, MOVA, SIN, COS, IVEST | `STAR.mad:13-337`, MOVA 75/90, POLG 222 |
| STRMOD | 117 / 6 | Store/modify 28-word graphic element into output | ABS, SIGN | `STRMOD.mad:13-176`, 28,SET 174 |
| SUPLIN | 140 / 3 | Supplementary lines in polar coordinates | MOD, XPOL, YPOL, LINEMC/MO, BRLINE | `SUPLIN.mad:13-217`, calls 31-143 |
| SYMTAB | 25 / 725 | Symbol/glyph lookup in 725-word constant table | internal | `SYMTAB.mad:13-521`, bounds 37-46 |
| TCALC | 62 / 4 | Tangent/angle parameters from two points | SQRT | `TCALC.mad:13-117`, call 52 |
| TDLIM | 256 / 5 | 3-D line clipping against limits with integer arithmetic | LIMITS, HCNCRD, AMIN1/AMAX1, I*MUI* | `TDLIM.mad:13-368`, LIMITS 150, ZINT n/a |
| TDLIML | 150 / 3 | Simpler 3-D line limit clipping (no I*MUI*) | LIMITS, HCNCRD, AMIN1/AMAX1 | `TDLIML.mad:13-231`, LIMITS 119 |
| TDLINE | 62 / 3 | Draw 3-D line between two transformed points | HCNCRD, TMF, MOVE | `TDLINE.mad:13-122`, MOVE 42/67 |
| TDMP | 167 / 6 | Tridiagonal matrix preparation for TRIDIG | internal | `TDMP.mad:13-261`, recurrence 35-52 |
| TDROT | 130 / 13 | 3-D rotation by degrees around an axis | IABS, COS, SIN, HCUNIT, HCMULT, I*MUI* | `TDROT.mad:13-200`, HCSURF n/a, HCMULT 95 |
| TDSCAL | 50 / 5 | 3-D scaling of homogeneous matrix | HCUNIT, HCMULT, I*MUI* | `TDSCAL.mad:13-101`, calls 22/28/44 |
| TDSECT | 1715 / 13 | Draw 3-D surface section with interpolation | IABS, HCNCRD, ZINT, HCLINE, R*ST*I | `TDSECT.mad:13-1854`, ZINT 783/1237/1395/1702/1746 |
| TDTRAN | 27 / 1 | 3-D translation of homogeneous matrix | HCUNIT, HCMULT | `TDTRAN.mad:13-70`, calls 24/36 |
| TFM | 57 / 10 | Real-valued transform-from-file scale factors | ABS, FLOAT, RDB | `TFM.mad:13-117`, FLOAT 44/70 |
| THAXES | 451 / 23 | Draw 3-D axes with ticks and labels | SIGNA, TPF, CIRCLE, MOVE, NUMBER | `THAXES.mad:13-656`, SIGNA 99, TPF 107/136 |
| THREED | 774 / 13 | 3-D surface plotting with hidden-line removal | HCNCRD, HCSURF, HCIND, R*ST*I, I*MU*I | `THREED.mad:13-1041`, HCSURF 442/948, HCIND 559 |
| TMF | 53 / 10 | Transform-from-file coordinate conversion (integer) | RDB | `TMF.mad:13-109`, 8 RDB calls |
| TMLGF | 135 / 7 | Logarithmic tick-label formatting | ALOG10, TMLGF self, RDB, I*PO*I, I*MU*I | `TMLGF.mad:13-207`, ALOG10 70/72/75 |
| TPF | 177 / 12 | Tick/polar parameters for THAXES | IRDB, RDB, AMOD, COS, SIN | `TPF.mad:13-279`, AMOD 92/128, SIN/COS 177/184 |
| TRIDIG | 217 / 5 | Tridiagonal linear-system solver for spline | internal | `TRIDIG.mad:13-310`, loops 15-154 |
| VIEW | 61 / 1 | Compute perspective viewing matrix | HCINV, HCROT1, HCPRSP, SQRT | `VIEW.mad:13-127`, calls 42-65 |
| WCATWO | 160 / 13 | Write catalog entry v2 (ISO name, RZONE/WZON/CLEAZN) | ISO*TEX*, RZONE, WZON, CLEAZN | `WCATWO.mad:13-241`, calls 77/188/200/203 |
| WHERE | 24 / 2 | Current position in file A (`*GFAFTR*`) | RDB ×2 | `WHERE.mad:13-61`, RDB 28/32 |
| WHERP | 24 / 2 | Current position in file B (`*GFBFTR*`) | RDB ×2 | `WHERP.mad:13-61`, RDB 28/32 |
| WRACA | 70 / 4 | Write circular arc element (variant A) | ABS, SIN, COS, R*ST*I, STRMOD | `WRACA.mad:13-142`, calls 50-112 |
| WRACB | 36 / 0 | Write circular arc variant B via ARCANG | ARCANG, WRACA | `WRACB.mad:13-83`, calls 47/55 |
| WRACC | 51 / 0 | Write circular arc variant C via ARCC1 | ARCC1, ARCANG, WRACA | `WRACC.mad:13-109`, calls 53/68/77 |
| WRACD | 73 / 3 | Write circular arc variant D via SQRT/ANGLER | SQRT, ANGLER, ABS, R*ST*I, STRMOD | `WRACD.mad:13-147`, calls 56-117 |
| WRAEA | 122 / 4 | Write elliptic arc variant A | SIN, COS, SQRT, R*ST*I, STRMOD | `WRAEA.mad:13-198`, calls 68-164 |
| WRAEB | 105 / 3 | Write elliptic arc variant B via ARCANG/AREB1 | ARCANG, AREB1, WRAEA | `WRAEB.mad:13-174`, calls 109/122/135 |
| WRCRC | 45 / 4 | Write circle element (`DK0`) | ABS, R*ST*I, STRMOD | `WRCRC.mad:13-102`, TEXT 97 |
| WRELP | 51 / 5 | Write ellipse element (`DK0`) | ABS, R*ST*I, STRMOD | `WRELP.mad:13-116`, TEXT 109 |
| WRMVA | 32 / 0 | Write vector element from angle via COS/SIN | COS, SIN, WRMVE | `WRMVA.mad:13-74`, calls 35/42/51 |
| WRMVB | 24 / 0 | Write vector element from coordinate deltas | WRMVE | `WRMVB.mad:13-58`, call 36 |
| WRMVC | 42 / 0 | Write vector element from normalised delta | SQRT, WRMVE | `WRMVC.mad:13-88`, calls 42/64 |
| WRMVE | 117 / 4 | General vector-element writer (visibility, STRMOD) | ABS, R*ST*I, IVEST, STRMOD | `WRMVE.mad:13-189`, IVEST 77, STRMOD 161 |
| WRSTR | 23 / 2 | Write text string into `*GFGEL*` element (28 words) | internal | `WRSTR.mad:13-55`, copy loop 19-29 |
| XAXIS | 755 / 33 | Draw linear X axis with ticks/labels | ASTEP, TMF, MOVE, BCD, SYMBOL, R*ST*I | `XAXIS.mad:13-986`, ASTEP 163, ISO " *10" 1005 |
| XLGAX | 531 / 37 | Draw logarithmic X axis | TMLGF, ALOG10, SIGN, SYMBOL, NUMBER, MOVE | `XLGAX.mad:13-728`, TMLGF 79, SYMBOL 331 |
| XPOL | 16 / 0 | Polar→Cartesian X = R·COS(φ) | COS | `XPOL.mad:13-44`, call 19 |
| YAXIS | 755 / 32 | Draw linear Y axis with ticks/labels | ASTEP, TMF, MOVE, BCD, SYMBOL, R*ST*I | `YAXIS.mad:13-984`, ASTEP 163, R*ST*I 487 |
| YLGAX | 536 / 41 | Draw logarithmic Y axis | TMLGF, ALOG10, SIGN, SYMBOL, NUMBER, MOVE | `YLGAX.mad:13-740`, TMLGF 80, SYMBOL 336 |
| YPOL | 16 / 0 | Polar→Cartesian Y = R·SIN(φ) | SIN | `YPOL.mad:13-44`, call 19 |
| ZAPIT | 114 / 5 | Write/record the 9-word `*GFCELL*` cell | I*MUI* | `ZAPIT.mad:13-171`, LC9 13, I*MUI* 40/76/96 |
| ZINT | 33 / 0 | Interval interpolation helper used by TDSECT | internal | `ZINT.mad:13-73`, ratio 20-25 |

---

## 8. Summary of inferences

1. **[I]** The catalog/disk group (`SETK`, `SETEND`, `SETIND`, `SETREF`,
   `SETWGR`, `SETZON`, `WCATWO`, `WHERE`, `WHERP`, together with `RCATAL`,
   `RZON`, `E70`, `*70`, `GDISC`, `FDISC` from the adjacent audit) is a
   functional match for the OVERLAY* worker's FIND0/COPY/PROC steps, but no
   direct call edge from OVERLAY* to library 22 is present in the disassembly.
2. **[I]** The expansions of SMTBVF/SMTONE/SMTSIM/SFCFIT method names and the
   exact mathematical scheme inside these compiled Fortran routines are
   inferred from their validation messages and loop structure.
3. **[I]** SETWGR/SETIND/SETREF/SETZON operate on GRAFOR descriptor arrays;
   the precise table they patch is not named in the listings.
4. **[I]** WRSTR writes a string element without a named external call; it is
   grouped with the WR* family because it uses `*GFGEL*` and `INT,28`.
5. **[I]** STAR, SDPG, SINCL, SPLINT, SPIRAL and SYMTAB purposes are inferred
   from their call graphs and common blocks, not from source comments.
6. Confirmed directly by the listings: every call edge listed in the tables,
   all GRAFOR common-block symbols and EQU offsets, the ISO/TEXT error and
   format strings, the `*50`/`*72`/`*74` extops, and all command/constant/BSS
   counts.
