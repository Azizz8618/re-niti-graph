# OVERLAY-HINT: does library 22 contain routines the OVERLAY* worker would call?

Question from the parent session: the OVERLAY* worker was seen failing on an
э70 exchange before LU 060 was mounted; the link map printed REDAKT and Pascal
runtime names. Does library 22 (ГРАФОР-СУД) hold the actual routine handling
that exchange, and if so which module?

All statements are tagged **[OBSERVED]** (directly in the files) or
**[INFERENCE]** (reasoning from those observations). No disk image or project
source was modified.

---

## 1. Background: what OVERLAY* does (from project docs)

**[OBSERVED]** `pascal/README/ПЛАН-ОЗУ.md` lines 304-306 describe the
assemble sequence after reading an `*OVERLAY` card:
> "FIND0 (поиск модуля в каталоге по имени), COPY (перенос тела), встраивание
> STLOAD** ... в PROC строится каталог сегментов (TABLE, STCAT*)".

So the named sub-steps are **FIND0** (find module in catalog by name),
**COPY** (move the body), **PROC** (build the segment catalog TABLE/STCAT*),
plus **IO1 / IO3** in the worker's own naming. The same document (lines 321-322)
locates the worker itself on volume 2048, not in library 22:
> "OVERLAY* - зона 0o1457 слово 448 (cmd 218, const 15, sym 59); OVERLAY - зона
> 0o1457 слово 768 ...".

**[OBSERVED]** `ПЛАН-ОЗУ.md` line 284 records a related symptom: the monitor
answers "ОТСУТСТВУЕТ OVERLAY*" / "СВОБОД 03122" - GIVCALL* looks up the name
in a table.

---

## 2. What library 22 actually contains (from the dtran MADLEN)

**[OBSERVED]** The catalog (`extract/catalog.txt`, zone 0o1100) contains the
following disk/graph low-level entries, and 238 of them have disassembled
bodies in `../`:

- The **Э70 path**: `E70` (entry 26, zone 1161/625 word 576) and `*70`
  (entry 25, zone 1161/625 word 608, file `_s70.mad`).
- The **Э50 disk primitives**: `GDISC` (word 832) issues `*50` extops;
  `*70` itself issues `*50,1206B`, `*50,115B`, `*50,116B` and `*72`.
- **Zone/catalog routines**: `RZON`, `RZONE`, `WZON`, `WZONE`, `RCATAL`,
  `WCATAL`, `GIVENZ`, `GIVZON`, `SETREF`, `SETIND`, `GETIND`, `SETK`, `SETEND`,
  `SETZON`, `SETWGR`, `WCATWO`, `CLEAZN`, `COMPDT`, `FOPEN`, `NEXTZN`, `ABUFF`,
  `FCATBD`, `E70`.
- **Second catalog** in zone 0o1163 lists the "нижний уровень графора" names
  `GROPEN, GRWRIT, GRCLOS, GRNOTZ, GRNAME, MDBUFF, RDB/IRDB, WDB/IWDB, PLOT,
  PEN, FRAME, ...` (from `disasm/INDEX.md`).

**[OBSERVED]** Exact call edges (see `IO-MODULES.md` for line numbers):

```
E70    --VJM--> *70            and NEXTZN
RZON   --UJ ---> E70  and *70
GDISC  issues  *50 extops (105B, 115B, 116B)
*70    issues  *50 extops (1206B, 115B, 116B) and *72
RCATAL --UJ ---> RZONE / WZONE  (uses LC 132096)
SETK   --VJM--> GDISC, RCATAL, SETEND, WCATAL, FDISC
GIVZON --VJM--> GDISC, RCATAL, GIVENZ, SETREF, WCATAL, FDISC
NEXTZN --VJM--> GDISC, FDISC
WCATWO --VJM--> RZONE, WZON
SETEND --VJM--> RZONE ; issues *74 (STOP)
```

**[OBSERVED]** An independent SIPROD example, `re-siprod/dis/SKZONA.be`, shows
the same machine mechanism used for a zone read: `Э75 0` then `Э70 SKZONA`
(lines 38-39 of that file), with a comment that the module reads/writes a
1024-word zone. So Э70 is the BESM-6/DISPAK disk-exchange supervisor entry
used for zone I/O.

---

## 3. Answer

**[INFERENCE, high confidence] Yes - library 22 contains the routine that
performs an э70 exchange.** The concrete module is `*70` (`_s70.mad`), with
`E70.mad` as its catalog-facing wrapper. Evidence chain:

1. The required operation is an "э70 exchange". Library 22 has catalog entries
   literally named `E70` and `*70`, and `*70`'s body issues `*50`/`*72` extops
   (the disk I/O instructions) - this is the only module in the library that
   is both named `*70` and contains Э50-class I/O.
2. `RZON` (read zone) transfers to **both** `E70` and `*70`, so zone reads in
   this library go through the Э70 path.
3. `RCATAL`/`SETK`/`GIVZON`/`NEXTZN` build the higher-level catalog and disk
   setup on top of `GDISC`/`FDISC` and the Э70 primitive.

**[INFERENCE] Which of these the OVERLAY* worker would call during
PROC/FIND0/IO1/IO3:** FIND0 is "search module in catalog by name" and COPY
moves a body (ПЛАН-ОЗУ.md). Catalog search plus body copy are exactly the
`RCATAL -> RZONE/RZONE -> E70/*70 -> Э50` path in library 22, so the most
likely library-22 entry points an OVERLAY worker hits are:

- **`RCATAL`** (catalog read) - the natural analogue of FIND0's catalog lookup;
- **`RZON` / `RZONE`** (zone read) - the natural analogue of COPY's body read;
- **`E70` / `*70`** - the actual Э70 exchange that fails before LU 060 is
  mounted;
- **`GDISC` / `FDISC`** - opened/closed by `SETK`/`NEXTZN` around those reads.

**[INFERENCE, important qualification] The link map names REDAKT and Pascal
runtime, and the worker body itself lives at zone 0o1457 on volume 2048, not
in library 22.** Library 22 is the *GRAFOR* library; its `*70` and `GDISC` are
the GRAFOR library's own disk-exchange layer, not the DISPAK monitor's core
Э70 driver. Two readings are possible and the disassembly alone cannot decide
between them:

(a) The worker calls the GRAFOR low-level layer (`E70`/`*70`/`RCATAL`/`RZON`)
    through REDAKT's link map, in which case library 22 does hold the failing
    exchange routine and those modules are the ones to inspect.
(b) The worker uses the OS monitor's own Э70 (as `SKZONA.be` does) and merely
    *loads* library-22 modules; then the failing exchange is in the monitor,
    not in library 22, and library 22 only contains an equivalent but
    unused-by-OVERLAY copy.

**[OBSERVED]** Nothing in the `.mad` files or their name map mentions
`OVERLAY`, `FIND0`, `IO1`, `IO3`, `REDAKT` or `STLOAD`, so no direct call edge
from OVERLAY* to a library-22 module is present in this corpus. The
identification above is by functional match (named Э70 entry + disk I/O
extops + catalog/zone routine chain), not by a resolved cross-reference.

---

## 4. Practical next step (not performed - read-only audit)

To convert reading (a) or (b) into a fact, resolve the external-symbol table
of the OVERLAY* DMS module at zone 0o1457 word 448 (cmd 218, const 15, sym 59)
with `dtran -F dms`, then grep its `SUBP` declarations for `E70`, `*70`,
`GDISC`, `RCATAL`, `RZON`. That is a separate task and was outside this
audit's write scope.
