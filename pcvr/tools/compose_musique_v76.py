"""V76 : les musiques d'Astralys, l'île flottante des Lumens (la cité de cristal et de lumière, la Nuit
des Aurores, le Jardin des Apesanteurs), du vol en aéronef, du chantier naval de Port-Azur, et la petite
ritournelle des compagnons animaux.

Compositions originales pour « Les Mondes de Travers », versées au domaine public (CC0 1.0). Elles sont
jouées avec les outils de la V75 (compose_musique_v75.py : le morceau, ses bus, la salle, le mastering,
les boucles sans raccord) et de la V70 (compose_musique_v70.py : le chœur synthétisé, les anches
« musette » et l'accordéon de la main gauche), par :
  - l'orchestre VSCO-2 CE (Versilian Studios, CC0) : harpe, glockenspiel, marimba, xylophone, cordes
    (tenues, trémolos, pizzicati, spiccato), flûte, hautbois, clarinette, basson, cors, trompette,
    trombone, tuba, timbales ;
  - la « Versilian Community Sample Library » (VCSL, Versilian Studios, CC0 1.0) : verres frottés
    (l'harmonica de verre), carillons à main, arbres à clochettes, l'harmonica chromatique (joué à
    trois anches par note : l'accordéon musette), tambourin, bloc de bois, cymbales, toms, grosse caisse ;
  - et des instruments synthétisés ici : le célesta, le THÉRÉMINE de Vibrato (une onde presque pure,
    glissée d'une note à l'autre, avec son vibrato de main), les nappes, le voile des aurores (des
    sinus très aigus qui ondulent et voyagent d'une oreille à l'autre), les scintillements, la basse
    « rebond » du Jardin des Apesanteurs, le chœur doux (voix synthétiques à formants, V70).

Les morceaux (www/assets/sons/musique/, OGG stéréo 44,1 kHz) :
  astralys.ogg       « Astralys, la Cité de Lumière » : ré majeur (avec le sol dièse lydien), 76 à la
                     noire, en boucle (38 mesures, 2 min). La harpe qui égrène, le célesta et le
                     glockenspiel chantent l'air ; la flûte le reprend, les violons en contre-chant ;
                     les violons et le chœur doux ; un passage plus étrange (si bémol et do : les
                     accords venus d'ailleurs) où le thérémine de Vibrato chante tout bas, avec les
                     verres frottés ; la clarinette ramène la boucle.
  astralys_nuit.ogg  « La Nuit des Aurores » : la majeur, 60 à la noire, en boucle (30 mesures, 2 min).
                     Les nappes, le voile des aurores, les verres, le célesta en écho, le thérémine
                     qui plane, le chœur doux, la harpe, des étoiles qui scintillent.
  apesanteur.ogg     « Le Jardin des Apesanteurs » : fa majeur, 104, en boucle (52 mesures, 2 min) :
                     pizzicati qui rebondissent, xylophone et clarinette staccato, flûte, basson et
                     marimba (en ré mineur), un moment où tout flotte (harpe, célesta, « wiii » du
                     thérémine), puis tout le monde.
  ciel_libre.ogg     « Ciel Libre », le vol en aéronef : sol majeur, 92, en boucle (46 mesures, 2 min) :
                     les cordes qui courent, les cors chantent le thème, les violons, les flûtes, un
                     grand élan (mi bémol, fa : on monte encore), trompette, chœur, timbales, puis on
                     plane (le hautbois, la harpe).
  chantier.ogg       « Le Chantier Naval » : chanson de marins en 6/8, ré majeur, 72 à la noire
                     pointée, en boucle (72 mesures, 2 min) : l'accordéon musette et sa main gauche,
                     le tuba « oum-pa-pa », la trompette et le trombone, la clarinette en si mineur, le
                     tambourin, les marteaux du chantier (enclume) et les « Ho ! » des charpentiers.
  compagnons.ogg     « Un Ami pour la Vie » : la ritournelle d'adoption (fa majeur, 88, 6 mesures,
                     ~19 s, NON bouclée) : célesta, harpe, pizzicati, clarinette, cordes douces, et le
                     glockenspiel qui scintille sur l'accord final.

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/compose_musique_v76.py [--vsco <VSCO-2-CE>] [--vcsl <VCSL>] [--cc0 <CC0-…>] [morceaux…]
(par défaut, les banques sont cherchées dans /root/snd)
"""
from __future__ import annotations

from pathlib import Path
import gc
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v75 as m75  # noqa: E402
import compose_musique_v70 as cm70  # noqa: E402
import compose_musique_v51 as cm51  # noqa: E402
import orchestre_v51 as orch  # noqa: E402

SR = m75.SR
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "sons" / "musique"
SND = Path("/root/snd")
VSCO = SND / "VSCO-2-CE"
VCSL = SND / "VCSL"
CC0 = SND / "CC0-Public-Domain-Sounds"

midi_of, hz, filt, bw, peak, shelf = m75.midi_of, m75.hz, m75.filt, m75.bw, m75.peak, m75.shelf
lp, hp, bp, pan2, echo = m75.lp, m75.hp, m75.bp, m75.pan2, m75.echo
Song, play, melody, celesta, pad, twinkle = m75.Song, m75.play, m75.melody, m75.celesta, m75.pad, m75.twinkle

# =========================================================================== les pupitres

EXTRA = {   # pupitres de VSCO-2 CE qui manquaient aux listes des versions précédentes
    "clar_v": ("Woodwinds/Clarinet/susLong/*.wav", dict(attack=0.06, release=0.5, pan=0.2, width=0.4, gain=0.85)),
    "oboe_v": ("Woodwinds/Oboe/Vib/*.wav", dict(attack=0.05, release=0.45, pan=0.05, width=0.4, gain=0.8)),
    "flute_stac": ("Woodwinds/Flute/stac/*.wav", dict(sustain=False, attack=0.002, release=0.2, pan=-0.15, width=0.4, gain=0.8)),
    "picc": ("Woodwinds/Piccolo/Sus/*.wav", dict(attack=0.04, release=0.4, pan=-0.2, width=0.3, gain=0.55)),
    "horn_stac": ("Brass/F Horn/stac/*.wav", dict(sustain=False, attack=0.002, release=0.25, pan=-0.3, width=0.5, gain=0.8)),
    "vln_spic": ("Strings/Violin Section/Spic/*.wav", dict(sustain=False, attack=0.002, release=0.12, pan=-0.45, width=0.5, gain=0.6)),
    "vla_pizz": ("Strings/Viola Section/pizz/*.wav", dict(sustain=False, attack=0.002, release=0.3, pan=0.15, width=0.4, gain=0.7)),
    "timp_roll": ("Percussion/Timpani/Rolls/Timpani1_Roll_*.wav", dict(base=42.0, sustain=False, attack=0.3, release=1.0, pan=0.1, width=0.5, gain=0.7)),
}
_INS: dict = {}


def instrument(key: str):
    """Un pupitre (mis en cache le temps d'un morceau) : VSCO-2 CE, VCSL ou synthétisé (V70)."""
    if key not in _INS:
        if key in EXTRA:
            pat, opt = EXTRA[key]
            _INS[key] = orch.Instrument(key, VSCO, pat, **opt)
        elif key in m75.SAMPLED:
            pat, opt = m75.SAMPLED[key]
            _INS[key] = orch.Instrument(key, VSCO, pat, **opt)
        elif key in cm70.SYNTH or key in cm70.VCSL_INSTR:
            ins = cm70.instrument(key)
            if hasattr(ins, "rng"):            # (l'accordéon de la V56 tirait sa graine de hash() : on la fixe)
                ins.rng = np.random.default_rng(76000 + sum(map(ord, key)))
            _INS[key] = ins
        else:
            pat, opt = cm51.INSTR[key]
            _INS[key] = orch.Instrument(key, VSCO, pat, **opt)
    return _INS[key]


def release_instruments() -> None:
    _INS.clear()
    gc.collect()


m75.instrument = instrument        # play() et melody() de la V75 jouent nos pupitres (rien n'est modifié dans son fichier)


# =========================================================================== synthèses nouvelles

def theremin(S: Song, bus: str, bar0: int, text: str, vel: float = 0.5, octave: int = 0, glide: float = 0.07,
             vib: float = 0.22, rate: float = 5.7, pan: float = 0.15, seed: int = 1) -> None:
    """Le thérémine : une onde presque pure (un peu de deuxième et troisième harmonique), qui glisse
    d'une note à l'autre (portamento), avec le vibrato de la main qui vient après l'attaque ; entre
    deux phrases la main s'écarte de l'antenne de volume (le son s'éteint en douceur)."""
    rng = np.random.default_rng(seed)
    ev = []
    for bi, b in enumerate(text.split("|")):
        beat = 0.0
        for tok in b.split():
            p, d = tok.split(":")
            ev.append((S.t(bar0 + bi, beat), p, float(d) * S.spb))
            beat += float(d)
    t0 = ev[0][0]
    t_end = ev[-1][0] + ev[-1][2]
    n = int((t_end - t0 + 1.2) * SR)
    semis = np.full(n, np.nan)
    amp = np.zeros(n)
    onset = np.zeros(n)
    for t, p, d in ev:
        a, e = int((t - t0) * SR), min(n, int((t - t0 + d) * SR))
        if p == "r":
            continue
        semis[a:e] = midi_of(p.lstrip(">~")) + 12 * octave
        amp[a:e] = 1.0
        onset[a:e] = (np.arange(e - a) / SR)
    # les trous (silences) : la hauteur reste où elle était
    idx = np.where(~np.isnan(semis), np.arange(n), 0)
    np.maximum.accumulate(idx, out=idx)
    semis = semis[idx]
    semis[np.isnan(semis)] = np.nanmean(semis)
    from scipy import signal as sg
    a1 = np.exp(-1.0 / (glide * SR))
    semis = sg.lfilter([1 - a1], [1, -a1], semis, zi=[semis[0] * a1])[0]
    a2 = np.exp(-1.0 / (0.09 * SR))
    amp = sg.lfilter([1 - a2], [1, -a2], amp)
    x = np.arange(n) / SR
    depth = vib * np.clip((onset - 0.18) / 0.35, 0, 1) * (0.8 + 0.2 * np.sin(2 * np.pi * 0.31 * x))
    f = hz(semis + depth * np.sin(2 * np.pi * rate * x + rng.uniform(0, 6)))
    ph = 2 * np.pi * np.cumsum(f) / SR
    y = np.sin(ph) + 0.16 * np.sin(2 * ph + 0.4) + 0.05 * np.sin(3 * ph + 1.1)
    y = np.tanh(1.3 * y) / np.tanh(1.3)
    y = y * amp * vel * 0.22
    S.add(bus, y.astype(np.float32), t0, 1.0, pan)


def aurore(S: Song, bus: str, bar: float, beats: float, notes, vel: float = 0.5, seed: int = 1) -> None:
    """Le voile des aurores : pour chaque note (très aiguë), trois sinus à peine désaccordés dont le
    volume ondule lentement, et qui voyagent d'une oreille à l'autre."""
    rng = np.random.default_rng(seed)
    dur = beats * S.spb
    n = int((dur + 3.0) * SR)
    x = np.arange(n) / SR
    out = np.zeros((n, 2))
    for m in notes:
        for k in range(3):
            f = hz(m + rng.normal(0, 0.06))
            w = 0.5 + 0.5 * np.sin(2 * np.pi * rng.uniform(0.07, 0.2) * x + rng.uniform(0, 6))
            y = np.sin(2 * np.pi * f * x + rng.uniform(0, 6)) * w ** 2
            p = np.sin(2 * np.pi * rng.uniform(0.03, 0.09) * x + rng.uniform(0, 6)) * 0.85
            out[:, 0] += y * np.cos((p + 1) * np.pi / 4)
            out[:, 1] += y * np.sin((p + 1) * np.pi / 4)
    env = np.clip(x / 2.5, 0, 1) ** 2 * np.clip((dur + 3.0 - x) / 3.0, 0, 1)
    out *= env[:, None] * vel * 0.03 / max(1, len(notes)) ** 0.5
    S.add(bus, out.astype(np.float32), S.t(bar) - 1.0, 1.0)


def bloop(m: float, dur: float, vel: float = 0.7) -> np.ndarray:
    """La basse « rebond » du Jardin des Apesanteurs : une note ronde qui tombe dans sa hauteur
    (comme une balle qui touche le sol), un peu de deuxième harmonique."""
    n = int((dur + 0.3) * SR)
    x = np.arange(n) / SR
    f = hz(m) * (1 + 0.45 * np.exp(-x / 0.025))
    ph = 2 * np.pi * np.cumsum(f) / SR
    y = np.sin(ph) + 0.3 * np.sin(2 * ph) + 0.08 * np.sin(3 * ph)
    env = np.clip(x / 0.003, 0, 1) * np.exp(-x / 0.28) * np.clip((dur + 0.3 - x) / 0.08, 0, 1)
    return (y * env * vel * 0.35).astype(np.float32)


def wheee(S: Song, bus: str, bar: float, beat: float, m0: float, m1: float, dur_beats: float, vel: float = 0.4,
          pan: float = 0.0) -> None:
    """Un « wiiii » qui monte (ou qui descend) : le thérémine glissé, pour ce qui s'envole."""
    d = dur_beats * S.spb
    n = int((d + 0.2) * SR)
    x = np.arange(n) / SR
    u = np.clip(x / d, 0, 1)
    semis = m0 + (m1 - m0) * (1 - np.cos(np.pi * u)) / 2 + 0.25 * np.sin(2 * np.pi * 6.0 * x) * u
    ph = 2 * np.pi * np.cumsum(hz(semis)) / SR
    y = np.sin(ph) + 0.12 * np.sin(2 * ph)
    env = np.sin(np.pi * np.clip(x / (d + 0.2), 0, 1)) ** 0.8
    S.add(bus, (y * env * vel * 0.2).astype(np.float32), S.t(bar, beat), 1.0, pan)


def harp_arp(S: Song, bar: float, notes, per_bar: int = 8, vel: float = 0.4, shape: str = "updown", beat0: float = 0.0,
             beats: float | None = None, bus: str = "harp") -> None:
    """La harpe qui égrène les notes de l'accord (montée, ou montée-descente)."""
    beats = S.beats if beats is None else beats
    seq = sorted(notes)
    if shape == "updown":
        seq = seq + seq[-2:0:-1]
    elif shape == "down":
        seq = seq[::-1]
    for k in range(per_bar):
        m = seq[k % len(seq)]
        play(S, "harp", bus, m, bar, beat0 + k * beats / per_bar, 2.5, vel * float(S.rng.uniform(0.85, 1.05)))


def harp_gliss(S: Song, bar: float, beat: float, notes, span: float = 0.9, vel: float = 0.45, bus: str = "harp") -> None:
    """Un glissando de harpe sur les notes de l'accord, sur plusieurs octaves."""
    seq = sorted(notes)
    for k, m in enumerate(seq):
        play(S, "harp", bus, m, bar, beat + k * span / len(seq), 2.0, vel * (0.7 + 0.3 * k / len(seq)), human=0.002)


def sprinkle(S: Song, bar: int, tones, prob: float, rng, bus: str = "celesta", vel=(0.2, 0.45), steps: int = 8) -> None:
    """Le célesta qui égrène doucement des notes de l'accord, au hasard."""
    for k in range(steps):
        if rng.random() < prob:
            m = tones[int(rng.integers(0, len(tones)))]
            S.add(bus, celesta(m, 0.6, float(rng.uniform(*vel)), rng), S.t(bar, k * S.beats / steps) + float(rng.normal(0, 0.01)),
                  1.0, float(rng.uniform(-0.6, 0.6)))


def chord_tones(notes, lo: int, hi: int):
    return sorted({m + 12 * o for m in notes for o in (-1, 0, 1, 2, 3) if lo <= m + 12 * o <= hi})


def mark_tree(S: Song, bar: float, which: str, gain: float = 0.5, bus: str = "far", rng=None) -> None:
    p = VCSL / m75.ST / "Mark Trees" / which
    if p.is_file():
        x = m75.read(p)[: int(6 * SR)]
        S.add(bus, x * gain, S.t(bar), 1.0, float(rng.uniform(-0.5, 0.5)) if rng is not None else 0.0)


def vsco_raw(rel: str) -> np.ndarray | None:
    p = VSCO / rel
    return m75.read(p) if p.is_file() else None


def chords_cells(prog):
    """Pour chaque mesure : la liste des (accord, temps de début, durée en temps)."""
    out = []
    for cell in prog:
        syms = cell.split()
        out.append([(s, k * 4.0 / len(syms), 4.0 / len(syms)) for k, s in enumerate(syms)])
    return out


# =========================================================================== Astralys, le jour

ASTRA = {   # accord : (basse, notes de la nappe)
    "Dmaj7": ("D2", "F#3 A3 C#4 E4"), "E/D": ("D2", "E3 G#3 B3 F#4"), "Bm7": ("B1", "D3 F#3 A3 C#4"),
    "Gmaj7": ("G1", "B3 D4 F#4 A4"), "Asus": ("A1", "D3 E3 A3 B3"), "A": ("A1", "C#3 E3 A3 B3"),
    "A/G": ("G1", "A3 C#4 E4 F#4"), "F#m7": ("F#1", "A3 C#4 E4 F#4"), "Em7": ("E2", "G3 B3 D4 F#4"),
    "D/F#": ("F#1", "A3 D4 E4 F#4"), "Bb": ("A#1", "D3 F3 A3 C4"), "C": ("C2", "E3 G3 B3 D4"),
    "Esus": ("E2", "A3 B3 E4 F#4"), "E": ("E2", "G#3 B3 E4 F#4"),
}


def notes_of(table, sym):
    b, ps = table[sym]
    return midi_of(b), [midi_of(p) for p in ps.split()]


def astralys(kit) -> Song:
    S = Song("astralys", 76, 38, loop=True, seed=761)
    rng = np.random.default_rng(7610)
    A = ["Dmaj7", "E/D", "Bm7", "Gmaj7", "Dmaj7", "E/D", "Gmaj7", "Asus A"]
    B = ["Gmaj7", "A/G", "F#m7", "Bm7", "Em7", "A", "D/F#", "Gmaj7"]
    C = ["Bb", "C", "Dmaj7", "Dmaj7", "Bb", "C", "Esus", "E"]
    D = ["Gmaj7", "A", "F#m7", "Bm7", "Em7", "Asus A"]
    prog = A + A + B + C + D
    melA = ("F#5:1.5 A5:0.5 C#6:1 A5:1 | G#5:2 B5:1 E6:1 | D6:1.5 C#6:0.5 B5:1 F#5:1 | B5:3 r:1 | "
            "F#5:1 A5:1 D6:1 E6:1 | F#6:2 E6:1 B5:1 | D6:1 B5:1 A5:1 F#5:1 | E5:2 A5:1 C#6:1")
    contre = "A4:4 | B4:4 | B4:2 A4:2 | G4:2 F#4:2 | A4:4 | G#4:4 | G4:2 F#4:2 | E4:2 E4:2"
    melB = ("B5:2 A5:1 G5:1 | C#6:3 E6:1 | A5:2 F#5:2 | D6:3 C#6:0.5 B5:0.5 | G5:2 B5:1 D6:1 | C#6:2 E6:2 | "
            "F#6:2 E6:1 D6:1 | D6:2 B5:1 A5:1")
    melC = "D5:2 F5:1 A5:1 | G5:3 E5:1 | F#5:4 | A5:2 C#6:2 | D6:2 C6:1 A5:1 | G5:2 E5:2 | A5:2 B5:2 | G#5:4"
    melD = "B5:2 D6:2 | C#6:2 A5:2 | A5:1 F#5:1 E5:1 C#5:1 | D5:2 F#5:2 | G5:2 E5:1 B4:1 | A4:2 C#5:2"
    cel = lambda m, d, v: celesta(m, d, v, rng)
    for i, cells in enumerate(chords_cells(prog)):
        for sym, b0, nb in cells:
            bass, notes = notes_of(ASTRA, sym)
            for m in notes:
                S.add("pad", pad(m, nb * S.spb + 0.3, 0.5, rng, cutoff=1700, attack=1.2, release=2.0), S.t(i, b0) - 0.25, 1.0)
            play(S, "cb", "low", bass, i, b0, nb + 0.2, 0.32)
            play(S, "vc", "low", bass + 12, i, b0, nb + 0.2, 0.2)
            tones = chord_tones(notes, 74, 98)
            # la harpe égrène (sauf pendant le passage étrange : elle ne pince que les temps forts)
            if 24 <= i < 32:
                for bb in (b0, b0 + nb / 2):
                    play(S, "harp", "harp", notes[int(rng.integers(0, len(notes)))] + 12, i, bb, 3.0, 0.32)
            else:
                harp_arp(S, i + b0 / 4, [m + 12 for m in notes] + [notes[0] + 24], int(8 * nb / 4), 0.36 if i >= 8 else 0.3,
                         "updown", 0.0, nb)
            if 16 <= i < 32:                   # le chœur doux (« ou »)
                for m in notes[-3:]:
                    play(S, "choeur_doux", "choir", m + 12, i, b0, nb + 0.3, 0.42)
        # les petits éclats de cristal : célesta, glockenspiel, carillons, scintillements
        sprinkle(S, i, chord_tones(notes_of(ASTRA, prog[i].split()[0])[1], 74, 98), 0.22 if i < 8 else 0.32, rng)
        tones = chord_tones(notes_of(ASTRA, prog[i].split()[0])[1], 76, 100)
        if rng.random() < 0.4:
            play(S, "glock", "far", tones[int(rng.integers(0, len(tones)))], i, float(rng.choice([1.5, 2.5, 3.5])), 1.0, 0.25)
        if rng.random() < 0.35:
            play(S, "carillon", "far", tones[int(rng.integers(0, len(tones)))] - 12, i, float(rng.choice([1.0, 3.0])), 3.0,
                 float(rng.uniform(0.18, 0.3)), pan=float(rng.uniform(-0.8, 0.8)))
        for _ in range(int(rng.integers(1, 4))):
            S.add("twinkle", twinkle(rng), S.t(i, float(rng.uniform(0, 4))), float(rng.uniform(0.08, 0.22)),
                  float(rng.uniform(-0.9, 0.9)))
    # les mélodies
    melody(S, None, "celesta", 0, melA, 0.55, synth=cel)
    melody(S, "glock", "glock", 0, melA, 0.3)
    melody(S, "flute", "flute", 8, melA, 0.42, legato=0.08)
    melody(S, "vln", "vln", 8, contre, 0.28, legato=0.2)
    melody(S, "vln", "vln", 16, melB, 0.45, legato=0.15)
    melody(S, None, "celesta", 16, melB, 0.3, octave=0, synth=cel)
    theremin(S, "theremin", 24, melC, 0.55, octave=-1, seed=7611)
    melody(S, "verres", "glass", 24, melC, 0.32, octave=0, legato=0.4)
    melody(S, "vln_trem", "trem", 24, "A6:4 | G6:4 | F#6:4 | F#6:4 | A6:4 | G6:4 | F#6:4 | G#6:4", 0.12)
    melody(S, "clar_v", "clar", 32, melD, 0.42, legato=0.08)
    melody(S, None, "celesta", 32, melD, 0.35, octave=1, synth=cel)
    for b, f in ((0, "windchimes_slowAsc1.wav"), (16, "windchimes_slowDesc1.wav"), (24, "windchimes_random.wav"), (32, "windchimes_slowAsc1.wav")):
        mark_tree(S, b, f, 0.4, rng=rng)
    for b0, c in ((0, "Dmaj7"), (16, "Gmaj7"), (32, "Gmaj7")):
        _, ns = notes_of(ASTRA, c)
        harp_gliss(S, b0 - 0.25, 0.0, chord_tones(ns, 55, 91), 0.95, 0.4)
    S.fx["pad"] = lambda x: filt(x, bw("highpass", 200)) * 0.7
    S.fx["low"] = lambda x: x * 0.55
    S.fx["harp"] = lambda x: x * 0.9
    S.fx["celesta"] = lambda x: echo(x, S.spb * 1.5, 0.28, 3, 6000, True, True) * 1.1
    S.fx["glock"] = lambda x: x * 0.7
    S.fx["flute"] = lambda x: x * 1.2
    S.fx["vln"] = lambda x: x * 1.0
    S.fx["choir"] = lambda x: filt(x, bw("highpass", 180)) * 1.4
    S.fx["theremin"] = lambda x: echo(x, S.spb * 0.75, 0.22, 3, 3500, True, True) * 1.0
    S.fx["glass"] = lambda x: x * 0.8
    S.fx["trem"] = lambda x: x * 0.6
    S.fx["clar"] = lambda x: x * 1.15
    S.fx["far"] = lambda x: x * 1.0
    S.fx["twinkle"] = lambda x: echo(x, S.spb * 0.75, 0.4, 4, 9000, True, True) * 0.7
    S.send.update({"pad": 0.35, "low": 0.35, "harp": 0.45, "celesta": 0.45, "glock": 0.5, "flute": 0.45, "vln": 0.45,
                   "choir": 0.6, "theremin": 0.5, "glass": 0.6, "trem": 0.6, "clar": 0.4, "far": 0.7, "twinkle": 0.7})
    return S


# =========================================================================== la Nuit des Aurores

NUIT = {
    "Amaj9": ("A1", "E3 G#3 B3 C#4"), "F#m9": ("F#1", "A3 C#4 E4 G#4"), "Dmaj9": ("D2", "F#3 A3 C#4 E4"),
    "Esus": ("E2", "A3 B3 E4 F#4"), "E": ("E2", "G#3 B3 E4 F#4"), "C#m7": ("C#2", "E3 G#3 B3 C#4"),
    "Bm9": ("B1", "D3 F#3 A3 C#4"), "Fmaj9": ("F1", "A3 C4 E4 G4"), "Gadd9": ("G1", "G3 B3 D4 A4"),
    "Dmaj9/A": ("A1", "F#3 A3 C#4 E4"),
}


def astralys_nuit(kit) -> Song:
    S = Song("astralys_nuit", 60, 30, loop=True, seed=762)
    rng = np.random.default_rng(7620)
    P1 = ["Amaj9", "Amaj9", "F#m9", "F#m9", "Dmaj9", "Dmaj9", "Esus", "E"]
    P2 = ["C#m7", "C#m7", "F#m9", "F#m9", "Dmaj9", "Bm9", "Esus", "E"]
    P3 = ["Fmaj9", "Fmaj9", "Gadd9", "Gadd9", "Amaj9", "F#m9", "Dmaj9", "Esus"]
    P4 = ["Amaj9", "Dmaj9/A", "Amaj9", "Dmaj9/A", "Esus", "E"]
    prog = P1 + P2 + P3 + P4
    mel1 = "C#6:2 B5:1 G#5:1 | E5:4 | A5:2 G#5:1 E5:1 | C#5:4 | F#5:2 E5:1 C#6:1 | A5:4 | B5:2 A5:2 | G#5:4"
    mel2 = "E5:3 C#5:1 | B4:4 | C#5:2 E5:2 | A5:4 | F#5:2 E5:2 | D5:2 C#5:1 B4:1 | A4:2 B4:2 | G#4:4"
    mel3 = "E5:2 G5:2 | A5:4 | D5:2 B4:2 | A4:4 | C#5:2 E5:2 | A5:2 G#5:2 | F#5:2 E5:2 | B4:4"
    mel4 = "A4:4 | F#4:2 A4:2 | E5:4 | C#5:2 E5:2 | B4:4 | G#4:4"
    cel = lambda m, d, v: celesta(m, d, v, rng)
    for i, c in enumerate(prog):
        bass, notes = notes_of(NUIT, c)
        for m in notes:
            S.add("pad", pad(m, 4 * S.spb + 0.5, 0.5, rng, cutoff=1300, attack=2.2, release=3.0), S.t(i) - 0.6, 1.0)
        play(S, "cb", "low", bass, i, 0, 4.3, 0.28)
        play(S, "vc", "low", bass + 12, i, 0, 4.3, 0.16)
        if i % 2 == 0:
            aurore(S, "aurore", i, 8.0, [m + 36 for m in notes[1:]], 0.9, seed=7621 + i)
            for m in notes[-2:]:
                play(S, "verres", "glass", m + 12, i, 0.5, 7.5, 0.34)
            harp_gliss(S, i, 0.0, [notes[0] + 12, notes[1] + 12, notes[2] + 12, notes[3] + 12, notes[1] + 24], 1.4, 0.3)
        if 8 <= i < 24:
            for m in notes[-3:]:
                play(S, "choeur_doux", "choir", m + 12, i, 0, 4.4, 0.4)
        tones = chord_tones(notes, 76, 100)
        sprinkle(S, i, tones, 0.2, rng, steps=4, vel=(0.18, 0.35))
        if rng.random() < 0.35:
            play(S, "glock", "far", tones[int(rng.integers(0, len(tones)))], i, float(rng.choice([1.0, 2.5, 3.0])), 1.0, 0.18)
        for _ in range(int(rng.integers(2, 6))):          # les étoiles
            S.add("twinkle", twinkle(rng), S.t(i, float(rng.uniform(0, 4))), float(rng.uniform(0.06, 0.2)), float(rng.uniform(-0.95, 0.95)))
    melody(S, None, "celesta", 0, mel1, 0.5, synth=cel)
    melody(S, "verres", "glass", 0, mel1, 0.22, octave=-1, legato=0.4)
    theremin(S, "theremin", 8, mel2, 0.6, glide=0.11, vib=0.26, seed=7622)
    melody(S, "verres", "glass", 16, mel3, 0.36, legato=0.4)
    melody(S, "flute", "flute", 16, mel3, 0.25, legato=0.1)
    theremin(S, "theremin", 24, mel4, 0.55, glide=0.12, vib=0.26, seed=7623)
    for b, f in ((0, "windchimes_slowAsc1.wav"), (12, "windchimes_random.wav"), (20, "windchimes_slowDesc1.wav"), (27, "windchimes_slowAsc1.wav")):
        mark_tree(S, b, f, 0.35, rng=rng)
    # la respiration grave de l'île (très bas, lente)
    for b in range(0, 30, 2):
        n = int(8 * S.spb * SR)
        x = np.arange(n) / SR
        f0 = hz(notes_of(NUIT, prog[b])[0])
        y = (np.sin(2 * np.pi * f0 * x) + 0.3 * np.sin(2 * np.pi * f0 * 2 * x + 1)) * np.sin(np.pi * x / x[-1]) ** 2
        S.add("deep", y * 0.07, S.t(b), 1.0)
    S.fx["pad"] = lambda x: filt(x, bw("highpass", 180)) * 0.8
    S.fx["low"] = lambda x: x * 0.5
    S.fx["aurore"] = lambda x: echo(x, S.spb * 1.5, 0.3, 3, 9000, True, True) * 1.0
    S.fx["glass"] = lambda x: x * 0.85
    S.fx["harp"] = lambda x: x * 0.8
    S.fx["choir"] = lambda x: filt(x, bw("highpass", 180)) * 1.3
    S.fx["celesta"] = lambda x: echo(x, S.spb * 0.75, 0.35, 4, 6000, True, True) * 1.0
    S.fx["theremin"] = lambda x: echo(x, S.spb * 1.0, 0.25, 3, 3500, True, True) * 1.0
    S.fx["flute"] = lambda x: x * 1.0
    S.fx["far"] = lambda x: x * 0.9
    S.fx["twinkle"] = lambda x: echo(x, S.spb * 0.5, 0.45, 5, 9000, True, True) * 0.7
    S.fx["deep"] = lambda x: x * 0.35
    S.send.update({"pad": 0.4, "low": 0.3, "aurore": 0.7, "glass": 0.65, "harp": 0.55, "choir": 0.65, "celesta": 0.55,
                   "theremin": 0.55, "flute": 0.5, "far": 0.8, "twinkle": 0.8, "deep": 0.2})
    return S


# =========================================================================== le Jardin des Apesanteurs

APE = {
    "F": ("F2", "A3 C4 F4"), "Gm7": ("G2", "A#3 D4 F4"), "C7": ("C2", "A#3 E4 G4"), "Dm": ("D2", "A3 D4 F4"),
    "Bb": ("A#1", "A#3 D4 F4"), "C": ("C2", "G3 C4 E4"), "A7": ("A1", "A3 C#4 G4"), "Gm": ("G2", "A#3 D4 G4"),
    "Bbmaj7": ("A#1", "A#3 D4 F4 A4"), "Am7": ("A1", "A3 C4 E4 G4"), "F/A": ("A1", "A3 C4 F4"),
}


def apesanteur(kit) -> Song:
    S = Song("apesanteur", 104, 52, loop=True, seed=763)
    rng = np.random.default_rng(7630)
    A = ["F", "Gm7 C7", "F", "Dm", "Bb", "C", "F Dm", "Gm7 C7"]
    Bm = ["Dm", "A7", "Dm", "Gm", "Bb", "A7", "Dm", "C7"]
    Cf = ["Bbmaj7", "Am7", "Gm7", "F/A", "Bbmaj7", "Am7", "Gm7", "C7"]
    L = ["F", "Dm", "Gm7", "C7"]
    prog = A + A + Bm + A + Cf + A + L
    melA = ("C5:0.5 F5:0.5 A5:0.5 r:0.5 G5:0.5 F5:0.5 r:1 | G5:0.5 A#5:0.5 D6:0.5 r:0.5 C6:1 r:1 | "
            "A5:0.5 C6:0.5 F6:0.5 r:0.5 E6:0.5 C6:0.5 A5:1 | D6:1.5 C6:0.5 A5:1 r:1 | "
            "D6:0.5 r:0.5 D6:0.5 C6:0.5 A#5:1 F5:1 | E5:0.5 G5:0.5 C6:0.5 r:0.5 A#5:1 G5:1 | "
            "A5:0.5 r:0.5 F5:0.5 A5:0.5 D6:1 A5:1 | G5:1 A5:0.5 A#5:0.5 C6:1 r:1")
    melB = ("D4:0.5 F4:0.5 A4:0.5 D5:0.5 C#5:1 A4:1 | E4:0.5 G4:0.5 A4:0.5 C#5:0.5 E5:1 r:1 | "
            "F5:0.5 E5:0.5 D5:0.5 A4:0.5 F4:1 D4:1 | G4:0.5 A#4:0.5 D5:0.5 G5:0.5 F5:1 D5:1 | "
            "F5:0.5 D5:0.5 A#4:0.5 D5:0.5 F5:1 A#5:1 | A5:1 G5:0.5 F5:0.5 E5:1 C#5:1 | D5:1 A4:1 F4:1 D4:1 | "
            "E4:0.5 G4:0.5 A#4:0.5 C5:0.5 E5:1 G5:1")
    melC = "D6:2 F6:2 | E6:4 | D6:2 A#5:2 | C6:4 | D6:1 F6:1 A6:2 | G6:2 E6:2 | F6:2 D6:1 A#5:1 | G5:2 C6:2"
    for i, cells in enumerate(chords_cells(prog)):
        sec = "C" if 32 <= i < 40 else ("B" if 16 <= i < 24 else ("L" if i >= 48 else "A"))
        for sym, b0, nb in cells:
            bass, notes = notes_of(APE, sym)
            if sec == "C":                     # tout flotte : la harpe, les nappes, la contrebasse tenue
                harp_arp(S, i + b0 / 4, [m + 12 for m in notes] + [notes[0] + 24], 6, 0.32, "up", 0.0, nb)
                for m in notes:
                    S.add("pad", pad(m + 12, nb * S.spb + 0.2, 0.45, rng, cutoff=2400, attack=0.8, release=1.6), S.t(i, b0) - 0.1, 1.0)
                play(S, "cb", "low", bass, i, b0, nb, 0.3)
                continue
            # la basse qui rebondit (pizzicato de contrebasse doublé par la basse « rebond »)
            steps = [(0.0, bass), (nb / 2, bass + 7 if nb == 4 else bass + 12)] if nb == 4 else [(0.0, bass)]
            if nb == 4 and rng.random() < 0.5:
                steps.append((1.5, bass + 12))
            for bt, m in steps:
                play(S, "cb_pizz", "bass", m, i, b0 + bt, 1.0, 0.7)
                S.add("bloop", bloop(m + 12, 0.5, 0.8), S.t(i, b0 + bt), 1.0, 0.0)
            # les contretemps : pizzicati des violons et accords de marimba
            for bt in np.arange(0.5, nb, 1.0):
                for m in notes:
                    play(S, "vln_pizz", "pizz", m + 12, i, b0 + float(bt), 0.5, 0.38 * float(rng.uniform(0.85, 1.05)))
            for bt in ((1.0, 3.0) if nb == 4 else (1.0,)):
                for m in notes:
                    play(S, "marimba", "marimba", m + 12, i, b0 + bt, 0.5, 0.42)
        # la petite percussion : bloc de bois et tambourin
        if sec != "C":
            m75.drums(S, kit, i, {"wb": "..x...x...x...x.", "tb": "....o.......o..."}, 0.55)
            if i % 8 == 7:
                m75.drums(S, kit, i, {"cv": "........x.x.x.x."}, 0.6)
        if i % 4 == 3 and sec != "C":         # un « boïng » de fin de phrase
            S.add("bloop", bloop(midi_of("C5"), 0.6, 0.6), S.t(i, 3.5), 1.0, float(rng.uniform(-0.4, 0.4)))
    # les mélodies : xylophone et clarinette, flûte, basson et marimba, célesta qui flotte, tout le monde
    melody(S, "xylo", "xylo", 0, melA, 0.5)
    melody(S, "clar_stac", "wood", 0, melA, 0.5, octave=-1)
    melody(S, "flute", "flute", 8, melA, 0.5, legato=0.0, stac=0.85)
    melody(S, "glock", "glock", 8, melA, 0.32)
    melody(S, "bsn_stac", "wood", 16, melB, 0.6, octave=-1)
    melody(S, "marimba", "marimba", 16, melB, 0.55, octave=1)
    melody(S, "glock", "glock", 24, melA, 0.4)
    melody(S, None, "celesta", 24, melA, 0.5, synth=lambda m, d, v: celesta(m, d, v, rng))
    melody(S, None, "celesta", 32, melC, 0.55, synth=lambda m, d, v: celesta(m, d, v, rng))
    melody(S, "verres", "glass", 32, melC, 0.3, octave=-1, legato=0.3)
    melody(S, "xylo", "xylo", 40, melA, 0.55)
    melody(S, "flute", "flute", 40, melA, 0.45, stac=0.85)
    melody(S, "clar_stac", "wood", 40, melA, 0.45, octave=-1)
    melody(S, "glock", "glock", 40, melA, 0.3)
    melody(S, "vla", "strings", 40, "A4:4 | A#4:2 G4:2 | A4:4 | A4:4 | A#4:4 | G4:4 | A4:2 A4:2 | A#4:2 G4:2", 0.25, legato=0.1)
    # les « wiii » de ceux qui s'envolent
    for b, bt, a, z in ((33, 2.0, 67, 84), (35, 2.5, 72, 89), (37, 1.0, 69, 86), (39, 2.0, 84, 72), (51, 0.0, 65, 89)):
        wheee(S, "wheee", b, bt, a, z, 2.0, 0.5, float(rng.uniform(-0.6, 0.6)))
    # la transition (4 mesures) : glockenspiel qui monte, pizzicati
    melody(S, "glock", "glock", 48, "C5:0.5 F5:0.5 A5:0.5 C6:0.5 F6:2 | D5:0.5 F5:0.5 A5:0.5 D6:0.5 F6:2 | "
           "D5:0.5 G5:0.5 A#5:0.5 D6:0.5 G6:2 | E5:0.5 G5:0.5 A#5:0.5 C6:0.5 E6:1 G6:1", 0.35)
    S.fx["bass"] = lambda x: x * 1.0
    S.fx["bloop"] = lambda x: filt(x, bw("highpass", 60)) * 0.9
    S.fx["pizz"] = lambda x: x * 0.55
    S.fx["marimba"] = lambda x: x * 0.6
    S.fx["xylo"] = lambda x: x * 0.8
    S.fx["wood"] = lambda x: x * 1.0
    S.fx["flute"] = lambda x: x * 1.0
    S.fx["glock"] = lambda x: x * 0.65
    S.fx["celesta"] = lambda x: echo(x, S.spb * 0.75, 0.3, 3, 6000, True, True) * 1.1
    S.fx["glass"] = lambda x: x * 0.8
    S.fx["harp"] = lambda x: x * 0.8
    S.fx["pad"] = lambda x: filt(x, bw("highpass", 250)) * 0.6
    S.fx["low"] = lambda x: x * 0.5
    S.fx["strings"] = lambda x: x * 0.8
    S.fx["wheee"] = lambda x: echo(x, S.spb * 0.75, 0.3, 3, 5000, True, True) * 1.0
    m75.drum_fx(S)
    S.fx["dr_perc"] = lambda x: x * 0.5
    S.send.update({"bass": 0.2, "bloop": 0.15, "pizz": 0.35, "marimba": 0.35, "xylo": 0.35, "wood": 0.3, "flute": 0.4,
                   "glock": 0.45, "celesta": 0.5, "glass": 0.6, "harp": 0.5, "pad": 0.4, "low": 0.3, "strings": 0.45,
                   "wheee": 0.5})
    return S


# =========================================================================== Ciel Libre (le vol)

CIEL = {
    "G": ("G1", "G3 B3 D4"), "D/F#": ("F#1", "F#3 A3 D4"), "Em": ("E2", "G3 B3 E4"), "C": ("C2", "G3 C4 E4"),
    "D": ("D2", "F#3 A3 D4"), "Bm": ("B1", "F#3 B3 D4"), "G/B": ("B1", "G3 B3 D4"), "Am7": ("A1", "G3 C4 E4"),
    "Dsus": ("D2", "G3 A3 D4"), "Eb": ("D#2", "G3 A#3 D#4"), "F": ("F2", "A3 C4 F4"),
}


def ciel_libre(kit) -> Song:
    S = Song("ciel_libre", 92, 46, loop=True, seed=764)
    rng = np.random.default_rng(7640)
    A = ["G", "D/F#", "Em", "C", "G", "D/F#", "C", "D"]
    A2 = ["G", "Bm", "C", "G/B", "Am7", "D", "Em C", "D"]
    B = ["Em", "C", "G", "D", "Em", "C", "Am7", "Dsus D"]
    C = A + ["Eb", "F"]
    Dc = ["C", "G/B", "Am7", "G", "C", "G/B", "Am7", "Dsus"]
    L = ["Eb", "F", "Dsus", "D"]
    prog = A + A2 + B + C + Dc + L
    melA = ("D4:1 G4:1 B4:1.5 A4:0.5 | A4:2 F#4:1 D4:1 | E4:1 G4:1 B4:1 E5:1 | E5:3 r:1 | D5:1.5 C5:0.5 B4:1 G4:1 | "
            "A4:2 F#4:1 D4:1 | E4:1 G4:1 C5:1 E5:1 | D5:4")
    melA2 = ("B5:1.5 A5:0.5 G5:1 D5:1 | F#5:2 D5:1 B4:1 | C5:1 E5:1 G5:1 C6:1 | B5:3 G5:1 | A5:1.5 G5:0.5 E5:1 C5:1 | "
             "A5:2 F#5:1 D5:1 | E5:1 G5:0.5 B5:0.5 C6:1 E5:1 | F#5:2 A5:2")
    melB = "G5:2 B5:1 E6:1 | E6:2 D6:1 C6:1 | B5:2 D6:1 G6:1 | F#6:3 r:1 | E6:1 D6:1 B5:1 G5:1 | C6:2 E6:1 G6:1 | E6:2 C6:1 A5:1 | A5:2 F#5:2"
    melC_end = " | G4:2 A#4:1 D5:1 | A4:2 C5:1 F5:1"
    melD = "E5:2 G5:1 C6:1 | B5:2 G5:2 | A5:1.5 G5:0.5 E5:1 C5:1 | D5:4 | E5:2 G5:1 E6:1 | D6:2 B5:2 | C6:1 B5:1 A5:1 E5:1 | D5:3 A4:1"
    run = "G4:0.5 A#4:0.5 D5:0.5 G5:0.5 A#5:1 D6:1 | A4:0.5 C5:0.5 F5:0.5 A5:0.5 C6:1 F6:1 | G5:1 A5:1 C6:1 D6:1 | F#6:4"
    for i, cells in enumerate(chords_cells(prog)):
        climax = 24 <= i < 34
        calm = 34 <= i < 42
        for sym, b0, nb in cells:
            bass, notes = notes_of(CIEL, sym)
            play(S, "cb", "low", bass, i, b0, nb + 0.1, 0.42 if climax else 0.34)
            play(S, "vc", "low", bass + 12, i, b0, nb + 0.1, 0.3 if climax else 0.24)
            # les cordes qui courent (altos en spiccato, croches) ; plus calmes : la harpe
            if calm:
                harp_arp(S, i + b0 / 4, [m + 12 for m in notes] + [notes[0] + 24], int(8 * nb / 4), 0.35, "updown", 0.0, nb)
                for m in notes:
                    S.add("pad", pad(m + 12, nb * S.spb + 0.2, 0.45, rng, cutoff=2000, attack=1.0, release=1.8), S.t(i, b0) - 0.2, 1.0)
            else:
                seq = sorted(notes + [notes[0] + 12])
                order = [0, 2, 1, 3, 2, 1, 3, 2]
                for k in range(int(8 * nb / 4)):
                    play(S, "vla_spic", "ost", seq[order[k % 8]] + 12, i, b0 + k * 0.5, 0.5,
                         (0.55 if k % 2 == 0 else 0.42) * (1.15 if climax else 1.0))
                # les cors tenus (accord) sous le thème des violons
                if 8 <= i < 24 or climax:
                    for m in notes:
                        play(S, "horn", "horns", m, i, b0, nb + 0.1, 0.3 if not climax else 0.38)
            if climax:
                for m in notes:
                    play(S, "choeur_f", "choir", m + 12, i, b0, nb + 0.2, 0.42)
                play(S, "vln_trem", "trem", notes[-1] + 24, i, b0, nb + 0.1, 0.2)
        # le pouls de l'élan : timbales et tom grave, grosse caisse douce
        if not calm and i >= 8:
            r, _ = notes_of(CIEL, prog[i].split()[0])
            tm = 40 + (r - 40) % 12                  # la timbale : la fondamentale entre mi2 et ré#3
            if climax:
                play(S, "timp", "timp", tm, i, 0, 1.0, 0.55)
                play(S, "timp", "timp", tm + 7 if tm + 7 <= 52 else tm - 5, i, 2.0, 1.0, 0.45)
                m75.drums(S, kit, i, {"k": "x.......x.......", "4": "....o.......o.o.", "R": "..o...o...o...o."}, 0.6)
            else:
                m75.drums(S, kit, i, {"k": "o.......o.......", "4": "........o......."}, 0.5)
        if i in (8, 24, 28, 34):
            m75.drums(S, kit, i, {"c": "x..............."}, 0.6)
    # les mélodies
    melody(S, "horn", "horns_mel", 0, melA, 0.55, legato=0.1)
    melody(S, "vln", "vln", 8, melA2, 0.5, legato=0.12)
    melody(S, "flute", "flute", 16, melB, 0.5, legato=0.08)
    melody(S, "vln", "vln", 16, m75.transpose(melB, -12), 0.32, legato=0.12)
    melody(S, "horn", "horns_mel", 24, melA + melC_end, 0.62, legato=0.1)
    melody(S, "trp", "trp", 24, m75.transpose(melA, 12) + " | G5:2 A#5:1 D6:1 | A5:2 C6:1 A5:1", 0.42, legato=0.08)
    melody(S, "vln", "vln", 24, m75.transpose(melA + melC_end, 12), 0.42, legato=0.12)
    melody(S, "oboe_v", "oboe", 34, melD, 0.5, legato=0.08)
    melody(S, "flute", "flute", 38, " | ".join(melD.split(" | ")[4:]), 0.3, legato=0.08)
    melody(S, "vln", "vln", 42, run, 0.42, legato=0.05)
    melody(S, "picc", "flute", 42, run, 0.25, legato=0.05)
    # harpe en glissando à chaque départ, la cymbale qui enfle avant l'élan, les timbales qui roulent
    for b0, c in ((0, "G"), (8, "G"), (16, "Em"), (24, "G"), (34, "C"), (42, "Eb")):
        _, ns = notes_of(CIEL, c)
        harp_gliss(S, b0 - 0.25, 0.0, chord_tones(ns, 55, 93), 0.95, 0.5)
    sw = vsco_raw("Percussion/susCymb1-cresc-Median_v1.wav")
    if sw is not None:
        k = int(np.argmax(np.abs(sw).max(axis=1)))
        for b in (24, 42):
            S.add("cymb", sw[: k + int(0.4 * SR)] * 0.5, S.t(b) - k / SR, 1.0, 0.2)
    for b in (22, 46 - 2):
        play(S, "timp_roll", "timp", midi_of("D3"), b, 0.0, 8.0, 0.5)
    S.fx["low"] = lambda x: x * 0.6
    S.fx["ost"] = lambda x: x * 0.7
    S.fx["horns"] = lambda x: x * 0.5
    S.fx["horns_mel"] = lambda x: x * 1.05
    S.fx["vln"] = lambda x: x * 1.0
    S.fx["flute"] = lambda x: x * 1.1
    S.fx["trp"] = lambda x: x * 0.75
    S.fx["oboe"] = lambda x: x * 1.0
    S.fx["choir"] = lambda x: filt(x, bw("highpass", 200)) * 1.2
    S.fx["trem"] = lambda x: x * 0.5
    S.fx["harp"] = lambda x: x * 0.9
    S.fx["pad"] = lambda x: filt(x, bw("highpass", 220)) * 0.55
    S.fx["timp"] = lambda x: x * 0.8
    S.fx["cymb"] = lambda x: x * 0.6
    m75.drum_fx(S)
    S.fx["dr_kick"] = lambda x: m75.compress(filt(x, bw("lowpass", 3000)), -14, 2.0, 0.005, 0.1) * 0.55
    S.fx["dr_toms"] = lambda x: x * 0.6
    S.fx["dr_cym"] = lambda x: filt(x, bw("highpass", 300)) * 0.4
    S.send.update({"low": 0.35, "ost": 0.35, "horns": 0.5, "horns_mel": 0.5, "vln": 0.45, "flute": 0.45, "trp": 0.45,
                   "oboe": 0.45, "choir": 0.6, "trem": 0.55, "harp": 0.5, "pad": 0.4, "timp": 0.5, "cymb": 0.6,
                   "dr_kick": 0.3, "dr_toms": 0.45, "dr_cym": 0.5})
    return S


# =========================================================================== le Chantier Naval (6/8)

NAV = {
    "D": ("D2", "F#3 A3 D4"), "A": ("A1", "E3 A3 C#4"), "A7": ("A1", "E3 G3 C#4"), "G": ("G1", "G3 B3 D4"),
    "Em": ("E2", "G3 B3 E4"), "C": ("C2", "G3 C4 E4"), "D7": ("D2", "F#3 C4 D4"), "Bm": ("B1", "F#3 B3 D4"),
    "F#": ("F#1", "F#3 A#3 C#4"),
}


def chantier(kit) -> Song:
    S = Song("chantier", 216, 72, beats=6, loop=True, seed=765)     # 6/8 : une croche = un « temps » de la grille
    rng = np.random.default_rng(7650)
    I_ = ["D", "A7", "D", "A7"]
    A1 = ["D", "A", "D", "A", "G", "D", "A", "D"]
    A2 = ["D", "G", "D", "A", "G", "D", "A7", "D"]
    B1 = ["G", "C", "G", "D", "G", "D7", "G D", "G"]
    B2 = ["Em", "D", "G", "A", "D", "A", "A7", "A7"]
    Cm = ["Bm", "Bm", "G", "F#", "Bm", "D", "G F#", "Bm A7"]
    Dt = A2 + ["D", "A7", "D", "A7"]
    prog = I_ + A1 + A2 + B1 + B2 + Cm + A1 + A2 + Dt
    melA1 = ("D5:2 F#5:1 A5:2 F#5:1 | G5:2 E5:1 C#5:2 A4:1 | D5:2 F#5:1 A5:2 D6:1 | C#6:3 A5:3 | B5:2 G5:1 E5:2 G5:1 | "
             "A5:2 F#5:1 D5:2 F#5:1 | E5:2 D5:1 C#5:2 E5:1 | D5:3 r:3")
    melA2 = ("A5:2 B5:1 A5:2 F#5:1 | G5:2 A5:1 G5:2 E5:1 | F#5:2 G5:1 F#5:2 D5:1 | E5:3 A4:3 | D5:2 E5:1 F#5:2 G5:1 | "
             "A5:2 B5:1 A5:2 D6:1 | C#6:2 B5:1 A5:2 C#6:1 | D6:3 r:3")
    melB1 = ("B4:2 D5:1 G5:2 B4:1 | C5:2 E5:1 G5:2 C5:1 | D5:2 G5:1 B5:2 G5:1 | A5:3 D5:3 | B4:2 D5:1 G5:2 B5:1 | "
             "A5:2 F#5:1 D5:2 C5:1 | B4:2 A4:1 G4:2 F#4:1 | G4:3 r:3")
    melB2 = ("E5:2 F#5:1 G5:2 E5:1 | F#5:2 G5:1 A5:2 F#5:1 | G5:2 A5:1 B5:2 G5:1 | A5:3 E5:3 | F#5:2 E5:1 D5:2 F#5:1 | "
             "E5:2 D5:1 C#5:2 E5:1 | A4:3 C#5:3 | E5:3 A5:3")
    melC = ("F#5:2 E5:1 D5:2 C#5:1 | B4:3 F#4:3 | G4:2 A4:1 B4:2 D5:1 | C#5:3 F#4:3 | B4:2 C#5:1 D5:2 E5:1 | "
            "F#5:2 G5:1 F#5:2 E5:1 | D5:2 C#5:1 B4:2 A#4:1 | B4:3 A4:3")
    for i, cells in enumerate(chords_cells(prog)):
        intro = i < 4
        vamp = i >= 68
        light = 36 <= i < 44
        for sym, b0, nb in cells:
            b0, nb = b0 * 1.5, nb * 1.5                 # (chords_cells compte en 4 temps : on passe en croches)
            bass, notes = notes_of(NAV, sym)
            # le tuba « oum » (fondamentale, puis quinte) et l'accordéon de la main gauche « pa-pa »
            for k, bt in enumerate(np.arange(0, nb, 3.0)):
                m = bass + (0 if (k + i) % 2 == 0 or nb < 6 else 7)
                play(S, "tuba_stac", "tuba", m + 12 if m + 12 <= 50 else m, i, b0 + bt, 1.0, 0.7 if not (light or intro) else 0.5)
                for pb in (1.0, 2.0):
                    for mm in notes:
                        play(S, "accordeon_g", "acc_g", mm, i, b0 + bt + pb, 0.7, 0.42 if pb == 1.0 else 0.36)
            if light:
                for mm in notes:
                    play(S, "vc_pizz", "pizz", mm, i, b0, 1.0, 0.5)
            if 20 <= i < 36 or 44 <= i < 68:          # les cors tiennent l'accord
                for mm in notes:
                    play(S, "horn", "horns", mm, i, b0, nb, 0.26)
        # la batterie : grosse caisse, bord de caisse claire, tambourin
        if not intro and not vamp:
            pat = {"k": "x.....x.....", "x": "......x.....", "tb": "..o..o..o..o"} if not light else {"tb": "..o.....o..."}
            m75.drums(S, kit, i, pat, 0.6)
        # les marteaux du chantier (l'enclume) : dans l'intro, la transition et à chaque fin de phrase
        if intro or vamp or (i % 8 == 7 and not light):
            m75.drums(S, kit, i, {"an": "x.....x....." if (intro or vamp) else "......x..x.."}, 0.5)
        if i % 16 == 4:
            play(S, "glock", "far", midi_of("A6"), i, 0.0, 2.0, 0.25)
    # les mélodies
    melody(S, "musette", "musette", 2, "F#5:2 E5:1 D5:2 C#5:1 | B4:2 C#5:1 E5:2 A4:1", 0.42)
    melody(S, "musette", "musette", 4, melA1, 0.55)
    melody(S, "musette", "musette", 12, melA2, 0.55)
    melody(S, "trp", "brass", 20, melB1, 0.55, legato=0.05)
    melody(S, "tbn", "brass", 20, m75.transpose(melB1, -12), 0.4, legato=0.05)
    melody(S, "trp", "brass", 28, melB2, 0.55, legato=0.05)
    melody(S, "tbn", "brass", 28, m75.transpose(melB2, -12), 0.4, legato=0.05)
    melody(S, "clar_v", "clar", 36, melC, 0.5, legato=0.05)
    melody(S, "musette", "musette", 44, melA1, 0.55)
    melody(S, "trp", "brass", 44, melA1, 0.32, legato=0.03)
    melody(S, "musette", "musette", 52, melA2, 0.55)
    melody(S, "clar_v", "clar", 52, m75.transpose(melA2, -12), 0.32, legato=0.05)
    melody(S, "trp", "brass", 60, melA2, 0.5, legato=0.03)
    melody(S, "tbn", "brass", 60, m75.transpose(melA2, -12), 0.38, legato=0.03)
    melody(S, "musette", "musette", 60, melA2, 0.45)
    melody(S, "musette", "musette", 68, "A4:3 D5:3 | C#5:3 E5:3 | F#5:3 A5:3 | G5:3 E5:3", 0.42)
    # les « Ho ! » des charpentiers
    m75.crowd_seed(7651)
    for b, bt in ((19, 3.0), (35, 3.0), (59, 3.0), (67, 3.0)):
        h = m75.hey(np.random.default_rng(7652 + b), 12, "o")
        S.add("crowd", h, S.t(b, bt), 0.5)
    S.fx["tuba"] = lambda x: x * 0.85
    S.fx["acc_g"] = lambda x: filt(x, bw("highpass", 150)) * 0.6
    S.fx["musette"] = lambda x: x * 1.0
    S.fx["brass"] = lambda x: x * 0.85
    S.fx["clar"] = lambda x: x * 1.0
    S.fx["horns"] = lambda x: x * 0.45
    S.fx["pizz"] = lambda x: x * 0.7
    S.fx["far"] = lambda x: x * 0.7
    S.fx["crowd"] = lambda x: filt(x, bw("lowpass", 4500)) * 0.6
    m75.drum_fx(S)
    S.fx["dr_perc"] = lambda x: x * 0.35
    S.fx["dr_kick"] = lambda x: m75.compress(filt(x, bw("lowpass", 2500)), -14, 2.0, 0.005, 0.1) * 0.6
    S.fx["dr_snare"] = lambda x: x * 0.8
    S.send.update({"tuba": 0.2, "acc_g": 0.25, "musette": 0.3, "brass": 0.35, "clar": 0.35, "horns": 0.45, "pizz": 0.3,
                   "far": 0.6, "crowd": 0.5})
    return S


# =========================================================================== la ritournelle des compagnons

COMP = {"F": ("F2", "A3 C4 F4"), "Dm": ("D2", "A3 D4 F4"), "Bb": ("A#1", "A#3 D4 F4"), "C7": ("C2", "A#3 E4 G4"),
        "Gm7/C": ("C2", "A#3 D4 F4"), "Fadd9": ("F2", "A3 C4 G4")}


def compagnons(kit) -> Song:
    S = Song("compagnons", 88, 6, loop=False, seed=766, tail=3.2)
    rng = np.random.default_rng(7660)
    prog = ["F", "Dm", "Bb", "C7", "Bb Gm7/C", "Fadd9"]
    mel = "C5:1 F5:1 A5:1.5 G5:0.5 | A5:1 C6:2 A5:1 | D6:1 C6:0.5 A#5:0.5 A5:1 F5:1 | G5:3 r:1 | A#5:1 A5:0.5 G5:0.5 E5:1 G5:1 | F5:4"
    answer = "r:4 | r:4 | r:4 | r:1 E5:1 G5:1 A#5:1 | r:4 | r:4"
    for i, cells in enumerate(chords_cells(prog)):
        last = i == len(prog) - 1
        for sym, b0, nb in cells:
            bass, notes = notes_of(COMP, sym)
            play(S, "vc", "strings", bass + 12, i, b0, (nb + 3.0) if last else nb + 0.1, 0.3)
            play(S, "cb", "strings", bass, i, b0, (nb + 3.0) if last else nb + 0.1, 0.25)
            for m in notes:
                play(S, "vla", "strings", m, i, b0, (nb + 3.0) if last else nb + 0.1, 0.18)
            if not last:
                harp_arp(S, i + b0 / 4, [m + 12 for m in notes] + [notes[0] + 24], int(8 * nb / 4), 0.36, "up", 0.0, nb)
                for bt in np.arange(1.0, nb, 2.0):
                    for m in notes:
                        play(S, "vln_pizz", "pizz", m + 12, i, b0 + float(bt), 0.5, 0.4)
    melody(S, None, "celesta", 0, mel, 0.6, synth=lambda m, d, v: celesta(m, d, v, rng))
    melody(S, "flute", "flute", 0, mel, 0.3, legato=0.08)
    melody(S, "clar_v", "clar", 0, answer, 0.45, octave=-1, legato=0.05)
    # l'accord final : glissando de harpe et le glockenspiel qui scintille
    _, ns = notes_of(COMP, "Fadd9")
    harp_gliss(S, 5, 0.0, chord_tones(ns, 53, 89), 1.0, 0.45)
    for k, m in enumerate([77, 81, 84, 89, 93]):
        play(S, "glock", "glock", m, 5, 1.0 + k * 0.25, 1.5, 0.3)
    for _ in range(6):
        S.add("twinkle", twinkle(rng), S.t(5, float(rng.uniform(1.0, 4.0))), float(rng.uniform(0.1, 0.2)), float(rng.uniform(-0.8, 0.8)))
    S.fx["strings"] = lambda x: x * 0.7
    S.fx["harp"] = lambda x: x * 0.9
    S.fx["pizz"] = lambda x: x * 0.6
    S.fx["celesta"] = lambda x: echo(x, S.spb * 0.75, 0.25, 3, 6000, False, False) * 1.15
    S.fx["flute"] = lambda x: x * 1.0
    S.fx["clar"] = lambda x: x * 1.1
    S.fx["glock"] = lambda x: x * 0.7
    S.fx["twinkle"] = lambda x: x * 0.7
    S.send.update({"strings": 0.4, "harp": 0.45, "pizz": 0.35, "celesta": 0.45, "flute": 0.45, "clar": 0.4, "glock": 0.5,
                   "twinkle": 0.6})
    return S


# =========================================================================== lancement

PIECES = {
    # nom : (fonction, sonie visée en LUFS, salle : (durée, sombre, pré-délai, réflexions, étendue), compression)
    "astralys": (astralys, -19.0, (3.4, 0.4, 0.03, 20, 0.09), (-22.0, 1.5)),
    "astralys_nuit": (astralys_nuit, -20.0, (5.0, 0.35, 0.04, 22, 0.1), (-24.0, 1.5)),
    "apesanteur": (apesanteur, -18.5, (1.8, 0.5, 0.015, 16, 0.05), (-20.0, 1.8)),
    "ciel_libre": (ciel_libre, -18.0, (2.8, 0.5, 0.025, 18, 0.07), (-20.0, 1.8)),
    "chantier": (chantier, -18.0, (1.2, 0.6, 0.012, 14, 0.04), (-18.0, 2.0)),
    "compagnons": (compagnons, -18.5, (2.2, 0.5, 0.02, 16, 0.06), (-20.0, 1.5)),
}


def render_piece(name: str, kit, out_dir: Path) -> np.ndarray:
    fn, target, (sec, dark, pre, er, span), glue = PIECES[name]
    S = fn(kit)
    ir = m75.room_ir(sec, dark, pre, er, S.seed, span)
    y = S.render(out_dir / f"{name}.ogg", target, -2.0, ir, glue, None)
    release_instruments()
    del S
    gc.collect()
    return y


def main() -> int:
    global VSCO, VCSL, CC0
    args = sys.argv[1:]
    names = []
    while args:
        a = args.pop(0)
        if a == "--vsco":
            VSCO = Path(args.pop(0))
        elif a == "--vcsl":
            VCSL = Path(args.pop(0))
        elif a == "--cc0":
            CC0 = Path(args.pop(0))
        else:
            names.append(a)
    m75.VSCO, m75.VCSL, m75.CC0 = VSCO, VCSL, CC0
    m75.TMP = Path(m75.tempfile.gettempdir()) / "musique_v76"
    cm70.VCSL = VCSL
    cm51.VSCO = VSCO
    import generate_sons_v63 as s63
    s63.LIB = CC0
    kit = m75.Kit(seed=76)
    for name in names or list(PIECES):
        if name not in PIECES:
            print("morceau inconnu :", name)
            continue
        render_piece(name, kit, OUT)
    try:
        m75.TMP.rmdir()
    except OSError:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
