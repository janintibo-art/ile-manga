"""V70 : les musiques de l'Île de Braise et de Pandémonia, la méga-cité des démons gentils.

Compositions originales pour Île Manga, versées au domaine public (CC0 1.0), jouées avec les outils
de la V51 (compose_musique_v51.py, orchestre_v51.py) par l'orchestre VSCO-2 CE (CC0), et, pour la
première fois, par des instruments de la « Versilian Community Sample Library » (VCSL, Versilian
Studios, github.com/sgossner/VCSL, CC0 1.0) :
  - le grand orgue (bourdon 16', principal 8', un jeu doux, la pédale) et le petit orgue Renaissance
    (flûte 8', plein jeu) ;
  - le clavecin (clavecin « français ») ;
  - l'harmonica chromatique, joué à trois anches par note (une juste, une un peu haute, une un peu
    basse : le trémolo « musette » de l'accordéon de bal) ;
  - les verres frottés et le psaltérion à archet (le froid du Cocyte), les carillons à main, les
    cloches tubulaires, le tambourin, les claquements de mains, le tom, la caisse claire à cordes, la
    grosse caisse, le tambour sur cadre.
Le chœur est synthétisé ici (aucun chœur libre de droits n'existe dans ces banques) : pour chaque
note, six chanteurs, chacun avec sa voix (source glottique, souffle), son vibrato, son léger
désaccord, son instant d'attaque, dans les formants d'une voyelle (« a », « o », « ou »). L'accordéon
de la main gauche est celui de la V56 (compose_musique_v56.Accordion), le violoneux celui de la V68.

« La Valse de Pandémonia » (pandemonia.ogg), le thème de la cité : valse gothique en ré mineur, 144 à
la noire, en boucle (96 mesures, 2 min). La cloche, puis le clavecin seul ; le « poum-tchak-tchak »
des cordes en pizzicato et du clavecin ; les violons chantent l'air, malicieux, avec sa sensible et
sa sixte (mi bécarre sur sol mineur), le petit orgue le reprend, les violons en contre-chant ; un
épisode joyeux en fa majeur (la flûte, la clarinette, le basson qui fait « poum-pa-pa », le
glockenspiel) ; un épisode mystérieux (le violoncelle dans le grave, le grand orgue, les trémolos,
la sixte napolitaine, la cloche, les timbales) ; l'air repris par tout le monde ; la fin, et la
boucle recommence.

« L'Île de Braise » (braise.ogg), dehors sur l'île volcanique : ut mineur, 64 à la noire, en boucle
(32 mesures, 2 min). La pédale de l'orgue (ut grave), les contrebasses, les timbales qui roulent
comme la chaleur qui monte, le gong ; le chœur d'hommes (« o ») puis de femmes (« a ») ; les cors
chantent le thème de l'île ; la grandeur (trombones, tuba, trompette, violons qui frémissent tout en
haut, cymbale) ; un moment de chaleur immobile (la clarinette, l'accord phrygien de ré bémol, la
harpe, le tambour sur cadre comme un cœur) ; le retour du bourdon.

« Les Neuf Cercles » (neuf_cercles.ogg), le grand donjon sous la Cathédrale-Forge : ré mineur, 60 à
la noire, en boucle (32 mesures, 2 min 8 s). La basse descend comme un lamento (ré, do#, do, si,
si bémol, la), l'orgue doux puis le grand orgue, la clarinette, le violoncelle, les trombones, les
timbales ; puis le froid monte : la flûte sans vibrato, la harpe, les trémolos tout en haut, les
verres frottés ; et le Cocyte, le lac gelé : le psaltérion à archet, les verres, les carillons,
le glockenspiel, et c'est l'orgue qui reprend la boucle.

« Le Tournoi des Cornes » (arene.ogg), l'Arène : si bémol majeur, 128 à la noire, en boucle
(64 mesures, 2 min). Fanfare de trompettes ; le thème héroïque des cors (avec l'accord de sol bémol,
le sixième degré abaissé), les cordes en spiccato, la caisse claire, la grosse caisse, les
timbales ; en sol mineur, le riff des trombones et du tuba, les appels de trompette ; une pause de
tambours (toms, claquements de mains, timbales) ; le thème en tutti ; l'apothéose ; la fanfare.

« La Nuit des Lanternes » (fete_lanternes.ogg), la fête sur la Grand-Place : une gigue en 6/8 en sol
majeur, 96 à la noire pointée, en boucle (96 mesures, 2 min). Le tambourin seul, puis l'orgue de
fête, l'accordéon et la contrebasse (« poum-tchak ») ; le violoneux mène la danse ; les anches
musette chantent l'épisode en mi mineur ; un couplet d'orgue avec les claquements de mains ; la
flûte, le piccolo et le glockenspiel (les lanternes qui s'envolent) ; tout le monde pour finir.

Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/compose_musique_v70.py <dossier VSCO-2-CE> [--vcsl <dossier VCSL>] [morceaux...]
(sans --vcsl, la VCSL est cherchée à côté de VSCO-2-CE ; morceaux : pandemonia, braise,
neuf_cercles, arene, fete_lanternes)
"""
from pathlib import Path
import gc
import sys
import tempfile

import numpy as np
from scipy import signal

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v51 as cm  # noqa: E402
import orchestre_v51 as orch  # noqa: E402
import compose_musique_v56 as cm56  # noqa: E402
import compose_musique_v68 as cm68  # noqa: E402
import compose_musique_v69 as cm69  # noqa: E402

SR = orch.SR
VCSL = Path(".")
mel, drone = cm69.mel, cm69.drone

# ------------------------------------------------------------------ les pupitres de la VCSL
ORG = "Aerophones/Edge-blown Aerophones/Pipe Organ/"
REN = "Aerophones/Edge-blown Aerophones/Renaissance Organ/"
ST = "Idiophones/Struck Idiophones/"
MB = "Membranophones/Struck Membranophones/"
# clé : (motif de fichiers dans la VCSL, options de orchestre_v51.Instrument, traitement)
#   traitement : « tenue » (on garde la partie tenue de l'enregistrement, sans la queue de
#   relâchement, et on accorde chaque échantillon), « accord » (seulement accordé), « » (rien)
VCSL_INSTR = {
    # le grand orgue : bourdon 16' (doux) et principal 8' ; on écrit la hauteur du 8'
    "orgue": (ORG + "Loud/*.wav", dict(attack=0.05, release=0.8, pan=0.0, width=0.9, gain=0.8, octave=12), "tenue"),
    "orgue_doux": (ORG + "Quiet/*.wav", dict(attack=0.06, release=0.8, pan=-0.1, width=0.8, gain=0.8), "tenue"),
    "orgue_pedale": (ORG + "Loud Pedal/*.wav", dict(attack=0.12, release=1.0, pan=0.05, width=0.8, gain=0.8), "tenue"),
    # le petit orgue Renaissance de la Grand-Place
    "orgue_flute": (REN + "8'/*.wav", dict(attack=0.03, release=0.35, pan=0.2, width=0.7, gain=0.9), "tenue"),
    "orgue_plein": (REN + "Full/*.wav", dict(attack=0.02, release=0.25, pan=0.15, width=0.7, gain=1.2), "tenue"),
    "clavecin": ("Chordophones/Zithers/Harpsichord, French/Sustains/*rr1_Main.wav",
                 dict(sustain=False, attack=0.001, release=0.35, pan=-0.35, width=0.6, gain=0.8), "accord"),
    "harmonica": ("Aerophones/Free Aerophones/Harmonica-Hohner-Super64/Sustains/Normal/*.wav",
                  dict(attack=0.025, release=0.1, pan=0.0, width=0.3, gain=1.0), "tenue"),
    "psalterion": ("Chordophones/Zithers/Psaltery, Bowed and Plucked/LongBow/*.wav",
                   dict(attack=0.25, release=1.0, pan=-0.3, width=0.6, gain=0.8), "tenue"),
    "verres": ("Idiophones/Friction Idiophones/Wine Glasses/Sustains/Slow/*.wav",
               dict(attack=0.8, release=1.5, pan=0.3, width=0.9, gain=0.9), "tenue"),
    "cloche": (ST + "Tubular Bells 2/*_v4_*.wav", dict(sustain=False, attack=0.001, release=3.0, pan=-0.2, width=0.8, gain=0.7), ""),
    "carillon": (ST + "Hand Chimes/*.wav", dict(sustain=False, attack=0.001, release=2.0, pan=0.35, width=0.7, gain=0.5), "accord"),
    "tambourin": (ST + "Tambourine 1/Tamb1_Hit_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=0.4, pan=0.45, width=0.3, gain=1.3), ""),
    "secoue": (ST + "Tambourine 1/Tamb1_Shake_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=0.2, pan=0.4, width=0.3, gain=0.45), ""),
    "claque": (ST + "Claps/Clap_rr*.wav", dict(pitched=False, sustain=False, attack=0.001, release=0.3, pan=-0.1, width=0.8, gain=1.5), ""),
    "tom": (MB + "Tom 1/Mallet/TomH_HitM_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=0.6, pan=-0.2, width=0.5, gain=0.9), ""),
    "tom_b": (MB + "Tom 1/Stick/TomH_HitS_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=0.5, pan=0.25, width=0.5, gain=0.8), ""),
    "caisse": (MB + "Snare Drum, Rope Tension/Hi/RopeSnare_hi_sn_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=0.35, pan=0.1, width=0.4, gain=1.0), ""),
    "gc": (MB + "Bass Drum 2/bassdrum_hit_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=1.0, pan=0.0, width=0.5, gain=0.8), ""),
    "cadre": (MB + "Frame Drum/HDrumL_Hit_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=0.8, pan=0.1, width=0.5, gain=0.55), ""),
}
VCSL_WET = {"orgue": 0.4, "orgue_doux": 0.45, "orgue_pedale": 0.35, "orgue_flute": 0.4, "orgue_plein": 0.35,
            "clavecin": 0.35, "musette": 0.3, "psalterion": 0.55, "verres": 0.6, "cloche": 0.55, "carillon": 0.6,
            "tambourin": 0.35, "secoue": 0.35, "claque": 0.4, "tom": 0.4, "tom_b": 0.4, "caisse": 0.35, "gc": 0.45, "cadre": 0.4,
            "choeur_h": 0.6, "choeur_f": 0.6, "choeur_doux": 0.65, "accordeon_g": 0.25, "timp": 0.5}


def _ecart_cents(x: np.ndarray, midi: float) -> float:
    """De combien de centièmes de demi-ton un échantillon s'écarte de sa note (somme des harmoniques
    du spectre, au demi-centième près)."""
    m = x.mean(axis=1)
    a = int(0.4 * SR)
    seg = m[a:a + 65536] if len(m) > a + 65536 else m[-min(len(m), 65536):]
    seg = seg * np.hanning(len(seg))
    nfft = 262144
    sp = np.abs(np.fft.rfft(seg, nfft))
    f0 = 440.0 * 2 ** ((midi - 69) / 12.0)
    best, best_c = -1.0, 0.0
    for c in np.arange(-50.0, 50.5, 0.5):
        f = f0 * 2 ** (c / 1200.0)
        s = 0.0
        for h in range(1, 7):
            i = int(round(h * f * nfft / SR))
            if 2 <= i < len(sp) - 3:
                s += sp[i - 2:i + 3].max() / h ** 0.5
        if s > best:
            best, best_c = s, c
    return float(best_c)


def _accorde(ins) -> None:
    """Chaque échantillon à sa vraie hauteur : les tuyaux d'orgue, les cordes du clavecin, les
    anches de l'harmonica ne sont pas tous parfaitement justes."""
    for s in ins.samples:
        c = _ecart_cents(s.data, s.midi)
        if abs(c) < 45.0:
            s.midi = s.midi + c / 100.0


def _tenue(ins) -> None:
    """Ne garde que la partie tenue d'un son enregistré (sans le relâchement et l'écho de l'église) :
    la note pourra être tenue aussi longtemps qu'il faut (boucle en fondu) et relâchée par la
    table de mixage."""
    for s in ins.samples:
        d = s.data
        env = np.abs(d).max(axis=1)
        w = int(0.05 * SR)
        env = np.convolve(env, np.ones(w) / w, mode="same")
        a, b = int(0.4 * SR), int(len(env) * 0.6)
        if b <= a + SR // 4:
            continue
        ref = float(np.median(env[a:b]))
        above = np.nonzero(env > 0.6 * ref)[0]
        if len(above):
            end = int(above[-1] - 0.06 * SR)
            if end > int(1.2 * SR):
                f = int(0.03 * SR)
                y = d[:end].copy()
                y[-f:] *= np.linspace(1.0, 0.0, f)[:, None]
                s.data = y


def vcsl(key: str):
    pat, opt, how = VCSL_INSTR[key]
    ins = orch.Instrument(key, VCSL, pat, **opt)
    if how == "tenue":
        _tenue(ins)
    if how in ("tenue", "accord"):
        _accorde(ins)
    return ins


# ------------------------------------------------------------------ le chœur synthétisé

VOY = {  # formants d'une voix d'homme (fréquence, largeur, gain) ; × 1,17 pour les voix de femme
    "a": [(730, 90, 1.0), (1090, 110, 0.5), (2440, 160, 0.26), (3300, 260, 0.1)],
    "o": [(540, 80, 1.0), (850, 100, 0.45), (2420, 160, 0.16), (3300, 260, 0.06)],
    "ou": [(330, 70, 1.0), (860, 100, 0.25), (2300, 160, 0.08)],
}


def _reso(f: float, bw: float):
    r = np.exp(-np.pi * bw / SR)
    th = 2 * np.pi * f / SR
    return [(1 - r) * np.sqrt(max(1e-9, 1 - 2 * r * np.cos(2 * th) + r * r))], [1.0, -2 * r * np.cos(th), r * r]


class Choeur:
    """Un pupitre de chœur : pour chaque note, plusieurs chanteurs (source glottique riche en
    harmoniques, un peu de souffle), chacun avec son vibrato, son léger désaccord, sa dérive lente,
    son instant d'attaque et sa place dans l'espace, dans les formants d'une voyelle."""

    def __init__(self, name: str, femmes: bool = False, voyelle: str = "a", n: int = 6, pan: float = 0.0,
                 width: float = 0.9, gain: float = 1.0, attack: float = 0.5, release: float = 1.0,
                 souffle: float = 0.1, seed: int = 7):
        self.name = name
        self.pan = pan
        self.width = width
        self.gain = gain
        self.attack = attack
        self.release = release
        self.n = n
        self.souffle = souffle
        self.lag = 0.12
        self.fs = 1.17 if femmes else 1.0
        self.fm = VOY[voyelle]
        self.rng = np.random.default_rng(seed)

    def note(self, midi: float, dur: float, vel: float = 0.5, attack=None, release=None, legato: bool = False) -> np.ndarray:
        att = max(0.15, self.attack if attack is None else attack * 3.0)
        rel = max(0.4, self.release if release is None else release * 3.0)
        f0 = 440.0 * 2 ** ((midi - 69) / 12.0)
        m = int((dur + rel + 0.12) * SR)
        x = np.arange(m) / SR
        out = np.zeros((m, 2))
        tilt = 1.25 - 0.45 * vel                       # plus fort : plus brillant
        fmax = min(6000.0, SR * 0.4)
        for v in range(self.n):
            det = self.rng.normal(0.0, 5.0)
            drift = np.interp(x, np.linspace(0, x[-1], 6), self.rng.normal(0.0, 3.0, 6))
            rate = self.rng.uniform(4.6, 5.9)
            depth = self.rng.uniform(0.003, 0.0065)
            vib = depth * np.sin(2 * np.pi * rate * x + self.rng.uniform(0, 6.3)) * np.clip((x - 0.3) / 0.7, 0, 1)
            f = f0 * 2 ** ((det + drift) / 1200.0) * (1.0 + vib)
            ph = 2 * np.pi * np.cumsum(f) / SR + self.rng.uniform(0, 6.3)
            src = np.zeros(m)
            for k in range(1, int(fmax / f0) + 1):
                w = np.clip((fmax - k * f0) / (0.3 * fmax), 0.0, 1.0)
                src += np.sin(k * ph) * w / k ** tilt
            src /= np.std(src) + 1e-9
            src += signal.sosfilt(signal.butter(2, 1200, "highpass", fs=SR, output="sos"), self.rng.standard_normal(m)) * self.souffle
            sc = self.fs * self.rng.uniform(0.97, 1.03)
            y = np.zeros(m)
            for F, B, g in self.fm:
                b, a = _reso(F * sc, B * sc)
                y += g * signal.lfilter(b, a, src)
            d = int(self.rng.uniform(0.0, 0.07) * SR)
            y = np.concatenate([np.zeros(d), y[: m - d]])
            p = -0.85 + 1.7 * v / max(1, self.n - 1) + self.rng.uniform(-0.1, 0.1)
            out[:, 0] += y * np.cos((p + 1) * np.pi / 4)
            out[:, 1] += y * np.sin((p + 1) * np.pi / 4)
        env = np.clip(x / att, 0, 1) ** 1.5 * np.clip((dur + rel - x) / rel, 0, 1) ** 1.3
        out *= env[:, None]
        out *= 0.25 * (0.45 + 0.55 * vel) / np.sqrt(self.n)
        return out.astype(np.float32)


class Musette:
    """Les anches de la fête : l'harmonica chromatique (VCSL), trois anches par note (une juste, une
    un peu haute, une un peu basse : leurs battements donnent le trémolo de l'accordéon musette)."""

    def __init__(self, name: str, inner, cents: float = 14.0, pan: float = 0.0, width: float = 0.7, gain: float = 1.0):
        self.name = name
        self.inner = inner
        self.cents = cents
        self.pan = pan
        self.width = width
        self.gain = gain
        self.lag = inner.lag

    def note(self, midi: float, dur: float, vel: float = 0.6, attack=None, release=None, legato: bool = False) -> np.ndarray:
        c = self.cents / 100.0
        ys = [self.inner.note(midi + d, dur, vel, attack, release, legato) for d in (0.0, c, -c)]
        n = max(len(y) for y in ys)
        ys = [np.pad(y, ((0, n - len(y)), (0, 0))) for y in ys]
        a, b, d = ys
        l = a[:, 0] * 0.8 + b[:, 0] * 0.7 + d[:, 0] * 0.3
        r = a[:, 1] * 0.8 + b[:, 1] * 0.3 + d[:, 1] * 0.7
        return (np.stack([l, r], axis=1) * 0.5).astype(np.float32)


SYNTH = {
    "choeur_h": lambda: Choeur("choeur_h", femmes=False, voyelle="o", n=6, pan=0.2, gain=1.0, seed=7001),
    "choeur_f": lambda: Choeur("choeur_f", femmes=True, voyelle="a", n=6, pan=-0.2, gain=0.9, seed=7002),
    "choeur_doux": lambda: Choeur("choeur_doux", femmes=True, voyelle="ou", n=6, pan=0.0, gain=0.5, attack=0.8, release=1.4, seed=7003),
    "musette": lambda: Musette("musette", vcsl("harmonica"), cents=14.0, pan=-0.05, width=0.7, gain=2.1),
    "accordeon_g": lambda: cm56.Accordion("accordeon_g", pan=0.15, width=0.4, gain=0.75, detune=6.0, bright=0.4, attack=0.012, release=0.05),
}


def instrument(key: str):
    if key in SYNTH:
        return SYNTH[key]()
    if key in VCSL_INSTR:
        return vcsl(key)
    return cm.I(key)


class Morceau70(cm69.Morceau):
    """La partition de la V69 (notes d'abord notées, puis jouées pupitre par pupitre, un seul jeu
    d'échantillons en mémoire à la fois), avec en plus les pupitres de la VCSL et les instruments
    synthétisés (chœur, musette, accordéon)."""

    def play(self) -> None:
        for key in list(self._todo):
            ins = instrument(key)
            for midi, t, jit, dur, vel, kw in self._todo.pop(key):
                at = max(0.0, t - (0.0 if kw.get("legato") else ins.lag) + jit)
                self.mix.add(key, ins.note(midi, dur, vel, **kw), at, ins.pan, ins.width, ins.gain)
            cm._cache.pop(key, None)
            del ins
            gc.collect()


def register() -> None:
    cm68.register()
    cm69.register()
    cm.WET.update(VCSL_WET)


def _bass(sym: str, lo: int = 38) -> int:
    _, _, b = cm.chord(sym)
    return lo + ((b - lo) % 12)


def _fifth(sym: str, lo: int = 38, hi: int = 50) -> int:
    r, _, _ = cm.chord(sym)
    r = lo + ((r - lo) % 12)
    return r + 7 if r + 7 <= hi else r - 5


# =========================================================================== Pandémonia

def valse_bar(P, bar: int, sym: str, vel: float = 1.0, lh: str | None = "clavecin", lo: int = 57, hi: int = 69,
              n: int = 3, alt: bool = False, bass: bool = True) -> None:
    """« Poum-tchak-tchak » : la basse au premier temps (violoncelles et contrebasse en pizzicato ;
    une mesure sur deux, la quinte), l'accord aux deux autres temps."""
    if bass:
        root = _fifth(sym) if (alt and "/" not in sym) else _bass(sym)
        P.note("vc_pizz", root, bar, 0, 1.0, 0.44 * vel)
        P.note("cb_pizz", root - 12 if root - 12 >= 28 else root, bar, 0, 1.0, 0.34 * vel)
    if lh:
        _, pcs, _ = cm.chord(sym)
        vs = P._voicing(lh, pcs, lo, hi, n)
        for beat, v in ((1, 0.42), (2, 0.35)):
            for m in vs:
                P.note(lh, m, bar, beat, 0.55, v * vel)


def pandemonia():
    P = Morceau70("pandemonia", 144, 96, beats=3, seed=701, room=3.0)
    intro = ["Dm", "Dm/C", "Bb", "A7", "Dm", "Gm/Bb", "A7", "A7"]
    A = ["Dm", "Dm", "Gm/Bb", "A7", "Dm", "F", "Gm", "A7", "Dm", "Dm/C", "Bb", "Gm", "Dm/A", "A7", "Dm", "Dm"]
    B = ["F", "C7/E", "F", "Bb", "Gm7", "C7", "F", "C7", "F", "A7", "Dm", "Bb", "F/C", "C7", "F", "A7"]
    C = ["Dm", "Bb/D", "Gm/D", "A/D", "Dm", "Eb", "A7", "Dm", "Bb", "Gm", "Eb", "A7", "Dm", "Gm/D", "Dm/A", "A7"]
    coda = ["Dm", "Gm/D", "Dm", "A7/C#", "Dm", "Bb", "A7", "A7"]
    melA = ("A4:1 D5:1 F5:1 | A5:2 G5:0.5 F5:0.5 | E5:1 G5:1 Bb5:1 | A5:1.5 G5:0.5 F5:0.5 E5:0.5 | "
            "D5:1 F5:1 A5:1 | C6:2 A5:1 | Bb5:1 G5:1 E5:1 | C#5:2 A4:1 | "
            "A4:1 D5:1 F5:1 | A5:2 G5:0.5 F5:0.5 | F5:1 D5:1 Bb4:1 | G5:1.5 F5:0.5 E5:1 | "
            "F5:1 E5:1 D5:1 | G5:1 E5:1 C#5:1 | D5:3 | r:3")
    contre = ("F5:3 | F5:2 E5:1 | D5:3 | C#5:3 | A4:3 | A4:3 | G4:2 Bb4:1 | A4:3 | "
              "F5:3 | E5:3 | D5:3 | Bb4:2 C#5:1 | D5:2 A4:1 | C#5:3 | A4:3 | r:3")
    melB = ("C5:1 F5:1 A5:1 | G5:1.5 F5:0.5 E5:1 | F5:1 A5:1 C6:1 | D6:2 Bb5:1 | "
            "Bb5:1 G5:1 D5:1 | E5:1.5 F5:0.5 G5:1 | A5:2 F5:1 | E5:1 G5:1 Bb5:1 | "
            "A5:1 C6:1 A5:1 | C#6:1.5 B5:0.5 A5:1 | D6:2 A5:1 | Bb5:1 G5:1 F5:1 | "
            "A5:1 F5:1 C5:1 | E5:1 G5:1 Bb5:1 | A5:3 | E5:1 C#5:1 A4:1")
    melC = ("D4:2 E4:0.5 F4:0.5 | D4:1.5 C#4:0.5 D4:1 | Bb4:2 A4:0.5 G4:0.5 | A4:3 | "
            "F4:1 E4:1 D4:1 | Eb4:2 G4:1 | C#4:2 E4:1 | D4:3 | "
            "F4:2 Bb4:1 | D5:2 C5:0.5 Bb4:0.5 | Bb4:1.5 G4:0.5 Eb4:1 | E4:1 G4:1 C#5:1 | "
            "D5:2 A4:1 | Bb4:2 G4:1 | F4:1 E4:1 D4:1 | C#4:1.5 E4:0.5 A4:1")
    melCoda = ("A4:1 D5:1 F5:1 | E5:1.5 D5:0.5 C#5:1 | A4:1 D5:1 F5:1 | E5:3 | "
               "A4:1 D5:1 F5:1 | Bb5:2 G5:1 | E5:3 | C#5:2 r:1")
    # --- l'introduction (0-7) : la cloche de la cathédrale, le clavecin seul, l'orgue qui tient le ré
    P.note("cloche", 62, 0, 0, 3.0, 0.5)
    P.arp("clavecin", intro, 0, 50, step=0.5, pattern=[0, 2, 4, 5, 4, 2], vel=0.3, ring=1.2, span=2)
    P.note("orgue_pedale", 26, 0, 0, 12.0, 0.32, attack=0.8)
    P.pad("orgue_flute", intro, 0, 53, 65, 2, vel=0.16)
    for i, s in enumerate(intro[4:]):
        valse_bar(P, 4 + i, s, 0.7, lh=None)
    mel(P, "solo_vln", 4, "A4:1 D5:1 F5:1 | Bb5:2 G5:1 | E5:1 G5:1 C#5:1 | A4:3", vel=0.55, legato=0.04)
    # --- A (8-23) : les violons chantent l'air, le clavecin fait « tchak-tchak »
    mel(P, "vln", 8, melA, vel=0.56, legato=0.04)
    for i, s in enumerate(A):
        valse_bar(P, 8 + i, s, 1.0, alt=i % 2 == 1)
    P.pad("orgue_flute", A, 8, 53, 65, 2, vel=0.14)
    P.hit("triangle", 8, 0, 0.12)
    # --- A' (24-39) : le petit orgue reprend l'air, les violons en contre-chant, le clavecin arpège
    mel(P, "orgue_plein", 24, melA, vel=0.75, octave=-1, legato=0.02)
    mel(P, "vln_pad", 24, contre, vel=0.42, legato=0.06)
    for i, s in enumerate(A):
        valse_bar(P, 24 + i, s, 0.95, lh="vla_pizz", lo=55, hi=67, n=2, alt=i % 2 == 1)
    P.arp("clavecin", A, 24, 62, step=0.5, pattern=[0, 2, 4, 2, 1, 2], vel=0.26, ring=0.8, span=2)
    # --- B (40-55) : fa majeur, joyeux ; la flûte et la clarinette, le basson qui fait « poum-pa-pa »
    mel(P, "flute", 40, melB, vel=0.7, legato=0.03)
    mel(P, "clar", 40, melB, vel=0.06, octave=-1, legato=0.03)
    for i, s in enumerate(B):
        valse_bar(P, 40 + i, s, 0.85, lh="vln_pizz", lo=62, hi=74, n=2, alt=i % 2 == 1)
        r = _bass(s, 34) if "/" in s else (_fifth(s, 34, 46) if i % 2 else _bass(s, 34))
        P.note("bsn_stac", r, 40 + i, 0, 0.6, 0.45)
        P.note("bsn_stac", r + 12, 40 + i, 2, 0.4, 0.3)
    P.arp("clavecin", B, 40, 53, step=1.0, pattern=[0, 2, 4, 3], vel=0.24, ring=1.0, span=2)
    P.sparkle("glock", B, 40, 84, 96, prob=0.22, vel=0.2, step=1.5)
    P.hit("triangle", 40, 0, 0.16)
    P.hit("triangle", 48, 0, 0.13)
    # --- C (56-71) : le mystère ; le violoncelle, le grand orgue, les trémolos, la cloche, les timbales
    mel(P, "vc", 56, melC, vel=0.55, legato=0.05)
    P.pad("orgue", C, 56, 50, 62, 3, vel=0.24)
    P.pad("trem_nuit", C, 56, 69, 81, 2, vel=0.12)
    P.note("orgue_pedale", 26, 56, 0, 12.0, 0.34, attack=0.6)
    for i, s in enumerate(C[4:]):
        P.note("orgue_pedale", _bass(s, 24), 60 + i, 0, 3.2, 0.3)
    P.arp("clavecin", C, 56, 50, step=0.5, pattern=[0, 1, 2, 1, 0, 1], vel=0.24, ring=0.5, span=1)
    for i, s in enumerate(C):
        valse_bar(P, 56 + i, s, 0.55, lh=None)
        pcs = cm.chord(s)[1]
        if 2 in pcs or 9 in pcs:      # les timbales accordées en ré et en la
            P.note("timp", 38 if 2 in pcs else 45, 56 + i, 0, 1.5, 0.26 if i % 2 == 0 else 0.18)
    P.note("cloche", 62, 56, 0, 3.0, 0.42)
    P.note("cloche", 57, 64, 0, 3.0, 0.36)
    P.hit("timp_roll", 63, 0, 0.18, 3.0, midi=45)
    P.hit("timp_roll", 70, 0, 0.22, 6.0, midi=45)
    # --- A'' (72-87) : tout le monde
    P.hit("cymbal", 70, 0, 0.22, 6.0)
    P.hit("crash", 72, 0, 0.2)
    mel(P, "vln", 72, melA, vel=0.56, legato=0.04)
    mel(P, "flute", 72, melA, vel=0.24, octave=1, legato=0.03)
    mel(P, "orgue_plein", 72, contre, vel=0.3, octave=-1, legato=0.02)
    mel(P, "glock", 72, "|".join(melA.split("|")[:8]), vel=0.14)
    for i, s in enumerate(A):
        valse_bar(P, 72 + i, s, 1.05, alt=i % 2 == 1)
    P.pad("orgue", A, 72, 50, 62, 3, vel=0.15)
    P.pad("vla_pad", A, 72, 55, 67, 2, vel=0.12)
    # --- la fin (88-95) : l'orgue flûte rappelle le motif, la basse descend, la boucle repart
    mel(P, "orgue_flute", 88, melCoda, vel=0.7, legato=0.02)
    P.arp("clavecin", coda, 88, 57, step=0.5, pattern=[0, 2, 4, 2, 0, 2], vel=0.22, ring=1.0, span=2)
    for i, s in enumerate(coda):
        valse_bar(P, 88 + i, s, 0.8 - 0.03 * i, lh=None)
    P.note("orgue_pedale", 26, 88, 0, 9.0, 0.26, attack=0.6)
    return P


# =========================================================================== L'Île de Braise

def braise():
    P = Morceau70("braise", 64, 32, beats=4, seed=702, room=3.8)
    intro = ["Cm", "Cm", "Cm", "Cm"]
    A = ["Cm", "Ab/C", "Fm/C", "Cm", "Ab", "Eb/G", "Fm", "G"]
    B = ["Ab", "Bb", "Eb/G", "Cm", "Ab", "Bb", "Gsus4", "G"]
    Cc = ["Cm", "Db/C", "Cm", "Db/C", "Fm", "Db", "G", "G"]
    outro = ["Cm", "Cm", "Ab/C", "Cm"]
    melA = ("C4:2 Eb4:1 G4:1 | Ab4:3 G4:1 | F4:2 Ab4:1 C5:1 | G4:4 | "
            "Ab4:2 C5:1 Eb5:1 | G4:2 Bb4:2 | Ab4:1.5 G4:0.5 F4:1 Eb4:1 | D4:2 B3:2")
    melB = ("Eb4:2 F4:1 G4:1 | Bb4:3 Ab4:1 | G4:2 Eb4:1 G4:1 | C5:4 | "
            "C5:2 Bb4:1 Ab4:1 | Bb4:2 D5:2 | C5:2 G4:2 | B4:4")
    melC = ("G4:3 Ab4:1 | Ab4:2 F4:1 Db4:1 | Eb4:2 C4:1 D4:1 | Db4:4 | "
            "C4:2 F4:1 Ab4:1 | Ab4:2 F4:1 Db4:1 | D4:2 F4:1 Eb4:0.5 D4:0.5 | B3:4")
    # --- le bourdon de la montagne : la pédale de l'orgue, les contrebasses, le gong
    drone(P, "orgue_pedale", 24, 0, 12, 0.34, every=4, attack=1.2)
    drone(P, "orgue_pedale", 24, 20, 32, 0.32, every=4, attack=1.2)
    drone(P, "cb", 36, 0, 4, 0.3, every=4, attack=1.0)
    drone(P, "cb", 36, 28, 32, 0.3, every=4, attack=1.0)
    drone(P, "vc_drone", 48, 0, 4, 0.36, every=4)
    drone(P, "vc_drone", 55, 0, 4, 0.26, every=4)
    drone(P, "vc_drone", 48, 28, 32, 0.34, every=4)
    drone(P, "vc_drone", 55, 28, 32, 0.24, every=4)
    P.hit("gong", 0, 0, 0.3, 8.0)
    P.hit("gong", 28, 0, 0.26, 8.0)
    P.hit("timp_roll", 0, 0, 0.2, 8.0, midi=36)
    P.hit("timp_roll", 2, 2, 0.24, 6.0, midi=43)
    # le chœur d'hommes : la quinte vide, qui enfle
    for b, m, v in ((0, 48, 0.32), (0, 55, 0.28), (2, 48, 0.4), (2, 55, 0.36), (2, 60, 0.3)):
        P.note("choeur_h", m, b, 0, 8.0, v)
    # --- A (4-11) : les cors chantent le thème de l'île
    mel(P, "horn", 4, melA, vel=0.55, legato=0.05)
    P.pad("horn_pad", A, 4, 53, 65, 2, vel=0.16)
    P.pad("choeur_h", A, 4, 48, 62, 2, vel=0.32)
    P.pad("choeur_f", A, 4, 60, 74, 2, vel=0.3)
    P.bass("cb", A, 4, 28, 40, vel=0.3)
    for i, s in enumerate(A):
        low = _bass(s, 36)
        P.note("timp", low if low <= 43 else low - 12, 4 + i, 0, 2.0, 0.34 if i % 2 == 0 else 0.26)
        P.hit("cadre", 4 + i, 0, 0.3)
        P.hit("cadre", 4 + i, 0.45, 0.18)
    P.hit("timp_roll", 11, 0, 0.26, 4.0, midi=43)
    P.hit("cymbal", 10, 2, 0.2, 6.0)
    # --- B (12-19) : la grandeur
    P.hit("crash", 12, 0, 0.2)
    P.hit("gong", 12, 0, 0.22, 8.0)
    mel(P, "horn", 12, melB, vel=0.68, legato=0.05)
    mel(P, "trp", 12, melB, vel=0.24, legato=0.04)
    P.pad("tbn", B, 12, 45, 57, 2, vel=0.2)
    P.bass("tuba", B, 12, 28, 40, vel=0.32)
    P.bass("cb", B, 12, 28, 40, vel=0.3)
    P.pad("choeur_h", B, 12, 48, 62, 3, vel=0.38)
    P.pad("choeur_f", B, 12, 62, 76, 3, vel=0.42)
    P.pad("trem_nuit", B, 12, 72, 84, 2, vel=0.12)
    for i, s in enumerate(B):
        low = _bass(s, 36)
        P.note("timp", low if low <= 43 else low - 12, 12 + i, 0, 2.0, 0.38 if i % 2 == 0 else 0.3)
        P.note("timp", low if low <= 43 else low - 12, 12 + i, 2.5, 1.0, 0.2)
    P.hit("timp_roll", 15, 2, 0.24, 2.0, midi=41)
    P.hit("timp_roll", 19, 0, 0.3, 4.0, midi=43)
    P.hit("cymbal", 18, 2, 0.18, 6.0)
    # --- C (20-27) : la chaleur immobile ; la clarinette, l'accord phrygien, la harpe, le cœur
    mel(P, "clar", 20, melC, vel=0.46, legato=0.05)
    P.pad("choeur_doux", Cc, 20, 60, 72, 2, vel=0.4)
    P.pad("vla_pad", Cc, 20, 53, 65, 2, vel=0.08)
    P.arp("harp", Cc, 20, 43, step=1.0, pattern=[0, 2, 4, 2], vel=0.2, span=2)
    for b in range(20, 28):
        P.hit("cadre", b, 0, 0.32)
        P.hit("cadre", b, 0.42, 0.2)
    P.hit("bd_rub", 24, 0, 0.3, 4.0)
    # --- la fin (28-31) : le bourdon, la quinte du chœur, le roulement qui ramène au début
    for m, v in ((48, 0.36), (55, 0.3)):
        P.note("choeur_h", m, 28, 0, 15.0, v)
    P.note("choeur_doux", 67, 28, 0, 8.0, 0.24)
    P.hit("timp_roll", 30, 0, 0.22, 8.0, midi=36)
    P.hit("cadre", 31, 3, 0.24)
    return P


# =========================================================================== Les Neuf Cercles

def neuf_cercles():
    P = Morceau70("neuf_cercles", 60, 32, beats=4, seed=703, room=4.2)
    L = ["Dm", "A/C#", "Dm/C", "G/B", "Gm/Bb", "Dm/A", "Gm", "A"]
    L2 = ["Dm", "A/C#", "Dm/C", "G/B", "Gm/Bb", "Dm/A", "Gm6", "A7"]
    froid = ["Dm", "Bb", "Gm", "A", "Dm", "F", "Gm", "A"]
    cocyte = ["Dm", "Dm", "Bb", "Bb", "Gm", "Gm", "A", "A"]
    lamento = "D3:4 | C#3:4 | C3:4 | B2:4 | Bb2:4 | A2:4 | G2:4 | A2:4"
    melL = ("A4:3 F4:1 | E4:4 | F4:2 A4:1 G4:1 | G4:2 D4:2 | "
            "Bb4:2 G4:1 D4:1 | F4:2 E4:1 D4:1 | Bb3:1 D4:1 G4:2 | C#4:4")
    melD = ("D4:2 F4:1 A4:1 | G4:2 E4:2 | A4:2 G4:1 F4:1 | D4:4 | "
            "Bb3:2 D4:1 G4:1 | F4:2 E4:1 D4:1 | E4:2 G4:1 Bb4:1 | A4:4")
    melF = ("A5:4 | F5:2 D5:2 | G5:3 Bb5:1 | A5:4 | D6:2 C6:1 A5:1 | C6:2 A5:1 F5:1 | Bb5:2 G5:1 E5:1 | C#5:4")
    melP = ("D5:2 E5:1 F5:1 | A5:4 | Bb5:2 A5:1 F5:1 | D5:4 | G5:2 Bb5:1 D6:1 | Bb5:2 G5:2 | E5:2 G5:1 E5:1 | C#5:4")
    # --- 0-7 : la porte ; l'orgue doux, la basse qui descend, la clarinette dans l'ombre
    P.pad("orgue_doux", L, 0, 50, 62, 3, vel=0.24)
    mel(P, "cb", 0, lamento, vel=0.26, octave=-1, legato=0.06)
    mel(P, "vc_drone", 0, lamento, vel=0.4, legato=0.06)
    mel(P, "clar", 0, melL, vel=0.42, legato=0.05)
    P.hit("gong", 0, 0, 0.2, 8.0)
    P.hit("bd_rub", 0, 0, 0.3, 4.0)
    P.hit("bd_rub", 4, 0, 0.26, 4.0)
    # --- 8-15 : la descente ; le grand orgue, la pédale, le violoncelle, les trombones, le cœur
    P.pad("orgue", L2, 8, 50, 62, 3, vel=0.22)
    for i, s in enumerate(L2):
        P.note("orgue_pedale", _bass(s, 24), 8 + i, 0, 4.2, 0.3)
    mel(P, "cb", 8, lamento, vel=0.3, octave=-1, legato=0.06)
    mel(P, "vc", 8, melD, vel=0.5, legato=0.05)
    P.pad("tbn", L2, 8, 45, 57, 2, vel=0.1)
    P.bass("tuba", L2, 8, 28, 40, vel=0.18)
    for b in range(8, 16):
        P.note("timp", 38, b, 0, 1.0, 0.24)
        P.note("timp", 38, b, 0.6, 1.0, 0.16)
    P.hit("timp_roll", 15, 0, 0.2, 4.0, midi=45)
    # --- 16-23 : le froid monte ; la flûte sans vibrato, la harpe, les trémolos tout en haut, les verres
    P.pad("orgue_doux", froid[:4], 16, 50, 62, 3, vel=0.18)
    mel(P, "flute_nv", 16, melF, vel=0.42, legato=0.04)
    P.pad("trem_nuit", froid, 16, 74, 86, 2, vel=0.12)
    P.arp("harp", froid, 16, 74, step=1.0, pattern=[0, 2, 4, 2], vel=0.15, span=2)
    P.pad("verres", froid[4:], 20, 74, 89, 2, vel=0.28)
    P.bass("cb", froid, 16, 28, 40, vel=0.22)
    P.hit("chimes", 20, 0, 0.12)
    # --- 24-31 : le Cocyte, le lac gelé ; le psaltérion, les verres, les carillons, le givre
    mel(P, "psalterion", 24, melP, vel=0.75, legato=0.05)
    P.pad("verres", cocyte, 24, 72, 89, 3, vel=0.22)
    P.sparkle("carillon", cocyte, 24, 72, 96, prob=0.3, vel=0.22, step=2.0)
    P.sparkle("glock", cocyte, 24, 84, 96, prob=0.15, vel=0.1, step=2.0)
    P.pad("vln_pad", cocyte, 24, 81, 93, 2, vel=0.07)
    drone(P, "cb", 38, 24, 32, 0.2, every=4, attack=1.0)
    # l'orgue doux qui revient sous le givre, pour la boucle
    P.note("orgue_doux", 50, 31, 1, 3.2, 0.2, attack=1.5)
    P.note("orgue_doux", 57, 31, 1, 3.2, 0.18, attack=1.5)
    return P


# =========================================================================== Le Tournoi des Cornes

def arene_drums(P, bar: int, vel: float = 1.0, fill: bool = False) -> None:
    """La marche : la grosse caisse sur 1 et 3, la caisse claire sur 2 et 4 (« ra-ta-plan »)."""
    P.hit("gc", bar, 0, 0.5 * vel, 1.0)
    P.hit("gc", bar, 2, 0.42 * vel, 1.0)
    for pos, v in ((1, 0.42), (3, 0.46), (3.5, 0.2), (3.75, 0.24)):
        P.hit("caisse", bar, pos, v * vel, 0.5)
    if fill:
        for k in range(8):
            P.hit("caisse", bar, 2 + k * 0.25, (0.22 + 0.04 * k) * vel, 0.25)
        P.hit("tom", bar, 3.5, 0.4 * vel, 0.5)


def ostinato_arene(P, prog, bar0: int, vel: float = 1.0) -> None:
    """Les cordes en spiccato : fondamentale, octave, quinte, en croches (comme le combat de la V51)."""
    for i, s in enumerate(prog):
        r = _bass(s.split()[0], 38)
        for k, off in enumerate([0, 0, 12, 0, 7, 0, 12, 7]):
            P.note("vc_spic", r + off, bar0 + i, k * 0.5, 0.45, (0.5 if k % 2 == 0 else 0.38) * vel)
            P.note("vla_spic", r + 12 + off, bar0 + i, k * 0.5, 0.45, 0.34 * vel)


def arene():
    P = Morceau70("arene", 128, 64, beats=4, seed=704, room=2.6)
    intro = ["Bb", "Eb F", "Bb", "F"]
    A = ["Bb", "Bb", "Eb", "F", "Gm", "Eb", "C7/E", "F", "Bb", "Bb/D", "Eb", "Gb", "Bb/F", "F", "Bb", "Bb"]
    B = ["Gm", "Gm", "Eb", "Eb", "Cm", "D", "Gm", "D"]
    Cb = ["Bb", "Bb", "Gb", "Ab", "Bb", "Bb", "Gb", "F"]
    Bp = ["Eb", "F", "Gm", "Eb", "Cm", "F", "Bb/D", "F"]
    coda = ["Bb", "Gb", "Ab", "Bb"]
    fanfare = "F4:0.5 F4:0.5 F4:0.5 Bb4:0.5 D5:1 F5:1 | Eb5:1.5 D5:0.5 C5:2 | D5:0.5 D5:0.5 D5:0.5 F5:0.5 Bb5:2 | A5:2 F5:2"
    melA = ("F4:1.5 Bb4:0.5 Bb4:1 C5:1 | D5:2 C5:1 Bb4:1 | Eb5:1.5 D5:0.5 C5:1 Bb4:1 | C5:3 F4:1 | "
            "G4:1.5 Bb4:0.5 D5:1.5 C5:0.5 | Bb4:2 G4:1 Eb4:1 | E4:1 G4:1 Bb4:1 C5:1 | A4:2 F4:2 | "
            "F4:1.5 Bb4:0.5 Bb4:1 C5:1 | D5:2 F5:1 D5:1 | Eb5:1.5 D5:0.5 C5:1 Eb5:1 | Db5:2 Bb4:1 Gb4:1 | "
            "F4:1 Bb4:1 D5:1 F5:1 | Eb5:1.5 D5:0.5 C5:1 A4:1 | Bb4:4 | r:4")
    riff = ("G2:0.5 G2:0.5 Bb2:0.5 G2:0.5 D3:1 C3:0.5 Bb2:0.5 | A2:1 G2:1 F#2:1 D2:1 | "
            "Eb2:0.5 Eb2:0.5 G2:0.5 Eb2:0.5 Bb2:1 Ab2:0.5 G2:0.5 | F2:1 Eb2:1 D2:1 Bb1:1 | "
            "C2:0.5 C2:0.5 Eb2:0.5 C2:0.5 G2:1 F2:0.5 Eb2:0.5 | D2:1 F#2:1 A2:1 D3:1 | "
            "G2:0.5 G2:0.5 Bb2:0.5 G2:0.5 D3:1 C3:0.5 Bb2:0.5 | A2:1 F#2:1 D2:2")
    appels = "r:2 D5:1 G5:1 | Bb5:2 A5:1 G5:1 | r:2 Eb5:1 G5:1 | Bb5:3 r:1 | r:2 C5:1 Eb5:1 | F#5:2 A5:2 | r:2 D5:1 G5:1 | F#5:4"
    melBp = ("G4:1.5 Bb4:0.5 Eb5:2 | F5:1.5 C5:0.5 A4:2 | D5:1 G5:1 Bb4:1 D5:1 | Eb5:3 Bb4:1 | "
             "C5:1.5 Eb5:0.5 G5:2 | F5:2 A4:2 | Bb4:1 D5:1 F5:1 D5:1 | C5:4")
    # --- 0-3 : la fanfare et les tambours
    mel(P, "trp", 0, fanfare, vel=0.55, legato=0.02)
    mel(P, "horn", 0, fanfare, vel=0.36, octave=-1, legato=0.02)
    P.pad("tbn", intro, 0, 46, 58, 2, vel=0.18)
    P.bass("tuba", intro, 0, 29, 41, vel=0.34)
    for b, s in enumerate(intro):
        arene_drums(P, b, 0.85, fill=b == 3)
        for j, c in enumerate(s.split()):
            P.note("timp", 46 if c.startswith("B") else (39 if c.startswith("E") else 41), b, 2 * j, 1.0, 0.4)
    P.hit("crash", 0, 0, 0.24)
    # --- A (4-19) : le thème héroïque des cors
    mel(P, "horn", 4, melA, vel=0.58, legato=0.04)
    P.pad("horn_pad", A, 4, 53, 65, 2, vel=0.14)
    ostinato_arene(P, A, 4, 0.85)
    P.bass("cb", A, 4, 29, 41, vel=0.18)
    P.bass("tuba", A, 4, 29, 41, vel=0.22)
    for i, s in enumerate(A):
        arene_drums(P, 4 + i, 1.0, fill=i in (7, 15))
        if i % 4 == 0:
            P.hit("crash", 4 + i, 0, 0.2)
        r = _bass(s, 34)
        P.note("timp", r if r <= 45 else r - 12, 4 + i, 0, 1.0, 0.36)
    mel(P, "trp", 11, "C5:2 F5:2", vel=0.32)
    # --- B (20-27) : sol mineur ; le riff des trombones et du tuba, les appels de trompette, les toms
    mel(P, "tbn", 20, riff, vel=0.66, octave=1, legato=0.0)
    mel(P, "tuba", 20, riff, vel=0.42, legato=0.0)
    mel(P, "trp", 20, appels, vel=0.56, legato=0.02)
    P.pad("horn_pad", B, 20, 55, 67, 2, vel=0.16)
    P.pad("trem_nuit", B, 20, 67, 79, 2, vel=0.12)
    for i, s in enumerate(B):
        P.hit("gc", 20 + i, 0, 0.5, 1.0)
        P.hit("tom", 20 + i, 1.5, 0.36, 0.5)
        P.hit("tom", 20 + i, 2, 0.42, 0.5)
        P.hit("caisse", 20 + i, 3, 0.4, 0.5)
        P.hit("tom_b", 20 + i, 3.5, 0.3, 0.5)
        r = _bass(s, 38)
        P.note("timp", r if r <= 45 else r - 12, 20 + i, 0, 1.0, 0.36)
    P.hit("crash", 20, 0, 0.2)
    P.hit("crash", 24, 0, 0.18)
    # --- C (28-35) : la pause des tambours (toms, claquements de mains, timbales), les cors qui appellent
    for i, s in enumerate(Cb):
        b = 28 + i
        P.hit("gc", b, 0, 0.55, 1.0)
        P.hit("tom", b, 0.75, 0.34, 0.5)
        P.hit("tom", b, 1.5, 0.4, 0.5)
        P.hit("claque", b, 1, 0.5, 0.5)
        P.hit("claque", b, 3, 0.55, 0.5)
        P.hit("gc", b, 2, 0.45, 1.0)
        P.hit("tom_b", b, 2.5, 0.3, 0.5)
        P.hit("tom_b", b, 2.75, 0.26, 0.5)
        r = _bass(s, 34)
        P.note("timp", r if r <= 45 else r - 12, b, 0, 1.0, 0.38)
        P.note("cb_pizz", _bass(s, 29), b, 0, 1.0, 0.45)
    for b in (28, 30, 32):
        mel(P, "horn", b, "Bb3:1 F4:1 Bb4:2 | r:4", vel=0.5, legato=0.03)
    mel(P, "horn", 34, "Bb3:0.5 D4:0.5 F4:0.5 Bb4:0.5 D5:2 | C5:4", vel=0.55, legato=0.03)
    P.hit("snare_roll", 35, 0, 0.3, 4.0)
    P.hit("cymbal", 34, 2, 0.24, 6.0)
    # --- A' (36-51) : le thème en tutti
    P.hit("crash", 36, 0, 0.26)
    mel(P, "horn", 36, melA, vel=0.62, legato=0.04)
    mel(P, "trp", 36, melA, vel=0.32, legato=0.03)
    mel(P, "glock", 36, melA, vel=0.14, octave=1)
    P.pad("tbn", A, 36, 46, 58, 2, vel=0.17)
    P.pad("vln_pad", A, 36, 65, 77, 2, vel=0.12)
    ostinato_arene(P, A, 36, 1.0)
    P.bass("cb", A, 36, 29, 41, vel=0.2)
    P.bass("tuba", A, 36, 29, 41, vel=0.28)
    for i, s in enumerate(A):
        arene_drums(P, 36 + i, 1.05, fill=i in (7, 15))
        if i % 4 == 0 and i:
            P.hit("crash", 36 + i, 0, 0.2)
        r = _bass(s, 34)
        P.note("timp", r if r <= 45 else r - 12, 36 + i, 0, 1.0, 0.4)
    # --- B' (52-59) : l'apothéose
    P.hit("crash", 52, 0, 0.26)
    mel(P, "horn", 52, melBp, vel=0.62, legato=0.04)
    mel(P, "trp", 52, melBp, vel=0.38, legato=0.03)
    P.pad("tbn", Bp, 52, 46, 58, 2, vel=0.2)
    P.pad("trem_nuit", Bp, 52, 70, 82, 2, vel=0.12)
    ostinato_arene(P, Bp, 52, 1.0)
    P.bass("tuba", Bp, 52, 29, 41, vel=0.3)
    for i, s in enumerate(Bp):
        arene_drums(P, 52 + i, 1.1, fill=i == 7)
        r = _bass(s, 34)
        P.note("timp", r if r <= 45 else r - 12, 52 + i, 0, 1.0, 0.42)
    P.hit("timp_roll", 59, 0, 0.3, 4.0, midi=41)
    # --- 60-63 : la fanfare finale (si bémol, sol bémol, la bémol, si bémol), la boucle repart
    P.hit("crash", 60, 0, 0.26)
    mel(P, "trp", 60, "Bb4:1 D5:1 F5:2 | Gb5:2 Db5:2 | Ab5:2 Eb5:2 | F5:3 r:1", vel=0.52, legato=0.02)
    mel(P, "horn", 60, "D4:1 F4:1 Bb4:2 | Bb4:2 Gb4:2 | C5:2 Ab4:2 | A4:3 r:1", vel=0.5, legato=0.03)
    P.pad("tbn", coda, 60, 46, 58, 2, vel=0.22)
    P.bass("tuba", coda, 60, 29, 41, vel=0.34)
    for i, s in enumerate(coda):
        arene_drums(P, 60 + i, 1.0, fill=i == 3)
        r = _bass(s, 34)
        P.note("timp", r if r <= 45 else r - 12, 60 + i, 0, 1.0, 0.42)
    return P


# =========================================================================== La Nuit des Lanternes

def gigue_bar(P, bar: int, sym: str, vel: float = 1.0, orgue: bool = True, accordeon: bool = True, tamb: bool = True,
              bass: bool = True) -> None:
    """« Poum-tchak, poum-tchak » en 6/8 : la basse sur la première et la quatrième croche
    (fondamentale puis quinte), l'accord sur la troisième et la sixième ; le tambourin."""
    syms = sym.split()
    for half, s in ((0, syms[0]), (3, syms[-1])):
        _, pcs, _ = cm.chord(s)
        bn = _bass(s, 40) if (half == 0 or len(syms) > 1 or "/" in s) else _fifth(s, 40, 52)
        if bass:
            P.note("cb_pizz", bn - 12 if bn - 12 >= 28 else bn, bar, half, 1.5, 0.2 * vel)
        if accordeon:
            P.note("accordeon_g", bn, bar, half, 1.2, 0.5 * vel)
            for m in P._voicing("accordeon_g", pcs, 55, 67, 3):
                P.note("accordeon_g", m, bar, half + 2, 0.8, 0.36 * vel)
        if orgue:
            for m in P._voicing("orgue_plein", pcs, 60, 72, 3):
                P.note("orgue_plein", m, bar, half + 2, 0.7, 0.28 * vel)
    if tamb:
        P.hit("tambourin", bar, 0, 0.45 * vel, 1.0)
        P.hit("tambourin", bar, 3, 0.36 * vel, 1.0)
        for k in (1, 2, 4, 5):
            P.hit("secoue", bar, k, (0.4 if k in (2, 5) else 0.26) * vel, 0.5)


def fete_lanternes():
    P = Morceau70("fete_lanternes", 288, 96, beats=6, seed=705, room=2.6)
    intro = ["G", "G", "G", "G", "G", "C", "D", "D7"]
    A = ["G", "G", "C", "D", "G", "Em", "Am", "D", "G", "G", "C", "Am", "G/D", "D7", "G D", "G"]
    B = ["Em", "Em", "C", "D", "Em", "Bm", "C", "D7", "G", "C", "G/B", "Am", "C", "D", "G", "G"]
    Cc = ["Em", "C", "G", "D", "Em", "C", "Am", "D7"]
    melA = ("G4:2 B4:1 D5:2 G5:1 | F#5:1 E5:1 D5:1 B4:2 G4:1 | E5:2 G5:1 E5:2 C5:1 | D5:1 E5:1 F#5:1 A5:2 F#5:1 | "
            "G5:2 D5:1 B4:2 G4:1 | E5:1 F#5:1 G5:1 B5:2 G5:1 | A5:1 G5:1 F#5:1 E5:1 D5:1 C5:1 | B4:2 A4:1 D5:3 | "
            "G4:2 B4:1 D5:2 G5:1 | F#5:1 E5:1 D5:1 B4:2 G4:1 | E5:2 G5:1 E5:2 C5:1 | C6:2 A5:1 E5:2 C5:1 | "
            "B4:1 D5:1 G5:1 B5:2 G5:1 | A5:1 G5:1 F#5:1 E5:1 D5:1 C5:1 | B4:2 G4:1 A4:2 F#4:1 | G4:3 D5:1 E5:1 F#5:1")
    melA_fin = melA.rsplit("|", 1)[0] + "| G4:3 r:3"
    melB = ("B4:1 E5:1 G5:1 B5:2 G5:1 | A5:1 G5:1 F#5:1 E5:3 | E5:1 G5:1 C6:1 B5:1 A5:1 G5:1 | F#5:2 D5:1 A4:3 | "
            "B4:1 E5:1 G5:1 B5:2 E6:1 | D6:1 C#6:1 B5:1 F#5:3 | E5:2 G5:1 A5:2 C6:1 | B5:1 A5:1 G5:1 F#5:1 E5:1 D5:1 | "
            "D5:2 G5:1 B5:2 G5:1 | C6:1 B5:1 A5:1 G5:1 E5:1 C5:1 | D5:2 G5:1 B5:2 D6:1 | C6:1 B5:1 A5:1 E5:3 | "
            "E5:1 G5:1 C6:1 E6:2 C6:1 | D6:1 C6:1 B5:1 A5:1 F#5:1 D5:1 | G5:2 D5:1 B4:2 D5:1 | G5:3 r:3")
    melC = ("E5:2 B4:1 G4:2 B4:1 | C5:2 E5:1 G5:2 E5:1 | D5:2 B4:1 G4:2 B4:1 | A4:2 D5:1 F#5:2 A5:1 | "
            "G5:2 E5:1 B4:2 E5:1 | E5:2 C5:1 G4:2 C5:1 | A4:1 C5:1 E5:1 A5:2 E5:1 | F#5:1 E5:1 D5:1 C5:1 B4:1 A4:1")
    appel = "G5:2 F#5:1 E5:2 D5:1 | E5:2 C5:1 G4:3 | A4:2 B4:1 C5:2 D5:1 | F#5:3 r:3"
    # --- 0-7 : le tambourin seul, puis l'orgue, l'accordéon, la contrebasse ; l'appel des anches
    for b in range(2):
        P.hit("tambourin", b, 0, 0.45, 1.0)
        P.hit("tambourin", b, 3, 0.38, 1.0)
        for k in (1, 2, 4, 5):
            P.hit("secoue", b, k, 0.32, 0.5)
        P.hit("stomp", b, 0, 0.45, 1.0)
        P.hit("stomp", b, 3, 0.35, 1.0)
    for i, s in enumerate(intro[2:]):
        gigue_bar(P, 2 + i, s, 0.85, accordeon=i >= 2)
    mel(P, "musette", 4, appel, vel=0.5, legato=0.02)
    P.hit("triangle", 4, 0, 0.14)
    # --- A (8-23) : le violoneux mène la danse
    cm68.fiddle(P, 8, melA, vel=0.56, bite=0.4)
    for i, s in enumerate(A):
        gigue_bar(P, 8 + i, s, 1.0, orgue=i % 4 != 3)
    P.hit("triangle", 8, 0, 0.16)
    # --- B (24-39) : mi mineur ; les anches musette chantent, le violon les double à l'octave basse
    mel(P, "musette", 24, melB, vel=0.7, legato=0.02)
    cm68.fiddle(P, 24, melB, vel=0.22, bite=0.3, octave=-1)
    for i, s in enumerate(B):
        gigue_bar(P, 24 + i, s, 0.95, accordeon=False)
    P.pad("orgue_flute", B, 24, 55, 67, 2, vel=0.14)
    # --- C (40-47) : le couplet de l'orgue, les claquements de mains
    mel(P, "orgue_plein", 40, melC, vel=0.5, legato=0.02)
    for i, s in enumerate(Cc):
        gigue_bar(P, 40 + i, s, 0.9, orgue=False)
        P.hit("claque", 40 + i, 3, 0.5, 0.5)
        if i % 2 == 1:
            P.hit("claque", 40 + i, 5, 0.32, 0.5)
    P.pad("musette", Cc, 40, 60, 72, 2, vel=0.22)
    # --- A' (48-63) : les lanternes s'envolent ; la flûte et le piccolo, le glockenspiel
    cm68.fiddle(P, 48, melA, vel=0.56, bite=0.4)
    mel(P, "flute", 48, melA, vel=0.3, octave=1, legato=0.02)
    mel(P, "picc", 56, "|".join(melA.split("|")[8:]), vel=0.14, octave=1, legato=0.02)
    P.sparkle("glock", A, 48, 79, 96, prob=0.3, vel=0.18, step=3.0)
    for i, s in enumerate(A):
        gigue_bar(P, 48 + i, s, 1.0)
    P.hit("triangle", 48, 0, 0.16)
    # --- B' (64-79) : tout le monde sur l'épisode en mi mineur
    mel(P, "musette", 64, melB, vel=0.72, legato=0.02)
    cm68.fiddle(P, 64, melB, vel=0.36, bite=0.35)
    for i, s in enumerate(B):
        gigue_bar(P, 64 + i, s, 1.0)
        P.hit("claque", 64 + i, 3, 0.36, 0.5)
    # --- A'' (80-95) : le violoneux et les anches ensemble, et la boucle recommence
    cm68.fiddle(P, 80, melA_fin, vel=0.58, bite=0.4)
    mel(P, "musette", 80, melA_fin, vel=0.4, octave=-1, legato=0.02)
    mel(P, "flute", 88, "|".join(melA_fin.split("|")[8:]), vel=0.26, octave=1, legato=0.02)
    for i, s in enumerate(A):
        gigue_bar(P, 80 + i, s, 1.05 if i < 15 else 0.85)
        P.hit("stomp", 80 + i, 0, 0.3, 1.0)
    P.hit("triangle", 80, 0, 0.16)
    P.hit("crash", 80, 0, 0.16)
    return P


PIECES = {"pandemonia": (pandemonia, -21.0), "braise": (braise, -21.5), "neuf_cercles": (neuf_cercles, -22.0),
          "arene": (arene, -21.0), "fete_lanternes": (fete_lanternes, -21.0)}


def main():
    global VCSL
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        sys.exit(1)
    cm.VSCO = Path(args.pop(0))
    VCSL = cm.VSCO.parent / "VCSL"
    if args and args[0] == "--vcsl":
        args.pop(0)
        VCSL = Path(args.pop(0))
    cm.TMP = Path(tempfile.gettempdir()) / "musique_v70"
    cm.TMP.mkdir(parents=True, exist_ok=True)
    register()
    for name in args or list(PIECES):
        fn, rms = PIECES[name]
        P = fn()
        P.render(cm.OUT / f"{name}.ogg", rms_db=rms)
        del P
        gc.collect()


if __name__ == "__main__":
    main()
