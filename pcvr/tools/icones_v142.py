"""V142 : les icônes des objets de l'Île des Géants (dessinées ici, versées au domaine public, CC0 1.0).

  items/bague_geante.png   l'alliance de Mère Mathurine (un anneau d'or, si gros qu'on le porte à deux bras)
  items/miette_geante.png  une miette du pain des géants (pour nous, une miche entière)
  items/pomme_geante.png   une pomme du verger des géants (grosse comme un ballon)
  items/bille_geante.png   Gustave, la plus belle bille de Pâquerette (du verre, une spirale bleue)
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/icones_v142.py
"""
from pathlib import Path
import math
import sys

from PIL import ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import icones_v92 as i92  # noqa: E402


def bague():
    img = i92.toile()
    d = ImageDraw.Draw(img)
    # l'anneau, vu un peu de biais : une ellipse épaisse dorée, son reflet, son ombre intérieure
    d.ellipse([60, 120, 452, 392], fill=(196, 140, 40, 255))
    d.ellipse([92, 150, 420, 362], fill=(0, 0, 0, 0))
    d.ellipse([70, 128, 442, 384], outline=(250, 214, 110, 255), width=10)
    d.arc([96, 154, 416, 358], 200, 340, fill=(140, 92, 22, 255), width=12)
    d.arc([70, 128, 442, 384], 210, 300, fill=(255, 244, 200, 255), width=6)
    # les éclats
    for (x, y, r) in [(140, 150, 16), (380, 330, 11), (300, 128, 9)]:
        d.polygon([(x, y - r * 2), (x + r * 0.5, y - r * 0.5), (x + r * 2, y), (x + r * 0.5, y + r * 0.5), (x, y + r * 2), (x - r * 0.5, y + r * 0.5), (x - r * 2, y), (x - r * 0.5, y - r * 0.5)], fill=(255, 255, 240, 255))
    i92.finir(img, "bague_geante")


def miette():
    img = i92.toile()
    d = ImageDraw.Draw(img)
    # une grosse miche, la croûte dorée, la mie claire à l'endroit où elle a été arrachée
    d.ellipse([70, 150, 450, 410], fill=(176, 106, 46, 255))
    d.ellipse([90, 140, 440, 370], fill=(208, 140, 66, 255))
    d.polygon([(300, 150), (440, 230), (430, 360), (330, 330), (290, 250)], fill=(246, 226, 180, 255))
    for (x, y) in [(330, 230), (360, 280), (390, 250), (350, 320), (400, 310)]:
        d.ellipse([x - 9, y - 7, x + 9, y + 7], fill=(226, 200, 150, 255))
    for k in range(4):
        x = 140 + k * 45
        d.arc([x, 180, x + 80, 260], 200, 330, fill=(150, 88, 36, 255), width=8)
    d.arc([110, 160, 300, 260], 200, 300, fill=(240, 190, 110, 255), width=6)
    i92.finir(img, "miette_geante")


def pomme():
    img = i92.toile()
    d = ImageDraw.Draw(img)
    d.ellipse([90, 130, 270, 420], fill=(176, 22, 18, 255))
    d.ellipse([230, 130, 420, 420], fill=(176, 22, 18, 255))
    d.ellipse([110, 140, 400, 410], fill=(206, 34, 26, 255))
    d.ellipse([150, 180, 230, 270], fill=(240, 120, 100, 255))
    d.ellipse([168, 196, 206, 236], fill=(255, 196, 180, 255))
    d.line([(256, 150), (270, 70)], fill=(92, 58, 26, 255), width=14)
    d.polygon([(272, 96), (350, 60), (400, 90), (340, 120)], fill=(70, 140, 50, 255))
    d.line([(280, 98), (390, 86)], fill=(120, 186, 90, 255), width=4)
    i92.finir(img, "pomme_geante")


def bille():
    img = i92.toile()
    d = ImageDraw.Draw(img)
    d.ellipse([86, 86, 426, 426], fill=(196, 226, 240, 235))
    # la spirale bleue dedans
    pts = []
    for k in range(120):
        t = k / 119
        a = t * 4.2 * math.pi
        r = 20 + t * 140
        pts.append((256 + math.cos(a) * r, 256 + math.sin(a) * r * 0.8))
    d.line(pts, fill=(36, 92, 200, 255), width=22, joint="curve")
    d.line(pts, fill=(90, 150, 236, 255), width=8, joint="curve")
    d.ellipse([86, 86, 426, 426], outline=(120, 170, 200, 255), width=6)
    d.ellipse([150, 130, 230, 190], fill=(255, 255, 255, 220))
    d.ellipse([320, 330, 350, 352], fill=(255, 255, 255, 150))
    i92.finir(img, "bille_geante")


if __name__ == "__main__":
    bague()
    miette()
    pomme()
    bille()
    print("icônes V142 : 4")
