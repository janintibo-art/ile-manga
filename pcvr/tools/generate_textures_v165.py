"""V165 : les textures d'Arcanelle, de la Balafre et de l'Île des Trois Soleils (faites ici ; CC0 1.0).
Dossier www/assets/textures/beau165/.

  planches_pirate  les planches des cabanes de Port-Coutelas (la texture couvre ~2 m) : des planches
                   à clin de 20 cm, grises d'avoir pris le sel et le soleil, le fil du bois, les nœuds,
                   les clous rouillés et leurs coulures, les fentes au bout, et des restes de peinture
                   claire qui s'écaille (la teinte de la cabane la colore).
  paille_tressee   la paille des ruches d'Arcanelle, tressée en boudins (2 m) : les brins dorés tordus
                   dans chaque boudin, le creux sombre entre deux boudins, les liens d'éclisse en biais.
  enduit_soleils   l'enduit de terre et de chaux des maisons des Trois Soleils (2,2 m) : lissé à la
                   taloche, les reprises, les fines craquelures, des trous d'air (clair : la teinte du
                   mur le colore ; le shader enduit_v163 le vieillit et le fait tomber par plaques).
  adobe            les briques crues sous l'enduit (2 m) : des briques de limon et de paille de 40 cm,
                   les arêtes usées, les brins de paille, l'épais joint de boue.
  terre_cuite      la terre cuite des jarres et des fours (2 m) : les cercles du tour, les coups de feu,
                   la suie, les éclats, le sel qui ressort (claire : la teinte de l'argile la colore).
  dallage_soleils  le dallage des places et des chaussées (6,7 m) : des dalles de calcaire en rangs de
                   largeurs différentes, usées au milieu, les coins ébréchés, les joints de terre.
  tezontle         la pierre volcanique rouge d'Aztlán (2 m) : des moellons équarris de tailles
                   différentes, criblés de bulles, du rouge sang au brun et au gris, le mortier de chaux.

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_textures_v165.py
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

RACINE = Path(__file__).resolve().parents[2]
OUT = RACINE / "www" / "assets" / "textures" / "beau165"


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


def planches_pirate():
    N = 1024
    px_m = N / 2.0
    rng = np.random.default_rng(1751)
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    larg = 0.2 * px_m
    n_b = int(round(N / larg))
    larg = N / n_b
    rang = np.floor(yy / larg).astype(int)
    fv = yy / larg - rang
    # les abouts (une planche de 2 à 4 m, décalée d'un rang à l'autre)
    about = np.zeros((N, N))
    ids = np.zeros((N, N))
    for k in range(n_b):
        sel = rang == k
        x = rng.random() * N
        line = np.zeros(N)
        line[int(x) % N] = 1.0
        if rng.random() < 0.5:
            line[int(x + N * 0.5) % N] = 1.0
        about[sel] = np.broadcast_to(line[None, :], (N, N))[sel]
        ids[sel] = np.broadcast_to((np.cumsum(line) + k * 7)[None, :], (N, N))[sel]
    h1 = (np.sin(ids * 12.9898) * 43758.5453) % 1.0
    # le fil du bois : des veines qui ondulent le long de la planche (les cernes usés par le sel), un
    # fin strié par-dessus
    warp = fbm(3, 3, 1752, N, N, cy=n_b * 3)
    veine = 0.5 + 0.5 * np.sin((fv * 9.0 + warp * 7.0 + h1 * 13.0) * np.pi * 2)
    veine = veine ** 3
    strie = valeur(5, 1753, N, N, cy=N // 3)
    fil = 0.55 * (1 - veine) + 0.45 * strie
    nu = fbm(5, 4, 1754, N, N)
    gris = np.array([0.68, 0.66, 0.62])
    brun = np.array([0.52, 0.43, 0.34])
    c = gris * (1 - 0.45 * h1[..., None]) + brun * 0.45 * h1[..., None]
    c = c * (0.7 + 0.32 * fil + 0.12 * (nu - 0.5))[..., None]
    # la peinture claire qui reste par écailles, surtout sur certaines planches (la teinte de la cabane
    # la colore) ; elle part le long du fil
    h2b = (np.sin(ids * 78.233) * 12345.678) % 1.0
    pp = fbm(24, 4, 1755, N, N) + 0.25 * (strie - 0.5) + 0.35 * (h2b - 0.5)
    peint = np.clip((pp - 0.62) * 14, 0, 1)
    bord = np.clip((pp - 0.59) * 14, 0, 1) - peint
    c = c * (1 - 0.35 * np.clip(bord, 0, 1)[..., None])
    c = c * (1 - peint[..., None]) + np.array([0.88, 0.87, 0.84]) * (0.9 + 0.1 * strie)[..., None] * peint[..., None]
    # le clin : l'ombre sous chaque planche, le bord du dessus éclairé
    ombre = np.clip(1 - fv / 0.12, 0, 1) ** 1.5
    clair = np.clip((fv - 0.88) / 0.12, 0, 1)
    c = c * (1 - 0.5 * ombre[..., None]) * (1 + 0.1 * clair[..., None])
    ab = np.clip(flou(about, 1.2) * 4, 0, 1)
    c = c * (1 - 0.7 * ab[..., None])
    # les nœuds, les clous rouillés (par paires, tous les 60 cm) et leurs coulures
    for k in range(n_b):
        for xc in np.arange(rng.uniform(0, 80), N, 0.6 * px_m):
            for dy in (0.32, 0.7):
                cx, cy = int(xc) % N, int((k + dy) * larg) % N
                r = np.sqrt((xx[max(cy - 30, 0):cy + 30, max(cx - 8, 0):cx + 8] - cx) ** 2 + (yy[max(cy - 30, 0):cy + 30, max(cx - 8, 0):cx + 8] - cy) ** 2)
                tete = np.clip(1 - r / 3.5, 0, 1)
                c[max(cy - 30, 0):cy + 30, max(cx - 8, 0):cx + 8] = c[max(cy - 30, 0):cy + 30, max(cx - 8, 0):cx + 8] * (1 - tete[..., None]) + np.array([0.28, 0.16, 0.1]) * tete[..., None]
                ys = slice(cy, min(cy + 30, N))
                xs = slice(max(cx - 2, 0), cx + 2)
                fade = np.linspace(0.35, 0.0, ys.stop - ys.start)[:, None, None]
                c[ys, xs] = c[ys, xs] * (1 - fade) + np.array([0.45, 0.24, 0.12]) * fade
    for k in range(int(n_b * 1.5)):
        x0, y0 = rng.random() * N, (rng.integers(0, n_b) + rng.uniform(0.3, 0.7)) * larg
        r = np.sqrt(((xx - x0 + N / 2) % N - N / 2) ** 2 + (((yy - y0) * 1.8)) ** 2)
        nd = np.clip(1 - r / rng.uniform(6, 12), 0, 1)
        c = c * (1 - 0.55 * nd[..., None]) + np.array([0.3, 0.22, 0.15]) * 0.55 * nd[..., None]
    h = fv * 0.5 + fil * 0.35 - ab * 0.5 + peint * 0.12
    rough = 0.9 - 0.12 * peint
    sauver("planches_pirate", c, h, 3.0, rough)


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


def enduit_soleils():
    N = 1024
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    grand = fbm(3, 3, 1801, N, N)
    moyen = fbm(12, 3, 1802, N, N)
    # les passes de taloche : des arcs larges, chacun dans son sens
    reg = valeur(4, 1803, N, N)
    ang = reg * np.pi * 2
    u = (xx * np.cos(ang) + yy * np.sin(ang)) / N
    v = (-xx * np.sin(ang) + yy * np.cos(ang)) / N
    arc = vn(u * 6 + np.sin(v * 9) * 0.6, v * 60, 64, 1804)
    taloche = flou(arc, 1.5)
    # les reprises : des bords nets d'une passe à l'autre
    rep = np.clip((fbm(6, 3, 1805, N, N) - 0.5) * 30, -1, 1)
    # les craquelures fines, en réseau, par endroits
    cr = fbm(40, 3, 1806, N, N)
    craq = np.exp(-((cr - 0.5) * 70) ** 2) * np.clip((fbm(5, 2, 1807, N, N) - 0.6) * 5, 0, 1)
    # les trous d'air
    trou = np.clip((vn(xx / 3.5, yy / 3.5, int(N / 3.5) + 1, 1808) - 0.93) * 14, 0, 1)
    c = np.ones((N, N, 3)) * np.array([0.93, 0.91, 0.87])
    c *= (0.92 + 0.12 * grand + 0.06 * (moyen - 0.5) + 0.03 * (taloche - 0.5))[..., None]
    c *= (1 + 0.025 * rep)[..., None]
    c *= (1 - 0.12 * craq - 0.35 * trou)[..., None]
    c *= np.array([1.0, 0.995, 0.98]) + (grand - 0.5)[..., None] * np.array([0.02, 0.0, -0.03])
    h = taloche * 0.35 + grand * 0.2 + rep * 0.05 - craq * 0.4 - trou * 0.8
    rough = 0.88 - 0.08 * taloche
    sauver("enduit_soleils", c, h, 2.0, rough)


def adobe():
    N = 1024
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    sid, dx, dy, fy, fx = appareil(N, (58, 72), (175, 240), 1811)
    hb = h01(sid.astype(float))
    hb2 = h01(sid * 3.7 + 1.0)
    # l'arête usée : la brique s'arrondit vers le joint, irrégulière, rongée par la pluie
    bord = np.minimum(dx, dy) - 7 + (fbm(26, 3, 1812, N, N) - 0.5) * 16
    plein = np.clip(bord / 14.0, 0, 1)
    joint = 1 - np.clip(bord / 3 + 1, 0, 1)
    nu = fbm(24, 4, 1813, N, N)
    gros = fbm(5, 3, 1817, N, N)
    brique = np.array([0.64, 0.53, 0.4]) * (0.9 + 0.14 * hb)[..., None] + np.array([-0.03, 0.0, 0.03]) * (hb2 - 0.5)[..., None]
    brique = brique * (0.84 + 0.22 * nu + 0.1 * (gros - 0.5))[..., None]
    # la paille : de courts brins, surtout couchés
    paille = np.zeros((N, N))
    rng = np.random.default_rng(1814)
    for i in range(900):
        x0, y0 = rng.random() * N, rng.random() * N
        a = rng.normal(0, 0.5)
        L = rng.uniform(5, 15)
        t = np.linspace(0, L, int(L * 1.5))
        px = (x0 + np.cos(a) * t).astype(int) % N
        py = (y0 + np.sin(a) * t).astype(int) % N
        paille[py, px] = 1.0 if rng.random() < 0.5 else -1.0
    paille = flou(paille, 0.6)
    clair = np.clip(paille * 2, 0, 1) * plein
    sombre = np.clip(-paille * 2, 0, 1) * plein
    brique = brique * (1 - 0.25 * sombre[..., None])
    brique = brique * (1 - 0.4 * clair[..., None]) + np.array([0.8, 0.7, 0.48]) * 0.4 * clair[..., None]
    mortier = np.array([0.6, 0.5, 0.39]) * (0.82 + 0.28 * fbm(50, 2, 1815, N, N))[..., None]
    c = brique * plein[..., None] + mortier * (1 - plein[..., None])
    c *= (1 - 0.18 * joint)[..., None]
    trou = np.clip((vn(xx / 4, yy / 4, 256, 1816) - 0.9) * 10, 0, 1) * plein
    c *= (1 - 0.3 * trou)[..., None]
    h = plein * 0.9 + nu * 0.3 - trou * 0.4
    rough = np.full((N, N), 0.95)
    sauver("adobe", c, h, 4.0, rough)


def terre_cuite():
    N = 1024
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    # les cercles du tour : de fines côtes horizontales qui ondulent un peu
    on = vn(xx / N * 8, yy / N * 2, 8, 1821) * 6
    tour = 0.5 + 0.5 * np.sin((yy + on) / N * np.pi * 2 * 70)
    tour = tour * (0.5 + 0.5 * valeur(6, 1822, N, N))
    # les coups de feu : de grandes taches plus sombres, puis plus claires (l'engobe)
    feu = fbm(4, 4, 1823, N, N)
    engobe = fbm(9, 3, 1824, N, N)
    suie = np.clip((fbm(5, 4, 1825, N, N) - 0.64) * 3, 0, 1)
    sel = np.clip((fbm(30, 3, 1826, N, N) - 0.78) * 5, 0, 1)
    eclat = np.clip((vn(xx / 9, yy / 9, 114, 1827) - 0.94) * 16, 0, 1)
    c = np.ones((N, N, 3)) * np.array([0.92, 0.9, 0.86])
    c *= (0.82 + 0.25 * feu + 0.04 * tour)[..., None]
    c = c * (1 + 0.08 * np.clip((engobe - 0.55) * 4, 0, 1))[..., None]
    c = c * (1 - 0.4 * suie[..., None])
    c = c * (1 - sel[..., None] * 0.35) + np.array([1.0, 0.98, 0.94]) * sel[..., None] * 0.35
    c = c * (1 - 0.15 * eclat[..., None]) + np.array([1.0, 0.86, 0.72]) * 0.15 * eclat[..., None]
    h = tour * 0.25 + feu * 0.1 - eclat * 0.6
    rough = 0.82 - 0.1 * np.clip((engobe - 0.55) * 4, 0, 1) + 0.1 * sel
    sauver("terre_cuite", c, h, 2.0, rough)


def dallage_soleils():
    N = 1024
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    sid, dx, dy, fy, fx = appareil(N, (78, 140), (90, 215), 1831)
    hb = h01(sid.astype(float))
    hb2 = h01(sid * 2.3 + 5.0)
    hb3 = h01(sid * 7.1 + 2.0)
    bruit = (fbm(20, 3, 1832, N, N) - 0.5) * 3.0
    bord = np.minimum(dx, dy) - 1.6 + bruit
    # les coins ébréchés
    coin = np.clip(1 - np.sqrt(np.maximum(dx, 0) ** 2 + np.maximum(dy, 0) ** 2) / (4 + 8 * hb3), 0, 1)
    plein = np.clip(bord / 2.5, 0, 1) * (1 - np.clip((coin - 0.4) * 6, 0, 1) * (hb3 > 0.5))
    nu = fbm(16, 4, 1833, N, N)
    fin = fbm(64, 2, 1834, N, N)
    pierre = np.array([0.84, 0.78, 0.66]) * (0.8 + 0.3 * hb)[..., None]
    pierre = pierre + np.array([0.03, 0.0, -0.04]) * (hb2 - 0.5)[..., None]
    pierre = pierre * (0.88 + 0.16 * nu + 0.06 * (fin - 0.5))[..., None]
    # l'usure : le milieu poli et plus clair, les bords plus sombres
    usure = np.clip(np.minimum(dx, dy) / 30.0, 0, 1)
    pierre = pierre * (0.93 + 0.1 * usure)[..., None]
    # des lichens, des fissures dans quelques dalles
    lich = np.clip((fbm(10, 3, 1835, N, N) - 0.68) * 5, 0, 1) * (1 - usure * 0.7)
    pierre = pierre * (1 - 0.25 * lich[..., None]) + np.array([0.55, 0.56, 0.45]) * 0.25 * lich[..., None]
    fis_n = vn(xx / 37.0 + (fbm(8, 2, 1836, N, N) - 0.5) * 3, yy / 37.0, int(N / 37) + 1, 1837)
    fissure = np.clip((vn(xx / 3.0, yy / 3.0, 342, 1838) - 0.9) * 8, 0, 1) * (0.3 + 0.7 * hb2) * plein
    pierre = pierre * (1 - 0.3 * fissure[..., None])
    joint = np.array([0.36, 0.32, 0.26]) * (0.8 + 0.3 * nu)[..., None]
    c = pierre * plein[..., None] + joint * (1 - plein[..., None])
    # chaque dalle un peu bombée, un peu de travers
    bomb = np.clip(np.minimum(dx, dy) / 40, 0, 1) * 0.3 + (hb - 0.5) * 0.15
    h = plein * (0.8 + bomb) + nu * 0.15 - fissure * 0.3
    rough = 0.9 - 0.12 * usure * plein
    sauver("dallage_soleils", c, h, 5.0, rough)


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


def tezontle():
    N = 1024
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    f1, f2, sid = voronoi(N, 6, 8, 1841)
    hb = h01(sid.astype(float))
    hb2 = h01(sid * 4.3 + 1.0)
    bruit = (fbm(24, 3, 1842, N, N) - 0.5) * 7
    bord = (f2 - f1) * 0.5 - 3.5 + bruit * 0.6
    plein = np.clip(bord / 5.0, 0, 1)
    # du rouge sang au brun, quelques pierres gris-noir
    rouge = np.array([0.56, 0.22, 0.16])
    brun = np.array([0.38, 0.2, 0.16])
    noir = np.array([0.27, 0.23, 0.22])
    col = rouge * (1 - hb)[..., None] + brun * hb[..., None]
    col = np.where((hb2 > 0.9)[..., None], noir * (0.9 + 0.2 * hb[..., None]), col)
    nu = fbm(18, 4, 1843, N, N)
    col = col * (0.8 + 0.34 * nu)[..., None]
    # les bulles : beaucoup de trous sombres, de deux tailles
    b1 = np.clip((vn(xx / 3.0, yy / 3.0, 342, 1844) - 0.78) * 7, 0, 1)
    b2 = np.clip((vn(xx / 8.0, yy / 8.0, 128, 1845) - 0.84) * 8, 0, 1)
    bulle = np.clip(b1 + b2, 0, 1) * plein
    col = col * (1 - 0.65 * bulle[..., None])
    mortier = np.array([0.62, 0.59, 0.54]) * (0.75 + 0.3 * fbm(60, 2, 1846, N, N))[..., None]
    c = col * plein[..., None] + mortier * (1 - plein[..., None])
    bomb = np.clip((f2 - f1) * 0.5 / 30, 0, 1) * 0.5
    h = plein * (0.6 + bomb) + nu * 0.3 - bulle * 0.5
    rough = 0.95 - 0.03 * plein
    sauver("tezontle", c, h, 4.0, rough)


def paille_tressee():
    N = 1024
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    bande = 20.48
    ph = (yy / bande) % 1.0
    # les brins : des stries couchées, tordues dans chaque boudin
    tors = np.sin(ph * np.pi * 2) * 0.9
    fib = vn(xx / 16.0 + tors, yy / 1.6, 64, 1861) * 0.6 + vn(xx / 8.0 - tors, yy / 1.0, 128, 1862) * 0.4
    creux = np.cos(ph * np.pi * 2) * 0.5 + 0.5
    nu = fbm(6, 3, 1863, N, N)
    c = np.array([0.8, 0.64, 0.36]) * (0.62 + 0.55 * fib)[..., None]
    c = c * (0.55 + 0.45 * (1 - creux ** 3))[..., None] * (0.9 + 0.2 * nu)[..., None]
    c = c + np.array([0.04, 0.02, -0.03]) * (nu - 0.5)[..., None]
    # les liens d'éclisse : en biais sur chaque boudin, plus sombres et plus lisses
    lien = (((xx + yy * 0.78125 + np.floor(yy / bande) * 23.0) % 80.0) < 7.0) & (ph > 0.12) & (ph < 0.88)
    lien = flou(lien.astype(float), 0.8)
    c = c * (1 - 0.5 * lien[..., None]) + np.array([0.52, 0.38, 0.22]) * 0.5 * lien[..., None]
    h = (1 - creux ** 3) * 0.8 + fib * 0.3 + lien * 0.25
    sauver("paille_tressee", c, h, 3.0)


def main() -> int:
    print("V165 : les textures d'Arcanelle, de la Balafre et des Trois Soleils")
    import sys
    for f in (planches_pirate, paille_tressee, enduit_soleils, adobe, terre_cuite, dallage_soleils, tezontle):
        if len(sys.argv) < 2 or f.__name__ in sys.argv[1:]:
            f()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
