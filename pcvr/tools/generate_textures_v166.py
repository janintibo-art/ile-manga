"""V166 : les textures de Pandémonia, de Montjoie et de Port-Boucan (faites ici ; CC0 1.0).
Dossier www/assets/textures/beau166/.

  toile            la toile des auvents et des étals (1 m) : la trame et la chaîne du coton épais, les
                   plis, la poussière (claire : la couleur de l'étal la teinte).
  brique_badigeon  la brique peinte de Port-Boucan (1,6 m) : la peinture épaisse sur les briques de
                   boucan/brique (le même appareil : on voit leur relief, les joints plus sombres), la
                   poussière, les coulures (claire : la couleur de la façade la teinte ; le shader de
                   l'enduit vieilli la fait tomber par plaques sur la vraie brique).

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_textures_v166.py [nom…]
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

RACINE = Path(__file__).resolve().parents[2]
OUT = RACINE / "www" / "assets" / "textures" / "beau166"


def valeur(cx, seed, w, h, cy=None):
    cy = cy or cx
    r = np.random.default_rng(seed)
    g = r.random((cy, cx))

    def axe(c, n):
        x = np.arange(n) * c / n
        i0 = np.floor(x).astype(int)
        f = x - i0
        return i0 % c, (i0 + 1) % c, f * f * (3 - 2 * f)
    y0, y1, fy = axe(cy, h)
    x0, x1, fx = axe(cx, w)
    fy, fx = fy[:, None], fx[None, :]
    return (g[np.ix_(y0, x0)] * (1 - fx) + g[np.ix_(y0, x1)] * fx) * (1 - fy) + (g[np.ix_(y1, x0)] * (1 - fx) + g[np.ix_(y1, x1)] * fx) * fy


def fbm(cell, oct_, seed, w, h, gain=0.5, cy=None):
    s = np.zeros((h, w))
    amp = tot = 1.0
    s += valeur(cell, seed, w, h, cy)
    for o in range(1, oct_):
        amp *= gain
        s += amp * valeur(cell * 2 ** o, seed + o * 17, w, h, (cy * 2 ** o) if cy else None)
        tot += amp
    return s / tot


def normale(h, force):
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * force
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5 * force
    l = np.sqrt(dx * dx + dy * dy + 1.0)
    return np.stack([-dx / l * 0.5 + 0.5, dy / l * 0.5 + 0.5, 1.0 / l * 0.5 + 0.5], -1)


def flou(a, r):
    k = int(r * 3) + 1
    x = np.arange(-k, k + 1)
    g = np.exp(-x * x / (2.0 * r * r))
    g /= g.sum()
    b = sum(np.roll(a, int(i), 0) * w for i, w in zip(x, g))
    return sum(np.roll(b, int(i), 1) * w for i, w in zip(x, g))


def sauver(nom, c, h=None, force=3.0, rough=None):
    OUT.mkdir(parents=True, exist_ok=True)
    c = np.clip(c, 0, 1)
    Image.fromarray((c * 255).round().astype(np.uint8)).save(OUT / f"{nom}.png", optimize=True)
    if h is not None:
        Image.fromarray((np.clip(normale(h, force), 0, 1) * 255).round().astype(np.uint8)).save(OUT / f"{nom}_n.png", optimize=True)
    if rough is not None:
        Image.fromarray((np.clip(rough, 0, 1) * 255).round().astype(np.uint8), "L").save(OUT / f"{nom}_r.png", optimize=True)
    print("  ", nom)


def vn(x, y, per, seed):
    """Un bruit de valeur aux coordonnées (x, y) en cases, périodique de per cases."""
    g = np.random.default_rng(seed).random((per, per))
    xi = np.floor(x).astype(int)
    yi = np.floor(y).astype(int)
    fx = x - xi
    fy = y - yi
    fx = fx * fx * (3 - 2 * fx)
    fy = fy * fy * (3 - 2 * fy)
    x0, x1, y0, y1 = xi % per, (xi + 1) % per, yi % per, (yi + 1) % per
    return (g[y0, x0] * (1 - fx) + g[y0, x1] * fx) * (1 - fy) + (g[y1, x0] * (1 - fx) + g[y1, x1] * fx) * fy


def h01(a):
    return (np.sin(a * 12.9898 + 4.1) * 43758.5453) % 1.0


def appareil(N, hauteurs, longueurs, seed, regulier=False):
    """Des rangs (hauteurs en px) de blocs (longueurs en px), qui se raccordent d'un bord à l'autre.
    Renvoie l'identifiant du bloc, la distance au joint vertical, au joint horizontal, la place dans le
    rang (0 en haut, 1 en bas) et la place dans le bloc (0 à 1)."""
    rng = np.random.default_rng(seed)
    hs = []
    tot = 0.0
    while tot < N - hauteurs[0] * 0.5:
        hh = hauteurs[0] if regulier else rng.uniform(*hauteurs)
        hs.append(hh)
        tot += hh
    hs = np.array(hs) * N / tot
    e = np.round(np.concatenate([[0.0], np.cumsum(hs)])).astype(int)
    e[-1] = N
    sid = np.zeros((N, N), int)
    dx = np.zeros((N, N))
    dy = np.zeros((N, N))
    fy = np.zeros((N, N))
    fx = np.zeros((N, N))
    xs = np.arange(N, dtype=float)
    for k in range(len(hs)):
        y0, y1 = e[k], e[k + 1]
        if y1 <= y0:
            continue
        pos = []
        t = 0.0
        while t < N - longueurs[0] * 0.5:
            pos.append(t)
            t += longueurs[0] if regulier else rng.uniform(*longueurs)
        x0 = (k % 2) * longueurs[0] * 0.5 if regulier else rng.uniform(0, N)
        pos = np.sort((np.array(pos) * N / t + x0) % N)
        idx = (np.searchsorted(pos, xs, side="right") - 1) % len(pos)
        d = np.full(N, 1e9)
        for q in pos:
            a = np.abs(xs - q)
            d = np.minimum(d, np.minimum(a, N - a))
        debut = pos[idx]
        fin = np.where(idx + 1 < len(pos), pos[(idx + 1) % len(pos)], pos[0] + N)
        lx = np.where(xs >= debut, xs - debut, xs + N - debut) / np.maximum(fin - debut, 1.0)
        ys = np.arange(y0, y1)
        sid[y0:y1] = (idx + k * 101)[None, :]
        dx[y0:y1] = d[None, :]
        fx[y0:y1] = lx[None, :]
        dy[y0:y1] = np.minimum(ys - y0 + 0.5, y1 - ys - 0.5)[:, None]
        fy[y0:y1] = ((ys - y0 + 0.5) / (y1 - y0))[:, None]
    return sid, dx, dy, fy, fx


def voronoi(N, gx, gy, seed, jitter=0.85):
    """Des cellules (gx × gy points sur une grille secouée, raccordées d'un bord à l'autre) :
    F1, F2 (distances au plus proche point et au suivant) et l'identifiant de la cellule."""
    rng = np.random.default_rng(seed)
    cx, cy = N / gx, N / gy
    jit = rng.uniform(-0.5, 0.5, (gy, gx, 2)) * jitter
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    ix = np.floor(xx / cx).astype(int)
    iy = np.floor(yy / cy).astype(int)
    f1 = np.full((N, N), 1e9)
    f2 = np.full((N, N), 1e9)
    ids = np.zeros((N, N), int)
    for dj in (-1, 0, 1):
        for di in (-1, 0, 1):
            jx = ix + di
            jy = iy + dj
            px = (jx + 0.5 + jit[jy % gy, jx % gx, 0]) * cx
            py = (jy + 0.5 + jit[jy % gy, jx % gx, 1]) * cy
            d = np.sqrt((xx - px) ** 2 + (yy - py) ** 2)
            pid = (jy % gy) * gx + (jx % gx)
            m1 = d < f1
            f2 = np.where(m1, f1, np.minimum(f2, d))
            ids = np.where(m1, pid, ids)
            f1 = np.where(m1, d, f1)
    return f1, f2, ids


def toile():
    N = 1024
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    # la trame : 4 px par fil (≈ 256 fils au mètre), chaîne et trame qui passent dessus-dessous
    fx = (xx / 4.0) % 1.0
    fy = (yy / 4.0) % 1.0
    cx = np.floor(xx / 4.0)
    cy = np.floor(yy / 4.0)
    dessus = ((cx + cy) % 2) == 0
    fil_x = np.sin(fy * np.pi) ** 0.6
    fil_y = np.sin(fx * np.pi) ** 0.6
    trame = np.where(dessus, fil_x, fil_y)
    irr = vn(xx / 4.0, yy / 64.0, 256, 1901) * 0.5 + vn(xx / 64.0, yy / 4.0, 16, 1902) * 0.5
    nu = fbm(4, 4, 1903, N, N)
    pli = fbm(3, 3, 1904, N, N)
    c = np.ones((N, N, 3)) * np.array([0.86, 0.85, 0.82])
    c *= (0.8 + 0.14 * trame + 0.08 * (irr - 0.5))[..., None]
    c *= (0.9 + 0.14 * nu)[..., None]
    poussiere = np.clip((fbm(8, 3, 1905, N, N) - 0.6) * 3, 0, 1)
    c = c * (1 - 0.18 * poussiere[..., None]) + np.array([0.55, 0.5, 0.42]) * 0.18 * poussiere[..., None]
    h = trame * 0.5 + irr * 0.15 + pli * 0.6
    rough = np.full((N, N), 0.95)
    sauver("toile", c, h, 2.5, rough)


def brique_badigeon():
    src = np.asarray(Image.open(RACINE / "www" / "assets" / "textures" / "boucan" / "brique.png").convert("RGB")).astype(float) / 255.0
    N = src.shape[0]
    lum = src @ np.array([0.3, 0.55, 0.15])
    l0 = flou(lum, 1.0)
    m, sd = l0.mean(), l0.std() + 1e-6
    z = np.clip((l0 - m) / sd, -2.5, 2.5)
    joint = np.clip(-z - 0.6, 0, 2) / 2.0
    nu = fbm(5, 4, 1911, N, N)
    # les coulures : de longues traînées verticales
    coul = np.clip((valeur(40, 1912, N, N, cy=3) - 0.62) * 3, 0, 1)
    c = np.ones((N, N, 3)) * np.array([0.9, 0.89, 0.86])
    c *= (0.92 + 0.025 * np.clip(z, -1, 1) - 0.2 * joint + 0.07 * (nu - 0.5))[..., None]
    c *= (1 - 0.12 * coul)[..., None]
    h = 0.6 - joint * 0.8 + nu * 0.1
    sauver("brique_badigeon", c, h, 3.0, np.full((N, N), 0.9))


def main() -> int:
    import sys
    print("V166 : les textures de Pandémonia, de Montjoie et de Port-Boucan")
    for f in (toile, brique_badigeon):
        if len(sys.argv) < 2 or f.__name__ in sys.argv[1:]:
            f()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
