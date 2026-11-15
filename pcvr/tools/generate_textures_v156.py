"""V156 : les textures des intérieurs de Néopolis (faites ici ; versées au domaine public, CC0 1.0).

Chaque matière : une image de couleur (nom.png) et sa carte de relief (nom_n.png), 1024 × 1024,
qui se raccordent sur leurs bords (on les répète sur les sols, les murs, les meubles). Les
couleurs sont neutres quand le jeu les teinte (la moquette, le tissu, le cuir).

  plafond_dalles   les dalles de plafond (60 cm, fibre minérale, ossature en T)      2,4 m
  moquette         une moquette bouclée                                               1,0 m
  beton_cire       du béton ciré (nuages, pores, fines fissures)                      4,0 m
  enduit           un enduit de mur (peau d'orange)                                   2,0 m
  bois_chene       du chêne (fil, maillures)                                          1,0 m
  bois_noyer       du noyer                                                           1,0 m
  marbre_blanc     un marbre blanc veiné                                              2,0 m
  marbre_noir      un marbre noir veiné d'or                                          2,0 m
  tissu            un tissage (canapés, banquettes)                                   0,5 m
  cuir             un cuir grainé                                                     0,5 m
  inox_brosse      de l'inox brossé                                                   1,0 m
  sol_technique    des dalles de faux plancher perforées (60 cm)                      1,2 m
  carrelage        un carrelage blanc (20 cm), ses joints                             1,2 m
  papier_peint     un papier peint (rayures douces, petits losanges)                  1,0 m
  lattes_bois      un mur de lattes de bois verticales                                1,2 m
  ecran_code       un écran : un éditeur (des lignes de couleur sur fond sombre)       (un écran)
  ecran_graphes    un écran : un tableau de bord (des barres, une courbe, des cases)    (un écran)
  ecran_messages   un écran : une messagerie (des bulles, une liste)                    (un écran)
  eau              des vaguelettes (le relief seul : eau_n ; la piscine le fait glisser) 2,0 m
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_textures_v156.py
"""
from pathlib import Path
import sys

import numpy as np
from PIL import Image

N = 1024
OUT = Path(__file__).resolve().parents[2] / "www" / "assets" / "textures" / "neo156"
RNG = np.random.default_rng(156)


# =================================================================== le bruit (qui se raccorde)

def _lisse(t):
    return t * t * (3.0 - 2.0 * t)


def valeur(cell, seed, n=N):
    """Bruit de valeur périodique : une grille de cell × cell, interpolée."""
    r = np.random.default_rng(seed)
    g = r.random((cell, cell))
    x = np.arange(n) * cell / n
    i0 = np.floor(x).astype(int)
    f = _lisse(x - i0)
    i1 = (i0 + 1) % cell
    i0 = i0 % cell
    a = g[np.ix_(i0, i0)]
    b = g[np.ix_(i0, i1)]
    c = g[np.ix_(i1, i0)]
    d = g[np.ix_(i1, i1)]
    fy = f[:, None]
    fx = f[None, :]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def fbm(cell, oct_, seed, gain=0.5, n=N):
    s = np.zeros((n, n))
    amp = 1.0
    tot = 0.0
    for o in range(oct_):
        s += amp * valeur(cell * (2 ** o), seed + o * 17, n)
        tot += amp
        amp *= gain
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
    nz = np.ones_like(h)
    l = np.sqrt(dx * dx + dy * dy + nz * nz)
    nx, ny, nz = -dx / l, dy / l, nz / l
    return np.stack([nx * 0.5 + 0.5, ny * 0.5 + 0.5, nz * 0.5 + 0.5], -1)


def teinte(v, c0, c1):
    v = np.clip(v, 0, 1)[..., None]
    return np.array(c0)[None, None, :] * (1 - v) + np.array(c1)[None, None, :] * v


def sauver(nom, couleur, h, force):
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(couleur, 0, 1) * 255).astype(np.uint8)).save(OUT / f"{nom}.png", optimize=True)
    Image.fromarray((np.clip(normale(h, force), 0, 1) * 255).astype(np.uint8)).save(OUT / f"{nom}_n.png", optimize=True)
    print("  ", nom)


def coords():
    y, x = np.mgrid[0:N, 0:N] / N
    return x, y


# =================================================================== les matières

def plafond_dalles():
    x, y = coords()
    k = 4                                   # 4 × 4 dalles sur 2,4 m
    fx = (x * k) % 1.0
    fy = (y * k) % 1.0
    bord = np.minimum(np.minimum(fx, 1 - fx), np.minimum(fy, 1 - fy))
    t_bar = bord < 0.012
    biseau = np.clip((bord - 0.012) / 0.02, 0, 1)
    fibre = fbm(64, 4, 1) * 0.6 + grain(2) * 0.4
    trous = (grain(3) > 0.985).astype(float)
    trous = flou(trous, 1)
    h = np.where(t_bar, 1.0, 0.55 + 0.25 * biseau + 0.06 * fibre - 0.5 * trous)
    c = teinte(0.75 + 0.2 * fibre - 0.5 * trous, (0.8, 0.8, 0.79), (0.97, 0.97, 0.96))
    c = np.where(t_bar[..., None], np.array([0.93, 0.93, 0.94])[None, None, :], c)
    ombre = np.clip(1 - (1 - biseau) * 0.18, 0, 1)
    c = c * ombre[..., None]
    sauver("plafond_dalles", c, h, 6.0)


def moquette():
    g = grain(11)
    boucles = flou(g, 1)
    rang = (np.sin(np.arange(N) / N * np.pi * 2 * 180)[:, None] * 0.5 + 0.5) * 0.25
    nuage = fbm(8, 3, 12)
    h = boucles * 0.7 + rang * 0.3
    v = 0.55 + 0.25 * boucles + 0.12 * (nuage - 0.5) + 0.08 * rang
    sauver("moquette", teinte(v, (0.25, 0.25, 0.26), (0.85, 0.85, 0.86)), h, 9.0)


def beton_cire():
    nuage = fbm(4, 5, 21)
    taches = fbm(16, 3, 22)
    pores = (grain(23) > 0.992).astype(float)
    pores = flou(pores, 1)
    # de fines fissures : les crêtes d'un bruit
    f = fbm(6, 4, 24)
    fissures = np.clip(1 - np.abs(f - 0.5) * 140, 0, 1) * (fbm(3, 2, 25) > 0.6)
    v = 0.5 + 0.35 * (nuage - 0.5) + 0.12 * (taches - 0.5) - 0.3 * pores - 0.25 * fissures
    h = 0.5 + 0.05 * taches - 0.4 * pores - 0.3 * fissures
    sauver("beton_cire", teinte(v, (0.38, 0.38, 0.39), (0.72, 0.71, 0.7)), h, 4.0)


def enduit():
    peau = flou(fbm(96, 3, 31), 1)
    nuage = fbm(6, 3, 32)
    h = peau
    v = 0.86 + 0.06 * (peau - 0.5) + 0.04 * (nuage - 0.5)
    sauver("enduit", teinte(v, (0.0, 0.0, 0.0), (1.0, 0.995, 0.985)), h, 3.0)


def _bois(seed, clair, fonce, nom):
    x, y = coords()
    # le fil : des veines presque droites (dans le sens de y), qui ondulent à peine
    deform = (fbm(3, 3, seed) - 0.5) * 0.035 + (fbm(12, 2, seed + 5) - 0.5) * 0.006
    cernes = (x + deform) * 22.0
    fil = np.abs(np.sin(cernes * np.pi)) ** 0.6
    # les fibres longues : du bruit étiré dans le sens du fil
    r = np.random.default_rng(seed + 3)
    col = r.random((1, N))
    for _ in range(2):
        col = (col + np.roll(col, 1, 1) + np.roll(col, -1, 1)) / 3.0
    fibres = np.repeat(col, N, 0)
    fibres = fibres + (np.repeat(valeur(64, seed + 6)[:1, :], N, 0) - 0.5) * 0.2 + (fbm(2, 3, seed + 7) - 0.5) * 0.3
    pores = (grain(seed + 2) > 0.985) * (fil < 0.5)
    maille = np.clip((fbm(10, 3, seed + 4) - 0.68) * 6, 0, 1) * 0.12
    v = 0.3 + 0.32 * fil + 0.22 * fibres - 0.12 * pores + maille
    h = 0.5 + 0.25 * fil + 0.15 * fibres - 0.2 * pores
    sauver(nom, teinte(v, fonce, clair), h, 2.5)


def bois_chene():
    _bois(41, (0.78, 0.6, 0.4), (0.42, 0.28, 0.16), "bois_chene")


def bois_noyer():
    _bois(51, (0.48, 0.32, 0.2), (0.16, 0.09, 0.05), "bois_noyer")


def _marbre(seed, fond0, fond1, veine, nom):
    x, y = coords()
    t = fbm(3, 6, seed)
    # une grande veine qui serpente, des veinules qui s'en détachent
    v1 = np.abs(np.sin((x * 1.0 + y * 1.0 + (t - 0.5) * 1.6) * np.pi * 2))
    t2 = fbm(5, 6, seed + 1)
    v2 = np.abs(np.sin((x * 3.0 - y * 1.0 + (t2 - 0.5) * 2.4) * np.pi * 2))
    t3 = fbm(8, 5, seed + 3)
    v3 = np.abs(np.sin((x * 2.0 + y * 4.0 + (t3 - 0.5) * 3.0) * np.pi * 2))
    veines = np.clip(1 - v1 * 10, 0, 1) ** 1.5 * 0.95 + np.clip(1 - v2 * 26, 0, 1) * 0.55 * (fbm(4, 2, seed + 4) > 0.45) \
        + np.clip(1 - v3 * 40, 0, 1) * 0.35
    veines = flou(np.clip(veines, 0, 1), 1)
    nuage = fbm(4, 5, seed + 2)
    base = teinte(nuage, fond0, fond1)
    c = base * (1 - veines[..., None]) + np.array(veine)[None, None, :] * veines[..., None]
    h = 0.5 + 0.02 * nuage
    sauver(nom, c, h, 1.0)


def marbre_blanc():
    _marbre(61, (0.82, 0.82, 0.83), (0.96, 0.96, 0.95), (0.55, 0.55, 0.58), "marbre_blanc")


def marbre_noir():
    _marbre(71, (0.03, 0.03, 0.035), (0.09, 0.09, 0.1), (0.75, 0.62, 0.35), "marbre_noir")


def tissu():
    x, y = coords()
    k = 220
    chaine = np.sin(x * np.pi * 2 * k) * 0.5 + 0.5
    trame = np.sin(y * np.pi * 2 * k) * 0.5 + 0.5
    case = ((np.floor(x * k) + np.floor(y * k)) % 2)
    tiss = np.where(case > 0, chaine, trame)
    fils = flou(grain(81), 1)
    chine = fbm(32, 3, 82)
    h = tiss * 0.8 + fils * 0.2
    v = 0.6 + 0.2 * tiss + 0.1 * (chine - 0.5) + 0.08 * fils
    sauver("tissu", teinte(v, (0.2, 0.2, 0.2), (0.95, 0.95, 0.95)), h, 5.0)


def cuir():
    # un grain : des cellules (le minimum de bruits décalés)
    g = np.minimum(valeur(160, 91), valeur(160, 92))
    g = np.minimum(g, valeur(200, 93))
    grain_ = flou(g, 1)
    use = fbm(4, 3, 94)
    h = grain_
    v = 0.55 + 0.25 * grain_ + 0.15 * (use - 0.5)
    sauver("cuir", teinte(v, (0.1, 0.08, 0.07), (0.95, 0.9, 0.86)), h, 6.0)


def inox_brosse():
    r = np.random.default_rng(101)
    traits = np.repeat(r.random((N, 1)), N, 1)
    traits = (traits + np.roll(traits, 1, 0) * 0.5) / 1.5
    long_ = np.repeat(fbm(64, 2, 102)[:, :1], N, 1)
    v = 0.62 + 0.12 * traits + 0.08 * (long_ - 0.5) + 0.04 * grain(103)
    h = traits
    sauver("inox_brosse", teinte(v, (0.0, 0.0, 0.0), (1.0, 1.0, 1.02)), h, 1.5)


def sol_technique():
    x, y = coords()
    k = 2
    fx = (x * k) % 1.0
    fy = (y * k) % 1.0
    bord = np.minimum(np.minimum(fx, 1 - fx), np.minimum(fy, 1 - fy))
    joint = bord < 0.008
    # la grille de perforations
    px = (x * k * 24) % 1.0
    py = (y * k * 24) % 1.0
    trou = ((px - 0.5) ** 2 + (py - 0.5) ** 2) < 0.06
    zone = (bord > 0.08)
    trou = trou & zone
    use = fbm(8, 3, 111)
    v = 0.5 + 0.1 * (use - 0.5) - 0.35 * trou - 0.3 * joint
    h = np.where(joint, 0.0, 0.8) - 0.5 * trou
    sauver("sol_technique", teinte(v, (0.12, 0.13, 0.15), (0.6, 0.62, 0.66)), flou(h.astype(float), 1), 6.0)


def carrelage():
    x, y = coords()
    k = 6
    fx = (x * k) % 1.0
    fy = (y * k) % 1.0
    bord = np.minimum(np.minimum(fx, 1 - fx), np.minimum(fy, 1 - fy))
    joint = bord < 0.025
    arrondi = np.clip((bord - 0.025) / 0.03, 0, 1)
    nuance = valeur(k, 121)
    v = np.where(joint, 0.55, 0.9 + 0.05 * (nuance - 0.5) + 0.03 * fbm(32, 2, 122))
    h = np.where(joint, 0.0, 0.6 + 0.4 * arrondi)
    sauver("carrelage", teinte(v, (0.0, 0.0, 0.0), (0.98, 0.98, 0.97)), h, 5.0)


def papier_peint():
    x, y = coords()
    rayures = (np.sin(x * np.pi * 2 * 10) * 0.5 + 0.5) ** 4
    mx = (x * 20) % 1.0
    my = (y * 14) % 1.0
    losange = (np.abs(mx - 0.5) + np.abs(my - 0.5)) < 0.12
    papier = fbm(48, 3, 131)
    v = 0.8 + 0.06 * rayures + 0.06 * losange + 0.04 * (papier - 0.5)
    c = teinte(v, (0.3, 0.26, 0.2), (1.0, 0.94, 0.84))
    h = 0.5 + 0.1 * losange + 0.05 * papier
    sauver("papier_peint", c, h, 2.0)


def lattes_bois():
    x, y = coords()
    k = 16
    fx = (x * k) % 1.0
    lame = np.floor(x * k)
    gap = (fx < 0.12)
    teinte_lame = np.random.default_rng(141).random(k)[lame.astype(int) % k]
    fil = np.sin((y + fbm(4, 3, 142) * 0.05) * np.pi * 2 * 30 + lame * 1.7) * 0.5 + 0.5
    v = np.where(gap, 0.05, 0.35 + 0.3 * fil ** 2 + 0.25 * teinte_lame)
    h = np.where(gap, 0.0, 0.8 + 0.05 * fil)
    sauver("lattes_bois", teinte(v, (0.2, 0.12, 0.06), (0.86, 0.66, 0.44)), h, 4.0)


def _ecran_sauver(nom, img):
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).save(OUT / f"{nom}.png", optimize=True)
    print("  ", nom)


def ecran_code():
    W, H = 512, 320
    r = np.random.default_rng(161)
    img = np.zeros((H, W, 3)) + np.array([0.06, 0.07, 0.1])
    img[:, :70] = [0.09, 0.1, 0.14]
    img[:18, :] = [0.13, 0.14, 0.2]
    cols = [(0.55, 0.75, 1.0), (0.95, 0.6, 0.85), (0.6, 0.95, 0.6), (1.0, 0.8, 0.45), (0.8, 0.8, 0.85)]
    y = 26
    while y < H - 8:
        x = 80 + int(r.integers(0, 4)) * 16
        img[y:y + 6, 30:56] = [0.3, 0.32, 0.4]
        while x < W - 30 and r.random() < 0.85:
            w = int(r.integers(14, 70))
            img[y:y + 6, x:min(W - 10, x + w)] = cols[int(r.integers(0, len(cols)))]
            x += w + 8
        y += 12
    _ecran_sauver("ecran_code", img)


def ecran_graphes():
    W, H = 512, 320
    r = np.random.default_rng(162)
    img = np.zeros((H, W, 3)) + np.array([0.92, 0.94, 0.97])
    img[:24, :] = [0.16, 0.36, 0.7]
    # les cases
    for k in range(4):
        x0 = 14 + k * 124
        img[34:84, x0:x0 + 112] = [1, 1, 1]
        img[34:38, x0:x0 + 112] = [[0.2, 0.6, 1.0], [0.3, 0.8, 0.5], [1.0, 0.6, 0.2], [0.9, 0.3, 0.5]][k]
        img[58:70, x0 + 10:x0 + 60] = [0.25, 0.27, 0.32]
    # les barres
    img[96:306, 14:250] = [1, 1, 1]
    for k in range(9):
        h = int(r.integers(30, 180))
        img[296 - h:296, 26 + k * 24:42 + k * 24] = [0.2, 0.55, 0.95]
    # la courbe
    img[96:306, 262:498] = [1, 1, 1]
    xs = np.arange(270, 490)
    ys = (200 - 60 * np.sin((xs - 270) / 30.0) - (xs - 270) * 0.3).astype(int)
    for dx in range(-1, 2):
        img[np.clip(ys + dx, 100, 300), xs] = [0.95, 0.4, 0.55]
    _ecran_sauver("ecran_graphes", img)


def ecran_messages():
    W, H = 512, 320
    r = np.random.default_rng(163)
    img = np.zeros((H, W, 3)) + np.array([0.12, 0.13, 0.17])
    img[:, :150] = [0.17, 0.18, 0.23]
    for k in range(9):
        y0 = 12 + k * 34
        img[y0:y0 + 26, 8:142] = [0.22, 0.24, 0.3] if k != 2 else [0.25, 0.4, 0.7]
        c = [[0.95, 0.5, 0.6], [0.4, 0.8, 0.95], [0.6, 0.9, 0.5], [1.0, 0.8, 0.4]][k % 4]
        yy, xx = np.mgrid[0:20, 0:20]
        disque = ((yy - 10) ** 2 + (xx - 10) ** 2) < 90
        img[y0 + 3:y0 + 23, 14:34][disque] = c
        img[y0 + 6:y0 + 11, 42:42 + int(r.integers(40, 90))] = [0.85, 0.86, 0.9]
        img[y0 + 15:y0 + 19, 42:42 + int(r.integers(30, 95))] = [0.5, 0.52, 0.6]
    y = 20
    for k in range(6):
        moi = k % 2 == 1
        w = int(r.integers(120, 260))
        h = 34 if r.random() < 0.6 else 52
        x0 = W - 16 - w if moi else 166
        img[y:y + h, x0:x0 + w] = [0.2, 0.5, 0.95] if moi else [0.26, 0.28, 0.35]
        for ln in range(h // 18):
            img[y + 8 + ln * 16:y + 13 + ln * 16, x0 + 10:x0 + w - int(r.integers(10, 60))] = [0.92, 0.94, 0.98]
        y += h + 12
    _ecran_sauver("ecran_messages", img)


def eau():
    h = fbm(6, 5, 151) * 0.6 + fbm(12, 4, 152) * 0.4
    h = flou(h, 2)
    sauver("eau", teinte(h, (0.1, 0.45, 0.6), (0.35, 0.75, 0.85)), h, 18.0)


TOUT = [plafond_dalles, moquette, beton_cire, enduit, bois_chene, bois_noyer, marbre_blanc, marbre_noir, tissu, cuir, inox_brosse,
        sol_technique, carrelage, papier_peint, lattes_bois, eau, ecran_code, ecran_graphes, ecran_messages]


def main() -> int:
    print("V156 : les textures des intérieurs ->", OUT)
    for f in TOUT:
        f()
    return 0


if __name__ == "__main__":
    sys.exit(main())
