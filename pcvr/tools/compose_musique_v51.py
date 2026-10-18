#!/usr/bin/env python3
"""V51 : la musique d'Île Manga — compositions originales, style « orchestral fantasy doux ».

Chaque morceau est écrit ici sous forme de partition (accords, mélodies, motifs
d'accompagnement), puis joué par l'orchestre virtuel de orchestre_v51.py avec les vrais
instruments enregistrés de VSCO-2 CE (CC0). Les morceaux de zone bouclent sans couture ;
le thème de l'île revient dans plusieurs d'entre eux (leitmotiv D-F#-A-B).

    python3 pcvr/tools/compose_musique_v51.py <dossier VSCO-2-CE> [morceau ...]

Sortie : www/assets/sons/musique/<morceau>.ogg (Ogg Vorbis, stéréo 44,1 kHz).
Les compositions et les fichiers produits sont versés au domaine public (CC0).
"""
from __future__ import annotations

import itertools
import random
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from orchestre_v51 import SR, Instrument, Mix, hall_ir, master_to, midi_of, write_wav  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "sons" / "musique"
TMP = Path("/tmp/musique_v51")

# --------------------------------------------------------------------------- instruments
# (clé, motif de fichiers, options) ; pan : -1 gauche .. +1 droite (placement d'orchestre)
INSTR = {
    "vln": ("Strings/Violin Section/susVib/*.wav", dict(attack=0.12, release=0.9, pan=-0.45, width=0.7, gain=1.0)),
    "vln_trem": ("Strings/Violin Section/Trem/*.wav", dict(attack=0.2, release=0.8, pan=-0.4, width=0.7, gain=0.8)),
    "vln_pizz": ("Strings/Violin Section/Pizz/*.wav", dict(sustain=False, attack=0.002, release=0.3, pan=-0.45, gain=0.7)),
    "vln_spic": ("Strings/Violin Section/Spic/*.wav", dict(sustain=False, attack=0.002, release=0.12, pan=-0.45, gain=0.55)),
    "vla": ("Strings/Viola Section/susvib/*.wav", dict(attack=0.12, release=0.9, pan=0.15, width=0.6, gain=0.9)),
    "vla_pizz": ("Strings/Viola Section/pizz/*.wav", dict(sustain=False, attack=0.002, release=0.3, pan=0.15, gain=0.7)),
    "vla_spic": ("Strings/Viola Section/spic/*.wav", dict(sustain=False, attack=0.002, release=0.12, pan=0.15, gain=0.55)),
    "vc": ("Strings/Cello Section/susvib/*.wav", dict(attack=0.12, release=0.9, pan=0.4, width=0.6, gain=1.0)),
    "vc_pizz": ("Strings/Cello Section/pizzT/*.wav", dict(sustain=False, attack=0.002, release=0.4, pan=0.4, gain=0.8)),
    "vc_spic": ("Strings/Cello Section/spic/*.wav", dict(sustain=False, attack=0.002, release=0.12, pan=0.4, gain=0.6)),
    "vc_trem": ("Strings/Cello Section/trem/*.wav", dict(attack=0.2, release=0.8, pan=0.4, width=0.6, gain=0.8)),
    "cb": ("Strings/Solo Contrabass/SusVib/*.wav", dict(attack=0.15, release=0.9, pan=0.6, width=0.3, gain=0.9)),
    "cb_pizz": ("Strings/Solo Contrabass/Pizz/*.wav", dict(sustain=False, attack=0.002, release=0.5, pan=0.6, width=0.3, gain=0.8)),
    "solo_vln": ("Strings/Solo Violin/Arco Vib/*.wav", dict(attack=0.08, release=0.7, pan=-0.2, width=0.4, gain=0.9)),
    "harp": ("Strings/Harp/*.wav", dict(sustain=False, attack=0.002, release=1.5, pan=-0.6, width=0.5, gain=0.9)),
    "flute": ("Woodwinds/Flute/expvib/*.wav", dict(attack=0.06, release=0.5, pan=-0.15, width=0.4, gain=0.85)),
    "oboe": ("Woodwinds/Oboe/Vib/*.wav", dict(attack=0.05, release=0.45, pan=0.05, width=0.4, gain=0.8)),
    "clar": ("Woodwinds/Clarinet/susLong/*.wav", dict(attack=0.06, release=0.5, pan=0.2, width=0.4, gain=0.85)),
    "bsn": ("Woodwinds/Bassoon/vib/*.wav", dict(attack=0.06, release=0.5, pan=0.3, width=0.4, gain=0.8)),
    "horn": ("Brass/F Horn/sus/*.wav", dict(attack=0.08, release=0.7, pan=-0.25, width=0.6, gain=0.85)),
    "tbn": ("Brass/Tenor Trombone/sus/*.wav", dict(attack=0.06, release=0.6, pan=0.3, width=0.5, gain=0.75)),
    "tuba": ("Brass/Tuba/sus/*.wav", dict(attack=0.08, release=0.6, pan=0.45, width=0.4, gain=0.75)),
    "trp": ("Brass/Trumpet/susvib/*.wav", dict(attack=0.05, release=0.5, pan=0.1, width=0.4, gain=0.7)),
    "glock": ("Percussion/Glock/*.wav", dict(sustain=False, attack=0.001, release=1.5, pan=-0.1, width=0.4, gain=0.45)),
    "marimba": ("Percussion/Marimba/*.wav", dict(sustain=False, attack=0.001, release=0.8, pan=0.0, width=0.5, gain=0.6)),
    # timbales : hauteur mesurée (fondamentale ≈ Fa2), transposées vers la tonique / la quinte
    "timp": ("Percussion/Timpani/Timpani1_Hit_*.wav", dict(base=41.5, sustain=False, attack=0.001, release=1.5, pan=0.1, width=0.5, gain=0.8)),
    "timp_roll": ("Percussion/Timpani/Rolls/Timpani1_Roll_*.wav", dict(base=42.0, sustain=False, attack=0.3, release=1.0, pan=0.1, width=0.5, gain=0.7)),
    "anvil": ("Percussion/Anvil_Hit1_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=1.0, pan=0.35, width=0.3, gain=0.25)),
    "logdrum_lo": ("Percussion/LogDrumLo_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=0.5, pan=0.25, width=0.3, gain=0.45)),
    "logdrum_hi": ("Percussion/LogDrumHi_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=0.5, pan=-0.25, width=0.3, gain=0.4)),
    "shaker": ("Percussion/Tamb1-Shake_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=0.3, pan=0.5, width=0.3, gain=0.18)),
    "bdrum": ("Percussion/BDrumNewhit_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=1.0, pan=0.0, width=0.4, gain=0.6)),
    "snare": ("Percussion/Snare2-HitSN_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=0.4, pan=0.1, width=0.3, gain=0.3)),
    "cymbal": ("Percussion/susCymb1-cresc-*.wav", dict(pitched=False, sustain=False, attack=0.05, release=1.5, pan=0.0, width=0.8, gain=0.35)),
    "crash": ("Percussion/cymbal-crash1_mp_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=2.0, pan=0.0, width=0.8, gain=0.35)),
    "triangle": ("Percussion/Triangle3-Hit_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=1.5, pan=-0.5, width=0.3, gain=0.2)),
    "chimes": ("Percussion/BellTree_Stroke*.wav", dict(pitched=False, sustain=False, attack=0.001, release=2.0, pan=-0.3, width=0.9, gain=0.25)),
}
# réverbération (part envoyée dans la salle) par famille
WET = {"vln": 0.45, "vln_trem": 0.5, "vla": 0.45, "vc": 0.4, "cb": 0.35, "solo_vln": 0.5, "harp": 0.55,
       "flute": 0.5, "oboe": 0.45, "clar": 0.45, "bsn": 0.4, "horn": 0.55, "tbn": 0.5, "tuba": 0.4, "trp": 0.5,
       "glock": 0.6, "marimba": 0.4, "timp": 0.5, "timp_roll": 0.5, "anvil": 0.5, "chimes": 0.6,
       "cymbal": 0.6, "crash": 0.6, "triangle": 0.6}

_cache: dict[str, Instrument] = {}
VSCO = Path(".")


def I(key: str) -> Instrument:
    if key not in _cache:
        pat, opt = INSTR[key]
        _cache[key] = Instrument(key, VSCO, pat, **opt)
    return _cache[key]


# --------------------------------------------------------------------------- harmonie
QUAL = {"": [0, 4, 7], "m": [0, 3, 7], "7": [0, 4, 7, 10], "m7": [0, 3, 7, 10], "maj7": [0, 4, 7, 11],
        "sus4": [0, 5, 7], "sus2": [0, 2, 7], "add9": [0, 4, 7, 14], "6": [0, 4, 7, 9], "m6": [0, 3, 7, 9],
        "dim": [0, 3, 6], "m9": [0, 3, 7, 10, 14], "maj9": [0, 4, 7, 11, 14]}


def chord(sym: str) -> tuple[int, list[int], int]:
    """'F#m7/C#' -> (classe de la fondamentale, classes des notes, classe de la basse)."""
    bass = None
    if "/" in sym:
        sym, b = sym.split("/")
        bass = midi_of(b + "0") % 12
    root = sym[0]
    k = 1
    if len(sym) > 1 and sym[1] in "#b":
        root += sym[1]
        k = 2
    rp = midi_of(root + "0") % 12
    q = QUAL[sym[k:]]
    pcs = [(rp + i) % 12 for i in q]
    return rp, pcs, (bass if bass is not None else rp)


class Piece:
    """Une partition : tempo, mesure, et les notes posées dans un Mix."""

    def __init__(self, name: str, bpm: float, bars: int, beats: int = 4, loop: bool = True, seed: int = 1,
                 room: float = 2.8, extra: float = 0.0):
        self.name = name
        self.bpm = bpm
        self.beats = beats
        self.bars = bars
        self.spb = 60.0 / bpm
        self.mix = Mix(bars * beats * self.spb + extra, loop=loop)
        self.rng = random.Random(seed)
        self.room = room
        self._voices: dict[str, list[int]] = {}

    def t(self, bar: float, beat: float = 0.0) -> float:
        return (bar * self.beats + beat) * self.spb

    def note(self, key: str, midi: float, bar: float, beat: float, beats: float, vel: float = 0.5,
             human: bool = True, **kw):
        ins = I(key)
        at = self.t(bar, beat) - (0.0 if kw.get("legato") else ins.lag)
        if human:
            at += self.rng.uniform(-0.012, 0.012)
            vel = min(1.0, max(0.02, vel + self.rng.uniform(-0.04, 0.04)))
        at = max(0.0, at)
        x = ins.note(midi, beats * self.spb, vel, **kw)
        self.mix.add(key, x, at, ins.pan, ins.width, ins.gain)

    def hit(self, key: str, bar: float, beat: float, vel: float = 0.5, beats: float = 4.0, midi: float = 60):
        self.note(key, midi, bar, beat, beats, vel)

    # ---- mélodie : "D5:2 F#5:1 A5:1 | B5:1.5 ..." (r = silence)
    def melody(self, key: str, bar: float, text: str, vel: float = 0.55, octave: int = 0, legato: float = 0.06,
               swell: bool = True):
        beat = 0.0
        toks = [t.split(":") for t in text.replace("|", " ").split() if t]
        toks = [(p, float(d)) for p, d in toks]
        prev_end = None
        for i, (p, d) in enumerate(toks):
            if p != "r":
                m = midi_of(p) + 12 * octave
                # notes longues : un peu plus fort au cœur (phrasé)
                v = vel * (1.06 if (swell and d >= 2) else 1.0)
                tied = prev_end is not None and abs(prev_end - beat) < 1e-6
                nxt_tied = i + 1 < len(toks) and toks[i + 1][0] != "r"
                self.note(key, m, bar, beat - (0.03 / self.spb if tied else 0.0), d + legato / self.spb, v,
                          attack=0.07 if tied else None, legato=tied, release=0.16 if nxt_tied else None)
                prev_end = beat + d
            else:
                prev_end = None
            beat += d
        return beat / self.beats  # nombre de mesures

    # ---- accords posés par les cordes / vents : voix menées au plus près
    def _voicing(self, key: str, pcs: list[int], lo: int, hi: int, n: int) -> list[int]:
        cand = [m for m in range(lo, hi + 1) if m % 12 in pcs]
        prev = self._voices.get(key)
        best, best_s = None, 1e9
        for combo in itertools.combinations(cand, n):
            got = {m % 12 for m in combo}
            need = min(len(set(pcs)), n)
            if len(got) < need:
                continue
            if max(combo) - min(combo) > 19:
                continue
            s = sum(abs(a - b) for a, b in zip(combo, prev)) if prev else abs(sum(combo) / n - (lo + hi) / 2) * n
            s += self.rng.random() * 0.01
            if s < best_s:
                best, best_s = combo, s
        if best is None:
            best = tuple(sorted(cand)[:n])
        self._voices[key] = list(best)
        return list(best)

    def pad(self, key: str, prog: list[str], bar0: int, lo: int, hi: int, n: int = 3, vel: float = 0.35,
            per_bar: int | None = None):
        """prog : un symbole par mesure, ou 'Em A' = deux accords dans la mesure."""
        for i, cell in enumerate(prog):
            syms = cell.split()
            each = self.beats / len(syms)
            for j, s in enumerate(syms):
                _, pcs, _ = chord(s)
                for m in self._voicing(key, pcs, lo, hi, n):
                    self.note(key, m, bar0 + i, j * each, each + 0.15, vel, attack=0.25)

    def bass(self, key: str, prog: list[str], bar0: int, lo: int = 28, hi: int = 45, vel: float = 0.4,
             rhythm: list[tuple[float, float]] | None = None, fifth: bool = False):
        for i, cell in enumerate(prog):
            syms = cell.split()
            each = self.beats / len(syms)
            for j, s in enumerate(syms):
                _, _, b = chord(s)
                m = lo + ((b - lo) % 12)
                if m > hi:
                    m -= 12
                if rhythm is None:
                    self.note(key, m, bar0 + i, j * each, each + 0.1, vel, attack=0.15)
                else:
                    for k, (pos, d) in enumerate(rhythm):
                        if j * each <= pos < (j + 1) * each:
                            mm = m + (7 if (fifth and k % 2 == 1) else 0)
                            self.note(key, mm, bar0 + i, pos, d, vel)

    def arp(self, key: str, prog: list[str], bar0: int, lo: int, step: float = 0.5,
            pattern: list[int] | None = None, vel: float = 0.45, ring: float = 3.0, span: int = 2):
        """Arpège sur les notes de l'accord, de lo vers l'aigu (pattern = indices)."""
        for i, cell in enumerate(prog):
            syms = cell.split()
            each = self.beats / len(syms)
            for j, s in enumerate(syms):
                _, pcs, b = chord(s)
                tones = sorted({m for m in range(lo, lo + 12 * span + 1) if m % 12 in pcs})
                pat = pattern or list(range(len(tones))) + list(range(len(tones) - 2, 0, -1))
                k = 0
                pos = 0.0
                while pos < each - 1e-6:
                    idx = pat[k % len(pat)] % len(tones)
                    self.note(key, tones[idx], bar0 + i, j * each + pos, ring, vel * (1.1 if pos == 0 else 1.0))
                    pos += step
                    k += 1

    def chord_hits(self, key: str, prog: list[str], bar0: int, lo: int, hi: int, beats_at: list[float],
                   n: int = 3, vel: float = 0.4, dur: float = 0.9):
        for i, cell in enumerate(prog):
            syms = cell.split()
            each = self.beats / len(syms)
            for j, s in enumerate(syms):
                _, pcs, _ = chord(s)
                vs = self._voicing(key, pcs, lo, hi, n)
                for b in beats_at:
                    if j * each <= b < (j + 1) * each:
                        for m in vs:
                            self.note(key, m, bar0 + i, b, dur, vel)

    def sparkle(self, key: str, prog: list[str], bar0: int, lo: int, hi: int, prob: float = 0.35,
                vel: float = 0.4, step: float = 1.0):
        for i, cell in enumerate(prog):
            syms = cell.split()
            each = self.beats / len(syms)
            pos = 0.0
            while pos < self.beats - 1e-6:
                s = syms[min(len(syms) - 1, int(pos // each))]
                _, pcs, _ = chord(s)
                if self.rng.random() < prob:
                    tones = [m for m in range(lo, hi + 1) if m % 12 in pcs]
                    self.note(key, self.rng.choice(tones), bar0 + i, pos + self.rng.choice([0, 0, 0.5]), 2.0, vel)
                pos += step

    def render(self, out: Path, rms_db: float = -21.0):
        ir = hall_ir(self.room, dark=0.6)
        x = self.mix.render(WET, ir)
        x = master_to(x, rms_db=rms_db)
        wav = TMP / (self.name + ".wav")
        write_wav(wav, x)
        out.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "libvorbis", "-q:a", "4",
                        str(out)], check=True)
        print(f"  {self.name}: {len(x) / SR:.1f} s -> {out.relative_to(ROOT)}")


def rep(prog: list[str], n: int) -> list[str]:
    return prog * n


# =========================================================================== morceaux

def theme_ile():
    """Menu : le thème de l'île. Ré majeur, 76 à la noire. Harpe, flûte, cor, cordes."""
    P = Piece("theme_ile", 76, 32, seed=11, room=3.0)
    intro = ["D", "Gmaj7/D"]
    A = ["D", "Gmaj7", "Em7 A", "A", "D", "Bm", "G A", "D"]
    B = ["Bm", "G", "D", "A", "Bm", "G", "Em7", "Asus4 A"]
    coda = ["D", "Gmaj7", "Bm", "A", "Gmaj7", "Asus4"]
    prog = intro + A + B + A + coda
    melA = "D5:2 F#5:1 A5:1 | B5:1.5 A5:0.5 F#5:2 | G5:1 F#5:1 E5:1 D5:1 | E5:3 r:1 | D5:2 F#5:1 A5:1 | D6:1.5 C#6:0.5 B5:2 | A5:1 G5:1 F#5:1 E5:1 | D5:3 r:1"
    melB = "F#4:3 E4:1 | D4:2 B3:2 | A3:2 D4:1 F#4:1 | E4:4 | F#4:3 G4:1 | A4:2 B4:2 | G4:1.5 F#4:0.5 E4:1 G4:1 | A4:4"
    # harpe tout du long, plus discrète sous le cor
    P.arp("harp", prog, 0, 50, step=0.5, vel=0.42)
    # cordes
    P.pad("vla", prog, 0, 55, 69, 2, vel=0.28)
    P.pad("vln", prog[2:], 2, 62, 79, 2, vel=0.25)
    P.bass("vc", prog, 0, 38, 50, vel=0.32)
    P.bass("cb", prog[10:26], 10, 28, 40, vel=0.25)
    # A : flûte ; B : cor ; A' : violons (+ flûte à l'octave) ; coda : écho du motif
    P.melody("flute", 2, melA, vel=0.5)
    P.melody("horn", 10, melB, vel=0.48)
    P.pad("clar", B, 10, 57, 69, 1, vel=0.22)
    P.melody("vln", 18, melA, vel=0.5, octave=0)
    P.melody("flute", 18, melA, vel=0.35, octave=1)
    P.pad("horn", A, 18, 50, 62, 2, vel=0.22)
    P.melody("flute", 26, "D5:2 F#5:1 A5:1 | B5:4 | r:4 | r:4 | D5:2 F#5:1 A5:1 | A5:4", vel=0.38)
    P.melody("glock", 26, "r:4 | r:4 | F#6:2 D6:2 | E6:4 | r:4 | r:4", vel=0.35)
    P.hit("cymbal", 17, 0, 0.3)
    P.hit("timp_roll", 25, 0, 0.25, midi=45)
    return P


def village():
    """Le village : le thème devenu valse pastorale. Sol majeur, 3/4, 104."""
    P = Piece("village", 104, 48, beats=3, seed=21, room=2.4)
    A = ["G", "C", "G", "D", "G", "Em7", "D", "D", "C", "Em", "G/D", "D", "G", "Am", "D", "G"]
    B = ["Em", "C", "D", "Em", "C", "Em", "Am", "D", "Em", "Am", "C", "D", "C", "G", "D", "G"]
    prog = A + B + A
    melA = ("G4:2 B4:1 | D5:2 E5:1 | D5:1 B4:1 G4:1 | A4:3 | B4:2 C5:1 | D5:2 G5:1 | F#5:1 E5:1 D5:1 | D5:3 | "
            "E5:2 F#5:1 | G5:2 E5:1 | D5:1.5 C5:0.5 B4:1 | A4:3 | B4:2 D5:1 | C5:1 B4:1 A4:1 | B4:1.5 A4:0.5 F#4:1 | G4:3")
    melB = ("B5:3 | A5:1 G5:1 E5:1 | F#5:2 D5:1 | E5:3 | G5:2 F#5:1 | E5:1 D5:1 B4:1 | C5:1 D5:1 E5:1 | D5:3 | "
            "B5:3 | C6:1 B5:1 A5:1 | G5:2 E5:1 | F#5:3 | G5:2 A5:1 | B5:1 A5:1 G5:1 | F#5:1 E5:1 F#5:1 | G5:3")
    # « oum-pa-pa » : basse pizz sur 1, accords pizz sur 2 et 3
    P.bass("vc_pizz", prog, 0, 36, 50, vel=0.5, rhythm=[(0, 1.0)])
    P.bass("cb_pizz", prog, 0, 28, 40, vel=0.35, rhythm=[(0, 1.0)])
    P.chord_hits("vla_pizz", prog, 0, 55, 67, [1, 2], n=2, vel=0.35)
    P.chord_hits("vln_pizz", prog[16:32], 16, 62, 74, [1, 2], n=2, vel=0.3)
    P.arp("harp", prog, 0, 55, step=1.0, pattern=[0, 2, 4], vel=0.3)
    P.pad("vln", prog[16:], 16, 62, 76, 2, vel=0.2)
    P.pad("bsn", A, 0, 43, 55, 1, vel=0.25)
    P.melody("oboe", 0, melA, vel=0.5)
    P.melody("flute", 16, melB, vel=0.48)
    P.melody("clar", 32, melA, vel=0.48)
    P.melody("flute", 32, "D6:3 | E6:3 | D6:3 | C6:3 | B5:3 | B5:3 | A5:3 | F#5:3 | G5:3 | G5:3 | F#5:3 | F#5:3 | G5:3 | E5:3 | F#5:3 | G5:3", vel=0.3)
    for b in (0, 16, 32):
        P.hit("triangle", b, 0, 0.3)
    return P


def jungle():
    """La jungle : ostinato de marimba, tambours de bois, flûte grave. La mineur, 92."""
    P = Piece("jungle", 92, 32, seed=31, room=2.0)
    A = ["Am7", "Am7", "Fmaj7 G", "Am", "Am7", "Am7", "Fmaj7 G", "Am"]
    B = ["Dm7", "Em7", "Fmaj7", "Esus4 E", "Dm7", "Em7", "Fmaj7 G", "Am"]
    prog = A[:4] + A + B + A + A[:4]
    melA = "E5:3 D5:0.5 C5:0.5 | D5:2 A4:2 | C5:1.5 B4:0.5 A4:1 G4:1 | A4:4 | E5:3 G5:1 | A5:2 E5:2 | F5:1.5 E5:0.5 D5:1 C5:1 | B4:1 C5:1 A4:2"
    melB = "F4:2 A4:1 C5:1 | B4:2 G4:2 | A4:1 C5:1 E5:1 D5:1 | B4:2 G#4:2 | F4:2 A4:1 D5:1 | E5:2 B4:2 | C5:1 A4:1 B4:1 D5:1 | A4:4"
    P.arp("marimba", prog, 0, 57, step=0.5, pattern=[0, 2, 1, 3, 2, 4, 3, 1], vel=0.42, ring=1.0)
    for b in range(32):
        for beat, k, v in ((0, "logdrum_lo", 0.5), (1.5, "logdrum_lo", 0.35), (2, "logdrum_hi", 0.4),
                           (3.5, "logdrum_hi", 0.3), (3.75, "logdrum_hi", 0.22)):
            P.hit(k, b, beat, v, 1.0)
        for beat in (0.5, 1.5, 2.5, 3.5):
            P.hit("shaker", b, beat, 0.3, 0.5)
    P.bass("vc_pizz", prog, 0, 33, 45, vel=0.45, rhythm=[(0, 1.0), (2.5, 1.0)], fifth=True)
    P.pad("vla", prog[4:], 4, 52, 67, 2, vel=0.2)
    P.pad("vc", prog[4:], 4, 40, 52, 1, vel=0.2)
    P.melody("flute", 4, melA, vel=0.48, octave=-1 + 1)
    P.melody("clar", 12, melB, vel=0.45)
    P.melody("flute", 20, melA, vel=0.48)
    P.melody("oboe", 20, "r:4 | A4:4 | A4:2 B4:2 | C5:4 | r:4 | C5:4 | A4:2 B4:2 | E4:4", vel=0.32)
    return P


def elfes():
    """L'île des elfes : harpe en arpèges, violon solo, éclats de glockenspiel. Mi majeur lydien, 66."""
    P = Piece("elfes", 66, 24, seed=41, room=3.6)
    A = ["Emaj7", "F#/E", "C#m7", "Amaj7", "Emaj7", "F#/E", "G#m7", "Bsus4 B"]
    B = ["Amaj7", "B", "G#m7", "C#m7", "Amaj7", "B/A", "E/G#", "B"]
    prog = A + B + A
    melA = "B5:2 G#5:1 B5:1 | C#6:2 A#5:2 | G#5:1.5 F#5:0.5 E5:2 | C#5:4 | B5:2 E6:1 D#6:1 | C#6:2 A#5:1 F#5:1 | B5:2 G#5:1 D#5:1 | F#5:4"
    melB = "C#6:3 B5:1 | A5:2 F#5:2 | G#5:1 B5:1 D#6:1 B5:1 | C#6:4 | E6:3 C#6:1 | D#6:2 B5:2 | G#5:2 F#5:1 E5:1 | F#5:4"
    P.arp("harp", prog, 0, 52, step=0.5, pattern=[0, 2, 4, 6, 7, 6, 4, 2], vel=0.4, span=3)
    P.pad("vln", prog, 0, 68, 83, 3, vel=0.18)
    P.pad("vla", prog, 0, 56, 68, 2, vel=0.18)
    P.bass("vc", prog, 0, 40, 52, vel=0.2)
    P.melody("solo_vln", 0, melA, vel=0.45, octave=-1)
    P.melody("flute", 8, melB, vel=0.45)
    P.melody("solo_vln", 8, melB, vel=0.3, octave=-1)
    P.melody("flute", 16, melA, vel=0.42)
    P.melody("glock", 16, melA, vel=0.28)
    P.sparkle("glock", prog[:16], 0, 84, 96, prob=0.18, vel=0.25, step=2.0)
    for b in (0, 8, 16):
        P.hit("chimes", b, 0, 0.35)
    return P


def nains():
    """L'île des nains : choral de cuivres graves, timbales, une enclume au loin. Ré mineur, 80."""
    P = Piece("nains", 80, 28, seed=51, room=3.2)
    A = ["Dm", "C", "Bb", "C", "Dm", "F", "Gm", "A"]
    B = ["F", "C", "Dm", "Bb", "Gm", "Dm", "Bb", "A"]
    prog = ["Dm", "Dm"] + A + B + A + ["Dm", "A"]
    melA = "D4:2 F4:1 A4:1 | G4:2 E4:2 | F4:1 D4:1 Bb3:1 D4:1 | C4:3 r:1 | D4:2 F4:1 A4:1 | C5:2 A4:2 | Bb4:1 A4:1 G4:1 Bb4:1 | A4:3 r:1"
    melB = "A4:2 C5:2 | G4:2 E4:2 | F4:1 A4:1 D5:2 | D5:1 C5:1 Bb4:2 | G4:2 Bb4:1 D5:1 | F5:2 D5:1 A4:1 | Bb4:1.5 A4:0.5 G4:1 F4:1 | E4:2 C#4:2"
    P.bass("cb", prog, 0, 26, 38, vel=0.38)
    P.bass("vc", prog, 0, 38, 50, vel=0.36)
    P.pad("vla", prog, 0, 50, 62, 2, vel=0.25)
    P.pad("bsn", prog[2:], 2, 43, 55, 1, vel=0.28)
    P.pad("tbn", B, 10, 48, 60, 2, vel=0.3)
    P.bass("tuba", B + A, 10, 29, 41, vel=0.3)
    P.melody("horn", 2, melA, vel=0.5)
    P.melody("horn", 10, melB, vel=0.52)
    P.melody("vln", 10, melB, vel=0.32, octave=1)
    P.melody("tbn", 18, melA, vel=0.48)
    P.melody("horn", 18, melA, vel=0.42, octave=1)
    P.melody("vln", 18, "F5:4 | E5:4 | D5:4 | E5:4 | F5:4 | A5:4 | G5:4 | E5:4", vel=0.28)
    P.hit("timp_roll", 0, 0, 0.3, midi=38)
    for b in range(2, 26):
        _, _, r = chord(prog[b])
        P.hit("timp", b, 0, 0.32 if b % 2 == 0 else 0.22, 2.0, midi=38 + (r - 38) % 12 - (12 if (r - 38) % 12 > 7 else 0))
        if b % 4 == 0:
            P.hit("timp", b, 3, 0.2, 1.0, midi=45)
        if b % 2 == 1:
            P.hit("anvil", b, 2, 0.25, 1.0)
    return P


def large():
    """Au large : cordes amples, violoncelles chantants, houle de harpe. Fa majeur, 72."""
    P = Piece("large", 72, 24, seed=61, room=3.4)
    A = ["F", "Dm", "Bb", "C", "F", "Am", "Bb", "Csus4 C"]
    B = ["Dm", "Bb", "F", "C", "Dm", "Bb", "Gm7", "C"]
    prog = A + B + A
    melA = "C4:2 F4:1 G4:1 | A4:3 F4:1 | Bb4:2 A4:1 G4:1 | G4:4 | C4:2 F4:1 G4:1 | A4:2 C5:2 | D5:1 C5:1 Bb4:1 A4:1 | G4:4"
    melB = "D5:3 E5:1 | F5:2 D5:2 | C5:2 A4:1 C5:1 | G5:4 | F5:3 E5:1 | D5:2 F5:2 | E5:1 D5:1 C5:1 Bb4:1 | C5:4"
    P.arp("harp", prog, 0, 41, step=0.5, pattern=[0, 1, 2, 3, 4, 5, 4, 3], vel=0.32, span=3)
    P.pad("vln", prog, 0, 65, 81, 2, vel=0.22)
    P.pad("vla", prog, 0, 53, 67, 2, vel=0.22)
    P.bass("cb", prog, 0, 29, 41, vel=0.3)
    P.melody("vc", 0, melA, vel=0.52)
    P.melody("vln", 8, melB, vel=0.48)
    P.pad("horn", B, 8, 53, 65, 2, vel=0.25)
    P.melody("horn", 16, melA, vel=0.48, octave=1)
    P.melody("flute", 16, "A5:4 | F5:4 | D5:4 | E5:4 | A5:4 | C6:4 | Bb5:4 | G5:4", vel=0.3)
    P.bass("vc", B, 8, 41, 53, vel=0.3)
    for b in (0, 8, 16):
        P.hit("cymbal", b - 1 if b else 23, 1, 0.22)
    return P


def souterrain():
    """Souterrains : bourdon grave, clarinette dans l'ombre, gouttes de glockenspiel. Ré mineur, 60."""
    P = Piece("souterrain", 60, 20, seed=71, room=3.4)
    A = ["Dm", "Bb/D", "Gm/D", "A/D", "Dm", "Bb", "A", "Dm"]
    prog = A + A + ["Dm", "Bb/D", "Gm/D", "A/D"]
    mot = "r:2 A3:1 D4:1 | F4:3 E4:1 | D4:4 | C#4:4 | r:2 A3:1 D4:1 | G4:3 F4:1 | E4:2 D4:1 C#4:1 | D4:4"
    P.bass("cb", prog, 0, 26, 38, vel=0.3)
    P.pad("vc", prog, 0, 38, 50, 1, vel=0.22)
    P.pad("vla", prog, 0, 50, 62, 2, vel=0.15)
    P.pad("vln_trem", prog[8:], 8, 69, 81, 2, vel=0.12)
    P.melody("clar", 0, mot, vel=0.42, octave=0)
    P.melody("bsn", 8, mot, vel=0.4, octave=-1)
    P.melody("flute", 8, "A5:8 | r:8 | G5:4 | E5:4 | r:8", vel=0.25)
    for b in range(20):
        if P.rng.random() < 0.55:
            P.sparkle("glock", [prog[b]], b, 79, 91, prob=0.25, vel=0.2, step=2.0)
        if b % 4 == 0:
            P.note("harp", 38, b, 0, 4, 0.35)
    P.hit("timp_roll", 7, 2, 0.18, midi=38)
    P.hit("timp_roll", 15, 2, 0.18, midi=45)
    return P


def racines():
    """Royaume des Racines : valse des fées, glockenspiel et harpe. Si bémol lydien, 3/4, 84."""
    P = Piece("racines", 84, 32, beats=3, seed=81, room=3.6)
    A = ["Bbmaj7", "C/Bb", "Bbmaj7", "C/Bb", "Gm7", "Ebmaj7", "Cm7", "F"]
    B = ["Ebmaj7", "F", "Dm7", "Gm7", "Cm7", "F/A", "Bb", "Fsus4 F"]
    prog = A + B + A + B
    melA = "D6:2 F6:1 | E6:2 C6:1 | D6:1 A5:1 F5:1 | G5:3 | Bb5:2 D6:1 | G6:2 Eb6:1 | D6:1 C6:1 Bb5:1 | A5:3"
    melB = "G5:2 Bb5:1 | C6:2 A5:1 | F5:1 A5:1 C6:1 | D6:3 | Eb6:2 C6:1 | A5:2 F5:1 | D5:1 F5:1 Bb5:1 | A5:2 C6:1"
    P.arp("harp", prog, 0, 58, step=0.5, pattern=[0, 2, 4, 5, 4, 2], vel=0.32, span=2)
    P.bass("vc_pizz", prog, 0, 34, 46, vel=0.4, rhythm=[(0, 1.0)])
    P.chord_hits("vln_pizz", prog, 0, 65, 77, [1, 2], n=2, vel=0.25)
    P.pad("vln", prog, 0, 70, 84, 2, vel=0.14)
    P.melody("glock", 0, melA, vel=0.35, octave=0)
    P.melody("flute", 8, melB, vel=0.42)
    P.melody("flute", 16, melA, vel=0.42, octave=-1)
    P.melody("glock", 16, melA, vel=0.25)
    P.melody("solo_vln", 24, melB, vel=0.4, octave=-1)
    for b in (0, 8, 16, 24):
        P.hit("chimes", b, 0, 0.3)
    return P


def combat():
    """Combat : ostinato de cordes, cors, timbales. Ré mineur, 138."""
    P = Piece("combat", 138, 32, seed=91, room=2.4)
    A = ["Dm", "Dm", "Bb", "C", "Dm", "Dm", "Gm", "A"]
    B = ["Bb", "C", "Am", "Dm", "Bb", "C", "E7", "A"]
    prog = A + A + B + A
    melA = "A4:3 D5:1 | C5:2 A4:2 | Bb4:1.5 A4:0.5 G4:1 F4:1 | E4:4 | A4:3 D5:1 | F5:2 E5:1 D5:1 | Bb4:2 D5:2 | C#5:4"
    melB = "F5:2 G5:2 | A5:2 E5:2 | C6:2 B5:1 A5:1 | D6:4 | Bb5:2 A5:2 | G5:2 C6:2 | B5:2 G#5:2 | A5:4"
    # ostinato en croches : fondamentale, octave, quinte
    for i, s in enumerate(prog):
        _, _, b = chord(s)
        root = 38 + ((b - 38) % 12)
        for k, off in enumerate([0, 0, 12, 0, 7, 0, 12, 7]):
            P.note("vc_spic", root + off, i, k * 0.5, 0.45, 0.55 if k % 2 == 0 else 0.42)
            P.note("vla_spic", root + 12 + off, i, k * 0.5, 0.45, 0.4)
    P.bass("cb", prog, 0, 26, 38, vel=0.4)
    P.pad("vln", prog[:16], 0, 62, 74, 2, vel=0.25)
    P.pad("vln_trem", B, 16, 69, 81, 2, vel=0.25)
    P.melody("horn", 0, melA, vel=0.6)
    P.melody("horn", 8, melA, vel=0.65)
    P.melody("tbn", 8, melA, vel=0.45, octave=-1)
    P.melody("vln", 16, melB, vel=0.5)
    P.melody("flute", 16, melB, vel=0.35)
    P.melody("horn", 24, melA, vel=0.65)
    P.melody("trp", 24, melA, vel=0.35, octave=0)
    for b in range(32):
        _, _, r = chord(prog[b])
        low = 38 + (r - 38) % 12 - (12 if (r - 38) % 12 > 7 else 0)
        P.hit("timp", b, 0, 0.5, 1.0, midi=low)
        P.hit("timp", b, 2, 0.38, 1.0, midi=low + 7 if low + 7 <= 47 else low - 5)
        if b % 2 == 1:
            P.hit("timp", b, 3.5, 0.3, 0.5, midi=low)
        if b % 8 == 7:
            P.hit("snare", b, 3, 0.3, 0.5)
            P.hit("snare", b, 3.5, 0.35, 0.5)
        if b % 8 == 0:
            P.hit("crash", b, 0, 0.3)
            P.hit("bdrum", b, 0, 0.45)
    return P


def victoire():
    """Jingle : boss vaincu, grande quête accomplie. Ré majeur."""
    P = Piece("victoire", 100, 3, loop=False, seed=101, room=3.0, extra=3.0)
    P.melody("horn", 0, "A3:0.5 D4:0.5 F#4:0.5 A4:2.5 | B4:1 C#5:1 D5:2", vel=0.65)
    P.melody("trp", 0, "A4:0.5 D5:0.5 F#5:0.5 A5:2.5 | G5:1 E5:1 F#5:2", vel=0.4)
    P.pad("vln_trem", ["D", "G A", "D"], 0, 66, 81, 3, vel=0.4)
    P.pad("vla", ["D", "G A", "D"], 0, 54, 66, 2, vel=0.4)
    P.bass("cb", ["D", "G A", "D"], 0, 26, 38, vel=0.45)
    P.bass("vc", ["D", "G A", "D"], 0, 38, 50, vel=0.45)
    P.arp("harp", ["D"], 0, 50, step=0.125, pattern=list(range(9)), vel=0.4, ring=3.0, span=3)
    P.arp("harp", ["D"], 2, 62, step=0.25, pattern=[0, 2, 4, 6], vel=0.35, ring=4.0, span=2)
    P.hit("timp_roll", 0, 0, 0.35, 3.0, midi=45)
    P.hit("crash", 2, 0, 0.35)
    P.hit("timp", 2, 0, 0.5, midi=38)
    P.hit("triangle", 2, 0, 0.35)
    return P


def decouverte():
    """Jingle : un passage s'ouvre, un trésor, une île nouvelle. Mi majeur, doux."""
    P = Piece("decouverte", 72, 2, loop=False, seed=111, room=3.6, extra=3.0)
    P.arp("harp", ["Emaj7"], 0, 52, step=0.125, pattern=list(range(12)), vel=0.4, ring=4.0, span=3)
    P.pad("vln", ["Emaj7", "Emaj7"], 0, 68, 83, 3, vel=0.28)
    P.pad("vla", ["Emaj7", "Emaj7"], 0, 56, 68, 2, vel=0.25)
    P.bass("vc", ["E", "E"], 0, 40, 52, vel=0.28)
    P.melody("glock", 0, "r:1.5 B5:0.5 E6:0.5 G#6:1.5 | D#6:4", vel=0.4)
    P.melody("flute", 0, "r:2 B5:2 | D#6:4", vel=0.35)
    P.hit("chimes", 0, 0, 0.4)
    return P


PIECES = {f.__name__: f for f in (theme_ile, village, jungle, elfes, nains, large, souterrain, racines,
                                   combat, victoire, decouverte)}


def main():
    global VSCO
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    VSCO = Path(sys.argv[1])
    TMP.mkdir(parents=True, exist_ok=True)
    names = sys.argv[2:] or list(PIECES)
    for n in names:
        P = PIECES[n]()
        P.render(OUT / f"{n}.ogg", rms_db=-23.0 if n in ("souterrain", "elfes", "racines") else -21.0)


if __name__ == "__main__":
    main()
