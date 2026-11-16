"""V161 : les textures de la Citadelle des Nuées (l'île flottante) et de l'Île des Géants (faites ici ;
CC0 1.0). Dossier www/assets/textures/beau161/.

  page_livre     le grand livre ouvert de la bibliothèque : le parchemin (taches, bords plus sombres,
                 piqûres), une écriture inventée (aucune langue : le jeu parle trois langues), une
                 lettrine bleue et or à l'aigle des Rois-Ciel, et sur la page de droite le Chant des
                 Quatre Cloches en images : la Vague, le Soleil, la Lune, le Vent (l'ordre du beffroi)
  vitrail        les vitraux de la grande salle : des losanges de verre teinté sertis de plomb, peints
                 en grisaille, une bordure de verres rouges et bleus à perles jaunes, le médaillon bleu
                 à l'aigle d'or ; le verre a ses nuances, ses bulles et ses stries (la forme de la
                 fenêtre est celle de l'ancien vitrail ; l'aigle est redessiné)

L'Île des Géants (à l'échelle des géants : une texture couvre plusieurs mètres) :
  bois_peint     le bois peint en blanc (les clôtures, les encadrements) : le fil du bois sous la
                 peinture, la peinture qui s'écaille par plaques et laisse voir le bois gris
  zinc_galva     le zinc galvanisé (l'arrosoir, le seau, la gouttière) : les cristaux de la
                 galvanisation (des « fleurs » plus claires ou plus sombres), des rayures, un peu de
                 rouille blanche
  caoutchouc     le caoutchouc des bottes et du pneu : un grain fin, des plis, des éclaboussures
  terre_cuite    la terre cuite des jardinières : le grain, les nuances, le salpêtre blanc qui
                 remonte, des taches d'humidité
  foin_rond      le bout d'une balle de foin ronde : la paille enroulée en spirale
  corde          la corde de chanvre : les torons tordus
  tweed          la veste de l'épouvantail : un tweed à chevrons
  toile_lin      la grosse toile de lin (les ailes du moulin, le sac de l'épouvantail) : la trame

Néopolis :
  conteneur      la tôle ondulée des conteneurs du port (neutre : la matière lui donne sa couleur) :
                 les ondes (8 par motif de 2,4 m), la peinture écaillée, la rouille qui coule, la crasse
                 en bas, des rayures

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_textures_v161.py
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

RACINE = Path(__file__).resolve().parents[2]
OUT = RACINE / "www" / "assets" / "textures" / "beau161"
ANCIEN_VITRAIL = RACINE / "www" / "assets" / "textures" / "chateau" / "vitrail.png"


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


def flou(x, k=1):
    out = x.copy()
    for _ in range(k):
        out = (out + np.roll(out, 1, 0) + np.roll(out, -1, 0) + np.roll(out, 1, 1) + np.roll(out, -1, 1)) / 5.0
    return out


def sauver_tex(nom, c, h=None, force=3.0, rough=None):
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


def voronoi(n, cellules, seed):
    """Des cellules (raccordables) : la distance au plus proche, au second, l'indice du plus proche."""
    r = np.random.default_rng(seed)
    pts = r.random((cellules, 2)) * n
    yy, xx = np.mgrid[0:n, 0:n]
    d1 = np.full((n, n), 1e9)
    d2 = np.full((n, n), 1e9)
    idx = np.zeros((n, n), int)
    for i, (px, py) in enumerate(pts):
        dx = np.abs(xx - px)
        dx = np.minimum(dx, n - dx)
        dy = np.abs(yy - py)
        dy = np.minimum(dy, n - dy)
        d = np.sqrt(dx * dx + dy * dy)
        plus = d < d1
        d2 = np.where(plus, d1, np.minimum(d2, d))
        idx = np.where(plus, i, idx)
        d1 = np.where(plus, d, d1)
    return d1, d2, idx


def sauver(nom, img):
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / f"{nom}.png", optimize=True)
    print("  ", nom)


# =================================================================== l'aigle des Rois-Ciel

def aigle_masque(taille):
    """L'aigle héraldique des Rois-Ciel (les ailes déployées, la tête tournée, la queue en éventail),
    dessiné en grand puis réduit : un masque en niveaux de gris."""
    S = 1024
    im = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(im)
    cx, cy = S / 2, S * 0.5
    # les ailes : un éventail de plumes de chaque côté
    for sx in (-1, 1):
        for k in range(7):
            a0 = np.radians(-150 + k * 18) if sx < 0 else np.radians(-30 - k * 18)
            ln = 330 - abs(k - 2) * 26
            base = (cx + sx * 70, cy - 40 + k * 12)
            tip = (base[0] + np.cos(a0) * ln, base[1] + np.sin(a0) * ln)
            perp = np.array([np.cos(a0 + np.pi / 2), np.sin(a0 + np.pi / 2)]) * 34
            d.polygon([base, (tip[0] + perp[0] * 0.4, tip[1] + perp[1] * 0.4), (tip[0] - perp[0] * 0.4 + np.cos(a0) * 30, tip[1] - perp[1] * 0.4 + np.sin(a0) * 30), (base[0] - perp[0], base[1] - perp[1])], fill=255)
        d.ellipse([cx + sx * 40 - 120, cy - 130, cx + sx * 40 + 120, cy + 60], fill=255)
    # le corps, la tête et son bec, la couronne
    d.ellipse([cx - 95, cy - 150, cx + 95, cy + 170], fill=255)
    d.ellipse([cx - 62, cy - 270, cx + 62, cy - 140], fill=255)
    d.polygon([(cx + 40, cy - 230), (cx + 130, cy - 210), (cx + 92, cy - 178), (cx + 40, cy - 182)], fill=255)
    d.ellipse([cx + 4, cy - 236, cx + 26, cy - 214], fill=0)
    for k in range(3):
        x = cx - 40 + k * 40
        d.polygon([(x - 18, cy - 262), (x, cy - 320), (x + 18, cy - 262)], fill=255)
    # la queue en éventail, les pattes et leurs serres
    for k in range(5):
        a = np.radians(60 + k * 15)
        tip = (cx + np.cos(a) * 300, cy + 120 + np.sin(a) * 300 - 150)
        d.polygon([(cx - 30, cy + 140), tip, (tip[0] + 40, tip[1] - 10), (cx + 30, cy + 140)], fill=255)
    for sx in (-1, 1):
        d.line([(cx + sx * 50, cy + 140), (cx + sx * 120, cy + 260)], fill=255, width=34)
        for k in range(3):
            a = np.radians(60 + k * 30) if sx > 0 else np.radians(120 - k * 30)
            p0 = (cx + sx * 120, cy + 260)
            d.line([p0, (p0[0] + np.cos(a) * 60, p0[1] + np.sin(a) * 60)], fill=255, width=14)
    return im.resize((taille, taille), Image.LANCZOS)


# =================================================================== la page du livre

def ecriture(d, x0, y0, x1, y1, rng, encre, interligne=22, corps=9):
    """Des lignes d'une écriture inventée : des mots de petites lettres liées."""
    y = y0
    while y < y1:
        x = x0 + (rng.integers(0, 3) * 6 if y > y0 else 0)
        fin = x1 - rng.integers(0, 40) if rng.random() < 0.15 else x1
        while x < fin - 20:
            n = int(rng.integers(2, 8))
            for _ in range(n):
                g = rng.integers(0, 6)
                h = corps * (1.6 if g == 0 else 1.0)
                if g == 0:
                    d.line([(x, y), (x, y - h)], fill=encre, width=2)
                    d.arc([x, y - corps, x + corps * 0.8, y], 200, 520, fill=encre, width=2)
                elif g == 1:
                    d.arc([x, y - corps, x + corps * 0.9, y], 0, 360, fill=encre, width=2)
                elif g == 2:
                    d.line([(x, y - corps), (x + 2, y), (x + corps * 0.8, y - corps)], fill=encre, width=2)
                elif g == 3:
                    d.line([(x, y), (x, y - corps)], fill=encre, width=2)
                    d.arc([x, y - corps, x + corps * 0.9, y], 180, 360, fill=encre, width=2)
                elif g == 4:
                    d.line([(x, y + corps * 0.5), (x, y - corps)], fill=encre, width=2)
                else:
                    d.arc([x, y - corps, x + corps, y], 30, 330, fill=encre, width=2)
                x += corps * 0.95
            x += corps * 0.9
        y += interligne


def page_livre():
    W, H = 2048, 1024
    rng = np.random.default_rng(1611)
    base = np.array([0.93, 0.87, 0.72])
    t = fbm(6, 5, 1612, W, H)
    taches = np.clip((fbm(14, 3, 1613, W, H) - 0.62) * 4, 0, 1)
    yy, xx = np.mgrid[0:H, 0:W]
    u = (xx % (W // 2)) / (W // 2)
    v = yy / H
    bord = np.clip(1 - np.minimum.reduce([u * 9, (1 - u) * 9, v * 9, (1 - v) * 9]), 0, 1) ** 2
    pli = np.exp(-((xx - W / 2) / 40.0) ** 2)
    c = base[None, None, :] * (0.92 + 0.12 * t)[..., None]
    c *= (1 - 0.18 * taches)[..., None] * (1 - 0.25 * bord)[..., None] * (1 - 0.35 * pli)[..., None]
    c = c * np.array([1.0, 0.98, 0.94])
    # quelques piqûres rousses
    for _ in range(60):
        px, py = rng.integers(0, W), rng.integers(0, H)
        r = rng.uniform(2, 6)
        m = ((xx - px) ** 2 + (yy - py) ** 2) < r * r
        c[m] *= np.array([0.86, 0.76, 0.62])
    img = Image.fromarray((np.clip(c, 0, 1) * 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    encre = (58, 36, 22)
    # la page de gauche : la lettrine (l'aigle d'or sur fond bleu), le titre, le texte
    lx, ly, ls = 150, 140, 190
    d.rectangle([lx - 8, ly - 8, lx + ls + 8, ly + ls + 8], fill=(176, 134, 52))
    d.rectangle([lx, ly, lx + ls, ly + ls], fill=(28, 46, 120))
    for k in range(0, ls, 18):
        d.ellipse([lx + k + 4, ly + 4, lx + k + 10, ly + 10], fill=(200, 170, 80))
    aig = aigle_masque(ls + 10)
    img.paste((222, 178, 70), (lx - 5, ly - 2), aig)
    rng2 = np.random.default_rng(1614)
    ecriture(d, lx + ls + 40, 190, 930, 330, rng2, (130, 30, 22), 46, 16)
    ecriture(d, 150, 380, 930, 920, rng2, encre)
    # des ornements de marge
    for k in range(5):
        y = 420 + k * 110
        d.ellipse([96, y, 112, y + 16], outline=(130, 30, 22), width=2)
    # la page de droite : le Chant des Quatre Cloches en images
    ox = W // 2
    ecriture(d, ox + 120, 160, ox + 900, 290, rng2, encre)
    cy = 470
    pas = 200
    signes = ["vague", "soleil", "lune", "vent"]
    for i, s in enumerate(signes):
        cx = ox + 190 + i * pas
        d.ellipse([cx - 70, cy - 70, cx + 70, cy + 70], outline=(150, 112, 40), width=6)
        d.ellipse([cx - 60, cy - 60, cx + 60, cy + 60], fill=(238, 226, 196))
        if s == "vague":
            for k in range(3):
                yk = cy - 22 + k * 22
                d.arc([cx - 46, yk - 14, cx - 6, yk + 14], 180, 360, fill=(30, 70, 150), width=6)
                d.arc([cx - 6, yk - 14, cx + 34, yk + 14], 0, 180, fill=(30, 70, 150), width=6)
        elif s == "soleil":
            d.ellipse([cx - 24, cy - 24, cx + 24, cy + 24], fill=(214, 150, 30))
            for k in range(12):
                a = 2 * np.pi * k / 12
                d.line([(cx + np.cos(a) * 30, cy + np.sin(a) * 30), (cx + np.cos(a) * 50, cy + np.sin(a) * 50)], fill=(214, 150, 30), width=5)
        elif s == "lune":
            d.ellipse([cx - 38, cy - 38, cx + 38, cy + 38], fill=(120, 130, 170))
            d.ellipse([cx - 22, cy - 46, cx + 50, cy + 30], fill=(238, 226, 196))
        else:
            for k in range(3):
                yk = cy - 26 + k * 26
                d.line([(cx - 44, yk), (cx + 20, yk)], fill=(90, 120, 110), width=5)
                d.arc([cx + 4, yk - 16, cx + 36, yk + 16], 270, 450 if k != 1 else 180, fill=(90, 120, 110), width=5)
        if i < 3:
            ax = cx + 78
            d.line([(ax, cy), (ax + 40, cy)], fill=(130, 30, 22), width=5)
            d.polygon([(ax + 44, cy), (ax + 30, cy - 10), (ax + 30, cy + 10)], fill=(130, 30, 22))
    ecriture(d, ox + 120, 620, ox + 900, 920, rng2, encre)
    img = img.filter(ImageFilter.GaussianBlur(0.6))
    sauver("page_livre", img.convert("RGB"))


# =================================================================== le vitrail

def vitrail():
    ancien = Image.open(ANCIEN_VITRAIL).convert("RGBA")
    W, H = ancien.size
    W2, H2 = W * 2, H * 2
    alpha = np.asarray(ancien.resize((W2, H2), Image.LANCZOS))[..., 3].astype(float) / 255.0
    rng = np.random.default_rng(1615)
    yy, xx = np.mgrid[0:H2, 0:W2]
    c = np.zeros((H2, W2, 3))
    plomb = np.zeros((H2, W2))
    # les losanges (des « quarries ») : verres pâles, chacun sa nuance
    s = 92.0
    a = (xx + yy) / s
    b = (xx - yy) / s
    ia, ib = np.floor(a), np.floor(b)
    fa, fb = a - ia, b - ib
    h = np.abs(np.sin(ia * 12.9898 + ib * 78.233) * 43758.5453) % 1.0
    pales = np.array([[0.7, 0.82, 0.55], [0.58, 0.74, 0.88], [0.92, 0.76, 0.38], [0.56, 0.78, 0.66], [0.84, 0.82, 0.72]])
    c = pales[(h * 5).astype(int) % 5]
    d_bord = np.minimum.reduce([fa, 1 - fa, fb, 1 - fb]) * s
    plomb = np.maximum(plomb, np.clip(1 - (d_bord - 3.0) / 2.0, 0, 1))
    # la grisaille : une petite fleur peinte au milieu de chaque losange
    da, db = fa - 0.5, fb - 0.5
    rr = np.sqrt(da * da + db * db)
    ang = np.arctan2(db, da)
    fleur = np.clip(1 - np.abs(rr - (0.16 + 0.05 * np.cos(ang * 4))) * 40, 0, 1) + np.clip(1 - rr * 14, 0, 1)
    c *= (1 - 0.45 * np.clip(fleur, 0, 1))[..., None]
    # la bordure : des verres rouges et bleus, des perles jaunes
    def eroder(k):
        pad = np.zeros((H2 + 2 * k, W2 + 2 * k))
        pad[k:k + H2, k:k + W2] = alpha
        pad[:k, k:k + W2] = alpha[:1, :]
        e = np.asarray(Image.fromarray((pad * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(2 * k + 1))).astype(float) / 255.0
        return e[k:k + H2, k:k + W2]
    m_in = eroder(30)
    m_in2 = eroder(38)
    bordure = (alpha > 0.5) & (m_in < 0.5)
    seg = ((yy + xx * 0.3) // 70).astype(int)
    rouge = np.array([0.72, 0.1, 0.1])
    bleu = np.array([0.12, 0.2, 0.62])
    c[bordure] = np.where((seg[bordure] % 2 == 0)[:, None], rouge, bleu)
    perle = (m_in > 0.5) & (m_in2 < 0.5)
    c[perle] = np.array([0.95, 0.78, 0.2])
    plomb[bordure | perle] = 0.0
    for mm in (m_in, m_in2):
        e = np.asarray(Image.fromarray((mm * 255).astype(np.uint8)).filter(ImageFilter.FIND_EDGES)).astype(float) / 255.0
        e = np.asarray(Image.fromarray((np.clip(e * 3, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5))).astype(float) / 255.0
        plomb = np.maximum(plomb, e)
    pb = (perle | bordure)
    plomb[pb & ((seg % 1) == 0) & (((yy + xx * 0.3) % 70) < 4)] = 1.0
    # le médaillon : le fond bleu profond, l'aigle d'or, sa couronne de verres
    mcy, mcx, mr = int(H2 * 0.53), W2 // 2, int(W2 * 0.31)
    dist = np.sqrt((yy - mcy) ** 2 + (xx - mcx) ** 2)
    med = dist < mr
    c[med] = np.array([0.1, 0.16, 0.5])
    plomb[dist < mr + 34] = 0.0
    anneau = (dist >= mr) & (dist < mr + 34)
    angm = (np.arctan2(yy - mcy, xx - mcx) / (2 * np.pi) * 24).astype(int)
    c[anneau] = np.where((angm[anneau] % 2 == 0)[:, None], np.array([0.62, 0.08, 0.1]), np.array([0.9, 0.7, 0.18]))
    plomb = np.maximum(plomb, np.clip(1 - np.abs(dist - mr) / 4, 0, 1))
    plomb = np.maximum(plomb, np.clip(1 - np.abs(dist - mr - 34) / 4, 0, 1))
    plomb[anneau & (((np.arctan2(yy - mcy, xx - mcx) / (2 * np.pi) * 24) % 1) < 0.05)] = 1.0
    aig = np.asarray(aigle_masque(int(mr * 2.3))).astype(float) / 255.0
    ah = aig.shape[0]
    y0, x0 = mcy - ah // 2, mcx - ah // 2
    zone = (slice(y0, y0 + ah), slice(x0, x0 + ah))
    ah2 = np.mgrid[0:ah, 0:ah]
    aig = aig * ((((ah2[0] - ah / 2) ** 2 + (ah2[1] - ah / 2) ** 2) < (mr * 0.94) ** 2))
    am = aig > 0.5
    sub = c[zone]
    sub[am] = np.array([0.96, 0.74, 0.22])
    c[zone] = sub
    e2 = np.asarray(Image.fromarray((aig * 255).astype(np.uint8)).filter(ImageFilter.FIND_EDGES)).astype(float) / 255.0
    e2 = np.asarray(Image.fromarray((np.clip(e2 * 3, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5))).astype(float) / 255.0
    pl = plomb[zone]
    plomb[zone] = np.maximum(pl, e2)
    # le verre : ses nuances, ses stries, ses bulles
    stries = valeur(6, 1616, W2, H2, cy=60) * 0.5 + fbm(8, 4, 1617, W2, H2) * 0.5
    c *= (0.82 + 0.3 * stries)[..., None]
    for _ in range(500):
        bx, by = rng.integers(0, W2), rng.integers(0, H2)
        br = rng.uniform(1.5, 4)
        m = ((xx[max(0, by - 5):by + 5, max(0, bx - 5):bx + 5] - bx) ** 2 + (yy[max(0, by - 5):by + 5, max(0, bx - 5):bx + 5] - by) ** 2) < br * br
        c[max(0, by - 5):by + 5, max(0, bx - 5):bx + 5][m] *= 1.15
    # le plomb : gris sombre, un reflet au milieu
    plomb = np.clip(plomb, 0, 1)
    c = c * (1 - plomb[..., None]) + np.array([0.1, 0.1, 0.11]) * plomb[..., None]
    rgba = np.dstack([np.clip(c, 0, 1), alpha])
    img = Image.fromarray((rgba * 255).astype(np.uint8), "RGBA").resize((W, H), Image.LANCZOS)
    sauver("vitrail", img)


# =================================================================== l'Île des Géants

N = 1024


def bois_peint():
    # le fil du bois (le long de v), sous une peinture blanche qui s'écaille
    fil = valeur(24, 1620, N, N, cy=3) * 0.6 + valeur(70, 1621, N, N, cy=6) * 0.4
    nuage = fbm(4, 4, 1622, N, N)
    ecaille = fbm(10, 5, 1623, N, N)
    pelee = np.clip((ecaille - 0.68) * 9, 0, 1)                 # le bois à nu
    bord = np.clip((ecaille - 0.63) * 9, 0, 1) - pelee          # le bord de la peinture, un peu relevé
    sale = fbm(6, 4, 1624, N, N)
    bois = np.array([0.52, 0.48, 0.42]) * (0.75 + 0.35 * fil)[..., None]
    peint = np.array([0.93, 0.92, 0.88]) * (0.92 + 0.08 * nuage - 0.1 * np.clip(sale - 0.6, 0, 1))[..., None]
    peint = peint * (1 - 0.05 * (fil - 0.5))[..., None]
    c = peint * (1 - pelee[..., None]) + bois * pelee[..., None]
    c *= (1 - 0.18 * np.clip(bord, 0, 1))[..., None]
    h = fil * 0.25 * (0.3 + 0.7 * pelee) + (1 - pelee) * 0.35 + np.clip(bord, 0, 1) * 0.15
    r = 0.55 + 0.35 * pelee
    sauver_tex("bois_peint", c, h, 3.0, r)


def zinc_galva():
    d1, d2, idx = voronoi(N, 140, 1625)
    teinte = (np.random.default_rng(1626).random(140) * 0.22 + 0.78)[idx]
    grain = (np.random.default_rng(1627).random(140))[idx]
    # les fleurs de zinc : chaque cristal sa nuance, et de fines stries dans le cristal
    yy, xx = np.mgrid[0:N, 0:N]
    ang = grain * np.pi
    stries = 0.5 + 0.5 * np.sin((xx * np.cos(ang) + yy * np.sin(ang)) * 0.9)
    joint = np.clip(1 - (d2 - d1) / 2.5, 0, 1)
    nuage = fbm(5, 4, 1628, N, N)
    rouille = np.clip((fbm(12, 4, 1629, N, N) - 0.7) * 5, 0, 1)
    v = 0.66 * teinte * (0.96 + 0.04 * stries) * (0.92 + 0.12 * nuage) - 0.05 * joint
    c = np.repeat(v[..., None], 3, -1) * np.array([0.98, 1.0, 1.02])
    c = c * (1 - 0.6 * rouille[..., None]) + np.array([0.88, 0.88, 0.84]) * 0.6 * rouille[..., None]
    h = teinte * 0.2 + stries * 0.03 - joint * 0.1
    r = 0.42 + 0.3 * (1 - teinte) + 0.3 * rouille
    sauver_tex("zinc_galva", c, h, 2.0, r)


def caoutchouc():
    grain = flou(np.random.default_rng(1630).random((N, N)), 2)
    plis = valeur(6, 1631, N, N, cy=40) * 0.7 + fbm(8, 3, 1632, N, N) * 0.3
    boue = np.clip((fbm(7, 5, 1633, N, N) - 0.64) * 5, 0, 1)
    v = 0.92 + 0.06 * (plis - 0.5)
    # neutre : la matière le teinte (vert pour les bottes, noir pour le pneu)
    c = np.array([0.8, 0.8, 0.8]) * v[..., None]
    c = c * (1 - boue[..., None]) + np.array([1.1, 0.85, 0.6]) * boue[..., None]
    h = grain * 0.15 + plis * 0.4 + boue * 0.3
    r = 0.5 + 0.1 * grain + 0.35 * boue
    sauver_tex("caoutchouc", c, h, 2.5, r)


def terre_cuite():
    nuage = fbm(4, 5, 1634, N, N)
    grain = flou(np.random.default_rng(1635).random((N, N)), 1)
    pores = (np.random.default_rng(1636).random((N, N)) > 0.985).astype(float)
    sel = np.clip((fbm(9, 5, 1637, N, N) * 0.7 + valeur(30, 1638, N, N, cy=4) * 0.3 - 0.64) * 3, 0, 1) * 0.6
    humide = np.clip((fbm(5, 4, 1639, N, N) - 0.6) * 4, 0, 1)
    c = np.array([0.74, 0.4, 0.25]) * (0.86 + 0.24 * nuage + 0.06 * (grain - 0.5))[..., None]
    c *= (1 - 0.25 * humide)[..., None]
    c = c * (1 - 0.7 * sel[..., None]) + np.array([0.86, 0.84, 0.78]) * 0.7 * sel[..., None]
    c *= (1 - 0.5 * flou(pores, 1))[..., None]
    h = grain * 0.1 - flou(pores, 1) * 0.8 + sel * 0.08
    r = 0.88 - 0.15 * humide
    sauver_tex("terre_cuite", c, h, 3.0, r)


def foin_rond():
    yy, xx = np.mgrid[0:N, 0:N]
    dx, dy = (xx - N / 2) / (N / 2), (yy - N / 2) / (N / 2)
    rr = np.sqrt(dx * dx + dy * dy)
    ang = np.arctan2(dy, dx)
    # la spirale : une couche de paille par tour, des brins qui dépassent
    tour = rr * 22 - ang / (2 * np.pi)
    couche = 0.5 + 0.5 * np.cos(tour * 2 * np.pi)
    brins = valeur(300, 1640, N, N, cy=300)
    tache = fbm(8, 4, 1641, N, N)
    v = 0.66 + 0.2 * couche + 0.2 * (brins - 0.5) + 0.1 * (tache - 0.5)
    c = np.array([0.86, 0.72, 0.42]) * v[..., None]
    c *= (1 - 0.35 * np.clip((rr - 0.94) * 20, 0, 1))[..., None]
    c = c * (1 - 0.25 * np.clip((0.06 - rr) * 30, 0, 1))[..., None]
    h = couche * 0.5 + brins * 0.3
    sauver_tex("foin_rond", c, h, 3.0)


def corde():
    yy, xx = np.mgrid[0:N, 0:N] / N
    # trois torons qui tournent : des bandes en biais, chacune faite de fibres
    t = (xx * 3 + yy * 3) % 1.0
    toron = np.sin(t * np.pi) ** 0.6
    fibres = valeur(4, 1642, N, N, cy=200) * 0.5 + valeur(8, 1643, N, N, cy=400) * 0.5
    fib = 0.5 + 0.5 * np.sin((xx * 3 - yy * 9 + fibres * 0.3) * 2 * np.pi * 8)
    v = 0.5 + 0.35 * toron + 0.12 * (fib - 0.5)
    c = np.array([0.72, 0.6, 0.42]) * v[..., None]
    h = toron * 0.8 + fib * 0.1
    sauver_tex("corde", c, h, 4.0)


def tweed():
    yy, xx = np.mgrid[0:N, 0:N]
    # des chevrons : le sens du sergé s'inverse toutes les bandes
    bande = (xx // 32) % 2
    diag = np.where(bande == 0, (xx + yy) % 16, (yy - xx) % 16)
    serge = (diag < 8).astype(float)
    fils = np.random.default_rng(1644).random((N, N))
    couleur = np.where(fils[..., None] > 0.7, np.array([0.42, 0.36, 0.26]), np.where(fils[..., None] > 0.4, np.array([0.3, 0.32, 0.36]), np.array([0.22, 0.24, 0.28])))
    nuage = fbm(6, 4, 1645, N, N)
    c = couleur * (0.85 + 0.2 * serge + 0.1 * nuage)[..., None]
    c = np.stack([flou(c[..., k], 1) for k in range(3)], -1)
    h = flou(serge, 1) * 0.6 + fils * 0.2
    sauver_tex("tweed", c, h, 2.0)


def toile_lin():
    yy, xx = np.mgrid[0:N, 0:N]
    trame = 0.5 + 0.5 * np.sin(xx * 2 * np.pi / 8) * np.sin(yy * 2 * np.pi / 8)
    irr = valeur(64, 1646, N, N, cy=8) * 0.5 + valeur(8, 1647, N, N, cy=64) * 0.5
    nuage = fbm(5, 4, 1648, N, N)
    tache = np.clip((fbm(9, 4, 1649, N, N) - 0.66) * 4, 0, 1)
    v = 0.86 + 0.08 * trame + 0.08 * (irr - 0.5) + 0.06 * (nuage - 0.5)
    c = np.array([0.92, 0.88, 0.78]) * v[..., None]
    c *= (1 - 0.2 * tache)[..., None]
    h = trame * 0.6 + irr * 0.2
    sauver_tex("toile_lin", c, h, 2.0)


# =================================================================== Néopolis

def conteneur():
    yy, xx = np.mgrid[0:N, 0:N] / N
    # les ondes : 8 par motif, un profil trapézoïdal (les conteneurs ont des ondes à pans)
    o = (xx * 8) % 1.0
    onde = np.clip(np.abs(o - 0.5) * 4 - 0.5, 0, 1)
    nuage = fbm(5, 5, 1650, N, N)
    eclats = np.clip((fbm(18, 4, 1651, N, N) - 0.68) * 7, 0, 1)
    coul = valeur(40, 1652, N, N, cy=3) * 0.6 + valeur(90, 1653, N, N, cy=5) * 0.4
    rouille = np.clip((coul - 0.64) * 3, 0, 1) * np.clip(1.0 - yy * 1.2, 0, 1) * 0.6 + eclats * 0.8
    rouille = np.clip(rouille, 0, 1)
    crasse = np.clip((yy - 0.75) * 4, 0, 1) * (0.5 + 0.5 * nuage)
    ray = np.zeros((N, N))
    rng = np.random.default_rng(1654)
    for _ in range(40):
        x0, y0 = rng.random() * N, rng.random() * N
        a = rng.uniform(-0.3, 0.3)
        l = rng.uniform(20, 120)
        t = np.linspace(0, 1, int(l))
        xs = (x0 + np.cos(a) * l * t).astype(int) % N
        ys = (y0 + np.sin(a) * l * t).astype(int) % N
        ray[ys, xs] = 1.0
    ray = flou(ray, 1)
    v = 0.86 + 0.1 * (nuage - 0.5) - 0.08 * onde
    c = np.repeat(v[..., None], 3, -1)
    c = c * (1 - rouille[..., None] * 0.85) + np.array([0.42, 0.22, 0.12]) * rouille[..., None] * 0.85 * (0.8 + 0.4 * nuage)[..., None]
    c *= (1 - 0.35 * crasse)[..., None]
    c = c * (1 - 0.3 * ray[..., None]) + 0.3 * ray[..., None] * np.array([0.7, 0.68, 0.64])
    h = onde * 1.0 - eclats * 0.05 + rouille * 0.04
    r = 0.55 + 0.35 * rouille + 0.1 * crasse
    sauver_tex("conteneur", c, h, 6.0, r)


def main() -> int:
    print("V161 : les textures de la Citadelle des Nuées et de l'Île des Géants")
    page_livre()
    vitrail()
    bois_peint()
    zinc_galva()
    caoutchouc()
    terre_cuite()
    foin_rond()
    corde()
    tweed()
    toile_lin()
    conteneur()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
