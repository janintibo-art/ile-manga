"""V59 : « La Gigue du Léviathan », la musique de Carène, le port bâti dans l'épave géante.

Composition originale pour Île Manga, versée au domaine public (CC0 1.0), jouée par
l'orchestre VSCO-2 (CC0) avec les outils de la V51 (compose_musique_v51.py, orchestre_v51.py).
Une gigue de marins à 6/8, ré dorien, 76 à la noire pointée : un bourdon de violoncelles (la coque
qui résonne), la harpe celtique, le tambour sur cadre (grosse caisse feutrée et wood-blocks) ; la
flûte joue l'air comme un sifflet de bord, le violon solo le reprend comme un violoneux de taverne,
le hautbois sonne la bombarde dans la partie haute ; à la fin, tout le monde ensemble, et un dernier
coup de pied sur le pont.

Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/compose_musique_v59.py <dossier VSCO-2-CE>
"""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v51 as cm  # noqa: E402


def carene():
    P = cm.Piece("carene", 228, 44, beats=6, seed=591, room=2.6)
    intro = ["Dm", "Dm"]
    A = ["Dm", "C", "Dm", "Am", "Dm", "C", "F C", "Dm"]
    B = ["F", "C", "Dm", "Am", "F", "C", "Gm A", "Dm"]
    outro = ["Dm", "Dm"]
    prog = intro + A + A + B + B + A + outro
    # l'air (6 croches par mesure)
    melA = ("A4:2 D5:1 D5:1 E5:1 F5:1 | G5:2 E5:1 C5:1 D5:1 E5:1 | F5:1 E5:1 D5:1 A5:2 F5:1 | E5:1 C5:1 A4:1 C5:2 E5:1 | "
            "D5:1 F5:1 A5:1 D6:2 A5:1 | G5:1 E5:1 C5:1 E5:2 G5:1 | F5:1 A5:1 F5:1 E5:1 G5:1 E5:1 | D5:3 D5:2 r:1")
    melB = ("C6:2 A5:1 F5:1 A5:1 C6:1 | E6:2 C6:1 G5:1 C6:1 E6:1 | D6:1 C6:1 A5:1 F5:2 A5:1 | C6:1 A5:1 E5:1 A5:3 | "
            "F5:1 A5:1 C6:1 A5:2 F5:1 | G5:1 C6:1 E6:1 D6:1 C6:1 G5:1 | G5:1 A#5:1 D6:1 C#6:1 E6:1 A5:1 | D6:3 D5:2 r:1")
    # le bourdon : la coque qui résonne (ré et la tenus)
    for b in range(0, 44, 2):
        P.note("vc", 38, b, 0, 12.2, 0.2, attack=0.4)
        P.note("vla", 45, b, 0, 12.2, 0.12, attack=0.4)
    # le tambour sur cadre : grosse caisse feutrée sur 1 et 4, wood-blocks en croches
    for b in range(0, 42):
        P.hit("bdrum", b, 0, 0.32 if b % 2 == 0 else 0.26)
        P.hit("bdrum", b, 3, 0.2)
        if b >= 2:
            for k in (1, 2, 4, 5):
                P.hit("logdrum_hi" if k in (2, 5) else "logdrum_lo", b, k, 0.13 + (0.04 if k == 4 else 0.0))
        if b >= 18 and b % 2 == 1:
            P.hit("shaker", b, 4.5, 0.14)
    P.hit("bdrum", 42, 0, 0.42)
    P.hit("bdrum", 42, 3, 0.36)
    P.hit("bdrum", 43, 0, 0.5)
    # la harpe celtique : accords brisés en croches
    P.arp("harp", prog, 0, 50, step=1.0, pattern=[0, 2, 4, 3, 2, 1], vel=0.3, span=2)
    P.bass("cb_pizz", prog[2:], 2, 31, 43, vel=0.34, rhythm=[(0.0, 2.0), (3.0, 2.0)], fifth=True)
    # A (1) : la flûte, seule, comme un sifflet de bord
    P.melody("flute", 2, melA, vel=0.5, legato=0.02)
    # A (2) : le violon solo reprend, la flûte à l'octave dans la deuxième moitié
    P.melody("solo_vln", 10, melA, vel=0.5, legato=0.02)
    P.melody("flute", 14, melA.split("|", 4)[4], vel=0.28, legato=0.02)
    P.pad("clar", A, 10, 57, 69, 2, vel=0.12)
    # B : le violon dans l'aigu, les cordes en contretemps
    P.melody("solo_vln", 18, melB, vel=0.48, legato=0.02)
    P.chord_hits("vla_spic", B + B, 18, 57, 69, [2.0, 5.0], n=2, vel=0.22, dur=0.6)
    # B' : la bombarde (hautbois) et la flûte ensemble
    P.melody("oboe", 26, melB, vel=0.5, legato=0.02, octave=-1)
    P.melody("flute", 26, melB, vel=0.32, legato=0.02)
    P.pad("vln", B, 26, 62, 77, 2, vel=0.14)
    # A' : tout le monde
    P.melody("solo_vln", 34, melA, vel=0.5, legato=0.02)
    P.melody("flute", 34, melA, vel=0.42, legato=0.02)
    P.melody("oboe", 34, melA, vel=0.32, legato=0.02, octave=-1)
    P.pad("horn", A, 34, 50, 62, 2, vel=0.14)
    P.chord_hits("vln_pizz", A, 34, 62, 74, [0.0, 3.0], n=2, vel=0.22, dur=0.5)
    # fin : un dernier accord, la cymbale et le pied sur le pont
    P.melody("solo_vln", 42, "D5:6 | D4:3 r:3", vel=0.42)
    P.melody("flute", 42, "A5:6 | D5:3 r:3", vel=0.3)
    P.pad("vln", ["Dm", "Dm"], 42, 62, 77, 3, vel=0.16)
    P.hit("cymbal", 41, 2, 0.2)
    return P


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cm.VSCO = Path(sys.argv[1])
    cm.TMP.mkdir(parents=True, exist_ok=True)
    carene().render(cm.OUT / "carene.ogg", rms_db=-21.0)


if __name__ == "__main__":
    main()
