"""V58 : « Le Royaume des Fées », la musique de l'île au-dessus des nuages et d'Yggdrasil.

Composition originale pour Île Manga, versée au domaine public (CC0 1.0), jouée par
l'orchestre VSCO-2 (CC0) avec les outils de la V51 (compose_musique_v51.py, orchestre_v51.py).
Une valse lente à trois temps, mi majeur aux couleurs lydiennes (le la dièse fait briller l'air),
66 à la noire : la harpe tourne comme des ailes, le glockenspiel sème des lucioles, la flûte
chante le thème, le violon solo lui répond ; au milieu, les cordes et le cor évoquent l'Arbre-Monde,
immense et calme ; la fin s'éteint sur un accord suspendu, comme un vol qui se pose.

Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/compose_musique_v58.py <dossier VSCO-2-CE>
"""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v51 as cm  # noqa: E402


def royaume_fees():
    P = cm.Piece("royaume_fees", 66, 42, beats=3, seed=581, room=3.8)
    intro = ["Emaj7", "F#/E", "Emaj7", "F#/E"]
    A = ["Emaj7", "F#/E", "C#m7", "Amaj7", "Emaj7", "F#/E", "Bsus4", "B"]
    B = ["Amaj7", "B/A", "G#m7", "C#m7", "F#m7", "B", "Emaj7", "F#/E"]
    C = ["C#m7", "Amaj7", "Emaj7", "B", "C#m7", "Amaj7", "F#m7", "Bsus4 B"]
    coda = ["Emaj7", "F#/E", "Amaj7", "Bsus4", "Emaj7", "Emaj7"]
    prog = intro + A + B + C + A + coda
    # le thème (flûte) : il monte comme une fée qui prend son envol
    melA = ("B4:1 E5:1 F#5:1 | G#5:2 A#5:1 | B5:2 G#5:1 | E5:3 | B4:1 E5:1 F#5:1 | G#5:1.5 F#5:0.5 E5:1 | "
            "F#5:3 | r:1 D#5:1 F#5:1")
    melB = ("C#6:2 B5:1 | A5:2 F#5:1 | B5:2 G#5:1 | E5:3 | A5:1 G#5:1 F#5:1 | D#5:2 F#5:1 | G#5:3 | A#5:3")
    melC = ("E5:3 | C#5:2 E5:1 | B4:3 | D#5:2 F#5:1 | E5:2 G#5:1 | A5:2 C#6:1 | B5:3 | A#5:1.5 F#5:1.5")
    # La harpe : des arpèges qui tournent, comme des ailes (trois croches par temps)
    P.arp("harp", prog, 0, 52, step=0.5, pattern=[0, 2, 4, 5, 4, 2], vel=0.34, span=2)
    # Les cordes en nappe, très douces
    P.pad("vla", prog, 0, 56, 68, 2, vel=0.2)
    P.pad("vln", prog[4:], 4, 64, 80, 2, vel=0.17)
    P.bass("vc", prog, 0, 40, 52, vel=0.26)
    P.bass("cb", prog[12:36], 12, 28, 40, vel=0.22)
    # Les lucioles : le glockenspiel, au hasard dans l'accord
    P.sparkle("glock", prog, 0, 76, 91, prob=0.32, vel=0.2)
    P.hit("chimes", 0, 0, 0.35)
    # A : la flûte chante ; la clarinette tient une note en dessous
    P.melody("flute", 4, melA, vel=0.5)
    P.pad("clar", A, 4, 59, 68, 1, vel=0.16)
    # B : le violon solo répond, la flûte à la tierce au-dessus pour la fin de phrase
    P.melody("solo_vln", 12, melB, vel=0.46)
    P.melody("flute", 18, "G#5:3 | A#5:3", vel=0.3, octave=1)
    # C : l'Arbre-Monde — le cor et les violoncelles, larges et calmes ; les timbales roulent
    P.melody("horn", 20, melC, vel=0.46, octave=-1)
    P.melody("vc", 20, melC, vel=0.24, octave=-1)
    P.pad("vln_trem", C, 20, 68, 83, 2, vel=0.12)
    P.hit("timp_roll", 20, 0, 0.16, 6.0, midi=40)
    P.hit("timp_roll", 26, 0, 0.18, 6.0, midi=35)
    P.hit("cymbal", 27, 0, 0.18)
    # A' : la flûte et le violon ensemble, la harpe plus présente
    P.melody("flute", 28, melA, vel=0.5)
    P.melody("solo_vln", 28, melA, vel=0.3, octave=-1)
    P.pad("horn", A, 28, 52, 64, 2, vel=0.14)
    # coda : l'accord suspendu, les cloches, une dernière luciole
    P.melody("flute", 36, "B5:3 | A#5:3 | G#5:3 | F#5:3 | E5:6", vel=0.38)
    P.pad("vln", ["Emaj7", "Emaj7"], 40, 64, 80, 3, vel=0.18)
    P.hit("chimes", 36, 0, 0.3)
    P.hit("chimes", 41, 0, 0.3)
    P.hit("triangle", 40, 0, 0.25)
    return P


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cm.VSCO = Path(sys.argv[1])
    cm.TMP.mkdir(parents=True, exist_ok=True)
    royaume_fees().render(cm.OUT / "royaume_fees.ogg", rms_db=-21.0)


if __name__ == "__main__":
    main()
