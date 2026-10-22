"""Cartes de base (position, normale, zone) du corps neutre dans l'espace UV."""
import numpy as np, os, pickle
from mh import *
from rig import *
from export import *
from landmarks import landmarks
from uvraster import *

from chemins import cache
CACHE = cache('cache_maps_%d.pkl')


def neutral():
    base = Base(); W = weight_matrix(base.n); topo = Topology(base)
    P0 = dict(gender=0.5, age=0.5, muscle=0.5, weight=0.5, height=0.5, african=1, asian=1, caucasian=1)
    Vw0, HJ, s, Vf = make_body(base, topo, W, macro_targets(P0), full=True)
    return base, W, topo, Vw0, HJ, Vf


def body_maps(size=2048):
    path = CACHE % size
    if os.path.exists(path):
        return pickle.load(open(path, 'rb'))
    base, W, topo, Vw0, HJ, Vf = neutral()
    N0 = welded_normals(topo, Vw0)
    tris = topo.surfaces['peau'].reshape(-1, 3)
    UV = topo.split_uv
    tid, bary = rasterize(UV, tris, size)
    P = interp(tid, bary, tris, Vw0[topo.split_w])
    N = interp(tid, bary, tris, N0[topo.split_w])
    N /= np.linalg.norm(N, axis=-1, keepdims=True) + 1e-9
    # groupe MakeHuman du triangle (tous 'body' ici) + face d'origine
    fof = topo.face_of_tri['peau']
    face = np.where(tid >= 0, fof[np.maximum(tid, 0)], -1)
    L = landmarks(base, Vf)
    out = dict(tid=tid, bary=bary, P=P, N=N, face=face, L=L, mask=tid >= 0)
    pickle.dump(out, open(path, 'wb'))
    return out
