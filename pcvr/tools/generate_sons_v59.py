"""V59 : les sons de la grande île de l'est et de Carène.

Nappes d'ambiance (boucles sans raccord, stéréo) :
  ambiance/epave    dans la coque du Léviathan : le bois qui travaille (grincements longs et
                    graves, membrures qui craquent), l'eau du bassin qui clapote contre le
                    vaigrage, des gouttes, un « boum » sourd de la mer sur la quille, des cordages
                    qui se tendent ;
  ambiance/lande    les hautes terres du nord : un vent froid qui siffle dans la bruyère, des
                    rafales, des clarines de moutons au loin ;
  ambiance/brumes   la forêt des brumes : grenouilles dans les mares, gouttes qui tombent des
                    feuilles, un oiseau qui appelle au loin, un vent mou et humide ;
  ambiance/desert   le désert du sud : vent sec en rafales, sable qui siffle, criquets, le cri
                    lointain d'un rapace.
Synthétisés ici (domaine public), plus quelques grincements d'après le recueil CC0
« lavenderdotpet/CC0-Public-Domain-Sounds » (kenney_rpgaudio, s'il est donné).
Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/generate_sons_v59.py [dossier CC0-Public-Domain-Sounds]
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_sons_v56 as s56  # noqa: E402

SR = 44100
RNG = np.random.default_rng(5959)


def _env(m: int, a: float, d: float) -> np.ndarray:
    x = np.arange(m) / SR
    return np.clip(x / max(a, 1e-4), 0, 1) * np.exp(-x / d)


def scatter(out: np.ndarray, clips: list, per_min: float, gain_r, pan_r=(-1.0, 1.0)) -> None:
    n = len(out)
    count = int(n / SR / 60.0 * per_min)
    for _ in range(count):
        c = clips[RNG.integers(0, len(clips))]
        if len(c) == 0 or len(c) >= n:
            continue
        amb.place(out, c, int(RNG.integers(0, n - len(c))), RNG.uniform(*gain_r), RNG.uniform(*pan_r))


# =================================================================== l'épave

def wood_groan(seconds: float, f0: float) -> np.ndarray:
    """Un long grincement de bois : friction (impulsions irrégulières) dans des résonances graves."""
    m = int(seconds * SR)
    x = np.arange(m) / SR
    rate = f0 * (1.0 + 0.25 * np.sin(2 * np.pi * RNG.uniform(0.2, 0.6) * x + RNG.uniform(0, 6))) * np.interp(x, [0, x[-1]], [1.0, RNG.uniform(0.8, 1.25)])
    ph = np.cumsum(rate) / SR
    pulses = (np.diff(np.floor(ph), prepend=0) > 0).astype(float) * (0.6 + 0.4 * RNG.random(m))
    y = np.zeros(m)
    for fc, q in [(RNG.uniform(180, 260), 30), (RNG.uniform(420, 600), 20), (RNG.uniform(900, 1300), 12)]:
        y += amb.bp(pulses, fc * (1 - 1 / q), fc * (1 + 1 / q))
    env = np.sin(np.pi * np.clip(x / x[-1], 0, 1)) ** 0.8
    return y * env


def creak(k: int) -> np.ndarray:
    """Un craquement sec de membrure."""
    m = int(RNG.uniform(0.2, 0.5) * SR)
    x = np.arange(m) / SR
    clicks = (RNG.random(m) < 0.004).astype(float) * RNG.uniform(0.3, 1.0, m)
    y = amb.bp(clicks, 300 + 80 * k, 2500) * np.exp(-x / 0.18)
    return y


def drip() -> np.ndarray:
    m = int(0.25 * SR)
    x = np.arange(m) / SR
    f = np.interp(x, [0, 0.03, x[-1]], [900, RNG.uniform(1400, 2200), 1500])
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-x / 0.04) * np.clip(x / 0.002, 0, 1)


def hull_boom() -> np.ndarray:
    m = int(1.6 * SR)
    x = np.arange(m) / SR
    y = np.sin(2 * np.pi * 46 * x) * np.exp(-x / 0.45) + amb.lp(RNG.standard_normal(m), 180) * np.exp(-x / 0.3) * 0.6
    return y * np.clip(x / 0.03, 0, 1)


def epave_bed(lib: Path | None, seconds: float = 52.0) -> np.ndarray:
    n = int(seconds * SR)
    out = s56.lapping(n) * 0.9
    # l'eau du bassin, assourdie par la coque
    out[:, 0] = amb.lp(out[:, 0], 1100)
    out[:, 1] = amb.lp(out[:, 1], 1100)
    groans = [wood_groan(RNG.uniform(1.4, 3.2), RNG.uniform(14, 34)) for _ in range(7)]
    scatter(out, groans, 9, (0.18, 0.42))
    scatter(out, [creak(k) for k in range(5)], 16, (0.1, 0.3))
    scatter(out, [drip() for _ in range(4)], 18, (0.04, 0.1))
    scatter(out, [hull_boom()], 2.5, (0.25, 0.4), pan_r=(-0.3, 0.3))
    if lib is not None:
        cr = [s56._read(lib, f"kenney_rpgaudio/Audio/creak{i}.ogg") for i in (1, 2, 3)]
        cr = [amb.lp(s56._shift(c, RNG.uniform(-12.0, -7.0)), 1800) for c in cr if len(c)]
        if cr:
            scatter(out, cr, 7, (0.14, 0.3))
    room = np.stack([amb.lp(amb.noise(n, "brown"), 120)] * 2, axis=1) * 0.05
    out = s56._room(out + room, 1.4, 2.8, 2200.0, 0.4, seed=591)
    return amb.loopify(out, 2.5)


# =================================================================== les hautes terres

def wind(n: int, lo: float, hi: float, gust_rate: float, gmin: float, gmax: float) -> np.ndarray:
    g = amb.smooth_env(n, gust_rate, gmin, gmax)
    l = amb.bp(amb.noise(n, "pink"), lo, hi) * g
    r = amb.bp(amb.noise(n, "pink"), lo, hi) * np.roll(g, SR // 3)
    return amb.stereo(l, r)


def whistle(n: int, base: float) -> np.ndarray:
    """Le vent qui siffle : une résonance étroite qui glisse avec les rafales."""
    f = base * amb.smooth_env(n, 0.25, 0.85, 1.25)
    y = amb.tv_lowpass(amb.noise(n, "white"), f * 1.02) - amb.tv_lowpass(amb.noise(n, "white"), f * 0.98)
    return y * amb.smooth_env(n, 0.2, 0.0, 1.0) ** 2


def clarine(k: int) -> np.ndarray:
    """Une clarine (cloche de mouton) au loin : trois tintements irréguliers."""
    f = [820.0, 1010.0, 930.0, 760.0][k % 4] * RNG.uniform(0.97, 1.03)
    m = int(1.6 * SR)
    out = np.zeros(m)
    t = 0.0
    for i in range(RNG.integers(2, 5)):
        mm = int(0.6 * SR)
        x = np.arange(mm) / SR
        y = sum(a * np.sin(2 * np.pi * f * r * x) * np.exp(-x / d) for r, a, d in [(1, 1, 0.18), (2.32, 0.6, 0.08), (3.9, 0.3, 0.04)])
        amb.place(out, y * np.clip(x / 0.002, 0, 1), int(t * SR), RNG.uniform(0.5, 1.0))
        t += RNG.uniform(0.18, 0.32)
        if int(t * SR) + mm >= m:
            break
    return amb.lp(out, 3000)


def lande_bed(seconds: float = 50.0) -> np.ndarray:
    n = int(seconds * SR)
    out = wind(n, 150, 2200, 0.35, 0.25, 1.0) * 0.7
    w = whistle(n, 820.0) * 0.06
    out[:, 0] += w
    out[:, 1] += np.roll(w, SR)
    rustle = amb.hp(amb.noise(n, "white"), 3500) * amb.smooth_env(n, 0.5, 0.0, 1.0) * 0.05
    out += amb.stereo(rustle, np.roll(rustle, SR // 2))
    scatter(out, [clarine(k) for k in range(4)], 5, (0.03, 0.07))
    return amb.loopify(out, 2.5)


# =================================================================== la forêt des brumes

def frog(k: int) -> np.ndarray:
    """Une grenouille : un coassement grave, en impulsions rapprochées, nasillard."""
    reps = RNG.integers(2, 6)
    parts = []
    f0 = RNG.uniform(160, 260) * (1.0 + 0.1 * k)
    for i in range(reps):
        m = int(RNG.uniform(0.08, 0.14) * SR)
        x = np.arange(m) / SR
        pulses = np.sign(np.sin(2 * np.pi * f0 * x)) * 0.5 + 0.5
        y = amb.bp(pulses, 400, 1800) * np.hanning(m)
        parts += [y, np.zeros(int(RNG.uniform(0.04, 0.09) * SR))]
    return np.concatenate(parts)


def far_bird() -> np.ndarray:
    """Un oiseau qui appelle au loin dans le brouillard : deux notes plaintives."""
    out = []
    for f0, f1, d in [(1700, 1450, 0.32), (1500, 1200, 0.45)]:
        m = int(d * SR)
        x = np.arange(m) / SR
        f = np.interp(x, [0, x[-1]], [f0, f1])
        out += [np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * x / x[-1]) ** 1.5, np.zeros(int(0.15 * SR))]
    return amb.lp(np.concatenate(out), 2500)


def brumes_bed(seconds: float = 50.0) -> np.ndarray:
    n = int(seconds * SR)
    out = wind(n, 60, 700, 0.15, 0.3, 0.7) * 0.45
    scatter(out, [frog(k) for k in range(6)], 34, (0.05, 0.2))
    scatter(out, [drip() for _ in range(6)], 40, (0.03, 0.09))
    scatter(out, [far_bird()], 4, (0.04, 0.08))
    insects = amb.bp(amb.noise(n, "white"), 4000, 6500) * amb.smooth_env(n, 0.2, 0.3, 1.0) * 0.02
    out += amb.stereo(insects, np.roll(insects, SR))
    out = s56._room(out, 1.8, 2.2, 2400.0, 0.35, seed=592)
    return amb.loopify(out, 2.5)


# =================================================================== le désert

def hawk() -> np.ndarray:
    """Le cri d'un rapace très haut : un « kiiii-ah » qui descend."""
    m = int(1.1 * SR)
    x = np.arange(m) / SR
    f = np.interp(x, [0, 0.15, 0.8, x[-1]], [2600, 3300, 2500, 1900])
    vib = 1.0 + 0.03 * np.sin(2 * np.pi * 28 * x)
    y = np.sin(2 * np.pi * np.cumsum(f * vib) / SR) + 0.3 * np.sin(4 * np.pi * np.cumsum(f * vib) / SR)
    y *= np.sin(np.pi * x / x[-1]) ** 0.7
    return amb.lp(y, 4500)


def cricket_dry(n: int) -> np.ndarray:
    x = np.arange(n) / SR
    chirp = (np.sin(2 * np.pi * 26 * x) > 0.6).astype(float)
    y = np.sin(2 * np.pi * 5200 * x) * chirp * amb.smooth_env(n, 0.3, 0.0, 1.0)
    return amb.lp(y, 7000)


def desert_bed(seconds: float = 50.0) -> np.ndarray:
    n = int(seconds * SR)
    out = wind(n, 120, 1500, 0.3, 0.2, 1.0) * 0.6
    sand = amb.hp(amb.noise(n, "white"), 5000) * amb.smooth_env(n, 0.3, 0.0, 1.0) ** 2 * 0.07
    out += amb.stereo(sand, np.roll(sand, SR // 4))
    cr = cricket_dry(n) * 0.012
    out += amb.stereo(np.roll(cr, SR // 5), cr)
    scatter(out, [hawk()], 2.5, (0.03, 0.06))
    return amb.loopify(out, 2.5)


# =================================================================== lancement

def main() -> int:
    lib = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    if lib is not None and not lib.is_dir():
        lib = None
    amb.save("ambiance/epave", epave_bed(lib))
    amb.save("ambiance/lande", lande_bed())
    amb.save("ambiance/brumes", brumes_bed())
    amb.save("ambiance/desert", desert_bed())
    return 0


if __name__ == "__main__":
    sys.exit(main())
