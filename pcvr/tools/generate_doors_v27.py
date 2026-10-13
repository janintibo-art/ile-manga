"""V27 : texture des portes (planches de bois, pentures et anneau en fer), libre de droits.

- door_wood.png   : couleur (planches verticales, veinage, joints, ferrures)
- door_wood_n.png : relief
Lancement : python3 pcvr/tools/generate_doors_v27.py (depuis la racine du dépôt).
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "doors"
OUT.mkdir(parents=True, exist_ok=True)
W, H = 512, 1024
RNG = np.random.default_rng(27)


def grain_field():
    fx = np.fft.fftfreq(W)[None, :]
    fy = np.fft.fftfreq(H)[:, None]
    spec = 1.0 / (1e-4 + (fx * 1.0) ** 2 + (fy * 12.0) ** 2) ** 0.85
    spec[0, 0] = 0
    f = np.real(np.fft.ifft2(spec * np.exp(1j * RNG.uniform(0, 2 * np.pi, (H, W)))))
    return (f - f.min()) / (f.max() - f.min())


def normal_from_height(h, strength):
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5
    nx, ny, nz = -dx * strength, -dy * strength, np.ones_like(h)
    n = np.sqrt(nx * nx + ny * ny + nz * nz)
    rgb = np.stack([nx / n, ny / n, nz / n], -1)
    return Image.fromarray(((rgb * 0.5 + 0.5) * 255).clip(0, 255).astype(np.uint8), "RGB")


def main():
    grain = grain_field()
    planks = 5
    x = np.arange(W)[None, :].repeat(H, 0)
    plank_id = (x * planks) // W
    tone = RNG.uniform(0.85, 1.12, planks)[plank_id]
    base = np.array([0.42, 0.27, 0.15])
    color = base[None, None, :] * (0.72 + 0.5 * grain[..., None]) * tone[..., None]
    height = 0.6 + 0.4 * grain
    # Joints entre planches.
    edge = (x * planks) % W
    gap = (edge < 5) | (edge > W - 5)
    color[gap] *= 0.35
    height[gap] = 0.05
    img = Image.fromarray((color.clip(0, 1) * 255).astype(np.uint8), "RGB")
    hmap = Image.fromarray((height * 255).astype(np.uint8), "L")
    d, dh = ImageDraw.Draw(img), ImageDraw.Draw(hmap)
    # Traverses horizontales en bois plus sombre.
    for y in (int(H * 0.2), int(H * 0.78)):
        d.rectangle([0, y - 26, W, y + 26], fill=(84, 52, 28))
        dh.rectangle([0, y - 26, W, y + 26], fill=230)
    # Pentures (ferrures) côté charnière et clous.
    for y in (int(H * 0.2), int(H * 0.78)):
        d.rectangle([0, y - 14, int(W * 0.72), y + 14], fill=(32, 30, 30))
        dh.rectangle([0, y - 14, int(W * 0.72), y + 14], fill=255)
        d.ellipse([int(W * 0.72) - 22, y - 22, int(W * 0.72) + 22, y + 22], fill=(32, 30, 30))
        for k in range(6):
            cx = 30 + k * int(W * 0.12)
            d.ellipse([cx - 6, y - 6, cx + 6, y + 6], fill=(70, 66, 62))
    # Anneau de tirage côté libre.
    cx, cy = int(W * 0.84), int(H * 0.5)
    d.ellipse([cx - 40, cy - 40, cx + 40, cy + 40], outline=(28, 26, 26), width=11)
    dh.ellipse([cx - 40, cy - 40, cx + 40, cy + 40], outline=255, width=11)
    d.ellipse([cx - 14, cy - 54, cx + 14, cy - 26], fill=(40, 38, 36))
    img.save(OUT / "door_wood.png", optimize=True)
    h = np.asarray(hmap.filter(ImageFilter.GaussianBlur(1.0)), dtype=np.float32) / 255.0
    normal_from_height(h, 6.0).save(OUT / "door_wood_n.png", optimize=True)
    print("door_wood")


def plain_wood():
    """Bois uni (planches sans ferrures) pour les meubles."""
    grain = grain_field()
    planks = 4
    x = np.arange(W)[None, :].repeat(H, 0)
    tone = RNG.uniform(0.85, 1.12, planks)[(x * planks) // W]
    color = np.array([0.46, 0.31, 0.18])[None, None, :] * (0.75 + 0.45 * grain[..., None]) * tone[..., None]
    edge = (x * planks) % W
    gap = (edge < 3) | (edge > W - 3)
    color[gap] *= 0.45
    Image.fromarray((color.clip(0, 1) * 255).astype(np.uint8), "RGB").resize((256, 512)).save(OUT / "wood_plain.png", optimize=True)
    print("wood_plain")


def plaster(size=512):
    """Enduit à la chaux : crème, légèrement taché, très fin relief."""
    fx = np.fft.fftfreq(size)[None, :]
    fy = np.fft.fftfreq(size)[:, None]
    k = np.sqrt(fx * fx + fy * fy); k[0, 0] = 1
    def field(falloff, seed):
        r = np.random.default_rng(seed)
        s = k ** (-falloff); s[0, 0] = 0
        f = np.real(np.fft.ifft2(s * np.exp(1j * r.uniform(0, 2 * np.pi, (size, size)))))
        return (f - f.min()) / (f.max() - f.min())
    broad, fine = field(2.0, 31), field(1.0, 32)
    color = np.array([0.86, 0.8, 0.68])[None, None, :] * (0.9 + 0.12 * broad[..., None] + 0.05 * fine[..., None])
    Image.fromarray((color.clip(0, 1) * 255).astype(np.uint8), "RGB").save(OUT / "plaster.png", optimize=True)
    normal_from_height(broad * 0.3 + fine * 0.7, 3.0).save(OUT / "plaster_n.png", optimize=True)
    print("plaster")


if __name__ == "__main__":
    main()
    plain_wood()
    plaster()
