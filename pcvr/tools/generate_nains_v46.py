"""V46 : textures de l'île des nains (la Montagne de Feu) et icône de la carte.

Textures recolorées à partir de celles du terrain du jeu (mêmes reliefs) :
sable noir volcanique, cendre, herbe brûlée, basalte. Icône : carte des Récifs de Feu.
Lancement : python3 pcvr/tools/generate_nains_v46.py (depuis la racine du dépôt).
"""
from pathlib import Path
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_items_v28 as base  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "www" / "assets" / "textures" / "terrain"
OUT = ROOT / "www" / "assets" / "textures" / "volcan"
OUT.mkdir(parents=True, exist_ok=True)


def recolor(src, name, tint, contrast=1.0, lift=0.0, size=1024):
    img = Image.open(SRC / src).convert("RGB").resize((size, size), Image.LANCZOS)
    a = np.asarray(img).astype(np.float32) / 255.0
    lum = (0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2])[..., None]
    lum = np.clip((lum - 0.5) * contrast + 0.5 + lift, 0, 1)
    out = np.clip(lum * np.array(tint)[None, None, :], 0, 1)
    Image.fromarray((out * 255).astype(np.uint8)).save(OUT / f"{name}.png", optimize=True)
    print(name)


def carte():
    img = base.canvas()
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((60, 90, 452, 420), radius=18, fill=(214, 190, 140, 255))
    for k in range(6):
        d.line((70, 120 + k * 52, 440, 112 + k * 52), fill=(190, 165, 120, 255), width=3)
    # l'île et son volcan
    d.ellipse((150, 160, 330, 340), fill=(110, 95, 85, 255))
    d.polygon([(240, 175), (280, 300), (200, 300)], fill=(80, 70, 65, 255))
    d.ellipse((228, 172, 252, 186), fill=(240, 110, 30, 255))
    # récifs et la passe en pointillés
    for k in range(14):
        a = math.radians(k * 25)
        x, y = 240 + math.cos(a) * 140, 250 + math.sin(a) * 120
        if abs(((k * 25) % 360) - 20) < 25:
            continue
        d.polygon([(x - 8, y + 6), (x, y - 10), (x + 8, y + 6)], fill=(60, 50, 50, 255))
    for k in range(7):
        d.ellipse((330 + k * 14, 255 - k * 6, 338 + k * 14, 263 - k * 6), fill=(170, 30, 30, 255))
    d.line((400, 200, 425, 225), fill=(170, 30, 30, 255), width=6)
    d.line((425, 200, 400, 225), fill=(170, 30, 30, 255), width=6)
    base.save(img, "carte_naine")


if __name__ == "__main__":
    recolor("sand.jpg", "sable_noir", (0.32, 0.3, 0.32), 1.3, -0.12)
    recolor("sand.jpg", "cendre", (0.36, 0.33, 0.31), 1.15, -0.06)
    recolor("grass.jpg", "herbe_brulee", (0.62, 0.55, 0.32), 1.2, -0.05)
    recolor("rock.jpg", "basalte", (0.42, 0.42, 0.46), 1.35, -0.1)
    carte()
