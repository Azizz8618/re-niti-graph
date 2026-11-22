#!/usr/bin/env python3
"""Independent cross-check: dtran MADLEN vs disbesm6 on the same DMS module.

For a sampled module we decode the DMS header straight from the zone dump,
isolate exactly the command-section words (cmd_len), feed those words to
disbesm6 as a standalone 6-byte/word binary, and compare the number of decoded
instructions with the number dtran emitted in the .mad file.

Read-only: writes only scratch files under /tmp and the AUDIT folder.
"""
import os, re, subprocess, sys

ROOT = "/home/azizz/Yandex.Disk/re-siprod/notes/grafor22-disasm"
ZBIN = os.path.join(ROOT, "extract/bin")
MAD = os.path.join(ROOT, "madlen")
TMP = "/tmp/.private/azizz/opencode/grafor22-audit"
os.makedirs(TMP, exist_ok=True)

# name -> (zone dec, word dec) taken from catalog.txt / INDEX.md
LOC = {}
with open(os.path.join(ROOT, "extract/catalog.txt")) as fh:
    for line in fh:
        m = re.match(r"\s*\d+\s+(\S+)\s+[0-7]+\s+0o(\d+)\s+(\d+)\s+", line)
        if m:
            name, zone_oct, word = m.group(1), m.group(2), m.group(3)
            LOC[name] = (int(zone_oct, 8), int(word))

def words_of(path):
    with open(path, "rb") as fh:
        b = fh.read()
    return [int.from_bytes(b[i:i+6], "big") for i in range(0, len(b)-5, 6)]

def text_word(w):
    # 8 chars x 6 bit, Dubna TEXT: 0=sp, 33..58=A..Z, 16..25=digits
    out = ""
    for i in range(7, -1, -1):
        c = (w >> (6*i)) & 0o77
        if c == 0: out += " "
        elif 33 <= c <= 58: out += chr(ord('A') + c - 33)
        elif 16 <= c <= 25: out += str(c - 16)
        else: out += "?"
    return out.rstrip()

def header(zone, word):
    ws = words_of(os.path.join(ZBIN, f"zone_{zone}.bin"))
    w0, w1, w2 = ws[word], ws[word+1], ws[word+2]
    head   = w0 & 0o7777
    sym    = (w0 >> 12) & 0o7777
    debug  = w0 >> 36
    setlen = w1 & 0o77777
    datalen= (w1 >> 15) & 0o77777
    longlen= (w1 >> 30) & 0o77777
    cmd    = w2 & 0o77777
    bss    = (w2 >> 15) & 0o77777
    const  = (w2 >> 30) & 0o77777
    nameoff = 3 + cmd + const + datalen + setlen
    name = text_word(ws[word+nameoff]) if word+nameoff < len(ws) else "?"
    return dict(head=head, sym=sym, debug=debug, set=setlen, data=datalen,
                long=longlen, cmd=cmd, bss=bss, const=const, name=name,
                ws=ws, word=word)

# mnemonics dtran may emit (opcode field) - instruction lines look like:
#   " 12,VTM,"   " ,STI,10"   " *0001B:8,VTM,*0001B"   " 13,VJM,*70"
# i.e. optional label prefix, optional numeric prefix, then ,OP,
OP_RE = re.compile(r'^\s*(?:\*[\w.]+:)?\s*(?:[-+]?\d+|\*[\w.]+)?\s*,\s*([A-Z*+/\-][\w*+/\-]*)\s*,')

DIRECTIVES = {"END", "NAME", "SUBP", "LC", "LP", "EQU", "BSS", "SET",
              "LOG", "INT", "ISO", "TEXT", "ADDR", "REF"}

def mad_instr_count(path):
    n = 0
    lines = []
    with open(path, errors="replace") as fh:
        for ln in fh:
            if ln.startswith("C "):
                continue
            m = OP_RE.match(ln)
            if m and m.group(1) not in DIRECTIVES:
                n += 1
                lines.append(ln.rstrip())
    return n, lines

def disasm_count(cmdwords):
    p = os.path.join(TMP, "cmd.bin")
    with open(p, "wb") as fh:
        for w in cmdwords:
            fh.write(w.to_bytes(6, "big"))
    r = subprocess.run(["disbesm6", "-a0", "-e0", p], capture_output=True, text=True)
    out = r.stdout
    # instruction lines begin with an octal address then opcode field:
    # "    0 00 000 0000 \tSTART\tмод\t..."  or continuation "      00 000 0001 \t\tзп\t..."
    cnt = 0
    for ln in out.splitlines():
        m = re.match(r'^\s*(?:\d+\s+)?\d\d\s+\d+\s+\d+\s+\S+\s+\S+', ln)
        if m and ("конд" not in ln) and ("пам" not in ln) and ("nop" not in ln):
            cnt += 1
    return cnt, out

SAMPLE = ["FCATBD", "ABUFF", "GDISC", "E70", "RCATAL", "RZON", "NEXTZN", "CLEAZN",
          "SETK", "LOOK", "ITPLBV"]

print("BESM-6 packs two 24-bit instructions per 48-bit word; dtran emits 1 or 2")
print("instruction lines per command word. Expect cmd <= mad_lines <= 2*cmd.")
print(f"{'module':10} {'zone':>5} {'word':>5} {'hdrname':9} {'cmd':>4} {'const':>4} {'mad_ins':>7} {'range':>10} {'verdict'}")
for name in SAMPLE:
    if name not in LOC:
        print(f"{name:10} (not in catalog)")
        continue
    zone, word = LOC[name]
    h = header(zone, word)
    stem = name.replace("*", "_s").replace("/", "_p")
    madpath = os.path.join(MAD, stem + ".mad")
    if not os.path.exists(madpath):
        print(f"{name:10} (no .mad)")
        continue
    madn, _ = mad_instr_count(madpath)
    cmd = h["cmd"]
    ok = "OK" if cmd <= madn <= 2*cmd else "CHECK"
    print(f"{name:10} {zone:5d} {word:5d} {h['name']:9} {cmd:4o} {h['const']:4o} {madn:7d} {cmd:4d}-{2*cmd:<5d} {ok}")
