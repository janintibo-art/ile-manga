"""V133 : les cris de la faune des trois îles (synthétisés ici ; versés au domaine public, CC0 1.0).

  sfx/aurochs_meugle_1..2      l'aurochs : un meuglement grave qui enfle, la voyelle qui
                               s'ouvre (« mmmoooâââ »), du souffle par les naseaux.
  sfx/ours_rugit_1..2          l'ours : un grondement rauque, roulé, qui monte en rugissement.
  sfx/boulette_grogne_1..2     la boulette : un grognement mouillé, des bulles de sauce qui
                               éclatent.
  sfx/spaghetti_fouet_1..2     le spaghetti : le sifflement du brin qui fend l'air, puis la
                               claque mouillée.
  sfx/tomate_splat_1..2        la tomate : « splotch ! », et les gouttes qui retombent.
  sfx/gribouillis_griffe_1..2  le gribouillis : des coups de crayon rageurs sur le papier.
  sfx/gomme_couine_1..2        la gomme : le couinement du caoutchouc qui frotte et accroche.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v133.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402

SR = 44100
RNG = np.random.default_rng(13333)


def t_(n):
    return np.arange(n) / SR


def norm(x, peak=0.89):
    return x / (np.max(np.abs(x)) + 1e-9) * peak


def env(n, att, rel, sus=1.0):
    e = np.ones(n) * sus
    a = int(att * SR)
    r = int(rel * SR)
    if a > 0:
        e[:a] = np.linspace(0, sus, a)
    if r > 0:
        e[-r:] *= np.linspace(1, 0, r)
    return e


def fin(x, hp=50):
    return norm(amb.hp(x, hp))


def voix(f, harm, vib=0.0, vib_f=6.0, jitter=0.0):
    """Une voix : fréquence f (tableau), harmoniques [(rang, amp)], vibrato, voix éraillée."""
    n = len(f)
    t = t_(n)
    fv = f * (1.0 + vib * np.sin(2 * np.pi * vib_f * t))
    if jitter > 0:
        j = amb.lp(RNG.standard_normal(n), 60) * jitter * 30.0
        fv = fv * (1.0 + j)
    ph = 2 * np.pi * np.cumsum(fv) / SR
    y = np.zeros(n)
    for k, a in harm:
        y += a * np.sin(k * ph)
    return y


def formant(y, lo, hi):
    return amb.bp(y, lo, hi)


def aurochs(k):
    dur = RNG.uniform(1.4, 1.8)
    n = int(dur * SR)
    u = np.linspace(0, 1, n)
    f0 = RNG.uniform(88, 108)
    f = f0 * (0.85 + 0.3 * np.sin(np.pi * np.minimum(u * 1.3, 1.0)) - 0.1 * u)
    harm = [(1, 1.0), (2, 0.9), (3, 0.75), (4, 0.6), (5, 0.45), (6, 0.35), (8, 0.22), (10, 0.12)]
    y = voix(f, harm, vib=0.01, vib_f=5.0, jitter=0.004)
    # la voyelle s'ouvre : « ooo » (formant bas) puis « âââ » (formant plus haut)
    lo = formant(y, 150, 700)
    hi = formant(y, 500, 1600)
    open_ = np.clip((u - 0.25) / 0.4, 0, 1)
    y = lo * (1 - open_ * 0.6) + hi * open_ * 0.9
    breath = amb.bp(RNG.standard_normal(n), 300, 2500) * 0.12
    y = (y + breath) * env(n, 0.18, 0.45)
    return fin(y, 40)


def ours(k):
    dur = RNG.uniform(1.1, 1.4)
    n = int(dur * SR)
    u = np.linspace(0, 1, n)
    f0 = RNG.uniform(95, 125)
    f = f0 * (0.8 + 0.45 * np.sin(np.pi * np.minimum(u * 1.6, 1.0)))
    y = voix(f, [(1, 0.9), (2, 1.0), (3, 0.85), (4, 0.7), (5, 0.55), (7, 0.35), (9, 0.2)], jitter=0.02)
    # le grondement roulé : une modulation rapide de l'amplitude
    am = 0.55 + 0.45 * np.sin(2 * np.pi * RNG.uniform(26, 34) * t_(n) + 3.0 * amb.lp(RNG.standard_normal(n), 8))
    noise = amb.bp(RNG.standard_normal(n), 250, 2600) * 0.45
    y = formant(y * am + noise * am, 180, 2200) * env(n, 0.12, 0.4)
    return fin(y, 45)


def boulette(k):
    dur = 0.9
    n = int(dur * SR)
    u = np.linspace(0, 1, n)
    f = RNG.uniform(62, 80) * (1.0 + 0.15 * np.sin(2 * np.pi * 3.0 * u))
    y = voix(f, [(1, 1.0), (2, 0.7), (3, 0.5), (4, 0.3)], jitter=0.015)
    y = amb.lp(y, 900) * env(n, 0.05, 0.3) * 0.8
    # les bulles de sauce
    for j in range(RNG.integers(5, 9)):
        m = int(RNG.uniform(0.03, 0.06) * SR)
        i = int(RNG.uniform(0.0, dur - 0.08) * SR)
        fb = RNG.uniform(250, 600)
        b = np.sin(2 * np.pi * np.cumsum(np.linspace(fb, fb * 2.2, m)) / SR) * env(m, 0.002, m / SR * 0.7)
        y[i:i + m] += b * RNG.uniform(0.3, 0.6)
    squelch = amb.lp(RNG.standard_normal(n), 700) * 0.25 * (0.5 + 0.5 * np.sin(2 * np.pi * 7.0 * u))
    return fin(y + squelch * env(n, 0.05, 0.3), 40)


def fouet(k):
    dur = 0.65
    out = np.zeros(int(dur * SR))
    m = int(0.2 * SR)
    sw = RNG.standard_normal(m)
    # le sifflement descend en fréquence
    parts = []
    for j in range(4):
        a = j * m // 4
        b = (j + 1) * m // 4
        parts.append(amb.bp(sw[a:b], 1200 - j * 250, 6000 - j * 1100))
    swish = np.concatenate(parts) * np.sin(np.pi * np.linspace(0, 1, m)) ** 1.5
    out[:m] += swish * 0.6
    s = int(0.2 * SR)
    slap = amb.bp(RNG.standard_normal(s), 300, 3500) * np.exp(-np.linspace(0, 1, s) * 14.0)
    wet = amb.lp(RNG.standard_normal(s), 900) * np.exp(-np.linspace(0, 1, s) * 7.0) * 0.6
    i = int(0.19 * SR)
    out[i:i + s] += slap + wet
    return fin(out, 80)


def splat(k):
    dur = 0.75
    out = np.zeros(int(dur * SR))
    s = int(0.25 * SR)
    burst = amb.bp(RNG.standard_normal(s), 250, 3200) * np.exp(-np.linspace(0, 1, s) * 11.0)
    body = amb.lp(RNG.standard_normal(s), 600) * np.exp(-np.linspace(0, 1, s) * 6.0) * 0.9
    thump = np.sin(2 * np.pi * np.cumsum(np.linspace(140, 60, s)) / SR) * np.exp(-np.linspace(0, 1, s) * 9.0) * 0.7
    out[:s] += burst + body + thump
    # les gouttes qui retombent
    for j in range(RNG.integers(6, 11)):
        m = int(0.02 * SR)
        i = int(RNG.uniform(0.12, dur - 0.05) * SR)
        out[i:i + m] += amb.bp(RNG.standard_normal(m), 900, 4000) * np.exp(-np.linspace(0, 1, m) * 8.0) * RNG.uniform(0.1, 0.3)
    return fin(out, 45)


def griffe(k):
    dur = 0.95
    out = np.zeros(int(dur * SR))
    tt = 0.0
    while tt < dur - 0.1:
        d = RNG.uniform(0.06, 0.15)
        m = int(d * SR)
        g = amb.bp(RNG.standard_normal(m), RNG.uniform(1800, 2600), RNG.uniform(6500, 9000))
        # la mine accroche le grain du papier
        grain = 0.6 + 0.4 * np.sign(np.sin(2 * np.pi * RNG.uniform(90, 160) * t_(m)))
        g = g * grain * np.sin(np.pi * np.linspace(0, 1, m)) ** 0.7 * RNG.uniform(0.5, 1.0)
        i = int(tt * SR)
        out[i:i + m] += g[: len(out) - i]
        tt += d + RNG.uniform(0.0, 0.04)
    return fin(out, 400)


def gomme(k):
    dur = 0.85
    n = int(dur * SR)
    u = np.linspace(0, 1, n)
    f = RNG.uniform(620, 760) * (1.0 + 0.45 * np.sin(np.pi * u) - 0.1 * u)
    y = voix(f, [(1, 1.0), (2, 0.55), (3, 0.35), (4, 0.2)], vib=0.02, vib_f=9.0)
    # le caoutchouc accroche et lâche (adhérence-glissement)
    stick = 0.5 + 0.5 * np.sign(np.sin(2 * np.pi * RNG.uniform(32, 46) * t_(n)))
    rub = amb.bp(RNG.standard_normal(n), 300, 2400) * 0.5
    y = (y * stick * 0.7 + rub * (0.6 + 0.4 * stick)) * env(n, 0.04, 0.2)
    return fin(y, 120)


CAT = {
    "aurochs_meugle": (aurochs, 2), "ours_rugit": (ours, 2), "boulette_grogne": (boulette, 2),
    "spaghetti_fouet": (fouet, 2), "tomate_splat": (splat, 2), "gribouillis_griffe": (griffe, 2),
    "gomme_couine": (gomme, 2),
}


def main() -> int:
    total = 0
    for name, (fn, count) in CAT.items():
        for k in range(1, count + 1):
            fx.save(f"{name}_{k}", fn(k))
            total += 1
    print(f"V133 : {total} sons écrits dans {fx.OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
