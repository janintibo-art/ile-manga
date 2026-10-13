"""V30 : textures de la végétation de la jungle (libres de droits, dessinées ici).

- palm_frond      : palme de cocotier (nervure centrale, folioles fines), détourée
- broadleaf       : grande feuille de bananier (nervures parallèles, déchirures), détourée
- canopy_leaves   : grappe de feuilles tropicales luisantes à pointe effilée, détourée (+ _n)
- palm_trunk      : stipe de cocotier (anneaux), répétable
Lancement depuis la racine du dépôt : python3 pcvr/tools/generate_jungle_flora_v30.py
"""
from pathlib import Path
import math

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "jungle"
OUT.mkdir(parents=True, exist_ok=True)
RNG = np.random.default_rng(30)


def jitter(c, amount=0.12):
    f = 1.0 + RNG.uniform(-amount, amount)
    return tuple(int(max(0, min(255, v * f))) for v in c[:3]) + ((c[3],) if len(c) > 3 else (255,))


def lerp_c(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)


def normal_from_alpha_luma(img, strength=3.0):
    a = np.asarray(img, dtype=np.float32) / 255.0
    h = (a[..., 0] * 0.3 + a[..., 1] * 0.6 + a[..., 2] * 0.1) * a[..., 3]
    h = np.asarray(Image.fromarray((h * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.5)), dtype=np.float32) / 255.0
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * strength
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * strength
    n = np.stack([-dx, -dy, np.ones_like(h)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8), "RGB")


def finish(img, name, size):
    # Bords de la découpe : on étend la couleur sous l'alpha pour éviter les liserés au mipmap.
    rgb = img.convert("RGB")
    a = img.split()[3]
    grown = rgb.filter(ImageFilter.MaxFilter(9))
    base = Image.composite(rgb, grown, a.point(lambda v: 255 if v > 8 else 0))
    out = base.convert("RGBA")
    out.putalpha(a)
    out = out.resize(size, Image.LANCZOS)
    out.save(OUT / f"{name}.png", optimize=True)
    print(name)
    return out


def palm_frond():
    W, H = 512, 2048
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = W // 2
    dark = (40, 86, 24)
    light = (110, 146, 46)
    n = 58
    for side in (-1, 1):
        for i in range(n):
            t = (i + 0.5) / n                       # 0 = base (en bas), 1 = pointe (en haut)
            y = H - 60 - t * (H - 140)
            length = (W * 0.47) * math.sin(math.pi * (0.12 + 0.88 * t)) ** 0.7 * RNG.uniform(0.88, 1.05)
            ang = math.radians(32 + 20 * t + RNG.uniform(-4, 4))
            tipx = cx + side * math.sin(ang) * length
            tipy = y - math.cos(ang) * length
            wdt = 34 * (1.0 - 0.45 * t)
            col = jitter(lerp_c(dark, light, 0.25 + 0.5 * RNG.random()))
            pts = []
            steps = 10
            for k in range(steps + 1):
                u = k / steps
                px = cx + (tipx - cx) * u
                py = y + (tipy - y) * u + math.sin(u * math.pi) * 18
                w = wdt * math.sin(math.pi * min(1.0, u * 1.15 + 0.05)) ** 0.6
                pts.append((px, py, w))
            poly = [(p[0], p[1] - p[2] / 2) for p in pts] + [(p[0], p[1] + p[2] / 2) for p in reversed(pts)]
            d.polygon(poly, fill=col)
            d.line([(p[0], p[1]) for p in pts], fill=lerp_c(col, (200, 210, 120), 0.35), width=2)
    d.line([(cx, H - 10), (cx, 40)], fill=(150, 150, 80, 255), width=12)
    return finish(img, "palm_frond", (256, 1024))


def broadleaf():
    W, H = 1024, 2048
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = W / 2
    top, bot = 70, H - 40
    pts_l, pts_r = [], []
    for k in range(121):
        t = k / 120
        y = bot - t * (bot - top)
        w = (W * 0.46) * (math.sin(math.pi * t) ** 0.55) * (1.0 - 0.15 * t)
        pts_l.append((cx - w, y))
        pts_r.append((cx + w, y))
    d.polygon(pts_l + list(reversed(pts_r)), fill=(58, 112, 36, 255))
    leaf_mask = img.split()[3].copy()
    # Dégradé de couleur et nervures latérales parallèles.
    arr = np.asarray(img, dtype=np.float32)
    yy, xx = np.mgrid[0:H, 0:W]
    shade = 0.82 + 0.25 * np.abs((xx - cx) / (W * 0.5))
    var = np.asarray(Image.fromarray((RNG.random((H // 32, W // 32)) * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC), dtype=np.float32) / 255.0
    arr[..., :3] *= (shade * (0.9 + 0.2 * var))[..., None]
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(img)
    for k in range(70):
        t = (k + 0.5) / 70
        y = bot - 30 - t * (bot - top - 60)
        for side in (-1, 1):
            d.line([(cx, y), (cx + side * W * 0.48, y - W * 0.28)], fill=(46, 92, 30, 255), width=2)
    d.line([(cx, bot), (cx, top + 20)], fill=(170, 186, 110, 255), width=22)
    # Déchirures du limbe (le vent fend les feuilles de bananier le long des nervures).
    a = leaf_mask
    ad = ImageDraw.Draw(a)
    for _ in range(10):
        t = RNG.uniform(0.12, 0.88)
        y = bot - t * (bot - top)
        side = RNG.choice([-1, 1])
        depth = RNG.uniform(0.3, 0.85)
        x0 = cx + side * W * 0.52
        y0 = y - W * 0.29
        x1 = cx + side * W * 0.5 * (1 - depth)
        y1 = y - W * 0.28 * (1 - depth)
        ad.polygon([(x0, y0 - 10), (x0, y0 + 10), (x1, y1)], fill=0)
    img.putalpha(a)
    return finish(img, "broadleaf", (512, 1024))


def canopy_leaves():
    S = 1024
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    palette = [(26, 62, 20), (40, 84, 26), (58, 102, 30), (30, 70, 34), (72, 110, 40)]
    for _ in range(260):
        L = RNG.uniform(90, 170)
        Wd = L * RNG.uniform(0.32, 0.42)
        leaf = Image.new("RGBA", (int(L) + 40, int(L) + 40), (0, 0, 0, 0))
        ld = ImageDraw.Draw(leaf)
        c = (int(L) + 40) / 2
        pts = []
        for k in range(41):
            t = k / 40
            y = c + L / 2 - t * L
            w = Wd / 2 * math.sin(math.pi * t) ** 0.8 * (1.0 if t < 0.8 else (1.0 - (t - 0.8) * 3.5))
            pts.append((c + max(w, 0), y))
        poly = pts + [(2 * c - p[0], p[1]) for p in reversed(pts)]
        col = jitter(palette[RNG.integers(len(palette))], 0.18)
        ld.polygon(poly, fill=col)
        ld.line([(c, c + L / 2), (c, c - L / 2)], fill=lerp_c(col, (150, 170, 90), 0.4), width=3)
        # Reflet luisant sur une moitié.
        hl = Image.new("RGBA", leaf.size, (0, 0, 0, 0))
        hd = ImageDraw.Draw(hl)
        hd.polygon(pts + [(c, p[1]) for p in reversed(pts)], fill=(255, 255, 230, 26))
        leaf = Image.alpha_composite(leaf, Image.composite(hl, Image.new("RGBA", leaf.size), leaf.split()[3]))
        leaf = leaf.rotate(RNG.uniform(0, 360), expand=True, resample=Image.BICUBIC)
        r = S * 0.42 * math.sqrt(RNG.random())
        a = RNG.uniform(0, 2 * math.pi)
        x = int(S / 2 + math.cos(a) * r - leaf.size[0] / 2)
        y = int(S / 2 + math.sin(a) * r - leaf.size[1] / 2)
        img.alpha_composite(leaf, (max(0, min(S - leaf.size[0], x)), max(0, min(S - leaf.size[1], y))))
    out = finish(img, "canopy_leaves", (512, 512))
    normal_from_alpha_luma(out, 4.0).save(OUT / "canopy_leaves_n.png", optimize=True)


def palm_trunk():
    W, H = 256, 512
    yy = np.arange(H)[:, None].repeat(W, 1).astype(np.float32)
    xx = np.arange(W)[None, :].repeat(H, 0).astype(np.float32)
    rings = 0.5 + 0.5 * np.cos(yy / H * 2 * np.pi * 12 + np.sin(xx / W * 2 * np.pi) * 0.6)
    ring_line = np.exp(-((rings - 1.0) * 9.0) ** 2)
    fib = np.asarray(Image.fromarray((RNG.random((H, W)) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8)).resize((W, H)), dtype=np.float32) / 255.0
    base = np.array([0.66, 0.6, 0.5])
    col = base[None, None, :] * (0.75 + 0.3 * fib[..., None]) * (1.0 - 0.45 * ring_line[..., None])
    Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB").save(OUT / "palm_trunk.png", optimize=True)
    print("palm_trunk")


if __name__ == "__main__":
    palm_frond()
    broadleaf()
    canopy_leaves()
    palm_trunk()
