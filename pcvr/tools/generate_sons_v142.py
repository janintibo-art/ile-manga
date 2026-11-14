"""V142 : les sons de l'Île des Géants (synthétisés ici ; versés au domaine public, CC0 1.0).

  sfx/pas_geant_1..3         le pas d'un géant : un « boum » très grave qui fait vibrer le sol, la
                             terre qui s'affaisse, quelques mottes qui retombent.
  sfx/limace_splotch_1..2    une limace qui se recroqueville et file : un « splotch » mouillé, un
                             glissement visqueux.
  sfx/gloussement_1..2       Pâquerette qui pouffe de rire dans sa cachette : « hi hi hi » (une voix
                             d'enfant synthétisée, très étouffée, puis qui éclate).
  sfx/ronflement_geant_1..2  la maison des géants qui ronfle, la nuit : un grondement qui monte à
                             l'inspiration, et le sifflement qui suit.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v142.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
from generate_sons_v135 import SR, t_, env, fin, place  # noqa: E402

RNG = np.random.default_rng(14242)


def boum(n, f0, f1, decay, k=12.0):
    t = t_(n)
    f = f1 + (f0 - f1) * np.exp(-t * k)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.exp(-t * decay)


def pas_geant(k):
    dur = 1.9
    n = int(dur * SR)
    out = boum(n, RNG.uniform(70, 85), RNG.uniform(26, 32), 2.6) * 1.4
    # le sol qui encaisse : un bruit sourd, filtré très bas
    out += amb.lp(RNG.standard_normal(n), 180) * np.exp(-t_(n) * 4.5) * 2.2
    # le grondement qui roule et qui s'éloigne
    out += amb.lp(RNG.standard_normal(n), 90) * env(n, 0.04, 1.2) * np.exp(-t_(n) * 1.3) * 1.6
    # la terre qui s'affaisse, les mottes qui retombent
    m = int(0.5 * SR)
    place(out, amb.bp(RNG.standard_normal(m), 200, 900) * env(m, 0.02, 0.4) * 0.35, 0.05)
    for j in range(RNG.integers(5, 9)):
        mm = int(RNG.uniform(0.02, 0.05) * SR)
        c = amb.bp(RNG.standard_normal(mm), 300, 1800) * np.exp(-np.linspace(0, 5, mm))
        place(out, c * RNG.uniform(0.08, 0.2), RNG.uniform(0.15, 0.9))
    return fin(out, 20)


def limace_splotch(k):
    dur = 0.9
    n = int(dur * SR)
    out = np.zeros(n)
    # le « splotch » : un plop mouillé (une bulle qui crève), très court
    m = int(0.12 * SR)
    tt = np.linspace(0, 1, m)
    f = 700 * np.exp(-tt * 3.0) + 180
    plop = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt * 9.0)
    place(out, plop * 0.9, 0.0)
    place(out, amb.bp(RNG.standard_normal(m), 600, 3000) * np.exp(-tt * 14.0) * 0.5, 0.005)
    # le glissement visqueux : un bruit modulé, comme des bulles qui claquent
    m2 = int(0.7 * SR)
    g = amb.bp(RNG.standard_normal(m2), 300, 1400)
    mod = 0.5 + 0.5 * np.sin(2 * np.pi * np.cumsum(RNG.uniform(18, 30, m2)) / SR)
    place(out, g * mod * env(m2, 0.05, 0.4) * 0.35, 0.12)
    return fin(out, 60)


def voix(n, f0, form, vib=0.0):
    """Une voyelle synthétisée : une source glottique (dents de scie), trois formants."""
    t = t_(n)
    f = f0 * (1.0 + vib * np.sin(2 * np.pi * 6.0 * t))
    ph = np.cumsum(f) / SR
    src = 2.0 * (ph % 1.0) - 1.0
    out = np.zeros(n)
    for fc, bw, a in form:
        out += amb.bp(src, fc - bw, fc + bw) * a
    return out


def gloussement(k):
    dur = 1.7
    n = int(dur * SR)
    out = np.zeros(n)
    hi = [(420, 120, 1.0), (2600, 300, 0.55), (3400, 400, 0.3)]      # « i »
    t0 = 0.05
    count = 4 if k == 1 else 5
    for j in range(count):
        m = int(RNG.uniform(0.09, 0.13) * SR)
        f0 = RNG.uniform(430, 520) * (1.0 + 0.04 * j)
        v = voix(m, f0, hi, 0.02) * np.sin(np.linspace(0, np.pi, m)) ** 0.7
        # le souffle du rire (le « h »)
        h = amb.bp(RNG.standard_normal(m), 1500, 5000) * np.exp(-np.linspace(0, 6, m)) * 0.4
        place(out, (v * 0.8 + h) * (0.7 + 0.3 * j / count), t0)
        t0 += RNG.uniform(0.17, 0.22)
    # étouffé (les mains sur la bouche), sauf le dernier éclat
    out = amb.lp(out, 3200)
    return fin(out, 80) * 0.85


def ronflement_geant(k):
    dur = 4.2
    n = int(dur * SR)
    t = t_(n)
    out = np.zeros(n)
    # l'inspiration : un grondement qui vibre (le voile du palais), qui monte puis s'arrête
    m = int(2.2 * SR)
    tt = np.linspace(0, 1, m)
    f0 = 38 + 10 * tt
    ph = np.cumsum(f0) / SR
    flap = (np.sin(2 * np.pi * ph) > 0.2).astype(float) * 0.6 + 0.4
    rumble = amb.lp(RNG.standard_normal(m), 350) * flap * np.sin(np.pi * tt) ** 0.8
    place(out, rumble * 2.2, 0.1)
    # l'expiration : un long souffle qui siffle un peu
    m2 = int(1.5 * SR)
    tt2 = np.linspace(0, 1, m2)
    breath = amb.bp(RNG.standard_normal(m2), 300, 1600) * np.sin(np.pi * tt2) ** 1.2 * 0.45
    whistle = np.sin(2 * np.pi * np.cumsum(np.full(m2, 900 + 120 * k) * (1.0 - 0.15 * tt2)) / SR) * np.sin(np.pi * tt2) ** 2 * 0.05
    place(out, breath + whistle, 2.45)
    return fin(out, 30) * 0.9


CAT = {"pas_geant": (pas_geant, 3), "limace_splotch": (limace_splotch, 2), "gloussement": (gloussement, 2), "ronflement_geant": (ronflement_geant, 2)}


def main() -> int:
    total = 0
    for name, (fn, count) in CAT.items():
        for k in range(1, count + 1):
            fx.save(f"{name}_{k}", fn(k))
            total += 1
    print(f"V142 : {total} sons écrits dans {fx.OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
