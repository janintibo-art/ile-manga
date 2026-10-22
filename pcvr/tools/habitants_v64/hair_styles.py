"""Coiffures et barbes (cartes) sur la tête neutre."""
import numpy as np
from hair import Body, grow, grow2, ribbon, CardMesh, smooth

UP = np.array([0.0, 1.0, 0.0])


def tangent(body, p, v):
    g = body.grad(p)[0]
    v = v - g * np.dot(v, g)
    n = np.linalg.norm(v)
    return v / n if n > 1e-6 else -UP


def parted_comb(body, part_x=0.0, back_bias=0.35, side=1.0, fringe=0.0):
    """peigné de part et d'autre d'une raie : vers les côtés puis vers le bas ; derrière, vers le bas."""
    def comb(p):
        x, y, z, ax, th = body.local(p)
        sx = np.sign(x - part_x) if abs(x - part_x) > 0.002 else side
        front = smooth(120, 60, th)
        v = np.array([sx * 0.9 * front, -0.55 - 0.6 * (1 - front), -back_bias * front - 0.3 * (1 - front)])
        if fringe > 0 and z > 0.0 and y > 0.04:
            v = v * (1 - fringe) + np.array([sx * 0.4, -0.6, 0.6]) * fringe
        return tangent(body, p, v / np.linalg.norm(v))
    return comb


def back_comb(body, to=None):
    """tout tiré vers un point (chignon, queue) ou vers l'arrière."""
    def comb(p):
        if to is not None:
            v = to - p
        else:
            v = np.array([0, -0.2, -1.0])
        return tangent(body, p, v / np.linalg.norm(v))
    return comb


def length_field(body, p, top, side, back):
    x, y, z, ax, th = body.local(p)
    a = smooth(40, 110, th)
    b = smooth(110, 170, th)
    return top * (1 - a) + side * a * (1 - b) + back * b


def strands_to_cards(body, mesh, strands, widths, cols, rng, taper=0.55, shades=None):
    for i, s in enumerate(strands):
        L, R, T = ribbon(body, s, widths[i], taper)
        mesh.add_ribbon(body, L, R, T, cols[i], rng, shade=1.0 if shades is None else shades[i])


def root_layer(body, r):
    """0 près de la ligne d'implantation, 1 au sommet : les mèches du haut recouvrent les autres."""
    x, y, z, ax, th = body.local(r)
    hl = body.hairline(th)
    return float(np.clip((y - hl) / max(0.105 - hl, 0.02), 0, 1))


def style_court(body, seed=1, n=900, top=0.055, side=0.028, back=0.032, part_x=0.03, fringe=0.0, col=1):
    rng = np.random.default_rng(seed)
    roots, normals = body.sample_region(n, lambda x, y, z, ax, th: body.scalp_weight(x, y, z, ax, th), seed=seed)
    comb = parted_comb(body, part_x=part_x, back_bias=0.9, fringe=fringe)
    mesh = CardMesh()
    strands, widths, cols, shades = [], [], [], []
    for i, (r, n0) in enumerate(zip(roots, normals)):
        lay = root_layer(body, r)
        ln = length_field(body, r, top, side, back) * (0.75 + 0.5 * rng.random())
        s = grow2(body, r, n0, comb, ln, 4, hug=0.003 + 0.007 * lay + 0.002 * rng.random(), gravity=0.1, stiff=0.45, seed=seed + i)
        strands.append(s)
        widths.append(0.014 + 0.01 * rng.random())
        cols.append(1 if rng.random() < 0.55 else (0 if rng.random() < 0.5 else 7))
        shades.append(0.9 + 0.2 * lay)
    strands_to_cards(body, mesh, strands, widths, cols, rng, taper=0.6, shades=shades)
    return mesh


def style_long(body, seed=2, n=650, top=0.36, side=0.38, back=0.46, part_x=0.0, col=1, wavy=False, curl=0.0):
    rng = np.random.default_rng(seed)
    roots, normals = body.sample_region(n, lambda x, y, z, ax, th: body.scalp_weight(x, y, z, ax, th), seed=seed)
    comb = parted_comb(body, part_x=part_x, back_bias=0.35)
    mesh = CardMesh()
    strands, widths, cols, shades = [], [], [], []
    for i, (r, n0) in enumerate(zip(roots, normals)):
        lay = root_layer(body, r)
        ln = length_field(body, r, top, side, back) * (0.85 + 0.25 * rng.random())
        s = grow2(body, r, n0, comb, ln, 14, hug=0.004 + 0.012 * lay + 0.003 * rng.random(), gravity=0.5, stiff=0.55, seed=seed + i,
                  curl=curl, curl_r=0.012 if curl else 0.0, wave=0.25 if wavy else 0.0)
        strands.append(s)
        widths.append(0.022 + 0.016 * rng.random())
        c = (3 if rng.random() < 0.6 else 4) if wavy else (0 if rng.random() < 0.5 else (1 if rng.random() < 0.7 else 2))
        if curl:
            c = 5
        cols.append(c)
        shades.append(0.88 + 0.24 * lay)
    strands_to_cards(body, mesh, strands, widths, cols, rng, taper=0.45, shades=shades)
    return mesh


def style_generic(body, seed, n, top, side, back, part_x, hug0, hug1, segs, gravity, stiff, width, cols_p, fringe=0.0,
                  back_bias=0.35, curl=0.0, curl_r=0.0, wave=0.0, region=None, comb=None, taper=0.5, lift=0.0):
    rng = np.random.default_rng(seed)
    wf = region or (lambda x, y, z, ax, th: body.scalp_weight(x, y, z, ax, th))
    roots, normals = body.sample_region(n, wf, seed=seed)
    comb = comb or parted_comb(body, part_x=part_x, back_bias=back_bias, fringe=fringe)
    mesh = CardMesh()
    strands, widths, cols, shades = [], [], [], []
    for i, (r, n0) in enumerate(zip(roots, normals)):
        lay = root_layer(body, r)
        ln = length_field(body, r, top, side, back) * (0.82 + 0.3 * rng.random())
        s = grow2(body, r, n0, comb, ln, segs, hug=hug0 + hug1 * lay + 0.002 * rng.random(), gravity=gravity, stiff=stiff,
                  seed=seed + i, curl=curl, curl_r=curl_r, wave=wave, lift=lift)
        strands.append(s)
        widths.append(width[0] + (width[1] - width[0]) * rng.random())
        cols.append(int(rng.choice(len(cols_p), p=np.array([c[1] for c in cols_p]) / sum(c[1] for c in cols_p))) and cols_p[0][0] or cols_p[0][0])
        cols[-1] = cols_p[int(rng.choice(len(cols_p), p=np.array([c[1] for c in cols_p]) / sum(c[1] for c in cols_p)))][0]
        shades.append(0.88 + 0.24 * lay)
    strands_to_cards(body, mesh, strands, widths, cols, rng, taper=taper, shades=shades)
    return mesh, strands


def tie_comb(body, tie, ease=0.5):
    def comb(p):
        v = tie - p
        return tangent(body, p, v / (np.linalg.norm(v) + 1e-9))
    return comb


def bundle(body, mesh, rng, start, n, length, spread, width, col, segs=12, gravity=0.8, curl=0.0, seed=0, hug=0.012, dir0=None):
    """faisceau de mèches partant d'un même point (queue de cheval, mèches de chignon)."""
    for k in range(n):
        off = rng.normal(0, spread, 3)
        r = start + off
        d0 = dir0 if dir0 is not None else np.array([0.0, -0.3, -1.0])
        d0 = d0 / np.linalg.norm(d0)
        comb = lambda p, d0=d0: d0
        s = grow2(body, r, d0, comb, length * (0.8 + 0.35 * rng.random()), segs, hug=hug, gravity=gravity, stiff=0.7,
                  free_y=1.0, seed=seed + k, curl=curl, curl_r=0.01 if curl else 0.0)
        L, R, T = ribbon(body, s, width * (0.8 + 0.4 * rng.random()), 0.6)
        mesh.add_ribbon(body, L, R, T, col, rng)


def tube(body, mesh, rng, path, radius, col, sides=6, shade=1.0, twist=0.0):
    """tube (dread, tresse) le long d'un chemin ; u autour, v le long."""
    n = len(path)
    base = mesh.n
    u0 = (col + 0.06) / 8.0
    u1 = (col + 0.94) / 8.0
    bright = shade * (0.85 + 0.3 * rng.random())
    for i in range(n):
        a = path[max(i - 1, 0)]
        b = path[min(i + 1, n - 1)]
        t = b - a
        t /= np.linalg.norm(t) + 1e-9
        e1 = np.cross(t, [0, 0, 1])
        if np.linalg.norm(e1) < 1e-3:
            e1 = np.cross(t, [1, 0, 0])
        e1 /= np.linalg.norm(e1)
        e2 = np.cross(t, e1)
        rr = radius[i] if hasattr(radius, '__len__') else radius
        for k in range(sides + 1):
            ang = 2 * np.pi * k / sides + twist * i
            nrm = e1 * np.cos(ang) + e2 * np.sin(ang)
            mesh.P.append(path[i] + nrm * rr)
            mesh.UV.append([u0 + (u1 - u0) * k / sides, i / (n - 1)])
            mesh.T.append(t)
            mesh.N.append(nrm)
            mesh.C.append([bright, bright, bright, 1.0])
    for i in range(n - 1):
        for k in range(sides):
            a = base + i * (sides + 1) + k
            b = a + 1
            c = a + (sides + 1)
            d = c + 1
            mesh.I += [a, c, b, b, c, d]
    mesh.n += n * (sides + 1)


def style_queue(body, seed=5, tie=None, tail=0.3, n=500, col=1):
    rng = np.random.default_rng(seed)
    tie = tie if tie is not None else body.c + np.array([0.0, 0.035, -0.165])
    mesh, _ = style_generic(body, seed, n, 0.2, 0.2, 0.2, 0.0, 0.003, 0.008, 6, 0.0, 0.3, (0.016, 0.026), [(1, 0.6), (0, 0.4)],
                            comb=tie_comb(body, tie), taper=0.2)
    # longueurs limitées par la distance au nœud : on recoupe en refaisant pousser jusqu'au nœud
    bundle(body, mesh, rng, tie + np.array([0, 0, -0.012]), 50, tail, 0.008, 0.035, 0, segs=8, gravity=0.9, seed=seed * 7)
    return mesh


def style_chignon(body, seed=6, n=500, col=1):
    rng = np.random.default_rng(seed)
    bun = body.c + np.array([0.0, 0.065, -0.15])
    mesh, _ = style_generic(body, seed, n, 0.2, 0.2, 0.2, 0.0, 0.003, 0.007, 6, 0.0, 0.25, (0.016, 0.026), [(1, 0.6), (0, 0.4)],
                            comb=tie_comb(body, bun), taper=0.2)
    # le chignon : spirales de mèches autour d'un centre
    g = body.grad(bun)[0]
    e1 = np.cross(g, [1, 0, 0]); e1 /= np.linalg.norm(e1)
    e2 = np.cross(g, e1)
    for k in range(46):
        r0 = 0.012 + 0.026 * rng.random()
        a0 = rng.random() * 6.28
        pts = []
        h = rng.random() * 0.02
        for s in range(14):
            a = a0 + s * 0.42
            rr = r0 * (1 - 0.15 * s / 13)
            pts.append(bun + g * (0.018 + h + 0.008 * np.sin(s * 0.5)) + (e1 * np.cos(a) + e2 * np.sin(a)) * rr)
        pts = np.array(pts)
        L, R, T = ribbon(body, pts, 0.022, 0.3, outward=lambda p, c=bun, g=g: (p - c + g * 0.01) / (np.linalg.norm(p - c + g * 0.01) + 1e-9))
        mesh.add_ribbon(body, L, R, T, 0 if rng.random() < 0.5 else 1, rng)
    return mesh


def style_tresse(body, seed=7, n=500, length=0.38, tie=None):
    rng = np.random.default_rng(seed)
    tie = tie if tie is not None else body.c + np.array([0.0, -0.05, -0.16])
    mesh, _ = style_generic(body, seed, n, 0.2, 0.2, 0.2, 0.0, 0.003, 0.008, 6, 0.0, 0.3, (0.016, 0.026), [(1, 0.6), (0, 0.4)],
                            comb=tie_comb(body, tie), taper=0.2)
    braid(body, mesh, rng, tie + np.array([0, -0.01, -0.01]), length, 0.022)
    return mesh


def braid(body, mesh, rng, start, length, r0, seed=0, direction=None):
    """natte : trois brins tressés (tubes) qui tombent en glissant sur le dos."""
    down = np.array([0, -1.0, 0]) if direction is None else direction / np.linalg.norm(direction)
    segs = 24
    axis = [start]
    p = start.copy()
    for s in range(segs):
        q = p + down * (length / segs)
        dq = body.dist(q)[0]
        if dq < r0 * 1.2:
            q = q + body.grad(q)[0] * (r0 * 1.2 - dq)
        axis.append(q)
        p = q
    axis = np.array(axis)
    for k in range(3):
        pts = []
        for i, a in enumerate(axis):
            t = i / segs
            ph = t * length / 0.05 * 2 * np.pi + k * 2 * np.pi / 3
            w = r0 * (1 - 0.45 * t)
            side = np.cross(down, body.grad(a)[0])
            if np.linalg.norm(side) < 1e-3:
                side = np.array([1.0, 0, 0])
            side /= np.linalg.norm(side)
            out = body.grad(a)[0]
            pts.append(a + side * np.sin(ph) * w * 0.7 + out * np.cos(ph) * w * 0.4)
        rad = [r0 * 0.55 * (1 - 0.4 * i / segs) for i in range(len(pts))]
        tube(body, mesh, rng, np.array(pts), rad, 1, sides=6)
    # la pointe libre
    bundle(body, mesh, rng, axis[-1], 12, 0.06, 0.004, 0.02, 2, segs=4, gravity=1.0, seed=seed + 99)


def style_couronne(body, seed=8, n=500):
    """chauve : une couronne de cheveux courts sur les côtés et la nuque."""
    def reg(x, y, z, ax, th):
        return body.scalp_weight(x, y, z, ax, th) * smooth(0.045, 0.025, y) * smooth(50, 75, th)
    mesh, _ = style_generic(body, seed, n, 0.02, 0.02, 0.022, 0.0, 0.003, 0.003, 3, 0.2, 0.4, (0.012, 0.02), [(7, 0.6), (1, 0.4)],
                            region=reg, back_bias=0.9, taper=0.6)
    return mesh


def style_dreads(body, seed=9, n=46, length=0.3):
    rng = np.random.default_rng(seed)
    roots, normals = body.sample_region(n, lambda x, y, z, ax, th: body.scalp_weight(x, y, z, ax, th), seed=seed)
    comb = parted_comb(body, part_x=0.0, back_bias=0.4)
    mesh = CardMesh()
    # une calotte de cheveux courts sous les mèches
    cap, _ = style_generic(body, seed + 1, 500, 0.025, 0.02, 0.02, 0.0, 0.003, 0.004, 3, 0.1, 0.4, (0.014, 0.02), [(6, 0.5), (7, 0.5)], taper=0.6)
    for i, (r, n0) in enumerate(zip(roots, normals)):
        lay = root_layer(body, r)
        s = grow2(body, r, n0, comb, length * (0.75 + 0.4 * rng.random()), 12, hug=0.01 + 0.012 * lay, gravity=0.7, stiff=0.6, seed=seed + i)
        tube(body, cap, rng, s, [0.007 * (1 - 0.3 * j / len(s)) for j in range(len(s))], 6, sides=5, twist=0.4)
    return cap


# =================================================================== barbes

def beard_regions(body):
    lip_top, lip_bot, nose_bot = -0.0575, -0.0795, -0.047

    def must(x, y, z, ax, th):
        return (th < 78) * smooth(0.034, 0.024, ax) * smooth(nose_bot + 0.002, nose_bot - 0.003, y) * smooth(lip_top - 0.004, lip_top + 0.001, y)

    def chin(x, y, z, ax, th):
        return (th < 78) * smooth(0.045, 0.03, ax) * smooth(lip_bot + 0.0, lip_bot - 0.005, y) * smooth(-0.135, -0.115, y)

    def cheek(x, y, z, ax, th):
        cl = np.interp(th, [0, 12, 25, 40, 55, 66, 72], [-0.045, -0.044, -0.038, -0.03, -0.018, -0.005, 0.004])
        return smooth(73, 66, th) * smooth(cl + 0.001, cl - 0.006, y) * smooth(-0.135, -0.11, y) * smooth(0.014, 0.024, ax)
    return must, chin, cheek


def beard_comb(body):
    def comb(p):
        x, y, z, ax, th = body.local(p)
        sx = np.sign(x) if abs(x) > 0.003 else 0.0
        if y > -0.06 and ax < 0.035:          # moustache : vers le bas et l'extérieur
            v = np.array([sx * 0.7, -1.0, 0.25])
        elif y < -0.1:                        # sous le menton : vers le bas
            v = np.array([sx * 0.1, -1.0, 0.35])
        else:
            v = np.array([sx * 0.15, -1.0, 0.3])
        return tangent(body, p, v / np.linalg.norm(v))
    return comb


def style_beard(body, kind, seed=11):
    rng = np.random.default_rng(seed)
    must, chin, cheek = beard_regions(body)
    mesh = CardMesh()
    comb = beard_comb(body)
    parts = []
    if kind == 'moustache':
        parts = [(must, 170, 0.013, 0.0022, 3, (0.007, 0.011))]
    elif kind == 'courte':
        parts = [(must, 150, 0.012, 0.0022, 3, (0.007, 0.011)),
                 (lambda *a: np.maximum(chin(*a), cheek(*a)), 700, 0.014, 0.0025, 3, (0.009, 0.014))]
    elif kind in ('longue', 'nain_large', 'nain_tresse', 'nain_fourche'):
        L = {'longue': 0.2, 'nain_large': 0.36, 'nain_tresse': 0.3, 'nain_fourche': 0.32}[kind]
        parts = [(must, 150, 0.045 if kind != 'longue' else 0.035, 0.004, 4, (0.012, 0.018)),
                 (cheek, 300, L * 0.75, 0.006, 7, (0.022, 0.034)),
                 (chin, 200, L, 0.008, 8, (0.028, 0.04))]
    for wf, n, length, hug, segs, wd in parts:
        roots, normals = body.sample_region(n, wf, seed=seed + n)
        for i, (r, n0) in enumerate(zip(roots, normals)):
            x, y, z, ax, th = body.local(r)
            ln = length * (0.7 + 0.5 * rng.random())
            if kind == 'nain_fourche':
                spread = np.array([np.sign(x) * 0.35, 0, 0]) if abs(x) > 0.004 else np.zeros(3)
            else:
                spread = np.zeros(3)
            c2 = (lambda p, sp=spread: (lambda v: v / np.linalg.norm(v))(comb(p) + sp))
            s = grow2(body, r, n0, c2, ln, segs, hug=hug + 0.003 * rng.random(), gravity=0.6 if segs > 6 else 0.2,
                      stiff=0.55, free_y=-0.105, seed=seed + i, wave=0.12 if kind.startswith('nain') else 0.05)
            Lr, Rr, T = ribbon(body, s, wd[0] + (wd[1] - wd[0]) * rng.random(), 0.55)
            short = kind in ('moustache', 'courte')
            mesh.add_ribbon(body, Lr, Rr, T, (7 if rng.random() < 0.6 else 2) if short else (6 if rng.random() < 0.5 else 1), rng)
    if kind == 'nain_tresse':
        start = body.c + np.array([0.0, -0.2, 0.12])
        braid(body, mesh, rng, start, 0.25, 0.022, direction=np.array([0, -1.0, 0.15]))
    return mesh
