"""V68 : les musiques de l'Île de la Balafre, l'île des pirates.

Compositions originales pour Île Manga, versées au domaine public (CC0 1.0), jouées par
l'orchestre VSCO-2 (CC0) avec les outils de la V51 (compose_musique_v51.py, orchestre_v51.py).
Quelques pupitres sont ajoutés pour l'occasion (toujours VSCO-2 CE / VSCO 1, CC0) : le violon solo
en spiccato (le coup d'archet sec du violoneux), la contrebasse en spiccato, la grosse caisse
étouffée (les bottes qui frappent le pont), le tambourin.

« La Balafre » (balafre.ogg), le thème de l'île : une chanson de marins un peu menaçante, mi mineur,
4/4 à 116 à la noire, jouée une fois (avec sa fin). Les bottes frappent le pont (grosse caisse
étouffée, timbales) sur le premier et le troisième temps, les violoncelles et la contrebasse
marquent les basses, les altos et les violons « hachent » les accords sur les temps faibles ; le
violon solo (le violoneux du bord) mène l'air, le basson lui répond en grommelant, la clarinette
chante le contre-chant du refrain, où tout l'équipage crie « Hé ! » ; au milieu, la nuit en mer :
plus de bottes, des trémolos de cordes comme la houle sous la lune, la harpe, le violon seul qui
reprend l'air tout doucement, la clarinette au loin, les timbales qui roulent comme des vagues ;
puis les bottes reviennent, de plus en plus fort, et l'air repart avec la flûte et la trompette.

« La Gigue du Crâne » (gigue_crane.ogg), ce que joue Tom le Violoneux sur la scène du Crâne
Fendu : une gigue rapide à 6/8, la dorien, 112 à la noire pointée, en boucle. Le violon seul (deux
fois l'air AABB, la seconde avec des doubles cordes et des variantes), un bourdon de violoncelles
sur la et mi, et la botte de Tom qui bat la mesure sur les planches.

Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/compose_musique_v68.py <dossier VSCO-2-CE> [balafre|gigue_crane]
"""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_musique_v51 as cm  # noqa: E402

# les pupitres ajoutés (motif de fichiers, options), comme dans compose_musique_v51.INSTR
EXTRA = {
    "solo_spic": ("Strings/Solo Violin/spic/*.wav", dict(sustain=False, attack=0.002, release=0.12, pan=-0.2, width=0.4, gain=0.75)),
    "cb_spic": ("Strings/Solo Contrabass/Spic/*.wav", dict(sustain=False, attack=0.002, release=0.15, pan=0.55, width=0.3, gain=0.8)),
    "stomp": ("VSCO 1 Percussion/drums/bass/bdrum_muted_m*.wav", dict(pitched=False, sustain=False, attack=0.001, release=0.5, pan=0.0, width=0.5, gain=1.3)),
    "tamb": ("Percussion/Tamb1-Hit_*.wav", dict(pitched=False, sustain=False, attack=0.001, release=0.4, pan=0.45, width=0.3, gain=0.4)),
    "snare_roll": ("Percussion/Snare2-rollSN_*.wav", dict(pitched=False, sustain=False, attack=0.05, release=0.5, pan=0.1, width=0.4, gain=0.25)),
    "bsn_stac": ("Woodwinds/Bassoon/stac/*.wav", dict(sustain=False, attack=0.002, release=0.2, pan=0.3, width=0.4, gain=0.75)),
    "vc_drone": ("Strings/Cello Section/susvib/*.wav", dict(attack=0.3, release=1.0, pan=0.3, width=0.5, gain=0.3)),
    # les mêmes pupitres, plus doux, pour les nappes qui accompagnent l'air sans le couvrir
    "vln_pad": ("Strings/Violin Section/susVib/*.wav", dict(attack=0.15, release=0.9, pan=-0.45, width=0.7, gain=0.32)),
    "vla_pad": ("Strings/Viola Section/susvib/*.wav", dict(attack=0.15, release=0.9, pan=0.15, width=0.6, gain=0.32)),
    "horn_pad": ("Brass/F Horn/sus/*.wav", dict(attack=0.1, release=0.7, pan=-0.25, width=0.6, gain=0.45)),
    # la nuit en mer : tout plus bas
    "vln_nuit": ("Strings/Solo Violin/Arco Vib/*.wav", dict(attack=0.12, release=0.9, pan=-0.2, width=0.4, gain=0.4)),
    "trem_nuit": ("Strings/Violin Section/Trem/*.wav", dict(attack=0.4, release=1.0, pan=-0.4, width=0.8, gain=0.24)),
    "cb_nuit": ("Strings/Solo Contrabass/SusVib/*.wav", dict(attack=0.3, release=1.0, pan=0.6, width=0.3, gain=0.4)),
}
EXTRA_WET = {"vln_nuit": 0.6, "trem_nuit": 0.6, "cb_nuit": 0.4, "vc_drone": 0.4, "vln_pad": 0.5, "vla_pad": 0.5, "horn_pad": 0.55, "solo_spic": 0.45, "cb_spic": 0.3, "stomp": 0.35, "tamb": 0.4, "snare_roll": 0.45, "bsn_stac": 0.35, "snare": 0.4,
             "bdrum": 0.4}


def register() -> None:
    cm.INSTR.update(EXTRA)
    cm.WET.update(EXTRA_WET)


def detache(P, key: str, bar: float, text: str, vel: float, octave: int = 0) -> None:
    """Une ligne jouée note à note, sans liaison (spiccato, staccato) : même écriture que
    Piece.melody (« E5:1 G5:0.5 | … », r = silence), chaque note attaquée franchement."""
    beat = 0.0
    for tok in text.replace("|", " ").split():
        p, d = tok.split(":")
        if p != "r":
            P.note(key, cm.midi_of(p) + 12 * octave, bar, beat, float(d), vel)
        beat += float(d)


def fiddle(P, bar: float, text: str, vel: float = 0.6, bite: float = 0.4, octave: int = 0, legato: float = 0.02) -> None:
    """Le violoneux : l'archet tenu (violon solo, notes liées) et, dessous, l'attaque sèche du
    spiccato qui donne le coup d'archet."""
    P.melody("solo_vln", bar, text, vel=vel, legato=legato, octave=octave)
    if bite > 0:
        detache(P, "solo_spic", bar, text, vel * bite, octave)


# =========================================================================== La Balafre

def stomp_bar(P, bar: int, sym: str, vel: float = 1.0, chop: bool = True, extra: bool = False, tamb: bool = False) -> None:
    """Une mesure « de pont » : les bottes sur 1 et 3, les basses en spiccato, les accords hachés
    sur 2 et 4 (altos et violons)."""
    syms = sym.split()
    _, _, r0 = cm.chord(syms[0])
    _, _, r1 = cm.chord(syms[-1])
    low0 = 28 + (r0 - 28) % 12
    low1 = 28 + (r1 - 28) % 12
    P.hit("stomp", bar, 0, 0.62 * vel, 1.0)
    P.hit("stomp", bar, 2, 0.48 * vel, 1.0)
    if extra:
        P.hit("stomp", bar, 2.5, 0.32 * vel, 0.5)
    P.note("cb_spic", low0, bar, 0, 0.9, 0.55 * vel)
    P.note("vc_spic", low0 + 12, bar, 0, 0.9, 0.5 * vel)
    fifth = low1 + 7 if len(syms) == 1 else low1
    P.note("cb_spic", fifth, bar, 2, 0.9, 0.45 * vel)
    P.note("vc_spic", fifth + 12, bar, 2, 0.9, 0.42 * vel)
    if chop:
        for b, s in ((1, syms[0]), (3, syms[-1])):
            _, pcs, _ = cm.chord(s)
            for m in P._voicing("vla_spic", pcs, 55, 67, 2):
                P.note("vla_spic", m, bar, b, 0.45, 0.42 * vel)
            for m in P._voicing("vln_spic", pcs, 64, 76, 2):
                P.note("vln_spic", m, bar, b, 0.45, 0.32 * vel)
    if tamb:
        P.hit("tamb", bar, 1, 0.35 * vel, 0.5)
        P.hit("tamb", bar, 3, 0.4 * vel, 0.5)


def hey(P, bar: int, beat: float, vel: float = 1.0) -> None:
    """« Hé ! » : tout l'équipage frappe en même temps (bottes, caisse claire, cordes graves, cors)."""
    P.hit("stomp", bar, beat, 0.75 * vel, 1.0)
    P.hit("bdrum", bar, beat, 0.4 * vel, 1.0)
    P.hit("snare", bar, beat, 0.45 * vel, 0.5)
    P.note("cb_spic", 40, bar, beat, 0.5, 0.6 * vel)
    P.note("vc_spic", 52, bar, beat, 0.5, 0.55 * vel)
    for m in (59, 64, 71):
        P.note("horn", m, bar, beat, 0.35, 0.5 * vel, attack=0.02)


def balafre():
    P = cm.Piece("balafre", 116, 64, beats=4, loop=False, seed=681, room=2.4, extra=4.0)
    intro = ["Em", "Em", "Em", "B7"]
    A = ["Em", "Em", "D", "B7", "C", "D", "Am B7", "Em"]
    B = ["C", "G", "Am", "B7", "C", "G/B", "Am B7", "Em"]
    night = ["Em", "Cmaj7", "Am", "B7", "Em", "C", "D", "B7", "C", "Am", "B7", "B7"]
    build = ["Em", "Em", "C B7", "B7"]
    coda = ["Em", "C", "B7", "Em"]
    melA = ("B4:1 E5:0.5 E5:0.5 E5:1 F#5:0.5 G5:0.5 | F#5:0.5 E5:0.5 D5:0.5 B4:0.5 A4:1 B4:1 | "
            "A4:1 D5:0.5 D5:0.5 D5:1 E5:0.5 F#5:0.5 | E5:0.5 D#5:0.5 C5:0.5 B4:0.5 B4:2 | "
            "G5:1 G5:0.5 F#5:0.5 E5:1 G5:1 | F#5:1 F#5:0.5 E5:0.5 D5:1 F#5:1 | "
            "E5:0.5 D5:0.5 C5:0.5 B4:0.5 A4:0.5 C5:0.5 B4:0.5 D#5:0.5 | E5:1.5 B4:0.5 E5:1 r:1")
    melA2 = ("B4:0.5 B4:0.5 E5:0.5 E5:0.5 E5:1 F#5:0.5 G5:0.5 | A5:0.5 G5:0.5 F#5:0.5 D5:0.5 A4:1 D5:1 | "
             "A4:0.5 A4:0.5 D5:0.5 D5:0.5 D5:1 E5:0.5 F#5:0.5 | G5:0.5 F#5:0.5 E5:0.5 D#5:0.5 B4:2 | "
             "G5:1 G5:0.5 A5:0.5 B5:1 G5:1 | A5:1 A5:0.5 G5:0.5 F#5:1 D5:1 | "
             "E5:0.5 D5:0.5 C5:0.5 B4:0.5 A4:0.5 C5:0.5 B4:0.5 D#5:0.5 | E5:2 E4:1 r:1")
    melB = ("G5:1.5 G5:0.5 A5:1 G5:1 | B5:1.5 A5:0.5 G5:1 D5:1 | E5:1 A5:1 G5:0.5 F#5:0.5 E5:1 | F#5:2 D#5:1 r:1 | "
            "G5:1.5 G5:0.5 A5:1 B5:1 | C6:1 B5:0.5 A5:0.5 B5:1 G5:1 | A5:0.5 G5:0.5 F#5:0.5 E5:0.5 F#5:1 D#5:1 | E5:3 r:1")
    # le basson qui grommelle (introduction, montée)
    grumble = "E3:1 G3:0.5 F#3:0.5 E3:1 B2:1 | E3:1 G3:0.5 A3:0.5 B3:1 r:1 | C4:1 B3:0.5 A3:0.5 G3:1 F#3:1 | D#3:2 F#3:1 B2:1"
    counter = ("E3:2 G3:2 | B3:2 A3:1 G3:1 | F#3:2 A3:2 | D#3:2 F#3:2 | "
               "E3:2 G3:2 | F#3:2 A3:2 | A3:1 C4:1 B3:1 A3:1 | G3:2 B2:2")
    clar_ct = ("E5:2 C5:2 | D5:2 B4:2 | C5:2 E5:2 | D#5:2 B4:2 | E5:2 C5:2 | D5:2 G5:2 | E5:1 C5:1 D#5:2 | B4:4")
    night_vln = ("B4:2 E5:2 | E5:3 F#5:0.5 G5:0.5 | A5:2 C5:2 | B4:4 | B4:2 E5:2 | G5:3 F#5:1 | "
                 "F#5:2 A5:1 F#5:1 | D#5:4 | E5:2 G5:2 | C5:2 E5:2 | D#5:2 F#5:1 A5:1 | B5:4")
    night_clar = "r:4 | r:2 E4:1 G4:1 | r:4 | r:2 F#4:1 D#4:1 | r:4 | r:2 G4:1 E4:1 | r:4 | r:2 B3:1 D#4:1 | r:4 | r:4 | r:4 | r:4"

    # ---- introduction : les bottes seules, le bourdon, le basson
    for b, s in enumerate(intro):
        stomp_bar(P, b, s, vel=0.75 + 0.08 * b, chop=b >= 2)
    P.note("vc_drone", 40, 0, 0, 15.5, 0.4, attack=0.6)
    P.note("cb", 28, 0, 0, 15.5, 0.22, attack=0.6)
    P.melody("bsn", 0, grumble, vel=0.5, legato=0.03)
    P.hit("timp", 0, 0, 0.45, 2.0, midi=40)
    P.hit("timp", 2, 0, 0.45, 2.0, midi=40)
    P.hit("timp_roll", 3, 0, 0.3, 4.0, midi=47)

    # ---- A : le violoneux mène l'air
    for b, s in enumerate(A):
        stomp_bar(P, 4 + b, s, vel=0.85)
    fiddle(P, 4, melA, vel=0.58)
    P.pad("vla_pad", A, 4, 52, 64, 2, vel=0.15)

    # ---- A' : l'air varié, le basson répond
    for b, s in enumerate(A):
        stomp_bar(P, 12 + b, s, vel=0.9, tamb=b % 2 == 1)
    fiddle(P, 12, melA2, vel=0.6)
    P.melody("bsn", 12, counter, vel=0.42, legato=0.04)
    P.pad("horn_pad", A, 12, 52, 64, 2, vel=0.12)
    for b in range(12, 20, 2):
        P.hit("timp", b, 0, 0.35, 2.0, midi=40 if b % 4 == 0 else 47)

    # ---- B : le refrain, tout l'équipage
    for b, s in enumerate(B):
        stomp_bar(P, 20 + b, s, vel=1.0, extra=True, tamb=True)
    fiddle(P, 20, melB, vel=0.62)
    P.melody("clar", 20, clar_ct, vel=0.36, legato=0.04)
    P.pad("vln_pad", B, 20, 62, 76, 2, vel=0.2)
    P.pad("horn_pad", B, 20, 52, 64, 2, vel=0.15)
    P.hit("crash", 20, 0, 0.3)
    hey(P, 23, 3)
    hey(P, 27, 1.5, 0.9)

    # ---- la nuit en mer : la houle, la lune, le violon seul
    P.pad("trem_nuit", night, 28, 64, 79, 2, vel=0.15)
    P.bass("vc_drone", night, 28, 40, 52, vel=0.3)
    P.bass("cb_nuit", night, 28, 28, 40, vel=0.2)
    P.arp("harp", night, 28, 52, step=1.0, pattern=[0, 2, 4, 5, 4, 2], vel=0.14, span=2)
    P.melody("vln_nuit", 28, night_vln, vel=0.35, legato=0.06)
    P.melody("clar", 28, night_clar, vel=0.22, legato=0.04)
    P.sparkle("glock", night, 28, 79, 91, prob=0.18, vel=0.12, step=2.0)
    for b, v in ((31, 0.16), (35, 0.18), (38, 0.22)):
        P.hit("timp_roll", b, 0, v, 6.0, midi=40)
    P.hit("cymbal", 38, 0, 0.18)

    # ---- la montée : les bottes reviennent
    for b, s in enumerate(build):
        stomp_bar(P, 40 + b, s, vel=0.55 + 0.15 * b, chop=b >= 1)
        for k in range(8):
            P.note("vc_spic", 40, 40 + b, k * 0.5, 0.4, 0.28 + 0.05 * b)
    P.melody("bsn", 40, grumble, vel=0.48, legato=0.03)
    detache(P, "bsn_stac", 40, grumble, 0.35, octave=1)
    P.hit("snare_roll", 43, 0, 0.35, 4.0)
    P.hit("timp_roll", 43, 0, 0.3, 4.0, midi=47)

    # ---- A'' : l'air repart, la flûte à l'octave, la clarinette en contre-chant
    for b, s in enumerate(A):
        stomp_bar(P, 44 + b, s, vel=1.0, tamb=True)
        if b % 2 == 1:
            P.hit("snare", 44 + b, 3, 0.18, 0.5)
    fiddle(P, 44, melA, vel=0.62)
    P.melody("flute", 44, melA, vel=0.4, octave=1, legato=0.02)
    P.melody("clar", 44, counter, vel=0.32, octave=1, legato=0.04)
    P.pad("horn_pad", A, 44, 52, 64, 2, vel=0.18)
    P.hit("crash", 44, 0, 0.32)

    # ---- B' : le refrain, la trompette avec le violon
    for b, s in enumerate(B):
        stomp_bar(P, 52 + b, s, vel=1.05, extra=True, tamb=True)
    fiddle(P, 52, melB, vel=0.64)
    P.melody("trp", 52, melB, vel=0.32, octave=-1, legato=0.03)
    P.melody("clar", 52, clar_ct, vel=0.3, legato=0.04)
    P.pad("vln_pad", B, 52, 62, 76, 2, vel=0.25)
    P.pad("tbn", B, 52, 48, 60, 2, vel=0.1)
    P.hit("crash", 52, 0, 0.3)
    hey(P, 55, 3)
    hey(P, 59, 1.5)

    # ---- la fin : un dernier tour de pont, et le coup de botte final
    for b, s in enumerate(coda[:3]):
        stomp_bar(P, 60 + b, s, vel=1.0, extra=True)
    fiddle(P, 60, "E5:0.5 F#5:0.5 G5:0.5 A5:0.5 B5:1 E6:1 | C6:0.5 B5:0.5 A5:0.5 G5:0.5 F#5:1 E5:1 | "
                  "D#5:0.5 E5:0.5 F#5:0.5 A5:0.5 B5:2 | E5:1 r:3", vel=0.64)
    P.melody("flute", 60, "r:4 | r:4 | r:2 B5:2 | E6:1 r:3", vel=0.3)
    P.pad("horn_pad", ["Em", "C", "B7"], 60, 52, 64, 2, vel=0.2)
    hey(P, 63, 0, 1.1)
    P.hit("crash", 63, 0, 0.35)
    P.hit("timp", 63, 0, 0.55, 2.0, midi=40)
    P.note("cb", 28, 63, 0, 2.0, 0.3)
    P.note("vc_drone", 40, 63, 0, 2.0, 0.5)
    P.hit("stomp", 63, 2, 0.7, 1.0)
    return P


# =========================================================================== La Gigue du Crâne

class Jig(cm.Piece):
    """Une gigue : dans chaque groupe de trois croches, la deuxième et la troisième arrivent un
    rien en retard (le « balancé » des violoneux)."""

    def t(self, bar: float, beat: float = 0.0) -> float:
        pos = beat % 3.0
        lilt = float(np.interp(pos, [0.0, 1.0, 2.0, 3.0], [0.0, 0.08, 0.035, 0.0]))
        return (bar * self.beats + beat + lilt) * self.spb


def gigue_crane():
    P = Jig("gigue_crane", 336, 68, beats=6, seed=682, room=1.5)
    A = ("A4:2 B4:1 C5:1 B4:1 A4:1 | G4:2 A4:1 B4:1 A4:1 G4:1 | E5:1 A4:1 A4:1 E5:1 A4:1 A4:1 | G5:2 E5:1 D5:1 B4:1 G4:1 | "
         "A4:2 B4:1 C5:1 B4:1 A4:1 | G4:2 A4:1 B4:1 C5:1 D5:1 | E5:1 G5:1 E5:1 D5:1 B4:1 G4:1 | A4:3 A4:2 E4:1")
    A_end = ("A4:2 B4:1 C5:1 B4:1 A4:1 | G4:2 A4:1 B4:1 A4:1 G4:1 | E5:1 A4:1 A4:1 E5:1 A4:1 A4:1 | G5:2 E5:1 D5:1 B4:1 G4:1 | "
             "A4:2 B4:1 C5:1 B4:1 A4:1 | G4:2 A4:1 B4:1 C5:1 D5:1 | E5:1 G5:1 E5:1 D5:1 B4:1 G4:1 | A4:3 A4:2 E5:1")
    B = ("A5:2 E5:1 A5:1 B5:1 A5:1 | G5:2 D5:1 G5:1 A5:1 G5:1 | E5:1 F#5:1 G5:1 A5:1 G5:1 E5:1 | F#5:1 D5:1 F#5:1 A5:2 F#5:1 | "
         "A5:2 E5:1 A5:1 B5:1 C6:1 | B5:1 A5:1 G5:1 A5:1 G5:1 E5:1 | D5:1 E5:1 G5:1 E5:1 D5:1 B4:1 | A4:3 A4:2 E5:1")
    B_end = B.rsplit("|", 1)[0] + "| A4:3 A4:2 E4:1"
    # le second tour : des variantes, des notes plus hautes
    A2 = ("A4:2 B4:1 C5:1 D5:1 E5:1 | G4:2 A4:1 B4:1 D5:1 G5:1 | E5:1 A4:1 A4:1 E5:1 F#5:1 G5:1 | A5:2 G5:1 E5:1 D5:1 B4:1 | "
          "A4:2 B4:1 C5:1 B4:1 A4:1 | G4:2 A4:1 B4:1 C5:1 D5:1 | E5:1 G5:1 B5:1 A5:1 G5:1 E5:1 | A4:3 A4:2 E4:1")
    A2_end = A2.rsplit("|", 1)[0] + "| A4:3 A4:2 E5:1"
    B2 = ("A5:2 E5:1 A5:1 B5:1 A5:1 | G5:2 D5:1 G5:1 A5:1 B5:1 | E5:1 F#5:1 G5:1 A5:1 B5:1 C6:1 | D6:1 A5:1 F#5:1 D6:2 A5:1 | "
          "A5:2 E5:1 A5:1 C6:1 E6:1 | D6:1 C6:1 B5:1 A5:1 G5:1 E5:1 | D5:1 E5:1 G5:1 B5:1 A5:1 G5:1 | A5:3 A5:2 E5:1")
    B2_end = B2.rsplit("|", 1)[0] + "| A5:3 A4:3"
    # introduction (2 mesures : la botte, le bourdon, une levée), puis AABB deux fois, puis 2 mesures de fin
    detache(P, "solo_spic", 1, "r:5 E4:1", 0.25)
    P.melody("solo_vln", 1, "r:5 E4:1", vel=0.5, legato=0.02)
    order = [(2, A, 0.6), (10, A_end, 0.6), (18, B, 0.62), (26, B_end, 0.62),
             (34, A2, 0.64), (42, A2_end, 0.62), (50, B2, 0.66), (58, B2_end, 0.64)]
    for bar, text, v in order:
        fiddle(P, bar, text, vel=v, bite=0.42)
    # les doubles cordes du second tour : la corde de la (à vide) qui sonne sous l'air
    for bar in (34, 36, 38, 42, 44, 46):
        P.note("solo_vln", 69, bar, 0, 2.6, 0.22, attack=0.03)
    for bar in (50, 54, 58, 62):
        P.note("solo_vln", 76, bar, 0, 2.6, 0.2, attack=0.03)
    # la fin du tour : une dernière phrase, qui retombe sur la levée du début
    fiddle(P, 66, "A5:1 G5:1 E5:1 D5:1 B4:1 G4:1 | A4:3 r:3", vel=0.6)
    # le bourdon des violoncelles : la et mi, repris toutes les deux mesures
    for bar in range(0, 68, 2):
        under_d = bar in (20, 28, 52, 60)
        P.note("vc_drone", 45, bar, 0, 12.3, 0.3 if bar >= 2 else 0.2, attack=0.35)
        P.note("vc_drone", 50 if under_d else 52, bar, 0, 12.3, 0.2, attack=0.4)
    # la botte de Tom sur les planches (et, au second tour, le talon sur le contretemps)
    for bar in range(68):
        P.hit("stomp", bar, 0, 0.4 if bar % 2 == 0 else 0.34, 1.0)
        P.hit("stomp", bar, 3, 0.3, 1.0)
        if 34 <= bar < 66 and bar % 2 == 1:
            P.hit("stomp", bar, 5, 0.18, 0.5)
    return P


PIECES = {"balafre": (balafre, -21.0), "gigue_crane": (gigue_crane, -22.0)}


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cm.VSCO = Path(sys.argv[1])
    cm.TMP.mkdir(parents=True, exist_ok=True)
    register()
    for name in sys.argv[2:] or list(PIECES):
        fn, rms = PIECES[name]
        fn().render(cm.OUT / f"{name}.ogg", rms_db=rms)


if __name__ == "__main__":
    main()
