"""V115 : la Fosse d'Azur, au fond de la mer, sous les falaises du sud de Hautefond.

Une fosse abyssale, à cent quarante mètres sous la surface, où sont posés les trois dômes du Dôme
d'Azur (le Grand Dôme, le Dôme des Serres à l'ouest, le Dôme de l'Institut à l'est) :
  le FOND        du sable fin, de longues rides, des cailloux ; aplani sous les dômes (leurs socles) ;
  les PAROIS     des falaises de basalte bleu-gris, qui s'évasent en montant (elles se perdent dans le
                 bleu bien avant le haut de la fosse) ;
  le CANYON      au nord-nord-est, un ravin qui monte vers l'île : le tube du Funiculaire d'Azur le
                 descend sur ses pylônes ; au bout, la falaise et le TUNNEL où la cabine attend ;
  la FAILLE     au sud du Grand Dôme, une faille étroite qui plonge dans le noir (sous le Belvédère) ;
  les ROCHERS    des blocs et des aiguilles posés sur le fond ;
  la CHEMINÉE    une cheminée hydrothermale (à l'est, devant le Dôme de l'Institut).
La fosse est décrite par une fonction de distance (le creux = l'eau), bosselée par un bruit en trois
dimensions, puis taillée en triangles (marching cubes), comme les Strates (V114). On garde, pour le jeu :
  parts       la roche en morceaux (blocs de 32 m x 32 m), chacun avec v, n, i (sommets, normales
              tournées vers l'eau, triangles) et c (par sommet : ouverture, sédiment, sol, cheminée) ;
  eponges     des points du fond (les éponges de verre) ;
  gorgones    des points des rochers et du bas des parois (les gorgones, et leurs normales) ;
  lueurs      des points des parois, de la Faille et des rochers (les bêtes qui luisent, et leurs normales) ;
  anemones    des points du fond près des dômes (les anémones qui luisent) ;
  lys         des points du fond (les lys de mer) ;
  cailloux    des points du fond (des pierres) ;
  vers        des points autour de la cheminée (les vers géants).
Repère : local au Dôme d'Azur (x vers l'est, z vers le sud, depuis le centre du Grand Dôme ; y : au-dessus
du sol du Grand Dôme). Gardé en accord avec fosse_azur_v115.gd (les mêmes constantes).

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_fosse_v115.py
"""
from __future__ import annotations

from math import cos, radians, sin
from pathlib import Path
import sys

import numpy as np
from scipy import ndimage
from skimage import measure

sys.path.insert(0, str(Path(__file__).resolve().parent / "habitants_v64"))
import gdvar  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "models" / "dome115"

STEP = 1.25
LO = np.array([-220.0, -48.0, -216.0])
HI = np.array([220.0, 86.0, 122.0])

# la fosse (le fond, au pied des parois : un ovale)
A0, B0 = 202.0, 106.0
# les dômes : (x, z, rayon)
DOMES = [(0.0, 0.0, 70.0), (-128.0, -16.0, 32.0), (124.0, 22.0, 32.0)]
# le Funiculaire : direction, le tube (plat jusqu'à r = 92, puis montant jusqu'au portail), le tunnel
LDEG = -66.0
LDIR = np.array([cos(radians(LDEG)), sin(radians(LDEG))])
L_FLAT = 92.0
L_PORTAL = 200.0
L_END = 219.0
AXE_BAS = 2.5
AXE_HAUT = 39.5
R_TUBE = 3.4
CANYON_END = 206.0
# la Faille d'Azur (au sud du Grand Dôme) : son axe z = FAILLE_Z + 4 sin(0,03 x), de -FAILLE_X à FAILLE_X
FAILLE_Z = 90.0
FAILLE_X = 95.0
FAILLE_FOND = -44.0
# la cheminée hydrothermale
VENT = np.array([172.0, 54.0])
VENT_H = 15.0


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
    return lattice_noise(p, 18.0, 1151) * 0.5 + lattice_noise(p, 7.0, 1152) * 0.32 + lattice_noise(p, 2.6, 1153) * 0.18


def line_r(x, z):
    """(distance le long de la ligne du Funiculaire, distance de côté)."""
    r = x * LDIR[0] + z * LDIR[1]
    side = np.abs(-x * LDIR[1] + z * LDIR[0])
    return r, side


def tube_axis_y(r):
    return np.where(r < L_FLAT, AXE_BAS, np.where(r < L_PORTAL, AXE_BAS + (r - L_FLAT) * (AXE_HAUT - AXE_BAS) / (L_PORTAL - L_FLAT), AXE_HAUT))


def canyon_floor(r):
    return np.maximum(-1.4, tube_axis_y(r) - R_TUBE - 7.0)


def dunes(x, z):
    p = np.stack([x, np.zeros_like(x), z], -1)
    rides = np.sin(x * 0.21 + z * 0.09 + lattice_noise(p, 30.0, 1161) * 2.0) * 0.18
    return lattice_noise(p, 22.0, 1162) * 0.45 + rides


def floor_y(x, z):
    """Le fond de la fosse (sans les rochers)."""
    e = np.sqrt((x / A0) ** 2 + (z / B0) ** 2)
    f = -1.35 + dunes(x, z)
    # le fond remonte doucement au pied des parois
    f = f + 16.0 * np.clip((e - 0.82) / 0.24, 0.0, 1.0) ** 2
    # les socles des dômes : le fond bien plat tout autour
    for dx, dz, rr in DOMES:
        d = np.hypot(x - dx, z - dz)
        k = 1.0 - np.clip((d - rr - 5.0) / 10.0, 0.0, 1.0)
        f = f * (1.0 - k) + (-0.95) * k
    return f


def basin(p, nz):
    x, y, z = p[:, 0], p[:, 1], p[:, 2]
    up = np.maximum(y, 0.0)
    a = A0 + up * 0.18
    b = B0 + up * 0.16
    e = np.sqrt((x / a) ** 2 + (z / b) ** 2)
    d_wall = (e - 1.0) * np.minimum(a, b) + nz * 4.2
    d_floor = floor_y(x, z) - y + nz * 0.25
    return np.maximum(d_wall, d_floor)


def canyon(p, nz):
    x, y, z = p[:, 0], p[:, 1], p[:, 2]
    r, side = line_r(x, z)
    fy = canyon_floor(r)
    hw = 21.0 + 0.32 * np.maximum(y - fy, 0.0)
    d = np.maximum(side - hw + nz * 3.0, np.maximum(r - CANYON_END + nz * 2.0, 40.0 - r))
    return np.maximum(d, fy - y + nz * 0.4)


def tunnel(p):
    x, y, z = p[:, 0], p[:, 1], p[:, 2]
    r, side = line_r(x, z)
    perp = np.sqrt(side ** 2 + (y - AXE_HAUT) ** 2)
    return np.maximum(perp - (R_TUBE + 0.4), np.maximum(r - L_END, 194.0 - r))


def faille_zc(x):
    return FAILLE_Z + 4.0 * np.sin(x * 0.03)


def faille(p, nz):
    x, y, z = p[:, 0], p[:, 1], p[:, 2]
    hw = 4.0 + 6.5 * np.clip((y - FAILLE_FOND) / -FAILLE_FOND, 0.0, 1.0)
    hw = hw * (1.0 - 0.6 * np.clip((np.abs(x) - FAILLE_X + 25.0) / 25.0, 0.0, 1.0))
    d = np.maximum(np.abs(z - faille_zc(x)) - hw + nz * 1.4, np.abs(x) - FAILLE_X)
    return np.maximum(d, FAILLE_FOND - y)


ROCKS: list = []


def _make_rocks():
    rng = np.random.default_rng(11505)
    tries = 0
    while len(ROCKS) < 46 and tries < 4000:
        tries += 1
        x = rng.uniform(-195.0, 195.0)
        z = rng.uniform(-100.0, 100.0)
        if np.sqrt((x / A0) ** 2 + (z / B0) ** 2) > 0.93:
            continue
        if not _clear(np.array([x]), np.array([z]), 9.0)[0]:
            continue
        if any(np.hypot(x - q[0], z - q[2]) < q[3] + 14.0 for q in ROCKS):
            continue
        rr = rng.uniform(1.6, 5.5)
        tall = rng.uniform(0.7, 2.6) if rng.random() < 0.35 else rng.uniform(0.5, 1.0)
        ROCKS.append((x, -1.2, z, rr, tall))


def _clear(x, z, margin):
    """Loin des dômes, des galeries, du tube du Funiculaire (pour les rochers et le décor)."""
    ok = np.ones(len(x), dtype=bool)
    for dx, dz, rr in DOMES:
        ok &= np.hypot(x - dx, z - dz) > rr + margin
    for (ax, az, ar), (bx, bz, br) in ((DOMES[0], DOMES[1]), (DOMES[0], DOMES[2])):
        a = np.array([ax, az])
        b = np.array([bx, bz])
        ab = b - a
        t = np.clip(((np.stack([x, z], -1) - a) @ ab) / (ab @ ab), 0.0, 1.0)
        q = a + t[:, None] * ab
        ok &= np.hypot(x - q[:, 0], z - q[:, 1]) > 3.4 + margin
    r, side = line_r(x, z)
    ok &= ~((r > 50.0) & (side < 4.0 + margin))
    ok &= ~((np.abs(x) < FAILLE_X + 3.0) & (np.abs(z - faille_zc(x)) < 12.0 + margin * 0.5))
    return ok


def rocks_sdf(p, nz):
    out = np.full(len(p), 1e9)
    for x, y, z, rr, tall in ROCKS:
        q = (p - np.array([x, y, z])) / np.array([rr, rr * tall, rr])
        d = (np.sqrt(q[:, 0] ** 2 + q[:, 1] ** 2 + q[:, 2] ** 2) - 1.0) * rr
        out = np.minimum(out, d + nz * 0.9)
    # la cheminée hydrothermale : un cône bosselé, ses trois évents
    x, y, z = p[:, 0], p[:, 1], p[:, 2]
    dv = np.hypot(x - VENT[0], z - VENT[1])
    t = np.clip((y + 1.2) / VENT_H, 0.0, 1.0)
    rad = 4.2 * (1.0 - t) + 1.1 * t
    d = np.maximum(dv - rad + nz * 0.7, np.maximum(y - VENT_H + 1.2, -1.6 - y))
    out = np.minimum(out, d)
    for k, (ox, oz, hh) in enumerate(((5.0, 2.0, 7.0), (-3.5, 4.0, 9.5), (2.0, -4.5, 5.0))):
        dv2 = np.hypot(x - VENT[0] - ox, z - VENT[1] - oz)
        t2 = np.clip((y + 1.2) / hh, 0.0, 1.0)
        d2 = np.maximum(dv2 - (1.8 * (1.0 - t2) + 0.6 * t2) + nz * 0.4, np.maximum(y - hh + 1.2, -1.6 - y))
        out = smin(out, d2, 1.2)
    return out


def sdf(p, with_noise=True):
    nz = fbm(p) if with_noise else np.zeros(len(p))
    water = smin(basin(p, nz), canyon(p, nz), 6.0)
    water = np.minimum(water, tunnel(p))
    water = np.minimum(water, faille(p, nz))
    rock = rocks_sdf(p, nz)
    return np.maximum(water, -rock)


def main() -> int:
    _make_rocks()
    nx, ny, nz = (np.ceil((HI - LO) / STEP).astype(int) + 1)
    gx = LO[0] + np.arange(nx) * STEP
    gy = LO[1] + np.arange(ny) * STEP
    gz = LO[2] + np.arange(nz) * STEP
    vol = np.empty((nx, ny, nz), dtype=np.float32)
    YY, ZZ = np.meshgrid(gy, gz, indexing="ij")
    for i in range(nx):
        P = np.stack([np.full(YY.size, gx[i]), YY.ravel(), ZZ.ravel()], -1)
        vol[i] = sdf(P).reshape(ny, nz)
    # la fosse reste ouverte vers le haut (la mer) ; fermée sur les autres bords
    vol[0, :, :] = vol[-1, :, :] = 5.0
    vol[:, 0, :] = 5.0
    vol[:, :, 0] = vol[:, :, -1] = 5.0
    verts, faces, _, _ = measure.marching_cubes(vol, 0.0, spacing=(STEP, STEP, STEP))
    verts = verts + LO
    # on enlève le « couvercle » (les triangles tout en haut de la boîte)
    top = verts[:, 1] > HI[1] - STEP * 0.6
    keep = ~(top[faces[:, 0]] & top[faces[:, 1]] & top[faces[:, 2]])
    faces = faces[keep]
    e = 0.2
    g = np.stack([sdf(verts + np.array(dv)) - sdf(verts - np.array(dv)) for dv in ((e, 0, 0), (0, e, 0), (0, 0, e))], -1)
    n_in = -g / (np.linalg.norm(g, axis=1, keepdims=True) + 1e-9)
    a, b, c = verts[faces[:, 0]], verts[faces[:, 1]], verts[faces[:, 2]]
    fn = np.cross(b - a, c - a)
    face_in = n_in[faces[:, 0]] + n_in[faces[:, 1]] + n_in[faces[:, 2]]
    ccw_in = np.einsum("ij,ij->i", fn, face_in) > 0
    faces = np.where(ccw_in[:, None], faces[:, [0, 2, 1]], faces)
    # occlusion approchée
    o1 = np.clip(-sdf(verts + n_in * 1.5, False) / 1.5, 0, 1)
    o2 = np.clip(-sdf(verts + n_in * 6.0, False) / 6.0, 0, 1)
    ao = np.clip(0.25 + 0.35 * o1 + 0.45 * o2, 0, 1)
    x, y, z = verts[:, 0], verts[:, 1], verts[:, 2]
    fy = floor_y(x, z)
    r_l, side_l = line_r(x, z)
    fy = np.where((r_l > 60.0) & (side_l < 30.0), np.minimum(fy, canyon_floor(r_l)), fy)
    above = y - fy
    is_floor = (n_in[:, 1] > 0.8) & (above < 1.5)
    sediment = np.clip((n_in[:, 1] - 0.45) / 0.4, 0, 1)
    dv = np.hypot(x - VENT[0], z - VENT[1])
    vent = np.clip(1.0 - dv / 14.0, 0, 1)
    col = np.stack([ao, sediment, is_floor.astype(float), vent], -1)
    rng = np.random.default_rng(11500)
    flo = np.flatnonzero(is_floor & _clear(x, z, 2.5) & (np.sqrt((x / A0) ** 2 + (z / B0) ** 2) < 0.97))

    def pick(idx, n, spacing):
        out = []
        for k in rng.permutation(idx):
            pnt = verts[k]
            if all(np.linalg.norm(pnt - s) > spacing for s in out[-60:]) and all(np.linalg.norm(pnt[[0, 2]] - s[[0, 2]]) > spacing * 0.6 for s in out):
                out.append(pnt)
            if len(out) >= n:
                break
        return np.array(out) if out else np.zeros((0, 3))

    # près des dômes (là où on les voit à travers le verre), plus serré
    near = np.zeros(len(verts), dtype=bool)
    for dx, dz, rr in DOMES:
        near |= np.hypot(x - dx, z - dz) < rr + 26.0
    eponges = pick(np.intersect1d(flo, np.flatnonzero(near)), 150, 5.0)
    anemones = pick(np.intersect1d(flo, np.flatnonzero(near)), 320, 1.8)
    lys = pick(flo, 160, 4.0)
    cailloux = pick(flo, 600, 1.4)
    # les gorgones : les flancs des rochers et le bas des parois (tournés de côté)
    side_pts = np.flatnonzero((np.abs(n_in[:, 1]) < 0.45) & (above < 14.0) & (above > 0.4) & (dv > 9.0))
    gorg = []
    for k in rng.permutation(side_pts):
        pnt = verts[k]
        if all(np.linalg.norm(pnt - s) > 3.5 for s in gorg[-80:]):
            gorg.append(pnt)
        if len(gorg) >= 260:
            break
    gorg = np.array(gorg)
    gorg_n = n_in[[int(np.argmin(np.linalg.norm(verts - s, axis=1))) for s in gorg]] if len(gorg) else np.zeros((0, 3))
    # les lueurs : des grappes de bêtes qui luisent (bioluminescence) sur les parois, la Faille et les
    # flancs des rochers ; un tirage régulier (grille de hachage de 3 m)
    wall = np.flatnonzero((np.abs(n_in[:, 1]) < 0.7) & (above > 1.0) & (dv > 9.0) & (y < 60.0))
    cell = 3.2
    seen = set()
    lueurs = []
    for k in rng.permutation(wall):
        pnt = verts[k]
        ck = (int(pnt[0] // cell), int(pnt[1] // cell), int(pnt[2] // cell))
        if ck in seen:
            continue
        seen.add(ck)
        lueurs.append(k)
        if len(lueurs) >= 1400:
            break
    lueurs_p = verts[lueurs] if lueurs else np.zeros((0, 3))
    lueurs_n = n_in[lueurs] if lueurs else np.zeros((0, 3))
    # les vers géants : en couronne au pied de la cheminée
    vers = []
    for k in range(70):
        a_ = rng.uniform(0, 2 * np.pi)
        rr = rng.uniform(4.6, 9.5)
        px, pz = VENT[0] + cos(a_) * rr, VENT[1] + sin(a_) * rr
        py = float(floor_y(np.array([px]), np.array([pz]))[0])
        vers.append([px, py, pz])
    vers = np.array(vers)
    # en morceaux de 32 m x 32 m
    cen = verts[faces].mean(axis=1)
    key = np.floor((cen[:, 0] - LO[0]) / 32.0).astype(int) * 100 + np.floor((cen[:, 2] - LO[2]) / 32.0).astype(int)
    parts = []
    for k in np.unique(key):
        fk = faces[key == k]
        used, inv = np.unique(fk.ravel(), return_inverse=True)
        parts.append({"v": gdvar.v3(verts[used]), "n": gdvar.v3(n_in[used]), "c": gdvar.col4(col[used]),
                      "i": gdvar.i32(inv.reshape(-1, 3))})
    OUT.mkdir(parents=True, exist_ok=True)
    d = {
        "parts": parts,
        "eponges": gdvar.v3(eponges), "anemones": gdvar.v3(anemones), "lys": gdvar.v3(lys),
        "cailloux": gdvar.v3(cailloux), "gorgones": gdvar.v3(gorg), "gorgones_n": gdvar.v3(gorg_n),
        "vers": gdvar.v3(vers), "lueurs": gdvar.v3(lueurs_p), "lueurs_n": gdvar.v3(lueurs_n),
        "rochers": gdvar.f32(np.array(ROCKS)),
    }
    raw, comp = gdvar.save(OUT / "fosse.bin", d)
    print(f"fosse : {len(verts)} sommets, {len(faces)} triangles en {len(parts)} morceaux, {len(eponges)} éponges, "
          f"{len(anemones)} anémones, {len(lys)} lys, {len(gorg)} gorgones, {len(lueurs_p)} lueurs, {len(ROCKS)} rochers ; {comp // 1024} Ko")
    return 0


if __name__ == "__main__":
    sys.exit(main())
