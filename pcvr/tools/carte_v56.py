"""V56 : les deux cartes du carnet, peintes à partir du relief réel du jeu.

  archipel.png   (1080 x 1080, 1 px = 1 m) : carte marine ancienne : fonds en bleus étagés
                 avec isobathes, hauts-fonds turquoise, côtes cernées d'encre et de lignes de
                 houle, terres en teintes hypsométriques ombrées (sable, prairie, maquis,
                 roche, neiges du volcan), l'île flottante comme un nuage, rose des vents,
                 cartouche, papier vieilli. Les noms des lieux sont écrits en direct par le jeu
                 (seulement ceux qu'on a découverts).
  port_azur.png  (960 x 840, 3 px = 1 m) : plan touristique de Port-Azur : mer et bassin, plage,
                 quais, rues, maisons et leurs toits de tuiles, arbres, phare, fontaine, noms
                 des commerces.

Les données viennent du jeu lui-même : un petit script Godot (/root/suites/bake56.gd dans les
tests) échantillonne le relief et lance des rayons sur la ville, et écrit dans /tmp/carte :
arch_h.bin, azur_sol.bin, azur_toit.bin, plan.json.
Lancement (depuis la racine du dépôt) :
    python3 pcvr/tools/carte_v56.py [/tmp/carte]
"""
from pathlib import Path
import json
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "carte"
FONTS = ROOT / "www" / "assets" / "fonts"
RNG = np.random.default_rng(5656)


def font(size: int, bold: bool = False, italic: bool = False) -> ImageFont.FreeTypeFont:
    name = "Lora-" + ("BoldItalic" if bold and italic else "Bold" if bold else "Italic" if italic else "Regular") + ".ttf"
    return ImageFont.truetype(str(FONTS / name), size)


def noise(w: int, h: int, scales=(4, 8, 16, 32, 64), amp: float = 0.55) -> np.ndarray:
    out = np.zeros((h, w), np.float32)
    a = 1.0
    tot = 0.0
    for s in scales:
        g = RNG.standard_normal((max(2, h // s + 2), max(2, w // s + 2))).astype(np.float32)
        up = np.asarray(Image.fromarray(g).resize((w, h), Image.BICUBIC), np.float32)
        out += up * a
        tot += a
        a *= amp
    out /= tot
    return (out - out.min()) / (out.max() - out.min() + 1e-9)


def hillshade(h: np.ndarray, px_m: float, az: float = 315.0, alt: float = 45.0, z: float = 1.0) -> np.ndarray:
    gy, gx = np.gradient(h * z, px_m)
    slope = np.pi / 2 - np.arctan(np.hypot(gx, gy))
    aspect = np.arctan2(-gx, gy)
    a = math.radians(az)
    e = math.radians(alt)
    s = np.sin(e) * np.sin(slope) + np.cos(e) * np.cos(slope) * np.cos(a - aspect)
    return np.clip(s, 0, 1)


def ramp(v: np.ndarray, stops) -> np.ndarray:
    xs = [s[0] for s in stops]
    out = np.zeros(v.shape + (3,), np.float32)
    for c in range(3):
        out[..., c] = np.interp(v, xs, [s[1][c] for s in stops])
    return out / 255.0


def paper(w: int, h: int) -> np.ndarray:
    n = noise(w, h, (2, 4, 8, 16, 64, 128), 0.6)
    base = np.array([238, 226, 196], np.float32) / 255.0
    p = base[None, None, :] * (0.9 + 0.12 * n[..., None])
    # bords brunis
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.minimum.reduce([xx, yy, w - 1 - xx, h - 1 - yy]).astype(np.float32)
    edge = np.clip(d / (0.06 * min(w, h)), 0, 1) ** 0.6
    p *= (0.78 + 0.22 * edge[..., None])
    return p


def to_img(arr: np.ndarray) -> Image.Image:
    return Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8))


# =================================================================== l'archipel

def archipel(src: Path) -> None:
    h = np.fromfile(src / "arch_h.bin", np.float32).reshape(540, 540)
    h = np.array(Image.fromarray(h).resize((1080, 1080), Image.BICUBIC), np.float32)
    W = 1080
    land = h > 0.05
    # les petits flotteurs (bateaux, pontons) ne sont pas des îles
    lab, nl = ndimage.label(land)
    sizes = ndimage.sum(land, lab, range(1, nl + 1))
    for k, sz in enumerate(sizes):
        if sz < 600:
            land[lab == k + 1] = False
            h[lab == k + 1] = -2.0
    sea_d = np.clip(-h, 0, 60)
    # la mer : du turquoise des hauts-fonds au bleu profond
    sea = ramp(sea_d, [(0, (150, 214, 210)), (3, (112, 190, 200)), (10, (70, 150, 184)), (22, (44, 108, 160)), (40, (30, 76, 130)), (60, (22, 56, 104))])
    tex = noise(W, W, (8, 16, 32, 64), 0.6)
    sea *= (0.94 + 0.1 * tex[..., None])
    # isobathes (5, 10, 20, 30 m)
    iso = np.zeros((W, W), bool)
    for lv in (5, 10, 20, 30):
        m = sea_d > lv
        iso |= m ^ ndimage.binary_erosion(m)
    sea[iso & ~land] = sea[iso & ~land] * 0.82
    # les terres : teintes hypsométriques, ombrage
    hl = np.clip(h, 0, 140)
    lands = ramp(hl, [(0, (232, 214, 160)), (0.9, (230, 212, 160)), (1.1, (222, 210, 186)), (1.6, (214, 206, 176)), (4, (160, 182, 110)), (14, (118, 152, 86)), (30, (104, 128, 76)),
                      (55, (140, 120, 90)), (85, (128, 108, 96)), (115, (176, 170, 168)), (140, (242, 240, 236))])
    lands *= (0.9 + 0.14 * noise(W, W, (4, 8, 16), 0.6)[..., None])
    hs = hillshade(h, 1.0, z=1.6)
    lands *= (0.55 + 0.6 * hs[..., None])
    img = np.where(land[..., None], lands, sea)
    # lignes de houle autour des côtes (trois, de plus en plus pâles)
    dist = ndimage.distance_transform_edt(~land)
    for r, a in ((5.0, 0.55), (11.0, 0.32), (18.0, 0.18)):
        ring = np.abs(dist - r) < 0.9
        img[ring & ~land] = img[ring & ~land] * (1 - a) + np.array([0.95, 0.97, 0.96]) * a
    # les toits de Port-Azur (relevés par les rayons du plan de la ville)
    try:
        g2 = np.fromfile(src / "azur_sol.bin", np.float32).reshape(560, 640)
        r2 = np.fromfile(src / "azur_toit.bin", np.float32).reshape(560, 640)
        yaw = 0.98279

        def to_px(bj, bi):
            tx = -180.0 + (bi + 0.5) * 0.5
            tz = 170.0 - (bj + 0.5) * 0.5
            wx = 201.82 + math.cos(yaw) * tx + math.sin(yaw) * tz
            wz = 134.55 - math.sin(yaw) * tx + math.cos(yaw) * tz
            return np.clip((wz + 600).astype(int), 0, W - 1), np.clip((wx + 540).astype(int), 0, W - 1)

        pj, pi = to_px(*np.nonzero((g2 < -0.3) & (r2 > -1.2) & (r2 - g2 > 0.8)))
        decks = np.zeros((W, W), bool)
        decks[pj, pi] = True
        img[decks] = np.array([0.62, 0.50, 0.36])
        bj, bi = np.nonzero((r2 - g2 > 2.2) & (r2 > -50) & (g2 > -0.3))
        jj, ii = to_px(bj, bi)
        roofs = np.zeros((W, W), bool)
        roofs[jj, ii] = True
        roofs = ndimage.binary_closing(roofs)
        img[roofs] = np.array([0.74, 0.40, 0.28]) * (0.85 + 0.2 * hs[roofs][:, None])
        img[roofs ^ ndimage.binary_erosion(roofs)] *= 0.7
    except FileNotFoundError:
        pass
    # le trait de côte, à l'encre
    coast = land ^ ndimage.binary_erosion(land, iterations=2)
    img[coast] = np.array([0.24, 0.18, 0.12])
    # papier par-dessus (teinte « carte ancienne »)
    pap = paper(W, W)
    img = img * (0.72 + 0.28 * pap / pap.max())
    im = to_img(img).convert("RGBA")
    d = ImageDraw.Draw(im)
    # l'île flottante : un nuage et son ombre
    cx, cz = 40 + 540, 400 + 600
    shadow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ds = ImageDraw.Draw(shadow)
    for k in range(14):
        a = k / 14 * math.tau
        r = 48 + RNG.uniform(-10, 14)
        x, y = cx + math.cos(a) * r * 0.8, cz + math.sin(a) * r * 0.6
        ds.ellipse((x - 34 + 14, y - 26 + 18, x + 34 + 14, y + 26 + 18), fill=(20, 40, 70, 60))
    shadow = shadow.filter(ImageFilter.GaussianBlur(10))
    im.alpha_composite(shadow)
    cloud = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    dc = ImageDraw.Draw(cloud)
    for k in range(16):
        a = k / 16 * math.tau
        r = 46 + RNG.uniform(-8, 12)
        x, y = cx + math.cos(a) * r * 0.8, cz + math.sin(a) * r * 0.6
        dc.ellipse((x - 32, y - 24, x + 32, y + 24), fill=(250, 250, 246, 235))
    dc.ellipse((cx - 50, cz - 34, cx + 50, cz + 34), fill=(250, 250, 246, 235))
    cloud = cloud.filter(ImageFilter.GaussianBlur(2))
    im.alpha_composite(cloud)
    d.ellipse((cx - 26, cz - 16, cx + 26, cz + 16), fill=(128, 156, 96, 255), outline=(60, 50, 40, 255), width=2)
    d.ellipse((cx - 8, cz - 10, cx + 6, cz + 2), fill=(200, 196, 190, 255))
    # quadrillage léger
    for g in range(0, W, 120):
        d.line([(g, 0), (g, W)], fill=(80, 60, 40, 40), width=1)
        d.line([(0, g), (W, g)], fill=(80, 60, 40, 40), width=1)
    # rose des vents
    _compass(d, 960, 960, 70)
    # cartouche
    _cartouche(im, (40, 34), "Archipel d'Île Manga", "levé par un voyageur curieux")
    # cadre
    d.rectangle((6, 6, W - 7, W - 7), outline=(70, 50, 30, 255), width=4)
    d.rectangle((14, 14, W - 15, W - 15), outline=(70, 50, 30, 180), width=1)
    OUT.mkdir(parents=True, exist_ok=True)
    im.convert("RGB").save(OUT / "archipel.png", optimize=True)
    print("archipel.png")


def _compass(d: ImageDraw.ImageDraw, cx: float, cy: float, r: float) -> None:
    ink = (70, 46, 28, 255)
    red = (170, 40, 30, 255)
    d.ellipse((cx - r * 0.72, cy - r * 0.72, cx + r * 0.72, cy + r * 0.72), outline=ink, width=2)
    d.ellipse((cx - r * 0.6, cy - r * 0.6, cx + r * 0.6, cy + r * 0.6), outline=ink, width=1)
    for k in range(8):
        a = k * math.pi / 4 - math.pi / 2
        L = r if k % 2 == 0 else r * 0.55
        tip = (cx + math.cos(a) * L, cy + math.sin(a) * L)
        l = (cx + math.cos(a - math.pi / 2) * r * 0.12, cy + math.sin(a - math.pi / 2) * r * 0.12)
        rr = (cx + math.cos(a + math.pi / 2) * r * 0.12, cy + math.sin(a + math.pi / 2) * r * 0.12)
        d.polygon([tip, l, (cx, cy)], fill=(red if k == 0 else ink))
        d.polygon([tip, rr, (cx, cy)], fill=(236, 224, 196, 255))
        d.line([tip, l, (cx, cy), rr, tip], fill=ink, width=1)
    f = font(22, bold=True)
    d.text((cx, cy - r - 14), "N", font=f, fill=ink, anchor="mm")


def _cartouche(im: Image.Image, at, title: str, sub: str) -> None:
    d = ImageDraw.Draw(im)
    f = font(40, bold=True, italic=True)
    fs = font(20, italic=True)
    w = int(max(d.textlength(title, font=f), d.textlength(sub, font=fs)) + 70)
    h = 96
    x, y = at
    box = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    db = ImageDraw.Draw(box)
    db.rounded_rectangle((0, 0, w - 1, h - 1), radius=14, fill=(244, 234, 206, 235), outline=(90, 62, 36, 255), width=3)
    db.rounded_rectangle((7, 7, w - 8, h - 8), radius=10, outline=(90, 62, 36, 160), width=1)
    db.text((w / 2, 38), title, font=f, fill=(70, 40, 22, 255), anchor="mm")
    db.text((w / 2, 74), sub, font=fs, fill=(90, 62, 36, 255), anchor="mm")
    im.alpha_composite(box, (x, y))


# =================================================================== Port-Azur

NAMES = {
    "boulangerie": "Au Pain Doré", "epicerie": "Épicerie Colette", "taverne": "Le Perroquet Bleu", "paulo": "Chez Paulo",
    "cafe": "Café de la Place", "hotel": "Grand Hôtel des Embruns", "capitainerie": "Capitainerie", "poste": "Postes",
    "mairie": "Mairie", "libraire": "La Rose des Vents", "herboriste": "Herboristerie", "armurerie": "L'Enclume Bleue",
    "bijouterie": "Bijouterie Inès", "souvenirs": "Souvenirs d'Azur", "glacier": "Glaces Bruno", "paillote": "Le Coco Loco",
    "poissonnerie": "Marché aux Poissons", "gare": "Gare Maritime", "fleurs": "Fleurs de Rose", "location": "Location de bateaux",
    "rita": "Madame Rita", "gardien": "Maison du gardien",
}
X0, X1, Z0, Z1 = -180.0, 140.0, -110.0, 170.0
PX = 3.0  # pixels par mètre


def _tp(x: float, z: float):
    return ((x - X0) * PX, (Z1 - z) * PX)


def port_azur(src: Path) -> None:
    g = np.fromfile(src / "azur_sol.bin", np.float32).reshape(560, 640)
    r = np.fromfile(src / "azur_toit.bin", np.float32).reshape(560, 640)
    plan = json.loads((src / "plan.json").read_text())
    Wd, Hd = 960, 840
    g = np.asarray(Image.fromarray(g).resize((Wd, Hd), Image.BILINEAR), np.float32)
    r = np.asarray(Image.fromarray(r).resize((Wd, Hd), Image.NEAREST), np.float32)
    land = g > -0.05
    above = r - g
    build = (above > 2.2) & (r > -50) & (g > -0.3)
    build = ndimage.binary_opening(build, iterations=1)
    over = (r > g + 0.3) & (g < -0.3) & (r > -1.5)
    jetty = over & (r > 1.7)                                       # digue de rochers
    deck = over & ~jetty                                           # pontons de bois
    plaza = land & ~build & (g > 0.9) & (g < 1.5)                  # la ville basse, pavée
    sea_d = np.clip(-g, 0, 25)
    sea = ramp(sea_d, [(0, (168, 222, 214)), (1.5, (120, 200, 206)), (4, (80, 168, 196)), (10, (54, 128, 178)), (25, (40, 96, 150))])
    sea *= (0.95 + 0.08 * noise(Wd, Hd, (4, 8, 16, 32), 0.6)[..., None])
    hl = np.clip(g, 0, 60)
    lands = ramp(hl, [(0, (238, 222, 178)), (0.9, (236, 224, 186)), (1.6, (240, 232, 214)), (4, (214, 214, 170)), (14, (190, 200, 150)), (40, (176, 184, 136)), (60, (200, 190, 160))])
    hs = hillshade(g, 1.0 / PX, z=1.2)
    lands *= (0.72 + 0.4 * hs[..., None])
    img = np.where(land[..., None], lands, sea)
    img[deck] = np.array([0.70, 0.55, 0.38])
    img[jetty] = np.array([0.62, 0.60, 0.56]) * (0.8 + 0.3 * noise(Wd, Hd, (2, 4), 0.5)[jetty][:, None])
    # pavés : un grain de pierre discret
    grain = noise(Wd, Hd, (1, 2, 3), 0.7)
    img[plaza] = img[plaza] * (0.93 + 0.1 * grain[plaza][:, None])
    # contour des quais et de la côte
    coast = land ^ ndimage.binary_erosion(land, iterations=1)
    img[coast] = img[coast] * 0.55
    pap = paper(Wd, Hd)
    img = img * (0.8 + 0.2 * pap / pap.max())
    im = to_img(img).convert("RGBA")
    d = ImageDraw.Draw(im)
    # les rues : les liens du graphe des rues, pavés clairs
    nodes = plan["noeuds"]
    for a, b in plan["liens"]:
        if a in nodes and b in nodes and not (a.startswith("@") or b.startswith("@")):
            pa, pb = _tp(*nodes[a]), _tp(*nodes[b])
            if math.dist(pa, pb) < 260:
                d.line([pa, pb], fill=(226, 214, 190, 255), width=11)
    for a, b in plan["liens"]:
        if a in nodes and b in nodes and not (a.startswith("@") or b.startswith("@")):
            pa, pb = _tp(*nodes[a]), _tp(*nodes[b])
            if math.dist(pa, pb) < 260:
                d.line([pa, pb], fill=(246, 238, 220, 255), width=7)
    # les maisons : ombre portée puis toits de tuiles (plus foncés au faîte)
    bmask = Image.fromarray((build * 255).astype(np.uint8))
    shadow = Image.new("RGBA", (Wd, Hd), (40, 30, 20, 0))
    shadow.putalpha(bmask.filter(ImageFilter.GaussianBlur(3)).point(lambda v: int(v * 0.45)))
    im.alpha_composite(shadow, (4, 5))
    roofh = np.where(build, r, 0)
    edge = ndimage.distance_transform_edt(build)
    tone = np.clip(edge / 6.0, 0, 1)
    roof_col = np.array([196, 98, 66], np.float32) / 255.0
    var = noise(Wd, Hd, (2, 4, 8), 0.5)
    rc = roof_col[None, None, :] * (0.78 + 0.22 * tone[..., None]) * (0.92 + 0.12 * var[..., None])
    hs2 = hillshade(roofh, 1.0 / PX, z=0.6)
    rc *= (0.75 + 0.35 * hs2[..., None])
    rc_img = to_img(rc).convert("RGBA")
    rc_img.putalpha(bmask)
    im.alpha_composite(rc_img)
    d = ImageDraw.Draw(im)
    outline = build ^ ndimage.binary_erosion(build)
    ol = Image.fromarray((outline * 200).astype(np.uint8))
    ink = Image.new("RGBA", (Wd, Hd), (90, 40, 24, 255))
    ink.putalpha(ol)
    im.alpha_composite(ink)
    d = ImageDraw.Draw(im)
    # les arbres
    tree_col = {"platane": (96, 140, 70), "palmier": (80, 150, 90), "laurier": (90, 130, 70), "bougainvillier": (200, 70, 140),
                "cypres": (60, 100, 60), "olivier": (140, 160, 110)}
    tree_r = {"platane": 9, "palmier": 6, "laurier": 4, "bougainvillier": 4, "cypres": 3, "olivier": 6}
    for k, pts in plan["arbres"].items():
        for (x, z) in pts:
            px, py = _tp(x, z)
            rr = tree_r.get(k, 5)
            d.ellipse((px - rr + 3, py - rr + 4, px + rr + 3, py + rr + 4), fill=(40, 50, 30, 70))
            c = tree_col.get(k, (100, 140, 80))
            d.ellipse((px - rr, py - rr, px + rr, py + rr), fill=c + (255,), outline=(50, 70, 40, 255))
            d.ellipse((px - rr * 0.5, py - rr * 0.6, px + rr * 0.1, py), fill=tuple(min(255, int(v * 1.25)) for v in c) + (255,))
    # la fontaine et le phare
    fx, fz = plan["fontaine"]
    px, py = _tp(fx, fz)
    d.ellipse((px - 10, py - 10, px + 10, py + 10), fill=(120, 190, 220, 255), outline=(80, 70, 60, 255), width=3)
    if plan["phare"]:
        lx, lz = plan["phare"]
        px, py = _tp(lx, lz)
        d.ellipse((px - 12, py - 12, px + 12, py + 12), fill=(250, 248, 240, 255), outline=(170, 40, 30, 255), width=4)
        d.ellipse((px - 4, py - 4, px + 4, py + 4), fill=(250, 200, 60, 255))
    # les noms : d'abord les quartiers, puis les commerces là où il reste de la place
    placed = []

    def free(b):
        return all(b[2] < q[0] or b[0] > q[2] or b[3] < q[1] or b[1] > q[3] for q in placed)

    big = font(26, bold=True, italic=True)
    for txt, x, z in [("Le Port", -20.0, -20.0), ("Plage des Embruns", -130.0, -14.0), ("Pointe du Phare", 98.0, -58.0), ("Les Collines", -40.0, 140.0), ("Place de la Mairie", 0.0, 64.0)]:
        px, py = _tp(x, z)
        tw = d.textlength(txt, font=big)
        placed.append((px - tw / 2, py - 15, px + tw / 2, py + 15))
        d.text((px, py), txt, font=big, fill=(30, 50, 90, 230), anchor="mm", stroke_width=4, stroke_fill=(250, 246, 232, 200))
    fl = font(14, bold=True, italic=True)
    for k, (x, z) in sorted(plan["portes"].items(), key=lambda kv: kv[1][0]):
        if k not in NAMES:
            continue
        px, py = _tp(x, z)
        txt = NAMES[k]
        tw = d.textlength(txt, font=fl)
        for oy in (-14, 14, -28, 28, -42, 42):
            box = (px - tw / 2 - 3, py + oy - 8, px + tw / 2 + 3, py + oy + 8)
            if free(box):
                break
        placed.append(box)
        cy = (box[1] + box[3]) / 2
        if abs(cy - py) > 16:
            d.line([(px, py), (px, cy + (8 if cy < py else -8))], fill=(90, 60, 40, 200), width=1)
        d.text((px, cy), txt, font=fl, fill=(40, 24, 14, 255), anchor="mm", stroke_width=3, stroke_fill=(250, 244, 226, 230))
        d.ellipse((px - 3, py - 3, px + 3, py + 3), fill=(170, 40, 30, 255))
    _compass(d, Wd - 70, 80, 48)
    _cartouche(im, (24, Hd - 120), "Port-Azur", "plan offert par la mairie")
    d.rectangle((5, 5, Wd - 6, Hd - 6), outline=(70, 50, 30, 255), width=4)
    OUT.mkdir(parents=True, exist_ok=True)
    im.convert("RGB").save(OUT / "port_azur.png", optimize=True)
    print("port_azur.png")


if __name__ == "__main__":
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/tmp/carte")
    archipel(src)
    port_azur(src)
