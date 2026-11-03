"""V101 : les icônes des objets de l'Île Crayonnée (dessinées ici, versées au domaine public, CC0 1.0).

  items/pinceau.png           le Pinceau de l'île (manche verni, virole dorée, soies, le bout bleu)
  items/pot_<couleur>.png     les neuf pots de couleur de la Palette de pierre (fer-blanc cabossé,
                              la peinture qui déborde un peu, l'étiquette et son numéro)
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/icones_v101.py
"""
from pathlib import Path
import math
import sys

from PIL import ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
import icones_v92 as i92  # noqa: E402

POTS = [
    ("bleu", 1, (41, 97, 199)), ("vert", 2, (51, 140, 56)), ("rouge", 3, (214, 33, 28)),
    ("jaune", 4, (250, 209, 46)), ("brun", 5, (128, 79, 41)), ("violet", 6, (128, 69, 168)),
    ("orange", 7, (247, 133, 31)), ("turquoise", 8, (36, 173, 173)), ("rose", 9, (242, 128, 168)),
]


def _police(taille):
    for nom in ("DejaVuSans-Bold.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", "LiberationSans-Bold.ttf"):
        try:
            return ImageFont.truetype(nom, taille)
        except OSError:
            continue
    return ImageFont.load_default()


def pot(nom, num, c):
    img = i92.toile()
    d = ImageDraw.Draw(img)
    fonce = tuple(int(v * 0.72) for v in c)
    clair = tuple(min(255, int(v * 1.18 + 20)) for v in c)
    # le corps du pot (fer-blanc), un reflet, une bosse
    d.rectangle([126, 170, 386, 430], fill=(176, 180, 186, 255))
    d.ellipse([126, 400, 386, 460], fill=(150, 154, 160, 255))
    d.rectangle([150, 175, 176, 425], fill=(214, 218, 224, 255))
    d.ellipse([300, 300, 352, 352], fill=(160, 164, 170, 255))
    # l'étiquette et son numéro
    d.rectangle([126, 250, 386, 360], fill=(244, 238, 222, 255))
    f = _police(92)
    t = str(num)
    w = d.textlength(t, font=f)
    d.text((256 - w / 2, 252), t, font=f, fill=(30, 28, 26, 255))
    # le bord et la peinture, qui déborde en coulures
    d.ellipse([116, 136, 396, 204], fill=(150, 154, 160, 255))
    d.ellipse([132, 142, 380, 198], fill=c + (255,))
    d.ellipse([170, 150, 290, 178], fill=clair + (255,))
    for (x, l, w2) in [(150, 70, 22), (210, 120, 26), (330, 92, 24), (366, 52, 18)]:
        d.rounded_rectangle([x - w2 / 2, 170, x + w2 / 2, 170 + l], radius=int(w2 / 2), fill=c + (255,))
        d.ellipse([x - w2 * 0.62, 160 + l, x + w2 * 0.62, 182 + l], fill=c + (255,))
        d.line([(x - w2 * 0.2, 176), (x - w2 * 0.2, 162 + l)], fill=clair + (255,), width=3)
    d.arc([116, 136, 396, 204], 200, 340, fill=fonce + (255,), width=4)
    # l'anse
    d.arc([126, 40, 386, 250], 200, 340, fill=(110, 112, 116, 255), width=10)
    i92.finir(img, "pot_" + nom)


def pinceau():
    img = i92.toile()
    d = ImageDraw.Draw(img)
    a = math.radians(-40)
    ux, uy = math.cos(a), math.sin(a)
    vx, vy = -uy, ux

    def quad(t0, t1, w0, w1, col):
        cx, cy = 256, 256
        p = [(cx + ux * t0 + vx * w0, cy + uy * t0 + vy * w0), (cx + ux * t1 + vx * w1, cy + uy * t1 + vy * w1),
             (cx + ux * t1 - vx * w1, cy + uy * t1 - vy * w1), (cx + ux * t0 - vx * w0, cy + uy * t0 - vy * w0)]
        d.polygon(p, fill=col)
    quad(-220, 60, 14, 22, (110, 62, 30, 255))
    quad(-215, 50, 4, 6, (150, 92, 50, 255))
    quad(60, 120, 26, 30, (222, 180, 92, 255))
    quad(68, 112, 6, 7, (250, 222, 150, 255))
    quad(120, 190, 32, 26, (232, 216, 180, 255))
    quad(190, 236, 26, 2, (41, 97, 199, 255))
    i92.finir(img, "pinceau")


if __name__ == "__main__":
    for nom, num, c in POTS:
        pot(nom, num, c)
    pinceau()
    print("icônes V101 :", len(POTS) + 1)
