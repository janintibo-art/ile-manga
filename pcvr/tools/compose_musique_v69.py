"""V69 : les musiques de l'Île des Trois Soleils.

Compositions originales pour Île Manga, versées au domaine public (CC0 1.0), jouées par
l'orchestre VSCO-2 (CC0) avec les outils de la V51 (compose_musique_v51.py, orchestre_v51.py).
Quelques pupitres sont ajoutés pour l'occasion (toujours VSCO-2 CE / VSCO 1, CC0) : la flûte sans
vibrato (souffle boisé : le ney, les flûtes d'argile et d'os), le piccolo, le xylophone, la tumba et
le quinto (le « doum » et le « tek » du tambour sur cadre), le grand tambour joué à la main (le
huehuetl), les tambours à fente (le teponaztli, deux tons), les maracas (les sonnailles), le
tambourin (le riq), le gong et la grosse caisse frottée.

« Per-Hâpy » (per_hapy.ogg), le village égyptien au bord du fleuve Iterou, calme et lumineux : la
mixolydien, 80 à la noire, en boucle (44 mesures). Un bourdon de violoncelles et
d'altos sur la et mi, la harpe qui égrène (la harpe du Nil), le tambour sur cadre (doum de la tumba,
tek du quinto, sur un maqsoum paisible) et le riq. La flûte sans vibrato, dans le grave, chante l'air
comme un ney ; le hautbois le reprend, orné de gruppettos et d'appoggiatures ; au milieu, le mode
change : le si bémol et le do dièse du hijaz (la phrygien dominant), le ney chante, le hautbois lui
répond en écho ; un intermède de harpe ; puis le hautbois et la flûte ensemble, chacun avec ses
ornements (une hétérophonie, comme les musiciens du fleuve) ; la fin revient au hijaz, la flûte seule
sur le bourdon, et la boucle recommence.

« Yaxché » (yaxche.ogg), la cité maya dans la jungle : ré dorien, 96 à la noire, en boucle
(52 mesures). Le marimba tourne en ostinato (3 + 3 + 2 croches), le teponaztli (tambours à fente,
deux tons) et la tumba battent doucement, les maracas frémissent ; la contrebasse en pizzicato. La
flûte boisée chante l'air, mystérieux et chaud ; la clarinette mène le second thème (fa, do, sol) ;
une pause où il ne reste que les tambours, le marimba grave et des appels d'oiseaux (le piccolo) ;
la flûte et la clarinette ensemble, puis le retour de l'air, doublé au xylophone, avec les cordes.

« Aztlán » (aztlan.ogg), la cité aztèque sur le lac de la Lune : sol mixolydien, 104 à la noire,
en boucle (52 mesures). Le huehuetl (grand tambour à main) et le teponaztli qui s'entrecroise, les
sonnailles ; un appel de conque (le cor) ouvre le morceau. La flûte sans vibrato, très aiguë, chante
comme un ocarina, fière et claire ; le cor et le trombone mènent le second thème, une procession,
la flûte leur répond ; une pause de tambours ; puis tout le monde, le xylophone, les cordes, la
trompette.

« Les Trois Soleils » (trois_soleils_donjon.ogg), la musique des trois grands souterrains : mi
phrygien, 60 à la noire, en boucle (36 mesures). Un bourdon de contrebasses et de violoncelles, la
grosse caisse frottée, le gong, les timbales, de rares coups de tambour de bois. Le motif des soleils,
trois notes qui montent (mi, si, do : la fondamentale, la quinte, la sixte mineure), revient partout :
aux violoncelles, aux timbales, à la clarinette qui chante dans l'ombre, aux cors et au trombone (un
choral solennel), aux cors encore quand les cordes s'agitent (trémolos, ostinato en spiccato), et tout
en haut, à la flûte et au glockenspiel, comme un éclat de soleil dans les ténèbres.

Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/compose_musique_v69.py <dossier VSCO-2-CE> [per_hapy|yaxche|aztlan|trois_soleils_donjon]
"""
from pathlib import Path
import gc
import sys

import numpy as np
from scipy.signal import butter, fftconvolve, sosfilt

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v51 as cm  # noqa: E402
import orchestre_v51 as orch  # noqa: E402

SR = orch.SR

# les pupitres ajoutés (motif de fichiers, options), comme dans compose_musique_v51.INSTR
EXTRA = {
    "flute_nv": ("Woodwinds/Flute/susNV/*.wav", dict(attack=0.05, release=0.5, pan=-0.2, width=0.4, gain=0.85)),
    "picc": ("Woodwinds/Piccolo/Sus/*.wav", dict(attack=0.03, release=0.35, pan=-0.05, width=0.3, gain=0.45)),
    "xylo": ("Percussion/Xylo/*.wav", dict(sustain=False, attack=0.001, release=0.6, pan=0.15, width=0.4, gain=0.3)),
    "doum": ("Percussion/Tumba-HitN_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=0.5, pan=0.15, width=0.3, gain=0.55)),
    "tek": ("Percussion/Quinto-HitN_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=0.4, pan=-0.2, width=0.3, gain=0.35)),
    "huehuetl": ("VSCO 1 Percussion/drums/other/ethnic/giant/hand/EthnicLargeHand_hit_*.wav",
                 dict(pitched=False, sustain=False, attack=0.001, release=0.8, pan=0.1, width=0.5, gain=0.8)),
    "tepo_lo": ("VSCO 1 Percussion/varWood/log_drum/slitdrum1_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=0.4, pan=-0.3, width=0.3, gain=0.4)),
    "tepo_hi": ("VSCO 1 Percussion/varWood/log_drum/slitdrum2_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=0.4, pan=-0.4, width=0.3, gain=0.35)),
    "maraca": ("VSCO 1 Percussion/varWood/maraca[1-5].wav", dict(pitched=False, sustain=False, attack=0.001, release=0.3, pan=0.45, width=0.3, gain=0.16)),
    "tamb": ("Percussion/Tamb1-Hit_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=0.4, pan=0.45, width=0.3, gain=0.3)),
    "gong": ("VSCO 1 Percussion/varMetal/Gong/gong_hit_p*.wav", dict(pitched=False, sustain=False, attack=0.001, release=3.0, pan=0.0, width=0.8, gain=0.3)),
    "bd_rub": ("Percussion/bassdrum_rub*_v1.wav", dict(pitched=False, sustain=False, attack=0.05, release=1.5, pan=0.0, width=0.6, gain=0.35)),
    # des nappes plus douces, pour accompagner l'air sans le couvrir
    "vln_pad": ("Strings/Violin Section/susVib/*.wav", dict(attack=0.15, release=0.9, pan=-0.45, width=0.7, gain=0.32)),
    "vla_pad": ("Strings/Viola Section/susvib/*.wav", dict(attack=0.15, release=0.9, pan=0.15, width=0.6, gain=0.32)),
    "vc_drone": ("Strings/Cello Section/susvib/*.wav", dict(attack=0.3, release=1.0, pan=0.3, width=0.5, gain=0.3)),
    "horn_pad": ("Brass/F Horn/sus/*.wav", dict(attack=0.1, release=0.7, pan=-0.25, width=0.6, gain=0.45)),
}
EXTRA_WET = {"flute_nv": 0.5, "picc": 0.55, "xylo": 0.45, "doum": 0.35, "tek": 0.35, "huehuetl": 0.4, "tepo_lo": 0.4,
             "tepo_hi": 0.4, "maraca": 0.35, "tamb": 0.4, "gong": 0.6, "bd_rub": 0.55, "vln_pad": 0.5, "vla_pad": 0.5,
             "vc_drone": 0.4, "horn_pad": 0.55, "snare": 0.4, "bdrum": 0.4}


def register() -> None:
    cm.INSTR.update(EXTRA)
    cm.WET.update(EXTRA_WET)


class LeanMix(orch.Mix):
    """La même table de mixage qu'orchestre_v51.Mix, sans une piste par pupitre : chaque note va
    tout de suite dans la piste sèche et dans l'envoi vers la salle (avec la part de réverbération de
    son pupitre). Le résultat est le même, avec bien moins de mémoire."""

    def __init__(self, seconds: float, loop: bool = True):
        super().__init__(seconds, loop)
        self.dry = np.zeros((self.n + self.tail, 2), np.float32)
        self.send = np.zeros_like(self.dry)

    def add(self, bus, x, at, pan, width, gain=1.0):
        i = int(round(at * SR))
        y = orch.panned(x, pan, width) * gain
        j = min(len(self.dry), i + len(y))
        if j > i:
            self.dry[i:j] += y[:j - i]
            self.send[i:j] += y[:j - i] * cm.WET.get(bus, 0.3)

    def render(self, wet, ir, master=1.0):
        rev = np.stack([fftconvolve(self.send[:, c], ir[:, c])[: len(self.send)] for c in range(2)], axis=1)
        self.send = None
        out = self.dry + rev
        del rev
        out = sosfilt(butter(2, 30, "highpass", fs=SR, output="sos"), out, axis=0)
        if self.loop:
            body = out[: self.n].copy()
            rest = out[self.n:]
            k = 0
            while k < len(rest):
                m = min(self.n, len(rest) - k)
                body[:m] += rest[k:k + m]
                k += m
            out = body
        else:
            env = np.abs(out).max(axis=1)
            last = np.nonzero(env > env.max() * 1e-3)[0]
            out = out[: (last[-1] + 1) if len(last) else self.n]
            f = min(len(out), int(0.8 * SR))
            out[-f:] *= np.linspace(1, 0, f)[:, None] ** 2
        return master * out


class Morceau(cm.Piece):
    """Une partition (comme compose_musique_v51.Piece), jouée sur la table de mixage économe. Les
    notes sont d'abord notées (avec le même « jeu humain » que la V51), puis jouées pupitre par
    pupitre : un seul jeu d'échantillons en mémoire à la fois."""

    def __init__(self, *a, **kw):
        super().__init__(*a, **kw)
        self.mix = LeanMix(self.mix.n / SR, loop=self.mix.loop)
        self._todo: dict[str, list] = {}

    def note(self, key, midi, bar, beat, beats, vel=0.5, human=True, **kw):
        t = self.t(bar, beat)
        jit = 0.0
        if human:
            jit = self.rng.uniform(-0.012, 0.012)
            vel = min(1.0, max(0.02, vel + self.rng.uniform(-0.04, 0.04)))
        self._todo.setdefault(key, []).append((midi, t, jit, beats * self.spb, vel, kw))

    def play(self) -> None:
        for key in list(self._todo):
            ins = cm.I(key)
            for midi, t, jit, dur, vel, kw in self._todo.pop(key):
                at = max(0.0, t - (0.0 if kw.get("legato") else ins.lag) + jit)
                self.mix.add(key, ins.note(midi, dur, vel, **kw), at, ins.pan, ins.width, ins.gain)
            cm._cache.pop(key, None)
            del ins
            gc.collect()

    def render(self, out: Path, rms_db: float = -21.0):
        self.play()
        super().render(out, rms_db)


def mel(P, key: str, bar: float, text: str, **kw) -> None:
    """Piece.melody, en vérifiant que chaque mesure est complète."""
    for k, m in enumerate(text.split("|")):
        tot = sum(float(t.split(":")[1]) for t in m.split())
        if abs(tot - P.beats) > 1e-6:
            raise ValueError(f"{P.name} {key} mesure {bar + k} : {tot} temps")
    P.melody(key, bar, text, **kw)


def drone(P, key: str, midi: int, bar0: int, bar1: int, vel: float, every: int = 4, attack: float = 0.6) -> None:
    """Une note tenue (bourdon), reprise toutes les « every » mesures."""
    for b in range(bar0, bar1, every):
        n = min(every, bar1 - b)
        P.note(key, midi, b, 0, n * P.beats + 0.3, vel, attack=attack)


def ostinato(P, key: str, prog, bar0: int, lo: int, pattern, accents, vel: float, span: int = 2, ring: float = 1.0) -> None:
    """Un ostinato en croches sur les notes de l'accord (pattern = indices), accentué (accents)."""
    for i, cell in enumerate(prog):
        syms = cell.split()
        each = P.beats / len(syms)
        for k in range(int(P.beats * 2)):
            pos = k * 0.5
            s = syms[min(len(syms) - 1, int(pos // each))]
            _, pcs, _ = cm.chord(s)
            tones = sorted({m for m in range(lo, lo + 12 * span + 1) if m % 12 in pcs})
            P.note(key, tones[pattern[k % len(pattern)] % len(tones)], bar0 + i, pos, ring, vel * accents[k % len(accents)])


# =========================================================================== Per-Hâpy

def frame_drum(P, bar: int, vel: float = 1.0, riq: bool = True, light: bool = False) -> None:
    """Le tambour sur cadre, un maqsoum paisible : DOUM tek . tek DOUM . tek (tek)."""
    P.hit("doum", bar, 0, 0.42 * vel, 1.0)
    P.hit("doum", bar, 2, 0.34 * vel, 1.0)
    if not light:
        P.hit("tek", bar, 0.5, 0.2 * vel, 0.5)
        P.hit("tek", bar, 1.5, 0.24 * vel, 0.5)
        P.hit("tek", bar, 3, 0.24 * vel, 0.5)
        P.hit("tek", bar, 3.5, 0.13 * vel, 0.5)
    if riq:
        for k in range(8):
            P.hit("shaker", bar, k * 0.5 + 0.25, (0.07 if k % 2 else 0.1) * vel, 0.5)
        P.hit("tamb", bar, 1, 0.12 * vel, 0.5)
        P.hit("tamb", bar, 3, 0.14 * vel, 0.5)


def per_hapy():
    P = Morceau("per_hapy", 80, 44, beats=4, seed=691, room=3.0)
    intro = ["A", "A", "G/A", "A"]
    A = ["A", "Dmaj7/A", "A", "Em7/A", "D/A", "A", "G", "A"]
    B = ["A", "Gm6/A", "Dm", "A", "Dm A", "Gm", "C#dim", "A"]
    inter = ["A", "Dmaj7/A", "Em7/A", "A"]
    coda = ["A", "Bb", "Gm", "A"]
    prog = intro + A + A + B + inter + A + coda
    melA = ("A4:1 C#5:1 E5:1.5 F#5:0.25 E5:0.25 | D5:0.5 E5:0.5 C#5:1 B4:2 | A4:1 B4:0.5 C#5:0.5 D5:1 E5:1 | "
            "F#5:1.5 G5:0.25 F#5:0.25 E5:2 | A5:1 G5:0.5 F#5:0.5 E5:1 D5:1 | C#5:0.5 D5:0.5 E5:1 B4:2 | "
            "C#5:1 B4:0.5 A4:0.5 G4:1 B4:1 | A4:4")
    melA2 = ("A4:1 C#5:0.75 D5:0.25 E5:1.5 G5:0.25 F#5:0.25 | E5:0.5 D5:0.5 C#5:0.5 D5:0.5 B4:2 | "
             "A4:0.5 B4:0.5 C#5:0.5 D5:0.5 E5:1 A5:1 | G5:1 F#5:0.5 G5:0.25 F#5:0.25 E5:2 | "
             "A5:1.5 B5:0.25 A5:0.25 G5:0.5 F#5:0.5 E5:1 | D5:0.5 C#5:0.5 D5:0.5 E5:0.5 B4:2 | "
             "C#5:1 B4:0.5 A4:0.5 G4:0.5 A4:0.5 B4:1 | A4:4")
    melB = ("A4:1 Bb4:1 C#5:1.5 D5:0.5 | E5:2 D5:0.5 C#5:0.5 Bb4:1 | D5:1 F5:1 E5:1 D5:1 | C#5:2 Bb4:0.5 C#5:0.5 A4:1 | "
            "F5:1.5 E5:0.5 D5:1 C#5:1 | D5:0.5 E5:0.5 F5:0.5 E5:0.5 D5:1 Bb4:1 | C#5:1 D5:0.5 C#5:0.5 Bb4:1 G4:1 | A4:4")
    echoB = ("r:4 | r:2 F5:0.5 E5:0.5 D5:1 | r:4 | r:2 Bb4:0.5 A4:0.5 G4:0.5 A4:0.5 | r:4 | r:2 G5:0.5 F5:0.5 E5:1 | "
             "r:4 | r:4")
    counter = "E5:4 | F#5:4 | E5:4 | G5:4 | F#5:4 | E5:4 | D5:4 | C#5:4"
    # le bourdon : la (violoncelles) partout, mi (altos) sauf dans le hijaz et la fin
    drone(P, "vc_drone", 45, 0, 44, 0.42)
    drone(P, "vla_pad", 52, 0, 20, 0.2)
    drone(P, "vla_pad", 52, 28, 40, 0.2)
    P.bass("cb", prog[4:40], 4, 33, 45, vel=0.16)
    # la harpe du Nil : tranquille au début, plus vive à la reprise
    P.arp("harp", prog[:32], 0, 50, step=1.0, pattern=[0, 2, 4, 5, 4, 2], vel=0.24, span=2)
    P.arp("harp", inter + A, 28, 50, step=0.5, pattern=[0, 2, 4, 6, 5, 4, 2, 1], vel=0.22, span=3)
    P.arp("harp", coda, 40, 45, step=1.0, pattern=[0, 2, 4, 2], vel=0.2, span=2)
    # le tambour sur cadre et le riq
    for b in range(2, 44):
        if 28 <= b < 32:
            frame_drum(P, b, 0.75, riq=True, light=True)
        elif b >= 40:
            frame_drum(P, b, 0.85 - 0.08 * (b - 40), riq=b < 42)
        else:
            frame_drum(P, b, 0.7 if b < 4 else 1.0, riq=b >= 4)
    # l'appel du ney
    mel(P, "flute_nv", 1, "r:2 E5:2 | A5:2.5 G5:0.25 F#5:0.25 E5:1 | C#5:3 r:1", vel=0.4, legato=0.03)
    # A : le ney chante l'air
    mel(P, "flute_nv", 4, melA, vel=0.48, legato=0.03)
    P.pad("vla_pad", A, 4, 55, 67, 2, vel=0.1)
    # A' : le hautbois, orné ; la flûte tient un contre-chant
    mel(P, "oboe", 12, melA2, vel=0.46, legato=0.03)
    mel(P, "flute", 12, counter, vel=0.22, legato=0.05)
    P.pad("vln_pad", A, 12, 64, 76, 2, vel=0.1)
    # B : le hijaz ; le ney, le hautbois en écho, la clarinette tient les accords
    mel(P, "flute_nv", 20, melB, vel=0.5, legato=0.03)
    mel(P, "oboe", 20, echoB, vel=0.36, legato=0.02)
    P.pad("clar", B, 20, 53, 65, 2, vel=0.12)
    P.hit("triangle", 20, 0, 0.12)
    # l'intermède : la harpe, une nappe de violons
    P.pad("vln_pad", inter, 28, 64, 76, 3, vel=0.12)
    P.sparkle("glock", inter, 28, 81, 93, prob=0.2, vel=0.1, step=2.0)
    # A'' : le hautbois et la flûte, chacun avec ses ornements
    mel(P, "oboe", 32, melA2, vel=0.46, legato=0.03)
    mel(P, "flute", 32, melA, vel=0.3, legato=0.03, octave=1)
    P.pad("vln_pad", A, 32, 64, 76, 2, vel=0.12)
    P.pad("vla_pad", A, 32, 55, 67, 2, vel=0.12)
    P.hit("triangle", 32, 0, 0.12)
    # la fin : le hijaz revient, le ney seul sur le bourdon
    mel(P, "flute_nv", 40, "E5:2 F5:0.5 E5:0.5 D5:1 | D5:1 C#5:0.5 D5:0.5 Bb4:2 | Bb4:1 A4:0.5 Bb4:0.5 G4:1 Bb4:1 | A4:4",
        vel=0.42, legato=0.03)
    P.pad("clar", coda, 40, 53, 65, 2, vel=0.1)
    return P


# =========================================================================== Yaxché

def maya_drums(P, bar: int, vel: float = 1.0, full: bool = True) -> None:
    """Le teponaztli (deux tons, en 3 + 3 + 2), la tumba, les maracas."""
    P.hit("tepo_lo", bar, 0, 0.42 * vel, 0.5)
    P.hit("tepo_hi", bar, 1.5, 0.36 * vel, 0.5)
    P.hit("tepo_lo", bar, 3, 0.38 * vel, 0.5)
    if full:
        P.hit("tepo_hi", bar, 0.5, 0.18 * vel, 0.5)
        P.hit("tepo_hi", bar, 2, 0.22 * vel, 0.5)
        P.hit("tepo_hi", bar, 2.5, 0.16 * vel, 0.5)
        P.hit("tepo_hi", bar, 3.5, 0.2 * vel, 0.5)
        for k in range(8):
            P.hit("maraca", bar, k * 0.5, (0.22 if k in (0, 3, 6) else 0.13) * vel, 0.5)
    P.hit("doum", bar, 0, 0.3 * vel, 1.0)
    P.hit("doum", bar, 2.5, 0.22 * vel, 1.0)


def yaxche():
    P = Morceau("yaxche", 96, 52, beats=4, seed=692, room=2.4)
    intro = ["Dm7", "C/D", "Dm7", "C/D"]
    A = ["Dm7", "C/D", "Dm7", "G/D", "Dm7", "C/D", "Fmaj7", "Am7"]
    A2 = ["Dm7", "C/D", "Dm7", "G/D", "Dm7", "C/D", "Fmaj7 G", "Dm7"]
    B = ["Fmaj7", "C", "G", "Dm7", "Fmaj7", "C", "Em7", "Asus4 A"]
    brk = ["Dm7", "Dm7", "C/D", "Dm7"]
    coda = ["Dm7", "C/D", "Dm7", "Dm7"]
    prog = intro + A + A2 + B + brk + B + A2 + coda
    melA = ("A4:1.5 C5:0.5 D5:1 F5:1 | E5:1 D5:1 C5:2 | D5:1.5 F5:0.5 G5:1 A5:1 | B5:1 A5:0.5 G5:0.5 D5:2 | "
            "A5:1.5 G5:0.5 F5:1 D5:1 | E5:1 C5:1 G4:2 | A4:1 C5:1 F5:1 E5:1 | E5:1 C5:1 A4:2")
    melA2 = melA.rsplit("|", 2)[0] + "| A4:1 C5:1 D5:1 B4:1 | D5:4"
    melB = ("C5:2 A4:1 F4:1 | G4:1.5 E4:0.5 C4:2 | D4:1 G4:1 B4:1 D5:1 | C5:2 A4:2 | F4:1 A4:1 C5:1.5 E5:0.5 | "
            "D5:1 C5:1 G4:2 | G4:1 B4:1 E5:1 D5:1 | D5:2 C#5:2")
    # le marimba : l'ostinato en 3 + 3 + 2 (sauf à la pause, où il descend dans le grave)
    acc = [1.0, 0.62, 0.7, 0.95, 0.62, 0.7, 0.9, 0.66]
    ostinato(P, "marimba", prog[:28], 0, 50, [0, 2, 4, 1, 3, 5, 2, 4], acc, 0.36)
    ostinato(P, "marimba", brk, 28, 38, [0, 2, 1, 0, 2, 1, 3, 2], acc, 0.32)
    ostinato(P, "marimba", prog[32:], 32, 50, [0, 2, 4, 1, 3, 5, 2, 4], acc, 0.34)
    # les tambours
    for b in range(52):
        maya_drums(P, b, 0.7 if b < 2 else (0.85 if b >= 48 else 1.0), full=b >= 2 and not (b >= 50))
    P.bass("cb_pizz", prog[4:28] + prog[32:48], 4, 31, 43, vel=0.32, rhythm=[(0.0, 1.0), (2.5, 1.0)])
    P.bass("cb_pizz", prog[48:], 48, 31, 43, vel=0.28, rhythm=[(0.0, 1.0)])
    # A : la flûte boisée
    mel(P, "flute_nv", 4, melA, vel=0.46, legato=0.03)
    P.pad("vla_pad", A, 4, 53, 65, 2, vel=0.08)
    # A' : la flûte reprend, le xylophone répond en écho
    mel(P, "flute_nv", 12, melA2, vel=0.46, legato=0.03)
    mel(P, "xylo", 12, "r:4 | r:2 C6:1 G5:1 | r:4 | r:2 D6:1 B5:1 | r:4 | r:2 C6:1 G5:1 | r:4 | r:2 A5:1 D6:1", vel=0.3)
    P.pad("vla_pad", A2, 12, 53, 65, 2, vel=0.1)
    # B : la clarinette, les cordes en pizzicato
    mel(P, "clar", 20, melB, vel=0.46, legato=0.03)
    P.chord_hits("vla_pizz", B, 20, 55, 67, [1.0, 3.0], n=2, vel=0.16, dur=0.5)
    P.pad("vc_drone", B, 20, 41, 53, 1, vel=0.22)
    # la pause : les tambours, le marimba grave, des oiseaux
    mel(P, "picc", 28, "r:2 A6:0.25 G6:0.25 A6:1.5 | r:4 | r:1 D6:0.25 E6:0.25 D6:0.5 r:2 | r:2.5 G6:0.25 A6:0.25 E6:1", vel=0.26, legato=0.02)
    P.hit("triangle", 28, 0, 0.1)
    # B' : la flûte et la clarinette ensemble
    mel(P, "clar", 32, melB, vel=0.42, legato=0.03)
    mel(P, "flute_nv", 32, melB, vel=0.36, legato=0.03, octave=1)
    P.pad("vln_pad", B, 32, 62, 74, 2, vel=0.1)
    P.pad("vc_drone", B, 32, 41, 53, 1, vel=0.22)
    # A'' : l'air revient, doublé au xylophone, avec les cordes
    mel(P, "flute_nv", 40, melA2, vel=0.48, legato=0.03)
    mel(P, "xylo", 40, melA2, vel=0.2, octave=1)
    P.pad("vln_pad", A2, 40, 62, 74, 2, vel=0.1)
    P.pad("vla_pad", A2, 40, 53, 65, 2, vel=0.1)
    # la fin : l'ostinato seul, un dernier appel de flûte
    mel(P, "flute_nv", 48, "r:4 | A4:1.5 C5:0.5 D5:2 | r:4 | r:4", vel=0.34, legato=0.03)
    return P


# =========================================================================== Aztlán

def aztec_drums(P, bar: int, vel: float = 1.0, full: bool = True) -> None:
    """Le huehuetl (grand tambour à main), le teponaztli qui s'entrecroise, les sonnailles."""
    P.hit("huehuetl", bar, 0, 0.7 * vel, 1.5)
    P.hit("huehuetl", bar, 1.5, 0.42 * vel, 1.0)
    P.hit("huehuetl", bar, 2, 0.6 * vel, 1.5)
    P.hit("huehuetl", bar, 3, 0.48 * vel, 1.0)
    if full:
        P.hit("huehuetl", bar, 3.5, 0.36 * vel, 1.0)
        for pos, k, v in ((0, "tepo_lo", 0.42), (1, "tepo_hi", 0.3), (1.5, "tepo_hi", 0.26), (2, "tepo_lo", 0.38),
                          (3, "tepo_hi", 0.3), (3.75, "tepo_hi", 0.18)):
            P.hit(k, bar, pos, v * vel, 0.5)
        for k in range(8):
            P.hit("maraca", bar, k * 0.5, (0.2 if k % 2 == 0 else 0.12) * vel, 0.5)
        P.hit("shaker", bar, 1, 0.12 * vel, 0.5)
        P.hit("shaker", bar, 3, 0.14 * vel, 0.5)


def aztlan():
    P = Morceau("aztlan", 104, 52, beats=4, seed=693, room=2.6)
    intro = ["G", "G", "F/G", "G"]
    A = ["G", "F", "G", "C", "G", "F", "Em", "D"]
    B = ["C", "G", "Am", "Em", "F", "C", "D", "D"]
    brk = ["G", "F/G", "G", "F/G"]
    coda = ["G", "F", "C", "G"]
    prog = intro + A + A + B + brk + A + B + coda
    melA = ("G5:1 B5:0.5 D6:0.5 D6:1 B5:1 | C6:1 A5:1 F5:2 | G5:0.5 A5:0.5 B5:1 D6:1 B5:1 | C6:1.5 B5:0.5 G5:1 E5:1 | "
            "D5:1 G5:1 B5:1.5 A5:0.5 | A5:1 F5:1 C5:2 | E5:1 G5:1 B5:1 G5:1 | F#5:1 A5:1 D6:2")
    melB = ("E4:2 G4:1 C5:1 | B4:2 D5:1 B4:1 | A4:1.5 C5:0.5 E5:1 C5:1 | B4:4 | A4:1 C5:1 F5:1.5 E5:0.5 | E5:2 C5:2 | "
            "D5:1 F#4:1 A4:1 D5:1 | D5:3 r:1")
    answer = ("r:4 | r:4 | r:4 | r:2 B5:0.5 A5:0.5 G5:0.5 E5:0.5 | r:4 | r:2 G5:0.5 F5:0.5 E5:0.5 C5:0.5 | r:4 | "
              "r:2 A5:0.5 B5:0.5 C6:0.5 D6:0.5")
    # les tambours, tout du long (seuls dans l'introduction et à la pause)
    for b in range(52):
        aztec_drums(P, b, 0.85 if b < 2 else (0.8 if b >= 50 else 1.0), full=b >= 1)
    # l'appel de la conque (le cor) au début
    mel(P, "horn", 0, "r:4 | D4:3 r:1 | G4:2.5 r:1.5 | D4:1 G4:3", vel=0.5, legato=0.03)
    drone(P, "vc_drone", 43, 0, 4, 0.3)
    # A : l'ocarina (la flûte sans vibrato, aiguë)
    mel(P, "flute_nv", 4, melA, vel=0.46, legato=0.02)
    P.bass("vc_pizz", prog[4:28], 4, 31, 43, vel=0.36, rhythm=[(0.0, 1.0), (2.0, 1.0)])
    P.pad("vla_pad", A, 4, 55, 67, 2, vel=0.08)
    # A' : le xylophone avec l'ocarina, les cordes en pizzicato
    mel(P, "flute_nv", 12, melA, vel=0.46, legato=0.02)
    mel(P, "xylo", 12, melA, vel=0.2)
    P.chord_hits("vla_pizz", A, 12, 55, 67, [1.0, 3.0], n=2, vel=0.18, dur=0.5)
    # B : la procession — le cor et le trombone, la flûte répond
    mel(P, "horn", 20, melB, vel=0.56, legato=0.03)
    mel(P, "tbn", 20, melB, vel=0.38, legato=0.03, octave=-1)
    mel(P, "flute_nv", 20, answer, vel=0.38, legato=0.02)
    P.pad("vla_pad", B, 20, 55, 67, 2, vel=0.12)
    P.bass("cb", B, 20, 28, 40, vel=0.26)
    P.hit("crash", 20, 0, 0.18)
    # la pause : les tambours, un appel de conque au loin, la flûte en écho
    mel(P, "horn", 28, "r:4 | G3:3 r:1 | r:4 | D4:2 G4:2", vel=0.36, legato=0.03)
    mel(P, "picc", 28, "r:4 | r:2 D6:0.5 G6:1.5 | r:4 | r:4", vel=0.22, legato=0.02)
    drone(P, "vc_drone", 43, 28, 32, 0.26)
    # A'' : tout le monde
    mel(P, "flute_nv", 32, melA, vel=0.48, legato=0.02)
    mel(P, "picc", 32, melA, vel=0.16, legato=0.02)
    mel(P, "xylo", 32, melA, vel=0.2)
    P.pad("vln_pad", A, 32, 62, 74, 2, vel=0.12)
    P.pad("vla_pad", A, 32, 55, 67, 2, vel=0.12)
    P.bass("vc_pizz", prog[32:48], 32, 31, 43, vel=0.36, rhythm=[(0.0, 1.0), (2.0, 1.0)])
    P.bass("cb", A, 32, 28, 40, vel=0.22)
    P.hit("crash", 32, 0, 0.2)
    # B' : la procession, avec la trompette
    mel(P, "horn", 40, melB, vel=0.56, legato=0.03)
    mel(P, "trp", 40, melB, vel=0.24, legato=0.03)
    mel(P, "tbn", 40, melB, vel=0.38, legato=0.03, octave=-1)
    mel(P, "flute_nv", 40, answer, vel=0.4, legato=0.02)
    P.pad("vln_pad", B, 40, 62, 74, 2, vel=0.12)
    P.bass("cb", B, 40, 28, 40, vel=0.26)
    # la fin : l'ocarina retombe, la conque appelle, et la boucle repart
    mel(P, "flute_nv", 48, "D6:1 B5:1 G5:2 | C6:1 A5:1 F5:2 | E5:1 G5:1 C6:2 | B5:1 A5:1 G5:2", vel=0.4, legato=0.02)
    P.pad("vla_pad", coda, 48, 55, 67, 2, vel=0.1)
    mel(P, "horn", 50, "r:4 | D4:3 r:1", vel=0.36, legato=0.03)
    return P


# =========================================================================== Les Trois Soleils

def trois_soleils_donjon():
    P = Morceau("trois_soleils_donjon", 60, 36, beats=4, seed=694, room=3.6)
    intro = ["Em", "F/E", "Em", "F/E"]
    A = ["Em", "F/E", "Em", "Dm/E", "Am", "F", "Dm", "E"]
    B = ["Am", "Em", "F", "C", "Dm", "Am", "F", "E"]
    C = ["Em", "Em", "F", "F", "Dm", "Dm", "F", "E"]
    D = ["Am", "Em", "F", "E"]
    outro = ["Em", "F/E", "Em", "Em"]
    prog = intro + A + B + C + D + outro
    sun = "E3:1 B3:1 C4:2"
    melA = ("E4:1 B4:1 C5:2 | B4:1 A4:1 F4:2 | G4:1.5 F4:0.5 E4:2 | F4:1 A4:1 D5:2 | C5:1.5 B4:0.5 A4:1 E4:1 | "
            "F4:1 A4:1 C5:1 A4:1 | D5:1.5 C5:0.5 A4:1 F4:1 | G#4:2 E4:2")
    chorale = ("A3:1 E4:1 F4:2 | E4:4 | C5:2 A4:2 | G4:4 | F4:1.5 E4:0.5 D4:2 | A3:1 E4:1 F4:2 | E4:1 D4:1 C4:2 | B3:4")
    # le bourdon des profondeurs, la grosse caisse frottée, le gong
    drone(P, "cb", 28, 0, 36, 0.3, every=4, attack=0.8)
    drone(P, "vc_drone", 40, 0, 12, 0.32)
    drone(P, "vc_drone", 40, 28, 36, 0.3)
    for b in (0, 12, 20, 28):
        P.hit("gong", b, 0, 0.3, 4.0)
    for b in (2, 10, 18, 26, 34):
        P.hit("bd_rub", b, 2, 0.32, 4.0)
    # le motif des soleils : violoncelles et timbales (introduction, fin)
    for b in (1, 3, 33, 35):
        mel(P, "vc", b, sun, vel=0.4, legato=0.04)
        P.note("timp", 40, b, 0, 1.0, 0.36)
        P.note("timp", 47, b, 1, 1.0, 0.3)
        P.note("timp", 48, b, 2, 2.0, 0.34)
    # A : la clarinette dans l'ombre, la harpe grave, le tambour de bois qui compte les pas
    mel(P, "clar", 4, melA, vel=0.44, legato=0.04)
    P.pad("vla_pad", A, 4, 52, 64, 2, vel=0.08)
    P.arp("harp", A, 4, 40, step=2.0, pattern=[0, 2, 1, 3], vel=0.22, span=2)
    for b in range(4, 12):
        P.hit("logdrum_lo", b, 0, 0.22, 1.0)
        P.hit("logdrum_lo", b, 2, 0.16, 1.0)
    P.note("timp", 40, 11, 0, 4.0, 0.22)
    # B : le choral des cuivres, le motif aux cors
    mel(P, "horn", 12, chorale, vel=0.5, legato=0.04)
    P.pad("horn_pad", B, 12, 50, 62, 2, vel=0.16)
    P.pad("tbn", B, 12, 45, 57, 2, vel=0.22)
    P.bass("tuba", B, 12, 28, 40, vel=0.26)
    P.bass("vc", B, 12, 36, 48, vel=0.22)
    for b in (12, 17):
        P.note("timp", 45, b, 0, 1.0, 0.3)
        P.note("timp", 40, b, 1, 1.0, 0.26)
        P.note("timp", 41, b, 2, 2.0, 0.3)
    P.hit("timp_roll", 19, 0, 0.22, 4.0, midi=40)
    # C : les cordes s'agitent (ostinato en spiccato, trémolos), le motif aux cors et au trombone
    for i, s in enumerate(C):
        _, _, r = cm.chord(s)
        low = 36 + (r - 36) % 12
        for k, off in enumerate([0, 0, 1, 0, 0, 7, 8, 7]):
            P.note("vc_spic", low + off, 20 + i, k * 0.5, 0.45, 0.42 if k % 4 == 0 else 0.3)
    P.pad("vln_trem", C, 20, 64, 77, 2, vel=0.12)
    P.pad("vla_pad", C, 20, 52, 64, 2, vel=0.1)
    for b in (20, 24):
        mel(P, "horn", b, "E4:1 B4:1 C5:2 | B4:4", vel=0.52, legato=0.04)
        mel(P, "tbn", b, "E3:1 B3:1 C4:2 | B3:4", vel=0.4, legato=0.04)
        P.note("timp", 40, b, 0, 1.0, 0.4)
        P.note("timp", 47, b, 1, 1.0, 0.34)
        P.note("timp", 48, b, 2, 2.0, 0.38)
    mel(P, "horn", 26, "D4:2 F4:2 | E4:4", vel=0.46, legato=0.04)
    for b in range(20, 28):
        P.hit("doum", b, 0, 0.3, 1.0)
        P.hit("doum", b, 0.42, 0.2, 1.0)
    P.hit("timp_roll", 27, 0, 0.26, 4.0, midi=40)
    # D : un éclat de soleil dans les ténèbres — la flûte et le glockenspiel, très haut
    mel(P, "flute_nv", 28, "E5:1 B5:1 C6:2 | B5:4 | A5:1 E5:1 F5:2 | E5:4", vel=0.32, legato=0.04)
    mel(P, "glock", 28, "E6:1 B6:1 C7:2 | r:4 | r:4 | r:4", vel=0.2)
    P.pad("vln_pad", D, 28, 64, 76, 3, vel=0.08)
    P.hit("chimes", 28, 0, 0.14)
    # la fin : le bourdon, le motif aux violoncelles (et la boucle recommence)
    P.pad("vla_pad", outro, 32, 52, 64, 2, vel=0.07)
    return P


PIECES = {"per_hapy": (per_hapy, -21.0), "yaxche": (yaxche, -21.0), "aztlan": (aztlan, -21.0),
          "trois_soleils_donjon": (trois_soleils_donjon, -22.0)}


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cm.VSCO = Path(sys.argv[1])
    cm.TMP.mkdir(parents=True, exist_ok=True)
    register()
    for name in sys.argv[2:] or list(PIECES):
        fn, rms = PIECES[name]
        P = fn()
        P.render(cm.OUT / f"{name}.ogg", rms_db=rms)
        del P
        gc.collect()


if __name__ == "__main__":
    main()
