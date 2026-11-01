"""V93 : les icônes des objets du Festival du Larsen (dessinées ici, versées au domaine public, CC0 1.0).

  items/cordes_scene.png  le gros rouleau de cordes de Galet, fermé par son nœud
  items/toile_scene.png   la toile de Lune, roulée, nouée de deux liens rouges ; un coin déroulé
                          laisse voir le soleil et l'arc-en-ciel
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/icones_v93.py
"""
from pathlib import Path
import math
import sys

from PIL import ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import icones_v92 as i92  # noqa: E402


def cordes():
    img = i92.toile()
    d = ImageDraw.Draw(img)
    for k in range(9):
        r = 200 - k * 18
        col = (190 - k * 5, 150 - k * 4, 92 - k * 3, 255)
        d.ellipse([256 - r, 270 - r * 0.7, 256 + r, 270 + r * 0.7], outline=col, width=18)
        for t in range(0, 360, 10):
            a = math.radians(t + k * 5)
            x, y = 256 + math.cos(a) * r, 270 + math.sin(a) * r * 0.7
            d.line([(x - 5, y - 7), (x + 5, y + 7)], fill=(130, 98, 58, 255), width=4)
    d.ellipse([226, 250, 286, 290], fill=(110, 82, 48, 255))
    # le nœud d'amitié, sur le côté
    d.ellipse([400, 300, 470, 360], outline=(170, 132, 80, 255), width=16)
    d.ellipse([430, 300, 500, 360], outline=(185, 145, 90, 255), width=16)
    i92.finir(img, "cordes_scene")


def toile_roulee():
    img = i92.toile()
    d = ImageDraw.Draw(img)
    # le coin déroulé : un morceau de ciel jaune, le soleil, l'arc-en-ciel
    d.polygon([(120, 250), (300, 250), (330, 430), (150, 450)], fill=(250, 205, 110, 255))
    for i, c in enumerate([(220, 50, 50), (240, 140, 40), (245, 215, 60), (80, 175, 80), (60, 120, 210)]):
        r = 150 - i * 14
        d.arc([240 - r, 450 - r, 240 + r, 450 + r], 200, 290, fill=c + (255,), width=14)
    d.ellipse([150, 280, 200, 330], fill=(252, 210, 60, 255))
    # le rouleau, en biais
    d.polygon([(100, 210), (430, 90), (470, 170), (140, 290)], fill=(225, 205, 160, 255))
    d.ellipse([400, 82, 480, 178], fill=(205, 185, 140, 255))
    d.ellipse([420, 100, 460, 160], fill=(170, 150, 110, 255))
    for t in (0.3, 0.7):
        x0, y0 = 100 + (430 - 100) * t, 210 + (90 - 210) * t
        d.line([(x0, y0), (x0 + 40, y0 + 80)], fill=(200, 60, 70, 255), width=16)
    i92.finir(img, "toile_scene")


if __name__ == "__main__":
    cordes()
    toile_roulee()
    print("V93 : 2 icônes")
