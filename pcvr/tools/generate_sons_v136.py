"""V136 : les cris de la faune de l'Île aux Moaïs, de l'Île de la Balafre et de l'Île de Larsen
(synthétisés ici ; versés au domaine public, CC0 1.0).

  sfx/cheval_hennit_1..2     le cheval sauvage : un hennissement qui part haut, tremble et
                             retombe, puis un ébrouement.
  sfx/fregate_claque_1..2    la frégate : le claquement sec du bec, très rapide, et un gargouillis.
  sfx/tortue_souffle_1..2    la tortue verte : un long souffle, puis une petite inspiration.
  sfx/varan_siffle_1..2      le varan : un sifflement qui enfle et tremble un peu.
  sfx/lapin_tape_1..2        le lapin : deux ou trois coups sourds de la patte arrière.
  sfx/frelon_bourdonne_1..2  les frelons : un bourdonnement grave qui va et vient.
  sfx/herisson_renifle_1..2  le hérisson : de petits reniflements pressés et un grognement.
  sfx/hibou_hulule_1..2      le grand-duc : son « hou-HOU » grave, qui porte loin la nuit.
  sfx/renard_glapit_1..2     le renard : deux ou trois aboiements rauques et aigus.
(L'ara garde le cri de perroquet déjà dans le jeu, sfx/perroquet_* ; le crabe de cocotier, ceux
du crabe, sfx/crabe_menace_* et sfx/crabe_mort_*.)
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v136.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
from generate_sons_v135 import SR, t_, env, fin, voix, place  # noqa: E402

RNG = np.random.default_rng(13636)


def cheval(k):
    dur = RNG.uniform(1.5, 1.8)
    n = int(dur * SR)
    out = np.zeros(n)
    m = int((dur - 0.35) * SR)
    u = np.linspace(0, 1, m)
    # le hennissement : il part haut, tremble très vite, puis retombe en cascade
    f = RNG.uniform(880, 1000) * (1.0 - 0.55 * u ** 0.8) * (1.0 + 0.06 * np.sin(2 * np.pi * RNG.uniform(11, 14) * t_(m)))
    y = voix(f, [(1, 1.0), (2, 0.65), (3, 0.4), (4, 0.22), (5, 0.12)], jitter=0.02)
    trem = 0.55 + 0.45 * np.sin(2 * np.pi * RNG.uniform(9, 12) * t_(m)) ** 2
    souffle = amb.bp(RNG.standard_normal(m), 500, 4000) * 0.25
    place(out, amb.bp((y + souffle) * trem, 250, 6000) * env(m, 0.04, 0.35), 0.0)
    # l'ébrouement : un souffle des naseaux qui vibre
    s = int(0.3 * SR)
    br = amb.bp(RNG.standard_normal(s), 150, 1500) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 32 * t_(s)))) * np.sin(np.pi * np.linspace(0, 1, s))
    place(out, br * 0.7, dur - 0.33)
    return fin(out, 120)


def fregate(k):
    dur = 0.8
    out = np.zeros(int(dur * SR))
    tt = 0.02
    rate = RNG.uniform(22, 28)
    while tt < 0.55:
        m = int(0.006 * SR)
        c = amb.bp(RNG.standard_normal(m), 1200, 4500) * np.exp(-np.linspace(0, 1, m) * 5.0)
        place(out, c * RNG.uniform(0.6, 1.0), tt)
        tt += 1.0 / rate * RNG.uniform(0.85, 1.15)
    g = int(0.3 * SR)
    f = RNG.uniform(160, 200) * np.ones(g)
    gl = voix(f, [(1, 1.0), (2, 0.5), (3, 0.3)], jitter=0.06) * (0.5 + 0.5 * np.sin(2 * np.pi * 18 * t_(g))) * env(g, 0.05, 0.15)
    place(out, gl * 0.4, 0.48)
    return fin(out, 150)


def tortue(k):
    dur = RNG.uniform(1.2, 1.4)
    n = int(dur * SR)
    out = np.zeros(n)
    m = int(0.75 * SR)
    u = np.linspace(0, 1, m)
    ex = amb.bp(RNG.standard_normal(m), 250, 2200) * np.sin(np.pi * np.minimum(u * 1.2, 1.0)) ** 0.7
    place(out, ex, 0.02)
    s = int(0.35 * SR)
    inh = amb.bp(RNG.standard_normal(s), 600, 3500) * np.sin(np.pi * np.linspace(0, 1, s)) * 0.45
    place(out, inh, dur - 0.4)
    return fin(out, 120) * 0.8


def varan(k):
    dur = RNG.uniform(0.9, 1.1)
    n = int(dur * SR)
    u = np.linspace(0, 1, n)
    h = amb.bp(RNG.standard_normal(n), 1800, 8000) * np.sin(np.pi * np.minimum(u * 1.6, 1.0)) ** 1.1
    h *= 0.8 + 0.2 * np.sin(2 * np.pi * RNG.uniform(7, 10) * t_(n))
    low = amb.bp(RNG.standard_normal(n), 300, 900) * 0.15
    return fin((h + low) * env(n, 0.06, 0.3), 500)


def lapin(k):
    dur = 0.55
    out = np.zeros(int(dur * SR))
    tt = 0.01
    for j in range(RNG.integers(2, 4)):
        m = int(0.09 * SR)
        f = RNG.uniform(70, 95) * np.exp(-np.linspace(0, 1, m) * 0.8)
        th = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-np.linspace(0, 1, m) * 6.0)
        clic = amb.bp(RNG.standard_normal(m), 300, 2000) * np.exp(-np.linspace(0, 1, m) * 25.0) * 0.4
        place(out, (th + clic) * RNG.uniform(0.7, 1.0), tt)
        tt += RNG.uniform(0.12, 0.16)
    return fin(out, 30)


def frelon(k):
    dur = 1.3
    n = int(dur * SR)
    u = np.linspace(0, 1, n)
    f = RNG.uniform(115, 140) * (1.0 + 0.08 * np.sin(2 * np.pi * RNG.uniform(0.8, 1.4) * t_(n)) + 0.03 * np.sin(2 * np.pi * 5.3 * t_(n)))
    harm = [(h, 1.0 / h) for h in range(1, 14)]
    y = voix(f, harm, jitter=0.01)
    am = 0.7 + 0.3 * amb.lp(RNG.standard_normal(n), 8) * 4.0
    y = amb.bp(y * np.clip(am, 0.2, 1.2), 150, 5000) * np.sin(np.pi * u) ** 0.5
    return fin(y, 90)


def herisson(k):
    dur = 0.9
    out = np.zeros(int(dur * SR))
    tt = 0.01
    while tt < dur - 0.08:
        m = int(RNG.uniform(0.03, 0.06) * SR)
        c = amb.bp(RNG.standard_normal(m), 900, 5000) * np.sin(np.pi * np.linspace(0, 1, m)) ** 2
        place(out, c * RNG.uniform(0.4, 0.9), tt)
        tt += RNG.uniform(0.05, 0.1)
    g = int(0.22 * SR)
    f = RNG.uniform(140, 180) * np.ones(g)
    place(out, voix(f, [(1, 1.0), (2, 0.6), (3, 0.35)], jitter=0.08) * env(g, 0.03, 0.1) * 0.35, RNG.uniform(0.3, 0.55))
    return fin(out, 200) * 0.85


def hibou(k):
    dur = 1.35
    out = np.zeros(int(dur * SR))
    # « hou » court, puis « HOU » plus fort et un peu plus haut, qui retombe
    for (at, d, f0, g) in [(0.05, 0.22, RNG.uniform(255, 275), 0.6), (0.42, 0.55, RNG.uniform(290, 310), 1.0)]:
        m = int(d * SR)
        u = np.linspace(0, 1, m)
        f = f0 * (1.0 + 0.04 * np.sin(np.pi * u) - 0.06 * u)
        y = voix(f, [(1, 1.0), (2, 0.18), (3, 0.05)])
        souffle = amb.bp(RNG.standard_normal(m), 200, 1200) * 0.05
        place(out, (y + souffle) * np.sin(np.pi * u) ** 0.8 * g, at)
    return fin(amb.lp(out, 2500), 80)


def renard(k):
    dur = 1.2
    out = np.zeros(int(dur * SR))
    tt = 0.02
    for j in range(RNG.integers(2, 4)):
        d = RNG.uniform(0.18, 0.26)
        m = int(d * SR)
        u = np.linspace(0, 1, m)
        f = RNG.uniform(620, 760) * (1.0 + 0.3 * np.sin(np.pi * u) - 0.2 * u)
        y = voix(f, [(1, 1.0), (2, 0.7), (3, 0.5), (4, 0.3), (5, 0.2)], jitter=0.05)
        rauque = amb.bp(RNG.standard_normal(m), 800, 4000) * 0.35
        place(out, (y + rauque) * np.sin(np.pi * u) ** 0.5 * RNG.uniform(0.7, 1.0), tt)
        tt += d + RNG.uniform(0.12, 0.2)
        if tt > dur - 0.3:
            break
    return fin(amb.bp(out, 300, 7000), 200)


CAT = {
    "cheval_hennit": (cheval, 2), "fregate_claque": (fregate, 2), "tortue_souffle": (tortue, 2),
    "varan_siffle": (varan, 2), "lapin_tape": (lapin, 2), "frelon_bourdonne": (frelon, 2),
    "herisson_renifle": (herisson, 2), "hibou_hulule": (hibou, 2), "renard_glapit": (renard, 2),
}


def main() -> int:
    total = 0
    for name, (fn, count) in CAT.items():
        for k in range(1, count + 1):
            fx.save(f"{name}_{k}", fn(k))
            total += 1
    print(f"V136 : {total} sons écrits dans {fx.OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
