"""V58 : les sons du royaume des fées et d'Yggdrasil.

Synthétisés ici (domaine public) :
  sfx/teleport_1..2       la téléportation : un souffle qui s'élève, une gerbe de clochettes de
                          cristal qui montent en glissando, un accord de lumière qui s'éteint
  sfx/rune_0..4           les cinq pierres-runes de la Salle des Lucioles : cinq notes de cristal
                          (mi, fa dièse, sol dièse, si, do dièse : la gamme des fées), longue
                          résonance dans le bois creux
  sfx/fleur_tourne_1..2   une fleur-miroir (ou une fleur des saisons) qui tourne : froissement
                          de pétales et petit trille de verre
  sfx/esprit_1            l'esprit de l'arbre : un chœur sans paroles (voyelles « a » et « o »
                          en formants), cloches graves et scintillement
  sfx/porte_ygg_1         la porte d'Yggdrasil apparaît : grondement profond du bois, accord
                          magique qui monte
D'après le recueil CC0 « lavenderdotpet/CC0-Public-Domain-Sounds » :
  sfx/plante_menace_1..2  une plante carnivore qui se cabre : souffle mouillé, gargouillis,
                          feuillage froissé
  sfx/plante_mort_1..2    une plante qui se fane : râle aigu, tige qui casse, feuilles qui tombent
  sfx/ronce_menace_1..2   un ronceux : bois qui grince et craque, grognement végétal
  sfx/racines_1..2        les racines qui se retirent : craquements, grincements, grondement
Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/generate_sons_v58.py <dossier CC0-Public-Domain-Sounds>
"""
from pathlib import Path
import sys

import numpy as np
from scipy import signal

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
import generate_sons_v54 as s54  # noqa: E402

SR = 44100
RNG = np.random.default_rng(5858)


def _norm(x: np.ndarray, peak: float = 0.89) -> np.ndarray:
    sos = signal.butter(2, 40.0, btype="highpass", fs=SR, output="sos")
    x = signal.sosfilt(sos, x, axis=0)
    return x / (np.max(np.abs(x)) + 1e-9) * peak


def _room(x: np.ndarray, seconds: float, decay: float, lp_hz: float, wet: float, seed: int = 1) -> np.ndarray:
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    t = np.arange(n) / SR
    chans = [x] if x.ndim == 1 else [x[:, 0], x[:, 1]]
    out = []
    for c in chans:
        ir = rng.standard_normal(n) * np.exp(-t * decay)
        ir = amb.lp(ir, lp_hz, order=4)
        ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
        y = signal.fftconvolve(np.concatenate([c, np.zeros(n)]), ir)[: len(c) + n]
        out.append(np.concatenate([c, np.zeros(n)]) * (1 - wet) + y * wet * 2.5)
    return out[0] if x.ndim == 1 else np.stack(out, axis=1)


def crystal(f: float, dur: float, bright: float = 1.0) -> np.ndarray:
    """Une note de cristal (verre frotté / clochette) : partiels inharmoniques qui battent."""
    m = int(dur * SR)
    x = np.arange(m) / SR
    y = np.zeros(m)
    for r, a, d in [(1.0, 1.0, dur * 0.5), (2.0, 0.35 * bright, dur * 0.3), (2.76, 0.25 * bright, dur * 0.2),
                    (4.07, 0.12 * bright, dur * 0.12), (5.4, 0.08 * bright, dur * 0.08)]:
        y += a * np.sin(2 * np.pi * f * r * x + RNG.uniform(0, 6)) * np.exp(-x / d)
        y += a * 0.3 * np.sin(2 * np.pi * (f * r + RNG.uniform(0.8, 2.5)) * x) * np.exp(-x / d)
    return y * np.clip(x / 0.003, 0, 1)


def rustle(seconds: float, density: float = 40.0) -> np.ndarray:
    """Froissement de feuilles : petits craquements filtrés, en grappes."""
    n = int(seconds * SR)
    y = np.zeros(n)
    for _ in range(int(seconds * density)):
        m = int(RNG.uniform(0.004, 0.02) * SR)
        e = RNG.standard_normal(m) * np.hanning(m)
        e = amb.bp(e, RNG.uniform(1500, 3500), RNG.uniform(5000, 9000))
        at = int(RNG.uniform(0, max(n - m, 1)))
        y[at:at + m] += e * RNG.uniform(0.2, 1.0)
    return y * amb.smooth_env(n, 6.0, 0.4, 1.0)


def teleport(k: int) -> np.ndarray:
    dur = 2.6
    n = int(dur * SR)
    t = np.arange(n) / SR
    out = np.zeros((n, 2))
    # le souffle : bruit dont le filtre monte
    wind = amb.noise(n, "pink")
    fc = 300 + 5000 * (t / dur) ** 1.4
    w = amb.tv_lowpass(wind, fc) * np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 1.5
    out[:, 0] += w * 0.5
    out[:, 1] += np.roll(w, 211) * 0.5
    # la gerbe de clochettes qui monte (gamme pentatonique de mi)
    scale = [659.3, 740.0, 830.6, 987.8, 1108.7]
    notes = [scale[i % 5] * (2 ** (i // 5)) for i in range(12)]
    for i, f in enumerate(notes):
        e = crystal(f * (1.0 + 0.02 * k), 1.6, 0.8)
        at = int((0.15 + i * 0.11) * SR)
        amb.place(out, e, at, 0.18, np.sin(i * 1.3) * 0.8)
    # l'accord de lumière
    for f in [329.6, 415.3, 493.9, 622.3]:
        m = int(2.0 * SR)
        x = np.arange(m) / SR
        tone = (np.sin(2 * np.pi * f * x) + 0.3 * np.sin(4 * np.pi * f * x)) * np.clip(x / 0.6, 0, 1) * np.exp(-x / 0.9)
        amb.place(out, tone, int(0.5 * SR), 0.09, RNG.uniform(-0.5, 0.5))
    return _norm(_room(out, 2.2, 2.0, 7000.0, 0.35, seed=k + 5))


def rune(i: int) -> np.ndarray:
    f = [659.3, 740.0, 830.6, 987.8, 1108.7][i]
    y = crystal(f, 3.4) + 0.5 * crystal(f * 0.5, 3.4, 0.5)
    # petite attaque de bois (on pose la main sur la pierre)
    m = int(0.03 * SR)
    knock = amb.bp(RNG.standard_normal(m), 300, 1800) * np.hanning(m) * 0.6
    y[:m] += knock
    st = np.stack([y, np.roll(y, 29)], axis=1)
    return _norm(_room(st, 2.6, 1.6, 5000.0, 0.4, seed=20 + i))


def fleur(k: int) -> np.ndarray:
    dur = 1.0
    y = rustle(dur, 70.0) * 0.5
    for j, f in enumerate([[1318.5, 1661.2, 1975.5], [1479.98, 1864.7, 2217.5]][k]):
        e = crystal(f, 0.7, 0.6)
        at = int((0.06 + j * 0.07) * SR)
        y[at:at + len(e)] += e[: len(y) - at] * 0.35
    st = np.stack([y, np.roll(y, 41)], axis=1)
    return _norm(_room(st, 1.0, 3.0, 6000.0, 0.25, seed=30 + k))


def formant_voice(f0: float, dur: float, vowel: str) -> np.ndarray:
    n = int(dur * SR)
    t = np.arange(n) / SR
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5.1 * t + RNG.uniform(0, 6))
    ph = np.cumsum(f0 * vib) / SR
    src = 2.0 * (ph % 1.0) - 1.0
    src = amb.lp(src, 4000)
    forms = {"a": [(800, 80, 1.0), (1150, 90, 0.5), (2900, 120, 0.25)], "o": [(450, 70, 1.0), (800, 80, 0.4), (2830, 120, 0.15)]}[vowel]
    y = np.zeros(n)
    for fc, bw, g in forms:
        y += amb.bp(src, fc - bw, fc + bw) * g
    return y


def esprit() -> np.ndarray:
    dur = 4.6
    n = int(dur * SR)
    t = np.arange(n) / SR
    out = np.zeros((n, 2))
    env = np.clip(t / 1.2, 0, 1) * np.clip((dur - t) / 1.6, 0, 1)
    for i, (f, v) in enumerate([(164.8, "o"), (246.9, "a"), (329.6, "a"), (415.3, "o"), (493.9, "a")]):
        for ch in range(2):
            y = formant_voice(f * (1.0 + (ch - 0.5) * 0.004), dur, v) * env
            out[:, ch] += y * 0.35
    for f in [82.4, 164.8]:
        b = crystal(f * 2, 4.0, 0.4)
        amb.place(out, b, int(0.1 * SR), 0.25, 0.0)
    for i in range(10):
        e = crystal(RNG.choice([1318.5, 1661.2, 1975.5, 2489.0]), 1.4, 0.7)
        amb.place(out, e, int(RNG.uniform(0.6, 3.2) * SR), 0.06, RNG.uniform(-0.9, 0.9))
    return _norm(_room(out, 3.0, 1.2, 4500.0, 0.45, seed=41))


def porte(lib) -> np.ndarray:
    dur = 4.5
    n = int(dur * SR)
    t = np.arange(n) / SR
    rumble = amb.lp(amb.noise(n, "brown"), 120) * np.clip(t / 0.8, 0, 1) * np.clip((dur - t) / 1.5, 0, 1)
    y = rumble * 1.2
    if lib is not None:
        cr = s54.from_lib(lib, ["100-CC0-wood-metal-SFX/wood_squeak_01.ogg", "100-CC0-wood-metal-SFX/wood_cracking_02.ogg"], 2.0, -9, 40, 2500.0)
        for i, c in enumerate(cr):
            at = int((0.4 + i * 1.1) * SR)
            y[at:at + len(c)] += c[: n - at] * 0.5
    st = np.stack([y, np.roll(y, 53)], axis=1)
    for i, f in enumerate([329.6, 415.3, 493.9, 659.3, 830.6]):
        m = int(3.0 * SR)
        x = np.arange(m) / SR
        tone = np.sin(2 * np.pi * f * x) * np.clip(x / 1.2, 0, 1) * np.exp(-x / 1.4)
        amb.place(st, tone, int((1.0 + i * 0.25) * SR), 0.1, (i - 2) * 0.3)
    return _norm(_room(st, 2.5, 1.5, 3000.0, 0.35, seed=51))


def main() -> int:
    lib = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    if lib is not None and not lib.is_dir():
        lib = None
    for k in range(2):
        fx.save(f"teleport_{k + 1}", teleport(k))
        fx.save(f"fleur_tourne_{k + 1}", fleur(k))
    for i in range(5):
        fx.save(f"rune_{i}_1", rune(i))
    fx.save("esprit_1", esprit())
    fx.save("porte_ygg_1", porte(lib))
    if lib is None:
        print("Sans le recueil CC0, seuls les sons synthétisés sont refaits.")
        return 0
    CRE = "80-CC0-creature-SFX/"
    CR2 = "80-CC0-creature-sfx-2/"
    WM = "100-CC0-wood-metal-SFX/"
    wet = s54.from_lib(lib, [CR2 + "slime_03.ogg", CR2 + "slime_06.ogg"], 1.0, -3, 80, 4000.0)
    hiss = s54.from_lib(lib, [CR2 + "monster_12.ogg", CRE + "monster_04.ogg"], 1.0, -5, 70, 3500.0)
    for i in range(min(len(wet), len(hiss))):
        y = s54.layer(hiss[i], wet[i], 0.7, 0.05)
        r = rustle(len(y) / SR, 60.0)
        fx.save(f"plante_menace_{i + 1}", _norm(y + r[: len(y)] * 0.25))
    die = s54.from_lib(lib, [CR2 + "die_02.ogg", CR2 + "die_04.ogg"], 1.2, -4, 90, 4000.0)
    snap = s54.from_lib(lib, [WM + "wood_cracking_01.ogg", WM + "wood_cracking_03.ogg"], 0.8, 2, 200)
    for i in range(min(len(die), len(snap))):
        y = s54.layer(die[i], snap[i], 0.6, 0.25)
        r = rustle(len(y) / SR, 40.0) * np.linspace(1, 0, len(y))
        fx.save(f"plante_mort_{i + 1}", _norm(y + r * 0.35))
    creak = s54.from_lib(lib, [WM + "wood_squeak_02.ogg", WM + "wood_cracking_04.ogg"], 1.0, -4, 60)
    grunt = s54.from_lib(lib, [CR2 + "grunt_07.ogg", CRE + "grunt_03.ogg"], 1.0, -8, 50, 2200.0)
    for i in range(min(len(creak), len(grunt))):
        fx.save(f"ronce_menace_{i + 1}", _norm(s54.layer(creak[i], grunt[i], 0.6, 0.08)))
    roots = s54.from_lib(lib, [WM + "wood_cracking_02.ogg", WM + "wood_squeak_01.ogg", WM + "wood_misc_04.ogg"], 2.5, -10, 30, 2500.0)
    for k in range(2):
        n = int(3.0 * SR)
        y = amb.lp(amb.noise(n, "brown"), 90) * np.sin(np.pi * np.arange(n) / n) * 0.8
        for j, c in enumerate(roots):
            at = int((0.1 + j * 0.7 + k * 0.2) * SR)
            y[at:at + len(c)] += c[: n - at] * 0.55
        r = rustle(3.0, 30.0) * 0.2
        fx.save(f"racines_{k + 1}", _norm(y + r))
    return 0


if __name__ == "__main__":
    sys.exit(main())
