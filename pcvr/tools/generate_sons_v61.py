"""V61 : les sons de Cliquetis, la cité des ingénieurs fous.

Nappe d'ambiance (boucle sans raccord, stéréo) :
  ambiance/atelier   la cité au travail : le tic-tac de mille engrenages, des sifflements de
                     vapeur, des coups de marteau sur l'enclume et sur la tôle, des cliquetis de
                     chaînes, le ronron d'une chaudière, des bips de robots, un brouhaha lointain.
Bruitages (sfx/) :
  vapeur_1..2        un jet de vapeur qui siffle (soupape, chaudière qui tousse) ;
  tesla_1..3         l'arc électrique des bobines de Tesla (crépitement, claquement, bourdon) ;
  boum_1..2          l'explosion du professeur Boum (détonation sourde, débris qui retombent) ;
  bip_1..3           un robot qui répond (bips modulés) ;
  confettis_1..2     le canon à confettis (« pop » feutré et pluie de papier).
Synthétisés ici (domaine public), le brouhaha d'après les voix du recueil CC0
« lavenderdotpet/CC0-Public-Domain-Sounds ».
Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/generate_sons_v61.py <dossier CC0-Public-Domain-Sounds>
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_sons_v56 as s56  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402

SR = 44100
RNG = np.random.default_rng(6161)
s56.RNG = np.random.default_rng(6162)


def _env(m: int, a: float, d: float) -> np.ndarray:
    x = np.arange(m) / SR
    return np.clip(x / max(a, 1e-4), 0, 1) * np.exp(-x / d)


def _norm(x: np.ndarray, peak: float = 0.9) -> np.ndarray:
    return x / (np.max(np.abs(x)) + 1e-9) * peak


def steam(seconds: float, f0: float = 3200.0) -> np.ndarray:
    """Un jet de vapeur : souffle filtré, attaque franche, sifflement résonant qui glisse."""
    m = int(seconds * SR)
    x = np.arange(m) / SR
    env = np.clip(x / 0.03, 0, 1) * np.clip((seconds - x) / 0.4, 0, 1) * (0.8 + 0.2 * np.sin(2 * np.pi * 7 * x))
    hiss = amb.bp(RNG.standard_normal(m), 1500, 9000) * 0.6
    f = f0 * np.interp(x, [0, seconds], [1.0, 0.85])
    whistle = amb.tv_lowpass(RNG.standard_normal(m), f * 1.01) - amb.tv_lowpass(RNG.standard_normal(m), f * 0.99)
    return (hiss + whistle * 0.8) * env


def tick_bed(n: int) -> np.ndarray:
    """Des engrenages : des tic-tac à plusieurs vitesses, petits cliquetis métalliques."""
    out = np.zeros((n, 2))
    for period, f, g, pan in [(0.5, 4200, 0.05, -0.6), (0.333, 3100, 0.04, 0.5), (0.25, 5200, 0.025, 0.1), (0.71, 2400, 0.05, -0.2), (1.2, 1800, 0.06, 0.7)]:
        m = int(0.03 * SR)
        xx = np.arange(m) / SR
        click = np.sin(2 * np.pi * f * xx) * np.exp(-xx / 0.004) + amb.bp(RNG.standard_normal(m), 2000, 8000) * np.exp(-xx / 0.002) * 0.5
        t = RNG.uniform(0, period)
        while t < n / SR - 0.05:
            amb.place(out, click, int(t * SR), g * RNG.uniform(0.7, 1.0), pan)
            t += period * RNG.uniform(0.98, 1.02)
    return out


def hammer(metal: bool) -> np.ndarray:
    m = int(0.9 * SR)
    x = np.arange(m) / SR
    if metal:
        y = sum(a * np.sin(2 * np.pi * f * x) * np.exp(-x / d) for f, a, d in [(620, 1.0, 0.25), (1450, 0.6, 0.12), (2900, 0.4, 0.06), (4100, 0.2, 0.04)])
    else:
        y = sum(a * np.sin(2 * np.pi * f * x) * np.exp(-x / d) for f, a, d in [(210, 1.0, 0.12), (480, 0.5, 0.06), (1100, 0.3, 0.03)])
    y += amb.bp(RNG.standard_normal(m), 1500, 7000) * np.exp(-x / 0.006) * 0.8
    return y * np.clip(x / 0.0008, 0, 1)


def hammering(metal: bool) -> np.ndarray:
    out = np.zeros(int(3.0 * SR))
    t = 0.0
    for _ in range(int(RNG.integers(3, 7))):
        amb.place(out, hammer(metal), int(t * SR), RNG.uniform(0.6, 1.0))
        t += RNG.uniform(0.32, 0.5)
        if t > 2.2:
            break
    return out


def chain() -> np.ndarray:
    out = np.zeros(int(1.4 * SR))
    for k in range(int(RNG.integers(8, 18))):
        m = int(0.05 * SR)
        xx = np.arange(m) / SR
        f = RNG.uniform(2500, 5000)
        c = (np.sin(2 * np.pi * f * xx) + 0.5 * np.sin(2 * np.pi * f * 1.6 * xx)) * np.exp(-xx / 0.01)
        amb.place(out, c, int(RNG.uniform(0, 1.2) * SR), RNG.uniform(0.2, 0.6))
    return out


def bip(k: int) -> np.ndarray:
    """Un robot qui répond : deux à quatre bips d'onde carrée adoucie, modulés."""
    parts = []
    notes = [[880, 1320], [660, 990, 1320], [1200, 900, 1500, 1100]][k % 3]
    for f in notes:
        m = int(RNG.uniform(0.07, 0.13) * SR)
        x = np.arange(m) / SR
        sq = np.sign(np.sin(2 * np.pi * f * x)) * 0.5 + np.sin(2 * np.pi * f * x) * 0.5
        sq *= np.clip(x / 0.004, 0, 1) * np.clip((m / SR - x) / 0.01, 0, 1)
        parts += [amb.lp(sq, 4000), np.zeros(int(0.04 * SR))]
    return _norm(np.concatenate(parts), 0.6)


def boiler(n: int) -> np.ndarray:
    hum = amb.lp(amb.noise(n, "brown"), 160) * 0.6
    x = np.arange(n) / SR
    hum += np.sin(2 * np.pi * 49 * x) * 0.05 * (0.6 + 0.4 * np.sin(2 * np.pi * 0.2 * x))
    return amb.stereo(hum, np.roll(hum, SR // 3))


def atelier_bed(lib: Path, seconds: float = 52.0) -> np.ndarray:
    n = int(seconds * SR)
    out = tick_bed(n)
    out += boiler(n) * 0.35
    s56.scatter(out, [steam(RNG.uniform(0.6, 1.6), RNG.uniform(2200, 4200)) for _ in range(4)], 9, (0.05, 0.14))
    s56.scatter(out, [hammering(True) for _ in range(3)], 8, (0.05, 0.12))
    s56.scatter(out, [hammering(False) for _ in range(2)], 5, (0.05, 0.1))
    s56.scatter(out, [chain() for _ in range(3)], 6, (0.04, 0.1))
    s56.scatter(out, [bip(k) for k in range(3)], 7, (0.03, 0.07), semis=(-2.0, 3.0))
    if lib is not None:
        far = s56.walla(lib, seconds, 5.0, 1600.0, gain_r=(0.05, 0.18))
        out += s56._room(far, 1.6, 2.0, 1800.0, 0.5, seed=611)
    out = s56._room(out, 1.0, 2.6, 5000.0, 0.25, seed=612)
    return amb.loopify(out, 2.0)


def tesla(k: int) -> np.ndarray:
    """Un arc de Tesla : crépitement dense d'impulsions, claquement, bourdon à 120 Hz."""
    dur = [0.7, 1.1, 0.5][k]
    m = int(dur * SR)
    x = np.arange(m) / SR
    dens = 0.02 + 0.06 * RNG.random(m)
    imp = (RNG.random(m) < dens).astype(float) * RNG.uniform(0.3, 1.0, m)
    crack = amb.bp(imp, 800, 12000) * 1.4
    buzz = np.sign(np.sin(2 * np.pi * 120 * x)) * 0.15 + np.sin(2 * np.pi * 240 * x) * 0.1
    env = np.clip(x / 0.01, 0, 1) * np.clip((dur - x) / 0.08, 0, 1)
    y = (crack + buzz) * env
    snap = amb.bp(RNG.standard_normal(int(0.05 * SR)), 500, 9000) * np.exp(-np.arange(int(0.05 * SR)) / SR / 0.008) * 2.0
    amb.place(y, snap, 0, 1.0)
    return _norm(y, 0.85)


def boum(k: int) -> np.ndarray:
    """L'explosion : une détonation grave, un souffle, puis des débris qui retombent."""
    dur = 3.2
    m = int(dur * SR)
    x = np.arange(m) / SR
    thump = np.sin(2 * np.pi * np.cumsum(np.interp(x, [0, 0.4], [70, 32])) / SR) * np.exp(-x / 0.35)
    blast = amb.lp(RNG.standard_normal(m), 1800 if k == 0 else 1200) * np.exp(-x / 0.25)
    rumble = amb.lp(RNG.standard_normal(m), 200) * np.exp(-x / 0.9) * 0.8
    y = thump * 1.4 + blast * 1.2 + rumble
    for _ in range(int(RNG.integers(12, 25))):
        t = RNG.uniform(0.5, 2.6)
        d = hammer(RNG.random() < 0.5)[: int(0.25 * SR)] * RNG.uniform(0.05, 0.2)
        amb.place(y, d, int(t * SR), 1.0)
    y *= np.clip(x / 0.002, 0, 1)
    return _norm(y, 0.95)


def confettis(k: int) -> np.ndarray:
    m = int(1.8 * SR)
    x = np.arange(m) / SR
    pop = amb.lp(RNG.standard_normal(m), 900) * np.exp(-x / 0.05) * 1.5 + np.sin(2 * np.pi * np.cumsum(np.interp(x, [0, 0.1], [180, 70])) / SR) * np.exp(-x / 0.08)
    rain = amb.hp(RNG.standard_normal(m), 3000) * (RNG.random(m) < 0.05) * np.clip((x - 0.2) / 0.3, 0, 1) * np.exp(-(x - 0.2).clip(0) / 0.6) * 0.6
    return _norm(pop + rain, 0.8)


def main() -> int:
    lib = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    if lib is not None and not lib.is_dir():
        lib = None
    for k in range(2):
        fx.save(f"vapeur_{k + 1}", _norm(steam(1.4 + k * 0.6, 3000 + k * 600), 0.7))
        fx.save(f"boum_{k + 1}", boum(k))
        fx.save(f"confettis_{k + 1}", confettis(k))
    for k in range(3):
        fx.save(f"tesla_{k + 1}", tesla(k))
        fx.save(f"bip_{k + 1}", bip(k))
    amb.save("ambiance/atelier", atelier_bed(lib))
    return 0


if __name__ == "__main__":
    sys.exit(main())
