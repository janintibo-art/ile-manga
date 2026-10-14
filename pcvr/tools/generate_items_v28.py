"""V28 : icônes de l'inventaire et cœurs de vie, dessinés ici (libres de droits).

Chaque icône est dessinée en 512 px avec ombrage, puis réduite en 128 px (anticrénelage).
Lancement : python3 pcvr/tools/generate_items_v28.py (depuis la racine du dépôt).
"""
from pathlib import Path
import math

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "items"
OUT.mkdir(parents=True, exist_ok=True)
S = 512


def canvas():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def shaded_ellipse(img, box, base, light=(0.35, 0.3), gloss=True):
    """Ellipse ombrée en volume : centre clair vers la lumière, bord sombre."""
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    yy, xx = np.mgrid[0:h, 0:w]
    u = (xx + 0.5) / w * 2 - 1
    v = (yy + 0.5) / h * 2 - 1
    r2 = u * u + v * v
    inside = r2 <= 1.0
    z = np.sqrt(np.clip(1 - r2, 0, 1))
    lx, ly = -light[0], -light[1]
    lz = math.sqrt(max(0.0, 1 - lx * lx - ly * ly))
    lam = np.clip(u * lx + v * ly + z * lz, 0, 1)
    shade = 0.35 + 0.75 * lam
    col = np.array(base, dtype=np.float32)[None, None, :] / 255.0 * shade[..., None]
    if gloss:
        spec = np.clip(lam, 0, 1) ** 28 * 0.8
        col = col + spec[..., None]
    rgba = np.zeros((h, w, 4), dtype=np.float32)
    rgba[..., :3] = np.clip(col, 0, 1)
    edge = np.clip((1.0 - np.sqrt(r2)) * min(w, h) * 0.5, 0, 1)
    rgba[..., 3] = np.where(inside, edge, 0)
    layer = Image.fromarray((rgba * 255).astype(np.uint8), "RGBA")
    img.alpha_composite(layer, (int(x0), int(y0)))


def outline(img, width=10, color=(20, 14, 10, 230)):
    """Contour sombre autour de la silhouette, comme les icônes de jeu."""
    a = img.split()[3]
    grown = a.filter(ImageFilter.MaxFilter(width * 2 + 1))
    back = Image.new("RGBA", img.size, color)
    back.putalpha(grown)
    back.alpha_composite(img)
    return back


def shadow(img):
    a = img.split()[3].filter(ImageFilter.GaussianBlur(14))
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    dark = Image.new("RGBA", img.size, (0, 0, 0, 120))
    sh.paste(dark, (10, 16), a)
    sh.alpha_composite(img)
    return sh


def save(img, name):
    img = shadow(outline(img))
    img.resize((128, 128), Image.LANCZOS).save(OUT / f"{name}.png", optimize=True)
    print(name)


def stick_polygon(d, p0, p1, w, fill):
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    L = math.hypot(dx, dy)
    nx, ny = -dy / L * w / 2, dx / L * w / 2
    d.polygon([(p0[0] + nx, p0[1] + ny), (p1[0] + nx, p1[1] + ny), (p1[0] - nx, p1[1] - ny), (p0[0] - nx, p0[1] - ny)], fill=fill)


def pomme():
    img = canvas()
    shaded_ellipse(img, (96, 140, 300, 430), (200, 30, 30))
    shaded_ellipse(img, (212, 140, 416, 430), (190, 28, 26))
    shaded_ellipse(img, (150, 150, 362, 440), (214, 40, 34))
    d = ImageDraw.Draw(img)
    stick_polygon(d, (256, 168), (276, 88), 16, (92, 60, 30, 255))
    leaf = canvas()
    shaded_ellipse(leaf, (270, 70, 420, 140), (70, 150, 50), gloss=False)
    leaf = leaf.rotate(18, center=(345, 105))
    img.alpha_composite(leaf)
    save(img, "pomme")


def champignon():
    img = canvas()
    d = ImageDraw.Draw(img)
    stem = canvas()
    shaded_ellipse(stem, (196, 230, 316, 460), (236, 226, 204), gloss=False)
    img.alpha_composite(stem)
    cap = canvas()
    shaded_ellipse(cap, (70, 90, 442, 330), (150, 72, 38))
    cut = Image.new("L", (S, S), 0)
    ImageDraw.Draw(cut).rectangle((0, 0, S, 268), fill=255)
    cap.putalpha(Image.fromarray(np.minimum(np.array(cap.split()[3]), np.array(cut))))
    img.alpha_composite(cap)
    for (x, y, r) in [(170, 170, 22), (260, 138, 18), (340, 186, 20), (220, 222, 14), (300, 230, 12)]:
        d.ellipse((x - r, y - r, x + r, y + r), fill=(240, 228, 200, 235))
    d.rectangle((86, 262, 426, 274), fill=(214, 190, 160, 255))
    save(img, "champignon")


def baies():
    img = canvas()
    d = ImageDraw.Draw(img)
    stick_polygon(d, (256, 80), (200, 230), 10, (70, 90, 40, 255))
    stick_polygon(d, (256, 80), (320, 220), 10, (70, 90, 40, 255))
    for (x, y) in [(150, 250), (230, 230), (310, 240), (190, 320), (270, 310), (350, 320), (230, 390), (310, 390)]:
        shaded_ellipse(img, (x - 52, y - 52, x + 52, y + 52), (70, 40, 130))
    save(img, "baies")


def baton():
    img = canvas()
    d = ImageDraw.Draw(img)
    stick_polygon(d, (100, 420), (420, 92), 48, (122, 84, 48, 255))
    stick_polygon(d, (300, 215), (380, 250), 22, (122, 84, 48, 255))
    for k in range(9):
        t = k / 9
        x, y = 110 + 300 * t, 410 - 308 * t
        stick_polygon(d, (x, y), (x + 26, y - 26), 5, (88, 58, 32, 200))
    d.ellipse((400, 70, 440, 112), fill=(196, 160, 110, 255))
    save(img, "baton")


def caillou():
    img = canvas()
    shaded_ellipse(img, (90, 170, 430, 420), (140, 140, 136), gloss=False)
    d = ImageDraw.Draw(img)
    d.line((180, 260, 250, 300, 300, 290), fill=(96, 96, 92, 200), width=7)
    save(img, "caillou")


def coquillage():
    img = canvas()
    shaded_ellipse(img, (90, 110, 422, 420), (240, 200, 186))
    d = ImageDraw.Draw(img)
    for k in range(-4, 5):
        a = math.radians(90 + k * 17)
        d.line((256, 440, 256 + 190 * math.cos(a), 440 - 300 * math.sin(a)), fill=(200, 140, 130, 220), width=10)
    d.polygon([(196, 400), (316, 400), (290, 460), (222, 460)], fill=(226, 180, 166, 255))
    save(img, "coquillage")


def epee_bois():
    img = canvas()
    d = ImageDraw.Draw(img)
    stick_polygon(d, (150, 362), (430, 82), 54, (196, 156, 102, 255))
    d.polygon([(430, 82), (452, 60), (450, 104)], fill=(196, 156, 102, 255))
    stick_polygon(d, (166, 346), (412, 100), 10, (232, 200, 150, 255))
    stick_polygon(d, (104, 300), (210, 406), 34, (120, 78, 42, 255))
    stick_polygon(d, (70, 442), (150, 362), 34, (80, 50, 30, 255))
    for k in range(4):
        x, y = 80 + k * 18, 432 - k * 18
        stick_polygon(d, (x - 14, y - 14), (x + 14, y + 14), 6, (150, 110, 70, 255))
    d.ellipse((50, 440, 88, 478), fill=(120, 78, 42, 255))
    save(img, "epee_bois")


def piece():
    img = canvas()
    shaded_ellipse(img, (110, 110, 402, 402), (214, 160, 60))
    d = ImageDraw.Draw(img)
    d.ellipse((160, 160, 352, 352), outline=(150, 100, 30, 255), width=12)
    d.polygon([(256, 196), (276, 246), (330, 250), (288, 284), (302, 336), (256, 306), (210, 336), (224, 284), (182, 250), (236, 246)], fill=(170, 116, 36, 255))
    save(img, "piece")


def boussole():
    img = canvas()
    shaded_ellipse(img, (70, 70, 442, 442), (190, 146, 60))
    d = ImageDraw.Draw(img)
    d.ellipse((120, 120, 392, 392), fill=(236, 226, 200, 255))
    for k in range(16):
        a = k * math.pi / 8
        r0 = 118 if k % 4 else 100
        d.line((256 + math.cos(a) * r0, 256 + math.sin(a) * r0, 256 + math.cos(a) * 134, 256 + math.sin(a) * 134), fill=(90, 70, 40, 255), width=6 if k % 4 == 0 else 3)
    d.polygon([(256, 140), (276, 256), (236, 256)], fill=(196, 30, 24, 255))
    d.polygon([(256, 372), (276, 256), (236, 256)], fill=(60, 60, 70, 255))
    d.ellipse((244, 244, 268, 268), fill=(180, 140, 60, 255))
    d.ellipse((236, 40, 276, 80), outline=(160, 120, 50, 255), width=10)
    save(img, "boussole")


def heart(fill_ratio, name):
    img = canvas()
    m = Image.new("L", (S, S), 0)
    md = ImageDraw.Draw(m)
    md.ellipse((70, 90, 270, 290), fill=255)
    md.ellipse((242, 90, 442, 290), fill=255)
    md.polygon([(84, 230), (428, 230), (256, 440)], fill=255)
    empty = Image.new("RGBA", (S, S), (60, 30, 34, 200))
    img.paste(empty, (0, 0), m)
    if fill_ratio > 0:
        full = canvas()
        shaded_ellipse(full, (40, 40, 472, 472), (226, 36, 52))
        cut = Image.new("L", (S, S), 0)
        ImageDraw.Draw(cut).rectangle((0, 0, int(S * fill_ratio), S), fill=255)
        mask = Image.fromarray(np.minimum(np.array(m), np.array(cut)))
        img.paste(full, (0, 0), mask)
    save(img, name)


if __name__ == "__main__":
    pomme()
    champignon()
    baies()
    baton()
    caillou()
    coquillage()
    epee_bois()
    piece()
    boussole()
    heart(1.0, "coeur_plein")
    heart(0.5, "coeur_moitie")
    heart(0.0, "coeur_vide")
