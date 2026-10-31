"""V90 : le relief de l'Île Pixelithique, en blocs de 50 cm.

Repère « île » : origine au CENTRE (gardé en accord avec ile_pixel_v90.gd), x vers l'est, z vers le
sud. Une grille de blocs (BLOC = 0,5 m) : pour chaque bloc, sa hauteur en niveaux (0,5 m) et sa
matière. Le maillage, la collision et height() du jeu se lisent dans la même grille.

Les lieux :
  le Mont Fumant (nord-est)       un volcan, son cratère et son lac de lave ;
  les Falaises du Clan (ouest)    un grand plateau ; sa face est tombe à pic : les grottes ;
  le Campement (au pied)          le feu, les séchoirs, le totem ;
  le Lac des Long-Cous (sud-ouest) une eau calme où marchent les brachiosaures ;
  le Cirque des Os (nord)         l'arène ronde de Grosse-Dent, le tyrannosaure ;
  la Plaine des Cornes (nord-ouest) les tricératops ;
  la Jungle des Fougères (est)    fougères géantes, prêles, cycas ;
  la Plage des Œufs (sud)         le ponton.
"""
from __future__ import annotations

import numpy as np
from scipy import ndimage

BLOC = 0.5
HALF = 180.0
N = int(HALF * 2 / BLOC)          # 720 blocs de côté
LEVEL = 0.5                       # un niveau = un bloc de haut
SEA_Y = -0.42

# matières (gardées en accord avec le shader pixel_terrain_v90)
SABLE, HERBE, JUNGLE, TERRE, PIERRE, BASALTE, LAVE, CENDRE, BOUE, MOUSSE, OS, PRAIRIE = range(12)

VOLCAN = (72.0, -72.0, 62.0, 40.0, 13.0, 31.0)      # x, z, rayon, hauteur, rayon du cratère, niveau de la lave
PLATEAU = (-108.0, 0.0, 34.0, 62.0, 17.0)           # x, z, demi-largeur (x), demi-longueur (z), hauteur
FALAISE_X = -74.0                                   # la face est du plateau (les grottes)
CAMP = (-50.0, 6.0, 20.0, 3.0)                      # x, z, rayon plat, hauteur
LAC = (-42.0, 78.0, 28.0, 1.5)                      # x, z, rayon, niveau de l'eau
CIRQUE = (-8.0, -118.0, 26.0, 6.0, 14.0)            # x, z, rayon de l'arène, sol, crête
PLAGE_Z = 112.0
DOCK_A = (22.0, 128.0)
DOCK_B = (22.0, 148.0)
CHEMINS = {
    "plage_camp": [(20.0, 124.0), (14.0, 100.0), (0.0, 70.0), (-14.0, 44.0), (-34.0, 18.0), (-46.0, 8.0)],
    "camp_lac": [(-48.0, 14.0), (-50.0, 34.0), (-46.0, 50.0)],
    "camp_cirque": [(-46.0, 0.0), (-40.0, -30.0), (-28.0, -62.0), (-14.0, -88.0), (-9.0, -96.0)],
    "plage_jungle": [(14.0, 100.0), (40.0, 74.0), (64.0, 46.0), (80.0, 20.0)],
    "jungle_volcan": [(80.0, 20.0), (74.0, -12.0), (66.0, -32.0)],
}


def coast_r(th):
    return (148.0 + 10.0 * np.sin(th * 3.0 + 0.6) + 7.0 * np.sin(th * 5.0 - 1.1) + 5.0 * np.sin(th * 9.0 + 2.0))


def smooth_noise(shape, sigma, seed):
    rng = np.random.default_rng(seed)
    g = rng.standard_normal(shape)
    g = ndimage.gaussian_filter(g, sigma, mode="wrap")
    return g / (g.std() + 1e-9)


def seg_dist(px, pz, a, b):
    ax, az = a
    bx, bz = b
    dx, dz = bx - ax, bz - az
    t = np.clip(((px - ax) * dx + (pz - az) * dz) / (dx * dx + dz * dz), 0, 1)
    return np.hypot(px - (ax + t * dx), pz - (az + t * dz))


def path_dist(px, pz, pts):
    d = np.full(px.shape, 1e9)
    for i in range(len(pts) - 1):
        d = np.minimum(d, seg_dist(px, pz, pts[i], pts[i + 1]))
    return d


def build():
    """Renvoie (niveaux int16 N×N, matières uint8 N×N, hauteurs lisses float32 N×N)."""
    c = (np.arange(N) + 0.5) * BLOC - HALF
    X, Z = np.meshgrid(c, c, indexing="xy")        # [z, x]
    r = np.hypot(X, Z)
    th = np.arctan2(Z, X)
    n_big = smooth_noise((N, N), 40, 901)
    n_mid = smooth_noise((N, N), 14, 902)
    n_small = smooth_noise((N, N), 4, 903)
    cr = coast_r(th) + n_big * 6.0
    inland = np.clip((cr - r) / 22.0, -1.0, 1.0)
    # la base : des collines douces, le fond de la mer au large
    h = 2.6 + 3.2 * np.clip(n_big * 0.6 + n_mid * 0.4 + 0.3, -0.5, 2.0) * np.clip(inland, 0, 1)
    deep = np.clip((r - cr - 10.0) / 28.0, 0, 1) ** 1.2 * 28.0           # au large, le fond plonge (comme la mer autour)
    h = np.where(inland > 0, h * np.clip(inland * 1.6, 0, 1) + 0.4 * (1 - np.clip(inland * 1.6, 0, 1)), 0.4 + inland * 8.0 - deep)
    # la plage du sud : basse et plate
    plage = np.clip((Z - (PLAGE_Z - 26.0)) / 22.0, 0, 1) * np.clip(inland * 3, 0, 1)
    h = h * (1 - plage) + (0.4 + 0.6 * np.clip(inland * 2.5, 0, 1)) * plage
    # le Mont Fumant
    vx, vz, vr, vh, vcr, vlava = VOLCAN
    dv = np.hypot(X - vx, Z - vz) + n_mid * 2.5
    cone = vh * np.clip(1.0 - dv / vr, 0, 1) ** 1.25
    h = np.where(cone > 0.05, np.maximum(h, cone + 1.0), h)
    crater = np.clip(1.0 - dv / vcr, 0, 1)
    h = np.where(dv < vcr + 3.0, np.minimum(h, vlava - 0.5 + (h - vlava) * np.clip((dv - vcr) / 3.0, 0, 1)), h)
    # le plateau des Falaises du Clan (une face est à pic)
    px, pz, pw, pl, ph = PLATEAU
    qx = (X - px) / pw
    qz = (Z - pz) / pl
    mesa = np.clip(1.6 - np.sqrt(qx ** 2 + qz ** 2) * 1.6 + n_mid * 0.08, 0, 1)
    cliff_e = np.clip((FALAISE_X - X) / 2.0 + 0.5, 0, 1)            # la face est : très raide
    mesa = np.minimum(mesa * 3.0, 1.0) * cliff_e
    h = np.where(mesa > 0.01, np.maximum(h, ph * mesa + n_small * 0.4 * mesa), h)
    # le campement, au pied de la falaise
    cx, cz, crr, chh = CAMP
    dc = np.hypot(X - cx, Z - cz)
    k = np.clip((crr + 10.0 - dc) / 10.0, 0, 1) * (X > FALAISE_X + 0.5)
    h = h * (1 - k) + chh * k
    # le Lac des Long-Cous
    lx, lz, lr, ly = LAC
    dl = np.hypot(X - lx, Z - lz) + n_mid * 2.0
    bowl = np.clip((lr + 8.0 - dl) / 8.0, 0, 1)
    h = h * (1 - bowl) + (ly + 0.6) * bowl
    h = np.where(dl < lr, ly - 0.5 - 1.6 * np.clip((lr - dl) / 8.0, 0, 1), h)
    # le Cirque des Os : une arène plate dans un anneau de rochers, ouverte au sud
    ax, az, ar, ay, aw = CIRQUE
    da = np.hypot(X - ax, Z - az) + n_small * 0.6
    gap = (Z > az) & (np.abs(X - ax) < 6.0)
    ring = np.clip(1.0 - np.abs(da - ar - 4.0) / 6.0, 0, 1) * (~gap)
    h = np.where(da < ar + 1.0, ay, h)
    h = np.maximum(h, np.where(da < ar + 12.0, ay + (aw - ay) * ring + n_small * 0.8 * ring, -99))
    floor_k = np.clip((ar + 14.0 - da) / 6.0, 0, 1) * (da >= ar + 1.0) * (1 - ring)
    h = np.where((floor_k > 0) & (h < ay), h * (1 - floor_k) + ay * floor_k, h)
    # les chemins (un peu aplanis)
    dpath = np.full(X.shape, 1e9)
    for pts in CHEMINS.values():
        dpath = np.minimum(dpath, path_dist(X, Z, pts))
    sm = ndimage.gaussian_filter(h, 5)
    pk = np.clip((3.5 - dpath) / 2.0, 0, 1) * (inland > 0.1) * (h < 12)
    h = h * (1 - pk * 0.7) + sm * pk * 0.7
    # le ponton : un fond plat
    h = np.where(seg_dist(X, Z, DOCK_A, DOCK_B) < 3.0, np.minimum(h, -1.0), h)
    levels = np.round(h / LEVEL).astype(np.int16)
    levels = np.clip(levels, -80, 120)
    # ---------------------------------------------------------------- les matières
    top = levels * LEVEL
    gy, gx = np.gradient(levels.astype(float))
    steep = np.hypot(gx, gy)
    mat = np.full((N, N), HERBE, np.uint8)
    region_e = np.clip((X - 10.0) / 40.0, 0, 1) * np.clip((40.0 - np.abs(Z - 30.0)) / 40.0 + 0.5, 0, 1)
    mat[(region_e + n_mid * 0.25) > 0.55] = JUNGLE
    wp = np.clip((10.0 - X) / 40.0, 0, 1) * np.clip((-10.0 - Z) / 40.0, 0, 1) + n_mid * 0.18
    mat[wp > 0.4] = PRAIRIE
    mat[(top < 1.6) & (inland < 0.55)] = SABLE
    mat[plage > 0.5] = SABLE
    mat[top < 0.1] = SABLE
    mat[dpath < 1.6] = TERRE
    mat[(dl < lr + 4.0) & (top <= ly + 1.0)] = BOUE
    mat[steep > 1.6] = PIERRE
    mat[(mesa > 0.05) & (steep > 0.9)] = PIERRE
    mat[(mesa > 0.6) & (steep <= 0.9)] = PRAIRIE
    mat[((X > FALAISE_X - 3) & (X < FALAISE_X + 3)) & (mesa > 0.02) & (n_small > 0.3)] = MOUSSE
    vk = cone > 6.0
    mat[vk & (n_small > -0.4)] = BASALTE
    mat[vk & (n_small <= -0.4)] = CENDRE
    mat[(cone > 18.0) & (n_mid > 0.2)] = CENDRE
    mat[dv < vcr + 1.0] = LAVE
    mat[da < ar + 1.0] = OS
    mat[(ring > 0.2) & (da > ar)] = PIERRE
    mat[(dc < crr) & (dpath > 1.6)] = TERRE
    return levels, mat, h.astype(np.float32), {"dpath": dpath, "dl": dl, "lake": (dl < lr)}
