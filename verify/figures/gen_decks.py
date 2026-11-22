#!/usr/bin/env python3
"""Generate the complex-figure decks with explicit numeric CALL MOVE/PLOT pairs.

Coordinates are precomputed here and written as literal numbers into each .
b6 deck; the decks have no arithmetic and no loops.  The same computation
writes expected.tsv, the machine-readable contract used by run.sh.

All coordinates are integer 0.1 mm steps: X in 0..5000, Y in 0..7500.
"""

import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))

HEADER = """шифр 419999 зс5^
DIS 41(2148)^
лен 60(2348)^
ееВ1а3
*name C1LINE
*call yesmemory
*perso:602300
*perso:602400,cont
*perso:602410,cont
*perso:602420,cont
*perso:602430,cont
*perso:602440,cont
*perso:602450,cont
*perso:602460,cont
*perso:602470,cont
*perso:602500,cont
*perso:602510,cont
*perso:602520,cont
*perso:602530,cont
*perso:602540,cont
*perso:602550,cont
*perso:602560,cont
*perso:602570,cont
*perso:602600,cont
*perso:602610,cont
*perso:602620,cont
*perso:602630,cont
*perso:602640,cont
*TRANS:FOREX3*,,411550
"""

FOOTER = """      CALL ENDPG()
      PRINT 900, NPLOT
  900 FORMAT(' NITI-C1 NPLOT=',I6)
      END
*execute
*end file
``````
еконец
"""


def star():
    pts = []
    for k in range(10):
        ang = math.radians(-90 + 36 * k)
        r = 400 if k % 2 == 0 else 160
        pts.append((round(500 + r * math.cos(ang)),
                    round(500 + r * math.sin(ang))))
    return pts


def circle():
    pts = []
    for k in range(24):
        ang = math.radians(15 * k)
        pts.append((round(500 + 300 * math.cos(ang)),
                    round(500 + 300 * math.sin(ang))))
    return pts


def spiral():
    n = 28
    pts = []
    for k in range(n):
        f = k / (n - 1)
        ang = 2 * math.pi * 3 * f
        r = 20 + 430 * f
        pts.append((round(500 + r * math.cos(ang)),
                    round(500 + r * math.sin(ang))))
    return pts


def sine():
    n = 28
    pts = []
    for k in range(n):
        f = k / (n - 1)
        x = round(50 + 900 * f)
        y = round(300 + 150 * math.sin(4 * math.pi * f))
        pts.append((x, y))
    return pts


def grid():
    pos = (150, 300, 450, 600, 750)
    pts = []
    for y in pos:
        pts.append((100, y))
        pts.append((800, y))
    for x in pos:
        pts.append((x, 100))
        pts.append((x, 800))
    return pts


def sawtooth():
    n = 25
    pts = []
    for k in range(n):
        x = round(60 + 880 * k / (n - 1))
        y = 200 if k % 2 == 0 else 700
        pts.append((x, y))
    return pts


FIGURES = (
    ("f01-star", star, "five-pointed star, outer R=400 inner r=160, center (500,500)"),
    ("f02-circle", circle, "regular 24-gon radius 300, center (500,500)"),
    ("f03-spiral", spiral, "Archimedean spiral, 3 turns, r=20..450"),
    ("f04-sine", sine, "two periods, X=50..950, Y=300+150*sin"),
    ("f05-grid", grid, "5 horizontal + 5 vertical lines"),
    ("f06-sawtooth", sawtooth, "25 points alternating Y=200/700"),
)


def main():
    manifest = []
    for name, fn, description in FIGURES:
        pts = fn()
        assert all(0 <= x <= 5000 and 0 <= y <= 7500 for x, y in pts), name
        assert len(set(pts)) == len(pts), name
        maxx = max(x for x, _ in pts)
        maxy = max(y for _, y in pts)

        lines = [HEADER]
        lines.append("C     %s - %s" % (name.upper(), description))
        lines.append("      PROGRAM C1LINE")
        lines.append("      COMMON /TRACE/ NEXC50, NEXC70, NEXC72, NEXC74, NPLOT")
        lines.append("      CALL PAGE()")
        for x, y in pts:
            lines.append("      CALL MOVE(%d.0,%d.0)" % (x, y))
            lines.append("      CALL PLOT()")
        lines.append(FOOTER)

        with open(os.path.join(HERE, name + ".b6"), "w", encoding="utf-8") as f:
            f.write("".join(line + "\n" for line in lines))

        # SVG geometry: width = maxX+2, height = maxY+1 (see EXPECTED.md).
        manifest.append((name, len(pts), maxx, maxy, maxx + 2, maxy + 1, description))
        print("%-14s points=%2d  maxX=%3d maxY=%3d  WxH=%dx%d" %
              (name, len(pts), maxx, maxy, maxx + 2, maxy + 1))

    with open(os.path.join(HERE, "expected.tsv"), "w", encoding="utf-8") as f:
        f.write("# name\tpoints\tmaxX\tmaxY\texpW\texpH\tdescription\n")
        for row in manifest:
            f.write("\t".join(str(v) for v in row) + "\n")


if __name__ == "__main__":
    main()
