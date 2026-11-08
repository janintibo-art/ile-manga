"""V121 : la musique de Sombreval, la ville morte.

Composition originale pour « Les Mondes de Travers », versée au domaine public (CC0 1.0). Elle est
jouée avec les outils des V75 et V76 (compose_musique_v75.py, compose_musique_v76.py : le morceau,
ses bus, la salle, le mastering, la boucle sans raccord, le chœur doux synthétisé, le thérémine)
et l'orchestre VSCO-2 CE et la VCSL (Versilian Studios, CC0).

  sombreval.ogg  « La Ville morte » : ré mineur, 50 à la noire, en boucle (24 mesures, ~1 min 55).
                 Un bourdon de contrebasse et d'orgue tout au fond, une nappe sombre où traînent
                 des secondes mineures, les violons en trémolo tout là-haut, à peine audibles ; une
                 boîte à musique (le célesta) joue une berceuse qui se dérègle ; puis le chœur
                 sans paroles, le cœur qui bat dans les timbales, le thérémine qui gémit ; et à la
                 fin, l'orgue du comte (ré, la, si bémol, la, sol dièse, la…) avant que tout
                 retombe dans le bourdon.

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/compose_musique_v121.py [--vsco <VSCO-2-CE>] [--vcsl <VCSL>] [--cc0 <CC0-…>]
(par défaut, les banques sont cherchées dans /root/snd)
"""
from __future__ import annotations

from pathlib import Path
import gc
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v76 as m76  # noqa: E402

m75, cm70, cm51 = m76.m75, m76.cm70, m76.cm51
SR = m75.SR
Song, play, melody, celesta, pad, twinkle = m75.Song, m75.play, m75.melody, m75.celesta, m75.pad, m75.twinkle
filt, bw, echo, hz = m75.filt, m75.bw, m75.echo, m75.hz
notes_of, mark_tree, theremin = m76.notes_of, m76.mark_tree, m76.theremin

NUIT = {   # accord : (basse, notes de la nappe)
    "Dm": ("D2", "D3 F3 A3 D4"), "Bb": ("A#1", "D3 F3 A#3 D4"), "Gm": ("G1", "G3 A#3 D4 G4"),
    "A7b9": ("A1", "C#3 G3 A#3 E4"), "Eb/D": ("D2", "D#3 G3 A#3 D4"), "Dm9": ("D2", "E3 F3 A3 D4"),
}


def boite(m: float, dur: float, vel: float = 0.5) -> np.ndarray:
    """La boîte à musique : le célesta, un peu faux (la lame sonne un rien trop bas)."""
    return celesta(m - 0.18, dur, vel * 0.8, np.random.default_rng(int(m * 31)))


def battement(S: Song, bar: int, vel: float) -> None:
    """Le cœur qui bat : deux coups sourds de timbale (« poum-poum »), à chaque mesure."""
    play(S, "timp", "heart", 38, bar, 0.0, 0.8, vel)
    play(S, "timp", "heart", 38, bar, 0.42, 0.8, vel * 0.7)


def ville_morte(kit) -> Song:
    S = Song("sombreval", 50, 24, loop=True, seed=1211)
    rng = np.random.default_rng(12110)
    prog = ["Dm", "Dm", "Eb/D", "Dm", "Bb", "Gm", "A7b9", "A7b9",
            "Dm", "Bb", "Gm", "A7b9", "Dm9", "Eb/D", "Gm", "A7b9",
            "Dm", "Bb", "Eb/D", "A7b9", "Gm", "Eb/D", "A7b9", "Dm"]
    for i, c in enumerate(prog):
        bass, notes = notes_of(NUIT, c)
        for m in notes:
            S.add("pad", pad(m, 4 * S.spb + 0.6, 0.36, rng, cutoff=700, attack=2.8, release=3.5), S.t(i) - 0.8, 1.0)
        play(S, "cb", "low", bass, i, 0, 4.4, 0.32)
        if i % 2 == 0:
            play(S, "orgue_pedale", "organ_low", 26, i, 0, 8.4, 0.22)
        # les violons en trémolo, tout là-haut (une seconde mineure qui grince)
        if i % 4 == 0:
            play(S, "vln_trem", "trem", 93, i, 0, 16.0, 0.07 + 0.03 * (i >= 16))
            play(S, "vln_trem", "trem", 94, i, 1.0, 15.0, 0.05 + 0.03 * (i >= 16))
        # le chœur sans paroles, au milieu
        if 8 <= i < 20:
            for m in notes[-3:]:
                play(S, "choeur_doux", "choir", m + 12, i, 0, 4.4, 0.28 if i < 12 else 0.36)
        # le cœur qui bat (de plus en plus fort)
        if 8 <= i < 22:
            battement(S, i, 0.18 + 0.02 * (i - 8))
        if rng.random() < 0.25:
            S.add("twinkle", twinkle(rng), S.t(i, float(rng.uniform(0, 4))), float(rng.uniform(0.04, 0.1)), float(rng.uniform(-0.9, 0.9)))
    # la berceuse de la boîte à musique (qui se dérègle : des notes fausses, des silences)
    ber1 = "A5:1 D6:1 F6:1 E6:1 | D6:2 A5:2 | A#5:1 A5:1 G5:1 A5:1 | F5:3 r:1"
    ber2 = "A5:1 D6:1 F6:1 E6:1 | D6:2 C#6:2 | D6:1 r:1 G#5:1 A5:1 | D5:3 r:1"
    melody(S, "boite", "box", 2, ber1, 0.42, synth=boite)
    melody(S, "boite", "box", 18, ber2, 0.4, synth=boite)
    melody(S, "boite", "box", 22, "A5:1 D6:1 F6:1 E6:1 | D6:4", 0.3, synth=boite)
    # le thérémine qui gémit
    theremin(S, "theremin", 12, "D5:2 C#5:2 | D5:3 r:1 | A#4:2 A4:2 | G#4:4", 0.32, octave=0, seed=1213)
    # l'orgue du comte
    melody(S, "orgue_doux", "organ", 16, "D4:1 A3:1 A#3:1 A3:1 | G#3:1 A3:3 | D4:1 F4:1 E4:1 D4:1 | C#4:2 D4:2", 0.38)
    melody(S, "orgue_doux", "organ", 20, "A#3:1 A3:1 G3:1 F3:1 | E3:2 D#3:2 | D3:4 | r:4", 0.34)
    for b, f in ((5, "windchimes_random.wav"), (19, "windchimes_slowDesc1.wav")):
        mark_tree(S, b, f, 0.12, rng=rng)
    # le souffle des profondeurs (très grave, lent)
    for b in range(0, 24, 2):
        n = int(8 * S.spb * SR)
        x = np.arange(n) / SR
        f0 = hz(notes_of(NUIT, prog[b])[0]) * 0.5
        y = (np.sin(2 * np.pi * f0 * x) + 0.4 * np.sin(2 * np.pi * f0 * 1.06 * x + 1)) * np.sin(np.pi * x / x[-1]) ** 2
        S.add("deep", y * 0.09, S.t(b), 1.0)
    S.fx["pad"] = lambda x: filt(x, bw("highpass", 90)) * 0.7
    S.fx["low"] = lambda x: x * 0.6
    S.fx["organ_low"] = lambda x: x * 0.5
    S.fx["trem"] = lambda x: x * 0.6
    S.fx["choir"] = lambda x: filt(x, bw("highpass", 160)) * 1.1
    S.fx["heart"] = lambda x: filt(x, bw("lowpass", 400)) * 1.2
    S.fx["box"] = lambda x: echo(x, S.spb * 0.75, 0.35, 4, 6000, True, True) * 0.9
    S.fx["theremin"] = lambda x: echo(x, S.spb * 0.75, 0.25, 3, 3500, True, True) * 0.9
    S.fx["organ"] = lambda x: x * 0.8
    S.fx["far"] = lambda x: x * 0.7
    S.fx["twinkle"] = lambda x: echo(x, S.spb * 0.5, 0.45, 5, 9000, True, True) * 0.5
    S.fx["deep"] = lambda x: x * 0.5
    S.send.update({"pad": 0.5, "low": 0.35, "organ_low": 0.4, "trem": 0.75, "choir": 0.8, "heart": 0.2, "box": 0.8,
                   "theremin": 0.7, "organ": 0.75, "far": 0.85, "twinkle": 0.85, "deep": 0.25})
    return S


PIECES = {
    "sombreval": (ville_morte, -20.0, (6.5, 0.45, 0.05, 26, 0.14), (-24.0, 1.5)),
}


def main() -> int:
    args = sys.argv[1:]
    while args:
        a = args.pop(0)
        if a == "--vsco":
            m76.VSCO = Path(args.pop(0))
        elif a == "--vcsl":
            m76.VCSL = Path(args.pop(0))
        elif a == "--cc0":
            m76.CC0 = Path(args.pop(0))
    m75.VSCO, m75.VCSL, m75.CC0 = m76.VSCO, m76.VCSL, m76.CC0
    m75.TMP = Path(m75.tempfile.gettempdir()) / "musique_v121"
    cm70.VCSL = m76.VCSL
    cm51.VSCO = m76.VSCO
    import generate_sons_v63 as s63
    s63.LIB = m76.CC0
    kit = m75.Kit(seed=121)
    for name, (fn, target, (sec, dark, pre, er, span), glue) in PIECES.items():
        S = fn(kit)
        ir = m75.room_ir(sec, dark, pre, er, S.seed, span)
        S.render(m76.OUT / f"{name}.ogg", target, -2.0, ir, glue, None)
        m76.release_instruments()
        del S
        gc.collect()
    try:
        m75.TMP.rmdir()
    except OSError:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
