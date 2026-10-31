"""V91 : les sons de l'Île de Larsen (synthétisés ici, versés au domaine public, CC0 1.0).

  ambiance/pluie         Rainville sous la pluie : le grésillement de l'averse, les gouttes sur les
                         toiles des yourtes, les « tic » sur la tôle des garages, une gouttière qui coule
                         (40 s, en boucle sans raccord).
  ambiance/camp_fleurs   le Camp des Fleurs : une brise douce, des carillons au vent, des oiseaux, et,
                         au loin, un djembé qui ne s'arrête jamais tout à fait (40 s, en boucle).
  sfx/djembe_1..3        un coup de djembé : la basse (au milieu de la peau), le ton (au bord), la claque.
  sfx/carillon_1..2      le grand carillon de la Colline du Feedback (des tubes accordés en pentatonique).
  sfx/larsen_1           l'effet Larsen : une corde de guitare pincée, puis l'ampli qui se met à siffler,
                         de plus en plus fort… et le « pop » du câble qu'on débranche vite.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v91.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
import generate_sons_v58 as s58  # noqa: E402

SR = 44100
RNG = np.random.default_rng(9191)
PENTA = [0, 2, 4, 7, 9]


def _n(x, peak=0.89):
    return s58._norm(x, peak)


def place(buf, ev, at, gain=1.0, pan=0.0):
    """Comme amb.place, mais ce qui dépasse la fin repart au début (la boucle reste sans raccord)."""
    n = len(buf)
    at = int(at) % n
    k = min(len(ev), n - at)
    amb.place(buf, ev[:k], at, gain, pan)
    if k < len(ev):
        amb.place(buf, ev[k:], 0, gain, pan)


def hz(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


# =========================================================================== les ambiances

def pluie(seconds=40.0):
    n = int(seconds * SR)
    t = np.arange(n) / SR
    out = np.zeros((n, 2))
    # l'averse : un souffle large, qui respire un peu (les rafales)
    gust = amb.smooth_env(n, 0.12, 0.7, 1.0)
    for ch in range(2):
        hiss = amb.bp(RNG.standard_normal(n), 500.0, 9000.0) * 0.5 + amb.bp(RNG.standard_normal(n), 150.0, 900.0) * 0.35
        out[:, ch] += hiss * gust
    # les gouttes sur les toiles : de tout petits coups sourds, très nombreux
    drop = lambda f, d: np.sin(2 * np.pi * f * np.arange(int(d * SR)) / SR) * np.exp(-np.arange(int(d * SR)) / SR / (d * 0.25))
    for k in range(int(seconds * 140)):
        at = RNG.integers(0, n - 4000)
        f = RNG.uniform(700.0, 2400.0)
        place(out, drop(f, 0.03) * RNG.uniform(0.05, 0.16), at, 1.0, RNG.uniform(-0.9, 0.9))
    # les « tic » sur la tôle des garages (plus clairs, qui sonnent un peu)
    for k in range(int(seconds * 5)):
        at = RNG.integers(0, n - 20000)
        f = RNG.uniform(2200.0, 4200.0)
        m = int(0.18 * SR)
        x = np.arange(m) / SR
        tin = (np.sin(2 * np.pi * f * x) + 0.5 * np.sin(2 * np.pi * f * 1.73 * x)) * np.exp(-x / 0.035)
        place(out, tin * RNG.uniform(0.06, 0.14), at, 1.0, RNG.uniform(-0.8, 0.8))
    # la gouttière : un filet d'eau qui glougloute, à droite
    trickle = amb.bp(RNG.standard_normal(n), 900.0, 3000.0) * amb.smooth_env(n, 3.0, 0.2, 1.0) * 0.18
    out[:, 1] += trickle
    out[:, 0] += trickle * 0.35
    for k in range(int(seconds * 3)):
        at = RNG.integers(0, n - 8000)
        m = int(0.08 * SR)
        x = np.arange(m) / SR
        bl = np.sin(2 * np.pi * (500.0 + 900.0 * x / 0.08) * x) * np.exp(-x / 0.02)
        place(out, bl * 0.12, at, 1.0, 0.6)
    return amb.loopify(out, 2.5)


def carillon_coup(f, dur=3.5):
    # un tube de carillon : des partiels inharmoniques, le plus aigu s'éteint vite
    m = int(dur * SR)
    x = np.arange(m) / SR
    y = sum(a * np.sin(2 * np.pi * f * r * x + RNG.uniform(0, 6.28)) * np.exp(-x / d)
            for r, a, d in [(1.0, 1.0, 1.6), (2.756, 0.45, 0.8), (5.404, 0.25, 0.35), (8.933, 0.1, 0.15)])
    y *= 1.0 + 0.03 * np.sin(2 * np.pi * 3.1 * x)          # le tube qui tourne sur sa ficelle
    return y * np.clip(x / 0.002, 0, 1)


def djembe_coup(kind, gain=1.0):
    dur = 0.6
    m = int(dur * SR)
    x = np.arange(m) / SR
    if kind == "basse":
        f = 78.0 * (1.0 + 0.25 * np.exp(-x / 0.02))
        y = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-x / 0.22)
        y += 0.25 * amb.lp(RNG.standard_normal(m), 400.0) * np.exp(-x / 0.02)
    elif kind == "ton":
        y = sum(a * np.sin(2 * np.pi * f * x) * np.exp(-x / d) for f, a, d in [(330.0, 1.0, 0.12), (528.0, 0.5, 0.08), (712.0, 0.3, 0.05), (165.0, 0.4, 0.15)])
        y += 0.2 * amb.bp(RNG.standard_normal(m), 800.0, 4000.0) * np.exp(-x / 0.01)
    else:
        y = amb.bp(RNG.standard_normal(m), 900.0, 6500.0) * np.exp(-x / 0.035) * 1.3
        y += 0.5 * np.sin(2 * np.pi * 420.0 * x) * np.exp(-x / 0.04)
    return y * gain


def camp_fleurs(seconds=40.0):
    n = int(seconds * SR)
    out = np.zeros((n, 2))
    # la brise
    for ch in range(2):
        out[:, ch] += amb.lp(RNG.standard_normal(n), 500.0) * amb.smooth_env(n, 0.08, 0.15, 0.6) * 0.5
    # les carillons (pentatonique de ré), quand le vent souffle un peu plus
    t = 0.6
    while t < seconds - 4.0:
        k = RNG.integers(2, 6)
        for j in range(k):
            note = 74 + 12 * RNG.integers(0, 2) + PENTA[RNG.integers(0, 5)]
            place(out, carillon_coup(hz(note), 3.0) * RNG.uniform(0.05, 0.11), int((t + j * RNG.uniform(0.08, 0.3)) * SR), 1.0, RNG.uniform(-0.7, 0.7))
        t += RNG.uniform(2.5, 6.0)
    # le djembé, au loin, de l'autre côté du camp (un rythme à 100, avec des silences)
    beat = 60.0 / 100.0
    motif = [("basse", 0.0), ("ton", 0.5), ("ton", 0.75), ("claque", 1.0), ("basse", 1.5), ("ton", 2.0), ("claque", 2.5), ("ton", 3.0), ("ton", 3.25), ("claque", 3.5)]
    far = np.zeros(n)
    bar = 0
    while (bar + 1) * 4 * beat < seconds:
        if bar % 6 != 5:
            for kind, b in motif:
                at = int(((bar * 4 + b) * beat + RNG.normal(0, 0.008)) * SR)
                place(far, djembe_coup(kind, RNG.uniform(0.75, 1.0)), at)
        bar += 1
    far = amb.lp(far, 1800.0)
    far = s58._room(np.stack([far, np.roll(far, 91)], 1), 2.2, 1.4, 2500.0, 0.6, seed=91)[:n]
    out += far * 0.22
    # des oiseaux, de temps en temps
    for k in range(int(seconds / 3.0)):
        bird = amb.chirp_call(RNG.uniform(2600, 3600), RNG.uniform(3800, 5200), RNG.uniform(0.08, 0.2), vib=RNG.uniform(0, 30))
        for r in range(RNG.integers(1, 4)):
            place(out, bird * 0.06, RNG.integers(0, n - 20000) if r == 0 else min(n - 20000, int(RNG.integers(0, n - 20000))), 1.0, RNG.uniform(-0.9, 0.9))
    return amb.loopify(out, 2.5)


# =========================================================================== les bruitages

def carillon(k):
    dur = 4.5
    n = int(dur * SR)
    out = np.zeros((n, 2))
    notes = [74, 76, 78, 81, 83, 86, 88]
    t = 0.0
    order = RNG.permutation(len(notes)) if k == 0 else np.arange(len(notes))[::-1]
    for i in order:
        place(out, carillon_coup(hz(notes[i] + 12 * (k == 1 and i % 3 == 0)), 3.5) * RNG.uniform(0.5, 0.9), int(t * SR), 1.0, -0.6 + 1.2 * i / len(notes))
        t += RNG.uniform(0.07, 0.22)
    return s58._room(out, 2.5, 1.6, 6000.0, 0.3, seed=92 + k)


def larsen():
    dur = 3.2
    n = int(dur * SR)
    x = np.arange(n) / SR
    # la corde pincée (Karplus-Strong), un mi grave
    p = int(SR / 82.4)
    buf = RNG.uniform(-1, 1, p)
    pl = np.zeros(n)
    for i in range(n):
        pl[i] = buf[i % p]
        buf[i % p] = 0.5 * (buf[i % p] + buf[(i + 1) % p]) * 0.996
    # le sifflement qui monte : une note aiguë qui enfle, se fixe, vibre, et sature
    f = 2480.0 + 30.0 * np.tanh((x - 0.6) * 4.0) + 6.0 * np.sin(2 * np.pi * 5.5 * x) * (x > 1.2)
    ph = 2 * np.pi * np.cumsum(f) / SR
    grow = np.clip((x - 0.35) / 1.6, 0, 1) ** 1.6
    sq = np.sin(ph) * grow
    y = pl * 0.8 + sq * 1.2
    y = np.tanh(y * 3.0)                                     # l'ampli à fond
    y = amb.lp(y, 7000.0)
    hum = 0.06 * np.sin(2 * np.pi * 50.0 * x) + 0.03 * np.sin(2 * np.pi * 100.0 * x)
    y += hum
    # on débranche : coupure nette, un « pop »
    cut = int(2.75 * SR)
    y[cut:] = 0.0
    m = int(0.05 * SR)
    pop = amb.lp(RNG.standard_normal(m), 600.0) * np.exp(-np.arange(m) / SR / 0.01) * 1.5
    y[cut:cut + m] += pop
    return y


def main() -> int:
    amb.save("ambiance/pluie", pluie())
    amb.save("ambiance/camp_fleurs", camp_fleurs())
    for i, kind in enumerate(["basse", "ton", "claque"]):
        y = djembe_coup(kind)
        fx.save(f"djembe_{i + 1}", _n(s58._room(np.stack([y, np.roll(y, 23)], 1), 0.8, 0.4, 5000.0, 0.15, seed=93 + i)[:, 0]))
    for k in range(2):
        c = carillon(k)
        fx.save(f"carillon_{k + 1}", _n(c[:, 0] * 0.5 + c[:, 1] * 0.5))
    fx.save("larsen_1", _n(larsen()))
    print("V91 : les sons de l'Île de Larsen sont faits")
    return 0


if __name__ == "__main__":
    sys.exit(main())
