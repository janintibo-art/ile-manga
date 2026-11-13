"""V140 : les cris de la faune de Montjoie, de Port-Azur et de l'Île Pixelithique (synthétisés ici ;
versés au domaine public, CC0 1.0).

  sfx/poule_caquette_1..2    les poules : des « cot cot cot » et un « codêêt » qui monte.
  sfx/coq_chante_1..2        le coq : « co-co-ri-côôô », la dernière syllabe longue et éraillée.
  sfx/heron_croasse_1..2     le héron cendré : un « fraank » rauque et sourd.
  sfx/ecureuil_crie_1..2     l'écureuil roux : des « tchouk » secs et un roulement grondeur.
  sfx/guepier_trille_1..2    les guêpiers : des « prrüp » liquides, roulés.
  sfx/compso_piaille_1..2    les compsognathes : de petits piaulements aigus qui retombent.
  sfx/archeo_cri_1..2        l'archéoptéryx : un cri rêche, entre la corneille et le perroquet.
  sfx/meganeura_bourdon_1..2 la libellule géante : le bourdonnement grave de ses quatre ailes.
(La tortue d'Hermann souffle avec le son déjà dans le jeu, sfx/tortue_souffle_* ; le lézard est muet.)
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v140.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
from generate_sons_v135 import SR, t_, env, fin, voix, place  # noqa: E402

RNG = np.random.default_rng(14040)


def poule(k):
    dur = 1.4
    out = np.zeros(int(dur * SR))
    tt = 0.02
    for j in range(RNG.integers(3, 5)):
        d = RNG.uniform(0.07, 0.1)
        m = int(d * SR)
        u = np.linspace(0, 1, m)
        f = RNG.uniform(430, 520) * (1.0 + 0.2 * np.sin(np.pi * u))
        y = voix(f, [(1, 0.5), (2, 1.0), (3, 0.8), (4, 0.5), (5, 0.3)], jitter=0.05)
        place(out, amb.bp(y, 500, 3500) * np.sin(np.pi * u) ** 0.5, tt)
        tt += d + RNG.uniform(0.09, 0.16)
    # le « codêêt » final, qui monte
    d = RNG.uniform(0.35, 0.45)
    m = int(d * SR)
    u = np.linspace(0, 1, m)
    f = RNG.uniform(520, 600) * (1.0 + 0.45 * np.sqrt(u))
    y = voix(f, [(1, 0.6), (2, 1.0), (3, 0.7), (4, 0.4), (6, 0.2)], jitter=0.07)
    place(out, amb.bp(y, 500, 4000) * env(m, 0.03, 0.12), min(tt, dur - d - 0.02))
    return fin(out, 200)


def coq(k):
    dur = 1.9
    out = np.zeros(int(dur * SR))
    tt = 0.03
    sylls = [(0.14, 600, 0.0), (0.12, 680, 0.05), (0.15, 760, 0.1), (0.85, 820, -0.25)]
    for j, (d, f0, pente) in enumerate(sylls):
        m = int(d * SR)
        u = np.linspace(0, 1, m)
        f = f0 * RNG.uniform(0.95, 1.05) * (1.0 + pente * u + 0.03 * np.sin(2 * np.pi * 7.0 * t_(m)))
        y = voix(f, [(1, 0.7), (2, 1.0), (3, 0.9), (4, 0.6), (5, 0.4), (7, 0.25)], jitter=0.09)
        rauque = amb.bp(RNG.standard_normal(m), 800, 4000) * (0.25 if j < 3 else 0.4)
        e = env(m, 0.02, 0.05 if j < 3 else 0.35)
        place(out, (amb.bp(y, 400, 5000) + rauque) * e, tt)
        tt += d + 0.04
    return fin(out, 250)


def heron(k):
    dur = 0.75
    n = int(dur * SR)
    u = np.linspace(0, 1, n)
    f = RNG.uniform(190, 240) * (1.0 + 0.25 * np.sin(np.pi * u) - 0.2 * u)
    y = voix(f, [(1, 0.8), (2, 1.0), (3, 0.9), (4, 0.7), (5, 0.5), (6, 0.4), (8, 0.25)], jitter=0.15)
    rauque = amb.bp(RNG.standard_normal(n), 300, 2500) * 0.6
    puls = 0.6 + 0.4 * np.sign(np.sin(2 * np.pi * RNG.uniform(45, 60) * t_(n)))
    return fin((y + rauque) * puls * env(n, 0.02, 0.3), 120)


def ecureuil(k):
    dur = 1.1
    out = np.zeros(int(dur * SR))
    tt = 0.02
    for j in range(RNG.integers(3, 5)):
        m = int(0.035 * SR)
        u = np.linspace(0, 1, m)
        f = RNG.uniform(2200, 2800) * (1.0 - 0.3 * u)
        y = voix(f, [(1, 1.0), (2, 0.5), (3, 0.2)])
        place(out, (y + amb.bp(RNG.standard_normal(m), 2000, 7000) * 0.5) * np.exp(-u * 5.0), tt)
        tt += RNG.uniform(0.09, 0.14)
    # le roulement grondeur
    m = int(0.4 * SR)
    trem = 0.5 + 0.5 * np.sign(np.sin(2 * np.pi * RNG.uniform(28, 36) * t_(m)))
    r = amb.bp(RNG.standard_normal(m), 1800, 6000) * trem * env(m, 0.02, 0.15)
    place(out, r * 0.8, min(tt, dur - 0.42))
    return fin(out, 900) * 0.8


def guepier(k):
    dur = 1.2
    out = np.zeros(int(dur * SR))
    tt = 0.02
    for j in range(RNG.integers(2, 4)):
        d = RNG.uniform(0.16, 0.22)
        m = int(d * SR)
        u = np.linspace(0, 1, m)
        f = RNG.uniform(2300, 2700) * (1.0 + 0.12 * np.sin(np.pi * u))
        roule = 0.55 + 0.45 * np.sin(2 * np.pi * RNG.uniform(45, 60) * t_(m))
        y = voix(f, [(1, 1.0), (2, 0.35), (3, 0.1)], jitter=0.02)
        place(out, y * roule * np.sin(np.pi * u) ** 0.6, tt)
        tt += d + RNG.uniform(0.12, 0.2)
        if tt > dur - 0.25:
            break
    return fin(out, 1200) * 0.7


def compso(k):
    dur = 0.9
    out = np.zeros(int(dur * SR))
    tt = 0.02
    for j in range(RNG.integers(3, 6)):
        d = RNG.uniform(0.05, 0.1)
        m = int(d * SR)
        u = np.linspace(0, 1, m)
        f = RNG.uniform(1800, 2600) * (1.0 + 0.3 * (1.0 - u) ** 2 - 0.25 * u)
        y = voix(f, [(1, 1.0), (2, 0.45), (3, 0.2)], jitter=0.03)
        place(out, y * np.sin(np.pi * u) ** 0.5 * RNG.uniform(0.6, 1.0), tt)
        tt += d + RNG.uniform(0.04, 0.12)
        if tt > dur - 0.12:
            break
    return fin(out, 800) * 0.75


def archeo(k):
    dur = 0.8
    out = np.zeros(int(dur * SR))
    tt = 0.02
    for j in range(2):
        d = RNG.uniform(0.18, 0.26)
        m = int(d * SR)
        u = np.linspace(0, 1, m)
        f = RNG.uniform(650, 800) * (1.0 + 0.2 * np.sin(np.pi * u) + 0.3 * u * j)
        y = voix(f, [(1, 0.6), (2, 1.0), (3, 0.8), (4, 0.6), (5, 0.4)], jitter=0.12)
        r = amb.bp(RNG.standard_normal(m), 900, 5000) * 0.5
        place(out, (y + r) * np.sin(np.pi * u) ** 0.5, tt)
        tt += d + RNG.uniform(0.06, 0.1)
    return fin(amb.bp(out, 300, 6000), 250)


def meganeura(k):
    dur = 1.3
    n = int(dur * SR)
    t = t_(n)
    f = RNG.uniform(70, 85) * (1.0 + 0.05 * np.sin(2 * np.pi * 1.3 * t))
    y = voix(f, [(1, 1.0), (2, 0.7), (3, 0.5), (4, 0.35), (5, 0.25), (6, 0.15)], jitter=0.02)
    froiss = amb.bp(RNG.standard_normal(n), 600, 3000) * 0.25 * (0.5 + 0.5 * np.sin(2 * np.pi * f * t / 2.0))
    return fin((y + froiss) * env(n, 0.15, 0.4), 40) * 0.8


CAT = {
    "poule_caquette": (poule, 2), "coq_chante": (coq, 2), "heron_croasse": (heron, 2), "ecureuil_crie": (ecureuil, 2),
    "guepier_trille": (guepier, 2), "compso_piaille": (compso, 2), "archeo_cri": (archeo, 2), "meganeura_bourdon": (meganeura, 2),
}


def main() -> int:
    total = 0
    for name, (fn, count) in CAT.items():
        for k in range(1, count + 1):
            fx.save(f"{name}_{k}", fn(k))
            total += 1
    print(f"V140 : {total} sons écrits dans {fx.OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
