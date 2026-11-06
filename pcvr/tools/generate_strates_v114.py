"""V114 : la roche des Strates et de la Fronde, sous Hautefond.

Sous la Place de la Colonne, à une centaine de mètres de profondeur, une suite de cavernes taillées dans
un grès en couches :
  la GRANDE STRATE (GS)   une immense caverne en dôme (172 m sur 140, 48 m sous la voûte) : la ville des
                          Strates ; la Colonne Renversée pend du sommet de la voûte jusqu'à la Gare ;
  les GALERIES            deux étages taillés dans la paroi nord (G1, G2), où sont creusées des maisons ;
  les MINES               un tunnel vers l'ouest, et la GROTTE AUX CRISTAUX ;
  les JARDINS             une grande arche au sud, et la grotte des Jardins des Champignons (l'étang) ;
  le GOUFFRE              une faille très profonde, à l'est, que traverse le tunnel de la Fronde ;
  la FRONDE               la caverne du quartier libre, à l'est.
La roche est décrite par une fonction de distance (chaque morceau : un volume creusé, coupé par son sol,
bien plat), bosselée par un bruit en trois dimensions, puis taillée en triangles (marching cubes), comme
pour le souterrain du Grand Moaï (V89). On garde, pour le jeu :
  parts       la roche en morceaux (blocs de 24 m × 24 m), chacun avec v, n, i (sommets, normales tournées
              vers le creux, triangles) et c (par sommet : ouverture, mouillé, sol, cristal) ;
  stalac      des stalactites (point du plafond, longueur) ;
  cristaux    des points des parois de la Grotte aux Cristaux et du tunnel des Mines (et leurs normales) ;
  mousse      des points des parois basses des Jardins (la mousse qui luit) ;
  vers        des points de la voûte des Jardins et de la Fronde (les vers luisants).
Repère : local à Hautefond (x vers l'est, z vers le sud, depuis le centre de la Grande Colonne) ; y absolu.
Gardé en accord avec strates_roche_v114.gd (les mêmes constantes).

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_strates_v114.py
"""
from __future__ import annotations

from pathlib import Path
import sys

import numpy as np
from scipy import ndimage
from skimage import measure

sys.path.insert(0, str(Path(__file__).resolve().parent / "habitants_v64"))
import gdvar  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "models" / "strates114"

STEP = 1.0
LO = np.array([-176.0, -152.0, -84.0])
HI = np.array([204.0, -42.0, 130.0])

F0 = -96.0
# la Grande Strate
GS_A, GS_B, GS_H = 86.0, 70.0, 48.0
# les Galeries (côté nord) : (sol, hauteur, e intérieur, e extérieur, angle min, angle max en degrés)
G1 = (-84.0, 8.0, 0.93, 1.13, -160.0, -20.0)
G2 = (-72.0, 8.0, 0.84, 1.02, -150.0, -30.0)
# les Mines
MINE_T = np.array([[-80.0, F0, -8.0], [-104.0, F0 - 2.0, -11.0], [-128.0, F0 - 4.0, -14.0]])
MINE_C = np.array([-148.0, F0 - 4.0, -16.0])
MINE_R = np.array([22.0, 16.0, 18.0])
# les Jardins
JA_T = np.array([[2.0, F0, 58.0], [6.0, F0 - 3.0, 78.0]])
JA_C = np.array([6.0, F0 - 3.0, 98.0])
JA_R = np.array([34.0, 22.0, 26.0])
ETANG = np.array([16.0, 104.0])
ETANG_R = 9.0
# la Fronde
FR_T = np.array([[80.0, F0, 10.0], [94.0, F0 - 1.0, 16.5], [108.0, F0 - 2.0, 22.0]])
FR_C = np.array([152.0, F0 - 2.0, 26.0])
FR_R = np.array([46.0, 30.0, 38.0])
GOUFFRE = (93.0, 99.5, -40.0, 70.0, -150.0, F0 + 6.0)


def smin(a, b, k):
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b * (1 - h) + a * h - k * h * (1 - h)


_GRIDS: dict = {}


def lattice_noise(pts, cell, seed):
    """Bruit lisse (valeurs au hasard sur une grille, interpolées) aux points donnés (N, 3)."""
    if (cell, seed) not in _GRIDS:
        rng = np.random.default_rng(seed)
        n = np.ceil((HI - LO) / cell).astype(int) + 4
        g = rng.standard_normal(n).astype(np.float32)
        g = ndimage.gaussian_filter(g, 0.6)
        g /= g.std() + 1e-6
        _GRIDS[(cell, seed)] = g
    g = _GRIDS[(cell, seed)]
    c = ((pts - LO) / cell + 1.0).T
    return ndimage.map_coordinates(g, c, order=3, mode="nearest")


def fbm(p):
    return lattice_noise(p, 14.0, 1141) * 0.5 + lattice_noise(p, 5.5, 1142) * 0.32 + lattice_noise(p, 2.2, 1143) * 0.18


def seg_param(p_xz, a, b):
    ab = b - a
    t = np.clip(((p_xz - a) @ ab) / (ab @ ab), 0.0, 1.0)
    q = a + t[:, None] * ab
    return t, np.linalg.norm(p_xz - q, axis=1)


def tube(p, pts, w, h):
    """Un couloir le long d'une ligne brisée : section en demi-ellipse posée sur un sol plat (dont la
    hauteur suit la ligne) ; renvoie (distance approchée, hauteur du sol)."""
    best = np.full(len(p), 1e9)
    fy = np.zeros(len(p))
    for k in range(len(pts) - 1):
        a, b = pts[k], pts[k + 1]
        t, dh = seg_param(p[:, [0, 2]], a[[0, 2]], b[[0, 2]])
        y0 = a[1] + (b[1] - a[1]) * t
        better = dh < best
        best = np.where(better, dh, best)
        fy = np.where(better, y0, fy)
    e = np.sqrt((best / w) ** 2 + (np.maximum(p[:, 1] - fy, 0.0) / h) ** 2) - 1.0
    return e * min(w, h), fy


def ell(p, c, r):
    """Un dôme : la moitié haute d'un ellipsoïde (sous le sol, le même ovale, tout droit)."""
    q = (p - c) / r
    return (np.sqrt(q[:, 0] ** 2 + np.maximum(q[:, 1], 0.0) ** 2 + q[:, 2] ** 2) - 1.0) * float(np.min(r))


def gallery(p, g):
    y0, h, e0, e1, a0, a1 = g
    x, y, z = p[:, 0], p[:, 1], p[:, 2]
    e = np.sqrt((x / GS_A) ** 2 + (z / GS_B) ** 2)
    rr = np.hypot(x, z)
    ang = np.degrees(np.arctan2(z, x))
    de = np.maximum(e0 - e, e - e1) * 76.0
    da = np.maximum(np.radians(a0 - ang), np.radians(ang - a1)) * np.maximum(rr, 1.0)
    # le plafond : une voûte basse (plus haute au milieu de la profondeur)
    mid = (e - e0) / (e1 - e0)
    top = y0 + h + 1.2 * np.sin(np.clip(mid, 0, 1) * np.pi)
    dy = y - top
    return np.maximum(np.maximum(de, da), dy), y0


def parts_sdf(p, nz):
    x, y, z = p[:, 0], p[:, 1], p[:, 2]
    out = []
    # la Grande Strate (le sol bien plat ; les parois et la voûte bosselées)
    d = ell(p, np.array([0.0, F0, 0.0]), np.array([GS_A, GS_H, GS_B])) + nz * 1.6
    out.append(np.maximum(d, F0 - y))
    for g in (G1, G2):
        d, y0 = gallery(p, g)
        out.append(np.maximum(d + nz * 0.7, y0 - y))
    # les Mines : le tunnel, la Grotte aux Cristaux
    d, fy = tube(p, MINE_T, 3.4, 5.6)
    out.append(np.maximum(d + nz * 0.55, fy - y))
    d = ell(p, MINE_C, MINE_R) + nz * 1.6
    out.append(np.maximum(d, MINE_C[1] - y))
    # les Jardins : l'arche, la grotte ; le sol descend doucement vers l'étang
    d, fy = tube(p, JA_T, 8.5, 11.0)
    out.append(np.maximum(d + nz * 0.8, fy - y))
    d = ell(p, JA_C, JA_R) + nz * 1.5
    re = np.hypot(x - ETANG[0], z - ETANG[1])
    fy = JA_C[1] - 0.9 * np.clip((ETANG_R + 1.5 - re) / 2.0, 0.0, 1.0)
    out.append(np.maximum(d, fy - y))
    # la Fronde : le tunnel, la caverne
    d, fy = tube(p, FR_T, 4.2, 7.2)
    out.append(np.maximum(d + nz * 0.5, fy - y))
    d = ell(p, FR_C, FR_R) + nz * 1.5
    out.append(np.maximum(d, FR_C[1] - y))
    return out


def gouffre(p, nz):
    x0, x1, z0, z1, y0, y1 = GOUFFRE
    x, y, z = p[:, 0], p[:, 1], p[:, 2]
    # une faille : les deux lèvres se resserrent vers le haut et vers les bouts
    w = 1.0 - 0.35 * np.clip((y - y0) / (y1 - y0), 0, 1) - 0.5 * np.clip(np.abs(z - 15.0) / 55.0, 0, 1) ** 2
    cx = (x0 + x1) * 0.5
    hw = (x1 - x0) * 0.5 * w
    d = np.maximum(np.abs(x - cx) - hw, np.maximum(np.maximum(z0 - z, z - z1), np.maximum(y0 - y, y - y1)))
    return d + nz * 0.9


def sdf(p, with_noise=True):
    nz = fbm(p) if with_noise else np.zeros(len(p))
    parts = parts_sdf(p, nz)
    o = parts[0]
    for d in parts[1:]:
        o = smin(o, d, 1.6)
    # la faille coupe tout (sans lisser : ses lèvres restent nettes)
    o = np.minimum(o, gouffre(p, nz))
    return o


def floor_info(p):
    """Le sol attendu sous chaque point (pour les masques)."""
    x, z = p[:, 0], p[:, 2]
    fy = np.full(len(p), F0)
    e = np.sqrt((x / GS_A) ** 2 + (z / GS_B) ** 2)
    ang = np.degrees(np.arctan2(z, x))
    fy = np.where((e > 0.96) & (ang < -20) & (ang > -160), G1[0], fy)
    fy = np.where((e > 0.86) & (e < 1.02) & (ang < -30) & (ang > -150) & (p[:, 1] > G2[0] - 0.5), G2[0], fy)
    fy = np.where(x < -82.0, np.interp(-x, [82.0, 128.0], [F0, F0 - 4.0]), fy)
    fy = np.where(z > 64.0, np.interp(z, [64.0, 78.0], [F0, F0 - 3.0]), fy)
    fy = np.where(x > 82.0, np.interp(x, [82.0, 108.0], [F0, F0 - 2.0]), fy)
    return fy


def main() -> int:
    nx, ny, nz = (np.ceil((HI - LO) / STEP).astype(int) + 1)
    gx = LO[0] + np.arange(nx) * STEP
    gy = LO[1] + np.arange(ny) * STEP
    gz = LO[2] + np.arange(nz) * STEP
    vol = np.empty((nx, ny, nz), dtype=np.float32)
    YY, ZZ = np.meshgrid(gy, gz, indexing="ij")
    for i in range(nx):
        P = np.stack([np.full(YY.size, gx[i]), YY.ravel(), ZZ.ravel()], -1)
        vol[i] = sdf(P).reshape(ny, nz)
    vol[0, :, :] = vol[-1, :, :] = 5.0
    vol[:, 0, :] = vol[:, -1, :] = 5.0
    vol[:, :, 0] = vol[:, :, -1] = 5.0
    verts, faces, _, _ = measure.marching_cubes(vol, 0.0, spacing=(STEP, STEP, STEP))
    verts = verts + LO
    e = 0.15
    g = np.stack([sdf(verts + np.array(dv)) - sdf(verts - np.array(dv)) for dv in ((e, 0, 0), (0, e, 0), (0, 0, e))], -1)
    n_in = -g / (np.linalg.norm(g, axis=1, keepdims=True) + 1e-9)
    a, b, c = verts[faces[:, 0]], verts[faces[:, 1]], verts[faces[:, 2]]
    fn = np.cross(b - a, c - a)
    face_in = n_in[faces[:, 0]] + n_in[faces[:, 1]] + n_in[faces[:, 2]]
    ccw_in = np.einsum("ij,ij->i", fn, face_in) > 0
    faces = np.where(ccw_in[:, None], faces[:, [0, 2, 1]], faces)
    # occlusion approchée
    o1 = np.clip(-sdf(verts + n_in * 1.5, False) / 1.5, 0, 1)
    o2 = np.clip(-sdf(verts + n_in * 5.0, False) / 5.0, 0, 1)
    ao = np.clip(0.2 + 0.35 * o1 + 0.5 * o2, 0, 1)
    fy = floor_info(verts)
    above = verts[:, 1] - fy
    is_floor = (n_in[:, 1] > 0.85) & (above < 0.5)
    x, y, z = verts[:, 0], verts[:, 1], verts[:, 2]
    re = np.hypot(x - ETANG[0], z - ETANG[1])
    in_ja = z > 70.0
    in_mine = x < -82.0
    in_fr = x > 104.0
    wet = np.clip(1.0 - above / 1.5, 0, 1) * 0.35 * in_ja + np.clip((ETANG_R + 3.0 - re) / 3.0, 0, 1) * in_ja * 0.8
    wet = wet + (x > 92.5) * (x < 100.0) * (y < F0 - 3.0) * 0.6
    cris = np.clip((-x - 112.0) / 14.0, 0, 1) * (1.0 - is_floor)
    col = np.stack([ao, np.clip(wet, 0, 1), is_floor.astype(float), cris], -1)
    rng = np.random.default_rng(11400)
    # les stalactites : la voûte franche de la Grande Strate (loin de la Colonne), des Jardins, de la Grotte
    idx = np.flatnonzero((n_in[:, 1] < -0.75) & (above > 14.0) & (np.hypot(x, z) > 20.0))
    stalac = []
    for k in rng.permutation(idx):
        pnt = verts[k]
        if all(np.linalg.norm(pnt - s[:3]) > 6.0 for s in stalac):
            stalac.append(np.r_[pnt, rng.uniform(1.0, 5.5)])
        if len(stalac) >= 160:
            break
    # les cristaux : les parois de la Grotte (et, moins, du tunnel des Mines)
    idx = np.flatnonzero(in_mine & (n_in[:, 1] < 0.75) & (n_in[:, 1] > -0.25) & (above > 0.05) & (above < 7.0) & ((x < -124.0) | (rng.random(len(verts)) < 0.15)))
    cr = []
    for k in rng.permutation(idx):
        pnt = verts[k]
        if all(np.linalg.norm(pnt - s) > 2.2 for s in cr):
            cr.append(pnt)
        if len(cr) >= 130:
            break
    cr_n = [n_in[np.argmin(np.linalg.norm(verts - s, axis=1))] for s in cr]
    # la mousse qui luit : bas des parois des Jardins
    idx = np.flatnonzero(in_ja & (n_in[:, 1] < 0.7) & (above < 9.0) & (above > 0.05))
    mo = rng.choice(idx, size=min(700, len(idx)), replace=False)
    # les vers luisants : voûte des Jardins et de la Fronde
    idx = np.flatnonzero((in_ja | in_fr) & (n_in[:, 1] < -0.4) & (above > 8.0))
    ve = rng.choice(idx, size=min(1600, len(idx)), replace=False)
    # en morceaux de 24 m × 24 m
    cen = verts[faces].mean(axis=1)
    key = np.floor((cen[:, 0] - LO[0]) / 24.0).astype(int) * 100 + np.floor((cen[:, 2] - LO[2]) / 24.0).astype(int)
    parts = []
    for k in np.unique(key):
        fk = faces[key == k]
        used, inv = np.unique(fk.ravel(), return_inverse=True)
        parts.append({"v": gdvar.v3(verts[used]), "n": gdvar.v3(n_in[used]), "c": gdvar.col4(col[used]),
                      "i": gdvar.i32(inv.reshape(-1, 3))})
    OUT.mkdir(parents=True, exist_ok=True)
    d = {
        "parts": parts,
        "stalac": gdvar.f32(np.array(stalac)),
        "cristaux": gdvar.v3(np.array(cr)), "cristaux_n": gdvar.v3(np.array(cr_n)),
        "mousse": gdvar.v3(verts[mo]), "mousse_n": gdvar.v3(n_in[mo]),
        "vers": gdvar.v3(verts[ve]), "vers_n": gdvar.v3(n_in[ve]),
    }
    raw, comp = gdvar.save(OUT / "roche.bin", d)
    print(f"strates : {len(verts)} sommets, {len(faces)} triangles en {len(parts)} morceaux, {len(stalac)} stalactites, "
          f"{len(cr)} cristaux, {len(mo)} mousses, {len(ve)} vers ; {comp // 1024} Ko")
    return 0


if __name__ == "__main__":
    sys.exit(main())
