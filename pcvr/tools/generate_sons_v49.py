"""V49 : les ambiances sonores d'Île Manga.

Deux origines, toutes deux libres (domaine public / CC0) :
 1. Enregistrements CC0 (Freesound, via les versions publiées par DNAABR/ambient-sounds-library et
    le recueil lavenderdotpet/CC0-Public-Domain-Sounds) : oiseaux de forêt, brise, ruisseau,
    rivière, bouillonnement, coups de marteau sur métal. Ils sont découpés, bouclés sans
    raccord audible, normalisés et convertis en OGG Vorbis.
 2. Sons synthétisés ici (numpy) : ressac des vagues, houle du large, vent du volcan, cigales et
    grenouilles de la jungle, cris de mouettes, oiseaux exotiques, gouttes et bourdon des grottes,
    nappe féerique et carillons, feu qui crépite, grondement de lave, sifflement des fumerolles,
    grondement de cascade.

Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/generate_sons_v49.py <dossier des enregistrements CC0>
Le dossier doit contenir nature-forest-day.wav, wind-breeze.wav, water-stream.wav,
water-river.wav (DNAABR) et le dépôt CC0-Public-Domain-Sounds. Sans lui, seuls les sons
synthétisés sont refaits.
"""
from pathlib import Path
import subprocess
import sys
import tempfile

import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "sons"
RNG = np.random.default_rng(4900)


# =================================================================== outils

def save(name: str, x: np.ndarray, quality: int = 4) -> None:
    """x : (n,) mono ou (n, 2) stéréo, flottant. Normalisé, écrit en OGG Vorbis."""
    path = OUT / f"{name}.ogg"
    path.parent.mkdir(parents=True, exist_ok=True)
    # Pas de composante continue ni d'infra-basse (elles mangent la marge sans s'entendre)
    # (filtrage « circulaire » : on amorce le filtre avec la fin du son, la boucle reste sans raccord)
    k = min(len(x) // 2, SR)
    ext = np.concatenate([x[-k:], x])
    ext = hp(ext.T, 28.0).T if x.ndim == 2 else hp(ext, 28.0)
    x = ext[k:]
    peak = np.max(np.abs(x)) + 1e-9
    x = x / peak * 0.89
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        wavfile.write(tmp.name, SR, (x * 32767).astype(np.int16))
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp.name, "-c:a", "libvorbis", "-q:a", str(quality), str(path)], check=True)
    print(f"{name}: {len(x) / SR:.1f} s, {path.stat().st_size // 1024} Ko")


def loopify(x: np.ndarray, fade_s: float = 2.0) -> np.ndarray:
    """Boucle sans raccord : la fin se fond dans le début (fondu à puissance constante)."""
    n = int(fade_s * SR)
    head = x[:n]
    tail = x[-n:]
    t = np.linspace(0.0, 1.0, n)
    a = np.sqrt(1.0 - t)
    b = np.sqrt(t)
    if x.ndim == 2:
        a = a[:, None]
        b = b[:, None]
    mixed = tail * a + head * b
    return np.concatenate([mixed, x[n:-n]])


def noise(n: int, color: str = "white") -> np.ndarray:
    w = RNG.standard_normal(n)
    if color == "white":
        return w
    f = np.fft.rfftfreq(n, 1.0 / SR)
    f[0] = f[1]
    spec = np.fft.rfft(w)
    if color == "pink":
        spec /= np.sqrt(f)
    elif color == "brown":
        spec /= f
    y = np.fft.irfft(spec, n)
    return y / (np.std(y) + 1e-9)


def bp(x, lo, hi, order=2):
    sos = signal.butter(order, [lo, hi], btype="bandpass", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def lp(x, fc, order=2):
    sos = signal.butter(order, fc, btype="lowpass", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def hp(x, fc, order=2):
    sos = signal.butter(order, fc, btype="highpass", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def smooth_env(n: int, rate_hz: float, lo: float, hi: float) -> np.ndarray:
    """Enveloppe aléatoire lente entre lo et hi."""
    k = max(int(n / SR * rate_hz) + 3, 4)
    pts = RNG.uniform(lo, hi, k)
    xs = np.linspace(0, n, k)
    return np.interp(np.arange(n), xs, pts)


def tv_lowpass(x: np.ndarray, fc: np.ndarray) -> np.ndarray:
    """Filtre passe-bas à fréquence variable (un pôle), pour les vagues et le vent."""
    a = np.exp(-2.0 * np.pi * np.clip(fc, 20, SR / 2.2) / SR)
    y = np.empty_like(x)
    s = 0.0
    for i in range(len(x)):
        s = a[i] * s + (1.0 - a[i]) * x[i]
        y[i] = s
    return y


def stereo(l, r):
    return np.stack([l, r], axis=1)


def place(buf: np.ndarray, ev: np.ndarray, at: int, gain: float = 1.0, pan: float = 0.0) -> None:
    end = min(len(buf), at + len(ev))
    seg = ev[: end - at] * gain
    if buf.ndim == 2:
        buf[at:end, 0] += seg * np.sqrt(0.5 * (1 - pan))
        buf[at:end, 1] += seg * np.sqrt(0.5 * (1 + pan))
    else:
        buf[at:end] += seg


# =================================================================== sons synthétisés

def surf(seconds=48.0):
    """Ressac : chaque vague monte (bruit qui s'éclaircit), déferle, puis l'écume se retire."""
    n = int(seconds * SR)
    out = np.zeros((n, 2))
    t = 0.0
    while t < seconds - 1.0:
        period = RNG.uniform(5.5, 9.0)
        length = period + 2.5
        m = int(length * SR)
        tt = np.linspace(0, length, m)
        rise = RNG.uniform(1.6, 2.6)
        env = np.where(tt < rise, (tt / rise) ** 2, np.exp(-(tt - rise) / RNG.uniform(1.6, 2.6)))
        fc = 250 + 3800 * np.where(tt < rise, tt / rise, np.exp(-(tt - rise) / 1.2))
        for ch in range(2):
            src = noise(m, "pink")
            wave = tv_lowpass(src, fc) * env
            fizz = hp(noise(m), 3000) * env * np.clip((tt - rise) / 0.4, 0, 1) * np.exp(-(tt - rise).clip(0) / 1.6) * 0.18
            place(out[:, ch], wave + fizz, int(t * SR), RNG.uniform(0.6, 1.0))
        t += period * RNG.uniform(0.75, 1.0)
    bed = stereo(lp(noise(n, "brown"), 400), lp(noise(n, "brown"), 400)) * 0.25
    return loopify(out + bed, 3.0)


def sea_open(seconds=40.0):
    """Le grand large, depuis la barque : houle sourde, clapot, souffle du vent."""
    n = int(seconds * SR)
    swell = smooth_env(n, 0.18, 0.3, 1.0)
    l = tv_lowpass(noise(n, "pink"), 300 + 700 * swell) * swell
    r = tv_lowpass(noise(n, "pink"), 300 + 700 * swell[::-1]) * swell[::-1]
    lap = np.zeros(n)
    for _ in range(int(seconds * 1.6)):
        m = int(RNG.uniform(0.08, 0.25) * SR)
        e = bp(noise(m), 600, 2400) * np.hanning(m)
        place(lap, e, RNG.integers(0, n - m), RNG.uniform(0.1, 0.35))
    wind = hp(tv_lowpass(noise(n, "pink"), 900 + 600 * smooth_env(n, 0.3, 0, 1)), 200) * 0.25
    return loopify(stereo(l + lap + wind, r + lap * 0.8 + wind), 3.0)


def wind_volcano(seconds=40.0):
    """Vent du volcan : rafales sourdes et sifflements, plus grave que la brise."""
    n = int(seconds * SR)
    gust = smooth_env(n, 0.35, 0.15, 1.0) ** 1.5
    ch = []
    for k in range(2):
        g = np.roll(gust, k * SR // 2)
        body = tv_lowpass(noise(n, "pink"), 200 + 900 * g) * (0.4 + g)
        whistle = bp(noise(n), 700 + 300 * k, 760 + 300 * k, 2) * g * 1.6
        ch.append(body + whistle)
    return loopify(stereo(*ch), 3.0)


def cicadas(seconds=30.0):
    """Jungle : nappe d'insectes (cigales qui enflent et se taisent), grenouilles, criquets."""
    n = int(seconds * SR)
    out = np.zeros((n, 2))
    tt = np.arange(n) / SR
    for k in range(5):
        f0 = RNG.uniform(4200, 6800)
        am = 0.5 + 0.5 * np.sin(2 * np.pi * RNG.uniform(40, 90) * tt)
        swell = 0.15 + 0.85 * np.clip(np.sin(2 * np.pi * tt / RNG.uniform(6, 14) + RNG.uniform(0, 6)) * 1.6, 0, 1)
        c = bp(noise(n), f0 * 0.93, f0 * 1.07) * am * swell
        pan = RNG.uniform(-0.8, 0.8)
        out[:, 0] += c * np.sqrt(0.5 * (1 - pan))
        out[:, 1] += c * np.sqrt(0.5 * (1 + pan))
    # Un fond de sous-bois qui ne s'arrête jamais
    bed = bp(noise(n, "pink"), 300, 3000) * 0.12
    out[:, 0] += bed
    out[:, 1] += np.roll(bed, SR // 4)
    # Grenouilles : coassements graves répétés
    for _ in range(int(seconds * 1.2)):
        f = RNG.uniform(220, 480)
        reps = RNG.integers(2, 5)
        ev = []
        for r in range(reps):
            m = int(0.07 * SR)
            x = np.arange(m) / SR
            ev.append(np.sign(np.sin(2 * np.pi * f * x)) * np.hanning(m) * 0.6)
            ev.append(np.zeros(int(0.06 * SR)))
        e = lp(np.concatenate(ev), 1800)
        place(out, e, RNG.integers(0, n - len(e)), RNG.uniform(0.05, 0.16), RNG.uniform(-1, 1))
    # Criquets : stridulations rapides
    for _ in range(int(seconds * 0.8)):
        f = RNG.uniform(3500, 4500)
        m = int(RNG.uniform(0.6, 1.4) * SR)
        x = np.arange(m) / SR
        e = np.sin(2 * np.pi * f * x) * (np.sin(2 * np.pi * 28 * x) > 0.3) * np.hanning(m)
        place(out, e, RNG.integers(0, n - m), RNG.uniform(0.03, 0.08), RNG.uniform(-1, 1))
    return loopify(out, 2.0)


def chirp_call(f0, f1, dur, harm=(1.0, 0.3), vib=0.0):
    m = int(dur * SR)
    x = np.arange(m) / SR
    f = np.linspace(f0, f1, m) + vib * np.sin(2 * np.pi * 22 * x) * f0 * 0.03
    ph = 2 * np.pi * np.cumsum(f) / SR
    y = sum(a * np.sin(ph * (i + 1)) for i, a in enumerate(harm))
    env = np.sin(np.pi * np.linspace(0, 1, m)) ** 0.7
    return y * env


def jungle_bird(k):
    """Oiseaux exotiques : sifflets glissés, trilles, appels doubles."""
    if k == 0:
        parts = [chirp_call(1800, 3200, 0.18), np.zeros(int(0.05 * SR)), chirp_call(3200, 1500, 0.25)]
    elif k == 1:
        parts = []
        for i in range(9):
            parts += [chirp_call(2600 + 200 * (i % 2), 3000, 0.05), np.zeros(int(0.025 * SR))]
    elif k == 2:
        parts = [chirp_call(900, 1300, 0.35, (1.0, 0.5, 0.2), vib=1.0), np.zeros(int(0.12 * SR)), chirp_call(1300, 800, 0.4, (1.0, 0.5, 0.2), vib=1.0)]
    else:
        parts = [chirp_call(4200, 2400, 0.12), np.zeros(int(0.08 * SR))] * 3
    y = np.concatenate(parts)
    tail = np.zeros(int(0.6 * SR))
    y = np.concatenate([y, tail])
    # petite réverbération de sous-bois
    ir = np.exp(-np.arange(int(0.5 * SR)) / (0.12 * SR)) * RNG.standard_normal(int(0.5 * SR)) * 0.05
    return np.convolve(y, ir)[: len(y)] + y


def gull(k):
    """Mouette : « kiaou » plaintif (glissando descendant, timbre nasal), répété."""
    parts = []
    for i in range(2 + k):
        m = int(RNG.uniform(0.28, 0.45) * SR)
        x = np.arange(m) / SR
        f = np.interp(x, [0, x[-1] * 0.25, x[-1]], [1500, 2100, 1100]) * RNG.uniform(0.9, 1.1)
        ph = 2 * np.pi * np.cumsum(f) / SR
        y = np.sin(ph) + 0.7 * np.sin(2 * ph) + 0.5 * np.sin(3 * ph) + 0.25 * np.sin(5 * ph)
        y = y * (1 + 0.4 * np.sin(2 * np.pi * 35 * x))
        y *= np.sin(np.pi * np.linspace(0, 1, m)) ** 0.5
        y += bp(noise(m), 1500, 4000) * 0.15 * np.hanning(m)
        parts += [y, np.zeros(int(RNG.uniform(0.08, 0.2) * SR))]
    return bp(np.concatenate(parts), 700, 6000)


def cave_drone(seconds=40.0):
    """Grotte : bourdon grave, souffle d'air, lointaines résonances."""
    n = int(seconds * SR)
    tt = np.arange(n) / SR
    out = np.zeros((n, 2))
    for f, a in [(55, 0.5), (82.4, 0.3), (110, 0.18)]:
        mod = 0.7 + 0.3 * np.sin(2 * np.pi * tt / RNG.uniform(7, 13))
        out[:, 0] += np.sin(2 * np.pi * f * tt) * a * mod
        out[:, 1] += np.sin(2 * np.pi * f * 1.003 * tt) * a * mod
    air = lp(noise(n, "pink"), 500) * 0.6 * smooth_env(n, 0.2, 0.5, 1.0)
    out[:, 0] += air
    out[:, 1] += np.roll(air, SR // 3)
    return loopify(out, 3.0)


def drip(k):
    """Une goutte qui tombe dans une flaque : « plic » ascendant + écho de grotte."""
    m = int(0.09 * SR)
    x = np.arange(m) / SR
    f = np.interp(x, [0, x[-1]], [700 + 250 * k, 1900 + 400 * k])
    y = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-x / 0.025)
    y = np.concatenate([y, np.zeros(int(1.6 * SR))])
    ir = np.zeros(int(1.5 * SR))
    for d, g in [(0.11, 0.35), (0.23, 0.22), (0.41, 0.14), (0.67, 0.08), (0.9, 0.05)]:
        ir[int(d * SR)] = g
    ir[0] = 1.0
    ir = np.convolve(ir, np.exp(-np.arange(int(0.05 * SR)) / (0.01 * SR)))[: len(ir)]
    return lp(np.convolve(y, ir)[: len(y)], 5000)


def fairy_pad(seconds=32.0):
    """Royaume des fées : accord suspendu qui scintille, notes de cristal éparses."""
    n = int(seconds * SR)
    tt = np.arange(n) / SR
    out = np.zeros((n, 2))
    chord = [261.6, 329.6, 392.0, 493.9, 587.3, 784.0]   # do maj9 (do mi sol si ré sol)
    for i, f in enumerate(chord):
        mod = 0.55 + 0.45 * np.sin(2 * np.pi * tt / (7 + i * 1.7) + i)
        for ch, det in [(0, 0.998), (1, 1.002)]:
            ph = 2 * np.pi * f * det * tt + 0.3 * np.sin(2 * np.pi * 0.2 * tt + i)
            out[:, ch] += (np.sin(ph) + 0.2 * np.sin(2 * ph)) * 0.12 * mod
    scale = [1046.5, 1174.7, 1318.5, 1568.0, 1760.0, 2093.0]
    for _ in range(int(seconds * 1.1)):
        f = scale[RNG.integers(0, len(scale))]
        e = bell(f, 1.8)
        place(out, e, RNG.integers(0, n - len(e)), RNG.uniform(0.04, 0.1), RNG.uniform(-0.9, 0.9))
    return loopify(out, 3.0)


def bell(f, dur):
    m = int(dur * SR)
    x = np.arange(m) / SR
    partials = [(1.0, 1.0, 1.2), (2.76, 0.4, 0.6), (5.4, 0.2, 0.3), (8.9, 0.08, 0.15)]
    y = sum(a * np.sin(2 * np.pi * f * r * x) * np.exp(-x / d) for r, a, d in partials)
    return y * np.clip(x / 0.004, 0, 1)


def fire_crackle(seconds=20.0):
    """Feu de bois : souffle sourd des flammes, crépitements et petits craquements."""
    n = int(seconds * SR)
    out = lp(noise(n, "brown"), 300) * 0.5 * smooth_env(n, 1.5, 0.6, 1.0)
    out += bp(noise(n, "pink"), 300, 1200) * 0.12 * smooth_env(n, 3.0, 0.4, 1.0)
    for _ in range(int(seconds * 14)):
        m = int(RNG.uniform(0.002, 0.012) * SR)
        e = hp(noise(m), RNG.uniform(1500, 4000)) * np.exp(-np.arange(m) / (m / 3))
        place(out, e, RNG.integers(0, n - m), RNG.uniform(0.2, 1.0) ** 2 * 1.4)
    for _ in range(int(seconds * 0.6)):
        m = int(0.05 * SR)
        e = bp(noise(m), 500, 2500) * np.exp(-np.arange(m) / (m / 4))
        place(out, e, RNG.integers(0, n - m), RNG.uniform(0.6, 1.2))
    return loopify(out, 1.0)


def lava_rumble(seconds=30.0):
    """Lac de lave : grondement profond qui respire, gros bouillons sourds."""
    n = int(seconds * SR)
    out = lp(noise(n, "brown"), 120, 4) * 1.4 * smooth_env(n, 0.3, 0.5, 1.0)
    for _ in range(int(seconds * 2.0)):
        m = int(RNG.uniform(0.15, 0.4) * SR)
        x = np.arange(m) / SR
        f = RNG.uniform(60, 140)
        e = np.sin(2 * np.pi * np.cumsum(np.linspace(f, f * 1.8, m)) / SR) * np.sin(np.pi * np.linspace(0, 1, m))
        e += lp(noise(m), 400) * np.hanning(m) * 0.6
        place(out, e, RNG.integers(0, n - m), RNG.uniform(0.2, 0.6))
    return loopify(out, 2.0)


def fumarole(seconds=16.0):
    """Fumerolle : sifflement de vapeur qui pulse, petits crachotements."""
    n = int(seconds * SR)
    pulse = smooth_env(n, 0.8, 0.5, 1.0)
    out = bp(noise(n), 1800, 7000) * pulse * 0.6 + bp(noise(n, "pink"), 200, 900) * 0.3 * pulse
    for _ in range(int(seconds * 1.5)):
        m = int(0.08 * SR)
        e = bp(noise(m), 400, 1500) * np.hanning(m)
        place(out, e, RNG.integers(0, n - m), RNG.uniform(0.3, 0.7))
    return loopify(out, 1.5)


def waterfall_roar(seconds=20.0):
    """Cascade : grondement large bande de l'eau qui tombe."""
    n = int(seconds * SR)
    body = lp(noise(n, "pink"), 2500) * smooth_env(n, 1.2, 0.85, 1.0)
    low = lp(noise(n, "brown"), 150) * 0.8
    return loopify(body + low, 2.0)


def forge_hall(seconds=40.0):
    """Grande halle naine : rumeur de forge lointaine (souffle, feu, coups étouffés)."""
    n = int(seconds * SR)
    out = np.zeros((n, 2))
    base = lp(noise(n, "brown"), 200) * 0.6
    out[:, 0] += base
    out[:, 1] += np.roll(base, SR // 5)
    t = 0.5
    while t < seconds - 1:
        f = RNG.uniform(380, 520)
        e = bell(f, 1.2) * 0.5
        e = lp(e, 1800)
        place(out, e, int(t * SR), RNG.uniform(0.06, 0.14), RNG.uniform(-0.9, 0.9))
        t += RNG.choice([0.55, 0.6, 0.65, 1.8, 2.6])
    ir = np.exp(-np.arange(int(1.2 * SR)) / (0.35 * SR)) * RNG.standard_normal(int(1.2 * SR)) * 0.03
    out[:, 0] = out[:, 0] + np.convolve(out[:, 0], ir)[:n]
    out[:, 1] = out[:, 1] + np.convolve(out[:, 1], ir[::-1].copy())[:n]
    return loopify(out, 3.0)


# =================================================================== enregistrements CC0

def read_any(path: Path) -> np.ndarray:
    """Lit wav/ogg/mp3 via ffmpeg, rend un tableau (n, 2) flottant à 44,1 kHz."""
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(path), "-ac", "2", "-ar", str(SR), tmp.name], check=True)
        sr, d = wavfile.read(tmp.name)
    d = d.astype(np.float64)
    return d / (np.max(np.abs(d)) + 1e-9)


def recorded(src: Path) -> None:
    lib = src / "CC0-Public-Domain-Sounds"
    # Oiseaux de forêt (Sadiquecat, CC0) : 0 à 90 s (un bruit humain vers 94 s est écarté)
    x = read_any(src / "nature-forest-day.wav")[: 90 * SR]
    save("ambiance/oiseaux_foret", loopify(hp(x.T, 120).T, 3.0))
    # Brise (keweldog, CC0) : la partie sans coupure, de 2 à 30 s
    x = read_any(src / "wind-breeze.wav")[2 * SR: 30 * SR]
    save("ambiance/brise", loopify(x, 3.0))
    # Ruisseau (SamsterBirdies, CC0) et rivière (JW_Audio, CC0) : émetteurs en mono
    x = read_any(src / "water-stream.wav")[: 40 * SR].mean(axis=1)
    save("emetteurs/ruisseau", loopify(x, 2.0))
    x = read_any(src / "water-river.wav")[: 40 * SR].mean(axis=1)
    save("emetteurs/riviere", loopify(x, 2.0))
    # Bouillonnement (recueil CC0) ralenti : la lave qui bulle
    x = read_any(lib / "30-cc0-sfx-loops" / "water_boiling.ogg").mean(axis=1)
    slow = signal.resample(x, int(len(x) * 1.6))
    save("emetteurs/lave_bulles", loopify(lp(slow, 2500), 0.8))
    # Coups de marteau sur l'enclume (recueil CC0 « wood-metal »)
    wm = lib / "100-CC0-wood-metal-SFX"
    for k, name in enumerate(["metal_hit_01", "metal_hit_03", "hammer_02", "metal_hit_05"]):
        x = read_any(wm / f"{name}.ogg").mean(axis=1)
        save(f"ponctuels/enclume_{k + 1}", x[: int(1.5 * SR)])


def main() -> int:
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    save("ambiance/ressac", surf())
    save("ambiance/large", sea_open())
    save("ambiance/vent_volcan", wind_volcano())
    save("ambiance/jungle_insectes", cicadas())
    save("ambiance/grotte", cave_drone())
    save("ambiance/feerique", fairy_pad())
    save("ambiance/halle_forge", forge_hall())
    save("emetteurs/feu", fire_crackle())
    save("emetteurs/lave", lava_rumble())
    save("emetteurs/fumerolle", fumarole())
    save("emetteurs/cascade", waterfall_roar())
    for k in range(4):
        save(f"ponctuels/oiseau_jungle_{k + 1}", jungle_bird(k))
    for k in range(3):
        save(f"ponctuels/mouette_{k + 1}", gull(k))
    for k in range(4):
        save(f"ponctuels/goutte_{k + 1}", drip(k))
    for k, f in enumerate([1568.0, 2093.0, 2637.0]):
        save(f"ponctuels/carillon_{k + 1}", np.concatenate([bell(f, 2.5), np.zeros(SR // 2)]))
    if src is not None and src.exists():
        recorded(src)
    else:
        print("(enregistrements CC0 absents : seuls les sons synthétisés ont été refaits)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
