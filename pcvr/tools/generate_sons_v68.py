"""V68 : les sons de l'Île de la Balafre, l'île des pirates, et de son port, Port-Coutelas.

Bruitages (sfx/) :
  coup_poing_1..3       un coup de poing nu qui porte (mâchoire, ventre) : le « pof » de la chair,
                        la gifle de la peau, un souffle d'étoffe ; le 2 fait craquer la mâchoire ;
  ko_1..2               un pirate qui s'effondre, assommé : un « ouf » qui se vide, les genoux,
                        puis tout le corps sur le plancher (1) ou sur la terre battue (2) ;
  foule_bagarre_1..3    deux à trois secondes de foule autour d'une bagarre : « Ouais ! » (1),
                        « Ohhh ! » puis les chopes qui cognent en cadence (2), « Bouuuh ! » (3) ;
                        des sifflets, des chopes d'étain et de bois sur les tables ;
  des_roule_1..2        trois dés secoués dans un gobelet de cuir, jetés sur une table de bois,
                        qui rebondissent, roulent et s'arrêtent en tournoyant ;
  perroquet_1..3        un perroquet : un « RRAAAK ! » rauque (1), un perroquet qui « parle »
                        (« Pièces de huit ! », un babil criard qui imite la voix) (2), un sifflet
                        coquin suivi d'un cri (3) ;
  croco_menace_1        le crocodile du Marais des Noyés : la gueule qui s'ouvre, un sifflement
                        rauque, un grondement de gorge très grave ;
  croco_mort_1          il se débat dans l'eau (gerbes, coups de queue), un long râle qui
                        descend, puis des bulles ;
  squelette_menace_1    des os secs qui s'entrechoquent, une plainte creuse comme dans un crâne,
                        les dents qui claquent ;
  squelette_mort_1      le squelette qui s'effondre en tas : les os qui dégringolent, le crâne
                        qui rebondit et roule ;
  os_choc_1..3          un coup sur de l'os : un claquement sec et creux, les os qui tremblent.
Nappes d'ambiance (ambiance/, boucles sans raccord, stéréo) :
  port_pirate           le port de Port-Coutelas, le jour : les coques et les amarres qui
                        grincent au rythme de la houle, l'eau qui clapote contre le quai, des cris
                        et des rires au loin, un marteau de calfat, les goélands, de temps en temps
                        la cloche d'un navire, une chaîne d'ancre ;
  taverne_pirate        une taverne de pirates bondée : le brouhaha de dizaines de voix graves,
                        des éclats de rire, les chopes qui trinquent et qui cognent sur les tables,
                        une chaise qui racle, le plancher qui craque, le feu de l'âtre, des dés,
                        et, au fond de la salle, une tablée qui entonne une chanson à boire ;
  marais                le Marais des Noyés : grenouilles (coassements, ouaouarons graves,
                        rainettes), insectes, la vase qui bouillonne, le vent dans les roseaux,
                        de temps en temps une lourde gerbe d'eau, un héron au loin.
Synthétisés ici (domaine public), ou retravaillés d'après le recueil CC0
« lavenderdotpet/CC0-Public-Domain-Sounds » (packs Kenney Impact, RPG, Casino et Voiceover,
« 100 CC0 wood/metal SFX », « 100 CC0 SFX » 1 et 2, « 75 CC0 breaking/falling/hit »,
« 40 CC0 water splash/slime », « 25 CC0 mud », « 80 CC0 creature SFX » 1 et 2, beast_or_animal,
« BB Retail Therapy Sample Pack », « bb - Bottle Plops », les voix de Warfork (CC0) et de
« The Motion Monkey Retro Arcade Sounds » (CC0)) : tout est libre de droits.
Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/generate_sons_v68.py [dossier CC0-Public-Domain-Sounds] [noms...]
"""
from pathlib import Path
import sys

import numpy as np
from scipy import signal

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v63 as s63  # noqa: E402
import generate_sons_v59 as s59  # noqa: E402
import generate_sons_v56 as s56  # noqa: E402
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402

SR = 44100
RNG = np.random.default_rng(6868)
s63.RNG = np.random.default_rng(6869)
s59.RNG = np.random.default_rng(6870)
s56.RNG = np.random.default_rng(6871)
amb.RNG = np.random.default_rng(6872)
_t, _norm, _env, _fade, mix, noise, rec, slow = (s63._t, s63._norm, s63._env, s63._fade, s63.mix, s63.noise,
                                                 s63.rec, s63.slow)

ARC = "MMRetroArcadeSoundsPack1_0_5/Vocal/wav/"
KI = "kenney_impactsounds/Audio/"
KR = "kenney_rpgaudio/Audio/"
KC = "kenney_casinoaudio/Audio/"
WM = "100-CC0-wood-metal-SFX/"
SPL = "40-cc0-water-splash-slime-sfx/"
BBR = "BB_Retail Therapy Sample Pack/"
WF = "warfork-cc0/sounds/"


# =================================================================== outils

def trim(x: np.ndarray, thr: float = 0.03, pre: float = 0.004) -> np.ndarray:
    """Retire le silence de tête (seuil relatif à la crête)."""
    if len(x) == 0:
        return x
    pk = np.max(np.abs(x)) + 1e-9
    i = int(np.argmax(np.abs(x) > pk * thr))
    return x[max(0, i - int(pre * SR)):]


def cut(x: np.ndarray, a: float, b: float, fin: float = 0.004, fout: float = 0.05) -> np.ndarray:
    """Un morceau d'enregistrement, de a à b secondes, avec fondus."""
    y = x[int(a * SR):int(b * SR)].copy()
    if len(y) > int((fin + fout) * SR) + 2:
        y = _fade(y, fin, fout)
    return y


def unit(x: np.ndarray) -> np.ndarray:
    return x / (np.max(np.abs(x)) + 1e-9)


def addp(*xs) -> np.ndarray:
    """Somme de sons de longueurs différentes (les plus courts complétés de silence)."""
    n = max(len(x) for x in xs)
    return sum(np.pad(x, (0, n - len(x))) for x in xs)


def clip_rec(rel: str, semi: float = 0.0, max_s: float = 0.0, fout: float = 0.05) -> np.ndarray:
    """Un enregistrement du recueil, silence de tête retiré, borné, normalisé."""
    x = trim(rec(rel, semi))
    if max_s > 0:
        x = x[: int(max_s * SR)]
    return unit(_fade(x, 0.002, min(fout, len(x) / SR / 3)))


def modal(parts, dur: float, attack: float = 0.0004) -> np.ndarray:
    """Synthèse modale : une somme de sinus amortis (fréquence, amplitude, durée de vie)."""
    x = _t(dur)
    y = sum(a * np.sin(2 * np.pi * f * x + RNG.uniform(0, 6)) * np.exp(-x / d) for f, a, d in parts)
    return y * np.clip(x / attack, 0, 1)


def clack(f: float, decay: float = 0.02, bright: float = 1.0, knock: float = 0.3) -> np.ndarray:
    """Un claquement d'os ou de bois sec : des modes inharmoniques très amortis, un souffle d'attaque."""
    parts = [(f, 1.0, decay), (f * 2.37, 0.55 * bright, decay * 0.5), (f * 3.91, 0.3 * bright, decay * 0.3),
             (f * 0.43, knock, decay * 0.8)]
    y = modal(parts, decay * 8 + 0.02)
    m = int(0.0025 * SR)
    y[:m] += amb.bp(RNG.standard_normal(m), 2000, 9000) * np.hanning(m) * 0.6 * bright
    return y


def thump(f0: float = 90.0, f1: float = 45.0, decay: float = 0.07, dur: float = 0.3) -> np.ndarray:
    """Un coup sourd : un sinus grave qui tombe vite, un peu de bruit grave."""
    x = _t(dur)
    f = np.interp(x, [0, 0.06], [f0, f1])
    y = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-x / decay)
    y += amb.lp(RNG.standard_normal(len(x)), 300) * np.exp(-x / (decay * 0.5)) * 0.35
    return y * np.clip(x / 0.0015, 0, 1)


def _res(f: float, bw: float):
    r = np.exp(-np.pi * bw / SR)
    th = 2 * np.pi * f / SR
    return [(1 - r) * np.sqrt(max(1e-9, 1 - 2 * r * np.cos(2 * th) + r * r))], [1.0, -2 * r * np.cos(th), r * r]


def formants(src: np.ndarray, fmts, blk: int = 256) -> np.ndarray:
    """Résonances en parallèle (fréquence, largeur, gain) ; la fréquence peut être un tableau
    qui varie dans le temps (le filtre suit, bloc par bloc)."""
    out = np.zeros(len(src))
    for F, B, g in fmts:
        if np.isscalar(F):
            b, a = _res(float(F), B)
            out += g * signal.lfilter(b, a, src)
            continue
        zi = np.zeros(2)
        y = np.empty(len(src))
        for i in range(0, len(src), blk):
            b, a = _res(float(F[min(len(F) - 1, i + blk // 2)]), B)
            y[i:i + blk], zi = signal.lfilter(b, a, src[i:i + blk], zi=zi)
        out += g * y
    return out


def glottal(f0: np.ndarray, tilt: float = 1.0, fmax: float = 5500.0, jitter: float = 0.0) -> np.ndarray:
    """Une source de voix : des harmoniques qui suivent la hauteur f0 (tableau), pente tilt."""
    n = len(f0)
    if jitter:
        f0 = f0 * (1 + jitter * amb.smooth_env(n, 30.0, -1, 1))
    ph = 2 * np.pi * np.cumsum(f0) / SR + RNG.uniform(0, 6)
    y = np.zeros(n)
    kmax = int(fmax / max(float(np.min(f0)), 40.0))
    for k in range(1, kmax + 1):
        w = np.clip((fmax - k * f0) / (0.25 * fmax), 0, 1)
        if not w.any():
            break
        y += np.sin(k * ph) * w / k ** tilt
    return y


# voyelles (formants d'une voix d'homme : fréquence, largeur, gain)
VOW = {
    "a": [(750, 90, 1.0), (1250, 110, 0.55), (2600, 160, 0.3), (3400, 250, 0.15)],
    "è": [(550, 80, 1.0), (1800, 120, 0.5), (2550, 160, 0.35), (3500, 250, 0.15)],
    "é": [(400, 70, 1.0), (2000, 120, 0.4), (2700, 160, 0.3)],
    "i": [(300, 60, 1.0), (2250, 120, 0.35), (3000, 200, 0.3)],
    "o": [(480, 70, 1.0), (880, 90, 0.55), (2500, 160, 0.18)],
    "ou": [(320, 60, 1.0), (780, 90, 0.4), (2300, 160, 0.12)],
    "eu": [(450, 70, 1.0), (1350, 110, 0.4), (2400, 160, 0.2)],
}


def _vow(v: str, scale: float = 1.0):
    return [(f * scale, b * scale, g) for f, b, g in VOW[v]]


def shout(dur: float, f0: float, v1: str, v2: str | None = None, at: float = 0.12, shape: str = "cheer",
          breath: float = 0.25, scale: float = 1.0, att: float = 0.08, rel: float = 0.35) -> np.ndarray:
    """Une voix qui crie (« Ouais ! », « Ohhh ! », « Bouuuh ! ») : source voisée, souffle,
    formants (qui glissent de v1 à v2), contour de hauteur selon l'intention."""
    n = int(dur * SR)
    x = np.arange(n) / SR
    u = x / dur
    if shape == "cheer":
        c = np.interp(u, [0, 0.15, 0.5, 1.0], [0.85, 1.12, 1.05, 0.8])
    elif shape == "oh":
        c = np.interp(u, [0, 0.35, 1.0], [0.92, 1.2, 0.72])
    elif shape == "boo":
        c = np.interp(u, [0, 0.2, 1.0], [1.0, 1.04, 0.8])
    elif shape == "chant":
        c = np.ones(n)
    else:
        c = np.interp(u, [0, 1.0], [1.0, 0.85])
    f = f0 * c * (1 + 0.012 * np.sin(2 * np.pi * RNG.uniform(4.5, 6.5) * x + RNG.uniform(0, 6)))
    src = glottal(f, tilt=0.9, jitter=0.015)
    src = src / (np.std(src) + 1e-9)
    src += amb.hp(RNG.standard_normal(n), 400) * breath
    y = formants(src, _vow(v1, scale))
    if v2:
        y2 = formants(src, _vow(v2, scale))
        w = np.clip((x - at) / 0.12, 0, 1)
        y = y * (1 - w) + y2 * w
    env = np.clip(x / att, 0, 1) * np.clip((dur - x) / rel, 0, 1) ** 1.3
    env *= 1 + 0.15 * amb.smooth_env(n, 6.0, -1, 1)
    return y * env


def whistle(kind: int = 0) -> np.ndarray:
    """Un sifflet entre deux doigts : « fuuiiit-fiouuu » (0), long et perçant (1), court (2)."""
    if kind == 0:
        segs = [(0.26, [1900, 3150, 3050]), (0.07, None), (0.48, [3100, 2600, 1750])]
    elif kind == 1:
        segs = [(0.75, [2900, 3350, 3400, 3250])]
    else:
        segs = [(0.22, [2600, 3300, 3200])]
    out = []
    for d, fs in segs:
        n = int(d * SR)
        if fs is None:
            out.append(np.zeros(n))
            continue
        x = np.arange(n) / SR
        f = np.interp(x, np.linspace(0, d, len(fs)), fs) * (1 + 0.006 * np.sin(2 * np.pi * 9 * x))
        ph = 2 * np.pi * np.cumsum(f) / SR
        y = np.sin(ph) + 0.06 * np.sin(2 * ph)
        y += amb.bp(RNG.standard_normal(n), 1800, 4200) * 0.12
        y *= np.clip(x / 0.03, 0, 1) * np.clip((d - x) / 0.06, 0, 1)
        out.append(y)
    return np.concatenate(out)


def wplace(buf: np.ndarray, ev: np.ndarray, at: float, gain: float = 1.0, pan: float = 0.0) -> None:
    """Pose un son dans une boucle : ce qui dépasse la fin repart au début (raccord parfait)."""
    n = len(buf)
    i = int(at) % n
    ev = ev[:n]
    k = n - i
    amb.place(buf, ev[:k], i, gain, pan)
    if len(ev) > k:
        amb.place(buf, ev[k:], 0, gain, pan)


def room_wrap(x: np.ndarray, seconds: float, decay: float, lp_hz: float, wet: float, seed: int = 1) -> np.ndarray:
    """Réverbération d'une boucle : la queue est repliée au début (comme dans orchestre_v51)."""
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    t = np.arange(n) / SR
    chans = [x] if x.ndim == 1 else [x[:, 0], x[:, 1]]
    out = []
    for c in chans:
        ir = rng.standard_normal(n) * np.exp(-t * decay)
        ir = amb.lp(ir, lp_hz, order=4)
        ir *= np.clip((n - np.arange(n)) / (0.35 * n), 0, 1) ** 2
        ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
        y = signal.fftconvolve(c, ir)
        body = y[: len(c)].copy()
        rest = y[len(c):]
        k = 0
        while k < len(rest):
            m = min(len(c), len(rest) - k)
            body[:m] += rest[k:k + m]
            k += m
        out.append(c * (1 - wet) + body * wet * 2.5)
    return out[0] if x.ndim == 1 else np.stack(out, axis=1)


def scatter(out: np.ndarray, clips: list, per_min: float, gain_r, semis=(0.0, 0.0), lp_hz: float = 0.0,
            pan_r=(-0.9, 0.9), weight=None) -> None:
    """Répartit des sons dans la boucle, à peu près régulièrement (une case par son, un instant au
    hasard dans la case : pas d'attroupement, pas de trou)."""
    clips = [c for c in clips if len(c) > 0]
    if not clips:
        return
    n = len(out)
    count = max(1, int(round(n / SR / 60.0 * per_min)))
    slot = n / count
    for i in range(count):
        at = (i + RNG.uniform(0.05, 0.95)) * slot
        if weight is not None and RNG.random() > weight(at / SR):
            continue
        c = clips[RNG.integers(0, len(clips))]
        if semis != (0.0, 0.0):
            c = s56._shift(c, RNG.uniform(*semis))
        if lp_hz > 0:
            c = amb.lp(c, lp_hz * RNG.uniform(0.85, 1.15))
        wplace(out, c, at, RNG.uniform(*gain_r), RNG.uniform(*pan_r))


def loop_layer(fn, seconds: float, fade: float = 2.5) -> np.ndarray:
    """Une couche continue (vent, eau…) rendue un peu plus longue puis bouclée en fondu
    (longueur finale : exactement celle de la boucle)."""
    return amb.loopify(fn(int(seconds * SR) + int(fade * SR)), fade)


def hp_loop(x: np.ndarray, fc: float = 32.0) -> np.ndarray:
    """Coupe l'infra-grave d'une boucle (filtre amorcé avec la fin de la boucle : pas de raccord)."""
    k = min(len(x) // 2, SR)
    ext = np.concatenate([x[-k:], x])
    return signal.sosfilt(signal.butter(2, fc, btype="highpass", fs=SR, output="sos"), ext, axis=0)[k:]


def finish_bed(x: np.ndarray, ceil: float = 0.7) -> np.ndarray:
    """Fin d'une nappe : sans infra-grave, crêtes adoucies (plafond relatif à la crête)."""
    x = hp_loop(x)
    return soft_limit(x, np.max(np.abs(x)) * ceil)


def soft_limit(x: np.ndarray, ceil: float) -> np.ndarray:
    """Écrête en douceur (tanh) ce qui dépasse le plafond : quelques pointes ne dictent plus le niveau."""
    k = ceil * 0.75
    a = np.abs(x)
    return np.where(a > k, np.sign(x) * (k + (ceil - k) * np.tanh((a - k) / (ceil - k))), x)


# =================================================================== la bagarre

def coup_poing(k: int) -> np.ndarray:
    """Un poing nu qui porte : le « pof » de la chair, la gifle de la peau, un souffle d'étoffe ;
    la variante 2 fait craquer la mâchoire, la 3 frappe au ventre (plus sourd)."""
    base = clip_rec(KI + "impactPunch_heavy_00%d.ogg" % [0, 2, 4][k], [-1.0, 0.0, -3.0][k], 0.45)
    th = thump([100.0, 115.0, 80.0][k], [48.0, 55.0, 40.0][k], [0.06, 0.05, 0.09][k], 0.35)
    m = int(0.07 * SR)
    xs = np.arange(m) / SR
    slap = amb.bp(RNG.standard_normal(m), 900, 5200) * np.exp(-xs / [0.008, 0.007, 0.005][k])
    slap += amb.bp(RNG.standard_normal(m), 250, 900) * np.exp(-xs / 0.02) * 0.7
    cloth = s63.whoosh(0.09, 1300.0, 3200.0, 0.5) * 0.12
    parts = [(cloth, 0.0, 1.0), (base, 0.03, 1.0), (th, 0.03, [0.8, 0.7, 1.1][k]), (unit(slap), 0.03, [0.55, 0.6, 0.3][k])]
    if k == 1:
        jaw = clack(1650.0, 0.012, 1.1, 0.2)
        parts.append((unit(jaw), 0.036, 0.22))
    if k == 2:
        # le ventre : un souffle chassé des poumons
        air = amb.bp(noise(0.25), 300, 1800) * _env(int(0.25 * SR), 0.01, 0.07)
        parts.append((unit(air), 0.05, 0.18))
    out = mix(0.6, *parts)
    out = s56._room(out, 0.35, 10.0, 4500.0, 0.1, seed=681 + k)
    return _norm(_fade(out, 0.001, 0.08), 0.89)


def ko(k: int) -> np.ndarray:
    """Un pirate assommé qui s'effondre : un « ouf » qui se vide, les genoux, puis tout le corps
    sur le plancher (1, les planches résonnent) ou sur la terre battue (2)."""
    dur = 2.4
    if k == 0:
        v = amb.lp(clip_rec(ARC + "Hit11.wav", -2.5, 0.6), 3200)
        sigh = amb.lp(clip_rec("80-CC0-creature-SFX/ooh.ogg", -6.0, 0.6), 1400)
        knees = clip_rec(KI + "impactWood_medium_002.ogg", -2.0, 0.3)
        body = [clip_rec(KI + "impactSoft_heavy_000.ogg", -3.0), clip_rec(KI + "impactWood_heavy_002.ogg", -2.0),
                clip_rec(KI + "impactPlank_medium_001.ogg", -1.0, 0.6)]
        bounce = clip_rec(KI + "impactWood_light_003.ogg", 0.0, 0.2)
        creak = amb.lp(clip_rec(KR + "creak3.ogg", -4.0), 1800)
        parts = [(v, 0.0, 0.75), (knees, 0.36, 0.45), (body[0], 0.6, 1.0), (body[1], 0.6, 0.6), (body[2], 0.61, 0.45),
                 (thump(70.0, 38.0, 0.12, 0.5), 0.6, 0.8), (bounce, 0.78, 0.22), (creak, 0.95, 0.12), (sigh, 1.35, 0.32)]
    else:
        v = amb.lp(clip_rec(WF + "players/male/death.ogg", -3.5, 1.0), 3000)
        knees = clip_rec(KI + "impactSoft_medium_001.ogg", -2.0, 0.2)
        body = [clip_rec(KI + "impactSoft_heavy_003.ogg", -4.0), clip_rec("75-cc0-breaking-falling-hit-sfx/bfh1_hit_02.ogg", -3.0)]
        dirt = amb.lp(clip_rec("25-CC0-mud-sfx/mud_06.ogg", -7.0), 2200)
        m = int(0.6 * SR)
        dust = amb.bp(RNG.standard_normal(m), 1500, 6000) * _env(m, 0.02, 0.18)
        breath = amb.lp(clip_rec(WF + "players/male/gasp.ogg", -4.0, 1.2), 1600)
        parts = [(v, 0.0, 0.7), (knees, 0.42, 0.5), (body[0], 0.68, 1.0), (body[1], 0.68, 0.7),
                 (thump(62.0, 35.0, 0.11, 0.5), 0.68, 0.9), (dirt, 0.7, 0.3), (unit(dust), 0.7, 0.1), (breath, 1.3, 0.18)]
    out = mix(dur, *parts)
    out = s56._room(out, 0.6, 7.0, 3500.0, 0.14, seed=684 + k)
    return _norm(_fade(out, 0.001, 0.3), 0.89)


SHOUTS = [ARC + "Attack%d.wav" % i for i in (1, 2, 3, 4, 5, 6, 7, 8)] + [WF + "vsay/yeehaa.ogg", ARC + "Hit3.wav"]


def _shouts(n: int, t0: float, t1: float, semis=(-5.0, 1.0)) -> list:
    out = []
    for _ in range(n):
        c = clip_rec(SHOUTS[RNG.integers(0, len(SHOUTS))], RNG.uniform(*semis), 0.9, 0.15)
        out.append((amb.lp(c, RNG.uniform(2400, 3600)), RNG.uniform(t0, t1), RNG.uniform(0.18, 0.4)))
    return out


def _bang(clink: bool = False) -> np.ndarray:
    """Une chope qui cogne sur une table de bois (et parfois l'étain qui tinte)."""
    srcs = ["100-cc0-sfx-2/sfx100v2_wood_hit_01.ogg", "100-cc0-sfx-2/sfx100v2_wood_hit_02.ogg", WM + "wood_hit_08.ogg",
            WM + "wood_hit_09.ogg", KI + "impactWood_heavy_001.ogg", KI + "impactWood_medium_003.ogg"]
    y = clip_rec(srcs[RNG.integers(0, len(srcs))], RNG.uniform(-3.0, 1.0), 0.35) * 0.9
    y = addp(y, thump(110.0, 70.0, 0.04, 0.2) * 0.4)
    if clink:
        c = clip_rec(KR + "metalPot%d.ogg" % RNG.integers(1, 4), RNG.uniform(2.0, 6.0), 0.4, 0.2)
        c = amb.lp(c, 5000) * 0.35
        y = addp(y, c)
    return y


def foule_bagarre(k: int) -> np.ndarray:
    """La foule autour d'une bagarre : « Ouais ! » (1) ; « Ohhh ! » puis les chopes en cadence (2) ;
    « Bouuuh ! » (3)."""
    dur = 3.0
    parts = []
    if k == 0:
        for _ in range(20):
            fem = RNG.random() < 0.15
            v = shout(RNG.uniform(0.9, 1.7), RNG.uniform(260, 340) if fem else RNG.uniform(120, 210),
                      "ou", "è" if RNG.random() < 0.6 else "a", at=RNG.uniform(0.06, 0.14), scale=1.15 if fem else 1.0)
            parts.append((unit(v), RNG.uniform(0.0, 0.35), RNG.uniform(0.08, 0.18)))
        for _ in range(8):
            v = shout(RNG.uniform(0.8, 1.3), RNG.uniform(130, 220), "a", rel=0.5)
            parts.append((unit(v), RNG.uniform(0.9, 1.4), RNG.uniform(0.05, 0.12)))
        parts += _shouts(7, 0.0, 0.7)
        parts.append((whistle(0), 0.45, 0.22))
        for t in (0.15, 0.42, 0.66, 0.9, 1.25):
            parts.append((_bang(RNG.random() < 0.4), t + RNG.uniform(-0.03, 0.03), RNG.uniform(0.25, 0.4)))
    elif k == 1:
        for _ in range(18):
            v = shout(RNG.uniform(0.75, 1.1), RNG.uniform(115, 200), "o", shape="oh", att=0.05, rel=0.4)
            parts.append((unit(v), RNG.uniform(0.0, 0.12), RNG.uniform(0.08, 0.16)))
        # quelques vraies voix dans le « Ohhh ! »
        ooh = rec(BBR + "Hey Ooooh.wav")
        for semi in (-4.0, -1.5, 1.5):
            c = amb.lp(cut(s56._shift(ooh, semi), 0.8, 1.9, 0.08, 0.35), 3000)
            parts.append((unit(c), RNG.uniform(0.0, 0.08), 0.2))
        for semi in (-5.0, -2.0):
            parts.append((amb.lp(clip_rec("80-CC0-creature-SFX/ooh.ogg", semi, 0.5, 0.15), 3000), RNG.uniform(0.0, 0.1), 0.18))
        for _ in range(12):
            v = shout(RNG.uniform(0.9, 1.5), RNG.uniform(130, 210), "ou", "è", at=0.1)
            parts.append((unit(v), RNG.uniform(1.0, 1.4), RNG.uniform(0.06, 0.13)))
        parts += _shouts(4, 1.0, 1.6)
        parts.append((whistle(2), 1.3, 0.2))
        for beat in range(5):
            for _ in range(3):
                parts.append((_bang(RNG.random() < 0.3), 1.0 + beat * 0.34 + RNG.uniform(-0.025, 0.025), RNG.uniform(0.18, 0.32)))
    else:
        for _ in range(16):
            v = shout(RNG.uniform(1.4, 2.2), RNG.uniform(100, 170), "ou", shape="boo", att=0.15, rel=0.6, breath=0.35)
            parts.append((unit(v), RNG.uniform(0.0, 0.4), RNG.uniform(0.08, 0.15)))
        for rel_, semi in [(WF + "vsay/booo.ogg", -2.0), (WF + "vsay/booo.ogg", 1.5), (WF + "vsay/vsay Boo.wav", -3.5),
                           (WF + "vsay/vsay Boo.wav", 0.5)]:
            c = amb.lp(clip_rec(rel_, semi + RNG.uniform(-0.5, 0.5), 1.8, 0.4), 2800)
            parts.append((c, RNG.uniform(0.0, 0.3), RNG.uniform(0.2, 0.32)))
        parts += _shouts(2, 1.2, 1.8, semis=(-6.0, -2.0))
        parts.append((whistle(1), 0.7, 0.2))
        parts.append((_bang(False), 1.55, 0.3))
    out = mix(dur + 0.6, *parts)
    out = amb.lp(out, 5500)
    out = s56._room(out, 0.9, 4.5, 3500.0, 0.22, seed=686 + k)
    out = out[: int((dur + 0.4) * SR)]
    return _norm(_fade(out, 0.002, 0.6), 0.89)


# =================================================================== les dés

def _die_bounces(t0: float, f: float, g: float, n: int, gap: float, ratio: float) -> list:
    """Un dé qui rebondit : des chocs de plus en plus rapprochés et faibles, puis il tournoie."""
    ev = []
    t = t0
    for i in range(n):
        c = clack(f * RNG.uniform(0.9, 1.1), RNG.uniform(0.006, 0.012), 1.0, 0.0)
        knock = modal([(RNG.uniform(240, 420), 1.0, 0.025), (RNG.uniform(700, 900), 0.4, 0.012)], 0.12)
        ev.append((addp(c * 0.8, knock * 0.5 * (1.0 if i < 3 else 0.5)), t, g * 0.72 ** i))
        t += gap * ratio ** i
    # il tournoie sur une arête avant de se poser
    p = 0.05
    gg = g * 0.72 ** n
    while p > 0.012 and gg > 0.01:
        ev.append((clack(f * 1.2, 0.004, 0.8, 0.0), t, gg))
        t += p
        p *= 0.8
        gg *= 0.9
    return ev


def des_roule(k: int) -> np.ndarray:
    """Trois dés dans un gobelet de cuir, secoués, jetés sur une table de bois."""
    dur = 2.1
    sh = trim(rec(KC + "dieShuffle%d.ogg" % (k + 1)))[: int(0.95 * SR)]
    sh = _fade(sh, 0.005, 0.12)
    cup = amb.lp(sh, 2600) * 0.55 + formants(sh, [(950, 260, 1.0), (1750, 420, 0.5)]) * 1.4
    parts = [(unit(cup), 0.0, 0.55)]
    # la paume et le gobelet : de petits coups sourds à chaque aller-retour
    for i in range(6):
        parts.append((unit(thump(260.0, 180.0, 0.018, 0.08)), 0.04 + i * 0.152 + RNG.uniform(-0.01, 0.01), 0.22))
    t1 = 1.02
    parts.append((s63.whoosh(0.12, 900.0, 2400.0, 0.5) * 0.25, t1 - 0.1, 1.0))
    parts.append((clip_rec(KC + ["diceThrow2.ogg", "diceThrow3.ogg"][k]), t1, 0.7))
    parts.append((clip_rec(KC + ["dieThrow3.ogg", "dieThrow1.ogg"][k]), t1 + 0.09, 0.5))
    for d in range(3):
        parts += _die_bounces(t1 + 0.03 + d * RNG.uniform(0.02, 0.07), RNG.uniform(2600, 4200), 0.5,
                              RNG.integers(4, 7), RNG.uniform(0.08, 0.13), RNG.uniform(0.58, 0.7))
    out = mix(dur, *parts)
    out = s56._room(out, 0.5, 7.0, 6000.0, 0.12, seed=690 + k)
    return _norm(_fade(out, 0.002, 0.2), 0.89)


# =================================================================== le perroquet

def squawk(dur: float, fp, am: float = 110.0, depth: float = 0.7, sub: float = 0.3, noise_g: float = 0.45,
           tp=None, rasp: float = 0.06) -> np.ndarray:
    """Un cri de perroquet : une voix aiguë très riche, rauque (hauteur qui grésille, modulée,
    sous-harmonique), saturée, passée dans les résonances du bec."""
    n = int(dur * SR)
    x = np.arange(n) / SR
    tp = np.linspace(0, dur, len(fp)) if tp is None else np.array(tp) * dur
    fm = amb.bp(RNG.standard_normal(n), 60, 450)
    fm /= np.std(fm) + 1e-9
    f0 = np.interp(x, tp, fp) * (1 + 0.03 * amb.smooth_env(n, 40.0, -1, 1) + rasp * fm)
    ph = 2 * np.pi * np.cumsum(f0) / SR
    y = np.zeros(n)
    for k in range(1, int(9000 / min(fp)) + 1):
        y += np.sin(k * ph + RNG.uniform(0, 6)) * np.clip((9000 - k * f0) / 2000, 0, 1) / k ** 0.55
    y += sub * np.sin(0.5 * ph) * (2 + np.sin(ph))
    y *= (1 - depth) + depth * (0.5 + 0.5 * np.sin(2 * np.pi * am * x + 3 * amb.smooth_env(n, 15.0, -1, 1)))
    y = np.tanh(2.2 * y / (np.max(np.abs(y)) + 1e-9))
    y = 0.35 * y + formants(y, [(2300, 900, 1.0), (3800, 1200, 0.6), (1250, 500, 0.5)])
    y = y / (np.std(y) + 1e-9) * 0.3
    y += amb.bp(RNG.standard_normal(n), 1800, 7000) * noise_g * 0.3 * (0.6 + 0.4 * amb.smooth_env(n, 30.0, 0, 1))
    env = np.clip(x / 0.012, 0, 1) * np.clip((dur - x) / (0.3 * dur), 0, 1) ** 1.3
    return y * env


def parrot_talk(sylls) -> np.ndarray:
    """Un perroquet qui « parle » : des syllabes (consonne de bruit, voyelle dont les formants
    glissent), une voix aiguë et grinçante, l'intonation d'une phrase."""
    out = []
    for cons, v1, v2, d, f_a, f_b in sylls:
        if cons == "s":
            m = int(0.09 * SR)
            out.append(amb.bp(RNG.standard_normal(m), 4500, 9500) * np.hanning(m) * 0.5)
        elif cons in ("p", "d", "t", "k"):
            m = int(0.018 * SR)
            lo = {"p": 600, "d": 1500, "t": 3000, "k": 1800}[cons]
            out.append(np.zeros(int(0.03 * SR)))
            out.append(amb.bp(RNG.standard_normal(m), lo, lo * 3) * np.hanning(m) * 0.7)
        elif cons == "_":
            out.append(np.zeros(int(0.07 * SR)))
        if v1 is None:
            continue
        n = int(d * SR)
        x = np.arange(n) / SR
        f0 = np.interp(x, [0, d], [f_a, f_b]) * (1 + 0.04 * amb.smooth_env(n, 30.0, -1, 1))
        src = glottal(f0, tilt=0.7, fmax=8000.0)
        src *= 0.55 + 0.45 * (0.5 + 0.5 * np.sin(2 * np.pi * RNG.uniform(70, 95) * x))
        src = np.tanh(1.5 * src / (np.max(np.abs(src)) + 1e-9))
        a, b = VOW[v1], VOW[v2 or v1]
        w = np.clip(x / max(d * 0.7, 1e-3), 0, 1)
        fm = [((a[i][0] + (b[i][0] - a[i][0]) * w) * 1.3, a[i][1] * 2.2, a[i][2]) for i in range(3)]
        y = formants(src, fm) + src * 0.12
        y += amb.bp(RNG.standard_normal(n), 2500, 7000) * 0.12
        y *= np.clip(x / 0.012, 0, 1) * np.clip((d - x) / 0.03, 0, 1)
        out.append(unit(y))
    return np.concatenate(out)


def perroquet(k: int) -> np.ndarray:
    """Un perroquet : « RRAAAK ! » (1), « Pièces de huit ! » (2), un sifflet coquin et un cri (3)."""
    if k == 0:
        a = squawk(0.42, [720, 980, 930, 640], am=115.0, depth=0.75, tp=[0, 0.18, 0.55, 1.0])
        b = squawk(0.3, [820, 1050, 700], am=130.0, depth=0.8)
        out = mix(1.1, (unit(a), 0.0, 1.0), (unit(b), 0.55, 0.8))
    elif k == 1:
        talk = parrot_talk([
            ("p", "i", "è", 0.15, 980, 1120), ("s", None, None, 0, 0, 0), ("d", "eu", None, 0.09, 1050, 990),
            ("_", None, None, 0, 0, 0), (None, "i", "i", 0.2, 1250, 1500), ("t", None, None, 0, 0, 0)])
        rawk = squawk(0.28, [800, 1000, 760], am=120.0, depth=0.7)
        out = mix(1.6, (unit(talk), 0.0, 0.85), (unit(rawk), 0.95, 0.9))
    else:
        w = []
        for d, fs in [(0.2, [1500, 2600]), (0.06, None), (0.42, [2700, 2300, 1500])]:
            n = int(d * SR)
            if fs is None:
                w.append(np.zeros(n))
                continue
            x = np.arange(n) / SR
            f = np.interp(x, np.linspace(0, d, len(fs)), fs)
            ph = 2 * np.pi * np.cumsum(f) / SR
            y = (np.sin(ph) + 0.25 * np.sin(2 * ph) + 0.1 * np.sin(3 * ph)) * (0.85 + 0.15 * np.sin(2 * np.pi * 60 * x))
            w.append(y * np.clip(x / 0.02, 0, 1) * np.clip((d - x) / 0.05, 0, 1))
        rawk = squawk(0.26, [900, 1100, 820], am=125.0, depth=0.75)
        out = mix(1.3, (np.concatenate(w), 0.0, 0.7), (unit(rawk), 0.85, 1.0))
    out = s56._room(out, 0.5, 6.0, 7000.0, 0.12, seed=692 + k)
    return _norm(_fade(out, 0.001, 0.15), 0.85)


# =================================================================== le crocodile

def croco_menace() -> np.ndarray:
    """La gueule qui s'ouvre (un clappement humide), un sifflement rauque et grave, un grondement
    de gorge qui fait vibrer le sol."""
    dur = 2.6
    wet = amb.lp(clip_rec(SPL + "slime_04.ogg", -5.0, 0.35), 2500)
    x = _t(2.1)
    hiss = amb.bp(noise(2.1), 600, 5500) + amb.bp(noise(2.1), 250, 1200) * 0.6
    hiss *= np.clip(x / 0.18, 0, 1) * np.clip((2.1 - x) / 0.7, 0, 1) * (1 + 0.3 * amb.smooth_env(len(x), 16.0, -1, 1))
    g1 = amb.lp(slow(rec("beast_or_animal/Growl.wav"), 1.7), 900)[: int(2.3 * SR)]
    g2 = amb.lp(slow(rec("beast_or_animal/Growl 1.wav"), 1.45), 1200)[: int(2.1 * SR)]
    # l'infra-grave : des impulsions de gorge (≈ 24 par seconde) dans un sinus très bas
    rm = np.zeros(int(2.3 * SR))
    t = 0.0
    while t < 2.1:
        amb.place(rm, modal([(RNG.uniform(42, 50), 1.0, 0.03)], 0.12), int(t * SR), RNG.uniform(0.6, 1.0))
        t += 1 / 24.0 * RNG.uniform(0.85, 1.15)
    rm *= np.clip(_t(2.3) / 0.4, 0, 1) * np.clip((2.3 - _t(2.3)) / 0.6, 0, 1)
    out = mix(dur, (wet, 0.0, 0.35), (unit(hiss), 0.05, 0.5), (_fade(unit(g1), 0.15, 0.6), 0.2, 0.9),
              (_fade(unit(g2), 0.2, 0.6), 0.35, 0.45), (unit(rm), 0.2, 0.55))
    out = s56._room(out, 0.8, 5.0, 3500.0, 0.15, seed=695)
    return _norm(_fade(out, 0.001, 0.3), 0.9)


def croco_mort() -> np.ndarray:
    """Il se débat : des gerbes d'eau et des coups de queue, un râle qui descend, puis des bulles."""
    dur = 3.2
    parts = []
    for rel_, semi, t, g in [("splash_11.ogg", -4.0, 0.0, 1.0), ("splash_13.ogg", -5.0, 0.2, 0.7), ("splash_14.ogg", -3.0, 0.45, 0.65),
                             ("splash_15.ogg", -4.0, 0.7, 0.5), ("splash_08.ogg", -6.0, 0.95, 0.45), ("splash_05.ogg", -3.0, 1.2, 0.3)]:
        parts.append((clip_rec(SPL + rel_, semi, 1.2, 0.3), t, g))
    for t, g in [(0.02, 0.8), (0.47, 0.6), (0.96, 0.4)]:
        parts.append((unit(thump(75.0, 40.0, 0.08, 0.4)), t, g))
    groan = amb.lp(slow(rec("beast_or_animal/Growl 2.wav"), 2.0), 700)[: int(2.4 * SR)]
    groan = _fade(unit(groan), 0.2, 1.2) * np.interp(np.arange(len(groan)) / SR, [0, 0.8, 2.4], [1.0, 0.8, 0.2])
    x = _t(2.2)
    bel = glottal(np.interp(x, [0, 2.2], [68.0, 36.0]), tilt=1.2, fmax=1200.0)
    bel = formants(bel, [(320, 90, 1.0), (680, 120, 0.4)]) * np.clip(x / 0.3, 0, 1) * np.clip((2.2 - x) / 1.0, 0, 1)
    parts += [(groan, 0.15, 0.8), (unit(bel), 0.25, 0.5)]
    for t in (1.9, 2.15, 2.3, 2.55):
        parts.append((amb.lp(clip_rec(SPL + "bubble_0%d.ogg" % RNG.integers(1, 3), RNG.uniform(-8.0, -5.0)), 1500), t, RNG.uniform(0.15, 0.3)))
    out = mix(dur, *parts)
    out = s56._room(out, 0.9, 4.5, 3000.0, 0.15, seed=696)
    return _norm(_fade(out, 0.001, 0.4), 0.9)


# =================================================================== le squelette

def bone_rattle(dur: float, rate: float = 22.0, spread=(900.0, 2600.0), env=None) -> np.ndarray:
    """Des os secs qui s'entrechoquent : des secousses de deux ou trois claquements à la fois."""
    out = np.zeros(int((dur + 0.3) * SR))
    t = 0.0
    while t < dur:
        g = 1.0 if env is None else float(env(t))
        for _ in range(RNG.integers(1, 4)):
            c = clack(RNG.uniform(*spread), RNG.uniform(0.008, 0.025), RNG.uniform(0.6, 1.2), RNG.uniform(0.1, 0.4))
            amb.place(out, c, int((t + RNG.uniform(0, 0.012)) * SR), g * RNG.uniform(0.4, 1.0))
        t += 1.0 / rate * RNG.uniform(0.6, 1.4)
    return out


def hollow_moan(dur: float, f0: float = 120.0, shape=(0.9, 1.12, 1.0, 0.8)) -> np.ndarray:
    """Une plainte creuse, soufflée, « ouuuh », qui résonne comme dans un crâne vide."""
    n = int(dur * SR)
    x = np.arange(n) / SR
    f = f0 * np.interp(x / dur, [0, 0.3, 0.7, 1.0], shape) * (1 + 0.02 * np.sin(2 * np.pi * 4.5 * x))
    src = glottal(f, tilt=1.6, fmax=3000.0)
    src = src / (np.std(src) + 1e-9) * 0.5 + amb.bp(RNG.standard_normal(n), 200, 3000) * 0.9
    y = formants(src, _vow("ou"))
    d = int(SR / 185.0)
    a = np.zeros(d + 1)
    a[0], a[d] = 1.0, -0.6
    y = signal.lfilter([1.0], a, y)
    return y * np.clip(x / 0.35, 0, 1) * np.clip((dur - x) / 0.5, 0, 1)


def squelette_menace() -> np.ndarray:
    """Le squelette qui se dresse : les os qui claquent, une plainte creuse, les dents qui claquent."""
    dur = 2.6
    r = bone_rattle(2.0, 24.0, env=lambda t: np.interp(t, [0, 0.3, 1.2, 2.0], [0.4, 1.0, 0.7, 0.2]))
    moan = hollow_moan(1.9, 118.0)
    chatter = np.zeros(int(0.7 * SR))
    for i in range(9):
        amb.place(chatter, clack(RNG.uniform(2700, 3200), 0.006, 1.2, 0.05), int(i / 13.0 * SR), 1.0 - i * 0.06)
    rt = [clip_rec(BBR + "Rattle %d.wav" % i, 2.0, 0.35) for i in (1, 2, 3)]
    out = mix(dur, (unit(r), 0.0, 0.7), (unit(moan), 0.1, 0.6), (unit(chatter), 1.35, 0.4), (rt[0], 0.05, 0.25), (rt[2], 0.7, 0.2))
    out = s56._room(out, 1.4, 3.0, 4000.0, 0.28, seed=697)
    return _norm(_fade(out, 0.001, 0.3), 0.88)


def squelette_mort() -> np.ndarray:
    """Le squelette s'effondre en tas : un os qui casse, les os qui dégringolent, les grosses pièces
    qui tombent, le crâne qui rebondit et roule, puis le silence."""
    dur = 3.0
    parts = [(clip_rec(WM + "wood_cracking_02.ogg", -3.0, 0.25), 0.0, 0.6), (unit(hollow_moan(0.9, 100.0, (1.0, 1.05, 0.85, 0.6))), 0.0, 0.35)]
    tumble = clip_rec(BBR + "Tiny Wooden Dummy Tumbles Down Staircase.wav", -2.0)
    parts.append((_fade(tumble[: int(1.5 * SR)], 0.002, 0.5), 0.12, 0.45))
    for i in range(36):
        t = 0.1 + RNG.exponential(0.32)
        if t > 1.5:
            continue
        g = 0.85 * np.exp(-(t - 0.1) / 0.6) * RNG.uniform(0.4, 1.0)
        parts.append((clack(RNG.uniform(800, 2800), RNG.uniform(0.008, 0.03), RNG.uniform(0.7, 1.2), RNG.uniform(0.1, 0.5)), t, g))
    for t, f in [(0.22, 420.0), (0.31, 520.0), (0.45, 360.0), (0.6, 480.0)]:
        parts.append((clack(f, 0.04, 0.6, 0.6), t, 0.55))
        parts.append((unit(thump(140.0, 90.0, 0.03, 0.15)), t, 0.3))
    t = 0.62
    gap = 0.24
    g = 0.7
    for i in range(7):
        parts.append((clack(560.0 * RNG.uniform(0.97, 1.03), 0.035, 0.7, 0.5), t, g))
        t += gap
        gap *= 0.68
        g *= 0.75
    while t < 1.9:
        parts.append((clack(RNG.uniform(1300, 1700), 0.006, 0.8, 0.1), t, 0.05))
        t += RNG.uniform(0.025, 0.04)
    for t in (2.05, 2.25):
        parts.append((clack(RNG.uniform(1800, 2600), 0.01, 1.0, 0.1), t, 0.08))
    out = mix(dur, *parts)
    out = s56._room(out, 1.2, 3.5, 4000.0, 0.25, seed=698)
    return _norm(_fade(out, 0.001, 0.3), 0.88)


def os_choc(k: int) -> np.ndarray:
    """Un coup sur de l'os : un claquement sec et creux, un peu de corps, les os qui tremblent après."""
    base = clip_rec(WM + ["wood_hit_01.ogg", "wood_hit_03.ogg", "wood_hit_06.ogg"][k], [2.0, 0.0, 1.0][k], 0.3)
    c = clack([1500.0, 1250.0, 1750.0][k], 0.018, 1.0, 0.5)
    parts = [(base, 0.0, 0.7), (unit(c), 0.0, 0.8), (unit(thump(220.0, 150.0, 0.015, 0.1)), 0.0, 0.35)]
    for i in range(RNG.integers(2, 4)):
        parts.append((clack(RNG.uniform(1400, 2600), 0.008, 0.9, 0.1), 0.06 + i * RNG.uniform(0.03, 0.05), 0.15 / (i + 1)))
    out = mix(0.42, *parts)
    out = s56._room(out, 0.4, 10.0, 5000.0, 0.08, seed=699 + k)
    out *= np.interp(np.arange(len(out)) / SR, [0, 0.12, 0.42], [1.0, 1.0, 0.0]) ** 1.5
    return _norm(out, 0.89)


# =================================================================== les nappes

def _laugh(semi: float) -> np.ndarray:
    """Un rire (deux à quatre « ha ! » pris dans un enregistrement), voix plus ou moins grave."""
    src = rec(ARC + "Laugh%d.wav" % RNG.integers(1, 4), semi)
    src = trim(src)
    ln = len(src) / SR
    a = RNG.uniform(0.0, max(0.01, ln - 1.6))
    b = min(ln, a + RNG.uniform(0.8, 1.6))
    return unit(cut(src, a, b, 0.02, 0.2))


def laugh_group(n: int, semis=(-6.0, 0.5), lp_hz: float = 2600.0) -> np.ndarray:
    """Un éclat de rire de toute une tablée : plusieurs rires décalés, plus ou moins graves."""
    out = np.zeros(int(2.8 * SR))
    for i in range(n):
        c = amb.lp(_laugh(RNG.uniform(*semis)), lp_hz * RNG.uniform(0.8, 1.2))
        amb.place(out, c, int(RNG.uniform(0.0, 0.5) * SR) if i else 0, RNG.uniform(0.4, 1.0))
    return out


def voice_walla(lib: Path, out: np.ndarray, density: float, lp_hz: float, semis, gain_r) -> None:
    """Brouhaha (comme en V56) : des syllabes de voix, transposées et assourdies, sur toute la boucle."""
    vs = s56._voices(lib)
    if not vs:
        return
    n = len(out)
    count = int(n / SR * density)
    for i in range(count):
        v = vs[RNG.integers(0, len(vs))]
        ln = int(RNG.uniform(0.12, 0.45) * SR)
        a = RNG.integers(0, max(1, len(v) - ln))
        s = v[a:a + ln] * np.hanning(min(ln, len(v) - a))
        s = s56._shift(s, RNG.uniform(*semis))
        s = amb.lp(s, lp_hz * RNG.uniform(0.8, 1.2), order=4)
        wplace(out, s, (i + RNG.uniform(0, 1)) * n / count, RNG.uniform(*gain_r), RNG.uniform(-0.9, 0.9))


def rope_creak(dur: float) -> np.ndarray:
    """Une amarre qui se tend sur un bollard : un frottement aigu, irrégulier."""
    m = int(dur * SR)
    x = np.arange(m) / SR
    rate = RNG.uniform(90, 170) * (1 + 0.3 * np.sin(2 * np.pi * RNG.uniform(1.0, 3.0) * x)) * np.interp(x, [0, x[-1]], [1.0, RNG.uniform(0.7, 1.3)])
    ph = np.cumsum(rate) / SR
    pulses = (np.diff(np.floor(ph), prepend=0) > 0).astype(float) * (0.5 + 0.5 * RNG.random(m))
    y = sum(amb.bp(pulses, f * 0.95, f * 1.05) * g for f, g in [(RNG.uniform(600, 900), 1.0), (RNG.uniform(1300, 1900), 0.7), (RNG.uniform(2400, 3200), 0.35)])
    return y * np.sin(np.pi * np.clip(x / x[-1], 0, 1)) ** 0.7


def hammering() -> np.ndarray:
    """Un calfat qui cloue un bordage : trois à six coups de marteau réguliers."""
    srcs = [WM + "wood_hammer_01.ogg", WM + "wood_hammer_02.ogg", WM + "hammer_01.ogg", WM + "hammer_04.ogg"]
    kind = srcs[RNG.integers(0, len(srcs))]
    nb = RNG.integers(3, 7)
    step = RNG.uniform(0.42, 0.6)
    out = np.zeros(int((nb * step + 0.6) * SR))
    for i in range(nb):
        c = clip_rec(kind, RNG.uniform(-3.0, -1.0), 0.3)
        c = addp(c, thump(180.0, 120.0, 0.02, 0.1) * 0.3)
        amb.place(out, c, int((i * step + RNG.uniform(-0.015, 0.015)) * SR + 0.02 * SR), RNG.uniform(0.7, 1.0))
    return amb.lp(out, 3500)


def ship_bell(f: float) -> np.ndarray:
    """La cloche d'un navire au mouillage : deux coups (« ding-ding »)."""
    a = s56.bronze_bell(f, 2.6, 1.3)
    g = int(0.42 * SR)
    out = np.zeros(len(a) + g)
    out[: len(a)] += a
    out[g:] += a * 0.85
    return unit(amb.lp(out, 5000))


def port_pirate_bed(lib: Path, seconds: float = 56.0) -> np.ndarray:
    n = int(seconds * SR)

    def water(m):
        out = s56.lapping(m) * 0.9
        sw = amb.lp(amb.noise(m, "brown"), 260) * amb.smooth_env(m, 0.14, 0.6, 1.0) * 0.05
        out[:, 0] += sw
        out[:, 1] += np.roll(sw, SR // 3)
        w = s59.wind(m, 200, 1600, 0.25, 0.4, 0.8) * 0.06
        return out + w

    cont = loop_layer(water, seconds, 3.0)
    ev = np.zeros((n, 2))
    # le quai : de lourdes claques d'eau contre la pierre
    slaps = []
    for _ in range(6):
        m = int(RNG.uniform(0.25, 0.5) * SR)
        e = amb.bp(RNG.standard_normal(m), 130, 750) * _env(m, 0.02, m / SR * 0.3)
        slaps.append(unit(e))
    scatter(ev, slaps, 12, (0.2, 0.4))
    # la houle fait rouler les navires : les coques et les amarres grincent au même rythme
    rock = lambda t: 0.25 + 0.75 * (0.5 + 0.5 * np.sin(2 * np.pi * t / 7.3)) ** 2  # noqa: E731
    groans = [unit(s59.wood_groan(RNG.uniform(1.2, 3.0), RNG.uniform(14, 32))) for _ in range(8)]
    scatter(ev, groans, 16, (0.3, 0.6), weight=rock)
    scatter(ev, [unit(rope_creak(RNG.uniform(0.35, 0.9))) for _ in range(6)], 12, (0.15, 0.3), weight=rock)
    creaks = [amb.lp(clip_rec(KR + "creak%d.ogg" % i), 2200) for i in (1, 2, 3)]
    scatter(ev, creaks, 8, (0.25, 0.45), semis=(-8.0, -3.0), weight=rock)
    # la ville derrière le quai : des voix, des cris, des rires, au loin
    far = np.zeros((n, 2))
    voice_walla(lib, far, 2.6, 1300.0, (-5.0, 1.0), (0.12, 0.35))
    calls = [amb.lp(clip_rec(r, 0.0, 1.6, 0.3), 1800) for r in SHOUTS[:6] + [BBR + "Hey Ooooh.wav", WF + "vsay/yeehaa.ogg"]]
    scatter(far, calls, 6, (0.2, 0.4), semis=(-6.0, -1.0))
    scatter(far, [laugh_group(RNG.integers(2, 4), lp_hz=1800.0) for _ in range(4)], 3.5, (0.18, 0.32))
    scatter(far, [hammering() for _ in range(4)], 4, (0.3, 0.5))
    chain = amb.lp(slow(clip_rec("80-CC0-RPG-SFX/chain_02.ogg"), 1.5), 2000)
    wplace(far, chain, 31.0 * SR, 0.3, 0.5)
    ev += room_wrap(far, 1.8, 2.0, 2200.0, 0.3, seed=6801)
    # les goélands, la cloche d'un navire de temps en temps
    scatter(ev, [amb.gull(k) for k in range(3)], 6, (0.08, 0.16))
    bells = np.zeros((n, 2))
    wplace(bells, ship_bell(1046.5), 13.0 * SR, 0.16, -0.6)
    wplace(bells, ship_bell(932.3), 41.5 * SR, 0.12, 0.55)
    ev += room_wrap(bells, 2.5, 1.6, 3500.0, 0.5, seed=6802)
    ev = room_wrap(ev, 1.4, 2.6, 3000.0, 0.15, seed=6803)
    return finish_bed(cont + ev, 0.7)


def chair_scrape() -> np.ndarray:
    """Une chaise qui racle le plancher, puis qui se pose."""
    d = RNG.uniform(0.25, 0.6)
    m = int(d * SR)
    x = np.arange(m) / SR
    rate = RNG.uniform(70, 160) * np.interp(x, [0, d], [1.0, RNG.uniform(0.6, 1.4)])
    ph = np.cumsum(rate) / SR
    pulses = (np.diff(np.floor(ph), prepend=0) > 0).astype(float) * (0.5 + 0.5 * RNG.random(m))
    y = sum(amb.bp(pulses, f * 0.9, f * 1.1) * g for f, g in [(RNG.uniform(250, 400), 1.0), (RNG.uniform(700, 1100), 0.7), (RNG.uniform(1600, 2400), 0.3)])
    y += amb.bp(RNG.standard_normal(m), 400, 3000) * 0.08
    y *= np.sin(np.pi * np.clip(x / d, 0, 1)) ** 0.5
    out = np.zeros(m + int(0.3 * SR))
    out[:m] += unit(y)
    amb.place(out, unit(thump(150.0, 100.0, 0.03, 0.15)) * 0.5 + 0, m - int(0.02 * SR), 1.0)
    return out


def drinking_song(seconds: float = 7.2) -> np.ndarray:
    """Au fond de la salle, une tablée qui entonne une chanson à boire (« Ho ! Hisse ! Et ho ! »),
    en frappant la table à chaque temps."""
    beat = 0.42
    tune = [(0, "o", 0, 2), (2, "i", 0, 1), (3, "é", 2, 1), (4, "o", 4, 2), (6, "a", 2, 1), (7, "o", 0, 1),
            (8, "o", 5, 2), (10, "è", 4, 1), (11, "a", 2, 1), (12, "o", 0, 3)]
    out = np.zeros(int((seconds + 1.0) * SR))
    base = 130.0
    for voice in range(6):
        det = RNG.uniform(-0.25, 0.25)
        octv = 2.0 if voice == 5 else 1.0
        for st, v, deg, ln in tune:
            f0 = base * octv * 2 ** ((deg + det) / 12.0)
            y = shout(ln * beat * 0.95, f0, v, shape="chant", att=0.04, rel=0.12, breath=0.3)
            amb.place(out, unit(y), int(max(0.0, st * beat + RNG.uniform(-0.03, 0.03)) * SR), RNG.uniform(0.5, 0.9))
    for b in range(16):
        if b % 2 == 0 or b >= 12:
            amb.place(out, _bang(False), int(max(0.0, b * beat + RNG.uniform(-0.02, 0.02)) * SR), 0.9)
    return amb.lp(out, 1600)


def taverne_pirate_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def hearth(m):
        f = amb.lp(amb.noise(m, "brown"), 250) * 0.35 * amb.smooth_env(m, 1.5, 0.6, 1.0)
        for _ in range(int(m / SR * 10)):
            k = int(RNG.uniform(0.002, 0.01) * SR)
            amb.place(f, amb.hp(RNG.standard_normal(k), RNG.uniform(1500, 4000)) * np.exp(-np.arange(k) / (k / 3)),
                      int(RNG.integers(0, m - k)), RNG.uniform(0.1, 0.6) ** 2)
        mur = amb.bp(amb.noise(m, "pink"), 150, 900) * amb.smooth_env(m, 4.0, 0.5, 1.0) * 0.5
        return amb.stereo(f * 0.6 + mur, np.roll(f, SR // 7) * 0.4 + np.roll(mur, SR // 3))

    cont = loop_layer(hearth, seconds, 2.0) * 0.12
    room = np.zeros((n, 2))
    # le brouhaha : des dizaines de voix, plutôt graves
    voice_walla(lib, room, 24.0, 2700.0, (-6.0, 1.0), (0.12, 0.5))
    # les rires : des tablées entières, les unes près, les autres au fond
    scatter(room, [laugh_group(RNG.integers(2, 5)) for _ in range(6)], 7, (0.25, 0.5))
    scatter(room, [amb.lp(clip_rec(r, 0.0, 0.9, 0.2), 2600) for r in SHOUTS], 4, (0.25, 0.5), semis=(-6.0, -1.0))
    # les chopes : on trinque, on cogne sur la table
    clinks = [clip_rec(BBR + "Ceramic Bowl %d.wav" % i, 0.0, 0.5, 0.2) for i in (1, 2, 5)]
    clinks += [clip_rec("100-CC0-SFX/glass_0%d.ogg" % i, -2.0, 0.35, 0.15) for i in (1, 2)]
    clinks += [amb.lp(clip_rec(KR + "metalPot%d.ogg" % i, 4.0, 0.4, 0.2), 6000) for i in (2, 3)]
    toasts = []
    for _ in range(8):
        y = np.zeros(int(0.8 * SR))
        for j in range(RNG.integers(2, 4)):
            amb.place(y, clinks[RNG.integers(0, len(clinks))], int(RNG.uniform(0, 0.12) * SR), RNG.uniform(0.6, 1.0))
        toasts.append(y)
    scatter(room, toasts, 14, (0.3, 0.6), lp_hz=7000.0)
    bangs = []
    for _ in range(6):
        y = np.zeros(int(0.8 * SR))
        for j in range(RNG.integers(1, 3)):
            amb.place(y, _bang(RNG.random() < 0.3), int(j * RNG.uniform(0.18, 0.3) * SR), RNG.uniform(0.6, 1.0))
        bangs.append(amb.lp(y, 3500))
    scatter(room, bangs, 10, (0.4, 0.8))
    scatter(room, [chair_scrape() for _ in range(5)], 4, (0.2, 0.35))
    scatter(room, [amb.lp(clip_rec(KR + "creak%d.ogg" % i), 2000) for i in (1, 2, 3)], 5, (0.15, 0.3), semis=(-5.0, -1.0))
    steps = []
    for _ in range(3):
        y = np.zeros(int(3.0 * SR))
        for j in range(RNG.integers(4, 7)):
            amb.place(y, clip_rec(KI + "footstep_wood_00%d.ogg" % RNG.integers(0, 5), -2.0, 0.3), int(j * 0.48 * SR), RNG.uniform(0.6, 1.0))
        steps.append(amb.lp(y, 2500))
    scatter(room, steps, 3, (0.2, 0.35))
    scatter(room, [clip_rec(KC + "diceThrow%d.ogg" % i) for i in (1, 2, 3, 4)], 2, (0.2, 0.3), lp_hz=4000.0)
    scatter(room, [clip_rec(BBR + "Cork Lid 1.wav", 3.0, 0.6, 0.2)], 1, (0.25, 0.3), lp_hz=5000.0)
    # au fond de la salle, la chanson à boire (une fois par tour de boucle)
    far = np.zeros((n, 2))
    wplace(far, drinking_song(), 22.0 * SR, 0.05, 0.55)
    room += room_wrap(far, 1.4, 3.0, 2000.0, 0.35, seed=6804)
    room = room_wrap(room, 1.0, 4.5, 3500.0, 0.2, seed=6805)
    return finish_bed(cont + room, 0.65)


def bullfrog() -> np.ndarray:
    """Un ouaouaron : « rrou-oum » grave, en impulsions, une à trois fois."""
    out = []
    for _ in range(RNG.integers(1, 4)):
        d = RNG.uniform(0.35, 0.6)
        m = int(d * SR)
        x = np.arange(m) / SR
        f0 = RNG.uniform(95, 125) * np.interp(x, [0, d], [1.0, 0.92])
        src = glottal(f0, tilt=1.0, fmax=2500.0) * (0.5 + 0.5 * (np.sin(2 * np.pi * RNG.uniform(18, 26) * x) > -0.3))
        y = formants(src, [(260, 80, 1.0), (620, 120, 0.6), (1100, 200, 0.2)])
        out += [unit(y) * np.sin(np.pi * x / d) ** 0.6, np.zeros(int(RNG.uniform(0.15, 0.3) * SR))]
    return np.concatenate(out)


def tree_frog() -> np.ndarray:
    """Une rainette : des « kwek » aigus en rafale."""
    f = RNG.uniform(2100, 3100)
    out = []
    for _ in range(RNG.integers(3, 9)):
        m = int(RNG.uniform(0.025, 0.04) * SR)
        x = np.arange(m) / SR
        y = np.sin(2 * np.pi * np.cumsum(np.interp(x, [0, x[-1]], [f * 0.85, f])) / SR) * np.hanning(m)
        y *= 0.6 + 0.4 * np.sin(2 * np.pi * 300 * x)
        out += [y, np.zeros(int(1 / RNG.uniform(6, 9) * SR) - m)]
    return np.concatenate(out)


def mud_blub() -> np.ndarray:
    """La vase qui bouillonne : deux à cinq « bloup » sourds."""
    out = np.zeros(int(1.0 * SR))
    t = 0.0
    for _ in range(RNG.integers(2, 6)):
        d = RNG.uniform(0.04, 0.08)
        m = int(d * SR)
        x = np.arange(m) / SR
        f = np.interp(x, [0, d], [RNG.uniform(140, 220), RNG.uniform(350, 520)])
        y = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-x / (d * 0.5)) * np.clip(x / 0.004, 0, 1)
        amb.place(out, y, int(t * SR), RNG.uniform(0.5, 1.0))
        t += RNG.uniform(0.06, 0.18)
    return amb.lp(out, 1800)


def heron() -> np.ndarray:
    """Un héron au loin : un « kraaak » rauque et grave."""
    return amb.lp(squawk(0.45, [420, 520, 380], am=60.0, depth=0.85, sub=0.6, noise_g=0.4), 2400)


def marais_bed(lib: Path, seconds: float = 54.0) -> np.ndarray:
    n = int(seconds * SR)

    def air(m):
        gust = amb.smooth_env(m, 0.22, 0.15, 1.0) ** 1.5
        reeds = amb.bp(amb.noise(m, "pink"), 250, 2500) * (0.35 + gust) * 0.3
        rustle = amb.hp(amb.noise(m, "white"), 3000) * gust ** 2 * 0.06
        hum = amb.lp(amb.noise(m, "brown"), 180) * 0.08
        tt = np.arange(m) / SR
        ins = amb.bp(amb.noise(m, "white"), 4300, 6300) * (0.5 + 0.5 * (np.sin(2 * np.pi * 170 * tt) > 0.2))
        ins *= amb.smooth_env(m, 0.12, 0.3, 1.0) * 0.07
        cr = s59.cricket_dry(m) * 0.015
        l = reeds + rustle + hum + ins + cr
        r = np.roll(reeds, SR // 2) + np.roll(rustle, SR // 3) + hum + np.roll(ins, SR) + np.roll(cr, SR // 5)
        return amb.stereo(l, r)

    cont = loop_layer(air, seconds, 3.0) * 0.4
    ev = np.zeros((n, 2))
    scatter(ev, [unit(s59.frog(k)) for k in range(6)], 36, (0.1, 0.3))
    scatter(ev, [bullfrog() for _ in range(4)], 7, (0.15, 0.3))
    scatter(ev, [unit(tree_frog()) for _ in range(5)], 22, (0.06, 0.15))
    muds = [amb.lp(clip_rec("25-CC0-mud-sfx/mud_%02d.ogg" % i, 0.0, 0.6, 0.15), 2500) for i in (3, 4, 5, 6, 8, 11, 14)]
    scatter(ev, muds, 10, (0.25, 0.5), semis=(-7.0, -3.0))
    scatter(ev, [unit(mud_blub()) for _ in range(6)], 14, (0.15, 0.35))
    plops = [amb.lp(trim(rec("bb - Bottle Plops (Apr 2021)/Plop - Viscous %d.wav" % i, -5.0))[: int(1.5 * SR)], 3000) for i in (1, 2, 3)]
    scatter(ev, [_fade(unit(p), 0.005, 0.3) for p in plops], 5, (0.15, 0.3))
    knocks = []
    for _ in range(4):
        y = np.zeros(int(0.6 * SR))
        for j in range(RNG.integers(2, 5)):
            amb.place(y, clack(RNG.uniform(500, 950), 0.015, 0.5, 0.2), int(RNG.uniform(0, 0.4) * SR), RNG.uniform(0.5, 1.0))
        knocks.append(y)
    scatter(ev, knocks, 8, (0.05, 0.1))
    far = np.zeros((n, 2))
    for at, rel_, semi in [(17.0, "splash_11.ogg", -4.0), (43.5, "splash_14.ogg", -5.0)]:
        sp = amb.lp(clip_rec(SPL + rel_, semi, 1.4, 0.4), 2400)
        wplace(far, sp, at * SR, 0.5, RNG.uniform(-0.7, 0.7))
        wplace(far, unit(thump(70.0, 40.0, 0.1, 0.4)), at * SR, 0.25, 0.0)
    scatter(far, [unit(heron())], 2, (0.1, 0.16))
    scatter(far, [unit(amb.jungle_bird(k)) for k in (0, 2)], 2, (0.04, 0.07))
    ev += room_wrap(far, 1.6, 2.4, 2500.0, 0.4, seed=6806)
    ev = room_wrap(ev, 1.2, 3.0, 3000.0, 0.2, seed=6807)
    return finish_bed(cont + ev, 0.7)


# =================================================================== lancement

SOUNDS = {
    "coup_poing": (coup_poing, 3), "ko": (ko, 2), "foule_bagarre": (foule_bagarre, 3), "des_roule": (des_roule, 2),
    "perroquet": (perroquet, 3), "croco_menace": (lambda k: croco_menace(), 1), "croco_mort": (lambda k: croco_mort(), 1),
    "squelette_menace": (lambda k: squelette_menace(), 1), "squelette_mort": (lambda k: squelette_mort(), 1),
    "os_choc": (os_choc, 3),
}
BEDS = {"port_pirate": port_pirate_bed, "taverne_pirate": taverne_pirate_bed, "marais": marais_bed}


def loudness(x: np.ndarray) -> float:
    """Sonie perçue d'un bruitage (approchée) : le maximum sur 400 ms d'un signal pondéré
    (graves atténués, aigus un peu relevés), en dB."""
    y = signal.sosfilt(signal.butter(2, 100.0, btype="highpass", fs=SR, output="sos"), x)
    y = y + 0.6 * signal.sosfilt(signal.butter(1, 2000.0, btype="highpass", fs=SR, output="sos"), y)
    w = min(int(0.4 * SR), len(y))
    c = np.cumsum(np.concatenate([[0.0], y ** 2]))
    return float(10 * np.log10(np.max((c[w:] - c[:-w]) / w) + 1e-12))


def main() -> int:
    if len(sys.argv) > 1 and Path(sys.argv[1]).is_dir():
        s63.LIB = Path(sys.argv[1])
        names = sys.argv[2:]
    else:
        names = sys.argv[1:]
    for name, (fn, count) in SOUNDS.items():
        if names and name not in names:
            continue
        # les variantes d'une même famille sont mises à la même sonie (la plus douce) : tirées au
        # hasard en jeu, aucune ne ressort
        xs = [fn(k) for k in range(count)]
        ref = min(loudness(x) for x in xs)
        for k, x in enumerate(xs):
            fx.save(f"{name}_{k + 1}", x * 10 ** ((ref - loudness(x)) / 20.0))
        print(" ", name, count)
    for name, fn in BEDS.items():
        if names and name not in names:
            continue
        amb.save(f"ambiance/{name}", fn(s63.LIB))
    return 0


if __name__ == "__main__":
    sys.exit(main())
