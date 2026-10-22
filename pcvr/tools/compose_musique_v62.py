"""V62 : les musiques de Ramure, le village des oreilles, perché dans les arbres de la forêt des brumes.

Compositions originales pour Île Manga, versées au domaine public (CC0 1.0), jouées par
l'orchestre VSCO-2 (CC0) avec les outils de la V51 (compose_musique_v51.py, orchestre_v51.py).

« Les Branches » (ramure.ogg), la musique du village : ré majeur pentatonique, 88 à la noire.
La harpe arpège doucement comme le vent dans les couronnes, les altos et la contrebasse en
pizzicato marchent sur les ponts de corde ; la flûte chante l'air, la clarinette le reprend ;
au milieu, le marimba et un wood-block discret (les lapins qui courent), puis le violon ;
à la fin, la flûte retrouve le thème de l'île (ré, fa dièse, la, si).

« La Lune toujours pleine » (ramure_fete.ogg), la fête de chaque nuit au Cercle de la Lune :
126 à la noire, gamme « yo » sur ré (ré mi sol la si). Les grands tambours (grosse caisse et
timbales, comme des taikos) font « don, don, doko-don », les wood-blocks font « ka » ; un
bourdon de ré et la aux cordes ; la flûte joue l'air de la danse, le hautbois la double en
dessous, le violon répond ; un pont de tambours seuls, et ça repart.

Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/compose_musique_v62.py <dossier VSCO-2-CE> [ramure|ramure_fete]
"""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v51 as cm  # noqa: E402


def ramure():
    P = cm.Piece("ramure", 88, 48, beats=4, seed=621, room=2.6)
    intro = ["D", "Bm", "G", "A"]
    A = ["D", "D", "Bm", "Bm", "G", "A", "D", "D"]
    B = ["Bm", "G", "D", "A", "Bm", "G", "Em", "A"]
    bridge = ["G", "A", "Bm", "A"]
    outro = ["D", "G", "D", "A", "D", "G", "D", "D"]
    prog = intro + A + A + B + A + bridge + outro
    melA = ("A4:1 B4:0.5 A4:0.5 F#4:1 E4:1 | D4:2 E4:1 F#4:1 | B4:1.5 A4:0.5 F#4:1 A4:1 | B4:3 r:1 | "
            "D5:1 B4:1 A4:1 F#4:1 | E4:1 F#4:0.5 E4:0.5 D4:2 | F#4:1 A4:1 B4:1 A4:1 | D4:3 r:1")
    melB = ("F#5:1.5 E5:0.5 D5:1 B4:1 | D5:2 B4:1 A4:1 | A4:1 B4:1 D5:1 F#5:1 | E5:3 r:1 | "
            "F#5:1 A5:1 F#5:1 E5:1 | D5:1.5 E5:0.5 B4:2 | B4:1 D5:1 E5:1 F#5:0.5 E5:0.5 | E5:3 r:1")
    theme = "D5:2 F#5:2 | A5:2 B5:2 | A5:4 | F#5:2 E5:2 | D5:2 F#5:2 | A5:2 B5:2 | D6:4 | r:4"
    # la harpe, tout le long : le vent dans les couronnes
    P.arp("harp", prog, 0, 50, step=0.5, pattern=[0, 2, 4, 2, 1, 3, 4, 3], vel=0.2, span=2)
    # les ponts de corde : la contrebasse et les altos en pizzicato
    P.bass("cb_pizz", prog[4:], 4, 31, 43, vel=0.32, rhythm=[(0.0, 1.0), (2.0, 1.0)], fifth=True)
    P.chord_hits("vla_pizz", prog[4:], 4, 57, 69, [1.0, 3.0], n=2, vel=0.14, dur=0.5)
    # A : la flûte
    P.melody("flute", 4, melA, vel=0.46, legato=0.03, octave=1)
    # A' : la clarinette, la flûte en écho une sixte au-dessus dans la seconde moitié
    P.melody("clar", 12, melA, vel=0.44, legato=0.03, octave=1)
    P.melody("flute", 16, melA.split("|", 4)[4], vel=0.22, legato=0.03, octave=2)
    P.pad("vla", A, 12, 57, 69, 2, vel=0.08)
    # B : le marimba chante, un wood-block discret (les lapins qui courent), les cordes tenues
    P.melody("marimba", 20, melB, vel=0.42, legato=0.0, swell=False)
    P.melody("flute", 20, melB, vel=0.18, legato=0.03)
    P.pad("vln", B, 20, 62, 74, 2, vel=0.1)
    for b in range(20, 28):
        P.hit("logdrum_hi", b, 1.0, 0.07)
        P.hit("logdrum_lo", b, 3.0, 0.06)
        P.hit("logdrum_hi", b, 3.5, 0.05)
    # A'' : le violon, la flûte à l'octave, le cor tenu
    P.melody("solo_vln", 28, melA, vel=0.42, legato=0.03, octave=1)
    P.melody("flute", 28, melA, vel=0.26, legato=0.03, octave=2)
    P.pad("horn", A, 28, 50, 62, 2, vel=0.08)
    # le pont : le glockenspiel scintille (les lucioles), les violons en trémolo
    P.sparkle("glock", bridge, 36, 74, 88, prob=0.5, vel=0.18, step=0.5)
    P.pad("vln_trem", bridge, 36, 62, 76, 3, vel=0.1)
    P.hit("chimes", 36, 0, 0.2)
    # la fin : la flûte retrouve le thème de l'île
    P.melody("flute", 40, theme, vel=0.42, legato=0.04)
    P.melody("clar", 40, theme, vel=0.2, legato=0.04, octave=-1)
    P.pad("vla", outro, 40, 55, 67, 2, vel=0.08)
    P.hit("triangle", 46, 0, 0.14)
    return P


def taiko_bar(P, bar: int, vel: float = 1.0, ka: bool = True) -> None:
    """Un temps de taiko : « don, don, doko-don » (grosse caisse et timbale), « ka » (wood-blocks)."""
    P.hit("bdrum", bar, 0.0, 0.42 * vel)
    P.note("timp", 38, bar, 0.0, 1.0, 0.22 * vel)
    P.hit("bdrum", bar, 1.0, 0.3 * vel)
    P.hit("bdrum", bar, 2.0, 0.36 * vel)
    P.hit("bdrum", bar, 2.5, 0.26 * vel)
    P.hit("bdrum", bar, 3.0, 0.32 * vel)
    if ka:
        P.hit("logdrum_hi", bar, 1.5, 0.14 * vel)
        P.hit("logdrum_hi", bar, 3.5, 0.15 * vel)
    for k in range(8):
        P.hit("shaker", bar, k * 0.5, (0.07 if k % 2 else 0.1) * vel)


def ramure_fete():
    P = cm.Piece("ramure_fete", 126, 40, beats=4, seed=622, room=1.9)
    mf1 = ("A5:1 B5:0.5 A5:0.5 G5:1 E5:1 | D5:1 E5:1 G5:2 | A5:0.5 B5:0.5 D6:1 B5:1 A5:1 | G5:3 r:1 | "
           "E5:1 G5:1 A5:1 B5:1 | A5:1 G5:0.5 E5:0.5 D5:2 | E5:1 G5:1 E5:1 D5:1 | D5:3 r:1")
    mf2 = ("D6:1.5 B5:0.5 A5:1 B5:1 | D6:1 E6:1 D6:2 | B5:1 A5:1 G5:1 A5:1 | B5:3 r:1 | "
           "A5:1 B5:1 D6:1 B5:1 | A5:1 G5:1 E5:2 | G5:1 A5:0.5 G5:0.5 E5:1 D5:1 | D5:3 r:1")
    yo = ["Dsus2", "Dsus2", "Gsus2", "Em7", "Dsus2", "Gsus2", "Asus4", "Dsus2"]
    # les tambours : l'intro qui monte, la danse, le pont de tambours seuls
    for b in range(40):
        vel = 0.6 + 0.1 * b if b < 4 else (1.15 if b >= 36 else 1.0)
        taiko_bar(P, b, min(vel, 1.15), ka=b >= 2)
        if b % 8 == 7 or b >= 36:
            P.hit("bdrum", b, 3.5, 0.3)
        if b % 4 == 0 and b >= 4:
            P.hit("triangle", b, 0.5, 0.08)
    P.hit("crash", 4, 0, 0.12)
    P.hit("crash", 20, 0, 0.12)
    # le bourdon : ré et la, tenus par les cordes graves
    for b in range(4, 36, 4):
        P.note("vc", 38, b, 0, 16.2, 0.12, attack=0.5)
        P.note("vla", 57, b, 0, 16.2, 0.08, attack=0.5)
    # la harpe en croches (la koto du village)
    P.arp("harp", yo * 4, 4, 50, step=0.5, pattern=[0, 2, 1, 3, 2, 4, 3, 1], vel=0.18, span=2)
    # l'air de la danse
    P.melody("flute", 4, mf1, vel=0.5, legato=0.02)
    P.melody("flute", 12, mf2, vel=0.5, legato=0.02)
    P.melody("oboe", 12, mf2, vel=0.3, legato=0.02, octave=-1)
    P.melody("solo_vln", 20, mf1, vel=0.4, legato=0.02)
    P.melody("flute", 20, mf1, vel=0.34, legato=0.02, octave=1)
    P.melody("flute", 28, mf2, vel=0.48, legato=0.02)
    P.melody("oboe", 28, mf2, vel=0.3, legato=0.02, octave=-1)
    P.melody("marimba", 28, mf2, vel=0.3, legato=0.0, octave=-1, swell=False)
    P.chord_hits("vln_pizz", yo, 28, 62, 74, [1.0, 3.0], n=2, vel=0.14, dur=0.5)
    return P


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cm.VSCO = Path(sys.argv[1])
    cm.TMP.mkdir(parents=True, exist_ok=True)
    want = sys.argv[2:] or ["ramure", "ramure_fete"]
    if "ramure" in want:
        ramure().render(cm.OUT / "ramure.ogg", rms_db=-21.0)
    if "ramure_fete" in want:
        ramure_fete().render(cm.OUT / "ramure_fete.ogg", rms_db=-19.0)


if __name__ == "__main__":
    main()
