"""Textures de peau (espace UV MakeHuman, 2048) : variations de teint, masques (lèvres,
sourcils, barbe, cuir chevelu, paupières, joues), normales (grain, rides), occlusion."""
import numpy as np
from PIL import Image
from scipy import ndimage
from maps import body_maps
from uvraster import value_noise3, dilate, blur

from chemins import MPFB, cache
MPFB_TEX = MPFB + '/textures/'


def mpfb_mask(name, size):
    im = Image.open(MPFB_TEX + 'mpfb_%s.jpg' % name).convert('L').resize((size, size), Image.BILINEAR)
    return np.asarray(im).astype(np.float32) / 255.0


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def gauss(d, w):
    return np.exp(-(d / w) ** 2)


class Face:
    """coordonnées locales à la tête (origine entre les yeux, x gauche, y haut, z avant)."""

    def __init__(self, M):
        L = M['L']
        self.M = M
        self.L = L
        self.c = L['eyes_mid']
        H = M['P'] - self.c
        self.x, self.y, self.z = H[..., 0], H[..., 1], H[..., 2]
        self.ax = np.abs(self.x)
        self.N = M['N']
        self.mask = M['mask']
        self.eye_dx = abs(L['eye_l'][0] - L['eye_r'][0]) / 2
        self.nose_y = L['nose'][1] - self.c[1]
        self.chin_y = L['chin'][1] - self.c[1]
        self.top_y = L['top'][1] - self.c[1]
        self.front = L['front_z'] - self.c[2]
        self.head = (self.y > -0.16) & (self.y < 0.15) & (self.z > -0.2) & (self.ax < 0.1) & self.mask
        # angle autour de la tête : 0 devant, 90° aux oreilles, 180° derrière
        self.zc = (L['front_z'] + L['back_z']) / 2 - self.c[2]
        self.th = np.degrees(np.arctan2(self.ax, self.z - self.zc))
        # à l'avant du crâne (visage) : z au-dessus du plan des oreilles
        self.facing = self.N[..., 2]


def brow_curve(t):
    """t 0 (intérieur) -> 1 (extérieur) : (x, y) en m, côté gauche."""
    x = 0.009 + t * 0.047
    y = 0.016 + 0.012 * np.sin(np.clip(t, 0, 1) * np.pi * 0.85) - 0.006 * t
    return x, y


def paint_brows(F, size, seed=3):
    """densité des sourcils : traits fins (poils) le long de la courbe, plus denses au centre."""
    rng = np.random.default_rng(seed)
    res = 2400        # canevas frontal : 2400 px pour 0,16 m
    ext = 0.16
    can = np.zeros((res, res), np.float32)
    def to_px(x, y):
        return (x / ext + 0.5) * res, (0.5 - y / ext) * res
    from PIL import ImageDraw
    img = Image.new('F', (res, res), 0.0)
    d = ImageDraw.Draw(img)
    for side in (1, -1):
        for k in range(900):
            t = rng.random() ** 0.9
            bx, by = brow_curve(t)
            thick = 0.0085 * (1 - t) + 0.0035 * t
            off = (rng.random() - 0.5) * thick
            # direction des poils : vers le haut au départ, puis vers l'extérieur et un peu vers le bas
            ang = np.radians(75 - 95 * np.clip(t * 1.6, 0, 1)) + rng.normal(0, 0.12)
            ln = 0.0045 + rng.random() * 0.004
            x0 = bx + 0.0
            y0 = by + off - thick * 0.15
            x1 = x0 + np.cos(ang) * ln
            y1 = y0 + np.sin(ang) * ln
            # densité : plus clair aux bords de la bande et à l'extrémité
            a = (1 - abs(off) / thick * 1.4) * (1.0 - 0.45 * t)
            if a <= 0:
                continue
            p0 = to_px(side * x0, y0)
            p1 = to_px(side * x1, y1)
            d.line([p0, p1], fill=float(a), width=3)
    can = np.asarray(img)
    can = ndimage.gaussian_filter(can, 0.8)
    can = np.clip(can / 1.2, 0, 1)
    # échantillonnage aux texels du front
    m = F.head & (F.facing > 0.25) & (F.y > -0.01) & (F.y < 0.05) & (F.z > F.front - 0.07)
    u = (F.x / ext + 0.5) * res
    v = (0.5 - F.y / ext) * res
    out = np.zeros((size, size), np.float32)
    out[m] = ndimage.map_coordinates(can, [v[m], u[m]], order=1, mode='constant')
    return out


def interp_curve(xp, fp, x):
    return np.interp(x, xp, fp)


def regions(F, size):
    x, y, z, ax, th = F.x, F.y, F.z, F.ax, F.th
    head = F.head
    R = {}
    hd = head.astype(np.float32)
    R['levres'] = blur(mpfb_mask('lips', size), 1.0) * hd
    R['paupieres'] = mpfb_mask('eyelids', size) * hd
    R['oreilles'] = mpfb_mask('ears', size) * hd
    R['ongles'] = np.maximum(mpfb_mask('fingernails', size), mpfb_mask('toenails', size))
    R['aureoles'] = mpfb_mask('aureolae', size)
    lip = R['levres']
    ears = blur(R['oreilles'], 2.0)
    # --- cuir chevelu : ligne d'implantation selon l'angle autour de la tête
    hl = interp_curve([0, 25, 42, 55, 63, 70, 78, 100, 115, 140, 180],
                      [0.066, 0.062, 0.05, 0.034, 0.012, 0.0, 0.012, 0.012, -0.03, -0.075, -0.098], th)
    R['crane'] = head * smooth(hl - 0.002, hl + 0.007, y) * (1 - ears)
    # --- barbe
    nose_bot = -0.047
    lip_top = -0.0575
    lip_bot = -0.0795
    face = head * (th < 78)
    R['moustache'] = face * smooth(0.033, 0.024, ax) * smooth(nose_bot + 0.001, nose_bot - 0.004, y) * smooth(lip_top - 0.006, lip_top + 0.0, y) * (1 - lip)
    R['menton'] = face * smooth(0.045, 0.03, ax) * smooth(lip_bot + 0.001, lip_bot - 0.004, y) * smooth(-0.14, -0.115, y) * (1 - lip)
    cheek = interp_curve([0, 12, 25, 40, 55, 66, 72], [-0.045, -0.044, -0.038, -0.03, -0.018, -0.005, 0.004], th)
    jaw = head * smooth(73, 66, th) * smooth(cheek + 0.001, cheek - 0.008, y) * smooth(-0.15, -0.12, y) * (1 - lip)
    # le dessous de la mâchoire et le haut du cou (se fond plus bas)
    R['joues'] = jaw * (1 - np.maximum(R['moustache'], R['menton']) * 0.0) * smooth(0.012, 0.022, ax + smooth(-0.1, -0.12, y) * 0.03)
    # sourcils
    R['sourcils'] = paint_brows(F, size)
    # creux des yeux (ombre, fard)
    orb = np.zeros_like(x)
    for side in (1, -1):
        ex = side * F.eye_dx
        de = np.sqrt(((x - ex) / 1.2) ** 2 + ((y - 0.004) * 1.5) ** 2)
        orb = np.maximum(orb, gauss(de, 0.016))
    R['orbites'] = orb * face * (F.facing > 0)
    # joues (rose)
    blush = np.zeros_like(x)
    for side in (1, -1):
        d = np.sqrt((x - side * 0.043) ** 2 + ((y + 0.032) * 1.25) ** 2)
        blush = np.maximum(blush, gauss(d, 0.018))
    R['blush'] = blush * face
    R['nez'] = face * gauss(np.sqrt(x ** 2 + ((y + 0.03) * 0.8) ** 2), 0.016) * smooth(-0.005, 0.02, z)
    return R


def bake_ao(size=2048):
    """occlusion ambiante par cartes de profondeur (96 directions) sur le corps neutre."""
    from maps import neutral
    from export import welded_normals
    base, W, topo, Vw0, HJ, Vf = neutral()
    tris_s = topo.surfaces['peau'].reshape(-1, 3)
    Vs = Vw0[topo.split_w]
    tw = topo.split_w[tris_s]
    # échantillons de surface pour les cartes de profondeur
    rng = np.random.default_rng(1)
    A = Vw0[tw[:, 0]]; B = Vw0[tw[:, 1]]; C = Vw0[tw[:, 2]]
    area = np.linalg.norm(np.cross(B - A, C - A), axis=1) / 2
    nsamp = 900000
    idx = rng.choice(len(tw), nsamp, p=area / area.sum())
    r1 = np.sqrt(rng.random(nsamp)); r2 = rng.random(nsamp)
    S = A[idx] * (1 - r1)[:, None] + B[idx] * (r1 * (1 - r2))[:, None] + C[idx] * (r1 * r2)[:, None]
    N = welded_normals(topo, Vw0)
    used = np.unique(tw)
    Pv = Vw0[used]
    Nv = N[used]
    ndir = 96
    k = np.arange(ndir) + 0.5
    phi = np.arccos(1 - 2 * k / ndir)
    th = np.pi * (1 + 5 ** 0.5) * k
    dirs = np.stack([np.cos(th) * np.sin(phi), np.cos(phi), np.sin(th) * np.sin(phi)], 1)
    res = 1400
    lo = Vw0.min(0) - 0.05
    hi = Vw0.max(0) + 0.05
    ext = (hi - lo).max()
    cen = (lo + hi) / 2
    vis = np.zeros(len(used))
    wsum = np.zeros(len(used))
    for d in dirs:
        # repère caméra : d = direction vers la lumière (on regarde depuis +d)
        up = np.array([0, 1, 0]) if abs(d[1]) < 0.9 else np.array([1, 0, 0])
        ux = np.cross(up, d); ux /= np.linalg.norm(ux)
        uy = np.cross(d, ux)
        def proj(Q):
            q = Q - cen
            return ((q @ ux) / ext + 0.5) * res, ((q @ uy) / ext + 0.5) * res, q @ d
        sx, sy, sz = proj(S)
        ix = np.clip(sx.astype(int), 0, res - 1); iy = np.clip(sy.astype(int), 0, res - 1)
        zb = np.full((res, res), -9.0)
        np.maximum.at(zb, (iy, ix), sz)
        zb = ndimage.maximum_filter(zb, 3)
        vx, vy, vz = proj(Pv)
        jx = np.clip(vx.astype(int), 0, res - 1); jy = np.clip(vy.astype(int), 0, res - 1)
        cos = Nv @ d
        front = cos > 0
        visible = vz >= zb[jy, jx] - 0.006
        vis += front * visible * cos
        wsum += front * cos
    ao_v = np.ones(len(Vw0))
    ao_v[used] = vis / np.maximum(wsum, 1e-6)
    return ao_v, topo, Vw0


def normal_from_height(h, P, mask, strength=1.0):
    """hauteur (m) par texel -> normale tangente (convention Godot / OpenGL)."""
    # taille d'un texel en mètres (selon u et v)
    dPu = np.linalg.norm(np.roll(P, -1, 1) - P, axis=-1)
    dPv = np.linalg.norm(np.roll(P, -1, 0) - P, axis=-1)
    ok = mask & np.roll(mask, -1, 1) & np.roll(mask, -1, 0)
    tu = np.where(ok, dPu, np.nan)
    tv = np.where(ok, dPv, np.nan)
    med = np.nanmedian(tu)
    tu = np.where(np.isfinite(tu) & (tu > 1e-6), tu, med)
    tv = np.where(np.isfinite(tv) & (tv > 1e-6), tv, med)
    tu = ndimage.median_filter(tu, 5)
    tv = ndimage.median_filter(tv, 5)
    gu = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) / (2 * tu)
    gv = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) / (2 * tv)
    n = np.stack([-gu * strength, gv * strength, np.ones_like(h)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return n


def vertex_attr_to_tex(M, topo, attr_v):
    """attribut par sommet soudé -> carte UV (corps neutre)."""
    from uvraster import interp
    tris = topo.surfaces['peau'].reshape(-1, 3)
    a = attr_v[topo.split_w]
    if a.ndim == 1:
        a = a[:, None]
    out = interp(M['tid'], M['bary'], tris, a.astype(np.float32))
    return out[..., 0] if out.shape[-1] == 1 else out


def wrinkle_height(F):
    """rides de l'âge (hauteur en m, négatif = creux)."""
    x, y, z, ax, th = F.x, F.y, F.z, F.ax, F.th
    face = F.head * (th < 80)
    h = np.zeros_like(x)
    # front : 4 lignes horizontales ondulées
    for k, yy in enumerate((0.032, 0.041, 0.05, 0.058)):
        wav = yy + 0.0025 * np.sin(x * 70 + k) + 0.004 * (ax / 0.05) ** 2
        h -= 0.00035 * gauss(y - wav, 0.0012) * smooth(0.058, 0.03, ax) * face
    # rides du lion (entre les sourcils)
    for sx in (-1, 1):
        h -= 0.0003 * gauss(x - sx * 0.006, 0.0011) * gauss(y - 0.016, 0.008) * face
    # pattes d'oie : rayons au coin externe des yeux
    for sx in (-1, 1):
        cx, cy = sx * (F.eye_dx + 0.017), 0.0
        dx, dy = x - cx, y - cy
        r = np.sqrt(dx ** 2 + dy ** 2)
        ang = np.arctan2(dy, dx * sx)
        lines = np.cos(ang * 9.0) ** 8
        h -= 0.00028 * lines * smooth(0.004, 0.008, r) * smooth(0.024, 0.012, r) * (np.abs(ang) < 1.0) * face
    # sous les yeux
    for sx in (-1, 1):
        d = np.sqrt(((x - sx * F.eye_dx) / 1.4) ** 2 + ((y + 0.013) * 2.2) ** 2)
        h -= 0.0003 * gauss(d - 0.006, 0.0018) * (y < -0.006) * face
    # sillons naso-géniens : de l'aile du nez au coin de la bouche
    for sx in (-1, 1):
        t = np.clip((y - (-0.036)) / (-0.075 - (-0.036)), 0, 1)
        cxl = sx * (0.019 + 0.012 * t)
        d = np.abs(x - cxl)
        inside = (y < -0.034) & (y > -0.082)
        h -= 0.0009 * gauss(d, 0.0022) * inside * face
        h += 0.0005 * gauss(d - 0.004 * 1.0, 0.004) * inside * face * 0.6
    # plis d'amertume (coins de la bouche vers le menton)
    for sx in (-1, 1):
        t = np.clip((y - (-0.07)) / (-0.098 - (-0.07)), 0, 1)
        cxl = sx * (0.026 + 0.004 * t)
        h -= 0.0005 * gauss(np.abs(x - cxl), 0.002) * (y < -0.068) * (y > -0.1) * face
    # lèvres : fines rides verticales
    lip = F.lips_soft
    h -= 0.00012 * (np.cos(x * 900) ** 6) * lip
    # cou : anneaux
    neck = F.mask & (y < -0.12) & (y > -0.24) & (ax < 0.07)
    for yy in (-0.15, -0.175, -0.2):
        h -= 0.0004 * gauss(y - yy - 0.003 * np.sin(x * 40), 0.002) * neck
    return h


def fine_height(F, M):
    """grain de peau : petits creux (pores) et relief doux, rides fines des lèvres."""
    P = M['P']
    n1 = value_noise3(P, 900.0, seed=11, octaves=2)
    n2 = value_noise3(P, 260.0, seed=12, octaves=2)
    h = (n1 - 0.5) * 0.00006 + (n2 - 0.5) * 0.00008
    h -= 0.00008 * (np.cos(F.x * 1100) ** 8) * F.lips_soft
    return h * F.mask


def compose(size=2048):
    import pickle
    from maps import body_maps, neutral
    M = body_maps(size)
    F = Face(M)
    R = regions(F, size)
    F.lips_soft = R['levres']
    base, W, topo, Vw0, HJ, Vf = neutral()
    ao_v = pickle.load(open(cache('cache_ao.pkl'), 'rb'))
    ao = vertex_attr_to_tex(M, topo, ao_v)
    mask = M['mask']
    P = M['P']
    # --- variations de teint (multiplicatives, 0,5 = neutre)
    f = np.ones((size, size, 3), np.float32)
    mot = value_noise3(P, 14.0, seed=5, octaves=3)
    f *= (1 + (mot - 0.5)[..., None] * np.array([0.10, 0.12, 0.13]))
    fine = value_noise3(P, 180.0, seed=6, octaves=2)
    f *= (1 + (fine - 0.5)[..., None] * 0.06)
    # rougeurs
    red = 0.45 * R['blush'] + 0.55 * R['nez'] + 0.5 * blur(R['oreilles'], 3) + 0.3 * blur(R['levres'], 10) * (1 - R['levres'])
    # mains, pieds, genoux, coudes
    J = HJ
    for b, amt, rad in (('LeftHand', 0.35, 0.2), ('RightHand', 0.35, 0.2), ('LeftToeBase', 0.25, 0.08), ('RightToeBase', 0.25, 0.08),
                         ('LeftLeg', 0.22, 0.05), ('RightLeg', 0.22, 0.05), ('LeftForeArm', 0.15, 0.04), ('RightForeArm', 0.15, 0.04)):
        d = np.linalg.norm(P - J[b], axis=-1)
        red += amt * gauss(d, rad) * mask
    red = np.clip(red, 0, 1)
    f *= (1 - red[..., None] * np.array([0.0, 0.2, 0.2]))
    # creux des yeux et paupières
    orb = R['orbites']
    f *= (1 - orb[..., None] * np.array([0.10, 0.13, 0.08]))
    f *= (1 - blur(R['paupieres'], 2)[..., None] * np.array([0.06, 0.1, 0.06]))
    # aréoles, ongles
    f *= (1 - R['aureoles'][..., None] * np.array([0.25, 0.4, 0.38]))
    f = f * (1 - R['ongles'][..., None] * 0.0) + R['ongles'][..., None] * np.array([0.15, 0.08, 0.1])
    # occlusion
    f *= (0.5 + 0.5 * np.clip(ao, 0, 1))[..., None]
    var = np.clip(f * 0.5, 0, 1)
    var = dilate(var, mask, 24)
    # --- masques
    m1 = np.stack([R['levres'], R['sourcils'], R['moustache'], R['menton']], -1)
    m2 = np.stack([R['joues'], R['crane'], R['orbites'], R['blush']], -1)
    m1 = dilate(np.clip(m1, 0, 1), mask, 24)
    m2 = dilate(np.clip(m2, 0, 1), mask, 24)
    # --- normales
    hf = fine_height(F, M)
    nf = normal_from_height(dilate(hf, mask, 4), P, mask, 1.0)
    hw = wrinkle_height(F)
    nw = normal_from_height(dilate(blur(hw, 0.7), mask, 4), P, mask, 1.0)
    nf = dilate(nf, mask, 24)
    nw = dilate(nw, mask, 24)
    return dict(var=var, m1=m1, m2=m2, nf=nf, nw=nw, ao=ao, M=M, F=F, R=R)


def save_rgb(path, a):
    Image.fromarray((np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8)).save(path, optimize=True)


def save_normal(path, n):
    save_rgb(path, n * 0.5 + 0.5)
