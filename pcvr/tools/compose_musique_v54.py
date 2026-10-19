"""V54 : « La Citadelle des Nuées », la musique du ciel (île flottante, vol sur Ventaile).

Composition originale pour Île Manga, versée au domaine public (CC0 1.0), jouée par
l'orchestre VSCO-2 (CC0) avec les outils de la V51 (compose_musique_v51.py, orchestre_v51.py).
Ré lydien (le sol dièse donne la lumière du ciel), 70 à la noire : la harpe monte en
arpèges comme un vent ascendant, les cors chantent le thème, les violons s'envolent à
l'octave, les timbales et les cymbales soulèvent la reprise.

Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/compose_musique_v54.py <dossier VSCO-2-CE>
"""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v51 as cm  # noqa: E402


def ciel():
    P = cm.Piece("ciel", 70, 34, seed=541, room=3.6)
    A = ["D", "E/D", "Bm7", "Gmaj7", "D/F#", "E/G#", "A", "Asus4 A"]
    B = ["Gmaj7", "A", "F#m7", "Bm", "Gmaj7", "E/G#", "Asus4", "A"]
    intro = ["Dmaj7", "E/D"]
    prog = intro + A + B + A + B
    melA = "A4:2 D5:1 E5:1 | F#5:3 G#5:1 | F#5:2 D5:2 | B4:4 | A4:2 F#5:1 E5:1 | D5:2 B4:1 G#4:1 | A4:4 | r:4"
    melB = "B5:2 A5:1 G5:1 | E5:4 | F#5:2 A5:2 | D6:4 | B5:2 G5:1 E5:1 | G#5:2 E5:2 | A5:3 B5:1 | C#6:4"
    # La harpe : arpèges qui montent sur trois octaves (le vent ascendant)
    P.arp("harp", prog + ["D", "D"], 0, 50, step=0.5, pattern=[0, 1, 2, 3, 4, 5, 6, 7], vel=0.3, span=3)
    P.pad("vln", prog, 0, 66, 81, 2, vel=0.2)
    P.pad("vla", prog, 0, 54, 67, 2, vel=0.22)
    P.bass("cb", prog, 0, 26, 38, vel=0.3)
    P.bass("vc", prog[2:], 2, 38, 50, vel=0.28)
    P.sparkle("glock", intro, 0, 79, 91, prob=0.5, vel=0.25)
    P.hit("timp_roll", 0, 0, 0.22, 4.0, midi=38)
    P.hit("chimes", 0, 0, 0.35)
    # A : les cors chantent le thème
    P.melody("horn", 2, melA, vel=0.52)
    P.melody("clar", 2, melA, vel=0.22, octave=-1)
    # B : les violons s'envolent, la flûte double à l'octave
    P.melody("vln", 10, melB, vel=0.46)
    P.melody("flute", 10, melB, vel=0.3, octave=1)
    P.pad("horn", B, 10, 53, 65, 2, vel=0.24)
    # A' : tout l'orchestre ; trompette et cors, contre-chant des violons
    P.melody("horn", 18, melA, vel=0.6)
    P.melody("trp", 18, melA, vel=0.32, octave=1)
    P.melody("vln", 18, "D6:4 | C#6:4 | B5:4 | B5:4 | A5:4 | G#5:4 | A5:4 | C#6:4", vel=0.32)
    P.pad("tbn", A, 18, 48, 60, 2, vel=0.26)
    P.bass("tuba", A, 18, 29, 41, vel=0.26)
    # B' : les violons et le cor ensemble, puis l'accord final qui s'éteint
    P.melody("vln", 26, melB, vel=0.5)
    P.melody("horn", 26, melB, vel=0.4, octave=-1)
    P.melody("flute", 26, melB, vel=0.3, octave=1)
    P.pad("vln_trem", ["D", "D"], 32, 66, 81, 3, vel=0.25)
    P.bass("cb", ["D", "D"], 32, 26, 38, vel=0.3)
    P.melody("horn", 32, "A4:4 | D5:4", vel=0.42)
    for b in range(18, 32):
        _, _, r = cm.chord(prog[b].split()[0])
        low = 38 + (r - 38) % 12 - (12 if (r - 38) % 12 > 7 else 0)
        P.hit("timp", b, 0, 0.3 if b % 2 == 0 else 0.2, 2.0, midi=low)
    for b in (9, 17, 25):
        P.hit("cymbal", b, 0, 0.25)
    P.hit("crash", 18, 0, 0.25)
    P.hit("chimes", 26, 0, 0.3)
    P.hit("chimes", 32, 0, 0.35)
    return P


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cm.VSCO = Path(sys.argv[1])
    cm.TMP.mkdir(parents=True, exist_ok=True)
    ciel().render(cm.OUT / "ciel.ogg", rms_db=-21.0)


if __name__ == "__main__":
    main()
