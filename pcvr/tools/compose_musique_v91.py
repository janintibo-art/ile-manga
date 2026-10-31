"""V91 : les musiques de l'Île de Larsen.

Compositions originales pour « Les Mondes de Travers », versées au domaine public (CC0 1.0). Jouées avec
les outils de la V75 (le morceau, ses bus, les cordes de Karplus-Strong, l'ampli simulé, la batterie de
la VCSL, la salle, le mastering, la boucle sans raccord) et les instruments de VSCO-2 CE (Versilian
Studios, CC0) : flûte, glockenspiel, contrebasse en pizzicati.

  camp_des_fleurs.ogg  « Le Camp des Fleurs » : sol majeur, 104 à la noire, en boucle (32 mesures,
                       ~1 min 14). Une guitare acoustique grattée (bas, bas-haut, haut-bas-haut), une
                       deuxième qui fait des arpèges, la contrebasse en pizzicati, le tambourin, des mains
                       sur un djembé ; la flûte chante l'air, le glockenspiel scintille au refrain.
  rainville.ogg        « Rainville » : ré mineur (guitares accordées en ré grave), 88 à la noire, en boucle
                       (32 mesures, ~1 min 27). Grunge : un couplet tout calme (une guitare presque claire
                       en arpèges, la basse, la batterie au cerclage), puis le refrain qui explose (deux
                       guitares saturées à gauche et à droite, la cymbale qui lave tout, la guitare solo qui
                       pleure) ; deuxième couplet, deuxième refrain, et la boucle repart.

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/compose_musique_v91.py [--vsco <VSCO-2-CE>] [--vcsl <VCSL>] [morceaux…]
"""
from __future__ import annotations

from pathlib import Path
import gc
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v75 as m75  # noqa: E402

SR = m75.SR
Song, drums, fill, Band, lead = m75.Song, m75.drums, m75.fill, m75.Band, m75.lead
Guitar, Bass = m75.Guitar, m75.Bass
filt, bw, peak, shelf, pan2 = m75.filt, m75.bw, m75.peak, m75.shelf, m75.pan2
melody, room_ir, drum_fx = m75.melody, m75.room_ir, m75.drum_fx


# =========================================================================== « Le Camp des Fleurs »

def acoustique(x: np.ndarray) -> np.ndarray:
    """Une guitare acoustique : la corde passe dans la caisse (la bosse grave du bois, le corps, l'air
    de la rosace), pas d'ampli."""
    y = filt(x.astype(np.float64), bw("highpass", 85), peak(110, 5.0, 1.2), peak(220, 3.0, 1.0), peak(1200, -2.0, 0.8),
             peak(3200, 3.0, 1.0), bw("lowpass", 11000, 2))
    return m75.compress(y, -20, 2.5, 0.006, 0.12).astype(np.float32)


def camp_des_fleurs(kit) -> Song:
    S = Song("camp_des_fleurs", 104, 32, loop=True, seed=911)
    strum = Guitar(S, "ac1", 9111, jitter=0.006, bright=0.62, pickup=0.2, lo=43)
    arp = Guitar(S, "ac2", 9112, jitter=0.004, bright=0.7, pickup=0.22, lo=55)
    bass = Bass(S, "basse", 9113, lo=31, t60=1.0, bright=0.2)
    verse = ["G", "Em", "C", "D"] * 2
    chorus = ["C", "G", "Am", "D", "C", "G", "D", "G"]
    # la flûte : l'air, puis le refrain
    air = ("B4:1 D5:1 G5:1.5 F#5:0.5 | E5:1 G5:1 B4:2 | C5:1 E5:1 G5:1 E5:1 | D5:3 r:1 | "
           "B4:1 D5:1 G5:1.5 A5:0.5 | B5:1 G5:1 E5:2 | C5:1.5 B4:0.5 A4:1 C5:1 | D5:4")
    refrain = ("E5:1 G5:1 C6:1.5 B5:0.5 | B5:1 G5:1 D5:2 | C5:1 E5:1 A5:1.5 G5:0.5 | F#5:2 A5:2 | "
               "E5:1 G5:1 C6:1.5 B5:0.5 | B5:1 G5:1 D5:1 B4:1 | A4:1 C5:1 F#5:1 A5:1 | G5:3 r:1")
    for sec, prog in ((0, verse), (8, chorus), (16, verse), (24, chorus)):
        strum.rhythm(sec, prog, "O-Ou-uOu", "full", 0.85 if sec in (0, 16) else 1.0)
        bass.line(sec, prog, ["r--.f--.", "r--.f-a."], 0.95)
        if sec in (16, 24):
            # la deuxième guitare : des arpèges en croches
            for i, sym in enumerate(prog):
                notes = m75.voice(sym, "full", 55)
                text = " ".join(f"{m75.NAMES[n % 12]}{n // 12 - 1}:0.5" for n in [notes[0], notes[2], notes[3], notes[4], notes[3], notes[2], notes[4], notes[1]])
                arp.riff(sec + i, text, 0.55)
        # le tambourin, les mains sur le djembé
        for i in range(8):
            drums(S, kit, sec + i, {"tb": "..x...x...x...x." if sec in (0, 16) else "x.x.x.x.x.x.x.x.",
                                    "2": "X.......x.x.....", "4": "....x.......x..x"}, 0.55 if sec in (0, 16) else 0.7)
    melody(S, "flute", "flute", 0, air, 0.55)
    melody(S, "flute", "flute", 8, refrain, 0.6)
    melody(S, "flute", "flute", 16, air, 0.58)
    melody(S, "flute", "flute", 24, refrain, 0.62)
    # le glockenspiel au refrain : des notes de l'accord, en haut
    for sec in (8, 24):
        for i, sym in enumerate(chorus):
            r = m75.parse_chord(sym)[0]
            for k, b in enumerate((0.0, 1.5, 3.0)):
                m75.play(S, "glock", "glock", m75.root_in(r, 84) + (0, 7, 12)[k], sec + i, b, 1.0, 0.35)
    S.fx["ac1"] = lambda x: pan2(acoustique(x), -0.35, 0.8) * 0.9
    S.fx["ac2"] = lambda x: pan2(acoustique(x), 0.45, 0.6) * 0.6
    S.fx["basse"] = lambda x: m75.bass_amp(x, 1.5) * 1.6
    S.fx["flute"] = lambda x: filt(x, shelf(9000, -1.5)) * 1.0
    S.fx["glock"] = lambda x: x * 0.5
    drum_fx(S, False)
    S.fx["dr_toms"] = lambda x: filt(x, bw("lowpass", 3000)) * 0.6
    S.send.update({"ac1": 0.12, "ac2": 0.18, "basse": 0.03, "flute": 0.3, "glock": 0.35})
    return S


# =========================================================================== « Rainville »

def rainville(kit) -> Song:
    S = Song("rainville", 88, 32, loop=True, seed=912)
    B = Band(S, kit, 9120, lo=38, tight=0.006)          # ré grave
    verse_p = ["Dm", "F", "G", "Bb"] * 2
    ch_p = ["D5", "C5", "G5", "A5", "D5", "C5", "Bb5", "A5"]
    arpege = ["D3:0.5 A3:0.5 D4:0.5 F4:0.5 A3:0.5 F4:0.5 E4:0.5 D4:0.5", "F3:0.5 C4:0.5 F4:0.5 A4:0.5 C4:0.5 A4:0.5 G4:0.5 F4:0.5",
              "G3:0.5 D4:0.5 G4:0.5 Bb4:0.5 D4:0.5 Bb4:0.5 A4:0.5 G4:0.5", "Bb2:0.5 F3:0.5 Bb3:0.5 D4:0.5 F3:0.5 D4:0.5 C4:0.5 A3:0.5"]
    calme = {"k": "X.......X.x.....", "x": "....x.......x...", "h": "x.x.x.x.x.x.x.x."}
    fort = {"k": "X.....x.X.....x.", "s": "....X.......X...", "l": "x.x.x.x.x.x.x.x."}
    solo = ("A4:1.5 G4:0.5 F4:1 D4:1 | ^F4:2 E4:1 D4:1 | A4:1.5 C5:0.5 A4:1 G4:1 | ~A4:4 | "
            "A4:1.5 G4:0.5 F4:1 D4:1 | F4:1 G4:1 ^A4:2 | C5:1 A4:1 G4:1 F4:1 | ~D4:4")
    hum = ("r:2 D4:1 F4:1 | E4:2 D4:2 | r:2 G4:1 F4:1 | D4:4 | r:2 D4:1 F4:1 | A4:2 G4:2 | F4:2 E4:1 C4:1 | D4:4")
    for sec in (0, 16):
        # le couplet : la guitare presque claire en arpèges, la basse, la batterie au cerclage
        B.gC.riff(sec, " | ".join(arpege * 2), 0.75)
        B.bass.line(sec, verse_p, "R---r-f-", 0.8)
        B.drum_section(sec, 8, calme, 0.7, fills={7: {"k": "X.......X.......", "s": "........o.x.xXXX", "h": "x.x.x.x........."}}, first_crash=sec == 0)
        if sec == 16:
            lead(S, "lead", sec, hum, 91201, octave=-1, vel=0.45, vib=0.15, bright=0.5)
        # le refrain : tout explose
        c0 = sec + 8
        B.gtr(c0, ch_p, ["O-------", "O-----o-", "O-------", "O---O-O-"], "5", 1.0)
        B.bass.line(c0, ch_p, "R-------", 1.0)
        B.drum_section(c0, 8, fort, 1.0, crash_every=4, fills={7: "toms" if sec == 0 else "snare8"})
        lead(S, "lead", c0, solo, 91202 + sec, vel=0.85, vib=0.3)
    B.mix(False, gtr_gain=58.0, gtr_level=0.13, bass_level=2.0, lead_level=0.1)
    S.fx["gC"] = lambda x: pan2(m75.amp(x, 3.5, bias=0.08, mid=1.0, scoop=-1.0, presence=0.5, cab=6500), -0.25, 1.0) * 0.25
    return S


PIECES = {"camp_des_fleurs": (camp_des_fleurs, -19.0), "rainville": (rainville, -18.5)}


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
        ir = room_ir(1.2, 0.6, 0.012, 14, S.seed, 0.04)
        S.render(m75.OUT / f"{name}.ogg", target, -2.0, ir, (-18.0, 2.0), None)
        m75.release_instruments()
        del S
        gc.collect()
    return 0


if __name__ == "__main__":
    sys.exit(main())
