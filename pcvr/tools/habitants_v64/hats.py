"""Chapeaux et coiffes (proxies ajustés à la tête) : surfaces de révolution et coques de crâne."""
import numpy as np
from loose import ClothMesh
from hair import smooth


class HeadGeo:
    def __init__(self, body):
        self.body = body
        L = body.L
        self.c = body.c.copy()
        # centre de la tête : entre l'avant et l'arrière, au niveau des tempes
        self.hc = np.array([body.c[0], body.c[1] + 0.035, (L['front_z'] + L['back_z']) / 2])
        self.top = L['top'][1]

    def surface(self, d, start=None):
        """point de la surface de la tête dans la direction d depuis le centre (marche sur le champ de distance)."""
        o = self.hc if start is None else start
        d = d / np.linalg.norm(d)
        t = 0.0
        for _ in range(60):
            p = o + d * t
            dist = self.body.dist(p)[0]
            if dist > 0.0005 and t > 0.03:
                # on revient sur la surface par bissection
                lo, hi = max(t - 0.02, 0.0), t
                for _ in range(16):
                    mid = (lo + hi) / 2
                    if self.body.dist(o + d * mid)[0] > 0:
                        hi = mid
                    else:
                        lo = mid
                return o + d * hi
            t += max(abs(dist), 0.002) if dist < 0 else 0.004
        return o + d * t

    def ring_radius(self, y, n, clear=0.0):
        """rayon de la tête (par angle, depuis l'axe du centre de la tête) à la hauteur y."""
        ang = np.linspace(0, 2 * np.pi, n, endpoint=False)
        out = []
        for a in ang:
            d = np.array([np.sin(a), 0.0, np.cos(a)])
            o = np.array([self.hc[0], y, self.hc[2]])
            p = self.surface(d, o)
            out.append(np.hypot(p[0] - self.hc[0], p[2] - self.hc[2]) + clear)
        return ang, np.array(out)


def rot_x(P, ang, pivot):
    c, s = np.cos(ang), np.sin(ang)
    R = np.array([[1, 0, 0], [0, c, -s], [0, s, c]])
    return (P - pivot) @ R.T + pivot


def rot_z(P, ang, pivot):
    c, s = np.cos(ang), np.sin(ang)
    R = np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])
    return (P - pivot) @ R.T + pivot


def lathe(H, y_seat, profile, n=64, clear=0.006, brim_fn=None, tilt=0.0, roll=0.0, rad_fn=None):
    """profile : liste de (dr, dy) relatifs à l'anneau d'assise (dr ajouté au rayon de la tête).
    brim_fn(ang, k) -> (dr, dy) supplémentaires ; rad_fn(ang, k) -> facteur. Renvoie la liste d'anneaux."""
    ang, r0 = H.ring_radius(y_seat, n, clear)
    rows = []
    for k, (dr, dy) in enumerate(profile):
        ring = []
        for i, a in enumerate(ang):
            r = r0[i] + dr
            yy = y_seat + dy
            if brim_fn is not None:
                er, ey = brim_fn(a, k)
                r += er
                yy += ey
            if rad_fn is not None:
                r *= rad_fn(a, k)
            ring.append([H.hc[0] + np.sin(a) * r, yy, H.hc[2] + np.cos(a) * r])
        rows.append(np.array(ring))
    pivot = np.array([H.hc[0], y_seat, H.hc[2]])
    if tilt:
        rows = [rot_x(r, tilt, pivot) for r in rows]
    if roll:
        rows = [rot_z(r, roll, pivot) for r in rows]
    return rows


def mesh_from(rows_list, wrap=True):
    m = ClothMesh()
    for rows in rows_list:
        m.grid(rows, wrap=wrap, hem_from_bottom=False)
    return m


def disc_cap(rows_top, center_lift=0.004, nrings=4):
    """ferme le dessus d'un chapeau : anneaux concentriques vers le centre."""
    last = rows_top
    c = last.mean(0) + np.array([0, center_lift, 0])
    rows = [last]
    for k in range(1, nrings + 1):
        t = k / nrings
        rows.append(last * (1 - t) + c * t + np.array([0, center_lift * np.sin(t * np.pi / 2), 0]) * 0)
    return rows


def head_shell(H, theta0, theta1, phi0, phi1, nt, nphi, offset, extra=None, thetas=None):
    """coque autour du crâne : directions (theta autour de l'axe vertical, 0 devant ; phi : 0 horizontal,
    90° vers le haut). offset(t, p) et extra(t, p, q) reçoivent t ramené dans ]-180, 180] (|t| = écart à l'avant)."""
    if thetas is None:
        thetas = [theta0 + (theta1 - theta0) * i / (nt - 1) for i in range(nt)]
    rows = []
    for j in range(nphi):
        phi = np.radians(phi0 + (phi1 - phi0) * j / (nphi - 1))
        ring = []
        for tdeg in thetas:
            th = np.radians(tdeg)
            tn = (tdeg + 180.0) % 360.0 - 180.0
            d = np.array([np.sin(th) * np.cos(phi), np.sin(phi), np.cos(th) * np.cos(phi)])
            p = H.surface(d)
            n = H.body.grad(p)[0]
            off = offset(tn, np.degrees(phi)) if callable(offset) else offset
            q = p + n * off
            if extra is not None:
                q = q + extra(tn, np.degrees(phi), q)
            ring.append(q)
        rows.append(np.array(ring))
    return rows[::-1]     # du haut vers le bas


def close_top(rows):
    """ferme le petit trou du sommet (anneau à phi ~ 88°) par un anneau réduit à son centre."""
    r0 = rows[0]
    c = r0.mean(0)
    return [np.repeat(c[None], len(r0), 0)] + list(rows)


def framed_shell(H, open_deg, phi_low, phi_split, phi_top, n_top, n_low, offset, extra=None, step=7.5):
    """coque qui encadre le visage : calotte complète au-dessus de phi_split, puis un pourtour ouvert
    devant (|theta| < open_deg) jusqu'à phi_low. Les deux parties partagent les mêmes angles (pas de fente)."""
    full = [k * step for k in range(int(round(360 / step)))]
    top = head_shell(H, 0, 0, phi_split, phi_top, 0, n_top, offset, extra, thetas=full)
    low_t = [t for t in np.arange(open_deg, 360.0 - open_deg + 1e-6, step)]
    low = head_shell(H, 0, 0, phi_low, phi_split, 0, n_low, offset, extra, thetas=low_t)
    return top, low, np.array([(t + 180.0) % 360.0 - 180.0 for t in low_t])


# ------------------------------------------------------------------ catalogue

def build_hats(body):
    H = HeadGeo(body)
    ey = body.c[1]
    hats = {}
    # chapeau de paille (bord large, calotte ronde)
    prof = [(0.07, -0.004), (0.05, 0.0), (0.02, 0.002), (0.003, 0.005), (0.006, 0.03), (0.002, 0.06), (-0.015, 0.085), (-0.04, 0.095)]
    rows = lathe(H, ey + 0.05, prof, brim_fn=lambda a, k: (0.0, -0.012 * (1 - k / 2) if k < 2 else 0.0), tilt=-0.12)
    rows += disc_cap(rows[-1], 0.0)[1:]
    hats['ch_paille'] = mesh_from([rows])
    # capeline (très large, ondulée)
    prof = [(0.12, -0.02), (0.08, -0.006), (0.03, 0.0), (0.004, 0.006), (0.006, 0.035), (-0.008, 0.07), (-0.035, 0.085)]
    rows = lathe(H, ey + 0.05, prof, brim_fn=lambda a, k: (0.0, 0.012 * np.sin(5 * a) * (1 - k / 3) if k < 3 else 0.0), tilt=-0.1)
    rows += disc_cap(rows[-1])[1:]
    hats['ch_capeline'] = mesh_from([rows])
    # casquette : calotte + visière
    prof = [(0.002, 0.0), (0.004, 0.025), (0.0, 0.05), (-0.02, 0.075), (-0.05, 0.088)]
    rows = lathe(H, ey + 0.045, prof, tilt=-0.08)
    rows += disc_cap(rows[-1])[1:]
    vis = visor(H, ey + 0.045, 0.065, -0.08)
    hats['ch_casquette'] = mesh_from([rows]) ; append(hats['ch_casquette'], vis, wrap=False)
    # képi : cylindre rigide, dessus plat, visière
    prof = [(0.004, 0.0), (0.006, 0.03), (0.002, 0.075), (0.0, 0.08)]
    rows = lathe(H, ey + 0.04, prof, tilt=-0.05)
    rows += disc_cap(rows[-1], 0.0)[1:]
    hats['ch_kepi'] = mesh_from([rows]); append(hats['ch_kepi'], visor(H, ey + 0.04, 0.055, -0.05, droop=0.02), wrap=False)
    # casquette de marin / capitaine : calotte souple, dessus large
    prof = [(0.004, 0.0), (0.012, 0.025), (0.028, 0.055), (0.03, 0.065), (0.0, 0.072)]
    rows = lathe(H, ey + 0.042, prof, tilt=-0.1)
    rows += disc_cap(rows[-1], 0.004)[1:]
    hats['ch_marin'] = mesh_from([rows]); append(hats['ch_marin'], visor(H, ey + 0.042, 0.055, -0.1, droop=0.018), wrap=False)
    # béret
    prof = [(0.004, 0.0), (0.022, 0.012), (0.035, 0.03), (0.025, 0.045), (-0.02, 0.055), (-0.06, 0.058)]
    rows = lathe(H, ey + 0.058, prof, tilt=-0.15, roll=0.18)
    rows += disc_cap(rows[-1])[1:]
    hats['ch_beret'] = mesh_from([rows])
    # toque de cuisinier (plis)
    prof = [(0.004, 0.0), (0.006, 0.05), (0.018, 0.12), (0.04, 0.17), (0.035, 0.2), (0.0, 0.215)]
    rows = lathe(H, ey + 0.04, prof, brim_fn=lambda a, k: (0.004 * np.sin(18 * a) * (k > 0), 0.0), tilt=-0.05)
    rows += disc_cap(rows[-1], 0.01)[1:]
    hats['ch_cuisinier'] = mesh_from([rows])
    # tricorne : bord relevé, pincé en trois pointes
    def tri(a, k):
        pinch = np.cos(3 * (a - 0.0)) * 0.5 + 0.5
        if k <= 2:
            return (0.035 * pinch, 0.0)
        return (0.0, 0.0)
    prof = [(0.06, 0.06), (0.065, 0.02), (0.05, 0.0), (0.004, 0.005), (0.004, 0.04), (-0.02, 0.07), (-0.05, 0.08)]
    rows = lathe(H, ey + 0.048, prof, brim_fn=tri, tilt=-0.08)
    rows += disc_cap(rows[-1])[1:]
    hats['ch_tricorne'] = mesh_from([rows])
    # haut-de-forme
    prof = [(0.045, 0.012), (0.035, 0.0), (0.004, 0.0), (0.004, 0.01), (0.0, 0.08), (0.008, 0.16), (0.006, 0.165)]
    rows = lathe(H, ey + 0.048, prof, brim_fn=lambda a, k: (0.0, 0.012 * abs(np.sin(a)) if k == 0 else 0.0), tilt=-0.06)
    rows += disc_cap(rows[-1], 0.0)[1:]
    hats['ch_haut_de_forme'] = mesh_from([rows])
    # fez
    prof = [(0.003, 0.0), (0.0, 0.03), (-0.008, 0.07), (-0.01, 0.095)]
    rows = lathe(H, ey + 0.06, prof, tilt=-0.08)
    rows += disc_cap(rows[-1], 0.0)[1:]
    hats['ch_fez'] = mesh_from([rows])
    # coiffes souples (coques) -----------------------------------------
    hats['ch_bonnet'] = mesh_from([close_top(head_shell(H, -180, 180, 5, 88, 48, 14, lambda t, p: 0.012 + 0.006 * smooth(25, 5, p),
                                              extra=lambda t, p, q: np.array([0, 0.004, 0]) * (p < 20)))])
    hats['ch_bandana'] = mesh_from([close_top(head_shell(H, -180, 180, 30, 88, 48, 10, 0.007))])
    hats['ch_foulard_tete'] = foulard(H)
    hats['ch_capuche'] = hood(H)
    hats['ch_casque'] = mesh_from([close_top(head_shell(H, -180, 180, 18, 88, 48, 12, 0.016))])
    hats['ch_turban'] = turban(H)
    hats['ch_casque_aviateur'] = aviator(H)
    return hats


def append(m, rows, wrap=True):
    m.grid(rows, wrap=wrap, hem_from_bottom=False)


def visor(H, y_seat, length, tilt, droop=0.012, span=1.15, n=20):
    """visière : plaque courbe devant (span radians de part et d'autre de l'avant)."""
    ang = np.linspace(-span, span, n)
    _, r0all = H.ring_radius(y_seat, 64, 0.006)
    a64 = np.linspace(0, 2 * np.pi, 64, endpoint=False)
    rows = []
    for k, t in enumerate(np.linspace(0, 1, 5)):
        ring = []
        for a in ang:
            r0 = np.interp(a % (2 * np.pi), a64, r0all, period=2 * np.pi)
            w = length * np.cos(a * 0.9 / span * np.pi / 2) ** 0.6
            r = r0 + w * t
            yy = y_seat - droop * t * t
            ring.append([H.hc[0] + np.sin(a) * r, yy, H.hc[2] + np.cos(a) * r])
        rows.append(np.array(ring))
    pivot = np.array([H.hc[0], y_seat, H.hc[2]])
    return [rot_x(r, tilt, pivot) for r in rows]


def foulard(H):
    """foulard noué sur la tête : couvre le crâne, les oreilles et la nuque, encadre le visage,
    retombe dans le dos."""
    off = lambda t, p: 0.008 + 0.006 * smooth(-10, -35, p)
    ext = lambda t, p, q: np.array([0, 0, -0.012]) * smooth(-10, -40, p) * smooth(60, 140, abs(t))
    top, low, tl = framed_shell(H, 52.5, -40, 26, 88, 9, 10, off, ext)
    m = ClothMesh()
    m.grid(close_top(top), wrap=True, hem_from_bottom=False)
    rows = list(low)
    last = rows[-1]
    for k in range(1, 6):
        rows.append(last + np.array([0, -0.035 * k, -0.012 * k]) * smooth(70, 130, np.abs(tl))[:, None] + np.array([0, -0.01 * k, 0]))
    m.grid(rows, wrap=False, hem_from_bottom=False)
    return m


def hood(H):
    off = lambda t, p: 0.016 + 0.01 * smooth(20, -40, p)
    top, low, tl = framed_shell(H, 45, -45, 34, 89, 8, 10, off)
    m = ClothMesh()
    # pointe de la capuche vers l'arrière
    full = np.array([(k * 7.5 + 180.0) % 360.0 - 180.0 for k in range(48)])
    tip = top[0] + np.array([0, 0.02, -0.06]) * smooth(110, 180, np.abs(full))[:, None]
    m.grid(close_top([tip] + list(top)), wrap=True, hem_from_bottom=False)
    m.grid(low, wrap=False, hem_from_bottom=False)
    return m


def aviator(H):
    top, low, tl = framed_shell(H, 60, -38, 30, 88, 8, 10, 0.008)
    m = ClothMesh()
    m.grid(close_top(top), wrap=True, hem_from_bottom=False)
    m.grid(low, wrap=False, hem_from_bottom=False)
    return m


def turban(H):
    """turban : bandes de tissu plates enroulées en biais (elles se croisent sur le front),
    autour d'une calotte bombée."""
    m = ClothMesh()
    a = np.linspace(0, 2 * np.pi, 64, endpoint=False)
    base_y = H.c[1] + 0.03
    for k in range(5):
        tilt = (0.22 if k % 2 == 0 else -0.2) * (1.0 - 0.12 * k)
        yc = base_y + 0.011 + k * 0.019
        clear = 0.011 + 0.007 * k
        half_h, half_t = 0.016, 0.0065
        center, radial = [], []
        for ang in a:
            y = yc + np.sin(tilt) * np.cos(ang) * 0.085
            o = np.array([H.hc[0], min(y, H.top - 0.025), H.hc[2]])
            d = np.array([np.sin(ang), 0.0, np.cos(ang)])
            p = H.surface(d, o)
            r = np.hypot(p[0] - H.hc[0], p[2] - H.hc[2]) + clear + half_t
            center.append([H.hc[0] + np.sin(ang) * r, y + 0.004 * np.sin(3 * ang + k), H.hc[2] + np.cos(ang) * r])
            radial.append(d)
        center = np.array(center)
        radial = np.array(radial)
        # le haut de la bande penche vers l'intérieur (elle épouse le crâne qui se resserre)
        up = np.array([0.0, 1.0, 0.0])[None, :] - radial * (0.25 + 0.08 * k)
        up /= np.linalg.norm(up, axis=1, keepdims=True)
        rows = []
        for sgm in range(9):
            ph = 2 * np.pi * sgm / 8
            rows.append(center + radial * (half_t * np.cos(ph)) + up * (half_h * np.sin(ph)))
        m.grid(rows, wrap=True, hem_from_bottom=False)
    cap = close_top(head_shell(H, -180, 180, 40, 88, 40, 8, lambda t, p: 0.034 + 0.008 * smooth(40, 70, p)))
    m.grid(cap, wrap=True, hem_from_bottom=False)
    return m
