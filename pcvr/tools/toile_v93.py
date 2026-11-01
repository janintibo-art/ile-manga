"""V93 : la toile du fond de la Grande Scène, tissée par Lune (peinte ici, versée au domaine public, CC0 1.0).

  textures/larsen/toile_scene_v93.png  2048 × 768 : à gauche le ciel du Camp des Fleurs (un grand soleil,
      des tournesols), à droite celui de Rainville (le petit nuage, la pluie, un parapluie troué), et
      par-dessus, d'un bout à l'autre, un arc-en-ciel ; en bas, la prairie et les coquelicots. La trame
      de la toile de chanvre se voit à travers la peinture, et une petite goutte se cache dans un coin
      (le motif secret de Lune).
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/toile_v93.py
"""
from pathlib import Path
import math

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "larsen"
W, H = 2048, 768
RNG = np.random.default_rng(930)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def ciel(img):
    px = np.zeros((H, W, 3), np.float32)
    y = np.linspace(0, 1, H)[:, None]
    x = np.linspace(0, 1, W)[None, :]
    soleil_haut, soleil_bas = np.array([0.98, 0.72, 0.28]), np.array([1.0, 0.92, 0.62])
    pluie_haut, pluie_bas = np.array([0.32, 0.38, 0.5]), np.array([0.62, 0.68, 0.76])
    sol = soleil_haut * (1 - y[..., None]) + soleil_bas * y[..., None]
    plu = pluie_haut * (1 - y[..., None]) + pluie_bas * y[..., None]
    k = np.clip((x - 0.42) / 0.16, 0, 1)[..., None]
    k = k * k * (3 - 2 * k)
    px[:] = (sol * (1 - k) + plu * k)[:, :, :]
    img.paste(Image.fromarray((px * 255).astype(np.uint8)))


def soleil(d, cx, cy, r):
    for i in range(24):
        a = 2 * math.pi * i / 24
        l = r * (1.55 if i % 2 == 0 else 1.3)
        d.polygon([(cx + math.cos(a - 0.06) * r * 1.05, cy + math.sin(a - 0.06) * r * 1.05), (cx + math.cos(a) * l, cy + math.sin(a) * l),
                   (cx + math.cos(a + 0.06) * r * 1.05, cy + math.sin(a + 0.06) * r * 1.05)], fill=(250, 196, 40))
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(252, 210, 60))
    d.ellipse([cx - r * 0.82, cy - r * 0.82, cx + r * 0.82, cy + r * 0.82], fill=(254, 224, 90))
    # le visage peint, souriant
    for sx in (-0.3, 0.3):
        d.ellipse([cx + sx * r - 9, cy - r * 0.18 - 12, cx + sx * r + 9, cy - r * 0.18 + 12], fill=(140, 70, 20))
    d.arc([cx - r * 0.45, cy - r * 0.2, cx + r * 0.45, cy + r * 0.48], 20, 160, fill=(140, 70, 20), width=9)


def nuage(d, cx, cy, s):
    for (dx, dy, r) in [(-1.1, 0.2, 0.62), (-0.45, -0.25, 0.8), (0.35, -0.1, 0.72), (1.0, 0.25, 0.58), (0.0, 0.35, 0.7)]:
        d.ellipse([cx + (dx - r) * s, cy + (dy - r) * s, cx + (dx + r) * s, cy + (dy + r) * s], fill=(88, 96, 112))
    for (dx, dy, r) in [(-0.5, -0.35, 0.55), (0.3, -0.2, 0.5)]:
        d.ellipse([cx + (dx - r) * s, cy + (dy - r) * s, cx + (dx + r) * s, cy + (dy + r) * s], fill=(112, 120, 136))


def pluie(d, x0, x1, y0, y1):
    for _ in range(380):
        x = RNG.uniform(x0, x1)
        y = RNG.uniform(y0, y1)
        d.line([(x, y), (x - 6, y + 34)], fill=(190, 205, 225), width=3)


def arc_en_ciel(d, cx, cy, r):
    cols = [(220, 50, 50), (240, 140, 40), (245, 215, 60), (80, 175, 80), (60, 120, 210), (120, 70, 180)]
    w = 30
    for i, c in enumerate(cols):
        rr = r - i * w
        d.arc([cx - rr, cy - rr, cx + rr, cy + rr], 180, 360, fill=c, width=w + 2)


def tournesol(d, cx, cy, r):
    d.line([(cx, cy), (cx + 6, H)], fill=(60, 110, 40), width=10)
    d.ellipse([cx + 4, cy + 80, cx + 60, cy + 110], fill=(70, 130, 50))
    for i in range(16):
        a = 2 * math.pi * i / 16
        px, py = cx + math.cos(a) * r * 0.85, cy + math.sin(a) * r * 0.85
        q = r * 0.38
        d.ellipse([px - q, py - q * 0.55, px + q, py + q * 0.55], fill=(250, 190, 30))
    d.ellipse([cx - r * 0.5, cy - r * 0.5, cx + r * 0.5, cy + r * 0.5], fill=(100, 55, 20))


def parapluie(d, cx, cy, r):
    d.pieslice([cx - r, cy - r, cx + r, cy + r], 180, 360, fill=(30, 30, 36))
    for i in range(3):
        a = math.pi + math.pi * (i + 0.5) / 3
        hx, hy = cx + math.cos(a) * r * 0.6, cy + math.sin(a) * r * 0.6
        d.ellipse([hx - 9, hy - 7, hx + 9, hy + 7], fill=(150, 165, 185))        # les trous, exprès
    d.line([(cx, cy - r), (cx, cy + r * 0.9)], fill=(90, 60, 35), width=8)
    d.arc([cx - 24, cy + r * 0.75, cx + 4, cy + r * 1.05], 0, 180, fill=(90, 60, 35), width=8)


def prairie(d):
    for k in range(3):
        y0 = H - 150 + k * 40
        pts = [(0, H)]
        for x in range(0, W + 64, 64):
            pts.append((x, y0 + 22 * math.sin(x * 0.006 + k * 1.7) + 10 * math.sin(x * 0.021 + k)))
        pts.append((W, H))
        d.polygon(pts, fill=[(96, 150, 70), (80, 135, 60), (66, 118, 52)][k])
    for _ in range(260):
        x = RNG.uniform(0, W)
        y = RNG.uniform(H - 110, H - 10)
        r = RNG.uniform(6, 11)
        c = (215, 40, 30) if x < W * 0.55 or RNG.random() < 0.3 else (90, 120, 200)
        d.ellipse([x - r, y - r * 0.8, x + r, y + r * 0.8], fill=c)


def trame(img):
    a = np.asarray(img).astype(np.float32) / 255.0
    yy, xx = np.mgrid[0:H, 0:W]
    weave = 0.93 + 0.05 * np.sin(xx * 1.2) * np.sin(yy * 1.2) + 0.03 * np.sin(xx * 0.31 + yy * 0.07)
    grain = RNG.normal(1.0, 0.035, (H, W))
    a = a * (weave * grain)[..., None]
    # les bords un peu plus sombres (la toile est tendue sur ses cordes)
    v = np.clip(np.minimum.reduce([xx / 60.0, (W - xx) / 60.0, yy / 40.0, (H - yy) / 40.0]), 0, 1)
    a = a * (0.75 + 0.25 * v)[..., None]
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8))


def main():
    img = Image.new("RGB", (W, H))
    ciel(img)
    d = ImageDraw.Draw(img)
    arc_en_ciel(d, W // 2, H - 120, 760)
    soleil(d, 360, 250, 120)
    nuage(d, 1640, 210, 120)
    pluie(d, 1430, 1900, 300, 640)
    parapluie(d, 1700, 520, 90)
    prairie(d)
    for (x, y, r) in [(140, 520, 54), (300, 470, 62), (470, 540, 50), (620, 500, 44), (800, 560, 40)]:
        tournesol(d, x, y, r)
    # le motif secret de Lune : une petite goutte de pluie, tout en bas, côté soleil
    d.polygon([(232, H - 46), (222, H - 26), (242, H - 26)], fill=(120, 170, 230))
    d.ellipse([220, H - 36, 244, H - 14], fill=(120, 170, 230))
    img = img.filter(ImageFilter.GaussianBlur(1.2))
    img = trame(img)
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / "toile_scene_v93.png")
    print("V93 : la toile de la scène est peinte")


if __name__ == "__main__":
    main()
