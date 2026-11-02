"""V97 : les icônes des objets de l'Île Al Dente (dessinées ici, versées au domaine public, CC0 1.0).

  items/sauce_volcan.png     le petit pot de sauce du volcan (verre rouge, couvercle doré, étiquette)
  items/tomate_coeur.png     la tomate cœur-de-bœuf (côtelée, sa queue verte)
  items/spaghettis_secs.png  la botte de spaghettis, nouée d'un ruban vert, blanc et rouge
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/icones_v97.py
"""
from pathlib import Path
import sys

from PIL import ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import icones_v92 as i92  # noqa: E402


def sauce():
    img = i92.toile()
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([140, 150, 372, 450], radius=40, fill=(160, 22, 12, 255))
    d.rounded_rectangle([160, 170, 210, 420], radius=20, fill=(205, 60, 40, 255))
    d.rounded_rectangle([130, 96, 382, 160], radius=18, fill=(220, 180, 70, 255))
    for x in range(150, 372, 22):
        d.line([(x, 100), (x, 156)], fill=(180, 140, 40, 255), width=6)
    d.rectangle([140, 250, 372, 350], fill=(244, 236, 214, 255))
    d.ellipse([228, 270, 284, 330], fill=(200, 30, 20, 255))
    d.polygon([(256, 262), (240, 280), (272, 280)], fill=(60, 140, 50, 255))
    for (x, y) in [(330, 200), (300, 400), (190, 380)]:
        d.ellipse([x - 7, y - 7, x + 7, y + 7], fill=(70, 120, 40, 255))
    i92.finir(img, "sauce_volcan")


def tomate():
    img = i92.toile()
    d = ImageDraw.Draw(img)
    for k, (x0, x1) in enumerate([(90, 250), (170, 342), (262, 422)]):
        d.ellipse([x0, 160, x1, 430], fill=(205 - k * 8, 30, 20, 255))
    d.ellipse([150, 150, 362, 440], fill=(212, 36, 24, 255))
    d.ellipse([180, 190, 240, 260], fill=(245, 110, 90, 255))
    for a in range(5):
        import math
        t = a / 5 * 2 * math.pi
        d.polygon([(256, 160), (256 + 70 * math.cos(t), 160 + 30 * math.sin(t) - 10), (256 + 30 * math.cos(t + 0.4), 160 + 12 * math.sin(t + 0.4))], fill=(60, 130, 40, 255))
    d.rounded_rectangle([248, 100, 266, 165], radius=8, fill=(70, 120, 40, 255))
    i92.finir(img, "tomate_coeur")


def spaghettis():
    img = i92.toile()
    d = ImageDraw.Draw(img)
    for k in range(16):
        y = 196 + k * 8
        d.line([(60, y + (k % 3) * 2), (452, y - (k % 2) * 3)], fill=(236, 196, 100, 255) if k % 2 else (245, 214, 130, 255), width=9)
    d.rectangle([200, 180, 236, 340], fill=(30, 130, 70, 255))
    d.rectangle([236, 180, 272, 340], fill=(245, 242, 232, 255))
    d.rectangle([272, 180, 308, 340], fill=(200, 30, 30, 255))
    d.polygon([(300, 330), (350, 420), (320, 420), (290, 350)], fill=(200, 30, 30, 255))
    d.polygon([(210, 330), (160, 420), (190, 420), (220, 350)], fill=(30, 130, 70, 255))
    i92.finir(img, "spaghettis_secs")


if __name__ == "__main__":
    sauce()
    tomate()
    spaghettis()
    print("V97 : 3 icônes")
