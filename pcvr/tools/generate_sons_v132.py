"""V132 : les cris de la faune sauvage (synthétisés ici ; versés au domaine public, CC0 1.0).

  sfx/mouette_cri_1..3        la mouette : un « kiaaa » nasillard qui monte puis retombe,
                              avec ses harmoniques criardes et un petit vibrato.
  sfx/sanglier_grogne_1..3    le sanglier : des grognements graves en rafale, du souffle
                              par le groin.
  sfx/loup_hurle_1..2         le loup : un long hurlement qui monte, tient, et retombe.
  sfx/bouc_belement_1..2      le bouc : un « mêêê » chevrotant.
  sfx/salamandre_crache_1..2  la salamandre : un sifflement qui enfle, puis le « pfff » du
                              crachat de braise.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v132.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402

SR = 44100
RNG = np.random.default_rng(13232)


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


def fin(x):
    return norm(amb.hp(x, 60))


def voix(f, dur, harm, vib=0.0, vib_f=6.0, bruit=0.0):
    """Une voix : fréquence f (tableau), harmoniques [(rang, amp)], vibrato, souffle."""
    n = len(f)
    t = t_(n)
    fv = f * (1.0 + vib * np.sin(2 * np.pi * vib_f * t))
    ph = 2 * np.pi * np.cumsum(fv) / SR
    y = np.zeros(n)
    for k, a in harm:
        y += a * np.sin(k * ph)
    if bruit > 0:
        y += bruit * amb.bp(RNG.standard_normal(n), 800, 5000)
    return y


def mouette(k):
    dur = RNG.uniform(0.5, 0.75)
    n = int(dur * SR)
    u = np.linspace(0, 1, n)
    f0 = RNG.uniform(1050, 1350)
    f = f0 * (0.8 + 0.45 * np.sin(np.pi * np.minimum(u * 1.4, 1.0)) - 0.2 * u)
    y = voix(f, dur, [(1, 1.0), (2, 0.7), (3, 0.45), (4, 0.25), (5, 0.12)], vib=0.012, vib_f=24, bruit=0.08)
    y = amb.bp(y, 700, 7000) * env(n, 0.03, 0.18)
    out = np.zeros(int((dur + 0.5) * SR))
    out[:n] += y
    if RNG.random() < 0.7:
        m = int(0.32 * SR)
        f2 = f0 * 1.1 * (0.9 + 0.3 * np.sin(np.pi * np.linspace(0, 1, m)))
        y2 = voix(f2, 0.32, [(1, 1.0), (2, 0.6), (3, 0.4)], vib=0.01, vib_f=24, bruit=0.06) * env(m, 0.02, 0.12)
        i = int((dur + 0.08) * SR)
        out[i:i + m] += amb.bp(y2, 700, 7000)[: len(out) - i] * 0.7
    return fin(out)


def sanglier(k):
    dur = 1.1
    out = np.zeros(int(dur * SR))
    tt = 0.0
    for j in range(RNG.integers(3, 6)):
        d = RNG.uniform(0.09, 0.18)
        n = int(d * SR)
        f = np.full(n, RNG.uniform(70, 110)) * np.linspace(1.1, 0.9, n)
        y = voix(f, d, [(1, 0.6), (2, 1.0), (3, 0.8), (4, 0.5), (6, 0.3)], vib=0.08, vib_f=38, bruit=0.25)
        y = amb.lp(y, 1600) * env(n, 0.01, 0.05)
        i = int(tt * SR)
        out[i:i + n] += y[: len(out) - i]
        tt += d + RNG.uniform(0.03, 0.09)
    sn = int(0.35 * SR)
    snort = amb.bp(RNG.standard_normal(sn), 400, 2200) * env(sn, 0.02, 0.2)
    i = int(min(tt, dur - 0.36) * SR)
    out[i:i + sn] += snort * 0.6
    return fin(out)


def loup(k):
    dur = RNG.uniform(2.4, 3.0)
    n = int(dur * SR)
    u = np.linspace(0, 1, n)
    f0 = RNG.uniform(380, 460)
    f = f0 * (0.75 + 0.35 * np.minimum(u * 3.0, 1.0) - 0.25 * np.maximum(u - 0.7, 0) / 0.3)
    y = voix(f, dur, [(1, 1.0), (2, 0.25), (3, 0.08)], vib=0.012, vib_f=5.5, bruit=0.03)
    y = amb.lp(y, 2500) * env(n, 0.35, 0.6)
    # l'écho de la forêt
    out = np.zeros(n + int(0.9 * SR))
    out[:n] += y
    d = int(0.32 * SR)
    out[d:d + n] += y * 0.25
    return fin(out)


def bouc(k):
    dur = RNG.uniform(0.7, 0.95)
    n = int(dur * SR)
    u = np.linspace(0, 1, n)
    f0 = RNG.uniform(240, 300)
    f = f0 * (1.0 + 0.12 * np.sin(np.pi * u)) * (1.0 + 0.05 * np.sign(np.sin(2 * np.pi * 9.5 * t_(n))))
    y = voix(f, dur, [(1, 0.8), (2, 1.0), (3, 0.9), (4, 0.6), (5, 0.45), (6, 0.3), (8, 0.15)], vib=0.0, bruit=0.12)
    # formant « è »
    y = amb.bp(y, 400, 3200) * env(n, 0.05, 0.25)
    return fin(y)


def salamandre(k):
    dur = 1.0
    out = np.zeros(int(dur * SR))
    hn = int(0.55 * SR)
    hiss = amb.bp(RNG.standard_normal(hn), 2500, 9000) * np.linspace(0.2, 1.0, hn) ** 2
    out[:hn] += hiss * 0.7
    pn = int(0.35 * SR)
    puff = amb.bp(RNG.standard_normal(pn), 200, 1800) * env(pn, 0.005, 0.28)
    i = int(0.52 * SR)
    out[i:i + pn] += puff
    cr = np.zeros(pn)
    for j in range(14):
        c = int(RNG.uniform(0, 0.3) * SR)
        m = int(0.004 * SR)
        cr[c:c + m] += amb.bp(RNG.standard_normal(m), 3000, 9000)[: max(0, min(m, pn - c))] * RNG.uniform(0.2, 0.7)
    out[i:i + pn] += cr
    return fin(out)


CAT = {
    "mouette_cri": (mouette, 3), "sanglier_grogne": (sanglier, 3), "loup_hurle": (loup, 2),
    "bouc_belement": (bouc, 2), "salamandre_crache": (salamandre, 2),
}


def main() -> int:
    total = 0
    for name, (fn, count) in CAT.items():
        for k in range(1, count + 1):
            fx.save(f"{name}_{k}", fn(k))
            total += 1
    print(f"V132 : {total} sons écrits dans {fx.OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
