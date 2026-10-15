"""V44 : icônes du Village des Fées (dessinées ici, libres de droits).

goutte_rosee, baguette_fee, eclat_cristal, nectar_fee.
Lancement : python3 pcvr/tools/generate_feerique_v44.py (depuis la racine du dépôt).
"""
from pathlib import Path
import math
import sys

from PIL import ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_items_v28 as base  # noqa: E402
import generate_feerique_v43 as v43  # noqa: E402


def goutte_rosee():
    img = base.canvas()
    lay = base.canvas()
    base.shaded_ellipse(lay, (150, 190, 362, 430), (190, 235, 255))
    d = ImageDraw.Draw(lay)
    d.polygon([(256, 70), (165, 260), (347, 260)], fill=(190, 235, 255, 255))
    img.alpha_composite(lay)
    d = ImageDraw.Draw(img)
    d.ellipse((200, 250, 250, 300), fill=(255, 255, 255, 230))
    d.ellipse((290, 340, 312, 362), fill=(255, 255, 255, 180))
    base.save(v43.glow(img, (180, 230, 255), 18, 2), "goutte_rosee")


def baguette_fee():
    img = base.canvas()
    d = ImageDraw.Draw(img)
    base.stick_polygon(d, (130, 440), (300, 170), 22, (190, 150, 100, 255))
    pts = []
    for k in range(10):
        a = math.radians(-90 + k * 36)
        r = 85 if k % 2 == 0 else 36
        pts.append((330 + math.cos(a) * r, 140 + math.sin(a) * r))
    d.polygon(pts, fill=(255, 235, 150, 255))
    d.ellipse((315, 125, 345, 155), fill=(255, 255, 230, 255))
    base.save(v43.glow(img, (255, 230, 150), 16, 2), "baguette_fee")


def eclat_cristal():
    img = base.canvas()
    d = ImageDraw.Draw(img)
    d.polygon([(256, 60), (350, 230), (300, 450), (200, 440), (160, 220)], fill=(225, 140, 230, 255))
    d.polygon([(256, 60), (300, 450), (200, 440)], fill=(245, 190, 250, 255))
    d.polygon([(256, 60), (350, 230), (300, 450)], fill=(190, 110, 210, 255))
    base.save(v43.glow(img, (240, 160, 245), 16, 2), "eclat_cristal")


def nectar_fee():
    img = base.canvas()
    d = ImageDraw.Draw(img)
    d.rectangle((226, 70, 286, 160), fill=(220, 235, 240, 160))
    d.rectangle((216, 50, 296, 84), fill=(200, 120, 190, 255))
    base.shaded_ellipse(img, (140, 140, 372, 440), (250, 200, 70))
    d = ImageDraw.Draw(img)
    for k in range(5):
        x = 190 + k * 30
        d.ellipse((x, 260 + (k % 2) * 60, x + 14, 274 + (k % 2) * 60), fill=(255, 250, 200, 230))
    d.arc((140, 140, 372, 440), 200, 300, fill=(255, 255, 255, 220), width=10)
    base.save(img, "nectar_fee")


if __name__ == "__main__":
    goutte_rosee()
    baguette_fee()
    eclat_cristal()
    nectar_fee()
