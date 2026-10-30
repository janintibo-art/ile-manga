"""V89 : la musique de la Salle du Chant, sous le Grand Moaï (l'Île aux Moaïs).

Composition originale pour « Les Mondes de Travers », versée au domaine public (CC0 1.0). Elle est
jouée avec les outils des V75 et V76 (compose_musique_v75.py, compose_musique_v76.py : le morceau,
ses bus, la salle, le mastering, la boucle sans raccord, le chœur doux synthétisé) et l'orchestre
VSCO-2 CE et la VCSL (Versilian Studios, CC0) : verres frottés, harpe, contrebasses, violoncelles,
flûte, arbres à clochettes.

  salle_du_chant.ogg  « La Salle du Chant » : ré dorien, 56 à la noire, en boucle (32 mesures,
                      ~2 min 17). Une caverne qui respire : la nappe grave, les contrebasses en
                      bourdon, les gouttes d'eau du célesta (en écho), les verres frottés chantent
                      l'air (ré, fa, sol, la, do : la gamme des Pierres-qui-Chantent), le chœur doux
                      des voix de pierre qui monte au milieu, la harpe en glissandos, la flûte grave
                      qui reprend l'air à la fin, et le souffle des profondeurs.

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/compose_musique_v89.py [--vsco <VSCO-2-CE>] [--vcsl <VCSL>] [--cc0 <CC0-…>]
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
notes_of, harp_gliss, sprinkle, chord_tones, mark_tree = m76.notes_of, m76.harp_gliss, m76.sprinkle, m76.chord_tones, m76.mark_tree

CHANT = {   # accord : (basse, notes de la nappe)
    "Dm9": ("D2", "F3 A3 C4 E4"), "Bbmaj7": ("A#1", "D3 F3 A3 C4"), "Gm9": ("G1", "A#3 D4 F4 A4"),
    "Am7": ("A1", "A3 C4 E4 G4"), "Fmaj7": ("F1", "A3 C4 E4 F4"), "Cadd9": ("C2", "G3 C4 D4 E4"),
    "Asus": ("A1", "D3 E3 A3 D4"), "Gm/D": ("D2", "G3 A#3 D4 F4"),
}


def goutte(m: float, rng) -> np.ndarray:
    """Une goutte d'eau qui tombe dans la vasque : un célesta très court, une pointe de « plic »."""
    y = celesta(m, 0.6, 0.45, rng)
    n = int(0.05 * SR)
    x = np.arange(n) / SR
    plic = np.sin(2 * np.pi * (1800 + 2600 * x / x[-1]) * x) * np.exp(-x / 0.012) * 0.25
    y[:n] += plic
    return y


def salle_du_chant(kit) -> Song:
    S = Song("salle_du_chant", 56, 32, loop=True, seed=891)
    rng = np.random.default_rng(8910)
    P1 = ["Dm9", "Dm9", "Bbmaj7", "Bbmaj7", "Gm9", "Gm9", "Am7", "Am7"]
    P2 = ["Fmaj7", "Fmaj7", "Cadd9", "Cadd9", "Dm9", "Dm9", "Bbmaj7", "Asus"]
    P3 = ["Gm9", "Bbmaj7", "Dm9", "Cadd9", "Gm9", "Bbmaj7", "Am7", "Am7"]
    P4 = ["Dm9", "Gm/D", "Bbmaj7", "Fmaj7", "Gm9", "Cadd9", "Asus", "Am7"]
    prog = P1 + P2 + P3 + P4
    mel1 = "A4:3 G4:1 | F4:4 | D4:2 F4:2 | A4:4 | G4:3 F4:1 | D4:4 | E4:2 G4:2 | A4:4"
    mel2 = "C5:3 A4:1 | G4:4 | E4:2 G4:2 | D5:4 | C5:2 A4:2 | F4:4 | G4:2 A4:2 | E4:4"
    mel3 = "D5:4 | C5:2 A4:2 | G4:4 | F4:2 G4:2 | A4:3 C5:1 | D5:4 | C5:2 A4:2 | A4:4"
    mel4 = "A4:3 C5:1 | D5:4 | A4:2 G4:2 | F4:4 | G4:3 A4:1 | E4:4 | D4:2 E4:2 | A3:4"
    for i, c in enumerate(prog):
        bass, notes = notes_of(CHANT, c)
        for m in notes:
            S.add("pad", pad(m, 4 * S.spb + 0.6, 0.45, rng, cutoff=1100, attack=2.5, release=3.2), S.t(i) - 0.7, 1.0)
        play(S, "cb", "low", bass, i, 0, 4.4, 0.3)
        if i % 2 == 0:
            play(S, "vc", "low", bass + 12, i, 0, 8.4, 0.14)
        # le chœur des voix de pierre (au milieu du morceau)
        if 8 <= i < 28:
            for m in notes[-3:]:
                play(S, "choeur_doux", "choir", m + 12, i, 0, 4.4, 0.32 if i < 16 else 0.42)
        if i % 4 == 0:
            harp_gliss(S, i, 0.0, [notes[0] + 12, notes[1] + 12, notes[2] + 12, notes[3] + 12, notes[1] + 24], 1.6, 0.26)
        # les gouttes (dans la gamme des Pierres-qui-Chantent)
        tones = [t for t in chord_tones(notes, 74, 98) if t % 12 in (2, 5, 7, 9, 0)]
        for _ in range(int(rng.integers(1, 4))):
            if tones:
                S.add("drops", goutte(tones[int(rng.integers(0, len(tones)))], rng), S.t(i, float(rng.choice([0.0, 1.5, 2.0, 3.0, 3.5]))),
                      float(rng.uniform(0.2, 0.42)), float(rng.uniform(-0.8, 0.8)))
        if rng.random() < 0.3:
            S.add("twinkle", twinkle(rng), S.t(i, float(rng.uniform(0, 4))), float(rng.uniform(0.05, 0.14)), float(rng.uniform(-0.9, 0.9)))
    melody(S, "verres", "glass", 0, mel1, 0.34, legato=0.4)
    melody(S, "verres", "glass", 8, mel2, 0.3, legato=0.4)
    melody(S, "verres", "glass", 16, mel3, 0.38, legato=0.4)
    melody(S, "flute", "flute", 16, mel3, 0.16, octave=-1, legato=0.1)
    melody(S, "flute", "flute", 24, mel4, 0.24, legato=0.1)
    melody(S, "verres", "glass", 24, mel4, 0.2, octave=1, legato=0.4)
    for b, f in ((0, "windchimes_slowDesc1.wav"), (14, "windchimes_random.wav"), (27, "windchimes_slowAsc1.wav")):
        mark_tree(S, b, f, 0.22, rng=rng)
    # le souffle des profondeurs (très grave, lent)
    for b in range(0, 32, 2):
        n = int(8 * S.spb * SR)
        x = np.arange(n) / SR
        f0 = hz(notes_of(CHANT, prog[b])[0])
        y = (np.sin(2 * np.pi * f0 * x) + 0.35 * np.sin(2 * np.pi * f0 * 1.5 * x + 1)) * np.sin(np.pi * x / x[-1]) ** 2
        S.add("deep", y * 0.08, S.t(b), 1.0)
    S.fx["pad"] = lambda x: filt(x, bw("highpass", 150)) * 0.75
    S.fx["low"] = lambda x: x * 0.55
    S.fx["glass"] = lambda x: echo(x, S.spb * 1.5, 0.22, 3, 5000, True, True) * 0.9
    S.fx["harp"] = lambda x: x * 0.7
    S.fx["choir"] = lambda x: filt(x, bw("highpass", 160)) * 1.25
    S.fx["drops"] = lambda x: echo(x, S.spb * 0.75, 0.45, 5, 7000, True, True) * 0.9
    S.fx["flute"] = lambda x: x * 0.9
    S.fx["far"] = lambda x: x * 0.8
    S.fx["twinkle"] = lambda x: echo(x, S.spb * 0.5, 0.45, 5, 9000, True, True) * 0.6
    S.fx["deep"] = lambda x: x * 0.4
    S.send.update({"pad": 0.45, "low": 0.35, "glass": 0.7, "harp": 0.6, "choir": 0.75, "drops": 0.85,
                   "flute": 0.6, "far": 0.85, "twinkle": 0.85, "deep": 0.25})
    return S


PIECES = {
    "salle_du_chant": (salle_du_chant, -20.0, (5.5, 0.4, 0.045, 24, 0.12), (-24.0, 1.5)),
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
    m75.TMP = Path(m75.tempfile.gettempdir()) / "musique_v89"
    cm70.VCSL = m76.VCSL
    cm51.VSCO = m76.VSCO
    import generate_sons_v63 as s63
    s63.LIB = m76.CC0
    kit = m75.Kit(seed=89)
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
