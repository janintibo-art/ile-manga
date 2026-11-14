"""V143 : les sons de la magie élémentaire (synthétisés ici ; versés au domaine public, CC0 1.0).

  sfx/sort_foudre_1..3   l'éclair : le claquement sec (une déchirure d'air), puis le tonnerre qui
                         roule et s'éloigne.
  sfx/vapeur_feu_1..2       le feu qui rencontre la glace : un « pschhh » brûlant, puis le nuage.
  sfx/brise_glace_1..3   la gangue de glace qui vole en éclats : un craquement, une pluie de
                         cristaux qui tintent.
  sfx/brulure_1..2       l'ennemi qui prend feu : un « wouf » de flamme, des crépitements.
  sfx/electrocute_1..2   la foudre qui traverse un ennemi trempé : un grésillement haché.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v143.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
from generate_sons_v135 import SR, t_, env, fin, place  # noqa: E402

RNG = np.random.default_rng(14343)


def bruit(n):
    return RNG.standard_normal(n)


def sort_foudre(k):
    n = int(2.4 * SR)
    out = np.zeros(n)
    # le claquement : un bruit blanc très bref, très aigu, qui déchire
    m = int(0.09 * SR)
    place(out, amb.hp(bruit(m), 1800) * np.exp(-t_(m) * 55) * 1.6, 0.0)
    # deux ou trois répliques hachées
    for j in range(RNG.integers(2, 4)):
        mm = int(RNG.uniform(0.03, 0.07) * SR)
        place(out, amb.bp(bruit(mm), 900, 6000) * np.exp(-t_(mm) * 40) * RNG.uniform(0.5, 0.9), RNG.uniform(0.04, 0.2))
    # le coup sourd
    m2 = int(0.5 * SR)
    t2 = t_(m2)
    f = 45 + 90 * np.exp(-t2 * 14)
    place(out, np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t2 * 7) * 1.2, 0.02)
    # le tonnerre qui roule
    m3 = n - int(0.06 * SR)
    roul = amb.lp(bruit(m3), 220) * (0.6 + 0.4 * np.sin(2 * np.pi * RNG.uniform(3, 6) * t_(m3) + RNG.uniform(0, 6)))
    place(out, roul * env(m3, 0.03, 1.6) * np.exp(-t_(m3) * 1.5) * 2.4, 0.06)
    return fin(out, 25)


def vapeur(k):
    n = int(1.5 * SR)
    t = t_(n)
    # le sifflement : un bruit aigu dont la bande descend
    out = np.zeros(n)
    blocs = 12
    for b in range(blocs):
        i0 = b * n // blocs
        i1 = (b + 1) * n // blocs
        fc = 7000 - 4500 * b / blocs
        seg = amb.bp(bruit(i1 - i0 + 400), fc * 0.5, min(fc * 1.6, 10000))[200:200 + i1 - i0]
        out[i0:i1] += seg
    out *= (np.exp(-t * 2.6) * 1.3 + 0.12 * np.exp(-t * 0.8)) * env(n, 0.012, 0.5)
    # le « pouf » du nuage
    m = int(0.4 * SR)
    place(out, amb.lp(bruit(m), 320) * env(m, 0.01, 0.3) * 0.9, 0.0)
    return fin(out, 60)


def brise_glace(k):
    n = int(1.2 * SR)
    out = np.zeros(n)
    # le craquement
    m = int(0.07 * SR)
    place(out, amb.bp(bruit(m), 1200, 7000) * np.exp(-t_(m) * 45) * 1.5, 0.0)
    m2 = int(0.18 * SR)
    place(out, amb.lp(bruit(m2), 500) * np.exp(-t_(m2) * 22) * 1.0, 0.0)
    # les cristaux qui tintent en retombant
    for j in range(RNG.integers(14, 22)):
        mm = int(RNG.uniform(0.05, 0.16) * SR)
        f = RNG.uniform(2400, 7200)
        tt = t_(mm)
        c = (np.sin(2 * np.pi * f * tt) + 0.5 * np.sin(2 * np.pi * f * 1.51 * tt)) * np.exp(-tt * RNG.uniform(28, 55))
        place(out, c * RNG.uniform(0.08, 0.3), RNG.uniform(0.03, 0.75) ** 1.3)
    return fin(out, 80)


def brulure(k):
    n = int(1.1 * SR)
    t = t_(n)
    out = amb.lp(bruit(n), 500) * env(n, 0.05, 0.7) * np.exp(-t * 2.8) * 1.6
    out += amb.bp(bruit(n), 500, 2500) * env(n, 0.03, 0.8) * np.exp(-t * 3.5) * 0.5
    for j in range(RNG.integers(8, 14)):
        mm = int(RNG.uniform(0.004, 0.012) * SR)
        place(out, amb.hp(bruit(mm), 2000) * np.exp(-np.linspace(0, 6, mm)) * RNG.uniform(0.15, 0.4), RNG.uniform(0.08, 0.95))
    return fin(out, 40)


def electrocute(k):
    n = int(0.9 * SR)
    t = t_(n)
    f = RNG.uniform(95, 115)
    buzz = np.sign(np.sin(2 * np.pi * f * t)) * 0.4 + np.sin(2 * np.pi * f * 2 * t) * 0.3
    hache = (RNG.uniform(0, 1, n // 300 + 2) > 0.35).astype(float).repeat(300)[:n]
    out = amb.bp(buzz * hache, 200, 5000) * env(n, 0.005, 0.25)
    out += amb.hp(bruit(n), 3000) * hache * 0.35 * env(n, 0.005, 0.3)
    for j in range(RNG.integers(4, 7)):
        mm = int(RNG.uniform(0.01, 0.03) * SR)
        place(out, amb.hp(bruit(mm), 2500) * np.exp(-t_(mm) * 120) * RNG.uniform(0.5, 1.0), RNG.uniform(0.0, 0.7))
    return fin(out, 80)


CAT = {"sort_foudre": (sort_foudre, 3), "vapeur_feu": (vapeur, 2), "brise_glace": (brise_glace, 3), "brulure": (brulure, 2), "electrocute": (electrocute, 2)}


def main() -> int:
    total = 0
    for name, (fn, count) in CAT.items():
        for k in range(1, count + 1):
            fx.save(f"{name}_{k}", fn(k))
            total += 1
    print(f"V143 : {total} sons écrits dans {fx.OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
