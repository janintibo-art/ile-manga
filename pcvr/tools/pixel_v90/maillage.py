"""V90 : le maillage des blocs (le relief) et des petits cubes (les modèles : plantes, dinosaures,
hommes des cavernes).

Pour Godot, la face avant d'un triangle est celle qu'on voit tourner dans le sens des aiguilles
d'une montre : on construit chaque carré dans le sens inverse vu de dehors (a, b, c, d), puis on
écrit les triangles (a, c, b) et (a, d, c).
"""
from __future__ import annotations

import numpy as np


# =========================================================================== le relief

def relief_quads(levels: np.ndarray, mats: np.ndarray, x0: int, z0: int, x1: int, z1: int):
    """Les carrés d'un morceau de relief [x0, x1[ × [z0, z1[ (en blocs).
    Dessus (fusionnés en rectangles de même hauteur et même matière) : (bx0, bz0, bx1, bz1, niveau, matière).
    Côtés (fusionnés le long du bord) : (sens, a0, a1, fixe, bas, haut, matière) ; sens 0 : face +x (fixe = x
    du bord, a = z), 1 : face -x, 2 : face +z (fixe = z du bord, a = x), 3 : face -z ; bas, haut en niveaux."""
    n = levels.shape[0]
    L = levels[z0:z1, x0:x1]
    M = mats[z0:z1, x0:x1]
    h, w = L.shape
    used = np.zeros((h, w), bool)
    tops = []
    for z in range(h):
        x = 0
        while x < w:
            if used[z, x]:
                x += 1
                continue
            lv, mt = L[z, x], M[z, x]
            x2 = x + 1
            while x2 < w and not used[z, x2] and L[z, x2] == lv and M[z, x2] == mt:
                x2 += 1
            z2 = z + 1
            while z2 < h:
                row_ok = np.all(L[z2, x:x2] == lv) and np.all(M[z2, x:x2] == mt) and not used[z2, x:x2].any()
                if not row_ok:
                    break
                z2 += 1
            used[z:z2, x:x2] = True
            tops.append((x0 + x, z0 + z, x0 + x2, z0 + z2, int(lv), int(mt)))
            x = x2
    sides = []
    pad = np.pad(levels, 1, mode="edge")
    # les voisins (dans la grille complète, bord compris)
    def neigh(dz, dx):
        return pad[1 + z0 + dz:1 + z1 + dz, 1 + x0 + dx:1 + x1 + dx]
    for sens, (dz, dx) in enumerate(((0, 1), (0, -1), (1, 0), (-1, 0))):
        nb = neigh(dz, dx)
        low = np.minimum(nb, L)
        diff = (L > nb) & (L > -12)          # (les marches du grand fond, sous 6 m d'eau, ne se voient pas)
        if sens < 2:
            # faces ±x : on avance le long de z, colonne par colonne
            for x in range(w):
                z = 0
                while z < h:
                    if not diff[z, x]:
                        z += 1
                        continue
                    key = (L[z, x], low[z, x], M[z, x])
                    z2 = z + 1
                    while z2 < h and diff[z2, x] and (L[z2, x], low[z2, x], M[z2, x]) == key:
                        z2 += 1
                    fx = x0 + x + (1 if sens == 0 else 0)
                    sides.append((sens, z0 + z, z0 + z2, fx, int(key[1]), int(key[0]), int(key[2])))
                    z = z2
        else:
            for z in range(h):
                x = 0
                while x < w:
                    if not diff[z, x]:
                        x += 1
                        continue
                    key = (L[z, x], low[z, x], M[z, x])
                    x2 = x + 1
                    while x2 < w and diff[z, x2] and (L[z, x2], low[z, x2], M[z, x2]) == key:
                        x2 += 1
                    fz = z0 + z + (1 if sens == 2 else 0)
                    sides.append((sens, x0 + x, x0 + x2, fz, int(key[1]), int(key[0]), int(key[2])))
                    x = x2
    return tops, sides


# =========================================================================== les petits cubes

AO_SHADE = np.array([1.0, 0.82, 0.68, 0.55])
DIRS = [((1, 0, 0), (0, 1, 0), (0, 0, 1)), ((-1, 0, 0), (0, 0, 1), (0, 1, 0)),
        ((0, 1, 0), (0, 0, 1), (1, 0, 0)), ((0, -1, 0), (1, 0, 0), (0, 0, 1)),
        ((0, 0, 1), (1, 0, 0), (0, 1, 0)), ((0, 0, -1), (0, 1, 0), (1, 0, 0))]


def mesh_voxels(vox: np.ndarray, palette, size: float, origin=(0.0, 0.0, 0.0), seed: int = 1, var: float = 0.07, bord_plein: bool = False):
    """Un modèle en petits cubes : vox[x, y, z] = indice de couleur (0 : vide), palette[k] = (r, g, b).
    Renvoie (sommets, normales, couleurs RGBA, indices) ; chaque cube garde une nuance au hasard (les
    « pixels ») et chaque coin une ombre douce (occlusion des voisins)."""
    sx, sy, sz = vox.shape
    solid = vox > 0
    pad = np.pad(solid, 1, constant_values=bord_plein)
    rng = np.random.default_rng(seed)
    shade = 1.0 + rng.uniform(-var, var, vox.shape)
    pal = np.asarray(palette, float)
    V, Nn, C, I = [], [], [], []
    base = 0
    org = np.asarray(origin, float)
    for (d, u, v) in DIRS:
        d, u, v = np.array(d), np.array(u), np.array(v)
        # cubes pleins dont le voisin dans la direction d est vide
        nb = pad[1 + d[0]:1 + d[0] + sx, 1 + d[1]:1 + d[1] + sy, 1 + d[2]:1 + d[2] + sz]
        face = solid & ~nb
        idx = np.argwhere(face)
        if len(idx) == 0:
            continue
        # le coin de départ de la face : sur le côté d du cube
        off = (d > 0).astype(float)
        corners = []
        for (cu, cv) in ((0, 0), (1, 0), (1, 1), (0, 1)):
            corners.append(off + u * cu + v * cv)
        # occlusion : pour chaque coin, les deux voisins de côté et celui en diagonale, dans la couche d
        aos = []
        for (cu, cv) in ((0, 0), (1, 0), (1, 1), (0, 1)):
            su = u * (1 if cu else -1)
            sv = v * (1 if cv else -1)
            def at(o):
                q = idx + d + o + 1
                return pad[q[:, 0], q[:, 1], q[:, 2]]
            s1, s2, cc = at(su), at(sv), at(su + sv)
            ao = np.where(s1 & s2, 3, s1.astype(int) + s2.astype(int) + cc.astype(int))
            aos.append(ao)
        aos = np.stack(aos, 1)
        col = pal[vox[idx[:, 0], idx[:, 1], idx[:, 2]] - 1] * shade[idx[:, 0], idx[:, 1], idx[:, 2]][:, None]
        m = len(idx)
        # sens : (u × v) doit valoir d ; sinon on retourne les coins
        uxv = np.cross(u, v)
        order = [0, 1, 2, 3] if np.dot(uxv, d) > 0 else [0, 3, 2, 1]
        P = np.stack([(idx + corners[k]) * size + org for k in order], 1)          # (m, 4, 3)
        A = aos[:, order]
        Cq = np.clip(col[:, None, :] * AO_SHADE[A][:, :, None], 0, 1)
        V.append(P.reshape(-1, 3))
        Nn.append(np.repeat(d[None, :].astype(float), m * 4, 0))
        C.append(np.concatenate([Cq.reshape(-1, 3), np.ones((m * 4, 1))], 1))
        # deux triangles par carré (la diagonale qui suit l'ombre), écrits pour Godot (sens horaire)
        flip = (A[:, 0] + A[:, 2]) > (A[:, 1] + A[:, 3])
        b = base + np.arange(m) * 4
        t1 = np.where(flip[:, None], np.stack([b, b + 3, b + 1], 1), np.stack([b, b + 2, b + 1], 1))
        t2 = np.where(flip[:, None], np.stack([b + 1, b + 3, b + 2], 1), np.stack([b, b + 3, b + 2], 1))
        I.append(np.concatenate([t1, t2], 1).reshape(-1, 3))
        base += m * 4
    if not V:
        return (np.zeros((0, 3)), np.zeros((0, 3)), np.zeros((0, 4)), np.zeros((0, 3), int))
    return np.concatenate(V), np.concatenate(Nn), np.concatenate(C), np.concatenate(I)


def export(vox, palette, size, origin=(0.0, 0.0, 0.0), seed=1, var=0.07, bord_plein=False):
    import gdvar
    v, n, c, i = mesh_voxels(vox, palette, size, origin, seed, var, bord_plein)
    return {"v": gdvar.v3(v), "n": gdvar.v3(n), "c": gdvar.col4(c), "i": gdvar.i32(i)}
