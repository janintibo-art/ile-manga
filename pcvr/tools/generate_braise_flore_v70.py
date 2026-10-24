#!/usr/bin/env python3
"""V70 : les textures de la végétation de l'Île de Braise (procédurales, sans réseau).

 - feuilles_braise.png (512 x 512, RGBA) : une grappe de feuilles d'arbre de braise : des
   feuilles pointues, rouge sombre au pied, orange puis jaune vers la pointe, des nervures
   claires ; quelques feuilles presque noires (brûlées) ;
 - fleur_braise.png (256 x 256, RGBA) : une fleur de braise vue de face : des pétales en
   flammes (jaune au cœur, orange, rouge au bout), un cœur sombre ;
 - ecorce_braise.png / ecorce_braise_n.png (512 x 512, raccordables) : une écorce noire,
   profondément crevassée, avec un peu de feu rouge au fond des crevasses.

Usage : python3 generate_braise_flore_v70.py
"""
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "braise"


def lerp(a, b, t):
    return a + (b - a) * t


def leaf_cluster(size=512, ss=4, seed=7081):
    rng = np.random.default_rng(seed)
    S = size * ss
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = cy = S / 2
    leaves = []
    for i in range(170):
        r = (rng.random() ** 0.6) * S * 0.38
        a = rng.random() * math.tau
        x = cx + math.cos(a) * r
        y = cy + math.sin(a) * r
        ang = a + rng.uniform(-0.9, 0.9)
        L = S * rng.uniform(0.08, 0.13)
        W = L * rng.uniform(0.28, 0.4)
        leaves.append((r, x, y, ang, L, W, rng.random(), rng.random()))
    # les feuilles du dedans d'abord (elles passent dessous)
    leaves.sort(key=lambda t: t[0])
    for (r, x, y, ang, L, W, burnt, hue) in leaves:
        ca, sa = math.cos(ang), math.sin(ang)
        n = 18
        # le contour d'une feuille pointue : une amande qui s'effile vers la pointe
        pts_l, pts_r = [], []
        for k in range(n + 1):
            t = k / n
            w = W * 0.5 * math.sin(math.pi * t) ** 0.8 * (1.0 - 0.35 * t)
            px = (t - 0.15) * L
            pts_l.append((px, w))
            pts_r.append((px, -w))
        poly = pts_l + pts_r[::-1]
        dark = burnt < 0.12
        # le dégradé : on pose des bandes du pied à la pointe
        steps = 10
        for s in range(steps):
            t0 = s / steps
            t1 = (s + 1) / steps
            sub = [(px, py) for (px, py) in poly if t0 * L - 0.15 * L <= px <= t1 * L - 0.15 * L + 1.0]
            if len(sub) < 3:
                continue
        # simple : un remplissage en couches, de la teinte du pied à celle de la pointe
        for s in range(steps, 0, -1):
            t = s / steps
            if dark:
                col = (int(lerp(18, 40, t)), int(lerp(10, 16, t)), int(lerp(8, 10, t)), 255)
            else:
                base = (70 + 30 * hue, 8 + 6 * hue, 5)
                mid = (175 + 30 * hue, 34 + 20 * hue, 8)
                tip = (240, 105 + 50 * hue, 22)
                if t < 0.55:
                    u = t / 0.55
                    c = [lerp(base[j], mid[j], u) for j in range(3)]
                else:
                    u = (t - 0.55) / 0.45
                    c = [lerp(mid[j], tip[j], u) for j in range(3)]
                col = (int(c[0]), int(c[1]), int(c[2]), 255)
            scale = t
            spoly = []
            for (px, py) in poly:
                qx = -0.15 * L + (px + 0.15 * L) * scale
                qy = py * (0.55 + 0.45 * scale)
                spoly.append((x + qx * ca - qy * sa, y + qx * sa + qy * ca))
            d.polygon(spoly, fill=col)
        # la nervure médiane, deux ou trois nervures de côté
        vein = (255, 170, 70, 255) if not dark else (70, 30, 16, 255)
        x0, y0 = x - 0.15 * L * ca, y - 0.15 * L * sa
        x1, y1 = x + 0.82 * L * ca, y + 0.82 * L * sa
        d.line([(x0, y0), (x1, y1)], fill=vein, width=max(2, int(W * 0.05)))
        for k in range(3):
            t = 0.15 + k * 0.22
            bx, by = lerp(x0, x1, t), lerp(y0, y1, t)
            for sgn in (-1, 1):
                ex = bx + (ca * 0.6 - sgn * sa * 0.8) * W * 0.4
                ey = by + (sa * 0.6 + sgn * ca * 0.8) * W * 0.4
                d.line([(bx, by), (ex, ey)], fill=vein, width=max(1, int(W * 0.025)))
    img = img.resize((size, size), Image.LANCZOS)
    a = np.asarray(img).astype(np.float32)
    # un peu de grain dans la couleur, l'alpha net
    g = np.random.default_rng(seed + 1).normal(0, 6, (size, size, 1))
    a[..., :3] = np.clip(a[..., :3] + g, 0, 255)
    a[..., 3] = np.where(a[..., 3] > 110, 255, 0)
    Image.fromarray(a.astype(np.uint8), "RGBA").save(OUT / "feuilles_braise.png", optimize=True)


def fire_flower(size=256, ss=4, seed=7082):
    rng = np.random.default_rng(seed)
    S = size * ss
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = S / 2
    npet = 7
    for layer in range(2):
        for i in range(npet):
            a = math.tau * (i + 0.5 * layer) / npet + rng.uniform(-0.12, 0.12)
            L = S * (0.46 if layer == 0 else 0.33)
            W = L * 0.5
            for s in range(12, 0, -1):
                t = s / 12
                tip = (205, 30, 10) if layer == 0 else (240, 90, 20)
                core = (255, 235, 120)
                col = tuple(int(lerp(core[j], tip[j], t)) for j in range(3)) + (255,)
                pts = []
                for k in range(25):
                    u = k / 24
                    w = W * 0.5 * math.sin(math.pi * u) ** 0.7 * (1 - u * 0.6)
                    # la pointe de la flamme se recourbe un peu
                    bend = 0.18 * W * u * u
                    for side in (1,):
                        pass
                    pts.append((u * L * t, w * t + bend * t))
                pts2 = [(px, -py + 2 * 0.18 * W * (px / L) ** 2 * t) for (px, py) in pts[::-1]]
                poly = pts + pts2
                ca, sa = math.cos(a), math.sin(a)
                d.polygon([(c + px * ca - py * sa, c + px * sa + py * ca) for (px, py) in poly], fill=col)
    d.ellipse([c - S * 0.07, c - S * 0.07, c + S * 0.07, c + S * 0.07], fill=(40, 12, 8, 255))
    for k in range(14):
        a = rng.random() * math.tau
        r = S * rng.uniform(0.02, 0.06)
        d.ellipse([c + math.cos(a) * r - S * 0.008, c + math.sin(a) * r - S * 0.008, c + math.cos(a) * r + S * 0.008, c + math.sin(a) * r + S * 0.008], fill=(255, 200, 60, 255))
    img = img.resize((size, size), Image.LANCZOS)
    a = np.asarray(img).copy()
    a[..., 3] = np.where(a[..., 3] > 110, 255, 0)
    Image.fromarray(a, "RGBA").save(OUT / "fleur_braise.png", optimize=True)


def _tile_noise(rng, n, scales):
    out = np.zeros((n, n), np.float32)
    amp = 1.0
    tot = 0.0
    for s in scales:
        g = rng.normal(0, 1, (s, s)).astype(np.float32)
        im = Image.fromarray(g)
        # répété 3 x 3 puis agrandi : raccordable
        big = np.tile(g, (3, 3))
        bi = Image.fromarray(big).resize((n * 3, n * 3), Image.BICUBIC)
        arr = np.asarray(bi)[n:2 * n, n:2 * n]
        out += arr * amp
        tot += amp
        amp *= 0.55
    out /= tot
    out = (out - out.mean()) / (out.std() + 1e-6)
    return out


def bark(size=512, seed=7083):
    rng = np.random.default_rng(seed)
    n = size
    # des crevasses verticales : un bruit étiré en hauteur, raccordable
    v = _tile_noise(rng, n, (8, 16, 32))
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    stretch = np.zeros((n, n), np.float32)
    g = rng.normal(0, 1, (6, 40)).astype(np.float32)
    big = np.tile(g, (3, 3))
    bi = np.asarray(Image.fromarray(big).resize((n * 3, n * 3), Image.BICUBIC))[n:2 * n, n:2 * n]
    stretch = (bi - bi.mean()) / (bi.std() + 1e-6)
    warp = _tile_noise(rng, n, (4, 8))
    ridges = np.abs(np.sin((xx / n * 14 + stretch * 0.35 + warp * 0.3) * math.pi))
    crack = 1.0 - np.clip(ridges * 3.0, 0, 1)
    h = np.clip(ridges * 0.8 + v * 0.12 + 0.2, 0, 1)
    base = np.stack([np.full((n, n), 0.12), np.full((n, n), 0.1), np.full((n, n), 0.1)], -1)
    col = base * (0.55 + 0.6 * h[..., None])
    # des écailles plus claires (la cendre) sur les crêtes
    ash = np.clip((h - 0.75) * 3.0, 0, 1) * np.clip(v * 0.5 + 0.5, 0, 1)
    col = col * (1 - ash[..., None] * 0.6) + np.array([0.42, 0.4, 0.38]) * ash[..., None] * 0.6
    # le feu au fond des crevasses (par endroits)
    fire_mask = np.clip(_tile_noise(rng, n, (6, 12)) * 0.6 + 0.2, 0, 1)
    fire = np.clip(crack - 0.55, 0, 1) * 2.2 * fire_mask
    col = col * (1 - fire[..., None]) + np.array([0.95, 0.32, 0.06]) * fire[..., None]
    rgb = (np.clip(col, 0, 1) * 255).astype(np.uint8)
    Image.fromarray(rgb, "RGB").save(OUT / "ecorce_braise.png", optimize=True)
    # la normale (depuis h)
    hp = np.pad(h, 1, mode="wrap")
    dx = (hp[1:-1, 2:] - hp[1:-1, :-2]) * 2.5
    dy = (hp[2:, 1:-1] - hp[:-2, 1:-1]) * 2.5
    nz = np.ones_like(dx)
    ln = np.sqrt(dx * dx + dy * dy + nz * nz)
    nrm = np.stack([-dx / ln, dy / ln, nz / ln], -1)
    Image.fromarray(((nrm * 0.5 + 0.5) * 255).astype(np.uint8), "RGB").save(OUT / "ecorce_braise_n.png", optimize=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    leaf_cluster()
    fire_flower()
    bark()
    for nm in ["feuilles_braise.png", "fleur_braise.png", "ecorce_braise.png", "ecorce_braise_n.png"]:
        p = OUT / nm
        print(nm, p.stat().st_size)


if __name__ == "__main__":
    main()
