"""V137 : les cris de la faune des îles du ciel (synthétisés ici ; versés au domaine public, CC0 1.0).

  sfx/cerf_brame_1..2       le cerf blanc : l'aboiement d'alarme du cerf, rauque et bref, deux fois.
  sfx/blaireau_grogne_1..2  le blaireau : un grondement sourd, puis un petit caquètement de colère.
  sfx/marmotte_siffle_1..2  la marmotte : le sifflement d'alarme, très aigu et sec.
  sfx/lynx_feule_1..2       le lynx : un feulement soufflé, puis un grondement qui roule.
(Les papillons, le gypaète et les raies sont muets ; la méduse garde la piqûre déjà dans le jeu,
sfx/meduse_pique_* ; l'os qui éclate, sfx/os_choc_*.)
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v137.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
from generate_sons_v135 import SR, t_, env, fin, voix, place  # noqa: E402

RNG = np.random.default_rng(13737)


def cerf(k):
    dur = 1.1
    out = np.zeros(int(dur * SR))
    tt = 0.03
    for j in range(2):
        d = RNG.uniform(0.18, 0.24)
        m = int(d * SR)
        u = np.linspace(0, 1, m)
        f = RNG.uniform(330, 420) * (1.0 + 0.25 * np.sin(np.pi * u) - 0.3 * u)
        y = voix(f, [(1, 1.0), (2, 0.8), (3, 0.6), (4, 0.4), (6, 0.2)], jitter=0.06)
        rauque = amb.bp(RNG.standard_normal(m), 400, 3000) * 0.6
        place(out, (y + rauque) * np.sin(np.pi * u) ** 0.4 * (1.0 if j == 0 else 0.8), tt)
        tt += d + RNG.uniform(0.25, 0.35)
    return fin(amb.bp(out, 200, 5000), 150)


def blaireau(k):
    dur = 1.0
    n = int(dur * SR)
    out = np.zeros(n)
    m = int(0.55 * SR)
    f = RNG.uniform(90, 120) * np.ones(m)
    g = voix(f, [(1, 1.0), (2, 0.7), (3, 0.5), (4, 0.3)], jitter=0.08)
    rumble = amb.lp(RNG.standard_normal(m), 400) * 0.5
    place(out, (g + rumble) * env(m, 0.08, 0.15), 0.0)
    tt = 0.6
    while tt < dur - 0.06:
        c = int(0.035 * SR)
        f2 = RNG.uniform(500, 700) * np.ones(c)
        place(out, voix(f2, [(1, 1.0), (2, 0.5)], jitter=0.1) * np.sin(np.pi * np.linspace(0, 1, c)) * 0.6, tt)
        tt += RNG.uniform(0.05, 0.07)
    return fin(out, 60)


def marmotte(k):
    dur = 0.45
    n = int(dur * SR)
    out = np.zeros(n)
    m = int(RNG.uniform(0.18, 0.24) * SR)
    u = np.linspace(0, 1, m)
    f = RNG.uniform(2600, 3000) * (1.0 + 0.08 * np.sin(np.pi * u) - 0.05 * u)
    y = voix(f, [(1, 1.0), (2, 0.15)]) * np.sin(np.pi * np.minimum(u * 1.5, 1.0)) ** 0.5 * (1.0 - u) ** 0.3
    souffle = amb.bp(RNG.standard_normal(m), 2000, 6000) * 0.08
    place(out, y + souffle, 0.02)
    return fin(out, 800)


def lynx(k):
    dur = 1.2
    n = int(dur * SR)
    out = np.zeros(n)
    s = int(0.45 * SR)
    hiss = amb.bp(RNG.standard_normal(s), 1500, 7000) * np.sin(np.pi * np.linspace(0, 1, s)) ** 0.7
    place(out, hiss, 0.0)
    m = int(0.7 * SR)
    u = np.linspace(0, 1, m)
    f = RNG.uniform(110, 140) * (1.0 + 0.1 * np.sin(np.pi * u))
    g = voix(f, [(1, 1.0), (2, 0.8), (3, 0.6), (5, 0.3)], jitter=0.07)
    am = 0.6 + 0.4 * np.sin(2 * np.pi * RNG.uniform(18, 25) * t_(m))
    place(out, g * am * env(m, 0.1, 0.25) * 0.8, 0.42)
    return fin(out, 80)


CAT = {
    "cerf_brame": (cerf, 2), "blaireau_grogne": (blaireau, 2), "marmotte_siffle": (marmotte, 2), "lynx_feule": (lynx, 2),
}


def main() -> int:
    total = 0
    for name, (fn, count) in CAT.items():
        for k in range(1, count + 1):
            fx.save(f"{name}_{k}", fn(k))
            total += 1
    print(f"V137 : {total} sons écrits dans {fx.OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
