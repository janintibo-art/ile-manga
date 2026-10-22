"""Textures des yeux (iris en niveaux de gris + masque d'iris) et des cils."""
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

CENTERS = [(0.7055, 0.2955), (0.2896, 0.7078)]
R_IRIS = 0.118
R_PUPIL = 0.036


def eye_texture(size=1024, seed=7):
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:size, 0:size] / size
    rgb = np.zeros((size, size, 3), np.float32)
    rgb[:] = [0.92, 0.89, 0.86]
    alpha = np.zeros((size, size), np.float32)
    # veines : traits rouges fins
    veins = Image.new('L', (size, size), 0)
    d = ImageDraw.Draw(veins)
    for cx, cy in CENTERS:
        for k in range(70):
            a = rng.random() * 2 * np.pi
            r = R_IRIS * (2.6 + rng.random() * 0.8)
            pts = []
            ang = a
            rr = r
            for s in range(14):
                pts.append(((cx + np.cos(ang) * rr) * size, (cy + np.sin(ang) * rr) * size))
                rr -= R_IRIS * (0.06 + rng.random() * 0.06)
                ang += rng.normal(0, 0.06)
                if rr < R_IRIS * 1.25:
                    break
            d.line(pts, fill=int(60 + rng.random() * 110), width=1 if rng.random() < 0.7 else 2)
    v = ndimage.gaussian_filter(np.asarray(veins).astype(np.float32) / 255.0, 0.6)
    for cx, cy in CENTERS:
        r = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / R_IRIS
        ang = np.arctan2(yy - cy, xx - cx)
        # bords du blanc : plus rosé, plus sombre (coins de l'œil)
        edge = np.clip((r - 2.4) / 1.0, 0, 1)
        rgb *= (1 - edge[..., None] * np.array([0.12, 0.22, 0.22]))
        rgb *= (1 - (v * np.clip((r - 1.1) / 0.6, 0, 1))[..., None] * np.array([0.05, 0.45, 0.45]))
        # anneau sombre autour de l'iris (limbe)
        limb = np.exp(-((r - 1.0) / 0.09) ** 2)
        # iris : fibres radiales + collerette
        fib = np.zeros_like(r)
        for f, amp in ((60, 0.35), (130, 0.25), (23, 0.3)):
            ph = rng.random(f) * 2 * np.pi
            k = (ang / (2 * np.pi) * f) % f
            i0 = np.floor(k).astype(int) % f
            fr = k - np.floor(k)
            fib += amp * (np.sin(ph[i0] + fr * 0.0 + r * 9.0) * 0.5 + 0.5)
        n = ndimage.gaussian_filter(rng.random((size, size)).astype(np.float32), 1.2)
        L = 0.45 + 0.35 * (fib / 0.9 - 0.5) + (n - 0.5) * 0.4
        coll = np.exp(-((r - 0.55) / 0.08) ** 2)
        L = L + 0.25 * coll - 0.35 * limb
        L = L * (0.75 + 0.25 * np.clip((r - 0.3) / 0.4, 0, 1))
        iris = r < 1.05
        soft = np.clip((1.05 - r) / 0.06, 0, 1)
        pupil = np.clip((R_PUPIL / R_IRIS + 0.02 - r) / 0.04, 0, 1)
        Lc = np.clip(L, 0.05, 1.0) * (1 - pupil)
        rgb = np.where(iris[..., None], rgb * (1 - soft[..., None]) + Lc[..., None] * soft[..., None], rgb)
        rgb *= (1 - (limb * (r > 0.95) * 0.3)[..., None])
        alpha = np.maximum(alpha, soft * (1 - pupil))
        # pupille noire
        rgb *= (1 - pupil[..., None] * 0.97)
    return np.concatenate([np.clip(rgb, 0, 1), alpha[..., None]], -1)


def lash_texture(w=512, h=128, seed=9, n=110):
    """cils : racines en bas (v=1), pointes en haut ; alpha."""
    rng = np.random.default_rng(seed)
    img = Image.new('L', (w * 2, h * 2), 0)
    d = ImageDraw.Draw(img)
    W, H = w * 2, h * 2
    for k in range(n):
        x0 = (0.04 + 0.92 * rng.random()) * W
        ln = (0.55 + 0.4 * rng.random()) * H * (0.6 + 0.4 * np.sin(np.pi * x0 / W))
        lean = (x0 / W - 0.5) * 0.5 + rng.normal(0, 0.12)
        pts = []
        for s in range(9):
            t = s / 8
            x = x0 + lean * ln * t + 0.15 * ln * t * t * np.sign(lean)
            y = H - 2 - t * ln
            pts.append((x, y))
        for s in range(8):
            wdt = max(1, int(round(4 * (1 - s / 8))))
            d.line([pts[s], pts[s + 1]], fill=int(255 * (1 - 0.5 * s / 8)), width=wdt)
    a = np.asarray(img.resize((w, h), Image.LANCZOS)).astype(np.float32) / 255.0
    rgb = np.zeros((h, w, 3), np.float32) + 0.04
    return np.concatenate([rgb, a[..., None]], -1)


def save_rgba(path, a):
    Image.fromarray((np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8), 'RGBA').save(path, optimize=True)
