"""V162 : les textures de l'Atlantide et de l'île de la jungle (faites ici ; CC0 1.0). Dossier
www/assets/textures/beau162/.

  mosaique   le sol de la place : une vraie mosaïque romaine, faite de tesselles (2,5 cm sur le sol :
             la texture couvre 4 m), posées en rangs un peu de travers, chacune de sa nuance, les joints
             de mortier entre elles ; le dessin : des cercles qui se croisent (des « quatre-feuilles »)
             bleu de mer sur fond crème, un cœur d'or au milieu de chaque fleur, de petites croix
             turquoise entre elles. Le relief : les tesselles bombées, les joints en creux.

  karst      le calcaire des pitons de la jungle (la texture couvre 11 m) : les cannelures creusées
             par la pluie (des rigoles verticales qui naissent et s'effacent), les joints de
             stratification, les coulures noires (les algues), des taches d'ocre, de petits trous,
             des lichens gris et jaunes. Le relief : les rigoles, les trous, les joints.

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_textures_v162.py
"""
from pathlib import Path

import numpy as np
from PIL import Image

RACINE = Path(__file__).resolve().parents[2]
OUT = RACINE / "www" / "assets" / "textures" / "beau162"


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


def fbm(cell, oct_, seed, w, h, gain=0.5):
    s = np.zeros((h, w))
    amp = tot = 1.0
    s += valeur(cell, seed, w, h)
    for o in range(1, oct_):
        amp *= gain
        s += amp * valeur(cell * 2 ** o, seed + o * 17, w, h)
        tot += amp
    return s / tot


def normale(h, force):
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * force
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5 * force
    l = np.sqrt(dx * dx + dy * dy + 1.0)
    return np.stack([-dx / l * 0.5 + 0.5, dy / l * 0.5 + 0.5, 1.0 / l * 0.5 + 0.5], -1)


def sauver(nom, c, h=None, force=3.0, rough=None):
    OUT.mkdir(parents=True, exist_ok=True)
    c = np.clip(c, 0, 1)
    Image.fromarray((c * 255).round().astype(np.uint8)).save(OUT / f"{nom}.png", optimize=True)
    if h is not None:
        Image.fromarray((np.clip(normale(h, force), 0, 1) * 255).round().astype(np.uint8)).save(OUT / f"{nom}_n.png", optimize=True)
    if rough is not None:
        Image.fromarray((np.clip(rough, 0, 1) * 255).round().astype(np.uint8), "L").save(OUT / f"{nom}_r.png", optimize=True)
    print("  ", nom)


def mosaique():
    N = 2048
    n_t = 160                       # tesselles par côté
    ts = N / n_t
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    # les rangs : chaque rang un peu décalé, chaque tesselle un peu plus ou moins large
    rang = np.floor(yy / ts)
    dec = (np.sin(rang * 12.9898) * 43758.5453 % 1.0) * ts
    u = (xx + dec) / ts
    v = yy / ts
    iu = np.floor(u) % n_t
    iv = np.floor(v) % n_t
    fu = u - np.floor(u)
    fv = v - np.floor(v)
    h1 = (np.sin(iu * 12.9898 + iv * 78.233) * 43758.5453) % 1.0
    h2 = (np.sin(iu * 39.346 + iv * 11.135) * 43758.5453) % 1.0
    # le centre de chaque tesselle, en coordonnées du motif (4 répétitions par texture)
    cx = ((iu + 0.5) * ts - dec) / N
    cy = (iv + 0.5) / n_t
    rep = 4.0
    px = (cx * rep) % 1.0
    py = (cy * rep) % 1.0
    # des cercles qui se croisent : centrés sur les coins et le milieu de la case
    R = 0.5
    def d(ax, ay):
        dx = px - ax
        dy = py - ay
        return np.sqrt(dx * dx + dy * dy)
    dmin = np.minimum.reduce([np.abs(d(a, b) - R) for a, b in ((0, 0), (1, 0), (0, 1), (1, 1), (0.5, 0.5))])
    trait = dmin < 0.035
    # le cœur des fleurs (au milieu des pétales) : or ; les petites croix entre elles : turquoise
    dc = np.minimum(d(0.5, 0.0), np.minimum(d(0.0, 0.5), np.minimum(d(1.0, 0.5), d(0.5, 1.0))))
    coeur = dc < 0.075
    croix = ((np.abs(px - 0.5) < 0.025) | (np.abs(py - 0.5) < 0.025)) & (d(0.5, 0.5) < 0.14) & ~trait
    bord = np.abs(dc - 0.11) < 0.02
    creme = np.array([0.86, 0.81, 0.7])
    bleu = np.array([0.14, 0.3, 0.5])
    turq = np.array([0.28, 0.56, 0.58])
    orr = np.array([0.82, 0.64, 0.28])
    c = np.empty((N, N, 3))
    c[:] = creme
    c[trait] = bleu
    c[bord] = turq
    c[coeur] = orr
    c[croix] = turq
    # chaque tesselle sa nuance
    c *= (0.88 + 0.2 * h1)[..., None]
    c *= (1.0 + 0.06 * (h2[..., None] - 0.5) * np.array([1.0, 0.6, -0.4]))
    # les joints
    ju = np.minimum(fu, 1 - fu)
    jv = np.minimum(fv, 1 - fv)
    joint = np.clip(1 - np.minimum(ju, jv) / 0.12, 0, 1)
    c = c * (1 - joint[..., None] * 0.55) + np.array([0.42, 0.4, 0.36]) * joint[..., None] * 0.55
    # l'usure : de grandes nuances, des taches
    us = fbm(6, 5, 1621, N, N)
    c *= (0.9 + 0.16 * us)[..., None]
    bomb = np.clip(np.minimum(ju, jv) / 0.2, 0, 1) ** 0.5
    h = bomb * 0.8 + h1 * 0.05
    r = 0.45 + 0.35 * joint
    sauver("mosaique", c, h, 2.5, r)


def karst():
    N = 2048
    rng = np.random.default_rng(1622)
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    # les cannelures : des rigoles verticales (un peu ondulées), qui naissent et s'effacent
    warp = valeur(12, 1623, N, N, cy=4) * 18.0
    x2 = xx + warp
    per = N / 220.0
    rig = np.abs(np.sin(x2 / per * np.pi)) ** 0.6
    long_ = valeur(220, 1624, N, N, cy=10)
    vie = np.clip((long_ - 0.35) * 3.0, 0, 1)
    flutes = (1 - rig) * vie
    # les joints de stratification : tous les ~1,5 m (la texture couvre 11 m), un peu de travers
    lit = (yy / N * 7.0 + valeur(4, 1625, N, N, cy=2) * 0.6) % 1.0
    joint = np.clip(1 - np.abs(lit - 0.5) * 2 / 0.05, 0, 1) ** 2 * np.clip((valeur(24, 1626, N, N, cy=3) - 0.35) * 2.5, 0, 1)
    # les coulures noires (verticales), l'ocre, les petits trous, les lichens
    coul = valeur(70, 1627, N, N, cy=3) * 0.7 + valeur(160, 1628, N, N, cy=6) * 0.3
    noir = np.clip((coul - 0.56) * 4, 0, 1) * (0.4 + 0.6 * valeur(6, 1629, N, N))
    ocre = np.clip((fbm(6, 4, 1630, N, N) - 0.66) * 4, 0, 1)
    trous = (rng.random((N, N)) > 0.9965).astype(float)
    trous = np.maximum(trous, np.roll(trous, 1, 0) * 0.7)
    trous = np.maximum(trous, np.roll(trous, 1, 1) * 0.7)
    lich = np.clip((fbm(40, 3, 1631, N, N) - 0.72) * 6, 0, 1)
    lich_j = np.clip((fbm(36, 3, 1632, N, N) - 0.76) * 6, 0, 1)
    nuage = fbm(5, 5, 1633, N, N)
    base = np.array([0.52, 0.51, 0.47]) * (0.8 + 0.34 * nuage)[..., None]
    c = base * (1 - 0.18 * flutes)[..., None]
    c *= (1 - 0.07 * joint)[..., None]
    c = c * (1 - 0.55 * noir[..., None]) + np.array([0.16, 0.16, 0.15]) * 0.55 * noir[..., None]
    c = c * (1 - 0.35 * ocre[..., None]) + np.array([0.62, 0.45, 0.28]) * 0.35 * ocre[..., None]
    c = c * (1 - 0.5 * lich[..., None]) + np.array([0.82, 0.82, 0.76]) * 0.5 * lich[..., None]
    c = c * (1 - 0.45 * lich_j[..., None]) + np.array([0.72, 0.7, 0.32]) * 0.45 * lich_j[..., None]
    c *= (1 - 0.6 * trous)[..., None]
    h = -flutes * 0.9 - joint * 0.2 - trous * 1.2 + nuage * 0.2 + lich * 0.05
    r = 0.8 - 0.25 * noir
    sauver("karst", c, h, 3.0, r)


def main() -> int:
    print("V162 : les textures de l'Atlantide et de la jungle")
    mosaique()
    karst()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
