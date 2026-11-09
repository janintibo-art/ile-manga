"""V124 : les textures de l'intérieur du château du comte (Sombreval), dessinées ici.

  textures/chateau/livres.png         des dos de livres anciens, trois rangées par mètre (cuir bordeaux,
                                      vert bouteille, bleu nuit, brun, noir ; nervures et titres dorés,
                                      quelques livres penchés, des vides) : 1 024 × 1 024, 1 m × 1 m.
  textures/chateau/vitrail_comte.png  un vitrail gothique en ogive (fond transparent hors de l'ogive) :
                                      des verres rouge sang, violets, bleu nuit et ambre sertis de plomb,
                                      un croissant de lune pâle et une chauve-souris noire au centre.
  textures/chateau/portrait_comte.png le portrait du comte (une huile très sombre : un homme grand et maigre,
                                      la peau blanche, les cheveux noirs plaqués en pointe sur le front, le
                                      grand col dressé de sa cape doublée de rouge) ; ses yeux sont des
                                      perles rouges posées par le jeu sur la toile : 512 × 672.
  textures/chateau/toile_peinte.png   la toile d'un vieux tableau sombre (un paysage de nuit, la lune
                                      derrière les nuages, des collines noires, un château) : 512 × 384.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_chateau_v124.py
"""
from pathlib import Path
import math

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parents[2] / "www" / "assets" / "textures" / "chateau"
RNG = np.random.default_rng(124)


def grain(w, h, amp, blur=1.2):
    n = RNG.normal(0.0, 1.0, (h, w)).astype(np.float32)
    im = Image.fromarray(np.uint8(np.clip(128 + n * 40, 0, 255)), "L").filter(ImageFilter.GaussianBlur(blur))
    return (np.asarray(im, np.float32) - 128.0) / 40.0 * amp


# =================================================================== les livres

CUIRS = [(92, 22, 26), (70, 16, 20), (28, 52, 34), (22, 40, 30), (26, 32, 58), (18, 24, 44), (78, 50, 30),
         (58, 36, 22), (30, 24, 20), (16, 14, 14), (100, 70, 40), (60, 20, 44)]


def livres():
    W = 1024
    img = np.zeros((W, W, 3), np.float32)
    img[:] = (10, 8, 7)
    rows = 3
    rh = W // rows
    d = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    canvas = Image.fromarray(np.uint8(img))
    d = ImageDraw.Draw(canvas)
    for r in range(rows):
        y_floor = (r + 1) * rh - 22                     # le haut de la planche (dessinée par le jeu)
        x = int(RNG.integers(0, 12))
        while x < W - 6:
            bw = int(RNG.integers(16, 46))
            if RNG.random() < 0.06:                     # un vide
                x += int(RNG.integers(20, 60))
                continue
            bh = int(rh * RNG.uniform(0.55, 0.86))
            col = np.array(CUIRS[int(RNG.integers(0, len(CUIRS)))], np.float32) * RNG.uniform(0.75, 1.2)
            lean = 0
            if RNG.random() < 0.07 and x + bw + 30 < W:
                lean = int(RNG.integers(10, 26))
            top = y_floor - bh
            poly = [(x, y_floor), (x + bw, y_floor), (x + bw + lean, top), (x + lean, top)]
            d.polygon(poly, fill=tuple(int(c) for c in col))
            # l'arrondi du dos : plus clair au milieu
            for k in range(bw):
                t = k / max(bw - 1, 1)
                f = 0.62 + 0.55 * math.sin(t * math.pi)
                c2 = tuple(int(min(255, c * f)) for c in col)
                d.line([(x + k, y_floor), (x + k + lean, top)], fill=c2)
            # les nervures et les filets dorés
            gold = (int(RNG.uniform(150, 200)), int(RNG.uniform(115, 150)), int(RNG.uniform(45, 70)))
            nb = int(RNG.integers(2, 5))
            for b in range(nb):
                yy = top + 10 + b * (bh - 20) / max(nb, 1) * RNG.uniform(0.3, 0.45)
                for dy in (0, 5):
                    fx = lean * (y_floor - (yy + dy)) / max(bh, 1)
                    d.line([(x + fx + 1, yy + dy), (x + bw + fx - 1, yy + dy)], fill=gold, width=2)
            # le titre (de petits traits dorés)
            if bw > 20 and RNG.random() < 0.8:
                ty = top + bh * RNG.uniform(0.35, 0.5)
                for k in range(int(RNG.integers(3, 7))):
                    yy = ty + k * 7
                    fx = lean * (y_floor - yy) / max(bh, 1)
                    w2 = bw * RNG.uniform(0.25, 0.6)
                    d.line([(x + fx + bw / 2 - w2 / 2, yy), (x + fx + bw / 2 + w2 / 2, yy)], fill=gold, width=1)
            x += bw + lean + int(RNG.integers(0, 3))
    a = np.asarray(canvas, np.float32)
    # la poussière et l'usure
    a *= (1.0 + grain(W, W, 0.12, 0.8))[..., None]
    a += grain(W, W, 6.0, 3.0)[..., None]
    for r in range(rows):
        y0 = (r + 1) * rh - 22
        a[y0 - 6:y0, :] *= 0.55                          # l'ombre au pied des livres
        a[(r * rh):(r * rh) + 14, :] *= 0.35             # l'ombre de la planche du dessus
    Image.fromarray(np.uint8(np.clip(a, 0, 255))).save(OUT / "livres.png", optimize=True)


# =================================================================== le vitrail

def vitrail():
    W, H = 512, 1024
    rgba = np.zeros((H, W, 4), np.float32)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    # l'ogive : deux arcs de cercle au-dessus d'un rectangle
    r = W * 0.9
    spring = W * 0.62
    inside = (xx > 6) & (xx < W - 6) & (yy > 6) & (yy < H - 6)
    top = yy < spring
    c1 = ((xx - (W - 6 - r)) ** 2 + (yy - spring) ** 2) < r * r
    c2 = ((xx - (6 + r)) ** 2 + (yy - spring) ** 2) < r * r
    inside &= (~top) | (c1 & c2)
    # les pièces de verre : une mosaïque de Voronoï
    n = 150
    pts = np.stack([RNG.uniform(0, W, n), RNG.uniform(0, H, n)], 1)
    pal = np.array([(150, 10, 18), (110, 8, 30), (70, 14, 70), (40, 20, 90), (18, 26, 92), (14, 40, 110), (170, 90, 20), (120, 18, 12), (60, 8, 40)], np.float32)
    cols = pal[RNG.integers(0, len(pal), n)] * RNG.uniform(0.75, 1.15, (n, 1))
    best = np.full((H, W), 1e12, np.float32)
    second = np.full((H, W), 1e12, np.float32)
    idx = np.zeros((H, W), np.int32)
    for i in range(n):
        dd = (xx - pts[i, 0]) ** 2 + (yy - pts[i, 1]) ** 2
        upd = dd < best
        second = np.where(upd, best, np.minimum(second, dd))
        idx = np.where(upd, i, idx)
        best = np.where(upd, dd, best)
    col = cols[idx]
    lead = (np.sqrt(second) - np.sqrt(best)) < 4.0
    # au centre : la lune pâle (un croissant) et la chauve-souris noire devant
    cx, cy = W * 0.5, H * 0.42
    moon = ((xx - cx) ** 2 + (yy - cy) ** 2) < 120 ** 2
    bite = ((xx - cx - 52) ** 2 + (yy - cy + 26) ** 2) < 104 ** 2
    cres = moon & ~bite
    col[cres] = (235, 222, 170)
    ring = np.abs(np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) - 150) < 5
    lead |= ring
    # la chauve-souris : un corps et deux ailes en dents
    bat = Image.new("L", (W, H), 0)
    bd = ImageDraw.Draw(bat)
    bx, by = cx - 6, cy + 10
    wing = []
    for s in (-1, 1):
        wing = [(bx, by - 8), (bx + s * 50, by - 44), (bx + s * 100, by - 52), (bx + s * 150, by - 28), (bx + s * 130, by - 5),
                (bx + s * 108, by + 8), (bx + s * 84, by - 2), (bx + s * 58, by + 16), (bx + s * 32, by + 3), (bx, by + 22)]
        bd.polygon(wing, fill=255)
    bd.ellipse((bx - 15, by - 26, bx + 15, by + 32), fill=255)
    bd.polygon([(bx - 13, by - 20), (bx - 8, by - 42), (bx - 1, by - 24)], fill=255)
    bd.polygon([(bx + 13, by - 20), (bx + 8, by - 42), (bx + 1, by - 24)], fill=255)
    batm = np.asarray(bat) > 128
    col[batm] = (6, 4, 6)
    # le verre ancien : des bulles, des variations, la crasse sur les bords
    col *= (1.0 + grain(W, H, 0.16, 2.2))[..., None]
    edge = np.clip(np.minimum.reduce([xx, W - xx, H - yy]) / 60.0, 0.4, 1.0)
    col *= edge[..., None]
    lead &= ~cres
    lead &= ~batm
    lead |= ring
    col[lead] = (14, 13, 12)
    rgba[..., :3] = col
    rgba[..., 3] = np.where(inside, 255, 0)
    # le cadre de plomb autour de l'ogive
    Image.fromarray(np.uint8(np.clip(rgba, 0, 255)), "RGBA").save(OUT / "vitrail_comte.png", optimize=True)


# =================================================================== le vieux tableau

def toile():
    W, H = 512, 384
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    sky = np.zeros((H, W, 3), np.float32)
    t = yy / H
    sky[..., 0] = 24 + 30 * t
    sky[..., 1] = 26 + 22 * t
    sky[..., 2] = 40 + 18 * t
    # la lune, son halo
    mx, my = W * 0.68, H * 0.26
    d = np.sqrt((xx - mx) ** 2 + (yy - my) ** 2)
    sky += np.clip(1.0 - d / 140.0, 0, 1)[..., None] ** 2 * np.array([90, 86, 70])
    sky[d < 26] = (210, 200, 160)
    # des nuages
    cl = grain(W, H, 1.0, 14.0)
    cl = np.clip(cl * 0.9 + 0.2 - t * 0.4, 0, 1)
    sky = sky * (1 - cl[..., None] * 0.6) + cl[..., None] * np.array([46, 44, 50])
    # les collines noires et le château sur la plus haute
    h1 = H * 0.7 + 30 * np.sin(xx / 70.0) + 14 * np.sin(xx / 23.0 + 1.0)
    h2 = H * 0.8 + 20 * np.sin(xx / 50.0 + 2.0)
    sky[yy > h1] = (16, 16, 18)
    sky[yy > h2] = (8, 8, 9)
    img = Image.fromarray(np.uint8(np.clip(sky, 0, 255)))
    dr = ImageDraw.Draw(img)
    base = H * 0.6
    cx = W * 0.3
    for (dx, w, h) in ((-40, 16, 70), (-14, 30, 100), (22, 18, 80), (44, 14, 60)):
        dr.rectangle((cx + dx, base - h, cx + dx + w, base + 40), fill=(10, 10, 12))
        dr.polygon([(cx + dx - 3, base - h), (cx + dx + w / 2, base - h - 34), (cx + dx + w + 3, base - h)], fill=(10, 10, 12))
    dr.rectangle((cx - 48, base - 30, cx + 64, base + 40), fill=(10, 10, 12))
    for (dx, dy) in ((0, -60), (8, -60), (30, -40)):
        dr.rectangle((cx + dx, base + dy, cx + dx + 3, base + dy + 6), fill=(150, 30, 20))
    a = np.asarray(img, np.float32)
    # le vernis jauni, les craquelures
    a = a * np.array([1.08, 1.0, 0.82]) + 6
    cr = grain(W, H, 1.0, 0.6)
    a[np.abs(cr) < 0.035] *= 0.6
    Image.fromarray(np.uint8(np.clip(a, 0, 255))).save(OUT / "toile_peinte.png", optimize=True)


# =================================================================== le portrait du comte

def portrait():
    W, H = 512, 672
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    bg = np.zeros((H, W, 3), np.float32)
    # le fond : un brun-rouge très sombre, éclairé à gauche
    lum = np.clip(1.0 - np.sqrt(((xx - W * 0.35) / W) ** 2 + ((yy - H * 0.3) / H) ** 2) * 1.6, 0, 1)
    bg[...] = np.array([18, 10, 9]) + lum[..., None] * np.array([46, 24, 18])
    img = Image.fromarray(np.uint8(np.clip(bg, 0, 255)))
    d = ImageDraw.Draw(img)
    cx = W * 0.5
    # la cape et les épaules
    d.polygon([(cx - 230, H), (cx - 190, H * 0.62), (cx - 70, H * 0.5), (cx + 70, H * 0.5), (cx + 190, H * 0.62), (cx + 230, H)], fill=(8, 7, 9))
    # le grand col dressé, doublé de rouge
    d.polygon([(cx - 150, H * 0.47), (cx - 95, H * 0.3), (cx - 55, H * 0.52)], fill=(90, 8, 14))
    d.polygon([(cx + 150, H * 0.47), (cx + 95, H * 0.3), (cx + 55, H * 0.52)], fill=(90, 8, 14))
    d.polygon([(cx - 160, H * 0.48), (cx - 100, H * 0.28), (cx - 92, H * 0.31), (cx - 146, H * 0.5)], fill=(10, 8, 10))
    d.polygon([(cx + 160, H * 0.48), (cx + 100, H * 0.28), (cx + 92, H * 0.31), (cx + 146, H * 0.5)], fill=(10, 8, 10))
    # la chemise, le médaillon
    d.polygon([(cx - 40, H * 0.5), (cx + 40, H * 0.5), (cx, H * 0.66)], fill=(150, 142, 130))
    d.ellipse((cx - 16, H * 0.6, cx + 16, H * 0.64), fill=(150, 20, 24))
    # le cou, le visage (long, maigre, très pâle)
    d.rectangle((cx - 26, H * 0.38, cx + 26, H * 0.5), fill=(170, 162, 160))
    d.ellipse((cx - 62, H * 0.16, cx + 62, H * 0.43), fill=(196, 188, 186))
    # les cheveux noirs, plaqués, en pointe sur le front
    d.polygon([(cx - 66, H * 0.27), (cx - 60, H * 0.15), (cx, H * 0.11), (cx + 60, H * 0.15), (cx + 66, H * 0.27), (cx + 50, H * 0.2), (cx, H * 0.215), (cx - 50, H * 0.2)], fill=(12, 10, 12))
    # les sourcils, les orbites creuses, la bouche
    d.line([(cx - 44, H * 0.255), (cx - 12, H * 0.265)], fill=(20, 16, 18), width=5)
    d.line([(cx + 44, H * 0.255), (cx + 12, H * 0.265)], fill=(20, 16, 18), width=5)
    for s in (-1, 1):
        d.ellipse((cx + s * 28 - 15, H * 0.27, cx + s * 28 + 15, H * 0.3), fill=(110, 92, 96))
    d.line([(cx - 20, H * 0.375), (cx + 20, H * 0.375)], fill=(90, 22, 30), width=4)
    d.line([(cx, H * 0.3), (cx - 6, H * 0.35)], fill=(150, 140, 140), width=3)
    img = img.filter(ImageFilter.GaussianBlur(2.2))
    a = np.asarray(img, np.float32)
    # la lumière de côté sur le visage, le vernis, les craquelures
    a *= (0.75 + 0.5 * np.clip(1.0 - (xx - W * 0.3) / W, 0, 1))[..., None]
    a = a * np.array([1.05, 0.98, 0.85])
    a *= (1.0 + grain(W, H, 0.08, 1.0))[..., None]
    cr = grain(W, H, 1.0, 0.6)
    a[np.abs(cr) < 0.03] *= 0.65
    Image.fromarray(np.uint8(np.clip(a, 0, 255))).save(OUT / "portrait_comte.png", optimize=True)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    livres()
    vitrail()
    toile()
    portrait()
    for f in ("livres.png", "vitrail_comte.png", "toile_peinte.png", "portrait_comte.png"):
        print(f, Image.open(OUT / f).size, (OUT / f).stat().st_size // 1024, "Ko")
