"""Textures des vêtements : trames de tissu (raccordables), détails cousus et plis (espace UV du corps)."""
import numpy as np
from PIL import Image
from scipy import ndimage
from skin_tex import smooth, gauss, normal_from_height, save_rgb
from uvraster import dilate, blur, value_noise3


def periodic_noise(n, scale, seed):
    """bruit raccordable (filtrage FFT d'un bruit blanc)."""
    rng = np.random.default_rng(seed)
    w = rng.normal(size=(n, n))
    f = np.fft.fftfreq(n)
    fx, fy = np.meshgrid(f, f)
    r = np.sqrt(fx ** 2 + fy ** 2) * n
    filt = np.exp(-(r / scale) ** 2)
    out = np.real(np.fft.ifft2(np.fft.fft2(w) * filt))
    out = (out - out.min()) / (out.max() - out.min())
    return out


def tile_normal(h, strength):
    gy, gx = np.gradient(h)
    gx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5
    gy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5
    n = np.stack([-gx * strength, gy * strength, np.ones_like(h)], -1)
    return n / np.linalg.norm(n, axis=-1, keepdims=True)


def weave(kind, n=512, seed=0):
    """-> RGBA : RG normale, B variation de couleur, A variation de rugosité."""
    yy, xx = np.mgrid[0:n, 0:n] / n
    rng = np.random.default_rng(seed)
    nz = periodic_noise(n, 40, seed)
    if kind in ('coton', 'toile', 'lin'):
        k = {'coton': 64, 'toile': 40, 'lin': 48}[kind]
        wx = np.sin(xx * k * 2 * np.pi)
        wy = np.sin(yy * k * 2 * np.pi)
        over = np.sign(np.sin(xx * k * np.pi) * np.sin(yy * k * np.pi))
        h = 0.5 + 0.25 * (np.abs(wx) * (over > 0) + np.abs(wy) * (over <= 0))
        if kind == 'lin':
            slub = periodic_noise(n, 6, seed + 1)
            h += 0.25 * (slub - 0.5)
        col = 0.5 + 0.4 * (nz - 0.5) + 0.1 * (h - 0.5)
        strength = 3.0
    elif kind == 'jean':
        k = 56
        d = (xx + yy) * k
        h = 0.5 + 0.35 * np.sin(d * 2 * np.pi) + 0.15 * np.sin(xx * k * 4 * np.pi)
        speck = periodic_noise(n, 120, seed + 2)
        col = 0.5 + 0.55 * (nz - 0.5) + 0.25 * (speck - 0.5) + 0.1 * np.sin(d * 2 * np.pi)
        strength = 3.5
    elif kind == 'laine':
        k = 18
        u = xx * k
        v = yy * k * 1.6
        h = 0.5 + 0.4 * np.abs(np.sin((v + np.abs((u % 1) - 0.5) * 1.4) * np.pi)) * np.abs(np.cos(u * np.pi))
        col = 0.5 + 0.35 * (nz - 0.5) + 0.15 * (h - 0.5)
        strength = 5.0
    elif kind == 'cuir':
        cell = periodic_noise(n, 70, seed + 3)
        crack = np.abs(periodic_noise(n, 25, seed + 4) - 0.5)
        h = cell * 0.6 + smooth(0.0, 0.06, crack) * 0.4
        col = 0.5 + 0.5 * (periodic_noise(n, 8, seed + 5) - 0.5) + 0.1 * (h - 0.5)
        strength = 2.5
    elif kind == 'paille':
        k = 20
        u, v = xx * k, yy * k
        over = np.sign(np.sin(u * np.pi) * np.sin(v * np.pi))
        su = 0.5 + 0.5 * np.cos((u % 1 - 0.5) * np.pi * 1.6)
        sv = 0.5 + 0.5 * np.cos((v % 1 - 0.5) * np.pi * 1.6)
        h = np.where(over > 0, su, sv)
        fib = periodic_noise(n, 90, seed + 7)
        col = 0.5 + 0.3 * (h - 0.5) + 0.35 * (fib - 0.5) + 0.2 * (nz - 0.5)
        strength = 4.0
    else:  # soie
        h = periodic_noise(n, 30, seed + 6) * 0.2
        col = 0.5 + 0.2 * (nz - 0.5)
        strength = 1.0
    N = tile_normal(h, strength)
    rough = 0.5 + 0.4 * (h - 0.5) + 0.2 * (nz - 0.5)
    return np.stack([N[..., 0] * 0.5 + 0.5, N[..., 1] * 0.5 + 0.5, np.clip(col, 0, 1), np.clip(rough, 0, 1)], -1)


def details_and_folds(M, body, F, ao_tex, size=2048):
    """carte des coutures (R), boutonnage (G), poches/braguette (B), occlusion (A) ; et normale des plis."""
    P = M['P']
    mask = M['mask']
    tid = M['tid']
    # caractéristiques par texel (depuis les sommets du triangle)
    from uvraster import interp
    topo = body.topo
    tris = topo.surfaces['peau'].reshape(-1, 3)
    part_v = F.part[topo.split_w].astype(np.float32)
    s_v = F.s[topo.split_w]
    S = interp(tid, M['bary'], tris, s_v[:, None])[..., 0]
    PART = np.where(mask, np.round(interp(tid, M['bary'], tris, part_v[:, None])[..., 0]), -1)
    HJ = body.HJ
    hx = HJ['Hips'][0]
    x, y, z = P[..., 0] - hx, P[..., 1], P[..., 2]
    ax = np.abs(x)
    tor = PART == 0
    arm = (PART == 1) | (PART == 2)
    leg = (PART == 3) | (PART == 4)
    seam = np.zeros(mask.shape, np.float32)
    w = 0.0016
    # coutures latérales du torse et des jambes, entrejambe
    zc_t = HJ['Spine01'][2]
    ang = np.degrees(np.arctan2(ax, z - zc_t))
    seam += tor * gauss(ang - 90, 3.0) * (y < F.neck_y - 0.06)
    for side, leg_part in ((1, 3), (-1, 4)):
        name = 'Left' if side > 0 else 'Right'
        a, b = HJ[name + 'UpLeg'], HJ[name + 'Foot']
        dvec = (b - a) / np.linalg.norm(b - a)
        rel = P - a
        rel = rel - (rel @ dvec)[..., None] * dvec
        la = np.degrees(np.arctan2(rel[..., 0] * side, rel[..., 2]))
        m = PART == leg_part
        seam += m * (gauss(la - 90, 4.0) + gauss(la + 90, 4.0))
    seam += tor * gauss(x, w * 1.5) * (y < F.waist_y - 0.02)
    # épaules et emmanchures
    zc_sh = (HJ['LeftArm'][2] + HJ['RightArm'][2]) / 2
    seam += tor * gauss(z - zc_sh, 0.003) * (y > F.chest_y + 0.02) * (ax > 0.06)
    seam += arm * gauss(S - 0.02, 0.003)
    seam = np.clip(seam, 0, 1)
    # boutonnage de chemise : deux lignes de patte + boutons
    btn = np.zeros(mask.shape, np.float32)
    front = tor & (z > HJ['Spine01'][2]) & (y < F.neck_y - 0.03)
    btn += front * (gauss(ax - 0.013, 0.0012) * 0.6)
    for k in range(9):
        by = F.neck_y - 0.06 - k * 0.075
        r = np.sqrt(x ** 2 + (y - by) ** 2)
        btn += front * smooth(0.0065, 0.0045, r) * (1 - 0.6 * smooth(0.0012, 0.0, np.abs(r - 0.003)))
    btn = np.clip(btn, 0, 1)
    # pantalon : ceinture, braguette, poches avant et arrière
    pk = np.zeros(mask.shape, np.float32)
    wy = F.waist_y + 0.015
    hip = (tor | leg) & (y < wy + 0.005)
    pk += hip * gauss(y - (wy - 0.038), 0.0016)
    fz = HJ['Hips'][2]
    frontp = hip & (z > fz)
    fly_x = 0.022 + 0.01 * smooth(F.crotch_y + 0.1, F.crotch_y + 0.03, y)
    pk += frontp * gauss(x - fly_x, 0.0014) * (y > F.crotch_y + 0.04) * (y < wy - 0.04)
    for side in (1, -1):
        # poche avant : oblique de la ceinture vers la couture latérale
        t = np.clip((wy - 0.04 - y) / 0.1, 0, 1)
        px = side * (0.075 + 0.07 * t)
        pk += frontp * gauss(x - px, 0.0018) * (y < wy - 0.04) * (y > wy - 0.14) * (z > fz + 0.02)
        # poche arrière
        bz = hip & (z < fz - 0.04)
        rect = (np.abs(x - side * 0.075) < 0.06) & (y < wy - 0.06) & (y > wy - 0.2)
        edge = gauss(np.abs(x - side * 0.075) - 0.06, 0.0016) * ((y < wy - 0.06) & (y > wy - 0.2)) + \
               gauss(y - (wy - 0.06), 0.0016) * (np.abs(x - side * 0.075) < 0.06) + gauss(y - (wy - 0.2), 0.0016) * (np.abs(x - side * 0.075) < 0.06)
        pk += bz * edge
    pk = np.clip(pk, 0, 1)
    det = np.stack([seam, btn, pk, np.clip(ao_tex, 0, 1)], -1) * mask[..., None]
    det = dilate(det, mask, 24)
    # plis
    h = np.zeros(mask.shape, np.float32)
    nlow = value_noise3(P, 9.0, seed=31, octaves=2)
    h += (nlow - 0.5) * 0.004
    for name in ('Left', 'Right'):
        e = HJ[name + 'ForeArm']
        de = np.linalg.norm(P - e, axis=-1)
        part_arm = (PART == (1 if name == 'Left' else 2))
        h += part_arm * gauss(de, 0.06) * np.sin((S - F.arm_len) * 260) * 0.0012
        k = HJ[name + 'Leg']
        dk = np.linalg.norm(P - k, axis=-1)
        part_leg = (PART == (3 if name == 'Left' else 4))
        h += part_leg * gauss(dk, 0.08) * np.sin((S - F.thigh_len) * 180) * 0.0015
        # tire-bouchonnage au bas du pantalon
        h += part_leg * gauss(S - (F.thigh_len + F.shin_len - 0.07), 0.05) * np.sin(S * 150 + y * 0) * 0.0012
        # plis de l'aisselle
        ap = HJ[name + 'Arm'] + np.array([0, -0.08, 0])
        da = np.linalg.norm(P - ap, axis=-1)
        h += tor * gauss(da, 0.07) * np.sin(np.arctan2(y - ap[1], z - ap[2]) * 7) * 0.0012
    # taille et entrejambe
    h += tor * gauss(y - (F.waist_y + 0.05), 0.03) * np.sin(y * 300) * 0.0008
    cr = np.array([hx, F.crotch_y + 0.02, HJ['Hips'][2] + 0.05])
    dc = np.linalg.norm(P - cr, axis=-1)
    h += (leg | tor) * gauss(dc, 0.1) * np.sin(np.arctan2(x, y - cr[1]) * 9) * 0.0012
    h = h * mask
    nf = normal_from_height(dilate(blur(h, 1.0), mask, 4), P, mask, 1.0)
    nf = dilate(nf, mask, 24)
    return det, nf
