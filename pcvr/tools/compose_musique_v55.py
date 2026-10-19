"""V55 : « Atlantide », la musique de la cité engloutie et des profondeurs.

Composition originale pour Île Manga, versée au domaine public (CC0 1.0), jouée par
l'orchestre VSCO-2 (CC0) avec les outils de la V51 (compose_musique_v51.py, orchestre_v51.py).
Mi dorien, 64 à la noire : la harpe ondule comme la lumière qui danse sur le sable, le
glockenspiel scintille (les bulles, les cristaux), les cordes tiennent de longues nappes
(la masse de l'eau), la flûte chante le thème, le hautbois et le violon solo lui répondent,
les cymbales roulent comme une houle lointaine.

Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/compose_musique_v55.py <dossier VSCO-2-CE>
"""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v51 as cm  # noqa: E402


def atlantide():
    P = cm.Piece("atlantide", 64, 36, seed=555, room=4.2)
    intro = ["Em9", "Cmaj7"]
    A = ["Em9", "Cmaj7", "Gmaj7", "D/F#", "Am9", "Cmaj7", "Bm7", "Bm7"]
    B = ["Cmaj9", "D", "Bm7", "Em9", "Am9", "D/F#", "Gmaj7", "Bm7"]
    prog = intro + A + B + A + B + ["Em9", "Em9"]
    melA = "B4:2 E5:1 F#5:1 | G5:3 A5:1 | B5:2 A5:1 F#5:1 | A5:4 | C6:2 B5:1 A5:1 | G5:2 E5:2 | F#5:4 | r:4"
    melB = "G5:2 A5:1 B5:1 | A5:3 F#5:1 | D5:2 F#5:1 A5:1 | B5:4 | C6:2 B5:1 A5:1 | F#5:2 D5:2 | B4:3 D5:1 | E5:4"
    # La harpe : ondulations (arpège montant puis redescendant)
    P.arp("harp", prog, 0, 47, step=0.5, pattern=[0, 2, 4, 6, 7, 6, 4, 2], vel=0.28, span=3)
    P.sparkle("glock", prog, 0, 79, 96, prob=0.3, vel=0.2, step=0.5)
    P.pad("vln", prog, 0, 64, 79, 2, vel=0.16)
    P.pad("vla", prog, 0, 55, 67, 2, vel=0.2)
    P.bass("cb", prog, 0, 28, 40, vel=0.26)
    P.bass("vc", prog[2:], 2, 36, 48, vel=0.22)
    P.hit("timp_roll", 0, 0, 0.12, 6.0, midi=40)
    P.hit("chimes", 0, 0, 0.3)
    # A : la flûte
    P.melody("flute", 2, melA, vel=0.42)
    P.melody("clar", 2, melA, vel=0.16, octave=-1)
    # B : le hautbois, le violon solo à l'octave
    P.melody("oboe", 10, melB, vel=0.38)
    P.melody("solo_vln", 10, melB, vel=0.22, octave=-1)
    P.pad("horn", B, 10, 52, 64, 2, vel=0.16)
    # A' : la flûte et le violon solo ensemble, contre-chant des violons
    P.melody("flute", 18, melA, vel=0.46)
    P.melody("solo_vln", 18, melA, vel=0.3, octave=-1)
    P.melody("vln", 18, "E6:4 | E6:4 | D6:4 | D6:4 | E6:4 | E6:4 | D6:4 | F#6:4", vel=0.18)
    P.pad("vc_trem", A, 18, 43, 55, 2, vel=0.14)
    # B' : tout le monde, puis le retour au silence des profondeurs
    P.melody("oboe", 26, melB, vel=0.4)
    P.melody("flute", 26, melB, vel=0.3, octave=1)
    P.melody("horn", 26, melB, vel=0.24, octave=-1)
    P.pad("vln_trem", ["Em9", "Em9"], 34, 64, 79, 3, vel=0.18)
    P.melody("flute", 34, "B5:4 | E5:4", vel=0.32)
    for b in (9, 17, 25, 33):
        P.hit("cymbal", b, 0, 0.18)
    for b in (2, 10, 18, 26, 34):
        P.hit("chimes", b, 0, 0.22)
    for b in range(18, 34, 2):
        P.hit("triangle", b, 2, 0.12)
    return P


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cm.VSCO = Path(sys.argv[1])
    cm.TMP.mkdir(parents=True, exist_ok=True)
    atlantide().render(cm.OUT / "atlantide.ogg", rms_db=-22.0)


if __name__ == "__main__":
    main()
