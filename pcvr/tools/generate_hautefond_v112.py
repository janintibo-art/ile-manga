"""V112 : textures de Hautefond, la cité-colonne (fantastique-vapeur : pierre blonde, ardoise bleue,
laiton et cuivre).

hautefond/ — surfaces 1024 px raccordables, chacune avec sa carte de relief <nom>_n.png
          (une tuile couvre environ 3 m x 3 m) :
          pierre_blonde (+_n) : pierre de taille calcaire blond miel en assises réglées (35 à 45 cm),
                                blocs de 70 cm à 1,4 m, joints fins de chaux claire, layures du
                                taillage, arêtes épaufrées, traînées de pluie grises, lichens rares ;
          ardoise_hf (+_n)    : toit d'ardoises rectangulaires bleu-gris posées au crochet, rangs
                                décalés d'une demi-ardoise, crochets de cuivre, reflets ;
          pave_blond (+_n)    : grandes dalles de calcaire blond, usées, joints fins (les places).
          — panneaux (non raccordables, sans _n) :
          enseigne_liftiers, _piston, _horloger, _forge_vapeur, _epices, _bibliotheque,
          _observatoire, _mairie (512 x 256) : enseignes des boutiques et des grands lieux ;
          banniere_hautefond (256 x 512, RGBA) : la Colonne d'or et sa lanterne sur un drap bleu nuit.

Tout est dessiné ici, procéduralement (libre de droits, aucune image tierce), avec les outils des
générateurs V69, V70 et V71. Déterministe.
Lancement depuis la racine du dépôt :
    python3 pcvr/tools/generate_hautefond_v112.py [surfaces | enseignes | banniere | <nom>]
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
from generate_soleils_v69 import (tn, smooth, mix, C, bake, per_id, masonry, speck, ellp, bez)  # noqa: E402
from generate_braise_v70 import (grain, hshadow, roof_rows, Paint)  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "hautefond"
TAU = math.tau
gm.OUT = OUT


def rng(seed):
    return np.random.default_rng(seed)


# =================================================================== surfaces

def pierre_blonde():
    S = 1024
    R = rng(11201)
    rows = [118, 132, 124, 136, 120, 130, 126, 138]
    bid, e, u, v = masonry(R, S, rows, 240, 480, rr=2.5)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    chip = tn(R, S, (16, 32, 64, 128), 0.7)
    gr = grain(R, S, 0.6)
    e2 = e - 1.6 - np.clip(chip - 0.66, 0, 1) * 30.0
    tone = per_id(bid, R, 0.9, 1.1)
    hue = per_id(bid, R, 0.0, 1.0)
    tilt = per_id(bid, R, -0.03, 0.03)
    stone = mix(C(0.74, 0.64, 0.47), C(0.82, 0.73, 0.56), hue) * tone[..., None]
    stone = mix(stone, C(0.7, 0.66, 0.58) * tone[..., None], smooth(0.75, 0.95, per_id(bid, R, 0, 1))[..., None] * 0.6)
    stone = stone * (0.9 + 0.18 * mot[..., None]) * (0.92 + 0.14 * fine[..., None]) * (0.95 + 0.08 * gr[..., None])
    ta = per_id(bid, R, 0.7, 1.2) * np.where(per_id(bid, R, 0, 1) < 0.5, 1, -1)
    tool = np.sin((xx * np.cos(ta) + yy * np.sin(ta)) / per_id(bid, R, 4.0, 6.0) * TAU)
    toolm = smooth(4.0, 12.0, e2) * (0.5 + 0.5 * tn(R, S, (16, 32, 64), 0.6))
    stone = stone * (1 + 0.03 * (tool * toolm)[..., None])
    pits = speck(R, S, 0.0016, 0.8)
    stone = stone * (1 - 0.22 * pits[..., None])
    chipd = np.clip((e - 1.6 - e2) / 20.0, 0, 1) * smooth(0.0, 3.0, e)
    stone = mix(stone, stone * C(1.08, 1.06, 1.04), chipd * 0.6)
    face = smooth(0.0, 4.0, e2) ** 0.6 * 0.7 + smooth(1.0, 4.0, e) * 0.3
    rhs = np.zeros_like(v)
    top = 0
    for hgt in rows:
        rhs[top:top + hgt] = hgt
        top += hgt
    below = v * rhs
    stk = tn(R, S, (32, 64, 128, 256), 0.65, oy=(2, 4, 8, 16))
    stk2 = tn(R, S, (64, 128, 256, 512), 0.7, oy=(4, 8, 16, 32))
    Lr = 14 + 50 * stk
    streak = np.exp(-below / Lr) * smooth(0.5, 0.8, stk2) * smooth(0.35, 0.6, tn(R, S, (4, 8, 16), 0.6))
    stone = mix(stone, C(0.44, 0.42, 0.38), np.clip(streak, 0, 1) * 0.35)
    wash = smooth(0.62, 0.85, tn(R, S, (16, 32, 64, 128), 0.6, oy=(2, 4, 8, 16)))
    stone = mix(stone, stone * C(1.08, 1.07, 1.05), wash * 0.45)
    li = speck(R, S, 0.0008, 2.4) * smooth(0.55, 0.7, tn(R, S, (8, 16, 32), 0.6))
    stone = mix(stone, C(0.8, 0.8, 0.74), np.clip(li * 1.4, 0, 1) * 0.4)
    stone = stone * (0.88 + 0.12 * face[..., None])
    jm = 1 - smooth(1.0, 2.6, e)
    mortar = C(0.78, 0.74, 0.66) * (0.85 + 0.3 * fine[..., None]) * (1 - 0.3 * np.clip(streak, 0, 1)[..., None])
    col = mix(stone, mortar, jm)
    h = face * 0.6 + (u - 0.5) * tilt + mot * 0.05 + fine * 0.04 + tool * toolm * 0.012 - pits * 0.06 - jm * 0.14
    h = h - np.clip((e - 1.6 - e2) / 40.0, 0, 0.5) * 0.4
    sh = hshadow(h, 5.0, 10, 1.0)
    col = col * (1 - 0.18 * sh[..., None])
    col = bake(col, h, 4.0, k=0.25, ao=0.25, ao_r=4)
    gm.save_surface("pierre_blonde", col, h, 4.5)


def ardoise_hf():
    S = 1024
    R = rng(11202)
    nr, nc = 18, 8

    def corner(u):
        k = 0.06
        t = np.clip((np.abs(u) - (1 - k)) / k, 0, 1)
        return 1 - np.sqrt(np.clip(1 - t * t, 0, 1))
    bid, db, u, rr, cc = roof_rows(R, S, nr, nc, corner, 4.0, 0.8)
    rh = S / nr
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    gr = grain(R, S, 0.6)
    tone = per_id(bid, R, 0.86, 1.12)
    hue = per_id(bid, R, 0.0, 1.0)
    tx = per_id(bid, R, -0.04, 0.04)
    side = (1 - np.abs(u)) * S / nc * 0.5
    gap = 1 - smooth(0.5, 1.8, side)
    face = smooth(0.0, 2.0, db)
    slope = np.clip(db / (rh * 1.8), 0, 1)
    h = 0.7 - 0.3 * slope + u * tx + mot * 0.03 + fine * 0.03 + gr * 0.012
    h = h * face + (1 - face) * (0.48 - 0.3 * slope)
    h = h - gap * 0.25
    pal = np.array([(0.26, 0.29, 0.34), (0.3, 0.33, 0.38), (0.23, 0.25, 0.3), (0.33, 0.35, 0.39), (0.28, 0.28, 0.31)], np.float32)
    ki = np.digitize(hue, [0.3, 0.55, 0.75, 0.9])
    col = pal[ki] * tone[..., None] * (0.88 + 0.2 * mot[..., None]) * (0.86 + 0.26 * gr[..., None]) * (0.92 + 0.14 * fine[..., None])
    # le clivage de l'ardoise : de fines rayures obliques, des reflets par plaques
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    cleave = np.sin((xx * 0.2 + yy * 0.9) / 3.1 + per_id(bid, R, 0, 6.28)) * 0.5 + 0.5
    col = col * (0.96 + 0.06 * cleave[..., None])
    sheen = smooth(0.62, 0.8, tn(R, S, (16, 32, 64), 0.6))
    col = mix(col, col * C(1.18, 1.2, 1.24), sheen * 0.35)
    bot = smooth(14.0, 0.0, db)
    col = col * (1 - 0.12 * bot[..., None])
    # les crochets de cuivre (verdis) au bas de chaque ardoise
    hook = (np.abs(u) < 0.07) & (db < 9.0) & (db > 1.0)
    col = np.where(hook[..., None], C(0.32, 0.5, 0.42) * (0.8 + 0.3 * gr[..., None]), col)
    h = np.where(hook, h + 0.08, h)
    li = speck(R, S, 0.0006, 2.4) * smooth(0.55, 0.7, tn(R, S, (4, 8, 16), 0.6))
    col = mix(col, C(0.7, 0.72, 0.66), np.clip(li * 1.5, 0, 1) * 0.35)
    col = col * (1 - 0.6 * gap[..., None])
    sh = hshadow(h, 6.0, 12, 0.8)
    col = col * (1 - 0.4 * sh[..., None])
    col = bake(col, h, 3.5, k=0.28, ao=0.3, ao_r=4)
    gm.save_surface("ardoise_hf", col, h, 4.5)


def pave_blond():
    S = 1024
    R = rng(11203)
    rows = [148, 156, 144, 152, 140, 150, 134]
    bid, e, u, v = masonry(R, S, rows, 150, 300, rr=4.0)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    gr = grain(R, S, 0.6)
    tone = per_id(bid, R, 0.86, 1.1)
    hue = per_id(bid, R, 0.0, 1.0)
    stone = mix(C(0.66, 0.6, 0.5), C(0.76, 0.69, 0.56), hue) * tone[..., None]
    stone = stone * (0.88 + 0.22 * mot[..., None]) * (0.9 + 0.18 * fine[..., None]) * (0.94 + 0.1 * gr[..., None])
    # l'usure : le milieu des dalles est plus lisse et plus clair
    worn = smooth(4.0, 40.0, e)
    stone = mix(stone, stone * C(1.07, 1.06, 1.04), worn * 0.4)
    cracks = np.zeros_like(e)
    jm = 1 - smooth(1.5, 4.0, e)
    dirt = C(0.36, 0.32, 0.26) * (0.8 + 0.4 * gr[..., None])
    moss = smooth(0.6, 0.8, tn(R, S, (8, 16, 32), 0.6))
    joint = mix(dirt, C(0.24, 0.3, 0.14), moss[..., None] * 0.6)
    col = mix(stone, joint, jm)
    h = smooth(0.0, 10.0, e) * 0.5 + mot * 0.05 + fine * 0.03 - cracks * 0.05 - jm * 0.15 + per_id(bid, R, -0.03, 0.03)
    col = bake(col, h, 3.0, k=0.25, ao=0.3, ao_r=4)
    gm.save_surface("pave_blond", col, h, 4.0)


SURFACES = {"pierre_blonde": pierre_blonde, "ardoise_hf": ardoise_hf, "pave_blond": pave_blond}


# =================================================================== emblèmes et enseignes

def em_colonne(pa, cx, cy, s):
    """La Grande Colonne : une tour d'or à nervures, ses bagues, sa lanterne au sommet."""
    pa.rect(cx - 0.32 * s, cy + 0.58 * s, cx + 0.32 * s, cy + 0.7 * s, (190, 150, 70), shade=0.6, depth=3, ol=1.2)
    pa.poly([(cx - 0.2 * s, cy + 0.58 * s), (cx - 0.13 * s, cy - 0.5 * s), (cx + 0.13 * s, cy - 0.5 * s), (cx + 0.2 * s, cy + 0.58 * s)],
            (226, 182, 80), shade=0.8, depth=4, ol=1.4, grad=((250, 214, 120), (180, 124, 40), 0))
    for k in range(5):
        y = cy + 0.5 * s - k * 0.24 * s
        w = 0.21 * s - k * 0.016 * s
        pa.rect(cx - w, y - 0.03 * s, cx + w, y + 0.03 * s, (150, 100, 40), shade=0.5, depth=1.5, ol=0.8)
    pa.line([(cx, cy + 0.56 * s), (cx, cy - 0.48 * s)], (170, 214, 230), 0.06 * s, alpha=0.8)
    pa.ell(cx, cy - 0.62 * s, 0.13 * s, 0.13 * s, (255, 226, 130), shade=0.4, depth=3, ol=1.2)
    for k in range(8):
        a = k / 8 * TAU
        pa.line([(cx + math.cos(a) * 0.18 * s, cy - 0.62 * s + math.sin(a) * 0.18 * s), (cx + math.cos(a) * 0.3 * s, cy - 0.62 * s + math.sin(a) * 0.3 * s)],
                (255, 230, 150), 0.03 * s, alpha=0.8)
    # une cabine dorée qui monte
    pa.rect(cx - 0.09 * s, cy + 0.05 * s, cx + 0.09 * s, cy + 0.25 * s, (240, 200, 100), shade=0.6, depth=2, ol=1.0)


def em_tasse(pa, cx, cy, s):
    """Une grosse tasse de chocolat fumant, un piston de laiton."""
    pa.poly(ellp(cx - 0.05 * s, cy + 0.1 * s, 0.48 * s, 0.5 * s, 0, 180, 30), (236, 226, 206), shade=0.7, depth=s * 0.1)
    pa.ell(cx - 0.05 * s, cy + 0.1 * s, 0.48 * s, 0.12 * s, (110, 60, 30), shade=0.4, depth=3)
    pa.poly(ellp(cx + 0.45 * s, cy + 0.28 * s, 0.2 * s, 0.22 * s, -90, 90, 20) + ellp(cx + 0.45 * s, cy + 0.28 * s, 0.1 * s, 0.12 * s, 90, -90, 20),
            (226, 214, 190), shade=0.6, depth=s * 0.06)
    for k in (-1, 0, 1):
        x = cx - 0.05 * s + k * 0.22 * s
        pts = [(x + math.sin(t * 5.5) * 0.07 * s, cy - 0.02 * s - t * 0.7 * s) for t in np.linspace(0, 1, 16)]
        pa.line(pts, (240, 238, 230), 0.06 * s)
    pa.rect(cx - 0.62 * s, cy - 0.62 * s, cx - 0.48 * s, cy + 0.04 * s, (214, 172, 80), shade=0.7, depth=2, ol=1.0)
    pa.rect(cx - 0.68 * s, cy - 0.7 * s, cx - 0.42 * s, cy - 0.6 * s, (180, 130, 60), shade=0.6, depth=2, ol=1.0)


def em_horloge(pa, cx, cy, s):
    """Une horloge de laiton : cadran, chiffres en traits, aiguilles, engrenage derrière."""
    br.em_engrenage(pa, cx + 0.32 * s, cy + 0.25 * s, 0.6 * s)
    pa.ell(cx - 0.05 * s, cy - 0.05 * s, 0.56 * s, 0.56 * s, (200, 160, 70), shade=0.7, depth=4, ol=1.6)
    pa.ell(cx - 0.05 * s, cy - 0.05 * s, 0.46 * s, 0.46 * s, (246, 238, 214), shade=0.4, depth=2, ol=1.2)
    for k in range(12):
        a = k / 12 * TAU
        r0, r1 = (0.34, 0.43) if k % 3 else (0.3, 0.43)
        pa.line([(cx - 0.05 * s + math.cos(a) * r0 * s, cy - 0.05 * s + math.sin(a) * r0 * s),
                 (cx - 0.05 * s + math.cos(a) * r1 * s, cy - 0.05 * s + math.sin(a) * r1 * s)], (40, 30, 24), 0.035 * s)
    pa.line([(cx - 0.05 * s, cy - 0.05 * s), (cx - 0.05 * s, cy - 0.36 * s)], (30, 24, 20), 0.05 * s)
    pa.line([(cx - 0.05 * s, cy - 0.05 * s), (cx + 0.18 * s, cy + 0.08 * s)], (30, 24, 20), 0.06 * s)
    pa.ell(cx - 0.05 * s, cy - 0.05 * s, 0.05 * s, 0.05 * s, (180, 40, 30), shade=0.3, depth=1, ol=0.8)


def em_epices(pa, cx, cy, s):
    """Un panier de fruits et trois petits sacs d'épices (rouge, ocre, vert)."""
    for k, c in enumerate(((190, 60, 40), (210, 150, 50), (110, 140, 60))):
        x = cx - 0.45 * s + k * 0.45 * s
        pa.poly([(x - 0.18 * s, cy + 0.62 * s), (x - 0.22 * s, cy + 0.05 * s), (x + 0.22 * s, cy + 0.05 * s), (x + 0.18 * s, cy + 0.62 * s)],
                (200, 176, 130), shade=0.6, depth=3, ol=1.2)
        pa.ell(x, cy + 0.05 * s, 0.2 * s, 0.08 * s, c, shade=0.4, depth=2, ol=1.0)
        pa.line([(x - 0.18 * s, cy + 0.18 * s), (x + 0.18 * s, cy + 0.18 * s)], (120, 90, 50), 0.03 * s)
    for (dx, dy, c) in ((-0.3, -0.35, (220, 60, 40)), (0.0, -0.45, (240, 180, 40)), (0.28, -0.32, (120, 180, 60)), (-0.12, -0.18, (240, 120, 40)), (0.16, -0.16, (200, 40, 60))):
        pa.ell(cx + dx * s, cy + dy * s, 0.15 * s, 0.15 * s, c, shade=0.7, depth=3, ol=1.0)


def em_lunette(pa, cx, cy, s):
    """La grande lunette sur son pied, une étoile."""
    a = math.radians(-35)
    ca, sa = math.cos(a), math.sin(a)
    x0, y0 = cx - 0.5 * s, cy + 0.25 * s
    pts = [(x0 - sa * 0.1 * s, y0 + ca * 0.1 * s), (x0 + ca * 1.0 * s - sa * 0.16 * s, y0 + sa * 1.0 * s + ca * 0.16 * s),
           (x0 + ca * 1.0 * s + sa * 0.16 * s, y0 + sa * 1.0 * s - ca * 0.16 * s), (x0 + sa * 0.1 * s, y0 - ca * 0.1 * s)]
    pa.poly(pts, (200, 160, 70), shade=0.8, depth=4, ol=1.4)
    for t in (0.3, 0.6):
        x, y = x0 + ca * t * s, y0 + sa * t * s
        pa.line([(x - sa * 0.14 * s, y + ca * 0.14 * s), (x + sa * 0.14 * s, y - ca * 0.14 * s)], (120, 80, 30), 0.04 * s)
    pa.line([(cx - 0.05 * s, cy + 0.0 * s), (cx - 0.35 * s, cy + 0.65 * s)], (80, 60, 40), 0.05 * s)
    pa.line([(cx - 0.05 * s, cy + 0.0 * s), (cx + 0.25 * s, cy + 0.65 * s)], (80, 60, 40), 0.05 * s)
    sx, sy = cx + 0.45 * s, cy - 0.5 * s
    st = [(sx + math.cos(-math.pi / 2 + k * TAU / 10) * (0.2 * s if k % 2 == 0 else 0.08 * s), sy + math.sin(-math.pi / 2 + k * TAU / 10) * (0.2 * s if k % 2 == 0 else 0.08 * s)) for k in range(10)]
    pa.poly(st, (255, 226, 120), shade=0.3, depth=2, ol=1.0)


def em_blason(pa, cx, cy, s):
    """L'écu de Hautefond : la Colonne sur un champ bleu, une couronne de laiton."""
    pts = gm.shield_pts(cx, cy - 0.6 * s, 1.1 * s, 1.3 * s)
    pa.poly(pts, (40, 60, 120), shade=0.6, depth=4, ol=1.6)
    em_colonne(pa, cx, cy + 0.02 * s, 0.75 * s)


gm.EMBLEMS.update({"colonne": em_colonne, "tasse": em_tasse, "horloge": em_horloge, "epices": em_epices, "lunette": em_lunette,
                   "blason": em_blason, "livres": br.em_livres, "vapeur": br.em_vapeur, "enclume": br.em_enclume})

ENSEIGNES = {
    "liftiers": ("Confrérie des Liftiers", "La Grande Colonne · Ça monte !", "fer", (36, 46, 70), "or", "colonne"),
    "piston": ("Le Piston Joyeux", "Taverne · Chocolat à la vapeur", "bois", (92, 56, 32), "or", "tasse"),
    "horloger": ("Horlogerie Ressort", "Gaspard · À la seconde près", "peint", (40, 58, 54), "laiton", "horloge"),
    "forge_vapeur": ("Forge à Vapeur", "Mathilde · Armes, outils & rouages", "fer", (52, 48, 46), "laiton", "enclume"),
    "epices": ("Épices & Fruits", "Rosalie · Au Grand Marché", "peint", (120, 62, 40), "creme", "epices"),
    "bibliotheque": ("Bibliothèque des Cartes", "Silence, s'il vous plaît", "bois", (70, 44, 30), "or", "livres"),
    "observatoire": ("Observatoire", "Professeur Lunette · Les étoiles", "peint", (26, 30, 70), "or", "lunette"),
    "mairie": ("Hôtel de Ville", "Hautefond · Par la Colonne !", "peint", (34, 52, 96), "or", "blason"),
}


def enseignes():
    gm.ENSEIGNES.clear()
    gm.ENSEIGNES.update(ENSEIGNES)
    for k in ENSEIGNES:
        gm.enseigne(k)


# =================================================================== la bannière

def banniere_hautefond():
    W, H = 256, 512
    R = rng(11210)
    pa = Paint(W, H, 2, bg=(22, 30, 70), seed=11210)
    x0, x1, y0, yt, yn = 18, 238, 10, 500, 420
    shape = [(x0, y0), (x1, y0), (x1, yt), (128, yn), (x0, yt)]
    yy, xx = np.mgrid[0:pa.h, 0:pa.w].astype(np.float32) / pa.K
    big = max(pa.w, pa.h)
    weave = 0.93 + 0.07 * (np.sin(xx * 3.1) * np.sin(yy * 3.1) * 0.5 + 0.5)
    blue = np.array((0.09, 0.13, 0.32), np.float32) * weave[..., None] * (0.88 + 0.22 * tn(R, big, (8, 16, 32, 64), 0.6)[:pa.h, :pa.w, None])
    pa.rgb = blue.astype(np.float32)
    # des nuages en bas (l'île flottante au-dessus), la colonne au milieu
    for k in range(5):
        pa.ell(40 + k * 44, 350 + (k % 2) * 8, 34, 16, (200, 210, 230), shade=0.3, depth=2, ol=1.0, alpha=0.9)
    em_colonne(pa, 128, 270, 150)
    pa.text((128, 76), "HAUTEFOND", 26, (240, 204, 100), stroke=1.4, stroke_col=(20, 16, 8), spacing=1.5, shade=0.4)
    inner = [(x0 + 12, y0 + 30), (x1 - 12, y0 + 30), (x1 - 12, yt - 20), (128, yn - 13), (x0 + 12, yt - 20)]
    m_out = np.asarray(pa._draw(lambda d: d.polygon(pa.P(shape), fill=255)), np.float32) / 255.0
    m_in = np.asarray(pa._draw(lambda d: d.polygon(pa.P(inner), fill=255)), np.float32) / 255.0
    pa.comp(Image.fromarray((np.clip(m_out - m_in, 0, 1) * 255).astype(np.uint8)), (196, 150, 52), shade=0.5, depth=2)
    pa.outline(inner, 1.4, (90, 60, 20), alpha=0.9)
    pa.rect(x0, y0, x1, y0 + 22, (150, 110, 40), shade=0.6, depth=2, ol=1.4)
    folds = 1 + 0.13 * np.sin(xx / 64 * TAU + 0.6) + 0.06 * np.sin(xx / 23 * TAU + 1.3)
    pa.rgb = pa.rgb * folds[..., None]
    rgb, _ = pa.result()
    am = Image.new("L", (W * 4, H * 4), 0)
    ImageDraw.Draw(am).polygon([(x * 4, y * 4) for x, y in shape], fill=255)
    alpha = np.asarray(am.resize((W, H), Image.LANCZOS), np.float32) / 255.0
    gm.save_rgba(np.dstack([rgb, alpha]), "banniere_hautefond.png")


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else ""
    OUT.mkdir(parents=True, exist_ok=True)
    if arg in ("", "surfaces"):
        for f in SURFACES.values():
            f()
    if arg in ("", "enseignes"):
        enseignes()
    if arg in ("", "banniere"):
        banniere_hautefond()
    if arg in SURFACES:
        SURFACES[arg]()
    if arg in ENSEIGNES:
        gm.ENSEIGNES.clear()
        gm.ENSEIGNES.update(ENSEIGNES)
        gm.enseigne(arg)


if __name__ == "__main__":
    main()
