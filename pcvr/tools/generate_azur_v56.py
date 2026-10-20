"""V56 : textures de Port-Azur, la grande île touristique.

azur/       sable_azur (+_n)    : sable doré de la plage, grains fins, débris de coquilles ;
            terre_garrigue (+_n): terre rouge du maquis, cailloux de calcaire, aiguilles de pin ;
            herbe_seche (+_n)   : herbe blonde de l'été, touffes vertes ;
            calcaire (+_n)      : roche calcaire blanche, fissures, lichens ;
            paves (+_n)         : calade de galets ronds (rues) ;
            dalles (+_n)        : grandes dalles de pierre (quai, place) ;
            enduit (+_n)        : enduit à la chaux, clair (teinté par le matériau) ;
            tuiles (+_n)        : tuiles canal en terre cuite ;
            moellons (+_n)      : mur de moellons (quai, phare, murets) ;
            planches (+_n)      : planches d'un ponton, bois gris salé ;
            volet (+_n)         : volet persienne (clair, teinté par le matériau) ;
            porte (+_n)         : porte à panneaux (claire, teintée) ;
            fenetre             : fenêtre à petits carreaux, verre sombre et reflets ;
            vitrine             : grande vitrine de boutique ;
            auvent_*            : toiles rayées des stores et des parasols ;
            horloge             : cadran de l'horloge de la mairie ;
            enseigne_*          : enseignes peintes des boutiques, bars et de l'hôtel ;
            affiche_ferry       : affiche du bateau de ligne (ponton du village) ;
items/      croissant, baguette, glace, punch_coco, bouillabaisse, carte_postale, partition,
            cerf_volant, alliance, cochonnet, rouage, lentille_phare, etoile_mer, cle_ville,
            appareil_photo, corail_rouge, panier_pain, billet_ferry, lettre_azur.
Tout est dessiné ici (libre de droits). Police des enseignes : Lora (SIL OFL 1.1).
Lancement depuis la racine du dépôt : python3 pcvr/tools/generate_azur_v56.py
"""
from pathlib import Path
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
TEX = ROOT / "www" / "assets" / "textures"
AZ = TEX / "azur"
rng = np.random.default_rng(5656)

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_items_v28 as icons  # noqa: E402

FONT_DIRS = [ROOT / "www" / "assets" / "fonts", Path("/usr/share/fonts/truetype/google-fonts")]


def font(size, italic=False, bold=False):
    names = [("Lora-BoldItalic.ttf" if bold else "Lora-Italic.ttf") if italic else ("Lora-Bold.ttf" if bold else "Lora-Regular.ttf")]
    for d in FONT_DIRS:
        for n in names:
            p = d / n
            if p.exists():
                f = ImageFont.truetype(str(p), size)
                try:
                    f.set_variation_by_name("Bold" if bold else "Regular")
                except Exception:
                    pass
                return f
    return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf", size)


# =================================================================== outils

def tile_noise(size, octaves=(8, 16, 32, 64, 128, 256), falloff=0.55):
    acc = np.zeros((size, size), dtype=np.float32)
    amp, total = 1.0, 0.0
    for o in octaves:
        layer = rng.random((o, o)).astype(np.float32)
        big = Image.fromarray((np.tile(layer, (3, 3)) * 255).astype(np.uint8)).resize((size * 3, size * 3), Image.BICUBIC)
        acc += np.asarray(big, dtype=np.float32)[size:size * 2, size:size * 2] / 255.0 * amp
        total += amp
        amp *= falloff
    acc /= total
    return np.clip((acc - acc.mean()) * 1.8 + 0.5, 0, 1)


def rect_noise(w, h, octaves=(4, 8, 16, 32, 64), falloff=0.55):
    s = max(w, h)
    n = tile_noise(s, octaves, falloff)
    return np.asarray(Image.fromarray((n * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC), np.float32) / 255.0


def normal_map(h, strength):
    gy, gx = np.gradient(h)
    n = np.dstack((-gx * strength, -gy * strength, np.ones_like(h)))
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    return Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8), "RGB")


def blur(a, r):
    return np.asarray(Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r)), np.float32) / 255.0


def wblur(a, r):
    """Flou raccordable (on floute une mosaïque 3 x 3 et on garde le centre)."""
    h, w = a.shape[:2]
    big = np.tile(a, (3, 3) if a.ndim == 2 else (3, 3, 1))
    img = Image.fromarray((np.clip(big, 0, 1) * 255).astype(np.uint8))
    out = np.asarray(img.filter(ImageFilter.GaussianBlur(r)), np.float32) / 255.0
    return out[h:2 * h, w:2 * w]


def save_rgb(arr, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGB").save(path, optimize=True)
    print(path.relative_to(ROOT))


def save_rgba(arr, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA").save(path, optimize=True)
    print(path.relative_to(ROOT))


def save_img(img, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)
    print(path.relative_to(ROOT))


def save_n(h, strength, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    normal_map(h, strength).save(path, optimize=True)
    print(path.relative_to(ROOT))


def wrap_dist(ax, ay, bx, by, size):
    dx = np.abs(ax - bx)
    dy = np.abs(ay - by)
    dx = np.minimum(dx, size - dx)
    dy = np.minimum(dy, size - dy)
    return np.sqrt(dx * dx + dy * dy)


def voronoi(size, n, pts=None):
    pts = pts if pts is not None else rng.random((n, 2)) * size
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    f1 = np.full((size, size), 1e9, np.float32)
    f2 = np.full((size, size), 1e9, np.float32)
    ident = np.zeros((size, size), np.int32)
    for i, (px, py) in enumerate(pts):
        d = wrap_dist(xx, yy, px, py, size)
        closer = d < f1
        f2 = np.where(closer, f1, np.minimum(f2, d))
        ident = np.where(closer, i, ident)
        f1 = np.where(closer, d, f1)
    return f1, f2, ident


def stamp_dots(size, n, rmin, rmax, seedcols):
    """Petits éclats posés au hasard (raccordables) : renvoie une image RGBA."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for _ in range(n):
        x, y = rng.random(2) * size
        r = rng.uniform(rmin, rmax)
        c = seedcols[rng.integers(len(seedcols))]
        a = rng.uniform(0.0, math.pi)
        pts = []
        k = rng.integers(5, 9)
        for j in range(k):
            t = a + j / k * math.tau
            rr = r * rng.uniform(0.6, 1.0)
            pts.append((math.cos(t) * rr, math.sin(t) * rr * rng.uniform(0.55, 1.0)))
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                d.polygon([(x + ox + px, y + oy + py) for px, py in pts], fill=c)
    return img


# =================================================================== sols

def sable_azur():
    size = 1024
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    warp = tile_noise(size, (4, 8, 16), 0.6)
    ph = (yy / size * 14.0 + warp * 2.5 + xx / size * 1.0) * math.tau
    ripple = (np.sin(ph) * 0.5 + 0.5) ** 2.0 * 0.35
    grain = tile_noise(size, (128, 256, 512), 0.75)
    patch = tile_noise(size, (4, 8, 16), 0.5)
    h = ripple + grain * 0.5 + patch * 0.15
    base = np.array([0.86, 0.76, 0.56])
    col = base[None, None, :] * (0.82 + 0.2 * grain[..., None] + 0.08 * ripple[..., None])
    col = col * (0.94 + 0.1 * patch[..., None])
    col[..., 0] *= 1.0 + 0.03 * (patch - 0.5)
    img = Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB").convert("RGBA")
    img.alpha_composite(stamp_dots(size, 1400, 0.8, 2.6, [(246, 238, 222, 255), (196, 170, 130, 255), (120, 104, 84, 255), (236, 200, 180, 255), (250, 246, 236, 255)]))
    img = img.convert("RGB").filter(ImageFilter.GaussianBlur(0.45))
    save_img(img, AZ / "sable_azur.png")
    save_n(h, 5.0, AZ / "sable_azur_n.png")


def terre_garrigue():
    size = 1024
    n = tile_noise(size)
    fine = tile_noise(size, (64, 128, 256, 512), 0.7)
    patch = tile_noise(size, (4, 8, 16), 0.55)
    red = np.array([0.55, 0.36, 0.24])
    ochre = np.array([0.66, 0.52, 0.36])
    mix = np.clip(patch * 1.4 - 0.2, 0, 1)[..., None]
    col = red[None, None, :] * (1 - mix) + ochre[None, None, :] * mix
    col *= (0.72 + 0.4 * fine[..., None]) * (0.9 + 0.15 * n[..., None])
    h = n * 0.4 + fine * 0.4
    img = Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB").convert("RGBA")
    # cailloux de calcaire et éclats, aiguilles de pin sèches
    stones = stamp_dots(size, 520, 2.0, 9.0, [(214, 206, 190, 255), (190, 180, 165, 255), (232, 226, 214, 255), (160, 146, 128, 255)])
    sh = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sh.paste((30, 18, 10, 120), (2, 3), stones.split()[3].filter(ImageFilter.GaussianBlur(2)))
    img.alpha_composite(sh)
    img.alpha_composite(stones)
    d = ImageDraw.Draw(img)
    for _ in range(1600):
        x, y = rng.random(2) * size
        a = rng.uniform(0, math.pi)
        L = rng.uniform(10, 26)
        c = [(150, 112, 70, 255), (120, 88, 52, 255), (176, 140, 92, 255)][rng.integers(3)]
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                d.line([(x + ox, y + oy), (x + ox + math.cos(a) * L, y + oy + math.sin(a) * L)], fill=c, width=2)
    img = img.convert("RGB").filter(ImageFilter.GaussianBlur(0.4))
    st = np.asarray(stones.split()[3], np.float32) / 255.0
    save_img(img, AZ / "terre_garrigue.png")
    save_n(h + wblur(st, 1.5) * 0.6, 6.0, AZ / "terre_garrigue_n.png")


def herbe_seche():
    size = 1024
    base = tile_noise(size, (8, 16, 32, 64), 0.55)
    patch = tile_noise(size, (4, 8, 16), 0.55)
    img = Image.new("RGBA", (size, size), (0, 0, 0, 255))
    soil = np.array([0.42, 0.38, 0.24])
    arr = soil[None, None, :] * (0.7 + 0.4 * base[..., None])
    img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGB").convert("RGBA")
    d = ImageDraw.Draw(img)
    hmap = Image.new("L", (size, size), 0)
    dh = ImageDraw.Draw(hmap)
    for _ in range(26000):
        x, y = rng.random(2) * size
        p = patch[int(y) % size, int(x) % size]
        green = rng.random() < 0.42 + 0.35 * max(0.0, p - 0.5)
        if green:
            c = (int(rng.uniform(78, 118)), int(rng.uniform(100, 138)), int(rng.uniform(44, 64)), 255)
        else:
            t = rng.uniform(0, 1)
            c = (int(160 + 44 * t), int(140 + 36 * t), int(80 + 34 * t), 255)
        a = -math.pi / 2 + rng.normal(0, 0.45)
        L = rng.uniform(12, 30)
        x2, y2 = x + math.cos(a) * L * 0.4, y + math.sin(a) * L
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                d.line([(x + ox, y + oy), (x2 + ox, y2 + oy)], fill=c, width=2)
                dh.line([(x + ox, y + oy), (x2 + ox, y2 + oy)], fill=int(120 + rng.uniform(0, 135)), width=2)
    img = img.convert("RGB").filter(ImageFilter.GaussianBlur(0.35))
    h = np.asarray(hmap, np.float32) / 255.0
    save_img(img, AZ / "herbe_seche.png")
    save_n(wblur(h, 0.8) * 0.8 + base * 0.2, 5.0, AZ / "herbe_seche_n.png")


def calcaire():
    size = 1024
    n = tile_noise(size, (4, 8, 16, 32, 64, 128, 256))
    fine = tile_noise(size, (64, 128, 256, 512), 0.7)
    f1, f2, _ = voronoi(size, 22)
    crack = np.exp(-((f2 - f1) / 1.3) ** 2) * np.clip((tile_noise(size, (4, 8, 16), 0.5) - 0.45) * 3.0, 0, 1)
    strata = (np.sin((np.mgrid[0:size, 0:size][0] / size * 9.0 + n * 1.6) * math.tau) * 0.5 + 0.5) ** 6
    h = n * 0.6 + fine * 0.25 - crack * 0.35 - strata * 0.08
    base = np.array([0.70, 0.66, 0.58])
    col = base[None, None, :] * (0.7 + 0.32 * n[..., None] + 0.12 * fine[..., None])
    col *= (1 - crack[..., None] * 0.45) * (1 - strata[..., None] * 0.08)
    # lichens orangés et gris, taches sombres
    li = tile_noise(size, (16, 32, 64), 0.55)
    li = li * tile_noise(size, (64, 128, 256), 0.6)
    m = np.clip((li - 0.5) * 6.0, 0, 1)[..., None] * 0.35
    col = col * (1 - m) + np.array([0.74, 0.6, 0.38])[None, None, :] * m
    gl = tile_noise(size, (32, 64, 128), 0.6)
    mg = np.clip((gl - 0.72) * 5.0, 0, 1)[..., None] * 0.3
    col = col * (1 - mg) + np.array([0.55, 0.58, 0.5])[None, None, :] * mg
    dk = tile_noise(size, (8, 16, 32), 0.5)
    md = np.clip((dk - 0.7) * 3.0, 0, 1)[..., None]
    col *= 1 - md * 0.25
    pits = (rng.random((size, size)) < 0.0012).astype(np.float32)
    pits = wblur(pits, 1.4) * 4.0
    col *= (1 - np.clip(pits, 0, 1)[..., None] * 0.4)
    save_rgb(col, AZ / "calcaire.png")
    save_n(h - pits * 0.3, 7.0, AZ / "calcaire_n.png")


# =================================================================== ville

def paves():
    """Calade : galets ronds posés de chant, en rangées irrégulières, joints de sable."""
    size = 1024
    pts = []
    rows = 22
    for r in range(rows):
        y = (r + 0.5) / rows * size
        x = rng.uniform(0, 20)
        while x < size:
            w = rng.uniform(32, 58)
            pts.append((x + w / 2, y + rng.uniform(-6, 6)))
            x += w * rng.uniform(0.95, 1.08)
    pts = np.array(pts)
    f1, f2, ident = voronoi(size, len(pts), pts)
    edge = np.clip((f2 - f1) / 22.0, 0, 1)
    dome = np.sqrt(np.clip(edge, 0, 1)) * np.clip(1.0 - f1 / 34.0, 0.25, 1.0)
    tint = rng.random(len(pts))
    tone = tint[ident]
    noise = tile_noise(size, (32, 64, 128, 256), 0.6)
    c1 = np.array([0.62, 0.58, 0.52])
    c2 = np.array([0.74, 0.68, 0.58])
    c3 = np.array([0.5, 0.48, 0.46])
    col = np.where((tone < 0.33)[..., None], c1, np.where((tone < 0.75)[..., None], c2, c3))
    col = col * (0.7 + 0.35 * dome[..., None]) * (0.88 + 0.2 * noise[..., None])
    joint = np.array([0.42, 0.37, 0.3])
    jm = (1 - np.clip((edge - 0.18) * 4.0, 0, 1))[..., None]
    col = col * (1 - jm) + joint[None, None, :] * (0.8 + 0.3 * noise[..., None]) * jm
    # usure : les sommets polis brillent un peu
    col += (dome ** 6)[..., None] * 0.06
    save_rgb(col, AZ / "paves.png")
    save_n(dome * 0.9 + noise * 0.1, 9.0, AZ / "paves_n.png")


def dalles():
    """Grandes dalles de calcaire beige, rangées décalées, usées et tachées."""
    size = 1024
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    rows = 4
    rh = size / rows
    joint = np.zeros((size, size), np.float32)
    ident = np.zeros((size, size), np.int32)
    for r in range(rows):
        y0 = int(r * rh)
        y1 = int((r + 1) * rh)
        off = rng.uniform(0, size)
        widths = []
        x = 0.0
        while x < size:
            w = rng.choice([size / 4, size / 3, size / 2.5, size / 5])
            widths.append(w)
            x += w
        scale = size / x
        x = off
        for k, w in enumerate(widths):
            xs = (np.mod(xx[y0:y1] - x, size) < w * scale)
            ident[y0:y1][xs] = r * 100 + k
            x += w * scale
    ident_s = ident.astype(np.float32)
    gx = np.abs(np.diff(ident_s, axis=1, append=ident_s[:, :1])) > 0
    gy = np.abs(np.diff(ident_s, axis=0, append=ident_s[:1, :])) > 0
    joint = (gx | gy).astype(np.float32)
    joint = np.clip(wblur(joint, 2.0) * 4.0, 0, 1)
    noise = tile_noise(size)
    fine = tile_noise(size, (64, 128, 256, 512), 0.7)
    tone = (np.sin(ident * 12.9898) * 43758.5453) % 1.0
    base = np.array([0.76, 0.72, 0.64])
    col = base[None, None, :] * (0.82 + 0.16 * tone[..., None]) * (0.86 + 0.18 * noise[..., None]) * (0.92 + 0.1 * fine[..., None])
    stain = tile_noise(size, (4, 8, 16), 0.55)
    col *= 1 - np.clip((stain - 0.65) * 2.0, 0, 1)[..., None] * 0.18
    col = col * (1 - joint[..., None] * 0.5)
    h = (1 - joint) * 0.6 + noise * 0.25 + fine * 0.15
    save_rgb(col, AZ / "dalles.png")
    save_n(h, 6.0, AZ / "dalles_n.png")


def enduit():
    """Enduit à la chaux, presque blanc : la couleur de la façade vient du matériau."""
    size = 1024
    n = tile_noise(size, (4, 8, 16, 32, 64), 0.6)
    fine = tile_noise(size, (128, 256, 512), 0.75)
    trowel = tile_noise(size, (8, 16, 32), 0.5)
    trowel = np.abs(trowel - 0.5) * 2.0
    yy = np.mgrid[0:size, 0:size][0].astype(np.float32) / size
    v = 0.86 + 0.08 * n + 0.05 * fine - 0.05 * trowel ** 3
    # coulures et salissures (plus fortes vers le bas de la texture = bas des murs)
    streak = tile_noise(size, (64, 128), 0.5)
    streak = np.asarray(Image.fromarray((streak * 255).astype(np.uint8)).resize((size // 8, size)).resize((size, size), Image.BICUBIC), np.float32) / 255.0
    v -= np.clip(streak - 0.6, 0, 1) * 0.25 * (0.3 + 0.7 * yy)
    f1, f2, _ = voronoi(size, 18)
    crack = np.exp(-((f2 - f1) / 1.2) ** 2) * (tile_noise(size, (8, 16), 0.5) > 0.72)
    v -= crack * 0.25
    col = np.dstack([v * 1.0, v * 0.985, v * 0.955])
    save_rgb(col, AZ / "enduit.png")
    save_n(n * 0.3 + fine * 0.4 - trowel * 0.2 - crack * 0.4, 3.0, AZ / "enduit_n.png")


def tuiles():
    """Tuiles canal : rangées de tuiles courbes alternativement creuses et bombées."""
    size = 1024
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    cols = 12
    rows = 8
    cw = size / cols
    rh = size / rows
    u = (xx % cw) / cw
    row = (yy // rh).astype(np.int32)
    v = (yy % rh) / rh
    col_i = (xx // cw).astype(np.int32)
    over = (col_i % 2 == 0)
    prof = np.sin(u * math.pi)
    h = np.where(over, 0.35 + prof * 0.65, 0.35 - prof * 0.25)
    # chevauchement : le bas de chaque tuile recouvre la suivante (marche + ombre)
    lap = np.clip(1 - v / 0.12, 0, 1)
    h = h + (1 - v) * 0.25
    shade = 0.55 + 0.55 * np.where(over, prof * 0.85 + 0.15, 0.45 + 0.25 * (1 - prof))
    shade *= 1 - lap * 0.0
    shade *= np.where(v > 0.9, 0.72, 1.0)
    seed = (col_i * 31 + row * 17)
    tone = (np.sin(seed * 12.9898) * 43758.5453) % 1.0
    noise = tile_noise(size, (16, 32, 64, 128, 256), 0.6)
    a = np.array([0.72, 0.36, 0.22])
    b = np.array([0.80, 0.48, 0.30])
    c = np.array([0.6, 0.3, 0.2])
    base = np.where((tone < 0.4)[..., None], a, np.where((tone < 0.8)[..., None], b, c))
    col = base * shade[..., None] * (0.85 + 0.25 * noise[..., None])
    li = tile_noise(size, (16, 32, 64), 0.55)
    li = li * tile_noise(size, (64, 128, 256), 0.6)
    m = np.clip((li - 0.55) * 6.0, 0, 1)[..., None] * 0.35
    col = col * (1 - m) + np.array([0.7, 0.66, 0.52])[None, None, :] * m
    save_rgb(col, AZ / "tuiles.png")
    save_n(h + noise * 0.08, 7.0, AZ / "tuiles_n.png")


def moellons():
    """Mur de moellons : assises de blocs plus ou moins longs, arêtes arrondies, joints de mortier."""
    size = 1024
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    ident = np.zeros((size, size), np.int32)
    bev = np.zeros((size, size), np.float32)
    y = 0
    r = 0
    wob = tile_noise(size, (8, 16, 32), 0.5)
    while y < size:
        hgt = int(rng.uniform(70, 120)) if y + 140 < size else size - y
        y1 = min(size, y + hgt)
        x = rng.uniform(0, 80)
        k = 0
        while x < size + 200:
            w = rng.uniform(90, 210)
            x0, x1 = x, x + w
            for off in (-size, 0, size):
                m = (yy >= y) & (yy < y1) & (xx >= x0 + off) & (xx < x1 + off)
                ident[m] = r * 1000 + k
                dx = np.minimum(xx[m] - (x0 + off), (x1 + off) - xx[m])
                dy = np.minimum(yy[m] - y, y1 - yy[m])
                bev[m] = np.minimum(dx, dy)
            x = x1
            k += 1
        y = y1
        r += 1
    bev = bev + (wob - 0.5) * 10.0
    edge = np.clip(bev / 14.0, 0, 1)
    noise = tile_noise(size)
    fine = tile_noise(size, (64, 128, 256, 512), 0.7)
    tone = (np.sin(ident * 7.233) * 43758.5453) % 1.0
    base = np.array([0.66, 0.62, 0.55])
    col = base[None, None, :] * (0.72 + 0.32 * tone[..., None]) * (0.8 + 0.3 * noise[..., None]) * (0.9 + 0.15 * fine[..., None])
    col[..., 0] *= 1.0 + 0.08 * (tone - 0.5)
    mortar = np.array([0.62, 0.6, 0.55])
    mm = (1 - np.clip(edge * 2.5, 0, 1))[..., None]
    col = col * (1 - mm) + mortar * (0.8 + 0.2 * fine[..., None]) * mm
    h = np.sqrt(edge) * 0.7 + noise * 0.2 + fine * 0.1
    save_rgb(col, AZ / "moellons.png")
    save_n(h, 8.0, AZ / "moellons_n.png")


def planches():
    size = 1024
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    n_planks = 8
    pw = size / n_planks
    idx = (xx // pw).astype(np.int32)
    u = (xx % pw) / pw
    grain = tile_noise(size, (8, 16, 32, 64), 0.6)
    grain_s = np.asarray(Image.fromarray((grain * 255).astype(np.uint8)).resize((size // 16, size)).resize((size, size), Image.BICUBIC), np.float32) / 255.0
    lines = (np.sin((xx / 6.0 + grain_s * 12.0) ) * 0.5 + 0.5) ** 3
    tone = (np.sin(idx * 3.7) * 43758.5453) % 1.0
    base = np.array([0.56, 0.52, 0.46])
    col = base[None, None, :] * (0.75 + 0.3 * tone[..., None]) * (0.8 + 0.2 * grain_s[..., None]) * (0.92 + 0.08 * lines[..., None])
    gap = (u < 0.03) | (u > 0.97)
    col[gap] *= 0.3
    # têtes de clous
    for p in range(n_planks):
        for y in (60, 60 + size // 2):
            for dx in (0.2, 0.8):
                cx, cy = (p + dx) * pw, y
                m = (xx - cx) ** 2 + (yy - cy) ** 2 < 16
                col[m] = col[m] * 0.4 + np.array([0.25, 0.2, 0.18]) * 0.6
    h = (1 - gap.astype(np.float32)) * 0.6 + grain_s * 0.2 + lines * 0.2
    save_rgb(col, AZ / "planches.png")
    save_n(h, 6.0, AZ / "planches_n.png")


def volet():
    """Volet persienne : cadre et lames inclinées, peint en clair (teinté ensuite)."""
    w, h = 256, 512
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    frame = (xx < 22) | (xx > w - 23) | (yy < 22) | (yy > h - 23) | (np.abs(yy - h / 2) < 10)
    slat = (yy % 22) / 22.0
    hgt = np.where(frame, 0.85, 0.3 + slat * 0.5)
    shade = np.where(frame, 0.95, 0.62 + slat * 0.42)
    noise = rect_noise(w, h, (8, 16, 32, 64), 0.6)
    chip = rect_noise(w, h, (16, 32, 64), 0.5)
    v = shade * (0.9 + 0.12 * noise)
    peel = np.clip((chip - 0.86) * 5.0, 0, 1) * 0.6
    col = np.dstack([v, v, v]) * (1 - peel[..., None]) + np.array([0.55, 0.45, 0.35]) * peel[..., None]
    save_rgb(col, AZ / "volet.png")
    save_n(hgt + noise * 0.1, 4.0, AZ / "volet_n.png")


def porte():
    w, h = 256, 512
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    hgt = np.full((h, w), 0.8, np.float32)
    shade = np.full((h, w), 0.92, np.float32)
    for (x0, y0, x1, y1) in [(30, 30, 226, 230), (30, 260, 226, 480)]:
        inside = (xx > x0) & (xx < x1) & (yy > y0) & (yy < y1)
        bev = np.minimum(np.minimum(xx - x0, x1 - xx), np.minimum(yy - y0, y1 - yy))
        hgt = np.where(inside, 0.5 + np.clip(bev / 14.0, 0, 1) * 0.25, hgt)
        shade = np.where(inside & (bev < 14), 0.78 + bev / 14 * 0.14, shade)
    grain = rect_noise(w, h, (8, 16, 32), 0.6)
    v = shade * (0.88 + 0.14 * grain)
    col = np.dstack([v, v, v])
    # poignée en laiton (non teintée : on la garde sombre-chaude)
    m = (xx - 205) ** 2 + (yy - 265) ** 2 < 90
    col[m] = [0.55, 0.42, 0.18]
    save_rgb(col, AZ / "porte.png")
    save_n(hgt + grain * 0.06, 4.0, AZ / "porte_n.png")


def fenetre():
    """Fenêtre à la française : deux battants, petits carreaux, verre sombre aux reflets de ciel."""
    w, h = 256, 384
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    rgba = np.zeros((h, w, 4), np.float32)
    glass_top = np.array([0.36, 0.46, 0.56])
    glass_bot = np.array([0.08, 0.1, 0.12])
    t = yy / h
    glass = glass_top * (1 - t[..., None]) + glass_bot * t[..., None]
    # reflets diagonaux
    refl = (np.sin((xx + yy * 0.6) / 18.0) * 0.5 + 0.5) ** 8 * 0.25
    glass = glass + refl[..., None]
    # rideau clair derrière la moitié haute d'un battant (vie intérieure)
    cur = (xx > 140) & (xx < 236) & (yy > 20) & (yy < 200)
    glass[cur] = glass[cur] * 0.4 + np.array([0.75, 0.72, 0.62]) * 0.6 * (0.85 + 0.15 * np.sin(xx[cur] / 5.0))[..., None]
    rgba[..., :3] = glass
    rgba[..., 3] = 1.0
    frame = (xx < 14) | (xx > w - 15) | (yy < 14) | (yy > h - 15) | (np.abs(xx - w / 2) < 7)
    bars = (np.abs(((yy - 14) % ((h - 28) / 3)) ) < 4) & (yy > 20) & (yy < h - 20)
    bars |= (np.abs(xx - w / 4) < 3) | (np.abs(xx - 3 * w / 4) < 3)
    fm = frame | bars
    rgba[fm, :3] = np.array([0.93, 0.92, 0.88])
    save_rgba(rgba, AZ / "fenetre.png")


def vitrine():
    w, h = 512, 384
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    rgba = np.zeros((h, w, 4), np.float32)
    t = yy / h
    glass = np.array([0.30, 0.38, 0.44]) * (1 - t[..., None]) + np.array([0.12, 0.12, 0.13]) * t[..., None]
    refl = (np.sin((xx * 0.8 + yy) / 30.0) * 0.5 + 0.5) ** 10 * 0.35
    glass = glass + refl[..., None]
    # étagères et marchandises floues à l'intérieur
    for y in (150, 250, 340):
        sh = (np.abs(yy - y) < 4)
        glass[sh] = [0.4, 0.3, 0.2]
        for _ in range(14):
            x0 = rng.uniform(20, w - 60)
            ww = rng.uniform(14, 40)
            hh = rng.uniform(20, 60)
            c = np.array([rng.uniform(0.3, 0.9), rng.uniform(0.3, 0.8), rng.uniform(0.2, 0.7)])
            m = (xx > x0) & (xx < x0 + ww) & (yy > y - hh) & (yy < y)
            glass[m] = glass[m] * 0.45 + c * 0.55 * 0.7
    rgba[..., :3] = glass
    rgba[..., 3] = 1.0
    frame = (xx < 12) | (xx > w - 13) | (yy < 12) | (yy > h - 13) | (np.abs(xx - w / 2) < 6)
    rgba[frame, :3] = [0.2, 0.18, 0.16]
    save_rgba(rgba, AZ / "vitrine.png")


AUVENTS = {
    "rouge": (182, 40, 38), "bleu": (36, 82, 150), "vert": (40, 110, 70), "jaune": (226, 176, 40),
    "orange": (214, 110, 40), "turquoise": (30, 150, 160), "bordeaux": (120, 30, 48),
}


def auvents():
    size = 512
    for name, c in AUVENTS.items():
        yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
        stripe = ((xx // 64) % 2 == 0)
        weave = tile_noise(size, (64, 128, 256), 0.7)
        cc = np.array(c) / 255.0
        white = np.array([0.94, 0.92, 0.86])
        col = np.where(stripe[..., None], cc, white) * (0.86 + 0.16 * weave[..., None])
        fade = tile_noise(size, (4, 8), 0.5)
        col = col * (0.92 + 0.08 * fade[..., None]) + 0.04
        # bord festonné (lambrequin) en bas : alpha
        rgba = np.dstack([col, np.ones((size, size))])
        scal = (yy > size - 48) & (((xx % 64) - 32) ** 2 + (yy - (size - 48)) ** 2 > 32 ** 2)
        rgba[scal, 3] = 0.0
        save_rgba(rgba, AZ / f"auvent_{name}.png")


def horloge():
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = size // 2
    d.ellipse((6, 6, size - 6, size - 6), fill=(32, 30, 28, 255))
    d.ellipse((22, 22, size - 22, size - 22), fill=(236, 230, 214, 255))
    d.ellipse((40, 40, size - 40, size - 40), outline=(40, 36, 30, 255), width=3)
    f = font(46, bold=True)
    romans = ["XII", "I", "II", "III", "IIII", "V", "VI", "VII", "VIII", "IX", "X", "XI"]
    for i, r in enumerate(romans):
        a = i / 12 * math.tau - math.pi / 2
        x = c + math.cos(a) * 178
        y = c + math.sin(a) * 178
        d.text((x, y), r, font=f, fill=(30, 28, 26, 255), anchor="mm")
    for i in range(60):
        a = i / 60 * math.tau
        r0 = 205 if i % 5 else 196
        d.line([(c + math.cos(a) * r0, c + math.sin(a) * r0), (c + math.cos(a) * 214, c + math.sin(a) * 214)], fill=(30, 28, 26, 255), width=3 if i % 5 == 0 else 2)
    fs = font(26, italic=True)
    d.text((c, c + 70), "Port-Azur", font=fs, fill=(90, 70, 40, 255), anchor="mm")
    save_img(img, AZ / "horloge.png")


ENSEIGNES = {
    # id : (texte, sous-titre, fond, encre, style)
    "boulangerie": ("Au Pain Doré", "Boulangerie · Pâtisserie", (120, 70, 36), (250, 226, 160), "bois"),
    "epicerie": ("Épicerie Colette", "Produits fins", (40, 80, 60), (240, 230, 200), "peint"),
    "taverne": ("Le Perroquet Bleu", "Taverne · Musique le soir", (24, 52, 96), (250, 210, 90), "bois"),
    "paulo": ("Chez Paulo", "Poissons & Bouillabaisse", (140, 40, 36), (250, 240, 220), "peint"),
    "cafe": ("Café de la Place", "", (30, 30, 34), (236, 214, 150), "peint"),
    "hotel": ("Grand Hôtel des Embruns", "", (240, 236, 226), (40, 60, 100), "plaque"),
    "capitainerie": ("Capitainerie", "Port-Azur", (30, 60, 110), (250, 250, 250), "plaque"),
    "poste": ("Postes", "Télégraphe", (230, 190, 40), (30, 40, 90), "peint"),
    "mairie": ("Mairie", "Liberté · Port-Azur", (240, 236, 226), (60, 50, 40), "plaque"),
    "libraire": ("La Rose des Vents", "Livres · Cartes marines", (60, 40, 70), (240, 220, 170), "bois"),
    "herboriste": ("Herboristerie", "Dr Amélie Roux", (40, 90, 60), (240, 240, 220), "peint"),
    "armurerie": ("L'Enclume Bleue", "Armurier · Forgeron", (40, 44, 52), (150, 190, 240), "fer"),
    "bijouterie": ("Bijouterie Inès", "Perles & Pierres", (40, 30, 60), (240, 210, 140), "peint"),
    "souvenirs": ("Souvenirs d'Azur", "Cartes postales", (30, 140, 160), (255, 250, 230), "peint"),
    "glacier": ("Glaces Bruno", "", (240, 160, 180), (90, 40, 60), "peint"),
    "paillote": ("Le Coco Loco", "Bar de plage", (160, 110, 60), (250, 240, 200), "bois"),
    "poissonnerie": ("Marché aux Poissons", "", (36, 90, 130), (250, 250, 240), "peint"),
    "gare": ("Gare Maritime", "L'Hirondelle · Traversées", (240, 236, 226), (30, 60, 110), "plaque"),
    "fleurs": ("Fleurs de Rose", "", (230, 220, 200), (150, 50, 80), "peint"),
    "location": ("Location de bateaux", "Yannick", (30, 110, 150), (255, 255, 255), "peint"),
    "rita": ("Madame Rita", "Voyance · Tarots", (70, 30, 80), (240, 200, 90), "peint"),
    "hirondelle": ("L'Hirondelle", "Port-Azur", (0, 0, 0), (250, 248, 240), "texte"),
}


def enseignes():
    for key, (title, sub, bg, ink, style) in ENSEIGNES.items():
        w, h = 1024, 256
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        if style == "bois":
            arr = np.zeros((h, w, 3), np.float32)
            grain = rect_noise(w, h, (4, 8, 16, 32), 0.6)
            gs = np.asarray(Image.fromarray((grain * 255).astype(np.uint8)).resize((w, h // 8)).resize((w, h), Image.BICUBIC), np.float32) / 255.0
            arr[:] = np.array(bg) / 255.0
            arr *= (0.75 + 0.35 * gs[..., None])
            img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8)).convert("RGBA")
            d = ImageDraw.Draw(img)
            d.rectangle((6, 6, w - 7, h - 7), outline=(40, 26, 14, 255), width=10)
            d.rectangle((22, 22, w - 23, h - 23), outline=tuple(int(c * 0.8) for c in ink) + (255,), width=3)
        elif style == "fer":
            d.rounded_rectangle((0, 0, w - 1, h - 1), radius=30, fill=bg + (255,))
            d.rounded_rectangle((14, 14, w - 15, h - 15), radius=24, outline=(160, 170, 180, 255), width=5)
        elif style == "texte":
            pass  # lettres peintes directement sur la coque : fond transparent
        elif style == "plaque":
            d.rounded_rectangle((0, 0, w - 1, h - 1), radius=18, fill=bg + (255,))
            d.rounded_rectangle((12, 12, w - 13, h - 13), radius=12, outline=ink + (255,), width=4)
        else:
            d.rectangle((0, 0, w - 1, h - 1), fill=bg + (255,))
            d.rectangle((10, 10, w - 11, h - 11), outline=tuple(min(255, int(c * 1.0)) for c in ink) + (255,), width=4)
        size = 118 if not sub else 104
        f = font(size, italic=(style in ("bois", "peint")), bold=True)
        while d.textlength(title, font=f) > w - 90 and size > 40:
            size -= 4
            f = font(size, italic=(style in ("bois", "peint")), bold=True)
        ty = h * 0.42 if sub else h * 0.5
        # ombre portée des lettres peintes
        d.text((w / 2 + 3, ty + 4), title, font=f, fill=(0, 0, 0, 110), anchor="mm")
        d.text((w / 2, ty), title, font=f, fill=ink + (255,), anchor="mm")
        if sub:
            fs = font(44, italic=True)
            d.text((w / 2, h * 0.79), sub, font=fs, fill=ink + (230,), anchor="mm")
        # patine
        arr = np.asarray(img, np.float32) / 255.0
        wear = rect_noise(w, h, (8, 16, 32, 64), 0.6)
        arr[..., :3] *= (0.86 + 0.16 * wear[..., None])
        save_rgba(arr, AZ / f"enseigne_{key}.png")


def affiche_ferry():
    """Affiche de voyage façon années 30 : le phare, la baie, le bateau."""
    w, h = 512, 768
    img = Image.new("RGB", (w, h), (240, 228, 200))
    d = ImageDraw.Draw(img)
    # ciel dégradé
    for y in range(0, 470):
        t = y / 470
        c = (int(250 - 40 * t), int(190 + 30 * t), int(120 + 100 * t))
        d.line([(0, y), (w, y)], fill=c)
    d.ellipse((300, 120, 420, 240), fill=(255, 236, 170))
    # mer
    for y in range(470, 640):
        t = (y - 470) / 170
        d.line([(0, y), (w, y)], fill=(int(30 + 20 * t), int(120 - 50 * t), int(170 - 60 * t)))
    for k in range(14):
        y = 480 + k * 12
        d.line([(rng.uniform(0, 300), y), (rng.uniform(250, 512), y)], fill=(170, 220, 230), width=2)
    # colline et maisons
    d.polygon([(0, 470), (0, 360), (120, 330), (260, 380), (340, 430), (420, 470)], fill=(110, 140, 80))
    for i, (x, c) in enumerate([(30, (230, 170, 120)), (80, (240, 210, 150)), (130, (220, 140, 120)), (180, (245, 230, 200)), (230, (230, 190, 110))]):
        d.rectangle((x, 400 - i % 2 * 12, x + 44, 470), fill=c)
        d.polygon([(x - 4, 400 - i % 2 * 12), (x + 22, 384 - i % 2 * 12), (x + 48, 400 - i % 2 * 12)], fill=(190, 90, 60))
    # phare
    d.rectangle((440, 300, 470, 470), fill=(245, 245, 240))
    d.rectangle((440, 340, 470, 362), fill=(200, 40, 40))
    d.rectangle((436, 286, 474, 300), fill=(40, 40, 40))
    d.polygon([(436, 286), (455, 266), (474, 286)], fill=(200, 40, 40))
    # le bateau
    d.polygon([(90, 560), (330, 560), (300, 600), (110, 600)], fill=(250, 250, 250))
    d.rectangle((110, 588, 300, 600), fill=(30, 70, 140))
    d.rectangle((150, 530, 260, 560), fill=(250, 250, 250))
    d.rectangle((200, 505, 222, 532), fill=(200, 50, 40))
    for x in range(160, 255, 16):
        d.rectangle((x, 540, x + 9, 550), fill=(40, 60, 90))
    # cadre et textes
    d.rectangle((0, 640, w, h), fill=(30, 50, 90))
    f1 = font(64, italic=True, bold=True)
    f2 = font(30, italic=True)
    f3 = font(26, bold=True)
    d.text((w / 2, 60), "PORT-AZUR", font=f1, fill=(30, 50, 90), anchor="mm")
    d.text((w / 2, 112), "la perle de l'archipel", font=f2, fill=(60, 60, 80), anchor="mm")
    d.text((w / 2, 680), "Bateau de ligne « L'Hirondelle »", font=f3, fill=(250, 236, 200), anchor="mm")
    d.text((w / 2, 722), "Départ du ponton · 5 pièces", font=f2, fill=(250, 236, 200), anchor="mm")
    d.rectangle((0, 0, w - 1, h - 1), outline=(30, 50, 90), width=10)
    arr = np.asarray(img, np.float32) / 255.0
    wear = rect_noise(w, h, (8, 16, 32, 64), 0.6)
    arr *= (0.9 + 0.12 * wear[..., None])
    save_rgb(arr, AZ / "affiche_ferry.png")


# =================================================================== icônes d'objets

def se(img, box, base, **kw):
    x0, y0, x1, y1 = (int(round(v)) for v in box)
    icons.shaded_ellipse(img, (x0, y0, x1, y1), base, **kw)


def ic_croissant():
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    pts = []
    for k in range(7):
        t = k / 6
        a = math.pi * (0.15 + 0.7 * t)
        r = 150
        cx = 256 - math.cos(a) * r
        cy = 330 - math.sin(a) * r * 0.85
        s = 52 - abs(t - 0.5) * 60
        pts.append((cx, cy, s))
    for cx, cy, s in pts:
        se(img, (cx - s * 1.1, cy - s, cx + s * 1.1, cy + s), (214, 150, 64))
    d = ImageDraw.Draw(img)
    for cx, cy, s in pts[1:-1]:
        d.arc((cx - s, cy - s * 0.9, cx + s, cy + s * 0.9), 200, 340, fill=(150, 90, 30, 255), width=6)
    icons.save(img, "croissant")


def ic_baguette():
    img = icons.canvas()
    bag = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    se(bag, (40, 200, 472, 312), (216, 160, 80))
    d = ImageDraw.Draw(bag)
    for x in (130, 210, 290, 370):
        d.line([(x - 24, 240), (x + 24, 228)], fill=(240, 210, 150, 255), width=12)
    bag = bag.rotate(30, resample=Image.BICUBIC)
    img.alpha_composite(bag)
    icons.save(img, "baguette")


def ic_glace():
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.polygon([(176, 250), (336, 250), (256, 486)], fill=(214, 160, 90, 255))
    for k in range(6):
        d.line([(190 + k * 26, 260), (256, 470)], fill=(180, 120, 60, 255), width=4)
        d.line([(322 - k * 26, 260), (256, 470)], fill=(180, 120, 60, 255), width=4)
    se(img, (160, 150, 352, 300), (250, 180, 200))
    se(img, (190, 70, 322, 200), (250, 240, 200))
    se(img, (240, 40, 276, 76), (200, 30, 40))
    icons.save(img, "glace")


def ic_punch():
    img = icons.canvas()
    se(img, (110, 170, 402, 450), (120, 80, 50), gloss=False)
    d = ImageDraw.Draw(img)
    d.ellipse((140, 180, 372, 260), fill=(250, 240, 220, 255))
    d.ellipse((160, 192, 352, 250), fill=(240, 150, 60, 255))
    d.line([(300, 210), (390, 60)], fill=(220, 60, 80, 255), width=14)
    d.polygon([(170, 200), (130, 120), (230, 190)], fill=(60, 160, 80, 255))
    d.ellipse((330, 150, 410, 230), fill=(240, 220, 60, 255))
    icons.save(img, "punch_coco")


def ic_bouillabaisse():
    img = icons.canvas()
    se(img, (70, 210, 442, 440), (230, 230, 225))
    d = ImageDraw.Draw(img)
    d.ellipse((100, 220, 412, 330), fill=(200, 110, 40, 255))
    for _ in range(9):
        x, y = rng.uniform(140, 370), rng.uniform(240, 310)
        d.ellipse((x - 18, y - 10, x + 18, y + 10), fill=(240, 200, 150, 255))
    d.ellipse((300, 240, 340, 270), fill=(60, 60, 70, 255))
    d.polygon([(330, 230), (390, 200), (380, 240)], fill=(200, 60, 40, 255))
    icons.save(img, "bouillabaisse")


def ic_carte_postale():
    img = icons.canvas()
    card = Image.new("RGBA", (380, 260), (246, 240, 226, 255))
    d = ImageDraw.Draw(card)
    for y in range(20, 150):
        t = (y - 20) / 130
        d.line([(20, y), (240, y)], fill=(int(120 + 120 * t), int(180 + 40 * t), int(240 - 30 * t)))
    for y in range(150, 240):
        d.line([(20, y), (240, y)], fill=(30, 120, 170))
    d.polygon([(20, 150), (90, 110), (170, 140), (240, 150)], fill=(100, 140, 80))
    d.rectangle((280, 30, 350, 100), outline=(180, 60, 60, 255), width=5)
    for y in (140, 175, 210):
        d.line([(262, y), (360, y)], fill=(120, 110, 100, 255), width=3)
    d.rectangle((0, 0, 379, 259), outline=(150, 130, 100, 255), width=4)
    card = card.rotate(-8, resample=Image.BICUBIC, expand=True)
    img.alpha_composite(card, (40, 110))
    icons.save(img, "carte_postale")


def ic_partition():
    img = icons.canvas()
    page = Image.new("RGBA", (320, 400), (244, 236, 212, 255))
    d = ImageDraw.Draw(page)
    for s in range(4):
        y0 = 50 + s * 85
        for l in range(5):
            d.line([(20, y0 + l * 10), (300, y0 + l * 10)], fill=(60, 50, 40, 255), width=2)
        for k in range(7):
            x = 50 + k * 36
            y = y0 + rng.integers(0, 5) * 10 - 5
            d.ellipse((x - 9, y - 6, x + 9, y + 6), fill=(30, 26, 22, 255))
            d.line([(x + 8, y), (x + 8, y - 34)], fill=(30, 26, 22, 255), width=3)
    page = page.rotate(10, resample=Image.BICUBIC, expand=True)
    img.alpha_composite(page, (60, 40))
    icons.save(img, "partition")


def ic_cerf_volant():
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    top, right, bottom, left = (256, 40), (420, 200), (256, 400), (92, 200)
    d.polygon([top, right, (256, 200)], fill=(220, 50, 50, 255))
    d.polygon([right, bottom, (256, 200)], fill=(250, 200, 40, 255))
    d.polygon([bottom, left, (256, 200)], fill=(40, 110, 200, 255))
    d.polygon([left, top, (256, 200)], fill=(60, 170, 90, 255))
    d.line([top, bottom], fill=(90, 60, 30, 255), width=6)
    d.line([left, right], fill=(90, 60, 30, 255), width=6)
    pts = [(256 + math.sin(k * 0.9) * 30, 400 + k * 16) for k in range(8)]
    d.line(pts, fill=(80, 60, 40, 255), width=4)
    for k, p in enumerate(pts[1::2]):
        d.polygon([(p[0] - 14, p[1]), (p[0] + 14, p[1] - 10), (p[0] + 14, p[1] + 10)], fill=[(220, 50, 50, 255), (250, 200, 40, 255), (40, 110, 200, 255), (60, 170, 90, 255)][k % 4])
    icons.save(img, "cerf_volant")


def ic_alliance():
    img = icons.canvas()
    ring = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    d = ImageDraw.Draw(ring)
    d.ellipse((96, 150, 416, 440), outline=(232, 186, 70, 255), width=46)
    d.ellipse((120, 176, 392, 414), outline=(255, 226, 130, 255), width=8)
    img.alpha_composite(ring)
    d = ImageDraw.Draw(img)
    d.polygon([(256, 80), (300, 130), (256, 175), (212, 130)], fill=(220, 240, 255, 255))
    d.polygon([(256, 80), (300, 130), (256, 130)], fill=(255, 255, 255, 255))
    icons.save(img, "alliance")


def ic_cochonnet():
    img = icons.canvas()
    se(img, (166, 166, 346, 346), (200, 140, 70))
    d = ImageDraw.Draw(img)
    d.arc((180, 180, 332, 332), 120, 240, fill=(150, 100, 50, 255), width=5)
    icons.save(img, "cochonnet")


def ic_rouage():
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    c = 256
    pts = []
    for k in range(48):
        a = k / 48 * math.tau
        r = 200 if (k // 2) % 2 == 0 else 160
        pts.append((c + math.cos(a) * r, c + math.sin(a) * r))
    d.polygon(pts, fill=(196, 150, 60, 255))
    d.ellipse((c - 130, c - 130, c + 130, c + 130), fill=(214, 170, 80, 255))
    d.ellipse((c - 56, c - 56, c + 56, c + 56), fill=(0, 0, 0, 0))
    for k in range(5):
        a = k / 5 * math.tau
        d.ellipse((c + math.cos(a) * 92 - 22, c + math.sin(a) * 92 - 22, c + math.cos(a) * 92 + 22, c + math.sin(a) * 92 + 22), fill=(150, 110, 40, 255))
    icons.save(img, "rouage")


def ic_lentille():
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.ellipse((70, 70, 442, 442), fill=(160, 120, 50, 255))
    for k in range(6):
        r = 170 - k * 26
        d.ellipse((256 - r, 256 - r, 256 + r, 256 + r), fill=(150 + k * 15, 210 + k * 6, 230 + k * 4, 235))
    d.polygon([(170, 150), (240, 130), (190, 230)], fill=(255, 255, 255, 200))
    icons.save(img, "lentille_phare")


def ic_etoile():
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    pts = []
    for k in range(10):
        a = k / 10 * math.tau - math.pi / 2
        r = 210 if k % 2 == 0 else 90
        pts.append((256 + math.cos(a) * r, 266 + math.sin(a) * r))
    d.polygon(pts, fill=(230, 110, 50, 255))
    for k in range(5):
        a = k / 5 * math.tau - math.pi / 2
        for j in range(6):
            r = 40 + j * 28
            x, y = 256 + math.cos(a) * r, 266 + math.sin(a) * r
            d.ellipse((x - 7, y - 7, x + 7, y + 7), fill=(250, 190, 120, 255))
    icons.save(img, "etoile_mer")


def ic_cle():
    img = icons.canvas()
    k = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    d = ImageDraw.Draw(k)
    gold = (226, 182, 70, 255)
    d.ellipse((60, 160, 230, 330), outline=gold, width=34)
    d.rectangle((220, 230, 470, 262), fill=gold)
    d.rectangle((400, 262, 420, 320), fill=gold)
    d.rectangle((440, 262, 460, 300), fill=gold)
    d.ellipse((120, 220, 170, 270), fill=(200, 40, 50, 255))
    k = k.rotate(25, resample=Image.BICUBIC)
    img.alpha_composite(k)
    icons.save(img, "cle_ville")


def ic_appareil():
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((70, 160, 442, 400), radius=30, fill=(40, 38, 36, 255))
    d.rectangle((70, 200, 442, 230), fill=(160, 120, 80, 255))
    d.rectangle((120, 120, 220, 165), fill=(40, 38, 36, 255))
    d.ellipse((176, 196, 336, 356), fill=(190, 190, 195, 255))
    d.ellipse((196, 216, 316, 336), fill=(20, 24, 30, 255))
    d.ellipse((226, 240, 262, 276), fill=(140, 170, 210, 200))
    d.ellipse((360, 170, 400, 200), fill=(220, 220, 225, 255))
    icons.save(img, "appareil_photo")


def ic_corail():
    img = icons.canvas()
    d = ImageDraw.Draw(img)

    def branch(x, y, a, L, w, depth):
        if depth == 0 or L < 12:
            d.ellipse((x - w, y - w, x + w, y + w), fill=(232, 80, 70, 255))
            return
        x2, y2 = x + math.cos(a) * L, y + math.sin(a) * L
        d.line([(x, y), (x2, y2)], fill=(214, 60, 56, 255), width=int(w * 2))
        d.ellipse((x2 - w, y2 - w, x2 + w, y2 + w), fill=(214, 60, 56, 255))
        for s in (-0.5, 0.45):
            branch(x2, y2, a + s + rng.normal(0, 0.12), L * 0.72, w * 0.75, depth - 1)

    branch(256, 470, -math.pi / 2, 120, 22, 5)
    icons.save(img, "corail_rouge")


def ic_panier():
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.arc((120, 70, 392, 330), 190, 350, fill=(150, 100, 50, 255), width=22)
    for k in range(4):
        se(img, (140 + k * 50, 170 - (k % 2) * 30, 230 + k * 50, 260 - (k % 2) * 30), (216, 160, 80))
    d = ImageDraw.Draw(img)
    d.polygon([(90, 240), (422, 240), (380, 440), (132, 440)], fill=(178, 128, 64, 255))
    for y in range(256, 440, 26):
        d.line([(100 + (y - 240) * 0.2, y), (412 - (y - 240) * 0.2, y)], fill=(130, 88, 40, 255), width=6)
    for x in range(120, 400, 34):
        d.line([(x, 244), (x + (256 - x) * 0.12, 436)], fill=(150, 104, 52, 255), width=5)
    icons.save(img, "panier_pain")


def ic_billet():
    img = icons.canvas()
    t = Image.new("RGBA", (420, 220), (236, 214, 160, 255))
    d = ImageDraw.Draw(t)
    d.rectangle((0, 0, 419, 219), outline=(140, 60, 40, 255), width=8)
    d.line([(300, 10), (300, 210)], fill=(140, 60, 40, 255), width=3)
    f = font(40, bold=True)
    d.text((150, 80), "PASSAGE", font=f, fill=(140, 60, 40, 255), anchor="mm")
    d.text((150, 140), "Port-Azur", font=font(34, italic=True), fill=(60, 50, 40, 255), anchor="mm")
    d.text((360, 110), "N°\n56", font=font(30, bold=True), fill=(60, 50, 40, 255), anchor="mm")
    t = t.rotate(-12, resample=Image.BICUBIC, expand=True)
    img.alpha_composite(t, (30, 120))
    icons.save(img, "billet_ferry")


def ic_lettre():
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.rectangle((80, 150, 432, 380), fill=(240, 232, 214, 255))
    d.polygon([(80, 150), (256, 290), (432, 150)], fill=(220, 210, 190, 255))
    d.line([(80, 150), (256, 290), (432, 150)], fill=(150, 130, 100, 255), width=5)
    d.ellipse((226, 260, 286, 320), fill=(170, 30, 40, 255))
    icons.save(img, "lettre_azur")


# =================================================================== feuillages (cartes alpha)

def _leaf(d, x, y, a, L, W, col, edge=None):
    pts = []
    for k in range(9):
        t = k / 8
        w = math.sin(t * math.pi) * W * (1.0 - 0.3 * t)
        pts.append((t * L, w))
    pts += [(t, -w) for (t, w) in reversed(pts[1:-1])]
    ca, sa = math.cos(a), math.sin(a)
    poly = [(x + px * ca - py * sa, y + px * sa + py * ca) for px, py in pts]
    d.polygon(poly, fill=col, outline=edge)


def _card_save(img, name, dark=0.0):
    img = img.filter(ImageFilter.GaussianBlur(0.6))
    save_img(img, AZ / f"{name}.png")


def feuille_pin():
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for _ in range(26):
        cx, cy = rng.uniform(90, 420), rng.uniform(90, 420)
        n = int(rng.integers(30, 50))
        r = rng.uniform(55, 95)
        for k in range(n):
            a = rng.uniform(0, math.tau)
            L = r * rng.uniform(0.6, 1.0)
            g = int(rng.uniform(70, 120))
            col = (int(g * 0.45), g, int(g * 0.4), 255)
            d.line([(cx, cy), (cx + math.cos(a) * L, cy + math.sin(a) * L * 0.75)], fill=col, width=2)
        d.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=(90, 70, 40, 255))
    _card_save(img, "feuille_pin")


def feuille_olivier():
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for _ in range(9):
        x0, y0 = rng.uniform(60, 450), rng.uniform(60, 450)
        a0 = rng.uniform(0, math.tau)
        L0 = rng.uniform(140, 220)
        d.line([(x0, y0), (x0 + math.cos(a0) * L0, y0 + math.sin(a0) * L0)], fill=(90, 80, 60, 255), width=3)
        for k in range(16):
            t = k / 16
            bx, by = x0 + math.cos(a0) * L0 * t, y0 + math.sin(a0) * L0 * t
            for side in (-1, 1):
                a = a0 + side * rng.uniform(0.4, 0.9)
                silver = rng.random() < 0.4
                col = (int(rng.uniform(150, 175)), int(rng.uniform(165, 185)), int(rng.uniform(140, 160)), 255) if silver else (int(rng.uniform(70, 95)), int(rng.uniform(95, 115)), int(rng.uniform(60, 75)), 255)
                _leaf(d, bx, by, a, rng.uniform(34, 50), rng.uniform(5, 7), col)
    _card_save(img, "feuille_olivier")


def feuille_cypres():
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for _ in range(140):
        x, y = rng.uniform(40, 470), rng.uniform(30, 480)
        a = -math.pi / 2 + rng.normal(0, 0.5)
        L = rng.uniform(50, 110)
        g = int(rng.uniform(50, 85))
        col = (int(g * 0.5), g, int(g * 0.5), 255)
        x2, y2 = x + math.cos(a) * L, y + math.sin(a) * L
        d.line([(x, y), (x2, y2)], fill=col, width=7)
        for k in range(8):
            t = k / 8
            px, py = x + (x2 - x) * t, y + (y2 - y) * t
            d.ellipse((px - 6, py - 4, px + 6, py + 4), fill=(int(g * 0.55), int(g * 1.1), int(g * 0.5), 255))
    _card_save(img, "feuille_cypres")


def feuille_bougainvillier():
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for _ in range(60):
        _leaf(d, rng.uniform(40, 470), rng.uniform(40, 470), rng.uniform(0, math.tau), rng.uniform(40, 60), rng.uniform(12, 18), (int(rng.uniform(50, 80)), int(rng.uniform(100, 130)), 50, 255))
    for _ in range(70):
        cx, cy = rng.uniform(50, 460), rng.uniform(50, 460)
        hue = rng.uniform(0, 1)
        base = (int(200 + 40 * hue), int(30 + 30 * hue), int(130 + 40 * hue), 255)
        for k in range(3):
            a = k / 3 * math.tau + rng.uniform(-0.3, 0.3)
            px, py = cx + math.cos(a) * 12, cy + math.sin(a) * 12
            d.ellipse((px - 16, py - 13, px + 16, py + 13), fill=base, outline=(int(base[0] * 0.75), int(base[1] * 0.6), int(base[2] * 0.75), 255))
        d.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=(250, 240, 200, 255))
    _card_save(img, "feuille_bougainvillier")


def feuille_laurier():
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for _ in range(70):
        _leaf(d, rng.uniform(40, 470), rng.uniform(60, 480), -math.pi / 2 + rng.normal(0, 0.8), rng.uniform(80, 120), rng.uniform(9, 13), (int(rng.uniform(40, 60)), int(rng.uniform(85, 105)), int(rng.uniform(45, 60)), 255))
    for _ in range(14):
        cx, cy = rng.uniform(80, 430), rng.uniform(60, 260)
        for k in range(8):
            px, py = cx + rng.uniform(-30, 30), cy + rng.uniform(-22, 22)
            for j in range(5):
                a = j / 5 * math.tau
                d.ellipse((px + math.cos(a) * 8 - 7, py + math.sin(a) * 8 - 7, px + math.cos(a) * 8 + 7, py + math.sin(a) * 8 + 7), fill=(240, 120, 160, 255))
            d.ellipse((px - 4, py - 4, px + 4, py + 4), fill=(250, 200, 210, 255))
    _card_save(img, "feuille_laurier")


def feuille_platane():
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for _ in range(34):
        cx, cy = rng.uniform(60, 450), rng.uniform(60, 450)
        r = rng.uniform(34, 52)
        a0 = rng.uniform(0, math.tau)
        g = rng.uniform(0.8, 1.15)
        col = (int(90 * g), int(140 * g), int(60 * g), 255)
        pts = []
        for k in range(10):
            a = a0 + k / 10 * math.tau
            rr = r if k % 2 == 0 else r * 0.55
            pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
        d.polygon(pts, fill=col, outline=(int(60 * g), int(100 * g), int(40 * g), 255))
        for k in range(0, 10, 2):
            a = a0 + k / 10 * math.tau
            d.line([(cx, cy), (cx + math.cos(a) * r * 0.9, cy + math.sin(a) * r * 0.9)], fill=(int(120 * g), int(160 * g), int(90 * g), 255), width=2)
    _card_save(img, "feuille_platane")


def ecorce_platane():
    size = 512
    n = tile_noise(size, (4, 8, 16, 32), 0.55)
    f1, f2, ident = voronoi(size, 40)
    tone = (np.sin(ident * 3.1) * 43758.5453) % 1.0
    a = np.array([0.72, 0.7, 0.6])
    b = np.array([0.55, 0.56, 0.45])
    c = np.array([0.82, 0.8, 0.7])
    col = np.where((tone < 0.4)[..., None], a, np.where((tone < 0.75)[..., None], b, c))
    col = col * (0.85 + 0.2 * n[..., None])
    edge = np.exp(-((f2 - f1) / 2.0) ** 2)
    col *= 1 - edge[..., None] * 0.25
    save_rgb(col, AZ / "ecorce_platane.png")
    save_n(n * 0.4 - edge * 0.3, 4.0, AZ / "ecorce_platane_n.png")


def ecorce_pin():
    size = 512
    n = tile_noise(size, (4, 8, 16, 32, 64), 0.55)
    pts = []
    for r in range(14):
        y = (r + 0.5) / 14 * size
        x = rng.uniform(0, 30)
        while x < size:
            w = rng.uniform(40, 80)
            pts.append((x + w / 2, y + rng.uniform(-6, 6)))
            x += w
    f1, f2, ident = voronoi(size, len(pts), np.array(pts))
    edge = np.clip((f2 - f1) / 10.0, 0, 1)
    tone = (np.sin(ident * 5.3) * 43758.5453) % 1.0
    col = np.array([0.45, 0.3, 0.22])[None, None, :] * (0.7 + 0.4 * tone[..., None]) * (0.8 + 0.3 * n[..., None])
    col = col * (0.35 + 0.65 * edge[..., None] ** 0.5)
    save_rgb(col, AZ / "ecorce_pin.png")
    save_n(np.sqrt(edge) * 0.8 + n * 0.2, 6.0, AZ / "ecorce_pin_n.png")


def fenetre_lum():
    """Masque lumineux des fenêtres la nuit : le verre éclairé de l'intérieur, cadre éteint."""
    w, h = 256, 384
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    lum = np.zeros((h, w, 3), np.float32)
    warm = np.array([1.0, 0.72, 0.38])
    glow = 0.65 + 0.35 * (1 - yy / h)
    lum[:] = warm * glow[..., None]
    cur = (xx > 140) & (xx < 236) & (yy > 20) & (yy < 200)
    lum[cur] = np.array([1.0, 0.85, 0.6]) * 1.0
    frame = (xx < 14) | (xx > w - 15) | (yy < 14) | (yy > h - 15) | (np.abs(xx - w / 2) < 7)
    bars = (np.abs(((yy - 14) % ((h - 28) / 3))) < 4) & (yy > 20) & (yy < h - 20)
    bars |= (np.abs(xx - w / 4) < 3) | (np.abs(xx - 3 * w / 4) < 3)
    lum[frame | bars] = 0.0
    save_rgb(lum, AZ / "fenetre_lum.png")


def balcon():
    """Garde-corps en fer forgé : barreaux, volutes, main courante (alpha)."""
    w, h = 512, 256
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    iron = (28, 30, 32, 255)
    d.rectangle((0, 0, w, 14), fill=iron)
    d.rectangle((0, h - 12, w, h), fill=iron)
    d.rectangle((0, h - 70, w, h - 62), fill=iron)
    for x in range(8, w, 32):
        d.rectangle((x, 14, x + 5, h - 12), fill=iron)
    for x in range(24, w, 64):
        d.arc((x - 14, h - 66, x + 30, h - 22), 180, 360, fill=iron, width=5)
        d.arc((x - 14, h - 50, x + 30, h - 14), 0, 180, fill=iron, width=5)
        d.ellipse((x + 4, 30, x + 12, 38), fill=iron)
    save_img(img, AZ / "balcon.png")


def filet():
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    col = (150, 110, 70, 255)
    for k in range(-size, size * 2, 22):
        d.line([(k, 0), (k + size, size)], fill=col, width=3)
        d.line([(k, size), (k + size, 0)], fill=col, width=3)
    for _ in range(14):
        x, y = rng.uniform(0, size), rng.uniform(0, size)
        d.ellipse((x - 9, y - 9, x + 9, y + 9), fill=(214, 120, 40, 255))
    save_img(img, AZ / "filet.png")


def ic_sabre():
    img = icons.canvas()
    k = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    d = ImageDraw.Draw(k)
    steel = (214, 222, 230, 255)
    edge = (150, 160, 175, 255)
    # lame courbe
    pts_out, pts_in = [], []
    for i in range(41):
        t = i / 40
        x = 150 + t * 300
        y = 300 - t * 170 - math.sin(t * math.pi) * 40
        wdt = 26 * (1 - t) + 6
        pts_out.append((x, y - wdt * 0.5))
        pts_in.append((x, y + wdt * 0.5))
    d.polygon(pts_out + pts_in[::-1], fill=steel)
    d.line(pts_in, fill=edge, width=4)
    d.line([(160, 296), (430, 150)], fill=(245, 248, 252, 255), width=3)
    # garde en coquille et poignée
    gold = (210, 168, 64, 255)
    d.chord((92, 262, 182, 360), 200, 20, fill=gold)
    d.arc((70, 250, 190, 380), 120, 300, fill=gold, width=12)
    d.rounded_rectangle((70, 300, 120, 420), radius=14, fill=(90, 50, 30, 255))
    for yy in range(312, 410, 14):
        d.line([(72, yy), (118, yy + 8)], fill=(60, 34, 20, 255), width=4)
    d.ellipse((76, 410, 116, 446), fill=gold)
    k = k.rotate(10, resample=Image.BICUBIC, center=(256, 256))
    img.alpha_composite(k)
    icons.save(img, "sabre_corsaire")


def portrait_inconnu():
    """Le portrait d'un personnage pas encore rencontré : une silhouette sur papier."""
    w = h = 256
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, w - 1, h - 1), radius=24, fill=(216, 200, 170, 255))
    d.ellipse((88, 44, 168, 132), fill=(120, 104, 84, 255))
    d.chord((40, 130, 216, 330), 180, 360, fill=(120, 104, 84, 255))
    f = font(92, bold=True)
    d.text((w / 2, 92), "?", font=f, fill=(216, 200, 170, 255), anchor="mm")
    arr = np.asarray(img, np.float32) / 255.0
    wear = rect_noise(w, h, (8, 16, 32), 0.6)
    arr[..., :3] *= (0.9 + 0.12 * wear[..., None])
    out = TEX / "portraits" / "inconnu.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    save_rgba(arr, out)


def tableaux():
    """Trois toiles pour le hall du Grand Hôtel : la baie au phare, un champ de lavande, des
    barques au port. Peintes à grands coups de pinceau (taches orientées, bruit)."""
    for k in range(3):
        w, h = 512, 384
        img = Image.new("RGB", (w, h), (0, 0, 0))
        d = ImageDraw.Draw(img)
        if k == 0:
            bands = [(0, 200, (250, 214, 160), (130, 170, 220)), (200, 260, (60, 120, 170), (40, 90, 150)), (260, 384, (120, 150, 80), (90, 110, 60))]
        elif k == 1:
            bands = [(0, 150, (250, 200, 140), (150, 190, 230)), (150, 210, (120, 140, 90), (100, 120, 80)), (210, 384, (130, 100, 190), (90, 60, 150))]
        else:
            bands = [(0, 170, (240, 230, 210), (140, 180, 220)), (170, 384, (60, 140, 170), (30, 90, 130))]
        for y0, y1, c0, c1 in bands:
            for y in range(y0, y1):
                t = (y - y0) / max(1, y1 - y0)
                d.line([(0, y), (w, y)], fill=tuple(int(c0[i] + (c1[i] - c0[i]) * t) for i in range(3)))
        if k == 0:
            d.polygon([(330, 260), (380, 150), (512, 140), (512, 260)], fill=(140, 130, 110))
            d.rectangle((420, 70, 438, 150), fill=(245, 245, 240))
            d.rectangle((418, 60, 440, 72), fill=(200, 60, 40))
            d.ellipse((90, 40, 150, 100), fill=(255, 236, 180))
        elif k == 1:
            for r in range(14):
                y = 220 + r * 12
                for x in range(-20, w, 26):
                    d.ellipse((x + r * 6 % 26, y, x + r * 6 % 26 + 22, y + 9), fill=(150 + r * 3, 110, 200 - r * 3))
            d.rectangle((360, 120, 440, 170), fill=(230, 200, 160))
            d.polygon([(352, 122), (400, 96), (448, 122)], fill=(190, 90, 60))
            for x in (60, 120, 220):
                d.ellipse((x - 18, 120, x + 18, 175), fill=(70, 90, 50))
        else:
            for i, (x, c) in enumerate([(80, (200, 60, 50)), (220, (240, 240, 230)), (360, (60, 110, 180))]):
                y = 250 + (i % 2) * 30
                d.polygon([(x - 60, y), (x + 60, y), (x + 45, y + 22), (x - 45, y + 22)], fill=c)
                d.line([(x, y), (x, y - 110)], fill=(90, 70, 50), width=3)
                d.polygon([(x + 2, y - 105), (x + 2, y - 10), (x + 55, y - 12)], fill=(250, 246, 236))
            d.rectangle((0, 120, 512, 170), fill=(220, 190, 150))
            for x in range(10, 512, 44):
                d.rectangle((x, 90 - (x * 7) % 25, x + 36, 170), fill=((x * 3) % 60 + 190, (x * 5) % 70 + 150, (x * 2) % 50 + 110))
        arr = np.asarray(img, np.float32) / 255.0
        # coups de pinceau : on étire du bruit dans une direction, on module les couleurs
        strokes = np.asarray(Image.fromarray((tile_noise(512, (2, 4, 8), 0.6) * 255).astype(np.uint8)).resize((w, h // 6)).resize((w, h), Image.BICUBIC), np.float32)[..., None] / 255.0
        arr = arr * (0.85 + 0.3 * strokes)
        im2 = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.ModeFilter(5))
        im2.save(AZ / f"tableau_{k + 1}.png")
        print(f"tableau_{k + 1}")


ICONS = [ic_sabre, portrait_inconnu, ic_croissant, ic_baguette, ic_glace, ic_punch, ic_bouillabaisse, ic_carte_postale, ic_partition, ic_cerf_volant,
         ic_alliance, ic_cochonnet, ic_rouage, ic_lentille, ic_etoile, ic_cle, ic_appareil, ic_corail, ic_panier, ic_billet, ic_lettre]


if __name__ == "__main__":
    which = sys.argv[1:] or ["sols", "ville", "flore", "icones"]
    if "sols" in which:
        sable_azur(); terre_garrigue(); herbe_seche(); calcaire()
    if "ville" in which:
        paves(); dalles(); enduit(); tuiles(); moellons(); planches(); volet(); porte(); fenetre(); vitrine(); auvents(); horloge(); enseignes(); affiche_ferry()
    if "flore" in which:
        feuille_pin(); feuille_olivier(); feuille_cypres(); feuille_bougainvillier(); feuille_laurier(); feuille_platane()
        ecorce_platane(); ecorce_pin(); fenetre_lum(); balcon(); filet()
    if "icones" in which:
        for f in ICONS:
            f()
