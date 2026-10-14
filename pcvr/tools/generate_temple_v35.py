"""V35 : textures du temple englouti (souterrain sous les deux îles).

- temple_wall.png / temple_wall_n.png : maçonnerie de gros blocs (murs), relief en normal map ;
- temple_floor.png / temple_floor_n.png : grandes dalles (sols) ;
- glyph_lune / glyph_vague / glyph_soleil / glyph_serpent.png : plaques gravées des braseros ;
- fresque.png : la fresque du couloir (les quatre symboles dans l'ordre, chiffres anciens).
Tout part de la texture de pierre du terrain, pour rester dans les mêmes tons.
Lancement depuis la racine du dépôt : python3 pcvr/tools/generate_temple_v35.py
"""
from pathlib import Path
import math

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "www" / "assets" / "textures" / "terrain" / "stone.jpg"
OUT = ROOT / "www" / "assets" / "textures" / "temple"
OUT.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(3535)


def stone_tile(size, blur=7):
    """Pierre taillée procédurale : bruit fractal (grandes taches + grain fin), teinte grès."""
    acc = np.zeros((size, size), dtype=np.float32)
    amp = 1.0
    total = 0.0
    for octave in (8, 16, 32, 64, 128, 256):
        layer = rng.random((octave, octave)).astype(np.float32)
        # Tuile raccordable : on agrandit une mosaïque 3 x 3 et on garde le centre.
        big = Image.fromarray((np.tile(layer, (3, 3)) * 255).astype(np.uint8)).resize((size * 3, size * 3), Image.BICUBIC)
        img = np.asarray(big, dtype=np.float32)[size:size * 2, size:size * 2]
        acc += img / 255.0 * amp
        total += amp
        amp *= 0.55
    acc /= total
    acc = (acc - acc.mean()) * 1.8 + 0.5
    ref = Image.open(SRC).convert("RGB").resize((8, 8)).filter(ImageFilter.GaussianBlur(4))
    tint = np.asarray(ref, dtype=np.float32).reshape(-1, 3).mean(axis=0) / 255.0
    tint = tint / tint.max() * 0.78
    return np.clip(tint[None, None, :] * (0.72 + 0.5 * acc[..., None]), 0, 1)


def normal_from_height(h, strength):
    gy, gx = np.gradient(h)
    n = np.dstack((-gx * strength, -gy * strength, np.ones_like(h)))
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    return Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8), "RGB")


def masonry(name, size, rows, min_w, max_w, groove, tint, seed_shift=0):
    col = stone_tile(size)
    gray = col.mean(axis=2, keepdims=True)
    col = gray * 0.55 + col * 0.45
    height = np.ones((size, size), dtype=np.float32)
    shade = np.ones((size, size, 1), dtype=np.float32)
    row_h = size // rows
    yy, xx = np.mgrid[0:size, 0:size]
    for r in range(rows):
        y0 = r * row_h
        x = int(rng.integers(0, max_w)) - max_w
        while x < size:
            w = int(rng.integers(min_w, max_w))
            x1 = x + w
            # Chaque bloc a sa teinte et un léger bombé ; joints creusés et arêtes émoussées.
            k = 0.82 + rng.random() * 0.3
            for xs in (x, x - size, x + size):
                xa, xb = max(xs, 0), min(xs + w, size)
                if xa >= xb:
                    continue
                shade[y0:y0 + row_h, xa:xb] *= k
                dx = np.minimum(xx[y0:y0 + row_h, xa:xb] - xs, xs + w - xx[y0:y0 + row_h, xa:xb])
                dy = np.minimum(yy[y0:y0 + row_h, xa:xb] - y0, y0 + row_h - yy[y0:y0 + row_h, xa:xb])
                d = np.minimum(dx, dy).astype(np.float32)
                height[y0:y0 + row_h, xa:xb] = np.clip(d / (groove * 2.5), 0, 1) ** 0.6
            x = x1
    small = rng.random((size // 8, size // 8))
    noise = np.asarray(Image.fromarray((np.tile(small, (3, 3)) * 255).astype(np.uint8)).resize((size * 3, size * 3), Image.BICUBIC), dtype=np.float32)[size:size * 2, size:size * 2] / 255.0
    height = height * (0.85 + 0.15 * noise)
    groove_mask = (height < 0.3)[..., None]
    out = col * shade * np.array(tint, dtype=np.float32)
    out = np.where(groove_mask, out * 0.45, out)
    out = out * (0.8 + 0.2 * height[..., None])
    Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGB").save(OUT / f"{name}.png")
    normal_from_height(height + noise * 0.15, 6.0).save(OUT / f"{name}_n.png")
    print(name)


def carve(d, draw_fn, size):
    """Gravure : creux sombre, avec un liseré clair en bas à droite (lumière rasante)."""
    for off, color in (((3, 3), (226, 214, 186, 255)), ((0, 0), (52, 44, 36, 255))):
        draw_fn(d, off, color, size)


def glyph_bg(size):
    col = stone_tile(size)
    gray = col.mean(axis=2, keepdims=True)
    arr = (gray * 0.6 + col * 0.4) * np.array([0.92, 0.86, 0.74])
    img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGB").convert("RGBA")
    d = ImageDraw.Draw(img)
    d.rectangle((10, 10, size - 11, size - 11), outline=(70, 60, 48, 255), width=10)
    d.rectangle((24, 24, size - 25, size - 25), outline=(210, 196, 166, 255), width=3)
    return img


def lune(d, o, c, s):
    ox, oy = o
    # Croissant : bord extérieur (grand cercle) et bord intérieur (cercle décalé).
    outer = [(s * 0.5 + ox + math.cos(a) * s * 0.3, s * 0.5 + oy + math.sin(a) * s * 0.3) for a in np.linspace(math.radians(60), math.radians(300), 40)]
    inner = [(s * 0.62 + ox + math.cos(a) * s * 0.24, s * 0.5 + oy + math.sin(a) * s * 0.24) for a in np.linspace(math.radians(292), math.radians(68), 40)]
    d.line(outer + inner + [outer[0]], fill=c, width=18, joint="curve")


def vague(d, o, c, s):
    ox, oy = o
    for k in range(3):
        y = s * (0.32 + k * 0.17) + oy
        pts = [(s * 0.15 + i * s * 0.035 + ox, y + math.sin(i * 0.55) * s * 0.06) for i in range(21)]
        d.line(pts, fill=c, width=22, joint="curve")


def soleil(d, o, c, s):
    ox, oy = o
    cx, cy = s * 0.5 + ox, s * 0.5 + oy
    d.ellipse((cx - s * 0.16, cy - s * 0.16, cx + s * 0.16, cy + s * 0.16), outline=c, width=24)
    for k in range(8):
        a = k / 8 * math.tau
        d.line((cx + math.cos(a) * s * 0.24, cy + math.sin(a) * s * 0.24, cx + math.cos(a) * s * 0.36, cy + math.sin(a) * s * 0.36), fill=c, width=20)


def serpent(d, o, c, s):
    ox, oy = o
    pts = []
    for i in range(40):
        t = i / 39
        pts.append((s * (0.2 + 0.6 * t) + ox, s * 0.5 + math.sin(t * math.tau * 1.25) * s * 0.18 + oy))
    d.line(pts, fill=c, width=24, joint="curve")
    hx, hy = pts[-1]
    d.ellipse((hx - 30, hy - 26, hx + 30, hy + 26), fill=c)
    d.line((hx + 26, hy, hx + 56, hy - 10), fill=c, width=8)
    d.line((hx + 26, hy, hx + 56, hy + 10), fill=c, width=8)


GLYPHS = {"lune": lune, "vague": vague, "soleil": soleil, "serpent": serpent}


def glyph(name, size=512):
    img = glyph_bg(size)
    d = ImageDraw.Draw(img)
    carve(d, GLYPHS[name], size)
    img = img.filter(ImageFilter.SMOOTH)
    img.save(OUT / f"glyph_{name}.png")
    print("glyph", name)


def numeral(d, n, x, y, c):
    # Chiffres anciens : des traits verticaux, cinq = un trait barré.
    for k in range(n):
        d.line((x + k * 26, y, x + k * 26, y + 70), fill=c, width=12)


def fresque():
    w, h = 2048, 640
    col = stone_tile(1024)
    gray = col.mean(axis=2, keepdims=True)
    arr = (gray * 0.6 + col * 0.4) * np.array([0.88, 0.8, 0.68])
    tile = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGB")
    img = Image.new("RGBA", (w, h))
    for x in range(0, w, 1024):
        img.paste(tile.crop((0, 0, 1024, h)), (x, 0))
    d = ImageDraw.Draw(img)
    d.rectangle((8, 8, w - 9, h - 9), outline=(60, 50, 40, 255), width=14)
    order = ["lune", "vague", "soleil", "serpent"]
    for i, name in enumerate(order):
        x0 = 40 + i * 500
        panel = Image.new("RGBA", (440, 440), (0, 0, 0, 0))
        pd = ImageDraw.Draw(panel)
        carve(pd, GLYPHS[name], 440)
        img.alpha_composite(panel, (x0, 40))
        for off, c in (((3, 3), (226, 214, 186, 255)), ((0, 0), (52, 44, 36, 255))):
            numeral(d, i + 1, x0 + 220 - (i * 13) + off[0], 510 + off[1], c)
        if i < 3:
            for off, c in (((3, 3), (226, 214, 186, 255)), ((0, 0), (52, 44, 36, 255))):
                d.polygon([(x0 + 452 + off[0], 230 + off[1]), (x0 + 488 + off[0], 260 + off[1]), (x0 + 452 + off[0], 290 + off[1])], fill=c)
    img.filter(ImageFilter.SMOOTH).save(OUT / "fresque.png")
    print("fresque")


def fragment_amulette():
    import generate_items_v28 as base
    img = base.canvas()
    d = ImageDraw.Draw(img)
    # Un tiers de disque de jade, cassé net, avec l'œil gravé et un cordon de cuir
    d.pieslice((70, 70, 442, 442), 200, 330, fill=(60, 150, 110, 255))
    d.polygon([(256, 256), (96, 186), (430, 150)], fill=(60, 150, 110, 255))
    d.polygon([(256, 256), (150, 200), (380, 176)], fill=(90, 190, 140, 255))
    d.ellipse((216, 160, 296, 210), outline=(20, 60, 40, 255), width=10)
    d.ellipse((244, 174, 268, 198), fill=(20, 60, 40, 255))
    d.line((256, 256, 256, 330), fill=(20, 60, 40, 255), width=6)
    d.arc((150, 20, 362, 200), 200, 340, fill=(110, 70, 40, 255), width=10)
    base.save(img, "fragment_amulette")


if __name__ == "__main__":
    masonry("temple_wall", 1024, 6, 180, 360, 11, (0.95, 0.9, 0.8))
    masonry("temple_floor", 1024, 4, 220, 300, 9, (0.85, 0.82, 0.76))
    for g in GLYPHS:
        glyph(g)
    fresque()
    import sys
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    fragment_amulette()
