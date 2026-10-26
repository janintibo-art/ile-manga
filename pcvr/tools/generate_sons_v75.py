"""V75 : les sons de l'Île du Boucan : Port-Boucan, la ville libre des punks (squats, la Halle Hurlante,
Radio Boucan, le skatepark, les murs de graffitis, les jardins, des chiens partout), la Cathédrale des
Spores (les champignons féeriques et les champignards), la Casse, le port, et l'Usine Grise de
« Lisse & Fils » (les robots déménageurs, polis mais têtus, et la Grande Pelleteuse). Ton : joyeux,
chaleureux, drôle, tout public.

Bruitages (sfx/, mono) :
  robot_bip_1..3          un robot poli qui bipe (« bi-dou-bip ! ») : petites notes qui glissent ;
  robot_servo_1..3        un servomoteur qui tourne (le bras, la tête, la pince) ;
  robot_pas_1..3          un robot qui avance : chenilles qui claquent (1, 2), un gros pas de métal (3) ;
  robot_mort_1..2         un robot qui s'éteint : la plainte qui descend, « piou », et les boulons qui
                          tombent et rebondissent ;
  robot_voix_1..3         un robot qui « parle » : une phrase de bips qui a l'air d'une phrase polie
                          (aucun vrai mot) ;
  drone_vol_1             le bourdonnement d'un petit drone (boucle de 2 s sans raccord) ;
  drone_zap_1..2          un drone qui grésille (« bzzt ! ») ;
  soudure_1..2            l'arc d'un poste à souder qui crépite ;
  vapeur_3..4             un jet de vapeur (vapeur_1 et _2 existaient déjà : on continue la numérotation) ;
  pelleteuse_cri_1..2     la Grande Pelleteuse : énorme rugissement hydraulique, le moteur qui monte,
                          la ferraille qui gémit ;
  pelleteuse_frappe_1..3  le godet qui s'écrase sur le béton : le choc, le béton qui craque, les gravats ;
  durite_1..2             une durite hydraulique qui éclate (« pof ! pshhhh… ») ;
  tapis_roulant_1         un tapis roulant (boucle de 3 s sans raccord) ;
  tampon_bureau_1..2      le tampon de Mademoiselle Prune (guilde_tampon existait déjà : autre nom) ;
  photocopieuse_1..2      une photocopieuse comique (moteur, lumière qui balaie, « clac », la feuille) ;
  alarme_usine_1..2       la sirène d'alarme de l'usine, courte ;
  champignard_pouf_1..3   un champignard qui lâche ses spores (« pouf ! », doux et drôle) ;
  champignard_rire_1..3   un champignard qui rigole (petits couinements, aucun mot) ;
  eternuement_1..2        un petit éternuement comique (« a… a… atchoum ! », sans mot) ;
  champi_boing_1..2       le ressort du Bolet-Ressort (« boïng ») ;
  champi_magie_1..2       on mange un champignon féerique : carillon qui scintille et monte ;
  champi_fin_1..2         l'effet s'arrête : carillon doux qui descend ;
  aboiement_1..4          un chien joyeux qui aboie ;
  aboiement_petit_1..3    un petit chien qui jappe ;
  chat_miaou_1..3         un chat qui miaule ;
  pigeon_1..2             un pigeon qui roucoule ;
  sirene_alerte_1..2      la vieille sirène à manivelle qui monte et redescend (~4 s) ;
  radio_jingle_1..2       le jingle de Radio Boucan (synthé, batterie, sans paroles) ;
  radio_gresillement_1..2 la radio qu'on cherche sur le cadran : grésillements, sifflements ;
  bombe_peinture_1..2     une bombe de peinture qu'on secoue (la bille qui cliquette) puis qui pschitte ;
  grue_1..2               le treuil de la grue : le cliquet, le moteur, le câble qui grince ;
  skate_1..3              une planche à roulettes : elle roule, « clac » (le ollie), elle retombe ;
  pogo_1..2               la fosse qui saute : « boum-boum » de tout le monde, des cris ;
  foule_acclame_1..2      la foule qui acclame après une chanson ;
  larsen_micro_1..2       un petit larsen de micro, comique et doux (pas douloureux, joué bas) ;
  guitare_riff_1..3       une fioriture de guitare saturée (Germaine-la-Terrible) ;
  batterie_roulement_1..2 un roulement de batterie ;
  cymbale_1..2            une cymbale crash ;
  monte_charge_1..2       le monte-charge : il démarre, monte en grondant, s'arrête (« ding ») ;
  tourniquet_1..2         un tourniquet d'entrée (cliquet et « clonk ») ;
  vanne_1..2              un volant de vanne qui grince, et ce qui s'en échappe ;
  porte_usine_1..2        la lourde porte coulissante de l'usine.
Nappes d'ambiance (ambiance/, stéréo, boucles de 60 s sans raccord) :
  boucan_jour    la ville-friche le jour : on parle et on rit, de la musique qui sort d'une fenêtre,
                 des marteaux dans les ateliers, un skate, des chiens au loin, les mouettes, une
                 sonnette de vélo, l'eau du port ;
  boucan_nuit    la nuit : le concert étouffé à travers les murs, les grillons de la friche, un chien,
                 le vent dans la ferraille, l'eau du port ;
  halle          la Halle entre deux chansons : la foule qui parle, les verres de limonade, le
                 ronflement des amplis, la bassiste qui s'accorde, une baguette qui tapote ;
  spores         la Cathédrale des Spores : le vent tout là-haut dans la charpente d'acier, des
                 scintillements, des résonances graves et lentes, des gouttes, un souffle tranquille ;
  casse          la Casse : le vent dans les carcasses, la tôle qui grince, un chalumeau au loin, les
                 corneilles ;
  usine          l'usine : le ronron des machines, des presses au loin, la vapeur, des bips ;
  port_boucan    les quais : mouettes, l'eau contre la pierre, les chaînes, une grue au loin, les amarres.
Synthétisés ici (domaine public), ou retravaillés (découpés, transposés, filtrés, réverbérés) d'après :
le recueil CC0 « lavenderdotpet/CC0-Public-Domain-Sounds » (packs Kenney Impact, Voiceover et Voiceover Fighter,
« 80 CC0 creature SFX », « 100 CC0 wood/metal SFX », « 100 CC0 SFX », « 75 CC0 breaking/falling/hit »,
« Micro Pack - Cat Meows » et « BB Retail Therapy Sample Pack » (Ben Burnes), les rires de « Free Retro
Arcade Sounds » (The Motion Monkey)) ; l'enregistrement « wind-breeze » (keweldog), CC0, via
github.com/DNAABR/ambient-sounds-library ; la banque
VSCO-2 CE (Versilian Studios, CC0 : glockenspiel, cloche de vache, enclume) ; la « Versilian Community
Sample Library » (VCSL, Versilian Studios, CC0 : batterie, cymbales, claquements de mains, carillons à
main, arbres à clochettes). Les guitares, la basse et la batterie viennent de compose_musique_v75.py
(cordes de Karplus-Strong et ampli simulé, fûts de la VCSL).
Chaque son a ses propres graines (tirées de son nom) : on peut n'en refaire qu'un, il sort à
l'identique.
Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/generate_sons_v75.py [dossier CC0-Public-Domain-Sounds] [noms...]
(les banques VSCO-2-CE et VCSL et le dossier « dl » des enregistrements sont cherchés à côté du recueil)
"""
from pathlib import Path
import sys
import zlib

import numpy as np
from scipy import signal

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v71 as s71  # noqa: E402
import generate_sons_v70 as s70  # noqa: E402
import generate_sons_v69 as s69  # noqa: E402
import generate_sons_v68 as s68  # noqa: E402
import generate_sons_v63 as s63  # noqa: E402
import generate_sons_v61 as s61  # noqa: E402
import generate_sons_v59 as s59  # noqa: E402
import generate_sons_v56 as s56  # noqa: E402
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402
import compose_musique_v75 as m75  # noqa: E402

SR = 44100
RNG = np.random.default_rng(7575)
VSCO = s63.LIB.parent / "VSCO-2-CE"
VCSL = s63.LIB.parent / "VCSL"
DL = s63.LIB.parent / "dl"

_t, _norm, _fade, noise, rec = s63._t, s63._norm, s63._fade, s63.noise, s63.rec
trim, cut, unit, addp, clip_rec = s68.trim, s68.cut, s68.unit, s68.addp, s68.clip_rec
clack, thump, formants, wplace, room_wrap = s68.clack, s68.thump, s68.formants, s68.wplace, s68.room_wrap
scatter, loop_layer, finish_bed, shout, modal, glottal = s68.scatter, s68.loop_layer, s68.finish_bed, s68.shout, s68.modal, s68.glottal
syllabe, crepite, sifflement, bouffee, tinte, etincelles = s70.syllabe, s70.crepite, s70.sifflement, s70.bouffee, s70.tinte, s70.etincelles
place_st, pan_move, room, finish, servo, bronze = s70.place_st, s70.pan_move, s70.room, s70.finish, s70.servo, s70.bronze
lp, hp, bp, texture = s70.lp, s70.hp, s70.bp, s70.texture

KI = "kenney_impactsounds/Audio/"
WM = "100-CC0-wood-metal-SFX/"
SX = "100-CC0-SFX/"
BBR = "BB_Retail Therapy Sample Pack/"
CRE = "80-CC0-creature-SFX/"
BFH = "75-cc0-breaking-falling-hit-sfx/"
CAT = "Micro Pack - Cat Meows/Cat Meows - "


# =================================================================== outils

def _read_any(path: Path) -> np.ndarray:
    """Comme generate_sons_v49.read_any (wav/ogg -> (n, 2) flottant à 44,1 kHz, normalisé), mais le
    fichier wav intermédiaire est effacé (les anciens outils le laissaient dans /tmp)."""
    import subprocess
    import tempfile
    from scipy.io import wavfile
    with tempfile.TemporaryDirectory() as d:
        w = Path(d) / "x.wav"
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(path), "-ac", "2", "-ar", str(SR), str(w)], check=True)
        _, x = wavfile.read(w)
    x = x.astype(np.float64)
    return x / (np.max(np.abs(x)) + 1e-9)


amb.read_any = _read_any       # (pour tous les outils appelés d'ici : rien n'est modifié dans leurs fichiers)


def save_sfx(name: str, x: np.ndarray) -> None:
    """Comme generate_bruitages_v50.save (Ogg Vorbis q4, mono), sans laisser de wav dans /tmp."""
    import subprocess
    import tempfile
    from scipy.io import wavfile
    fx.OUT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as d:
        w = Path(d) / "x.wav"
        wavfile.write(w, SR, (np.clip(x, -1, 1) * 32767).astype(np.int16))
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(w), "-c:a", "libvorbis", "-q:a", "4", str(fx.OUT / f"{name}.ogg")],
                       check=True)


def reseed(name: str, k: int = 0) -> None:
    """Chaque son a ses propres graines (tirées de son nom) : refaire un seul son le redonne à l'identique."""
    global RNG
    base = [7575, zlib.crc32(name.encode()), k]
    RNG = np.random.default_rng(base + [0])
    s71.RNG = np.random.default_rng(base + [9])
    s70.RNG = np.random.default_rng(base + [8])
    s69.RNG = np.random.default_rng(base + [1])
    s68.RNG = np.random.default_rng(base + [2])
    s63.RNG = np.random.default_rng(base + [3])
    s61.RNG = np.random.default_rng(base + [7])
    s59.RNG = np.random.default_rng(base + [4])
    s56.RNG = np.random.default_rng(base + [5])
    amb.RNG = np.random.default_rng(base + [6])


def mix(dur: float, *parts) -> np.ndarray:
    """Pose des sons (son, instant, gain) dans un tampon de dur secondes (ce qui dépasse est coupé)."""
    out = np.zeros(int(dur * SR))
    for x, at, g in parts:
        i = int(at * SR)
        if 0 <= i < len(out) and len(x):
            amb.place(out, np.asarray(x, float), i, g)
    return out


def nz(n: int) -> np.ndarray:
    return RNG.standard_normal(n)


def env_ad(n: int, a: float, d: float) -> np.ndarray:
    x = np.arange(n) / SR
    return np.clip(x / max(a, 1e-4), 0, 1) * np.exp(-x / d)


def chirp(f, dur: float, harm=(1.0, 0.3), att: float = 0.005, rel: float = 0.03) -> np.ndarray:
    """Un son pur dont la hauteur suit les points f, quelques harmoniques, attaque et chute douces."""
    x = _t(dur)
    fp = np.asarray(f, float)
    ff = np.interp(x, np.linspace(0, dur, len(fp)), fp)
    ph = 2 * np.pi * np.cumsum(ff) / SR
    y = sum(a * np.sin((i + 1) * ph) for i, a in enumerate(harm))
    return y * np.clip(x / att, 0, 1) * np.clip((dur - x) / rel, 0, 1)


def first_event(x: np.ndarray, thr: float = 0.12, gap: float = 0.12, pad: float = 0.03) -> np.ndarray:
    """Le premier « événement » d'un enregistrement (un miaulement, un aboiement) : du premier passage
    au-dessus du seuil jusqu'au premier silence assez long."""
    w = int(0.01 * SR)
    e = np.sqrt(np.convolve(x ** 2, np.ones(w) / w, "same"))
    on = e > e.max() * thr
    if not on.any():
        return x
    i = int(np.argmax(on))
    j = i
    quiet = 0
    while j < len(x):
        quiet = quiet + 1 if not on[j] else 0
        if quiet > gap * SR:
            break
        j += 1
    return _fade(x[max(0, i - int(pad * SR)):min(len(x), j - int(gap * SR) + int(pad * SR))], 0.004, 0.04)


def loudest(x: np.ndarray, dur: float, lo: float, hi: float) -> np.ndarray:
    """Le moment le plus fort d'un enregistrement dans une bande (un miaulement entier, par exemple) :
    la fenêtre de dur secondes la plus chargée, recentrée sur son début, avec fondus."""
    n = int(dur * SR)
    if len(x) <= n:
        return _fade(x, 0.004, 0.05)
    e = bp(x, lo, hi) ** 2
    c = np.concatenate([[0.0], np.cumsum(e)])
    i = int(np.argmax(c[n:] - c[:-n]))
    w = int(0.01 * SR)
    seg = e[i:i + n]
    env = np.sqrt(np.convolve(seg, np.ones(w) / w, "same"))
    on = np.nonzero(env > env.max() * 0.08)[0]
    a = i + (int(on[0]) if len(on) else 0)
    b = i + (int(on[-1]) if len(on) else n)
    return _fade(x[max(0, a - int(0.02 * SR)):min(len(x), b + int(0.08 * SR))], 0.004, 0.06)


def vsco_pc(rel: str) -> np.ndarray:
    """Un échantillon de VSCO-2 CE ou de la VCSL (mono)."""
    for root in (VSCO, VCSL):
        p = root / rel
        if p.is_file():
            return amb.read_any(p).mean(axis=1)
    return np.zeros(int(0.1 * SR))


_KIT = {}


def kit() -> "m75.Kit":
    if "k" not in _KIT:
        m75.VCSL, m75.VSCO = VCSL, VSCO
        _KIT["k"] = m75.Kit(seed=7575)
    return _KIT["k"]


def loop_seamless(x: np.ndarray, fade: float = 0.25) -> np.ndarray:
    """Une boucle courte sans raccord : la fin fondue dans le début (puissance constante)."""
    return amb.loopify(x, fade)


# =================================================================== les robots de Lisse & Fils

def beep(f0: float, f1: float, dur: float, sq: float = 0.25) -> np.ndarray:
    """Un bip de robot poli : un son presque pur, un rien carré, qui glisse de f0 à f1."""
    x = _t(dur)
    f = f0 * (f1 / f0) ** np.clip(x / max(dur * 0.6, 1e-3), 0, 1)
    ph = 2 * np.pi * np.cumsum(f) / SR
    y = np.sin(ph) + sq * np.tanh(4 * np.sin(ph)) * 0.5 + 0.15 * np.sin(2 * ph)
    return y * np.clip(x / 0.006, 0, 1) * np.clip((dur - x) / 0.025, 0, 1)


def robot_bip(k: int) -> np.ndarray:
    seqs = [[(880, 1320, 0.09), (0, 0, 0.04), (1320, 1760, 0.12)],
            [(1046, 1046, 0.07), (1318, 1318, 0.07), (1568, 2093, 0.16)],
            [(1500, 1100, 0.1), (0, 0, 0.05), (990, 1480, 0.08), (1480, 1480, 0.06), (0, 0, 0.03), (1760, 1980, 0.11)]][k]
    parts = []
    for f0, f1, d in seqs:
        parts.append(np.zeros(int(d * SR)) if f0 == 0 else beep(f0, f1, d))
    y = np.concatenate(parts + [np.zeros(int(0.15 * SR))])
    y = y + 0.08 * lp(nz(len(y)), 3000) * np.clip(np.abs(y) * 4, 0, 1)
    y = room(y, 0.3, 14.0, 7000.0, 0.08, seed=7501 + k)
    return finish(y, 0.89, 0.08)


def gears(dur: float, rate: float = 60.0, f: float = 3000.0) -> np.ndarray:
    """Le cliquetis fin des engrenages d'un moteur."""
    n = int(dur * SR)
    imp = (RNG.random(n) < rate / SR).astype(float) * RNG.uniform(0.3, 1.0, n)
    ker = np.sin(2 * np.pi * f * np.arange(int(0.01 * SR)) / SR) * np.exp(-np.arange(int(0.01 * SR)) / (0.0015 * SR))
    return np.convolve(imp, ker)[:n]


def robot_servo(k: int) -> np.ndarray:
    d = [0.55, 0.9, 0.7][k]
    f0, f1 = [(240.0, 420.0), (380.0, 200.0), (300.0, 520.0)][k]
    y = unit(servo(d, f0, f1)) * 0.7
    y = addp(y, unit(gears(d, 90, 2600)) * 0.15)
    if k == 1:          # un aller-retour
        y = np.concatenate([y, unit(servo(0.45, f1, f0 * 1.1)) * 0.6])
    stop = unit(clack(RNG.uniform(1500, 2300), 0.015, 0.8, 0.3)) * 0.4
    out = addp(y, np.concatenate([np.zeros(len(y) - int(0.02 * SR)), stop]))
    out = room(out, 0.3, 14.0, 6000.0, 0.06, seed=7511 + k)
    return finish(out, 0.89, 0.06)


def chenille(dur: float, rate: float = 14.0) -> np.ndarray:
    """Les chenilles : les patins qui claquent sur le sol, les galets qui grincent."""
    n = int(dur * SR)
    out = np.zeros(n)
    t = 0.0
    while t < dur - 0.05:
        c = unit(clack(RNG.uniform(900, 1500), 0.012, 0.6, 0.5)) * RNG.uniform(0.5, 1.0)
        amb.place(out, c, int(t * SR), 1.0)
        t += 1.0 / rate * RNG.uniform(0.9, 1.1)
    rumble = lp(nz(n), 180) * 0.6
    whine = unit(servo(dur, 160.0, 175.0)) * 0.25
    return out * 0.6 + rumble * 0.3 + whine


def robot_pas(k: int) -> np.ndarray:
    if k < 2:
        d = [1.1, 1.4][k]
        y = chenille(d, [13.0, 17.0][k])
        y = addp(y, clip_rec(KI + "impactMetal_light_00%d.ogg" % (k + 1), -4.0, 0.4) * 0.5)
        x = np.arange(len(y)) / SR
        y *= np.clip(x / 0.08, 0, 1) * np.clip((d - x) / 0.15, 0, 1)
    else:
        y = s70.automate_pas(1)
        y = addp(y, np.concatenate([np.zeros(int(0.16 * SR)), unit(gears(0.3, 120, 3500)) * 0.15]))
    out = room(y, 0.4, 10.0, 5000.0, 0.08, seed=7521 + k)
    return finish(out, 0.89, 0.12)


def boulons(t0: float, count: int, spread: float = 1.2) -> list:
    """Des boulons et des ressorts qui tombent et rebondissent sur le béton."""
    parts = []
    for _ in range(count):
        t = t0 + RNG.exponential(spread / 3)
        f = RNG.uniform(2200, 5200)
        g = RNG.uniform(0.15, 0.35)
        gap = RNG.uniform(0.08, 0.18)
        for b in range(int(RNG.integers(2, 5))):
            parts.append((tinte(f, RNG.uniform(0.01, 0.03), 0.8), t, g))
            t += gap
            gap *= 0.6
            g *= 0.55
    return parts


def robot_mort(k: int) -> np.ndarray:
    dur = [2.8, 2.4][k]
    parts = [(unit(servo([1.1, 0.8][k], [520.0, 400.0][k], 70.0)), 0.0, 0.45),
             (unit(beep(1300, 500, 0.35, 0.1)), [1.0, 0.7][k], 0.35),          # « piou »
             (unit(thump(80.0, 45.0, 0.1, 0.5)), [1.15, 0.85][k], 0.7),
             (clip_rec(KI + "impactMetal_heavy_00%d.ogg" % [1, 3][k], -4.0, 0.6), [1.15, 0.85][k], 0.6),
             (unit(sifflement(0.8, 2500, 8000, 0.01, 0.6)), [1.2, 0.9][k], 0.15)]
    parts += boulons([1.2, 0.95][k], [10, 7][k])
    if k == 1:
        parts.append((clip_rec(WM + "metal_spring_01.ogg", -2.0, 0.8), 1.0, 0.3))
    out = mix(dur, *parts)
    out = room(out, 0.7, 6.0, 6000.0, 0.1, seed=7531 + k)
    return finish(out, 0.89, 0.3)


def robot_voix(k: int) -> np.ndarray:
    """Une « phrase » de robot : des syllabes de bips (voix synthétique très simple, en marches
    d'escalier, modulée en anneau) qui ont le rythme d'une phrase polie, sans aucun mot."""
    plans = [  # (durée, hauteur relative, voyelle)
        [(0.12, 1.0, "o"), (0.1, 1.12, "a"), (0.16, 1.0, "é"), (0.06, 0, None), (0.1, 0.94, "i"), (0.12, 1.06, "a"), (0.22, 1.25, "é")],
        [(0.1, 1.2, "i"), (0.1, 1.2, "o"), (0.12, 1.0, "a"), (0.06, 0, None), (0.12, 1.0, "o"), (0.1, 0.9, "é"), (0.1, 0.85, "a"), (0.24, 0.75, "o")],
        [(0.08, 1.0, "a"), (0.08, 1.05, "é"), (0.08, 1.1, "i"), (0.08, 1.0, "o"), (0.05, 0, None), (0.1, 1.3, "a"), (0.1, 1.2, "é"), (0.2, 1.0, "o"),
         (0.05, 0, None), (0.14, 1.4, "i")],
    ][k]
    f0 = [210.0, 190.0, 240.0][k]
    parts = []
    for d, r, v in plans:
        n = int(d * SR)
        if v is None:
            parts.append(np.zeros(n))
            continue
        x = np.arange(n) / SR
        f = np.full(n, f0 * r)
        src = glottal(f, tilt=0.6, fmax=6000.0)
        src = src / (np.std(src) + 1e-9)
        y = formants(src, s68._vow(v, 1.15))
        y *= np.sin(2 * np.pi * 55.0 * x) * 0.5 + 0.7          # modulation en anneau : la voix de métal
        y *= np.clip(x / 0.008, 0, 1) * np.clip((d - x) / 0.012, 0, 1)
        parts.append(unit(y))
    y = np.concatenate(parts)
    y = np.round(y * 24) / 24                                   # un peu d'« électronique »
    y = lp(y, 5500)
    tail = beep(1500, 2000, 0.1)
    y = np.concatenate([y, np.zeros(int(0.06 * SR)), tail * 0.5, np.zeros(int(0.12 * SR))])
    y = room(y, 0.25, 16.0, 7000.0, 0.06, seed=7541 + k)
    return finish(y, 0.89, 0.06)


def drone_vol(k: int) -> np.ndarray:
    """Un petit drone : quatre hélices (le bourdon, le battement des pales) : boucle de 2 s exactement
    (toutes les fréquences font un nombre entier de tours en 2 s : aucun raccord)."""
    dur = 2.0
    n = int(dur * SR)
    x = np.arange(n) / SR
    y = np.zeros(n)
    for f, a in ((182.0, 1.0), (191.5, 0.8), (176.0, 0.7), (199.0, 0.6)):
        fq = round(f * dur) / dur
        ph = 2 * np.pi * fq * x
        y += a * (np.sin(ph) + 0.5 * np.sin(2 * ph) + 0.3 * np.sin(3 * ph) + 0.2 * np.sin(5 * ph))
    am = 1 + 0.15 * np.sin(2 * np.pi * (round(9.0 * dur) / dur) * x)
    y = y * am
    air = nz(n)
    y = y / np.max(np.abs(y)) + 0.25 * air
    y = np.concatenate([y[-SR // 2:], y])
    y = bp(y, 120, 6000)[SR // 2:]                               # filtré « en boucle » (amorcé par la fin)
    return _norm(y, 0.89)


def drone_zap(k: int) -> np.ndarray:
    dur = [0.9, 1.2][k]
    n = int(dur * SR)
    x = np.arange(n) / SR
    buzz = np.sign(np.sin(2 * np.pi * np.cumsum(np.interp(x, [0, dur], [140.0, 60.0])) / SR)) * np.exp(-x / 0.35)
    parts = [(unit(lp(buzz, 4000)), 0.0, 0.45), (unit(crepite(dur * 0.7, 900, 1500, 9000)), 0.0, 0.6),
             (unit(beep(2400, 600, 0.18, 0.6)), 0.02, 0.35), (unit(etincelles(0.5, 10, 3000, 8000)), 0.05, 0.3)]
    if k == 1:
        parts += [(unit(crepite(0.4, 1200, 1500, 9000)), 0.6, 0.5), (unit(beep(1800, 300, 0.3, 0.6)), 0.62, 0.3)]
    out = mix(dur + 0.3, *parts)
    return finish(room(out, 0.3, 14.0, 8000.0, 0.06, seed=7551 + k), 0.89, 0.1)


def soudure(k: int) -> np.ndarray:
    """Un poste à souder : l'arc qui crépite et grésille, le bourdon du poste."""
    dur = [2.6, 3.4][k]
    n = int(dur * SR)
    x = np.arange(n) / SR
    rate = lambda xx: 1800 + 1400 * (0.5 + 0.5 * np.sin(2 * np.pi * 1.7 * xx + 1.3))
    arc = unit(crepite(dur, rate, 1200, 10000))
    sizzle = sifflement(dur, 3000, 11000, 0.02, 0.1, 0.6) * 0.5
    hum = (np.sign(np.sin(2 * np.pi * 100 * x)) * 0.3 + np.sin(2 * np.pi * 100 * x)) * 0.05
    y = arc * 0.8 + unit(sizzle) * 0.35 + lp(hum, 1200)
    y *= np.clip(x / 0.03, 0, 1) * np.clip((dur - x) / 0.08, 0, 1)
    if k == 1:              # on relâche, on reprend
        gate = np.where((x > 1.5) & (x < 1.85), 0.0, 1.0)
        y *= lp(gate, 60)
    y = addp(y, np.concatenate([np.zeros(n - int(0.05 * SR)), unit(clack(1800, 0.01, 0.6, 0.2)) * 0.3]))
    return finish(room(y, 0.4, 10.0, 7000.0, 0.06, seed=7561 + k), 0.89, 0.1)


def vapeur(k: int) -> np.ndarray:
    dur = [1.4, 2.0][k]
    y = s61.steam(dur, [3200.0, 2600.0][k])
    y = addp(unit(y), unit(bouffee(0.25, 200, 2000)) * 0.3)
    if k == 1:
        y = addp(y, np.concatenate([np.zeros(int(1.2 * SR)), unit(s61.steam(0.7, 3600.0)) * 0.5]))
    return finish(room(y, 0.5, 8.0, 7000.0, 0.08, seed=7571 + k), 0.89, 0.2)


# =================================================================== la Grande Pelleteuse

def roar(dur: float, f0: float, f1: float, rasp: float = 0.4) -> np.ndarray:
    """Un énorme moteur hydraulique qui hurle : dents de scie graves qui montent, grain irrégulier."""
    x = _t(dur)
    f = np.interp(x, [0, dur * 0.6, dur], [f0, f1, f1 * 0.92])
    f = f * (1 + rasp * 0.05 * bp(nz(len(x)), 15, 60) / 0.3)
    ph = (np.cumsum(f) / SR) % 1.0
    saw = 2 * ph - 1
    y = lp(saw, 1800) + 0.3 * lp(np.tanh(3 * saw), 600)
    return y * np.clip(x / 0.15, 0, 1) * np.clip((dur - x) / 0.5, 0, 1)


def groan(dur: float, f: float = 95.0) -> np.ndarray:
    """La ferraille qui gémit : un frottement grave et irrégulier (stick-slip) dans des résonances."""
    n = int(dur * SR)
    x = np.arange(n) / SR
    rate = f * (1 + 0.25 * np.sin(2 * np.pi * 0.7 * x)) * np.interp(x, [0, dur], [1.0, 1.4])
    ph = np.cumsum(rate) / SR
    pulses = (np.diff(np.floor(ph), prepend=0) > 0).astype(float) * RNG.uniform(0.5, 1.0, n)
    y = sum(bp(pulses, fq * 0.96, fq * 1.04) * g for fq, g in ((f * 3.1, 1.0), (f * 5.3, 0.7), (f * 8.7, 0.4), (f * 12.9, 0.25)))
    return y * np.sin(np.pi * np.clip(x / dur, 0, 1)) ** 0.6


def pelleteuse_cri(k: int) -> np.ndarray:
    dur = [3.2, 2.8][k]
    parts = [(unit(roar(dur, [45.0, 55.0][k], [95.0, 120.0][k])), 0.0, 0.8),
             (unit(sifflement(dur * 0.8, 1200, 9000, 0.05, 0.6)), 0.15, 0.4),
             (unit(groan(dur * 0.85, [90.0, 110.0][k])), 0.25, 0.5),
             (unit(thump(60.0, 32.0, 0.25, 0.9)), 0.0, 0.7)]
    if k == 0:
        parts += [(unit(clang_m(160.0, 1.4)), 1.6, 0.35), (unit(bouffee(0.6, 400, 4000)), 2.4, 0.4)]
    else:
        parts += [(clip_rec(KI + "impactMetal_heavy_002.ogg", -8.0, 0.8), 0.0, 0.5), (unit(clang_m(210.0, 1.0)), 1.9, 0.3)]
    out = mix(dur + 0.6, *parts)
    out = np.tanh(out / (np.max(np.abs(out)) + 1e-9) * 1.8)
    out = room(out, 1.2, 4.0, 4000.0, 0.15, seed=7581 + k)
    return finish(out, 0.89, 0.5)


def clang_m(f: float, dur: float) -> np.ndarray:
    return m75.clang(f, dur, RNG, 0.8)


def gravats(t0: float, count: int, spread: float = 1.0) -> list:
    """Des gravats de béton qui retombent (petits chocs secs et poussière)."""
    parts = []
    for _ in range(count):
        t = t0 + RNG.exponential(spread / 3)
        c = unit(clack(RNG.uniform(600, 2500), RNG.uniform(0.008, 0.02), 0.5, 0.6))
        parts.append((c, t, RNG.uniform(0.05, 0.25)))
    return parts


def pelleteuse_frappe(k: int) -> np.ndarray:
    dur = 2.6
    t = [0.05, 0.25, 0.05][k]
    parts = [(unit(thump([55.0, 48.0, 62.0][k], 28.0, 0.35, 1.4)), t, 1.0),
             (clip_rec(BFH + ["bfh1_rock_hit_01.ogg", "bfh1_rock_breaking_01.ogg", "bfh1_rock_breaking_03.ogg"][k], -6.0, 1.2), t, 0.7),
             (clip_rec(KI + "impactMetal_heavy_00%d.ogg" % [0, 2, 4][k], -7.0, 1.0), t, 0.6),
             (unit(lp(nz(int(1.2 * SR)), 400) * np.exp(-np.arange(int(1.2 * SR)) / (0.3 * SR))), t, 0.5),
             (unit(clang_m([140.0, 120.0, 170.0][k], 1.6)), t, 0.25)]
    if k == 1:      # le godet qui siffle en descendant
        parts.append((unit(sifflement(0.3, 1500, 6000, 0.1, 0.05)), 0.0, 0.25))
    if k == 2:      # deux coups
        parts += [(unit(thump(58.0, 30.0, 0.3, 1.2)), 0.65, 0.8), (clip_rec(BFH + "bfh1_rock_breaking_02.ogg", -7.0, 1.0), 0.65, 0.5)]
    parts += gravats(t + 0.08, 18, 1.4)
    out = mix(dur, *parts)
    out = np.tanh(out / (np.max(np.abs(out)) + 1e-9) * 1.6)
    out = room(out, 1.4, 3.5, 4000.0, 0.15, seed=7591 + k)
    return finish(out, 0.89, 0.5)


def durite(k: int) -> np.ndarray:
    dur = [2.0, 2.4][k]
    n = int(dur * SR)
    x = np.arange(n) / SR
    pop = unit(addp(thump(150.0, 70.0, 0.03, 0.2), bp(nz(int(0.03 * SR)), 300, 4000) * np.hanning(int(0.03 * SR))))
    jet = sifflement(dur - 0.05, 1500, 10000, 0.005, 0.6, 0.8)
    sputter = 0.6 + 0.4 * np.sign(np.sin(2 * np.pi * np.cumsum(np.interp(x, [0, dur], [9.0, 22.0])) / SR))
    jet = jet[:n] * lp(sputter, 80)[: len(jet)] if k == 1 else jet
    spray = unit(crepite(dur * 0.8, 400, 800, 5000)) * 0.25
    out = mix(dur, (pop, 0.0, 0.8), (unit(jet), 0.02, 0.7), (spray, 0.1, 1.0), (unit(groan(0.4, 160.0)), 0.0, 0.2))
    return finish(room(out, 0.6, 7.0, 6000.0, 0.1, seed=7601 + k), 0.89, 0.4)


def tapis_roulant(k: int) -> np.ndarray:
    """Un tapis roulant : le moteur, les rouleaux qui claquent à chaque jointure du tapis (cadence
    exacte : boucle de 3 s sans raccord)."""
    dur = 3.0
    n = int(dur * SR)
    x = np.arange(n) / SR
    out = np.zeros(n)
    for rate, f, g in ((4.0, 1200.0, 1.0), (6.0, 1800.0, 0.5), (2.0, 700.0, 0.8)):
        for j in range(int(rate * dur)):
            c = unit(clack(f * RNG.uniform(0.95, 1.05), 0.012, 0.6, 0.4)) * g * RNG.uniform(0.7, 1.0)
            wplace(out, c, j / rate * SR + RNG.uniform(0, 0.004) * SR)
    motor = np.sin(2 * np.pi * 100 * x) * 0.4 + np.sin(2 * np.pi * 200 * x) * 0.15 + np.sin(2 * np.pi * 50 * x) * 0.3
    belt = nz(n)
    y = out * 0.5 + motor * 0.2 + belt * 0.0
    ext = np.concatenate([y[-SR:], y])
    ext = ext + 0.12 * np.concatenate([belt[-SR:], belt])
    ext = bp(ext, 60, 7000)
    return _norm(ext[SR:], 0.89)


# =================================================================== les bureaux

def tampon_bureau(k: int) -> np.ndarray:
    """Le tampon de Mademoiselle Prune : deux petits coups sur l'encreur, puis « TCHAC ! » sur le
    papier et le bureau (le 2 tamponne deux fois, très vite)."""
    pad = [clip_rec(KI + "impactSoft_medium_00%d.ogg" % i, 2.0, 0.2) for i in (0, 1)]
    hit = lambda: addp(clip_rec(KI + "impactWood_light_00%d.ogg" % RNG.integers(0, 5), -2.0, 0.3),
                       unit(thump(220.0, 140.0, 0.02, 0.12)) * 0.5,
                       unit(bp(nz(int(0.03 * SR)), 1500, 6000) * np.hanning(int(0.03 * SR))) * 0.25)
    parts = [(pad[0], 0.0, 0.3), (pad[1], 0.16, 0.3), (hit(), 0.42, 1.0)]
    if k == 1:
        parts += [(pad[0], 0.75, 0.25), (hit(), 0.92, 0.95)]
    out = mix(1.4 if k else 0.9, *parts)
    return finish(room(out, 0.3, 14.0, 7000.0, 0.08, seed=7611 + k), 0.89, 0.1)


def photocopieuse(k: int) -> np.ndarray:
    dur = [4.2, 3.4][k]
    n = int(dur * SR)
    x = np.arange(n) / SR
    motor = unit(servo(dur - 0.3, 110.0, 118.0)) * 0.3
    scan = np.zeros(n)
    s0, s1 = 0.8, 2.3
    m = int((s1 - s0) * SR)
    scan[int(s0 * SR):int(s0 * SR) + m] = unit(beep(420, 980, s1 - s0, 0.4)) * 0.25 + unit(servo(s1 - s0, 300.0, 520.0)) * 0.3
    parts = [(motor, 0.1, 1.0), (scan, 0.0, 1.0), (unit(clack(900, 0.02, 0.5, 0.6)), 0.15, 0.4),
             (unit(clack(700, 0.03, 0.4, 0.7)), 2.4, 0.5), (unit(gears(1.0, 140, 2400)), 2.45, 0.2)]
    # la feuille qui sort (« ffrrt ») et le petit bip de fin
    sh = bp(nz(int(0.45 * SR)), 1500, 7000) * np.sin(np.pi * np.linspace(0, 1, int(0.45 * SR)))
    parts += [(unit(sh), 2.8 if k == 0 else 2.6, 0.45), (unit(beep(1760, 1760, 0.12)), dur - 0.55, 0.3)]
    if k == 0:      # un « hoquet » comique : elle cale et redémarre
        parts += [(unit(clack(500, 0.04, 0.3, 0.8)), 1.55, 0.6), (unit(beep(300, 180, 0.2, 0.6)), 1.6, 0.25)]
    out = mix(dur, *parts)
    out *= np.clip(x / 0.05, 0, 1)[: len(out)]
    return finish(room(out, 0.4, 10.0, 7000.0, 0.1, seed=7621 + k), 0.89, 0.2)


def alarme_usine(k: int) -> np.ndarray:
    dur = [2.4, 2.2][k]
    x = _t(dur)
    if k == 0:          # deux tons qui alternent (« pin-pon » d'usine)
        f = np.where((x * 2.5) % 1.0 < 0.5, 660.0, 880.0)
        f = lp(f, 30)
    else:               # un klaxon qui monte (« aouuu-ga ! »)
        f = 300 + 500 * ((x * 1.6) % 1.0) ** 0.7
    ph = 2 * np.pi * np.cumsum(f) / SR
    y = np.sign(np.sin(ph)) * 0.4 + np.sin(ph) + 0.3 * np.sin(3 * ph)
    y = bp(y, 250, 5000) * np.clip(x / 0.02, 0, 1) * np.clip((dur - x) / 0.1, 0, 1)
    return finish(room(y, 0.8, 6.0, 5000.0, 0.15, seed=7631 + k), 0.89, 0.1)


# =================================================================== la Cathédrale des Spores

def champignard_pouf(k: int) -> np.ndarray:
    """Un champignard qui lâche ses spores : « pouf ! » tout doux, un petit couinement, des
    scintillements qui retombent."""
    dur = 1.4
    parts = [(unit(bouffee([0.35, 0.45, 0.3][k], 200, 2500, 0.01)), 0.0, 0.8),
             (unit(lp(bouffee(0.2, 80, 600, 0.004), 900)), 0.0, 0.5),
             (unit(m75.celesta(84 + [0, 3, 7][k], 0.2, 0.5, RNG)), 0.05, 0.15)]
    for i in range(7):
        parts.append((tinte(RNG.uniform(3500, 7000), 0.03, 0.5), 0.1 + i * 0.09 + RNG.uniform(0, 0.04), RNG.uniform(0.05, 0.12)))
    if k == 1:
        parts.append((unit(chirp([900, 1400, 1100], 0.12, (1.0, 0.2))), 0.12, 0.25))
    if k == 2:
        parts.append((unit(bouffee(0.25, 300, 3000, 0.01)), 0.3, 0.5))
    out = mix(dur, *parts)
    return finish(room(out, 0.6, 7.0, 8000.0, 0.15, seed=7641 + k), 0.89, 0.3)


def squeak(f0: float, f1: float, dur: float) -> np.ndarray:
    """Un petit couinement (voix de champignard) : voyelle « i » très aiguë qui glisse."""
    return syllabe(dur, [f0, f1], "i", 1.6, h=0.0, souffle=0.15, att=0.005, rel=dur * 0.4, fmax=9000.0, tilt=0.8)


def champignard_rire(k: int) -> np.ndarray:
    notes = [[(780, 900), (760, 880), (740, 860), (700, 820), (640, 700)],
             [(900, 1100), (980, 1180), (900, 1050)],
             [(700, 820), (700, 820), (680, 790), (660, 760), (620, 740), (560, 600)]][k]
    parts = []
    t = 0.0
    for f0, f1 in notes:
        d = RNG.uniform(0.07, 0.1)
        parts.append((unit(squeak(f0, f1, d)), t, RNG.uniform(0.6, 1.0)))
        t += d + RNG.uniform(0.025, 0.05)
    if k == 1:     # il pouffe
        parts.append((unit(bouffee(0.12, 600, 4000, 0.004)), t, 0.4))
    out = mix(t + 0.3, *parts)
    out = lp(out, 7500)
    return finish(room(out, 0.3, 14.0, 8000.0, 0.08, seed=7651 + k), 0.89, 0.06)


def eternuement(k: int) -> np.ndarray:
    """« A… a… atchoum ! » sans mot : deux inspirations hésitantes qui montent, puis l'éternuement
    (le « tch » de l'air, la voix qui part en « oum »), petit et comique."""
    s = [1.0, 1.35][k]
    parts = []
    t = 0.0
    for i, (f0, f1) in enumerate(((180, 230), (200, 270))):
        d = 0.22 + 0.08 * i
        a = syllabe(d, [f0 * s, f1 * s], "a", 1.1, h=0.06, souffle=0.6, att=0.04, rel=0.08, tilt=1.1)
        parts.append((unit(a), t, 0.35 + 0.1 * i))
        t += d + [0.18, 0.12][i]
    m = int(0.09 * SR)
    tch = hp(nz(m), 2500) * np.exp(-np.arange(m) / (0.03 * SR))
    parts.append((unit(tch), t, 0.9))
    oum = syllabe(0.28, [320 * s, 260 * s, 200 * s], "ou", 1.1, h=0.0, souffle=0.4, att=0.01, rel=0.15, sat=1.2)
    parts.append((unit(oum), t + 0.05, 0.7))
    if k == 1:      # et un petit reniflement
        sn = bp(nz(int(0.2 * SR)), 1500, 6000) * np.sin(np.pi * np.linspace(0, 1, int(0.2 * SR)))
        parts.append((unit(sn), t + 0.6, 0.2))
    out = mix(t + 0.9, *parts)
    return finish(room(out, 0.3, 14.0, 7000.0, 0.06, seed=7661 + k), 0.89, 0.1)


def boing(f0: float, dur: float, wob: float = 9.0, depth: float = 0.35) -> np.ndarray:
    """Le « boïng » d'un ressort : une note qui part vers le haut et tremblote en s'éteignant."""
    x = _t(dur)
    f = f0 * (1 + depth * np.sin(2 * np.pi * wob * x) * np.exp(-x / (dur * 0.35))) * (1 + 0.6 * np.exp(-x / 0.03))
    ph = 2 * np.pi * np.cumsum(f) / SR
    y = np.sin(ph) + 0.35 * np.sin(2 * ph) + 0.12 * np.sin(3.01 * ph)
    return y * np.clip(x / 0.003, 0, 1) * np.exp(-x / (dur * 0.35))


def champi_boing(k: int) -> np.ndarray:
    parts = [(unit(boing([220.0, 300.0][k], 0.9)), 0.0, 1.0),
             (unit(clack(1200, 0.01, 0.5, 0.3)), 0.0, 0.2),
             (unit(m75.celesta([88, 91][k], 0.2, 0.4, RNG)), 0.03, 0.12)]
    if k == 1:
        parts.append((unit(boing(420.0, 0.5, 12.0, 0.25)), 0.32, 0.4))
    out = mix(1.8, *parts)
    return finish(room(out, 0.4, 10.0, 8000.0, 0.08, seed=7671 + k), 0.89, 0.3)


def carillon(notes, step: float, dur: float, vel: float = 0.5) -> np.ndarray:
    out = np.zeros(int(dur * SR))
    for i, m in enumerate(notes):
        y = addp(m75.celesta(m, 0.4, vel, RNG), 0.5 * glock(m + 12))
        amb.place(out, y[: len(out) - int(i * step * SR)], int(i * step * SR), 1.0)
    return out


_GLOCK = {}


def glock(m: float) -> np.ndarray:
    """Une note de glockenspiel (VSCO-2 CE), mono."""
    if "g" not in _GLOCK:
        m75.VSCO = VSCO
        try:
            _GLOCK["g"] = m75.orch.Instrument("glock", VSCO, "Percussion/Glock/*.wav", sustain=False, attack=0.001, release=1.2)
        except (FileNotFoundError, ValueError):
            _GLOCK["g"] = None
    ins = _GLOCK["g"]
    if ins is None:
        return m75.celesta(m, 0.5, 0.5, RNG)
    return np.asarray(ins.note(m, 0.6, 0.5), float).mean(axis=1)


def champi_magie(k: int) -> np.ndarray:
    notes = [[72, 76, 79, 84, 88, 91, 96], [77, 81, 84, 89, 93, 96, 101]][k]
    y = carillon(notes, 0.075, 2.4, 0.5)
    parts = [(unit(y), 0.0, 0.8), (unit(etincelles(1.4, 26, 3500, 9000, (0.05, 0.2))), 0.1, 0.4),
             (unit(m75.pad(notes[2], 1.0, 0.5, RNG, 3000, 0.25, 0.8)[:, 0]), 0.0, 0.25)]
    out = mix(2.4, *parts)
    out = s69.echoes(out, [(0.18, 0.3), (0.36, 0.15)], 6000.0)
    return finish(room(out, 1.2, 4.0, 9000.0, 0.2, seed=7681 + k), 0.89, 0.6)


def champi_fin(k: int) -> np.ndarray:
    notes = [[91, 88, 84, 79, 76], [96, 93, 89, 84, 81]][k]
    y = carillon(notes, 0.11, 2.0, 0.4)
    out = mix(2.0, (unit(y), 0.0, 0.8), (unit(etincelles(0.8, 8, 3000, 6000, (0.03, 0.1))), 0.0, 0.25))
    out = lp(out, 9000)
    return finish(room(out, 1.0, 5.0, 8000.0, 0.18, seed=7691 + k), 0.89, 0.5)


# =================================================================== les animaux de la ville

def aboiement(k: int) -> np.ndarray:
    """Un chien content : « wouf ! » (enregistrements CC0 et voix synthétique d'aboiement, plus aiguë
    et plus ronde que les chiens des enfers de la V70)."""
    if k < 2:
        c = clip_rec(CRE + "barking_0%d.ogg" % (k + 1), [0.0, 1.0][k])
        parts = [(c, 0.0, 1.0)]
        if k == 1:
            parts.append((clip_rec(CRE + "barking_01.ogg", 1.5), 0.42, 0.85))
        dur = len(c) / SR + (0.5 if k == 1 else 0.15)
    else:
        parts = []
        t = 0.0
        for i in range(k):           # deux ou trois « wouf ! »
            f0 = RNG.uniform(250, 320)
            y = s70.aboi(f0, 0.9, RNG.uniform(0.16, 0.22), 0.07)
            parts.append((unit(y), t, RNG.uniform(0.8, 1.0)))
            t += RNG.uniform(0.26, 0.34)
        dur = t + 0.3
    out = mix(dur, *parts)
    out = hp(out, 120)
    return finish(room(out, 0.4, 10.0, 7000.0, 0.08, seed=7701 + k), 0.89, 0.06)


def aboiement_petit(k: int) -> np.ndarray:
    parts = []
    t = 0.0
    for i in range([2, 3, 4][k]):
        f0 = RNG.uniform(480, 620)
        y = s70.aboi(f0, 0.55, RNG.uniform(0.08, 0.12), 0.05)
        parts.append((unit(y), t, RNG.uniform(0.75, 1.0)))
        t += RNG.uniform(0.14, 0.2)
    out = mix(t + 0.25, *parts)
    out = hp(out, 250)
    return finish(room(out, 0.3, 12.0, 8000.0, 0.06, seed=7711 + k), 0.89, 0.05)


def chat_miaou(k: int) -> np.ndarray:
    f = ["Food Time 2.wav", "Food Time 7.wav", "Tiny Tito.wav"][k]
    x = rec(CAT + f)
    if len(x) < SR // 10:
        y = syllabe(0.7, [500, 750, 600], "i", 1.5, voy2="ou", h=0.0, souffle=0.2)
    else:
        x = s69.denoise(x)
        y = loudest(hp(x, 180), [0.9, 1.0, 0.8][k], 400.0, 2500.0)
    y = np.concatenate([_fade(y, 0.004, 0.08), np.zeros(int(0.2 * SR))])
    return finish(room(y, 0.3, 14.0, 6000.0, 0.05, seed=7721 + k), 0.89, 0.1)


def pigeon(k: int) -> np.ndarray:
    y = s56.pigeon(k)
    if k == 1:
        y = np.concatenate([y, np.zeros(int(0.15 * SR)), s56.pigeon(2)])
    y = addp(unit(y), np.zeros(int(0.1 * SR)))
    return finish(room(y, 0.4, 10.0, 5000.0, 0.08, seed=7731 + k), 0.89, 0.1)


# =================================================================== la ville, la radio, la musique

def sirene_alerte(k: int) -> np.ndarray:
    """La vieille sirène à manivelle : le rotor qui hache l'air (le son est riche, un peu rauque), la
    hauteur qui monte avec chaque tour de manivelle, puis redescend en gémissant."""
    dur = [4.2, 3.8][k]
    x = _t(dur)
    crank = 1 + 0.04 * np.sin(2 * np.pi * 1.6 * x)
    if k == 0:
        f = np.interp(x, [0, 2.3, 2.7, dur], [120.0, 820.0, 840.0, 260.0]) * crank
    else:
        f = np.interp(x, [0, 1.4, 1.8, 2.0, 3.0, dur], [150.0, 760.0, 780.0, 650.0, 800.0, 300.0]) * crank
    ph = 2 * np.pi * np.cumsum(f) / SR
    y = np.sin(ph) + 0.55 * np.sin(2 * ph) + 0.35 * np.sin(3 * ph) + 0.2 * np.sign(np.sin(ph))
    air = bp(nz(len(x)), 500, 3000) * 0.15
    y = (y + air) * np.clip(x / 0.3, 0, 1) * np.clip((dur - x) / 0.6, 0, 1)
    y = bp(y, 150, 6000)
    return finish(room(y, 1.4, 3.5, 5000.0, 0.2, seed=7741 + k), 0.89, 0.4)


def radio_jingle(k: int) -> np.ndarray:
    """Le jingle de Radio Boucan : « tata-tata-TAAA ! » au synthé cuivré, un roulement, la cymbale,
    un « wouiiip » de balayage, et un accord final qui chatoie."""
    K = kit()
    if k == 0:
        seq = [(0.0, [67, 71, 74]), (0.18, [67, 71, 74]), (0.36, [69, 72, 76]), (0.54, [69, 72, 76]), (0.9, [72, 76, 79, 84])]
    else:
        seq = [(0.0, [64, 68, 71]), (0.15, [66, 69, 73]), (0.3, [68, 71, 75]), (0.6, [69, 73, 76, 81])]
    dur = 4.8
    out = np.zeros(int(dur * SR))
    for i, (t, ch) in enumerate(seq):
        last = i == len(seq) - 1
        d = 2.2 if last else 0.15
        for m in ch:
            y = m75.pad(m, d, 1.0, RNG, 4500, 0.005, 0.3 if not last else 1.2, 3, 0.15)[:, 0]
            y = addp(y, 0.4 * m75.organ(m + 12, d, 0.6, RNG, 0.8, 0.6))
            amb.place(out, y[: len(out) - int(t * SR)], int(t * SR), 1.0)
    # la batterie (VCSL) : roulement de caisse claire et toms, puis la crash
    roll = [(0.0 + i * 0.045, "snare", 0.5 + 0.03 * i) for i in range(12)] if k == 0 else \
           [(0.0 + i * 0.075, "tom%d" % (1 + i // 2), 0.8) for i in range(8)]
    for t, p, v in roll:
        amb.place(out, K.get(p, min(1.0, v)).mean(axis=1) * 0.35, int((t + 0.0) * SR), 1.0)
    tf = seq[-1][0]
    for p in ("crash", "kick"):
        y = K.get(p, 0.95).mean(axis=1) * (0.45 if p == "crash" else 0.6)
        amb.place(out, y[: len(out) - int(tf * SR)], int(tf * SR), 1.0)
    sw = chirp([400, 2400], 0.5, (1.0, 0.2, 0.1)) * np.linspace(0.2, 1, int(0.5 * SR))
    amb.place(out, sw * 0.2, int(max(0.0, tf - 0.5) * SR), 1.0)
    out = lp(out, 9000)
    out = room(out, 0.9, 5.0, 8000.0, 0.15, seed=7751 + k)
    x = np.arange(len(out)) / SR
    out *= np.clip((dur - x) / 1.2, 0, 1)
    return finish(out, 0.89, 0.3)


def radio_gresillement(k: int) -> np.ndarray:
    """On tourne le bouton de la radio : souffle, crépitements, sifflements qui glissent (les
    stations qui passent), un bout de musique au loin, puis le souffle."""
    dur = [2.6, 3.2][k]
    n = int(dur * SR)
    x = np.arange(n) / SR
    hissy = bp(nz(n), 400, 5000) * (0.6 + 0.4 * amb.smooth_env(n, 8.0, 0, 1))
    crack = crepite(dur, 60, 800, 6000)
    w1 = chirp([2600, 900, 1800], dur * 0.6, (1.0,), 0.05, 0.1)
    w2 = chirp([400, 1500], dur * 0.35, (1.0, 0.2), 0.05, 0.1)
    music = np.zeros(int(0.8 * SR))
    for i, m in enumerate([72, 76, 79, 76, 74, 72] if k == 0 else [67, 71, 74, 79]):
        y = m75.organ(m, 0.13, 0.7, RNG, 0.6, 0.3)
        amb.place(music, y[: len(music) - int(i * 0.13 * SR)], int(i * 0.13 * SR), 1.0)
    music = bp(music, 400, 3000) * (1 + 0.5 * np.sin(2 * np.pi * 7 * np.arange(len(music)) / SR))
    parts = [(unit(hissy), 0.0, 0.5), (unit(crack), 0.0, 0.4), (unit(w1), 0.1, 0.2), (unit(w2), dur * 0.55, 0.15),
             (unit(music), dur * 0.35, 0.35)]
    out = mix(dur, *parts)
    out = bp(out, 200, 6000) * np.clip(x / 0.03, 0, 1)[: len(out)]
    return finish(out, 0.89, 0.15)


def bombe_peinture(k: int) -> np.ndarray:
    """Une bombe de peinture : on la secoue (la bille qui cliquette dans la boîte), puis « pschhh »."""
    shakes = [6, 9][k]
    rate = 7.5
    parts = []
    for i in range(shakes):
        t = i / rate
        for j in range(2):
            c = addp(tinte(RNG.uniform(2600, 3600), 0.02, 0.6), 0.5 * unit(clack(RNG.uniform(1500, 2500), 0.008, 0.8, 0.2)))
            parts.append((unit(c), t + j * 0.03, RNG.uniform(0.4, 0.8)))
        parts.append((unit(bp(nz(int(0.05 * SR)), 1000, 5000) * np.hanning(int(0.05 * SR))), t, 0.15))
    t0 = shakes / rate + 0.25
    sd = [1.1, 1.6][k]
    spray = sifflement(sd, 3500, 12000, 0.01, 0.15, 0.2)
    parts.append((unit(spray), t0, 0.8))
    parts.append((unit(clack(1800, 0.01, 0.5, 0.2)), t0 - 0.02, 0.3))
    out = mix(t0 + sd + 0.2, *parts)
    return finish(room(out, 0.3, 14.0, 9000.0, 0.06, seed=7761 + k), 0.89, 0.1)


def grue(k: int) -> np.ndarray:
    """Le treuil de la grue : le moteur qui démarre, le cliquet du tambour, le câble qui grince sous la
    charge, la tôle qui gémit, et le frein qui claque."""
    dur = [3.6, 3.0][k]
    parts = [(unit(servo(dur - 0.5, 70.0, 95.0)), 0.0, 0.6), (s63.ratchet(int((dur - 0.8) * 9), 9.0, 0.7), 0.3, 0.35),
             (unit(s68.rope_creak(dur - 0.8)), 0.4, 0.3), (unit(groan(dur * 0.6, 70.0)), 0.6, 0.3),
             (unit(clack(600, 0.04, 0.4, 0.8)), dur - 0.4, 0.6), (unit(thump(90.0, 60.0, 0.05, 0.3)), dur - 0.4, 0.5)]
    out = mix(dur + 0.2, *parts)
    out = room(out, 1.2, 4.0, 4000.0, 0.15, seed=7771 + k)
    return finish(out, 0.89, 0.25)


def skate(k: int) -> np.ndarray:
    """Une planche à roulettes : les roues qui roulent sur le béton (le « tac-tac » des joints), le
    « clac » de la planche (le ollie), la retombée, et elle repart."""
    dur = [2.2, 2.4, 1.8][k]
    n = int(dur * SR)
    x = np.arange(n) / SR
    roll = lp(nz(n), 900) * 0.6 + bp(nz(n), 1500, 4000) * 0.12
    roll *= 0.8 + 0.2 * np.sin(2 * np.pi * 23 * x)
    joints = np.zeros(n)
    for t in np.arange(0.2, dur, 0.38):
        amb.place(joints, unit(clack(900, 0.01, 0.5, 0.6)) * 0.4, int(t * SR), 1.0)
    pop_t = [0.9, 1.0, 0.5][k]
    air = (x > pop_t) & (x < pop_t + 0.35)
    gate = lp(np.where(air, 0.0, 1.0), 40)
    rolling = (roll + joints) * gate * np.clip(x / 0.15, 0, 1) * np.clip((dur - x) / 0.5, 0, 1)
    pop = addp(clip_rec(KI + "impactWood_heavy_00%d.ogg" % [0, 1, 2][k], 2.0, 0.25), unit(clack(1300, 0.008, 1.0, 0.4)) * 0.4)
    land = addp(clip_rec(KI + "impactWood_heavy_00%d.ogg" % [3, 4, 2][k], -1.0, 0.35), unit(thump(110.0, 70.0, 0.04, 0.25)) * 0.6,
                unit(clack(800, 0.02, 0.4, 0.6)) * 0.3)
    parts = [(unit(rolling), 0.0, 0.5), (pop, pop_t, 0.9), (land, pop_t + 0.38, 1.0)]
    if k == 2:      # il retombe… et s'arrête d'un coup de pied
        parts.append((unit(bp(nz(int(0.3 * SR)), 500, 3000) * np.linspace(1, 0, int(0.3 * SR))), pop_t + 0.9, 0.4))
    out = mix(dur, *parts)
    return finish(room(out, 0.6, 7.0, 6000.0, 0.12, seed=7781 + k), 0.89, 0.2)


def pogo(k: int) -> np.ndarray:
    """La fosse qui saute : tout le monde retombe (presque) en même temps sur le plancher, « boum !
    boum ! », des cris, des « hé ! »."""
    K = kit()
    m75.crowd_seed(7790 + k)
    dur = 2.4
    out = np.zeros(int((dur + 0.5) * SR))
    beat = [0.42, 0.36][k]
    t = 0.05
    while t < dur - 0.2:
        for _ in range(14):
            st = addp(K.get("kick", RNG.uniform(0.3, 0.7)).mean(axis=1) * 0.5, unit(thump(80.0, 50.0, 0.05, 0.3)) * 0.4)
            st = lp(st, RNG.uniform(1500, 2500))
            amb.place(out, st, int(max(0.0, t + RNG.normal(0, 0.025)) * SR), RNG.uniform(0.08, 0.16))
        t += beat
    h = m75.hey(np.random.default_rng(7792 + k), 14).mean(axis=1)
    amb.place(out, unit(h) * 0.6, int(beat * 2 * SR), 1.0)
    cr = m75.cheer(np.random.default_rng(7793 + k), dur, 14, 0, None).mean(axis=1)
    amb.place(out, unit(cr) * 0.45, 0, 1.0)
    out = room(out, 1.0, 5.0, 5000.0, 0.2, seed=7795 + k)
    return finish(out, 0.89, 0.4)


def foule_acclame(k: int) -> np.ndarray:
    K = kit()
    m75.crowd_seed(7800 + k)
    y = m75.cheer(np.random.default_rng(7801 + k), [4.0, 3.6][k], [30, 24][k], [110, 90][k], K).mean(axis=1)
    if k == 1:      # et ils scandent « hé ! hé ! »
        for i in range(3):
            h = m75.hey(np.random.default_rng(7810 + i), 16).mean(axis=1)
            amb.place(y, unit(h) * 0.5, int((2.0 + i * 0.45) * SR), 1.0)
    y = room(y, 1.2, 4.5, 5000.0, 0.2, seed=7805 + k)
    return finish(y, 0.89, 0.8)


def larsen_micro(k: int) -> np.ndarray:
    """Un petit larsen de micro, pour rire : un sifflement doux qui enfle, hésite et qu'on coupe vite
    (« tapotement » sur le micro avant, pour le 2). Joué bas."""
    dur = [1.3, 1.6][k]
    x = _t(dur)
    f = np.interp(x, [0, dur * 0.5, dur], [[1850.0, 1600.0][k], [2050.0, 1750.0][k], [2100.0, 2350.0][k]])
    f *= 1 + 0.004 * np.sin(2 * np.pi * 5.5 * x)
    y = np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.08 * np.sin(4 * np.pi * np.cumsum(f) / SR)
    env = np.clip(x / (dur * 0.7), 0, 1) ** 2 * np.clip((dur - x) / 0.06, 0, 1) * (1 + 0.25 * np.sin(2 * np.pi * 3.0 * x))
    y = y * env
    parts = [(y, 0.0, 0.7)]
    if k == 1:          # « toc, toc » sur le micro avant
        tap = [(unit(addp(thump(140.0, 90.0, 0.02, 0.12), clack(1500, 0.006, 0.6, 0.6) * 0.3)), i * 0.22, 0.5) for i in range(2)]
        parts = tap + [(y, 0.5, 0.7)]
    out = mix(dur + (0.6 if k else 0.1), *parts)
    out = lp(out, 5000)
    return finish(room(out, 0.6, 7.0, 6000.0, 0.15, seed=7821 + k), 0.89, 0.06)


def guitar_render(play, dur: float, seed: int, gain: float = 40.0) -> np.ndarray:
    """Une phrase de guitare saturée (corde de Karplus-Strong et ampli de compose_musique_v75)."""
    S = m75.Song("riff", 150, 4, loop=False, seed=seed)
    g = m75.Guitar(S, "g", seed, jitter=0.003, bright=0.6)
    play(S, g)
    di = S.dis["g"][: int((dur + 1.0) * SR)]
    y = m75.amp(di, gain, mid=3.0, scoop=-3.5, presence=2.0)
    y = m75.filt(y, m75.bw("highpass", 70))
    return y.astype(float)


def guitare_riff(k: int) -> np.ndarray:
    """Une fioriture de Germaine-la-Terrible : un glissé qui descend et une note qui vibre (1), un riff
    en quintes « tcha-tcha-tchaaa ! » (2), une montée rapide et un tiré qui chante (3)."""
    def p0(S, g):
        m75.lead(S, "g", 0, "/E5:0.5 D5:0.25 B4:0.25 A4:0.5 ^B4:0.5 ~E5:2 | r:4", 7831, vel=0.9)

    def p1(S, g):
        g.riff(0, "E2:0.5 E2:0.25 E2:0.25 G2:0.5 A2:0.5 A#2:0.25 A2:0.75 | E2:2 r:2", 1.0, power=True)

    def p2(S, g):
        m75.lead(S, "g", 0, "A4:0.25 C5:0.25 D5:0.25 E5:0.25 G5:0.25 A5:0.25 ^C6:0.5 ~A5:2 | r:4", 7832, vel=0.9)
    dur = [2.4, 2.6, 2.4][k]
    y = guitar_render([p0, p1, p2][k], dur, 7830 + k, [30.0, 42.0, 30.0][k])
    y = y[: int((dur + 0.4) * SR)]
    y = room(y, 0.8, 5.0, 6000.0, 0.15, seed=7835 + k)
    return finish(y, 0.89, 0.4)


def batterie_roulement(k: int) -> np.ndarray:
    K = kit()
    out = np.zeros(int(2.8 * SR))
    if k == 0:      # la caisse claire qui enfle, puis la crash
        for i in range(28):
            t = i * 0.065
            amb.place(out, K.get("snare", 0.35 + 0.6 * i / 27).mean(axis=1), int(t * SR), 0.6)
        for p in ("crash", "kick"):
            amb.place(out, K.get(p, 1.0).mean(axis=1)[: len(out) - int(1.85 * SR)], int(1.85 * SR), 0.7)
    else:           # le tour des toms
        order = ["tom1"] * 4 + ["tom2"] * 4 + ["tom3"] * 4 + ["tom4"] * 4
        for i, p in enumerate(order):
            amb.place(out, K.get(p, 0.75 + 0.2 * i / 15).mean(axis=1), int(i * 0.1 * SR), 0.7)
            if i % 4 == 0:
                amb.place(out, K.get("kick", 0.8).mean(axis=1), int(i * 0.1 * SR), 0.5)
        for p in ("crash", "kick", "snare"):
            amb.place(out, K.get(p, 1.0).mean(axis=1)[: len(out) - int(1.65 * SR)], int(1.65 * SR), 0.6)
    out = room(out, 0.9, 5.0, 8000.0, 0.15, seed=7841 + k)
    return finish(out, 0.89, 0.6)


def cymbale(k: int) -> np.ndarray:
    K = kit()
    y = K.get(["crash", "crash2"][k], 1.0).mean(axis=1)
    y = y[: int(3.2 * SR)]
    y = room(y, 0.8, 5.0, 9000.0, 0.1, seed=7851 + k)
    return finish(y, 0.89, 1.0)


# =================================================================== l'usine : machines

def monte_charge(k: int) -> np.ndarray:
    dur = [4.4, 3.6][k]
    run = dur - 1.0
    parts = [(unit(clack(500, 0.05, 0.4, 0.8)), 0.0, 0.6), (unit(thump(70.0, 45.0, 0.08, 0.4)), 0.0, 0.5),
             (unit(servo(run, 60.0, 72.0)), 0.25, 0.6), (lp(unit(groan(run * 0.8, 85.0)), 2500), 0.5, 0.1),
             (lp(s63.ratchet(int(run * 6), 6.0, 0.5), 3000), 0.4, 0.1), (unit(lp(nz(int(run * SR)), 300)), 0.25, 0.45),
             (unit(clack(450, 0.06, 0.4, 0.9)), dur - 0.7, 0.8), (unit(thump(65.0, 40.0, 0.1, 0.5)), dur - 0.7, 0.7)]
    bell = s63.bell(1760.0 if k == 0 else 1568.0, 1.0, 1.0)
    parts.append((unit(bell), dur - 0.45, 0.3))
    out = mix(dur + 0.6, *parts)
    out = room(out, 0.9, 5.0, 4000.0, 0.15, seed=7861 + k)
    return finish(out, 0.89, 0.4)


def tourniquet(k: int) -> np.ndarray:
    parts = [(s63.ratchet([3, 4][k], [14.0, 18.0][k], 0.8), 0.0, 0.5),
             (clip_rec(KI + "impactMetal_medium_00%d.ogg" % [0, 2][k], -3.0, 0.5), [0.22, 0.24][k], 0.9),
             (unit(thump(160.0, 110.0, 0.03, 0.2)), [0.22, 0.24][k], 0.5),
             (unit(bronze(RNG.uniform(500, 700), 0.2)), [0.23, 0.25][k], 0.2)]
    out = mix(0.9, *parts)
    return finish(room(out, 0.4, 10.0, 6000.0, 0.08, seed=7871 + k), 0.89, 0.15)


def squeal(dur: float, f0: float, f1: float) -> np.ndarray:
    """Un volant de métal qui grince : frottement « collé-glissé » très aigu, irrégulier."""
    n = int(dur * SR)
    x = np.arange(n) / SR
    f = np.interp(x, [0, dur], [f0, f1]) * (1 + 0.03 * amb.smooth_env(n, 12.0, -1, 1))
    ph = np.cumsum(f) / SR
    pulses = (np.diff(np.floor(ph), prepend=0) > 0).astype(float)
    y = sum(bp(pulses, fq * 0.97, fq * 1.03) * g for fq, g in ((f0 * 2.0, 1.0), (f0 * 3.0, 0.6), (f0 * 4.1, 0.3)))
    y *= amb.smooth_env(n, 6.0, 0.3, 1.0)
    return y * np.clip(x / 0.03, 0, 1) * np.clip((dur - x) / 0.08, 0, 1)


def vanne(k: int) -> np.ndarray:
    dur = [2.4, 2.8][k]
    parts = [(unit(squeal(1.4, 420.0, 520.0)), 0.0, 0.6), (unit(squeal(0.8, 480.0, 560.0)), 1.5, 0.5),
             (unit(clack(700, 0.03, 0.4, 0.6)), 0.0, 0.4)]
    if k == 0:
        parts.append((unit(sifflement(1.2, 1800, 9000, 0.3, 0.4)), 1.0, 0.4))
    else:
        parts.append((unit(s70.bulles_eau(1.4, 18.0)), 1.2, 0.4) if hasattr(s70, "bulles_eau") else (unit(sifflement(1.2, 800, 4000)), 1.2, 0.4))
    out = mix(dur, *parts)
    return finish(room(out, 0.6, 7.0, 5000.0, 0.12, seed=7881 + k), 0.89, 0.3)


def porte_usine(k: int) -> np.ndarray:
    dur = [3.2, 2.6][k]
    run = dur - 0.9
    x = _t(run)
    rumble = lp(nz(len(x)), 220) * (0.8 + 0.2 * np.sin(2 * np.pi * 7 * x))
    rollers = np.zeros(len(x))
    for t in np.arange(0.05, run, 0.21):
        amb.place(rollers, unit(clack(400, 0.02, 0.4, 0.8)) * 0.4, int(t * SR), 1.0)
    parts = [(unit(clack(800, 0.03, 0.5, 0.6)), 0.0, 0.5), (unit(rumble + rollers), 0.05, 0.6),
             (unit(squeal(run * 0.7, 300.0, 340.0)), 0.3, 0.12),
             (clip_rec(KI + "impactMetal_heavy_00%d.ogg" % [0, 4][k], -8.0, 1.2), run + 0.05, 1.0),
             (unit(thump(60.0, 35.0, 0.15, 0.7)), run + 0.05, 0.8), (unit(m75.clang(110.0, 1.4, RNG, 0.6)), run + 0.06, 0.4)]
    out = mix(dur + 0.4, *parts)
    out = room(out, 1.2, 4.0, 4000.0, 0.18, seed=7891 + k)
    return finish(out, 0.89, 0.4)


# =================================================================== les nappes : briques

def band_snippet(bars: int, seed: int, prog=None, bpm: float = 176.0, ska: bool = False) -> np.ndarray:
    """Quelques mesures des Rats de Cale (batterie, deux guitares, basse), rendues par
    compose_musique_v75, en stéréo, pour les entendre de loin."""
    S = m75.Song("snip", bpm, bars, loop=False, seed=seed, tail=3.0)
    B = m75.Band(S, kit(), seed)
    prog = prog or (["A", "A", "D", "E", "F#m", "D", "E", "E"] * 4)[:bars]
    if ska:
        sk = m75.Guitar(S, "gC", seed + 9, bright=0.7)
        sk.rhythm(0, prog, ".s.s.s.s")
        B.bass.line(0, prog, ["r3f6", "rf3a"])
        for i in range(bars):
            m75.drums(S, kit(), i, m75.SKA, 0.9)
    else:
        B.gtr(0, prog, "Oooooooo" if seed % 2 else "MmmmMmmm")
        B.bass.line(0, prog, "Rrrrrrrr")
        B.drum_section(0, bars, m75.PUNK, 1.0, crash_every=4, fills={bars - 1: "toms"})
    B.mix(True)
    y = S.render(None, -18.0, -2.0, m75.room_ir(1.0, seed=seed), None, None)
    return np.asarray(y, float)


def far_music(y: np.ndarray, lp_hz: float, hp_hz: float = 60.0) -> np.ndarray:
    """De la musique entendue de loin (à travers une fenêtre, un mur) : sourde, sans stéréo précise."""
    m = y.mean(axis=1)
    m = lp(hp(m, hp_hz), lp_hz, 4) if lp_hz < 8000 else hp(m, hp_hz)
    return m


def velo_sonnette() -> np.ndarray:
    """Une sonnette de vélo : « dring-dring »."""
    out = np.zeros(int(1.2 * SR))
    f = RNG.uniform(2900, 3400)
    for i in range(2):
        b = s63.bell(f, 0.8, 1.2) * (1 + 0.5 * np.sin(2 * np.pi * 28 * _t(0.8)))[: int(0.8 * SR)]
        amb.place(out, unit(b), int(i * 0.16 * SR), 1.0)
    return out


def scie() -> np.ndarray:
    """Quelqu'un qui scie une planche dans un atelier (aller-retour de la scie, puis le bois)."""
    out = np.zeros(int(4.0 * SR))
    n = int(RNG.integers(5, 9))
    for i in range(n):
        m = int(0.28 * SR)
        st = bp(nz(m), RNG.uniform(1500, 2500), RNG.uniform(5000, 7000)) * np.sin(np.pi * np.linspace(0, 1, m)) ** 0.8
        st *= 1 + 0.6 * np.sin(2 * np.pi * RNG.uniform(60, 90) * np.arange(m) / SR)
        amb.place(out, st, int(i * 0.34 * SR), RNG.uniform(0.6, 1.0))
    return lp(out, 6000)


def corneille() -> np.ndarray:
    """Une corneille de la Casse : deux ou trois « kraa » rauques."""
    out = np.zeros(int(1.6 * SR))
    for i in range(int(RNG.integers(2, 4))):
        f0 = RNG.uniform(380, 520)
        y = syllabe(RNG.uniform(0.2, 0.3), [f0, f0 * 1.08, f0 * 0.85], "a", 1.35, h=0.0, souffle=0.4, rasp=0.3, sat=1.8,
                    tilt=0.7, att=0.01, rel=0.08)
        amb.place(out, unit(y), int(i * RNG.uniform(0.35, 0.45) * SR), RNG.uniform(0.7, 1.0))
    return lp(out, 5000)


def tuning_bass() -> np.ndarray:
    """La bassiste qui s'accorde : la corde grave pincée, qui monte un peu (la clé tourne), l'octave
    à la douzième case, l'harmonique."""
    out = np.zeros(int(9.5 * SR))
    rng = RNG
    t = 0.0
    for m, d, glide in ((28, 1.3, 0.0), (28, 1.3, 0.35), (40, 0.9, 0.0), (28, 1.6, 0.1), (52, 1.2, 0.0)):
        x = np.arange(int(d * SR)) / SR
        fm = 2 ** ((-glide + glide * np.clip(x / 0.9, 0, 1)) / 12)
        y = m75.string(m75.hz(m), d, rng, t60=3.0, bright=0.15, hard=0.4, pick=0.25, fmul=fm if glide else None)
        y = m75.choke(y, d - 0.05, 0.05)
        y = m75.bass_amp(y, 2.0)
        amb.place(out, y[: len(out) - int(t * SR)], int(t * SR), 1.0)
        t += d + rng.uniform(0.1, 0.4)
    return out


def ampli_ronfle(m: int) -> np.ndarray:
    """Les amplis allumés : le ronflement du secteur (50 Hz et ses harmoniques) et le souffle."""
    x = np.arange(m) / SR
    hum = sum(a * np.sin(2 * np.pi * f * x) for f, a in ((50, 0.4), (100, 1.0), (150, 0.5), (200, 0.25), (300, 0.12)))
    hiss = hp(nz(m), 3000) * 0.08
    return amb.stereo(hum * 0.5 + hiss, hum * 0.45 + np.roll(hiss, 999))


def baguettes() -> np.ndarray:
    """Le batteur qui vérifie ses fûts : grosse caisse, caisse claire, un tom, un « tchak »."""
    K = kit()
    out = np.zeros(int(4.0 * SR))
    t = 0.0
    for p, v in (("kick", 0.6), ("kick", 0.6), ("snare", 0.5), ("snare", 0.7), ("tom2", 0.6), ("tom3", 0.6), ("hat", 0.4), ("hat", 0.4)):
        amb.place(out, K.get(p, v).mean(axis=1)[: len(out) - int(t * SR)], int(t * SR), 0.6)
        t += RNG.uniform(0.35, 0.6)
    return out


# =================================================================== les nappes

def boucan_jour_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def bed(m):
        hum = lp(amb.noise(m, "pink"), 450) * 0.18
        water = s56.lapping(m) * 0.35
        return amb.stereo(hum, np.roll(hum, SR // 2)) + water + s71.brise(m) * 0.08

    cont = loop_layer(bed, seconds, 3.0)
    town = np.zeros((n, 2))
    s68.voice_walla(lib, town, 10.0, 2200.0, (-4.0, 3.0), (0.08, 0.26))
    scatter(town, [s68.laugh_group(int(RNG.integers(2, 4)), (-4.0, 1.5), 2400.0) for _ in range(4)], 6, (0.1, 0.22))
    scatter(town, [s70.pas_passant(int(RNG.integers(5, 10))) for _ in range(3)], 4, (0.08, 0.16))
    scatter(town, [velo_sonnette() for _ in range(2)], 3, (0.06, 0.12))
    for at, k in ((14.0, 0), (41.0, 1)):
        wplace(town, lp(skate(k), 5000), at * SR, 0.12, RNG.uniform(-0.6, 0.6))
    town = room_wrap(town, 1.2, 3.0, 2600.0, 0.22, seed=7901)
    far = np.zeros((n, 2))
    for at in (4.0, 9.0, 27.0, 33.0, 50.0):
        wplace(far, s68.hammering(), at * SR, 0.1, RNG.uniform(-0.9, -0.3))
    for at in (18.0, 46.0):
        wplace(far, scie(), at * SR, 0.07, RNG.uniform(0.4, 0.9))
    scatter(far, [lp(aboiement(int(RNG.integers(0, 4))), 2500) for _ in range(3)], 4, (0.04, 0.08))
    scatter(far, [amb.gull(int(RNG.integers(0, 3))) for _ in range(4)], 6, (0.03, 0.07))
    # de la musique qui sort d'une fenêtre (un disque de ska)
    mus = far_music(band_snippet(12, 7905, ["G", "C", "D", "G"] * 3, 150.0, ska=True), 2500.0, 150.0)
    x = np.arange(len(mus)) / SR
    mus *= np.clip(x / 2.0, 0, 1) * np.clip((x[-1] - x) / 2.0, 0, 1)
    wplace(far, mus, 21.0 * SR, 0.1, 0.75)
    far = room_wrap(far, 2.0, 2.0, 2800.0, 0.35, seed=7902)
    return finish_bed(cont + town + far, 0.7)


def boucan_nuit_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def bed(m):
        w = s59.wind(m, 150, 1400, 0.15, 0.2, 0.8) * 0.3
        wh = s59.whistle(m, 950.0) * 0.04
        return w + amb.stereo(wh, np.roll(wh, SR)) + s71.grillons(m) * 0.5 + s56.lapping(m) * 0.3

    cont = loop_layer(bed, seconds, 3.0)
    far = np.zeros((n, 2))
    # le concert de la Halle, étouffé par les murs (deux morceaux, des bravos entre les deux)
    for at, seed, prog in ((2.0, 7911, None), (31.0, 7912, ["E", "E", "D", "A"] * 6)):
        y = far_music(band_snippet(18, seed, prog, 184.0), 420.0, 40.0)
        x = np.arange(len(y)) / SR
        y *= np.clip(x / 1.0, 0, 1) * np.clip((x[-1] - x) / 1.5, 0, 1)
        wplace(far, y, at * SR, 0.32, -0.35)
    m75.crowd_seed(7913)
    ch = lp(m75.cheer(np.random.default_rng(7914), 3.0, 18, 30, kit()).mean(axis=1), 700)
    wplace(far, ch, 28.0 * SR, 0.12, -0.35)
    far = room_wrap(far, 1.6, 2.5, 1200.0, 0.3, seed=7915)
    ev = np.zeros((n, 2))
    wplace(ev, lp(aboiement(2), 2200), 12.0 * SR, 0.06, 0.7)
    wplace(ev, lp(aboiement(0), 2200), 47.0 * SR, 0.05, 0.6)
    wplace(ev, lp(chat_miaou(2), 4000), 38.0 * SR, 0.04, -0.8)
    scatter(ev, [s68.laugh_group(2, (-4.0, 0.0), 1500.0)], 2, (0.05, 0.08))
    scatter(ev, [lp(unit(groan(2.0, 60.0)), 2500)], 3, (0.03, 0.05))      # la tôle qui travaille dans le vent
    ev = room_wrap(ev, 2.2, 1.8, 2500.0, 0.4, seed=7916)
    return finish_bed(cont + far + ev, 0.7)


def halle_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def bed(m):
        rum = bp(amb.noise(m, "pink"), 150, 1200) * amb.smooth_env(m, 0.5, 0.6, 1.0) * 0.3
        return amb.stereo(rum, np.roll(rum, SR // 3)) + ampli_ronfle(m) * 0.05

    cont = loop_layer(bed, seconds, 2.0)
    rm = np.zeros((n, 2))
    s68.voice_walla(lib, rm, 24.0, 2600.0, (-4.0, 3.0), (0.1, 0.4))
    scatter(rm, [s68.laugh_group(int(RNG.integers(2, 5)), (-4.0, 2.0)) for _ in range(6)], 7, (0.18, 0.36))
    scatter(rm, [s71.trinque() for _ in range(8)], 14, (0.2, 0.45), lp_hz=7000.0)
    scatter(rm, [s71.chope_posee() for _ in range(5)], 10, (0.15, 0.3), lp_hz=5000.0)
    scatter(rm, [s70.pas_passant(int(RNG.integers(4, 9))) for _ in range(3)], 5, (0.1, 0.2))
    scatter(rm, [s68.whistle(2)], 2, (0.05, 0.08))
    stage = np.zeros((n, 2))
    wplace(stage, tuning_bass(), 6.0 * SR, 0.3, 0.3)
    wplace(stage, tuning_bass(), 37.0 * SR, 0.28, 0.3)
    wplace(stage, baguettes(), 22.0 * SR, 0.25, 0.0)
    g = guitare_riff(1)
    wplace(stage, lp(g, 6000), 51.0 * SR, 0.12, -0.4)
    wplace(stage, larsen_micro(0) * 0.5, 30.5 * SR, 0.06, 0.0)
    rm += room_wrap(stage, 1.6, 2.5, 4000.0, 0.35, seed=7921)
    rm = room_wrap(rm, 1.4, 3.0, 3800.0, 0.25, seed=7922)
    return finish_bed(cont + rm, 0.65)


def spores_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)
    x = np.arange(n) / SR

    def bed(m):
        w = s59.wind(m, 700, 4000, 0.1, 0.1, 0.6) * 0.05
        wh1 = s59.whistle(m, 1400.0) * 0.025
        wh2 = s59.whistle(m, 2100.0) * 0.015
        breath = bp(amb.noise(m, "pink"), 180, 700)
        return w + amb.stereo(wh1 + wh2 * 0.5, np.roll(wh1, SR) * 0.5 + wh2) + amb.stereo(breath, np.roll(breath, SR // 2)) * 0.0

    cont = loop_layer(bed, seconds, 3.0)
    # le souffle tranquille de la forêt (12 respirations par boucle : raccord parfait)
    br = bp(nz(n), 180, 700)
    br = np.concatenate([br[-SR:], br])
    br = bp(br, 180, 700)[SR:] * (0.55 + 0.45 * np.sin(2 * np.pi * x * 12 / seconds) ** 2) * 0.05
    # les résonances graves et lentes (des cloches de lumière très lointaines)
    deep = np.zeros(n)
    for f, cyc, ph in ((87.3, 3, 0.0), (130.8, 4, 1.3), (65.4, 2, 2.1), (174.6, 5, 0.7)):
        deep += np.sin(2 * np.pi * f * x) * (0.5 + 0.5 * np.sin(2 * np.pi * cyc * x / seconds + ph)) ** 3
    deep *= 0.018
    out = cont + amb.stereo(br + deep, np.roll(br, SR // 3) + deep)
    ev = np.zeros((n, 2))
    scatter(ev, [m75.twinkle(RNG).astype(float) for _ in range(8)], 70, (0.05, 0.16))
    scatter(ev, [unit(etincelles(1.2, 6, 3000, 7000, (0.05, 0.12))) for _ in range(3)], 6, (0.06, 0.1))
    scatter(ev, [s59.drip() for _ in range(5)], 14, (0.04, 0.1))
    scatter(ev, [unit(m75.celesta(float(RNG.choice([77, 81, 84, 88, 89, 93])), 0.3, 0.4, RNG)) for _ in range(5)], 8, (0.02, 0.05))
    ev = room_wrap(ev, 3.0, 1.5, 7000.0, 0.45, seed=7931)
    return finish_bed(out + ev, 0.7)


def casse_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def bed(m):
        w = s59.wind(m, 150, 2500, 0.2, 0.2, 1.0) * 0.16
        w1 = s59.whistle(m, 700.0) * 0.05
        w2 = s59.whistle(m, 1150.0) * 0.035
        return w + amb.stereo(w1 + w2 * 0.3, np.roll(w1, SR) * 0.4 + w2)

    cont = loop_layer(bed, seconds, 3.0)
    ev = np.zeros((n, 2))
    scatter(ev, [unit(groan(RNG.uniform(1.5, 2.5), RNG.uniform(60, 110))) for _ in range(4)], 7, (0.05, 0.12), lp_hz=3000.0)
    scatter(ev, [unit(s68.rope_creak(RNG.uniform(1.0, 2.0))) for _ in range(3)], 4, (0.03, 0.07))
    scatter(ev, [clip_rec(WM + "metal_sheet_0%d.ogg" % i, -3.0) for i in (1, 3, 5)], 5, (0.05, 0.12), lp_hz=4000.0)
    scatter(ev, [corneille() for _ in range(4)], 6, (0.05, 0.12))
    scatter(ev, [clip_rec(KI + "impactMetal_light_00%d.ogg" % i, -6.0) for i in range(3)], 4, (0.03, 0.07), lp_hz=2500.0)
    far = np.zeros((n, 2))
    for at in (8.0, 36.0):
        wplace(far, lp(soudure(int(RNG.integers(0, 2))), 3500), at * SR, 0.06, 0.6)
    wplace(far, lp(grue(1), 2000), 22.0 * SR, 0.06, -0.7)
    far = room_wrap(far, 2.0, 2.0, 2500.0, 0.4, seed=7941)
    ev = room_wrap(ev, 1.5, 2.5, 4000.0, 0.3, seed=7942)
    return finish_bed(cont + ev + far, 0.7)


def usine_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)
    x = np.arange(n) / SR
    hum = sum(a * np.sin(2 * np.pi * f * x + p) for f, a, p in ((50, 0.5, 0), (100, 0.8, 1), (150, 0.3, 2), (200, 0.2, 0.5), (400, 0.06, 1.2)))
    vent = bp(nz(n), 200, 2500)
    vent = np.concatenate([vent[-SR:], vent])
    vent = lp(vent, 1200)[SR:]
    cont = amb.stereo(hum * 0.05 + vent * 0.08, hum * 0.045 + np.roll(vent, SR // 2) * 0.08)
    belt = tapis_roulant(0)
    belt = np.tile(belt, int(np.ceil(n / len(belt))))[:n]
    cont += amb.stereo(lp(belt, 3000), np.roll(lp(belt, 3000), 777)) * 0.05
    press = np.zeros((n, 2))
    period = 3.75
    for i in range(int(seconds / period)):
        y = addp(unit(thump(70.0, 38.0, 0.12, 0.8)), unit(m75.clang(150.0, 1.0, RNG, 0.5)) * 0.3, unit(sifflement(0.5, 1500, 7000, 0.01, 0.4)) * 0.15)
        wplace(press, lp(y, 2500), (i * period + 0.4) * SR, 0.22, -0.5)
    press = room_wrap(press, 1.8, 2.2, 2500.0, 0.4, seed=7951)
    ev = np.zeros((n, 2))
    scatter(ev, [unit(s61.steam(RNG.uniform(0.8, 1.6), RNG.uniform(2500, 3500))) for _ in range(3)], 5, (0.05, 0.1))
    scatter(ev, [lp(robot_bip(int(RNG.integers(0, 3))), 5000) for _ in range(3)], 7, (0.03, 0.07))
    scatter(ev, [unit(servo(RNG.uniform(0.5, 0.9), RNG.uniform(200, 300), RNG.uniform(350, 500))) for _ in range(3)], 6, (0.02, 0.05))
    scatter(ev, [clip_rec(KI + "impactMetal_medium_00%d.ogg" % i, -5.0) for i in range(3)], 5, (0.03, 0.06), lp_hz=3000.0)
    ev = room_wrap(ev, 1.6, 2.5, 4000.0, 0.35, seed=7952)
    return finish_bed(cont + press + ev, 0.7)


def port_boucan_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def bed(m):
        water = s56.lapping(m) * 1.6
        swell = lp(amb.noise(m, "brown"), 250) * amb.smooth_env(m, 0.15, 0.3, 1.0) * 0.4
        return water + amb.stereo(swell, np.roll(swell, SR)) + s71.brise(m) * 0.12

    cont = loop_layer(bed, seconds, 3.0)
    ev = np.zeros((n, 2))
    scatter(ev, [amb.gull(int(RNG.integers(0, 3))) for _ in range(5)], 10, (0.05, 0.14))
    scatter(ev, [s61.chain() for _ in range(3)], 6, (0.06, 0.14), lp_hz=6000.0)
    scatter(ev, [unit(s68.rope_creak(RNG.uniform(1.0, 2.2))) for _ in range(4)], 7, (0.04, 0.09))
    scatter(ev, [unit(s56.halyard(k)) for k in range(3)], 6, (0.02, 0.05))
    far = np.zeros((n, 2))
    wplace(far, lp(grue(0), 2500), 9.0 * SR, 0.05, 0.6)
    wplace(far, lp(grue(1), 2500), 38.0 * SR, 0.04, 0.7)
    fh = s56.fog_horn()
    wplace(far, lp(unit(fh.mean(axis=1) if fh.ndim == 2 else fh), 1500), 27.0 * SR, 0.05, -0.6)
    scatter(far, [lp(aboiement(int(RNG.integers(0, 4))), 2000)], 2, (0.03, 0.05))
    far = room_wrap(far, 2.4, 1.8, 2500.0, 0.4, seed=7961)
    ev = room_wrap(ev, 1.4, 3.0, 5000.0, 0.25, seed=7962)
    return finish_bed(cont + ev + far, 0.55)


# =================================================================== lancement

# nom : (fonction, nombre de variantes, numéro de la première, correction de niveau en dB)
#   vapeur_1..2 existaient (V61) : on écrit vapeur_3..4, au niveau des anciens ;
#   guilde_tampon existait (V71) : le tampon des bureaux s'appelle tampon_bureau.
SOUNDS = {
    "robot_bip": (robot_bip, 3, 1, -3.0), "robot_servo": (robot_servo, 3, 1, -5.0), "robot_pas": (robot_pas, 3, 1, 2.0),
    "robot_mort": (robot_mort, 2, 1, 0.0), "robot_voix": (robot_voix, 3, 1, 0.0), "drone_vol": (drone_vol, 1, 1, -3.0),
    "drone_zap": (drone_zap, 2, 1, 0.0), "soudure": (soudure, 2, 1, -2.0), "vapeur": (vapeur, 2, 3, 0.0),
    "pelleteuse_cri": (pelleteuse_cri, 2, 1, 0.0), "pelleteuse_frappe": (pelleteuse_frappe, 3, 1, 0.0),
    "durite": (durite, 2, 1, 0.0), "tapis_roulant": (tapis_roulant, 1, 1, -4.0), "tampon_bureau": (tampon_bureau, 2, 1, 0.0),
    "photocopieuse": (photocopieuse, 2, 1, -2.0), "alarme_usine": (alarme_usine, 2, 1, -2.0),
    "champignard_pouf": (champignard_pouf, 3, 1, 0.0), "champignard_rire": (champignard_rire, 3, 1, 0.0),
    "eternuement": (eternuement, 2, 1, 0.0), "champi_boing": (champi_boing, 2, 1, -3.0), "champi_magie": (champi_magie, 2, 1, 0.0),
    "champi_fin": (champi_fin, 2, 1, -2.0), "aboiement": (aboiement, 4, 1, 0.0), "aboiement_petit": (aboiement_petit, 3, 1, 0.0),
    "chat_miaou": (chat_miaou, 3, 1, 0.0), "pigeon": (pigeon, 2, 1, 0.0), "sirene_alerte": (sirene_alerte, 2, 1, -1.0),
    "radio_jingle": (radio_jingle, 2, 1, 0.0), "radio_gresillement": (radio_gresillement, 2, 1, -2.0),
    "bombe_peinture": (bombe_peinture, 2, 1, 0.0), "grue": (grue, 2, 1, 0.0), "skate": (skate, 3, 1, 0.0),
    "pogo": (pogo, 2, 1, 0.0), "foule_acclame": (foule_acclame, 2, 1, 0.0), "larsen_micro": (larsen_micro, 2, 1, -9.0),
    "guitare_riff": (guitare_riff, 3, 1, 0.0), "batterie_roulement": (batterie_roulement, 2, 1, 0.0), "cymbale": (cymbale, 2, 1, 0.0),
    "monte_charge": (monte_charge, 2, 1, -3.0), "tourniquet": (tourniquet, 2, 1, 0.0), "vanne": (vanne, 2, 1, 0.0),
    "porte_usine": (porte_usine, 2, 1, 0.0),
}
BEDS = {"boucan_jour": boucan_jour_bed, "boucan_nuit": boucan_nuit_bed, "halle": halle_bed, "spores": spores_bed,
        "casse": casse_bed, "usine": usine_bed, "port_boucan": port_boucan_bed}
LOOPS = ("drone_vol", "tapis_roulant")     # bruitages qui bouclent : pas de fondu de fin


def save_bed(name: str, x: np.ndarray) -> None:
    """Comme generate_sons_v49.save (sans infra-grave, crête à 0,89), puis on vérifie la crête du
    fichier Ogg décodé : si l'encodage la fait dépasser, on réenregistre un peu plus bas."""
    import subprocess
    import tempfile
    from scipy.io import wavfile
    path = amb.OUT / "ambiance" / f"{name}.ogg"
    path.parent.mkdir(parents=True, exist_ok=True)
    k = min(len(x) // 2, SR)
    ext = np.concatenate([x[-k:], x])
    x = amb.hp(ext.T, 28.0).T[k:]
    target = 0.89
    for _ in range(3):
        y = x / (np.max(np.abs(x)) + 1e-9) * target
        with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
            wavfile.write(tmp.name, SR, (y * 32767).astype(np.int16))
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp.name, "-c:a", "libvorbis", "-q:a", "4", str(path)], check=True)
        d = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "-"], capture_output=True, check=True).stdout
        pk = float(np.max(np.abs(np.frombuffer(d, np.float32))))
        if pk <= 0.93:
            break
        target *= 0.9 / pk
    print(f"ambiance/{name}: {len(x) / SR:.1f} s, {path.stat().st_size // 1024} Ko")


def main() -> int:
    global VSCO, VCSL, DL
    if len(sys.argv) > 1 and Path(sys.argv[1]).is_dir():
        s63.LIB = Path(sys.argv[1])
        names = sys.argv[2:]
    else:
        names = sys.argv[1:]
    VSCO = s63.LIB.parent / "VSCO-2-CE"
    VCSL = s63.LIB.parent / "VCSL"
    DL = s63.LIB.parent / "dl"
    s70.VSCO, s70.VCSL = VSCO, VCSL
    s71.VSCO, s71.VCSL, s71.DL = VSCO, VCSL, DL
    m75.VSCO, m75.VCSL, m75.CC0 = VSCO, VCSL, s63.LIB
    for name, (fn, count, first, gain_db) in SOUNDS.items():
        if names and name not in names:
            continue
        xs = []
        for k in range(count):
            reseed(name, k)
            xs.append(np.asarray(fn(k), float))
        old = [s70.loudness(s70.read_raw(fx.OUT / f"{name}_{j}.ogg")) for j in range(1, first) if (fx.OUT / f"{name}_{j}.ogg").is_file()]
        ref = (min(old) if old else min(s70.loudness(x) for x in xs)) + gain_db
        for k, x in enumerate(xs):
            y = x * 10 ** ((ref - s70.loudness(x)) / 20.0)
            if np.max(np.abs(y)) > 0.89:
                y = s68.soft_limit(y, 0.89)
            save_sfx(f"{name}_{first + k}", y)
            pk = np.max(np.abs(s70.read_raw(fx.OUT / f"{name}_{first + k}.ogg")))
            if pk > 0.93:
                save_sfx(f"{name}_{first + k}", y * 0.89 / pk)
        print(" ", name, ", ".join(f"{name}_{first + k}" for k in range(count)))
    for name, fn in BEDS.items():
        if names and name not in names:
            continue
        reseed(name)
        save_bed(name, fn(s63.LIB))
    return 0


if __name__ == "__main__":
    sys.exit(main())
