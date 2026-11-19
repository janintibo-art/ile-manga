"""V174 : les images de la maison des Grandpré et du Moulin de la Butte (l'Île des Géants).
Faites ici ; CC0 1.0. Dossier www/assets/textures/beau174/.

  vichy_rouge        le vichy rouge et blanc (les rideaux, le couvercle du pot de confiture) ; se répète.
  faience            une assiette de faïence (le marli à festons bleus, le bouquet au milieu) ; ronde,
                     le dehors transparent.
  cadran_comtoise    le cadran émaillé de l'horloge comtoise (chiffres romains, guirlande de fleurs).
  dessin_paquerette  le dessin de Pâquerette punaisé au mur : la ferme, la famille, et le tout petit ami.
  tableau_moulin     la peinture au-dessus de la cheminée : le Moulin de la Butte, les blés, le ciel.
  calendrier         l'almanach de la ferme (le mois, les jours, la foire et la moisson entourées).
  laine              les brins d'une pelote de laine ; se répète.
  tapis_tresse       le tapis rond en chiffons tressés devant la cheminée ; rond, le dehors transparent.
  croute             la croûte d'une miche de campagne (fendue, farinée) ; se répète.
  fromage            la pâte d'un fromage à trous, coupée ; se répète.
  sac_farine         la toile d'un sac de farine du moulin, tamponnée.
  etiquette_sardines l'étiquette de la boîte de sardines (le lit de Tante Brindille).
  timbre             le timbre-poste encadré chez Tante Brindille (un voilier).
  enseigne_pepin     l'enseigne de Pépin, le boulanger des Petits (peinte sur un couvercle de boîte).
  panneau_chateau    V177 : l'écriteau de Pâquerette au-dessus de la porte du donjon (son château de
                     sable) : « CHÂTEAU DES PETITS », écrit au crayon gras sur une planchette de bois flotté.
  marees             V177 : l'ardoise des marées de Firmin, le gardien du château (les heures, la
                     courbe de la mer, ce qu'il ne faut pas oublier), à la craie.
  vues               ce qu'on voit par les fenêtres (le jour, la nuit) : d'après les images de
                     tests/outils/rendu_geants.sh DOSSIER fenetres, recadrées ; la nuit, bleuie,
                     des étoiles. (python3 -B pcvr/tools/generate_textures_v174.py vues DOSSIER)

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_textures_v174.py [nom…]
"""
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

RACINE = Path(__file__).resolve().parents[2]
OUT = RACINE / "www" / "assets" / "textures" / "beau174"
SS = 2
FONTS = Path("/usr/share/fonts/truetype/dejavu")


def police(nom, taille):
    try:
        return ImageFont.truetype(str(FONTS / nom), int(taille * SS))
    except OSError:
        return ImageFont.load_default()


def bruit(cell, seed, w, h=None):
    """Un bruit de valeur lisse (w × h pixels), qui se répète en largeur et en hauteur."""
    h = h or w
    r = np.random.default_rng(seed)
    ch = max(1, int(round(cell * h / w)))
    g = r.random((ch + 1, cell + 1))
    g[:, cell] = g[:, 0]
    g[ch, :] = g[0, :]
    tx = np.linspace(0, cell, w, endpoint=False)
    ty = np.linspace(0, ch, h, endpoint=False)
    ix = np.floor(tx).astype(int)
    iy = np.floor(ty).astype(int)
    fx = tx - ix
    fy = ty - iy
    fx = fx * fx * (3 - 2 * fx)
    fy = fy * fy * (3 - 2 * fy)
    a = g[np.ix_(iy, ix)]
    b = g[np.ix_(iy, ix + 1)]
    c = g[np.ix_(iy + 1, ix)]
    d = g[np.ix_(iy + 1, ix + 1)]
    fy = fy[:, None]
    fx = fx[None, :]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def fbm(cell, oct_, seed, w, h=None):
    s = bruit(cell, seed, w, h)
    amp = tot = 1.0
    for o in range(1, oct_):
        amp *= 0.5
        s = s + amp * bruit(cell * 2 ** o, seed + o * 13, w, h)
        tot += amp
    return s / tot


def rgb(arr):
    return Image.fromarray((np.clip(arr, 0, 1) * 255).round().astype(np.uint8))


def melange(c0, c1, t):
    t = t[..., None]
    return np.array(c0)[None, None, :] * (1 - t) + np.array(c1)[None, None, :] * t


def rond(img, marge=2):
    """Le dehors du cercle devient transparent (une assiette, un cadran, un tapis)."""
    w, h = img.size
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).ellipse([marge * SS, marge * SS, w - marge * SS, h - marge * SS], fill=255)
    img = img.convert("RGBA")
    img.putalpha(m)
    return img


def papier(w, h, seed, c0=(0.95, 0.93, 0.86), c1=(0.86, 0.82, 0.72)):
    n = fbm(8, 4, seed, w, h)
    return rgb(melange(c0, c1, n * 0.7)).convert("RGBA")


# =================================================================== les tissus

def vichy_rouge():
    w = 256 * SS
    x = np.arange(w)
    n_carres = 8
    bande = ((x * n_carres // w) % 2 == 0).astype(float)
    bx = bande[None, :] * np.ones((w, 1))
    by = bande[:, None] * np.ones((1, w))
    # le rouge plein (les deux bandes se croisent), le rouge clair (une seule), le blanc
    t = (bx + by) / 2.0
    rouge = np.array((0.72, 0.1, 0.12))
    blanc = np.array((0.96, 0.94, 0.9))
    c = blanc[None, None, :] * (1 - t[..., None]) + rouge[None, None, :] * t[..., None]
    # la trame : de fins fils, un peu de grain
    fil = 0.92 + 0.08 * np.sin(x * math.pi * 2 / (3 * SS))
    c = c * fil[None, :, None] * fil[:, None, None]
    c = c * (0.94 + 0.12 * fbm(16, 3, 7, w, w))[..., None]
    rgb(c).resize((256, 256), Image.LANCZOS).save(OUT / "vichy_rouge.png")


def laine():
    w = 256 * SS
    yy, xx = np.mgrid[0:w, 0:w].astype(float)
    # des brins en biais, torsadés, quelques fibres claires
    u = (xx + yy * 0.55) / w * 26 * math.pi
    brin = 0.5 + 0.5 * np.sin(u + 2.2 * np.sin(yy / w * 2 * math.pi * 3))
    tors = 0.5 + 0.5 * np.sin((xx - yy) / w * 80 * math.pi)
    v = 0.55 + 0.3 * brin + 0.1 * tors + 0.15 * (fbm(24, 3, 41, w, w) - 0.5)
    c = np.stack([v * 0.98, v * 0.97, v * 0.95], axis=-1)
    rgb(c).resize((256, 256), Image.LANCZOS).save(OUT / "laine.png")


def tapis_tresse():
    w = 512 * SS
    yy, xx = np.mgrid[0:w, 0:w].astype(float)
    cx = cy = w / 2
    r = np.hypot(xx - cx, yy - cy) / (w / 2)
    a = np.arctan2(yy - cy, xx - cx)
    # des tours de tresse : chaque tour a sa couleur de chiffon, la tresse fait des chevrons
    tours = r * 14
    k = np.floor(tours).astype(int)
    f = tours - k
    couleurs = np.array([(0.62, 0.18, 0.16), (0.82, 0.7, 0.45), (0.3, 0.42, 0.56), (0.55, 0.62, 0.38),
                         (0.78, 0.48, 0.3), (0.42, 0.3, 0.42), (0.86, 0.82, 0.72)])
    base = couleurs[k % len(couleurs)]
    chevron = 0.5 + 0.5 * np.sin(a * (40 + k * 6) + np.where(f < 0.5, f, 1 - f) * 9)
    relief = np.sin(f * math.pi) ** 0.6
    v = (0.55 + 0.35 * chevron[..., None] * 0.6 + 0.25 * relief[..., None]) * base
    v = v * (0.9 + 0.2 * fbm(20, 3, 13, w, w))[..., None]
    img = rond(rgb(v), 6)
    img.resize((512, 512), Image.LANCZOS).save(OUT / "tapis_tresse.png")


# =================================================================== la vaisselle, l'horloge

def faience():
    w = 512 * SS
    img = rgb(melange((0.97, 0.95, 0.9), (0.9, 0.88, 0.8), fbm(6, 3, 3, w, w) * 0.5))
    d = ImageDraw.Draw(img)
    c = w / 2
    bleu = (40, 70, 140)
    bleu_c = (90, 120, 185)
    # le marli : un filet, des festons et des fleurettes tout autour
    d.ellipse([c - w * 0.47, c - w * 0.47, c + w * 0.47, c + w * 0.47], outline=bleu, width=5 * SS)
    d.ellipse([c - w * 0.33, c - w * 0.33, c + w * 0.33, c + w * 0.33], outline=bleu_c, width=3 * SS)
    for k in range(18):
        a = k * 2 * math.pi / 18
        x = c + math.cos(a) * w * 0.4
        y = c + math.sin(a) * w * 0.4
        r0 = w * 0.055
        d.arc([x - r0, y - r0, x + r0, y + r0], math.degrees(a) + 90, math.degrees(a) + 270, fill=bleu, width=3 * SS)
        for p in range(5):
            b = p * 2 * math.pi / 5 + a
            px = x + math.cos(b) * w * 0.016
            py = y + math.sin(b) * w * 0.016
            d.ellipse([px - w * 0.011, py - w * 0.011, px + w * 0.011, py + w * 0.011], fill=bleu_c)
    # le bouquet au milieu : une rose, des feuilles, deux boutons
    for (dx, dy, s) in [(0, 0, 1.0), (-0.1, 0.08, 0.55), (0.11, 0.07, 0.6)]:
        x = c + dx * w
        y = c + dy * w
        for p in range(7):
            b = p * 2 * math.pi / 7
            r1 = w * 0.05 * s
            px = x + math.cos(b) * r1 * 0.8
            py = y + math.sin(b) * r1 * 0.8
            d.ellipse([px - r1 * 0.7, py - r1 * 0.7, px + r1 * 0.7, py + r1 * 0.7], outline=bleu, width=2 * SS, fill=(205, 70, 80) if s == 1.0 else (225, 110, 120))
        d.ellipse([x - w * 0.02 * s, y - w * 0.02 * s, x + w * 0.02 * s, y + w * 0.02 * s], fill=(160, 40, 50))
    for (a, l) in [(200, 0.15), (240, 0.13), (300, 0.14), (340, 0.12), (20, 0.13), (140, 0.12)]:
        ar = math.radians(a)
        x0 = c + math.cos(ar) * w * 0.05
        y0 = c + math.sin(ar) * w * 0.05
        x1 = c + math.cos(ar) * w * l
        y1 = c + math.sin(ar) * w * l
        d.line([(x0, y0), (x1, y1)], fill=(60, 110, 70), width=3 * SS)
        d.ellipse([x1 - w * 0.025, y1 - w * 0.013, x1 + w * 0.025, y1 + w * 0.013], fill=(80, 140, 85), outline=(50, 90, 55))
    img = rond(img, 3)
    img.resize((512, 512), Image.LANCZOS).save(OUT / "faience.png")


def cadran_comtoise():
    w = 512 * SS
    img = rgb(melange((0.98, 0.97, 0.93), (0.9, 0.88, 0.82), fbm(5, 3, 21, w, w) * 0.5))
    d = ImageDraw.Draw(img)
    c = w / 2
    noir = (30, 26, 24)
    f = police("DejaVuSerif-Bold.ttf", 34)
    romains = ["XII", "I", "II", "III", "IIII", "V", "VI", "VII", "VIII", "IX", "X", "XI"]
    for k in range(12):
        a = k * 2 * math.pi / 12 - math.pi / 2
        x = c + math.cos(a) * w * 0.37
        y = c + math.sin(a) * w * 0.37
        t = romains[k]
        bb = d.textbbox((0, 0), t, font=f)
        d.text((x - (bb[2] - bb[0]) / 2, y - (bb[3] - bb[1]) / 2 - bb[1]), t, fill=noir, font=f)
    for k in range(60):
        a = k * 2 * math.pi / 60
        r0 = w * (0.445 if k % 5 else 0.43)
        d.line([(c + math.cos(a) * r0, c + math.sin(a) * r0), (c + math.cos(a) * w * 0.465, c + math.sin(a) * w * 0.465)], fill=noir, width=(3 if k % 5 == 0 else 1) * SS)
    d.ellipse([c - w * 0.47, c - w * 0.47, c + w * 0.47, c + w * 0.47], outline=noir, width=3 * SS)
    # une guirlande de fleurs peintes en haut, le nom du village
    for k in range(9):
        a = math.radians(205 + k * 16.25)
        x = c + math.cos(a) * w * 0.22
        y = c + math.sin(a) * w * 0.22
        col = [(200, 60, 70), (230, 170, 50), (70, 110, 180)][k % 3]
        d.ellipse([x - w * 0.025, y - w * 0.025, x + w * 0.025, y + w * 0.025], fill=col, outline=(90, 60, 40))
        d.ellipse([x - w * 0.045, y + w * 0.01, x - w * 0.015, y + w * 0.03], fill=(80, 130, 70))
    f2 = police("DejaVuSerif-Italic.ttf", 20)
    t = "Grandpré · la Butte"
    bb = d.textbbox((0, 0), t, font=f2)
    d.text((c - (bb[2] - bb[0]) / 2, c + w * 0.12), t, fill=(90, 60, 40), font=f2)
    img = rond(img, 2)
    img.resize((512, 512), Image.LANCZOS).save(OUT / "cadran_comtoise.png")


# =================================================================== aux murs

def dessin_paquerette():
    w, h = 768 * SS, 560 * SS
    img = papier(w, h, 91, (0.97, 0.96, 0.92), (0.9, 0.88, 0.82))
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(5)

    def cire(pts, col, larg=6):
        # un trait de craie grasse : plusieurs passages un peu tremblés
        for k in range(3):
            q = [(x + rng.normal(0, 1.5 * SS), y + rng.normal(0, 1.5 * SS)) for (x, y) in pts]
            d.line(q, fill=col, width=int(larg * SS * (0.6 + 0.2 * k)), joint="curve")

    def gribouille(x0, y0, x1, y1, col, pas=7):
        y = y0
        while y < y1:
            cire([(x0, y), (x1, y + pas * SS * 0.6)], col, 4)
            y += pas * SS
    # le ciel, le soleil et ses rayons
    gribouille(0, 0, w, h * 0.12, (120, 175, 235, 255))
    sx, sy = w * 0.86, h * 0.14
    d.ellipse([sx - 50 * SS, sy - 50 * SS, sx + 50 * SS, sy + 50 * SS], fill=(250, 210, 60, 255))
    for k in range(12):
        a = k * math.pi / 6
        cire([(sx + math.cos(a) * 62 * SS, sy + math.sin(a) * 62 * SS), (sx + math.cos(a) * 95 * SS, sy + math.sin(a) * 95 * SS)], (245, 180, 40, 255), 5)
    # l'herbe
    gribouille(0, h * 0.8, w, h, (90, 170, 80, 255), 9)
    # la maison : les murs, le toit rouge, la porte verte et sa petite porte
    mx0, mx1, my0, my1 = w * 0.08, w * 0.42, h * 0.42, h * 0.82
    cire([(mx0, my1), (mx0, my0), (mx1, my0), (mx1, my1), (mx0, my1)], (120, 90, 70, 255))
    cire([(mx0 - 20 * SS, my0), ((mx0 + mx1) / 2, h * 0.2), (mx1 + 20 * SS, my0), (mx0 - 20 * SS, my0)], (200, 50, 40, 255), 8)
    cire([(w * 0.21, my1), (w * 0.21, h * 0.6), (w * 0.29, h * 0.6), (w * 0.29, my1)], (40, 140, 70, 255), 7)
    cire([(w * 0.215, my1), (w * 0.215, h * 0.78), (w * 0.235, h * 0.78), (w * 0.235, my1)], (150, 100, 60, 255), 4)
    for fx in (0.12, 0.33):
        cire([(w * fx, h * 0.5), (w * fx + 50 * SS, h * 0.5), (w * fx + 50 * SS, h * 0.56), (w * fx, h * 0.56), (w * fx, h * 0.5)], (70, 120, 200, 255), 5)
    # la famille : cinq bonhommes, du plus grand au plus petit (Pâquerette et ses tresses)
    tailles = [(0.5, 0.5, (60, 60, 160)), (0.58, 0.48, (150, 60, 140)), (0.66, 0.4, (90, 90, 90)), (0.73, 0.42, (120, 80, 50)), (0.8, 0.34, (230, 120, 170))]
    for (fx, ht, col) in tailles:
        x = w * fx
        pied = h * 0.86
        tete = pied - h * ht
        r = 26 * SS
        d.ellipse([x - r, tete - r, x + r, tete + r], outline=(60, 40, 30, 255), width=4 * SS, fill=(250, 220, 190, 255))
        cire([(x - 8 * SS, tete - 4 * SS), (x - 7 * SS, tete - 3 * SS)], (40, 30, 30, 255), 4)
        cire([(x + 8 * SS, tete - 4 * SS), (x + 9 * SS, tete - 3 * SS)], (40, 30, 30, 255), 4)
        d.arc([x - 12 * SS, tete - 6 * SS, x + 12 * SS, tete + 14 * SS], 20, 160, fill=(190, 50, 50, 255), width=3 * SS)
        cire([(x, tete + r), (x - 30 * SS, pied - h * ht * 0.35), (x + 30 * SS, pied - h * ht * 0.35), (x, tete + r)], col, 7)
        cire([(x - 10 * SS, pied - h * ht * 0.35), (x - 18 * SS, pied)], (60, 40, 30, 255), 5)
        cire([(x + 10 * SS, pied - h * ht * 0.35), (x + 18 * SS, pied)], (60, 40, 30, 255), 5)
        cire([(x - 20 * SS, tete + r + h * ht * 0.12), (x - 55 * SS, tete + r + h * ht * 0.25)], (60, 40, 30, 255), 4)
        cire([(x + 20 * SS, tete + r + h * ht * 0.12), (x + 55 * SS, tete + r + h * ht * 0.2)], (60, 40, 30, 255), 4)
        if fx == 0.8:
            for s in (-1, 1):
                cire([(x + s * r, tete), (x + s * (r + 22 * SS), tete + 40 * SS)], (240, 200, 60, 255), 6)
    # le tout petit ami, et la flèche
    px, py = w * 0.91, h * 0.86
    d.ellipse([px - 7 * SS, py - 48 * SS, px + 7 * SS, py - 34 * SS], outline=(60, 40, 30, 255), width=3 * SS)
    cire([(px, py - 34 * SS), (px, py - 14 * SS)], (60, 40, 30, 255), 3)
    cire([(px, py - 14 * SS), (px - 6 * SS, py)], (60, 40, 30, 255), 3)
    cire([(px, py - 14 * SS), (px + 6 * SS, py)], (60, 40, 30, 255), 3)
    cire([(px - 8 * SS, py - 28 * SS), (px + 8 * SS, py - 28 * SS)], (60, 40, 30, 255), 3)
    cire([(w * 0.8, h * 0.3), (w * 0.9, h * 0.5), (w * 0.92, h * 0.7)], (220, 40, 60, 255), 5)
    cire([(w * 0.905, h * 0.66), (w * 0.92, h * 0.71), (w * 0.94, h * 0.67)], (220, 40, 60, 255), 5)
    f = police("DejaVuSans-Bold.ttf", 30)
    x = w * 0.32
    for i, ch in enumerate("MON TOUT PETIT AMI"):
        lettre = Image.new("RGBA", (40 * SS, 50 * SS), (0, 0, 0, 0))
        ImageDraw.Draw(lettre).text((4 * SS, 2 * SS), ch, font=f, fill=(220, 40, 60, 255))
        lettre = lettre.rotate(rng.normal(0, 9), resample=Image.BICUBIC)
        img.alpha_composite(lettre, (int(x), int(h * 0.2 + rng.normal(0, 4) * SS)))
        x += (f.getbbox(ch)[2] if ch != " " else 10 * SS) + 5 * SS
    f2 = police("DejaVuSans-Bold.ttf", 22)
    x = w * 0.05
    for ch in "PAQUERETTE":
        lettre = Image.new("RGBA", (34 * SS, 40 * SS), (0, 0, 0, 0))
        ImageDraw.Draw(lettre).text((3 * SS, 2 * SS), ch, font=f2, fill=(110, 60, 160, 255))
        lettre = lettre.rotate(rng.normal(0, 10), resample=Image.BICUBIC)
        img.alpha_composite(lettre, (int(x), int(h * 0.9)))
        x += 19 * SS
    img.convert("RGB").resize((768, 560), Image.LANCZOS).save(OUT / "dessin_paquerette.png")


def tableau_moulin():
    w, h = 640 * SS, 480 * SS
    yy = np.linspace(0, 1, h)[:, None] * np.ones((1, w))
    n = fbm(10, 5, 301, w, h)
    ciel = melange((0.45, 0.62, 0.86), (0.93, 0.86, 0.72), np.clip(yy * 1.6, 0, 1))
    nuage = np.clip((fbm(5, 5, 77, w, h) - 0.52) * 4, 0, 1) * (1 - yy) ** 0.5
    ciel = ciel * (1 - nuage[..., None] * 0.6) + np.array((0.98, 0.96, 0.92))[None, None, :] * nuage[..., None] * 0.6
    img = rgb(ciel)
    d = ImageDraw.Draw(img)
    # la colline, les blés, la ferme au loin
    pts = [(0, h)]
    for k in range(65):
        x = k * w / 64
        y = h * (0.62 - 0.16 * math.exp(-((x / w - 0.62) ** 2) / 0.05) + 0.02 * math.sin(k * 0.7))
        pts.append((x, y))
    pts.append((w, h))
    d.polygon(pts, fill=(118, 150, 70))
    d.polygon([(0, h), (0, h * 0.78)] + [(k * w / 32, h * (0.78 + 0.02 * math.sin(k))) for k in range(33)] + [(w, h)], fill=(214, 180, 86))
    # le moulin : la tour blanche, le bonnet, les ailes
    mx, my = w * 0.62, h * 0.47
    d.polygon([(mx - 30 * SS, my + 4 * SS), (mx + 30 * SS, my + 4 * SS), (mx + 22 * SS, my - 110 * SS), (mx - 22 * SS, my - 110 * SS)], fill=(236, 232, 222))
    d.ellipse([mx - 26 * SS, my - 132 * SS, mx + 26 * SS, my - 96 * SS], fill=(120, 84, 56))
    d.rectangle([mx - 8 * SS, my - 30 * SS, mx + 8 * SS, my + 4 * SS], fill=(60, 110, 70))
    hx, hy = mx + 4 * SS, my - 112 * SS
    for k in range(4):
        a = k * math.pi / 2 + 0.5
        ex = hx + math.cos(a) * 120 * SS
        ey = hy + math.sin(a) * 120 * SS
        d.line([(hx, hy), (ex, ey)], fill=(90, 62, 40), width=5 * SS)
        px = -math.sin(a) * 22 * SS
        py = math.cos(a) * 22 * SS
        d.polygon([(hx + math.cos(a) * 30 * SS, hy + math.sin(a) * 30 * SS), (ex, ey), (ex + px, ey + py), (hx + math.cos(a) * 30 * SS + px, hy + math.sin(a) * 30 * SS + py)], fill=(240, 232, 214), outline=(110, 80, 56))
    # la ferme au loin (le toit rouge), des peupliers
    d.polygon([(w * 0.12, h * 0.66), (w * 0.26, h * 0.66), (w * 0.26, h * 0.6), (w * 0.12, h * 0.6)], fill=(232, 222, 200))
    d.polygon([(w * 0.1, h * 0.6), (w * 0.19, h * 0.53), (w * 0.28, h * 0.6)], fill=(176, 72, 52))
    for px2 in (0.33, 0.36, 0.86, 0.9):
        d.ellipse([w * px2 - 12 * SS, h * 0.42, w * px2 + 12 * SS, h * 0.64], fill=(62, 96, 52))
    # la touche du peintre : de petits coups de pinceau
    a = np.array(img).astype(float) / 255.0
    touche = fbm(64, 2, 919, w, h)
    a = a * (0.9 + 0.2 * touche[..., None])
    img = rgb(a).filter(ImageFilter.GaussianBlur(1.2 * SS))
    img.resize((640, 480), Image.LANCZOS).save(OUT / "tableau_moulin.png")


def calendrier():
    w, h = 320 * SS, 480 * SS
    img = papier(w, h, 33)
    d = ImageDraw.Draw(img)
    # l'image du mois : un champ de tournesols
    d.rectangle([16 * SS, 16 * SS, w - 16 * SS, h * 0.42], fill=(130, 180, 230, 255))
    d.rectangle([16 * SS, h * 0.3, w - 16 * SS, h * 0.42], fill=(90, 140, 70, 255))
    rng = np.random.default_rng(8)
    for k in range(14):
        x = 30 * SS + rng.random() * (w - 60 * SS)
        y = h * 0.28 + rng.random() * h * 0.12
        r = (10 + rng.random() * 8) * SS
        for p in range(10):
            a = p * math.pi / 5
            d.ellipse([x + math.cos(a) * r - r * 0.45, y + math.sin(a) * r - r * 0.45, x + math.cos(a) * r + r * 0.45, y + math.sin(a) * r + r * 0.45], fill=(245, 196, 40, 255))
        d.ellipse([x - r * 0.6, y - r * 0.6, x + r * 0.6, y + r * 0.6], fill=(110, 70, 30, 255))
    f = police("DejaVuSerif-Bold.ttf", 26)
    t = "SEPTEMBRE"
    bb = d.textbbox((0, 0), t, font=f)
    d.text(((w - (bb[2] - bb[0])) / 2, h * 0.45), t, fill=(120, 40, 30, 255), font=f)
    f2 = police("DejaVuSans.ttf", 15)
    f3 = police("DejaVuSans-Bold.ttf", 11)
    for i, j in enumerate("LMMJVSD"):
        d.text((24 * SS + i * 40 * SS, h * 0.54), j, fill=(80, 60, 50, 255), font=f3)
    for jour in range(1, 31):
        k = jour + 1
        col = k % 7
        lig = k // 7
        x = 22 * SS + col * 40 * SS
        y = h * 0.59 + lig * 30 * SS
        d.text((x, y), str(jour), fill=(50, 40, 35, 255) if col < 6 else (170, 50, 40, 255), font=f2)
        if jour in (12, 21):
            d.ellipse([x - 8 * SS, y - 4 * SS, x + 28 * SS, y + 24 * SS], outline=(200, 40, 60, 255), width=3 * SS)
    f4 = police("DejaVuSerif-Italic.ttf", 13)
    d.text((24 * SS, h * 0.93), "Almanach de la Butte", fill=(110, 80, 60, 255), font=f4)
    img.convert("RGB").resize((320, 480), Image.LANCZOS).save(OUT / "calendrier.png")


# =================================================================== sur la table

def croute():
    w = 256 * SS
    n = fbm(6, 5, 61, w, w)
    fines = fbm(32, 3, 62, w, w)
    c = melange((0.5, 0.28, 0.12), (0.86, 0.62, 0.32), np.clip(n * 1.3 - 0.15, 0, 1))
    # les fentes (plus claires, la mie qui affleure), la farine
    fente = np.clip(1 - np.abs(np.sin((np.mgrid[0:w, 0:w][0] / w + n * 0.3) * 6 * math.pi)) * 12, 0, 1)
    c = c * (1 - fente[..., None] * 0.5) + np.array((0.95, 0.86, 0.66))[None, None, :] * fente[..., None] * 0.5
    farine = np.clip((fines - 0.62) * 5, 0, 1)
    c = c * (1 - farine[..., None] * 0.6) + np.array((0.96, 0.94, 0.9))[None, None, :] * farine[..., None] * 0.6
    rgb(c).resize((256, 256), Image.LANCZOS).save(OUT / "croute.png")


def fromage():
    w = 256 * SS
    n = fbm(5, 4, 71, w, w)
    c = melange((0.98, 0.86, 0.5), (0.93, 0.76, 0.38), n)
    img = rgb(c)
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(72)
    for k in range(16):
        x = rng.random() * w
        y = rng.random() * w
        r = (6 + rng.random() * 18) * SS
        for (ox, oy) in [(0, 0), (w, 0), (-w, 0), (0, w), (0, -w)]:
            d.ellipse([x + ox - r, y + oy - r * 0.85, x + ox + r, y + oy + r * 0.85], fill=(196, 150, 70))
            d.ellipse([x + ox - r * 0.85, y + oy - r * 0.7, x + ox + r * 0.85, y + oy + r * 0.6], fill=(214, 168, 86))
    img.resize((256, 256), Image.LANCZOS).save(OUT / "fromage.png")


# =================================================================== chez les Petits, au moulin

def sac_farine():
    w, h = 320 * SS, 400 * SS
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    trame = 0.88 + 0.06 * np.sin(xx * math.pi * 2 / (4 * SS)) + 0.06 * np.sin(yy * math.pi * 2 / (4 * SS))
    c = melange((0.86, 0.8, 0.66), (0.76, 0.68, 0.52), fbm(6, 4, 81, w, h)) * trame[..., None]
    img = rgb(c)
    d = ImageDraw.Draw(img)
    encre = (150, 52, 40)
    f = police("DejaVuSerif-Bold.ttf", 34)
    f2 = police("DejaVuSerif.ttf", 15)
    for (t, ff, y) in [("FARINE", f, 0.2), ("de la Butte", f2, 0.33), ("Moulin des Grandpré", f2, 0.8), ("FROMENT · 1re QUALITÉ", f2, 0.87)]:
        bb = d.textbbox((0, 0), t, font=ff)
        d.text(((w - (bb[2] - bb[0])) / 2, h * y), t, fill=encre, font=ff)
    # le petit moulin tamponné
    mx, my = w / 2, h * 0.58
    d.polygon([(mx - 26 * SS, my + 40 * SS), (mx + 26 * SS, my + 40 * SS), (mx + 18 * SS, my - 30 * SS), (mx - 18 * SS, my - 30 * SS)], outline=encre, width=4 * SS)
    for k in range(4):
        a = k * math.pi / 2 + 0.6
        d.line([(mx, my - 36 * SS), (mx + math.cos(a) * 64 * SS, my - 36 * SS + math.sin(a) * 64 * SS)], fill=encre, width=5 * SS)
    # l'encre usée par endroits
    a = np.array(img).astype(float) / 255.0
    use = np.clip((fbm(12, 3, 83, w, h) - 0.18) * 4, 0.35, 1)
    a = a * use[..., None] + c * (1 - use[..., None])
    rgb(a).resize((320, 400), Image.LANCZOS).save(OUT / "sac_farine.png")


def etiquette_sardines():
    w, h = 512 * SS, 192 * SS
    img = rgb(melange((0.18, 0.36, 0.56), (0.1, 0.24, 0.4), fbm(6, 3, 91, w, h)))
    d = ImageDraw.Draw(img)
    or_ = (232, 196, 96)
    d.rectangle([8 * SS, 8 * SS, w - 8 * SS, h - 8 * SS], outline=or_, width=4 * SS)
    f = police("DejaVuSerif-Bold.ttf", 30)
    f2 = police("DejaVuSerif-Italic.ttf", 15)
    for (t, ff, y) in [("SARDINES", f, 0.18), ("à l'huile d'olive · Conserverie du Grand Large", f2, 0.62)]:
        bb = d.textbbox((0, 0), t, font=ff)
        d.text(((w - (bb[2] - bb[0])) / 2, h * y), t, fill=or_, font=ff)
    for k in range(3):
        x = w * (0.2 + 0.3 * k)
        y = h * 0.82
        d.ellipse([x - 40 * SS, y - 8 * SS, x + 30 * SS, y + 8 * SS], fill=(196, 206, 214))
        d.polygon([(x + 28 * SS, y), (x + 44 * SS, y - 10 * SS), (x + 44 * SS, y + 10 * SS)], fill=(196, 206, 214))
    img.resize((512, 192), Image.LANCZOS).save(OUT / "etiquette_sardines.png")


def timbre():
    w, h = 240 * SS, 300 * SS
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, w, h], fill=(246, 242, 232, 255))
    # les dents
    for k in range(0, w, 16 * SS):
        d.ellipse([k + 2 * SS, -6 * SS, k + 12 * SS, 6 * SS], fill=(0, 0, 0, 0))
        d.ellipse([k + 2 * SS, h - 6 * SS, k + 12 * SS, h + 6 * SS], fill=(0, 0, 0, 0))
    for k in range(0, h, 16 * SS):
        d.ellipse([-6 * SS, k + 2 * SS, 6 * SS, k + 12 * SS], fill=(0, 0, 0, 0))
        d.ellipse([w - 6 * SS, k + 2 * SS, w + 6 * SS, k + 12 * SS], fill=(0, 0, 0, 0))
    d.rectangle([20 * SS, 20 * SS, w - 20 * SS, h - 60 * SS], fill=(150, 190, 220, 255))
    d.rectangle([20 * SS, h * 0.55, w - 20 * SS, h - 60 * SS], fill=(40, 90, 150, 255))
    cx = w / 2
    d.polygon([(cx - 4 * SS, h * 0.2), (cx - 4 * SS, h * 0.52), (cx - 60 * SS, h * 0.52)], fill=(250, 250, 245, 255))
    d.polygon([(cx + 2 * SS, h * 0.25), (cx + 2 * SS, h * 0.52), (cx + 44 * SS, h * 0.52)], fill=(236, 230, 214, 255))
    d.polygon([(cx - 60 * SS, h * 0.54), (cx + 56 * SS, h * 0.54), (cx + 40 * SS, h * 0.6), (cx - 46 * SS, h * 0.6)], fill=(140, 70, 40, 255))
    f = police("DejaVuSans-Bold.ttf", 18)
    d.text((26 * SS, h - 52 * SS), "POSTES", fill=(120, 40, 40, 255), font=f)
    d.text((w - 70 * SS, h - 52 * SS), "0,50", fill=(120, 40, 40, 255), font=f)
    img.resize((240, 300), Image.LANCZOS).save(OUT / "timbre.png")


def enseigne_pepin():
    w, h = 512 * SS, 256 * SS
    img = rgb(melange((0.62, 0.12, 0.12), (0.46, 0.08, 0.08), fbm(8, 3, 101, w, h)))
    d = ImageDraw.Draw(img)
    or_ = (236, 204, 120)
    d.rounded_rectangle([10 * SS, 10 * SS, w - 10 * SS, h - 10 * SS], radius=24 * SS, outline=or_, width=5 * SS)
    f = police("DejaVuSerif-Bold.ttf", 44)
    f2 = police("DejaVuSerif-Italic.ttf", 20)
    for (t, ff, y) in [("PÉPIN", f, 0.16), ("farine & pain des Petits", f2, 0.56), ("depuis toujours", f2, 0.72)]:
        bb = d.textbbox((0, 0), t, font=ff)
        d.text(((w - (bb[2] - bb[0])) / 2, h * y), t, fill=or_, font=ff)
    for s in (-1, 1):
        x = w / 2 + s * 170 * SS
        y = h * 0.34
        d.ellipse([x - 26 * SS, y - 16 * SS, x + 26 * SS, y + 16 * SS], fill=(214, 150, 70), outline=or_, width=2 * SS)
        for k in range(3):
            d.line([(x - 14 * SS + k * 12 * SS, y - 10 * SS), (x - 8 * SS + k * 12 * SS, y + 8 * SS)], fill=(150, 90, 40), width=2 * SS)
    img.resize((512, 256), Image.LANCZOS).save(OUT / "enseigne_pepin.png")


# =================================================================== par les fenêtres

def vues(dossier=None):
    """Recadre les vues rendues (dossier : celui de rendu_geants.sh … fenetres) en portrait ; le ciel uni
    de l'outil d'images devient un vrai ciel (bleu, des nuages) ; la nuit : bleuie, assombrie, des
    étoiles dans le ciel."""
    src = Path(dossier) if dossier else None
    if src is None or not src.exists():
        print("vues : il faut le dossier des images de rendu_geants.sh … fenetres")
        return
    for f in sorted(src.glob("vue_*.png")):
        img = Image.open(f).convert("RGB")
        w, h = img.size
        cw = int(h * 0.78)
        img = img.crop(((w - cw) // 2, 0, (w - cw) // 2 + cw, h))
        a = np.array(img).astype(float) / 255.0
        ref = np.array((168, 180, 189)) / 255.0        # le ciel uni de l'outil d'images
        masque = (np.abs(a - ref[None, None, :]).max(axis=-1) < 0.035).astype(float)
        masque = np.array(Image.fromarray((masque * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2))).astype(float) / 255.0
        hh, ww = masque.shape
        yy = np.linspace(0, 1, hh)[:, None] * np.ones((1, ww))
        ciel = melange((0.33, 0.55, 0.88), (0.76, 0.85, 0.94), np.clip(yy * 1.9, 0, 1))
        nuages = np.array(rgb(fbm(3, 5, len(f.stem) * 7 + 3, ww, hh * 3)).resize((ww, hh), Image.LANCZOS)).astype(float) / 255.0
        nu = np.clip((nuages - 0.52) * 3.0, 0, 1) * np.clip(1.25 - yy * 1.5, 0, 1)
        ciel = ciel * (1 - nu[..., None] * 0.85) + np.array((0.98, 0.98, 0.97))[None, None, :] * nu[..., None] * 0.85
        a = a * (1 - masque[..., None]) + ciel * masque[..., None]
        jour = rgb(a).resize((468, 600), Image.LANCZOS)
        jour.save(OUT / (f.stem + "_jour.png"))
        b = np.array(jour).astype(float) / 255.0
        mq = np.array(Image.fromarray((masque * 255).astype(np.uint8)).resize((468, 600), Image.LANCZOS)).astype(float) / 255.0
        nuit = b * np.array((0.06, 0.08, 0.16))[None, None, :] + np.array((0.008, 0.012, 0.035))[None, None, :]
        nuit = nuit * (1 - mq[..., None]) + (np.array((0.02, 0.03, 0.08))[None, None, :] + nuit * 0.3) * mq[..., None]
        rng = np.random.default_rng(len(f.stem))
        for k in range(90):
            y = int(rng.random() * b.shape[0])
            x = int(rng.random() * b.shape[1])
            if mq[y, x] > 0.9:
                v = 0.45 + rng.random() * 0.55
                nuit[y, x] = (v, v, v * 0.95)
                if v > 0.85 and x + 1 < b.shape[1]:
                    nuit[y, x + 1] = (v * 0.5, v * 0.5, v * 0.5)
        rgb(nuit).save(OUT / (f.stem + "_nuit.png"))



# =================================================================== V177 : le château de sable

def _lettres(img, texte, x, y, f, couleurs, rng, pas=6, angle=9.0, ss_w=46, ss_h=58):
    """Des lettres d'enfant : chacune un peu penchée, un peu plus haut ou plus bas."""
    for i, ch in enumerate(texte):
        if ch == " ":
            x += 18 * SS
            continue
        lettre = Image.new("RGBA", (ss_w * SS, ss_h * SS), (0, 0, 0, 0))
        col = couleurs[i % len(couleurs)]
        dl = ImageDraw.Draw(lettre)
        for k in range(2):
            dl.text((4 * SS + k, 2 * SS + k), ch, font=f, fill=col)
        lettre = lettre.rotate(rng.normal(0, angle), resample=Image.BICUBIC)
        img.alpha_composite(lettre, (int(x), int(y + rng.normal(0, 3) * SS)))
        x += (f.getbbox(ch)[2]) + pas * SS
    return x


def panneau_chateau():
    w, h = 640 * SS, 216 * SS
    # le bois flotté : gris-beige, le fil du bois en long, des nœuds, blanchi par le sel
    yy = np.linspace(0, 1, h)[:, None] * np.ones((1, w))
    fil = bruit(3, 41, w, h) * 0.5 + fbm(40, 4, 42, w, h) * 0.5
    veines = (np.sin((yy * 26 + fil * 1.2 + bruit(24, 44, w, h) * 0.25) * math.pi) * 0.5 + 0.5) ** 4
    base = melange((0.74, 0.69, 0.6), (0.6, 0.55, 0.47), fil)
    base = base * (1 - veines[..., None] * 0.12)
    sel = np.clip((fbm(12, 4, 43, w, h) - 0.55) * 3, 0, 1)
    base = base * (1 - sel[..., None] * 0.3) + np.array((0.92, 0.9, 0.86))[None, None, :] * sel[..., None] * 0.3
    img = rgb(base).convert("RGBA")
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(177)
    f = police("DejaVuSans-Bold.ttf", 58)
    x = _lettres(img, "CHÂTEAU", 70 * SS, 8 * SS, f, [(205, 40, 50, 255), (40, 90, 190, 255), (230, 150, 30, 255), (60, 150, 70, 255)], rng)
    f2 = police("DejaVuSans-Bold.ttf", 46)
    _lettres(img, "DES PETITS", 150 * SS, 104 * SS, f2, [(140, 60, 170, 255), (205, 40, 50, 255), (40, 90, 190, 255)], rng, 5)
    # un cœur, un coquillage dessiné, des points (le crayon appuie trop)
    def cire(pts, col, larg=5):
        for k in range(3):
            q = [(px + rng.normal(0, 1.2 * SS), py + rng.normal(0, 1.2 * SS)) for (px, py) in pts]
            d.line(q, fill=col, width=int(larg * SS * (0.6 + 0.2 * k)), joint="curve")
    cx, cy = w * 0.88, h * 0.3
    coeur = [(cx + 16 * SS * (16 * math.sin(t) ** 3) / 16, cy - 16 * SS * (13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)) / 16) for t in np.linspace(0, 2 * math.pi, 40)]
    cire(coeur, (220, 50, 90, 255), 4)
    sx, sy = w * 0.08, h * 0.72
    for k in range(7):
        a = math.pi * (0.15 + 0.7 * k / 6)
        cire([(sx, sy + 18 * SS), (sx + math.cos(a) * 34 * SS, sy + 18 * SS - math.sin(a) * 34 * SS)], (235, 130, 150, 255), 3)
    d.arc([sx - 34 * SS, sy - 16 * SS, sx + 34 * SS, sy + 52 * SS], 200, 340, fill=(235, 130, 150, 255), width=4 * SS)
    img.convert("RGB").resize((640, 216), Image.LANCZOS).save(OUT / "panneau_chateau.png")


def marees():
    w, h = 768 * SS, 512 * SS
    # l'ardoise : gris-vert sombre, les traces de craie effacée
    n = fbm(10, 5, 501, w, h)
    base = melange((0.17, 0.2, 0.2), (0.24, 0.27, 0.26), n)
    efface = np.clip((fbm(4, 4, 502, w, h) - 0.45) * 1.6, 0, 1)
    base = base * (1 - efface[..., None] * 0.25) + np.array((0.55, 0.56, 0.54))[None, None, :] * efface[..., None] * 0.25
    img = rgb(base).convert("RGBA")
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(503)
    craie = (236, 234, 224, 255)

    def trait(pts, col=craie, larg=3):
        for k in range(2):
            q = [(px + rng.normal(0, 0.8 * SS), py + rng.normal(0, 0.8 * SS)) for (px, py) in pts]
            d.line(q, fill=col, width=int(larg * SS), joint="curve")
    f = police("DejaVuSans-Bold.ttf", 40)
    _lettres(img, "MARÉES", 250 * SS, 18 * SS, f, [craie], rng, 4, 4.0)
    # les heures, la courbe de la mer (deux hautes, deux basses), la vague dessinée au-dessus
    x0, x1, y0, y1 = 70 * SS, 720 * SS, 120 * SS, 360 * SS
    trait([(x0, y1 + 20 * SS), (x1, y1 + 20 * SS)], craie, 2)
    f2 = police("DejaVuSans.ttf", 22)
    for i, hh in enumerate(["0 h", "6 h", "12 h", "18 h", "24 h"]):
        xx = x0 + (x1 - x0) * i / 4
        trait([(xx, y1 + 12 * SS), (xx, y1 + 28 * SS)], craie, 2)
        d.text((xx - 20 * SS, y1 + 34 * SS), hh, font=f2, fill=craie)
    pts = []
    for k in range(120):
        t = k / 119
        pts.append((x0 + (x1 - x0) * t, (y0 + y1) / 2 - 10 * SS - math.cos(t * 4 * math.pi - 0.6) * (y1 - y0) * 0.36))
    trait(pts, (150, 200, 235, 255), 4)
    f3 = police("DejaVuSans-Bold.ttf", 22)
    for t, mot in [(0.05, "haute"), (0.3, "basse"), (0.55, "haute"), (0.8, "basse")]:
        xx = x0 + (x1 - x0) * t
        yy = (y0 + y1) / 2 - 10 * SS - math.cos(t * 4 * math.pi - 0.6) * (y1 - y0) * 0.36
        d.text((xx - 26 * SS, yy + (-40 if mot == "haute" else 14) * SS), mot, font=f3, fill=craie)
    # ce qu'il ne faut pas oublier
    f4 = police("DejaVuSans.ttf", 24)
    d.text((40 * SS, 440 * SS), "arroser les murs : matin et soir", font=f4, fill=(240, 220, 150, 255))
    # un petit crabe (Sire Bernard) dans le coin
    cx, cy = 690 * SS, 70 * SS
    d.ellipse([cx - 26 * SS, cy - 18 * SS, cx + 26 * SS, cy + 18 * SS], outline=(240, 150, 120, 255), width=3 * SS)
    for s in (-1, 1):
        trait([(cx + s * 22 * SS, cy - 10 * SS), (cx + s * 40 * SS, cy - 34 * SS)], (240, 150, 120, 255), 3)
        d.ellipse([cx + s * 40 * SS - 9 * SS, cy - 46 * SS, cx + s * 40 * SS + 9 * SS, cy - 30 * SS], outline=(240, 150, 120, 255), width=3 * SS)
        for j in range(3):
            trait([(cx + s * 20 * SS, cy + (j * 6) * SS), (cx + s * 40 * SS, cy + (8 + j * 8) * SS)], (240, 150, 120, 255), 2)
    img.convert("RGB").resize((768, 512), Image.LANCZOS).save(OUT / "marees.png")

TOUT = {
    "vichy_rouge": vichy_rouge,
    "laine": laine,
    "tapis_tresse": tapis_tresse,
    "faience": faience,
    "cadran_comtoise": cadran_comtoise,
    "dessin_paquerette": dessin_paquerette,
    "tableau_moulin": tableau_moulin,
    "calendrier": calendrier,
    "croute": croute,
    "fromage": fromage,
    "sac_farine": sac_farine,
    "etiquette_sardines": etiquette_sardines,
    "timbre": timbre,
    "enseigne_pepin": enseigne_pepin,
    "panneau_chateau": panneau_chateau,
    "marees": marees,
}


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    args = sys.argv[1:]
    if args and args[0] == "vues":
        vues(args[1] if len(args) > 1 else None)
        print("beau174 : vues")
        sys.exit(0)
    for nom in args or list(TOUT):
        TOUT[nom]()
        print("beau174 :", nom)
