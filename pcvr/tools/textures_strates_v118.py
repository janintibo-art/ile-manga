#!/usr/bin/env python3
"""V118 : les textures des intérieurs des Strates et de la Fronde (www/assets/textures/strates/) :
 - le grès en couches des murs creusés dans la roche (gres.png, et ses normales) : des bandes ocre,
   crème, rouille et grises, un peu ondulées, comme la caverne des Strates ;
 - les dalles de grès du sol (dalles_gres.png, et ses normales) ;
 - la tôle peinte, écaillée, des conteneurs de la Fronde (tole_fronde.png, et ses normales), et
   quelques affiches de concert des Soupapes (affiche_soupapes_1..3.png), sans texte.
Tout est dessiné ici (Pillow + numpy), sans texte : les images n'ont pas besoin d'être traduites.
Usage : python3 pcvr/tools/textures_strates_v118.py (depuis la racine du dépôt)."""
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "www", "assets", "textures", "strates")


def _perm(rng):
    p = np.arange(256, dtype=np.int64)
    rng.shuffle(p)
    return p


def _perlin(x, y, perm):
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


def _tile_noise(N, lam, perm):
    """Un bruit raccordable (le bruit est pris sur un tore : on fond quatre copies)."""
    ys, xs = np.mgrid[0:N, 0:N].astype(np.float32)
    n = _perlin(xs / lam, ys / lam, perm)
    # raccord : un fondu en x et en y entre l'image et sa copie décalée
    n2 = np.roll(n, N // 2, axis=1)
    wx = np.abs(np.linspace(-1, 1, N, dtype=np.float32))[None, :]
    n = n * (1 - wx) + n2 * wx
    n3 = np.roll(n, N // 2, axis=0)
    wy = np.abs(np.linspace(-1, 1, N, dtype=np.float32))[:, None]
    return n * (1 - wy) + n3 * wy


def _normals(h, strength):
    dx = (np.roll(h, -1, axis=1) - np.roll(h, 1, axis=1)) * strength
    dy = (np.roll(h, -1, axis=0) - np.roll(h, 1, axis=0)) * strength
    nz = np.ones_like(dx)
    ln = np.sqrt(dx * dx + dy * dy + nz * nz)
    nrm = np.stack([-dx / ln, dy / ln, nz / ln], axis=-1)
    return Image.fromarray(((nrm * 0.5 + 0.5) * 255).astype(np.uint8), "RGB")


def gres(seed=118, N=1024):
    rng = np.random.default_rng(seed)
    perms = [_perm(rng) for _ in range(4)]
    ys = np.arange(N, dtype=np.float32)[:, None] * np.ones((1, N), np.float32)
    # les couches : la hauteur ondule un peu le long de x (le bruit ne dépend presque que de x)
    ondul = _tile_noise(N, 220.0, perms[0]) * 26.0 + _tile_noise(N, 70.0, perms[1]) * 6.0
    v = (ys + ondul) / N * 2.0 * np.pi
    # des teintes proches (un vrai grès : ocre, sable, un peu de rouille et de gris), sans couleurs de bonbon
    bandes = [
        (186, 150, 108),   # ocre
        (204, 180, 144),   # sable clair
        (168, 122, 86),    # ocre rouge
        (158, 146, 128),   # gris beige
        (194, 160, 116),   # ocre clair
        (176, 132, 96),    # terre cuite douce
    ]
    rnd = random.Random(seed)
    couches = []
    t = 0.0
    while t < 2 * np.pi:
        ep = rnd.uniform(0.22, 0.7)
        couches.append((t, min(t + ep, 2 * np.pi), rnd.randrange(len(bandes))))
        t += ep
    # chaque couche se fond dans la suivante (pas d'arête nette) : on mélange par un profil doux
    vv = v % (2 * np.pi)
    img = np.zeros((N, N, 3), np.float32)
    wsum = np.zeros((N, N), np.float32)
    for (t0, t1, k) in couches:
        mid = 0.5 * (t0 + t1)
        half = 0.5 * (t1 - t0)
        d = np.abs(((vv - mid + np.pi) % (2 * np.pi)) - np.pi)
        w = np.clip(1.0 - (d - half * 0.7) / (half * 0.6 + 0.02), 0, 1) ** 2
        img += w[..., None] * np.array(bandes[k], np.float32)[None, None, :]
        wsum += w
    img = img / np.maximum(wsum, 1e-3)[..., None]
    # des taches à grande échelle (la roche n'est jamais uniforme), le grain, les petits points
    tache = _tile_noise(N, 160.0, perms[2]) * 22.0
    grain = _tile_noise(N, 6.0, perms[3]) * 10.0 + _tile_noise(N, 1.8, perms[1]) * 9.0
    img = img + (tache + grain)[..., None] * np.array([1.0, 0.92, 0.82], np.float32)[None, None, :]
    # les joints : un fil sombre discret, seulement par endroits
    lim = np.zeros((N, N), np.float32)
    casse = np.clip(_tile_noise(N, 90.0, perms[0]) * 2.0 + 0.4, 0, 1)
    for (t0, t1, k) in couches:
        d = np.abs(((v - t0 + np.pi) % (2 * np.pi)) - np.pi)
        lim = np.maximum(lim, np.clip(1.0 - d / 0.02, 0, 1) * casse)
    img = img * (1.0 - lim[..., None] * 0.18)
    h = -lim * 0.4 + grain / 30.0 + tache / 80.0
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB"), _normals(h, 2.0)


def dalles_gres(seed=1180, N=1024):
    rng = np.random.default_rng(seed)
    perms = [_perm(rng) for _ in range(3)]
    ys, xs = np.mgrid[0:N, 0:N].astype(np.float32)
    n = 4
    cell = N / n
    row = np.floor(ys / cell)
    xo = (row % 2) * cell * 0.5
    col = np.floor((xs + xo) / cell)
    fx = ((xs + xo) % cell) / cell
    fy = (ys % cell) / cell
    joint = np.clip(np.minimum(np.minimum(fx, 1 - fx), np.minimum(fy, 1 - fy)) / 0.035, 0, 1)
    rnd = random.Random(seed)
    img = np.zeros((N, N, 3), np.float32)
    base = [(192, 160, 118), (176, 140, 96), (206, 178, 136), (168, 128, 92), (184, 150, 108)]
    for r in range(n):
        for c in range(n + 1):
            cc = np.array(base[rnd.randrange(len(base))], np.float32) * rnd.uniform(0.9, 1.08)
            m = (row == r) & (col == c)
            img = np.where(m[..., None], cc[None, None, :], img)
    img = img + (_tile_noise(N, 6.0, perms[0]) * 14.0 + _tile_noise(N, 40.0, perms[1]) * 12.0)[..., None]
    img = img * (0.55 + 0.45 * joint)[..., None]
    h = joint * 0.8 + _tile_noise(N, 6.0, perms[2]) * 0.15
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB"), _normals(h, 1.6)


def tole_fronde(seed=1181, N=1024):
    """De la tôle ondulée peinte (crème), écaillée par places, rouillée sur les bords des ondes."""
    rng = np.random.default_rng(seed)
    perms = [_perm(rng) for _ in range(3)]
    ys, xs = np.mgrid[0:N, 0:N].astype(np.float32)
    onde = np.sin(xs / N * 2 * np.pi * 24.0)
    paint = np.array([226, 214, 190], np.float32)
    rust = np.array([122, 66, 36], np.float32)
    metal = np.array([150, 146, 140], np.float32)
    ecaille = _tile_noise(N, 90.0, perms[0]) + _tile_noise(N, 30.0, perms[1]) * 0.5
    k = np.clip((ecaille - 0.12) * 5.0, 0, 1)         # là où la peinture est partie (des plaques, pas des points)
    r0 = np.clip((ecaille - 0.36) * 6.0, 0, 1)         # là où ça rouille
    # la rouille coule vers le bas en longues traînées (dans les creux des ondes surtout)
    creux = np.clip(-onde, 0, 1)
    src = np.clip(r0 + creux * np.clip(_tile_noise(N, 40.0, perms[2]) * 3.0 - 0.2, 0, 1) * 0.6, 0, 1)
    coule = np.zeros_like(src)
    acc = src[-1].copy()
    for y in range(2 * N):
        yy = y % N
        acc = np.maximum(src[yy], acc * 0.992)
        if y >= N:
            coule[yy] = acc
    r = np.clip(np.maximum(r0, coule * 0.55), 0, 1)
    img = paint[None, None, :] * (1 - k[..., None]) + metal[None, None, :] * k[..., None]
    img = img * (1 - r[..., None]) + rust[None, None, :] * r[..., None]
    img = img * (0.8 + 0.2 * onde)[..., None]
    img = img + (_tile_noise(N, 4.0, perms[2]) * 9.0)[..., None]
    h = onde * 0.5 - k * 0.12
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB"), _normals(h, 1.2)


def affiche(seed):
    """Une affiche de concert des Soupapes : des formes, des rayures, pas de texte."""
    rnd = random.Random(seed)
    W, H = 384, 512
    pal = [(236, 72, 60), (250, 200, 50), (40, 160, 200), (60, 180, 110), (150, 70, 190), (20, 20, 24), (245, 240, 225)]
    bg = rnd.choice(pal[:5])
    im = Image.new("RGB", (W, H), bg)
    dr = ImageDraw.Draw(im)
    for _ in range(6):
        c = rnd.choice(pal)
        x0, y0 = rnd.randint(-40, W), rnd.randint(-40, H)
        if rnd.random() < 0.5:
            dr.ellipse([x0, y0, x0 + rnd.randint(60, 220), y0 + rnd.randint(60, 220)], fill=c)
        else:
            dr.rectangle([x0, y0, x0 + rnd.randint(40, 200), y0 + rnd.randint(20, 160)], fill=c)
    # l'emblème des Soupapes, au milieu : un volant de vanne (une roue à rayons) d'où s'échappent des notes de musique
    cx, cy, rr = W // 2, H // 2 - 10, 100
    ink = (20, 20, 24)
    dr.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], outline=ink, width=16)
    for k in range(5):
        a = k / 5.0 * math.tau + rnd.random() * 0.3
        dr.line([(cx, cy), (cx + math.cos(a) * rr, cy + math.sin(a) * rr)], fill=ink, width=12)
    dr.ellipse([cx - 22, cy - 22, cx + 22, cy + 22], fill=ink)
    for k in range(5):
        a = k / 5.0 * math.tau + 0.6
        bx, by = cx + math.cos(a) * rr, cy + math.sin(a) * rr
        dr.ellipse([bx - 12, by - 12, bx + 12, by + 12], fill=ink)
    # trois notes de musique qui montent en vapeur, à droite
    for k in range(3):
        nx, ny = cx + 78 + k * 30, cy - 60 - k * 40
        dr.ellipse([nx - 14, ny - 10, nx + 14, ny + 10], fill=ink)
        dr.line([(nx + 12, ny), (nx + 12, ny - 52)], fill=ink, width=6)
        dr.line([(nx + 12, ny - 52), (nx + 30, ny - 40)], fill=ink, width=6)
    # des rayures de « texte » (des barres), en bas
    for k in range(3):
        y = H - 90 + k * 24
        dr.rectangle([40, y, 40 + rnd.randint(120, 300), y + 12], fill=pal[5] if bg != pal[5] else pal[6])
    px = im.load()
    for y in range(H):
        for x in range(W):
            g = rnd.randint(-8, 8)
            r0, g0, b0 = px[x, y]
            px[x, y] = (max(0, min(255, r0 + g)), max(0, min(255, g0 + g)), max(0, min(255, b0 + g)))
    return im.filter(ImageFilter.GaussianBlur(0.6))


def main():
    os.makedirs(OUT, exist_ok=True)
    c, n = gres()
    c.save(os.path.join(OUT, "gres.png"))
    n.save(os.path.join(OUT, "gres_n.png"))
    c, n = dalles_gres()
    c.save(os.path.join(OUT, "dalles_gres.png"))
    n.save(os.path.join(OUT, "dalles_gres_n.png"))
    c, n = tole_fronde()
    c.save(os.path.join(OUT, "tole_fronde.png"))
    n.save(os.path.join(OUT, "tole_fronde_n.png"))
    for k in range(3):
        affiche(118 + k).save(os.path.join(OUT, "affiche_soupapes_%d.png" % (k + 1)))
    print("écrit gres, dalles_gres, tole_fronde (+ normales), affiche_soupapes_1..3")


if __name__ == "__main__":
    main()
