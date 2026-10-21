"""V61 : « La Valse des Engrenages », la musique de Cliquetis, la cité des ingénieurs fous.

Composition originale pour Île Manga, versée au domaine public (CC0 1.0), jouée par
l'orchestre VSCO-2 (CC0) avec les outils de la V51 (compose_musique_v51.py, orchestre_v51.py).
Une valse mécanique à 3/4, 138 à la noire : l'« oum-pa-pa » des pizzicati (contrebasse, puis les
violoncelles et les altos sur les deux temps faibles), un tic-tac de wood-blocks sur chaque
temps, comme une horloge ; le basson joue l'air en sol mineur, un peu de travers, la clarinette
le reprend ; puis tout passe en sol majeur : la flûte et le glockenspiel, comme une boîte à
musique ; le marimba et le hautbois font le pont ; à la fin, tout le monde, et le triangle.

Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/compose_musique_v61.py <dossier VSCO-2-CE>
"""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v51 as cm  # noqa: E402


def cliquetis():
    P = cm.Piece("cliquetis", 138, 60, beats=3, seed=611, room=2.2)
    A = ["Gm", "D7", "Gm", "Cm", "Gm", "D7", "Eb D7", "Gm"]
    B = ["G", "Em", "C", "D", "G", "Em", "Am D", "G"]
    intro = ["Gm", "D7", "Gm", "D7"]
    bridge = ["Eb", "Cm", "D", "D7"]
    outro = ["Gm", "D7", "Gm", "Gm"]
    prog = intro + A + A + B + B + A + bridge + A + outro
    melA = ("G3:1 A3:0.5 Bb3:0.5 D4:1 | F#3:1.5 A3:0.5 C4:1 | Bb3:0.5 A3:0.5 G3:1 D4:1 | Eb4:1.5 D4:0.5 C4:1 | "
            "Bb3:1 A3:0.5 G3:0.5 D4:1 | F#3:1 G3:0.5 A3:0.5 C4:1 | Bb3:1 G3:1 F#3:1 | G3:2 r:1")
    melB = ("D5:1 B4:0.5 C5:0.5 D5:1 | E5:1.5 D5:0.5 B4:1 | C5:1 E5:1 G5:1 | F#5:2 D5:1 | "
            "G5:1 F#5:0.5 E5:0.5 D5:1 | B4:1.5 C5:0.5 D5:1 | E5:1 C5:1 F#5:1 | G5:2 r:1")
    # le tic-tac : un wood-block par temps, plus aigu sur le premier
    for b in range(60):
        for beat in range(3):
            P.hit("logdrum_hi" if beat == 0 else "logdrum_lo", b, beat, 0.16 if beat == 0 else 0.1)
        if b % 4 == 0 and b >= 4:
            P.hit("triangle", b, 0, 0.12)
        if 44 <= b < 48:
            for beat2 in (0.5, 1.5, 2.5):
                P.hit("shaker", b, beat2, 0.1)
    # l'oum-pa-pa : la contrebasse sur le temps, les violoncelles et altos sur les temps faibles
    P.bass("cb_pizz", prog, 0, 31, 43, vel=0.4, rhythm=[(0.0, 1.0)])
    P.chord_hits("vc_pizz", prog, 0, 48, 60, [1.0, 2.0], n=2, vel=0.22, dur=0.5)
    P.chord_hits("vla_pizz", prog, 0, 55, 67, [1.0, 2.0], n=2, vel=0.18, dur=0.5)
    # A : le basson, seul et un peu bancal
    P.melody("bsn", 4, melA, vel=0.55, legato=0.03)
    # A' : la clarinette reprend, le basson en contrechant à l'octave
    P.melody("clar", 12, melA, vel=0.5, legato=0.03, octave=1)
    P.melody("bsn", 12, melA, vel=0.3, legato=0.03)
    # B : en majeur, la flûte et le glockenspiel (une boîte à musique)
    P.melody("flute", 20, melB, vel=0.48, legato=0.03)
    P.melody("glock", 20, melB, vel=0.22, legato=0.0, octave=1, swell=False)
    P.pad("vln", B, 20, 62, 74, 2, vel=0.1)
    # B' : tout le monde
    P.melody("flute", 28, melB, vel=0.45, legato=0.03)
    P.melody("clar", 28, melB, vel=0.32, legato=0.03, octave=-1)
    P.melody("solo_vln", 28, melB, vel=0.35, legato=0.03)
    P.pad("horn", B, 28, 50, 62, 2, vel=0.1)
    # A'' : le marimba et le hautbois
    P.melody("marimba", 36, melA, vel=0.5, legato=0.0, octave=1, swell=False)
    P.melody("oboe", 36, melA, vel=0.42, legato=0.03, octave=1)
    # le pont : les cordes montent, les engrenages s'emballent
    P.pad("vln_trem", bridge, 44, 62, 77, 3, vel=0.14)
    P.melody("bsn", 44, "Eb3:1 G3:1 Bb3:1 | C4:1 Eb4:1 G3:1 | F#3:1 A3:1 C4:1 | D4:1.5 C4:0.5 A3:1", vel=0.45)
    # A final : tout le monde
    P.melody("clar", 48, melA, vel=0.45, legato=0.03, octave=1)
    P.melody("bsn", 48, melA, vel=0.42, legato=0.03)
    P.melody("glock", 48, melA, vel=0.16, octave=2, legato=0.0, swell=False)
    P.pad("vln", A, 48, 62, 74, 2, vel=0.1)
    P.melody("bsn", 56, "G3:3 | D3:3 | G3:1 D3:1 G2:1 | r:3", vel=0.4)
    P.hit("cymbal", 57, 0, 0.14)
    return P


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cm.VSCO = Path(sys.argv[1])
    cm.TMP.mkdir(parents=True, exist_ok=True)
    cliquetis().render(cm.OUT / "cliquetis.ogg", rms_db=-21.0)


if __name__ == "__main__":
    main()
