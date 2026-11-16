"""V159 : les sols volcaniques refaits à partir des sols du jeu en haute définition (V158).

Les textures de la V46 (generate_nains_v46.py) étaient des sols du jeu recolorés, agrandis de 512
à 1024 (flous). On repart des sols en 2048, réduits à 1024 (nets), et on leur ajoute ce qui fait
un volcan :
  sable_noir     le sable noir de la côte : des grains qui brillent, quelques grains d'olivine
  cendre         la cendre des pentes : des lapilli (petites scories) semés dedans, et leur relief
                 (cendre_n)
  herbe_brulee   l'herbe brûlée : des plaques de cendre grise et de terre calcinée
  basalte        le basalte : des vacuoles (les bulles du gaz figées dans la lave) et leur relief
                 (basalte_n)
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_volcan_v159.py
"""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "www" / "assets" / "textures" / "terrain"
OUT = ROOT / "www" / "assets" / "textures" / "volcan"
N = 1024


def lire(p, taille=N):
    im = Image.open(p).convert("RGB")
    if im.size[0] != taille:
        im = im.resize((taille, taille), Image.LANCZOS)
    return np.asarray(im, dtype=np.float64) / 255.0


def sauver(nom, a):
    Image.fromarray((np.clip(a, 0, 1) * 255).round().astype(np.uint8)).save(OUT / f"{nom}.png", optimize=True)
    print("  ", nom)


def lum(a):
    return a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114


def recolor(a, tint, contrast, lift):
    l = np.clip((lum(a) - 0.5) * contrast + 0.5 + lift, 0, 1)
    return l[..., None] * np.array(tint)[None, None, :]


def flou(x, k=1):
    out = x.copy()
    for _ in range(k):
        out = (out + np.roll(out, 1, 0) + np.roll(out, -1, 0) + np.roll(out, 1, 1) + np.roll(out, -1, 1)) / 5.0
    return out


def valeur(cell, seed, n=N):
    r = np.random.default_rng(seed)
    g = r.random((cell, cell))
    x = np.arange(n) * cell / n
    i0 = np.floor(x).astype(int)
    f = x - i0
    f = f * f * (3 - 2 * f)
    i1 = (i0 + 1) % cell
    i0 = i0 % cell
    a, b, c, d = g[np.ix_(i0, i0)], g[np.ix_(i0, i1)], g[np.ix_(i1, i0)], g[np.ix_(i1, i1)]
    fy, fx = f[:, None], f[None, :]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def fbm(cell, oct_, seed, n=N):
    s = np.zeros((n, n))
    amp = tot = 1.0
    s += valeur(cell, seed, n)
    for o in range(1, oct_):
        amp *= 0.5
        s += amp * valeur(cell * 2 ** o, seed + o * 17, n)
        tot += amp
    return s / tot


def bosses(seed, nombre, r0, r1, n=N):
    """Des bosses rondes (raccordables) : [hauteur 0..1, masque 0..1, l'indice de la bosse]."""
    r = np.random.default_rng(seed)
    h = np.zeros((n, n))
    m = np.zeros((n, n))
    for _ in range(nombre):
        cx, cy = r.random() * n, r.random() * n
        rr = r.uniform(r0, r1)
        ex = r.uniform(0.7, 1.3)
        x0, x1 = int(cx - rr * 1.4) - 1, int(cx + rr * 1.4) + 2
        y0, y1 = int(cy - rr * 1.4) - 1, int(cy + rr * 1.4) + 2
        ys = np.arange(y0, y1)
        xs = np.arange(x0, x1)
        dy = (ys[:, None] - cy) / rr
        dx = (xs[None, :] - cx) / (rr * ex)
        d = np.sqrt(dx * dx + dy * dy)
        b = np.clip(1 - d * d, 0, 1)
        mm = np.clip((1 - d) * rr, 0, 1)
        yi = ys % n
        xi = xs % n
        h[np.ix_(yi, xi)] = np.maximum(h[np.ix_(yi, xi)], np.sqrt(b))
        m[np.ix_(yi, xi)] = np.maximum(m[np.ix_(yi, xi)], mm)
    return h, m


def normale(h, force):
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * force
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5 * force
    l = np.sqrt(dx * dx + dy * dy + 1.0)
    return np.stack([-dx / l, dy / l, 1.0 / l], -1)


def melanger_normales(n0, h, force):
    """Le relief d'origine (n0, en couleurs) plus celui d'une hauteur h."""
    a = n0 * 2.0 - 1.0
    b = normale(h, force)
    n = np.stack([a[..., 0] + b[..., 0], a[..., 1] + b[..., 1], a[..., 2] * b[..., 2]], -1)
    n = n / np.linalg.norm(n, axis=-1, keepdims=True)
    return n * 0.5 + 0.5


def sable_noir():
    a = recolor(lire(SRC / "sand.jpg"), (0.32, 0.3, 0.32), 1.3, -0.12)
    r = np.random.default_rng(1591)
    g = r.random((N, N))
    brille = flou((g > 0.9975).astype(float), 1) * 1.6
    olivine = flou((g < 0.0015).astype(float), 1) * 1.4
    a = a * (1 + (flou(r.random((N, N)), 1) - 0.5) * 0.22)[..., None]
    a = a + brille[..., None] * np.array([0.55, 0.55, 0.58]) + olivine[..., None] * np.array([0.12, 0.2, 0.05])
    sauver("sable_noir", a)


def cendre():
    a = recolor(lire(SRC / "sand.jpg"), (0.36, 0.33, 0.31), 1.15, -0.06)
    n0 = lire(SRC / "sand_n.png")
    h1, m1 = bosses(1592, 900, 1.6, 3.6)
    h2, m2 = bosses(1593, 70, 3.6, 7.0)
    # des scories anguleuses, pas des billes : le bord est rongé par un bruit fin
    ronge = fbm(128, 3, 1600)
    h = np.maximum(h1 * 0.7, h2) * (0.55 + 0.45 * ronge)
    m = np.clip((np.maximum(m1, m2) * (0.4 + 0.9 * ronge) - 0.3) * 2.5, 0, 1)
    # les lapilli : des scories gris-noir, quelques-unes brun rouille, à peine plus sombres que la cendre
    teinte = np.where(valeur(48, 1594)[..., None] > 0.7, np.array([0.24, 0.17, 0.14]), np.array([0.16, 0.15, 0.15]))
    pierre = teinte * (0.75 + 0.45 * h[..., None]) * (0.85 + 0.3 * fbm(64, 3, 1595)[..., None])
    a = a * (1 - 0.8 * m[..., None]) + pierre * 0.8 * m[..., None]
    # l'ombre au pied des cailloux
    ombre = np.clip(flou(m, 3) - m, 0, 1)
    a = a * (1 - 0.35 * ombre[..., None])
    sauver("cendre", a)
    sauver("cendre_n", melanger_normales(n0, h * m, 6.0))


def herbe_brulee():
    a = recolor(lire(SRC / "grass.jpg"), (0.62, 0.55, 0.32), 1.2, -0.05)
    plaques = fbm(6, 4, 1596)
    cendre = np.clip((plaques - 0.58) * 6, 0, 1)
    calcine = np.clip((0.4 - plaques) * 6, 0, 1)
    gris = lum(a)[..., None] * np.array([0.95, 0.92, 0.9]) * 1.1
    a = a * (1 - cendre[..., None]) + gris * cendre[..., None]
    a = a * (1 - 0.45 * calcine[..., None])
    sauver("herbe_brulee", a)


def basalte():
    a = recolor(lire(SRC / "rock.jpg"), (0.42, 0.42, 0.46), 1.35, -0.1)
    n0 = lire(SRC / "rock_n.png")
    # les vacuoles : de petits trous ronds, plus nombreux par endroits
    zones = fbm(8, 3, 1597)
    h1, m1 = bosses(1598, 2200, 0.9, 2.4)
    keep = (zones > 0.45).astype(float)
    trous = h1 * keep
    mt = m1 * keep
    a = a * (1 - 0.32 * mt[..., None])
    # un grain fin et un peu de bleu d'acier dans le noir
    a = a * (0.92 + 0.16 * flou(np.random.default_rng(1599).random((N, N)), 1))[..., None]
    sauver("basalte", a)
    sauver("basalte_n", melanger_normales(n0, -trous, 4.0))


def main() -> int:
    print("V159 : les sols volcaniques en haute définition")
    sable_noir()
    cendre()
    herbe_brulee()
    basalte()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
