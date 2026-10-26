"""V75 : les musiques de l'Île du Boucan (Port-Boucan, la ville libre des punks, la Halle Hurlante et
les Rats de Cale, la Cathédrale des Spores, l'Usine Grise de Lisse & Fils et la Grande Pelleteuse).

Compositions originales pour « Les Mondes de Travers », versées au domaine public (CC0 1.0). Un groupe
de punk-rock joué « en vrai » dans une salle : tout est fabriqué ici (numpy/scipy), à partir de vrais
échantillons libres de droits pour la batterie et les cuivres.
  - la batterie : des fûts et des cymbales enregistrés de la « Versilian Community Sample Library »
    (VCSL, Versilian Studios, CC0 1.0 : grosse caisse, caisses claires modernes (timbre, bord, rim),
    charleston (fermé, ouvert, au pied), cymbales suspendues (crash, ride, cloche), toms, claquements
    de mains, tambourin), chaque coup avec ses variations (nuances, alternance des baguettes), un peu
    d'humain dans la mise en place, des micros de salle ; la grosse caisse est « rock » : l'échantillon
    raccourci, la batte (un clic) et un sub ajoutés ;
  - les guitares électriques : des cordes pincées de Karplus-Strong (ligne à retard fractionnaire, la
    perte d'aigus de la corde, la position du médiator et du micro), jouées en quintes (« power
    chords » : fondamentale, quinte, octave), étouffées de la paume en croches, à grands coups ouverts,
    en contretemps « ska » ; la ligne directe (« DI ») de chaque guitare passe dans un ampli simulé :
    pré-filtre, gain, écrêtage doux puis dur, asymétrique, puis le baffle (bosse à 110 Hz, creux des
    médiums, présence à 2,7 kHz, coupure raide vers 5 kHz) ; chaque partie est jouée deux fois (deux
    prises, deux réglages) à gauche et à droite ;
  - la basse : une corde de Karplus-Strong grave, attaquée au médiator, un peu saturée, qui suit les
    fondamentales en croches (ou qui « marche » pour le ska) ;
  - la guitare solo : la même corde, avec vibrato, tirés et glissés (la hauteur change période par
    période), dans l'ampli, avec un écho ;
  - l'orgue « combo » un peu jouet (synthèse additive, vibrato, petit haut-parleur tournant), la
    trompette et le trombone (VSCO-2 CE, Versilian Studios, CC0), la sourdine « harmon » la nuit ;
  - la foule (dans la Halle) : des voix synthétisées (source glottique et formants, comme les foules
    de la V70) qui crient « Hé ! » en chœur ou chantent « Oh-oh » avec le groupe, des sifflets, des
    applaudissements (claquements de mains de la VCSL), le brouhaha ;
  - la Cathédrale des Spores : verres frottés (harmonica de verre), carillons à main, glockenspiel,
    harpe, cordes douces (VSCO-2 CE, VCSL), un célesta et des nappes synthétisés ;
  - l'Usine Grise : enclumes, tambour de frein, cloche de vache, claves (VSCO-2 CE, VCSL), pizzicati,
    basson, une basse de synthèse, des jets de vapeur et des « clang » synthétisés.

Les morceaux :
  boucan.ogg            « Port-Boucan », le thème de la ville, le jour : ska-punk en sol majeur, 152 à la
                        noire, en boucle (76 mesures, 2 min). La guitare « skank » en contretemps, l'orgue
                        qui fait des bulles, la basse qui marche, la trompette et le trombone chantent
                        l'air, un couplet punk à toute allure, une pause « dub », et la boucle repart.
  boucan_nuit.ogg       « Port-Boucan, la nuit » : dub tranquille en la mineur, 72 à la noire (« one
                        drop »), en boucle (36 mesures, 2 min) ; l'écho qui se répète, la trompette en
                        sourdine, l'orgue, la basse ronde.
  concert_1.ogg         « Les Rats de Cale » : la majeur, 184 à la noire, 2 min 30 :
                        le décompte aux baguettes, le riff, couplets étouffés, refrains ouverts avec la
                        foule qui crie « Hé ! », un pont, le dernier refrain un ton plus haut, la grande fin.
  concert_2.ogg         « Rangers et Pâquerettes » : mi, 200, 2 min 10, le plus rapide (« skank beat ») :
                        larsen comique, riff, refrains « Hé ! Hé ! », un passage lourd, un solo de guitare.
  concert_3.ogg         « Tout le Monde Chante » : l'hymne, ré majeur, 160, 2 min 30 : la guitare seule et
                        les mains de la foule, puis tout le groupe ; la foule chante « Oh-oh-oh » ; un pont
                        tout doux, et le dernier refrain en mi, tous ensemble.
  concert_gedeon.ogg    « Gédéon Tape Fort » : sol, 192, 2 min 25 : le nouveau batteur ouvre par un solo
                        (roulements de toms, double grosse caisse, cymbales), le groupe entre ; des
                        « breaks » où la batterie répond au groupe, un second solo, et un final énorme.
  (Les quatre concerts sont entendus DANS la Halle : la salle, la foule ; ils ne bouclent pas, chacun a son
  début et sa fin, avec les bravos.)
  spores.ogg            « La Cathédrale des Spores » : fa lydien, 66 à la noire, en boucle (32 mesures,
                        2 min) : l'harmonica de verre, le célesta, les carillons, la harpe, les cordes douces.
  usine_grise.ogg       « L'Usine Grise » : ré mineur, 116, en boucle (58 mesures, 2 min) : les machines en
                        rythme (enclumes, tambour de frein, cloche, vapeur), la basse de synthèse, les
                        pizzicati, le basson qui fait le malin, les cordes graves.
  grande_pelleteuse.ogg « La Grande Pelleteuse » (le boss) : ré mineur (guitares accordées en ré grave),
                        168, en boucle (84 mesures, 2 min) : punk-métal au galop, double grosse caisse, la
                        machine qui souffle (vérins hydrauliques), les cuivres héroïques et comiques.

Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/compose_musique_v75.py [--vsco <dossier VSCO-2-CE>] [--vcsl <dossier VCSL>]
                                               [--cc0 <dossier CC0-Public-Domain-Sounds>] [morceaux...]
(par défaut, les banques sont cherchées dans /root/snd ; la VCSL doit contenir, en plus des dossiers des
versions précédentes : « Hi-Hat Cymbal », « Snare Drum, Modern 1/2/3 », « Bass Drum 1 », « Tom 2 »,
« Legacy Toms », « Suspended Cymbal 1/2 », « Woodblock » (git sparse-checkout add …))
"""
from __future__ import annotations

from pathlib import Path
import gc
import math
import subprocess
import sys
import tempfile
import zlib

import numpy as np
from scipy import signal
from scipy.io import wavfile
from scipy.ndimage import minimum_filter1d, uniform_filter1d

sys.path.insert(0, str(Path(__file__).resolve().parent))
import orchestre_v51 as orch  # noqa: E402

SR = 44100
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "sons" / "musique"
SND = Path("/root/snd")
VSCO = SND / "VSCO-2-CE"
VCSL = SND / "VCSL"
CC0 = SND / "CC0-Public-Domain-Sounds"
TMP = Path(tempfile.gettempdir()) / "musique_v75"
DEBUG = False

ST = "Idiophones/Struck Idiophones/"
MB = "Membranophones/Struck Membranophones/"
PC = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


# =========================================================================== outils

def midi_of(name: str) -> int:
    return orch.midi_of(name)


def hz(m: float) -> float:
    return 440.0 * 2 ** ((m - 69) / 12.0)


def bw(kind: str, f, order: int = 2):
    return signal.butter(order, f, btype=kind, fs=SR, output="sos")


def peak(f: float, gain_db: float, q: float = 1.0):
    """Correcteur en cloche (RBJ)."""
    a = 10 ** (gain_db / 40)
    w0 = 2 * np.pi * f / SR
    al = np.sin(w0) / (2 * q)
    b = [1 + al * a, -2 * np.cos(w0), 1 - al * a]
    d = [1 + al / a, -2 * np.cos(w0), 1 - al / a]
    return np.array([[b[0] / d[0], b[1] / d[0], b[2] / d[0], 1.0, d[1] / d[0], d[2] / d[0]]])


def shelf(f: float, gain_db: float, high: bool = True):
    """Plateau (RBJ, pente 1)."""
    a = 10 ** (gain_db / 40)
    w0 = 2 * np.pi * f / SR
    al = np.sin(w0) / 2 * np.sqrt(2)
    c = np.cos(w0)
    s = 1 if high else -1
    b0 = a * ((a + 1) + s * (a - 1) * c + 2 * np.sqrt(a) * al)
    b1 = -2 * s * a * ((a - 1) + s * (a + 1) * c)
    b2 = a * ((a + 1) + s * (a - 1) * c - 2 * np.sqrt(a) * al)
    a0 = (a + 1) - s * (a - 1) * c + 2 * np.sqrt(a) * al
    a1 = 2 * s * ((a - 1) - s * (a + 1) * c)
    a2 = (a + 1) - s * (a - 1) * c - 2 * np.sqrt(a) * al
    return np.array([[b0 / a0, b1 / a0, b2 / a0, 1.0, a1 / a0, a2 / a0]])


def filt(x: np.ndarray, *soss) -> np.ndarray:
    for s in soss:
        x = signal.sosfilt(s, x, axis=0)
    return x


def lp(x, f, order=2):
    return filt(x, bw("lowpass", f, order))


def hp(x, f, order=2):
    return filt(x, bw("highpass", f, order))


def bp(x, lo, hi, order=2):
    return filt(x, bw("bandpass", [lo, hi], order))


def pan2(x: np.ndarray, pan: float = 0.0, width: float = 1.0) -> np.ndarray:
    """Mono ou stéréo -> stéréo placé (loi à puissance constante, centre = gain 1)."""
    th = (pan + 1) * np.pi / 4
    gl, gr = np.cos(th) * np.sqrt(2), np.sin(th) * np.sqrt(2)
    if x.ndim == 1:
        return np.stack([x * gl, x * gr], axis=1)
    m = x.mean(axis=1)
    sd = (x[:, 0] - x[:, 1]) * 0.5 * width
    return np.stack([m * gl + sd, m * gr - sd], axis=1)


def fade(x: np.ndarray, fin: float = 0.002, fout: float = 0.01) -> np.ndarray:
    n = len(x)
    a, b = min(n, int(fin * SR)), min(n, int(fout * SR))
    y = x.copy()
    if a > 1:
        y[:a] *= np.linspace(0, 1, a)[:, None] if y.ndim == 2 else np.linspace(0, 1, a)
    if b > 1:
        y[-b:] *= np.linspace(1, 0, b)[:, None] if y.ndim == 2 else np.linspace(1, 0, b)
    return y


def resample(x: np.ndarray, ratio: float) -> np.ndarray:
    """Transposition par rééchantillonnage (ratio > 1 : plus aigu, plus court)."""
    if abs(ratio - 1.0) < 1e-6:
        return x
    pos = np.arange(0, len(x) - 1, ratio)
    if x.ndim == 1:
        return np.interp(pos, np.arange(len(x)), x)
    return np.stack([np.interp(pos, np.arange(len(x)), x[:, c]) for c in range(x.shape[1])], axis=1)


def read(path: Path) -> np.ndarray:
    """Un échantillon (wav, ou ogg via ffmpeg), stéréo float32 à 44,1 kHz."""
    if path.suffix.lower() == ".wav":
        return orch._read(path)
    d = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "-ac", "2", "-ar", str(SR), "-"],
                       capture_output=True, check=True).stdout
    return np.frombuffer(d, np.float32).reshape(-1, 2).copy()


def trim_head(x: np.ndarray, thr: float = 0.04, pre: float = 0.002) -> np.ndarray:
    e = np.abs(x).max(axis=1) if x.ndim == 2 else np.abs(x)
    i = int(np.argmax(e > e.max() * thr))
    return x[max(0, i - int(pre * SR)):]


def circ_conv(x: np.ndarray, ir: np.ndarray) -> np.ndarray:
    """Convolution circulaire (pour une boucle : la queue de réverbération revient au début)."""
    n = len(x)
    out = np.empty_like(x)
    for c in range(x.shape[1]):
        X = np.fft.rfft(x[:, c], n)
        H = np.fft.rfft(ir[: n, c % ir.shape[1]], n)
        out[:, c] = np.fft.irfft(X * H, n)
    return out


def room_ir(seconds: float, dark: float = 0.6, predelay: float = 0.012, er: int = 16, seed: int = 7,
            er_span: float = 0.05) -> np.ndarray:
    """Réponse d'une salle (bruit qui décroît, aigus qui s'éteignent plus vite, premières réflexions)."""
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    t = np.arange(n) / SR
    noise = rng.standard_normal((n, 2))
    t60 = seconds * 0.8
    low = signal.sosfilt(bw("lowpass", 1500), noise, axis=0)
    high = noise - low
    ir = low * np.exp(-6.9 * t / t60)[:, None] + high * np.exp(-6.9 * t / (t60 * (1 - 0.65 * dark)))[:, None] * 0.6
    ir *= 0.22
    for k in range(er):
        d = int(rng.uniform(0.004, er_span) * SR)
        ir[d, k % 2] += rng.uniform(0.25, 0.6) * (1 if k % 3 else -1)
    ir *= np.minimum(1.0, t / 0.008)[:, None]
    ir = np.concatenate([np.zeros((int(predelay * SR), 2)), ir])
    ir /= np.sqrt(np.sum(ir ** 2) / 2)
    return ir.astype(np.float32)


def compress(x: np.ndarray, thr_db: float, ratio: float, tau: float = 0.03, rel: float = 0.15,
             makeup_db: float = 0.0) -> np.ndarray:
    """Compresseur (détection RMS, gain lissé) : colle les instruments ensemble."""
    m = x if x.ndim == 1 else np.max(np.abs(x), axis=1)
    a = np.exp(-1.0 / (tau * SR))
    env = np.sqrt(np.maximum(signal.lfilter([1 - a], [1, -a], m.astype(np.float64) ** 2), 1e-12))
    lev = 20 * np.log10(env + 1e-9)
    gr = np.minimum(0.0, -(lev - thr_db) * (1 - 1 / ratio))
    b = np.exp(-1.0 / (rel * SR))
    gr = signal.lfilter([1 - b], [1, -b], gr)
    g = 10 ** ((gr + makeup_db) / 20)
    return (x * (g[:, None] if x.ndim == 2 else g)).astype(np.float32)


def limit(x: np.ndarray, ceil: float, win: float = 0.008) -> np.ndarray:
    """Limiteur à anticipation : le gain ne laisse jamais dépasser le plafond (min glissant puis
    moyenne glissante de même largeur : la courbe reste sous le gain nécessaire en tout point)."""
    a = np.max(np.abs(x), axis=1) if x.ndim == 2 else np.abs(x)
    g = np.minimum(1.0, ceil / np.maximum(a, 1e-9))
    w = max(3, int(win * SR) | 1)
    g = minimum_filter1d(g, w, mode="nearest")
    g = uniform_filter1d(g, w, mode="nearest")
    y = x * (g[:, None] if x.ndim == 2 else g)
    return np.clip(y, -ceil, ceil).astype(np.float32)


def lufs(x: np.ndarray) -> float:
    """Sonie intégrée approchée (pondération K, porte relative à -10 LU sur blocs de 400 ms)."""
    y = filt(x.astype(np.float64), shelf(1500.0, 4.0, True), bw("highpass", 38.0))
    p = (y ** 2).sum(axis=1)
    blk = int(0.4 * SR)
    hop = int(0.1 * SR)
    c = np.concatenate([[0.0], np.cumsum(p)])
    idx = np.arange(0, len(p) - blk, hop)
    if len(idx) == 0:
        return -70.0
    z = (c[idx + blk] - c[idx]) / blk
    ok = z > 10 ** ((-70 + 0.691) / 10)
    z = z[ok]
    g = -0.691 + 10 * np.log10(z.mean() + 1e-12)
    z2 = z[-0.691 + 10 * np.log10(z + 1e-12) > g - 10]
    return float(-0.691 + 10 * np.log10(z2.mean() + 1e-12))


def preroll(fn, x: np.ndarray, loop: bool, k_s: float = 6.0) -> np.ndarray:
    """Applique un traitement à mémoire (filtres, compresseur, ampli) à une boucle sans raccord : on
    le fait tourner d'abord sur la fin de la boucle, puis on jette ce morceau."""
    if not loop:
        return fn(x)
    k = min(len(x) // 2, int(k_s * SR))
    y = fn(np.concatenate([x[-k:], x]))
    return y[k:]


# =========================================================================== la corde pincée

def string(f0: float, dur: float, rng, t60: float = 2.5, bright: float = 0.5, pick: float = 0.13, vel: float = 1.0,
           fmul=None, pickup: float = 0.0, hard: float = 0.5) -> np.ndarray:
    """Une corde de Karplus-Strong accordée juste : une période de bruit (médiator plus ou moins dur,
    position du médiator : filtre en peigne), puis la boucle de retard fractionnaire (4 prises) avec
    sa perte d'aigus (bright : 0 très feutrée … 1 claire) et sa durée de résonance t60. fmul : la
    hauteur multipliée échantillon par échantillon (vibrato, tirés, glissés), relue à chaque période.
    pickup : position du micro (peigne en sortie), 0 = pas de micro (corde acoustique)."""
    n = max(8, int(dur * SR))
    f_start = f0 * (float(fmul[0]) if fmul is not None else 1.0)
    d0 = SR / f_start
    L = max(4, int(d0))
    off = 8 + (int(SR / (f0 * float(np.min(fmul)))) if fmul is not None else 0)
    y = np.zeros(n + L + off + 8)
    ex = rng.uniform(-1, 1, L)
    a = 0.7 * (1 - hard)
    ex = signal.lfilter([1 - a], [1, -a], ex)
    p = max(1, int(L * pick))
    ex[p:] = ex[p:] - 0.9 * ex[:-p]
    ex -= ex.mean()
    ex /= np.max(np.abs(ex)) + 1e-9
    y[off:off + L] = ex * vel
    s = off + L
    end = off + n
    bb = float(np.clip(bright, 0.0, 1.0))
    base0 = np.array([0.25, 0.5, 0.25, 0.0]) * (1 - bb) + np.array([0.0, 1.0, 0.0, 0.0]) * bb
    base1 = np.array([0.0, 0.25, 0.5, 0.25]) * (1 - bb) + np.array([0.0, 0.0, 1.0, 0.0]) * bb
    while s < end:
        f = f0 if fmul is None else f0 * float(fmul[min(len(fmul) - 1, s - off)])
        d = SR / f
        N = int(d) - 1
        fr = d - 1 - N
        if N < 4:
            N, fr = 4, 0.0
        g = 10 ** (-3.0 / (t60 * f))
        w = (1 - fr) * base0 + fr * base1
        Lb = min(N, end - s)
        acc = w[0] * y[s - N:s - N + Lb]
        for j in (1, 2, 3):
            if w[j] != 0.0:
                acc = acc + w[j] * y[s - N - j:s - N - j + Lb]
        y[s:s + Lb] = g * acc
        s += Lb
    out = y[off:end].copy()
    out[:40] *= np.linspace(0.0, 1.0, 40)          # le médiator quitte la corde (pas de marche brutale)
    if pickup > 0:
        k = max(1, int(d0 * pickup))
        out = out.copy()
        out[k:] -= 0.7 * out[:-k].copy()
    return out


def choke(x: np.ndarray, keep: float, rel: float = 0.012) -> np.ndarray:
    """La note étouffée au bout de « keep » secondes (la main se pose sur les cordes)."""
    k = int(keep * SR)
    r = max(2, int(rel * SR))
    if k >= len(x):
        return x
    y = x[: k + r].copy()
    ramp = np.linspace(1, 0, len(y) - k) ** 2
    y[k:] *= ramp[:, None] if y.ndim == 2 else ramp
    return y


# =========================================================================== la batterie

class Kit:
    """La batterie (VCSL, CC0) : chaque élément a ses échantillons triés par nuance, alternés ; la
    grosse caisse est rendue « rock » (attaque de la batte, sub, échantillon raccourci)."""

    def __init__(self, seed: int = 75):
        self.rng = np.random.default_rng(seed)
        self.p: dict[str, list[list[np.ndarray]]] = {}
        self.rr: dict[str, int] = {}

        def grab(pattern: str, maxlen: float, root: Path = VCSL, fout: float = 0.05, filt_fn=None, ratio: float = 1.0):
            files = sorted(root.glob(pattern))
            out = []
            for f in files:
                x = trim_head(read(f), 0.05, 0.001)
                if ratio != 1.0:
                    x = resample(x, ratio)
                x = x[: int(maxlen * SR)]
                x = fade(x, 0.0005, min(fout, len(x) / SR / 2))
                if filt_fn is not None:
                    x = filt_fn(x)
                out.append((f.stem, x.astype(np.float32)))
            return out

        def layered(items, key=lambda s: s, norm: float = 0.5, tilt: float = 0.5):
            """Groupe par nuance (v1, v2… dans le nom), normalise chaque coup puis redonne la pente
            des nuances (le coup fort reste plus fort)."""
            import re
            groups: dict[int, list] = {}
            for stem, x in items:
                m = re.search(r"_v(\d)", stem) or re.search(r"_(pp|mp|mf|ff|fff|f|p)(\d|_|$)", stem)
                if m and m.group(1).isdigit():
                    lv = int(m.group(1))
                elif m:
                    lv = ["pp", "p", "mp", "mf", "f", "ff", "fff"].index(m.group(1)) + 1
                else:
                    lv = 1
                groups.setdefault(lv, []).append(x)
            lvs = sorted(groups)
            res = []
            for i, lv in enumerate(lvs):
                g = norm * (1 - tilt + tilt * (i + 1) / len(lvs))
                res.append([x / (np.max(np.abs(x)) + 1e-9) * g for x in groups[lv]])
            return res

        # grosse caisse : l'échantillon (Bass Drum 1) raccourci, creusé, la batte et le sub ajoutés
        def kick_fx(x):
            n = len(x)
            t = np.arange(n) / SR
            env = np.where(t < 0.03, 1.0, np.exp(-(t - 0.03) / 0.11))
            y = x * env[:, None]
            y = filt(y, bw("highpass", 38), peak(70, 4, 1.0), peak(380, -8, 1.2), peak(3800, 5, 1.0))
            m = int(0.25 * SR)
            tt = np.arange(m) / SR
            sub = np.sin(2 * np.pi * np.cumsum(52 + 70 * np.exp(-tt / 0.018)) / SR) * np.exp(-tt / 0.1)
            cl = signal.sosfilt(bw("bandpass", [1800, 6500]), self.rng.standard_normal(m)) * np.exp(-tt / 0.0025)
            add = np.zeros((n, 2))
            k = min(n, m)
            add[:k] += ((sub * 0.55 + cl * 0.35)[:k])[:, None]
            y = y / (np.max(np.abs(y)) + 1e-9) + add
            return np.tanh(y * 1.2)
        self.p["kick"] = layered(grab(MB + "Bass Drum 1/BDrumNew_hit_*.wav", 0.42, fout=0.12, filt_fn=kick_fx), tilt=0.35)
        snare_fx = lambda x: filt(x, bw("highpass", 90), peak(210, 3, 1.2), peak(900, -2, 1.0), peak(5200, 3, 0.9))
        self.p["snare"] = layered(grab(MB + "Snare Drum, Modern 1/Snare2_HitSN_*.wav", 0.55, fout=0.2, filt_fn=snare_fx), tilt=0.6)
        self.p["rim"] = layered(grab(MB + "Snare Drum, Modern 3/Snare4_rimshot_*.wav", 0.6, fout=0.2, filt_fn=snare_fx), tilt=0.3)
        self.p["xstick"] = layered(grab(MB + "Snare Drum, Modern 2/Snare3M_Xstick_*.wav", 0.35, fout=0.1), tilt=0.0)
        self.p["ghost"] = layered(grab(MB + "Snare Drum, Modern 2/Snare3M_HitSN_v2_*.wav", 0.4, fout=0.15, filt_fn=snare_fx), tilt=0.0)
        hat_fx = lambda x: filt(x, bw("highpass", 350), peak(9000, 2, 0.8))
        self.p["hat"] = layered(grab(ST + "Hi-Hat Cymbal/HiHat_HitC_*.wav", 0.35, fout=0.08, filt_fn=hat_fx), tilt=0.6)
        self.p["hat_open"] = layered(grab(ST + "Hi-Hat Cymbal/HiHat_HitO_*.wav", 2.0, fout=0.6, filt_fn=hat_fx), tilt=0.0)
        self.p["hat_loose"] = layered(grab(ST + "Hi-Hat Cymbal/HiHat_HitLoose_*.wav", 0.9, fout=0.3, filt_fn=hat_fx), tilt=0.0)
        self.p["hat_pedal"] = layered(grab(ST + "Hi-Hat Cymbal/HiHat_Close_*.wav", 0.3, fout=0.08, filt_fn=hat_fx), tilt=0.0)
        cym_fx = lambda x: filt(x, bw("highpass", 250))
        self.p["crash"] = layered(grab(ST + "Suspended Cymbal 2/susCymb2_hit_[fm]*1.wav", 4.0, fout=1.5, filt_fn=cym_fx), tilt=0.4)
        self.p["crash2"] = layered(grab(ST + "Suspended Cymbal 1/susCymb1_hit_[fm]*1.wav", 4.0, fout=1.5, filt_fn=cym_fx, ratio=1.12), tilt=0.4)
        self.p["china"] = layered(grab(ST + "Suspended Cymbal 2/susCymb2_hit_fff1.wav", 3.0, fout=1.2, filt_fn=lambda x: filt(x, bw("highpass", 600), peak(3000, 5, 1.5)), ratio=1.3), tilt=0.0)
        self.p["ride"] = layered(grab(ST + "Suspended Cymbal 2/susCymb2_hit_stick_*.wav", 1.6, fout=1.0, filt_fn=cym_fx, ratio=1.15), tilt=0.5)
        self.p["bell"] = layered(grab(ST + "Suspended Cymbal 2/susCymb2_hit_bell_*.wav", 1.4, fout=0.9, filt_fn=cym_fx, ratio=1.2), tilt=0.4)
        tom_fx = lambda x: filt(x, bw("highpass", 60), peak(3500, 3, 1.0))
        self.p["tom1"] = layered(grab(MB + "Legacy Toms/tenor_higher/tenorH_f*_rr*.wav", 0.7, fout=0.3, filt_fn=tom_fx, ratio=0.84), tilt=0.3)
        self.p["tom2"] = layered(grab(MB + "Tom 1/Stick/TomH_HitS_*.wav", 0.9, fout=0.35, filt_fn=tom_fx, ratio=1.06), tilt=0.3)
        self.p["tom3"] = layered(grab(MB + "Tom 2/Stick/TomL_HitS_*.wav", 1.0, fout=0.4, filt_fn=tom_fx, ratio=0.94), tilt=0.3)
        self.p["tom4"] = layered(grab(MB + "Tom 2/Stick/TomL_HitS_*.wav", 1.2, fout=0.45, filt_fn=tom_fx, ratio=0.76), tilt=0.3)
        self.p["clap"] = layered(grab(ST + "Claps/Clap_rr*.wav", 0.4, fout=0.1), tilt=0.0)
        self.p["tamb"] = layered(grab(ST + "Tambourine 1/Tamb1_Hit_*.wav", 0.5, fout=0.15), tilt=0.3)
        self.p["cowbell"] = layered(grab("Percussion/Cowbell1_Hit_*.wav", 0.6, root=VSCO, fout=0.2), tilt=0.3)
        self.p["anvil"] = layered(grab("Percussion/Anvil_Hit1_*.wav", 1.2, root=VSCO, fout=0.5), tilt=0.3)
        self.p["brake"] = layered(grab("Percussion/BrakeDrum1_Hammer_*.wav", 1.0, root=VSCO, fout=0.4), tilt=0.3)
        self.p["claves"] = layered(grab("Percussion/Claves1_Hit_*.wav", 0.4, root=VSCO, fout=0.1), tilt=0.3)
        self.p["wood"] = layered(grab(ST + "Woodblock/wood_click*.wav", 0.4, fout=0.1), tilt=0.3)
        self.p["sticks"] = layered(grab(MB + "Snare Drum, Modern 3/Snare4_stick_*.wav", 0.3, fout=0.1), tilt=0.0)
        # où chaque élément est placé (vu de la salle) et sur quel bus
        self.where = {"kick": (0.0, "kick"), "snare": (0.05, "snare"), "rim": (0.05, "snare"), "ghost": (0.05, "snare"),
                      "xstick": (0.05, "snare"), "hat": (0.35, "hats"), "hat_open": (0.35, "hats"),
                      "hat_loose": (0.35, "hats"), "hat_pedal": (0.35, "hats"), "crash": (-0.45, "cym"),
                      "crash2": (0.5, "cym"), "china": (0.65, "cym"), "ride": (-0.4, "cym"), "bell": (-0.4, "cym"),
                      "tom1": (0.25, "toms"), "tom2": (0.0, "toms"), "tom3": (-0.3, "toms"), "tom4": (-0.5, "toms"),
                      "clap": (0.0, "perc"), "tamb": (0.55, "perc"), "cowbell": (-0.3, "perc"), "anvil": (0.4, "perc"),
                      "brake": (-0.35, "perc"), "claves": (0.3, "perc"), "wood": (-0.25, "perc"), "sticks": (0.0, "snare")}

    def get(self, piece: str, vel: float) -> np.ndarray:
        layers = self.p[piece]
        li = min(len(layers) - 1, int(np.clip(vel, 0, 0.999) * len(layers)))
        pool = layers[li]
        self.rr[piece] = self.rr.get(piece, 0) + 1
        x = pool[(self.rr[piece] + int(self.rng.integers(0, 2))) % len(pool)]
        return x * (0.45 + 0.55 * vel)


# =========================================================================== le morceau

class Song:
    """Une partition : les bus stéréo (batterie, cuivres…), les lignes directes mono des guitares et de
    la basse (passées dans l'ampli au rendu), la réverbération de la salle, le mastering."""

    def __init__(self, name: str, bpm: float, bars: int, beats: int = 4, loop: bool = True, seed: int = 1,
                 swing: float = 0.0, lead_in: float = 0.0, tail: float = 8.0):
        self.name = name
        self.bpm = bpm
        self.beats = beats
        self.bars = bars
        self.spb = 60.0 / bpm
        self.loop = loop
        self.swing = swing
        self.lead_in = lead_in
        self.n = int(round((bars * beats * self.spb + lead_in) * SR))
        self.tail = int(tail * SR)
        self.buses: dict[str, np.ndarray] = {}
        self.dis: dict[str, np.ndarray] = {}
        self.fx: dict[str, object] = {}
        self.send: dict[str, float] = {}
        self.rng = np.random.default_rng(seed)
        self.seed = seed

    # --- le temps
    def t(self, bar: float, beat: float = 0.0) -> float:
        pos = bar * self.beats + beat
        if self.swing:
            whole = math.floor(pos)
            u = pos - whole
            s = 0.5 + self.swing
            u = u / 0.5 * s if u < 0.5 else s + (u - 0.5) / 0.5 * (1 - s)
            pos = whole + u
        return pos * self.spb + self.lead_in

    # --- poser des sons
    def _buf(self, d: dict, name: str, stereo: bool) -> np.ndarray:
        if name not in d:
            d[name] = np.zeros((self.n + self.tail, 2) if stereo else self.n + self.tail, np.float32)
        return d[name]

    def _place(self, buf: np.ndarray, y: np.ndarray, at: float) -> None:
        i = int(round(at * SR))
        if i < 0 and not self.loop:
            y = y[-i:]
            i = 0
        n = len(buf)
        if self.loop:                     # en boucle : ce qui dépasse la fin repart au début
            i %= self.n
            while len(y) > 0:
                k = min(len(y), self.n - i)
                buf[i:i + k] += y[:k]
                y = y[k:]
                i = 0
        else:
            k = min(len(y), n - i)
            if k > 0:
                buf[i:i + k] += y[:k]

    def add(self, bus: str, x: np.ndarray, at: float, gain: float = 1.0, pan: float = 0.0, width: float = 1.0) -> None:
        self._place(self._buf(self.buses, bus, True), (pan2(np.asarray(x, np.float32), pan, width) * gain).astype(np.float32), at)

    def di(self, track: str, x: np.ndarray, at: float, gain: float = 1.0) -> None:
        self._place(self._buf(self.dis, track, False), (np.asarray(x) * gain).astype(np.float32), at)

    # --- le rendu
    def render(self, out: Path | None, lufs_target: float = -18.0, ceil_db: float = -1.5, room: np.ndarray | None = None,
               glue=(-16.0, 2.0), master_fx=None) -> np.ndarray:
        L = self.n + self.tail
        mix = np.zeros((L, 2), np.float32)
        send = np.zeros((L, 2), np.float32)

        def fold(x):
            if not self.loop:
                return x
            y = x[: self.n].copy()
            r = x[self.n:]
            y[: len(r)] += r
            return y

        names = list(self.dis) + list(self.buses)
        for name in names:
            raw = self.dis.pop(name) if name in self.dis else self.buses.pop(name)
            raw = fold(raw)
            fn = self.fx.get(name)
            y = preroll(fn, raw, self.loop) if fn is not None else raw
            if y.ndim == 1:
                y = pan2(y, 0.0)
            y = y.astype(np.float32)
            if DEBUG:
                print(f"    {name:10s} rms {20 * np.log10(np.sqrt(np.mean(y.astype(np.float64) ** 2)) + 1e-12):6.1f} dB")
            if self.loop:
                mix[: self.n] += y
                send[: self.n] += y * self.send.get(name, 0.2)
            else:
                mix[: len(y)] += y[:L]
                send[: len(y)] += y[:L] * self.send.get(name, 0.2)
            del raw, y
            gc.collect()
        if self.loop:
            mix, send = mix[: self.n], send[: self.n]
        if room is not None:
            if self.loop:
                rev = circ_conv(send, room)
            else:
                rev = np.stack([signal.fftconvolve(send[:, c], room[:, c])[:L] for c in range(2)], axis=1)
            mix = mix + rev.astype(np.float32)
            del rev
        del send
        gc.collect()

        def master(x):
            x = filt(x, bw("highpass", 28))
            if master_fx is not None:
                x = master_fx(x)
            if glue:
                x = compress(x, glue[0], glue[1], tau=0.04, rel=0.25)
            return x
        y = preroll(master, mix, self.loop)
        g = 10 ** ((lufs_target - lufs(y)) / 20)
        y = y * g
        ceil = 10 ** (ceil_db / 20)
        y = preroll(lambda z: limit(z, ceil), y, self.loop)
        if not self.loop:
            e = np.abs(y).max(axis=1)
            nz = np.nonzero(e > 10 ** (-60 / 20))[0]
            y = y[: (nz[-1] + 1) if len(nz) else len(y)]
            f = min(len(y), int(0.5 * SR))
            y[-f:] *= np.linspace(1, 0, f)[:, None] ** 2
        if out is not None:
            write_ogg(out, y)
        return y


def write_ogg(out: Path, y: np.ndarray) -> None:
    TMP.mkdir(parents=True, exist_ok=True)
    wav = TMP / (out.stem + ".wav")
    wavfile.write(wav, SR, (np.clip(y, -1, 1) * 32767).astype(np.int16))
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "libvorbis", "-q:a", "5", str(out)], check=True)
    wav.unlink()
    print(f"  {out.name}: {len(y) / SR:.1f} s")


# =========================================================================== jouer la batterie

DVEL = {"X": 1.0, "x": 0.8, "o": 0.45, "g": 0.28}
DRUM_KEYS = {"k": "kick", "s": "snare", "r": "rim", "g": "ghost", "x": "xstick", "h": "hat", "o": "hat_open",
             "l": "hat_loose", "p": "hat_pedal", "c": "crash", "C": "crash2", "z": "china", "R": "ride", "b": "bell",
             "1": "tom1", "2": "tom2", "3": "tom3", "4": "tom4", "cl": "clap", "tb": "tamb", "cb": "cowbell",
             "an": "anvil", "br": "brake", "cv": "claves", "wb": "wood", "st": "sticks"}
HATS = ("h", "o", "l", "p")


def drums(S: Song, kit: Kit, bar: float, pat: dict, vel: float = 1.0, human: float = 0.004, beats: float | None = None,
          beat0: float = 0.0, push: float = 0.0) -> None:
    """Une mesure de batterie écrite en grille : {"k": "X...x...", "s": "....X...", …} ; chaque
    caractère est un pas (X fort, x normal, o léger, g fantôme, 1-9 nuance, . rien). Le charleston
    ouvert s'arrête au coup de charleston suivant."""
    span = S.beats if beats is None else beats
    hat_times = []
    for key in HATS:
        s = pat.get(key, "")
        for i, c in enumerate(s):
            if c not in ".-":
                hat_times.append(beat0 + i * span / len(s))
    hat_times.sort()
    for key, s in pat.items():
        name = DRUM_KEYS[key]
        steps = len(s)
        for i, c in enumerate(s):
            if c in ".-":
                continue
            v = DVEL[c] if c in DVEL else int(c) / 9.0
            beat = beat0 + i * span / steps
            t = S.t(bar, beat) + float(S.rng.normal(0, human)) + push
            if key in ("h", "R") and c == "x":             # le charleston et la ride : les temps un peu plus appuyés
                v *= 1.0 if abs(beat - round(beat)) < 1e-6 else 0.8
            v = float(np.clip(v * vel * S.rng.uniform(0.92, 1.05), 0.05, 1.0))
            x = kit.get(name, v)
            if key == "o":
                nxt = [h for h in hat_times if h > beat + 1e-6]
                keep = ((nxt[0] - beat) if nxt else 1.0) * S.spb
                x = choke(x, keep, 0.03)
            pan, bus = kit.where[name]
            S.add("dr_" + bus, x, t, 1.0, pan, 0.6)


def drum_fx(S: Song, hall: bool = False) -> None:
    """Les tranches de console de la batterie : égaliseur, compresseur, niveau, envoi en salle."""
    S.fx["dr_kick"] = lambda x: compress(filt(x, peak(60, 2, 1.0)), -14, 3.0, 0.004, 0.08) * 1.0
    S.fx["dr_snare"] = lambda x: compress(filt(x, peak(5000, 4, 0.8)), -16, 3.0, 0.005, 0.1) * 2.0
    S.fx["dr_hats"] = lambda x: filt(x, bw("highpass", 500)) * 1.0
    S.fx["dr_cym"] = lambda x: filt(x, bw("highpass", 300), shelf(9000, -2)) * 0.6
    S.fx["dr_toms"] = lambda x: compress(x, -16, 2.5, 0.005, 0.12) * 0.9
    S.fx["dr_perc"] = lambda x: x * 0.45
    w = 0.32 if hall else 0.18
    S.send.update({"dr_kick": w * 0.5, "dr_snare": w * 1.4, "dr_hats": w * 0.6, "dr_cym": w * 0.9, "dr_toms": w * 1.2,
                   "dr_perc": w})


# quelques mesures types (pas de croche ou de double-croche)
PUNK = {"k": "X.....x.X.......", "s": "....X.......X...", "h": "x.x.x.x.x.x.x.x."}
PUNK2 = {"k": "X.....x.X.x.....", "s": "....X.......X...", "h": "x.x.x.x.x.x.x.x."}
PUNK_RIDE = {"k": "X.....x.X.......", "s": "....X.......X...", "R": "x.x.x.x.x.x.x.x."}
PUNK_CRASH = {"k": "X.....x.X.......", "s": "....X.......X...", "c": "X...............", "h": "..x.x.x.x.x.x.x."}
POLKA = {"k": "X...x...X...x...", "s": "..X...X...X...X.", "h": "x.x.x.x.x.x.x.x."}       # le « skank beat »
POLKA_RIDE = {"k": "X...x...X...x...", "s": "..X...X...X...X.", "R": "x.x.x.x.x.x.x.x."}
SKA = {"k": "X.......X.......", "x": "....x.......x...", "h": "x.x.x.x.x.x.x.x.", "p": "..x...x...x...x."}
HALF = {"k": "X.....x.........", "s": "........X.......", "h": "x.x.x.x.x.x.x.x."}


def fill(kind: str) -> dict:
    """Les roulements (une mesure ; le roulement occupe la fin)."""
    F = {
        "snare4": {"k": "X.......X.......", "s": "....X.......xxxx", "h": "x.x.x.x.x......."},
        "snare8": {"k": "X...............", "s": "........oxxxXxXX", "h": "x.x.x.x........."},
        "toms": {"k": "X.......X.......", "s": "....X...xx......", "1": "..........xx....", "2": "............xx..", "3": "..............XX"},
        "toms_big": {"k": "X...........X..X", "s": "xxxx............", "1": "....xxxx........", "2": "........xx......", "3": "..........xx....",
                     "4": "............xxxx"},
        "flam": {"k": "X.......X.....X.", "s": "....X.....X.X.X."},
        "rush": {"k": "X.X.X.X.X.X.X.X.", "s": "xxxxxxxxXxXxXXXX"},
        "stop": {"k": "X...............", "c": "X..............."},
    }
    return F[kind]


def tom_roll(S: Song, kit: Kit, bar: float, beat0: float, beats: float, order: str = "1234", per_beat: int = 4,
             vel: float = 0.9, cresc: float = 0.3) -> None:
    """Un roulement de toms qui descend (ou ce qu'on veut) en doubles croches."""
    n = int(round(beats * per_beat))
    for i in range(n):
        tom = order[min(len(order) - 1, i * len(order) // n)]
        v = vel * (1 - cresc + cresc * i / max(1, n - 1))
        drums(S, kit, bar, {tom: "x"}, v, beats=beats / n, beat0=beat0 + i * beats / n)


# =========================================================================== les guitares

def parse_chord(sym: str):
    """'F#m' -> (classe de la fondamentale, tierce 3 ou 4 (0 pour un « 5 »), septième ou None)."""
    sym = sym.split("/")[0]
    r = PC[sym[0]]
    k = 1
    if len(sym) > 1 and sym[1] in "#b":
        r += 1 if sym[1] == "#" else -1
        k = 2
    q = sym[k:]
    third = 0 if q.startswith("5") else (3 if q.startswith("m") and not q.startswith("maj") else 4)
    if q.startswith("sus4"):
        third = 5
    sev = 10 if q.endswith("7") and "maj" not in q else (11 if "maj7" in q else None)
    return r % 12, third, sev


def root_in(pc: int, lo: int) -> int:
    return lo + ((pc - lo) % 12)


def voice(sym: str, voicing: str, lo: int = 40) -> list[int]:
    r, third, sev = parse_chord(sym)
    R = root_in(r, lo)
    if voicing == "5":
        return [R, R + 7, R + 12]
    if voicing == "5lo":
        return [R, R + 7]
    if voicing == "8":
        return [R, R + 12]
    if voicing == "5hi":
        return [R + 12, R + 19, R + 24]
    if voicing == "full":
        t = third or 4
        out = [R, R + 7, R + 12, R + 12 + t, R + 19]
        return out
    if voicing == "hi":                           # trois notes en haut du manche (le « skank »)
        pcs = [r, (r + (third or 4)) % 12, (r + 7) % 12] + ([(r + sev) % 12] if sev else [])
        tones = sorted(m for m in range(62, 80) if m % 12 in pcs)
        return tones[:3]
    raise ValueError(voicing)


KIND = {"m": ("mute", 0.78), "M": ("mute", 1.0), "o": ("open", 0.85), "O": ("open", 1.0), "u": ("up", 0.62),
        "s": ("skank", 0.75), "S": ("skank", 0.95), "x": ("dead", 0.6), "n": ("note", 0.9)}


class Guitar:
    """Un guitariste (une prise) : il joue sur une ligne directe mono, l'ampli vient au rendu."""

    def __init__(self, S: Song, track: str, seed: int, jitter: float = 0.005, bright: float = 0.6, pickup: float = 0.12,
                 tune: float = 0.0, lo: int = 40, late: float = 0.0):
        self.S = S
        self.track = track
        self.rng = np.random.default_rng(seed)
        self.jitter = jitter
        self.bright = bright
        self.pickup = pickup
        self.tune = tune
        self.lo = lo
        self.late = late

    def strike(self, t: float, notes: list, dur: float, vel: float, kind: str) -> None:
        up = kind in ("up", "skank")
        order = notes[::-1] if up else notes
        spread = {"mute": 0.0035, "open": 0.008, "up": 0.006, "skank": 0.004, "dead": 0.003, "note": 0.0}[kind]
        t0 = t + float(self.rng.normal(0, self.jitter)) + self.late
        for j, m in enumerate(order):
            f = hz(m + self.tune + float(self.rng.normal(0, 0.04)))
            if kind == "mute":
                keep = min(dur, 0.34)
                x = string(f, keep + 0.02, self.rng, t60=0.2, bright=0.18, hard=0.45, pick=0.2, pickup=self.pickup)
            elif kind == "skank":
                keep = min(dur, 0.1)
                x = string(f, keep + 0.02, self.rng, t60=0.7, bright=0.7, hard=0.75, pick=0.1, pickup=self.pickup)
            elif kind == "dead":
                keep = min(dur, 0.05)
                x = string(f, keep + 0.02, self.rng, t60=0.03, bright=0.3, hard=0.9, pick=0.1, pickup=self.pickup)
            else:
                keep = dur
                x = string(f, keep + 0.02, self.rng, t60=3.2, bright=self.bright, hard=0.65, pick=0.12, pickup=self.pickup)
            x = choke(x, keep, 0.015)
            v = vel * (1.0 - 0.07 * j) * float(self.rng.uniform(0.9, 1.05))
            self.S.di(self.track, x, t0 + j * spread, v)

    def rhythm(self, bar0: int, prog: list, patt, voicing: str = "5", vel: float = 1.0, lo: int | None = None) -> None:
        """Les accords d'une section : prog = un accord (ou deux, « A E ») par mesure, patt = la grille de
        la mesure (ou une liste de grilles) : m/M étouffé, o/O ouvert, u aller-retour, s/S « skank »,
        x coup mort, - laisser sonner, . s'arrêter."""
        S = self.S
        lo = self.lo if lo is None else lo
        ev = []
        for i, cell in enumerate(prog):
            p = patt if isinstance(patt, str) else patt[i % len(patt)]
            syms = cell.split()
            steps = len(p)
            for k, c in enumerate(p):
                beat = k * S.beats / steps
                sym = syms[min(len(syms) - 1, int(beat // (S.beats / len(syms)) + 1e-9))]
                ev.append((bar0 + i, beat, c, sym))
        for idx, (bar, beat, c, sym) in enumerate(ev):
            if c in "-.":
                continue
            t0 = S.t(bar, beat)
            j = idx + 1
            while j < len(ev) and ev[j][2] == "-":
                j += 1
            t1 = S.t(ev[j][0], ev[j][1]) if j < len(ev) else S.t(bar0 + len(prog))
            kind, v = KIND[c]
            vv = voicing
            if kind == "mute" and voicing in ("5", "full"):
                vv = "5lo"
            if kind == "skank":
                vv = "hi"
            self.strike(t0, voice(sym, vv, lo), max(0.04, t1 - t0 - 0.012), v * vel, kind)

    def riff(self, bar0: int, text: str, vel: float = 1.0, power: bool = False) -> None:
        """Un riff en notes : « E2:0.5 G2:0.5 A2m:1 … » (m : étouffée ; power : en quintes)."""
        S = self.S
        for bi, b in enumerate(text.split("|")):
            beat = 0.0
            toks = b.split()
            for tok in toks:
                p, d = tok.split(":")
                d = float(d)
                if p != "r":
                    mute = p.endswith("m")
                    p = p.rstrip("m")
                    m = midi_of(p)
                    notes = [m, m + 7, m + 12] if power and not mute else ([m, m + 7] if power else [m])
                    self.strike(S.t(bar0 + bi, beat), notes, d * S.spb - 0.012, vel * (0.85 if mute else 1.0),
                                "mute" if mute else ("open" if power else "note"))
                beat += d


def lead(S: Song, track: str, bar0: int, text: str, seed: int, octave: int = 0, vel: float = 0.9, t60: float = 3.5,
         vib: float = 0.25, rate: float = 5.6, bright: float = 0.8) -> None:
    """La guitare solo : « A4:1 ^C#5:0.5 ~E5:2 /F#5:1 r:1 | … » (^ tiré d'un ton, ^1 d'un demi-ton,
    / glissé d'en dessous, ~ grand vibrato ; les notes sont liées jusqu'à la suivante)."""
    rng = np.random.default_rng(seed)
    events = []
    for bi, b in enumerate(text.split("|")):
        beat = 0.0
        for tok in b.split():
            p, d = tok.split(":")
            events.append((bar0 + bi, beat, p, float(d)))
            beat += float(d)
    for i, (bar, beat, p, d) in enumerate(events):
        if p == "r":
            continue
        bend = 0.0
        slide = 0.0
        vv = vib
        acc = 1.0
        while p and p[0] in "^/~>":
            if p[0] == ">":
                acc, p = 1.2, p[1:]
            elif p.startswith("^1"):
                bend, p = 1.0, p[2:]
            elif p[0] == "^":
                bend, p = 2.0, p[1:]
            elif p[0] == "/":
                slide, p = 3.0, p[1:]
            else:
                vv, p = vib * 2.2, p[1:]
        m = midi_of(p) + 12 * octave
        t0 = S.t(bar, beat)
        nxt = events[i + 1] if i + 1 < len(events) else None
        t1 = S.t(nxt[0], nxt[1]) if nxt else t0 + d * S.spb
        if nxt and nxt[2] == "r":
            t1 = S.t(nxt[0], nxt[1]) - 0.02
        dur = max(0.06, t1 - t0)
        n = int((dur + 0.05) * SR)
        x = np.arange(n) / SR
        semi = np.zeros(n)
        if bend:
            semi -= bend * (1 - np.clip(x / 0.11, 0, 1)) ** 1.5
        if slide:
            semi -= slide * (1 - np.clip(x / 0.07, 0, 1))
        if dur > 0.3:
            ramp = np.clip((x - 0.2) / 0.3, 0, 1)
            semi += vv * ramp * np.sin(2 * np.pi * rate * x)
        fm = 2 ** (semi / 12)
        y = string(hz(m), dur + 0.05, rng, t60=t60, bright=bright, hard=0.85, pick=0.1, pickup=0.1, fmul=fm)
        y = choke(y, dur, 0.02)
        S.di(track, y, t0 + float(rng.normal(0, 0.004)), vel * acc)


def amp(di: np.ndarray, gain: float = 40.0, bias: float = 0.25, tight: float = 110.0, mid: float = 4.0,
        scoop: float = -4.0, presence: float = 3.0, cab: float = 5200.0, level: float = 1.0) -> np.ndarray:
    """L'ampli : pré-filtre (graves serrés, bosse de médiums), gain, deux étages d'écrêtage (doux et
    asymétrique, puis plus dur), puis le baffle 4×12 (bosse grave, creux, présence, coupure raide)."""
    x = filt(di.astype(np.float64), bw("highpass", tight), peak(850, mid, 0.7))
    x = x * gain
    y = np.tanh(x + bias) - np.tanh(bias)
    y = filt(y, bw("highpass", 30), peak(700, 2.0, 0.8))
    y = 0.75 * np.tanh(2.2 * y) + 0.25 * np.clip(2.2 * y, -1, 1)
    y = filt(y, bw("highpass", 75), peak(115, 3.0, 1.0), peak(430, scoop, 1.0), peak(2700, presence, 1.3),
             bw("lowpass", cab, 4), bw("lowpass", 9000, 2))
    return (y * level).astype(np.float32)


def bass_amp(di: np.ndarray, drive: float = 3.0, level: float = 1.0) -> np.ndarray:
    """La basse : le son direct rond, et une part saturée (le grain du médiator) dans le haut-médium."""
    di = di.astype(np.float64)
    clean = lp(di, 700, 4)
    dirty = filt(np.tanh(drive * hp(di, 160)), bw("lowpass", 2200, 4), peak(1100, 2, 1.0))
    y = clean + 0.07 * dirty
    y = filt(y, bw("highpass", 33), peak(80, 4, 0.8), peak(280, -2, 1.0))
    y = compress(y, -22, 4.0, 0.01, 0.1)
    return (y * level).astype(np.float32)


def echo(x: np.ndarray, delay: float, fb: float = 0.35, n: int = 5, lp_hz: float = 2800.0, pingpong: bool = True,
         loop: bool = False) -> np.ndarray:
    """Un écho à bande : les répétitions de plus en plus sourdes, gauche-droite."""
    if x.ndim == 1:
        x = pan2(x)
    out = x.astype(np.float64).copy()
    d = int(delay * SR)
    cur = x.astype(np.float64)
    for k in range(1, n + 1):
        cur = lp(cur, lp_hz) * fb
        # (pour une boucle, le traitement tourne dans preroll() : la fin de la boucle est déjà devant)
        sh = np.concatenate([np.zeros((d * k, 2)), cur[:-d * k]]) if d * k < len(cur) else np.zeros_like(cur)
        if pingpong:
            sh = sh[:, ::-1] if k % 2 else sh
        out += sh
    return out.astype(np.float32)


class Bass:
    """La bassiste : une corde grave de Karplus-Strong au médiator."""

    def __init__(self, S: Song, track: str, seed: int, lo: int = 28, jitter: float = 0.004, t60: float = 1.4,
                 bright: float = 0.12):
        self.S = S
        self.track = track
        self.rng = np.random.default_rng(seed)
        self.lo = lo
        self.jitter = jitter
        self.t60 = t60
        self.bright = bright

    def note(self, t: float, m: float, dur: float, vel: float = 0.9) -> None:
        x = string(hz(m), dur + 0.03, self.rng, t60=self.t60, bright=self.bright, hard=0.35, pick=0.2)
        x = choke(x, dur, 0.02)
        self.S.di(self.track, x, t + float(self.rng.normal(0, self.jitter)), vel * float(self.rng.uniform(0.92, 1.03)))

    def line(self, bar0: int, prog: list, patt, vel: float = 1.0, lo: int | None = None) -> None:
        """La ligne : une grille par mesure ; r fondamentale, R accentuée, o octave, f quinte, 3 tierce,
        6 sixte, 7 septième, 2 seconde, 4 quarte, a approche chromatique (d'en dessous) de l'accord
        suivant, A (d'au-dessus), - tenue, . silence."""
        S = self.S
        lo = self.lo if lo is None else lo
        ev = []
        for i, cell in enumerate(prog):
            p = patt if isinstance(patt, str) else patt[i % len(patt)]
            syms = cell.split()
            for k, c in enumerate(p):
                beat = k * S.beats / len(p)
                sym = syms[min(len(syms) - 1, int(beat // (S.beats / len(syms)) + 1e-9))]
                ev.append((bar0 + i, beat, c, sym, i))
        for idx, (bar, beat, c, sym, i) in enumerate(ev):
            if c in "-.":
                continue
            r, third, sev = parse_chord(sym)
            R = root_in(r, lo)
            nxt_sym = prog[i + 1].split()[0] if i + 1 < len(prog) else prog[0].split()[0]
            nr = root_in(parse_chord(nxt_sym)[0], lo)
            m = {"r": R, "R": R, "o": R + 12, "f": R + 7, "F": R - 5 if R - 5 >= lo - 4 else R + 7, "3": R + (third or 4),
                 "6": R + 9, "7": R + (sev or 10), "2": R + 2, "4": R + 5, "a": nr - 1, "A": nr + 1,
                 "b": R - 1}[c]
            j = idx + 1
            while j < len(ev) and ev[j][2] == "-":
                j += 1
            t0 = S.t(bar, beat)
            t1 = S.t(ev[j][0], ev[j][1]) if j < len(ev) else S.t(bar0 + len(prog))
            self.note(t0, m, max(0.05, (t1 - t0) * 0.92), vel * (1.0 if c == "R" else 0.85))

    def riff(self, bar0: int, text: str, vel: float = 1.0) -> None:
        S = self.S
        for bi, b in enumerate(text.split("|")):
            beat = 0.0
            for tok in b.split():
                p, d = tok.split(":")
                d = float(d)
                if p != "r":
                    self.note(S.t(bar0 + bi, beat), midi_of(p), d * S.spb * 0.92, vel)
                beat += d


# =========================================================================== claviers et synthèses

def organ(m: float, dur: float, vel: float = 0.7, rng=None, combo: float = 0.6, perc: float = 0.4) -> np.ndarray:
    """L'orgue « combo » un peu jouet : des harmoniques (tirettes 16'… 2'), un peu de carré (le côté
    transistor), vibrato, le « clic » de la touche et une percussion à l'attaque."""
    rng = rng if rng is not None else np.random.default_rng(int(m * 100))
    f = hz(m)
    n = int((dur + 0.05) * SR)
    x = np.arange(n) / SR
    vib = 1 + 0.0032 * np.sin(2 * np.pi * 6.4 * x + rng.uniform(0, 6))
    ph = 2 * np.pi * np.cumsum(f * vib) / SR + rng.uniform(0, 6)
    y = np.zeros(n)
    for k, a in ((1, 1.0), (2, 0.6), (3, 0.42), (4, 0.3), (6, 0.16), (8, 0.12)):
        if k * f < 9000:
            y += a * np.sin(k * ph)
    y += combo * 0.35 * np.tanh(4 * np.sin(ph))
    if perc > 0 and 3 * f < 9000:
        y += perc * np.sin(3 * ph) * np.exp(-x / 0.12)
    env = np.clip(x / 0.004, 0, 1) * np.clip((dur + 0.05 - x) / 0.05, 0, 1)
    y *= env
    k = int(0.003 * SR)
    y[:k] += rng.standard_normal(k) * 0.2 * np.hanning(k)
    return lp(y, 7000) * vel * 0.18


def leslie(x: np.ndarray, rate: float = 5.8, depth: float = 0.25, loop_n: int | None = None) -> np.ndarray:
    """Le petit haut-parleur tournant : volume et timbre qui tournent d'une oreille à l'autre."""
    m = x if x.ndim == 1 else x.mean(axis=1)
    n = len(m)
    t = np.arange(n) / SR
    rr = rate if loop_n is None else max(1, round(rate * loop_n / SR)) * SR / loop_n
    a = np.sin(2 * np.pi * rr * t)
    br = lp(m, 2500)
    l = m * (1 - depth * a) + (m - br) * depth * a
    r = m * (1 + depth * a) - (m - br) * depth * a
    return np.stack([l, r], axis=1).astype(np.float32)


def celesta(m: float, dur: float, vel: float = 0.6, rng=None) -> np.ndarray:
    """Un célesta (lames d'acier frappées par des marteaux feutrés, une caisse de résonance)."""
    rng = rng if rng is not None else np.random.default_rng(int(m * 10))
    f = hz(m)
    n = int((dur + 2.0) * SR)
    x = np.arange(n) / SR
    y = np.sin(2 * np.pi * f * x) * np.exp(-x / 1.6)
    y += 0.25 * np.sin(2 * np.pi * 2.0 * f * x + 0.5) * np.exp(-x / 0.6)
    y += 0.12 * np.sin(2 * np.pi * 3.0 * f * x + 1.0) * np.exp(-x / 0.3)
    if 4.1 * f < 16000:
        y += 0.15 * np.sin(2 * np.pi * 4.07 * f * x) * np.exp(-x / 0.15)
    if 6.2 * f < 18000:
        y += 0.06 * np.sin(2 * np.pi * 6.2 * f * x) * np.exp(-x / 0.06)
    k = int(0.004 * SR)
    y[:k] += rng.standard_normal(k) * np.hanning(k) * 0.05
    y *= np.clip(x / 0.0015, 0, 1)
    rel = np.clip((dur + 0.6 - x) / 0.6, 0, 1)
    return y * rel * vel * 0.3


def twinkle(rng) -> np.ndarray:
    """Un scintillement : une toute petite clochette aiguë (une spore qui brille)."""
    f = float(rng.uniform(2600, 6500))
    n = int(0.6 * SR)
    x = np.arange(n) / SR
    ff = f * (1 + 0.01 * x)
    y = np.sin(2 * np.pi * np.cumsum(ff) / SR) * np.exp(-x / 0.12) + 0.3 * np.sin(2 * np.pi * 2.76 * f * x) * np.exp(-x / 0.04)
    return (y * np.clip(x / 0.002, 0, 1) * 0.3).astype(np.float32)


def pad(m: float, dur: float, vel: float = 0.5, rng=None, cutoff: float = 1800.0, attack: float = 1.2,
        release: float = 1.8, voices: int = 5, detune: float = 0.12) -> np.ndarray:
    """Une nappe douce : des dents de scie un peu désaccordées, filtrées, qui enflent lentement (stéréo)."""
    rng = rng if rng is not None else np.random.default_rng(int(m * 7))
    f = hz(m)
    n = int((dur + release) * SR)
    x = np.arange(n) / SR
    out = np.zeros((n, 2))
    for v in range(voices):
        d = (v - (voices - 1) / 2) / max(1, (voices - 1) / 2) * detune
        ph = (f * 2 ** (d / 12) * x + rng.uniform(0, 1)) % 1.0
        saw = 2 * ph - 1
        side = (v % 2) * 2 - 1
        out[:, 0] += saw * (1 + 0.4 * side)
        out[:, 1] += saw * (1 - 0.4 * side)
    out = lp(out, cutoff, 4)
    env = np.clip(x / attack, 0, 1) ** 2 * np.clip((dur + release - x) / release, 0, 1)
    return (out * env[:, None] * vel * 0.06).astype(np.float32)


def synth_bass(m: float, dur: float, vel: float = 0.8, cut: float = 900.0, reso: float = 4.0, sq: float = 0.5) -> np.ndarray:
    """La basse de synthèse de l'usine : carré et scie, filtre qui claque à l'attaque."""
    f = hz(m)
    n = int((dur + 0.06) * SR)
    x = np.arange(n) / SR
    ph = (f * x) % 1.0
    y = (1 - sq) * (2 * ph - 1) + sq * np.sign(np.sin(2 * np.pi * f * x))
    fc = cut * (0.4 + 1.6 * np.exp(-x / 0.06))
    out = np.zeros(n)
    blk = 256
    zi = np.zeros(2)
    for i in range(0, n, blk):
        b, a = signal.iirpeak(float(np.clip(fc[i], 60, 8000)), reso, fs=SR)
        lb, la = signal.butter(1, float(np.clip(fc[i], 60, 8000)), fs=SR)
        seg = y[i:i + blk]
        z, zi = signal.lfilter(b, a, seg, zi=zi)
        out[i:i + blk] = signal.lfilter(lb, la, seg) * 0.7 + z * 0.5
    env = np.clip(x / 0.003, 0, 1) * np.clip((dur + 0.06 - x) / 0.06, 0, 1)
    return np.tanh(out * env * 1.5) * vel * 0.5


def hiss(dur: float, rng, lo: float = 1500.0, hi: float = 9000.0, att: float = 0.01, rel: float = 0.3,
         sweep: float = 0.0) -> np.ndarray:
    """Un jet de vapeur ou de vérin hydraulique : souffle filtré ; sweep (en octaves) fait glisser la
    coupure haute pendant le jet (négatif : le jet qui s'essouffle)."""
    n = int(dur * SR)
    x = np.arange(n) / SR
    y = bp(rng.standard_normal(n), lo, hi)
    if sweep:
        cut = hi * 2 ** (sweep * x / dur)
        z = np.zeros(n)
        zi = np.zeros((1, 2))
        blk = 512
        for i in range(0, n, blk):
            sos = bw("lowpass", float(np.clip(cut[i], 200, 18000)), 2)
            z[i:i + blk], zi = signal.sosfilt(sos, y[i:i + blk], zi=zi)
        y = z
    env = np.clip(x / att, 0, 1) * np.clip((dur - x) / rel, 0, 1) ** 1.5
    return y * env * 0.3


def clang(f: float, dur: float, rng, bright: float = 1.0) -> np.ndarray:
    """Un « clang » de métal : des partiels inharmoniques amortis (poutrelle, tôle, tuyau)."""
    n = int(dur * SR)
    x = np.arange(n) / SR
    y = np.zeros(n)
    for r, a, d in ((1.0, 1.0, 0.5), (2.76, 0.6, 0.3), (5.4, 0.4 * bright, 0.15), (8.93, 0.25 * bright, 0.08),
                    (13.3, 0.15 * bright, 0.05)):
        ff = f * r * rng.uniform(0.98, 1.02)
        if ff < 16000:
            y += a * np.sin(2 * np.pi * ff * x + rng.uniform(0, 6)) * np.exp(-x / (d * dur))
    k = int(0.004 * SR)
    y[:k] += rng.standard_normal(k) * np.hanning(k) * 0.6
    return y * 0.35


def thump(f0: float, f1: float, dur: float, rng, noise: float = 0.3) -> np.ndarray:
    """Une presse qui retombe : un coup sourd (sinus qui plonge) et du bruit grave."""
    n = int(dur * SR)
    x = np.arange(n) / SR
    f = f1 + (f0 - f1) * np.exp(-x / 0.03)
    y = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-x / (0.3 * dur))
    y += noise * lp(rng.standard_normal(n), 600) * np.exp(-x / 0.05)
    return y * 0.6


# =========================================================================== instruments échantillonnés

SAMPLED = {
    "trp": ("Brass/Trumpet/susvib/*.wav", dict(attack=0.025, release=0.18, pan=0.2, width=0.3, gain=1.0)),
    "trp_stac": ("Brass/Trumpet/stac/*.wav", dict(sustain=False, attack=0.002, release=0.12, pan=0.2, width=0.3, gain=0.9)),
    "trp_harmon": ("Brass/Trumpet/harmonM-sus/*.wav", dict(attack=0.03, release=0.3, pan=-0.15, width=0.3, gain=1.1)),
    "tbn": ("Brass/Tenor Trombone/sus/*.wav", dict(attack=0.035, release=0.2, pan=-0.25, width=0.3, gain=0.95)),
    "tbn_stac": ("Brass/Tenor Trombone/stac/*.wav", dict(sustain=False, attack=0.002, release=0.15, pan=-0.25, width=0.3, gain=0.9)),
    "horn": ("Brass/F Horn/sus/*.wav", dict(attack=0.06, release=0.5, pan=-0.3, width=0.5, gain=0.8)),
    "tuba_stac": ("Brass/Tuba/stac/*.wav", dict(sustain=False, attack=0.002, release=0.2, pan=0.1, width=0.3, gain=0.9)),
    "glock": ("Percussion/Glock/*.wav", dict(sustain=False, attack=0.001, release=1.5, pan=-0.2, width=0.4, gain=0.5)),
    "harp": ("Strings/Harp/*.wav", dict(sustain=False, attack=0.002, release=1.5, pan=-0.45, width=0.5, gain=0.9)),
    "marimba": ("Percussion/Marimba/*.wav", dict(sustain=False, attack=0.001, release=0.8, pan=0.2, width=0.5, gain=0.7)),
    "xylo": ("Percussion/Xylo/*.wav", dict(sustain=False, attack=0.001, release=0.6, pan=0.2, width=0.4, gain=0.8)),
    "vln": ("Strings/Violin Section/susVib/*.wav", dict(attack=0.25, release=0.9, pan=-0.45, width=0.7, gain=0.6)),
    "vla": ("Strings/Viola Section/susvib/*.wav", dict(attack=0.25, release=0.9, pan=0.15, width=0.6, gain=0.6)),
    "vc": ("Strings/Cello Section/susvib/*.wav", dict(attack=0.2, release=0.9, pan=0.35, width=0.6, gain=0.7)),
    "cb": ("Strings/Solo Contrabass/SusVib/*.wav", dict(attack=0.2, release=0.9, pan=0.5, width=0.3, gain=0.8)),
    "vln_trem": ("Strings/Violin Section/Trem/*.wav", dict(attack=0.3, release=0.8, pan=-0.4, width=0.8, gain=0.5)),
    "vc_spic": ("Strings/Cello Section/spic/*.wav", dict(sustain=False, attack=0.002, release=0.12, pan=0.35, width=0.4, gain=0.8)),
    "vla_spic": ("Strings/Viola Section/spic/*.wav", dict(sustain=False, attack=0.002, release=0.12, pan=0.1, width=0.4, gain=0.7)),
    "vln_pizz": ("Strings/Violin Section/Pizz/*.wav", dict(sustain=False, attack=0.002, release=0.3, pan=-0.45, width=0.4, gain=0.8)),
    "vc_pizz": ("Strings/Cello Section/pizzT/*.wav", dict(sustain=False, attack=0.002, release=0.4, pan=0.4, width=0.4, gain=0.85)),
    "cb_pizz": ("Strings/Solo Contrabass/Pizz/*.wav", dict(sustain=False, attack=0.002, release=0.5, pan=0.5, width=0.3, gain=0.85)),
    "bsn_stac": ("Woodwinds/Bassoon/stac/*.wav", dict(sustain=False, attack=0.002, release=0.2, pan=0.3, width=0.4, gain=0.85)),
    "bsn": ("Woodwinds/Bassoon/vib/*.wav", dict(attack=0.05, release=0.4, pan=0.3, width=0.4, gain=0.8)),
    "clar_stac": ("Woodwinds/Clarinet/stac/*.wav", dict(sustain=False, attack=0.002, release=0.15, pan=0.2, width=0.4, gain=0.8)),
    "flute": ("Woodwinds/Flute/expvib/*.wav", dict(attack=0.06, release=0.5, pan=-0.15, width=0.4, gain=0.8)),
    "timp": ("Percussion/Timpani/Timpani1_Hit_*.wav", dict(base=41.5, sustain=False, attack=0.001, release=1.5, pan=0.1, width=0.5, gain=0.8)),
}
VCSL_KEYS = ("verres", "carillon", "cloche")
_INS: dict = {}


def instrument(key: str):
    if key not in _INS:
        if key in VCSL_KEYS:
            import compose_musique_v70 as cm70
            cm70.VCSL = VCSL
            _INS[key] = cm70.vcsl(key)
        else:
            pat, opt = SAMPLED[key]
            _INS[key] = orch.Instrument(key, VSCO, pat, **opt)
    return _INS[key]


def release_instruments() -> None:
    _INS.clear()
    gc.collect()


def play(S: Song, key: str, bus: str, midi: float, bar: float, beat: float, beats: float, vel: float = 0.6,
         pan: float | None = None, human: float = 0.006, **kw) -> None:
    ins = instrument(key)
    x = ins.note(midi, beats * S.spb, vel, **kw)
    t = S.t(bar, beat) - (0.0 if kw.get("legato") else ins.lag) + float(S.rng.normal(0, human))
    S.add(bus, x, t, ins.gain, ins.pan if pan is None else pan, ins.width)


def melody(S: Song, key: str, bus: str, bar0: int, text: str, vel: float = 0.6, octave: int = 0, legato: float = 0.03,
           stac: float = 1.0, pan: float | None = None, synth=None) -> None:
    """Une mélodie « D5:1 F#5:0.5 … | … » (r : silence ; > accent) jouée par un instrument échantillonné
    (key) ou une fonction de synthèse (synth(m, durée, force))."""
    for bi, b in enumerate(text.split("|")):
        beat = 0.0
        toks = b.split()
        tot = sum(float(t.split(":")[1]) for t in toks)
        if abs(tot - S.beats) > 1e-6:
            raise ValueError(f"{S.name} {key} mesure {bar0 + bi} : {tot} temps")
        for tok in toks:
            p, d = tok.split(":")
            d = float(d)
            acc = p.startswith(">")
            p = p.lstrip(">~^/")
            if p != "r":
                m = midi_of(p) + 12 * octave
                v = vel * (1.2 if acc else 1.0)
                if synth is not None:
                    x = synth(m, d * S.spb * stac, min(1.0, v))
                    S.add(bus, x, S.t(bar0 + bi, beat) + float(S.rng.normal(0, 0.004)), 1.0, pan or 0.0)
                else:
                    play(S, key, bus, m, bar0 + bi, beat, d * stac + legato, min(1.0, v), pan=pan)
            beat += d


def chords_of(S: Song, key: str, bus: str, bar0: int, prog: list, lo: int, hi: int, n: int, beats_at, length: float,
              vel: float = 0.5, synth=None, pan: float | None = None) -> None:
    """Des accords plaqués (cuivres, orgue…) aux temps donnés de chaque mesure."""
    for i, cell in enumerate(prog):
        syms = cell.split()
        for b in beats_at:
            sym = syms[min(len(syms) - 1, int(b // (S.beats / len(syms))))]
            r, third, sev = parse_chord(sym)
            pcs = [r, (r + (third or 7)) % 12, (r + 7) % 12] + ([(r + sev) % 12] if sev else [])
            tones = sorted(m for m in range(lo, hi + 1) if m % 12 in pcs)[:n]
            for m in tones:
                if synth is not None:
                    S.add(bus, synth(m, length * S.spb, vel), S.t(bar0 + i, b), 1.0, pan or 0.0)
                else:
                    play(S, key, bus, m, bar0 + i, b, length, vel, pan=pan)


# =========================================================================== la foule

_CROWD = {}


def _s68():
    import generate_sons_v68 as s68
    return s68


def crowd_seed(seed: int) -> None:
    s68 = _s68()
    s68.RNG = np.random.default_rng([7575, seed, 1])
    s68.amb.RNG = np.random.default_rng([7575, seed, 2])
    s68.s56.RNG = np.random.default_rng([7575, seed, 3])


def hey(rng, voices: int = 16, vowel: str = "è") -> np.ndarray:
    """Toute la fosse qui crie « Hé ! » en même temps (voix d'hommes et de femmes, un rien décalées)."""
    s68 = _s68()
    out = np.zeros((int(0.6 * SR), 2))
    for _ in range(voices):
        fem = rng.random() < 0.4
        f0 = rng.uniform(230, 330) if fem else rng.uniform(120, 210)
        v = s68.shout(rng.uniform(0.15, 0.24), f0, "a" if rng.random() < 0.3 else vowel, "é" if rng.random() < 0.3 else None,
                      at=0.06, shape="cheer", att=0.012, rel=0.08, breath=0.4, scale=1.15 if fem else 1.0)
        v = v / (np.max(np.abs(v)) + 1e-9)
        i = int(max(0.0, rng.normal(0.02, 0.012)) * SR)
        k = min(len(v), len(out) - i)
        p = rng.uniform(-0.9, 0.9)
        out[i:i + k] += pan2(v[:k] * rng.uniform(0.5, 1.0), p)
    return lp(out, 5500)


def cheer(rng, dur: float = 4.0, voices: int = 26, claps: int = 80, kit: Kit | None = None) -> np.ndarray:
    """La foule qui acclame : « Ouais ! », sifflets, applaudissements."""
    s68 = _s68()
    out = np.zeros((int((dur + 1.0) * SR), 2))
    for _ in range(voices):
        fem = rng.random() < 0.4
        v = s68.shout(rng.uniform(0.8, 1.9), rng.uniform(230, 340) if fem else rng.uniform(110, 220), "ou",
                      "è" if rng.random() < 0.6 else "a", at=rng.uniform(0.06, 0.14), scale=1.15 if fem else 1.0)
        v = v / (np.max(np.abs(v)) + 1e-9)
        i = int(rng.uniform(0, dur * 0.45) * SR)
        k = min(len(v), len(out) - i)
        out[i:i + k] += pan2(v[:k] * rng.uniform(0.25, 0.6), rng.uniform(-0.9, 0.9))
    for w in range(3):
        v = s68.whistle(int(rng.integers(0, 3)))
        i = int(rng.uniform(0.2, dur * 0.6) * SR)
        k = min(len(v), len(out) - i)
        out[i:i + k] += pan2(v[:k] * rng.uniform(0.2, 0.35), rng.uniform(-0.8, 0.8))
    if kit is not None:
        for _ in range(claps):
            t = rng.uniform(0.05, dur)
            c = kit.get("clap", rng.uniform(0.3, 0.9)).mean(axis=1)
            c = lp(c, rng.uniform(3000, 7000))
            i = int(t * SR)
            k = min(len(c), len(out) - i)
            g = 0.35 * min(1.0, (dur - t) / 1.2 + 0.2)
            out[i:i + k] += pan2(c[:k] * g * rng.uniform(0.4, 1.0), rng.uniform(-0.9, 0.9))
    x = np.arange(len(out)) / SR
    out *= np.clip((dur + 0.8 - x) / 1.5, 0, 1)[:, None]
    return lp(out, 6500).astype(np.float32)


def crowd_sing(S: Song, bar0: int, text: str, rng, voices: int = 12, vowel: str = "o", vel: float = 1.0,
               bus: str = "crowd") -> None:
    """La foule qui chante avec le groupe (« Oh-oh-oh ») : chaque voix suit la mélodie avec sa propre
    justesse et son propre retard, un petit « w » à chaque note (« wo »), les hommes à l'octave du
    dessous."""
    s68 = _s68()
    ev = []
    for bi, b in enumerate(text.split("|")):
        beat = 0.0
        for tok in b.split():
            p, d = tok.split(":")
            ev.append((S.t(bar0 + bi, beat), p, float(d)))
            beat += float(d)
    t_start = ev[0][0]
    t_end = S.t(bar0 + len(text.split("|")))
    n = int((t_end - t_start + 0.6) * SR)
    x = np.arange(n) / SR
    vo = s68.VOW[vowel]
    vw = s68.VOW["ou"]
    for v in range(voices):
        fem = v % 3 == 0
        shift = 0 if fem else -12
        lag = abs(rng.normal(0.03, 0.02))
        det = rng.normal(0, 0.18)
        f0 = np.zeros(n)
        amp_ = np.zeros(n)
        f1 = np.full(n, float(vo[0][0]))
        f2 = np.full(n, float(vo[1][0]))
        last = None
        for i, (t, p, d) in enumerate(ev):
            a = int((t - t_start + lag) * SR)
            e = int((t - t_start + lag + d * S.spb) * SR)
            if p == "r":
                continue
            m = midi_of(p) + shift + det
            e2 = min(n, e)
            f0[a:e2] = hz(m)
            seg = np.arange(e2 - a) / SR
            amp_[a:e2] = np.clip(seg / 0.05, 0, 1) * np.clip((e2 - a) / SR - seg, 0, 0.05) / 0.05
            w = np.exp(-seg / 0.06)
            f1[a:e2] = vo[0][0] * (1 - w) + vw[0][0] * w
            f2[a:e2] = vo[1][0] * (1 - w) + vw[1][0] * w
            last = e2
        # la hauteur glisse un peu d'une note à l'autre ; entre les phrases on garde la dernière note
        filled = f0.copy()
        for i in range(1, n):
            if filled[i] == 0:
                filled[i] = filled[i - 1]
        filled[filled == 0] = hz(60)
        a1 = np.exp(-1 / (0.025 * SR))
        filled = signal.lfilter([1 - a1], [1, -a1], filled, zi=[filled[0] * a1])[0]
        src = s68.glottal(filled, tilt=1.0, fmax=4200.0, jitter=0.01)
        src = src / (np.std(src) + 1e-9) + rng.standard_normal(n) * 0.25
        sc = 1.15 if fem else 1.0
        fm = [(f1 * sc, vo[0][1], vo[0][2]), (f2 * sc, vo[1][1], vo[1][2])] + [(F * sc, B, g) for F, B, g in vo[2:]]
        y = s68.formants(src, fm, blk=512) * amp_
        y = y / (np.max(np.abs(y)) + 1e-9)
        S.add(bus, y.astype(np.float32), t_start, 0.5 * vel * rng.uniform(0.6, 1.0), rng.uniform(-0.85, 0.85))


def crowd_bed(S: Song, rng, t0: float, t1: float, level: float = 0.04, bus: str = "crowd") -> None:
    """La rumeur de la salle pendant le morceau (gens qui crient, sautent) : un souffle de voix."""
    n = int((t1 - t0) * SR)
    y = np.stack([bp(rng.standard_normal(n), 250, 1800), bp(rng.standard_normal(n), 250, 1800)], axis=1)
    k = max(4, int((t1 - t0) * 2))
    env = np.interp(np.arange(n), np.linspace(0, n, k), rng.uniform(0.6, 1.0, k))
    y *= env[:, None] * level
    f = min(n // 2, int(1.0 * SR))
    y[:f] *= np.linspace(0, 1, f)[:, None]
    y[-f:] *= np.linspace(1, 0, f)[:, None]
    S.add(bus, y.astype(np.float32), t0, 1.0)


# =========================================================================== le groupe : outils communs

class Band:
    """Les Rats de Cale sur scène : deux guitares (Clou joue les deux prises : gauche et droite), la
    basse de Mouette, la batterie, la guitare solo (la « voix » des morceaux instrumentaux) et la foule."""

    def __init__(self, S: Song, kit: Kit, seed: int, lo: int = 40, drop: bool = False, tight: float = 0.005):
        self.S = S
        self.kit = kit
        self.seed = seed
        self.gL = Guitar(S, "gL", seed + 1, jitter=tight, bright=0.6, lo=lo)
        self.gR = Guitar(S, "gR", seed + 2, jitter=tight, bright=0.55, lo=lo, tune=0.06, late=0.003)
        self.gC = Guitar(S, "gC", seed + 5, jitter=tight, bright=0.6, lo=lo)       # la guitare presque claire
        self.bass = Bass(S, "bass", seed + 3, lo=lo - 12 if lo - 12 >= 26 else 28)
        self.rng = np.random.default_rng(seed + 4)

    def gtr(self, bar0: int, prog: list, patt, voicing: str = "5", vel: float = 1.0, only: str | None = None) -> None:
        if only in (None, "L"):
            self.gL.rhythm(bar0, prog, patt, voicing, vel)
        if only in (None, "R"):
            self.gR.rhythm(bar0, prog, patt, voicing, vel * 0.97)

    def drum_section(self, bar0: int, nbars: int, groove: dict, vel: float = 1.0, crash_every: int = 0,
                     fills: dict | None = None, first_crash: bool = True) -> None:
        for i in range(nbars):
            pat = dict(groove)
            if fills and i in fills:
                pat = fill(fills[i]) if isinstance(fills[i], str) else fills[i]
            elif (crash_every and i % crash_every == 0 and (i > 0 or first_crash)) or (i == 0 and first_crash):
                pat = dict(pat)
                pat["c" if (i // max(1, crash_every)) % 2 == 0 else "C"] = "X"
                for hk in ("h", "R"):
                    if hk in pat:
                        pat[hk] = "." + pat[hk][1:]
            drums(self.S, self.kit, bar0 + i, pat, vel)

    def hits(self, bar: int, beats, sym: str, crash: bool = True, ring: float = 0.0, vel: float = 1.0) -> None:
        """Coups d'ensemble (tout le groupe frappe ensemble) : les guitares ouvertes, la basse, grosse
        caisse et cymbale."""
        S = self.S
        for k, b in enumerate(beats):
            t = S.t(bar, b)
            nxt = beats[k + 1] if k + 1 < len(beats) else None
            dur = ((nxt - b) * S.spb - 0.02) if nxt is not None else (ring or 0.4)
            for g in (self.gL, self.gR):
                g.strike(t, voice(sym, "5", g.lo), dur, vel, "open")
            r = parse_chord(sym)[0]
            self.bass.note(t, root_in(r, self.bass.lo), dur, vel)
            pat = {"k": "X"}
            if crash:
                pat["c" if k % 2 == 0 else "C"] = "X"
            drums(S, self.kit, bar, pat, vel, beats=1, beat0=b)

    def count_in(self, n: int = 4) -> None:
        for k in range(n):
            drums(self.S, self.kit, -1, {"st": "x"}, 0.85, beats=1, beat0=float(self.S.beats - n + k))

    def shout(self, bar: int, beat: float, vel: float = 1.0, voices: int = 16) -> None:
        key = ("hey", int(self.rng.integers(0, 4)))
        if key not in _CROWD:
            _CROWD[key] = hey(np.random.default_rng([self.seed, key[1]]), voices)
        self.S.add("crowd", _CROWD[key], self.S.t(bar, beat) - 0.02, vel)

    def mix(self, hall: bool = True, gtr_gain: float = 42.0, gtr_level: float = 0.15, bass_level: float = 2.2,
            lead_level: float = 0.12, lead_echo: float = 0.0, crowd_level: float = 0.35) -> None:
        S = self.S
        S.fx["gL"] = lambda x: pan2(amp(x, gtr_gain, mid=2.5, scoop=-4.0, presence=1.5), -0.85) * gtr_level
        S.fx["gR"] = lambda x: pan2(amp(x, gtr_gain * 0.85, bias=0.18, mid=1.5, scoop=-5.0, presence=2.0, cab=4800), 0.85) * gtr_level
        S.fx["gC"] = lambda x: pan2(amp(x, 5.0, bias=0.1, mid=2.0, scoop=-2.0, presence=1.0, cab=5500), -0.3, 1.0) * gtr_level * 1.6
        S.fx["bass"] = lambda x: bass_amp(x) * bass_level
        de = lead_echo if lead_echo else S.spb * 0.75

        def lead_fx(x):
            y = pan2(amp(x, 26, tight=220, mid=6.0, scoop=-2.0, presence=2.0, cab=5600, bias=0.3), 0.1) * lead_level
            return echo(y, de, 0.28, 4, 2600, True, S.loop)
        S.fx["lead"] = lead_fx
        S.fx["crowd"] = lambda x: filt(x, bw("highpass", 140)) * crowd_level
        drum_fx(S, hall)
        S.send.update({"gL": 0.13, "gR": 0.13, "gC": 0.25, "bass": 0.03, "lead": 0.22, "crowd": 0.6})


def hall_master(x: np.ndarray) -> np.ndarray:
    """La sono de la Halle : un rien de bas-médium, les aigus un peu adoucis par la salle."""
    return filt(x, shelf(110, 2.5, False), peak(200, 1.0, 0.9), peak(2800, -1.5, 0.9), shelf(9500, -1.0))


def hall_ir(seed: int) -> np.ndarray:
    return room_ir(1.7, dark=0.65, predelay=0.018, er=22, seed=seed, er_span=0.07)


def ending_cheer(S: Song, band: Band, t: float, dur: float = 4.0) -> None:
    crowd_seed(band.seed + 99)
    S.add("crowd", cheer(np.random.default_rng(band.seed + 98), dur, 30, 90, band.kit), t, 1.4)


NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


def transpose(text: str, k: int) -> str:
    """Transpose une mélodie écrite « D5:1 ^E5:0.5 … » de k demi-tons."""
    out = []
    for tok in text.replace("|", " | ").split():
        if tok == "|" or tok.startswith("r:"):
            out.append(tok)
            continue
        p, d = tok.split(":")
        pre_ = ""
        while p and p[0] in "^/~>":
            if p.startswith("^1"):
                pre_ += "^1"
                p = p[2:]
            else:
                pre_ += p[0]
                p = p[1:]
        m = midi_of(p) + k
        out.append(f"{pre_}{NAMES[m % 12]}{m // 12 - 1}:{d}")
    return " ".join(out)


# =========================================================================== concert 1 : « Les Rats de Cale »

def concert_1(kit: Kit) -> Song:
    S = Song("concert_1", 184, 112, loop=False, seed=751, lead_in=4 * 60 / 184)
    B = Band(S, kit, 7510)
    crowd_seed(7510)
    hook_p = ["A", "E", "F#m", "D", "A", "E", "D", "E"]
    verse_p = ["A", "A", "E", "E", "F#m", "F#m", "D", "E"]
    pre_p = ["D", "E", "F#m", "E"]
    ch_p = ["A", "E", "F#m", "D", "A", "E", "F#m", "D", "A", "E", "F#m", "D", "A", "E", "D E", "A"]
    hook = ("C#5:1.5 B4:0.5 A4:1 E4:1 | G#4:1 A4:0.5 B4:0.5 B4:2 | A4:1.5 G#4:0.5 F#4:1 C#5:1 | D5:1 C#5:0.5 B4:0.5 A4:2 | "
            "C#5:1.5 B4:0.5 A4:1 E5:1 | E5:1 D5:0.5 C#5:0.5 B4:2 | A4:1 B4:0.5 C#5:0.5 D5:1 F#5:1 | ~E5:3 r:1")
    verse = ("r:1 E4:0.5 E4:0.5 A4:1 A4:0.5 B4:0.5 | C#5:1 B4:1 A4:2 | r:1 E4:0.5 E4:0.5 G#4:1 G#4:0.5 A4:0.5 | B4:1 A4:1 G#4:2 | "
             "r:1 F#4:0.5 G#4:0.5 A4:1 A4:0.5 B4:0.5 | C#5:1 E5:1 C#5:2 | D5:1 C#5:0.5 B4:0.5 A4:1 F#4:1 | G#4:1 A4:0.5 B4:0.5 B4:2")
    verse_b = ("r:1 E4:0.5 E4:0.5 A4:1 A4:0.5 B4:0.5 | C#5:1 B4:1 A4:2 | r:1 E4:0.5 E4:0.5 G#4:1 G#4:0.5 A4:0.5 | B4:1 A4:1 G#4:2 | "
               "r:1 F#4:0.5 G#4:0.5 A4:1 A4:0.5 B4:0.5 | C#5:1 E5:1 C#5:2 | D5:1 E5:0.5 F#5:0.5 E5:1 D5:1 | ~E5:3 r:1")
    pre = "F#4:2 A4:2 | G#4:2 B4:2 | A4:2 C#5:2 | B4:2 >E5:1 r:1"
    chorus = ("E5:2 C#5:1 E5:1 | ^E5:1.5 D5:0.5 C#5:1 B4:1 | C#5:2 A4:1 C#5:1 | D5:1 C#5:1 B4:1 A4:1 | "
              "E5:2 C#5:1 E5:1 | F#5:1.5 E5:0.5 D5:1 B4:1 | A4:1 B4:1 C#5:1 E5:1 | ~D5:2 C#5:1 B4:1 | "
              "E5:2 C#5:1 E5:1 | ^E5:1.5 D5:0.5 C#5:1 B4:1 | C#5:2 A4:1 C#5:1 | D5:1 C#5:1 B4:1 A4:1 | "
              "E5:2 C#5:1 E5:1 | F#5:1.5 E5:0.5 D5:1 B4:1 | A4:1 B4:1 C#5:1 B4:1 | ~A4:3 r:1")

    tr = transpose

    def chorus_at(b0: int, prog: list, text: str, lead_vel: float = 0.95) -> None:
        B.gtr(b0, prog, "Ooooooo" + "o")
        B.bass.line(b0, prog, "Rrrrrrrr")
        B.drum_section(b0, 16, PUNK_RIDE, 1.0, crash_every=4, fills={7: "snare4", 15: "toms"})
        lead(S, "lead", b0, text, 75101 + b0, vel=lead_vel)
        for i in range(1, 16, 2):
            B.shout(b0 + i, 3.0, 0.9)
        crowd_bed(S, B.rng, S.t(b0), S.t(b0 + 16), 0.05)

    B.count_in()
    # --- 0-3 : le riff, Clou tout seul (guitare gauche), puis la droite à la quatrième mesure
    riff = "A2:0.5 A2:0.5 A2m:0.5 A2:0.5 C#3:1 D3:1 | E3:0.5 E3:0.5 E3m:0.5 E3:0.5 D3:1 C#3:1"
    B.gL.riff(0, riff + " | " + riff, 0.95, power=True)
    B.gR.riff(2, riff, 0.9, power=True)
    drums(S, kit, 3, {"s": "........oxxxXxXX", "k": "............X..."}, 0.9)
    # --- 4-11 : tout le groupe, la mélodie du refrain-riff
    B.gtr(4, hook_p, "Oooooooo")
    B.bass.line(4, hook_p, "Rrrrrrrr")
    B.drum_section(4, 8, PUNK, 1.0, crash_every=4, fills={7: "snare8"})
    lead(S, "lead", 4, hook, 75102)
    crowd_bed(S, B.rng, S.t(4), S.t(12), 0.05)
    # --- 12-27 : premier couplet, étouffé
    B.gtr(12, verse_p * 2, "MmmmMmmm")
    B.bass.line(12, verse_p * 2, "Rrrrrrrr")
    B.drum_section(12, 16, PUNK, 0.95, crash_every=8, fills={7: "snare4", 15: "snare8"})
    lead(S, "lead", 12, verse + " | " + verse_b, 75103, vel=0.8)
    # --- 28-31 : la montée (accords ouverts sur les temps, toms)
    B.gtr(28, pre_p, "O-o-O-o-")
    B.bass.line(28, pre_p, "R-r-R-r-")
    for i in range(4):
        drums(S, kit, 28 + i, {"k": "X...X...X...X...", "3": "..x...x...x...x.", "s": "....X.......X..." if i < 3 else "....X...xxXXXXXX",
                               "c": "X..............." if i == 0 else "................"}, 0.95)
    lead(S, "lead", 28, pre, 75104)
    # --- 32-47 : refrain
    chorus_at(32, ch_p, chorus)
    # --- 48-55 : deuxième couplet
    B.gtr(48, verse_p, "MmmmMmmm")
    B.bass.line(48, verse_p, "Rrrrrrrr")
    B.drum_section(48, 8, PUNK2, 0.95, crash_every=8, fills={7: "snare8"})
    lead(S, "lead", 48, verse_b, 75105, vel=0.8)
    # --- 56-59 : la montée
    B.gtr(56, pre_p, "O-o-O-o-")
    B.bass.line(56, pre_p, "R-r-R-r-")
    for i in range(4):
        drums(S, kit, 56 + i, {"k": "X...X...X...X...", "3": "..x...x...x...x.", "s": "....X.......X..." if i < 3 else "....X...xxXXXXXX",
                               "c": "X..............." if i == 0 else "................"}, 0.95)
    lead(S, "lead", 56, pre, 75106)
    # --- 60-75 : refrain
    chorus_at(60, ch_p, chorus)
    # --- 76-83 : le pont (demi-tempo, la basse devant, une guitare en arpèges)
    br = ["F#m", "D", "A", "E", "F#m", "D", "E", "E"]
    B.bass.line(76, br, ["R-r-r-o-", "R-r-r-o-", "R-r-r-o-", "R-r-f-o-"])
    arp = "F#3:0.5 C#4:0.5 F#4:0.5 A4:0.5 C#5:0.5 A4:0.5 F#4:0.5 C#4:0.5 | D3:0.5 A3:0.5 D4:0.5 F#4:0.5 A4:0.5 F#4:0.5 D4:0.5 A3:0.5 | " \
          "A2:0.5 E3:0.5 A3:0.5 C#4:0.5 E4:0.5 C#4:0.5 A3:0.5 E3:0.5 | E3:0.5 B3:0.5 E4:0.5 G#4:0.5 B4:0.5 G#4:0.5 E4:0.5 B3:0.5"
    B.gC.riff(76, arp + " | " + arp, 0.8)
    B.gL.rhythm(80, br[4:], "O-------", "5", 0.9)
    for i in range(8):
        drums(S, kit, 76 + i, HALF if i < 4 else {"k": "X.....x.X.......", "s": "....X.......X...", "R": "x.x.x.x.x.x.x.x."}, 0.85)
    lead(S, "lead", 80, "C#5:4 | D5:2 E5:2 | ~F#5:4 | E5:2 G#5:2", 75107, vel=0.75)
    crowd_sing(S, 80, "C#4:2 C#4:2 | D4:2 E4:2 | F#4:4 | E4:2 G#4:2", B.rng, 10, vel=0.7)
    # --- 84-87 : tout s'arrête… la batterie remonte, la foule crie, un temps de silence
    B.gtr(84, ["E", "E", "E", "E"], ["mmmmmmmm", "mmmmmmmm", "MmMmMmMm", "MMMMMM.."], "5")
    B.bass.line(84, ["E", "E", "E", "E"], ["rrrrrrrr", "rrrrrrrr", "RrRrRrRr", "RRRRRR.."])
    drums(S, kit, 84, {"k": "X...X...X...X...", "s": "x.x.x.x.x.x.x.x."}, 0.7)
    drums(S, kit, 85, {"k": "X...X...X...X...", "s": "x.x.x.x.x.x.x.x."}, 0.8)
    drums(S, kit, 86, {"k": "X.X.X.X.X.X.X.X.", "s": "xxxxxxxxxxxxxxxx"}, 0.9)
    drums(S, kit, 87, {"k": "X.X.X.X.X.X.....", "s": "XXXXXXXXXXXX....", "c": "............"}, 1.0)
    for b, bt in ((85, 0), (85, 2), (86, 0), (86, 2), (87, 0), (87, 1), (87, 2)):
        B.shout(b, bt, 1.0)
    # --- 88-103 : le dernier refrain, un ton plus haut (si majeur)
    chorus_at(88, ["B", "F#", "G#m", "E", "B", "F#", "G#m", "E", "B", "F#", "G#m", "E", "B", "F#", "E F#", "B"], tr(chorus, 2), 1.0)
    # --- 104-107 : le riff en si, et 108-111 : la grande fin
    end_p = ["B", "F#", "E", "F#"]
    B.gtr(104, end_p, "Oooooooo")
    B.bass.line(104, end_p, "Rrrrrrrr")
    B.drum_section(104, 4, PUNK, 1.0, crash_every=2, fills={3: "toms_big"})
    lead(S, "lead", 104, tr("C#5:1.5 B4:0.5 A4:1 E5:1 | E5:1 D5:0.5 C#5:0.5 B4:2 | A4:1 B4:0.5 C#5:0.5 D5:1 F#5:1 | ~E5:3 r:1", 2), 75108)
    B.hits(108, [0.0, 1.5, 3.0], "B")
    B.hits(109, [0.0], "B", ring=4.5 * S.spb + 3.0)
    tom_roll(S, kit, 109, 0.5, 3.5, "11223344", 4, 0.9, 0.4)
    drums(S, kit, 110, {"c": "X...X...X...X...", "C": "..X...X...X...X.", "k": "XXXXXXXXXXXXXXXX"}, 0.85)
    drums(S, kit, 111, {"k": "X", "c": "X", "C": "X", "s": "X"}, 1.0)
    B.hits(111, [0.0], "B", crash=False, ring=4.0)
    lead(S, "lead", 109, "~B5:4 | ~B5:4 | r:4", 75109, vel=0.8)
    ending_cheer(S, B, S.t(111, 1.0), 4.5)
    B.mix(True)
    return S


# =========================================================================== concert 2 : « Rangers et Pâquerettes »

def feedback(S: Song, track: str, bar: float, beats: float, m: float, seed: int, vel: float = 0.5) -> None:
    """Le larsen (pour rire, pas méchant) : une note tenue qui enfle toute seule puis saute à
    l'harmonique du dessus."""
    rng = np.random.default_rng(seed)
    dur = beats * S.spb
    n = int((dur + 0.1) * SR)
    x = np.arange(n) / SR
    semi = np.where(x > dur * 0.62, 12.0, 0.0) + 0.15 * np.sin(2 * np.pi * 5.0 * x) * np.clip((x - 0.4) / 0.6, 0, 1)
    semi = signal.lfilter([0.002], [1, -0.998], semi, zi=[semi[0] * 0.998])[0]
    y = string(hz(m), dur + 0.1, rng, t60=30.0, bright=0.95, hard=0.9, pick=0.08, fmul=2 ** (semi / 12))
    y *= (0.08 + 0.92 * np.clip(x / dur, 0, 1) ** 2)
    y = choke(y, dur, 0.03)
    S.di(track, y, S.t(bar), vel)


def concert_2(kit: Kit) -> Song:
    S = Song("concert_2", 200, 104, loop=False, seed=752, lead_in=0.0)
    B = Band(S, kit, 7520, tight=0.004)
    crowd_seed(7520)
    riff = "E2:0.5 E2:0.5 G2:0.5 E2:0.5 A2:0.5 E2:0.5 B2:0.5 A2:0.5 | E2:0.5 E2:0.5 G2:0.5 E2:0.5 D3:0.5 C#3:0.5 B2:1"
    verse_p = ["E", "E", "D", "A"] * 4
    ch_p = ["A", "B", "E", "C#m", "A", "B", "E", "E"]
    verse = ("B4:1 B4:0.5 A4:0.5 G#4:1 E4:1 | r:2 E4:0.5 F#4:0.5 G#4:1 | A4:1 A4:0.5 G#4:0.5 F#4:1 D4:1 | E4:1 C#4:1 r:2 | "
             "B4:1 B4:0.5 A4:0.5 G#4:1 E4:1 | r:2 G#4:0.5 A4:0.5 B4:1 | D5:1 C#5:0.5 B4:0.5 A4:1 F#4:1 | E4:2 r:2")
    chorus = ("C#5:1 E5:1 C#5:1 A4:1 | D#5:1 F#5:1 D#5:1 B4:1 | E5:1.5 D#5:0.5 E5:1 B4:1 | C#5:2 G#4:2 | "
              "C#5:1 E5:1 C#5:1 A4:1 | D#5:1 F#5:1 B5:2 | ~G#5:4 | E5:2 r:2")
    solo = ("E5:0.5 G#5:0.5 B5:0.5 G#5:0.5 ^B5:1 G#5:0.5 E5:0.5 | F#5:0.5 A5:0.5 D6:0.5 A5:0.5 F#5:1 D5:1 | "
            "C#5:0.5 E5:0.5 A5:0.5 E5:0.5 C#6:1 A5:1 | ~B5:2 G#5:0.5 F#5:0.5 E5:1 | "
            "^G#5:1 G#5:0.5 F#5:0.5 E5:0.5 F#5:0.5 G#5:1 | A5:0.5 G#5:0.5 F#5:0.5 D5:0.5 A5:1 F#5:1 | "
            "E5:0.5 C#5:0.5 E5:0.5 A5:0.5 C#6:0.5 B5:0.5 A5:1 | ~G#5:3 r:1 | "
            "B5:0.5 B5:0.5 B5:0.5 B5:0.5 ^C#6:1 B5:1 | A5:0.5 A5:0.5 A5:0.5 A5:0.5 ^B5:1 A5:1 | "
            "C#6:0.5 B5:0.5 A5:0.5 G#5:0.5 A5:0.5 B5:0.5 C#6:1 | ~E6:4 | "
            "E6:0.5 D6:0.5 B5:0.5 G#5:0.5 E6:0.5 D6:0.5 B5:0.5 G#5:0.5 | D6:0.5 A5:0.5 F#5:0.5 D5:0.5 D6:0.5 A5:0.5 F#5:0.5 D5:0.5 | "
            "C#6:0.5 A5:0.5 E5:0.5 C#5:0.5 E5:0.5 A5:0.5 C#6:0.5 E6:0.5 | ~E6:3 r:1")

    def chorus_at(b0: int, n: int = 8, vel: float = 1.0) -> None:
        prog = (ch_p * 2)[:n]
        B.gtr(b0, prog, "Oooooooo", vel=vel)
        B.bass.line(b0, prog, "Rrrrrrrr")
        B.drum_section(b0, n, PUNK_RIDE, vel, crash_every=4, fills={n - 1: "snare8"})
        lead(S, "lead", b0, " | ".join((chorus.split("|") * 2)[:n]), 75201 + b0)
        for i in range(0, n, 2):
            B.shout(b0 + i, 1.0, 1.0)
            B.shout(b0 + i, 3.0, 1.0)
        crowd_bed(S, B.rng, S.t(b0), S.t(b0 + n), 0.06)

    # --- 0-1 : le larsen (comique), quatre coups de tom basse, la foule qui crie
    feedback(S, "lead", 0, 7.0, 71, 75200, 0.5)
    drums(S, kit, 1, {"4": "X.X.X.X.", "k": "X.X.X.X."}, 0.95)
    S.add("crowd", cheer(np.random.default_rng(7529), 2.5, 16, 30, kit), S.t(0), 0.8)
    # --- 2-9 : le riff, guitares et basse à l'unisson
    B.gL.riff(2, (riff + " | ") * 3 + riff, 1.0, power=True)
    B.gR.riff(2, (riff + " | ") * 3 + riff, 0.95, power=True)
    B.bass.riff(2, transpose((riff + " | ") * 3 + riff, -12), 1.0)
    B.drum_section(2, 8, POLKA, 1.0, crash_every=4, fills={7: "snare4"})
    # --- 10-25 : couplet (le « skank beat »)
    B.gtr(10, verse_p, "MmMmMmMm")
    B.bass.line(10, verse_p, "Rrrrrrrr")
    B.drum_section(10, 16, POLKA, 0.95, crash_every=8, fills={7: "snare4", 15: "toms"})
    lead(S, "lead", 10, verse + " | " + verse, 75202, vel=0.8)
    # --- 26-33 : refrain (« Hé ! Hé ! »)
    chorus_at(26)
    # --- 34-49 : deuxième couplet (demi-mesure punk, puis le skank)
    B.gtr(34, verse_p, ["MmmmMmmm", "MmmmMmmm", "MmMmMmMm", "MmMmMmMm"])
    B.bass.line(34, verse_p, "Rrrrrrrr")
    B.drum_section(34, 8, PUNK2, 0.95, crash_every=8, fills={7: "snare8"})
    B.drum_section(42, 8, POLKA, 0.95, crash_every=8, fills={7: "toms"})
    lead(S, "lead", 34, verse + " | " + verse, 75203, vel=0.8)
    # --- 50-57 : refrain
    chorus_at(50)
    # --- 58-65 : le passage lourd (demi-tempo), la foule crie sur les temps forts
    br = ["C#m", "A", "E", "B"] * 2
    B.gtr(58, br, ["O-------", "O-----O-", "O-------", "O-O-O-O-"])
    B.bass.line(58, br, ["R-------", "R-----r-", "R-------", "R-r-r-r-"])
    for i in range(8):
        drums(S, kit, 58 + i, {"k": "X.....X.........", "s": "........X.......", "z": "X.......X.......",
                               "h": "....x.......x..."} if i < 7 else fill("toms_big"), 1.0)
        B.shout(58 + i, 0.0, 0.9)
    # --- 66-81 : le solo de guitare
    sp = ["E", "D", "A", "E"] * 4
    B.gtr(66, sp, "MmMmOoOo")
    B.bass.line(66, sp, "Rrrrrrrr")
    B.drum_section(66, 16, POLKA_RIDE, 1.0, crash_every=4, fills={15: "rush"})
    lead(S, "lead", 66, solo, 75204, vel=1.0, vib=0.32)
    crowd_bed(S, B.rng, S.t(66), S.t(82), 0.05)
    # --- 82-97 : deux refrains, tout le monde
    chorus_at(82, 16, 1.0)
    # --- 98-101 : le riff, 102-103 : la fin
    B.gL.riff(98, riff + " | " + riff, 1.0, power=True)
    B.gR.riff(98, riff + " | " + riff, 0.95, power=True)
    B.bass.riff(98, transpose(riff + " | " + riff, -12), 1.0)
    B.drum_section(98, 4, POLKA, 1.0, crash_every=2, fills={3: "rush"})
    B.hits(102, [0.0, 0.5, 1.0, 1.5], "E")
    B.hits(102, [2.0], "E", ring=2.0 * S.spb + 3.0)
    tom_roll(S, kit, 102, 2.5, 3.5, "1234", 4, 0.9, 0.5)
    drums(S, kit, 103, {"c": "....X", "C": "....X", "k": "....X", "s": "....X"}, 1.0)
    B.hits(103, [2.0], "E", crash=False, ring=3.5)
    ending_cheer(S, B, S.t(103, 2.5), 4.5)
    B.mix(True, gtr_gain=48.0)
    return S


# =========================================================================== concert 3 : « Tout le Monde Chante » (l'hymne)

def claps(S: Song, kit: Kit, bar0: int, nbars: int, beats=(1.0, 3.0), people: int = 14, vel: float = 0.8) -> None:
    """Toute la salle tape dans ses mains (chacun un peu en avance ou en retard)."""
    for i in range(nbars):
        for b in beats:
            for _ in range(people):
                c = kit.get("clap", float(S.rng.uniform(0.3, 0.9))).mean(axis=1)
                S.add("crowd", lp(c, float(S.rng.uniform(2500, 6000))), S.t(bar0 + i, b) + float(S.rng.normal(0.01, 0.018)),
                      vel * 0.22 * float(S.rng.uniform(0.5, 1.0)), float(S.rng.uniform(-0.9, 0.9)))


def concert_3(kit: Kit) -> Song:
    S = Song("concert_3", 160, 96, loop=False, seed=753, lead_in=0.0)
    B = Band(S, kit, 7530)
    crowd_seed(7530)
    intro_p = ["D", "A", "Bm", "G"]
    hook_p = ["D", "A", "Bm", "G", "D", "A", "G", "A"]
    verse_p = ["D", "D", "A", "A", "Bm", "Bm", "G", "A"]
    ch_p = ["G", "D", "A", "Bm", "G", "D", "A", "A", "G", "D", "A", "Bm", "G", "D", "A", "D"]
    hook = ("F#4:1 A4:1 D5:2 | C#5:1 B4:1 A4:2 | B4:1 A4:1 F#4:1 D4:1 | G4:2 B4:2 | F#4:1 A4:1 D5:2 | E5:1 D5:1 C#5:2 | "
            "B4:1 A4:1 G4:1 B4:1 | ~A4:3 r:1")
    verse = ("D4:1 F#4:1 A4:1 F#4:1 | A4:1.5 G4:0.5 F#4:2 | E4:1 A4:1 C#5:1 A4:1 | B4:1.5 A4:0.5 E4:2 | F#4:1 B4:1 D5:1 B4:1 | "
             "C#5:1.5 B4:0.5 F#4:2 | G4:1 B4:1 D5:1 B4:1 | ~A4:3 r:1")
    sing = ("B4:2 A4:1 G4:1 | A4:2 F#4:1 D4:1 | E4:1 F#4:1 G4:1 A4:1 | F#4:3 r:1 | B4:2 A4:1 G4:1 | A4:2 F#4:1 A4:1 | "
            "B4:1 A4:1 G4:1 E4:1 | A4:3 r:1 | B4:2 A4:1 G4:1 | A4:2 F#4:1 D4:1 | E4:1 F#4:1 G4:1 A4:1 | F#4:2 B4:2 | "
            "D5:2 B4:1 G4:1 | A4:2 F#4:1 D4:1 | E4:1.5 F#4:0.5 G4:1 E4:1 | D4:3 r:1")

    def chorus_at(b0: int, prog: list, k: int = 0, crowd: float = 1.0) -> None:
        B.gtr(b0, prog, "Oooooooo")
        B.bass.line(b0, prog, "Rrrrrrrr")
        B.drum_section(b0, 16, PUNK_RIDE, 1.0, crash_every=4, fills={7: "snare4", 15: "toms"})
        lead(S, "lead", b0, transpose(sing, k + 12), 75301 + b0, vel=0.85)
        crowd_sing(S, b0, transpose(sing, k), B.rng, 14, "o", crowd)
        crowd_bed(S, B.rng, S.t(b0), S.t(b0 + 16), 0.05)

    # --- 0-3 : Clou seul, accords ouverts qui sonnent ; la salle tape dans ses mains
    B.gC.rhythm(0, intro_p, ["O---O-u-", "O---O-u-", "O---O-u-", "O---O-o-"], "full", 0.8)
    claps(S, kit, 1, 3)
    # --- 4-11 : tout le groupe
    B.gtr(4, hook_p, "Oooooooo")
    B.bass.line(4, hook_p, "Rrrrrrrr")
    B.drum_section(4, 8, PUNK_RIDE, 1.0, crash_every=4, fills={7: "snare8"})
    lead(S, "lead", 4, hook, 75302)
    claps(S, kit, 4, 4, vel=0.6)
    crowd_bed(S, B.rng, S.t(4), S.t(12), 0.05)
    # --- 12-27 : couplet
    B.gtr(12, verse_p * 2, ["MmmmMmmm", "MmmmMmmm", "MmmmMmmm", "MmmmMmmm", "MmmmMmmm", "MmmmMmmm", "MmmmMmmm", "O-o-O-o-"])
    B.bass.line(12, verse_p * 2, "Rrrrrrrr")
    B.drum_section(12, 16, PUNK, 0.92, crash_every=8, fills={7: "snare4", 15: "snare8"})
    lead(S, "lead", 12, verse + " | " + verse, 75303, vel=0.8)
    # --- 28-43 : refrain, la foule chante
    chorus_at(28, ch_p)
    # --- 44-51 : deuxième couplet
    B.gtr(44, verse_p, ["MmmmMmmm"] * 7 + ["O-o-O-o-"])
    B.bass.line(44, verse_p, "Rrrrrrrr")
    B.drum_section(44, 8, PUNK2, 0.92, crash_every=8, fills={7: "snare8"})
    lead(S, "lead", 44, verse, 75304, vel=0.8)
    # --- 52-67 : refrain
    chorus_at(52, ch_p, 0, 1.1)
    # --- 68-73 : le pont tout doux : la guitare seule, la basse, les mains, la foule qui chante
    soft = ["G", "D", "A", "Bm", "G", "A"]
    B.gC.rhythm(68, soft, "O---o-u-", "full", 0.7)
    B.bass.line(68, soft, "R-------")
    for i in range(6):
        drums(S, kit, 68 + i, {"k": "X.......", "R": "x...x..."}, 0.6)
    claps(S, kit, 68, 6, vel=0.9)
    crowd_sing(S, 68, "B4:2 A4:1 G4:1 | A4:2 F#4:1 D4:1 | E4:1 F#4:1 G4:1 A4:1 | F#4:3 r:1 | B4:2 A4:1 G4:1 | A4:4", B.rng, 16, "o", 0.9)
    # --- 74-75 : la montée (vers mi majeur)
    B.gtr(74, ["B", "B"], ["MmmmMmmm", "MMMMMMMM"])
    B.bass.line(74, ["B", "B"], ["rrrrrrrr", "RRRRRRRR"])
    drums(S, kit, 74, {"k": "X...X...X...X...", "s": "..x...x...x.xxxx"}, 0.85)
    drums(S, kit, 75, {"k": "X.X.X.X.X.X.X.X.", "s": "xxxxxxxxXXXXXXXX"}, 0.95)
    B.shout(75, 2.0, 1.0)
    # --- 76-91 : le dernier refrain, en mi, tout le monde
    chorus_at(76, ["A", "E", "B", "C#m", "A", "E", "B", "B", "A", "E", "B", "C#m", "A", "E", "B", "E"], 2, 1.3)
    # --- 92-95 : la fin
    B.gtr(92, ["A", "B"], "O-o-O-o-")
    B.bass.line(92, ["A", "B"], "R-r-R-r-")
    drums(S, kit, 92, {"k": "X...X...X...X...", "4": "..x...x...x...x.", "s": "....X.......X...", "c": "X..............."}, 1.0)
    drums(S, kit, 93, {"k": "X...X...X...X...", "4": "..x...x...x...x.", "s": "....X...xxxxXXXX"}, 1.0)
    B.hits(94, [0.0], "E", ring=4 * S.spb + 2.5)
    tom_roll(S, kit, 94, 0.5, 3.5, "11223344", 4, 0.85, 0.4)
    drums(S, kit, 95, {"k": "X", "c": "X", "C": "X", "s": "X"}, 1.0)
    B.hits(95, [0.0], "E", crash=False, ring=4.0)
    lead(S, "lead", 92, "C#5:4 | D#5:4 | ~E5:4 | ~E5:4", 75305, vel=0.8)
    crowd_sing(S, 92, "C#4:4 | D#4:4 | E4:4 | E4:4", B.rng, 16, "o", 1.0)
    ending_cheer(S, B, S.t(95, 1.5), 5.0)
    B.mix(True, gtr_gain=38.0)
    return S


# =========================================================================== concert de Gédéon : « Gédéon Tape Fort »

def gedeon_solo(S: Song, kit: Kit, bar0: int, rng) -> None:
    """Le solo d'ouverture de Gédéon (16 mesures) : tribal sur les toms, rudiments à la caisse claire,
    roulements autour des fûts, double grosse caisse, triolets, et la grande montée."""
    d = lambda b, pat, v=1.0, **kw: drums(S, kit, bar0 + b, pat, v, human=0.0025, **kw)
    d(0, {"k": "X..x..X.X..x..X.", "4": "x..x..x.x..x..x.", "2": "........X.......", "p": "x...x...x...x..."}, 0.85)
    d(1, {"k": "X..x..X.X..x..X.", "4": "x..x..x.x..x..x.", "3": "....X.......X.xx", "p": "x...x...x...x..."}, 0.9)
    d(2, {"s": "XgxgXgxgXgxgXgxg", "k": "X.......X.......", "p": "x...x...x...x..."}, 0.85)
    d(3, {"s": "XgxgxgXgxgXgXxXx", "k": "X.......X...X...", "c": "............X..."}, 0.9)
    tom_roll(S, kit, bar0 + 4, 0.0, 2.0, "1234", 4, 0.85, 0.2)
    tom_roll(S, kit, bar0 + 4, 2.0, 2.0, "4321", 4, 0.85, 0.2)
    d(4, {"k": "X.......X......."}, 0.9)
    d(5, {"s": "X.xxX.xxX.xxXXXX", "1": "..x...x...x.....", "k": "X...X...X...X...", "c": "X..............."}, 0.95)
    d(6, {"k": "XxXxXxXxXxXxXxXx", "c": "X...X...X...X...", "s": "....X.......X..."}, 0.95)
    d(7, {"k": "XxXxXxXxXxXxXxXx", "C": "X...X...X...X...", "s": "....X.......X.XX", "z": "............X..."}, 1.0)
    d(8, {"h": "x.xxx.xxx.xxx.xx", "k": "X..X..X...X..X..", "s": "....X..o.o..X..o"}, 0.85)
    d(9, {"h": "x.xxx.xxx.x.....", "k": "X..X..X...X.....", "s": "....X..o.o..xxXX", "o": "..........x....."}, 0.9)
    # triolets autour des toms (12 par mesure)
    d(10, {"1": "xx.xx.......", "2": "..x..xx.....", "3": "........xx..", "4": "..........xx", "k": "x..x..x..x.."}, 0.9)
    d(11, {"s": "xxx.........", "1": "...xxx......", "3": "......xxx...", "4": ".........XXX", "k": "x..x..x..x.."}, 0.95)
    d(12, {"k": "XxXxXxXxXxXxXxXx", "s": "X.X.X.X.X.X.X.X.", "z": "X...X...X...X..."}, 0.9)
    d(13, {"k": "XxXxXxXxXxXxXxXx", "s": "X.X.X.X.X.X.XXXX", "c": "X.......X......."}, 0.95)
    tom_roll(S, kit, bar0 + 14, 0.0, 4.0, "11112222333344444", 6, 0.8, 0.4)
    d(14, {"k": "X..X..X..X..X..X..X..X.."}, 0.8)
    d(15, {"s": "oooxxxxxXXXXXXXX", "k": "X...X...X...XXXX", "4": "............XXXX"}, 1.0)
    crowd_seed(7549)
    S.add("crowd", cheer(np.random.default_rng(7548), 3.0, 18, 40, kit), S.t(bar0 + 6), 0.7)
    S.add("crowd", cheer(np.random.default_rng(7547), 3.0, 18, 40, kit), S.t(bar0 + 12), 0.8)


def concert_gedeon(kit: Kit) -> Song:
    S = Song("concert_gedeon", 192, 112, loop=False, seed=754, lead_in=0.0)
    B = Band(S, kit, 7540, tight=0.0035)
    crowd_seed(7540)
    hook_p = ["G", "D", "Em", "C", "G", "D", "C", "D"]
    verse_p = ["G", "G", "C", "C", "Em", "D", "C", "D"]
    ch_p = ["C", "G", "D", "Em", "C", "G", "D", "D", "C", "G", "D", "Em", "C", "G", "D", "G"]
    hook = ("B4:1 D5:1 G5:1.5 F#5:0.5 | F#5:1 E5:1 D5:2 | E5:1 G5:1 B5:1.5 A5:0.5 | G5:1 E5:1 C5:2 | B4:1 D5:1 G5:1.5 A5:0.5 | "
            "B5:1 A5:1 F#5:2 | E5:1 G5:1 E5:1 C5:1 | ~D5:3 r:1")
    verse = ("G4:1 B4:0.5 D5:0.5 D5:1 B4:1 | A4:1 B4:1 G4:2 | E4:1 G4:0.5 C5:0.5 C5:1 B4:1 | A4:1 G4:1 E4:2 | "
             "B4:1 B4:0.5 C5:0.5 D5:1 E5:1 | F#5:1 E5:1 D5:2 | C5:1 E5:1 G5:1 E5:1 | ~D5:3 r:1")
    chorus = ("E5:2 G5:1 E5:1 | D5:2 B4:1 G4:1 | A4:1 B4:1 C5:1 D5:1 | B4:3 r:1 | E5:2 G5:1 E5:1 | D5:1 G5:1 B5:2 | ~A5:4 | F#5:2 r:2 | "
              "E5:2 G5:1 E5:1 | D5:2 B4:1 G4:1 | A4:1 B4:1 C5:1 D5:1 | B4:3 r:1 | E5:2 G5:1 E5:1 | D5:1 G5:1 B5:2 | A5:1.5 B5:0.5 A5:1 F#5:1 | ~G5:3 r:1")
    big = {3: "toms_big", 7: "toms", 11: "toms_big", 15: "rush"}

    def chorus_at(b0: int, prog: list, text: str) -> None:
        B.gtr(b0, prog, "Oooooooo")
        B.bass.line(b0, prog, "Rrrrrrrr")
        B.drum_section(b0, 16, PUNK_RIDE, 1.0, crash_every=2, fills=big)
        lead(S, "lead", b0, text, 75401 + b0)
        for i in range(1, 16, 2):
            B.shout(b0 + i, 3.0, 1.0)
        crowd_bed(S, B.rng, S.t(b0), S.t(b0 + 16), 0.06)

    # --- 0-15 : le solo de Gédéon
    gedeon_solo(S, kit, 0, B.rng)
    crowd_bed(S, B.rng, S.t(0), S.t(16), 0.035)
    # --- 16-23 : le groupe entre
    B.gtr(16, hook_p, "Oooooooo")
    B.bass.line(16, hook_p, "Rrrrrrrr")
    B.drum_section(16, 8, PUNK, 1.0, crash_every=2, fills={3: "toms", 7: "toms_big"})
    lead(S, "lead", 16, hook, 75402)
    B.shout(16, 0.0, 1.0)
    # --- 24-39 : couplet (Gédéon place des roulements partout)
    B.gtr(24, verse_p * 2, "MmmmMmmm")
    B.bass.line(24, verse_p * 2, "Rrrrrrrr")
    B.drum_section(24, 16, PUNK2, 0.95, crash_every=4, fills={3: "flam", 7: "toms", 11: "snare8", 15: "toms_big"})
    lead(S, "lead", 24, verse + " | " + verse, 75403, vel=0.8)
    # --- 40-55 : refrain
    chorus_at(40, ch_p, chorus)
    # --- 56-59 : arrêts : le groupe frappe, la batterie répond
    for i in range(4):
        B.hits(56 + i, [0.0], ["C", "D", "Em", "D"][i], ring=0.9 * S.spb)
        tom_roll(S, kit, 56 + i, 1.0, 3.0, ["1234", "4321", "1324", "11223344"][i], 4, 0.9, 0.3)
        drums(S, kit, 56 + i, {"k": "....X...X...X..."}, 0.8)
    # --- 60-67 : deuxième couplet
    B.gtr(60, verse_p, "MmMmMmMm")
    B.bass.line(60, verse_p, "Rrrrrrrr")
    B.drum_section(60, 8, POLKA, 0.95, crash_every=4, fills={3: "toms", 7: "rush"})
    lead(S, "lead", 60, verse, 75404, vel=0.8)
    # --- 68-83 : refrain
    chorus_at(68, ch_p, chorus)
    # --- 84-91 : second solo de batterie, le groupe ponctue
    for i in range(8):
        if i % 2 == 0:
            B.hits(84 + i, [0.0, 2.0], "G" if i % 4 == 0 else "D", ring=0.8 * S.spb)
        pats = [{"k": "X.X.X.X.X.X.X.X.", "s": "....X..x.xX.X.XX"}, {"1": "xxxx............", "2": "....xxxx........", "3": "........xxxx....", "4": "............XXXX", "k": "X...X...X...X..."},
                {"k": "XxXxXxXxXxXxXxXx", "s": "....X.......X...", "c": "X.......X......."}, {"s": "XgxgXgxgXgxgXXXX", "k": "X..X..X..X..X..."},
                {"k": "X.X.X.X.X.X.X.X.", "s": "x.xxx.xxx.xxXXXX", "z": "X..............."}, {"1": "xxx.........", "2": "...xxx......", "3": "......xxx...", "4": ".........XXX"},
                {"k": "XxXxXxXxXxXxXxXx", "s": "X.X.X.X.X.X.X.X.", "C": "X...X...X...X..."}, {"s": "oooxxxxxXXXXXXXX", "k": "X...X...X...XXXX"}]
        drums(S, kit, 84 + i, pats[i], 1.0, human=0.0025)
        if i % 2 == 1:
            B.shout(84 + i, 3.0, 1.0)
    S.add("crowd", cheer(np.random.default_rng(7546), 3.0, 20, 50, kit), S.t(88), 0.8)
    # --- 92-107 : le dernier refrain, un ton plus haut (la majeur)
    chorus_at(92, ["D", "A", "E", "F#m", "D", "A", "E", "E", "D", "A", "E", "F#m", "D", "A", "E", "A"], transpose(chorus, 2))
    # --- 108-111 : la fin, le grand roulement
    B.hits(108, [0.0, 0.5, 1.5, 2.0, 3.0], "A")
    B.hits(109, [0.0], "A", ring=2 * 4 * S.spb + 3.0)
    tom_roll(S, kit, 109, 0.0, 4.0, "1111222233334444", 4, 0.85, 0.3)
    tom_roll(S, kit, 110, 0.0, 4.0, "1234123412341234", 6, 0.9, 0.5)
    drums(S, kit, 109, {"k": "X...X...X...X..."}, 0.8)
    drums(S, kit, 110, {"k": "XxXxXxXxXxXxXxXx", "c": "X.......X......."}, 0.9)
    drums(S, kit, 111, {"k": "X", "c": "X", "C": "X", "s": "X", "z": "X"}, 1.0)
    B.hits(111, [0.0], "A", crash=False, ring=4.0)
    lead(S, "lead", 109, "~A5:4 | ~C#6:4 | ~E6:4", 75405, vel=0.85)
    ending_cheer(S, B, S.t(111, 1.0), 5.0)
    B.mix(True, gtr_gain=44.0)
    return S


# =========================================================================== Port-Boucan (le jour) : ska-punk

def boucan(kit: Kit) -> Song:
    S = Song("boucan", 152, 76, loop=True, seed=755)
    rng = np.random.default_rng(7550)
    B = Band(S, kit, 7550)
    sk = Guitar(S, "skank", 7556, jitter=0.004, bright=0.7)
    A = ["G", "G", "C", "D", "G", "Em", "C D", "G"]
    Bp = ["C", "D", "G", "Em", "C", "D", "G", "G"]
    dub = ["Em", "Em", "C", "C", "Em", "Em", "D", "D"]
    turn = ["C", "D", "G", "Em", "Am", "D", "G", "D7"]
    intro = ["G", "C", "D", "D7"]
    melA = ("D5:0.5 r:0.5 B4:0.5 D5:0.5 G5:1 F#5:0.5 E5:0.5 | D5:1 B4:1 G4:1 r:1 | E5:0.5 r:0.5 C5:0.5 E5:0.5 G5:1 E5:0.5 C5:0.5 | "
            "A4:1 B4:0.5 C5:0.5 D5:1 r:1 | D5:0.5 r:0.5 B4:0.5 D5:0.5 G5:1 A5:0.5 B5:0.5 | A5:1 G5:0.5 E5:0.5 E5:1 r:1 | "
            "C5:0.5 E5:0.5 G5:0.5 E5:0.5 A5:0.5 F#5:0.5 D5:1 | G5:1 D5:1 G4:1 r:1")
    melA2 = ("D5:0.5 r:0.5 B4:0.5 D5:0.5 G5:1 F#5:0.5 E5:0.5 | D5:1 B4:1 G4:1 r:1 | E5:0.5 r:0.5 C5:0.5 E5:0.5 G5:1 E5:0.5 C5:0.5 | "
             "A4:1 B4:0.5 C5:0.5 D5:1 r:1 | B5:1 A5:0.5 G5:0.5 A5:1 G5:0.5 E5:0.5 | G5:1 E5:0.5 D5:0.5 E5:1 r:1 | "
             "C5:0.5 E5:0.5 G5:0.5 C6:0.5 A5:0.5 F#5:0.5 D5:1 | G5:2 r:2")
    melB = "E5:4 | F#5:4 | D5:2 B4:2 | E5:4 | G5:4 | A5:4 | B5:2 A5:1 G5:1 | G5:3 r:1"
    melDub = "B4:2 G4:1 E4:1 | r:4 | C5:2 B4:1 G4:1 | r:4 | B4:1 D5:1 E5:2 | r:4 | F#5:2 E5:1 D5:1 | E5:3 r:1"
    melTurn = ("E5:1 G5:1 E5:1 C5:1 | F#5:1 A5:1 F#5:1 D5:1 | G5:2 D5:2 | E5:2 B4:2 | C5:1 E5:1 A5:1 G5:1 | F#5:2 A5:2 | "
               "G5:2 B5:2 | A5:1 F#5:1 D5:1 C5:1")
    org = lambda m, d, v: organ(m, d, v, rng, combo=0.7, perc=0.5)
    toy = lambda m, d, v: organ(m, d, v, rng, combo=0.9, perc=0.9)

    def ska(b0: int, prog: list, vel: float = 1.0, organ_on: bool = True, walk: bool = True, fills=None, crash: int = 8) -> None:
        sk.rhythm(b0, prog, ".s.s.s.s", vel=vel)
        if organ_on:
            chords_of(S, None, "organ", b0, prog, 64, 78, 3, [0.5, 1.5, 2.5, 3.5], 0.3, 0.5 * vel, synth=org)
        B.bass.line(b0, prog, ["r3f6", "rf3a"] if walk else "rrrr", vel)
        for i in range(len(prog)):
            pat = dict(SKA)
            if fills and i in fills:
                pat = fills[i]
            elif crash and i % crash == 0:
                pat["c"] = "X"
            drums(S, kit, b0 + i, pat, 0.9 * vel)

    ska_fill = {"k": "X.......X.......", "x": "....x...........", "s": "........xxXxXxXX", "h": "x.x.x.x........."}
    ska_fill2 = {"k": "X.......X.......", "x": "....x...........", "2": "........xx......", "3": "..........xx....", "4": "............XX..", "s": "..............XX"}
    # --- 0-3 : l'intro (skank, orgue, la trompette qui appelle)
    ska(0, intro, 0.9, fills={3: ska_fill})
    melody(S, "trp", "horns", 2, "r:4 | r:2 D5:0.5 D5:0.5 >D5:1", 0.75)
    # --- 4-19 : l'air, trompette et trombone (à l'octave)
    ska(4, A + A, 1.0, fills={7: ska_fill2, 15: ska_fill})
    melody(S, "trp", "horns", 4, melA + " | " + melA2, 0.72)
    melody(S, "tbn", "horns", 4, melA + " | " + melA2, 0.62, octave=-1)
    # --- 20-27 : le couplet punk à toute allure
    B.gtr(20, Bp, "Oooooooo")
    B.bass.line(20, Bp, "Rrrrrrrr")
    B.drum_section(20, 8, PUNK, 1.0, crash_every=4, fills={7: "snare8"})
    melody(S, "trp", "horns", 20, melB, 0.8)
    melody(S, "tbn", "horns", 20, melB, 0.7, octave=-1)
    chords_of(S, None, "organ", 20, Bp, 60, 74, 3, [0.0, 2.0], 1.8, 0.45, synth=org)
    # --- 28-43 : l'orgue-jouet chante l'air, les cuivres ponctuent
    ska(28, A + A, 1.0, fills={7: ska_fill2, 15: ska_fill})
    melody(S, None, "toy", 28, melA + " | " + melA2, 0.85, octave=1, synth=toy, stac=0.85)
    chords_of(S, "trp_stac", "horns", 28, A + A, 67, 79, 2, [1.5, 3.5], 0.5, 0.55)
    chords_of(S, "tbn_stac", "horns", 28, A + A, 55, 67, 2, [1.5, 3.5], 0.5, 0.5)
    # --- 44-51 : la pause « dub » (un seul coup par mesure, la basse devant)
    sk.rhythm(44, dub, "....s.......s...", vel=0.8)
    B.bass.line(44, dub, ["R--rR-f-", "R--ro-f-"])
    for i in range(8):
        drums(S, kit, 44 + i, {"k": "........X.......", "x": "........x.......", "h": "x.x.x.x.x.x.x.x." if i >= 2 else "........", "o": "..............x."}, 0.85)
    melody(S, "trp_harmon", "horns", 44, melDub, 0.8)
    # --- 52-67 : tout le monde (cuivres et orgue à l'unisson)
    ska(52, A + A, 1.05, fills={7: ska_fill2, 15: ska_fill}, crash=4)
    melody(S, "trp", "horns", 52, melA + " | " + melA2, 0.8)
    melody(S, "tbn", "horns", 52, melA + " | " + melA2, 0.68, octave=-1)
    melody(S, None, "toy", 52, melA + " | " + melA2, 0.55, octave=1, synth=toy, stac=0.8)
    B.gtr(60, A, ".o.o.o.o", vel=0.7, only="R")
    # --- 68-75 : la relance (et la boucle repart)
    ska(68, turn, 1.0, fills={7: {"k": "X.......X.......", "s": "....X...xxxxXXXX", "x": "........", "h": "x.x.x.x........."}})
    melody(S, "trp", "horns", 68, melTurn, 0.75)
    melody(S, "tbn", "horns", 68, melTurn, 0.65, octave=-1)
    # --- la console
    B.mix(False, gtr_gain=34.0, gtr_level=0.11, bass_level=2.4)
    S.fx["skank"] = lambda x: pan2(amp(x, 6.0, bias=0.1, mid=3.0, scoop=-1.0, presence=2.0, cab=6000), 0.45) * 0.17
    S.fx["organ"] = lambda x: leslie(x.mean(axis=1), 5.8, 0.25, S.n) * 0.55
    S.fx["toy"] = lambda x: leslie(x.mean(axis=1), 6.5, 0.35, S.n) * 0.7
    S.fx["horns"] = lambda x: filt(x, bw("highpass", 90), peak(2500, 1.5, 1.0)) * 1.0
    S.send.update({"skank": 0.15, "organ": 0.2, "toy": 0.25, "horns": 0.25})
    return S


# =========================================================================== Port-Boucan, la nuit : dub

def boucan_nuit(kit: Kit) -> Song:
    S = Song("boucan_nuit", 72, 36, loop=True, seed=756, swing=0.06)
    rng = np.random.default_rng(7560)
    sk = Guitar(S, "skank", 7561, jitter=0.004, bright=0.65)
    bass = Bass(S, "bass", 7562, lo=28, t60=2.5, bright=0.04)
    A = ["Am", "Em", "Dm", "Am", "Am", "C", "G", "Am"]
    D = ["Am", "Am", "Dm", "Dm", "F", "G", "Am", "Am"]
    intro = ["Am", "Am", "Dm", "Am"]
    out = ["Am", "Dm", "F", "G", "Am", "Dm", "Em", "Am"]
    riffs = {"Am": "A1:1.5 A1:0.5 r:0.5 C2:0.5 E2:0.5 G2:0.5", "Em": "E2:1.5 E2:0.5 r:0.5 G2:0.5 B2:0.5 D3:0.5",
             "Dm": "D2:1.5 D2:0.5 r:0.5 F2:0.5 A2:0.5 C3:0.5", "C": "C2:1.5 C2:0.5 r:0.5 E2:0.5 G2:0.5 A2:0.5",
             "G": "G1:1.5 G1:0.5 r:0.5 B1:0.5 D2:0.5 F2:0.5", "F": "F1:1.5 F1:0.5 r:0.5 A1:0.5 C2:0.5 E2:0.5"}
    melA = ("E5:1.5 D5:0.5 C5:1 A4:1 | B4:2 A4:2 | D5:1.5 C5:0.5 A4:1 F4:1 | E4:4 | E5:1.5 D5:0.5 C5:1 E5:1 | G5:2 E5:2 | "
            "D5:1 E5:1 D5:1 B4:1 | A4:4")
    melB = "r:2 A4:1 C5:1 | E5:4 | r:2 F5:1 E5:1 | D5:4 | C5:1 D5:1 E5:2 | D5:2 B4:2 | ~A4:4 | r:4"
    org = lambda m, d, v: organ(m, d, v, rng, combo=0.3, perc=0.2)
    mel_org = lambda m, d, v: organ(m, d, v, rng, combo=0.5, perc=0.1)

    def drop(b0: int, n: int, vel: float = 1.0, hats: bool = True, throw=()) -> None:
        for i in range(n):
            pat = {"k": "........X.......", "x": "........x.......", "p": "....x.......x..."}
            if hats:
                pat["h"] = "x.xxx.xxx.xxx.x."
                pat["o"] = "..............x." if i % 2 else "................"
            drums(S, kit, b0 + i, pat, 0.8 * vel)
            if i in throw:
                S.add("throw", kit.get("rim", 0.7), S.t(b0 + i, 3.5), 0.8, 0.0)

    def line(b0: int, prog: list, vel: float = 1.0) -> None:
        bass.riff(b0, " | ".join(riffs[c] for c in prog), vel)

    def skank_org(b0: int, prog: list, vel: float = 1.0) -> None:
        sk.rhythm(b0, prog, "....s.......s...", vel=vel)
        chords_of(S, None, "organ", b0, prog, 60, 74, 3, [0.5, 0.75, 1.5, 1.75, 2.5, 2.75, 3.5, 3.75], 0.2, 0.32 * vel, synth=org)

    # --- 0-3 : la batterie, la basse
    drop(0, 4, 0.9, hats=False, throw=(3,))
    line(0, intro)
    sk.rhythm(2, intro[2:], "....s.......s...", vel=0.7)
    # --- 4-11 : la trompette en sourdine
    drop(4, 8, throw=(3, 7))
    line(4, A)
    skank_org(4, A)
    melody(S, "trp_harmon", "horns", 4, melA, 0.75)
    # --- 12-19 : le « dub » : des trous, des échos
    drop(12, 8, 0.9, hats=True, throw=(1, 3, 5, 7))
    line(12, D, 1.05)
    sk.rhythm(12, D, ["....s...........", "............s...", "....s.......s...", "................"] * 2, vel=0.9)
    melody(S, None, "melodica", 14, "r:2 E5:1 G5:1 | A5:4 | r:4 | r:2 C6:1 B5:1 | A5:4 | r:4", 0.5, synth=mel_org)
    # --- 20-27 : l'orgue chante, la trompette répond
    drop(20, 8, throw=(7,))
    line(20, A)
    skank_org(20, A)
    melody(S, None, "melodica", 20, melA, 0.75, synth=mel_org)
    melody(S, "trp_harmon", "horns", 20, melB, 0.6)
    # --- 28-35 : la fin de nuit (et la boucle repart)
    drop(28, 8, 0.9, throw=(1, 5))
    line(28, out, 0.95)
    skank_org(28, out, 0.85)
    melody(S, "trp_harmon", "horns", 30, "r:4 | E5:2 D5:1 C5:1 | D5:2 B4:2 | r:4 | r:4 | A4:4", 0.55)
    # --- la console : l'écho à bande qui tourne
    dly = S.spb * 0.75
    S.fx["skank"] = lambda x: echo(pan2(amp(x, 5.0, bias=0.1, mid=3.0, scoop=-1.0, presence=1.0, cab=5000), 0.35) * 0.3,
                                   dly, 0.45, 6, 2200, True, True)
    S.fx["organ"] = lambda x: leslie(x.mean(axis=1), 5.0, 0.2, S.n) * 0.8
    S.fx["melodica"] = lambda x: echo(leslie(x.mean(axis=1), 6.0, 0.15, S.n) * 0.55, dly, 0.3, 4, 2500, True, True)
    S.fx["horns"] = lambda x: echo(filt(x, bw("highpass", 120)) * 1.1, dly * 2, 0.32, 4, 2400, True, True)
    S.fx["throw"] = lambda x: echo(filt(x, bw("highpass", 300)) * 1.5, dly, 0.55, 7, 1800, True, True)
    S.fx["bass"] = lambda x: bass_amp(x, 1.5) * 2.6
    drum_fx(S, False)
    S.fx["dr_kick"] = lambda x: compress(filt(x, peak(60, 3, 1.0), bw("lowpass", 3000)), -14, 3.0, 0.004, 0.08) * 1.0
    S.fx["dr_snare"] = lambda x: compress(filt(x, peak(4000, 3, 0.8)), -16, 3.0, 0.005, 0.1) * 3.0
    S.send.update({"skank": 0.25, "organ": 0.25, "melodica": 0.3, "horns": 0.3, "throw": 0.4, "bass": 0.02})
    return S


# =========================================================================== la Cathédrale des Spores

SPORES = {   # (basse, notes de la nappe) : fa lydien, et un passage plus mystérieux
    "F": ("F2", "A3 C4 E4 G4"), "G/F": ("F2", "B3 D4 G4 A4"), "Em7": ("E2", "G3 B3 D4 E4"), "Am7": ("A2", "C4 E4 G4 B4"),
    "Dm9": ("D2", "F3 A3 C4 E4"), "C": ("C2", "E3 G3 D4 E4"), "Bb": ("A#1", "D4 F4 A4 E5"), "Db": ("C#2", "F3 G#3 C4 D#4"),
    "Eb/Db": ("C#2", "D#3 G3 A#3 F4"), "Ab": ("G#1", "C4 D#4 G4 A#4"), "Gsus": ("G2", "C4 D4 G4 A4"),
}


def spores(kit: Kit) -> Song:
    S = Song("spores", 66, 32, loop=True, seed=757)
    rng = np.random.default_rng(7570)
    A = ["F", "G/F", "F", "G/F", "Em7", "Am7", "Dm9", "G/F"]
    Bm = ["Db", "Eb/Db", "Db", "Eb/Db", "Bb", "Ab", "Gsus", "G/F"]
    A2 = ["F", "G/F", "Am7", "Em7", "Dm9", "C", "Bb", "G/F"]
    prog = A + Bm + A2 + A
    melA = ("C6:2 A5:1 G5:1 | B5:3 r:1 | C6:1 E6:1 D6:1 C6:1 | B5:2 G5:2 | B5:2 G5:1 E5:1 | C6:2 B5:1 A5:1 | "
            "F5:1 A5:1 C6:1 E6:1 | D6:4")
    melB = "C6:4 | A#5:2 G5:2 | G#5:3 F5:1 | G5:4 | F5:2 A5:2 | D#5:2 G5:2 | ~G5:4 | B5:4"
    melC = "A5:2 C6:1 E6:1 | D6:2 B5:2 | E6:2 C6:1 A5:1 | B5:4 | A5:2 F5:1 A5:1 | G5:2 E5:2 | F5:1 A5:1 D6:1 E6:1 | B5:4"
    cel = lambda m, d, v: celesta(m, d, v, rng)
    for i, c in enumerate(prog):
        bs, ps = SPORES[c]
        notes = [midi_of(p) for p in ps.split()]
        # la nappe, les cordes douces (contrebasse et violoncelle), l'harmonica de verre en haut
        for m in notes:
            S.add("pad", pad(m, 4 * S.spb + 0.2, 0.55, rng, cutoff=1500, attack=1.4, release=2.2), S.t(i) - 0.3, 1.0)
        play(S, "cb", "strings", midi_of(bs), i, 0, 4.2, 0.35)
        play(S, "vc", "strings", midi_of(bs) + 12, i, 0, 4.2, 0.22)
        if i % 2 == 0:
            for m in notes[-2:]:
                play(S, "verres", "glass", m + 12, i, 0, 8.0, 0.45)
        # le célesta qui égrène les notes de l'accord, doucement
        tones = sorted({m + 12 * o for m in notes for o in (1, 2) if 70 <= m + 12 * o <= 96})
        for k in range(8):
            if rng.random() < (0.55 if 8 <= i < 16 else 0.4):
                m = tones[int(rng.integers(0, len(tones)))]
                S.add("celesta", cel(m, 0.6, float(rng.uniform(0.25, 0.5))), S.t(i, k * 0.5) + float(rng.normal(0, 0.01)), 1.0,
                      float(rng.uniform(-0.6, 0.6)))
        # les carillons, très loin ; le glockenspiel qui scintille
        if rng.random() < 0.45:
            play(S, "carillon", "far", tones[int(rng.integers(0, len(tones)))], i, float(rng.choice([1.0, 2.5, 3.0])), 3.0,
                 float(rng.uniform(0.2, 0.35)), pan=float(rng.uniform(-0.8, 0.8)))
        if rng.random() < 0.5:
            play(S, "glock", "far", tones[int(rng.integers(0, len(tones)))] + 12, i, float(rng.choice([0.5, 1.5, 3.5])), 1.0, 0.3)
        # les spores qui scintillent (de toutes petites clochettes très aiguës)
        for _ in range(int(rng.integers(2, 6))):
            S.add("twinkle", twinkle(rng), S.t(i, float(rng.uniform(0, 4))), float(rng.uniform(0.1, 0.3)), float(rng.uniform(-0.9, 0.9)))
    # la harpe au début de chaque partie
    for b0, c in ((0, "F"), (8, "Db"), (16, "F"), (24, "F")):
        _, ps = SPORES[c]
        ns = sorted({midi_of(p) + 12 * o for p in ps.split() for o in (0, 1)})
        for k, m in enumerate(ns):
            play(S, "harp", "harp", m, b0, k * 0.17, 2.0, 0.45)
    # les mélodies : le célesta, l'harmonica de verre, la flûte
    melody(S, None, "celesta", 0, melA, 0.55, synth=cel)
    melody(S, "verres", "glass", 8, melB, 0.55, octave=-1, legato=0.4)
    melody(S, "flute", "flute", 16, transpose(melC, -12), 0.4, legato=0.1)
    melody(S, None, "celesta", 24, melA, 0.5, synth=cel)
    melody(S, "verres", "glass", 24, melA, 0.3, octave=-1, legato=0.4)
    # les arbres à clochettes (VCSL), une respiration grave
    for f, b in (("windchimes_slowAsc1.wav", 7.5), ("windchimes_slowDesc1.wav", 15.0), ("windchimes_random.wav", 23.0)):
        p = VCSL / ST / "Mark Trees" / f
        if p.is_file():
            x = read(p)
            S.add("far", x[: int(6 * SR)] * 0.5, S.t(b), 1.0, float(rng.uniform(-0.5, 0.5)))
    for b in range(0, 32, 4):
        n = int(4 * 4 * S.spb * SR)
        x = np.arange(n) / SR
        f0 = hz(midi_of(SPORES[prog[b]][0]) - 12)
        y = (np.sin(2 * np.pi * f0 * x) + 0.4 * np.sin(2 * np.pi * f0 * 1.5 * x + 1)) * np.sin(np.pi * x / x[-1]) ** 2
        S.add("deep", y * 0.08, S.t(b), 1.0)
    S.fx["pad"] = lambda x: filt(x, bw("highpass", 220)) * 0.75
    S.fx["strings"] = lambda x: x * 0.55
    S.fx["glass"] = lambda x: x * 0.85
    S.fx["celesta"] = lambda x: echo(x, S.spb * 1.5, 0.3, 3, 5000, True, True) * 1.1
    S.fx["far"] = lambda x: x * 1.2
    S.fx["harp"] = lambda x: x * 1.0
    S.fx["flute"] = lambda x: x * 1.3
    S.fx["deep"] = lambda x: x * 0.35
    S.fx["twinkle"] = lambda x: echo(x, S.spb * 0.75, 0.4, 4, 9000, True, True) * 0.8
    S.send.update({"pad": 0.4, "strings": 0.45, "glass": 0.6, "celesta": 0.5, "far": 0.8, "harp": 0.5, "flute": 0.5, "deep": 0.2,
                   "twinkle": 0.7})
    return S


# =========================================================================== l'Usine Grise (le donjon)

def usine_grise(kit: Kit) -> Song:
    S = Song("usine_grise", 116, 58, loop=True, seed=758)
    rng = np.random.default_rng(7580)
    A = ["Dm", "Dm", "Dm", "A7", "Bb", "A7", "Dm A7", "Dm"]
    Bt = ["Bb", "Bb", "Gm", "Gm", "Eb", "Eb", "A", "A7"]
    C = ["F", "Dm", "Gm7", "C7", "F", "Dm", "Gm7", "C7"]
    outro = ["Dm", "Dm", "Gm", "A7", "Dm", "A7"]
    intro = ["Dm", "Dm", "Dm", "A7"]
    melA = ("D3:0.5 r:0.5 F3:0.5 r:0.5 A3:0.5 G#3:0.5 A3:1 | D4:0.5 C4:0.5 A3:0.5 F3:0.5 E3:1 r:1 | "
            "D3:0.5 r:0.5 F3:0.5 r:0.5 A3:0.5 G#3:0.5 A3:1 | E4:0.5 D4:0.5 C#4:0.5 E4:0.5 A3:1 r:1 | "
            "A#3:0.5 r:0.5 D4:0.5 r:0.5 F4:0.5 E4:0.5 F4:1 | G4:0.5 F4:0.5 E4:0.5 D4:0.5 C#4:1 r:1 | "
            "D4:0.5 F4:0.5 A4:0.5 F4:0.5 G4:0.5 E4:0.5 C#4:0.5 A3:0.5 | D4:1 A3:1 D3:1 r:1")
    melC = ("A5:1 C6:1 A5:1 F5:1 | D5:2 F5:2 | G5:1 A#5:1 D6:1 A#5:1 | C6:2 r:2 | A5:1 C6:1 F6:1 C6:1 | D6:1 C6:1 A5:2 | "
            "G5:1 A5:1 A#5:1 D6:1 | C6:2 E5:2")
    shapes = {"m": [0, 0, 12, 0, 3, 0, 6, 7], "7": [0, 0, 12, 0, 4, 0, 6, 7], "": [0, 0, 12, 0, 4, 0, 7, 9]}

    def ostinato(b0: int, prog: list, vel: float = 1.0, spic: bool = True) -> None:
        for i, cell in enumerate(prog):
            syms = cell.split()
            for k in range(8):
                sym = syms[min(len(syms) - 1, k * len(syms) // 8)]
                r, third, sev = parse_chord(sym)
                q = "m" if third == 3 else ("7" if sev else "")
                m = root_in(r, 38) + shapes[q][k]
                v = (1.0 if k in (0, 4) else 0.75) * vel
                S.add("synbass", synth_bass(m, 0.5 * S.spb * 0.8, 0.7 * v), S.t(b0 + i, k * 0.5), 1.0)
                if spic:
                    play(S, "vc_spic", "strings", m + 12, b0 + i, k * 0.5, 0.5, 0.5 * v)

    def machines(b0: int, n: int, vel: float = 1.0, full: bool = True) -> None:
        for i in range(n):
            b = b0 + i
            pat = {"an": "X.......", "cv": "x.x.x.x.x.x.x.x." if full else "x...x...x...x...", "br": "....x...", "k": "X.......X......."}
            if full:
                pat["cb"] = "..x...x..x..x..x"
                pat["h"] = "..x...x...x...x."
            drums(S, kit, b, pat, 0.75 * vel)
            if i % 2 == 0:
                S.add("machines", thump(80, 40, 0.6, rng), S.t(b, 0), 0.7 * vel)
            if i % 4 == 3:
                S.add("machines", hiss(0.6, rng, 2000, 9000, 0.005, 0.4, -1.5), S.t(b, 3.0), 0.6 * vel, float(rng.uniform(-0.6, 0.6)))
            if i % 4 == 1:
                S.add("machines", clang(float(rng.uniform(300, 500)), 0.9, rng), S.t(b, 2.5), 0.5 * vel, float(rng.uniform(-0.7, 0.7)))

    # le bourdonnement de l'usine (le secteur, les moteurs, l'air) d'un bout à l'autre
    tt = np.arange(S.n) / SR
    hum_cyc = round(50 * S.n / SR) * SR / S.n
    S.add("hum", (rng.standard_normal(S.n) * 0.7).astype(np.float32), 0.0, 1.0, 0.0, 1.0)
    S.add("hum2", (0.012 * np.sin(2 * np.pi * hum_cyc * tt) + 0.006 * np.sin(4 * np.pi * hum_cyc * tt)).astype(np.float32), 0.0)
    # --- 0-3 : les machines démarrent
    machines(0, 4, 0.85, full=False)
    ostinato(2, intro[2:], 0.8, spic=False)
    # --- 4-19 : le basson fait le malin, la clarinette lui répond
    machines(4, 16)
    ostinato(4, A + A)
    melody(S, "bsn_stac", "winds", 4, melA, 0.75, stac=0.7)
    melody(S, "clar_stac", "winds", 12, melA, 0.55, octave=1, stac=0.7)
    melody(S, "bsn_stac", "winds", 12, melA, 0.45, stac=0.7)
    # --- 20-27 : ça se tend (trémolos, cors, timbales)
    machines(20, 8, 1.1)
    ostinato(20, Bt, 1.1)
    for i, c in enumerate(Bt):
        r, third, sev = parse_chord(c)
        for m in sorted({root_in(r, 72), root_in((r + (third or 4)) % 12, 72), root_in((r + 7) % 12, 72)}):
            play(S, "vln_trem", "strings", m, 20 + i, 0, 4.0, 0.35)
        play(S, "horn", "brass", root_in(r, 53), 20 + i, 0, 0.9, 0.55)
        play(S, "horn", "brass", root_in((r + 7) % 12, 53), 20 + i, 2.5, 1.2, 0.5)
        play(S, "timp", "brass", root_in(r, 38) if root_in(r, 38) <= 45 else root_in(r, 38) - 12, 20 + i, 0, 1.0, 0.5)
    S.add("machines", hiss(1.5, rng, 1200, 8000, 0.01, 1.0, -2.0), S.t(27, 2.0), 0.8)
    # --- 28-35 : le bureau des robots polis (musique d'ascenseur au marimba)
    for i, c in enumerate(C):
        r, third, sev = parse_chord(c)
        R = root_in(r, 36)
        for k, (st, deg) in enumerate(((0, 0), (1, 7), (2, 12), (3, 7))):
            play(S, "cb_pizz", "office", R + deg, 28 + i, st, 1.0, 0.5)
        chords_of(S, "vln_pizz", "office", 28 + i, [c], 64, 76, 3, [1.0, 3.0], 0.5, 0.35)
        drums(S, kit, 28 + i, {"cv": "x.x.x.x.x.x.x.x.", "tb": "....x.......x...", "wb": "x......x..x....."}, 0.5)
    melody(S, "marimba", "office", 28, melC, 0.55)
    drums(S, kit, 35, {"cv": "x.x.x.x.", "an": "........X......."}, 0.8)
    # --- 36-51 : tout le monde (le xylophone double le basson)
    machines(36, 16, 1.05)
    ostinato(36, A + A, 1.05)
    melody(S, "bsn_stac", "winds", 36, melA + " | " + melA, 0.8, stac=0.7)
    melody(S, "xylo", "winds", 36, melA + " | " + melA, 0.4, octave=2, stac=0.7)
    melody(S, "clar_stac", "winds", 44, melA, 0.5, octave=1, stac=0.7)
    for i in range(0, 16, 4):
        play(S, "horn", "brass", 50, 36 + i, 0, 3.5, 0.4)
    # --- 52-57 : les machines ralentissent… et repartent
    machines(52, 6, 0.9, full=False)
    ostinato(52, outro, 0.85)
    melody(S, "bsn_stac", "winds", 54, "D3:0.5 r:0.5 F3:0.5 r:0.5 A3:1 r:1 | r:4 | D3:1 r:1 A2:1 r:1 | D3:0.5 C#3:0.5 D3:0.5 E3:0.5 A2:1 r:1", 0.65, stac=0.7)
    S.add("machines", hiss(1.2, rng, 1500, 9000, 0.01, 0.8, -1.0), S.t(57, 1.5), 0.6)
    drum_fx(S, False)
    S.fx["dr_perc"] = lambda x: filt(x, bw("highpass", 150)) * 0.8
    S.fx["hum"] = lambda x: (filt(x, bw("bandpass", [60, 400])) * 0.004 + filt(x, bw("bandpass", [1500, 5000])) * 0.0008).astype(np.float32)
    S.fx["synbass"] = lambda x: filt(x, bw("highpass", 35), bw("lowpass", 3500)) * 0.9
    S.fx["machines"] = lambda x: filt(x, bw("highpass", 40)) * 0.7
    S.fx["strings"] = lambda x: x * 0.8
    S.fx["winds"] = lambda x: x * 1.0
    S.fx["brass"] = lambda x: x * 0.8
    S.fx["office"] = lambda x: x * 1.5
    S.send.update({"synbass": 0.05, "machines": 0.35, "strings": 0.3, "winds": 0.3, "brass": 0.35, "office": 0.3, "dr_perc": 0.35})
    return S


# =========================================================================== la Grande Pelleteuse (le boss)

def grande_pelleteuse(kit: Kit) -> Song:
    S = Song("grande_pelleteuse", 168, 84, loop=True, seed=759)
    rng = np.random.default_rng(7590)
    B = Band(S, kit, 7590, lo=38, tight=0.004)
    gallop = "M.mmM.mmM.mmM.mm"
    riffA = ("D2:0.5 D2:0.25 D2:0.25 D2:0.5 F2:0.5 D2:0.5 G2:0.5 D2:0.5 G#2:0.5 | "
             "D2:0.5 D2:0.25 D2:0.25 D2:0.5 F2:0.5 E2:0.5 C3:0.5 A#2:0.5 A2:0.5")
    th = ["Dm", "Bb", "C", "Dm", "Dm", "Bb", "C", "A", "Dm", "Bb", "C", "A", "Dm", "Bb", "A", "Dm"]
    melT = ("D5:2 A4:1 D5:1 | F5:2 D5:1 F5:1 | E5:1 G5:1 C6:1 G5:1 | A5:3 r:1 | D6:1.5 C6:0.5 A5:1 F5:1 | D5:2 A#4:2 | "
            "C5:1 E5:1 G5:1 C6:1 | ~C#6:4 | D5:2 A4:1 D5:1 | F5:2 D5:1 F5:1 | E5:1 G5:1 C6:1 G5:1 | A5:2 C#6:2 | "
            "D6:2 A5:1 F5:1 | A#5:2 F5:2 | E5:1 C#5:1 E5:1 A5:1 | ~D6:3 r:1")
    comic = ["Dm", "A7", "Dm", "A7", "Gm", "Dm", "A7", "Dm"]
    melComic = ("D5:0.5 r:0.5 A4:0.5 r:0.5 D5:0.5 E5:0.5 F5:1 | E5:0.5 r:0.5 C#5:0.5 r:0.5 A4:2 | D5:0.5 r:0.5 A4:0.5 r:0.5 "
                "F5:0.5 G5:0.5 A5:1 | G5:0.5 F5:0.5 E5:0.5 D5:0.5 C#5:2 | A#4:0.5 r:0.5 D5:0.5 r:0.5 G5:1 F5:1 | "
                "F5:0.5 E5:0.5 D5:0.5 C5:0.5 A4:2 | E5:0.5 r:0.5 G5:0.5 r:0.5 A5:0.5 G5:0.5 E5:0.5 C#5:0.5 | D5:2 r:2")

    def pshh(bar: float, beat: float, dur: float = 0.8, vel: float = 1.0, clank: bool = True) -> None:
        """La machine qui souffle : un vérin hydraulique (« pshhhh ») et la ferraille qui cogne."""
        S.add("machine", hiss(dur, rng, 900, 9000, 0.004, dur * 0.7, -1.6), S.t(bar, beat), 0.9 * vel, float(rng.uniform(-0.5, 0.5)))
        if clank:
            S.add("machine", clang(float(rng.uniform(140, 260)), 1.2, rng, 0.7), S.t(bar, beat), 0.6 * vel, float(rng.uniform(-0.4, 0.4)))
            S.add("machine", thump(70, 35, 0.7, rng, 0.5), S.t(bar, beat), 0.8 * vel)

    # --- 0-3 : la machine se réveille : vérins, coups lourds
    for i in range(4):
        B.hits(i, [0.0, 2.0], "D5", crash=i % 2 == 0, ring=0.0)
        drums(S, kit, i, {"4": "..........x.x.xx" if i < 3 else "x.x.xxxxXXXXXXXX", "k": "X.......X......."}, 0.9)
        pshh(i, 1.0, 0.7, 0.9)
    # --- 4-11 : le riff au galop (guitares et basse à l'unisson), double grosse caisse
    for g in (B.gL, B.gR):
        g.riff(4, " | ".join([riffA] * 4), 1.0, power=True)
    B.bass.riff(4, transpose(" | ".join([riffA] * 4), -12), 1.0)
    B.drum_section(4, 8, {"k": "XxXxXxXxXxXxXxXx", "s": "....X.......X...", "h": "x.x.x.x.x.x.x.x."}, 0.95, crash_every=4, fills={7: "toms"})
    # --- 12-27 : le thème héroïque (cuivres), galop étouffé
    B.gtr(12, th, gallop)
    B.bass.line(12, th, "RrrRrrRrrRrr" if False else "R.rrR.rrR.rrR.rr")
    B.drum_section(12, 16, {"k": "X.xxX.xxX.xxX.xx", "s": "....X.......X...", "R": "x.x.x.x.x.x.x.x."}, 1.0, crash_every=4, fills={7: "snare8", 15: "toms_big"})
    melody(S, "trp", "brass", 12, melT, 0.75)
    melody(S, "horn", "brass", 12, melT, 0.6, octave=-1)
    for b in (12, 16, 20, 24):
        pshh(b, 0.0, 0.5, 0.6, clank=False)
    # --- 28-35 : le passage comique : la machine qui piétine (tuba, basson, xylophone)
    for i, c in enumerate(comic):
        r, third, sev = parse_chord(c)
        R = root_in(r, 26 + 12)
        play(S, "tuba_stac", "brass", R - 12 if R - 12 >= 28 else R, 28 + i, 0, 0.6, 0.7)
        play(S, "tuba_stac", "brass", R + 7 - 12 if R - 5 >= 28 else R + 7, 28 + i, 2, 0.6, 0.6)
        for b in (1.0, 3.0):
            for g in (B.gL, B.gR):
                g.strike(S.t(28 + i, b), voice(c.replace("7", "") + "5", "5", 38), 0.25, 0.8, "mute")
        drums(S, kit, 28 + i, {"k": "X.......X.......", "s": "....x.......x...", "cb": "x...x...x...x..."}, 0.85)
        pshh(28 + i, 2.0 if i % 2 else 0.0, 0.35, 0.6, clank=i % 2 == 0)
    melody(S, "bsn_stac", "brass", 28, transpose(melComic, -12), 0.7, stac=0.7)
    melody(S, "xylo", "brass", 28, melComic, 0.45, stac=0.7)
    # --- 36-51 : le thème, tout le monde
    B.gtr(36, th, ["OoooOoooOoooOooo"])
    B.bass.line(36, th, "R.rrR.rrR.rrR.rr")
    B.drum_section(36, 16, {"k": "XxXxXxXxXxXxXxXx", "s": "....X.......X...", "R": "x.x.x.x.x.x.x.x."}, 1.0, crash_every=2, fills={7: "toms", 15: "rush"})
    melody(S, "trp", "brass", 36, melT, 0.85)
    melody(S, "horn", "brass", 36, melT, 0.7, octave=-1)
    melody(S, "tbn", "brass", 36, melT, 0.55, octave=-1)
    lead(S, "lead", 44, " | ".join(melT.split("|")[8:]), 75901, octave=0, vel=0.7)
    # --- 52-59 : l'écrasement (ré grave étouffé, arrêts, vérins)
    for i in range(8):
        B.gtr(52 + i, ["D5"], "MmMmM.MmMmM.M.M." if i % 2 else "MmmmMmmmMmmmM.M.")
        B.bass.line(52 + i, ["D"], "RrRrR.RrRrR.R.R." if i % 2 else "RrrrRrrrRrrrR.R.")
        drums(S, kit, 52 + i, {"k": "XxXxX.XxXxX.X.X." if i % 2 else "XxxxXxxxXxxxX.X.", "z": "X.......X.......", "s": "....X.......X..."}, 1.0)
        pshh(52 + i, 3.0, 0.4, 0.7, clank=i % 2 == 1)
    # --- 60-75 : le thème, guitare solo en tierce, cuivres
    B.gtr(60, th, gallop)
    B.bass.line(60, th, "R.rrR.rrR.rrR.rr")
    B.drum_section(60, 16, {"k": "X.xxX.xxX.xxX.xx", "s": "....X.......X...", "R": "x.x.x.x.x.x.x.x."}, 1.0, crash_every=4, fills={7: "toms_big", 15: "toms"})
    lead(S, "lead", 60, melT, 75902, vel=0.85)
    melody(S, "trp", "brass", 60, melT, 0.7)
    melody(S, "tbn", "brass", 60, melT, 0.55, octave=-1)
    # --- 76-83 : le riff, la montée, la boucle repart
    for g in (B.gL, B.gR):
        g.riff(76, " | ".join([riffA] * 4), 1.0, power=True)
    B.bass.riff(76, transpose(" | ".join([riffA] * 4), -12), 1.0)
    B.drum_section(76, 8, {"k": "XxXxXxXxXxXxXxXx", "s": "....X.......X...", "h": "x.x.x.x.x.x.x.x."}, 1.0, crash_every=4,
                   fills={7: {"s": "xxxxxxxxXXXXXXXX", "k": "X.X.X.X.XXXXXXXX", "4": "............XXXX"}})
    pshh(83, 2.0, 1.2, 1.0)
    B.mix(False, gtr_gain=50.0, gtr_level=0.15, bass_level=2.2, lead_level=0.12)
    S.fx["dr_kick"] = lambda x: compress(filt(x, peak(60, 1, 1.0), peak(3500, 3, 1.0)), -14, 3.0, 0.004, 0.08) * 0.5
    S.fx["brass"] = lambda x: filt(x, bw("highpass", 70)) * 0.9
    S.fx["machine"] = lambda x: filt(x, bw("highpass", 35)) * 1.0
    S.send.update({"brass": 0.3, "machine": 0.25})
    return S


# =========================================================================== lancement

PIECES = {
    # nom : (fonction, sonie visée en LUFS, salle, traitement de la sono)
    "boucan": (boucan, -18.0, "street"),
    "boucan_nuit": (boucan_nuit, -19.0, "street"),
    "concert_1": (concert_1, -17.5, "hall"),
    "concert_2": (concert_2, -17.5, "hall"),
    "concert_3": (concert_3, -17.5, "hall"),
    "concert_gedeon": (concert_gedeon, -17.5, "hall"),
    "spores": (spores, -19.5, "cathedral"),
    "usine_grise": (usine_grise, -18.5, "factory"),
    "grande_pelleteuse": (grande_pelleteuse, -17.5, "factory"),
}


def render_piece(name: str, kit: Kit, out_dir: Path) -> np.ndarray:
    fn, target, room = PIECES[name]
    S = fn(kit)
    if room == "hall":
        ir, mfx, glue = hall_ir(S.seed), hall_master, (-18.0, 2.5)
    elif room == "street":
        ir, mfx, glue = room_ir(1.1, 0.6, 0.012, 14, S.seed, 0.04), None, (-18.0, 2.0)
    elif room == "cathedral":
        ir, mfx, glue = room_ir(4.5, 0.45, 0.03, 20, S.seed, 0.09), None, (-22.0, 1.5)
    else:
        ir, mfx, glue = room_ir(1.6, 0.55, 0.015, 18, S.seed, 0.06), None, (-18.0, 2.0)
    y = S.render(out_dir / f"{name}.ogg", target, -2.0, ir, glue, mfx)
    release_instruments()
    del S
    gc.collect()
    return y


def main() -> int:
    global VSCO, VCSL, CC0
    args = sys.argv[1:]
    names = []
    while args:
        a = args.pop(0)
        if a == "--vsco":
            VSCO = Path(args.pop(0))
        elif a == "--vcsl":
            VCSL = Path(args.pop(0))
        elif a == "--cc0":
            CC0 = Path(args.pop(0))
        else:
            names.append(a)
    import generate_sons_v63 as s63
    s63.LIB = CC0
    kit = Kit()
    for name in names or list(PIECES):
        render_piece(name, kit, OUT)
    return 0


if __name__ == "__main__":
    sys.exit(main())
