"""V99 : la musique de l'Île Crayonnée (composée ici, versée au domaine public, CC0 1.0).

  musique/crayonnee.ogg  « La Page Blanche » : une petite valse à trois temps, comme une boîte à
                         musique qu'on remonterait au bord d'un cahier de coloriage. Ré majeur, puis
                         si mineur, 64 mesures en boucle (~1 min 27), la noire à 132 par minute.
                         Le célesta (la boîte à musique) chante l'air, la harpe égrène les accords,
                         les cordes en pizzicati font le « poum-pa-pa » de la valse, la flûte reprend
                         l'air la troisième fois, le glockenspiel scintille à la fin.
                         Harpe, pizzicati, flûte, glockenspiel : VSCO-2 CE (Versilian Studios, CC0).
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/compose_musique_v99.py [--vsco <VSCO-2-CE>] [--vcsl <VCSL>]
"""
from __future__ import annotations

from pathlib import Path
import gc
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v75 as m75  # noqa: E402

SR = m75.SR
Song = m75.Song
filt, bw, shelf, room_ir, echo = m75.filt, m75.bw, m75.shelf, m75.room_ir, m75.echo
RNG = np.random.default_rng(9999)

# l'air (A : ré majeur ; B : si mineur), en noires (3 par mesure)
AIR_A = ("F#5:2 A5:1 | D6:3 | C#6:1 B5:1 A5:1 | F#5:3 | G5:2 B5:1 | E6:2 D6:1 | C#6:3 | A5:3 | "
         "B5:2 D6:1 | G6:3 | F#6:1 E6:1 D6:1 | B5:3 | G5:1 A5:1 B5:1 | C#6:2 E6:1 | D6:3 | r:3")
AIR_B = ("B5:2 C#6:1 | D6:2 B5:1 | F#5:3 | F#5:3 | G5:2 A5:1 | B5:2 G5:1 | E5:3 | r:3 | "
         "A5:2 B5:1 | C#6:2 A5:1 | E6:3 | D6:1 C#6:1 B5:1 | A#5:2 B5:1 | C#6:2 A#5:1 | B5:3 | F#5:3")
PROG_A = ["D", "D", "A7", "D", "G", "Em", "A", "A", "G", "G", "D", "Bm", "Em", "A7", "D", "D"]
PROG_B = ["Bm", "Bm", "Bm", "F#", "G", "G", "Em", "Em", "A", "A", "A", "A", "F#", "F#", "Bm", "F#"]
CHORDS = {"D": [62, 66, 69], "A7": [61, 64, 67], "G": [59, 62, 67], "Em": [59, 64, 67], "A": [61, 64, 69],
          "Bm": [59, 62, 66], "F#": [58, 61, 66]}
ROOTS = {"D": 38, "A7": 33, "G": 31, "Em": 40, "A": 33, "Bm": 35, "F#": 30}


def crayonnee() -> Song:
    S = Song("crayonnee", 132, 64, beats=3, loop=True, seed=99)
    cel = lambda m, d, v: m75.celesta(m, d, v, RNG)
    sections = [(0, AIR_A, PROG_A, "boite"), (16, AIR_B, PROG_B, "boite"), (32, AIR_A, PROG_A, "flute"), (48, AIR_A, PROG_A, "tutti")]
    for bar0, air, prog, lead in sections:
        if lead in ("boite", "tutti"):
            m75.melody(S, None, "celesta", bar0, air, 0.6 if lead == "boite" else 0.5, synth=cel)
        if lead == "flute":
            m75.melody(S, "flute", "flute", bar0, air, 0.45, octave=-1, legato=0.08)
            # la boîte à musique, plus discrète, une octave plus haut, une note sur deux
            m75.melody(S, None, "celesta", bar0, air, 0.25, octave=1, synth=cel)
        for i, sym in enumerate(prog):
            bar = bar0 + i
            ch = CHORDS[sym]
            # le « poum » : la contrebasse en pizzicato sur le premier temps
            m75.play(S, "cb_pizz", "basse", ROOTS[sym] + 12, bar, 0.0, 1.0, 0.75)
            # le « pa-pa » : les violons en pizzicati sur les temps 2 et 3
            for b in (1.0, 2.0):
                for m in ch:
                    m75.play(S, "vln_pizz", "pizz", m, bar, b, 0.5, 0.42 if b == 1.0 else 0.36)
            # la harpe : l'accord égrené, une mesure sur deux
            if i % 2 == 0:
                ns = sorted({m + 12 * o for m in ch for o in (-1, 0)})
                for k, m in enumerate(ns):
                    m75.play(S, "harp", "harp", m, bar, k * 0.22, 2.0, 0.4)
            # le glockenspiel, à la fin : la tierce et la quinte de l'accord, en haut
            if lead == "tutti" and i % 2 == 1:
                m75.play(S, "glock", "glock", ch[1] + 24, bar, 0.0, 1.0, 0.3)
                m75.play(S, "glock", "glock", ch[2] + 24, bar, 1.5, 1.0, 0.25)
    S.fx["celesta"] = lambda x: echo(x, S.spb * 1.5, 0.25, 3, 5000, True, True) * 1.1
    S.fx["flute"] = lambda x: x * 1.2
    S.fx["basse"] = lambda x: x * 1.2
    S.fx["pizz"] = lambda x: filt(x, shelf(5000, -2.0)) * 0.8
    S.fx["harp"] = lambda x: x * 0.9
    S.fx["glock"] = lambda x: x * 0.45
    S.send.update({"celesta": 0.45, "flute": 0.4, "basse": 0.1, "pizz": 0.25, "harp": 0.45, "glock": 0.5})
    return S


def main() -> int:
    args = sys.argv[1:]
    while args:
        a = args.pop(0)
        if a == "--vcsl":
            m75.VCSL = Path(args.pop(0))
        elif a == "--vsco":
            m75.VSCO = Path(args.pop(0))
    S = crayonnee()
    ir = room_ir(1.8, 0.6, 0.014, 14, S.seed, 0.06)
    S.render(m75.OUT / "crayonnee.ogg", -19.0, -2.0, ir, (-18.0, 2.0), None)
    m75.release_instruments()
    gc.collect()
    print("V99 : crayonnee.ogg")
    return 0


if __name__ == "__main__":
    sys.exit(main())
