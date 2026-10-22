"""Accrochage des « proxies » (cheveux, barbes, vêtements amples) au corps : chaque sommet est
lié à un triangle du corps (barycentre) + un décalage, mis à l'échelle de la tête ou du buste.
Au chargement d'un personnage, le jeu recalcule les positions à partir de son propre corps."""
import numpy as np
from scipy.spatial import cKDTree


def closest_on_tri(p, a, b, c):
    """point le plus proche de p sur le triangle abc -> (point, barycentres)."""
    ab, ac, ap = b - a, c - a, p - a
    d1, d2 = ab @ ap, ac @ ap
    if d1 <= 0 and d2 <= 0:
        return a, (1, 0, 0)
    bp = p - b
    d3, d4 = ab @ bp, ac @ bp
    if d3 >= 0 and d4 <= d3:
        return b, (0, 1, 0)
    vc = d1 * d4 - d3 * d2
    if vc <= 0 and d1 >= 0 and d3 <= 0:
        v = d1 / (d1 - d3)
        return a + v * ab, (1 - v, v, 0)
    cp = p - c
    d5, d6 = ab @ cp, ac @ cp
    if d6 >= 0 and d5 <= d6:
        return c, (0, 0, 1)
    vb = d5 * d2 - d1 * d6
    if vb <= 0 and d2 >= 0 and d6 <= 0:
        w = d2 / (d2 - d6)
        return a + w * ac, (1 - w, 0, w)
    va = d3 * d6 - d5 * d4
    if va <= 0 and (d4 - d3) >= 0 and (d5 - d6) >= 0:
        w = (d4 - d3) / ((d4 - d3) + (d5 - d6))
        return b + w * (c - b), (0, 1 - w, w)
    denom = 1.0 / (va + vb + vc)
    v = vb * denom
    w = vc * denom
    return a + ab * v + ac * w, (1 - v - w, v, w)


class Binder:
    def __init__(self, body, allowed_tris=None):
        self.body = body
        tris = body.tris if allowed_tris is None else body.tris[allowed_tris]
        self.tris = tris
        A, B, C = (body.V[tris[:, k]] for k in range(3))
        self.kd = cKDTree((A + B + C) / 3)

    def bind(self, P, k=12):
        V = self.body.V
        refs = np.zeros((len(P), 3), np.int64)
        bary = np.zeros((len(P), 3))
        off = np.zeros((len(P), 3))
        _, cand = self.kd.query(P, k)
        for i, p in enumerate(P):
            best = None
            for t in cand[i]:
                a, b, c = (V[self.tris[t, j]] for j in range(3))
                q, w = closest_on_tri(p, a, b, c)
                d = np.sum((p - q) ** 2)
                if best is None or d < best[0]:
                    best = (d, t, w, q)
            _, t, w, q = best
            refs[i] = self.tris[t]
            bary[i] = w
            off[i] = p - q
        return refs, bary, off


def head_refs(body):
    """sommets de référence (ids soudés) pour l'échelle de la tête : largeur, hauteur, profondeur."""
    V = body.V
    c = body.c
    head = np.where((V[:, 1] > c[1] - 0.16) & (np.abs(V[:, 0] - c[0]) < 0.1) & (V[:, 2] > c[2] - 0.2) & (np.arange(len(V)) < body.topo.nb))[0]
    lvl = head[np.abs(V[head, 1] - (c[1] + 0.03)) < 0.006]
    ia, ib = lvl[np.argmax(V[lvl, 0])], lvl[np.argmin(V[lvl, 0])]
    it = head[np.argmax(V[head, 1])]
    ch = body.L['chin']
    ic = head[np.argmin(np.linalg.norm(V[head] - ch, axis=1))]
    mid = head[np.abs(V[head, 0] - c[0]) < 0.005]
    fr = mid[(V[mid, 1] > c[1] + 0.03) & (V[mid, 1] < c[1] + 0.05)]
    bk = mid[(V[mid, 1] > c[1]) & (V[mid, 1] < c[1] + 0.06)]
    iff, ibk = fr[np.argmax(V[fr, 2])], bk[np.argmin(V[bk, 2])]
    ids = [int(ia), int(ib), int(it), int(ic), int(iff), int(ibk)]
    ref = [abs(V[ia, 0] - V[ib, 0]), abs(V[it, 1] - V[ic, 1]), abs(V[iff, 2] - V[ibk, 2])]
    return ids, ref


def torso_refs(body):
    V = body.V
    HJ = body.HJ
    nb = body.topo.nb
    ids = np.arange(nb)
    sh_y = (HJ['LeftArm'][1] + HJ['RightArm'][1]) / 2
    band = ids[(np.abs(V[:nb, 1] - (sh_y - 0.08)) < 0.01) & (np.abs(V[:nb, 0]) < 0.25)]
    # largeur de la poitrine sous les aisselles : points du tronc proches de l'axe
    tor = band[np.abs(V[band, 0]) < 0.2]
    ia, ib = tor[np.argmax(V[tor, 0])], tor[np.argmin(V[tor, 0])]
    iff, ibk = tor[np.argmax(V[tor, 2])], tor[np.argmin(V[tor, 2])]
    neck = ids[np.argmin(np.linalg.norm(V[:nb] - HJ['neck'], axis=1))]
    crotch_y = (HJ['LeftUpLeg'][1] + HJ['RightUpLeg'][1]) / 2 - 0.05
    low = ids[(np.abs(V[:nb, 0]) < 0.01) & (np.abs(V[:nb, 1] - crotch_y) < 0.02)]
    il = low[np.argmin(V[low, 1])] if len(low) else neck
    ids_out = [int(ia), int(ib), int(neck), int(il), int(iff), int(ibk)]
    ref = [abs(V[ia, 0] - V[ib, 0]), abs(V[neck, 1] - V[il, 1]), abs(V[iff, 2] - V[ibk, 2])]
    return ids_out, ref


def interp_weights(bidx, bw, refs, bary, nbones=24):
    """poids de peau interpolés depuis les 3 sommets du triangle."""
    n = len(refs)
    H = np.zeros((n, nbones))
    for k in range(3):
        for j in range(4):
            np.add.at(H, (np.arange(n), bidx[refs[:, k], j]), bw[refs[:, k], j] * bary[:, k])
    idx = np.argsort(-H, axis=1)[:, :4]
    w = np.take_along_axis(H, idx, 1)
    w /= np.maximum(w.sum(1, keepdims=True), 1e-9)
    return idx, w
