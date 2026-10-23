"""V67 : les sons d'Arcanelle, l'île des sorciers, et des six sorts qu'on y apprend.

Bruitages (sfx/) :
  sort_lumiere     une orbe s'allume : un accord clair qui s'ouvre, des étincelles d'argent ;
  sort_gel         le givre qui prend : des cristaux qui crépitent, un souffle glacé, une note de verre ;
  sort_levitation  on s'élève : un souffle qui monte, une nappe qui glisse vers l'aigu ;
  sort_telekinesie l'objet qui vole : un bourdonnement qui ondule et monte, des pages qui frémissent, un « pop » ;
  sort_soin        une chaleur douce : la harpe qui monte en majeur, une nappe tiède ;
  brasero          un brasero qui s'embrase : le « fwoump », puis le feu qui crépite ;
  rune_arc         une rune qui s'allume dans la pierre : un bourdon grave, une cloche, un frisson.
Synthétisés ici, ou retravaillés d'après le recueil CC0 « lavenderdotpet/CC0-Public-Domain-Sounds »
(feu, livres) : tout est libre de droits.
Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/generate_sons_v67.py [dossier CC0-Public-Domain-Sounds] [noms...]
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v63 as s63  # noqa: E402
import generate_sons_v56 as s56  # noqa: E402
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402

SR = 44100
RNG = np.random.default_rng(6767)
s63.RNG = np.random.default_rng(6768)
s56.RNG = np.random.default_rng(6769)
amb.RNG = np.random.default_rng(6770)
_t, _norm, _env, _fade, mix, noise, bell, whoosh, rec = (s63._t, s63._norm, s63._env, s63._fade, s63.mix, s63.noise,
                                                         s63.bell, s63.whoosh, s63.rec)


def sparkles(n: int, dur: float, f0: float, f1: float, g0: float = 0.1, g1: float = 0.25) -> np.ndarray:
    out = np.zeros(int((dur + 0.6) * SR))
    for _ in range(n):
        amb.place(out, bell(RNG.uniform(f0, f1), 0.5, 0.6), int(RNG.uniform(0.0, dur) * SR), RNG.uniform(g0, g1))
    return out


def sort_lumiere() -> np.ndarray:
    """Une orbe de lumière qui s'allume : un accord de la majeur qui s'ouvre, des étincelles."""
    x = _t(2.2)
    chord = [880.0, 1108.7, 1318.5, 1760.0, 2217.5]
    pad = sum(np.sin(2 * np.pi * f * x + RNG.uniform(0, 6)) * (1 + 0.003 * np.sin(2 * np.pi * 6 * x)) * (0.85 ** i)
              for i, f in enumerate(chord)) / 3
    env = np.clip(x / 0.25, 0, 1) ** 1.5 * np.exp(-np.clip(x - 0.4, 0, 9) / 0.7)
    sw = whoosh(0.5, 1500.0, 6000.0, 0.5) * 0.35
    ping = bell(1760.0, 1.4, 1.2) * 0.5
    out = mix(2.8, (pad * env * 0.5, 0.0, 1.0), (sw, 0.0, 1.0), (ping, 0.12, 1.0), (sparkles(14, 1.2, 3000, 6500), 0.1, 1.0))
    return _norm(s56._room(out, 1.4, 2.4, 10000.0, 0.3, seed=671), 0.78)


def sort_gel() -> np.ndarray:
    """Le givre qui prend : un souffle glacé, des cristaux qui crépitent, une note de verre qui descend."""
    dur = 2.0
    x = _t(dur)
    air = amb.bp(noise(dur), 2500, 11000) * np.clip(x / 0.15, 0, 1) * np.exp(-x / 0.7) * 0.4
    crack = (RNG.random(len(x)) < np.interp(x, [0, 0.3, 1.4, dur], [0.012, 0.008, 0.002, 0.0])).astype(float)
    crack = amb.hp(crack, 3000) * 1.6
    tink = np.zeros(int((dur + 0.6) * SR))
    for _ in range(22):
        t0 = RNG.uniform(0.0, 1.3)
        amb.place(tink, bell(RNG.uniform(3500, 8000), 0.25, 1.4), int(t0 * SR), RNG.uniform(0.05, 0.16) * (1.3 - t0 * 0.6))
    glass = np.sin(2 * np.pi * np.cumsum(np.interp(x, [0, dur], [2637.0, 1975.5])) / SR) * _env(len(x), 0.01, 0.6) * 0.18
    low = amb.lp(noise(0.5), 400) * _env(int(0.5 * SR), 0.005, 0.12) * 0.6
    out = mix(2.6, (air, 0.0, 1.0), (crack, 0.0, 1.0), (tink, 0.02, 1.0), (glass, 0.05, 1.0), (low, 0.0, 1.0))
    return _norm(s56._room(out, 1.5, 2.2, 9000.0, 0.3, seed=672), 0.82)


def sort_levitation() -> np.ndarray:
    """On s'élève : un souffle qui monte, une nappe qui glisse vers l'aigu, un léger frisson."""
    dur = 2.4
    x = _t(dur)
    up = whoosh(dur, 300.0, 2600.0, 0.55) * 0.9
    f = np.interp(x, [0, dur], [330.0, 660.0])
    pad = sum(np.sin(2 * np.pi * np.cumsum(f * r) / SR + RNG.uniform(0, 6)) * g for r, g in [(1.0, 1.0), (1.5, 0.6), (2.0, 0.4), (3.0, 0.15)])
    pad *= (1 + 0.25 * np.sin(2 * np.pi * 4.5 * x)) * np.sin(np.pi * np.clip(x / dur, 0, 1)) ** 1.2 * 0.18
    out = mix(2.9, (up, 0.0, 1.0), (pad, 0.0, 1.0), (sparkles(6, 1.8, 2500, 5000, 0.04, 0.1), 0.4, 1.0))
    return _norm(s56._room(out, 1.6, 2.0, 8000.0, 0.3, seed=673), 0.78)


def sort_telekinesie() -> np.ndarray:
    """L'objet qui vole vers toi : un bourdon qui ondule et monte, des pages qui frémissent, un « pop »."""
    dur = 1.6
    x = _t(dur)
    f = np.interp(x, [0, dur], [140.0, 420.0]) * (1 + 0.04 * np.sin(2 * np.pi * 7 * x))
    ph = np.cumsum(f) / SR * 2 * np.pi
    hum = (np.sin(ph) + 0.5 * np.sin(2 * ph + 0.3) + 0.25 * np.sin(3 * ph)) * (0.6 + 0.4 * np.sin(2 * np.pi * 3 * x))
    hum = amb.bp(hum, 100, 3000) * np.clip(x / 0.2, 0, 1) * np.clip((dur - x) / 0.3, 0, 1) * 0.35
    pages = rec("80-CC0-RPG-SFX/book_02.ogg", 3)
    pop = bell(1318.5, 0.6, 0.8) * 0.4
    thump = amb.lp(noise(0.08), 900) * _env(int(0.08 * SR), 0.001, 0.02) * 0.8
    out = mix(2.3, (hum, 0.0, 1.0), (pages, 0.15, 0.45), (whoosh(0.6, 600.0, 2400.0, 0.5) * 0.5, 0.9, 1.0), (pop, 1.45, 1.0),
              (thump, 1.45, 1.0))
    return _norm(s56._room(out, 1.2, 2.5, 7000.0, 0.25, seed=674), 0.8)


def sort_soin() -> np.ndarray:
    """Une chaleur douce : la harpe monte en fa majeur, une nappe tiède, une clochette."""
    out = np.zeros(int(3.2 * SR))
    notes = [349.2, 440.0, 523.3, 698.5, 880.0, 1046.5]
    for i, f in enumerate(notes):
        x = _t(2.2)
        pl = sum(np.sin(2 * np.pi * f * k * x) * (0.5 ** (k - 1)) for k in (1, 2, 3)) * np.exp(-x / 0.8) * np.clip(x / 0.003, 0, 1)
        amb.place(out, pl, int(i * 0.09 * SR), 0.22)
    x = _t(3.0)
    pad = sum(np.sin(2 * np.pi * f * x + RNG.uniform(0, 6)) for f in (174.6, 261.6, 349.2, 440.0)) / 4
    pad *= np.clip(x / 0.6, 0, 1) * np.exp(-np.clip(x - 0.9, 0, 9) / 0.8) * 0.3
    out[:len(pad)] += pad
    amb.place(out, bell(2093.0, 1.5, 0.7), int(0.55 * SR), 0.15)
    return _norm(s56._room(out, 1.8, 1.8, 7000.0, 0.35, seed=675), 0.78)


def brasero() -> np.ndarray:
    """Un brasero qui s'embrase : le « fwoump » grave, la flamme qui monte, le crépitement."""
    a = rec("80-CC0-RPG-SFX/spell_fire_02.ogg", -3)
    boom = amb.lp(noise(0.6), 160) * _env(int(0.6 * SR), 0.01, 0.18) * 1.6
    roar = amb.bp(noise(2.0), 200, 2500) * np.clip(_t(2.0) / 0.2, 0, 1) * np.exp(-_t(2.0) / 0.9) * 0.4
    crackle = (RNG.random(int(2.2 * SR)) < 0.003).astype(float)
    crackle = amb.bp(crackle, 1200, 7000) * np.exp(-_t(2.2) / 1.0) * 2.2
    return _norm(mix(2.6, (boom, 0.0, 1.0), (a, 0.02, 0.8), (roar, 0.05, 1.0), (crackle, 0.15, 0.7)), 0.88)


def rune_arc() -> np.ndarray:
    """Une rune qui s'allume dans la pierre : un bourdon grave qui enfle, une cloche, un frisson d'aigus."""
    x = _t(2.6)
    drone = sum(np.sin(2 * np.pi * f * x + RNG.uniform(0, 6)) * g for f, g in [(110.0, 1.0), (165.0, 0.5), (220.0, 0.35), (330.0, 0.15)])
    drone *= np.clip(x / 0.5, 0, 1) ** 2 * np.exp(-np.clip(x - 0.7, 0, 9) / 0.7) * 0.4
    b = bell(659.3, 2.0, 1.1) * 0.45
    sh = amb.bp(noise(1.2), 4000, 10000) * np.sin(np.pi * np.clip(_t(1.2) / 1.2, 0, 1)) * 0.12
    out = mix(3.2, (drone, 0.0, 1.0), (b, 0.45, 1.0), (sh, 0.4, 1.0), (sparkles(5, 0.8, 2000, 4000, 0.04, 0.09), 0.55, 1.0))
    return _norm(s56._room(out, 2.2, 1.5, 5000.0, 0.4, seed=676), 0.82)


SOUNDS = {
    "sort_lumiere": sort_lumiere, "sort_gel": sort_gel, "sort_levitation": sort_levitation,
    "sort_telekinesie": sort_telekinesie, "sort_soin": sort_soin, "brasero": brasero, "rune_arc": rune_arc,
}


def main() -> int:
    if len(sys.argv) > 1 and Path(sys.argv[1]).is_dir():
        s63.LIB = Path(sys.argv[1])
        names = sys.argv[2:]
    else:
        names = sys.argv[1:]
    for name, fn in SOUNDS.items():
        if names and name not in names:
            continue
        fx.save(f"{name}_1", fn())
        print(" ", name)
    return 0


if __name__ == "__main__":
    sys.exit(main())
