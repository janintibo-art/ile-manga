"""V147 : les sons des tables de jeu de Pile-ou-Face (synthétisés ici ; versés au domaine public, CC0 1.0).

  sfx/jetons_1..3    des jetons qu'on pose ou qu'on ramasse : quelques claquements secs, bois et argile.
  sfx/gobelet_1..2   un gobelet de cuir qu'on secoue : des dés qui s'entrechoquent dedans, étouffés, puis
                     le gobelet qu'on retourne sur la table.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v147.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
from generate_sons_v135 import SR, t_, env, fin, place  # noqa: E402

RNG = np.random.default_rng(14747)


def clic(f, dur=0.06, decay=110.0, bruit=0.7):
    n = int(dur * SR)
    t = t_(n)
    s = amb.bp(RNG.standard_normal(n), f * 0.6, f * 2.2) * np.exp(-t * decay) * bruit
    s += np.sin(2 * np.pi * f * t + RNG.uniform(0, 6.28)) * np.exp(-t * decay * 0.8) * 0.5
    s += np.sin(2 * np.pi * f * 1.73 * t) * np.exp(-t * decay * 1.2) * 0.25
    return s


def jetons(k):
    n = int(0.7 * SR)
    out = np.zeros(n)
    nb = [5, 7, 9][k - 1]
    at = 0.0
    for i in range(nb):
        f = RNG.uniform(1900, 3100)
        place(out, clic(f) * RNG.uniform(0.45, 0.9), at)
        at += RNG.uniform(0.025, 0.07)
    return fin(out, 200) * 0.8


def gobelet(k):
    n = int(1.3 * SR)
    out = np.zeros(n)
    # les dés qui cognent dans le cuir (étouffés)
    at = 0.02
    while at < 0.85:
        c = clic(RNG.uniform(700, 1300), 0.05, 140.0, 0.9)
        place(out, amb.lp(c, 1800) * RNG.uniform(0.35, 0.8), at)
        at += RNG.uniform(0.035, 0.09)
    # le cuir qui frotte
    m = int(0.85 * SR)
    tm = t_(m)
    cuir = amb.bp(RNG.standard_normal(m), 300, 1200) * (0.5 + 0.5 * np.sin(2 * np.pi * (6.0 + k) * tm)) ** 2 * 0.12 * env(m, 0.05, 0.1)
    place(out, cuir, 0.0)
    # le gobelet retourné sur le feutre : un « toc » sourd
    place(out, amb.lp(clic(180.0, 0.18, 30.0, 1.0), 900) * 0.9, 0.95)
    return fin(out, 150) * 0.85


CAT = {"jetons": (jetons, 3), "gobelet": (gobelet, 2)}


def main() -> int:
    total = 0
    for name, (fn, count) in CAT.items():
        for k in range(1, count + 1):
            fx.save(f"{name}_{k}", fn(k))
            total += 1
    print(f"V147 : {total} sons écrits dans {fx.OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
