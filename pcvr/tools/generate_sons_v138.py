"""V138 : les cris de la faune d'Arcanelle, de l'Île de Braise et de Hautefond (synthétisés ici ;
versés au domaine public, CC0 1.0).

  sfx/corbeau_croasse_1..2   le grand corbeau : deux ou trois « croaa » graves et rauques.
  sfx/molosse_jappe_1..2     le molosse des cendres : des aboiements secs, un grondement.
  sfx/macareux_grogne_1..2   le macareux : un ronronnement grave qui monte et descend.
  sfx/mouton_bele_1..2       le mouton : un bêlement chevrotant.
  sfx/effraie_cri_1..2       la chouette effraie : son cri soufflé, long et rauque.
(L'iguane marin éternue avec le son déjà dans le jeu, sfx/eternuement_* ; l'hermine, le vautour et
les phalènes sont muets.)
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v138.py
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
from generate_sons_v135 import SR, t_, env, fin, voix, place  # noqa: E402

RNG = np.random.default_rng(13838)


def corbeau(k):
    dur = 1.2
    out = np.zeros(int(dur * SR))
    tt = 0.02
    for j in range(RNG.integers(2, 4)):
        d = RNG.uniform(0.2, 0.28)
        m = int(d * SR)
        u = np.linspace(0, 1, m)
        f = RNG.uniform(300, 380) * (1.0 + 0.15 * np.sin(np.pi * u) - 0.2 * u)
        y = voix(f, [(1, 0.6), (2, 1.0), (3, 0.8), (4, 0.6), (5, 0.4), (7, 0.2)], jitter=0.09)
        rauque = amb.bp(RNG.standard_normal(m), 500, 3500) * 0.5
        place(out, (y + rauque) * np.sin(np.pi * u) ** 0.5, tt)
        tt += d + RNG.uniform(0.08, 0.14)
        if tt > dur - 0.3:
            break
    return fin(amb.bp(out, 200, 5000), 150)


def molosse(k):
    dur = 1.1
    out = np.zeros(int(dur * SR))
    tt = 0.02
    for j in range(RNG.integers(2, 4)):
        d = RNG.uniform(0.11, 0.15)
        m = int(d * SR)
        u = np.linspace(0, 1, m)
        f = RNG.uniform(260, 330) * (1.0 + 0.3 * np.sin(np.pi * u))
        y = voix(f, [(1, 1.0), (2, 0.8), (3, 0.6), (4, 0.4), (6, 0.2)], jitter=0.06)
        place(out, (y + amb.bp(RNG.standard_normal(m), 600, 3000) * 0.4) * np.sin(np.pi * u) ** 0.4, tt)
        tt += d + RNG.uniform(0.1, 0.16)
    m = int(0.35 * SR)
    g = voix(RNG.uniform(85, 100) * np.ones(m), [(1, 1.0), (2, 0.7), (3, 0.5)], jitter=0.08)
    place(out, g * env(m, 0.05, 0.12) * 0.6, min(tt, dur - 0.37))
    return fin(out, 70)


def macareux(k):
    dur = 1.0
    n = int(dur * SR)
    u = np.linspace(0, 1, n)
    f = RNG.uniform(120, 150) * (1.0 + 0.25 * np.sin(np.pi * u * 2.0))
    y = voix(f, [(1, 1.0), (2, 0.6), (3, 0.4)], jitter=0.05)
    puls = 0.5 + 0.5 * np.sin(2 * np.pi * RNG.uniform(22, 30) * t_(n))
    return fin(amb.lp(y * puls * np.sin(np.pi * u) ** 0.6, 1800), 60) * 0.8


def mouton(k):
    dur = RNG.uniform(0.9, 1.1)
    n = int(dur * SR)
    u = np.linspace(0, 1, n)
    f = RNG.uniform(360, 440) * (1.0 + 0.04 * np.sin(2 * np.pi * RNG.uniform(6, 8) * t_(n)) - 0.1 * u)
    y = voix(f, [(1, 0.7), (2, 1.0), (3, 0.8), (4, 0.5), (5, 0.3), (6, 0.2)], jitter=0.03)
    trem = 0.6 + 0.4 * np.abs(np.sin(2 * np.pi * RNG.uniform(6.5, 8.5) * t_(n)))
    nasal = amb.bp(y, 600, 3000)
    return fin(nasal * trem * env(n, 0.05, 0.3), 150)


def effraie(k):
    dur = RNG.uniform(1.1, 1.4)
    n = int(dur * SR)
    u = np.linspace(0, 1, n)
    h = amb.bp(RNG.standard_normal(n), 1500, 7000) * np.sin(np.pi * np.minimum(u * 1.3, 1.0)) ** 0.8
    rough = 0.6 + 0.4 * np.sign(np.sin(2 * np.pi * RNG.uniform(55, 70) * t_(n)))
    return fin(h * rough * env(n, 0.05, 0.35), 900)


CAT = {
    "corbeau_croasse": (corbeau, 2), "molosse_jappe": (molosse, 2), "macareux_grogne": (macareux, 2),
    "mouton_bele": (mouton, 2), "effraie_cri": (effraie, 2),
}


def main() -> int:
    total = 0
    for name, (fn, count) in CAT.items():
        for k in range(1, count + 1):
            fx.save(f"{name}_{k}", fn(k))
            total += 1
    print(f"V138 : {total} sons écrits dans {fx.OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
