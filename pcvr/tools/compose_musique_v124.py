"""V124 : les musiques du château du comte Dracula, à Sombreval.

Compositions originales pour « Les Mondes de Travers », versées au domaine public (CC0 1.0). Elles sont
jouées avec les outils des V75 et V76 (compose_musique_v75.py, compose_musique_v76.py : le morceau,
ses bus, la salle, le mastering, la boucle sans raccord, le chœur doux synthétisé), l'orchestre VSCO-2
CE et la VCSL (Versilian Studios, CC0 : cordes, timbales, le grand orgue, le clavecin français).

  chateau_comte.ogg  « Le Château du Comte » : ré mineur, 54 à la noire, en boucle (26 mesures, ~1 min 56).
                     Un bourdon d'orgue et de contrebasse tout au fond, une nappe sombre ; puis la basse
                     descend en lamento (ré, do dièse, do, si, si bémol, la…) sous des notes de clavecin
                     qui tombent une à une, comme des gouttes ; les violoncelles et les altos tiennent
                     l'harmonie, les violons frémissent tout là-haut (une seconde mineure) ; au milieu,
                     l'orgue doux chante la complainte du comte avec le chœur sans paroles ; des
                     roulements de timbales viennent gronder avant chaque retour. Inquiétant, jamais fort.
  bal_vampires.ogg   « Le Bal des Vampires » : une valse macabre à trois temps, ré mineur, 132 à la noire,
                     en boucle (72 mesures, ~1 min 38). Le clavecin joue l'air, la basse en pizzicati et
                     les accords « oum-pa-pa » ; puis les violons reprennent la valse, le célesta la
                     double comme une boîte à musique fantôme ; un passage en si bémol où le violon seul
                     chante, plus inquiétant, sur des trémolos ; tout le bal danse (cordes, clavecin,
                     chœur, timbales) ; et une coda où l'orgue et le chœur ramènent la boucle.

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/compose_musique_v124.py [--vsco <VSCO-2-CE>] [--vcsl <VCSL>] [--cc0 <CC0-…>] [morceaux…]
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
notes_of, mark_tree = m76.notes_of, m76.mark_tree


def fantome(m: float, dur: float, vel: float = 0.5) -> np.ndarray:
    """Le célesta fantôme (une boîte à musique un peu fausse : la lame sonne un rien trop bas)."""
    return celesta(m - 0.15, dur, vel * 0.8, np.random.default_rng(int(m * 37)))


# =========================================================================== le château du comte

CHATEAU = {   # accord : (basse, notes de la nappe)
    "Dm": ("D2", "D3 F3 A3 D4"), "Gm/D": ("D2", "D3 G3 A#3 D4"), "Eb/D": ("D2", "D#3 G3 A#3 D4"),
    "A7b9": ("A1", "C#3 G3 A#3 E4"), "A/C#": ("C#2", "C#3 E3 A3 E4"), "Dm/C": ("C2", "C3 F3 A3 D4"),
    "G/B": ("B1", "B2 F3 G3 D4"), "Bb": ("A#1", "D3 F3 A#3 D4"), "Gm": ("G1", "G3 A#3 D4 G4"),
    "A": ("A1", "C#3 E3 A3 E4"), "Dm9": ("D2", "E3 F3 A3 D4"),
}


def chateau_comte(kit) -> Song:
    S = Song("chateau_comte", 54, 26, loop=True, seed=1241)
    rng = np.random.default_rng(12410)
    prog = ["Dm", "Dm", "Gm/D", "Dm", "Eb/D", "Dm", "A7b9", "A7b9",
            "Dm", "A/C#", "Dm/C", "G/B", "Bb", "Gm", "A", "A7b9",
            "Dm", "A/C#", "Dm/C", "G/B", "Bb", "Eb/D", "Gm", "A7b9",
            "Dm9", "A7b9"]
    for i, c in enumerate(prog):
        bass, notes = notes_of(CHATEAU, c)
        # la nappe sombre, toujours là
        for m in notes:
            S.add("pad", pad(m, 4 * S.spb + 0.6, 0.32, rng, cutoff=650, attack=2.6, release=3.5), S.t(i) - 0.8, 1.0)
        # la contrebasse, et le bourdon de pédale de l'orgue (ré grave au début, puis la basse qui descend)
        play(S, "cb", "low", bass, i, 0, 4.4, 0.3)
        if i < 8:
            if i % 2 == 0:
                play(S, "orgue_pedale", "organ_low", 26, i, 0, 8.4, 0.22)
        else:
            play(S, "orgue_pedale", "organ_low", bass, i, 0, 4.3, 0.18)
        # les violoncelles (la basse à l'octave) et les altos (la tierce de l'accord), à partir du lamento
        if i >= 8:
            play(S, "vc", "strings", bass + 12, i, 0, 4.2, 0.3)
            play(S, "vla", "strings", notes[1] + 12, i, 0.5, 3.8, 0.2)
        # les violons qui frémissent tout là-haut (une seconde mineure qui grince)
        if i % 8 == 4:
            play(S, "vln_trem", "trem", 81, i, 0, 14.0, 0.07)
            play(S, "vln_trem", "trem", 82, i, 1.5, 12.0, 0.05)
        # le chœur sans paroles, pendant la complainte
        if 16 <= i < 24:
            for m in notes[-3:]:
                play(S, "choeur_doux", "choir", m + 12, i, 0, 4.4, 0.24 if i < 20 else 0.3)
        # le clavecin, pendant la complainte : quelques notes brisées, à contretemps
        if 16 <= i < 24:
            tones = sorted(n + 24 for n in notes[1:])
            for b in (1.5, 2.5):
                if rng.random() < 0.7:
                    play(S, "clavecin", "hpsi", int(rng.choice(tones)), i, b, 0.6, 0.22)
        if rng.random() < 0.2:
            S.add("twinkle", twinkle(rng), S.t(i, float(rng.uniform(0, 4))), float(rng.uniform(0.03, 0.07)), float(rng.uniform(-0.9, 0.9)))
    # le clavecin qui égrène le lamento, note à note, comme des gouttes
    melody(S, "clavecin", "hpsi", 8, "D5:1.5 A4:0.5 F5:2 | E5:1.5 C#5:0.5 A4:2 | F5:1.5 A5:0.5 D5:2 | F5:1.5 D5:0.5 B4:2 | "
                                     "A#4:1.5 D5:0.5 F5:2 | G5:1.5 D5:0.5 A#4:2 | A4:1.5 C#5:0.5 E5:2 | G5:1 F5:1 E5:1 C#5:1", 0.4)
    # au début, une boîte à musique perdue (trois notes, très loin)
    melody(S, "fantome", "box", 2, "A5:2 D6:1 F6:1 | E6:4", 0.3, synth=fantome)
    melody(S, "fantome", "box", 24, "A5:2 D6:1 F6:1 | E6:2 C#6:2", 0.26, synth=fantome)
    # la complainte du comte, à l'orgue doux
    melody(S, "orgue_doux", "organ", 16, "A4:2 D5:2 | C#5:3 E5:1 | F5:2 E5:1 D5:1 | D5:2 B4:2 | "
                                         "A#4:2 D5:1 F5:1 | G5:3 D#5:1 | D5:2 A#4:2 | C#5:2 A4:2", 0.36)
    # les timbales : un coup sourd au début de chaque partie, un roulement qui gronde avant chaque retour
    for b in (0, 8, 16):
        play(S, "timp", "timp", 38, b, 0, 2.0, 0.28)
    for b in (7, 15, 23, 25):
        play(S, "timp_roll", "timp", 45, b, 1.0, 3.0, 0.22 if b != 25 else 0.16)
    for b, f in ((5, "windchimes_random.wav"), (21, "windchimes_slowDesc1.wav")):
        mark_tree(S, b, f, 0.08, rng=rng)
    # le souffle des profondeurs (très grave, lent)
    for b in range(0, 26, 2):
        n = int(8 * S.spb * SR)
        x = np.arange(n) / SR
        f0 = hz(notes_of(CHATEAU, prog[b])[0]) * 0.5
        y = (np.sin(2 * np.pi * f0 * x) + 0.4 * np.sin(2 * np.pi * f0 * 1.06 * x + 1)) * np.sin(np.pi * x / x[-1]) ** 2
        S.add("deep", y * 0.08, S.t(b), 1.0)
    S.fx["pad"] = lambda x: filt(x, bw("highpass", 90)) * 0.7
    S.fx["low"] = lambda x: x * 0.6
    S.fx["organ_low"] = lambda x: x * 0.5
    S.fx["strings"] = lambda x: filt(x, bw("lowpass", 5000)) * 0.75
    S.fx["trem"] = lambda x: x * 0.6
    S.fx["choir"] = lambda x: filt(x, bw("highpass", 160)) * 1.0
    S.fx["hpsi"] = lambda x: echo(x, S.spb * 0.75, 0.3, 3, 4500, True, True) * 0.8
    S.fx["box"] = lambda x: echo(x, S.spb * 0.75, 0.35, 4, 6000, True, True) * 0.7
    S.fx["organ"] = lambda x: x * 0.8
    S.fx["timp"] = lambda x: filt(x, bw("lowpass", 1500)) * 0.9
    S.fx["far"] = lambda x: x * 0.6
    S.fx["twinkle"] = lambda x: echo(x, S.spb * 0.5, 0.45, 5, 9000, True, True) * 0.5
    S.fx["deep"] = lambda x: x * 0.5
    S.send.update({"pad": 0.5, "low": 0.35, "organ_low": 0.4, "strings": 0.55, "trem": 0.75, "choir": 0.8, "hpsi": 0.7,
                   "box": 0.85, "organ": 0.75, "timp": 0.45, "far": 0.85, "twinkle": 0.85, "deep": 0.25})
    return S


# =========================================================================== le bal des vampires

VALSE = {   # accord : (basse, accord du « pa-pa »)
    "Dm": ("D2", "A3 D4 F4"), "Gm": ("G2", "A#3 D4 G4"), "A7": ("A1", "C#4 E4 G4"), "A7b9": ("A1", "C#4 G4 A#4"),
    "Bb": ("A#1", "A#3 D4 F4"), "F": ("F2", "A3 C4 F4"), "C7": ("C2", "A#3 C4 E4"),
}
PROG_A = ["Dm", "Dm", "Gm", "Gm", "A7", "A7", "Dm", "Dm", "Dm", "Dm", "Gm", "Gm", "Bb", "A7", "Dm", "A7"]
PROG_B = ["Bb", "Bb", "F", "F", "Gm", "Gm", "A7", "A7", "Bb", "Bb", "F", "Dm", "Gm", "A7b9", "Dm", "A7"]
PROG_C = ["Dm", "Gm", "A7b9", "A7b9", "Dm", "Bb", "A7", "A7"]
AIR_A = ("A4:2 D5:1 | F5:1.5 E5:0.5 D5:1 | A#5:2 G5:1 | D5:3 | C#5:2 E5:1 | G5:1.5 F5:0.5 E5:1 | F5:2 D5:1 | A4:3 | "
         "A4:2 D5:1 | F5:1.5 E5:0.5 D5:1 | A#5:2 D6:1 | G5:3 | F5:1 A#5:1 F5:1 | E5:1 C#5:1 A4:1 | D5:3 | r:1 E5:1 C#5:1")
AIR_B = ("D5:3 | F5:2 D5:1 | C5:3 | A4:3 | A#4:2 D5:1 | G5:2 F5:1 | E5:3 | C#5:2 A4:1 | "
         "D5:2 F5:1 | A#5:2 A5:1 | A5:2 G5:1 | F5:3 | G5:1.5 F5:0.5 E5:1 | E5:2 C#5:1 | D5:3 | E5:2 C#5:1")
AIR_C = "A5:2 D6:1 | A#5:3 | A5:2 G5:1 | C#5:3 | D5:2 F5:1 | D5:3 | C#5:1 E5:1 G5:1 | A5:1 r:2"


def oum_pa_pa(S: Song, bar0: int, prog: list, vel: float = 1.0, cordes: bool = False, pizz_hauts: bool = False) -> None:
    """L'accompagnement de valse : la basse au premier temps, l'accord sur les deux suivants."""
    for i, c in enumerate(prog):
        b = bar0 + i
        bass, ch = notes_of(VALSE, c)
        play(S, "cb_pizz", "bass", bass, b, 0, 1.0, 0.55 * vel)
        play(S, "vc_pizz", "bass", bass + 12, b, 0, 1.0, 0.4 * vel)
        play(S, "clavecin", "hpsi_acc", bass + 12, b, 0, 0.9, 0.42 * vel)
        for beat in (1, 2):
            for m in ch:
                play(S, "clavecin", "hpsi_acc", m, b, beat, 0.45, 0.3 * vel, human=0.004)
            if pizz_hauts:
                play(S, "vla_pizz", "pizz", ch[1], b, beat, 0.5, 0.3 * vel)
        if cordes and i % 2 == 0:
            play(S, "vc", "strings", bass + 12, b, 0, 6.0, 0.24 * vel)
            play(S, "vla", "strings", ch[1], b, 0, 6.0, 0.18 * vel)


def bal_vampires(kit) -> Song:
    S = Song("bal_vampires", 132, 72, beats=3, loop=True, seed=1242)
    rng = np.random.default_rng(12420)
    # A : le clavecin joue l'air, l'orchestre fait « oum-pa-pa »
    oum_pa_pa(S, 0, PROG_A, 0.9)
    melody(S, "clavecin", "hpsi", 0, AIR_A, 0.55)
    # A : les violons reprennent la valse, le célesta la double (une boîte à musique fantôme)
    oum_pa_pa(S, 16, PROG_A, 0.95, cordes=True)
    melody(S, "vln", "lead", 16, AIR_A, 0.42, legato=0.05)
    melody(S, "fantome", "box", 16, AIR_A, 0.2, octave=1, synth=fantome)
    # B : en si bémol, le violon seul, plus inquiétant ; les violons frémissent derrière
    oum_pa_pa(S, 32, PROG_B, 0.8, pizz_hauts=True)
    melody(S, "solo_vln", "solo", 32, AIR_B, 0.45, legato=0.05)
    for b in (32, 40):
        play(S, "vln_trem", "trem", 81, b, 0, 22.0, 0.06)
        play(S, "vln_trem", "trem", 82, b, 1.0, 21.0, 0.045)
    for b in range(32, 48, 4):
        play(S, "timp", "timp", notes_of(VALSE, PROG_B[b - 32])[0] + 12, b, 0, 2.0, 0.22)
    # A : tout le bal danse (les violons, le clavecin à l'octave, le chœur, les timbales)
    oum_pa_pa(S, 48, PROG_A, 1.0, cordes=True, pizz_hauts=True)
    melody(S, "vln", "lead", 48, AIR_A, 0.48, legato=0.05)
    melody(S, "clavecin", "hpsi", 48, AIR_A, 0.4, octave=1)
    for i, c in enumerate(PROG_A):
        if i % 2 == 0:
            _, ch = notes_of(VALSE, c)
            for m in ch:
                play(S, "choeur_doux", "choir", m + 12, 48 + i, 0, 6.0, 0.2)
        if i % 4 == 0:
            play(S, "timp", "timp", notes_of(VALSE, c)[0] + 12, 48 + i, 0, 2.0, 0.26)
    # coda : l'orgue doux, le chœur et le célesta, la valse qui se suspend avant de repartir
    for i, c in enumerate(PROG_C):
        bass, ch = notes_of(VALSE, c)
        b = 64 + i
        play(S, "cb_pizz", "bass", bass, b, 0, 1.0, 0.45)
        play(S, "clavecin", "hpsi_acc", bass + 12, b, 0, 0.9, 0.3)
        for beat in (1, 2):
            for m in ch:
                play(S, "clavecin", "hpsi_acc", m, b, beat, 0.45, 0.2, human=0.004)
        play(S, "orgue_doux", "organ", bass + 12, b, 0, 3.1, 0.26)
        for m in ch:
            play(S, "orgue_doux", "organ", m, b, 0, 3.1, 0.16)
            play(S, "choeur_doux", "choir", m + 12, b, 0, 3.4, 0.22)
    melody(S, "fantome", "box", 64, AIR_C, 0.45, synth=fantome)
    play(S, "vln_trem", "trem", 81, 64, 0, 22.0, 0.06)
    play(S, "timp_roll", "timp", 45, 70, 0, 6.0, 0.2)
    for _ in range(14):
        b = float(rng.uniform(0, 72))
        S.add("twinkle", twinkle(rng), S.t(b), float(rng.uniform(0.03, 0.07)), float(rng.uniform(-0.9, 0.9)))
    mark_tree(S, 31, "windchimes_slowDesc1.wav", 0.07, rng=rng)
    mark_tree(S, 63, "windchimes_random.wav", 0.07, rng=rng)
    S.fx["bass"] = lambda x: filt(x, bw("lowpass", 2500)) * 0.9
    S.fx["hpsi_acc"] = lambda x: filt(x, bw("highpass", 140)) * 0.55
    S.fx["hpsi"] = lambda x: x * 0.85
    S.fx["pizz"] = lambda x: x * 0.6
    S.fx["strings"] = lambda x: filt(x, bw("lowpass", 5000)) * 0.6
    S.fx["lead"] = lambda x: x * 0.8
    S.fx["solo"] = lambda x: x * 0.85
    S.fx["box"] = lambda x: echo(x, S.spb, 0.3, 3, 6000, True, True) * 0.6
    S.fx["trem"] = lambda x: x * 0.55
    S.fx["timp"] = lambda x: filt(x, bw("lowpass", 1500)) * 0.8
    S.fx["choir"] = lambda x: filt(x, bw("highpass", 160)) * 0.9
    S.fx["organ"] = lambda x: x * 0.7
    S.fx["far"] = lambda x: x * 0.6
    S.fx["twinkle"] = lambda x: echo(x, S.spb, 0.4, 4, 9000, True, True) * 0.5
    S.send.update({"bass": 0.25, "hpsi_acc": 0.35, "hpsi": 0.45, "pizz": 0.4, "strings": 0.55, "lead": 0.55, "solo": 0.6,
                   "box": 0.8, "trem": 0.75, "timp": 0.45, "choir": 0.8, "organ": 0.7, "far": 0.85, "twinkle": 0.85})
    return S


# (fonction, LUFS visé, salle (durée, sombre, pré-délai, réflexions, étendue), compression de « colle »)
PIECES = {
    "chateau_comte": (chateau_comte, -20.0, (6.5, 0.45, 0.05, 26, 0.14), (-24.0, 1.5)),
    "bal_vampires": (bal_vampires, -20.0, (3.6, 0.4, 0.035, 22, 0.1), (-22.0, 1.6)),
}


def main() -> int:
    args = sys.argv[1:]
    only = []
    while args:
        a = args.pop(0)
        if a == "--vsco":
            m76.VSCO = Path(args.pop(0))
        elif a == "--vcsl":
            m76.VCSL = Path(args.pop(0))
        elif a == "--cc0":
            m76.CC0 = Path(args.pop(0))
        else:
            only.append(a)
    m75.VSCO, m75.VCSL, m75.CC0 = m76.VSCO, m76.VCSL, m76.CC0
    m75.TMP = Path(m75.tempfile.gettempdir()) / "musique_v124"
    cm70.VCSL = m76.VCSL
    cm51.VSCO = m76.VSCO
    import generate_sons_v63 as s63
    s63.LIB = m76.CC0
    kit = m75.Kit(seed=124)
    for name, (fn, target, (sec, dark, pre, er, span), glue) in PIECES.items():
        if only and name not in only:
            continue
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
