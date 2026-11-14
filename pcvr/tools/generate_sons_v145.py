"""V145 : les sons de la roue des sorts (synthétisés ici ; versés au domaine public, CC0 1.0).

  sfx/roue_ouvre_1..2   la roue s'ouvre : un frisson de clochettes qui monte, très doux.
  sfx/roue_tic_1..3     un sort survolé : un petit tintement de verre.
  sfx/geste_magie_1..2  le geste qui lance un sort en VR : un souffle qui file, une étincelle.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v145.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
from generate_sons_v135 import SR, t_, env, fin, place  # noqa: E402

RNG = np.random.default_rng(14545)


def clochette(f, dur, decay):
    n = int(dur * SR)
    t = t_(n)
    s = np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * f * 2.76 * t) + 0.2 * np.sin(2 * np.pi * f * 5.4 * t)
    return s * np.exp(-t * decay) * env(n, 0.003, 0.05)


def roue_ouvre(k):
    n = int(0.75 * SR)
    out = np.zeros(n)
    notes = [880, 1108.7, 1318.5, 1760] if k == 1 else [784, 987.8, 1174.7, 1568]
    for i, f in enumerate(notes):
        place(out, clochette(f * RNG.uniform(0.997, 1.003), 0.6, 7.0) * (0.5 + 0.1 * i), 0.035 * i)
    m = int(0.4 * SR)
    place(out, amb.bp(RNG.standard_normal(m), 3000, 9000) * env(m, 0.1, 0.25) * 0.08, 0.0)
    return fin(out, 200) * 0.8


def roue_tic(k):
    n = int(0.16 * SR)
    out = clochette(RNG.uniform(2200, 2900), 0.16, 32.0)
    out += amb.hp(RNG.standard_normal(n), 5000) * np.exp(-t_(n) * 120) * 0.15
    return fin(out, 300) * 0.7


def geste_magie(k):
    n = int(0.55 * SR)
    t = t_(n)
    blocs = 10
    out = np.zeros(n)
    for b in range(blocs):
        i0 = b * n // blocs
        i1 = (b + 1) * n // blocs
        fc = 900 + 3500 * b / blocs
        out[i0:i1] += amb.bp(RNG.standard_normal(i1 - i0 + 400), fc * 0.6, min(fc * 1.7, 11000))[200:200 + i1 - i0]
    out *= env(n, 0.05, 0.3) * np.exp(-t * 2.0)
    place(out, clochette(RNG.uniform(1700, 2100), 0.4, 12.0) * 0.35, 0.12)
    return fin(out, 120)


CAT = {"roue_ouvre": (roue_ouvre, 2), "roue_tic": (roue_tic, 3), "geste_magie": (geste_magie, 2)}


def main() -> int:
    total = 0
    for name, (fn, count) in CAT.items():
        for k in range(1, count + 1):
            fx.save(f"{name}_{k}", fn(k))
            total += 1
    print(f"V145 : {total} sons écrits dans {fx.OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
