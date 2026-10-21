"""V60 : les sons de Tazira, le port des sables.

Nappes d'ambiance (boucles sans raccord, stéréo) :
  ambiance/souk    le souk couvert : un brouhaha serré de marchandages, le martelage du cuivre
                   chez le dinandier (tac… tac-tac), des clochettes de porteurs d'eau, des
                   pas sur les pavés, des pigeons sous les claies, un fond de voix lointaines ;
  ambiance/criee   la criée sur le quai : le crieur qui lance ses prix par-dessus la foule, les
                   acheteurs, les caisses de poisson posées sur la pierre, les mouettes en
                   nombre, l'eau du bassin qui clapote contre les barques.
Brouhaha d'après les voix du recueil CC0 « lavenderdotpet/CC0-Public-Domain-Sounds »
(kenney_voiceoverpack), le reste synthétisé ici (domaine public).
Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/generate_sons_v60.py <dossier CC0-Public-Domain-Sounds>
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_sons_v56 as s56  # noqa: E402

SR = 44100
RNG = np.random.default_rng(6060)
s56.RNG = np.random.default_rng(6061)


def _env(m: int, a: float, d: float) -> np.ndarray:
    x = np.arange(m) / SR
    return np.clip(x / max(a, 1e-4), 0, 1) * np.exp(-x / d)


def copper_tap(k: int) -> np.ndarray:
    """Un coup de marteau sur un plateau de cuivre : brillant, inharmonique, court."""
    m = int(0.9 * SR)
    x = np.arange(m) / SR
    f = [1830.0, 2140.0, 1650.0, 2420.0][k % 4] * RNG.uniform(0.97, 1.03)
    y = sum(a * np.sin(2 * np.pi * f * r * x + RNG.uniform(0, 6)) * np.exp(-x / d)
            for r, a, d in [(1.0, 1.0, 0.16), (1.47, 0.6, 0.11), (2.13, 0.45, 0.07), (2.9, 0.3, 0.05), (0.62, 0.35, 0.2)])
    y += amb.bp(RNG.standard_normal(m), 2000, 8000) * np.exp(-x / 0.004) * 0.6
    return y * np.clip(x / 0.0007, 0, 1)


def hammering() -> np.ndarray:
    """Une série de coups de dinandier : tac… tac-tac… tac."""
    out = np.zeros(int(3.2 * SR))
    t = 0.0
    while t < 2.6:
        c = copper_tap(int(RNG.integers(0, 4)))
        amb.place(out, c, int(t * SR), RNG.uniform(0.5, 1.0))
        t += RNG.choice([0.18, 0.2, 0.36, 0.55])
    return out


def water_bell() -> np.ndarray:
    """Les clochettes du porteur d'eau : un petit carillon de laiton qu'on secoue."""
    out = np.zeros(int(1.2 * SR))
    for i in range(RNG.integers(3, 7)):
        m = int(0.5 * SR)
        x = np.arange(m) / SR
        f = RNG.uniform(2600, 3400)
        y = (np.sin(2 * np.pi * f * x) + 0.4 * np.sin(2 * np.pi * f * 2.7 * x)) * np.exp(-x / 0.08)
        amb.place(out, y * np.clip(x / 0.001, 0, 1), int(RNG.uniform(0, 0.6) * SR), RNG.uniform(0.4, 1.0))
    return amb.hp(out, 1500)


def footstep() -> np.ndarray:
    m = int(0.14 * SR)
    x = np.arange(m) / SR
    return amb.bp(RNG.standard_normal(m), 150, 2500) * np.exp(-x / 0.025)


def steps_seq() -> np.ndarray:
    out = np.zeros(int(2.4 * SR))
    for i in range(int(RNG.integers(3, 7))):
        amb.place(out, footstep(), int(i * RNG.uniform(0.32, 0.4) * SR), RNG.uniform(0.6, 1.0))
    return out


def crate_drop() -> np.ndarray:
    """Une caisse de poisson posée sur la pierre du quai : bois creux, un peu d'eau."""
    m = int(0.6 * SR)
    x = np.arange(m) / SR
    y = amb.bp(RNG.standard_normal(m), 90, 900) * np.exp(-x / 0.06) * 1.2
    y += np.sin(2 * np.pi * RNG.uniform(110, 160) * x) * np.exp(-x / 0.07)
    splash = amb.bp(RNG.standard_normal(m), 1500, 6000) * _env(m, 0.01, 0.12) * 0.3
    return y + np.roll(splash, int(0.02 * SR))


def crier(lib: Path) -> np.ndarray:
    """Le crieur : de longues voyelles chantées, portées, par-dessus la foule."""
    vs = s56._voices(lib)
    out = np.zeros(int(4.0 * SR))
    if not vs:
        return out
    t = 0.0
    for i in range(RNG.integers(2, 4)):
        v = vs[RNG.integers(0, len(vs))]
        ln = min(len(v), int(RNG.uniform(0.4, 0.8) * SR))
        a = RNG.integers(0, max(1, len(v) - ln))
        s = v[a:a + ln]
        # on étire la voix (une note tenue, crieur de marché)
        s = s56._shift(s, RNG.uniform(-1.0, 2.0))
        st = np.interp(np.linspace(0, len(s) - 1, int(len(s) * 1.6)), np.arange(len(s)), s)
        st *= np.hanning(len(st)) ** 0.4
        amb.place(out, amb.bp(st, 250, 3500), int(t * SR), RNG.uniform(0.7, 1.0))
        t += len(st) / SR + RNG.uniform(0.1, 0.35)
        if t > 3.2:
            break
    return out


def souk_bed(lib: Path, seconds: float = 50.0) -> np.ndarray:
    n = int(seconds * SR)
    out = s56.walla(lib, seconds, 26.0, 2600.0, semis=(-4.0, 3.0), gain_r=(0.12, 0.5))
    near = s56.walla(lib, seconds, 5.0, 3600.0, semis=(-2.0, 2.0), gain_r=(0.35, 0.7))
    out = s56._room(out + near, 1.1, 3.4, 3200.0, 0.32, seed=601)
    s56.scatter(out, [hammering() for _ in range(3)], 9, (0.05, 0.12), semis=(-0.5, 0.5))
    s56.scatter(out, [water_bell() for _ in range(3)], 4, (0.04, 0.09), semis=(-0.5, 0.5))
    s56.scatter(out, [steps_seq() for _ in range(4)], 14, (0.05, 0.12), semis=(-2.0, 2.0))
    s56.scatter(out, [s56.pigeon(k) for k in range(3)], 4, (0.04, 0.09), semis=(-1.0, 1.0))
    out += np.stack([amb.bp(amb.noise(n, "pink"), 120, 1600)] * 2, axis=1) * 0.035
    return amb.loopify(out, 2.0)


def criee_bed(lib: Path, seconds: float = 50.0) -> np.ndarray:
    n = int(seconds * SR)
    out = s56.lapping(n) * 0.8
    crowd = s56.walla(lib, seconds, 16.0, 2400.0, semis=(-3.0, 2.0), gain_r=(0.12, 0.42))
    out += s56._room(crowd, 1.6, 2.2, 2600.0, 0.4, seed=602)
    s56.scatter(out, [crier(lib) for _ in range(4)], 7, (0.25, 0.42), semis=(-0.5, 0.5))
    s56.scatter(out, [crate_drop() for _ in range(4)], 10, (0.1, 0.25), semis=(-2.0, 2.0))
    s56.scatter(out, [amb.gull(k) for k in range(4)], 22, (0.05, 0.16), semis=(-1.0, 1.5))
    return amb.loopify(out, 2.0)


def main() -> int:
    lib = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    if lib is None or not lib.is_dir():
        print(__doc__)
        return 1
    amb.save("ambiance/souk", souk_bed(lib))
    amb.save("ambiance/criee", criee_bed(lib))
    return 0


if __name__ == "__main__":
    sys.exit(main())
