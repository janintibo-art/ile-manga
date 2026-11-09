"""V124 : les sons du château du comte Dracula, à Sombreval (synthétisés ici, ou tirés de la banque CC0
et retravaillés ; versés au domaine public, CC0 1.0).

  sfx/vampire_siffle_1..4      le sifflement menaçant du vampire (« khhhhh ») : un souffle aigu entre
                               les dents (du bruit dont la bande monte et descend), un raclement de
                               gorge qui grésille, un grondement de voix tout au fond, et quelques
                               souffles de la banque CC0 mêlés par-dessous.
  sfx/vampire_rire_1..3        le rire du comte, grave, lent, aristocratique (« hé… hé… hé… »), sans
                               paroles : une voix d'homme synthétisée (source glottale, formants de
                               « è »), chaque « hé » plus bas et plus espacé que le précédent, dans la
                               réverbération d'une grande salle de pierre.
  sfx/vampire_attaque_1..3     le bond du vampire : un feulement rageur et le claquement de la cape
                               qui fend l'air (un souffle large dont la bande glisse, le tissu qui
                               bat), mêlés à des attaques de créatures et des « swish » de la banque.
  sfx/vampire_mort_1..3        la mort du vampire : un cri aigu qui s'éteint et se défait en souffle,
                               puis une nuée de chauves-souris qui s'envole et un scintillement
                               d'air très doux (des sinus aigus qui tremblent, des poussières).
  sfx/vampire_brume_1..2       le vampire se change en brume et reparaît plus loin : un grand souffle
                               grave qui monte et retombe, un sous-grave qui plonge, un court
                               battement d'ailes.
  sfx/nuee_chauves_souris_1..2 une nuée de chauves-souris qui passe (mono) : une trentaine de petites
                               bêtes qui battent des ailes chacune à son rythme, de minuscules cris
                               aigus, le tout qui enfle puis s'éloigne.
  sfx/murmures_1..3            des chuchotements de fantômes, incompréhensibles : des consonnes de
                               bruit (s, ch, f, h) et des voyelles soufflées dont les formants
                               glissent, plusieurs voix (certaines jouées à l'envers) dans une salle
                               très réverbérante.
  sfx/orgue_accord_1           le grand accord d'orgue gothique (ré mineur, avec la pédale grave) :
                               l'orgue à tuyaux de la VCSL (Versilian Studios, CC0), qui enfle (la
                               boîte expressive s'ouvre) puis s'arrête et laisse sonner l'église ; à
                               défaut de la banque, un orgue en synthèse additive avec un léger chorus.
  sfx/porte_grince_1..2        une lourde porte de bois qui grince longuement : les grincements de
                               porte de la banque CC0 descendus de quelques demi-tons, et un
                               frottement collé-glissé synthétisé (le gond) qui fait chanter le bois.
  sfx/herse_monte_1            la herse de fer qui se lève : le treuil et son cliquet, les chaînes qui
                               cliquettent, le fer qui frotte dans les rainures de pierre, et le
                               grand « clang » final quand elle se bloque.
  sfx/bougies_soufflees_1      un courant d'air glacé souffle toutes les bougies d'un coup : un
                               souffle qui passe, et une dizaine de petits « fft ».
  sfx/boite_musique_1          une boîte à musique, un peu fausse : une valse en ré mineur dont le
                               mouvement ralentit à la fin (le ressort se détend).
  ambiance/chateau_comte       l'intérieur du château (48 s, en boucle) : le vent qui gémit dans les
                               couloirs, des boiseries qui craquent, un bourdon d'orgue très lointain,
                               des gouttes d'eau, de rares chuchotements, la grande salle de pierre.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_sons_v124.py [/root/snd/CC0-Public-Domain-Sounds] [--vcsl /root/snd/VCSL]
"""
from pathlib import Path
import sys

import numpy as np
from scipy import signal

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402

SR = 44100
RNG = np.random.default_rng(12424)
CRE = "80-CC0-creature-SFX/"
CRE2 = "80-CC0-creature-sfx-2/"
WM = "100-CC0-wood-metal-SFX/"
SFX1 = "100-CC0-SFX/"
RPG = "80-CC0-RPG-SFX/"
WOOSH = "Micro Pack - Organic Wooshes/"
MECA = "bb - Smol Mechanisms (May 2021)/"
KRPG = "kenney_rpgaudio/Audio/"
VCSL = Path("/root/snd/VCSL")

# les formants (F, Q, gain) des voyelles d'une voix d'homme grave
VOY = {
    "a": [(700, 5, 1.0), (1100, 6, 0.7), (2450, 9, 0.25), (3300, 12, 0.1)],
    "è": [(520, 6, 1.0), (1700, 8, 0.55), (2450, 10, 0.25), (3300, 12, 0.1)],
    "é": [(400, 6, 1.0), (1950, 9, 0.5), (2600, 10, 0.25), (3400, 12, 0.1)],
    "o": [(480, 6, 1.0), (820, 7, 0.6), (2450, 10, 0.2), (3300, 12, 0.08)],
    "ou": [(320, 6, 1.0), (760, 7, 0.5), (2300, 10, 0.15), (3200, 12, 0.06)],
    "i": [(280, 6, 1.0), (2200, 10, 0.5), (2950, 12, 0.3), (3600, 12, 0.1)],
    "eu": [(430, 6, 1.0), (1400, 8, 0.5), (2350, 10, 0.2), (3200, 12, 0.08)],
}
# les mêmes, pour les voyelles chuchotées (centre, largeur de bande en Hz, gain)
VOY_B = {k: [(f, f / q * 1.6, g) for f, q, g in v] for k, v in VOY.items()}


# =================================================================== outils (ceux de la V121, et quelques autres)

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


def formants(src: np.ndarray, fs: list, scale: float = 1.0) -> np.ndarray:
    out = np.zeros(len(src))
    for f, q, g in fs:
        out += bpf(src, f * scale, q) * g
    return out


def moan(dur: float, f0a: float, f0b: float, vowel: str, rough: float) -> np.ndarray:
    """La plainte de la V121 (une voix qui racle)."""
    n = int(dur * SR)
    t = t_(n)
    u = t / dur
    f0 = f0a + (f0b - f0a) * u ** 0.8 + 6.0 * np.sin(2 * np.pi * 3.1 * t) * u
    src = glottal(f0, rough)
    asp = amb.bp(RNG.standard_normal(n), 300, 4500) * 0.35
    y = formants(src + asp * (0.6 + rough), VOY[vowel])
    env = np.clip(t / 0.18, 0, 1) * np.clip((dur - t) / 0.45, 0, 1) ** 1.4
    env *= 0.8 + 0.2 * np.sin(2 * np.pi * 1.7 * t + RNG.uniform(0, 6))
    return norm(amb.lp(y * env, 3800))


def lib_pitched(lib, files, semi, lp_hz=2600.0, max_s=3.0, hp_hz=70):
    out = []
    if lib is None:
        return out
    for f in files:
        p = lib / f
        if not p.is_file():
            print("  ! absent :", f)
            continue
        x = fx.read_mono(p)
        x = fx.process(x, max_s, semi, hp_hz)
        out.append(norm(amb.lp(x, lp_hz)))
    return out


def mix_at(a, b, gb, off_s=0.0):
    off = int(off_s * SR)
    n = max(len(a), len(b) + off)
    y = np.zeros(n)
    y[:len(a)] += a
    y[off:off + len(b)] += b * gb
    return norm(y)


def mix(dur: float, *parts) -> np.ndarray:
    """Des sons posés sur une piste : (son, départ en s, gain)."""
    y = np.zeros(int(dur * SR))
    for x, at, g in parts:
        place(y, x, at * SR, g)
    return y


def fin(x: np.ndarray, dur: float | None = None, fade: float = 0.08) -> np.ndarray:
    """Coupe à la durée voulue, fondu de fin (pas de clic), normalisé."""
    if dur is not None:
        x = x[:int(dur * SR)]
    k = min(int(fade * SR), len(x) // 3)
    x = x.copy()
    x[-k:] *= np.linspace(1.0, 0.0, k) ** 2
    return norm(x)


def salle(x: np.ndarray, rt: float = 1.6, wet: float = 0.35, dark: float = 3500.0, pre: float = 0.018,
          seed: int = 0, er: int = 10) -> np.ndarray:
    """La réverbération d'une salle de pierre : un bruit qui décroît (les aigus s'éteignent plus vite),
    des premières réflexions sur les murs. Rend le son et sa queue."""
    r = np.random.default_rng(seed)
    m = int(rt * 1.1 * SR)
    t = t_(m)
    nz = r.standard_normal(m)
    low = amb.lp(nz, dark)
    ir = low * np.exp(-6.9 * t / rt) + (nz - low) * np.exp(-6.9 * t / (rt * 0.35)) * 0.4
    ir *= np.clip(t / 0.01, 0, 1)
    for _ in range(er):
        ir[int(r.uniform(0.006, 0.07) * SR)] += r.uniform(0.6, 1.4) * r.choice([-1, 1])
    ir = np.concatenate([np.zeros(int(pre * SR)), ir])
    ir /= np.sqrt(np.sum(ir ** 2))
    y = np.concatenate([x, np.zeros(len(ir))])
    rev = np.zeros(len(y))
    c = signal.fftconvolve(x, ir)[:len(y)]
    rev[:len(c)] = c
    rev *= np.sqrt(np.mean(x ** 2) / (np.mean(rev ** 2) + 1e-12))
    return y * (1.0 - 0.5 * wet) + rev * wet


def spectre(x: np.ndarray, gain_fn, nper: int = 1024) -> np.ndarray:
    """Filtre qui bouge dans le temps (par la transformée de Fourier à court terme) :
    gain_fn(f [bins, 1], t [1, trames]) donne le gain de chaque case."""
    f, tt, Z = signal.stft(x, SR, nperseg=nper, noverlap=nper * 3 // 4)
    G = gain_fn(f[:, None], tt[None, :])
    _, y = signal.istft(Z * G, SR, nperseg=nper, noverlap=nper * 3 // 4)
    y = y[:len(x)]
    return np.concatenate([y, np.zeros(len(x) - len(y))])


def courbe(pts, tt):
    """Une courbe (temps, valeur) lue aux instants tt."""
    xs, ys = zip(*pts)
    return np.interp(tt, xs, ys)


def bosse(f, fc, bwid):
    return np.exp(-0.5 * ((f - fc) / bwid) ** 2)


def souffle(dur: float, pts_fc, pts_bw, pts_amp, color: str = "pink") -> np.ndarray:
    """Un souffle (vent, cape, brume) : du bruit dont la bande glisse (fc, largeur, force dans le temps)."""
    n = int(dur * SR)
    src = amb.noise(n, color)

    def g(f, tt):
        fc = courbe(pts_fc, tt)
        bwid = courbe(pts_bw, tt)
        return bosse(f, fc, bwid) * courbe(pts_amp, tt)
    return spectre(src, g, 2048)


def chuchote_voyelle(dur: float, v1: str, v2: str, scale: float = 1.0) -> np.ndarray:
    """Une voyelle soufflée (sans voix) : du bruit dans des formants qui glissent de v1 à v2."""
    n = int(dur * SR)
    src = amb.bp(RNG.standard_normal(n), 250, 7000)
    a, b = VOY_B[v1], VOY_B[v2]

    def g(f, tt):
        u = np.clip(tt / dur, 0, 1)
        G = np.zeros((len(f), tt.shape[1]))
        for (fa, ba, ga), (fb, bb, gb) in zip(a, b):
            fc = (fa + (fb - fa) * u) * scale
            G += bosse(f, fc, (ba + (bb - ba) * u) * scale) * (ga + (gb - ga) * u)
        return G
    y = spectre(src, g, 1024)
    t = t_(n)
    return y * np.clip(t / 0.05, 0, 1) * np.clip((dur - t) / (dur * 0.5), 0, 1) ** 1.3


def consonne(c: str) -> np.ndarray:
    lo, hi, d = {"s": (4200, 10000, 0.11), "ch": (1900, 6500, 0.13), "f": (1200, 7000, 0.09),
                 "h": (500, 3200, 0.08), "k": (1500, 5000, 0.035)}[c]
    m = int(d * SR)
    return amb.bp(RNG.standard_normal(m), lo, hi) * np.hanning(m)


def aile(size: float = 1.0, bright: float = 1.0) -> np.ndarray:
    """Un battement d'aile de chauve-souris : la membrane de peau claque (« flp »), l'air chassé."""
    m = int(0.06 * size * SR)
    t = t_(m)
    lo, hi = 350 / size, min(5200 * bright / size, 9000)
    y = amb.bp(RNG.standard_normal(m), lo, hi) * (t / (0.006 * size)) * np.exp(-t / (0.014 * size))
    y += amb.lp(RNG.standard_normal(m), 260 / size) * np.exp(-t / (0.02 * size)) * 0.8
    return y


def battements(dur: float, rate: float, size: float = 1.0, env=None, jitter: float = 0.12, bright: float = 1.0) -> np.ndarray:
    """Une chauve-souris qui vole : des battements d'ailes réguliers (rate par seconde), un peu irréguliers."""
    y = np.zeros(int((dur + 0.1) * SR))
    t = RNG.uniform(0, 1 / rate)
    while t < dur:
        u = t / dur
        g = env(u) if env is not None else 1.0
        place(y, aile(size * RNG.uniform(0.85, 1.15), bright), t * SR, g * RNG.uniform(0.6, 1.0))
        t += 1 / rate * (1 + RNG.uniform(-jitter, jitter))
    return y


def couic(f: float | None = None) -> np.ndarray:
    """Un tout petit cri de chauve-souris : une glissade aiguë très brève."""
    d = RNG.uniform(0.018, 0.045)
    m = int(d * SR)
    t = t_(m)
    f0 = f or RNG.uniform(4200, 7800)
    fr = f0 * (1 + RNG.uniform(0.1, 0.35) * (1 - t / d)) * (1 + 0.04 * np.sin(2 * np.pi * 180 * t))
    ph = 2 * np.pi * np.cumsum(fr) / SR
    y = np.sin(ph) + 0.25 * np.sin(2 * ph)
    return y * np.sin(np.pi * t / d) ** 1.5


def scintille(dur: float, n_par: int = 14, lo: float = 2200.0, hi: float = 7500.0) -> np.ndarray:
    """Un scintillement d'air : des sinus aigus qui tremblent, des grains de poussière lumineuse."""
    n = int(dur * SR)
    t = t_(n)
    y = np.zeros(n)
    for _ in range(n_par):
        f = RNG.uniform(lo, hi)
        trem = 0.5 + 0.5 * np.sin(2 * np.pi * RNG.uniform(3, 9) * t + RNG.uniform(0, 6))
        y += np.sin(2 * np.pi * f * t * (1 + 0.004 * np.sin(2 * np.pi * 0.7 * t)) + RNG.uniform(0, 6)) * trem * RNG.uniform(0.3, 1.0)
    grains = (RNG.random(n) < 120 / SR) * RNG.uniform(0.3, 1.0, n)
    y = y / n_par + amb.bp(grains, 5000, 12000) * 0.8 + amb.hp(RNG.standard_normal(n), 6000) * 0.02
    return y


def clink(f: float, d: float = 0.05) -> np.ndarray:
    """Un petit choc de fer (un maillon) : des modes inharmoniques qui s'éteignent vite."""
    m = int(max(d * 4, 0.05) * SR)
    t = t_(m)
    y = np.zeros(m)
    for r, a, dd in ((1.0, 1.0, 1.0), (2.76, 0.6, 0.6), (5.4, 0.4, 0.35), (8.93, 0.25, 0.2)):
        if f * r < SR * 0.45:
            y += a * np.sin(2 * np.pi * f * r * t + RNG.uniform(0, 6)) * np.exp(-t / (d * dd))
    k = int(0.002 * SR)
    y[:k] += RNG.standard_normal(k) * 0.5
    return y


def clang(f: float, dur: float = 1.6) -> np.ndarray:
    """Un grand choc de fer (la herse qui se bloque) : des modes graves et longs, un coup sourd."""
    m = int(dur * SR)
    t = t_(m)
    y = np.zeros(m)
    for r, a, d in ((1.0, 1.0, 0.9), (2.32, 0.7, 0.6), (3.9, 0.5, 0.45), (5.1, 0.4, 0.3), (6.8, 0.3, 0.2), (9.3, 0.2, 0.12)):
        y += a * np.sin(2 * np.pi * f * r * t + RNG.uniform(0, 6)) * np.exp(-t / d)
    y += np.sin(2 * np.pi * (70 - 25 * np.clip(t / 0.2, 0, 1)) * t) * np.exp(-t / 0.12) * 1.6
    k = int(0.03 * SR)
    y[:k] += amb.bp(RNG.standard_normal(k), 400, 6000) * np.exp(-t[:k] / 0.006) * 2
    return y * np.clip(t / 0.001, 0, 1)


def colle_glisse(dur: float, pts_rate, res, width: float = 0.05, bruit: float = 0.15) -> np.ndarray:
    """Un frottement « collé-glissé » (gond, bois qui grince) : des impulsions dont la cadence fait la
    note du grincement, qui font chanter les résonances (f, gain) du bois."""
    n = int(dur * SR)
    t = t_(n)
    rate = courbe(pts_rate, t) * (1 + 0.07 * amb.smooth_env(n, 4.0, -1.0, 1.0))
    ph = np.cumsum(np.clip(rate, 5, None)) / SR
    pulses = (np.diff(np.floor(ph), prepend=0) > 0).astype(float) * RNG.uniform(0.5, 1.0, n)
    y = np.zeros(n)
    for f, g in res:
        y += amb.bp(pulses, f * (1 - width), f * (1 + width)) * g
    y += amb.lp(pulses, 900) * 0.3
    # un peu de frottement (bruit), dosé par rapport au grincement lui-même
    nz = amb.bp(RNG.standard_normal(n), 200, 2500)
    y += nz * bruit * np.std(y) / (np.std(nz) + 1e-12)
    return y * (0.55 + 0.45 * amb.smooth_env(n, 6.0, 0.0, 1.0))


# =================================================================== le vampire

def siffle(k, libx):
    """Le sifflement : « khhhhhh » entre les dents, et la gorge qui gronde."""
    dur = [0.8, 1.05, 0.7, 1.15][k]
    n = int(dur * SR)
    t = t_(n)
    att = [0.03, 0.06, 0.02, 0.09][k]
    env = np.clip(t / att, 0, 1) ** 0.7 * np.clip((dur - t) / (dur * 0.45), 0, 1) ** 1.6
    env *= 1.0 + 0.25 * np.exp(-t / 0.12)                       # le coup de souffle du début
    env *= 0.85 + 0.15 * np.sin(2 * np.pi * RNG.uniform(5, 8) * t)   # la menace qui tremble
    # les dents : du bruit très aigu (une bande qui glisse un peu vers le haut)
    f0 = RNG.uniform(4200, 5600)
    teeth = spectre(amb.noise(n, "white"), lambda f, tt: bosse(f, courbe([(0, f0 * 0.85), (dur, f0 * 1.15)], tt), 1600)
                    + 0.5 * bosse(f, 8200, 1800) + 0.25 * bosse(f, 2600, 500))
    # la gorge : un « kh » qui grésille (du bruit dans des formants de « a », haché par la friture)
    fry = 0.5 + 0.5 * np.sign(np.sin(2 * np.pi * np.cumsum(np.full(n, RNG.uniform(32, 46))) / SR))
    throat = formants(amb.bp(RNG.standard_normal(n), 500, 3500), VOY["a"], RNG.uniform(1.0, 1.25)) * amb.lp(fry, 160)
    # tout au fond, un grondement de voix
    growl = moan(dur, RNG.uniform(78, 95), RNG.uniform(62, 72), "a", 0.95) * 0.5
    y = norm(teeth) * 1.0 + norm(throat) * 0.45 + growl * [0.25, 0.35, 0.18, 0.4][k]
    y *= env
    if libx:
        y = mix_at(norm(y), libx[k % len(libx)], 0.3, 0.0)
    y = salle(norm(y), 0.9, 0.18, 4000, seed=1240 + k)
    return fin(y, dur + 0.25)


def rire(k):
    """Le rire du comte : « hé… hé… hé… », grave, lent, qui descend, dans la grande salle."""
    sylls = [[(0.0, 104, 0.24), (0.36, 98, 0.24), (0.76, 92, 0.26), (1.2, 84, 0.42)],
             [(0.0, 96, 0.26), (0.42, 92, 0.24), (0.88, 86, 0.48)],
             [(0.0, 110, 0.2), (0.3, 104, 0.2), (0.62, 98, 0.22), (0.98, 92, 0.24), (1.4, 82, 0.5)]][k]
    total = sylls[-1][0] + sylls[-1][2] + 0.4
    y = np.zeros(int(total * SR))
    for i, (at, f0a, d) in enumerate(sylls):
        n = int(d * SR)
        t = t_(n)
        # le « h » : un souffle dans la bouche déjà ouverte sur le « è »
        h = formants(amb.bp(RNG.standard_normal(int(0.07 * SR)), 300, 5000), VOY["è"], 0.92)
        h *= np.hanning(len(h)) ** 0.7
        # le « è » : la voix, qui retombe à la fin de chaque « hé »
        f0 = f0a * (1.0 - 0.12 * (t / d) ** 1.3) * (1 + 0.012 * np.sin(2 * np.pi * 5.2 * t))
        src = glottal(f0, 0.35) + amb.bp(RNG.standard_normal(n), 300, 5000) * 0.6
        v = formants(src, VOY["è"], 0.92)
        v = amb.lp(v, 3600)
        venv = np.clip(t / 0.018, 0, 1) * np.exp(-t / (d * 0.55)) * np.clip((d - t) / 0.05, 0, 1)
        # une petite secousse de la poitrine (le rire « hoqueté »)
        venv *= 1.0 - 0.3 * np.exp(-((t - d * 0.35) / 0.02) ** 2)
        g = 1.0 - 0.1 * i
        place(y, norm(h) * 0.35, at * SR, g)
        place(y, norm(v * venv), (at + 0.045) * SR, g)
    # le souffle qui sort par le nez, à la fin
    m = int(0.35 * SR)
    br = formants(amb.bp(RNG.standard_normal(m), 200, 2500), VOY["eu"], 0.9) * np.sin(np.pi * t_(m) / (m / SR)) ** 2
    place(y, norm(br) * 0.12, (sylls[-1][0] + sylls[-1][2]) * SR)
    y = amb.hp(y, 60)
    y = salle(norm(y), 2.1, 0.42, 2800, pre=0.03, seed=1250 + k, er=14)
    return fin(y, min(2.5, total + 0.9), 0.4)


def cape(dur: float = 0.5) -> np.ndarray:
    """La cape qui fend l'air : un souffle qui glisse, le tissu qui bat."""
    n = int(dur * SR)
    t = t_(n)
    w = souffle(dur, [(0, 300), (dur * 0.35, 1300), (dur, 450)], [(0, 250), (dur * 0.35, 900), (dur, 300)],
                [(0, 0), (dur * 0.3, 1.0), (dur, 0)])
    flap = 1.0 - 0.6 * (0.5 + 0.5 * np.sin(2 * np.pi * RNG.uniform(18, 26) * t)) * np.exp(-t / 0.25)
    return norm(w * flap)


def attaque(k, libx, swish):
    dur = [0.75, 0.85, 0.65][k]
    y = moan(dur * 0.85, RNG.uniform(150, 175), RNG.uniform(105, 120), "a", 1.0)
    y = np.tanh(y * 2.6)
    # le sifflement qui accompagne le feulement
    n = len(y)
    hs = spectre(amb.noise(n, "white"), lambda f, tt: bosse(f, 5200, 1800)) * np.clip(t_(n) / 0.02, 0, 1) * np.exp(-t_(n) / 0.35)
    y = norm(y) + norm(hs) * 0.35
    if libx:
        y = mix_at(norm(y), libx[k % len(libx)], 0.55, 0.02)
    c = cape(0.5)
    if swish:
        c = mix_at(c, swish[k % len(swish)], 0.6, 0.03)
    out = mix(dur + 0.3, (norm(y), 0.06, 1.0), (c, 0.0, 0.75))
    out = salle(norm(out), 0.8, 0.15, 4000, seed=1260 + k)
    return fin(out, dur)


def mort(k, libx):
    """Le cri qui s'éteint, se défait en souffle, puis les chauves-souris s'envolent et l'air scintille."""
    dur_cri = [1.0, 1.15, 0.9][k]
    n = int(dur_cri * SR)
    t = t_(n)
    u = t / dur_cri
    f0 = 330 + 280 * np.sin(np.pi * np.clip(u * 1.6, 0, 1)) * (1 - 0.6 * u) - 120 * u + RNG.uniform(-20, 20)
    src = glottal(f0, 0.8) + amb.bp(RNG.standard_normal(n), 800, 7000) * 0.7
    voiced = formants(src, [(820, 4, 1.0), (1300, 5, 0.8), (2800, 7, 0.45), (3700, 9, 0.2)])
    voiced = np.tanh(voiced / (np.max(np.abs(voiced)) + 1e-9) * 2.5)
    # le cri se défait : la voix s'efface, il ne reste qu'un souffle aigu
    air = spectre(amb.noise(n, "white"), lambda f, tt: bosse(f, courbe([(0, 2500), (dur_cri, 6000)], tt), 2000))
    cri = norm(voiced) * np.clip(1.0 - u * 1.3, 0, 1) ** 1.5 + norm(air) * np.sin(np.pi * np.clip(u, 0, 1)) * 0.35
    cri *= np.clip(t / 0.04, 0, 1) * np.clip((dur_cri - t) / 0.3, 0, 1)
    cri = amb.lp(cri, 7500)
    if libx:
        cri = mix_at(norm(cri), libx[k % len(libx)] * np.linspace(1, 0, len(libx[k % len(libx)])) ** 2, 0.4, 0.0)
    total = [2.3, 2.5, 2.1][k]
    parts = [(norm(cri), 0.0, 1.0)]
    # la nuée de chauves-souris qui s'envole (elles partent toutes, de plus en plus loin)
    for b in range(10 + 2 * k):
        d = RNG.uniform(0.7, 1.3)
        fl = battements(d, RNG.uniform(11, 17), RNG.uniform(0.7, 1.0), env=lambda x: np.sin(np.pi * min(1.0, x * 1.4 + 0.15)) ** 1.2)
        parts.append((fl, RNG.uniform(0.45, 0.9), RNG.uniform(0.18, 0.32)))
    for _ in range(7):
        parts.append((couic(), RNG.uniform(0.55, 1.5), RNG.uniform(0.06, 0.13)))
    # le scintillement de l'air, tout doux, qui s'éteint
    sd = total - 0.8
    sc = scintille(sd)
    ts = t_(len(sc))
    sc *= np.clip(ts / 0.35, 0, 1) * np.clip((sd - ts) / (sd * 0.7), 0, 1) ** 1.5
    parts.append((norm(sc), 0.75, 0.16))
    out = mix(total + 0.5, *parts)
    out = salle(norm(out), 1.5, 0.3, 4500, seed=1270 + k)
    return fin(out, total, 0.35)


def brume(k, swish):
    """La brume : un grand souffle grave qui monte et retombe, un sous-grave qui plonge, des ailes."""
    dur = [0.95, 1.0][k]
    n = int(dur * SR)
    t = t_(n)
    w = souffle(dur, [(0, 140), (dur * 0.45, [650, 800][k]), (dur, 160)], [(0, 120), (dur * 0.45, 600), (dur, 150)],
                [(0, 0), (dur * 0.42, 1.0), (dur * 0.8, 0.35), (dur, 0)], "pink")
    sub = np.sin(2 * np.pi * np.cumsum(courbe([(0, 62), (dur, 36)], t)) / SR) * np.sin(np.pi * t / dur) ** 2
    # un voile aigu, comme une vapeur
    veil = souffle(dur, [(0, 3000), (dur, 5000)], [(0, 1500), (dur, 2500)], [(0, 0), (dur * 0.5, 1.0), (dur, 0)], "white")
    parts = [(norm(w), 0.0, 1.0), (norm(sub), 0.0, 0.45), (norm(veil), 0.0, 0.12)]
    if swish:
        sw = norm(amb.lp(swish[k % len(swish)], 2500))
        parts.append((sw, dur * 0.3, 0.4))
    fl = battements(0.32, 16, 0.85, env=lambda x: np.sin(np.pi * x))
    parts.append((norm(fl), dur * [0.55, 0.62][k], 0.5))
    out = mix(dur + 0.3, *parts)
    out = salle(norm(out), 1.2, 0.25, 3000, seed=1280 + k)
    return fin(out, dur + 0.1, 0.25)


# =================================================================== le château

def nuee(k):
    """Une nuée de chauves-souris qui passe : beaucoup d'ailes, de petits cris, ça enfle et ça s'éloigne."""
    dur = [2.7, 3.0][k]
    parts = []
    for b in range(30 + 6 * k):
        c = RNG.uniform(0.25, 0.75) * dur                       # le moment où elle passe au plus près
        d = RNG.uniform(0.6, 1.3)
        at = max(0.0, c - d / 2)
        fl = battements(d, RNG.uniform(10, 18), RNG.uniform(0.6, 1.1), env=lambda x: np.sin(np.pi * x) ** 1.5,
                        bright=RNG.uniform(0.7, 1.2))
        g = 0.12 + 0.2 * np.exp(-abs(c / dur - 0.5) * 3)
        parts.append((fl, at, g * RNG.uniform(0.7, 1.0)))
    for _ in range(26 + 6 * k):
        u = RNG.beta(2.5, 2.5)
        parts.append((couic(), u * dur, RNG.uniform(0.04, 0.12)))
    # le souffle de la nuée qui passe
    w = souffle(dur, [(0, 500), (dur * 0.5, 1400), (dur, 600)], [(0, 400), (dur, 900)], [(0, 0), (dur * 0.5, 1.0), (dur, 0)])
    parts.append((norm(w), 0.0, 0.18))
    out = mix(dur + 0.2, *parts)
    t = t_(len(out))
    out *= np.clip(t / 0.4, 0, 1) * np.clip((dur - t) / 0.7, 0, 1) ** 1.2
    out = salle(norm(out), 1.3, 0.22, 5000, seed=1290 + k)
    return fin(out, dur, 0.2)


def voix_chuchotee(phrase, scale: float) -> np.ndarray:
    out = []
    for cons, v1, v2, d in phrase:
        if cons:
            out.append(norm(consonne(cons)) * 0.45)
        if v1:
            out.append(norm(chuchote_voyelle(d, v1, v2 or v1, scale)) * 0.7)
        out.append(np.zeros(int(RNG.uniform(0.02, 0.09) * SR)))
    return np.concatenate(out)


PHRASES = [
    [("s", "i", "è", 0.3), ("h", "ou", "a", 0.42), ("ch", "é", None, 0.25), ("f", "o", "ou", 0.4)],
    [("h", "a", "o", 0.38), ("s", None, None, 0), ("k", "è", "i", 0.3), ("ch", "ou", None, 0.45)],
    [("f", "i", "a", 0.3), ("h", "eu", "o", 0.5), ("s", "è", None, 0.22), ("h", "a", "ou", 0.35)],
    [("ch", "a", "é", 0.32), ("s", "ou", "i", 0.35), ("h", "o", None, 0.42)],
    [("k", "i", "ou", 0.28), ("f", "è", "a", 0.4), ("ch", "o", "eu", 0.38)],
]


def murmures(k):
    """Des chuchotements de fantômes, à plusieurs voix (certaines à l'envers), dans une salle immense."""
    dur = [2.4, 2.8, 2.2][k]
    parts = []
    for v in range(3):
        ph = PHRASES[(k * 2 + v) % len(PHRASES)]
        w = voix_chuchotee(ph, RNG.uniform(0.85, 1.2))
        if (k + v) % 2 == 1:
            w = w[::-1].copy()                                   # une voix à l'envers : on ne comprend rien
        parts.append((amb.lp(norm(w), 7000), RNG.uniform(0.0, 0.5), [1.0, 0.65, 0.45][v]))
    out = mix(dur + 1.0, *parts)
    # un tout petit gémissement aigu, très loin (le froid)
    n = int(dur * SR)
    t = t_(n)
    tone = np.sin(2 * np.pi * np.cumsum(courbe([(0, 880), (dur, 820 - 40 * k)], t) * (1 + 0.006 * np.sin(2 * np.pi * 4.5 * t))) / SR)
    tone *= np.sin(np.pi * t / dur) ** 2
    place(out, tone, 0, 0.02)
    out = salle(norm(out), 2.4, 0.5, 3500, pre=0.03, seed=1300 + k, er=14)
    # le début respire à l'envers (la réverbération qui « aspire » la première syllabe)
    pre = salle(norm(parts[0][0][:int(0.4 * SR)]), 1.2, 1.0, 3000, seed=1310 + k)[::-1]
    out = mix(dur + 1.5, (norm(pre), 0.0, 0.25), (out, 0.25, 1.0))
    t = t_(len(out))
    out *= np.clip((dur - t) / 0.6, 0, 1) ** 1.2
    return fin(out, dur, 0.1)


def orgue_additif(m: float, dur: float) -> np.ndarray:
    """Un tuyau d'orgue en synthèse (si la banque manque) : beaucoup d'harmoniques, un léger chorus."""
    f = 440.0 * 2 ** ((m - 69) / 12)
    n = int(dur * SR)
    t = t_(n)
    y = np.zeros(n)
    for det in (-0.0012, 0.0, 0.0014):
        for h, a in ((0.5, 0.5), (1, 1.0), (2, 0.7), (3, 0.45), (4, 0.35), (5, 0.2), (6, 0.18), (8, 0.12), (10, 0.06), (12, 0.04)):
            if f * h < 12000:
                y += a * np.sin(2 * np.pi * f * h * (1 + det) * t + RNG.uniform(0, 6))
    y += amb.bp(RNG.standard_normal(n), f, min(f * 8, 12000)) * 0.03   # le souffle du tuyau
    return y / 3


def orgue_accord(vcsl: Path):
    """Le grand accord de ré mineur : la pédale (ré grave), et les mains qui plaquent ré-fa-la."""
    hold = 2.9
    pedale = [26, 38]                       # ré 1, ré 2 (pédale 16' et 8')
    mains = [50, 53, 57, 62, 65, 69, 74]     # ré 3, fa 3, la 3, ré 4, fa 4, la 4, ré 5
    n = int((hold + 1.2) * SR)
    y = np.zeros(n)
    ok = False
    if vcsl.is_dir():
        try:
            import compose_musique_v70 as cm70
            cm70.VCSL = vcsl
            ped = cm70.vcsl("orgue_pedale")
            man = cm70.vcsl("orgue")
            for i, m in enumerate(pedale):
                x = ped.note(m, hold, 0.9).mean(axis=1)
                place(y, x, 0.0, 1.0)
            for i, m in enumerate(mains):
                x = man.note(m, hold - 0.03 * i, 0.85).mean(axis=1)
                place(y, x, (0.02 + 0.012 * i) * SR, 0.55)
            ok = True
        except Exception as e:  # noqa: BLE001
            print("  ! orgue de la VCSL indisponible :", e)
    if not ok:
        for i, m in enumerate(pedale + mains):
            x = orgue_additif(m, hold + 0.3)
            r = np.clip((hold + 0.3 - t_(len(x))) / 0.3, 0, 1)
            place(y, x * r, (0.012 * i) * SR, 1.0 if m < 40 else 0.55)
    t = t_(n)
    # la boîte expressive qui s'ouvre : le son enfle, s'éclaircit
    s = np.clip(t / 0.9, 0, 1) ** 1.5
    y = amb.lp(y, 900) * (1 - s) + y * s
    y *= 0.35 + 0.65 * s
    y *= np.clip((hold + 0.35 - t) / 0.35, 0, 1)
    out = salle(norm(y), 3.6, 0.55, 2600, pre=0.04, seed=1320, er=16)
    return fin(out, 5.8, 0.6)


def porte(k, creaks):
    """La lourde porte de bois qui grince en s'ouvrant."""
    dur = [2.5, 2.7][k]
    rate = [[(0, 30), (0.6, 55), (1.4, 42), (2.0, 68), (dur, 36)], [(0, 24), (0.8, 40), (1.6, 58), (2.2, 35), (dur, 28)]][k]
    res = [(170, 0.8), (390, 1.0), (760, 0.8), (1380, 0.5), (2300, 0.25)]
    g = colle_glisse(dur, rate, [(f * RNG.uniform(0.9, 1.1), a) for f, a in res], 0.06, 0.3)
    t = t_(len(g))
    g *= np.clip(t / 0.25, 0, 1) * np.clip((dur - t) / 0.4, 0, 1)
    # le poids de la porte : un frottement sourd
    rumble = amb.lp(RNG.standard_normal(len(g)), 160) * np.sin(np.pi * t / dur) * 0.4
    parts = [(norm(g), 0.0, 0.7), (norm(rumble), 0.0, 0.25)]
    if creaks:
        c = creaks[k % len(creaks)]
        c = c[:int(dur * SR)]
        tc = t_(len(c))
        c = c * np.clip((len(c) / SR - tc) / 0.4, 0, 1)
        parts.append((norm(c), 0.0, 0.85))
    out = mix(dur + 0.3, *parts)
    out = salle(norm(out), 1.6, 0.3, 3000, seed=1330 + k)
    return fin(out, dur + 0.3, 0.3)


def herse(lib):
    """La herse se lève : le treuil, son cliquet, les chaînes, le fer dans la pierre, et « clang »."""
    dur = 5.2
    stop = 4.25
    y = np.zeros(int((dur + 0.5) * SR))
    # le cliquet du treuil : « clac… clac… » (7 par seconde, qui ralentit à peine)
    tk = 0.18
    while tk < stop - 0.05:
        c = clink(RNG.uniform(1900, 2400), 0.012) + clink(RNG.uniform(3300, 3800), 0.008) * 0.5
        c = np.concatenate([c, np.zeros(200)])
        c[:int(0.03 * SR)] += np.sin(2 * np.pi * 380 * t_(int(0.03 * SR))) * np.exp(-t_(int(0.03 * SR)) / 0.008) * 0.8
        place(y, c, tk * SR, RNG.uniform(0.25, 0.35))
        tk += 1 / 7.0 * (1 + 0.05 * tk / stop) * RNG.uniform(0.95, 1.05)
    # les chaînes : des maillons qui cliquettent sans cesse
    tc = 0.15
    while tc < stop + 0.15:
        place(y, clink(RNG.uniform(1300, 4200), RNG.uniform(0.02, 0.05)), tc * SR, RNG.uniform(0.05, 0.16))
        tc += RNG.exponential(1 / 55)
    # le fer qui frotte dans les rainures de pierre (grave, qui tremble)
    n = int(stop * SR)
    t = t_(n)
    grind = amb.bp(RNG.standard_normal(n), 70, 650) * (0.6 + 0.4 * amb.smooth_env(n, 14, 0, 1))
    grind *= np.clip(t / 0.4, 0, 1) * np.clip((stop - t) / 0.08, 0, 1)
    place(y, norm(grind), 0.1 * SR, 0.3)
    groan = colle_glisse(stop, [(0, 18), (stop, 26)], [(95, 1.0), (210, 0.7), (460, 0.4)], 0.08, 0.0)
    groan *= np.clip(t / 0.5, 0, 1) * np.clip((stop - t) / 0.1, 0, 1)
    place(y, norm(groan), 0.1 * SR, 0.18)
    if lib is not None:
        bank = {}
        for key, f, semi, mx in (("r", MECA + "Ratchet Harsh 2.wav", -5, 4.2), ("c1", RPG + "chain_01.ogg", -3, 1.0),
                                 ("c2", RPG + "chain_02.ogg", -3, 1.0), ("c3", RPG + "chain_03.ogg", -4, 1.5),
                                 ("s", WM + "metal_slam_01.ogg", -7, 1.5), ("h", WM + "metal_hit_03.ogg", -5, 1.0)):
            p = lib / f
            if p.is_file():
                bank[key] = norm(fx.process(fx.read_mono(p), mx, semi, 50))
        if "r" in bank:
            r = bank["r"][:int((stop - 0.2) * SR)]
            r = r * np.clip((len(r) / SR - t_(len(r))) / 0.1, 0, 1)
            place(y, amb.lp(r, 5000), 0.2 * SR, 0.3)
        for i, at in enumerate(np.arange(0.2, stop - 0.3, 0.55)):
            key = ["c1", "c2", "c3"][i % 3]
            if key in bank:
                place(y, bank[key], (at + RNG.uniform(-0.08, 0.08)) * SR, RNG.uniform(0.22, 0.34))
        if "h" in bank:
            place(y, bank["h"], 0.0, 0.35)                     # le levier qu'on abaisse
        if "s" in bank:
            place(y, bank["s"], stop * SR, 0.8)
    # le grand « clang » : la herse arrive en haut et se bloque, le cliquet retombe, les chaînes s'apaisent
    place(y, norm(clang(RNG.uniform(150, 175))), stop * SR, 0.9)
    place(y, clink(2100, 0.02), (stop + 0.14) * SR, 0.3)
    tc = stop + 0.05
    while tc < stop + 0.7:
        place(y, clink(RNG.uniform(1500, 4000), 0.03), tc * SR, 0.1 * (1 - (tc - stop) / 0.7))
        tc += RNG.exponential(1 / 30)
    y = salle(norm(y), 2.2, 0.35, 3500, seed=1340, er=14)
    return fin(y, dur, 0.4)


def bougies(lib):
    """Le courant d'air glacé et les bougies qui s'éteignent (« fft, fft-fft… »)."""
    dur = 1.5
    w = souffle(1.3, [(0, 350), (0.35, 1500), (1.3, 500)], [(0, 300), (0.35, 1400), (1.3, 400)],
                [(0, 0), (0.3, 1.0), (0.8, 0.45), (1.3, 0)])
    sif = souffle(1.2, [(0, 900), (0.4, 1200), (1.2, 1000)], [(0, 60), (1.2, 80)], [(0, 0), (0.4, 1.0), (1.2, 0)], "white")
    parts = [(norm(w), 0.0, 0.8), (norm(sif), 0.05, 0.08)]
    for i in range(13):
        m = int(RNG.uniform(0.035, 0.07) * SR)
        tt = t_(m)
        puff = amb.bp(RNG.standard_normal(m), RNG.uniform(600, 1000), RNG.uniform(3000, 5000)) * (tt / 0.004).clip(0, 1) * np.exp(-tt / 0.018)
        puff += amb.lp(RNG.standard_normal(m), 350) * np.exp(-tt / 0.01) * 0.6
        parts.append((puff, 0.22 + 0.55 * (i / 12) ** 0.8 + RNG.uniform(-0.04, 0.04), RNG.uniform(0.25, 0.5)))
    out = mix(dur + 0.3, *parts)
    out = salle(norm(out), 1.2, 0.22, 4000, seed=1350)
    return fin(out, dur, 0.25)


def lame(m: float, dur: float, vel: float) -> np.ndarray:
    """Une lame de boîte à musique : un fondamental qui chante longtemps, des partiels de poutre
    (6,3 et 17,5 fois plus haut) qui s'éteignent vite, le petit « tic » de la goupille."""
    f = 440.0 * 2 ** ((m - 69) / 12)
    n = int((dur + 1.4) * SR)
    t = t_(n)
    y = np.sin(2 * np.pi * f * t) * np.exp(-t / 1.1)
    y += 0.35 * np.sin(2 * np.pi * f * 1.004 * t + 1.0) * np.exp(-t / 0.9)       # la lame qui bat un peu
    if 6.27 * f < 18000:
        y += 0.3 * np.sin(2 * np.pi * 6.27 * f * t) * np.exp(-t / 0.08)
    if 17.55 * f < 18000:
        y += 0.1 * np.sin(2 * np.pi * 17.55 * f * t) * np.exp(-t / 0.02)
    k = int(0.003 * SR)
    y[:k] += amb.hp(RNG.standard_normal(k), 3000) * 0.4
    return y * vel * np.clip(t / 0.0008, 0, 1)


def boite_musique():
    """La boîte à musique : une valse en ré mineur, un peu fausse, qui ralentit (le ressort se détend)."""
    mel = [("A5", 1), ("D6", 1), ("F6", 1), ("E6", 1.5), ("D6", 0.5), ("C#6", 1), ("D6", 1), ("A5", 1), ("F5", 1),
           ("G5", 1), ("F5", 1), ("E5", 1), ("F5", 1.5), ("E5", 0.5), ("D5", 1), ("D5", 3)]
    basses = [("D4", "F4 A4"), ("A3", "E4 G4"), ("D4", "F4 A4"), ("A#3", "D4 G4"), ("A3", "C#4 E4"), ("D4", "")]
    pc = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}

    def midi(s):
        return 12 * (int(s[-1]) + 1) + pc[s[0]] + (1 if "#" in s else 0)

    def quand(beat):
        """Le temps qui passe : régulier, puis de plus en plus lent sur les deux dernières mesures."""
        bs = np.linspace(0, beat, 200)
        spb = 0.25 * (1 + 1.5 * np.clip((bs - 10) / 8, 0, None) ** 2)
        return float(np.sum((spb[1:] + spb[:-1]) * 0.5 * np.diff(bs))) if beat > 0 else 0.0

    faux = -0.18                                         # toute la boîte sonne un rien trop bas
    y = np.zeros(int(8.0 * SR))
    beat = 0.0
    for p, d in mel:
        at = quand(beat)
        last = beat >= 15
        place(y, lame(midi(p) + faux + RNG.uniform(-0.12, 0.12), 0.4, 0.8 if not last else 0.55), at * SR)
        beat += d
    for bar, (b, ch) in enumerate(basses):
        at = quand(bar * 3)
        place(y, lame(midi(b) + faux + RNG.uniform(-0.1, 0.1), 0.6, 0.5), at * SR)
        for i, c in enumerate(ch.split()):
            for bb in (1, 2):
                place(y, lame(midi(c) + faux + RNG.uniform(-0.1, 0.1), 0.3, 0.22), quand(bar * 3 + bb) * SR)
    # le mécanisme : un tic-tic très faible du cylindre, qui ralentit lui aussi
    bt = 0.0
    while quand(bt) < 6.0 and bt < 18:
        m = int(0.004 * SR)
        place(y, amb.hp(RNG.standard_normal(m), 4000) * np.hanning(m), quand(bt) * SR, 0.03)
        bt += 0.25
    y = amb.lp(y, 9000) + bpf(y, 650, 2) * 0.3                   # la petite caisse de bois
    y = salle(norm(y), 1.4, 0.3, 4500, seed=1360)
    return fin(y, 6.3, 0.9)


# =================================================================== l'ambiance

def chateau_comte(lib, seconds=51.0):
    """L'intérieur du château : vent dans les couloirs, boiseries, orgue lointain, gouttes, chuchotements."""
    n = int(seconds * SR)
    t = t_(n)
    # le vent : un grave qui souffle, et les couloirs qui « chantent » (des bandes étroites qui glissent)
    base = amb.lp(amb.noise(n, "brown"), 300, 2) * amb.smooth_env(n, 0.06, 0.3, 1.0)
    left, right = base * 0.6, np.roll(base, int(0.5 * SR)) * 0.6
    for side in range(2):
        for v in range(2):
            fpts = [(x, RNG.uniform(260, 620)) for x in np.linspace(0, seconds, 9)]
            apts = [(x, RNG.uniform(0.0, 1.0) ** 2) for x in np.linspace(0, seconds, 14)]
            moan_w = spectre(amb.noise(n, "pink"), lambda f, tt: (bosse(f, courbe(fpts, tt), 18) + 0.35 * bosse(f, 2 * courbe(fpts, tt), 30))
                             * courbe(apts, tt), 4096)
            (left if side == 0 else right)[:] += norm(moan_w) * 0.35
    # le bourdon d'orgue, très lointain (ré et la graves), qui respire lentement
    org = np.zeros(n)
    for m, g in ((38, 1.0), (45, 0.6), (26, 0.5)):
        f = 440.0 * 2 ** ((m - 69) / 12)
        for h, a in ((1, 1.0), (2, 0.5), (3, 0.3), (4, 0.15), (6, 0.06)):
            org += g * a * np.sin(2 * np.pi * f * h * t + RNG.uniform(0, 6))
    org = amb.lp(org, 700) * amb.smooth_env(n, 0.05, 0.35, 1.0)
    left += norm(org) * 0.09
    right += norm(org) * 0.09
    # les boiseries qui craquent (la banque, descendue ; et des grincements synthétisés)
    cr = []
    if lib is not None:
        for f in [WM + "wood_squeak_01.ogg", WM + "wood_squeak_02.ogg", KRPG + "creak1.ogg", KRPG + "creak2.ogg", WM + "wood_cracking_01.ogg"]:
            p = lib / f
            if p.is_file():
                cr.append(norm(amb.lp(fx.process(fx.read_mono(p), 2.5, -5, 80), 2200)))
    for k in range(3):
        d = RNG.uniform(0.6, 1.1)
        c = colle_glisse(d, [(0, RNG.uniform(20, 30)), (d, RNG.uniform(35, 55))], [(200, 0.8), (450, 1.0), (900, 0.6), (1700, 0.3)], 0.06)
        tc = t_(len(c))
        cr.append(norm(amb.lp(c * np.sin(np.pi * tc / d), 2500)))
    for k in range(7):
        at = int((k + RNG.uniform(0.1, 0.9)) / 7 * seconds * SR)
        pan = RNG.uniform(-1, 1)
        c = cr[k % len(cr)] * RNG.uniform(0.06, 0.12)
        place_loop(left, c * (1 - pan) * 0.5, at)
        place_loop(right, c * (1 + pan) * 0.5, at)
    # les gouttes d'eau (assez rares, avec l'écho de la pierre)
    for k in range(14):
        d = amb.drip(int(RNG.integers(0, 3)))
        at = int(RNG.uniform(0, seconds) * SR)
        pan = RNG.uniform(-1, 1)
        g = RNG.uniform(0.03, 0.07)
        place_loop(left, d * g * (1 - pan) * 0.5, at)
        place_loop(right, d * g * (1 + pan) * 0.5, at)
    # de rares chuchotements, très loin
    for k in range(3):
        w = voix_chuchotee(PHRASES[(k * 2 + 1) % len(PHRASES)], RNG.uniform(0.9, 1.1))
        if k == 1:
            w = w[::-1].copy()
        w = amb.lp(norm(w), 2600) * RNG.uniform(0.05, 0.08)
        at = int((k + RNG.uniform(0.2, 0.8)) / 3 * seconds * SR)
        pan = RNG.uniform(-0.8, 0.8)
        for d, gg in ((0.0, 1.0), (0.29, 0.4), (0.63, 0.2)):
            place_loop(left, w * gg * (1 - pan) * 0.5, at + int(d * SR))
            place_loop(right, w * gg * (1 + pan) * 0.5, at + int(d * SR))
    # la grande salle de pierre : réverbération circulaire (la queue revient au début : rien ne coupe)
    out = []
    for c, ch in enumerate((left, right)):
        wet = salle(ch, 2.8, 1.0, 2500, pre=0.03, seed=1370 + c)
        rv = wet[:n].copy()
        rv[:len(wet) - n] += wet[n:]
        out.append(ch * 0.75 + rv * 0.5)
    st = amb.stereo(out[0], out[1])
    return amb.loopify(st, 3.0)


def main() -> int:
    args = sys.argv[1:]
    vcsl = VCSL
    if "--vcsl" in args:
        i = args.index("--vcsl")
        vcsl = Path(args[i + 1])
        del args[i:i + 2]
    lib = Path(args[0]) if args else Path("/root/snd/CC0-Public-Domain-Sounds")
    if not lib.is_dir():
        lib = None
    h_lib = lib_pitched(lib, [CRE2 + "misc_14.ogg", CRE + "alien_05.ogg", CRE + "alien_06.ogg", CRE2 + "alien_08.ogg"], -2, 9000)
    a_lib = lib_pitched(lib, [CRE2 + "attack_02.ogg", CRE2 + "attack_03.ogg", CRE + "monster_02.ogg"], -3, 5000)
    s_lib = lib_pitched(lib, [CRE + "scream_01.ogg", CRE + "scream_02.ogg", CRE + "howl.ogg"], 1, 8000)
    sw_lib = lib_pitched(lib, [WOOSH + "Classic Swish 1.wav", WOOSH + "Classic Swish 3.wav", WOOSH + "Swish 3.wav"], -3, 6000)
    br_lib = lib_pitched(lib, [WOOSH + "Gentle Swish.wav", WOOSH + "Swish 6.wav"], -9, 3000)
    door_lib = lib_pitched(lib, [SFX1 + "door_01.ogg", SFX1 + "door_02.ogg"], -3, 5000, max_s=3.2, hp_hz=60)
    for k in range(4):
        fx.save(f"vampire_siffle_{k + 1}", siffle(k, h_lib))
    for k in range(3):
        fx.save(f"vampire_rire_{k + 1}", rire(k))
        fx.save(f"vampire_attaque_{k + 1}", attaque(k, a_lib, sw_lib))
        fx.save(f"vampire_mort_{k + 1}", mort(k, s_lib))
        fx.save(f"murmures_{k + 1}", murmures(k))
    for k in range(2):
        fx.save(f"vampire_brume_{k + 1}", brume(k, br_lib))
        fx.save(f"nuee_chauves_souris_{k + 1}", nuee(k))
        fx.save(f"porte_grince_{k + 1}", porte(k, door_lib))
    fx.save("orgue_accord_1", orgue_accord(vcsl))
    fx.save("herse_monte_1", herse(lib))
    fx.save("bougies_soufflees_1", bougies(lib))
    fx.save("boite_musique_1", boite_musique())
    amb.save("ambiance/chateau_comte", chateau_comte(lib))
    print("V124 : les sons du château du comte sont faits")
    return 0


if __name__ == "__main__":
    sys.exit(main())
