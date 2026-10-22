"""V63 : les sons de la grande enquête des Quatre Sceaux, du donjon du Cœur-de-Pierre et de la
progression du héros.

Bruitages (sfx/) :
  le héros   niveau (des clochettes qui montent), double_saut (un souffle d'air), charge_pret
             (la lame qui chante), coup_charge (le grand coup), tournoyante (la lame qui tourne),
             parade_parfaite (le choc et la note claire), esquive, armure_bloque, forge ;
  pouvoirs   bourrasque (la rafale), flamme_lance / flamme_impact, rouage (les engrenages
             d'airain), lueur (la lumière de lune), sceau_eveil (un sceau qui s'éveille),
             sceau_pose (un sceau posé dans la grande porte) ;
  enquête    porte_coeur (une très lourde porte de pierre qui s'enfonce), feu_ronces,
             mecanisme (des engrenages et des chaînes), eau_vanne (l'eau qui s'engouffre) ;
  donjon     geyser, vague, lame (le pendule), dard, dalle_clic, piston, ombre_mains,
             onde_choc, rune_brisee, boss_coeur_cri ;
  créatures  scorpion_menace/_mort, automate_menace/_mort, spectre_menace/_mort,
             ondin_menace/_mort, loup_menace.
Synthétisés ici, ou retravaillés d'après le recueil CC0 « lavenderdotpet/CC0-Public-Domain-Sounds »
(créatures, feu, chaînes, pierres, eau, souffles) : tout est libre de droits.
Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/generate_sons_v63.py [dossier CC0-Public-Domain-Sounds]
"""
from pathlib import Path
import sys

import numpy as np
from scipy import signal

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_sons_v56 as s56  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402

SR = 44100
RNG = np.random.default_rng(6363)
s56.RNG = np.random.default_rng(6364)
amb.RNG = np.random.default_rng(6365)
LIB = Path("/root/snd/CC0-Public-Domain-Sounds")


def _t(seconds: float) -> np.ndarray:
    return np.arange(int(seconds * SR)) / SR


def _norm(x: np.ndarray, peak: float = 0.89) -> np.ndarray:
    return s56._norm(x, peak)


def _env(n: int, a: float, d: float) -> np.ndarray:
    x = np.arange(n) / SR
    return np.clip(x / max(a, 1e-4), 0, 1) * np.exp(-x / d)


def _fade(x: np.ndarray, fin: float = 0.005, fout: float = 0.05) -> np.ndarray:
    n = len(x)
    e = np.ones(n)
    a = int(fin * SR)
    b = int(fout * SR)
    if a > 0:
        e[:a] = np.linspace(0, 1, a)
    if b > 0:
        e[-b:] *= np.linspace(1, 0, b)
    return x * e


def rec(rel: str, semi: float = 0.0) -> np.ndarray:
    """Un enregistrement du recueil (mono), transposé de quelques demi-tons."""
    x = s56._read(LIB, rel)
    if len(x) == 0:
        return np.zeros(int(0.2 * SR))
    return s56._shift(x, semi)


def slow(x: np.ndarray, factor: float) -> np.ndarray:
    """Ralentit (et grave) un son : factor 2 = deux fois plus long, une octave plus bas."""
    return signal.resample(x, int(len(x) * factor))


def mix(n_s: float, *parts) -> np.ndarray:
    out = np.zeros(int(n_s * SR))
    for p in parts:
        x, at, g = p
        amb.place(out, x, int(at * SR), g)
    return out


def noise(n_s: float) -> np.ndarray:
    return RNG.standard_normal(int(n_s * SR))


def bell(f: float, dur: float, bright: float = 1.0) -> np.ndarray:
    x = _t(dur)
    y = sum(a * np.sin(2 * np.pi * f * r * x + RNG.uniform(0, 6)) * np.exp(-x / (dur * d))
            for r, a, d in [(1.0, 1.0, 0.45), (2.0, 0.35 * bright, 0.25), (2.76, 0.5 * bright, 0.18), (5.4, 0.25 * bright, 0.08), (8.9, 0.1 * bright, 0.04)])
    return y * np.clip(x / 0.002, 0, 1)


def whoosh(dur: float, f0: float, f1: float, q: float = 0.5) -> np.ndarray:
    """Un souffle filtré dont la couleur glisse de f0 à f1 (épée, rafale)."""
    x = _t(dur)
    fc = np.interp(x, [0, dur], [f0, f1])
    n = noise(dur)
    lo = amb.tv_lowpass(n, fc * (1 + q))
    lo2 = amb.tv_lowpass(n, fc * (1 - q * 0.6))
    env = np.sin(np.pi * np.clip(x / dur, 0, 1)) ** 1.5
    return (lo - lo2) * env


# =================================================================== le héros

def niveau() -> np.ndarray:
    """Le passage de niveau : des clochettes qui montent en arpège, un voile scintillant."""
    notes = [784.0, 988.0, 1175.0, 1568.0, 1976.0]
    out = np.zeros(int(2.6 * SR))
    for k, f in enumerate(notes):
        amb.place(out, bell(f, 1.6, 0.8), int(k * 0.09 * SR), 0.7 - k * 0.05)
    sh = amb.bp(noise(2.0), 5000, 12000) * _env(int(2.0 * SR), 0.3, 0.5) * 0.12
    amb.place(out, sh, int(0.1 * SR), 1.0)
    return _norm(s56._room(out, 1.4, 2.5, 7000.0, 0.25, seed=631), 0.8)


def double_saut() -> np.ndarray:
    w = whoosh(0.35, 700.0, 2400.0, 0.6)
    puff = amb.lp(noise(0.25), 500) * _env(int(0.25 * SR), 0.01, 0.06)
    return _norm(mix(0.45, (w, 0.0, 1.0), (puff, 0.0, 0.7)), 0.8)


def charge_pret() -> np.ndarray:
    """La lame chargée : un frottement métallique qui monte, puis une note claire."""
    x = _t(0.9)
    f = np.interp(x, [0, 0.5, 0.9], [900, 2400, 2400])
    ring = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.clip(x / 0.4, 0, 1) * np.exp(-np.clip(x - 0.5, 0, 9) / 0.25) * 0.3
    scrape = amb.bp(noise(0.9), 2500, 9000) * np.clip(x / 0.45, 0, 1) * (x < 0.5) * 0.25
    ping = bell(2637.0, 0.9, 1.2)
    out = mix(1.3, (ring + scrape, 0.0, 1.0), (ping, 0.48, 0.6))
    return _norm(out, 0.75)


def coup_charge() -> np.ndarray:
    w = whoosh(0.45, 300.0, 1400.0, 0.7)
    thump = amb.lp(noise(0.5), 160) * _env(int(0.5 * SR), 0.005, 0.12) * 2.0
    blade = rec("80-CC0-RPG-SFX/blade_03.ogg", -3)
    return _norm(mix(0.9, (w, 0.0, 1.0), (blade, 0.18, 0.8), (thump, 0.3, 1.0)), 0.9)


def tournoyante() -> np.ndarray:
    """La lame qui tourne : deux souffles qui passent d'une oreille à l'autre."""
    a = whoosh(0.32, 600.0, 2200.0, 0.6)
    b = whoosh(0.32, 2000.0, 700.0, 0.6)
    return _norm(mix(0.8, (a, 0.0, 1.0), (b, 0.22, 0.9), (whoosh(0.3, 900.0, 1800.0), 0.44, 0.6)), 0.85)


def parade_parfaite() -> np.ndarray:
    clang = rec("80-CC0-RPG-SFX/metal_02.ogg", 2)
    note = bell(1760.0, 1.4, 1.4)
    shim = amb.bp(noise(1.0), 6000, 14000) * _env(int(1.0 * SR), 0.01, 0.25) * 0.15
    return _norm(s56._room(mix(1.6, (clang, 0.0, 1.0), (note, 0.01, 0.7), (shim, 0.02, 1.0)), 1.0, 3.0, 7000.0, 0.2, seed=632), 0.85)


def esquive() -> np.ndarray:
    return _norm(whoosh(0.28, 1200.0, 3000.0, 0.5), 0.7)


def armure_bloque() -> np.ndarray:
    th = rec("BB_Retail Therapy Sample Pack/Metal Thunk 2.wav", -2)[: int(0.6 * SR)]
    return _norm(_fade(th, 0.001, 0.15), 0.8)


def forge() -> np.ndarray:
    """Trois coups de marteau sur l'enclume, puis la lame plongée dans l'eau."""
    hits = [rec("100-CC0-wood-metal-SFX/metal_hit_01.ogg"), rec("100-CC0-wood-metal-SFX/metal_hit_03.ogg"), rec("100-CC0-wood-metal-SFX/metal_hit_05.ogg")]
    out = np.zeros(int(3.4 * SR))
    for k, h in enumerate(hits):
        amb.place(out, h[: int(0.9 * SR)], int(k * 0.55 * SR), 0.9)
    sizzle = amb.bp(noise(1.5), 2500, 9000) * _env(int(1.5 * SR), 0.02, 0.5) * 0.4
    sizzle += amb.lp(noise(1.5), 400) * _env(int(1.5 * SR), 0.01, 0.2) * 0.3
    amb.place(out, sizzle, int(1.9 * SR), 1.0)
    return _norm(out, 0.85)


# =================================================================== les pouvoirs

def bourrasque() -> np.ndarray:
    """La Bourrasque : une rafale qui enfle et file devant soi (le vent qui siffle un peu)."""
    x = _t(1.4)
    fc = np.interp(x, [0, 0.25, 1.4], [300, 2200, 600])
    n = noise(1.4)
    wind = amb.tv_lowpass(n, fc) - amb.tv_lowpass(n, fc * 0.4)
    env = np.clip(x / 0.12, 0, 1) * np.exp(-np.clip(x - 0.2, 0, 9) / 0.4)
    whistle = np.sin(2 * np.pi * np.cumsum(np.interp(x, [0, 0.3, 1.4], [500, 900, 650])) / SR) * env * 0.05
    rumble = amb.lp(noise(1.4), 120) * env * 0.6
    return _norm((wind * 3.0 + whistle + rumble) * env, 0.85)


def flamme_lance() -> np.ndarray:
    a = rec("80-CC0-RPG-SFX/spell_fire_07.ogg", 0)
    b = whoosh(0.4, 500.0, 1800.0, 0.6) * 0.6
    return _norm(mix(1.0, (a, 0.0, 1.0), (b, 0.0, 0.8)), 0.85)


def flamme_impact() -> np.ndarray:
    a = rec("80-CC0-RPG-SFX/spell_fire_04.ogg", -2)
    boom = amb.lp(noise(0.8), 200) * _env(int(0.8 * SR), 0.003, 0.15) * 1.5
    crackle = (RNG.random(int(1.4 * SR)) < 0.004).astype(float)
    crackle = amb.bp(crackle, 1500, 7000) * np.exp(-_t(1.4) / 0.5) * 2.0
    return _norm(mix(1.8, (a, 0.0, 1.0), (boom, 0.0, 1.0), (crackle, 0.05, 0.6)), 0.9)


def ratchet(n_clicks: int, rate: float, pitch: float = 1.0) -> np.ndarray:
    out = np.zeros(int((n_clicks / rate + 0.3) * SR))
    for k in range(n_clicks):
        x = _t(0.05)
        c = sum(a * np.sin(2 * np.pi * f * pitch * x) * np.exp(-x / d) for f, a, d in [(2300, 1.0, 0.008), (4100, 0.6, 0.005), (900, 0.4, 0.012)])
        c += amb.bp(RNG.standard_normal(len(x)), 1500, 8000) * np.exp(-x / 0.003) * 0.5
        amb.place(out, c, int(k / rate * SR), RNG.uniform(0.6, 1.0))
    return out


def rouage() -> np.ndarray:
    """Le Rouage : un cliquetis d'engrenages d'airain qui accélère, un bourdon métallique."""
    clicks = ratchet(16, 22.0, 1.0)
    x = _t(1.0)
    hum = (np.sin(2 * np.pi * 220 * x) + 0.5 * np.sin(2 * np.pi * 330 * x) + 0.3 * np.sin(2 * np.pi * 523 * x)) * _env(len(x), 0.05, 0.35) * 0.25
    clink = bell(1318.0, 0.8, 1.5) * 0.4
    return _norm(mix(1.3, (clicks, 0.0, 1.0), (hum, 0.0, 1.0), (clink, 0.65, 1.0)), 0.85)


def lueur() -> np.ndarray:
    """La Lueur de lune : une nappe d'argent qui s'ouvre (accord aigu, scintillement)."""
    x = _t(3.0)
    chord = [880.0, 1108.7, 1318.5, 1760.0]
    pad = sum(np.sin(2 * np.pi * f * x + RNG.uniform(0, 6)) * (1 + 0.004 * np.sin(2 * np.pi * 5.5 * x)) for f in chord) / 4
    env = np.clip(x / 0.6, 0, 1) * np.exp(-np.clip(x - 0.8, 0, 9) / 0.9)
    sparkle = np.zeros(len(x))
    for k in range(18):
        amb.place(sparkle, bell(RNG.uniform(2500, 5200), 0.5, 0.6), int(RNG.uniform(0.0, 2.2) * SR), RNG.uniform(0.1, 0.25))
    return _norm(s56._room(pad * env * 0.6 + sparkle, 1.8, 2.0, 9000.0, 0.35, seed=633), 0.75)


def sceau_eveil() -> np.ndarray:
    """Un sceau s'éveille : un grand accord qui enfle, une cloche de bronze, un souffle."""
    x = _t(4.0)
    chord = [130.8, 196.0, 261.6, 329.6, 392.0]
    pad = sum(np.sin(2 * np.pi * f * x + RNG.uniform(0, 6)) * (0.8 ** i) for i, f in enumerate(chord))
    env = np.clip(x / 1.2, 0, 1) ** 2 * np.exp(-np.clip(x - 1.6, 0, 9) / 1.0)
    swell = amb.bp(noise(4.0), 300, 3000) * env * 0.15
    b = bell(523.3, 3.0, 1.0)
    out = mix(4.5, (pad * env * 0.35 + swell, 0.0, 1.0), (b, 1.3, 0.6))
    return _norm(s56._room(out, 2.0, 1.6, 6000.0, 0.35, seed=634), 0.85)


def sceau_pose() -> np.ndarray:
    """Un sceau posé dans la porte : le disque qui claque dans son creux, la pierre qui vibre."""
    clunk = rec("80-CC0-RPG-SFX/stones_02.ogg", -5)
    thud = amb.lp(noise(0.7), 150) * _env(int(0.7 * SR), 0.002, 0.15) * 2.0
    b = bell(392.0, 2.5, 0.8)
    return _norm(s56._room(mix(2.8, (clunk, 0.0, 1.0), (thud, 0.0, 1.0), (b, 0.05, 0.5)), 1.6, 2.0, 5000.0, 0.3, seed=635), 0.9)


# =================================================================== l'enquête

def stone_grind(dur: float, f: float = 90.0) -> np.ndarray:
    """De la pierre qui frotte sur de la pierre : un grondement granuleux, irrégulier."""
    x = _t(dur)
    n = noise(dur)
    grain = amb.bp(n, 80, 900) * (0.6 + 0.4 * amb.smooth_env(len(n), 6.0, 0.2, 1.0))
    chatter = (RNG.random(len(n)) < 0.003).astype(float)
    chatter = amb.bp(chatter, 300, 3000) * 3.0
    low = np.sin(2 * np.pi * np.cumsum(f * (1 + 0.1 * amb.smooth_env(len(n), 2.0, -1, 1))) / SR) * 0.4
    return grain + chatter * 0.3 + low


def porte_coeur() -> np.ndarray:
    """La très lourde porte de pierre qui s'enfonce : un choc, le grondement, la poussière."""
    dur = 7.0
    x = _t(dur)
    body = stone_grind(dur, 55.0) * np.clip(x / 0.6, 0, 1) * np.clip((dur - x) / 1.2, 0, 1)
    boom = amb.lp(noise(2.0), 90) * _env(int(2.0 * SR), 0.005, 0.5) * 2.5
    stones = rec("80-CC0-RPG-SFX/stones_01.ogg", -9)
    out = mix(dur + 1.0, (body, 0.0, 0.8), (boom, 0.0, 1.0), (slow(stones, 1.5), 0.1, 0.6), (boom, dur - 0.3, 0.8))
    return _norm(s56._room(out, 2.5, 1.2, 3000.0, 0.35, seed=636), 0.92)


def feu_ronces() -> np.ndarray:
    a = rec("80-CC0-RPG-SFX/spell_fire_03.ogg", -3)
    dur = 3.5
    roar = amb.bp(noise(dur), 150, 2500) * np.clip(_t(dur) / 0.3, 0, 1) * np.exp(-_t(dur) / 1.6) * 0.5
    crackle = (RNG.random(int(dur * SR)) < 0.006).astype(float)
    crackle = amb.bp(crackle, 1200, 8000) * np.exp(-_t(dur) / 1.4) * 2.5
    return _norm(mix(dur, (a, 0.0, 1.0), (roar, 0.05, 1.0), (crackle, 0.1, 0.8)), 0.88)


def mecanisme() -> np.ndarray:
    """Un vieux mécanisme qui se remet en route : un cliquet, des chaînes, un grincement."""
    out = np.zeros(int(3.0 * SR))
    amb.place(out, ratchet(22, 9.0, 0.6), 0, 0.7)
    for k in range(3):
        amb.place(out, rec("80-CC0-RPG-SFX/chain_0%d.ogg" % (k + 1), -2), int((0.3 + k * 0.7) * SR), 0.6)
    x = _t(1.6)
    squeal = np.sin(2 * np.pi * np.cumsum(np.interp(x, [0, 1.6], [420, 380]) * (1 + 0.02 * np.sin(2 * np.pi * 7 * x))) / SR)
    squeal = amb.bp(squeal + 0.3 * RNG.standard_normal(len(x)), 300, 2000) * _env(len(x), 0.2, 0.6) * 0.25
    amb.place(out, squeal, int(0.5 * SR), 1.0)
    return _norm(s56._room(out, 1.2, 2.5, 5000.0, 0.2, seed=637), 0.85)


def eau_vanne() -> np.ndarray:
    """L'eau qui s'engouffre par la vanne : un grondement qui enfle, puis coule."""
    w = rec("30-cc0-sfx-loops/water_flowing.ogg", -3)
    seg = np.concatenate([w, w, w, w])[: int(6.0 * SR)]
    x = _t(len(seg) / SR)
    rush = amb.bp(noise(len(seg) / SR), 120, 1500) * 0.6
    env = np.clip(x / 1.0, 0, 1) * np.clip((6.0 - x) / 1.5, 0, 1)
    return _norm((seg + rush) * env, 0.85)


# =================================================================== le donjon

def geyser() -> np.ndarray:
    """Un geyser : un glouglou sourd, puis le jet qui jaillit et retombe en pluie."""
    gl = rec("40-cc0-water-splash-slime-sfx/bubble_01.ogg", -6)
    x = _t(2.2)
    jet = amb.bp(noise(2.2), 400, 6000) * np.clip(x / 0.08, 0, 1) * np.exp(-x / 0.9)
    rain = amb.hp(noise(2.2), 3000) * np.clip((x - 0.4) / 0.4, 0, 1) * np.exp(-x / 1.0) * 0.4
    sp = rec("40-cc0-water-splash-slime-sfx/splash_04.ogg", -4)
    return _norm(mix(2.6, (gl, 0.0, 0.6), (jet, 0.25, 1.0), (rain, 0.25, 1.0), (sp, 0.3, 0.6)), 0.88)


def vague() -> np.ndarray:
    """La vague qui roule dans la galerie : elle approche en grondant, puis déferle."""
    dur = 4.0
    x = _t(dur)
    fc = np.interp(x, [0, 2.8, 3.2, 4.0], [200, 900, 3500, 1200])
    n = noise(dur)
    roar = amb.tv_lowpass(n, fc) * np.interp(x, [0, 2.6, 3.0, 4.0], [0.1, 0.8, 1.0, 0.0])
    low = amb.lp(noise(dur), 100) * np.interp(x, [0, 2.8, 4.0], [0.2, 1.0, 0.0]) * 0.8
    sp = rec("40-cc0-water-splash-slime-sfx/splash_10.ogg", -5)
    return _norm(s56._room(mix(dur + 0.5, (roar * 2 + low, 0.0, 1.0), (sp, 2.9, 0.7)), 1.5, 2.0, 4000.0, 0.3, seed=638), 0.9)


def lame() -> np.ndarray:
    """La grande lame du pendule qui fend l'air (lent, grave)."""
    w = whoosh(0.7, 250.0, 900.0, 0.7)
    ring = bell(620.0, 0.6, 1.5) * 0.08
    return _norm(mix(0.9, (w, 0.0, 1.0), (ring, 0.3, 1.0)), 0.8)


def dard() -> np.ndarray:
    out = np.zeros(int(0.8 * SR))
    for k in range(3):
        x = _t(0.12)
        c = amb.bp(RNG.standard_normal(len(x)), 1800, 9000) * np.exp(-x / 0.02)
        c += np.sin(2 * np.pi * np.cumsum(np.interp(x, [0, 0.12], [3400, 1800])) / SR) * np.exp(-x / 0.03) * 0.3
        amb.place(out, c, int((k * 0.07 + RNG.uniform(0, 0.02)) * SR), 0.8)
    return _norm(out, 0.8)


def dalle_clic() -> np.ndarray:
    a = rec("80-CC0-RPG-SFX/item_stone_02.ogg", -3)[: int(0.4 * SR)]
    c = ratchet(1, 10.0, 0.5) * 0.5
    return _norm(mix(0.5, (_fade(a, 0.001, 0.08), 0.0, 1.0), (c, 0.04, 1.0)), 0.75)


def piston() -> np.ndarray:
    """Un piston de fonte qui s'abat : le choc, la vapeur qui fuse."""
    hit = rec("75-cc0-breaking-falling-hit-sfx/bfh1_hit_05.ogg", -6)
    boom = amb.lp(noise(0.9), 110) * _env(int(0.9 * SR), 0.002, 0.18) * 2.2
    clang = rec("BB_Retail Therapy Sample Pack/Metal Clank 1.wav", -5)[: int(0.8 * SR)]
    x = _t(1.4)
    steam = amb.bp(noise(1.4), 2500, 10000) * np.clip(x / 0.05, 0, 1) * np.exp(-x / 0.45) * 0.35
    return _norm(s56._room(mix(1.8, (hit, 0.0, 1.0), (boom, 0.0, 1.0), (_fade(clang), 0.0, 0.4), (steam, 0.08, 1.0)), 1.2, 2.5, 4000.0, 0.25, seed=639), 0.92)


def ombre_mains() -> np.ndarray:
    """Les mains d'ombre : des chuchotements graves, un frottement sec, comme des ongles."""
    w = rec("80-CC0-creature-SFX/weird_02.ogg", -10)
    b = rec("80-CC0-creature-sfx-2/breath_02.ogg", -7)
    scr = amb.bp(noise(1.2), 2500, 7000) * amb.smooth_env(int(1.2 * SR), 12.0, 0.0, 1.0) * _env(int(1.2 * SR), 0.1, 0.5) * 0.3
    out = mix(1.8, (slow(w, 1.4), 0.0, 0.8), (b, 0.1, 0.6), (scr, 0.2, 1.0))
    return _norm(s56._room(out, 1.6, 2.0, 3500.0, 0.4, seed=640), 0.8)


def onde_choc() -> np.ndarray:
    """L'onde de choc : un coup sourd énorme, la roche qui tremble et roule."""
    boom = amb.lp(noise(2.0), 80) * _env(int(2.0 * SR), 0.003, 0.5) * 3.0
    crack = rec("75-cc0-breaking-falling-hit-sfx/bfh1_breaking_02.ogg", -8)
    rumble = stone_grind(2.0, 45.0) * _env(int(2.0 * SR), 0.05, 0.7) * 0.6
    return _norm(s56._room(mix(2.6, (boom, 0.0, 1.0), (crack, 0.0, 0.7), (rumble, 0.05, 1.0)), 2.0, 1.5, 2500.0, 0.35, seed=641), 0.95)


def rune_brisee() -> np.ndarray:
    """Une rune brisée : le cristal qui éclate, une note qui s'éteint, un souffle de magie."""
    gl = rec("75-cc0-breaking-falling-hit-sfx/bfh1_glass_breaking_03.ogg", -2)
    note = bell(1046.5, 1.6, 1.3) * 0.5
    x = _t(1.4)
    down = np.sin(2 * np.pi * np.cumsum(np.interp(x, [0, 1.4], [1600, 300])) / SR) * _env(len(x), 0.01, 0.4) * 0.25
    return _norm(s56._room(mix(2.0, (gl, 0.0, 1.0), (note, 0.0, 1.0), (down, 0.02, 1.0)), 1.6, 2.2, 7000.0, 0.3, seed=642), 0.9)


def boss_coeur_cri() -> np.ndarray:
    """Le cri du Gardien du Cœur : un rugissement de roche, très grave, qui fait trembler."""
    r = slow(rec("80-CC0-creature-sfx-2/roar_05.ogg", 0), 2.2)
    r2 = slow(rec("80-CC0-creature-sfx-2/roar_04.ogg", 0), 1.7)
    rumble = stone_grind(3.0, 40.0) * _env(int(3.0 * SR), 0.2, 1.2) * 0.5
    sub = np.sin(2 * np.pi * 38 * _t(3.0)) * _env(int(3.0 * SR), 0.3, 1.0) * 0.6
    return _norm(s56._room(mix(3.4, (r, 0.0, 1.0), (r2, 0.15, 0.6), (rumble + sub, 0.0, 1.0)), 2.5, 1.2, 3000.0, 0.4, seed=643), 0.95)


# =================================================================== les créatures

def scorpion_menace() -> np.ndarray:
    """Le scorpion qui se dresse : un sifflement sec, le cliquetis des pinces."""
    h = rec("80-CC0-creature-SFX/bug_02.ogg", -2)
    hiss = amb.bp(noise(0.8), 3000, 9000) * _env(int(0.8 * SR), 0.05, 0.3) * 0.35
    clicks = ratchet(5, 14.0, 1.4) * 0.6
    return _norm(mix(1.0, (h, 0.0, 1.0), (hiss, 0.0, 1.0), (clicks, 0.25, 1.0)), 0.85)


def scorpion_mort() -> np.ndarray:
    crunch = rec("75-cc0-breaking-falling-hit-sfx/bfh1_breaking_01.ogg", 3)[: int(0.7 * SR)]
    h = rec("80-CC0-creature-SFX/bug_04.ogg", -5)
    return _norm(mix(1.2, (_fade(crunch, 0.001, 0.1), 0.0, 1.0), (h, 0.1, 0.6)), 0.85)


def automate_menace() -> np.ndarray:
    """L'automate de bronze qui arme son coup : des rouages qui tournent vite, un jet de vapeur."""
    x = _t(1.0)
    whirr = np.sin(2 * np.pi * np.cumsum(np.interp(x, [0, 0.7, 1.0], [180, 520, 480])) / SR)
    whirr = amb.bp(whirr + 0.4 * np.sign(np.sin(2 * np.pi * np.cumsum(np.interp(x, [0, 1.0], [30, 70])) / SR)), 150, 3000) * _env(len(x), 0.1, 0.5) * 0.4
    steam = amb.bp(noise(0.6), 2500, 10000) * _env(int(0.6 * SR), 0.02, 0.2) * 0.4
    return _norm(mix(1.2, (whirr, 0.0, 1.0), (ratchet(8, 18.0, 0.8), 0.0, 0.5), (steam, 0.55, 1.0)), 0.85)


def automate_mort() -> np.ndarray:
    fall = rec("75-cc0-breaking-falling-hit-sfx/bfh1_metal_falling_02.ogg", -3)
    x = _t(1.2)
    wind_down = np.sin(2 * np.pi * np.cumsum(np.interp(x, [0, 1.2], [500, 60])) / SR) * _env(len(x), 0.01, 0.5) * 0.3
    return _norm(mix(2.0, (wind_down, 0.0, 1.0), (fall, 0.15, 1.0)), 0.88)


def spectre_menace() -> np.ndarray:
    """Le spectre des brumes : une plainte qui monte, voilée, et un souffle froid."""
    v = slow(rec("80-CC0-creature-sfx-2/human_03.ogg", 0), 1.6)
    x = _t(2.0)
    moan = np.sin(2 * np.pi * np.cumsum(np.interp(x, [0, 1.2, 2.0], [300, 420, 360]) * (1 + 0.01 * np.sin(2 * np.pi * 5 * x))) / SR)
    moan = amb.bp(moan + 0.2 * RNG.standard_normal(len(x)), 200, 1800) * _env(len(x), 0.4, 0.8) * 0.3
    air = amb.bp(noise(2.0), 600, 4000) * _env(int(2.0 * SR), 0.3, 0.7) * 0.25
    return _norm(s56._room(mix(2.4, (amb.lp(v, 2500), 0.0, 0.6), (moan, 0.0, 1.0), (air, 0.0, 1.0)), 2.0, 1.4, 4000.0, 0.5, seed=644), 0.8)


def spectre_mort() -> np.ndarray:
    x = _t(2.2)
    wail = np.sin(2 * np.pi * np.cumsum(np.interp(x, [0, 2.2], [700, 180])) / SR)
    wail = amb.bp(wail + 0.3 * RNG.standard_normal(len(x)), 150, 3000) * _env(len(x), 0.05, 0.6) * 0.4
    air = amb.hp(noise(2.2), 2000) * _env(int(2.2 * SR), 0.02, 0.9) * 0.2
    return _norm(s56._room(wail + air, 2.0, 1.6, 5000.0, 0.5, seed=645), 0.8)


def ondin_menace() -> np.ndarray:
    s = rec("80-CC0-creature-sfx-2/slime_03.ogg", -3)
    g = rec("40-cc0-water-splash-slime-sfx/bubble_01.ogg", 0)
    burble = rec("80-CC0-creature-SFX/burble_01.ogg", -4)
    return _norm(mix(1.4, (s, 0.0, 1.0), (g, 0.1, 0.5), (burble, 0.25, 0.7)), 0.85)


def ondin_mort() -> np.ndarray:
    sp = rec("40-cc0-water-splash-slime-sfx/splash_02.ogg", -2)
    s = rec("80-CC0-creature-sfx-2/slime_06.ogg", -5)
    return _norm(mix(1.6, (sp, 0.0, 1.0), (s, 0.05, 0.6)), 0.85)


def loup_menace() -> np.ndarray:
    """Le Grand Loup des Brumes : un hurlement long, grave, dans la brume."""
    h = slow(rec("80-CC0-creature-SFX/howl.ogg", 0), 2.4)
    g = rec("beast_or_animal/Growl 1.wav", -3)[: int(1.6 * SR)]
    return _norm(s56._room(mix(3.2, (h, 0.0, 1.0), (_fade(g, 0.01, 0.4), 1.5, 0.5)), 2.2, 1.3, 4000.0, 0.45, seed=646), 0.88)


SOUNDS = {
    "niveau": niveau, "double_saut": double_saut, "charge_pret": charge_pret, "coup_charge": coup_charge,
    "tournoyante": tournoyante, "parade_parfaite": parade_parfaite, "esquive": esquive, "armure_bloque": armure_bloque,
    "forge": forge, "bourrasque": bourrasque, "flamme_lance": flamme_lance, "flamme_impact": flamme_impact,
    "rouage": rouage, "lueur": lueur, "sceau_eveil": sceau_eveil, "sceau_pose": sceau_pose,
    "porte_coeur": porte_coeur, "feu_ronces": feu_ronces, "mecanisme": mecanisme, "eau_vanne": eau_vanne,
    "geyser": geyser, "vague": vague, "lame": lame, "dard": dard, "dalle_clic": dalle_clic, "piston": piston,
    "ombre_mains": ombre_mains, "onde_choc": onde_choc, "rune_brisee": rune_brisee, "boss_coeur_cri": boss_coeur_cri,
    "scorpion_menace": scorpion_menace, "scorpion_mort": scorpion_mort, "automate_menace": automate_menace,
    "automate_mort": automate_mort, "spectre_menace": spectre_menace, "spectre_mort": spectre_mort,
    "ondin_menace": ondin_menace, "ondin_mort": ondin_mort, "loup_menace": loup_menace,
}


def main() -> int:
    global LIB
    if len(sys.argv) > 1 and Path(sys.argv[1]).is_dir():
        LIB = Path(sys.argv[1])
    only = set(sys.argv[2:])
    for name, fn in SOUNDS.items():
        if only and name not in only:
            continue
        fx.save(f"{name}_1", fn())
    return 0


if __name__ == "__main__":
    sys.exit(main())
