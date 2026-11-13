"""V139 : les cris de la faune des îles des villes (synthétisés ici ; versés au domaine public, CC0 1.0).

  sfx/chat_crache_1..2       le chat en colère : un souffle rauque, un « khhh » qui siffle.
  sfx/rat_couine_1..2        les rats : de petits couinements aigus, en rafale.
  sfx/canard_cancan_1..2     la cane : deux ou trois « coin-coin » nasillards.
  sfx/caneton_piaille_1..2   les canetons : de petits « piou » aigus.
(Le chat miaule et ronronne avec les sons déjà dans le jeu, sfx/chat_miaou_* et sfx/ronron_* ;
les pigeons roucoulent avec sfx/pigeon_* et s'envolent avec sfx/ailes_*.)
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v139.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
from generate_sons_v135 import SR, t_, env, fin, voix, place  # noqa: E402

RNG = np.random.default_rng(13939)


def crache(k):
    dur = RNG.uniform(0.7, 0.9)
    n = int(dur * SR)
    u = np.linspace(0, 1, n)
    souffle = amb.bp(RNG.standard_normal(n), 2500, 9000) * (np.minimum(u * 12.0, 1.0) * (1.0 - u) ** 0.6)
    # un grondement sourd sous le souffle, et le petit claquement du début
    m = int(0.5 * SR)
    g = voix(RNG.uniform(110, 140) * np.ones(m), [(1, 1.0), (2, 0.6), (3, 0.4)], jitter=0.1) * env(m, 0.03, 0.2) * 0.25
    out = souffle
    place(out, g, 0.05)
    c = int(0.03 * SR)
    place(out, amb.bp(RNG.standard_normal(c), 1500, 6000) * np.linspace(1, 0, c) * 1.5, 0.0)
    return fin(out, 300)


def rat(k):
    dur = 0.8
    out = np.zeros(int(dur * SR))
    tt = 0.02
    for j in range(RNG.integers(3, 6)):
        d = RNG.uniform(0.04, 0.09)
        m = int(d * SR)
        u = np.linspace(0, 1, m)
        f = RNG.uniform(3000, 4200) * (1.0 + 0.15 * np.sin(np.pi * u) - 0.1 * u)
        y = voix(f, [(1, 1.0), (2, 0.3)], jitter=0.02)
        place(out, y * np.sin(np.pi * u) ** 0.7 * RNG.uniform(0.5, 1.0), tt)
        tt += d + RNG.uniform(0.03, 0.12)
        if tt > dur - 0.1:
            break
    return fin(out, 1500) * 0.7


def cancan(k):
    dur = 1.1
    out = np.zeros(int(dur * SR))
    tt = 0.02
    for j in range(RNG.integers(2, 4)):
        d = RNG.uniform(0.16, 0.22)
        m = int(d * SR)
        u = np.linspace(0, 1, m)
        f = RNG.uniform(380, 450) * (1.0 + 0.12 * np.sin(np.pi * u) - 0.15 * u)
        y = voix(f, [(1, 0.5), (2, 1.0), (3, 1.0), (4, 0.8), (5, 0.6), (6, 0.5), (8, 0.3)], jitter=0.05)
        nasal = amb.bp(y, 700, 3200) + amb.bp(RNG.standard_normal(m), 900, 2500) * 0.15
        place(out, nasal * np.sin(np.pi * u) ** 0.4, tt)
        tt += d + RNG.uniform(0.05, 0.1)
        if tt > dur - 0.25:
            break
    return fin(out, 200)


def caneton(k):
    dur = 0.9
    out = np.zeros(int(dur * SR))
    tt = 0.02
    for j in range(RNG.integers(2, 5)):
        d = RNG.uniform(0.07, 0.11)
        m = int(d * SR)
        u = np.linspace(0, 1, m)
        f = RNG.uniform(2800, 3400) * (1.0 + 0.25 * u - 0.35 * u ** 2)
        y = voix(f, [(1, 1.0), (2, 0.25)])
        place(out, y * np.sin(np.pi * u) ** 0.6 * RNG.uniform(0.6, 1.0), tt)
        tt += d + RNG.uniform(0.06, 0.16)
        if tt > dur - 0.12:
            break
    return fin(out, 1200) * 0.6


CAT = {
    "chat_crache": (crache, 2), "rat_couine": (rat, 2), "canard_cancan": (cancan, 2), "caneton_piaille": (caneton, 2),
}


def main() -> int:
    total = 0
    for name, (fn, count) in CAT.items():
        for k in range(1, count + 1):
            fx.save(f"{name}_{k}", fn(k))
            total += 1
    print(f"V139 : {total} sons écrits dans {fx.OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
