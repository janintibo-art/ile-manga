"""V54 : les sons du ciel — Ventaile, la Citadelle des Nuées, Sire Orage.

Synthétisés ici (domaine public) :
  sfx/aigle_cri_1..3      le cri de Ventaile (« kiii-ah » rauque et descendant)
  sfx/cloche_vague_1, cloche_soleil_1, cloche_lune_1, cloche_vent_1 : les quatre cloches du
                          beffroi (partiels d'une vraie cloche : bourdon, fondamentale, tierce
                          mineure, quinte, nominale), un carillon descendant mi - ré - si - sol
  ambiance/vent_altitude  le vent du vol (souffle large qui gronde et siffle)
D'après le recueil CC0 « lavenderdotpet/CC0-Public-Domain-Sounds » :
  sfx/ailes_1..3          battements d'ailes (« Organic Wooshes », transposés très bas)
  sfx/tonnerre_1..3       la foudre de Sire Orage (« 100 CC0 SFX 2 », « Chairmat »)
  sfx/armure_menace_1..2, armure_mort_1..2     armures animées (métal, cottes, chutes)
  sfx/gargouille_menace_1..2, gargouille_mort_1..2   gargouilles (cris rauques, pierre brisée)
Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/generate_sons_v54.py <dossier CC0-Public-Domain-Sounds>
"""
from pathlib import Path
import sys

import numpy as np
from scipy import signal

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402

SR = 44100
RNG = np.random.default_rng(5454)


# =================================================================== synthèses

def eagle_cry(k: int) -> np.ndarray:
    """Cri d'aigle : une attaque aiguë et rauque qui glisse vers le bas, avec un « r » roulé."""
    dur = [1.9, 1.6, 2.3][k]
    n = int(dur * SR)
    t = np.arange(n) / SR
    f_start = [3100.0, 2900.0, 3300.0][k]
    f_end = [1550.0, 1700.0, 1400.0][k]
    shape = np.clip(t / dur, 0, 1)
    f = f_start + (f_end - f_start) * shape ** 0.7
    f *= 1.0 + 0.012 * np.sin(2 * np.pi * 7.5 * t)            # vibrato
    phase = 2 * np.pi * np.cumsum(f) / SR
    # Timbre nasal et rauque : harmoniques, roulement (modulation d'amplitude à ~55 Hz)
    y = np.sin(phase) + 0.55 * np.sin(2 * phase + 0.3) + 0.3 * np.sin(3 * phase + 1.1) + 0.12 * np.sin(4 * phase)
    rasp = 0.65 + 0.35 * np.sign(np.sin(2 * np.pi * (52.0 + 10.0 * shape) * t)) * 0.8
    y *= rasp
    y += 0.25 * amb.bp(RNG.standard_normal(n), 2000.0, 6000.0) * (0.5 + 0.5 * np.sin(phase * 0.5) ** 2)
    env = np.clip(t / 0.03, 0, 1) * np.exp(-np.maximum(t - 0.25, 0) * (1.2 + k * 0.2))
    env *= 1.0 - np.clip((t - (dur - 0.25)) / 0.25, 0, 1)
    y *= env
    # Un léger écho de montagne
    echo = np.zeros(n + int(0.33 * SR))
    echo[:n] += y
    echo[int(0.33 * SR):] += 0.22 * amb.lp(y, 3000.0)
    return echo


def church_bell(f: float, dur: float = 6.0) -> np.ndarray:
    n = int(dur * SR)
    t = np.arange(n) / SR
    # (rapport, amplitude, durée de vie) : bourdon, fondamentale, tierce mineure, quinte, nominale…
    partials = [(0.5, 0.55, 4.5), (1.0, 0.8, 3.2), (1.183, 0.5, 2.2), (1.506, 0.35, 1.6), (2.0, 0.6, 1.9),
                (2.514, 0.22, 1.0), (2.662, 0.18, 0.9), (3.011, 0.15, 0.7), (4.166, 0.1, 0.45), (5.433, 0.06, 0.3)]
    y = np.zeros(n)
    for r, a, d in partials:
        beat = 1.0 + 0.04 * np.sin(2 * np.pi * (0.6 + r * 0.3) * t)
        y += a * np.sin(2 * np.pi * f * r * t + RNG.random() * 6.28) * np.exp(-t / d) * beat
    strike = amb.bp(RNG.standard_normal(n), 1500.0, 7000.0) * np.exp(-t / 0.012) * 0.6
    y = (y + strike) * np.clip(t / 0.002, 0, 1)
    return y


def altitude_wind(seconds: float = 40.0) -> np.ndarray:
    """Le vent du vol : un souffle large (grave), des rafales, un sifflement aigu qui varie."""
    n = int(seconds * SR)
    base = amb.noise(n, "pink")
    gust = amb.smooth_env(n, 0.25, 0.35, 1.0)
    fc = 300.0 + 900.0 * gust
    rush = amb.tv_lowpass(base, fc) * (0.6 + 0.6 * gust)
    whistle_f = 900.0 + 500.0 * amb.smooth_env(n, 0.15, 0.0, 1.0)
    whistle = amb.bp(amb.noise(n, "white"), 700.0, 1800.0) * 0.15 * amb.smooth_env(n, 0.2, 0.1, 1.0)
    rumble = amb.lp(amb.noise(n, "brown"), 90.0) * 1.6
    left = rush + whistle + rumble
    right = np.roll(rush, int(0.13 * SR)) + np.roll(whistle, int(0.05 * SR)) + rumble
    st = amb.stereo(left, right)
    return amb.loopify(st, 3.0)


# =================================================================== d'après les enregistrements

def from_lib(lib: Path, files: list, max_s: float, semi: int, hp_hz: float, lp_hz: float = 0.0, mix: list | None = None) -> list:
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


def main() -> int:
    for k in range(3):
        fx.save(f"aigle_cri_{k + 1}", _norm(eagle_cry(k)))
    notes = {"vague": 659.25, "soleil": 587.33, "lune": 493.88, "vent": 392.0}
    for name, f in notes.items():
        fx.save(f"cloche_{name}_1", _norm(church_bell(f * 0.5)))
    amb.save("ambiance/vent_altitude", altitude_wind())
    lib = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    if lib is None or not lib.is_dir():
        print("Sans le recueil CC0, seuls les sons synthétisés sont refaits.")
        return 0
    W = "Micro Pack - Organic Wooshes/"
    for i, x in enumerate(from_lib(lib, [W + "Swish 4.wav", W + "Combo 2.wav", W + "Twirl 2.wav"], 0.9, -12, 40, 1800.0)):
        fx.save(f"ailes_{i + 1}", x)
    thunder = from_lib(lib, ["100-cc0-sfx-2/sfx100v2_thunder_01.ogg", "Micro Pack - Chairmat/Fake Thunder 1.wav", "Micro Pack - Chairmat/Fake Thunder 2.wav"], 3.5, -2, 30)
    crack = from_lib(lib, ["75-cc0-breaking-falling-hit-sfx/bfh1_hit_03.ogg"], 0.3, 3, 400)
    for i, x in enumerate(thunder):
        fx.save(f"tonnerre_{i + 1}", layer(x, crack[0], 0.6) if crack else x)
    WM = "100-CC0-wood-metal-SFX/"
    BFH = "75-cc0-breaking-falling-hit-sfx/"
    CRE = "80-CC0-creature-SFX/"
    metal = from_lib(lib, [WM + "metal_hit_02.ogg", WM + "metal_slam_01.ogg"], 0.8, -3, 80)
    growl = from_lib(lib, [CRE + "grunt_02.ogg", CRE + "grunt_04.ogg"], 1.0, -7, 60, 2500.0)
    for i in range(min(len(metal), len(growl))):
        fx.save(f"armure_menace_{i + 1}", layer(metal[i], growl[i], 0.7, 0.05))
    for i, x in enumerate(from_lib(lib, [BFH + "bfh1_metal_falling_01.ogg", BFH + "bfh1_metal_falling_03.ogg"], 2.0, -2, 50)):
        fx.save(f"armure_mort_{i + 1}", x)
    scream = from_lib(lib, [CRE + "scream_01.ogg", CRE + "scream_02.ogg"], 1.0, -5, 120)
    grind = from_lib(lib, ["80-CC0-RPG-SFX/stones_01.ogg", "80-CC0-RPG-SFX/stones_02.ogg"], 0.8, -3, 60)
    for i in range(min(len(scream), len(grind))):
        fx.save(f"gargouille_menace_{i + 1}", layer(scream[i], grind[i], 0.6))
    for i, x in enumerate(from_lib(lib, [BFH + "bfh1_rock_breaking_01.ogg", BFH + "bfh1_rock_falling_02.ogg"], 1.6, 0, 50)):
        fx.save(f"gargouille_mort_{i + 1}", x)
    return 0


def _norm(x: np.ndarray) -> np.ndarray:
    sos = signal.butter(2, 60.0, btype="highpass", fs=SR, output="sos")
    x = signal.sosfilt(sos, x)
    return x / (np.max(np.abs(x)) + 1e-9) * 0.89


if __name__ == "__main__":
    sys.exit(main())
