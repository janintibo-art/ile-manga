"""V93 : la musique du Festival du Larsen.

Composition originale pour « Les Mondes de Travers », versée au domaine public (CC0 1.0). Jouée avec les
outils de la V75 et de la V91 (cordes de Karplus-Strong, ampli simulé, batterie de la VCSL, flûte et
glockenspiel de VSCO-2 CE, la foule) : les deux villages sur la même scène.

  festival_larsen.ogg  « Le Soleil et la Pluie » : sol majeur, 112 à la noire, en boucle (32 mesures,
                       ~1 min 09). Le couplet est au Camp des Fleurs (la guitare acoustique grattée, les
                       mains sur les djembés, le tambourin, la flûte chante l'air) ; le refrain est à
                       Rainville (deux guitares saturées, la batterie, la basse, la foule crie « hey ! »)
                       — et les djembés continuent dessous. Deuxième couplet : la guitare de Rainville
                       fait des arpèges sous la flûte ; dernier refrain : tout le monde, la flûte une
                       octave plus haut, la guitare solo, le glockenspiel.

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/compose_musique_v93.py [--vsco <VSCO-2-CE>] [--vcsl <VCSL>]
"""
from __future__ import annotations

from pathlib import Path
import gc
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v75 as m75  # noqa: E402
import compose_musique_v91 as m91  # noqa: E402

Song, drums, Band, lead, Guitar = m75.Song, m75.drums, m75.Band, m75.lead, m75.Guitar
filt, bw, shelf, pan2, melody, room_ir = m75.filt, m75.bw, m75.shelf, m75.pan2, m75.melody, m75.room_ir


def festival_larsen(kit) -> Song:
    S = Song("festival_larsen", 112, 32, loop=True, seed=931)
    B = Band(S, kit, 9310, lo=40, tight=0.006)
    ac = Guitar(S, "ac1", 9311, jitter=0.006, bright=0.62, pickup=0.2, lo=43)
    verse = ["G", "D", "Em", "C"] * 2
    chorus = ["G5", "D5", "E5", "C5", "G5", "D5", "C5", "D5"]
    chorus_ac = ["G", "D", "Em", "C", "G", "D", "C", "D"]
    air = ("D5:1 G5:1 B5:1.5 A5:0.5 | A5:1 F#5:1 D5:2 | E5:1 G5:1 B5:1 G5:1 | E5:3 r:1 | "
           "D5:1 G5:1 B5:1.5 C6:0.5 | D6:1 B5:1 A5:2 | G5:1.5 E5:0.5 C5:1 E5:1 | D5:4")
    refrain = ("B5:1.5 A5:0.5 G5:1 D5:1 | A5:2 F#5:2 | G5:1 B5:1 E6:1.5 D6:0.5 | C6:2 G5:2 | "
               "B5:1.5 A5:0.5 G5:1 B5:1 | A5:2 D6:2 | C6:1 B5:1 A5:1 G5:1 | ~A5:4")
    solo = ("D5:1.5 B4:0.5 A4:1 G4:1 | ^A4:2 F#4:1 D4:1 | E4:1 G4:1 B4:1.5 A4:0.5 | ~G4:4 | "
            "D5:1.5 B4:0.5 A4:1 G4:1 | A4:1 B4:1 ^D5:2 | C5:1 B4:1 A4:1 B4:1 | ~A4:4")
    fort = {"k": "X.....x.X.....x.", "s": "....X.......X...", "h": "x.x.x.x.x.x.x.x."}
    for sec in (0, 16):
        # le couplet du Camp des Fleurs
        ac.rhythm(sec, verse, "O-Ou-uOu", "full", 0.85 if sec == 0 else 0.8)
        B.bass.line(sec, verse, "R--.f--.", 0.75)
        for i in range(8):
            drums(S, kit, sec + i, {"tb": "..x...x...x...x.", "2": "X.......x.x.....", "4": "....x.......x..x"}, 0.62)
        melody(S, "flute", "flute", sec, air, 0.58)
        if sec == 16:
            for i, sym in enumerate(verse):
                notes = m75.voice(sym, "full", 52)
                text = " ".join(f"{m75.NAMES[n % 12]}{n // 12 - 1}:0.5" for n in [notes[0], notes[2], notes[3], notes[4], notes[3], notes[2], notes[4], notes[1]])
                B.gC.riff(sec + i, text, 0.55)
        # le refrain de Rainville (et les djembés dessous)
        c0 = sec + 8
        B.gtr(c0, chorus, ["O-------", "O-----o-", "O-------", "O---O-O-"], "5", 0.95)
        ac.rhythm(c0, chorus_ac, "O-Ou-uOu", "full", 0.7)
        B.bass.line(c0, chorus, "R-r-R-r-", 1.0)
        B.drum_section(c0, 8, fort, 0.95, crash_every=4, fills={7: "toms" if sec == 0 else "snare8"})
        for i in range(8):
            drums(S, kit, c0 + i, {"2": "X.x.....X.x.x...", "4": "....x..x....x..x", "tb": "x.x.x.x.x.x.x.x."}, 0.6)
        for k in (0, 4):
            B.shout(c0 + k, 0.0, 0.8)
        melody(S, "flute", "flute", c0, refrain, 0.6 if sec == 0 else 0.68)
        if sec == 16:
            lead(S, "lead", c0, solo, 93102, vel=0.8, vib=0.3)
            for i, sym in enumerate(chorus_ac):
                r = m75.parse_chord(sym)[0]
                for k2, b in enumerate((0.0, 1.5, 3.0)):
                    m75.play(S, "glock", "glock", m75.root_in(r, 84) + (0, 7, 12)[k2], c0 + i, b, 1.0, 0.32)
    B.mix(False, gtr_gain=48.0, gtr_level=0.12, bass_level=1.9, lead_level=0.1, crowd_level=0.3)
    S.fx["ac1"] = lambda x: pan2(m91.acoustique(x), -0.4, 0.8) * 0.85
    S.fx["flute"] = lambda x: filt(x, shelf(9000, -1.5)) * 1.0
    S.fx["glock"] = lambda x: x * 0.45
    S.send.update({"ac1": 0.14, "flute": 0.3, "glock": 0.35})
    return S


PIECES = {"festival_larsen": (festival_larsen, -18.0)}


def main() -> int:
    args = sys.argv[1:]
    names = []
    while args:
        a = args.pop(0)
        if a == "--vsco":
            m75.VSCO = Path(args.pop(0))
        elif a == "--vcsl":
            m75.VCSL = Path(args.pop(0))
        else:
            names.append(a)
    kit = m75.Kit()
    for name in names or list(PIECES):
        fn, target = PIECES[name]
        S = fn(kit)
        ir = room_ir(1.6, 0.55, 0.015, 14, S.seed, 0.05)
        S.render(m75.OUT / f"{name}.ogg", target, -2.0, ir, (-18.0, 2.0), None)
        m75.release_instruments()
        del S
        gc.collect()
    return 0


if __name__ == "__main__":
    sys.exit(main())
