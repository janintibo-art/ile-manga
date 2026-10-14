"""V32 : icônes de la pêche (poissons, canne, vieille botte), dessinées ici.

Réutilise les outils de dessin des icônes de la V28 (ombrage, contour, ombre portée).
Lancement depuis la racine du dépôt : python3 pcvr/tools/generate_fish_v32.py
"""
from pathlib import Path
import math
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_items_v28 as base  # noqa: E402

S = base.S
canvas = base.canvas
def shaded_ellipse(img, box, col, **kw):
    base.shaded_ellipse(img, tuple(int(round(v)) for v in box), col, **kw)


save = base.save


def fish(name, body, belly, fin, length=0.82, height=0.34, stripes=None, spots=None, band=None, round_body=False):
    img = canvas()
    d = ImageDraw.Draw(img)
    cx, cy = S * 0.46, S * 0.5
    L = S * length
    H = S * (height if not round_body else 0.62)
    # Queue
    tail_x = cx + L * 0.45
    d.polygon([(tail_x - 20, cy), (tail_x + L * 0.17, cy - H * 0.55), (tail_x + L * 0.11, cy), (tail_x + L * 0.17, cy + H * 0.55)], fill=fin + (255,))
    # Nageoires dorsale et ventrale
    d.polygon([(cx - L * 0.12, cy - H * 0.42), (cx + L * 0.05, cy - H * 0.82), (cx + L * 0.22, cy - H * 0.38)], fill=fin + (255,))
    d.polygon([(cx + L * 0.02, cy + H * 0.4), (cx + L * 0.12, cy + H * 0.7), (cx + L * 0.2, cy + H * 0.36)], fill=fin + (255,))
    # Corps ombré, ventre plus clair
    shaded_ellipse(img, (cx - L * 0.5, cy - H * 0.5, cx + L * 0.5, cy + H * 0.5), body)
    belly_layer = canvas()
    shaded_ellipse(belly_layer, (cx - L * 0.45, cy - H * 0.05, cx + L * 0.42, cy + H * 0.48), belly, gloss=False)
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse((cx - L * 0.5, cy - H * 0.5, cx + L * 0.5, cy + H * 0.5), fill=255)
    img.paste(belly_layer, (0, 0), Image.fromarray(np.minimum(np.array(mask), np.array(belly_layer.split()[3]))))
    d = ImageDraw.Draw(img)
    if stripes:
        for k in range(7):
            x = cx - L * 0.32 + k * L * 0.1
            d.line((x, cy - H * 0.45, x + 18, cy - H * 0.05), fill=stripes + (255,), width=9)
    if spots:
        rng = np.random.default_rng(len(name))
        for _ in range(22):
            x = cx + rng.uniform(-0.38, 0.38) * L
            y = cy + rng.uniform(-0.3, 0.25) * H
            r = rng.uniform(6, 13)
            d.ellipse((x - r, y - r, x + r, y + r), fill=spots + (255,))
    if band:
        d.line((cx - L * 0.3, cy - H * 0.42, cx - L * 0.3, cy + H * 0.42), fill=band + (255,), width=16)
    # Ouïe et œil
    d.arc((cx - L * 0.36, cy - H * 0.36, cx - L * 0.18, cy + H * 0.36), 300, 60, fill=(30, 30, 30, 200), width=6)
    ex, ey = cx - L * 0.34, cy - H * 0.1
    d.ellipse((ex - 26, ey - 26, ex + 26, ey + 26), fill=(250, 250, 240, 255), outline=(30, 30, 30, 255), width=4)
    d.ellipse((ex - 13, ey - 13, ex + 13, ey + 13), fill=(15, 15, 20, 255))
    save(img, name)


def canne():
    img = canvas()
    d = ImageDraw.Draw(img)
    d.line((90, 440, 430, 70), fill=(110, 72, 38, 255), width=20)
    d.line((300, 213, 430, 70), fill=(150, 104, 58, 255), width=10)
    d.line((70, 462, 140, 385), fill=(180, 150, 110, 255), width=34)        # poignée en liège
    shaded_ellipse(img, (128, 330, 210, 412), (160, 160, 170))                 # moulinet
    d = ImageDraw.Draw(img)
    for t in (0.35, 0.55, 0.75, 0.9):
        x, y = 90 + 340 * t, 440 - 370 * t
        d.ellipse((x - 9, y - 9, x + 9, y + 9), outline=(200, 200, 210, 255), width=4)
    pts = [(430, 70)] + [(430 + 14 * math.sin(k * 0.5), 70 + k * 26) for k in range(1, 15)]
    d.line(pts, fill=(235, 235, 235, 230), width=4)
    d.ellipse((415, 430, 455, 470), fill=(220, 40, 30, 255))
    d.pieslice((415, 430, 455, 470), 180, 360, fill=(245, 245, 240, 255))
    save(img, "canne_peche")


def botte():
    img = canvas()
    d = ImageDraw.Draw(img)
    d.polygon([(190, 80), (310, 80), (320, 330), (430, 360), (440, 430), (170, 430), (180, 300)], fill=(92, 62, 36, 255))
    d.polygon([(190, 80), (310, 80), (305, 120), (195, 120)], fill=(70, 46, 26, 255))
    d.line((170, 430, 440, 430), fill=(40, 28, 18, 255), width=18)
    d.line((240, 170, 300, 230), fill=(60, 40, 22, 255), width=6)
    d.polygon([(340, 360), (370, 300), (385, 365)], fill=(80, 140, 60, 255))   # algue
    save(img, "vieille_botte")


if __name__ == "__main__":
    fish("sardine", (120, 150, 175), (225, 230, 235), (90, 120, 150), length=0.8, height=0.24)
    fish("maquereau", (40, 110, 120), (225, 230, 225), (40, 90, 100), length=0.82, height=0.28, stripes=(20, 50, 60))
    fish("dorade", (170, 175, 180), (235, 235, 230), (140, 140, 150), length=0.76, height=0.42, band=(220, 170, 50))
    fish("bar", (110, 120, 125), (220, 222, 220), (90, 95, 100), length=0.84, height=0.32)
    fish("poisson_perroquet", (40, 190, 170), (240, 140, 170), (230, 90, 150), length=0.78, height=0.4, spots=(250, 200, 60))
    fish("merou", (120, 85, 55), (190, 160, 120), (95, 65, 40), length=0.86, height=0.42, spots=(70, 50, 30))
    fish("poisson_lune", (230, 190, 60), (250, 230, 150), (220, 150, 40), length=0.66, height=0.7, round_body=True)
    canne()
    botte()
