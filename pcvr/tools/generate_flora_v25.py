"""V25 : textures de végétation calculées ici (libres de droits).

- leaves.png / leaves_n.png : grappe de feuilles détourée (canal alpha) + relief.
- bark.png / bark_n.png     : écorce fibreuse répétable.
- flowers.png               : touffe de fleurs (pétales clairs, teintés en jeu) + tiges.
- fern.png                  : fronde de fougère détourée.
Lancement : python3 pcvr/tools/generate_flora_v25.py (depuis la racine du dépôt).
"""
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "flora"
OUT.mkdir(parents=True, exist_ok=True)
RNG = np.random.default_rng(2510)


def normal_from_height(height: np.ndarray, strength: float) -> Image.Image:
    dx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) * 0.5
    dy = (np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)) * 0.5
    nx, ny, nz = -dx * strength, -dy * strength, np.ones_like(height)
    length = np.sqrt(nx * nx + ny * ny + nz * nz)
    rgb = np.stack([nx / length, ny / length, nz / length], axis=-1)
    return Image.fromarray(((rgb * 0.5 + 0.5) * 255).clip(0, 255).astype(np.uint8), "RGB")


def leaf_polygon(cx, cy, length, width, angle, steps=14):
    """Feuille en amande : bords courbes, pointe effilée."""
    pts = []
    for side in (1, -1):
        rng = range(steps + 1) if side == 1 else range(steps, -1, -1)
        for i in rng:
            t = i / steps
            w = math.sin(math.pi * t) ** 0.8 * (1.0 - 0.35 * t) * width * 0.5 * side
            x, y = t * length - length * 0.15, w
            pts.append((cx + x * math.cos(angle) - y * math.sin(angle), cy + x * math.sin(angle) + y * math.cos(angle)))
    return pts


def leaves(size=1024, ss=2):
    S = size * ss
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    height = Image.new("L", (S, S), 0)
    d, dh = ImageDraw.Draw(img), ImageDraw.Draw(height)
    # Petites branches au cœur de la grappe, dessinées sous les feuilles.
    for _ in range(9):
        a = RNG.random() * math.tau
        d.line([(S / 2, S / 2), (S / 2 + math.cos(a) * S * 0.3, S / 2 + math.sin(a) * S * 0.3)], fill=(70, 52, 36, 255), width=ss * 5)
    count = 230
    for k in range(count):
        depth = k / count  # les dernières feuilles sont devant : plus claires
        r = math.sqrt(RNG.random()) * S * 0.36
        a = RNG.random() * math.tau
        cx, cy = S / 2 + math.cos(a) * r, S / 2 + math.sin(a) * r * 0.92
        length = S * RNG.uniform(0.09, 0.15)
        width = length * RNG.uniform(0.38, 0.5)
        angle = a + RNG.uniform(-0.9, 0.9)
        base = np.array([RNG.uniform(0.16, 0.3), RNG.uniform(0.36, 0.52), RNG.uniform(0.1, 0.2)])
        base *= 0.62 + 0.5 * depth
        col = tuple(int(c * 255) for c in base.clip(0, 1)) + (255,)
        poly = leaf_polygon(cx, cy, length, width, angle)
        d.polygon(poly, fill=col)
        dh.polygon(poly, fill=int(90 + 150 * depth))
        # Nervure centrale, plus sombre.
        tip = (cx + math.cos(angle) * length * 0.8, cy + math.sin(angle) * length * 0.8)
        root = (cx - math.cos(angle) * length * 0.12, cy - math.sin(angle) * length * 0.12)
        vein = tuple(int(c * 0.72) for c in col[:3]) + (255,)
        d.line([root, tip], fill=vein, width=max(2, ss * 2))
    img = img.resize((size, size), Image.LANCZOS)
    h = np.asarray(height.resize((size, size), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.2)), dtype=np.float32) / 255.0
    # Bords alpha nets pour le seuil de découpe (alpha scissor).
    arr = np.asarray(img).copy()
    arr[..., 3] = np.where(arr[..., 3] > 110, 255, 0)
    # On étend la couleur sous les pixels transparents : pas de liseré sombre en lointain.
    rgb = Image.fromarray(arr[..., :3]).filter(ImageFilter.MaxFilter(5))
    arr[..., :3] = np.where(arr[..., 3:4] > 0, arr[..., :3], np.asarray(rgb))
    Image.fromarray(arr, "RGBA").save(OUT / "leaves.png", optimize=True)
    normal_from_height(h, 9.0).save(OUT / "leaves_n.png", optimize=True)
    print("leaves")


def bark(size=512):
    # Bruit étiré verticalement : fibres et crevasses de l'écorce, répétable.
    fx = np.fft.fftfreq(size)[None, :]
    fy = np.fft.fftfreq(size)[:, None]
    spectrum = 1.0 / (1e-4 + (fx * 1.0) ** 2 + (fy * 7.0) ** 2) ** 0.9
    spectrum[0, 0] = 0
    field = np.real(np.fft.ifft2(spectrum * np.exp(1j * RNG.uniform(0, math.tau, (size, size)))))
    field = (field - field.min()) / (field.max() - field.min())
    cracks = np.clip((field - 0.42) * 3.0, 0, 1)
    colors = np.stack([0.24 + 0.2 * cracks, 0.18 + 0.15 * cracks, 0.13 + 0.11 * cracks], axis=-1)
    colors *= 0.85 + 0.3 * field[..., None]
    Image.fromarray((colors.clip(0, 1) * 255).astype(np.uint8), "RGB").save(OUT / "bark.png", optimize=True)
    normal_from_height(field, 14.0).save(OUT / "bark_n.png", optimize=True)
    print("bark")


def flowers(size=512, ss=2):
    S = size * ss
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    heads = []
    for _ in range(7):
        bx = S * RNG.uniform(0.3, 0.7)
        hx, hy = bx + S * RNG.uniform(-0.18, 0.18), S * RNG.uniform(0.12, 0.45)
        d.line([(bx, S), ((bx + hx) / 2, (S + hy) / 2 + S * 0.05), (hx, hy)], fill=(58, 104, 42, 255), width=ss * 5)
        heads.append((hx, hy))
    for _ in range(14):  # feuilles à la base
        a = -math.pi / 2 + RNG.uniform(-1.1, 1.1)
        cx, cy = S * RNG.uniform(0.32, 0.68), S * RNG.uniform(0.82, 0.98)
        poly = leaf_polygon(cx, cy, S * RNG.uniform(0.18, 0.3), S * 0.06, a)
        g = RNG.uniform(0.75, 1.1)
        d.polygon(poly, fill=(int(54 * g), int(110 * g), int(40 * g), 255))
    for hx, hy in heads:
        r = S * RNG.uniform(0.07, 0.1)
        petals = int(RNG.integers(6, 10))
        rot = RNG.random() * math.tau
        for p in range(petals):
            a = rot + p * math.tau / petals
            poly = leaf_polygon(hx, hy, r * 1.15, r * 0.55, a)
            shade = int(RNG.uniform(225, 250))
            d.polygon(poly, fill=(shade, shade, shade, 255))
        d.ellipse([hx - r * 0.28, hy - r * 0.28, hx + r * 0.28, hy + r * 0.28], fill=(232, 176, 44, 255))
    img = img.resize((size, size), Image.LANCZOS)
    arr = np.asarray(img).copy()
    arr[..., 3] = np.where(arr[..., 3] > 110, 255, 0)
    rgb = Image.fromarray(arr[..., :3]).filter(ImageFilter.MaxFilter(5))
    arr[..., :3] = np.where(arr[..., 3:4] > 0, arr[..., :3], np.asarray(rgb))
    Image.fromarray(arr, "RGBA").save(OUT / "flowers.png", optimize=True)
    print("flowers")


def fern(size=512, ss=2):
    S = size * ss
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pts = [(S * 0.5 + S * 0.08 * math.sin(t * 2.2) * t, S * (0.98 - 0.9 * t)) for t in np.linspace(0, 1, 40)]
    d.line(pts, fill=(64, 92, 38, 255), width=ss * 4)
    for i, (x, y) in enumerate(pts[2:-1:2]):
        i *= 2
        t = i / len(pts)
        length = S * 0.26 * (1.0 - t) ** 0.7 + S * 0.02
        for side in (1, -1):
            ang = -0.45 if side == 1 else math.pi + 0.45  # folioles inclinées vers le haut
            g = 0.85 + 0.25 * RNG.random()
            d.polygon(leaf_polygon(x, y, length, length * 0.3, ang), fill=(int(48 * g), int(112 * g), int(36 * g), 255))
    img = img.resize((size, size), Image.LANCZOS)
    arr = np.asarray(img).copy()
    arr[..., 3] = np.where(arr[..., 3] > 110, 255, 0)
    rgb = Image.fromarray(arr[..., :3]).filter(ImageFilter.MaxFilter(5))
    arr[..., :3] = np.where(arr[..., 3:4] > 0, arr[..., :3], np.asarray(rgb))
    Image.fromarray(arr, "RGBA").save(OUT / "fern.png", optimize=True)
    print("fern")


if __name__ == "__main__":
    leaves()
    bark()
    flowers()
    fern()
