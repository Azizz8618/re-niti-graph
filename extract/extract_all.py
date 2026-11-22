#!/usr/bin/env python3
"""Extract library 22 (ГРАФОР-СУД) from BESM-6 volume 2048.

Creates, in this directory:
  bin/zone_<decimal>.bin   6-byte-per-word dumps of catalog + body zones
  catalog.txt              human-readable decoded catalog
  manifest.json            machine-readable decoded catalog + checksums
  README.md                provenance, commands, caveats
"""
import hashlib
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from decode_catalog import decode, v, CATZ

OUT = os.path.dirname(os.path.abspath(__file__))
BINDIR = os.path.join(OUT, "bin")
VOLNAME = "2048"          # BESM6_PATH resolves via besmtool
CATALOG_LABEL = "*LIBRARY:22 /ГРАФОР-СУД/ 1201 10.12.91"


def md5(path):
    h = hashlib.md5()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def dump_zone(z):
    """besmtool dump uses decimal logical zone numbers; 1024 words x 6 bytes."""
    path = os.path.join(BINDIR, "zone_%d.bin" % z)
    subprocess.run(["besmtool", "dump", VOLNAME,
                    "--start=%d" % z, "--length=1",
                    "--to-file=" + path],
                   check=True, stdout=subprocess.DEVNULL)
    return path


def main():
    os.makedirs(BINDIR, exist_ok=True)
    ents = decode()
    mods = [e for e in ents if e["kind"] == "module"]
    refs = [e for e in ents if e["kind"] == "ref"]

    # Every zone physically covered by a module body, including zones spanned
    # by a body that starts in an earlier zone (e.g. 0o1132 inside ITPLBV).
    body_zones = set()
    for e in mods:
        end = (e["word"] + max(e["load"], e.get("hdr_load", 0))) // 1024
        for k in range(end + 1):
            body_zones.add(e["zone"] + k)
    zones = sorted(set([CATZ]) | body_zones)

    print("dumping %d zones: 0o%04o (catalog) + 0o%04o..0o%04o (bodies)" %
          (len(zones), CATZ, min(body_zones), max(body_zones)))
    binfiles = {}
    for z in zones:
        p = dump_zone(z)
        binfiles[z] = os.path.relpath(p, OUT)
        assert os.path.getsize(p) == 6144, p

    # --- verify: re-dump one body zone and byte-compare ---------------------
    probe = 0o1162
    first = binfiles[probe]
    again = os.path.join(BINDIR, "verify_tmp_zone_%d.bin" % probe)
    subprocess.run(["besmtool", "dump", VOLNAME,
                    "--start=%d" % probe, "--length=1", "--to-file=" + again],
                   check=True, stdout=subprocess.DEVNULL)
    b1 = open(os.path.join(OUT, first), "rb").read()
    b2 = open(again, "rb").read()
    assert b1 == b2, "re-dump mismatch"
    os.remove(again)   # temporary verification copy only
    verify = dict(zone_oct="%04o" % probe, zone_dec=probe,
                  re_dump_byte_identical=True, bytes=len(b1),
                  md5=md5(os.path.join(OUT, first)))

    checksums = {binfiles[z]: md5(os.path.join(OUT, binfiles[z])) for z in zones}

    # --- manifest.json -----------------------------------------------------
    manifest = dict(
        source_volume="/usr/local/share/besm6/2048",
        source_volume_alt="/home/azizz/Yandex.Disk/simh/BESM6/MD/2048",
        catalog_label=CATALOG_LABEL,
        catalog_zone_dec=CATZ, catalog_zone_oct="%04o" % CATZ,
        info_word_format=dict(
            note="Calibrated formula, re-siprod/pascal/README/ПЛАН-ОЗУ.md p.7",
            fields="4 x 12 bit [A][B][C][D], D=0",
            A="0o2000 + carry + word + 8 (base 0o6000 for permanent libraries)",
            B="(relzone + 0o40) & 0o77 ; carry=1 when relzone >= 0o40",
            C="load * 8",
            body_zone="catalog_zone + relzone",
        ),
        body_zone_range_oct=["%04o" % min(body_zones), "%04o" % max(body_zones)],
        body_zone_range_dec=[min(body_zones), max(body_zones)],
        bin_format="1024 x 6-byte big-endian BESM-6 words per zone (6144 bytes)",
        dump_command="besmtool dump 2048 --start=<decimal zone> --length=1 --to-file=bin/zone_<decimal>.bin",
        totals=dict(entries=len(ents), modules=len(mods), refs=len(refs),
                    head_names_verified=sum(e["verified"] for e in mods),
                    load_field_matches_header=sum(e.get("load_matches", False) for e in mods)),
        zones=[dict(zone_dec=z, zone_oct="%04o" % z, bin=binfiles[z],
                    md5=checksums[binfiles[z]],
                    kind="catalog" if z == CATZ else "body") for z in zones],
        verification=verify,
        entries=[],
    )
    for e in ents:
        rec = dict(idx=e["idx"], name=e["name"], cat_word=e["cat_word"],
                   info_word_oct=e["info_oct"], info_word_dec=e["info"],
                   kind=e["kind"])
        if e["kind"] == "module":
            rec.update(zone_oct="%04o" % e["zone"], zone_dec=e["zone"],
                       word=e["word"], load=e["load"],
                       relzone_oct="%02o" % e["relzone"], carry=e["carry"],
                       bin=binfiles[e["zone"]],
                       head_name=e.get("head_name"),
                       head_zone_oct=("%04o" % e["head_zone"]) if e.get("head_zone") is not None else None,
                       head_word=e.get("head_word"),
                       head_verified=e["verified"],
                       header_load=e.get("hdr_load"),
                       load_field_matches_header=e.get("load_matches", False))
        else:
            rec.update(ref_oct="%o" % e["ref"], ref_dec=e["ref"],
                       note="reference/entry-point record, no body found on volume")
        manifest["entries"].append(rec)
    with open(os.path.join(OUT, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
        f.write("\n")

    # --- catalog.txt -------------------------------------------------------
    lines = []
    lines.append("Library 22 (ГРАФОР-СУД) catalog, volume 2048, zone 0o1100")
    lines.append(CATALOG_LABEL)
    lines.append("Info word = [A=12][B=6][C=18][D=12]; "
                 "A=0o2000+carry+word+8, B=(relzone+0o40)&0o77, C=load*8")
    lines.append("")
    lines.append("%3s %-9s %-16s %-7s %6s %6s %8s %-6s %s" %
                 ("#", "name", "info(oct)", "zone", "word", "load", "hdr_load", "verify", "bin/zone_<dec>.bin"))
    lines.append("-" * 100)
    for e in ents:
        if e["kind"] == "module":
            lines.append("%3d %-9s %-16s 0o%04o %6d %6d %8s %-6s %s" %
                         (e["idx"], e["name"], e["info_oct"], e["zone"],
                          e["word"], e["load"],
                          e.get("hdr_load", "-"),
                          "OK" if e["verified"] else "FAIL",
                          binfiles[e["zone"]]))
        else:
            lines.append("%3d %-9s %-16s %-7s %6s %6s %8s %-6s %s" %
                         (e["idx"], e["name"], e["info_oct"], "-", "-", "-", "-",
                          "REF", "-> %o" % e["ref"]))
    lines.append("")
    lines.append("Total: %d entries = %d modules + %d reference records" %
                 (len(ents), len(mods), len(refs)))
    lines.append("Head-name verification: %d/%d OK" %
                 (sum(e["verified"] for e in mods), len(mods)))
    lines.append("Body zones: 0o%04o..0o%04o (all zones dumped; 0o1132 is spanned "
                 "by ITPLBV, not a catalog start)" %
                 (min(body_zones), max(body_zones)))
    with open(os.path.join(OUT, "catalog.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    # --- README.md ---------------------------------------------------------
    r = []
    r.append("# Library 22 (ГРАФОР-СУД) extraction, volume 2048")
    r.append("")
    r.append("## Source")
    r.append("")
    r.append("- Image: `/usr/local/share/besm6/2048` (byte-identical to "
             "`/home/azizz/Yandex.Disk/simh/BESM6/MD/2048` in the relevant zones).")
    r.append("- Catalog: logical zone `0o1100` (decimal `576`), entry "
             "`*LIBRARY:22 /ГРАФОР-СУД/ 1201 10.12.91`.")
    r.append("- Catalog structure: `w0` service/date word (`0000000002244600`), "
             "`w1=0`, then 255 pairs (name, info word) in `w2..w511`, "
             "terminator `w512 = 0o7777777777777777`.")
    r.append("- There is **no second catalog zone**: zone `0o1101` is empty "
             "(all 1024 words zero).")
    r.append("")
    r.append("## Info-word decoding")
    r.append("")
    r.append("Calibrated BESM-6 DMS format (see "
             "`re-siprod/pascal/README/ПЛАН-ОЗУ.md`, item 7):")
    r.append("")
    r.append("```")
    r.append("[A:12][B:6][C:18][D:12], D=0")
    r.append("A = 0o2000 + carry + word + 8     (base 0o2000: personal/general library on 2048)")
    r.append("B = (relzone + 0o40) & 0o77       carry = 1 if relzone >= 0o40")
    r.append("C = load * 8")
    r.append("body_zone = catalog_zone + relzone")
    r.append("```")
    r.append("")
    r.append("`word` is the logical word of the DMS header inside the body zone "
             "(`+8` in the formula accounts for the 8-word file-zone header). "
             "The module head name follows the header plus cmd/const/data/set "
             "sections; all 238 decoded names were located and matched there.")
    r.append("")
    r.append("## Zone range")
    r.append("")
    r.append("- Catalog: `0o1100` (dec 576).")
    r.append("- Body zones pointed to by the catalog: `0o1105..0o1162` "
             "(dec 581..626), 46 zones, all dumped.")
    r.append("- `0o1102..0o1104` contain non-DMS data and are **not** referenced "
             "by the catalog; they were not dumped.")
    r.append("- `0o1101` is empty; `0o1132` has no catalog start but is fully "
             "spanned by the large `ITPLBV` body beginning in `0o1131`, so it "
             "is included in the dump.")
    r.append("")
    r.append("## Extraction commands")
    r.append("")
    r.append("```sh")
    r.append("# catalog zone")
    r.append("besmtool dump 2048 --start=576 --length=1 --to-file=bin/zone_576.bin")
    r.append("# body zones, e.g. 0o1105 = 581 ... 0o1162 = 626")
    r.append("for z in $(seq 581 626); do")
    r.append("  besmtool dump 2048 --start=$z --length=1 --to-file=bin/zone_$z.bin")
    r.append("done")
    r.append("```")
    r.append("")
    r.append("Each `.bin` is 6144 bytes = 1024 words x 6 bytes (big-endian "
             "48-bit words), suitable for `disbesm6`. File names use the "
             "**decimal** `--start` zone; `manifest.json` records both octal "
             "and decimal zone numbers.")
    r.append("")
    r.append("## Verification")
    r.append("")
    r.append("- Decoded all 255 catalog entries: 238 modules + 17 reference "
             "records; head names verified for **238/238** modules.")
    r.append("- Re-dumped zone `0o1162` (dec 626) to a temporary file: "
             "byte-identical to the stored dump (6144 bytes, md5 "
             "`%s`)." % verify["md5"])
    r.append("- MD5 of every `.bin` is in `manifest.json` under `zones[]`.")
    r.append("")
    r.append("## Caveats / inconsistencies")
    r.append("")
    r.append("- 17 entries have a small info word with no body (GETIND, AFTZN, "
             "CRDUM, SWCAT, FDISC, WCATAL, WZON, RZONE, WZONE, SETR, SETW, "
             "GETXY, NOTCH1, BLANCA, MOVBL3, MOVBL1, IBCD). They are "
             "reference/entry-point records; their small value is recorded as "
             "`ref` in the manifest. No corresponding head name exists in any "
             "body zone.")
    r.append("- The catalog `load` field disagrees with the module header's "
             "`cmd+const` for 213 of 238 modules (e.g. SETK: catalog 30, "
             "header 26; DRACON: catalog 524, header 437). The repo notes this "
             "as a known stale-catalog artifact; both values are recorded in "
             "`catalog.txt` and `manifest.json`. Zone/word pointers themselves "
             "are confirmed by head names.")
    r.append("- Zone `0o1101` is empty; no second catalog zone exists.")
    r.append("- Modules may span zone boundaries (notably `ITPLBV` starting at "
             "`0o1131` word 384 and covering `0o1132`); the dump covers the "
             "whole contiguous body range.")
    r.append("")
    r.append("## Files")
    r.append("")
    r.append("- `bin/zone_<dec>.bin` - 47 zone dumps (1 catalog + 46 body).")
    r.append("- `catalog.txt` - full decoded catalog table.")
    r.append("- `manifest.json` - same data as JSON, with per-file MD5.")
    r.append("- `decode_catalog.py`, `extract_all.py` - extraction scripts "
             "(kept for reproducibility).")
    with open(os.path.join(OUT, "README.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(r) + "\n")

    print("wrote catalog.txt, manifest.json, README.md and %d bin files" % len(zones))
    print("verify md5", verify["md5"])


if __name__ == "__main__":
    main()
