"""V90 : les peintures du Clan (la Grotte aux Peintures) et les icônes des objets de l'île, en pixel art.

  www/assets/textures/pixel90/peinture_*.png   64 × 40 pixels, ocre, rouge, noir de charbon, blanc
                                               de craie, sur fond transparent (le mur se voit dessous) ;
  www/assets/textures/items/<objet>.png        128 × 128 (dessinées en 32 × 32, agrandies sans flou).
"""
from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image

OCRE = (196, 108, 46, 255)
ROUGE = (160, 44, 30, 255)
NOIR = (30, 24, 22, 255)
CRAIE = (236, 228, 206, 255)
JAUNE = (224, 180, 60, 255)


class Toile:
    def __init__(self, w=64, h=40, seed=1):
        self.a = np.zeros((h, w, 4), np.uint8)
        self.w, self.h = w, h
        self.rng = np.random.default_rng(seed)
        self.parfait = False

    def px(self, x, y, c):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            # la peinture n'est pas parfaite : quelques pixels manquent
            if self.parfait or self.rng.random() < 0.94:
                self.a[y, x] = c

    def ligne(self, x0, y0, x1, y1, c, e=1):
        n = int(max(abs(x1 - x0), abs(y1 - y0)) * 1.5) + 1
        for t in np.linspace(0, 1, n):
            x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            for dx in range(e):
                for dy in range(e):
                    self.px(x + dx, y + dy, c)

    def disque(self, cx, cy, r, c):
        for y in range(int(cy - r - 1), int(cy + r + 2)):
            for x in range(int(cx - r - 1), int(cx + r + 2)):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    self.px(x, y, c)

    def ellipse(self, cx, cy, rx, ry, c):
        for y in range(int(cy - ry - 1), int(cy + ry + 2)):
            for x in range(int(cx - rx - 1), int(cx + rx + 2)):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                    self.px(x, y, c)

    def bonhomme(self, x, y, c, lance=False, bras_haut=False):
        self.disque(x, y - 7, 1.5, c)
        self.ligne(x, y - 5, x, y - 1, c)
        self.ligne(x, y - 1, x - 2, y + 3, c)
        self.ligne(x, y - 1, x + 2, y + 3, c)
        if bras_haut:
            self.ligne(x, y - 4, x - 3, y - 7, c)
            self.ligne(x, y - 4, x + 3, y - 7, c)
        else:
            self.ligne(x, y - 4, x - 3, y - 2, c)
            self.ligne(x, y - 4, x + 3, y - 3, c)
        if lance:
            self.ligne(x + 3, y - 1, x + 7, y - 9, NOIR)

    def save(self, path, scale=1):
        im = Image.fromarray(self.a, "RGBA")
        if scale > 1:
            im = im.resize((self.w * scale, self.h * scale), Image.NEAREST)
        im.save(path)


def chasse():
    t = Toile(seed=11)
    # un raptor qui court, trois chasseurs avec des lances
    t.ellipse(44, 22, 7, 3, OCRE)
    t.ligne(50, 21, 56, 15, OCRE, 2)
    t.ellipse(57, 14, 3, 1.5, OCRE)
    t.ligne(37, 22, 28, 18, OCRE)
    t.ligne(42, 24, 40, 30, ROUGE)
    t.ligne(46, 24, 48, 30, ROUGE)
    for x in (10, 17, 24):
        t.bonhomme(x, 28, NOIR, lance=True)
    return t


def longcou():
    t = Toile(seed=12)
    t.ellipse(30, 26, 11, 5, OCRE)
    t.ligne(39, 23, 50, 6, OCRE, 2)
    t.ellipse(52, 5, 3, 2, OCRE)
    t.ligne(20, 26, 8, 30, OCRE, 2)
    for x in (24, 28, 34, 37):
        t.ligne(x, 30, x, 36, ROUGE, 2)
    t.bonhomme(55, 34, NOIR, bras_haut=True)
    t.bonhomme(60, 34, NOIR)
    return t


def cornes():
    t = Toile(seed=13)
    t.ellipse(30, 24, 10, 6, ROUGE)
    t.ellipse(44, 20, 5, 7, OCRE)
    t.ligne(46, 16, 54, 10, CRAIE)
    t.ligne(46, 19, 55, 15, CRAIE)
    t.ligne(48, 23, 54, 22, CRAIE)
    for x in (23, 27, 33, 37):
        t.ligne(x, 29, x, 35, ROUGE, 2)
    t.bonhomme(8, 34, NOIR, bras_haut=True)
    return t


def grosse_dent():
    t = Toile(seed=14)
    t.ellipse(28, 22, 11, 7, ROUGE)
    t.ellipse(44, 13, 8, 5, ROUGE)
    t.ligne(37, 17, 52, 19, ROUGE, 2)
    for x in range(39, 52, 3):
        t.px(x, 16, CRAIE)
        t.px(x, 19, CRAIE)
    t.px(46, 10, CRAIE)
    t.ligne(18, 22, 4, 28, ROUGE, 2)
    t.ligne(26, 28, 24, 38, NOIR, 2)
    t.ligne(32, 28, 34, 38, NOIR, 2)
    t.ligne(38, 22, 40, 25, NOIR)
    for x in (54, 58, 61):
        t.bonhomme(x, 36, NOIR, bras_haut=True)
    return t


def volcan():
    t = Toile(seed=15)
    for y in range(14, 40):
        w = (y - 14) * 0.9 + 2
        t.ligne(32 - w, y, 32 + w, y, NOIR)
    for k in range(7):
        t.ligne(32, 13, 32 + (k - 3) * 3, 4 - abs(k - 3), ROUGE, 1)
    t.ligne(31, 14, 26, 30, ROUGE, 2)
    t.disque(55, 8, 4, JAUNE)
    for k in range(8):
        a = k / 8 * 2 * math.pi
        t.ligne(55 + math.cos(a) * 5, 8 + math.sin(a) * 5, 55 + math.cos(a) * 7, 8 + math.sin(a) * 7, JAUNE)
    return t


def mains():
    t = Toile(seed=16)
    rng = np.random.default_rng(3)
    for k in range(9):
        cx, cy = rng.uniform(8, 56), rng.uniform(8, 32)
        c = [OCRE, ROUGE, CRAIE][k % 3]
        t.ellipse(cx, cy, 3, 3.5, c)
        for j in range(5):
            a = -2.4 + j * 0.45
            t.ligne(cx + math.cos(a) * 3, cy + math.sin(a) * 3, cx + math.cos(a) * 6, cy + math.sin(a) * 6.5, c)
    return t


def lisse():
    """Le héros, peint par Ocre : rond, lisse… presque. (Ocre a beaucoup essayé.)"""
    t = Toile(seed=17)
    t.disque(32, 10, 5.5, CRAIE)
    t.px(30, 9, NOIR)
    t.px(34, 9, NOIR)
    t.ligne(30, 12, 34, 12, NOIR)
    t.ellipse(32, 23, 5, 7, OCRE)
    t.ligne(27, 20, 20, 15, OCRE, 2)
    t.ligne(37, 20, 44, 14, OCRE, 2)
    t.ligne(44, 14, 50, 4, CRAIE, 1)
    t.ligne(29, 29, 27, 38, OCRE, 2)
    t.ligne(35, 29, 37, 38, OCRE, 2)
    # autour : les petits carrés du Clan qui regardent, étonnés
    for x, y in ((8, 34), (14, 34), (52, 34), (58, 34)):
        t.bonhomme(x, y, NOIR, bras_haut=True)
    for k in range(6):
        t.ligne(18 + k * 6, 2, 19 + k * 6, 3, JAUNE)
    return t


def victoire():
    t = Toile(seed=18)
    t.ellipse(30, 30, 16, 5, ROUGE)
    t.ellipse(49, 31, 7, 4, ROUGE)
    t.ligne(14, 30, 4, 34, ROUGE, 2)
    for k, (x, y) in enumerate(((54, 22), (58, 17), (62, 12))):
        t.ligne(x, y, x + 3, y, CRAIE)
        t.ligne(x + 3, y, x, y + 3, CRAIE)
        t.ligne(x, y + 3, x + 3, y + 3, CRAIE)
    t.disque(30, 12, 3, CRAIE)
    t.ellipse(30, 19, 3, 4, OCRE)
    t.ligne(30, 23, 28, 25, OCRE)
    t.ligne(30, 23, 32, 25, OCRE)
    t.ligne(27, 17, 23, 11, OCRE)
    t.ligne(33, 17, 37, 11, OCRE)
    for x in (6, 12, 52, 58):
        t.bonhomme(x, 14, NOIR, bras_haut=True)
    return t


PEINTURES = {"chasse": chasse, "longcou": longcou, "cornes": cornes, "grosse_dent": grosse_dent, "volcan": volcan,
             "mains": mains, "lisse": lisse, "victoire": victoire}


# =========================================================================== les icônes

def icone_dent():
    t = Toile(32, 32, seed=21)
    t.parfait = True
    for y in range(4, 29):
        w = 6.5 * (1 - (y - 4) / 26.0) ** 0.7
        cx = 13 + (y - 4) * 0.28
        for x in range(int(cx - w), int(cx + w) + 1):
            c = (240, 232, 205, 255) if x < cx + w * 0.3 else (205, 192, 160, 255)
            t.px(x, y, c)
    for y in range(4, 8):
        t.ligne(7, y, 20, y, (176, 120, 70, 255))
    t.ligne(9, 2, 18, 2, (120, 80, 50, 255))
    t.ligne(18, 2, 24, 0, (120, 80, 50, 255))
    return t


def icone_galette():
    t = Toile(32, 32, seed=22)
    t.parfait = True
    t.ellipse(16, 18, 13, 9, (190, 140, 72, 255))
    t.ellipse(16, 17, 11, 7, (214, 168, 92, 255))
    rng = np.random.default_rng(4)
    for k in range(10):
        x, y = rng.uniform(7, 25), rng.uniform(12, 22)
        t.px(x, y, (80, 140, 50, 255))
        t.px(x + 1, y, (60, 110, 40, 255))
    for k in range(5):
        x, y = rng.uniform(8, 24), rng.uniform(12, 22)
        t.px(x, y, (130, 80, 40, 255))
    return t


def icone_peinture():
    t = Toile(32, 32, seed=23)
    t.parfait = True
    t.ellipse(16, 17, 14, 12, (128, 120, 112, 255))
    t.ellipse(16, 16, 12, 10, (156, 148, 136, 255))
    t.disque(16, 10, 3, CRAIE)
    t.ellipse(16, 18, 3, 4, OCRE)
    t.ligne(13, 16, 9, 12, OCRE)
    t.ligne(19, 16, 23, 12, OCRE)
    t.ligne(15, 22, 14, 26, OCRE)
    t.ligne(17, 22, 18, 26, OCRE)
    t.px(15, 9, NOIR)
    t.px(17, 9, NOIR)
    return t


def build(root: Path):
    out = root / "www" / "assets" / "textures" / "pixel90"
    out.mkdir(parents=True, exist_ok=True)
    for k, f in PEINTURES.items():
        f().save(out / f"peinture_{k}.png")
    items = root / "www" / "assets" / "textures" / "items"
    icone_dent().save(items / "dent_grosse_dent.png", 4)
    icone_galette().save(items / "galette_fougere.png", 4)
    icone_peinture().save(items / "peinture_clan.png", 4)
    print(f"peintures : {len(PEINTURES)} ; icônes : 3")
