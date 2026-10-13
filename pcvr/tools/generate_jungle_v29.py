"""V29 : textures du sol de l'île-jungle (libres de droits, générées ici).

- jungle_soil   : humus sombre couvert de feuilles mortes (sous-bois)
- jungle_moss   : mousse épaisse, touffes et creux
- jungle_rock   : calcaire sombre et humide, strates, fissures, coulures vertes
Chaque texture a sa carte de relief (_n). Lancement depuis la racine du dépôt :
python3 pcvr/tools/generate_jungle_v29.py
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "jungle"
OUT.mkdir(parents=True, exist_ok=True)
N = 1024
RNG = np.random.default_rng(29)


def field(falloff, seed, aniso=(1.0, 1.0)):
    """Bruit spectral périodique (raccord parfait), normalisé 0..1."""
    r = np.random.default_rng(seed)
    fx = np.fft.fftfreq(N)[None, :] * aniso[0]
    fy = np.fft.fftfreq(N)[:, None] * aniso[1]
    k = np.sqrt(fx * fx + fy * fy)
    k[0, 0] = 1.0
    spec = k ** (-falloff)
    spec[0, 0] = 0.0
    f = np.real(np.fft.ifft2(spec * np.exp(1j * r.uniform(0, 2 * np.pi, (N, N)))))
    return (f - f.min()) / (f.max() - f.min())


def normal_map(h, strength):
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * strength
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5 * strength
    n = np.stack([-dx, -dy, np.ones_like(h)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8), "RGB")


def save(name, color, height, strength):
    Image.fromarray((np.clip(color, 0, 1) * 255).astype(np.uint8), "RGB").save(OUT / f"{name}.png", optimize=True)
    normal_map(height, strength).save(OUT / f"{name}_n.png", optimize=True)
    print(name)


def wrap_paste(canvas, stamp, x, y):
    """Colle une forme RGBA en raccordant les bords (texture répétable)."""
    w, h = stamp.size
    for ox in (-N, 0, N):
        for oy in (-N, 0, N):
            px, py = x + ox, y + oy
            if px + w > 0 and py + h > 0 and px < N and py < N:
                canvas.paste(stamp, (px, py), stamp)


def soil():
    base = field(1.6, 1)
    fine = field(0.9, 2)
    col = np.array([0.20, 0.13, 0.08])[None, None, :] * (0.7 + 0.5 * base[..., None] + 0.25 * fine[..., None])
    img = Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB").convert("RGBA")
    hmap = Image.fromarray((base * 0.5 * 255).astype(np.uint8), "L")
    hd = ImageDraw.Draw(hmap)
    palette = [(120, 70, 30), (150, 92, 40), (98, 60, 28), (170, 120, 60), (80, 66, 34), (132, 104, 52)]
    for _ in range(2600):
        L = int(RNG.uniform(14, 46))
        W = int(L * RNG.uniform(0.35, 0.55))
        leaf = Image.new("RGBA", (L + 4, L + 4), (0, 0, 0, 0))
        d = ImageDraw.Draw(leaf)
        c = palette[RNG.integers(len(palette))]
        shade = RNG.uniform(0.7, 1.15)
        c = tuple(int(min(255, v * shade)) for v in c) + (255,)
        cx = (L + 4) // 2
        d.ellipse((cx - W // 2, 2, cx + W // 2, L + 2), fill=c)
        d.line((cx, 3, cx, L + 1), fill=tuple(int(v * 0.7) for v in c[:3]) + (255,), width=1)
        leaf = leaf.rotate(RNG.uniform(0, 360), expand=True, resample=Image.BICUBIC)
        x, y = int(RNG.uniform(0, N)), int(RNG.uniform(0, N))
        wrap_paste(img, leaf, x, y)
        hl = Image.new("L", leaf.size, 0)
        hl.paste(int(RNG.uniform(150, 230)), (0, 0), leaf.split()[3])
        for ox in (-N, 0, N):
            for oy in (-N, 0, N):
                hmap.paste(hl, (x + ox, y + oy), leaf.split()[3])
    # Brindilles.
    d2 = ImageDraw.Draw(img)
    for _ in range(260):
        x, y = RNG.uniform(0, N, 2)
        a = RNG.uniform(0, np.pi)
        L = RNG.uniform(20, 70)
        d2.line((x, y, x + np.cos(a) * L, y + np.sin(a) * L), fill=(70, 48, 28, 255), width=2)
    color = np.asarray(img.convert("RGB"), dtype=np.float32) / 255.0
    color *= (0.82 + 0.3 * field(2.2, 3))[..., None]
    h = np.asarray(hmap.filter(ImageFilter.GaussianBlur(1.2)), dtype=np.float32) / 255.0
    save("jungle_soil", color, h, 5.0)


def moss():
    clumps = field(1.3, 11)
    mid = field(0.9, 12)
    # Petites touffes serrées : points clairs au sommet, creux sombres autour.
    speck = RNG.random((N, N)).astype(np.float32)
    speck = np.asarray(Image.fromarray((speck * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.1)), dtype=np.float32) / 255.0
    speck = np.clip((speck - 0.5) * 6.0 + 0.5, 0, 1)
    h = np.clip(clumps * 0.45 + mid * 0.2 + speck * 0.45, 0, 1)
    dark = np.array([0.05, 0.13, 0.04])
    lush = np.array([0.22, 0.40, 0.09])
    tip = np.array([0.46, 0.58, 0.16])
    t = np.clip((h - 0.2) / 0.65, 0, 1)[..., None]
    color = dark * (1 - t) + lush * t
    color = color + (tip - lush) * (speck[..., None] > 0.85) * 0.35 * clumps[..., None]
    y = np.clip((field(2.0, 14) - 0.62) * 3.5, 0, 1)[..., None]
    color = color * (1 - y * 0.4) + np.array([0.40, 0.44, 0.14]) * y * 0.4
    save("jungle_moss", color, h, 9.0)


def rock():
    warp = field(2.0, 21)
    yy = np.arange(N)[:, None].repeat(N, 1).astype(np.float32) / N
    # Strates de calcaire légèrement ondulées, d'épaisseurs inégales.
    phase = yy * 2 * np.pi * 7 + warp * 5.0
    strata = 0.5 + 0.5 * np.sin(phase) + 0.25 * np.sin(phase * 2.7 + 1.0)
    grain = field(0.7, 22)
    big = field(2.2, 23)
    cracks = np.zeros((N, N), np.float32)
    for s in (24, 25):
        f = field(2.3, s)
        cracks = np.maximum(cracks, np.exp(-((f - 0.5) * 150.0) ** 2))
    pits = np.clip((field(0.5, 26) - 0.78) * 6.0, 0, 1)
    blotch = field(1.1, 28)
    h = np.clip(strata * 0.25 + grain * 0.3 + big * 0.25 + blotch * 0.3 - cracks * 0.5 - pits * 0.3, 0, 1)
    light = np.array([0.52, 0.50, 0.44])
    darkc = np.array([0.20, 0.21, 0.19])
    color = darkc + (light - darkc) * np.clip(0.1 + 1.1 * (h * 0.6 + blotch * 0.4) - 0.2, 0, 1)[..., None]
    lichen = np.clip((field(0.9, 29) - 0.7) * 5.0, 0, 1)[..., None]
    color = color * (1 - lichen * 0.35) + np.array([0.62, 0.62, 0.5]) * lichen * 0.35
    streak = field(1.6, 27, aniso=(1.0, 0.1))
    green = np.clip((streak - 0.58) * 3.0, 0, 1)[..., None] * (0.6 + 0.4 * strata[..., None])
    color = color * (1 - green * 0.55) + np.array([0.10, 0.19, 0.07]) * green * 0.55
    color *= (1.0 - cracks[..., None] * 0.45)
    save("jungle_rock", color, h, 7.0)


if __name__ == "__main__":
    soil()
    moss()
    rock()
