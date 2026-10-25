"""V71 : les musiques de l'Île de Montjoie, la ville des aventuriers, et du Donjon des Mille Marches.

Compositions originales pour Île Manga, versées au domaine public (CC0 1.0), jouées avec les outils
de la V51 (compose_musique_v51.py, orchestre_v51.py) par l'orchestre VSCO-2 CE (Versilian Studios,
CC0) et les instruments de la « Versilian Community Sample Library » (VCSL, Versilian Studios, CC0)
déjà employés en V70 (clavecin, harmonica « musette », verres frottés, tambourin, claquements de
mains, tambour sur cadre, tom, caisse claire, grosse caisse). Sont synthétisés ici :
  - le luth du barde : deux cordes pincées par chœur (cordes de Karplus-Strong de
    compose_musique_v56.Guitar, accordées à l'unisson, un rien désaccordées), pincées près du
    chevalet, un timbre un peu nasal ;
  - la « basse gluante » du Roi Gélatineux : une basse ronde qui fait « boïng » à chaque note (la
    hauteur qui plonge dans la note, le filtre qui s'ouvre et se referme, la gelée qui tremblote).
Le chœur est celui de la V70, l'accordéon celui de la V56, le violoneux celui de la V68.

« Montjoie » (montjoie.ogg), le thème de la ville : ré majeur, 128 à la noire, en boucle (64 mesures,
2 min). Le tambourin et le tambour sur cadre, le luth gratté, le clavecin qui arpège ; la flûte (jouée
sans vibrato, comme une flûte à bec) chante l'air, le violon la rejoint ; un épisode en si mineur où
le violoneux mène, la flûte en contre-chant, le glockenspiel ; un pont en sol majeur (le hautbois, la
clarinette, le basson qui fait « poum-pa ») ; l'air repris par tout le monde (les cors, la cymbale) ;
la cadence qui ramène au début.

« La Gigue de la Guilde » (guilde.ogg), la taverne de la Guilde : une gigue en 6/8 en la majeur, 96 à
la noire pointée (les croches un peu balancées), en boucle (96 mesures, 2 min). Le tambourin seul,
puis l'accordéon et la contrebasse (« poum-tchak ») ; le violoneux mène la danse, les anches musette
le rejoignent, le luth gratte ; un épisode en fa dièse mineur (la musette, les claquements de mains) ;
tout le monde, avec la flûte à l'octave ; la fin, et la boucle repart.

« Les Champs de Montjoie » (campagne.ogg), dehors : fa majeur, 3/4, 90 à la noire, en boucle
(60 mesures, 2 min). La harpe, les cordes douces et l'appel du cor ; la flûte chante l'air pastoral ;
le hautbois et la clarinette partent à l'aventure (ré mineur, les violoncelles en contre-chant, les
cors qui enflent, les pizzicati qui marchent) ; les violons reprennent l'air, la flûte en
contre-chant ; le cor rappelle l'appel du début.

« Le Donjon des Mille Marches » (donjon_mille_marches.ogg) : ré mineur, 100 à la noire, en boucle
(50 mesures, 2 min). Les pizzicati qui marchent sur la pointe des pieds, le marimba qui tourne en
rond, la clarinette qui se faufile ; un moment de mystère (les verres frottés, les trémolos tout en
haut, la harpe, la flûte) ; le basson staccato et le xylophone reprennent l'air en faisant les
malins, les claves ; la fin qui revient sur la pointe des pieds.

« Le Roi Gélatineux » (roi_gelatineux.ogg), le combat contre le boss : sol mineur, 160 à la noire, en
boucle (80 mesures, 2 min). Les tambours et les cuivres, la basse gluante qui rebondit ; le thème
héroïque des cors et des trompettes, les cordes en spiccato ; un épisode bouffon en si bémol (le
xylophone et le basson qui se répondent, les trombones qui ponctuent) ; une pause des tambours (toms,
claquements de mains, timbales, le chœur qui lance des « Oh ! ») où la basse gluante fait son solo ;
le thème en tutti ; l'épisode bouffon en tutti ; la grande fanfare finale, et la boucle repart.

Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/compose_musique_v71.py <dossier VSCO-2-CE> [--vcsl <dossier VCSL>] [morceaux...]
(sans --vcsl, la VCSL est cherchée à côté de VSCO-2-CE ; morceaux : montjoie, guilde, campagne,
donjon_mille_marches, roi_gelatineux)
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
import compose_musique_v70 as cm70  # noqa: E402

SR = orch.SR
mel, drone = cm69.mel, cm69.drone
_bass, _fifth = cm70._bass, cm70._fifth

# ------------------------------------------------------------------ pupitres de VSCO-2 CE en plus
EXTRA = {
    "flute_stac": ("Woodwinds/Flute/stac/*.wav", dict(sustain=False, attack=0.002, release=0.15, pan=-0.15, width=0.4, gain=0.7)),
    "trp_stac": ("Brass/Trumpet/stac/*.wav", dict(sustain=False, attack=0.002, release=0.15, pan=0.1, width=0.4, gain=0.6)),
    "tuba_stac": ("Brass/Tuba/stac/*.wav", dict(sustain=False, attack=0.002, release=0.2, pan=0.45, width=0.4, gain=0.7)),
    "clar_stac": ("Woodwinds/Clarinet/stac/*.wav", dict(sustain=False, attack=0.002, release=0.15, pan=0.2, width=0.4, gain=0.7)),
    "oboe_stac": ("Woodwinds/Oboe/Stacc/*.wav", dict(sustain=False, attack=0.002, release=0.15, pan=0.05, width=0.4, gain=0.65)),
    "solo_pizz": ("Strings/Solo Violin/Pizz/*.wav", dict(sustain=False, attack=0.002, release=0.3, pan=-0.25, width=0.4, gain=0.7)),
    "xylo": ("Percussion/Xylo/*.wav", dict(sustain=False, attack=0.001, release=0.6, pan=0.15, width=0.4, gain=0.9)),
    # les cordes douces des champs (plus discrètes que vln_pad et vla_pad de la V68)
    "vln_doux": ("Strings/Violin Section/susVib/*.wav", dict(attack=0.2, release=0.9, pan=-0.45, width=0.7, gain=0.17)),
    "vla_doux": ("Strings/Viola Section/susvib/*.wav", dict(attack=0.2, release=0.9, pan=0.15, width=0.6, gain=0.2)),
    "vc_doux": ("Strings/Cello Section/susvib/*.wav", dict(attack=0.12, release=0.9, pan=0.4, width=0.6, gain=0.45)),
    "cb_doux": ("Strings/Solo Contrabass/SusVib/*.wav", dict(attack=0.2, release=0.9, pan=0.6, width=0.3, gain=0.55)),
    "claves": ("Percussion/Claves1_Hit_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=0.3, pan=0.35, width=0.3, gain=0.3)),
}
EXTRA_WET = {"flute_stac": 0.45, "trp_stac": 0.4, "tuba_stac": 0.3, "clar_stac": 0.45, "oboe_stac": 0.45, "solo_pizz": 0.45,
             "claves": 0.45, "vln_doux": 0.55, "vla_doux": 0.55, "cb_doux": 0.4, "vc_doux": 0.45, "luth": 0.3, "luth_b": 0.25, "basse_gluante": 0.15, "marimba": 0.45, "xylo": 0.4}


class Luth:
    """Le luth : chaque note est un chœur de deux cordes pincées (Karplus-Strong, comme la guitare de
    la V56), un rien désaccordées l'une de l'autre, pincées près du chevalet ; la caisse plus petite
    que celle d'une guitare : moins de graves, un timbre un peu nasal."""

    def __init__(self, name: str, pan: float = -0.2, width: float = 0.5, gain: float = 1.0, bright: float = 0.9):
        self.name = name
        self.pan = pan
        self.width = width
        self.gain = gain
        self.lag = 0.0
        self.a = cm56.Guitar(name + "_a", pan=pan, width=width, gain=gain, decay=0.9935, bright=bright)
        self.b = cm56.Guitar(name + "_b", pan=pan, width=width, gain=gain, decay=0.993, bright=bright * 0.9)
        self.hp = signal.butter(2, 150.0, btype="highpass", fs=SR, output="sos")
        self.nas = signal.butter(2, [900.0, 1900.0], btype="bandpass", fs=SR, output="sos")

    def note(self, midi: float, dur: float, vel: float = 0.6, attack=None, release=None, legato: bool = False) -> np.ndarray:
        a = np.asarray(self.a.note(midi + 0.03, dur, vel), np.float64)
        b = np.asarray(self.b.note(midi - 0.03, dur, vel * 0.85), np.float64)
        d = int(0.004 * SR)
        n = max(len(a), len(b) + d)
        y = np.zeros((n, 2))
        y[: len(a)] += a
        y[d:d + len(b)] += b
        y = signal.sosfilt(self.hp, y, axis=0) + signal.sosfilt(self.nas, y, axis=0) * 0.8
        return (y * 0.6).astype(np.float32)


class BasseGluante:
    """La basse du Roi Gélatineux : une note ronde et saturée qui fait « boïng » (la hauteur plonge
    dans la note), son filtre s'ouvre à l'attaque et se referme, et la gelée tremblote (le timbre qui
    ondule)."""

    def __init__(self, name: str, pan: float = 0.0, width: float = 0.3, gain: float = 1.0, wob: float = 7.0):
        self.name = name
        self.pan = pan
        self.width = width
        self.gain = gain
        self.wob = wob
        self.lag = 0.0
        self.lo = signal.butter(2, 320.0, btype="lowpass", fs=SR, output="sos")
        self.hi = signal.butter(2, 2200.0, btype="lowpass", fs=SR, output="sos")

    def note(self, midi: float, dur: float, vel: float = 0.6, attack=None, release=None, legato: bool = False) -> np.ndarray:
        f0 = 440.0 * 2 ** ((midi - 69) / 12.0)
        rel = 0.06
        m = int((dur + rel) * SR)
        x = np.arange(m) / SR
        f = f0 * (1 + 0.32 * np.exp(-x / 0.035)) * (1 + 0.012 * np.sin(2 * np.pi * 5.0 * x))
        ph = 2 * np.pi * np.cumsum(f) / SR
        y = np.tanh(2.2 * np.sin(ph)) + 0.35 * np.sin(2 * ph) + 0.15 * np.sin(3 * ph)
        lo = signal.sosfilt(self.lo, y)
        hi = signal.sosfilt(self.hi, y)
        br = np.clip(np.exp(-x / 0.09) * (0.5 + 0.5 * vel) + 0.22 * (0.5 + 0.5 * np.sin(2 * np.pi * self.wob * x - np.pi / 2)) * np.clip(x / 0.15, 0, 1), 0, 1)
        z = lo * (1 - br) + hi * br
        env = np.clip(x / 0.004, 0, 1) * np.clip((dur + rel - x) / rel, 0, 1) * (0.75 + 0.25 * np.exp(-x / 0.3))
        z = z * env * vel * 0.16
        return np.stack([z, z * 0.98], axis=1).astype(np.float32)


SYNTH = {
    "luth": lambda: Luth("luth", pan=-0.3, width=0.5, gain=1.0),
    "luth_b": lambda: Luth("luth_b", pan=0.3, width=0.5, gain=0.8, bright=0.75),
    "basse_gluante": lambda: BasseGluante("basse_gluante", pan=0.0, width=0.3, gain=1.0),
}


def instrument(key: str):
    if key in SYNTH:
        return SYNTH[key]()
    return cm70.instrument(key)


class Morceau71(cm70.Morceau70):
    """La partition de la V70, avec en plus le luth et la basse gluante."""

    def play(self) -> None:
        for key in list(self._todo):
            ins = instrument(key)
            for midi, t, jit, dur, vel, kw in self._todo.pop(key):
                at = max(0.0, t - (0.0 if kw.get("legato") else ins.lag) + jit)
                self.mix.add(key, ins.note(midi, dur, vel, **kw), at, ins.pan, ins.width, ins.gain)
            cm._cache.pop(key, None)
            del ins
            gc.collect()


class Gigue71(Morceau71):
    """Une gigue : dans chaque groupe de trois croches, la deuxième et la troisième arrivent un rien
    en retard (le « balancé » des violoneux, comme la gigue de la V68)."""

    def t(self, bar: float, beat: float = 0.0) -> float:
        pos = beat % 3.0
        lilt = float(np.interp(pos, [0.0, 1.0, 2.0, 3.0], [0.0, 0.07, 0.03, 0.0]))
        return (bar * self.beats + beat + lilt) * self.spb


def register() -> None:
    cm70.register()
    cm.INSTR.update(EXTRA)
    cm.WET.update(EXTRA_WET)


def strum(P, key: str, sym: str, bar: float, beat: float, lo: int, hi: int, vel: float, beats: float, n: int = 4,
          down: bool = True) -> None:
    """Un accord gratté sur le luth : les cordes l'une après l'autre (14 ms d'écart)."""
    _, pcs, _ = cm.chord(sym)
    vs = P._voicing(key, pcs, lo, hi, n)
    order = vs if down else vs[::-1]
    for j, m in enumerate(order):
        P.note(key, m, bar, beat + j * 0.014 / P.spb, beats, vel * (1.0 if j == 0 else 0.85))


# =========================================================================== Montjoie

def bounce_bar(P, bar: int, cell: str, vel: float = 1.0, clav: bool = True, luth: bool = True, perc: bool = True,
               bass: bool = True) -> None:
    """La mesure qui rebondit : la basse en pizzicato sur 1 et 3 (fondamentale puis quinte), le
    clavecin sur 2 et 4, le luth qui gratte sur chaque temps, le tambourin et le tambour sur cadre."""
    syms = cell.split()
    for half in range(2):
        s = syms[min(len(syms) - 1, half)]
        b0 = half * 2
        if bass:
            root = _bass(s, 38) if (half == 0 or len(syms) > 1 or "/" in s) else _fifth(s, 38, 50)
            P.note("cb_pizz", root - 12 if root - 12 >= 28 else root, bar, b0, 1.0, 0.36 * vel)
            P.note("vc_pizz", root, bar, b0, 1.0, 0.3 * vel)
        if clav:
            _, pcs, _ = cm.chord(s)
            for mm in P._voicing("clavecin", pcs, 62, 74, 3):
                P.note("clavecin", mm, bar, b0 + 1, 0.5, 0.3 * vel)
        if luth:
            strum(P, "luth", s, bar, b0, 50, 64, 0.34 * vel, 0.9, 4, True)
            strum(P, "luth", s, bar, b0 + 1, 55, 67, 0.22 * vel, 0.5, 3, False)
            strum(P, "luth", s, bar, b0 + 1.5, 55, 67, 0.18 * vel, 0.4, 3, True)
    if perc:
        P.hit("cadre", bar, 0, 0.34 * vel, 1.0)
        P.hit("cadre", bar, 1.5, 0.2 * vel, 1.0)
        P.hit("cadre", bar, 2, 0.28 * vel, 1.0)
        P.hit("tambourin", bar, 1, 0.3 * vel, 1.0)
        P.hit("tambourin", bar, 3, 0.34 * vel, 1.0)
        for k in (0.5, 1.5, 2.5, 3.5):
            P.hit("secoue", bar, k, 0.2 * vel, 0.5)


def montjoie():
    P = Morceau71("montjoie", 128, 64, beats=4, seed=711, room=2.4)
    intro = ["D", "G", "A", "D"]
    A = ["D", "G D", "Em A", "A", "D", "D", "Em A7", "D", "D", "G D", "Em A", "A", "G", "D", "Em A7", "D"]
    B = ["Bm", "G", "D", "A", "Bm", "G", "Em", "F#", "G", "A", "F#m", "Bm", "G", "A", "D", "A7"]
    C = ["G", "C", "G", "D", "Em", "C", "Am", "D7"]
    coda = ["G", "A", "D", "A7"]
    melA = ("D5:1 F#5:0.5 A5:0.5 B5:1 A5:1 | G5:0.5 F#5:0.5 E5:0.5 F#5:0.5 D5:2 | E5:1 F#5:0.5 G5:0.5 A5:1 F#5:1 | "
            "E5:1.5 D5:0.5 C#5:1 A4:1 | D5:1 F#5:0.5 A5:0.5 D6:1 C#6:0.5 B5:0.5 | A5:1 F#5:0.5 G5:0.5 A5:2 | "
            "B5:0.5 A5:0.5 G5:0.5 F#5:0.5 E5:1 G5:1 | F#5:1 E5:1 D5:2 | "
            "D5:1 F#5:0.5 A5:0.5 B5:1 A5:1 | G5:0.5 F#5:0.5 E5:0.5 F#5:0.5 D5:2 | E5:1 F#5:0.5 G5:0.5 A5:1 B5:1 | "
            "C#6:1.5 B5:0.5 A5:2 | B5:1 G5:0.5 B5:0.5 D6:1 B5:1 | A5:1 F#5:0.5 A5:0.5 D6:2 | "
            "G5:0.5 F#5:0.5 E5:0.5 D5:0.5 E5:1 C#5:1 | D5:3 r:1")
    melB = ("F#5:1.5 E5:0.5 D5:1 F#5:1 | G5:1.5 F#5:0.5 E5:1 D5:1 | F#5:1 A5:1 D6:1 A5:1 | C#6:1.5 B5:0.5 A5:2 | "
            "B5:1 A5:0.5 G5:0.5 F#5:1 B4:1 | G5:1 F#5:0.5 E5:0.5 D5:1 B4:1 | E5:1 G5:1 B5:1 G5:1 | A#5:1.5 C#6:0.5 F#5:2 | "
            "G5:1 B5:1 D6:1 B5:1 | A5:1 C#6:1 E6:1 C#6:1 | F#5:1 A5:0.5 G#5:0.5 F#5:1 C#5:1 | D5:1 F#5:1 B5:2 | "
            "B5:1 G5:0.5 A5:0.5 B5:1 D6:1 | C#6:1 B5:0.5 C#6:0.5 E6:2 | D6:1 A5:0.5 F#5:0.5 D5:1 F#5:1 | E5:1 G5:1 A5:1 C#5:1")
    contreB = ("D5:4 | D5:2 B4:2 | A4:4 | E5:2 C#5:2 | D5:4 | B4:4 | B4:2 E5:2 | C#5:4 | "
               "D5:4 | E5:4 | C#5:4 | D5:2 F#5:2 | D5:4 | E5:2 A5:2 | F#5:4 | G5:2 E5:2")
    melC = ("D5:1 G5:1 B5:1.5 A5:0.5 | G5:1 E5:1 C5:2 | B4:1 D5:1 G5:1 B5:1 | A5:3 r:1 | "
            "G5:1 E5:1 B4:1.5 C5:0.5 | E5:1 G5:1 C6:2 | A5:1 C6:0.5 B5:0.5 A5:1 E5:1 | F#5:1 A5:1 C6:1 A5:1")
    melCoda = "B5:1 A5:1 G5:1 E5:1 | C#5:1 E5:1 A5:2 | D5:1 F#5:1 A5:1 D6:1 | C#6:1 A5:1 E5:1 C#5:1"
    # --- 0-3 : les tambours, le luth, le clavecin qui arpège
    for i, s in enumerate(intro):
        bounce_bar(P, i, s, 0.85, clav=False, bass=i >= 2)
    P.arp("clavecin", intro, 0, 62, step=0.5, pattern=[0, 2, 4, 2, 1, 3, 4, 3], vel=0.24, ring=0.6, span=2)
    P.hit("triangle", 0, 0, 0.14)
    # --- A (4-19) : la flûte (sans vibrato : une flûte à bec) chante l'air ; le violon la rejoint
    mel(P, "flute_nv", 4, melA, vel=0.62, legato=0.02)
    mel(P, "solo_vln", 12, "|".join(melA.split("|")[8:]), vel=0.3, octave=-1, legato=0.03)
    for i, s in enumerate(A):
        bounce_bar(P, 4 + i, s, 1.0)
    P.hit("triangle", 4, 0, 0.16)
    P.hit("triangle", 12, 0, 0.14)
    # --- B (20-35) : si mineur ; le violoneux mène, la flûte en contre-chant, le glockenspiel
    cm68.fiddle(P, 20, melB, vel=0.56, bite=0.35)
    mel(P, "flute_nv", 20, contreB, vel=0.3, legato=0.03)
    for i, s in enumerate(B):
        bounce_bar(P, 20 + i, s, 0.95, clav=i % 2 == 0)
    P.pad("vla_pad", B, 20, 57, 69, 2, vel=0.12)
    P.sparkle("glock", B, 20, 81, 93, prob=0.2, vel=0.16, step=2.0)
    # --- C (36-43) : le pont en sol majeur ; le hautbois, la clarinette, le basson « poum-pa »
    mel(P, "oboe", 36, melC, vel=0.6, legato=0.03)
    mel(P, "clar", 36, melC, vel=0.18, octave=-1, legato=0.03)
    for i, s in enumerate(C):
        r = _bass(s, 36)
        P.note("bsn_stac", r, 36 + i, 0, 0.6, 0.45)
        P.note("bsn_stac", r + 7 if r + 7 <= 50 else r - 5, 36 + i, 2, 0.6, 0.38)
        bounce_bar(P, 36 + i, s, 0.7, bass=False, luth=i % 2 == 0)
    P.arp("harp", C, 36, 55, step=1.0, pattern=[0, 2, 4, 2], vel=0.2, span=2)
    P.pad("vln_pad", C, 36, 67, 79, 2, vel=0.1)
    # --- A' (44-59) : tout le monde
    P.hit("crash", 44, 0, 0.18)
    mel(P, "flute_nv", 44, melA, vel=0.58, legato=0.02)
    cm68.fiddle(P, 44, melA, vel=0.42, bite=0.3)
    mel(P, "picc", 52, "|".join(melA.split("|")[8:]), vel=0.12, legato=0.02)
    P.pad("horn_pad", A, 44, 53, 65, 2, vel=0.16)
    for i, s in enumerate(A):
        bounce_bar(P, 44 + i, s, 1.05)
    P.sparkle("glock", A, 44, 81, 93, prob=0.15, vel=0.14, step=2.0)
    P.hit("triangle", 52, 0, 0.16)
    # --- 60-63 : la cadence (sol, la, ré, la7), la boucle repart
    mel(P, "flute_nv", 60, melCoda, vel=0.55, legato=0.02)
    mel(P, "solo_vln", 60, melCoda, vel=0.3, octave=-1, legato=0.03)
    for i, s in enumerate(coda):
        bounce_bar(P, 60 + i, s, 0.95)
    P.hit("timp_roll", 63, 0, 0.16, 4.0, midi=45)
    return P


# =========================================================================== La Gigue de la Guilde

def gigue_bar(P, bar: int, cell: str, vel: float = 1.0, accordeon: bool = True, tamb: bool = True, bass: bool = True,
              luth: bool = False) -> None:
    """« Poum-tchak, poum-tchak » en 6/8 : la basse sur la première et la quatrième croche, l'accord
    (l'accordéon, ou le luth) sur la troisième et la sixième ; le tambourin."""
    syms = cell.split()
    for half, s in ((0, syms[0]), (3, syms[-1])):
        _, pcs, _ = cm.chord(s)
        bn = _bass(s, 40) if (half == 0 or len(syms) > 1 or "/" in s) else _fifth(s, 40, 52)
        if bass:
            P.note("cb_pizz", bn - 12 if bn - 12 >= 28 else bn, bar, half, 1.5, 0.17 * vel)
        if accordeon:
            P.note("accordeon_g", bn, bar, half, 1.2, 0.48 * vel)
            for mm in P._voicing("accordeon_g", pcs, 55, 67, 3):
                P.note("accordeon_g", mm, bar, half + 2, 0.8, 0.34 * vel)
        if luth:
            strum(P, "luth", s, bar, half, 52, 66, 0.3 * vel, 1.4, 4, True)
            strum(P, "luth", s, bar, half + 2, 55, 67, 0.2 * vel, 0.8, 3, False)
    if tamb:
        P.hit("tambourin", bar, 0, 0.42 * vel, 1.0)
        P.hit("tambourin", bar, 3, 0.34 * vel, 1.0)
        for k in (1, 2, 4, 5):
            P.hit("secoue", bar, k, (0.36 if k in (2, 5) else 0.24) * vel, 0.5)


def guilde():
    P = Gigue71("guilde", 288, 96, beats=6, seed=712, room=1.8)
    intro = ["A", "A", "A", "E"]
    A1 = ["A", "D", "E", "E", "A", "D", "E", "A"]
    A2 = ["A", "D", "E", "A", "D", "F#m", "E", "A"]
    A = A1 + A2
    B = ["F#m", "E", "D", "C#", "F#m", "Bm", "E", "F#m", "F#m", "E", "D", "C#", "D", "E", "D E", "E"]
    fin = ["D", "E", "A", "E"]
    melA1 = ("A4:1 C#5:1 E5:1 A5:2 E5:1 | F#5:1 E5:1 D5:1 C#5:2 A4:1 | B4:1 C#5:1 D5:1 E5:2 G#5:1 | A5:1 G#5:1 F#5:1 E5:3 | "
             "A4:1 C#5:1 E5:1 A5:2 C#6:1 | B5:1 A5:1 G#5:1 F#5:2 D5:1 | C#5:1 E5:1 A5:1 G#5:1 E5:1 B4:1 | A4:3 A4:2 E5:1")
    melA2 = ("C#6:1 B5:1 A5:1 E5:2 C#5:1 | D5:1 F#5:1 A5:1 D6:2 A5:1 | B5:1 G#5:1 E5:1 B4:2 E5:1 | C#5:1 E5:1 A5:1 C#6:3 | "
             "D6:1 C#6:1 B5:1 A5:1 F#5:1 D5:1 | C#5:1 E5:1 A5:1 F#5:2 D5:1 | B4:1 D5:1 G#5:1 B5:1 G#5:1 E5:1 | A5:3 A4:2 E5:1")
    melA = melA1 + " | " + melA2
    melB = ("F#5:2 C#5:1 F#5:2 A5:1 | G#5:1 F#5:1 E5:1 C#5:3 | D5:2 F#5:1 A5:2 F#5:1 | E5:1 F#5:1 G#5:1 C#5:3 | "
            "F#5:2 C#5:1 F#5:2 A5:1 | B5:1 A5:1 G#5:1 A5:2 F#5:1 | E5:1 G#5:1 B5:1 C#6:1 B5:1 G#5:1 | F#5:3 r:3 | "
            "A5:2 F#5:1 C#6:2 A5:1 | B5:1 A5:1 G#5:1 E5:3 | F#5:1 A5:1 D6:1 C#6:1 B5:1 A5:1 | G#5:2 E#5:1 C#5:3 | "
            "F#5:1 G#5:1 A5:1 B5:1 C#6:1 D6:1 | E6:2 D6:1 C#6:2 B5:1 | A5:1 G#5:1 F#5:1 E5:1 D5:1 C#5:1 | B4:2 C#5:1 E5:3")
    melFin = "D6:2 C#6:1 B5:2 A5:1 | G#5:1 B5:1 E6:1 B5:3 | A5:1 C#6:1 E6:1 A5:2 E5:1 | E5:3 G#4:3"
    appel = "E5:2 C#5:1 A4:2 C#5:1 | E5:3 G#5:3"
    # --- 0-3 : le tambourin seul, puis l'accordéon et la contrebasse ; l'appel des anches
    for b in range(2):
        P.hit("tambourin", b, 0, 0.45, 1.0)
        P.hit("tambourin", b, 3, 0.36, 1.0)
        for k in (1, 2, 4, 5):
            P.hit("secoue", b, k, 0.3, 0.5)
        P.hit("stomp", b, 0, 0.42, 1.0)
        P.hit("stomp", b, 3, 0.32, 1.0)
    for i, s in enumerate(intro[2:]):
        gigue_bar(P, 2 + i, s, 0.85)
    mel(P, "musette", 2, appel, vel=0.5, legato=0.02)
    # --- A (4-19) : le violoneux mène la danse, le luth gratte
    cm68.fiddle(P, 4, melA, vel=0.56, bite=0.4)
    for i, s in enumerate(A):
        gigue_bar(P, 4 + i, s, 1.0, luth=i % 2 == 1)
    P.hit("triangle", 4, 0, 0.16)
    # --- A (20-35) : les anches musette le rejoignent, le luth et les claquements de mains
    mel(P, "musette", 20, melA, vel=0.62, legato=0.02)
    cm68.fiddle(P, 20, melA, vel=0.4, bite=0.35, octave=-1)
    for i, s in enumerate(A):
        gigue_bar(P, 20 + i, s, 1.0, accordeon=i % 4 != 3, luth=True)
        P.hit("claque", 20 + i, 3, 0.36, 0.5)
    # --- B (36-51) : fa dièse mineur ; la musette chante, le violon en dessous, les mains
    mel(P, "musette", 36, melB, vel=0.68, legato=0.02)
    cm68.fiddle(P, 36, melB, vel=0.22, bite=0.3, octave=-1)
    for i, s in enumerate(B):
        gigue_bar(P, 36 + i, s, 0.95, accordeon=False, luth=True)
        P.hit("claque", 36 + i, 3, 0.45, 0.5)
        if i % 2 == 1:
            P.hit("claque", 36 + i, 5, 0.3, 0.5)
    P.pad("vla_pad", B, 36, 57, 69, 2, vel=0.1)
    # --- A' (52-67) : tout le monde ; la flûte à l'octave, les bottes
    cm68.fiddle(P, 52, melA, vel=0.56, bite=0.4)
    mel(P, "musette", 52, melA, vel=0.36, octave=-1, legato=0.02)
    mel(P, "flute", 60, melA2, vel=0.26, octave=1, legato=0.02)
    for i, s in enumerate(A):
        gigue_bar(P, 52 + i, s, 1.05, luth=True)
        P.hit("stomp", 52 + i, 0, 0.3, 1.0)
    P.hit("crash", 52, 0, 0.14)
    # --- B' (68-83) : l'épisode en mineur, par tout le monde
    cm68.fiddle(P, 68, melB, vel=0.5, bite=0.35)
    mel(P, "musette", 68, melB, vel=0.5, legato=0.02)
    for i, s in enumerate(B):
        gigue_bar(P, 68 + i, s, 1.0, luth=True)
        P.hit("claque", 68 + i, 3, 0.4, 0.5)
    # --- A'' (84-91) puis la fin (92-95) : le violoneux et les anches, et la boucle repart
    cm68.fiddle(P, 84, melA1, vel=0.58, bite=0.4)
    mel(P, "musette", 84, melA1, vel=0.4, octave=-1, legato=0.02)
    for i, s in enumerate(A1):
        gigue_bar(P, 84 + i, s, 1.05, luth=True)
        P.hit("stomp", 84 + i, 0, 0.3, 1.0)
    cm68.fiddle(P, 92, melFin, vel=0.56, bite=0.4)
    mel(P, "flute", 92, melFin, vel=0.2, legato=0.02)
    for i, s in enumerate(fin):
        gigue_bar(P, 92 + i, s, 0.95, luth=True)
    P.hit("triangle", 84, 0, 0.16)
    return P


# =========================================================================== Les Champs de Montjoie

def campagne():
    P = Morceau71("campagne", 90, 60, beats=3, seed=713, room=3.2)
    intro = ["F", "Bb/F", "F", "C"]
    A = ["F", "F", "Gm", "F", "Bb", "Gm", "F/C", "C", "F", "F", "Bb", "F", "Gm", "F/C", "C7", "F"]
    B = ["Dm", "Dm", "Bb", "C", "Dm", "F", "Gm", "A", "Dm", "C7", "F", "Gm6", "Bb", "C", "F/A", "C7"]
    coda = ["F", "Bb", "F", "C", "Dm", "Bb", "C", "F"]
    melA = ("C5:1 F5:1 G5:1 | A5:2 F5:1 | Bb5:1 A5:1 G5:1 | A5:2 F5:1 | D5:1 G5:1 A5:1 | Bb5:2 G5:1 | A5:1 G5:1 F5:1 | G5:3 | "
            "C5:1 F5:1 G5:1 | A5:2 C6:1 | D6:1 C6:1 Bb5:1 | A5:2 F5:1 | G5:1 A5:1 Bb5:1 | C6:2 A5:1 | G5:1.5 A5:0.5 G5:1 | F5:3")
    melB = ("A4:1 D5:1 E5:1 | F5:2 E5:1 | D5:1 F5:1 A5:1 | G5:3 | A4:1 D5:1 E5:1 | F5:1 G5:1 A5:1 | Bb5:2 A5:1 | A5:3 | "
            "D5:1 F5:1 A5:1 | C6:2 Bb5:1 | A5:1 F5:1 C5:1 | D5:2 E5:1 | F5:1 E5:1 D5:1 | E5:1 F5:1 G5:1 | A5:2 Bb5:1 | C6:3")
    contreB = ("D3:3 | F3:2 A3:1 | Bb2:3 | C3:2 E3:1 | D3:3 | A2:2 C3:1 | G2:2 Bb2:1 | A2:2 C#3:1 | "
               "D3:2 F3:1 | E3:2 C3:1 | F3:2 A3:1 | G3:2 E3:1 | D3:3 | C3:2 E3:1 | F3:2 A2:1 | C3:3")
    contreA = ("A4:3 | C5:3 | D5:3 | C5:3 | F4:3 | G4:3 | C5:2 A4:1 | E4:3 | "
               "A4:3 | C5:3 | F5:2 D5:1 | C5:3 | Bb4:3 | A4:3 | Bb4:2 E4:1 | F4:3")
    cor = "C4:1 F4:1 A4:1 | C5:3 | Bb4:1 A4:1 G4:1 | G4:3"
    corCoda = "C4:1 F4:1 A4:1 | Bb4:2 A4:1 | A4:1 G4:1 F4:1 | G4:3 | F4:1 A4:1 D5:1 | D5:2 C5:1 | C5:2 E4:1 | F4:3"
    # --- 0-3 : la harpe, les cordes douces, l'appel du cor
    P.arp("harp", intro, 0, 53, step=0.5, pattern=[0, 2, 4, 5, 4, 2], vel=0.22, ring=2.0, span=2)
    P.pad("vla_doux", intro, 0, 53, 65, 3, vel=0.12)
    P.bass("cb_doux", intro, 0, 29, 41, vel=0.18)
    mel(P, "horn", 0, cor, vel=0.45, legato=0.05)
    # --- A (4-19) : la flûte chante l'air pastoral
    mel(P, "flute", 4, melA, vel=0.7, legato=0.04)
    P.pad("vln_doux", A, 4, 60, 72, 3, vel=0.07)
    P.pad("vla_doux", A, 4, 53, 65, 2, vel=0.07)
    P.bass("cb_doux", A, 4, 29, 41, vel=0.14)
    P.arp("harp", A, 4, 53, step=1.0, pattern=[0, 2, 4], vel=0.18, ring=2.0, span=2)
    mel(P, "clar", 12, "|".join(contreA.split("|")[8:]), vel=0.18, legato=0.05)
    # --- B (20-35) : l'aventure ; le hautbois et la clarinette, les violoncelles, les cors qui enflent
    mel(P, "oboe", 20, melB, vel=0.68, legato=0.04)
    mel(P, "clar", 28, "|".join(melB.split("|")[8:]), vel=0.22, octave=-1, legato=0.04)
    mel(P, "vc_doux", 20, contreB, vel=0.42, legato=0.05)
    P.pad("horn_pad", B, 20, 53, 65, 2, vel=0.14)
    P.pad("vln_doux", B, 20, 62, 74, 2, vel=0.07)
    for i, s in enumerate(B):
        r = _bass(s, 33)
        P.note("cb_pizz", r, 20 + i, 0, 1.0, 0.36)
        P.note("vla_pizz", r + 12 + (7 if i % 2 else 0), 20 + i, 1, 1.0, 0.22)
        P.note("vla_pizz", r + 12, 20 + i, 2, 1.0, 0.2)
    P.hit("timp_roll", 27, 0, 0.16, 3.0, midi=45)
    P.hit("cymbal", 34, 0, 0.14, 6.0)
    # --- A' (36-51) : les violons reprennent l'air, la flûte en contre-chant
    mel(P, "vln", 36, melA, vel=0.5, legato=0.05)
    mel(P, "flute", 36, contreA, vel=0.34, octave=1, legato=0.04)
    P.pad("horn_pad", A, 36, 53, 65, 2, vel=0.12)
    P.pad("vla_doux", A, 36, 53, 65, 2, vel=0.08)
    P.bass("cb_doux", A, 36, 29, 41, vel=0.16)
    P.arp("harp", A, 36, 60, step=0.5, pattern=[0, 1, 2, 3, 2, 1], vel=0.16, ring=1.5, span=2)
    P.sparkle("glock", A, 36, 84, 96, prob=0.12, vel=0.1, step=1.5)
    # --- 52-59 : le cor rappelle l'appel ; tout se calme, la boucle repart
    mel(P, "horn", 52, corCoda, vel=0.48, legato=0.05)
    P.pad("vln_doux", coda, 52, 60, 72, 3, vel=0.1)
    P.pad("vla_doux", coda, 52, 53, 65, 2, vel=0.1)
    P.bass("cb_doux", coda, 52, 29, 41, vel=0.18)
    P.arp("harp", coda, 52, 53, step=1.0, pattern=[0, 2, 4], vel=0.16, ring=2.0, span=2)
    mel(P, "flute", 56, "F5:3 | D5:3 | E5:2 G5:1 | A5:3", vel=0.32, legato=0.04)
    return P


# =========================================================================== Le Donjon des Mille Marches

def tiptoe(P, bar: int, cell: str, vel: float = 1.0, mar: bool = True) -> None:
    """Sur la pointe des pieds : la basse en pizzicato qui marche (fondamentale, quinte, octave,
    quinte), le marimba qui tourne en rond en croches."""
    syms = cell.split()
    s = syms[0]
    r = _bass(s, 38)
    fifth = r + 7
    for b, (m, v) in enumerate(((r, 0.44), (fifth, 0.3), (r + 12, 0.34), (fifth, 0.28))):
        key = "cb_pizz" if b == 0 else "vc_pizz"
        P.note(key, m - (12 if key == "cb_pizz" and m - 12 >= 28 else 0), bar, b, 1.0, v * vel)
    if mar:
        _, pcs, _ = cm.chord(s)
        tones = sorted({m for m in range(62, 62 + 25) if m % 12 in pcs})
        for k, idx in enumerate([0, 2, 1, 2, 0, 2, 1, 3]):
            P.note("marimba", tones[idx % len(tones)], bar, k * 0.5, 0.6, (0.3 if k % 2 == 0 else 0.22) * vel)


def donjon_mille_marches():
    P = Morceau71("donjon_mille_marches", 100, 50, beats=4, seed=714, room=3.4)
    A = ["Dm", "Dm", "Gm", "A7", "Dm", "Dm", "A7", "Dm", "F", "F", "Bb", "A7", "Dm", "Gm6", "A7", "Dm"]
    M = ["Bb", "Bb", "Gm", "Gm", "Eb", "Eb", "A", "A7"]
    coda = ["Dm", "Gm/D", "Dm", "A7/C#", "Dm", "Bb", "A7", "A7"]
    melA = ("D4:0.5 r:0.5 F4:0.5 r:0.5 A4:0.5 G#4:0.5 A4:1 | r:1 D5:0.5 C5:0.5 A4:1 F4:1 | "
            "E4:0.5 r:0.5 G4:0.5 r:0.5 Bb4:0.5 A4:0.5 Bb4:1 | r:1 E5:0.5 D5:0.5 C#5:1 A4:1 | "
            "D4:0.5 r:0.5 F4:0.5 r:0.5 A4:0.5 G#4:0.5 A4:1 | r:1 D5:0.5 E5:0.5 F5:1 D5:1 | "
            "G5:0.5 F5:0.5 E5:0.5 D5:0.5 C#5:1 E5:1 | D5:2 r:2 | "
            "F4:0.5 r:0.5 A4:0.5 r:0.5 C5:0.5 B4:0.5 C5:1 | r:1 F5:0.5 E5:0.5 C5:1 A4:1 | "
            "Bb4:0.5 r:0.5 D5:0.5 r:0.5 F5:0.5 E5:0.5 F5:1 | r:1 G5:0.5 F5:0.5 E5:1 C#5:1 | "
            "D5:0.5 F5:0.5 A5:1 G#5:0.5 A5:0.5 F5:1 | E5:0.5 G5:0.5 Bb5:1 A5:0.5 G5:0.5 E5:1 | "
            "F5:0.5 E5:0.5 D5:0.5 C#5:0.5 D5:0.5 E5:0.5 A4:1 | D5:1 A4:1 D4:1 r:1")
    melM = "D5:4 | F5:2 E5:2 | D5:4 | Bb4:4 | G5:4 | F5:2 Eb5:2 | E5:4 | C#5:2 A4:2"
    melCoda = "A4:2 D5:1 F5:1 | E5:2 D5:1 Bb4:1 | A4:2 D5:1 F5:1 | E5:4 | F5:1 E5:1 D5:1 A4:1 | Bb4:2 D5:2 | C#5:4 | E5:2 A4:2"
    # --- 0-1 : la pointe des pieds toute seule
    tiptoe(P, 0, "Dm", 0.8)
    tiptoe(P, 1, "A7", 0.8)
    P.hit("claves", 1, 3.5, 0.3, 0.5)
    # --- A (2-17) : la clarinette qui se faufile
    mel(P, "clar", 2, melA, vel=0.56, legato=0.02)
    for i, s in enumerate(A):
        tiptoe(P, 2 + i, s, 1.0)
        if i % 4 == 3:
            P.hit("claves", 2 + i, 2.5, 0.28, 0.5)
            P.hit("claves", 2 + i, 3.0, 0.32, 0.5)
    P.pad("vc_drone", A, 2, 38, 50, 2, vel=0.18)
    P.sparkle("glock", A[8:], 10, 86, 98, prob=0.12, vel=0.1, step=2.0)
    # --- M (18-25) : le mystère ; les verres frottés, les trémolos, la harpe, la flûte
    mel(P, "flute_nv", 18, melM, vel=0.42, legato=0.05)
    P.pad("verres", M, 18, 74, 86, 2, vel=0.22)
    P.pad("trem_nuit", M, 18, 69, 81, 2, vel=0.1)
    P.arp("harp", M, 18, 50, step=0.5, pattern=[0, 2, 4, 2], vel=0.14, ring=1.5, span=2)
    for i, s in enumerate(M):
        P.note("cb_pizz", _bass(s, 33), 18 + i, 0, 1.0, 0.34)
        P.note("cb_pizz", _bass(s, 33), 18 + i, 2.5, 1.0, 0.22)
        if i % 2 == 1:
            P.note("bsn_stac", _bass(s, 34), 18 + i, 3, 0.4, 0.32)
    P.hit("bd_rub", 22, 0, 0.22, 4.0)
    P.note("vc_drone", 38, 18, 0, 16.0, 0.16, attack=1.0)
    # --- A' (26-41) : le basson staccato et le xylophone font les malins, les claves
    mel(P, "bsn_stac", 26, melA, vel=0.5, octave=-1, legato=0.0)
    mel(P, "xylo", 26, melA, vel=0.22, octave=1, legato=0.0)
    mel(P, "flute_nv", 34, "|".join(melA.split("|")[8:]), vel=0.26, legato=0.02)
    for i, s in enumerate(A):
        tiptoe(P, 26 + i, s, 1.0, mar=i % 2 == 0)
        P.hit("claves", 26 + i, 1, 0.24, 0.5)
        P.hit("claves", 26 + i, 3, 0.28, 0.5)
    P.pad("vln_pad", A, 26, 62, 74, 2, vel=0.08)
    P.hit("triangle", 34, 0, 0.12)
    # --- 42-49 : la fin, qui revient sur la pointe des pieds
    mel(P, "clar", 42, melCoda, vel=0.46, legato=0.03)
    P.pad("verres", coda[:4], 42, 74, 86, 2, vel=0.16)
    for i, s in enumerate(coda):
        tiptoe(P, 42 + i, s, 0.85, mar=i >= 4)
    P.note("bsn_stac", 26, 49, 3, 0.5, 0.4)
    P.note("glock", 86, 49, 3.5, 1.0, 0.16)
    return P


# =========================================================================== Le Roi Gélatineux

def gluante_bar(P, bar: int, cell: str, vel: float = 1.0, busy: bool = True) -> None:
    """La basse gluante qui rebondit : « boïng… boïng-boïng… boïng »."""
    syms = cell.split()
    each = P.beats / len(syms)
    for j, s in enumerate(syms):
        r = _bass(s, 31)
        pos = [0.0, 1.5, 2.0, 3.0] if busy else [0.0, 2.0]
        for k, p in enumerate(pos):
            if j * each <= p < (j + 1) * each:
                m = r + (12 if (busy and k == 2) else 0)
                P.note("basse_gluante", m, bar, p, 0.7 if busy else 1.5, (0.75 if k == 0 else 0.6) * vel)


def roi_gelatineux():
    P = Morceau71("roi_gelatineux", 160, 80, beats=4, seed=715, room=2.4)
    intro = ["Gm", "Gm", "Eb", "D"]
    A = ["Gm", "Eb", "Cm", "D", "Gm", "Eb F", "Cm", "D", "Gm", "F", "Eb", "Bb", "Cm", "D7", "Gm D", "Gm"]
    B = ["Bb", "F", "Gm", "D", "Eb", "Bb", "C", "F", "Bb", "F", "Gm", "D", "Eb", "F", "Bb", "D7"]
    Cb = ["Gm", "Gm", "Eb", "D", "Gm", "Gm", "Eb", "D"]
    coda = ["Eb", "F", "D", "D", "Eb", "F", "Gm", "Gm", "Cm", "D", "Eb", "D7"]
    melA = ("G4:1 Bb4:0.5 D5:0.5 G5:1.5 F5:0.5 | Eb5:1 D5:1 C5:1 D5:1 | Bb4:1 C5:0.5 D5:0.5 Eb5:1.5 D5:0.5 | D5:3 r:1 | "
            "G4:1 Bb4:0.5 D5:0.5 G5:1.5 A5:0.5 | Bb5:1 A5:1 G5:1 F5:1 | Eb5:1 G5:1 C6:1 Bb5:0.5 A5:0.5 | Bb5:2 A5:2 | "
            "D6:1.5 C6:0.5 Bb5:1 G5:1 | A5:1.5 G5:0.5 F5:1 D5:1 | Eb5:1 G5:1 Bb5:1 Eb6:1 | D6:3 r:1 | "
            "C6:1 Bb5:0.5 A5:0.5 G5:1 Eb5:1 | D5:1 F#5:1 A5:1 C6:1 | Bb5:1 A5:1 G5:1 F#5:1 | G5:3 r:1")
    melB = ("D5:0.5 r:0.5 F5:0.5 r:0.5 Bb5:1 r:1 | C6:0.5 r:0.5 A5:0.5 r:0.5 F5:1 r:1 | Bb5:0.5 A5:0.5 G5:0.5 F5:0.5 G5:1 D5:1 | "
            "F#5:1 A5:1 D6:1 r:1 | Eb5:0.5 r:0.5 G5:0.5 r:0.5 Bb5:1 r:1 | D5:0.5 r:0.5 F5:0.5 r:0.5 Bb5:1 r:1 | "
            "C5:0.5 E5:0.5 G5:0.5 Bb5:0.5 C6:1 Bb5:1 | A5:2 r:2 | "
            "D5:0.5 r:0.5 F5:0.5 r:0.5 Bb5:1 r:1 | C6:0.5 r:0.5 A5:0.5 r:0.5 F5:1 r:1 | Bb5:0.5 A5:0.5 G5:0.5 F5:0.5 G5:1 D5:1 | "
            "F#5:1 A5:1 D6:1 r:1 | Eb5:0.5 r:0.5 G5:0.5 r:0.5 Bb5:1 r:1 | F5:0.5 r:0.5 A5:0.5 r:0.5 C6:1 r:1 | "
            "D6:0.5 C6:0.5 Bb5:0.5 A5:0.5 Bb5:1 F5:1 | F#5:1 A5:1 C6:1 D6:1")
    riff = "G2:1 G2:0.5 Bb2:0.5 C3:1 D3:1 | Eb3:0.5 D3:0.5 C3:0.5 Bb2:0.5 A2:1 D2:1"
    fanfare = ("Eb5:0.5 Eb5:0.5 Eb5:0.5 G5:0.5 Bb5:2 | F5:0.5 F5:0.5 F5:0.5 A5:0.5 C6:2 | D6:2 A5:1 F#5:1 | D5:1 F#5:1 A5:1 D6:1 | "
               "Eb5:0.5 G5:0.5 Bb5:0.5 Eb6:0.5 D6:1 Bb5:1 | F5:0.5 A5:0.5 C6:0.5 F6:0.5 Eb6:1 C6:1 | D6:4 | Bb5:2 G5:2 | "
               "C6:2 Eb6:2 | D6:2 C6:1 A5:1 | G5:1 Bb5:1 Eb6:1 D6:1 | C6:1 A5:1 F#5:1 D5:1")
    # --- 0-3 : les tambours, les accords de cuivres, la basse gluante
    for i, s in enumerate(intro):
        cm70.arene_drums(P, i, 0.9, fill=i == 3)
        gluante_bar(P, i, s, 0.9)
        _, pcs, _ = cm.chord(s)
        for mm in P._voicing("tbn", pcs, 46, 58, 3):
            P.note("tbn", mm, i, 0, 0.5, 0.5)
            P.note("tbn", mm, i, 1.5, 0.4, 0.4)
        P.note("timp", 43 if s.startswith("G") else (39 if s.startswith("E") else 38), i, 0, 1.0, 0.42)
    P.hit("crash", 0, 0, 0.24)
    # --- A (4-19) : le thème héroïque ; cors et trompettes, les cordes en spiccato
    mel(P, "horn", 4, melA, vel=0.6, legato=0.03)
    mel(P, "trp", 4, melA, vel=0.24, legato=0.03)
    cm70.ostinato_arene(P, A, 4, 0.8)
    for i, s in enumerate(A):
        cm70.arene_drums(P, 4 + i, 1.0, fill=i in (7, 15))
        gluante_bar(P, 4 + i, s, 1.0)
        if i % 4 == 0:
            P.hit("crash", 4 + i, 0, 0.18)
        r = _bass(s.split()[0], 34)
        P.note("timp", r if r <= 45 else r - 12, 4 + i, 0, 1.0, 0.36)
    P.pad("horn_pad", A, 4, 55, 67, 2, vel=0.12)
    # --- B (20-35) : l'épisode bouffon ; le xylophone, le basson qui répond, les trombones qui ponctuent
    mel(P, "xylo", 20, melB, vel=0.75, legato=0.0)
    mel(P, "flute_stac", 20, melB, vel=0.42, legato=0.0)
    for i, s in enumerate(B):
        b = 20 + i
        r = _bass(s.split()[0], 34)
        P.note("bsn_stac", r, b, 2, 0.4, 0.42)
        P.note("bsn_stac", r + 12, b, 2.5, 0.4, 0.36)
        P.note("bsn_stac", r + 7, b, 3, 0.4, 0.38)
        _, pcs, _ = cm.chord(s)
        for mm in P._voicing("trp_stac", pcs, 60, 72, 3):
            P.note("trp_stac", mm, b, 3.5, 0.4, 0.34)
        gluante_bar(P, b, s, 0.7, busy=False)
        P.hit("gc", b, 0, 0.42, 1.0)
        P.hit("caisse", b, 1, 0.3, 0.5)
        P.hit("caisse", b, 3, 0.34, 0.5)
        P.hit("tambourin", b, 2, 0.26, 0.5)
    P.pad("vln_pad", B, 20, 65, 77, 2, vel=0.08)
    # --- C (36-43) : la pause des tambours, le chœur qui lance des « Oh ! », le solo de la basse gluante
    for rep in range(4):
        for j, tok in enumerate(riff.split("|")):
            beat = 0.0
            for t in tok.split():
                p, d = t.split(":")
                P.note("basse_gluante", orch.midi_of(p) + 12, 36 + rep * 2 + j, beat, float(d) * 0.85, 0.8)
                beat += float(d)
    for i, s in enumerate(Cb):
        b = 36 + i
        P.hit("gc", b, 0, 0.55, 1.0)
        P.hit("tom", b, 0.75, 0.34, 0.5)
        P.hit("tom", b, 1.5, 0.4, 0.5)
        P.hit("claque", b, 1, 0.5, 0.5)
        P.hit("claque", b, 3, 0.55, 0.5)
        P.hit("gc", b, 2, 0.45, 1.0)
        P.hit("tom_b", b, 2.5, 0.3, 0.5)
        P.hit("tom_b", b, 2.75, 0.26, 0.5)
        r = _bass(s.split()[0], 34)
        P.note("timp", r if r <= 45 else r - 12, b, 0, 1.0, 0.4)
        if i % 2 == 0:
            _, pcs, _ = cm.chord(s)
            for mm in P._voicing("choeur_h", pcs, 50, 64, 3):
                P.note("choeur_h", mm, b, 0, 0.7, 0.55, attack=0.05, release=0.12)
    P.hit("snare_roll", 43, 0, 0.3, 4.0)
    P.hit("cymbal", 42, 2, 0.24, 6.0)
    # --- A' (44-59) : le thème en tutti
    P.hit("crash", 44, 0, 0.26)
    mel(P, "horn", 44, melA, vel=0.64, legato=0.03)
    mel(P, "trp", 44, melA, vel=0.34, legato=0.03)
    mel(P, "vln", 52, "|".join(melA.split("|")[8:]), vel=0.36, octave=1, legato=0.04)
    P.pad("tbn", A, 44, 46, 58, 2, vel=0.16)
    P.pad("choeur_h", A, 44, 50, 64, 3, vel=0.22)
    cm70.ostinato_arene(P, A, 44, 1.0)
    for i, s in enumerate(A):
        cm70.arene_drums(P, 44 + i, 1.05, fill=i in (7, 15))
        gluante_bar(P, 44 + i, s, 1.0)
        if i % 4 == 0 and i:
            P.hit("crash", 44 + i, 0, 0.2)
        r = _bass(s.split()[0], 34)
        P.note("timp", r if r <= 45 else r - 12, 44 + i, 0, 1.0, 0.4)
    # --- B' (60-67) : l'épisode bouffon en tutti
    mel(P, "xylo", 60, "|".join(melB.split("|")[:8]), vel=0.7, legato=0.0)
    mel(P, "trp_stac", 60, "|".join(melB.split("|")[:8]), vel=0.4, legato=0.0)
    mel(P, "picc", 60, "|".join(melB.split("|")[:8]), vel=0.12, legato=0.0)
    for i, s in enumerate(B[:8]):
        b = 60 + i
        r = _bass(s.split()[0], 34)
        P.note("bsn_stac", r, b, 2, 0.4, 0.5)
        P.note("bsn_stac", r + 12, b, 2.5, 0.4, 0.42)
        P.note("tuba_stac", r - 12 if r - 12 >= 28 else r, b, 0, 0.5, 0.5)
        gluante_bar(P, b, s, 0.9)
        cm70.arene_drums(P, b, 0.9, fill=i == 7)
    # --- 68-79 : la grande fanfare finale, et la boucle repart
    P.hit("crash", 68, 0, 0.26)
    mel(P, "trp", 68, fanfare, vel=0.55, legato=0.02)
    mel(P, "horn", 68, fanfare, vel=0.4, octave=-1, legato=0.03)
    P.pad("tbn", coda, 68, 46, 58, 3, vel=0.2)
    P.pad("choeur_h", coda, 68, 50, 64, 3, vel=0.26)
    P.pad("trem_nuit", coda, 68, 70, 82, 2, vel=0.12)
    for i, s in enumerate(coda):
        cm70.arene_drums(P, 68 + i, 1.05, fill=i in (3, 11))
        gluante_bar(P, 68 + i, s, 1.0)
        r = _bass(s.split()[0], 34)
        P.note("timp", r if r <= 45 else r - 12, 68 + i, 0, 1.0, 0.42)
    P.hit("timp_roll", 78, 0, 0.3, 8.0, midi=38)
    return P


PIECES = {"montjoie": (montjoie, -21.0), "guilde": (guilde, -21.0), "campagne": (campagne, -21.5),
          "donjon_mille_marches": (donjon_mille_marches, -21.5), "roi_gelatineux": (roi_gelatineux, -21.0)}


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        sys.exit(1)
    cm.VSCO = Path(args.pop(0))
    cm70.VCSL = cm.VSCO.parent / "VCSL"
    if args and args[0] == "--vcsl":
        args.pop(0)
        cm70.VCSL = Path(args.pop(0))
    cm.TMP = Path(tempfile.gettempdir()) / "musique_v71"
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
