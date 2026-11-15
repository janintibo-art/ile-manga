"""V155 : les sons des quartiers de Néopolis (synthétisés ici ; versés au domaine public, CC0 1.0).

  sfx/friture_wok_1..2  la friture d'un wok au comptoir de nouilles (le grésillement, quelques crépitements).
  sfx/karaoke_1..2      un petit air de karaoké, au loin derrière les vitres (une mélodie, une basse, un battement).
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v155.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
from generate_sons_v135 import SR, t_, env, fin, place  # noqa: E402

RNG = np.random.default_rng(15555)


def friture(k):
    n = int(2.6 * SR)
    s = amb.bp(RNG.standard_normal(n), 2500, 9000) * 0.25
    s *= 0.7 + 0.3 * amb.smooth_env(n, 6.0, 0.0, 1.0)
    for i in range(int(60 + 25 * k)):
        m = int(0.012 * SR)
        c = amb.hp(RNG.standard_normal(m), 1800) * np.exp(-t_(m) * 300.0) * RNG.uniform(0.3, 1.0)
        place(s, c, RNG.uniform(0.0, 2.55))
    return fin(s * env(n, 0.15, 0.6), 400) * 0.8


def note(f, dur, forme="carre"):
    n = int(dur * SR)
    t = t_(n)
    if forme == "carre":
        s = np.sign(np.sin(2 * np.pi * f * t)) * 0.5 + 0.5 * np.sin(2 * np.pi * f * t)
    else:
        s = np.sin(2 * np.pi * f * t)
    return amb.lp(s, 3200) * env(n, 0.01, dur * 0.4)


def karaoke(k):
    tempo = 0.24
    n = int(3.4 * SR)
    out = np.zeros(n)
    # do majeur ; deux airs
    gammes = {1: [523.3, 587.3, 659.3, 784.0, 659.3, 587.3, 523.3, 659.3, 784.0, 880.0, 784.0, 659.3],
              2: [659.3, 659.3, 784.0, 880.0, 784.0, 659.3, 587.3, 523.3, 587.3, 659.3, 587.3, 523.3]}
    for i, f in enumerate(gammes[k]):
        place(out, note(f, tempo * 0.95) * 0.32, i * tempo)
    for i in range(7):
        place(out, note([130.8, 98.0, 110.0, 87.3, 130.8, 98.0, 130.8][i], tempo * 1.9, "sinus") * 0.4, i * tempo * 2)
    for i in range(14):
        m = int(0.08 * SR)
        place(out, amb.lp(RNG.standard_normal(m), 200 if i % 2 == 0 else 5000) * np.exp(-t_(m) * 40.0) * (0.5 if i % 2 == 0 else 0.15), i * tempo)
    # au loin, derrière une vitre
    out = amb.lp(out, 2400)
    return fin(out * env(n, 0.05, 0.5), 80) * 0.7


CAT = {"friture_wok": (friture, 2), "karaoke": (karaoke, 2)}


def main() -> int:
    total = 0
    for name, (fn, count) in CAT.items():
        for k in range(1, count + 1):
            fx.save(f"{name}_{k}", fn(k))
            total += 1
    print(f"V155 : {total} sons écrits dans {fx.OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
