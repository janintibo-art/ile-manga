"""V60 : textures de Tazira, le grand port de pêcheurs de la côte sud (le désert).

tazira/  pise.png (+_n)       : les remparts et les maisons de terre — pisé ocre rouge, banchées
                                 horizontales, trous de boulins, ravinements de pluie ;
         chaux.png (+_n)      : le badigeon de chaux des maisons, blanc un peu bleuté, écaillé
                                 par endroits (le pisé apparaît dessous) ;
         zellige.png          : mosaïque d'étoiles à huit branches (fontaine, seuils) ;
         canisse.png          : les claies de roseaux qui couvrent le souk (alpha entre les roseaux) ;
         tapis_1..3.png       : trois tapis berbères (losanges rouges, bleu et blanc, kilim) ;
         barque.png (+_n)     : la coque des barques — bleu vif délavé, liston rouge, filet jaune ;
         voile_noire.png      : la voile noire, rapiécée, du navire pirate (alpha dans les trous) ;
         pavillon.png         : le pavillon pirate (tête de mort et tibias), bords effilochés ;
         enseignes            : enseigne_criee, enseigne_souk, enseigne_murene, enseigne_fondouk.
items/   carte_tresor, rhum_murene, sardines_grillees, the_menthe, tajine_poisson.
Tout est dessiné ici (libre de droits).
Lancement depuis la racine du dépôt : python3 pcvr/tools/generate_tazira_v60.py [enseignes | icones]
"""
from pathlib import Path
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_carene_v59 as gc  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "tazira"
FONTS = ROOT / "www" / "assets" / "fonts"
rng = np.random.default_rng(6060)
tile_noise = gc.tile_noise


def save_rgb(arr, name):
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGB").save(OUT / name, optimize=True)
    print("tazira/" + name)


def save_rgba(arr, name):
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA").save(OUT / name, optimize=True)
    print("tazira/" + name)


def save_n(h, strength, name):
    OUT.mkdir(parents=True, exist_ok=True)
    gc.normal_map(h, strength).save(OUT / name, optimize=True)
    print("tazira/" + name)


# =================================================================== murs

def pise():
    """Pisé : 4 m de mur par tuile, cinq banchées, trous de boulins, ravines."""
    S = 1024
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    lift = S / 5.0
    band = np.floor(yy / lift)
    inb = (yy - band * lift) / lift
    base = np.array([0.72, 0.5, 0.37], np.float32)
    n1 = tile_noise(S, S, ox=(4, 8, 16, 32, 64, 128, 256), falloff=0.6)
    strata = tile_noise(S, S, ox=(2, 4, 8), oy=(64, 128, 256), falloff=0.6)
    col = base[None, None, :] * (0.78 + 0.32 * n1[..., None]) * (0.9 + 0.14 * strata[..., None])
    # chaque banchée a sa teinte (la terre de chaque jour de chantier)
    for b in range(5):
        m = band == b
        col[m] *= rng.uniform(0.9, 1.08)
    # le joint entre deux banchées : un léger creux sombre
    joint = np.clip(1.0 - np.minimum(inb, 1.0 - inb) * lift / 5.0, 0, 1)
    col *= (1.0 - 0.22 * joint)[..., None]
    h = n1 * 0.6 + strata * 0.4 - joint * 0.8
    # trous de boulins (les trous des poutrelles du coffrage), en ligne sous chaque joint
    for b in range(0, 5, 2):
        y = b * lift + lift * 0.18
        for k in range(3):
            x = (k + 0.5) * S / 3 + rng.uniform(-60, 60)
            r = rng.uniform(9, 14)
            m2 = ((xx - x) / r) ** 2 + ((yy - y) / (r * 0.8)) ** 2 < 1.0
            col[m2] *= 0.35
            h[m2] -= 1.5
    # ravinements verticaux (pluies d'orage)
    rav = tile_noise(S, S, ox=(64, 128, 256), oy=(2, 4, 8), falloff=0.6)
    r = np.clip((rav - 0.62) * 3.0, 0, 1)
    col *= (1.0 - 0.18 * r)[..., None]
    h -= r * 0.6
    # cailloux pris dans la terre
    for k in range(260):
        x, y = rng.uniform(0, S), rng.uniform(0, S)
        rr = rng.uniform(2, 6)
        m3 = (xx - x) ** 2 + (yy - y) ** 2 < rr * rr
        col[m3] = col[m3] * 0.5 + np.array([0.62, 0.58, 0.52]) * rng.uniform(0.6, 1.0) * 0.5
        h[m3] += 0.6
    save_rgb(col, "pise.png")
    save_n(h, 6.0, "pise_n.png")


def chaux():
    """Badigeon de chaux sur un mur de terre : blanc bleuté, coulures, écailles."""
    S = 1024
    n1 = tile_noise(S, S, ox=(4, 8, 16, 32, 64, 128, 256), falloff=0.6)
    n2 = tile_noise(S, S, ox=(3, 6, 12, 24), falloff=0.6)
    white = np.array([0.95, 0.95, 0.93], np.float32)
    col = white[None, None, :] * (0.88 + 0.12 * n1[..., None])
    # un voile bleuté par endroits (le bleu de lessive qu'on ajoute à la chaux)
    col[..., 2] += 0.03 * n2
    col[..., 0] -= 0.02 * n2
    # écailles : le pisé apparaît dessous
    flake = np.clip((n2 - 0.7) * 5.0, 0, 1) * np.clip((n1 - 0.45) * 4.0, 0, 1)
    earth = np.array([0.7, 0.46, 0.32], np.float32)
    col = col * (1 - flake[..., None]) + earth * (0.8 + 0.3 * n1[..., None]) * flake[..., None]
    # coulures grises en bas (la tuile représente 3 m de mur)
    yy = np.mgrid[0:S, 0:S][0].astype(np.float32) / S
    streak = tile_noise(S, S, ox=(64, 128, 256), oy=(2, 4, 8), falloff=0.6)
    dirt = np.clip((streak - 0.55) * 2.5, 0, 1) * (0.3 + 0.7 * yy)
    col *= (1.0 - 0.12 * dirt)[..., None]
    h = n1 * 0.5 + n2 * 0.3 - flake * 0.8
    save_rgb(col, "chaux.png")
    save_n(h, 4.0, "chaux_n.png")


def zellige():
    """Zellige : étoiles à huit branches, carreaux vernissés, joints de mortier."""
    S = 512
    img = Image.new("RGB", (S, S), (236, 230, 214))
    d = ImageDraw.Draw(img)
    cell = 128
    cols = [(24, 96, 92), (22, 64, 132), (198, 150, 52), (150, 46, 38)]
    for cy in range(0, S + cell, cell):
        for cx in range(0, S + cell, cell):
            c = cols[((cx // cell) + (cy // cell)) % len(cols)]
            r = cell * 0.42
            pts = []
            for k in range(16):
                a = k * math.pi / 8 + math.pi / 16
                rr = r if k % 2 == 0 else r * 0.62
                pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
            d.polygon(pts, fill=c, outline=(230, 224, 206))
            d.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(236, 230, 214))
            # petites croix entre les étoiles
            mx, my = cx + cell / 2, cy + cell / 2
            d.polygon([(mx, my - 18), (mx + 18, my), (mx, my + 18), (mx - 18, my)], fill=(28, 58, 112), outline=(230, 224, 206))
    arr = np.asarray(img, np.float32) / 255.0
    # vernis : un peu de variation, des éclats
    n = tile_noise(S, S, ox=(8, 16, 32, 64), falloff=0.6)
    arr *= (0.9 + 0.16 * n[..., None])
    save_rgb(arr, "zellige.png")


def canisse():
    """Claies de roseaux : la lumière passe entre les roseaux (alpha)."""
    W, H = 512, 512
    xx = np.mgrid[0:H, 0:W][1].astype(np.float32)
    yy = np.mgrid[0:H, 0:W][0].astype(np.float32)
    col = np.zeros((H, W, 3), np.float32)
    alpha = np.zeros((H, W), np.float32)
    x = 0.0
    while x < W:
        w = rng.uniform(7, 11)
        gap = rng.uniform(1.5, 6.0)
        c = np.array([0.72, 0.62, 0.42]) * rng.uniform(0.8, 1.1)
        m = (xx >= x) & (xx < x + w)
        prof = np.clip(1.0 - np.abs((xx - x - w / 2) / (w / 2)), 0, 1) ** 0.5
        col[m] = (c * (0.65 + 0.4 * prof[m, None]))
        # les nœuds du roseau
        nodes = (np.mod(yy + rng.uniform(0, 90), rng.uniform(80, 120)) < 3)
        col[m & nodes] *= 0.7
        alpha[m] = 1.0
        x += w + gap
    # les liens de corde en travers
    for y0 in (90, 260, 430):
        m = (yy > y0) & (yy < y0 + 7)
        col[m] = np.array([0.5, 0.4, 0.28])
        alpha[m] = 1.0
    save_rgba(np.dstack([col, alpha]), "canisse.png")


def tapis(k):
    W, H = 256, 512
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    if k == 1:
        bg, c1, c2 = (150, 36, 30), (236, 168, 60), (40, 24, 20)
    elif k == 2:
        bg, c1, c2 = (232, 226, 210), (30, 50, 110), (20, 20, 24)
    else:
        bg, c1, c2 = (200, 96, 40), (40, 110, 104), (236, 210, 140)
    d.rectangle((0, 0, W, H), fill=bg)
    d.rectangle((10, 10, W - 10, H - 10), outline=c2, width=6)
    d.rectangle((22, 22, W - 22, H - 22), outline=c1, width=3)
    for i, cy in enumerate(range(70, H - 40, 92)):
        cx = W // 2
        r = 52
        d.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)], outline=c1, width=6)
        d.polygon([(cx, cy - 26), (cx + 26, cy), (cx, cy + 26), (cx - 26, cy)], fill=c2 if i % 2 else c1)
        for sx in (-1, 1):
            d.line([(cx + sx * 80, cy - 40), (cx + sx * 80, cy + 40)], fill=c2, width=4)
    arr = np.asarray(img, np.float32) / 255.0
    wool = tile_noise(W, H, ox=(32, 64, 128), oy=(64, 128, 256), falloff=0.6)
    arr *= (0.82 + 0.25 * wool[..., None])
    # les franges en haut et en bas
    for y0, y1 in ((0, 8), (H - 8, H)):
        arr[y0:y1, :] = np.array([0.9, 0.86, 0.76]) * (0.8 + 0.2 * (np.arange(W) % 4 < 2))[:, None]
    save_rgb(arr, "tapis_%d.png" % k)


def barque():
    """Coque de barque : planches peintes en bleu (v = 0 en haut : liston rouge, filet jaune)."""
    S = 512
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    rows = 8
    rh = S / rows
    row = np.floor(yy / rh)
    inr = (yy - row * rh) / rh
    blue = np.array([0.1, 0.36, 0.68], np.float32)
    col = np.tile(blue, (S, S, 1)) * (0.85 + 0.15 * rng.random((S, S, 1)).astype(np.float32) * 0 + 0.0)
    n1 = tile_noise(S, S, ox=(4, 8, 16, 32, 64), falloff=0.6)
    grain = gc.wood_grain(S, S, True)
    col *= (0.82 + 0.3 * n1[..., None]) * (0.92 + 0.12 * grain[..., None])
    # bandes : liston rouge, filet jaune, puis blanc sous la flottaison (le bas de la tuile)
    top = yy < rh * 0.9
    col[top] = np.array([0.72, 0.14, 0.1]) * (0.85 + 0.25 * n1[top, None])
    line = (yy >= rh * 1.0) & (yy < rh * 1.25)
    col[line] = np.array([0.95, 0.76, 0.18]) * (0.85 + 0.2 * n1[line, None])
    low = yy > rh * 6.4
    col[low] = np.array([0.88, 0.88, 0.84]) * (0.8 + 0.25 * n1[low, None])
    # la peinture s'écaille : le bois gris apparaît
    flake = np.clip((tile_noise(S, S, ox=(8, 16, 32, 64), falloff=0.6) - 0.68) * 5, 0, 1)
    wood = np.array([0.55, 0.5, 0.42])
    col = col * (1 - flake[..., None]) + wood * (0.7 + 0.4 * grain[..., None]) * flake[..., None]
    seam = np.clip(1.0 - np.minimum(inr, 1 - inr) * rh / 2.0, 0, 1)
    col *= (1.0 - 0.35 * seam)[..., None]
    h = grain * 0.3 - seam * 0.8 - flake * 0.3
    save_rgb(col, "barque.png")
    save_n(h, 5.0, "barque_n.png")


def voile_noire():
    W, H = 1024, 1024
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    weave = 0.5 + 0.5 * np.sin(xx * 1.4) * np.sin(yy * 1.4)
    stain = tile_noise(W, H, ox=(3, 6, 12, 24, 48), falloff=0.6)
    col = np.dstack([0.12 + 0 * xx, 0.11 + 0 * xx, 0.1 + 0 * xx]) * (0.85 + 0.15 * weave)[..., None] * (0.75 + 0.5 * stain)[..., None]
    lz = np.mod(xx, 128)
    col *= (1.0 - 0.25 * np.clip(1.0 - np.abs(lz - 2) / 3.0, 0, 1))[..., None]
    img = Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB")
    d = ImageDraw.Draw(img)
    for k in range(7):
        x0, y0 = rng.uniform(40, W - 200), rng.uniform(40, H - 200)
        w, h = rng.uniform(60, 150), rng.uniform(60, 140)
        tone = int(rng.uniform(24, 46))
        d.rectangle((x0, y0, x0 + w, y0 + h), fill=(tone, tone - 2, tone - 4), outline=(70, 66, 60), width=3)
    col = np.asarray(img, np.float32) / 255.0
    holes = tile_noise(W, H, ox=(4, 8, 16, 32, 64), falloff=0.55)
    m = holes > 0.93
    tear = Image.fromarray((m * 255).astype(np.uint8), "L").filter(ImageFilter.MaxFilter(3))
    alpha = 1.0 - np.asarray(tear, np.float32) / 255.0
    save_rgba(np.dstack([col, alpha]), "voile_noire.png")


def pavillon():
    W, H = 512, 320
    img = Image.new("RGBA", (W, H), (14, 12, 12, 255))
    d = ImageDraw.Draw(img)
    cx, cy = W // 2, H // 2 - 14
    bone = (236, 230, 214, 255)
    # tibias croisés
    for s in (-1, 1):
        d.line([(cx - 120, cy + 40 * s + 50), (cx + 120, cy - 40 * s + 50)], fill=bone, width=22)
        for (x, y) in ((cx - 120, cy + 40 * s + 50), (cx + 120, cy - 40 * s + 50)):
            d.ellipse((x - 18, y - 22, x + 4, y), fill=bone)
            d.ellipse((x - 4, y - 4, x + 18, y + 18), fill=bone)
    # le crâne
    d.ellipse((cx - 62, cy - 86, cx + 62, cy + 30), fill=bone)
    d.rounded_rectangle((cx - 36, cy + 10, cx + 36, cy + 52), 10, fill=bone)
    for s in (-1, 1):
        d.ellipse((cx + s * 26 - 18, cy - 34, cx + s * 26 + 18, cy + 4), fill=(14, 12, 12, 255))
    d.polygon([(cx, cy + 6), (cx - 9, cy + 22), (cx + 9, cy + 22)], fill=(14, 12, 12, 255))
    for k in range(-2, 3):
        d.line([(cx + k * 13, cy + 30), (cx + k * 13, cy + 50)], fill=(14, 12, 12, 255), width=3)
    arr = np.asarray(img, np.float32) / 255.0
    # bord effiloché (côté battant, à droite) et trous
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    n = tile_noise(W, H, ox=(4, 8, 16, 32), falloff=0.6)
    fray = xx > W - 40 - 50 * n
    arr[fray, 3] = 0.0
    small = tile_noise(W, H, ox=(16, 32, 64), falloff=0.6)
    arr[(small > 0.94) & (xx > 60), 3] = 0.0
    arr[..., :3] *= (0.85 + 0.2 * tile_noise(W, H, ox=(8, 16, 32), falloff=0.6)[..., None])
    save_rgba(arr, "pavillon.png")


# =================================================================== enseignes

def enseigne(name, title, sub, bg, ink, frame, icon):
    W, H = 512, 256
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # un panneau en arc outrepassé, peint, cadre de couleur
    d.rounded_rectangle((8, 30, W - 8, H - 8), 18, fill=frame + (255,))
    d.pieslice((W // 2 - 120, 4, W // 2 + 120, 120), 180, 360, fill=frame + (255,))
    d.rounded_rectangle((20, 42, W - 20, H - 20), 14, fill=bg + (255,))
    d.pieslice((W // 2 - 106, 18, W // 2 + 106, 132), 180, 360, fill=bg + (255,))
    arr = np.asarray(img, np.float32) / 255.0
    n = tile_noise(W, H, ox=(8, 16, 32, 64), falloff=0.6)
    arr[..., :3] *= (0.82 + 0.25 * n[..., None])
    img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(img)
    f1 = ImageFont.truetype(str(FONTS / "Lora-BoldItalic.ttf"), 42)
    f2 = ImageFont.truetype(str(FONTS / "Lora-Italic.ttf"), 24)
    tw = d.textlength(title, font=f1)
    d.text(((W - tw) / 2, 92), title, fill=ink + (255,), font=f1)
    sw = d.textlength(sub, font=f2)
    d.text(((W - sw) / 2, 150), sub, fill=ink + (235,), font=f2)
    cx, cy = W // 2, 60
    if icon == "poisson":
        d.ellipse((cx - 34, cy - 14, cx + 22, cy + 14), fill=ink)
        d.polygon([(cx + 18, cy), (cx + 40, cy - 16), (cx + 40, cy + 16)], fill=ink)
        d.ellipse((cx - 24, cy - 5, cx - 16, cy + 3), fill=bg)
    elif icon == "lanterne":
        d.polygon([(cx - 16, cy - 10), (cx + 16, cy - 10), (cx + 22, cy + 18), (cx - 22, cy + 18)], outline=ink, width=4)
        d.polygon([(cx - 12, cy - 10), (cx, cy - 34), (cx + 12, cy - 10)], fill=ink)
        d.line((cx, cy - 10, cx, cy + 18), fill=ink, width=2)
    elif icon == "crane":
        d.ellipse((cx - 20, cy - 30, cx + 20, cy + 6), fill=ink)
        d.rectangle((cx - 12, cy, cx + 12, cy + 14), fill=ink)
        for s in (-1, 1):
            d.ellipse((cx + s * 9 - 6, cy - 18, cx + s * 9 + 6, cy - 6), fill=bg)
            d.line((cx - 34, cy + 22 * s + 6, cx + 34, cy - 22 * s + 6), fill=ink, width=6)
    elif icon == "theiere":
        d.ellipse((cx - 24, cy - 16, cx + 24, cy + 20), fill=ink)
        d.polygon([(cx - 8, cy - 16), (cx, cy - 34), (cx + 8, cy - 16)], fill=ink)
        d.line((cx + 20, cy, cx + 40, cy - 16), fill=ink, width=5)
        d.arc((cx - 40, cy - 12, cx - 12, cy + 14), 90, 270, fill=ink, width=5)
    img = img.filter(ImageFilter.GaussianBlur(0.4))
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / name, optimize=True)
    print("tazira/" + name)


def signs():
    enseigne("enseigne_criee.png", "La Criée", "le poisson de l'aube, au plus offrant", (240, 232, 214), (22, 64, 120), (22, 96, 150), "poisson")
    enseigne("enseigne_souk.png", "Souk des Mille Couleurs", "épices, tapis, lanternes, babouches", (226, 166, 70), (60, 26, 16), (150, 46, 38), "lanterne")
    enseigne("enseigne_murene.png", "La Murène Ivre", "rhum, cartes et coups de sabre", (24, 20, 18), (230, 200, 120), (110, 26, 20), "crane")
    enseigne("enseigne_fondouk.png", "Le Fondouk", "auberge — thé à la menthe", (36, 110, 96), (244, 236, 214), (198, 150, 52), "theiere")


# =================================================================== icônes d'objets

def icones():
    import generate_items_v28 as icons
    S = icons.S
    # carte au trésor : parchemin roulé, pointillés et croix rouge
    img = icons.canvas()
    par = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(par)
    d.polygon([(70, 110), (440, 80), (450, 420), (80, 440)], fill=(222, 196, 140, 255))
    arr = np.asarray(par, np.float32)
    n = tile_noise(S, S, ox=(4, 8, 16, 32), falloff=0.6)
    arr[..., :3] *= (0.75 + 0.35 * n[..., None])
    par = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")
    img.alpha_composite(par)
    d = ImageDraw.Draw(img)
    d.polygon([(150, 300), (190, 220), (270, 200), (330, 250), (300, 330), (210, 350)], outline=(110, 80, 40), width=6)
    pts = [(120, 400), (170, 370), (220, 380), (260, 330), (300, 290)]
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        for t in np.linspace(0, 1, 5)[:-1]:
            d.ellipse((a[0] + (b[0] - a[0]) * t - 5, a[1] + (b[1] - a[1]) * t - 5, a[0] + (b[0] - a[0]) * t + 5, a[1] + (b[1] - a[1]) * t + 5), fill=(120, 60, 30))
    d.line((280, 270, 330, 320), fill=(200, 30, 20), width=14)
    d.line((330, 270, 280, 320), fill=(200, 30, 20), width=14)
    d.ellipse((60, 90, 110, 140), fill=(196, 168, 112))
    d.ellipse((420, 390, 470, 440), fill=(196, 168, 112))
    icons.save(img, "carte_tresor")
    # rhum : bouteille ambrée, étiquette noire à tête de mort
    img = icons.canvas()
    b = icons.canvas()
    bd = ImageDraw.Draw(b)
    bd.rounded_rectangle((176, 200, 336, 470), 34, fill=(150, 80, 26, 255))
    bd.polygon([(196, 210), (232, 120), (280, 120), (316, 210)], fill=(150, 80, 26, 255))
    bd.rectangle((232, 70, 280, 128), fill=(150, 80, 26, 255))
    img.alpha_composite(b)
    d = ImageDraw.Draw(img)
    d.rectangle((232, 46, 280, 84), fill=(90, 60, 40))
    d.rounded_rectangle((190, 290, 322, 400), 10, fill=(20, 18, 16))
    d.ellipse((236, 310, 276, 350), fill=(236, 230, 214))
    d.line((226, 372, 286, 342), fill=(236, 230, 214), width=7)
    d.line((226, 342, 286, 372), fill=(236, 230, 214), width=7)
    sh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((196, 220, 220, 440), 10, fill=(255, 220, 160, 110))
    img.alpha_composite(sh)
    icons.save(img, "rhum_murene")
    # sardines grillées : trois poissons argentés sur une grille
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    for k in range(5):
        d.line((90, 140 + k * 60, 430, 140 + k * 60), fill=(60, 56, 54), width=8)
    for i, y in enumerate((170, 260, 350)):
        f = icons.canvas()
        icons.shaded_ellipse(f, (110, y - 34, 380, y + 34), (170, 180, 186))
        img.alpha_composite(f)
        d = ImageDraw.Draw(img)
        d.polygon([(370, y), (430, y - 36), (430, y + 36)], fill=(140, 150, 156))
        d.ellipse((140, y - 10, 158, y + 8), fill=(30, 30, 30))
        for k in range(4):
            d.line((200 + k * 40, y - 30, 216 + k * 40, y + 30), fill=(60, 40, 30), width=6)
    icons.save(img, "sardines_grillees")
    # thé à la menthe : théière d'argent et petit verre
    img = icons.canvas()
    t = icons.canvas()
    icons.shaded_ellipse(t, (120, 200, 340, 420), (200, 200, 206))
    img.alpha_composite(t)
    d = ImageDraw.Draw(img)
    d.polygon([(190, 210), (230, 130), (270, 210)], fill=(186, 186, 192))
    d.ellipse((216, 104, 244, 132), fill=(176, 176, 182))
    d.line((330, 280, 400, 210), fill=(180, 180, 186), width=16)
    d.arc((90, 230, 170, 340), 90, 270, fill=(170, 170, 176), width=14)
    d.polygon([(370, 330), (450, 330), (440, 450), (380, 450)], fill=(200, 230, 200, 200))
    d.rectangle((384, 370, 436, 446), fill=(150, 110, 30))
    for k in range(3):
        d.ellipse((392 + k * 12, 318 - k * 10, 412 + k * 12, 338 - k * 10), fill=(60, 160, 70))
    icons.save(img, "the_menthe")
    # tajine de poisson : plat de terre et couvercle conique
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.ellipse((70, 330, 442, 440), fill=(160, 72, 40))
    d.ellipse((90, 320, 422, 410), fill=(190, 92, 52))
    lid = icons.canvas()
    ImageDraw.Draw(lid).polygon([(110, 360), (256, 90), (402, 360)], fill=(196, 104, 60, 255))
    img.alpha_composite(lid)
    d = ImageDraw.Draw(img)
    d.ellipse((236, 70, 276, 110), fill=(176, 84, 44))
    for k in range(3):
        d.arc((150 + k * 10, 200 + k * 50, 362 - k * 10, 300 + k * 50), 200, 340, fill=(230, 200, 120), width=6)
    icons.save(img, "tajine_poisson")
    # dattes : une grappe brune et luisante dans un petit panier de palme
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.ellipse((90, 300, 422, 450), fill=(170, 130, 70))
    for k in range(6):
        d.arc((90, 300 + k * 6, 422, 450 - k * 6), 0, 180, fill=(140, 100, 50), width=4)
    rng = np.random.default_rng(7)
    for i in range(14):
        cx = 140 + rng.integers(0, 230)
        cy = 250 + rng.integers(0, 110)
        f = icons.canvas()
        icons.shaded_ellipse(f, (cx - 26, cy - 44, cx + 26, cy + 44), (110 + rng.integers(0, 30), 50, 22))
        img.alpha_composite(f.rotate(int(rng.integers(-40, 40)), center=(cx, cy)))
    d = ImageDraw.Draw(img)
    d.chord((90, 300, 422, 450), 0, 180, fill=(176, 136, 74))
    for k in range(4):
        d.arc((96, 306 + k * 8, 416, 444 - k * 8), 10, 170, fill=(140, 100, 50), width=4)
    icons.save(img, "dattes")


if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else ""
    if what in ("", "textures"):
        pise()
        chaux()
        zellige()
        canisse()
        for k in (1, 2, 3):
            tapis(k)
        barque()
        voile_noire()
        pavillon()
    if what in ("", "enseignes"):
        signs()
    if what in ("", "icones"):
        icones()
