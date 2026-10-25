"""V71 : les sons de l'Île de Montjoie, la ville des aventuriers (une petite ville fortifiée sur sa
butte, sa Guilde des Aventuriers et sa taverne, le marché, le temple, le château, les champs et le
moulin, le Lac des Grenouilles, le Bois des Lutins) et du Donjon des Mille Marches (slimes, pièges,
lac souterrain, mimiques et le Roi Gélatineux). Ton : comédie d'aventuriers, chaleureuse.

Bruitages (sfx/) :
  slime_saut_1..3        un slime qui rebondit : la gelée qui s'écrase (« splotch »), le « boïng »
                         élastique qui monte, la gelée qui tremblote ; un petit saut (1), deux petits
                         sauts (2), un gros saut lourd (3) ;
  slime_mort_1..3        le slime vaincu : il se dégonfle en sifflant puis s'étale (« splotch »), les
                         gouttes qui retombent (1) ; il éclate (« plop » mouillé) (2) ; il fond en
                         glougloutant (3) ;
  slime_roi_cri_1..2     le Roi Gélatineux : un énorme rugissement gluant (« Blblblb… BWOUAAAH ! »),
                         la gelée qui gargouille, un rot royal et deux petits « bloups » pour finir ;
  slime_divise_1..2      le Roi qui se divise : la gelée qui s'étire en couinant, se déchire
                         (« sccrrlutch »), puis « plop-plop » : les petits slimes qui tombent et
                         rebondissent ;
  grenouille_coasse_1..3 une grenouille géante : un « BROOOAP » énorme et profond (1), deux coups (2),
                         un « rrri-BOUP » comique (3) ;
  grenouille_langue_1..2 la langue qui part (« fflip »), colle (« splotch ») et revient en aspirant ;
  grenouille_avale_1..2  « GLOUP » : la gorge qui avale, la langue, un petit gargouillis content ;
  grenouille_recrache_1..2 elle recrache : les joues qui gonflent (« hmmmm… »), « PTOUAH ! », le vol
                         en sifflet à coulisse et le « splotch » de l'atterrissage, couvert de bave ;
  gobelin_cri_1..3       un petit gobelin : « Gyaah ! » (1), « Hé-hé… YAK ! » (2), « Grak-grak ! » (3) ;
  gobelin_mort_1..2      « Gyaaa-aah… », il tombe, son gourdin roule ;
  gobelin_chef_cri_1..2  le chef gobelin : il se frappe la poitrine et pousse son cri de guerre
                         (« HWAAAGH ! »), ses gobelins répondent derrière ;
  navet_cri_1..3         un navet fuyard, tout petit : « Aah ! » (1), « Ah-ah-ah-ah ! » en courant
                         (2), « Iiiih ! » (3) ;
  navet_attrape_1..2     on l'attrape : le « pop » quand il sort de terre, les fanes qui
                         froufroutent, un petit « hmpf » ;
  mimique_morsure_1..2   la mimique mord : le couvercle qui claque (« CHOMP »), les dents, les
                         ferrures ; deux bouchées (2) ;
  mimique_reveil_1..2    le coffre qui se réveille : le couvercle qui grince, un grognement de
                         gorge, le coffre qui claque des dents en tremblant ;
  alerte_cloche_1..2     la cloche à main de Mélusine, la crieuse : on la secoue fort, trois secondes ;
  guilde_tampon_1..3     le tampon d'Églantine : un tapotis sur l'encreur, puis « TCHAC ! » sur la
                         carte (le 3 tamponne deux fois) ;
  rang_monte_1..2        montée de rang : une fanfare de trompettes, les cors, les timbales,
                         la cymbale, le glockenspiel ;
  cristal_mesure_1..2    la boule de cristal qui mesure les aptitudes : un bourdonnement de verre
                         qui monte, qui tremble, puis « DING ! » ;
  eclair_1..2            le grand éclair de Violette : le claquement, la détonation, le tonnerre
                         qui roule, l'électricité qui grésille ;
  eclair_rate_1..3       l'éclair raté : « bzzt… bzt… pfzzt », le grésillement, un petit « pouf » de
                         fumée (le 3 finit par un « piou » tout triste) ;
  soin_1..2              le soin de Pétronille : de petites cloches qui montent, des scintillements ;
  benediction_1..2       la bénédiction : un chœur doux qui enfle (« Aaaah »), une clochette ;
  charge_chevalier_1..2  Sire Tancrède qui charge : l'armure qui s'ébranle, les pas, « HAAAA ! » ;
  chute_armure_1..2      Tancrède qui se prend les pieds dans sa cape : « Oh ! », la dégringolade
                         de ferraille, le casque qui tournoie sur les dalles jusqu'à s'arrêter ;
  pas_armure_1..3        un pas en armure : le pas, les plaques qui cliquettent ;
  rocher_roule_1         un énorme rocher qui roule (boucle de 3 s sans raccord) ;
  piege_dalle_1..2       une dalle piégée : le « clac » de la pierre qui s'enfonce, puis le
                         mécanisme (cliquet, engrenages, chaîne) ;
  fleche_piege_1..3      un piège à fléchettes : le ressort, le sifflement, la fléchette qui se
                         plante dans le bois (le 3 ricoche sur la pierre) ;
  levier_1..2            un vieux levier : la poignée, le cliquet, le « clonk », le mécanisme au loin ;
  cristal_retour_1..2    le cristal de retour : un tourbillon de scintillements qui monte, puis
                         « fwoum » ;
  porte_donjon_1..2      une lourde porte de bois du donjon : le loquet, les gonds qui gémissent,
                         le battant contre le mur ;
  moulin_1..2            le moulin : l'arbre de bois qui grince, les ailes qui passent dans le vent ;
  coffre_pieces_1..2     des pièces qui se déversent (d'un coffre, d'une bourse) ;
  lit_dodo_1..2          le lit qui grince quand on s'y laisse tomber, puis un ronflement comique ;
  luth_1..3              une courte fioriture de luth (le luth de Bertrand, le barde).
Nappes d'ambiance (ambiance/, boucles sans raccord, stéréo) :
  montjoie_jour          la ville, le jour : la rumeur de la foule, les marchands, les rires, une
                         forge au loin, une charrette et son cheval sur les pavés, la fontaine, les
                         moineaux et les pigeons, la cloche du temple de temps en temps ;
  montjoie_nuit          la ville, la nuit : les grillons, le vent, au loin les rires de la taverne de
                         la Guilde et un luth, un chien, la chouette ;
  guilde                 la taverne de la Guilde, pleine et joyeuse : les conversations, les rires,
                         les chopes qui trinquent, les chaises, le plancher, le feu, le tampon et la
                         sonnette du comptoir, et, au fond, Bertrand qui joue du luth ;
  campagne               les champs : le vent dans les herbes, les alouettes, le moulin au loin,
                         les vaches, une abeille qui passe ;
  lac_grenouilles        le lac : l'eau qui clapote, les roseaux, des grenouilles partout, et de
                         temps en temps le coassement très grave et comique d'une grenouille géante ;
  foret_lutins           le Bois des Lutins : les oiseaux, les feuilles, un pic-vert, une brindille,
                         et de temps en temps, au loin, le babil des gobelins ;
  donjon_caves           le donjon : des gouttes, l'air des galeries, des échos lointains, de légers
                         « splotch » de slimes ;
  donjon_lac             le lac souterrain : l'eau qui clapote sous la voûte, un filet d'eau, les
                         gouttes et leurs longs échos.
Synthétisés ici (domaine public), ou retravaillés (découpés, transposés, ralentis, filtrés,
réverbérés) d'après : le recueil CC0 « lavenderdotpet/CC0-Public-Domain-Sounds » (« 80 CC0 creature
SFX » 1 et 2, « 80 CC0 RPG SFX », packs Kenney Impact, RPG et Voiceover, « 100 CC0 wood/metal SFX »,
« 100 CC0 SFX », « 75 CC0 breaking/falling/hit », « 40 CC0 water splash/slime », « 30 CC0 SFX loops »,
« BB Retail Therapy Sample Pack », « bb - Bottle Plops », « bb - Slide Whistle », « bb - Smol
Mechanisms », « bb - Books, Paper, Writing » (Ben Burnes), les rires de « Free Retro Arcade Sounds »
(The Motion Monkey)) ; les enregistrements « nature-forest-day » (Sadiquecat), « wind-breeze »
(keweldog) et « water-stream » (SamsterBirdies), CC0, via github.com/DNAABR/ambient-sounds-library ;
la banque VSCO-2 CE (Versilian Studios, CC0 : trompette, cor, timbales, cymbale, glockenspiel) ; la
« Versilian Community Sample Library » (VCSL, Versilian Studios, CC0 : enclumes, verres frottés) :
tout est libre de droits. Le luth (corde pincée de Karplus-Strong, en chœurs doubles) et le chœur
sont synthétisés.
Chaque son a ses propres graines (tirées de son nom) : on peut n'en refaire qu'un, il sort à
l'identique.
Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/generate_sons_v71.py [dossier CC0-Public-Domain-Sounds] [noms...]
(les banques VSCO-2-CE et VCSL et le dossier « dl » des enregistrements sont cherchés à côté du
recueil ; sans eux, les sons qui en viennent sont faits seulement de synthèse)
"""
from pathlib import Path
import sys
import zlib

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v70 as s70  # noqa: E402
import generate_sons_v69 as s69  # noqa: E402
import generate_sons_v68 as s68  # noqa: E402
import generate_sons_v63 as s63  # noqa: E402
import generate_sons_v59 as s59  # noqa: E402
import generate_sons_v56 as s56  # noqa: E402
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402

SR = 44100
RNG = np.random.default_rng(7171)
VSCO = s63.LIB.parent / "VSCO-2-CE"
VCSL = s63.LIB.parent / "VCSL"
DL = s63.LIB.parent / "dl"

_t, _norm, _fade, mix, noise, rec, slow = s63._t, s63._norm, s63._fade, s63.mix, s63.noise, s63.rec, s63.slow
trim, cut, unit, addp, clip_rec = s68.trim, s68.cut, s68.unit, s68.addp, s68.clip_rec
clack, thump, formants, wplace, room_wrap = s68.clack, s68.thump, s68.formants, s68.wplace, s68.room_wrap
scatter, loop_layer, finish_bed, shout, modal, glottal = s68.scatter, s68.loop_layer, s68.finish_bed, s68.shout, s68.modal, s68.glottal
syllabe, crepite, sifflement, bouffee, tinte, etincelles, blorp, eclabousse = (
    s70.syllabe, s70.crepite, s70.sifflement, s70.bouffee, s70.tinte, s70.etincelles, s70.blorp, s70.eclabousse)
sweep, disperse, place_st, pan_move, room, rmsn, finish = s70.sweep, s70.disperse, s70.place_st, s70.pan_move, s70.room, s70.rmsn, s70.finish
lp, hp, bp, texture = s70.lp, s70.hp, s70.bp, s70.texture
grains, whisper = s69.grains, s69.whisper

KI = "kenney_impactsounds/Audio/"
KR = "kenney_rpgaudio/Audio/"
WM = "100-CC0-wood-metal-SFX/"
SX = "100-CC0-SFX/"
SPL = "40-cc0-water-splash-slime-sfx/"
BBR = "BB_Retail Therapy Sample Pack/"
CRE = "80-CC0-creature-SFX/"
CRE2 = "80-CC0-creature-sfx-2/"
RPG = "80-CC0-RPG-SFX/"
BFH = "75-cc0-breaking-falling-hit-sfx/"
ARC = "MMRetroArcadeSoundsPack1_0_5/Vocal/wav/"
PLOP = "bb - Bottle Plops (Apr 2021)/Plop - "
SLW = "bb - Slide Whistle (Aug 2021)/"
MECA = "bb - Smol Mechanisms (May 2021)/"
PEN = "bb - Books, Paper, Writing (Jan 2021)/"


# =================================================================== outils

def reseed(name: str, k: int = 0) -> None:
    """Chaque son a ses propres graines (tirées de son nom) : refaire un seul son le redonne à l'identique."""
    global RNG
    base = [7171, zlib.crc32(name.encode()), k]
    RNG = np.random.default_rng(base + [0])
    s70.RNG = np.random.default_rng(base + [8])
    s69.RNG = np.random.default_rng(base + [1])
    s68.RNG = np.random.default_rng(base + [2])
    s63.RNG = np.random.default_rng(base + [3])
    s59.RNG = np.random.default_rng(base + [4])
    s56.RNG = np.random.default_rng(base + [5])
    amb.RNG = np.random.default_rng(base + [6])


def nz(n: int) -> np.ndarray:
    return RNG.standard_normal(n)


def dlrec(name: str) -> np.ndarray:
    """Un enregistrement du dossier « dl » (DNAABR/ambient-sounds-library, CC0), mono, s'il est là."""
    p = DL / name
    return amb.read_any(p).mean(axis=1) if p.is_file() else np.zeros(0)


def env_ad(n: int, a: float, d: float) -> np.ndarray:
    x = np.arange(n) / SR
    return np.clip(x / max(a, 1e-4), 0, 1) * np.exp(-x / d)


def hann_burst(dur: float, lo: float, hi: float) -> np.ndarray:
    m = int(dur * SR)
    return bp(nz(m), lo, hi) * np.hanning(m)


def chirp(f, dur: float, harm=(1.0, 0.3), shape=None) -> np.ndarray:
    """Un sinus dont la hauteur suit les points f (glissé), quelques harmoniques, enveloppe douce."""
    x = _t(dur)
    fp = np.asarray(f, float)
    ff = np.interp(x, np.linspace(0, dur, len(fp)), fp)
    ph = 2 * np.pi * np.cumsum(ff) / SR
    y = sum(a * np.sin((i + 1) * ph) for i, a in enumerate(harm))
    e = np.sin(np.pi * np.clip(x / dur, 0, 1)) ** 0.6 if shape is None else shape(x)
    return y * e


# =================================================================== briques : gelée, VSCO, luth

SLIMES = [SPL + "slime_%02d.ogg" % i for i in range(1, 17)] + [CRE2 + "slime_%02d.ogg" % i for i in range(1, 9)]


def gelee(i: int, semi: float = 0.0, max_s: float = 0.6, lp_hz: float = 5000.0) -> np.ndarray:
    """Un « splotch » de gelée (enregistrement du recueil)."""
    return lp(clip_rec(SLIMES[i % len(SLIMES)], semi, max_s, 0.15), lp_hz)


def jelly(f0: float, fpk: float, f1: float, dur: float, wob: float = 15.0, depth: float = 0.5) -> np.ndarray:
    """Le « boïng » d'une gelée : une note ronde qui monte puis retombe, et la gelée qui tremblote
    (modulation d'amplitude et de hauteur qui s'amortit)."""
    x = _t(dur)
    f = np.interp(x, [0, 0.35 * dur, dur], [f0, fpk, f1])
    w = np.sin(2 * np.pi * wob * x) * np.exp(-x / (0.5 * dur))
    f = f * (1 + 0.06 * w)
    ph = 2 * np.pi * np.cumsum(f) / SR
    y = np.sin(ph) + 0.35 * np.sin(2 * ph) + 0.12 * np.sin(3 * ph)
    y *= (1 - depth * 0.5 + depth * 0.5 * w) * np.clip(x / 0.006, 0, 1) * np.exp(-x / (0.45 * dur))
    return y


_VS = {}


def vsco_note(key: str, midi: float, dur: float, vel: float = 0.6) -> np.ndarray:
    """Une note d'un pupitre de VSCO-2 CE (définitions de compose_musique_v51), en mono."""
    import compose_musique_v51 as cm
    if not VSCO.is_dir():
        return np.zeros(int(dur * SR))
    cm.VSCO = VSCO
    if key not in _VS:
        try:
            _VS[key] = cm.I(key)
        except (FileNotFoundError, ValueError, KeyError):
            _VS[key] = None
    ins = _VS[key]
    if ins is None:
        return np.zeros(int(dur * SR))
    return np.asarray(ins.note(midi, dur, vel), float).mean(axis=1)


_LUTH = {}


def luth_note(midi: float, dur: float, vel: float = 0.6) -> np.ndarray:
    """Une note de luth : deux cordes accordées à l'unisson (un chœur), pincées près du chevalet
    (corde de Karplus-Strong de compose_musique_v56.Guitar), un timbre un peu nasal."""
    import compose_musique_v56 as cm56
    if not _LUTH:
        _LUTH["a"] = cm56.Guitar("luth_a", pan=0.0, width=0.4, gain=1.0, decay=0.9935, bright=0.9)
        _LUTH["b"] = cm56.Guitar("luth_b", pan=0.0, width=0.4, gain=1.0, decay=0.993, bright=0.8)
    a = np.asarray(_LUTH["a"].note(midi + 0.03, dur, vel), float).mean(axis=1)
    b = np.asarray(_LUTH["b"].note(midi - 0.03, dur, vel * 0.85), float).mean(axis=1)
    d = int(0.004 * SR)
    y = addp(a, np.concatenate([np.zeros(d), b]))
    y = hp(y, 140.0) + bp(y, 900.0, 1800.0) * 0.8
    return y


def luth_phrase(notes, gap: float = 0.0) -> np.ndarray:
    """Une phrase de luth : [(midi ou liste de midis pour un accord gratté, durée en s, force)]."""
    tot = sum(d for _, d, _ in notes) + 1.6
    out = np.zeros(int(tot * SR))
    t = 0.0
    for m, d, v in notes:
        ms = m if isinstance(m, (list, tuple)) else [m]
        for j, mm in enumerate(ms):
            amb.place(out, luth_note(mm, max(d, 0.25) + 0.8, v), int((t + j * 0.018) * SR), 1.0)
        t += d
    return out


# =================================================================== les slimes

def slime_saut(k: int) -> np.ndarray:
    parts = []
    if k == 0:
        parts += [(gelee(2, 2.0, 0.35), 0.0, 0.7), (unit(jelly(150.0, 330.0, 210.0, 0.42, 16.0)), 0.02, 0.8),
                  (unit(thump(120.0, 70.0, 0.03, 0.15)), 0.0, 0.4), (gelee(5, 3.0, 0.3), 0.44, 0.55),
                  (unit(jelly(210.0, 240.0, 170.0, 0.3, 19.0, 0.8)), 0.45, 0.3)]
        dur = 1.0
    elif k == 1:
        for i, (t, f) in enumerate(((0.0, 1.0), (0.36, 1.15))):
            parts += [(gelee(7 + i * 3, 4.0 + 2 * i, 0.3), t, 0.6), (unit(jelly(180.0 * f, 380.0 * f, 250.0 * f, 0.3, 18.0)), t + 0.015, 0.75),
                      (unit(thump(140.0, 80.0, 0.025, 0.12)), t, 0.3)]
        parts += [(gelee(12, 5.0, 0.25), 0.7, 0.45), (unit(jelly(260.0, 300.0, 200.0, 0.3, 22.0, 0.9)), 0.71, 0.25)]
        dur = 1.2
    else:
        parts += [(gelee(1, -3.0, 0.5, 3500.0), 0.0, 0.8), (unit(jelly(90.0, 230.0, 140.0, 0.6, 11.0)), 0.02, 1.0),
                  (unit(thump(80.0, 45.0, 0.06, 0.3)), 0.0, 0.6), (gelee(16, -4.0, 0.55, 3000.0), 0.64, 0.9),
                  (unit(thump(70.0, 40.0, 0.08, 0.4)), 0.64, 0.7), (unit(jelly(140.0, 170.0, 110.0, 0.5, 9.0, 0.9)), 0.66, 0.45)]
        parts += eclabousse(0.7, 1.0, 4, f=(250.0, 480.0), g=(0.05, 0.15))
        dur = 1.6
    out = mix(dur, *parts)
    out = room(out, 0.4, 9.0, 6000.0, 0.06, seed=7101 + k)
    return finish(out, 0.88, 0.2)


def slime_mort(k: int) -> np.ndarray:
    parts = []
    if k == 0:
        # il se dégonfle en sifflant (le petit couinement qui descend), puis s'étale
        d = 0.55
        x = _t(d)
        sq = np.sin(2 * np.pi * np.cumsum(np.interp(x, [0, d], [720.0, 180.0]) * (1 + 0.03 * np.sin(2 * np.pi * 28 * x))) / SR)
        sq = (sq + bp(nz(len(x)), 800, 4000) * 0.35) * np.clip(x / 0.02, 0, 1) * np.clip((d - x) / 0.1, 0, 1)
        parts += [(unit(sq), 0.0, 0.55), (gelee(3, -2.0, 0.6, 4000.0), d - 0.03, 1.0),
                  (unit(thump(110.0, 60.0, 0.05, 0.25)), d - 0.02, 0.5)]
        parts += eclabousse(d + 0.1, d + 0.7, 7, f=(260.0, 520.0), g=(0.06, 0.2))
        dur = d + 1.0
    elif k == 1:
        # il éclate : « PLOP » mouillé, les éclaboussures
        pop = lp(clip_rec(PLOP + "Airy 2.wav", -3.0, 0.4, 0.1), 6000)
        parts += [(unit(blorp(160.0, 420.0, 0.12, 1.0)), 0.0, 0.8), (pop, 0.1, 0.8), (gelee(9, 0.0, 0.5), 0.11, 0.9),
                  (lp(clip_rec(SPL + "splash_03.ogg", 3.0, 0.6, 0.2), 5000), 0.12, 0.35)]
        parts += eclabousse(0.25, 0.9, 10, f=(300.0, 650.0), g=(0.05, 0.18))
        dur = 1.3
    else:
        # il fond en glougloutant
        parts += [(gelee(14, -5.0, 0.8, 3000.0), 0.0, 0.8)]
        for i in range(5):
            parts.append((unit(blorp(RNG.uniform(120, 200), RNG.uniform(300, 500), RNG.uniform(0.05, 0.1), 0.6)), 0.15 + i * 0.16, 0.6 - 0.08 * i))
        parts += [(lp(clip_rec(PLOP + "Viscous 2.wav", -2.0, 0.8, 0.3), 2500), 0.2, 0.5),
                  (unit(jelly(240.0, 200.0, 90.0, 0.9, 7.0, 0.7)), 0.05, 0.3)]
        dur = 1.7
    out = mix(dur, *parts)
    out = room(out, 0.5, 8.0, 6000.0, 0.08, seed=7104 + k)
    return finish(out, 0.88, 0.25)


def gargouillis(dur: float, rate: float = 14.0, depth: float = 0.6) -> np.ndarray:
    """La gelée qui gargouille : une modulation d'amplitude bulleuse, irrégulière."""
    x = _t(dur)
    r = rate * (1 + 0.4 * amb.smooth_env(len(x), 3.0, -1, 1))
    ph = np.cumsum(r) / SR
    b = np.abs(np.sin(np.pi * ph)) ** 3
    return 1 - depth + depth * b


def slime_roi_cri(k: int) -> np.ndarray:
    parts = []
    if k == 0:
        # « Blblblb… BWOUAAAH ! » : les lèvres de gelée qui vibrent, puis le grand cri gluant
        d0 = 0.45
        x = _t(d0)
        lips = syllabe(d0, [95.0, 105.0], "ou", 0.7, h=0.0, souffle=0.2, sat=1.4, sub=0.3)
        lips *= (0.35 + 0.65 * (np.sin(2 * np.pi * 24 * x) > 0))[: len(lips)]
        parts.append((unit(lp(lips, 1800)), 0.0, 0.55))
        d = 1.9
        roar = syllabe(d, [62.0, 88.0, 96.0, 84.0, 58.0], "ou", 0.62, h=0.1, souffle=0.4, rasp=0.12, sub=0.8, sat=2.4,
                       voy2="a", att=0.12, rel=0.6, tilt=0.95)
        roar *= gargouillis(d, 16.0, 0.45)[: len(roar)]
        parts += [(unit(roar), d0, 1.0), (lp(slow(clip_rec(CRE + "burble_01.ogg", -2.0), 1.7), 2200), d0 + 0.1, 0.4),
                  (lp(slow(clip_rec(CRE2 + "slime_03.ogg", -3.0), 1.8), 2500), d0 + 0.05, 0.5),
                  (lp(slow(clip_rec(CRE + "roar_02.ogg", -3.0), 1.6), 1800), d0 + 0.2, 0.25)]
        for t in np.linspace(d0 + 0.2, d0 + d - 0.2, 7):
            parts.append((unit(blorp(RNG.uniform(70, 110), RNG.uniform(200, 320), RNG.uniform(0.08, 0.16), 0.7)), t, 0.3))
        te = d0 + d + 0.05
        parts += [(lp(slow(clip_rec(CRE + "burp_01.ogg", -4.0), 1.5), 2500), te, 0.55),
                  (unit(blorp(150.0, 380.0, 0.08, 0.8)), te + 0.6, 0.35), (unit(blorp(190.0, 460.0, 0.06, 0.8)), te + 0.78, 0.3)]
        dur = te + 1.3
    else:
        # « Gloo-oo-OOOH ! » : il monte, tremble de toute sa gelée, et retombe en gargouillant
        d = 2.2
        roar = syllabe(d, [55.0, 70.0, 82.0, 104.0, 98.0, 66.0], "o", 0.6, h=0.12, souffle=0.45, rasp=0.15, sub=0.9, sat=2.6,
                       voy2="a", att=0.2, rel=0.6, vib=0.05)
        roar *= gargouillis(d, 11.0, 0.5)[: len(roar)]
        parts += [(unit(roar), 0.0, 1.0), (lp(slow(clip_rec(CRE2 + "monster_12.ogg", -3.0), 1.7), 2000), 0.1, 0.3),
                  (lp(slow(clip_rec(SPL + "slime_09.ogg", -4.0), 2.0), 2200), 0.0, 0.5),
                  (lp(slow(clip_rec(SPL + "slime_13.ogg", -2.0), 1.8), 2400), 1.0, 0.45),
                  (unit(jelly(70.0, 120.0, 50.0, 1.6, 6.0, 0.9)), 0.4, 0.35)]
        for t in np.linspace(0.3, d, 8):
            parts.append((unit(blorp(RNG.uniform(60, 100), RNG.uniform(180, 300), RNG.uniform(0.08, 0.18), 0.7)), t, 0.28))
        parts += [(gelee(4, -6.0, 0.6, 2500.0), d + 0.05, 0.6), (unit(thump(60.0, 35.0, 0.12, 0.5)), d + 0.05, 0.5),
                  (unit(blorp(140.0, 350.0, 0.07, 0.8)), d + 0.6, 0.3)]
        dur = d + 1.3
    out = lp(mix(dur, *parts), 5000.0)
    out = room(out, 1.8, 2.4, 3500.0, 0.2, seed=7107 + k)
    return finish(out, 0.92, 0.5)


def slime_divise(k: int) -> np.ndarray:
    parts = []
    d = [0.75, 0.6][k]
    x = _t(d)
    # la gelée qui s'étire : un frottement mouillé dont la couleur monte, un petit couinement
    st = sweep(nz(len(x)), np.interp(x, [0, d], [350.0, 1800.0]), q=2.5) * np.clip(x / 0.1, 0, 1) * np.clip((d - x) / 0.05, 0, 1)
    st *= gargouillis(d, 30.0, 0.5)[: len(st)]
    squeak = chirp([400.0, 650.0, 900.0], d, (1.0, 0.4, 0.2))
    parts += [(unit(st), 0.0, 0.6), (unit(squeak), 0.0, 0.25), (lp(slow(clip_rec(SPL + "slime_06.ogg", 0.0), 1.4), 4500), 0.0, 0.5)]
    # ça se déchire
    parts += [(gelee(10, 2.0, 0.4), d, 0.9), (unit(hann_burst(0.06, 600, 5000)), d, 0.4)]
    # les petits slimes qui tombent et rebondissent
    n_small = [2, 3][k]
    for i in range(n_small):
        t = d + 0.2 + i * RNG.uniform(0.13, 0.2)
        f = RNG.uniform(1.0, 1.4)
        parts += [(unit(blorp(170.0 * f, 420.0 * f, 0.06, 0.9)), t, 0.6), (gelee(11 + i, 5.0, 0.25), t + 0.04, 0.4),
                  (unit(jelly(220.0 * f, 460.0 * f, 300.0 * f, 0.25, 20.0)), t + 0.06, 0.45)]
    dur = d + 0.4 + n_small * 0.2 + 0.6
    out = mix(dur, *parts)
    out = room(out, 0.9, 5.0, 5000.0, 0.12, seed=7109 + k)
    return finish(out, 0.88, 0.25)


# =================================================================== les grenouilles géantes

def croak(f0: float = 60.0, dur: float = 0.55, rate: float = 26.0, size: float = 1.0, tp=(1.0, 1.08, 0.9)) -> np.ndarray:
    """Le coassement d'une grenouille géante : une voix très grave en impulsions serrées (la gorge qui
    claque), le sac vocal qui résonne (le sous-grave), une bouche de grande taille (formants bas)."""
    x = _t(dur)
    f = f0 * np.interp(x, np.linspace(0, dur, len(tp)), tp)
    src = glottal(f, tilt=0.85, fmax=3000.0, jitter=0.02)
    src /= np.std(src) + 1e-9
    gate = 0.25 + 0.75 * (np.sin(2 * np.pi * np.cumsum(np.full(len(x), rate)) / SR) > -0.2)
    gate = lp(gate, 300.0)
    y = formants(src * gate, [(230 / size, 90, 1.0), (560 / size, 140, 0.7), (1050 / size, 220, 0.3), (1900 / size, 300, 0.1)])
    sac = np.sin(2 * np.pi * np.cumsum(f) / SR) * gate * 0.8
    y = lp(np.tanh(1.6 * unit(y + sac * np.std(y) * 2.5)), 3200.0)
    return y * np.clip(x / 0.03, 0, 1) * np.clip((dur - x) / 0.09, 0, 1)


def grenouille_coasse(k: int) -> np.ndarray:
    parts = []
    if k == 0:
        parts += [(unit(croak(52.0, 0.85, 24.0, 1.25, (0.95, 1.1, 1.0, 0.85))), 0.0, 1.0),
                  (lp(slow(clip_rec(CRE + "burble_02.ogg", -3.0), 1.8), 1600), 0.05, 0.25)]
        dur = 1.6
    elif k == 1:
        parts += [(unit(croak(62.0, 0.45, 28.0, 1.15)), 0.0, 1.0), (unit(croak(56.0, 0.6, 26.0, 1.2, (1.0, 1.05, 0.85))), 0.6, 0.95)]
        dur = 1.8
    else:
        # « rrri-BOUP » : un roulement aigu, puis le gros « boup » rond
        parts += [(unit(croak(110.0, 0.25, 40.0, 0.9, (0.9, 1.2))), 0.0, 0.6),
                  (unit(croak(70.0, 0.32, 22.0, 1.1, (1.2, 1.0, 0.8))), 0.3, 1.0),
                  (unit(jelly(90.0, 140.0, 80.0, 0.35, 9.0, 0.4)), 0.32, 0.35)]
        dur = 1.2
    out = mix(dur, *parts)
    out = room(out, 0.9, 4.5, 3500.0, 0.12, seed=7111 + k)
    return finish(out, 0.9, 0.25)


def grenouille_langue(k: int) -> np.ndarray:
    parts = []
    # « fflip » : la langue part
    w = s63.whoosh(0.13, 3500.0, 900.0, 0.6)
    tw = chirp([1800.0, 600.0], 0.1, (1.0, 0.3))
    parts += [(unit(clack(500.0, 0.01, 0.3, 0.4)), 0.0, 0.4), (unit(w), 0.0, 0.7), (unit(tw), 0.01, 0.25)]
    t_hit = [0.14, 0.18][k]
    parts += [(gelee(4 + k * 5, 4.0, 0.25), t_hit, 0.8), (unit(thump(180.0, 110.0, 0.02, 0.1)), t_hit, 0.3)]
    # elle revient en aspirant
    d = [0.35, 0.5][k]
    x = _t(d)
    slurp = sweep(nz(len(x)), np.interp(x, [0, d], [500.0, 2600.0]), q=3.0) * np.sin(np.pi * np.clip(x / d, 0, 1)) ** 0.7
    slurp *= gargouillis(d, 35.0, 0.6)[: len(slurp)]
    sl = gelee(8, -1.0, 0.5)[::-1]
    parts += [(unit(slurp), t_hit + 0.12, 0.6), (_fade(sl, 0.05, 0.02), t_hit + 0.1, 0.4),
              (unit(clack(380.0, 0.015, 0.2, 0.6)), t_hit + 0.12 + d, 0.5)]
    if k == 1:
        parts.append((lp(clip_rec(SLW + "Quick Low.wav", -2.0, 0.4, 0.1), 3000), t_hit + 0.1, 0.25))
    dur = t_hit + d + 0.5
    out = mix(dur, *parts)
    out = room(out, 0.5, 8.0, 6000.0, 0.08, seed=7114 + k)
    return finish(out, 0.88, 0.15)


def grenouille_avale(k: int) -> np.ndarray:
    parts = []
    # « GLOUP » : la gorge, la voix grave qui tombe d'un coup
    g = syllabe(0.32, [130.0, 95.0, 60.0], "ou", 0.7, h=0.0, souffle=0.2, sat=1.6, sub=0.6, att=0.01, rel=0.08)
    parts += [(unit(thump(95.0, 50.0, 0.06, 0.3)), 0.0, 0.8), (unit(lp(g, 1500)), 0.0, 0.9),
              (lp(clip_rec(CRE + "eat_0%d.ogg" % (1 + k), -6.0, 0.5, 0.2), 2500), 0.0, 0.35),
              (lp(clip_rec(SPL + "bubble_0%d.ogg" % (1 + k), -6.0, 0.6, 0.2), 1800), 0.18, 0.4)]
    if k == 0:
        parts += [(unit(thump(80.0, 40.0, 0.07, 0.3)), 0.4, 0.5), (unit(lp(syllabe(0.22, [110.0, 75.0], "ou", 0.7, h=0.0, sat=1.4, sub=0.5), 1300)), 0.4, 0.5)]
        tail = 0.75
    else:
        tail = 0.45
    # un petit gargouillis content (« mmm-bop »)
    parts += [(unit(croak(75.0, 0.3, 30.0, 1.1, (1.0, 1.1))), tail + 0.15, 0.4),
              (unit(blorp(90.0, 220.0, 0.08, 0.6)), tail + 0.05, 0.3)]
    dur = tail + 0.9
    out = mix(dur, *parts)
    out = room(out, 0.6, 6.0, 3500.0, 0.1, seed=7116 + k)
    return finish(out, 0.9, 0.2)


def grenouille_recrache(k: int) -> np.ndarray:
    parts = []
    # les joues qui gonflent : « hmmmm… » qui monte, étouffé
    d = [0.9, 0.7][k]
    hm = syllabe(d, [70.0, 85.0, 120.0], "ou", 0.65, h=0.0, souffle=0.15, rasp=0.05, sub=0.5, sat=1.4, att=0.1, rel=0.05)
    parts += [(unit(lp(hm, 900)), 0.0, 0.6), (lp(slow(clip_rec(CRE + "burble_01.ogg", 0.0), 1.4), 1500), 0.1, 0.25)]
    # « PTOUAH ! »
    t = d
    pt = syllabe(0.32, [160.0, 210.0, 120.0], "a", 0.75, h=0.07, souffle=0.6, sat=2.0, sub=0.3, att=0.005, rel=0.15)
    parts += [(unit(hann_burst(0.03, 500, 6000)), t, 0.9), (unit(bouffee(0.4, 200.0, 3000.0, 0.002)), t, 0.8), (unit(pt), t + 0.01, 0.7),
              (clip_rec(CRE + "spit_0%d.ogg" % (1 + k), -4.0, 0.6, 0.2), t, 0.6), (gelee(15, 0.0, 0.4), t + 0.02, 0.5)]
    # le vol, en sifflet à coulisse, puis l'atterrissage tout baveux
    sw = lp(clip_rec(SLW + ["Fast Drop.wav", "Wobble Drop.wav"][k], 0.0, 0.9, 0.2), 6000)
    parts += [(sw, t + 0.15, 0.35)]
    tl = t + [0.9, 1.0][k]
    parts += [(gelee(1, -3.0, 0.6, 4000.0), tl, 0.9), (unit(thump(110.0, 60.0, 0.06, 0.3)), tl, 0.6),
              (lp(clip_rec(SPL + "splash_05.ogg", 2.0, 0.6, 0.2), 4000), tl, 0.4)]
    parts += eclabousse(tl + 0.08, tl + 0.6, 6, f=(260.0, 520.0), g=(0.05, 0.15))
    dur = tl + 1.0
    out = mix(dur, *parts)
    out = room(out, 0.8, 5.5, 5000.0, 0.1, seed=7118 + k)
    return finish(out, 0.9, 0.3)


# =================================================================== les gobelins

def gob(dur: float, f0, voy: str = "a", voy2=None, rasp: float = 0.08, sat: float = 1.8, scale: float = 1.3, **kw) -> np.ndarray:
    """Une syllabe de gobelin : petite gorge nasillarde et rauque."""
    return syllabe(dur, f0, voy, scale, h=kw.pop("h", 0.02), souffle=kw.pop("souffle", 0.25), rasp=rasp, sat=sat,
                   sub=kw.pop("sub", 0.15), voy2=voy2, tilt=0.85, **kw)


def gobelin_cri(k: int) -> np.ndarray:
    parts = []
    if k == 0:
        parts += [(unit(gob(0.42, [300.0, 420.0, 390.0, 280.0], "a", "è", 0.09, 2.0, att=0.01, rel=0.1)), 0.0, 1.0),
                  (lp(clip_rec(CRE + "grunt_0%d.ogg" % 2, 6.0, 0.5, 0.2), 3500), 0.0, 0.15)]
        dur = 0.8
    elif k == 1:
        t = 0.0
        for f in (380.0, 360.0):
            parts.append((unit(gob(0.09, [f, f * 0.92], "é", h=0.03, souffle=0.4, sat=1.2, rel=0.03)), t, 0.55))
            t += 0.15
        t += 0.12
        parts.append((unit(gob(0.3, [330.0, 470.0, 300.0], "a", "è", 0.1, 2.2, att=0.008, rel=0.08)), t, 1.0))
        dur = t + 0.6
    else:
        t = 0.0
        for i, f in enumerate((340.0, 360.0)):
            parts.append((unit(gob(0.17, [f * 0.9, f * 1.1, f * 0.85], "a", "o", 0.14, 2.4, att=0.006, rel=0.05)), t, 0.95))
            parts.append((unit(clack(1300.0, 0.008, 0.6, 0.3)), t, 0.15))
            t += 0.24
        dur = t + 0.5
    out = mix(dur, *parts)
    out = room(out, 0.5, 8.0, 6000.0, 0.08, seed=7121 + k)
    return finish(out, 0.86, 0.15)


def gobelin_mort(k: int) -> np.ndarray:
    parts = []
    d = [0.75, 0.6][k]
    y = gob(d, [420.0, 380.0, 280.0, 170.0], "a", "o", 0.1, 1.6, att=0.01, rel=0.25, vib=0.02)
    parts.append((unit(y), 0.0, 1.0))
    t = d - 0.05
    parts += [(clip_rec(KI + "impactSoft_medium_00%d.ogg" % (1 + k), -2.0), t, 0.7), (unit(thump(120.0, 70.0, 0.05, 0.2)), t, 0.4)]
    # le gourdin qui tombe et roule
    for i, dt in enumerate((0.08, 0.22, 0.3, 0.36)):
        parts.append((unit(clack(RNG.uniform(420, 600), 0.03, 0.5, 0.5)), t + dt, 0.5 * 0.7 ** i))
    if k == 1:
        parts.append((unit(gob(0.18, [260.0, 200.0], "eu", sat=1.0, souffle=0.5, rel=0.08)), t + 0.5, 0.35))
    dur = t + 1.0
    out = mix(dur, *parts)
    out = room(out, 0.5, 8.0, 5000.0, 0.08, seed=7123 + k)
    return finish(out, 0.86, 0.2)


def gobelin_chef_cri(k: int) -> np.ndarray:
    parts = []
    # deux coups de poing sur la poitrine (le plastron de cuir)
    for i, t in enumerate((0.0, 0.26)):
        parts += [(unit(thump(95.0, 60.0, 0.05, 0.2)), t, 0.8), (clip_rec(KI + "impactPunch_medium_00%d.ogg" % i, -4.0), t, 0.5)]
    t0 = 0.58
    d = [1.3, 1.1][k]
    roar = syllabe(d, [150.0, 230.0, 250.0, 215.0, 160.0], "a", 0.95, h=0.08, souffle=0.4, rasp=0.13, sub=0.4, sat=2.6,
                   voy2="o" if k == 0 else "è", att=0.05, rel=0.35, tilt=0.85)
    parts += [(unit(roar), t0, 1.0), (lp(clip_rec(CRE2 + "attack_0%d.ogg" % (2 + k), 0.0, 1.2, 0.3), 3000), t0 + 0.05, 0.2)]
    if k == 1:
        parts.append((unit(syllabe(0.35, [190.0, 170.0], "a", 0.95, h=0.03, souffle=0.3, rasp=0.1, sat=2.2, rel=0.1)), t0 + d + 0.08, 0.7))
    # ses gobelins répondent derrière (plus aigus, plus loin)
    for i in range(6):
        f = RNG.uniform(300, 430)
        g = gob(RNG.uniform(0.25, 0.45), [f * 0.9, f * 1.15, f * 0.95], RNG.choice(["a", "è", "o"]), rasp=0.1, sat=1.8)
        parts.append((unit(lp(g, 3500)), t0 + d * 0.6 + RNG.uniform(0, 0.35), RNG.uniform(0.15, 0.3)))
    dur = t0 + d + 1.0
    out = mix(dur, *parts)
    out = room(out, 1.1, 4.0, 4500.0, 0.14, seed=7125 + k)
    return finish(out, 0.9, 0.35)


# =================================================================== les navets fuyards

def petit(dur: float, f0, voy: str = "a", voy2=None, **kw) -> np.ndarray:
    """Une toute petite voix (un navet !) : très aiguë, formants de poupée."""
    return syllabe(dur, f0, voy, 1.75, h=kw.pop("h", 0.01), souffle=kw.pop("souffle", 0.2), sat=kw.pop("sat", 1.0),
                   voy2=voy2, tilt=1.0, fmax=9000.0, **kw)


def pitter(n: int, rate: float = 13.0) -> np.ndarray:
    """De tout petits pieds (des racines !) qui trottinent sur la terre."""
    out = np.zeros(int((n / rate + 0.2) * SR))
    for i in range(n):
        c = addp(unit(clack(RNG.uniform(900, 1400), 0.006, 0.4, 0.4)), unit(hann_burst(0.012, 800, 4000)) * 0.5)
        amb.place(out, c, int(i / rate * SR * RNG.uniform(0.95, 1.05)), RNG.uniform(0.4, 1.0))
    return lp(out, 6000)


def navet_cri(k: int) -> np.ndarray:
    parts = []
    if k == 0:
        parts.append((unit(petit(0.32, [880.0, 1250.0, 1150.0, 900.0], "a", "è", att=0.01, rel=0.08)), 0.0, 1.0))
        parts.append((unit(pitter(6)), 0.3, 0.25))
        dur = 0.95
    elif k == 1:
        t = 0.0
        for i in range(4):
            f = 1000.0 + 60.0 * (i % 2)
            parts.append((unit(petit(0.11, [f * 0.95, f * 1.15, f], "a", att=0.008, rel=0.03)), t, 0.9))
            t += 0.17
        parts.append((unit(pitter(11, 14.0)), 0.0, 0.35))
        dur = t + 0.4
    else:
        parts.append((unit(petit(0.45, [1300.0, 1550.0, 1500.0, 1250.0], "i", vib=0.03, att=0.01, rel=0.12)), 0.0, 1.0))
        parts.append((unit(pitter(5, 12.0)), 0.42, 0.25))
        dur = 1.0
    out = mix(dur, *parts)
    out = room(out, 0.3, 12.0, 8000.0, 0.05, seed=7127 + k)
    return finish(out, 0.84, 0.15)


def froufrou(dur: float, dens: float = 1.0) -> np.ndarray:
    """Des feuilles (les fanes) qui froufroutent : un bruissement granuleux."""
    x = _t(dur)
    g = grains(dur, lambda t: 900 * dens * np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 0.7, 1500, 7000)
    s = bp(noise(dur), 2000, 8000) * (0.4 + 0.6 * amb.smooth_env(len(x), 20.0, 0, 1)) * np.sin(np.pi * np.clip(x / dur, 0, 1))
    return g + s * 0.3


def navet_attrape(k: int) -> np.ndarray:
    parts = []
    pop = lp(clip_rec(PLOP + ["Airy 1.wav", "Airy 3.wav"][k], 0.0, 0.4, 0.1), 7000)
    earth = lp(clip_rec(KI + "footstep_grass_00%d.ogg" % (1 + k), -3.0, 0.3, 0.1), 3000)
    parts += [(earth, 0.0, 0.5), (pop, 0.03, 1.0), (unit(froufrou(0.5, 1.2)), 0.05, 0.45),
              (lp(clip_rec(KR + "cloth%d.ogg" % (1 + k), 2.0, 0.4, 0.1), 7000), 0.08, 0.35)]
    if k == 0:
        parts.append((unit(petit(0.18, [700.0, 560.0], "eu", souffle=0.35, att=0.01, rel=0.06)), 0.32, 0.4))
    else:
        parts.append((unit(petit(0.12, [950.0, 820.0], "ou", souffle=0.3, att=0.01, rel=0.05)), 0.3, 0.35))
        parts.append((unit(tinte(2600.0, 0.15, 0.6)), 0.12, 0.12))
    out = mix(0.9, *parts)
    out = room(out, 0.3, 12.0, 8000.0, 0.05, seed=7130 + k)
    return finish(out, 0.86, 0.15)


# =================================================================== les mimiques

def mimique_morsure(k: int) -> np.ndarray:
    parts = []
    bites = [0.12] if k == 0 else [0.1, 0.42]
    parts.append((lp(slow(clip_rec(KR + "creak%d.ogg" % (1 + k), -3.0, 0.6, 0.2), 1.2), 3000), 0.0, 0.35))
    for i, t in enumerate(bites):
        parts += [(clip_rec(KI + "impactWood_heavy_00%d.ogg" % (i + 2 * k), -3.0), t, 1.0),
                  (unit(thump(110.0, 60.0, 0.05, 0.25)), t, 0.6),
                  (unit(clack(1700.0, 0.012, 0.9, 0.3)), t + 0.002, 0.5), (unit(clack(2300.0, 0.01, 0.9, 0.2)), t + 0.008, 0.35),
                  (clip_rec(KI + "impactMetal_light_00%d.ogg" % (i + 1), -2.0), t + 0.01, 0.3),
                  (lp(clip_rec(CRE + "eat_0%d.ogg" % (3 + i), -5.0, 0.4, 0.15), 3000), t + 0.03, 0.35)]
    tg = bites[-1] + 0.15
    parts.append((unit(s70.gronde(0.6, 85.0, 1.1)), tg, 0.4))
    dur = tg + 0.9
    out = mix(dur, *parts)
    out = room(out, 0.7, 6.0, 4500.0, 0.12, seed=7132 + k)
    return finish(out, 0.9, 0.25)


def mimique_reveil(k: int) -> np.ndarray:
    parts = []
    d = [1.3, 1.0][k]
    groan = s59.wood_groan(d, [22.0, 30.0][k])
    groan = bp(groan, 150, 2500)
    parts += [(unit(groan), 0.0, 0.7), (lp(slow(clip_rec(KR + "creak3.ogg", -2.0), 1.4), 2500), 0.1, 0.4),
              (unit(s70.gronde(d + 0.3, [70.0, 80.0][k], 1.2, rise=True)), 0.25, 0.6)]
    # il claque des dents en tremblant : le couvercle qui cogne vite
    t = d + 0.2
    for i in range([7, 9][k]):
        parts.append((unit(addp(clack(RNG.uniform(500, 650), 0.02, 0.5, 0.6), thump(160.0, 100.0, 0.015, 0.06) * 0.5)), t + i * 0.07, RNG.uniform(0.5, 0.9)))
    parts.append((unit(clack(1900.0, 0.01, 1.0, 0.2)), t + 0.05, 0.25))
    if k == 1:
        parts.append((unit(lp(gelee(6, -6.0, 0.5)[::-1], 2500)), t + 0.7, 0.3))
    dur = t + [7, 9][k] * 0.07 + 0.8
    out = mix(dur, *parts)
    out = room(out, 0.8, 5.0, 4000.0, 0.14, seed=7134 + k)
    return finish(out, 0.9, 0.3)


# =================================================================== la Guilde

def alerte_cloche(k: int) -> np.ndarray:
    f = [1180.0, 960.0][k]
    rate = [7.5, 6.0][k]
    ring = 2.7
    out = np.zeros(int((ring + 1.6) * SR))
    t = 0.02
    i = 0
    while t < ring:
        g = (1.0 if i % 2 == 0 else 0.72) * RNG.uniform(0.85, 1.0)
        b = s56.bronze_bell(f * RNG.uniform(0.998, 1.002), 1.4, 1.35)
        amb.place(out, b * g, int(t * SR), 1.0)
        amb.place(out, unit(clack(f * 2.6, 0.006, 1.0, 0.1)) * 0.25 * g, int(t * SR), 1.0)
        t += 1.0 / rate * RNG.uniform(0.9, 1.1)
        i += 1
    x = np.arange(len(out)) / SR
    out *= 0.85 + 0.15 * np.sin(2 * np.pi * rate / 2 * x)          # la cloche qui se balance
    out = lp(out, 9000)
    out = room(out, 0.8, 6.0, 6000.0, 0.08, seed=7140 + k)
    out = s68.soft_limit(out, 0.6 * np.max(np.abs(out)))
    return finish(out, 0.9, 0.9)


def guilde_tampon(k: int) -> np.ndarray:
    parts = []
    # le tapotis sur l'encreur
    for i, t in enumerate((0.0, 0.11)):
        parts.append((lp(clip_rec(KI + "impactSoft_medium_00%d.ogg" % (2 + i), 3.0, 0.2, 0.05), 3500), t, 0.35))
    stamps = [0.42] if k < 2 else [0.38, 0.6]
    for j, t in enumerate(stamps):
        body = addp(unit(thump(140.0, 85.0, 0.035, 0.18)), unit(hann_burst(0.035, 250, 1800)) * 0.5)
        desk = clip_rec(KI + "impactWood_medium_00%d.ogg" % ((k + j) % 5), -2.0, 0.4, 0.1)
        parts += [(body, t, 1.0), (desk, t, 0.7), (lp(clip_rec(PEN + "Softcover Tap %d.wav" % (1 + j), -2.0, 0.3, 0.1), 5000), t, 0.4)]
    if k == 1:
        parts.append((lp(clip_rec(PEN + "Page Turn 1.wav", 0.0, 0.5, 0.2), 6000), stamps[-1] + 0.2, 0.25))
    dur = stamps[-1] + 0.6
    out = mix(dur, *parts)
    out = room(out, 0.5, 9.0, 6000.0, 0.08, seed=7143 + k)
    return finish(out, 0.86, 0.15)


def rang_monte(k: int) -> np.ndarray:
    import orchestre_v51 as orch
    m = orch.midi_of
    if k == 0:
        trp = [("G4", 0.0, 0.13), ("C5", 0.15, 0.13), ("E5", 0.3, 0.13), ("G5", 0.45, 0.4), ("E5", 0.9, 0.14), ("G5", 1.05, 1.5)]
        horn = [(["C4", "E4", "G4"], 1.05, 1.5)]
        timp = [(36, 0.45), (36, 1.05)]
        glock = ["C6", "E6", "G6", "C7"]
    else:
        trp = [("A4", 0.0, 0.2), ("A4", 0.22, 0.1), ("A4", 0.34, 0.1), ("D5", 0.46, 0.4), ("F#5", 0.9, 0.2), ("A5", 1.12, 1.45)]
        horn = [(["D4", "F#4", "A4"], 1.12, 1.45)]
        timp = [(38, 0.46), (33, 0.9), (38, 1.12)]
        glock = ["D6", "F#6", "A6", "D7"]
    dur = 3.2
    out = np.zeros(int(dur * SR))
    for p, t, d in trp:
        amb.place(out, vsco_note("trp", m(p), d, 0.75), int(t * SR), 1.0)
        amb.place(out, vsco_note("trp", m(p) - 12, d, 0.55), int(t * SR), 0.35)
    for ch, t, d in horn:
        for p in ch:
            amb.place(out, vsco_note("horn", m(p), d, 0.6), int(t * SR), 0.5)
    for mi, t in timp:
        amb.place(out, vsco_note("timp", mi, 1.2, 0.7), int(t * SR), 0.6)
    amb.place(out, vsco_note("crash", 60, 2.0, 0.6), int(horn[0][1] * SR), 0.35)
    for i, p in enumerate(glock):
        amb.place(out, vsco_note("glock", m(p), 1.0, 0.5), int((horn[0][1] + 0.05 + i * 0.07) * SR), 0.3)
    if np.max(np.abs(out)) < 1e-6:          # sans VSCO : une fanfare de cuivres synthétiques
        for p, t, d in trp:
            f = 440.0 * 2 ** ((m(p) - 69) / 12.0)
            y = syllabe(d, [f], "a", 1.2, h=0.0, souffle=0.05, sat=1.5, att=0.02, rel=0.08, fmax=6000.0)
            amb.place(out, unit(y), int(t * SR), 0.8)
    out = room(out, 1.6, 2.6, 7000.0, 0.15, seed=7146 + k)
    return finish(out, 0.9, 0.6)


def cristal_mesure(k: int) -> np.ndarray:
    d = [2.4, 2.0][k]
    x = _t(d)
    rise = np.interp(x, [0, d * 0.75, d], [1.0, 1.55, 1.75]) if k == 0 else np.interp(x, [0, 0.3 * d, 0.45 * d, 0.6 * d, d], [1.0, 1.3, 1.1, 1.3, 1.9])
    base = 520.0
    hum = np.zeros(len(x))
    for r, a in ((1.0, 1.0), (1.5, 0.4), (2.0, 0.3), (3.0, 0.12)):
        for det in (0.0, 1.5):
            f = base * r * rise + det * (1 + x)
            hum += a * np.sin(2 * np.pi * np.cumsum(f * (1 + 0.004 * np.sin(2 * np.pi * 6 * x) * x / d)) / SR + RNG.uniform(0, 6))
    hum *= np.clip(x / 0.5, 0, 1) ** 1.5 * (0.6 + 0.4 * x / d) * np.clip((d - x) / 0.05, 0, 1)
    parts = [(unit(hum), 0.0, 0.6), (unit(etincelles(d, 18, 3500.0, 8000.0)), 0.3, 0.15)]
    g = s70.clip_bank(VCSL, "Idiophones/Friction Idiophones/Wine Glasses/Sustains/Slow/glass4_D5_Slow_2_Main.wav", 0.0, d, 0.3)
    if len(g) > int(0.2 * SR):
        gx = np.arange(len(g)) / SR
        parts.append((_fade(g * np.clip(gx / 0.8, 0, 1), 0.3, 0.2), 0.0, 0.25))
    # « DING ! »
    ding = [(2093.0, 0.0), (2637.0, 0.0)] if k == 0 else [(1568.0, 0.0), (2093.0, 0.12), (3136.0, 0.24)]
    for f, dt in ding:
        parts.append((unit(s63.bell(f, 2.0, 0.8)), d + dt, 0.8))
    parts.append((unit(etincelles(1.0, 14, 4000.0, 9000.0)), d + 0.02, 0.3))
    dur = d + 2.3
    out = mix(dur, *parts)
    out = room(out, 1.6, 2.6, 9000.0, 0.2, seed=7148 + k)
    return finish(out, 0.86, 0.8)


# =================================================================== la foudre de Violette

def tonnerre(dur: float, peaks: int = 4) -> np.ndarray:
    """Le tonnerre qui roule : un grondement grave à plusieurs bosses, qui s'éloigne."""
    x = _t(dur)
    e = np.zeros(len(x))
    for i in range(peaks):
        c = RNG.uniform(0.05, 0.6) * dur * (i + 1) / peaks
        w = RNG.uniform(0.15, 0.4) * dur / peaks * 2
        e += RNG.uniform(0.5, 1.0) * (1 - i / (peaks + 1)) * np.exp(-((x - c) / w) ** 2)
    e = e / (e.max() + 1e-9) * np.clip(x / 0.05, 0, 1) * np.clip((dur - x) / (0.4 * dur), 0, 1)
    r = lp(amb.noise(len(x), "brown"), 260.0, 3) + bp(nz(len(x)), 150, 900) * 0.15
    return r * e


def eclair(k: int) -> np.ndarray:
    parts = []
    # les traceurs : quelques petits claquements secs avant le coup
    for i in range(4):
        parts.append((unit(hann_burst(0.004, 2000, 12000)), i * RNG.uniform(0.012, 0.025), RNG.uniform(0.2, 0.5)))
    t0 = 0.08
    m = int(0.004 * SR)
    buf = np.zeros(int(0.8 * SR))
    buf[:m] = nz(m) * np.hanning(m)
    snap = unit(hp(disperse(buf, -0.75, 500), 300))
    crack = hp(nz(int(0.25 * SR)), 200) * env_ad(int(0.25 * SR), 0.0005, 0.04)
    parts += [(unit(crack), t0, 0.7), (snap, t0, 0.4), (unit(thump(70.0, 32.0, 0.25, 1.2)), t0, 1.0),
              (unit(tonnerre([3.2, 3.8][k], [4, 5][k])), t0 + 0.05, 1.3),
              (unit(crepite(1.2, lambda xx: 900 * np.exp(-xx / 0.25), 2500, 9000)), t0, 0.35),
              (lp(clip_rec(SX + "explosion.ogg", -5.0, 1.5, 0.6), 2500), t0, 0.35 if k == 1 else 0.2)]
    if k == 1:
        parts.append((unit(hann_burst(0.15, 1500, 9000)), t0 + 0.01, 0.4))
    dur = t0 + [3.6, 4.2][k]
    out = mix(dur, *parts)
    out = room(out, 2.4, 1.8, 5000.0, 0.2, seed=7151 + k)
    out = s68.soft_limit(out, 0.35 * np.max(np.abs(out)))
    return finish(out, 0.92, 0.8)


def bzz(dur: float, f: float = 110.0, sputter: float = 0.5) -> np.ndarray:
    """Un grésillement électrique : un bourdonnement carré rugueux, coupé par saccades."""
    x = _t(dur)
    sq = np.sign(np.sin(2 * np.pi * np.cumsum(f * (1 + 0.05 * amb.smooth_env(len(x), 40.0, -1, 1))) / SR))
    y = bp(sq + nz(len(x)) * 0.6, 200, 6000)
    gate = (amb.smooth_env(len(x), 35.0, 0.0, 1.0) > sputter * 0.6).astype(float)
    gate = lp(gate, 400.0)
    return y * gate * np.clip(x / 0.004, 0, 1) * np.clip((dur - x) / 0.02, 0, 1)


def eclair_rate(k: int) -> np.ndarray:
    parts = []
    if k == 0:
        parts += [(unit(bzz(0.18, 120.0, 0.2)), 0.0, 0.8), (unit(bzz(0.1, 135.0, 0.3)), 0.3, 0.6), (unit(bzz(0.22, 95.0, 0.6)), 0.5, 0.5)]
        t = 0.75
    elif k == 1:
        parts += [(unit(bzz(0.45, 100.0, 0.5)), 0.0, 0.8), (unit(hann_burst(0.02, 2000, 9000)), 0.1, 0.4)]
        t = 0.5
    else:
        parts += [(unit(bzz(0.25, 115.0, 0.3)), 0.0, 0.8), (unit(bzz(0.12, 105.0, 0.5)), 0.35, 0.5)]
        t = 0.55
    parts += [(unit(crepite(1.2, lambda xx: 400 * np.exp(-xx / 0.35), 2500, 9000)), 0.05, 0.4),
              (unit(sifflement(1.0, 3000, 9000, 0.02, 0.6, 0.5)), t - 0.1, 0.12),
              (unit(bouffee(0.5, 200.0, 2000.0, 0.01)), t, 0.6)]
    if k == 2:
        # « piou » tout triste
        parts.append((unit(chirp([1200.0, 900.0, 380.0], 0.55, (1.0, 0.25))), t + 0.25, 0.4))
    dur = t + 1.0
    out = mix(dur, *parts)
    out = room(out, 0.5, 8.0, 7000.0, 0.08, seed=7154 + k)
    return finish(out, 0.86, 0.3)


# =================================================================== Pétronille

def soin(k: int) -> np.ndarray:
    notes = [[1046.5, 1318.5, 1568.0, 2093.0], [1174.7, 1480.0, 1760.0, 2349.3, 2960.0]][k]
    parts = []
    for i, f in enumerate(notes):
        parts.append((unit(s63.bell(f, 1.6, 0.6)), 0.05 + i * 0.11, 0.6 - 0.04 * i))
    x = _t(2.0)
    pad = sum(np.sin(2 * np.pi * f * 0.5 * x + RNG.uniform(0, 6)) * (1 + 0.003 * np.sin(2 * np.pi * 5 * x)) for f in notes[:3])
    pad *= np.clip(x / 0.4, 0, 1) * np.exp(-np.clip(x - 0.5, 0, 9) / 0.6)
    parts += [(unit(pad), 0.0, 0.25), (unit(etincelles(1.6, 24, 3500.0, 9000.0)), 0.1, 0.3),
              (unit(sifflement(1.5, 4000, 10000, 0.3, 0.8, 0.2)), 0.0, 0.04)]
    out = mix(2.6, *parts)
    out = room(out, 1.8, 2.2, 9000.0, 0.25, seed=7157 + k)
    return finish(out, 0.84, 0.6)


def benediction(k: int) -> np.ndarray:
    import compose_musique_v70 as cm70
    ch = cm70.Choeur("benediction", femmes=True, voyelle="a" if k == 0 else "o", n=6, attack=0.7, release=1.0, seed=7160 + k)
    chord = [[65, 69, 72, 77], [67, 71, 74, 79, 83]][k]
    d = 1.9
    out = np.zeros(int((d + 2.2) * SR))
    for i, mi in enumerate(chord):
        y = np.asarray(ch.note(mi, d, 0.55), float).mean(axis=1)
        amb.place(out, y, int(i * 0.06 * SR), 1.0)
    out = unit(out)
    bell = unit(s63.bell([1396.9, 1568.0][k] * 2, 1.8, 0.6))
    amb.place(out, bell * 0.3, int(0.9 * SR), 1.0)
    amb.place(out, unit(etincelles(1.4, 16, 4000.0, 9000.0)) * 0.2, int(0.8 * SR), 1.0)
    out = room(out, 2.2, 1.8, 7000.0, 0.3, seed=7162 + k)
    return finish(out, 0.86, 0.8)


# =================================================================== Sire Tancrède

def cliquetis(dur: float, n: int = 10, lo: float = 1800.0, hi: float = 4200.0) -> np.ndarray:
    """Les plaques d'une armure qui cliquettent."""
    out = np.zeros(int((dur + 0.2) * SR))
    for _ in range(n):
        f = RNG.uniform(lo, hi)
        c = modal([(f, 1.0, 0.03), (f * 1.73, 0.6, 0.02), (f * 2.9, 0.3, 0.012)], 0.12)
        amb.place(out, c, int(RNG.uniform(0, dur) * SR), RNG.uniform(0.3, 1.0))
    return out


def pas_armure(k: int) -> np.ndarray:
    parts = [(clip_rec(KI + "footstep_concrete_00%d.ogg" % (k + 1), -3.0, 0.4), 0.0, 0.9),
             (unit(thump(110.0, 70.0, 0.03, 0.15)), 0.0, 0.4),
             (clip_rec(KI + "impactPlate_light_00%d.ogg" % k, -5.0, 0.4, 0.15), 0.01, 0.35),
             (unit(cliquetis(0.12, 6)), 0.005, 0.3)]
    out = mix(0.7, *parts)
    out = room(out, 0.4, 10.0, 6000.0, 0.06, seed=7165 + k)
    return finish(out, 0.86, 0.12)


def charge_chevalier(k: int) -> np.ndarray:
    parts = []
    parts += [(clip_rec(KI + "impactPlate_medium_00%d.ogg" % k, -2.0), 0.0, 0.6), (unit(cliquetis(0.3, 12)), 0.0, 0.4)]
    if k == 1:
        parts.append((slow(clip_rec(KR + "drawKnife1.ogg", -2.0), 1.3), 0.05, 0.5))
    t = 0.25
    for i in range(5):
        parts.append((pas_armure(i % 3) * 0.7, t + i * 0.27, 0.9))
    d = [1.1, 1.0][k]
    f = [145.0, 175.0][k]
    sh = syllabe(d, [f * 0.95, f * 1.22, f * 1.3, f * 1.18], "a", 1.0, h=0.12, souffle=0.4, rasp=0.04, sat=1.8, sub=0.1,
                 voy2="a", att=0.05, rel=0.3, vib=0.015, tilt=0.85)
    parts.append((unit(sh), 0.3, 1.0))
    dur = 0.3 + d + 0.5
    out = mix(dur, *parts)
    out = room(out, 0.9, 5.0, 5000.0, 0.12, seed=7168 + k)
    return finish(out, 0.9, 0.3)


def casque_tournoie(dur: float = 1.6, f: float = 760.0) -> np.ndarray:
    """Le casque qui tournoie sur les dalles avant de s'arrêter : « wang-wang-wa-wa-wawawrrr »
    (comme une pièce qui finit de tourner)."""
    x = _t(dur)
    ring = modal([(f, 1.0, 1.2), (f * 2.32, 0.5, 0.8), (f * 4.1, 0.25, 0.4), (f * 0.61, 0.3, 1.0)], dur)
    rate = np.interp(x, [0, dur], [6.0, 26.0])
    ph = np.cumsum(rate) / SR
    am = np.abs(np.sin(np.pi * ph)) ** 2
    rattle = np.zeros(len(x))
    taps = np.nonzero(np.diff(np.floor(ph)) > 0)[0]
    for i in taps:
        amb.place(rattle, unit(clack(RNG.uniform(1500, 2200), 0.006, 0.8, 0.2)), int(i), 0.4)
    e = np.clip((dur - x) / 0.15, 0, 1) * (0.5 + 0.5 * np.clip(1 - x / dur, 0, 1))
    return (ring * (0.3 + 0.7 * am) + rattle * 0.5) * e


def chute_armure(k: int) -> np.ndarray:
    parts = []
    oh = syllabe(0.3, [170.0, 230.0, 200.0], "o", 1.0, h=0.06, souffle=0.3, sat=1.3, att=0.02, rel=0.08)
    parts += [(unit(oh), 0.0, 0.8), (slow(clip_rec(KR + "cloth%d.ogg" % (3 + k), -3.0), 1.2), 0.15, 0.4)]
    t = 0.45
    hits = [("impactPlate_heavy_00%d.ogg" % (1 + k), 0.0, 1.0), ("impactMetal_heavy_00%d.ogg" % (2 + k), 0.05, 0.7),
            ("impactPlate_medium_00%d.ogg" % (3 - k), 0.17, 0.6), ("impactPlate_light_00%d.ogg" % (2 + k), 0.3, 0.45),
            ("impactMetal_medium_00%d.ogg" % (1 + k), 0.38, 0.35)]
    for f, dt, g in hits:
        parts.append((clip_rec(KI + f, -3.0), t + dt, g))
    parts += [(unit(thump(70.0, 40.0, 0.12, 0.5)), t, 0.9), (unit(cliquetis(0.6, 30, 1500.0, 4500.0)), t, 0.5),
              (lp(clip_rec(BBR + "Metal Rattling %d.wav" % (1 + k), -2.0, 0.9, 0.3), 7000), t + 0.05, 0.35)]
    # le casque qui roule et tournoie
    tc = t + 0.55
    parts.append((unit(casque_tournoie([1.6, 1.9][k], [760.0, 640.0][k])), tc, 0.5))
    # « ouille… »
    ou = syllabe(0.4, [150.0, 120.0], "ou", 1.0, h=0.05, souffle=0.4, sat=1.0, voy2="i", rel=0.15)
    parts.append((unit(lp(ou, 3000)), tc + [1.7, 2.0][k], 0.2))
    dur = tc + [2.3, 2.6][k]
    out = mix(dur, *parts)
    out = room(out, 1.2, 4.0, 5000.0, 0.15, seed=7171 + k)
    return finish(out, 0.9, 0.3)


# =================================================================== le donjon : pièges, cristal, porte

def rocher_roule(k: int) -> np.ndarray:
    L = 3.0
    fade = 0.6
    dur = L + fade
    x = _t(dur)
    rot = 1.9
    parts = []
    grind = lp(s63.stone_grind(dur, 38.0), 900)
    rum = lp(amb.noise(len(x), "brown"), 120, 3)
    rolling = rec("30-cc0-sfx-loops/rolling.ogg", -6.0)
    if len(rolling) > SR:
        rl = lp(slow(rolling, 1.6), 1400)
        rl = np.tile(rl, int(np.ceil(len(x) / len(rl))) + 1)[: len(x)]
        parts.append((unit(rl), 0.0, 0.5))
    ph = rot * x
    bump = np.zeros(len(x))
    for i in range(int(dur * rot) + 1):
        tt = (i + RNG.uniform(-0.05, 0.05)) / rot
        amb.place(bump, unit(thump(55.0, 35.0, 0.09, 0.4)), int(max(0.0, tt) * SR), RNG.uniform(0.6, 1.0))
        amb.place(bump, lp(clip_rec(RPG + "stones_0%d.ogg" % (1 + i % 4), -7.0, 0.4, 0.15), 1800), int(max(0.0, tt + 0.01) * SR), 0.3)
    gr = grains(dur, lambda t: 300 + 0 * t, 1000, 5000)
    parts += [(rmsn(grind, 0.25), 0.0, 1.0), (rmsn(rum, 0.3) * (0.8 + 0.2 * np.sin(2 * np.pi * rot * x)), 0.0, 1.0),
              (unit(bump), 0.0, 0.8), (rmsn(gr, 0.04), 0.0, 1.0)]
    out = mix(dur, *parts)
    out = room(out, 0.8, 4.0, 3000.0, 0.15, seed=7175 + k)
    out = s68.hp_loop(amb.loopify(out, fade), 35.0)       # filtrée en boucle : pas de raccord
    return out / (np.max(np.abs(out)) + 1e-9) * 0.88


def piege_dalle(k: int) -> np.ndarray:
    parts = [(lp(clip_rec(RPG + "item_stone_0%d.ogg" % (2 + k), -4.0, 0.4, 0.1), 5000), 0.0, 0.9),
             (unit(clack([620.0, 540.0][k], 0.03, 0.6, 0.6)), 0.0, 0.6), (unit(thump(120.0, 70.0, 0.04, 0.2)), 0.02, 0.5)]
    t = 0.25
    parts += [(s63.ratchet([8, 12][k], [14.0, 18.0][k], 0.6), t, 0.4), (clip_rec(RPG + "chain_0%d.ogg" % (1 + k), -3.0), t + 0.1, 0.4),
              (lp(clip_rec(MECA + "Ratchet Muted %d.wav" % (1 + k), -4.0, 0.8, 0.2), 4000), t, 0.35),
              (unit(lp(s63.stone_grind(0.7, 50.0), 1200) * np.sin(np.pi * _t(0.7) / 0.7)), t, 0.3),
              (clip_rec(KI + "impactMetal_heavy_00%d.ogg" % (3 + k), -6.0), t + 0.75, 0.5), (unit(thump(80.0, 45.0, 0.06, 0.3)), t + 0.75, 0.5)]
    dur = t + 1.4
    out = mix(dur, *parts)
    out = room(out, 1.4, 3.0, 4000.0, 0.2, seed=7177 + k)
    return finish(out, 0.88, 0.4)


def fleche_piege(k: int) -> np.ndarray:
    parts = []
    tw = modal([(320.0, 1.0, 0.12), (870.0, 0.4, 0.06)], 0.4) * (1 + 0.3 * np.sin(2 * np.pi * 30 * _t(0.4)))
    parts += [(unit(clack(2200.0, 0.008, 1.0, 0.2)), 0.0, 0.6), (unit(tw), 0.0, 0.3)]
    w = s63.whoosh(0.2, 1800.0, 5000.0, 0.6)
    whis = chirp([3200.0, 2600.0], 0.2, (1.0,))
    parts += [(unit(w), 0.02, 0.9), (unit(whis), 0.02, 0.12)]
    t = 0.24
    if k < 2:
        parts += [(clip_rec(KI + "impactWood_light_00%d.ogg" % (1 + k), -2.0), t, 0.9), (unit(clack(900.0, 0.03, 0.5, 0.5)), t, 0.4),
                  (unit(modal([(260.0 + 40 * k, 1.0, 0.15), (690.0, 0.3, 0.08)], 0.5) * (1 + 0.6 * np.sin(2 * np.pi * 24 * _t(0.5)))), t + 0.005, 0.3)]
    else:
        parts += [(lp(clip_rec(RPG + "item_stone_01.ogg", 2.0, 0.3, 0.1), 7000), t, 0.7), (unit(tinte(3100.0, 0.08, 0.9)), t, 0.4),
                  (unit(s63.whoosh(0.15, 2500.0, 1200.0, 0.5)), t + 0.02, 0.3), (unit(clack(1900.0, 0.01, 0.8, 0.2)), t + 0.35, 0.3)]
    dur = t + 0.7
    out = mix(dur, *parts)
    out = room(out, 0.9, 5.0, 6000.0, 0.12, seed=7180 + k)
    return finish(out, 0.88, 0.2)


def levier(k: int) -> np.ndarray:
    parts = [(lp(slow(clip_rec(KR + "creak%d.ogg" % (1 + k), -2.0, 0.6, 0.2), 1.3), 3000), 0.0, 0.4),
             (s63.ratchet(3, 7.0, 0.5), 0.1, 0.5)]
    t = 0.55
    parts += [(clip_rec(KI + "impactMetal_heavy_00%d.ogg" % k, -5.0), t, 0.8), (unit(thump(90.0, 50.0, 0.06, 0.3)), t, 0.7),
              (clip_rec(KI + "impactWood_heavy_00%d.ogg" % (k + 1), -3.0), t, 0.4)]
    x = _t(1.2)
    far = lp(s63.stone_grind(1.2, 40.0), 600) * np.sin(np.pi * x / 1.2) ** 0.7
    parts += [(unit(far), t + 0.3, 0.25), (lp(clip_rec(RPG + "chain_03.ogg", -4.0), 2000), t + 0.4, 0.2)]
    dur = t + 1.8
    out = mix(dur, *parts)
    out = room(out, 1.6, 2.6, 3500.0, 0.2, seed=7183 + k)
    return finish(out, 0.88, 0.4)


def cristal_retour(k: int) -> np.ndarray:
    d = [1.6, 1.3][k]
    parts = []
    scale = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24] if k == 0 else [0, 4, 7, 11, 12, 16, 19, 23, 24]
    base = [784.0, 880.0][k]
    for i, s in enumerate(scale):
        f = base * 2 ** (s / 12.0)
        parts.append((unit(s63.bell(f, 1.0, 0.5)), i * d / len(scale), 0.35 + 0.03 * i))
    x = _t(d)
    sw = sweep(nz(len(x)), np.interp(x, [0, d], [600.0, 6000.0]), q=1.5) * np.clip(x / d, 0, 1) ** 1.5
    parts += [(unit(sw), 0.0, 0.35), (unit(etincelles(d, 30, 3000.0, 9000.0)), 0.0, 0.3)]
    x2 = _t(0.7)
    fw = lp(noise(0.7), 600) * env_ad(len(x2), 0.01, 0.15)
    fw2 = sweep(noise(0.7), np.interp(x2, [0, 0.7], [3000.0, 300.0]), q=1.0) * env_ad(len(x2), 0.005, 0.2)
    parts += [(unit(fw), d, 0.7), (unit(fw2), d, 0.4), (unit(thump(90.0, 50.0, 0.08, 0.4)), d, 0.4),
              (unit(s63.bell(base * 2, 1.5, 0.4)), d, 0.3)]
    dur = d + 1.4
    out = mix(dur, *parts)
    out = room(out, 1.8, 2.2, 8000.0, 0.25, seed=7186 + k)
    return finish(out, 0.86, 0.6)


def porte_donjon(k: int) -> np.ndarray:
    mv = [2.4, 1.8][k]
    parts = [(lp(clip_rec(KR + "metalLatch.ogg", -4.0), 4000), 0.0, 0.8), (unit(thump(120.0, 70.0, 0.03, 0.15)), 0.0, 0.3)]
    t0 = 0.35
    res = (240.0, 560.0, 1050.0, 1800.0) if k == 0 else (280.0, 640.0, 1200.0, 2000.0)
    parts.append((rmsn(s70.gond(mv * 0.65, 45.0, 85.0, res), 0.2), t0, 1.0))
    parts.append((rmsn(s59.wood_groan(mv, [18.0, 24.0][k]), 0.2), t0, 1.0))
    parts.append((lp(slow(clip_rec(KR + "doorOpen_%d.ogg" % (1 + k), -2.0), 1.6), 2500), t0, 0.6))
    te = t0 + mv
    parts += [(slow(clip_rec(KI + "impactWood_heavy_00%d.ogg" % (3 + k), -2.0), 1.4), te, 1.0), (unit(thump(60.0, 35.0, 0.15, 0.6)), te, 0.8),
              (lp(clip_rec(SX + "slam_0%d.ogg" % (2 + k), -4.0, 1.0, 0.3), 3000), te, 0.4)]
    dur = te + 1.6
    out = mix(dur, *parts)
    out = room(out, 2.4, 1.6, 3500.0, 0.25, seed=7189 + k)
    return finish(out, 0.9, 0.6)


def moulin(k: int) -> np.ndarray:
    dur = [4.0, 4.5][k]
    x = _t(dur)
    period = [1.35, 1.6][k]
    parts = []
    # l'arbre de bois qui grince à chaque tour (deux grincements par tour)
    t = 0.05
    while t < dur - 0.6:
        g = s59.wood_groan(RNG.uniform(0.5, 0.8), RNG.uniform(16.0, 26.0))
        parts.append((unit(bp(g, 150, 2200)), t, RNG.uniform(0.5, 0.8)))
        t += period / 2 * RNG.uniform(0.9, 1.1)
    # les ailes qui passent (quatre ailes par tour)
    t = 0.1
    while t < dur - 0.5:
        parts.append((unit(s63.whoosh(0.55, 250.0, 700.0, 0.6)), t, 0.6))
        t += period / 4
    for i in range(int(dur / period * 3)):
        parts.append((unit(clack(RNG.uniform(260, 380), 0.04, 0.4, 0.7)), 0.2 + i * period / 3, 0.25))
    wind = s59.wind(len(x), 200, 1600, 0.3, 0.4, 0.8).mean(axis=1)
    parts.append((rmsn(wind, 0.03), 0.0, 1.0))
    out = mix(dur, *parts)
    out = room(out, 0.9, 5.0, 4000.0, 0.12, seed=7192 + k)
    return finish(out, 0.88, 0.5)


def pieces_cascade(dur: float, dens, lo: float = 2800.0, hi: float = 6500.0) -> np.ndarray:
    """Des pièces qui tombent les unes sur les autres : de petits tintements serrés, et le cliquetis."""
    out = np.zeros(int((dur + 0.6) * SR))
    t = 0.0
    while t < dur:
        r = dens(t)
        f = RNG.uniform(lo, hi)
        amb.place(out, tinte(f, RNG.uniform(0.01, 0.05), 0.8), int(t * SR), RNG.uniform(0.15, 0.6))
        if RNG.random() < 0.3:
            amb.place(out, clack(RNG.uniform(1800, 3000), 0.004, 0.9, 0.1), int(t * SR), 0.3)
        t += 1.0 / max(r, 1.0) * RNG.uniform(0.3, 1.7)
    return out


def coffre_pieces(k: int) -> np.ndarray:
    d = [1.5, 1.1][k]
    parts = [(unit(pieces_cascade(d, lambda t: 140 * np.sin(np.pi * min(1.0, t / d)) ** 0.6 + 20)), 0.0, 0.8),
             (lp(clip_rec(KR + ["handleCoins.ogg", "handleCoins2.ogg"][k], 0.0), 9000), 0.05, 0.6),
             (lp(clip_rec(RPG + "item_coins_0%d.ogg" % (1 + k)), 9000), 0.0, 0.5),
             (lp(clip_rec(RPG + "item_coins_0%d.ogg" % (3 + k)), 9000), d * 0.5, 0.4)]
    # les dernières qui roulent et se couchent
    for i, dt in enumerate((0.15, 0.32, 0.55)):
        y = tinte(RNG.uniform(3000, 4500), 0.3, 0.8)[: int(0.4 * SR)]
        xx = np.arange(len(y)) / SR
        y *= 0.5 + 0.5 * np.sin(2 * np.pi * np.interp(xx, [0, xx[-1]], [10.0, 30.0]) * xx) ** 2
        parts.append((unit(_fade(y, 0.0, 0.05)), d + dt, 0.25 * 0.8 ** i))
    out = mix(d + 1.1, *parts)
    out = room(out, 0.5, 9.0, 9000.0, 0.06, seed=7195 + k)
    return finish(out, 0.86, 0.2)


def lit_dodo(k: int) -> np.ndarray:
    parts = []
    # on se laisse tomber : le matelas, le bois du lit qui grince, un ressort
    parts += [(clip_rec(KI + "impactSoft_heavy_00%d.ogg" % (1 + k), -2.0), 0.0, 0.8), (unit(thump(90.0, 55.0, 0.06, 0.3)), 0.0, 0.5),
              (unit(bp(s59.wood_groan(0.6, 28.0), 200, 2500)), 0.05, 0.5), (lp(clip_rec(SX + "spring_0%d.ogg" % (2 + k), -4.0, 0.5, 0.2), 4000), 0.04, 0.25),
              (unit(s68.rope_creak(0.35)), 0.25, 0.25)]
    t = 0.85
    # un ronflement comique : « rrrooonk… fiuuuu »
    parts += [(unit(s70.ronfle(1.1, [30.0, 24.0][k], [0.85, 0.75][k])), t, 0.8),
              (unit(s70.expire(1.0, "siffle", [1400.0, 1150.0][k])), t + 1.15, 0.45)]
    if k == 1:
        for tt in (t + 2.25, t + 2.45):
            parts.append((unit(clack(RNG.uniform(900, 1300), 0.01, 0.4, 0.6)), tt, 0.2))
        parts.append((unit(s70.ronfle(0.7, 34.0, 0.9)), t + 2.6, 0.5))
        dur = t + 3.5
    else:
        parts.append((unit(s70.expire(0.4, "pff")), t + 2.15, 0.35))
        dur = t + 2.8
    out = mix(dur, *parts)
    out = room(out, 0.5, 9.0, 5000.0, 0.06, seed=7198 + k)
    return finish(out, 0.86, 0.3)


def luth(k: int) -> np.ndarray:
    import orchestre_v51 as orch
    m = orch.midi_of
    if k == 0:   # ré majeur : une montée, puis l'accord
        ns = [(m("D4"), 0.11, 0.7), (m("E4"), 0.11, 0.6), (m("F#4"), 0.11, 0.65), (m("A4"), 0.11, 0.65), (m("B4"), 0.11, 0.6),
              (m("C#5"), 0.11, 0.6), (m("D5"), 0.3, 0.75), ([m("D3"), m("A3"), m("D4"), m("F#4"), m("A4")], 1.0, 0.75)]
    elif k == 1:  # sol majeur : une cascade qui descend
        ns = [(m("D5"), 0.1, 0.7), (m("B4"), 0.1, 0.6), (m("G4"), 0.1, 0.6), (m("D4"), 0.1, 0.6), (m("E4"), 0.1, 0.6),
              (m("F#4"), 0.1, 0.6), (m("G4"), 0.25, 0.7), ([m("G2"), m("D3"), m("G3"), m("B3"), m("D4")], 1.0, 0.75)]
    else:         # la mineur puis mi, et la majeur : la petite cadence du barde
        ns = [(m("A4"), 0.09, 0.65), (m("B4"), 0.09, 0.55), (m("A4"), 0.09, 0.6), (m("G#4"), 0.09, 0.55), (m("A4"), 0.18, 0.65),
              ([m("E3"), m("B3"), m("E4"), m("G#4")], 0.45, 0.6), ([m("A2"), m("E3"), m("A3"), m("C#4"), m("E4")], 1.0, 0.75)]
    out = luth_phrase(ns)
    out = room(out, 1.0, 4.0, 7000.0, 0.15, seed=7201 + k)
    return finish(out, 0.86, 0.5)


# =================================================================== les nappes : briques

def sabots(dur: float, rate: float = 2.4) -> np.ndarray:
    """Un cheval au pas sur les pavés : « clip-clop, clip-clop »."""
    out = np.zeros(int((dur + 0.3) * SR))
    t = 0.0
    while t < dur:
        for dt in (0.0, 0.11):
            c = addp(unit(clack(RNG.uniform(700, 1000), 0.02, 0.6, 0.5)), unit(thump(160.0, 110.0, 0.02, 0.08)) * 0.4)
            amb.place(out, c, int((t + dt) * SR), RNG.uniform(0.5, 0.9))
        t += 1.0 / rate * RNG.uniform(0.95, 1.05)
    return lp(out, 3500)


def attelage(dur: float = 7.0) -> np.ndarray:
    """Une charrette et son cheval qui traversent la place."""
    c = s70.charrette(dur)
    h = sabots(dur - 0.2)
    x = np.arange(len(h)) / SR
    h = h * 1.0 / (1.0 + ((x - dur / 2 + 0.3) / (dur / 4)) ** 2)
    out = c.copy()
    place_st(out, pan_move(h, -0.85, 0.85), 0.0, 0.7)
    return out


def oiseaux(m: int, lo: float = 1500.0) -> np.ndarray:
    """Des oiseaux de jardin et de forêt (l'enregistrement « nature-forest-day », en morceaux pris au
    hasard, sans répétition qu'on reconnaîtrait), stéréo."""
    src = dlrec("nature-forest-day.wav")[: 90 * SR]
    if len(src) < 10 * SR:
        out = np.zeros((m, 2))
        scatter(out, [unit(amb.jungle_bird(kk)) for kk in (0, 1, 3)], 20, (0.1, 0.2))
        return out
    src = hp(src, lo)
    l = texture(src, m, 4.0, 1.0, (-0.5, 0.5))
    r = texture(src, m, 4.0, 1.0, (-0.5, 0.5))
    return amb.stereo(l, r)


def brise(m: int) -> np.ndarray:
    src = dlrec("wind-breeze.wav")[2 * SR: 30 * SR]
    if len(src) < 5 * SR:
        return s59.wind(m, 150, 2200, 0.35, 0.3, 1.0)
    return amb.stereo(texture(src, m, 5.0, 1.5, (-1.0, 1.0)), texture(src, m, 5.0, 1.5, (-1.0, 1.0)))


def ruisseau(m: int, lp_hz: float = 3000.0) -> np.ndarray:
    src = dlrec("water-stream.wav")[: 70 * SR]
    if len(src) < 5 * SR:
        return amb.stereo(bp(amb.noise(m, "pink"), 300, 3000), bp(amb.noise(m, "pink"), 300, 3000)) * 0.2
    src = lp(src, lp_hz)
    return amb.stereo(texture(src, m, 5.0, 1.2, (-0.5, 0.5)), texture(src, m, 5.0, 1.2, (-0.5, 0.5)))


def fontaine(m: int) -> np.ndarray:
    """La fontaine de la Grand-Place : l'eau qui retombe dans le bassin."""
    w = ruisseau(m, 5000.0)
    sp = bp(amb.noise(m, "pink"), 800, 6000) * 0.15 * amb.smooth_env(m, 2.0, 0.7, 1.0)
    return w + amb.stereo(sp, np.roll(sp, SR // 3))


def chien() -> np.ndarray:
    """Un chien au loin : deux ou trois aboiements."""
    out = np.zeros(int(2.0 * SR))
    for i in range(RNG.integers(2, 4)):
        c = clip_rec(CRE + "barking_0%d.ogg" % RNG.integers(1, 3), RNG.uniform(-2.0, 2.0), 0.5)
        amb.place(out, c, int(i * RNG.uniform(0.35, 0.5) * SR), RNG.uniform(0.6, 1.0))
    return lp(out, 2200)


def meuh() -> np.ndarray:
    """Une vache au loin : « mmmeuuuh » grave et long."""
    d = RNG.uniform(1.2, 1.8)
    f0 = RNG.uniform(105.0, 135.0)
    y = syllabe(d, [f0 * 0.9, f0 * 1.15, f0 * 1.1, f0 * 0.85], "ou", 0.72, h=0.0, souffle=0.35, rasp=0.04, sat=1.2, sub=0.2,
                voy2="eu", att=0.15, rel=0.5, tilt=0.95)
    return lp(unit(y), 1800)


def alouette(dur: float) -> np.ndarray:
    """Une alouette, très haut : un chant continu de petites notes rapides et variées."""
    out = np.zeros(int((dur + 0.3) * SR))
    t = 0.0
    while t < dur:
        d = RNG.uniform(0.03, 0.09)
        f0 = RNG.uniform(2600, 4800)
        f1 = f0 * RNG.uniform(0.75, 1.3)
        y = chirp([f0, f1], d, (1.0, 0.15))
        if RNG.random() < 0.25:            # un petit trille
            y = y * (0.6 + 0.4 * np.sin(2 * np.pi * 120 * _t(d))[: len(y)])
        amb.place(out, y, int(t * SR), RNG.uniform(0.4, 1.0))
        t += d + RNG.uniform(0.005, 0.04)
        if RNG.random() < 0.03:
            t += RNG.uniform(0.2, 0.5)
    x = np.arange(len(out)) / SR
    return lp(out, 7000) * np.clip(x / 0.5, 0, 1) * np.clip((dur - x) / 0.8, 0, 1)


def abeille(dur: float = 3.0) -> np.ndarray:
    """Une abeille qui passe : un bourdonnement qui approche et s'éloigne (effet Doppler léger)."""
    x = _t(dur)
    f = 220.0 * np.interp(x, [0, dur / 2, dur], [1.04, 1.0, 0.96]) * (1 + 0.02 * amb.smooth_env(len(x), 6.0, -1, 1))
    ph = 2 * np.pi * np.cumsum(f) / SR
    y = sum(np.sin(k * ph) / k ** 0.7 for k in range(1, 12))
    y = bp(y, 200, 4000) * 1.0 / (1.0 + ((x - dur / 2) / (dur / 6)) ** 2)
    return pan_move(y, -0.7, 0.7)


def pic_vert() -> np.ndarray:
    """Un pic qui tambourine sur un tronc : une rafale de coups secs qui accélère un peu."""
    n = RNG.integers(10, 20)
    out = np.zeros(int(1.5 * SR))
    f = RNG.uniform(700, 1100)
    t = 0.0
    for i in range(n):
        amb.place(out, clack(f, 0.012, 0.5, 0.6), int(t * SR), 0.6 + 0.4 * np.sin(np.pi * i / n))
        t += 1.0 / RNG.uniform(14.0, 18.0)
    return lp(out, 4000)


def brindille() -> np.ndarray:
    return lp(addp(unit(clack(RNG.uniform(1500, 2500), 0.006, 1.0, 0.3)), unit(hann_burst(0.03, 1500, 6000)) * 0.5), 6000)


def babil_gobelins() -> np.ndarray:
    """Au loin, des gobelins qui se chamaillent : des syllabes nasillardes, un petit rire."""
    out = np.zeros(int(3.0 * SR))
    t = 0.0
    for i in range(RNG.integers(4, 8)):
        f = RNG.uniform(280, 420)
        y = gob(RNG.uniform(0.1, 0.25), [f, f * RNG.uniform(0.85, 1.2)], RNG.choice(["a", "è", "o", "i"]), rasp=0.08, sat=1.5,
                rel=0.04)
        amb.place(out, unit(y), int(t * SR), RNG.uniform(0.5, 1.0))
        t += RNG.uniform(0.12, 0.35)
    if RNG.random() < 0.6:
        for j in range(3):
            y = gob(0.08, [430.0, 400.0], "é", souffle=0.4, sat=1.0, rel=0.03)
            amb.place(out, unit(y), int((t + j * 0.13) * SR), 0.6)
    return lp(out, 2200)


def grillons(m: int) -> np.ndarray:
    seconds = m / SR
    cr = s56.night_crickets(seconds + 2.0)
    if len(cr) < m:
        cr = np.pad(cr, ((0, m - len(cr)), (0, 0)))
    return cr[:m]


def foyer(m: int) -> np.ndarray:
    """Le feu de l'âtre : un souffle grave, de petits craquements."""
    f = amb.lp(amb.noise(m, "brown"), 250) * 0.35 * amb.smooth_env(m, 1.5, 0.6, 1.0)
    for _ in range(int(m / SR * 8)):
        k = int(RNG.uniform(0.002, 0.01) * SR)
        amb.place(f, amb.hp(RNG.standard_normal(k), RNG.uniform(1500, 4000)) * np.exp(-np.arange(k) / (k / 3)),
                  int(RNG.integers(0, m - k)), RNG.uniform(0.1, 0.6) ** 2)
    return f


def trinque() -> np.ndarray:
    clinks = [clip_rec(BBR + "Ceramic Bowl %d.wav" % i, 0.0, 0.5, 0.2) for i in (1, 2, 5)]
    clinks += [clip_rec(SX + "glass_0%d.ogg" % i, -2.0, 0.35, 0.15) for i in (1, 2)]
    y = np.zeros(int(0.8 * SR))
    for j in range(RNG.integers(2, 4)):
        amb.place(y, clinks[RNG.integers(0, len(clinks))], int(RNG.uniform(0, 0.12) * SR), RNG.uniform(0.6, 1.0))
    return y


def chope_posee() -> np.ndarray:
    return addp(clip_rec(KI + "impactWood_light_00%d.ogg" % RNG.integers(0, 5), RNG.uniform(-3.0, 0.0), 0.3),
                clip_rec(BBR + "Ceramic Bowl %d.wav" % RNG.choice([3, 4, 6]), -3.0, 0.3, 0.1) * 0.4)


def sonnette() -> np.ndarray:
    """La sonnette du comptoir de la Guilde : « ding ! »."""
    return unit(s63.bell(RNG.choice([1760.0, 1975.5]), 1.4, 1.1))


def air_luth(seconds: float = 9.0, key: int = 0) -> np.ndarray:
    """Bertrand qui joue du luth au fond de la salle : un petit air de danse."""
    import orchestre_v51 as orch
    m = orch.midi_of
    if key == 0:
        tune = "D5 F#5 A5 F#5 G5 E5 F#5 D5 E5 C#5 D5 B4 A4 B4 C#5 D5 E5 F#5 E5 D5 C#5 A4 B4 C#5 D5"
        chords = [[50, 57, 62], [55, 59, 62], [57, 61, 64], [50, 57, 62]]
    else:
        tune = "A4 C5 E5 C5 D5 B4 C5 A4 G4 B4 D5 B4 C5 A4 B4 G#4 A4 C5 E5 A5 G5 E5 F5 D5 E5"
        chords = [[45, 52, 57], [43, 50, 55], [40, 47, 52], [45, 52, 57]]
    notes = tune.split()
    step = 0.22
    out = np.zeros(int((len(notes) * step + 2.0) * SR))
    for i, p in enumerate(notes):
        amb.place(out, luth_note(m(p), step * 1.6, 0.55 if i % 3 else 0.7), int(i * step * SR), 1.0)
    per = len(notes) * step / len(chords)
    for j, ch in enumerate(chords):
        for q, mm in enumerate(ch):
            amb.place(out, luth_note(mm, per, 0.45), int((j * per + q * 0.015) * SR), 0.6)
    return out[: int(seconds * SR) + SR]


# =================================================================== les nappes : la ville

def montjoie_jour_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def bed(m):
        hum = lp(amb.noise(m, "pink"), 450) * 0.22
        crowd = bp(amb.noise(m, "pink"), 250, 1600) * 0.1 * amb.smooth_env(m, 0.3, 0.7, 1.0)
        out = amb.stereo(hum + crowd, np.roll(hum, SR // 2) + np.roll(crowd, SR // 3))
        out += fontaine(m) * 0.12
        out += oiseaux(m, 2000.0) * 0.12
        return out

    cont = loop_layer(bed, seconds, 3.0)
    town = np.zeros((n, 2))
    s68.voice_walla(lib, town, 13.0, 2100.0, (-4.0, 3.0), (0.1, 0.3))
    scatter(town, [s68.laugh_group(RNG.integers(2, 4), (-4.0, 1.5), 2400.0) for _ in range(4)], 5, (0.12, 0.26))
    scatter(town, [s70.cri_marchand() for _ in range(6)], 6, (0.12, 0.24))
    scatter(town, [s70.pas_passant(RNG.integers(5, 10)) for _ in range(4)], 6, (0.1, 0.2))
    town = room_wrap(town, 1.2, 3.0, 2600.0, 0.22, seed=7301)
    far = np.zeros((n, 2))
    for at in (6.0, 23.0, 41.0, 53.0):
        wplace(far, s70.forgeron(), at * SR, 0.12, RNG.uniform(-0.8, -0.4))
    place_st(far, attelage(7.0), 12.0 * SR, 0.32)
    place_st(far, attelage(6.0)[:, ::-1], 44.0 * SR, 0.26)
    wplace(far, s70.cloche_loin(261.6, 3, 2.1), 30.0 * SR, 0.08, 0.5)
    scatter(far, [unit(s56.pigeon(kk)) for kk in range(2)], 3, (0.05, 0.1))
    scatter(far, [chien()], 1, (0.04, 0.07))
    far = room_wrap(far, 2.2, 1.8, 2600.0, 0.35, seed=7302)
    return finish_bed(cont + town + far, 0.7)


def montjoie_nuit_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def bed(m):
        w = s59.wind(m, 100, 1200, 0.15, 0.2, 0.7) * 0.35
        return w + grillons(m) * 0.9

    cont = loop_layer(bed, seconds, 3.0)
    far = np.zeros((n, 2))
    tav = np.zeros((n, 2))
    s68.voice_walla(lib, tav, 3.0, 900.0, (-4.0, 1.0), (0.08, 0.2))
    scatter(tav, [s68.laugh_group(RNG.integers(2, 4), (-4.0, 1.0), 1300.0) for _ in range(3)], 3, (0.12, 0.22), pan_r=(-0.6, -0.2))
    wplace(tav, lp(air_luth(9.0, 1), 1600), 18.0 * SR, 0.07, -0.4)
    wplace(tav, lp(air_luth(9.0, 0), 1600), 46.0 * SR, 0.06, -0.35)
    far += room_wrap(tav, 1.6, 2.4, 1800.0, 0.4, seed=7311)
    ev = np.zeros((n, 2))
    wplace(ev, chien(), 9.0 * SR, 0.06, 0.7)
    wplace(ev, chien(), 37.0 * SR, 0.05, 0.5)
    wplace(ev, s70.chouette(), 25.0 * SR, 0.06, -0.7)
    wplace(ev, s70.chouette(), 54.0 * SR, 0.05, 0.75)
    wplace(ev, s70.cloche_loin(261.6, 1, 2.0), 3.0 * SR, 0.05, 0.3)
    scatter(ev, [s70.pas_passant(RNG.integers(4, 8))], 1, (0.06, 0.1))
    far += room_wrap(ev, 2.4, 1.6, 2400.0, 0.45, seed=7312)
    return finish_bed(cont + far, 0.7)


def guilde_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def hearth(m):
        f = foyer(m)
        mur = amb.bp(amb.noise(m, "pink"), 150, 900) * amb.smooth_env(m, 4.0, 0.5, 1.0) * 0.45
        return amb.stereo(f * 0.6 + mur, np.roll(f, SR // 7) * 0.4 + np.roll(mur, SR // 3))

    cont = loop_layer(hearth, seconds, 2.0) * 0.12
    rm = np.zeros((n, 2))
    s68.voice_walla(lib, rm, 20.0, 2700.0, (-4.0, 3.0), (0.1, 0.42))
    scatter(rm, [s68.laugh_group(RNG.integers(2, 5), (-4.0, 2.0)) for _ in range(6)], 6, (0.2, 0.42))
    scatter(rm, [trinque() for _ in range(8)], 12, (0.25, 0.5), lp_hz=7000.0)
    scatter(rm, [chope_posee() for _ in range(6)], 10, (0.2, 0.4), lp_hz=5000.0)
    scatter(rm, [s68.chair_scrape() for _ in range(5)], 4, (0.15, 0.3))
    scatter(rm, [amb.lp(clip_rec(KR + "creak%d.ogg" % i), 2000) for i in (1, 2, 3)], 4, (0.12, 0.25), semis=(-5.0, -1.0))
    steps = []
    for _ in range(3):
        y = np.zeros(int(3.0 * SR))
        for j in range(RNG.integers(4, 7)):
            amb.place(y, clip_rec(KI + "footstep_wood_00%d.ogg" % RNG.integers(0, 5), -2.0, 0.3), int(j * 0.5 * SR), RNG.uniform(0.6, 1.0))
        steps.append(amb.lp(y, 2500))
    scatter(rm, steps, 3, (0.15, 0.3))
    # le comptoir d'Églantine : la sonnette, le tampon
    wplace(rm, sonnette(), 14.0 * SR, 0.12, 0.6)
    wplace(rm, lp(guilde_tampon(0), 4000), 15.2 * SR, 0.2, 0.6)
    wplace(rm, lp(guilde_tampon(2), 4000), 47.0 * SR, 0.18, 0.55)
    wplace(rm, sonnette(), 39.0 * SR, 0.1, 0.65)
    # au fond, Bertrand et son luth
    far = np.zeros((n, 2))
    wplace(far, air_luth(10.0, 0), 4.0 * SR, 0.1, -0.55)
    wplace(far, air_luth(10.0, 1), 24.0 * SR, 0.09, -0.6)
    wplace(far, air_luth(10.0, 0), 44.0 * SR, 0.09, -0.5)
    rm += room_wrap(far, 1.2, 3.5, 3500.0, 0.3, seed=7321)
    rm = room_wrap(rm, 1.0, 4.5, 3500.0, 0.2, seed=7322)
    return finish_bed(cont + rm, 0.65)


# =================================================================== les nappes : dehors

def lp_loop(x: np.ndarray, fc: float) -> np.ndarray:
    """Passe-bas d'une boucle, amorcé avec la fin de la boucle (pas de raccord) : les aigus du vent
    adoucis, l'encodage Vorbis ne fait plus dépasser les crêtes."""
    from scipy import signal
    k = min(len(x) // 2, SR)
    ext = np.concatenate([x[-k:], x])
    return signal.sosfilt(signal.butter(2, fc, btype="lowpass", fs=SR, output="sos"), ext, axis=0)[k:]


def campagne_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def air(m):
        w = brise(m) * 0.5
        g = amb.smooth_env(m, 0.25, 0.2, 1.0) ** 1.5
        grass = hp(amb.noise(m, "pink"), 2500) * g * 0.05
        return w + amb.stereo(grass, np.roll(grass, SR // 2)) + oiseaux(m, 2500.0) * 0.07

    cont = loop_layer(air, seconds, 3.0)
    ev = np.zeros((n, 2))
    for at, d, p in ((3.0, 9.0, -0.3), (24.0, 8.0, 0.4), (41.0, 10.0, 0.1)):
        wplace(ev, alouette(d), at * SR, 0.1, p)
    for at in (10.0, 36.0, 52.0):
        wplace(ev, meuh(), at * SR, 0.06, RNG.uniform(-0.8, 0.8))
    place_st(ev, abeille(3.0), 19.0 * SR, 0.05)
    place_st(ev, abeille(2.5)[:, ::-1], 48.0 * SR, 0.04)
    far = np.zeros((n, 2))
    for at in (0.0, 12.0, 24.0, 36.0, 48.0):
        wplace(far, lp(moulin(0), 2000), at * SR, 0.045, 0.65)
    ev += room_wrap(far, 2.0, 2.0, 2500.0, 0.35, seed=7331)
    ev = room_wrap(ev, 1.4, 3.0, 5000.0, 0.15, seed=7332)
    return finish_bed(lp_loop(cont + ev, 9000.0), 0.55)


def lac_grenouilles_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def air(m):
        lap = s56.lapping(m) * 0.8
        gust = amb.smooth_env(m, 0.22, 0.15, 1.0) ** 1.5
        reeds = amb.bp(amb.noise(m, "pink"), 250, 2500) * (0.35 + gust) * 0.25
        rustle = amb.hp(amb.noise(m, "white"), 3000) * gust ** 2 * 0.04
        cr = s59.cricket_dry(m) * 0.01
        return lap + amb.stereo(reeds + rustle + cr, np.roll(reeds, SR // 2) + np.roll(rustle, SR // 3) + np.roll(cr, SR // 5))

    cont = loop_layer(air, seconds, 3.0) * 0.6
    ev = np.zeros((n, 2))
    scatter(ev, [unit(s59.frog(kk)) for kk in range(6)], 60, (0.1, 0.3))
    scatter(ev, [s68.bullfrog() for _ in range(4)], 14, (0.12, 0.26))
    scatter(ev, [unit(s68.tree_frog()) for _ in range(5)], 28, (0.05, 0.14))
    plops = [_fade(unit(amb.lp(trim(rec(PLOP + "Airy %d.wav" % i, -6.0))[: int(0.8 * SR)], 3000)), 0.005, 0.2) for i in (1, 2, 4)]
    scatter(ev, plops, 6, (0.1, 0.22))
    far = np.zeros((n, 2))
    giants = [unit(croak(RNG.uniform(45, 58), RNG.uniform(0.6, 0.9), RNG.uniform(22, 27), 1.3, (0.95, 1.1, 1.0, 0.85))) for _ in range(3)]
    for at in (8.0, 29.0, 47.0):
        wplace(far, giants[RNG.integers(0, 3)], at * SR, 0.09, RNG.uniform(-0.6, 0.6))
    wplace(far, lp(clip_rec(SPL + "splash_11.ogg", -4.0, 1.4, 0.4), 2400), 38.0 * SR, 0.15, 0.4)
    scatter(far, [unit(amb.jungle_bird(kk)) for kk in (0, 2)], 2, (0.03, 0.06))
    ev += room_wrap(far, 1.6, 2.4, 2500.0, 0.35, seed=7341)
    ev = room_wrap(ev, 1.2, 3.0, 3500.0, 0.18, seed=7342)
    return finish_bed(cont + ev, 0.7)


def foret_lutins_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def air(m):
        b = oiseaux(m, 300.0) * 0.6
        g = amb.smooth_env(m, 0.2, 0.1, 1.0) ** 1.6
        leaves = bp(amb.noise(m, "pink"), 1500, 7000) * g * 0.06
        low = s59.wind(m, 80, 600, 0.15, 0.3, 0.7) * 0.12
        return b + low + amb.stereo(leaves, np.roll(leaves, SR // 2))

    cont = loop_layer(air, seconds, 3.0)
    ev = np.zeros((n, 2))
    scatter(ev, [pic_vert() for _ in range(3)], 3, (0.06, 0.12))
    scatter(ev, [brindille() for _ in range(4)], 5, (0.05, 0.12))
    far = np.zeros((n, 2))
    for at in (14.0, 43.0):
        wplace(far, babil_gobelins(), at * SR, 0.035, RNG.uniform(-0.7, 0.7))
    ev += room_wrap(far, 1.8, 2.2, 2200.0, 0.45, seed=7351)
    ev = room_wrap(ev, 1.4, 2.8, 4000.0, 0.15, seed=7352)
    return finish_bed(cont + ev, 0.7)


# =================================================================== les nappes : le donjon

def donjon_caves_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def air(m):
        g = amb.smooth_env(m, 0.1, 0.2, 1.0) ** 1.5
        wind = bp(amb.noise(m, "pink"), 50, 380) * (0.35 + g) * 0.7
        w1 = s59.whistle(m, 310.0) * 0.025
        tt = np.arange(m) / SR
        drone = (np.sin(2 * np.pi * 41.2 * tt) * 0.08 + np.sin(2 * np.pi * 61.7 * tt) * 0.04) * (0.7 + 0.3 * np.sin(2 * np.pi * tt / 11))
        return amb.stereo(wind + w1 + drone, np.roll(wind, SR // 2) + drone)

    cont = loop_layer(air, seconds, 3.0)
    ev = np.zeros((n, 2))
    scatter(ev, [amb.drip(kk) for kk in range(4)], 22, (0.05, 0.12))
    scatter(ev, [s59.drip() for _ in range(4)], 12, (0.04, 0.09))
    far = np.zeros((n, 2))
    squ = [s69.echoes(np.concatenate([gelee(i * 3, RNG.uniform(-6.0, -2.0), 0.4, 2000.0), np.zeros(SR)]), [(0.3, 0.4), (0.7, 0.2)], 1500.0) for i in range(5)]
    scatter(far, squ, 5, (0.08, 0.16))
    boing = [s69.echoes(np.concatenate([unit(jelly(150.0, 300.0, 200.0, 0.35, 16.0)) * 0.6, np.zeros(SR)]), [(0.35, 0.4), (0.8, 0.2)], 1500.0)]
    scatter(far, boing, 2, (0.04, 0.07))
    knocks = []
    for _ in range(3):
        y = addp(unit(clack(RNG.uniform(280, 520), 0.05, 0.4, 0.8)), unit(thump(90.0, 60.0, 0.05, 0.3)) * 0.5)
        knocks.append(s69.echoes(np.concatenate([y, np.zeros(SR)]), [(0.35, 0.4), (0.8, 0.22), (1.4, 0.1)], 1200.0))
    scatter(far, knocks, 3, (0.08, 0.15))
    scatter(far, [lp(slow(clip_rec(BFH + "bfh1_rock_falling_0%d.ogg" % i), 1.4), 2000) for i in (1, 4, 7)], 2, (0.05, 0.09))
    scatter(far, [unit(blorp(RNG.uniform(70, 110), RNG.uniform(200, 320), RNG.uniform(0.1, 0.2), 0.6)) for _ in range(4)], 6, (0.04, 0.08))
    ev += room_wrap(far, 3.0, 1.2, 2200.0, 0.55, seed=7361)
    ev = room_wrap(ev, 2.4, 1.5, 3000.0, 0.4, seed=7362)
    return finish_bed(cont + ev, 0.6)


def donjon_lac_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def water(m):
        lap = s56.lapping(m) * 0.9
        lap[:, 0] = lp(lap[:, 0], 1600)
        lap[:, 1] = lp(lap[:, 1], 1600)
        tr = ruisseau(m, 2500.0) * 0.08
        tt = np.arange(m) / SR
        drone = np.sin(2 * np.pi * 36.7 * tt) * 0.06 * (0.7 + 0.3 * np.sin(2 * np.pi * tt / 13))
        air = bp(amb.noise(m, "pink"), 60, 400) * 0.25 * amb.smooth_env(m, 0.1, 0.5, 1.0)
        return lap + tr + amb.stereo(drone + air, drone + np.roll(air, SR // 2))

    cont = loop_layer(water, seconds, 3.0)
    ev = np.zeros((n, 2))
    scatter(ev, [amb.drip(kk) for kk in range(4)], 26, (0.05, 0.14))
    scatter(ev, [s59.drip() for _ in range(4)], 16, (0.04, 0.1))
    far = np.zeros((n, 2))
    scatter(far, [lp(clip_rec(SPL + "splash_0%d.ogg" % i, -5.0, 0.8, 0.3), 2200) for i in (2, 5, 8)], 2, (0.08, 0.14))
    wplace(far, lp(croak(48.0, 0.7, 23.0, 1.3), 1500), 33.0 * SR, 0.12, -0.5)
    ev += room_wrap(far, 3.5, 1.0, 2500.0, 0.6, seed=7371)
    ev = room_wrap(ev, 3.2, 1.1, 3500.0, 0.5, seed=7372)
    return finish_bed(cont + ev, 0.6)


# =================================================================== lancement

# nom : (fonction, nombre de variantes, numéro de la première) — aucun de ces noms n'existait avant la V71
SOUNDS = {
    "slime_saut": (slime_saut, 3, 1), "slime_mort": (slime_mort, 3, 1), "slime_roi_cri": (slime_roi_cri, 2, 1),
    "slime_divise": (slime_divise, 2, 1), "grenouille_coasse": (grenouille_coasse, 3, 1),
    "grenouille_langue": (grenouille_langue, 2, 1), "grenouille_avale": (grenouille_avale, 2, 1),
    "grenouille_recrache": (grenouille_recrache, 2, 1), "gobelin_cri": (gobelin_cri, 3, 1), "gobelin_mort": (gobelin_mort, 2, 1),
    "gobelin_chef_cri": (gobelin_chef_cri, 2, 1), "navet_cri": (navet_cri, 3, 1), "navet_attrape": (navet_attrape, 2, 1),
    "mimique_morsure": (mimique_morsure, 2, 1), "mimique_reveil": (mimique_reveil, 2, 1), "alerte_cloche": (alerte_cloche, 2, 1),
    "guilde_tampon": (guilde_tampon, 3, 1), "rang_monte": (rang_monte, 2, 1), "cristal_mesure": (cristal_mesure, 2, 1),
    "eclair": (eclair, 2, 1), "eclair_rate": (eclair_rate, 3, 1), "soin": (soin, 2, 1), "benediction": (benediction, 2, 1),
    "charge_chevalier": (charge_chevalier, 2, 1), "chute_armure": (chute_armure, 2, 1), "pas_armure": (pas_armure, 3, 1),
    "rocher_roule": (rocher_roule, 1, 1), "piege_dalle": (piege_dalle, 2, 1), "fleche_piege": (fleche_piege, 3, 1),
    "levier": (levier, 2, 1), "cristal_retour": (cristal_retour, 2, 1), "porte_donjon": (porte_donjon, 2, 1),
    "moulin": (moulin, 2, 1), "coffre_pieces": (coffre_pieces, 2, 1), "lit_dodo": (lit_dodo, 2, 1), "luth": (luth, 3, 1),
}
BEDS = {"montjoie_jour": montjoie_jour_bed, "montjoie_nuit": montjoie_nuit_bed, "guilde": guilde_bed, "campagne": campagne_bed,
        "lac_grenouilles": lac_grenouilles_bed, "foret_lutins": foret_lutins_bed, "donjon_caves": donjon_caves_bed,
        "donjon_lac": donjon_lac_bed}


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
    for name, (fn, count, first) in SOUNDS.items():
        if names and name not in names:
            continue
        xs = []
        for k in range(count):
            reseed(name, k)
            xs.append(fn(k))
        old = [s70.loudness(s70.read_raw(fx.OUT / f"{name}_{j}.ogg")) for j in range(1, first) if (fx.OUT / f"{name}_{j}.ogg").is_file()]
        ref = min(old) if old else min(s70.loudness(x) for x in xs)
        for k, x in enumerate(xs):
            y = x * 10 ** ((ref - s70.loudness(x)) / 20.0)
            if np.max(np.abs(y)) > 0.89:
                y = s68.soft_limit(y, 0.89)
            fx.save(f"{name}_{first + k}", y)
            pk = np.max(np.abs(s70.read_raw(fx.OUT / f"{name}_{first + k}.ogg")))
            if pk > 0.93:
                fx.save(f"{name}_{first + k}", y * 0.89 / pk)
        print(" ", name, ", ".join(f"{name}_{first + k}" for k in range(count)))
    for name, fn in BEDS.items():
        if names and name not in names:
            continue
        reseed(name)
        amb.save(f"ambiance/{name}", fn(s63.LIB))
    return 0


if __name__ == "__main__":
    sys.exit(main())
