"""V158 : les sols partagés en haute définition, et quelques textures d'intérieur trop petites.

  terrain/grass, sand, stone   512 → 2048 (couleur, jpg) ; relief 512 → 1024 (png)
  terrain/rock                 1024 → 2048 (couleur) ; relief refait en 1024
  interior/floor, ceiling      refaits en 1024 (les planchers des maisons de l'île du départ :
                               des lames de bois, leur fil, leurs joints décalés) + relief
  ramure/papier                256 → 1024 (le papier des cloisons de Ramure) + relief
  atlantide/frise              son relief (la frise peinte, à peine en relief)

On agrandit (Lanczos, en raccordant les bords), on rend du piqué (masque flou), puis on ajoute
le détail fin qui manquait : la texture elle-même, quatre fois plus petite (son grain, à sa
propre échelle), et un grain propre à chaque matière (les brins d'herbe, les grains de sable,
le grain de la pierre). Tout reste raccordable (on répète ces textures sur des kilomètres).
Les originaux sont gardés dans terrain/origine/ (et */origine/), d'où l'on repart à chaque fois.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_textures_v158.py
"""
from pathlib import Path
import shutil

import numpy as np
from PIL import Image

TX = Path(__file__).resolve().parents[2] / "www" / "assets" / "textures"


# =================================================================== outils (raccordables)

def lire(p):
    return np.asarray(Image.open(p).convert("RGB"), dtype=np.float64) / 255.0


def agrandir(a, taille):
    """Agrandit une image raccordable (on l'entoure de ses propres bords avant de l'agrandir)."""
    h, w = a.shape[:2]
    m = max(4, w // 16)
    pad = np.pad(a, ((m, m), (m, m), (0, 0)), mode="wrap")
    f = taille / w
    im = Image.fromarray((np.clip(pad, 0, 1) * 255).round().astype(np.uint8))
    im = im.resize((int(round(pad.shape[1] * f)), int(round(pad.shape[0] * f))), Image.LANCZOS)
    b = np.asarray(im, dtype=np.float64) / 255.0
    o = int(round(m * f))
    return b[o:o + taille, o:o + taille]


def reduire(a, taille):
    im = Image.fromarray((np.clip(a, 0, 1) * 255).round().astype(np.uint8))
    return np.asarray(im.resize((taille, taille), Image.BOX), dtype=np.float64) / 255.0


def flou(x, k=1):
    out = x.copy()
    for _ in range(k):
        out = (out + np.roll(out, 1, 0) + np.roll(out, -1, 0) + np.roll(out, 1, 1) + np.roll(out, -1, 1)) / 5.0
    return out


def flou_large(x, r):
    """Un flou plus large (des moyennes glissantes répétées, raccordables)."""
    out = x.copy()
    for _ in range(3):
        acc = np.zeros_like(out)
        for d in range(-r, r + 1):
            acc += np.roll(out, d, 0)
        out = acc / (2 * r + 1)
        acc = np.zeros_like(out)
        for d in range(-r, r + 1):
            acc += np.roll(out, d, 1)
        out = acc / (2 * r + 1)
    return out


def lum(a):
    return a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114


def bruit(seed, n):
    return np.random.default_rng(seed).random((n, n))


def stries(seed, n, long_=6):
    """Des brins : du bruit étiré dans un sens (un peu de travers selon l'endroit)."""
    g = bruit(seed, n)
    out = g.copy()
    for d in range(1, long_ + 1):
        out += np.roll(np.roll(g, d, 0), d // 3, 1) + np.roll(np.roll(g, -d, 0), -(d // 3), 1)
    return out / (2 * long_ + 1)


def normale(h, force):
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * force
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5 * force
    l = np.sqrt(dx * dx + dy * dy + 1.0)
    return np.stack([-dx / l, dy / l, 1.0 / l], -1)


def vers_rgb(n):
    return np.clip(n * 0.5 + 0.5, 0, 1)


def depuis_rgb(a):
    n = a * 2.0 - 1.0
    return n / np.maximum(np.linalg.norm(n, axis=-1, keepdims=True), 1e-6)


def origine(rel):
    """Le fichier d'origine (gardé dans …/origine/ la première fois)."""
    p = TX / rel
    o = p.parent / "origine" / p.name
    if not o.exists():
        o.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(p, o)
    return o


def sauver_jpg(rel, a, q=92):
    Image.fromarray((np.clip(a, 0, 1) * 255).round().astype(np.uint8)).save(TX / rel, quality=q, subsampling=0, optimize=True)


def sauver_png(rel, a):
    Image.fromarray((np.clip(a, 0, 1) * 255).round().astype(np.uint8)).save(TX / rel, optimize=True)


# =================================================================== la recette commune

def hd(rel, taille, grain, k_soi=0.3, piqué=0.55, rel_n=None, taille_n=1024, force_n=3.0, k_n=0.6, jpg=True, r_hp=6):
    """Agrandit rel à taille, ajoute le détail ; refait son relief (rel_n) à taille_n."""
    a0 = lire(origine(rel))
    w0 = a0.shape[1]
    f = taille // w0
    a = agrandir(a0, taille)
    # du piqué : un masque flou à l'échelle de l'agrandissement
    a = a + (a - flou_large(a, max(1, f // 2))) * piqué
    # la texture elle-même, f fois plus petite : son grain à sa propre échelle
    t = np.tile(a0, (f, f, 1))
    lt = lum(t)
    hp = lt - flou_large(lt, 2)
    m = max(1e-3, float(lum(a0).mean()))
    a = a * (1.0 + k_soi * hp / m)[..., None]
    # le grain propre à la matière
    d = grain(taille)
    a = a * (1.0 + d)[..., None]
    a = np.clip(a, 0, 1)
    if jpg:
        sauver_jpg(rel, a)
    else:
        sauver_png(rel, a)
    if rel_n is not None:
        # le relief : celui d'origine agrandi, et le relief du nouveau détail
        po = TX / rel_n
        if po.exists() or (po.parent / "origine" / po.name).exists():
            b0 = lire(origine(rel_n))
            n0 = depuis_rgb(agrandir(b0, taille_n) if b0.shape[1] != taille_n else b0)
        else:
            n0 = np.zeros((taille_n, taille_n, 3))
            n0[..., 2] = 1.0
        h = lum(reduire(a, taille_n))
        h = h - flou_large(h, r_hp)
        nd = normale(h, force_n * taille_n / 1024.0)
        n = np.stack([n0[..., 0] + nd[..., 0] * k_n, n0[..., 1] + nd[..., 1] * k_n, n0[..., 2]], -1)
        n = n / np.linalg.norm(n, axis=-1, keepdims=True)
        sauver_png(rel_n, vers_rgb(n))
    print("  ", rel, a.shape[1], "px", (rel_n or ""))


# =================================================================== les matières

def g_herbe(seed):
    def g(n):
        s = stries(seed, n, 7)
        s = (s - s.mean()) / (s.std() + 1e-6)
        fin = bruit(seed + 1, n) - 0.5
        return s * 0.055 + fin * 0.05
    return g


def g_sable(seed):
    def g(n):
        grains = flou(bruit(seed, n), 1) - 0.5
        points = bruit(seed + 1, n)
        sombres = flou((points > 0.996).astype(float), 1) * -0.5
        clairs = flou((points < 0.004).astype(float), 1) * 0.45
        return grains * 0.16 + sombres + clairs
    return g


def g_pierre(seed, k=1.0):
    def g(n):
        grain = flou(bruit(seed, n), 1) - 0.5
        pores = flou((bruit(seed + 1, n) > 0.997).astype(float), 1) * -0.45
        return (grain * 0.13 + pores) * k
    return g


def g_papier(seed):
    def g(n):
        fib = stries(seed, n, 4)
        fib = (fib - fib.mean()) / (fib.std() + 1e-6)
        return fib * 0.018 + (flou(bruit(seed + 1, n), 1) - 0.5) * 0.03
    return g


def valeur(cell, seed, n):
    """Bruit de valeur périodique (cell × cell cases sur n pixels)."""
    r = np.random.default_rng(seed)
    g = r.random((cell, cell))
    x = np.arange(n) * cell / n
    i0 = np.floor(x).astype(int)
    f = x - i0
    f = f * f * (3 - 2 * f)
    i1 = (i0 + 1) % cell
    i0 = i0 % cell
    a, b, c, d = g[np.ix_(i0, i0)], g[np.ix_(i0, i1)], g[np.ix_(i1, i0)], g[np.ix_(i1, i1)]
    fy, fx = f[:, None], f[None, :]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def etire(cy, cx, seed, n):
    """Bruit de valeur périodique étiré (cy cases en hauteur, cx en largeur) : des fibres."""
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


def fbm(cell, oct_, seed, n, gain=0.5):
    s = np.zeros((n, n))
    amp = tot = 1.0
    s += valeur(cell, seed, n)
    for o in range(1, oct_):
        amp *= gain
        s += amp * valeur(cell * (2 ** o), seed + o * 17, n)
        tot += amp
    return s / tot


def plancher(rel, seed, lames=8, moyenne=(0.376, 0.278, 0.196), n=1024):
    """Un plancher de lames de bois (le fil le long de x), des joints décalés, chaque lame sa
    teinte ; sa couleur moyenne reste celle de l'ancienne texture (le jeu la teinte pareil)."""
    origine(rel)
    r = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float64)
    hl = n // lames
    lame = (yy // hl).astype(int)
    ly = (yy % hl) / hl                                     # 0..1 dans la largeur de la lame
    # les bouts de lames : deux ou trois par rang, décalés d'un rang à l'autre
    coupe = np.zeros((n, n), dtype=int)
    joints_x = np.zeros((n, n))
    for k in range(lames):
        nb = int(r.integers(1, 3))
        xs = np.sort((r.random(nb) * n).astype(int))
        rows = slice(k * hl, (k + 1) * hl)
        xk = xx[rows]
        idx = np.zeros_like(xk, dtype=int)
        d = np.full_like(xk, 1e9)
        for j, x0 in enumerate(xs):
            idx += (xk >= x0)
            dd = np.abs(((xk - x0 + n / 2) % n) - n / 2)
            d = np.minimum(d, dd)
        coupe[rows] = (idx % nb) + k * 7
        joints_x[rows] = d
    cle = (lame * 31 + coupe * 17) % 97
    teintes = 0.86 + 0.28 * r.random(97)
    decal = r.random(97) * n
    # le fil : des cernes le long de x qui ondulent (différents d'une lame à l'autre), les
    # lignes plus sombres du bois d'été, des fibres longues, des nuances le long de la lame
    deform = (fbm(4, 4, seed + 1, n) - 0.5) * 1.4 + (etire(8, 2, seed + 2, n) - 0.5) * 0.8
    phase = decal[cle] / n * 7.0
    cernes = ly * 5.5 + deform + phase
    fil = 0.5 + 0.5 * np.sin(cernes * np.pi * 2)
    fr = cernes % 1.0
    lignes = np.exp(-((fr - 0.5) / 0.07) ** 2)
    fibres = etire(n // 2, 24, seed + 3, n) * 0.6 + etire(n // 4, 6, seed + 5, n) * 0.4
    nuance = etire(lames * 2, 3, seed + 6, n)
    noeuds = np.zeros((n, n))
    for _ in range(4):
        kx, ky = r.random() * n, (int(r.integers(0, lames)) + 0.3 + 0.4 * r.random()) * hl
        dx = ((xx - kx + n / 2) % n) - n / 2
        dy = ((yy - ky + n / 2) % n) - n / 2
        noeuds = np.maximum(noeuds, np.clip(1 - np.hypot(dx / 2.2, dy) / (hl * 0.22), 0, 1) ** 2)
    usure = fbm(3, 4, seed + 4, n)
    v = teintes[cle] * (0.78 + 0.07 * fil - 0.1 * lignes + 0.14 * (fibres - 0.5) + 0.1 * (nuance - 0.5) + 0.06 * (usure - 0.5)) * (1 - 0.4 * noeuds)
    # les joints : creux et sombres
    jy = np.minimum(ly, 1 - ly) * hl
    joint = np.clip(1 - np.minimum(jy, joints_x) / 2.2, 0, 1)
    v = v * (1 - 0.7 * joint)
    teinte = np.array([1.0, 0.74, 0.5])
    c = v[..., None] * teinte[None, None, :]
    c = c * (np.array(moyenne) / c.mean(axis=(0, 1)))[None, None, :]
    sauver_png(rel, c)
    bombe = np.sin(np.clip(ly, 0, 1) * np.pi) ** 0.3
    h = bombe * 0.5 - lignes * 0.05 + fibres * 0.06 - noeuds * 0.1 - joint * 0.6 + (teintes[cle] - 1.0) * 0.3
    rel_n = rel.replace(".png", "_n.png")
    sauver_png(rel_n, vers_rgb(normale(h, 3.0)))
    print("  ", rel, n, "px", rel_n)


def frise():
    """La frise d'Atlantide (peinte) : à peine en relief, la peinture un peu épaisse."""
    a = lire(TX / "atlantide/frise.png")
    h = flou(lum(a), 2)
    sauver_png("atlantide/frise_n.png", vers_rgb(normale(h, 2.0)))
    print("   atlantide/frise_n.png")


def main() -> int:
    print("V158 : les sols partagés et les petites textures, en haute définition")
    hd("terrain/grass.jpg", 2048, g_herbe(1581), k_soi=0.3, piqué=0.45, rel_n="terrain/grass_n.png", force_n=2.5, k_n=0.5)
    hd("terrain/sand.jpg", 2048, g_sable(1582), k_soi=0.3, rel_n="terrain/sand_n.png", force_n=3.0, k_n=0.6)
    hd("terrain/stone.jpg", 2048, g_pierre(1583), k_soi=0.3, rel_n="terrain/stone_n.png", force_n=3.0, k_n=0.5)
    hd("terrain/rock.jpg", 2048, g_pierre(1584, 0.8), k_soi=0.25, rel_n="terrain/rock_n.png", force_n=3.0, k_n=0.45)
    plancher("interior/floor.png", 1585)
    plancher("interior/ceiling.png", 1586, lames=7, moyenne=(0.366, 0.276, 0.197))
    hd("ramure/papier.png", 1024, g_papier(1587), k_soi=0.15, piqué=0.3, rel_n="ramure/papier_n.png", force_n=2.0, k_n=1.0, jpg=False)
    frise()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
