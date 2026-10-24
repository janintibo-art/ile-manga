"""V68 : textures de l'Île de la Balafre, l'île des pirates (au nord de l'archipel).

pirates/  sable (+_n)        : sable doré des grèves, débris de coquillages et de corail, algues ;
          terre (+_n)        : la terre rouge de la jungle, feuilles mortes, racines, cailloux ;
          sousbois (+_n)     : le sous-bois : fougères, jeunes pousses, feuilles larges, mousse ;
          basalte (+_n)      : roche volcanique sombre, bulles, fissures, lichens vert-de-gris ;
          vase (+_n)         : la vase du marais, flaques luisantes, lentilles d'eau, brindilles ;
          (le reste — bois, toiles, voiles, pavillons, enseignes, avis de recherche, la carte
          au trésor, les dés — avec « deco »).
items/    dent_croco, croc_geant, des_pipes, carte_morceau, carte_barbe, bourse_lestrange,
          herbe_fievre, graines, poing_fer, ceinture_champion, tricorne_or, plume_perroquet,
          rhum_balafre, ragout_pirate, remontant_doc (avec « icones »).
Tout est dessiné ici (libre de droits). Police : Lora (SIL OFL 1.1).
Lancement depuis la racine du dépôt : python3 pcvr/tools/generate_pirates_v68.py [sols | deco | icones]
"""
from pathlib import Path
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_azur_v56 as az  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "pirates"
ITEMS = ROOT / "www" / "assets" / "textures" / "items"
rng = np.random.default_rng(6868)
az.rng = np.random.default_rng(6869)
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
    """Petites taches posées au hasard, raccordables ; cluster : un bruit (0..1) qui décide où
    elles se regroupent. Renvoie (RGBA, alpha 0..1)."""
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


def leaf_poly(x, y, L, W, a):
    """Une feuille (losange arrondi) de longueur L, largeur W, orientée a."""
    pts = []
    for k in range(12):
        t = k / 11.0
        r = W * math.sin(math.pi * t) * (0.55 + 0.45 * math.sin(math.pi * t))
        u = (t - 0.5) * L
        pts.append((u, r))
    for k in range(11, -1, -1):
        t = k / 11.0
        r = W * math.sin(math.pi * t) * (0.55 + 0.45 * math.sin(math.pi * t))
        pts.append(((t - 0.5) * L, -r))
    ca, sa = math.cos(a), math.sin(a)
    return [(x + u * ca - v * sa, y + u * sa + v * ca) for u, v in pts]


# =================================================================== les sols

def sable():
    """Sable doré des grèves tropicales : grains fins, rides du ressac, éclats de coquillages
    blancs et roses, brindilles de corail, quelques algues sèches."""
    size = 1024
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    warp = tile_noise(size, (4, 8, 16), 0.6)
    ph = (yy / size * 12.0 + warp * 2.8 + xx / size * 1.0) * math.tau
    ripple = (np.sin(ph) * 0.5 + 0.5) ** 2.2 * 0.32
    grain = tile_noise(size, (128, 256, 512), 0.75)
    patch = tile_noise(size, (4, 8, 16), 0.5)
    h = ripple + grain * 0.5 + patch * 0.15
    base = np.array([0.9, 0.79, 0.57])
    col = base[None, None, :] * (0.82 + 0.2 * grain[..., None] + 0.08 * ripple[..., None]) * (0.93 + 0.1 * patch[..., None])
    img = Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB").convert("RGBA")
    img.alpha_composite(az.stamp_dots(size, 1600, 0.8, 2.8, [(248, 240, 226, 255), (236, 196, 184, 255), (204, 174, 128, 255), (128, 110, 88, 255), (252, 248, 240, 255)]))
    # brindilles de corail et algues sèches
    d = ImageDraw.Draw(img)
    for _ in range(260):
        x, y = rng.random(2) * size
        c = [(232, 160, 150, 255), (244, 226, 210, 255), (96, 80, 52, 255), (70, 62, 40, 255)][rng.integers(4)]
        a = rng.uniform(0, math.tau)
        L = rng.uniform(6, 16)
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                d.line([(x + ox, y + oy), (x + ox + math.cos(a) * L, y + oy + math.sin(a) * L)], fill=c, width=2)
    img = img.convert("RGB").filter(ImageFilter.GaussianBlur(0.45))
    az.save_img(img, OUT / "sable.png")
    save_n(h, 5.0, "sable_n.png")


def terre():
    """Terre rouge de la jungle (latérite) : mottes, cailloux, racines, et un tapis de feuilles
    mortes brunes et ocre, plus ou moins épais."""
    size = 1024
    n = tile_noise(size)
    fine = tile_noise(size, (64, 128, 256, 512), 0.7)
    patch = tile_noise(size, (4, 8, 16), 0.55)
    red = np.array([0.46, 0.24, 0.14])
    ochre = np.array([0.56, 0.36, 0.2])
    col = mix(red, ochre, np.clip(patch * 1.4 - 0.2, 0, 1)) * (0.72 + 0.4 * fine[..., None]) * (0.9 + 0.15 * n[..., None])
    h = n * 0.35 + fine * 0.4
    img = Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB").convert("RGBA")
    stones = az.stamp_dots(size, 300, 2.0, 7.0, [(110, 92, 80, 255), (84, 70, 62, 255), (140, 120, 104, 255)])
    img.alpha_composite(stones)
    d = ImageDraw.Draw(img)
    hm = Image.new("L", (size, size), 0)
    dh = ImageDraw.Draw(hm)
    # racines
    for _ in range(60):
        x, y = rng.random(2) * size
        a = rng.uniform(0, math.tau)
        pts = [(x, y)]
        for k in range(10):
            a += rng.normal(0, 0.35)
            x += math.cos(a) * 9
            y += math.sin(a) * 9
            pts.append((x, y))
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                d.line([(px + ox, py + oy) for px, py in pts], fill=(74, 50, 34, 255), width=4)
                dh.line([(px + ox, py + oy) for px, py in pts], fill=200, width=4)
    # feuilles mortes
    leaves = tile_noise(size, (4, 8, 16), 0.55)
    for _ in range(5200):
        x, y = rng.random(2) * size
        if leaves[int(y) % size, int(x) % size] < 0.42 + rng.random() * 0.2:
            continue
        L = rng.uniform(12, 30)
        W = L * rng.uniform(0.22, 0.38)
        a = rng.uniform(0, math.tau)
        t = rng.random()
        c = (int(120 + 70 * t), int(70 + 50 * t), int(32 + 20 * t), 255) if rng.random() < 0.7 else (int(84 + 30 * t), int(60 + 20 * t), int(36 + 10 * t), 255)
        poly = leaf_poly(x, y, L, W, a)
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                pp = [(px + ox, py + oy) for px, py in poly]
                d.polygon(pp, fill=c)
                dh.polygon(pp, fill=int(90 + rng.uniform(0, 120)))
                d.line([(x + ox - math.cos(a) * L * 0.5, y + oy - math.sin(a) * L * 0.5), (x + ox + math.cos(a) * L * 0.5, y + oy + math.sin(a) * L * 0.5)], fill=(int(c[0] * 0.7), int(c[1] * 0.7), int(c[2] * 0.7), 255), width=1)
    arr = np.asarray(img.convert("RGB"), np.float32) / 255.0
    st = np.asarray(stones.split()[3], np.float32) / 255.0
    lh = np.asarray(hm, np.float32) / 255.0
    save_rgb(wblur(arr, 0.4), "terre.png")
    save_n(h + wblur(st, 1.5) * 0.5 + lh * 0.3, 6.0, "terre_n.png")


def sousbois():
    """Le sous-bois de la jungle : un tapis de petites plantes vert sombre (fougères, jeunes
    pousses, feuilles larges luisantes), de la mousse, quelques trouées de feuilles mortes."""
    size = 1024
    base = tile_noise(size, (8, 16, 32, 64), 0.55)
    patch = tile_noise(size, (4, 8, 16, 32), 0.55)
    soil = np.array([0.16, 0.13, 0.08])
    arr = soil[None, None, :] * (0.7 + 0.5 * base[..., None])
    img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGB").convert("RGBA")
    d = ImageDraw.Draw(img)
    hmap = Image.new("L", (size, size), 0)
    dh = ImageDraw.Draw(hmap)
    # feuilles mortes dans les trouées
    for _ in range(1800):
        x, y = rng.random(2) * size
        if patch[int(y) % size, int(x) % size] > 0.4:
            continue
        L = rng.uniform(10, 24)
        a = rng.uniform(0, math.tau)
        t = rng.random()
        poly = leaf_poly(x, y, L, L * 0.3, a)
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                d.polygon([(px + ox, py + oy) for px, py in poly], fill=(int(104 + 50 * t), int(70 + 30 * t), int(36 + 14 * t), 255))
    # fougères et jeunes pousses : des feuilles vertes de toutes tailles
    for _ in range(16000):
        x, y = rng.random(2) * size
        p = patch[int(y) % size, int(x) % size]
        if p < 0.3 and rng.random() < 0.8:
            continue
        L = rng.uniform(8, 26) * (1.3 if p > 0.65 else 1.0)
        W = L * rng.uniform(0.18, 0.42)
        a = rng.uniform(0, math.tau)
        t = rng.random()
        if rng.random() < 0.12:
            c = (int(78 + 40 * t), int(104 + 34 * t), int(36 + 20 * t), 255)          # vert tendre
        else:
            c = (int(24 + 30 * t), int(50 + 40 * t), int(20 + 18 * t), 255)           # vert sombre
        poly = leaf_poly(x, y, L, W, a)
        hv = int(120 + rng.uniform(0, 135))
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                pp = [(px + ox, py + oy) for px, py in poly]
                d.polygon(pp, fill=c)
                dh.polygon(pp, fill=hv)
    moss, ma = specks(size, 700, 4.0, 10.0, [(52, 86, 30, 255), (64, 98, 36, 255)], patch, 0.6)
    img.alpha_composite(moss)
    img = img.convert("RGB").filter(ImageFilter.GaussianBlur(0.4))
    h = np.asarray(hmap, np.float32) / 255.0
    az.save_img(img, OUT / "sousbois.png")
    save_n(wblur(h, 0.9) * 0.8 + base * 0.2 + ma * 0.2, 5.0, "sousbois_n.png")


def basalte():
    """Roche volcanique sombre : basalte gris-noir, bulles (vacuoles), fissures en orgues,
    traînées de rouille, lichens vert-de-gris et blancs."""
    size = 1024
    n = tile_noise(size, (4, 8, 16, 32, 64, 128, 256))
    fine = tile_noise(size, (64, 128, 256, 512), 0.7)
    f1, f2, ident = voronoi(size, 34)
    crack = np.exp(-((f2 - f1) / 1.6) ** 2)
    cell = (np.sin(ident * 12.9898) * 43758.5453) % 1.0
    h = n * 0.45 + fine * 0.2 - crack * 0.45 + cell * 0.12
    col = mix(np.array([0.17, 0.17, 0.18]), np.array([0.27, 0.26, 0.26]), np.clip(n * 1.2 - 0.1, 0, 1))
    col = col * (0.82 + 0.3 * fine[..., None]) * (0.92 + 0.14 * cell[..., None]) * (1 - crack[..., None] * 0.55)
    # vacuoles
    vac, va = specks(size, 3500, 0.8, 3.0, [(16, 16, 18, 255)])
    arr = np.asarray(Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB").convert("RGBA"), np.float32)
    v = va[..., None]
    arr[..., :3] = arr[..., :3] * (1 - v * 0.8) + 16 * v * 0.8
    col = arr[..., :3] / 255.0
    rust = tile_noise(size, (8, 16, 32), 0.6)
    col = mix(col, np.array([0.38, 0.22, 0.13]), np.clip((rust - 0.7) * 3.0, 0, 1) * 0.45)
    li = tile_noise(size, (16, 32, 64), 0.55) * tile_noise(size, (64, 128, 256), 0.6)
    lm = np.clip((li - 0.52) * 6.0, 0, 1) * 0.35
    col = mix(col, np.array([0.42, 0.5, 0.36]), lm)
    wl = tile_noise(size, (32, 64, 128), 0.6)
    col = mix(col, np.array([0.62, 0.64, 0.6]), np.clip((wl - 0.74) * 5.0, 0, 1) * 0.3)
    save_rgb(col, "basalte.png")
    save_n(h - va * 0.25, 8.0, "basalte_n.png")


def vase():
    """La vase du marais : boue gris-brun luisante, flaques sombres où flottent des lentilles
    d'eau vert vif, brindilles noires, traces de pas (de crocodile ?)."""
    size = 1024
    n = tile_noise(size, (4, 8, 16, 32, 64), 0.55)
    fine = tile_noise(size, (64, 128, 256, 512), 0.7)
    pud = tile_noise(size, (4, 8, 16), 0.55)
    wet = np.clip((pud - 0.55) * 4.0, 0, 1)
    col = mix(np.array([0.27, 0.23, 0.16]), np.array([0.36, 0.31, 0.22]), np.clip(n * 1.3 - 0.2, 0, 1))
    col = col * (0.8 + 0.3 * fine[..., None])
    col = mix(col, np.array([0.07, 0.075, 0.05]), wet * 0.85)
    h = n * 0.4 + fine * 0.25 - wet * 0.5
    img = Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB").convert("RGBA")
    duck, da = specks(size, 7000, 1.0, 2.2, [(70, 108, 32, 255), (86, 122, 40, 255), (58, 92, 28, 255)], pud, 0.66)
    duck = duck.filter(ImageFilter.GaussianBlur(0.6))
    img.alpha_composite(duck)
    da = np.asarray(duck.split()[3], np.float32) / 255.0
    d = ImageDraw.Draw(img)
    for _ in range(900):
        x, y = rng.random(2) * size
        a = rng.uniform(0, math.tau)
        L = rng.uniform(6, 20)
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                d.line([(x + ox, y + oy), (x + ox + math.cos(a) * L, y + oy + math.sin(a) * L)], fill=(34, 28, 20, 255), width=2)
    arr = np.asarray(img.convert("RGB"), np.float32) / 255.0
    save_rgb(wblur(arr, 0.5), "vase.png")
    save_n(h + da * 0.15, 5.0, "vase_n.png")


def sols():
    sable()
    terre()
    sousbois()
    basalte()
    vase()


# =================================================================== le bois, la paille, la pierre

def planchesp():
    """Planches de bardage délavées par le sel (horizontales) : bois gris-brun, veines, nœuds,
    clous rouillés, coulures de goudron, un peu de lichen ; assez clair pour être teinté
    (planches peintes : rouge, vert, bleu délavés)."""
    size = 1024
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    n_rows = 8
    ph = size / n_rows
    wob = tile_noise(size, (2, 4, 8), 0.6) * 10.0
    row = ((yy + wob) // ph).astype(np.int32) % n_rows
    v = ((yy + wob) % ph) / ph
    grain = tile_noise(size, (8, 16, 32, 64), 0.6)
    gs = np.asarray(Image.fromarray((grain * 255).astype(np.uint8)).resize((size, size // 16)).resize((size, size), Image.BICUBIC), np.float32) / 255.0
    lines = (np.sin(yy / 3.0 + gs * 14.0) * 0.5 + 0.5) ** 3
    tone = (np.sin(row * 7.31) * 43758.5453) % 1.0
    base = np.array([0.6, 0.55, 0.48])
    col = base[None, None, :] * (0.74 + 0.3 * tone[..., None]) * (0.8 + 0.22 * gs[..., None]) * (0.9 + 0.1 * lines[..., None])
    # recouvrement : l'ombre sous chaque planche
    shade = np.clip(1.0 - v / 0.12, 0, 1)
    col *= (1.0 - 0.55 * shade[..., None])
    # bouts de planches décalés (joints verticaux)
    off = (np.sin(row * 3.17) * 43758.5453 % 1.0) * size
    jx = np.mod(xx + off, size / 2.0)
    joint = (jx < 3.0)
    col[joint] *= 0.35
    # goudron et sel
    tar = tile_noise(size, (4, 8, 16), 0.6)
    col = mix(col, np.array([0.12, 0.1, 0.08]), np.clip((tar - 0.72) * 4.0, 0, 1) * 0.6)
    salt = tile_noise(size, (16, 32, 64), 0.6)
    col = mix(col, np.array([0.78, 0.78, 0.74]), np.clip((salt - 0.75) * 4.0, 0, 1) * 0.35)
    li = tile_noise(size, (16, 32, 64), 0.55)
    col = mix(col, np.array([0.5, 0.56, 0.36]), np.clip((li - 0.8) * 5.0, 0, 1) * 0.4)
    # clous rouillés
    for r in range(n_rows):
        for k in range(4):
            cx = ((k + 0.5) / 4.0 * size + (np.sin(r * 5.1 + k) * 43758.5) % 30) % size
            cy = (r + 0.6) * ph
            m = (xx - cx) ** 2 + (yy - cy) ** 2 < 12
            col[m] = np.array([0.32, 0.18, 0.1])
            m2 = ((xx - cx) ** 2 + (yy - cy - 6) ** 2 < 40) & ~m
            col[m2] = col[m2] * 0.8 + np.array([0.35, 0.2, 0.1]) * 0.2
    h = (1.0 - shade) * 0.6 + gs * 0.25 + lines * 0.15 - joint.astype(np.float32) * 0.5
    save_rgb(col, "planchesp.png")
    save_n(h, 6.0, "planchesp_n.png")


def palmes():
    """Toit de palmes séchées : des rangées de feuilles de palmier qui se recouvrent, paille
    dorée et brune, nervures, quelques feuilles plus vertes (récentes)."""
    size = 1024
    img = Image.new("RGBA", (size, size), (70, 52, 30, 255))
    d = ImageDraw.Draw(img)
    hm = Image.new("L", (size, size), 0)
    dh = ImageDraw.Draw(hm)
    rows = 8
    rh = size / rows
    for r in range(rows + 1):
        y0 = r * rh
        for _ in range(140):
            x = rng.random() * size
            L = rh * rng.uniform(1.2, 1.7)
            a = math.pi / 2 + rng.normal(0, 0.12)
            t = rng.random()
            if rng.random() < 0.08:
                c = (int(110 + 40 * t), int(120 + 30 * t), int(60 + 20 * t), 255)
            else:
                c = (int(150 + 60 * t), int(118 + 50 * t), int(66 + 34 * t), 255)
            x2, y2 = x + math.cos(a) * L, y0 + math.sin(a) * L
            w = int(rng.integers(3, 7))
            for ox in (-size, 0, size):
                for oy in (-size, 0, size):
                    d.line([(x + ox, y0 + oy), (x2 + ox, y2 + oy)], fill=c, width=w)
                    d.line([(x + ox, y0 + oy), (x2 + ox, y2 + oy)], fill=(int(c[0] * 0.7), int(c[1] * 0.7), int(c[2] * 0.6), 255), width=1)
                    dh.line([(x + ox, y0 + oy), (x2 + ox, y2 + oy)], fill=int(120 + 135 * (1 - (y2 - y0) / L * 0.0) * rng.uniform(0.6, 1.0)), width=w)
        # l'ombre du rang du dessus
        for ox in (-size, 0, size):
            pass
    arr = np.asarray(img.convert("RGB"), np.float32) / 255.0
    yy = np.mgrid[0:size, 0:size][0].astype(np.float32)
    band = np.mod(yy, rh) / rh
    arr *= (0.62 + 0.38 * np.clip(band * 1.6, 0, 1))[..., None]
    h = np.asarray(hm, np.float32) / 255.0 * 0.6 + band * 0.4
    save_rgb(wblur(arr, 0.5), "palmes.png")
    save_n(wblur(h, 0.8), 6.0, "palmes_n.png")


def toile():
    """Toile à voile écrue (tentes, auvents, sacs) : trame serrée, taches, reprises."""
    size = 512
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    weave = 0.5 + 0.5 * np.sin(xx * 1.6) * np.sin(yy * 1.6)
    st = tile_noise(size, (4, 8, 16, 32), 0.6)
    col = np.array([0.82, 0.76, 0.62])[None, None, :] * (0.88 + 0.12 * weave[..., None]) * (0.8 + 0.3 * st[..., None])
    col = mix(col, np.array([0.45, 0.38, 0.28]), np.clip((st - 0.78) * 4.0, 0, 1) * 0.5)
    save_rgb(col, "toile.png")
    save_n(weave * 0.3 + st * 0.2, 3.0, "toile_n.png")


def pierrefort():
    """Les murs du Fort Maudit : blocs de pierre corallienne grise et ocre, joints creusés,
    croûtes de sel, mousse et traînées noires sous les créneaux."""
    size = 1024
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    rows = 9
    rh = size / rows
    row = (yy // rh).astype(np.int32)
    v = (yy % rh) / rh
    off = (np.sin(row * 4.13) * 43758.5453 % 1.0) * size
    bw = rh * 1.7
    u = np.mod(xx + off, bw) / bw
    bid = (np.floor((xx + off) / bw) + row * 31).astype(np.int32)
    tone = (np.sin(bid * 12.9898) * 43758.5453) % 1.0
    n = tile_noise(size, (8, 16, 32, 64, 128), 0.6)
    fine = tile_noise(size, (64, 128, 256), 0.7)
    edge = np.minimum(np.minimum(u, 1 - u) * bw, np.minimum(v, 1 - v) * rh)
    mortar = edge < 5.0 + n * 4.0
    col = mix(np.array([0.62, 0.6, 0.55]), np.array([0.7, 0.6, 0.46]), tone) * (0.75 + 0.3 * n[..., None]) * (0.85 + 0.2 * fine[..., None])
    pits, pa = specks(size, 2500, 0.8, 2.6, [(60, 58, 52, 255)])
    col = col * (1 - pa[..., None] * 0.5)
    col[mortar] = np.array([0.42, 0.4, 0.36]) * (0.8 + 0.3 * fine[mortar][..., None])
    moss = tile_noise(size, (8, 16, 32), 0.55)
    col = mix(col, np.array([0.3, 0.38, 0.18]), np.clip((moss - 0.7) * 4.0, 0, 1) * 0.55)
    streak = tile_noise(size, (32, 64), 0.6)
    sm = np.asarray(Image.fromarray((streak * 255).astype(np.uint8)).resize((size // 16, size)).resize((size, size), Image.BICUBIC), np.float32) / 255.0
    col = mix(col, np.array([0.15, 0.14, 0.13]), np.clip((sm - 0.68) * 3.0, 0, 1) * 0.4)
    h = np.clip(edge / 12.0, 0, 1) * 0.6 + n * 0.3 - pa * 0.2
    save_rgb(col, "pierrefort.png")
    save_n(h, 7.0, "pierrefort_n.png")


def rondins():
    """Rondins verticaux d'une palissade : écorce brune crevassée, têtes taillées en pointe
    (le haut de la texture), mousse au pied."""
    size = 512
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    n_l = 4
    lw = size / n_l
    u = np.mod(xx, lw) / lw
    cyl = np.sqrt(np.clip(1 - (u * 2 - 1) ** 2, 0, 1))
    bark = tile_noise(size, (8, 16, 32, 64), 0.6)
    bs = np.asarray(Image.fromarray((bark * 255).astype(np.uint8)).resize((size // 8, size)).resize((size, size), Image.BICUBIC), np.float32) / 255.0
    col = np.array([0.36, 0.27, 0.18])[None, None, :] * (0.5 + 0.6 * cyl[..., None]) * (0.7 + 0.5 * bs[..., None])
    save_rgb(col, "rondins.png")
    save_n(cyl * 0.6 + bs * 0.4, 6.0, "rondins_n.png")


def os_tex():
    """L'os : blanc jauni, poreux, des fissures, de la terre dans les creux."""
    size = 512
    n = tile_noise(size, (4, 8, 16, 32), 0.55)
    fine = tile_noise(size, (64, 128, 256), 0.7)
    col = mix(np.array([0.86, 0.82, 0.7]), np.array([0.7, 0.62, 0.48]), np.clip(n * 1.3 - 0.3, 0, 1)) * (0.85 + 0.2 * fine[..., None])
    pits, pa = specks(size, 700, 0.6, 1.4, [(90, 76, 56, 255)])
    col *= (1 - pa[..., None] * 0.35)
    save_rgb(col, "os.png")
    save_n(n * 0.4 + fine * 0.3 - pa * 0.3, 4.0, "os_n.png")


def croco():
    """Peau de crocodile : écailles rectangulaires en rangées (dos), plaques bombées, vert
    olive sombre, ventre plus clair (bas de la texture)."""
    size = 1024
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    rows = 16
    rh = size / rows
    row = (yy // rh).astype(np.int32)
    off = (row % 2) * 0.5
    cw = rh * 1.3
    u = np.mod(xx / cw + off, 1.0)
    v = (yy % rh) / rh
    bump = np.sin(u * math.pi) * np.sin(v * math.pi)
    tone = (np.sin((np.floor(xx / cw + off) + row * 17) * 12.9898) * 43758.5453) % 1.0
    n = tile_noise(size, (4, 8, 16, 32), 0.6)
    col = mix(np.array([0.2, 0.24, 0.12]), np.array([0.3, 0.32, 0.18]), tone) * (0.6 + 0.6 * bump[..., None]) * (0.85 + 0.25 * n[..., None])
    belly = np.clip((yy / size - 0.72) * 5.0, 0, 1)
    col = mix(col, np.array([0.62, 0.6, 0.42]) * (0.75 + 0.35 * bump[..., None]), belly)
    save_rgb(col, "croco.png")
    save_n(bump * 0.8 + n * 0.2, 7.0, "croco_n.png")


# =================================================================== voiles et pavillons

def voile(name, base, patch_cols, holes=0.982):
    W, H = 1024, 1024
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    weave = 0.5 + 0.5 * np.sin(xx * 1.4) * np.sin(yy * 1.4)
    stain = tile_noise(W, (3, 6, 12, 24, 48), 0.6)
    col = np.array(base)[None, None, :] * (0.86 + 0.14 * weave[..., None]) * (0.78 + 0.4 * stain[..., None])
    lz = np.mod(xx, 128)
    col *= (1.0 - 0.22 * np.clip(1.0 - np.abs(lz - 2) / 3.0, 0, 1))[..., None]
    img = Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB")
    d = ImageDraw.Draw(img)
    for k in range(6):
        x0, y0 = rng.uniform(40, W - 200), rng.uniform(40, H - 200)
        w, h = rng.uniform(60, 150), rng.uniform(60, 140)
        c = patch_cols[rng.integers(len(patch_cols))]
        d.rectangle((x0, y0, x0 + w, y0 + h), fill=c, outline=(int(c[0] * 0.6), int(c[1] * 0.6), int(c[2] * 0.6)), width=3)
        for t in range(int(w // 10)):
            d.line([(x0 + t * 10, y0 - 3), (x0 + t * 10 + 4, y0 + 3)], fill=(60, 50, 40), width=1)
    col = np.asarray(img, np.float32) / 255.0
    tear = Image.new("L", (W, H), 0)
    dt = ImageDraw.Draw(tear)
    for _ in range(int((1.0 - holes) * 600)):
        x, y = rng.uniform(30, W - 30), rng.uniform(30, H - 30)
        r = rng.uniform(4, 14)
        pts = [(x + math.cos(t) * r * rng.uniform(0.4, 1.2), y + math.sin(t) * r * rng.uniform(0.4, 1.2)) for t in np.linspace(0, math.tau, 9)[:-1]]
        dt.polygon(pts, fill=255)
    alpha = 1.0 - np.asarray(tear, np.float32) / 255.0
    save_rgba(np.dstack([col, alpha]), name)


def _skull(d, cx, cy, s, bone, bg):
    d.ellipse((cx - 62 * s, cy - 86 * s, cx + 62 * s, cy + 30 * s), fill=bone)
    d.rounded_rectangle((cx - 36 * s, cy + 10 * s, cx + 36 * s, cy + 52 * s), int(10 * s), fill=bone)
    for sx in (-1, 1):
        d.ellipse((cx + sx * 26 * s - 18 * s, cy - 34 * s, cx + sx * 26 * s + 18 * s, cy + 4 * s), fill=bg)
    d.polygon([(cx, cy + 6 * s), (cx - 9 * s, cy + 22 * s), (cx + 9 * s, cy + 22 * s)], fill=bg)
    for k in range(-2, 3):
        d.line([(cx + k * 13 * s, cy + 30 * s), (cx + k * 13 * s, cy + 50 * s)], fill=bg, width=max(2, int(3 * s)))


def _fray(arr, W, H):
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    n = az.rect_noise(W, H, (4, 8, 16, 32), 0.6)
    arr[xx > W - 40 - 50 * n, 3] = 0.0
    small = az.rect_noise(W, H, (16, 32, 64), 0.6)
    arr[(small > 0.94) & (xx > 60), 3] = 0.0
    arr[..., :3] *= (0.85 + 0.2 * az.rect_noise(W, H, (8, 16, 32), 0.6)[..., None])
    return arr


def pavillons():
    W, H = 512, 320
    bone = (236, 230, 214, 255)
    # Le Requin Borgne : noir, un crâne de requin borgne (une orbite barrée)
    bg = (14, 14, 16, 255)
    img = Image.new("RGBA", (W, H), bg)
    d = ImageDraw.Draw(img)
    cx, cy = W // 2, H // 2
    d.polygon([(cx - 150, cy + 10), (cx + 40, cy - 70), (cx + 150, cy - 20), (cx + 120, cy + 30), (cx + 40, cy + 60), (cx - 150, cy + 30)], fill=bone)
    for k in range(9):
        x = cx - 130 + k * 26
        d.polygon([(x, cy + 30), (x + 12, cy + 30), (x + 6, cy + 46)], fill=bone)
        d.polygon([(x + 4, cy + 12), (x + 16, cy + 12), (x + 10, cy - 4)], fill=bg)
    d.ellipse((cx + 50, cy - 40, cx + 82, cy - 10), fill=bg)
    d.line([(cx + 40, cy - 52), (cx + 96, cy + 4)], fill=bone, width=10)
    d.polygon([(cx + 60, cy - 70), (cx + 30, cy - 130), (cx + 90, cy - 66)], fill=bone)
    arr = _fray(np.asarray(img, np.float32) / 255.0, W, H)
    save_rgba(arr, "pavillon_requin.png")
    # La Veuve Écarlate : rouge sang, un crâne coiffé d'un voile de veuve, une rose
    bg2 = (120, 14, 14, 255)
    img = Image.new("RGBA", (W, H), bg2)
    d = ImageDraw.Draw(img)
    _skull(d, cx, cy + 10, 1.1, bone, bg2)
    d.polygon([(cx - 80, cy - 70), (cx, cy - 120), (cx + 80, cy - 70), (cx + 96, cy + 40), (cx + 70, cy - 40), (cx - 70, cy - 40), (cx - 96, cy + 40)], fill=(20, 16, 18, 255))
    d.line([(cx - 140, cy + 120), (cx - 90, cy + 40)], fill=(40, 90, 40, 255), width=6)
    d.ellipse((cx - 112, cy + 18, cx - 72, cy + 58), fill=(230, 40, 50, 255))
    arr = _fray(np.asarray(img, np.float32) / 255.0, W, H)
    save_rgba(arr, "pavillon_veuve.png")
    # La Morue Enragée : bleu nuit, une arête de poisson et deux sabres croisés
    bg3 = (22, 34, 66, 255)
    img = Image.new("RGBA", (W, H), bg3)
    d = ImageDraw.Draw(img)
    for sgn in (-1, 1):
        d.line([(cx - 130, cy + sgn * 90), (cx + 130, cy - sgn * 90)], fill=(200, 204, 210, 255), width=10)
        d.line([(cx - 130, cy + sgn * 90), (cx - 100, cy + sgn * 70)], fill=(180, 140, 60, 255), width=16)
    d.line([(cx - 110, cy), (cx + 90, cy)], fill=bone, width=10)
    for k in range(7):
        x = cx - 80 + k * 24
        d.line([(x, cy), (x - 14, cy - 40)], fill=bone, width=6)
        d.line([(x, cy), (x - 14, cy + 40)], fill=bone, width=6)
    d.ellipse((cx + 70, cy - 34, cx + 140, cy + 34), fill=bone)
    d.ellipse((cx + 100, cy - 16, cx + 118, cy + 2), fill=bg3)
    d.polygon([(cx - 110, cy), (cx - 160, cy - 40), (cx - 150, cy), (cx - 160, cy + 40)], fill=bone)
    arr = _fray(np.asarray(img, np.float32) / 255.0, W, H)
    save_rgba(arr, "pavillon_morue.png")
    # Port-Coutelas : le crâne balafré sur un coutelas
    bg4 = (16, 14, 14, 255)
    img = Image.new("RGBA", (W, H), bg4)
    d = ImageDraw.Draw(img)
    d.line([(cx - 160, cy + 60), (cx + 150, cy + 60)], fill=(200, 204, 210, 255), width=16)
    d.polygon([(cx + 150, cy + 52), (cx + 190, cy + 60), (cx + 150, cy + 68)], fill=(200, 204, 210, 255))
    d.line([(cx - 180, cy + 60), (cx - 150, cy + 60)], fill=(150, 100, 50, 255), width=22)
    _skull(d, cx, cy - 10, 1.0, bone, bg4)
    d.line([(cx - 50, cy - 80), (cx + 40, cy + 10)], fill=(200, 30, 30, 255), width=8)
    arr = _fray(np.asarray(img, np.float32) / 255.0, W, H)
    save_rgba(arr, "pavillon_balafre.png")


# =================================================================== enseignes, affiches, cartes

def _icon(d, kind, cx, cy, ink):
    if kind == "crane":
        _skull(d, cx, cy + 10, 0.55, ink, (0, 0, 0, 0))
        d.line([(cx - 4, cy - 38), (cx + 10, cy - 4), (cx - 2, cy + 8)], fill=(40, 26, 18, 255), width=5)
    elif kind == "dent":
        d.polygon([(cx - 26, cy - 40), (cx + 26, cy - 40), (cx, cy + 44)], fill=ink)
        d.rectangle((cx - 30, cy - 50, cx + 30, cy - 38), fill=ink)
    elif kind == "main":
        for k in range(5):
            d.rounded_rectangle((cx - 40 + k * 17, cy - 50 + abs(k - 2) * 8, cx - 28 + k * 17, cy), 6, fill=ink)
        d.rounded_rectangle((cx - 42, cy - 10, cx + 46, cy + 40), 14, fill=ink)
    elif kind == "enclume":
        d.polygon([(cx - 54, cy - 20), (cx + 40, cy - 20), (cx + 60, cy - 8), (cx + 30, cy), (cx + 20, cy + 20), (cx + 34, cy + 40), (cx - 34, cy + 40), (cx - 20, cy + 20), (cx - 30, cy)], fill=ink)
    elif kind == "scie":
        d.line([(cx - 50, cy + 30), (cx + 50, cy - 30)], fill=ink, width=10)
        for k in range(8):
            x = cx - 44 + k * 12
            y = cy + 26 - k * 7
            d.polygon([(x, y), (x + 8, y - 5), (x + 8, y + 6)], fill=ink)
        d.line([(cx - 40, cy - 40), (cx + 40, cy + 40)], fill=ink, width=6)
    elif kind == "boussole":
        d.ellipse((cx - 46, cy - 46, cx + 46, cy + 46), outline=ink, width=6)
        d.polygon([(cx, cy - 40), (cx + 10, cy), (cx, cy + 40), (cx - 10, cy)], fill=ink)
    elif kind == "aiguille":
        d.line([(cx - 40, cy + 40), (cx + 34, cy - 34)], fill=ink, width=6)
        d.ellipse((cx + 26, cy - 46, cx + 46, cy - 26), outline=ink, width=5)
        d.arc((cx - 50, cy - 30, cx + 10, cy + 30), 30, 300, fill=ink, width=4)
    elif kind == "perroquet":
        d.ellipse((cx - 24, cy - 40, cx + 20, cy + 10), fill=ink)
        d.polygon([(cx - 18, cy - 10), (cx + 14, cy - 6), (cx + 4, cy + 50), (cx - 10, cy + 48)], fill=ink)
        d.polygon([(cx + 16, cy - 30), (cx + 36, cy - 22), (cx + 16, cy - 12)], fill=ink)
    elif kind == "plume":
        d.polygon([(cx - 40, cy + 44), (cx + 40, cy - 44), (cx + 20, cy - 10), (cx - 30, cy + 40)], fill=ink)


ENSEIGNES68 = {
    "crane_fendu": ("Le Crâne Fendu", "rhum · grog · dés · bagarres", (52, 26, 18), (236, 206, 140), "crane"),
    "dent_requin": ("La Dent du Requin", "on joue gros, on perd tout", (24, 40, 46), (226, 222, 196), "dent"),
    "receleur": ("Cinq-Doigts", "on achète tout · on ne demande rien", (38, 32, 26), (214, 190, 120), "main"),
    "forge": ("Brutus · Forge", "sabres · crochets · fers", (30, 28, 28), (230, 150, 70), "enclume"),
    "chirurgien": ("Doc Saignée", "barbier · chirurgien · dentiste", (66, 22, 22), (232, 224, 210), "scie"),
    "cartographe": ("Ph. Lunette", "cartes marines & instruments", (26, 36, 52), (226, 206, 150), "boussole"),
    "tatoueur": ("L'Encre de Coralie", "tatouages pour les durs", (20, 20, 24), (120, 200, 210), "aiguille"),
    "perroquets": ("Perroquet-Joe", "oiseaux qui parlent (poliment)", (30, 60, 30), (250, 210, 80), "perroquet"),
    "residence": ("Résidence du Gouverneur", "Port-Coutelas · Ordre & Profit", (60, 22, 30), (236, 214, 150), "plume"),
}


def enseignes68():
    for key, (title, sub, bg, ink, icon) in ENSEIGNES68.items():
        w, h = 1024, 256
        grain = az.rect_noise(w, h, (4, 8, 16, 32), 0.6)
        gs = np.asarray(Image.fromarray((grain * 255).astype(np.uint8)).resize((w, h // 8)).resize((w, h), Image.BICUBIC), np.float32) / 255.0
        arr = np.zeros((h, w, 3), np.float32)
        arr[:] = np.array(bg) / 255.0
        arr *= (0.7 + 0.45 * gs[..., None])
        img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8)).convert("RGBA")
        d = ImageDraw.Draw(img)
        # planches : deux joints horizontaux
        for y in (h // 3, 2 * h // 3):
            d.line([(0, y), (w, y)], fill=(0, 0, 0, 90), width=3)
        d.rectangle((6, 6, w - 7, h - 7), outline=(14, 10, 8, 255), width=10)
        for (x, y) in ((24, 24), (w - 24, 24), (24, h - 24), (w - 24, h - 24)):
            d.ellipse((x - 7, y - 7, x + 7, y + 7), fill=(60, 40, 30, 255))
        _icon(d, icon, 120, h // 2, ink + (255,))
        _icon(d, icon, w - 120, h // 2, ink + (255,))
        size = 96
        f = az.font(size, italic=False, bold=True)
        while d.textlength(title, font=f) > w - 300 and size > 40:
            size -= 4
            f = az.font(size, italic=False, bold=True)
        d.text((w / 2 + 3, h * 0.42 + 4), title, font=f, fill=(0, 0, 0, 140), anchor="mm")
        d.text((w / 2, h * 0.42), title, font=f, fill=ink + (255,), anchor="mm")
        fs = az.font(36, italic=True)
        d.text((w / 2, h * 0.8), sub, font=fs, fill=ink + (230,), anchor="mm")
        a2 = np.asarray(img, np.float32) / 255.0
        wear = az.rect_noise(w, h, (8, 16, 32, 64), 0.6)
        a2[..., :3] *= (0.8 + 0.22 * wear[..., None])
        scr = az.rect_noise(w, h, (32, 64, 128), 0.6)
        a2[..., :3] = a2[..., :3] * (1 - np.clip((scr - 0.8) * 4.0, 0, 1)[..., None] * 0.4)
        save_rgba(a2, f"enseigne_{key}.png")


AVIS = [
    ("lestrange", "GONTRAN « JAMBE-DE-BOIS »", "500 pièces", "pour avoir coulé trois navires du roi"),
    ("malaterre", "IGNACE « BOUCHE-D'OR »", "300 pièces", "tricheur, menteur, charmeur"),
    ("anne_rose", "ANNE-ROSE « LA BALAFRÉE »", "1000 pièces", "morte ou vive (de préférence loin)"),
]


def avis():
    """Avis de recherche placardés : papier jauni, déchiré, un portrait au fusain."""
    for key, name, prime, motif in AVIS:
        w, h = 384, 512
        n = az.rect_noise(w, h, (4, 8, 16, 32), 0.6)
        arr = np.zeros((h, w, 3), np.float32)
        arr[:] = np.array([0.86, 0.78, 0.6])
        arr *= (0.78 + 0.3 * n[..., None])
        img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8)).convert("RGBA")
        d = ImageDraw.Draw(img)
        ink = (40, 28, 20, 255)
        f1 = az.font(44, bold=True)
        d.text((w / 2, 46), "RECHERCHÉ", font=f1, fill=ink, anchor="mm")
        # portrait
        d.rectangle((70, 90, w - 70, 300), outline=ink, width=4)
        cx, cy = w // 2, 200
        d.ellipse((cx - 60, cy - 80, cx + 60, cy + 70), outline=ink, width=5)
        d.line([(cx - 30, cy - 20), (cx - 12, cy - 22)], fill=ink, width=6)
        d.line([(cx + 12, cy - 22), (cx + 30, cy - 20)], fill=ink, width=6)
        d.arc((cx - 30, cy + 10, cx + 30, cy + 44), 20, 160, fill=ink, width=5)
        if key == "anne_rose":
            d.line([(cx - 40, cy - 50), (cx + 20, cy + 30)], fill=(140, 20, 20, 255), width=5)
            d.polygon([(cx - 80, cy - 70), (cx + 80, cy - 70), (cx + 40, cy - 110), (cx - 40, cy - 110)], fill=ink)
        elif key == "lestrange":
            d.arc((cx - 50, cy + 20, cx + 50, cy + 100), 0, 180, fill=ink, width=14)
        else:
            for k in range(-2, 3):
                d.rectangle((cx + k * 9 - 3, cy + 22, cx + k * 9 + 3, cy + 30), fill=(200, 160, 40, 255))
        f2 = az.font(26, bold=True)
        size = 26
        while d.textlength(name, font=f2) > w - 30 and size > 14:
            size -= 2
            f2 = az.font(size, bold=True)
        d.text((w / 2, 336), name, font=f2, fill=ink, anchor="mm")
        f3 = az.font(48, bold=True)
        d.text((w / 2, 396), prime, font=f3, fill=(120, 20, 16, 255), anchor="mm")
        f4 = az.font(20, italic=True)
        d.text((w / 2, 448), motif, font=f4, fill=ink, anchor="mm")
        a2 = np.asarray(img, np.float32) / 255.0
        yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
        tear = az.rect_noise(w, h, (8, 16, 32), 0.6)
        border = np.minimum(np.minimum(xx, w - 1 - xx), np.minimum(yy, h - 1 - yy))
        a2[border < 6 + tear * 16, 3] = 0.0
        save_rgba(a2, f"avis_{key}.png")


def carte_tresor():
    """La carte au trésor de Barbe-Sanglante : un vieux parchemin, l'île dessinée à l'encre,
    le Pic, la Balafre, le Rocher du Crâne marqué d'une croix rouge, une rose des vents."""
    w, h = 768, 512
    n = az.rect_noise(w, h, (4, 8, 16, 32), 0.6)
    arr = np.zeros((h, w, 3), np.float32)
    arr[:] = np.array([0.84, 0.74, 0.54])
    arr *= (0.75 + 0.32 * n[..., None])
    img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8)).convert("RGBA")
    d = ImageDraw.Draw(img)
    ink = (64, 40, 24, 255)
    pts = []
    for k in range(48):
        a = k / 48 * math.tau
        r = 1.0 + 0.08 * math.sin(a * 5 + 1) + 0.05 * math.sin(a * 11)
        x = w / 2 + math.cos(a) * 260 * r
        y = h / 2 + math.sin(a) * 180 * r
        if 1.2 < a < 1.95:
            y -= 50 * math.sin((a - 1.2) / 0.75 * math.pi)
        pts.append((x, y))
    d.polygon(pts, outline=ink, width=4)
    for k in range(4):
        d.polygon([(w / 2 - 30 + k * 6, h / 2 - 40 - k * 6), (w / 2 - 6, h / 2 - 90), (w / 2 + 20 - k * 4, h / 2 - 40 - k * 6)], outline=ink, width=2)
    d.line([(w / 2 + 20, h / 2 - 60), (w / 2 + 120, h / 2 - 30), (w / 2 + 250, h / 2 - 10)], fill=ink, width=5)
    sx, sy = w / 2 + 10, h / 2 - 66
    d.line([(sx - 14, sy - 14), (sx + 14, sy + 14)], fill=(170, 24, 20, 255), width=7)
    d.line([(sx - 14, sy + 14), (sx + 14, sy - 14)], fill=(170, 24, 20, 255), width=7)
    for k in range(4):
        a = k * math.pi / 2
        d.polygon([(110, 410), (110 + math.cos(a) * 46, 410 + math.sin(a) * 46), (110 + math.cos(a + 0.4) * 12, 410 + math.sin(a + 0.4) * 12)], fill=ink)
    f = az.font(30, italic=True)
    d.text((w / 2, 40), "Ici dort l'or de Barbe-Sanglante", font=f, fill=ink, anchor="mm")
    a2 = np.asarray(img, np.float32) / 255.0
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    tear = az.rect_noise(w, h, (8, 16, 32), 0.6)
    border = np.minimum(np.minimum(xx, w - 1 - xx), np.minimum(yy, h - 1 - yy))
    a2[border < 4 + tear * 14, 3] = 0.0
    a2[..., :3] *= np.clip(0.6 + border[..., None] / 60.0, 0, 1)
    save_rgba(a2, "carte_tresor.png")


def de():
    """Une face de dé (cinq points) en os jauni."""
    s = 128
    img = Image.new("RGB", (s, s), (232, 224, 204))
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, s - 1, s - 1), outline=(190, 180, 160), width=6)
    for (x, y) in ((32, 32), (96, 32), (64, 64), (32, 96), (96, 96)):
        d.ellipse((x - 11, y - 11, x + 11, y + 11), fill=(30, 20, 16))
    az.save_img(img, OUT / "de.png")


def deco():
    planchesp()
    palmes()
    toile()
    pierrefort()
    rondins()
    os_tex()
    croco()
    voile("voile_grise.png", [0.52, 0.5, 0.46], [(110, 104, 92), (90, 86, 78), (130, 120, 100)])
    voile("voile_rouge.png", [0.56, 0.12, 0.1], [(120, 30, 24), (96, 24, 20), (150, 70, 50)])
    voile("voile_blanche.png", [0.86, 0.82, 0.72], [(200, 190, 160), (180, 170, 140), (220, 210, 180)], 0.99)
    pavillons()
    enseignes68()
    avis()
    carte_tresor()
    de()


# =================================================================== icônes

def icones():
    """Les objets de la Balafre (128 px, ombrés et cernés comme les autres icônes)."""
    import generate_items_v28 as icons  # noqa: E402
    icons.OUT = ROOT / "www" / "assets" / "textures" / "items"
    S = 512
    se = icons.shaded_ellipse
    stick = icons.stick_polygon

    # dent de crocodile : un croc jaune ivoire, légèrement courbe, la racine brunie
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.polygon([(190, 420), (330, 410), (318, 300), (292, 190), (262, 90), (238, 200), (206, 300)], fill=(236, 222, 180, 255))
    d.polygon([(262, 90), (292, 190), (318, 300), (286, 300), (268, 190)], fill=(250, 242, 214, 255))
    d.polygon([(190, 420), (330, 410), (322, 360), (198, 368)], fill=(170, 130, 80, 255))
    icons.save(img, "dent_croco")
    # croc de Vieille-Dent : un croc énorme, fendu, une ficelle de pêcheur autour
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.polygon([(130, 450), (330, 470), (360, 380), (330, 220), (270, 50), (230, 210), (170, 340)], fill=(220, 200, 150, 255))
    d.polygon([(270, 50), (330, 220), (360, 380), (310, 380), (290, 220)], fill=(244, 232, 196, 255))
    d.line([(262, 140), (250, 230), (262, 300)], fill=(120, 96, 60, 255), width=5)
    d.polygon([(130, 450), (330, 470), (340, 420), (140, 404)], fill=(140, 100, 60, 255))
    for y in (400, 418):
        d.line([(132, y), (346, y + 14)], fill=(190, 160, 110, 255), width=6)
    icons.save(img, "croc_geant")
    # dés pipés : trois dés d'os, l'un montre un six, un éclat de plomb sur une face
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    for (cx, cy, a, n) in ((170, 300, -12, 6), (330, 330, 14, 6), (250, 180, 4, 5)):
        r = 82
        pts = [(cx + math.cos(math.radians(a + k * 90 + 45)) * r * 1.41, cy + math.sin(math.radians(a + k * 90 + 45)) * r * 1.41) for k in range(4)]
        d.polygon(pts, fill=(236, 228, 206, 255), outline=(150, 136, 110, 255))
        spots = {6: [(-1, -1), (-1, 0), (-1, 1), (1, -1), (1, 0), (1, 1)], 5: [(-1, -1), (1, -1), (0, 0), (-1, 1), (1, 1)]}[n]
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        for (u, v) in spots:
            x = cx + (u * ca - v * sa) * 40
            y = cy + (u * sa + v * ca) * 40
            d.ellipse((x - 12, y - 12, x + 12, y + 12), fill=(40, 30, 26, 255))
    d.ellipse((300, 262, 318, 280), fill=(120, 124, 130, 255))
    icons.save(img, "des_pipes")

    def parchemin(d, pts, burnt=True):
        d.polygon(pts, fill=(226, 204, 158, 255), outline=(150, 112, 70, 255))

    # morceau de carte : un tiers de parchemin déchiré en zigzag, des pointillés, une flèche
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    parchemin(d, [(110, 120), (400, 100), (380, 190), (412, 250), (372, 320), (404, 400), (120, 420), (96, 270)])
    for k in range(9):
        x = 150 + k * 24
        d.ellipse((x, 260 - k * 10 - 4, x + 10, 260 - k * 10 + 6), fill=(120, 40, 30, 255))
    d.line([(150, 340), (240, 360), (300, 330)], fill=(70, 50, 30, 255), width=6)
    d.polygon([(300, 316), (330, 330), (300, 346)], fill=(70, 50, 30, 255))
    d.ellipse((170, 140, 230, 200), outline=(90, 70, 40, 255), width=5)
    icons.save(img, "carte_morceau")
    # carte de Barbe-Sanglante : le parchemin entier recousu, une croix rouge, un crâne
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    parchemin(d, [(70, 110), (440, 96), (452, 410), (60, 424)])
    for x0 in (190, 316):
        for y in range(120, 410, 22):
            d.line([(x0 - 6, y), (x0 + 6, y + 10)], fill=(90, 70, 40, 255), width=3)
    d.polygon([(110, 300), (160, 210), (240, 180), (330, 200), (400, 270), (380, 360), (260, 390), (150, 370)], fill=(196, 176, 120, 255), outline=(110, 80, 50, 255))
    for k in range(10):
        x = 180 + k * 18
        d.ellipse((x, 300 - k * 6, x + 8, 308 - k * 6), fill=(120, 40, 30, 255))
    d.line([(350, 236), (390, 276)], fill=(200, 20, 20, 255), width=12)
    d.line([(390, 236), (350, 276)], fill=(200, 20, 20, 255), width=12)
    d.ellipse((96, 120, 150, 172), fill=(236, 230, 214, 255), outline=(60, 50, 40, 255), width=3)
    d.ellipse((108, 136, 120, 148), fill=(30, 24, 20, 255))
    d.ellipse((126, 136, 138, 148), fill=(30, 24, 20, 255))
    icons.save(img, "carte_barbe")
    # bourse de Jambe-de-Bois : cuir rouge, une veuve noire brodée, des pièces qui dépassent
    img = icons.canvas()
    se(img, (110, 170, 400, 450), (150, 30, 28))
    d = ImageDraw.Draw(img)
    d.polygon([(190, 180), (320, 180), (290, 120), (220, 120)], fill=(130, 26, 24, 255))
    d.line([(200, 160), (310, 160)], fill=(210, 170, 70, 255), width=10)
    se(img, (226, 82, 290, 132), (230, 190, 70))
    d = ImageDraw.Draw(img)
    d.ellipse((230, 280, 280, 330), fill=(20, 16, 16, 255))
    d.ellipse((242, 254, 268, 280), fill=(20, 16, 16, 255))
    for k in range(4):
        for sx in (-1, 1):
            d.line([(255, 300), (255 + sx * (50 + k * 4), 270 + k * 18)], fill=(20, 16, 16, 255), width=5)
    d.polygon([(248, 296), (262, 296), (255, 314)], fill=(200, 30, 30, 255))
    icons.save(img, "bourse_lestrange")
    # herbe à fièvre : une touffe d'herbe argentée, une goutte d'eau
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    rr = np.random.default_rng(681)
    for k in range(22):
        bx = 180 + rr.uniform(0, 150)
        tip = (bx + rr.uniform(-90, 90), 70 + rr.uniform(0, 120))
        col = (int(170 + rr.uniform(0, 60)), int(196 + rr.uniform(0, 40)), int(200 + rr.uniform(0, 40)), 255)
        d.polygon([(bx - 9, 440), (bx + 9, 440), tip], fill=col)
    d.ellipse((150, 420, 360, 470), fill=(90, 70, 50, 255))
    icons.save(img, "herbe_fievre")
    # sachet de graines : un petit sac de toile noué, des graines qui débordent
    img = icons.canvas()
    se(img, (130, 190, 380, 450), (200, 176, 130))
    d = ImageDraw.Draw(img)
    d.polygon([(200, 200), (310, 200), (340, 140), (170, 140)], fill=(186, 160, 116, 255))
    d.line([(196, 196), (316, 196)], fill=(120, 70, 40, 255), width=10)
    for k in range(9):
        x = 190 + k * 16
        y = 150 + (k % 3) * 8
        d.ellipse((x, y, x + 18, y + 26), fill=(60, 50, 40, 255), outline=(230, 220, 200, 255), width=2)
    icons.save(img, "graines")
    # poing de fer : une manicle de fer cloutée, trois crocs sur les jointures
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((120, 190, 400, 380), radius=60, fill=(96, 98, 104, 255), outline=(40, 40, 44, 255), width=8)
    for k in range(4):
        x = 150 + k * 62
        d.rounded_rectangle((x, 170, x + 56, 250), radius=22, fill=(120, 122, 128, 255), outline=(40, 40, 44, 255), width=6)
    for k in range(3):
        x = 182 + k * 64
        d.polygon([(x, 176), (x + 30, 176), (x + 15, 96)], fill=(236, 222, 180, 255), outline=(150, 120, 80, 255))
    for (x, y) in ((170, 320), (250, 330), (330, 320)):
        d.ellipse((x - 10, y - 10, x + 10, y + 10), fill=(200, 200, 205, 255))
    icons.save(img, "poing_fer")
    # ceinture du Roi de la Bagarre : cuir clouté, boucle de laiton en forme de poing
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.arc((60, 120, 452, 420), 200, 340, fill=(90, 56, 30, 255), width=60)
    d.arc((60, 160, 452, 460), 20, 160, fill=(90, 56, 30, 255), width=60)
    for k in range(10):
        a = math.radians(200 + k * 14)
        x, y = 256 + math.cos(a) * 196, 270 + math.sin(a) * 150
        d.ellipse((x - 7, y - 7, x + 7, y + 7), fill=(210, 200, 180, 255))
    se(img, (176, 220, 336, 360), (214, 170, 60))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((216, 250, 296, 320), radius=18, fill=(170, 124, 40, 255))
    for k in range(4):
        d.line([(222 + k * 20, 252), (222 + k * 20, 280)], fill=(120, 84, 24, 255), width=4)
    icons.save(img, "ceinture_champion")
    # tricorne de Barbe-Sanglante : feutre noir, les trois bords relevés galonnés d'or, plume rouge
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    for k in range(18):
        t = k / 17
        x, y = 330 + t * 110, 210 - math.sin(t * math.pi * 0.9) * 110
        L = 46 * math.sin(t * math.pi) + 10
        d.line([(x, y), (x - L * 0.5, y - L * 0.8)], fill=(214, 40, 34, 255), width=12)
        d.line([(x, y), (x + L * 0.7, y - L * 0.4)], fill=(186, 26, 22, 255), width=12)
    se(img, (156, 150, 356, 300), (44, 40, 46), gloss=False)
    d = ImageDraw.Draw(img)
    back = [(66, 250), (160, 196), (256, 214), (352, 196), (446, 250), (420, 300), (256, 262), (92, 300)]
    d.polygon(back, fill=(36, 33, 38, 255))
    front = [(66, 250), (256, 300), (446, 250), (430, 300), (256, 392), (82, 300)]
    d.polygon(front, fill=(26, 24, 28, 255))
    d.line([(66, 250), (256, 300), (446, 250)], fill=(220, 178, 70, 255), width=12)
    d.line([(82, 300), (256, 392), (430, 300)], fill=(200, 156, 56, 255), width=8)
    se(img, (238, 302, 274, 338), (230, 190, 80))
    icons.save(img, "tricorne_or")
    # plume de Rhubarbe : longue plume rouge vif, le bout bleu
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    for k in range(22):
        t = k / 21
        x = 120 + t * 280
        y = 400 - t * 300
        L = 90 * math.sin(t * math.pi) + 18
        c1 = (230, 40, 30, 255) if t < 0.72 else (40, 90, 210, 255)
        c2 = (200, 26, 20, 255) if t < 0.72 else (30, 70, 180, 255)
        d.line([(x, y), (x - L * 0.75, y - L * 0.55)], fill=c1, width=16)
        d.line([(x, y), (x + L * 0.55, y + L * 0.75)], fill=c2, width=16)
    d.line([(100, 430), (410, 90)], fill=(240, 220, 160, 255), width=10)
    icons.save(img, "plume_perroquet")
    # rhum de la Balafre : bouteille brune, étiquette au crâne
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    se(img, (160, 210, 352, 460), (96, 56, 26))
    d = ImageDraw.Draw(img)
    d.rectangle((222, 90, 290, 230), fill=(90, 52, 24, 255))
    d.rectangle((216, 64, 296, 100), fill=(170, 130, 80, 255))
    d.rectangle((186, 300, 326, 400), fill=(226, 210, 170, 255), outline=(90, 60, 30, 255), width=4)
    d.ellipse((232, 316, 280, 360), fill=(40, 30, 26, 255))
    d.ellipse((242, 330, 252, 340), fill=(226, 210, 170, 255))
    d.ellipse((260, 330, 270, 340), fill=(226, 210, 170, 255))
    d.line([(214, 380), (298, 368)], fill=(40, 30, 26, 255), width=8)
    d.line([(214, 368), (298, 380)], fill=(40, 30, 26, 255), width=8)
    icons.save(img, "rhum_balafre")
    # ragoût de pirate : une écuelle de bois fumante, rouge de piment
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.chord((90, 200, 422, 440), 0, 180, fill=(120, 78, 40, 255), outline=(60, 36, 20, 255), width=6)
    d.ellipse((100, 230, 412, 300), fill=(170, 60, 30, 255))
    for (x, y, c) in ((160, 250, (240, 220, 140)), (230, 262, (90, 40, 30)), (300, 248, (230, 200, 90)), (350, 262, (60, 120, 40)), (200, 276, (240, 120, 40))):
        d.ellipse((x - 16, y - 10, x + 16, y + 10), fill=c + (255,))
    for k in range(3):
        x = 190 + k * 60
        d.arc((x - 20, 90, x + 20, 220), 100, 260, fill=(230, 230, 230, 200), width=8)
    icons.save(img, "ragout_pirate")
    # remontant du Doc : un flacon brun bouché de cire, une croix blanche
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    se(img, (150, 220, 362, 460), (110, 70, 34))
    d = ImageDraw.Draw(img)
    d.rectangle((226, 120, 286, 240), fill=(100, 64, 30, 255))
    d.rectangle((216, 90, 296, 130), fill=(150, 30, 30, 255))
    d.rectangle((236, 300, 276, 400), fill=(240, 236, 226, 255))
    d.rectangle((206, 330, 306, 370), fill=(240, 236, 226, 255))
    icons.save(img, "remontant_doc")

def main():
    what = sys.argv[1:] or ["sols", "deco", "icones"]
    if "sols" in what:
        sols()
    if "deco" in what and "deco" in globals():
        globals()["deco"]()
    if "icones" in what and "icones" in globals():
        globals()["icones"]()


if __name__ == "__main__":
    main()
