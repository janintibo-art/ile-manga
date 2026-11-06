"""V114 : textures des Strates et de la Fronde (sous Hautefond).

strates/ — panneaux (non raccordables, sans _n) :
    enseigne_gare, _dome, _ligne, _forge, _marmite, _lumieres, _mines, _jardins, _guilde, _train, _pont
        (512 x 256) : les enseignes des Strates (fantastique-vapeur : fer riveté, bois, panneaux peints) ;
    enseigne_fronde, _cantine, _atelier, _troc, _assemblee, _soupapes (512 x 256) : celles de la Fronde
        (panneaux peints à la main, couleurs vives) ;
    banniere_fronde (256 x 512, RGBA) : le A cerclé en engrenage, sur un drap noir et rouge ;
    fresque_1, _2, _3 (1024 x 512) : les fresques de la Fronde, peintes sur la tôle rouillée :
        1. la Colonne et les quatre mondes ; 2. les Soupapes en concert ; 3. la fondation de la Fronde.

Tout est dessiné ici, procéduralement (libre de droits, aucune image tierce), avec les outils des
générateurs V70, V71, V75 et V112. Déterministe.
Lancement depuis la racine du dépôt :
    python3 pcvr/tools/textures_strates_v114.py [enseignes | banniere | fresques | <nom>]
"""
import math
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # pas de __pycache__ dans pcvr/tools

import numpy as np  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_braise_v70 as br  # noqa: E402
import generate_montjoie_v71 as gm  # noqa: E402
import generate_boucan_v75 as bo  # noqa: E402
import generate_hautefond_v112 as hf  # noqa: E402
from generate_soleils_v69 import tn, smooth, mix  # noqa: E402
from generate_braise_v70 import Paint, grain  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "strates"
TAU = math.tau
gm.OUT = OUT


def rng(seed):
    return np.random.default_rng(seed)


# =================================================================== les emblèmes

def em_cristal(pa, cx, cy, s):
    """Une grappe de cristaux bleus qui luisent."""
    pa.glow(cx, cy, 0.7 * s, (90, 160, 255), k=0.5)
    for (dx, h, w, a, c) in ((0.0, 1.0, 0.2, 0, (120, 190, 255)), (-0.28, 0.7, 0.15, -25, (150, 120, 255)), (0.28, 0.75, 0.15, 22, (100, 170, 250)),
                             (-0.12, 0.5, 0.12, -10, (170, 210, 255)), (0.15, 0.55, 0.12, 12, (130, 200, 255))):
        ra = math.radians(a)
        bx, by = cx + dx * s, cy + 0.55 * s
        tx, ty = bx + math.sin(ra) * h * s, by - math.cos(ra) * h * s
        nx, ny = math.cos(ra) * w * s, math.sin(ra) * w * s
        pts = [(bx - nx, by - ny), (tx - nx * 0.9 + (tx - bx) * -0.18, ty - ny * 0.9 + (ty - by) * -0.18), (tx, ty),
               (tx + nx * 0.9 + (tx - bx) * -0.18, ty + ny * 0.9 + (ty - by) * -0.18), (bx + nx, by + ny)]
        pa.poly(pts, c, shade=0.8, depth=3, ol=1.2)
    pa.rect(cx - 0.45 * s, cy + 0.5 * s, cx + 0.45 * s, cy + 0.66 * s, (110, 90, 70), shade=0.6, depth=2, ol=1.0)


def em_champi(pa, cx, cy, s):
    """Trois champignons lumineux (vert, bleu, rose)."""
    for (dx, h, r, c) in ((-0.38, 0.55, 0.26, (120, 255, 170)), (0.32, 0.45, 0.22, (255, 130, 200)), (0.0, 0.85, 0.38, (110, 190, 255))):
        x = cx + dx * s
        pa.glow(x, cy + 0.55 * s - h * s, r * 1.6 * s, c, k=0.35)
        pa.rect(x - 0.05 * s, cy + 0.55 * s - h * s, x + 0.05 * s, cy + 0.62 * s, (230, 226, 210), shade=0.5, depth=2, ol=1.0)
        pa.poly(bo.ellp(x, cy + 0.58 * s - h * s, r * s, r * 0.7 * s, 180, 360, 20) if hasattr(bo, "ellp") else hf.ellp(x, cy + 0.58 * s - h * s, r * s, r * 0.7 * s, 180, 360, 20),
                c, shade=0.7, depth=3, ol=1.2)


def em_loco(pa, cx, cy, s):
    """Une petite locomotive verte à cheminée et sa fumée."""
    pa.rect(cx - 0.6 * s, cy + 0.2 * s, cx + 0.62 * s, cy + 0.32 * s, (40, 36, 34), shade=0.5, depth=2, ol=1.0)
    pa.rect(cx - 0.35 * s, cy - 0.15 * s, cx + 0.5 * s, cy + 0.2 * s, (50, 120, 80), shade=0.8, depth=4, ol=1.2)
    pa.rect(cx - 0.62 * s, cy - 0.4 * s, cx - 0.3 * s, cy + 0.2 * s, (50, 120, 80), shade=0.8, depth=4, ol=1.2)
    pa.rect(cx - 0.7 * s, cy - 0.46 * s, cx - 0.24 * s, cy - 0.38 * s, (30, 30, 30), shade=0.5, depth=2, ol=1.0)
    pa.rect(cx + 0.28 * s, cy - 0.42 * s, cx + 0.4 * s, cy - 0.15 * s, (30, 30, 30), shade=0.5, depth=2, ol=1.0)
    for k in range(3):
        pa.ell(cx + 0.4 * s + k * 0.12 * s, cy - 0.55 * s - k * 0.12 * s, (0.08 + k * 0.04) * s, (0.07 + k * 0.03) * s, (236, 232, 226), shade=0.3, depth=2, ol=0.8)
    for x in (-0.45, -0.05, 0.35):
        pa.ell(cx + x * s, cy + 0.36 * s, 0.13 * s, 0.13 * s, (190, 50, 40), shade=0.6, depth=3, ol=1.0)
    pa.ell(cx + 0.52 * s, cy, 0.06 * s, 0.06 * s, (255, 220, 140), shade=0.3, depth=1, ol=0.8)


def em_pont(pa, cx, cy, s):
    """Un pont de fer en treillis au-dessus d'une faille."""
    pa.poly([(cx - 0.75 * s, cy + 0.65 * s), (cx - 0.75 * s, cy + 0.1 * s), (cx - 0.35 * s, cy + 0.1 * s), (cx - 0.2 * s, cy + 0.65 * s)], (150, 110, 80), shade=0.6, depth=3, ol=1.0)
    pa.poly([(cx + 0.75 * s, cy + 0.65 * s), (cx + 0.75 * s, cy + 0.1 * s), (cx + 0.35 * s, cy + 0.1 * s), (cx + 0.2 * s, cy + 0.65 * s)], (150, 110, 80), shade=0.6, depth=3, ol=1.0)
    pa.rect(cx - 0.6 * s, cy + 0.02 * s, cx + 0.6 * s, cy + 0.1 * s, (50, 46, 46), shade=0.5, depth=2, ol=1.0)
    pa.rect(cx - 0.6 * s, cy - 0.32 * s, cx + 0.6 * s, cy - 0.26 * s, (50, 46, 46), shade=0.5, depth=2, ol=1.0)
    for k in range(6):
        x0 = cx - 0.6 * s + k * 0.2 * s
        pa.line([(x0, cy + 0.06 * s), (x0 + 0.2 * s, cy - 0.29 * s)], (60, 56, 56), 0.035 * s)
        pa.line([(x0, cy - 0.29 * s), (x0 + 0.2 * s, cy + 0.06 * s)], (60, 56, 56), 0.035 * s)
    pa.glow(cx, cy + 0.62 * s, 0.25 * s, (80, 180, 230), k=0.6)


def em_soupape(pa, cx, cy, s):
    """Des tuyaux d'orgue de cuivre qui fument, deux notes de musique."""
    for k in range(7):
        x = cx - 0.6 * s + k * 0.2 * s
        h = 0.5 + 0.45 * math.sin(math.pi * k / 6)
        pa.rect(x - 0.07 * s, cy + 0.6 * s - h * s, x + 0.07 * s, cy + 0.6 * s, (210, 130, 70) if k % 2 else (230, 180, 90), shade=0.8, depth=3, ol=1.0)
        if k % 3 == 1:
            pa.ell(x, cy + 0.5 * s - h * s, 0.1 * s, 0.07 * s, (240, 238, 232), shade=0.3, depth=1, ol=0.6)
    for (nx, ny) in ((0.55, -0.55), (0.75, -0.35)):
        pa.ell(cx + nx * s, cy + ny * s + 0.15 * s, 0.07 * s, 0.055 * s, (250, 80, 120), shade=0.4, depth=2, ol=0.8)
        pa.line([(cx + nx * s + 0.065 * s, cy + ny * s + 0.15 * s), (cx + nx * s + 0.065 * s, cy + ny * s - 0.15 * s)], (250, 80, 120), 0.025 * s)


def em_marmite(pa, cx, cy, s):
    """Une grosse marmite noire, sa vapeur, une louche."""
    pa.poly(hf.ellp(cx, cy + 0.05 * s, 0.6 * s, 0.55 * s, 0, 180, 30), (52, 50, 52), shade=0.8, depth=5, ol=1.4)
    pa.ell(cx, cy + 0.05 * s, 0.6 * s, 0.13 * s, (200, 140, 70), shade=0.4, depth=2, ol=1.2)
    for k in (-1, 0, 1):
        x = cx + k * 0.25 * s
        pa.line([(x + math.sin(t * 5) * 0.06 * s, cy - 0.05 * s - t * 0.6 * s) for t in np.linspace(0, 1, 14)], (240, 236, 228), 0.06 * s)
    pa.line([(cx + 0.35 * s, cy - 0.1 * s), (cx + 0.7 * s, cy - 0.6 * s)], (150, 110, 60), 0.05 * s)


def em_lanterne(pa, cx, cy, s):
    """Une lanterne de fer et son cristal bleu allumé."""
    pa.glow(cx, cy + 0.05 * s, 0.6 * s, (110, 180, 255), k=0.6)
    pa.rect(cx - 0.28 * s, cy - 0.35 * s, cx + 0.28 * s, cy + 0.45 * s, (180, 220, 255), shade=0.3, depth=2, ol=1.6)
    pa.poly([(cx - 0.36 * s, cy - 0.35 * s), (cx, cy - 0.65 * s), (cx + 0.36 * s, cy - 0.35 * s)], (40, 40, 44), shade=0.6, depth=3, ol=1.2)
    pa.rect(cx - 0.34 * s, cy + 0.45 * s, cx + 0.34 * s, cy + 0.55 * s, (40, 40, 44), shade=0.6, depth=2, ol=1.0)
    em_cristal(pa, cx, cy + 0.05 * s, 0.32 * s)
    pa.ell(cx, cy - 0.74 * s, 0.07 * s, 0.07 * s, (40, 40, 44), shade=0.5, depth=1, ol=1.0)


def em_pioche(pa, cx, cy, s):
    """Une pioche et une lampe de mineur."""
    pa.line([(cx - 0.55 * s, cy + 0.55 * s), (cx + 0.35 * s, cy - 0.35 * s)], (140, 96, 60), 0.09 * s)
    pa.poly([(cx + 0.05 * s, cy - 0.65 * s), (cx + 0.7 * s, cy - 0.05 * s), (cx + 0.6 * s, cy + 0.02 * s), (cx + 0.32 * s, cy - 0.28 * s), (cx + 0.1 * s, cy - 0.3 * s), (cx - 0.02 * s, cy - 0.55 * s)],
            (120, 124, 130), shade=0.8, depth=3, ol=1.2)
    pa.glow(cx - 0.35 * s, cy - 0.25 * s, 0.3 * s, (255, 210, 120), k=0.6)
    pa.ell(cx - 0.35 * s, cy - 0.25 * s, 0.13 * s, 0.13 * s, (255, 226, 150), shade=0.3, depth=2, ol=1.0)


def em_fronde(pa, cx, cy, s, col=(230, 60, 50)):
    """Le A cerclé de la Fronde : le cercle est un engrenage."""
    n = 14
    pts = []
    for k in range(n * 4):
        a = k / (n * 4) * TAU
        r = 0.66 if (k % 4) in (0, 1) else 0.56
        pts.append((cx + math.cos(a) * r * s, cy + math.sin(a) * r * s))
    pa.poly(pts, col, shade=0.7, depth=4, ol=1.4)
    pa.ell(cx, cy, 0.46 * s, 0.46 * s, (24, 22, 24), shade=0.4, depth=2, ol=1.0)
    pa.poly([(cx - 0.42 * s, cy + 0.5 * s), (cx, cy - 0.62 * s), (cx + 0.42 * s, cy + 0.5 * s), (cx + 0.26 * s, cy + 0.5 * s), (cx, cy - 0.22 * s), (cx - 0.26 * s, cy + 0.5 * s)],
            (245, 236, 210), shade=0.5, depth=3, ol=1.4)
    pa.rect(cx - 0.62 * s, cy + 0.06 * s, cx + 0.62 * s, cy + 0.18 * s, (245, 236, 210), shade=0.5, depth=3, ol=1.4)


def em_mains(pa, cx, cy, s):
    """Deux flèches qui se croisent : on donne, on échange."""
    for sg in (-1, 1):
        y = cy + sg * 0.2 * s
        pa.poly([(cx - 0.6 * s * sg, y - 0.08 * s), (cx + 0.35 * s * sg, y - 0.08 * s), (cx + 0.35 * s * sg, y - 0.2 * s), (cx + 0.65 * s * sg, y),
                 (cx + 0.35 * s * sg, y + 0.2 * s), (cx + 0.35 * s * sg, y + 0.08 * s), (cx - 0.6 * s * sg, y + 0.08 * s)],
                (90, 200, 160) if sg > 0 else (250, 180, 60), shade=0.7, depth=3, ol=1.2)


def em_cle(pa, cx, cy, s):
    """Une clé à molette et un engrenage."""
    br.em_engrenage(pa, cx + 0.3 * s, cy - 0.2 * s, 0.6 * s)
    pa.line([(cx - 0.6 * s, cy + 0.6 * s), (cx + 0.05 * s, cy - 0.05 * s)], (150, 156, 164), 0.12 * s)
    pa.ell(cx + 0.1 * s, cy - 0.1 * s, 0.18 * s, 0.18 * s, (150, 156, 164), shade=0.7, depth=3, ol=1.2)
    pa.ell(cx + 0.18 * s, cy - 0.18 * s, 0.08 * s, 0.08 * s, (40, 36, 38), shade=0.3, depth=1, ol=0.8)


def em_cercle(pa, cx, cy, s):
    """Un cercle de canapés autour d'un brasero."""
    pa.glow(cx, cy, 0.4 * s, (255, 140, 60), k=0.7)
    pa.ell(cx, cy, 0.14 * s, 0.14 * s, (255, 150, 60), shade=0.3, depth=2, ol=1.0)
    for k in range(6):
        a = k / 6 * TAU
        x, y = cx + math.cos(a) * 0.5 * s, cy + math.sin(a) * 0.42 * s
        pa.ell(x, y, 0.15 * s, 0.1 * s, [(200, 60, 60), (60, 140, 90), (60, 90, 190), (220, 170, 50), (200, 60, 60), (130, 70, 170)][k], shade=0.7, depth=3, ol=1.0)


gm.EMBLEMS.update({"colonne": hf.em_colonne, "horloge": hf.em_horloge, "tasse": hf.em_tasse, "enclume": br.em_enclume, "vapeur": br.em_vapeur,
                   "livres": br.em_livres, "engrenage": br.em_engrenage, "cristal": em_cristal, "champi": em_champi, "loco": em_loco,
                   "pont": em_pont, "soupape": em_soupape, "marmite": em_marmite, "lanterne": em_lanterne, "pioche": em_pioche,
                   "fronde": em_fronde, "mains": em_mains, "cle": em_cle, "cercle": em_cercle, "blason": hf.em_blason})

ENSEIGNES = {
    "gare": ("Gare des Strates", "Ligne des Strates · Hautefond", "fer", (40, 46, 60), "or", "colonne"),
    "ligne": ("Ligne des Strates", "Cent mètres sous la ville · Ça descend !", "fer", (36, 46, 70), "or", "colonne"),
    "dome": ("Ligne du Dôme d'Azur", "Fermée pour travaux", "fer", (24, 56, 80), "creme", "colonne"),
    "forge": ("Grande Forge des Strates", "Maîtresse Brunehaut · On tape fort", "fer", (56, 44, 40), "laiton", "enclume"),
    "marmite": ("La Marmite", "Cantine des Strates · Soupes & chocolat", "bois", (96, 50, 30), "or", "marmite"),
    "lumieres": ("Atelier des Lumières", "Lanternes à cristal · Docteure Quartz", "peint", (30, 44, 74), "or", "lanterne"),
    "mines": ("Mines de Cristaux", "Casque obligatoire · Ludovic Grisou", "bois", (70, 50, 34), "creme", "pioche"),
    "jardins": ("Jardins des Champignons", "Ne pas cueillir · Bertille veille", "peint", (30, 60, 52), "creme", "champi"),
    "guilde": ("Maison de la Guilde", "Les Strates · Par la roche !", "peint", (60, 36, 30), "or", "blason"),
    "train": ("Le Petit Train", "Tour des Strates · Toutes les dix minutes", "peint", (40, 70, 50), "or", "loco"),
    "pont": ("Pont des Frondeurs", "Vers la Fronde · Ne vous penchez pas", "fer", (50, 42, 40), "creme", "pont"),
    "fronde": ("La Fronde", "Quartier libre · Bienvenue d'en haut !", "peint", (22, 20, 24), "creme", "fronde"),
    "cantine": ("Cantine Libre", "Prix libre · Mémé Gamelle", "peint", (150, 60, 30), "creme", "marmite"),
    "atelier": ("Atelier Libre", "On répare tout · Ensemble", "peint", (30, 70, 110), "creme", "cle"),
    "troc": ("Le Troc", "On donne, on échange · Lumi", "peint", (110, 40, 90), "creme", "mains"),
    "assemblee": ("L'Assemblée", "Ici, tout se décide ensemble", "peint", (40, 40, 44), "creme", "cercle"),
    "soupapes": ("Les Soupapes", "Tous les soirs · 20 h - 23 h", "peint", (24, 22, 26), "creme", "soupape"),
}


def enseignes():
    gm.ENSEIGNES.clear()
    gm.ENSEIGNES.update(ENSEIGNES)
    for k in ENSEIGNES:
        gm.enseigne(k)


# =================================================================== la bannière de la Fronde

def banniere_fronde():
    W, H = 256, 512
    R = rng(11440)
    pa = Paint(W, H, 2, bg=(20, 18, 20), seed=11440)
    x0, x1, y0, yt, yn = 18, 238, 10, 500, 430
    shape = [(x0, y0), (x1, y0), (x1, yt), (128, yn), (x0, yt)]
    yy, xx = np.mgrid[0:pa.h, 0:pa.w].astype(np.float32) / pa.K
    big = max(pa.w, pa.h)
    weave = 0.93 + 0.07 * (np.sin(xx * 3.1) * np.sin(yy * 3.1) * 0.5 + 0.5)
    base = np.array((0.08, 0.075, 0.08), np.float32) * weave[..., None] * (0.85 + 0.3 * tn(R, big, (8, 16, 32, 64), 0.6)[:pa.h, :pa.w, None])
    pa.rgb = base.astype(np.float32)
    # une large bande rouge en biais, le A cerclé en engrenage, le nom
    pa.poly([(x0, 300), (x1, 210), (x1, 280), (x0, 370)], (190, 40, 36), shade=0.4, depth=2, ol=0.0, alpha=0.95)
    em_fronde(pa, 128, 236, 150, col=(220, 60, 50))
    pa.text((128, 70), "LA FRONDE", 30, (245, 236, 210), stroke=1.6, stroke_col=(20, 16, 16), spacing=1.5, shade=0.3)
    pa.text((128, 400), "fait main · fait en bas", 15, (230, 200, 120), italic=True, stroke=0.8, stroke_col=(20, 16, 16))
    folds = 1 + 0.13 * np.sin(xx / 64 * TAU + 0.6) + 0.06 * np.sin(xx / 23 * TAU + 1.3)
    pa.rgb = pa.rgb * folds[..., None]
    rgb, _ = pa.result()
    am = Image.new("L", (W * 4, H * 4), 0)
    ImageDraw.Draw(am).polygon([(x * 4, y * 4) for x, y in shape], fill=255)
    alpha = np.asarray(am.resize((W, H), Image.LANCZOS), np.float32) / 255.0
    gm.save_rgba(np.dstack([rgb, alpha]), "banniere_fronde.png")


# =================================================================== les fresques (1024 x 512, sur la tôle)

FW, FH = 1024, 512


def metal_finish(pa, R, name):
    """Pose la fresque sur une grande tôle rouillée rivetée : la rouille se voit à travers la peinture,
    les joints des tôles, les rivets, des écailles, des coulures."""
    W, H = FW, FH
    rgb = bo.down(np.clip(pa.rgb, 0, 1), pa.K * pa.W // W)
    cov = bo.down(pa.cov, pa.K * pa.W // W)
    big = max(W, H)
    n1 = tn(R, big, (16, 32, 64, 128, 256), 0.6)[:H, :W]
    n2 = tn(R, big, (4, 8, 16, 32), 0.6)[:H, :W]
    rust = np.array((0.42, 0.24, 0.14), np.float32)
    steel = np.array((0.36, 0.36, 0.38), np.float32)
    rmask = smooth(0.35, 0.7, n1)
    plate = mix(np.broadcast_to(steel, (H, W, 3)) * (0.8 + 0.3 * n2[..., None]), np.broadcast_to(rust, (H, W, 3)) * (0.75 + 0.5 * n2[..., None]), rmask)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    seams = np.zeros((H, W), np.float32)
    for x in (256, 512, 768):
        seams = np.maximum(seams, np.exp(-((xx - x) / 1.5) ** 2))
    plate = plate * (1 - 0.5 * seams[..., None])
    gr = grain(R, big, 0.6)[:H, :W]
    paint = rgb * (0.92 + 0.12 * gr[..., None]) * (0.95 + 0.08 * n2[..., None])
    keep, pedge = bo.peel_mask(R, W, 0.985, H=H, scale=(16, 32, 64, 128), sharp=0.02)
    a = np.clip(cov, 0, 1) * keep * (1 - 0.35 * rmask * smooth(0.6, 0.9, n2))
    col = plate * (1 - a[..., None]) + paint * a[..., None]
    col = col * (1 - 0.2 * pedge[..., None] * (1 - keep[..., None]))
    # les rivets, le long des joints et des bords
    im = Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8))
    d = ImageDraw.Draw(im)
    for x in (6, 256, 512, 768, W - 6):
        for y in range(14, H, 34):
            d.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(70, 62, 58))
            d.ellipse([x - 2, y - 3, x + 1, y], fill=(150, 140, 130))
    col = np.asarray(im, np.float32) / 255.0
    drip = smooth(0.6, 0.9, bo.vstreak(R, W, (16, 32, 64, 128), 0.6, 6, H=H))
    col = col * (1 - 0.15 * drip[..., None])
    gm.save_rgb(col, name)


def fresque_1():
    """La Colonne et les quatre mondes : les Nuées tout en haut, Hautefond, les Strates en couches de
    couleur, le Dôme d'Azur au fond de la mer ; la Colonne les traverse tous ; deux Frondeurs dansent."""
    R = rng(11451)
    pa = Paint(FW, FH, K=2, bg=(0, 0, 0), seed=11451)
    # le ciel (en haut), les couches des Strates, la mer (en bas)
    pa.rect(20, 20, 1004, 140, (110, 170, 230), grad=((150, 200, 245), (90, 150, 220), 90), shade=0.0, depth=0, ol=1.6)
    bands = [(214, 160, 100), (230, 210, 170), (170, 100, 70), (160, 150, 140), (200, 150, 130), (214, 160, 100)]
    for k, c in enumerate(bands):
        y0 = 210 + k * 32
        pa.poly([(20, y0), (1004, y0 - 10 + (k % 2) * 20), (1004, y0 + 34), (20, y0 + 32)], c, shade=0.3, depth=2, ol=1.0)
    pa.rect(20, 400, 1004, 492, (30, 90, 140), grad=((40, 110, 160), (14, 50, 90), 90), shade=0.0, depth=0, ol=1.6)
    # Hautefond (une butte, des toits) entre le ciel et les Strates
    pa.poly([(20, 210), (200, 175), (380, 150), (512, 140), (644, 150), (824, 175), (1004, 210)], (190, 160, 110), shade=0.5, depth=3, ol=1.4)
    for k in range(18):
        x = 120 + k * 45 + (k % 3) * 6
        y = 196 - 50 * math.sin(math.pi * (x - 20) / 984)
        pa.rect(x - 14, y - 16, x + 14, y + 4, (230, 210, 170), shade=0.5, depth=2, ol=1.0)
        pa.poly([(x - 17, y - 16), (x, y - 30), (x + 17, y - 16)], (70, 90, 130), shade=0.5, depth=2, ol=1.0)
    # la Cité des Nuées (une île flottante blanche) et ses nuages
    pa.poly([(400, 70), (624, 70), (580, 110), (512, 128), (444, 110)], (140, 120, 110), shade=0.6, depth=3, ol=1.2)
    pa.rect(410, 50, 614, 70, (245, 245, 240), shade=0.4, depth=2, ol=1.0)
    for k in range(7):
        pa.ell(120 + k * 130, 115 + (k % 2) * 12, 50, 18, (245, 245, 250), shade=0.2, depth=2, ol=0.8, alpha=0.9)
    # le Dôme d'Azur, au fond de la mer, des poissons qui luisent
    pa.poly(hf.ellp(512, 488, 120, 70, 180, 360, 30), (150, 220, 240), shade=0.3, depth=2, ol=1.4, alpha=0.7)
    for k in range(9):
        x, y = 200 + k * 80, 430 + (k % 3) * 14
        pa.glow(x, y, 14, (120, 230, 255), k=0.5)
        pa.ell(x, y, 10, 5, (180, 250, 255), shade=0.3, depth=1, ol=0.6)
    # la Colonne : elle traverse tout
    pa.rect(497, 40, 527, 470, (230, 186, 90), grad=((255, 220, 130), (180, 124, 40), 0), shade=0.7, depth=4, ol=1.6)
    for y in range(60, 470, 34):
        pa.rect(492, y, 532, y + 6, (150, 100, 40), shade=0.5, depth=2, ol=0.8)
    # le Soleil de Laiton, dans les Strates
    pa.glow(512, 300, 60, (255, 210, 130), k=0.8)
    pa.ell(512, 300, 34, 34, (255, 226, 150), shade=0.3, depth=3, ol=1.4)
    for k in range(12):
        a = k / 12 * TAU
        pa.line([(512 + math.cos(a) * 44, 300 + math.sin(a) * 44), (512 + math.cos(a) * 60, 300 + math.sin(a) * 60)], (255, 220, 140), 3)
    # deux Frondeurs qui dansent (des silhouettes à crête), des notes
    for (x, c) in ((200, (230, 70, 60)), (820, (80, 200, 120))):
        pa.ell(x, 286, 12, 12, (40, 32, 30), shade=0.4, depth=2, ol=1.0)
        pa.poly([(x - 4, 274), (x, 250), (x + 4, 274)], c, shade=0.5, depth=2, ol=0.8)
        pa.line([(x, 298), (x, 340)], (40, 32, 30), 9)
        pa.line([(x, 310), (x - 26, 290)], (40, 32, 30), 6)
        pa.line([(x, 310), (x + 26, 292)], (40, 32, 30), 6)
        pa.line([(x, 340), (x - 16, 372)], (40, 32, 30), 7)
        pa.line([(x, 340), (x + 18, 370)], (40, 32, 30), 7)
    pa.text((512, 24 + 6), "UNE TOUR · QUATRE MONDES", 26, (255, 236, 200), stroke=2.0, stroke_col=(30, 20, 20), spacing=2.0, anchor="mt")
    metal_finish(pa, R, "fresque_1.png")


def fresque_2():
    """Les Soupapes en concert : la batterie, la chanteuse à la guitare, le bassiste, l'orgue à vapeur
    qui fume derrière, des projecteurs et des notes partout."""
    R = rng(11452)
    pa = Paint(FW, FH, K=2, bg=(0, 0, 0), seed=11452)
    pa.rect(20, 20, 1004, 492, (40, 20, 60), grad=((70, 30, 90), (20, 10, 30), 90), shade=0.0, depth=0, ol=1.6)
    # les faisceaux des projecteurs
    for (x, c) in ((200, (255, 80, 80)), (512, (90, 140, 255)), (824, (255, 200, 80))):
        pa.poly([(x - 10, 20), (x + 10, 20), (x + 190, 470), (x - 190, 470)], c, shade=0.0, depth=0, ol=0.0, alpha=0.22)
    # l'orgue à vapeur (des tuyaux de cuivre) et sa vapeur
    for k in range(17):
        x = 210 + k * 38
        h = 120 + 120 * math.sin(math.pi * k / 16)
        pa.rect(x - 12, 330 - h, x + 12, 330, (220, 140, 80) if k % 2 else (240, 190, 100), shade=0.8, depth=3, ol=1.2)
        if k % 3 == 0:
            for j in range(3):
                pa.ell(x + j * 8, 320 - h - j * 22, 16 + j * 6, 10 + j * 4, (240, 236, 230), shade=0.2, depth=1, ol=0.6, alpha=0.8)
    # la scène
    pa.rect(20, 400, 1004, 492, (60, 44, 34), shade=0.5, depth=3, ol=1.4)
    # les trois musiciens (des silhouettes vives, crêtes de couleur)
    def figure(x, crest, inst):
        pa.ell(x, 290, 22, 24, (240, 200, 170), shade=0.5, depth=3, ol=1.4)
        pa.poly([(x - 8, 268), (x, 222), (x + 8, 268)], crest, shade=0.5, depth=2, ol=1.0)
        pa.poly([(x - 34, 320), (x + 34, 320), (x + 28, 400), (x - 28, 400)], (30, 30, 34), shade=0.6, depth=3, ol=1.4)
        if inst == "guitare":
            pa.poly(hf.ellp(x + 10, 360, 34, 22, 0, 360, 24), (200, 60, 40), shade=0.7, depth=3, ol=1.2)
            pa.line([(x + 30, 350), (x + 110, 300)], (90, 60, 40), 8)
        elif inst == "basse":
            pa.poly(hf.ellp(x - 6, 362, 30, 20, 0, 360, 24), (60, 120, 200), shade=0.7, depth=3, ol=1.2)
            pa.line([(x - 26, 352), (x - 120, 290)], (90, 60, 40), 8)
    figure(300, (240, 70, 60), "guitare")
    figure(724, (70, 200, 120), "basse")
    # la batterie au milieu
    pa.ell(512, 380, 60, 48, (230, 230, 220), shade=0.6, depth=4, ol=1.4)
    pa.ell(512, 380, 26, 22, (200, 40, 40), shade=0.4, depth=2, ol=1.0)
    for (dx, dy) in ((-80, 340), (80, 340)):
        pa.ell(512 + dx, dy, 30, 10, (230, 190, 90), shade=0.5, depth=2, ol=1.0)
    pa.ell(512, 300, 20, 22, (240, 200, 170), shade=0.5, depth=3, ol=1.4)
    pa.poly([(504, 280), (512, 238), (520, 280)], (250, 140, 40), shade=0.5, depth=2, ol=1.0)
    # des notes
    for k in range(10):
        x, y = 90 + k * 95, 90 + (k % 3) * 40
        c = [(255, 90, 120), (120, 220, 255), (255, 220, 90)][k % 3]
        pa.ell(x, y + 20, 13, 10, c, shade=0.4, depth=2, ol=1.0)
        pa.line([(x + 12, y + 20), (x + 12, y - 20)], c, 4)
    pa.text((512, 470), "LES SOUPAPES", 54, (255, 236, 200), stroke=2.4, stroke_col=(30, 10, 20), spacing=3.0, shade=0.3)
    metal_finish(pa, R, "fresque_2.png")


def fresque_3():
    """La fondation de la Fronde : la brouette et son feu, les premiers frondeurs, les planches du Pont,
    les mots « Fait main, fait en bas »."""
    R = rng(11453)
    pa = Paint(FW, FH, K=2, bg=(0, 0, 0), seed=11453)
    pa.rect(20, 20, 1004, 492, (230, 200, 150), grad=((240, 214, 170), (200, 160, 110), 90), shade=0.0, depth=0, ol=1.6)
    # la caverne (des arcs de couleur), le Gouffre et le Pont
    for k in range(5):
        pa.poly(hf.ellp(512, 492, 470 - k * 40, 440 - k * 40, 180, 360, 40), [(170, 100, 70), (214, 160, 100), (160, 150, 140), (200, 150, 130), (230, 210, 170)][k], shade=0.3, depth=2, ol=1.0)
    pa.rect(690, 380, 760, 492, (20, 30, 40), shade=0.4, depth=2, ol=1.2)
    pa.glow(725, 480, 40, (80, 180, 230), k=0.6)
    pa.rect(650, 372, 800, 384, (90, 70, 50), shade=0.5, depth=2, ol=1.0)
    for k in range(5):
        x = 660 + k * 32
        pa.line([(x, 384), (x + 16, 356)], (60, 56, 56), 4)
        pa.line([(x + 16, 356), (x + 32, 384)], (60, 56, 56), 4)
    # la brouette et son feu
    pa.poly([(260, 380), (400, 380), (380, 420), (280, 420)], (120, 110, 100), shade=0.7, depth=3, ol=1.4)
    pa.ell(300, 432, 16, 16, (60, 50, 44), shade=0.5, depth=2, ol=1.0)
    pa.line([(400, 382), (460, 360)], (120, 90, 60), 8)
    pa.glow(330, 350, 70, (255, 150, 60), k=0.9)
    for k in range(5):
        x = 290 + k * 18
        pa.poly([(x - 14, 382), (x, 330 - (k % 2) * 20), (x + 14, 382)], (255, 170 - k * 15, 60), shade=0.2, depth=1, ol=0.8)
    # les premiers frondeurs autour du feu (des silhouettes)
    for (x, c) in ((170, (230, 70, 60)), (480, (90, 140, 255)), (560, (250, 190, 60))):
        pa.ell(x, 316, 16, 18, (60, 44, 38), shade=0.4, depth=2, ol=1.0)
        pa.poly([(x - 5, 300), (x, 274), (x + 5, 300)], c, shade=0.5, depth=2, ol=0.8)
        pa.poly([(x - 24, 336), (x + 24, 336), (x + 18, 400), (x - 18, 400)], (60, 44, 38), shade=0.5, depth=2, ol=1.0)
    em_fronde(pa, 840, 170, 110, col=(210, 60, 50))
    pa.text((360, 120), "FAIT MAIN", 64, (180, 40, 36), stroke=2.4, stroke_col=(40, 20, 20), spacing=2.0, shade=0.3)
    pa.text((360, 200), "FAIT EN BAS", 64, (40, 60, 120), stroke=2.4, stroke_col=(20, 20, 40), spacing=2.0, shade=0.3)
    metal_finish(pa, R, "fresque_3.png")


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else ""
    OUT.mkdir(parents=True, exist_ok=True)
    if arg in ("", "enseignes"):
        enseignes()
    elif arg in ENSEIGNES:
        gm.ENSEIGNES.clear()
        gm.ENSEIGNES.update(ENSEIGNES)
        gm.enseigne(arg)
    if arg in ("", "banniere"):
        banniere_fronde()
    if arg in ("", "fresques"):
        fresque_1()
        fresque_2()
        fresque_3()
    if arg.startswith("fresque_"):
        globals()[arg]()


if __name__ == "__main__":
    main()
