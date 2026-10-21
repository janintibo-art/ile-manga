"""V60 : les musiques de Tazira, le port des sables (la côte sud de la grande île).

Compositions originales pour Île Manga, versées au domaine public (CC0 1.0), jouées par
l'orchestre VSCO-2 (CC0) avec les outils de la V51 (compose_musique_v51.py, orchestre_v51.py).

« Tazira » (le jour) : mode de ré hijaz (ré, mi bémol, fa dièse, sol, la, si bémol, do), 96 à la
noire. Un bourdon d'altos sur ré, la harpe pincée comme un qanoun, la contrebasse en pizzicato, la
darbouka (grosse caisse feutrée pour le « doum », wood-blocks pour le « tek », sur le rythme
maqsoum) et le tambourin. La flûte joue l'air comme un ney, le hautbois le reprend comme une
rhaïta, le violon solo chante la partie haute ; à la fin, tout le monde.

« Tazira, la fête » (le soir, sur la place des Lanternes) : 116 à la noire, en ré mineur teinté de
hijaz. La basse ostinato du guembri (contrebasse en pizzicato), les claquements de mains, les
qraqeb (tambourin et wood-blocks en triolets), la darbouka ; le hautbois-rhaïta lance l'appel,
la flûte et le violon répondent, puis tout le monde danse. Le tempo est celui des danseurs
(pnj_tazira_v60.gd, BEAT_TZ).

Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/compose_musique_v60.py <dossier VSCO-2-CE>
"""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v51 as cm  # noqa: E402


def maqsoum(P, bar: int, vel: float = 1.0, riq: bool = True) -> None:
    """Le rythme maqsoum sur une mesure de 8 croches : DOUM tek . tek DOUM . tek ."""
    P.hit("bdrum", bar, 0, 0.34 * vel)
    P.hit("logdrum_hi", bar, 1, 0.16 * vel)
    P.hit("logdrum_hi", bar, 3, 0.18 * vel)
    P.hit("bdrum", bar, 4, 0.28 * vel)
    P.hit("logdrum_hi", bar, 6, 0.17 * vel)
    P.hit("logdrum_lo", bar, 7, 0.1 * vel)
    if riq:
        for k in range(8):
            P.hit("shaker", bar, k + 0.5, 0.08 * vel + (0.04 if k % 2 == 0 else 0.0))


def tazira():
    P = cm.Piece("tazira", 192, 40, beats=8, seed=601, room=2.4)
    intro = ["D", "D"]
    A = ["D", "Eb", "Gm", "D", "Cm", "Gm", "D Eb", "D"]
    B = ["Gm", "Cm", "Gm", "Gm", "Cm", "D", "Eb Cm", "D"]
    prog = intro + A + A + B + A + ["D", "D"] + ["D", "D"]
    melA = ("D5:2 Eb5:1 F#5:1 G5:2 F#5:1 Eb5:1 | D5:3 Eb5:1 F#5:4 | G5:1 A5:1 Bb5:2 A5:1 G5:1 F#5:2 | G5:2 F#5:1 Eb5:1 D5:4 | "
            "A5:2 Bb5:1 A5:1 G5:2 F#5:2 | G5:1 F#5:1 Eb5:1 F#5:1 G5:4 | F#5:1 G5:1 A5:1 G5:1 F#5:1 Eb5:1 D5:1 Eb5:1 | D5:6 r:2")
    melB = ("D6:2 C6:1 Bb5:1 A5:2 G5:2 | A5:1 Bb5:1 C6:2 Bb5:2 A5:2 | G5:2 A5:1 Bb5:1 A5:2 G5:1 F#5:1 | G5:4 r:2 D5:1 G5:1 | "
            "Bb5:2 A5:1 G5:1 F#5:2 Eb5:2 | F#5:1 G5:1 A5:2 G5:2 F#5:2 | Eb5:2 F#5:1 Eb5:1 D5:2 C5:2 | D5:6 r:2")
    # le bourdon : ré et la, tenus
    for b in range(0, 40, 2):
        P.note("vla", 50, b, 0, 16.2, 0.12, attack=0.5)
        P.note("vc", 38, b, 0, 16.2, 0.14, attack=0.5)
    # la darbouka et le tambourin
    for b in range(0, 40):
        maqsoum(P, b, 0.75 if b < 2 else 1.0, riq=b >= 2)
    # la harpe-qanoun : accords brisés en croches
    P.arp("harp", prog, 0, 50, step=1.0, pattern=[0, 2, 1, 3, 2, 4, 3, 1], vel=0.26, span=2)
    P.bass("cb_pizz", prog[2:], 2, 31, 43, vel=0.32, rhythm=[(0.0, 1.5), (3.0, 1.0), (4.0, 1.5), (6.0, 1.0)], fifth=True)
    # A : la flûte-ney, seule
    P.melody("flute", 2, melA, vel=0.48, legato=0.03)
    # A' : la rhaïta (hautbois), la flûte en écho une octave plus haut dans la 2e moitié
    P.melody("oboe", 10, melA, vel=0.5, legato=0.03)
    P.melody("flute", 14, melA.split("|", 4)[4], vel=0.24, legato=0.03, octave=1)
    P.chord_hits("vln_pizz", A, 10, 62, 74, [0.0, 3.0, 6.0], n=2, vel=0.18, dur=0.5)
    # B : le violon dans l'aigu, les cordes en pizzicato
    P.melody("solo_vln", 18, melB, vel=0.48, legato=0.03)
    P.pad("clar", B, 18, 55, 67, 2, vel=0.1)
    P.chord_hits("vla_pizz", B, 18, 55, 67, [2.0, 5.0], n=2, vel=0.2, dur=0.5)
    # A'' : tout le monde
    P.melody("oboe", 26, melA, vel=0.48, legato=0.03)
    P.melody("flute", 26, melA, vel=0.36, legato=0.03, octave=1)
    P.melody("solo_vln", 26, melA, vel=0.3, legato=0.03)
    P.pad("vln", A, 26, 62, 74, 2, vel=0.12)
    # la coda : la flûte seule sur le bourdon
    P.melody("flute", 34, "A5:2 G5:1 F#5:1 Eb5:2 D5:2 | Eb5:1 F#5:1 G5:2 F#5:2 Eb5:2 | D5:8 | r:8 | r:8 | r:8", vel=0.36, legato=0.03)
    P.hit("triangle", 36, 0, 0.18)
    return P


def tazira_fete():
    P = cm.Piece("tazira_fete", 232, 48, beats=8, seed=602, room=1.8)
    mf1 = "D5:1 F5:1 G5:1 A5:2 G5:1 F5:1 G5:1 | A5:3 C6:1 A5:2 G5:2 | F5:1 G5:1 A5:1 G5:1 F5:1 Eb5:1 D5:2 | D5:4 r:4"
    mf2 = "A5:2 C6:1 D6:1 C6:2 A5:2 | G5:1 A5:1 C6:1 A5:1 G5:2 F5:2 | G5:2 A5:1 G5:1 F5:1 Eb5:1 F5:2 | D5:6 r:2"
    p1 = ["Dm", "Dm", "Cm", "Dm"]
    p2 = ["F", "Gm", "Cm", "Dm"]
    prog = ["Dm"] * 4 + p1 * 2 + p2 * 2 + ["Dm"] * 4 + p1 * 2 + p2 * 2 + p1 * 2
    # la basse du guembri : un ostinato qui tourne, ré grave et sa quinte
    for b in range(48):
        for pos, m, v in [(0.0, 38, 0.42), (1.5, 38, 0.3), (3.0, 45, 0.34), (4.0, 48, 0.3), (5.0, 45, 0.26), (6.0, 38, 0.38), (7.0, 41, 0.26)]:
            P.note("cb_pizz", m, b, pos, 1.2, v)
    # la darbouka, les mains, les qraqeb (triolets métalliques)
    for b in range(48):
        brk = 20 <= b < 24
        P.hit("bdrum", b, 0, 0.38)
        P.hit("bdrum", b, 3, 0.26)
        P.hit("bdrum", b, 4, 0.32)
        if b >= 2:
            P.hit("snare", b, 2, 0.22 if not brk else 0.3)
            P.hit("snare", b, 6, 0.24 if not brk else 0.32)
        for k in range(8):
            for tri in (0.0, 0.333, 0.667):
                if b >= 1 and not (brk and tri > 0.0):
                    P.hit("shaker", b, k + tri, (0.1 if tri == 0.0 else 0.06))
        if not brk:
            P.hit("logdrum_hi", b, 1, 0.16)
            P.hit("logdrum_hi", b, 5, 0.16)
            P.hit("logdrum_lo", b, 7, 0.14)
    # la harpe : les accords qui sonnent en contretemps
    P.chord_hits("harp", prog[4:], 4, 57, 74, [1.0, 2.5, 5.0, 6.5], n=3, vel=0.22, dur=1.0)
    # l'appel : la rhaïta seule
    P.melody("oboe", 4, mf1, vel=0.55, legato=0.02)
    P.melody("oboe", 8, mf1, vel=0.55, legato=0.02)
    # la réponse : la flûte et la rhaïta ensemble
    P.melody("oboe", 12, mf2, vel=0.52, legato=0.02)
    P.melody("flute", 12, mf2, vel=0.42, legato=0.02)
    P.melody("oboe", 16, mf2, vel=0.52, legato=0.02)
    P.melody("flute", 16, mf2, vel=0.42, legato=0.02)
    # la pause : seulement la basse et les mains, un cri de flûte
    P.melody("flute", 21, "D6:1 r:1 D6:1 r:1 A5:4", vel=0.4)
    P.melody("flute", 23, "C6:1 r:1 C6:1 r:1 D6:4", vel=0.4)
    # le violon reprend, la rhaïta derrière
    P.melody("solo_vln", 24, mf1, vel=0.5, legato=0.02)
    P.melody("solo_vln", 28, mf1, vel=0.5, legato=0.02)
    P.melody("oboe", 28, mf1, vel=0.36, legato=0.02, octave=-1)
    # tout le monde
    for b0 in (32, 36):
        P.melody("oboe", b0, mf2, vel=0.52, legato=0.02)
        P.melody("flute", b0, mf2, vel=0.4, legato=0.02)
        P.melody("solo_vln", b0, mf2, vel=0.4, legato=0.02)
    P.chord_hits("vln_pizz", p2 * 2, 32, 62, 74, [0.0, 4.0], n=2, vel=0.2, dur=0.5)
    for b0 in (40, 44):
        P.melody("oboe", b0, mf1, vel=0.55, legato=0.02)
        P.melody("flute", b0, mf1, vel=0.4, legato=0.02, octave=1)
        P.melody("solo_vln", b0, mf1, vel=0.38, legato=0.02, octave=-1)
    P.pad("horn", p1 * 2, 40, 50, 62, 2, vel=0.1)
    return P


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cm.VSCO = Path(sys.argv[1])
    cm.TMP.mkdir(parents=True, exist_ok=True)
    tazira().render(cm.OUT / "tazira.ogg", rms_db=-21.0)
    tazira_fete().render(cm.OUT / "tazira_fete.ogg", rms_db=-19.0)


if __name__ == "__main__":
    main()
