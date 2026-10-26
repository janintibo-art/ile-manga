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
    # chapeau de sorcier : bord large et souple, grand cône dont la pointe retombe vers l'arrière
    prof = [(0.095, -0.016), (0.075, -0.006), (0.04, 0.0), (0.004, 0.004), (0.004, 0.03), (-0.012, 0.07), (-0.03, 0.115),
            (-0.047, 0.16), (-0.06, 0.2), (-0.07, 0.235), (-0.077, 0.262)]
    rows = lathe(H, ey + 0.05, prof, brim_fn=lambda a, k: (0.0, -0.01 * (1.0 + 0.6 * np.cos(a)) * (1 - k / 2) if k < 2 else 0.0),
                 tilt=-0.1)
    rows += disc_cap(rows[-1], 0.0, 2)[1:]
    base = ey + 0.05
    bent = []
    for r in rows:
        dy = float(r[:, 1].mean()) - base
        u = max(0.0, (dy - 0.11) / 0.16)
        bent.append(r + np.array([0.0, -0.025 * u * u, -0.07 * u * u]))
    hats['ch_sorcier'] = mesh_from([bent])
    # coiffes souples (coques) -----------------------------------------
    hats['ch_bonnet'] = mesh_from([close_top(head_shell(H, -180, 180, 5, 88, 48, 14, lambda t, p: 0.012 + 0.006 * smooth(25, 5, p),
                                              extra=lambda t, p, q: np.array([0, 0.004, 0]) * (p < 20)))])
    hats['ch_bandana'] = mesh_from([close_top(head_shell(H, -180, 180, 30, 88, 48, 10, 0.007))])
    hats['ch_foulard_tete'] = foulard(H)
    hats['ch_capuche'] = hood(H)
    hats['ch_casque'] = mesh_from([close_top(head_shell(H, -180, 180, 18, 88, 48, 12, 0.016))])
    hats['ch_turban'] = turban(H)
    hats['ch_casque_aviateur'] = aviator(H)
    # V75 : Port-Boucan : le bandana noué derrière la tête (deux pans qui pendent) et le casque de skate
    hats['ch_bandana_noeud'] = bandana_knot(H)
    hats['ch_casque_skate'] = skate_helmet(H)
    # V76 : les Lumens d'Astralys : antennes (et taches lumineuses des tempes), crête de cristal, filaments
    hats['ch_lumen_antennes'] = lumen_antennes(H)
    hats['ch_lumen_cristal'] = lumen_cristal(H)
    hats['ch_lumen_filaments'] = lumen_filaments(H)
    return hats


def blob(c, rx, ry, rz, n=12, m=7):
    """petite boule (nœud) : anneaux du haut vers le bas."""
    rows = []
    for j in range(m + 1):
        ph = np.pi / 2 - np.pi * j / m
        ring = []
        for i in range(n):
            a = 2 * np.pi * i / n
            ring.append(c + np.array([np.cos(ph) * np.sin(a) * rx, np.sin(ph) * ry, np.cos(ph) * np.cos(a) * rz]))
        rows.append(np.array(ring))
    return rows


def bandana_knot(H):
    """V75 : bandana noué : une coque du front (bas sur le front) à la nuque, un nœud derrière et deux pans."""
    off = lambda t, p: 0.007 + 0.003 * smooth(60, 160, abs(t))
    # plus bas derrière que devant : la coque descend jusqu'à phi -12° à l'arrière
    ext = lambda t, p, q: np.array([0.0, -0.022, -0.004]) * smooth(90, 170, abs(t)) * smooth(40, 15, p)
    m = mesh_from([close_top(head_shell(H, -180, 180, 15, 88, 48, 12, off, extra=ext))])
    back = H.surface(np.array([0.0, np.sin(np.radians(8)), -np.cos(np.radians(8))]))
    n = H.body.grad(back)[0]
    k = back + n * 0.018 + np.array([0.0, -0.02, 0.0])
    m.grid(blob(k, 0.019, 0.015, 0.013), wrap=True, hem_from_bottom=False)
    # deux pans : bandes plates qui retombent en s'écartant un peu
    for sx in (-1.0, 1.0):
        rows = []
        for j in range(6):
            t = j / 5
            ctr = k + np.array([sx * (0.008 + 0.022 * t), -0.012 - 0.075 * t, -0.006 - 0.01 * t])
            w = 0.016 * (1 - 0.35 * t)
            rows.append(np.array([ctr + np.array([-w, 0, 0]), ctr, ctr + np.array([w, 0, 0])]))
        m.grid(rows, wrap=False, hem_from_bottom=False)
    return m


def skate_helmet(H):
    """V75 : casque de skate : coque épaisse et bombée, du front aux oreilles, avec un bord replié vers la tête."""
    off = lambda t, p: 0.026 + 0.004 * smooth(30, 80, p)
    ext = lambda t, p, q: np.array([0.0, 0.006, 0.0]) * smooth(60, 20, abs(t)) * smooth(30, 12, p)
    rows = close_top(head_shell(H, -180, 180, 12, 88, 48, 13, off, extra=ext))
    last = rows[-1]
    inward = last - np.array([H.hc[0], last[:, 1].mean(), H.hc[2]])
    inward[:, 1] = 0.0
    inward /= np.linalg.norm(inward, axis=1, keepdims=True) + 1e-9
    rows = list(rows) + [last - inward * 0.012 + np.array([0, -0.003, 0]), last - inward * 0.024]
    return mesh_from([rows])


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


# ------------------------------------------------------------------ V76 : les Lumens
# UV.y = part de lumière (0 : la matière, 1 : la lueur), lue par les motifs 12 et 14 du shader des tissus.

def _unit(v):
    return v / (np.linalg.norm(v) + 1e-12)


def _dir(th, ph):
    th, ph = np.radians(th), np.radians(ph)
    return np.array([np.sin(th) * np.cos(ph), np.sin(ph), np.cos(th) * np.cos(ph)])


def _sag(s, x=0.0):
    """direction depuis le centre de la tête dans le plan médian : s = 0 devant (à l'horizontale),
    90 en haut, 180 derrière ; x : écart latéral (m, approximatif)."""
    s = np.radians(s)
    return _unit(np.array([x / 0.09, np.sin(s), np.cos(s)]))


def _vert(m, p, n, t, u, g):
    m.P.append(np.asarray(p, float)); m.N.append(_unit(np.asarray(n, float))); m.T.append(_unit(np.asarray(t, float)))
    m.UV.append([float(u), float(g)]); m.H.append(0.05); m.WH.append(1.0)
    m.n += 1
    return m.n - 1


def _frame(a):
    ref = np.array([1.0, 0.0, 0.0]) if abs(a[0]) < 0.9 else np.array([0.0, 1.0, 0.0])
    u = _unit(np.cross(a, ref))
    v = np.cross(a, u)
    return u, v


def _tube(m, pts, radii, glows, k=6):
    """tube le long d'une polyligne (repère transporté), fermé au départ par un anneau réduit."""
    pts = np.asarray(pts, float)
    n = len(pts)
    tan = np.gradient(pts, axis=0)
    tan = tan / (np.linalg.norm(tan, axis=1, keepdims=True) + 1e-12)
    u, v = _frame(tan[0])
    base = m.n
    for i in range(n):
        if i > 0:
            u = _unit(u - tan[i] * np.dot(u, tan[i]))
            v = np.cross(tan[i], u)
        for j in range(k):
            a = 2 * np.pi * j / k
            d = u * np.cos(a) + v * np.sin(a)
            _vert(m, pts[i] + d * radii[i], d, tan[i], j / k, glows[i])
    for i in range(n - 1):
        for j in range(k):
            a = base + i * k + j
            b = base + i * k + (j + 1) % k
            m.I += [a, a + k, b, b, a + k, b + k]


def _ball(m, c, r, g, squash=None, k=10, rows=6):
    """sphère (squash : (axe, facteur) pour l'aplatir)."""
    base = m.n
    for i in range(rows + 1):
        ph = np.pi / 2 - np.pi * i / rows
        for j in range(k):
            a = 2 * np.pi * j / k
            d = np.array([np.cos(ph) * np.cos(a), np.sin(ph), np.cos(ph) * np.sin(a)])
            q = d * r
            nn = d
            if squash is not None:
                ax, f = squash
                q = q + ax * np.dot(q, ax) * (f - 1.0)
                nn = _unit(d + ax * np.dot(d, ax) * (1.0 / f - 1.0))
            _vert(m, c + q, nn, np.array([-np.sin(a), 0.0, np.cos(a)]), j / k, g)
    for i in range(rows):
        for j in range(k):
            a = base + i * k + j
            b = base + i * k + (j + 1) % k
            m.I += [a, b, a + k, b, b + k, a + k]


def _bezier(P, n):
    P = np.asarray(P, float)
    t = np.linspace(0, 1, n)[:, None]
    return (1 - t) ** 3 * P[0] + 3 * (1 - t) ** 2 * t * P[1] + 3 * (1 - t) * t ** 2 * P[2] + t ** 3 * P[3]


def lumen_antennes(H):
    """deux antennes souples (une tige fine, une petite boule de lumière au bout) et, sur chaque tempe,
    une ligne de taches lumineuses qui remonte du coin de l'œil vers le crâne."""
    m = ClothMesh()
    up = np.array([0.0, 1.0, 0.0])
    for sx in (-1.0, 1.0):
        b = H.surface(_sag(72, sx * 0.034))
        n = H.body.grad(b)[0]
        x = np.array([sx, 0.0, 0.0])
        fwd = np.array([0.0, 0.0, 1.0])
        P = [b - n * 0.004, b + n * 0.035 + up * 0.012 + x * 0.008, b + up * 0.075 + x * 0.034 - fwd * 0.01, b + up * 0.098 + x * 0.05 + fwd * 0.014]
        pts = _bezier(P, 16)
        t = np.linspace(0, 1, len(pts))
        _tube(m, pts, 0.0034 - 0.0016 * t, 0.12 * t ** 3, k=7)
        _ball(m, b - n * 0.001, 0.0062, 0.0, squash=(n, 0.6))
        tip = pts[-1] + _unit(pts[-1] - pts[-2]) * 0.008
        _ball(m, tip, 0.0105, 1.0)
        # les taches des tempes
        for k in range(6):
            th, ph = 70 + 8.5 * k, 8 + 6.5 * k
            q = H.surface(_dir(sx * th, ph))
            nq = H.body.grad(q)[0]
            r = 0.0027 - 0.00024 * k
            _ball(m, q - nq * r * 0.15, r, 0.85, squash=(nq, 0.45), k=8, rows=4)
    return m


def _crystal(m, b, a, L, w, lat, g0=0.25, g1=0.95):
    """un cristal : prisme hexagonal à facettes (aplati de côté), pointe en haut ; sommets dupliqués par face."""
    a = _unit(a)
    u = _unit(lat - a * np.dot(lat, a))
    v = np.cross(a, u)
    ring = lambda c, r, rot: [c + (u * np.cos(t + rot) * 0.62 + v * np.sin(t + rot)) * r for t in np.linspace(0, 2 * np.pi, 7)[:-1]]
    R0 = ring(b, w, 0.0)
    R1 = ring(b + a * L * 0.6, w * 1.08, 0.0)
    tip = b + a * L
    gm = (g0 + g1) / 2

    def face(p0, p1, p2, gs):
        nn = np.cross(p1 - p0, p2 - p0)
        c = (p0 + p1 + p2) / 3
        if np.dot(nn, c - (b + a * L * 0.4)) < 0:
            p1, p2 = p2, p1
            gs = (gs[0], gs[2], gs[1])
            nn = -nn
        i0 = _vert(m, p0, nn, p1 - p0, 0.0, gs[0])
        i1 = _vert(m, p1, nn, p1 - p0, 0.5, gs[1])
        i2 = _vert(m, p2, nn, p1 - p0, 1.0, gs[2])
        m.I += [i0, i1, i2]
    for i in range(6):
        j = (i + 1) % 6
        face(R0[i], R0[j], R1[i], (g0, g0, gm))
        face(R0[j], R1[j], R1[i], (g0, gm, gm))
        face(R1[i], R1[j], tip, (gm, gm, g1))


def lumen_cristal(H):
    """la crête de cristal : une arête de cristaux du haut du front à l'arrière du crâne (les plus grands
    au sommet), et de petits cristaux de part et d'autre."""
    m = ClothMesh()
    rng = np.random.default_rng(76)
    back = np.array([0.0, 0.0, -1.0])
    for k, s in enumerate(np.linspace(64, 150, 10)):
        q = H.surface(_sag(s))
        n = H.body.grad(q)[0]
        f = np.sin(np.pi * (s - 50) / 115) ** 1.6
        L = 0.022 + 0.062 * f
        a = _unit(n + back * 0.35 + np.array([0.0, 0.25, 0.0]))
        _crystal(m, q - n * 0.005, a, L, 0.006 + 0.085 * L, np.array([1.0, 0.0, 0.0]))
        if 0 < k < 9:
            for sx in (-1.0, 1.0):
                s2 = s + rng.uniform(-4, 4)
                q2 = H.surface(_sag(s2, sx * 0.016))
                n2 = H.body.grad(q2)[0]
                L2 = L * rng.uniform(0.4, 0.58)
                a2 = _unit(n2 + back * 0.3 + np.array([sx * 0.35, 0.15, 0.0]))
                _crystal(m, q2 - n2 * 0.003, a2, L2, 0.004 + 0.07 * L2, np.array([1.0, 0.0, 0.0]), g0=0.15, g1=0.8)
    return m


def lumen_filaments(H):
    """les filaments : de longues fibres fines et souples, lumineuses comme des fibres optiques, qui
    poussent sur une bande au milieu du crâne et retombent en panache vers la nuque ; pointes allumées."""
    m = ClothMesh()
    body = H.body
    rng = np.random.default_rng(77)
    up, back = np.array([0.0, 1.0, 0.0]), np.array([0.0, 0.0, -1.0])
    n_f = 64
    for i in range(n_f):
        s = rng.uniform(64, 132)
        x = rng.uniform(-0.024, 0.024) * (1.0 - 0.3 * (s < 75))
        q = H.surface(_sag(s, x))
        n = body.grad(q)[0]
        ln = (0.13 + 0.12 * (s - 64) / 68) * rng.uniform(0.85, 1.15)
        d = _unit(back * 0.8 + n * 0.45 + np.array([np.sign(x) * (abs(x) / 0.024) ** 1.5 * 0.55, 0.0, 0.0]))
        pts = [q - n * 0.003]
        nseg = 16
        stp = ln / nseg
        for k in range(nseg):
            d = _unit(d + np.array([0.0, -0.16, 0.0]) + rng.normal(0, 0.02, 3))
            p = pts[-1] + d * stp
            dist = body.dist(p)[0]
            if dist < 0.009:
                gr = body.grad(p)[0]
                p = p + gr * (0.009 - dist)
                d = _unit(d - gr * min(0.0, float(np.dot(d, gr))))
            pts.append(p)
        pts = np.array(pts)
        t = np.linspace(0, 1, len(pts))
        _tube(m, pts, 0.0017 - 0.0008 * t, 0.08 + 0.55 * t ** 3, k=5)
        _ball(m, pts[-1], 0.0026, 1.0, k=6, rows=4)
    return m
