"""V150 : les sons du Saloon du Chien qui Mise (synthétisés ici ; versés au domaine public, CC0 1.0).

  sfx/banjo_1..3       quelques mesures de banjo (des cordes pincées, synthèse de Karplus-Strong : un
                       bruit qui tourne dans une ligne à retard et s'amortit), en sol majeur.
(Joker, le chien qui mise, aboie avec les aboiements déjà là : sfx/aboiement_*.)
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v150.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
from generate_sons_v135 import SR, t_, env, fin, place  # noqa: E402

RNG = np.random.default_rng(15050)


def pince(f, dur=0.9, brillance=0.996):
    """Une corde pincée (Karplus-Strong), un peu métallique comme un banjo."""
    n = int(dur * SR)
    p = max(2, int(SR / f))
    buf = RNG.uniform(-1, 1, p)
    out = np.zeros(n)
    for i in range(n):
        out[i] = buf[i % p]
        buf[i % p] = brillance * 0.5 * (buf[i % p] + buf[(i + 1) % p])
    # la peau du banjo : un petit claquement au départ
    t = t_(n)
    out += amb.bp(RNG.standard_normal(n), 1500, 5000) * np.exp(-t * 90.0) * 0.25
    return out * np.exp(-t * 2.2)


NOTES = {"G3": 196.0, "B3": 246.9, "D4": 293.7, "G4": 392.0, "A4": 440.0, "B4": 493.9, "D5": 587.3, "E5": 659.3, "C4": 261.6, "E4": 329.6}
PHRASES = [
    ["G4", "B3", "D4", "G4", "D5", "B4", "G4", "D4", "G4", "B3", "D4", "G4", "B4", "A4", "G4"],
    ["C4", "E4", "G4", "C4", "E5", "C4", "G4", "E4", "D4", "G4", "B4", "D4", "D5", "B4", "G4"],
    ["G4", "G4", "B4", "D5", "E5", "D5", "B4", "G4", "A4", "B4", "A4", "G4", "E4", "D4", "G3"],
]


def banjo(k):
    ph = PHRASES[k - 1]
    pas = 0.17
    n = int((len(ph) * pas + 1.2) * SR)
    out = np.zeros(n)
    for i, note in enumerate(ph):
        f = NOTES[note] * RNG.uniform(0.998, 1.002)
        place(out, pince(f) * (0.75 if i % 2 else 0.95), max(0.0, i * pas + RNG.uniform(-0.008, 0.008)))
        # la cinquième corde, le bourdon (sol aigu), de temps en temps
        if i % 4 == 3:
            place(out, pince(392.0, 0.5) * 0.35, i * pas + pas * 0.5)
    return fin(out, 300) * 0.7


CAT = {"banjo": (banjo, 3)}


def main() -> int:
    total = 0
    for name, (fn, count) in CAT.items():
        for k in range(1, count + 1):
            fx.save(f"{name}_{k}", fn(k))
            total += 1
    print(f"V150 : {total} sons écrits dans {fx.OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
