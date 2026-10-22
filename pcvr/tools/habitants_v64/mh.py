"""Chargement de MakeHuman (CC0) : maillage de base, cibles (targets), macros, rig mixamo."""
import numpy as np, json, os, functools

from chemins import MH, MPFB


def load_obj(path=MH + '/3dobjs/base.obj'):
    V, VT, F, FT, G = [], [], [], [], []
    cur = None
    groups = []
    for line in open(path):
        if line.startswith('v '):
            V.append([float(x) for x in line.split()[1:4]])
        elif line.startswith('vt '):
            VT.append([float(x) for x in line.split()[1:3]])
        elif line.startswith('g '):
            cur = line.split()[1]
            if cur not in groups:
                groups.append(cur)
        elif line.startswith('f '):
            parts = line.split()[1:]
            F.append([int(p.split('/')[0]) - 1 for p in parts])
            FT.append([int(p.split('/')[1]) - 1 for p in parts])
            G.append(groups.index(cur))
    return np.array(V), np.array(VT), np.array(F), np.array(FT), np.array(G), groups


class Base:
    def __init__(self):
        self.V, self.VT, self.F, self.FT, self.G, self.groups = load_obj()
        self.n = len(self.V)

    def group_faces(self, name):
        return np.where(self.G == self.groups.index(name))[0]

    def group_verts(self, name):
        return np.unique(self.F[self.group_faces(name)].ravel())


@functools.lru_cache(maxsize=None)
def load_target(rel):
    """rel : chemin relatif à data/targets, sans extension. Renvoie (indices, deltas) ou None."""
    p = MH + '/targets/' + rel + '.target'
    if not os.path.exists(p):
        return None
    idx, d = [], []
    for line in open(p):
        if not line.strip() or line[0] == '#':
            continue
        a = line.split()
        idx.append(int(a[0]))
        d.append([float(a[1]), float(a[2]), float(a[3])])
    return np.array(idx, dtype=np.int64), np.array(d, dtype=float).reshape(-1, 3)


def _three(v):
    """Valeur 0..1 -> poids (min, moyen, max)."""
    mx = max(0.0, v * 2 - 1)
    mn = max(0.0, 1 - v * 2)
    return {'min': mn, 'average': 1 - mx - mn, 'max': mx}


def macro_targets(p):
    """p : gender, age, muscle, weight, height, proportions, african, asian, caucasian,
    breastsize, breastfirmness (0..1). Renvoie [(cible, poids)]."""
    g = {'female': 1 - p['gender'], 'male': p['gender']}
    a = p['age']
    if a < 0.5:
        young = max(0.0, (a - 0.1875) * 3.2)
        ages = {'baby': max(0.0, 1 - a * 5.333), 'young': young,
                'child': max(0.0, min(1.0, 5.333 * a) - young), 'old': 0.0}
    else:
        old = max(0.0, a * 2 - 1)
        ages = {'baby': 0.0, 'child': 0.0, 'young': 1 - old, 'old': old}
    mu = _three(p['muscle'])
    we = _three(p['weight'])
    races = {'african': p['african'], 'asian': p['asian'], 'caucasian': p['caucasian']}
    s = sum(races.values())
    races = {k: v / s for k, v in races.items()}
    out = []
    for gk, gv in g.items():
        for ak, av in ages.items():
            if gv * av <= 1e-6:
                continue
            for rk, rv in races.items():
                if rv > 1e-6:
                    out.append(('macrodetails/%s-%s-%s' % (rk, gk, ak), gv * av * rv))
            for mk, mv in mu.items():
                for wk, wv in we.items():
                    w = gv * av * mv * wv
                    if w <= 1e-6:
                        continue
                    out.append(('macrodetails/universal-%s-%s-%smuscle-%sweight' % (gk, ak, mk, wk), w))
                    h = _three(p['height'])
                    for hk in ('min', 'max'):
                        if h[hk] > 1e-6:
                            out.append(('macrodetails/height/%s-%s-%smuscle-%sweight-%sheight' % (gk, ak, mk, wk, hk), w * h[hk]))
                    pr = p.get('proportions', 0.5)
                    ideal = max(0.0, pr * 2 - 1)
                    unc = max(0.0, 1 - pr * 2)
                    if ideal > 1e-6:
                        out.append(('macrodetails/proportions/%s-%s-%smuscle-%sweight-idealproportions' % (gk, ak, mk, wk), w * ideal))
                    if unc > 1e-6:
                        out.append(('macrodetails/proportions/%s-%s-%smuscle-%sweight-uncommonproportions' % (gk, ak, mk, wk), w * unc))
                    if gk == 'female':
                        cup = _three(p.get('breastsize', 0.5))
                        firm = _three(p.get('breastfirmness', 0.5))
                        for ck, cv in cup.items():
                            for fk, fv in firm.items():
                                if ck == 'average' and fk == 'average':
                                    continue
                                if cv * fv > 1e-6:
                                    out.append(('breast/female-%s-%smuscle-%sweight-%scup-%sfirmness' % (ak, mk, wk, ck, fk), w * cv * fv))
    return out


def modifier_targets(mods):
    """mods : {'nose/nose-trans-up|down': v, 'head/head-oval': v, ...}
    Clé 'groupe/cible-min|max' : v<0 -> min, v>0 -> max. Clé sans '|' : poids direct."""
    out = []
    for k, v in mods.items():
        if abs(v) < 1e-4:
            continue
        if '|' in k:
            base, mm = k.split('|')
            grp, name = base.split('/')
            lo, hi = mm.split(',')
            out.append(('%s/%s-%s' % (grp, name, hi if v > 0 else lo), abs(v)))
        else:
            out.append((k, v))
    return out


def apply_targets(V0, tlist):
    V = V0.copy()
    for name, w in tlist:
        t = load_target(name)
        if t is None:
            if name.startswith('macrodetails/') or name.startswith('breast/'):
                continue
            raise FileNotFoundError(name)
        idx, d = t
        V[idx] += d * w
    return V


# ------------------------------------------------------------------ rig mixamo (MPFB2, CC0)

RIG = json.load(open(MPFB + '/rigs/standard/rig.mixamo.json'))['bones']
WEIGHTS = json.load(open(MPFB + '/rigs/standard/weights.mixamo.json'))['weights']


def joint_pos(base, V, spec):
    st = spec['strategy']
    if st == 'CUBE':
        vs = base.group_verts(spec['cube_name'])
        return V[vs].mean(0)
    if st == 'MEAN':
        return V[spec['vertex_indices']].mean(0)
    if st == 'VERTEX':
        return V[spec['vertex_index']]
    raise ValueError(st)


def mixamo_joints(base, V):
    out = {}
    for b, d in RIG.items():
        out[b.replace('mixamorig:', '')] = (joint_pos(base, V, d['head']), joint_pos(base, V, d['tail']), d['parent'].replace('mixamorig:', ''))
    return out
