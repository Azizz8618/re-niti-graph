#!/usr/bin/env python3
"""Slice library-22 DMS modules out of the dumped zones and run native dtran.

Inputs (read only):
  ../extract/manifest.json        catalog of modules, with zone/word pointers
  ../extract/bin/zone_<dec>.bin   1024 x 6-byte big-endian BESM-6 words per zone
  /home/azizz/Yandex.Disk/dtran/dtran

Outputs (written only into this folder):
  bin/<safe>.bin     exact DMS module bytes, 6 bytes/word
  <safe>.mad         dtran output (MADLEN-style pseudo-assembly)
  INDEX.md           one row per module
  README.md          how to reproduce, caveats
  FAILURES.txt       dtran failures and header-validation warnings
  SPOTCHECK.txt      first 20 lines of three representative .mad files
  name_map.tsv       catalog name -> safe filename mapping
  dtran_stderr.log   dtran diagnostics (stderr) for all attempts

The DMS header is decoded as in tools/siprod_lib.py (re-siprod):
  w0 = head_len | sym_len<<12 | debug_len<<36
  w1 = set_len | data_len<<15 | long_len<<30
  w2 = cmd_len | bss_len<<15 | const_len<<30
  disk length = 3 + cmd + const + data + set + head + sym + long + debug
(head_len is validated to be 1; the single head word holds the module name.)
"""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
EXTRACT = HERE.parent / "extract"
MANIFEST = EXTRACT / "manifest.json"
DTRAN = Path("/home/azizz/Yandex.Disk/dtran/dtran")
BIN_DIR = HERE / "bin"

# Kodirovka TEXT from re-siprod/tools/siprod_lib.py.
TEXT = [
    " ", ".", "Б", "Ц", "Д", "Ф", "Г", "И", "(", ")", "*", "Й",
    "Л", "Я", "Ж", "/", "0", "1", "2", "3", "4", "5", "6", "7",
    "8", "9", "Ь", ",", "П", "-", "+", "Ы", "З", "A", "B", "C",
    "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O",
    "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "Ш",
    "Э", "Щ", "Ч", "Ю",
]

M15 = 0o77777
M12 = 0o7777


def text_decode(word: int) -> str:
    return "".join(TEXT[(word >> (42 - 6 * i)) & 0x3F] for i in range(8))


def safe_name(name: str) -> str:
    """Deterministic, readable filename stem; Cyrillic is preserved."""
    out = []
    for ch in name:
        if ch == "*":
            out.append("_s")
        elif ch == "/":
            out.append("_p")
        elif ch.isalnum() or ch in "-_":
            out.append(ch)
        else:
            out.append("_u%02X" % ord(ch))
    return "".join(out)


def md5(data: bytes) -> str:
    return hashlib.md5(data).hexdigest()


class Zones:
    """Read arbitrary word ranges from the contiguous dumped zone files."""

    def __init__(self, manifest: dict):
        self.manifest = manifest
        self.cache: dict[int, list[bytes]] = {}
        self.md5_warnings: list[str] = []
        zmap = {z["zone_dec"]: z for z in manifest["zones"]}
        for z in manifest["zones"]:
            raw = (EXTRACT / z["bin"]).read_bytes()
            if len(raw) != 1024 * 6:
                raise RuntimeError(f"{z['bin']}: {len(raw)} bytes, expected 6144")
            if md5(raw) != z["md5"]:
                self.md5_warnings.append(f"{z['bin']}: md5 mismatch")
            self.cache[z["zone_dec"]] = [
                raw[i * 6:(i + 1) * 6] for i in range(1024)
            ]
        self.zmap = zmap

    def word_bytes(self, zone_dec: int, index: int) -> bytes:
        z = zone_dec + index // 1024
        i = index % 1024
        if z not in self.cache:
            raise RuntimeError(f"missing dumped zone {z} (octal {z:o})")
        return self.cache[z][i]

    def slice_words(self, zone_dec: int, first: int, count: int) -> bytes:
        return b"".join(self.word_bytes(zone_dec, first + i) for i in range(count))


def parse_header(words: list[int]) -> dict:
    w0, w1, w2 = words[0], words[1], words[2]
    return {
        "head": w0 & M12,
        "sym": (w0 >> 12) & M12,
        "debug": w0 >> 36,
        "set": w1 & M15,
        "data": (w1 >> 15) & M15,
        "long": (w1 >> 30) & M15,
        "cmd": w2 & M15,
        "bss": (w2 >> 15) & M15,
        "const": w2 >> 30,
    }


def disk_length(h: dict) -> int:
    return (3 + h["cmd"] + h["const"] + h["data"] + h["set"]
            + h["head"] + h["sym"] + h["long"] + h["debug"])


def w_to_int(data: bytes) -> int:
    return int.from_bytes(data, "big")


# dtran attempt list: (label, argv builder). The first successful one wins.
def attempts(slice_path: Path, cmdfile: Path):
    yield ("-F dms", [str(DTRAN), "-F", "dms", str(slice_path)])
    yield ("-F dms -e", [str(DTRAN), "-F", "dms", "-e", str(slice_path)])
    yield ("-F dms -c", [str(DTRAN), "-F", "dms", "-c", str(slice_path)])
    yield ("-F dms -R 8", [str(DTRAN), "-F", "dms", "-R", "8", str(slice_path)])
    yield ("-F dms -D cmdfile",
           [str(DTRAN), "-F", "dms", "-D", str(cmdfile), str(slice_path)])


def output_looks_ok(text: str) -> tuple[bool, str]:
    if not text.strip():
        return False, "empty output"
    lines = text.splitlines()
    if not any(re.match(r"^\s*\S+\s*:,NAME,", ln) for ln in lines[:3]):
        return False, "no NAME banner in first lines"
    if not any(",END," in ln for ln in lines):
        return False, "no ,END, directive"
    # Rough garbage detector: too many undecoded words is suspicious.
    dunno = sum(1 for ln in lines if "dunno" in ln)
    if dunno > 10 and dunno > len(lines) / 4:
        return True, f"suspicious: {dunno} 'dunno' lines"
    return True, ""


def main() -> int:
    if not DTRAN.is_file():
        print(f"missing dtran: {DTRAN}", file=sys.stderr)
        return 2
    BIN_DIR.mkdir(parents=True, exist_ok=True)
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    entries = manifest["entries"]
    modules = [e for e in entries if e.get("kind") == "module"]
    refs = [e for e in entries if e.get("kind") != "module"]
    zones = Zones(manifest)

    rows = []
    failures = []
    warnings = []
    stderr_log = []
    mapping = []
    name_seen: dict[str, str] = {}

    for e in modules:
        name = e["name"]
        stem = safe_name(name)
        if stem in name_seen and name_seen[stem] != name:
            failures.append(f"{name}: filename collision with {name_seen[stem]}")
            continue
        name_seen[stem] = name
        mapping.append((name, stem))

        zdec = e["zone_dec"]
        start = e["word"]
        try:
            hdr_words = [w_to_int(zones.word_bytes(zdec, start + i)) for i in range(3)]
        except RuntimeError as ex:
            failures.append(f"{name}: cannot read header: {ex}")
            continue
        h = parse_header(hdr_words)
        notes = []
        if h["head"] != 1:
            msg = f"{name}: head_len={h['head']} (expected 1)"
            warnings.append(msg)
            notes.append("head_len != 1")
        try:
            head_words = [w_to_int(zones.word_bytes(zdec, start + i))
                          for i in range(3 + h["cmd"] + h["const"] + h["data"] + h["set"],
                                         3 + h["cmd"] + h["const"] + h["data"] + h["set"] + h["head"])]
        except RuntimeError as ex:
            failures.append(f"{name}: cannot read head name: {ex}")
            continue
        head_name = text_decode(head_words[0]).rstrip() if head_words else ""
        if head_name != name:
            msg = f"{name}: head name mismatch (in module: {head_name!r})"
            warnings.append(msg)
            notes.append("head name mismatch")

        length = disk_length(h)
        if length <= 3 or length > 4096:
            failures.append(f"{name}: implausible disk length {length}")
            continue
        try:
            blob = zones.slice_words(zdec, start, length)
        except RuntimeError as ex:
            failures.append(f"{name}: unable to slice {length} words: {ex}")
            continue
        slice_path = BIN_DIR / f"{stem}.bin"
        slice_path.write_bytes(blob)

        cmdfile = HERE / "cmd" / f"{stem}.cmd"
        cmdfile.parent.mkdir(parents=True, exist_ok=True)
        # code:0 = start of the command section, in octal file offsets.
        cmdfile.write_text("code:0\n", encoding="ascii")

        chosen, chosen_out, chosen_err, chosen_rc = None, "", "", None
        tried = []
        for label, argv in attempts(slice_path, cmdfile):
            try:
                p = subprocess.run(argv, capture_output=True, text=True,
                                   errors="replace", timeout=120)
            except (OSError, subprocess.TimeoutExpired) as ex:
                tried.append(f"{label}: {ex}")
                continue
            tried.append(f"{label}: rc={p.returncode}, {len(p.stdout)} bytes")
            if p.stderr:
                stderr_log.append(f"=== {name} [{label}] rc={p.returncode} ===\n"
                                  + p.stderr.rstrip() + "\n")
            if p.returncode == 0 and p.stdout.strip():
                chosen, chosen_out, chosen_err, chosen_rc = label, p.stdout, p.stderr, p.returncode
                break

        if chosen is None:
            failures.append(f"{name}: dtran failed; attempts: {'; '.join(tried)}")
            notes.append("DTRAN FAILED")
            rows.append(dict(name=name, stem=stem, zone=zdec, zoct=e["zone_oct"],
                             word=start, load=e["load"], hload=h["cmd"] + h["const"] + h["bss"],
                             length=length, opts="FAILED", out="-", size="-", lines="-",
                             note="; ".join(notes)))
            continue

        ok, quality = output_looks_ok(chosen_out)
        if not ok:
            failures.append(f"{name}: dtran output looks wrong ({quality}) "
                            f"with {chosen}; attempts: {'; '.join(tried)}")
        if quality:
            notes.append(quality)
        if len(tried) > 1:
            notes.append("fell back: " + "; ".join(tried))

        out_path = HERE / f"{stem}.mad"
        out_path.write_text(chosen_out, encoding="utf-8")
        rows.append(dict(name=name, stem=stem, zone=zdec, zoct=e["zone_oct"],
                         word=start, load=e["load"],
                         hload=h["cmd"] + h["const"] + h["bss"],
                         length=length, opts=chosen, out=out_path.name,
                         size=out_path.stat().st_size,
                         lines=len(chosen_out.splitlines()),
                         note="; ".join(notes)))

    # --- name_map.tsv ------------------------------------------------------
    (HERE / "name_map.tsv").write_text(
        "catalog_name\tfilename_stem\n" + "".join(f"{a}\t{b}\n" for a, b in mapping),
        encoding="utf-8")

    # --- FAILURES.txt ------------------------------------------------------
    fail_lines = [
        "dtran failures and header-validation warnings",
        "==============================================",
        "",
        f"modules processed: {len(rows)} / {len(modules)}",
        f"dtran failures: {len(failures)}",
        "",
        "## Failures",
        "",
    ]
    fail_lines += [f"- {x}" for x in failures] or ["- none"]
    fail_lines += ["", "## Header-validation warnings", ""]
    fail_lines += [f"- {x}" for x in warnings] or ["- none"]
    fail_lines += ["", "## Zone md5 warnings", ""]
    fail_lines += [f"- {x}" for x in zones.md5_warnings] or ["- none"]
    (HERE / "FAILURES.txt").write_text("\n".join(fail_lines) + "\n", encoding="utf-8")

    (HERE / "dtran_stderr.log").write_text("\n".join(stderr_log) + "\n", encoding="utf-8")

    # --- INDEX.md ----------------------------------------------------------
    idx = [
        "# Library 22 (ГРАФОР-СУД, volume 2048) - MADLEN disassembly index",
        "",
        f"Generated by `slice_and_dtran.py` with `{DTRAN}`.",
        f"Real modules: **{len(modules)}**, reference/entry-only records skipped: "
        f"**{len(refs)}**. Modules with a dtran output: "
        f"**{sum(1 for r in rows if r['out'] != '-')}**.",
        "",
        "`Zone` is decimal (octal in parentheses); `Word` is the DMS header word "
        "inside that zone. `Load` is catalog load / header cmd+const+bss (words). "
        "`Disk len` is computed from the DMS header, see README.md. "
        "`Options` are the dtran flags that worked (default `-F dms`). "
        "Filename stems are in `name_map.tsv` (`*` -> `_s`, `/` -> `_p`).",
        "",
        "| Module | File | Zone | Word | Load cat/hdr | Disk len | dtran options | .mad | Bytes | Lines | Note |",
        "|---|---|---:|---:|---:|---:|---|---|---:|---:|---|",
    ]
    for r in rows:
        file_cell = f"`{r['stem']}.bin`" if r["stem"] != r["name"] else "-"
        out_cell = f"[{r['out']}]({r['out']})" if r["out"] != "-" else "-"
        idx.append(
            f"| {r['name']} | {file_cell} | {r['zone']} ({r['zoct']}) | {r['word']} "
            f"| {r['load']}/{r['hload']} | {r['length']} | `{r['opts']}` | {out_cell} "
            f"| {r['size']} | {r['lines']} | {r['note']} |")
    idx += [
        "",
        "## Skipped reference/entry-only records (no body)",
        "",
        "Name | Info word (octal) | Note",
        "|---|---|---|",
    ]
    for e in refs:
        idx.append(f"| {e['name']} | `{e.get('info_word_oct','')}` | "
                   f"{e.get('note','no body')} |")
    (HERE / "INDEX.md").write_text("\n".join(idx) + "\n", encoding="utf-8")

    # --- SPOTCHECK.txt -----------------------------------------------------
    picks = [("COPDCB", "small module"),
             ("LOOK", "large module, crosses a zone boundary"),
             ("ITPLBV", "largest module, spans three zones")]
    sp = [
        "Spot check of dtran output (first 20 lines of each .mad file)",
        "==============================================================",
        "",
    ]
    for name, why in picks:
        r = next((x for x in rows if x["name"] == name), None)
        sp += [f"--- {name} ({why}) ---"]
        if not r or r["out"] == "-":
            sp += ["NOT AVAILABLE (see FAILURES.txt)", ""]
            continue
        lines = (HERE / r["out"]).read_text(encoding="utf-8").splitlines()
        sample = lines[:20]
        banner_ok = bool(sample) and bool(re.match(r"^\s*\S+\s*:,NAME,", sample[0]))
        mnemonic_re = re.compile(r",(?:[A-Z][A-Z0-9+*/-]*),")
        mnemonics = sum(1 for ln in sample if mnemonic_re.search(ln))
        sp += [f"auto-check: NAME banner={banner_ok}, MADLEN-like directive/"
               f"mnemonic lines={mnemonics}/{len(sample)}", ""]
        sp += sample + [""]
    (HERE / "SPOTCHECK.txt").write_text("\n".join(sp) + "\n", encoding="utf-8")

    good = sum(1 for r in rows if r["out"] != "-")
    print(f"modules={len(modules)} disassembled={good} failures={len(failures)} "
          f"warnings={len(warnings)}")
    return 0 if good == len(modules) and not failures else 1


if __name__ == "__main__":
    sys.exit(main())
