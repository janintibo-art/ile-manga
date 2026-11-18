"""V175 : les images de l'Arcade du Dragon-Pixel (Néopolis) et des quatre bus peints (l'Île de Larsen).
Faites ici ; CC0 1.0. Dossier www/assets/textures/beau175/. Toutes les marques sont inventées.

L'arcade :
  moquette_cosmos      la moquette « cosmique » des salles de jeux (planètes, étoiles, éclairs, zigzags
                       fluo sur fond nuit) ; se répète.
  moquette_cosmos_lum  ce qui en luit sous la lumière noire (les motifs seuls) ; se répète.
  affiche_dragon       les affiches des jeux : Dragon-Pixel, Néo-Kart, Carpe Cosmos, Robo-Rythme.
  affiche_kart, affiche_carpe, affiche_rythme
  fronton_dragon       les frontons lumineux en haut des bornes (le nom du jeu, rétroéclairé).
  fronton_kart, fronton_carpe, fronton_rythme
  flanc_eclairs        les flancs peints des bornes (des éclairs ; des planètes).
  flanc_planetes
  neon_jetons          les néons de la salle (lumière sur fond transparent) : JETONS & LOTS, LA PINCE,
  neon_pince           PIXEL-PHOTO, et le grand dragon de néon au-dessus de la salle.
  neon_photo
  neon_dragon
  records              le tableau des meilleurs scores (des lettres de lumière).
  tapis_danse          les quatre flèches de la machine à danser.
  table_palet          le plateau du palet sur coussin d'air (ses trous, ses lignes).
  bande_photo          une bande de photomaton (quatre images, des autocollants).
Les bus :
  vue_prairie_jour     ce qu'on voit par les fenêtres d'un bus du Camp des Fleurs (flou, comme à
  vue_prairie_nuit     travers une vitre) : la prairie, les yourtes, le ciel ; la nuit, les étoiles,
                       le feu de camp, les guirlandes.
  vue_plage_jour       par les fenêtres du bus de la plage : le sable, la mer, le ciel ; la nuit, la lune
  vue_plage_nuit       sur la mer.
  tenture_soleil       la tenture du soleil et de la lune (indigo et or).
  patchwork            le dessus-de-lit en patchwork ; se répète.
  kilim                le tapis tissé.
  indienne             le tissu à petites fleurs des rideaux ; se répète.
  toile_fleurs         les tableaux du bus-atelier (des fleurs, un soleil, des vagues).
  toile_soleil
  toile_vagues
  carte_route          la carte de la route, punaisée : les îles, le chemin du bus en pointillés.

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_textures_v175.py [nom…]
"""
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

RACINE = Path(__file__).resolve().parents[2]
OUT = RACINE / "www" / "assets" / "textures" / "beau175"
DEJAVU = Path("/usr/share/fonts/truetype/dejavu")
GOOGLE = Path("/usr/share/fonts/truetype/google-fonts")

CYAN = (40, 230, 255)
ROSE = (255, 60, 200)
JAUNE = (255, 230, 60)
VERT = (80, 255, 120)
ORANGE = (255, 150, 40)
VIOLET = (170, 90, 255)
BLANC = (240, 240, 255)

## Le petit dragon de l'arcade (le même que sur la réclame de la ville) : X le corps, O l'œil.
DRAGON = ["..XXX.....", ".XXXXX....", "XXOXXXX...", "XXXXXXXXX.", "....XXXXXX", "...XXXXX.X", "..XXXXX...", ".XX..XX...", "XX....XX.."]


def police(chemin, taille):
    try:
        return ImageFont.truetype(str(chemin), int(taille))
    except OSError:
        return ImageFont.load_default()


def gras(taille):
    return police(GOOGLE / "Poppins-Bold.ttf", taille)


def mono(taille):
    return police(DEJAVU / "DejaVuSansMono-Bold.ttf", taille)


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


def degrade(w, h, haut, bas):
    y = np.linspace(0, 1, h)[:, None, None]
    a = np.array(haut, np.float32)[None, None, :]
    b = np.array(bas, np.float32)[None, None, :]
    g = a * (1 - y) + b * y
    return Image.fromarray(np.broadcast_to(g, (h, w, 3)).astype(np.uint8)).convert("RGBA")


def lueur(base, couleur, rayons=(26, 12, 5)):
    """Un tracé blanc (L) devient un néon : des halos de couleur, et un cœur presque blanc."""
    w, h = base.size
    out = np.zeros((h, w, 4), np.float32)
    m = np.asarray(base, np.float32) / 255.0
    col = np.array(couleur, np.float32) / 255.0
    for r, a in zip(rayons, (0.55, 0.8, 1.0)):
        g = np.asarray(base.filter(ImageFilter.GaussianBlur(r)), np.float32) / 255.0
        g = np.clip(g * 2.2, 0, 1) * a
        out[..., :3] += col * g[..., None]
        out[..., 3] = np.maximum(out[..., 3], g)
    coeur = np.clip(m, 0, 1)
    out[..., :3] = out[..., :3] * (1 - coeur[..., None]) + (col * 0.35 + 0.65) * coeur[..., None]
    out[..., 3] = np.maximum(out[..., 3], coeur)
    return Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGBA")


def texte_centre(d, w, h, txt, f, epais=0, dy=0, fill=255):
    bb = d.textbbox((0, 0), txt, font=f, stroke_width=epais)
    x = (w - (bb[2] - bb[0])) / 2 - bb[0]
    y = (h - (bb[3] - bb[1])) / 2 - bb[1] + dy
    d.text((x, y), txt, font=f, fill=fill, stroke_width=epais, stroke_fill=fill)


def contour(t_plein, creuser=9):
    """Le tube suit le bord des lettres : le plein moins son intérieur rétréci."""
    creux = t_plein.filter(ImageFilter.MinFilter(creuser))
    return Image.fromarray(np.clip(np.asarray(t_plein, np.int16) - np.asarray(creux, np.int16), 0, 255).astype(np.uint8))


def pixels(d, motif, x0, y0, p, couleurs, gap=0):
    for j, row in enumerate(motif):
        for i, c in enumerate(row):
            if c in couleurs:
                d.rectangle((x0 + i * p, y0 + j * p, x0 + (i + 1) * p - 1 - gap, y0 + (j + 1) * p - 1 - gap), fill=couleurs[c])


def pixeliser(img, pas):
    w, h = img.size
    return img.resize((max(1, w // pas), max(1, h // pas)), Image.BILINEAR).resize((w, h), Image.NEAREST)


def sauver(img, nom):
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / f"{nom}.png", optimize=True)


# =================================================================== l'arcade : la moquette

def _motifs_cosmos(w, seed):
    """Les motifs fluo de la moquette, dessinés trois fois (pour qu'ils se répètent) : [(couche L, couleur)]."""
    rng = np.random.default_rng(seed)
    cols = [CYAN, ROSE, JAUNE, VERT, ORANGE, VIOLET]
    couches = {c: Image.new("L", (w, w), 0) for c in cols}
    draws = {c: ImageDraw.Draw(couches[c]) for c in cols}
    formes = []
    for k in range(70):
        formes.append((["planete", "etoile", "eclair", "zigzag", "triangle", "rond", "spirale"][k % 7], rng.random() * w, rng.random() * w,
                       cols[int(rng.integers(len(cols)))], rng.uniform(0.6, 1.3), rng.random() * math.tau))
    for kind, x, y, c, s, a in formes:
        for ox in (-w, 0, w):
            for oy in (-w, 0, w):
                d = draws[c]
                cx, cy = x + ox, y + oy
                if kind == "planete":
                    r = 30 * s
                    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=255, width=7)
                    d.ellipse((cx - r * 1.9, cy - r * 0.45, cx + r * 1.9, cy + r * 0.45), outline=255, width=5)
                elif kind == "etoile":
                    r = 26 * s
                    pts = []
                    for i in range(8):
                        rr = r if i % 2 == 0 else r * 0.3
                        pts.append((cx + math.cos(a + i * math.pi / 4) * rr, cy + math.sin(a + i * math.pi / 4) * rr))
                    d.polygon(pts, fill=255)
                elif kind == "eclair":
                    pts = [(0, -40), (14, -6), (2, -4), (18, 40), (-10, 2), (2, 0), (-8, -40)]
                    ca, sa = math.cos(a), math.sin(a)
                    d.polygon([(cx + (px * ca - py * sa) * s, cy + (px * sa + py * ca) * s) for px, py in pts], fill=255)
                elif kind == "zigzag":
                    ca, sa = math.cos(a), math.sin(a)
                    pts = [(cx + ((i - 3) * 16 * ca - (12 if i % 2 else -12) * sa) * s, cy + ((i - 3) * 16 * sa + (12 if i % 2 else -12) * ca) * s) for i in range(7)]
                    d.line(pts, fill=255, width=8, joint="curve")
                elif kind == "triangle":
                    r = 28 * s
                    pts = [(cx + math.cos(a + i * math.tau / 3) * r, cy + math.sin(a + i * math.tau / 3) * r) for i in range(3)]
                    d.polygon(pts, outline=255, width=7)
                elif kind == "rond":
                    r = 9 * s
                    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=255)
                else:
                    pts = []
                    for i in range(60):
                        t = i / 60 * math.tau * 1.6
                        rr = 4 + t * 7 * s
                        pts.append((cx + math.cos(t + a) * rr, cy + math.sin(t + a) * rr))
                    d.line(pts, fill=255, width=6)
    return [(couches[c], c) for c in cols]


def moquette_cosmos():
    w = 1024
    # le fond : un bleu nuit, la laine bouclée (du bruit fin) et des confettis sombres
    fond = fbm(64, 3, 1751, w)
    fin = np.random.default_rng(1752).random((w, w))
    base = melange((0.035, 0.03, 0.09), (0.07, 0.045, 0.15), fond * 0.8 + fin * 0.2)
    lum = np.zeros((w, w, 3), np.float32)
    for couche, c in _motifs_cosmos(w, 1753):
        m = np.asarray(couche.filter(ImageFilter.GaussianBlur(1.2)), np.float32) / 255.0
        col = np.array(c, np.float32) / 255.0
        base = base * (1 - m[..., None]) + col[None, None, :] * (0.75 + 0.25 * fin[..., None]) * m[..., None]
        lum = np.maximum(lum, col[None, None, :] * m[..., None])
    # les brins de la moquette : un peu de grain par-dessus
    grain = (fin - 0.5) * 0.06
    sauver(rgb(base + grain[..., None]), "moquette_cosmos")
    sauver(rgb(lum), "moquette_cosmos_lum")


# =================================================================== l'arcade : les affiches

def _cadre_affiche(im, couleur):
    d = ImageDraw.Draw(im)
    w, h = im.size
    d.rectangle((6, 6, w - 7, h - 7), outline=couleur, width=6)
    d.rectangle((16, 16, w - 17, h - 17), outline=(255, 255, 255, 120), width=2)


def _titre(im, txt, y, taille, couleur, ombre=(0, 0, 0)):
    d = ImageDraw.Draw(im)
    f = gras(taille)
    w = im.size[0]
    bb = d.textbbox((0, 0), txt, font=f, stroke_width=6)
    x = (w - (bb[2] - bb[0])) / 2 - bb[0]
    d.text((x + 6, y + 8), txt, font=f, fill=ombre, stroke_width=6, stroke_fill=ombre)
    d.text((x, y), txt, font=f, fill=couleur, stroke_width=6, stroke_fill=(20, 10, 30))


def _ligne(im, txt, y, taille, couleur):
    d = ImageDraw.Draw(im)
    f = mono(taille)
    w = im.size[0]
    bb = d.textbbox((0, 0), txt, font=f)
    d.text(((w - (bb[2] - bb[0])) / 2 - bb[0], y), txt, font=f, fill=couleur)


def _etoiles(im, n, seed, zone=None):
    d = ImageDraw.Draw(im)
    w, h = im.size
    r = np.random.default_rng(seed)
    for _ in range(n):
        x, y = r.random() * w, r.random() * (zone or h)
        s = r.choice([1, 1, 2, 3])
        a = int(120 + r.random() * 135)
        d.rectangle((x, y, x + s, y + s), fill=(255, 255, 255, a))


def affiche_dragon():
    im = degrade(512, 768, (60, 10, 90), (10, 0, 20))
    _etoiles(im, 160, 1761, 520)
    d = ImageDraw.Draw(im)
    # des montagnes de pixels, la lune carrée
    d.rectangle((370, 90, 450, 170), fill=(255, 240, 180))
    d.rectangle((390, 100, 410, 120), fill=(230, 210, 150))
    r = np.random.default_rng(1762)
    for i in range(0, 512, 16):
        hh = int(140 + 60 * math.sin(i * 0.02) + r.random() * 30)
        d.rectangle((i, 768 - 210 - hh * 0.5, i + 15, 768 - 200), fill=(40, 20, 70))
    d.rectangle((0, 560, 512, 768), fill=(30, 80, 40))
    for i in range(0, 512, 32):
        d.rectangle((i, 560, i + 30, 574), fill=(60, 160, 70))
    # le dragon, en gros pixels, qui crache du feu
    pixels(d, DRAGON, 70, 250, 28, {"X": VERT, "O": (255, 255, 255)}, gap=2)
    for k in range(6):
        c = [(255, 230, 80), (255, 150, 40), (255, 80, 30)][k % 3]
        d.rectangle((345 + k * 22, 330 + (k % 2) * 14, 345 + k * 22 + 20 - k * 2, 350 + (k % 2) * 14 - k), fill=c)
    _titre(im, "DRAGON", 24, 96, VERT)
    _titre(im, "PIXEL", 118, 96, (255, 255, 255))
    _ligne(im, "1 PIÈCE = 3 VIES", 610, 34, (255, 255, 255))
    _ligne(im, "RECORD À BATTRE : 98 700", 660, 26, JAUNE)
    _cadre_affiche(im, VERT)
    sauver(im.convert("RGB"), "affiche_dragon")


def affiche_kart():
    im = degrade(512, 768, (255, 120, 60), (60, 0, 80))
    d = ImageDraw.Draw(im)
    # le soleil couchant rayé
    for k in range(10):
        y0 = 150 + k * 18
        d.rectangle((136, y0, 376, y0 + 14 - k), fill=(255, 220 - k * 12, 80))
    d.pieslice((136, 110, 376, 350), 180, 360, fill=None)
    # la route en perspective, la grille
    hz = 360
    d.rectangle((0, hz, 512, 768), fill=(20, 0, 40))
    for k in range(1, 18):
        y = hz + (k * k) * 1.4
        d.line((0, y, 512, y), fill=ROSE, width=2)
    for k in range(-12, 13):
        d.line((256, hz, 256 + k * 90, 768), fill=ROSE, width=2)
    d.polygon([(236, hz), (276, hz), (430, 768), (82, 768)], fill=(40, 40, 50))
    for k in range(8):
        y0 = hz + 12 + k * k * 6
        d.rectangle((252 - k, y0, 260 + k, y0 + 6 + k * 2), fill=(255, 255, 255))
    # le kart (vu de dos)
    d.rounded_rectangle((176, 560, 336, 640), 18, fill=CYAN)
    d.rectangle((150, 610, 196, 670), fill=(20, 20, 20))
    d.rectangle((316, 610, 362, 670), fill=(20, 20, 20))
    d.ellipse((226, 520, 286, 580), fill=(255, 220, 60))
    d.rectangle((200, 630, 312, 650), fill=(255, 60, 60))
    _titre(im, "NÉO-KART", 30, 92, CYAN)
    _ligne(im, "2 JOUEURS · 8 CIRCUITS", 700, 26, (255, 255, 255))
    _cadre_affiche(im, CYAN)
    sauver(im.convert("RGB"), "affiche_kart")


def affiche_carpe():
    im = degrade(512, 768, (5, 10, 40), (0, 0, 10))
    _etoiles(im, 260, 1771)
    d = ImageDraw.Draw(im)
    # une planète à anneaux
    d.ellipse((330, 120, 470, 260), fill=(180, 90, 255))
    d.arc((290, 170, 510, 210), 0, 360, fill=(255, 200, 255), width=6)
    # la carpe-vaisseau (la carpe des hologrammes de la place)
    carpe = ["....OOO.....", "..OOOOOOO...", ".OOWOOOOOOO.", "OOOOOOOOOOOOO", ".OOOOOOOOOO..", "..OOOOOOO..O.", "....OOO....OO"]
    pixels(d, carpe, 90, 360, 26, {"O": ORANGE, "W": (255, 255, 255)}, gap=2)
    for k in range(5):
        d.rectangle((60 - k * 10, 420 + k * 6, 84 - k * 10, 430 + k * 6), fill=CYAN)
    # les envahisseurs (des méduses de pixels)
    meduse = [".XXX.", "XXXXX", "X.X.X", "X...X"]
    for i, (x, y) in enumerate([(120, 200), (220, 170), (60, 140)]):
        pixels(d, meduse, x, y, 12, {"X": ROSE if i % 2 else VERT})
    _titre(im, "CARPE", 560, 88, ORANGE)
    _titre(im, "COSMOS", 650, 70, (255, 255, 255))
    _ligne(im, "L'ESPACE EST UNE MARE", 40, 26, CYAN)
    _cadre_affiche(im, ORANGE)
    sauver(im.convert("RGB"), "affiche_carpe")


def affiche_rythme():
    im = degrade(512, 768, (20, 0, 50), (90, 0, 90))
    d = ImageDraw.Draw(im)
    # des rayons de lumière
    for k in range(9):
        a = -0.9 + k * 0.22
        d.polygon([(256, 300), (256 + math.sin(a) * 700, 300 - math.cos(a) * 700), (256 + math.sin(a + 0.08) * 700, 300 - math.cos(a + 0.08) * 700)], fill=(255, 255, 255, 40))
    # le robot qui danse (des cubes)
    d.rounded_rectangle((206, 210, 306, 290), 14, fill=(200, 210, 230))
    d.rectangle((226, 236, 246, 256), fill=CYAN)
    d.rectangle((266, 236, 286, 256), fill=CYAN)
    d.rectangle((236, 270, 276, 278), fill=(40, 40, 60))
    d.rounded_rectangle((196, 300, 316, 420), 16, fill=(170, 180, 205))
    d.line((196, 320, 130, 260), fill=(170, 180, 205), width=26)
    d.line((316, 320, 390, 380), fill=(170, 180, 205), width=26)
    d.line((226, 420, 200, 520), fill=(170, 180, 205), width=28)
    d.line((286, 420, 330, 500), fill=(170, 180, 205), width=28)
    d.ellipse((240, 340, 272, 372), fill=ROSE)
    # les flèches
    fl = [((90, 590), 0, ROSE), ((200, 590), 1, CYAN), ((310, 590), 2, VERT), ((420, 590), 3, JAUNE)]
    for (x, y), rot, c in fl:
        pts = [(0, -34), (30, 0), (12, 0), (12, 30), (-12, 30), (-12, 0), (-30, 0)]
        a = rot * math.pi / 2
        d.polygon([(x + px * math.cos(a) - py * math.sin(a), y + px * math.sin(a) + py * math.cos(a)) for px, py in pts], fill=c)
    _titre(im, "ROBO", 30, 92, ROSE)
    _titre(im, "RYTHME", 120, 80, (255, 255, 255))
    _ligne(im, "DANSE AVEC LES ROBOTS !", 680, 26, (255, 255, 255))
    _cadre_affiche(im, ROSE)
    sauver(im.convert("RGB"), "affiche_rythme")


# =================================================================== l'arcade : les frontons, les flancs

def _fronton(nom, txt, couleur, fond_haut, fond_bas, deco, maxw=900):
    w, h = 1024, 256
    im = degrade(w, h, fond_haut, fond_bas)
    d = ImageDraw.Draw(im)
    deco(d, w, h)
    taille = 132
    while True:
        f = gras(taille)
        bb = d.textbbox((0, 0), txt, font=f, stroke_width=8)
        if bb[2] - bb[0] <= maxw or taille < 40:
            break
        taille -= 4
    x = (w - (bb[2] - bb[0])) / 2 - bb[0]
    y = (h - (bb[3] - bb[1])) / 2 - bb[1]
    d.text((x + 8, y + 10), txt, font=f, fill=(0, 0, 0), stroke_width=8, stroke_fill=(0, 0, 0))
    d.text((x, y), txt, font=f, fill=couleur, stroke_width=8, stroke_fill=(255, 255, 255))
    d.rectangle((0, 0, w - 1, h - 1), outline=(255, 255, 255), width=8)
    sauver(im.convert("RGB"), nom)


def fronton_dragon():
    def deco(d, w, h):
        pixels(d, DRAGON, 26, 44, 18, {"X": VERT, "O": (255, 255, 255)}, gap=1)
        pixels(d, [row[::-1] for row in DRAGON], w - 26 - 180, 44, 18, {"X": VERT, "O": (255, 255, 255)}, gap=1)
        for k in range(14):
            d.rectangle((246 + k * 38, 214, 266 + k * 38, 238), fill=[(255, 230, 80), (255, 150, 40), (255, 80, 30)][k % 3])
    _fronton("fronton_dragon", "DRAGON-PIXEL", VERT, (60, 0, 90), (10, 0, 30), deco, 560)


def fronton_kart():
    def deco(d, w, h):
        for k in range(12):
            d.rectangle((k * 90, 0, k * 90 + 44, 30), fill=(255, 255, 255))
            d.rectangle((k * 90 + 44, 226, k * 90 + 90, 256), fill=(255, 255, 255))
    _fronton("fronton_kart", "NÉO-KART", CYAN, (255, 90, 60), (90, 0, 90), deco)


def fronton_carpe():
    def deco(d, w, h):
        r = np.random.default_rng(1781)
        for _ in range(120):
            x, y = r.random() * w, r.random() * h
            d.rectangle((x, y, x + 3, y + 3), fill=(255, 255, 255))
    _fronton("fronton_carpe", "CARPE COSMOS", ORANGE, (10, 20, 70), (0, 0, 20), deco)


def fronton_rythme():
    def deco(d, w, h):
        for k in range(14):
            c = [ROSE, CYAN, VERT, JAUNE][k % 4]
            d.polygon([(40 + k * 72, 200), (70 + k * 72, 170), (100 + k * 72, 200)], fill=c)
    _fronton("fronton_rythme", "ROBO-RYTHME", ROSE, (40, 0, 80), (120, 0, 120), deco)


def flanc_eclairs():
    w, h = 512, 1024
    im = degrade(w, h, (30, 10, 60), (5, 0, 15))
    d = ImageDraw.Draw(im)
    for k, c in enumerate([ROSE, CYAN, JAUNE]):
        x0 = 80 + k * 140
        pts = [(x0, 0), (x0 + 60, 260), (x0 + 10, 280), (x0 + 90, 600), (x0 + 30, 620), (x0 + 120, 1024), (x0 + 60, 1024), (x0 - 20, 640),
               (x0 + 40, 620), (x0 - 40, 300), (x0 + 10, 280), (x0 - 50, 0)]
        d.polygon(pts, fill=c)
    d.rectangle((0, 0, w - 1, h - 1), outline=(10, 10, 10), width=10)
    sauver(im.convert("RGB"), "flanc_eclairs")


def flanc_planetes():
    w, h = 512, 1024
    im = degrade(w, h, (10, 20, 70), (40, 0, 60))
    _etoiles(im, 200, 1791)
    d = ImageDraw.Draw(im)
    for (x, y, r, c) in [(150, 220, 90, ORANGE), (370, 520, 60, VIOLET), (180, 800, 120, CYAN)]:
        d.ellipse((x - r, y - r, x + r, y + r), fill=c)
        d.ellipse((x - r * 0.7, y - r * 0.8, x + r * 0.2, y - r * 0.1), fill=tuple(min(255, int(v * 1.25)) for v in c))
        d.arc((x - r * 1.8, y - r * 0.4, x + r * 1.8, y + r * 0.4), 200, 520, fill=(255, 255, 255), width=8)
    d.rectangle((0, 0, w - 1, h - 1), outline=(10, 10, 10), width=10)
    sauver(im.convert("RGB"), "flanc_planetes")


# =================================================================== l'arcade : les néons, les écrans

def _neon(nom, txt, couleur, taille=150, cadre=True, w=1024, h=256, fonte=None):
    f = fonte or gras(taille)

    def des(img):
        d = ImageDraw.Draw(img)
        texte_centre(d, w, h, txt, f)
        return img

    plein = des(Image.new("L", (w, h), 0))
    t = contour(plein, 11)
    if cadre:
        d = ImageDraw.Draw(t)
        d.rounded_rectangle((18, 18, w - 18, h - 18), radius=40, outline=255, width=7)
    sauver(lueur(t, couleur), nom)


def neon_jetons():
    _neon("neon_jetons", "JETONS & LOTS", JAUNE, 120)


def neon_pince():
    _neon("neon_pince", "LA PINCE", ROSE, 150)


def neon_photo():
    _neon("neon_photo", "PIXEL-PHOTO", CYAN, 130)


def neon_dragon():
    """Le grand dragon de néon (le contour de chaque gros pixel), et son nom dessous."""
    w, h = 1024, 512
    t = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(t)
    p = 34
    x0, y0 = 60, 60
    for j, row in enumerate(DRAGON):
        for i, c in enumerate(row):
            if c == "X":
                d.rectangle((x0 + i * p, y0 + j * p, x0 + (i + 1) * p - 6, y0 + (j + 1) * p - 6), outline=255, width=5)
    f = gras(110)
    plein = Image.new("L", (w, h), 0)
    texte_centre(ImageDraw.Draw(plein), 560, 200, "DRAGON", f)
    plein2 = Image.new("L", (w, h), 0)
    texte_centre(ImageDraw.Draw(plein2), 560, 200, "PIXEL", f)
    tt = Image.new("L", (w, h), 0)
    tt.paste(contour(plein, 9).crop((0, 0, 560, 200)), (430, 90))
    tt.paste(contour(plein2, 9).crop((0, 0, 560, 200)), (430, 250))
    t = Image.fromarray(np.maximum(np.asarray(t), np.asarray(tt)))
    v = lueur(t, VERT)
    # les flammes, en orange, par-dessus
    fl = Image.new("L", (w, h), 0)
    df = ImageDraw.Draw(fl)
    for k in range(4):
        df.rectangle((370 + k * 22, 160 + (k % 2) * 14, 386 + k * 22, 176 + (k % 2) * 14), outline=255, width=4)
    o = lueur(fl, ORANGE, (16, 8, 3))
    v.alpha_composite(o)
    sauver(v, "neon_dragon")


def records():
    """Le tableau des meilleurs scores : des lettres de lumière (une grille de diodes)."""
    w, h = 512, 640
    im = Image.new("RGB", (w, h), (4, 4, 10))
    d = ImageDraw.Draw(im)
    lignes = [("MEILLEURS SCORES", ROSE), ("", BLANC), ("1. TURBO  98 700", JAUNE), ("2. TURBO  91 200", CYAN), ("3. MIO    88 800", VERT),
              ("4. GLITCH 75 400", ORANGE), ("5. KIKU   70 000", VIOLET), ("6. ZERO   64 300", CYAN), ("7. HIRO   59 900", ROSE),
              ("8. ???    00 100", (140, 140, 160))]
    f = mono(34)
    for i, (txt, c) in enumerate(lignes):
        bb = d.textbbox((0, 0), txt, font=f)
        d.text(((w - (bb[2] - bb[0])) / 2 - bb[0], 30 + i * 62), txt, font=f, fill=c)
    im = pixeliser(im, 4)
    a = np.asarray(im, np.float32)
    # les diodes : une grille de points
    yy, xx = np.mgrid[0:h, 0:w]
    grille = ((xx % 4 != 3) & (yy % 4 != 3)).astype(np.float32)
    a = a * (0.25 + 0.75 * grille[..., None])
    glow = np.asarray(Image.fromarray(a.astype(np.uint8)).filter(ImageFilter.GaussianBlur(3)), np.float32)
    sauver(Image.fromarray(np.clip(a + glow * 0.6, 0, 255).astype(np.uint8)), "records")


def tapis_danse():
    w = 512
    im = Image.new("RGB", (w, w), (30, 30, 40))
    d = ImageDraw.Draw(im)
    cases = {(1, 0): (0, ROSE), (0, 1): (3, CYAN), (2, 1): (1, VERT), (1, 2): (2, JAUNE)}
    for i in range(3):
        for j in range(3):
            x0, y0 = i * w // 3, j * w // 3
            d.rectangle((x0 + 6, y0 + 6, x0 + w // 3 - 7, y0 + w // 3 - 7), fill=(55, 55, 70), outline=(120, 120, 140), width=4)
            if (i, j) in cases:
                rot, c = cases[(i, j)]
                cx, cy = x0 + w // 6, y0 + w // 6
                pts = [(0, -56), (52, 0), (20, 0), (20, 50), (-20, 50), (-20, 0), (-52, 0)]
                a = rot * math.pi / 2
                d.polygon([(cx + px * math.cos(a) - py * math.sin(a), cy + px * math.sin(a) + py * math.cos(a)) for px, py in pts], fill=c, outline=(255, 255, 255))
    d.ellipse((w // 2 - 30, w // 2 - 30, w // 2 + 30, w // 2 + 30), fill=(90, 90, 110))
    sauver(im, "tapis_danse")


def table_palet():
    w, h = 512, 1024
    im = Image.new("RGB", (w, h), (20, 70, 170))
    d = ImageDraw.Draw(im)
    for y in range(12, h, 24):
        for x in range(12, w, 24):
            d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=(10, 40, 110))
    d.line((0, h // 2, w, h // 2), fill=(255, 60, 80), width=8)
    d.ellipse((w // 2 - 90, h // 2 - 90, w // 2 + 90, h // 2 + 90), outline=(255, 60, 80), width=8)
    for yy in (0, h):
        d.arc((w // 2 - 130, yy - 130, w // 2 + 130, yy + 130), 0, 360, fill=(255, 255, 255), width=8)
    pixels(d, DRAGON, w // 2 - 75, h // 2 - 70, 15, {"X": (60, 130, 230), "O": (60, 130, 230)})
    sauver(im, "table_palet")


def bande_photo():
    w, h = 256, 768
    im = Image.new("RGB", (w, h), (250, 250, 245))
    d = ImageDraw.Draw(im)
    fonds = [(255, 180, 210), (170, 230, 255), (200, 255, 180), (255, 230, 150)]
    for k in range(4):
        y0 = 16 + k * 186
        d.rectangle((16, y0, w - 16, y0 + 170), fill=fonds[k])
        # deux silhouettes rigolotes (des bonshommes ronds), des autocollants
        for s, x in enumerate((80, 170)):
            d.ellipse((x - 34, y0 + 40, x + 34, y0 + 108), fill=(250, 220, 190) if s == 0 else (200, 150, 110))
            d.rectangle((x - 40, y0 + 108, x + 40, y0 + 170), fill=[ROSE, CYAN, VERT, VIOLET][(k + s) % 4])
            d.ellipse((x - 14, y0 + 62, x - 6, y0 + 70), fill=(30, 30, 30))
            d.ellipse((x + 6, y0 + 62, x + 14, y0 + 70), fill=(30, 30, 30))
            d.arc((x - 16, y0 + 70, x + 16, y0 + 96), 20, 160, fill=(30, 30, 30), width=3)
        etoile = [(0, -16), (5, -5), (16, 0), (5, 5), (0, 16), (-5, 5), (-16, 0), (-5, -5)]
        for (ex, ey, c) in [(40, y0 + 26, JAUNE), (210, y0 + 40, ROSE), (128, y0 + 20, CYAN)]:
            d.polygon([(ex + px, ey + py) for px, py in etoile], fill=c)
        if k == 2:
            d.text((40, y0 + 4), "NÉOPOLIS !", font=gras(28), fill=(80, 40, 120))
    sauver(im, "bande_photo")


# =================================================================== les bus : ce qu'on voit par les fenêtres

def _flou(im, r):
    return im.filter(ImageFilter.GaussianBlur(r))


def vue_prairie(nuit):
    w, h = 1024, 512
    r = np.random.default_rng(1801)
    if nuit:
        im = degrade(w, h, (8, 12, 40), (30, 40, 70))
        _etoiles(im, 260, 1802, 300)
    else:
        im = degrade(w, h, (120, 175, 235), (210, 230, 245))
    d = ImageDraw.Draw(im, "RGBA")
    if not nuit:
        for _ in range(9):
            x, y = r.random() * w, 40 + r.random() * 150
            for k in range(6):
                d.ellipse((x + k * 26 - 40, y - 18 + (k % 2) * 8, x + k * 26 + 30, y + 22), fill=(255, 255, 255, 170))
    # les collines au loin, les arbres
    hz = 300
    d.polygon([(0, hz)] + [(x, hz - 40 - 30 * math.sin(x * 0.006) - 15 * math.sin(x * 0.021)) for x in range(0, w + 16, 16)] + [(w, h), (0, h)],
              fill=(40, 60, 70, 255) if nuit else (110, 150, 95, 255))
    for _ in range(14):
        x = r.random() * w
        y = hz - 30 + r.random() * 20
        s = 20 + r.random() * 30
        d.ellipse((x - s, y - s * 1.6, x + s, y + s * 0.4), fill=(25, 40, 45, 255) if nuit else (70, 115, 65, 255))
    # la prairie, les yourtes
    d.rectangle((0, hz + 10, w, h), fill=(30, 50, 40, 255) if nuit else (120, 175, 80, 255))
    for k, x in enumerate([140, 420, 760, 930]):
        s = [1.0, 0.75, 1.15, 0.8][k]
        y = hz + 70 + k * 6
        c = [(235, 225, 205), (220, 120, 60), (240, 230, 210), (90, 140, 170)][k]
        if nuit:
            c = tuple(int(v * 0.35) for v in c)
        d.polygon([(x - 70 * s, y), (x + 70 * s, y), (x + 70 * s, y - 45 * s), (x, y - 85 * s), (x - 70 * s, y - 45 * s)], fill=c + (255,))
        d.rectangle((x - 12 * s, y - 36 * s, x + 12 * s, y), fill=(250, 180, 80, 255) if nuit else (120, 70, 40, 255))
    # des fleurs, au premier plan
    for _ in range(500):
        x, y = r.random() * w, hz + 40 + r.random() * (h - hz - 40)
        c = [(250, 90, 120), (255, 220, 70), (255, 255, 255), (180, 120, 255), (255, 140, 40)][int(r.integers(5))]
        if nuit:
            c = tuple(int(v * 0.3) for v in c)
        s = 2 + (y - hz) * 0.03
        d.ellipse((x - s, y - s, x + s, y + s), fill=c + (255,))
    if nuit:
        # le feu de camp, les guirlandes (des points flous)
        d.ellipse((560, hz + 70, 620, hz + 110), fill=(255, 150, 50, 255))
        lum = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        dl = ImageDraw.Draw(lum)
        dl.ellipse((490, hz + 10, 690, hz + 150), fill=(255, 130, 40, 150))
        for k in range(30):
            x = 60 + k * 32
            y = hz - 10 + 18 * math.sin(k * 0.6) ** 2
            dl.ellipse((x - 7, y - 7, x + 7, y + 7), fill=[(255, 200, 80, 255), (255, 120, 180, 255), (120, 220, 255, 255)][k % 3])
        im = Image.alpha_composite(im, _flou(lum, 6))
    im = _flou(im, 3.0)
    sauver(im.convert("RGB"), "vue_prairie_nuit" if nuit else "vue_prairie_jour")


def vue_plage(nuit):
    w, h = 1024, 512
    r = np.random.default_rng(1811)
    im = degrade(w, h, (10, 15, 45) if nuit else (100, 170, 235), (40, 50, 90) if nuit else (200, 225, 245))
    d = ImageDraw.Draw(im, "RGBA")
    hz = 250
    if nuit:
        _etoiles(im, 220, 1812, hz)
        d.ellipse((720, 70, 790, 140), fill=(250, 245, 225, 255))
    else:
        for _ in range(7):
            x, y = r.random() * w, 40 + r.random() * 120
            for k in range(5):
                d.ellipse((x + k * 30 - 40, y - 16, x + k * 30 + 34, y + 18), fill=(255, 255, 255, 180))
    d.rectangle((0, hz, w, hz + 120), fill=(20, 35, 70, 255) if nuit else (40, 120, 170, 255))
    for k in range(40):
        y = hz + 6 + k * 3
        d.line((0, y, w, y), fill=(255, 255, 255, 25 if not nuit else 12), width=1)
    if nuit:
        for k in range(30):
            y = hz + 4 + k * 4
            ww = 10 + k * 3
            d.rectangle((755 - ww, y, 755 + ww, y + 1), fill=(240, 235, 210, 160 - k * 4))
    # l'écume, le sable
    d.polygon([(0, hz + 120)] + [(x, hz + 115 + 8 * math.sin(x * 0.03)) for x in range(0, w + 8, 8)] + [(w, h), (0, h)],
              fill=(80, 75, 70, 255) if nuit else (235, 215, 170, 255))
    for x in range(0, w, 6):
        y = hz + 114 + 8 * math.sin(x * 0.03)
        d.ellipse((x - 4, y - 3, x + 4, y + 3), fill=(255, 255, 255, 60 if nuit else 200))
    for _ in range(80):
        x, y = r.random() * w, hz + 140 + r.random() * (h - hz - 140)
        d.ellipse((x - 3, y - 2, x + 3, y + 2), fill=(200, 180, 140, 255) if not nuit else (60, 55, 50, 255))
    im = _flou(im, 3.0)
    sauver(im.convert("RGB"), "vue_plage_nuit" if nuit else "vue_plage_jour")


# =================================================================== les bus : les tissus, les tableaux

def tenture_soleil():
    w = 512
    im = Image.new("RGB", (w, w), (30, 30, 90))
    a = np.asarray(im, np.float32)
    n = fbm(8, 3, 1821, w)
    a = a * (0.85 + 0.3 * n[..., None])
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))
    d = ImageDraw.Draw(im)
    or_ = (240, 190, 70)
    c = w / 2
    # le soleil : des rayons, des pétales, un visage endormi
    for k in range(24):
        ang = k * math.tau / 24
        r0, r1 = 120, 200 if k % 2 == 0 else 170
        d.polygon([(c + math.cos(ang - 0.08) * r0, c + math.sin(ang - 0.08) * r0), (c + math.cos(ang) * r1, c + math.sin(ang) * r1),
                   (c + math.cos(ang + 0.08) * r0, c + math.sin(ang + 0.08) * r0)], fill=or_)
    d.ellipse((c - 118, c - 118, c + 118, c + 118), outline=or_, width=6)
    d.ellipse((c - 100, c - 100, c + 100, c + 100), fill=(240, 160, 60))
    # la lune, dedans, un croissant
    d.ellipse((c - 70, c - 70, c + 70, c + 70), fill=(250, 230, 170))
    d.ellipse((c - 40, c - 80, c + 90, c + 60), fill=(240, 160, 60))
    d.arc((c - 50, c - 10, c - 20, c + 10), 200, 340, fill=(90, 50, 30), width=4)
    # les étoiles et les points autour, la bordure
    for k in range(36):
        ang = k * math.tau / 36
        x, y = c + math.cos(ang) * 225, c + math.sin(ang) * 225
        d.ellipse((x - 5, y - 5, x + 5, y + 5), fill=or_)
    for (x, y) in [(60, 60), (452, 60), (60, 452), (452, 452)]:
        d.polygon([(x, y - 22), (x + 7, y - 7), (x + 22, y), (x + 7, y + 7), (x, y + 22), (x - 7, y + 7), (x - 22, y), (x - 7, y - 7)], fill=or_)
    d.rectangle((8, 8, w - 9, w - 9), outline=(200, 80, 60), width=10)
    sauver(im, "tenture_soleil")


def _fleurs_motif(d, x, y, s, c, coeur):
    for k in range(5):
        a = k * math.tau / 5
        d.ellipse((x + math.cos(a) * s - s * 0.6, y + math.sin(a) * s - s * 0.6, x + math.cos(a) * s + s * 0.6, y + math.sin(a) * s + s * 0.6), fill=c)
    d.ellipse((x - s * 0.5, y - s * 0.5, x + s * 0.5, y + s * 0.5), fill=coeur)


def patchwork():
    w = 512
    im = Image.new("RGB", (w, w))
    d = ImageDraw.Draw(im)
    r = np.random.default_rng(1831)
    fonds = [(200, 70, 60), (240, 190, 80), (80, 140, 120), (90, 110, 180), (230, 140, 160), (245, 235, 210), (150, 90, 140), (120, 170, 90)]
    n = 4
    pas = w // n
    for i in range(n):
        for j in range(n):
            f = fonds[int(r.integers(len(fonds)))]
            x0, y0 = i * pas, j * pas
            d.rectangle((x0, y0, x0 + pas, y0 + pas), fill=f)
            sorte = int(r.integers(4))
            c2 = tuple(min(255, int(v * 0.6 + 110)) for v in f)
            if sorte == 0:
                for yy in range(y0 + 10, y0 + pas, 22):
                    for xx in range(x0 + 10 + (yy // 22 % 2) * 11, x0 + pas, 22):
                        d.ellipse((xx - 4, yy - 4, xx + 4, yy + 4), fill=c2)
            elif sorte == 1:
                for k in range(0, pas, 16):
                    d.rectangle((x0 + k, y0, x0 + k + 7, y0 + pas), fill=c2)
            elif sorte == 2:
                for yy in range(y0 + 22, y0 + pas, 44):
                    for xx in range(x0 + 22, x0 + pas, 44):
                        _fleurs_motif(d, xx, yy, 8, c2, (250, 220, 90))
            else:
                d.polygon([(x0, y0), (x0 + pas, y0), (x0, y0 + pas)], fill=c2)
            # la couture (des points)
            for k in range(0, pas, 10):
                d.line((x0 + k, y0 + 3, x0 + k + 5, y0 + 3), fill=(250, 245, 230), width=2)
                d.line((x0 + 3, y0 + k, x0 + 3, y0 + k + 5), fill=(250, 245, 230), width=2)
    a = np.asarray(im, np.float32) * (0.9 + 0.15 * fbm(32, 2, 1832, w)[..., None])
    sauver(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)), "patchwork")


def kilim():
    """Le tapis tissé de l'allée du bus (en long : 2,7 fois plus long que large)."""
    w, h = 1024, 384
    im = Image.new("RGB", (w, h), (170, 50, 40))
    d = ImageDraw.Draw(im)
    bords = [(240, 200, 120), (40, 60, 90), (230, 230, 210)]
    for k, c in enumerate(bords):
        m = 12 + k * 16
        d.rectangle((m, m, w - m, h - m), outline=c, width=10)
    for col in range(7):
        cx = 92 + col * 140
        cy = h // 2
        c = [(240, 200, 120), (40, 60, 90), (230, 230, 210), (80, 140, 120)][col % 4]
        d.polygon([(cx, cy - 90), (cx + 62, cy), (cx, cy + 90), (cx - 62, cy)], fill=c)
        d.polygon([(cx, cy - 46), (cx + 32, cy), (cx, cy + 46), (cx - 32, cy)], fill=(170, 50, 40))
        d.rectangle((cx - 8, cy - 8, cx + 8, cy + 8), fill=(250, 240, 220))
        for sy in (-1, 1):
            d.polygon([(cx - 20, cy + sy * 120), (cx, cy + sy * 104), (cx + 20, cy + sy * 120), (cx, cy + sy * 136)], fill=(240, 200, 120))
    # les franges, aux deux bouts
    for y in range(4, h - 4, 7):
        d.line((0, y, 10, y + 2), fill=(235, 225, 200), width=3)
        d.line((w - 10, y, w, y + 2), fill=(235, 225, 200), width=3)
    a = np.asarray(im, np.float32)
    fil = (np.sin(np.arange(w) * 1.7)[None, :] * 0.04 + 1.0) * (0.9 + 0.15 * fbm(48, 2, 1841, w, h))
    a = a * fil[..., None]
    sauver(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)), "kilim")


def indienne():
    w = 256
    im = Image.new("RGB", (w, w), (245, 232, 205))
    d = ImageDraw.Draw(im)
    pts = [(32, 32), (160, 32), (96, 128), (224, 128), (32, 224), (160, 224)]
    for k, (x, y) in enumerate(pts):
        c = [(200, 70, 80), (60, 110, 160), (220, 140, 50)][k % 3]
        for ox in (-w, 0, w):
            for oy in (-w, 0, w):
                _fleurs_motif(d, x + ox, y + oy, 11, c, (250, 215, 90))
                d.line((x + ox + 14, y + oy + 14, x + ox + 34, y + oy + 30), fill=(90, 140, 80), width=3)
                d.ellipse((x + ox + 26, y + oy + 22, x + ox + 40, y + oy + 32), fill=(110, 160, 90))
    sauver(im, "indienne")


def _toile_fond(seed, c0, c1):
    w = 512
    n = fbm(6, 4, seed, w)
    return rgb(melange(c0, c1, n)).convert("RGBA")


def _touches(d, r, n, zone, couleurs, taille):
    x0, y0, x1, y1 = zone
    for _ in range(n):
        x, y = x0 + r.random() * (x1 - x0), y0 + r.random() * (y1 - y0)
        a = r.random() * math.pi
        c = couleurs[int(r.integers(len(couleurs)))]
        l = taille * (0.6 + r.random() * 0.8)
        d.line((x - math.cos(a) * l, y - math.sin(a) * l, x + math.cos(a) * l, y + math.sin(a) * l), fill=c, width=int(taille * 0.5))


def toile_fleurs():
    im = _toile_fond(1851, (0.95, 0.85, 0.55), (0.98, 0.65, 0.45))
    d = ImageDraw.Draw(im)
    r = np.random.default_rng(1852)
    _touches(d, r, 400, (0, 0, 512, 512), [(250, 200, 120), (250, 170, 110), (240, 220, 160)], 14)
    for k in range(9):
        x, y = 70 + (k % 3) * 180 + r.random() * 30, 100 + (k // 3) * 150 + r.random() * 30
        c = [(220, 50, 70), (250, 120, 160), (140, 80, 200), (250, 200, 40)][k % 4]
        d.line((x, y, x + r.random() * 20 - 10, 512), fill=(70, 130, 60), width=7)
        _fleurs_motif(d, x, y, 26, c, (250, 220, 60))
    sauver(im.convert("RGB"), "toile_fleurs")


def toile_soleil():
    im = _toile_fond(1861, (0.2, 0.55, 0.75), (0.95, 0.75, 0.4))
    d = ImageDraw.Draw(im)
    r = np.random.default_rng(1862)
    for k in range(16):
        a = k * math.tau / 16
        d.line((256, 220, 256 + math.cos(a) * 240, 220 + math.sin(a) * 240), fill=(250, 210, 80), width=14)
    d.ellipse((166, 130, 346, 310), fill=(250, 150, 40))
    d.ellipse((196, 160, 316, 280), fill=(250, 200, 70))
    _touches(d, r, 160, (0, 380, 512, 512), [(60, 120, 60), (90, 160, 70), (40, 90, 50)], 16)
    sauver(im.convert("RGB"), "toile_soleil")


def toile_vagues():
    im = _toile_fond(1871, (0.15, 0.35, 0.6), (0.4, 0.75, 0.85))
    d = ImageDraw.Draw(im)
    for k in range(9):
        y = 120 + k * 46
        c = [(250, 250, 255), (120, 200, 230), (30, 90, 160)][k % 3]
        pts = [(x, y + 26 * math.sin(x * 0.025 + k)) for x in range(-10, 530, 8)]
        d.line(pts, fill=c, width=14)
        for x in range(0, 512, 64):
            yy = y + 26 * math.sin(x * 0.025 + k)
            d.arc((x - 18, yy - 30, x + 18, yy + 6), 180, 360, fill=(255, 255, 255), width=6)
    d.ellipse((380, 40, 470, 130), fill=(250, 240, 200))
    sauver(im.convert("RGB"), "toile_vagues")


def carte_route():
    w, h = 768, 512
    n = fbm(8, 4, 1881, w, h)
    im = rgb(melange((0.95, 0.91, 0.8), (0.82, 0.74, 0.58), n * 0.8)).convert("RGBA")
    d = ImageDraw.Draw(im)
    mer = (150, 190, 205)
    d.rectangle((20, 20, w - 20, h - 20), fill=mer + (90,))
    iles = [(130, 120, 70, "Larsen"), (360, 300, 90, "Néopolis"), (600, 140, 60, "Montjoie"), (560, 380, 50, "Al Dente"), (240, 400, 40, "Moaïs")]
    r = np.random.default_rng(1882)
    for x, y, s, nom in iles:
        pts = [(x + math.cos(a) * s * (0.8 + 0.35 * r.random()), y + math.sin(a) * s * (0.6 + 0.3 * r.random())) for a in np.linspace(0, math.tau, 18, endpoint=False)]
        d.polygon(pts, fill=(225, 205, 150, 255), outline=(120, 90, 60, 255))
        d.text((x - 30, y - 8), nom, font=police(DEJAVU / "DejaVuSerif-Italic.ttf", 20), fill=(70, 50, 30))
    # le chemin du bus (en pointillés : il roule sur la plage, puis… « un jour, le bac »)
    chemin = [(130, 120), (200, 200), (290, 250), (360, 300), (470, 220), (600, 140)]
    for (a, b) in zip(chemin, chemin[1:]):
        for t in np.linspace(0, 1, 9)[:-1]:
            x = a[0] + (b[0] - a[0]) * t
            y = a[1] + (b[1] - a[1]) * t
            d.ellipse((x - 3, y - 3, x + 3, y + 3), fill=(200, 50, 60))
    d.text((300, 460), "un jour, on ira partout", font=police(DEJAVU / "DejaVuSerif-Italic.ttf", 24), fill=(90, 40, 40))
    d.rectangle((6, 6, w - 7, h - 7), outline=(120, 90, 60), width=4)
    sauver(im.convert("RGB"), "carte_route")


TOUTES = {
    "moquette_cosmos": moquette_cosmos,
    "affiche_dragon": affiche_dragon, "affiche_kart": affiche_kart, "affiche_carpe": affiche_carpe, "affiche_rythme": affiche_rythme,
    "fronton_dragon": fronton_dragon, "fronton_kart": fronton_kart, "fronton_carpe": fronton_carpe, "fronton_rythme": fronton_rythme,
    "flanc_eclairs": flanc_eclairs, "flanc_planetes": flanc_planetes,
    "neon_jetons": neon_jetons, "neon_pince": neon_pince, "neon_photo": neon_photo, "neon_dragon": neon_dragon,
    "records": records, "tapis_danse": tapis_danse, "table_palet": table_palet, "bande_photo": bande_photo,
    "vue_prairie": lambda: (vue_prairie(False), vue_prairie(True)), "vue_plage": lambda: (vue_plage(False), vue_plage(True)),
    "tenture_soleil": tenture_soleil, "patchwork": patchwork, "kilim": kilim, "indienne": indienne,
    "toile_fleurs": toile_fleurs, "toile_soleil": toile_soleil, "toile_vagues": toile_vagues, "carte_route": carte_route,
}


def main():
    noms = sys.argv[1:] or list(TOUTES)
    for n in noms:
        TOUTES[n]()
        print("beau175 :", n)


if __name__ == "__main__":
    main()
