"""V89 : les bruitages du souterrain du Grand Moaï (l'Île aux Moaïs).

Synthétisés ici (domaine public, CC0) :
  sfx/chant_0..4_1   les cinq Pierres-qui-Chantent de la Salle du Chant (et les quatre pierres
                     gravées de la vasque) : une voix de pierre, ronde et grave (un chœur sans
                     paroles, voyelle « o »), posée sur la résonance d'une grosse pierre qu'on
                     frappe du plat de la main ; la gamme pentatonique de ré mineur (ré, fa, sol,
                     la, do), une longue traîne de caverne.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v89.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
import generate_sons_v58 as s58  # noqa: E402

SR = s58.SR
NOTES = [146.83, 174.61, 196.0, 220.0, 261.63]       # ré, fa, sol, la, do (une octave sous le chant)


def pierre(i: int) -> np.ndarray:
    f = NOTES[i]
    dur = 2.6
    n = int(dur * SR)
    t = np.arange(n) / SR
    env = np.clip(t / 0.09, 0, 1) * np.exp(-np.maximum(t - 0.4, 0) / 0.9)
    out = np.zeros((n, 2))
    # la voix de pierre : trois voix en « o » (fondamentale, octave, quinte très douce)
    for ch in range(2):
        det = 1.0 + (ch - 0.5) * 0.005
        y = s58.formant_voice(f * 2 * det, dur, "o") * 0.55
        y += s58.formant_voice(f * det, dur, "o") * 0.45
        y += s58.formant_voice(f * 3 * det, dur, "a") * 0.12
        out[:, ch] += y * env
    # la pierre qui résonne (partiels graves inharmoniques) et le plat de la main
    amb.place(out, s58.crystal(f, 2.4, 0.35), 0, 0.42, 0.0)
    amb.place(out, s58.crystal(f * 2, 1.6, 0.25), 0, 0.15, 0.0)
    m = int(0.04 * SR)
    knock = amb.bp(np.random.default_rng(890 + i).standard_normal(m), 120, 900) * np.hanning(m)
    amb.place(out, knock, 0, 0.5, 0.0)
    return s58._norm(s58._room(out, 3.2, 1.1, 3800.0, 0.5, seed=890 + i), 0.85)


def main() -> int:
    for i in range(5):
        fx.save(f"chant_{i}_1", pierre(i))
    print("V89 : 5 pierres qui chantent")
    return 0


if __name__ == "__main__":
    sys.exit(main())
