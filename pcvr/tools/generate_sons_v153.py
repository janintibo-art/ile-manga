"""V153 : les sons des tours de Néopolis (synthétisés ici ; versés au domaine public, CC0 1.0).

  sfx/ding_ascenseur_1..2  le carillon de l'ascenseur à l'arrivée (deux notes douces).
  sfx/toc_porte_1..3       trois coups frappés à une porte d'appartement.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v153.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
from generate_sons_v135 import SR, t_, env, fin, place  # noqa: E402

RNG = np.random.default_rng(15353)


def cloche(f, dur=1.2):
    n = int(dur * SR)
    t = t_(n)
    s = np.sin(2 * np.pi * f * t) * np.exp(-t * 3.0)
    s += 0.35 * np.sin(2 * np.pi * f * 2.0 * t) * np.exp(-t * 5.0)
    s += 0.15 * np.sin(2 * np.pi * f * 3.01 * t) * np.exp(-t * 8.0)
    return s * env(n, 0.005, 0.2)


def ding(k):
    n = int(1.8 * SR)
    out = np.zeros(n)
    f1, f2 = (880.0, 698.5) if k == 1 else (987.8, 784.0)
    place(out, cloche(f1), 0.0)
    place(out, cloche(f2), 0.32)
    return fin(out, 300) * 0.55


def toc(k):
    n = int(1.2 * SR)
    out = np.zeros(n)
    at = 0.02
    for i in range(3):
        m = int(0.12 * SR)
        t = t_(m)
        f = RNG.uniform(140, 190)
        coup = np.sin(2 * np.pi * f * t) * np.exp(-t * 40.0) + amb.lp(RNG.standard_normal(m), 900) * np.exp(-t * 70.0) * 0.6
        place(out, coup * RNG.uniform(0.75, 1.0), at)
        at += RNG.uniform(0.17, 0.24)
    return fin(out, 200) * 0.8


CAT = {"ding_ascenseur": (ding, 2), "toc_porte": (toc, 3)}


def main() -> int:
    total = 0
    for name, (fn, count) in CAT.items():
        for k in range(1, count + 1):
            fx.save(f"{name}_{k}", fn(k))
            total += 1
    print(f"V153 : {total} sons écrits dans {fx.OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
