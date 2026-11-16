"""V86 — textures des intérieurs (papiers peints, lambris, chaux, parquets, carrelages).

Toutes calculées ici (numpy + Pillow), raccordables sur les bords (on peut les répéter).
V158 : chacune a aussi sa carte de relief (nom_n.png : les joints, les rainures, le grain du
papier, les coups de taloche), et le bois des meubles (bois_meuble, neutre : le jeu le teinte).
Sortie : www/assets/textures/maisons/*.png
    python3 pcvr/tools/maisons_v86/textures.py
"""
import os
import numpy as np
from PIL import Image, ImageFilter

N = 1024
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'www', 'assets', 'textures', 'maisons')


def rng(seed):
    return np.random.default_rng(seed)


def tile_noise(seed, cells, n=N):
    """Bruit de valeur raccordable (cells x cells cases), lissé en cosinus."""
    r = rng(seed)
    g = r.random((cells, cells))
    x = np.linspace(0, cells, n, endpoint=False)
    i0 = np.floor(x).astype(int)
    f = x - i0
    f = (1 - np.cos(f * np.pi)) * 0.5
    i1 = (i0 + 1) % cells
    a = g[i0][:, i0] * (1 - f)[None, :] + g[i0][:, i1] * f[None, :]
    b = g[i1][:, i0] * (1 - f)[None, :] + g[i1][:, i1] * f[None, :]
    return a * (1 - f)[:, None] + b * f[:, None]


def fbm(seed, octaves=(4, 8, 16, 32, 64), n=N):
    out = np.zeros((n, n))
    amp = 1.0
    tot = 0.0
    for k, c in enumerate(octaves):
        out += tile_noise(seed + k * 101, c, n) * amp
        tot += amp
        amp *= 0.55
    return out / tot


def normale(h, force):
    """V158 : la carte de relief d'une hauteur (raccordable), en couleurs (x, y, z)."""
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * force
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5 * force
    l = np.sqrt(dx * dx + dy * dy + 1.0)
    return np.stack([-dx / l * 0.5 + 0.5, dy / l * 0.5 + 0.5, 1.0 / l * 0.5 + 0.5], -1)


def flou(x, k=1):
    out = x.copy()
    for _ in range(k):
        out = (out + np.roll(out, 1, 0) + np.roll(out, -1, 0) + np.roll(out, 1, 1) + np.roll(out, -1, 1)) / 5.0
    return out


def save(name, rgb, h=None, force=4.0):
    """L'image (si elle n'est pas déjà faite, ou FORCE=1) et sa carte de relief (V158)."""
    os.makedirs(OUT, exist_ok=True)
    p = os.path.join(OUT, name + '.png')
    if os.environ.get('FORCE') == '1' or not os.path.exists(p):
        img = Image.fromarray(np.clip(rgb * 255.0, 0, 255).astype(np.uint8), 'RGB')
        img.save(p, optimize=True)
    if h is not None:
        pn = os.path.join(OUT, name + '_n.png')
        if os.environ.get('FORCE') == '1' or not os.path.exists(pn):
            n = np.clip(normale(h, force) * 255.0, 0, 255).astype(np.uint8)
            Image.fromarray(n, 'RGB').save(pn, optimize=True)
    print('  ', name)


def col(c):
    return np.array(c, dtype=float)[None, None, :]


def paper_grain(seed, k=0.06):
    g = fbm(seed, (32, 64, 128, 256))
    return 1.0 + (g - 0.5) * k * 2


def paper_relief(seed):
    """V158 : le relief du papier (ses fibres), le même grain que paper_grain."""
    return fbm(seed, (32, 64, 128, 256))


# ------------------------------------------------------------------ murs

def pp_rayures(name, c1, c2, seed, bands=16):
    x = np.arange(N)
    w = N / bands
    t = (x % w) / w
    m = (t < 0.5).astype(float)
    # liseré fin entre les bandes
    edge = np.minimum(np.abs(t - 0.5), np.minimum(t, 1 - t)) * w
    line = np.clip(1.5 - edge, 0, 1)
    rgb = col(c1) * m[None, :, None] + col(c2) * (1 - m)[None, :, None]
    rgb = rgb * (1 - 0.25 * line[None, :, None]) + col((0.85, 0.75, 0.5)) * 0.25 * line[None, :, None]
    rgb = np.repeat(rgb, N, axis=0)
    rgb *= paper_grain(seed)[:, :, None]
    rgb *= (0.94 + 0.06 * fbm(seed + 7, (2, 4, 8)))[:, :, None]
    # le relief : le papier, et les bandes satinées à peine en relief
    h = paper_relief(seed) * 0.5 + np.repeat(m[None, :], N, axis=0) * 0.25 - np.repeat(line[None, :], N, axis=0) * 0.15
    save(name, rgb, flou(h, 1), 3.0)


def pp_motif(name, fond, motif, seed, grid=8, kind='fleur'):
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    cs = N / grid
    rgb = np.ones((N, N, 3)) * col(fond)
    a = np.zeros((N, N))
    for row in range(grid + 1):
        for cc in range(grid + 1):
            cx = (cc + (0.5 if row % 2 else 0.0)) * cs
            cy = row * cs
            for ox in (-N, 0, N):
                for oy in (-N, 0, N):
                    dx = xx - (cx + ox)
                    dy = yy - (cy + oy)
                    if kind == 'fleur':
                        r = np.hypot(dx, dy)
                        th = np.arctan2(dy, dx)
                        petal = cs * 0.2 * (0.55 + 0.45 * np.cos(5 * th))
                        a = np.maximum(a, np.clip((petal - r) * 0.6, 0, 1))
                        a = np.maximum(a, np.clip((cs * 0.05 - r) * 0.8, 0, 1) * 0.6)
                    else:  # losange / damas simplifié
                        d = np.abs(dx) / (cs * 0.32) + np.abs(dy) / (cs * 0.46)
                        ring = np.clip(1.0 - np.abs(d - 0.8) * 9.0, 0, 1)
                        dot = np.clip((0.18 - d) * 8.0, 0, 1)
                        a = np.maximum(a, np.maximum(ring, dot))
    rgb = rgb * (1 - a[:, :, None]) + col(motif) * a[:, :, None]
    rgb *= paper_grain(seed)[:, :, None]
    rgb *= (0.93 + 0.07 * fbm(seed + 5, (2, 4, 8)))[:, :, None]
    # le relief : le papier ; le motif imprimé en relief (le damas est gaufré)
    h = paper_relief(seed) * 0.45 + flou(a, 2) * (0.9 if kind != 'fleur' else 0.45)
    save(name, rgb, h, 3.5)


def chaux(name, c, seed):
    n = fbm(seed, (3, 6, 12, 24, 48, 96))
    n2 = fbm(seed + 50, (64, 128, 256))
    rgb = col(c) * (0.82 + 0.3 * n)[:, :, None] * (0.96 + 0.08 * n2)[:, :, None]
    # le relief : les coups de taloche (le grain fin) et les ondulations de l'enduit
    h = n2 * 0.7 + n * 0.3
    save(name, rgb, h, 4.0)


def lambris(name, c, seed, boards=8):
    r = rng(seed)
    x = np.arange(N)
    w = N / boards
    idx = (x // w).astype(int)
    tint = 0.88 + 0.2 * r.random(boards)
    t = (x % w) / w
    groove = np.clip(1 - np.minimum(t, 1 - t) * w / 3.0, 0, 1)
    grain = fbm(seed, (2, 4, 8))  # bas
    yy = np.linspace(0, 1, N)
    streak = np.zeros((N, N))
    for k in range(boards):
        f = r.uniform(30, 60)
        ph = r.uniform(0, 6.28)
        cols = slice(int(k * w), int((k + 1) * w))
        xs = np.linspace(0, 1, int(w))[None, :]
        wob = 0.02 * np.sin(yy[:, None] * 6.28 * 2 + ph)
        streak[:, cols] = 0.5 + 0.5 * np.sin((xs + wob) * f + ph)
    v = tint[idx][None, :] * (0.86 + 0.12 * streak + 0.08 * grain)
    v = v * (1 - 0.55 * groove[None, :])
    rgb = col(c) * v[:, :, None]
    # le relief : les rainures entre les lames, le fil du bois
    h = (1 - groove[None, :]) * 1.0 + streak * 0.04 + grain * 0.03
    save(name, rgb, h, 5.0)


# ------------------------------------------------------------------ sols

def wood_plank(r, w, h, base, seed):
    """Une lame de bois (h lignes, w colonnes), le fil le long de x."""
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    f = r.uniform(0.04, 0.09)
    ph = r.uniform(0, 100)
    wob = 6 * np.sin(xx / w * 6.28 * r.uniform(0.5, 1.5) + ph)
    s = 0.5 + 0.5 * np.sin((yy + wob) * f * 6.28 / 4 + ph)
    knot = 0
    if r.random() < 0.3:
        kx, ky = r.uniform(0.2, 0.8) * w, r.uniform(0.3, 0.7) * h
        d = np.hypot((xx - kx) / 2.5, yy - ky)
        knot = np.clip(1 - d / (h * 0.35), 0, 1) ** 2
    tint = r.uniform(0.85, 1.12)
    v = tint * (0.86 + 0.12 * s) * (1 - 0.35 * knot)
    return col(base)[0, 0] * v[:, :, None]


def parquet_chevron(name, base, seed):
    r = rng(seed)
    rgb = np.zeros((N, N, 3))
    L, Wd = 256, 64
    # chevrons : lames à +45 / -45 en alternance (on dessine dans une grille tournée)
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    u = (xx + yy) / np.sqrt(2)
    v = (yy - xx) / np.sqrt(2)
    period = L / np.sqrt(2) * 2
    col_i = np.floor(xx / (L / np.sqrt(2))).astype(int)
    side = col_i % 2
    lu = np.where(side == 0, u, v)
    lv = np.where(side == 0, v, u)
    pl = np.floor(lv / Wd).astype(int)
    off = (pl % 4) * (L / 4)
    pu = np.floor((lu + off) / L).astype(int)
    key = (pl * 7919 + pu * 104729 + side * 13) % 997
    tints = 0.84 + 0.28 * rng(seed).random(997)
    t = tints[key]
    gu = ((lu + off) % L) / L
    gv = (lv % Wd) / Wd
    grain = 0.5 + 0.5 * np.sin(gv * 6.28 * 3 + gu * 2 + key * 0.7)
    fine = fbm(seed + 3, (64, 128, 256))
    joint = np.clip(1 - np.minimum(np.minimum(gu, 1 - gu) * L, np.minimum(gv, 1 - gv) * Wd) / 1.6, 0, 1)
    edge_x = np.clip(1 - np.minimum(xx % (L / np.sqrt(2)), (L / np.sqrt(2)) - xx % (L / np.sqrt(2))) / 1.6, 0, 1)
    val = t * (0.84 + 0.1 * grain + 0.1 * fine) * (1 - 0.5 * np.maximum(joint, edge_x))
    rgb = col(base) * val[:, :, None]
    # le relief : les joints entre les lames (un peu creux), le fil, les lames pas tout à fait à plat
    h = (1 - np.maximum(joint, edge_x)) * 0.8 + grain * 0.04 + fine * 0.04 + t * 0.12
    save(name, rgb, h, 4.0)


def damier(name, c1, c2, seed, n=8):
    yy, xx = np.mgrid[0:N, 0:N]
    s = N // n
    chk = ((xx // s + yy // s) % 2).astype(float)
    gx = np.minimum(xx % s, s - xx % s)
    gy = np.minimum(yy % s, s - yy % s)
    grout = np.clip(1 - np.minimum(gx, gy) / 3.0, 0, 1)
    wear = fbm(seed, (4, 8, 16, 32))
    rgb = col(c1) * chk[:, :, None] + col(c2) * (1 - chk)[:, :, None]
    rgb *= (0.9 + 0.14 * wear)[:, :, None]
    rgb = rgb * (1 - grout[:, :, None]) + col((0.55, 0.53, 0.5)) * grout[:, :, None]
    # le relief : les joints creux, les carreaux à peine bombés et usés
    h = (1 - grout) * 1.0 + wear * 0.05
    save(name, rgb, flou(h, 1), 4.0)


def tomettes(name, base, seed, cells=8):
    """Tomettes hexagonales de terre cuite (cellules de Voronoï d'une grille en quinconce)."""
    r = rng(seed)
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    hx = N / cells
    rows = 2 * round(N / (hx * np.sqrt(3) / 2) / 2)
    hy = N / rows
    d1 = np.full((N, N), 1e9)
    d2 = np.full((N, N), 1e9)
    idx = np.zeros((N, N), dtype=int)
    for row in range(-1, rows + 1):
        for c in range(-1, cells + 2):
            cx = c * hx + (hx / 2 if row % 2 else 0)
            cy = row * hy
            d = np.hypot(xx - cx, yy - cy)
            closer = d < d1
            d2 = np.where(closer, d1, np.minimum(d2, d))
            d1 = np.where(closer, d, d1)
            idx = np.where(closer, ((row % rows) * 31 + (c % cells) * 17) % 251, idx)
    tints = 0.8 + 0.3 * r.random(251)
    t = tints[idx]
    edge = np.clip(1 - (d2 - d1) / 4.0, 0, 1)
    wear = fbm(seed + 9, (8, 16, 32, 64))
    rgb = col(base) * (t * (0.88 + 0.16 * wear))[:, :, None]
    rgb = rgb * (1 - edge[:, :, None]) + col((0.62, 0.58, 0.52)) * edge[:, :, None]
    # le relief : les joints, les bords des tomettes arrondis, la terre cuite piquée
    bord = np.clip((d2 - d1) / 10.0, 0, 1)
    h = np.sqrt(bord) * 0.9 + wear * 0.08 + flou(rng(seed + 5).random((N, N)), 1) * 0.06
    save(name, rgb, h, 4.0)


def carreaux_ciment(name, fond, c1, c2, seed, n=4):
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    s = N / n
    u = (xx % s) / s - 0.5
    v = (yy % s) / s - 0.5
    r = np.hypot(u, v)
    th = np.arctan2(v, u)
    petal = 0.32 * (0.5 + 0.5 * np.abs(np.cos(2 * th)))
    a1 = np.clip((petal - r) * 40, 0, 1)
    a2 = np.clip((0.07 - r) * 60, 0, 1)
    corner = np.clip((0.2 - np.hypot(np.abs(u) - 0.5, np.abs(v) - 0.5)) * 40, 0, 1)
    rgb = np.ones((N, N, 3)) * col(fond)
    rgb = rgb * (1 - a1[:, :, None]) + col(c1) * a1[:, :, None]
    rgb = rgb * (1 - corner[:, :, None]) + col(c2) * corner[:, :, None]
    rgb = rgb * (1 - a2[:, :, None]) + col(c2) * a2[:, :, None]
    g = np.minimum(np.minimum(u + 0.5, 0.5 - u), np.minimum(v + 0.5, 0.5 - v)) * s
    grout = np.clip(1 - g / 2.0, 0, 1)
    wear = fbm(seed, (4, 8, 16, 32))
    rgb *= (0.88 + 0.16 * wear)[:, :, None]
    rgb = rgb * (1 - grout[:, :, None]) + col((0.7, 0.68, 0.64)) * grout[:, :, None]
    # le relief : les joints, la surface du ciment (lisse, un peu usée)
    h = (1 - grout) * 1.0 + wear * 0.04
    save(name, rgb, flou(h, 1), 4.0)


# ------------------------------------------------------------------ V158 : les meubles

def bois_meuble(name, seed, fonce=(0.22, 0.14, 0.07), clair=(0.53, 0.36, 0.22)):
    """Le bois des meubles (le fil le long de y, des cernes, des fibres, des pores, des
    maillures), dans la teinte moyenne de l'ancien bois uni : le jeu le teinte comme avant."""
    yy, xx = np.mgrid[0:N, 0:N] / N
    deform = (fbm(seed, (3, 6, 12)) - 0.5) * 0.035 + (fbm(seed + 5, (12, 24)) - 0.5) * 0.006
    cernes = (xx + deform) * 22.0
    fil = np.abs(np.sin(cernes * np.pi)) ** 0.6
    r = rng(seed + 3)
    c = r.random((1, N))
    for _ in range(2):
        c = (c + np.roll(c, 1, 1) + np.roll(c, -1, 1)) / 3.0
    fibres = np.repeat(c, N, 0) + (fbm(seed + 7, (2, 4, 8)) - 0.5) * 0.3
    pores = (rng(seed + 2).random((N, N)) > 0.985) * (fil < 0.5)
    maille = np.clip((fbm(seed + 4, (10, 20, 40)) - 0.68) * 6, 0, 1) * 0.12
    v = np.clip(0.3 + 0.32 * fil + 0.22 * fibres - 0.12 * pores + maille, 0, 1)
    rgb = col(fonce) * (1 - v[:, :, None]) + col(clair) * v[:, :, None]
    h = 0.5 + 0.25 * fil + 0.15 * fibres - 0.2 * pores
    save(name, rgb, h, 2.5)


def tissu(name, seed, k=256):
    """Un tissage clair et neutre (le jeu le teinte : literie, rideaux, coussins, nappes)."""
    yy, xx = np.mgrid[0:N, 0:N] / N
    chaine = np.sin(xx * np.pi * 2 * k) * 0.5 + 0.5
    trame = np.sin(yy * np.pi * 2 * k) * 0.5 + 0.5
    case = (np.floor(xx * k) + np.floor(yy * k)) % 2
    tiss = np.where(case > 0, chaine, trame)
    fils = fbm(seed, (128, 256))
    chine = fbm(seed + 1, (32, 64, 128))
    v = 0.88 + 0.07 * tiss + 0.05 * (chine - 0.5) + 0.05 * (fils - 0.5)
    rgb = np.repeat(np.clip(v, 0, 1)[:, :, None], 3, 2) * col((1.0, 0.99, 0.97))
    h = tiss * 0.9 + fils * 0.1
    save(name, rgb, h, 5.0)


def _skip_existing():
    """Sans FORCE=1, on ne recalcule pas les textures déjà faites (l'image et son relief)."""
    if os.environ.get('FORCE') == '1':
        return
    g = globals()
    for fn in ('pp_rayures', 'pp_motif', 'chaux', 'lambris', 'parquet_chevron', 'damier', 'tomettes', 'carreaux_ciment', 'bois_meuble', 'tissu'):
        f = g[fn]
        def wrap(name, *a, _f=f, **k):
            if os.path.exists(os.path.join(OUT, name + '.png')) and os.path.exists(os.path.join(OUT, name + '_n.png')):
                return
            _f(name, *a, **k)
        g[fn] = wrap


if __name__ == '__main__':
    _skip_existing()
    print('textures des maisons :')
    pp_rayures('pp_rayures_sauge', (0.86, 0.88, 0.78), (0.74, 0.8, 0.68), 11)
    pp_rayures('pp_rayures_rose', (0.95, 0.86, 0.84), (0.88, 0.74, 0.74), 12, bands=20)
    pp_rayures('pp_rayures_bleu', (0.84, 0.88, 0.94), (0.7, 0.78, 0.88), 13, bands=12)
    pp_motif('pp_fleurs_creme', (0.94, 0.9, 0.8), (0.72, 0.5, 0.42), 21, 8, 'fleur')
    pp_motif('pp_fleurs_vert', (0.62, 0.72, 0.62), (0.93, 0.9, 0.8), 22, 7, 'fleur')
    pp_motif('pp_damas_bordeaux', (0.5, 0.16, 0.18), (0.72, 0.5, 0.3), 23, 6, 'damas')
    pp_motif('pp_damas_bleu', (0.2, 0.26, 0.42), (0.7, 0.65, 0.5), 24, 6, 'damas')
    chaux('chaux_ocre', (0.92, 0.76, 0.52), 31)
    chaux('chaux_terracotta', (0.86, 0.56, 0.42), 32)
    chaux('chaux_bleu', (0.66, 0.78, 0.86), 33)
    chaux('chaux_vert', (0.7, 0.8, 0.66), 34)
    lambris('lambris_miel', (0.72, 0.5, 0.3), 41)
    lambris('lambris_blanc', (0.92, 0.9, 0.86), 42, boards=16)
    lambris('lambris_sombre', (0.42, 0.28, 0.18), 43)
    parquet_chevron('parquet_chevron', (0.7, 0.48, 0.28), 51)
    parquet_chevron('parquet_chevron_clair', (0.86, 0.7, 0.5), 52)
    damier('damier_noir_blanc', (0.92, 0.9, 0.86), (0.12, 0.12, 0.13), 61)
    damier('damier_rouge_creme', (0.92, 0.86, 0.74), (0.62, 0.2, 0.16), 62, n=10)
    tomettes('tomettes', (0.78, 0.4, 0.26), 71)
    carreaux_ciment('carreaux_ciment_bleu', (0.92, 0.9, 0.84), (0.2, 0.42, 0.62), (0.85, 0.62, 0.22), 81)
    carreaux_ciment('carreaux_ciment_vert', (0.9, 0.88, 0.8), (0.26, 0.5, 0.38), (0.72, 0.28, 0.22), 82)
    bois_meuble('bois_meuble', 91)
    tissu('tissu', 92)
