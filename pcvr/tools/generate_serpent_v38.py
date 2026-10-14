"""V38 : icône de l'Amulette du Serpent (dessinée ici, libre de droits).

Lancement : python3 pcvr/tools/generate_serpent_v38.py (depuis la racine du dépôt).
"""
from pathlib import Path
import math
import sys

from PIL import ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_items_v28 as base  # noqa: E402


def amulette_serpent():
    img = base.canvas()
    d = ImageDraw.Draw(img)
    # Cordon de cuir
    d.arc((120, 10, 392, 250), 200, 340, fill=(110, 70, 40, 255), width=12)
    # Disque de jade en volume, avec les trois fêlures dorées des fragments soudés
    base.shaded_ellipse(img, (86, 96, 426, 436), (70, 165, 115))
    d = ImageDraw.Draw(img)
    cx, cy = 256, 266
    for a in (90, 210, 330):
        r = math.radians(a)
        d.line((cx, cy, cx + math.cos(r) * 168, cy - math.sin(r) * 168), fill=(225, 185, 80, 255), width=7)
    # Serpent de bronze enroulé sur le bord
    for i in range(36):
        t = i / 35
        a = math.radians(100 + t * 330)
        rr = 150 - t * 30
        x, y = cx + math.cos(a) * rr, cy - math.sin(a) * rr
        w = 22 - t * 9
        d.ellipse((x - w, y - w, x + w, y + w), fill=(150, 110, 50, 255), outline=(80, 55, 25, 255), width=3)
    # L'œil vert au centre
    d.ellipse((cx - 62, cy - 36, cx + 62, cy + 36), fill=(235, 230, 200, 255), outline=(30, 60, 40, 255), width=8)
    base.shaded_ellipse(img, (cx - 32, cy - 32, cx + 32, cy + 32), (60, 230, 110))
    d = ImageDraw.Draw(img)
    d.ellipse((cx - 8, cy - 26, cx + 8, cy + 26), fill=(10, 30, 15, 255))
    base.save(img, "amulette_serpent")


if __name__ == "__main__":
    amulette_serpent()
