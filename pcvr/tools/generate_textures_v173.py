"""V173 : les images des tours de la Citadelle des Nuées et de la tour de contrôle d'Astralys.
Faites ici ; CC0 1.0. Dossier www/assets/textures/beau173/.

  blason_rois_ciel     le blason des Rois-Ciel : l'aigle d'or aux ailes ouvertes sur champ d'azur, trois
                       nuées d'argent en pointe, la bordure d'or (fond transparent, en forme d'écu).
  tapisserie_rois_ciel une tapisserie tissée : la Citadelle sur son île flottante, l'aigle et son
                       cavalier, les nuages, les étoiles, la bordure de laine rouge et ses fleurons.
  merelles             le plateau du jeu de mérelles (trois carrés et leurs traits), brûlé dans le bois.
  radar_astralys       l'écran du radar de la tour de contrôle : les cercles, le balayage, les soucoupes.
  vols_astralys        le tableau des départs et des arrivées du Spatioport d'Astralys.
  panorama_astralys    la vue des grandes vitres de la tour de contrôle : le ciel mauve, les nuages, les
                       flèches de cristal au loin, les îlots qui flottent ; se répète en largeur.

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_textures_v173.py [nom…]
"""
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

RACINE = Path(__file__).resolve().parents[2]
OUT = RACINE / "www" / "assets" / "textures" / "beau173"
SS = 2
FONTS = Path("/usr/share/fonts/truetype/dejavu")


def police(nom, taille):
    try:
        return ImageFont.truetype(str(FONTS / nom), int(taille * SS))
    except OSError:
        return ImageFont.load_default()


def bruit(cell, seed, w, h=None):
    """Un bruit de valeur lisse (w × h pixels), qui se répète en largeur."""
    h = h or w
    r = np.random.default_rng(seed)
    ch = max(1, int(round(cell * h / w)))
    g = r.random((ch + 1, cell + 1))
    g[:, cell] = g[:, 0]
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


# =================================================================== l'aigle des Rois-Ciel

def aigle(d, cx, cy, s, coul, trait):
    """L'aigle aux ailes ouvertes (vu de face, la tête tournée à gauche), centré en (cx, cy), taille s."""
    def P(x, y):
        return (cx + x * s, cy + y * s)
    # les ailes : un bord d'attaque qui monte, des rémiges en doigts
    for sg in (-1, 1):
        pts = [P(sg * 0.12, -0.18), P(sg * 0.38, -0.42), P(sg * 0.62, -0.52), P(sg * 0.86, -0.46)]
        doigts = 6
        for k in range(doigts + 1):
            t = k / doigts
            ang = math.radians(-35 + 110 * t)
            r0 = 0.86 - 0.18 * t
            x = sg * (0.15 + r0 * math.cos(ang) * 0.95)
            y = -0.1 + r0 * math.sin(ang) * 0.75
            pts.append(P(x, y))
            if k < doigts:
                t2 = (k + 0.5) / doigts
                ang2 = math.radians(-35 + 110 * t2)
                pts.append(P(sg * (0.15 + (r0 - 0.16) * math.cos(ang2) * 0.95), -0.1 + (r0 - 0.16) * math.sin(ang2) * 0.75))
        pts += [P(sg * 0.14, 0.12)]
        d.polygon(pts, fill=coul, outline=trait)
        # les plumes de l'aile (des traits)
        for k in range(5):
            t = (k + 0.5) / 5
            ang = math.radians(-30 + 100 * t)
            d.line([P(sg * 0.2, -0.12), P(sg * (0.15 + 0.6 * math.cos(ang)), -0.1 + 0.48 * math.sin(ang))], fill=trait, width=max(1, int(s * 0.012)))
    # le corps, la queue en éventail, les pattes
    d.ellipse([P(-0.15, -0.28), P(0.15, 0.3)], fill=coul, outline=trait, width=max(1, int(s * 0.01)))
    queue = [P(-0.08, 0.22), P(-0.2, 0.62), P(-0.07, 0.56), P(0.0, 0.66), P(0.07, 0.56), P(0.2, 0.62), P(0.08, 0.22)]
    d.polygon(queue, fill=coul, outline=trait)
    for sg in (-1, 1):
        d.line([P(sg * 0.08, 0.22), P(sg * 0.2, 0.42)], fill=trait, width=max(2, int(s * 0.035)))
        for k in (-1, 0, 1):
            d.line([P(sg * 0.2, 0.42), P(sg * 0.2 + k * 0.05, 0.5)], fill=trait, width=max(1, int(s * 0.02)))
    # le cou, la tête (tournée à gauche), le bec crochu, la langue
    d.polygon([P(-0.09, -0.22), P(0.09, -0.22), P(0.05, -0.36), P(-0.07, -0.4)], fill=coul, outline=trait)
    d.polygon([P(-0.03, -0.5), P(0.05, -0.44), P(0.04, -0.36), P(-0.08, -0.34), P(-0.13, -0.4), P(-0.11, -0.47)], fill=coul, outline=trait)
    d.polygon([P(-0.12, -0.45), P(-0.25, -0.43), P(-0.27, -0.37), P(-0.23, -0.35), P(-0.22, -0.39), P(-0.12, -0.38)], fill=coul, outline=trait)
    d.line([P(-0.2, -0.38), P(-0.26, -0.3), P(-0.23, -0.27)], fill=(170, 30, 30), width=max(1, int(s * 0.015)))
    d.ellipse([P(-0.07, -0.45), P(-0.035, -0.415)], fill=trait)
    # les plumes de la poitrine (des écailles)
    for row in range(4):
        for k in range(3 - row % 2):
            x = -0.06 + k * 0.06 + (row % 2) * 0.03
            y = -0.14 + row * 0.08
            d.arc([P(x - 0.03, y - 0.03), P(x + 0.03, y + 0.03)], 20, 160, fill=trait, width=max(1, int(s * 0.008)))
    # la couronne
    d.polygon([P(-0.08, -0.49), P(-0.09, -0.6), P(-0.05, -0.54), P(-0.02, -0.62), P(0.01, -0.54), P(0.05, -0.6), P(0.04, -0.48)], fill=coul, outline=trait)


def blason_rois_ciel():
    w, h = 384 * SS, 448 * SS
    # la forme de l'écu
    masque = Image.new("L", (w, h), 0)
    dm = ImageDraw.Draw(masque)
    m = 10 * SS
    pts = [(m, m), (w - m, m), (w - m, h * 0.52)]
    for k in range(1, 21):
        t = k / 20
        x = (w - m) + (w / 2 - (w - m)) * t
        y = h * 0.52 + (h - m - h * 0.52) * math.sin(t * math.pi / 2)
        pts.append((x, y))
    for k in range(20, -1, -1):
        t = k / 20
        x = m + (w / 2 - m) * t
        y = h * 0.52 + (h - m - h * 0.52) * math.sin(t * math.pi / 2)
        pts.append((x, y))
    dm.polygon(pts, fill=255)
    # le champ d'azur (un peu de grain, plus clair en haut)
    yy = np.linspace(0, 1, h)[:, None] * np.ones((1, w))
    n = fbm(6, 4, 731, w, h)
    champ = melange((0.16, 0.3, 0.62), (0.08, 0.16, 0.42), yy * 0.8 + (n - 0.5) * 0.4)
    img = rgb(champ).convert("RGBA")
    d = ImageDraw.Draw(img)
    # trois nuées d'argent en pointe
    for (cx, cy, r) in [(0.3, 0.8, 0.09), (0.5, 0.86, 0.1), (0.7, 0.8, 0.09)]:
        for k in range(5):
            a = math.pi * (k / 4)
            x = (cx + math.cos(a) * r * 0.8) * w
            y = (cy - math.sin(a) * r * 0.5) * h
            d.ellipse([x - r * 0.45 * w, y - r * 0.4 * w, x + r * 0.45 * w, y + r * 0.4 * w], fill=(222, 228, 236, 255), outline=(150, 160, 175, 255), width=SS)
    aigle(d, w * 0.5, h * 0.42, w * 0.42, (226, 182, 72, 255), (120, 78, 20, 255))
    # la bordure d'or (sur le contour de l'écu)
    bord = masque.filter(ImageFilter.MinFilter(int(26 * SS) | 1))
    anneau = Image.eval(Image.fromarray(np.array(masque) - np.array(bord)), lambda v: v)
    or_ = Image.new("RGBA", (w, h), (214, 168, 64, 255))
    on = rgb(melange((0.95, 0.78, 0.36), (0.6, 0.42, 0.14), fbm(10, 3, 77, w, h))).convert("RGBA")
    or_ = Image.blend(or_, on, 0.55)
    img.paste(or_, (0, 0), anneau)
    img.putalpha(masque)
    img = img.resize((w // SS, h // SS), Image.LANCZOS)
    img.save(OUT / "blason_rois_ciel.png")


# =================================================================== la tapisserie

def tapisserie_rois_ciel():
    w, h = 512 * SS, 768 * SS
    yy = np.linspace(0, 1, h)[:, None] * np.ones((1, w))
    n = fbm(8, 4, 173, w, h)
    fond = melange((0.1, 0.17, 0.3), (0.2, 0.32, 0.42), yy * 0.9 + (n - 0.5) * 0.3)
    img = rgb(fond).convert("RGB")
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(3)
    # les étoiles (petites croix de laine dorée)
    for _ in range(70):
        x = rng.uniform(0.1, 0.9) * w
        y = rng.uniform(0.08, 0.45) * h
        r = rng.uniform(2, 5) * SS
        d.line([(x - r, y), (x + r, y)], fill=(226, 196, 120), width=SS)
        d.line([(x, y - r), (x, y + r)], fill=(226, 196, 120), width=SS)
    # les nuages, en bas (des bourrelets de laine claire)
    for row in range(3):
        y0 = h * (0.74 + row * 0.07)
        for k in range(9):
            x = w * (k / 8.0) + (row % 2) * w * 0.06
            r = w * rng.uniform(0.07, 0.11)
            col = tuple(int(c) for c in np.array([200, 210, 222]) - row * 18)
            d.ellipse([x - r, y0 - r * 0.6, x + r, y0 + r * 0.6], fill=col, outline=(120, 132, 150), width=SS)
    # l'île flottante (la roche, ses racines) et la Citadelle
    cx, cy = w * 0.5, h * 0.6
    roche = [(cx - w * 0.3, cy), (cx + w * 0.3, cy), (cx + w * 0.2, cy + h * 0.06), (cx + w * 0.06, cy + h * 0.11), (cx, cy + h * 0.15),
             (cx - w * 0.08, cy + h * 0.1), (cx - w * 0.22, cy + h * 0.05)]
    d.polygon(roche, fill=(104, 84, 70), outline=(60, 46, 38))
    for k in range(6):
        x = cx - w * 0.2 + k * w * 0.08
        d.line([(x, cy + h * 0.02), (x + rng.uniform(-8, 8) * SS, cy + h * 0.02 + rng.uniform(0.02, 0.06) * h)], fill=(70, 56, 46), width=2 * SS)
    d.rectangle([cx - w * 0.3, cy - h * 0.012, cx + w * 0.3, cy], fill=(92, 130, 70))
    pierre = (196, 186, 168)
    ombre = (120, 112, 100)
    # les remparts, les tours, le donjon
    d.rectangle([cx - w * 0.22, cy - h * 0.07, cx + w * 0.22, cy - h * 0.01], fill=pierre, outline=ombre, width=SS)
    for k in range(12):
        x = cx - w * 0.22 + k * w * 0.04
        d.rectangle([x, cy - h * 0.082, x + w * 0.02, cy - h * 0.07], fill=pierre, outline=ombre)
    for sx in (-1, 1):
        tx = cx + sx * w * 0.22
        d.rectangle([tx - w * 0.04, cy - h * 0.13, tx + w * 0.04, cy - h * 0.01], fill=pierre, outline=ombre, width=SS)
        d.polygon([(tx - w * 0.05, cy - h * 0.13), (tx + w * 0.05, cy - h * 0.13), (tx, cy - h * 0.2)], fill=(70, 80, 110), outline=(40, 46, 70))
        d.rectangle([tx - w * 0.008, cy - h * 0.1, tx + w * 0.008, cy - h * 0.08], fill=(40, 34, 30))
    d.rectangle([cx - w * 0.09, cy - h * 0.17, cx + w * 0.09, cy - h * 0.07], fill=pierre, outline=ombre, width=SS)
    d.polygon([(cx - w * 0.06, cy - h * 0.17), (cx + w * 0.06, cy - h * 0.17), (cx, cy - h * 0.3)], fill=(70, 80, 110), outline=(40, 46, 70))
    d.line([(cx, cy - h * 0.3), (cx, cy - h * 0.33)], fill=(214, 170, 70), width=2 * SS)
    d.ellipse([cx - 4 * SS, cy - h * 0.335 - 4 * SS, cx + 4 * SS, cy - h * 0.335 + 4 * SS], fill=(230, 186, 80))
    d.pieslice([cx - w * 0.03, cy - h * 0.07, cx + w * 0.03, cy - h * 0.01], 180, 360, fill=(46, 36, 30))
    d.rectangle([cx - w * 0.03, cy - h * 0.04, cx + w * 0.03, cy - h * 0.01], fill=(46, 36, 30))
    for k in range(3):
        d.rectangle([cx - w * 0.06 + k * w * 0.05, cy - h * 0.15, cx - w * 0.05 + k * w * 0.05, cy - h * 0.12], fill=(240, 200, 110))
    # l'aigle et son cavalier, en haut à gauche
    aigle(d, w * 0.3, h * 0.24, w * 0.3, (214, 166, 74), (96, 62, 24))
    d.ellipse([w * 0.3 - 8 * SS, h * 0.24 - 30 * SS, w * 0.3 + 8 * SS, h * 0.24 - 14 * SS], fill=(150, 40, 40), outline=(70, 20, 20))
    d.ellipse([w * 0.3 - 6 * SS, h * 0.24 - 42 * SS, w * 0.3 + 6 * SS, h * 0.24 - 30 * SS], fill=(232, 196, 160), outline=(110, 80, 60))
    d.line([(w * 0.3 + 6 * SS, h * 0.24 - 36 * SS), (w * 0.3 + 40 * SS, h * 0.24 - 60 * SS)], fill=(200, 200, 210), width=2 * SS)
    d.polygon([(w * 0.3 + 40 * SS, h * 0.24 - 60 * SS), (w * 0.3 + 64 * SS, h * 0.24 - 66 * SS), (w * 0.3 + 44 * SS, h * 0.24 - 52 * SS)], fill=(30, 90, 170))
    # la bordure de laine rouge et ses fleurons d'or
    b = int(w * 0.07)
    d.rectangle([0, 0, w, b], fill=(118, 26, 30))
    d.rectangle([0, h - b, w, h], fill=(118, 26, 30))
    d.rectangle([0, 0, b, h], fill=(118, 26, 30))
    d.rectangle([w - b, 0, w, h], fill=(118, 26, 30))
    d.rectangle([b - 3 * SS, b - 3 * SS, w - b + 3 * SS, h - b + 3 * SS], outline=(214, 170, 80), width=3 * SS)
    pas = b * 1.6
    for side in range(4):
        long_ = w if side < 2 else h
        n_ = int(long_ / pas)
        for k in range(n_):
            t = (k + 0.5) * long_ / n_
            if side == 0:
                x, y = t, b / 2
            elif side == 1:
                x, y = t, h - b / 2
            elif side == 2:
                x, y = b / 2, t
            else:
                x, y = w - b / 2, t
            r = b * 0.28
            for a in range(4):
                aa = a * math.pi / 2
                d.ellipse([x + math.cos(aa) * r * 0.7 - r * 0.45, y + math.sin(aa) * r * 0.7 - r * 0.45,
                           x + math.cos(aa) * r * 0.7 + r * 0.45, y + math.sin(aa) * r * 0.7 + r * 0.45], fill=(214, 170, 80))
            d.ellipse([x - r * 0.3, y - r * 0.3, x + r * 0.3, y + r * 0.3], fill=(150, 40, 40))
    img = img.resize((w // SS, h // SS), Image.LANCZOS)
    # le tissage : les fils de trame (des lignes), le grain de la laine
    a = np.asarray(img).astype(np.float32) / 255.0
    hh, ww = a.shape[:2]
    trame = 0.9 + 0.1 * np.sin(np.arange(hh) * math.pi * 0.9)[:, None]
    chaine = 0.96 + 0.04 * np.sin(np.arange(ww) * math.pi * 0.7)[None, :]
    grain = 0.88 + 0.24 * fbm(64, 3, 9, ww, hh)
    a = a * (trame * chaine * grain)[..., None]
    rgb(a).save(OUT / "tapisserie_rois_ciel.png")


# =================================================================== le jeu de mérelles

def merelles():
    w = 256 * SS
    n = fbm(4, 4, 55, w, w)
    veines = 0.5 + 0.5 * np.sin(np.linspace(0, 1, w)[None, :] * 40 + n * 9)
    bois = melange((0.5, 0.33, 0.2), (0.68, 0.48, 0.3), veines * 0.6 + n * 0.4)
    img = rgb(bois)
    d = ImageDraw.Draw(img)
    brule = (54, 32, 20)
    for k in range(3):
        m = w * (0.1 + k * 0.14)
        d.rectangle([m, m, w - m, w - m], outline=brule, width=4 * SS)
    for (a, b) in [((w * 0.5, w * 0.1), (w * 0.5, w * 0.38)), ((w * 0.5, w * 0.62), (w * 0.5, w * 0.9)),
                   ((w * 0.1, w * 0.5), (w * 0.38, w * 0.5)), ((w * 0.62, w * 0.5), (w * 0.9, w * 0.5))]:
        d.line([a, b], fill=brule, width=4 * SS)
    for k in range(3):
        m = w * (0.1 + k * 0.14)
        for x in (m, w * 0.5, w - m):
            for y in (m, w * 0.5, w - m):
                if x == w * 0.5 and y == w * 0.5:
                    continue
                d.ellipse([x - 7 * SS, y - 7 * SS, x + 7 * SS, y + 7 * SS], fill=brule)
    img = img.resize((256, 256), Image.LANCZOS)
    img.save(OUT / "merelles.png")


# =================================================================== Astralys : le radar, les vols, la vue

def radar_astralys():
    w = 512 * SS
    yy, xx = np.mgrid[0:w, 0:w].astype(np.float32)
    cx = cy = w / 2
    dx = (xx - cx) / (w / 2)
    dy = (yy - cy) / (w / 2)
    r = np.sqrt(dx * dx + dy * dy)
    ang = (np.arctan2(dy, dx) + np.pi * 2) % (np.pi * 2)
    fond = np.zeros((w, w, 3), np.float32)
    fond[:] = (0.02, 0.06, 0.08)
    dedans = r < 0.96
    base = np.array([0.03, 0.16, 0.18])
    fond[dedans] = base
    # le balayage : un éventail qui s'efface derrière la ligne
    sweep = np.clip(1.0 - ((ang - 0.6) % (np.pi * 2)) / 1.4, 0, 1) ** 2
    fond = fond + (np.array([0.1, 0.75, 0.7])[None, None, :] * (sweep * dedans)[..., None]) * 0.55
    img = rgb(fond)
    d = ImageDraw.Draw(img)
    vert = (90, 230, 210)
    for k in range(1, 5):
        rr = w / 2 * 0.96 * k / 4
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], outline=vert, width=2 * SS)
    d.line([(cx - w * 0.48, cy), (cx + w * 0.48, cy)], fill=vert, width=SS)
    d.line([(cx, cy - w * 0.48), (cx, cy + w * 0.48)], fill=vert, width=SS)
    for k in range(36):
        a = k * math.pi / 18
        r0 = w / 2 * (0.9 if k % 3 else 0.86)
        d.line([(cx + math.cos(a) * r0, cy + math.sin(a) * r0), (cx + math.cos(a) * w * 0.48, cy + math.sin(a) * w * 0.48)], fill=vert, width=SS)
    d.line([(cx, cy), (cx + math.cos(0.6) * w * 0.48, cy + math.sin(0.6) * w * 0.48)], fill=(200, 255, 245), width=3 * SS)
    # les soucoupes (des points qui luisent, et leur étiquette)
    f = police("DejaVuSansMono-Bold.ttf", 13)
    for (a, rr, nom) in [(0.9, 0.55, "GLOOP-7"), (2.4, 0.72, "NEO-12"), (3.9, 0.35, "COMETE"), (5.2, 0.8, "HF-3"), (0.3, 0.25, "ASTR-1")]:
        x = cx + math.cos(a) * rr * w * 0.48
        y = cy + math.sin(a) * rr * w * 0.48
        d.ellipse([x - 7 * SS, y - 7 * SS, x + 7 * SS, y + 7 * SS], fill=(230, 255, 160))
        d.text((x + 10 * SS, y - 8 * SS), nom, font=f, fill=(170, 255, 230))
    img = img.filter(ImageFilter.GaussianBlur(0.6 * SS))
    img = img.resize((512, 512), Image.LANCZOS)
    img.save(OUT / "radar_astralys.png")


def vols_astralys():
    w, h = 768 * SS, 384 * SS
    yy = np.linspace(0, 1, h)[:, None] * np.ones((1, w))
    fond = melange((0.05, 0.07, 0.2), (0.02, 0.03, 0.1), yy)
    img = rgb(fond)
    d = ImageDraw.Draw(img)
    titre = police("DejaVuSans-Bold.ttf", 30)
    f = police("DejaVuSansMono-Bold.ttf", 22)
    turq = (120, 240, 230)
    rose = (255, 150, 210)
    d.text((w * 0.04, h * 0.05), "SPATIOPORT D'ASTRALYS", font=titre, fill=turq)
    d.text((w * 0.62, h * 0.07), "DÉPARTS · ARRIVÉES", font=police("DejaVuSans-Bold.ttf", 20), fill=rose)
    d.line([(w * 0.04, h * 0.2), (w * 0.96, h * 0.2)], fill=turq, width=2 * SS)
    lignes = [
        ("09:40", "GLOOP (planète)", "EN AVANCE (3 jours)"),
        ("10:15", "NÉOPOLIS", "À L'HEURE"),
        ("11:00", "HAUTEFOND", "À L'HEURE"),
        ("12:30", "LA CITÉ DES NUÉES", "EMBARQUEMENT"),
        ("14:05", "CEINTURE DE SATURNE", "RETARDÉ (anneaux)"),
        ("16:20", "LA LUNE (face cachée)", "ANNULÉ (elle dort)"),
    ]
    for i, (hh, dest, etat) in enumerate(lignes):
        y = h * (0.26 + i * 0.12)
        if i % 2 == 0:
            d.rectangle([w * 0.03, y - h * 0.01, w * 0.97, y + h * 0.1], fill=(18, 26, 56))
        d.text((w * 0.05, y), hh, font=f, fill=(255, 230, 150))
        d.text((w * 0.18, y), dest, font=f, fill=(230, 236, 255))
        coul = turq if "HEURE" in etat or "EMBARQ" in etat else rose
        d.text((w * 0.62, y), etat, font=f, fill=coul)
    img = img.filter(ImageFilter.GaussianBlur(0.35 * SS))
    img = img.resize((768, 384), Image.LANCZOS)
    img.save(OUT / "vols_astralys.png")


def panorama_astralys():
    w, h = 1024 * SS, 256 * SS
    yy = np.linspace(0, 1, h)[:, None] * np.ones((1, w))
    ciel = melange((0.62, 0.66, 0.95), (0.95, 0.78, 0.9), yy ** 1.4)
    nuages = fbm(8, 5, 4242, w, h)
    masque = np.clip((nuages - 0.52) * 4.0, 0, 1) * np.clip(1.2 - yy * 1.1, 0, 1)
    ciel = ciel * (1 - masque[..., None] * 0.6) + np.array([1.0, 0.97, 0.99])[None, None, :] * masque[..., None] * 0.6
    img = rgb(ciel)
    d = ImageDraw.Draw(img, "RGBA")
    rng = np.random.default_rng(76)
    # des îlots qui flottent au loin (pâles), les flèches de cristal de la cité
    for k in range(7):
        x = rng.uniform(0, w)
        y = h * rng.uniform(0.35, 0.6)
        r = w * rng.uniform(0.015, 0.035)
        for ox in (-w, 0, w):
            d.polygon([(x + ox - r, y), (x + ox + r, y), (x + ox + r * 0.3, y + r * 0.9), (x + ox - r * 0.2, y + r * 1.2)], fill=(150, 140, 175, 170))
            d.rectangle([x + ox - r, y - r * 0.12, x + ox + r, y], fill=(150, 200, 170, 170))
    sol_y = h * 0.86
    for k in range(26):
        x = rng.uniform(0, w)
        hh = h * rng.uniform(0.18, 0.62)
        lw = w * rng.uniform(0.008, 0.02)
        col = [(190, 210, 255, 220), (240, 190, 235, 220), (200, 180, 255, 220)][k % 3]
        for ox in (-w, 0, w):
            d.polygon([(x + ox - lw, sol_y), (x + ox + lw, sol_y), (x + ox, sol_y - hh)], fill=col)
            d.line([(x + ox, sol_y), (x + ox, sol_y - hh)], fill=(255, 255, 255, 140), width=SS)
    # le bord de l'île (la dalle nacrée), la piste et ses balises
    d.rectangle([0, sol_y, w, h], fill=(214, 214, 236, 255))
    for k in range(32):
        x = k * w / 32
        d.ellipse([x - 3 * SS, sol_y + 6 * SS, x + 3 * SS, sol_y + 12 * SS], fill=(120, 255, 235, 255))
    # une soucoupe qui passe
    x, y = w * 0.62, h * 0.3
    d.ellipse([x - 40 * SS, y - 8 * SS, x + 40 * SS, y + 8 * SS], fill=(210, 214, 230, 255), outline=(120, 120, 150, 255))
    d.ellipse([x - 16 * SS, y - 20 * SS, x + 16 * SS, y], fill=(160, 230, 255, 220))
    for k in range(5):
        d.ellipse([x - 30 * SS + k * 15 * SS - 2 * SS, y - 2 * SS, x - 30 * SS + k * 15 * SS + 2 * SS, y + 2 * SS], fill=(255, 240, 150, 255))
    img = img.resize((1024, 256), Image.LANCZOS)
    img.save(OUT / "panorama_astralys.png")


TOUT = {
    "blason_rois_ciel": blason_rois_ciel,
    "tapisserie_rois_ciel": tapisserie_rois_ciel,
    "merelles": merelles,
    "radar_astralys": radar_astralys,
    "vols_astralys": vols_astralys,
    "panorama_astralys": panorama_astralys,
}


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    noms = sys.argv[1:] or list(TOUT)
    for nom in noms:
        TOUT[nom]()
        print("beau173 :", nom)
