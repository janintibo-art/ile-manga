"""Rastérisation de triangles dans l'espace UV (pour peindre des textures à partir de la géométrie)."""
import numpy as np
from scipy import ndimage


def rasterize(UV, tris, size):
    """UV (n,2) dans [0,1] (v vers le bas, convention Godot). tris (m,3).
    Renvoie tri_id (H,W) (-1 vide) et bary (H,W,3)."""
    H = W = size
    tid = -np.ones((H, W), dtype=np.int32)
    bary = np.zeros((H, W, 3), dtype=np.float32)
    P = UV * size - 0.5
    for t, (a, b, c) in enumerate(tris):
        pa, pb, pc = P[a], P[b], P[c]
        x0 = int(np.floor(min(pa[0], pb[0], pc[0])))
        x1 = int(np.ceil(max(pa[0], pb[0], pc[0])))
        y0 = int(np.floor(min(pa[1], pb[1], pc[1])))
        y1 = int(np.ceil(max(pa[1], pb[1], pc[1])))
        x0, y0 = max(x0, 0), max(y0, 0)
        x1, y1 = min(x1, W - 1), min(y1, H - 1)
        if x1 < x0 or y1 < y0:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1), np.arange(y0, y1 + 1))
        d = (pb[1] - pc[1]) * (pa[0] - pc[0]) + (pc[0] - pb[0]) * (pa[1] - pc[1])
        if abs(d) < 1e-12:
            continue
        l1 = ((pb[1] - pc[1]) * (xs - pc[0]) + (pc[0] - pb[0]) * (ys - pc[1])) / d
        l2 = ((pc[1] - pa[1]) * (xs - pc[0]) + (pa[0] - pc[0]) * (ys - pc[1])) / d
        l3 = 1 - l1 - l2
        e = -1e-4
        inside = (l1 >= e) & (l2 >= e) & (l3 >= e)
        if not inside.any():
            continue
        yy, xx = ys[inside], xs[inside]
        tid[yy, xx] = t
        bary[yy, xx, 0] = l1[inside]
        bary[yy, xx, 1] = l2[inside]
        bary[yy, xx, 2] = l3[inside]
    return tid, bary


def interp(tid, bary, tris, attr):
    """attribut par sommet (n,k) -> carte (H,W,k)."""
    m = tid >= 0
    out = np.zeros(tid.shape + (attr.shape[1],), dtype=np.float32)
    t = tris[tid[m]]
    b = bary[m]
    out[m] = attr[t[:, 0]] * b[:, 0:1] + attr[t[:, 1]] * b[:, 1:2] + attr[t[:, 2]] * b[:, 2:3]
    return out


def dilate(img, mask, iters=16):
    """étend les bords des îlots UV (évite les coutures au mipmapping)."""
    img = img.copy().astype(np.float32)
    m = mask.copy()
    if img.ndim == 2:
        img = img[..., None]
    for _ in range(iters):
        if m.all():
            break
        acc = np.zeros_like(img)
        cnt = np.zeros(m.shape, np.float32)
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)):
            sm = np.roll(np.roll(m, dy, 0), dx, 1)
            si = np.roll(np.roll(img, dy, 0), dx, 1)
            acc += si * sm[..., None]
            cnt += sm
        new = (~m) & (cnt > 0)
        img[new] = acc[new] / cnt[new][:, None]
        m = m | new
    if img.shape[-1] == 1:
        img = img[..., 0]
    return img


def blur(img, sigma):
    if img.ndim == 2:
        return ndimage.gaussian_filter(img, sigma)
    return np.stack([ndimage.gaussian_filter(img[..., k], sigma) for k in range(img.shape[-1])], -1)


def value_noise3(P, freq, seed=0, octaves=1, gain=0.5):
    """bruit de valeur 3D lissé (trilinéaire + smoothstep), P (...,3) en m."""
    rng = np.random.default_rng(seed)
    perm = rng.permutation(256)
    vals = rng.random(256).astype(np.float32)
    out = np.zeros(P.shape[:-1], np.float32)
    amp = 1.0
    tot = 0.0
    f = freq
    for o in range(octaves):
        q = P * f + o * 17.31
        i = np.floor(q).astype(np.int64)
        fr = q - i
        u = fr * fr * (3 - 2 * fr)

        def h(ix, iy, iz):
            return vals[perm[(perm[(perm[ix & 255] + iy) & 255] + iz) & 255]]
        x0, y0, z0 = i[..., 0], i[..., 1], i[..., 2]
        c000 = h(x0, y0, z0); c100 = h(x0 + 1, y0, z0)
        c010 = h(x0, y0 + 1, z0); c110 = h(x0 + 1, y0 + 1, z0)
        c001 = h(x0, y0, z0 + 1); c101 = h(x0 + 1, y0, z0 + 1)
        c011 = h(x0, y0 + 1, z0 + 1); c111 = h(x0 + 1, y0 + 1, z0 + 1)
        ux, uy, uz = u[..., 0], u[..., 1], u[..., 2]
        x00 = c000 + (c100 - c000) * ux
        x10 = c010 + (c110 - c010) * ux
        x01 = c001 + (c101 - c001) * ux
        x11 = c011 + (c111 - c011) * ux
        y0v = x00 + (x10 - x00) * uy
        y1v = x01 + (x11 - x01) * uy
        out += (y0v + (y1v - y0v) * uz) * amp
        tot += amp
        amp *= gain
        f *= 2.0
    return out / tot
