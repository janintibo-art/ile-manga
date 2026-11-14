"""V146 : peint l'Île Perchée sur la carte de l'archipel (www/assets/textures/carte/archipel.png), dans le
style d'Astralys (tools/carte_v56.py : l'île flottante vue du ciel, son ombre sur la mer, un halo de
nuages) : la prairie dorée ombrée, la terre rouge, les mesas (leurs falaises rayées), le ruisseau et la
mare ; le bourg de Pile-ou-Face (la grand-rue, la rue du Pique, les toits, la place de la Roue) ; le Quai
des Nuées ; la Grande Chaîne et son ponton sur la mer ; la ligne de la Navette jusqu'au Mât de Hautefond.
Le relief vient du jeu : tools/carte_perchee_v146.gd écrit perchee_h.bin et perchee_biome.png.
Lancement (depuis la racine du dépôt) :
    godot --headless --path pcvr -s res://tools/carte_perchee_v146.gd -- /tmp/carte
    python3 pcvr/tools/carte_v146.py /tmp/carte
"""
from pathlib import Path
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import carte_v56 as c56  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
MAP = ROOT / "www" / "assets" / "textures" / "carte" / "archipel.png"
OX, OZ = 1320, 960
CX, CZ = -820.0, 2140.0
MAT = (-938.7, 1654.4)                 # le Mât des Nuées de Hautefond
CHAINE_A = 0.86
QUAI_A = 0.0


def main(src: Path) -> None:
    n = 253
    h2 = np.fromfile(src / "perchee_h.bin", np.float32).reshape(n, n)
    size = 504
    h = np.array(Image.fromarray(h2).resize((size, size), Image.BILINEAR), np.float32)
    land = h > -100
    h = np.where(land, h, 0.0)
    bio = np.asarray(Image.open(src / "perchee_biome.png").convert("RGBA").resize((size, size), Image.BILINEAR), np.float32) / 255.0
    im = Image.open(MAP).convert("RGBA")
    W, H = im.size
    x0, y0 = int(CX - 252 + OX), int(CZ - 252 + OZ)
    rng = np.random.default_rng(14646)
    # l'ombre sur la mer (décalée, le soleil au nord-ouest), puis un halo de nuages
    mask = Image.fromarray((land * 255).astype(np.uint8), "L")
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sh.paste(Image.new("RGBA", (size, size), (14, 30, 60, 95)), (x0 + 50, y0 + 60), mask)
    sh = sh.filter(ImageFilter.GaussianBlur(16))
    im.alpha_composite(sh)
    cl = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dc = ImageDraw.Draw(cl)
    for k in range(46):
        a = k / 46 * math.tau + rng.uniform(-0.05, 0.05)
        r = 232 + rng.uniform(-6, 16)
        x, z = CX + OX + math.cos(a) * r, CZ + OZ + math.sin(a) * r
        rr = rng.uniform(14, 26)
        dc.ellipse((x - rr * 1.3, z - rr, x + rr * 1.3, z + rr), fill=(250, 250, 255, 160))
    cl = cl.filter(ImageFilter.GaussianBlur(5))
    im.alpha_composite(cl)
    # le dessus : la prairie dorée, la terre rouge, la verdure, les rues ; les mesas rayées
    gold = np.array([0.80, 0.70, 0.40])
    img = np.ones((size, size, 3)) * gold
    img = img * (1 - bio[..., 1:2] * 0.85) + np.array([0.72, 0.42, 0.28]) * bio[..., 1:2] * 0.85
    img = img * (1 - bio[..., 2:3] * 0.7) + np.array([0.42, 0.55, 0.28]) * bio[..., 2:3] * 0.7
    img = img * (1 - bio[..., 0:1] * 0.9) + np.array([0.66, 0.5, 0.36]) * bio[..., 0:1] * 0.9
    img = img * (1 - bio[..., 3:4] * 0.9) + np.array([0.7, 0.66, 0.6]) * bio[..., 3:4] * 0.9
    high = np.clip((h - 8.0) / 6.0, 0, 1)[..., None]
    band = (np.sin(h * 0.9) * 0.5 + 0.5)[..., None]
    rock = np.array([0.66, 0.34, 0.2]) * (1 - band * 0.25) + np.array([0.86, 0.6, 0.4]) * band * 0.25
    img = img * (1 - high) + rock * high
    img *= (0.9 + 0.14 * c56.noise(size, size, (4, 8, 16), 0.6)[..., None])
    hs = c56.hillshade(h, 1.0, z=1.6)
    img *= (0.55 + 0.6 * hs[..., None])
    # l'eau : la mare et le ruisseau
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    lx, lz = xx - 252.0, yy - 252.0
    pres = np.hypot(lx + 58.0, lz - 66.0) < 16.0
    ru = [(-92, -30), (-108, -4), (-132, 14), (-158, 22), (-184, 34), (-206, 44), (-226, 50)]
    for (ax, az), (bx, bz) in zip(ru[:-1], ru[1:]):
        dx, dz = bx - ax, bz - az
        t = np.clip(((lx - ax) * dx + (lz - az) * dz) / (dx * dx + dz * dz), 0, 1)
        pres |= np.hypot(lx - ax - t * dx, lz - az - t * dz) < 3.0
    water = (h < -0.9) & land & pres
    img[water] = np.array([0.36, 0.56, 0.62])
    coast = land ^ ndimage.binary_erosion(land, iterations=2)
    img[coast] = np.array([0.28, 0.16, 0.1])
    pap = c56.paper(size, size)
    img = img * (0.74 + 0.26 * pap / pap.max())
    top = Image.fromarray(np.clip(img * 255, 0, 255).astype(np.uint8), "RGB").convert("RGBA")
    im.paste(top, (x0, y0), mask)
    d = ImageDraw.Draw(im)
    ink = (60, 40, 26, 255)

    def P(x, z):
        return (CX + OX + x, CZ + OZ + z)

    # les toits du bourg (rangées le long des rues), la place et sa Roue, la chapelle, le donjon
    roofs = [(178, 70, 52), (120, 96, 72), (150, 120, 84), (96, 112, 120), (172, 140, 96), (110, 70, 52)]
    for (x, w, side) in [(-30, 11, -1), (-15, 14, -1), (3, 13, -1), (26, 20, -1), (-30, 12, 1), (-15, 10, 1), (4, 18, 1), (27, 16, 1),
                         (95, 18, -1), (114, 12, -1), (130, 11, -1), (147, 14, -1), (94, 14, 1), (111, 12, 1), (127, 12, 1), (147, 18, 1)]:
        z0 = side * 10.6
        z1 = side * (10.6 + 14)
        c = roofs[int(abs(x)) % len(roofs)]
        d.rectangle([P(x - w / 2, min(z0, z1)), P(x + w / 2, max(z0, z1))], fill=c + (255,), outline=ink)
    for (z, side) in [(-36, -1), (-54, -1), (-71, -1), (-36, 1), (-54, 1), (-71, 1), (34, -1), (52, -1), (69, -1), (36, 1), (55, 1), (71, 1)]:
        x0b = 60 + side * 9.1
        x1b = 60 + side * 21
        c = roofs[int(abs(z)) % len(roofs)]
        d.rectangle([P(min(x0b, x1b), z - 5.5), P(max(x0b, x1b), z + 5.5)], fill=c + (255,), outline=ink)
    d.ellipse([P(40, -20), P(80, 20)], fill=(196, 190, 176, 255), outline=ink, width=2)
    d.ellipse([P(55, -5), P(65, 5)], fill=(220, 180, 70, 255), outline=ink, width=2)
    d.rectangle([P(54.5, -118), P(65.5, -100)], fill=(150, 120, 100, 255), outline=ink, width=2)
    d.ellipse([P(146, -42), P(158, -30)], fill=(150, 130, 116, 255), outline=ink, width=2)
    # le Quai des Nuées (une aire de planches au-delà du bord est)
    d.rectangle([P(226, -13), P(262, 13)], fill=(170, 128, 84, 255), outline=ink, width=2)
    # la Grande Chaîne (sa potence) et le ponton, sur la mer
    cr = 236 + 9
    cx, cz = math.cos(CHAINE_A) * cr, math.sin(CHAINE_A) * cr
    d.line([P(cx * 0.93, cz * 0.93), P(cx, cz)], fill=ink, width=5)
    px, pz = cx - math.cos(CHAINE_A) * 6, cz - math.sin(CHAINE_A) * 6
    d.rectangle([P(px - 9, pz - 7), P(px + 9, pz + 7)], fill=(150, 112, 72, 255), outline=ink, width=2)
    d.ellipse([P(cx - 3, cz - 3), P(cx + 3, cz + 3)], fill=(90, 90, 96, 255))
    # la ligne de la Navette des Nuées (pointillés), jusqu'au Mât de Hautefond
    ax, az = CX + OX + 250, CZ + OZ
    bx, bz = MAT[0] + OX, MAT[1] + OZ
    m = 18
    for k in range(m):
        if k % 2 == 0:
            d.line([(ax + (bx - ax) * k / m, az + (bz - az) * k / m), (ax + (bx - ax) * (k + 1) / m, az + (bz - az) * (k + 1) / m)], fill=(200, 50, 40, 255), width=3)
    d.ellipse((bx - 6, bz - 6, bx + 6, bz + 6), fill=(200, 50, 40, 255), outline=ink, width=2)
    im.convert("RGB").save(MAP, optimize=True)
    print("archipel.png : l'Île Perchée est sur la carte")


if __name__ == "__main__":
    main(Path(sys.argv[1] if len(sys.argv) > 1 else "/tmp/carte"))
