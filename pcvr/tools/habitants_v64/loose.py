"""Vêtements amples (proxies) : jupes, robes, bas de tunique, blouses, tabliers, capes, ceintures, foulards."""
import numpy as np
from hair import CardMesh, smooth
from clothes import Features
from rig import HB


class ClothMesh:
    def __init__(self):
        self.P, self.UV, self.T, self.N, self.I, self.H = [], [], [], [], [], []
        self.WH = []          # poids de « bassin » (1 = suit le bassin, 0 = suit la jambe)
        self.n = 0

    def grid(self, rows, wrap=True, hem_from_bottom=True):
        """rows : liste d'anneaux (k, 3) de même taille ; v du haut (0) vers le bas (1)."""
        nr = len(rows)
        k = len(rows[0])
        base = self.n
        L = [0.0]
        for r in range(1, nr):
            L.append(L[-1] + np.linalg.norm(rows[r] - rows[r - 1], axis=1).mean())
        tot = L[-1]
        for r in range(nr):
            for j in range(k):
                p = rows[r][j]
                a = rows[r][(j + 1) % k] if (wrap or j + 1 < k) else rows[r][j]
                b = rows[r][(j - 1) % k] if (wrap or j > 0) else rows[r][j]
                down = rows[min(r + 1, nr - 1)][j] - rows[max(r - 1, 0)][j]
                t = a - b
                t /= np.linalg.norm(t) + 1e-9
                n = np.cross(down, t)
                n /= np.linalg.norm(n) + 1e-9
                self.P.append(p)
                self.UV.append([j / (k - (0 if wrap else 1)) * (k / 12.0), L[r] / max(tot, 1e-6) * tot * 4.0])
                self.T.append(t)
                self.N.append(n)
                self.H.append(min(tot - L[r], L[r]) if not hem_from_bottom else tot - L[r])
                self.WH.append(1.0 - min(1.0, L[r] / max(tot, 1e-6)))
        cols = k if wrap else k - 1
        for r in range(nr - 1):
            for j in range(cols):
                a = base + r * k + j
                b = base + r * k + (j + 1) % k
                c = a + k
                d = b + k
                self.I += [a, b, c, b, d, c]
        self.n += nr * k


class Hull:
    """coupes horizontales du corps neutre (sans les bras) : rayon maximal par direction."""

    def __init__(self, body, F, nth=72, parts=(0, 3, 4)):
        V = body.V[:body.topo.nb]
        part = F.part[:body.topo.nb]
        keep = np.isin(part, parts)
        self.P = V[keep]
        self.cx = body.HJ['Hips'][0]
        self.cz = body.HJ['Hips'][2] - 0.01
        self.nth = nth
        self.th = np.linspace(0, 2 * np.pi, nth, endpoint=False)

    def radius(self, y, band=0.012):
        m = np.abs(self.P[:, 1] - y) < band
        Q = self.P[m]
        dx, dz = Q[:, 0] - self.cx, Q[:, 2] - self.cz
        a = np.arctan2(dx, dz) % (2 * np.pi)
        r = np.sqrt(dx ** 2 + dz ** 2)
        out = np.zeros(self.nth)
        for i, t in enumerate(self.th):
            d = np.abs(((a - t + np.pi) % (2 * np.pi)) - np.pi)
            sel = d < (2 * np.pi / self.nth) * 1.6
            out[i] = r[sel].max() if sel.any() else 0.0
        # enveloppe convexe approximative en polaire (lissage par maximum glissant)
        for _ in range(3):
            out = np.maximum(out, (np.roll(out, 1) + np.roll(out, -1)) * 0.5 * np.cos(2 * np.pi / self.nth))
        return out


def skirt_radius(hull, y_top, y_bot, y, angs, clear_top=0.012, flare=0.12, folds=14, fold_amp=(0.003, 0.014), ring_step=0.03, seed=0):
    """rayon (par angle) d'une jupe faite par skirt() avec ces paramètres, à la hauteur y (même formule)."""
    rng = np.random.default_rng(seed)
    ph = rng.random(3) * 6.28
    nr = max(3, int(round((y_top - y_bot) / ring_step)) + 1)
    ys = [yy for yy in np.linspace(y_top, y_bot, nr) if yy >= y] + [y]
    rmax = None
    for yy in ys:
        rr = np.interp(angs % (2 * np.pi), hull.th, hull.radius(yy), period=2 * np.pi)
        rmax = rr if rmax is None else np.maximum(rmax, rr)
    t = (y_top - y) / max(y_top - y_bot, 1e-6)
    r = rmax + clear_top + flare * t ** 1.3
    amp = fold_amp[0] + (fold_amp[1] - fold_amp[0]) * t
    return r + amp * (np.sin(angs * folds + ph[0] + t * 0.8) * 0.7 + np.sin(angs * folds * 0.5 + ph[1]) * 0.3)


def skirt(body, F, hull, y_top, y_bot, clear_top=0.012, flare=0.12, folds=14, fold_amp=(0.003, 0.014), span=None,
          gap=0.0, nk=64, ring_step=0.03, seed=0, under=None):
    """jupe (ou pan) : anneaux du haut vers le bas ; span=(a0, a1) en radians pour un pan (tablier, cape).
    under : paramètres d'une jupe portée dessous (un tablier sur une jupe) : on reste toujours au-dessus d'elle."""
    rng = np.random.default_rng(seed)
    nr = max(3, int(round((y_top - y_bot) / ring_step)) + 1)
    ys = np.linspace(y_top, y_bot, nr)
    rows = []
    rmax = None
    if span is None:
        angs = np.linspace(0, 2 * np.pi, nk, endpoint=False)
        wrap = True
    else:
        angs = np.linspace(span[0], span[1], nk)
        wrap = False
    ph = rng.random(3) * 6.28
    for i, y in enumerate(ys):
        rr = hull.radius(y)
        rr = np.interp(angs % (2 * np.pi), hull.th, rr, period=2 * np.pi)
        rmax = rr if rmax is None else np.maximum(rmax, rr)       # la jupe ne rentre jamais vers l'intérieur
        t = (y_top - y) / max(y_top - y_bot, 1e-6)
        r = rmax + clear_top + flare * t ** 1.3
        amp = fold_amp[0] + (fold_amp[1] - fold_amp[0]) * t
        r = r + amp * (np.sin(angs * folds + ph[0] + t * 0.8) * 0.7 + np.sin(angs * folds * 0.5 + ph[1]) * 0.3)
        if under is not None and under['y_bot'] - 0.01 <= y <= under['y_top'] + 0.01:
            yy = float(np.clip(y, under['y_bot'], under['y_top']))
            ru = skirt_radius(hull, under['y_top'], under['y_bot'], yy, angs, **{k: v for k, v in under.items() if k not in ('y_top', 'y_bot')})
            r = np.maximum(r, ru + 0.009)
        if gap > 0:
            # ouverture devant (blouse) : les deux pans se recouvrent un peu
            d = np.abs(((angs + np.pi) % (2 * np.pi)) - np.pi)
            r = r + 0.004 * smooth(gap * 1.5, gap * 0.5, d)
        ring = np.stack([hull.cx + np.sin(angs) * r, np.full(len(angs), y), hull.cz + np.cos(angs) * r], 1)
        rows.append(ring)
    m = ClothMesh()
    if gap > 0:
        # on coupe l'anneau devant : pan ouvert
        keep = np.abs(((angs + np.pi) % (2 * np.pi)) - np.pi) > gap
        idx = np.where(keep)[0]
        start = np.argmax(np.diff(np.concatenate([idx, [idx[0] + nk]])) > 1) + 1
        idx = np.roll(idx, -start)
        rows = [r[idx] for r in rows]
        wrap = False
    m.grid(rows, wrap=wrap)
    return m


def front_panel(body, y_top, y_bot, half_w, clear=0.012, nx=14, step=0.025):
    """panneau qui épouse l'avant du corps (bavette de tablier)."""
    rows = []
    for y in np.arange(y_top, y_bot - 1e-6, -step):
        row = []
        for x in np.linspace(-half_w, half_w, nx):
            p = np.array([body.HJ['Hips'][0] + x, y, body.HJ['Hips'][2] + 0.3])
            # descend le long de -z jusqu'à la surface
            for _ in range(40):
                d = body.dist(p)[0]
                if d < clear:
                    break
                p[2] -= max(d - clear, 0.002)
            row.append(p.copy())
        rows.append(np.array(row))
    m = ClothMesh()
    m.grid(rows, wrap=False)
    return m


def tube_ring(body, hull, y, radius_tube, clear, nk=40, sides=8):
    rr = hull.radius(y) + clear
    angs = np.linspace(0, 2 * np.pi, nk, endpoint=False)
    rows = []
    for s in range(sides + 1):
        a = 2 * np.pi * s / sides
        r = np.interp(angs, hull.th, rr, period=2 * np.pi) + radius_tube * (1 + np.cos(a))
        yy = y + radius_tube * np.sin(a)
        rows.append(np.stack([hull.cx + np.sin(angs) * r, np.full(nk, yy), hull.cz + np.cos(angs) * r], 1))
    m = ClothMesh()
    m.grid(rows, wrap=True, hem_from_bottom=False)
    return m


def tie(body, y_top, y_bot, w_top=0.011, w_bot=0.027, clear=0.013, nx=7, step=0.02):
    """V75 : cravate : bande qui épouse l'avant du buste, plus large en bas, terminée en pointe ;
    un petit nœud (plus épais) sous le col."""
    ys = list(np.arange(y_top, y_bot - 1e-6, -step)) + [y_bot - 0.025]
    rows = []
    for k, y in enumerate(ys):
        t = min(1.0, (y_top - y) / max(y_top - y_bot, 1e-6))
        hw = w_top + (w_bot - w_top) * t
        knot = k <= 1
        row = []
        for j, x in enumerate(np.linspace(-hw, hw, nx)):
            yy = y
            if k == len(ys) - 1:
                yy = y + 0.025 * abs(x) / hw          # la pointe
            p = np.array([body.HJ['Hips'][0] + x, yy, body.HJ['Hips'][2] + 0.3])
            c = clear + (0.006 if knot else 0.0)
            for _ in range(40):
                d = body.dist(p)[0]
                if d < c:
                    break
                p[2] -= max(d - c, 0.002)
            row.append(p.copy())
        rows.append(np.array(row))
    m = ClothMesh()
    m.grid(rows, wrap=False)
    return m
