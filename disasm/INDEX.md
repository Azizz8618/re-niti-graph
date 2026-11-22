# BESM-6 system library 22 (ГРАФОР-СУД) - disassembly index

Source: `/usr/local/share/besm6/2048` (BESM-6 disk image, 6 bytes/word).
Zones: 0o1100..0o1177 (decimal 576..639), 64 zones x 1024 words = 65536 words.

Method (one zone at a time, so each listing has a clean 0-based address map):
```
besmtool dump 2048 --start=<decimal> --length=1 --to-file=zone_<octal>.bin
disbesm6 -a0 -e0 zone_<octal>.bin > disasm/zone_<octal>.txt
besmtool view 2048 --start=<decimal> --encoding=t   # TEXT decode
```
Module names were decoded from 6-byte words as eight 6-bit characters using the
Dubna TEXT alphabet (0=space, 1=dot, 2..15 and 26..32 Cyrillic/punctuation,
16..25 = digits, 33..58 = A..Z, 59..63 = Ш Э Щ Ч Ю). A name word has six
uppercase-alphanumeric characters followed by two blanks.

## Zone summary

| Zone (oct) | Dec | Nonzero/1024 | Const words | Instr lines | Class | Names found: catalog / secondary / other 6-char words (often data) |
|---|---|---|---|---|---|---|
| 1100 | 576 | 514 | 507 | 12 | CATALOG (module directory, 257 entries) ** | COPDCB, SETIND, GETIND, SETREF, AFTZN, WCATWO, CRDUM, SWCAT, GIVENZ, SETWGR, SETEND, SETZON, GDISC, FDISC, ABUFF, RCATAL, WCATAL, RZON, ... (+239) / - / - |
| 1101 | 577 | 0 | 0 | 0 | EMPTY (all 1024 words zero) | - / - / - |
| 1102 | 578 | 184 | 0 | 1941 | CODE | - / - / - |
| 1103 | 579 | 85 | 77 | 1142 | SPARSE / mostly empty | - / - / - |
| 1104 | 580 | 257 | 0 | 1776 | CODE | - / - / - |
| 1105 | 581 | 913 | 910 | 7 | TABLES/DATA (mostly constants) | BCD, SYMTAB, NUMBER, LIMITS / SYMBOL / З6ИBБ0, З7ИЗW, ЛDЯФЯЗ, ДSП, 2ED, ЛCЛ |
| 1106 | 582 | 977 | 909 | 69 | TABLES/DATA (mostly constants) | REGION, BOX, RECT, GRID, CIRCLE, POLYG, SYMTAB, ELIPS, LINEO, WHERE / SYMBOL / БПБДZЗ, БПБФZЗ, IWDBC, IRDBC, AMIN1 |
| 1107 | 583 | 1023 | 1020 | 4 | TABLES/DATA (mostly constants) | LINEMO, MARKER, WHERE, LINEC, LINEMC, TMF, ASTEP / - / БTБЖБ0, БПБZZЗ, БПБЭZЗ, БПБXZЗ, Г7ЗЙZЗ |
| 1110 | 584 | 1023 | 1021 | 2 | TABLES/DATA (mostly constants) | AXES, ASTEP / SYMBOL / ЦДФ7Б0, ЦДЦUБ0, ЦДФЖБ0, ЦДД2Б0 |
| 1111 | 585 | 1020 | 1018 | 3 | TABLES/DATA (mostly constants) | YAXIS, ASTEP, XAXIS, MINMAX, REBLAN, PVAL / SYMBOL / ЦДГHБ0, ЦДГOБ0, БTГЩБ0, ЦДИKБ0, FOЗ3F0, DЙ0 |
| 1112 | 586 | 1022 | 942 | 90 | TABLES/DATA (mostly constants) | INCLIN, MARKER, WHERE, RAND, TFM, RENTCH, GFFALS, TPF / ENDPG / БПЦVZЗ, ЦДБЮБ0, ЦДБ4Б0, БПЦШZЗ, БПЦQГЗ, ЦДЦЦБ0 |
| 1113 | 587 | 1022 | 981 | 37 | TABLES/DATA (mostly constants) | THAXES, CIRCLE, NUMBER, SIGNA, POLINE, MARKER, WHERE, ASTEP, POLREG / SYMBOL / БTЦББ0, БПФЗZЗ, ЦДДFБ0, FOЗЖF0, CK0, MOVEC |
| 1114 | 588 | 1023 | 1011 | 17 | TABLES/DATA (mostly constants) | RAXES, CIRCLE, NUMBER, SIGNA, XLGAX, TMLGF / SYMBOL / БTД2Б0, БTДЯБ0, ЦДЦЮБ0, ЦДДЯБ0, ЦДДDБ0 |
| 1115 | 589 | 1022 | 998 | 20 | TABLES/DATA (mostly constants) | YLGAX, TMLGF, NUMBER, LGLINE, MARKER, WHERE, COORD, SDPG / SYMBOL / ЦДФПБ0, FOЗ1F0, CK0, MOVEC, AMODC, SIGNC |
| 1116 | 590 | 1021 | 1013 | 10 | TABLES/DATA (mostly constants) | SHADE, LINEO, SDPG / - / ЦДФФБ0, ЦДФИБ0, ЦДГ9Б0, БTЖЖБ0, ЦДИЖБ0, ЦДГJБ0 |
| 1117 | 591 | 952 | 945 | 11 | TABLES/DATA (mostly constants) | HISTGM, BARS, BAR, AXISC, DASHP, ANGLER, ATRAN2 / SYMBOL / MOVEC, IRDBC, FOЗБF0, БПДWZЗ, БПДVZЗ, ЦДБBБ0 |
| 1120 | 592 | 1017 | 1013 | 8 | TABLES/DATA (mostly constants) | MTMPL, SHIFT, ATRAN2, BEGLEV, ENDLEV, LSCALE, ROTATE, PSCALE, RESET, AXISC / - / FOЗБF0, Б7З0, Б7З1, Б7З2, Б7З3 |
| 1121 | 593 | 1009 | 999 | 8 | TABLES/DATA (mostly constants) | BLANCH, MOVBL1, MOVE2, NOTCH1, ATRAN2, GOBSEK, GFFALS, MOVE1, BLANCA / - / ЦДГГБ0, ЦДФRБ0, Б7ЗБ, Б7ЗД, Б7ЗЦ, Б7ЗФ |
| 1122 | 594 | 1006 | 978 | 33 | TABLES/DATA (mostly constants) | MOVE3, BLANCA, NOTCH1, BLANC, BLANCH, GFFALS, NOTCH, GOBSEK, SPLINE, TRIDIG, TDMP / - / БTБ4Б0, ЦДБ2Б0, Г7ЗI, БПФШZЗ, БПФЭZЗ, БTЦ1Б0 |
| 1123 | 595 | 1016 | 1013 | 6 | TABLES/DATA (mostly constants) | TRIDIG, SPLINT, CUBPOL, TCALC, LESQ, SMINV, APPOLY / - / БПБЬГЗ, БПБЗБ8, БПБ9ГЗ |
| 1124 | 596 | 1017 | 1003 | 19 | TABLES/DATA (mostly constants) | CHENSP, FORFIT, FORIT, TCALC, FORIF, LINFIL, DERIV5, SINCL, CUBPOL / - / БПБ2ГЗ, БПБЖГЗ, FOЗЦF0, БПБ9ГЗ, БПБЗБ8 |
| 1125 | 597 | 1022 | 1018 | 7 | TABLES/DATA (mostly constants) | LSFIT, MINMAX, TDLIM, HCNCRD, LIMITS, HCSURF, TDSECT / - / Г7ЗЖZЗ, БПЦЮZЗ, БПЦЩZЗ, ЦДБББ0, БПЦQГЗ |
| 1126 | 598 | 1022 | 1018 | 6 | TABLES/DATA (mostly constants) | TDSECT, HCNCRD, HCLINE, LINEO, HCIND, ZINT, INIT, HCUNIT, VIEW, HCPRSP, HCINV, HCROT1 / - / ЦДЯЙБ0, ЦДЦBБ0, ЦДГ3Б0, ЦДФXБ0, ЦДГЩБ0, ЦДИ5Б0 |
| 1127 | 599 | 1021 | 1017 | 7 | TABLES/DATA (mostly constants) | AXONOM, HCROT1, TDROT, CABIN, SHEAR, ISOMET, DIMET, TDSCAL, HCUNIT, HCMULT, TDTRAN, SAVETR, SETTR, VIEW, HCPRSP / - / ЦДГ3Б0, SQRTC, ATAN2, ЦДИШБ0, БTЖЮБ0 |
| 1130 | 600 | 1023 | 1016 | 13 | TABLES/DATA (mostly constants) | HCINV, ISOMET, TDLIML, HCNCRD, LIMITS, TDSCAL, HCUNIT, HCMULT, TDLINE, TDTRAN / - / БПЦ4ГЗ, WЛБШБ0, БПЦ5ГЗ, Г4ЦG |
| 1131 | 601 | 1023 | 1011 | 15 | TABLES/DATA (mostly constants) | THREED, HCNCRD, HCIND, HCSURF, FNROOT, ITPLBV, TDLIML, LIMITS / - / DЙ0, SQRTC, MAX0C, IABSC, ISIGN, БПД9ГЗ |
| 1132 | 602 | 1024 | 1010 | 22 | TABLES/DATA (mostly constants) | - / - / ЦДЙФБ0, ЦДЙ7Б0 |
| 1133 | 603 | 1023 | 863 | 282 | TABLES/DATA (mostly constants) | ITPLBV / - / БПЫДГЗ, ЦДПPБ0, Г7ЗГZЗ |
| 1134 | 604 | 1022 | 1019 | 3 | TABLES/DATA (mostly constants) | SFCFIT, CONDEK, FNROOT, INSDEK, WHERE / - / ЦДЙЛБ0, WЛЯ3Б0, БП0EГЗ, БП0BГЗ, WЛЛШБ0, ЦДЖ1Б0 |
| 1135 | 605 | 1023 | 1016 | 12 | TABLES/DATA (mostly constants) | INSDEK, ITPLBV, NUMBER, DRALIM / - / ЦДЦЖБ0, ЦДЦЗБ0, Б7ЗД, MOVEC, ЦДЛ9Б0 |
| 1136 | 606 | 1024 | 1022 | 3 | TABLES/DATA (mostly constants) | SMTSIM / - / FOЗФF0, ЦДЛ4Б0, ЦДЛBБ0, БП3ИГЗ, ЦДЛXБ0, WЛЖ1Б0 |
| 1137 | 607 | 1023 | 904 | 230 | TABLES/DATA (mostly constants) | SMTBVF / - / ЦД1HБ0, ЦДЯVБ0, WЛЖ1Б0 |
| 1140 | 608 | 1024 | 1015 | 16 | TABLES/DATA (mostly constants) | SMTONE, DRFRAM / - / ЦДИИБ0, БП3ГГЗ, WЛЛЦБ0, БП2ЛГЗ, БП4ГДФ, БП3ФГЗ |
| 1141 | 609 | 1021 | 1017 | 5 | TABLES/DATA (mostly constants) | OPER, DRACON, FNROOT, INSIDE, WHERE, ITPLBV, NUMBER, ANGLER / - / WЛЛЦБ0, Б7ЗФ, БПИDБ8, Б7З8, БПГШГЗ, Б7ЗД |
| 1142 | 610 | 1023 | 1006 | 22 | TABLES/DATA (mostly constants) | ARCANG, IVEST, ARCC1, ARCELA, GFFALS, ELIPS, ARCELB, AREB1, ARCIA, ARCIB, ARCIC, ARCID, ANGLER, ITPLBV, NUMBER / - / БПЦ3ZЗ, ЦДБГБ0, БПЦ4ZЗ, ЦДБББ0, ЦДБЖБ0, БПЦ7 |
| 1143 | 611 | 1024 | 999 | 42 | TABLES/DATA (mostly constants) | ARCOCC, IVEST, GFFALS, ANGLER, ARCOLC, STRMOD, CIRTAC, ARCIA, ITPLBV, NUMBER / - / БПИЮZЗ |
| 1144 | 612 | 1022 | 1013 | 13 | TABLES/DATA (mostly constants) | ARCOLL, IVEST, GFFALS, ANGLER, AREB1, ARROW, STRMOD, ARCIA, CIRC, CIRTAC, CIRTAL / - / БПБM, БПБN, ЦДБ3Б0, FOЗ9F0 |
| 1145 | 613 | 1024 | 1020 | 5 | TABLES/DATA (mostly constants) | CROSS, IVEST, GFFALS, ANGLER, CIRTAC, DDIST / - / БПЙIГЗ, ЦДГHБ0, ЦДГKБ0 |
| 1146 | 614 | 1022 | 994 | 36 | TABLES/DATA (mostly constants) | DIMDRO, WRACA, ARROW, RDSTR, STRMOD, RDMVA, GFFALS, WRSTR, WRMVA, RDACA, RDACB, ARCIA, DIST, AREB1, SECANT, IVEST, ANGLER, ELPS, ... (+4) / - / БПГXZЗ, ЦДФЮБ0, ЦДДGБ0, DЙ0, DHП |
| 1147 | 615 | 1023 | 1018 | 7 | TABLES/DATA (mostly constants) | LICON, IVEST, GFFALS, ANGLER, LITAN, RDCRC, MODGF, STRMOD, MOVA, MOVB, MOVC, POLG, RDACA, RDACB / - / БTЦIБ0, ЦДЦGБ0, БПД3, БПД5, ЦДЦQБ0, ЦДЦЛБ0 |
| 1150 | 616 | 1024 | 1020 | 5 | TABLES/DATA (mostly constants) | RDACC, STRMOD, GFFALS, RDACD, RDAEA, RDAEB, RDCRC, RDELP, RDMVA, ANGLER, RDMVB, RDMVC, RDMVE / - / FOЗ0F0, БПД2, БПД3, FOЗ2F0, SQRTC, БПББ |
| 1151 | 617 | 998 | 997 | 1 | TABLES/DATA (mostly constants) | GFFALS, RDSTR, SECANT, RDMVA, IVEST, WRSTR, WRMVA, SPIRAL, CIRCLE, STAR, STRMOD, WHERP, WRACA, WRACB, ARCANG, ANGLER, WRACC, ARCC1, ... (+2) / - / Г7ЗЦ, Б7ЗЖ, БПБVZЗ, БПБYZЗ |
| 1152 | 618 | 1016 | 1015 | 2 | TABLES/DATA (mostly constants) | STRMOD, GFFALS, WRAEB, AREB1, WRAEA, ARCANG, WRCRC, WRELP, WRMVA, WRMVE, WRMVB, WRMVC, IVEST, WRSTR / - / SQRTC, Г7ЗЙ, Г7ЗЛ, DK0, CLЗ |
| 1153 | 619 | 1022 | 1000 | 9 | TABLES/DATA (mostly constants) | PRSP, CORNL, PATCH / - / Б7ЗИ, FOЗ0F0, Г7ЗЙ, Г7ЗЛ, Г7ЗЯ, Б7З5 |
| 1154 | 620 | 1022 | 1020 | 2 | TABLES/DATA (mostly constants) | PATCH, SEARCH, LININT, INTRSC, BUFL / - / БПФZГЗ, БЫЗЖГЗ, БПФЮZЗ |
| 1155 | 621 | 1021 | 1017 | 5 | TABLES/DATA (mostly constants) | MNMX, LIMITS, PATCH, INTRSC, MAP, PRJT / - / Б7ЗБ, Б7ЗЦ, БПДWГЗ, БПДЩГЗ, БПДЧГЗ |
| 1156 | 622 | 1020 | 1003 | 25 | TABLES/DATA (mostly constants) | ISOLIN, LINEO, MNMX, XPOL, PATCH, YPOL, LINT, EXTREM, CELL, ZAPIT, NUMLIN, SIZLIN / - / Б7ЗЙ, ЦДЦHБ0, БПГЬГЗ, Б7ЗБ, WЛФ1Б0 |
| 1157 | 623 | 1024 | 1021 | 3 | TABLES/DATA (mostly constants) | LINNUM, NUMBER, CMGRID, CELL, SIZNUM, RENUM, QUADRA / BRLINE / БПДEГЗ, БTЦЮБ0, ЦДБ2Б0, БПДNГЗ |
| 1160 | 624 | 1021 | 1017 | 5 | TABLES/DATA (mostly constants) | ADDLEV, LEVFUN, MINMAX, SUPLIN, LINEMC, LINEMO, KEYPO, MARKER, BITA, LOCEXT, NUMBER, LEVMAP / BRLINE / БПДNГЗ, БПФДГ0, БПФФГ0, БПДLГЗ, БПФДZЗ, FOЗИF0 |
| 1161 | 625 | 1013 | 989 | 21 | TABLES/DATA (mostly constants) ** | LOOK, LINNUM, ZAPIT, FCATBD, SUPLIN, LINEMC, LINEMO, GIVZON, FDISC, WCATAL, GDISC, GIVENZ, SETREF, RCATAL, SETK, SETEND, MARKER, PUTXY, ... (+12) / BRLINE, MDBUFF / БПДЬZЗ, WЛЦ2Б0, БПДЫZЗ, БПД9ZЗ, БПДAZЗ |
| 1162 | 626 | 1011 | 1004 | 13 | TABLES/DATA (mostly constants) ** | GIVENZ, WCATWO, CLEAZN, RZONE, LINNUM, ZAPIT, SETREF, SETIND, SETK, COPDCB, PUTXY, FOPEN, NEXTZN, FDISC, GDISC, E70, COMPDT, RZON, ... (+8) / MDBUFF / ЦДБEБ0, ZGЗФБ0, WZONC, FOЗИF0, БПИГГЗ, БПЦTГЗ |
| 1163 | 627 | 90 | 90 | 1 | SPARSE CATALOG (secondary GRAFOR-SUD directory) ** | - / MDBUFF, PLOT, ONOFF, PEN, FRAME, FRAGM, EFRAGM, GROPEN, GRWRIT, GRCLOS, GRNOTZ, GRNAME, WRITC, ENDPG, PAGE, SET, IDENT, ITALIC, ... (+18) / - |
| 1164 | 628 | 0 | 0 | 0 | EMPTY (all 1024 words zero) | - / - / - |
| 1165 | 629 | 912 | 908 | 5 | TABLES/DATA (mostly constants) | CIRCLE, SYMTAB, WHERE / XYSORT, ARC, SYMBOL, MOVE, BRLINE, FULL, BROKEN / БПЦЖZЗ, ЦДБJБ0, БПЦЛZЗ |
| 1166 | 630 | 1024 | 1020 | 5 | TABLES/DATA (mostly constants) | - / - / WЛ84Б0, WЛ9ЦБ0, БПП1ГЗ, ЦДБLБ0 |
| 1167 | 631 | 1003 | 989 | 12 | TABLES/DATA (mostly constants) | LIMITS, REGION, NUMBER / LPL, ENDPG, SYMBOL, SET / БПП9ЖЗ, ЦД02Б0, ЦД1ЭБ0, БПП9ГЗ, БПП6ЖЗ, БППE2З |
| 1170 | 632 | 16 | 4 | 1522 | SPARSE / mostly empty | - / - / - |
| 1171 | 633 | 760 | 758 | 2 | TABLES/DATA (mostly constants) | - / - / Б87ЯBЗ, 2OЮЮБ0, Б87D2З, KЗ2WЭ, Б87E6З, Б87E2З |
| 1172 | 634 | 790 | 785 | 3 | TABLES/DATA (mostly constants) | - / - / 08Ю, ИXЬЧБ0, БPПФЭ, ЭИЮЮ |
| 1173 | 635 | 732 | 725 | 5 | TABLES/DATA (mostly constants) | - / - / - |
| 1174 | 636 | 14 | 10 | 4 | SPARSE / mostly empty | - / - / - |
| 1175 | 637 | 1024 | 1019 | 2 | TABLES/DATA (mostly constants) | - / - / - |
| 1176 | 638 | 1024 | 1017 | 2 | TABLES/DATA (mostly constants) | - / - / - |
| 1177 | 639 | 1024 | 994 | 7 | TABLES/DATA (mostly constants) | - / - / - |

`**` marks a zone where a low-level GRAFOR or disk-exchange module name was found.
The third name column is raw decoded six-character words; in table zones these are data, not module names.

## Explicitly empty or nearly empty zones

- **0o1101 (577 dec): 0/1024 nonzero words - the whole zone is zeros.**
- **0o1164 (628 dec): 0/1024 nonzero words - the whole zone is zeros.**
- 0o1170 (632): 16/1024 nonzero; 0o1174 (636): 14/1024 nonzero - almost entirely zeros.
- 0o1103 (579): 85/1024, 0o1163 (627): 90/1024 - sparse, but 0o1163 is a real small directory, not erased code.
- A zero zone in a catalog-driven library does not by itself prove erasure: it may simply be an unused slot.

## Catalog contents (zone 0o1100)

The primary catalog contains **257 module names**. Low-level / disk-exchange entries found:

`SETIND`, `GETIND`, `SETREF`, `AFTZN`, `WCATWO`, `SWCAT`, `GIVENZ`, `SETWGR`, `SETEND`, `SETZON`, `GDISC`, `FDISC`, `ABUFF`, `RCATAL`, `WCATAL`, `RZON`, `WZON`, `RZONE`, `WZONE`, `SETR`, `SETW`, `CLEAZN`, `COMPDT`, `E70`

A second, much smaller directory in zone **0o1163** lists
36 names: `MDBUFF`, `PLOT`, `ONOFF`, `PEN`, `FRAME`, `FRAGM`, `EFRAGM`, `GROPEN`, `GRWRIT`, `GRCLOS`, `GRNOTZ`, `GRNAME`, `WRITC`, `ENDPG`, `PAGE`, `SET`, `IDENT`, `ITALIC`, `MMS`, `CMS`, `INCHES`, `RDB`, `IRDB`, `WDB`, `IWDB`, `LPL`, `LPL1`, `LPL2`, `LPL3`, `BROKEN`, `FULL`, `BRLINE`, `MOVE`, `SYMBOL`, `ARC`, `XYSORT`.

These 0o1163 names (GROPEN, GRWRIT, GRCLOS, GRNOTZ, GRNAME, MDBUFF, RDB/IRDB, WDB/IWDB, PLOT, PEN, FRAME, ...)
are exactly the "нижний уровень графора" style routines, plus the Э70/E70 disk entry in the main catalog.

## Sanity check: zone 0o1162

`disasm/zone_1162.txt` disassembles cleanly: 1011/1024 nonzero words, readable BEMSH code
starting with `START зп START`, `уиа 40000(M10)`, `уим M12`, `уи M11`, `сч 10(M11)`,
`по 40005`, `мод 10(M11)`. Decoded name words include COPDCB at word 368 decimal (0o560), matching the locator given in the task, plus FDISC (0o1063), GDISC (0o1064), E70 (0o1114), SETIND, SETREF, CLEAZN and RZONE.
Together with WCATWO, GIVENZ, LINNUM and ZAPIT, this confirms the catalog points at real bodies here.

## Conclusion

Observed facts:
- The catalog at 0o1100 is intact and dense (514/1024 nonzero words, 257 readable names).
- 62 of 64 zones contain nonzero data; only 2 zones are completely zero.
- Low-level GRAFOR names and disk-exchange names (E70/Э70, GDISC, FDISC, RCATAL, WCATAL, RZON, WZON,
  RZONE, WZONE, WCATWO, GROPEN, GRWRIT, GRCLOS, GRNOTZ, GRNAME) are present in the catalogs.
- Extract codes Э50..Э77 and one УВВ appear in the disassembled bodies (see GRAFOR-GREP.txt).
- Zone 0o1162 disassembles to coherent code, so at least that body is intact.

Inference (not proven by this pass):
- Library 22 as a whole looks intact, not wiped: the directory and most bodies are present.
- The two zero zones (0o1101, 0o1164) and the sparse zones look like unused/leftover slots;
  whether the OVERLAY* worker fails because a specific low-level module body is missing
  requires resolving a catalog name to its body address and checking that body, which is a separate step.

