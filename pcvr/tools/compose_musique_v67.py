"""V67 : la musique d'Arcanelle, l'île des sorciers cachée dans les brumes du nord-ouest.

Composition originale pour Île Manga, versée au domaine public (CC0 1.0), jouée par
l'orchestre VSCO-2 (CC0) avec les outils de la V51 (compose_musique_v51.py, orchestre_v51.py).

« La Valse des Grimoires » (arcanelle.ogg) : mi mineur, 3/4, 96 à la noire.
La harpe ouvre les grimoires en arpèges, le glockenspiel scintille comme les orbes des
lanternes ; les violoncelles et les violons en pizzicato font « boum, tic, tic » (la valse
des livres qui s'envolent). La clarinette chante l'air, la flûte le reprend plus haut ;
le violon solo emmène le second thème en sol majeur ; au milieu, le mystère de la crypte :
trémolos de cordes, clarinette grave et arbre à cloches ; à la fin, la flûte et le
glockenspiel reprennent l'air, et la harpe referme le livre sur mi.

Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/compose_musique_v67.py <dossier VSCO-2-CE>
"""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v51 as cm  # noqa: E402


def arcanelle():
    P = cm.Piece("arcanelle", 96, 48, beats=3, seed=671, room=3.2)
    intro = ["Em", "Cmaj7", "Am", "B7"]
    A = ["Em", "Em/D", "Cmaj7", "C", "Am", "B7", "Em", "B7"]
    A2 = ["Em", "Em/D", "Cmaj7", "C", "Am", "B7", "Em", "Em"]
    B = ["G", "D/F#", "Em", "Bm", "C", "G/B", "Am", "B7"]
    bridge = ["Cmaj7", "Bm", "Am", "B7", "Cmaj7", "Bm", "Am", "B7"]
    outro = ["Em", "Cmaj7", "Am B7", "Em"]
    prog = intro + A + A2 + B + bridge + A2 + outro
    melA = ("E5:1 F#5:1 G5:1 | B5:2 A5:1 | G5:1 E5:1 C5:1 | E5:3 | "
            "A5:1 G5:1 F#5:1 | D#5:2 F#5:1 | E5:1 B4:1 G4:1 | B4:3")
    melA2 = ("E5:1 F#5:1 G5:1 | B5:2 C6:1 | B5:1 G5:1 E5:1 | C5:3 | "
             "A4:1 C5:1 E5:1 | D#5:2 B4:1 | E5:3 | r:3")
    melB = ("D5:2 B4:1 | A4:1 D5:1 F#5:1 | G5:2 E5:1 | F#5:2 D5:1 | "
            "E5:1 G5:1 C6:1 | B5:2 G5:1 | A5:1 C6:1 E5:1 | D#5:3")
    myst = ("G4:3 | F#4:3 | E4:2 C5:1 | B4:3 | "
            "G4:2 A4:1 | F#4:2 G4:1 | E4:1 F#4:1 A4:1 | D#4:3")
    # la harpe tout le long : les pages qui tournent
    P.arp("harp", prog, 0, 52, step=0.5, pattern=[0, 2, 4, 5, 4, 2], vel=0.22, span=2)
    # la valse : « boum » des violoncelles, « tic, tic » des violons (sauf au mystère)
    waltz = intro + A + A2 + B
    P.bass("vc_pizz", waltz, 0, 33, 45, vel=0.34, rhythm=[(0.0, 1.0)])
    P.chord_hits("vln_pizz", waltz, 0, 64, 76, [1.0, 2.0], n=2, vel=0.13, dur=0.5)
    P.bass("vc_pizz", A2 + outro, 36, 33, 45, vel=0.32, rhythm=[(0.0, 1.0)])
    P.chord_hits("vln_pizz", A2, 36, 64, 76, [1.0, 2.0], n=2, vel=0.12, dur=0.5)
    # l'intro : les orbes qui s'allument
    P.sparkle("glock", intro, 0, 76, 91, prob=0.45, vel=0.2, step=1.0)
    P.hit("chimes", 0, 0, 0.22)
    # A : la clarinette, le glockenspiel en écho discret
    P.melody("clar", 4, melA, vel=0.46, legato=0.03)
    P.melody("glock", 8, melA.split("|", 4)[4], vel=0.16, octave=1)
    P.pad("vla", A, 4, 55, 67, 2, vel=0.07)
    # A2 : la flûte, à l'octave
    P.melody("flute", 12, melA2, vel=0.44, legato=0.03)
    P.melody("clar", 12, melA2, vel=0.18, legato=0.03, octave=-1)
    P.pad("vln", A2, 12, 64, 76, 2, vel=0.07)
    # B : le violon solo en sol majeur, le cor tenu
    P.melody("solo_vln", 20, melB, vel=0.42, legato=0.04)
    P.melody("flute", 24, melB.split("|", 4)[4], vel=0.2, legato=0.03, octave=1)
    P.pad("horn", B, 20, 50, 62, 2, vel=0.07)
    P.hit("triangle", 20, 0, 0.1)
    # le mystère de la crypte : trémolos, clarinette grave, arbre à cloches
    P.pad("vln_trem", bridge, 28, 62, 76, 3, vel=0.09)
    P.pad("vc", bridge, 28, 40, 52, 1, vel=0.1)
    P.melody("clar", 28, myst, vel=0.4, legato=0.04)
    P.sparkle("glock", bridge, 28, 79, 93, prob=0.3, vel=0.16, step=1.0)
    P.hit("chimes", 28, 0, 0.18)
    P.hit("chimes", 32, 0, 0.16)
    P.note("timp_roll", 40, 34, 0, 6.0, 0.12)
    # le retour : la flûte et le glockenspiel, les cordes amples
    P.melody("flute", 36, melA2, vel=0.46, legato=0.03)
    P.melody("glock", 36, melA2, vel=0.2, octave=1)
    P.pad("vla", A2, 36, 55, 67, 2, vel=0.08)
    P.pad("vln", A2, 36, 67, 79, 2, vel=0.06)
    # la fin : la harpe referme le livre
    P.melody("glock", 44, "B5:3 | G5:3 | E5:1.5 F#5:1.5 | E5:3", vel=0.2)
    P.hit("chimes", 47, 0, 0.16)
    return P


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cm.VSCO = Path(sys.argv[1])
    cm.TMP.mkdir(parents=True, exist_ok=True)
    arcanelle().render(cm.OUT / "arcanelle.ogg", rms_db=-21.0)


if __name__ == "__main__":
    main()
