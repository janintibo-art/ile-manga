"""V159 : les matières du Bois-Doré, de la Montagne de Feu et de Forgefer (faites ici ; CC0 1.0).

Chaque matière : une image de couleur (nom.png) et sa carte de relief (nom_n.png), 1024 × 1024,
qui se raccordent sur leurs bords.

  tuiles_feuilles   le toit des maisons des elfes : des écailles en forme de feuille, cuivre
                    vert-de-gris, une nervure au milieu                                  1,0 m
  pierre_naine      la pierre taillée des nains : de grands blocs (50 cm de haut), leurs
                    joints, les coups de ciseau en biais, le grain du granit             2,0 m
  dalles_naines     le dallage de la Grande Halle : de grandes dalles (1 m), une gorge
                    gravée sur leur pourtour, une rune au milieu, l'usure                 2,0 m
  fer_martele       le fer martelé : les coups de marteau, la calamine, un peu de rouille 0,6 m
  ecorce_calcinee   le bois brûlé des arbres morts du volcan : la peau de crocodile du
                    charbon de bois, ses fentes, la cendre sur les écailles             1,0 m
  banniere_naine    une bannière de Forgefer (512 × 1024) : un drap rouge, une bordure d'or,
                    le marteau sur l'enclume sous la montagne (couleur seule)
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_textures_v159.py
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

N = 1024
OUT = Path(__file__).resolve().parents[2] / "www" / "assets" / "textures" / "beau159"


# =================================================================== outils (raccordables)

def valeur(cell, seed, n=N, cy=None):
    cy = cy or cell
    r = np.random.default_rng(seed)
    g = r.random((cy, cell))

    def axe(c):
        x = np.arange(n) * c / n
        i0 = np.floor(x).astype(int)
        f = x - i0
        return i0 % c, (i0 + 1) % c, f * f * (3 - 2 * f)
    y0, y1, fy = axe(cy)
    x0, x1, fx = axe(cell)
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


def grain(seed, n=N):
    return np.random.default_rng(seed).random((n, n))


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


def teinte(v, c0, c1):
    v = np.clip(v, 0, 1)[..., None]
    return np.array(c0)[None, None, :] * (1 - v) + np.array(c1)[None, None, :] * v


def sauver(nom, couleur, h=None, force=4.0):
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(couleur, 0, 1) * 255).round().astype(np.uint8)).save(OUT / f"{nom}.png", optimize=True)
    if h is not None:
        Image.fromarray((np.clip(normale(h, force), 0, 1) * 255).round().astype(np.uint8)).save(OUT / f"{nom}_n.png", optimize=True)
    print("  ", nom)


def voronoi(n_pts, seed, n=N, sx=1.0, sy=1.0):
    """Cellules (raccordables) : d1, d2 (distances au plus proche et au second), l'indice de la cellule."""
    r = np.random.default_rng(seed)
    pts = r.random((n_pts, 2)) * n
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float64)
    d1 = np.full((n, n), 1e9)
    d2 = np.full((n, n), 1e9)
    idx = np.zeros((n, n), dtype=int)
    for i, (px, py) in enumerate(pts):
        dx = (((xx - px) + n / 2) % n - n / 2) * sx
        dy = (((yy - py) + n / 2) % n - n / 2) * sy
        d = np.sqrt(dx * dx + dy * dy)
        closer = d < d1
        d2 = np.where(closer, d1, np.minimum(d2, d))
        d1 = np.where(closer, d, d1)
        idx = np.where(closer, i, idx)
    return d1, d2, idx


# =================================================================== les matières

def tuiles_feuilles():
    """Des écailles en feuille, posées en rangs décalés ; le rang du dessus recouvre le haut du
    rang du dessous (on dessine de bas en haut)."""
    rangs, par_rang = 14, 10
    hr = N / rangs
    w = N / par_rang
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float64)
    h = np.full((N, N), -1.0)
    teintes = np.zeros((N, N))
    nerv = np.zeros((N, N))
    bord = np.zeros((N, N))
    r = np.random.default_rng(1591)
    tv = r.random((rangs, par_rang))
    L = hr * 1.85                                    # longueur d'une écaille
    # chaque écaille à sa vraie place (avec ses copies au-dessus et au-dessous, pour raccorder) ;
    # on dessine de la plus basse à la plus haute : celle du dessus recouvre
    places = []
    for row in range(rangs):
        for i in range(par_rang):
            cx = (i + 0.5 * (row % 2)) * w
            for oy in (-N, 0, N):
                places.append((row * hr - L + hr + oy, cx, row, i))
    places.sort(key=lambda p: -p[0])
    for y0, cx, row, i in places:
        for ox in (-N, 0, N):
            x0 = cx + ox
            if y0 > N + 2 or y0 + L < -2 or x0 + w < -2 or x0 - w > N + 2:
                continue
            ys = slice(max(0, int(y0)), min(N, int(y0 + L) + 1))
            xs = slice(max(0, int(x0 - w * 0.6)), min(N, int(x0 + w * 0.6) + 1))
            v = (yy[ys, xs] - y0) / L                         # 0 en haut, 1 à la pointe
            u = (xx[ys, xs] - x0) / (w * 0.56)
            demi = np.where(v < 0.55, np.sin(np.clip(v / 0.55, 0, 1) * np.pi * 0.5) ** 0.5, np.cos(np.clip((v - 0.55) / 0.45, 0, 1) * np.pi * 0.5) ** 0.8)
            put = (np.abs(u) < demi) & (v > 0) & (v < 1)
            if not put.any():
                continue
            k = np.clip(1 - (np.abs(u) / np.maximum(demi, 1e-3)) ** 2, 0, 1)
            hh = np.sqrt(k) * 0.6 + v * 0.5
            cur = h[ys, xs]
            cur[put] = hh[put]
            h[ys, xs] = cur
            t = teintes[ys, xs]
            t[put] = tv[row, i]
            teintes[ys, xs] = t
            nv = nerv[ys, xs]
            nv[put] = np.clip(1 - np.abs(u[put]) * 14, 0, 1) * np.clip(v[put] * 1.4, 0, 1)
            nerv[ys, xs] = nv
            bd = bord[ys, xs]
            bd[put] = 1 - k[put]
            bord[ys, xs] = bd
    h = np.where(h < -0.5, 0.0, h)
    patine = fbm(8, 4, 1592)
    base = teinte(teintes * 0.7 + patine * 0.3, (0.16, 0.3, 0.24), (0.34, 0.5, 0.4))
    # les bords des écailles plus clairs (le vert-de-gris), la nervure dorée à peine
    base = base * (1 - 0.25 * bord[..., None]) + np.array([0.55, 0.72, 0.6]) * 0.25 * bord[..., None] * (patine[..., None] > 0.45)
    base = base * (1 - 0.35 * nerv[..., None]) + np.array([0.75, 0.62, 0.3]) * 0.35 * nerv[..., None]
    base = base * (0.9 + 0.2 * flou(grain(1593), 1))[..., None]
    # l'ombre sous le bord de l'écaille du dessus
    ombre = np.clip(np.roll(h, 3, 0) - h, 0, 1)
    base = base * (1 - 0.5 * np.clip(ombre * 2.5, 0, 1))[..., None]
    sauver("tuiles_feuilles", base, flou(h, 1) - nerv * 0.06, 9.0)


def pierre_naine():
    """De grands blocs taillés (4 rangs de 50 cm sur 2 m), joints fins, ciseau en biais."""
    rangs = 4
    hr = N // rangs
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float64)
    r = np.random.default_rng(1594)
    bloc = np.zeros((N, N), dtype=int)
    dx_joint = np.full((N, N), 1e9)
    for k in range(rangs):
        nb = int(r.integers(2, 4))
        xs = np.sort(r.random(nb) * N)
        rows = slice(k * hr, (k + 1) * hr)
        xk = xx[rows]
        idx = np.zeros_like(xk, dtype=int)
        d = np.full_like(xk, 1e9)
        for j, x0 in enumerate(xs):
            idx += (xk >= x0)
            d = np.minimum(d, np.abs(((xk - x0 + N / 2) % N) - N / 2))
        bloc[rows] = (idx % nb) + k * 5
        dx_joint[rows] = d
    ly = (yy % hr)
    dy_joint = np.minimum(ly, hr - ly)
    dj = np.minimum(dx_joint, dy_joint)
    joint = np.clip(1 - dj / 3.0, 0, 1)
    biseau = np.clip(dj / 14.0, 0, 1)
    tint = 0.86 + 0.24 * r.random(64)
    ang = r.uniform(0.5, 1.1, 64) * np.where(r.random(64) > 0.5, 1, -1)
    a = ang[bloc]
    ciseau = np.sin((xx * np.cos(a) + yy * np.sin(a)) * 0.55 + fbm(32, 2, 1595) * 6.0) * 0.5 + 0.5
    ciseau = ciseau * (0.6 + 0.4 * fbm(16, 3, 1596))
    granit = flou(grain(1597), 1)
    taches = (grain(1598) > 0.985).astype(float)
    nuage = fbm(4, 4, 1599)
    v = tint[bloc] * (0.62 + 0.12 * nuage + 0.1 * (granit - 0.5) + 0.05 * ciseau) - 0.18 * flou(taches, 1)
    v = v * (0.75 + 0.25 * biseau)
    c = teinte(v, (0.12, 0.11, 0.1), (0.78, 0.74, 0.68))
    c = c * (1 - 0.65 * joint[..., None]) + np.array([0.12, 0.1, 0.09]) * 0.65 * joint[..., None]
    h = np.sqrt(biseau) * 1.0 + ciseau * 0.05 + granit * 0.02 - joint * 0.4
    sauver("pierre_naine", c, h, 6.0)


def dalles_naines():
    """De grandes dalles (2 × 2 sur 2 m) : biseau, une gorge gravée sur le pourtour, une rune."""
    k = 2
    s = N // k
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float64)
    u = (xx % s) / s
    v = (yy % s) / s
    bord = np.minimum(np.minimum(u, 1 - u), np.minimum(v, 1 - v)) * s
    joint = np.clip(1 - bord / 3.0, 0, 1)
    biseau = np.clip(bord / 12.0, 0, 1)
    # la gorge gravée, à 9 % du bord
    gorge_d = np.abs(np.minimum(np.minimum(u, 1 - u), np.minimum(v, 1 - v)) - 0.09) * s
    gorge = np.clip(1 - gorge_d / 3.5, 0, 1)
    # une rune au milieu : un losange, une croix de branches (la rune des forges)
    cu, cv = u - 0.5, v - 0.5
    los = np.abs(np.abs(cu) + np.abs(cv) - 0.16) * s
    rune = np.clip(1 - los / 3.0, 0, 1)
    tige = np.clip(1 - np.abs(cu) * s / 3.0, 0, 1) * (np.abs(cv) < 0.24)
    bras = np.clip(1 - np.abs(np.abs(cu) - (0.24 - np.abs(cv))) * s / 3.0, 0, 1) * (cv < -0.06) * (np.abs(cu) < 0.18)
    rune = np.maximum(rune, np.maximum(tige, bras))
    idx = (np.floor(xx / s) + np.floor(yy / s) * 7).astype(int)
    tint = 0.88 + 0.2 * np.random.default_rng(1600).random(64)
    usure = fbm(3, 4, 1601)
    granit = flou(grain(1602), 1)
    poli = np.clip(1 - np.hypot(cu, cv) * 1.6, 0, 1)                    # le milieu, poli par les pas
    val = tint[idx % 64] * (0.5 + 0.12 * usure + 0.08 * (granit - 0.5) + 0.08 * poli)
    c = teinte(val, (0.1, 0.1, 0.11), (0.7, 0.68, 0.68))
    c = c * (0.8 + 0.2 * biseau[..., None])
    c = c * (1 - 0.45 * np.maximum(gorge, rune)[..., None])
    c = c * (1 - 0.65 * joint[..., None]) + np.array([0.08, 0.07, 0.07]) * 0.65 * joint[..., None]
    h = np.sqrt(biseau) - 0.35 * gorge - 0.35 * rune + granit * 0.02 - 0.4 * joint
    sauver("dalles_naines", c, h, 6.0)


def fer_martele():
    """Le fer martelé : des coups de marteau (des creux ronds qui se chevauchent), la calamine."""
    d1, d2, idx = voronoi(260, 1603)
    r = np.random.default_rng(1604)
    rr = 18.0 + 10.0 * r.random(260)
    creux = np.clip(1 - (d1 / rr[idx]) ** 2, 0, 1)
    arete = np.clip(1 - (d2 - d1) / 3.0, 0, 1)
    calamine = fbm(6, 4, 1605)
    rouille = np.clip((fbm(10, 4, 1606) - 0.66) * 5, 0, 1) * (1 - creux * 0.3)
    v = 0.36 + 0.12 * creux + 0.1 * (calamine - 0.5) + 0.06 * arete
    c = teinte(v, (0.05, 0.05, 0.055), (0.55, 0.55, 0.58))
    c = c * (1 - rouille[..., None]) + np.array([0.32, 0.17, 0.09]) * rouille[..., None]
    h = -creux * 0.6 + arete * 0.08 + flou(grain(1607), 1) * 0.02
    sauver("fer_martele", c, h, 5.0)


def ecorce_calcinee():
    """Le bois brûlé : des écailles en peau de crocodile (allongées dans le sens du fil), fendues."""
    d1, d2, idx = voronoi(170, 1608, sx=1.0, sy=0.45)
    fente = np.clip(1 - (d2 - d1) / 5.0, 0, 1)
    ecaille = np.clip((d2 - d1) / 24.0, 0, 1)
    r = np.random.default_rng(1609)
    tint = 0.7 + 0.6 * r.random(170)
    fil = flou(valeur(N // 6, 1610, cy=12), 1)
    cendre = np.clip((fbm(12, 3, 1611) - 0.55) * 4, 0, 1) * ecaille
    v = tint[idx] * (0.08 + 0.06 * fil + 0.05 * ecaille)
    c = np.repeat(v[..., None], 3, -1) * np.array([1.0, 0.95, 0.92])
    c = c + cendre[..., None] * np.array([0.22, 0.21, 0.2]) * 0.6
    # un éclat bleuté, celui du charbon de bois, sur le dessus des écailles
    c = c + (np.clip(ecaille - 0.6, 0, 1) * 0.06)[..., None] * np.array([0.6, 0.7, 0.9])
    c = c * (1 - 0.8 * fente[..., None])
    h = np.sqrt(ecaille) * 0.9 + fil * 0.1 - fente * 0.6
    sauver("ecorce_calcinee", c, h, 7.0)


def banniere_naine():
    """La bannière de Forgefer : le drap rouge (sa trame), une bordure d'or, l'emblème."""
    W, H = 512, 1024
    S = 2                                             # dessiné deux fois plus grand, puis réduit
    img = Image.new("RGB", (W * S, H * S), (128, 18, 22))
    d = ImageDraw.Draw(img)
    or_ = (214, 168, 70)
    or_s = (150, 108, 40)
    b = 34 * S
    d.rectangle((b, b, W * S - b, H * S - b), outline=or_, width=10 * S)
    d.rectangle((b + 22 * S, b + 22 * S, W * S - b - 22 * S, H * S - b - 22 * S), outline=or_s, width=3 * S)
    cx, cy = W * S // 2, int(H * S * 0.42)
    # la montagne
    d.polygon([(cx - 150 * S, cy + 120 * S), (cx, cy - 170 * S), (cx + 150 * S, cy + 120 * S)], outline=or_, width=8 * S)
    d.polygon([(cx - 60 * S, cy - 78 * S), (cx, cy - 170 * S), (cx + 60 * S, cy - 78 * S), (cx + 25 * S, cy - 60 * S), (cx, cy - 85 * S), (cx - 25 * S, cy - 60 * S)], fill=or_)
    # l'enclume
    d.polygon([(cx - 95 * S, cy + 30 * S), (cx + 70 * S, cy + 30 * S), (cx + 110 * S, cy + 10 * S), (cx + 60 * S, cy + 55 * S),
               (cx + 30 * S, cy + 55 * S), (cx + 45 * S, cy + 100 * S), (cx - 55 * S, cy + 100 * S), (cx - 40 * S, cy + 55 * S), (cx - 80 * S, cy + 55 * S)], fill=or_)
    # le marteau, en biais au-dessus
    import math
    a = math.radians(-35)

    def rot(px, py):
        return (cx + (px * math.cos(a) - py * math.sin(a)) * S, cy - 40 * S + (px * math.sin(a) + py * math.cos(a)) * S)
    d.polygon([rot(-12, -10), rot(110, -10), rot(110, 10), rot(-12, 10)], fill=or_s)
    d.polygon([rot(-60, -34), rot(-12, -34), rot(-12, 34), rot(-60, 34)], fill=or_)
    # des runes en bas, sur une bande
    y0 = int(H * S * 0.78)
    d.line((b + 40 * S, y0, W * S - b - 40 * S, y0), fill=or_s, width=3 * S)
    for k in range(7):
        x = b + 70 * S + k * 52 * S
        d.line((x, y0 + 20 * S, x, y0 + 70 * S), fill=or_, width=5 * S)
        d.line((x, y0 + 20 * S, x + 18 * S, y0 + (35 + (k % 3) * 8) * S), fill=or_, width=5 * S)
        if k % 2:
            d.line((x, y0 + 45 * S, x - 16 * S, y0 + 60 * S), fill=or_, width=5 * S)
    img = img.resize((W, H), Image.LANCZOS)
    a_ = np.asarray(img, dtype=np.float64) / 255.0
    # la trame du drap et des plis doux
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float64)
    trame = (np.sin(xx * np.pi) * 0.5 + 0.5) * (np.sin(yy * np.pi) * 0.5 + 0.5)
    plis = np.sin(xx / W * np.pi * 5.0 + np.sin(yy / H * 3.0) * 0.6) * 0.5 + 0.5
    a_ = a_ * (0.88 + 0.08 * trame + 0.1 * plis)[..., None]
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(a_, 0, 1) * 255).round().astype(np.uint8)).save(OUT / "banniere_naine.png", optimize=True)
    print("   banniere_naine")


def main() -> int:
    print("V159 : les matières du Bois-Doré, de la Montagne de Feu et de Forgefer")
    tuiles_feuilles()
    pierre_naine()
    dalles_naines()
    fer_martele()
    ecorce_calcinee()
    banniere_naine()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
