#!/usr/bin/env python3
"""Decode library 22 (ГРАФОР-СУД) catalog in zone 0o1100 of volume 2048.

Info-word format (calibrated, see re-siprod/pascal/README/ПЛАН-ОЗУ.md p.7):
  4 x 12-bit fields [A][B][C][D]
  A = 0o2000 + carry + word + 8          (carry = 1 if relzone >= 0o40)
  B = (relzone + 0o40) & 0o77
  C = load * 8
  D = 0
"""
import json
import os
import sys

sys.path.insert(0, "/home/azizz/Yandex.Disk/re-siprod/tools")
from vol import Volume, text_decode, encode_word

VOL = "/usr/local/share/besm6/2048"
CATZ = 0o1100          # library 22 catalog zone (decimal 576)
BASE = 0o2000          # personal-library base
FUL = (1 << 48) - 1    # 0o7777777777777777 terminator

M15 = 0o77777

v = Volume(VOL)


def plausible(s):
    letters = set(" ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789*/-.+()ЦДФГИЙЛЯЖЬПЫЗШЭЩЧЮБ")
    return bool(s) and all(c in letters for c in s)


def dms_header(z, w):
    if w + 3 >= 1024:
        return None
    w0, w1, w2 = (v.word(z, w + k) for k in range(3))
    if w0 & 0o7777 != 1:
        return None
    cmd, cst = w2 & M15, (w2 >> 30) & 0o7777
    if cmd + cst == 0 or cmd + cst > 40000:
        return None
    return dict(head=w0 & 0o7777, sym=(w0 >> 12) & 0o7777,
                set_=w1 & 0o7777, data=(w1 >> 15) & 0o7777,
                cmd=cmd, const=cst, load=cmd + cst)


def decode():
    ws, _ = v.zone_words(CATZ)
    out = []
    for idx, i in enumerate(range(2, 1022, 2)):
        nmw, inf = ws[i], ws[i + 1]
        if nmw == 0 or inf == FUL:
            break
        name = text_decode(nmw).rstrip()
        if not plausible(name):
            break
        A = (inf >> 36) & 0xFFF
        B = (inf >> 30) & 0x3F
        C = (inf >> 12) & 0x3FFFF
        D = inf & 0xFFF
        e = dict(idx=idx, cat_word=i, name=name, info=inf,
                 info_oct="%016o" % inf, A=A, B=B, C=C, D=D)
        if inf < 0o10000 and A == 0 and B == 0 and C == 0:
            # alias / entry-point reference: small ordinal, no body
            e["kind"] = "ref"
            e["ref"] = inf
        else:
            relzone = (B - 0o40) & 0o77
            carry = 1 if relzone >= 0o40 else 0
            word = A - BASE - carry - 8
            zone = CATZ + relzone
            load = C // 8
            e.update(kind="module", relzone=relzone, carry=carry,
                     zone=zone, word=word, load=load)
            h = dms_header(zone, word)
            e["verified"] = False
            if h:
                # DMS head name follows cmd, const, data and set sections
                off = word + 3 + h["cmd"] + h["const"] + h["data"] + h["set_"]
                zz, ww = zone + off // 1024, off % 1024
                hname = text_decode(v.word(zz, ww)).rstrip()
                e["head_name"] = hname
                e["head_zone"] = zz
                e["head_word"] = ww
                e["hdr"] = h
                e["hdr_load"] = h["load"]
                e["hdr_total"] = h["load"] + h["data"] + h["set_"]
                e["verified"] = (hname == name)
                e["load_matches"] = (h["load"] == load)
        out.append(e)
    return out


if __name__ == "__main__":
    ents = decode()
    mods = [e for e in ents if e["kind"] == "module"]
    refs = [e for e in ents if e["kind"] == "ref"]
    print("total=%d modules=%d refs=%d" % (len(ents), len(mods), len(refs)))
    ok = [e for e in mods if e["verified"]]
    bad = [e for e in mods if not e["verified"]]
    print("verified=%d failed=%d" % (len(ok), len(bad)))
    for e in bad:
        print("  FAIL %-9s info=%s zone=%04o word=%4d load=%d head=%r hdr=%s" %
              (e["name"], e["info_oct"], e["zone"], e["word"], e["load"],
               e.get("head_name"), e.get("hdr")))
    zones = sorted({e["zone"] for e in mods})
    print("body zones:", " ".join("%04o(%d)" % (z, z) for z in zones))
    print("zone range %04o..%04o" % (zones[0], zones[-1]))
    print("refs:", ", ".join("%s->%o" % (e["name"], e["ref"]) for e in refs))
