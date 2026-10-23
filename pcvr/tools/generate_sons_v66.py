"""V66 : les bruits des objets qu'on casse, des coffres fermés à clé, et de ce qu'on boit.

Bruitages (sfx/) :
  caisse_casse   des planches qui éclatent, puis retombent ;
  tonneau_casse  les douelles qui cèdent, un cercle de fer qui sonne en tombant, un peu de liquide ;
  panier_casse   l'osier qui craque ;
  coffre_verrou  on secoue un coffre fermé à clé : le loquet claque, le moraillon cliquette ;
  boire          trois gorgées (le « glouglou » de la gorge, des bulles), puis un souffle ;
  rot            un rot sonore ;
  hoquet         un « hic ! » (synthétisé : un coup de glotte et une voyelle brève).
Retravaillés d'après le recueil CC0 « lavenderdotpet/CC0-Public-Domain-Sounds » (bois, métal,
éclaboussures, créatures), ou synthétisés ici : tout est libre de droits.
Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/generate_sons_v66.py [dossier CC0-Public-Domain-Sounds]
"""
from pathlib import Path
import sys

import numpy as np
from scipy import signal

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_bruitages_v50 as fx  # noqa: E402

SR = 44100
RNG = np.random.default_rng(6666)
LIB = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/root/snd/CC0-Public-Domain-Sounds")
BFH = "75-cc0-breaking-falling-hit-sfx/"
WM = "100-CC0-wood-metal-SFX/"
SPL = "40-cc0-water-splash-slime-sfx/"
CRE = "80-CC0-creature-SFX/"
K_RPG = "kenney_rpgaudio/Audio/"


def src(name, max_s=2.0, semi=0, hp=60):
    return fx.process(fx.read_mono(LIB / name), max_s, semi, hp)


def mix(parts, length):
    """parts : [(signal, départ en s, gain)]"""
    out = np.zeros(int(length * SR))
    for x, t0, g in parts:
        i0 = int(t0 * SR)
        n = min(len(x), len(out) - i0)
        if n > 0:
            out[i0:i0 + n] += x[:n] * g
    fade = int(0.05 * SR)
    out[-fade:] *= np.linspace(1, 0, fade)
    return out / (np.max(np.abs(out)) + 1e-9) * 0.89


def t(seconds):
    return np.arange(int(seconds * SR)) / SR


def bandpass(x, lo, hi, order=2):
    sos = signal.butter(order, [lo, hi], btype="bandpass", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def lowpass(x, hz, order=2):
    sos = signal.butter(order, hz, btype="lowpass", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


# =================================================================== casser

def caisse():
    k = 0
    for i, name in enumerate([BFH + "bfh1_wood_breaking_01.ogg", BFH + "bfh1_wood_breaking_02.ogg", BFH + "bfh1_wood_breaking_03.ogg",
                              BFH + "bfh1_wood_breaking_04.ogg", WM + "wood_breaking_01.ogg", WM + "wood_breaking_02.ogg"]):
        if not (LIB / name).is_file():
            continue
        brk = src(name, 1.2, 0, 60)
        fall = src(WM + "wood_falling_0%d.ogg" % (1 + i % 6), 0.9, 1, 80)
        k += 1
        fx.save("caisse_casse_%d" % k, mix([(brk, 0.0, 1.0), (fall, 0.28, 0.45)], 1.6))
    print("caisse_casse:", k)


def tonneau():
    k = 0
    for i in range(4):
        brk = src(BFH + "bfh1_wood_breaking_0%d.ogg" % (1 + i), 1.2, -2, 50)
        hoop = src(BFH + "bfh1_metal_falling_0%d.ogg" % (1 + i), 1.0, 2, 120)
        splash = src(SPL + "splash_0%d.ogg" % (1 + i), 0.6, -3, 150)
        k += 1
        fx.save("tonneau_casse_%d" % k, mix([(brk, 0.0, 1.0), (splash, 0.04, 0.35), (hoop, 0.22, 0.4)], 1.8))
    print("tonneau_casse:", k)


def panier():
    k = 0
    for i in range(4):
        cr = src(WM + "wood_cracking_0%d.ogg" % (1 + i), 0.6, 5, 200)
        cr2 = src(WM + "wood_cracking_0%d.ogg" % (1 + (i + 1) % 4), 0.5, 8, 300)
        k += 1
        fx.save("panier_casse_%d" % k, mix([(cr, 0.0, 1.0), (cr2, 0.07, 0.6)], 0.8))
    print("panier_casse:", k)


def verrou():
    latch = src(K_RPG + "metalLatch.ogg", 0.4, 0, 150)
    click = src(K_RPG + "metalClick.ogg", 0.3, 0, 150)
    creak = src(K_RPG + "creak1.ogg", 0.5, 2, 100)
    fx.save("coffre_verrou_1", mix([(latch, 0.0, 1.0), (click, 0.14, 0.7), (click, 0.27, 0.5)], 0.7))
    fx.save("coffre_verrou_2", mix([(creak, 0.0, 0.4), (latch, 0.05, 1.0), (latch, 0.22, 0.6)], 0.75))
    fx.save("coffre_verrou_3", mix([(click, 0.0, 0.8), (latch, 0.1, 1.0), (click, 0.3, 0.6)], 0.7))
    print("coffre_verrou: 3")


# =================================================================== boire

def gulp(f0):
    """Une gorgée : un clic de gorge, le « glunk » qui remonte, deux ou trois bulles."""
    n = int(0.32 * SR)
    out = np.zeros(n)
    click = RNG.normal(0, 1, int(0.012 * SR))
    click = bandpass(click, 900, 3200) * np.linspace(1, 0, len(click)) * 0.35
    out[:len(click)] += click
    tt = t(0.2)
    f = f0 + (f0 * 0.9) * (1 - np.exp(-tt / 0.05))
    ph = 2 * np.pi * np.cumsum(f) / SR
    env = (1 - np.exp(-tt / 0.004)) * np.exp(-tt / 0.045)
    g = (np.sin(ph) + 0.35 * np.sin(2 * ph) + 0.12 * np.sin(3 * ph)) * env
    i0 = int(0.008 * SR)
    out[i0:i0 + len(g)] += g
    for _ in range(RNG.integers(2, 4)):
        bf = RNG.uniform(650, 1300)
        bt = t(0.06)
        bfreq = bf * (1 + 0.35 * bt / 0.06)
        bph = 2 * np.pi * np.cumsum(bfreq) / SR
        b = np.sin(bph) * np.exp(-bt / 0.014) * RNG.uniform(0.12, 0.25)
        j = int(RNG.uniform(0.03, 0.2) * SR)
        out[j:j + len(b)] += b[:max(0, min(len(b), n - j))]
    return out


def boire():
    for k in range(3):
        L = 1.9
        base = np.zeros(int(L * SR))
        # le liquide (un murmure grave qui va et vient)
        noise = lowpass(RNG.normal(0, 1, len(base)), 900) * 0.05
        mod = 0.6 + 0.4 * np.sin(2 * np.pi * 2.3 * t(L) + k)
        base += bandpass(noise, 150, 900) * mod * 2.0
        f0 = RNG.uniform(150, 190)
        for g_t in (0.12, 0.58 + RNG.uniform(-0.04, 0.04), 1.02 + RNG.uniform(-0.05, 0.05)):
            g = gulp(f0 * RNG.uniform(0.92, 1.08))
            i0 = int(g_t * SR)
            base[i0:i0 + len(g)] += g
        # « ahh » : un souffle qui sort
        br = bandpass(RNG.normal(0, 1, int(0.35 * SR)), 350, 2200) * 0.16
        br *= np.sin(np.linspace(0, np.pi, len(br))) ** 1.5
        i1 = int(1.42 * SR)
        base[i1:i1 + len(br)] += br
        fade = int(0.08 * SR)
        base[-fade:] *= np.linspace(1, 0, fade)
        sos = signal.butter(2, 70, btype="highpass", fs=SR, output="sos")
        base = signal.sosfilt(sos, base)
        fx.save("boire_%d" % (k + 1), base / (np.max(np.abs(base)) + 1e-9) * 0.85)
    print("boire: 3")


def rot():
    k = 0
    for i, (name, semi) in enumerate([(CRE + "burp_01.ogg", -1), (CRE + "burp_02.ogg", -1), (CRE + "burp_01.ogg", 1)]):
        k += 1
        fx.save("rot_%d" % k, src(name, 0.9, semi, 60))
    print("rot:", k)


def hoquet():
    """« Hic ! » : la glotte claque (un clic), une voyelle très brève qui monte, le souffle coupé."""
    for k in range(4):
        L = 0.24
        tt = t(L)
        f0 = RNG.uniform(220, 300)
        f = f0 * (1 + 0.25 * np.clip(tt / 0.05, 0, 1))
        ph = 2 * np.pi * np.cumsum(f) / SR
        # source glottique : une impulsion riche en harmoniques
        src_sig = np.zeros_like(tt)
        for h in range(1, 18):
            src_sig += np.sin(h * ph) / h ** 1.1
        env = (1 - np.exp(-tt / 0.002)) * np.exp(-tt / 0.032)
        v = src_sig * env
        # formants du « i » (environ 300, 2300, 3000 Hz)
        voice = bandpass(v, 240, 420, 2) * 1.0 + bandpass(v, 2000, 2600, 2) * 0.55 + bandpass(v, 2800, 3300, 2) * 0.3
        click = bandpass(RNG.normal(0, 1, len(tt)), 1200, 5000) * np.exp(-tt / 0.004) * 0.5
        x = voice + click
        fade = int(0.03 * SR)
        x[-fade:] *= np.linspace(1, 0, fade)
        fx.save("hoquet_%d" % (k + 1), x / (np.max(np.abs(x)) + 1e-9) * 0.8)
    print("hoquet: 4")


if __name__ == "__main__":
    if not LIB.is_dir():
        print("Donner le chemin du recueil CC0-Public-Domain-Sounds", file=sys.stderr)
        sys.exit(1)
    caisse()
    tonneau()
    panier()
    verrou()
    boire()
    rot()
    hoquet()
