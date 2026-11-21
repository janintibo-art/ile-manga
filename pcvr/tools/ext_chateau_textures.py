#!/usr/bin/env python3
"""Extension « Le Château d'Ombrelac » : fabrique les textures du château (une seule fois, sur le
PC de l'auteur ; les PNG sont dans www/assets/textures/ext_chateau/).

    python3 pcvr/tools/ext_chateau_textures.py

- pierre_ombrelac(.png, _n.png) : un appareil de pierre de taille (calcaire gris-blond), des assises
  de hauteurs inégales, des blocs de longueurs variées, les arêtes un peu épaufrées, des joints de
  mortier en creux ; 4 m de côté, se répète sans couture.
- pierre_claire_ombrelac(.png, _n.png) : la pierre fine des encadrements, des moulures (des blocs
  plus réguliers, plus clairs, un grain plus fin) ; 2 m de côté.
- dalles_ombrelac(.png, _n.png) : les grandes dalles usées des cours et des salles ; 4 m de côté.
Tout est aléatoire mais à graine fixe : on retrouve toujours les mêmes images.
"""
from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "www", "assets", "textures", "ext_chateau")
N = 1024


def bruit(rng: np.random.Generator, n: int, echelle: float, pente: float = 2.0) -> np.ndarray:
    """Un bruit périodique (filtré dans les fréquences) : rien ne se voit au raccord."""
    f = np.fft.fftfreq(n)[:, None] ** 2 + np.fft.fftfreq(n)[None, :] ** 2
    f = np.sqrt(f) * n / echelle
    amp = 1.0 / np.maximum(f, 1.0) ** pente
    amp[0, 0] = 0.0
    ph = rng.standard_normal((n, n)) + 1j * rng.standard_normal((n, n))
    b = np.real(np.fft.ifft2(ph * amp))
    b -= b.min()
    return b / max(b.max(), 1e-9)


def lisse(x: np.ndarray, a: float, b: float) -> np.ndarray:
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def normales(h: np.ndarray, force: float) -> np.ndarray:
    gx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * force
    gy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5 * force
    n = np.stack([-gx, gy, np.ones_like(h)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return ((n * 0.5 + 0.5) * 255).astype(np.uint8)


def appareil(seed: int, metres: float, assises: tuple, longueurs: tuple, palette: list, joint_cm: float,
             epaufrure: float, grain: float) -> tuple:
    rng = np.random.default_rng(seed)
    px = N / metres
    # les assises (leur hauteur en pixels ; la somme fait toute l'image)
    hs = []
    while sum(hs) < N:
        hs.append(rng.uniform(*assises) * px)
    hs = np.array(hs[:-1] if sum(hs[:-1]) > N * 0.92 else hs)
    hs = hs * N / hs.sum()
    ys = np.concatenate([[0], np.cumsum(hs)])
    bloc_id = np.zeros((N, N), np.int32)
    dist = np.full((N, N), 1e9)            # la distance au joint le plus proche (pixels)
    xx = np.arange(N)
    nid = 0
    infos = []
    for r in range(len(hs)):
        y0, y1 = int(round(ys[r])), int(round(ys[r + 1]))
        # les blocs de l'assise (ils tournent autour : le dernier rejoint le premier)
        xs = [rng.uniform(0, N)]
        while True:
            nxt = xs[-1] + rng.uniform(*longueurs) * px
            if nxt - xs[0] > N - longueurs[0] * px * 0.6:
                break
            xs.append(nxt)
        xs = np.array(xs)
        rel = (xx[None, :] - xs[0]) % N
        starts = xs - xs[0]
        k = np.searchsorted(starts, rel[0], side="right") - 1
        ends = np.append(starts[1:], N)
        dx = np.minimum(rel[0] - starts[k], ends[k] - rel[0])
        for y in range(y0, y1):
            dy = min(y - y0, y1 - 1 - y)
            bloc_id[y] = nid + k
            dist[y] = np.minimum(dx, dy)
        for _ in range(len(xs)):
            infos.append(rng.random(4))
        nid += len(xs)
    infos = np.array(infos)
    # la couleur de chaque bloc : une teinte de la palette, plus ou moins claire
    pal = np.array(palette)
    choix = (infos[:, 0] * len(pal)).astype(int).clip(0, len(pal) - 1)
    col_bloc = pal[choix] * (0.9 + 0.14 * infos[:, 1])[:, None]
    col = col_bloc[bloc_id]
    # le grain de la pierre, des veines, des taches
    g1 = bruit(rng, N, 220.0 * grain, 1.6)
    g2 = bruit(rng, N, 60.0 * grain, 1.2)
    g3 = bruit(rng, N, 12.0, 2.2)
    # les lits du calcaire : de fines strates horizontales, ondulées
    yy = np.arange(N)[:, None] + 6.0 * g1
    lits = 0.5 + 0.5 * np.sin(yy / N * np.pi * 2.0 * 37.0 + g2 * 3.0)
    col *= (0.86 + 0.2 * g1[..., None]) * (0.95 + 0.07 * g2[..., None]) * (0.97 + 0.05 * lits[..., None])
    col *= (1.0 - 0.1 * lisse(g3, 0.62, 0.85))[..., None]
    # la crasse : le haut de chaque bloc un peu plus sombre (l'eau ruisselle du joint)
    col *= (1.0 - 0.06 * lisse(g1, 0.6, 0.9))[..., None]
    # les arêtes : épaufrées (le joint mange un peu le bloc, au hasard)
    joint = joint_cm / 100.0 * px
    ronge = epaufrure * px * lisse(bruit(rng, N, 30.0, 1.4), 0.35, 0.9)
    d = dist - joint - ronge
    biseau = lisse(d, 0.0, 0.05 * px) ** 0.7
    # la hauteur : le bloc bombé, le biseau, le grain, des petits trous
    trous = lisse(bruit(rng, N, 6.0, 0.6), 0.9, 0.97)
    bombe = 0.15 * (infos[:, 2][bloc_id])
    h = biseau * (0.75 + bombe + 0.25 * g2 + 0.05 * g3 - 0.2 * trous)
    # le mortier
    mortier = np.array([0.58, 0.56, 0.52]) * (0.85 + 0.2 * g2[..., None])
    a = lisse(d, -0.5, 1.5)[..., None]
    col = col * a + mortier * (1.0 - a)
    # l'ombre au fond des joints, les arêtes un peu plus claires (usées)
    col *= (0.8 + 0.2 * lisse(d, 0.0, 0.05 * px))[..., None]
    col = col * (1.0 - trous[..., None] * 0.35)
    alb = (np.clip(col, 0, 1) ** (1 / 1.0) * 255).astype(np.uint8)
    return alb, normales(h, 8.0 * N / 1024)


def main() -> int:
    os.makedirs(OUT, exist_ok=True)
    calcaire = [[0.72, 0.68, 0.6], [0.68, 0.65, 0.59], [0.74, 0.69, 0.59], [0.65, 0.63, 0.58], [0.7, 0.65, 0.56]]
    alb, nm = appareil(1881, 4.0, (0.34, 0.56), (0.55, 1.35), calcaire, 0.7, 0.02, 1.0)
    Image.fromarray(alb).save(os.path.join(OUT, "pierre_ombrelac.png"), optimize=True)
    Image.fromarray(nm).save(os.path.join(OUT, "pierre_ombrelac_n.png"), optimize=True)
    claire = [[0.86, 0.82, 0.72], [0.82, 0.79, 0.71], [0.88, 0.82, 0.7]]
    alb, nm = appareil(1882, 2.0, (0.3, 0.32), (0.7, 1.0), claire, 0.45, 0.008, 0.5)
    Image.fromarray(alb).save(os.path.join(OUT, "pierre_claire_ombrelac.png"), optimize=True)
    Image.fromarray(nm).save(os.path.join(OUT, "pierre_claire_ombrelac_n.png"), optimize=True)
    dalles = [[0.6, 0.58, 0.54], [0.55, 0.54, 0.52], [0.64, 0.6, 0.53], [0.5, 0.5, 0.5]]
    alb, nm = appareil(1883, 4.0, (0.7, 1.0), (0.7, 1.3), dalles, 0.6, 0.04, 1.3)
    Image.fromarray(alb).save(os.path.join(OUT, "dalles_ombrelac.png"), optimize=True)
    Image.fromarray(nm).save(os.path.join(OUT, "dalles_ombrelac_n.png"), optimize=True)
    print("textures écrites dans", os.path.normpath(OUT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
