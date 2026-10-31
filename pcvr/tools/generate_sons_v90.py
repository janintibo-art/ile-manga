"""V90 : les cris et les pas des dinosaures de l'Île Pixelithique.

D'après le recueil CC0 « lavenderdotpet/CC0-Public-Domain-Sounds » (créatures, monstres), transposé et
mélangé, et des sons synthétisés ici (domaine public) :
  sfx/raptor_cri_1..3     le raptor qui siffle avant de bondir (aigu, rauque)
  sfx/raptor_fuite_1..2   le raptor vaincu qui détale (« Iiih ! »)
  sfx/trice_grogne_1..2   le tricératops qui gratte la terre (un grognement grave)
  sfx/trice_fuite_1       le tricératops qui se couche (un long soupir)
  sfx/anky_grogne_1..2    l'ankylosaure (un grondement de ventre)
  sfx/anky_fuite_1        l'ankylosaure qui s'endort
  sfx/ptero_cri_1..3      le ptéranodon (un cri d'oiseau, rauque et râpeux)
  sfx/trex_rugit_1..2     GROSSE-DENT qui rugit : un monstre transposé très bas, un grondement de
                          poitrine synthétisé (40-90 Hz), un souffle
  sfx/trex_ronfle_1       Grosse-Dent qui ronfle (vaincu)
  sfx/trex_pas_1..2       un pas de tyrannosaure (un coup sourd, le sol qui tremble)
  sfx/longcou_cri_1..2    le long cri d'un brachiosaure (une trompe grave qui glisse)
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v90.py [<dossier CC0-Public-Domain-Sounds>]
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
import generate_sons_v54 as s54  # noqa: E402
import generate_sons_v58 as s58  # noqa: E402

SR = 44100
RNG = np.random.default_rng(9090)
CR = "80-CC0-creature-SFX/"
CR2 = "80-CC0-creature-sfx-2/"


def _n(x, peak=0.89):
    return s58._norm(x, peak)


def rumble(dur, f0=55.0, f1=42.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = f0 + (f1 - f0) * (t / dur)
    ph = 2 * np.pi * np.cumsum(f) / SR
    y = np.sin(ph) + 0.5 * np.sin(2 * ph + 0.4) + 0.3 * np.sin(3 * ph + 1.2)
    y *= 0.6 + 0.4 * np.abs(np.sin(2 * np.pi * 23.0 * t))          # la gorge qui vibre
    y += 0.5 * amb.lp(RNG.standard_normal(n), 300.0)
    env = np.clip(t / 0.15, 0, 1) * np.clip((dur - t) / 0.6, 0, 1)
    return y * env


def ronfle():
    dur = 3.2
    n = int(dur * SR)
    t = np.arange(n) / SR
    inspire = np.clip(np.sin(np.pi * np.clip(t / 1.6, 0, 1)), 0, 1) ** 1.5
    expire = np.clip(np.sin(np.pi * np.clip((t - 1.8) / 1.2, 0, 1)), 0, 1) * (t > 1.8)
    ph = 2 * np.pi * np.cumsum(38.0 + 6.0 * inspire) / SR
    y = (np.sin(ph) + 0.6 * np.sign(np.sin(ph)) * 0.4) * inspire * (0.6 + 0.4 * np.abs(np.sin(2 * np.pi * 28.0 * t)))
    y += amb.bp(RNG.standard_normal(n), 200.0, 1200.0) * expire * 0.5
    return y


def pas():
    dur = 1.2
    n = int(dur * SR)
    t = np.arange(n) / SR
    y = np.sin(2 * np.pi * (60.0 - 25.0 * t) * t) * np.exp(-t / 0.18)
    y += 0.6 * amb.lp(RNG.standard_normal(n), 180.0) * np.exp(-t / 0.3)
    y += 0.25 * amb.bp(RNG.standard_normal(n), 800.0, 3000.0) * np.exp(-np.maximum(t - 0.05, 0) / 0.05) * (t > 0.04)
    return y


def longcou(k):
    dur = 3.6
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = (190.0 - 70.0 * (t / dur) ** 0.8) * (1.0 + 0.04 * k)
    f *= 1.0 + 0.01 * np.sin(2 * np.pi * 4.5 * t)
    ph = 2 * np.pi * np.cumsum(f) / SR
    src = sum(np.sin(h * ph) / h ** 0.9 for h in range(1, 9))
    y = amb.bp(src, 150.0, 900.0) * 0.8 + amb.bp(src, 900.0, 2400.0) * 0.25
    env = np.clip(t / 0.35, 0, 1) * np.clip((dur - t) / 1.2, 0, 1)
    out = np.stack([y * env, np.roll(y * env, 61)], 1)
    return s58._room(out, 3.0, 0.9, 3000.0, 0.45, seed=90 + k)


def main() -> int:
    lib = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/root/snd/CC0-Public-Domain-Sounds")
    ok = lib.is_dir()
    for k in range(2):
        fx.save(f"trex_pas_{k + 1}", _n(pas()))
        fx.save(f"longcou_cri_{k + 1}", _n(longcou(k)))
    fx.save("trex_ronfle_1", _n(ronfle()))
    if not ok:
        print("Sans le recueil CC0, seuls les sons synthétisés sont refaits.")
        return 0
    rap = s54.from_lib(lib, [CR2 + "attack_02.ogg", CR + "monster_03.ogg", CR2 + "attack_04.ogg"], 0.9, 5, 400)
    hiss = s54.from_lib(lib, [CR + "bug_02.ogg", CR2 + "bug_07.ogg", CR + "bug_04.ogg"], 0.9, 2, 1500)
    for i in range(min(len(rap), len(hiss))):
        fx.save(f"raptor_cri_{i + 1}", _n(s54.layer(rap[i], hiss[i], 0.45, 0.05)))
    sq = s54.from_lib(lib, [CR + "cute_03.ogg", CR + "cute_07.ogg"], 0.7, 3, 600)
    for i, x in enumerate(sq):
        fx.save(f"raptor_fuite_{i + 1}", _n(x))
    gr = s54.from_lib(lib, [CR + "grunt_02.ogg", CR2 + "grunt_07.ogg"], 1.4, -6, 50)
    for i, x in enumerate(gr):
        fx.save(f"trice_grogne_{i + 1}", _n(s54.layer(x, rumble(1.2, 70.0, 55.0), 0.4, 0.0)))
    sig = s54.from_lib(lib, [CR + "breath.ogg"], 2.0, -5, 40)
    for i, x in enumerate(sig):
        fx.save(f"trice_fuite_{i + 1}", _n(x))
    an = s54.from_lib(lib, [CR + "grunt_04.ogg", CR2 + "grunt_09.ogg"], 1.4, -9, 40)
    for i, x in enumerate(an):
        fx.save(f"anky_grogne_{i + 1}", _n(s54.layer(x, rumble(1.3, 50.0, 40.0), 0.5, 0.0)))
    fx.save("anky_fuite_1", _n(ronfle()[: int(2.0 * SR)]))
    for k in range(3):
        fx.save(f"ptero_cri_{k + 1}", _n(s54.eagle_cry(k)[:, 0] if s54.eagle_cry(k).ndim == 2 else s54.eagle_cry(k)))
    big = s54.from_lib(lib, [CR + "monster_05.ogg", CR + "monster_01.ogg"], 2.6, -11, 25)
    howl = s54.from_lib(lib, [CR + "howl.ogg"], 2.6, -9, 30)
    for i, x in enumerate(big):
        y = s54.layer(x, rumble(2.4, 58.0, 40.0), 0.7, 0.0)
        if howl:
            y = s54.layer(y, howl[0], 0.35, 0.1)
        fx.save(f"trex_rugit_{i + 1}", _n(s58._room(np.stack([y, np.roll(y, 37)], 1), 1.6, 1.8, 4000.0, 0.25, seed=95 + i)))
    print("V90 : les sons des dinosaures sont faits")
    return 0


if __name__ == "__main__":
    sys.exit(main())
