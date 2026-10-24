"""V70 : les sons de l'Île de Braise et de Pandémonia, la méga-cité des démons gentils (une ville
gothique sur une île volcanique, des démons serviables et drôles), de son grand donjon « Les Neuf
Cercles » (Charon, Cerbère, les Furies, Géryon, le Cocyte gelé et le Titan de Givre), de l'Arène des
Cornes et de la Nuit des Lanternes.

Bruitages (sfx/) :
  lave_bulles_1..3      la lave qui bulle : une grosse bulle épaisse qui enfle (une note grave qui
                        monte) et qui crève, les éclaboussures qui retombent, le gaz qui siffle ;
  lave_gerbe_1..2       une gerbe de lave : le « vloum » sourd, la lave épaisse qui jaillit et
                        retombe en paquets, le grésillement, la croûte qui crépite ;
  feu_souffle_1..2      un grand souffle de flammes : l'embrasement, le grondement du feu (le
                        filtre qui s'ouvre puis se referme), la turbulence, les crépitements ;
  demon_rire_1..3       un démon qui rit de bon cœur : « Ho ho ho ho ! » grave et chaleureux (1),
                        « Ha ha ha ha ! » (2), un petit rire malicieux « hé hé hé… ho ho ! » (3) ;
  diablotin_cri_1..3    un diablotin effronté : « Nyè-hè-hè ! » (1), une grimace « pfrrrt » et un
                        gloussement (2), « Yaaah ! hihi » (3) ;
  diablotin_mort_1..2   le diablotin vaincu : « Ouille ! » (ou un « aaah » qui tombe), puis « pouf »,
                        il disparaît dans un petit nuage, quelques étincelles ;
  chien_enfer_aboi_1..3 un chien d'enfer : de gros aboiements rauques, chacun suivi d'une bouffée de
                        flammes et de braises ;
  chien_enfer_grogne_1..2 un grondement de gorge très grave, les crocs, le feu qui siffle ;
  chien_enfer_mort_1..2 un jappement, une plainte qui descend, il tombe, son feu s'éteint en
                        sifflant ;
  gargouille_cri_1..2   une gargouille : un cri perçant dans une gorge de pierre (grincements,
                        grenaille), un battement d'ailes de pierre ;
  gargouille_mort_3     une gargouille qui se brise : la pierre qui craque, un dernier cri, les
                        morceaux qui roulent, la poussière (les variantes 1 et 2, plus anciennes,
                        restent : la famille passe à trois) ;
  ailes_pierre_1..2     des ailes de pierre qui battent : le souffle, le crissement du gravier ;
  ombre_murmure_1..3    une ombre des Limbes qui chuchote, doux et aérien, pas effrayant ;
  furie_cri_1..2        une Furie : un cri de rapace aigu et furieux, ses grandes ailes ;
  cerbere_aboi_1..2     les trois têtes de Cerbère qui aboient ensemble (une grosse, une moyenne,
                        une petite), dans la caverne ;
  cerbere_ronfle_1..2   les trois têtes qui ronflent chacune à sa façon (le gros ronflement, le
                        sifflement, le petit « pfff » et les babines qui claquent) ;
  charon_rame_1..3      la rame de Charon dans l'eau noire de l'Achéron : la pale qui plonge,
                        le remous, les gouttes, le tolet qui grince ;
  obole_1..2            une pièce qui tombe dans la paume (le petit tintement étouffé) ; une
                        pièce lancée qui tinte en tournoyant, puis rattrapée ;
  glace_craque_1..3     la glace qui se fend : le claquement, puis le « piou » de la fissure (les
                        aigus filent d'abord, comme dans un ressort), la plaque qui gronde ;
  souffle_givre_1..2    un souffle glacé : l'haleine, les cristaux de givre qui tintent et crissent ;
  titan_rugit_1..2      le Titan de Givre : un rugissement énorme, la glace qui craque et tombe ;
  titan_pas_1..3        un pas du Titan sur la glace : le choc sourd, le crissement, la fissure ;
  chaines_1..3          des chaînes secouées (1), traînées (2), lâchées en tas (3) ;
  grande_porte_1..2     une immense grille de fer qui s'ouvre : le loquet, le treuil, les gonds qui
                        gémissent, le poids qui roule, le grand « clang » de la fin ;
  cloche_cathedrale_1..2  le bourdon de la Cathédrale-Forge (ré, puis la), une longue queue ;
  arene_foule_1..3      la foule de l'Arène : « Ouais ! » et applaudissements (1), « Ohhh ! » puis
                        acclamations (2), « Ho ! Ho ! Ho ! » scandé en tapant des pieds (3) ;
  arene_gong_1..2       le grand gong de l'Arène ;
  artifice_depart_1..3  une fusée qui part : la mèche, le « pfoum », le sifflet qui monte et
                        s'éloigne (1), une fusée à traîne d'étincelles (2), deux fusées (3) ;
  artifice_eclat_1..3   un éclat de feu d'artifice : le « boum » et son écho sur la ville, puis les
                        crépitements des paillettes (1), une gerbe de petits pétards (2), une
                        pluie d'étoiles qui sifflent en tombant (3) ;
  lanterne_allume_1..2  une lanterne de braise qui s'allume : le « vloum » de la flamme, un petit
                        carillon, deux étincelles ;
  forge_marteau_1..3    le marteau sur l'enclume (un coup qui sonne, un coup et deux rebonds, un
                        coup mat sur le fer chaud) ;
  geryon_ailes_1..2     les immenses ailes de cuir de Géryon ;
  contrat_signe_1..2    un contrat signé : la plume qui gratte le parchemin, le cachet de cire
                        pressé, un scintillement magique ;
  bain_soufre_1..2      une source chaude de soufre qui bouillonne, la vapeur qui siffle ;
  automate_pas_1..3     un pas d'automate de bronze : le choc du métal, le servomoteur, le déclic ;
  automate_mort_2..3    l'automate qui s'arrête et s'affaisse (la variante 1, de la V63, reste) ;
  gorgoth_cri_1..3      Gorgoth le Cornu, colosse débonnaire : « Hooo-aaah ! » (après deux coups
                        de poing sur la poitrine) (1), « Ha-ha-haaa ! » (2), « Hmmf… HAAA ! » (3) ;
  spectre_givre_cri_1..2  un spectre de givre : une plainte voilée, comme du verre, pas effrayante ;
  cocyte_vent_coup_1..3 une rafale de vent glacé : le souffle, le hurlement dans les crevasses, les
                        cristaux de glace qu'elle emporte.
Nappes d'ambiance (ambiance/, boucles sans raccord, stéréo) :
  pandemonia_jour       la cité, le jour : la rumeur de la foule, les rires, les marchands qui
                        crient, une forge au loin, une charrette sur les pavés, les braseros qui
                        crépitent, des pas, des ailes qui passent, de temps en temps les cloches ;
  pandemonia_nuit       la cité, la nuit : les braseros tout près, au loin un violon et un accordéon
                        qui jouent la valse de Pandémonia, quelques voix, un rire, la chouette, le
                        bourdon de la cathédrale de temps en temps ;
  champ_lave            le champ de lave : un grondement profond, les bulles, les évents qui
                        sifflent, la croûte qui craque, des gerbes, le volcan au loin ;
  port_braise           le Port de Cendre : les vagues contre les quais de basalte, les coques et
                        les amarres qui grincent, une voile qui claque, des voix au loin, un calfat,
                        la cloche d'un navire, un étrange oiseau de mer (le goéland de braise) ;
  neuf_cercles          sous terre : un vent profond, des gouttes, des échos lointains et doux (un
                        choc de pierre, une chaîne, un soupir du vent dans les galeries) ;
  cocyte                le lac gelé : le vent glacé qui hurle, la glace qui craque et gémit, des
                        cristaux qui tintent ;
  arene                 l'Arène des Cornes : la rumeur d'une foule immense, des vivats, des chants
                        scandés en tapant des pieds et des mains, des sifflets, le cor des hérauts ;
  thermes_soufre        les Thermes de Soufre : les sources qui bouillonnent, la vapeur qui siffle,
                        l'eau qui clapote, des gouttes sous la voûte, un baigneur, un « aaah » ravi.
Synthétisés ici (domaine public), ou retravaillés (découpés, transposés, ralentis, filtrés,
réverbérés) d'après : le recueil CC0 « lavenderdotpet/CC0-Public-Domain-Sounds » (« 80 CC0 creature
SFX » 1 et 2, beast_or_animal, « 80 CC0 RPG SFX », packs Kenney Impact, RPG et Voiceover, « 100 CC0
wood/metal SFX », « 100 CC0 SFX » 2, « 75 CC0 breaking/falling/hit », « 40 CC0 water splash/slime »,
« 30 CC0 SFX loops », « BB Retail Therapy Sample Pack », « bb - Bottle Plops », « bb - Books, Paper,
Writing » (Ben Burnes), les rires de « Free Retro Arcade Sounds » (The Motion Monkey)) ; la banque
VSCO-2 CE (Versilian Studios, CC0 : grosse caisse étouffée, gong, enclume, violon solo, cor) ; la
« Versilian Community Sample Library » (VCSL, Versilian Studios, CC0 : enclumes, gong, cloches
tubulaires, carillons à main, verres frottés, claquements de mains) : tout est libre de droits.
Chaque son a ses propres graines (tirées de son nom) : on peut n'en refaire qu'un, il sort à
l'identique.
Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/generate_sons_v70.py [dossier CC0-Public-Domain-Sounds] [noms...]
(les banques VSCO-2-CE et VCSL sont cherchées à côté du recueil ; sans elles, les sons qui en
viennent sont faits seulement de synthèse)
"""
from pathlib import Path
import subprocess
import sys
import tempfile
import zlib

import numpy as np
from scipy import signal
from scipy.io import wavfile

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_sons_v69 as s69  # noqa: E402
import generate_sons_v68 as s68  # noqa: E402
import generate_sons_v63 as s63  # noqa: E402
import generate_sons_v59 as s59  # noqa: E402
import generate_sons_v56 as s56  # noqa: E402
import generate_sons_v49 as amb  # noqa: E402
import generate_bruitages_v50 as fx  # noqa: E402

SR = 44100
RNG = np.random.default_rng(7070)
VSCO = s63.LIB.parent / "VSCO-2-CE"
VCSL = s63.LIB.parent / "VCSL"

_t, _norm, _env, _fade, mix, noise, rec, slow = (s63._t, s63._norm, s63._env, s63._fade, s63.mix, s63.noise,
                                                 s63.rec, s63.slow)
trim, cut, unit, addp, clip_rec = s68.trim, s68.cut, s68.unit, s68.addp, s68.clip_rec
clack, thump, formants, wplace, room_wrap = s68.clack, s68.thump, s68.formants, s68.wplace, s68.room_wrap
scatter, loop_layer, finish_bed, squawk, shout = s68.scatter, s68.loop_layer, s68.finish_bed, s68.squawk, s68.shout
modal, glottal = s68.modal, s68.glottal
whisper, grains, wing_beat, flutter, vowel_track = s69.whisper, s69.grains, s69.wing_beat, s69.flutter, s69.vowel_track

KI = "kenney_impactsounds/Audio/"
KR = "kenney_rpgaudio/Audio/"
WM = "100-CC0-wood-metal-SFX/"
SPL = "40-cc0-water-splash-slime-sfx/"
BBR = "BB_Retail Therapy Sample Pack/"
CRE = "80-CC0-creature-SFX/"
CRE2 = "80-CC0-creature-sfx-2/"
RPG = "80-CC0-RPG-SFX/"
BFH = "75-cc0-breaking-falling-hit-sfx/"
BEAST = "beast_or_animal/"
ARC = "MMRetroArcadeSoundsPack1_0_5/Vocal/wav/"
PLOP = "bb - Bottle Plops (Apr 2021)/Plop - "
PEN = "bb - Books, Paper, Writing (Jan 2021)/"
ST = "Idiophones/Struck Idiophones/"


# =================================================================== outils

def reseed(name: str, k: int = 0) -> None:
    """Chaque son a ses propres graines (tirées de son nom) : refaire un seul son le redonne à l'identique."""
    global RNG
    base = [7070, zlib.crc32(name.encode()), k]
    RNG = np.random.default_rng(base + [0])
    s69.RNG = np.random.default_rng(base + [1])
    s68.RNG = np.random.default_rng(base + [2])
    s63.RNG = np.random.default_rng(base + [3])
    s59.RNG = np.random.default_rng(base + [4])
    s56.RNG = np.random.default_rng(base + [5])
    amb.RNG = np.random.default_rng(base + [6])


def lp(x: np.ndarray, fc: float, order: int = 2) -> np.ndarray:
    return amb.lp(x, min(fc, SR * 0.45), order)


def hp(x: np.ndarray, fc: float, order: int = 2) -> np.ndarray:
    return amb.hp(x, fc, order)


def bp(x: np.ndarray, lo: float, hi: float, order: int = 2) -> np.ndarray:
    return amb.bp(x, lo, min(hi, SR * 0.45), order)


def nz(n: int) -> np.ndarray:
    return RNG.standard_normal(n)


_BANK = {}


def bank(root: Path, rel: str) -> np.ndarray:
    """Un échantillon d'une banque VSCO-2 CE ou VCSL (mono), s'il est là."""
    p = root / rel
    if str(p) not in _BANK:
        _BANK[str(p)] = amb.read_any(p).mean(axis=1) if p.is_file() else np.zeros(0)
    return _BANK[str(p)]


def clip_bank(root: Path, rel: str, semi: float = 0.0, max_s: float = 0.0, fout: float = 0.05) -> np.ndarray:
    x = bank(root, rel)
    if len(x) == 0:
        return np.zeros(int(0.1 * SR))
    x = trim(s56._shift(x, semi))
    if max_s > 0:
        x = x[: int(max_s * SR)]
    return unit(_fade(x, 0.002, min(fout, len(x) / SR / 3)))


def sweep(x: np.ndarray, fc, kind: str = "lowpass", order: int = 2, q: float = 0.0, blk: int = 256) -> np.ndarray:
    """Un filtre dont la fréquence varie dans le temps (recalculé bloc par bloc) : passe-bas, passe-haut,
    ou passe-bande de largeur relative q (fc/q de chaque côté) si q > 0."""
    fc = np.asarray(fc, float)
    if fc.ndim == 0:
        fc = np.full(len(x), float(fc))
    out = np.empty(len(x))
    zi = None
    for i in range(0, len(x), blk):
        f = float(np.clip(fc[min(len(fc) - 1, i + blk // 2)], 25.0, SR * 0.42))
        if q > 0:
            sos = signal.butter(order, [f / (1 + 1 / q), min(f * (1 + 1 / q), SR * 0.45)], btype="bandpass", fs=SR, output="sos")
        else:
            sos = signal.butter(order, f, btype=kind, fs=SR, output="sos")
        if zi is None:
            zi = np.zeros((sos.shape[0], 2))
        out[i:i + blk], zi = signal.sosfilt(sos, x[i:i + blk], zi=zi)
    return out


def disperse(x: np.ndarray, a: float = -0.9, n: int = 200) -> np.ndarray:
    """Une cascade de filtres passe-tout : les aigus arrivent d'abord, les graves après (le « piou »
    de la glace qui se fend, comme le son d'un ressort)."""
    sos = np.tile([a, 1.0, 0.0, 1.0, a, 0.0], (n, 1))
    return signal.sosfilt(sos, x)


def place_st(buf: np.ndarray, st: np.ndarray, at: float, gain: float = 1.0) -> None:
    """Pose un son stéréo dans une boucle (ce qui dépasse la fin repart au début)."""
    n = len(buf)
    i = int(at) % n
    st = st[:n]
    k = n - i
    buf[i:i + min(k, len(st))] += st[:k] * gain
    if len(st) > k:
        buf[: len(st) - k] += st[k:] * gain


def pan_move(x: np.ndarray, p0: float, p1: float) -> np.ndarray:
    """Un son mono qui traverse l'espace : son panoramique glisse de p0 à p1."""
    p = np.linspace(p0, p1, len(x))
    return np.stack([x * np.sqrt(0.5 * (1 - p)), x * np.sqrt(0.5 * (1 + p))], axis=1)


def loudness(x: np.ndarray) -> float:
    return s68.loudness(x)


def read_raw(path: Path) -> np.ndarray:
    """Un .ogg du jeu, tel quel (sans le normaliser), mono."""
    with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(path), "-ac", "1", "-ar", str(SR), tmp.name], check=True)
        _, d = wavfile.read(tmp.name)
    return d.astype(np.float64) / 32768.0


def room(x: np.ndarray, seconds: float, decay: float, lp_hz: float, wet: float, seed: int) -> np.ndarray:
    return s56._room(x, seconds, decay, lp_hz, wet, seed=seed)


def rmsn(x: np.ndarray, r: float) -> np.ndarray:
    """Met un son à un niveau efficace (RMS) donné, plutôt qu'à une crête."""
    return x / (np.sqrt(np.mean(x ** 2)) + 1e-12) * r


def finish(x: np.ndarray, peak: float = 0.89, fout: float = 0.3) -> np.ndarray:
    return _norm(_fade(x, 0.002, fout), peak)


# =================================================================== briques : voix, feu, métal

def syllabe(dur: float, f0, voy: str = "a", scale: float = 1.0, h: float = 0.04, souffle: float = 0.2,
            rasp: float = 0.0, sat: float = 0.0, sub: float = 0.0, tilt: float = 1.0, tp=None, voy2: str | None = None,
            att: float = 0.015, rel: float = 0.06, fmax: float = 5500.0, fm=None, vib: float = 0.0) -> np.ndarray:
    """Une syllabe : l'aspiration du début (« h »), puis la voyelle voisée (la hauteur suit f0, une
    liste de points), qui peut glisser vers une autre voyelle ; raucité, sous-harmonique, saturation."""
    n = int(dur * SR)
    x = np.arange(n) / SR
    fp = np.atleast_1d(np.asarray(f0, float))
    tpp = np.linspace(0, dur, len(fp)) if tp is None else np.asarray(tp, float) * dur
    f = np.interp(x, tpp, fp) if len(fp) > 1 else np.full(n, fp[0])
    if vib > 0:
        f = f * (1 + vib * np.sin(2 * np.pi * RNG.uniform(4.5, 6.0) * x) * np.clip((x - 0.15) / 0.3, 0, 1))
    if rasp > 0:
        fmod = bp(nz(n), 25.0, 220.0)
        f = f * (1 + rasp * fmod / (np.std(fmod) + 1e-9))
    f = np.clip(f, 25.0, None)
    src = glottal(f, tilt=tilt, fmax=fmax, jitter=0.012)
    src = src / (np.std(src) + 1e-9)
    if sub > 0:
        ph = 2 * np.pi * np.cumsum(f) / SR
        src = src + sub * np.sin(0.5 * ph) * (1 + np.sin(ph))
    venv = np.clip((x - h * 0.7) / max(att, 1e-3), 0, 1) * np.clip((dur - x) / max(rel, 1e-3), 0, 1)
    henv = np.clip(x / 0.006, 0, 1) * np.where(x < h, 1.0, np.exp(-(x - h) / 0.02))
    asp = hp(nz(n), 500.0)
    exc = src * venv + asp * (henv * 1.4 + souffle * venv)
    if fm is None:
        fm = vowel_track(n, [(0, voy), (1.0, voy2)], scale) if voy2 else s68._vow(voy, scale)
    y = formants(exc, fm)
    if sat > 0:
        y = np.tanh(sat * y / (np.max(np.abs(y)) + 1e-9))
    return y


def flamme(dur: float, f_lo: float = 250.0, f_hi: float = 2600.0, turb: float = 0.35) -> np.ndarray:
    """Une langue de feu : un grondement de bruit dont le filtre s'ouvre puis se referme, la
    turbulence (le souffle qui tremble), le corps grave."""
    x = _t(dur)
    n = len(x)
    fc = np.interp(x, [0, 0.12 * dur, 0.4 * dur, dur], [f_lo, f_hi, f_hi * 0.8, f_lo * 0.7])
    w = nz(n)
    roar = sweep(w, fc, "lowpass", 2) - sweep(w, fc * 0.12, "lowpass", 1) * 0.6
    tr = bp(nz(n), 3.0, 18.0)
    roar *= 1 + turb * tr / (np.std(tr) + 1e-9)
    body = lp(nz(n), 160) * 0.8
    env = np.clip(x / 0.05, 0, 1) * np.clip((dur - x) / (0.45 * dur), 0, 1) ** 1.2
    return (roar + body) * env


def crepite(dur: float, rate, lo: float = 1500.0, hi: float = 7000.0) -> np.ndarray:
    """Des crépitements : de petits craquements secs (la braise, la croûte de lave, le bois)."""
    n = int(dur * SR)
    x = np.arange(n) / SR
    r = rate(x) if callable(rate) else np.full(n, float(rate))
    imp = (RNG.random(n) < r / SR).astype(float) * RNG.uniform(0.1, 1.0, n) ** 2
    ker = np.exp(-np.arange(int(0.004 * SR)) / (0.0008 * SR))
    y = np.convolve(imp * np.sign(nz(n)), ker)[:n]
    return bp(y, lo, hi)


def sifflement(dur: float, lo: float = 2000.0, hi: float = 8000.0, att: float = 0.05, rel: float = 0.4,
               flick: float = 0.3) -> np.ndarray:
    """Un sifflement de gaz ou de vapeur : du bruit aigu, qui tremble un peu."""
    x = _t(dur)
    y = bp(noise(dur), lo, hi)
    y *= 1 + flick * amb.smooth_env(len(x), 25.0, -1, 1)
    return y * np.clip(x / att, 0, 1) * np.clip((dur - x) / rel, 0, 1)


def bouffee(dur: float = 0.4, lo: float = 150.0, hi: float = 1500.0, att: float = 0.004) -> np.ndarray:
    """Une bouffée : un « pouf » d'air ou de fumée."""
    x = _t(dur)
    return bp(noise(dur), lo, hi) * np.clip(x / att, 0, 1) * np.exp(-x / (dur * 0.3))


def tinte(f: float, dec: float = 0.05, bright: float = 1.0) -> np.ndarray:
    """Un petit tintement de métal ou de cristal : les modes d'un disque mince (inharmoniques)."""
    parts = [(f, 1.0, dec), (f * 1.62, 0.7 * bright, dec * 0.8), (f * 2.24, 0.45 * bright, dec * 0.6),
             (f * 2.95, 0.3 * bright, dec * 0.45), (f * 3.62, 0.15 * bright, dec * 0.35)]
    parts = [(fq, a, d) for fq, a, d in parts if fq < SR * 0.45]
    return modal(parts, dec * 6 + 0.05)


def etincelles(dur: float, count: int, lo: float = 2500.0, hi: float = 7000.0, g=(0.05, 0.2)) -> np.ndarray:
    """Des étincelles ou des cristaux qui tintent, au hasard."""
    out = np.zeros(int((dur + 0.5) * SR))
    for _ in range(count):
        amb.place(out, tinte(RNG.uniform(lo, hi), RNG.uniform(0.01, 0.05), 0.7), int(RNG.uniform(0, dur) * SR), RNG.uniform(*g))
    return out


def blorp(f0: float, f1: float, dur: float, pop: float = 0.8) -> np.ndarray:
    """Une bulle de lave épaisse : la peau qui enfle (une note grave qui monte de plus en plus vite),
    puis qui crève (« plop »)."""
    m = int(dur * SR)
    x = np.arange(m) / SR
    f = f0 * (f1 / f0) ** ((x / dur) ** 1.6)
    y = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.clip(x / (0.4 * dur), 0, 1) ** 1.5 * np.clip((dur - x) / 0.01, 0, 1)
    y += lp(nz(m), 250) * np.clip(x / dur, 0, 1) ** 2 * 0.3
    out = np.zeros(m + int(0.35 * SR))
    out[:m] = y
    if pop > 0:
        k = int(0.07 * SR)
        xs = np.arange(k) / SR
        b = bp(nz(k), 180, 2400) * np.exp(-xs / 0.013) * np.clip(xs / 0.001, 0, 1)
        amb.place(out, b * pop, m - int(0.004 * SR), 1.0)
        amb.place(out, thump(f1 * 1.3, f1 * 0.7, 0.03, 0.15) * 0.5 * pop, m - int(0.003 * SR), 1.0)
    return out


def eclabousse(t0: float, t1: float, count: int, f=(140.0, 320.0), g=(0.1, 0.35)) -> list:
    """De petits paquets (de lave, d'eau) qui retombent : des « ploc » sourds, au hasard."""
    parts = []
    for _ in range(count):
        a = RNG.uniform(*f)
        y = addp(unit(thump(a, a * 0.6, RNG.uniform(0.012, 0.03), 0.1)), unit(bp(nz(int(0.03 * SR)), 300, 2500) * np.hanning(int(0.03 * SR))) * 0.4)
        parts.append((y, RNG.uniform(t0, t1), RNG.uniform(*g)))
    return parts


def pierre_gorge(dur: float, f: float = 70.0) -> np.ndarray:
    """Une gorge de pierre : de la pierre qui grince sur de la pierre, par saccades."""
    x = _t(dur)
    g = s63.stone_grind(dur, f)
    g = bp(g, 200, 2600)
    am = 0.5 + 0.5 * np.sin(2 * np.pi * np.cumsum(RNG.uniform(30, 55) * (1 + 0.3 * amb.smooth_env(len(x), 8.0, -1, 1))) / SR)
    return g * (0.4 + 0.6 * am)


# =================================================================== la lave et le feu

def lave_bulles(k: int) -> np.ndarray:
    if k == 0:
        dur = 2.0
        parts = [(unit(blorp(55.0, 150.0, 0.34)), 0.05, 1.0),
                 (lp(clip_rec(PLOP + "Viscous 1.wav", -8.0, 0.8, 0.2), 1500), 0.33, 0.55)]
        parts += eclabousse(0.42, 0.95, 7)
        parts.append((unit(sifflement(1.3, 2500, 8000, 0.08, 0.7)), 0.38, 0.12))
        parts.append((unit(crepite(1.5, lambda x: 40 * np.exp(-x / 0.6))), 0.4, 0.18))
    elif k == 1:
        dur = 2.2
        parts = []
        for t, (a, b, d) in zip((0.05, 0.47, 0.86), ((70.0, 190.0, 0.2), (60.0, 160.0, 0.26), (85.0, 230.0, 0.16))):
            parts.append((unit(blorp(a, b, d)), t, RNG.uniform(0.75, 1.0)))
        for t, r in ((0.27, "Viscous 2.wav"), (0.74, "Viscous 3.wav")):
            parts.append((lp(clip_rec(PLOP + r, RNG.uniform(-8.0, -5.0), 0.7, 0.2), 1600), t, 0.45))
        boil = lp(slow(clip_rec("30-cc0-sfx-loops/water_boiling.ogg", 0.0, 1.0), 1.8), 1100)
        parts.append((_fade(unit(boil), 0.2, 0.6), 0.0, 0.3))
        parts += eclabousse(0.3, 1.3, 6, g=(0.08, 0.25))
        parts.append((unit(sifflement(1.4, 3000, 9000, 0.1, 0.6)), 0.5, 0.08))
    else:
        dur = 2.4
        parts = [(unit(blorp(45.0, 120.0, 0.52, pop=1.0)), 0.05, 1.0),
                 (lp(clip_rec(PLOP + "Viscous 4.wav", -9.0, 0.9, 0.2), 1300), 0.55, 0.5),
                 (unit(sifflement(1.5, 800, 5000, 0.12, 0.8, 0.5)), 0.6, 0.3),
                 (unit(crepite(1.8, lambda x: 60 * np.exp(-x / 0.8), 1200, 6000)), 0.55, 0.22),
                 (unit(lp(noise(2.2), 90) * np.sin(np.pi * np.clip(_t(2.2) / 2.2, 0, 1))), 0.0, 0.3)]
        parts += eclabousse(0.6, 1.2, 5, f=(110.0, 220.0))
    out = mix(dur, *parts)
    out = room(out, 0.5, 7.0, 4000.0, 0.08, seed=7001 + k)
    return finish(out, 0.89, 0.3)


def lave_gerbe(k: int) -> np.ndarray:
    dur = [2.6, 3.0][k]
    x = _t(0.5)
    whoomph = lp(noise(0.5), 600) * np.clip(x / 0.01, 0, 1) * np.exp(-x / 0.12)
    parts = [(unit(thump(70.0, 34.0, 0.13, 0.6)), 0.0, 0.9), (unit(whoomph), 0.0, 0.7)]
    s1 = lp(slow(clip_rec(SPL + "splash_11.ogg", -2.0, 1.4, 0.4), 1.8), 1700)
    s2 = lp(slow(clip_rec(SPL + "splash_14.ogg", -1.0, 1.2, 0.4), 1.6), 1500)
    parts += [(s1, 0.02, 0.8), (s2, 0.1, 0.5)]
    lava = lp(clip_rec("warfork-cc0/sounds/world/lava_in.ogg", -4.0, 1.3, 0.4), 3500)
    parts.append((lava, 0.05, 0.4))
    if k == 1:
        parts.insert(0, (s63.whoosh(0.45, 300.0, 1400.0, 0.6) * 0.8, 0.0, 1.0))
        parts.append((unit(s63.stone_grind(1.6, 40.0) * np.sin(np.pi * np.clip(_t(1.6) / 1.6, 0, 1))), 0.0, 0.3))
        parts = [(p[0], p[1] + (0.3 if i > 0 else 0.0), p[2]) for i, p in enumerate(parts)]
    t0 = 0.3 if k == 1 else 0.0
    parts += eclabousse(t0 + 0.45, t0 + 1.7, 12)
    parts.append((unit(sifflement(1.8, 2200, 8000, 0.05, 1.0, 0.4)), t0 + 0.15, 0.25))
    parts.append((unit(crepite(2.0, lambda xx: 120 * np.exp(-xx / 0.7))), t0 + 0.2, 0.3))
    out = mix(dur, *parts)
    out = room(out, 0.7, 6.0, 4000.0, 0.1, seed=7004 + k)
    return finish(out, 0.9, 0.4)


def feu_souffle(k: int) -> np.ndarray:
    if k == 0:
        dur = 2.3
        x = _t(0.3)
        ign = lp(noise(0.3), 900) * np.clip(x / 0.008, 0, 1) * np.exp(-x / 0.08)
        parts = [(unit(thump(95.0, 45.0, 0.07, 0.35)), 0.0, 0.7), (unit(ign), 0.0, 0.6),
                 (unit(flamme(1.7, 300.0, 2800.0)), 0.03, 1.0),
                 (clip_rec(RPG + "spell_fire_03.ogg", -3.0, 1.8, 0.4), 0.02, 0.45),
                 (unit(crepite(1.9, lambda xx: 90 * np.exp(-xx / 0.9))), 0.1, 0.35)]
    else:
        dur = 3.0
        fl = flamme(2.5, 280.0, 3200.0, 0.5)
        fl *= 0.75 + 0.25 * np.sin(2 * np.pi * 2.2 * _t(2.5)) ** 2
        parts = [(clip_rec(RPG + "spell_fire_07.ogg", -2.0), 0.0, 0.6), (unit(fl), 0.05, 1.0),
                 (unit(thump(80.0, 40.0, 0.09, 0.4)), 0.0, 0.6),
                 (unit(crepite(2.6, 70)), 0.15, 0.3), (unit(sifflement(2.2, 1800, 6000, 0.2, 0.8)), 0.2, 0.12)]
    out = mix(dur, *parts)
    out = room(out, 0.8, 5.0, 5000.0, 0.12, seed=7006 + k)
    return finish(out, 0.89, 0.4)


# =================================================================== les démons

def demon_rire(k: int) -> np.ndarray:
    parts = []
    if k == 0:
        # « Ho ho ho ho ! » : grave, rond, chaleureux, la série qui descend
        t = 0.03
        for i, f in enumerate([132.0, 127.0, 121.0, 114.0, 106.0]):
            d = 0.17 + 0.012 * i
            y = syllabe(d, [f * 1.07, f, f * 0.9], "o", 0.86, h=0.05, souffle=0.25, rasp=0.03, sub=0.3, sat=1.3,
                        tilt=0.95, rel=0.05)
            parts.append((unit(y), t, 1.0 - 0.07 * i))
            t += d + 0.07
        y = syllabe(0.62, [112.0, 98.0, 86.0], "a", 0.86, h=0.08, souffle=0.45, sub=0.25, sat=1.1, voy2="o", rel=0.3)
        parts.append((unit(y), t + 0.08, 0.6))
        dur = t + 0.9
    elif k == 1:
        # « Ha ha ha ha ! » : un bon rire franc, un peu moins grave
        t = 0.03
        for i in range(6):
            f = 168.0 - 9.0 * i
            d = 0.12 + (0.05 if i == 5 else 0.0)
            y = syllabe(d, [f * 1.08, f * 0.95], "a", 0.92, h=0.035, souffle=0.3, rasp=0.025, sub=0.15, sat=1.2,
                        tilt=0.9, rel=0.04)
            parts.append((unit(y), t, 1.0 - 0.05 * i))
            t += d + 0.065
        lr = lp(clip_rec(ARC + "Laugh3.wav", -4.0, 1.4, 0.3), 3000)
        parts.append((lr, 0.04, 0.16))
        y = syllabe(0.5, [150.0, 120.0], "è", 0.92, h=0.1, souffle=0.6, voy2="a", rel=0.25)
        parts.append((unit(y), t + 0.05, 0.4))
        dur = t + 0.75
    else:
        # « hé hé hé… ho ho ! » : un petit rire malicieux, puis franc
        t = 0.03
        for i in range(3):
            y = syllabe(0.09, [205.0, 190.0], "é", 0.95, h=0.03, souffle=0.35, sat=0.9, rel=0.03)
            parts.append((unit(y), t, 0.7))
            t += 0.16
        t += 0.12
        for i in range(2):
            f = 150.0 - 12.0 * i
            y = syllabe(0.2, [f * 1.06, f * 0.88], "o", 0.88, h=0.05, souffle=0.25, sub=0.25, sat=1.2, rel=0.06)
            parts.append((unit(y), t, 1.0))
            t += 0.29
        dur = t + 0.5
    out = mix(dur, *parts)
    out = lp(out, 4800)
    out = room(out, 0.6, 6.0, 4000.0, 0.12, seed=7008 + k)
    return finish(out, 0.89, 0.25)


def diablotin_cri(k: int) -> np.ndarray:
    parts = []
    if k == 0:
        # « Nyè-hè-hè ! » : effronté
        y = syllabe(0.2, [520.0, 640.0, 590.0], "è", 1.4, h=0.0, souffle=0.15, sat=1.6, rel=0.04)
        nas = lp(syllabe(0.05, [500.0, 520.0], "ou", 1.3, h=0.0, souffle=0.1), 900)
        parts += [(unit(nas), 0.02, 0.5), (unit(y), 0.06, 1.0)]
        t = 0.32
        for f in (610.0, 540.0):
            parts.append((unit(syllabe(0.1, [f * 1.05, f * 0.92], "è", 1.4, h=0.03, souffle=0.3, sat=1.3, rel=0.03)), t, 0.8))
            t += 0.15
        dur = t + 0.35
    elif k == 1:
        # « Pfrrrt ! » (il tire la langue), puis un gloussement
        d = 0.55
        x = _t(d)
        rate = 31.0 * (1 + 0.1 * np.sin(2 * np.pi * 3.0 * x))
        ph = np.cumsum(rate) / SR
        pulse = np.exp(-(ph % 1.0) * 6.0)
        rz = nz(len(x)) * (0.35 + pulse) + pulse * 1.5
        rz = formants(rz, [(400, 200, 1.0), (1300, 400, 0.5), (2600, 600, 0.2)])
        rz *= np.clip(x / 0.03, 0, 1) * np.clip((d - x) / 0.08, 0, 1)
        parts.append((unit(rz), 0.0, 0.9))
        t = 0.66
        for f in (720.0, 760.0, 700.0):
            parts.append((unit(syllabe(0.08, [f, f * 0.94], "i", 1.4, h=0.025, souffle=0.4, sat=1.0, rel=0.025)), t, 0.6))
            t += 0.12
        dur = t + 0.35
    else:
        # « Yaaah ! » puis « hihi »
        y = syllabe(0.42, [480.0, 760.0, 720.0, 560.0], "a", 1.35, h=0.02, souffle=0.2, rasp=0.03, sat=1.8,
                    voy2="è", rel=0.08)
        parts.append((unit(y), 0.02, 1.0))
        t = 0.55
        for f in (740.0, 780.0):
            parts.append((unit(syllabe(0.08, [f, f * 0.93], "i", 1.4, h=0.025, souffle=0.4, sat=1.0, rel=0.025)), t, 0.55))
            t += 0.12
        dur = t + 0.35
    out = mix(dur, *parts)
    out = room(out, 0.4, 9.0, 6000.0, 0.08, seed=7011 + k)
    return finish(out, 0.86, 0.15)


def diablotin_mort(k: int) -> np.ndarray:
    parts = []
    if k == 0:
        y = syllabe(0.34, [760.0, 640.0, 380.0], "ou", 1.4, h=0.0, souffle=0.2, sat=1.4, voy2="i", rel=0.06)
        parts.append((unit(y), 0.02, 1.0))
        t = 0.42
    else:
        y = syllabe(0.6, [680.0, 560.0, 300.0], "a", 1.35, h=0.02, souffle=0.3, sat=1.2, voy2="o", rel=0.2, vib=0.02)
        parts.append((unit(y), 0.02, 1.0))
        t = 0.62
    parts.append((unit(bouffee(0.5, 120.0, 1400.0)), t, 0.8))
    parts.append((unit(bouffee(0.9, 300.0, 3000.0, 0.08)), t + 0.02, 0.25))
    parts.append((unit(etincelles(0.5, 6, 2800.0, 6000.0)), t + 0.05, 0.3))
    if k == 1:
        parts.append((unit(crepite(0.8, 50)), t, 0.2))
    out = mix(t + 1.2, *parts)
    out = room(out, 0.5, 7.0, 6000.0, 0.1, seed=7014 + k)
    return finish(out, 0.86, 0.3)


# =================================================================== les chiens d'enfer et Cerbère

def aboi(f0: float = 160.0, size: float = 1.0, dur: float = 0.24, rasp: float = 0.12) -> np.ndarray:
    """Un aboiement : un coup de voix bref, rauque et saturé, la hauteur qui monte puis tombe, le
    souffle de l'attaque ; size > 1 : un plus gros chien (formants plus graves)."""
    fm = [(620 / size, 170, 1.0), (1250 / size, 240, 0.75), (2450 / size, 320, 0.4), (3500 / size, 450, 0.2)]
    y = syllabe(dur, [f0 * 1.12, f0 * 1.25, f0, f0 * 0.72], fm=fm, tp=[0, 0.12, 0.45, 1.0], h=0.012, souffle=0.45,
                rasp=rasp, sat=2.6, sub=0.4, tilt=0.75, att=0.005, rel=dur * 0.5, fmax=7000.0)
    m = int(0.025 * SR)
    burst = bp(nz(m), 500, 4000) * np.hanning(m)
    return addp(unit(y), unit(burst) * 0.3)


def gronde(dur: float, f0: float = 62.0, size: float = 1.2, rise: bool = False) -> np.ndarray:
    """Un grondement de gorge : une voix très grave, rauque, qui tremble par saccades."""
    shape = [0.9, 1.1, 1.0, 1.35] if rise else [0.9, 1.1, 1.0, 0.92]
    y = syllabe(dur, [f0 * s for s in shape], "eu", 0.8 / size, h=0.08, souffle=0.6, rasp=0.25, sub=0.6,
                sat=2.2, tilt=0.9, voy2="o", att=0.15, rel=0.3)
    x = _t(dur)
    trem = 0.6 + 0.4 * (0.5 + 0.5 * np.sin(2 * np.pi * np.cumsum(np.full(len(x), RNG.uniform(18.0, 24.0))) / SR))
    return y * trem[: len(y)]


def chien_enfer_aboi(k: int) -> np.ndarray:
    parts = []
    times = [[0.02, 0.36], [0.4], [0.02, 0.24, 0.46]][k]
    if k == 1:
        parts.append((unit(gronde(0.42, 70.0, 1.2)), 0.0, 0.5))
    for i, t in enumerate(times):
        f0 = RNG.uniform(140.0, 165.0) if k != 2 else RNG.uniform(165.0, 190.0)
        size = 1.25 if k != 2 else 1.1
        parts.append((aboi(f0, size, RNG.uniform(0.2, 0.26)), t, 1.0 - 0.08 * i))
        smp = lp(clip_rec(CRE + "barking_0%d.ogg" % (1 + i % 2), RNG.uniform(-7.0, -5.0)), 2600)
        parts.append((smp, t, 0.22))
        parts.append((unit(flamme(0.4, 400.0, 1800.0)), t + 0.12, 0.25))
        parts.append((unit(crepite(0.5, 80)), t + 0.15, 0.15))
    dur = times[-1] + 0.9
    out = mix(dur, *parts)
    out = room(out, 0.7, 6.0, 4500.0, 0.12, seed=7016 + k)
    return finish(out, 0.89, 0.25)


def chien_enfer_grogne(k: int) -> np.ndarray:
    dur = [2.3, 1.9][k]
    g = gronde(dur - 0.3, [64.0, 72.0][k], 1.25, rise=k == 1)
    gr = lp(slow(clip_rec(BEAST + ["Growl.wav", "Growl 1.wav"][k], -2.0, 2.0, 0.4), 1.25), 1500)
    parts = [(unit(g), 0.0, 1.0), (_fade(gr, 0.1, 0.5), 0.05, 0.45),
             (unit(sifflement(dur - 0.4, 1500, 6000, 0.2, 0.5)), 0.1, 0.12), (unit(crepite(dur - 0.3, 25)), 0.1, 0.12)]
    if k == 1:
        x = _t(0.5)
        teeth = bp(noise(0.5), 3000, 7500) * np.clip(x / 0.1, 0, 1) * np.clip((0.5 - x) / 0.15, 0, 1)
        parts.append((unit(teeth), dur - 0.85, 0.25))
    out = mix(dur, *parts)
    out = room(out, 0.6, 7.0, 4000.0, 0.1, seed=7019 + k)
    return finish(out, 0.89, 0.3)


def chien_enfer_mort(k: int) -> np.ndarray:
    parts = []
    yelp = syllabe(0.15, [700.0, 920.0, 640.0], "a", 1.0, h=0.01, souffle=0.3, sat=1.5, voy2="i", rel=0.04)
    parts.append((unit(yelp), 0.02, 0.9))
    if k == 0:
        wh = syllabe(0.65, [560.0, 470.0, 290.0], "ou", 1.0, h=0.03, souffle=0.4, rasp=0.03, rel=0.25, vib=0.015)
        parts.append((unit(wh), 0.22, 0.7))
        t = 0.75
    else:
        t = 0.3
    parts += [(unit(thump(80.0, 40.0, 0.12, 0.5)), t, 0.9), (clip_rec(KI + "impactSoft_heavy_002.ogg", -3.0), t, 0.5)]
    x = _t(1.6)
    fizz = bp(noise(1.6), 1500, 7000) * np.exp(-x / 0.5) * np.clip(x / 0.03, 0, 1)
    parts += [(unit(fizz), t + 0.05, 0.35), (unit(crepite(1.4, lambda xx: 120 * np.exp(-xx / 0.4))), t + 0.05, 0.3),
              (unit(bouffee(0.8, 150.0, 1200.0, 0.05)), t + 0.1, 0.3)]
    if k == 1:
        parts.append((unit(whisper(0.7, [(0, "a"), (1.0, "ou")], 0.8, lo=150.0, att=0.08, rel=0.4)), t + 0.6, 0.25))
    out = mix(t + 1.8, *parts)
    out = room(out, 0.6, 7.0, 4000.0, 0.1, seed=7021 + k)
    return finish(out, 0.89, 0.4)


def cerbere_aboi(k: int) -> np.ndarray:
    parts = []
    heads = [(132.0, 1.4, 0.0, -8.0), (158.0, 1.2, 0.06, -5.0), (196.0, 1.0, 0.13, -2.0)]
    volleys = [[0.02, 0.44], [0.02, 0.3, 0.75]][k]
    for v, t in enumerate(volleys):
        order = heads if (k == 0 or v == len(volleys) - 1) else [heads[v]]
        for f0, size, off, semi in order:
            tt = t + (off if len(order) > 1 else 0.0) + RNG.uniform(-0.01, 0.01)
            parts.append((aboi(f0 * RNG.uniform(0.97, 1.03), size, RNG.uniform(0.22, 0.28)), tt, RNG.uniform(0.75, 1.0)))
            parts.append((lp(clip_rec(CRE + "barking_0%d.ogg" % RNG.integers(1, 3), semi), 2600), tt, 0.18))
    dur = volleys[-1] + 1.1
    out = mix(dur, *parts)
    out = room(out, 1.6, 2.4, 3500.0, 0.22, seed=7023 + k)
    return finish(out, 0.9, 0.4)


def ronfle(dur: float, rate: float, scale: float = 1.0) -> np.ndarray:
    """Un ronflement (l'inspiration) : le voile du palais qui vibre (rate coups par seconde) dans le
    souffle, qui enfle et retombe."""
    x = _t(dur)
    r = rate * (1 + 0.08 * np.sin(2 * np.pi * 0.7 * x))
    ph = np.cumsum(r) / SR
    pulse = np.exp(-(ph % 1.0) * 5.0)
    exc = nz(len(x)) * (0.25 + pulse) + pulse * 0.8
    y = formants(exc, [(280 * scale, 120, 1.0), (750 * scale, 200, 0.5), (1500 * scale, 300, 0.2)])
    env = np.sin(np.pi * np.clip(x / dur, 0, 1)) ** 0.8 * (0.35 + 0.65 * x / dur)
    return y * env


def expire(dur: float, kind: str = "pff", f: float = 1200.0) -> np.ndarray:
    """L'expiration : les lèvres qui battent (« pfffbbb »), ou un sifflement de nez qui descend."""
    x = _t(dur)
    env = np.clip(x / 0.05, 0, 1) * np.exp(-x / (dur * 0.45))
    if kind == "pff":
        y = bp(noise(dur), 300, 3500) * (0.6 + 0.4 * np.sin(2 * np.pi * 14.0 * x) ** 2)
    else:
        ff = np.interp(x, [0, dur], [f, f * 0.72])
        y = np.sin(2 * np.pi * np.cumsum(ff) / SR) * 0.8 + bp(noise(dur), 800, 3000) * 0.4
    return y * env


def cerbere_ronfle(k: int) -> np.ndarray:
    parts = []
    sn = [lp(clip_rec(CRE + "snore.ogg", s), 3000) for s in (-6.0, -2.0, 2.0)]
    if k == 0:
        dur = 5.6
        parts += [(unit(ronfle(1.4, 26.0, 0.75)), 0.0, 1.0), (sn[0], 0.6, 0.3), (unit(expire(0.9, "pff")), 1.45, 0.55),
                  (unit(ronfle(1.1, 38.0, 0.95)), 1.25, 0.75), (sn[1], 1.7, 0.25), (unit(expire(0.8, "siffle", 1350.0)), 2.4, 0.4),
                  (unit(ronfle(0.9, 50.0, 1.15)), 2.6, 0.6), (sn[2], 2.95, 0.25), (unit(expire(0.4, "pff")), 3.55, 0.4)]
        # les babines de la petite tête : « mnyam mnyam »
        for t in (4.05, 4.3):
            parts.append((unit(clack(RNG.uniform(900, 1300), 0.01, 0.4, 0.6)), t, 0.25))
            parts.append((unit(lp(syllabe(0.12, [240.0, 220.0], "ou", 1.2, h=0.0, souffle=0.1), 900)), t + 0.02, 0.2))
        parts += [(unit(ronfle(1.2, 25.0, 0.75)), 4.4, 0.8)]
    else:
        dur = 5.2
        parts += [(unit(ronfle(1.5, 27.0, 0.75)), 0.0, 1.0), (unit(ronfle(1.4, 39.0, 0.95)), 0.08, 0.65),
                  (unit(ronfle(1.3, 52.0, 1.15)), 0.15, 0.5), (sn[0], 0.7, 0.3), (sn[2], 0.9, 0.2),
                  (unit(expire(1.0, "pff")), 1.7, 0.6), (unit(expire(0.9, "siffle", 1500.0)), 2.6, 0.45),
                  (unit(expire(0.35, "pff")), 3.5, 0.4), (unit(ronfle(1.3, 27.0, 0.75)), 3.85, 0.8)]
    out = mix(dur, *parts)
    out = room(out, 1.2, 3.0, 3500.0, 0.15, seed=7025 + k)
    return finish(out, 0.88, 0.4)


# =================================================================== les gargouilles, les ombres, les Furies

def gargouille_cri(k: int) -> np.ndarray:
    parts = []
    if k == 0:
        dur = 1.6
        sq = squawk(0.95, [850, 1350, 1220, 820], am=48.0, depth=0.6, sub=0.5, noise_g=0.6, tp=[0, 0.2, 0.6, 1.0], rasp=0.1)
        parts += [(unit(lp(sq, 5000)), 0.02, 1.0), (unit(pierre_gorge(0.95)) * np.interp(np.arange(int(0.95 * SR)), [0, 0.2 * SR, 0.95 * SR], [0.3, 1.0, 0.2]), 0.02, 0.4),
                  (unit(syllabe(0.9, [140.0, 175.0, 120.0], "a", 0.8, h=0.05, souffle=0.6, rasp=0.12, sat=2.0)), 0.04, 0.35),
                  (unit(grains(0.8, lambda x: 500 * np.exp(-x / 0.3), 1500, 7000)), 0.05, 0.15)]
    else:
        dur = 1.9
        for t, fs in ((0.02, [900, 1450, 1000]), (0.45, [950, 1550, 1250, 800])):
            sq = squawk(0.38 if len(fs) == 3 else 0.6, fs, am=52.0, depth=0.6, sub=0.5, noise_g=0.6, rasp=0.1)
            parts.append((unit(lp(sq, 5000)), t, 0.9))
            parts.append((unit(pierre_gorge(0.4)), t, 0.3))
        parts.append((aile_pierre(1.3), 1.0, 0.6))
    out = mix(dur, *parts)
    out = room(out, 1.0, 4.0, 4500.0, 0.15, seed=7027 + k)
    return finish(out, 0.89, 0.3)


def gargouille_mort(k: int) -> np.ndarray:
    dur = 2.8
    parts = [(slow(clip_rec(BFH + "bfh1_rock_breaking_01.ogg", 0.0), 1.2), 0.0, 0.8),
             (unit(lp(squawk(0.6, [900, 650, 400], am=40.0, depth=0.6, sub=0.5, noise_g=0.6), 4000)), 0.02, 0.5),
             (unit(thump(70.0, 40.0, 0.1, 0.5)), 0.45, 0.7)]
    for i in range(8):
        c = slow(clip_rec(BFH + "bfh1_rock_falling_0%d.ogg" % RNG.integers(1, 10), 0.0), RNG.uniform(1.0, 1.4))
        parts.append((lp(c, 5000), RNG.uniform(0.35, 1.6), RNG.uniform(0.15, 0.35)))
    parts.append((clip_rec(RPG + "stones_01.ogg", -2.0), 0.45, 0.45))
    for i in range(10):
        parts.append((clack(RNG.uniform(900, 2600), RNG.uniform(0.008, 0.02), 0.8, 0.3), 0.6 + RNG.exponential(0.45), RNG.uniform(0.05, 0.15)))
    parts.append((unit(grains(1.8, lambda x: 900 * np.exp(-x / 0.6), 2500, 9000)), 0.4, 0.12))
    out = mix(dur, *parts)
    out = room(out, 1.0, 4.0, 4000.0, 0.15, seed=7029)
    return finish(out, 0.9, 0.4)


def aile_pierre(size: float = 1.3) -> np.ndarray:
    """Une aile de pierre : un battement (le souffle, l'air chassé), et le crissement du gravier dans
    les articulations, un frottement de pierre."""
    w = wing_beat(size)
    d = 0.5 * size
    g = grains(0.35, lambda x: 1800 * np.exp(-x / 0.1), 1500, 7000)
    scrape = lp(s63.stone_grind(0.3, 80.0), 1500) * np.sin(np.pi * np.clip(_t(0.3) / 0.3, 0, 1))
    return mix(len(w) / SR + 0.2, (unit(w), 0.0, 1.0), (unit(g), d * 0.5, 0.35), (unit(scrape), d * 0.45, 0.3),
               (unit(thump(60.0, 35.0, 0.06, 0.3)), d * 0.95, 0.35))


def ailes_pierre(k: int) -> np.ndarray:
    beats = [[0.0, 0.72], [0.0, 0.55, 1.1]][k]
    parts = [(aile_pierre(RNG.uniform(1.2, 1.45)), t, 1.0 - 0.1 * i) for i, t in enumerate(beats)]
    if k == 1:
        for i in range(5):
            parts.append((clack(RNG.uniform(1200, 2800), 0.01, 0.8, 0.2), RNG.uniform(0.3, 1.5), 0.08))
    out = mix(beats[-1] + 1.0, *parts)
    out = room(out, 0.8, 5.0, 4500.0, 0.12, seed=7030 + k)
    return finish(out, 0.89, 0.3)


def chuchote(sylls) -> np.ndarray:
    """Des chuchotements : une consonne de bruit (s, ch, f, h), puis une voyelle soufflée."""
    out = []
    for cons, v1, v2, d in sylls:
        if cons:
            lo, hi, cd = {"s": (4000, 9500, 0.1), "ch": (1800, 6000, 0.12), "f": (1200, 6000, 0.09), "h": (500, 3000, 0.07)}[cons]
            m = int(cd * SR)
            out.append(bp(nz(m), lo, hi) * np.hanning(m) * 0.35)
        if v1:
            out.append(unit(whisper(d, [(0, v1), (1.0, v2 or v1)], 1.1, lo=300.0, att=0.06, rel=d * 0.5)) * 0.6)
        out.append(np.zeros(int(RNG.uniform(0.04, 0.1) * SR)))
    return np.concatenate(out)


def ombre_murmure(k: int) -> np.ndarray:
    phr = [[("ch", None, None, 0), ("h", "ou", "a", 0.45), ("s", "a", "é", 0.35)],
           [("f", "i", None, 0.25), ("f", "ou", None, 0.4), ("h", "a", "o", 0.5)],
           [("h", "é", "ou", 0.4), ("ch", "ou", None, 0.3), ("s", None, None, 0)]][k]
    w = chuchote(phr)
    dur = len(w) / SR + 1.2
    parts = [(unit(lp(w, 7000)), 0.05, 1.0)]
    if k == 2:
        hum = lp(syllabe(1.1, [220.0, 235.0, 210.0], "ou", 1.1, h=0.0, souffle=0.3, att=0.3, rel=0.5, vib=0.01), 1200)
        parts.append((unit(hum), 0.1, 0.25))
    parts.append((unit(etincelles(len(w) / SR, 4, 2000.0, 4200.0, (0.3, 0.6))), 0.15, 0.06))
    out = mix(dur, *parts)
    out = room(out, 2.4, 1.6, 4500.0, 0.42, seed=7032 + k)
    return finish(out, 0.8, 0.6)


def furie_cri(k: int) -> np.ndarray:
    parts = [(wing_beat(1.2), 0.0, 0.7)]
    cries = [[(0.35, 0.8)], [(0.3, 0.38), (0.78, 0.45)]][k]
    for t, d in cries:
        sq = squawk(d, [1100, 1750, 1600, 1150], am=70.0, depth=0.5, sub=0.25, noise_g=0.5, rasp=0.07, tp=[0, 0.18, 0.55, 1.0])
        vo = syllabe(d, [520.0, 790.0, 700.0, 560.0], "i", 1.2, h=0.02, souffle=0.4, rasp=0.05, sat=2.0, voy2="a",
                     tp=[0, 0.2, 0.6, 1.0], rel=d * 0.4)
        parts += [(unit(lp(sq, 7000)), t, 0.8), (unit(vo), t, 0.6)]
    parts.append((lp(clip_rec(CRE + "scream_01.ogg", -3.0, 0.8, 0.2), 6000), cries[0][0], 0.2))
    parts.append((wing_beat(1.2), cries[-1][0] + cries[-1][1] * 0.7, 0.6))
    dur = cries[-1][0] + cries[-1][1] + 1.0
    out = mix(dur, *parts)
    out = room(out, 1.2, 3.5, 5000.0, 0.15, seed=7035 + k)
    return finish(out, 0.89, 0.3)


# =================================================================== Charon, l'obole

def coup_rame(dark: float = 1800.0) -> np.ndarray:
    """La rame de Charon : la pale qui plonge dans l'eau noire, le remous qu'on tire, les gouttes, le
    tolet qui grince."""
    s = lp(slow(clip_rec(SPL + "splash_%02d.ogg" % [8, 9, 13][RNG.integers(0, 3)], -2.0, 0.6, 0.15), 1.5), dark)
    m = int(0.8 * SR)
    xs = np.arange(m) / SR
    sw = bp(nz(m), 150, 900) * np.sin(np.pi * xs / xs[-1]) * (1 + 0.4 * amb.smooth_env(m, 6.0, -1, 1))
    parts = [(unit(s68.rope_creak(0.45)), 0.0, 0.18), (s, 0.25, 1.0), (unit(sw), 0.35, 0.4)]
    for i in range(RNG.integers(2, 4)):
        f0 = RNG.uniform(120, 220)
        parts.append((unit(blorp(f0, f0 * 2.2, RNG.uniform(0.04, 0.07), 0.3)), 0.45 + RNG.uniform(0, 0.5), 0.15))
    for i in range(RNG.integers(4, 7)):
        parts.append((lp(s59.drip(), 3200), 1.1 + i * RNG.uniform(0.1, 0.2), 0.12 * 0.85 ** i))
    return mix(2.4, *parts)


def charon_rame(k: int) -> np.ndarray:
    if k == 2:
        out = mix(3.2, (coup_rame(), 0.0, 0.8), (coup_rame(), 1.35, 0.7))
    else:
        out = coup_rame(1800.0 if k == 0 else 1500.0)
        if k == 1:
            hull = unit(s59.wood_groan(1.2, 16.0))
            out = mix(2.6, (out, 0.0, 1.0), (hull, 0.9, 0.25), (unit(s56.lapping(int(1.4 * SR))[:, 0]), 1.0, 0.25))
    out = room(out, 1.6, 2.2, 3500.0, 0.25, seed=7037 + k)
    return finish(out, 0.89, 0.4)


def obole(k: int) -> np.ndarray:
    if k == 0:
        # la pièce tombe dans la paume : le petit choc mat, le tintement tout de suite étouffé, une autre pièce
        palm = addp(unit(thump(200.0, 130.0, 0.018, 0.08)), unit(bp(nz(int(0.02 * SR)), 250, 1500) * np.hanning(int(0.02 * SR))) * 0.5)
        parts = [(unit(tinte(3350.0, 0.004, 0.8)), 0.0, 0.5), (palm, 0.002, 0.8), (unit(tinte(3350.0, 0.022, 1.0)), 0.004, 0.35),
                 (unit(tinte(4150.0, 0.05, 0.9)), 0.11, 0.45), (lp(clip_rec(KR + "handleCoins2.ogg", 2.0, 0.3, 0.1), 9000), 0.1, 0.25)]
        x = _t(0.25)
        rub = bp(noise(0.25), 1000, 4500) * np.sin(np.pi * x / 0.25) * 0.15
        parts.append((rub, 0.3, 1.0))
        dur = 0.9
    else:
        # lancée en l'air, elle tinte en tournoyant, puis on la rattrape dans la main
        ring = tinte(3600.0, 0.5, 0.9)[: int(0.63 * SR)]
        x = np.arange(len(ring)) / SR
        ring *= 0.55 + 0.45 * np.sin(2 * np.pi * np.interp(x, [0, x[-1]], [16.0, 9.0]) * x) ** 2
        ring = _fade(ring, 0.0, 0.012)
        catch = addp(unit(thump(180.0, 120.0, 0.02, 0.08)), unit(bp(nz(int(0.025 * SR)), 300, 1800) * np.hanning(int(0.025 * SR))) * 0.6)
        parts = [(unit(clack(2400.0, 0.006, 1.0, 0.1)), 0.0, 0.4), (unit(ring), 0.005, 0.5), (catch, 0.62, 0.9),
                 (unit(tinte(3600.0, 0.015, 1.0)), 0.625, 0.3)]
        dur = 1.1
    out = mix(dur, *parts)
    out = room(out, 0.3, 14.0, 9000.0, 0.06, seed=7040 + k)
    return finish(out, 0.86, 0.1)


# =================================================================== la glace et le Titan

def craque_glace(size: float = 1.0, n: int = 700, a: float = -0.8) -> np.ndarray:
    """Une fissure dans la glace : le claquement sec, puis le « piou » (les aigus filent d'abord, les
    graves suivent, comme dans un ressort : une cascade de filtres passe-tout), ses échos dans la
    plaque de glace, et la plaque qui gronde."""
    buf = np.zeros(int(1.0 * SR))
    m = int(0.003 * SR)
    buf[:m] = nz(m) * np.hanning(m)
    ch = hp(disperse(buf, a, n), 150)
    ch = unit(ch)
    for d, g in ((RNG.uniform(0.06, 0.11), 0.4), (RNG.uniform(0.15, 0.24), 0.2)):
        k = int(d * SR)
        ch[k:] += ch[:-k] * g
    k = int(0.03 * SR)
    xs = np.arange(k) / SR
    snap = bp(nz(k), 1500, 9000) * np.exp(-xs / 0.005)
    th = thump(90.0 / size, 50.0 / size, 0.05 * size, 0.3)
    return addp(unit(ch), unit(snap) * 0.45, unit(th) * 0.4 * size)


def glace_craque(k: int) -> np.ndarray:
    parts = []
    if k == 0:
        dur = 2.0
        parts += [(craque_glace(1.3, 900), 0.0, 1.0), (craque_glace(0.8, 600, -0.75), 0.27, 0.35), (craque_glace(0.7, 500, -0.72), 0.52, 0.22)]
        parts.append((unit(grains(1.0, lambda x: 300 * np.exp(-x / 0.3), 2000, 8000)), 0.02, 0.12))
    elif k == 1:
        dur = 2.3
        gr = s59.wood_groan(0.9, 26.0)
        gr = bp(gr, 300, 2500) + bp(gr, 900, 2200) * 0.5
        parts += [(unit(gr), 0.0, 0.45), (craque_glace(1.0, 800), 0.85, 1.0), (craque_glace(0.6, 500, -0.75), 1.15, 0.25)]
    else:
        dur = 2.4
        for i, t in enumerate((0.0, 0.18, 0.31, 0.55, 0.82)):
            parts.append((craque_glace(1.2 - 0.12 * i, int(900 - 80 * i), -0.8 + 0.02 * i), t, 1.0 * 0.8 ** i))
        parts.append((unit(grains(1.4, lambda x: 250 * np.exp(-x / 0.5), 2000, 8000)), 0.05, 0.12))
    out = mix(dur, *parts)
    out = room(out, 1.4, 2.6, 6000.0, 0.22, seed=7042 + k)
    out = s68.soft_limit(out, 0.45 * np.max(np.abs(out)))
    return finish(out, 0.9, 0.4)


def souffle_givre(k: int) -> np.ndarray:
    dur = [1.9, 2.3][k]
    d = dur - 0.4
    x = _t(d)
    breath = bp(noise(d), 600, 6000) * np.clip(x / 0.12, 0, 1) * np.clip((d - x) / (0.5 * d), 0, 1) ** 1.3
    breath = sweep(breath, np.interp(x, [0, d], [5000.0, 1800.0]), "lowpass", 2)
    wh = whisper(d, [(0, "ou"), (1.0, "a")], 1.0, lo=400.0, att=0.12, rel=d * 0.5)
    parts = [(unit(breath), 0.0, 0.7), (unit(wh), 0.0, 0.35),
             (unit(etincelles(d, [22, 34][k], 3000.0, 9000.0)), 0.15, 0.35),
             (unit(grains(d, lambda t: 2500 * np.clip((t - 0.4 * d) / (0.6 * d), 0, 1), 4000, 10000)), 0.0, 0.18)]
    g = clip_bank(VCSL, "Idiophones/Friction Idiophones/Wine Glasses/Sustains/Fast/glass4_D5_Fast_1_Main.wav", 12.0, 1.0, 0.5)
    parts.append((_fade(g, 0.3, 0.5), 0.2, 0.12))
    out = mix(dur, *parts)
    out = room(out, 1.2, 3.0, 8000.0, 0.2, seed=7045 + k)
    return finish(out, 0.86, 0.4)


def titan_rugit(k: int) -> np.ndarray:
    d = [2.8, 1.9][k]
    dur = d + 1.6
    roar = syllabe(d, [40.0, 52.0, 58.0, 50.0, 38.0], "a", 0.6, h=0.12, souffle=0.7, rasp=0.15, sub=0.8, sat=2.8,
                   tilt=0.9, voy2="o", att=0.25, rel=0.7)
    r1 = lp(slow(clip_rec(CRE2 + "roar_05.ogg", 0.0), 2.1), 2500)
    r2 = lp(slow(clip_rec(CRE2 + "roar_04.ogg", 0.0), 1.8), 2000)
    x = _t(d)
    howl = sweep(noise(d), np.interp(x, [0, 0.3 * d, d], [400.0, 1800.0, 600.0]), q=3.0) * np.sin(np.pi * np.clip(x / d, 0, 1)) ** 0.8
    sub = np.sin(2 * np.pi * 33 * x) * np.clip(x / 0.4, 0, 1) * np.clip((d - x) / 0.8, 0, 1)
    parts = [(unit(roar), 0.0, 1.0), (_fade(r1, 0.05, 0.6), 0.05, 0.5), (_fade(r2, 0.05, 0.6), 0.2, 0.35),
             (unit(howl), 0.1, 0.3), (sub, 0.0, 0.35)]
    for t in sorted(RNG.uniform(0.3, d, 3)):
        parts.append((craque_glace(RNG.uniform(0.8, 1.2), int(RNG.integers(500, 900))), t, 0.35))
    for i in range(6):
        c = slow(clip_rec(BFH + "bfh1_glass_falling_0%d.ogg" % RNG.integers(1, 5), 0.0), RNG.uniform(1.2, 1.6))
        parts.append((lp(c, 6000), RNG.uniform(0.6 * d, d + 0.5), RNG.uniform(0.08, 0.2)))
    if k == 1:
        parts.append((titan_pas(0) * 0.8, d * 0.75, 0.6))
    out = mix(dur, *parts)
    out = room(out, 2.2, 1.7, 3500.0, 0.28, seed=7047 + k)
    return finish(out, 0.93, 0.5)


def titan_pas(k: int) -> np.ndarray:
    dur = 1.7
    x = _t(0.25)
    imp = lp(noise(0.25), 400) * np.exp(-x / 0.05)
    crunch = grains(0.3, lambda t: 5000 * np.exp(-t / 0.06), 1200, 8000)
    snow = lp(slow(clip_rec(KI + "footstep_snow_00%d.ogg" % k, -4.0), 1.5), 5000)
    parts = [(unit(thump(42.0, 28.0, 0.22, 1.0)), 0.0, 1.0), (unit(imp), 0.0, 0.6), (unit(crunch), 0.0, 0.4), (snow, 0.0, 0.4),
             (craque_glace(0.9, [600, 750, 500][k], -0.78), 0.03, 0.35), (unit(etincelles(0.5, 8, 2500.0, 6000.0)), 0.1, 0.18),
             (unit(lp(noise(1.0), 80) * np.exp(-_t(1.0) / 0.35)), 0.02, 0.5)]
    out = mix(dur, *parts)
    out = room(out, 1.6, 2.4, 3000.0, 0.2, seed=7049 + k)
    return finish(out, 0.92, 0.4)


# =================================================================== chaînes, grille, cloche

def maillons(dur: float, rate, g: float = 1.0) -> np.ndarray:
    """Des maillons qui s'entrechoquent : de petits chocs métalliques serrés (modes d'un anneau)."""
    out = np.zeros(int((dur + 0.2) * SR))
    t = 0.0
    while t < dur:
        r = rate(t) if callable(rate) else rate
        f = RNG.uniform(1800, 4200)
        c = modal([(f, 1.0, 0.012), (f * 2.71, 0.6, 0.008), (f * 5.1, 0.3, 0.005)], 0.06)
        amb.place(out, c, int(t * SR), g * RNG.uniform(0.3, 1.0))
        t += 1.0 / max(r, 1e-3) * RNG.uniform(0.4, 1.6)
    return out


def chaines(k: int) -> np.ndarray:
    if k == 0:
        dur = 1.8
        parts = [(clip_rec(RPG + "chain_01.ogg"), 0.0, 0.6), (clip_rec(RPG + "chain_03.ogg", -1.0), 0.45, 0.6),
                 (unit(maillons(1.4, lambda t: 40 * np.sin(np.pi * min(1.0, t / 1.4)) + 5)), 0.0, 0.6),
                 (lp(cut(rec(BBR + "Metal Rattling 1.wav"), 0.2, 1.4, 0.02, 0.3), 8000), 0.1, 0.3)]
    elif k == 1:
        dur = 2.3
        x = _t(2.0)
        scrape = bp(noise(2.0), 800, 4000) * (0.5 + 0.5 * amb.smooth_env(len(x), 30.0, 0, 1)) * np.sin(np.pi * x / 2.0) ** 0.5
        parts = [(unit(maillons(2.0, 25)), 0.0, 0.7), (unit(scrape), 0.0, 0.25), (slow(clip_rec(RPG + "chain_02.ogg"), 1.2), 0.3, 0.5),
                 (slow(clip_rec(RPG + "chain_01.ogg"), 1.3), 1.2, 0.4)]
    else:
        dur = 1.6
        parts = [(unit(maillons(0.8, lambda t: 90 * np.exp(-t / 0.3) + 4)), 0.0, 0.8), (clip_rec(RPG + "chain_03.ogg", -2.0), 0.0, 0.6),
                 (unit(thump(140.0, 80.0, 0.04, 0.2)), 0.05, 0.4), (clip_rec(KI + "impactMetal_light_002.ogg", -3.0), 0.04, 0.3)]
    out = mix(dur, *parts)
    out = room(out, 0.8, 5.0, 6000.0, 0.12, seed=7052 + k)
    return finish(out, 0.89, 0.3)


def gond(dur: float, r0: float, r1: float, res=(310.0, 740.0, 1380.0, 2250.0)) -> np.ndarray:
    """Un gond de fer qui gémit : la friction (le métal qui accroche et glisse, des impulsions dont la
    cadence donne la note du gémissement, qui glisse) fait chanter les résonances de la grille."""
    x = _t(dur)
    rate = np.interp(x, np.linspace(0, dur, 4), [r0, r0 * 1.25, r1 * 0.9, r1]) * (1 + 0.06 * amb.smooth_env(len(x), 4.0, -1, 1))
    ph = np.cumsum(rate) / SR
    pulses = (np.diff(np.floor(ph), prepend=0) > 0).astype(float) * RNG.uniform(0.6, 1.0, len(x))
    y = sum(bp(pulses, f * 0.96, f * 1.04) * g for f, g in zip(res, (1.0, 0.8, 0.5, 0.3)))
    y += lp(pulses, 1800) * 0.4
    y += bp(noise(dur), 300, 2500) * 0.01
    y *= 0.6 + 0.4 * amb.smooth_env(len(x), 5.0, 0.0, 1.0)
    return y * np.clip(x / 0.15, 0, 1) * np.clip((dur - x) / 0.3, 0, 1)


def grande_porte(k: int) -> np.ndarray:
    dur, mv = [(7.2, 4.6), (5.4, 3.2)][k]
    parts = [(slow(clip_rec(KR + "metalLatch.ogg", -3.0), 1.5), 0.0, 0.7), (clip_rec(KI + "impactMetal_heavy_001.ogg", -5.0), 0.05, 0.6),
             (unit(thump(70.0, 45.0, 0.08, 0.4)), 0.05, 0.5)]
    t0 = 0.6
    parts.append((s63.ratchet(int(mv * 3.5), 3.5, 0.5), t0, 0.2))
    res = (310.0, 740.0, 1380.0, 2250.0) if k == 0 else (260.0, 620.0, 1150.0, 1980.0)
    parts.append((rmsn(gond(mv * 0.58, 70.0, 128.0, res), 0.25), t0 + 0.1, 1.0))
    parts.append((rmsn(gond(mv * 0.42, 140.0, 95.0, tuple(r * 1.12 for r in res)), 0.2), t0 + mv * 0.55, 1.0))
    x = _t(mv)
    rumble = lp(noise(mv), 140) * np.sin(np.pi * np.clip(x / mv, 0, 1)) ** 0.6
    grind = lp(s63.stone_grind(mv, 45.0), 700) * np.sin(np.pi * np.clip(x / mv, 0, 1)) ** 0.8
    parts += [(rmsn(rumble, 0.08), t0, 1.0), (rmsn(grind, 0.035), t0, 1.0)]
    te = t0 + mv
    ring = modal([(178.0, 1.0, 1.6), (421.0, 0.6, 1.0), (763.0, 0.4, 0.6), (1190.0, 0.25, 0.35)], 3.0)
    parts += [(slow(clip_rec(KI + "impactMetal_heavy_003.ogg", -4.0), 1.4), te, 0.9), (slow(clip_rec(KI + "impactMetal_heavy_000.ogg", -2.0), 1.3), te + 0.03, 0.6),
              (unit(thump(50.0, 30.0, 0.25, 1.0)), te, 1.0), (unit(ring), te, 0.4)]
    out = mix(dur, *parts)
    out = room(out, 2.5, 1.5, 3500.0, 0.25, seed=7055 + k)
    return finish(out, 0.92, 0.8)


def cloche_cathedrale(k: int) -> np.ndarray:
    f = [146.83, 110.0][k]
    dur = 10.0
    b = s56.bronze_bell(f, dur, 1.0)
    tube = bank(VCSL, ST + "Tubular Bells 2/TB_hit_D4_v4_2.wav")
    parts = [(unit(b), 0.0, 1.0)]
    if len(tube):
        t = trim(s56._shift(tube, [-12.0, -17.0][k]))[: int(dur * SR)]
        t = _fade(t, 0.002, 2.0)
        parts.append((unit(t), 0.0, 0.5))
    m = int(0.02 * SR)
    parts.append((unit(bp(nz(m), 600, 4000) * np.hanning(m)), 0.0, 0.3))
    parts.append((unit(thump(90.0, 60.0, 0.05, 0.3)), 0.0, 0.25))
    out = mix(dur, *parts)
    out = room(out, 4.0, 0.75, 3500.0, 0.35, seed=7057 + k)
    return finish(out, 0.9, 2.5)


# =================================================================== l'Arène

def claps(n: int, t0: float, t1: float, g=(0.1, 0.3), dens=None) -> list:
    """Des applaudissements : des claquements de mains (VCSL), chacun un peu différent."""
    parts = []
    for _ in range(n):
        t = RNG.uniform(t0, t1) if dens is None else t0 + RNG.exponential(dens)
        if t > t1:
            continue
        c = clip_bank(VCSL, ST + "Claps/Clap_rr%d.wav" % RNG.integers(1, 7), RNG.uniform(-2.0, 2.0), 0.3)
        if len(c) <= int(0.1 * SR) + 1:
            m = int(0.02 * SR)
            c = bp(nz(m), 800, 5000) * np.exp(-np.arange(m) / (0.004 * SR))
        parts.append((lp(c, RNG.uniform(3000, 7000)), t, RNG.uniform(*g)))
    return parts


def stomp(g: float = 1.0) -> np.ndarray:
    c = clip_bank(VSCO, "VSCO 1 Percussion/drums/bass/bdrum_muted_mf_1.wav", RNG.uniform(-2.0, 1.0), 0.6)
    return addp(lp(c, 2500), unit(thump(90.0, 55.0, 0.06, 0.3)) * 0.5) * g


def arene_foule(k: int) -> np.ndarray:
    parts = []
    if k == 0:
        dur = 3.4
        for _ in range(30):
            fem = RNG.random() < 0.25
            v = shout(RNG.uniform(0.9, 1.8), RNG.uniform(240, 330) if fem else RNG.uniform(110, 210), "ou",
                      "è" if RNG.random() < 0.6 else "a", at=RNG.uniform(0.06, 0.14), scale=1.15 if fem else 1.0)
            parts.append((unit(v), RNG.uniform(0.0, 0.4), RNG.uniform(0.06, 0.16)))
        parts += claps(70, 0.15, 3.0, dens=0.9)
        parts += [(s68.whistle(0), 0.5, 0.18), (s68.whistle(2), 1.4, 0.14)]
        for i in range(4):
            parts.append((stomp(), i * 0.21, 0.35))
    elif k == 1:
        dur = 3.6
        for _ in range(22):
            v = shout(RNG.uniform(0.75, 1.1), RNG.uniform(110, 230), "o", shape="oh", att=0.05, rel=0.4)
            parts.append((unit(v), RNG.uniform(0.0, 0.12), RNG.uniform(0.07, 0.14)))
        for _ in range(26):
            v = shout(RNG.uniform(0.9, 1.6), RNG.uniform(120, 300), "ou", "è", at=0.1)
            parts.append((unit(v), RNG.uniform(1.0, 1.5), RNG.uniform(0.05, 0.13)))
        parts += claps(60, 1.1, 3.3, dens=0.8)
        parts.append((s68.whistle(1), 1.3, 0.16))
    else:
        dur = 3.8
        for beat in range(3):
            t = beat * 0.5
            for _ in range(20):
                v = shout(0.24, RNG.uniform(110, 200), "o", shape="chant", att=0.02, rel=0.1, breath=0.3)
                parts.append((unit(v), max(0.0, t + RNG.uniform(-0.02, 0.03)), RNG.uniform(0.06, 0.12)))
            parts.append((stomp(), t, 0.5))
            parts += claps(18, t + 0.24, t + 0.3, g=(0.06, 0.16))
        for _ in range(28):
            v = shout(RNG.uniform(1.0, 1.8), RNG.uniform(120, 300), "ou", "a", at=0.08)
            parts.append((unit(v), RNG.uniform(1.5, 1.8), RNG.uniform(0.05, 0.13)))
        parts += claps(50, 1.6, 3.5, dens=0.7)
        parts.append((s68.whistle(0), 1.9, 0.15))
    out = mix(dur, *parts)
    out = lp(out, 6500)
    out = room(out, 1.4, 2.8, 4000.0, 0.2, seed=7060 + k)
    return finish(out, 0.89, 0.6)


def arene_gong(k: int) -> np.ndarray:
    dur = [7.0, 6.0][k]
    if k == 0:
        g = bank(VCSL, ST + "Gong 1/gong_fff.wav")
    else:
        g = bank(VSCO, "VSCO 1 Percussion/varMetal/Gong/gong_hit_ff.wav")
    if len(g):
        g = trim(s56._shift(g, [0.0, -1.0][k]))[: int(dur * SR)]
        g = _fade(g, 0.001, 2.0)
    else:
        g = modal([(f, a, d) for f, a, d in [(92, 1.0, 4.0), (147, 0.7, 3.0), (233, 0.6, 2.5), (318, 0.5, 2.0), (452, 0.4, 1.5),
                                             (611, 0.3, 1.2), (877, 0.2, 0.8), (1290, 0.15, 0.5)]], dur)
    parts = [(unit(g), 0.0, 1.0), (unit(thump(75.0, 45.0, 0.07, 0.35)), 0.0, 0.3)]
    out = mix(dur, *parts)
    out = room(out, 2.0, 1.6, 5000.0, 0.15, seed=7063 + k)
    return finish(out, 0.9, 1.5)


# =================================================================== le feu d'artifice, les lanternes

def fusee(dur: float, sifflet: bool = True, f0: float = 900.0, f1: float = 2600.0, sparks: float = 0.2) -> np.ndarray:
    """Une fusée qui monte : le souffle (dont la couleur monte), le sifflet, la traîne d'étincelles ;
    elle s'éloigne (plus faible, plus sourde)."""
    x = _t(dur)
    away = np.clip(1.0 - 0.85 * x / dur, 0.05, 1.0) ** 1.6
    w = sweep(noise(dur), np.interp(x, [0, dur], [700.0, 2600.0]), q=2.0)
    env = np.clip(x / 0.05, 0, 1) * away
    y = unit(w) * env * 0.7
    if sifflet:
        ff = f0 * (f1 / f0) ** (x / dur)
        ph = 2 * np.pi * np.cumsum(ff * (1 + 0.004 * np.sin(2 * np.pi * 9 * x))) / SR
        y += (np.sin(ph) + 0.2 * np.sin(2 * ph)) * env * 0.5
    if sparks > 0:
        y += unit(crepite(dur, 350, 2000, 8000)) * env * sparks
    return sweep(y, np.interp(x, [0, dur], [9000.0, 2500.0]), "lowpass", 2)


def depart(g: float = 1.0) -> list:
    """La mèche qui grésille, puis le « pfoum » du départ."""
    x = _t(0.35)
    fuse = bp(noise(0.35), 3000, 9000) * (0.5 + 0.5 * (RNG.random(len(x)) < 0.05)) * np.clip(x / 0.05, 0, 1)
    pf = lp(noise(0.18), 1500) * np.exp(-_t(0.18) / 0.04)
    return [(unit(fuse), 0.0, 0.25 * g), (unit(thump(110.0, 55.0, 0.05, 0.25)), 0.35, 0.7 * g), (unit(pf), 0.35, 0.6 * g)]


def artifice_depart(k: int) -> np.ndarray:
    if k == 0:
        parts = depart() + [(unit(fusee(1.9, True, 900.0, 2600.0)), 0.37, 0.8)]
        dur = 2.5
    elif k == 1:
        parts = [(unit(thump(110.0, 55.0, 0.05, 0.25)), 0.0, 0.7), (unit(lp(noise(0.18), 1500) * np.exp(-_t(0.18) / 0.04)), 0.0, 0.6),
                 (unit(fusee(1.7, False, sparks=0.6)), 0.02, 0.9)]
        dur = 2.0
    else:
        parts = depart(0.9) + [(unit(fusee(1.8, True, 1000.0, 2900.0)), 0.37, 0.75)]
        parts += [(unit(thump(120.0, 60.0, 0.05, 0.25)), 0.75, 0.5), (unit(fusee(1.6, True, 800.0, 2300.0)), 0.77, 0.55)]
        dur = 2.7
    out = mix(dur, *parts)
    out = room(out, 1.0, 4.0, 6000.0, 0.12, seed=7065 + k)
    return finish(out, 0.89, 0.4)


def boum(g: float = 1.0) -> np.ndarray:
    """Le « boum » d'une bombe d'artifice, et son écho sur les tours de la cité."""
    x = _t(0.6)
    b = addp(unit(thump(55.0, 32.0, 0.18, 1.2)), unit(lp(noise(0.6), 900) * np.clip(x / 0.004, 0, 1) * np.exp(-x / 0.12)) * 0.8,
             unit(bp(nz(int(0.02 * SR)), 800, 5000) * np.hanning(int(0.02 * SR))) * 0.4)
    return s69.echoes(b, [(0.28, 0.3), (0.61, 0.18), (1.05, 0.1)], 1500.0) * g


def petille(dur: float, r0: float = 1500.0, tau: float = 0.8) -> np.ndarray:
    """Les paillettes qui crépitent : des milliers de petits claquements, de plus en plus rares."""
    return crepite(dur, lambda x: r0 * np.exp(-x / tau), 2000.0, 9000.0)


def artifice_eclat(k: int) -> np.ndarray:
    if k == 0:
        dur = 3.8
        parts = [(boum(), 0.0, 1.0), (unit(petille(2.9)), 0.12, 0.45), (unit(sifflement(2.2, 3000, 9000, 0.1, 1.2)), 0.12, 0.08)]
    elif k == 1:
        dur = 3.4
        parts = [(boum(0.9), 0.0, 1.0)]
        for i in range(8):
            t = 0.45 + RNG.uniform(0, 0.7)
            pop = addp(unit(thump(RNG.uniform(140, 200), 90.0, 0.03, 0.12)), unit(bp(nz(int(0.015 * SR)), 1000, 6000) * np.hanning(int(0.015 * SR))) * 0.6)
            parts.append((pop, t, RNG.uniform(0.25, 0.45)))
        parts.append((unit(petille(2.0, 600.0, 0.6)), 0.5, 0.3))
    else:
        dur = 3.8
        parts = [(boum(0.9), 0.0, 1.0)]
        for i in range(6):
            dd = RNG.uniform(0.6, 1.1)
            x = _t(dd)
            ff = np.interp(x, [0, dd], [RNG.uniform(2600, 3400), RNG.uniform(1300, 1800)])
            wsl = np.sin(2 * np.pi * np.cumsum(ff) / SR) * np.sin(np.pi * x / dd) ** 1.2
            parts.append((unit(wsl), 0.3 + RNG.uniform(0, 0.6), RNG.uniform(0.06, 0.12)))
        parts.append((unit(petille(2.6, 500.0, 1.0)), 0.25, 0.3))
        parts.append((unit(etincelles(2.0, 10, 2500.0, 5000.0)), 0.4, 0.15))
    out = mix(dur, *parts)
    out = room(out, 1.8, 2.0, 5000.0, 0.15, seed=7068 + k)
    out = s68.soft_limit(out, 0.55 * np.max(np.abs(out)))
    return finish(out, 0.92, 0.8)


def lanterne_allume(k: int) -> np.ndarray:
    x = _t(0.6)
    fw = bp(noise(0.6), 150, 1500) * np.clip(x / 0.04, 0, 1) * np.exp(-x / 0.15)
    parts = [(unit(fw), 0.0, 0.8), (unit(flamme(0.7, 300.0, 1500.0)), 0.02, 0.35)]
    if k == 1:
        m = int(0.12 * SR)
        parts.insert(0, (unit(bp(nz(m), 2500, 8000) * np.hanning(m)), 0.0, 0.35))
        parts = [(p[0], p[1] + (0.1 if i > 0 else 0.0), p[2]) for i, p in enumerate(parts)]
    t = 0.18 if k == 0 else 0.28
    ch = clip_bank(VCSL, ST + "Hand Chimes/sus_%s_r01_main.wav" % ["E4", "A4"][k], 0.0, 2.0, 1.0)
    if len(ch) > int(0.1 * SR) + 1:
        parts.append((ch, t, 0.5))
    else:
        parts.append((unit(s63.bell([659.3, 880.0][k] * 2, 1.6, 0.8)), t, 0.5))
    parts.append((unit(etincelles(0.5, 5, 2500.0, 5000.0)), t + 0.02, 0.2))
    out = mix(2.3, *parts)
    out = room(out, 1.0, 4.0, 7000.0, 0.15, seed=7071 + k)
    return finish(out, 0.86, 0.5)


# =================================================================== la forge, Géryon, le contrat

def forge_marteau(k: int) -> np.ndarray:
    anv = [ST + "Anvil/Anvil_Hit1_v3_rr1_Mid.wav", ST + "Anvil/Anvil_Hit2_v3_rr1_Mid.wav", ST + "Anvil/Anvil_Hit3_v2_rr1_Mid.wav"][k]
    a = clip_bank(VCSL, anv, 0.0, 1.6, 0.5)
    m = clip_rec(WM + ["metal_hit_01.ogg", "metal_hit_03.ogg", "metal_hit_05.ogg"][k], -1.0, 1.2, 0.4)
    parts = [(a, 0.0, 1.0), (m, 0.0, 0.45), (unit(thump(300.0, 180.0, 0.02, 0.1)), 0.0, 0.3)]
    dur = 1.6
    if k == 1:
        for t, g in ((0.27, 0.35), (0.42, 0.22)):
            parts.append((clip_bank(VCSL, ST + "Anvil/Anvil_Hit1_v1_rr1_Mid.wav", 2.0, 0.8, 0.3), t, g))
        dur = 1.9
    if k == 2:
        parts = [(lp(a, 3000), 0.0, 0.7), (m, 0.0, 0.35), (unit(thump(220.0, 140.0, 0.03, 0.12)), 0.0, 0.6),
                 (unit(bp(nz(int(0.06 * SR)), 200, 1500) * np.exp(-np.arange(int(0.06 * SR)) / (0.012 * SR))), 0.0, 0.5)]
    out = mix(dur, *parts)
    out = room(out, 0.9, 5.0, 6000.0, 0.12, seed=7073 + k)
    out = s68.soft_limit(out, 0.5 * np.max(np.abs(out)))
    return finish(out, 0.89, 0.4)


def geryon_ailes(k: int) -> np.ndarray:
    beats = [[0.0, 0.95, 1.9], [0.0, 1.0]][k]
    parts = [(wing_beat(RNG.uniform(2.1, 2.4)), t, 1.0 - 0.08 * i) for i, t in enumerate(beats)]
    if k == 1:
        parts.append((unit(flutter(0.5, 20.0, 200.0, 1500.0)), 1.6, 0.35))
    x = _t(0.8)
    parts.append((unit(lp(noise(0.8), 120) * np.sin(np.pi * x / 0.8)), 0.4, 0.3))
    out = mix(beats[-1] + 1.4, *parts)
    out = room(out, 1.2, 3.5, 4000.0, 0.15, seed=7076 + k)
    return finish(out, 0.9, 0.4)


def plume(dur: float, strokes: int) -> np.ndarray:
    """La plume qui gratte le parchemin : des traits rapides, la pointe qui accroche les fibres."""
    out = np.zeros(int((dur + 0.2) * SR))
    t = 0.0
    for i in range(strokes):
        d = RNG.uniform(0.08, 0.22)
        m = int(d * SR)
        x = np.arange(m) / SR
        fib = (RNG.random(m) < RNG.uniform(60, 140) / SR).astype(float)
        y = bp(nz(m), 2500, 8000) * 0.4 + bp(fib, 2000, 7000) * 6.0
        y *= np.sin(np.pi * x / d) ** 0.6
        amb.place(out, y, int(t * SR), RNG.uniform(0.5, 1.0))
        t += d + RNG.uniform(0.02, 0.09)
        if t > dur:
            break
    return out


def contrat_signe(k: int) -> np.ndarray:
    d = [1.3, 0.75][k]
    pen = rec(PEN + "Pen Writing 1.wav")
    seg = hp(cut(pen, [1.0, 3.2][k], [1.0, 3.2][k] + d, 0.02, 0.15), 1200)
    parts = [(rmsn(seg, 0.09), 0.0, 1.0), (rmsn(plume(d, [9, 5][k]), 0.07), 0.0, 1.0),
             (unit(s63.whoosh(0.25, 1500.0, 4000.0, 0.5)), d - 0.15, 0.25)]
    ts = d + 0.15
    squish = lp(clip_rec(SPL + "slime_0%d.ogg" % [3, 6][k], -4.0, 0.25, 0.1), 2500)
    parts += [(unit(thump(140.0, 90.0, 0.04, 0.2)), ts, 0.8), (squish, ts + 0.01, 0.35),
              (clip_rec(KI + "impactWood_medium_00%d.ogg" % [1, 3][k], -2.0, 0.3), ts, 0.5)]
    notes = [[784.0, 988.0, 1175.0, 1568.0, 1976.0], [880.0, 1109.0, 1319.0, 1760.0]][k]
    for i, f in enumerate(notes):
        parts.append((s63.bell(f, 1.4, 0.8), ts + 0.15 + 0.08 * i, 0.3 - 0.03 * i))
    x = _t(1.0)
    sh = bp(noise(1.0), 5000, 11000) * np.clip(x / 0.3, 0, 1) * np.exp(-x / 0.4)
    parts += [(unit(sh), ts + 0.15, 0.12), (unit(s63.whoosh(0.6, 800.0, 3000.0, 0.5)), ts + 0.1, 0.15)]
    out = mix(ts + 2.0, *parts)
    out = room(out, 1.2, 4.0, 8000.0, 0.15, seed=7078 + k)
    return finish(out, 0.86, 0.6)


def bulles_eau(dur: float, rate: float) -> np.ndarray:
    """De petites bulles d'eau chaude : des « bloup » aigus et brefs (la note monte vite)."""
    out = np.zeros(int((dur + 0.2) * SR))
    for _ in range(int(dur * rate)):
        d = RNG.uniform(0.008, 0.03)
        m = int(d * SR)
        x = np.arange(m) / SR
        f0 = RNG.uniform(350, 1100)
        y = np.sin(2 * np.pi * np.cumsum(f0 * (1 + 2.5 * x / d)) / SR) * np.exp(-x / (d * 0.4)) * np.clip(x / 0.001, 0, 1)
        amb.place(out, y, int(RNG.uniform(0, dur) * SR), RNG.uniform(0.2, 1.0) ** 2)
    return out


def bain_soufre(k: int) -> np.ndarray:
    dur = [3.0, 3.3][k]
    boil = lp(clip_rec("30-cc0-sfx-loops/water_boiling.ogg", [-2.0, -3.5][k], dur, 0.3), 3500)
    parts = [(_fade(unit(boil), 0.3, 0.6), 0.0, 0.7), (unit(bulles_eau(dur - 0.3, 40)), 0.0, 0.35),
             (unit(sifflement(dur - 0.2, 2500, 9000, 0.4, 0.8, 0.5)), 0.0, 0.08)]
    for t in sorted(RNG.uniform(0.2, dur - 0.6, 3)):
        parts.append((unit(blorp(RNG.uniform(110, 160), RNG.uniform(280, 360), RNG.uniform(0.06, 0.1), 0.5)), t, 0.35))
    if k == 1:
        parts += [(unit(blorp(70.0, 180.0, 0.18, 0.9)), 1.4, 0.6), (unit(sifflement(1.0, 1200, 6000, 0.05, 0.6)), 1.6, 0.2)]
    out = mix(dur, *parts)
    out = room(out, 1.0, 4.0, 5000.0, 0.15, seed=7080 + k)
    return finish(out, 0.86, 0.6)


# =================================================================== les automates de bronze

def servo(dur: float, f0: float, f1: float) -> np.ndarray:
    """Un servomoteur : un bourdonnement qui monte (ou descend), un peu rauque."""
    x = _t(dur)
    ff = np.interp(x, [0, dur], [f0, f1])
    ph = 2 * np.pi * np.cumsum(ff) / SR
    y = np.sin(ph) + 0.5 * np.sin(2 * ph) + 0.3 * np.sign(np.sin(3 * ph)) * 0.3
    return bp(y, 120, 3500) * np.clip(x / 0.02, 0, 1) * np.clip((dur - x) / 0.03, 0, 1)


def bronze(f: float = 410.0, d: float = 0.3) -> np.ndarray:
    return modal([(f, 1.0, d), (f * 2.51, 0.6, d * 0.6), (f * 4.2, 0.4, d * 0.3), (f * 6.46, 0.25, d * 0.2)], d * 3)


def automate_pas(k: int) -> np.ndarray:
    parts = [(unit(servo(0.16, 180.0, 270.0)), 0.0, 0.18),
             (clip_rec(KI + "impactMetal_heavy_00%d.ogg" % [0, 2, 4][k], -5.0, 0.5), 0.16, 0.8),
             (clip_rec(KI + "impactPlate_heavy_00%d.ogg" % [1, 2, 3][k], -3.0, 0.4), 0.16, 0.4),
             (unit(thump(85.0, 50.0, 0.07, 0.35)), 0.16, 0.8), (unit(bronze(RNG.uniform(380, 450))), 0.17, 0.25),
             (s63.ratchet(3, 30.0, 0.8), 0.32, 0.25)]
    if k == 2:
        parts.append((unit(sifflement(0.3, 2500, 9000, 0.01, 0.2)), 0.3, 0.25))
    out = mix(1.05, *parts)
    out = room(out, 0.8, 5.0, 5000.0, 0.1, seed=7082 + k)
    return finish(out, 0.89, 0.2)


def automate_mort(k: int) -> np.ndarray:
    if k == 0:
        dur = 2.9
        parts = [(unit(servo(1.0, 420.0, 60.0)), 0.0, 0.35), (unit(crepite(0.6, 200, 2000, 8000)), 0.0, 0.2),
                 (clip_rec(BFH + "bfh1_metal_falling_01.ogg", -3.0), 0.75, 0.7), (clip_rec(KI + "impactMetal_heavy_001.ogg", -6.0), 0.8, 0.6),
                 (unit(thump(70.0, 40.0, 0.12, 0.5)), 0.8, 0.8), (unit(bronze(330.0, 0.7)), 0.82, 0.3)]
        for i in range(14):
            parts.append((clack(RNG.uniform(2000, 5000), 0.01, 1.0, 0.1), 0.9 + RNG.exponential(0.35), RNG.uniform(0.05, 0.15)))
        parts.append((unit(sifflement(1.4, 2500, 8000, 0.02, 1.0)), 0.85, 0.2))
    else:
        dur = 2.5
        parts = [(unit(servo(0.7, 300.0, 90.0)), 0.0, 0.3), (unit(sifflement(0.6, 2500, 9000, 0.01, 0.4)), 0.05, 0.3),
                 (clip_rec(KI + "impactPlate_heavy_004.ogg", -5.0), 0.65, 0.8), (unit(thump(75.0, 42.0, 0.1, 0.45)), 0.65, 0.8),
                 (clip_rec(WM + "metal_spring_01.ogg", -3.0, 0.8), 0.9, 0.35), (unit(bronze(390.0, 0.5)), 0.66, 0.25),
                 (s63.ratchet(1, 10.0, 0.6), 1.6, 0.3)]
    out = mix(dur, *parts)
    out = room(out, 0.8, 5.0, 5000.0, 0.1, seed=7085 + k)
    return finish(out, 0.89, 0.4)


# =================================================================== Gorgoth, le spectre, le vent du Cocyte

def gorgoth_cri(k: int) -> np.ndarray:
    parts = []
    if k == 0:
        for t in (0.0, 0.2):
            parts.append((unit(thump(95.0, 55.0, 0.05, 0.25)), t, 0.6))
        y = syllabe(1.1, [105.0, 132.0, 150.0, 140.0, 118.0], "o", 0.85, h=0.06, souffle=0.3, rasp=0.04, sub=0.3,
                    sat=1.8, tilt=0.85, voy2="a", att=0.05, rel=0.25)
        parts.append((unit(y), 0.42, 1.0))
        t = 1.55
    elif k == 1:
        t = 0.02
        for f, d in ((140.0, 0.16), (146.0, 0.16), (165.0, 0.55)):
            y = syllabe(d, [f * 1.05, f * 1.12, f * 0.85] if d > 0.3 else [f * 1.06, f * 0.92], "a", 0.86, h=0.035,
                        souffle=0.3, rasp=0.03, sub=0.25, sat=1.6, tilt=0.85, rel=0.05 if d < 0.3 else 0.2)
            parts.append((unit(y), t, 1.0))
            t += d + 0.07
    else:
        g = lp(syllabe(0.4, [92.0, 98.0], "eu", 0.85, h=0.0, souffle=0.2, sat=1.0, att=0.08, rel=0.08), 900)
        parts.append((unit(g), 0.0, 0.5))
        y = syllabe(0.8, [125.0, 158.0, 135.0, 110.0], "a", 0.85, h=0.05, souffle=0.3, rasp=0.05, sub=0.3, sat=2.0,
                    tilt=0.85, att=0.03, rel=0.25)
        parts.append((unit(y), 0.55, 1.0))
        t = 1.35
    parts.append((lp(clip_rec(ARC + "Attack%d.wav" % [3, 5, 7][k], -6.0, 0.8, 0.2), 2500), 0.42 if k == 0 else (0.0 if k == 1 else 0.55), 0.15))
    out = mix(t + 0.8, *parts)
    out = lp(out, 5000)
    out = room(out, 1.4, 3.0, 4000.0, 0.15, seed=7087 + k)
    return finish(out, 0.9, 0.4)


def spectre_givre_cri(k: int) -> np.ndarray:
    d = [1.6, 1.1][k]
    seq = [[380.0, 470.0, 520.0, 430.0, 340.0], [420.0, 520.0, 380.0]][k]
    wail = syllabe(d, seq, "ou", 1.1, h=0.1, souffle=0.8, tilt=1.4, voy2="o", att=0.25, rel=d * 0.4, vib=0.012)
    x = _t(d)
    f3 = np.interp(x, np.linspace(0, d, len(seq)), seq) * 3.0
    glass = np.sin(2 * np.pi * np.cumsum(f3) / SR) * np.sin(np.pi * np.clip(x / d, 0, 1)) ** 1.5
    parts = [(unit(wail), 0.0, 1.0), (unit(glass), 0.05, 0.12),
             (unit(whisper(d, [(0, "ou"), (1.0, "a")], 1.0, lo=300.0, att=0.2, rel=d * 0.4)), 0.0, 0.3),
             (unit(etincelles(d, 10, 3000.0, 8000.0)), 0.1, 0.2)]
    g = clip_bank(VCSL, "Idiophones/Friction Idiophones/Wine Glasses/Sustains/Slow/glass1_D#4_Slow_1_Main.wav", 0.0, d + 0.3, 0.4)
    parts.append((_fade(g, 0.3, 0.4), 0.0, 0.15))
    if k == 1:
        parts.append((craque_glace(0.6, 500, -0.75), d - 0.1, 0.3))
    out = mix(d + 1.6, *parts)
    out = room(out, 2.2, 1.8, 6000.0, 0.35, seed=7090 + k)
    return finish(out, 0.86, 0.8)


def rafale(dur: float, f_peak: float = 1500.0, howl: float = 700.0, crystals: int = 20) -> np.ndarray:
    """Une rafale de vent glacé : le souffle qui enfle et retombe, le hurlement dans les crevasses
    (une résonance étroite qui monte avec la rafale), la poussière de glace, les cristaux."""
    x = _t(dur)
    env = np.interp(x, [0, 0.35 * dur, 0.6 * dur, dur], [0.05, 1.0, 0.7, 0.0]) ** 1.3
    w = amb.noise(len(x), "pink")
    body = sweep(w, 300.0 + (f_peak - 300.0) * env, "lowpass", 2) * env
    hiss = bp(noise(dur), 2000, 6500) * env ** 2 * 0.25
    hw = sweep(noise(dur), howl * (0.8 + 0.5 * env), q=22.0) * env ** 1.5
    rumble = lp(noise(dur), 120) * env * 0.5
    y = unit(body) + unit(hiss) * 0.3 + unit(hw) * 0.35 + unit(rumble) * 0.4
    if crystals:
        y = addp(y, unit(etincelles(dur * 0.8, crystals, 3000.0, 9000.0)) * 0.12)
    return y


def cocyte_vent_coup(k: int) -> np.ndarray:
    d, fpk, hw, cr = [(2.2, 1500.0, 700.0, 18), (2.7, 1900.0, 820.0, 26), (1.8, 1300.0, 600.0, 30)][k]
    out = mix(d + 0.6, (rafale(d, fpk, hw, cr), 0.0, 1.0))
    out = room(out, 1.4, 2.6, 6000.0, 0.15, seed=7092 + k)
    return finish(out, 0.89, 0.5)


# =================================================================== les nappes : la cité

def texture(src: np.ndarray, m: int, seg: float = 2.5, xf: float = 0.6, semis=(-1.0, 1.0)) -> np.ndarray:
    """Une longue texture faite de morceaux d'un enregistrement court, pris au hasard (un peu
    transposés) et enchaînés en fondu : pas de répétition qu'on reconnaîtrait."""
    out = np.zeros(m + int(seg * SR))
    if len(src) < int(seg * SR * 1.2):
        return out[:m]
    L, X = int(seg * SR), int(xf * SR)
    fin = np.sin(np.linspace(0, np.pi / 2, X)) ** 2
    pos = 0
    while pos < m:
        s = s56._shift(src, RNG.uniform(*semis))
        a = int(RNG.integers(0, len(s) - L))
        piece = s[a:a + L].copy()
        piece[:X] *= fin
        piece[-X:] *= fin[::-1]
        out[pos:pos + L] += piece
        pos += L - X
    return out[:m]


def braseros(m: int, gains=(1.0, 0.7), pans=(-0.6, 0.55)) -> np.ndarray:
    """Des braseros qui crépitent : le souffle du feu, les craquements, chacun à sa place."""
    out = np.zeros((m, 2))
    for g, p in zip(gains, pans):
        roar = lp(amb.noise(m, "brown"), 260) * 0.3 * amb.smooth_env(m, 1.2, 0.6, 1.0)
        breath = bp(amb.noise(m, "pink"), 250, 1300) * 0.08 * amb.smooth_env(m, 2.0, 0.4, 1.0)
        cr = np.zeros(m)
        for _ in range(int(m / SR * 11)):
            k = int(RNG.uniform(0.002, 0.01) * SR)
            amb.place(cr, hp(RNG.standard_normal(k), RNG.uniform(1500, 4000)) * np.exp(-np.arange(k) / (k / 3)),
                      int(RNG.integers(0, m - k)), RNG.uniform(0.1, 0.7) ** 2)
        for _ in range(int(m / SR * 0.5)):
            k = int(0.05 * SR)
            amb.place(cr, bp(RNG.standard_normal(k), 500, 2500) * np.exp(-np.arange(k) / (k / 4)), int(RNG.integers(0, m - k)), RNG.uniform(0.3, 0.7))
        y = (roar + breath + lp(cr, 6000) * 0.9) * g
        out[:, 0] += y * np.sqrt(0.5 * (1 - p))
        out[:, 1] += y * np.sqrt(0.5 * (1 + p))
    return out


def charrette(dur: float = 6.0) -> np.ndarray:
    """Une charrette sur les pavés : les roues cerclées de fer qui cognent chaque pavé, la caisse qui
    grince, le chargement qui brinquebale ; elle passe de gauche à droite."""
    n = int(dur * SR)
    y = np.zeros(n)
    for w, off in ((0, 0.0), (1, 0.045)):
        t = off
        while t < dur:
            c = addp(unit(clack(RNG.uniform(650, 1300), 0.02, 0.6, 0.6)), unit(thump(RNG.uniform(120, 150), 90.0, 0.025, 0.1)) * 0.6)
            amb.place(y, c, int(t * SR), RNG.uniform(0.4, 1.0))
            t += 1.0 / 11.0 * RNG.uniform(0.7, 1.3)
    x = np.arange(n) / SR
    y += lp(RNG.standard_normal(n), 180) * 0.25
    y += unit(s59.wood_groan(dur, 9.0)) * 0.12
    rat = np.zeros(n)
    for _ in range(int(dur * 6)):
        amb.place(rat, clack(RNG.uniform(1500, 3000), 0.01, 0.8, 0.2), int(RNG.uniform(0, dur - 0.1) * SR), RNG.uniform(0.1, 0.3))
    y += rat
    g = 1.0 / (1.0 + ((x - dur / 2) / (dur / 4)) ** 2)
    y = lp(y, 4500) * g
    return pan_move(y, -0.85, 0.85)


def forgeron(lib_ok: bool = True) -> np.ndarray:
    """Une forge au loin : une série de coups de marteau sur l'enclume, réguliers."""
    nb = RNG.integers(3, 7)
    step = RNG.uniform(0.45, 0.62)
    out = np.zeros(int((nb * step + 1.5) * SR))
    for i in range(nb):
        a = clip_bank(VCSL, ST + "Anvil/Anvil_Hit%d_v%d_rr1_Mid.wav" % (RNG.integers(1, 4), RNG.integers(2, 4)), RNG.uniform(-1.0, 0.0), 1.2, 0.4)
        if len(a) <= int(0.1 * SR) + 1:
            a = clip_rec(WM + "metal_hit_0%d.ogg" % RNG.choice([1, 3, 5]), -1.0, 1.0, 0.3)
        amb.place(out, a, int(max(0.0, i * step + RNG.uniform(-0.01, 0.01)) * SR), RNG.uniform(0.7, 1.0) * (0.6 if i % 2 else 1.0))
    return lp(out, 3000)


def pas_passant(nb: int = 8, kind: str = "concrete") -> np.ndarray:
    """Quelqu'un qui passe : une suite de pas sur la pierre."""
    step = RNG.uniform(0.46, 0.56)
    out = np.zeros(int((nb * step + 0.5) * SR))
    for i in range(nb):
        c = clip_rec(KI + "footstep_%s_00%d.ogg" % (kind, RNG.integers(0, 5)), RNG.uniform(-3.0, 0.0), 0.3)
        amb.place(out, c, int(i * step * SR), RNG.uniform(0.6, 1.0) * np.sin(np.pi * (i + 0.5) / nb) ** 0.5)
    return lp(out, 4000)


def cri_marchand() -> np.ndarray:
    """Un marchand qui crie sa marchandise (une voix chantante, sans mots)."""
    out = []
    f = RNG.uniform(140, 230)
    for i in range(RNG.integers(2, 4)):
        v = shout(RNG.uniform(0.25, 0.5), f * RNG.uniform(0.95, 1.15), RNG.choice(["a", "o", "è"]), RNG.choice(["é", "o", "a"]),
                  shape="chant", att=0.03, rel=0.12)
        out += [unit(v), np.zeros(int(RNG.uniform(0.05, 0.12) * SR))]
    return lp(np.concatenate(out), 2600)


def cloche_loin(f: float, strokes: int = 3, gap: float = 2.2) -> np.ndarray:
    """Une cloche de la cité qui sonne au loin."""
    one = s56.bronze_bell(f, 6.0, 0.9)
    out = np.zeros(int((strokes * gap + 6.5) * SR))
    for i in range(strokes):
        amb.place(out, one, int(i * gap * SR), 1.0 - 0.1 * i)
    return lp(out, 3000)


def pandemonia_jour_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def bed(m):
        hum = lp(amb.noise(m, "pink"), 450) * 0.25
        crowd = bp(amb.noise(m, "pink"), 250, 1600) * 0.12 * amb.smooth_env(m, 0.3, 0.7, 1.0)
        out = amb.stereo(hum + crowd, np.roll(hum, SR // 2) + np.roll(crowd, SR // 3))
        return out + braseros(m, (0.55, 0.35), (-0.7, 0.6))

    cont = loop_layer(bed, seconds, 3.0)
    town = np.zeros((n, 2))
    s68.voice_walla(lib, town, 16.0, 2000.0, (-5.0, 2.0), (0.1, 0.32))
    scatter(town, [s68.laugh_group(RNG.integers(2, 4), (-5.0, 1.0), 2400.0) for _ in range(4)], 5, (0.15, 0.3))
    scatter(town, [cri_marchand() for _ in range(5)], 6, (0.12, 0.25))
    scatter(town, [pas_passant(RNG.integers(5, 10)) for _ in range(4)], 5, (0.1, 0.22))
    town = room_wrap(town, 1.2, 3.0, 2600.0, 0.25, seed=7101)
    far = np.zeros((n, 2))
    for at in (4.0, 21.0, 37.0, 50.0):
        wplace(far, forgeron(), at * SR, 0.14, RNG.uniform(-0.8, -0.3))
    place_st(far, charrette(6.5), 12.0 * SR, 0.35)
    place_st(far, charrette(5.5)[:, ::-1], 41.0 * SR, 0.28)
    wplace(far, cloche_loin(196.0, 3, 2.0), 26.0 * SR, 0.1, 0.4)
    scatter(far, [unit(s56.pigeon(kk)) for kk in range(2)], 2, (0.05, 0.1))
    for at in (17.0, 46.0):
        w = np.zeros(int(2.5 * SR))
        for i in range(3):
            amb.place(w, unit(wing_beat(1.4)), int(i * 0.62 * SR), 0.8)
        place_st(far, pan_move(lp(w, 3000), -0.5, 0.6), at * SR, 0.18)
    far = room_wrap(far, 2.2, 1.8, 2500.0, 0.4, seed=7102)
    return finish_bed(cont + town + far, 0.7)


def violon_loin(seconds: float = 11.0) -> np.ndarray:
    """Au loin, sur une place, un violon et un accordéon jouent la valse de Pandémonia."""
    import orchestre_v51 as orch
    import compose_musique_v56 as cm56
    out = np.zeros(int((seconds + 2.0) * SR))
    spb = 60.0 / 144.0
    melody = [("A4", 1), ("D5", 1), ("F5", 1), ("A5", 2), ("G5", 0.5), ("F5", 0.5), ("E5", 1), ("G5", 1), ("Bb5", 1),
              ("A5", 1.5), ("G5", 0.5), ("F5", 0.5), ("E5", 0.5), ("D5", 1), ("F5", 1), ("A5", 1), ("C6", 2), ("A5", 1),
              ("Bb5", 1), ("G5", 1), ("E5", 1), ("C#5", 2), ("A4", 1)]
    chords = [["D4", "F4", "A4"]] * 2 + [["D4", "G4", "Bb4"], ["C#4", "E4", "G4"], ["D4", "F4", "A4"], ["C4", "F4", "A4"],
                                         ["D4", "G4", "Bb4"], ["C#4", "E4", "G4"]]
    basses = ["D3", "A2", "Bb2", "A2", "D3", "F2", "G2", "A2"]
    vln = None
    if VSCO.is_dir():
        try:
            vln = orch.Instrument("solo_vln", VSCO, "Strings/Solo Violin/Arco Vib/*.wav", attack=0.08, release=0.5)
        except FileNotFoundError:
            vln = None
    acc = cm56.Accordion("accordeon", pan=0.0, width=0.5, gain=1.0, detune=12.0, bright=0.6)
    t = 0.0
    for p, d in melody:
        m = orch.midi_of(p)
        y = vln.note(m, d * spb * 0.95, 0.5).mean(axis=1) if vln is not None else acc.note(m, d * spb * 0.9, 0.5).mean(axis=1)
        amb.place(out, unit(y) * 0.7, int(t * SR), 1.0)
        t += d * spb
    for b in range(8):
        t0 = b * 3 * spb
        amb.place(out, unit(acc.note(orch.midi_of(basses[b]), spb * 0.8, 0.5).mean(axis=1)) * 0.35, int(t0 * SR), 1.0)
        for beat in (1, 2):
            for p in chords[b]:
                amb.place(out, unit(acc.note(orch.midi_of(p), spb * 0.5, 0.4).mean(axis=1)) * 0.12, int((t0 + beat * spb) * SR), 1.0)
    return lp(out, 2200)


def chouette() -> np.ndarray:
    """Une chouette : « hou… hou-hou-hou »."""
    out = []
    for i, d in enumerate((0.45, 0.16, 0.16, 0.5)):
        m = int(d * SR)
        x = np.arange(m) / SR
        f = np.interp(x, [0, d * 0.2, d], [360.0, 390.0, 340.0]) * (1.0 if i == 0 else 0.97)
        y = np.sin(2 * np.pi * np.cumsum(f) / SR) + bp(RNG.standard_normal(m), 300, 900) * 0.15
        out += [y * np.sin(np.pi * x / d) ** 0.8, np.zeros(int((0.35 if i == 0 else 0.08) * SR))]
    return lp(np.concatenate(out), 1500)


def pandemonia_nuit_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def bed(m):
        air = bp(amb.noise(m, "pink"), 80, 700) * 0.12 * amb.smooth_env(m, 0.15, 0.5, 1.0)
        cr = s59.cricket_dry(m) * 0.004
        out = amb.stereo(air + cr, np.roll(air, SR // 2) + np.roll(cr, SR // 3))
        return out + braseros(m, (1.0, 0.75), (-0.55, 0.65))

    cont = loop_layer(bed, seconds, 3.0)
    town = np.zeros((n, 2))
    s68.voice_walla(lib, town, 2.5, 1700.0, (-5.0, 1.0), (0.08, 0.2))
    scatter(town, [s68.laugh_group(RNG.integers(1, 3), (-5.0, 0.0), 2000.0) for _ in range(2)], 2, (0.1, 0.2))
    scatter(town, [pas_passant(RNG.integers(5, 9)) for _ in range(2)], 2, (0.08, 0.15))
    town = room_wrap(town, 1.4, 2.6, 2400.0, 0.3, seed=7111)
    far = np.zeros((n, 2))
    v = violon_loin()
    wplace(far, v, 6.0 * SR, 0.1, 0.45)
    wplace(far, v, 35.0 * SR, 0.08, 0.3)
    wplace(far, cloche_loin(146.83, 1, 2.0), 22.0 * SR, 0.08, -0.3)
    wplace(far, cloche_loin(146.83, 2, 2.6), 51.0 * SR, 0.065, -0.2)
    wplace(far, chouette(), 15.0 * SR, 0.06, 0.7)
    wplace(far, chouette(), 44.0 * SR, 0.05, -0.75)
    far = room_wrap(far, 2.6, 1.4, 2200.0, 0.5, seed=7112)
    return finish_bed(cont + town + far, 0.7)


# =================================================================== les nappes : le volcan, le port

def champ_lave_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def bed(m):
        rum = amb.lp(amb.noise(m, "brown"), 70, 4) * 1.2 * amb.smooth_env(m, 0.25, 0.5, 1.0)
        flow = lp(amb.noise(m, "pink"), 380) * 0.25 * amb.smooth_env(m, 0.5, 0.6, 1.0)
        heat = bp(amb.noise(m, "pink"), 200, 1200) * 0.06 * amb.smooth_env(m, 0.2, 0.3, 1.0)
        return amb.stereo(rum + flow + heat, np.roll(rum, SR // 3) + np.roll(flow, SR // 2) + np.roll(heat, SR))

    cont = loop_layer(bed, seconds, 3.0)
    ev = np.zeros((n, 2))
    bl = [unit(blorp(RNG.uniform(40, 80), RNG.uniform(110, 220), RNG.uniform(0.15, 0.45), RNG.uniform(0.3, 0.9))) for _ in range(8)]
    scatter(ev, bl, 40, (0.15, 0.45))
    plops = [lp(clip_rec(PLOP + "Viscous %d.wav" % i, -8.0, 0.8, 0.2), 1400) for i in (1, 2, 3, 4, 5)]
    scatter(ev, plops, 10, (0.15, 0.3))
    vents = []
    for _ in range(4):
        d = RNG.uniform(2.0, 5.0)
        vents.append(unit(sifflement(d, RNG.uniform(1200, 2500), RNG.uniform(5000, 9000), 0.3, 1.0, 0.5)))
    for p in (-0.7, 0.75):
        tmp = np.zeros((n, 2))
        scatter(tmp, vents, 5, (0.08, 0.16), pan_r=(p - 0.1, p + 0.1))
        ev += tmp
    scatter(ev, [unit(crepite(RNG.uniform(0.3, 1.0), 120, 1200, 6000)) for _ in range(5)], 20, (0.06, 0.15))
    small = []
    for _ in range(3):
        y = np.zeros(int(1.8 * SR))
        for p, at, g in eclabousse(0.0, 0.9, 7):
            amb.place(y, p, int(at * SR), g)
        amb.place(y, unit(sifflement(1.0, 2500, 8000, 0.05, 0.6)) * 0.3, int(0.05 * SR), 1.0)
        small.append(y)
    scatter(ev, small, 4, (0.15, 0.3))
    far = np.zeros((n, 2))
    booms = [unit(s69.far_rumble(RNG.uniform(3.0, 5.0))) for _ in range(2)]
    scatter(far, booms, 2, (0.35, 0.5), pan_r=(-0.4, 0.4))
    scatter(far, [lp(slow(clip_rec(BFH + "bfh1_rock_falling_0%d.ogg" % i), 1.5), 2200) for i in (2, 5, 8)], 2, (0.08, 0.15))
    ev += room_wrap(far, 2.4, 1.5, 2000.0, 0.45, seed=7121)
    ev = room_wrap(ev, 1.2, 3.0, 3500.0, 0.12, seed=7122)
    return finish_bed(cont + ev, 0.7)


def goeland_braise() -> np.ndarray:
    """Le goéland de braise, l'étrange oiseau de mer de l'île : des « ka-ka-ka » cuivrés, puis un long
    cri qui monte et retombe, avec un tremblement métallique."""
    out = []
    for i in range(RNG.integers(3, 6)):
        out += [unit(squawk(0.1, [1350, 1550, 1300], am=90.0, depth=0.8, sub=0.3, noise_g=0.3, rasp=0.04)),
                np.zeros(int(RNG.uniform(0.06, 0.1) * SR))]
    d = RNG.uniform(0.7, 1.0)
    long = squawk(d, [1500, 2300, 2100, 950], am=120.0, depth=0.5, sub=0.2, noise_g=0.3, tp=[0, 0.25, 0.55, 1.0], rasp=0.03)
    x = np.arange(len(long)) / SR
    long = long * (0.75 + 0.25 * np.sin(2 * np.pi * 620.0 * x))
    out += [unit(long)]
    return lp(np.concatenate(out), 5000)


def voile_claque() -> np.ndarray:
    """Une voile qui claque dans le vent (trois ou quatre battements de toile)."""
    out = np.zeros(int(1.6 * SR))
    for i in range(RNG.integers(3, 5)):
        m = int(0.12 * SR)
        x = np.arange(m) / SR
        y = bp(RNG.standard_normal(m), 200, 2500) * np.exp(-x / 0.03) * np.clip(x / 0.004, 0, 1)
        amb.place(out, y, int(i * RNG.uniform(0.25, 0.35) * SR), RNG.uniform(0.5, 1.0))
    return out


def port_braise_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def water(m):
        out = s56.lapping(m) * 0.9
        sw = amb.lp(amb.noise(m, "brown"), 260) * amb.smooth_env(m, 0.14, 0.6, 1.0) * 0.06
        out[:, 0] += sw
        out[:, 1] += np.roll(sw, SR // 3)
        return out + s59.wind(m, 200, 1600, 0.25, 0.4, 0.8) * 0.06

    cont = loop_layer(water, seconds, 3.0)
    ev = np.zeros((n, 2))
    slaps = []
    for _ in range(6):
        m = int(RNG.uniform(0.25, 0.55) * SR)
        e = bp(RNG.standard_normal(m), 120, 800) * _env(m, 0.02, m / SR * 0.3)
        slaps.append(unit(e))
    scatter(ev, slaps, 14, (0.22, 0.42))
    waves = []
    for _ in range(3):
        d = RNG.uniform(1.5, 2.5)
        x = _t(d)
        y = sweep(noise(d), np.interp(x, [0, 0.25 * d, d], [300.0, 3500.0, 800.0]), "lowpass", 2)
        y *= np.interp(x, [0, 0.25 * d, d], [0.0, 1.0, 0.0]) ** 1.2
        waves.append(unit(y))
    scatter(ev, waves, 3, (0.2, 0.3))
    rock = lambda t: 0.25 + 0.75 * (0.5 + 0.5 * np.sin(2 * np.pi * t / 7.3)) ** 2  # noqa: E731
    scatter(ev, [unit(s59.wood_groan(RNG.uniform(1.2, 3.0), RNG.uniform(14, 30))) for _ in range(8)], 16, (0.25, 0.5), weight=rock)
    scatter(ev, [unit(s68.rope_creak(RNG.uniform(0.35, 0.9))) for _ in range(6)], 12, (0.12, 0.25), weight=rock)
    scatter(ev, [amb.lp(clip_rec(KR + "creak%d.ogg" % i), 2200) for i in (1, 2, 3)], 6, (0.2, 0.4), semis=(-8.0, -3.0), weight=rock)
    scatter(ev, [voile_claque() for _ in range(3)], 3, (0.1, 0.2))
    far = np.zeros((n, 2))
    s68.voice_walla(lib, far, 2.4, 1300.0, (-5.0, 1.0), (0.12, 0.32))
    scatter(far, [cri_marchand() for _ in range(3)], 4, (0.15, 0.3))
    scatter(far, [s68.laugh_group(RNG.integers(2, 4), lp_hz=1800.0) for _ in range(3)], 3, (0.15, 0.28))
    scatter(far, [s68.hammering() for _ in range(3)], 3, (0.25, 0.45))
    wplace(far, s68.ship_bell(987.8), 33.0 * SR, 0.14, 0.5)
    wplace(far, amb.lp(slow(clip_rec(RPG + "chain_02.ogg"), 1.5), 2000), 9.0 * SR, 0.25, -0.5)
    ev += room_wrap(far, 1.8, 2.0, 2200.0, 0.3, seed=7131)
    birds = np.zeros((n, 2))
    scatter(birds, [goeland_braise() for _ in range(3)], 3, (0.06, 0.12))
    ev += room_wrap(birds, 1.4, 2.5, 4000.0, 0.3, seed=7132)
    ev = room_wrap(ev, 1.2, 2.8, 3000.0, 0.12, seed=7133)
    return finish_bed(cont + ev, 0.7)


# =================================================================== les nappes : sous terre, la glace

def neuf_cercles_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def air(m):
        g = amb.smooth_env(m, 0.1, 0.2, 1.0) ** 1.5
        wind = bp(amb.noise(m, "pink"), 50, 380) * (0.35 + g) * 0.8
        w1 = s59.whistle(m, 260.0) * 0.035
        w2 = s59.whistle(m, 405.0) * 0.022
        tt = np.arange(m) / SR
        drone = (np.sin(2 * np.pi * 36.7 * tt) * 0.1 + np.sin(2 * np.pi * 55.0 * tt) * 0.05) * (0.7 + 0.3 * np.sin(2 * np.pi * tt / 13))
        return amb.stereo(wind + w1 + drone, np.roll(wind, SR // 2) + w2 + drone)

    cont = loop_layer(air, seconds, 3.0)
    ev = np.zeros((n, 2))
    scatter(ev, [amb.drip(kk) for kk in range(4)], 20, (0.05, 0.12))
    scatter(ev, [s59.drip() for _ in range(4)], 12, (0.04, 0.09))
    far = np.zeros((n, 2))
    knocks = []
    for _ in range(4):
        y = addp(unit(clack(RNG.uniform(280, 520), 0.05, 0.4, 0.8)), unit(thump(90.0, 60.0, 0.05, 0.3)) * 0.5)
        knocks.append(s69.echoes(np.concatenate([y, np.zeros(SR)]), [(0.35, 0.4), (0.8, 0.22), (1.4, 0.1)], 1200.0))
    scatter(far, knocks, 4, (0.1, 0.18))
    ch = [s69.echoes(amb.lp(clip_rec(RPG + "chain_0%d.ogg" % i), 1500), [(0.4, 0.35), (0.9, 0.15)], 1200.0) for i in (1, 2, 3)]
    scatter(far, ch, 1.5, (0.06, 0.1))
    sighs = [unit(lp(whisper(RNG.uniform(1.5, 2.5), [(0, "ou"), (0.5, "o"), (1.0, "ou")], 0.7, lo=100.0, att=0.5, rel=0.9), 900)) for _ in range(2)]
    scatter(far, sighs, 1.5, (0.1, 0.16))
    scatter(far, [lp(slow(clip_rec(BFH + "bfh1_rock_falling_0%d.ogg" % i), 1.4), 2000) for i in (1, 4, 7)], 2, (0.06, 0.1))
    scatter(far, [unit(s69.far_rumble(RNG.uniform(3.0, 4.5)))], 1, (0.25, 0.35), pan_r=(-0.3, 0.3))
    ev += room_wrap(far, 3.0, 1.2, 2200.0, 0.55, seed=7141)
    ev = room_wrap(ev, 2.6, 1.4, 3000.0, 0.4, seed=7142)
    return finish_bed(cont + ev, 0.6)


def craquement_glace(dur: float) -> np.ndarray:
    """La glace qui gémit sous son propre poids : une friction lente dans des résonances claires."""
    g = s59.wood_groan(dur, RNG.uniform(18, 40))
    return bp(g, 400, 3000) + bp(g, 1200, 2600) * 0.6


def cocyte_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def wind(m):
        gust = amb.smooth_env(m, 0.22, 0.1, 1.0) ** 1.6
        body = bp(amb.noise(m, "pink"), 150, 2200) * (0.25 + gust) * 0.7
        hiss = hp(amb.noise(m, "white"), 3000) * gust ** 2 * 0.05
        h1 = s59.whistle(m, 560.0) * 0.06
        h2 = s59.whistle(m, 880.0) * 0.04
        rum = lp(amb.noise(m, "brown"), 110) * 0.18
        l = body + hiss + h1 + rum
        r = np.roll(body, SR // 2) + np.roll(hiss, SR // 3) + h2 + np.roll(rum, SR // 4)
        return amb.stereo(l, r)

    cont = loop_layer(wind, seconds, 3.0)
    ev = np.zeros((n, 2))
    scatter(ev, [unit(craquement_glace(RNG.uniform(0.8, 2.0))) for _ in range(6)], 8, (0.12, 0.25))
    scatter(ev, [unit(etincelles(RNG.uniform(0.8, 1.6), RNG.integers(5, 12), 3000.0, 9000.0)) for _ in range(5)], 10, (0.05, 0.12))
    far = np.zeros((n, 2))
    scatter(far, [lp(craque_glace(RNG.uniform(0.9, 1.3), int(RNG.integers(500, 1000))), 5000) for _ in range(5)], 5, (0.12, 0.25))
    scatter(far, [addp(unit(thump(40.0, 28.0, 0.3, 1.2)), lp(craque_glace(1.4, 1000), 2500) * 0.6)], 1, (0.25, 0.35))
    ev += room_wrap(far, 2.6, 1.5, 4000.0, 0.45, seed=7151)
    ev = room_wrap(ev, 1.6, 2.2, 6000.0, 0.2, seed=7152)
    return finish_bed(cont + ev, 0.65)


# =================================================================== les nappes : l'Arène, les Thermes

def chant_arene(beats: int = 6) -> np.ndarray:
    """Toute une tribune qui scande « Ho ! Ho ! Ho ! » en tapant des pieds et des mains."""
    out = np.zeros(int((beats * 0.5 + 1.0) * SR))
    for b in range(beats):
        t = b * 0.5
        for _ in range(14):
            v = shout(0.22, RNG.uniform(110, 210), "o", shape="chant", att=0.02, rel=0.1, breath=0.3)
            amb.place(out, unit(v), int(max(0.0, t + RNG.uniform(-0.02, 0.03)) * SR), RNG.uniform(0.06, 0.12))
        amb.place(out, stomp(0.5), int(t * SR), 1.0)
        for p, at, g in claps(10, t + 0.24, t + 0.3, g=(0.05, 0.12)):
            amb.place(out, p, int(at * SR), g)
    return lp(out, 3500)


def vivats(n_voices: int = 18) -> np.ndarray:
    out = np.zeros(int(2.6 * SR))
    for _ in range(n_voices):
        v = shout(RNG.uniform(0.8, 1.6), RNG.uniform(110, 320), "ou", RNG.choice(["è", "a"]), at=RNG.uniform(0.06, 0.14))
        amb.place(out, unit(v), int(RNG.uniform(0, 0.5) * SR), RNG.uniform(0.05, 0.12))
    for p, at, g in claps(40, 0.2, 2.2, dens=0.8):
        amb.place(out, p, int(at * SR), g * 0.8)
    return lp(out, 4000)


def cor_heraut() -> np.ndarray:
    """Le cor des hérauts de l'Arène (cor de VSCO-2 CE), au loin : « tûûû-tû-tûûû »."""
    import orchestre_v51 as orch
    out = np.zeros(int(3.5 * SR))
    try:
        horn = orch.Instrument("horn", VSCO, "Brass/F Horn/sus/*.wav", attack=0.06, release=0.4)
    except (FileNotFoundError, ValueError):
        return out
    t = 0.0
    for p, d in (("Bb3", 0.6), ("F4", 0.25), ("Bb4", 1.2)):
        amb.place(out, horn.note(orch.midi_of(p), d, 0.6).mean(axis=1), int(t * SR), 1.0)
        t += d + 0.06
    return lp(out, 2500)


def arene_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)

    def bed(m):
        roar = bp(amb.noise(m, "pink"), 250, 2200) * 0.35 * amb.smooth_env(m, 0.25, 0.75, 1.0)
        low = lp(amb.noise(m, "brown"), 200) * 0.15
        return amb.stereo(roar + low, np.roll(roar, SR // 2) + np.roll(low, SR // 3))

    cont = loop_layer(bed, seconds, 3.0)
    crowd = np.zeros((n, 2))
    s68.voice_walla(lib, crowd, 30.0, 2400.0, (-5.0, 3.0), (0.08, 0.25))
    scatter(crowd, [vivats(RNG.integers(12, 22)) for _ in range(3)], 3, (0.3, 0.5))
    scatter(crowd, [s68.whistle(kk) for kk in range(3)], 4, (0.05, 0.1))
    scatter(crowd, [cri_marchand() for _ in range(3)], 3, (0.12, 0.2))
    scatter(crowd, [s68.laugh_group(RNG.integers(2, 4)) for _ in range(2)], 3, (0.12, 0.22))
    for at, b in ((14.0, 6), (43.0, 8)):
        wplace(crowd, chant_arene(b), at * SR, 0.55, RNG.uniform(-0.4, 0.4))
    wplace(crowd, cor_heraut(), 29.0 * SR, 0.25, 0.2)
    crowd = room_wrap(crowd, 1.8, 2.2, 2800.0, 0.3, seed=7161)
    return finish_bed(cont + crowd, 0.7)


def soupir_aise() -> np.ndarray:
    """Un baigneur ravi : « Aaaah… »."""
    f = RNG.uniform(105, 170)
    y = syllabe(1.2, [f * 1.1, f, f * 0.82], "a", 0.95, h=0.15, souffle=0.6, voy2="o", att=0.1, rel=0.6)
    return lp(unit(y), 3000)


def thermes_soufre_bed(lib: Path, seconds: float = 60.0) -> np.ndarray:
    n = int(seconds * SR)
    boil = rec("30-cc0-sfx-loops/water_boiling.ogg", -2.0)

    def water(m):
        b = lp(texture(boil, m), 3000) * 0.5
        bub = bulles_eau(m / SR - 0.3, 22)[:m] * 0.3
        bub = np.pad(bub, (0, m - len(bub)))
        steam = bp(amb.noise(m, "white"), 2500, 9000) * 0.03 * amb.smooth_env(m, 0.3, 0.3, 1.0)
        lap = s56.lapping(m) * 0.5
        lap[:, 0] = lp(lap[:, 0], 2000)
        lap[:, 1] = lp(lap[:, 1], 2000)
        return amb.stereo(b + bub + steam, np.roll(b, SR // 2) + np.roll(bub, SR // 3) + np.roll(steam, SR)) + lap

    cont = loop_layer(water, seconds, 3.0)
    ev = np.zeros((n, 2))
    scatter(ev, [unit(blorp(RNG.uniform(90, 140), RNG.uniform(250, 380), RNG.uniform(0.05, 0.12), 0.5)) for _ in range(6)], 12, (0.15, 0.3))
    scatter(ev, [unit(sifflement(RNG.uniform(2.0, 4.0), 2500, 9000, 0.6, 1.2, 0.4)) for _ in range(3)], 4, (0.08, 0.14))
    scatter(ev, [lp(amb.drip(kk), 4500) for kk in range(4)], 14, (0.04, 0.09))
    scatter(ev, [lp(clip_rec(SPL + "splash_0%d.ogg" % i, -3.0, 0.8, 0.2), 3000) for i in (2, 5, 8)], 2, (0.1, 0.2))
    scatter(ev, [soupir_aise() for _ in range(2)], 1, (0.06, 0.1))
    far = np.zeros((n, 2))
    s68.voice_walla(lib, far, 1.5, 1500.0, (-4.0, 1.0), (0.05, 0.12))
    ev += room_wrap(far, 1.6, 2.4, 2000.0, 0.4, seed=7171)
    ev = room_wrap(ev, 1.8, 2.0, 3500.0, 0.35, seed=7172)
    return finish_bed(cont + ev, 0.7)


# =================================================================== lancement

# nom : (fonction, nombre de variantes, numéro de la première) — gargouille_mort et automate_mort
# existent déjà (V54, V63) : on ajoute des variantes après les anciennes, sans y toucher.
SOUNDS = {
    "lave_bulles": (lave_bulles, 3, 1), "lave_gerbe": (lave_gerbe, 2, 1), "feu_souffle": (feu_souffle, 2, 1),
    "demon_rire": (demon_rire, 3, 1), "diablotin_cri": (diablotin_cri, 3, 1), "diablotin_mort": (diablotin_mort, 2, 1),
    "chien_enfer_aboi": (chien_enfer_aboi, 3, 1), "chien_enfer_grogne": (chien_enfer_grogne, 2, 1),
    "chien_enfer_mort": (chien_enfer_mort, 2, 1), "gargouille_cri": (gargouille_cri, 2, 1),
    "gargouille_mort": (gargouille_mort, 1, 3), "ailes_pierre": (ailes_pierre, 2, 1), "ombre_murmure": (ombre_murmure, 3, 1),
    "furie_cri": (furie_cri, 2, 1), "cerbere_aboi": (cerbere_aboi, 2, 1), "cerbere_ronfle": (cerbere_ronfle, 2, 1),
    "charon_rame": (charon_rame, 3, 1), "obole": (obole, 2, 1), "glace_craque": (glace_craque, 3, 1),
    "souffle_givre": (souffle_givre, 2, 1), "titan_rugit": (titan_rugit, 2, 1), "titan_pas": (titan_pas, 3, 1),
    "chaines": (chaines, 3, 1), "grande_porte": (grande_porte, 2, 1), "cloche_cathedrale": (cloche_cathedrale, 2, 1),
    "arene_foule": (arene_foule, 3, 1), "arene_gong": (arene_gong, 2, 1), "artifice_depart": (artifice_depart, 3, 1),
    "artifice_eclat": (artifice_eclat, 3, 1), "lanterne_allume": (lanterne_allume, 2, 1),
    "forge_marteau": (forge_marteau, 3, 1), "geryon_ailes": (geryon_ailes, 2, 1), "contrat_signe": (contrat_signe, 2, 1),
    "bain_soufre": (bain_soufre, 2, 1), "automate_pas": (automate_pas, 3, 1), "automate_mort": (automate_mort, 2, 2),
    "gorgoth_cri": (gorgoth_cri, 3, 1), "spectre_givre_cri": (spectre_givre_cri, 2, 1),
    "cocyte_vent_coup": (cocyte_vent_coup, 3, 1),
}
BEDS = {"pandemonia_jour": pandemonia_jour_bed, "pandemonia_nuit": pandemonia_nuit_bed, "champ_lave": champ_lave_bed,
        "port_braise": port_braise_bed, "neuf_cercles": neuf_cercles_bed, "cocyte": cocyte_bed, "arene": arene_bed,
        "thermes_soufre": thermes_soufre_bed}


def main() -> int:
    global VSCO, VCSL
    if len(sys.argv) > 1 and Path(sys.argv[1]).is_dir():
        s63.LIB = Path(sys.argv[1])
        VSCO = s63.LIB.parent / "VSCO-2-CE"
        VCSL = s63.LIB.parent / "VCSL"
        names = sys.argv[2:]
    else:
        names = sys.argv[1:]
    for name, (fn, count, first) in SOUNDS.items():
        if names and name not in names:
            continue
        xs = []
        for k in range(count):
            reseed(name, k)
            xs.append(fn(k))
        # les variantes d'une même famille sont mises à la même sonie : la plus douce, ou, si la famille
        # a déjà des variantes plus anciennes (qu'on ne touche pas), la plus douce de celles-ci
        old = [loudness(read_raw(fx.OUT / f"{name}_{j}.ogg")) for j in range(1, first) if (fx.OUT / f"{name}_{j}.ogg").is_file()]
        ref = min(old) if old else min(loudness(x) for x in xs)
        for k, x in enumerate(xs):
            y = x * 10 ** ((ref - loudness(x)) / 20.0)
            if np.max(np.abs(y)) > 0.89:
                y = s68.soft_limit(y, 0.89)
            fx.save(f"{name}_{first + k}", y)
            # l'encodage Vorbis peut faire dépasser une crête très raide : on vérifie, et on refait plus bas
            pk = np.max(np.abs(read_raw(fx.OUT / f"{name}_{first + k}.ogg")))
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
