"""V26 : texture de roche de falaise (couleur + relief), calculée ici, libre de droits.

Roche grise fracturée : variations douces de teinte, fissures (cellules de Voronoï),
fines strates horizontales et grain. Répétable sans couture.
Lancement : python3 pcvr/tools/generate_rock_v26.py (depuis la racine du dépôt).
"""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "terrain"
SIZE = 1024
RNG = np.random.default_rng(2604)


def fbm(size, falloff, seed):
    rng = np.random.default_rng(seed)
    fx = np.fft.fftfreq(size)[None, :]
    fy = np.fft.fftfreq(size)[:, None]
    k = np.sqrt(fx * fx + fy * fy)
    k[0, 0] = 1.0
    spec = k ** (-falloff)
    spec[0, 0] = 0.0
    field = np.real(np.fft.ifft2(spec * np.exp(1j * rng.uniform(0, 2 * np.pi, (size, size)))))
    return (field - field.min()) / (field.max() - field.min())


def voronoi_edges(size, cells, seed, warp_x=None, warp_y=None):
    """Distance au bord de cellule la plus proche (F2 - F1), répétable, coordonnées déformées."""
    rng = np.random.default_rng(seed)
    pts = rng.random((cells, 2)) * size
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    if warp_x is not None:
        xx = (xx + warp_x) % size
        yy = (yy + warp_y) % size
    f1 = np.full((size, size), 1e9, np.float32)
    f2 = np.full((size, size), 1e9, np.float32)
    for px, py in pts:
        dx = np.abs(xx - px); dx = np.minimum(dx, size - dx)
        dy = np.abs(yy - py); dy = np.minimum(dy, size - dy)
        d = np.sqrt(dx * dx + dy * dy)
        f2 = np.where(d < f1, f1, np.minimum(f2, d))
        f1 = np.minimum(f1, d)
    return f2 - f1


def normal_from_height(height, strength):
    dx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * 0.5
    dy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) * 0.5
    nx, ny, nz = -dx * strength, -dy * strength, np.ones_like(height)
    length = np.sqrt(nx * nx + ny * ny + nz * nz)
    rgb = np.stack([nx / length, ny / length, nz / length], -1)
    return Image.fromarray(((rgb * 0.5 + 0.5) * 255).clip(0, 255).astype(np.uint8), "RGB")


def main():
    broad = fbm(SIZE, 1.9, 1)
    grain = fbm(SIZE, 1.1, 2)
    mid = fbm(SIZE, 1.5, 5)
    warp_a = (fbm(SIZE, 1.7, 6) - 0.5) * 140.0
    warp_b = (fbm(SIZE, 1.7, 7) - 0.5) * 140.0
    # Fractures irrégulières : cellules déformées, fissures interrompues par le bruit.
    edges = voronoi_edges(SIZE, 14, 3, warp_a, warp_b)
    crack = (1.0 - np.clip(edges / 5.0, 0.0, 1.0)) * np.clip((mid - 0.35) * 3.0, 0.0, 1.0)
    # Surface rugueuse : bruit « crêté » (arêtes vives).
    ridged = 1.0 - np.abs(mid * 2.0 - 1.0)
    rows = np.arange(SIZE)[:, None] / SIZE
    strata = 0.5 + 0.5 * np.sin(rows * np.pi * 2 * 9 + broad * 8.0 + mid * 3.0)
    height = broad * 0.45 + ridged * 0.3 + grain * 0.2 + strata * 0.06 - crack * 0.6
    height = (height - height.min()) / (height.max() - height.min())
    grey = np.array([0.47, 0.46, 0.44])
    warm = np.array([0.55, 0.5, 0.44])
    dark = np.array([0.3, 0.3, 0.3])
    color = grey[None, None, :] * (1 - broad[..., None]) + warm[None, None, :] * broad[..., None]
    blot = np.clip((fbm(SIZE, 1.6, 8) - 0.55) * 4.0, 0.0, 1.0)[..., None]
    color = color * (1 - blot * 0.45) + dark[None, None, :] * blot * 0.45
    lichen = np.clip((fbm(SIZE, 1.3, 9) - 0.7) * 6.0, 0.0, 1.0)[..., None] * 0.35
    color = color * (1 - lichen) + np.array([0.62, 0.6, 0.38])[None, None, :] * lichen
    color *= (0.8 + 0.3 * grain[..., None] + 0.12 * ridged[..., None])
    color *= (1.0 - 0.6 * crack[..., None])
    Image.fromarray((color.clip(0, 1) * 255).astype(np.uint8), "RGB").save(OUT / "rock.jpg", quality=92)
    normal_from_height(height, 12.0).save(OUT / "rock_n.png", optimize=True)
    print("rock")


if __name__ == "__main__":
    main()
