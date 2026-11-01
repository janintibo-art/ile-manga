"""V94 : la musique de Néopolis (composée ici, versée au domaine public, CC0 1.0).

  musique/neopolis.ogg   « Néopolis, la nuit » : une boucle de 32 mesures à 100 noires par minute, en
                         la mineur (la – fa – do – sol). Des nappes de synthétiseur un peu désaccordées,
                         un arpège en doubles croches qui rebondit d'une oreille à l'autre, une basse
                         qui pulse en croches, la batterie (VCSL, CC0) avec une caisse claire noyée de
                         réverbération, et, à partir de la mesure 16, une mélodie de synthé qui chante
                         au-dessus des tours. Tous les synthétiseurs sont calculés ici (dents de scie,
                         carrés, filtres), sans échantillon.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/compose_musique_v94.py [--vcsl /root/snd/VCSL]
"""
from __future__ import annotations

from pathlib import Path
import gc
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v75 as m75  # noqa: E402

SR = m75.SR
Song, drums = m75.Song, m75.drums
filt, bw, shelf, peak, room_ir, compress = m75.filt, m75.bw, m75.shelf, m75.peak, m75.room_ir, m75.compress
RNG = np.random.default_rng(9494)


def hz(m: float) -> float:
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def saw(f: float, n: int, ph: float = 0.0) -> np.ndarray:
    t = np.arange(n) / SR
    x = (t * f + ph) % 1.0
    # un peu d'adoucissement des arêtes (moins d'aliasing)
    return 2.0 * x - 1.0


def square(f: float, n: int, duty: float = 0.5) -> np.ndarray:
    t = np.arange(n) / SR
    return np.where((t * f) % 1.0 < duty, 1.0, -1.0)


def adsr(n: int, a: float, d: float, s: float, r: float, hold: float) -> np.ndarray:
    t = np.arange(n) / SR
    e = np.where(t < a, t / max(a, 1e-4), s + (1 - s) * np.exp(-(t - a) / max(d, 1e-4)))
    rel = np.clip((t - hold) / max(r, 1e-4), 0, 1)
    return e * (1 - rel) ** 2


def lpf(x: np.ndarray, f: float, order: int = 2) -> np.ndarray:
    return filt(x, bw("lowpass", min(f, SR * 0.45), order))


# =================================================================== les instruments

def pad(notes, dur: float) -> np.ndarray:
    """La nappe : sept dents de scie désaccordées par note, filtrées, une attaque lente."""
    n = int((dur + 1.5) * SR)
    y = np.zeros(n)
    for m in notes:
        for k in range(7):
            det = (k - 3) * 0.09
            y += saw(hz(m + det * 0.1) * (1 + det * 0.004), n, RNG.random()) * (0.8 if k != 3 else 1.0)
    y = lpf(y, 1500.0, 2) * adsr(n, 0.9, 1.0, 0.85, 1.4, dur)
    return y / (len(notes) * 7)


def pluck(m: float, dur: float, bright: float = 2600.0, duty: float = 0.5) -> np.ndarray:
    n = int((dur + 0.35) * SR)
    x = square(hz(m), n, duty) * 0.6 + saw(hz(m) * 1.003, n) * 0.4
    env = adsr(n, 0.003, 0.12, 0.25, 0.12, dur)
    # le filtre se ferme avec la note (un « pluck »)
    cut = np.exp(-np.arange(n) / SR / 0.09)
    lo = lpf(x, 600.0)
    hi = lpf(x, bright)
    return (lo * (1 - cut) + hi * cut) * env


def bass(m: float, dur: float) -> np.ndarray:
    n = int((dur + 0.08) * SR)
    x = saw(hz(m), n) * 0.7 + np.sin(2 * np.pi * hz(m - 12) * np.arange(n) / SR) * 0.8
    cut = np.exp(-np.arange(n) / SR / 0.08)
    y = lpf(x, 300.0) * (1 - cut) + lpf(x, 1400.0) * cut
    return y * adsr(n, 0.004, 0.15, 0.7, 0.05, dur)


def lead_note(m: float, dur: float) -> np.ndarray:
    n = int((dur + 0.4) * SR)
    t = np.arange(n) / SR
    vib = 1.0 + 0.006 * np.sin(2 * np.pi * 5.5 * t) * np.clip((t - 0.25) / 0.3, 0, 1)
    ph = np.cumsum(hz(m) * vib) / SR
    x = (2 * (ph % 1.0) - 1) * 0.55 + (2 * ((ph * 1.006) % 1.0) - 1) * 0.45
    x = lpf(x, 3200.0) + 0.25 * np.sin(2 * np.pi * ph)
    return x * adsr(n, 0.02, 0.3, 0.75, 0.3, dur)


def delay(S: Song, bus: str, x: np.ndarray, at: float, gain: float, pan: float, beats: float = 0.75, n: int = 4) -> None:
    S.add(bus, x, at, gain, pan)
    for k in range(1, n + 1):
        pk = -pan if k % 2 else pan
        if abs(pk) < 0.2:
            pk = 0.6 if k % 2 else -0.6
        S.add(bus + "_echo", lpf(x, 3000.0 - k * 400.0), at + k * beats * S.spb, gain * 0.42 ** k, pk)


# =================================================================== la partition

CHORDS = [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]]     # la m, fa, do, sol
ROOTS = [45, 41, 48, 43]
ARP = [[69, 72, 76, 81, 76, 72, 69, 72], [65, 69, 72, 77, 72, 69, 65, 69], [64, 67, 72, 76, 72, 67, 64, 67], [62, 67, 71, 74, 71, 67, 62, 67]]
# la mélodie : (note MIDI ou None, durée en temps), 8 mesures chacune
MEL_A = [(76, 1.5), (74, 0.5), (72, 1), (69, 1), (72, 2), (77, 1), (76, 1), (79, 1.5), (76, 0.5), (74, 1), (72, 1), (74, 4),
         (76, 1.5), (74, 0.5), (72, 1), (69, 1), (72, 2), (77, 1), (81, 1), (79, 2), (76, 1), (74, 1), (76, 4)]
MEL_B = [(81, 2), (79, 1), (77, 1), (76, 2), (72, 2), (77, 1.5), (76, 0.5), (74, 1), (72, 1), (71, 2), (67, 2),
         (69, 1.5), (72, 0.5), (76, 1), (79, 1), (77, 2), (76, 1), (74, 1), (72, 1), (71, 1), (72, 1), (74, 1), (76, 4)]
FOUR = {"k": "X...X...X...X...", "s": "....X.......X...", "h": "..x...x...x...x.", "p": "x.......x......."}
FOUR_B = {"k": "X...X...X...X.x.", "s": "....X.......X...", "h": "x.xxx.xxx.xxx.xx"}
INTRO = {"k": "X.......X.......", "h": "..x...x...x...x."}


def neopolis(kit) -> Song:
    S = Song("neopolis", 100, 32, loop=True, seed=944)
    for bar in range(32):
        c = bar % 4
        sec = bar // 8
        # la nappe (toujours), l'arpège (sauf la cassure des mesures 28-29)
        S.add("pad", pad(CHORDS[c], 4 * S.spb), S.t(bar), 0.55, 0.0, 1.0)
        if not (28 <= bar <= 29):
            for k in range(16):
                m = ARP[c][k % 8] + (12 if (sec == 3 and k % 4 == 3) else 0)
                delay(S, "arp", pluck(m, S.spb * 0.22, 2400.0 + 600.0 * np.sin(bar * 0.4)), S.t(bar, k * 0.25), 0.22, -0.35 if k % 2 else 0.35, 0.75, 3)
        # la basse : des croches, à partir de la mesure 8
        if bar >= 8 and not (28 <= bar <= 29):
            for k in range(8):
                m = ROOTS[c] + (12 if k in (3, 7) else 0)
                S.di("bass", bass(m, S.spb * 0.42), S.t(bar, k * 0.5), 0.8)
        # la batterie
        if bar < 8:
            if bar >= 4:
                drums(S, kit, bar, INTRO, 0.7)
        elif 28 <= bar <= 29:
            if bar == 29:
                drums(S, kit, bar, {"s": "........x.x.xxXX"}, 0.75)
        else:
            drums(S, kit, bar, FOUR_B if bar % 8 == 7 else FOUR, 0.85)
            if bar % 8 == 0:
                drums(S, kit, bar, {"c": "X..............."}, 0.7)
    # la mélodie : A (mesures 16 à 23), B (24 à 31 ; elle repart pendant la cassure)
    for start, mel in ((16, MEL_A), (24, MEL_B)):
        beat = 0.0
        for m, d in mel:
            if m is not None:
                delay(S, "lead", lead_note(m, d * S.spb * 0.92), S.t(start, beat), 0.32, 0.05, 0.75, 3)
            beat += d
    m75.drum_fx(S, hall=True)
    S.fx["dr_snare"] = lambda x: compress(filt(x, peak(4000, 3, 0.8), bw("highpass", 150)), -16, 3.0, 0.005, 0.1) * 2.2
    S.fx["bass"] = lambda x: compress(filt(x, bw("lowpass", 2500)), -18, 3.0, 0.006, 0.1)
    S.fx["pad"] = lambda x: filt(x, bw("highpass", 140), shelf(6000, -3))
    S.send.update({"pad": 0.35, "arp": 0.25, "arp_echo": 0.4, "lead": 0.3, "lead_echo": 0.45, "bass": 0.03, "dr_snare": 0.6})
    return S


def main() -> int:
    args = sys.argv[1:]
    while args:
        a = args.pop(0)
        if a == "--vcsl":
            m75.VCSL = Path(args.pop(0))
        elif a == "--vsco":
            m75.VSCO = Path(args.pop(0))
    kit = m75.Kit()
    S = neopolis(kit)
    ir = room_ir(2.6, 0.5, 0.02, 18, S.seed, 0.08)
    S.render(m75.OUT / "neopolis.ogg", -18.0, -2.0, ir, (-18.0, 2.0), None)
    m75.release_instruments()
    gc.collect()
    print("V94 : neopolis.ogg")
    return 0


if __name__ == "__main__":
    sys.exit(main())
