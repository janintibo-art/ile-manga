"""Cheveux et barbes en mèches (cartes alpha) poussées depuis le cuir chevelu du corps neutre,
avec collision contre la tête et le buste (champ de distance signée)."""
import numpy as np
from scipy import ndimage
from scipy.spatial import cKDTree
from maps import neutral
from export import welded_normals
from landmarks import landmarks


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


class Body:
    def __init__(self):
        base, W, topo, Vw0, HJ, Vf = neutral()
        self.base, self.W, self.topo = base, W, topo
        self.V = Vw0
        self.HJ = HJ
        self.L = landmarks(base, Vf)
        self.c = self.L['eyes_mid']
        self.tris = topo.split_w[topo.surfaces['peau'].reshape(-1, 3)][:, ::-1]   # sens direct
        self.N = welded_normals(topo, Vw0)
        A, B, C = (self.V[self.tris[:, k]] for k in range(3))
        self.tri_c = (A + B + C) / 3
        self.tri_n = np.cross(B - A, C - A)
        self.tri_area = np.linalg.norm(self.tri_n, axis=1) / 2
        self.tri_n /= np.linalg.norm(self.tri_n, axis=1, keepdims=True) + 1e-12
        self.kd = cKDTree(self.tri_c)
        self.zc = (self.L['front_z'] + self.L['back_z']) / 2 - self.c[2]
        self._sdf()

    # -------------------------------------------------- champ de distance
    def _sdf(self, h=0.004):
        lo = np.array([-0.32, 0.85, -0.3])
        hi = np.array([0.32, 1.85, 0.32])
        self.g_lo, self.g_h = lo, h
        shape = np.ceil((hi - lo) / h).astype(int) + 1
        surf = np.zeros(shape, bool)
        # échantillons denses de la surface (sans les bras sous le coude)
        rng = np.random.default_rng(3)
        p = self.tri_area / self.tri_area.sum()
        idx = rng.choice(len(self.tris), 2500000, p=p)
        r1 = np.sqrt(rng.random(len(idx)))
        r2 = rng.random(len(idx))
        A, B, C = (self.V[self.tris[idx, k]] for k in range(3))
        S = A * (1 - r1)[:, None] + B * (r1 * (1 - r2))[:, None] + C * (r1 * r2)[:, None]
        ij = np.round((S - lo) / h).astype(int)
        ok = np.all((ij >= 0) & (ij < shape), 1)
        surf[tuple(ij[ok].T)] = True
        surf = ndimage.binary_dilation(surf, iterations=1)
        outside = ~surf
        lab, n = ndimage.label(outside)
        outer = lab == lab[0, 0, 0]
        inside = ~outer
        d_out = ndimage.distance_transform_edt(~inside) * h
        d_in = ndimage.distance_transform_edt(inside) * h
        self.sdf = (d_out - d_in).astype(np.float32)
        self.sdf_grad = np.stack(np.gradient(self.sdf, h), -1).astype(np.float32)

    def dist(self, P):
        q = (np.atleast_2d(P) - self.g_lo) / self.g_h
        out = ndimage.map_coordinates(self.sdf, q.T, order=1, mode='nearest')
        return out

    def grad(self, P):
        q = (np.atleast_2d(P) - self.g_lo) / self.g_h
        g = np.stack([ndimage.map_coordinates(self.sdf_grad[..., k], q.T, order=1, mode='nearest') for k in range(3)], -1)
        return g / (np.linalg.norm(g, axis=-1, keepdims=True) + 1e-9)

    # -------------------------------------------------- repère de la tête
    def local(self, P):
        H = P - self.c
        ax = np.abs(H[..., 0])
        th = np.degrees(np.arctan2(ax, H[..., 2] - self.zc))
        return H[..., 0], H[..., 1], H[..., 2], ax, th

    def hairline(self, th):
        return np.interp(th, [0, 25, 42, 55, 63, 70, 78, 100, 115, 140, 180],
                         [0.066, 0.062, 0.05, 0.034, 0.012, 0.0, 0.012, 0.012, -0.03, -0.075, -0.098])

    def sample_region(self, n, weight_fn, seed=0):
        """points répartis sur la surface selon weight_fn(x, y, z, ax, th) -> [0,1]."""
        rng = np.random.default_rng(seed)
        x, y, z, ax, th = self.local(self.tri_c)
        w = weight_fn(x, y, z, ax, th) * self.tri_area
        w = np.clip(w, 0, None)
        p = w / w.sum()
        idx = rng.choice(len(self.tris), n * 3, p=p)
        r1 = np.sqrt(rng.random(len(idx)))
        r2 = rng.random(len(idx))
        A, B, C = (self.V[self.tris[idx, k]] for k in range(3))
        S = A * (1 - r1)[:, None] + B * (r1 * (1 - r2))[:, None] + C * (r1 * r2)[:, None]
        # tirage poisson-disque grossier : on écarte les points trop proches
        keep = []
        tree = None
        mind = np.sqrt(w.sum() / max(n, 1) / np.pi) * 0.9 / np.sqrt(np.mean(self.tri_area[idx] / self.tri_area[idx].mean()))
        chosen = []
        kd_pts = []
        for i in range(len(S)):
            if len(chosen) >= n:
                break
            if kd_pts:
                d = np.min(np.linalg.norm(np.array(kd_pts[-400:]) - S[i], axis=1))
                if d < mind:
                    continue
            chosen.append(i)
            kd_pts.append(S[i])
        idx = idx[chosen]
        S = S[chosen]
        return S, self.tri_n[idx]

    def scalp_weight(self, x, y, z, ax, th, extra=0.0):
        hl = self.hairline(th) - extra
        head = (y > -0.16) & (y < 0.15) & (z > -0.2) & (ax < 0.1)
        ear = (np.abs(ax - 0.072) < 0.012) & (np.abs(y + 0.024) < 0.03) & (np.abs(z + 0.073) < 0.025)
        return head * smooth(hl - 0.001, hl + 0.004, y) * (~ear)


# =================================================================== mèches

def grow(body, root, n0, comb, length, segs, gravity, stiff, min_off, curl=0.0, curl_r=0.0, seed=0, push=1.0):
    """root, n0 (3,) ; comb(p) -> direction de peignage au point p. Renvoie (segs+1, 3)."""
    rng = np.random.default_rng(seed)
    pts = [root + n0 * min_off * 0.5]
    d = n0 * 0.35 + comb(root) * 1.0
    d /= np.linalg.norm(d)
    ds = length / segs
    phase = rng.random() * 6.28
    for s in range(segs):
        t = (s + 1) / segs
        target = comb(pts[-1])
        d = d * stiff + target * (1 - stiff)
        d = d + np.array([0, -1.0, 0]) * gravity * t
        d /= np.linalg.norm(d)
        p = pts[-1] + d * ds
        if curl > 0:
            # boucle : petite spirale autour de la direction
            a = np.cross(d, [0, 1, 0])
            if np.linalg.norm(a) < 1e-3:
                a = np.cross(d, [1, 0, 0])
            a /= np.linalg.norm(a)
            b = np.cross(d, a)
            ang = phase + t * curl
            p = p + (a * np.cos(ang) + b * np.sin(ang)) * curl_r * min(1.0, t * 3)
        dd = body.dist(p)[0]
        need = min_off * (1.0 + 0.6 * t) * push
        if dd < need:
            g = body.grad(p)[0]
            p = p + g * (need - dd)
        d = p - pts[-1]
        d /= np.linalg.norm(d) + 1e-9
        pts.append(p)
    return np.array(pts)


def ribbon(body, strand, width, taper=0.6, outward=None):
    """ruban le long d'une mèche, posé à plat sur le volume (largeur tangente à la tête)."""
    n = len(strand)
    L = []
    R = []
    tans = []
    for i in range(n):
        a = strand[max(i - 1, 0)]
        b = strand[min(i + 1, n - 1)]
        t = b - a
        t /= np.linalg.norm(t) + 1e-9
        o = body.grad(strand[i])[0] if outward is None else outward(strand[i])
        w = np.cross(t, o)
        if np.linalg.norm(w) < 1e-4:
            w = np.cross(t, [0, 0, 1])
        w /= np.linalg.norm(w)
        k = 1.0 - taper * (i / (n - 1)) ** 1.5
        L.append(strand[i] - w * width * 0.5 * k)
        R.append(strand[i] + w * width * 0.5 * k)
        tans.append(t)
    return np.array(L), np.array(R), np.array(tans)


class CardMesh:
    def __init__(self):
        self.P, self.UV, self.T, self.C, self.I, self.N = [], [], [], [], [], []
        self.n = 0

    def add_ribbon(self, body, L, R, tans, col, rng, shade=1.0, uv_v=(0.0, 1.0)):
        """col : colonne de l'atlas (0..7) ; v de la racine (0) à la pointe (1)."""
        n = len(L)
        u0 = (col + 0.06) / 8.0
        u1 = (col + 0.94) / 8.0
        base = self.n
        bright = shade * (0.85 + 0.3 * rng.random())
        for i in range(n):
            v = uv_v[0] + (uv_v[1] - uv_v[0]) * i / (n - 1)
            mid = (L[i] + R[i]) / 2
            nrm = body.grad(mid)[0]
            for P, u in ((L[i], u0), (R[i], u1)):
                self.P.append(P)
                self.UV.append([u, v])
                self.T.append(tans[i])
                self.N.append(nrm)
                self.C.append([bright, bright, bright, 1.0 - 0.0 * i / (n - 1)])
        for i in range(n - 1):
            a, b, c, d = base + 2 * i, base + 2 * i + 1, base + 2 * i + 2, base + 2 * i + 3
            self.I += [a, c, b, b, c, d]
        self.n += 2 * n

    def arrays(self):
        return (np.array(self.P), np.array(self.UV), np.array(self.T), np.array(self.N), np.array(self.C), np.array(self.I))


def grow2(body, root, n0, comb, length, segs, hug, gravity=0.6, stiff=0.5, free_y=-0.035, seed=0,
          curl=0.0, curl_r=0.0, wave=0.0, lift=0.0, ds_jitter=0.0):
    """mèche qui épouse le crâne (distance ~hug) tant qu'elle est sur la tête, puis tombe librement
    (gravité) en glissant sur le cou, les épaules et le dos."""
    rng = np.random.default_rng(seed)
    down = np.array([0.0, -1.0, 0.0])
    p = root + n0 * hug * 0.5
    pts = [p.copy()]
    d = comb(root)
    d = d + n0 * lift
    d /= np.linalg.norm(d)
    ds = length / segs
    phase = rng.random() * 6.28
    for s in range(segs):
        t = (s + 1) / segs
        x, y, z, ax, th = body.local(p)
        dist = body.dist(p)[0]
        on_head = (y > free_y) and dist < 0.05
        if on_head:
            tgt = comb(p)
            dn = d * stiff + tgt * (1 - stiff)
        else:
            dn = d * stiff + down * (1 - stiff)
        dn = dn + down * gravity * t * (0.4 if on_head else 1.0)
        if wave > 0:
            side = np.cross(dn, body.grad(p)[0])
            dn = dn + side * np.sin(phase + t * 14.0) * wave
        dn /= np.linalg.norm(dn)
        q = p + dn * ds
        if curl > 0:
            a = np.cross(dn, [0, 1, 0])
            if np.linalg.norm(a) < 1e-3:
                a = np.cross(dn, [1, 0, 0])
            a /= np.linalg.norm(a)
            b = np.cross(dn, a)
            ang = phase + t * curl
            q = q + (a * np.cos(ang) + b * np.sin(ang)) * curl_r * min(1.0, t * 4)
        dq = body.dist(q)[0]
        g = body.grad(q)[0]
        x2, y2, z2, ax2, th2 = body.local(q)
        if y2 > free_y and dq < 0.06:
            q = q - g * (dq - hug) * 0.85          # épouse la tête
        elif dq < hug:
            q = q + g * (hug - dq)                 # glisse sur le corps
        d = q - p
        d /= np.linalg.norm(d) + 1e-9
        p = q
        pts.append(p.copy())
    return np.array(pts)
