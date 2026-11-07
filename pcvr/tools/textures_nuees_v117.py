#!/usr/bin/env python3
"""V117 : les textures des intérieurs de la Cité des Nuées (www/assets/textures/nuees/) :
 - des tableaux pour les appartements (un coucher de soleil sur la mer de nuages, des cumulus, la
   Cascade des Nuées qui tombe dans le vide) et l'affiche de la Ligne des Nuées (sans texte) ;
 - le plan de l'île (la carte holographique de la Maison du Conseil) ;
 - des écrans de l'Institut des Vents et du cœur des Sustentateurs (isobares, radar, mesures) ;
 - les plans d'une invention (l'Atelier des Inventeurs) ;
 - deux tapis clairs (laine grise, bleu ciel) ;
 - l'enduit blanc des murs (raccordable, sans taches) et ses normales.
Tout est dessiné ici (Pillow), sans texte : les images n'ont pas besoin d'être traduites.
Usage : python3 pcvr/tools/textures_nuees_v117.py (depuis la racine du dépôt)."""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "www", "assets", "textures", "nuees")


def lerp(a, b, t):
    return a + (b - a) * t


def mix(c1, c2, t):
    return tuple(int(lerp(c1[i], c2[i], t)) for i in range(3))


def grad(w, h, stops):
    """Un dégradé vertical : stops = [(t, (r, g, b)), …]."""
    im = Image.new("RGB", (w, h))
    px = im.load()
    for y in range(h):
        t = y / (h - 1)
        for k in range(len(stops) - 1):
            if stops[k][0] <= t <= stops[k + 1][0]:
                u = (t - stops[k][0]) / max(1e-6, stops[k + 1][0] - stops[k][0])
                c = mix(stops[k][1], stops[k + 1][1], u)
                break
        for x in range(w):
            px[x, y] = c
    return im


def nuage(dr, cx, cy, s, col, rnd, n=9):
    """Un cumulus : des disques qui se chevauchent, le bas aplati."""
    for _ in range(n):
        ox = rnd.uniform(-1.6, 1.6) * s
        oy = rnd.uniform(-0.7, 0.2) * s
        r = rnd.uniform(0.55, 1.0) * s
        dr.ellipse([cx + ox - r, cy + oy - r, cx + ox + r, cy + oy + r * 0.8], fill=col)


def peinture(im, rnd, k=2):
    """Un léger grain de toile et de coups de pinceau."""
    im = im.filter(ImageFilter.GaussianBlur(k))
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            g = rnd.randint(-6, 6) + (4 if (x // 3 + y // 3) % 2 == 0 else -4)
            r, gg, b = px[x, y]
            px[x, y] = (max(0, min(255, r + g)), max(0, min(255, gg + g)), max(0, min(255, b + g)))
    return im


def cadre(im, col=(236, 232, 224), w=10):
    dr = ImageDraw.Draw(im)
    W, H = im.size
    dr.rectangle([0, 0, W - 1, H - 1], outline=col, width=w)
    return im


def tableau_coucher(rnd):
    W, H = 512, 384
    im = grad(W, H, [(0.0, (62, 58, 120)), (0.35, (214, 104, 92)), (0.55, (252, 176, 96)), (0.62, (255, 214, 150)), (1.0, (232, 196, 190))])
    dr = ImageDraw.Draw(im)
    dr.ellipse([W * 0.55 - 34, H * 0.56 - 34, W * 0.55 + 34, H * 0.56 + 34], fill=(255, 236, 190))
    # la mer de nuages, rose et or, devant le soleil
    for row in range(5):
        y = H * (0.6 + row * 0.085)
        c = mix((250, 196, 186), (196, 150, 170), row / 4)
        for k in range(9):
            nuage(dr, rnd.uniform(-40, W + 40), y, rnd.uniform(26, 44), c, rnd, 6)
    # au loin, l'île flottante (une silhouette)
    dr.polygon([(70, 150), (190, 146), (172, 176), (140, 205), (110, 182)], fill=(70, 52, 90))
    dr.rectangle([96, 132, 168, 150], fill=(84, 64, 104))
    return cadre(peinture(im, rnd, 2))


def tableau_nuages(rnd):
    W, H = 512, 384
    im = grad(W, H, [(0.0, (86, 140, 214)), (0.7, (168, 206, 240)), (1.0, (214, 232, 246))])
    dr = ImageDraw.Draw(im)
    for k in range(7):
        x = rnd.uniform(20, W - 20)
        y = rnd.uniform(H * 0.25, H * 0.85)
        s = rnd.uniform(26, 52)
        nuage(dr, x + 4, y + 6, s, (190, 200, 220), rnd)
        nuage(dr, x, y, s, (250, 251, 255), rnd)
    return cadre(peinture(im, rnd, 2))


def tableau_cascade(rnd):
    W, H = 384, 512
    im = grad(W, H, [(0.0, (120, 176, 230)), (1.0, (210, 230, 246))])
    dr = ImageDraw.Draw(im)
    # le bord de l'île, son herbe, et l'eau qui tombe et se change en nuage
    dr.polygon([(0, 120), (230, 128), (210, 190), (150, 260), (60, 300), (0, 300)], fill=(118, 106, 98))
    dr.polygon([(0, 112), (240, 120), (232, 132), (0, 128)], fill=(108, 160, 86))
    for k in range(40):
        x = 200 + rnd.uniform(-10, 10)
        dr.line([(x, 124), (x + rnd.uniform(-8, 8), 124 + rnd.uniform(150, 280))], fill=(236, 244, 252), width=rnd.randint(2, 5))
    for k in range(12):
        nuage(dr, 200 + rnd.uniform(-60, 60), 420 + rnd.uniform(-30, 40), rnd.uniform(26, 40), (246, 248, 252), rnd, 5)
    return cadre(peinture(im, rnd, 2))


def affiche_ligne(rnd):
    W, H = 384, 512
    im = grad(W, H, [(0.0, (40, 92, 160)), (0.6, (120, 176, 226)), (1.0, (232, 240, 248))])
    dr = ImageDraw.Draw(im)
    # le câble, la capsule blanche, la Colonne en bas, l'île en haut (une affiche simple)
    dr.line([(W * 0.62, 0), (W * 0.38, H)], fill=(230, 236, 244), width=4)
    cx, cy = W * 0.5, H * 0.48
    dr.rounded_rectangle([cx - 44, cy - 60, cx + 44, cy + 60], radius=30, fill=(250, 250, 250), outline=(180, 196, 214), width=3)
    dr.rounded_rectangle([cx - 30, cy - 36, cx + 30, cy + 20], radius=14, fill=(120, 168, 214))
    dr.polygon([(W * 0.1, 60), (W * 0.9, 50), (W * 0.75, 100), (W * 0.5, 140), (W * 0.25, 102)], fill=(236, 240, 246))
    dr.rectangle([W * 0.3, H - 160, W * 0.36, H], fill=(214, 176, 92))
    for k in range(6):
        nuage(dr, rnd.uniform(0, W), rnd.uniform(H * 0.62, H * 0.9), rnd.uniform(20, 34), (250, 252, 255), rnd, 5)
    dr.rectangle([12, 12, W - 13, H - 13], outline=(250, 250, 250), width=6)
    return im.filter(ImageFilter.GaussianBlur(0.6))


def plan_ile(rnd):
    """La carte de l'île vue de dessus, en lignes claires sur un fond bleu nuit (un hologramme)."""
    W = H = 512
    im = Image.new("RGB", (W, H), (8, 22, 46))
    dr = ImageDraw.Draw(im)
    cx = cy = W / 2
    R = 210
    pts = []
    for k in range(64):
        a = math.tau * k / 64
        r = R * (1 + 0.05 * math.sin(a * 3) + 0.03 * math.sin(a * 7 + 1))
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    dr.polygon(pts, fill=(18, 52, 92), outline=(120, 210, 255))
    for rr, w in ((0.42, 2), (0.12, 2)):
        dr.ellipse([cx - R * rr, cy - R * rr, cx + R * rr, cy + R * rr], outline=(140, 220, 255), width=w)
    for k in range(8):
        a = math.tau * k / 8
        dr.line([(cx + math.cos(a) * R * 0.12, cy + math.sin(a) * R * 0.12), (cx + math.cos(a) * R * 0.42, cy + math.sin(a) * R * 0.42)], fill=(90, 170, 220), width=2)
    # les quartiers : des petits carrés, les dômes des serres, l'étang
    for k in range(26):
        a = rnd.uniform(0, math.tau)
        r = rnd.uniform(0.25, 0.8) * R
        x, y = cx + math.cos(a) * r, cy + math.sin(a) * r
        s = rnd.uniform(6, 14)
        dr.rectangle([x - s, y - s, x + s, y + s], outline=(160, 230, 255), width=2)
    for (dx, dy, r) in ((0.68, 0.0, 22), (0.6, -0.22, 13), (0.6, 0.2, 13)):
        dr.ellipse([cx + dx * R - r, cy + dy * R - r, cx + dx * R + r, cy + dy * R + r], outline=(180, 255, 210), width=3)
    dr.ellipse([cx - 0.5 * R - 24, cy - 0.44 * R - 24, cx - 0.5 * R + 24, cy - 0.44 * R + 24], fill=(30, 90, 150), outline=(140, 220, 255))
    # le cercle de la Navette
    dr.ellipse([cx - R * 0.82, cy - R * 0.82, cx + R * 0.82, cy + R * 0.82], outline=(255, 230, 150), width=2)
    im = im.filter(ImageFilter.GaussianBlur(0.8))
    return im


def isobares(rnd):
    W, H = 512, 320
    im = Image.new("RGB", (W, H), (14, 30, 52))
    dr = ImageDraw.Draw(im)
    centres = [(rnd.uniform(60, W - 60), rnd.uniform(60, H - 60), rnd.choice([1, -1])) for _ in range(3)]
    for (cx, cy, s) in centres:
        for k in range(1, 9):
            r = k * 22
            col = (120, 200, 255) if s > 0 else (255, 170, 140)
            dr.ellipse([cx - r * 1.3, cy - r, cx + r * 1.3, cy + r], outline=col, width=2)
    for k in range(18):
        x, y = rnd.uniform(20, W - 20), rnd.uniform(20, H - 20)
        a = rnd.uniform(0, math.tau)
        dr.line([(x, y), (x + math.cos(a) * 18, y + math.sin(a) * 18)], fill=(230, 240, 250), width=2)
        dr.ellipse([x - 3, y - 3, x + 3, y + 3], fill=(230, 240, 250))
    for x in range(0, W, 64):
        dr.line([(x, 0), (x, H)], fill=(30, 54, 80), width=1)
    for y in range(0, H, 64):
        dr.line([(0, y), (W, y)], fill=(30, 54, 80), width=1)
    return im.filter(ImageFilter.GaussianBlur(0.5))


def radar(rnd):
    W = H = 384
    im = Image.new("RGB", (W, H), (6, 24, 18))
    dr = ImageDraw.Draw(im)
    cx = cy = W / 2
    for k in range(1, 6):
        r = k * 36
        dr.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(40, 140, 90), width=2)
    dr.line([(cx, 0), (cx, H)], fill=(40, 140, 90), width=1)
    dr.line([(0, cy), (W, cy)], fill=(40, 140, 90), width=1)
    for k in range(40):
        a = math.radians(-40 + k)
        dr.line([(cx, cy), (cx + math.cos(a) * 180, cy + math.sin(a) * 180)], fill=(30, 110 + k * 3, 70 + k * 2), width=3)
    for k in range(9):
        a, r = rnd.uniform(0, math.tau), rnd.uniform(40, 170)
        x, y = cx + math.cos(a) * r, cy + math.sin(a) * r
        dr.ellipse([x - 9, y - 6, x + 9, y + 6], fill=(220, 250, 220))
    return im.filter(ImageFilter.GaussianBlur(0.6))


def ecran_mesures(rnd):
    W, H = 512, 320
    im = Image.new("RGB", (W, H), (10, 18, 34))
    dr = ImageDraw.Draw(im)
    for row in range(3):
        y0 = 20 + row * 100
        col = [(110, 210, 255), (140, 255, 190), (255, 210, 120)][row]
        pts = []
        for x in range(20, W - 20, 6):
            v = math.sin(x * 0.03 + row) * 18 + math.sin(x * 0.11 + row * 2) * 6 + rnd.uniform(-2, 2)
            pts.append((x, y0 + 40 + v))
        dr.line(pts, fill=col, width=3)
        dr.rectangle([18, y0, W - 18, y0 + 84], outline=(40, 70, 110), width=2)
    # quatre jauges (les quatre Sustentateurs)
    for k in range(4):
        x = W - 120 + k * 26
        h = rnd.uniform(60, 80)
        dr.rectangle([x, H - 20 - h, x + 16, H - 20], fill=(110, 210, 255))
    return im.filter(ImageFilter.GaussianBlur(0.5))


def plans_invention(rnd):
    W, H = 512, 384
    im = Image.new("RGB", (W, H), (36, 78, 140))
    dr = ImageDraw.Draw(im)
    for x in range(0, W, 16):
        dr.line([(x, 0), (x, H)], fill=(52, 96, 160), width=1)
    for y in range(0, H, 16):
        dr.line([(0, y), (W, y)], fill=(52, 96, 160), width=1)
    w = (230, 240, 250)
    # le parapluie-ascenseur : la toile, le manche, l'hélice, des cotes
    cx, cy = 190, 150
    dr.arc([cx - 120, cy - 70, cx + 120, cy + 70], 180, 360, fill=w, width=3)
    dr.line([(cx - 120, cy), (cx + 120, cy)], fill=w, width=2)
    for k in range(-3, 4):
        dr.line([(cx, cy - 70), (cx + k * 40, cy)], fill=w, width=1)
    dr.line([(cx, cy - 70), (cx, cy + 170)], fill=w, width=3)
    dr.arc([cx - 30, cy + 150, cx, cy + 190], 0, 180, fill=w, width=3)
    dr.ellipse([cx - 50, cy - 100, cx + 50, cy - 84], outline=w, width=2)
    dr.line([(cx - 60, cy - 92), (cx + 60, cy - 92)], fill=w, width=2)
    for (x0, y0, x1, y1) in ((330, 60, 480, 60), (330, 60, 330, 160), (330, 160, 480, 160), (480, 60, 480, 160)):
        dr.line([(x0, y0), (x1, y1)], fill=w, width=2)
    for k in range(6):
        dr.line([(340, 76 + k * 14), (340 + rnd.randint(60, 130), 76 + k * 14)], fill=w, width=2)
    for k in range(4):
        y = 230 + k * 30
        dr.line([(330, y), (330 + rnd.randint(80, 150), y)], fill=w, width=2)
        dr.ellipse([300, y - 6, 312, y + 6], outline=w, width=2)
    return im.filter(ImageFilter.GaussianBlur(0.5))


def tapis(rnd, base, motif):
    W = H = 512
    im = Image.new("RGB", (W, H), base)
    px = im.load()
    for y in range(H):
        for x in range(W):
            g = rnd.randint(-7, 7)
            r, gg, b = px[x, y]
            px[x, y] = (max(0, min(255, r + g)), max(0, min(255, gg + g)), max(0, min(255, b + g)))
    dr = ImageDraw.Draw(im)
    dr.rectangle([24, 24, W - 25, H - 25], outline=motif, width=8)
    dr.rectangle([48, 48, W - 49, H - 49], outline=motif, width=3)
    for k in range(5):
        y = 120 + k * 68
        dr.line([(90, y), (W - 90, y)], fill=motif, width=4)
    return im.filter(ImageFilter.GaussianBlur(1.0))


def enduit_blanc(seed=117, N=1024):
    """L'enduit blanc des murs des Nuées (raccordable) : un blanc chaud et doux, quelques passes de
    lisseuse à peine visibles, aucune tache. Rend [couleur, normales]."""
    import numpy as np
    rng = np.random.default_rng(seed)

    def bruit(n):
        # un bruit doux raccordable : une petite grille aléatoire, agrandie sur 3×3 tuiles, recadrée
        g = rng.random((n, n)).astype(np.float32)
        t = np.tile(g, (3, 3))
        im = Image.fromarray((t * 255).astype(np.uint8), "L").resize((N * 3, N * 3), Image.BICUBIC)
        return np.asarray(im.crop((N, N, 2 * N, 2 * N)), dtype=np.float32) / 255.0

    h = bruit(6) * 0.5 + bruit(16) * 0.3 + bruit(64) * 0.14 + bruit(256) * 0.06
    # les passes de lisseuse : de longues ellipses très claires ou très peu plus sombres, raccordées
    passes = Image.new("L", (N, N), 128)
    dr = ImageDraw.Draw(passes)
    rnd = random.Random(seed)
    for _ in range(70):
        cx, cy = rnd.uniform(0, N), rnd.uniform(0, N)
        a = rnd.uniform(-0.6, 0.6)
        L, W = rnd.uniform(120, 300), rnd.uniform(26, 60)
        v = 128 + rnd.choice([-1, 1]) * rnd.randint(6, 14)
        for ox in (-N, 0, N):
            for oy in (-N, 0, N):
                pts = []
                for k in range(16):
                    t = k / 16.0 * math.tau
                    x, y = math.cos(t) * L * 0.5, math.sin(t) * W * 0.5
                    pts.append((cx + ox + x * math.cos(a) - y * math.sin(a), cy + oy + x * math.sin(a) + y * math.cos(a)))
                dr.polygon(pts, fill=v)
    passes = passes.filter(ImageFilter.GaussianBlur(14))
    p = (np.asarray(passes, dtype=np.float32) - 128.0) / 128.0
    h = h + p * 0.35
    grain = rng.normal(0.0, 1.0, (N, N)).astype(np.float32)
    h2 = h + grain * 0.012
    v = (h2 - h2.mean()) / max(1e-6, h2.std())
    base = np.array([243.0, 241.0, 237.0], dtype=np.float32)
    col = base[None, None, :] + v[:, :, None] * np.array([2.6, 2.6, 2.9], dtype=np.float32)
    col = np.clip(col, 0, 255).astype(np.uint8)
    # les normales (raccordées) : la pente de la hauteur, très douce
    hh = np.asarray(Image.fromarray(((h - h.min()) / max(1e-6, h.max() - h.min()) * 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(1.2)), dtype=np.float32) / 255.0
    hh = hh + grain * 0.004
    dx = (np.roll(hh, -1, axis=1) - np.roll(hh, 1, axis=1)) * 3.5
    dy = (np.roll(hh, -1, axis=0) - np.roll(hh, 1, axis=0)) * 3.5
    nz = np.ones_like(dx)
    ln = np.sqrt(dx * dx + dy * dy + nz * nz)
    nrm = np.stack([-dx / ln, dy / ln, nz / ln], axis=-1)
    nrm = ((nrm * 0.5 + 0.5) * 255).astype(np.uint8)
    return Image.fromarray(col, "RGB"), Image.fromarray(nrm, "RGB")


# Le panorama vu des baies de la Cité des Nuées : un ruban équirectangulaire raccordable en largeur.
# Colonnes : l'azimut, de 0 à 360° ; lignes : la hauteur, de +PANO_HAUT° (en haut) à -PANO_BAS° (en bas).
PANO_HAUT = 25.0
PANO_BAS = 45.0


def _perm(rng):
    import numpy as np
    p = np.arange(256, dtype=np.int64)
    rng.shuffle(p)
    return p


def _perlin(x, y, perm):
    """Un bruit de gradient (Perlin) sur des tableaux numpy ; à peu près dans [-0,7 ; 0,7]."""
    import numpy as np
    xi = np.floor(x).astype(np.int64)
    yi = np.floor(y).astype(np.int64)
    xf = (x - xi).astype(np.float32)
    yf = (y - yi).astype(np.float32)

    def g(ix, iy):
        h = perm[(perm[ix & 255] + iy) & 255].astype(np.float32) * (2.0 * np.pi / 256.0)
        return np.cos(h), np.sin(h)

    def fade(t):
        return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)

    a, b = g(xi, yi)
    n00 = a * xf + b * yf
    a, b = g(xi + 1, yi)
    n10 = a * (xf - 1.0) + b * yf
    a, b = g(xi, yi + 1)
    n01 = a * xf + b * (yf - 1.0)
    a, b = g(xi + 1, yi + 1)
    n11 = a * (xf - 1.0) + b * (yf - 1.0)
    u = fade(xf)
    v = fade(yf)
    return (n00 * (1.0 - u) + n10 * u) * (1.0 - v) + (n01 * (1.0 - u) + n11 * u) * v


def _fbm(X, Y, perms, lam0, foot):
    """La somme de plusieurs octaves ; celles qui seraient plus fines que la taille d'un pixel au sol
    (foot, en mètres) s'effacent doucement (sinon : du bruit qui fourmille près de l'horizon)."""
    import numpy as np
    tot = np.zeros_like(X, dtype=np.float32)
    amp = 1.0
    lam = lam0
    for o, p in enumerate(perms):
        w = np.clip(1.0 - foot / (0.6 * lam), 0.0, 1.0)
        c, s = math.cos(0.7 * o), math.sin(0.7 * o)
        tot += amp * w * _perlin((X * c - Y * s) / lam + 31.7 * o, (X * s + Y * c) / lam - 17.3 * o, p)
        amp *= 0.5
        lam *= 0.5
    return tot


def panorama(nuit, seed=1170, W=4096, H=800):
    """Ce qu'on voit par les baies de la Cité des Nuées : le ciel ; l'horizon (un peu de brume) ; sous
    la Cité, une mer de nuages qui s'ouvre par endroits sur la mer, très loin en bas ; dans une trouée,
    Hautefond. La nuit : les étoiles, la Lune et son reflet, les nuages bleutés, les lumières de la
    ville. Tout se calcule en perspective (une couche de nuages 150 m sous les yeux, la mer à 300 m)."""
    import numpy as np
    rng = np.random.default_rng(seed)
    rnd = random.Random(seed + (7 if nuit else 0))
    perms = [_perm(rng) for _ in range(8)]
    th = (np.arange(W, dtype=np.float32) + 0.5) / W * (2.0 * np.pi)
    el = PANO_HAUT - (np.arange(H, dtype=np.float32) + 0.5) / H * (PANO_HAUT + PANO_BAS)   # degrés
    TH, EL = np.meshgrid(th, el)
    dpx = math.radians((PANO_HAUT + PANO_BAS) / H)
    hz = int(round(PANO_HAUT / (PANO_HAUT + PANO_BAS) * H))
    img = np.zeros((H, W, 3), np.float32)
    # --- le ciel
    t = np.clip(EL / PANO_HAUT, 0.0, 1.0)[..., None]
    if nuit:
        zen, hor = np.array([3, 6, 20], np.float32), np.array([26, 36, 70], np.float32)
    else:
        zen, hor = np.array([62, 118, 196], np.float32), np.array([196, 218, 238], np.float32)
    img[:] = hor + (zen - hor) * (t ** 0.55)
    th_sun = 0.18 * 2 * np.pi
    th_moon = 0.31 * 2 * np.pi
    if not nuit:
        # la lueur du soleil (il est plus haut que le ruban)
        dth = np.angle(np.exp(1j * (TH - th_sun)))
        glow = np.exp(-(dth ** 2) / 0.35) * np.clip((EL + 5.0) / 30.0, 0.0, 1.0)
        img += glow[..., None] * np.array([40, 30, 10], np.float32)
    # des cumulus lointains posés sur l'horizon : des grappes de bosses arrondies (en degrés)
    TOP = np.full(W, -9.0, np.float32)
    thd = np.degrees(th)
    for _ in range(26):
        c0 = rnd.uniform(0.0, 360.0)
        larg = rnd.uniform(2.0, 9.0)
        haut = rnd.uniform(0.6, 2.6)
        for _b in range(int(larg * 3.0) + 3):
            cb = c0 + rnd.uniform(-larg * 0.5, larg * 0.5)
            u = 1.0 - abs(cb - c0) / (larg * 0.5 + 1e-3)
            rb = rnd.uniform(0.35, 0.9) * (0.5 + 0.5 * u) * max(0.8, haut)
            hb = haut * (0.25 + 0.75 * u) * rnd.uniform(0.6, 1.0) - rb * 0.6
            d = np.abs(((thd - cb + 180.0) % 360.0) - 180.0)
            prof = hb + np.sqrt(np.maximum(rb * rb - d * d, 0.0)) * 0.6
            prof = np.where(d < rb, prof, -9.0)
            TOP = np.maximum(TOP, prof.astype(np.float32))
    TOPm = np.broadcast_to(TOP[None, :], EL.shape)
    inside = np.clip((TOPm - EL) / 0.12, 0.0, 1.0) * (EL > -0.3)
    shade = np.clip((EL + 0.3) / np.maximum(TOPm + 0.3, 0.3), 0.0, 1.0)[..., None]
    if nuit:
        c_bas, c_haut = np.array([42, 50, 82], np.float32), np.array([96, 106, 140], np.float32)
    else:
        c_bas, c_haut = np.array([176, 190, 212], np.float32), np.array([253, 253, 251], np.float32)
    cum = c_bas + (c_haut - c_bas) * (shade ** 0.6)
    img = img * (1 - inside[..., None] * 0.9) + cum * inside[..., None] * 0.9
    # --- sous l'horizon : la couche de nuages et la mer
    beta = np.radians(np.maximum(-EL, 0.02))
    below = EL < 0.0
    tb = np.tan(beta)
    Dn = np.minimum(150.0 / tb, 60000.0)                 # distance du point de nuage sous ce pixel
    Dm = np.minimum(300.0 / tb, 150000.0)                # distance du point de mer
    footn = np.maximum(Dn * (2 * np.pi / W), Dn * dpx / np.maximum(np.sin(beta), 1e-4))
    Xn, Zn = Dn * np.cos(TH), Dn * np.sin(TH)
    dens = _fbm(Xn, Zn, perms[:7], 600.0, footn) * 1.25
    # la trouée de Hautefond
    th_h = 0.72 * 2 * np.pi
    Xh, Zh = 1700.0 * math.cos(th_h), 1700.0 * math.sin(th_h)
    dens -= 1.4 * np.exp(-((Xn - Xh) ** 2 + (Zn - Zh) ** 2) / (2 * 420.0 ** 2))
    far = np.clip(footn / 600.0, 0.0, 1.0)
    alpha = np.clip((dens + 0.1) / 0.2, 0.0, 1.0)
    alpha = alpha * (1 - far) + 0.7 * far
    # le relief : le côté au soleil est plus clair
    sx, sz = math.cos(th_sun) * 40.0, math.sin(th_sun) * 40.0
    dens2 = _fbm(Xn + sx, Zn + sz, perms[:7], 600.0, footn) * 1.25
    lum = np.clip(0.78 + 0.5 * (dens - dens2) + 0.25 * np.clip(dens, 0, 0.6), 0.55, 1.08)
    lum = lum * (1 - far) + 0.92 * far
    if nuit:
        nc = np.array([92, 104, 142], np.float32)
    else:
        nc = np.array([248, 249, 252], np.float32)
    cloud = nc * lum[..., None]
    if not nuit:
        cloud += np.array([-26, -16, 0], np.float32) * np.clip(1.0 - lum, 0.0, 1.0)[..., None] * 3.0
    # la mer, très loin en bas (et l'ombre des nuages dessus)
    tm = np.clip(np.degrees(beta) / PANO_BAS, 0.0, 1.0)[..., None]
    if nuit:
        m_h, m_b = np.array([20, 28, 52], np.float32), np.array([4, 7, 16], np.float32)
    else:
        m_h, m_b = np.array([128, 160, 192], np.float32), np.array([30, 72, 118], np.float32)
    sea = m_h + (m_b - m_h) * (tm ** 0.45)
    Xm, Zm = Dm * np.cos(TH), Dm * np.sin(TH)
    footm = np.maximum(Dm * (2 * np.pi / W), Dm * dpx / np.maximum(np.sin(beta), 1e-4))
    if not nuit:
        ombre = _fbm(Xm * 0.5 - sx * 3.0, Zm * 0.5 - sz * 3.0, perms[:7], 600.0, footm * 0.5) * 1.25
        ombre -= 1.4 * np.exp(-((Xm * 0.5 - Xh) ** 2 + (Zm * 0.5 - Zh) ** 2) / (2 * 420.0 ** 2))
        sh = np.clip((ombre + 0.1) / 0.2, 0.0, 1.0) * (1 - np.clip(footm / 2500.0, 0, 1))
        sea *= (1.0 - 0.35 * sh)[..., None]
        # quelques vagues qui scintillent
        sea += (rng.random((H, W)).astype(np.float32) < 0.004)[..., None] * 40.0 * (1 - tm)
    else:
        # le reflet de la Lune
        dthm = np.abs(np.angle(np.exp(1j * (TH - th_moon))))
        path = np.exp(-(dthm ** 2) / (2 * 0.02 ** 2)) * (rng.random((H, W)) < 0.35)
        sea += path[..., None] * np.array([150, 150, 130], np.float32) * (1 - tm) ** 1.5
    # Hautefond, vu d'en haut, au fond de la trouée (la mer est deux fois plus loin que les nuages)
    Xhm, Zhm = Xh * 2.0, Zh * 2.0
    dI = np.sqrt((Xm - Xhm) ** 2 + (Zm - Zhm) ** 2)
    ilot = np.clip((520.0 - dI) / 80.0, 0.0, 1.0) * below
    if nuit:
        sea = sea * (1 - ilot[..., None]) + np.array([16, 18, 24], np.float32) * ilot[..., None]
        lights = (rng.random((H, W)) < 0.09) * np.clip((440.0 - dI) / 60.0, 0.0, 1.0)
        sea += lights[..., None] * np.array([255, 190, 110], np.float32)
        sea += np.exp(-(dI / 520.0) ** 2)[..., None] * np.array([40, 26, 10], np.float32)
    else:
        bruit_i = rng.random((H, W)).astype(np.float32)
        ville = np.array([170, 150, 120], np.float32) * (0.8 + 0.4 * bruit_i[..., None])
        verdure = np.array([96, 130, 80], np.float32) * (0.8 + 0.4 * bruit_i[..., None])
        terre = np.where((dI < 300.0)[..., None], ville, verdure)
        sea = sea * (1 - ilot[..., None]) + terre * ilot[..., None]
    low = sea * (1 - alpha[..., None]) + cloud * alpha[..., None]
    # la brume de l'air, plus épaisse au loin
    haze = (1.0 - np.exp(-Dn / 14000.0))[..., None]
    hc = np.array([30, 40, 72], np.float32) if nuit else np.array([200, 218, 236], np.float32)
    low = low * (1 - haze) + hc * haze
    img = np.where(below[..., None], low, img)
    # une bande de brume sur l'horizon
    bz = np.exp(-(EL / 1.2) ** 2)[..., None] * 0.55
    img = img * (1 - bz) + hc * bz
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB")
    if nuit:
        dr = ImageDraw.Draw(im, "RGBA")
        # les étoiles (plus nombreuses en haut), la Lune et son halo
        for _ in range(1400):
            x = rnd.uniform(0, W)
            y = (rnd.random() ** 1.5) * (hz - 12)
            b = rnd.randint(110, 255)
            r0 = 0.55 if rnd.random() < 0.92 else 1.2
            dr.ellipse([x - r0, y - r0, x + r0, y + r0], fill=(b, b, min(255, b + 18), 255))
        mx = th_moon / (2 * np.pi) * W
        my = (PANO_HAUT - 13.0) / (PANO_HAUT + PANO_BAS) * H
        for k in range(18, 0, -1):
            rr = 14 + k * 5
            dr.ellipse([mx - rr, my - rr, mx + rr, my + rr], fill=(120, 140, 200, 5))
        dr.ellipse([mx - 13, my - 13, mx + 13, my + 13], fill=(238, 238, 224, 255))
        dr.ellipse([mx - 5, my - 7, mx + 1, my - 1], fill=(222, 222, 208, 255))
        dr.ellipse([mx + 3, my + 2, mx + 8, my + 7], fill=(226, 226, 212, 255))
    big = Image.new("RGB", (W * 3, H))
    for k in range(3):
        big.paste(im, (k * W, 0))
    big = big.filter(ImageFilter.GaussianBlur(0.7))
    return big.crop((W, 0, 2 * W, H))


def main():
    os.makedirs(OUT, exist_ok=True)
    rnd = random.Random(117)
    panorama(False).save(os.path.join(OUT, "panorama_jour.png"))
    panorama(True).save(os.path.join(OUT, "panorama_nuit.png"))
    print("écrit panorama_jour.png, panorama_nuit.png")
    c, n = enduit_blanc()
    c.save(os.path.join(OUT, "enduit_blanc.png"))
    n.save(os.path.join(OUT, "enduit_blanc_n.png"))
    print("écrit enduit_blanc.png, enduit_blanc_n.png")
    todo = {
        "tableau_coucher.png": tableau_coucher,
        "tableau_nuages.png": tableau_nuages,
        "tableau_cascade.png": tableau_cascade,
        "affiche_ligne.png": affiche_ligne,
        "plan_ile.png": plan_ile,
        "isobares.png": isobares,
        "radar.png": radar,
        "ecran_mesures.png": ecran_mesures,
        "plans_invention.png": plans_invention,
    }
    for name, fn in todo.items():
        fn(rnd).save(os.path.join(OUT, name))
        print("écrit", name)
    tapis(rnd, (196, 198, 200), (150, 156, 166)).save(os.path.join(OUT, "tapis_laine.png"))
    tapis(rnd, (176, 206, 232), (240, 246, 250)).save(os.path.join(OUT, "tapis_ciel.png"))
    print("écrit tapis_laine.png, tapis_ciel.png")


if __name__ == "__main__":
    main()
