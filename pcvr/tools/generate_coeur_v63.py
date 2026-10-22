"""V63 : textures de la grande enquête des Quatre Sceaux et du donjon du Cœur-de-Pierre.

coeur/  pierre.png (+_n)      : le granit appareillé des salles (grands blocs piquetés, joints) ;
        dalles.png (+_n)      : les dalles du sol (calcaire usé, fissures, poussière dans les joints) ;
        gres.png (+_n)        : le grès des Sables et du tombeau (lits de sédiment, arêtes rongées) ;
        corail.png (+_n)      : la pierre des Marées, couverte de corail, d'algues et de balanes ;
        ardoise.png (+_n)     : l'ardoise feuilletée de l'Aile de la Lune ;
        fresque_peuples.png   : la fresque du vestibule (les quatre peuples devant la porte) ;
        fresque_bergerie.png  : la fresque du tombeau (le berger, la grotte, la roue dentée) ;
        fresque_mare.png      : la fresque de la Bergerie (la mare, la vanne, la pleine lune) ;
        chant_berger.png      : la planche peinte du chant du berger ;
        stele_soleil.png      : la stèle de l'Aile des Sables (la course du soleil) ;
        tapis.png             : les tapis roulants de la forge des pistons ;
        emblem_*.png          : les médaillons de bronze des quatre ailes ;
        anneau_tombeau.png    : les anneaux à symboles de la porte du tombeau ;
        roue_moutons.png      : les roues aux moutons de la Bergerie ;
        phases_lune.png       : les cadrans des phases de la lune ;
        rose_sceaux.png       : la rose des vents incrustée au sol de la Rose des Sceaux (alpha) ;
        encre_lune.png        : l'écriture d'argent que révèle la Lueur de lune (alpha).
items/  journal_bord, sceau_sables, sceau_airain, sceau_brumes, sceau_embruns, lame_coeur.
Les disques (anneaux, roues, cadrans) sont posés sur des CylinderMesh : leur face avant lit le
quart inférieur gauche de l'image (u 0..0.5, v 0..0.5 + 0.5), dessiné à l'endroit.
Tout est dessiné ici (libre de droits).
Lancement depuis la racine du dépôt : python3 pcvr/tools/generate_coeur_v63.py [textures | images | icones]
"""
from pathlib import Path
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_carene_v59 as gc  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "coeur"
FONTS = ROOT / "www" / "assets" / "fonts"
rng = np.random.default_rng(6363)
gc.rng = np.random.default_rng(6364)
tile_noise = gc.tile_noise


def save_rgb(arr, name):
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGB").save(OUT / name, optimize=True)
    print("coeur/" + name)


def save_img(img, name):
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / name, optimize=True)
    print("coeur/" + name)


def save_n(h, strength, name):
    OUT.mkdir(parents=True, exist_ok=True)
    gc.normal_map(h, strength).save(OUT / name, optimize=True)
    print("coeur/" + name)


def font(name, size):
    return ImageFont.truetype(str(FONTS / name), size)


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def speckle(S, density, blur=0.6, seed=0):
    """Grains isolés (minéraux, sable) : 1 sur les grains, 0 ailleurs."""
    r = np.random.default_rng(seed)
    a = r.random((S, S)).astype(np.float32)
    img = Image.fromarray(((a < density) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(blur))
    return np.asarray(img, dtype=np.float32) / 255.0


def masonry(S, rows_h, wmin, wmax, seed):
    """Appareil de blocs (tuilable) : identifiant de bloc, distance au joint (px), coordonnées
    dans le bloc (u, v de 0 à 1) et rangée."""
    r = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    bid = np.zeros((S, S), np.int32)
    e = np.zeros((S, S), np.float32)
    u = np.zeros((S, S), np.float32)
    v = np.zeros((S, S), np.float32)
    top = 0.0
    for ri, h in enumerate(rows_h):
        y0, y1 = int(round(top)), int(round(top + h))
        top += h
        ws = []
        while sum(ws) < S:
            ws.append(r.uniform(wmin, wmax))
        ws = np.array(ws)
        ws *= S / ws.sum()
        cum = np.cumsum(ws)
        off = r.uniform(0, S)
        sl = slice(y0, y1)
        xr = np.mod(xx[sl] + off, S)
        idx = np.minimum(np.searchsorted(cum, xr, side="right"), len(cum) - 1)
        left = np.where(idx > 0, cum[np.maximum(idx - 1, 0)], 0.0)
        right = cum[idx]
        dx = np.minimum(xr - left, right - xr)
        dy = np.minimum(yy[sl] - y0 + 0.5, y1 - yy[sl] - 0.5)
        e[sl] = np.minimum(dx, dy)
        bid[sl] = ri * 1000 + idx
        u[sl] = (xr - left) / (right - left)
        v[sl] = (yy[sl] - y0) / max(1, (y1 - y0))
    return bid, e, u, v


def per_block(bid, seed, lo, hi):
    r = np.random.default_rng(seed)
    ids, inv = np.unique(bid, return_inverse=True)
    vals = r.uniform(lo, hi, len(ids)).astype(np.float32)
    return vals[inv].reshape(bid.shape)


def worley(S, n, seed):
    """Bruit cellulaire tuilable : distance au point le plus proche, au second, et la cellule."""
    r = np.random.default_rng(seed)
    pts = r.random((n, n, 2)).astype(np.float32)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    xx = xx / S * n
    yy = yy / S * n
    cx = np.floor(xx).astype(int)
    cy = np.floor(yy).astype(int)
    d1 = np.full((S, S), 9.0, np.float32)
    d2 = np.full((S, S), 9.0, np.float32)
    cid = np.zeros((S, S), np.int32)
    for oy in (-1, 0, 1):
        for ox in (-1, 0, 1):
            nx = (cx + ox) % n
            ny = (cy + oy) % n
            px = cx + ox + pts[ny, nx, 0]
            py = cy + oy + pts[ny, nx, 1]
            d = np.hypot(xx - px, yy - py)
            closer = d < d1
            d2 = np.where(closer, d1, np.minimum(d2, d))
            cid = np.where(closer, ny * n + nx, cid)
            d1 = np.where(closer, d, d1)
    return d1, d2, cid


# =================================================================== matériaux tuilables

def pierre():
    """Granit gris appareillé : quatre rangées de grands blocs (une tuile = 3 m), faces piquetées,
    arêtes épaufrées, grains noirs (biotite), blancs (feldspath) et quelques roses ; joints de
    mortier en retrait ; coulures d'humidité sous terre."""
    S = 1024
    bid, e, u, v = masonry(S, [256] * 4, 300, 620, 631)
    mot = tile_noise(S, S, ox=(4, 8, 16, 32), falloff=0.6)
    fine = tile_noise(S, S, ox=(64, 128, 256), falloff=0.8)
    chip = tile_noise(S, S, ox=(16, 32, 64, 128), falloff=0.7)
    streak = tile_noise(S, S, ox=(16, 32, 64), oy=(2, 4, 8), falloff=0.7)
    tone = per_block(bid, 632, 0.86, 1.1)
    warm = per_block(bid, 633, -0.025, 0.03)
    e2 = e - np.clip(chip - 0.55, 0, 1) * 34.0
    face = smooth(1.0, 12.0, e2)
    base = np.array([0.55, 0.54, 0.52], np.float32)[None, None, :] * tone[..., None]
    base = base + warm[..., None] * np.array([1.0, 0.4, -0.6], np.float32)
    base *= (0.82 + 0.36 * mot[..., None])
    blk = speckle(S, 0.05, 0.7, 634)
    wht = speckle(S, 0.035, 0.6, 635)
    pnk = speckle(S, 0.012, 0.9, 636) * (per_block(bid, 637, 0, 1) > 0.6)
    col = base * (1 - 0.55 * blk[..., None])
    col = col + wht[..., None] * np.array([0.3, 0.3, 0.28]) + pnk[..., None] * np.array([0.22, 0.08, 0.04])
    col *= (0.9 + 0.2 * fine[..., None])
    # coulures sombres (l'eau suinte sous les joints)
    wet = np.clip((streak - 0.6) * 2.0, 0, 1) * smooth(0.3, 1.0, v)
    col *= (1 - 0.14 * wet[..., None])
    pits = speckle(S, 0.006, 1.4, 638)
    col *= (1 - 0.35 * pits[..., None])
    # arêtes plus claires (usées), creux épaufrés plus sombres
    col *= (0.72 + 0.28 * face[..., None])
    mortar = np.array([0.36, 0.355, 0.34], np.float32)[None, None, :] * (0.8 + 0.4 * fine[..., None])
    m = smooth(2.5, 4.5, e2)[..., None]
    col = col * m + mortar * (1 - m)
    h = face * (0.75 + 0.25 * mot) + fine * 0.12 + np.clip(chip - 0.5, 0, 1) * 0.15 * face - pits * 0.2
    save_rgb(col, "pierre.png")
    save_n(h, 4.0, "pierre_n.png")


def dalles():
    """Dalles de calcaire gris-beige : trois rangées de hauteurs différentes, dalles de largeurs
    diverses, polies par les pas au milieu, fissures, poussière noire dans les joints."""
    S = 1024
    bid, e, u, v = masonry(S, [380, 300, 344], 300, 560, 641)
    mot = tile_noise(S, S, ox=(4, 8, 16, 32), falloff=0.6)
    fine = tile_noise(S, S, ox=(64, 128, 256), falloff=0.75)
    fossil = speckle(S, 0.004, 1.6, 642)
    tone = per_block(bid, 643, 0.86, 1.1)
    tilt = per_block(bid, 644, -0.06, 0.06)
    base = np.array([0.66, 0.62, 0.55], np.float32)[None, None, :] * tone[..., None]
    base *= (0.85 + 0.3 * mot[..., None]) * (0.94 + 0.12 * fine[..., None])
    col = base * (1 - 0.25 * fossil[..., None])
    # fissures : quelques lignes brisées
    crack = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(crack)
    r = np.random.default_rng(645)
    for _ in range(7):
        x, y = r.uniform(0, S), r.uniform(0, S)
        a = r.uniform(0, math.tau)
        pts = [(x, y)]
        for k in range(r.integers(6, 14)):
            a += r.normal(0, 0.5)
            x += math.cos(a) * r.uniform(10, 30)
            y += math.sin(a) * r.uniform(10, 30)
            pts.append((x, y))
        for dx in (-S, 0, S):
            for dy in (-S, 0, S):
                d.line([(p[0] + dx, p[1] + dy) for p in pts], fill=255, width=1)
    cr = np.asarray(crack.filter(ImageFilter.GaussianBlur(0.7)), dtype=np.float32) / 255.0
    col *= (1 - 0.35 * cr[..., None])
    face = smooth(1.5, 7.0, e)
    col *= (0.7 + 0.3 * face[..., None])
    grime = np.array([0.18, 0.16, 0.14], np.float32)[None, None, :]
    m = smooth(2.0, 4.0, e)[..., None]
    col = col * m + grime * (1 - m)
    h = face * (0.8 + tilt * (u - 0.5) * 4) + mot * 0.12 + fine * 0.06 - cr * 0.3
    save_rgb(col, "dalles.png")
    save_n(h, 3.0, "dalles_n.png")


def gres():
    """Grès ocre-rose en blocs : lits de sédiment fins et ondulés, à peine marqués ; grain de
    sable ; alvéoles creusées par le vent (taffonis) ; arêtes arrondies ; taches de fer."""
    S = 1024
    bid, e, u, v = masonry(S, [205, 205, 204, 205, 205], 260, 520, 651)
    mot = tile_noise(S, S, ox=(4, 8, 16, 32), falloff=0.62)
    big = tile_noise(S, S, ox=(2, 4, 8), falloff=0.6)
    fine = tile_noise(S, S, ox=(128, 256), falloff=0.8)
    warp = tile_noise(S, S, ox=(4, 8, 16), oy=(2, 4, 8), falloff=0.6)
    yy = np.mgrid[0:S, 0:S][0].astype(np.float32)
    tone = per_block(bid, 652, 0.9, 1.08)
    hue = per_block(bid, 653, -1, 1)
    phase = per_block(bid, 655, 0, 6.28)
    band = 0.5 + 0.5 * np.sin(yy / S * math.tau * 14 + warp * 9.0 + phase)
    base = np.array([0.74, 0.58, 0.43], np.float32)[None, None, :] * tone[..., None]
    base = base + hue[..., None] * np.array([0.03, 0.005, -0.02])
    base *= (0.94 + 0.06 * band[..., None]) * (0.84 + 0.26 * mot[..., None]) * (0.92 + 0.12 * big[..., None])
    grains = speckle(S, 0.12, 0.5, 654)
    darkg = speckle(S, 0.03, 0.5, 656)
    col = base * (0.95 + 0.1 * grains[..., None]) * (1 - 0.18 * darkg[..., None]) * (0.95 + 0.1 * fine[..., None])
    # taches de fer (oxydes), en auréoles
    rust = np.clip((tile_noise(S, S, ox=(8, 16, 32), falloff=0.6) - 0.72) * 3, 0, 1)
    col = col * (1 - 0.18 * rust[..., None]) + rust[..., None] * np.array([0.12, 0.05, 0.01])
    # taffonis : petites alvéoles sombres
    d1, d2, cid = worley(S, 18, 657)
    rs = np.random.default_rng(658)
    keep = (rs.random(18 * 18) < 0.07)[cid]
    size = rs.uniform(0.12, 0.3, 18 * 18)[cid]
    alv = smooth(size, size * 0.3, d1 * (1.0 + 0.6 * (mot - 0.5))) * keep
    alv = np.asarray(Image.fromarray((alv * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(2.0)), np.float32) / 255.0
    col *= (1 - 0.3 * alv[..., None])
    face = smooth(0.0, 20.0, e + (mot - 0.5) * 14)
    col *= (0.7 + 0.3 * face[..., None])
    sandj = np.array([0.62, 0.5, 0.37], np.float32)[None, None, :] * (0.85 + 0.3 * fine[..., None])
    m = smooth(1.5, 3.5, e)[..., None]
    col = col * m + sandj * (1 - m)
    h = np.sqrt(face) * 0.8 + band * 0.04 + mot * 0.12 + fine * 0.05 + grains * 0.03 - alv * 0.35
    save_rgb(col, "gres.png")
    save_n(h, 3.5, "gres_n.png")


def corail():
    """Pierre des Marées : blocs gris-vert mouillés, recouverts par endroits d'une croûte
    d'algues calcaires (rose-lilas, mate, bosselée), de quelques têtes de corail cerveau
    beiges, d'éponges orangées, de grappes de balanes et d'algues vertes sous les joints."""
    S = 1024
    bid, e, u, v = masonry(S, [256] * 4, 300, 600, 661)
    mot = tile_noise(S, S, ox=(4, 8, 16, 32), falloff=0.6)
    fine = tile_noise(S, S, ox=(64, 128, 256), falloff=0.75)
    tone = per_block(bid, 662, 0.88, 1.08)
    stone = np.array([0.33, 0.38, 0.38], np.float32)[None, None, :] * tone[..., None] * (0.82 + 0.36 * mot[..., None])
    stone *= (0.94 + 0.12 * fine[..., None])
    face = smooth(1.0, 10.0, e)
    col = stone * (0.72 + 0.28 * face[..., None])
    h = face * 0.6 + mot * 0.1 + fine * 0.05
    r = np.random.default_rng(664)
    # croûte d'algues calcaires (plaques irrégulières, bosselées)
    cover = tile_noise(S, S, ox=(4, 8, 16, 32), falloff=0.62)
    bumps = tile_noise(S, S, ox=(64, 128), falloff=0.7)
    crust = smooth(0.58, 0.66, cover) * 0.92
    ccol = np.array([0.54, 0.47, 0.5], np.float32)[None, None, :] * (0.78 + 0.3 * bumps[..., None]) * (0.9 + 0.2 * mot[..., None])
    edge_w = smooth(0.58, 0.61, cover) * (1 - smooth(0.61, 0.68, cover))
    ccol = ccol + edge_w[..., None] * np.array([0.12, 0.1, 0.1])
    col = col * (1 - crust[..., None]) + ccol * crust[..., None]
    h = h + crust * (0.25 + 0.2 * bumps)
    # têtes de corail cerveau (rares) et éponges
    d1, d2, cid = worley(S, 7, 663)
    kind = r.integers(0, 6, 49)[cid]
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    warp = tile_noise(S, S, ox=(16, 32, 64), falloff=0.6)
    grooves = 0.5 + 0.5 * np.sin(xx * 0.11 + yy * 0.07 + warp * 46.0)
    kind = np.where(r.random(49)[cid] < 0.5, kind, 9)
    head = smooth(0.28, 0.16, d1 * (1.0 + 0.5 * (mot - 0.5))) * (kind == 0)
    brain = np.array([0.58, 0.55, 0.45], np.float32)[None, None, :] * (0.7 + 0.3 * grooves[..., None]) * (0.85 + 0.2 * mot[..., None])
    col = col * (1 - head[..., None]) + brain * head[..., None]
    h = h + head * (0.55 + 0.2 * grooves)
    pores = speckle(S, 0.2, 0.8, 665)
    sponge = smooth(0.18, 0.1, d1 * (1.0 + 0.6 * (mot - 0.5))) * (kind == 1)
    sp = np.array([0.6, 0.4, 0.24], np.float32)[None, None, :] * (0.75 + 0.25 * (1 - pores[..., None]))
    col = col * (1 - sponge[..., None]) + sp * sponge[..., None]
    h = h + sponge * (0.4 - 0.2 * pores)
    # balanes, en grappes près des joints
    bar = Image.new("L", (S, S), 0)
    hole = Image.new("L", (S, S), 0)
    db = ImageDraw.Draw(bar)
    dh = ImageDraw.Draw(hole)
    for _ in range(26):
        cx, cy = r.uniform(0, S), float(r.integers(0, 4) * 256 + r.choice([r.uniform(4, 30), r.uniform(226, 252)]))
        for _k in range(r.integers(6, 16)):
            x, y, rr = cx + r.normal(0, 18), cy + r.normal(0, 8), r.uniform(3, 7)
            for ox in (-S, 0, S):
                for oy in (-S, 0, S):
                    db.ellipse((x + ox - rr, y + oy - rr, x + ox + rr, y + oy + rr), fill=255)
                    dh.ellipse((x + ox - rr * 0.35, y + oy - rr * 0.35, x + ox + rr * 0.35, y + oy + rr * 0.35), fill=255)
    b = np.asarray(bar.filter(ImageFilter.GaussianBlur(1.0)), np.float32) / 255.0
    ho = np.asarray(hole.filter(ImageFilter.GaussianBlur(0.7)), np.float32) / 255.0
    col = col * (1 - b[..., None]) + np.array([0.7, 0.69, 0.64]) * (0.85 + 0.2 * fine[..., None]) * b[..., None]
    col *= (1 - 0.65 * ho[..., None])
    h = h + b * 0.3 - ho * 0.3
    # algues vertes qui pendent sous les joints
    streak = tile_noise(S, S, ox=(32, 64, 128), oy=(4, 8, 16), falloff=0.7)
    alg = np.clip((streak - 0.48) * 3, 0, 1) * smooth(0.35, 0.0, v) * (1 - crust) * (1 - head)
    col = col * (1 - 0.65 * alg[..., None]) + alg[..., None] * np.array([0.07, 0.17, 0.09])
    mortar = np.array([0.2, 0.24, 0.23], np.float32)[None, None, :] * (0.8 + 0.4 * fine[..., None])
    m = np.clip(smooth(2.0, 4.0, e)[..., None] + (crust + head)[..., None], 0, 1)
    col = col * m + mortar * (1 - m)
    save_rgb(col, "corail.png")
    save_n(h, 3.5, "corail_n.png")


def ardoise():
    """Ardoise bleu-nuit en blocs minces, feuilletée : fines lames horizontales, éclats en
    gradins aux arêtes, reflets satinés, quelques veines de quartz."""
    S = 512
    bid, e, u, v = masonry(S, [86, 84, 86, 85, 86, 85], 140, 300, 671)
    mot = tile_noise(S, S, ox=(4, 8, 16, 32), falloff=0.6)
    lam = tile_noise(S, S, ox=(2, 4, 8), oy=(64, 128, 256), falloff=0.7)
    fine = tile_noise(S, S, ox=(64, 128, 256), falloff=0.8)
    tone = per_block(bid, 672, 0.85, 1.12)
    base = np.array([0.34, 0.38, 0.45], np.float32)[None, None, :] * tone[..., None]
    base *= (0.86 + 0.26 * mot[..., None]) * (0.92 + 0.14 * lam[..., None])
    steps = np.floor((tile_noise(S, S, ox=(8, 16, 32), falloff=0.6)) * 4) / 4
    col = base * (0.9 + 0.2 * steps[..., None]) * (0.96 + 0.08 * fine[..., None])
    vein = Image.new("L", (S, S), 0)
    dv = ImageDraw.Draw(vein)
    r = np.random.default_rng(673)
    for _ in range(5):
        x, y = r.uniform(0, S), r.uniform(0, S)
        pts = [(x, y)]
        for _k in range(8):
            x += r.uniform(8, 30)
            y += r.normal(0, 8)
            pts.append((x, y))
        for ox in (-S, 0, S):
            dv.line([(p[0] + ox, p[1]) for p in pts], fill=255, width=1)
    vn = np.asarray(vein.filter(ImageFilter.GaussianBlur(0.6)), np.float32) / 255.0
    col = col * (1 - vn[..., None] * 0.6) + vn[..., None] * np.array([0.5, 0.52, 0.55]) * 0.6
    face = smooth(0.5, 6.0, e + (mot - 0.5) * 5)
    col *= (0.7 + 0.3 * face[..., None])
    m = smooth(1.5, 3.0, e)[..., None]
    col = col * m + np.array([0.08, 0.09, 0.11]) * (1 - m)
    h = face * 0.7 + lam * 0.12 + steps * 0.2
    save_rgb(col, "ardoise.png")
    save_n(h, 3.0, "ardoise_n.png")


def tapis():
    """Tapis roulant : lattes d'acier sombres rivetées sur une bande de cuir huilé."""
    S = 512
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    fine = tile_noise(S, S, ox=(64, 128, 256), falloff=0.8)
    mot = tile_noise(S, S, ox=(4, 8, 16), falloff=0.6)
    slat = np.mod(yy, 64.0)
    edge = np.minimum(slat, 64 - slat)
    face = smooth(2.0, 7.0, edge)
    steel = np.array([0.3, 0.3, 0.32], np.float32)[None, None, :] * (0.75 + 0.5 * mot[..., None]) * (0.9 + 0.2 * fine[..., None])
    rust = np.clip((tile_noise(S, S, ox=(8, 16, 32), falloff=0.6) - 0.62) * 3, 0, 1)
    steel = steel * (1 - rust[..., None] * 0.4) + rust[..., None] * np.array([0.2, 0.09, 0.03])
    col = steel * (0.55 + 0.45 * face[..., None])
    rivet = np.zeros((S, S), np.float32)
    for cx in (40, 216, 296, 472):
        d = np.hypot(np.mod(xx - cx + S / 2, S) - S / 2, slat - 32)
        rivet = np.maximum(rivet, smooth(7, 4, d))
    col = col * (1 - rivet[..., None]) + rivet[..., None] * np.array([0.55, 0.52, 0.45])
    gap = 1 - face
    col = col * (1 - gap[..., None] * 0.6) + gap[..., None] * np.array([0.08, 0.05, 0.03])
    save_rgb(col, "tapis.png")


def textures():
    pierre()
    dalles()
    gres()
    corail()
    ardoise()
    tapis()


# =================================================================== fresques, gravures

def plaster(W, H, seed, base=(0.86, 0.79, 0.64)):
    r = np.random.default_rng(seed)
    gc.rng = np.random.default_rng(seed + 1)
    n = tile_noise(max(W, H), max(W, H), ox=(4, 8, 16, 32, 64), falloff=0.6)[:H, :W]
    f = tile_noise(max(W, H), max(W, H), ox=(128, 256), falloff=0.8)[:H, :W]
    col = np.array(base, np.float32)[None, None, :] * (0.88 + 0.2 * n[..., None]) * (0.95 + 0.1 * f[..., None])
    return col, n, r


def age_fresco(paint, W, H, seed, loss=0.12, fade=0.25):
    """Vieillit une fresque : enduit, écailles (la peinture tombe, l'enduit apparaît), craquelures,
    couleurs passées, taches d'humidité, coins assombris."""
    base, n, r = plaster(W, H, seed)
    pa = np.asarray(paint, dtype=np.float32) / 255.0
    rgb = pa[..., :3]
    a = pa[..., 3:4]
    pal = rgb * (1 - fade) + base * fade
    chip = tile_noise(max(W, H), max(W, H), ox=(8, 16, 32, 64, 128), falloff=0.65)[:H, :W]
    keep = np.clip(1 - smooth(1 - loss - 0.03, 1 - loss + 0.03, chip)[..., None], 0, 1)
    col = base * (1 - a * keep) + pal * a * keep
    col *= (0.92 + 0.12 * n[..., None])
    cr = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(cr)
    for _ in range(int(W * H / 22000)):
        x, y = r.uniform(0, W), r.uniform(0, H)
        ang = r.uniform(0, math.tau)
        pts = [(x, y)]
        for k in range(r.integers(4, 12)):
            ang += r.normal(0, 0.6)
            x += math.cos(ang) * r.uniform(6, 22)
            y += math.sin(ang) * r.uniform(6, 22)
            pts.append((x, y))
        d.line(pts, fill=255, width=1)
    c = np.asarray(cr.filter(ImageFilter.GaussianBlur(0.6)), np.float32)[..., None] / 255.0
    col *= (1 - 0.45 * c)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    vig = 1 - 0.35 * (np.abs(xx / W - 0.5) * 2) ** 3 - 0.3 * (np.abs(yy / H - 0.5) * 2) ** 3
    damp = np.clip((tile_noise(max(W, H), max(W, H), ox=(2, 4, 8), falloff=0.6)[:H, :W] - 0.6) * 2, 0, 1)[..., None]
    col = col * vig[..., None] * (1 - 0.25 * damp)
    return Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB")


def _figure(d, x, y, s, body, head=(214, 170, 130), hat=None, ears=False, staff=False, veil=None, tail=None):
    """Une silhouette de fresque, de face : tête, buste, robe ou pantalon, bras ouverts."""
    if tail is not None:
        d.polygon([(x + s * 0.3, y + s * 1.6), (x + s * 1.0, y + s * 1.2), (x + s * 1.1, y + s * 1.45), (x + s * 0.45, y + s * 1.85)], fill=tail)
        d.polygon([(x + s * 0.95, y + s * 1.2), (x + s * 1.12, y + s * 1.12), (x + s * 1.1, y + s * 1.45)], fill=(240, 236, 226))
    d.polygon([(x - s * 0.38, y + s * 0.62), (x + s * 0.38, y + s * 0.62), (x + s * 0.55, y + s * 2.1), (x - s * 0.55, y + s * 2.1)], fill=body)
    d.rectangle((x - s * 0.36, y + s * 2.1, x - s * 0.12, y + s * 2.75), fill=tuple(int(c * 0.6) for c in body))
    d.rectangle((x + s * 0.12, y + s * 2.1, x + s * 0.36, y + s * 2.75), fill=tuple(int(c * 0.6) for c in body))
    if veil is not None:
        d.ellipse((x - s * 0.36, y - s * 0.1, x + s * 0.36, y + s * 0.66), fill=veil)
    d.ellipse((x - s * 0.27, y, x + s * 0.27, y + s * 0.56), fill=head)
    if hat is not None:
        d.chord((x - s * 0.3, y - s * 0.08, x + s * 0.3, y + s * 0.4), 180, 360, fill=hat)
    if ears:
        for sx in (-1, 1):
            d.polygon([(x + sx * s * 0.12, y + s * 0.06), (x + sx * s * 0.32, y - s * 0.34), (x + sx * s * 0.3, y + s * 0.16)], fill=tail or head)
    d.ellipse((x - s * 0.12, y + s * 0.22, x - s * 0.06, y + s * 0.28), fill=(40, 30, 26))
    d.ellipse((x + s * 0.06, y + s * 0.22, x + s * 0.12, y + s * 0.28), fill=(40, 30, 26))
    if staff:
        d.line((x - s * 0.9, y - s * 0.3, x - s * 0.8, y + s * 2.75), fill=(110, 72, 40), width=max(2, int(s * 0.08)))
        d.arc((x - s * 1.15, y - s * 0.55, x - s * 0.75, y - s * 0.15), 180, 360, fill=(110, 72, 40), width=max(2, int(s * 0.08)))


def fresque_peuples():
    """Le vestibule : les quatre peuples main dans la main devant la grande porte ; au-dessus,
    le cœur de pierre rouge, et ses quatre rayons vers les quatre cristaux."""
    W, H = 1280, 576
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # ciel ocre, montagne grise
    d.rectangle((0, 0, W, H), fill=(196, 160, 106, 255))
    d.polygon([(0, 420), (240, 230), (430, 300), (640, 120), (860, 290), (1060, 210), (1280, 400), (1280, 576), (0, 576)], fill=(120, 116, 112, 255))
    d.polygon([(560, 210), (640, 120), (720, 210)], fill=(150, 146, 140, 255))
    # la grande porte
    d.rectangle((520, 250, 760, 520), fill=(92, 86, 80, 255))
    d.pieslice((520, 150, 760, 350), 180, 360, fill=(92, 86, 80, 255))
    d.ellipse((585, 300, 695, 410), outline=(214, 170, 70, 255), width=8)
    cols = [(90, 230, 220), (250, 150, 60), (240, 200, 90), (190, 210, 255)]
    for k, (ox, oy) in enumerate(((0, -42), (-42, 0), (0, 42), (42, 0))):
        d.ellipse((640 + ox - 14, 355 + oy - 14, 640 + ox + 14, 355 + oy + 14), fill=cols[k] + (255,))
    # le cœur de pierre et ses rayons
    d.polygon([(640, 20), (690, 80), (640, 150), (590, 80)], fill=(190, 40, 30, 255))
    d.polygon([(640, 20), (690, 80), (640, 80)], fill=(230, 80, 60, 255))
    for k, cx in enumerate((150, 430, 850, 1130)):
        d.line((640, 80, cx, 60), fill=cols[k] + (255,), width=5)
        d.polygon([(cx, 30), (cx + 18, 60), (cx, 92), (cx - 18, 60)], fill=cols[k] + (255,))
    # les quatre peuples, main dans la main
    s = 70
    xs = [300, 470, 810, 980]
    _figure(d, xs[0], 330, s, (60, 90, 160), hat=(190, 40, 40))
    for k in range(5):
        d.line((xs[0] - s * 0.38, 330 + s * (0.8 + k * 0.25), xs[0] + s * 0.38, 330 + s * (0.8 + k * 0.25)), fill=(230, 230, 230), width=4)
    _figure(d, xs[1], 330, s, (220, 120, 50), head=(196, 140, 96), veil=(240, 220, 170))
    _figure(d, xs[2], 330, s, (120, 84, 50), hat=(80, 60, 40), staff=True)
    _figure(d, xs[3], 330, s, (70, 130, 80), head=(222, 180, 140), ears=True, tail=(210, 110, 50))
    hand_y = 330 + s * 1.15
    for k in range(3):
        a, b = xs[k] + s * 0.4, xs[k + 1] - s * 0.4
        if k == 1:
            d.line((a, hand_y, 560, hand_y + 10), fill=(214, 170, 130), width=10)
            d.line((720, hand_y + 10, b, hand_y), fill=(214, 170, 130), width=10)
            continue
        d.line((a, hand_y, b, hand_y), fill=(214, 170, 130), width=10)
    d.line((xs[0] - s * 0.4, hand_y, xs[0] - s * 1.0, hand_y + s * 0.6), fill=(214, 170, 130), width=10)
    d.line((xs[3] + s * 0.4, hand_y, xs[3] + s * 1.0, hand_y + s * 0.6), fill=(214, 170, 130), width=10)
    # frise du bas
    for x in range(0, W, 64):
        d.polygon([(x, 576), (x + 32, 540), (x + 64, 576)], fill=(150, 60, 40, 255))
    d.rectangle((0, 528, W, 536), fill=(150, 60, 40, 255))
    save_img(age_fresco(img, W, H, 681, loss=0.1, fade=0.22), "fresque_peuples.png")


def fresque_bergerie():
    """Le tombeau : un berger et ses moutons au pied d'une montagne grise, une grotte, et dans la
    grotte une roue dentée de bronze ; la crête du Cœur-de-Pierre vue du nord."""
    W, H = 1024, 512
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, W, H), fill=(214, 186, 130, 255))
    d.polygon([(0, 330), (180, 160), (300, 220), (470, 60), (640, 210), (780, 120), (1024, 300), (1024, 512), (0, 512)], fill=(128, 124, 118, 255))
    d.polygon([(430, 100), (470, 60), (510, 100), (490, 120), (450, 120)], fill=(236, 236, 232, 255))
    d.rectangle((0, 380, W, 512), fill=(130, 150, 80, 255))
    # la grotte et sa roue
    d.ellipse((600, 250, 800, 420), fill=(48, 40, 36, 255))
    d.rectangle((600, 335, 800, 420), fill=(48, 40, 36, 255))
    cx, cy = 700, 340
    for k in range(12):
        a = k / 12 * math.tau
        d.polygon([(cx + math.cos(a - 0.12) * 52, cy + math.sin(a - 0.12) * 52), (cx + math.cos(a - 0.08) * 66, cy + math.sin(a - 0.08) * 66),
                   (cx + math.cos(a + 0.08) * 66, cy + math.sin(a + 0.08) * 66), (cx + math.cos(a + 0.12) * 52, cy + math.sin(a + 0.12) * 52)], fill=(190, 130, 60, 255))
    d.ellipse((cx - 54, cy - 54, cx + 54, cy + 54), fill=(190, 130, 60, 255))
    d.ellipse((cx - 16, cy - 16, cx + 16, cy + 16), fill=(120, 80, 36, 255))
    # le berger et les moutons
    _figure(d, 240, 300, 46, (120, 84, 50), hat=(80, 60, 40), staff=True)
    r = np.random.default_rng(682)
    for k in range(7):
        x = 330 + k * 46 + r.uniform(-10, 10)
        y = 410 + r.uniform(-14, 14)
        d.ellipse((x - 24, y - 16, x + 24, y + 16), fill=(240, 236, 226, 255))
        d.ellipse((x + 16, y - 14, x + 34, y + 2), fill=(50, 44, 40, 255))
        for lx in (-12, 10):
            d.line((x + lx, y + 12, x + lx, y + 28), fill=(50, 44, 40, 255), width=4)
    # le soleil, au nord (une étoile du nord), une boussole peinte
    d.ellipse((900, 40, 960, 100), outline=(150, 60, 40, 255), width=4)
    d.polygon([(930, 30), (938, 70), (930, 110), (922, 70)], fill=(150, 60, 40, 255))
    d.text((921, 4), "N", fill=(150, 60, 40, 255), font=font("Lora-Bold.ttf", 28))
    save_img(age_fresco(img, W, H, 683, loss=0.14, fade=0.25), "fresque_bergerie.png")


def fresque_mare():
    """La Bergerie : une mare entourée de grands arbres, une vanne de bronze sur son bord, et une
    pleine lune qui verse sa lumière jusqu'au fond de l'eau."""
    W, H = 832, 512
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, W, H), fill=(40, 52, 86, 255))
    for k in range(60):
        x, y = (k * 137) % W, (k * 71) % 220
        d.point((x, y), fill=(230, 230, 210, 255))
    d.ellipse((370, 40, 470, 140), fill=(244, 238, 210, 255))
    d.polygon([(400, 140), (440, 140), (500, 420), (340, 420)], fill=(150, 170, 200, 140))
    for x in (60, 180, 650, 770):
        d.rectangle((x - 14, 150, x + 14, 400), fill=(70, 50, 40, 255))
        d.ellipse((x - 90, 40, x + 90, 230), fill=(34, 74, 52, 255))
    d.rectangle((0, 380, W, H), fill=(52, 70, 40, 255))
    d.ellipse((160, 360, 680, 480), fill=(44, 80, 110, 255))
    d.ellipse((380, 405, 460, 435), fill=(220, 220, 200, 255))
    d.rectangle((640, 340, 700, 420), fill=(150, 110, 50, 255))
    d.ellipse((646, 330, 694, 378), outline=(200, 150, 70, 255), width=8)
    save_img(age_fresco(img, W, H, 684, loss=0.12, fade=0.2), "fresque_mare.png")


def chant_berger():
    """La planche du chant du berger : du bois gris, des moutons peints à la chaux, en trois
    scènes (la crête au soleil, la vallée, la bergerie au feu)."""
    W, H = 880, 400
    gc.rng = np.random.default_rng(691)
    grain = gc.wood_grain(W, H, along_x=True) if hasattr(gc, "wood_grain") else tile_noise(W, W)[:H, :W]
    if grain.ndim == 3:
        grain = grain[..., 0]
    base = np.array([0.5, 0.44, 0.36], np.float32)[None, None, :] * (0.75 + 0.35 * grain[..., None])
    for y in (130, 265):
        base[y - 2:y + 2] *= 0.4
    img = Image.fromarray((np.clip(base, 0, 1) * 255).astype(np.uint8), "RGB").convert("RGBA")
    paint = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(paint)
    chalk = (238, 234, 222, 235)

    def sheep(x, y, s=1.0):
        d.ellipse((x - 26 * s, y - 16 * s, x + 26 * s, y + 16 * s), outline=chalk, width=4)
        d.ellipse((x + 18 * s, y - 16 * s, x + 36 * s, y + 2 * s), fill=chalk)
        for lx in (-12, 10):
            d.line((x + lx * s, y + 14 * s, x + lx * s, y + 28 * s), fill=chalk, width=4)

    # la crête au soleil : trois moutons
    d.line((40, 110, 140, 60, 230, 90, 280, 70), fill=chalk, width=4)
    for k in range(3):
        sheep(80 + k * 70, 50 + (k == 1) * -10)
    d.ellipse((240, 10, 280, 50), outline=chalk, width=4)
    for k in range(8):
        a = k / 8 * math.tau
        d.line((260 + math.cos(a) * 26, 30 + math.sin(a) * 26, 260 + math.cos(a) * 36, 30 + math.sin(a) * 36), fill=chalk, width=3)
    # la vallée : un seul, qui boude
    d.line((330, 60, 430, 120, 530, 60), fill=chalk, width=4)
    sheep(430, 96, 0.9)
    for k in range(4):
        d.line((380 + k * 18, 124, 386 + k * 18, 112), fill=chalk, width=3)
    # la bergerie : deux, près du feu
    d.polygon([(600, 110), (690, 40), (780, 110)], outline=chalk, width=4)
    d.rectangle((615, 110, 765, 125), outline=chalk, width=3)
    sheep(640, 95, 0.75)
    sheep(705, 95, 0.75)
    d.polygon([(745, 100), (755, 80), (765, 100)], fill=(240, 150, 60, 230))
    # les paroles
    f = font("Lora-Italic.ttf", 25)
    lines = ["Trois moutons sur la crête, au soleil du matin ;", "un seul dans la vallée, qui boude dans le thym ;",
             "deux à la bergerie, qui dorment près du feu.", "Compte-les dans l'ordre, et le vent t'ouvrira."]
    for k, t in enumerate(lines):
        d.text((40, 150 + k * 56), t, fill=chalk, font=f)
    paint = paint.filter(ImageFilter.GaussianBlur(0.6))
    a = np.asarray(paint, np.float32)
    wear = tile_noise(1024, 1024, ox=(8, 16, 32, 64), falloff=0.6)[:H, :W]
    a[..., 3] *= np.clip(0.4 + wear * 0.9, 0, 1)
    paint = Image.fromarray(a.astype(np.uint8), "RGBA")
    img.alpha_composite(paint)
    save_img(img.convert("RGB"), "chant_berger.png")


def stele_soleil():
    """La stèle de l'Aile des Sables : grès, un soleil gravé au centre, ses quatre places autour
    (levant à l'est, midi au sud, couchant à l'ouest, sommeil au nord), le texte gravé."""
    W, H = 768, 512
    gc.rng = np.random.default_rng(692)
    n = tile_noise(768, 768, ox=(4, 8, 16, 32, 64), falloff=0.6)[:H, :W]
    f2 = tile_noise(768, 768, ox=(128, 256), falloff=0.8)[:H, :W]
    base = np.array([0.76, 0.6, 0.42], np.float32)[None, None, :] * (0.82 + 0.26 * n[..., None]) * (0.92 + 0.16 * f2[..., None])
    eng = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(eng)
    cx, cy = 384, 190
    d.ellipse((cx - 60, cy - 60, cx + 60, cy + 60), outline=255, width=8)
    for k in range(12):
        a = k / 12 * math.tau
        d.line((cx + math.cos(a) * 74, cy + math.sin(a) * 74, cx + math.cos(a) * 100, cy + math.sin(a) * 100), fill=255, width=6)
    f = font("Lora-Bold.ttf", 34)
    for t, (x, y) in (("E", (cx + 150, cy - 20)), ("S", (cx - 10, cy + 112)), ("O", (cx - 180, cy - 20)), ("N", (cx - 12, cy - 160))):
        d.text((x, y), t, fill=255, font=f)
    d.arc((cx + 120, cy - 70, cx + 210, cy + 10), 180, 360, fill=255, width=5)
    d.arc((cx - 210, cy - 70, cx - 120, cy + 10), 180, 360, fill=255, width=5)
    d.ellipse((cx + 30, cy - 158, cx + 66, cy - 122), outline=255, width=5)
    d.ellipse((cx + 42, cy - 164, cx + 76, cy - 130), fill=0)
    fi = font("Lora-Italic.ttf", 23)
    lines = ["Je me lève à l'est, je brûle au sud,", "je me couche à l'ouest, et je dors au nord.", "Rallume ma course, et la porte s'ouvrira."]
    for k, t in enumerate(lines):
        w = d.textlength(t, font=fi)
        d.text((W / 2 - w / 2, 365 + k * 40), t, fill=255, font=fi)
    e = np.asarray(eng.filter(ImageFilter.GaussianBlur(1.0)), np.float32) / 255.0
    sh = np.asarray(eng.filter(ImageFilter.GaussianBlur(1.0)).transform((W, H), Image.AFFINE, (1, 0, -2, 0, 1, -2)), np.float32) / 255.0
    col = base * (1 - 0.45 * e[..., None]) + np.clip(sh - e, 0, 1)[..., None] * 0.08
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    border = np.minimum(np.minimum(xx, W - xx), np.minimum(yy, H - yy))
    col *= (0.75 + 0.25 * smooth(0, 18, border))[..., None]
    save_rgb(col, "stele_soleil.png")


def _bronze_disc(S, seed, color=(0.62, 0.43, 0.22)):
    gc.rng = np.random.default_rng(seed)
    n = tile_noise(S, S, ox=(4, 8, 16, 32), falloff=0.6)
    f = tile_noise(S, S, ox=(64, 128), falloff=0.8)
    pat = np.clip((tile_noise(S, S, ox=(8, 16, 32), falloff=0.6) - 0.6) * 3, 0, 1)
    col = np.array(color, np.float32)[None, None, :] * (0.8 + 0.35 * n[..., None]) * (0.92 + 0.16 * f[..., None])
    col = col * (1 - pat[..., None] * 0.5) + pat[..., None] * np.array([0.2, 0.45, 0.38]) * 0.6
    return col


def _relief(col, mask_img, light=(1, 1), depth=0.35):
    """Applique un relief (masque blanc = en saillie) : arêtes éclairées en haut à gauche."""
    m = np.asarray(mask_img.filter(ImageFilter.GaussianBlur(1.5)), np.float32) / 255.0
    gy, gx = np.gradient(m)
    shade = np.clip(-(gx * light[0] + gy * light[1]) * 6.0, -1, 1)
    col = col * (1 + depth * m[..., None] * 0.25) + shade[..., None] * depth
    return col


def emblems():
    """Les médaillons de bronze au-dessus des portes des ailes : la vague, le soleil sur la dune,
    l'engrenage, le croissant de lune. Disque plein (UV du cylindre maison)."""
    S = 512
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    rr = np.hypot(xx - S / 2, yy - S / 2)
    for name, seed, draw in (("marees", 701, "vague"), ("sables", 702, "soleil"), ("rouages", 703, "roue"), ("lune", 704, "lune")):
        col = _bronze_disc(S, seed)
        m = Image.new("L", (S, S), 0)
        d = ImageDraw.Draw(m)
        d.ellipse((24, 24, S - 24, S - 24), outline=255, width=18)
        d.ellipse((60, 60, S - 60, S - 60), outline=255, width=5)
        c = S / 2
        if draw == "vague":
            for k in range(3):
                y = 210 + k * 60
                pts = [(x, y + math.sin(x / 40.0 + k) * 18) for x in range(110, 410, 6)]
                d.line(pts, fill=255, width=16)
            d.arc((170, 120, 330, 280), 200, 340, fill=255, width=16)
        elif draw == "soleil":
            d.ellipse((c - 70, c - 120, c + 70, c + 20), fill=255)
            for k in range(10):
                a = k / 10 * math.tau
                d.line((c + math.cos(a) * 90, c - 50 + math.sin(a) * 90, c + math.cos(a) * 130, c - 50 + math.sin(a) * 130), fill=255, width=12)
            d.chord((100, 290, 420, 470), 180, 360, fill=255)
        elif draw == "roue":
            for k in range(10):
                a = k / 10 * math.tau
                d.polygon([(c + math.cos(a - 0.17) * 110, c + math.sin(a - 0.17) * 110), (c + math.cos(a - 0.12) * 150, c + math.sin(a - 0.12) * 150),
                           (c + math.cos(a + 0.12) * 150, c + math.sin(a + 0.12) * 150), (c + math.cos(a + 0.17) * 110, c + math.sin(a + 0.17) * 110)], fill=255)
            d.ellipse((c - 115, c - 115, c + 115, c + 115), fill=255)
            d.ellipse((c - 45, c - 45, c + 45, c + 45), fill=0)
            for k in range(5):
                a = k / 5 * math.tau
                d.ellipse((c + math.cos(a) * 80 - 14, c + math.sin(a) * 80 - 14, c + math.cos(a) * 80 + 14, c + math.sin(a) * 80 + 14), fill=0)
        else:
            d.ellipse((c - 120, c - 120, c + 120, c + 120), fill=255)
            d.ellipse((c - 70, c - 140, c + 150, c + 80), fill=0)
            for (x, y) in ((340, 150), (380, 260), (300, 340)):
                d.polygon([(x, y - 18), (x + 6, y - 6), (x + 18, y), (x + 6, y + 6), (x, y + 18), (x - 6, y + 6), (x - 18, y), (x - 6, y - 6)], fill=255)
        col = _relief(col, m)
        rim = smooth(S / 2 - 8, S / 2 - 22, rr)
        col *= (0.55 + 0.45 * rim)[..., None]
        save_rgb(col, "emblem_%s.png" % name)


def _cap_disc(S, back, draw, seed):
    """Un disque pour CylinderMesh : la face avant est dans le quart inférieur gauche."""
    img = Image.new("RGB", (S, S), back)
    face = Image.new("RGB", (S // 2, S // 2), back)
    draw(face, seed)
    img.paste(face, (0, S // 2))
    return img


def anneau_tombeau():
    """Anneaux de grès de la porte du tombeau : six symboles gravés (l'étoile, la dune, le soleil,
    la lune, le palmier, le scarabée), le symbole k à k x 60° (sens inverse des aiguilles d'une
    montre) depuis le haut."""
    def draw(face, seed):
        F = face.size[0]
        gc.rng = np.random.default_rng(seed)
        n = tile_noise(F, F, ox=(4, 8, 16, 32), falloff=0.6)
        col = np.array([0.78, 0.62, 0.44], np.float32)[None, None, :] * (0.82 + 0.3 * n[..., None])
        m = Image.new("L", (F, F), 0)
        d = ImageDraw.Draw(m)
        c = F / 2
        d.ellipse((6, 6, F - 6, F - 6), outline=255, width=6)
        d.ellipse((c - 20, c - 20, c + 20, c + 20), outline=255, width=5)
        for k in range(6):
            a = math.radians(k * 60)
            sx, sy = c - math.sin(a) * F * 0.31, c - math.cos(a) * F * 0.31
            s = F * 0.085
            if k == 0:  # étoile
                pts = []
                for j in range(10):
                    rr = s if j % 2 == 0 else s * 0.45
                    aa = j / 10 * math.tau - math.pi / 2
                    pts.append((sx + math.cos(aa) * rr, sy + math.sin(aa) * rr))
                d.polygon(pts, fill=255)
            elif k == 1:  # dune
                d.chord((sx - s * 1.2, sy - s * 0.6, sx + s * 1.2, sy + s * 1.4), 180, 360, fill=255)
            elif k == 2:  # soleil
                d.ellipse((sx - s * 0.5, sy - s * 0.5, sx + s * 0.5, sy + s * 0.5), fill=255)
                for j in range(8):
                    aa = j / 8 * math.tau
                    d.line((sx + math.cos(aa) * s * 0.65, sy + math.sin(aa) * s * 0.65, sx + math.cos(aa) * s * 1.05, sy + math.sin(aa) * s * 1.05), fill=255, width=3)
            elif k == 3:  # lune
                d.ellipse((sx - s, sy - s, sx + s, sy + s), fill=255)
                d.ellipse((sx - s * 0.4, sy - s * 1.1, sx + s * 1.4, sy + s * 0.7), fill=0)
            elif k == 4:  # palmier
                d.line((sx, sy + s, sx + s * 0.2, sy - s * 0.4), fill=255, width=4)
                for aa in (-2.6, -2.0, -1.2, -0.5):
                    d.line((sx + s * 0.2, sy - s * 0.4, sx + s * 0.2 + math.cos(aa) * s, sy - s * 0.4 + math.sin(aa) * s * 0.7 + s * 0.3), fill=255, width=4)
            else:  # scarabée
                d.ellipse((sx - s * 0.5, sy - s * 0.6, sx + s * 0.5, sy + s * 0.8), fill=255)
                d.ellipse((sx - s * 0.3, sy - s * 0.95, sx + s * 0.3, sy - s * 0.5), fill=255)
                for j in (-1, 1):
                    for t in (-0.2, 0.2, 0.6):
                        d.line((sx + j * s * 0.4, sy + s * t, sx + j * s * 0.95, sy + s * (t + 0.25)), fill=255, width=2)
        e = np.asarray(m.filter(ImageFilter.GaussianBlur(0.8)), np.float32)[..., None] / 255.0
        col = col * (1 - 0.5 * e)
        face.paste(Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB"))
    save_img(_cap_disc(512, (176, 140, 100), draw, 711), "anneau_tombeau.png")


def roue_moutons():
    """Roues de bronze de la Bergerie : 1, 2, 3 ou 4 moutons, la valeur v à (v - 1) x 90°."""
    def draw(face, seed):
        F = face.size[0]
        col = _bronze_disc(F, seed)
        m = Image.new("L", (F, F), 0)
        d = ImageDraw.Draw(m)
        c = F / 2
        d.ellipse((6, 6, F - 6, F - 6), outline=255, width=7)
        d.ellipse((c - 16, c - 16, c + 16, c + 16), fill=255)
        for v in range(1, 5):
            a = math.radians((v - 1) * 90)
            sx, sy = c - math.sin(a) * F * 0.3, c - math.cos(a) * F * 0.3
            for j in range(v):
                off = (j - (v - 1) / 2) * F * 0.075
                px = sx + math.cos(a) * off
                py = sy - math.sin(a) * off
                s = F * 0.028
                d.ellipse((px - s, py - s * 0.7, px + s, py + s * 0.7), fill=255)
        col = _relief(col, m)
        face.paste(Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB"))
    save_img(_cap_disc(512, (150, 104, 56), draw, 712), "roue_moutons.png")


def phases_lune():
    """Cadrans d'argent de l'Aile de la Lune : nouvelle, croissante, pleine, décroissante ; la
    phase k à k x 90° depuis le haut."""
    def draw(face, seed):
        F = face.size[0]
        gc.rng = np.random.default_rng(seed)
        n = tile_noise(F, F, ox=(4, 8, 16), falloff=0.6)
        col = np.array([0.32, 0.34, 0.42], np.float32)[None, None, :] * (0.85 + 0.3 * n[..., None])
        img = Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB")
        d = ImageDraw.Draw(img)
        c = F / 2
        d.ellipse((5, 5, F - 5, F - 5), outline=(200, 205, 220), width=6)
        d.ellipse((c - 10, c - 10, c + 10, c + 10), fill=(200, 205, 220))
        silver = (228, 232, 244)
        dark = (40, 44, 60)
        for k in range(4):
            a = math.radians(k * 90)
            sx, sy = c - math.sin(a) * F * 0.3, c - math.cos(a) * F * 0.3
            s = F * 0.1
            d.ellipse((sx - s, sy - s, sx + s, sy + s), fill=dark, outline=silver, width=3)
            if k == 1:  # croissante (éclairée à droite)
                d.chord((sx - s, sy - s, sx + s, sy + s), 270, 90, fill=silver)
                d.ellipse((sx - s * 0.55, sy - s, sx + s * 0.55, sy + s), fill=dark)
            elif k == 2:
                d.ellipse((sx - s, sy - s, sx + s, sy + s), fill=silver)
            elif k == 3:  # décroissante (éclairée à gauche)
                d.chord((sx - s, sy - s, sx + s, sy + s), 90, 270, fill=silver)
                d.ellipse((sx - s * 0.55, sy - s, sx + s * 0.55, sy + s), fill=dark)
        face.paste(img)
    save_img(_cap_disc(512, (90, 96, 112), draw, 713), "phases_lune.png")


def rose_sceaux():
    """La rose des vents incrustée d'or et de pierres de couleur au sol de la Rose des Sceaux.
    Image vue de dessus : haut = nord (les Rouages), bas = sud (les Sables), gauche = ouest (les
    Marées), droite = est (la Lune). Transparente hors des incrustations."""
    S = 1024
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = S / 2
    gold = (214, 168, 70, 255)
    dark_gold = (150, 108, 40, 255)
    cols = {"n": (240, 196, 90, 255), "s": (236, 140, 54, 255), "o": (80, 210, 200, 255), "e": (190, 205, 245, 255)}
    d.ellipse((12, 12, S - 12, S - 12), outline=gold, width=14)
    d.ellipse((60, 60, S - 60, S - 60), outline=dark_gold, width=6)
    for k in range(64):
        a = k / 64 * math.tau
        r0, r1 = (S / 2 - 70, S / 2 - 26) if k % 4 == 0 else (S / 2 - 52, S / 2 - 30)
        d.line((c + math.cos(a) * r0, c + math.sin(a) * r0, c + math.cos(a) * r1, c + math.sin(a) * r1), fill=gold, width=5 if k % 4 == 0 else 3)
    # branches secondaires (diagonales)
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        tip = (c + math.cos(a) * 330, c + math.sin(a) * 330)
        l = (c + math.cos(a + 0.5) * 70, c + math.sin(a + 0.5) * 70)
        r = (c + math.cos(a - 0.5) * 70, c + math.sin(a - 0.5) * 70)
        d.polygon([tip, l, (c, c)], fill=dark_gold)
        d.polygon([tip, r, (c, c)], fill=gold)
    # les quatre grandes branches, aux couleurs des ailes
    for key, a in (("e", 0.0), ("s", math.pi / 2), ("o", math.pi), ("n", -math.pi / 2)):
        tip = (c + math.cos(a) * 470, c + math.sin(a) * 470)
        l = (c + math.cos(a + 0.35) * 110, c + math.sin(a + 0.35) * 110)
        r = (c + math.cos(a - 0.35) * 110, c + math.sin(a - 0.35) * 110)
        d.polygon([tip, l, (c, c)], fill=cols[key])
        dk = tuple(int(v * 0.7) for v in cols[key][:3]) + (255,)
        d.polygon([tip, r, (c, c)], fill=dk)
        d.line([tip, (c, c)], fill=gold, width=4)
    d.ellipse((c - 200, c - 200, c + 200, c + 200), outline=gold, width=8)
    a = np.asarray(img, np.float32)
    gc.rng = np.random.default_rng(721)
    n = tile_noise(S, S, ox=(16, 32, 64, 128), falloff=0.7)
    a[..., :3] *= (0.8 + 0.35 * n[..., None])
    # usure : l'or s'efface un peu sous les pas
    wear = tile_noise(S, S, ox=(8, 16, 32), falloff=0.6)
    a[..., 3] = np.where(wear > 0.8, a[..., 3] * 0.0, a[..., 3])
    save_img(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA"), "rose_sceaux.png")


def encre_lune():
    """L'écriture de lune au-dessus de la porte : quatre lunes dans l'ordre (pleine,
    décroissante, nouvelle, croissante), et un vers. Transparente, argent lumineux."""
    W, H = 1024, 358
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    silver = (230, 238, 255, 255)
    for k, ph in enumerate(("pleine", "decroissante", "nouvelle", "croissante")):
        cx, cy, s = 170 + k * 228, 120, 70
        d.ellipse((cx - s, cy - s, cx + s, cy + s), outline=silver, width=6)
        if ph == "pleine":
            d.ellipse((cx - s + 12, cy - s + 12, cx + s - 12, cy + s - 12), fill=silver)
        elif ph == "decroissante":
            d.chord((cx - s + 10, cy - s + 10, cx + s - 10, cy + s - 10), 90, 270, fill=silver)
        elif ph == "croissante":
            d.chord((cx - s + 10, cy - s + 10, cx + s - 10, cy + s - 10), 270, 90, fill=silver)
        if k < 3:
            d.line((cx + s + 22, cy, cx + 228 - s - 22, cy), fill=silver, width=4)
            d.polygon([(cx + 228 - s - 22, cy - 10), (cx + 228 - s - 8, cy), (cx + 228 - s - 22, cy + 10)], fill=silver)
    f = font("Lora-Italic.ttf", 40)
    t = "Pleine, puis elle décroît, se cache, et renaît."
    w = d.textlength(t, font=f)
    d.text((W / 2 - w / 2, 250), t, fill=silver, font=f)
    glow = img.filter(ImageFilter.GaussianBlur(6))
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    out.alpha_composite(glow)
    out.alpha_composite(glow)
    out.alpha_composite(img)
    save_img(out, "encre_lune.png")


def images():
    fresque_peuples()
    fresque_bergerie()
    fresque_mare()
    chant_berger()
    stele_soleil()
    emblems()
    anneau_tombeau()
    roue_moutons()
    phases_lune()
    rose_sceaux()
    encre_lune()


# =================================================================== icônes

def icones():
    import generate_items_v28 as ic

    # le journal de bord : cuir brun, coins de laiton, rose des vents en relief
    img = ic.canvas()
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((110, 70, 410, 450), 26, fill=(110, 64, 36))
    d.rectangle((110, 70, 150, 450), fill=(84, 46, 26))
    d.rectangle((400, 92, 420, 430), fill=(236, 226, 200))
    for (x, y) in ((150, 70), (380, 70), (150, 420), (380, 420)):
        d.rectangle((x - 2, y, x + 32, y + 30), fill=(212, 170, 80))
    cx, cy = 270, 250
    d.ellipse((cx - 70, cy - 70, cx + 70, cy + 70), outline=(212, 170, 80), width=8)
    for k in range(4):
        a = k * math.pi / 2
        d.polygon([(cx + math.cos(a) * 90, cy + math.sin(a) * 90), (cx + math.cos(a + 0.4) * 22, cy + math.sin(a + 0.4) * 22), (cx, cy), (cx + math.cos(a - 0.4) * 22, cy + math.sin(a - 0.4) * 22)], fill=(212, 170, 80))
    ic.save(img, "journal_bord")

    def seal(name, base, draw):
        img = ic.canvas()
        ic.shaded_ellipse(img, (70, 70, 442, 442), base)
        d = ImageDraw.Draw(img)
        d.ellipse((96, 96, 416, 416), outline=tuple(int(v * 0.6) for v in base), width=10)
        draw(d)
        ic.save(img, name)

    def sun(d):
        d.ellipse((196, 196, 316, 316), fill=(255, 236, 160))
        for k in range(12):
            a = k / 12 * math.tau
            d.line((256 + math.cos(a) * 76, 256 + math.sin(a) * 76, 256 + math.cos(a) * 130, 256 + math.sin(a) * 130), fill=(255, 236, 160), width=12)

    def gear(d):
        for k in range(10):
            a = k / 10 * math.tau
            d.polygon([(256 + math.cos(a - 0.17) * 100, 256 + math.sin(a - 0.17) * 100), (256 + math.cos(a - 0.12) * 136, 256 + math.sin(a - 0.12) * 136),
                       (256 + math.cos(a + 0.12) * 136, 256 + math.sin(a + 0.12) * 136), (256 + math.cos(a + 0.17) * 100, 256 + math.sin(a + 0.17) * 100)], fill=(250, 210, 120))
        d.ellipse((150, 150, 362, 362), fill=(250, 210, 120))
        d.ellipse((216, 216, 296, 296), fill=(120, 76, 30))

    def moon(d):
        d.ellipse((150, 150, 362, 362), fill=(240, 244, 255))
        d.ellipse((200, 120, 400, 330), fill=(150, 158, 180))

    def wave(d):
        for k in range(3):
            y = 200 + k * 50
            d.line([(x, y + math.sin(x / 30.0 + k) * 16) for x in range(140, 380, 6)], fill=(230, 255, 250), width=16)

    seal("sceau_sables", (230, 168, 60), sun)
    seal("sceau_airain", (190, 120, 50), gear)
    seal("sceau_brumes", (180, 190, 214), moon)
    seal("sceau_embruns", (60, 190, 180), wave)
    # la Lame du Cœur : lame de cristal rouge-or, garde dorée
    img = ic.canvas()
    d = ImageDraw.Draw(img)
    d.polygon([(380, 50), (420, 92), (220, 330), (180, 290)], fill=(230, 80, 50))
    d.polygon([(380, 50), (420, 92), (300, 236)], fill=(255, 190, 120))
    d.line((180, 290, 220, 330), fill=(255, 220, 150), width=6)
    ic.stick_polygon(d, (130, 240), (270, 380), 30, (212, 170, 70))
    ic.stick_polygon(d, (196, 314), (110, 400), 26, (90, 50, 30))
    d.ellipse((84, 404, 124, 444), fill=(212, 170, 70))
    d.ellipse((186, 296, 214, 324), fill=(255, 60, 40))
    ic.save(img, "lame_coeur")


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else ""
    if what in ("", "textures"):
        textures()
    if what in ("", "images"):
        images()
    if what in ("", "icones"):
        icones()


if __name__ == "__main__":
    main()
