"""V160 : le kit des métaux (faites ici ; CC0 1.0), pour toutes les villes (Hautefond, la Cité des
Nuées, les Strates, le Dôme d'Azur, l'Île Perchée). Les métaux y étaient des aplats de couleur : en VR,
ils avaient l'air de plastique. Chaque métal : la couleur (neutre : le jeu la teinte), le relief
(_n) et la rugosité (_r : le reflet n'est pas le même partout).

  metal_brosse   l'acier, l'aluminium, le titane : le brossage (de fines stries), des rayures   0,5 m
  metal_patine   le laiton, le bronze, l'or, le cuivre : la patine, les traces, les creux plus
                 sombres, les parties polies par les mains, de petits coups                    0,6 m
  verdigris      le cuivre vert-de-gris : le vert qui coule en traînées, le cuivre qui
                 reparaît par endroits (en couleur)                                            1,0 m
  fer_noir       le fer forgé noir : la calamine, de petites piqûres, un peu de rouille         0,6 m
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_textures_v160.py
"""
from pathlib import Path

import numpy as np
from PIL import Image

N = 1024
OUT = Path(__file__).resolve().parents[2] / "www" / "assets" / "textures" / "beau160"


def valeur(cx, seed, n=N, cy=None):
    cy = cy or cx
    r = np.random.default_rng(seed)
    g = r.random((cy, cx))

    def axe(c):
        x = np.arange(n) * c / n
        i0 = np.floor(x).astype(int)
        f = x - i0
        return i0 % c, (i0 + 1) % c, f * f * (3 - 2 * f)
    y0, y1, fy = axe(cy)
    x0, x1, fx = axe(cx)
    fy, fx = fy[:, None], fx[None, :]
    return (g[np.ix_(y0, x0)] * (1 - fx) + g[np.ix_(y0, x1)] * fx) * (1 - fy) + (g[np.ix_(y1, x0)] * (1 - fx) + g[np.ix_(y1, x1)] * fx) * fy


def fbm(cell, oct_, seed, n=N, gain=0.5):
    s = np.zeros((n, n))
    amp = tot = 1.0
    s += valeur(cell, seed, n)
    for o in range(1, oct_):
        amp *= gain
        s += amp * valeur(cell * 2 ** o, seed + o * 17, n)
        tot += amp
    return s / tot


def flou(x, k=1):
    out = x.copy()
    for _ in range(k):
        out = (out + np.roll(out, 1, 0) + np.roll(out, -1, 0) + np.roll(out, 1, 1) + np.roll(out, -1, 1)) / 5.0
    return out


def normale(h, force):
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * force
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5 * force
    l = np.sqrt(dx * dx + dy * dy + 1.0)
    return np.stack([-dx / l * 0.5 + 0.5, dy / l * 0.5 + 0.5, 1.0 / l * 0.5 + 0.5], -1)


def rayures(seed, nombre, long0, long1, n=N):
    """De fines rayures droites (raccordables) : un masque 0..1."""
    r = np.random.default_rng(seed)
    m = np.zeros((n, n))
    for _ in range(nombre):
        x, y = r.random() * n, r.random() * n
        a = r.random() * np.pi
        l = r.uniform(long0, long1)
        k = int(l)
        t = np.linspace(0, 1, k)
        xs = (x + np.cos(a) * l * t).astype(int) % n
        ys = (y + np.sin(a) * l * t).astype(int) % n
        m[ys, xs] = np.maximum(m[ys, xs], r.uniform(0.4, 1.0))
    return m


def bosses(seed, nombre, r0, r1, n=N):
    r = np.random.default_rng(seed)
    h = np.zeros((n, n))
    for _ in range(nombre):
        cx, cy = r.random() * n, r.random() * n
        rr = r.uniform(r0, r1)
        x0, x1 = int(cx - rr) - 1, int(cx + rr) + 2
        y0, y1 = int(cy - rr) - 1, int(cy + rr) + 2
        ys = np.arange(y0, y1)
        xs = np.arange(x0, x1)
        d2 = ((ys[:, None] - cy) ** 2 + (xs[None, :] - cx) ** 2) / (rr * rr)
        b = np.clip(1 - d2, 0, 1) ** 2
        yi, xi = ys % n, xs % n
        h[np.ix_(yi, xi)] = np.maximum(h[np.ix_(yi, xi)], b)
    return h


def sauver(nom, c, h=None, force=3.0, rough=None):
    OUT.mkdir(parents=True, exist_ok=True)
    c = np.clip(c, 0, 1)
    if c.ndim == 2:
        c = np.repeat(c[..., None], 3, -1)
    Image.fromarray((c * 255).round().astype(np.uint8)).save(OUT / f"{nom}.png", optimize=True)
    if h is not None:
        Image.fromarray((np.clip(normale(h, force), 0, 1) * 255).round().astype(np.uint8)).save(OUT / f"{nom}_n.png", optimize=True)
    if rough is not None:
        Image.fromarray((np.clip(rough, 0, 1) * 255).round().astype(np.uint8), "L").save(OUT / f"{nom}_r.png", optimize=True)
    print("  ", nom)


# =================================================================== les métaux

def metal_brosse():
    # le brossage : un bruit très étiré dans le sens du brossage (x), à plusieurs échelles
    stries = valeur(4, 1601, cy=N // 2) * 0.5 + valeur(8, 1602, cy=N // 4) * 0.3 + valeur(2, 1603, cy=N) * 0.2
    nuage = fbm(4, 4, 1604)
    ray = flou(rayures(1605, 70, 15, 110), 1) * 0.5
    v = 0.84 + 0.08 * (stries - 0.5) + 0.05 * (nuage - 0.5) + 0.05 * ray
    h = stries * 0.4 - ray * 0.4
    r = 0.85 + 0.15 * (stries - 0.5) + 0.12 * (nuage - 0.5) - 0.2 * ray
    sauver("metal_brosse", v, h, 2.0, r)


def metal_patine():
    nuage = fbm(3, 5, 1606)
    taches = fbm(16, 4, 1607)
    creux = np.clip((0.4 - taches) * 3, 0, 1)                   # la crasse dans les creux
    poli = np.clip((nuage - 0.6) * 3, 0, 1)                     # les endroits polis par les mains
    coups = bosses(1608, 60, 6, 18) * 0.6
    grain = flou(np.random.default_rng(1609).random((N, N)), 1)
    ray = flou(rayures(1610, 50, 10, 60), 1) * 0.5
    v = 0.82 + 0.06 * (nuage - 0.5) - 0.13 * creux + 0.07 * poli + 0.04 * (grain - 0.5) + 0.03 * ray
    h = -coups * 0.6 + grain * 0.04 - ray * 0.2
    r = 0.9 + 0.25 * creux - 0.35 * poli + 0.06 * (grain - 0.5) - 0.2 * ray
    sauver("metal_patine", v, h, 3.0, np.clip(r, 0.3, 1.0))


def verdigris():
    yy, xx = np.mgrid[0:N, 0:N] / N
    nuage = fbm(4, 5, 1611)
    # des traînées qui coulent vers le bas : un bruit étiré en hauteur
    coulures = valeur(40, 1612, cy=14) * 0.6 + valeur(80, 1613, cy=28) * 0.4
    tache = fbm(24, 3, 1618)
    patine = np.clip((nuage * 0.5 + coulures * 0.4 + tache * 0.3 - 0.36) * 2.6, 0, 1)
    cuivre = np.array([0.46, 0.26, 0.16]) * (0.8 + 0.3 * fbm(16, 3, 1614))[..., None]
    vert = np.array([0.32, 0.6, 0.5]) * (0.75 + 0.4 * fbm(24, 3, 1615))[..., None]
    vert = vert * (1 - 0.25 * flou(np.random.default_rng(1616).random((N, N)), 1))[..., None]
    c = cuivre * (1 - patine[..., None]) + vert * patine[..., None]
    h = patine * 0.25 + flou(np.random.default_rng(1617).random((N, N)), 1) * 0.15 * patine
    r = 0.45 + 0.5 * patine
    sauver("verdigris", c, h, 3.0, r)


def fer_noir():
    calamine = fbm(6, 5, 1618)
    piqures = bosses(1619, 900, 1.5, 4.0)
    rouille = np.clip((fbm(8, 4, 1620) - 0.68) * 5, 0, 1)
    grain = flou(np.random.default_rng(1621).random((N, N)), 1)
    v = 0.2 + 0.08 * (calamine - 0.5) - 0.08 * piqures + 0.04 * (grain - 0.5)
    c = np.repeat(v[..., None], 3, -1) * np.array([1.0, 1.0, 1.04])
    c = c * (1 - rouille[..., None]) + np.array([0.36, 0.19, 0.1]) * rouille[..., None]
    h = -piqures * 0.5 + grain * 0.05 + calamine * 0.1
    r = 0.6 + 0.2 * (calamine - 0.5) + 0.3 * rouille
    sauver("fer_noir", c, h, 4.0, r)


def main() -> int:
    print("V160 : le kit des métaux")
    metal_brosse()
    metal_patine()
    verdigris()
    fer_noir()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
