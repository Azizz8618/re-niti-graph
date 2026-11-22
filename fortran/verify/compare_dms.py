#!/usr/bin/env python3
"""Byte/word comparison of a FOREX-compiled DMS module with the original.

Usage: compare_dms.py ORIGINAL.bin COMPILED_PERSO.bin [start_word]

ORIGINAL is madlen/bin/<NAME>.bin (exact DMS slice from volume 2048).
COMPILED_PERSO is a dump of the PERSO library zone produced by *to perso.
start_word defaults to 2048 (first word of the second catalog zone).
"""
import sys
from pathlib import Path


def words(path, offset_words=0):
    data = Path(path).read_bytes()
    return [int.from_bytes(data[i:i + 6], "big")
            for i in range(offset_words * 6, len(data) - 5, 6)]


def fields(w):
    return (w & 0o7777, (w >> 12) & 0o7777,
            (w >> 24) & 0o7777, (w >> 36) & 0o7777)


def header(ws):
    h0, h1, h2 = fields(ws[0]), fields(ws[1]), fields(ws[2])
    return {
        "head": h0[0], "sym": h0[1], "debug": h0[3],
        "set": h1[0], "data": h1[1], "long": h1[2],
        "cmd": h2[0], "bss": h2[1], "const": h2[2],
    }


def main():
    if len(sys.argv) < 3:
        sys.exit("usage: compare_dms.py ORIG.bin COMPILED.bin [start_word]")
    orig = words(sys.argv[1])
    new = words(sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 2048)
    ho, hn = header(orig), header(new)

    print("field       original   compiled   equal")
    for k in ("head", "sym", "debug", "set", "data", "long",
              "cmd", "bss", "const"):
        a, b = ho[k], hn[k]
        print(f"{k:10} {a:9o} {b:9o} {'YES' if a == b else 'no'}")

    # Sections: header(3) | cmd | const | data | set
    lo = 3 + ho["cmd"] + ho["const"] + ho["data"] + ho["set"]
    ln = 3 + hn["cmd"] + hn["const"] + hn["data"] + hn["set"]
    a, b = orig[:lo], new[:ln]
    n = min(len(a), len(b))
    same = sum(1 for i in range(n) if a[i] == b[i])
    first = next((i for i in range(n) if a[i] != b[i]), None)
    print(f"\nmodule words: original={lo} compiled={ln}")
    print(f"identical words: {same}/{n} ({100.0 * same / n:.1f}%)")
    if first is not None:
        print(f"first difference: word {first}: "
              f"{a[first]:016o} != {b[first]:016o}")
    print(f"final verdict: {'BYTE-IDENTICAL' if a == b else 'DIFFERENT'}")


if __name__ == "__main__":
    main()
