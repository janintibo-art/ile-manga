"""V98 : les icônes des objets des adeptes de l'Île Al Dente (dessinées ici, versées au domaine public, CC0 1.0).

  items/focaccia.png         la focaccia au romarin (dorée, piquée de trous, du romarin, du gros sel)
  items/spaghettis_bolo.png  l'assiette de spaghettis bolognaise (sauce, trois boulettes, parmesan)
  items/pates_benites.png    le nid de tagliatelles fraîches de Mamma Lasagna
  items/rape_or.png          la Râpe d'Or du Capitaine (une râpe en laiton, une fourchette et une cuillère gravées)
  items/plat_sacre.png       le Plat de la Grande Réconciliation (le plat doré, les tagliatelles, la sauce)
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/icones_v98.py
"""
from pathlib import Path
import math
import sys

from PIL import ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import icones_v92 as i92  # noqa: E402


def focaccia():
    img = i92.toile()
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([70, 150, 442, 380], radius=70, fill=(170, 105, 40, 255))
    d.rounded_rectangle([80, 140, 432, 362], radius=66, fill=(226, 168, 80, 255))
    d.rounded_rectangle([110, 160, 300, 230], radius=30, fill=(240, 196, 110, 255))
    for (x, y) in [(150, 210), (220, 260), (300, 200), (360, 280), (190, 320), (290, 320), (390, 210), (130, 290)]:
        d.ellipse([x - 13, y - 9, x + 13, y + 9], fill=(180, 112, 40, 255))
    for (x, y, a) in [(180, 190, 0.4), (260, 300, -0.5), (340, 240, 0.9), (150, 260, -0.2), (380, 320, 0.3)]:
        dx, dy = 34 * math.cos(a), 34 * math.sin(a)
        d.line([(x - dx, y - dy), (x + dx, y + dy)], fill=(50, 92, 44, 255), width=7)
        for t in (-0.6, -0.2, 0.2, 0.6):
            px, py = x + dx * t, y + dy * t
            d.line([(px, py), (px - dy * 0.3, py + dx * 0.3)], fill=(70, 120, 55, 255), width=4)
    for (x, y) in [(240, 190), (320, 300), (170, 340), (400, 260)]:
        d.rectangle([x - 5, y - 5, x + 5, y + 5], fill=(250, 248, 240, 255))
    i92.finir(img, "focaccia")


def _assiette(d, gold):
    rim = (215, 170, 60, 255) if gold else (236, 234, 226, 255)
    inner = (240, 200, 90, 255) if gold else (250, 249, 244, 255)
    d.ellipse([50, 140, 462, 420], fill=rim)
    d.ellipse([100, 170, 412, 390], fill=inner)
    if gold:
        for k in range(24):
            t = k / 24 * 2 * math.pi
            x, y = 256 + 190 * math.cos(t), 280 + 126 * math.sin(t)
            d.ellipse([x - 5, y - 5, x + 5, y + 5], fill=(250, 226, 130, 255))


def _pates(d, cx, cy, rx, ry, n=34):
    for k in range(n):
        t0 = k * 0.7
        pts = []
        for s in range(14):
            t = t0 + s * 0.45
            r = 1.0 - s / 20
            pts.append((cx + rx * r * math.cos(t), cy + ry * r * math.sin(t) - s * 1.5))
        d.line(pts, fill=(246, 214, 120, 255) if k % 2 else (236, 196, 100, 255), width=7)


def bolo():
    img = i92.toile()
    d = ImageDraw.Draw(img)
    _assiette(d, False)
    _pates(d, 256, 270, 130, 80)
    d.ellipse([170, 200, 342, 300], fill=(170, 26, 14, 255))
    d.ellipse([190, 210, 260, 250], fill=(205, 56, 36, 255))
    for (x, y) in [(220, 245), (280, 235), (255, 280)]:
        d.ellipse([x - 26, y - 24, x + 26, y + 24], fill=(96, 50, 26, 255))
        d.ellipse([x - 14, y - 16, x + 4, y - 4], fill=(140, 80, 44, 255))
    for k in range(40):
        x = 200 + (k * 37) % 120
        y = 205 + (k * 53) % 70
        d.rectangle([x, y, x + 5, y + 3], fill=(250, 240, 200, 255))
    d.ellipse([262, 196, 300, 214], fill=(60, 130, 50, 255))
    i92.finir(img, "spaghettis_bolo")


def nid():
    img = i92.toile()
    d = ImageDraw.Draw(img)
    for ring in range(6):
        r = 170 - ring * 24
        for k in range(10):
            a0 = k * 36 + ring * 17
            d.arc([256 - r, 270 - r * 0.62, 256 + r, 270 + r * 0.62], a0, a0 + 300, fill=(246, 210, 110, 255) if (k + ring) % 2 else (232, 188, 90, 255), width=16)
    d.ellipse([200, 230, 312, 300], fill=(222, 176, 82, 255))
    for k in range(5):
        x = 140 + k * 60
        d.ellipse([x - 4, 400 - (k % 2) * 20, x + 4, 408 - (k % 2) * 20], fill=(250, 246, 236, 255))
    i92.finir(img, "pates_benites")


def rape():
    img = i92.toile()
    d = ImageDraw.Draw(img)
    d.polygon([(180, 110), (332, 110), (372, 440), (140, 440)], fill=(212, 164, 56, 255))
    d.polygon([(180, 110), (230, 110), (210, 440), (140, 440)], fill=(240, 200, 96, 255))
    for row in range(9):
        y = 150 + row * 30
        for col in range(5):
            x = 196 + col * 28 + (row % 2) * 12 + row * 1.8
            d.ellipse([x - 7, y - 5, x + 7, y + 5], fill=(120, 80, 20, 255))
            d.arc([x - 9, y - 9, x + 9, y + 3], 200, 340, fill=(255, 236, 160, 255), width=3)
    d.rounded_rectangle([222, 60, 290, 116], radius=20, outline=(110, 62, 26, 255), width=14)
    # la fourchette et la cuillère croisées, gravées en bas
    d.line([(200, 420), (300, 340)], fill=(140, 96, 24, 255), width=8)
    d.line([(312, 420), (212, 340)], fill=(140, 96, 24, 255), width=8)
    d.ellipse([196, 326, 226, 352], fill=(140, 96, 24, 255))
    for k in range(3):
        d.line([(290 + k * 8, 336 - k * 4), (306 + k * 8, 322 - k * 4)], fill=(140, 96, 24, 255), width=4)
    i92.finir(img, "rape_or")


def plat():
    img = i92.toile()
    d = ImageDraw.Draw(img)
    _assiette(d, True)
    _pates(d, 256, 270, 140, 86, 40)
    d.ellipse([180, 205, 332, 295], fill=(160, 22, 12, 255))
    for (x, y) in [(225, 245), (285, 238), (258, 276)]:
        d.ellipse([x - 22, y - 20, x + 22, y + 20], fill=(96, 50, 26, 255))
    for k in range(70):
        x = 190 + (k * 41) % 140
        y = 200 + (k * 59) % 90
        d.rectangle([x, y, x + 6, y + 3], fill=(252, 244, 206, 255))
    for (x, y) in [(120, 120), (400, 110), (440, 380), (80, 360)]:
        d.polygon([(x, y - 22), (x + 6, y - 6), (x + 22, y), (x + 6, y + 6), (x, y + 22), (x - 6, y + 6), (x - 22, y), (x - 6, y - 6)], fill=(255, 236, 140, 255))
    i92.finir(img, "plat_sacre")


if __name__ == "__main__":
    focaccia()
    bolo()
    nid()
    rape()
    plat()
    print("V98 : 5 icônes")
