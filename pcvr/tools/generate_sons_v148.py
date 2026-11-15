"""V148 : les sons du Tripot de la Dame de Pique (synthétisés ici ; versés au domaine public, CC0 1.0).

  sfx/carte_1..3          une carte qu'on distribue : elle glisse sur le feutre (un souffle de papier, un
                          petit claquement à l'arrivée).
  sfx/cartes_battre_1..2  on bat les cartes : le « frrrrt » du mélange en queue d'aronde, puis le paquet
                          qu'on tapote sur la table.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v148.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
from generate_sons_v135 import SR, t_, env, fin, place  # noqa: E402

RNG = np.random.default_rng(14848)


def claque(f, dur=0.04, decay=160.0, g=0.6):
    n = int(dur * SR)
    t = t_(n)
    return amb.bp(RNG.standard_normal(n), f * 0.5, f * 2.0) * np.exp(-t * decay) * g


def carte(k):
    n = int(0.35 * SR)
    out = np.zeros(n)
    m = int(RNG.uniform(0.16, 0.22) * SR)
    tm = t_(m)
    souffle = amb.bp(RNG.standard_normal(m), 2500, 9000) * env(m, 0.03, 0.06) * (0.6 + 0.4 * np.sin(2 * np.pi * 5 * tm)) * 0.35
    place(out, souffle, 0.0)
    place(out, claque(RNG.uniform(1800, 2600)), m / SR - 0.01)
    return fin(out, 250) * 0.7


def cartes_battre(k):
    n = int(1.6 * SR)
    out = np.zeros(n)
    at = 0.05
    nb = 46 + 10 * k
    for i in range(nb):
        place(out, claque(RNG.uniform(2500, 4200), 0.02, 260.0, RNG.uniform(0.25, 0.5)), at)
        at += RNG.uniform(0.012, 0.02) * (1.0 + 0.6 * i / nb)
    # le paquet qu'on égalise : deux petits coups sourds
    for d in (0.25, 0.4):
        place(out, amb.lp(claque(500.0, 0.08, 60.0, 1.0), 1500) * 0.9, at + d)
    return fin(out, 200) * 0.75


CAT = {"carte": (carte, 3), "cartes_battre": (cartes_battre, 2)}


def main() -> int:
    total = 0
    for name, (fn, count) in CAT.items():
        for k in range(1, count + 1):
            fx.save(f"{name}_{k}", fn(k))
            total += 1
    print(f"V148 : {total} sons écrits dans {fx.OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
