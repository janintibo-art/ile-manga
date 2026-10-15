"""V43 : icônes du Royaume des Racines (dessinées ici, libres de droits).

- lanterne_fee.png : la lanterne de fée de Faelar (argent, verre, une lueur verte).
- poussiere_fee.png : une bourse de poussière de fée qui scintille.
Lancement : python3 pcvr/tools/generate_feerique_v43.py (depuis la racine du dépôt).
"""
from pathlib import Path
import math
import sys

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_items_v28 as base  # noqa: E402


def glow(img, color, blur=22, strength=2):
    halo = Image.new("RGBA", img.size, color + (0,))
    halo.putalpha(img.split()[3].filter(ImageFilter.GaussianBlur(blur)).point(lambda v: v // strength))
    halo.alpha_composite(img)
    return halo


def lanterne_fee():
    img = base.canvas()
    d = ImageDraw.Draw(img)
    d.arc((206, 30, 306, 130), 180, 360, fill=(200, 205, 215, 255), width=14)
    d.polygon([(256, 90), (360, 170), (152, 170)], fill=(200, 205, 215, 255))
    lay = base.canvas()
    base.shaded_ellipse(lay, (170, 160, 342, 400), (200, 255, 170))
    img.alpha_composite(lay)
    d = ImageDraw.Draw(img)
    for x in (180, 256, 332):
        d.line((x, 168, x if x == 256 else (x + 256) // 2, 396), fill=(190, 195, 205, 255), width=10)
    d.rectangle((168, 392, 344, 430), fill=(190, 195, 205, 255))
    d.ellipse((232, 250, 280, 298), fill=(255, 255, 220, 255))
    base.save(glow(img, (190, 255, 150)), "lanterne_fee")


def poussiere_fee():
    img = base.canvas()
    base.shaded_ellipse(img, (120, 190, 392, 450), (150, 90, 170))
    d = ImageDraw.Draw(img)
    d.polygon([(200, 200), (312, 200), (290, 150), (222, 150)], fill=(130, 75, 150, 255))
    d.line((205, 200, 307, 200), fill=(240, 200, 90, 255), width=12)
    cols = [(255, 190, 240), (170, 255, 240), (255, 240, 160), (200, 180, 255)]
    for k in range(18):
        a = math.radians(k * 37)
        r = 40 + (k * 23) % 90
        x, y = 256 + math.cos(a) * r, 110 + math.sin(a) * r * 0.6
        s = 6 + (k % 3) * 4
        d.ellipse((x - s, y - s, x + s, y + s), fill=cols[k % 4] + (255,))
    base.save(glow(img, (255, 200, 250), 16, 3), "poussiere_fee")


if __name__ == "__main__":
    lanterne_fee()
    poussiere_fee()
