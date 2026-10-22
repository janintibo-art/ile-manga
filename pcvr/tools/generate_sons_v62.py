"""V62 : les sons de Ramure, le village des oreilles, perché dans les arbres de la forêt des brumes.

Nappe d'ambiance (boucle sans raccord, stéréo) :
  ambiance/ramure    le village dans les arbres : le vent dans les grandes couronnes, des
                     carillons de bambou, les ponts de corde qui grincent doucement, des oiseaux
                     chanteurs, quelques grenouilles des mares, des coups de maillet lointains
                     (la charpentière), et le babil clair du village, très loin.
Bruitages (sfx/) :
  tambour_1..2         un grand tambour de fête (taiko) : la peau qui gronde, la baguette ;
  clochette_1..2       une petite clochette d'argent (on passe sous une arche de la course) ;
  ascenseur_1          la nacelle d'osier qui part : l'osier qui craque, la poulie qui grince ;
  tyrolienne_1         la poulie qui file sur le câble, de plus en plus vite, puis freine ;
  course_depart_1      le départ de la Grande Course : deux claquoirs de bois, un coup de taiko ;
  course_arrivee_1     l'arrivée : les clochettes et un double coup de taiko.
Synthétisés ici (domaine public), le babil d'après les voix du recueil CC0
« lavenderdotpet/CC0-Public-Domain-Sounds ».
Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/generate_sons_v62.py [dossier CC0-Public-Domain-Sounds]
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_sons_v56 as s56  # noqa: E402
import generate_sons_v59 as s59  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402

SR = 44100
RNG = np.random.default_rng(6262)
s56.RNG = np.random.default_rng(6263)
s59.RNG = np.random.default_rng(6264)


def _norm(x: np.ndarray, peak: float = 0.9) -> np.ndarray:
    return x / (np.max(np.abs(x)) + 1e-9) * peak


def _t(seconds: float) -> np.ndarray:
    return np.arange(int(seconds * SR)) / SR


# =================================================================== la nappe

def bamboo_chime(k: int) -> np.ndarray:
    """Un carillon de bambou : quelques tubes creux qui s'entrechoquent (sons boisés, courts,
    accordés en pentatonique)."""
    notes = [523.3, 587.3, 659.3, 784.0, 880.0, 1046.5]
    out = np.zeros(int(2.4 * SR))
    t = 0.0
    for _ in range(int(RNG.integers(3, 8))):
        f = notes[int(RNG.integers(0, len(notes)))] * RNG.uniform(0.995, 1.005)
        x = _t(0.6)
        y = sum(a * np.sin(2 * np.pi * f * r * x) * np.exp(-x / d) for r, a, d in [(1.0, 1.0, 0.16), (2.76, 0.45, 0.05), (5.4, 0.2, 0.02)])
        y += amb.bp(RNG.standard_normal(len(x)), 1500, 6000) * np.exp(-x / 0.004) * 0.4
        amb.place(out, y * np.clip(x / 0.001, 0, 1), int(t * SR), RNG.uniform(0.4, 1.0))
        t += RNG.uniform(0.08, 0.35)
        if t > 1.7:
            break
    return amb.lp(out, 5000)


def rope_creak(k: int) -> np.ndarray:
    """Un pont de corde qui se balance : la corde qui frotte (grincement doux, un peu aigu)."""
    y = s59.wood_groan(RNG.uniform(0.8, 1.6), RNG.uniform(60.0, 110.0))
    return amb.hp(y, 300) * 0.6


def songbird(k: int) -> np.ndarray:
    """Un petit oiseau chanteur : une phrase de trois à sept notes rapides, flûtées."""
    parts = []
    base = RNG.uniform(2600, 4200)
    for i in range(int(RNG.integers(3, 8))):
        f0 = base * RNG.uniform(0.8, 1.25)
        f1 = f0 * RNG.uniform(0.75, 1.3)
        d = RNG.uniform(0.04, 0.12)
        parts += [amb.chirp_call(f0, f1, d, harm=(1.0, 0.15), vib=RNG.uniform(0, 1)), np.zeros(int(RNG.uniform(0.02, 0.08) * SR))]
    return amb.lp(np.concatenate(parts), 7000)


def dove(k: int) -> np.ndarray:
    """Une tourterelle au loin : « hou-hou-hou » doux, grave."""
    parts = []
    for i, (d, f) in enumerate([(0.28, 520), (0.42, 560), (0.26, 500)]):
        x = _t(d)
        y = np.sin(2 * np.pi * f * x) * np.sin(np.pi * x / x[-1]) ** 1.5 + 0.2 * np.sin(4 * np.pi * f * x) * np.sin(np.pi * x / x[-1]) ** 2
        parts += [y, np.zeros(int(0.12 * SR))]
    return amb.lp(np.concatenate(parts), 1500)


def mallet(k: int) -> np.ndarray:
    """La charpentière, au loin : trois ou quatre coups de maillet sur une cheville de bois."""
    out = np.zeros(int(2.2 * SR))
    t = 0.0
    for _ in range(int(RNG.integers(2, 5))):
        x = _t(0.3)
        y = sum(a * np.sin(2 * np.pi * f * x) * np.exp(-x / d) for f, a, d in [(330, 1.0, 0.05), (780, 0.5, 0.03), (1500, 0.2, 0.015)])
        y += amb.bp(RNG.standard_normal(len(x)), 800, 4000) * np.exp(-x / 0.004) * 0.5
        amb.place(out, y, int(t * SR), RNG.uniform(0.6, 1.0))
        t += RNG.uniform(0.38, 0.55)
    return amb.lp(out, 2500)


def leaves(n: int) -> np.ndarray:
    """Le vent dans les grandes couronnes : un bruissement aigu qui monte et descend."""
    g = amb.smooth_env(n, 0.12, 0.2, 1.0) ** 1.5
    l = amb.bp(amb.noise(n, "white"), 1800, 7000) * g
    r = amb.bp(amb.noise(n, "white"), 1800, 7000) * np.roll(g, int(1.3 * SR))
    return amb.stereo(l, r)


def ramure_bed(lib: Path | None, seconds: float = 54.0) -> np.ndarray:
    n = int(seconds * SR)
    out = s59.wind(n, 70, 900, 0.12, 0.3, 0.75) * 0.35
    out += leaves(n) * 0.09
    s59.scatter(out, [bamboo_chime(k) for k in range(5)], 7, (0.05, 0.12))
    s59.scatter(out, [rope_creak(k) for k in range(5)], 9, (0.04, 0.1))
    s59.scatter(out, [songbird(k) for k in range(6)], 16, (0.04, 0.11))
    s59.scatter(out, [dove(0)], 3, (0.04, 0.07))
    s59.scatter(out, [s59.frog(k) for k in range(4)], 10, (0.02, 0.06))
    s59.scatter(out, [mallet(k) for k in range(3)], 3, (0.03, 0.06))
    if lib is not None:
        # le village, très loin : des voix claires (on les monte un peu), surtout des rires
        far = s56.walla(lib, seconds, 3.0, 2200.0, semis=(1.0, 5.0), gain_r=(0.04, 0.14))
        out += s56._room(far, 1.6, 2.2, 2200.0, 0.55, seed=621)
    out = s56._room(out, 1.4, 2.0, 5000.0, 0.25, seed=622)
    return amb.loopify(out, 2.5)


# =================================================================== les bruitages

def taiko(k: int, big: float = 1.0) -> np.ndarray:
    """Un coup de taiko : la peau tendue (fondamentale qui glisse vers le grave), le fût qui
    résonne, le claquement de la baguette."""
    x = _t(2.4)
    f0 = [92.0, 78.0][k % 2] * big
    f = f0 * (1.0 + 0.35 * np.exp(-x / 0.03))
    skin = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-x / 0.55)
    body = sum(a * np.sin(2 * np.pi * f0 * r * x + RNG.uniform(0, 6)) * np.exp(-x / d) for r, a, d in [(1.59, 0.35, 0.3), (2.14, 0.22, 0.2), (2.65, 0.12, 0.12)])
    stick = amb.bp(RNG.standard_normal(len(x)), 600, 5000) * np.exp(-x / 0.006) * 0.7
    thump = amb.lp(RNG.standard_normal(len(x)), 240) * np.exp(-x / 0.08) * 0.8
    y = (skin * 1.2 + body + stick + thump) * np.clip(x / 0.0008, 0, 1)
    return s56._room(_norm(y, 0.9), 1.2, 1.6, 4000.0, 0.22, seed=623 + k)


def little_bell(k: int) -> np.ndarray:
    f = [2350.0, 2780.0][k % 2]
    x = _t(1.6)
    y = sum(a * np.sin(2 * np.pi * f * r * x) * np.exp(-x / d) for r, a, d in [(1.0, 1.0, 0.5), (2.41, 0.5, 0.25), (3.98, 0.3, 0.12), (5.6, 0.15, 0.06)])
    # le battant qui tinte deux fois
    out = np.zeros(int(1.9 * SR))
    amb.place(out, y, 0, 1.0)
    amb.place(out, y, int(0.13 * SR), 0.45)
    return _norm(out * np.clip(np.arange(len(out)) / SR / 0.0005, 0, 1), 0.8)


def wicker_lift() -> np.ndarray:
    """La nacelle d'osier qui démarre : l'osier qui craque, la corde qui se tend, la poulie
    qui grince en tournant (de plus en plus régulière)."""
    n = int(5.5 * SR)
    out = np.zeros(n)
    for _ in range(14):
        c = s59.creak(int(RNG.integers(0, 4)))
        amb.place(out, c, int(RNG.uniform(0, 1.8) * SR), RNG.uniform(0.3, 0.9))
    # la poulie : un grincement périodique (un tour toutes les 0,6 s)
    t = 0.6
    while t < 5.0:
        g = s59.wood_groan(0.35, RNG.uniform(140, 190))
        amb.place(out, amb.hp(g, 500), int(t * SR), 0.5 * min(1.0, (t - 0.4) / 1.2) * min(1.0, (5.2 - t) / 0.8))
        t += RNG.uniform(0.56, 0.64)
    rope = amb.bp(RNG.standard_normal(n), 300, 1500) * amb.smooth_env(n, 0.8, 0.0, 1.0) * 0.06
    return _norm(out + rope, 0.85)


def zipline() -> np.ndarray:
    """La poulie qui file sur le câble : un sifflement métallique qui monte avec la vitesse,
    le câble qui vibre, puis le freinage."""
    seconds = 6.5
    x = _t(seconds)
    speed = np.interp(x, [0, 0.4, 3.8, 5.6, seconds], [0.0, 0.3, 1.0, 0.45, 0.0])
    f = 500 + 2600 * speed
    roll = amb.tv_lowpass(RNG.standard_normal(len(x)), f * 1.03) - amb.tv_lowpass(RNG.standard_normal(len(x)), f * 0.97)
    hiss = amb.bp(RNG.standard_normal(len(x)), 2000, 9000) * speed * 0.3
    hum = np.sin(2 * np.pi * np.cumsum(70 + 110 * speed) / SR) * 0.25 * speed
    rattle = (RNG.random(len(x)) < 0.002 * (0.2 + speed)).astype(float)
    rattle = amb.bp(rattle, 1500, 6000) * 1.5
    y = (roll * 1.2 + hiss + hum + rattle) * np.clip(x / 0.2, 0, 1) * speed ** 0.5
    return _norm(y, 0.85)


def clapper() -> np.ndarray:
    """Les claquoirs de bois (hyoshigi) : un claquement sec, très aigu."""
    x = _t(0.5)
    y = sum(a * np.sin(2 * np.pi * f * x) * np.exp(-x / d) for f, a, d in [(1850, 1.0, 0.06), (3400, 0.6, 0.03), (5200, 0.3, 0.015)])
    y += amb.bp(RNG.standard_normal(len(x)), 1500, 9000) * np.exp(-x / 0.003)
    return y


def race_start() -> np.ndarray:
    out = np.zeros(int(3.6 * SR))
    amb.place(out, clapper(), int(0.05 * SR), 0.8)
    amb.place(out, clapper(), int(0.55 * SR), 0.9)
    amb.place(out, taiko(0), int(1.05 * SR), 1.0)
    return _norm(out, 0.9)


def race_finish() -> np.ndarray:
    out = np.zeros(int(4.0 * SR))
    t1 = taiko(1)
    amb.place(out, t1, 0, 1.0)
    amb.place(out, t1, int(0.42 * SR), 0.9)
    for k in range(6):
        b = little_bell(k)
        amb.place(out, b, int((0.9 + k * 0.17 + RNG.uniform(-0.03, 0.03)) * SR), 0.45)
    return _norm(out, 0.9)


def main() -> int:
    lib = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    if lib is not None and not lib.is_dir():
        lib = None
    for k in range(2):
        fx.save(f"tambour_{k + 1}", taiko(k))
        fx.save(f"clochette_{k + 1}", little_bell(k))
    fx.save("ascenseur_1", wicker_lift())
    fx.save("tyrolienne_1", zipline())
    fx.save("course_depart_1", race_start())
    fx.save("course_arrivee_1", race_finish())
    amb.save("ambiance/ramure", ramure_bed(lib))
    return 0


if __name__ == "__main__":
    sys.exit(main())
