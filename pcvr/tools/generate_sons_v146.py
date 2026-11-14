"""V146 : les sons de l'Île Perchée (synthétisés ici ; versés au domaine public, CC0 1.0).

  sfx/cloche_chaine_1..2   la cloche de la Grande Chaîne : deux coups de cloche de bronze, le départ.
  sfx/cliquet_roue_1..3    le cliquet de la Roue de la Fortune : un claquement de bois sur un clou de laiton.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v146.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
from generate_sons_v135 import SR, t_, env, fin, place  # noqa: E402

RNG = np.random.default_rng(14646)


def cloche(f, dur, decay):
    """Une cloche de bronze : les partiels d'une cloche (hum, prime, tierce mineure, quinte, octave)."""
    n = int(dur * SR)
    t = t_(n)
    s = np.zeros(n)
    for ratio, amp, dec in [(0.5, 0.5, 0.6), (1.0, 1.0, 1.0), (1.19, 0.6, 1.3), (1.5, 0.45, 1.6), (2.0, 0.5, 2.0), (2.74, 0.25, 3.0), (3.4, 0.15, 4.0)]:
        s += amp * np.sin(2 * np.pi * f * ratio * t + RNG.uniform(0, 6.28)) * np.exp(-t * decay * dec)
    strike = amb.bp(RNG.standard_normal(n), 1500, 6000) * np.exp(-t * 60.0) * 0.4
    return (s + strike) * env(n, 0.002, 0.2)


def cloche_chaine(k):
    n = int(2.6 * SR)
    out = np.zeros(n)
    f = 392.0 if k == 1 else 349.2
    place(out, cloche(f * RNG.uniform(0.997, 1.003), 2.0, 1.4) * 0.6, 0.0)
    place(out, cloche(f * RNG.uniform(0.997, 1.003), 2.0, 1.4) * 0.55, 0.55)
    # le grincement de la chaîne qui se tend
    m = int(0.9 * SR)
    tm = t_(m)
    gr = amb.bp(RNG.standard_normal(m), 600, 2200) * (0.5 + 0.5 * np.sin(2 * np.pi * 7.0 * tm)) * env(m, 0.2, 0.3) * 0.12
    place(out, gr, 1.4)
    return fin(out, 80) * 0.9


def cliquet_roue(k):
    n = int(0.12 * SR)
    t = t_(n)
    clac = amb.bp(RNG.standard_normal(n), 900, 4200) * np.exp(-t * 90.0)
    tinte = np.sin(2 * np.pi * RNG.uniform(1800, 2300) * t) * np.exp(-t * 55.0) * 0.35
    bois = np.sin(2 * np.pi * RNG.uniform(260, 320) * t) * np.exp(-t * 70.0) * 0.5
    return fin(clac + tinte + bois, 300) * 0.8


CAT = {"cloche_chaine": (cloche_chaine, 2), "cliquet_roue": (cliquet_roue, 3)}


def main() -> int:
    total = 0
    for name, (fn, count) in CAT.items():
        for k in range(1, count + 1):
            fx.save(f"{name}_{k}", fn(k))
            total += 1
    print(f"V146 : {total} sons écrits dans {fx.OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
