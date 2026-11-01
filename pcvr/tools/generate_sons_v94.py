"""V94 : les sons de Néopolis (synthétisés ici, versés au domaine public, CC0 1.0).

  ambiance/neopolis      la rumeur de la ville (40 s, en boucle) : le grondement sourd des tours, le
                         bourdonnement des néons, des voitures volantes qui passent au loin, un monorail,
                         et de temps en temps les deux notes d'une annonce lointaine.
  ambiance/marche_nuit   le Marché de Nuit (40 s, en boucle) : le brouhaha des gens (des voix sans mots),
                         les woks qui grésillent, les bols qui tintent, les lanternes qui grincent au vent.
  sfx/voiture_volante_1..2  une voiture volante qui passe tout près (le sifflement de ses turbines, l'effet Doppler)
  sfx/monorail_1         le monorail qui part (le carillon de la station, le souffle électrique)
  sfx/ascenseur_tour_1   l'ascenseur de la Tour Axiome (le « ding », la montée)
  sfx/distributeur_1..2  le distributeur (un bip, la canette qui tombe : clonk)
  sfx/robot_nouilles_1..2  le robot des nouilles (ses moteurs, ses bips contents)
  sfx/arcade_1..3        la borne de Dragon-Pixel (une petite musique en bips carrés)
  sfx/hologramme_1       l'émetteur de la place (un frisson de lumière)
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v94.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
import generate_sons_v58 as s58  # noqa: E402

SR = 44100
RNG = np.random.default_rng(9494)


def _n(x, peak=0.89):
    return s58._norm(x, peak)


def place(buf, ev, at, gain=1.0, pan=0.0):
    """Ce qui dépasse la fin repart au début (la boucle reste sans raccord)."""
    n = len(buf)
    at = int(at) % n
    k = min(len(ev), n - at)
    amb.place(buf, ev[:k], at, gain, pan)
    if k < len(ev):
        amb.place(buf, ev[k:], 0, gain, pan)


def t_(n):
    return np.arange(n) / SR


def env(n, a, r):
    t = t_(n)
    return np.clip(t / max(a, 1e-4), 0, 1) * np.clip((n / SR - t) / max(r, 1e-4), 0, 1)


# =================================================================== les passages

def passage(dur: float, f0: float, doppler: float, bruit: float = 0.6) -> np.ndarray:
    """Un engin qui passe : une turbine (un son tenu qui descend au passage), un souffle ; il monte,
    passe, s'éloigne."""
    n = int(dur * SR)
    t = t_(n)
    u = (t - dur * 0.5) / (dur * 0.18)
    amp = 1.0 / (1.0 + u * u)
    f = f0 * (1.0 + doppler * np.tanh(-u))
    ph = 2 * np.pi * np.cumsum(f) / SR
    ton = np.sin(ph) * 0.5 + np.sin(2 * ph) * 0.25 + np.sin(3.01 * ph) * 0.12
    souffle = amb.bp(RNG.standard_normal(n), 300.0, 4000.0) * bruit
    # le souffle s'éclaircit au plus près
    clair = amb.hp(RNG.standard_normal(n), 2500.0) * 0.25 * amp ** 2
    return (ton + souffle + clair) * amp * env(n, 0.05, 0.2)


def voiture(k: int) -> np.ndarray:
    return passage(3.2 + 0.4 * k, 210.0 + 70.0 * k, 0.12, 0.7)


def annonce(f1=659.0, f2=523.0) -> np.ndarray:
    """Les deux notes d'une annonce (comme dans les gares), un peu de résonance."""
    out = []
    for f in (f1, f2):
        n = int(0.6 * SR)
        t = t_(n)
        x = (np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * 2 * f * t) + 0.12 * np.sin(2 * np.pi * 3.01 * f * t)) * np.exp(-t / 0.35)
        out.append(x)
    return np.concatenate(out)


# =================================================================== les ambiances

def neopolis(seconds=40.0) -> np.ndarray:
    n = int(seconds * SR)
    buf = np.zeros((n, 2))
    # le grondement de la ville : un bruit très grave, qui respire lentement
    for c in range(2):
        g = amb.lp(amb.noise(n, "brown"), 180.0, 2) * amb.smooth_env(n, 0.1, 0.7, 1.0)
        buf[:, c] += g * 0.5
        buf[:, c] += amb.bp(amb.noise(n, "pink"), 200.0, 1500.0) * 0.08 * amb.smooth_env(n, 0.2, 0.5, 1.0)
    # les néons qui bourdonnent (le secteur, ses harmoniques)
    t = t_(n)
    hum = sum(np.sin(2 * np.pi * 50.0 * h * t) / h for h in (2, 3, 4, 6)) * 0.02
    buf[:, 0] += hum
    buf[:, 1] += hum * 0.8
    # les voitures volantes, au loin, de tous côtés
    for _ in range(int(seconds / 2.6)):
        v = passage(RNG.uniform(3.0, 6.0), RNG.uniform(150.0, 320.0), RNG.uniform(0.08, 0.16), 0.8)
        v = amb.lp(v, RNG.uniform(1500.0, 3500.0), 2)
        place(buf, v, RNG.uniform(0, seconds) * SR, RNG.uniform(0.08, 0.22), RNG.uniform(-0.9, 0.9))
    # un monorail, une fois
    m = passage(9.0, 95.0, 0.04, 1.0)
    place(buf, amb.lp(m, 1200.0, 2), 14.0 * SR, 0.25, -0.3)
    # une annonce lointaine, deux fois
    for at in (6.0, 27.0):
        a = s58._room(annonce(), 2.0, 2.5, 3000.0, 0.6, seed=int(at))
        place(buf, a, at * SR, 0.05, 0.5)
    return amb.loopify(buf, 2.0)


def voix(dur: float, f0: float) -> np.ndarray:
    """Une voix sans mots : des syllabes (un bruit et une vibration, passés dans deux « voyelles »)."""
    n = int(dur * SR)
    t = t_(n)
    f = f0 * (1.0 + 0.08 * amb.smooth_env(n, 3.0, -1.0, 1.0))
    ph = 2 * np.pi * np.cumsum(f) / SR
    src = (np.sin(ph) + 0.5 * np.sin(2 * ph) + 0.3 * np.sin(3 * ph)) * 0.6 + RNG.standard_normal(n) * 0.15
    syl = np.clip(np.sin(2 * np.pi * RNG.uniform(3.5, 5.5) * t + RNG.uniform(0, 6)), 0, 1) ** 0.6
    f1 = RNG.uniform(500.0, 800.0)
    f2 = RNG.uniform(1100.0, 1900.0)
    y = amb.bp(src, f1 * 0.8, f1 * 1.2) + 0.6 * amb.bp(src, f2 * 0.85, f2 * 1.15)
    return y * syl * env(n, 0.2, 0.3)


def marche_nuit(seconds=40.0) -> np.ndarray:
    n = int(seconds * SR)
    buf = np.zeros((n, 2))
    # le brouhaha : beaucoup de voix lointaines (étouffées), quelques-unes plus près
    for _ in range(70):
        d = RNG.uniform(1.5, 4.0)
        v = voix(d, RNG.uniform(110.0, 260.0))
        v = amb.lp(v, RNG.uniform(1200.0, 2600.0), 2)
        place(buf, v, RNG.uniform(0, seconds) * SR, RNG.uniform(0.04, 0.12), RNG.uniform(-0.9, 0.9))
    for c in range(2):
        buf[:, c] += amb.bp(amb.noise(n, "pink"), 250.0, 2000.0) * 0.06
    # les woks qui grésillent
    for _ in range(9):
        d = RNG.uniform(2.0, 5.0)
        m = int(d * SR)
        s = amb.hp(RNG.standard_normal(m), 3000.0) * (0.5 + 0.5 * np.abs(RNG.standard_normal(m)) ** 2) * env(m, 0.1, 0.8)
        place(buf, s * 0.35, RNG.uniform(0, seconds) * SR, 0.25, RNG.uniform(-0.8, 0.8))
    # les bols, les cuillères qui tintent
    for _ in range(26):
        f = RNG.uniform(1800.0, 4200.0)
        m = int(0.4 * SR)
        tt = t_(m)
        b = (np.sin(2 * np.pi * f * tt) + 0.4 * np.sin(2 * np.pi * f * 2.71 * tt)) * np.exp(-tt / 0.07)
        place(buf, b, RNG.uniform(0, seconds) * SR, RNG.uniform(0.04, 0.1), RNG.uniform(-0.9, 0.9))
    return amb.loopify(buf, 2.0)


# =================================================================== les bruitages

def monorail() -> np.ndarray:
    d = annonce(784.0, 659.0)
    m = passage(4.5, 110.0, 0.02, 1.0)
    out = np.zeros(int(5.5 * SR))
    out[: len(d)] += d * 0.6
    k = int(1.0 * SR)
    out[k:k + len(m)] += m[: len(out) - k] * 0.8
    return _n(s58._room(np.stack([out, out], 1), 1.2, 3.0, 5000.0, 0.25, seed=941)[:, 0])


def ascenseur() -> np.ndarray:
    n = int(2.4 * SR)
    t = t_(n)
    ding = np.sin(2 * np.pi * 1318.5 * t) * np.exp(-t / 0.6) + 0.3 * np.sin(2 * np.pi * 2637.0 * t) * np.exp(-t / 0.3)
    f = 70.0 + 40.0 * np.clip(t / 2.0, 0, 1)
    mot = np.sin(2 * np.pi * np.cumsum(f) / SR) * 0.3 * env(n, 0.3, 0.6)
    souffle = amb.bp(RNG.standard_normal(n), 200.0, 900.0) * 0.25 * env(n, 0.4, 0.6)
    return _n(ding * 0.7 + mot + souffle)


def distributeur(k: int) -> np.ndarray:
    n = int(1.2 * SR)
    t = t_(n)
    out = np.zeros(n)
    bip = np.sin(2 * np.pi * (1760.0 + 220.0 * k) * t[: int(0.09 * SR)]) * 0.4
    out[: len(bip)] += bip
    # la canette tombe : un coup sourd et un tintement de métal
    a = int((0.35 + 0.05 * k) * SR)
    m = n - a
    tt = t_(m)
    coup = amb.lp(RNG.standard_normal(m), 400.0, 2) * np.exp(-tt / 0.03) * 2.0
    tin = (np.sin(2 * np.pi * 2300.0 * tt) + 0.6 * np.sin(2 * np.pi * 3900.0 * tt)) * np.exp(-tt / 0.08) * 0.35
    out[a:] += coup + tin
    b = int(0.12 * SR)
    out[a + b:] += (coup * 0.4 + tin * 0.5)[: n - a - b]
    return _n(out)


def robot(k: int) -> np.ndarray:
    n = int(1.6 * SR)
    t = t_(n)
    f = 300.0 + 500.0 * (0.5 + 0.5 * np.sin(2 * np.pi * (0.9 + 0.3 * k) * t))
    ph = np.cumsum(f) / SR
    servo = amb.bp(2 * (ph % 1.0) - 1, 400.0, 2500.0) * 0.4 * env(n, 0.05, 0.2)
    out = servo.copy()
    for j, fb in enumerate([1046.5, 1318.5, 1568.0][: 2 + k]):
        a = int((1.0 + j * 0.12) * SR)
        m = int(0.1 * SR)
        if a + m < n:
            out[a:a + m] += np.sign(np.sin(2 * np.pi * fb * t_(m))) * 0.18
    return _n(out)


def arcade(k: int) -> np.ndarray:
    notes = [[72, 76, 79, 84, 79, 84, 88], [60, 64, 67, 72, 76, 72, 79, 84], [84, 83, 81, 79, 76, 72, 67, 60]][k]
    out = []
    for i, m in enumerate(notes):
        d = 0.075 if k != 2 else 0.06
        nn = int(d * SR)
        f = 440.0 * 2 ** ((m - 69) / 12)
        x = np.sign(np.sin(2 * np.pi * f * t_(nn))) * 0.3 * np.exp(-t_(nn) / 0.2)
        out.append(x)
    y = np.concatenate(out + [np.zeros(int(0.2 * SR))])
    return _n(y)


def hologramme() -> np.ndarray:
    n = int(1.8 * SR)
    t = t_(n)
    f = 400.0 + 1800.0 * (t / 1.8) ** 0.6
    mod = np.sin(2 * np.pi * f * 1.5 * t) * 3.0
    x = np.sin(2 * np.pi * np.cumsum(f) / SR + mod) * env(n, 0.05, 0.8) * 0.4
    sp = amb.hp(RNG.standard_normal(n), 5000.0) * (RNG.random(n) < 0.004) * 1.5
    return _n(s58._room(np.stack([x + sp, x + sp], 1), 1.5, 2.5, 8000.0, 0.35, seed=944)[:, 0])


def main() -> int:
    amb.save("ambiance/neopolis", neopolis())
    amb.save("ambiance/marche_nuit", marche_nuit())
    for k in range(2):
        fx.save(f"voiture_volante_{k + 1}", _n(voiture(k)))
    fx.save("monorail_1", monorail())
    fx.save("ascenseur_tour_1", ascenseur())
    for k in range(2):
        fx.save(f"distributeur_{k + 1}", distributeur(k))
        fx.save(f"robot_nouilles_{k + 1}", robot(k))
    for k in range(3):
        fx.save(f"arcade_{k + 1}", arcade(k))
    fx.save("hologramme_1", hologramme())
    print("V94 : les sons de Néopolis sont faits")
    return 0


if __name__ == "__main__":
    sys.exit(main())
