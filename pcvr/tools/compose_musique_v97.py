"""V97 : la musique de l'Île Al Dente (composée ici, versée au domaine public, CC0 1.0).

  musique/al_dente.ogg  « Al Dente » : une tarentelle en 6/8, la mineur puis do majeur, 64 mesures en
                        boucle (~1 min), la croche à 384 par minute. La mandoline en trémolo chante l'air
                        (des cordes de Karplus-Strong pincées très vite), l'accordéon « musette » (deux
                        anches un peu désaccordées) fait le « poum-tchac-tchac », la contrebasse en
                        pizzicati marque les temps, le tambourin (VCSL, CC0) secoue tout ; la clarinette
                        reprend l'air la troisième fois, le glockenspiel scintille à la fin.
                        Contrebasse, clarinette, glockenspiel : VSCO-2 CE (Versilian Studios, CC0).
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/compose_musique_v97.py [--vsco <VSCO-2-CE>] [--vcsl <VCSL>]
"""
from __future__ import annotations

from pathlib import Path
import gc
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v75 as m75  # noqa: E402

SR = m75.SR
Song, drums = m75.Song, m75.drums
filt, bw, shelf, peak, room_ir, pan2 = m75.filt, m75.bw, m75.shelf, m75.peak, m75.room_ir, m75.pan2
RNG = np.random.default_rng(9797)

# l'air (A : la mineur ; B : do majeur), en croches (6 par mesure)
AIR_A = ("E5:1 E5:1 E5:1 F5:1 E5:1 D5:1 | C5:1 D5:1 E5:1 A4:3 | B4:1 C5:1 D5:1 E5:1 D5:1 C5:1 | B4:1 G#4:1 B4:1 E4:3 | "
         "D5:1 D5:1 D5:1 E5:1 D5:1 C5:1 | B4:1 C5:1 D5:1 G#4:3 | A4:1 B4:1 C5:1 B4:1 C5:1 D5:1 | E5:3 A4:3 | "
         "A5:1 G5:1 F5:1 E5:1 D5:1 C5:1 | B4:1 C5:1 D5:1 E5:3 | F5:1 F5:1 F5:1 E5:1 D5:1 F5:1 | A5:2 F5:1 D5:3 | "
         "E5:1 F5:1 E5:1 D5:1 C5:1 B4:1 | G#4:1 A4:1 B4:1 E5:3 | C5:1 B4:1 A4:1 B4:1 G#4:1 B4:1 | A4:3 r:3")
AIR_B = ("E5:2 G5:1 C6:2 G5:1 | E5:1 F5:1 G5:1 E5:3 | D5:2 F5:1 B5:2 G5:1 | D5:1 E5:1 F5:1 D5:3 | "
         "B4:1 D5:1 G5:1 F5:1 E5:1 D5:1 | G5:3 G4:3 | C5:1 E5:1 G5:1 C6:1 B5:1 A5:1 | G5:3 E5:3 | "
         "A5:1 G5:1 F5:1 A5:1 G5:1 F5:1 | E5:1 D5:1 C5:1 F5:3 | E5:1 G5:1 C6:1 E5:1 G5:1 C6:1 | E6:3 C6:3 | "
         "D6:1 C6:1 B5:1 A5:1 G5:1 F5:1 | E5:1 F5:1 G5:1 D5:3 | C5:1 E5:1 G5:1 C6:3 | B5:1 G#5:1 E5:1 B4:3")
PROG_A = ["Am", "Am", "E", "E", "E", "E", "Am", "Am", "Am", "Am", "Dm", "Dm", "Am", "E", "E", "Am"]
PROG_B = ["C", "C", "G", "G", "G", "G", "C", "C", "F", "F", "C", "C", "G", "G", "C", "E"]
TRIADS = {"Am": [57, 60, 64], "E": [56, 59, 64], "Dm": [57, 62, 65], "C": [55, 60, 64], "G": [55, 59, 62], "F": [57, 60, 65]}
ROOTS = {"Am": (33, 40), "E": (28, 35), "Dm": (38, 33), "C": (36, 31), "G": (31, 38), "F": (29, 36)}


def hz(m: float) -> float:
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def mandoline(m: float, dur: float, vel: float) -> np.ndarray:
    """Une note de mandoline : un coup de médiator, puis, si la note est longue, le trémolo (des
    allers-retours très rapides sur la paire de cordes, un peu désaccordées)."""
    n = int((dur + 0.5) * SR)
    out = np.zeros(n)
    strokes = 1 if dur < 0.3 else int(dur / 0.058)
    for k in range(strokes):
        t0 = k * 0.058 + float(RNG.normal(0, 0.003))
        v = vel * (1.0 if k == 0 else 0.55 + 0.1 * (k % 2))
        for det in (-3.0, 3.0):
            f = hz(m) * 2.0 ** (det / 1200.0)
            x = m75.string(f, 0.6 if k < strokes - 1 else 0.9, RNG, t60=0.9, bright=0.85, pick=0.08, vel=v, hard=0.75)
            i = int(max(t0, 0.0) * SR)
            k2 = min(len(x), n - i)
            if k2 > 0:
                out[i:i + k2] += x[:k2] * 0.5
    # le corps en poire de la mandoline : un creux dans le bas-médium, de la présence
    return filt(out, bw("highpass", 180), peak(900, 3.0, 1.0), peak(2600, 4.0, 1.2), bw("lowpass", 9000)).astype(np.float32)


def anche(f: float, n: int) -> np.ndarray:
    t = np.arange(n) / SR
    ph = (t * f) % 1.0
    # une anche libre : une onde entre le carré et la dent de scie
    return (np.where(ph < 0.42, 1.0, -0.7) + (2.0 * ph - 1.0) * 0.5)


def accordeon(notes: list, dur: float, vel: float) -> np.ndarray:
    """L'accordéon musette : pour chaque note, deux anches (une juste, une un peu haute) et une à
    l'octave en dessous ; le soufflet donne une attaque douce et un léger vibrato d'amplitude."""
    n = int((dur + 0.12) * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for m in notes:
        f = hz(m)
        out += anche(f, n) + anche(f * 2.0 ** (12.0 / 1200.0), n) * 0.9 + anche(f * 0.5, n) * 0.5
    env = np.clip(t / 0.025, 0, 1) * np.clip((dur + 0.1 - t) / 0.08, 0, 1)
    out *= env * (1.0 + 0.06 * np.sin(2 * np.pi * 5.5 * t)) * vel / max(len(notes), 1)
    return filt(out, bw("lowpass", 3400, 2), peak(1400, 3.0, 1.2), bw("highpass", 120)).astype(np.float32) * 0.35


def al_dente(kit) -> Song:
    S = Song("al_dente", 384, 64, beats=6, loop=True, seed=97)
    sections = [(0, AIR_A, PROG_A, "mando"), (16, AIR_B, PROG_B, "accordeon"), (32, AIR_A, PROG_A, "clar"), (48, AIR_B, PROG_B, "tutti")]
    for bar0, air, prog, lead in sections:
        # l'air
        if lead in ("mando", "tutti", "clar"):
            m75.melody(S, "mando", "mando", bar0, air, 0.8 if lead != "clar" else 0.5, octave=0 if lead != "clar" else 1, synth=mandoline)
        if lead == "accordeon":
            m75.melody(S, "acc_lead", "acc_lead", bar0, air, 0.85, synth=lambda m, d, v: accordeon([m, m - 12], d, v))
        if lead == "clar":
            m75.melody(S, "clar_stac", "clar", bar0, air, 0.75, legato=0.01)
        if lead == "tutti":
            m75.melody(S, "clar_stac", "clar", bar0, air, 0.5, octave=-1, legato=0.01)
        for i, sym in enumerate(prog):
            bar = bar0 + i
            r1, r2 = ROOTS[sym]
            # la contrebasse : les deux temps forts (1 et 4)
            m75.play(S, "cb_pizz", "basse", r1 + 12, bar, 0.0, 2.0, 0.9)
            m75.play(S, "cb_pizz", "basse", r2 + 12, bar, 3.0, 2.0, 0.8)
            # l'accordéon : « tchac-tchac » sur les croches 2-3 et 5-6
            for b in (1.0, 2.0, 4.0, 5.0):
                x = accordeon(TRIADS[sym], 0.13, 0.8 if b in (1.0, 4.0) else 0.65)
                S.add("acc", x, S.t(bar, b) + float(RNG.normal(0, 0.004)), 1.0, 0.25)
            # le tambourin
            drums(S, kit, bar, {"tb": "x.x.x.x.x.x." if lead != "mando" else "x...x.x...x.", "k": "x.....x....." if lead == "tutti" else "", }, 0.6)
            # le glockenspiel, à la fin : la tierce et la quinte de l'accord, en haut
            if lead == "tutti" and i % 2 == 0:
                t3 = TRIADS[sym]
                m75.play(S, "glock", "glock", t3[1] + 24, bar, 0.0, 2.0, 0.35)
                m75.play(S, "glock", "glock", t3[2] + 24, bar, 3.0, 2.0, 0.3)
    S.fx["mando"] = lambda x: x * 1.0
    S.fx["acc"] = lambda x: filt(x, shelf(5000, -2.0)) * 0.9
    S.fx["acc_lead"] = lambda x: x * 1.0
    S.fx["basse"] = lambda x: x * 1.3
    S.fx["clar"] = lambda x: x * 0.9
    S.fx["glock"] = lambda x: x * 0.45
    m75.drum_fx(S, False)
    S.send.update({"mando": 0.2, "acc": 0.15, "acc_lead": 0.2, "basse": 0.05, "clar": 0.25, "glock": 0.35})
    return S


def main() -> int:
    args = sys.argv[1:]
    while args:
        a = args.pop(0)
        if a == "--vcsl":
            m75.VCSL = Path(args.pop(0))
        elif a == "--vsco":
            m75.VSCO = Path(args.pop(0))
    kit = m75.Kit()
    S = al_dente(kit)
    ir = room_ir(1.4, 0.55, 0.012, 14, S.seed, 0.05)
    S.render(m75.OUT / "al_dente.ogg", -18.5, -2.0, ir, (-18.0, 2.0), None)
    m75.release_instruments()
    gc.collect()
    print("V97 : al_dente.ogg")
    return 0


if __name__ == "__main__":
    sys.exit(main())
