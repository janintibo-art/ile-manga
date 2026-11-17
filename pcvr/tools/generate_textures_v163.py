"""V163 : les textures de Port-Azur et de la teuf de la plage (faites ici ; CC0 1.0). Dossier
www/assets/textures/beau163/.

  dalles_azur  les dalles de calcaire blond du quai et de la place (la texture couvre 4 m) : des rangs
               de hauteurs différentes, des dalles de longueurs différentes, chacune sa nuance (crème,
               miel, gris), le cœur poli par les pas, les arêtes émoussées, des coins ébréchés, de
               petits fossiles, les joints de sable, les taches (le café, l'huile), le sel.
  pierre_fine  le calcaire fin des encadrements, des appuis, des bandeaux (la texture couvre 1,5 m) :
               le grain, les traces de la boucharde, de rares veines.
  banderole    la banderole de toile nouée devant les platines : « DJ MISTRAL », la vague et le vent,
               l'ourlet cousu, les œillets ; la peinture un peu passée par le soleil.
  bambou       les flambeaux : les fibres, le jaune paille, les taches brunes, les brûlures (1 m).
  flight       les flight-cases : le stratifié noir granité.
  palette      le bois des palettes : du pin brut de sciage, les traits de scie, les nœuds, le gris.
  bois_flotte  les mâts des guirlandes : le bois flotté argenté, ses fentes, son fil.
  prairie_fees la prairie du royaume des fées (la texture couvre 6 m) : l'herbe drue de plusieurs verts,
               les brins secs, l'ombre entre les touffes, des fleurettes en touffes (pâquerettes,
               boutons d'or, myosotis, roses).
  trefle_fees  le tapis de trèfle et de mousse (là où l'herbe est rase) : les feuilles en trois cœurs,
               leur croissant clair, les fleurs de trèfle blanches et roses.

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_textures_v163.py
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

RACINE = Path(__file__).resolve().parents[2]
OUT = RACINE / "www" / "assets" / "textures" / "beau163"
POLICE = "/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf"


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


def sauver(nom, c, h=None, force=3.0, rough=None, n_moitie=False):
    OUT.mkdir(parents=True, exist_ok=True)
    c = np.clip(c, 0, 1)
    Image.fromarray((c * 255).round().astype(np.uint8)).save(OUT / f"{nom}.png", optimize=True)
    if h is not None:
        im = Image.fromarray((np.clip(normale(h, force), 0, 1) * 255).round().astype(np.uint8))
        if n_moitie:
            # le relief d'une herbe drue : la moitié de la taille suffit (et le fichier reste léger)
            im = im.resize((im.width // 2, im.height // 2), Image.LANCZOS)
        im.save(OUT / f"{nom}_n.png", optimize=True)
    if rough is not None:
        Image.fromarray((np.clip(rough, 0, 1) * 255).round().astype(np.uint8), "L").save(OUT / f"{nom}_r.png", optimize=True)
    print("  ", nom)


def flou(a, r):
    k = int(r * 3) + 1
    x = np.arange(-k, k + 1)
    g = np.exp(-x * x / (2.0 * r * r))
    g /= g.sum()
    b = sum(np.roll(a, int(i), 0) * w for i, w in zip(x, g))
    return sum(np.roll(b, int(i), 1) * w for i, w in zip(x, g))


# =================================================================== Port-Azur

def dalles_azur():
    N = 2048
    rng = np.random.default_rng(1631)
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    # des rangs (de 40 à 80 cm : la texture couvre 4 m, 512 px par mètre), des dalles de 50 à 120 cm
    rangs = []
    y = 0
    while y < N:
        hgt = int(rng.integers(160, 330))
        if N - y - hgt < 150:
            hgt = N - y
        rangs.append((y, y + hgt))
        y += hgt
    id_ = np.zeros((N, N), dtype=np.int32)
    bord = np.full((N, N), 1e9)
    k = 0
    for (y0, y1) in rangs:
        a0 = int(rng.integers(0, 300))
        coupes = [a0]
        x = a0
        while x + 720 < a0 + N:
            x += int(rng.integers(200, 520))
            coupes.append(x)
        coupes.append(a0 + N)
        sel = (yy >= y0) & (yy < y1)
        ry = np.minimum(yy - y0, y1 - 1 - yy)
        for i in range(len(coupes) - 1):
            a, b = coupes[i], coupes[i + 1]
            for dec in (0, -N, N):
                m = sel & (xx >= a + dec) & (xx < b + dec)
                if not m.any():
                    continue
                id_[m] = k
                rx = np.minimum(xx - (a + dec), (b + dec) - 1 - xx)
                bord[m] = np.minimum(rx, ry)[m]
            k += 1
    nb = k
    h1 = rng.random(nb)
    h2 = rng.random(nb)
    h3 = rng.random(nb)
    t1 = h1[id_]
    t2 = h2[id_]
    t3 = h3[id_]
    # la nuance de chaque dalle : crème, miel, gris clair
    creme = np.array([0.74, 0.69, 0.58])
    miel = np.array([0.72, 0.6, 0.44])
    gris = np.array([0.62, 0.61, 0.57])
    c = creme * (1 - 0.45 * t1[..., None]) + miel * 0.45 * t1[..., None]
    c = c * (1 - (t2[..., None] > 0.78) * 0.3) + gris * (t2[..., None] > 0.78) * 0.3
    c *= (0.94 + 0.09 * t3)[..., None]
    # le grain, les nuages du calcaire, les petits fossiles
    gr = fbm(64, 4, 1632, N, N)
    nu = fbm(8, 5, 1633, N, N)
    c *= (0.86 + 0.18 * nu + 0.08 * (gr - 0.5))[..., None]
    fos = (rng.random((N, N)) > 0.99965).astype(float)
    fos = flou(fos, 2.2) * 40
    c = c * (1 - np.clip(fos, 0, 0.5)[..., None] * 0.18)
    # le cœur poli (plus clair, plus lisse), les arêtes émoussées, les coins ébréchés
    poli = np.clip(bord / 90.0, 0, 1) * np.clip((fbm(10, 3, 1634, N, N) - 0.3) * 2.0, 0, 1)
    c = c * (1 + 0.07 * poli[..., None])
    ech = np.clip((fbm(90, 3, 1635, N, N) - 0.62) * 6, 0, 1) * (bord < 26)
    joint = np.clip(1 - bord / 7.0, 0, 1)
    chanfrein = np.clip(1 - bord / 22.0, 0, 1)
    sable = np.array([0.47, 0.42, 0.34]) * (0.85 + 0.3 * gr[..., None])
    c = c * (1 - chanfrein[..., None] * 0.18)
    c = c * (1 - np.maximum(joint, ech * 0.8)[..., None]) + sable * np.maximum(joint, ech * 0.8)[..., None]
    # la crasse le long des joints, les taches (café, huile), le sel blanc
    crasse = np.clip(1 - bord / 40.0, 0, 1) * fbm(30, 3, 1636, N, N)
    c *= (1 - 0.16 * crasse)[..., None]
    tache = np.clip((fbm(14, 4, 1637, N, N) - 0.7) * 5, 0, 1)
    c = c * (1 - 0.22 * tache[..., None]) + np.array([0.36, 0.3, 0.24]) * 0.22 * tache[..., None]
    sel = np.clip((fbm(20, 4, 1638, N, N) - 0.68) * 4, 0, 1) * (1 - poli)
    c = c * (1 - 0.18 * sel[..., None]) + np.array([0.86, 0.85, 0.8]) * 0.18 * sel[..., None]
    # le relief : chaque dalle un peu de travers, les joints en creux, le grain
    pente = (t2 - 0.5) * (xx % 512) / 512.0 * 0.4 + (t3 - 0.5) * (yy % 512) / 512.0 * 0.4
    h = -chanfrein * 1.2 - joint * 1.5 - ech * 1.0 + gr * 0.25 + pente * 0.3 - fos * 0.3
    r = 0.72 - 0.22 * poli + 0.2 * joint + 0.1 * ech
    sauver("dalles_azur", c, h, 2.6, r)


def pierre_fine():
    N = 1024
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    gr = fbm(96, 4, 1641, N, N)
    nu = fbm(6, 5, 1642, N, N)
    # les traces de la boucharde : de petits creux serrés
    rng = np.random.default_rng(1643)
    pts = (rng.random((N, N)) > 0.985).astype(float)
    bou = flou(pts, 1.4) * 9
    veine = np.clip(1 - np.abs(fbm(5, 4, 1644, N, N) - 0.5) * 60, 0, 1) * np.clip((fbm(4, 2, 1645, N, N) - 0.5) * 4, 0, 1)
    base = np.array([0.8, 0.76, 0.66])
    c = base * (0.88 + 0.16 * nu + 0.1 * (gr - 0.5))[..., None]
    c *= (1 - 0.1 * np.clip(bou, 0, 1))[..., None]
    c = c * (1 - 0.25 * veine[..., None]) + np.array([0.62, 0.56, 0.44]) * 0.25 * veine[..., None]
    h = gr * 0.4 - np.clip(bou, 0, 1) * 0.6
    r = 0.78 + 0.1 * (gr - 0.5)
    sauver("pierre_fine", c, h, 2.0, r)


# =================================================================== la teuf

def banderole():
    W, H = 2048, 560
    yy, xx = np.mgrid[0:H, 0:W].astype(float)
    # la toile bleu nuit, sa trame, le soleil qui l'a passée
    trame = (np.sin(xx * 1.9) * 0.5 + 0.5) * 0.5 + (np.sin(yy * 1.9) * 0.5 + 0.5) * 0.5
    passe = fbm(5, 4, 1651, W, H, ) * 0.6 + yy / H * 0.0
    fond = np.array([0.07, 0.13, 0.27]) * (0.88 + 0.12 * trame)[..., None]
    fond = fond * (1 - 0.25 * passe[..., None]) + np.array([0.3, 0.36, 0.48]) * 0.25 * passe[..., None]
    img = Image.fromarray((np.clip(fond, 0, 1) * 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    # les vagues et le vent (des arcs blancs et turquoise) de chaque côté
    for cx in (118, W - 118):
        for k in range(3):
            r = 34 + k * 24
            d.arc([cx - r, 300 - r, cx + r, 300 + r], 200, 340, fill=(64, 200, 210) if k % 2 == 0 else (240, 240, 230), width=11)
        for k in range(3):
            r = 34 + k * 24
            d.arc([cx - r, 360 - r, cx + r, 360 + r], 20, 160, fill=(240, 240, 230) if k % 2 == 0 else (64, 200, 210), width=11)
    # le titre
    f1 = ImageFont.truetype(POLICE, 250)
    f2 = ImageFont.truetype(POLICE, 72)
    t1 = "DJ MISTRAL"
    t2 = "·  LA TEUF DE LA PLAGE  ·"
    b1 = d.textbbox((0, 0), t1, font=f1)
    b2 = d.textbbox((0, 0), t2, font=f2)
    x1 = (W - (b1[2] - b1[0])) // 2 - b1[0]
    x2 = (W - (b2[2] - b2[0])) // 2 - b2[0]
    # l'ombre portée, puis le jaune soleil
    d.text((x1 + 10, 52 + 10), t1, font=f1, fill=(10, 18, 36))
    d.text((x1, 52), t1, font=f1, fill=(250, 200, 60))
    d.text((x2, 380), t2, font=f2, fill=(232, 236, 230))
    a = np.asarray(img).astype(float) / 255.0
    # la peinture : un peu craquelée, la trame qui transparaît
    cr = np.clip((fbm(60, 3, 1652, W, H) - 0.62) * 5, 0, 1)
    lum = a.mean(-1)
    peint = lum > 0.35
    a = np.where(peint[..., None], a * (0.92 + 0.08 * trame[..., None]) * (1 - 0.18 * cr[..., None]), a)
    # l'ourlet cousu (une ligne de points), les œillets de laiton aux coins
    m = 22
    ourlet = ((np.abs(xx - m) < 2) | (np.abs(xx - (W - m)) < 2) | (np.abs(yy - m) < 2) | (np.abs(yy - (H - m)) < 2)) & (((xx + yy) % 14) < 8)
    a[ourlet] = a[ourlet] * 0.4 + np.array([0.85, 0.83, 0.75]) * 0.6
    bord = (xx < 10) | (xx > W - 11) | (yy < 10) | (yy > H - 11)
    a[bord] *= 0.7
    for (ox, oy) in ((48, 48), (W - 48, 48), (48, H - 48), (W - 48, H - 48), (W // 2, 48), (W // 2, H - 48)):
        r = np.sqrt((xx - ox) ** 2 + (yy - oy) ** 2)
        anneau = (r > 9) & (r < 19)
        trou = r <= 9
        a[anneau] = np.array([0.78, 0.64, 0.32]) * (0.8 + 0.3 * ((yy[anneau] - oy) < 0))[..., None]
        a[trou] = np.array([0.04, 0.04, 0.05])
    sauver("banderole", a)


def bambou():
    N = 512
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    fib = valeur(180, 1661, N, N, cy=3) * 0.6 + valeur(400, 1662, N, N, cy=5) * 0.4
    nu = fbm(4, 4, 1663, N, N)
    base = np.array([0.74, 0.65, 0.44])
    c = base * (0.82 + 0.22 * fib + 0.12 * (nu - 0.5))[..., None]
    tache = np.clip((fbm(12, 4, 1664, N, N) - 0.7) * 4, 0, 1)
    c = c * (1 - 0.25 * tache[..., None]) + np.array([0.46, 0.34, 0.18]) * 0.25 * tache[..., None]
    # les brûlures du haut (la texture : v = 0 en bas, 1 m plus haut)
    brule = np.clip((fbm(8, 3, 1665, N, N) - 0.7) * 4, 0, 1)
    c *= (1 - 0.45 * brule)[..., None]
    h = fib * 0.5 - tache * 0.1
    r = 0.5 + 0.25 * tache + 0.1 * brule
    sauver("bambou", c, h, 1.6, r)


def flight():
    N = 1024
    gr = fbm(160, 3, 1671, N, N)
    gr2 = fbm(48, 2, 1672, N, N)
    c = np.ones((N, N, 3)) * np.array([0.055, 0.055, 0.06])[None, None, :] * (0.85 + 0.3 * gr2)[..., None]
    rayure = np.clip((fbm(30, 3, 1673, N, N) - 0.74) * 6, 0, 1) * (valeur(400, 1674, N, N, cy=8) > 0.6)
    c = c + rayure[..., None] * 0.08
    h = gr * 1.0 + gr2 * 0.3
    r = 0.6 + 0.12 * gr - 0.15 * rayure
    sauver("flight", c, h, 3.0, r)


def palette():
    N = 1024
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    fil = valeur(6, 1681, N, N, cy=90) * 0.5 + valeur(14, 1682, N, N, cy=240) * 0.5
    anneaux = np.sin((yy + fbm(3, 3, 1683, N, N) * 420 + valeur(4, 1687, N, N, cy=60) * 40) * 0.035) * 0.5 + 0.5
    # les traits de la scie : des arcs larges, à travers le fil
    rs = np.sqrt((xx - N * 0.5) ** 2 + (yy + N * 1.6) ** 2)
    scie = (np.sin(rs * 0.2 + valeur(3, 1684, N, N) * 6) * 0.5 + 0.5) ** 8 * (0.4 + 0.6 * valeur(8, 1688, N, N))
    base = np.array([0.8, 0.68, 0.5])
    c = base * (0.82 + 0.16 * fil + 0.06 * anneaux)[..., None]
    c *= (1 - 0.05 * scie)[..., None]
    gris = np.clip((fbm(5, 4, 1685, N, N) - 0.45) * 2.0, 0, 1)
    c = c * (1 - 0.4 * gris[..., None]) + np.array([0.56, 0.54, 0.5]) * 0.4 * gris[..., None]
    rng = np.random.default_rng(1686)
    noeuds = np.zeros((N, N))
    for _ in range(5):
        x0, y0 = rng.random() * N, rng.random() * N
        r = np.sqrt(((xx - x0 + N / 2) % N - N / 2) ** 2 * 1.0 + (((yy - y0 + N / 2) % N - N / 2) * 0.55) ** 2)
        noeuds = np.maximum(noeuds, np.clip(1 - r / 22, 0, 1))
    c = c * (1 - 0.5 * noeuds[..., None]) + np.array([0.38, 0.24, 0.12]) * 0.5 * noeuds[..., None]
    h = fil * 0.4 - scie * 0.3 - noeuds * 0.2
    r = 0.85 + 0.08 * scie
    sauver("palette", c, h, 2.5, r)


def bois_flotte():
    N = 1024
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    fil = valeur(5, 1691, N, N, cy=120) * 0.5 + valeur(12, 1692, N, N, cy=300) * 0.5
    fente = np.clip(1 - np.abs(valeur(40, 1693, N, N, cy=3) - 0.5) * 70, 0, 1) * np.clip((valeur(20, 1694, N, N, cy=2) - 0.5) * 4, 0, 1)
    nu = fbm(5, 4, 1695, N, N)
    base = np.array([0.66, 0.63, 0.57])
    c = base * (0.78 + 0.26 * fil + 0.12 * (nu - 0.5))[..., None]
    c = c * (1 - 0.6 * fente[..., None]) + np.array([0.18, 0.16, 0.14]) * 0.6 * fente[..., None]
    brun = np.clip((nu - 0.62) * 4, 0, 1)
    c = c * (1 - 0.25 * brun[..., None]) + np.array([0.5, 0.42, 0.32]) * 0.25 * brun[..., None]
    h = fil * 0.7 - fente * 1.2
    r = 0.88 - 0.1 * fil
    sauver("bois_flotte", c, h, 3.0, r)


# =================================================================== le royaume des fées

def _brins(N, n, seed, couleurs, longueur, epais):
    """Des brins d'herbe vus d'en haut (de petits traits de travers), dessinés à plat ; rend la couleur
    et la hauteur."""
    rng = np.random.default_rng(seed)
    img = Image.new("RGB", (N, N))
    hau = Image.new("L", (N, N))
    d = ImageDraw.Draw(img)
    dh = ImageDraw.Draw(hau)
    xs = rng.random(n) * N
    ys = rng.random(n) * N
    an = rng.normal(-1.2, 0.7, n)
    ln = longueur * (0.5 + rng.random(n))
    ci = rng.integers(0, len(couleurs), n)
    br = 0.75 + 0.5 * rng.random(n)
    for k in range(n):
        x0, y0 = xs[k], ys[k]
        x1 = x0 + np.cos(an[k]) * ln[k]
        y1 = y0 + np.sin(an[k]) * ln[k]
        c = np.clip(np.array(couleurs[ci[k]]) * br[k], 0, 1)
        col = tuple(int(v * 255) for v in c)
        hv = int(80 + 170 * (k / n))
        for dx in (0, -N, N):
            for dy in (0, -N, N):
                if -40 < x0 + dx < N + 40 and -40 < y0 + dy < N + 40:
                    d.line([(x0 + dx, y0 + dy), (x1 + dx, y1 + dy)], fill=col, width=epais)
                    dh.line([(x0 + dx, y0 + dy), (x1 + dx, y1 + dy)], fill=hv, width=epais)
    return np.asarray(img).astype(float) / 255.0, np.asarray(hau).astype(float) / 255.0


def _fleurettes(c, h, n, seed, couleurs, rayon):
    N = c.shape[0]
    rng = np.random.default_rng(seed)
    img = Image.fromarray((np.clip(c, 0, 1) * 255).astype(np.uint8))
    hau = Image.fromarray((np.clip(h, 0, 1) * 255).astype(np.uint8), "L")
    d = ImageDraw.Draw(img)
    dh = ImageDraw.Draw(hau)
    # en touffes : des centres, des fleurs autour
    centres = rng.random((max(1, n // 14), 2)) * N
    for k in range(n):
        cx, cy = centres[rng.integers(0, len(centres))]
        x = (cx + rng.normal(0, N * 0.035)) % N
        y = (cy + rng.normal(0, N * 0.035)) % N
        coul, coeur = couleurs[rng.integers(0, len(couleurs))]
        r = rayon * (0.7 + 0.6 * rng.random())
        for a in range(5):
            t = a / 5 * 6.2832 + rng.random()
            px, py = x + np.cos(t) * r * 0.8, y + np.sin(t) * r * 0.8
            d.ellipse([px - r * 0.6, py - r * 0.6, px + r * 0.6, py + r * 0.6], fill=tuple(int(v * 255) for v in coul))
        d.ellipse([x - r * 0.45, y - r * 0.45, x + r * 0.45, y + r * 0.45], fill=tuple(int(v * 255) for v in coeur))
        dh.ellipse([x - r * 1.3, y - r * 1.3, x + r * 1.3, y + r * 1.3], fill=255)
    return np.asarray(img).astype(float) / 255.0, np.asarray(hau).astype(float) / 255.0


def prairie_fees():
    # la prairie (la texture couvre ~6 m) : l'herbe drue, plusieurs verts, des brins secs, l'ombre
    # entre les touffes, des fleurettes en touffes (pâquerettes, boutons d'or, myosotis)
    N = 2048
    verts = [(0.24, 0.42, 0.12), (0.3, 0.5, 0.14), (0.2, 0.36, 0.1), (0.36, 0.52, 0.18), (0.42, 0.5, 0.2), (0.55, 0.55, 0.28)]
    fond = np.array([0.12, 0.2, 0.06]) * (0.8 + 0.4 * fbm(16, 4, 1701, N, N))[..., None]
    c, h = _brins(N, 150000, 1702, verts, 15, 2)
    m = (h > 0)[..., None]
    c = np.where(m, c, fond)
    touffe = fbm(24, 4, 1703, N, N)
    c *= (0.72 + 0.5 * touffe)[..., None]
    jaune = np.clip((fbm(6, 4, 1704, N, N) - 0.55) * 3, 0, 1)
    c = c * (1 - 0.25 * jaune[..., None]) + np.array([0.48, 0.5, 0.2]) * 0.25 * jaune[..., None]
    c, h2 = _fleurettes(c, h, 2600, 1705, [((0.95, 0.95, 0.92), (0.95, 0.8, 0.2)), ((0.98, 0.84, 0.15), (0.9, 0.7, 0.1)), ((0.55, 0.65, 0.95), (0.95, 0.9, 0.5)), ((0.95, 0.65, 0.8), (0.95, 0.85, 0.4))], 4.0)
    hh = h * 0.6 + touffe * 0.6 + h2 * 0.3
    sauver("prairie_fees", c, hh, 4.0, n_moitie=True)


def trefle_fees():
    # le tapis de trèfle et de mousse (la texture couvre ~3 m) : les feuilles en trois cœurs, la mousse
    # entre elles, des trèfles blancs en fleur
    N = 2048
    rng = np.random.default_rng(1711)
    mousse = np.array([0.16, 0.28, 0.08]) * (0.75 + 0.5 * fbm(40, 4, 1712, N, N))[..., None]
    img = Image.fromarray((np.clip(mousse, 0, 1) * 255).astype(np.uint8))
    hau = Image.fromarray((fbm(40, 4, 1712, N, N) * 90).astype(np.uint8), "L")
    d = ImageDraw.Draw(img)
    dh = ImageDraw.Draw(hau)
    for k in range(26000):
        x, y = rng.random() * N, rng.random() * N
        r = 7 + rng.random() * 7
        a0 = rng.random() * 6.2832
        g = 0.75 + 0.5 * rng.random()
        col = tuple(int(v * 255 * g) for v in (0.25, 0.41, 0.15))
        clair = tuple(int(min(255, v * 255 * g * 1.1)) for v in (0.29, 0.46, 0.18))
        hv = int(110 + 140 * rng.random())
        for f in range(3):
            t = a0 + f * 2.094
            px, py = x + np.cos(t) * r * 0.62, y + np.sin(t) * r * 0.62
            d.ellipse([px - r * 0.55, py - r * 0.55, px + r * 0.55, py + r * 0.55], fill=col)
            d.ellipse([px - r * 0.2, py - r * 0.2, px + r * 0.2, py + r * 0.2], fill=clair)
            dh.ellipse([px - r * 0.55, py - r * 0.55, px + r * 0.55, py + r * 0.55], fill=hv)
    c = np.asarray(img).astype(float) / 255.0
    h = np.asarray(hau).astype(float) / 255.0
    c, h2 = _fleurettes(c, h, 420, 1713, [((0.96, 0.94, 0.9), (0.9, 0.86, 0.75)), ((0.95, 0.8, 0.88), (0.9, 0.7, 0.8))], 6.0)
    sauver("trefle_fees", c, h * 0.8 + h2 * 0.3, 4.0, n_moitie=True)


def main() -> int:
    print("V163 : les textures de Port-Azur et de la teuf")
    dalles_azur()
    pierre_fine()
    banderole()
    bambou()
    flight()
    palette()
    bois_flotte()
    prairie_fees()
    trefle_fees()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
