"""V24 : génère les cartes de relief (normal maps) du sol et de l'eau.

Aucune image téléchargée : tout est calculé ici, donc libre de droits.
- grass_n / sand_n / stone_n : relief tiré de la luminosité des textures existantes.
- water_n : vaguelettes répétables sans couture (bruit spectral).
Lancement : python3 pcvr/tools/generate_textures_v24.py (depuis la racine du dépôt).
"""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
TERRAIN = ROOT / "www" / "assets" / "textures" / "terrain"
WATER = ROOT / "www" / "assets" / "textures" / "water"


def normal_from_height(height: np.ndarray, strength: float) -> Image.Image:
    # Différences centrées avec bouclage : la texture reste sans couture.
    dx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) * 0.5
    dy = (np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)) * 0.5
    nx = -dx * strength
    ny = -dy * strength
    nz = np.ones_like(height)
    length = np.sqrt(nx * nx + ny * ny + nz * nz)
    rgb = np.stack([nx / length, ny / length, nz / length], axis=-1)
    return Image.fromarray(((rgb * 0.5 + 0.5) * 255.0).clip(0, 255).astype(np.uint8), "RGB")


def blur_wrap(img: np.ndarray, passes: int) -> np.ndarray:
    for _ in range(passes):
        img = (img + np.roll(img, 1, 0) + np.roll(img, -1, 0) + np.roll(img, 1, 1) + np.roll(img, -1, 1)) / 5.0
    return img


def terrain_normals() -> None:
    for name, strength, smooth in (("grass", 5.0, 1), ("sand", 3.0, 2), ("stone", 7.0, 1)):
        albedo = np.asarray(Image.open(TERRAIN / f"{name}.jpg").convert("RGB"), dtype=np.float32) / 255.0
        luma = albedo @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
        height = blur_wrap(luma, smooth)
        normal_from_height(height, strength).save(TERRAIN / f"{name}_n.png", optimize=True)
        print("normal map:", name)


def water_normals(size: int = 1024, seed: int = 24) -> None:
    rng = np.random.default_rng(seed)
    fx = np.fft.fftfreq(size)[None, :]
    fy = np.fft.fftfreq(size)[:, None]
    k = np.sqrt(fx * fx + fy * fy) + 1e-6
    # Spectre de vagues : énergie surtout dans les moyennes fréquences, un peu étirée.
    spectrum = np.exp(-((k - 0.012) ** 2) / 0.00008) + 0.12 * np.exp(-((k - 0.032) ** 2) / 0.00025)
    spectrum *= 1.0 + 0.6 * (fx / k) ** 2
    phase = rng.uniform(0.0, 2.0 * np.pi, (size, size))
    field = np.real(np.fft.ifft2(spectrum * np.exp(1j * phase)))
    field = (field - field.min()) / (field.max() - field.min())
    normal_from_height(field, 30.0).save(WATER / "water_n.png", optimize=True)
    print("normal map: water")


if __name__ == "__main__":
    terrain_normals()
    water_normals()
