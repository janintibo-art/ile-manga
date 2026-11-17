"""V164 : les textures de la Grande Île (faites ici ; CC0 1.0). Dossier www/assets/textures/beau164/.

  porte_sceaux   les deux vantaux de la Porte aux Quatre Sceaux (14,5 × 18,4 m, d'un seul tenant :
                 la moitié gauche va sur le vantail gauche) : la pierre taillée d'un seul bloc, le cadre
                 en relief, la grande rainure du cercle, la bande des runes autour, les rosaces des
                 quatre creux, les quatre symboles (l'engrenage de l'Airain en haut, les vagues des
                 Embruns à gauche, la dune des Sables en bas, la spirale des Brumes à droite), le
                 cœur au milieu, les panneaux du bas, les fissures, les coulures, la mousse au pied.
  frise_sceaux   la frise du linteau (24 × 4 m) : les moulures, les quatre symboles dans leurs
                 médaillons, le soleil au milieu, les runes entre eux.
  pont_leviathan le pont du Léviathan (la texture couvre 8,3 m) : des bordages de chêne de 22 cm,
                 gris argent où le soleil et le sel les ont lavés, brun ailleurs, les coutures de brai
                 noir, les abouts décalés, les chevilles de bois par paires, les taches d'eau, le sel.
  ecorce_buche   les bûches du feu de camp et les bancs : l'écorce de chêne crevassée.
  cerne          le bout coupé d'une bûche : les cernes, les fentes du séchage, l'aubier.

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_textures_v164.py
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

RACINE = Path(__file__).resolve().parents[2]
OUT = RACINE / "www" / "assets" / "textures" / "beau164"


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


# =================================================================== la pierre sculptée

def _pierre(c_relief, W, H, seed):
    """Une pierre taillée (couleur, grain) et son relief sculpté : rend la couleur, la hauteur."""
    grain = fbm(int(W / 6), 4, seed, W, H, cy=int(H / 6))
    nuage = fbm(5, 5, seed + 1, W, H, cy=int(5 * H / W) + 1)
    base = np.array([0.6, 0.57, 0.52]) * (0.84 + 0.22 * nuage + 0.08 * (grain - 0.5))[..., None]
    h = c_relief + grain * 0.04
    # le creux (l'ombre au fond des gravures) : la différence entre le relief et son flou
    cav = np.clip((flou(h, 6.0) - h) * 6.0, 0, 1)
    arete = np.clip((h - flou(h, 3.0)) * 8.0, 0, 1)
    c = base * (1 - 0.5 * cav[..., None]) * (1 + 0.12 * arete[..., None])
    return c, h


def _vieillir(c, h, W, H, seed, mousse_bas=0.18):
    yy, xx = np.mgrid[0:H, 0:W].astype(float)
    rng = np.random.default_rng(seed)
    # les fissures : des marches au hasard, un peu ramifiées
    img = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(img)
    for k in range(9):
        x, y = rng.random() * W, rng.random() * H * 0.9
        a = rng.random() * 6.28
        for s in range(rng.integers(40, 120)):
            a += rng.normal(0, 0.35)
            x2, y2 = x + np.cos(a) * 6, y + abs(np.sin(a)) * 6 + 2
            d.line([(x, y), (x2, y2)], fill=255, width=2 if s < 30 else 1)
            x, y = x2, y2
    fis = np.asarray(img).astype(float) / 255.0
    h = h - fis * 0.25
    c = c * (1 - 0.55 * fis[..., None])
    # les coulures sombres, de haut en bas
    coul = valeur(max(4, int(W / 40)), seed + 5, W, H, cy=3) * 0.75 + valeur(max(8, int(W / 14)), seed + 6, W, H, cy=5) * 0.25
    noir = np.clip((coul - 0.58) * 3.0, 0, 1) * (0.5 + 0.5 * yy / H)
    c = c * (1 - 0.22 * noir[..., None])
    # les lichens, la mousse au pied
    lich = np.clip((fbm(int(W / 25), 3, seed + 7, W, H, cy=int(H / 25)) - 0.68) * 5, 0, 1)
    c = c * (1 - 0.35 * lich[..., None]) + np.array([0.7, 0.68, 0.5]) * 0.35 * lich[..., None]
    pied = np.clip((yy / H - (1.0 - mousse_bas)) / mousse_bas, 0, 1) * np.clip(fbm(int(W / 30), 3, seed + 8, W, H, cy=int(H / 30)) * 1.6 - 0.3, 0, 1)
    c = c * (1 - 0.6 * pied[..., None]) + np.array([0.24, 0.32, 0.14]) * 0.6 * pied[..., None]
    return c, h


def _symbole(d, nom, cx, cy, r, w):
    """Les quatre symboles des sceaux, dessinés en creux (blanc = gravé)."""
    if nom == "airain":           # l'engrenage
        dents = 12
        pts = []
        for k in range(dents * 2):
            a = k / (dents * 2) * 6.2832
            rr = r if k % 2 == 0 else r * 0.8
            pts.append((cx + np.cos(a) * rr, cy + np.sin(a) * rr))
        d.polygon(pts, outline=255, width=w)
        d.ellipse([cx - r * 0.35, cy - r * 0.35, cx + r * 0.35, cy + r * 0.35], outline=255, width=w)
    elif nom == "embruns":        # trois vagues
        for k in range(3):
            y = cy - r * 0.5 + k * r * 0.5
            pts = [(cx - r + i * 2 * r / 40, y + np.sin(i / 40 * 6.2832 * 1.5) * r * 0.16) for i in range(41)]
            d.line(pts, fill=255, width=w)
    elif nom == "sables":         # la dune et le soleil
        pts = [(cx - r + i * 2 * r / 40, cy + r * 0.4 - abs(np.sin(i / 40 * 3.1416)) ** 1.5 * r * 0.7) for i in range(41)]
        d.line(pts, fill=255, width=w)
        d.line([(cx - r, cy + r * 0.4), (cx + r, cy + r * 0.4)], fill=255, width=w)
        d.ellipse([cx + r * 0.25, cy - r * 0.85, cx + r * 0.65, cy - r * 0.45], outline=255, width=w)
    elif nom == "brumes":         # la spirale
        pts = []
        for i in range(160):
            t = i / 159
            a = t * 6.2832 * 2.4
            rr = r * (0.1 + 0.9 * t)
            pts.append((cx + np.cos(a) * rr, cy + np.sin(a) * rr))
        d.line(pts, fill=255, width=w)
    elif nom == "coeur":          # le Cœur-de-Pierre : un soleil à huit rayons
        d.ellipse([cx - r * 0.45, cy - r * 0.45, cx + r * 0.45, cy + r * 0.45], outline=255, width=w)
        for k in range(8):
            a = k / 8 * 6.2832
            d.line([(cx + np.cos(a) * r * 0.6, cy + np.sin(a) * r * 0.6), (cx + np.cos(a) * r, cy + np.sin(a) * r)], fill=255, width=w)


def _runes(d, cx, cy, r0, r1, n, seed, w):
    rng = np.random.default_rng(seed)
    for k in range(n):
        a = k / n * 6.2832
        ca, sa = np.cos(a), np.sin(a)
        # une rune : trois ou quatre traits dans la case (radiale, tangente)
        for t in range(rng.integers(2, 5)):
            p0 = (rng.random(), rng.random())
            p1 = (rng.random(), rng.random())
            pts = []
            for (u, v) in (p0, p1):
                rr = r0 + (r1 - r0) * (0.15 + 0.7 * v)
                da = (u - 0.5) * (6.2832 / n) * 0.7
                pts.append((cx + np.cos(a + da) * rr, cy + np.sin(a + da) * rr))
            d.line(pts, fill=255, width=w)


def porte_sceaux():
    S = 110.0                       # pixels par mètre
    W, H = int(14.5 * S), int(18.4 * S)
    rel = Image.new("L", (W, H), 128)
    d = ImageDraw.Draw(rel)
    # le cadre en relief de chaque vantail, le bandeau du battement
    for x0, x1 in ((0, W // 2 - 6), (W // 2 + 6, W)):
        d.rectangle([x0, 0, x1 - 1, H - 1], outline=200, width=int(0.35 * S))
        d.rectangle([x0 + int(0.45 * S), int(0.45 * S), x1 - 1 - int(0.45 * S), H - 1 - int(0.45 * S)], outline=90, width=6)
    cx, cy = W / 2, (17.4 - 9.2) * S
    R = lambda m: m * S
    # la grande rainure du cercle, le bourrelet de part et d'autre, la bande des runes
    d.ellipse([cx - R(6.75), cy - R(6.75), cx + R(6.75), cy + R(6.75)], outline=185, width=int(0.14 * S))
    d.ellipse([cx - R(5.85), cy - R(5.85), cx + R(5.85), cy + R(5.85)], outline=185, width=int(0.12 * S))
    d.ellipse([cx - R(5.75), cy - R(5.75), cx + R(5.75), cy + R(5.75)], outline=40, width=int(1.0 * S))
    run = Image.new("L", (W, H), 0)
    dr = ImageDraw.Draw(run)
    _runes(dr, cx, cy, R(5.95), R(6.6), 56, 1641, 7)
    d.ellipse([cx - R(4.2), cy - R(4.2), cx + R(4.2), cy + R(4.2)], outline=170, width=int(0.1 * S))
    # les rosaces des quatre creux, les symboles près d'eux, le cœur au milieu
    sym = Image.new("L", (W, H), 0)
    ds = ImageDraw.Draw(sym)
    for k, nom in enumerate(["airain", "embruns", "sables", "brumes"]):
        a = np.pi * 0.5 + k * np.pi * 0.5
        # (le repère de la porte : X le long de la façade ; vu de dehors, -X est à gauche : k=1 à
        # gauche, k=3 à droite ; la texture se lit comme on la voit de dehors)
        sx, sy = cx + np.cos(a) * R(5.2), cy - np.sin(a) * R(5.2)
        for j in range(12):
            b = j / 12 * 6.2832
            d.ellipse([sx + np.cos(b) * R(1.45) - R(0.22), sy + np.sin(b) * R(1.45) - R(0.22), sx + np.cos(b) * R(1.45) + R(0.22), sy + np.sin(b) * R(1.45) + R(0.22)], fill=190)
        ix, iy = cx + (sx - cx) * 0.55, cy + (sy - cy) * 0.55
        _symbole(ds, nom, ix, iy, R(1.05), 9)
    _symbole(ds, "coeur", cx, cy, R(1.1), 10)
    # les panneaux du bas et la bande du haut
    for x0, x1 in ((int(0.6 * S), W // 2 - int(0.5 * S)), (W // 2 + int(0.5 * S), W - int(0.6 * S))):
        for (ya, yb) in ((H - int(2.3 * S), H - int(0.6 * S)), (int(0.6 * S), int(1.35 * S))):
            d.rectangle([x0, ya, x1, yb], outline=175, width=int(0.12 * S))
            d.rectangle([x0 + int(0.2 * S), ya + int(0.2 * S), x1 - int(0.2 * S), yb - int(0.2 * S)], fill=110)
        # des chevrons gravés dans les panneaux du bas
        for k in range(int((x1 - x0) / (0.5 * S))):
            x = x0 + int(0.3 * S) + k * int(0.5 * S)
            dr.line([(x, H - int(1.9 * S)), (x + int(0.22 * S), H - int(1.45 * S)), (x, H - int(1.0 * S))], fill=255, width=6)
    r = flou(np.asarray(rel).astype(float) / 255.0, 2.5)
    g = flou(np.asarray(run).astype(float) / 255.0, 1.2) + flou(np.asarray(sym).astype(float) / 255.0, 1.6)
    h = (r - 0.5) * 1.6 - np.clip(g, 0, 1) * 0.6
    c, h = _pierre(h, W, H, 1642)
    c, h = _vieillir(c, h, W, H, 1643)
    gr = np.clip(g, 0, 1)
    c = c * (1 - 0.25 * gr[..., None])
    rough = 0.86 - 0.08 * np.clip((r - 0.5) * 3, 0, 1)
    sauver("porte_sceaux", c, h, 5.0, rough)


def frise_sceaux():
    S = 96.0
    W, H = int(24 * S), int(4 * S)
    rel = Image.new("L", (W, H), 128)
    d = ImageDraw.Draw(rel)
    sym = Image.new("L", (W, H), 0)
    ds = ImageDraw.Draw(sym)
    # les moulures du haut et du bas
    for y, v in ((int(0.12 * S), 210), (int(0.32 * S), 160), (H - int(0.14 * S), 210), (H - int(0.34 * S), 160)):
        d.line([(0, y), (W, y)], fill=v, width=int(0.12 * S))
    # des denticules sous la moulure du haut
    for x in range(0, W, int(0.3 * S)):
        d.rectangle([x, int(0.42 * S), x + int(0.16 * S), int(0.62 * S)], fill=185)
    # les médaillons : le soleil au milieu, les quatre symboles de part et d'autre
    noms = ["airain", "embruns", "coeur", "sables", "brumes"]
    for k, nom in enumerate(noms):
        cx = W * (0.12 + 0.19 * k)
        cy = H * 0.56
        d.ellipse([cx - 1.2 * S, cy - 1.2 * S, cx + 1.2 * S, cy + 1.2 * S], outline=200, width=int(0.14 * S))
        d.ellipse([cx - 1.0 * S, cy - 1.0 * S, cx + 1.0 * S, cy + 1.0 * S], fill=105)
        _symbole(ds, nom, cx, cy, 0.75 * S, 8)
        # des runes entre les médaillons
        if k < len(noms) - 1:
            rng = np.random.default_rng(1650 + k)
            x0 = cx + 1.45 * S
            for j in range(5):
                x = x0 + j * 0.38 * S
                for t in range(3):
                    p = [(x + rng.random() * 0.26 * S, cy - 0.55 * S + rng.random() * 1.1 * S) for _ in range(2)]
                    ds.line(p, fill=255, width=6)
    r = flou(np.asarray(rel).astype(float) / 255.0, 2.0)
    g = flou(np.asarray(sym).astype(float) / 255.0, 1.4)
    h = (r - 0.5) * 1.6 - np.clip(g, 0, 1) * 0.6
    c, h = _pierre(h, W, H, 1651)
    c, h = _vieillir(c, h, W, H, 1652, mousse_bas=0.05)
    c = c * (1 - 0.25 * np.clip(g, 0, 1)[..., None])
    sauver("frise_sceaux", c, h, 5.0, 0.86 + 0.0 * r)


# =================================================================== Carène

def pont_leviathan():
    N = 2048
    px_m = N / 8.33
    rng = np.random.default_rng(1661)
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    larg = 0.22 * px_m
    n_b = int(round(N / larg))
    larg = N / n_b
    rang = np.floor(yy / larg).astype(int)
    fv = yy / larg - rang
    # les abouts : chaque bordage a ses longueurs (de 4 à 7 m), décalées d'un rang à l'autre
    about = np.zeros((N, N), dtype=bool)
    id_ = np.zeros((N, N))
    for k in range(n_b):
        sel = rang == k
        x = rng.random() * N
        x0 = x
        pos = []
        while x < x0 + N - 1.0 * px_m:
            pos.append(x % N)
            x += rng.uniform(4.0, 7.0) * px_m
        line = np.zeros(N)
        for p in sorted(pos):
            line[int(p) % N] = 1
        acc = np.cumsum(line)
        ids = (acc + k * 13) % 97
        about[sel] = np.broadcast_to(line[None, :] > 0, (N, N))[sel]
        id_[sel] = np.broadcast_to(ids[None, :], (N, N))[sel]
    h1 = (np.sin(id_ * 12.9898 + rang * 78.233) * 43758.5453) % 1.0
    h2 = (np.sin(id_ * 39.346 + rang * 11.135) * 43758.5453) % 1.0
    # le fil du bois (le long des bordages, en x)
    fil = valeur(5, 1662, N, N, cy=n_b * 7) * 0.5 + valeur(11, 1663, N, N, cy=n_b * 19) * 0.5
    nu = fbm(6, 5, 1664, N, N)
    brun = np.array([0.42, 0.33, 0.24])
    gris = np.array([0.6, 0.58, 0.54])
    lave = np.clip((nu - 0.42) * 2.2 + (h1[...] - 0.5) * 0.6, 0, 1)
    c = brun * (1 - lave[..., None]) + gris * lave[..., None]
    c = c * (0.8 + 0.24 * fil + 0.1 * (h2 - 0.5))[..., None]
    # les coutures de brai noir, les abouts
    seam = np.clip(1 - np.minimum(fv, 1 - fv) * larg / 3.5, 0, 1)
    ab = flou(about.astype(float), 1.5) * 3.0
    ab = np.clip(ab, 0, 1)
    brai = np.maximum(seam, ab)
    c = c * (1 - brai[..., None] * 0.9) + np.array([0.04, 0.035, 0.03]) * brai[..., None] * 0.9
    # les chevilles par paires, tous les 1,2 m (sur les baux)
    for bx in np.arange(0, N, 1.2 * px_m):
        for k in range(n_b):
            for dy in (0.3, 0.7):
                cxp = int(bx + (k % 3) * 2) % N
                cyp = int((k + dy) * larg)
                r = 5
                c[max(cyp - r, 0):cyp + r, max(cxp - r, 0):cxp + r] *= 0.78
    # les taches d'eau, le sel blanc
    tache = np.clip((fbm(10, 4, 1665, N, N) - 0.66) * 4, 0, 1)
    c = c * (1 - 0.25 * tache[..., None])
    sel = np.clip((fbm(16, 4, 1666, N, N) - 0.7) * 5, 0, 1)
    c = c * (1 - 0.2 * sel[..., None]) + np.array([0.85, 0.84, 0.8]) * 0.2 * sel[..., None]
    bomb = np.clip(np.minimum(fv, 1 - fv) * larg / 10.0, 0, 1) ** 0.5
    h = bomb * 0.6 + fil * 0.35 - brai * 0.8
    rough = 0.82 - 0.2 * brai + 0.06 * lave
    sauver("pont_leviathan", c, h, 3.0, rough)


def ecorce_buche():
    N = 1024
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    # des crêtes verticales (le long de la bûche : v), des crevasses entre elles
    warp = valeur(6, 1671, N, N, cy=3) * 40
    cr = np.abs(np.sin((xx + warp) / N * np.pi * 22 + valeur(30, 1672, N, N, cy=8) * 3.0))
    cre = np.clip((0.35 - cr) * 4, 0, 1) * np.clip(valeur(22, 1673, N, N, cy=12) * 2 - 0.3, 0, 1)
    plaque = fbm(18, 4, 1674, N, N, cy=8)
    base = np.array([0.34, 0.27, 0.2]) * (0.8 + 0.4 * plaque)[..., None]
    c = base * (1 - 0.7 * cre[..., None])
    lich = np.clip((fbm(30, 3, 1675, N, N) - 0.7) * 5, 0, 1)
    c = c * (1 - 0.4 * lich[..., None]) + np.array([0.55, 0.58, 0.45]) * 0.4 * lich[..., None]
    h = plaque * 0.6 - cre * 1.2
    sauver("ecorce_buche", c, h, 4.0)


def cerne():
    N = 512
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    dx, dy = xx - N / 2, yy - N / 2
    r = np.sqrt(dx * dx + dy * dy) / (N / 2)
    a = np.arctan2(dy, dx)
    wob = valeur(8, 1681, N, N) * 0.05
    rings = np.sin((r + wob) * 70.0) * 0.5 + 0.5
    base = np.array([0.66, 0.52, 0.36]) * (0.85 + 0.15 * rings)[..., None]
    aubier = np.clip((r - 0.82) * 10, 0, 1)
    ecorce = np.clip((r - 0.93) * 20, 0, 1)
    c = base * (1 + 0.12 * aubier[..., None])
    c = c * (1 - ecorce[..., None]) + np.array([0.26, 0.2, 0.15]) * ecorce[..., None]
    # les fentes du séchage, en rayons
    fente = np.zeros((N, N))
    rng = np.random.default_rng(1682)
    for k in range(7):
        a0 = rng.random() * 6.2832
        da = np.abs(((a - a0 + np.pi) % (2 * np.pi)) - np.pi)
        fente = np.maximum(fente, np.clip(1 - da * 120 * (0.3 + r), 0, 1) * (r < rng.uniform(0.5, 0.9)))
    c = c * (1 - 0.7 * fente[..., None])
    # le noir de la suie d'un côté (le feu)
    c *= (0.75 + 0.25 * np.clip(dx / N + 0.6, 0, 1))[..., None]
    h = rings * 0.2 - fente * 1.0 - ecorce * 0.2
    sauver("cerne", c, h, 3.0)


# =================================================================== Tazira

def pise_tazira():
    # le pisé (la texture couvre ~2,5 m) : les banchées de 55 cm, leurs fines couches tassées, les
    # cailloux pris dans la terre, le joint de chaux entre deux banchées, les trous de boulin, la
    # pluie qui a creusé de petites rigoles
    N = 2048
    px_m = N / 2.5
    rng = np.random.default_rng(1691)
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    lift = 0.55 * px_m
    n_l = int(round(N / lift))
    lift = N / n_l
    li = np.floor(yy / lift)
    fl = yy / lift - li
    lam = np.sin(yy / lift * np.pi * 2 * 9 + valeur(6, 1692, N, N, cy=n_l * 3) * 4) * 0.5 + 0.5
    terre = np.array([0.62, 0.48, 0.36])
    var = (np.sin(li * 7.13) * 0.5 + 0.5)
    ocre = np.array([0.68, 0.5, 0.33])
    c = (terre * (1 - var[..., None] * 0.5) + ocre * var[..., None] * 0.5) * (0.82 + 0.2 * var + 0.1 * (lam - 0.5))[..., None]
    nu = fbm(6, 5, 1693, N, N)
    c *= (0.86 + 0.24 * nu)[..., None]
    # les cailloux
    img = Image.new("RGB", (N, N))
    hau = Image.new("L", (N, N))
    d = ImageDraw.Draw(img)
    dh = ImageDraw.Draw(hau)
    m = np.zeros((N, N))
    for k in range(2400):
        x, y = rng.random() * N, rng.random() * N
        r = rng.uniform(2.0, 7.0) * (1.0 + 1.6 * (rng.random() > 0.93))
        g = rng.uniform(0.3, 0.62)
        col = tuple(int(v * 255) for v in (g * 1.1, g * 0.92, g * 0.76))
        for dx in (0, -N, N):
            d.ellipse([x - r + dx, y - r * 0.8, x + r + dx, y + r * 0.8], fill=col)
            dh.ellipse([x - r + dx, y - r * 0.8, x + r + dx, y + r * 0.8], fill=255)
    ca = np.asarray(img).astype(float) / 255.0
    cm = np.asarray(hau).astype(float) / 255.0
    c = c * (1 - 0.7 * cm[..., None]) + ca * 0.7 * cm[..., None]
    # le joint de chaux entre les banchées (pas partout), les trous de boulin
    joint = np.clip(1 - np.minimum(fl, 1 - fl) * lift / 5.0, 0, 1) * (valeur(10, 1694, N, N, cy=n_l) > 0.4)
    c = c * (1 - 0.5 * joint[..., None]) + np.array([0.8, 0.76, 0.68]) * 0.5 * joint[..., None]
    trous = np.zeros((N, N))
    for k in range(n_l):
        if k % 2 == 1:
            continue
        y0 = k * lift
        for x0 in np.arange(rng.uniform(0, 200), N, 0.9 * px_m):
            rr = np.sqrt((xx - x0) ** 2 + (yy - y0) ** 2)
            trous = np.maximum(trous, np.clip(1 - rr / 22.0, 0, 1) ** 0.5)
    c = c * (1 - 0.85 * trous[..., None])
    # les rigoles de la pluie (en haut de chaque banchée), l'érosion qui arrondit les arêtes
    rig = np.clip((valeur(int(N / 14), 1695, N, N, cy=n_l * 2) - 0.6) * 4, 0, 1) * (1 - fl) ** 2
    c = c * (1 - 0.1 * rig[..., None])
    h = lam * 0.15 + cm * 0.7 - rig * 0.5 - trous * 1.5 - joint * 0.2 + nu * 0.3
    sauver("pise_tazira", c, h, 3.0, 0.92 - 0.1 * cm)


def chaux_tazira():
    # le lait de chaux (la texture couvre ~3 m) : plusieurs couches, les traces du pinceau, les
    # nuances (un peu bleu, un peu crème), de fines craquelures
    N = 2048
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    coups = valeur(int(N / 40), 1701, N, N, cy=int(N / 160)) * 0.5 + valeur(int(N / 12), 1702, N, N, cy=int(N / 70)) * 0.5
    couches = fbm(5, 5, 1703, N, N)
    c = np.ones((N, N, 3)) * np.array([0.93, 0.92, 0.89])
    c *= (0.9 + 0.08 * coups + 0.06 * (couches - 0.5))[..., None]
    bleu = np.clip((fbm(4, 4, 1704, N, N) - 0.55) * 2.5, 0, 1)
    c = c * (1 - 0.12 * bleu[..., None]) + np.array([0.82, 0.86, 0.92]) * 0.12 * bleu[..., None]
    rng = np.random.default_rng(1705)
    img = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(img)
    for k in range(260):
        x, y = rng.random() * N, rng.random() * N
        a = rng.random() * 6.28
        for s2 in range(rng.integers(6, 22)):
            a += rng.normal(0, 0.6)
            x2, y2 = x + np.cos(a) * 9, y + np.sin(a) * 9
            d.line([(x, y), (x2, y2)], fill=255, width=1)
            x, y = x2, y2
    cr = np.asarray(img).astype(float) / 255.0
    c = c * (1 - 0.18 * cr[..., None])
    h = coups * 0.4 + couches * 0.3 - cr * 0.4
    sauver("chaux_tazira", c, h, 2.0)


# =================================================================== Ramure : la forêt des brumes

def _feuille(d, dh, x, y, L, larg, a, col, hv):
    # une feuille morte vue d'en haut : un fuseau, sa nervure, un peu recroquevillée
    pts = []
    for i in range(13):
        t = i / 12
        w = np.sin(t * np.pi) ** 0.8 * larg * (0.85 + 0.15 * np.sin(t * 9 + x))
        pts.append((t * L - L / 2, w))
    for i in range(12, -1, -1):
        t = i / 12
        w = np.sin(t * np.pi) ** 0.8 * larg * (0.85 + 0.15 * np.cos(t * 7 + y))
        pts.append((t * L - L / 2, -w))
    ca, sa = np.cos(a), np.sin(a)
    poly = [(x + u * ca - v * sa, y + u * sa + v * ca) for (u, v) in pts]
    d.polygon(poly, fill=col)
    dh.polygon(poly, fill=hv)
    nerv = tuple(int(c * 0.72) for c in col)
    d.line([(x - L / 2 * ca, y - L / 2 * sa), (x + L / 2 * ca, y + L / 2 * sa)], fill=nerv, width=1)


def litiere():
    # la litière (la texture couvre ~3,5 m) : des feuilles mortes de chêne et de hêtre, brunes, ocre,
    # rouille, noircies, entassées ; des brindilles, de la terre noire entre elles
    N = 2048
    rng = np.random.default_rng(1711)
    fond = np.array([0.16, 0.12, 0.09]) * (0.7 + 0.5 * fbm(20, 4, 1712, N, N))[..., None]
    img = Image.fromarray((np.clip(fond, 0, 1) * 255).astype(np.uint8))
    hau = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(img)
    dh = ImageDraw.Draw(hau)
    couleurs = [(0.46, 0.3, 0.16), (0.55, 0.36, 0.17), (0.38, 0.24, 0.13), (0.6, 0.42, 0.2), (0.3, 0.2, 0.12), (0.5, 0.33, 0.2), (0.42, 0.36, 0.22)]
    n = 5200
    for k in range(n):
        x, y = rng.random() * N, rng.random() * N
        L = rng.uniform(38, 75)
        col = np.array(couleurs[rng.integers(0, len(couleurs))]) * rng.uniform(0.75, 1.15)
        col = tuple(int(np.clip(c, 0, 1) * 255) for c in col)
        hv = int(40 + 210 * k / n)
        for dx in (0, -N, N):
            for dy in (0, -N, N):
                if -60 < x + dx < N + 60 and -60 < y + dy < N + 60:
                    _feuille(d, dh, x + dx, y + dy, L, L * rng.uniform(0.28, 0.4), rng.random() * 6.28, col, hv)
    for k in range(700):
        x, y = rng.random() * N, rng.random() * N
        a = rng.random() * 6.28
        L = rng.uniform(30, 120)
        g = int(rng.uniform(40, 90))
        d.line([(x, y), (x + np.cos(a) * L, y + np.sin(a) * L)], fill=(g + 15, g, g - 15), width=int(rng.integers(2, 5)))
        dh.line([(x, y), (x + np.cos(a) * L, y + np.sin(a) * L)], fill=255, width=3)
    c = np.asarray(img).astype(float) / 255.0
    h = np.asarray(hau).astype(float) / 255.0
    # l'humidité : des zones plus sombres
    c *= (0.8 + 0.3 * fbm(6, 4, 1713, N, N))[..., None]
    sauver("litiere", c, h, 3.0)


def mousse_foret():
    # le tapis de mousse (la texture couvre ~6 m) : des coussins de mousse de plusieurs verts, leurs
    # creux sombres, quelques feuilles tombées dessus, de petites frondes de fougère
    N = 2048
    rng = np.random.default_rng(1721)
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    cous = np.zeros((N, N))
    teinte = np.zeros((N, N))
    pts = rng.random((900, 2)) * N
    tt = rng.random(900)
    # des coussins : la distance au centre le plus proche (Voronoï simple, en tuiles)
    dmin = np.full((N, N), 1e9)
    for (px, py), t in zip(pts, tt):
        for dx in (0, -N, N):
            for dy in (0, -N, N):
                x0, y0 = px + dx, py + dy
                if -120 < x0 < N + 120 and -120 < y0 < N + 120:
                    xs = slice(max(0, int(x0 - 110)), min(N, int(x0 + 110)))
                    ys = slice(max(0, int(y0 - 110)), min(N, int(y0 + 110)))
                    dd = np.sqrt((xx[ys, xs] - x0) ** 2 + (yy[ys, xs] - y0) ** 2)
                    m = dd < dmin[ys, xs]
                    dmin[ys, xs] = np.where(m, dd, dmin[ys, xs])
                    teinte[ys, xs] = np.where(m, t, teinte[ys, xs])
    cous = np.clip(1 - dmin / 90.0, 0, 1) ** 0.6
    fin = fbm(220, 3, 1722, N, N)
    v1 = np.array([0.24, 0.36, 0.12])
    v2 = np.array([0.34, 0.42, 0.14])
    v3 = np.array([0.18, 0.28, 0.12])
    c = v1 * (1 - teinte[..., None]) + v2 * teinte[..., None]
    c = c * (1 - (teinte[..., None] > 0.8) * 0.5) + v3 * (teinte[..., None] > 0.8) * 0.5
    c *= (0.5 + 0.5 * cous + 0.45 * (fin - 0.5))[..., None]
    img = Image.fromarray((np.clip(c, 0, 1) * 255).astype(np.uint8))
    hau = Image.fromarray((np.clip(cous * 0.7 + fin * 0.3, 0, 1) * 255).astype(np.uint8), "L")
    d = ImageDraw.Draw(img)
    dh = ImageDraw.Draw(hau)
    for k in range(400):
        x, y = rng.random() * N, rng.random() * N
        L = rng.uniform(22, 40)
        col = tuple(int(c * 255 * rng.uniform(0.8, 1.1)) for c in (0.5, 0.33, 0.17))
        _feuille(d, dh, x, y, L, L * 0.33, rng.random() * 6.28, col, 255)
    # de petites frondes de fougère
    for k in range(160):
        x, y = rng.random() * N, rng.random() * N
        a = rng.random() * 6.28
        L = rng.uniform(60, 120)
        g = (int(60 * 1.0), int(110), int(40))
        for i in range(14):
            t = i / 13
            px, py = x + np.cos(a) * L * t, y + np.sin(a) * L * t
            l2 = (1 - t) * L * 0.28
            for s2 in (-1, 1):
                b = a + s2 * 1.1
                d.line([(px, py), (px + np.cos(b) * l2, py + np.sin(b) * l2)], fill=g, width=3)
                dh.line([(px, py), (px + np.cos(b) * l2, py + np.sin(b) * l2)], fill=255, width=3)
        d.line([(x, y), (x + np.cos(a) * L, y + np.sin(a) * L)], fill=(50, 90, 30), width=2)
    c = np.asarray(img).astype(float) / 255.0
    h = np.asarray(hau).astype(float) / 255.0
    sauver("mousse_foret", c, h, 3.0)


def main() -> int:
    print("V164 : les textures de la Grande Île")
    porte_sceaux()
    frise_sceaux()
    pont_leviathan()
    ecorce_buche()
    cerne()
    pise_tazira()
    chaux_tazira()
    litiere()
    mousse_foret()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
