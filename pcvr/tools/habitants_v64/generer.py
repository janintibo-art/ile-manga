"""V64 — générateur des corps, visages, coiffures et vêtements des habitants (hors héros).

Sources : MakeHuman 1.x et MPFB2 (CC0). Tout le reste est calculé ici (numpy, scipy, PIL).
Préparation (une fois, depuis pcvr/) :
    godot --headless --path . -s res://tools/habitants_v64/extraire_fiches.gd
    godot --headless --path . -s res://tools/habitants_v64/extraire_squelette.gd
Puis :
    python3 generer.py tout              (ou une étape : ao peau yeux tissus cheveux habits amples chapeaux corps)
    python3 generer.py corps leon,odette (étape limitée à quelques noms)
Sorties : www/assets/models/pnj64 (*.bin) et www/assets/textures/pnj64 (*.png).
"""
import os, sys, time, json, pickle

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from chemins import OUT, OUTT, cache

ETAPES = ['ao', 'peau', 'yeux', 'tissus', 'cheveux', 'habits', 'amples', 'chapeaux', 'corps']
GRAINES_TISSU = {'coton': 11, 'lin': 23, 'toile': 37, 'jean': 41, 'laine': 53, 'cuir': 67, 'soie': 79, 'paille': 83}


def etape_ao(only=None):
    from skin_tex import bake_ao
    ao_v, topo, Vw0 = bake_ao()
    pickle.dump(ao_v, open(cache('cache_ao.pkl'), 'wb'))


def etape_peau(only=None):
    from skin_tex import compose, save_rgb, save_normal
    T = compose(2048)
    os.makedirs(OUTT, exist_ok=True)
    save_rgb(OUTT + '/peau_teint.png', T['var'])
    save_rgb(OUTT + '/peau_masques1.png', T['m1'])
    save_rgb(OUTT + '/peau_masques2.png', T['m2'])
    save_normal(OUTT + '/peau_grain_n.png', T['nf'])
    save_normal(OUTT + '/peau_rides_n.png', T['nw'])


def etape_yeux(only=None):
    from eye_tex import eye_texture, lash_texture, save_rgba
    from hair_tex import atlas
    os.makedirs(OUTT, exist_ok=True)
    save_rgba(OUTT + '/yeux.png', eye_texture(1024))
    save_rgba(OUTT + '/cils.png', lash_texture())
    save_rgba(OUTT + '/meches.png', atlas(1024))


def etape_tissus(only=None):
    from cloth_tex import weave, details_and_folds
    from maps import body_maps
    from hair import Body
    from clothes import Features
    from skin_tex import vertex_attr_to_tex, save_normal
    from eye_tex import save_rgba
    os.makedirs(OUTT, exist_ok=True)
    for k, g in GRAINES_TISSU.items():
        save_rgba(OUTT + '/tissu_%s.png' % k, weave(k, 512, seed=g))
    M = body_maps(2048)
    body = Body()
    F = Features(body)
    ao_v = pickle.load(open(cache('cache_ao.pkl'), 'rb'))
    ao = vertex_attr_to_tex(M, body.topo, ao_v)
    det, nf = details_and_folds(M, body, F, ao)
    save_rgba(OUTT + '/habits_details.png', det)
    save_normal(OUTT + '/habits_plis_n.png', nf)


def etape_cheveux(only=None):
    from hair import Body
    import hair_styles as hs
    from proxy_export import export_cards
    body = Body()
    os.makedirs(OUT + '/cheveux', exist_ok=True)
    H = lambda P: body.local(P)[1] > -0.03

    def nain_tresses():
        rng = np.random.default_rng(13)
        mesh, _ = hs.style_generic(body, 13, 650, 0.12, 0.12, 0.12, 0.0, 0.004, 0.009, 6, 0.2, 0.4, (0.018, 0.028), [(3, 0.5), (1, 0.5)],
                                   comb=hs.parted_comb(body, 0.0, back_bias=0.6), taper=0.3)
        for sx in (1, -1):
            start = body.c + np.array([sx * 0.07, -0.05, -0.04])
            hs.braid(body, mesh, rng, start, 0.3, 0.02, direction=np.array([sx * 0.15, -1.0, 0.3]))
        return mesh

    g = hs.style_generic
    styles = {
        'court': lambda: g(body, 1, 700, 0.045, 0.018, 0.022, 0.03, 0.003, 0.006, 4, 0.1, 0.45, (0.014, 0.024), [(1, 0.55), (0, 0.25), (7, 0.2)], back_bias=0.9, taper=0.6)[0],
        'court_f': lambda: g(body, 2, 600, 0.08, 0.055, 0.06, -0.02, 0.003, 0.009, 4, 0.25, 0.5, (0.016, 0.026), [(1, 0.5), (0, 0.3), (2, 0.2)], fringe=0.55, taper=0.5)[0],
        'long': lambda: g(body, 3, 400, 0.36, 0.38, 0.46, 0.0, 0.004, 0.012, 8, 0.5, 0.55, (0.03, 0.05), [(0, 0.45), (1, 0.4), (2, 0.15)], taper=0.45)[0],
        'long_b': lambda: g(body, 4, 400, 0.32, 0.34, 0.42, 0.035, 0.004, 0.012, 8, 0.5, 0.55, (0.03, 0.05), [(3, 0.6), (4, 0.4)], wave=0.25, taper=0.45)[0],
        'carre': lambda: g(body, 5, 500, 0.17, 0.13, 0.13, -0.025, 0.004, 0.011, 6, 0.45, 0.55, (0.02, 0.032), [(0, 0.5), (1, 0.5)], fringe=0.0, taper=0.3)[0],
        'boucles': lambda: g(body, 6, 480, 0.15, 0.13, 0.15, 0.0, 0.008, 0.016, 7, 0.25, 0.5, (0.022, 0.034), [(5, 1.0)], curl=22.0, curl_r=0.012, taper=0.35)[0],
        'queue': lambda: hs.style_queue(body),
        'chignon': lambda: hs.style_chignon(body),
        'tresse': lambda: hs.style_tresse(body),
        'chauve_couronne': lambda: hs.style_couronne(body),
        'dreads': lambda: hs.style_dreads(body),
        'crete': lambda: hs.style_crete(body),
        'crete_courte': lambda: hs.style_crete(body, seed=32, n=700, half_w=0.034, short=True),
        'plaque': lambda: g(body, 33, 750, 0.06, 0.03, 0.035, 0.0, 0.002, 0.003, 5, 0.05, 0.6, (0.014, 0.022), [(0, 0.7), (1, 0.3)], comb=hs.back_comb(body), taper=0.55)[0],
        'nain_long': lambda: g(body, 12, 450, 0.2, 0.22, 0.26, 0.0, 0.005, 0.012, 7, 0.5, 0.55, (0.022, 0.036), [(3, 0.5), (6, 0.5)], wave=0.2, taper=0.45)[0],
        'nain_tresses': nain_tresses,
        'barbe_moustache': lambda: hs.style_beard(body, 'moustache'),
        'barbe_courte': lambda: hs.style_beard(body, 'courte'),
        'barbe_longue': lambda: hs.style_beard(body, 'longue'),
        'barbe_nain_large': lambda: hs.style_beard(body, 'nain_large'),
        'barbe_nain_tresse': lambda: hs.style_beard(body, 'nain_tresse'),
        'barbe_nain_fourche': lambda: hs.style_beard(body, 'nain_fourche'),
    }
    for name in (only or list(styles)):
        m = styles[name]()
        beard = name.startswith('barbe')
        r = export_cards(body, m, OUT + '/cheveux/%s.bin' % name, 'barbe' if beard else 'cheveux', force_head=(None if beard else H))
        print(' ', name, r, flush=True)


def etape_habits(only=None):
    import clothes as cl
    from hair import Body
    from export import welded_normals, split_tangents, skin_weights
    import gdvar
    body = Body()
    F = cl.Features(body)
    G = cl.Garments(body, F)
    ao_v = pickle.load(open(cache('cache_ao.pkl'), 'rb'))
    topo = body.topo
    TAN = split_tangents(topo, body.V, welded_normals(topo, body.V))
    bidx, bw = skin_weights(topo, body.W)          # mêmes poids que la peau (base.bin)
    cat = cl.shell_catalog(body, F, G)
    os.makedirs(OUT + '/habits', exist_ok=True)
    for name in (only or list(cat)):
        sh = cat[name]
        d = cl.build_shell(body, F, G, sh, ao_v)
        out = {'kind': sh.kind, 'layer': sh.layer, 'w': gdvar.i32(d['w']), 'uv': gdvar.v2(topo.split_uv[d['sv']]), 'tan': gdvar.f32(TAN[d['sv']]),
               'bones': gdvar.i32(bidx[d['w']]), 'weights': gdvar.f32(bw[d['w']]), 'off': gdvar.f32(d['off']), 'shift': gdvar.v3(d['shift']),
               'hem': gdvar.f32(d['hem']), 'tri': gdvar.i32(d['tri']), 'tri_skin': gdvar.i32(d['tri_skin'])}
        print(' ', name, len(d['w']), 'sommets', gdvar.save(OUT + '/habits/%s.bin' % name, out), flush=True)


def etape_amples(only=None):
    from hair import Body
    from clothes import Features
    import loose as lo
    from proxy import Binder, interp_weights
    from export import skin_weights
    from rig import HB
    import gdvar
    body = Body()
    F = Features(body)
    hull = lo.Hull(body, F)
    hull_neck = lo.Hull(body, F, parts=(0, 5))
    bidx, bw = skin_weights(body.topo, body.W)
    binder = Binder(body)

    def export(name, m, path, hips_mix=0.6, anchor=None):
        P = np.array(m.P); UV = np.array(m.UV); T = np.array(m.T); N = np.array(m.N); I = np.array(m.I); H = np.array(m.H); WH = np.array(m.WH)
        refs, bary, off = binder.bind(P)
        idx, w = interp_weights(bidx, bw, refs, bary, len(HB))
        # mélange avec le bassin (ou l'os d'ancrage) : en haut 100 %, en bas (1 - hips_mix)
        anc = HB.index('Hips' if anchor is None else anchor)
        H24 = np.zeros((len(P), len(HB)))
        for j in range(4):
            np.add.at(H24, (np.arange(len(P)), idx[:, j]), w[:, j])
        a = WH + (1 - WH) * hips_mix
        H24 *= (1 - a)[:, None]
        H24[:, anc] += a
        idx = np.argsort(-H24, axis=1)[:, :4]
        w = np.take_along_axis(H24, idx, 1)
        w /= w.sum(1, keepdims=True)
        tan = np.concatenate([T, np.ones((len(T), 1))], 1)
        d = {'kind': 'ample', 'refs': gdvar.i32(refs), 'bary': gdvar.f32(bary), 'off': gdvar.v3(off), 'reg': gdvar.u8(np.ones(len(P), np.uint8)),
             'uv': gdvar.v2(UV), 'tan': gdvar.f32(tan), 'nrm': gdvar.v3(N), 'hem': gdvar.f32(H),
             'bones': gdvar.i32(idx), 'weights': gdvar.f32(w), 'idx': gdvar.i32(I)}
        print(' ', name, len(P), 'sommets', gdvar.save(path, d), flush=True)

    os.makedirs(OUT + '/habits', exist_ok=True)
    wy = F.waist_y + 0.01
    knee = F.knee_y
    ank = F.ankle_y + 0.03
    G = {
        'jupe': lambda: lo.skirt(body, F, hull, wy, knee - 0.04, flare=0.07, folds=12),
        'jupe_longue': lambda: lo.skirt(body, F, hull, wy, ank, flare=0.13, folds=14, fold_amp=(0.003, 0.018)),
        'tunique_bas': lambda: lo.skirt(body, F, hull, F.crotch_y + 0.06, F.crotch_y - 0.12, clear_top=0.016, flare=0.05, folds=10),
        'blouse_bas': lambda: lo.skirt(body, F, hull, F.crotch_y + 0.06, knee - 0.02, clear_top=0.018, flare=0.05, folds=6, fold_amp=(0.002, 0.008), gap=0.16),
        'djellaba_bas': lambda: lo.skirt(body, F, hull, F.crotch_y + 0.03, ank - 0.01, clear_top=0.02, flare=0.12, folds=12, fold_amp=(0.004, 0.02)),
        'tablier': lambda: lo.skirt(body, F, hull, wy, knee - 0.02, clear_top=0.02, flare=0.02, folds=5, fold_amp=(0.001, 0.005), span=(-1.25, 1.25), nk=24),
        'tablier_court': lambda: lo.skirt(body, F, hull, wy, F.crotch_y - 0.05, clear_top=0.02, flare=0.015, folds=4, fold_amp=(0.001, 0.004), span=(-1.15, 1.15), nk=20),
        'bavette': lambda: lo.front_panel(body, F.chest_y + 0.12, wy, 0.11, clear=0.022),
        'cape': lambda: lo.skirt(body, F, hull, F.neck_y - 0.05, knee - 0.12, clear_top=0.025, flare=0.16, folds=9, fold_amp=(0.003, 0.016), span=(np.pi - 1.85, np.pi + 1.85), nk=40),
        'ceinture_ample': lambda: lo.tube_ring(body, hull, wy - 0.005, 0.009, 0.016),
        'foulard': lambda: lo.tube_ring(body, hull_neck, F.neck_y - 0.035, 0.012, 0.004),
        # V75 : la cravate de Monsieur Lisse, le châle de Mère Morille
        'cravate': lambda: lo.tie(body, F.neck_y - 0.03, F.waist_y + 0.02),
        'chale': lambda: lo.skirt(body, F, hull, F.neck_y - 0.045, F.waist_y + 0.03, clear_top=0.024, flare=0.13, folds=8, fold_amp=(0.002, 0.012), span=(np.pi - 2.2, np.pi + 2.2), nk=44),
    }
    # tabliers portés sur une jupe : ils restent toujours au-dessus d'elle (même forme, un peu plus loin)
    dessous = {'jupe': dict(y_top=wy, y_bot=knee - 0.04, flare=0.07, folds=12),
               'longue': dict(y_top=wy, y_bot=ank, flare=0.13, folds=14, fold_amp=(0.003, 0.018)),
               'tunique': dict(y_top=F.crotch_y + 0.06, y_bot=F.crotch_y - 0.12, clear_top=0.016, flare=0.05, folds=10)}
    for k, u in dessous.items():
        G['tablier_sur_' + k] = (lambda u=u: lo.skirt(body, F, hull, wy, knee - 0.02, clear_top=0.02, flare=0.02, folds=5, fold_amp=(0.001, 0.005), span=(-1.25, 1.25), nk=24, under=u))
        G['tablier_court_sur_' + k] = (lambda u=u: lo.skirt(body, F, hull, wy, F.crotch_y - 0.05, clear_top=0.02, flare=0.015, folds=4, fold_amp=(0.001, 0.004), span=(-1.15, 1.15), nk=20, under=u))
    anchor = {'cape': 'Spine', 'bavette': 'Spine02', 'foulard': 'Spine', 'cravate': 'Spine', 'chale': 'Spine'}
    mix = {'cravate': 1.0, 'chale': 0.9, 'cape': 0.75, 'tablier': 0.55, 'tablier_court': 0.7, 'bavette': 1.0, 'foulard': 1.0, 'ceinture_ample': 1.0, 'blouse_bas': 0.55, 'tunique_bas': 0.6}
    for k in dessous:
        mix['tablier_sur_' + k] = 0.5
        mix['tablier_court_sur_' + k] = 0.6
    for name in (only or list(G)):
        export(name, G[name](), OUT + '/habits/%s.bin' % name, hips_mix=mix.get(name, 0.5), anchor=anchor.get(name))


def etape_chapeaux(only=None):
    from hair import Body
    from hats import build_hats
    from proxy import Binder
    from rig import HB
    import gdvar
    body = Body()
    binder = Binder(body)
    hats = build_hats(body)
    head = HB.index('Head')
    os.makedirs(OUT + '/habits', exist_ok=True)
    for name in (only or list(hats)):
        m = hats[name]
        P = np.array(m.P); UV = np.array(m.UV); T = np.array(m.T); N = np.array(m.N); I = np.array(m.I)
        refs, bary, off = binder.bind(P)
        idx = np.zeros((len(P), 4), np.int64)
        idx[:, 0] = head
        w = np.zeros((len(P), 4))
        w[:, 0] = 1
        tan = np.concatenate([T, np.ones((len(T), 1))], 1)
        d = {'kind': 'chapeau', 'refs': gdvar.i32(refs), 'bary': gdvar.f32(bary), 'off': gdvar.v3(off), 'reg': gdvar.u8(np.zeros(len(P), np.uint8)),
             'uv': gdvar.v2(UV), 'tan': gdvar.f32(tan), 'nrm': gdvar.v3(N), 'hem': gdvar.f32(np.full(len(P), 0.05)),
             'bones': gdvar.i32(idx), 'weights': gdvar.f32(w), 'idx': gdvar.i32(I)}
        print(' ', name, len(P), 'sommets', gdvar.save(OUT + '/habits/%s.bin' % name, d), flush=True)


def etape_corps(only=None):
    from mh import Base, macro_targets, modifier_targets
    from rig import weight_matrix
    from export import Topology, write_base, write_npc, make_body
    from appearance import decide, outfit, clean_outfit, assets, hats_for, adult_height
    from hair import Body
    from proxy import head_refs, torso_refs
    base = Base()
    W = weight_matrix(base.n)
    topo = Topology(base)
    P0 = dict(gender=0.5, age=0.5, muscle=0.5, weight=0.5, height=0.5, african=1, asian=1, caucasian=1)
    Vw0, HJ0, s0 = make_body(base, topo, W, macro_targets(P0))
    os.makedirs(OUT, exist_ok=True)
    b = Body()
    hr, href = head_refs(b)
    tr, tref = torso_refs(b)
    write_base(topo, W, Vw0, OUT + '/base.bin', refs={'head_ids': hr, 'head_ref': [float(x) for x in href], 'torso_ids': tr, 'torso_ref': [float(x) for x in tref]})
    prof = json.load(open(cache('pnj.json')))
    for pid, p in prof.items():
        if only and pid not in only:
            continue
        D = decide(pid, p)
        Vw, HJ, s = make_body(base, topo, W, macro_targets(D['morph']) + modifier_targets(D['mods']))
        hgt = Vw[:topo.nb, 1].max()
        scale = 1.0
        if 'lumen_h' in D:
            scale = D['lumen_h'] / hgt          # V76 : les Lumens (1,82 à 2 m), Glorb (1,32 m)
        elif D['child'] or D['species'] == 'nain':
            scale = D['taille'] * 1.70 / hgt
        else:
            scale = adult_height(D, hgt) / hgt
        T = clean_outfit(outfit(D, p), p)
        HT, cut = hats_for(D, p)
        hair, beard = assets(D)
        hj = HJ['Head']
        eyes = Vw[topo.nb:]
        el = eyes[eyes[:, 0] > hj[0]].mean(0)
        er = eyes[eyes[:, 0] <= hj[0]].mean(0)
        em = (el + er) / 2
        tete = {'yeux': [float(x) for x in (em - hj)], 'yeux_dx': float(abs(el[0] - er[0]) / 2), 'haut': float(Vw[hr[2], 1] - hj[1]),
                'menton': float(Vw[hr[3], 1] - hj[1]), 'avant': float(Vw[hr[4], 2] - hj[2]), 'arriere': float(Vw[hr[5], 2] - hj[2]),
                'cote': float(abs(Vw[hr[0], 0] - Vw[hr[1], 0]) / 2)}
        look = dict(D['look'])
        look['tete'] = tete
        look['hauteur'] = float(hgt)
        if cut < 10:
            look['coupe'] = -float(cut)
        look.update({'cheveux_style': hair, 'barbe_style': beard, 'tenue': T + HT, 'espece': D['species'], 'femme': D['female'],
                     'enfant': D['child'], 'vieux': D['old']})
        write_npc(topo, Vw, Vw0, HJ, s, OUT + '/' + pid + '.bin', meta={'scale': float(scale), 'look': look})
    print('  habitants :', len(prof) if not only else len(only))


if __name__ == '__main__':
    quoi = sys.argv[1] if len(sys.argv) > 1 else 'tout'
    only = sys.argv[2].split(',') if len(sys.argv) > 2 else None
    for e in (ETAPES if quoi == 'tout' else quoi.split(',')):
        t = time.time()
        print(e, '...', flush=True)
        globals()['etape_' + e](only)
        print(e, 'fini en %.1f s' % (time.time() - t), flush=True)
