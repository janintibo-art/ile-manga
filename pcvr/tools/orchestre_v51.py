#!/usr/bin/env python3
"""V51 : un petit orchestre virtuel pour composer la musique d'Île Manga.

Les instruments sont de vrais enregistrements : la banque « Versilian Studios Chamber
Orchestra 2 Community Edition » (VSCO-2 CE, github.com/sgossner/VSCO-2-CE), placée dans le
domaine public (CC0 1.0). Ce module :
  - indexe les échantillons et mesure la hauteur réelle de chacun (les noms de fichiers ne
    suivent pas tous la même convention d'octave) ;
  - joue une note : choix de l'échantillon le plus proche et de la nuance, transposition,
    attaque, tenue (boucle en fondu si la note dépasse l'enregistrement), relâchement ;
  - place chaque pupitre dans l'espace stéréo et ajoute une réverbération de salle ;
  - rend un morceau qui boucle sans couture (la queue de réverbération est repliée au début).
"""
from __future__ import annotations

import math
import re
import warnings
from pathlib import Path

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, fftconvolve, sosfilt

warnings.filterwarnings("ignore", category=wavfile.WavFileWarning)

SR = 44100
NOTE_RE = re.compile(r"(?<![A-Za-z])([A-G])(#|b)?(-?\d)(?![\d])")
PC = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def midi_of(name: str) -> int:
    """'C#4' -> 61 ; accepte aussi les bémols ('Bb3')."""
    m = re.fullmatch(r"([A-G])(#|b)?(-?\d)", name)
    if not m:
        raise ValueError(name)
    n = PC[m.group(1)] + (1 if m.group(2) == "#" else -1 if m.group(2) == "b" else 0)
    return 12 * (int(m.group(3)) + 1) + n


def _read(path: Path) -> np.ndarray:
    sr, d = wavfile.read(path)
    if d.dtype == np.int16:
        x = d.astype(np.float32) / 32768.0
    elif d.dtype == np.int32:
        x = d.astype(np.float32) / 2147483648.0
    elif d.dtype == np.uint8:
        x = (d.astype(np.float32) - 128.0) / 128.0
    else:
        x = d.astype(np.float32)
    if x.ndim == 1:
        x = np.stack([x, x], axis=1)
    x = x[:, :2]
    if sr != SR:
        t = np.arange(int(len(x) * SR / sr)) * sr / SR
        x = np.stack([np.interp(t, np.arange(len(x)), x[:, c]) for c in range(2)], axis=1).astype(np.float32)
    return x


def _f0(x: np.ndarray, lo: float = 25.0, hi: float = 2200.0) -> float:
    """Fréquence fondamentale (autocorrélation normalisée façon YIN) sur la partie tenue."""
    m = x.mean(axis=1)
    start = int(0.25 * SR)
    seg = m[start:start + 8192] if len(m) > start + 8192 else m[-8192:]
    seg = seg - seg.mean()
    n = len(seg)
    if n < 2048 or np.max(np.abs(seg)) < 1e-4:
        return 0.0
    w = n // 2
    # fonction de différence cumulée normalisée (YIN)
    f = np.fft.rfft(seg, 2 * n)
    ac = np.fft.irfft(f * np.conj(f))[:w]
    e = np.cumsum(seg ** 2)
    energy0 = e[w - 1]
    tau = np.arange(w)
    energy_tau = e[np.minimum(w - 1 + tau, n - 1)] - np.concatenate([[0.0], e[:w - 1]])
    d = energy0 + energy_tau - 2 * ac
    d[0] = 1.0
    cm = d * tau / np.maximum(np.cumsum(d), 1e-12)
    cm[0] = 1.0
    tmin, tmax = int(SR / hi), min(int(SR / lo), w - 2)
    cand = np.where(cm[tmin:tmax] < 0.15)[0]
    if len(cand):
        t = cand[0] + tmin
        while t + 1 < tmax and cm[t + 1] < cm[t]:
            t += 1
    else:
        t = int(np.argmin(cm[tmin:tmax])) + tmin
    if 1 <= t < len(cm) - 1:
        a, b, c = cm[t - 1], cm[t], cm[t + 1]
        den = a - 2 * b + c
        t = t + (0.5 * (a - c) / den if abs(den) > 1e-12 else 0.0)
    return SR / t if t > 0 else 0.0


def _octave_score(x: np.ndarray, f: float) -> float:
    """Vraisemblance que f soit la fondamentale : énergie sur les harmoniques h·f moins
    énergie entre elles ((h+½)·f). Une octave trop haute tombe sur des harmoniques réelles
    aux demi-pas ; une octave trop basse ne trouve rien sur ses harmoniques impaires."""
    m = x.mean(axis=1)
    a = int(0.2 * SR)
    seg = m[a:a + 32768] if len(m) > a + 32768 else m[: 32768]
    seg = seg * np.hanning(len(seg))
    spec = np.abs(np.fft.rfft(seg, 65536)) + 1e-9
    freqs = np.fft.rfftfreq(65536, 1 / SR)
    logs = np.log(spec)

    def at(fr):
        if fr <= 20 or fr >= SR / 2 - 100:
            return None
        lo, hi = np.searchsorted(freqs, [fr * 0.985, fr * 1.015])
        return float(logs[lo:hi + 1].max()) if hi >= lo else None

    on = [v for v in (at(h * f) for h in range(1, 9)) if v is not None]
    off = [v for v in (at((h + 0.5) * f) for h in range(0, 8)) if v is not None]
    if not on or not off:
        return -1e9
    return float(np.mean(on) - np.mean(off))


class Sample:
    def __init__(self, data: np.ndarray, midi: float, layer: int):
        self.data = data
        self.midi = midi
        self.layer = layer
        # temps pour atteindre 30 % du niveau : l'attaque « perçue » de l'enregistrement
        a = np.abs(data[: int(1.5 * SR)]).max(axis=1)
        pk = a.max() if len(a) else 0.0
        self.a30 = float(np.argmax(a > pk * 0.3)) / SR if pk > 0 else 0.0


class Instrument:
    """Un pupitre : échantillons triés par hauteur et par nuance."""

    def __init__(self, name: str, root: Path, pattern: str, *, pitched: bool = True,
                 attack: float = 0.03, release: float = 0.35, sustain: bool = True,
                 gain: float = 1.0, pan: float = 0.0, width: float = 0.6, offset: float = 0.0,
                 lowcut: float = 0.0, layers: int | None = None, octave: int | None = None, base: float | None = None,
                 verbose: bool = False):
        self.name = name
        self.attack = attack
        self.release = release
        self.sustain = sustain
        self.gain = gain
        self.pan = pan
        self.width = width
        self.offset = offset
        self.pitched = pitched
        self.samples: list[Sample] = []
        self.octave = 0
        self._rr = 0
        files = sorted(root.glob(pattern))
        if not files:
            raise FileNotFoundError(f"{name}: aucun fichier {root / pattern}")
        raw = []
        for f in files:
            x = _read(f)
            if lowcut > 0:
                x = sosfilt(butter(2, lowcut, "highpass", fs=SR, output="sos"), x, axis=0).astype(np.float32)
            stem = f.stem
            lm = re.search(r"_(?:v|dyn)(\d)", stem) or re.search(r"_(pp|p|mp|mf|f|ff)(?:_|$)", stem)
            if lm and lm.group(1).isdigit():
                layer = int(lm.group(1))
            elif lm:
                layer = ["pp", "p", "mp", "mf", "f", "ff"].index(lm.group(1)) + 1
            else:
                layer = 1
            midi = 60.0
            named = None
            if pitched and base is not None:
                midi = float(base)
            elif pitched:
                nm = None
                for mm in NOTE_RE.finditer(stem.replace("_Sum", "")):
                    nm = mm
                named = midi_of(nm.group(1) + (nm.group(2) or "") + nm.group(3)) if nm else None
                det = None
                if named is not None:
                    cands = [named + 12 * k for k in range(-2, 4) if 16 <= named + 12 * k <= 108]
                    scores = {c: _octave_score(x, 440.0 * 2 ** ((c - 69) / 12)) for c in cands}
                    midi = float(max(scores, key=scores.get))
                    det = midi
                else:
                    f0 = _f0(x)
                    det = 69 + 12 * math.log2(f0 / 440.0) if f0 > 0 else None
                    midi = float(round(det)) if det is not None else 60.0
                if verbose:
                    print(f"  {name:14s} {stem:40s} nom={named} mesure={det and round(det, 2)} -> {midi}")
            raw.append((x, midi, layer, named))
        # Chaque banque suit une seule convention d'octave : on retient l'écart majoritaire
        # entre le nom et la mesure, et on l'applique à toutes les notes (corrige les erreurs
        # de mesure isolées).
        if pitched:
            diffs = [int(r[1] - r[3]) for r in raw if r[3] is not None]
            if diffs:
                off = max(set(diffs), key=diffs.count) if octave is None else octave
                raw = [(x, float(n + off) if n is not None else m, l, n) for x, m, l, n in raw]
                self.octave = off
        # numérotation des nuances 1..N (de la plus douce à la plus forte)
        lay = sorted({r[2] for r in raw})
        self.n_layers = len(lay)
        for x, midi, layer, _n in raw:
            # même volume pour toutes les notes d'une nuance (partie tenue, ou crête si son percussif)
            body = x[int(0.05 * SR):int(1.2 * SR)] if len(x) > int(1.2 * SR) else x
            ref = np.sqrt(np.mean(body ** 2)) if sustain else np.max(np.abs(x))
            li = lay.index(layer)
            target = (0.12 if sustain else 0.5) * (0.6 + 0.4 * (li / max(1, len(lay) - 1)))
            if ref > 1e-6:
                x = x * (target / ref)
            self.samples.append(Sample(x.astype(np.float32), midi, li))
        if layers is not None:
            self.n_layers = layers
        # avance à donner aux notes tenues pour que l'attaque tombe sur le temps
        self.lag = min(0.18, 0.5 * float(np.median([q.a30 for q in self.samples]))) if sustain else 0.0

    def pick(self, midi: float, vel: float) -> Sample:
        li = min(self.n_layers - 1, int(vel * self.n_layers - 1e-6)) if self.n_layers > 1 else 0
        cands = [s for s in self.samples if s.layer == li] or self.samples
        best_d = min(abs(s.midi - midi) for s in cands)
        near = [s for s in cands if abs(s.midi - midi) <= best_d + 0.01]
        self._rr += 1
        return near[self._rr % len(near)]

    def note(self, midi: float, dur: float, vel: float = 0.6, attack: float | None = None,
             release: float | None = None, legato: bool = False) -> np.ndarray:
        """Rend une note (stéréo) : dur = durée tenue en secondes, puis relâchement."""
        if self.pitched:
            s = self.pick(midi, vel)
        else:
            self._rr += 1
            li = min(self.n_layers - 1, int(vel * self.n_layers - 1e-6)) if self.n_layers > 1 else 0
            pool = [q for q in self.samples if q.layer == li] or self.samples
            s = pool[self._rr % len(pool)]
        ratio = 2 ** ((midi - s.midi) / 12.0) if self.pitched else 1.0
        att = self.attack if attack is None else attack
        rel = self.release if release is None else release
        src = s.data[int(self.offset * SR):] if self.offset > 0 else s.data
        if legato and self.sustain:
            # note liée : on entre dans l'enregistrement après son attaque
            src = s.data[max(0, int((s.a30 + 0.03) * SR)):]
        if not self.sustain:
            need = int(min(len(src) / ratio, (dur + rel) * SR))
        else:
            need = int((dur + rel) * SR)
        # longueur dans l'échantillon source
        src_need = int(need * ratio) + 2
        if src_need > len(src) and self.sustain:
            src = _loop_extend(src, src_need)
        src = src[:src_need]
        if ratio != 1.0:
            pos = np.arange(min(need, int((len(src) - 1) / ratio))) * ratio
            out = np.empty((len(pos), 2), np.float32)
            for c in range(2):
                out[:, c] = np.interp(pos, np.arange(len(src)), src[:, c])
        else:
            out = src[:need].copy()
        n = len(out)
        env = np.ones(n, np.float32)
        a = min(n, int(att * SR))
        if a > 1:
            env[:a] = np.sin(np.linspace(0, math.pi / 2, a)) ** 2
        r0 = int(dur * SR)
        if r0 < n:
            rl = n - r0
            env[r0:] *= np.cos(np.linspace(0, math.pi / 2, rl)) ** 1.5
        out *= env[:, None]
        # dynamique à l'intérieur d'une nuance
        layer_span = 1.0 / max(1, self.n_layers)
        frac = (vel % layer_span) / layer_span if self.n_layers > 1 else vel
        out *= (0.55 + 0.45 * frac) if self.n_layers > 1 else (0.25 + 0.75 * vel)
        return out


def _loop_extend(x: np.ndarray, need: int) -> np.ndarray:
    """Allonge une note tenue en bouclant sa partie centrale avec des fondus enchaînés."""
    n = len(x)
    a, b = int(n * 0.30), int(n * 0.85)
    if b - a < SR // 2:
        a, b = n // 4, n - n // 8
    seg = x[a:b]
    xf = min(int(0.35 * SR), len(seg) // 3)
    out = [x[:b - xf]]
    total = b - xf
    fade_in = np.sin(np.linspace(0, math.pi / 2, xf))[:, None] ** 2
    fade_out = 1.0 - fade_in
    tail = x[b - xf:b]
    while total < need:
        mix = tail * fade_out + seg[:xf] * fade_in
        out.append(mix)
        out.append(seg[xf:len(seg) - xf])
        tail = seg[len(seg) - xf:]
        total += len(seg) - xf
    out.append(tail)
    return np.concatenate(out, axis=0)


def panned(x: np.ndarray, pan: float, width: float) -> np.ndarray:
    """Place un son stéréo : pan -1 (gauche) .. +1 (droite), width 0 (mono) .. 1."""
    m = x.mean(axis=1)
    side = (x[:, 0] - x[:, 1]) * 0.5 * width
    l = m * math.cos((pan + 1) * math.pi / 4) * math.sqrt(2) + side
    r = m * math.sin((pan + 1) * math.pi / 4) * math.sqrt(2) - side
    return np.stack([l, r], axis=1)


def hall_ir(seconds: float = 2.8, predelay: float = 0.025, seed: int = 7, dark: float = 0.6) -> np.ndarray:
    """Réponse impulsionnelle d'une salle : bruit stéréo à décroissance exponentielle,
    de plus en plus sourd avec le temps (les aigus s'éteignent plus vite)."""
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    t = np.arange(n) / SR
    noise = rng.standard_normal((n, 2)).astype(np.float32)
    t60 = seconds * 0.85
    env = np.exp(-6.9 * t / t60)
    # deux bandes : graves longs, aigus courts
    low = sosfilt(butter(2, 1800, "lowpass", fs=SR, output="sos"), noise, axis=0)
    high = noise - low
    env_hi = np.exp(-6.9 * t / (t60 * (1.0 - 0.6 * dark)))
    ir = low * env[:, None] + high * env_hi[:, None] * 0.6
    # premières réflexions
    er = np.zeros_like(ir)
    for k in range(14):
        d = int(rng.uniform(0.008, 0.08) * SR)
        er[d, k % 2] += rng.uniform(0.25, 0.6) * (1 if k % 3 else -1)
    ir = ir * 0.25 + er
    fade = np.minimum(1.0, t / 0.012)[:, None]
    ir *= fade
    pre = np.zeros((int(predelay * SR), 2), np.float32)
    ir = np.concatenate([pre, ir], axis=0)
    ir /= np.sqrt(np.sum(ir ** 2) / 2)
    return ir.astype(np.float32)


class Mix:
    """Une piste stéréo de longueur fixe (un tour de boucle) ; tout ce qui dépasse la fin
    est replié au début pour que le morceau boucle sans couture."""

    def __init__(self, seconds: float, loop: bool = True):
        self.n = int(round(seconds * SR))
        self.loop = loop
        self.tail = int(6 * SR)
        self.buses: dict[str, np.ndarray] = {}

    def add(self, bus: str, x: np.ndarray, at: float, pan: float, width: float, gain: float = 1.0):
        if bus not in self.buses:
            self.buses[bus] = np.zeros((self.n + self.tail, 2), np.float32)
        b = self.buses[bus]
        i = int(round(at * SR))
        y = panned(x, pan, width) * gain
        j = min(len(b), i + len(y))
        if j > i:
            b[i:j] += y[:j - i]

    def render(self, wet: dict[str, float], ir: np.ndarray, master: float = 1.0) -> np.ndarray:
        dry = np.zeros((self.n + self.tail, 2), np.float32)
        send = np.zeros_like(dry)
        for k, b in self.buses.items():
            dry += b
            send += b * wet.get(k, 0.3)
        rev = np.stack([fftconvolve(send[:, c], ir[:, c])[: len(send)] for c in range(2)], axis=1)
        out = dry + rev
        # coupe-bas doux avant le repli : le filtre ne crée pas de saut à la couture
        out = sosfilt(butter(2, 30, "highpass", fs=SR, output="sos"), out, axis=0)
        if self.loop:
            body = out[: self.n].copy()
            rest = out[self.n:]
            k = 0
            while k < len(rest):
                m = min(self.n, len(rest) - k)
                body[:m] += rest[k:k + m]
                k += m
            out = body
        else:
            # fin naturelle : on garde la queue et on coupe le silence
            env = np.abs(out).max(axis=1)
            last = np.nonzero(env > env.max() * 1e-3)[0]
            out = out[: (last[-1] + 1) if len(last) else self.n]
            f = min(len(out), int(0.8 * SR))
            out[-f:] *= np.linspace(1, 0, f)[:, None] ** 2
        return master * out


def master_to(x: np.ndarray, rms_db: float = -20.0, peak_db: float = -1.5) -> np.ndarray:
    """Met au niveau (RMS cible) puis limite doucement les crêtes."""
    rms = np.sqrt(np.mean(x ** 2)) + 1e-12
    x = x * (10 ** (rms_db / 20) / rms)
    lim = 10 ** (peak_db / 20)
    # compresseur/limiteur très doux (tanh au-delà du seuil)
    over = np.abs(x) > lim * 0.7
    if over.any():
        k = lim * 0.7
        x = np.where(over, np.sign(x) * (k + (lim - k) * np.tanh((np.abs(x) - k) / (lim - k))), x)
    return x.astype(np.float32)


def write_wav(path: Path, x: np.ndarray):
    path.parent.mkdir(parents=True, exist_ok=True)
    wavfile.write(path, SR, (np.clip(x, -1, 1) * 32767).astype(np.int16))
