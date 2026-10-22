"""Vêtements : coques (faces du corps décalées le long des normales) et pièces amples (proxies).
Tout est défini sur le corps neutre ; le jeu recalcule tout pour chaque personnage."""
import numpy as np
import pickle
from hair import Body, smooth
from export import build_weights
from rig import HB

ARM_L = ['LeftShoulder', 'LeftArm', 'LeftForeArm', 'LeftHand']
ARM_R = ['RightShoulder', 'RightArm', 'RightForeArm', 'RightHand']
LEG_L = ['LeftUpLeg', 'LeftLeg', 'LeftFoot', 'LeftToeBase']
LEG_R = ['RightUpLeg', 'RightLeg', 'RightFoot', 'RightToeBase']


def seg_proj(P, A, B):
    d = B - A
    t = np.clip(((P - A) @ d) / (d @ d), 0, 1)
    Q = A + t[:, None] * d
    return t, np.linalg.norm(P - Q, axis=1)


class Features:
    """par sommet soudé du corps : partie (tronc, bras g/d, jambe g/d, tête), abscisse le long du membre."""

    def __init__(self, body):
        self.body = body
        V = body.V
        HJ = body.HJ
        nb = body.topo.nb
        bidx, bw = build_weights(body.topo, body.W)
        self.bidx, self.bw = bidx, bw
        H = np.zeros((len(V), len(HB)))
        for j in range(4):
            np.add.at(H, (np.arange(len(V)), bidx[:, j]), bw[:, j])
        self.H = H

        def grp(names):
            return H[:, [HB.index(n) for n in names]].sum(1)
        g_arm_l = grp(['LeftArm', 'LeftForeArm', 'LeftHand'])
        g_arm_r = grp(['RightArm', 'RightForeArm', 'RightHand'])
        g_leg_l = grp(LEG_L)
        g_leg_r = grp(LEG_R)
        g_head = grp(['Head', 'neck'])
        g_tor = grp(['Hips', 'Spine02', 'Spine01', 'Spine', 'LeftShoulder', 'RightShoulder'])
        G = np.stack([g_tor, g_arm_l, g_arm_r, g_leg_l, g_leg_r, g_head], 1)
        self.part = np.argmax(G, 1)          # 0 tronc 1 bras g 2 bras d 3 jambe g 4 jambe d 5 tête
        self.y = V[:, 1]
        # abscisses le long des membres (m depuis l'épaule / la hanche)
        self.s = np.zeros(len(V))
        for side, arm, leg in ((1, 'Left', 'Left'), (2, 'Right', 'Right')):
            A = [HJ[arm + 'Arm'], HJ[arm + 'ForeArm'], HJ[arm + 'Hand'], HJ[arm + 'Hand'] + (HJ[arm + 'Hand'] - HJ[arm + 'ForeArm']) * 0.8]
            self.s = self._arc(V, A, self.part == side, self.s)
            Lg = [HJ[leg + 'UpLeg'], HJ[leg + 'Leg'], HJ[leg + 'Foot'], HJ[leg + 'ToeBase'] + (HJ[leg + 'ToeBase'] - HJ[leg + 'Foot']) * 0.6]
            self.s = self._arc(V, Lg, self.part == side + 2, self.s)
        self.arm_len = np.linalg.norm(HJ['LeftForeArm'] - HJ['LeftArm'])
        self.fore_len = np.linalg.norm(HJ['LeftHand'] - HJ['LeftForeArm'])
        self.thigh_len = np.linalg.norm(HJ['LeftLeg'] - HJ['LeftUpLeg'])
        self.shin_len = np.linalg.norm(HJ['LeftFoot'] - HJ['LeftLeg'])
        self.neck_y = HJ['neck'][1]
        self.hips_y = HJ['Hips'][1]
        self.crotch_y = (HJ['LeftUpLeg'][1] + HJ['RightUpLeg'][1]) / 2 - 0.07
        self.waist_y = HJ['Spine01'][1] + 0.0
        self.ankle_y = HJ['LeftFoot'][1]
        self.knee_y = HJ['LeftLeg'][1]
        self.chest_y = HJ['Spine'][1]

    @staticmethod
    def _arc(V, pts, mask, s):
        idx = np.where(mask)[0]
        P = V[idx]
        best = np.full(len(idx), 1e9)
        acc = 0.0
        out = np.zeros(len(idx))
        for k in range(len(pts) - 1):
            t, d = seg_proj(P, pts[k], pts[k + 1])
            L = np.linalg.norm(pts[k + 1] - pts[k])
            m = d < best
            out[m] = acc + t[m] * L
            best[m] = d[m]
            acc += L
        s = s.copy()
        s[idx] = out
        return s


class Garments:
    """masques de faces (triangles de la peau) pour chaque type de vêtement « coque »."""

    def __init__(self, body, F):
        self.body, self.F = body, F
        topo = body.topo
        self.tris_split = topo.surfaces['peau'].reshape(-1, 3)
        self.tw = topo.split_w[self.tris_split]               # triangles en ids soudés
        V = body.V
        # les deux triangles d'un même quadrilatère MakeHuman sont traités ensemble (ourlets moins dentelés)
        q = self.tw.reshape(-1, 6)
        C = np.repeat(V[q].mean(1), 2, axis=0)
        self.cx, self.cy, self.cz = C[:, 0] - body.HJ['Hips'][0], C[:, 1], C[:, 2]
        parts = F.part[q]
        self.part = np.repeat(np.array([np.bincount(p, minlength=6).argmax() for p in parts]), 2)
        self.s = np.repeat(F.s[q].mean(1), 2)
        N = np.cross(V[self.tw[:, 1]] - V[self.tw[:, 0]], V[self.tw[:, 2]] - V[self.tw[:, 0]])
        N = -N / (np.linalg.norm(N, axis=1, keepdims=True) + 1e-12)   # triangles stockés en sens Godot (horaire)
        self.nrm = N

    def torso(self):
        return self.part == 0

    def arms(self):
        return (self.part == 1) | (self.part == 2)

    def legs(self):
        return (self.part == 3) | (self.part == 4)

    def neckline(self, depth_front=0.03, width=0.06, back=0.0):
        F = self.F
        cut = F.neck_y - 0.045 - back
        front = smooth(-0.0, 0.04, self.cz - self.body.HJ['neck'][2]) * smooth(width, width * 0.3, np.abs(self.cx))
        return self.cy < cut - depth_front * front

    def top(self, sleeve=0.6, low=None, neck_depth=0.03, neck_w=0.06, sleeveless=False):
        F = self.F
        low = F.crotch_y + 0.11 if low is None else low
        m = self.torso() & (self.cy > low) & self.neckline(neck_depth, neck_w)
        if not sleeveless:
            m |= self.arms() & (self.s < sleeve)
        else:
            # emmanchures : on dégage le haut de l'épaule près du bras
            m &= ~((np.abs(self.cx) > 0.13) & (self.cy > F.chest_y - 0.02))
        return m

    def trousers(self, length, waist=None):
        F = self.F
        waist = F.waist_y + 0.015 if waist is None else waist
        return (self.torso() & (self.cy < waist)) | (self.legs() & (self.s < length))

    def shoes(self, height):
        F = self.F
        return self.legs() & (self.s > F.thigh_len + F.shin_len - height)

    def band(self, y0, y1):
        return self.torso() & (self.cy > y0) & (self.cy < y1)


def hem_distance(tw, mask, V, nverts):
    """distance (géodésique approchée) au bord du vêtement, par sommet soudé."""
    from scipy.sparse import coo_matrix
    from scipy.sparse.csgraph import dijkstra
    t = tw[mask]
    edges = {}
    for a, b, c in t:
        for u, v in ((a, b), (b, c), (c, a)):
            k = (min(u, v), max(u, v))
            edges[k] = edges.get(k, 0) + 1
    border = set()
    for (u, v), n in edges.items():
        if n == 1:
            border.add(u); border.add(v)
    E = np.array(list(edges.keys()))
    L = np.linalg.norm(V[E[:, 0]] - V[E[:, 1]], axis=1)
    G = coo_matrix((np.concatenate([L, L]), (np.concatenate([E[:, 0], E[:, 1]]), np.concatenate([E[:, 1], E[:, 0]]))), shape=(nverts, nverts)).tocsr()
    src = np.array(sorted(border))
    if len(src) == 0:
        return np.full(nverts, 1.0), edges
    d = dijkstra(G, indices=src, min_only=True, limit=0.2)
    d[~np.isfinite(d)] = 0.2
    return d, edges


# =================================================================== coques

class Shell:
    """un vêtement coque : faces + décalage + coupes (pour lisser les ourlets)."""

    def __init__(self, name, mask, offset, cuts, layer, kind='tissu'):
        self.name, self.mask, self.offset, self.cuts, self.layer, self.kind = name, mask, offset, cuts, layer, kind


def build_shell(body, F, G, sh, ao_v):
    """-> dict prêt à exporter (indices locaux, sommets éclatés, décalages, glissements d'ourlet, distance à l'ourlet)."""
    topo = body.topo
    V = body.V
    tri_ids = np.where(sh.mask)[0]
    tris_s = G.tris_split[tri_ids]
    sv, local = np.unique(tris_s, return_inverse=True)
    local = local.reshape(-1, 3)
    w = topo.split_w[sv]
    # décalage : moindre dans les creux (aisselles, entrejambe, plis du coude)
    ao = np.clip(ao_v[w], 0, 1)
    off = sh.offset * (0.45 + 0.55 * ao)
    # semelles
    if sh.kind == 'chaussure':
        nrm_w = body.N[w]
        off = off + 0.01 * smooth(-0.3, -0.7, nrm_w[:, 1])
    hem, edges = hem_distance(G.tw, sh.mask, V, len(V))
    hem_v = hem[w]
    # ourlets : glisser les sommets du bord jusqu'à la ligne de coupe (vers l'extérieur du vêtement)
    border = set()
    for (u, v_), n in edges.items():
        if n == 1:
            border.add(u); border.add(v_)
    shift = np.zeros((len(sv), 3))
    # chaque sommet du bord est rattaché à la coupe la plus proche et glisse (sur la peau) jusqu'à la
    # ligne de coupe elle-même : l'ourlet suit une ligne nette au lieu des marches des quadrilatères.
    # Sous la rangée de triangles du bord, la peau est gardée (aucun trou si le bord recule).
    assign = {}
    for wid in border:
        best = None
        for ci, (field, thr, direction, sign) in enumerate(sh.cuts):
            f = field(wid)
            d = abs(f - thr)
            if best is None or d < best[0]:
                best = (d, ci, f)
        if best is not None and best[0] < 0.04:
            assign[wid] = (best[1], best[2])
    for i, wid in enumerate(w):
        if wid not in assign:
            continue
        ci, f = assign[wid]
        field, thr, direction, sign = sh.cuts[ci]
        delta = (thr - sign * 0.002) - f
        # vers l'extérieur du vêtement : jusqu'à 4 cm ; vers l'intérieur : 2,5 cm (pas de pli)
        if delta * sign > 0:
            delta = float(np.clip(delta, -0.025, 0.025))
        else:
            delta = float(np.clip(delta, -0.04, 0.04))
        sh_v = direction(wid) * delta
        ln = np.linalg.norm(sh_v)
        if ln > 0.045:
            sh_v *= 0.045 / ln
        shift[i] = sh_v
    on_border = np.array([int(x) in border for x in w])
    row = on_border[local].any(axis=1)
    # bande d'ourlet : bords -> peau
    bedges = [(u, v_) for (u, v_), n in edges.items() if n == 1]
    w2i = {}
    for i, wid in enumerate(w):
        w2i.setdefault(int(wid), i)
    extra_tris = []
    extra_src = []
    inner = {}
    for u, v_ in bedges:
        for x in (u, v_):
            if x not in inner:
                inner[x] = len(sv) + len(extra_src)
                extra_src.append(w2i[x])
        a, b = w2i[u], w2i[v_]
        ia, ib = inner[u], inner[v_]
        extra_tris += [[a, b, ib], [a, ib, ia]]
    n0 = len(sv)
    es = np.array(extra_src, dtype=np.int64)
    all_w = np.concatenate([w, w[es]]) if len(es) else w
    all_sv = np.concatenate([sv, sv[es]]) if len(es) else sv
    all_off = np.concatenate([off, np.full(len(es), -0.0015)]) if len(es) else off
    all_shift = np.concatenate([shift, shift[es]]) if len(es) else shift
    all_hem = np.concatenate([hem_v, np.zeros(len(es))]) if len(es) else hem_v
    tri = np.concatenate([local, np.array(extra_tris, dtype=np.int64).reshape(-1, 3)]) if extra_tris else local
    ts = np.where(row, -1, tri_ids)
    tri_skin = np.concatenate([ts, -np.ones(len(extra_tris), dtype=np.int64)])
    return dict(sv=all_sv, w=all_w, off=all_off, shift=all_shift, hem=all_hem, tri=tri, tri_skin=tri_skin)


def shell_catalog(body, F, G):
    V = body.V
    up = np.array([0.0, 1.0, 0.0])
    yfield = lambda wid: V[wid, 1]
    N = body.N

    def ydir(wid):
        """« vers le haut » en restant sur la peau : la verticale projetée sur le plan tangent,
        allongée pour qu'un pas de 1 change la hauteur de 1 (épaules, haut de la poitrine)."""
        n = N[wid]
        t = up - (up @ n) * n
        ln = np.linalg.norm(t)
        if ln < 1e-6:
            return up * 0.0
        t = t / ln
        return t / max(float(t @ up), 0.35)
    sfield = lambda wid: F.s[wid]

    def sdir(wid):
        HJ = body.HJ
        p = F.part[wid]
        names = {1: ('LeftArm', 'LeftForeArm', 'LeftHand'), 2: ('RightArm', 'RightForeArm', 'RightHand'),
                 3: ('LeftUpLeg', 'LeftLeg', 'LeftFoot'), 4: ('RightUpLeg', 'RightLeg', 'RightFoot')}.get(p)
        if names is None:
            return up
        a, b, c = (HJ[n] for n in names)
        L1 = np.linalg.norm(b - a)
        d = (b - a) if F.s[wid] < L1 else (c - b)
        return d / np.linalg.norm(d)

    def neckf(depth, width):
        nz = body.HJ['neck'][2]
        hx = body.HJ['Hips'][0]

        def f(wid):
            x, y, z = V[wid]
            front = smooth(0.0, 0.04, z - nz) * smooth(width, width * 0.3, abs(x - hx))
            return y + depth * front
        return f
    L_arm = F.arm_len + F.fore_len
    L_leg = F.thigh_len + F.shin_len
    neck_cut = F.neck_y - 0.045
    cat = {}

    def top(name, sleeve, low, nd, nw, off, layer, sleeveless=False):
        m = G.top(sleeve=sleeve, low=low, neck_depth=nd, neck_w=nw, sleeveless=sleeveless)
        cuts = [(yfield, low, ydir, +1), (neckf(nd, nw), neck_cut, ydir, -1)]
        if not sleeveless:
            cuts.append((sfield, sleeve, sdir, -1))
        cat[name] = Shell(name, m, off, cuts, layer)
    low_out = F.crotch_y + 0.11
    top('chemise_courte', 0.15, low_out, 0.035, 0.05, 0.007, 3)
    top('chemise_longue', L_arm - 0.02, low_out, 0.035, 0.05, 0.007, 3)
    top('chemise_rentree', L_arm - 0.02, F.waist_y - 0.03, 0.035, 0.05, 0.006, 1)
    top('tshirt', 0.13, low_out - 0.01, 0.015, 0.06, 0.005, 3)
    top('debardeur', 0.0, low_out - 0.01, 0.06, 0.07, 0.004, 3, sleeveless=True)
    top('pull', L_arm - 0.015, F.crotch_y + 0.07, 0.01, 0.06, 0.011, 4)
    top('veste', L_arm - 0.02, F.crotch_y + 0.04, 0.09, 0.07, 0.014, 5)
    top('gilet', 0.0, F.crotch_y + 0.1, 0.12, 0.06, 0.012, 5, sleeveless=True)
    top('corsage', 0.12, F.waist_y - 0.035, 0.06, 0.08, 0.006, 3)
    top('corsage_long', L_arm - 0.02, F.waist_y - 0.035, 0.03, 0.07, 0.006, 3)
    top('corsage_nu', 0.0, F.waist_y - 0.035, 0.07, 0.09, 0.005, 3, sleeveless=True)
    top('tunique_haut', L_arm - 0.03, F.crotch_y + 0.05, 0.05, 0.05, 0.008, 3)
    top('djellaba_haut', L_arm - 0.005, F.crotch_y + 0.02, 0.06, 0.04, 0.016, 5)

    def trousers(name, length, off, layer, waist=None):
        wy = F.waist_y + 0.015 if waist is None else waist
        m = G.trousers(length, wy)
        cat[name] = Shell(name, m, off, [(yfield, wy, ydir, -1), (sfield, length, sdir, -1)], layer)
    trousers('pantalon', L_leg - 0.03, 0.008, 2)
    trousers('pantacourt', F.thigh_len + F.shin_len * 0.55, 0.008, 2)
    trousers('bermuda', F.thigh_len + 0.03, 0.009, 2)
    trousers('short', F.thigh_len * 0.65, 0.008, 2)
    trousers('collant', L_leg - 0.02, 0.0025, 1)

    def shoes(name, h, off, layer):
        m = G.shoes(h)
        cat[name] = Shell(name, m, off, [(sfield, L_leg - h, sdir, +1)], layer, kind='chaussure')
    shoes('chaussures', 0.075, 0.007, 6)
    shoes('bottes', F.shin_len * 0.55, 0.009, 6)
    shoes('bottes_hautes', F.shin_len * 0.95, 0.01, 6)
    # col, ceinture, écharpe
    # col : foulard noué autour du cou (le cou appartient à la « tête » dans les parties du corps)
    nz = body.HJ['neck'][2]
    around = np.hypot(G.cx, G.cz - nz) < 0.082
    m = ((G.part == 0) | (G.part == 5)) & (G.cy > F.neck_y - 0.02) & (G.cy < F.neck_y + 0.035) & around
    cat['col'] = Shell('col', m, 0.009, [(yfield, F.neck_y + 0.035, ydir, -1), (yfield, F.neck_y - 0.02, ydir, +1)], 6)
    m = G.band(F.waist_y - 0.012, F.waist_y + 0.028)
    cat['ceinture'] = Shell('ceinture', m, 0.016, [(yfield, F.waist_y - 0.012, ydir, +1), (yfield, F.waist_y + 0.028, ydir, -1)], 7)
    m = G.band(F.neck_y - 0.075, F.neck_y + 0.04) & (G.cy > F.neck_y - 0.075)
    cat['echarpe'] = Shell('echarpe', m, 0.022, [(yfield, F.neck_y + 0.04, ydir, -1), (yfield, F.neck_y - 0.075, ydir, +1)], 8)
    return cat
