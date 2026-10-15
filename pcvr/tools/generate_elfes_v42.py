"""V42 : les habitants du Bois-Doré (dessinés ici, libres de droits).

- Quatre textures d'elfes de plus, recolorées comme celle de Lyra à partir de la texture
  du modèle : azur, pourpre, ivoire, crépuscule.
- Icônes des produits du marché : potion de sève, tisane de lune, pain de miel.
Lancement : python3 pcvr/tools/generate_elfes_v42.py (depuis la racine du dépôt).
"""
from pathlib import Path
import math
import sys

from PIL import ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_items_v28 as base  # noqa: E402
import generate_elfes_v41 as v41  # noqa: E402


def potion_seve():
    img = base.canvas()
    d = ImageDraw.Draw(img)
    d.rectangle((222, 60, 290, 150), fill=(190, 225, 215, 150))
    d.rectangle((212, 40, 300, 76), fill=(140, 96, 56, 255))
    base.shaded_ellipse(img, (128, 130, 384, 450), (60, 175, 90))
    d = ImageDraw.Draw(img)
    for k in range(7):
        x = 180 + k * 24
        y = 250 + (k * 37) % 120
        d.ellipse((x, y, x + 14, y + 14), fill=(200, 255, 190, 230))
    d.polygon([(256, 300), (300, 360), (256, 420), (212, 360)], fill=(230, 255, 160, 200))
    d.arc((128, 130, 384, 450), 200, 300, fill=(255, 255, 255, 220), width=10)
    base.save(img, "potion_seve")


def tisane_lune():
    img = base.canvas()
    d = ImageDraw.Draw(img)
    d.ellipse((90, 380, 422, 450), fill=(225, 220, 235, 255))
    base.shaded_ellipse(img, (120, 200, 392, 420), (220, 215, 235))
    d = ImageDraw.Draw(img)
    d.ellipse((136, 196, 376, 246), fill=(170, 150, 210, 255))
    d.ellipse((150, 204, 362, 238), fill=(200, 185, 235, 255))
    d.arc((340, 250, 440, 350), 270, 90, fill=(225, 220, 235, 255), width=22)
    for k in range(3):
        x = 200 + k * 50
        d.arc((x, 90, x + 40, 190), 100, 260, fill=(240, 240, 255, 200), width=8)
    d.ellipse((240, 300, 272, 332), fill=(150, 200, 255, 255))
    base.save(img, "tisane_lune")


def pain_miel():
    img = base.canvas()
    base.shaded_ellipse(img, (70, 170, 442, 420), (205, 140, 60))
    d = ImageDraw.Draw(img)
    for k in range(4):
        x = 130 + k * 70
        d.arc((x, 200, x + 90, 300), 200, 340, fill=(240, 205, 130, 255), width=12)
    for k in range(5):
        a = math.radians(200 + k * 30)
        cx, cy = 256 + math.cos(a) * 120, 260 + math.sin(a) * 50
        d.ellipse((cx - 14, cy - 10, cx + 14, cy + 10), fill=(250, 200, 60, 255))
    d.ellipse((220, 150, 292, 200), fill=(255, 200, 40, 230))
    base.save(img, "pain_miel")


if __name__ == "__main__":
    v41.elf_texture("elfe_azur", (1.0, 0.91, 0.84), (0.18, 0.32, 0.55), (0.86, 0.88, 0.94))
    v41.elf_texture("elfe_pourpre", (0.98, 0.88, 0.8), (0.42, 0.14, 0.24), (0.9, 0.78, 0.5))
    v41.elf_texture("elfe_ivoire", (1.0, 0.92, 0.86), (0.82, 0.76, 0.62), (0.9, 0.82, 0.55))
    v41.elf_texture("elfe_crepuscule", (0.97, 0.88, 0.84), (0.3, 0.24, 0.44), (0.82, 0.84, 0.92))
    potion_seve()
    tisane_lune()
    pain_miel()
