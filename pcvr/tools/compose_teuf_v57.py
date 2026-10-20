"""V57 : « Marée Basse », le morceau de la teuf sur la plage de l'île du village.

Composition originale pour Île Manga, versée au domaine public (CC0 1.0), entièrement
synthétisée ici (numpy) : une techno de free-party à 145 battements par minute, en mi
phrygien.
  - le kick : une sinusoïde qui plonge de 150 à 46 Hz, un petit clic d'attaque ;
  - la basse roulante : trois notes courtes entre chaque kick (« boum-ta-ta-ta ») ;
  - la ligne acide : une dent de scie dans un filtre résonant dont l'ouverture suit chaque
    note (accents, glissés) et une lente vague sur seize mesures ;
  - les charlestons (fermé à contretemps, ouvert entre les temps), le shaker, le clap ;
  - des accords « stab » et une nappe au milieu, quand le kick se tait et que la foule
    attend qu'il revienne.
Soixante-quatre mesures (~106 s) qui bouclent sans raccord : la sono les joue en continu.

Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/compose_teuf_v57.py
"""
from pathlib import Path
import subprocess
import tempfile

import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
BPM = 145.0
BEAT = 60.0 / BPM
BARS = 64
N = int(BARS * 4 * BEAT * SR)
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "sons" / "musique" / "teuf.ogg"
RNG = np.random.default_rng(5757)


def f_of(m: float) -> float:
    return 440.0 * 2 ** ((m - 69) / 12.0)


def at(bar: float, beat: float = 0.0) -> int:
    return int(((bar * 4) + beat) * BEAT * SR)


def place(buf: np.ndarray, x: np.ndarray, i: int, g: float = 1.0, pan: float = 0.0) -> None:
    """Ajoute x (mono) en i, en boucle (ce qui dépasse revient au début)."""
    l = np.sqrt(0.5 * (1 - pan)) * g
    r = np.sqrt(0.5 * (1 + pan)) * g
    n = len(x)
    i %= N
    end = min(N, i + n)
    buf[i:end, 0] += x[: end - i] * l
    buf[i:end, 1] += x[: end - i] * r
    if i + n > N:
        rest = i + n - N
        buf[:rest, 0] += x[end - i:] * l
        buf[:rest, 1] += x[end - i:] * r


# =================================================================== les sons

def kick() -> np.ndarray:
    n = int(0.42 * SR)
    t = np.arange(n) / SR
    f = 46.0 + 104.0 * np.exp(-t / 0.028)
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) * np.exp(-t / 0.2)
    x += 0.35 * np.sin(ph * 2) * np.exp(-t / 0.03)
    click = signal.lfilter(*signal.butter(2, 2500, "high", fs=SR), RNG.standard_normal(n)) * np.exp(-t / 0.003) * 0.4
    return np.tanh((x + click) * 1.8) * 0.95


def bass(m: float, length: float) -> np.ndarray:
    n = int(length * SR)
    t = np.arange(n) / SR
    f = f_of(m)
    ph = 2 * np.pi * f * t
    x = np.sin(ph) + 0.45 * np.sin(2 * ph) + 0.2 * np.sign(np.sin(ph)) * 0.5
    env = np.clip(t / 0.003, 0, 1) * np.exp(-t / 0.055)
    x = signal.lfilter(*signal.butter(2, 380, fs=SR), x * env)
    return np.tanh(x * 2.2) * 0.8


def hat(open_: bool) -> np.ndarray:
    n = int((0.28 if open_ else 0.05) * SR)
    t = np.arange(n) / SR
    x = RNG.standard_normal(n)
    # timbre métallique : six carrés désaccordés ajoutés au bruit
    for fq in (317, 435, 543, 627, 812, 1047):
        x += 0.35 * np.sign(np.sin(2 * np.pi * fq * 7.3 * t + RNG.uniform(0, 6)))
    x = signal.lfilter(*signal.butter(4, 7000, "high", fs=SR), x)
    return x * np.exp(-t / (0.09 if open_ else 0.012)) * 0.22


def clap() -> np.ndarray:
    n = int(0.3 * SR)
    t = np.arange(n) / SR
    x = signal.lfilter(*signal.butter(2, [900, 3200], "band", fs=SR), RNG.standard_normal(n))
    env = np.zeros(n)
    for d in (0.0, 0.011, 0.023):
        k = int(d * SR)
        env[k:] += np.exp(-(t[: n - k]) / 0.012)
    env += np.exp(-t / 0.09) * 0.5
    return x * env * 0.5


def shaker() -> np.ndarray:
    n = int(0.06 * SR)
    t = np.arange(n) / SR
    x = signal.lfilter(*signal.butter(2, 5000, "high", fs=SR), RNG.standard_normal(n))
    return x * np.sin(np.pi * t / t[-1]) * 0.08


def acid(m: float, length: float, cut0: float, accent: bool, glide_from: float | None) -> np.ndarray:
    """Une note de la ligne acide : dent de scie dans un passe-bas résonant qui se referme."""
    n = int(length * SR)
    t = np.arange(n) / SR
    f1 = f_of(m)
    if glide_from is not None:
        f0 = f_of(glide_from)
        f = f1 + (f0 - f1) * np.exp(-t / 0.03)
    else:
        f = np.full(n, f1)
    ph = np.cumsum(f) / SR
    saw = 2.0 * (ph % 1.0) - 1.0
    out = np.zeros(n)
    zi = None
    blocks = 10
    q = 7.5 if accent else 5.0
    for b in range(blocks):
        a = b * n // blocks
        e = (b + 1) * n // blocks
        tc = (a + e) / 2 / SR
        fc = min(cut0 * (1.0 + (2.4 if accent else 1.2) * np.exp(-tc / 0.06)), 9000.0)
        bb, aa = signal.iirpeak(fc, q, fs=SR)
        lb, la = signal.butter(2, fc, fs=SR)
        seg = saw[a:e]
        y1 = signal.lfilter(lb, la, seg)
        y2 = signal.lfilter(bb, aa, seg)
        out[a:e] = y1 + y2 * (0.9 if accent else 0.6)
    env = np.clip(t / 0.003, 0, 1) * np.clip((length - t) / 0.01, 0, 1)
    return np.tanh(out * env * (1.6 if accent else 1.1)) * 0.32


def stab(ms: list, length: float) -> np.ndarray:
    n = int(length * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for m in ms:
        for d in (-0.08, 0.0, 0.08):
            ph = np.cumsum(np.full(n, f_of(m + d))) / SR
            x += 2.0 * (ph % 1.0) - 1.0
    x = signal.lfilter(*signal.butter(2, 2200, fs=SR), x)
    return x * np.exp(-t / 0.12) * 0.09


def pad(ms: list, length: float) -> np.ndarray:
    n = int(length * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for m in ms:
        for d in (-0.1, 0.0, 0.1):
            ph = np.cumsum(np.full(n, f_of(m + d))) / SR
            x += 2.0 * (ph % 1.0) - 1.0
    x = signal.lfilter(*signal.butter(2, 900, fs=SR), x)
    env = np.clip(t / 1.5, 0, 1) * np.clip((length - t) / 1.5, 0, 1)
    return x * env * 0.05


def riser(length: float) -> np.ndarray:
    n = int(length * SR)
    t = np.arange(n) / SR
    x = RNG.standard_normal(n)
    out = np.zeros(n)
    zi = None
    for b in range(40):
        a = b * n // 40
        e = (b + 1) * n // 40
        fc = 300 + 7000 * (b / 40) ** 2
        bb, aa = signal.butter(2, [fc * 0.7, min(fc * 1.4, 20000)], "band", fs=SR)
        out[a:e] = signal.lfilter(bb, aa, x[a:e])
    return out * (t / t[-1]) ** 2 * 0.25


def reverb(x: np.ndarray, seconds: float, wet: float) -> np.ndarray:
    n = int(seconds * SR)
    t = np.arange(n) / SR
    out = np.zeros_like(x)
    for c in range(2):
        ir = RNG.standard_normal(n) * np.exp(-t / (seconds / 5))
        ir = signal.lfilter(*signal.butter(2, 4000, fs=SR), ir)
        ir /= np.sqrt(np.sum(ir ** 2))
        y = signal.fftconvolve(np.concatenate([x[-n:, c], x[:, c]]), ir)[n: n + N]
        out[:, c] = y
    return x + out * wet


# =================================================================== la partition

def main() -> None:
    drums = np.zeros((N, 2))
    low = np.zeros((N, 2))
    acid_b = np.zeros((N, 2))
    synth = np.zeros((N, 2))
    K = kick()
    H = hat(False)
    HO = hat(True)
    C = clap()
    S = shaker()
    E1 = 28 + 12          # mi 2 (basse)
    sixteenth = BEAT / 4
    breakdown = range(32, 40)
    for bar in range(BARS):
        has_kick = bar not in breakdown
        for beat in range(4):
            if has_kick:
                place(drums, K, at(bar, beat), 1.0)
                # basse roulante : trois doubles-croches après le kick
                if bar >= 8:
                    note = E1 + (0 if (bar // 4) % 4 != 3 else (1 if beat >= 2 else 0))
                    for k in (1, 2, 3):
                        place(low, bass(note, sixteenth * 0.9), at(bar, beat + k * 0.25), 0.8 if k == 1 else 0.65)
            # charlestons
            if bar >= 2 and has_kick:
                place(drums, H, at(bar, beat + 0.5), 0.9, 0.25)
            if bar >= 16 and has_kick:
                place(drums, HO, at(bar, beat + 0.5), 0.45, -0.2)
            if bar >= 4:
                for k in (0.25, 0.75):
                    place(drums, S, at(bar, beat + k), 0.7 + 0.3 * RNG.random(), 0.5)
            if (bar >= 40 and bar < 56 and beat in (1, 3)) or (bar >= 24 and bar < 32 and beat == 3):
                place(drums, C, at(bar, beat), 0.8, -0.1)
        # petits roulements de fin de phrase
        if has_kick and bar % 8 == 7 and bar >= 8:
            for k in range(4):
                place(drums, H, at(bar, 3 + k * 0.25), 0.5 + 0.12 * k, 0.4)
    # la ligne acide (mi phrygien : mi fa sol la si do ré)
    pattern = [(0, 1, 0), (12, 0, 1), (0, 0, 0), (13, 1, 0), (0, 0, 0), (10, 0, 1), (12, 1, 0), (0, 0, 0),
               (3, 0, 0), (0, 1, 0), (15, 0, 1), (12, 0, 0), (0, 0, 0), (7, 1, 0), (5, 0, 1), (12, 1, 0)]
    A0 = 40
    for bar in range(16, 60):
        sweep = 0.5 - 0.5 * np.cos(2 * np.pi * ((bar - 16) % 16) / 16)
        quiet = bar in breakdown
        cut = (280 + 1500 * sweep) * (0.6 if quiet else 1.0)
        prev = None
        for k in range(16):
            semi, acc, slide = pattern[k]
            if bar % 4 == 3 and k >= 12:
                semi = [15, 13, 12, 10][k - 12]
            m = A0 + semi
            x = acid(m, sixteenth * (1.0 if slide else 0.8), cut, bool(acc), prev if slide else None)
            place(acid_b, x, at(bar, k * 0.25), 0.55 if quiet else 1.0, 0.15 * np.sin(bar + k))
            prev = m
    # stabs et nappe
    chords = [[52, 55, 59], [53, 57, 60], [50, 53, 57], [52, 55, 59]]
    for bar in list(range(24, 32)) + list(range(40, 56)):
        ch = chords[(bar // 2) % 4]
        for b in (1.5, 3.5) if bar % 2 == 0 else (2.5,):
            place(synth, stab(ch, 0.35), at(bar, b), 0.9, -0.3 if b < 2 else 0.3)
    for i, bar in enumerate(range(32, 40, 2)):
        place(synth, pad([c + 12 for c in chords[i % 4]], 2 * 4 * BEAT + 1.5), at(bar), 1.0)
    place(synth, riser(4 * 4 * BEAT), at(36), 1.0)
    # le mix : la basse s'efface sous le kick (compression « pompante »)
    duck = np.ones(N)
    dn = int(0.18 * SR)
    curve = 1.0 - 0.7 * np.exp(-np.arange(dn) / SR / 0.06)
    for bar in range(BARS):
        if bar in breakdown:
            continue
        for beat in range(4):
            i = at(bar, beat)
            duck[i:i + dn] = np.minimum(duck[i:i + dn], curve[: max(0, min(dn, N - i))])
    mix = drums * 0.9 + low * duck[:, None] * 1.0 + acid_b * duck[:, None] * 0.75 + reverb(synth, 2.5, 0.6) * duck[:, None]
    mix = reverb(mix, 0.6, 0.08)
    mix = np.tanh(mix * 1.4) / np.tanh(1.4)
    rms = np.sqrt(np.mean(mix ** 2))
    mix *= 10 ** (-12.0 / 20) / (rms + 1e-9)
    mix = np.clip(mix, -0.98, 0.98)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        wavfile.write(tmp.name, SR, (mix * 32767).astype(np.int16))
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp.name, "-c:a", "libvorbis", "-q:a", "5", str(OUT)], check=True)
    print(f"teuf : {N / SR:.1f} s -> {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
