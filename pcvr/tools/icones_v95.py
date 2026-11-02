"""V95 : l'icône de la puce vocale Série Z (dessinée ici, versée au domaine public, CC0 1.0).

  items/puce_vocale.png   une vieille puce verte aux pattes dorées, une étiquette jaunie « Z-0 »,
                          et trois petites ondes sonores qui en sortent
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/icones_v95.py
"""
from pathlib import Path
import sys

from PIL import ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import icones_v92 as i92  # noqa: E402


def puce():
    img = i92.toile()
    d = ImageDraw.Draw(img)
    # les pattes dorées
    for k in range(7):
        x = 128 + k * 40
        d.rectangle([x, 120, x + 16, 160], fill=(232, 182, 72, 255))
        d.rectangle([x, 352, x + 16, 392], fill=(232, 182, 72, 255))
    # le corps de la puce (circuit vert), ses pistes
    d.rounded_rectangle([96, 150, 416, 362], radius=18, fill=(26, 92, 44, 255))
    for k in range(5):
        y = 180 + k * 34
        d.line([(112, y), (180, y), (200, y + 14)], fill=(70, 170, 90, 255), width=5)
        d.line([(400, y), (332, y), (312, y + 14)], fill=(70, 170, 90, 255), width=5)
    # le cœur noir, son reflet
    d.rounded_rectangle([190, 182, 322, 300], radius=10, fill=(22, 22, 26, 255))
    d.line([(204, 196), (300, 196)], fill=(80, 80, 92, 255), width=5)
    # l'étiquette jaunie
    d.rectangle([200, 310, 312, 346], fill=(236, 220, 160, 255))
    d.text((222, 312), "Z-0", fill=(70, 50, 30, 255), font_size=30)
    # les ondes sonores
    for k, r in enumerate((40, 70, 100)):
        d.arc([416 - r, 256 - r, 416 + r, 256 + r], -40, 40, fill=(255, 190, 60, 255 - k * 50), width=10)
    i92.finir(img, "puce_vocale")


if __name__ == "__main__":
    puce()
    print("V95 : 1 icône")
