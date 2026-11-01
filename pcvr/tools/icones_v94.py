"""V94 : les icônes des objets de Néopolis (dessinées ici, versées au domaine public, CC0 1.0).

  items/soda_neon.png     la canette de Synthé-Soda (rose, une bande cyan, des bulles)
  items/nouilles_neo.png  le bol de néo-ramen du robot du Marché de Nuit (vu d'en haut, de biais)
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/icones_v94.py
"""
from pathlib import Path
import sys

from PIL import ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import icones_v92 as i92  # noqa: E402


def soda():
    img = i92.toile()
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([170, 90, 342, 440], radius=36, fill=(250, 60, 165, 255))
    d.rectangle([170, 230, 342, 310], fill=(40, 220, 255, 255))
    d.ellipse([170, 66, 342, 120], fill=(205, 205, 215, 255))
    d.ellipse([190, 74, 322, 112], fill=(170, 170, 182, 255))
    d.rounded_rectangle([238, 78, 290, 96], radius=8, outline=(120, 120, 130, 255), width=5)
    d.ellipse([170, 412, 342, 462], fill=(200, 40, 140, 255))
    d.text((228, 238), "S", fill=(255, 255, 255, 255), font_size=64)
    d.rounded_rectangle([196, 120, 214, 400], radius=8, fill=(255, 150, 210, 255))
    for (x, y, r) in [(380, 150, 16), (402, 230, 10), (372, 300, 13), (120, 180, 12), (104, 270, 9)]:
        d.ellipse([x - r, y - r, x + r, y + r], outline=(140, 240, 255, 255), width=5)
    i92.finir(img, "soda_neon")


def nouilles():
    img = i92.toile()
    d = ImageDraw.Draw(img)
    d.pieslice([60, 170, 452, 470], 0, 180, fill=(236, 232, 224, 255))
    d.ellipse([60, 140, 452, 280], fill=(250, 248, 242, 255))
    d.ellipse([78, 152, 434, 268], fill=(225, 160, 70, 255))
    for k in range(10):
        x = 110 + k * 30
        d.arc([x, 160, x + 60, 250], 200, 340, fill=(250, 225, 140, 255), width=9)
    d.ellipse([250, 168, 330, 214], fill=(255, 252, 244, 255))
    d.ellipse([272, 178, 308, 204], fill=(250, 180, 30, 255))
    d.ellipse([140, 176, 196, 206], fill=(80, 160, 70, 255))
    d.arc([180, 200, 240, 240], 20, 160, fill=(120, 40, 20, 255), width=6)
    d.line([(330, 60), (470, 230)], fill=(150, 95, 50, 255), width=12)
    d.line([(355, 50), (488, 214)], fill=(150, 95, 50, 255), width=12)
    d.rectangle([200, 380, 312, 400], fill=(210, 40, 50, 255))
    i92.finir(img, "nouilles_neo")


if __name__ == "__main__":
    soda()
    nouilles()
    print("V94 : 2 icônes")
