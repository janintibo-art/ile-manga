"""V56 : la musique de Port-Azur.

Compositions originales pour Île Manga, versées au domaine public (CC0 1.0), avec les outils
de la V51 (compose_musique_v51.py, orchestre_v51.py) et l'orchestre VSCO-2 (CC0), plus deux
instruments synthétisés ici, faute d'enregistrements libres :
  - l'accordéon « musette » : trois anches par note, une juste, une un peu haute, une un peu
    basse ; leurs battements donnent le trémolo chantant des bals du bord de l'eau ;
  - la guitare à cordes métalliques : corde pincée (algorithme de Karplus-Strong), caisse de
    résonance (trois formants du bois), attaque de médiator.

  port_azur   « Valse du Port-Azur » : valse musette en sol majeur, 168 à la noire. La main
              gauche de l'accordéon fait « poum-tchak-tchak », la guitare la double à la pompe,
              la contrebasse pince les temps ; le thème passe en mi mineur au milieu, la
              clarinette le reprend en écho.
  valse_azur  « La Valse d'Azur », la chanson de Django (qu'il joue le soir au Perroquet Bleu
              quand on lui a rendu sa partition) : valse manouche en la mineur, 132 à la
              noire ; la guitare chante le thème, puis l'orne de traits rapides, puis un
              violon le reprend pendant qu'elle accompagne. En boucle.
  guitare_triste  ce que Django joue tant que sa partition est perdue : des arpèges lents
              en la mineur qui cherchent un air sans le trouver. En boucle.

Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/compose_musique_v56.py <dossier VSCO-2-CE>
"""
from pathlib import Path
import sys

import numpy as np
from scipy import signal

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v51 as cm  # noqa: E402
from orchestre_v51 import SR  # noqa: E402


def _f(midi: float) -> float:
    return 440.0 * 2 ** ((midi - 69) / 12.0)


class Accordion:
    """Accordéon musette : anches libres (spectre riche, formant vers 1,5 kHz), trois voix
    désaccordées de ±16 cents, souffle léger du soufflet."""

    def __init__(self, name: str, pan: float, width: float, gain: float, detune: float = 16.0,
                 bright: float = 1.0, attack: float = 0.025, release: float = 0.09):
        self.name = name
        self.pan = pan
        self.width = width
        self.gain = gain
        self.detune = detune
        self.bright = bright
        self.attack = attack
        self.release = release
        self.lag = 0.0
        self.rng = np.random.default_rng(abs(hash(name)) % 10000)

    def _reed(self, f: float, m: int, vel: float) -> np.ndarray:
        x = np.arange(m) / SR
        y = np.zeros(m)
        nh = int(min(40, (SR * 0.45) / f))
        tilt = 0.75 + 0.5 * (1.0 - vel)
        ph0 = self.rng.uniform(0, 6.28)
        for k in range(1, nh + 1):
            fk = f * k
            form = 1.0 + 1.6 * np.exp(-((fk - 1500.0) / 900.0) ** 2) * self.bright
            a = form / k ** tilt
            y += a * np.sin(2 * np.pi * fk * x + ph0 * k)
        return y

    def note(self, midi: float, dur: float, vel: float = 0.6, attack=None, release=None, legato=False) -> np.ndarray:
        att = (self.attack if attack is None else attack) * (0.4 if legato else 1.0)
        rel = self.release if release is None else release
        m = int((dur + rel) * SR)
        f = _f(midi)
        c = 2 ** (self.detune / 1200.0)
        mid = self._reed(f, m, vel)
        hi = self._reed(f * c, m, vel)
        lo = self._reed(f / c, m, vel)
        x = np.arange(m) / SR
        env = np.clip(x / max(att, 1e-3), 0, 1) * np.clip((dur + rel - x) / max(rel, 1e-3), 0, 1)
        env *= 1.0 + 0.04 * np.sin(2 * np.pi * 0.8 * x)          # le soufflet respire
        air = signal.lfilter(*signal.butter(2, [800, 4000], btype="band", fs=SR), self.rng.standard_normal(m)) * 0.02
        l = (mid * 0.8 + hi * 0.7 + lo * 0.3) * env + air * env
        r = (mid * 0.8 + hi * 0.3 + lo * 0.7) * env + air * env
        st = np.stack([l, r], axis=1)
        st = signal.lfilter(*signal.butter(2, 6500, fs=SR), st, axis=0)
        return (st * vel * 0.12).astype(np.float32)


class Guitar:
    """Guitare acoustique : corde de Karplus-Strong accordée exactement (rendue sur une
    longueur entière puis rééchantillonnée), position du médiator, caisse de résonance."""

    def __init__(self, name: str, pan: float, width: float, gain: float, decay: float = 0.996,
                 bright: float = 0.6, mute: float = 0.0):
        self.name = name
        self.pan = pan
        self.width = width
        self.gain = gain
        self.decay = decay
        self.bright = bright
        self.mute = mute       # > 0 : étouffée de la paume (la pompe)
        self.lag = 0.0
        self.rng = np.random.default_rng(abs(hash(name)) % 10000 + 7)
        # la caisse : trois résonances du bois
        self.body = []
        for fc, q, g in [(105.0, 3.0, 0.7), (205.0, 4.0, 0.5), (420.0, 2.5, 0.35)]:
            b, a = signal.iirpeak(fc, q, fs=SR)
            self.body.append((b, a, g))

    def note(self, midi: float, dur: float, vel: float = 0.6, attack=None, release=None, legato=False) -> np.ndarray:
        f = _f(midi)
        n_del = max(2, int(round(SR / f)))
        f_real = SR / (n_del + 0.5)
        ratio = f / f_real
        ring = dur if self.mute <= 0 else min(dur, 0.18 + 0.1 * (1 - self.mute))
        total = ring + 0.25
        m = int(total * SR / ratio) + n_del + 4
        # excitation : bruit filtré, médiator vers le chevalet (filtre en peigne)
        ex = self.rng.uniform(-1, 1, n_del)
        ex = signal.lfilter([0.5 + 0.5 * self.bright], [1, -(0.5 - 0.5 * self.bright)], ex)
        p = max(1, int(n_del * 0.13))
        ex[p:] -= ex[:-p] * 0.8
        x = np.zeros(m)
        x[:n_del] = ex * vel
        g = self.decay ** (110.0 / max(f, 60.0)) if self.mute <= 0 else 0.97 - 0.05 * self.mute
        den = np.zeros(n_del + 2)
        den[0] = 1.0
        den[n_del] -= g * 0.5
        den[n_del + 1] -= g * 0.5
        y = signal.lfilter([1.0], den, x)
        # retour à la vraie hauteur
        pos = np.arange(0, len(y) - 1, ratio)
        y = np.interp(pos, np.arange(len(y)), y)
        k = int(total * SR)
        y = y[:k] if len(y) >= k else np.pad(y, (0, k - len(y)))
        tt = np.arange(len(y)) / SR
        y *= np.clip((ring + 0.25 - tt) / 0.25, 0, 1) if self.mute <= 0 else np.clip((ring + 0.08 - tt) / 0.08, 0, 1)
        out = y * 0.6
        for b, a, gg in self.body:
            out = out + signal.lfilter(b, a, y) * gg
        click = np.zeros(len(y))
        cl = int(0.004 * SR)
        click[:cl] = self.rng.standard_normal(cl) * np.hanning(cl) * 0.15 * vel
        out += signal.lfilter(*signal.butter(2, 2500, btype="high", fs=SR), click)
        st = np.stack([out, np.roll(out, 9) * 0.97], axis=1)
        return (st * 0.5).astype(np.float32)


def register():
    cm._cache["accordeon"] = Accordion("accordeon", pan=0.0, width=0.6, gain=1.0)
    cm._cache["accordeon_g"] = Accordion("accordeon_g", pan=0.1, width=0.4, gain=0.7, detune=6.0, bright=0.4, attack=0.012, release=0.05)
    cm._cache["guitare"] = Guitar("guitare", pan=-0.15, width=0.4, gain=1.1, decay=0.997, bright=0.75)
    cm._cache["pompe"] = Guitar("pompe", pan=0.35, width=0.4, gain=0.8, bright=0.5, mute=0.6)
    cm._cache["guitare_b"] = Guitar("guitare_b", pan=0.35, width=0.4, gain=0.9, decay=0.995, bright=0.35)
    cm.WET.update({"accordeon": 0.3, "accordeon_g": 0.25, "guitare": 0.3, "pompe": 0.2, "guitare_b": 0.2})


def strum(P, key: str, sym: str, bar: float, beat: float, lo: int, hi: int, vel: float, beats: float, down: bool = True):
    """Un accord gratté : les cordes l'une après l'autre (8 ms d'écart)."""
    _, pcs, _ = cm.chord(sym)
    notes = P._voicing(key, pcs, lo, hi, 4)
    if not down:
        notes = notes[::-1]
    for i, m in enumerate(notes):
        P.note(key, m, bar, beat + i * 0.008 / P.spb, beats, vel * (1.0 - 0.06 * i), human=False)


def waltz_comp(P, prog, bar0: int, gkey: str = "pompe", lh: bool = True, vel: float = 0.5, bass_key: str = "cb_pizz"):
    """« Poum-tchak-tchak » : basse (fondamentale puis quinte) au premier temps, accords aux deux autres."""
    for i, sym in enumerate(prog):
        _, pcs, b = cm.chord(sym)
        root = 40 + ((b - 40) % 12)
        if i % 2 == 1:
            root = root + 7 if root + 7 <= 52 else root - 5
        P.note(bass_key, root - 12 if bass_key == "cb_pizz" else root, bar0 + i, 0, 1.0, vel * 0.9)
        if lh:
            P.note("accordeon_g", root, bar0 + i, 0, 0.8, vel * 0.8)
            for m in P._voicing("accordeon_g", pcs, 55, 67, 3):
                P.note("accordeon_g", m, bar0 + i, 1, 0.55, vel * 0.55)
                P.note("accordeon_g", m, bar0 + i, 2, 0.55, vel * 0.5)
        strum(P, gkey, sym, bar0 + i, 1, 52, 67, vel * 0.7, 0.5)
        strum(P, gkey, sym, bar0 + i, 2, 52, 67, vel * 0.6, 0.5, down=False)


def port_azur():
    P = cm.Piece("port_azur", 168, 56, beats=3, seed=5601, room=1.8)
    A = ["G", "G", "G", "D7", "D7", "D7", "D7", "G", "G", "G", "G7", "C", "C", "G", "D7", "G"]
    B = ["Em", "Em", "B7", "B7", "B7", "B7", "Em", "Em", "Am", "Am", "Em", "Em", "C", "B7", "Em", "D7"]
    melA = ("D5:1 G5:1 A5:1 | B5:2 A5:1 | G5:1 F#5:1 G5:1 | A5:3 | C6:1 B5:1 A5:1 | F#5:2 E5:1 | D5:1 E5:1 F#5:1 | G5:3 | "
            "D5:1 G5:1 B5:1 | D6:2 C6:1 | B5:1 A5:1 G5:1 | E5:3 | E5:1 G5:1 C6:1 | B5:2 G5:1 | A5:1 C6:1 F#5:1 | G5:3")
    melB = ("E5:1 G5:1 B5:1 | E6:2 D#6:1 | D#6:1 C6:1 B5:1 | A5:3 | F#5:1 A5:1 B5:1 | D#6:2 C6:1 | B5:1 A5:1 G5:1 | E5:3 | "
            "A5:1 C6:1 E6:1 | D6:1 C6:1 A5:1 | B5:1 G5:1 E5:1 | G5:3 | C6:1 B5:1 A5:1 | F#5:1 A5:1 D#5:1 | E5:3 | D5:1 E5:1 F#5:1")
    intro = ["G", "C", "D7", "G"]
    # introduction : l'accordéon seul, un arpège qui monte et la guitare qui entre
    P.melody("accordeon", 0, "G4:1 B4:1 D5:1 | E5:1 G5:1 C6:1 | A5:1 F#5:1 D5:1 | G5:2 r:1", vel=0.5)
    waltz_comp(P, intro, 0, lh=False, vel=0.35)
    # A : le thème
    P.melody("accordeon", 4, melA, vel=0.62)
    waltz_comp(P, A, 4, vel=0.5)
    # B : en mi mineur, la clarinette répond à l'octave en dessous
    P.melody("accordeon", 20, melB, vel=0.6)
    P.melody("clar", 20, melB, vel=0.18, octave=-1)
    waltz_comp(P, B, 20, vel=0.48)
    # A' : le thème, la flûte brode au-dessus
    P.melody("accordeon", 36, melA, vel=0.64)
    P.melody("flute", 36, "B5:3 | D6:3 | D6:3 | C6:3 | C6:3 | A5:3 | A5:3 | B5:3 | B5:3 | G6:3 | F6:3 | E6:3 | E6:3 | D6:3 | C6:3 | B5:3", vel=0.16)
    waltz_comp(P, A, 36, vel=0.52)
    # coda
    P.melody("accordeon", 52, "D6:1 B5:1 G5:1 | A5:1 F#5:1 D5:1 | G5:3 | G4:1 r:2", vel=0.55)
    waltz_comp(P, ["G", "D7", "G", "G"], 52, vel=0.42)
    for b in (4, 12, 20, 28, 36, 44, 52):
        P.hit("triangle", b, 0, 0.1)
    return P


def valse_azur():
    P = cm.Piece("valse_azur", 132, 52, beats=3, seed=5602, room=1.2)
    prog = ["Am6", "Am6", "E7", "E7", "E7", "E7", "Am6", "Am6", "Dm6", "Dm6", "Am6", "Am6", "B7", "E7", "Am6", "E7"]
    mel = ("E5:1 A5:1 C6:1 | E6:2 D6:1 | D6:1 B5:1 G#5:1 | B5:3 | G#5:1 B5:1 D6:1 | F6:2 E6:1 | E6:1 C6:1 A5:1 | A5:3 | "
           "D5:1 F5:1 A5:1 | B5:2 A5:1 | C6:1 B5:1 A5:1 | E5:3 | D#5:1 F#5:1 A5:1 | G#5:1 B5:1 D6:1 | C6:1 B5:1 A5:1 | G#5:1 B5:1 E6:1")
    var = ("E5:0.5 F5:0.5 A5:0.5 C6:0.5 E6:1 | F6:0.5 E6:0.5 D6:1 C6:1 | B5:0.5 C6:0.5 D6:0.5 B5:0.5 G#5:1 | E5:1 G#5:1 B5:1 | "
           "D6:0.5 C6:0.5 B5:0.5 G#5:0.5 F5:1 | E5:0.5 F5:0.5 G#5:0.5 B5:0.5 D6:1 | C6:0.5 B5:0.5 A5:0.5 G#5:0.5 A5:1 | E6:3 | "
           "F6:0.5 E6:0.5 D6:0.5 C6:0.5 B5:1 | A5:0.5 B5:0.5 D6:0.5 F6:0.5 A6:1 | G#6:0.5 A6:0.5 E6:1 C6:1 | A5:3 | "
           "D#6:0.5 E6:0.5 F#6:0.5 A6:0.5 B6:1 | G#6:0.5 F6:0.5 E6:0.5 D6:0.5 B5:1 | C6:1 E6:1 A6:1 | G#6:1 E6:1 B5:1")
    # deux mesures de pompe pour lancer la danse
    waltz_comp(P, ["Am6", "E7"], 0, gkey="pompe", lh=False, vel=0.45)
    # 1er tour : la guitare chante le thème
    P.melody("guitare", 2, mel, vel=0.7, octave=-1, legato=0.0, swell=False)
    waltz_comp(P, prog, 2, gkey="pompe", lh=False, vel=0.45)
    # 2e tour : les traits rapides
    P.melody("guitare", 18, var, vel=0.72, octave=-1, legato=0.0, swell=False)
    waltz_comp(P, prog, 18, gkey="pompe", lh=False, vel=0.47)
    # 3e tour : le violon reprend le thème, la guitare accompagne en arpèges
    P.melody("solo_vln", 34, mel, vel=0.3)
    P.arp("guitare_b", prog, 34, 52, step=1.0, pattern=[0, 2, 3], vel=0.32, ring=2.0, span=2)
    waltz_comp(P, prog, 34, gkey="pompe", lh=False, vel=0.42)
    # fin, qui retombe sur la pompe du début (la boucle repart sans heurt)
    P.melody("guitare", 50, "A4:1 C5:1 E5:1 | G#4:1 B4:1 E5:1", vel=0.6, legato=0.0, swell=False)
    waltz_comp(P, ["Am6", "E7"], 50, gkey="pompe", lh=False, vel=0.45)
    return P


def guitare_triste():
    P = cm.Piece("guitare_triste", 84, 24, beats=3, seed=5603, room=1.2)
    prog = ["Am", "Am", "Dm", "Dm", "E7", "E7", "Am", "Am", "F", "F", "Dm", "E7"]
    P.arp("guitare_b", prog + prog, 0, 45, step=1.0, pattern=[0, 2, 4, 3], vel=0.42, ring=3.0, span=2)
    for b in range(0, 24, 2):
        _, _, root = cm.chord((prog + prog)[b])
        P.note("guitare_b", 40 + ((root - 40) % 12), b, 0, 3.0, 0.5)
    # un bout de mélodie, qui s'arrête en route (il ne se souvient plus de la suite)
    P.melody("guitare", 4, "E5:2 A5:1 | C6:3 | B5:1 A5:1 G#5:1 | B5:3", vel=0.55, octave=-1, legato=0.0, swell=False)
    P.melody("guitare", 14, "E5:2 A5:1 | C6:2 E6:1 | D6:3 | r:3", vel=0.5, octave=-1, legato=0.0, swell=False)
    return P


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cm.VSCO = Path(sys.argv[1])
    cm.TMP.mkdir(parents=True, exist_ok=True)
    register()
    which = sys.argv[2:] or ["port_azur", "valse_azur", "guitare_triste"]
    if "port_azur" in which:
        port_azur().render(cm.OUT / "port_azur.ogg", rms_db=-21.0)
    if "valse_azur" in which:
        valse_azur().render(cm.OUT / "valse_azur.ogg", rms_db=-21.0)
    if "guitare_triste" in which:
        guitare_triste().render(cm.OUT / "guitare_triste.ogg", rms_db=-23.0)


if __name__ == "__main__":
    main()
