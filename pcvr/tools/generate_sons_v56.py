"""V56 : les sons de Port-Azur — la ville, le port, la taverne, la plage, les cigales du
jour et les grillons de la nuit, l'horloge de la place, L'Hirondelle (cloche, corne, moteur).

Synthétisés ici (domaine public) :
  sfx/cloche_1..2           l'horloge de la place sonne l'heure (cloche de bronze : bourdon,
                            fondamentale, tierce mineure, quinte, nominale… chacune s'éteint
                            à son rythme)
  sfx/cloche_bateau_1..2    la cloche du quai qui appelle L'Hirondelle (double coup, petite cloche)
  sfx/corne_brume_1         la corne de L'Hirondelle (anche grave, cuivrée, écho sur la baie)
  sfx/moteur_bateau_1       le moteur diesel du bateau (« teuf-teuf » en boucle)
  ambiance/cigales          les cigales de Provence (stridulations qui enflent et se taisent)
  ambiance/grillons         la nuit : grillons, un crapaud au loin
D'après le recueil CC0 « lavenderdotpet/CC0-Public-Domain-Sounds » :
  ambiance/ville_azur       la ville : brouhaha lointain (des dizaines de voix superposées,
                            rendues inintelligibles), tasses et verres en terrasse, roucoulements
  ambiance/port_azur        le port : clapotis contre les coques, cordages et pontons qui
                            grincent, drisses qui tintent contre les mâts
  ambiance/taverne          le Perroquet Bleu : salle pleine, verres qui trinquent
  ambiance/plage            la plage : voix d'estivants au loin, enfants, ballon
Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/generate_sons_v56.py <dossier CC0-Public-Domain-Sounds>
"""
from pathlib import Path
import sys

import numpy as np
from scipy import signal

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402

SR = 44100
RNG = np.random.default_rng(5656)


def _norm(x: np.ndarray, peak: float = 0.89) -> np.ndarray:
    sos = signal.butter(2, 35.0, btype="highpass", fs=SR, output="sos")
    x = signal.sosfilt(sos, x, axis=0)
    return x / (np.max(np.abs(x)) + 1e-9) * peak


def _room(x: np.ndarray, seconds: float, decay: float, lp_hz: float, wet: float, seed: int = 1) -> np.ndarray:
    """Réverbération (bruit qui décroît, filtré), stéréo si x est stéréo."""
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    t = np.arange(n) / SR
    chans = [x] if x.ndim == 1 else [x[:, 0], x[:, 1]]
    out = []
    for c in chans:
        ir = rng.standard_normal(n) * np.exp(-t * decay)
        ir = amb.lp(ir, lp_hz, order=4)
        ir *= np.clip((n - np.arange(n)) / (0.35 * n), 0, 1) ** 2   # la queue s'éteint en douceur
        ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
        y = signal.fftconvolve(c, ir)[: len(c)]
        out.append(c * (1 - wet) + y * wet * 2.5)
    return out[0] if x.ndim == 1 else np.stack(out, axis=1)


def _env(m: int, a: float, d: float) -> np.ndarray:
    x = np.arange(m) / SR
    return np.clip(x / max(a, 1e-4), 0, 1) * np.exp(-x / d)


# =================================================================== cloches, corne, moteur

def bronze_bell(f: float, dur: float, bright: float = 1.0) -> np.ndarray:
    """Cloche de bronze : partiels « hum, prime, tierce, quinte, nominale » et au-delà."""
    m = int(dur * SR)
    x = np.arange(m) / SR
    partials = [  # rapport, amplitude, durée de vie (s)
        (0.5, 0.55, dur * 0.55), (1.0, 0.8, dur * 0.35), (1.19, 0.6, dur * 0.25), (1.5, 0.3, dur * 0.18),
        (2.0, 0.65 * bright, dur * 0.14), (2.52, 0.3 * bright, dur * 0.09), (2.66, 0.25 * bright, dur * 0.08),
        (3.01, 0.22 * bright, dur * 0.06), (4.17, 0.12 * bright, dur * 0.04), (5.43, 0.07 * bright, dur * 0.03)]
    y = np.zeros(m)
    for r, a, d in partials:
        beat = 1.0 + 0.002 * RNG.standard_normal()
        y += a * np.sin(2 * np.pi * f * r * beat * x + RNG.uniform(0, 6)) * np.exp(-x / d)
        # battements (la cloche n'est pas parfaitement ronde)
        y += a * 0.25 * np.sin(2 * np.pi * (f * r + RNG.uniform(0.6, 2.2)) * x) * np.exp(-x / d)
    strike = amb.bp(RNG.standard_normal(int(0.03 * SR)), 1500, 6000) * np.hanning(int(0.03 * SR)) * 0.25
    y[: len(strike)] += strike
    return y * np.clip(x / 0.002, 0, 1) * np.clip((dur - x) / (0.25 * dur), 0, 1)


def clock_bell(k: int) -> np.ndarray:
    f = [196.0, 174.6][k]
    y = bronze_bell(f, 7.0)
    st = np.stack([y, np.roll(y, 37)], axis=1)
    return _norm(_room(st, 3.5, 0.9, 3500.0, 0.35, seed=k + 3))


def ship_bell(k: int) -> np.ndarray:
    f = [880.0, 932.3][k]
    a = bronze_bell(f, 2.6, 1.3)
    gap = int([0.42, 0.38][k] * SR)
    y = np.zeros(len(a) + gap)
    y[: len(a)] += a
    y[gap:] += a * 0.85
    return _norm(_room(y, 1.4, 2.2, 5000.0, 0.25, seed=k + 9))


def fog_horn() -> np.ndarray:
    """Corne de bateau : anche grave (dents de scie), formant cuivré, montée puis tenue."""
    dur = 3.2
    m = int(dur * SR)
    x = np.arange(m) / SR
    f = 110.0 * (1 + 0.025 * np.clip(x / 0.35, 0, 1)) * (1 + 0.003 * np.sin(2 * np.pi * 5.5 * x))
    ph = np.cumsum(f) / SR
    saw = 2.0 * (ph % 1.0) - 1.0
    saw2 = 2.0 * ((ph * 1.004 + 0.3) % 1.0) - 1.0
    y = saw + 0.8 * saw2
    y = amb.bp(y, 160, 900) * 1.4 + amb.lp(y, 400) * 0.6
    y = np.tanh(y * 1.6)
    env = np.clip(x / 0.25, 0, 1) * np.clip((dur - x) / 0.6, 0, 1)
    y = y * env
    y = np.concatenate([y, np.zeros(int(3.0 * SR))])
    # écho sur la baie (deux retours lointains)
    out = y.copy()
    for d, g in [(0.9, 0.28), (1.7, 0.14)]:
        k = int(d * SR)
        out[k:] += amb.lp(y[:-k], 900) * g
    st = np.stack([out, np.roll(out, 61)], axis=1)
    return _norm(_room(st, 2.5, 1.4, 1800.0, 0.3, seed=21))


def diesel(seconds: float = 6.0) -> np.ndarray:
    """Moteur diesel de vieux bateau : explosions régulières (≈ 9 par seconde), carter qui
    ronronne, échappement mouillé ; en boucle."""
    n = int(seconds * SR)
    y = np.zeros(n)
    rate = 9.0
    t = 0.0
    i = 0
    while t < seconds:
        m = int(0.09 * SR)
        xx = np.arange(m) / SR
        pulse = (np.sin(2 * np.pi * 55 * xx) * 0.9 + amb.lp(RNG.standard_normal(m), 700) * 0.6) * np.exp(-xx / 0.025)
        g = 1.0 if i % 2 == 0 else 0.72
        at = int(t * SR)
        end = min(n, at + m)
        y[at:end] += pulse[: end - at] * g
        t += 1.0 / rate * (1 + 0.02 * RNG.standard_normal())
        i += 1
    tt = np.arange(n) / SR
    hum = np.sin(2 * np.pi * 27 * tt) * 0.35 + np.sin(2 * np.pi * 54 * tt + 1) * 0.2
    rattle = amb.bp(RNG.standard_normal(n), 900, 2600) * 0.05 * (0.6 + 0.4 * np.sin(2 * np.pi * rate * tt))
    wet = amb.bp(RNG.standard_normal(n), 200, 900) * 0.12 * np.clip(np.sin(2 * np.pi * rate / 2 * tt), 0, 1)
    y = amb.lp(y, 1200) + hum + rattle + wet
    return _norm(amb.loopify(np.stack([y, np.roll(y, 23)], axis=1), 0.5))


# =================================================================== nappes synthétisées

def provence_cicadas(seconds: float = 44.0) -> np.ndarray:
    """Cigales de Provence : chaque chanteuse est un grésillement rauque (impulsions rapides
    filtrées vers 5-7 kHz) qui enfle en longues phrases puis se tait d'un coup ; un chœur
    lointain ne s'arrête jamais."""
    n = int(seconds * SR)
    out = np.zeros((n, 2))
    tt = np.arange(n) / SR
    for k in range(7):
        f0 = RNG.uniform(5200, 7400)
        pulse_rate = RNG.uniform(160, 260)
        buzz = (np.sin(2 * np.pi * pulse_rate * tt) > 0.2).astype(float)
        c = amb.bp(RNG.standard_normal(n) * buzz, f0 * 0.82, f0 * 1.18)
        c += amb.bp(RNG.standard_normal(n) * buzz, f0 * 1.9, f0 * 2.2) * 0.25
        # des phrases de 4 à 12 s, coupées net
        env = np.zeros(n)
        t = RNG.uniform(0, 4)
        while t < seconds:
            ln = RNG.uniform(4, 12)
            a = int(t * SR)
            b = min(n, int((t + ln) * SR))
            seg = np.linspace(0, 1, b - a)
            env[a:b] = np.clip(seg * 4, 0, 1) ** 1.5 * (0.7 + 0.3 * np.sin(2 * np.pi * 0.4 * tt[a:b])) * (seg < 0.97)
            t += ln + RNG.uniform(1, 6)
        c *= env * RNG.uniform(0.4, 1.0)
        pan = RNG.uniform(-0.9, 0.9)
        out[:, 0] += c * np.sqrt(0.5 * (1 - pan))
        out[:, 1] += c * np.sqrt(0.5 * (1 + pan))
    chorus = amb.bp(RNG.standard_normal(n), 4800, 7600) * (0.5 + 0.5 * (np.sin(2 * np.pi * 190 * tt) > 0)) * 0.15
    out[:, 0] += chorus
    out[:, 1] += np.roll(chorus, SR // 3)
    out += np.stack([amb.bp(amb.noise(n, "pink"), 200, 2000)] * 2, axis=1) * 0.03
    return amb.loopify(out, 2.0)


def night_crickets(seconds: float = 44.0) -> np.ndarray:
    """La nuit : des grillons (trilles de trois impulsions vers 4,5 kHz, chacun à son rythme),
    un crapaud lointain, la brise."""
    n = int(seconds * SR)
    out = np.zeros((n, 2))
    for k in range(9):
        f = RNG.uniform(4100, 5000)
        period = RNG.uniform(0.45, 0.8)
        pulses = RNG.integers(3, 5)
        pan = RNG.uniform(-1, 1)
        gain = RNG.uniform(0.15, 0.6)
        m = int(0.018 * SR)
        xx = np.arange(m) / SR
        tick = np.sin(2 * np.pi * f * xx) * np.hanning(m)
        chirp = np.zeros(int(pulses * 0.03 * SR) + m)
        for p in range(pulses):
            a = int(p * 0.03 * SR)
            chirp[a:a + m] += tick
        t = RNG.uniform(0, period)
        while t < seconds - 0.3:
            amb.place(out, chirp * (0.8 + 0.2 * RNG.random()), int(t * SR), gain, pan)
            t += period * (1 + 0.04 * RNG.standard_normal())
            if RNG.random() < 0.02:
                t += RNG.uniform(2, 6)
    for _ in range(int(seconds / 5)):
        m = int(RNG.uniform(0.8, 1.4) * SR)
        xx = np.arange(m) / SR
        f = RNG.uniform(380, 520)
        toad = np.sin(2 * np.pi * f * xx) * (np.sin(2 * np.pi * 13 * xx) > -0.2) * np.hanning(m)
        amb.place(out, amb.lp(toad, 1500), int(RNG.uniform(0, seconds - 1.5) * SR), 0.05, RNG.uniform(-1, 1))
    out += np.stack([amb.lp(amb.noise(n, "pink"), 500), amb.lp(amb.noise(n, "pink"), 500)], axis=1) * 0.025
    return amb.loopify(out, 2.0)


# =================================================================== d'après le recueil CC0

def _read(lib: Path, rel: str) -> np.ndarray:
    p = lib / rel
    if not p.is_file():
        return np.zeros(0)
    return amb.read_any(p).mean(axis=1)


def _shift(x: np.ndarray, semi: float) -> np.ndarray:
    if len(x) == 0 or semi == 0:
        return x
    r = 2 ** (semi / 12.0)
    pos = np.arange(0, len(x) - 1, r)
    return np.interp(pos, np.arange(len(x)), x)


def _voices(lib: Path) -> list:
    out = []
    for d in ["kenney_voiceoverpack/Male", "kenney_voiceoverpack/Female", "kenney_voiceoverfighter/Audio" ]:
        dd = lib / d
        if dd.is_dir():
            for f in sorted(dd.glob("*.ogg")):
                x = amb.read_any(f).mean(axis=1)
                # on enlève les silences
                e = np.abs(x) > 0.02
                if e.any():
                    i0 = max(0, np.argmax(e) - 200)
                    i1 = len(x) - np.argmax(e[::-1]) + 200
                    x = x[i0:i1]
                if len(x) > 0.15 * SR:
                    out.append(x / (np.max(np.abs(x)) + 1e-9))
    return out


def walla(lib: Path, seconds: float, density: float, lp_hz: float, semis=(-3.0, 3.0), gain_r=(0.2, 1.0)) -> np.ndarray:
    """Brouhaha : des dizaines de bribes de voix superposées, transposées, coupées en syllabes
    et assourdies : on entend des gens parler sans comprendre un mot."""
    vs = _voices(lib)
    n = int(seconds * SR)
    out = np.zeros((n, 2))
    if not vs:
        return out
    count = int(seconds * density)
    for _ in range(count):
        v = vs[RNG.integers(0, len(vs))]
        # une syllabe ou deux, pas le mot entier
        ln = int(RNG.uniform(0.12, 0.45) * SR)
        a = RNG.integers(0, max(1, len(v) - ln))
        s = v[a:a + ln] * np.hanning(min(ln, len(v) - a))
        s = _shift(s, RNG.uniform(*semis))
        s = amb.lp(s, lp_hz * RNG.uniform(0.8, 1.2), order=4)
        amb.place(out, s, int(RNG.uniform(0, seconds - 0.6) * SR), RNG.uniform(*gain_r), RNG.uniform(-0.9, 0.9))
    return out


def scatter(out: np.ndarray, clips: list, per_min: float, gain_r, semis=(-2.0, 2.0), lp_hz: float = 0.0) -> None:
    clips = [c for c in clips if len(c) > 0]
    if not clips:
        return
    seconds = len(out) / SR
    for _ in range(int(seconds / 60.0 * per_min)):
        c = clips[RNG.integers(0, len(clips))]
        c = _shift(c, RNG.uniform(*semis))
        k = min(len(c) // 4, int(0.03 * SR))
        if k > 2:
            c = c.copy()
            c[:k] *= np.linspace(0, 1, k)
            c[-k:] *= np.linspace(1, 0, k)
        if lp_hz > 0:
            c = amb.lp(c, lp_hz)
        at = int(RNG.uniform(0, max(0.1, seconds - len(c) / SR - 0.1)) * SR)
        amb.place(out, c, at, RNG.uniform(*gain_r), RNG.uniform(-0.9, 0.9))


def pigeon(k: int) -> np.ndarray:
    """Roucoulement de pigeon : « rrou-rrou-rrouuu » grave, grasseyé."""
    parts = []
    for i in range(3):
        m = int((0.25 if i < 2 else 0.55) * SR)
        x = np.arange(m) / SR
        f = np.interp(x, [0, x[-1] * 0.3, x[-1]], [380, 470, 360]) * (1 + 0.04 * k)
        ph = 2 * np.pi * np.cumsum(f) / SR
        y = (np.sin(ph) + 0.4 * np.sin(2 * ph)) * (0.6 + 0.4 * np.sin(2 * np.pi * 30 * x))
        parts += [y * np.hanning(m), np.zeros(int(0.08 * SR))]
    return amb.lp(np.concatenate(parts), 1400)


def lapping(n: int) -> np.ndarray:
    """Clapotis contre les coques et les piles du ponton : petites claques d'eau."""
    out = np.zeros((n, 2))
    for _ in range(int(n / SR * 2.0)):
        m = int(RNG.uniform(0.08, 0.25) * SR)
        e = amb.bp(RNG.standard_normal(m), RNG.uniform(200, 400), RNG.uniform(900, 1800)) * _env(m, 0.012, m / SR * 0.25)
        e *= np.clip((m - np.arange(m)) / (0.3 * m), 0, 1)
        amb.place(out, e, RNG.integers(0, n - m), RNG.uniform(0.04, 0.16), RNG.uniform(-1, 1))
    swell = amb.lp(amb.noise(n, "brown"), 300) * amb.smooth_env(n, 0.3, 0.3, 1.0) * 0.12
    out[:, 0] += swell
    out[:, 1] += np.roll(swell, SR // 2)
    return out


def halyard(k: int) -> np.ndarray:
    """Une drisse qui tinte contre un mât d'aluminium (« ting », creux et métallique)."""
    f = [1250.0, 1480.0, 1710.0][k % 3] * RNG.uniform(0.95, 1.05)
    m = int(1.2 * SR)
    x = np.arange(m) / SR
    y = sum(a * np.sin(2 * np.pi * f * r * x) * np.exp(-x / d) for r, a, d in [(1, 1, 0.25), (2.76, 0.5, 0.12), (5.4, 0.25, 0.05), (0.5, 0.2, 0.3)])
    y += amb.bp(RNG.standard_normal(m), 3000, 7000) * np.exp(-x / 0.003) * 0.15
    y *= np.clip(x / 0.001, 0, 1)
    return y


def town_bed(lib: Path, seconds: float = 48.0) -> np.ndarray:
    n = int(seconds * SR)
    out = walla(lib, seconds, 9.0, 1900.0, gain_r=(0.12, 0.45))
    out = _room(out, 1.6, 2.4, 2600.0, 0.4, seed=31)
    cups = [_read(lib, f"100-cc0-sfx-2/sfx100v2_glass_0{i}.ogg") for i in range(1, 7)]
    cups += [_read(lib, f"kenney_impactsounds/Audio/impactGlass_light_00{i}.ogg") for i in range(0, 5)]
    scatter(out, [amb.hp(c, 400) for c in cups], 22, (0.05, 0.16), semis=(0.0, 5.0), lp_hz=6000.0)
    scatter(out, [pigeon(k) for k in range(3)], 6, (0.05, 0.12), semis=(-1.0, 1.0))
    # une rumeur de fond (pas, chaises, la mer derrière les maisons)
    out += np.stack([amb.bp(amb.noise(n, "pink"), 120, 1400)] * 2, axis=1) * 0.04
    return amb.loopify(out, 2.0)


def port_bed(lib: Path, seconds: float = 48.0) -> np.ndarray:
    n = int(seconds * SR)
    out = lapping(n)
    creaks = [_read(lib, f"kenney_rpgaudio/Audio/creak{i}.ogg") for i in (1, 2, 3)]
    scatter(out, [amb.lp(c, 2500) for c in creaks], 10, (0.12, 0.3), semis=(-7.0, -2.0))
    scatter(out, [halyard(k) for k in range(6)], 26, (0.03, 0.09), semis=(-0.3, 0.3))
    far = walla(lib, seconds, 3.0, 1300.0, gain_r=(0.05, 0.18))
    out += _room(far, 1.8, 2.0, 1800.0, 0.5, seed=41)
    return amb.loopify(out, 2.0)


def tavern_bed(lib: Path, seconds: float = 40.0) -> np.ndarray:
    out = walla(lib, seconds, 22.0, 3200.0, semis=(-4.0, 2.5), gain_r=(0.15, 0.6))
    glass = [_read(lib, f"100-cc0-sfx-2/sfx100v2_glass_0{i}.ogg") for i in range(1, 7)]
    glass += [_read(lib, f"kenney_impactsounds/Audio/impactGlass_medium_00{i}.ogg") for i in range(0, 2)]
    glass.append(_read(lib, "BB_Retail Therapy Sample Pack/Glass Glasses 1.wav"))
    scatter(out, [amb.hp(c, 300) for c in glass], 40, (0.08, 0.28), semis=(-1.0, 3.0))
    chairs = [_read(lib, f"kenney_rpgaudio/Audio/creak{i}.ogg") for i in (1, 2, 3)]
    scatter(out, [amb.lp(c, 1500) for c in chairs], 8, (0.05, 0.12), semis=(-9.0, -5.0))
    out = _room(out, 0.9, 5.0, 3500.0, 0.3, seed=51)
    return amb.loopify(out, 2.0)


def beach_bed(lib: Path, seconds: float = 44.0) -> np.ndarray:
    out = walla(lib, seconds, 5.0, 2600.0, semis=(-1.0, 6.0), gain_r=(0.08, 0.3))
    out = _room(out, 1.2, 3.0, 3000.0, 0.25, seed=61)
    # le ballon qui rebondit, au loin
    m = int(0.12 * SR)
    xx = np.arange(m) / SR
    ball = amb.bp(RNG.standard_normal(m), 150, 900) * np.exp(-xx / 0.02) + np.sin(2 * np.pi * 140 * xx) * np.exp(-xx / 0.03)
    seq = np.zeros(int(1.6 * SR))
    for i, (t, g) in enumerate([(0.0, 1.0), (0.55, 0.7), (0.95, 0.5)]):
        amb.place(seq, ball, int(t * SR), g)
    scatter(out, [seq], 3, (0.04, 0.09), semis=(-1.0, 1.0))
    return amb.loopify(out, 2.0)


# =================================================================== lancement

def main() -> int:
    for k in range(2):
        fx.save(f"cloche_{k + 1}", clock_bell(k))
        fx.save(f"cloche_bateau_{k + 1}", ship_bell(k))
    fx.save("corne_brume_1", fog_horn())
    fx.save("moteur_bateau_1", diesel())
    amb.save("ambiance/cigales", provence_cicadas())
    amb.save("ambiance/grillons", night_crickets())
    lib = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    if lib is None or not lib.is_dir():
        print("Sans le recueil CC0, seuls les sons synthétisés sont refaits.")
        return 0
    amb.save("ambiance/ville_azur", town_bed(lib))
    amb.save("ambiance/port_azur", port_bed(lib))
    amb.save("ambiance/taverne", tavern_bed(lib))
    amb.save("ambiance/plage", beach_bed(lib))
    return 0


if __name__ == "__main__":
    sys.exit(main())
