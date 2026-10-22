"""V63 : les musiques de la grande enquête et du donjon du Cœur-de-Pierre.

Compositions originales pour Île Manga, versées au domaine public (CC0 1.0), jouées par
l'orchestre VSCO-2 (CC0) avec les outils de la V51 (compose_musique_v51.py, orchestre_v51.py).

« Le Cœur-de-Pierre » (coeur.ogg), la musique du donjon : do mineur, 64 à la noire, avec la
couleur phrygienne du ré bémol. Sous tout le morceau, le cœur de la montagne bat : deux coups de
timbale, « boum-boum », une fois par mesure. Les contrebasses et les violoncelles tiennent un
bourdon, la harpe égrène des arpèges lents, le glockenspiel fait luire les cristaux.
Le thème des Quatre Peuples (do, mi bémol, sol, la bémol… sol, fa, mi bémol, ré) passe d'un
peuple à l'autre : la flûte (les Marées), le hautbois (les Sables), le basson (les Rouages), la
clarinette (la Lune) ; puis les cors et le trombone le chantent ensemble, toutes les cordes en
trémolo, comme les quatre peuples main dans la main. À la fin, le violon seul le reprend tout
bas, et il ne reste que le battement du cœur.

« Niveau » (niveau.ogg), le jingle du passage de niveau : un glissando de harpe, une fanfare
de trompette et de cor en sol majeur, le glockenspiel et le triangle.

Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/compose_musique_v63.py <dossier VSCO-2-CE> [coeur|niveau]
"""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v51 as cm  # noqa: E402


def heartbeat(P, bar: int, vel: float) -> None:
    """Le cœur de la montagne : « boum-boum » (timbale grave, grosse caisse feutrée)."""
    P.note("timp", 36, bar, 0.0, 1.0, 0.34 * vel)
    P.hit("bdrum", bar, 0.0, 0.22 * vel)
    P.note("timp", 36, bar, 0.42, 1.0, 0.24 * vel)
    P.hit("bdrum", bar, 0.42, 0.14 * vel)


def coeur():
    P = cm.Piece("coeur", 64, 32, beats=4, seed=631, room=3.6)
    intro = ["Cm", "Cm", "Ab", "G"]
    A = ["Cm", "Ab", "Fm", "G", "Cm", "Db", "Ab", "G"]
    B = ["Ab", "Eb", "Fm", "Cm", "Db", "Ab", "Fm", "G"]
    C = ["Cm", "Ab", "Eb", "Bb", "Fm", "Db", "G", "G"]
    outro = ["Cm", "Ab", "Cm", "Cm"]
    prog = intro + A + B + C + outro
    theme = "C4:2 Eb4:1 G4:1 | Ab4:3 G4:1 | F4:1.5 Eb4:0.5 D4:1 Eb4:1 | C4:4"
    answer = "Eb4:2 G4:1 C5:1 | Db5:3 C5:1 | Bb4:1.5 Ab4:0.5 G4:1 F4:1 | G4:4"
    themeB = "Ab4:2 C5:1 Eb5:1 | D5:2 C5:2 | Db5:1.5 C5:0.5 Bb4:1 Ab4:1 | G4:4"
    # le cœur bat tout le long (plus fort au sommet du morceau)
    for b in range(32):
        v = 0.7 if b < 4 else (1.25 if 20 <= b < 28 else (0.55 if b >= 28 else 1.0))
        heartbeat(P, b, v)
    # le bourdon des profondeurs
    P.bass("cb", prog, 0, 24, 36, vel=0.3)
    P.pad("vc", prog, 0, 36, 48, 1, vel=0.2)
    P.pad("vla", prog[4:28], 4, 50, 62, 2, vel=0.12)
    # la harpe : des arpèges lents, comme de l'eau qui goutte
    P.arp("harp", prog, 0, 48, step=1.0, pattern=[0, 2, 4, 2], vel=0.2, span=2)
    # les cristaux
    for b in range(32):
        if b % 2 == 0 or b >= 28:
            P.sparkle("glock", [prog[b]], b, 79, 91, prob=0.3, vel=0.16, step=2.0)
    P.hit("chimes", 0, 0, 0.18)
    # A : la flûte (les Marées), puis le hautbois (les Sables)
    P.melody("flute", 4, theme, vel=0.42, legato=0.04, octave=1)
    P.melody("oboe", 8, answer, vel=0.42, legato=0.04)
    # B : le basson (les Rouages), puis la clarinette (la Lune)
    P.melody("bsn", 12, themeB, vel=0.44, legato=0.04, octave=-1)
    P.chord_hits("vla_pizz", B[:4], 12, 55, 67, [1.0, 3.0], n=2, vel=0.12, dur=0.5)
    P.melody("clar", 16, theme, vel=0.42, legato=0.04, octave=0)
    P.pad("vln_trem", B[4:], 16, 67, 79, 2, vel=0.08)
    # C : les quatre peuples ensemble — cors, trombone, cordes en trémolo, timbales
    P.melody("horn", 20, theme, vel=0.55, legato=0.04)
    P.melody("tbn", 20, theme, vel=0.4, legato=0.04, octave=-1)
    P.melody("vln", 20, theme, vel=0.36, legato=0.04, octave=1)
    P.melody("horn", 24, answer, vel=0.55, legato=0.04, octave=-1)
    P.melody("flute", 24, answer, vel=0.35, legato=0.04, octave=1)
    P.melody("oboe", 24, answer, vel=0.3, legato=0.04)
    P.pad("vln_trem", C, 20, 62, 77, 3, vel=0.14)
    P.pad("vc", C, 20, 43, 55, 2, vel=0.16)
    P.hit("timp_roll", 19, 2, 0.24, midi=36)
    P.hit("cymbal", 19, 0, 0.16)
    P.hit("timp_roll", 27, 0, 0.2, midi=43)
    # la fin : le violon seul, tout bas, et le cœur
    P.melody("solo_vln", 28, theme, vel=0.3, legato=0.05, octave=1)
    P.note("cb", 24, 28, 0, 16.0, 0.2, attack=0.6)
    return P


def niveau():
    """Jingle : le héros passe un niveau. Sol majeur, éclatant et court."""
    P = cm.Piece("niveau", 112, 2, loop=False, seed=632, room=2.6, extra=2.5)
    P.arp("harp", ["G"], 0, 55, step=0.083, pattern=list(range(10)), vel=0.4, ring=3.0, span=3)
    P.melody("trp", 0, "D5:0.5 G5:0.5 B5:0.5 D6:2.5 | r:4", vel=0.5)
    P.melody("horn", 0, "B3:0.5 D4:0.5 G4:0.5 B4:2.5 | r:4", vel=0.5)
    P.pad("vln", ["G", "G"], 0, 67, 83, 3, vel=0.3)
    P.bass("vc", ["G", "G"], 0, 43, 55, vel=0.35)
    P.melody("glock", 0, "r:1.5 D6:0.5 G6:0.5 B6:1.5 | D7:4", vel=0.4)
    P.hit("triangle", 0, 1.5, 0.3)
    P.hit("timp", 0, 1.5, 0.35, midi=43)
    return P


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cm.VSCO = Path(sys.argv[1])
    cm.TMP.mkdir(parents=True, exist_ok=True)
    want = sys.argv[2:] or ["coeur", "niveau"]
    if "coeur" in want:
        coeur().render(cm.OUT / "coeur.ogg", rms_db=-22.0)
    if "niveau" in want:
        niveau().render(cm.OUT / "niveau.ogg", rms_db=-19.0)


if __name__ == "__main__":
    main()
