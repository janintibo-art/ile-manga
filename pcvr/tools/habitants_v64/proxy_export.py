"""Export d'un proxy (cartes de cheveux, barbe, vêtement ample) pour le jeu."""
import numpy as np
import gdvar
from proxy import Binder, interp_weights
from export import build_weights
from rig import HB


def head_region_mask(body, P):
    x, y, z, ax, th = body.local(P)
    return (y > -0.13) & (np.abs(x) < 0.12) & (z > -0.22)


def export_cards(body, mesh, path, kind, head_bound=True, zone=None, force_head=None):
    P, UV, T, N, C, I = mesh.arrays()
    binder = Binder(body)
    refs, bary, off = binder.bind(P)
    reg = np.where(head_region_mask(body, P) if head_bound else np.zeros(len(P), bool), 0, 1).astype(np.uint8)
    bidx, bw = build_weights(body.topo, body.W)
    idx, w = interp_weights(bidx, bw, refs, bary, len(HB))
    if force_head is not None:
        fh = force_head(P)
        idx[fh] = [HB.index('Head'), 0, 0, 0]
        w[fh] = [1, 0, 0, 0]
    tan = np.concatenate([T, np.ones((len(T), 1))], 1)
    d = {'kind': kind, 'refs': gdvar.i32(refs), 'bary': gdvar.f32(bary), 'off': gdvar.v3(off), 'reg': gdvar.u8(reg),
         'uv': gdvar.v2(UV), 'tan': gdvar.f32(tan), 'nrm': gdvar.v3(N), 'col': gdvar.col4(C),
         'bones': gdvar.i32(idx), 'weights': gdvar.f32(w), 'idx': gdvar.i32(I),
         'zone': gdvar.u8(np.zeros(len(P), np.uint8) if zone is None else zone.astype(np.uint8))}
    return gdvar.save(path, d), len(P)
