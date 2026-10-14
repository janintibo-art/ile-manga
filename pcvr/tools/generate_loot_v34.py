"""V34 : icônes du bois et des petits trésors (bûche, noix de coco, miel, perle, bague,
rubis, pièce d'or). Réutilise les outils de dessin des icônes de la V28.
Lancement depuis la racine du dépôt : python3 pcvr/tools/generate_loot_v34.py
"""
from pathlib import Path
import math
import sys

from PIL import ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_items_v28 as base  # noqa: E402

canvas = base.canvas
save = base.save
stick = base.stick_polygon


def ell(img, box, col, **kw):
    base.shaded_ellipse(img, tuple(int(round(v)) for v in box), col, **kw)


def buche():
    img = canvas()
    d = ImageDraw.Draw(img)
    # Rondin couché : écorce, puis la tranche avec ses cernes
    stick(d, (120, 330), (390, 190), 150, (112, 76, 44, 255))
    for k in range(5):
        x0, y0 = 150 + k * 52, 300 - k * 27
        d.line((x0, y0 - 60, x0 + 40, y0 + 50), fill=(86, 56, 30, 255), width=8)
    d.ellipse((330, 120, 470, 270), fill=(214, 172, 118, 255), outline=(96, 64, 36, 255), width=12)
    for r in (50, 34, 18):
        d.ellipse((400 - r, 195 - r, 400 + r, 195 + r), outline=(176, 128, 80, 255), width=6)
    save(img, "buche")


def noix_coco():
    img = canvas()
    ell(img, (96, 110, 416, 420), (120, 80, 46), gloss=False)
    d = ImageDraw.Draw(img)
    for k in range(14):
        a = k / 14 * math.tau
        x, y = 256 + math.cos(a) * 120, 265 + math.sin(a) * 120
        d.line((x, y, x + math.cos(a + 1.2) * 34, y + math.sin(a + 1.2) * 34), fill=(84, 54, 30, 255), width=7)
    for dx in (-36, 0, 36):
        d.ellipse((256 + dx - 14, 150, 256 + dx + 14, 178), fill=(50, 32, 18, 255))
    save(img, "noix_coco")


def miel():
    img = canvas()
    d = ImageDraw.Draw(img)
    # Pot de terre, couvercle de tissu, miel qui coule
    ell(img, (120, 170, 392, 450), (196, 120, 60), gloss=True)
    d = ImageDraw.Draw(img)
    d.rectangle((150, 140, 362, 200), fill=(224, 200, 150, 255))
    d.line((150, 196, 362, 196), fill=(150, 90, 50, 255), width=12)
    d.polygon([(200, 200), (232, 200), (228, 300), (210, 320), (198, 300)], fill=(240, 170, 30, 255))
    d.ellipse((196, 290, 226, 330), fill=(250, 186, 40, 255))
    save(img, "miel")


def perle():
    img = canvas()
    d = ImageDraw.Draw(img)
    # Huître ouverte et sa perle
    d.pieslice((70, 220, 442, 470), 180, 360, fill=(120, 110, 104, 255))
    d.pieslice((96, 236, 416, 452), 180, 360, fill=(220, 200, 210, 255))
    ell(img, (180, 200, 332, 352), (244, 240, 236))
    save(img, "perle")


def bague():
    img = canvas()
    d = ImageDraw.Draw(img)
    d.ellipse((120, 190, 392, 450), outline=(200, 204, 214, 255), width=40)
    d.ellipse((140, 210, 372, 430), outline=(236, 240, 246, 255), width=10)
    ell(img, (196, 80, 316, 200), (70, 170, 220))
    d = ImageDraw.Draw(img)
    d.polygon([(206, 190), (306, 190), (290, 216), (222, 216)], fill=(200, 204, 214, 255))
    save(img, "bague")


def rubis():
    img = canvas()
    d = ImageDraw.Draw(img)
    pts = [(256, 70), (420, 200), (256, 450), (92, 200)]
    d.polygon(pts, fill=(170, 20, 40, 255))
    d.polygon([(256, 70), (420, 200), (256, 200)], fill=(230, 60, 80, 255))
    d.polygon([(92, 200), (256, 200), (256, 450)], fill=(120, 10, 30, 255))
    d.polygon([(200, 130), (256, 100), (300, 140), (250, 170)], fill=(255, 170, 180, 255))
    save(img, "rubis")


def piece_or():
    img = canvas()
    ell(img, (100, 100, 412, 412), (236, 186, 50))
    d = ImageDraw.Draw(img)
    d.ellipse((150, 150, 362, 362), outline=(176, 120, 20, 255), width=12)
    # Une couronne frappée
    d.polygon([(186, 300), (186, 210), (220, 250), (256, 190), (292, 250), (326, 210), (326, 300)], fill=(190, 130, 24, 255))
    save(img, "piece_or")


if __name__ == "__main__":
    buche()
    noix_coco()
    miel()
    perle()
    bague()
    rubis()
    piece_or()
