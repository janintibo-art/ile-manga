"""V66 : textures des objets qu'on casse et des coffres qu'on ouvre.

objets/  caisse.png (+_n)      : une face de caisse — quatre planches de pin clouées, jours entre
                                 elles, nœuds, têtes de clous, bois grisé en bas par l'humidité ;
         douelles.png (+_n)    : les douelles d'un tonneau de chêne, tout le tour (u = l'angle),
                                 joints serrés, coulures sombres près du jable ;
         coffre.png (+_n)      : le bois d'un coffre — chêne sombre ciré, larges planches ;
         fer.png (+_n)         : fer forgé martelé, piqué, avec des plaques de rouille ;
         osier.png (+_n)       : de l'osier tressé (paniers) ;
         terre_cuite.png (+_n) : terre cuite tournée — sillons du tour, grains, coup de feu.
items/   petite_cle.png        : l'icône de la petite clé (argument « icones »).
Tout est dessiné ici (libre de droits).
Lancement depuis la racine du dépôt : python3 pcvr/tools/generate_objets_v66.py [icones]
"""
from pathlib import Path
import math
import sys

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "objets"
rng = np.random.default_rng(6666)
S = 512


def tile_noise(w, h, ox=(4, 8, 16, 32, 64, 128), oy=None, falloff=0.55):
    oy = oy or ox
    acc = np.zeros((h, w), dtype=np.float32)
    amp, total = 1.0, 0.0
    for fx, fy in zip(ox, oy):
        layer = rng.random((fy, fx)).astype(np.float32)
        big = Image.fromarray((np.tile(layer, (3, 3)) * 255).astype(np.uint8)).resize((w * 3, h * 3), Image.BICUBIC)
        acc += np.asarray(big, dtype=np.float32)[h:h * 2, w:w * 2] / 255.0 * amp
        total += amp
        amp *= falloff
    acc /= total
    return np.clip((acc - acc.mean()) * 1.8 + 0.5, 0, 1)


def normal_map(h, strength):
    gy, gx = np.gradient(h)
    n = np.dstack((-gx * strength, -gy * strength, np.ones_like(h)))
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    return Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8), "RGB")


def save(col, h, strength, name):
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB").save(OUT / f"{name}.png", optimize=True)
    normal_map(h, strength).save(OUT / f"{name}_n.png", optimize=True)
    print("objets/" + name)


def grain(w, h, along_x=True):
    """Veinage : bruit très étiré dans le sens des fibres, plus des cernes ondulés."""
    if along_x:
        g = tile_noise(w, h, ox=(2, 4, 8, 16), oy=(32, 64, 128, 256), falloff=0.6)
    else:
        g = tile_noise(w, h, ox=(32, 64, 128, 256), oy=(2, 4, 8, 16), falloff=0.6)
    return g


def knot(col, h, cx, cy, r, dark):
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    d = np.sqrt(((xx - cx) / (r * 1.6)) ** 2 + ((yy - cy) / r) ** 2)
    ring = np.clip(1.0 - d, 0, 1)
    rings = (np.sin(d * 18.0) * 0.5 + 0.5) * np.clip(1.6 - d, 0, 1)
    col *= (1.0 - (ring ** 0.6 * dark + rings * 0.08))[..., None]
    h -= ring * 0.4


# =================================================================== la caisse

def caisse():
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    g = grain(S, S, True)
    fine = tile_noise(S, S, ox=(64, 128, 256), oy=(8, 16, 32), falloff=0.6)
    blot = tile_noise(S, S, ox=(3, 6, 12, 24), falloff=0.6)
    rows = 4
    rh = S / rows
    row = np.floor(yy / rh).astype(int)
    inr = (yy - row * rh) / rh
    col = np.zeros((S, S, 3), np.float32)
    h = np.zeros((S, S), np.float32)
    for r in range(rows):
        m = row == r
        base = np.array([0.74, 0.56, 0.36], np.float32) * rng.uniform(0.86, 1.1) + rng.uniform(-0.03, 0.03, 3).astype(np.float32)
        shift = rng.uniform(0, 1)
        gg = np.roll(g, int(shift * S), axis=1)
        col[m] = base[None, :] * (0.72 + 0.48 * gg[m])[:, None] * (0.94 + 0.12 * fine[m])[:, None]
        # léger tuilage de la planche : bords un peu plus bas
        h[m] += -((inr[m] - 0.5) ** 2) * 0.8
    # jours entre les planches
    edge = np.minimum(inr, 1.0 - inr) * rh
    gap = np.clip(1.0 - edge / 3.5, 0, 1)
    col *= (1.0 - gap * 0.85)[..., None]
    h -= gap * 1.2
    # arêtes usées (plus claires) juste à côté des jours
    wear = np.clip(1.0 - np.abs(edge - 5.0) / 3.0, 0, 1) * (blot > 0.45)
    col += wear[..., None] * 0.06
    # nœuds
    for _ in range(3):
        knot(col, h, rng.uniform(60, S - 60), (rng.integers(0, rows) + rng.uniform(0.35, 0.65)) * rh, rng.uniform(9, 16), 0.45)
    # clous : deux par planche à chaque bout (là où elles tiennent sur le cadre)
    for r in range(rows):
        for cx in (34.0, S - 34.0):
            for d in (0.32, 0.68):
                cy = (r + d) * rh + rng.uniform(-3, 3)
                x0 = cx + rng.uniform(-4, 4)
                m2 = (xx - x0) ** 2 + (yy - cy) ** 2
                head = m2 < 5.5 ** 2
                halo = (m2 < 11 ** 2) & ~head
                col[halo] *= 0.82
                col[head] = np.array([0.24, 0.22, 0.2]) + 0.1 * fine[head][:, None]
                h[head] += 0.35
    # humidité en bas, poussière
    damp = np.clip((yy / S - 0.72) * 3.0, 0, 1) * (0.5 + 0.5 * blot)
    col = col * (1.0 - damp[..., None] * 0.35) + np.array([0.3, 0.3, 0.28]) * damp[..., None] * 0.2
    grey = np.clip((blot - 0.55) * 2.0, 0, 1) * 0.25
    col = col * (1 - grey[..., None]) + np.array([0.62, 0.6, 0.56]) * grey[..., None]
    h += g * 0.2 + fine * 0.12
    save(col, h, 6.0, "caisse")


# =================================================================== les douelles

def douelles():
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    g = grain(S, S, False)
    fine = tile_noise(S, S, ox=(8, 16, 32), oy=(64, 128, 256), falloff=0.6)
    blot = tile_noise(S, S, ox=(3, 6, 12, 24), falloff=0.6)
    n = 16
    sw = S / n
    st = np.floor(xx / sw).astype(int)
    ins = (xx - st * sw) / sw
    col = np.zeros((S, S, 3), np.float32)
    h = np.zeros((S, S), np.float32)
    for k in range(n):
        m = st == k
        base = np.array([0.56, 0.38, 0.22], np.float32) * rng.uniform(0.82, 1.12)
        gg = np.roll(g, int(rng.uniform(0, S)), axis=0)
        col[m] = base[None, :] * (0.7 + 0.5 * gg[m])[:, None] * (0.94 + 0.12 * fine[m])[:, None]
        h[m] += -((ins[m] - 0.5) ** 2) * 0.6
    edge = np.minimum(ins, 1.0 - ins) * sw
    seam = np.clip(1.0 - edge / 1.8, 0, 1)
    col *= (1.0 - seam * 0.7)[..., None]
    h -= seam * 0.8
    # coulures sombres près des fonds (le vin, la bière, la pluie)
    drip = tile_noise(S, S, ox=(32, 64, 128), oy=(2, 4, 8), falloff=0.6)
    for y0, sgn in ((0.0, 1.0), (1.0, -1.0)):
        t = np.clip(1.0 - np.abs(yy / S - y0) * 5.0, 0, 1)
        k2 = t * np.clip((drip - 0.35) * 2.0, 0, 1) * 0.5
        col *= (1.0 - k2)[..., None]
    for _ in range(4):
        knot(col, h, rng.uniform(20, S - 20), rng.uniform(80, S - 80), rng.uniform(6, 10), 0.4)
    grey = np.clip((blot - 0.6) * 2.0, 0, 1) * 0.2
    col = col * (1 - grey[..., None]) + np.array([0.5, 0.46, 0.4]) * grey[..., None]
    h += g * 0.25 + fine * 0.1
    save(col, h, 5.0, "douelles")


# =================================================================== le coffre

def coffre():
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    g = grain(S, S, True)
    fine = tile_noise(S, S, ox=(64, 128, 256), oy=(8, 16, 32), falloff=0.6)
    blot = tile_noise(S, S, ox=(3, 6, 12, 24), falloff=0.6)
    rows = 3
    rh = S / rows
    row = np.floor(yy / rh).astype(int)
    inr = (yy - row * rh) / rh
    col = np.zeros((S, S, 3), np.float32)
    h = np.zeros((S, S), np.float32)
    for r in range(rows):
        m = row == r
        base = np.array([0.42, 0.25, 0.13], np.float32) * rng.uniform(0.88, 1.1)
        gg = np.roll(g, int(rng.uniform(0, S)), axis=1)
        rings = np.sin((yy[m] * 0.12 + gg[m] * 9.0)) * 0.5 + 0.5
        col[m] = base[None, :] * (0.7 + 0.35 * gg[m] + 0.15 * rings)[:, None] * (0.95 + 0.1 * fine[m])[:, None]
        h[m] += -((inr[m] - 0.5) ** 2) * 0.5
    edge = np.minimum(inr, 1.0 - inr) * rh
    seam = np.clip(1.0 - edge / 2.2, 0, 1)
    col *= (1.0 - seam * 0.75)[..., None]
    h -= seam
    # cire : reflets plus clairs par plaques ; usure claire sur les bords
    wax = np.clip((blot - 0.5) * 2.0, 0, 1) * 0.1
    col += wax[..., None] * np.array([0.5, 0.35, 0.2])
    h += g * 0.2 + fine * 0.1
    save(col, h, 5.0, "coffre")


# =================================================================== le fer

def fer():
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    ham = tile_noise(S, S, ox=(16, 32, 64), falloff=0.7)
    fine = tile_noise(S, S, ox=(64, 128, 256), falloff=0.6)
    rust = tile_noise(S, S, ox=(4, 8, 16, 32, 64), falloff=0.62)
    col = np.zeros((S, S, 3), np.float32) + np.array([0.2, 0.2, 0.21])
    col *= (0.75 + 0.5 * ham)[..., None]
    col *= (0.9 + 0.2 * fine)[..., None]
    rk = np.clip((rust - 0.56) * 3.0, 0, 1)
    rc = np.array([0.45, 0.22, 0.09]) * (0.7 + 0.6 * fine[..., None])
    col = col * (1 - rk[..., None]) + rc * rk[..., None]
    # piqûres
    pits = (fine > 0.86) & (rng.random((S, S)) > 0.3)
    col[pits] *= 0.6
    h = ham * 0.8 + fine * 0.2 + rk * 0.15 - pits * 0.3
    save(col, h, 4.0, "fer")


# =================================================================== l'osier

def osier():
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    fine = tile_noise(S, S, ox=(64, 128, 256), oy=(16, 32, 64), falloff=0.6)
    blot = tile_noise(S, S, ox=(4, 8, 16), falloff=0.6)
    rows = 16
    cols = 16
    rh = S / rows
    cw = S / cols
    r = np.floor(yy / rh).astype(int)
    c = np.floor(xx / cw).astype(int)
    v = (yy - r * rh) / rh
    u = (xx - c * cw) / cw
    over = ((r + c) % 2 == 0)
    # brin horizontal : bombé, et qui passe dessus/dessous les montants
    bulge = np.sqrt(np.clip(1.0 - (v * 2 - 1) ** 2, 0, 1))
    dip = np.where(over, 1.0, 0.55) * (0.75 + 0.25 * np.cos((u - 0.5) * math.pi))
    h = bulge * dip
    base = np.array([0.78, 0.62, 0.38])
    col = base[None, None, :] * (0.55 + 0.45 * h[..., None]) * (0.88 + 0.24 * fine[..., None])
    # montants qui apparaissent dans les creux
    stake = np.clip(1.0 - np.abs(u - 0.5) * 6.0, 0, 1) * (~over)
    col = col * (1 - stake[..., None] * 0.35) + np.array([0.55, 0.42, 0.26]) * stake[..., None] * 0.35
    gaps = np.clip(1.0 - np.minimum(v, 1 - v) * rh / 1.5, 0, 1)
    col *= (1.0 - gaps * 0.7)[..., None]
    h -= gaps * 0.5
    dk = np.clip((blot - 0.55) * 2.0, 0, 1) * 0.25
    col *= (1.0 - dk)[..., None]
    h += fine * 0.1
    save(col, h, 6.0, "osier")


# =================================================================== la terre cuite

def terre_cuite():
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    fine = tile_noise(S, S, ox=(32, 64, 128, 256), falloff=0.6)
    blot = tile_noise(S, S, ox=(3, 6, 12, 24), falloff=0.6)
    lines = tile_noise(S, S, ox=(2, 4), oy=(64, 128), falloff=0.6)
    throw = np.sin(yy / S * math.tau * 22.0 + lines * 4.0) * 0.5 + 0.5
    col = np.array([0.74, 0.4, 0.24])[None, None, :] * (0.85 + 0.2 * blot[..., None]) * (0.92 + 0.12 * fine[..., None])
    col *= (0.95 + 0.06 * throw)[..., None]
    # coup de feu (plus sombre par endroits) et efflorescences claires
    fire = np.clip((blot - 0.62) * 2.5, 0, 1) * 0.3
    col *= (1.0 - fire)[..., None]
    salt = np.clip((tile_noise(S, S, ox=(8, 16, 32), falloff=0.6) - 0.66) * 3.0, 0, 1) * 0.35
    col = col * (1 - salt[..., None]) + np.array([0.86, 0.8, 0.7]) * salt[..., None]
    grains = rng.random((S, S)) > 0.985
    col[grains] *= 0.7
    h = throw * 0.35 + fine * 0.3 - grains * 0.2
    save(col, h, 3.0, "terre_cuite")


# =================================================================== l'icône de la petite clé

def icones():
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import generate_items_v28 as icons  # noqa: E402
    img = icons.canvas()
    k = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    d = ImageDraw.Draw(k)
    iron = (120, 112, 104, 255)
    dark = (70, 64, 60, 255)
    # anneau en trèfle
    for (cx, cy) in ((130, 200), (130, 312), (190, 256)):
        d.ellipse((cx - 62, cy - 62, cx + 62, cy + 62), fill=iron)
    for (cx, cy) in ((130, 200), (130, 312), (190, 256)):
        d.ellipse((cx - 28, cy - 28, cx + 28, cy + 28), fill=(0, 0, 0, 0))
    d.ellipse((108, 234, 152, 278), fill=dark)
    # tige et panneton
    d.rectangle((240, 236, 460, 276), fill=iron)
    d.rectangle((250, 230, 270, 282), fill=dark)
    d.rectangle((380, 276, 404, 344), fill=iron)
    d.rectangle((420, 276, 444, 326), fill=iron)
    d.rectangle((444, 276, 462, 344), fill=iron)
    # reflets
    d.line((246, 244, 452, 244), fill=(190, 182, 170, 255), width=6)
    k = k.rotate(30, resample=Image.BICUBIC, center=(256, 256))
    img.alpha_composite(k)
    icons.OUT = ROOT / "www" / "assets" / "textures" / "items"
    icons.save(img, "petite_cle")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "icones":
        icones()
    else:
        caisse()
        douelles()
        coffre()
        fer()
        osier()
        terre_cuite()
        icones()
