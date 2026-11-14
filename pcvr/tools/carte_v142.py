"""V142 : peint l'Île des Géants sur la carte de l'archipel (www/assets/textures/carte/archipel.png),
dans le style de la carte (tools/carte_v56.py) : les hauts-fonds turquoise qui se fondent dans le bleu
du large, la grève, la prairie ombrée, le trait de côte à l'encre, les lignes de houle, le papier ; et,
dessinés par-dessus : la maison des Grandpré et la grange (leurs toits), le potager (quatre planches),
le champ de blé, le verger, la mare, le moulin (ses quatre ailes), le ponton.
Le relief vient du jeu : tools/carte_geants_v142.gd écrit geants_h.bin et geants_biome.png.
Lancement (depuis la racine du dépôt) :
    godot --headless --path pcvr -s res://tools/carte_geants_v142.gd -- /tmp/carte
    python3 pcvr/tools/carte_v142.py /tmp/carte
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
OX, OZ = 1320, 960                 # l'origine de la carte (x = -1320, z = -960), 1 px = 1 m
CX, CZ, HALF = 800.0, 2100.0, 300.0


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def main(src: Path) -> None:
    n = 301
    h2 = np.fromfile(src / "geants_h.bin", np.float32).reshape(n, n)
    size = int(HALF * 2)
    h = np.array(Image.fromarray(h2).resize((size, size), Image.BICUBIC), np.float32)
    bio = np.asarray(Image.open(src / "geants_biome.png").convert("RGBA").resize((size, size), Image.BILINEAR), np.float32) / 255.0
    im = Image.open(MAP).convert("RGB")
    x0, y0 = int(CX - HALF + OX), int(CZ - HALF + OZ)
    old = np.asarray(im.crop((x0, y0, x0 + size, y0 + size)), np.float32) / 255.0
    land = h > 0.05
    sea_d = np.clip(-h, 0, 60)
    sea = c56.ramp(sea_d, [(0, (150, 214, 210)), (3, (112, 190, 200)), (10, (70, 150, 184)), (22, (44, 108, 160)), (40, (30, 76, 130)), (60, (22, 56, 104))])
    tex = c56.noise(size, size, (8, 16, 32, 64), 0.6)
    sea *= (0.94 + 0.1 * tex[..., None])
    iso = np.zeros((size, size), bool)
    for lv in (5, 10, 20):
        m = sea_d > lv
        iso |= m ^ ndimage.binary_erosion(m)
    sea[iso & ~land] = sea[iso & ~land] * 0.82
    hl = np.clip(h, 0, 140)
    lands = c56.ramp(hl, [(0, (232, 214, 160)), (0.9, (230, 212, 160)), (1.1, (222, 210, 186)), (1.6, (214, 206, 176)), (4, (160, 182, 110)), (14, (118, 152, 86)), (30, (104, 128, 76)),
                          (55, (140, 120, 90))])
    # la prairie des géants, plus verte ; la terre battue, les planches labourées, le sous-bois du verger
    lands = lands * (1 - bio[..., 0:1] * 0.8) + np.array([0.72, 0.62, 0.44]) * bio[..., 0:1] * 0.8
    lands = lands * (1 - bio[..., 1:2] * 0.85) + np.array([0.5, 0.36, 0.24]) * bio[..., 1:2] * 0.85
    lands = lands * (1 - bio[..., 2:3] * 0.5) + np.array([0.3, 0.45, 0.22]) * bio[..., 2:3] * 0.5
    lands = lands * (1 - bio[..., 3:4] * 0.8) + np.array([0.7, 0.68, 0.62]) * bio[..., 3:4] * 0.8
    lands *= (0.9 + 0.14 * c56.noise(size, size, (4, 8, 16), 0.6)[..., None])
    hs = c56.hillshade(h, 1.0, z=1.6)
    lands *= (0.55 + 0.6 * hs[..., None])
    img = np.where(land[..., None], lands, sea)
    dist = ndimage.distance_transform_edt(~land)
    for r, a in ((5.0, 0.55), (11.0, 0.32), (18.0, 0.18)):
        ring = np.abs(dist - r) < 0.9
        img[ring & ~land] = img[ring & ~land] * (1 - a) + np.array([0.95, 0.97, 0.96]) * a
    coast = land ^ ndimage.binary_erosion(land, iterations=2)
    img[coast] = np.array([0.24, 0.18, 0.12])
    pap = c56.paper(size, size)
    img = img * (0.72 + 0.28 * pap / pap.max())
    # le large reste celui de la carte : on ne repeint que l'île et ses hauts-fonds (fondu vers 28 m de fond)
    yy, xx = np.mgrid[0:size, 0:size]
    edge = np.minimum(np.minimum(xx, size - 1 - xx), np.minimum(yy, size - 1 - yy)).astype(np.float32)
    w = np.where(land, 1.0, 1.0 - smooth(18.0, 30.0, sea_d)) * smooth(0.0, 30.0, edge)
    out = old * (1 - w[..., None]) + np.clip(img, 0, 1) * w[..., None]
    patch = Image.fromarray(np.clip(out * 255, 0, 255).astype(np.uint8), "RGB").convert("RGBA")
    d = ImageDraw.Draw(patch)

    def P(x, z):
        return (x + HALF, z + HALF)

    ink = (60, 44, 30, 255)
    # le champ de blé (doré, hachuré), le potager (quatre planches brunes, des rangs verts)
    d.rectangle([P(-28, 66), P(44, 136)], fill=(214, 182, 96, 255), outline=ink)
    for k in range(-28, 44, 6):
        d.line([P(k, 66), P(k + 6, 136)], fill=(184, 150, 72, 255), width=1)
    d.rectangle([P(62, -52), P(152, 52)], outline=(236, 232, 220, 255), width=2)
    for r in [(67, -47, 103, -5), (111, -47, 147, -5), (67, 5, 103, 47), (111, 5, 147, 47)]:
        d.rectangle([P(r[0], r[1]), P(r[2], r[3])], fill=(120, 86, 58, 255), outline=ink)
        for x in range(int(r[0]) + 2, int(r[2]), 4):
            d.line([P(x, r[1] + 2), P(x, r[3] - 2)], fill=(92, 140, 70, 255), width=1)
    # la maison (le toit rouge, le faîtage) et la grange (le chaume), la cheminée
    d.rectangle([P(-46, -32), P(46, 32)], fill=(178, 76, 58, 255), outline=ink, width=2)
    d.line([P(-46, 0), P(46, 0)], fill=(120, 48, 36, 255), width=2)
    d.rectangle([P(18, 2), P(28, 10)], fill=(150, 146, 140, 255), outline=ink)
    d.rectangle([P(-129, -18), P(-67, 26)], fill=(196, 160, 96, 255), outline=ink, width=2)
    d.line([P(-129, 4), P(-67, 4)], fill=(150, 116, 64, 255), width=2)
    # le verger (des couronnes rondes), la mare (bleue, ses nénuphars)
    rng = np.random.default_rng(142)
    for k in range(15):
        a = rng.uniform(0, math.tau)
        rr = math.sqrt(rng.uniform()) * 52
        x, z = 110 + math.cos(a) * rr, 120 + math.sin(a) * rr
        d.ellipse([P(x - 6, z - 6), P(x + 6, z + 6)], fill=(70, 120, 56, 255), outline=(40, 70, 34, 255))
        d.ellipse([P(x - 1.5, z - 3), P(x + 1.5, z)], fill=(200, 40, 30, 255))
    d.ellipse([P(-148, 104), P(-76, 152)], fill=(96, 150, 170, 255), outline=ink, width=2)
    for k in range(9):
        a = rng.uniform(0, math.tau)
        rr = math.sqrt(rng.uniform()) * 0.75
        x, z = -112 + math.cos(a) * 36 * rr, 128 + math.sin(a) * 24 * rr
        d.ellipse([P(x - 2.4, z - 2.4), P(x + 2.4, z + 2.4)], fill=(80, 140, 70, 255))
    # le moulin : la tour blanche, les quatre ailes
    mx, mz = -150, -100
    d.ellipse([P(mx - 13, mz - 13), P(mx + 13, mz + 13)], fill=(238, 234, 222, 255), outline=ink, width=2)
    fx, fz = 0.62, 0.78
    hx, hz = mx + fx * 16, mz + fz * 16
    for k in range(4):
        a = math.tau * k / 4 + 0.3
        ex, ez = math.cos(a) * 30, math.sin(a) * 30
        # les ailes, vues du ciel : de longs traits à travers le moyeu (dans le plan des ailes)
        sx, sz = -fz, fx
        d.line([P(hx, hz), P(hx + sx * ex, hz + sz * ex)], fill=ink, width=3)
    d.ellipse([P(hx - 3, hz - 3), P(hx + 3, hz + 3)], fill=ink)
    # le ponton
    d.rectangle([P(34, -252), P(38, -222)], fill=(150, 112, 72, 255), outline=ink)
    patch = patch.convert("RGB")
    im.paste(patch, (x0, y0))
    im.save(MAP, optimize=True)
    print("archipel.png : l'Île des Géants est sur la carte")


if __name__ == "__main__":
    main(Path(sys.argv[1] if len(sys.argv) > 1 else "/tmp/carte"))
