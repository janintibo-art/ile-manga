"""V97 : les sons de l'Île Al Dente (synthétisés ici, versés au domaine public, CC0 1.0).

  ambiance/marmite   la sauce tomate qui mijote dans le cratère (40 s, en boucle) : de grosses bulles
                     épaisses qui font « blop » (des graves qui remontent vite), le frémissement sourd,
                     un léger chuintement de vapeur.
  sfx/eruption_1     l'éruption : le volcan gronde, la sauce gargouille de plus en plus fort, puis
                     SPLOOOSH ! la gerbe jaillit (une grosse vague de bulles et de giclées).
  sfx/splotch_1..3   une grosse goutte de sauce qui s'écrase par terre.
  sfx/couvercle_1    le Couvercle Sacré : un grand couvercle de marmite en cuivre frappé au maillet
                     (des partiels inharmoniques qui battent, une longue queue).
  sfx/louche_1       la louche géante : le cuilleron qui plonge, la sauce qu'on aspire (« slurp »).
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v97.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
import generate_sons_v58 as s58  # noqa: E402

SR = 44100
RNG = np.random.default_rng(9797)


def _n(x, peak=0.89):
    return s58._norm(x, peak)


def t_(n):
    return np.arange(n) / SR


def place(buf, ev, at, gain=1.0):
    """Ce qui dépasse la fin repart au début (la boucle reste sans raccord)."""
    n = len(buf)
    at = int(at) % n
    k = min(len(ev), n - at)
    buf[at:at + k] += ev[:k] * gain
    if k < len(ev):
        buf[:len(ev) - k] += ev[k:] * gain


def blop(f0: float, dur: float = 0.12, thick: float = 1.0) -> np.ndarray:
    """Une bulle épaisse qui éclate : un son grave dont la hauteur remonte vite, et un petit claquement."""
    n = int(dur * SR)
    t = t_(n)
    f = f0 * (1.0 + 1.6 * (t / dur) ** 1.4)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / (dur * 0.35 * thick))
    x *= np.clip(t / 0.004, 0, 1)
    pop = amb.bp(RNG.standard_normal(n), 600, 3000) * np.exp(-t / 0.006) * 0.35
    return x + pop


def marmite(seconds=40.0) -> np.ndarray:
    n = int(seconds * SR)
    out = amb.lp(amb.noise(n, "brown"), 160, 4) * 0.5 * amb.smooth_env(n, 0.4, 0.6, 1.0)
    out += amb.bp(amb.noise(n), 2500, 8000) * 0.025 * amb.smooth_env(n, 0.2, 0.3, 1.0)
    for _ in range(int(seconds * 7)):
        f0 = RNG.uniform(90, 320)
        e = blop(f0, RNG.uniform(0.08, 0.2), RNG.uniform(0.7, 1.4))
        place(out, e, RNG.integers(0, n), RNG.uniform(0.15, 0.6))
    # de temps en temps, une rafale (la sauce qui « glougloute »)
    for _ in range(int(seconds / 5)):
        at = RNG.integers(0, n)
        for k in range(int(RNG.integers(3, 7))):
            place(out, blop(RNG.uniform(70, 160), 0.16, 1.5), at + int(k * RNG.uniform(0.05, 0.11) * SR), RNG.uniform(0.4, 0.8))
    out = amb.loopify(out, 2.0)
    l = out
    r = np.roll(out, int(0.013 * SR))
    return np.stack([l, r], 1)


def eruption() -> np.ndarray:
    n = int(9.0 * SR)
    t = t_(n)
    # le grondement qui monte (4,5 s), puis la gerbe
    rise = np.clip(t / 4.5, 0, 1) ** 1.5
    out = amb.lp(amb.noise(n, "brown"), 90, 4) * (0.6 + 1.8 * rise) * np.exp(-np.clip(t - 6.0, 0, None) / 1.2)
    for _ in range(80):
        at = RNG.uniform(0.0, 4.5) ** 0.6 * 4.5 ** 0.4
        place(out, blop(RNG.uniform(60, 200), 0.18, 1.6), int(at * SR), RNG.uniform(0.2, 0.7) * (0.3 + at / 4.5))
    # SPLOOOSH : un souffle grave et large, des giclées
    m = int(3.0 * SR)
    tm = t_(m)
    whoosh = amb.lp(RNG.standard_normal(m), 900, 2) * np.exp(-tm / 0.9) * np.clip(tm / 0.03, 0, 1) * 2.2
    whoosh += np.sin(2 * np.pi * np.cumsum(np.linspace(55, 35, m)) / SR) * np.exp(-tm / 0.7) * 2.0
    place(out, whoosh, int(4.5 * SR), 1.0)
    for _ in range(60):
        place(out, blop(RNG.uniform(120, 420), 0.1, 0.8), int(RNG.uniform(4.6, 7.5) * SR), RNG.uniform(0.2, 0.6))
    return _n(s58._room(out, 1.6, 2.2, 3000.0, 0.3, seed=971))


def splotch(k: int) -> np.ndarray:
    n = int(0.5 * SR)
    t = t_(n)
    thud = np.sin(2 * np.pi * np.cumsum(np.linspace(110 + 20 * k, 50, n)) / SR) * np.exp(-t / 0.06)
    wet = amb.bp(RNG.standard_normal(n), 300, 2500) * np.exp(-t / (0.05 + 0.02 * k)) * 0.9
    out = thud + wet
    for _ in range(4 + k):
        place(out, blop(RNG.uniform(200, 500), 0.06, 0.6), int(RNG.uniform(0.02, 0.18) * SR), RNG.uniform(0.15, 0.35))
    return _n(out)


def couvercle() -> np.ndarray:
    n = int(5.5 * SR)
    t = t_(n)
    f0 = 196.0
    ratios = [1.0, 1.52, 2.07, 2.71, 3.38, 4.13, 5.02, 6.21]
    out = np.zeros(n)
    for i, r in enumerate(ratios):
        beat = 1.0 + 0.004 * RNG.standard_normal()
        a = 1.0 / (1 + i * 0.6)
        dec = 3.2 / (1 + i * 0.45)
        out += a * (np.sin(2 * np.pi * f0 * r * t) + 0.6 * np.sin(2 * np.pi * f0 * r * beat * t + 0.3)) * np.exp(-t / dec)
    # la frappe du maillet (feutre) et le léger frémissement de la tôle
    out += amb.lp(RNG.standard_normal(n), 1500) * np.exp(-t / 0.012) * 1.5
    out *= 1.0 + 0.15 * np.sin(2 * np.pi * 4.2 * t) * np.exp(-t / 2.0)
    return _n(s58._room(out, 2.0, 1.6, 6000.0, 0.25, seed=972))


def louche() -> np.ndarray:
    n = int(2.2 * SR)
    t = t_(n)
    out = np.zeros(n)
    # le cuilleron qui plonge dans la sauce
    place(out, blop(140, 0.25, 1.8), int(0.05 * SR), 0.9)
    place(out, amb.bp(RNG.standard_normal(int(0.4 * SR)), 200, 1200) * np.hanning(int(0.4 * SR)) * 0.5, int(0.08 * SR))
    # le « slurp » : un souffle qui monte, filtré comme une voyelle
    m = int(0.7 * SR)
    tm = t_(m)
    air = RNG.standard_normal(m) * np.sin(np.pi * tm / 0.7) ** 2
    fc = 500 + 2200 * (tm / 0.7)
    s = np.zeros(m)
    for k in range(0, m, 512):
        s[k:k + 512] = amb.bp(air[k:k + 512], max(fc[k] * 0.7, 100), fc[k] * 1.3)
    place(out, s * 0.8, int(1.1 * SR))
    # un « mmh » content
    h = int(0.6 * SR)
    th = t_(h)
    hum = np.sin(2 * np.pi * np.cumsum(np.linspace(180, 210, h)) / SR) * np.sin(np.pi * th / 0.6) * 0.25
    place(out, amb.lp(hum, 900), int(1.75 * SR) % n)
    return _n(out)


def main() -> int:
    amb.save("ambiance/marmite", marmite())
    fx.save("eruption_1", eruption())
    for k in range(3):
        fx.save(f"splotch_{k + 1}", splotch(k))
    fx.save("couvercle_1", couvercle())
    fx.save("louche_1", louche())
    print("V97 : les sons de l'Île Al Dente sont faits")
    return 0


if __name__ == "__main__":
    sys.exit(main())
