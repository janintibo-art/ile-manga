"""V89 : la roche du souterrain du Grand Moaï (l'Île aux Moaïs).

Sous le Grand Moaï, un puits rond où tourne l'escalier ; au pied de l'escalier, un couloir qui
serpente et descend doucement (les quatre fresques) ; au bout, la Salle du Chant, une grande
caverne en dôme avec sa vasque d'eau au milieu ; tout au fond, un passage étroit fermé par une
dalle, et derrière, la petite salle ronde du Cœur du Chant (le trésor).

La roche est décrite par une fonction de distance (chaque morceau : un volume creusé, coupé par
son sol, bien plat), bosselée par un bruit en trois dimensions, puis taillée en triangles
(marching cubes). On garde, pour le jeu :
  parts       la roche en morceaux (blocs de 14 m × 12 m), chacun avec :
    v, n, i     les sommets, les normales (tournées vers l'intérieur de la caverne), les triangles ;
    c           par sommet : (ouverture, mouillé, sol, 0) : l'occlusion approchée (combien la roche
              est « ouverte » devant elle), l'humidité (près du sol et de la vasque), le sol ;
  vers        des points du plafond (les vers luisants) ;
  stalac      les stalactites (point du plafond, longueur) ; stalag : les stalagmites ;
  cristaux    des points au pied des parois (les grappes de cristaux) et leurs normales ;
  mousse      des points des parois basses (la mousse qui luit) et leurs normales.
Repère : origine au pied du puits (sol à y = 0), z vers la Salle du Chant.

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_souterrain_v89.py
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
OUT = ROOT / "www" / "assets" / "models" / "moai89"

STEP = 0.4
LO = np.array([-21.0, -6.5, -6.0])
HI = np.array([21.0, 21.5, 92.0])

# --- les morceaux (gardés en accord avec souterrain_moai_v89.gd)
PUITS_R = 4.4
PUITS_H = 19.5
COULOIR = np.array([[0.0, 0.0, 2.0], [1.5, -0.3, 10.0], [-1.8, -1.0, 18.0], [-0.5, -1.8, 26.0],
                    [1.5, -2.5, 33.0], [0.5, -3.0, 40.0], [0.0, -3.0, 46.0]])
SALLE = np.array([0.0, -3.0, 58.0])
SALLE_R = np.array([17.0, 13.0, 16.0])
VASQUE_R = 4.6
PASSAGE = np.array([[0.0, -3.0, 70.0], [0.0, -3.0, 81.0]])
COEUR = np.array([0.0, -3.0, 85.5])
COEUR_R = 5.6


def smin(a, b, k):
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b * (1 - h) + a * h - k * h * (1 - h)


def lattice_noise(shape_pts, cell, seed):
    """Bruit lisse (valeurs au hasard sur une grille, interpolées) aux points donnés (N, 3)."""
    rng = np.random.default_rng(seed)
    n = np.ceil((HI - LO) / cell).astype(int) + 4
    g = rng.standard_normal(n).astype(np.float32)
    g = ndimage.gaussian_filter(g, 0.6)
    g /= g.std() + 1e-6
    c = ((shape_pts - LO) / cell + 1.0).T
    return ndimage.map_coordinates(g, c, order=3, mode="nearest")


def fbm(p):
    return (lattice_noise(p, 7.0, 891) * 0.55 + lattice_noise(p, 3.0, 892) * 0.3 + lattice_noise(p, 1.3, 893) * 0.15)


def seg_param(p_xz, a, b):
    ab = b - a
    t = np.clip(((p_xz - a) @ ab) / (ab @ ab), 0.0, 1.0)
    q = a + t[:, None] * ab
    return t, np.linalg.norm(p_xz - q, axis=1)


def tube(p, pts, w, h):
    """Un couloir le long d'une ligne brisée : section en demi-ellipse posée sur un sol plat (dont
    la hauteur suit la ligne) ; renvoie (distance approchée, hauteur du sol)."""
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


def sdf(p, with_noise=True):
    x, y, z = p[:, 0], p[:, 1], p[:, 2]
    nz = fbm(p) if with_noise else np.zeros(len(p))
    parts = []
    # le puits (un cylindre, coiffé d'un dôme) ; sol à 0
    r = np.hypot(x, z)
    cap = np.where(y > PUITS_H - 2.5, np.sqrt(np.maximum(r, 0) ** 2 + ((y - (PUITS_H - 2.5)) * 1.6) ** 2), r)
    d = np.maximum(cap - PUITS_R, -0.2 - y) + nz * 0.18
    parts.append(np.maximum(d, -y))
    # le couloir des fresques
    d, fy = tube(p, COULOIR, 2.4, 4.0)
    d = d + nz * 0.55
    parts.append(np.maximum(d, fy - y))
    # la Salle du Chant (un dôme bosselé, plus quelques bosses de roche en plus)
    q = (p - SALLE) / SALLE_R
    d = (np.sqrt(q[:, 0] ** 2 + np.maximum(q[:, 1], 0) ** 2 + q[:, 2] ** 2) - 1.0) * 14.0
    for c, rr in (((-11.0, 1.5, 50.0), 7.5), ((12.0, 2.0, 63.0), 7.0), ((-9.0, 3.0, 68.0), 6.5), ((9.0, 4.0, 49.0), 6.0)):
        d = smin(d, np.linalg.norm(p - np.array(c), axis=1) - rr, 3.0)
    d = d + nz * 1.4
    # le sol de la salle, et la vasque au milieu (creusée de 1,2 m)
    rs = np.hypot(x - SALLE[0], z - SALLE[2])
    fy = SALLE[1] - 1.2 * np.clip((VASQUE_R + 0.3 - rs) / 0.9, 0.0, 1.0) ** 0.7
    parts.append(np.maximum(d, fy - y))
    # le passage, puis le Cœur du Chant
    d, fy = tube(p, PASSAGE, 1.9, 3.4)
    parts.append(np.maximum(d + nz * 0.3, fy - y))
    q = p - COEUR
    d = np.sqrt(q[:, 0] ** 2 + (np.maximum(q[:, 1], 0) * 1.15) ** 2 + q[:, 2] ** 2) - COEUR_R
    parts.append(np.maximum(d + nz * 0.45, COEUR[1] - y))
    out = parts[0]
    for d in parts[1:]:
        out = smin(out, d, 1.2)
    return out


def floor_info(p):
    """Le sol attendu sous chaque point (pour les masques) : le plus proche des morceaux."""
    x, z = p[:, 0], p[:, 2]
    _, fyc = tube(p, COULOIR, 2.4, 4.0)
    fy = np.where(np.hypot(x, z) < PUITS_R + 0.5, 0.0, fyc)
    fy = np.where(z > 44.0, -3.0, fy)
    return fy


def main() -> int:
    nx, ny, nz = (np.ceil((HI - LO) / STEP).astype(int) + 1)
    gx = LO[0] + np.arange(nx) * STEP
    gy = LO[1] + np.arange(ny) * STEP
    gz = LO[2] + np.arange(nz) * STEP
    P = np.stack(np.meshgrid(gx, gy, gz, indexing="ij"), -1).reshape(-1, 3)
    vals = np.empty(len(P), dtype=np.float32)
    B = 400000
    for s in range(0, len(P), B):
        vals[s:s + B] = sdf(P[s:s + B])
    vol = vals.reshape(nx, ny, nz)
    # bords de la boîte : de la roche partout
    vol[0, :, :] = vol[-1, :, :] = 5.0
    vol[:, 0, :] = vol[:, -1, :] = 5.0
    vol[:, :, 0] = vol[:, :, -1] = 5.0
    verts, faces, _, _ = measure.marching_cubes(vol, 0.0, spacing=(STEP, STEP, STEP))
    verts = verts + LO
    # les normales : vers l'intérieur (là où la distance diminue)
    e = 0.12
    g = np.stack([sdf(verts + np.array(dv)) - sdf(verts - np.array(dv)) for dv in ((e, 0, 0), (0, e, 0), (0, 0, e))], -1)
    n_in = -g / (np.linalg.norm(g, axis=1, keepdims=True) + 1e-9)
    # l'ordre des triangles : la face visible regarde l'intérieur (pour Godot, la face avant est celle
    # qu'on voit tourner dans le sens des aiguilles d'une montre : (b - a) × (c - a) s'éloigne de l'œil)
    a, b, c = verts[faces[:, 0]], verts[faces[:, 1]], verts[faces[:, 2]]
    fn = np.cross(b - a, c - a)
    face_in = (n_in[faces[:, 0]] + n_in[faces[:, 1]] + n_in[faces[:, 2]])
    ccw_in = np.einsum("ij,ij->i", fn, face_in) > 0
    faces = np.where(ccw_in[:, None], faces[:, [0, 2, 1]], faces)
    # occlusion approchée : la roche est-elle ouverte devant le sommet ?
    o1 = np.clip(-sdf(verts + n_in * 0.8, False) / 0.8, 0, 1)
    o2 = np.clip(-sdf(verts + n_in * 2.5, False) / 2.5, 0, 1)
    ao = np.clip(0.25 + 0.4 * o1 + 0.45 * o2, 0, 1)
    fy = floor_info(verts)
    above = verts[:, 1] - fy
    is_floor = (n_in[:, 1] > 0.85) & (above < 0.4)
    rs = np.hypot(verts[:, 0] - SALLE[0], verts[:, 2] - SALLE[2])
    wet = np.clip(1.0 - above / 1.6, 0, 1) * 0.6 + np.clip((VASQUE_R + 2.5 - rs) / 2.5, 0, 1) * (verts[:, 2] > 40) * 0.6
    col = np.stack([ao, np.clip(wet, 0, 1), is_floor.astype(float), np.zeros(len(verts))], -1)
    rng = np.random.default_rng(8900)
    in_salle = (verts[:, 2] > 42.0)
    # les vers luisants : au plafond de la salle et du Cœur (et un peu dans le couloir)
    ceil = (n_in[:, 1] < -0.45) & (above > 4.0)
    idx = np.flatnonzero(ceil & (in_salle | (rng.random(len(verts)) < 0.25)))
    vers = rng.choice(idx, size=min(700, len(idx)), replace=False)
    # les stalactites (plafond franc de la salle)
    idx = np.flatnonzero((n_in[:, 1] < -0.8) & in_salle & (above > 7.0) & (verts[:, 2] < 74))
    stalac = []
    for k in rng.permutation(idx):
        pnt = verts[k]
        if all(np.linalg.norm(pnt - s[:3]) > 2.2 for s in stalac):
            stalac.append(np.r_[pnt, rng.uniform(0.8, 3.2)])
        if len(stalac) >= 40:
            break
    # les stalagmites : au sol de la salle, près des parois, loin de la vasque et des chemins
    idx = np.flatnonzero(is_floor & in_salle & (verts[:, 2] < 72) & (rs > 10.0))
    stalag = []
    for k in rng.permutation(idx):
        pnt = verts[k]
        wall = -sdf(pnt[None] + np.array([[0, 1.0, 0]]), False)[0]
        if wall > 2.5:
            continue
        if all(np.linalg.norm(pnt - s[:3]) > 2.5 for s in stalag):
            stalag.append(np.r_[pnt, rng.uniform(0.6, 2.2)])
        if len(stalag) >= 26:
            break
    # les cristaux : au pied des parois (couloir et salle), tournés vers l'intérieur
    idx = np.flatnonzero((np.abs(n_in[:, 1]) < 0.45) & (above > 0.05) & (above < 1.4) & (verts[:, 2] > 6.0))
    cris = []
    for k in rng.permutation(idx):
        pnt = verts[k]
        if all(np.linalg.norm(pnt - s) > 3.2 for s in cris):
            cris.append(pnt)
        if len(cris) >= 70:
            break
    cris_n = [n_in[np.argmin(np.linalg.norm(verts - s, axis=1))] for s in cris]
    # la mousse qui luit : bas des parois, partout
    idx = np.flatnonzero((n_in[:, 1] < 0.6) & (n_in[:, 1] > -0.3) & (above < 3.0) & (verts[:, 2] > 3.0))
    mo = rng.choice(idx, size=min(1600, len(idx)), replace=False)
    # en morceaux (des blocs de 14 m sur 12 m) : chaque morceau n'est dessiné que s'il est en vue, et
    # ne reçoit que les lumières proches
    cen = verts[faces].mean(axis=1)
    key = np.floor((cen[:, 0] + 21.0) / 14.0).astype(int) * 100 + np.floor((cen[:, 2] + 6.0) / 12.0).astype(int)
    parts = []
    for k in np.unique(key):
        fk = faces[key == k]
        used, inv = np.unique(fk.ravel(), return_inverse=True)
        parts.append({"v": gdvar.v3(verts[used]), "n": gdvar.v3(n_in[used]), "c": gdvar.col4(col[used]),
                      "i": gdvar.i32(inv.reshape(-1, 3))})
    OUT.mkdir(parents=True, exist_ok=True)
    d = {
        "parts": parts,
        "vers": gdvar.v3(verts[vers]), "vers_n": gdvar.v3(n_in[vers]),
        "stalac": gdvar.f32(np.array(stalac)), "stalag": gdvar.f32(np.array(stalag)),
        "cristaux": gdvar.v3(np.array(cris)), "cristaux_n": gdvar.v3(np.array(cris_n)),
        "mousse": gdvar.v3(verts[mo]), "mousse_n": gdvar.v3(n_in[mo]),
    }
    raw, comp = gdvar.save(OUT / "grotte.bin", d)
    print(f"grotte : {len(verts)} sommets, {len(faces)} triangles en {len(parts)} morceaux, {len(vers)} vers, {len(stalac)} stalactites, "
          f"{len(stalag)} stalagmites, {len(cris)} cristaux ; {comp // 1024} Ko")
    return 0


if __name__ == "__main__":
    sys.exit(main())
