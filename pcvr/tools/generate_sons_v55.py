"""V55 : les sons de la mer — nage, plongée, vie sous-marine, Atlantide.

Synthétisés ici (domaine public) :
  sfx/baleine_1..2        chant de baleine (longues glissades graves, harmoniques, écho du large)
  sfx/dauphin_1..2        sifflements et clics de dauphin
  sfx/perle_1             la Perle de Lumière (carillon de cristal qui scintille)
  sfx/cristal_eveil_1     le Grand Cristal se rallume (montée lumineuse, accord ouvert)
  sfx/meduse_pique_1..2   piqûre de méduse (crépitement électrique étouffé)
  ambiance/atlantide      le dôme d'Atlantide (bourdon chaud, eau lointaine, carillons de verre)
D'après le recueil CC0 « lavenderdotpet/CC0-Public-Domain-Sounds » :
  sfx/plongeon_1..2       on entre dans l'eau (« 40 CC0 water splash »)
  sfx/nage_1..3           brasses à la surface (éclaboussures courtes)
  sfx/nage_sous_1..3      brasses sous l'eau (remous étouffés)
  sfx/bulles_1..3         bulles qui remontent
  sfx/respiration_1..2    on reprend son souffle en sortant la tête (« warfork-cc0 », gasp)
  sfx/suffoque_1          plus d'air : bulles qui s'échappent, gorge serrée
  sfx/requin_menace_1..2, requin_morsure_1..2, requin_mort_1 : le requin
  ambiance/sous_marin     sous l'eau (« warfork-cc0 » underwater, grondement du large, bulles)
Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/generate_sons_v55.py <dossier CC0-Public-Domain-Sounds>
"""
from pathlib import Path
import sys

import numpy as np
from scipy import signal

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402

SR = 44100
RNG = np.random.default_rng(5555)


def _norm(x: np.ndarray) -> np.ndarray:
    sos = signal.butter(2, 40.0, btype="highpass", fs=SR, output="sos")
    x = signal.sosfilt(sos, x)
    return x / (np.max(np.abs(x)) + 1e-9) * 0.89


def _reverb(x: np.ndarray, seconds: float, decay: float, lp_hz: float, wet: float) -> np.ndarray:
    """Réverbération de grand large : bruit décroissant filtré, convolué."""
    n = int(seconds * SR)
    t = np.arange(n) / SR
    ir = RNG.standard_normal(n) * np.exp(-t * decay)
    ir = amb.lp(ir, lp_hz)
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    y = signal.fftconvolve(x, ir)[: len(x) + n]
    out = np.zeros(len(y))
    out[: len(x)] += x * (1 - wet)
    out += y * wet * 3.0
    return out


# =================================================================== synthèses

def whale(k: int) -> np.ndarray:
    """Chant de baleine à bosse : trois phrases glissées (montée, gémissement, grondement)."""
    dur = [7.5, 8.5][k]
    n = int(dur * SR)
    t = np.arange(n) / SR
    y = np.zeros(n)
    phrases = [
        [(0.2, 2.6, 140.0, 420.0), (3.0, 5.4, 380.0, 180.0), (5.8, 7.2, 90.0, 70.0)],
        [(0.3, 2.0, 220.0, 260.0), (2.3, 4.6, 260.0, 600.0), (5.0, 8.0, 160.0, 110.0)],
    ][k]
    for (a, b, f0, f1) in phrases:
        m = (t >= a) & (t < b)
        tt = (t[m] - a) / (b - a)
        f = f0 * (f1 / f0) ** (tt ** 1.3)
        f *= 1 + 0.02 * np.sin(2 * np.pi * 3.2 * t[m])
        ph = 2 * np.pi * np.cumsum(f) / SR
        env = np.sin(np.pi * np.clip(tt, 0, 1)) ** 0.7
        tone = np.sin(ph) + 0.45 * np.sin(2 * ph + 0.4) + 0.25 * np.sin(3 * ph + 1.0) + 0.12 * np.sin(5 * ph)
        y[m] += tone * env
    y += 0.05 * amb.lp(RNG.standard_normal(n), 300.0)
    y = amb.lp(y, 2400.0)
    return _reverb(y, 3.5, 1.1, 1500.0, 0.55)


def dolphin(k: int) -> np.ndarray:
    dur = [2.2, 2.6][k]
    n = int(dur * SR)
    t = np.arange(n) / SR
    y = np.zeros(n)
    # sifflements montants/descendants
    whistles = [[(0.0, 0.5, 7000, 13000), (0.6, 1.1, 12000, 8000), (1.4, 1.9, 9000, 14000)],
                [(0.1, 0.8, 9000, 15000), (1.0, 1.4, 14000, 10000), (1.6, 2.4, 8000, 12000)]][k]
    for (a, b, f0, f1) in whistles:
        m = (t >= a) & (t < b)
        tt = (t[m] - a) / (b - a)
        f = f0 + (f1 - f0) * (0.5 - 0.5 * np.cos(np.pi * tt))
        ph = 2 * np.pi * np.cumsum(f) / SR
        y[m] += np.sin(ph) * np.sin(np.pi * tt) ** 0.5 * 0.6
    # clics d'écholocation
    for c in np.arange(0.0, dur, 0.035 + 0.02 * k):
        i = int(c * SR)
        if RNG.random() < 0.6 and i + 200 < n:
            y[i:i + 200] += RNG.standard_normal(200) * np.exp(-np.arange(200) / 25.0) * 0.5
    y = amb.bp(y, 2500.0, 16000.0)
    return _reverb(y, 1.2, 3.0, 6000.0, 0.3)


def glass_chime(freqs, dur, sparkle=12) -> np.ndarray:
    n = int(dur * SR)
    t = np.arange(n) / SR
    y = np.zeros(n)
    for i, f in enumerate(freqs):
        a = i * 0.07
        m = t >= a
        tt = t[m] - a
        for h, g in ((1.0, 1.0), (2.76, 0.4), (5.4, 0.18)):
            y[m] += g * np.sin(2 * np.pi * f * h * tt) * np.exp(-tt * (1.4 + h * 0.8))
    for _ in range(sparkle):
        a = RNG.uniform(0.0, dur * 0.6)
        f = RNG.uniform(3000, 7000)
        m = t >= a
        tt = t[m] - a
        y[m] += 0.15 * np.sin(2 * np.pi * f * tt) * np.exp(-tt * 9.0)
    return _reverb(y, 2.0, 2.0, 7000.0, 0.35)


def crystal_awaken() -> np.ndarray:
    dur = 6.5
    n = int(dur * SR)
    t = np.arange(n) / SR
    # montée : bruit filtré qui s'éclaircit + accord ouvert ré - la - ré - fa# - la
    rise = amb.tv_lowpass(RNG.standard_normal(n), 200.0 + 6000.0 * np.clip(t / 2.5, 0, 1) ** 2) * np.clip(t / 2.5, 0, 1) * np.exp(-np.maximum(t - 2.5, 0) * 2.0) * 0.4
    y = rise
    for f in (146.83, 220.0, 293.66, 369.99, 440.0, 587.33):
        m = t >= 2.3
        tt = t[m] - 2.3
        y[m] += 0.25 * (np.sin(2 * np.pi * f * tt) + 0.3 * np.sin(4 * np.pi * f * tt)) * np.exp(-tt * 0.6) * np.clip(tt / 0.05, 0, 1)
    y += glass_chime([1174.66, 1479.98, 1760.0, 2349.32], dur, 24)[:n] * 0.5
    return _reverb(y, 3.0, 1.2, 6000.0, 0.4)


def jelly_sting(k: int) -> np.ndarray:
    dur = 0.6
    n = int(dur * SR)
    t = np.arange(n) / SR
    crackle = (RNG.random(n) < 0.08).astype(float) * RNG.standard_normal(n)
    buzz = np.sign(np.sin(2 * np.pi * (120 + 40 * k) * t)) * 0.3
    y = (crackle + buzz) * np.exp(-t * 6.0)
    y = amb.lp(y, 3000.0)
    return y


def atlantis_bed(seconds: float = 44.0) -> np.ndarray:
    n = int(seconds * SR)
    t = np.arange(n) / SR
    # bourdon chaud (ré grave + quinte) qui respire
    drone = np.zeros(n)
    for f, g in ((73.42, 1.0), (110.0, 0.6), (146.83, 0.4), (220.0, 0.15)):
        drone += g * np.sin(2 * np.pi * f * t + RNG.uniform(0, 6))
    drone *= amb.smooth_env(n, 0.15, 0.6, 1.0)
    drone = amb.lp(drone, 900.0) * 0.35
    # eau lointaine contre le dôme : bruit brun filtré qui ondule
    water = amb.lp(amb.noise(n, "brown"), 500.0) * amb.smooth_env(n, 0.3, 0.3, 0.8) * 0.25
    left = drone + water
    right = drone * 0.95 + amb.lp(amb.noise(n, "brown"), 500.0) * 0.22
    st = amb.stereo(left, right)
    # carillons de verre, au loin, de temps en temps
    notes = [587.33, 659.25, 739.99, 880.0, 987.77, 1174.66]
    at = 2.0
    while at < seconds - 4.0:
        f = float(RNG.choice(notes))
        ev = glass_chime([f, f * 1.5], 3.0, 2) * 0.12
        amb.place(st, ev, int(at * SR), 1.0, float(RNG.uniform(-0.8, 0.8)))
        at += float(RNG.uniform(3.5, 7.0))
    return amb.loopify(st, 3.0)


# =================================================================== d'après les enregistrements

def from_lib(lib: Path, files: list, max_s: float, semi: int, hp_hz: float, lp_hz: float = 0.0) -> list:
    out = []
    for f in files:
        p = lib / f
        if not p.is_file():
            print("  ! absent :", f)
            continue
        x = fx.process(fx.read_mono(p), max_s, semi, hp_hz)
        if lp_hz > 0:
            x = amb.lp(x, lp_hz)
        out.append(x / (np.max(np.abs(x)) + 1e-9) * 0.89)
    return out


def layer(a: np.ndarray, b: np.ndarray, gb: float, offset_s: float = 0.0) -> np.ndarray:
    off = int(offset_s * SR)
    n = max(len(a), len(b) + off)
    y = np.zeros(n)
    y[:len(a)] += a
    y[off:off + len(b)] += gb * b
    return y / (np.max(np.abs(y)) + 1e-9) * 0.89


def underwater_bed(lib: Path, seconds: float = 40.0) -> np.ndarray:
    n = int(seconds * SR)
    t = np.arange(n) / SR
    base = np.zeros(n)
    p = lib / "warfork-cc0/sounds/world/underwater.ogg"
    if p.is_file():
        x = fx.read_mono(p)
        reps = int(np.ceil(n / len(x))) + 1
        base = np.tile(x, reps)[:n]
        base = base / (np.max(np.abs(base)) + 1e-9)
    rumble = amb.lp(amb.noise(n, "brown"), 180.0) * amb.smooth_env(n, 0.2, 0.5, 1.0)
    left = base * 0.7 + rumble * 0.6
    right = np.roll(base, int(0.37 * SR)) * 0.7 + amb.lp(amb.noise(n, "brown"), 180.0) * 0.55
    st = amb.stereo(amb.lp(left, 1400.0), amb.lp(right, 1400.0))
    bubbles = from_lib(lib, ["40-cc0-water-splash-slime-sfx/bubble_01.ogg", "40-cc0-water-splash-slime-sfx/bubble_02.ogg", "40-cc0-water-splash-slime-sfx/bubble_03.ogg"], 1.5, -3, 100, 2500.0)
    at = 1.5
    while bubbles and at < seconds - 3.0:
        ev = bubbles[int(RNG.integers(0, len(bubbles)))] * 0.18
        amb.place(st, ev, int(at * SR), 1.0, float(RNG.uniform(-0.9, 0.9)))
        at += float(RNG.uniform(2.0, 5.0))
    return amb.loopify(st, 3.0)


def main() -> int:
    for k in range(2):
        fx.save(f"baleine_{k + 1}", _norm(whale(k)))
        fx.save(f"dauphin_{k + 1}", _norm(dolphin(k)))
        fx.save(f"meduse_pique_{k + 1}", _norm(jelly_sting(k)))
    fx.save("perle_1", _norm(glass_chime([1318.51, 1567.98, 1975.53, 2637.02], 3.5, 18)))
    fx.save("cristal_eveil_1", _norm(crystal_awaken()))
    amb.save("ambiance/atlantide", atlantis_bed())
    lib = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    if lib is None or not lib.is_dir():
        print("Sans le recueil CC0, seuls les sons synthétisés sont refaits.")
        return 0
    S = "40-cc0-water-splash-slime-sfx/"
    for i, x in enumerate(from_lib(lib, [S + "splash_04.ogg", S + "splash_09.ogg"], 1.6, -2, 60)):
        fx.save(f"plongeon_{i + 1}", x)
    for i, x in enumerate(from_lib(lib, [S + "splash_01.ogg", S + "splash_06.ogg", S + "splash_12.ogg"], 0.55, 2, 150)):
        fx.save(f"nage_{i + 1}", x)
    for i, x in enumerate(from_lib(lib, [S + "splash_02.ogg", S + "splash_07.ogg", S + "splash_13.ogg"], 0.8, -7, 60, 700.0)):
        fx.save(f"nage_sous_{i + 1}", x)
    for i, x in enumerate(from_lib(lib, [S + "bubble_01.ogg", S + "bubble_02.ogg", S + "bubble_03.ogg"], 1.6, 0, 120, 4000.0)):
        fx.save(f"bulles_{i + 1}", x)
    W = "warfork-cc0/sounds/players/"
    for i, x in enumerate(from_lib(lib, [W + "male/gasp.ogg", W + "female/gasp.ogg"], 1.5, 0, 90)):
        fx.save(f"respiration_{i + 1}", x)
    bub = from_lib(lib, [S + "loop_bubbles_1.ogg"], 1.2, -2, 100, 2500.0)
    gasp = from_lib(lib, [W + "male/gasp.ogg"], 1.0, -3, 90, 1200.0)
    if bub and gasp:
        fx.save("suffoque_1", layer(bub[0], gasp[0], 0.6, 0.3))
    CRE = "80-CC0-creature-SFX/"
    CRE2 = "80-CC0-creature-sfx-2/"
    BFH = "75-cc0-breaking-falling-hit-sfx/"
    woosh = from_lib(lib, ["Micro Pack - Organic Wooshes/Swish 4.wav", "Micro Pack - Organic Wooshes/Twirl 2.wav"], 1.2, -14, 30, 900.0)
    growl = from_lib(lib, [CRE + "grunt_02.ogg", CRE2 + "breath_02.ogg"], 1.2, -10, 40, 900.0)
    for i in range(min(len(woosh), len(growl))):
        fx.save(f"requin_menace_{i + 1}", layer(woosh[i], growl[i], 0.5))
    crunch = from_lib(lib, [BFH + "bfh1_hit_03.ogg", BFH + "bfh1_rock_breaking_01.ogg"], 0.5, -6, 60, 2500.0)
    for i in range(len(crunch)):
        snap = crunch[i]
        fx.save(f"requin_morsure_{i + 1}", layer(snap, bub[0][: int(0.6 * SR)] if bub else snap, 0.4, 0.05))
    death = from_lib(lib, [CRE + "grunt_04.ogg"], 1.4, -12, 40, 800.0)
    if death and bub:
        fx.save("requin_mort_1", layer(death[0], bub[0], 0.7, 0.2))
    amb.save("ambiance/sous_marin", underwater_bed(lib))
    return 0


if __name__ == "__main__":
    sys.exit(main())
