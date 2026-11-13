"""V141 : les sons des coups qui pèsent (synthétisés ici ; versés au domaine public, CC0 1.0).

  sfx/frappe_sol_1..2    le sol frappé de toute sa force : un boum sourd, des éclats de pierre, un
                         grondement qui roule.
  sfx/coup_final_1..2    le coup final d'un enchaînement : un grand souffle qui fend l'air, un choc.
  sfx/chute_corps_1..2   un ennemi qui tombe à la renverse : un choc mat, un frottement de poussière.
  sfx/plonge_vent_1..2   le coup plongeant : l'air qui siffle de plus en plus fort.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v141.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
from generate_sons_v135 import SR, t_, env, fin, place  # noqa: E402

RNG = np.random.default_rng(14141)


def boum(n, f0, f1, decay):
    t = t_(n)
    f = f1 + (f0 - f1) * np.exp(-t * 18.0)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.exp(-t * decay)


def frappe_sol(k):
    dur = 1.6
    n = int(dur * SR)
    out = boum(n, RNG.uniform(110, 130), RNG.uniform(38, 46), 3.2) * 1.2
    out += amb.lp(RNG.standard_normal(n), 400) * np.exp(-t_(n) * 5.0) * 1.4
    # le grondement qui roule
    out += amb.lp(RNG.standard_normal(n), 120) * env(n, 0.05, 1.0) * np.exp(-t_(n) * 1.6) * 1.8
    # les éclats de pierre qui retombent
    for j in range(RNG.integers(10, 16)):
        m = int(RNG.uniform(0.008, 0.02) * SR)
        c = amb.bp(RNG.standard_normal(m), 1500, 7000) * np.exp(-np.linspace(0, 6, m))
        place(out, c * RNG.uniform(0.15, 0.4), RNG.uniform(0.03, 0.9))
    return fin(out, 25)


def coup_final(k):
    dur = 0.75
    n = int(dur * SR)
    u = np.linspace(0, 1, n)
    out = np.zeros(n)
    # le souffle qui fend l'air (il monte, puis retombe)
    m = int(0.4 * SR)
    w = RNG.standard_normal(m)
    lo = amb.bp(w, 300, 1200)
    hi = amb.bp(w, 900, 3500)
    uu = np.linspace(0, 1, m)
    sweep = lo * (1 - uu) + hi * uu
    place(out, sweep * np.sin(np.pi * uu) ** 1.5 * 0.9, 0.0)
    # le choc
    m2 = int(0.4 * SR)
    place(out, boum(m2, 150, 55, 9.0) + amb.lp(RNG.standard_normal(m2), 800) * np.exp(-np.linspace(0, 14, m2)) * 0.8, 0.3)
    return fin(out, 40)


def chute_corps(k):
    dur = 0.8
    n = int(dur * SR)
    out = boum(n, RNG.uniform(95, 115), RNG.uniform(50, 60), 10.0)
    out += amb.lp(RNG.standard_normal(n), 900) * np.exp(-t_(n) * 18.0) * 0.8
    # la poussière qui frotte
    m = int(0.5 * SR)
    place(out, amb.bp(RNG.standard_normal(m), 1200, 5000) * env(m, 0.02, 0.4) * 0.18, 0.05)
    return fin(out, 35)


def plonge_vent(k):
    dur = 0.55
    n = int(dur * SR)
    u = np.linspace(0, 1, n)
    w = RNG.standard_normal(n)
    out = np.zeros(n)
    # un filtre qui monte : l'air siffle de plus en plus aigu
    for b0, b1, a in [(250, 700, 1.0), (600, 1600, 0.8), (1400, 3200, 0.5)]:
        out += amb.bp(w, b0, b1) * a * u ** (1.5 if b0 > 500 else 0.8)
    return fin(out * env(n, 0.05, 0.08), 120) * 0.8


CAT = {"frappe_sol": (frappe_sol, 2), "coup_final": (coup_final, 2), "chute_corps": (chute_corps, 2), "plonge_vent": (plonge_vent, 2)}


def main() -> int:
    total = 0
    for name, (fn, count) in CAT.items():
        for k in range(1, count + 1):
            fx.save(f"{name}_{k}", fn(k))
            total += 1
    print(f"V141 : {total} sons écrits dans {fx.OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
