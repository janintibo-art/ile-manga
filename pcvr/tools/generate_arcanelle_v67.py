"""V67 : textures d'Arcanelle, l'île des sorciers (au nord-ouest de l'archipel).

arcanelle/  galets (+_n)      : la grève de galets gris-bleu et de sable noir ;
            tourbe (+_n)      : la terre noire de la lande, brindilles de bruyère, cailloux ;
            bruyere (+_n)     : la lande : herbe rase, touffes de bruyère en fleurs (mauve) ;
            schiste (+_n)     : la roche feuilletée bleu ardoise, veines de quartz, lichens ;
            pierre_arc (+_n)  : les murs de moellons gris-bleu des tours et des maisons ;
            ecailles (+_n)    : les toits d'ardoise en écailles de poisson (bleu nuit) ;
            colombage (+_n)   : l'enduit crème des maisons à pans de bois ;
            dalles_arc (+_n)  : les dalles usées des cours et des places ;
            vitrail           : un vitrail en ogive (plomb, verres de couleur) ;
            rosace            : la rosace de l'Académie ;
            runes             : un cercle de runes (il luit : on le pose sur les sols) ;
            livres            : des rayonnages de vieux livres (la bibliothèque) ;
            carte_ciel        : la carte du ciel de l'observatoire ;
            enseigne_*        : enseignes du Chaudron Fumant, de L'Alambic, de la Bibliothèque ;
            banniere          : la bannière de l'Académie (une étoile, une lune) ;
items/      grimoire, eclat_lune, flocon_givre, plume_vent, livre_envole, potion_mana,
            elixir_etoile, baton_sorcier, hydromel, tarte_potiron, chouette_plume.
Tout est dessiné ici (libre de droits). Police : Lora (SIL OFL 1.1).
Lancement depuis la racine du dépôt : python3 pcvr/tools/generate_arcanelle_v67.py [textures | deco | icones]
"""
from pathlib import Path
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_azur_v56 as az  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "arcanelle"
rng = np.random.default_rng(6767)
az.rng = np.random.default_rng(6768)
tile_noise = az.tile_noise
wblur = az.wblur
voronoi = az.voronoi


def save_rgb(arr, name):
    az.save_rgb(arr, OUT / name)


def save_rgba(arr, name):
    az.save_rgba(arr, OUT / name)


def save_n(h, strength, name):
    az.save_n(h, strength, OUT / name)


def mix(a, b, t):
    t = np.asarray(t, np.float32)
    if t.ndim == 2:
        t = t[..., None]
    return np.asarray(a, np.float32) * (1 - t) + np.asarray(b, np.float32) * t


def specks(size, n, rmin, rmax, cols, cluster=None, thresh=0.5):
    """Petites taches (fleurs, éclats) posées au hasard, raccordables ; cluster : un bruit
    (0..1) qui décide où elles se regroupent. Renvoie (RGBA, alpha 0..1)."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    placed = 0
    tries = 0
    while placed < n and tries < n * 8:
        tries += 1
        x, y = rng.random(2) * size
        if cluster is not None and cluster[int(y) % size, int(x) % size] < thresh + rng.random() * 0.15:
            continue
        r = rng.uniform(rmin, rmax)
        c = cols[rng.integers(len(cols))]
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                d.ellipse((x + ox - r, y + oy - r, x + ox + r, y + oy + r), fill=c)
        placed += 1
    a = np.asarray(img.split()[3], np.float32) / 255.0
    return img, a


# =================================================================== les sols de l'île

def galets():
    """Grève de galets : galets ronds et plats serrés (on les pose les uns sur les autres),
    gris-bleu, quelques blancs (quartz) et rouille ; entre eux, du sable noir humide."""
    size = 1024
    fine = tile_noise(size, (128, 256, 512), 0.75)
    noise = tile_noise(size, (32, 64, 128, 256), 0.6)
    col = np.zeros((size, size, 3), np.float32)
    col[:] = np.array([0.13, 0.13, 0.14])
    col *= (0.75 + 0.5 * fine[..., None])
    h = fine * 0.1
    palette = [np.array(c) for c in ([0.44, 0.48, 0.53], [0.56, 0.56, 0.54], [0.32, 0.34, 0.37], [0.8, 0.78, 0.74], [0.52, 0.42, 0.34], [0.4, 0.42, 0.4])]
    weights = np.array([0.3, 0.26, 0.2, 0.08, 0.05, 0.11])
    for _ in range(6500):
        cx, cy = rng.random(2) * size
        rx = rng.uniform(7.0, 17.0)
        ry = rx * rng.uniform(0.6, 0.95)
        ang = rng.uniform(0, math.pi)
        base = palette[rng.choice(len(palette), p=weights)] * rng.uniform(0.85, 1.12)
        R = int(rx + 3)
        yy, xx = np.mgrid[-R:R + 1, -R:R + 1].astype(np.float32)
        ca, sa = math.cos(ang), math.sin(ang)
        u = (xx * ca + yy * sa) / rx
        v = (-xx * sa + yy * ca) / ry
        r2 = u * u + v * v
        m = r2 < 1.0
        if not m.any():
            continue
        z = np.sqrt(np.clip(1 - r2, 0, 1))
        lam = np.clip(-0.35 * u - 0.45 * v + 0.82 * z, 0, 1)
        shade = 0.45 + 0.7 * lam
        ix = (np.arange(-R, R + 1) + int(cx)) % size
        iy = (np.arange(-R, R + 1) + int(cy)) % size
        sub = col[np.ix_(iy, ix)]
        subh = h[np.ix_(iy, ix)]
        top = 0.4 + z * 0.6
        put = m & (top > subh)
        edge = np.clip((1 - np.sqrt(r2)) * rx / 1.5, 0, 1)
        newc = base[None, None, :] * shade[..., None] * (0.9 + 0.2 * fine[np.ix_(iy, ix)][..., None]) + (lam ** 14)[..., None] * 0.12
        sub = np.where(put[..., None], sub * (1 - edge[..., None]) + newc * edge[..., None], sub)
        subh = np.where(put, np.maximum(subh, top * edge), subh)
        col[np.ix_(iy, ix)] = sub
        h[np.ix_(iy, ix)] = subh
    weed = tile_noise(size, (8, 16, 32), 0.5)
    wm = np.clip((weed - 0.72) * 3.5, 0, 1) * 0.5
    col = mix(col, np.array([0.2, 0.19, 0.11]) * (0.7 + 0.6 * fine[..., None]), wm)
    col *= (0.9 + 0.14 * noise[..., None])
    save_rgb(col, "galets.png")
    save_n(h + wm * 0.1, 9.0, "galets_n.png")


def tourbe():
    """Terre noire de la lande : tourbe brun très sombre, racines, brindilles de bruyère
    sèche, petits cailloux de schiste, flaques de mousse."""
    size = 1024
    n = tile_noise(size)
    fine = tile_noise(size, (64, 128, 256, 512), 0.7)
    patch = tile_noise(size, (4, 8, 16), 0.55)
    peat = np.array([0.2, 0.15, 0.11])
    brown = np.array([0.33, 0.25, 0.17])
    col = mix(peat, brown, np.clip(patch * 1.4 - 0.3, 0, 1)) * (0.75 + 0.45 * fine[..., None]) * (0.9 + 0.15 * n[..., None])
    h = n * 0.35 + fine * 0.45
    img = Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB").convert("RGBA")
    stones = az.stamp_dots(size, 420, 2.0, 8.0, [(92, 98, 108, 255), (70, 76, 86, 255), (120, 124, 130, 255), (150, 148, 140, 255)])
    sh = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sh.paste((10, 6, 4, 140), (2, 3), stones.split()[3].filter(ImageFilter.GaussianBlur(2)))
    img.alpha_composite(sh)
    img.alpha_composite(stones)
    d = ImageDraw.Draw(img)
    hm = Image.new("L", (size, size), 0)
    dh = ImageDraw.Draw(hm)
    for _ in range(2600):
        x, y = rng.random(2) * size
        a = rng.uniform(0, math.pi * 2)
        L = rng.uniform(8, 30)
        c = [(96, 70, 48, 255), (70, 50, 36, 255), (122, 96, 70, 255), (60, 46, 52, 255)][rng.integers(4)]
        x2, y2 = x + math.cos(a) * L, y + math.sin(a) * L
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                d.line([(x + ox, y + oy), (x2 + ox, y2 + oy)], fill=c, width=2)
                dh.line([(x + ox, y + oy), (x2 + ox, y2 + oy)], fill=150, width=2)
                if rng.random() < 0.3:
                    bx, by = x + ox + math.cos(a) * L * 0.5, y + oy + math.sin(a) * L * 0.5
                    b2 = a + rng.choice([-0.7, 0.7])
                    d.line([(bx, by), (bx + math.cos(b2) * L * 0.4, by + math.sin(b2) * L * 0.4)], fill=c, width=1)
    # mousse verte dans les creux
    moss = tile_noise(size, (16, 32, 64), 0.55)
    arr = np.asarray(img.convert("RGB"), np.float32) / 255.0
    mm = np.clip((moss - 0.66) * 4.0, 0, 1) * 0.65
    arr = mix(arr, np.array([0.2, 0.3, 0.12]) * (0.7 + 0.5 * fine[..., None]), mm)
    st = np.asarray(stones.split()[3], np.float32) / 255.0
    tw = np.asarray(hm, np.float32) / 255.0
    save_rgb(wblur(arr, 0.4), "tourbe.png")
    save_n(h + wblur(st, 1.5) * 0.6 + tw * 0.25 + mm * 0.2, 6.0, "tourbe_n.png")


def bruyere():
    """La lande : herbe rase vert olive, coussins de bruyère (vert sombre) piquetés de petites
    fleurs mauves et roses, quelques ajoncs jaunes."""
    size = 1024
    base = tile_noise(size, (8, 16, 32, 64), 0.55)
    patch = tile_noise(size, (4, 8, 16, 32), 0.55)
    soil = np.array([0.2, 0.2, 0.12])
    arr = soil[None, None, :] * (0.7 + 0.5 * base[..., None])
    img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGB").convert("RGBA")
    d = ImageDraw.Draw(img)
    hmap = Image.new("L", (size, size), 0)
    dh = ImageDraw.Draw(hmap)
    # brins d'herbe
    for _ in range(30000):
        x, y = rng.random(2) * size
        p = patch[int(y) % size, int(x) % size]
        heath = p > 0.55
        t = rng.uniform(0, 1)
        if heath:
            c = (int(48 + 30 * t), int(66 + 28 * t), int(38 + 18 * t), 255)
            L = rng.uniform(6, 14)
        else:
            c = (int(92 + 50 * t), int(110 + 40 * t), int(48 + 24 * t), 255)
            L = rng.uniform(10, 24)
        a = -math.pi / 2 + rng.normal(0, 0.5)
        x2, y2 = x + math.cos(a) * L * 0.45, y + math.sin(a) * L
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                d.line([(x + ox, y + oy), (x2 + ox, y2 + oy)], fill=c, width=2)
                dh.line([(x + ox, y + oy), (x2 + ox, y2 + oy)], fill=int(110 + rng.uniform(0, 145)), width=2)
    # fleurs de bruyère (sur les coussins sombres) et d'ajonc
    fl, fa = specks(size, 9000, 1.2, 2.6, [(170, 86, 160, 255), (196, 110, 186, 255), (140, 64, 132, 255), (214, 150, 206, 255)], patch, 0.56)
    img.alpha_composite(fl)
    gorse, ga = specks(size, 700, 1.4, 2.8, [(232, 196, 60, 255), (244, 214, 92, 255)], 1.0 - patch, 0.62)
    img.alpha_composite(gorse)
    img = img.convert("RGB").filter(ImageFilter.GaussianBlur(0.35))
    h = np.asarray(hmap, np.float32) / 255.0
    az.save_img(img, OUT / "bruyere.png")
    save_n(wblur(h, 0.8) * 0.8 + base * 0.2 + fa * 0.2, 5.0, "bruyere_n.png")


def lande():
    """L'herbe rase de la lande, vue de près : brins vert olive et jaune paille, quelques trouées
    de terre brune, des coussins de mousse, de rares brins de bruyère mauve et de petites fleurs."""
    size = 1024
    base = tile_noise(size, (8, 16, 32, 64), 0.55)
    patch = tile_noise(size, (4, 8, 16, 32), 0.55)
    dry = tile_noise(size, (2, 4, 8), 0.6)
    soil = np.array([0.32, 0.26, 0.17])
    arr = soil[None, None, :] * (0.75 + 0.5 * base[..., None])
    img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGB").convert("RGBA")
    d = ImageDraw.Draw(img)
    hmap = Image.new("L", (size, size), 0)
    dh = ImageDraw.Draw(hmap)
    for _ in range(46000):
        x, y = rng.random(2) * size
        p = patch[int(y) % size, int(x) % size]
        if p < 0.32 and rng.random() < 0.7:
            continue                      # une trouée de terre
        t = rng.uniform(0, 1)
        dd = dry[int(y) % size, int(x) % size]
        if rng.random() < 0.06 + 0.3 * max(0.0, dd - 0.55):
            c = (int(150 + 40 * t), int(140 + 34 * t), int(82 + 26 * t), 255)        # paille
        else:
            c = (int(72 + 50 * t), int(112 + 52 * t), int(40 + 26 * t), 255)         # vert de lande
        L = rng.uniform(8, 20)
        a = -math.pi / 2 + rng.normal(0, 0.55)
        x2, y2 = x + math.cos(a) * L * 0.45, y + math.sin(a) * L
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                d.line([(x + ox, y + oy), (x2 + ox, y2 + oy)], fill=c, width=2)
                dh.line([(x + ox, y + oy), (x2 + ox, y2 + oy)], fill=int(110 + rng.uniform(0, 145)), width=2)
    moss, ma = specks(size, 900, 4.0, 9.0, [(70, 100, 40, 255), (84, 116, 46, 255), (60, 88, 36, 255)], patch, 0.62)
    img.alpha_composite(moss)
    fl, fa = specks(size, 1400, 1.0, 2.2, [(170, 86, 160, 255), (196, 110, 186, 255), (232, 226, 210, 255)], patch, 0.7)
    img.alpha_composite(fl)
    img = img.convert("RGB").filter(ImageFilter.GaussianBlur(0.35))
    h = np.asarray(hmap, np.float32) / 255.0
    az.save_img(img, OUT / "lande.png")
    save_n(wblur(h, 0.8) * 0.8 + base * 0.2 + ma * 0.3, 5.0, "lande_n.png")


def schiste():
    """Roche feuilletée bleu ardoise : strates fines et inclinées, cassures en marches, veines
    de quartz blanc, lichens jaune-vert et gris."""
    size = 1024
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    n = tile_noise(size, (4, 8, 16, 32, 64, 128, 256))
    fine = tile_noise(size, (64, 128, 256, 512), 0.7)
    warp = tile_noise(size, (4, 8, 16), 0.55)
    ph = (yy / size * 26.0 + xx / size * 4.0 + warp * 3.0) * math.tau
    layers = np.sin(ph) * 0.5 + 0.5
    steps = np.floor((yy / size * 13.0 + xx / size * 2.0 + warp * 1.5) * 1.0) / 13.0
    stp = (np.sin(steps * 97.0) * 0.5 + 0.5)
    f1, f2, _ = voronoi(size, 26)
    crack = np.exp(-((f2 - f1) / 1.4) ** 2) * np.clip((tile_noise(size, (4, 8, 16), 0.5) - 0.42) * 3.0, 0, 1)
    fol = np.mod(yy / size * 18.0 + xx / size * 3.0 + warp * 2.0, 1.0)
    lip = np.clip((fol - 0.86) * 8.0, 0, 1)
    h = layers * 0.22 + stp * 0.35 + n * 0.3 + fine * 0.18 - crack * 0.35 + fol * 0.25
    a = np.array([0.32, 0.36, 0.42])
    b = np.array([0.44, 0.47, 0.5])
    c = np.array([0.26, 0.28, 0.32])
    col = mix(a, b, layers * 0.6 + stp * 0.4)
    col = mix(col, c, np.clip((n - 0.6) * 2.0, 0, 1))
    col = col * (0.78 + 0.3 * fine[..., None]) * (1 - crack[..., None] * 0.5) * (1 - lip[..., None] * 0.35) * (0.9 + 0.15 * fol[..., None])
    # veines de quartz : quelques traits fins, presque droits, en travers des strates
    vimg = Image.new("L", (size, size), 0)
    vd = ImageDraw.Draw(vimg)
    for _ in range(14):
        x, y = rng.random(2) * size
        a = rng.uniform(0.9, 2.2)
        L = rng.uniform(80, 260)
        pts = [(x, y)]
        for k in range(8):
            a += rng.normal(0, 0.12)
            x += math.cos(a) * L / 8
            y += math.sin(a) * L / 8
            pts.append((x, y))
        wv = int(rng.integers(2, 5))
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                vd.line([(px + ox, py + oy) for px, py in pts], fill=255, width=wv)
    qm = wblur(np.asarray(vimg, np.float32) / 255.0, 0.8)
    col = mix(col, np.array([0.8, 0.8, 0.78]), qm * 0.75)
    # lichens
    li = tile_noise(size, (16, 32, 64), 0.55) * tile_noise(size, (64, 128, 256), 0.6)
    lm = np.clip((li - 0.48) * 6.0, 0, 1) * 0.5
    col = mix(col, np.array([0.62, 0.66, 0.36]), lm)
    gl = tile_noise(size, (32, 64, 128), 0.6)
    gm = np.clip((gl - 0.72) * 5.0, 0, 1) * 0.35
    col = mix(col, np.array([0.66, 0.68, 0.66]), gm)
    save_rgb(col, "schiste.png")
    save_n(h + qm * 0.1, 8.0, "schiste_n.png")


# =================================================================== les murs et les toits

def pierre_arc():
    """Moellons de pierre bleue grossièrement équarris, assises irrégulières, joints de
    mortier gris enfoncés ; quelques pierres plus claires, de la mousse dans les joints."""
    size = 1024
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    ident = np.zeros((size, size), np.int32)
    y = 0
    k = 0
    bounds = []
    while y < size:
        hrow = int(rng.choice([64, 72, 80, 96, 56]))
        if y + hrow > size - 40:
            hrow = size - y
        x = rng.uniform(0, size)
        start = x
        while x < start + size:
            w = rng.uniform(90, 200)
            if x + w > start + size - 50:
                w = start + size - x
            m = (yy >= y) & (yy < y + hrow) & (np.mod(xx - x, size) < w)
            ident[m] = k
            bounds.append((y, hrow))
            k += 1
            x += w
        y += hrow
    ids = ident.astype(np.float32)
    gx = np.abs(np.diff(ids, axis=1, append=ids[:, :1])) > 0
    gy = np.abs(np.diff(ids, axis=0, append=ids[:1, :])) > 0
    joint = (gx | gy).astype(np.float32)
    # joints irréguliers : on les épaissit avec un bruit
    jn = tile_noise(size, (16, 32, 64), 0.6)
    joint = np.clip(wblur(joint, 1.6) * (3.5 + jn * 4.0), 0, 1)
    # chaque pierre : un bombé (le bord s'arrondit), une teinte
    edge = np.clip(1.0 - wblur(joint, 3.5) * 1.8, 0, 1)
    noise = tile_noise(size)
    fine = tile_noise(size, (64, 128, 256, 512), 0.7)
    tone = (np.sin(ident * 12.9898) * 43758.5453) % 1.0
    tone2 = (np.sin(ident * 78.233) * 12345.678) % 1.0
    a = np.array([0.46, 0.49, 0.53])
    b = np.array([0.58, 0.58, 0.57])
    c = np.array([0.4, 0.4, 0.42])
    d_ = np.array([0.62, 0.56, 0.48])
    col = np.where((tone < 0.42)[..., None], a, np.where((tone < 0.75)[..., None], b, np.where((tone < 0.92)[..., None], c, d_)))
    grit = rng.random((size, size)).astype(np.float32)
    grit = az.blur(grit, 0.5)
    pits = np.clip((tile_noise(size, (64, 128, 256), 0.7) - 0.62) * 4.0, 0, 1)
    col = col * (0.78 + 0.18 * tone2[..., None]) * (0.78 + 0.34 * noise[..., None]) * (0.84 + 0.28 * fine[..., None]) * (0.9 + 0.2 * grit[..., None])
    col = col * (1 - pits[..., None] * 0.25)
    col = col * (0.6 + 0.4 * edge[..., None])
    mortar = np.array([0.52, 0.52, 0.5]) * (0.75 + 0.3 * fine[..., None])
    col = mix(col, mortar * 0.8, joint)
    moss = tile_noise(size, (8, 16, 32), 0.55)
    mm = np.clip((moss - 0.6) * 3.0, 0, 1) * np.clip(joint * 1.5, 0, 1) * 0.7
    col = mix(col, np.array([0.24, 0.32, 0.14]), mm)
    h = edge * 0.7 + noise * 0.2 + fine * 0.25 + grit * 0.08 - pits * 0.15 - joint * 0.6
    save_rgb(col, "pierre_arc.png")
    save_n(h, 7.0, "pierre_arc_n.png")


def ecailles():
    """Ardoises en écailles de poisson : rangées décalées de petites ardoises arrondies du
    bas, bleu nuit et violet sombre, bords éclatés, quelques lichens."""
    size = 1024
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    cols = 16
    rows = 20
    cw = size / cols
    rh = size / rows
    row = np.floor(yy / rh).astype(np.int32)
    shift = (row % 2) * 0.5
    u = (xx / cw + shift)
    ci = np.floor(u).astype(np.int32)
    fu = u - ci - 0.5
    v = (yy - row * rh) / rh
    # ardoise arrondie du bas : la limite est un demi-cercle
    rim = np.sqrt(np.clip(0.25 - fu * fu, 0, 1)) * 1.8
    lower = v > (0.55 + rim * 0.45)
    # recouvrement : la rangée du dessous (plus bas dans l'image) recouvre le bas de celle-ci
    h = 0.35 + (1 - v) * 0.4
    h = np.where(lower, h - 0.25, h)
    border = np.clip(1.0 - np.abs(v - (0.55 + rim * 0.45)) * 30.0, 0, 1)
    side = np.clip(1.0 - (0.5 - np.abs(fu)) * 26.0, 0, 1)
    tone = (np.sin((ci * 31 + row * 17) * 12.9898) * 43758.5453) % 1.0
    a = np.array([0.2, 0.22, 0.32])
    b = np.array([0.26, 0.24, 0.36])
    c = np.array([0.17, 0.19, 0.24])
    base = np.where((tone < 0.4)[..., None], a, np.where((tone < 0.78)[..., None], b, c))
    noise = tile_noise(size, (16, 32, 64, 128, 256), 0.6)
    col = base * (0.8 + 0.35 * (1 - v)[..., None]) * (0.85 + 0.3 * noise[..., None])
    col = col * (1 - border[..., None] * 0.45) * (1 - side[..., None] * 0.35)
    col = np.where(lower[..., None], col * 0.62, col)
    li = tile_noise(size, (16, 32, 64), 0.55) * tile_noise(size, (64, 128, 256), 0.6)
    m = np.clip((li - 0.55) * 6.0, 0, 1) * 0.35
    col = mix(col, np.array([0.5, 0.56, 0.42]), m)
    save_rgb(col, "ecailles.png")
    save_n(h - border * 0.2 - side * 0.1 + noise * 0.06, 7.0, "ecailles_n.png")


def colombage():
    """Enduit à la chaux crème des maisons à pans de bois (le bois est posé par-dessus)."""
    size = 1024
    n = tile_noise(size, (4, 8, 16, 32, 64), 0.6)
    fine = tile_noise(size, (128, 256, 512), 0.75)
    trowel = np.abs(tile_noise(size, (8, 16, 32), 0.5) - 0.5) * 2.0
    yy = np.mgrid[0:size, 0:size][0].astype(np.float32) / size
    v = 0.84 + 0.08 * n + 0.05 * fine - 0.06 * trowel ** 3
    streak = tile_noise(size, (64, 128), 0.5)
    streak = np.asarray(Image.fromarray((streak * 255).astype(np.uint8)).resize((size // 8, size)).resize((size, size), Image.BICUBIC), np.float32) / 255.0
    v -= np.clip(streak - 0.6, 0, 1) * 0.22 * (0.3 + 0.7 * yy)
    col = np.dstack([v * 0.98, v * 0.94, v * 0.84])
    save_rgb(col, "colombage.png")
    save_n(n * 0.3 + fine * 0.4 - trowel * 0.25, 3.0, "colombage_n.png")


def dalles_arc():
    """Dalles de schiste bleu des cours et des places, irrégulières, joints herbus."""
    size = 1024
    pts = []
    for r in range(7):
        for c in range(7):
            pts.append(((c + 0.5 + rng.uniform(-0.3, 0.3)) / 7 * size, (r + 0.5 + rng.uniform(-0.3, 0.3)) / 7 * size))
    pts = np.array(pts)
    f1, f2, ident = voronoi(size, len(pts), pts)
    edge = np.clip((f2 - f1) / 10.0, 0, 1)
    noise = tile_noise(size)
    fine = tile_noise(size, (64, 128, 256, 512), 0.7)
    tone = rng.random(len(pts))[ident]
    a = np.array([0.42, 0.45, 0.5])
    b = np.array([0.52, 0.53, 0.54])
    col = mix(a, b, tone) * (0.82 + 0.25 * noise[..., None]) * (0.9 + 0.14 * fine[..., None])
    worn = np.clip(edge * 1.6, 0, 1)
    col *= (0.8 + 0.2 * worn[..., None])
    joint = 1 - np.clip((edge - 0.08) * 6.0, 0, 1)
    grass = np.array([0.22, 0.3, 0.14]) * (0.7 + 0.6 * fine[..., None])
    col = mix(col, grass, joint * 0.85)
    h = worn * 0.6 + noise * 0.25 + fine * 0.15 - joint * 0.3
    save_rgb(col, "dalles_arc.png")
    save_n(h, 6.0, "dalles_arc_n.png")


def textures():
    galets()
    tourbe()
    bruyere()
    lande()
    schiste()
    pierre_arc()
    ecailles()
    colombage()
    dalles_arc()


# =================================================================== vitraux, runes, livres, enseignes

PALETTE = [(70, 60, 170), (40, 90, 190), (150, 50, 150), (220, 170, 50), (60, 150, 140), (180, 40, 60), (110, 70, 190)]


def vitrail():
    """Un vitrail en ogive : réseau de plomb, verres de couleur (bleus, violets, or), une étoile
    et un croissant au milieu. L'émission (la nuit) reprend la même image."""
    w, h = 256, 512
    img = Image.new("RGB", (w, h), (18, 16, 22))
    d = ImageDraw.Draw(img)
    pts = rng.random((60, 2)) * np.array([w, h])
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    best = np.full((h, w), 1e9, np.float32)
    second = np.full((h, w), 1e9, np.float32)
    idx = np.zeros((h, w), np.int32)
    for i, (px, py) in enumerate(pts):
        dd = np.hypot(xx - px, (yy - py) * 0.8)
        closer = dd < best
        second = np.where(closer, best, np.minimum(second, dd))
        idx = np.where(closer, i, idx)
        best = np.where(closer, dd, best)
    cols = np.array([PALETTE[rng.integers(len(PALETTE))] for _ in range(len(pts))], np.float32) / 255.0
    col = cols[idx]
    noise = rng.random((h, w)).astype(np.float32)
    col = col * (0.8 + 0.3 * az.blur(noise, 2.0)[..., None])
    lead = (second - best) < 3.0
    col[lead] = np.array([0.08, 0.07, 0.09])
    im = Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8))
    d = ImageDraw.Draw(im)
    # étoile et croissant
    cx, cy = w / 2, h * 0.42
    star = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5
        r = 54 if k % 2 == 0 else 22
        star.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    d.polygon(star, fill=(250, 214, 90), outline=(20, 16, 20))
    d.ellipse((cx - 40, h * 0.7 - 40, cx + 40, h * 0.7 + 40), fill=(236, 236, 220), outline=(20, 16, 20), width=4)
    d.ellipse((cx - 22, h * 0.7 - 50, cx + 46, h * 0.7 + 28), fill=(40, 60, 150), outline=(20, 16, 20), width=4)
    # ogive : en dehors de l'arc, le cadre de pierre (noir, il est caché par le mur)
    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    md.rectangle((10, h * 0.32, w - 10, h - 10), fill=255)
    r = w - 20
    md.pieslice((10, 10, 10 + 2 * r, 10 + 2 * r * 1.0), 180, 270, fill=255)
    md.pieslice((w - 10 - 2 * r, 10, w - 10, 10 + 2 * r * 1.0), 270, 360, fill=255)
    inter = Image.new("L", (w, h), 0)
    ImageDraw.Draw(inter).ellipse((10, 10, 10 + 2 * r, 10 + 2 * r), fill=255)
    inter2 = Image.new("L", (w, h), 0)
    ImageDraw.Draw(inter2).ellipse((w - 10 - 2 * r, 10, w - 10, 10 + 2 * r), fill=255)
    arch = np.minimum(np.asarray(inter, np.float32), np.asarray(inter2, np.float32))
    arch[int(h * 0.32):] = 0
    m = np.maximum(arch, 0)
    m[int(h * 0.32):h - 10, 10:w - 10] = 255
    out = np.asarray(im, np.float32) / 255.0
    out = out * (m[..., None] / 255.0) + np.array([0.06, 0.05, 0.07]) * (1 - m[..., None] / 255.0)
    # le cadre de plomb autour
    frame = (m > 0).astype(np.float32)
    fr = az.blur(frame, 3.0)
    border = (fr > 0.05) & (fr < 0.85)
    out[border] = np.array([0.08, 0.07, 0.09])
    save_rgb(out, "vitrail.png")


def rosace():
    """La rosace de l'Académie : douze pétales autour d'un œil d'or, verres bleus et violets."""
    S = 512
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = S / 2
    R = S * 0.48
    d.ellipse((c - R, c - R, c + R, c + R), fill=(16, 14, 20, 255))
    for ring, (r0, r1, n, cols) in enumerate([(0.5, 0.95, 12, [(50, 70, 180), (120, 50, 160)]), (0.22, 0.5, 8, [(40, 120, 190), (200, 150, 40)])]):
        for k in range(n):
            a0 = k * math.tau / n
            a1 = (k + 1) * math.tau / n
            am = (a0 + a1) / 2
            pts = [(c + math.cos(a0 + 0.04) * R * r0, c + math.sin(a0 + 0.04) * R * r0)]
            for t in np.linspace(0, 1, 12):
                aa = a0 + 0.04 + (a1 - a0 - 0.08) * t
                rr = R * (r1 - 0.06 * math.sin(t * math.pi) * 0.0)
                pts.append((c + math.cos(aa) * rr, c + math.sin(aa) * rr))
            pts.append((c + math.cos(a1 - 0.04) * R * r0, c + math.sin(a1 - 0.04) * R * r0))
            col = cols[k % 2]
            d.polygon(pts, fill=col + (255,))
            # petit cercle dans chaque pétale
            pr = R * (r1 - r0) * 0.22
            px, py = c + math.cos(am) * R * (r0 + r1) / 2, c + math.sin(am) * R * (r0 + r1) / 2
            d.ellipse((px - pr, py - pr, px + pr, py + pr), fill=(230, 190, 70, 255), outline=(16, 14, 20, 255), width=5)
    d.ellipse((c - R * 0.2, c - R * 0.2, c + R * 0.2, c + R * 0.2), fill=(250, 210, 90, 255), outline=(16, 14, 20, 255), width=8)
    for k in range(12):
        a = k * math.tau / 12
        d.line([(c + math.cos(a) * R * 0.2, c + math.sin(a) * R * 0.2), (c + math.cos(a) * R * 0.97, c + math.sin(a) * R * 0.97)], fill=(16, 14, 20, 255), width=7)
    for rr in (0.22, 0.5, 0.95):
        d.ellipse((c - R * rr, c - R * rr, c + R * rr, c + R * rr), outline=(16, 14, 20, 255), width=8)
    arr = np.asarray(img, np.float32) / 255.0
    noise = tile_noise(S, (16, 32, 64, 128), 0.6)
    arr[..., :3] *= (0.8 + 0.35 * noise[..., None])
    save_rgba(arr, "rosace.png")


RUNES = ["ᚠ", "ᚢ", "ᚦ", "ᚨ", "ᚱ", "ᚲ", "ᚷ", "ᚹ", "ᚺ", "ᚾ", "ᛁ", "ᛃ", "ᛇ", "ᛈ", "ᛉ", "ᛊ", "ᛏ", "ᛒ", "ᛖ", "ᛗ", "ᛚ", "ᛜ", "ᛞ", "ᛟ"]


def _rune_glyph(d, cx, cy, s, k, fill, width):
    """Une rune tracée au trait (la police n'a pas les runes) : des barres et des branches."""
    r = np.random.default_rng(1000 + k)
    d.line([(cx, cy - s), (cx, cy + s)], fill=fill, width=width)
    for _ in range(r.integers(1, 4)):
        y0 = cy + r.uniform(-s, s * 0.6)
        side = r.choice([-1, 1])
        y1 = y0 + r.choice([-1, 1]) * s * r.uniform(0.3, 0.7)
        d.line([(cx, y0), (cx + side * s * 0.6, y1)], fill=fill, width=width)
    if r.random() < 0.4:
        d.ellipse((cx - s * 0.3, cy - s * 0.3, cx + s * 0.3, cy + s * 0.3), outline=fill, width=width)


def runes():
    """Un cercle de runes (blanc sur transparent : le matériau le teinte et le fait luire)."""
    S = 1024
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = S / 2
    W = (255, 255, 255, 255)
    for r, wd in ((0.47, 10), (0.4, 6), (0.24, 6), (0.2, 4)):
        d.ellipse((c - S * r, c - S * r, c + S * r, c + S * r), outline=W, width=wd)
    for k in range(24):
        a = k * math.tau / 24 - math.pi / 2
        rx, ry = c + math.cos(a) * S * 0.435, c + math.sin(a) * S * 0.435
        _rune_glyph(d, rx, ry, 22, k, W, 6)
    # étoile à sept branches
    pts = []
    for k in range(7):
        a = -math.pi / 2 + k * math.tau / 7
        pts.append((c + math.cos(a) * S * 0.4, c + math.sin(a) * S * 0.4))
    for k in range(7):
        d.line([pts[k], pts[(k + 3) % 7]], fill=W, width=6)
    for k in range(12):
        a = k * math.tau / 12
        rx, ry = c + math.cos(a) * S * 0.22, c + math.sin(a) * S * 0.22
        d.ellipse((rx - 9, ry - 9, rx + 9, ry + 9), fill=W)
    _rune_glyph(d, c, c, 60, 99, W, 10)
    a = np.asarray(img.split()[3], np.float32) / 255.0
    glow = az.blur(a, 6.0) * 0.6
    alpha = np.clip(a + glow, 0, 1)
    arr = np.dstack([np.ones_like(alpha), np.ones_like(alpha), np.ones_like(alpha), alpha])
    save_rgba(arr, "runes.png")


def livres():
    """Des rayonnages de vieux livres : dos de cuir rouges, bruns, verts, bleus, titres dorés,
    quelques livres couchés ; les planches de l'étagère en haut et en bas."""
    W, H = 512, 512
    img = Image.new("RGB", (W, H), (30, 20, 14))
    d = ImageDraw.Draw(img)
    shelves = 4
    sh = H / shelves
    leather = [(110, 30, 26), (70, 40, 24), (40, 70, 44), (36, 50, 92), (120, 84, 40), (84, 30, 70), (150, 120, 80), (52, 34, 28)]
    for s in range(shelves):
        y0 = int(s * sh + 14)
        y1 = int((s + 1) * sh - 6)
        x = 4
        while x < W - 6:
            if rng.random() < 0.07:
                # quelques livres couchés
                hh = rng.integers(10, 18)
                n = rng.integers(2, 5)
                for k in range(n):
                    c = leather[rng.integers(len(leather))]
                    d.rectangle((x, y1 - (k + 1) * hh, x + 70, y1 - k * hh - 1), fill=c)
                    d.line((x + 4, y1 - k * hh - hh // 2, x + 66, y1 - k * hh - hh // 2), fill=(200, 170, 90), width=1)
                x += 76
                continue
            bw = int(rng.integers(12, 30))
            bh = int(rng.integers(int((y1 - y0) * 0.62), y1 - y0))
            c = leather[rng.integers(len(leather))]
            t = rng.uniform(0.75, 1.15)
            c = tuple(int(min(255, v * t)) for v in c)
            d.rectangle((x, y1 - bh, x + bw, y1), fill=c)
            d.line((x, y1 - bh, x, y1), fill=tuple(int(v * 0.6) for v in c), width=2)
            d.line((x + bw - 2, y1 - bh, x + bw - 2, y1), fill=tuple(int(v * 0.6) for v in c), width=2)
            for k in range(rng.integers(1, 4)):
                yy = y1 - bh + 10 + k * 10 + rng.integers(0, 6)
                d.line((x + 2, yy, x + bw - 3, yy), fill=(196, 160, 80), width=2)
            if bw > 16 and rng.random() < 0.6:
                d.rectangle((x + 4, y1 - bh * 0.6, x + bw - 5, y1 - bh * 0.45), fill=(170, 140, 70))
            x += bw + int(rng.integers(0, 3))
        d.rectangle((0, int((s + 1) * sh - 6), W, int((s + 1) * sh + 8)), fill=(92, 62, 38))
        d.line((0, int((s + 1) * sh - 6), W, int((s + 1) * sh - 6)), fill=(140, 100, 64), width=2)
    arr = np.asarray(img, np.float32) / 255.0
    noise = tile_noise(W, (16, 32, 64, 128), 0.6)
    arr *= (0.85 + 0.25 * noise[..., None])
    save_rgb(arr, "livres.png")


def carte_ciel():
    """La carte du ciel de l'observatoire : constellations reliées sur un fond bleu nuit."""
    S = 512
    img = Image.new("RGB", (S, S), (14, 20, 46))
    d = ImageDraw.Draw(img)
    for _ in range(500):
        x, y = rng.random(2) * S
        r = rng.uniform(0.5, 1.6)
        g = int(rng.uniform(150, 255))
        d.ellipse((x - r, y - r, x + r, y + r), fill=(g, g, int(g * 0.9 + 20)))
    for _ in range(9):
        cx, cy = rng.random(2) * S
        pts = [(cx + rng.uniform(-60, 60), cy + rng.uniform(-60, 60)) for _ in range(rng.integers(4, 7))]
        d.line(pts, fill=(200, 180, 110), width=2)
        for p in pts:
            d.ellipse((p[0] - 4, p[1] - 4, p[0] + 4, p[1] + 4), fill=(255, 240, 190))
    for r in (240, 180, 120):
        d.ellipse((S / 2 - r, S / 2 - r, S / 2 + r, S / 2 + r), outline=(120, 110, 80), width=2)
    d.rectangle((0, 0, S - 1, S - 1), outline=(150, 120, 60), width=8)
    arr = np.asarray(img, np.float32) / 255.0
    save_rgb(arr, "carte_ciel.png")


ENSEIGNES = {
    "chaudron": ("Le Chaudron Fumant", "taverne · hydromel · soupe", (54, 30, 66), (236, 200, 120)),
    "alambic": ("L'Alambic", "potions & élixirs", (24, 52, 60), (180, 236, 210)),
    "bibliotheque": ("Bibliothèque", "silence, les livres dorment", (60, 36, 22), (232, 210, 160)),
    "academie": ("Académie d'Arcanelle", "Fiat lux", (30, 26, 70), (240, 214, 120)),
}


def enseignes():
    for key, (title, sub, bg, ink) in ENSEIGNES.items():
        w, h = 1024, 256
        arr = np.zeros((h, w, 3), np.float32)
        grain = az.rect_noise(w, h, (4, 8, 16, 32), 0.6)
        gs = np.asarray(Image.fromarray((grain * 255).astype(np.uint8)).resize((w, h // 8)).resize((w, h), Image.BICUBIC), np.float32) / 255.0
        arr[:] = np.array(bg) / 255.0
        arr *= (0.75 + 0.4 * gs[..., None])
        img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8)).convert("RGBA")
        d = ImageDraw.Draw(img)
        d.rounded_rectangle((6, 6, w - 7, h - 7), radius=26, outline=(20, 14, 10, 255), width=10)
        d.rounded_rectangle((22, 22, w - 23, h - 23), radius=18, outline=ink + (255,), width=3)
        # étoiles dans les coins
        for (sx, sy) in ((70, 70), (w - 70, 70), (70, h - 70), (w - 70, h - 70)):
            pts = []
            for k in range(10):
                a = -math.pi / 2 + k * math.pi / 5
                r = 22 if k % 2 == 0 else 9
                pts.append((sx + math.cos(a) * r, sy + math.sin(a) * r))
            d.polygon(pts, fill=ink + (255,))
        size = 104
        f = az.font(size, italic=True, bold=True)
        while d.textlength(title, font=f) > w - 220 and size > 40:
            size -= 4
            f = az.font(size, italic=True, bold=True)
        d.text((w / 2 + 3, h * 0.42 + 4), title, font=f, fill=(0, 0, 0, 120), anchor="mm")
        d.text((w / 2, h * 0.42), title, font=f, fill=ink + (255,), anchor="mm")
        fs = az.font(40, italic=True)
        d.text((w / 2, h * 0.78), sub, font=fs, fill=ink + (230,), anchor="mm")
        a2 = np.asarray(img, np.float32) / 255.0
        wear = az.rect_noise(w, h, (8, 16, 32, 64), 0.6)
        a2[..., :3] *= (0.86 + 0.16 * wear[..., None])
        save_rgba(a2, f"enseigne_{key}.png")


def banniere():
    """La bannière de l'Académie : velours violet, une étoile d'or au-dessus d'un croissant,
    bord frangé (transparent en dessous)."""
    w, h = 256, 768
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    body = [(0, 0), (w, 0), (w, h - 110), (w / 2, h - 20), (0, h - 110)]
    d.polygon(body, fill=(70, 34, 110, 255))
    d.line([(14, 0), (14, h - 116), (w / 2, h - 36), (w - 14, h - 116), (w - 14, 0)], fill=(220, 180, 80, 255), width=8)
    cx = w / 2
    pts = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5
        r = 70 if k % 2 == 0 else 28
        pts.append((cx + math.cos(a) * r, 230 + math.sin(a) * r))
    d.polygon(pts, fill=(240, 204, 90, 255))
    d.ellipse((cx - 60, 380, cx + 60, 500), fill=(236, 230, 210, 255))
    d.ellipse((cx - 30, 362, cx + 80, 482), fill=(70, 34, 110, 255))
    for k in range(5):
        y = 560 + k * 0
    arr = np.asarray(img, np.float32) / 255.0
    noise = az.rect_noise(w, h, (4, 8, 16, 32), 0.6)
    arr[..., :3] *= (0.78 + 0.3 * noise[..., None])
    save_rgba(arr, "banniere.png")


def deco():
    vitrail()
    rosace()
    runes()
    livres()
    carte_ciel()
    enseignes()
    banniere()


# =================================================================== icônes

def icones():
    import generate_items_v28 as icons  # noqa: E402
    icons.OUT = ROOT / "www" / "assets" / "textures" / "items"
    S = 512

    def star(d, cx, cy, r1, r2, fill, n=5, rot=-math.pi / 2):
        pts = []
        for k in range(n * 2):
            a = rot + k * math.pi / n
            r = r1 if k % 2 == 0 else r2
            pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
        d.polygon(pts, fill=fill)

    # grimoire : un gros livre de cuir violet, coins d'or, une étoile sur la couverture
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.polygon([(110, 140), (400, 110), (420, 390), (130, 420)], fill=(230, 220, 190, 255))
    d.polygon([(96, 130), (392, 100), (412, 380), (116, 410)], fill=(84, 36, 110, 255))
    d.polygon([(96, 130), (120, 128), (140, 408), (116, 410)], fill=(56, 22, 76, 255))
    for (x, y) in ((96, 130), (392, 100), (412, 380), (116, 410)):
        d.ellipse((x - 18, y - 18, x + 18, y + 18), fill=(222, 180, 70, 255))
    star(d, 262, 250, 74, 30, (240, 206, 90, 255))
    d.ellipse((246, 234, 278, 266), fill=(150, 220, 255, 255))
    d.rectangle((400, 220, 440, 280), fill=(200, 160, 60, 255))
    icons.save(img, "grimoire")
    # éclat de lune : un cristal pâle, bleuté, qui luit
    img = icons.canvas()
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((90, 90, 422, 422), fill=(160, 200, 255, 120))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(40)))
    d = ImageDraw.Draw(img)
    d.polygon([(256, 70), (330, 220), (290, 440), (200, 430), (170, 230)], fill=(200, 222, 250, 255))
    d.polygon([(256, 70), (330, 220), (262, 250)], fill=(238, 246, 255, 255))
    d.polygon([(170, 230), (262, 250), (200, 430)], fill=(160, 186, 230, 255))
    d.polygon([(262, 250), (290, 440), (200, 430)], fill=(130, 160, 214, 255))
    icons.save(img, "eclat_lune")
    # flocon de givre : un flocon à six branches, bleu glacier
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    c = 256
    for k in range(6):
        a = k * math.pi / 3
        x2, y2 = c + math.cos(a) * 190, c + math.sin(a) * 190
        icons.stick_polygon(d, (c, c), (x2, y2), 30, (170, 220, 250, 255))
        for t in (0.45, 0.72):
            bx, by = c + math.cos(a) * 190 * t, c + math.sin(a) * 190 * t
            for s in (-1, 1):
                b = a + s * 0.8
                icons.stick_polygon(d, (bx, by), (bx + math.cos(b) * 64, by + math.sin(b) * 64), 20, (200, 236, 255, 255))
    d.ellipse((c - 40, c - 40, c + 40, c + 40), fill=(230, 248, 255, 255))
    icons.save(img, "flocon_givre")
    # plume du vent : une longue plume blanche aux reflets bleu ciel
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    for k in range(22):
        t = k / 21
        x = 120 + t * 280
        y = 400 - t * 300
        L = 90 * math.sin(t * math.pi) + 18
        col = (int(220 + 30 * t), int(236 + 10 * t), 255, 255)
        d.line([(x, y), (x - L * 0.75, y - L * 0.55)], fill=col, width=16)
        d.line([(x, y), (x + L * 0.55, y + L * 0.75)], fill=(int(190 + 40 * t), int(214 + 30 * t), 250, 255), width=16)
    d.line([(100, 430), (410, 90)], fill=(210, 200, 170, 255), width=10)
    icons.save(img, "plume_vent")
    # livre envolé : un livre ouvert, les pages qui battent comme des ailes
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.polygon([(256, 300), (90, 220), (110, 140), (256, 210)], fill=(240, 232, 210, 255))
    d.polygon([(256, 300), (422, 220), (402, 140), (256, 210)], fill=(232, 224, 200, 255))
    d.polygon([(256, 320), (80, 236), (90, 220), (256, 300)], fill=(150, 40, 40, 255))
    d.polygon([(256, 320), (432, 236), (422, 220), (256, 300)], fill=(130, 34, 34, 255))
    for k in range(5):
        y = 180 + k * 18
        d.line([(126, y - 6 + k * 4), (240, y + 30 - k * 2)], fill=(120, 110, 100, 255), width=4)
        d.line([(272, y + 30 - k * 2), (386, y - 6 + k * 4)], fill=(120, 110, 100, 255), width=4)
    for (x, y) in ((140, 360), (370, 380), (256, 420)):
        star(d, x, y, 22, 9, (250, 220, 120, 255), 4)
    icons.save(img, "livre_envole")

    def flask(name, liquid, glow_col, cork=(150, 110, 70), shape="rond"):
        img = icons.canvas()
        if glow_col is not None:
            g = Image.new("RGBA", (S, S), (0, 0, 0, 0))
            ImageDraw.Draw(g).ellipse((110, 170, 402, 462), fill=glow_col + (130,))
            img.alpha_composite(g.filter(ImageFilter.GaussianBlur(36)))
        d = ImageDraw.Draw(img)
        if shape == "rond":
            d.ellipse((126, 190, 386, 450), fill=(210, 230, 240, 200))
            d.rectangle((218, 96, 294, 210), fill=(210, 230, 240, 220))
            d.chord((140, 204, 372, 436), 10, 170, fill=liquid + (255,))
            d.ellipse((150, 280, 362, 330), fill=tuple(min(255, int(v * 1.25)) for v in liquid) + (255,))
        else:
            d.polygon([(200, 100), (312, 100), (312, 200), (400, 440), (112, 440), (200, 200)], fill=(210, 230, 240, 200))
            d.polygon([(166, 300), (346, 300), (390, 430), (122, 430)], fill=liquid + (255,))
        d.rectangle((206, 64, 306, 116), fill=cork + (255,))
        d.ellipse((180, 230, 230, 300), fill=(255, 255, 255, 150))
        icons.save(img, name)

    flask("potion_mana", (60, 90, 220), (90, 140, 255))
    flask("elixir_etoile", (230, 190, 60), (255, 220, 120), (90, 60, 120), "conique")
    # bâton de sorcier : bois noueux, un cristal violet au sommet
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    for (x, y) in ((450, 60), (330, 50), (460, 190)):
        star(d, x, y, 20, 7, (220, 190, 255, 255), 4)
    icons.stick_polygon(d, (110, 460), (370, 150), 30, (110, 72, 40, 255))
    icons.stick_polygon(d, (370, 150), (420, 90), 22, (96, 62, 34, 255))
    icons.stick_polygon(d, (370, 150), (330, 80), 18, (96, 62, 34, 255))
    d.polygon([(390, 50), (440, 110), (400, 190), (350, 120)], fill=(170, 100, 240, 255))
    d.polygon([(390, 50), (440, 110), (395, 115)], fill=(220, 180, 255, 255))
    for k in range(3):
        y = 300 + k * 26
        d.line([(230 - k * 18, y - 30), (262 - k * 18, y + 6)], fill=(70, 46, 26, 255), width=6)
    icons.save(img, "baton_sorcier")
    # hydromel : une corne-chope de miel doré
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((140, 150, 350, 430), radius=30, fill=(150, 104, 60, 255))
    d.rectangle((160, 170, 330, 410), fill=(210, 150, 50, 255))
    d.ellipse((150, 130, 340, 190), fill=(250, 236, 200, 255))
    d.arc((310, 210, 420, 360), -80, 80, fill=(150, 104, 60, 255), width=26)
    for y in (200, 300, 400):
        d.line([(140, y), (350, y)], fill=(90, 60, 30, 255), width=10)
    icons.save(img, "hydromel")
    # tarte au potiron
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.ellipse((90, 170, 422, 400), fill=(196, 140, 72, 255))
    d.ellipse((120, 186, 392, 370), fill=(226, 128, 40, 255))
    for k in range(10):
        a = k * math.tau / 10
        d.line([(256, 278), (256 + math.cos(a) * 130, 278 + math.sin(a) * 88)], fill=(200, 110, 34, 255), width=4)
    d.polygon([(256, 278), (400, 250), (410, 300)], fill=(240, 220, 200, 255))
    icons.save(img, "tarte_potiron")
    # plume de chouette (récompense du soin de la chouette)
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    for k in range(18):
        t = k / 17
        x = 150 + t * 220
        y = 410 - t * 300
        L = 70 * math.sin(t * math.pi) + 14
        col = (int(150 + 40 * (k % 2)), int(116 + 30 * (k % 2)), int(80 + 20 * (k % 2)), 255)
        d.line([(x, y), (x - L * 0.7, y - L * 0.6)], fill=col, width=18)
        d.line([(x, y), (x + L * 0.6, y + L * 0.7)], fill=col, width=18)
    d.line([(130, 440), (380, 100)], fill=(230, 220, 200, 255), width=8)
    icons.save(img, "chouette_plume")


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else "tout"
    if what in ("textures", "tout"):
        textures()
    if what in ("deco", "tout"):
        deco()
    if what in ("icones", "tout"):
        icones()


if __name__ == "__main__":
    main()
