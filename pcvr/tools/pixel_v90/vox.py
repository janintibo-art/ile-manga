"""V90 : un petit atelier de modèles en petits cubes.

Un modèle (une « pièce ») est une liste de formes simples, chacune avec sa couleur (un indice de la
palette, ou une fonction qui colore point par point : rayures, taches, ventre clair…). On pose
les formes dans le repère de la pièce (en mètres ; +z vers l'avant, +y vers le haut), puis on
taille le tout en cubes de côté s. L'origine de la pièce est son articulation (le pivot).
"""
from __future__ import annotations

import numpy as np

import maillage

COULEURS: dict = {}       # nom de couleur -> indice (rempli par modeles.py)


class Piece:
    def __init__(self, s: float):
        self.s = s
        self.formes = []          # (fonction distance (P) -> d, couleur, bornes min, bornes max)

    def _add(self, f, col, lo, hi):
        self.formes.append((f, col, np.asarray(lo, float), np.asarray(hi, float)))
        return self

    def ellipsoide(self, c, r, col):
        c, r = np.asarray(c, float), np.asarray(r, float)
        return self._add(lambda P: np.sqrt((((P - c) / r) ** 2).sum(-1)) - 1.0, col, c - r, c + r)

    def boite(self, c, demi, col):
        c, h = np.asarray(c, float), np.asarray(demi, float)
        return self._add(lambda P: (np.abs(P - c) - h).max(-1), col, c - h, c + h)

    def capsule(self, a, b, r0, r1, col):
        a, b = np.asarray(a, float), np.asarray(b, float)
        ab = b - a
        L2 = float(ab @ ab) + 1e-9

        def f(P):
            t = np.clip(((P - a) @ ab) / L2, 0.0, 1.0)
            q = a + t[..., None] * ab
            return np.linalg.norm(P - q, axis=-1) - (r0 + (r1 - r0) * t)
        m = max(r0, r1)
        return self._add(f, col, np.minimum(a, b) - m, np.maximum(a, b) + m)

    def chaine(self, pts, rayons, col):
        """Une suite de capsules (un cou, une queue, une branche qui ploie)."""
        for k in range(len(pts) - 1):
            self.capsule(pts[k], pts[k + 1], rayons[k], rayons[k + 1], col)
        return self

    def cone(self, base, sommet, r, col):
        return self.capsule(base, sommet, r, self.s * 0.3, col)

    def voxels(self):
        lo = np.min([f[2] for f in self.formes], 0) - self.s
        hi = np.max([f[3] for f in self.formes], 0) + self.s
        s = self.s
        shape = np.ceil((hi - lo) / s).astype(int) + 1
        g = np.stack(np.meshgrid(*[lo[k] + (np.arange(shape[k]) + 0.5) * s for k in range(3)], indexing="ij"), -1)
        vox = np.zeros(shape, np.int16)
        for (f, col, flo, fhi) in self.formes:
            if isinstance(col, str):
                col = COULEURS[col]
            i0 = np.clip(np.floor((flo - lo) / s).astype(int) - 1, 0, shape - 1)
            i1 = np.clip(np.ceil((fhi - lo) / s).astype(int) + 2, 0, shape)
            sub = g[i0[0]:i1[0], i0[1]:i1[1], i0[2]:i1[2]]
            d = f(sub)
            inside = d <= 0.0
            if callable(col):
                cv = col(sub)
                vox[i0[0]:i1[0], i0[1]:i1[1], i0[2]:i1[2]] = np.where(inside, cv, vox[i0[0]:i1[0], i0[1]:i1[1], i0[2]:i1[2]])
            else:
                vox[i0[0]:i1[0], i0[1]:i1[1], i0[2]:i1[2]] = np.where(inside, col, vox[i0[0]:i1[0], i0[1]:i1[1], i0[2]:i1[2]])
        return vox, lo

    def creuser_ellipsoide(self, c, r):
        """Creuser (vider) un volume : la forme vaut « vide »."""
        c, r = np.asarray(c, float), np.asarray(r, float)
        return self._add(lambda P: np.sqrt((((P - c) / r) ** 2).sum(-1)) - 1.0, 0, c - r, c + r)

    def creuser_capsule(self, a, b, r):
        n0 = len(self.formes)
        self.capsule(a, b, r, r, 0)
        return self

    def export(self, palette, seed=1, var=0.07, bord_plein=False):
        vox, lo = self.voxels()
        return maillage.export(vox, palette, self.s, origin=lo, seed=seed, var=var, bord_plein=bord_plein)


def pal_index(palette):
    """Les noms des couleurs → indices (1…)."""
    return {k: i + 1 for i, k in enumerate(palette)}
