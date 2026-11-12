"""V135 : les cris de la faune de l'île de la jungle et de l'Île des Trois Soleils (synthétisés ici ;
versés au domaine public, CC0 1.0).

  sfx/singe_hurle_1..2             le singe hurleur : un rugissement grave et rauque qui pulse, la
                                   gorge qui résonne (on l'entend de loin dans la jungle).
  sfx/mille_pattes_cliquette_1..2  le mille-pattes : un crépitement sec de chitine, très rapide.
  sfx/araignee_siffle_1..2         l'araignée : un sifflement qui enfle, un léger crissement.
  sfx/crocodile_grogne_1..2        le crocodile : un souffle, puis un grondement très grave.
  sfx/scarabee_crisse_1..2         le scarabée : des stridulations, comme un ongle sur une carapace.
  sfx/chacal_glapit_1..2           le chacal : des jappements qui montent, puis une plainte.
  sfx/coati_couine_1..2            le coati : de petits couinements vifs et pressés.
  sfx/jaguar_feule_1..2            le jaguar : son « sciage », une suite de grognements rauques.
  sfx/coyote_hurle_1..2            le coyote : quelques jappements, puis un long hurlement.
  sfx/axolotl_bulle_1..2           l'axolotl : deux ou trois bulles toutes douces.
(L'aigle royal garde le cri d'aigle déjà dans le jeu, sfx/aigle_cri_1..3.)
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v135.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402

SR = 44100
RNG = np.random.default_rng(13535)


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


def place(out, x, at):
    i = int(at * SR)
    m = min(len(x), len(out) - i)
    if m > 0:
        out[i:i + m] += x[:m]


def singe(k):
    dur = RNG.uniform(1.7, 2.1)
    n = int(dur * SR)
    u = np.linspace(0, 1, n)
    f0 = RNG.uniform(85, 105)
    f = f0 * (0.9 + 0.25 * np.sin(np.pi * u))
    y = voix(f, [(1, 0.7), (2, 1.0), (3, 0.9), (4, 0.75), (5, 0.6), (6, 0.45), (8, 0.3), (10, 0.18)], jitter=0.03)
    # le rugissement pulse : la gorge s'ouvre et se ferme
    puls = 0.35 + 0.65 * np.clip(np.sin(2 * np.pi * RNG.uniform(2.6, 3.2) * t_(n)), 0, 1) ** 0.6
    rauque = amb.bp(RNG.standard_normal(n), 200, 1800) * 0.5
    y = amb.bp((y + rauque) * puls, 120, 2400) * env(n, 0.15, 0.4)
    return fin(y, 50)


def mille_pattes(k):
    dur = 0.75
    out = np.zeros(int(dur * SR))
    tt = 0.0
    while tt < dur - 0.03:
        m = int(RNG.uniform(0.004, 0.008) * SR)
        c = amb.bp(RNG.standard_normal(m), RNG.uniform(2500, 4000), RNG.uniform(7000, 9500)) * np.exp(-np.linspace(0, 1, m) * 6.0)
        place(out, c * RNG.uniform(0.4, 1.0) * (0.6 + 0.4 * np.sin(np.pi * tt / dur)), tt)
        tt += RNG.uniform(0.018, 0.04)
    return fin(out, 800)


def araignee(k):
    dur = 0.85
    n = int(dur * SR)
    u = np.linspace(0, 1, n)
    h = amb.bp(RNG.standard_normal(n), 2200, 8500) * (np.sin(np.pi * np.minimum(u * 1.4, 1.0)) ** 1.2)
    crisse = amb.bp(RNG.standard_normal(n), 900, 3000) * 0.3 * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 38.0 * t_(n))))
    return fin((h + crisse * (u > 0.3)) * env(n, 0.05, 0.25), 600)


def crocodile(k):
    dur = RNG.uniform(1.2, 1.5)
    n = int(dur * SR)
    out = np.zeros(n)
    s = int(0.35 * SR)
    souffle = amb.bp(RNG.standard_normal(s), 400, 3500) * np.sin(np.pi * np.linspace(0, 1, s)) * 0.6
    out[:s] += souffle
    m = n - int(0.25 * SR)
    u = np.linspace(0, 1, m)
    f = RNG.uniform(38, 48) * (1.0 + 0.15 * np.sin(np.pi * u))
    g = voix(f, [(1, 1.0), (2, 0.8), (3, 0.6), (4, 0.4), (6, 0.2)], jitter=0.04)
    rumble = amb.lp(RNG.standard_normal(m), 300) * 0.6
    am = 0.6 + 0.4 * np.sin(2 * np.pi * RNG.uniform(14, 20) * t_(m))
    place(out, (g + rumble) * am * env(m, 0.12, 0.35), 0.25)
    return fin(out, 25)


def scarabee(k):
    dur = 0.65
    out = np.zeros(int(dur * SR))
    tt = 0.02
    while tt < dur - 0.05:
        m = int(RNG.uniform(0.03, 0.05) * SR)
        g = amb.bp(RNG.standard_normal(m), 3000, 7500)
        teeth = 0.4 + 0.6 * np.sign(np.sin(2 * np.pi * RNG.uniform(160, 240) * t_(m)))
        place(out, g * teeth * np.sin(np.pi * np.linspace(0, 1, m)), tt)
        tt += RNG.uniform(0.07, 0.11)
    return fin(out, 1200)


def chacal(k):
    dur = 1.35
    out = np.zeros(int(dur * SR))
    tt = 0.0
    for j in range(RNG.integers(3, 5)):
        d = RNG.uniform(0.09, 0.14)
        m = int(d * SR)
        u = np.linspace(0, 1, m)
        f = RNG.uniform(650, 850) * (1.0 + 0.35 * u)
        y = voix(f, [(1, 1.0), (2, 0.45), (3, 0.2)]) * np.sin(np.pi * u) ** 0.6
        place(out, y * RNG.uniform(0.6, 1.0), tt)
        tt += d + RNG.uniform(0.03, 0.07)
    m = int(min(0.6, dur - tt - 0.02) * SR)
    if m > 1000:
        u = np.linspace(0, 1, m)
        f = RNG.uniform(780, 900) * (1.0 + 0.2 * np.sin(np.pi * u) - 0.25 * u)
        place(out, voix(f, [(1, 1.0), (2, 0.35), (3, 0.12)], vib=0.03, vib_f=6.5) * env(m, 0.05, 0.25) * 0.8, tt)
    return fin(amb.bp(out, 300, 6000), 200)


def coati(k):
    dur = 0.6
    out = np.zeros(int(dur * SR))
    tt = 0.0
    while tt < dur - 0.06:
        d = RNG.uniform(0.04, 0.08)
        m = int(d * SR)
        u = np.linspace(0, 1, m)
        f = RNG.uniform(1700, 2600) * (1.0 + 0.4 * np.sin(np.pi * u))
        place(out, voix(f, [(1, 1.0), (2, 0.3)]) * np.sin(np.pi * u) * RNG.uniform(0.5, 1.0), tt)
        tt += d + RNG.uniform(0.02, 0.06)
    return fin(out, 500)


def jaguar(k):
    dur = 1.4
    out = np.zeros(int(dur * SR))
    tt = 0.05
    for j in range(RNG.integers(5, 7)):
        d = RNG.uniform(0.13, 0.18)
        m = int(d * SR)
        u = np.linspace(0, 1, m)
        f = RNG.uniform(95, 130) * (1.0 - 0.15 * u)
        g = voix(f, [(1, 0.8), (2, 1.0), (3, 0.8), (4, 0.6), (5, 0.45), (7, 0.25)], jitter=0.05)
        n2 = amb.bp(RNG.standard_normal(m), 300, 2500) * 0.8
        # le grognement « scié » : une expiration, puis une inspiration plus faible
        a = 1.0 if j % 2 == 0 else 0.55
        place(out, (g + n2) * np.sin(np.pi * u) ** 0.8 * a, tt)
        tt += d + RNG.uniform(0.04, 0.08)
    return fin(amb.bp(out, 70, 3500), 50)


# (l'aigle royal garde le cri d'aigle déjà dans le jeu : sfx/aigle_cri_1..3)
def aigle(k):
    dur = 0.85
    n = int(dur * SR)
    u = np.linspace(0, 1, n)
    f = RNG.uniform(2100, 2500) * (1.0 + 0.08 * np.sin(np.pi * u * 2.0) - 0.25 * u)
    y = voix(f, [(1, 1.0), (2, 0.55), (3, 0.3), (4, 0.15)], vib=0.04, vib_f=28.0, jitter=0.01)
    scr = amb.bp(RNG.standard_normal(n), 2000, 6000) * 0.25
    return fin((y + scr) * env(n, 0.03, 0.4), 800)


def coyote(k):
    dur = 1.9
    out = np.zeros(int(dur * SR))
    tt = 0.0
    for j in range(RNG.integers(2, 4)):
        d = RNG.uniform(0.08, 0.12)
        m = int(d * SR)
        u = np.linspace(0, 1, m)
        place(out, voix(RNG.uniform(700, 900) * (1.0 + 0.3 * u), [(1, 1.0), (2, 0.4)]) * np.sin(np.pi * u) ** 0.6, tt)
        tt += d + RNG.uniform(0.04, 0.08)
    m = int((dur - tt - 0.05) * SR)
    u = np.linspace(0, 1, m)
    f = RNG.uniform(520, 600) * (0.85 + 0.35 * np.sin(np.pi * np.minimum(u * 1.4, 1.0)) - 0.1 * u)
    place(out, voix(f, [(1, 1.0), (2, 0.3), (3, 0.1)], vib=0.025, vib_f=5.5) * env(m, 0.15, 0.6), tt)
    return fin(amb.bp(out, 250, 5000), 200)


def axolotl(k):
    dur = 0.5
    out = np.zeros(int(dur * SR))
    tt = 0.02
    for j in range(RNG.integers(2, 4)):
        m = int(RNG.uniform(0.04, 0.07) * SR)
        f = np.linspace(RNG.uniform(280, 380), RNG.uniform(800, 1100), m)
        b = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * np.linspace(0, 1, m)) ** 1.5
        place(out, b * RNG.uniform(0.5, 1.0), tt)
        tt += RNG.uniform(0.09, 0.16)
    return fin(out, 150) * 0.7


CAT = {
    "singe_hurle": (singe, 2), "mille_pattes_cliquette": (mille_pattes, 2), "araignee_siffle": (araignee, 2),
    "crocodile_grogne": (crocodile, 2), "scarabee_crisse": (scarabee, 2), "chacal_glapit": (chacal, 2),
    "coati_couine": (coati, 2), "jaguar_feule": (jaguar, 2), "coyote_hurle": (coyote, 2),
    "axolotl_bulle": (axolotl, 2),
}


def main() -> int:
    total = 0
    for name, (fn, count) in CAT.items():
        for k in range(1, count + 1):
            fx.save(f"{name}_{k}", fn(k))
            total += 1
    print(f"V135 : {total} sons écrits dans {fx.OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
