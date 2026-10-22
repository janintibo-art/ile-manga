"""Ajustement d'un corps MakeHuman sur le squelette du héros (mêmes os, mêmes rotations
de repos, longueurs propres au personnage) ; poids de peau mixamo -> os du héros."""
import numpy as np, json
from mh import RIG, WEIGHTS, mixamo_joints

from chemins import cache
HERO = json.load(open(cache('hero_skel.json')))
HB = [b['name'] for b in HERO['bones']]
HPARENT = [b['parent'] for b in HERO['bones']]


def quat_to_mat(q):
    x, y, z, w = q
    return np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                     [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                     [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])


HGR = {b['name']: quat_to_mat(b['gq']) for b in HERO['bones']}          # rotation globale de repos
HGO = {b['name']: np.array(b['go']) / 100.0 for b in HERO['bones']}     # origine globale (m)

# mixamo -> héros
MAP = {'Hips': 'Hips', 'Spine': 'Spine02', 'Spine1': 'Spine01', 'Spine2': 'Spine', 'Neck': 'neck', 'Head': 'Head'}
for s in ('Left', 'Right'):
    for b in ('Shoulder', 'Arm', 'ForeArm', 'Hand', 'UpLeg', 'Leg', 'Foot', 'ToeBase'):
        MAP[s + b] = s + b


def hero_bone_of(mixamo):
    if mixamo in MAP:
        return MAP[mixamo]
    for s in ('Left', 'Right'):
        if mixamo.startswith(s + 'Hand'):
            return s + 'Hand'
    raise KeyError(mixamo)


def rot_between(a, b):
    a = a / np.linalg.norm(a)
    b = b / np.linalg.norm(b)
    v = np.cross(a, b)
    c = float(np.dot(a, b))
    if c < -0.9999:
        raise ValueError('opposés')
    vx = np.array([[0, -v[2], v[1]], [v[2], 0, -v[0]], [-v[1], v[0], 0]])
    return np.eye(3) + vx + vx @ vx * (1.0 / (1.0 + c))


def axis_angle(axis, ang):
    axis = axis / np.linalg.norm(axis)
    x, y, z = axis
    c, s = np.cos(ang), np.sin(ang)
    C = 1 - c
    return np.array([[c + x * x * C, x * y * C - z * s, x * z * C + y * s],
                     [y * x * C + z * s, c + y * y * C, y * z * C - x * s],
                     [z * x * C - y * s, z * y * C + x * s, c + z * z * C]])


# dense weight matrix over mixamo bones
MIX = list(RIG.keys())
MIXN = [m.replace('mixamorig:', '') for m in MIX]


def weight_matrix(n):
    W = np.zeros((n, len(MIX)))
    for j, m in enumerate(MIX):
        for vi, w in WEIGHTS.get(m, []):
            if vi < n:
                W[vi, j] += w
    s = W.sum(1, keepdims=True)
    s[s == 0] = 1
    return W / s


ALIGN = {'LeftArm', 'LeftForeArm', 'RightArm', 'RightForeArm', 'LeftUpLeg', 'LeftLeg', 'RightUpLeg', 'RightLeg'}


def fit(base, Vdm, W, finger_curl=0.35, thumb_curl=0.2):
    """Vdm : positions MakeHuman (dm). Renvoie (V en m dans l'espace du héros, joints hero {nom: pos m}, échelle de mouvement)."""
    V = Vdm * 0.1
    J = mixamo_joints(base, V)      # nom -> (tete, queue, parent)
    # sol
    body = base.group_verts('body')
    ground = V[body, 1].min()
    # transformations de repose (rotation R autour de la tête de l'os, puis translation)
    R = {}
    Jn = {}
    order = []
    seen = set()

    def visit(m):
        if m in seen:
            return
        p = J[m][2]
        if p:
            visit(p)
        seen.add(m)
        order.append(m)
    for m in MIXN:
        visit(m)
    for m in order:
        head, tail, p = J[m]
        Rp = R[p] if p else np.eye(3)
        if m in ALIGN:
            hb = MAP[m]
            hdir = HGR[hb][:, 1]          # axe Y de l'os du héros (vers l'enfant)
            R[m] = rot_between(tail - head, hdir)
        elif 'Hand' in m and m not in ('LeftHand', 'RightHand'):
            # doigts : légère flexion naturelle (main au repos)
            side = 'Left' if m.startswith('Left') else 'Right'
            hand_h, hand_t, _ = J[side + 'Hand']
            d = tail - head
            # axe de flexion : perpendiculaire au doigt et à la normale de la paume
            idx = J[side + 'HandIndex1'][0]
            pin = J[side + 'HandPinky1'][0]
            across = idx - pin
            curl = thumb_curl if 'Thumb' in m else finger_curl
            ax = np.cross(d, across)
            # la flexion doit amener le bout du doigt vers la paume (vers le bas/l'intérieur) :
            # sens choisi pour que le bout descende (paume vers le sol en pose A)
            test = axis_angle(ax, curl) @ d
            if test[1] > d[1]:
                ax = -ax
            R[m] = axis_angle(ax, curl) @ Rp
        else:
            R[m] = Rp
        if p:
            Jn[m] = Jn[p] + R[p] @ (head - J[p][0])
        else:
            Jn[m] = head.copy()
    # LBS
    Vn = np.zeros_like(V)
    for j, m in enumerate(MIXN):
        w = W[:, j]
        nz = w > 1e-6
        if not nz.any():
            continue
        Vn[nz] += w[nz, None] * ((V[nz] - J[m][0]) @ R[m].T + Jn[m])
    # joints du héros
    HJ = {}
    for m, hb in MAP.items():
        HJ[hb] = Jn[m]
    # bout de la tête et devant du visage
    HJ['head_end'] = Jn['Head'] + R['Head'] @ (J['Head'][1] - J['Head'][0])
    # sol à 0
    shift = np.array([0.0, -ground, 0.0])
    # bassin : hauteur proportionnelle (pivot comme chez le héros) ; aplomb des hanches
    leg_mid = (HJ['LeftUpLeg'] + HJ['RightUpLeg']) / 2 + shift
    hero_leg_mid = (HGO['LeftUpLeg'] + HGO['RightUpLeg']) / 2
    s = leg_mid[1] / hero_leg_mid[1]
    shift[0] += hero_leg_mid[0] * s - leg_mid[0]
    shift[2] += hero_leg_mid[2] * s - leg_mid[2]
    Vn += shift
    for k in HJ:
        HJ[k] = HJ[k] + shift
    HJ['Hips'] = HGO['Hips'] * s
    HJ['headfront'] = HJ['Head'] + np.array([0.0, 0.0, 0.09])
    return Vn, HJ, s, shift


def hero_weights(W, n_keep=4):
    """W (n, mixamo) -> (indices (n,4) des os du héros, poids (n,4))."""
    n = W.shape[0]
    H = np.zeros((n, len(HB)))
    for j, m in enumerate(MIXN):
        H[:, HB.index(hero_bone_of(m))] += W[:, j]
    idx = np.argsort(-H, axis=1)[:, :n_keep]
    w = np.take_along_axis(H, idx, 1)
    s = w.sum(1, keepdims=True)
    s[s == 0] = 1
    w = w / s
    return idx, w


def local_rests(HJ):
    """Origines locales (cm) de chaque os, dans le repère de repos du parent (rotations du héros)."""
    out = []
    for i, b in enumerate(HERO['bones']):
        p = b['parent']
        if p < 0:
            out.append(np.array(b['o']))       # le bassin garde le repos du héros (échelle de mouvement)
            continue
        pn = HB[p]
        o = HGR[pn].T @ ((HJ[b['name']] - HJ[pn]) * 100.0)
        out.append(o)
    return out
