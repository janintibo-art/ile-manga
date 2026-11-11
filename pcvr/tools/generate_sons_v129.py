"""V129 : les sons du combat spectaculaire (synthétisés ici ; versés au domaine public, CC0 1.0).

  sfx/impact_acier_1..4     l'acier qui mord : un « tchang » métallique court (des partiels
                            inharmoniques de lame qui chante, vite éteints), un claquement
                            de bruit très bref, un petit grave de choc.
  sfx/impact_braise_1..3    la lame de forge : un souffle de braise qui s'embrase (« fouff »),
                            des crépitements d'étincelles, un grave chaud.
  sfx/impact_foudre_1..3    l'Épée des Nuées : un claquement électrique sec, un grésillement
                            qui crépite et retombe, un petit coup de tonnerre grave.
  sfx/impact_maree_1..3     le Trident : une gerbe d'eau (éclaboussure, gouttes qui
                            retombent), un « bloup » rond.
  sfx/impact_cristal_1..3   la Lame du Cœur : un tintement de cristal (partiels aigus
                            purs), un battement sourd de cœur dessous.
  sfx/impact_arcane_1..3    le bâton : un « vvoum » magique (deux sinus qui glissent l'un
                            contre l'autre), un scintillement.
  sfx/coup_critique_1..2    le coup qui pèse : un « boum » grave et sec, une onde qui siffle.
  sfx/onde_lame_1..2        le croissant d'énergie du coup chargé : un souffle large qui file
                            et monte, avec un sifflement de lame.
  sfx/cercle_magique_1..3   le cercle de runes qui s'ouvre : un accord cristallin qui monte
                            (arpège rapide), un souffle doux et une cloche lointaine.
  sfx/glace_jaillit_1..2    les pics de glace : des craquements de glace qui jaillissent l'un
                            après l'autre, puis un éclatement de verre givré.
  sfx/explosion_feu_1..3    l'explosion de la boule de feu : un « vroumm » profond, le souffle
                            des flammes, des crépitements qui retombent.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v129.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402

SR = 44100
RNG = np.random.default_rng(12929)


def t_(n):
    return np.arange(n) / SR


def norm(x, peak=0.89):
    return x / (np.max(np.abs(x)) + 1e-9) * peak


def env_exp(n, tau, att=0.002):
    t = t_(n)
    return np.clip(t / att, 0, 1) * np.exp(-t / tau)


def place(buf, ev, at_s, gain=1.0):
    i = int(at_s * SR)
    if i >= len(buf):
        return
    m = min(len(ev), len(buf) - i)
    buf[i:i + m] += ev[:m] * gain


def fin(x, fade=0.04):
    k = min(int(fade * SR), len(x) // 3)
    x = x.copy()
    x[-k:] *= np.linspace(1, 0, k)
    return norm(amb.hp(x, 40))


def partiels(dur, fs, taus, amps, detune=0.0):
    n = int(dur * SR)
    t = t_(n)
    y = np.zeros(n)
    for f, tau, a in zip(fs, taus, amps):
        f2 = f * (1 + RNG.uniform(-detune, detune))
        y += a * np.sin(2 * np.pi * f2 * t + RNG.uniform(0, 6.28)) * np.exp(-t / tau)
    return y


def clic(dur=0.012, lo=1500, hi=9000):
    n = int(dur * SR)
    return amb.bp(RNG.standard_normal(n), lo, hi) * np.exp(-t_(n) / (dur / 4))


def grave(f0, f1, dur, tau):
    n = int(dur * SR)
    t = t_(n)
    f = np.geomspace(f0, f1, n)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * env_exp(n, tau, 0.003)


def souffle(dur, lo0, hi0, lo1, hi1, att, tau):
    n = int(dur * SR)
    x = RNG.standard_normal(n)
    # bande qui glisse : on mélange deux bandes fixes selon l'avancement
    a = amb.bp(x, lo0, hi0)
    b = amb.bp(x, lo1, hi1)
    u = np.linspace(0, 1, n)
    y = a * (1 - u) + b * u
    return y * env_exp(n, tau, att)


def crepite(dur, n_ev, lo=2000, hi=9000, rate_decay=0.4):
    n = int(dur * SR)
    y = np.zeros(n)
    for k in range(n_ev):
        at = (RNG.exponential(rate_decay)) % dur
        g = RNG.uniform(0.2, 1.0) * np.exp(-at / (dur * 0.6))
        place(y, clic(RNG.uniform(0.003, 0.01), lo, hi), at, g)
    return y


def impact_acier(k):
    dur = 0.7
    n = int(dur * SR)
    y = np.zeros(n)
    base = RNG.uniform(1800, 2600)
    ratios = [1.0, 1.47, 2.09, 2.76, 3.9, 5.4]
    p = partiels(dur, [base * r for r in ratios], [0.22, 0.16, 0.12, 0.09, 0.05, 0.03], [1.0, 0.7, 0.55, 0.4, 0.25, 0.15], 0.01)
    place(y, p * 0.5, 0.0)
    place(y, clic(0.02, 1200, 12000), 0.0, 1.4)
    place(y, grave(180, 70, 0.2, 0.05), 0.0, 0.6)
    return fin(y)


def impact_braise(k):
    dur = 0.9
    n = int(dur * SR)
    y = np.zeros(n)
    place(y, souffle(0.6, 150, 900, 400, 2500, 0.01, 0.18), 0.0, 1.0)
    place(y, crepite(0.8, 26, 2500, 10000, 0.25), 0.02, 0.7)
    place(y, grave(120, 60, 0.3, 0.09), 0.0, 0.7)
    place(y, clic(0.015, 800, 6000), 0.0, 0.8)
    return fin(y)


def impact_foudre(k):
    dur = 1.0
    n = int(dur * SR)
    y = np.zeros(n)
    place(y, clic(0.006, 3000, 14000), 0.0, 2.0)
    # grésillement : des impulsions serrées, de plus en plus espacées
    tt = 0.0
    while tt < 0.45:
        place(y, clic(RNG.uniform(0.002, 0.006), 2000, 12000), tt, RNG.uniform(0.3, 1.0) * np.exp(-tt / 0.2))
        tt += RNG.uniform(0.002, 0.012) * (1 + tt * 12)
    buzz = amb.bp(np.sign(np.sin(2 * np.pi * 90 * t_(int(0.3 * SR)))) + RNG.standard_normal(int(0.3 * SR)) * 0.3, 200, 4000)
    place(y, buzz * env_exp(len(buzz), 0.08), 0.0, 0.35)
    thunder = amb.lp(RNG.standard_normal(int(0.9 * SR)), 180) * env_exp(int(0.9 * SR), 0.25, 0.03)
    place(y, thunder, 0.03, 2.5)
    return fin(y)


def impact_maree(k):
    dur = 0.9
    n = int(dur * SR)
    y = np.zeros(n)
    place(y, souffle(0.4, 600, 5000, 1500, 9000, 0.004, 0.09), 0.0, 1.2)
    bl = grave(RNG.uniform(380, 520), 160, 0.18, 0.06)
    place(y, bl, 0.005, 0.8)
    for j in range(12):
        f = RNG.uniform(900, 2600)
        d = grave(f, f * 1.6, 0.05, 0.015)
        place(y, d, RNG.uniform(0.08, 0.7), RNG.uniform(0.1, 0.35))
    return fin(y)


def impact_cristal(k):
    dur = 1.2
    n = int(dur * SR)
    y = np.zeros(n)
    base = RNG.uniform(2400, 3200)
    p = partiels(dur, [base, base * 2.01, base * 2.98, base * 4.2], [0.5, 0.35, 0.22, 0.12], [1.0, 0.5, 0.35, 0.2], 0.004)
    place(y, p * 0.5, 0.0)
    place(y, clic(0.01, 3000, 12000), 0.0, 0.8)
    # « toum-toum » sourd
    for at in [0.0, 0.2]:
        place(y, grave(85, 55, 0.18, 0.06), at, 0.9 if at == 0 else 0.6)
    return fin(y)


def impact_arcane(k):
    dur = 0.9
    n = int(dur * SR)
    t = t_(n)
    f1 = np.geomspace(RNG.uniform(500, 700), 180, n)
    f2 = f1 * 1.012
    ph1 = 2 * np.pi * np.cumsum(f1) / SR
    ph2 = 2 * np.pi * np.cumsum(f2) / SR
    y = (np.sin(ph1) + np.sin(ph2) + 0.4 * np.sin(2 * ph1)) * env_exp(n, 0.18, 0.004)
    sc = partiels(dur, list(RNG.uniform(3000, 7000, 6)), [0.12] * 6, [0.2] * 6)
    sc *= (0.5 + 0.5 * np.sin(2 * np.pi * 23 * t))
    y = y * 0.6 + sc * 0.4
    place(y, clic(0.01, 1000, 8000), 0.0, 0.6)
    return fin(y)


def coup_critique(k):
    dur = 1.0
    n = int(dur * SR)
    y = np.zeros(n)
    place(y, grave(140, 38, 0.6, 0.16), 0.0, 1.0)
    place(y, amb.lp(RNG.standard_normal(int(0.4 * SR)), 300) * env_exp(int(0.4 * SR), 0.08), 0.0, 1.3)
    place(y, souffle(0.5, 2000, 6000, 600, 2000, 0.005, 0.12), 0.02, 0.35)
    place(y, clic(0.02, 800, 9000), 0.0, 1.0)
    return fin(y)


def onde_lame(k):
    dur = 0.8
    n = int(dur * SR)
    y = np.zeros(n)
    w = souffle(0.7, 200, 1200, 1500, 6000, 0.06, 0.25)
    place(y, w, 0.0, 1.0)
    f = np.geomspace(1200, RNG.uniform(2600, 3400), int(0.5 * SR))
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * env_exp(len(f), 0.15, 0.04)
    place(y, s, 0.03, 0.25)
    return fin(y)


def cercle_magique(k):
    dur = 1.6
    n = int(dur * SR)
    y = np.zeros(n)
    root = RNG.choice([440.0, 466.16, 523.25])
    notes = [1.0, 1.25, 1.5, 2.0, 2.5]
    for j, r in enumerate(notes):
        p = partiels(1.2, [root * r * 2, root * r * 4.02], [0.35, 0.15], [1.0, 0.25], 0.002)
        place(y, p, j * 0.045, 0.5)
    place(y, souffle(1.2, 300, 2000, 1500, 7000, 0.3, 0.5), 0.0, 0.25)
    bell = partiels(1.5, [root, root * 2.76, root * 5.4], [0.6, 0.3, 0.15], [0.6, 0.25, 0.1])
    place(y, bell, 0.05, 0.4)
    return fin(y)


def glace_jaillit(k):
    dur = 1.4
    n = int(dur * SR)
    y = np.zeros(n)
    for j in range(7):
        at = j * 0.045 + RNG.uniform(0, 0.01)
        cr = amb.bp(RNG.standard_normal(int(0.08 * SR)), 1500, 9000) * env_exp(int(0.08 * SR), 0.015)
        place(y, cr, at, 0.8)
        place(y, grave(RNG.uniform(260, 380), 120, 0.1, 0.03), at, 0.4)
        f = RNG.uniform(3000, 5500)
        place(y, partiels(0.3, [f, f * 1.51], [0.08, 0.05], [0.5, 0.3]), at, 0.3)
    # l'éclatement final
    sh = amb.bp(RNG.standard_normal(int(0.5 * SR)), 2500, 12000) * env_exp(int(0.5 * SR), 0.1)
    place(y, sh, 0.95, 0.9)
    for j in range(14):
        f = RNG.uniform(2500, 7000)
        place(y, partiels(0.2, [f], [0.05], [1.0]), 0.95 + RNG.uniform(0, 0.3), RNG.uniform(0.1, 0.3))
    return fin(y)


def explosion_feu(k):
    dur = 2.0
    n = int(dur * SR)
    y = np.zeros(n)
    place(y, grave(90, 28, 1.2, 0.35), 0.0, 1.0)
    rumble = amb.lp(RNG.standard_normal(int(1.6 * SR)), 220) * env_exp(int(1.6 * SR), 0.45, 0.01)
    place(y, rumble, 0.0, 2.2)
    place(y, souffle(1.0, 200, 1500, 500, 3500, 0.01, 0.3), 0.0, 0.9)
    place(y, crepite(1.6, 40, 2000, 9000, 0.5), 0.05, 0.5)
    place(y, clic(0.03, 300, 6000), 0.0, 1.2)
    return fin(y, 0.2)


CAT = {
    "impact_acier": (impact_acier, 4), "impact_braise": (impact_braise, 3), "impact_foudre": (impact_foudre, 3),
    "impact_maree": (impact_maree, 3), "impact_cristal": (impact_cristal, 3), "impact_arcane": (impact_arcane, 3),
    "coup_critique": (coup_critique, 2), "onde_lame": (onde_lame, 2), "cercle_magique": (cercle_magique, 3),
    "glace_jaillit": (glace_jaillit, 2), "explosion_feu": (explosion_feu, 3),
}


def main() -> int:
    total = 0
    for name, (fn, count) in CAT.items():
        for k in range(1, count + 1):
            fx.save(f"{name}_{k}", fn(k))
            total += 1
    print(f"V129 : {total} sons écrits dans {fx.OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
