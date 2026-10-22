"""Export : base partagée (topologie, UV, poids) + corps propres à chaque personnage."""
import numpy as np
from mh import Base, MH, apply_targets, macro_targets, modifier_targets
from rig import weight_matrix, fit, hero_weights, local_rests, HB
import gdvar

from chemins import OUT


def load_mhclo(path):
    lines = [l.strip() for l in open(path)]
    scales = {}
    refs, ws, offs = [], [], []
    inv = False
    for l in lines:
        if not l or l.startswith('#'):
            continue
        a = l.split()
        if a[0] in ('x_scale', 'y_scale', 'z_scale'):
            scales[a[0][0]] = (int(a[1]), int(a[2]), float(a[3]))
        elif a[0] == 'verts':
            inv = True
            continue
        elif inv:
            if len(a) == 1:
                refs.append([int(a[0])] * 3); ws.append([1, 0, 0]); offs.append([0, 0, 0])
            elif len(a) >= 9:
                refs.append([int(a[0]), int(a[1]), int(a[2])])
                ws.append([float(a[3]), float(a[4]), float(a[5])])
                offs.append([float(a[6]), float(a[7]), float(a[8])])
            else:
                inv = False
    return np.array(refs), np.array(ws), np.array(offs), scales


def fit_proxy(V, clo):
    refs, ws, offs, sc = clo
    s = np.array([abs(V[sc[k][0]][i] - V[sc[k][1]][i]) / sc[k][2] for i, k in enumerate('xyz')])
    return (V[refs] * ws[:, :, None]).sum(1) + offs * s


def load_simple_obj(path):
    V, VT, F, FT = [], [], [], []
    for line in open(path):
        if line.startswith('v '):
            V.append([float(x) for x in line.split()[1:4]])
        elif line.startswith('vt '):
            VT.append([float(x) for x in line.split()[1:3]])
        elif line.startswith('f '):
            p = line.split()[1:]
            F.append([int(x.split('/')[0]) - 1 for x in p])
            FT.append([int(x.split('/')[1]) - 1 for x in p])
    return np.array(V), np.array(VT), F, FT


class Topology:
    """Liste des sommets « soudés » (base + yeux) et des surfaces en sommets « éclatés » (pos+uv)."""
    SURF = [('peau', ['body']), ('cils', ['helper-l-eyelashes-1', 'helper-l-eyelashes-2', 'helper-r-eyelashes-1', 'helper-r-eyelashes-2']),
            ('dents', ['helper-upper-teeth', 'helper-lower-teeth']), ('langue', ['helper-tongue'])]

    def __init__(self, base):
        self.base = base
        self.eye_clo = load_mhclo(MH + '/eyes/high-poly/high-poly.mhclo')
        eV, eVT, eF, eFT = load_simple_obj(MH + '/eyes/high-poly/high-poly.obj')
        self.eye_n = len(eV)
        used = set()
        for name, groups in self.SURF:
            for g in groups:
                used.update(base.group_verts(g).tolist())
        self.welded = np.array(sorted(used))                     # indices dans base.V
        self.nb = len(self.welded)
        remap = -np.ones(base.n, dtype=np.int64)
        remap[self.welded] = np.arange(self.nb)
        self.nw = self.nb + self.eye_n
        split_w, split_uv = [], []
        key = {}

        def sv(w, uv):
            k = (w, round(uv[0], 6), round(uv[1], 6))
            if k not in key:
                key[k] = len(split_w)
                split_w.append(w)
                split_uv.append([uv[0], 1.0 - uv[1]])
            return key[k]
        self.surfaces = {}
        self.face_of_tri = {}
        for name, groups in self.SURF:
            tris = []
            ftri = []
            for g in groups:
                gf = base.group_faces(g)
                uvmap = None
                if 'eyelashes' in g:
                    # UV des cils ramenées à [0,1] : u le long de la paupière, v = 1 à la racine
                    uvs = base.VT[base.FT[gf].ravel()]
                    lo, hi = uvs.min(0), uvs.max(0)
                    vv = base.V[base.F[gf].ravel()]
                    eye = base.V[base.group_verts('joint-l-eye' if '-l-' in g else 'joint-r-eye')].mean(0)
                    dist = np.linalg.norm(vv - eye, axis=1)
                    vn = (uvs[:, 1] - lo[1]) / (hi[1] - lo[1])
                    root_high = np.corrcoef(vn, -dist)[0, 1] > 0
                    def uvmap(t, lo=lo, hi=hi, root_high=root_high):
                        u = (t[0] - lo[0]) / (hi[0] - lo[0])
                        v = (t[1] - lo[1]) / (hi[1] - lo[1])
                        if not root_high:
                            v = 1 - v
                        return np.array([u, 1 - v])     # sv() retourne v : racine -> 1 après inversion
                for fi in gf:
                    f = base.F[fi]
                    ft = base.FT[fi]
                    ids = [sv(int(remap[f[k]]), uvmap(base.VT[ft[k]]) if uvmap else base.VT[ft[k]]) for k in range(4)]
                    tris += [ids[0], ids[2], ids[1], ids[0], ids[3], ids[2]]
                    ftri += [fi, fi]
            self.surfaces[name] = np.array(tris)
            self.face_of_tri[name] = np.array(ftri)
        # yeux (sans la cornée transparente, qui recouvrirait l'iris)
        from PIL import Image
        ea = np.asarray(Image.open(MH + '/eyes/materials/brown_eye.png').convert('RGBA'))[..., 3]
        tris = []
        for f, ft in zip(eF, eFT):
            cu = np.mean([eVT[t][0] for t in ft])
            cv = 1.0 - np.mean([eVT[t][1] for t in ft])
            if ea[min(int(cv * ea.shape[0]), ea.shape[0] - 1), min(int(cu * ea.shape[1]), ea.shape[1] - 1)] < 128:
                continue
            ids = [sv(self.nb + f[k], eVT[ft[k]]) for k in range(len(f))]
            for k in range(1, len(ids) - 1):
                tris += [ids[0], ids[k + 1], ids[k]]
        self.surfaces['yeux'] = np.array(tris)
        self.split_w = np.array(split_w)
        self.split_uv = np.array(split_uv)

    def welded_positions(self, Vbase_dm):
        """positions (dm) des sommets soudés : base + yeux ajustés."""
        eyes = fit_proxy(Vbase_dm, self.eye_clo)
        return np.concatenate([Vbase_dm[self.welded], eyes], 0)


def build_weights(topo, W):
    """poids hero par sommet soudé ; les yeux suivent la tête."""
    idx, w = hero_weights(W[topo.welded])
    eidx = np.zeros((topo.eye_n, 4), dtype=np.int64)
    eidx[:, 0] = HB.index('Head')
    ew = np.zeros((topo.eye_n, 4))
    ew[:, 0] = 1
    return np.concatenate([idx, eidx]), np.concatenate([w, ew])


def make_body(base, topo, W, tlist, full=False):
    V = apply_targets(base.V, tlist)
    Vn, HJ, s, shift = fit(base, V, W)
    eyes = fit_proxy(V, topo.eye_clo) * 0.1 + shift
    Vw = np.concatenate([Vn[topo.welded], eyes], 0)
    if full:
        return Vw, HJ, s, Vn
    return Vw, HJ, s


def _pad256(a):
    n = (len(a) + 255) // 256 * 256
    out = np.zeros((n, 3))
    out[:len(a)] = a
    return out


def half_bytes(a):
    return np.ascontiguousarray(np.asarray(a, dtype='<f2').ravel()).tobytes()


def vertex_normals(V, tris):
    n = np.zeros_like(V)
    t = V[tris]
    fn = np.cross(t[:, 1] - t[:, 0], t[:, 2] - t[:, 0])
    for k in range(3):
        np.add.at(n, tris[:, k], fn)
    l = np.linalg.norm(n, axis=1, keepdims=True)
    l[l == 0] = 1
    return n / l


def welded_normals(topo, Vw):
    """normales lissées sur les sommets soudés (coutures d'UV invisibles).
    Godot : faces avant dans le sens horaire -> on inverse pour le calcul."""
    N = np.zeros_like(Vw)
    for name, tris in topo.surfaces.items():
        tw = topo.split_w[tris.reshape(-1, 3)][:, ::-1]
        n = vertex_normals(Vw, tw)
        used = np.unique(tw)
        N[used] = n[used]
    l = np.linalg.norm(N, axis=1, keepdims=True)
    l[l == 0] = 1
    return N / l


def split_tangents(topo, Vw, N):
    """tangentes (x,y,z,w) par sommet éclaté, calculées sur la forme neutre (communes à tous)."""
    P = Vw[topo.split_w]
    UV = topo.split_uv
    Ns = N[topo.split_w]
    T = np.zeros_like(P)
    B = np.zeros_like(P)
    for name, tris in topo.surfaces.items():
        t = tris.reshape(-1, 3)
        p0, p1, p2 = P[t[:, 0]], P[t[:, 1]], P[t[:, 2]]
        u0, u1, u2 = UV[t[:, 0]], UV[t[:, 1]], UV[t[:, 2]]
        e1, e2 = p1 - p0, p2 - p0
        d1, d2 = u1 - u0, u2 - u0
        r = d1[:, 0] * d2[:, 1] - d2[:, 0] * d1[:, 1]
        r = np.where(np.abs(r) < 1e-12, 1e-12, r)
        sdir = (e1 * d2[:, 1:2] - e2 * d1[:, 1:2]) / r[:, None]
        tdir = (e2 * d1[:, 0:1] - e1 * d2[:, 0:1]) / r[:, None]
        for k in range(3):
            np.add.at(T, t[:, k], sdir)
            np.add.at(B, t[:, k], tdir)
    T = T - Ns * (T * Ns).sum(1, keepdims=True)
    l = np.linalg.norm(T, axis=1, keepdims=True)
    bad = l[:, 0] < 1e-9
    l[bad] = 1
    T = T / l
    T[bad] = [1, 0, 0]
    w = np.where((np.cross(Ns, T) * B).sum(1) < 0, -1.0, 1.0)
    return np.concatenate([T, w[:, None]], 1)


def surface_pack(topo, sname):
    tris = topo.surfaces[sname]
    sv, local = np.unique(tris, return_inverse=True)
    return sv, local


def write_base(topo, W, Vw0, path, refs=None):
    bidx, bw = build_weights(topo, W)
    N0 = welded_normals(topo, Vw0)
    TAN = split_tangents(topo, Vw0, N0)
    d = {'nw': int(topo.nw), 'base': gdvar.v3(Vw0), 'bone_names': HB, 'surfaces': list(topo.surfaces.keys()) + ['visage']}
    if refs is not None:
        d.update(refs)
    E, touched = expression_deltas(topo.base, topo)
    ft = face_triangles(topo, touched)
    d['visage_tris'] = gdvar.i32(ft)
    d['expressions'] = list(E.keys())
    surfs = dict(topo.surfaces)
    surfs['visage'] = topo.surfaces['peau'].reshape(-1, 3)[ft].ravel()
    for sname in surfs:
        tris = surfs[sname]
        sv, local = np.unique(tris, return_inverse=True)
        wid = topo.split_w[sv]
        if sname in ('visage', 'cils', 'dents', 'langue'):
            for en, De in E.items():
                d['bs_%s_%s' % (sname, en)] = gdvar.v3(De[wid])
        d['w_' + sname] = gdvar.i32(wid)
        d['i_' + sname] = gdvar.i32(local.ravel())
        d['uv_' + sname] = gdvar.v2(topo.split_uv[sv])
        d['t_' + sname] = gdvar.f32(TAN[sv])
        d['b_' + sname] = gdvar.i32(bidx[wid])
        d['p_' + sname] = gdvar.f32(bw[wid])
    return gdvar.save(path, d)


QUANT = 10000.0     # 0,1 mm


def oct8(N):
    n = N / (np.abs(N).sum(1, keepdims=True) + 1e-12)
    x, y, z = n[:, 0], n[:, 1], n[:, 2]
    sx = np.where(x >= 0, 1.0, -1.0)
    sy = np.where(y >= 0, 1.0, -1.0)
    ox = np.where(z < 0, (1 - np.abs(y)) * sx, x)
    oy = np.where(z < 0, (1 - np.abs(x)) * sy, y)
    return np.clip(np.round(ox * 127), -127, 127).astype(np.int8), np.clip(np.round(oy * 127), -127, 127).astype(np.int8)


def write_npc(topo, Vw, Vw0, HJ, s, path, meta=None):
    rest = local_rests(HJ)
    q = np.round((Vw - Vw0) * QUANT).astype(np.int64)
    assert q.min() > -32768 and q.max() < 32768, (q.min(), q.max())
    a = q.astype('<i2').T.copy().view(np.uint8).reshape(3, -1, 2)      # plans x, y, z
    shuf = np.concatenate([a[:, :, 0].ravel(), a[:, :, 1].ravel()])     # octets faibles puis forts
    N = welded_normals(topo, Vw)
    ox, oy = oct8(N)
    d = {
        'dq': gdvar.u8(shuf),
        'nq': gdvar.u8(np.concatenate([ox, oy]).view(np.uint8)),
        'rest': gdvar.v3(np.array(rest)),
        'joints': gdvar.v3(np.array([HJ[b] for b in HB])),
        'motion_scale': float(s),
    }
    if meta:
        d.update(meta)
    return gdvar.save(path, d)


# =================================================================== expressions (paupières, bouche)

EXPR = {
    'cligne': ['expression/units/caucasian/eye-left-closure', 'expression/units/caucasian/eye-right-closure'],
    'bouche': ['expression/units/caucasian/mouth-open'],
    'sourire': ['expression/units/caucasian/mouth-corner-puller'],
}


def expression_deltas(base, topo):
    """écarts (m) par sommet soudé pour chaque expression ; ensemble des sommets touchés."""
    from mh import load_target
    remap = -np.ones(base.n, dtype=np.int64)
    remap[topo.welded] = np.arange(topo.nb)
    out = {}
    touched = set()
    for name, ts in EXPR.items():
        D = np.zeros((topo.nw, 3))
        for t in ts:
            idx, d = load_target(t)
            w = remap[idx]
            ok = w >= 0
            D[w[ok]] += d[ok] * 0.1
            touched.update(w[ok][np.linalg.norm(d[ok], axis=1) > 1e-5].tolist())
        out[name] = D
    return out, touched


def face_triangles(topo, touched):
    """triangles de la peau touchés par une expression (+ un anneau autour)."""
    tw = topo.split_w[topo.surfaces['peau'].reshape(-1, 3)]
    t = set(touched)
    ring = set()
    hit = np.array([any(v in t for v in tri) for tri in tw])
    for tri in tw[hit]:
        ring.update(tri.tolist())
    hit2 = np.array([all(v in ring for v in tri) or any(v in t for v in tri) for tri in tw])
    return np.where(hit2)[0]
