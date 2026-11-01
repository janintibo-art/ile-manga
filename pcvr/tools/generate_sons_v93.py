"""V93 : les sons du Festival du Larsen (synthétisés ici, versés au domaine public, CC0 1.0).

  sfx/artifice_sifflet_1..2  une fusée de feu d'artifice qui monte : le souffle de la poudre et un
                             sifflement qui grimpe, puis s'éteint.
  sfx/artifice_boum_1..3     l'éclatement : le coup sourd dans la poitrine, l'écho sur la mer, et les
                             étincelles qui crépitent en retombant.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v93.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
import generate_sons_v58 as s58  # noqa: E402

SR = 44100
RNG = np.random.default_rng(9393)


def sifflet(k: int) -> np.ndarray:
    dur = 1.6
    n = int(dur * SR)
    x = np.arange(n) / SR
    env = np.clip(x / 0.05, 0, 1) * np.clip((dur - x) / 0.5, 0, 1)
    # le souffle de la poudre (un bruit qui s'éclaircit en montant)
    souffle = amb.bp(RNG.standard_normal(n), 600.0 + 300.0 * k, 4000.0) * 0.35 * np.exp(-x / 1.1)
    # le sifflement : une note qui grimpe, avec un peu de tremblement
    f = (1100.0 + 250.0 * k) + 1700.0 * (x / dur) ** 0.8 + 40.0 * np.sin(2 * np.pi * 13.0 * x)
    ph = 2 * np.pi * np.cumsum(f) / SR
    sif = (np.sin(ph) + 0.25 * np.sin(2 * ph)) * 0.45 * np.clip((x - 0.08) / 0.2, 0, 1)
    y = (souffle + sif) * env
    return y


def boum(k: int) -> np.ndarray:
    dur = 3.4
    n = int(dur * SR)
    x = np.arange(n) / SR
    # le coup sourd : un bruit grave très court et une onde basse qui tombe
    m = int(0.35 * SR)
    coup = amb.lp(RNG.standard_normal(m), 260.0 + 60.0 * k, 4) * np.exp(-np.arange(m) / SR / 0.07) * 3.0
    f0 = 62.0 - 8.0 * k
    onde = np.sin(2 * np.pi * np.cumsum(f0 * np.exp(-x[:m] / 0.25)) / SR) * np.exp(-x[:m] / 0.12) * 1.4
    y = np.zeros(n)
    y[:m] += coup + onde
    # l'écho sur la mer, un peu plus tard, plus doux
    d = int((0.42 + 0.08 * k) * SR)
    y[d:d + m] += (coup * 0.35)[: n - d]
    # les étincelles qui crépitent en retombant
    nb = 180 + 60 * k
    for _ in range(nb):
        t = RNG.uniform(0.15, 2.6)
        i = int(t * SR)
        l = int(RNG.uniform(0.002, 0.008) * SR)
        if i + l >= n:
            continue
        g = RNG.uniform(0.05, 0.22) * np.exp(-(t - 0.15) / 1.4)
        y[i:i + l] += amb.hp(RNG.standard_normal(l), 2500.0) * np.exp(-np.arange(l) / l * 4.0) * g
    y = np.tanh(y * 0.9)
    st = s58._room(np.stack([y, np.roll(y, 37)], 1), 2.8, 2.2, 5000.0, 0.35, seed=930 + k)
    return st[:, 0] * 0.5 + st[:, 1] * 0.5


def main() -> int:
    for k in range(2):
        fx.save(f"artifice_sifflet_{k + 1}", s58._norm(sifflet(k), 0.7))
    for k in range(3):
        fx.save(f"artifice_boum_{k + 1}", s58._norm(boum(k)))
    print("V93 : les sons du Festival du Larsen sont faits")
    return 0


if __name__ == "__main__":
    sys.exit(main())
