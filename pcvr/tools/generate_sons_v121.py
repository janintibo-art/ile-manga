"""V121 : les sons de Sombreval, la ville morte (synthétisés ici, ou tirés de la banque CC0 et
retravaillés ; versés au domaine public, CC0 1.0).

  sfx/zombie_grogne_1..8   le long grognement d'un mort-vivant (« hhhuuuurrgh ») : une voix grave
                           qui racle (une source glottale qui tremble, des formants de « ou / o »,
                           un frottement de gorge), mêlée à des grognements de la banque CC0
                           descendus de quelques demi-tons.
  sfx/zombie_cri_1..4      le hurlement de l'enragé quand il te voit : une voix éraillée qui monte.
  sfx/zombie_attaque_1..4  le grondement quand il se jette sur toi.
  sfx/zombie_mort_1..4     le dernier râle (un gargouillis, un souffle qui s'éteint).
  sfx/coeur_peur_1         le cœur qui bat fort (deux coups sourds).
  ambiance/sombreval       la ville morte (48 s, en boucle) : le vent dans les immeubles crevés,
                           des grincements de tôle, des grognements très lointains, un grondement
                           d'orage qui roule au loin.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v121.py [/root/snd/CC0-Public-Domain-Sounds]
"""
from pathlib import Path
import sys

import numpy as np
from scipy import signal

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402

SR = 44100
RNG = np.random.default_rng(12121)
CRE = "80-CC0-creature-SFX/"
CRE2 = "80-CC0-creature-sfx-2/"
WM = "100-CC0-wood-metal-SFX/"


def t_(n):
    return np.arange(n) / SR


def norm(x, peak=0.89):
    return x / (np.max(np.abs(x)) + 1e-9) * peak


def bpf(x, f, q):
    b, a = signal.iirpeak(min(f, SR * 0.45), q, fs=SR)
    return signal.lfilter(b, a, x)


def place(buf, ev, at, gain=1.0):
    at = int(at)
    if at >= len(buf):
        return
    k = min(len(ev), len(buf) - at)
    buf[at:at + k] += ev[:k] * gain


def place_loop(buf, ev, at, gain=1.0):
    n = len(buf)
    at = int(at) % n
    k = min(len(ev), n - at)
    buf[at:at + k] += ev[:k] * gain
    if k < len(ev):
        buf[:len(ev) - k] += ev[k:] * gain


def glottal(f0: np.ndarray, rough: float) -> np.ndarray:
    """Une source de voix : des harmoniques (1/n), une fréquence qui tremble (jitter), du grain."""
    jit = 1.0 + rough * 0.06 * amb.lp(RNG.standard_normal(len(f0)), 40)
    ph = 2 * np.pi * np.cumsum(f0 * jit) / SR
    y = np.zeros(len(f0))
    for k in range(1, 28):
        y += np.sin(k * ph) / k ** 1.1 * (f0 * k < 9000)
    # le frottement de gorge : des à-coups lents (la « friture » de la voix)
    fry = 0.55 + 0.45 * np.sign(np.sin(2 * np.pi * np.cumsum(np.full(len(f0), 27.0 + 8.0 * rough)) / SR + RNG.uniform(0, 6)))
    fry = amb.lp(fry, 120)
    return y * (1.0 - 0.6 * rough + 0.6 * rough * fry)


def formants(src: np.ndarray, fs: list) -> np.ndarray:
    out = np.zeros(len(src))
    for f, q, g in fs:
        out += bpf(src, f, q) * g
    return out


def moan(dur: float, f0a: float, f0b: float, vowel: str, rough: float) -> np.ndarray:
    n = int(dur * SR)
    t = t_(n)
    u = t / dur
    f0 = f0a + (f0b - f0a) * u ** 0.8 + 6.0 * np.sin(2 * np.pi * 3.1 * t) * u
    src = glottal(f0, rough)
    asp = amb.bp(RNG.standard_normal(n), 300, 4500) * 0.35
    if vowel == "ou":
        F = [(320, 6, 1.0), (760, 7, 0.55), (2400, 10, 0.18), (3200, 12, 0.08)]
    elif vowel == "a":
        F = [(720, 5, 1.0), (1150, 6, 0.7), (2500, 9, 0.25), (3400, 12, 0.1)]
    else:
        F = [(450, 6, 1.0), (850, 7, 0.6), (2450, 10, 0.2), (3300, 12, 0.08)]
    y = formants(src + asp * (0.6 + rough), F)
    env = np.clip(t / 0.18, 0, 1) * np.clip((dur - t) / 0.45, 0, 1) ** 1.4
    env *= 0.8 + 0.2 * np.sin(2 * np.pi * 1.7 * t + RNG.uniform(0, 6))
    return norm(amb.lp(y * env, 3800))


def lib_pitched(lib, files, semi, lp_hz=2600.0):
    out = []
    if lib is None:
        return out
    for f in files:
        p = lib / f
        if not p.is_file():
            print("  ! absent :", f)
            continue
        x = fx.read_mono(p)
        x = fx.process(x, 3.0, semi, 70)
        out.append(norm(amb.lp(x, lp_hz)))
    return out


def mix_at(a, b, gb, off_s=0.0):
    off = int(off_s * SR)
    n = max(len(a), len(b) + off)
    y = np.zeros(n)
    y[:len(a)] += a
    y[off:off + len(b)] += b * gb
    return norm(y)


def grunt(k, libx):
    dur = RNG.uniform(1.3, 2.4)
    y = moan(dur, RNG.uniform(88, 112), RNG.uniform(62, 80), ["ou", "o", "ou", "a"][k % 4], RNG.uniform(0.5, 0.95))
    if libx:
        y = mix_at(y, libx[k % len(libx)], 0.55, RNG.uniform(0.05, 0.5))
    # une respiration rauque à la fin
    n = int(0.5 * SR)
    th = t_(n)
    br = amb.bp(RNG.standard_normal(n), 400, 2200) * np.sin(np.pi * th / th[-1]) * 0.3
    y = np.concatenate([y, np.zeros(int(0.1 * SR))])
    place(y, br, len(y) - n, 1.0)
    return norm(y)


def shriek(k, libx):
    dur = RNG.uniform(1.0, 1.5)
    n = int(dur * SR)
    t = t_(n)
    f0 = 260 + 160 * np.sin(np.pi * np.clip(t / dur * 1.2, 0, 1)) + RNG.uniform(-20, 20)
    src = glottal(f0, 0.9) + amb.bp(RNG.standard_normal(n), 800, 6000) * 0.9
    y = formants(src, [(820, 4, 1.0), (1250, 5, 0.8), (2700, 7, 0.4), (3600, 9, 0.2)])
    y = np.tanh(y / (np.max(np.abs(y)) + 1e-9) * 3.0)
    env = np.clip(t / 0.06, 0, 1) * np.clip((dur - t) / 0.35, 0, 1)
    y = norm(amb.lp(y * env, 6500))
    if libx:
        y = mix_at(y, libx[k % len(libx)], 0.5, 0.0)
    return y


def snarl(k, libx):
    y = moan(RNG.uniform(0.55, 0.85), 130, 95, "a", 1.0)
    y = np.tanh(y * 2.2)
    if libx:
        y = mix_at(y, libx[k % len(libx)], 0.7, 0.0)
    return norm(y)


def death(k, libx):
    y = moan(RNG.uniform(1.2, 1.7), 95, 52, "o", 0.9)
    n = len(y)
    t = t_(n)
    # le gargouillis : des bulles graves
    g = np.zeros(n)
    for _ in range(14):
        at = int(RNG.uniform(0.2, 0.9) * n)
        m = int(0.05 * SR)
        tm = t_(m)
        place(g, np.sin(2 * np.pi * RNG.uniform(140, 320) * tm * (1 + tm * 8)) * np.exp(-tm / 0.015), at, RNG.uniform(0.2, 0.5))
    y = norm(y * np.clip((t[-1] - t) / 0.8, 0, 1) + g * 0.6)
    if libx:
        y = mix_at(libx[k % len(libx)], y, 0.9, 0.12)
    return y


def heart():
    n = int(1.0 * SR)
    y = np.zeros(n)
    for at, g in ((0.0, 1.0), (0.22, 0.7)):
        m = int(0.18 * SR)
        tm = t_(m)
        th = np.sin(2 * np.pi * (58 - 20 * tm / tm[-1]) * tm) * np.exp(-tm / 0.05)
        place(y, th, at * SR, g)
    return norm(amb.lp(y, 300))


def ville_morte(lib, seconds=48.0):
    n = int(seconds * SR)
    t = t_(n)
    # le vent : un grave qui souffle, des sifflements dans les fenêtres crevées
    w = amb.lp(amb.noise(n, "brown"), 380, 2) * amb.smooth_env(n, 0.07, 0.35, 1.0)
    whistle = amb.bp(amb.noise(n, "white"), 600, 1400) * amb.smooth_env(n, 0.11, 0.0, 0.35)
    left = w * 0.9 + whistle * 0.25
    right = np.roll(w, int(0.4 * SR)) * 0.9 + np.roll(whistle, int(0.9 * SR)) * 0.25
    # des grognements très lointains (étouffés, avec un écho)
    for k in range(7):
        g = moan(RNG.uniform(1.4, 2.4), RNG.uniform(85, 110), RNG.uniform(60, 75), "ou", 0.7)
        g = amb.lp(g, 700) * RNG.uniform(0.12, 0.22)
        at = int(RNG.uniform(0, seconds) * SR)
        pan = RNG.uniform(-1, 1)
        for d, gg in ((0.0, 1.0), (0.31, 0.35), (0.67, 0.15)):
            place_loop(left, g * gg * (1 - pan) * 0.5, at + int(d * SR))
            place_loop(right, g * gg * (1 + pan) * 0.5, at + int(d * SR))
    # des grincements de tôle et de bois
    if lib is not None:
        cr = []
        for f in ["wood_squeak_01.ogg", "wood_squeak_02.ogg", "metal_sheet_02.ogg", "wood_cracking_02.ogg"]:
            p = lib / WM / f
            if p.is_file():
                cr.append(norm(amb.lp(fx.process(fx.read_mono(p), 2.5, -5, 80), 2000)))
        for k in range(6):
            if not cr:
                break
            at = int(RNG.uniform(0, seconds) * SR)
            pan = RNG.uniform(-1, 1)
            c = cr[k % len(cr)] * RNG.uniform(0.08, 0.16)
            place_loop(left, c * (1 - pan) * 0.5, at)
            place_loop(right, c * (1 + pan) * 0.5, at)
    # un orage roule au loin
    for at_s in (11.0, 33.0):
        m = int(6.0 * SR)
        tm = t_(m)
        r = amb.lp(amb.noise(m, "brown"), 120, 2) * np.exp(-tm / 2.2) * np.clip(tm / 0.6, 0, 1)
        place_loop(left, r * 0.7, int(at_s * SR))
        place_loop(right, r * 0.7, int((at_s + 0.15) * SR))
    st = amb.stereo(left, right)
    return amb.loopify(st, 3.0)


def main() -> int:
    lib = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/root/snd/CC0-Public-Domain-Sounds")
    if not lib.is_dir():
        lib = None
    g_lib = lib_pitched(lib, [CRE2 + "human_01.ogg", CRE2 + "human_03.ogg", CRE + "grunt_01.ogg", CRE + "monster_04.ogg",
                              CRE2 + "human_06.ogg", CRE2 + "grunt_07.ogg", CRE + "troll_02.ogg", CRE + "monster_07.ogg"], -5)
    s_lib = lib_pitched(lib, [CRE + "scream_01.ogg", CRE + "scream_02.ogg", CRE + "howl.ogg", CRE2 + "attack_04.ogg"], -2, 7000)
    a_lib = lib_pitched(lib, [CRE2 + "attack_02.ogg", CRE2 + "attack_04.ogg", CRE + "monster_02.ogg", CRE2 + "monster_13.ogg"], -4)
    d_lib = lib_pitched(lib, [CRE2 + "die_02.ogg", CRE2 + "die_03.ogg", CRE2 + "die_04.ogg", CRE2 + "die_01.ogg"], -5)
    for k in range(8):
        fx.save(f"zombie_grogne_{k + 1}", grunt(k, g_lib))
    for k in range(4):
        fx.save(f"zombie_cri_{k + 1}", shriek(k, s_lib))
        fx.save(f"zombie_attaque_{k + 1}", snarl(k, a_lib))
        fx.save(f"zombie_mort_{k + 1}", death(k, d_lib))
    fx.save("coeur_peur_1", heart())
    amb.save("ambiance/sombreval", ville_morte(lib))
    print("V121 : les sons de Sombreval sont faits")
    return 0


if __name__ == "__main__":
    sys.exit(main())
