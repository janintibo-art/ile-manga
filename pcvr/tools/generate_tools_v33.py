"""V33 : icônes des outils et armes d'Octave Taillefer (pelle, hache, épée d'acier).

Réutilise les outils de dessin des icônes de la V28 (ombrage, contour, ombre portée).
Lancement depuis la racine du dépôt : python3 pcvr/tools/generate_tools_v33.py
"""
from pathlib import Path
import sys

from PIL import ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_items_v28 as base  # noqa: E402

canvas = base.canvas
save = base.save
stick = base.stick_polygon


def pelle():
    img = canvas()
    d = ImageDraw.Draw(img)
    # Manche en bois et poignée en T
    stick(d, (150, 360), (400, 110), 26, (150, 104, 60, 255))
    stick(d, (160, 350), (392, 118), 8, (190, 140, 88, 255))
    stick(d, (368, 82), (432, 146), 22, (120, 80, 44, 255))
    # Fer de pelle : pointe arrondie, reflet
    d.polygon([(70, 330), (150, 250), (238, 338), (196, 400), (120, 452), (80, 440), (62, 398)], fill=(130, 136, 142, 255))
    d.polygon([(92, 334), (150, 276), (170, 296), (110, 356)], fill=(200, 206, 212, 255))
    d.line([(150, 250), (238, 338)], fill=(90, 94, 100, 255), width=10)
    stick(d, (150, 330), (200, 280), 30, (100, 104, 110, 255))
    save(img, "pelle")


def hache():
    img = canvas()
    d = ImageDraw.Draw(img)
    stick(d, (110, 450), (330, 120), 30, (150, 104, 60, 255))
    stick(d, (122, 440), (322, 132), 9, (192, 142, 90, 255))
    stick(d, (100, 466), (150, 392), 34, (96, 62, 34, 255))
    # Fer : tranchant courbe vers la droite
    d.polygon([(300, 96), (360, 120), (440, 90), (462, 170), (440, 250), (370, 214), (316, 196)], fill=(124, 128, 134, 255))
    d.polygon([(420, 104), (440, 92), (462, 170), (440, 248), (424, 236), (442, 170)], fill=(214, 220, 226, 255))
    d.ellipse((316, 120, 352, 156), fill=(70, 72, 78, 255))
    save(img, "hache")


def epee():
    img = canvas()
    d = ImageDraw.Draw(img)
    # Lame d'acier avec gorge centrale
    stick(d, (170, 342), (432, 80), 46, (176, 184, 192, 255))
    d.polygon([(432, 80), (462, 50), (452, 98)], fill=(176, 184, 192, 255))
    stick(d, (186, 326), (426, 88), 10, (230, 236, 242, 255))
    stick(d, (200, 330), (440, 92), 4, (120, 126, 134, 255))
    # Garde en laiton, fusée en cuir, pommeau
    stick(d, (112, 296), (220, 404), 30, (196, 152, 64, 255))
    stick(d, (84, 430), (166, 348), 32, (74, 44, 28, 255))
    for k in range(4):
        x, y = 96 + k * 18, 418 - k * 18
        stick(d, (x - 14, y - 14), (x + 14, y + 14), 5, (120, 80, 50, 255))
    d.ellipse((54, 436, 100, 482), fill=(196, 152, 64, 255))
    save(img, "epee")


if __name__ == "__main__":
    pelle()
    hache()
    epee()
