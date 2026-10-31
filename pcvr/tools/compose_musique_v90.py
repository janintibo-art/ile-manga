"""V90 : les musiques de l'Île Pixelithique (tout en petits carrés… même la musique).

Compositions originales pour « Les Mondes de Travers », versées au domaine public (CC0 1.0). Jouées avec
les outils des V75 et V76 (le morceau, ses bus, la salle, le mastering, la boucle sans raccord) : des
instruments de console synthétisés ici (des ondes carrées « 8 bits » aux largeurs changeantes, une
basse triangle, des percussions de bruit), mêlés aux vrais instruments (VSCO-2 CE et VCSL, Versilian
Studios, CC0) : marimba, xylophone, flûte, pizzicati, toms, tambour sur cadre, bloc de bois, claves,
claquements de mains, grosse caisse.

  pixelithique.ogg  « L'Île Pixelithique » : ré dorien, 112 à la noire, en boucle (48 mesures, ~1 min 43).
                    L'aventure : la ronde des toms, le marimba qui sautille, la mélodie en onde carrée,
                    la flûte qui lui répond, un passage plus mystérieux (la jungle, le volcan) et le
                    retour de l'air, avec le xylophone.
  clan_du_feu.ogg   « Le Clan du Feu » : la mineur pentatonique, 96 à la noire, en boucle (32 mesures,
                    ~1 min 20). Autour du feu : le tambour de Boum, les mains qui claquent, la flûte
                    d'os, le marimba, et les « Hou ! Ha ! » du Clan (des voix synthétisées).

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/compose_musique_v90.py [--vsco <VSCO-2-CE>] [--vcsl <VCSL>] [--cc0 <CC0-…>] [morceaux…]
"""
from __future__ import annotations

from pathlib import Path
import gc
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v76 as m76  # noqa: E402

m75, cm70, cm51 = m76.m75, m76.cm70, m76.cm51
SR = m75.SR
Song, play, melody = m75.Song, m75.play, m75.melody
filt, bw, echo, hz = m75.filt, m75.bw, m75.echo, m75.hz
notes_of = m76.notes_of


# =========================================================================== les instruments « 8 bits »

def pulse(m, dur, vel=0.5, duty=0.25, rng=None):
    f = hz(m)
    n = int((dur + 0.08) * SR)
    t = np.arange(n) / SR
    ph = (t * f) % 1.0
    y = np.where(ph < duty, 1.0, -1.0)
    y = filt(y, bw("lowpass", 6000))
    env = np.clip(t / 0.004, 0, 1) * np.where(t < dur, 0.85 + 0.15 * np.exp(-t / 0.08), np.exp(-(t - dur) / 0.03))
    vib = 1.0
    return y * env * vel * 0.35 * vib


def tri(m, dur, vel=0.6, rng=None):
    f = hz(m)
    n = int((dur + 0.05) * SR)
    t = np.arange(n) / SR
    ph = (t * f) % 1.0
    y = 4.0 * np.abs(ph - 0.5) - 1.0
    y = np.round(y * 8) / 8           # la triangle « en escalier » des vieilles consoles
    env = np.where(t < dur, 1.0, np.exp(-(t - dur) / 0.02))
    return y * env * vel * 0.5


def bruit(dur, vel=0.4, ton=8000.0, seed=0):
    n = int(dur * SR)
    rng = np.random.default_rng(seed)
    y = rng.standard_normal(n)
    y = np.repeat(y[::4], 4)[:n]       # un bruit un peu « granuleux »
    y = filt(y, bw("highpass", ton * 0.5))
    t = np.arange(n) / SR
    return y * np.exp(-t / (dur * 0.3)) * vel


def hou(m, dur, vel, voyelle="o"):
    """Un « Hou ! » / « Ha ! » du Clan (voix à formants, V58)."""
    import generate_sons_v58 as s58
    y = s58.formant_voice(hz(m), dur, voyelle)
    n = len(y)
    t = np.arange(n) / SR
    env = np.clip(t / 0.02, 0, 1) * np.exp(-t / (dur * 0.5))
    return y * env * vel


def chip_melody(S, bus, bar0, text, vel=0.5, duty=0.25, octave=0):
    for bi, b in enumerate(text.split("|")):
        beat = 0.0
        for tok in b.split():
            nm, d = tok.split(":")
            d = float(d)
            if nm != "r":
                m = m75.midi_of(nm) + 12 * octave
                S.add(bus, pulse(m, d * S.spb * 0.92, vel, duty), S.t(bar0 + bi, beat), 1.0)
            beat += d


# =========================================================================== L'Île Pixelithique

PIX = {
    "Dm": ("D2", "D3 F3 A3"), "C": ("C2", "C3 E3 G3"), "G": ("G1", "G3 B3 D4"), "Am": ("A1", "A3 C4 E4"),
    "F": ("F1", "F3 A3 C4"), "Bb": ("A#1", "A#2 D3 F3"), "Em": ("E2", "E3 G3 B3"),
}


def pixelithique(kit) -> Song:
    S = Song("pixelithique", 112, 48, loop=True, seed=901)
    rng = np.random.default_rng(9010)
    A = ["Dm", "Dm", "C", "C", "Dm", "Dm", "G", "Am"]
    B = ["F", "C", "Dm", "Am", "Bb", "F", "G", "Am"]
    Cc = ["Dm", "Bb", "C", "Am", "Dm", "Bb", "Em", "Am"]
    prog = A + A + B + Cc + A + B
    mA = "D5:1 F5:0.5 G5:0.5 A5:1 C6:1 | A5:2 G5:1 F5:1 | E5:1 G5:0.5 E5:0.5 C5:2 | r:1 E5:1 G5:1 C6:1 | D6:1 C6:0.5 A5:0.5 G5:1 F5:1 | A5:3 r:1 | G5:1 B5:1 D6:1 B5:1 | A5:4"
    mB = "A5:1.5 C6:0.5 A5:1 F5:1 | G5:2 E5:2 | F5:1 A5:1 D6:2 | C6:1 A5:1 E5:2 | F5:1.5 D5:0.5 F5:1 A#5:1 | A5:2 F5:2 | G5:1 B5:1 D6:1 G6:1 | E6:4"
    mC = "D5:2 A4:2 | A#4:2 F5:2 | E5:2 C5:2 | A4:4 | D5:1 F5:1 A5:2 | A#5:2 F5:2 | G5:1 B5:1 E5:2 | A4:4"
    for i, c in enumerate(prog):
        bass, notes = notes_of(PIX, c)
        sec = i // 8
        # la basse triangle, en croches qui rebondissent
        for b in range(8):
            m = bass + 12 + (12 if b % 2 else 0)
            S.add("tri", tri(m, S.spb * 0.45, 0.6), S.t(i, b * 0.5), 1.0)
        # le marimba qui sautille (arpèges)
        if sec != 3:
            for b in range(8):
                play(S, "marimba", "mar", notes[(b * 2 + i) % 3] + 12, i, b * 0.5, 0.5, 0.35 + 0.1 * (b % 2 == 0))
        # la ronde des toms (préhistoire !) et le bruit-charleston
        for b in range(4):
            play(S, "tom", "perc", 45, i, b, 0.5, 0.55 if b in (0, 2) else 0.35)
            S.add("noise", bruit(0.06, 0.25, 9000.0, i * 4 + b), S.t(i, b + 0.5), 1.0)
        if b == 3 and i % 2 == 1:
            play(S, "cadre", "perc", 45, i, 3.5, 0.5, 0.5)
        play(S, "gc", "perc", 36, i, 0, 1, 0.5)
        if i % 4 == 3:
            for k in range(4):
                play(S, "tom_b", "perc", 45, i, 2 + k * 0.5, 0.5, 0.45 + k * 0.08)
        # la nappe en pizzicati (la jungle)
        if sec == 3:
            for b in range(4):
                play(S, "vln_pizz", "pizz", notes[b % 3] + 24, i, b, 1, 0.4)
            play(S, "cb_pizz", "pizz", bass + 12, i, 0, 2, 0.5)
    chip_melody(S, "chip", 0, mA, 0.55, 0.25)
    chip_melody(S, "chip", 8, mA, 0.5, 0.125)
    melody(S, "flute", "flute", 8, mA, 0.35, legato=0.05)
    chip_melody(S, "chip", 16, mB, 0.55, 0.25)
    melody(S, "xylo", "xylo", 16, mB, 0.3)
    melody(S, "flute", "flute", 24, mC, 0.45, legato=0.08)
    chip_melody(S, "chip2", 24, mC, 0.25, 0.5, octave=1)
    chip_melody(S, "chip", 32, mA, 0.55, 0.25)
    melody(S, "xylo", "xylo", 32, mA, 0.25)
    chip_melody(S, "chip", 40, mB, 0.55, 0.125)
    melody(S, "flute", "flute", 40, mB, 0.35, legato=0.05)
    S.fx["tri"] = lambda x: x * 0.9
    S.fx["mar"] = lambda x: x * 0.8
    S.fx["perc"] = lambda x: x * 0.9
    S.fx["noise"] = lambda x: x * 0.5
    S.fx["chip"] = lambda x: echo(x, S.spb * 0.75, 0.22, 2, 5000, True, True) * 0.75
    S.fx["chip2"] = lambda x: echo(x, S.spb * 0.5, 0.3, 3, 5000, True, True) * 0.6
    S.fx["flute"] = lambda x: x * 0.9
    S.fx["xylo"] = lambda x: x * 0.8
    S.fx["pizz"] = lambda x: x * 0.85
    S.send.update({"tri": 0.1, "mar": 0.3, "perc": 0.3, "noise": 0.15, "chip": 0.25, "chip2": 0.4, "flute": 0.45, "xylo": 0.35, "pizz": 0.4})
    return S


# =========================================================================== Le Clan du Feu

FEU = {"Am": ("A1", "A3 C4 E4"), "G": ("G1", "G3 B3 D4"), "Em": ("E2", "E3 G3 B3"), "D": ("D2", "D3 F#3 A3"), "C": ("C2", "C3 E3 G3")}


def clan_du_feu(kit) -> Song:
    S = Song("clan_du_feu", 96, 32, loop=True, seed=902)
    rng = np.random.default_rng(9020)
    A = ["Am", "Am", "G", "Am", "Am", "Am", "Em", "Am"]
    B = ["C", "G", "Am", "Em", "C", "G", "Em", "Am"]
    prog = A + A + B + A
    mA = "A4:1 C5:1 D5:1 E5:1 | D5:0.5 C5:0.5 A4:1 G4:2 | A4:1 C5:1 E5:1 G5:1 | E5:4 | D5:1 E5:1 G5:1 E5:1 | D5:1 C5:1 A4:2 | G4:1 A4:1 C5:1 B4:1 | A4:4"
    mB = "E5:1.5 G5:0.5 E5:1 D5:1 | D5:2 B4:2 | C5:1 E5:1 A5:2 | G5:1 E5:1 B4:2 | C5:1 E5:1 G5:1 A5:1 | G5:2 D5:2 | E5:1 G5:1 B4:2 | A4:4"
    for i, c in enumerate(prog):
        bass, notes = notes_of(FEU, c)
        # le tambour de Boum : boum… boum-boum
        for b, v in ((0, 0.7), (1.5, 0.5), (2, 0.6), (3.5, 0.45)):
            play(S, "cadre", "perc", 45, i, b, 0.5, v)
        play(S, "gc", "perc", 36, i, 0, 1, 0.55)
        for b in range(4):
            play(S, "tom", "perc", 45, i, b + 0.5, 0.5, 0.28)
        if i >= 8:
            play(S, "claque", "perc", 60, i, 1, 0.5, 0.5)
            play(S, "claque", "perc", 60, i, 3, 0.5, 0.5)
        play(S, "cb_pizz", "low", bass + 12, i, 0, 2, 0.55)
        play(S, "cb_pizz", "low", bass + 19, i, 2, 2, 0.4)
        for b in range(4):
            play(S, "marimba", "mar", notes[b % 3] + 12, i, b, 1, 0.3)
        # les « Hou ! Ha ! » du Clan
        if i % 4 == 3 and i >= 8:
            S.add("voix", hou(57, 0.4, 0.5, "o"), S.t(i, 2.0), 1.0, -0.3)
            S.add("voix", hou(52, 0.35, 0.6, "a"), S.t(i, 3.0), 1.0, 0.3)
    melody(S, "flute", "flute", 0, mA, 0.45, legato=0.06)
    melody(S, "flute", "flute", 8, mA, 0.4, legato=0.06)
    chip_melody(S, "chip", 8, mA, 0.25, 0.25, octave=1)
    melody(S, "flute", "flute", 16, mB, 0.5, legato=0.06)
    melody(S, "xylo", "xylo", 16, mB, 0.25)
    melody(S, "flute", "flute", 24, mA, 0.45, legato=0.06)
    S.fx["perc"] = lambda x: x * 0.95
    S.fx["low"] = lambda x: x * 0.8
    S.fx["mar"] = lambda x: x * 0.7
    S.fx["voix"] = lambda x: filt(x, bw("highpass", 120)) * 0.9
    S.fx["flute"] = lambda x: x * 0.9
    S.fx["xylo"] = lambda x: x * 0.8
    S.fx["chip"] = lambda x: echo(x, S.spb * 0.75, 0.25, 2, 5000, True, True) * 0.6
    S.send.update({"perc": 0.35, "low": 0.25, "mar": 0.35, "voix": 0.5, "flute": 0.5, "xylo": 0.35, "chip": 0.3})
    return S


PIECES = {
    "pixelithique": (pixelithique, -18.5, (1.6, 0.5, 0.015, 16, 0.05), (-20.0, 1.8)),
    "clan_du_feu": (clan_du_feu, -19.0, (2.2, 0.5, 0.02, 16, 0.06), (-20.0, 1.6)),
}


def main() -> int:
    args = sys.argv[1:]
    names = []
    while args:
        a = args.pop(0)
        if a == "--vsco":
            m76.VSCO = Path(args.pop(0))
        elif a == "--vcsl":
            m76.VCSL = Path(args.pop(0))
        elif a == "--cc0":
            m76.CC0 = Path(args.pop(0))
        else:
            names.append(a)
    m75.VSCO, m75.VCSL, m75.CC0 = m76.VSCO, m76.VCSL, m76.CC0
    m75.TMP = Path(m75.tempfile.gettempdir()) / "musique_v90"
    cm70.VCSL = m76.VCSL
    cm51.VSCO = m76.VSCO
    import generate_sons_v63 as s63
    s63.LIB = m76.CC0
    kit = m75.Kit(seed=90)
    for name in names or list(PIECES):
        fn, target, (sec, dark, pre, er, span), glue = PIECES[name]
        S = fn(kit)
        ir = m75.room_ir(sec, dark, pre, er, S.seed, span)
        S.render(m76.OUT / f"{name}.ogg", target, -2.0, ir, glue, None)
        m76.release_instruments()
        del S
        gc.collect()
    try:
        m75.TMP.rmdir()
    except OSError:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
