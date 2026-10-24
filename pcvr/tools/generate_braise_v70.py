"""V70 : textures de l'Île de Braise et de Pandémonia, la méga-cité des démons gentils.

braise/   — surfaces 1024 px raccordables, chacune avec sa carte de relief <nom>_n.png
          (« sols » : une tuile couvre environ 4 m x 4 m) :
          cendre (+_n)         : sol de cendre gris-brun, mottes, lapilli et cailloux de scorie ;
          basalte (+_n)        : basalte sombre et rugueux, lave refroidie (cordes, vacuoles, fissures) ;
          sable_noir (+_n)     : plage de sable noir volcanique, rides, laisses de mer, paillettes ;
          mousse_braise (+_n)  : l'« herbe » de l'île : mousse sombre et brins ras aux reflets cuivre-rouge ;
          paves_basalte (+_n)  : pavés de basalte de la cité, dessus usés et polis, joints sombres ;
          obsidienne (+_n)     : verre volcanique noir, cassures conchoïdales, reflets violets ;
          soufre (+_n)         : croûte de soufre jaune, aiguilles, cristaux orangés et blancs ;
          roche_volcan (+_n)   : falaise de roche volcanique rouge-brun oxydée, en strates ;
          lave_croute (+_n)    : croûte de lave refroidie, plaques noires et fentes incandescentes
                                 (+ lave_croute_e.png : masque d'émission en gris, seules les fentes brillent) ;
          lave (+_n)           : lave en fusion qui coule (cœurs jaunes, orange, rouge, peaux sombres),
                                 pour le nuanceur (la carte _n est facultative).
          (« bati » : une tuile couvre environ 3 m x 3 m)
          pierre_gothique (+_n): pierre de taille gris sombre en assises, coulures de suie sous les joints ;
          brique_noire (+_n)   : briques recuites noires et violacées, quelques rouges, mortier de chaux noirci ;
          enduit_rouge (+_n)   : enduit rouge sombre patiné, petits éclats montrant la pierre grise ;
          marbre_rouge (+_n)   : marbre rouge poli veiné de blanc ;
          marbre_noir (+_n)    : marbre noir veiné d'or (façon Portor) ;
          ardoise (+_n)        : toit d'ardoises en écailles qui se recouvrent ;
          tuiles_rouges (+_n)  : toit de tuiles plates rouge sombre, en rangs ;
          cuivre_vert (+_n)    : toit de cuivre à joints debout, patine vert-de-gris, coulures sombres ;
          bois_brule (+_n)     : planches carbonisées, charbon craquelé en écailles ;
          fer_forge (+_n)      : fer forgé martelé sombre, un peu de rouille ;
          dalles_palais (+_n)  : damier de marbre noir et rouge poli, filets d'or incrustés ;
          mosaique_feu (+_n)   : mosaïque de place : rosace soleil-flammes (rouge, orange, or, noir) ;
          pierre_abyssale (+_n): roche de caverne très sombre et mouillée (le donjon) ;
          glace (+_n)          : glace bleu-blanc, fêlures et bulles ;
          givre (+_n)          : cristaux de givre en fougères sur pierre sombre ;
          boue (+_n)           : boue sombre et flaques ;
          sable_arene (+_n)    : sable de l'arène, ocre-gris, traces de râteau et de pas.
          — panneaux et décors (non raccordables, sans _n) :
          fenetre_gothique (256 x 512) : fenêtre en lancette éclairée de l'intérieur, vitres ambrées ;
          vitrail_rosace (512 x 512, RGBA) : rosace, transparente hors du cercle, flamme cornue au centre ;
          vitrail_lancette (256 x 768) : haute verrière en lancette à trois médaillons ;
          enseigne_<x> (512 x 256) : enseignes peintes des boutiques (voir ENSEIGNES) ;
          banniere_pandemonia (256 x 512, RGBA) : bannière, flamme cornue d'or sur gueules, queue d'aronde ;
          affiche_tournoi, affiche_fete (512 x 768) : affiches du Grand Tournoi et de la Nuit des Lanternes ;
          plan_ville (1024 x 768) : plan illustré de Pandémonia ;
          fresque_porte, fresque_charon, fresque_cerbere, fresque_minos, fresque_dite, fresque_geryon,
          fresque_cocyte (1024 x 512) : les fresques des Neuf Cercles, peintes sur la pierre ;
          cercle_1 … cercle_9, sceau_contrat, lanterne_sym, flamme_sym, givre_sym (256 x 256, RGBA) :
          les sceaux gravés qui luisent ;
          contrat (512 x 768) : un vieux contrat sur parchemin, sceau de cire rouge et ligne de signature.
items/    (« icones », 128 px, ombrées et cernées comme les autres) obole, cle_brasier, gateau_miel,
          flamme_eternelle, corne_or, lanterne_braise, diplome_infernal, piment_infernal, cafe_brasier,
          lave_glacee, grog_soufre, fleur_braise, cristal_soufre, lettre, plume_furie, croc_cerbere,
          eclat_givre, huile_cornes, brioche_braise.

Tout est dessiné ici, procéduralement (libre de droits), avec les outils du générateur V69.
Police : Lora (SIL OFL 1.1). Déterministe : chaque image a sa propre graine.
Lancement depuis la racine du dépôt :
    python3 pcvr/tools/generate_braise_v70.py [sols | bati | panneaux | enseignes | fresques | sceaux | icones | <nom>]
(sans argument : tout ; <nom> : une seule image, par ex. « basalte » ou « fresque_charon »).
"""
import math
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # pas de __pycache__ dans pcvr/tools

import numpy as np  # noqa: E402
from PIL import Image, ImageDraw, ImageFilter  # noqa: E402
from scipy import ndimage  # noqa: E402

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_soleils_v69 as so  # noqa: E402
from generate_soleils_v69 import (tn, gblur, smooth, mix, C, grads, normal_img, bake, offs, to_img, from_img,  # noqa: E402
                                  per_id, masonry, worley, warp, speck, chaikin, bez, ellp, tube, leaf_poly,
                                  blade_poly, down, font, vol, Pen, age_panel, _layers, _arr)

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "braise"
ITEMS = ROOT / "www" / "assets" / "textures" / "items"
TAU = math.tau
LIGHT = (-0.45, -0.6, 0.66)  # la même lumière (en haut à gauche) que les autres générateurs
STATS = {}


# =================================================================== outils

def rng(seed):
    return np.random.default_rng(seed)


def _log(p, arr=None):
    print(p.relative_to(ROOT), flush=True)


def save_rgb(arr, name, folder=None):
    p = (folder or OUT) / name
    p.parent.mkdir(parents=True, exist_ok=True)
    img = (arr if isinstance(arr, Image.Image) else to_img(arr)).convert("RGB")
    img.save(p, optimize=True)
    STATS[name] = np.asarray(img, np.float32).reshape(-1, 3).mean(0)
    _log(p)


def save_rgba(arr, name, folder=None):
    p = (folder or OUT) / name
    p.parent.mkdir(parents=True, exist_ok=True)
    if not isinstance(arr, Image.Image):
        arr = Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA")
    arr.save(p, optimize=True)
    _log(p)


def save_gray(arr, name):
    p = OUT / name
    p.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8), "L").save(p, optimize=True)
    _log(p)


def save_surface(name, col, h, strength):
    save_rgb(col, name + ".png")
    p = OUT / (name + "_n.png")
    normal_img(h, strength).save(p, optimize=True)
    _log(p)


def norm01(a):
    """Recentre un champ : moyenne 0.5, écart-type 0.2 (comme tn)."""
    a = a - a.mean()
    a = a / (a.std() + 1e-6)
    return np.clip(0.5 + a * 0.2, 0, 1).astype(np.float32)


def grain(R, S, blur=0.6, H=None):
    """Grain fin (un grain ≈ un pixel), raccordable."""
    H = H or S
    return norm01(gblur(R.random((H, S)).astype(np.float32), blur))


def ridged(a):
    return (1.0 - np.abs(a - 0.5) * 2.0).astype(np.float32)


def warp_nn(a, dx, dy):
    """Comme warp, mais au plus proche voisin (pour les identifiants de cellules)."""
    H, W = a.shape[:2]
    yy, xx = np.mgrid[0:H, 0:W]
    x = np.round(xx + dx).astype(np.int32) % W
    y = np.round(yy + dy).astype(np.int32) % H
    return a[y, x]


def wrap_edt(mask, pad=64):
    """Distance au bord du masque (en px), raccordable."""
    m = np.pad(mask, pad, mode="wrap")
    d = ndimage.distance_transform_edt(m)
    return d[pad:-pad, pad:-pad].astype(np.float32)


def hshadow(h, hs, steps=16, soft=1.5):
    """Ombres portées d'un relief (raccordable) : h * hs = hauteur en pixels ; lumière LIGHT."""
    L = np.array(LIGHT, np.float32)
    L /= np.linalg.norm(L)
    hor = math.hypot(L[0], L[1])
    ux, uy, tv = L[0] / hor, L[1] / hor, L[2] / hor
    Hh = h.astype(np.float32) * hs
    occ = np.zeros_like(Hh)
    for k in range(1, steps + 1):
        sx, sy = int(round(k * ux)), int(round(k * uy))
        occ = np.maximum(occ, np.roll(Hh, (-sy, -sx), (0, 1)) - Hh - k * tv)
    return np.clip(occ / soft, 0, 1)


def scatter(S, items, H=None):
    """Dessine des polygones (x, y, pts, r) dans une carte d'identifiants (1..N), raccordable."""
    H = H or S
    img = Image.new("I", (S, H), 0)
    d = ImageDraw.Draw(img)
    for i, (x, y, pts, r) in enumerate(items, 1):
        for ox, oy in offs(x, y, r + 2, S, H):
            d.polygon([(x + ox + px, y + oy + py) for px, py in pts], fill=i)
    return np.asarray(img, np.int32)


def domes(ids, n):
    """Pour chaque pièce d'une carte d'identifiants : 0 au bord, 1 au cœur (hauteur relative)."""
    mask = ids > 0
    b = np.zeros_like(mask)
    for ax in (0, 1):
        for s in (1, -1):
            r = np.roll(ids, s, ax)
            b |= (r != ids) & mask
    dist = wrap_edt(mask & ~b) + (mask & ~b)
    mx = ndimage.maximum(dist, labels=ids, index=np.arange(1, n + 1))
    mx = np.concatenate([[1.0], np.maximum(np.asarray(mx, np.float32), 1.0)]).astype(np.float32)
    return np.clip(dist / mx[ids], 0, 1).astype(np.float32), mask


def rock_poly(R, r, k=None, el=None, jit=0.3, sm=0):
    k = k or int(R.integers(6, 11))
    el = R.uniform(0.6, 1.0) if el is None else el
    a0 = R.uniform(0, TAU)
    ca, sa = math.cos(a0), math.sin(a0)
    pts = []
    for j in range(k):
        a = j / k * TAU + R.uniform(-0.25, 0.25)
        rr = r * R.uniform(1 - jit, 1.0)
        x, y = math.cos(a) * rr, math.sin(a) * rr * el
        pts.append((x * ca - y * sa, x * sa + y * ca))
    return chaikin(pts, sm) if sm else pts


def pores(R, S, count, rlo, rhi, ang=None, stretch=1.0, H=None):
    """Vacuoles (bulles de gaz figées) : masque 0..1, raccordable ; ang : champ d'orientation."""
    H = H or S
    img = Image.new("L", (S, H), 0)
    d = ImageDraw.Draw(img)
    for _ in range(count):
        x, y = R.random() * S, R.random() * H
        r = R.uniform(rlo, rhi) if R.random() < 0.85 else R.uniform(rhi, rhi * 2.2)
        a = float(ang[int(y) % H, int(x) % S]) if ang is not None else R.uniform(0, TAU)
        st = stretch * R.uniform(0.8, 1.25)
        pts = [(math.cos(t) * r * st, math.sin(t) * r / st) for t in np.linspace(0, TAU, 12, endpoint=False)]
        ca, sa = math.cos(a), math.sin(a)
        pts = [(px * ca - py * sa, px * sa + py * ca) for px, py in pts]
        for ox, oy in offs(x, y, r * st + 2, S, H):
            d.polygon([(x + ox + px, y + oy + py) for px, py in pts], fill=255)
    return gblur(np.asarray(img, np.float32) / 255.0, 0.5)


def level_lines(a, v, w):
    """Lignes de niveau d'un champ (des courbes fermées qui se raccordent)."""
    return np.exp(-((a - v) / w) ** 2).astype(np.float32)


def iso_lines(f, v, wpx):
    """Lignes de niveau d'épaisseur régulière (wpx en pixels, scalaire ou champ)."""
    gx, gy = grads(f)
    d = np.abs(f - v) / (np.sqrt(gx * gx + gy * gy) + 1e-5)
    return np.exp(-(d / wpx) ** 2).astype(np.float32)


# =================================================================== les sols (une tuile ≈ 4 m)

def cendre():
    """Sol de cendre volcanique gris-brun : grain fin en petites mottes, zones un peu plus claires
    (sèches) ou plus sombres (humides), une teinte rouille par endroits ; lapilli et graviers de
    scorie (noirs, rouges, gris, un peu de ponce claire), quelques pierres anguleuses à demi
    enfouies et poudrées de cendre ; une croûte finement fendillée par plaques."""
    S = 1024
    R = rng(7001)
    n = tn(R, S, (4, 8, 16, 32, 64, 128), 0.6)
    damp_n = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    red_n = tn(R, S, (8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.55)
    wx = tn(R, S, (8, 16, 32), 0.6)
    wy = tn(R, S, (8, 16, 32), 0.6)
    _, ed, cid, _, _ = worley(R, S, 80, 0.9)
    ax, ay = (wx - 0.5) * 10, (wy - 0.5) * 10
    ed = warp(ed, ax, ay)
    cid = warp_nn(cid, ax, ay)
    clod = smooth(0.0, 3.5, ed) ** 0.7
    clh = per_id(cid, R, 0.3, 1.0)
    _, ed2, cid2, _, _ = worley(R, S, 190, 0.9)
    crumb = smooth(0.0, 1.6, ed2) * per_id(cid2, R, 0.5, 1.0)
    col = mix(C(0.41, 0.385, 0.36), C(0.47, 0.45, 0.425), smooth(0.3, 0.85, n))
    damp = smooth(0.4, 0.8, damp_n)
    col = mix(col, C(0.33, 0.305, 0.28), damp * 0.4)
    col = mix(col, col * C(1.08, 0.95, 0.88), smooth(0.55, 0.8, red_n) * 0.45)
    col = col * (0.8 + 0.4 * gr[..., None]) * (0.93 + 0.14 * fine[..., None])
    col = col * (0.95 + 0.05 * clod[..., None]) * (0.95 + 0.07 * clh[..., None]) * (0.96 + 0.05 * crumb[..., None])
    sp = R.random((S, S)).astype(np.float32)
    col = mix(col, C(0.16, 0.15, 0.145), (sp < 0.05) * 0.45)
    col = mix(col, C(0.66, 0.64, 0.6), (sp > 0.988) * 0.4)
    col = mix(col, C(0.47, 0.27, 0.2), ((sp > 0.05) & (sp < 0.062)) * 0.45)
    # croûte sèche finement fendillée, par plaques
    _, ce, _, _, _ = worley(R, S, 24, 0.9)
    ce = warp(ce, (wy - 0.5) * 24, (wx - 0.5) * 24)
    crk = (1 - smooth(0.3, 1.1, ce)) * smooth(0.62, 0.74, tn(R, S, (4, 8, 16, 32), 0.6)) * (1 - damp)
    col = col * (1 - 0.22 * crk[..., None])
    h = n * 0.3 + clod * clh * 0.12 + crumb * 0.05 + gr * 0.05 + fine * 0.05 - crk * 0.05
    # cailloux : (couleur, part, vacuoles)
    pal = [((0.25, 0.24, 0.23), 0.3, 1), ((0.46, 0.27, 0.2), 0.16, 1), ((0.41, 0.38, 0.35), 0.27, 0),
           ((0.63, 0.61, 0.56), 0.08, 1), ((0.18, 0.175, 0.17), 0.19, 0)]
    items = []
    for count, rlo, rhi in ((2600, 1.2, 3.4), (520, 3.4, 8.0), (16, 11.0, 24.0)):
        for _ in range(count):
            r = R.uniform(rlo, rhi)
            items.append((R.random() * S, R.random() * S, rock_poly(R, r, k=int(R.integers(5, 9)), jit=0.35, sm=1 if r < 8 else 0), r))
    N = len(items)
    ids = scatter(S, items)
    hn, mask = domes(ids, N)
    kind = R.choice(len(pal), N, p=[q[1] for q in pal])
    base = np.array([pal[k][0] for k in kind], np.float32) * R.uniform(0.85, 1.15, (N, 1)).astype(np.float32)
    base = np.vstack([np.zeros((1, 3), np.float32), base])
    vesic = np.concatenate([[0.0], np.array([pal[k][2] for k in kind], np.float32)])
    rad = np.concatenate([[0.0], np.array([it[3] for it in items], np.float32)])
    prof = np.clip(hn * 1.6, 0, 1) ** 0.6
    stex = tn(R, S, (32, 64, 128, 256), 0.7)
    sth = (prof * (0.85 + 0.3 * stex)) * np.minimum(0.9, 0.12 + rad / 26.0)[ids]
    scol = base[ids] * (0.8 + 0.4 * stex[..., None]) * (0.9 + 0.2 * fine[..., None])
    vp = pores(R, S, 9000, 0.6, 1.4)
    scol = scol * (1 - 0.5 * (vp * vesic[ids])[..., None])
    dust = smooth(0.45, 0.7, tn(R, S, (16, 32, 64, 128), 0.6)) * (0.25 + 0.5 * (1 - prof))
    scol = mix(scol, col, dust * 0.5)
    ma = gblur(mask.astype(np.float32), 0.5)
    col = mix(col, scol, ma)
    h = h + sth * mask - vp * vesic[ids] * 0.05
    # brindilles calcinées, rares
    img = to_img(col)
    d = ImageDraw.Draw(img)
    for _ in range(22):
        x, y = R.random(2) * S
        a = R.uniform(0, TAU)
        L = R.uniform(14, 46)
        for ox, oy in offs(x, y, L, S):
            d.line([(x + ox, y + oy), (x + ox + math.cos(a) * L, y + oy + math.sin(a) * L)], fill=(30, 27, 25), width=2)
    col = from_img(img)
    sh = hshadow(h, 7.0, 14, 1.2)
    col = col * (1 - 0.3 * sh[..., None])
    col = bake(col, h, 5.0, k=0.4, ao=0.3, ao_r=5)
    save_surface("cendre", col, h, 5.0)


def basalte():
    """Basalte sombre et rugueux, une coulée refroidie : bourrelets arrondis qui se chevauchent,
    sillons entre eux, plis en cordes là où la lave était lisse, scories hérissées ailleurs ;
    fines vacuoles, quelques longues fissures ; poussière de cendre claire au fond des creux, un
    peu d'oxydation brun-rouge, rares lichens gris."""
    S = 1024
    R = rng(7002)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    n = tn(R, S, (4, 8, 16, 32, 64, 128, 256), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    wx = tn(R, S, (2, 4, 8, 16), 0.6)
    wy = tn(R, S, (2, 4, 8, 16), 0.6)
    ax, ay = (wx - 0.5) * 90, (wy - 0.5) * 90
    b1 = warp(tn(R, S, (4, 8, 16, 32), 0.5), ax, ay)
    b2 = warp(tn(R, S, (8, 16, 32, 64), 0.5), ay * 0.5, ax * 0.5)
    lump = (np.abs(b1 - 0.5) * 2) ** 0.7 * 0.65 + (np.abs(b2 - 0.5) * 2) ** 0.7 * 0.35
    flow = smooth(0.48, 0.6, tn(R, S, (2, 4, 8), 0.6))
    big = tn(R, S, (2, 4), 0.5)
    ph = yy / S * 30 + (big - 0.5) * 12 + (tn(R, S, (4, 8, 16), 0.6) - 0.5) * 4 + np.sin(xx / S * TAU * 2) * 1.5
    rope = (np.sin(ph * TAU) * 0.5 + 0.5) ** 1.5
    clink = ridged(tn(R, S, (16, 32, 64, 128, 256, 512), 0.65))
    rough = clink * (1 - flow) * 0.55 + rope * flow * 0.3 + clink * flow * 0.12
    crease = (1 - smooth(0.0, 0.08, np.abs(b1 - 0.5) * 2)) * smooth(0.45, 0.6, tn(R, S, (4, 8, 16), 0.6))
    # fissures : segments anguleux, discontinus
    _, ce, _, _, _ = worley(R, S, 5, 0.9)
    jx = (tn(R, S, (32, 64, 128), 0.7) - 0.5) * 7 + (wx - 0.5) * 30
    jy = (tn(R, S, (32, 64, 128), 0.7) - 0.5) * 7 + (wy - 0.5) * 30
    ce = warp(ce, jx, jy)
    cw = 0.3 + 1.6 * tn(R, S, (8, 16, 32), 0.6)
    crack = (1 - smooth(cw * 0.4, cw + 0.7, ce)) * smooth(0.5, 0.58, tn(R, S, (4, 8, 16, 32), 0.6))
    vp = pores(R, S, 20000, 0.45, 1.0, stretch=1.1)
    vp2 = pores(R, S, 200, 1.4, 2.8, stretch=1.1)
    vv = np.clip(vp * 0.8 + vp2, 0, 1) * (1 - 0.5 * flow)
    h = lump * 2.2 + n * 0.5 + rough * 0.45 + fine * 0.08 - crease * 0.3 - crack * 0.5 - vv * 0.2
    hue = smooth(0.3, 0.7, tn(R, S, (2, 4, 8, 16), 0.6))
    base = mix(C(0.29, 0.29, 0.3), C(0.32, 0.3, 0.28), hue)
    col = base * (0.84 + 0.32 * n[..., None]) * (0.84 + 0.32 * fine[..., None])
    col = col * (0.84 + 0.3 * rough[..., None])
    sp = R.random((S, S)).astype(np.float32)
    col = mix(col, C(0.55, 0.55, 0.53), np.clip(gblur((sp < 0.003).astype(np.float32), 0.6) * 2.0, 0, 1) * 0.4)
    col = mix(col, C(0.32, 0.36, 0.24), np.clip(gblur((sp > 0.998).astype(np.float32), 0.6) * 2.5, 0, 1) * 0.35)
    col = col * (1 - 0.4 * vv[..., None])
    col = mix(col, C(0.08, 0.075, 0.07), crack * 0.85)
    cav = smooth(0.02, 0.12, np.clip(gblur(h, 6) - h, 0, None))
    col = mix(col, C(0.42, 0.4, 0.37), cav * 0.35 * smooth(0.4, 0.65, tn(R, S, (8, 16, 32), 0.6)))
    rust = smooth(0.68, 0.84, tn(R, S, (8, 16, 32, 64), 0.6))
    col = mix(col, col * C(1.2, 1.0, 0.85), rust * 0.45)
    li = smooth(0.75, 0.78, tn(R, S, (16, 32, 64, 128), 0.6)) * smooth(0.45, 0.6, fine) * (1 - flow)
    col = mix(col, C(0.52, 0.53, 0.48) * (0.85 + 0.3 * fine[..., None]), li * 0.4)
    h = h + li * 0.03
    sh = hshadow(h, 10.0, 16, 1.5)
    col = col * (1 - 0.28 * sh[..., None])
    col = bake(col, h, 6.0, k=0.5, ao=0.35, ao_r=7)
    gx, gy = grads(h)
    lam = np.clip((gx * 6 * 0.45 + gy * 6 * 0.6 + 0.66) / np.sqrt((gx * 6) ** 2 + (gy * 6) ** 2 + 1) / 0.66, 0, 2)
    col = col + (np.clip(lam - 1.0, 0, 1) ** 2 * flow * 0.05)[..., None] * C(0.8, 0.85, 1.0)
    save_surface("basalte", col, h, 7.0)


def sable_noir():
    """Sable noir volcanique d'une plage : grains noirs, gris, vert olive (olivine) et quelques
    clairs ; paillettes de verre qui accrochent la lumière ; rides douces, sable un peu plus
    sombre et lisse là où il est encore mouillé, laisses de mer (lignes de grains plus grossiers) ;
    quelques galets de basalte polis et de rares débris de coquillages."""
    S = 1024
    R = rng(7003)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    w1 = tn(R, S, (2, 4, 8), 0.5)
    w2 = tn(R, S, (8, 16, 32), 0.55)
    ph = yy / S * 17 + xx / S * 2 + (w1 - 0.5) * 3.0 + (w2 - 0.5) * 0.9
    f = ph - np.floor(ph)
    prof = gblur(np.where(f < 0.72, f / 0.72, (1 - f) / 0.28).astype(np.float32), 2.0)
    amp = 0.25 + 0.75 * smooth(0.3, 0.7, tn(R, S, (2, 4, 8, 16), 0.6))
    wet = smooth(0.35, 0.8, tn(R, S, (2, 4, 8, 16), 0.5))
    rip = prof * amp * (1 - 0.5 * wet)
    gr = grain(R, S, 0.5)
    gr2 = grain(R, S, 1.1)
    big = tn(R, S, (4, 8, 16, 32), 0.6)
    col = mix(C(0.29, 0.285, 0.28), C(0.32, 0.31, 0.3), big)
    col = col * (0.76 + 0.48 * gr[..., None]) * (0.9 + 0.2 * gr2[..., None])
    sp = R.random((S, S)).astype(np.float32)
    col = mix(col, C(0.34, 0.37, 0.23), (sp < 0.03) * 0.45)
    col = mix(col, C(0.4, 0.32, 0.26), ((sp >= 0.03) & (sp < 0.05)) * 0.45)
    col = mix(col, C(0.62, 0.61, 0.58), (sp > 0.994) * 0.45)
    col = mix(col, C(0.12, 0.115, 0.11), ((sp >= 0.05) & (sp < 0.12)) * 0.5)
    trough = (1 - prof) * amp
    col = mix(col, col * 0.88, smooth(0.5, 0.95, trough) * 0.5)
    sw = level_lines(tn(R, S, (2, 4, 8, 16), 0.55), 0.56, 0.009) + level_lines(tn(R, S, (2, 4, 8, 16), 0.55), 0.44, 0.007)
    sw = np.clip(sw, 0, 1) * smooth(0.3, 0.55, tn(R, S, (4, 8, 16), 0.6))
    coarse = grain(R, S, 1.6)
    col = mix(col, col * (0.8 + 0.6 * coarse[..., None]) * C(1.12, 1.1, 1.06), sw * 0.55)
    col = col * (1 - 0.14 * wet[..., None])
    h = rip * 0.55 + gr * 0.05 + gr2 * 0.04 + big * 0.06 + sw * coarse * 0.06
    items, kinds = [], []
    for _ in range(64):
        r = R.uniform(3, 9) if R.random() < 0.8 else R.uniform(9, 16)
        items.append((R.random() * S, R.random() * S, rock_poly(R, r, k=10, jit=0.12, sm=2), r))
        kinds.append(0 if R.random() < 0.85 else 1)
    for _ in range(24):
        r = R.uniform(2.5, 6)
        items.append((R.random() * S, R.random() * S, rock_poly(R, r, k=5, el=0.6, jit=0.4), r))
        kinds.append(2)
    N = len(items)
    ids = scatter(S, items)
    hn, mask = domes(ids, N)
    kinds = np.array([0] + kinds)
    pc = np.array([[0, 0, 0], [0.24, 0.24, 0.245], [0.45, 0.43, 0.41], [0.74, 0.7, 0.64]], np.float32)
    tone = np.concatenate([[1.0], R.uniform(0.8, 1.2, N)]).astype(np.float32)
    rad = np.concatenate([[0.0], np.array([it[3] for it in items], np.float32)])
    prof2 = np.sqrt(np.clip(1 - (1 - hn) ** 2, 0, 1))
    k_ = kinds[ids]
    scol = pc[np.where(mask, k_ + 1, 0)] * tone[ids][..., None] * (0.9 + 0.2 * gr2[..., None])
    sth = prof2 * np.where(k_ == 2, 0.2, np.minimum(0.9, 0.2 + rad / 18.0)[ids])
    ma = gblur(mask.astype(np.float32), 0.5)
    col = mix(col, scol, ma)
    h = h + sth * mask
    sh = hshadow(h, 6.0, 12, 1.2)
    col = col * (1 - 0.33 * sh[..., None])
    col = bake(col, h, 4.0, k=0.3, ao=0.3, ao_r=4)
    gl = (prof2 ** 6) * mask * (k_ <= 1)
    col = col + (gl * 0.08)[..., None]
    gp = R.random((S, S)).astype(np.float32)
    glint = (gp > 0.9985).astype(np.float32) * R.uniform(0.35, 1.0, (S, S)).astype(np.float32) * (1 - ma)
    glint = glint + 0.22 * (np.roll(glint, 1, 0) + np.roll(glint, -1, 0) + np.roll(glint, 1, 1) + np.roll(glint, -1, 1))
    col = col + (np.clip(glint, 0, 1) * 0.55)[..., None] * C(1.0, 0.98, 0.94)
    save_surface("sable_noir", col, h, 4.5)


def mousse_braise():
    """L'« herbe » de l'Île de Braise : un tapis de mousse sombre (coussinets bombés faits de
    petites rosettes serrées), vert olive tirant sur le brun, où passent des teintes cuivre et
    rouge sombre ; quelques brins ras à pointe cuivrée ; la cendre affleure çà et là."""
    S = 1024
    R = rng(7004)
    n = tn(R, S, (8, 16, 32, 64, 128, 256), 0.6)
    hue = tn(R, S, (8, 16, 32, 64), 0.7)
    hue2 = tn(R, S, (8, 16, 32, 64), 0.7)
    cop = tn(R, S, (8, 16, 32, 64, 128), 0.65)
    cov_n = tn(R, S, (8, 16, 32, 64, 128), 0.62)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.6)
    ash = mix(C(0.3, 0.28, 0.26), C(0.37, 0.35, 0.32), n) * (0.8 + 0.4 * gr[..., None])
    cov = smooth(0.17, 0.25, cov_n + (fine - 0.5) * 0.14)
    cush = gblur(cov, 5.0) * (0.7 + 0.6 * tn(R, S, (16, 32, 64), 0.6))
    _, me, mid, _, _ = worley(R, S, 210, 0.95)
    tipc = smooth(0.0, 2.0, me)
    mt = per_id(mid, R, 0.0, 1.0)
    _, me2, _, _, _ = worley(R, S, 420, 0.95)
    tip2 = smooth(0.0, 1.2, me2)
    moss = mix(C(0.23, 0.25, 0.115), C(0.3, 0.28, 0.135), smooth(0.25, 0.75, hue))
    moss = mix(moss, C(0.4, 0.23, 0.12), 0.18 + smooth(0.55, 0.8, cop) * 0.3)
    moss = mix(moss, C(0.33, 0.14, 0.1), smooth(0.66, 0.85, hue2) * 0.25)
    moss = moss * (0.62 + 0.38 * tipc[..., None]) * (0.86 + 0.14 * tip2[..., None]) * (0.84 + 0.32 * mt[..., None]) * (0.9 + 0.2 * gr[..., None])
    moss = moss * (0.85 + 0.25 * cush[..., None])
    col = mix(ash, moss, cov)
    h = 0.12 * n + cush * 0.45 + cov * (tipc * mt * 0.1 + tip2 * 0.04) + gr * 0.03
    img = to_img(col)
    d = ImageDraw.Draw(img)
    hm = Image.fromarray((np.clip(h, 0, 1) * 255).astype(np.uint8))
    dh = ImageDraw.Draw(hm)
    deep = np.array([0.18, 0.22, 0.09])
    olive = np.array([0.3, 0.28, 0.12])
    copper = np.array([0.48, 0.25, 0.11])
    red = np.array([0.36, 0.12, 0.08])
    tufts = R.random((2600, 2)) * S
    for count, bright, hv, ls in ((7000, 0.75, 170, 1.0), (6000, 0.95, 210, 0.85), (4000, 1.12, 240, 0.7)):
        for _ in range(count):
            cx, cy = tufts[R.integers(len(tufts))]
            x = cx + R.normal(0, 4)
            y = cy + R.normal(0, 4)
            xi, yi = int(x) % S, int(y) % S
            g = hue[yi, xi]
            c = deep * (1 - g) + olive * g
            cp = smooth(0.5, 0.72, cop[yi, xi])
            tipcol = c * (1 - cp) + (copper if R.random() < 0.7 else red) * cp
            if R.random() < 0.15:
                tipcol = copper * R.uniform(0.8, 1.1)
            c = c * bright * R.uniform(0.85, 1.15)
            tipcol = tipcol * bright * R.uniform(0.85, 1.15)
            a = R.uniform(0, TAU)
            L = R.uniform(7, 17) * ls
            w = R.uniform(1.3, 2.3)
            cv = R.uniform(-0.4, 0.4)
            poly = blade_poly(x, y, a, L, w, cv)
            tip = blade_poly(x + math.cos(a) * L * 0.55 - math.sin(a) * cv * L * 0.3, y + math.sin(a) * L * 0.55 + math.cos(a) * cv * L * 0.3,
                             a + cv * 0.6, L * 0.45, w * 0.5, cv)
            c1 = tuple(int(np.clip(v, 0, 1) * 255) for v in c)
            c2 = tuple(int(np.clip(v, 0, 1) * 255) for v in tipcol)
            hvv = int(hv + R.uniform(-20, 15))
            for ox, oy in offs(x, y, L + 4, S):
                pp = [(px + ox, py + oy) for px, py in poly]
                d.polygon(pp, fill=c1)
                d.polygon([(px + ox, py + oy) for px, py in tip], fill=c2)
                dh.polygon(pp, fill=hvv)
    col = gblur(from_img(img), 0.4)
    h = gblur(np.asarray(hm, np.float32) / 255.0, 0.8)
    sh = hshadow(h, 5.0, 10, 1.0)
    col = col * (1 - 0.25 * sh[..., None])
    col = bake(col, h, 3.0, k=0.3, ao=0.35, ao_r=6) * 1.36
    save_surface("mousse_braise", col, h, 4.0)


def paves_basalte():
    """Pavés de basalte des rues de la cité : rangs un peu ondulés de pavés de 12 à 25 cm, dessus
    presque plats aux arêtes arrondies, chacun un peu de travers ; dessus polis par les pas
    (plus clairs, lustrés), arêtes épaufrées, fines vacuoles ; joints sombres de terre et de
    cendre, un peu de sable clair, et de la mousse sombre seulement dans les joints les plus
    larges, à l'écart du passage."""
    S = 1024
    R = rng(7005)
    hs = R.uniform(32, 46, 26)
    hs = hs / hs.sum() * S
    bid, e, u, v = masonry(R, S, list(hs), 34, 80, rr=7.0)
    wx = tn(R, S, (2, 4, 8, 16), 0.6)
    wy = tn(R, S, (2, 4, 8, 16), 0.6)
    ax, ay = (wx - 0.5) * 10, (wy - 0.5) * 14
    e = warp(e, ax, ay)
    u = warp(u, ax, ay)
    v = warp(v, ax, ay)
    bid = warp_nn(bid, ax, ay)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    wob = tn(R, S, (32, 64, 128), 0.6)
    chip = tn(R, S, (16, 32, 64, 128), 0.7)
    jw = per_id(bid, R, 1.8, 4.4)
    e2 = e - jw - (wob - 0.5) * 5.0 - np.clip(chip - 0.66, 0, 1) * 20.0
    tone = per_id(bid, R, 0.86, 1.12)
    hue = per_id(bid, R, 0.0, 1.0)
    tx = per_id(bid, R, -0.1, 0.1)
    ty = per_id(bid, R, -0.1, 0.1)
    hz = per_id(bid, R, -0.06, 0.06)
    wearb = per_id(bid, R, 0.2, 1.0)
    face = smooth(0.0, 6.0, e2) ** 0.5
    crown = 1 - ((u - 0.5) ** 2 + (v - 0.5) ** 2) * 2.0
    stone = mix(C(0.31, 0.31, 0.32), C(0.345, 0.33, 0.315), hue) * tone[..., None]
    stone = stone * (0.86 + 0.26 * mot[..., None]) * (0.84 + 0.32 * fine[..., None])
    vp = pores(R, S, 3000, 0.4, 1.0)
    stone = stone * (1 - 0.35 * vp[..., None])
    sp = R.random((S, S)).astype(np.float32)
    stone = mix(stone, C(0.5, 0.5, 0.49), np.clip(gblur((sp < 0.002).astype(np.float32), 0.6) * 2.0, 0, 1) * 0.35)
    polish = smooth(3.0, 12.0, e2) * wearb * smooth(0.2, 0.6, crown)
    stone = mix(stone, stone * C(1.12, 1.12, 1.13), polish * 0.7)
    chipd = np.clip((e - jw - e2) / 14.0, 0, 1) * smooth(0.0, 2.0, e2)
    stone = mix(stone, C(0.4, 0.395, 0.39) * (0.85 + 0.3 * fine[..., None]), chipd * 0.4)
    grime = smooth(0.62, 0.82, tn(R, S, (8, 16, 32, 64), 0.6))
    stone = stone * (1 - 0.15 * grime[..., None])
    stone = stone * (0.8 + 0.2 * face[..., None])
    jm = 1 - smooth(-0.5, 1.2, e2)
    soil = mix(C(0.11, 0.1, 0.092), C(0.17, 0.16, 0.145), fine) * (0.8 + 0.4 * grain(R, S, 0.6)[..., None])
    sand = smooth(0.62, 0.72, tn(R, S, (8, 16, 32, 64), 0.6))
    soil = mix(soil, C(0.38, 0.36, 0.33) * (0.8 + 0.4 * fine[..., None]), sand * 0.65)
    wide = smooth(3.4, 4.2, jw)
    mz = smooth(0.6, 0.7, tn(R, S, (8, 16, 32, 64), 0.6)) * wide * smooth(0.45, 0.6, fine)
    soil = mix(soil, mix(C(0.13, 0.16, 0.07), C(0.27, 0.14, 0.08), smooth(0.4, 0.7, mot)) * (0.75 + 0.5 * fine[..., None]), mz)
    col = mix(stone, soil, jm)
    h = face * 0.45 + (crown * 0.08 + (u - 0.5) * tx + (v - 0.5) * ty + hz) * smooth(0.0, 4.0, e2) + mot * 0.03 + fine * 0.035 \
        - vp * 0.06 - jm * 0.12 + mz * jm * 0.08 - chipd * 0.12
    sh = hshadow(h, 6.0, 12, 1.0)
    col = col * (1 - 0.3 * sh[..., None])
    col = bake(col, h, 5.0, k=0.3, ao=0.4, ao_r=4)
    gx, gy = grads(gblur(h, 1.0))
    sheen = np.clip(-(gx * -0.45 + gy * -0.6) * 40, 0, 1) * polish
    col = col + (sheen * 0.04)[..., None]
    save_surface("paves_basalte", col, h, 6.0)


def obsidienne():
    """Obsidienne : verre volcanique noir, débité en éclats ; chaque enlèvement laisse une
    cuvette conchoïdale (ondes concentriques en coquille autour du point d'impact), et les
    cuvettes se recoupent en arêtes vives et courbes qui accrochent la lumière ; rubanement de
    coulée à peine visible, reflets violets selon l'orientation, quelques sphérolites gris."""
    S = 1024
    R = rng(7006)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    hmin = np.full((S, S), 1e9, np.float32)
    hsec = np.full((S, S), 1e9, np.float32)
    rdx = np.zeros((S, S), np.float32)
    rdy = np.zeros((S, S), np.float32)
    lam_ = np.zeros((S, S), np.float32)
    K = 44
    for k in range(K):
        cx, cy = R.random(2) * S
        r = R.uniform(80, 200)
        depth = R.uniform(0.6, 1.4)
        b = R.uniform(-0.5, 0.5)
        dx = np.mod(xx - cx + S / 2, S) - S / 2
        dy = np.mod(yy - cy + S / 2, S) - S / 2
        an = R.uniform(0, TAU)
        el = R.uniform(0.6, 1.0)
        u = dx * math.cos(an) + dy * math.sin(an)
        v = (-dx * math.sin(an) + dy * math.cos(an)) / el
        bowl = b - depth + depth * (u * u + v * v) / (r * r)
        ia = R.uniform(0, TAU)
        ix, iy = dx + math.cos(ia) * r * 0.85, dy + math.sin(ia) * r * 0.85
        lower = bowl < hmin
        hsec = np.where(lower, hmin, np.minimum(hsec, bowl))
        hmin = np.where(lower, bowl, hmin)
        rdx = np.where(lower, ix, rdx)
        rdy = np.where(lower, iy, rdy)
        lam_ = np.where(lower, np.float32(R.uniform(16, 30)), lam_)
    rr = np.hypot(rdx, rdy) + (tn(R, S, (8, 16, 32), 0.6) - 0.5) * 10
    ripple = np.sin(rr / lam_ * TAU) * np.exp(-rr / 300.0)
    ridge = np.exp(-(hsec - hmin) / 0.012)
    h = hmin * 0.5 + ripple * 0.012
    fine = tn(R, S, (64, 128, 256, 512), 0.75)
    band = np.sin((yy / S * 7 + xx / S * 2 + (tn(R, S, (2, 4, 8), 0.5) - 0.5) * 3.0) * TAU)
    col = C(0.18, 0.168, 0.2) * (0.93 + 0.1 * band[..., None]) * (0.92 + 0.16 * fine[..., None])
    col = col * (1 + 0.025 * ripple[..., None])
    sph = speck(R, S, 0.00010, 2.2)
    col = mix(col, C(0.36, 0.35, 0.36), np.clip(sph * 1.3, 0, 1) * 0.55)
    gx, gy = grads(gblur(h, 0.7))
    st = 16.0
    nx, ny = -gx * st, -gy * st
    inv = 1 / np.sqrt(nx * nx + ny * ny + 1)
    L = np.array(LIGHT, np.float32)
    L /= np.linalg.norm(L)
    ndl = (nx * L[0] + ny * L[1] + L[2]) * inv
    hv = np.array([L[0], L[1], L[2] + 1.0])
    hv /= np.linalg.norm(hv)
    ndh = np.clip((nx * hv[0] + ny * hv[1] + hv[2]) * inv, 0, 1)
    tilt = np.clip(1 - inv, 0, 1)
    az_ = np.arctan2(ny, nx)
    sheen = smooth(0.0, 0.25, tilt) * (0.5 + 0.5 * np.sin(az_ * 2 + fine * 3))
    col = col + sheen[..., None] * C(0.1, 0.045, 0.14)
    col = col * (0.82 + 0.25 * np.clip(ndl, 0, 1.3))[..., None]
    col = col + ((ndh ** 40) * 0.14)[..., None] * C(0.92, 0.9, 1.0)
    col = col + (ridge * 0.08)[..., None] * C(0.75, 0.73, 0.82)
    save_surface("obsidienne", col * 1.12, h, 16.0)


def soufre():
    """Croûte de soufre des fumerolles : masses bourgeonnantes jaune citron à jaune verdâtre, au
    grain de sucre cristallin qui scintille (cristaux millimétriques) ; un peu
    d'orangé et de brun-rouge au creux des bourgeons (plus chaud), des voiles blancs de sels, la
    cendre grise dans quelques fentes."""
    S = 1024
    R = rng(7007)
    n = tn(R, S, (4, 8, 16, 32, 64, 128), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.6)
    wx = tn(R, S, (8, 16, 32), 0.6)
    wy = tn(R, S, (8, 16, 32), 0.6)
    ax, ay = (wx - 0.5) * 16, (wy - 0.5) * 16
    d1, ed, _, _, _ = worley(R, S, 26, 0.95)
    b1 = np.sqrt(np.clip(1 - (warp(d1, ax, ay) / (S / 26 * 0.8)) ** 2, 0, 1))
    d2, _, _, _, _ = worley(R, S, 70, 0.95)
    b2 = np.sqrt(np.clip(1 - (warp(d2, ay, ax) / (S / 70 * 0.8)) ** 2, 0, 1))
    bump = np.maximum(b1 * 0.9, b2 * 0.55 + 0.25) * (0.75 + 0.5 * tn(R, S, (8, 16, 32), 0.6))
    _, ec, cc, _, _ = worley(R, S, 330, 0.95)
    xtal = per_id(cc, R, 0.0, 1.0)
    facet = smooth(0.0, 1.0, ec)
    cav = smooth(0.02, 0.15, np.clip(gblur(bump, 8) - bump, 0, None))
    col = mix(C(0.82, 0.72, 0.24), C(0.88, 0.8, 0.36), n)
    col = mix(col, C(0.74, 0.72, 0.32), smooth(0.55, 0.8, tn(R, S, (8, 16, 32), 0.6)) * 0.5)
    col = mix(col, C(0.84, 0.54, 0.16), smooth(0.4, 0.9, cav) * smooth(0.45, 0.65, tn(R, S, (8, 16, 32), 0.6)) * 0.75)
    col = mix(col, C(0.55, 0.3, 0.14), smooth(0.7, 1.0, cav) * 0.4)
    col = col * (0.84 + 0.22 * xtal[..., None]) * (0.92 + 0.08 * facet[..., None]) * (0.92 + 0.14 * gr[..., None])
    col = col * (0.86 + 0.18 * bump[..., None])
    salt = smooth(0.75, 0.8, tn(R, S, (32, 64, 128, 256), 0.6) + (fine - 0.5) * 0.16)
    col = mix(col, C(0.86, 0.85, 0.8) * (0.9 + 0.15 * fine[..., None]), salt * 0.55)
    crk = (1 - smooth(0.3, 1.3, warp(ed, ax, ay))) * smooth(0.72, 0.78, tn(R, S, (4, 8, 16), 0.6)) * (1 - salt)
    col = mix(col, C(0.4, 0.36, 0.28) * (0.8 + 0.4 * fine[..., None]), crk * 0.6)
    h = bump * 0.5 + n * 0.15 + xtal * facet * 0.05 + fine * 0.04 - crk * 0.2 + salt * 0.03
    img = to_img(col)
    hm = Image.fromarray((np.clip(h, 0, 1) * 200).astype(np.uint8))
    col = gblur(from_img(img), 0.3)
    h = gblur(np.asarray(hm, np.float32) / 255.0, 0.6)
    sh = hshadow(h, 7.0, 12, 1.0)
    col = col * (1 - 0.3 * sh[..., None])
    col = bake(col, h, 4.0, k=0.3, ao=0.35, ao_r=5)
    spark = (xtal > 0.985) * facet * 0.12
    col = col + spark[..., None] * C(1.0, 1.0, 0.9)
    save_surface("soufre", col, h, 5.0)


def roche_volcan():
    """Falaise de roche volcanique oxydée : strates de tufs et de scories qui ondulent et
    s'amincissent, rouge-brun, lie-de-vin, ocre et gris-brun ; les bancs durs font saillie (arêtes
    émoussées), les tendres sont creusés et grêlés ; diaclases presque verticales, souvent
    arrêtées d'un banc à l'autre ; quelques blocs anguleux dans les brèches ; coulures sombres,
    poussière claire sur les rebords."""
    S = 1024
    R = rng(7008)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    n = tn(R, S, (4, 8, 16, 32, 64, 128), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    mid = tn(R, S, (16, 32, 64, 128), 0.6)
    wv = tn(R, S, (2, 4, 8), 0.55)
    wv2 = tn(R, S, (8, 16, 32), 0.6)
    th = R.uniform(22, 110, 40)
    k = int(np.searchsorted(np.cumsum(th), S)) + 1
    th = th[:k]
    th = th / th.sum() * S
    tops = np.concatenate([[0.0], np.cumsum(th)])
    ys = np.mod(yy + (wv - 0.5) * 120 + (wv2 - 0.5) * 26, S)
    li = np.clip(np.searchsorted(tops, ys, side="right") - 1, 0, len(th) - 1)
    lv = (ys - tops[li]) / th[li]
    nl = len(th)
    kinds = R.choice(4, nl, p=[0.4, 0.25, 0.15, 0.2])   # 0 tuf fin, 1 scorie, 2 brèche, 3 banc massif
    pal = np.array([(0.47, 0.3, 0.23), (0.4, 0.26, 0.21), (0.5, 0.37, 0.27), (0.38, 0.33, 0.3), (0.44, 0.27, 0.22),
                    (0.42, 0.3, 0.27)], np.float32)
    lc = pal[R.integers(0, len(pal), nl)] * R.uniform(0.9, 1.1, (nl, 1)).astype(np.float32)
    hard = R.uniform(0.15, 0.85, nl).astype(np.float32)
    hard[kinds == 3] = R.uniform(0.75, 1.0, int((kinds == 3).sum()))
    hard[kinds == 1] *= 0.6
    kp = kinds[li]
    lcol = lc[li]
    # transition douce entre bancs voisins (pas d'aplats)
    nb = lc[np.clip(li + 1, 0, nl - 1)]
    lcol = mix(lcol, nb, smooth(0.75, 1.0, lv) * 0.4)
    col = lcol * (0.8 + 0.4 * n[..., None]) * (0.85 + 0.3 * fine[..., None]) * (0.88 + 0.24 * mid[..., None])
    lam = np.sin((lv * th[li] / 4.5) * TAU + wv2 * 5)
    col = col * (1 + 0.035 * lam[..., None] * (kp == 0)[..., None])
    edge = np.minimum(lv, 1 - lv) * th[li]
    ero = tn(R, S, (16, 32, 64, 128), 0.6)
    prot = hard[li] * smooth(0.0, 8.0 + 10.0 * ero, edge) ** 0.7
    rough = ridged(tn(R, S, (32, 64, 128, 256, 512), 0.65))
    h = prot * 0.7 + n * 0.3 + mid * 0.15 + rough * 0.3 * (1.2 - hard[li]) + fine * 0.06
    col = col * (0.86 + 0.2 * rough[..., None])
    items = []
    for _ in range(900):
        x, y = R.random(2) * S
        r = R.uniform(2.5, 11)
        items.append((x, y, rock_poly(R, r, k=int(R.integers(4, 7)), jit=0.35), r))
    ids = scatter(S, items)
    hn, mask = domes(ids, len(items))
    inbr = ((kp == 2) & mask).astype(np.float32)
    cl = np.vstack([np.zeros((1, 3), np.float32), pal[R.integers(0, len(pal), len(items))] * R.uniform(0.75, 1.15, (len(items), 1)).astype(np.float32)])
    col = mix(col, cl[ids] * (0.85 + 0.3 * fine[..., None]), inbr * 0.85)
    h = h + inbr * hn * 0.15
    vp = pores(R, S, 14000, 0.6, 2.0) * (kp == 1)
    col = col * (1 - 0.45 * vp[..., None])
    h = h - vp * 0.12
    # diaclases : presque verticales, une famille par banc, décalées d'un banc à l'autre
    kk = R.integers(3, 9, nl)
    off = R.uniform(0, S, nl)
    jit = (tn(R, S, (16, 32, 64), 0.6, oy=(64, 128, 256)) - 0.5) * 8 + (tn(R, S, (4, 8), 0.6) - 0.5) * 30
    per = S / kk[li]
    ph = np.mod(xx + off[li] + jit, per)
    dj = np.minimum(ph, per - ph)
    jvis = smooth(0.42, 0.55, tn(R, S, (4, 8, 16), 0.6))
    jw = 0.6 + 1.6 * fine
    joint = (1 - smooth(jw * 0.5, jw + 1.0, dj)) * jvis * smooth(0.0, 6.0, edge)
    col = mix(col, C(0.1, 0.075, 0.065), joint * 0.85)
    h = h - joint * 0.35
    bj = 1 - smooth(0.0, 2.5 + 2 * ero, edge)
    col = col * (1 - 0.18 * bj[..., None])
    h = h - bj * 0.06
    streak = smooth(0.6, 0.85, tn(R, S, (16, 32, 64, 128), 0.65, oy=(2, 4, 8, 16)))
    col = col * (1 - 0.22 * streak[..., None])
    gy = np.roll(h, -2, 0) - np.roll(h, 2, 0)
    top = smooth(0.02, 0.1, -gy) * smooth(0.4, 0.7, tn(R, S, (8, 16, 32), 0.6))
    col = mix(col, C(0.6, 0.52, 0.43), top * 0.3)
    sh = hshadow(h, 10.0, 16, 1.5)
    col = col * (1 - 0.32 * sh[..., None])
    col = bake(col, h, 6.0, k=0.45, ao=0.35, ao_r=7)
    save_surface("roche_volcan", col, h, 7.0)


def lave_croute():
    """Croûte de lave refroidie : plaques noires bombées, ridées, vacuoles et lustre vitreux,
    séparées par des fentes fines où luit la lave orange-rouge (plus jaune au cœur des fentes) ;
    le bord des plaques rougeoie encore. Écrit aussi lave_croute_e.png (émission : les fentes)."""
    S = 1024
    R = rng(7009)
    n = tn(R, S, (4, 8, 16, 32, 64, 128), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    wx = tn(R, S, (4, 8, 16, 32), 0.6)
    wy = tn(R, S, (4, 8, 16, 32), 0.6)
    d1, edge, cid, dx, dy = worley(R, S, 8, 0.85)
    ax, ay = (wx - 0.5) * 40, (wy - 0.5) * 40
    edge = warp(edge, ax, ay)
    cidw = warp_nn(cid, ax, ay)
    _, e2, _, _, _ = worley(R, S, 19, 0.9)
    e2 = warp(e2, (wy - 0.5) * 22, (wx - 0.5) * 22)
    wid = 1.2 + 2.6 * tn(R, S, (4, 8, 16, 32), 0.6)
    crack = 1 - smooth(wid * 0.5, wid + 1.0, edge)
    core = 1 - smooth(0.0, wid * 0.55, edge)
    sec = (1 - smooth(0.3, 1.3, e2)) * smooth(0.5, 0.64, tn(R, S, (4, 8, 16), 0.6))
    glow = np.clip(crack + sec * 0.6, 0, 1)
    heat = np.exp(-edge / 9.0) * 0.8 + np.exp(-e2 / 5.0) * sec * 0.4
    # plaques
    dome = smooth(0.0, 60.0, edge) ** 0.7
    wr = ridged(tn(R, S, (16, 32, 64, 128), 0.6))
    rope = np.sin((warp(d1, ax, ay) / 9.0 + (wr - 0.5) * 2.0) * TAU) * 0.5 + 0.5
    vp = pores(R, S, 9000, 0.6, 1.8)
    tone = per_id(cidw, R, 0.85, 1.15)
    plate = mix(C(0.15, 0.142, 0.137), C(0.24, 0.228, 0.216), n) * tone[..., None] * (0.82 + 0.36 * fine[..., None])
    plate = plate * (0.85 + 0.22 * wr[..., None]) * (1 - 0.5 * vp[..., None])
    plate = mix(plate, C(0.26, 0.11, 0.07), smooth(0.15, 0.7, heat) * 0.7)
    plate = mix(plate, C(0.24, 0.19, 0.17), smooth(0.7, 0.85, tn(R, S, (8, 16, 32), 0.6)) * 0.35)
    h = dome * 0.5 + wr * 0.12 + rope * 0.05 * dome + n * 0.15 + fine * 0.04 - vp * 0.1 - glow * 0.5
    sh = hshadow(h, 8.0, 12, 1.2)
    plate = plate * (1 - 0.35 * sh[..., None])
    plate = bake(plate, h, 6.0, k=0.45, ao=0.35, ao_r=6)
    gx, gy = grads(gblur(h, 0.8))
    lam = np.clip((gx * 6 * 0.45 + gy * 6 * 0.6 + 0.66) / np.sqrt((gx * 6) ** 2 + (gy * 6) ** 2 + 1), 0, 1)
    plate = plate + (lam ** 30 * 0.12)[..., None] * C(0.9, 0.92, 1.0)
    hotc = mix(C(0.7, 0.12, 0.03), C(1.0, 0.5, 0.08), np.clip(core * 1.2, 0, 1))
    hotc = mix(hotc, C(1.0, 0.85, 0.4), smooth(0.6, 1.0, core) * 0.8)
    col = mix(plate, hotc, glow)
    save_surface("lave_croute", col, h, 6.0)
    em = np.clip(glow * (0.55 + 0.45 * core) + smooth(0.2, 0.9, heat) * 0.18 * (1 - glow), 0, 1)
    save_gray(em, "lave_croute_e.png")


def lave():
    """Lave en fusion qui coule : courants étirés et tourbillonnants, orange vif et rouge, cœurs
    jaunes dans les veines rapides ; des peaux sombres qui se figent et dérivent par plaques,
    bordées d'un liseré plus vif là où elles se déchirent."""
    S = 1024
    R = rng(7010)
    a1 = tn(R, S, (2, 4, 8, 16), 0.55)
    a2 = tn(R, S, (2, 4, 8, 16), 0.55)
    s1 = tn(R, S, (4, 8, 16, 32, 64, 128), 0.6, oy=(16, 32, 64, 128, 256, 512))
    s1 = warp(s1, (a1 - 0.5) * 160, (a2 - 0.5) * 90)
    s2 = tn(R, S, (8, 16, 32, 64, 128), 0.6, oy=(32, 64, 128, 256, 512))
    s2 = warp(s2, (a2 - 0.5) * 120, (a1 - 0.5) * 60)
    T = norm01(0.6 * s1 + 0.4 * ridged(s2))
    T = smooth(0.1, 0.9, T)
    fine = tn(R, S, (64, 128, 256, 512), 0.7)
    T = np.clip(0.18 + 0.82 * T + (fine - 0.5) * 0.1, 0, 1)
    d1, edge, cid, _, _ = worley(R, S, 8, 0.9)
    ex, ey = (a1 - 0.5) * 70, (a2 - 0.5) * 70
    edge = warp(edge, ex, ey)
    cidw = warp_nn(cid, ex, ey)
    keep = (per_id(cidw, R, 0, 1) < 0.55).astype(np.float32)
    skin_n = tn(R, S, (8, 16, 32, 64), 0.6)
    skin = keep * smooth(5.0, 18.0, edge) * smooth(0.4, 0.58, skin_n) * smooth(0.85, 0.45, T)
    skin = gblur(skin, 1.2)
    rim = np.clip(gblur(skin, 3.0) * 1.6 - skin * 1.4, 0, 1)
    T = np.clip(T * (1 - 0.95 * skin) + rim * 0.45, 0, 1)
    stops = [(0.0, (0.07, 0.03, 0.025)), (0.2, (0.26, 0.04, 0.02)), (0.38, (0.58, 0.08, 0.02)), (0.56, (0.86, 0.25, 0.03)),
             (0.72, (0.98, 0.46, 0.06)), (0.86, (1.0, 0.68, 0.18)), (1.0, (1.0, 0.86, 0.48))]
    col = np.zeros((S, S, 3), np.float32)
    for (t0, c0), (t1, c1) in zip(stops[:-1], stops[1:]):
        m = (T >= t0) & (T <= t1)
        f = ((T - t0) / (t1 - t0))[m]
        col[m] = np.array(c0, np.float32) * (1 - f[:, None]) + np.array(c1, np.float32) * f[:, None]
    wr = ridged(tn(R, S, (16, 32, 64, 128), 0.6))
    skc = mix(C(0.1, 0.06, 0.05), C(0.2, 0.12, 0.1), wr) * (0.8 + 0.4 * fine[..., None])
    col = mix(col, skc, smooth(0.3, 0.8, skin) * 0.95)
    h = (1 - T) * 0.35 + skin * (0.3 + wr * 0.15)
    save_surface("lave", col, h, 3.0)


def sols():
    cendre()
    basalte()
    sable_noir()
    mousse_braise()
    paves_basalte()
    obsidienne()
    soufre()
    roche_volcan()
    lave_croute()
    lave()


# =================================================================== le bâti (une tuile ≈ 3 m)

def worley_xy(R, W, H, nx, ny, jitter=0.85, rx=2, ry=1):
    """Cellules de Voronoï raccordables sur une grille nx x ny (cellules allongées si nx/W ≠ ny/H).
    Renvoie d1, distance à la frontière (px), id, dx, dy vers la graine."""
    pts = (0.5 + (R.random((ny, nx, 2)) - 0.5) * jitter).astype(np.float32)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    cw, ch = W / nx, H / ny
    cx = np.floor(xx / cw).astype(np.int32)
    cy = np.floor(yy / ch).astype(np.int32)

    def cand():
        for oy in range(-ry, ry + 1):
            for ox in range(-rx, rx + 1):
                gx = (cx + ox) % nx
                gy = (cy + oy) % ny
                yield (cx + ox + pts[gy, gx, 0]) * cw, (cy + oy + pts[gy, gx, 1]) * ch, gy * nx + gx
    d1 = np.full((H, W), 1e9, np.float32)
    i1 = np.zeros((H, W), np.int32)
    p1x = np.zeros((H, W), np.float32)
    p1y = np.zeros((H, W), np.float32)
    for px, py, cid in cand():
        d = np.hypot(xx - px, yy - py)
        c = d < d1
        d1 = np.where(c, d, d1)
        i1 = np.where(c, cid, i1)
        p1x = np.where(c, px, p1x)
        p1y = np.where(c, py, p1y)
    edge = np.full((H, W), 1e9, np.float32)
    for px, py, cid in cand():
        mx, my = (px + p1x) * 0.5, (py + p1y) * 0.5
        ux, uy = px - p1x, py - p1y
        L = np.hypot(ux, uy)
        valid = L > 1e-3
        dd = np.where(valid, ((mx - xx) * ux + (my - yy) * uy) / np.maximum(L, 1e-3), 1e9)
        edge = np.minimum(edge, dd)
    return d1, edge, i1, xx - p1x, yy - p1y


def roof_rows(R, S, nrows, ncols, shape, depth, jit=1.5):
    """Rangs d'éléments de toiture qui se recouvrent (le rang du dessus couvre la tête du rang
    du dessous ; la pente descend vers le bas de l'image). shape(u) donne la remontée du bord
    bas (0 au milieu) pour u dans [-1, 1]. Renvoie id, distance au bord bas (px), u, rang, colonne."""
    rh, sw = S / nrows, S / ncols
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    ej = (tn(R, S, (32, 64, 128), 0.6) - 0.5) * 2 * jit
    rowoff = R.uniform(-0.06, 0.06, nrows) * sw
    best = np.full((S, S), -1, np.int32)
    db = np.zeros((S, S), np.float32)
    uu = np.zeros((S, S), np.float32)
    rr_ = np.zeros((S, S), np.int32)
    cc_ = np.zeros((S, S), np.int32)
    r0 = np.floor(yy / rh).astype(np.int32)
    found = np.zeros((S, S), bool)
    for dr in (-1, 0, 1, 2):
        r = r0 + dr
        rm = np.mod(r, nrows)
        off = (rm % 2) * sw * 0.5 + rowoff[rm]
        xr = xx - off
        c = np.floor(xr / sw).astype(np.int32)
        u = (xr - (c + 0.5) * sw) / (sw * 0.5)
        yb = (r + 1) * rh + ej - depth * shape(u)
        hit = (~found) & (yy < yb)
        best = np.where(hit, rm * 1000 + np.mod(c, ncols), best)
        db = np.where(hit, yb - yy, db)
        uu = np.where(hit, u, uu)
        rr_ = np.where(hit, rm, rr_)
        cc_ = np.where(hit, np.mod(c, ncols), cc_)
        found |= hit
    return best, db, uu, rr_, cc_


def pierre_gothique():
    """Pierre de taille gris sombre en assises réglées (35 à 40 cm), blocs de 70 cm à 1,5 m,
    joints fins de mortier de chaux noirci ; layures du taillage en biais, arêtes un peu
    épaufrées ; coulures de suie qui partent de chaque joint de lit, traînées de pluie plus
    claires, croûtes noires par plaques."""
    S = 1024
    R = rng(7101)
    rows = [132, 124, 130, 126, 128, 134, 122, 128]
    bid, e, u, v = masonry(R, S, rows, 250, 520, rr=2.5)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    chip = tn(R, S, (16, 32, 64, 128), 0.7)
    e2 = e - 1.6 - np.clip(chip - 0.64, 0, 1) * 34.0
    tone = per_id(bid, R, 0.86, 1.12)
    hue = per_id(bid, R, 0.0, 1.0)
    tilt = per_id(bid, R, -0.03, 0.03)
    stone = mix(C(0.37, 0.365, 0.355), C(0.4, 0.385, 0.365), hue) * tone[..., None]
    stone = stone * (0.88 + 0.22 * mot[..., None]) * (0.9 + 0.2 * fine[..., None])
    ta = per_id(bid, R, 0.7, 1.2) * np.where(per_id(bid, R, 0, 1) < 0.5, 1, -1)
    tool = np.sin((xx * np.cos(ta) + yy * np.sin(ta)) / per_id(bid, R, 4.0, 6.0) * TAU)
    toolm = smooth(4.0, 12.0, e2) * (0.5 + 0.5 * tn(R, S, (16, 32, 64), 0.6))
    stone = stone * (1 + 0.025 * (tool * toolm)[..., None])
    pits = speck(R, S, 0.002, 0.8)
    stone = stone * (1 - 0.3 * pits[..., None])
    chipd = np.clip((e - 1.6 - e2) / 20.0, 0, 1) * smooth(0.0, 3.0, e)
    stone = mix(stone, stone * C(1.12, 1.1, 1.08), chipd * 0.6)
    face = smooth(0.0, 4.0, e2) ** 0.6 * 0.7 + smooth(1.0, 4.0, e) * 0.3
    # suie : coulures sous chaque joint de lit, plus fortes par endroits
    rhs = np.zeros_like(v)
    top = 0
    for hgt in rows:
        rhs[top:top + hgt] = hgt
        top += hgt
    below = v * rhs
    stk = tn(R, S, (32, 64, 128, 256), 0.65, oy=(2, 4, 8, 16))
    stk2 = tn(R, S, (64, 128, 256, 512), 0.7, oy=(4, 8, 16, 32))
    Lr = 18 + 70 * stk
    soot = np.exp(-below / Lr) * smooth(0.4, 0.75, stk2) * smooth(0.3, 0.6, tn(R, S, (4, 8, 16), 0.6))
    stone = mix(stone, C(0.1, 0.095, 0.09), np.clip(soot, 0, 1) * 0.6)
    big = smooth(0.5, 0.85, tn(R, S, (4, 8, 16, 32), 0.6, oy=(1, 2, 4, 8)))
    stone = mix(stone, stone * C(0.55, 0.54, 0.53), big * 0.45)
    wash = smooth(0.62, 0.85, tn(R, S, (16, 32, 64, 128), 0.6, oy=(2, 4, 8, 16)))
    stone = mix(stone, stone * C(1.15, 1.14, 1.12), wash * (1 - big) * 0.5)
    crust = smooth(0.72, 0.8, tn(R, S, (16, 32, 64), 0.6)) * smooth(26.0, 4.0, e) * (1 - chipd)
    stone = mix(stone, C(0.14, 0.135, 0.13) * (0.8 + 0.4 * fine[..., None]), crust * 0.4)
    stone = stone * (0.86 + 0.14 * face[..., None])
    jm = 1 - smooth(1.0, 2.4, e)
    mortar = C(0.33, 0.31, 0.29) * (0.8 + 0.4 * fine[..., None]) * (1 - 0.4 * np.clip(soot, 0, 1)[..., None])
    col = mix(stone, mortar, jm)
    h = face * 0.6 + (u - 0.5) * tilt + mot * 0.06 + fine * 0.04 + tool * toolm * 0.012 - pits * 0.08 - jm * 0.12 + crust * 0.03
    h = h - np.clip((e - 1.6 - e2) / 40.0, 0, 0.5) * 0.4
    sh = hshadow(h, 5.0, 10, 1.0)
    col = col * (1 - 0.25 * sh[..., None])
    col = bake(col, h, 4.0, k=0.3, ao=0.3, ao_r=4)
    save_surface("pierre_gothique", col, h, 5.0)


def brique_noire():
    """Briques recuites (« briques noires ») : surfaces vitrifiées noires à violacées, brun
    sombre, quelques rouges ; bouts plus sombres (flammés), cloques et fentes de cuisson, bords
    un peu déformés ; mortier de chaux gris en retrait, noirci de suie ; coulures."""
    S = 1024
    R = rng(7102)
    rows, per_row = 32, 9
    rh, bw = S / rows, S / per_row
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    r = np.floor(yy / rh).astype(np.int32)
    roff = (r % 2) * bw * 0.5 + np.take(R.uniform(-6, 6, rows).astype(np.float32), r)
    xr = np.mod(xx + roff, S)
    ci = np.floor(xr / bw).astype(np.int32)
    bid = r * 100 + ci
    lu = xr - ci * bw
    lv = yy - r * rh
    dx = np.minimum(lu, bw - lu)
    dy = np.minimum(lv, rh - lv)
    rr = 3.0
    e = np.where((dx < rr) & (dy < rr), rr - np.hypot(rr - dx, rr - dy), np.minimum(dx, dy))
    wob = tn(R, S, (32, 64, 128, 256), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    e2 = e - 3.2 - (wob - 0.5) * 3.0 - np.clip(tn(R, S, (32, 64, 128), 0.7) - 0.68, 0, 1) * 16
    kind = per_id(bid, R, 0.0, 1.0)
    tone = per_id(bid, R, 0.82, 1.15)
    black = C(0.2, 0.165, 0.17)
    purple = C(0.27, 0.19, 0.2)
    brown = C(0.32, 0.21, 0.16)
    redb = C(0.42, 0.2, 0.15)
    base = np.where((kind < 0.38)[..., None], black, np.where((kind < 0.66)[..., None], purple,
                    np.where((kind < 0.86)[..., None], brown, redb)))
    flash = per_id(bid, R, -1, 1)
    end = np.clip(((lu / bw) - 0.5) * 2 * flash, 0, 1)
    brick = base * tone[..., None] * (1 - 0.35 * end[..., None]) * (0.85 + 0.3 * mot[..., None]) * (0.86 + 0.28 * fine[..., None])
    gl = per_id(bid, R, 0.0, 1.0)
    blist = speck(R, S, 0.0012, 1.4) * (gl > 0.4)
    brick = brick * (1 + 0.25 * blist[..., None])
    crk = speck(R, S, 0.0006, 1.8) * smooth(0.4, 0.6, tn(R, S, (8, 16, 32), 0.6))
    brick = brick * (1 - 0.35 * crk[..., None])
    face = smooth(0.0, 3.0, e2) ** 0.6
    jm = 1 - smooth(-0.3, 1.0, e2)
    mortar = C(0.42, 0.41, 0.39) * (0.78 + 0.44 * grain(R, S, 0.7)[..., None]) * (0.9 + 0.2 * fine[..., None])
    soot = smooth(0.5, 0.85, tn(R, S, (16, 32, 64, 128), 0.65, oy=(2, 4, 8, 16)))
    mortar = mortar * (1 - 0.4 * soot[..., None])
    col = mix(brick * (0.8 + 0.2 * face[..., None]), mortar, jm)
    col = col * (1 - 0.18 * soot[..., None])
    h = face * 0.6 + mot * 0.06 + fine * 0.05 + blist * 0.1 - crk * 0.1 - jm * 0.25 + wob * 0.04
    sh = hshadow(h, 4.0, 8, 0.8)
    col = col * (1 - 0.3 * sh[..., None])
    col = bake(col, h, 4.0, k=0.3, ao=0.35, ao_r=3)
    gx, gy = grads(gblur(h, 1.0))
    sheen = np.clip(-(gx * -0.45 + gy * -0.6) * 30, 0, 1) * (gl > 0.55) * face
    col = col + (sheen * 0.05)[..., None]
    save_surface("brique_noire", col * 1.08, h, 5.0)


def enduit_rouge():
    """Enduit rouge sombre (sang-de-bœuf) patiné : coups de lissoir, rouge plus pâle là où le
    soleil l'a lavé, plus sombre sous les salissures qui coulent ; fines fêlures ; petits éclats
    (quelques centimètres) qui montrent la couche de chaux claire puis la pierre grise."""
    S = 1024
    R = rng(7103)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    gr = grain(R, S, 0.7)
    b1 = tn(R, S, (8, 16, 32, 64), 0.7, oy=(32, 64, 128, 256))
    b2 = tn(R, S, (32, 64, 128, 256), 0.7, oy=(8, 16, 32, 64))
    brush = np.where(tn(R, S, (4, 8, 16), 0.6) > 0.5, b1, b2)
    red = mix(C(0.56, 0.19, 0.15), C(0.66, 0.25, 0.19), mot) * (0.93 + 0.1 * brush[..., None]) * (0.95 + 0.08 * fine[..., None])
    red = red * (0.94 + 0.1 * gr[..., None])
    pale = smooth(0.5, 0.85, tn(R, S, (4, 8, 16, 32), 0.6))
    red = mix(red, C(0.7, 0.38, 0.31), pale * 0.35)
    grime = smooth(0.55, 0.85, tn(R, S, (16, 32, 64, 128), 0.6, oy=(2, 4, 8, 16)))
    red = red * (1 - 0.22 * grime[..., None])
    # petits éclats : la peinture, puis la chaux, puis la pierre
    chip_n = tn(R, S, (64, 128, 256), 0.6)
    edge_n = tn(R, S, (256, 512), 0.7)
    cv = chip_n + (edge_n - 0.5) * 0.08 + (tn(R, S, (4, 8, 16), 0.6) - 0.5) * 0.2
    clu = smooth(0.42, 0.62, tn(R, S, (2, 4, 8, 16), 0.6))
    cv = cv - (1 - clu) * 0.2
    lime = smooth(0.815, 0.825, cv)
    stone = smooth(0.85, 0.86, cv)
    rim = np.exp(-((cv - 0.818) / 0.004) ** 2)
    limec = C(0.78, 0.74, 0.66) * (0.9 + 0.12 * fine[..., None])
    stonec = C(0.46, 0.45, 0.43) * (0.8 + 0.35 * fine[..., None]) * (0.9 + 0.2 * gr[..., None])
    col = mix(red, limec, lime)
    col = mix(col, stonec, stone)
    col = col * (1 - 0.3 * rim[..., None])
    wx = tn(R, S, (8, 16, 32), 0.6)
    wy = tn(R, S, (8, 16, 32), 0.6)
    _, edge, _, _, _ = worley(R, S, 9, 0.9)
    edge = warp(edge, (wx - 0.5) * 30, (wy - 0.5) * 30)
    crack = (1 - smooth(0.3, 1.1, edge)) * smooth(0.52, 0.62, tn(R, S, (4, 8, 16), 0.6))
    col = col * (1 - 0.45 * crack[..., None])
    h = 0.6 - lime * 0.12 - stone * 0.15 + mot * 0.08 + fine * 0.04 + brush * 0.03 - crack * 0.2 + gr * 0.02
    sh = hshadow(h, 3.0, 6, 0.6)
    col = col * (1 - 0.3 * sh[..., None])
    col = bake(col, h, 4.0, k=0.25, ao=0.2, ao_r=3)
    save_surface("enduit_rouge", col, h, 4.0)


def _veins(R, S, n_cells=5, warp_amp=110, lines=((0.5, 0.8),), net=0.5):
    """Veines de marbre raccordables : réseau de fractures recousues (bords de cellules déformés,
    dentelés, visibles par endroits) et lignes de niveau d'un bruit tordu ; épaisseur et opacité
    varient le long des veines. lines : (niveau, épaisseur en px). Renvoie (veines, halo)."""
    wx = tn(R, S, (2, 4, 8, 16), 0.55)
    wy = tn(R, S, (2, 4, 8, 16), 0.55)
    jx = (tn(R, S, (32, 64, 128, 256), 0.7) - 0.5) * 7
    jy = (tn(R, S, (32, 64, 128, 256), 0.7) - 0.5) * 7
    wv = tn(R, S, (8, 16, 32, 64), 0.6)
    op = smooth(0.25, 0.7, tn(R, S, (4, 8, 16, 32), 0.6))
    _, e1, _, _, _ = worley(R, S, n_cells, 0.9)
    e1 = warp(e1, (wx - 0.5) * warp_amp + jx, (wy - 0.5) * warp_amp + jy)
    w1 = 0.3 + 1.7 * smooth(0.45, 0.9, wv) ** 2
    vis = smooth(1 - net - 0.05, 1 - net + 0.05, tn(R, S, (2, 4, 8, 16), 0.6))
    netv = np.exp(-(e1 / w1) ** 2) * vis * (0.35 + 0.65 * op)
    _, e2, _, _, _ = worley(R, S, n_cells * 2 + 3, 0.9)
    e2 = warp(e2, (wy - 0.5) * warp_amp * 0.6 + jy, (wx - 0.5) * warp_amp * 0.6 + jx)
    netv2 = np.exp(-(e2 / 0.45) ** 2) * smooth(0.55, 0.62, tn(R, S, (4, 8, 16), 0.6)) * 0.55
    f = tn(R, S, (2, 4, 8, 16, 32), 0.55)
    f = warp(f, (wy - 0.5) * warp_amp * 1.5 + jx * 1.5, (wx - 0.5) * warp_amp * 1.5 + jy * 1.5)
    lv = np.zeros((S, S), np.float32)
    for val, w in lines:
        lv = np.maximum(lv, iso_lines(f, val, w * (0.5 + 1.0 * wv)) * (0.45 + 0.55 * op))
    thin = np.clip(np.maximum(np.maximum(netv, netv2), lv), 0, 1)
    halo = np.clip(gblur(thin, 2.5) * 1.6, 0, 1)
    return thin, halo


def marbre_rouge():
    """Marbre rouge poli (façon Rouge du Languedoc) : fond rouge sang tirant au lie-de-vin,
    nuées plus claires ou plus sombres, réseau de veines blanches et grises fines et dentelées,
    quelques-unes plus larges et laiteuses ; très lisse."""
    S = 1024
    R = rng(7104)
    cl = tn(R, S, (2, 4, 8, 16, 32, 64), 0.62)
    cl2 = tn(R, S, (4, 8, 16, 32), 0.6)
    fine = tn(R, S, (64, 128, 256, 512), 0.7)
    thin, halo = _veins(R, S, 6, 120, ((0.5, 0.9),), 0.62)
    milky, mh = _veins(R, S, 3, 160, ((0.55, 2.6),), 0.3)
    col = mix(C(0.42, 0.11, 0.1), C(0.6, 0.2, 0.15), cl)
    col = mix(col, C(0.33, 0.09, 0.1), smooth(0.6, 0.8, cl2) * 0.6)
    col = mix(col, C(0.64, 0.33, 0.28), smooth(0.72, 0.92, cl) * 0.35)
    col = col * (0.95 + 0.08 * fine[..., None])
    col = mix(col, C(0.68, 0.42, 0.37), np.clip(halo * 0.25 + mh * 0.2, 0, 1))
    col = mix(col, C(0.82, 0.74, 0.7), milky * 0.45)
    col = mix(col, C(0.9, 0.87, 0.82) * (0.92 + 0.1 * fine[..., None]), thin * 0.9)
    h = cl * 0.04 + thin * 0.006 + fine * 0.01
    col = bake(col, h, 2.0, k=0.1)
    save_surface("marbre_rouge", col, h, 1.5)


def marbre_noir():
    """Marbre noir veiné d'or (façon Portor) : fond noir profond aux nuées gris-brun, veines
    jaune d'or à crème, fines et dentelées, qui courent en faisceaux à peu près parallèles, se
    divisent et se rejoignent, bordées d'un liseré brun ; poli."""
    S = 1024
    R = rng(7105)
    cl = tn(R, S, (2, 4, 8, 16, 32, 64), 0.62)
    fine = tn(R, S, (64, 128, 256, 512), 0.7)
    wx = tn(R, S, (2, 4, 8), 0.55)
    wy = tn(R, S, (2, 4, 8), 0.55)
    jx = (tn(R, S, (32, 64, 128, 256), 0.7) - 0.5) * 6
    f = tn(R, S, (2, 4, 8, 16, 32), 0.55, oy=(1, 2, 4, 8, 16))
    f = warp(f, (wx - 0.5) * 220 + jx, (wy - 0.5) * 120 + jx)
    wv = tn(R, S, (8, 16, 32, 64), 0.6)
    op = smooth(0.25, 0.7, tn(R, S, (4, 8, 16, 32), 0.6))
    thin = np.zeros((S, S), np.float32)
    for val, w in ((0.33, 0.6), (0.41, 0.8), (0.47, 1.7), (0.52, 0.5), (0.58, 0.7), (0.66, 1.0)):
        vis = smooth(0.35, 0.55, tn(R, S, (2, 4, 8), 0.6))
        thin = np.maximum(thin, iso_lines(f, val, w * (0.5 + 1.0 * wv)) * vis * (0.4 + 0.6 * op))
    net, _ = _veins(R, S, 6, 90, ((0.5, 0.5),), 0.35)
    thin = np.clip(np.maximum(thin, net * 0.7), 0, 1)
    halo = np.clip(gblur(thin, 2.5) * 1.6, 0, 1)
    col = mix(C(0.1, 0.095, 0.09), C(0.17, 0.16, 0.15), cl) * (0.92 + 0.12 * fine[..., None])
    col = mix(col, C(0.26, 0.19, 0.1), halo * 0.45)
    gold = mix(C(0.72, 0.53, 0.22), C(0.86, 0.75, 0.48), tn(R, S, (8, 16, 32, 64), 0.6))
    col = mix(col, gold, thin * 0.95)
    h = cl * 0.04 + thin * 0.006 + fine * 0.01
    col = bake(col, h, 2.0, k=0.1)
    save_surface("marbre_noir", col * 1.28, h, 1.5)


def ardoise():
    """Toit d'ardoises en écailles : rangs décalés d'une demi-ardoise, bas arrondis, chaque rang
    couvrant la tête du rang de dessous (ombre sous chaque bord) ; ardoises gris-bleu à
    gris-violet, un peu de travers, feuilletage fin, arêtes ébréchées ; rouille de pyrite,
    rares lichens et un peu de mousse dans les creux des écailles."""
    S = 1024
    R = rng(7106)
    nr, nc = 16, 8
    bid, db, u, rr, cc = roof_rows(R, S, nr, nc, lambda u: 1 - np.sqrt(np.clip(1 - u * u, 0, 1)), 30.0, 1.2)
    rh = S / nr
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    tone = per_id(bid, R, 0.85, 1.14)
    hue = per_id(bid, R, 0.0, 1.0)
    tx = per_id(bid, R, -0.05, 0.05)
    side = (1 - np.abs(u)) * S / nc * 0.5
    gap = 1 - smooth(0.4, 1.6, side)
    chip = tn(R, S, (32, 64, 128), 0.7)
    edge = db - np.clip(chip - 0.66, 0, 1) * 10
    face = smooth(0.0, 2.5, edge)
    slope = np.clip(db / (rh * 1.7), 0, 1)
    h = 0.75 - 0.3 * slope + u * tx + mot * 0.04 + fine * 0.02
    h = h * face + (1 - face) * (0.55 - 0.3 * slope)
    h = h - gap * 0.3
    cleave = tn(R, S, (64, 128, 256, 512), 0.7, oy=(8, 16, 32, 64))
    h = h + cleave * 0.03
    base = mix(C(0.27, 0.29, 0.32), C(0.3, 0.27, 0.3), hue)
    base = mix(base, C(0.28, 0.3, 0.28), smooth(0.85, 1.0, hue))
    col = base * tone[..., None] * (0.88 + 0.22 * mot[..., None]) * (0.88 + 0.22 * fine[..., None]) * (0.94 + 0.1 * cleave[..., None])
    rust = smooth(0.8, 0.86, tn(R, S, (32, 64, 128), 0.6)) * smooth(0.5, 0.6, fine)
    col = mix(col, C(0.4, 0.27, 0.18), rust * 0.4)
    li = speck(R, S, 0.0004, 2.2) * smooth(0.55, 0.7, tn(R, S, (4, 8, 16), 0.6))
    col = mix(col, C(0.6, 0.62, 0.56), np.clip(li * 1.5, 0, 1) * 0.5)
    lo = speck(R, S, 0.00025, 1.8) * smooth(0.6, 0.72, tn(R, S, (4, 8, 16), 0.6))
    col = mix(col, C(0.66, 0.46, 0.22), np.clip(lo * 1.5, 0, 1) * 0.5)
    streak = smooth(0.62, 0.85, tn(R, S, (32, 64, 128, 256), 0.65, oy=(2, 4, 8, 16)))
    col = col * (1 - 0.15 * streak[..., None])
    crev = smooth(8.0, 0.0, db) * smooth(0.55, 1.0, np.abs(u))
    moss = crev * smooth(0.62, 0.72, tn(R, S, (16, 32, 64), 0.6))
    col = mix(col, C(0.17, 0.2, 0.09) * (0.8 + 0.4 * fine[..., None]), moss * 0.7)
    col = col * (1 - 0.6 * gap[..., None])
    sh = hshadow(h, 6.0, 12, 0.8)
    col = col * (1 - 0.4 * sh[..., None])
    col = bake(col, h, 4.0, k=0.3, ao=0.35, ao_r=4)
    save_surface("ardoise", col, h, 5.0)


def tuiles_rouges():
    """Toit de tuiles plates en terre cuite rouge sombre : rangs décalés d'une demi-tuile, coins
    du bas arrondis, chaque tuile un peu bombée et de travers ; teintes de cuisson variées (rouge,
    brun, quelques tuiles noircies), parement sablé ; lichens, coulures, mousse dans les joints."""
    S = 1024
    R = rng(7107)
    nr, nc = 14, 10

    def corner(u):
        k = 0.18
        t = np.clip((np.abs(u) - (1 - k)) / k, 0, 1)
        return 1 - np.sqrt(np.clip(1 - t * t, 0, 1))
    bid, db, u, rr, cc = roof_rows(R, S, nr, nc, corner, 12.0, 1.0)
    rh = S / nr
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    gr = grain(R, S, 0.6)
    tone = per_id(bid, R, 0.84, 1.14)
    hue = per_id(bid, R, 0.0, 1.0)
    tx = per_id(bid, R, -0.04, 0.04)
    side = (1 - np.abs(u)) * S / nc * 0.5
    gap = 1 - smooth(0.6, 2.2, side)
    edge = db
    face = smooth(0.0, 2.5, edge)
    slope = np.clip(db / (rh * 1.8), 0, 1)
    camber = 1 - u * u
    h = 0.72 - 0.28 * slope + u * tx + camber * 0.08 + mot * 0.04 + fine * 0.02 + gr * 0.015
    h = h * face + (1 - face) * (0.5 - 0.28 * slope)
    h = h - gap * 0.3
    base = np.where((hue < 0.45)[..., None], C(0.46, 0.2, 0.14), np.where((hue < 0.75)[..., None], C(0.41, 0.22, 0.16),
                    np.where((hue < 0.9)[..., None], C(0.52, 0.25, 0.16), C(0.28, 0.15, 0.12))))
    col = base * tone[..., None] * (0.86 + 0.24 * mot[..., None]) * (0.84 + 0.3 * gr[..., None]) * (0.92 + 0.14 * fine[..., None])
    bot = smooth(30.0, 0.0, db)
    col = col * (1 - 0.12 * bot[..., None])
    li = speck(R, S, 0.0005, 2.4) * smooth(0.5, 0.7, tn(R, S, (4, 8, 16), 0.6))
    col = mix(col, C(0.62, 0.62, 0.55), np.clip(li * 1.5, 0, 1) * 0.5)
    lo = speck(R, S, 0.0003, 2.0) * smooth(0.55, 0.7, tn(R, S, (4, 8, 16), 0.6))
    col = mix(col, C(0.7, 0.48, 0.2), np.clip(lo * 1.5, 0, 1) * 0.45)
    bl = smooth(0.7, 0.8, tn(R, S, (16, 32, 64), 0.6)) * smooth(0.5, 0.6, fine)
    col = mix(col, C(0.14, 0.12, 0.11), bl * 0.25)
    streak = smooth(0.6, 0.85, tn(R, S, (32, 64, 128, 256), 0.65, oy=(2, 4, 8, 16)))
    col = col * (1 - 0.15 * streak[..., None])
    crev = smooth(8.0, 0.0, db) + gap
    moss = np.clip(crev, 0, 1) * smooth(0.62, 0.72, tn(R, S, (16, 32, 64), 0.6))
    col = mix(col, C(0.17, 0.2, 0.09) * (0.8 + 0.4 * fine[..., None]), moss * 0.65)
    col = col * (1 - 0.55 * gap[..., None])
    sh = hshadow(h, 6.0, 12, 0.8)
    col = col * (1 - 0.4 * sh[..., None])
    col = bake(col, h, 4.0, k=0.3, ao=0.35, ao_r=4)
    save_surface("tuiles_rouges", col, h, 5.0)


def cuivre_vert():
    """Toit de cuivre à joints debout : bandes de 50 cm, agrafures transversales décalées,
    tôle un peu gondolée ; patine vert-de-gris turquoise, plus claire au soleil, coulures
    sombres (brun-noir) sous les agrafures et le long des joints, le cuivre brun qui reparaît
    par endroits."""
    S = 1024
    R = rng(7108)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    npan = 6
    pw = S / npan
    pi_ = np.floor(xx / pw).astype(np.int32)
    lx = xx - pi_ * pw
    dseam = np.minimum(lx, pw - lx)
    seam = np.exp(-(dseam / 4.5) ** 2)
    off = R.uniform(0, S, npan)
    cs = np.mod(yy + off[pi_], S / 2)
    dcs = np.minimum(cs, S / 2 - cs)
    cross = np.exp(-(dcs / 1.5) ** 2) * (1 - seam)
    below_cs = cs
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    oil = tn(R, S, (6, 12, 24), 0.6) * smooth(4.0, 20.0, dseam)
    h = seam * 1.6 + oil * 0.12 + cross * 0.05 + np.where(cs < 3.0, 0.03, 0.0) + fine * 0.01
    pat = mix(C(0.34, 0.56, 0.48), C(0.45, 0.66, 0.58), mot)
    pat = mix(pat, C(0.28, 0.46, 0.4), smooth(0.6, 0.85, tn(R, S, (8, 16, 32), 0.6)) * 0.6)
    pat = mix(pat, C(0.55, 0.7, 0.64), smooth(0.65, 0.85, tn(R, S, (8, 16, 32, 64), 0.6)) * 0.4)
    pat = pat * (0.9 + 0.2 * fine[..., None]) * (0.95 + 0.1 * grain(R, S, 0.7)[..., None])
    stk = tn(R, S, (32, 64, 128, 256), 0.65, oy=(2, 4, 8, 16))
    run = np.exp(-below_cs / (40 + 160 * stk)) * smooth(0.45, 0.75, tn(R, S, (16, 32, 64, 128), 0.6, oy=(2, 4, 8, 16)))
    run = run + np.exp(-(dseam / 9.0) ** 2) * smooth(0.5, 0.8, stk) * 0.6
    dark = smooth(0.55, 0.85, tn(R, S, (16, 32, 64, 128, 256), 0.65, oy=(2, 4, 8, 16, 32)))
    stre = np.clip(run + dark * 0.6, 0, 1)
    col = mix(pat, C(0.19, 0.21, 0.17) * (0.85 + 0.3 * fine[..., None]), stre * 0.65)
    cu = np.clip(smooth(0.82, 0.9, tn(R, S, (32, 64, 128), 0.6)) * smooth(0.45, 0.6, fine) + seam * 0.35 * smooth(0.5, 0.7, stk), 0, 1)
    col = mix(col, C(0.4, 0.27, 0.18) * (0.85 + 0.3 * fine[..., None]), cu * 0.55)
    col = col * (1 - 0.25 * cross[..., None])
    col = col * (1 + 0.12 * seam[..., None])
    sh = hshadow(h, 5.0, 10, 0.8)
    col = col * (1 - 0.3 * sh[..., None])
    col = bake(col, h, 5.0, k=0.35, ao=0.25, ao_r=4)
    save_surface("cuivre_vert", col, h, 5.0)


def bois_brule():
    """Planches carbonisées (façon bois brûlé) : huit planches verticales, joints sombres, clous
    rouillés ; le charbon se fend en écailles allongées dans le fil (« peau de crocodile »),
    crevasses profondes, dessus des écailles arrondis au lustre gris argenté ; deux planches
    moins brûlées, brun très sombre, au fil apparent."""
    S = 1024
    R = rng(7109)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    npl = 8
    pw = S / npl
    pi_ = np.floor(xx / pw).astype(np.int32)
    lx = xx - pi_ * pw
    dgap = np.minimum(lx, pw - lx)
    gap = 1 - smooth(1.2, 2.8, dgap)
    burn = np.array([1, 1, 0.45, 1, 1, 1, 0.5, 1], np.float32)[np.array(R.permutation(npl))][pi_]
    gx_ = tn(R, S, (32, 64, 128, 256, 512), 0.7, oy=(2, 4, 8, 16, 32))
    grain_ = np.sin((xx / pw * 9 + gx_ * 6 + tn(R, S, (8, 16, 32), 0.6, oy=(1, 2, 4)) * 4) * TAU) * 0.5 + 0.5
    d1, edge, cid, _, dy = worley_xy(R, S, S, 96, 30, 0.9, 3, 1)
    jx = (tn(R, S, (64, 128, 256), 0.7) - 0.5) * 2.5
    edge = warp(edge, jx, jx * 0.5)
    cidw = warp_nn(cid, jx, jx * 0.5)
    ch_w = 0.35 + 0.8 * tn(R, S, (8, 16, 32), 0.6)
    crack = (1 - smooth(ch_w * 0.4, ch_w + 0.6, edge)) * smooth(0.25, 0.6, burn)
    scale = smooth(0.0, 2.5, edge) ** 0.5
    cell_h = per_id(cidw, R, 0.85, 1.0)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    mot = tn(R, S, (4, 8, 16, 32), 0.6)
    char = mix(C(0.18, 0.175, 0.17), C(0.23, 0.22, 0.215), per_id(cidw, R, 0, 1)) * (0.85 + 0.3 * fine[..., None])
    char = char * (0.78 + 0.28 * scale[..., None]) * (0.9 + 0.2 * gx_[..., None])
    wood = mix(C(0.2, 0.13, 0.09), C(0.3, 0.2, 0.13), grain_) * (0.85 + 0.3 * fine[..., None]) * (0.9 + 0.2 * mot[..., None])
    b = smooth(0.4, 0.9, burn)[..., None]
    col = wood * (1 - b) + char * b
    col = mix(col, C(0.03, 0.028, 0.027), crack * 0.95)
    col = col * (1 - 0.8 * gap[..., None])
    h = (scale * cell_h * 0.35 - crack * 0.3) * smooth(0.4, 0.9, burn) + grain_ * 0.08 * (1 - smooth(0.4, 0.9, burn)) \
        + gx_ * 0.1 + fine * 0.04 - gap * 0.5
    img = to_img(col)
    d = ImageDraw.Draw(img)
    hm = Image.fromarray((np.clip(h * 0.7 + 0.3, 0, 1) * 255).astype(np.uint8))
    dh = ImageDraw.Draw(hm)
    for p in range(npl):
        for ny_ in (R.uniform(60, 200), R.uniform(560, 700)):
            for sx in (-1, 1):
                x = p * pw + pw / 2 + sx * pw * 0.28
                rr_ = 4.5
                d.ellipse((x - rr_ - 2, ny_ - rr_ - 2, x + rr_ + 2, ny_ + rr_ + 2), fill=(70, 34, 18))
                d.ellipse((x - rr_, ny_ - rr_, x + rr_, ny_ + rr_), fill=(46, 40, 38))
                d.ellipse((x - rr_ + 1.5, ny_ - rr_ + 1.5, x, ny_), fill=(78, 70, 66))
                dh.ellipse((x - rr_, ny_ - rr_, x + rr_, ny_ + rr_), fill=235)
                for k in range(int(R.integers(0, 3))):
                    L = R.uniform(10, 40)
                    d.line([(x + R.uniform(-2, 2), ny_ + rr_), (x + R.uniform(-3, 3), ny_ + rr_ + L)], fill=(64, 34, 20), width=2)
    col = from_img(img)
    h = np.asarray(hm, np.float32) / 255.0
    sh = hshadow(h, 5.0, 10, 0.8)
    col = col * (1 - 0.3 * sh[..., None])
    col = bake(col, h, 4.0, k=0.35, ao=0.3, ao_r=3)
    gx, gy = grads(gblur(h, 1.0))
    sheen = np.clip(-(gx * -0.45 + gy * -0.6) * 20, 0, 1) * scale * smooth(0.6, 0.9, burn)
    col = col + (sheen * 0.1)[..., None] * C(0.85, 0.88, 0.95)
    save_surface("bois_brule", col * 1.13, h, 5.0)


def fer_forge():
    """Fer forgé martelé sombre : la surface est faite des empreintes du marteau, cuvettes peu
    profondes qui se recoupent en arêtes ; arêtes polies plus claires, calamine bleu-noir par
    plaques, piqûres ; rouille orangée au fond de quelques cuvettes et en coulées."""
    S = 1024
    R = rng(7110)
    wx = tn(R, S, (8, 16, 32), 0.6)
    wy = tn(R, S, (8, 16, 32), 0.6)
    ax, ay = (wx - 0.5) * 10, (wy - 0.5) * 10
    d1, e1, c1, _, _ = worley(R, S, 34, 0.95)
    d2, e2, c2, _, _ = worley(R, S, 58, 0.95)
    r1, r2 = S / 34 * 0.75, S / 58 * 0.75
    k1 = warp(per_id(c1, R, 0.7, 1.3), ax, ay)
    b1 = warp(d1, ax, ay) ** 2 / (r1 * r1) * k1
    b2 = warp(d2, ay, ax) ** 2 / (r2 * r2) * warp(per_id(c2, R, 0.7, 1.3), ay, ax) + 0.25
    h0 = np.minimum(b1, b2)
    h = -np.clip(1.3 - h0, 0, 1.3) * 0.5
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    h = h + fine * 0.03 + mot * 0.08
    ridge = smooth(0.7, 1.2, h0)
    col = mix(C(0.25, 0.255, 0.265), C(0.3, 0.3, 0.31), mot) * (0.88 + 0.24 * fine[..., None])
    col = col * (0.88 + 0.22 * ridge[..., None])
    scale_ = smooth(0.55, 0.75, tn(R, S, (8, 16, 32, 64), 0.6))
    col = mix(col, C(0.19, 0.2, 0.24), scale_ * 0.6)
    pits = speck(R, S, 0.003, 0.7)
    col = col * (1 - 0.35 * pits[..., None])
    rust_n = tn(R, S, (8, 16, 32, 64, 128), 0.6)
    low = 1 - smooth(0.2, 0.9, h0)
    rust_f = tn(R, S, (32, 64, 128, 256), 0.6)
    rust = smooth(0.66, 0.74, rust_n) * smooth(0.6, 0.85, low) * smooth(0.45, 0.6, rust_f) + smooth(0.8, 0.86, rust_f) * smooth(0.5, 0.65, rust_n)
    run = smooth(0.7, 0.88, tn(R, S, (32, 64, 128), 0.65, oy=(2, 4, 8))) * smooth(0.58, 0.7, rust_n)
    rust = np.clip(rust + run * 0.6, 0, 1)
    rc = mix(C(0.36, 0.17, 0.09), C(0.5, 0.27, 0.12), fine) * (0.85 + 0.3 * grain(R, S, 0.8)[..., None])
    col = mix(col, rc, rust * 0.75)
    h = h + rust * 0.03 - pits * 0.05
    col = bake(col, h, 6.0, k=0.35, ao=0.25, ao_r=4)
    gx, gy = grads(gblur(h, 0.8))
    sheen = np.clip(-(gx * -0.45 + gy * -0.6) * 28, 0, 1) ** 2 * (1 - rust)
    col = col + (sheen * 0.08)[..., None] * C(0.9, 0.92, 1.0)
    save_surface("fer_forge", col, h, 6.0)


def dalles_palais():
    """Dallage du palais : damier de grandes dalles de marbre poli (75 cm), noir veiné de blanc
    et rouge sombre veiné de crème, chaque dalle taillée ailleurs dans le bloc (veines qui ne se
    suivent pas) ; filets de laiton doré incrustés entre les dalles ; poli, à peine terni sur
    les passages, fines rayures."""
    S = 1024
    R = rng(7111)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    n = 4
    sq = S // n
    ix = (xx // sq).astype(np.int32)
    iy = (yy // sq).astype(np.int32)
    lx = xx - ix * sq
    ly = yy - iy * sq
    dl = np.minimum(np.minimum(lx, sq - lx), np.minimum(ly, sq - ly))
    cl = tn(R, S, (2, 4, 8, 16, 32), 0.62)
    cl2 = tn(R, S, (4, 8, 16, 32), 0.6)
    fine = tn(R, S, (64, 128, 256, 512), 0.7)
    thin_b, wide_b = _veins(R, S, 5, 100, ((0.5, 0.7), (0.6, 0.5)), 0.5)
    thin_r, wide_r = _veins(R, S, 5, 120, ((0.45, 0.8), (0.62, 0.6)), 0.55)
    black = mix(C(0.07, 0.068, 0.068), C(0.13, 0.125, 0.12), cl) * (0.94 + 0.1 * fine[..., None])
    black = mix(black, C(0.2, 0.2, 0.2), wide_b * 0.2)
    black = mix(black, C(0.78, 0.77, 0.75), thin_b * 0.8)
    redm = mix(C(0.3, 0.07, 0.07), C(0.44, 0.12, 0.1), cl2) * (0.94 + 0.1 * fine[..., None])
    redm = mix(redm, C(0.5, 0.28, 0.25), wide_r * 0.2)
    redm = mix(redm, C(0.86, 0.8, 0.7), thin_r * 0.85)
    col = np.zeros((S, S, 3), np.float32)
    tilt = np.zeros((S, S), np.float32)
    for j in range(n):
        for i in range(n):
            src = black if (i + j) % 2 == 0 else redm
            k = int(R.integers(0, 4))
            fld = np.rot90(src, k)
            fld = np.roll(fld, (int(R.integers(0, S)), int(R.integers(0, S))), (0, 1))
            sl = (slice(j * sq, (j + 1) * sq), slice(i * sq, (i + 1) * sq))
            col[sl] = fld[sl] * R.uniform(0.92, 1.08)
            a, b = R.uniform(-0.00012, 0.00012, 2)
            tilt[sl] = (lx[sl] - sq / 2) * a + (ly[sl] - sq / 2) * b
    inlay = 1 - smooth(2.6, 3.6, dl)
    joint = np.exp(-((dl - 3.4) / 0.6) ** 2)
    goldc = mix(C(0.66, 0.5, 0.24), C(0.8, 0.64, 0.33), tn(R, S, (16, 32, 64, 128), 0.6)) * (0.9 + 0.2 * fine[..., None])
    col = mix(col, goldc, inlay)
    col = col * (1 - 0.5 * joint[..., None])
    wear = smooth(0.55, 0.8, tn(R, S, (2, 4, 8), 0.6))
    col = mix(col, col * 1.08 + 0.02, wear * 0.4 * (1 - inlay)[..., None][..., 0])
    scr = np.zeros((S, S), np.float32)
    img = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(img)
    for _ in range(900):
        x, y = R.random(2) * S
        a = R.uniform(0, TAU)
        L = R.uniform(10, 60)
        for ox, oy in offs(x, y, L, S):
            d.line([(x + ox, y + oy), (x + ox + math.cos(a) * L, y + oy + math.sin(a) * L)], fill=int(R.uniform(40, 120)), width=1)
    scr = np.asarray(img, np.float32) / 255.0 * smooth(0.4, 0.8, wear + 0.2)
    col = col + (scr * 0.05)[..., None]
    h = tilt + inlay * 0.01 - joint * 0.06 + fine * 0.002
    col = bake(col, h, 2.0, k=0.15, ao=0.15, ao_r=2)
    save_surface("dalles_palais", col * 1.16, h, 3.0)


def mosaique_feu():
    """Mosaïque de la Grand-Place : une rosace soleil-flammes en tesselles de pierre et d'émail
    (rouge, orange, or, noir), posées en anneaux autour du soleil et en rangs droits ailleurs,
    petites fleurs de feu aux coins (qui en se raccordant forment une rosace secondaire) ;
    joints de mortier sali, tesselles un peu bombées, usées, quelques-unes manquantes."""
    S = 1024
    R = rng(7112)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    ts = 11.6
    pal = np.array([(0.11, 0.1, 0.1), (0.34, 0.08, 0.06), (0.62, 0.13, 0.08), (0.85, 0.4, 0.09), (0.8, 0.62, 0.24),
                    (0.17, 0.155, 0.145)], np.float32)
    # 0 noir, 1 rouge sombre, 2 rouge, 3 orange, 4 or, 5 fond (noir-gris)

    def pattern_main(r, th):
        out = np.full(r.shape, 5, np.int32)
        out = np.where(r < 404, 0, out)
        out = np.where((r >= 390) & (r < 404), 4, out)
        wave = 360 + 22 * (0.5 + 0.5 * np.sin(th * 24))
        out = np.where((r >= 356) & (r < 390), np.where(r < wave + 4, 2, 1), out)
        out = np.where((r >= 340) & (r < 356), 4, out)
        # flammes
        nf = 12
        fl = np.zeros(r.shape, np.float32)
        lay = np.zeros(r.shape, np.float32)
        for k in range(nf):
            long_ = k % 2 == 0
            r0, r1 = 82.0, (326.0 if long_ else 248.0)
            t = np.clip((r - r0) / (r1 - r0), 0, 1)
            thc = k / nf * TAU + (0.12 if long_ else 0.09) * np.sin(t * math.pi * 1.3 + k)
            dth = np.mod(th - thc + math.pi, TAU) - math.pi
            w = (0.2 if long_ else 0.15) * (1 - t) ** 0.9 * (0.75 + 0.6 * np.sin(np.clip(t, 0, 1) * math.pi) ** 0.6)
            q = np.abs(dth) / np.maximum(w, 1e-4)
            inside = (r >= r0) & (r < r1) & (q < 1)
            fl = np.where(inside, 1, fl)
            lay = np.where(inside, np.maximum(lay, 1 - q * 0.9 - t * 0.35), lay)
        fcol = np.where(lay > 0.62, 4, np.where(lay > 0.36, 3, 2))
        out = np.where((r >= 82) & (r < 340) & (fl > 0), fcol, out)
        out = np.where((r >= 74) & (r < 82), 0, out)
        out = np.where((r >= 56) & (r < 74), 3, out)
        out = np.where(r < 56, 4, out)
        out = np.where((r < 56) & (np.abs(np.mod(th * 8 / TAU, 1) - 0.5) < 0.08) & (r > 26), 3, out)
        return out

    def pattern_corner(r, th):
        out = np.full(r.shape, 5, np.int32)
        out = np.where(r < 120, 0, out)
        out = np.where((r >= 108) & (r < 120), 4, out)
        petal = 0.5 + 0.5 * np.cos(th * 8)
        rp = 28 + 72 * petal ** 0.8
        out = np.where((r < rp) & (r >= 26), np.where(r < rp - 14, 3, 2), out)
        out = np.where(r < 26, 4, out)
        out = np.where(r < 12, 2, out)
        return out
    # tesselles : anneaux autour du centre et des coins, rangs droits ailleurs
    cx0 = cy0 = S / 2
    dxm, dym = xx - cx0, yy - cy0
    rm = np.hypot(dxm, dym)
    dxc = np.mod(xx + S / 2, S) - S / 2
    dyc = np.mod(yy + S / 2, S) - S / 2
    rc_ = np.hypot(dxc, dyc)
    zone = np.where(rm < 405, 1, np.where(rc_ < 121, 2, 0))
    cell_id = np.zeros((S, S), np.int64)
    e = np.zeros((S, S), np.float32)
    ccx = np.zeros((S, S), np.float32)
    ccy = np.zeros((S, S), np.float32)
    for z, (dx_, dy_, r_, ox_, oy_) in ((1, (dxm, dym, rm, cx0, cy0)), (2, (dxc, dyc, rc_, 0.0, 0.0))):
        th = np.mod(np.arctan2(dy_, dx_), TAU)
        ri = np.floor(r_ / ts).astype(np.int32)
        rmid = (ri + 0.5) * ts
        nseg = np.maximum(6, np.round(TAU * rmid / ts)).astype(np.int32)
        rot = (ri * 0.618) % 1.0
        a = th / TAU * nseg + rot
        ai = np.floor(a).astype(np.int32)
        thm = (ai + 0.5 - rot) / nseg * TAU
        er = ts / 2 - np.abs(r_ - rmid)
        et = (0.5 - np.abs(a - ai - 0.5)) * TAU / nseg * rmid
        m = zone == z
        cell_id = np.where(m, z * 10 ** 9 + ri * 10 ** 5 + np.mod(ai, nseg), cell_id)
        e = np.where(m, np.minimum(er, et), e)
        ccx = np.where(m, ox_ + np.cos(thm) * rmid, ccx)
        ccy = np.where(m, oy_ + np.sin(thm) * rmid, ccy)
    ng = int(round(S / ts))
    g = S / ng
    rowj = R.uniform(-1.5, 1.5, ng).astype(np.float32)
    gy_ = np.floor(yy / g).astype(np.int32)
    xs = xx + rowj[gy_ % ng]
    gx_ = np.floor(xs / g).astype(np.int32)
    m = zone == 0
    lxg = xs - gx_ * g
    lyg = yy - gy_ * g
    cell_id = np.where(m, gy_ * 1000 + np.mod(gx_, ng), cell_id)
    e = np.where(m, np.minimum(np.minimum(lxg, g - lxg), np.minimum(lyg, g - lyg)), e)
    ccx = np.where(m, (gx_ + 0.5) * g - rowj[gy_ % ng], ccx)
    ccy = np.where(m, (gy_ + 0.5) * g, ccy)
    # le motif, lu au centre de chaque tesselle
    pm = pattern_main(np.hypot(ccx - cx0, ccy - cy0), np.mod(np.arctan2(ccy - cy0, ccx - cx0), TAU))
    qx = np.mod(ccx + S / 2, S) - S / 2
    qy = np.mod(ccy + S / 2, S) - S / 2
    pc_ = pattern_corner(np.hypot(qx, qy), np.mod(np.arctan2(qy, qx), TAU))
    pidx = np.where(np.hypot(ccx - cx0, ccy - cy0) < 405, pm, np.where(np.hypot(qx, qy) < 121, pc_, 5))
    # losanges d'or au milieu des bords (entre deux rosaces)
    for mx, my in ((S / 2, 0.0), (0.0, S / 2)):
        ddx = np.abs(np.mod(ccx - mx + S / 2, S) - S / 2)
        ddy = np.abs(np.mod(ccy - my + S / 2, S) - S / 2)
        dia = ddx + ddy
        pidx = np.where((dia < 40) & (pidx == 5), np.where(dia < 22, 3, 4), pidx)
    u_, inv = np.unique(cell_id, return_inverse=True)
    inv = inv.reshape(S, S)
    nU = len(u_)
    tj = R.uniform(0.8, 1.18, nU).astype(np.float32)[inv]
    hj = R.uniform(-0.04, 0.04, (nU, 3)).astype(np.float32)[inv]
    shrink = R.uniform(0.0, 1.2, nU).astype(np.float32)[inv]
    miss = (R.random(nU) < 0.006)[inv]
    tiltx = R.uniform(-0.03, 0.03, nU).astype(np.float32)[inv]
    tilty = R.uniform(-0.03, 0.03, nU).astype(np.float32)[inv]
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    wob = tn(R, S, (64, 128, 256), 0.6)
    e2 = e - 0.8 - shrink * 0.5 - (wob - 0.5) * 1.0
    bgv = R.random(nU)[inv]
    pidx = np.where((pidx == 5) & (bgv < 0.16), 1, pidx)
    pidx = np.where((pidx == 5) & (bgv > 0.9), 0, pidx)
    col = pal[pidx] * tj[..., None] * (1 + hj) * (0.9 + 0.2 * fine[..., None])
    isgold = (pidx == 4)
    col = np.where(isgold[..., None], col * (0.92 + 0.16 * tn(R, S, (32, 64, 128), 0.6)[..., None]), col)
    face = smooth(0.0, 2.5, e2) ** 0.6
    worn = smooth(0.55, 0.85, tn(R, S, (4, 8, 16, 32), 0.6))
    col = mix(col, col * 1.1 + 0.03, worn * 0.4 * face)
    grout = C(0.34, 0.32, 0.29) * (0.75 + 0.5 * fine[..., None]) * (0.85 + 0.3 * mot[..., None])
    grout = mix(grout, C(0.16, 0.15, 0.14), smooth(0.5, 0.8, tn(R, S, (16, 32, 64), 0.6)) * 0.6)
    jm = 1 - smooth(-0.3, 0.9, e2)
    jm = np.where(miss, 1.0, jm)
    col = mix(col * (0.85 + 0.15 * face[..., None]), np.where(miss[..., None], grout * 0.8, grout), jm)
    dirt = smooth(0.6, 0.85, tn(R, S, (8, 16, 32, 64), 0.6))
    col = col * (1 - 0.15 * dirt[..., None])
    h = face * 0.5 + ((xx - ccx) * tiltx + (yy - ccy) * tilty) * 0.15 * face - jm * 0.2 - miss * 0.15 + fine * 0.02
    sh = hshadow(h, 3.0, 6, 0.5)
    col = col * (1 - 0.25 * sh[..., None])
    col = bake(col, h, 4.0, k=0.3, ao=0.3, ao_r=2)
    save_surface("mosaique_feu", col, h, 4.0)


def pierre_abyssale():
    """Roche de caverne du donjon : très sombre, rugueuse, en bosses et en écailles ; luisante
    d'humidité (reflets froids sur les bosses), suintements et coulures plus sombres, minces
    voiles de calcite blanchâtre le long des coulures, un film noir-vert dans les creux."""
    S = 1024
    R = rng(7113)
    n = tn(R, S, (4, 8, 16, 32, 64, 128, 256), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    wx = tn(R, S, (2, 4, 8, 16), 0.6)
    wy = tn(R, S, (2, 4, 8, 16), 0.6)
    ax, ay = (wx - 0.5) * 80, (wy - 0.5) * 80
    b1 = warp(tn(R, S, (4, 8, 16, 32), 0.5), ax, ay)
    b2 = warp(tn(R, S, (8, 16, 32, 64), 0.5), ay * 0.5, ax * 0.5)
    lump = (np.abs(b1 - 0.5) * 2) ** 0.7 * 0.6 + (np.abs(b2 - 0.5) * 2) ** 0.7 * 0.4
    _, e1, c1, _, _ = worley(R, S, 9, 0.9)
    e1 = warp(e1, ax * 0.4, ay * 0.4)
    flake = smooth(0.0, 6.0, e1) * warp(per_id(c1, R, 0.0, 0.4), ax * 0.4, ay * 0.4)
    rough = ridged(tn(R, S, (16, 32, 64, 128, 256, 512), 0.65))
    h = lump * 2.0 + flake * 0.4 + n * 0.4 + rough * 0.35 + fine * 0.06
    col = mix(C(0.25, 0.24, 0.235), C(0.29, 0.275, 0.26), smooth(0.3, 0.7, tn(R, S, (4, 8, 16), 0.6)))
    col = col * (0.84 + 0.32 * n[..., None]) * (0.85 + 0.3 * fine[..., None]) * (0.85 + 0.3 * rough[..., None])
    seep = smooth(0.5, 0.8, tn(R, S, (16, 32, 64, 128), 0.65, oy=(2, 4, 8, 16)))
    seep2 = smooth(0.55, 0.8, tn(R, S, (32, 64, 128, 256), 0.65, oy=(2, 4, 8, 16))) * smooth(0.4, 0.6, tn(R, S, (4, 8, 16), 0.6))
    wet = np.clip(seep * 0.7 + 0.3, 0, 1)
    col = col * (1 - 0.3 * seep[..., None])
    calc = seep2 * smooth(0.5, 0.7, fine)
    col = mix(col, C(0.5, 0.5, 0.47), calc * 0.35)
    cav = smooth(0.02, 0.12, np.clip(gblur(h, 6) - h, 0, None))
    col = mix(col, C(0.07, 0.09, 0.07), cav * 0.5)
    sh = hshadow(h, 10.0, 16, 1.5)
    col = col * (1 - 0.3 * sh[..., None])
    col = bake(col, h, 6.0, k=0.45, ao=0.35, ao_r=7)
    gx, gy = grads(gblur(h, 1.0))
    st = 6.0
    nx, ny = -gx * st, -gy * st
    inv = 1 / np.sqrt(nx * nx + ny * ny + 1)
    L = np.array(LIGHT, np.float32)
    L /= np.linalg.norm(L)
    hv = np.array([L[0], L[1], L[2] + 1.0])
    hv /= np.linalg.norm(hv)
    spec = np.clip((nx * hv[0] + ny * hv[1] + hv[2]) * inv, 0, 1) ** 40
    col = col + (spec * wet * 0.22)[..., None] * C(0.85, 0.9, 1.0)
    save_surface("pierre_abyssale", col, h, 7.0)


def glace():
    """Glace bleu-blanc : glace claire où l'on voit en profondeur (bleu plus soutenu), voiles
    laiteux ; fêlures blanches (plans de cassure qui diffusent la lumière), longues et droites ou
    en étoile, avec leurs barbules ; fines bulles d'air, en grappes et en chapelets ; un peu de
    givre poudreux, rayures de surface."""
    S = 1024
    R = rng(7114)
    n = tn(R, S, (2, 4, 8, 16, 32, 64), 0.6)
    n2 = tn(R, S, (4, 8, 16, 32, 64, 128), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    deep = smooth(0.2, 0.9, n)
    col = mix(C(0.68, 0.8, 0.88), C(0.56, 0.71, 0.82), deep)
    col = mix(col, C(0.8, 0.86, 0.9), smooth(0.55, 0.85, n2) * 0.18)
    col = col * (0.97 + 0.05 * fine[..., None])
    wx = tn(R, S, (8, 16, 32), 0.6)
    wy = tn(R, S, (8, 16, 32), 0.6)
    _, e1, _, _, _ = worley(R, S, 4, 0.95)
    e1 = warp(e1, (wx - 0.5) * 10 + (tn(R, S, (64, 128), 0.7) - 0.5) * 3, (wy - 0.5) * 10)
    cvis = smooth(0.42, 0.5, tn(R, S, (2, 4, 8), 0.6))
    crack = np.exp(-(e1 / 0.7) ** 2) * cvis
    plane = np.exp(-e1 / (3.0 + 6.0 * tn(R, S, (8, 16, 32), 0.6))) * cvis
    _, e2, _, _, _ = worley(R, S, 11, 0.95)
    e2 = warp(e2, (wy - 0.5) * 8, (wx - 0.5) * 8)
    c2 = np.exp(-(e2 / 0.5) ** 2) * smooth(0.55, 0.65, tn(R, S, (4, 8, 16), 0.6))
    feather = (np.sin(e1 * 1.4 + tn(R, S, (32, 64), 0.6) * 6) * 0.5 + 0.5) ** 10 * smooth(12.0, 2.0, e1) * cvis * smooth(0.5, 0.7, fine)
    whit = np.clip(crack + plane * 0.4 + c2 * 0.55 + feather * 0.3, 0, 1)
    col = mix(col, C(0.91, 0.95, 0.97), whit * 0.85)
    # bulles : petites, douces
    img = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(img)
    clus = tn(R, S, (4, 8, 16), 0.6)
    for _ in range(3000):
        x, y = R.random(2) * S
        if clus[int(y), int(x)] < 0.52 + R.random() * 0.15:
            continue
        r = R.uniform(0.6, 1.8) if R.random() < 0.92 else R.uniform(1.8, 3.6)
        v = int(R.uniform(120, 230))
        for ox, oy in offs(x, y, r + 2, S):
            d.ellipse((x + ox - r, y + oy - r, x + ox + r, y + oy + r), fill=v)
    for _ in range(36):
        x, y = R.random(2) * S
        a = math.pi / 2 + R.normal(0, 0.25)
        for k in range(int(R.integers(8, 28))):
            px, py = x + math.cos(a) * k * 4.0, y + math.sin(a) * k * 4.0
            r = R.uniform(0.5, 1.3)
            for ox, oy in offs(px, py, r + 2, S):
                d.ellipse((px + ox - r, py + oy - r, px + ox + r, py + oy + r), fill=int(R.uniform(110, 200)))
    bub = gblur(np.asarray(img, np.float32) / 255.0, 0.6)
    col = mix(col, C(0.95, 0.97, 0.99), bub * 0.8)
    snow = smooth(0.72, 0.84, tn(R, S, (32, 64, 128), 0.6)) * smooth(0.45, 0.6, fine)
    col = mix(col, C(0.9, 0.93, 0.95) * (0.94 + 0.08 * grain(R, S, 0.8)[..., None]), snow * 0.3)
    img2 = Image.new("L", (S, S), 0)
    d2 = ImageDraw.Draw(img2)
    for _ in range(260):
        x, y = R.random(2) * S
        a = R.uniform(0, TAU)
        L = R.uniform(20, 120)
        for ox, oy in offs(x, y, L, S):
            d2.line([(x + ox, y + oy), (x + ox + math.cos(a) * L, y + oy + math.sin(a) * L)], fill=int(R.uniform(25, 70)), width=1)
    scr = np.asarray(img2, np.float32) / 255.0
    col = col + (scr * 0.06)[..., None]
    h = n * 0.12 + n2 * 0.06 + snow * 0.06 - crack * 0.15 - c2 * 0.06 + fine * 0.015 - scr * 0.03
    col = bake(col, h, 3.0, k=0.12, ao=0.1, ao_r=3)
    col = np.minimum(col, 0.965)
    save_surface("glace", col, h, 3.0)


def givre():
    """Givre sur pierre sombre : la pierre (gris-bleu sombre, grenue) se couvre d'une gelée
    blanche granuleuse, plus épaisse par plaques, et de cristaux de givre en fougères qui
    rayonnent de quelques germes (une tige, des barbes à 60°, et leurs barbules)."""
    S = 1024
    R = rng(7115)
    n = tn(R, S, (4, 8, 16, 32, 64, 128), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    gr = grain(R, S, 0.6)
    stone = mix(C(0.24, 0.245, 0.26), C(0.3, 0.3, 0.31), n) * (0.82 + 0.36 * gr[..., None]) * (0.9 + 0.2 * fine[..., None])
    pits = speck(R, S, 0.003, 0.8)
    stone = stone * (1 - 0.35 * pits[..., None])
    hs = n * 0.3 + fine * 0.06 + gr * 0.05 - pits * 0.08
    dens = 0.45 + 0.45 * smooth(0.2, 0.8, tn(R, S, (8, 16, 32, 64), 0.6))
    rime_p = R.random((S, S)).astype(np.float32)
    rime = (rime_p < dens * 0.35).astype(np.float32)
    rime = np.clip(gblur(rime, 0.6) * 1.8, 0, 1) * (0.5 + 0.5 * dens)
    fern = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(fern)

    def branch(x, y, a, L, w, depth):
        pts = [(x, y)]
        step = 3.0
        curv = R.normal(0, 0.02)
        k = 0
        while k * step < L:
            a += curv + R.normal(0, 0.04)
            x += math.cos(a) * step
            y += math.sin(a) * step
            pts.append((x, y))
            k += 1
            if depth > 0 and k % 2 == 0 and k * step < L * 0.9:
                rem = (L - k * step) * R.uniform(0.25, 0.45)
                for sg in (-1, 1):
                    if R.random() < 0.85:
                        branch(x, y, a + sg * math.radians(60) + R.normal(0, 0.08), rem, max(1, w - 1), depth - 1)
        for ox, oy in offs(pts[0][0], pts[0][1], L + 4, S):
            d.line([(px + ox, py + oy) for px, py in pts], fill=255 if depth >= 2 else (210 if depth == 1 else 160), width=w)
    seeds = 0
    while seeds < 95:
        x, y = R.random(2) * S
        if dens[int(y), int(x)] < 0.5 and R.random() < 0.5:
            continue
        seeds += 1
        for _ in range(int(R.integers(2, 5))):
            branch(x, y, R.uniform(0, TAU), R.uniform(40, 130), 2, 2)
    fa = gblur(np.asarray(fern, np.float32) / 255.0, 0.5)
    cov = np.clip(rime * 0.8 + fa, 0, 1)
    frost = mix(C(0.78, 0.84, 0.9), C(0.9, 0.93, 0.96), fine) * (0.9 + 0.12 * gr[..., None])
    col = mix(stone, frost, cov * 0.85)
    col = mix(col, col * C(0.95, 0.98, 1.04) + 0.03, dens * 0.3)
    h = hs + cov * 0.12 + fa * 0.05
    col = bake(col, h, 4.0, k=0.25, ao=0.25, ao_r=3)
    save_surface("givre", col, h, 4.0)


def boue():
    """Boue sombre et grasse : bosses molles et luisantes, ornières, deux pistes d'empreintes de
    bottes plus ou moins nettes, quelques flaques lisses (le ciel gris s'y reflète, bord mouillé
    plus sombre) ; de la boue plus claire, sèche et fendillée sur les bosses ; cailloux, brins de
    paille."""
    S = 1024
    R = rng(7116)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    n = tn(R, S, (4, 8, 16, 32, 64, 128), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    gr = grain(R, S, 0.8)
    lumps = tn(R, S, (8, 16, 32, 64), 0.6)
    h = n * 0.6 + lumps * 0.3 + fine * 0.04
    pm = Image.new("F", (S, S), 0.0)
    d = ImageDraw.Draw(pm)
    for trail in range(2):
        x, y = R.random(2) * S
        a = R.uniform(0, TAU)
        for k in range(18):
            a += R.normal(0, 0.06)
            side = 1 if k % 2 == 0 else -1
            ca, sa = math.cos(a), math.sin(a)
            px, py = x - sa * side * 9, y + ca * side * 9
            b = a + R.normal(0, 0.08) + side * 0.08
            cb, sb = math.cos(b), math.sin(b)
            depth = R.uniform(0.4, 1.0)
            sole = [(px + cb * u_ - sb * v_ * side, py + sb * u_ + cb * v_ * side) for u_, v_ in
                    [(-6, -7), (4, -8), (11, -7), (15, -3), (15, 3), (10, 7), (2, 7), (-6, 6)]]
            heel = [(px + cb * u_ - sb * v_ * side, py + sb * u_ + cb * v_ * side) for u_, v_ in [(-24, -6), (-14, -6), (-13, 6), (-23, 6)]]
            for ox, oy in offs(px, py, 40, S):
                d.polygon([(qx + ox, qy + oy) for qx, qy in sole], fill=depth)
                d.polygon([(qx + ox, qy + oy) for qx, qy in heel], fill=depth * 0.9)
            x += ca * 64
            y += sa * 64
    prints = gblur(np.asarray(pm, np.float32), 1.8)
    rim = np.clip(gblur(prints, 4.0) * 1.5 - prints, 0, 1)
    rut_n = tn(R, S, (2, 4), 0.5)
    rp = yy / S * 2 + (rut_n - 0.5) * 1.2
    rut = np.exp(-(((rp - np.round(rp)) * S / 2) / 20.0) ** 2) * smooth(0.3, 0.6, tn(R, S, (2, 4, 8), 0.6))
    h = h - prints * 0.3 + rim * 0.1 - rut * 0.3
    hmn = h - gblur(h, 40)
    pud = smooth(0.62, 0.66, tn(R, S, (4, 8, 16, 32), 0.6) + (fine - 0.5) * 0.04) * smooth(0.02, 0.08, -hmn + 0.06)
    water = np.clip(np.maximum(pud, smooth(0.3, 0.5, prints) * smooth(0.5, 0.6, tn(R, S, (8, 16, 32), 0.6))), 0, 1)
    mud = mix(C(0.21, 0.17, 0.135), C(0.28, 0.23, 0.18), n) * (0.85 + 0.3 * gr[..., None]) * (0.9 + 0.2 * fine[..., None])
    dry = smooth(0.62, 0.8, h + (fine - 0.5) * 0.2) * smooth(0.5, 0.65, tn(R, S, (8, 16, 32), 0.6)) * (1 - water)
    _, ce, _, _, _ = worley(R, S, 40, 0.9)
    crk = (1 - smooth(0.3, 1.2, ce)) * dry
    mud = mix(mud, C(0.36, 0.32, 0.27) * (0.85 + 0.3 * gr[..., None]), dry * 0.65)
    mud = mud * (1 - 0.35 * crk[..., None])
    wetrim = np.clip(gblur(water, 3.0) * 2.0, 0, 1) * (1 - water)
    mud = mud * (1 - 0.25 * wetrim[..., None])
    refl = mix(C(0.11, 0.1, 0.09), C(0.24, 0.25, 0.27), smooth(0.2, 0.8, tn(R, S, (2, 4, 8), 0.6)))
    col = mix(mud, refl, water * 0.85)
    items = []
    for _ in range(140):
        r = R.uniform(2, 7)
        items.append((R.random() * S, R.random() * S, rock_poly(R, r, sm=1), r))
    ids = scatter(S, items)
    hn, mask = domes(ids, len(items))
    sc = np.vstack([np.zeros((1, 3), np.float32), (C(0.3, 0.28, 0.26) * R.uniform(0.7, 1.3, (len(items), 1))).astype(np.float32)])
    ma = gblur(mask.astype(np.float32), 0.5) * (1 - water)
    col = mix(col, sc[ids], ma)
    flat = gblur(h, 40) - 0.08
    h = h * (1 - water) + water * flat + hn * mask * 0.3 * (1 - water)
    img = to_img(col)
    dd = ImageDraw.Draw(img)
    for _ in range(60):
        x, y = R.random(2) * S
        a = R.uniform(0, TAU)
        L = R.uniform(10, 34)
        t = R.random()
        for ox, oy in offs(x, y, L, S):
            dd.line([(x + ox, y + oy), (x + ox + math.cos(a) * L, y + oy + math.sin(a) * L)], fill=(int(120 + 40 * t), int(100 + 30 * t), int(60 + 20 * t)), width=1)
    col = from_img(img)
    col = bake(col, h, 4.0, k=0.35, ao=0.3, ao_r=5)
    gx, gy = grads(gblur(h, 1.5))
    st = 5.0
    nx, ny = -gx * st, -gy * st
    inv = 1 / np.sqrt(nx * nx + ny * ny + 1)
    L = np.array(LIGHT, np.float32)
    L /= np.linalg.norm(L)
    hv = np.array([L[0], L[1], L[2] + 1.0])
    hv /= np.linalg.norm(hv)
    spec = np.clip((nx * hv[0] + ny * hv[1] + hv[2]) * inv, 0, 1) ** 30
    col = col + (spec * (1 - dry) * (1 - water) * 0.12)[..., None] * C(0.85, 0.88, 0.92)
    save_surface("boue", col * 1.15, h, 5.0)


def sable_arene():
    """Sable de l'arène : sable fin ocre-gris, tassé ; passes de râteau (sillons parallèles en
    larges courbes, qui se recoupent), effacées par endroits ; traces de pas et de sabots,
    piétinements plus sombres ; quelques cailloux."""
    S = 1024
    R = rng(7117)
    n = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.6)
    base = mix(C(0.58, 0.52, 0.42), C(0.64, 0.57, 0.46), n) * (0.86 + 0.28 * gr[..., None]) * (0.95 + 0.1 * fine[..., None])
    h = n * 0.15 + gr * 0.04 + fine * 0.03
    rake = Image.new("F", (S, S), -1.0)
    d = ImageDraw.Draw(rake)
    for _ in range(26):
        x, y = R.random(2) * S
        a = R.uniform(0, TAU)
        bend = R.normal(0, 0.004)
        L = R.uniform(300, 600)
        teeth = 9
        sp = 8.0
        path = []
        for k in range(int(L / 6)):
            path.append((x, y, a))
            a += bend
            x += math.cos(a) * 6
            y += math.sin(a) * 6
        for (px, py, pa) in path:
            nx_, ny_ = -math.sin(pa), math.cos(pa)
            for t in range(-teeth, teeth + 1):
                off = t * sp / 2
                val = 0.5 + 0.5 * math.cos(t * math.pi)
                qx, qy = px + nx_ * off, py + ny_ * off
                for ox, oy in offs(qx, qy, 6, S):
                    d.rectangle((qx + ox - 3, qy + oy - 3, qx + ox + 3, qy + oy + 3), fill=val)
    rk = np.asarray(rake, np.float32)
    has = rk >= 0
    rk = gblur(np.where(has, rk, 0.5).astype(np.float32), 1.6)
    hasf = gblur(has.astype(np.float32), 2.0)
    erase = smooth(0.62, 0.75, tn(R, S, (4, 8, 16, 32), 0.6))
    rmask = hasf * (1 - erase)
    h = h + (rk - 0.5) * 0.35 * rmask
    col = base * (1 + 0.06 * ((rk - 0.5) * rmask)[..., None])
    pm = Image.new("F", (S, S), 0.0)
    dp = ImageDraw.Draw(pm)
    for _ in range(5):
        x, y = R.random(2) * S
        a = R.uniform(0, TAU)
        hoof = R.random() < 0.4
        for k in range(14):
            a += R.normal(0, 0.1)
            side = 1 if k % 2 == 0 else -1
            px, py = x + math.cos(a + side * math.pi / 2) * 11, y + math.sin(a + side * math.pi / 2) * 11
            ca, sa = math.cos(a), math.sin(a)
            if hoof:
                shp = [[(px + ca * u_ - sa * v_, py + sa * u_ + ca * v_) for u_, v_ in ((-8, -2), (8, -7), (12, -1), (8, -1), (-6, 1))],
                       [(px + ca * u_ - sa * v_, py + sa * u_ + ca * v_) for u_, v_ in ((-8, 2), (8, 7), (12, 1), (8, 1), (-6, -1))]]
            else:
                shp = [[(px + ca * u_ - sa * v_, py + sa * u_ + ca * v_) for u_, v_ in
                        ((-12, -8), (4, -10), (13, -8), (16, -2), (14, 6), (5, 8), (-8, 7), (-12, 1))],
                       [(px + ca * u_ - sa * v_, py + sa * u_ + ca * v_) for u_, v_ in ((-28, -7), (-19, -7), (-18, 6), (-27, 6))]]
            for ox, oy in offs(px, py, 40, S):
                for q in shp:
                    dp.polygon([(qx + ox, qy + oy) for qx, qy in q], fill=1.0)
            x += ca * 38
            y += sa * 38
    prints = gblur(np.asarray(pm, np.float32), 1.2)
    prim = np.clip(gblur(prints, 3.0) * 1.4 - prints, 0, 1)
    scuff = smooth(0.68, 0.78, tn(R, S, (16, 32, 64), 0.6))
    h = h - prints * 0.25 + prim * 0.08 + scuff * (fine - 0.5) * 0.15
    col = mix(col, col * C(0.88, 0.86, 0.84), scuff * 0.5)
    col = col * (1 - 0.1 * prints[..., None])
    items = []
    for _ in range(160):
        r = R.uniform(1.5, 5)
        items.append((R.random() * S, R.random() * S, rock_poly(R, r, sm=1), r))
    ids = scatter(S, items)
    hn, mask = domes(ids, len(items))
    sc = np.vstack([np.zeros((1, 3), np.float32), (C(0.5, 0.46, 0.4) * R.uniform(0.6, 1.2, (len(items), 1))).astype(np.float32)])
    col = mix(col, sc[ids], gblur(mask.astype(np.float32), 0.5))
    h = h + hn * mask * 0.2
    sh = hshadow(h, 5.0, 10, 0.8)
    col = col * (1 - 0.3 * sh[..., None])
    col = bake(col, h, 4.0, k=0.35, ao=0.25, ao_r=4)
    save_surface("sable_arene", col, h, 4.5)


def bati():
    pierre_gothique()
    brique_noire()
    enduit_rouge()
    marbre_rouge()
    marbre_noir()
    ardoise()
    tuiles_rouges()
    cuivre_vert()
    bois_brule()
    fer_forge()
    dalles_palais()
    mosaique_feu()
    pierre_abyssale()
    glace()
    givre()
    boue()
    sable_arene()


# =================================================================== la palette du peintre (panneaux)

class Paint:
    """Une peinture RVB (0..1) dessinée K fois plus grand puis réduite : formes modelées (ombre
    propre d'après la silhouette, lumière en haut à gauche), contours sombres, lueurs additives,
    textes ; garde la couverture de peinture (cov) pour le vieillissement."""

    def __init__(self, W, H, K=2, bg=(0, 0, 0), seed=0):
        self.W, self.H, self.K = W, H, K
        self.w, self.h = W * K, H * K
        self.rgb = np.empty((self.h, self.w, 3), np.float32)
        self.rgb[:] = np.array(bg, np.float32) / 255.0
        self.cov = np.zeros((self.h, self.w), np.float32)
        self.ink = (38, 24, 18)
        L = np.array((-0.5, -0.65, 0.58), np.float32)
        self.L = L / np.linalg.norm(L)
        R = rng(seed + 90000)
        big = max(self.w, self.h)
        self.brush = (0.9 + 0.2 * tn(R, big, (8, 16, 32, 64, 128, 256), 0.65)[:self.h, :self.w]).astype(np.float32)

    def P(self, pts):
        return [(x * self.K, y * self.K) for x, y in pts]

    def _draw(self, fn):
        m = Image.new("L", (self.w, self.h), 0)
        fn(ImageDraw.Draw(m))
        return m

    def _field(self, col, x0, y0, x1, y1, grad):
        if grad is not None:
            c1, c2 = (np.array(c, np.float32) / 255.0 for c in grad[:2])
            ang = grad[2] if len(grad) > 2 else 90.0
            yy, xx = np.mgrid[y0:y1, x0:x1].astype(np.float32)
            ca, sa = math.cos(math.radians(ang)), math.sin(math.radians(ang))
            proj = xx * ca + yy * sa
            lo, hi = proj.min(), proj.max()
            if len(grad) > 3:
                lo, hi = grad[3][0] * self.K, grad[3][1] * self.K
            t = np.clip((proj - lo) / max(1e-3, hi - lo), 0, 1)[..., None]
            return c1 * (1 - t) + c2 * t
        if callable(col):
            yy, xx = np.mgrid[y0:y1, x0:x1].astype(np.float32)
            return col(xx / self.K, yy / self.K)
        return np.array(col, np.float32)[None, None, :] / 255.0

    def comp(self, m_img, col, alpha=1.0, shade=0.0, depth=6.0, tex=True, grad=None, add=False, cov=True):
        bb = m_img.getbbox()
        if not bb:
            return
        pad = int(depth * self.K * 2.5) + 4 if shade else 2
        x0, y0 = max(0, bb[0] - pad), max(0, bb[1] - pad)
        x1, y1 = min(self.w, bb[2] + pad), min(self.h, bb[3] + pad)
        crop = m_img.crop((x0, y0, x1, y1))
        m = np.asarray(crop, np.float32) / 255.0
        c = self._field(col, x0, y0, x1, y1, grad) * np.ones((y1 - y0, x1 - x0, 1), np.float32)
        if shade:
            hb = np.asarray(crop.filter(ImageFilter.GaussianBlur(depth * self.K)), np.float32) / 255.0
            gy, gx = np.gradient(hb)
            st = 2.2 * depth * self.K
            nx, ny = -gx * st, -gy * st
            inv = 1.0 / np.sqrt(nx * nx + ny * ny + 1.0)
            ndl = (nx * self.L[0] + ny * self.L[1] + self.L[2]) * inv
            f = np.clip(1.0 + shade * (ndl - self.L[2]) / self.L[2], 0.3, 1.7)
            c = c * f[..., None]
        if tex:
            c = c * self.brush[y0:y1, x0:x1, None]
        a = (m * alpha)[..., None]
        reg = self.rgb[y0:y1, x0:x1]
        if add:
            self.rgb[y0:y1, x0:x1] = reg + c * a
        else:
            self.rgb[y0:y1, x0:x1] = reg * (1 - a) + c * a
            if cov:
                self.cov[y0:y1, x0:x1] = np.maximum(self.cov[y0:y1, x0:x1], a[..., 0])

    def poly(self, pts, col, sm=0, shade=0.5, depth=6.0, ol=2.0, alpha=1.0, grad=None, inkc=None, tex=True):
        if sm:
            pts = chaikin(pts, sm)
        q = self.P(pts)
        self.comp(self._draw(lambda d: d.polygon(q, fill=255)), col, alpha, shade, depth, tex, grad)
        if ol:
            self.outline(pts, ol, inkc)

    def outline(self, pts, w, col=None, closed=True, alpha=0.92):
        q = self.P(pts)
        if closed:
            q = q + [q[0]]
        ww = max(1, int(round(w * self.K)))
        self.comp(self._draw(lambda d: d.line(q, fill=255, width=ww, joint="curve")), col or self.ink, alpha, tex=False)

    def ell(self, cx, cy, rx, ry, col, **kw):
        self.poly(ellp(cx, cy, rx, ry, n=64), col, **kw)

    def tubep(self, pts, w0, col, w1=None, **kw):
        self.poly(tube(pts, w0, w1), col, **kw)

    def line(self, pts, col, w, alpha=1.0, tex=False):
        q = self.P(pts)
        ww = max(1, int(round(w * self.K)))
        self.comp(self._draw(lambda d: d.line(q, fill=255, width=ww, joint="curve")), col, alpha, tex=tex)

    def glow(self, cx, cy, r, col, k=1.0, cov=False):
        x0, y0 = max(0, int((cx - 3 * r) * self.K)), max(0, int((cy - 3 * r) * self.K))
        x1, y1 = min(self.w, int((cx + 3 * r) * self.K) + 1), min(self.h, int((cy + 3 * r) * self.K) + 1)
        if x1 <= x0 or y1 <= y0:
            return
        yy, xx = np.mgrid[y0:y1, x0:x1].astype(np.float32)
        g = np.exp(-(((xx / self.K - cx) ** 2 + (yy / self.K - cy) ** 2) / (r * r)))
        self.rgb[y0:y1, x0:x1] += (np.array(col, np.float32) / 255.0)[None, None, :] * (g * k)[..., None]

    def rect(self, x0, y0, x1, y1, col, grad=None, **kw):
        self.poly([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], col, grad=grad, **kw)

    def text(self, xy, s, size, col, anchor="mm", italic=False, bold=True, stroke=0.0, stroke_col=None, shade=0.0, grad=None,
             shadow=None, alpha=1.0, spacing=0):
        f = font(size * self.K, italic=italic, bold=bold)
        x, y = xy[0] * self.K, xy[1] * self.K

        def draw_text(d, sw=0):
            if spacing:
                tw = sum(d.textlength(ch, font=f) for ch in s) + spacing * self.K * (len(s) - 1)
                cx = x - tw / 2 if anchor[0] == "m" else (x - tw if anchor[0] == "r" else x)
                for ch in s:
                    d.text((cx, y), ch, font=f, fill=255, anchor="l" + anchor[1], stroke_width=sw, stroke_fill=255)
                    cx += d.textlength(ch, font=f) + spacing * self.K
            else:
                d.text((x, y), s, font=f, fill=255, anchor=anchor, stroke_width=sw, stroke_fill=255)
        if shadow:
            dx, dy, sa = shadow
            m = self._draw(lambda d: draw_text(d, int(stroke * self.K)))
            m = ImageChops_offset(m, int(dx * self.K), int(dy * self.K)).filter(ImageFilter.GaussianBlur(self.K * 1.2))
            self.comp(m, (0, 0, 0), sa, tex=False)
        if stroke:
            self.comp(self._draw(lambda d: draw_text(d, int(stroke * self.K))), stroke_col or self.ink, alpha, tex=False)
        self.comp(self._draw(lambda d: draw_text(d)), col, alpha, shade=shade, depth=1.2, grad=grad, tex=False)

    def text_size(self, s, size, italic=False, bold=True):
        f = font(size * self.K, italic=italic, bold=bold)
        b = ImageDraw.Draw(Image.new("L", (8, 8))).textbbox((0, 0), s, font=f)
        return (b[2] - b[0]) / self.K, (b[3] - b[1]) / self.K

    def result(self):
        return down(np.clip(self.rgb, 0, 1), self.K), down(self.cov, self.K)


def ImageChops_offset(img, dx, dy):
    out = Image.new(img.mode, img.size, 0)
    out.paste(img, (dx, dy))
    return out


def stone_bg(R, W, H, base=(0.3, 0.29, 0.28), var=0.14, joints=None):
    """Fond de pierre (non raccordable) : grain, nuages, petites piqûres ; joints optionnels (masonry)."""
    big = max(W, H)
    n = tn(R, big, (4, 8, 16, 32, 64), 0.6)[:H, :W]
    f = tn(R, big, (64, 128, 256, 512), 0.75)[:H, :W]
    g = grain(R, big, 0.6)[:H, :W]
    col = np.array(base, np.float32)[None, None, :] * (1 - var + 2 * var * n[..., None]) * (0.9 + 0.2 * f[..., None]) * (0.92 + 0.16 * g[..., None])
    return col.astype(np.float32)


def arch_pts(x0, x1, ys, yb, d=0.0, n=40):
    """Contour d'une baie en arc brisé équilatéral (x0..x1, naissance de l'arc à ys, bas à yb),
    rétréci de d (arc concentrique) : de bas gauche, par le sommet, jusqu'à bas droite."""
    w = x1 - x0
    r = w - d
    xm = (x0 + x1) / 2
    a_apex = math.acos((xm - x1) / r)
    b_apex = math.acos((xm - x0) / r)
    pts = [(x0 + d, yb)]
    for k in range(n + 1):
        a = math.pi - (math.pi - a_apex) * k / n
        pts.append((x1 + math.cos(a) * r, ys - math.sin(a) * r))
    for k in range(1, n + 1):
        b = b_apex - b_apex * k / n
        pts.append((x0 + math.cos(b) * r, ys - math.sin(b) * r))
    pts.append((x1 - d, yb))
    return pts


# =================================================================== vitraux, bannière

def _glass_cells(pa, mask_img, cell, ang, R, base, var=0.22, lead=2.2, glow_c=None, glow_r=None, hue=0.06):
    """Remplit un masque de vitres en losanges (ou en carrés si ang=0) sertis de plomb."""
    m = np.asarray(mask_img, np.float32) / 255.0
    yy, xx = np.mgrid[0:pa.h, 0:pa.w].astype(np.float32) / pa.K
    if ang:
        t = math.tan(math.radians(ang))
        u = (xx + yy * t) / cell
        v = (xx - yy * t) / cell
    else:
        u = xx / cell
        v = yy / cell
    iu, iv = np.floor(u).astype(np.int32), np.floor(v).astype(np.int32)
    du = np.minimum(u - iu, 1 - (u - iu)) * cell
    dv = np.minimum(v - iv, 1 - (v - iv)) * cell
    if ang:
        du *= math.cos(math.radians(ang))
        dv *= math.cos(math.radians(ang))
    pid = (iu * 7919 + iv * 104729) % 100003
    rr = np.random.default_rng(int(R.integers(1 << 30)))
    br = rr.uniform(1 - var, 1.0, 100003).astype(np.float32)[pid]
    hu = rr.uniform(-hue, hue, (100003, 3)).astype(np.float32)[pid]
    col = np.array(base, np.float32)[None, None, :] / 255.0 * br[..., None] * (1 + hu)
    streak = tn(R, max(pa.w, pa.h), (16, 32, 64, 128), 0.6, oy=(64, 128, 256, 512))[:pa.h, :pa.w]
    col = col * (0.9 + 0.2 * streak[..., None])
    if glow_c is not None:
        g = np.exp(-(((xx - glow_c[0]) ** 2 + (yy - glow_c[1]) ** 2) / (glow_r ** 2)))
        col = col * (0.72 + 0.4 * g[..., None])
    leadm = 1 - smooth(lead * 0.5, lead * 0.5 + 0.8, np.minimum(du, dv))
    col = col * (1 - leadm[..., None]) + np.array((0.07, 0.06, 0.055), np.float32) * leadm[..., None]
    pa.rgb = pa.rgb * (1 - m[..., None]) + col * m[..., None]
    pa.cov = np.maximum(pa.cov, m)


def _masonry_wall(pa, R, base=(0.27, 0.26, 0.25), course=46, joint=(0.17, 0.16, 0.15)):
    pa.rgb[:] = stone_bg(R, pa.w, pa.h, base)
    W, H = pa.W, pa.H
    y = -R.uniform(0, course)
    k = 0
    while y < H:
        pa.line([(0, y), (W, y)], tuple(int(c * 255) for c in joint), 1.6)
        x = -R.uniform(0, 60) if k % 2 else -R.uniform(60, 120)
        while x < W:
            pa.line([(x, y), (x, y + course)], tuple(int(c * 255) for c in joint), 1.6)
            x += R.uniform(80, 130)
        y += course
        k += 1


def fenetre_gothique():
    """Une fenêtre en lancette éclairée de l'intérieur : arc brisé, ébrasement mouluré de pierre
    sombre, réseau de plombs en losanges, verres ambrés qui luisent (plus chauds vers le bas et
    le milieu, là où brûlent les chandelles), deux barlotières, appui de pierre."""
    W, H = 256, 512
    R = rng(7201)
    pa = Paint(W, H, 2, seed=7201)
    _masonry_wall(pa, R)
    x0, x1, ys, yb = 64, 192, 196, 462
    pa.poly(arch_pts(x0 - 30, x1 + 30, ys, yb + 16), (92, 88, 82), shade=0.7, depth=6, ol=1.2)
    pa.poly(arch_pts(x0 - 18, x1 + 18, ys, yb + 8), (70, 66, 62), shade=0.6, depth=4, ol=1.0)
    pa.poly(arch_pts(x0 - 8, x1 + 8, ys, yb + 2), (60, 56, 52), grad=((150, 104, 60), (84, 58, 40), 90), shade=0.4, depth=3, ol=1.0)
    gm = pa._draw(lambda d: d.polygon(pa.P(arch_pts(x0, x1, ys, yb)), fill=255))
    _glass_cells(pa, gm, 27, 58, R, (255, 180, 82), var=0.32, lead=1.5, glow_c=((x0 + x1) / 2, 340), glow_r=140)
    for yb_ in (268, 372):
        pa.line([(x0 - 2, yb_), (x1 + 2, yb_)], (24, 22, 22), 3.2)
        pa.line([(x0 - 2, yb_ - 1.0), (x1 + 2, yb_ - 1.0)], (70, 64, 60), 0.8)
    pa.rect(x0 - 40, yb + 14, x1 + 40, yb + 30, (96, 92, 86), shade=0.6, depth=3, ol=1.2)
    pa.rect(x0 - 40, yb + 30, x1 + 40, yb + 36, (30, 28, 27), shade=0, ol=0, alpha=0.7)
    pa.glow((x0 + x1) / 2, 360, 120, (90, 50, 14), 0.25)
    pa.glow((x0 + x1) / 2, yb + 20, 80, (70, 40, 12), 0.18)
    rgb, cov = pa.result()
    save_rgb(rgb, "fenetre_gothique.png")


def _flame_pts(cx, cy, w, h, lean=0.0, tongues=3, R=None):
    """Silhouette d'une flamme (base arrondie en cy, pointe en haut)."""
    pts = []
    n = 24
    for k in range(n + 1):
        t = k / n
        a = math.pi * (1 + t)
        pts.append((cx + math.cos(a) * w * 0.5, cy - math.sin(a) * w * 0.32))
    tip = (cx + lean * w, cy - h)
    pts += bez((cx + w * 0.5, cy), (cx + w * 0.55, cy - h * 0.45), (cx + w * 0.05 + lean * w * 0.5, cy - h * 0.7), tip, 14)
    pts += bez(tip, (cx - w * 0.15 + lean * w * 0.4, cy - h * 0.6), (cx - w * 0.6, cy - h * 0.35), (cx - w * 0.5, cy), 14)
    return pts


def horned_flame(pa, cx, cy, s, gold=(222, 170, 60), deep=(150, 30, 20), horn=(110, 24, 18), ol=2.0, layers=True, horn_tip=None):
    """L'emblème de Pandémonia : une flamme à trois langues entre deux cornes recourbées."""
    for sx in (-1, 1):
        ctr = bez((cx + sx * 0.3 * s, cy + 0.12 * s), (cx + sx * 0.95 * s, cy + 0.05 * s), (cx + sx * 0.95 * s, cy - 0.7 * s),
                  (cx + sx * 0.52 * s, cy - 1.0 * s), 24)
        pa.tubep(ctr, s * 0.34, horn, w1=s * 0.02, shade=0.8, depth=s * 0.07, ol=ol)
        for k in range(4, 20, 4):
            (ax, ay), (bx, by) = ctr[k - 1], ctr[k + 1]
            nx, ny = -(by - ay), bx - ax
            L = math.hypot(nx, ny) or 1
            w = s * 0.17 * (1 - k / 24)
            pa.line([(ctr[k][0] - nx / L * w, ctr[k][1] - ny / L * w), (ctr[k][0] + nx / L * w, ctr[k][1] + ny / L * w)],
                    tuple(int(c * 0.6) for c in horn), max(1.0, ol * 0.6), alpha=0.6)
        if horn_tip:
            pa.tubep(ctr[17:], s * 0.12, horn_tip, w1=s * 0.02, shade=0.6, depth=s * 0.04, ol=0)
    pa.poly(_flame_pts(cx, cy + s * 0.25, s * 0.9, s * 1.25, 0.0), gold, shade=0.8, depth=s * 0.08, ol=ol)
    for sx in (-1, 1):
        pa.poly(_flame_pts(cx + sx * s * 0.3, cy + s * 0.22, s * 0.42, s * 0.8, sx * 0.25), gold, shade=0.8, depth=s * 0.05, ol=ol)
    if layers:
        pa.poly(_flame_pts(cx, cy + s * 0.2, s * 0.5, s * 0.8, 0.0), deep, shade=0.5, depth=s * 0.05, ol=0)
        pa.poly(_flame_pts(cx, cy + s * 0.16, s * 0.24, s * 0.45, 0.0), gold, shade=0.6, depth=s * 0.03, ol=0)


def vitrail_rosace():
    """La rosace (transparente hors du cercle), vue de l'intérieur, éclairée par le jour : douze
    lancettes rayonnantes à pointe brisée, découpées par les plombs, alternativement bleu profond
    et rouge, chacune avec sa flamme d'or ; douze oculi d'or entre leurs pointes ; un remplage de
    pierre fin et sombre ; au centre, la flamme cornue de Pandémonia sur fond bleu nuit."""
    S = 512
    R = rng(7202)
    pa = Paint(S, S, 2, bg=(14, 12, 12), seed=7202)
    c = S / 2
    ink = (14, 12, 12)

    def pol(r, a):
        return (c + math.cos(a) * r, c + math.sin(a) * r)
    glass = Image.new("L", (pa.w, pa.h), 0)
    dg = ImageDraw.Draw(glass)
    dang = TAU / 12
    for k in range(12):
        a0 = k * dang + dang / 2
        half = dang / 2 - math.asin(4.0 / 150)
        pts = [pol(98, a0 - (dang / 2 - math.asin(4.0 / 98)))]
        for rr_ in (130, 160, 185):
            pts.append(pol(rr_, a0 - (dang / 2 - math.asin(4.0 / rr_))))
        tip_r = 228
        base_r = 192
        hw = math.sin(half) * base_r
        for t in np.linspace(0, 1, 9)[1:]:
            ang = (1 - t) * (-half) + 0.0
            rr2 = base_r + (tip_r - base_r) * math.sin(t * math.pi / 2)
            pts.append(pol(rr2, a0 + ang * (1 - t * 0.0) * (1 - t)))
        pts.append(pol(tip_r, a0))
        right = [(2 * c - 0, 0)]
        mirror = []
        for (px, py) in pts[::-1][1:]:
            # symétrique par rapport à l'axe de la lancette
            dx, dy = px - c, py - c
            r_ = math.hypot(dx, dy)
            ang = math.atan2(dy, dx) - a0
            mirror.append(pol(r_, a0 - ang))
        poly = pts + mirror
        del right
        dg.polygon(pa.P(poly), fill=255)
        col = (36, 58, 168) if k % 2 == 0 else (184, 30, 24)
        pa.poly(poly, col, shade=0, ol=0)
        for rr_ in (126, 156, 186):
            pa.line([pol(rr_, a0 - dang * 0.42), pol(rr_, a0 + dang * 0.42)], ink, 1.8)
        pa.line([pol(98, a0), pol(126, a0)], ink, 1.6)
        fx, fy = pol(172, a0)
        pa.poly(_flame_pts(fx, fy + 13, 26, 40, 0.0), (240, 184, 56), shade=0, ol=1.5, inkc=ink)
        pa.poly(_flame_pts(fx, fy + 10, 12, 21, 0.0), (252, 230, 130), shade=0, ol=0)
        pa.ell(*pol(112, a0), 5, 5, (240, 184, 56), shade=0, ol=1.3, inkc=ink)
        pa.ell(*pol(206, a0), 5, 5, (240, 200, 90) if k % 2 else (60, 140, 90), shade=0, ol=1.3, inkc=ink)
    for k in range(12):
        a = k * dang
        ox, oy = pol(222, a)
        dg.ellipse(tuple(v * pa.K for v in (ox - 13, oy - 13, ox + 13, oy + 13)), fill=255)
        pa.ell(ox, oy, 13, 13, (236, 172, 40), shade=0, ol=1.5, inkc=ink)
        pa.ell(ox, oy, 5.5, 5.5, (186, 30, 24), shade=0, ol=1.2, inkc=ink)
    dg.ellipse(tuple(v * pa.K for v in (c - 90, c - 90, c + 90, c + 90)), fill=255)
    pa.ell(c, c, 90, 90, (26, 42, 126), shade=0, ol=0)
    for k in range(20):
        a = k * TAU / 20
        pa.line([pol(66, a), pol(90, a)], ink, 1.5)
    pa.ell(c, c, 66, 66, (20, 30, 96), shade=0, ol=1.6, inkc=ink)
    horned_flame(pa, c, c + 12, 46, gold=(244, 190, 64), deep=(206, 54, 26), horn=(170, 40, 30), ol=1.6, horn_tip=(240, 220, 170))
    for k in range(10):
        a = R.uniform(0, TAU)
        r = R.uniform(30, 56)
        pa.ell(c + math.cos(a) * r, c - 20 + math.sin(a) * r * 0.6, 1.5, 1.5, (250, 230, 140), shade=0, ol=0)
    gl = np.asarray(glass, np.float32) / 255.0
    yy, xx = np.mgrid[0:pa.h, 0:pa.w].astype(np.float32) / pa.K
    rad = np.hypot(xx - c, yy - c)
    big = max(pa.w, pa.h)
    streak = tn(R, big, (16, 32, 64, 128), 0.6)[:pa.h, :pa.w]
    pa.rgb = pa.rgb * (1 + gl[..., None] * (0.2 * (1 - rad / 260.0)[..., None] + 0.16 * (streak[..., None] - 0.5)))
    stone = Image.new("L", (pa.w, pa.h), 0)
    ImageDraw.Draw(stone).ellipse(tuple(v * pa.K for v in (c - 250, c - 250, c + 250, c + 250)), fill=255)
    st = np.clip(np.asarray(stone, np.float32) / 255.0 - gl, 0, 1)
    pa.comp(Image.fromarray((st * 255).astype(np.uint8)), (66, 62, 58), shade=0.7, depth=2.5, tex=True)
    pa.outline(ellp(c, c, 250, 250, n=120), 2.0, ink)
    pa.outline(ellp(c, c, 240, 240, n=120), 1.0, (40, 36, 34), alpha=0.7)
    rgb, _ = pa.result()
    am = Image.new("L", (S * 4, S * 4), 0)
    ImageDraw.Draw(am).ellipse((4 * (c - 251), 4 * (c - 251), 4 * (c + 251), 4 * (c + 251)), fill=255)
    alpha = np.asarray(am.resize((S, S), Image.LANCZOS), np.float32) / 255.0
    save_rgba(np.dstack([rgb, alpha]), "vitrail_rosace.png")


def vitrail_lancette():
    """Une haute verrière en lancette : bordure de perles rouges et or, fond de petits carreaux
    bleus semés de rouge, trois médaillons cerclés d'or (la flamme, un démon qui porte sa
    lanterne, l'enclume de la Cathédrale-Forge), un oculus dans la tête de l'arc ; plombs,
    barlotières, encadrement de pierre sombre."""
    W, H = 256, 768
    R = rng(7203)
    pa = Paint(W, H, 2, seed=7203)
    _masonry_wall(pa, R, course=52)
    x0, x1, ys, yb = 40, 216, 196, 740
    pa.poly(arch_pts(x0 - 22, x1 + 22, ys, yb + 20), (84, 80, 76), shade=0.7, depth=6, ol=1.2)
    pa.poly(arch_pts(x0 - 10, x1 + 10, ys, yb + 10), (62, 58, 56), shade=0.6, depth=4, ol=1.0)
    gm = pa._draw(lambda d: d.polygon(pa.P(arch_pts(x0, x1, ys, yb)), fill=255))
    _glass_cells(pa, gm, 16, 0, R, (40, 62, 168), var=0.35, lead=1.8, hue=0.1)
    # semis de rouge dans le fond
    rr = rng(7213)
    for _ in range(70):
        x = x0 + 8 + rr.integers(0, int((x1 - x0 - 16) / 16)) * 16
        y = 60 + rr.integers(0, int((yb - 70) / 16)) * 16
        inside = gm.getpixel((int((x + 8) * pa.K), int((y + 8) * pa.K))) > 0
        if inside:
            pa.rect(x + 1, y + 1, x + 15, y + 15, (178, 30, 24), shade=0, ol=1.6, inkc=(18, 16, 15))
    # bordure de perles
    border = arch_pts(x0, x1, ys, yb, d=7, n=60)
    acc = 0.0
    for (ax, ay), (bx, by) in zip(border[:-1], border[1:]):
        seg = math.hypot(bx - ax, by - ay)
        t = 0.0
        while t < seg:
            if acc <= 0:
                px, py = ax + (bx - ax) * t / max(seg, 1e-6), ay + (by - ay) * t / max(seg, 1e-6)
                k = int(round(px * 0.37 + py * 0.11)) % 2
                pa.ell(px, py, 4.6, 4.6, (226, 172, 48) if k else (190, 32, 26), shade=0, ol=1.2, inkc=(18, 16, 15))
                acc = 11.0
            step = min(seg - t, acc)
            t += step
            acc -= step
            if step == 0:
                t += 1
    cx = (x0 + x1) / 2

    def medal(cy, draw):
        pa.ell(cx, cy, 64, 64, (226, 170, 46), shade=0, ol=1.8, inkc=(18, 16, 15))
        pa.ell(cx, cy, 55, 55, (160, 26, 22), shade=0, ol=1.8, inkc=(18, 16, 15))
        for k in range(12):
            a = k * TAU / 12
            pa.line([(cx + math.cos(a) * 56, cy + math.sin(a) * 56), (cx + math.cos(a) * 63, cy + math.sin(a) * 63)], (18, 16, 15), 1.4)
        draw(cy)

    def m_flame(cy):
        for k in range(8):
            a = k * TAU / 8 + 0.2
            pa.poly([(cx + math.cos(a - 0.12) * 20, cy + math.sin(a - 0.12) * 20), (cx + math.cos(a) * 48, cy + math.sin(a) * 48),
                     (cx + math.cos(a + 0.12) * 20, cy + math.sin(a + 0.12) * 20)], (236, 120, 30), shade=0, ol=1.2, inkc=(18, 16, 15))
        pa.poly(_flame_pts(cx, cy + 22, 44, 62, 0.05), (248, 196, 60), shade=0, ol=1.6, inkc=(18, 16, 15))
        pa.poly(_flame_pts(cx, cy + 18, 20, 32, 0.0), (252, 236, 150), shade=0, ol=0)

    def m_demon(cy):
        pa.poly([(cx - 26, cy + 50), (cx - 18, cy + 4), (cx, cy - 6), (cx + 18, cy + 4), (cx + 26, cy + 50)], (86, 40, 120), shade=0, ol=1.6, inkc=(18, 16, 15))
        pa.ell(cx, cy - 18, 13, 14, (196, 70, 60), shade=0, ol=1.6, inkc=(18, 16, 15))
        for sx in (-1, 1):
            pa.poly([(cx + sx * 7, cy - 28), (cx + sx * 16, cy - 46), (cx + sx * 12, cy - 26)], (240, 220, 180), shade=0, ol=1.2, inkc=(18, 16, 15))
        pa.ell(cx - 5, cy - 20, 2.2, 2.2, (250, 220, 90), shade=0, ol=0)
        pa.ell(cx + 5, cy - 20, 2.2, 2.2, (250, 220, 90), shade=0, ol=0)
        pa.line([(cx + 14, cy + 6), (cx + 34, cy - 8)], (40, 30, 26), 2.4)
        pa.line([(cx + 34, cy - 8), (cx + 34, cy + 4)], (40, 30, 26), 1.4)
        pa.rect(cx + 27, cy + 4, cx + 41, cy + 24, (250, 196, 70), shade=0, ol=1.4, inkc=(18, 16, 15))
        pa.poly(_flame_pts(cx + 34, cy + 20, 7, 12), (255, 240, 170), shade=0, ol=0)

    def m_anvil(cy):
        pa.poly([(cx - 40, cy - 2), (cx + 30, cy - 2), (cx + 44, cy - 10), (cx + 30, cy + 8), (cx + 12, cy + 10), (cx + 16, cy + 28), (cx + 26, cy + 34),
                 (cx - 26, cy + 34), (cx - 16, cy + 28), (cx - 12, cy + 10), (cx - 34, cy + 8)], (120, 124, 136), shade=0, ol=1.6, inkc=(18, 16, 15))
        pa.line([(cx - 30, cy - 34), (cx + 4, cy - 10)], (130, 84, 46), 4.0)
        pa.poly([(cx - 40, cy - 46), (cx - 22, cy - 46), (cx - 18, cy - 24), (cx - 36, cy - 24)], (110, 114, 126), shade=0, ol=1.4, inkc=(18, 16, 15))
        for k in range(9):
            a = -math.pi / 2 + R.uniform(-1.2, 1.2)
            r = R.uniform(14, 34)
            pa.ell(cx + 8 + math.cos(a) * r, cy - 12 + math.sin(a) * r, 1.8, 1.8, (255, 220, 90), shade=0, ol=0)

    medal(256, m_flame)
    medal(434, m_demon)
    medal(612, m_anvil)
    pa.ell(cx, 112, 26, 26, (226, 170, 46), shade=0, ol=1.8, inkc=(18, 16, 15))
    pa.ell(cx, 112, 18, 18, (34, 52, 150), shade=0, ol=1.6, inkc=(18, 16, 15))
    pa.poly(_flame_pts(cx, 124, 16, 24), (248, 196, 60), shade=0, ol=1.2, inkc=(18, 16, 15))
    for yb_ in (345, 523):
        pa.line([(x0 - 2, yb_), (x1 + 2, yb_)], (20, 18, 18), 3.0)
    gl = np.asarray(gm, np.float32) / 255.0
    pa.rgb = pa.rgb * (1 + gl[..., None] * 0.15)
    pa.rect(x0 - 30, yb + 18, x1 + 30, yb + 28, (92, 88, 82), shade=0.6, depth=3, ol=1.0)
    rgb, _ = pa.result()
    save_rgb(rgb, "vitrail_lancette.png")


def banniere_pandemonia():
    """La bannière de Pandémonia : drap de laine rouge sombre semé de losanges, bordure noire,
    queue d'aronde (transparente entre les deux pointes), la flamme cornue brodée d'or au
    milieu ; plis verticaux, ourlet du haut piqué."""
    W, H = 256, 512
    R = rng(7204)
    pa = Paint(W, H, 2, bg=(60, 8, 8), seed=7204)
    x0, x1, y0, yt, yn = 18, 238, 10, 500, 404
    shape = [(x0, y0), (x1, y0), (x1, yt), (128, yn), (x0, yt)]
    m = pa._draw(lambda d: d.polygon(pa.P(shape), fill=255))
    yy, xx = np.mgrid[0:pa.h, 0:pa.w].astype(np.float32) / pa.K
    big = max(pa.w, pa.h)
    weave = 0.92 + 0.08 * (np.sin(xx * 3.1) * np.sin(yy * 3.1) * 0.5 + 0.5)
    red = np.array((0.46, 0.05, 0.05), np.float32) * weave[..., None] * (0.9 + 0.2 * tn(R, big, (8, 16, 32, 64), 0.6)[:pa.h, :pa.w, None])
    lz = (np.abs(np.mod(xx - 128, 36) - 18) + np.abs(np.mod(yy, 44) - 22) * 0.82)
    red = red * (1 - 0.18 * (1 - smooth(9, 11, lz))[..., None])
    pa.rgb = red.astype(np.float32)
    inner = [(x0 + 13, y0 + 22), (x1 - 13, y0 + 22), (x1 - 13, yt - 22), (128, yn - 14), (x0 + 13, yt - 22)]
    bm = np.asarray(m, np.float32) / 255.0 - np.asarray(pa._draw(lambda d: d.polygon(pa.P(inner), fill=255)), np.float32) / 255.0
    pa.comp(Image.fromarray((np.clip(bm, 0, 1) * 255).astype(np.uint8)), (20, 16, 16), tex=True)
    pa.outline(inner, 1.2, (190, 140, 50), alpha=0.9)
    pa.rect(x0, y0, x1, y0 + 14, (30, 22, 22), shade=0.4, depth=2, ol=0)
    for k in range(18):
        pa.ell(x0 + 8 + k * 12, y0 + 18, 1.0, 1.0, (200, 150, 60), shade=0, ol=0)
    horned_flame(pa, 128, 250, 70, gold=(226, 172, 58), deep=(160, 40, 22), horn=(176, 118, 44), ol=2.0, horn_tip=(236, 200, 110))
    # fils d'or : hachures fines sur la broderie
    gold_m = (np.abs(pa.rgb[..., 0] - pa.rgb[..., 2]) > 0.35) & (pa.rgb[..., 1] > 0.3)
    hatch = 0.9 + 0.1 * np.sin((xx + yy) * 2.4)
    pa.rgb = np.where(gold_m[..., None], pa.rgb * hatch[..., None], pa.rgb)
    pa.text((128, 372), "PANDÉMONIA", 19, (226, 176, 70), stroke=1.2, stroke_col=(30, 10, 8), spacing=1.5)
    folds = 1 + 0.13 * np.sin(xx / 64 * TAU + 0.6) + 0.06 * np.sin(xx / 23 * TAU + 1.3)
    sag = 1 - 0.12 * smooth(200, 500, yy)
    pa.rgb = pa.rgb * (folds * sag)[..., None]
    rgb, _ = pa.result()
    am = Image.new("L", (W * 4, H * 4), 0)
    ImageDraw.Draw(am).polygon([(x * 4, y * 4) for x, y in shape], fill=255)
    alpha = np.asarray(am.resize((W, H), Image.LANCZOS), np.float32) / 255.0
    save_rgba(np.dstack([rgb, alpha]), "banniere_pandemonia.png")


# =================================================================== enseignes

def em_chope(pa, cx, cy, s):
    pa.poly([(cx - 0.45 * s, cy - 0.45 * s), (cx + 0.35 * s, cy - 0.45 * s), (cx + 0.32 * s, cy + 0.6 * s), (cx - 0.42 * s, cy + 0.6 * s)], (150, 92, 48), shade=0.7, depth=s * 0.12)
    for yv in (-0.28, 0.42):
        pa.line([(cx - 0.44 * s, cy + yv * s), (cx + 0.34 * s, cy + yv * s)], (60, 56, 60), s * 0.07)
    pa.poly(ellp(cx + 0.45 * s, cy + 0.05 * s, 0.28 * s, 0.32 * s, -90, 90, 20) + ellp(cx + 0.45 * s, cy + 0.05 * s, 0.15 * s, 0.19 * s, 90, -90, 20),
            (130, 80, 40), shade=0.6, depth=s * 0.06)
    for k, (dx, r) in enumerate(((-0.32, 0.2), (-0.08, 0.24), (0.18, 0.21), (0.0, 0.17))):
        pa.ell(cx + dx * s, cy - (0.5 + (0.12 if k == 3 else 0)) * s, r * s, r * 0.8 * s, (244, 236, 214), shade=0.6, depth=s * 0.05, ol=1.2)
    for k in range(2):
        pa.poly([(cx - 0.42 * s + k * 0.7 * s, cy + 0.55 * s), (cx - 0.38 * s + k * 0.7 * s, cy + 0.72 * s), (cx - 0.3 * s + k * 0.7 * s, cy + 0.55 * s)], (240, 220, 180), shade=0, ol=1)


def em_pain(pa, cx, cy, s):
    for k in range(3):
        a = math.radians(-60 + k * 14)
        pa.line([(cx + 0.5 * s, cy + 0.5 * s), (cx + 0.5 * s + math.cos(a) * s * 0.9, cy + 0.5 * s + math.sin(a) * s * 0.9)], (200, 160, 70), s * 0.04)
        for j in range(5):
            t = 0.45 + j * 0.11
            px, py = cx + 0.5 * s + math.cos(a) * s * 0.9 * t, cy + 0.5 * s + math.sin(a) * s * 0.9 * t
            pa.ell(px - 0.04 * s, py, 0.07 * s, 0.04 * s, (226, 186, 90), shade=0.4, depth=2, ol=0.8)
    pa.poly(ellp(cx - 0.05 * s, cy + 0.1 * s, 0.62 * s, 0.38 * s, n=48), (196, 122, 50), shade=0.8, depth=s * 0.14)
    for k in range(4):
        x = cx - 0.42 * s + k * 0.24 * s
        pa.line([(x, cy - 0.05 * s), (x + 0.16 * s, cy + 0.28 * s)], (120, 66, 26), s * 0.05)
    pa.ell(cx - 0.05 * s, cy - 0.38 * s, 0.22 * s, 0.17 * s, (206, 134, 58), shade=0.8, depth=s * 0.06)


def em_enclume(pa, cx, cy, s):
    pa.poly([(cx - 0.7 * s, cy - 0.1 * s), (cx + 0.45 * s, cy - 0.1 * s), (cx + 0.75 * s, cy - 0.22 * s), (cx + 0.5 * s, cy + 0.1 * s), (cx + 0.2 * s, cy + 0.14 * s),
             (cx + 0.24 * s, cy + 0.42 * s), (cx + 0.42 * s, cy + 0.55 * s), (cx - 0.42 * s, cy + 0.55 * s), (cx - 0.24 * s, cy + 0.42 * s),
             (cx - 0.2 * s, cy + 0.14 * s), (cx - 0.55 * s, cy + 0.1 * s)], (96, 98, 108), shade=0.8, depth=s * 0.08)
    pa.tubep([(cx - 0.6 * s, cy - 0.85 * s), (cx + 0.05 * s, cy - 0.25 * s)], s * 0.09, (140, 92, 50), shade=0.6, depth=s * 0.04)
    pa.poly([(cx - 0.78 * s, cy - 0.98 * s), (cx - 0.48 * s, cy - 1.04 * s), (cx - 0.38 * s, cy - 0.7 * s), (cx - 0.68 * s, cy - 0.64 * s)], (110, 112, 124), shade=0.7, depth=s * 0.05)
    R = rng(int(cx * 7 + cy))
    for k in range(12):
        a = -math.pi / 2 + R.uniform(-1.3, 1.3)
        r = R.uniform(0.25, 0.75) * s
        pa.ell(cx + 0.15 * s + math.cos(a) * r, cy - 0.2 * s + math.sin(a) * r, 0.035 * s, 0.035 * s, (255, 200, 80), shade=0, ol=0)
        pa.glow(cx + 0.15 * s + math.cos(a) * r, cy - 0.2 * s + math.sin(a) * r, 0.08 * s, (120, 60, 10), 0.6)


def em_livre(pa, cx, cy, s):
    for sx in (-1, 1):
        pa.poly([(cx, cy + 0.15 * s), (cx + sx * 0.75 * s, cy + 0.05 * s), (cx + sx * 0.78 * s, cy + 0.62 * s), (cx, cy + 0.72 * s)], (120, 30, 30), shade=0.5, depth=4)
        pa.poly([(cx, cy + 0.1 * s), (cx + sx * 0.68 * s, cy - 0.02 * s), (cx + sx * 0.7 * s, cy + 0.55 * s), (cx, cy + 0.64 * s)], (238, 226, 196), shade=0.6, depth=4)
        for k in range(4):
            y = cy + (0.12 + k * 0.1) * s
            pa.line([(cx + sx * 0.12 * s, y + 0.03 * s), (cx + sx * 0.56 * s, y - 0.02 * s)], (120, 100, 80), 1.2)
    pa.poly(_flame_pts(cx, cy - 0.05 * s, 0.5 * s, 0.85 * s), (240, 130, 30), shade=0.7, depth=s * 0.06)
    pa.poly(_flame_pts(cx, cy - 0.08 * s, 0.25 * s, 0.45 * s), (255, 214, 90), shade=0.5, depth=s * 0.04, ol=0)
    pa.glow(cx, cy - 0.35 * s, 0.6 * s, (120, 60, 10), 0.35)


def em_cornes(pa, cx, cy, s):
    for sx in (-1, 1):
        pts = [(cx - sx * 0.55 * s, cy + 0.55 * s)]
        for k in range(1, 13):
            t = k / 12
            pts.append((cx - sx * 0.55 * s + sx * t * 1.0 * s + sx * math.sin(t * math.pi) * 0.12 * s, cy + 0.55 * s - t * 1.15 * s - math.sin(t * math.pi) * 0.1 * s))
        pa.tubep(pts, 0.3 * s, (236, 222, 190), w1=0.03 * s, shade=0.8, depth=s * 0.06)
        for k in range(2, 9, 2):
            x, y = pts[k]
            pa.line([(x - 0.1 * s, y - 0.06 * s * sx), (x + 0.1 * s, y + 0.06 * s * sx)], (170, 150, 120), 1.2)
    pa.ell(cx, cy + 0.48 * s, 0.2 * s, 0.2 * s, (200, 40, 30), shade=0.7, depth=4)


def em_balance(pa, cx, cy, s):
    gold = (220, 168, 60)
    pa.tubep([(cx, cy - 0.75 * s), (cx, cy + 0.55 * s)], 0.08 * s, gold, shade=0.6, depth=3)
    pa.poly([(cx - 0.3 * s, cy + 0.72 * s), (cx + 0.3 * s, cy + 0.72 * s), (cx + 0.18 * s, cy + 0.55 * s), (cx - 0.18 * s, cy + 0.55 * s)], gold, shade=0.6, depth=3)
    pa.tubep([(cx - 0.72 * s, cy - 0.55 * s), (cx + 0.72 * s, cy - 0.55 * s)], 0.07 * s, gold, shade=0.6, depth=3)
    for sx in (-1, 1):
        x = cx + sx * 0.66 * s
        for dx in (-0.2, 0.2):
            pa.line([(x, cy - 0.55 * s), (x + dx * s, cy + 0.05 * s)], (90, 70, 40), 1.2)
        pa.poly(ellp(x, cy + 0.05 * s, 0.26 * s, 0.12 * s, 0, 180, 20), gold, shade=0.6, depth=3)
    pa.ell(cx, cy - 0.78 * s, 0.08 * s, 0.08 * s, gold, shade=0.6, depth=2)


def em_vapeur(pa, cx, cy, s):
    pa.poly(ellp(cx, cy + 0.25 * s, 0.75 * s, 0.45 * s, 0, 180, 30), (120, 80, 50), shade=0.7, depth=s * 0.08)
    pa.ell(cx, cy + 0.25 * s, 0.75 * s, 0.16 * s, (226, 206, 80), shade=0.4, depth=4)
    for k in (-1, 0, 1):
        x = cx + k * 0.32 * s
        pts = [(x + math.sin(t * 5.5) * 0.09 * s, cy + 0.05 * s - t * 0.95 * s) for t in np.linspace(0, 1, 18)]
        pa.line(pts, (236, 236, 226), 0.08 * s)


def em_livres(pa, cx, cy, s):
    cols = [(110, 30, 30), (30, 70, 50), (40, 50, 110), (120, 80, 30)]
    for k, c in enumerate(cols):
        y = cy + 0.55 * s - k * 0.24 * s
        dx = (k % 2) * 0.08 * s - 0.04 * s
        pa.rect(cx - 0.6 * s + dx, y - 0.2 * s, cx + 0.55 * s + dx, y, c, shade=0.6, depth=3)
        pa.line([(cx - 0.5 * s + dx, y - 0.1 * s), (cx + 0.45 * s + dx, y - 0.1 * s)], (220, 180, 80), 1.2)
    for k, dx in enumerate((-0.3, 0.05, 0.38)):
        fx, fy = cx + dx * s, cy - 0.45 * s - (k % 2) * 0.15 * s
        pa.poly(_flame_pts(fx, fy, 0.2 * s, 0.38 * s, 0.1), (170, 220, 250), shade=0.4, depth=3, ol=1.0)
        pa.glow(fx, fy - 0.12 * s, 0.25 * s, (40, 80, 110), 0.5)
        pa.ell(fx - 0.04 * s, fy - 0.1 * s, 0.018 * s, 0.025 * s, (30, 40, 60), shade=0, ol=0)
        pa.ell(fx + 0.04 * s, fy - 0.1 * s, 0.018 * s, 0.025 * s, (30, 40, 60), shade=0, ol=0)


def em_fiole(pa, cx, cy, s):
    pa.rect(cx - 0.13 * s, cy - 0.8 * s, cx + 0.13 * s, cy - 0.3 * s, (190, 220, 220), shade=0.5, depth=3, alpha=0.9)
    pa.rect(cx - 0.17 * s, cy - 0.92 * s, cx + 0.17 * s, cy - 0.78 * s, (140, 90, 50), shade=0.6, depth=3)
    pa.ell(cx, cy + 0.15 * s, 0.55 * s, 0.55 * s, (180, 214, 214), shade=0.6, depth=s * 0.1)
    pa.poly(ellp(cx, cy + 0.15 * s, 0.5 * s, 0.5 * s, 10, 170, 30), (120, 40, 150), shade=0.6, depth=s * 0.08, ol=0)
    for k in range(5):
        pa.ell(cx + (k - 2) * 0.13 * s, cy + (0.3 - (k % 2) * 0.12) * s, 0.04 * s, 0.04 * s, (220, 180, 240), shade=0, ol=0)
    pa.ell(cx - 0.22 * s, cy - 0.05 * s, 0.08 * s, 0.14 * s, (250, 250, 250), shade=0, ol=0, alpha=0.7)


def em_epees(pa, cx, cy, s):
    for sx in (-1, 1):
        a = math.radians(-50 if sx > 0 else -130)
        ca, sa = math.cos(a), math.sin(a)
        bx, by = cx - ca * 0.6 * s, cy - sa * 0.6 * s
        tx, ty = cx + ca * 0.85 * s, cy + sa * 0.85 * s
        nx, ny = -sa, ca
        pa.poly([(bx + nx * 0.07 * s, by + ny * 0.07 * s), (tx - ca * 0.12 * s + nx * 0.06 * s, ty - sa * 0.12 * s + ny * 0.06 * s), (tx, ty),
                 (tx - ca * 0.12 * s - nx * 0.06 * s, ty - sa * 0.12 * s - ny * 0.06 * s), (bx - nx * 0.07 * s, by - ny * 0.07 * s)], (200, 204, 214), shade=0.7, depth=3)
        pa.tubep([(bx - nx * 0.25 * s, by - ny * 0.25 * s), (bx + nx * 0.25 * s, by + ny * 0.25 * s)], 0.08 * s, (210, 160, 60), shade=0.6, depth=2)
        pa.tubep([(bx, by), (bx - ca * 0.3 * s, by - sa * 0.3 * s)], 0.09 * s, (90, 50, 30), shade=0.6, depth=2)
    pa.poly([(cx - 0.36 * s, cy - 0.1 * s), (cx + 0.36 * s, cy - 0.1 * s), (cx + 0.34 * s, cy + 0.3 * s), (cx, cy + 0.62 * s), (cx - 0.34 * s, cy + 0.3 * s)],
            (150, 30, 26), shade=0.7, depth=s * 0.06)
    pa.poly(_flame_pts(cx, cy + 0.32 * s, 0.24 * s, 0.36 * s), (230, 170, 60), shade=0.5, depth=2, ol=1.0)


def em_corne(pa, cx, cy, s):
    pts = [(cx - 0.55 * s, cy + 0.55 * s)]
    for k in range(1, 15):
        t = k / 14
        a = math.pi * 0.9 * t
        pts.append((cx - 0.55 * s + t * 0.7 * s + math.sin(a) * 0.3 * s, cy + 0.55 * s - t * 1.2 * s + (1 - math.cos(a)) * 0.08 * s))
    pa.tubep(pts, 0.36 * s, (120, 40, 34), w1=0.03 * s, shade=0.9, depth=s * 0.06)
    for k in range(3, 12, 2):
        x, y = pts[k]
        pa.line([(x - 0.12 * s, y + 0.02 * s), (x + 0.1 * s, y - 0.04 * s)], (70, 20, 18), 1.4)
    for (dx, dy, r) in ((0.42, -0.5, 0.12), (0.55, -0.15, 0.08), (0.2, -0.75, 0.07)):
        x, y = cx + dx * s, cy + dy * s
        pa.poly([(x, y - r * s), (x + 0.25 * r * s, y - 0.25 * r * s), (x + r * s, y), (x + 0.25 * r * s, y + 0.25 * r * s), (x, y + r * s),
                 (x - 0.25 * r * s, y + 0.25 * r * s), (x - r * s, y), (x - 0.25 * r * s, y - 0.25 * r * s)], (255, 240, 180), shade=0, ol=0)
    pa.poly([(cx + 0.05 * s, cy + 0.42 * s), (cx + 0.75 * s, cy + 0.2 * s), (cx + 0.78 * s, cy + 0.32 * s), (cx + 0.08 * s, cy + 0.55 * s)], (60, 50, 46), shade=0.5, depth=2)
    for k in range(7):
        x = cx + 0.14 * s + k * 0.09 * s
        y = cy + 0.4 * s - k * 0.028 * s
        pa.line([(x, y), (x + 0.02 * s, y + 0.12 * s)], (60, 50, 46), 1.4)


def em_enveloppe(pa, cx, cy, s):
    for sx in (-1, 1):
        for k in range(4):
            yo = -0.25 * s + k * 0.12 * s
            pa.poly([(cx + sx * 0.45 * s, cy + yo), (cx + sx * (0.95 - k * 0.1) * s, cy + yo - 0.22 * s), (cx + sx * (0.85 - k * 0.12) * s, cy + yo + 0.08 * s)],
                    (236, 232, 222), shade=0.4, depth=2, ol=1.0)
    pa.rect(cx - 0.5 * s, cy - 0.35 * s, cx + 0.5 * s, cy + 0.35 * s, (232, 216, 180), shade=0.5, depth=4)
    pa.poly([(cx - 0.5 * s, cy - 0.35 * s), (cx, cy + 0.08 * s), (cx + 0.5 * s, cy - 0.35 * s)], (214, 196, 156), shade=0.4, depth=3)
    pa.ell(cx, cy + 0.05 * s, 0.12 * s, 0.12 * s, (180, 30, 26), shade=0.7, depth=3)


def em_ciseaux(pa, cx, cy, s):
    pa.poly([(cx - 0.1 * s, cy - 0.7 * s), (cx + 0.55 * s, cy - 0.6 * s), (cx + 0.75 * s, cy + 0.65 * s), (cx + 0.3 * s, cy + 0.5 * s), (cx - 0.05 * s, cy + 0.7 * s)],
            (120, 28, 40), shade=0.7, depth=s * 0.08, sm=1)
    pa.line([(cx + 0.1 * s, cy - 0.6 * s), (cx + 0.3 * s, cy + 0.45 * s)], (80, 16, 26), 1.4)
    for sx in (-1, 1):
        a = math.radians(-110 + sx * 18)
        pa.tubep([(cx - 0.3 * s, cy + 0.1 * s), (cx - 0.3 * s + math.cos(a) * 0.75 * s, cy + 0.1 * s + math.sin(a) * 0.75 * s)], 0.08 * s, (200, 204, 214), w1=0.02 * s, shade=0.6, depth=2)
        ra = math.radians(70 + sx * 20)
        hx, hy = cx - 0.3 * s + math.cos(ra) * 0.38 * s, cy + 0.1 * s + math.sin(ra) * 0.38 * s
        pa.ell(hx, hy, 0.13 * s, 0.13 * s, (200, 204, 214), shade=0.6, depth=2)
        pa.ell(hx, hy, 0.07 * s, 0.07 * s, (60, 40, 50), shade=0, ol=1.0)


def em_ancre(pa, cx, cy, s):
    c = (70, 72, 80)
    pa.ell(cx, cy - 0.72 * s, 0.14 * s, 0.14 * s, c, shade=0.6, depth=3)
    pa.ell(cx, cy - 0.72 * s, 0.07 * s, 0.07 * s, (200, 180, 140), shade=0, ol=1.0)
    pa.tubep([(cx, cy - 0.6 * s), (cx, cy + 0.6 * s)], 0.12 * s, c, shade=0.7, depth=3)
    pa.tubep([(cx - 0.35 * s, cy - 0.38 * s), (cx + 0.35 * s, cy - 0.38 * s)], 0.1 * s, c, shade=0.7, depth=3)
    pts = [(cx + math.cos(a) * 0.62 * s, cy + 0.05 * s + math.sin(a) * 0.55 * s) for a in np.linspace(math.radians(160), math.radians(20), 20)]
    pa.tubep(pts, 0.12 * s, c, shade=0.7, depth=3)
    for sx in (-1, 1):
        x, y = cx + sx * 0.6 * s, cy + 0.2 * s
        pa.poly([(x, y - 0.18 * s), (x + sx * 0.12 * s, y + 0.06 * s), (x - sx * 0.06 * s, y)], c, shade=0.5, depth=2)
    rope = [(cx + 0.14 * s + math.sin(t * 9) * 0.1 * s + t * 0.3 * s, cy - 0.7 * s + t * 1.2 * s) for t in np.linspace(0, 1, 24)]
    pa.line(rope, (200, 160, 100), 0.06 * s)


def em_mortier(pa, cx, cy, s):
    for k, (dx, a) in enumerate(((-0.45, -0.3), (0.5, 0.4))):
        pts = [(cx + dx * s + math.sin(t * 2.2) * 0.12 * s * (1 if k else -1), cy - 0.55 * s + t * 0.7 * s) for t in np.linspace(0, 1, 12)]
        pa.tubep(pts, 0.16 * s, (190, 30, 20), w1=0.03 * s, shade=0.8, depth=3)
        pa.tubep([pts[0], (pts[0][0] + 0.05 * s, pts[0][1] - 0.12 * s)], 0.05 * s, (60, 120, 40), shade=0.5, depth=2)
    pa.tubep([(cx + 0.15 * s, cy - 0.75 * s), (cx - 0.1 * s, cy + 0.05 * s)], 0.14 * s, (150, 120, 90), shade=0.6, depth=3)
    pa.poly(ellp(cx, cy + 0.1 * s, 0.6 * s, 0.55 * s, 0, 180, 30), (130, 124, 116), shade=0.8, depth=s * 0.1)
    pa.ell(cx, cy + 0.1 * s, 0.6 * s, 0.13 * s, (90, 60, 30), shade=0.4, depth=3)
    pa.rect(cx - 0.3 * s, cy + 0.62 * s, cx + 0.3 * s, cy + 0.72 * s, (110, 104, 98), shade=0.5, depth=2)


def em_poisson(pa, cx, cy, s):
    body = ellp(cx, cy, 0.62 * s, 0.32 * s, n=48)
    pa.poly([(cx + 0.5 * s, cy), (cx + 0.92 * s, cy - 0.35 * s), (cx + 0.82 * s, cy), (cx + 0.92 * s, cy + 0.35 * s)], (230, 110, 30), shade=0.6, depth=3)
    for k in range(3):
        x = cx - 0.2 * s + k * 0.2 * s
        pa.poly(_flame_pts(x, cy - 0.25 * s, 0.2 * s, 0.32 * s, 0.25), (240, 150, 40), shade=0.5, depth=2, ol=1.0)
    pa.poly(body, (210, 70, 30), shade=0.8, depth=s * 0.1, grad=((240, 120, 40), (150, 30, 20), 90))
    pa.ell(cx - 0.36 * s, cy - 0.06 * s, 0.07 * s, 0.07 * s, (250, 240, 200), shade=0, ol=1.0)
    pa.ell(cx - 0.36 * s, cy - 0.06 * s, 0.035 * s, 0.035 * s, (20, 16, 14), shade=0, ol=0)
    for k in range(4):
        x = cx - 0.1 * s + k * 0.14 * s
        pa.poly(ellp(x, cy, 0.09 * s, 0.14 * s, -70, 70, 10), (140, 30, 20), shade=0, ol=0, alpha=0.6)
    pa.line(ellp(cx - 0.18 * s, cy, 0.1 * s, 0.24 * s, -70, 70, 12), (120, 30, 20), 1.4)


def em_engrenage(pa, cx, cy, s):
    teeth = []
    n = 10
    for k in range(n * 2):
        a = k / (n * 2) * TAU
        r = 0.62 * s if k % 2 == 0 else 0.48 * s
        a2 = a + TAU / (n * 2)
        teeth += [(cx - 0.12 * s + math.cos(a) * r, cy + 0.12 * s + math.sin(a) * r), (cx - 0.12 * s + math.cos(a2 - 0.08) * r, cy + 0.12 * s + math.sin(a2 - 0.08) * r)]
    pa.poly(teeth, (190, 150, 70), shade=0.8, depth=s * 0.06)
    pa.ell(cx - 0.12 * s, cy + 0.12 * s, 0.18 * s, 0.18 * s, (60, 44, 30), shade=0.3, depth=3)
    rx, ry = cx + 0.42 * s, cy - 0.42 * s
    a = math.radians(-50)
    ca, sa = math.cos(a), math.sin(a)
    body = [(rx - ca * 0.35 * s - sa * 0.1 * s, ry - sa * 0.35 * s + ca * 0.1 * s), (rx + ca * 0.25 * s - sa * 0.1 * s, ry + sa * 0.25 * s + ca * 0.1 * s),
            (rx + ca * 0.45 * s, ry + sa * 0.45 * s), (rx + ca * 0.25 * s + sa * 0.1 * s, ry + sa * 0.25 * s - ca * 0.1 * s),
            (rx - ca * 0.35 * s + sa * 0.1 * s, ry - sa * 0.35 * s - ca * 0.1 * s)]
    pa.poly(_flame_pts(rx - ca * 0.45 * s, ry - sa * 0.45 * s + 0.12 * s, 0.16 * s, 0.3 * s, -0.5), (250, 170, 40), shade=0.4, depth=2, ol=0.8)
    pa.poly(body, (180, 40, 30), shade=0.7, depth=3)
    pa.ell(rx, ry, 0.06 * s, 0.06 * s, (220, 230, 240), shade=0, ol=1.0)


EMBLEMS = {"chope": em_chope, "pain": em_pain, "enclume": em_enclume, "livre": em_livre, "cornes": em_cornes, "balance": em_balance,
           "vapeur": em_vapeur, "livres": em_livres, "fiole": em_fiole, "epees": em_epees, "corne": em_corne, "enveloppe": em_enveloppe,
           "ciseaux": em_ciseaux, "ancre": em_ancre, "mortier": em_mortier, "poisson": em_poisson, "engrenage": em_engrenage}

ENSEIGNES = {
    # id : (texte, sous-titre, style, fond, lettres, emblème)
    "taverne": ("Au Diable Repu", "Taverne · grog de soufre", "bois", (74, 42, 24), "or", "chope"),
    "boulangerie": ("Le Four Éternel", "Boulangerie · brioches de braise", "bois", (92, 56, 32), "or", "pain"),
    "forge": ("La Grande Forge", "Ferronnerie · Ferronde", "fer", (46, 44, 48), "laiton", "enclume"),
    "academie": ("Académie Infernale", "Sciences des flammes", "peint", (58, 26, 66), "or", "livre"),
    "arene": ("Arène des Cornes", "Grand Tournoi", "peint", (30, 24, 24), "rouge", "cornes"),
    "marche": ("Grand Marché", "Épices · Tissus · Merveilles", "peint", (124, 32, 26), "creme", "balance"),
    "thermes": ("Thermes de Soufre", "Bains chauds", "peint", (30, 72, 74), "soufre", "vapeur"),
    "bibliotheque": ("Bibliothèque des Âmes", "", "peint", (26, 52, 40), "or", "livres"),
    "apothicaire": ("Vespérine — Apothicaire", "", "peint", (22, 58, 62), "creme", "fiole"),
    "armurier": ("Kraxx — Armes", "", "fer", (38, 38, 42), "laiton", "epees"),
    "barbier": ("Le Polisseur de Cornes", "", "peint", (92, 26, 32), "or", "corne"),
    "poste": ("Poste ailée", "Lettres & colis", "peint", (28, 46, 92), "or", "enveloppe"),
    "couture": ("Grisette — Capes & Ailes", "", "peint", (72, 32, 64), "creme", "ciseaux"),
    "capitainerie": ("Capitainerie", "Port de Cendre", "bois", (54, 40, 30), "or", "ancre"),
    "epices": ("Épices de Zébuline", "", "peint", (150, 92, 34), "brun", "mortier"),
    "poissonnerie": ("Poissons de Lave", "Moloka", "peint", (30, 62, 98), "creme", "poisson"),
    "inventeur": ("Zigomar — Inventions", "", "bois", (64, 46, 30), "laiton", "engrenage"),
}

INKS = {"or": ((252, 216, 120), (186, 126, 40)), "laiton": ((240, 214, 140), (160, 116, 50)), "creme": ((246, 236, 210), (220, 200, 160)),
        "rouge": ((236, 70, 40), (160, 26, 20)), "soufre": ((246, 230, 110), (210, 170, 40)), "brun": ((70, 34, 20), (46, 22, 12))}


def _split_title(pa, title, size_max, width):
    if " — " in title:
        a, b = title.split(" — ", 1)
        return [a, b], True
    if pa.text_size(title, size_max)[0] <= width:
        return [title], False
    words = title.split(" ")
    if len(words) < 2:
        return [title], False
    best, bw = None, 1e9
    for k in range(1, len(words)):
        l1, l2 = " ".join(words[:k]), " ".join(words[k:])
        w_ = max(pa.text_size(l1, size_max)[0], pa.text_size(l2, size_max)[0])
        if w_ < bw:
            best, bw = [l1, l2], w_
    return best, False


def enseigne(key):
    title, sub, style, bg, ink, emb = ENSEIGNES[key]
    W, H = 512, 256
    seed = 7300 + sorted(ENSEIGNES).index(key)
    R = rng(seed)
    pa = Paint(W, H, 2, bg=bg, seed=seed)
    yy, xx = np.mgrid[0:pa.h, 0:pa.w].astype(np.float32) / pa.K
    big = pa.w
    if style == "bois":
        g = tn(R, big, (8, 16, 32, 64, 128), 0.65, oy=(1, 2, 4, 8, 16))[:pa.h, :pa.w]
        rings = np.sin((g * 9 + yy / 23.0) * TAU) * 0.5 + 0.5
        wood = np.array(bg, np.float32) / 255.0 * (0.72 + 0.4 * g[..., None]) * (0.9 + 0.12 * rings[..., None])
        for yp in (86, 171):
            wood = wood * (1 - 0.6 * np.exp(-((yy - yp) / 1.4) ** 2))[..., None]
        pa.rgb = wood.astype(np.float32)
        pa.rect(4, 4, W - 4, H - 4, (0, 0, 0), alpha=0, ol=0)
        pa.outline([(10, 10), (W - 10, 10), (W - 10, H - 10), (10, H - 10)], 3.0, (30, 18, 10))
        for (x, y) in ((12, 12), (W - 12, 12), (12, H - 12), (W - 12, H - 12)):
            sx, sy = (1 if x < W / 2 else -1), (1 if y < H / 2 else -1)
            pa.poly([(x - 6 * sx, y - 6 * sy), (x + 44 * sx, y - 6 * sy), (x + 30 * sx, y + 6 * sy), (x + 6 * sx, y + 6 * sy), (x + 6 * sx, y + 30 * sy), (x - 6 * sx, y + 44 * sy)],
                    (44, 42, 46), shade=0.7, depth=2.5, ol=1.2)
            pa.ell(x + 12 * sx, y + 12 * sy, 3, 3, (90, 86, 84), shade=0.8, depth=1.5, ol=0.8)
    elif style == "fer":
        hm = tn(R, big, (16, 32, 64, 128), 0.6)[:pa.h, :pa.w]
        pa.rgb = (np.array(bg, np.float32) / 255.0 * (0.8 + 0.4 * hm[..., None])).astype(np.float32)
        rust = smooth(0.66, 0.8, tn(R, big, (8, 16, 32), 0.6)[:pa.h, :pa.w])
        pa.rgb = mix(pa.rgb, np.array((0.36, 0.2, 0.12), np.float32) * (0.8 + 0.4 * hm[..., None]), rust * 0.4)
        pa.outline([(9, 9), (W - 9, 9), (W - 9, H - 9), (9, H - 9)], 4.0, (20, 20, 22))
        pa.outline([(16, 16), (W - 16, 16), (W - 16, H - 16), (16, H - 16)], 1.6, (130, 110, 70))
        for k in range(9):
            for y in (24, H - 24):
                pa.ell(30 + k * (W - 60) / 8, y, 4.2, 4.2, (90, 88, 92), shade=0.9, depth=1.5, ol=0.8)
    else:
        b = tn(R, big, (16, 32, 64, 128), 0.7, oy=(8, 16, 32, 64))[:pa.h, :pa.w]
        pa.rgb = (np.array(bg, np.float32) / 255.0 * (0.86 + 0.24 * b[..., None])).astype(np.float32)
        fr = INKS[ink][0] if ink != "brun" else (60, 30, 18)
        pa.outline([(12, 12), (W - 12, 12), (W - 12, H - 12), (12, H - 12)], 2.4, fr, alpha=0.95)
        pa.outline([(18, 18), (W - 18, 18), (W - 18, H - 18), (18, H - 18)], 1.0, fr, alpha=0.8)
        for (x, y) in ((18, 18), (W - 18, 18), (18, H - 18), (W - 18, H - 18)):
            pa.ell(x, y, 6, 6, fr, shade=0.5, depth=1.5, ol=1.0)
    # médaillon et emblème
    ex, ey, es = 104, 128, 66
    med = (np.array(bg) * 0.6 + 20).astype(int)
    pa.ell(ex, ey, 84, 84, tuple(int(v) for v in med), shade=0.5, depth=6, ol=2.0)
    pa.ell(ex, ey, 84, 84, (0, 0, 0), shade=0, ol=0, alpha=0)
    pa.outline(ellp(ex, ey, 78, 78, n=72), 1.4, INKS[ink][0] if ink != "brun" else (60, 30, 18), alpha=0.8)
    EMBLEMS[emb](pa, ex, ey, es)
    # le nom
    tx0, tx1 = 196, W - 26
    tw = tx1 - tx0
    lines, dash = _split_title(pa, title, 54, tw)
    size = 54
    while size > 22 and max(pa.text_size(l_, size)[0] for l_ in lines) > tw:
        size -= 2
    if dash:
        size2 = int(size * 0.7)
        while pa.text_size(lines[1], size2)[0] > tw and size2 > 18:
            size2 -= 2
    hi, lo = INKS[ink]
    tcx = (tx0 + tx1) / 2
    has_sub = bool(sub)
    if len(lines) == 1:
        ys = [112 if has_sub else 128]
        sizes = [size]
    elif dash:
        ys = [96, 160]
        sizes = [size, size2]
    else:
        ys = [94 if has_sub else 102, 152 if has_sub else 160]
        sizes = [size, size]
    st_col = (24, 14, 10) if ink != "brun" else (236, 206, 150)
    for l_, y_, sz in zip(lines, ys, sizes):
        pa.text((tcx, y_), l_, sz, hi, stroke=2.2 if ink != "brun" else 1.2, stroke_col=st_col, grad=(hi, lo, 90, (y_ - sz * 0.4, y_ + sz * 0.4)),
                shadow=(2.5, 3.0, 0.55), shade=0.6)
    if dash:
        for sx in (-1, 1):
            pa.line([(tcx + sx * 30, 128), (tcx + sx * 90, 128)], hi, 1.6)
        pa.ell(tcx, 128, 4, 4, hi, shade=0.5, depth=1, ol=0.8)
    if has_sub:
        pa.text((tcx, 206 if len(lines) > 1 else 176), sub, 21, INKS[ink][0] if ink != "brun" else (60, 30, 18), italic=True, bold=False,
                stroke=1.0 if ink != "brun" else 0, stroke_col=st_col, alpha=0.95)
    # patine
    rgb, cov = pa.result()
    rr = rng(seed + 1)
    wear = tn(rr, W, (8, 16, 32, 64), 0.6)[:H, :W]
    dirt = smooth(0.55, 0.85, tn(rr, W, (4, 8, 16), 0.6)[:H, :W])
    rgb = rgb * (0.9 + 0.12 * wear[..., None]) * (1 - 0.12 * dirt[..., None])
    yy2, xx2 = np.mgrid[0:H, 0:W].astype(np.float32)
    vig = 1 - 0.22 * ((np.abs(xx2 / W - 0.5) * 2) ** 6 + (np.abs(yy2 / H - 0.5) * 2) ** 6)
    rgb = rgb * vig[..., None]
    if style == "peint":
        chips = smooth(0.8, 0.82, tn(rr, W, (32, 64, 128), 0.6)[:H, :W]) * smooth(0.5, 0.2, np.minimum(np.minimum(xx2, W - xx2), np.minimum(yy2, H - yy2)) / 40)
        rgb = mix(rgb, C(0.32, 0.22, 0.14), chips * 0.8)
    save_rgb(rgb, "enseigne_%s.png" % key)


def enseignes():
    for k in ENSEIGNES:
        enseigne(k)


# =================================================================== affiches, plan, contrat

def paper_bg(R, W, H, base=(0.87, 0.8, 0.64), stains=0.5, edge=0.35):
    """Papier ou parchemin vieilli (non raccordable) : fibres, nuages, taches, bords roussis."""
    big = max(W, H)
    n = tn(R, big, (2, 4, 8, 16, 32), 0.6)[:H, :W]
    f = tn(R, big, (64, 128, 256, 512), 0.75)[:H, :W]
    fib = tn(R, big, (128, 256, 512), 0.7, oy=(16, 32, 64))[:H, :W]
    col = np.array(base, np.float32)[None, None, :] * (0.9 + 0.16 * n[..., None]) * (0.96 + 0.06 * f[..., None]) * (0.97 + 0.05 * fib[..., None])
    st = smooth(0.62, 0.8, tn(R, big, (4, 8, 16, 32), 0.6)[:H, :W]) * stains
    ring = np.exp(-((tn(R, big, (4, 8, 16), 0.6)[:H, :W] - 0.66) / 0.012) ** 2) * stains
    col = mix(col, col * C(0.86, 0.76, 0.6), st * 0.6)
    col = col * (1 - 0.12 * ring[..., None])
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    d = np.minimum(np.minimum(xx, W - 1 - xx), np.minimum(yy, H - 1 - yy))
    burn = np.exp(-d / (14 + 20 * n)) * edge
    col = mix(col, col * C(0.62, 0.48, 0.32), np.clip(burn, 0, 1))
    return col.astype(np.float32)


def wrap_lines(pa, text, size, width, italic=True, bold=False):
    words = text.split(" ")
    lines, cur = [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if pa.text_size(t, size, italic, bold)[0] <= width or not cur:
            cur = t
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def _poster_finish(pa, R, rgb_paper_mix=0.0, folds=True):
    rgb, cov = pa.result()
    H, W = rgb.shape[:2]
    big = max(W, H)
    ink_n = tn(R, big, (64, 128, 256, 512), 0.7)[:H, :W]
    rgb = rgb * (0.94 + 0.1 * ink_n[..., None])
    if folds:
        yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
        for (ax, v) in ((0, W / 2), (1, H / 3), (1, 2 * H / 3)):
            dd = np.abs((xx if ax == 0 else yy) - v)
            rgb = rgb * (1 - 0.07 * np.exp(-(dd / 1.5) ** 2))[..., None] * (1 + 0.03 * np.exp(-((dd - 3) / 2.0) ** 2))[..., None]
    dirt = smooth(0.6, 0.85, tn(R, big, (4, 8, 16, 32), 0.6)[:H, :W])
    rgb = rgb * (1 - 0.1 * dirt[..., None])
    return rgb


def _champion(pa, cx, by, s, col=(28, 20, 18)):
    """Silhouette d'un colosse cornu qui lève les poings (Gorgoth)."""
    k = s
    body = [(cx - 0.62 * k, by), (cx - 0.5 * k, by - 0.9 * k), (cx - 0.42 * k, by - 1.3 * k), (cx - 0.7 * k, by - 2.0 * k), (cx - 0.8 * k, by - 2.55 * k),
            (cx - 1.25 * k, by - 2.95 * k), (cx - 1.42 * k, by - 3.55 * k), (cx - 1.2 * k, by - 3.62 * k), (cx - 1.0 * k, by - 3.1 * k),
            (cx - 0.55 * k, by - 2.9 * k), (cx - 0.3 * k, by - 3.05 * k), (cx - 0.22 * k, by - 3.4 * k),
            (cx + 0.22 * k, by - 3.4 * k), (cx + 0.3 * k, by - 3.05 * k), (cx + 0.55 * k, by - 2.9 * k), (cx + 1.0 * k, by - 3.1 * k),
            (cx + 1.2 * k, by - 3.62 * k), (cx + 1.42 * k, by - 3.55 * k), (cx + 1.25 * k, by - 2.95 * k), (cx + 0.8 * k, by - 2.55 * k),
            (cx + 0.7 * k, by - 2.0 * k), (cx + 0.42 * k, by - 1.3 * k), (cx + 0.5 * k, by - 0.9 * k), (cx + 0.62 * k, by), (cx + 0.22 * k, by),
            (cx + 0.12 * k, by - 0.95 * k), (cx - 0.12 * k, by - 0.95 * k), (cx - 0.22 * k, by)]
    pa.poly(body, col, sm=1, shade=0, ol=0)
    pa.ell(cx, by - 3.55 * k, 0.3 * k, 0.32 * k, col, shade=0, ol=0)
    for sx in (-1, 1):
        pa.ell(cx + sx * 1.32 * k, by - 3.75 * k, 0.2 * k, 0.2 * k, col, shade=0, ol=0)
        horn = bez((cx + sx * 0.18 * k, by - 3.7 * k), (cx + sx * 0.75 * k, by - 3.75 * k), (cx + sx * 0.85 * k, by - 4.3 * k), (cx + sx * 0.5 * k, by - 4.55 * k), 20)
        pa.tubep(horn, 0.24 * k, col, w1=0.02 * k, shade=0, ol=0)
    pa.poly([(cx - 0.45 * k, by - 1.3 * k), (cx + 0.45 * k, by - 1.3 * k), (cx + 0.5 * k, by - 1.12 * k), (cx - 0.5 * k, by - 1.12 * k)], (150, 30, 24), shade=0, ol=0)
    tail = bez((cx + 0.3 * k, by - 1.2 * k), (cx + 1.2 * k, by - 1.0 * k), (cx + 1.0 * k, by - 0.2 * k), (cx + 1.5 * k, by - 0.3 * k), 20)
    pa.tubep(tail, 0.12 * k, col, w1=0.05 * k, shade=0, ol=0)
    pa.poly([(cx + 1.42 * k, by - 0.5 * k), (cx + 1.75 * k, by - 0.3 * k), (cx + 1.42 * k, by - 0.12 * k)], col, shade=0, ol=0)


def affiche_tournoi():
    """Affiche du Grand Tournoi des Cornes : imprimée en rouge, noir et orangé sur papier crème ;
    soleil rayonnant derrière la silhouette du champion cornu qui lève les poings, sur les
    arcades de l'arène ; textes de l'annonce ; plis, taches, bords roussis."""
    W, H = 512, 768
    R = rng(7401)
    pa = Paint(W, H, 2, seed=7401)
    pa.rgb[:] = paper_bg(R, pa.w, pa.h, (0.9, 0.83, 0.66), 0.35, 0.3)
    red, black, orange = (160, 30, 22), (30, 22, 20), (218, 112, 36)
    pa.outline([(16, 16), (W - 16, 16), (W - 16, H - 16), (16, H - 16)], 3.0, red)
    pa.outline([(24, 24), (W - 24, 24), (W - 24, H - 24), (24, H - 24)], 1.2, red)
    cx, cy = W / 2, 382
    for k in range(32):
        a0 = k * TAU / 32
        a1 = a0 + TAU / 64
        pa.poly([(cx, cy), (cx + math.cos(a0) * 300, cy + math.sin(a0) * 300), (cx + math.cos(a1) * 300, cy + math.sin(a1) * 300)],
                orange if k % 2 == 0 else (238, 190, 110), shade=0, ol=0, alpha=0.85)
    mask = Image.new("L", (pa.w, pa.h), 0)
    ImageDraw.Draw(mask).rectangle((0, 0, pa.w, int(178 * pa.K)), fill=255)
    ImageDraw.Draw(mask).rectangle((0, int(560 * pa.K), pa.w, pa.h), fill=255)
    ImageDraw.Draw(mask).rectangle((0, 0, int(26 * pa.K), pa.h), fill=255)
    ImageDraw.Draw(mask).rectangle((int((W - 26) * pa.K), 0, pa.w, pa.h), fill=255)
    paper2 = paper_bg(rng(7402), pa.w, pa.h, (0.9, 0.83, 0.66), 0.35, 0.3)
    m = np.asarray(mask, np.float32)[..., None] / 255.0
    pa.rgb = pa.rgb * (1 - m) + paper2 * m
    pa.text((W / 2, 74), "GRAND TOURNOI", 50, red, spacing=2, shadow=None)
    pa.text((W / 2, 136), "des Cornes", 64, black, italic=True)
    pa.ell(cx, cy, 70, 70, (246, 214, 120), shade=0, ol=0)
    # arcades de l'arène
    pa.rect(40, 470, W - 40, 560, black, shade=0, ol=0)
    for k in range(8):
        x = 58 + k * 52
        pa.poly(arch_pts(x, x + 34, 512, 560, n=12), (238, 190, 110), shade=0, ol=0)
    pa.rect(40, 462, W - 40, 472, red, shade=0, ol=0)
    _champion(pa, cx, 462, 62)
    pa.text((W / 2, 598), "à l'Arène des Cornes", 30, black, italic=True, bold=False)
    pa.text((W / 2, 640), "Quatre manches · la Corne d'or au vainqueur", 19, red, bold=True)
    pa.text((W / 2, 676), "Saurez-vous vaincre Gorgoth le Cornu ?", 22, black, italic=True, bold=True)
    pa.text((W / 2, 722), "Inscriptions auprès de Madame Hurla", 17, black, bold=False)
    rgb = _poster_finish(pa, R)
    save_rgb(rgb, "affiche_tournoi.png")


def _skyline(pa, base_y, W, col, R):
    pts = [(0, base_y + 60), (0, base_y)]
    x = 0
    while x < W:
        kind = R.random()
        w = R.uniform(18, 46)
        h = R.uniform(30, 90)
        if kind < 0.35:
            pts += [(x, base_y - h * 0.6), (x + w * 0.5, base_y - h * 1.5), (x + w, base_y - h * 0.6)]
        elif kind < 0.6:
            pts += [(x, base_y - h), (x + w * 0.25, base_y - h), (x + w * 0.25, base_y - h - 8), (x + w * 0.5, base_y - h - 8), (x + w * 0.5, base_y - h),
                    (x + w, base_y - h)]
        else:
            pts += [(x, base_y - h * 0.5), (x + w * 0.5, base_y - h * 0.8), (x + w, base_y - h * 0.5)]
        x += w
    pts += [(W, base_y), (W, base_y + 60)]
    pa.poly(pts, col, shade=0, ol=0)


def affiche_fete():
    """Affiche de la Nuit des Lanternes : ciel de nuit violet-bleu, feux d'artifice, lanternes qui
    s'envolent au-dessus des flèches de la cité et du volcan ; titre d'or, programme de la fête."""
    W, H = 512, 768
    R = rng(7403)
    pa = Paint(W, H, 2, seed=7403)
    pa.rgb[:] = paper_bg(R, pa.w, pa.h, (0.9, 0.84, 0.68), 0.3, 0.3)
    m = 22
    pa.rect(m, m, W - m, 600, (20, 18, 52), grad=((16, 14, 46), (92, 34, 70), 90, (m, 600)), shade=0, ol=0)
    for _ in range(140):
        x, y = R.uniform(m, W - m), R.uniform(m, 420)
        r = R.uniform(0.6, 1.5)
        pa.ell(x, y, r, r, (250, 246, 220), shade=0, ol=0, alpha=R.uniform(0.4, 1.0))
    for (fx, fy, rr_, c) in ((150, 190, 78, (255, 210, 90)), (360, 140, 64, (255, 110, 70)), (300, 290, 52, (130, 220, 255)), (110, 330, 40, (255, 240, 200))):
        for k in range(28):
            a = k * TAU / 28
            for j in range(6):
                t = 0.35 + j * 0.13
                pa.ell(fx + math.cos(a) * rr_ * t, fy + math.sin(a) * rr_ * t + t * t * 8, 1.6 - j * 0.15, 1.6 - j * 0.15, c, shade=0, ol=0, alpha=1 - j * 0.12)
        pa.glow(fx, fy, rr_ * 0.6, tuple(int(v * 0.3) for v in c), 0.5)
    for k in range(5):
        pa.ell(176 + k * 9, 392 - k * 26, 14 + k * 7, 9 + k * 4, (70, 40, 60), shade=0, ol=0, alpha=0.35)
    pa.glow(172, 412, 40, (140, 50, 20), 0.6)
    pa.poly([(m, 600), (m, 510), (80, 474), (148, 418), (196, 418), (262, 500), (330, 600)], (40, 20, 34), shade=0, ol=0)
    pa.poly([(150, 418), (194, 418), (186, 426), (158, 426)], (250, 120, 40), shade=0, ol=0)
    for a, b in (((166, 426), (130, 520)), ((182, 426), (214, 530))):
        pa.line(bez(a, ((a[0] + b[0]) / 2 + 8, (a[1] + b[1]) / 2), b), (230, 90, 30), 2.2)
    _skyline(pa, 548, W, (24, 16, 30), R)
    pa.rect(m, 560, W - m, 600, (24, 16, 30), shade=0, ol=0)
    for _ in range(26):
        x, y = R.uniform(40, W - 40), R.uniform(470, 590)
        pa.rect(x, y, x + 3, y + 4, (255, 200, 90), shade=0, ol=0)
    for k in range(26):
        x = R.uniform(50, W - 50)
        y = R.uniform(200, 520)
        sc = 0.5 + (y - 200) / 320 * 0.9
        pa.glow(x, y, 16 * sc, (160, 70, 10), 0.55)
        pa.poly([(x - 6 * sc, y - 8 * sc), (x + 6 * sc, y - 8 * sc), (x + 8 * sc, y + 6 * sc), (x - 8 * sc, y + 6 * sc)], (250, 150, 50), sm=1, shade=0, ol=0)
        pa.ell(x, y, 3 * sc, 4 * sc, (255, 236, 160), shade=0, ol=0)
    pa.text((W / 2, 72), "La Nuit", 56, (246, 202, 96), italic=True, stroke=2, stroke_col=(40, 20, 30), grad=((255, 230, 140), (220, 150, 50), 90, (50, 95)))
    pa.text((W / 2, 140), "des Lanternes", 58, (246, 202, 96), italic=True, stroke=2, stroke_col=(40, 20, 30), grad=((255, 230, 140), (220, 150, 50), 90, (115, 165)))
    ink = (40, 26, 30)
    pa.text((W / 2, 636), "Grand-Place des Lanternes · après 20 h", 20, (130, 30, 30), bold=True)
    pa.text((W / 2, 672), "Musique, danses et feux d'artifice de Zigomar", 17, ink, italic=True, bold=False)
    pa.text((W / 2, 708), "Allumez les sept Grandes Lanternes !", 19, ink, bold=True)
    pa.outline([(m, m), (W - m, m), (W - m, 600), (m, 600)], 2.0, (40, 26, 30))
    rgb = _poster_finish(pa, R)
    save_rgb(rgb, "affiche_fete.png")


def plan_ville():
    """Plan illustré de Pandémonia, à l'encre et au lavis sur parchemin : la Citadelle et son
    palais au centre, le Cercle de Feu (fossé de lave) et ses quatre ponts, la Haute-Ville et ses
    grands édifices, la Basse-Ville et ses quartiers, les remparts ; le Port de Cendre au
    nord-est, le Grand Brasier au sud-ouest et ses coulées, le Bois de Cendre, les plages de sable
    noir, les sources de soufre, les ruines ; rose des vents, titre, échelle."""
    W, H = 1024, 768
    R = rng(7404)
    pa = Paint(W, H, 2, seed=7404)
    pa.ink = (52, 34, 24)
    pa.rgb[:] = paper_bg(R, pa.w, pa.h, (0.88, 0.8, 0.62), 0.45, 0.4)
    ink = (52, 34, 24)
    sea = (96, 132, 136)
    pa.rect(30, 30, W - 30, H - 30, sea, shade=0, ol=0, alpha=0.5)
    # l'île
    cx0, cy0 = 520, 400
    isl = []
    for k in range(64):
        a = k / 64 * TAU
        r = 345 + 25 * math.sin(a * 3 + 1) + 18 * math.sin(a * 7 + 2) + R.uniform(-8, 8)
        isl.append((cx0 + math.cos(a) * r * 1.22, cy0 + math.sin(a) * r * 0.95))
    pa.poly(isl, (214, 196, 160), sm=2, shade=0, ol=2.0, inkc=ink)
    coast = chaikin(isl, 2)
    for k in range(3):
        off = 10 + k * 10
        ring = [(cx0 + (x - cx0) * (1 + off / 400), cy0 + (y - cy0) * (1 + off / 380)) for x, y in coast]
        pa.outline(ring, 1.0, (70, 90, 96), alpha=0.5 - k * 0.12)
    # sable noir (sud-est et est)
    for k in range(64 * 4):
        if not (0.05 < (k / 256) < 0.3):
            continue
        x, y = coast[k % len(coast)]
        pa.ell(x - (x - cx0) * 0.02, y - (y - cy0) * 0.02, 1.4, 1.4, (40, 34, 30), shade=0, ol=0)
    # le volcan au sud-ouest et ses coulées
    vx, vy = 230, 600
    pa.poly([(vx - 130, vy + 60), (vx - 30, vy - 70), (vx + 30, vy - 70), (vx + 140, vy + 60)], (150, 110, 90), sm=1, shade=0, ol=1.6, inkc=ink)
    pa.ell(vx, vy - 68, 30, 8, (120, 40, 26), shade=0, ol=1.4, inkc=ink)
    for k in range(6):
        pa.ell(vx - 10 + k * 7, vy - 90 - k * 16, 14 + k * 4, 9 + k * 3, (120, 110, 104), shade=0, ol=0, alpha=0.4)
    for path in ((vx - 10, vy - 60, vx - 120, vy + 140), (vx + 10, vy - 60, vx + 60, vy + 150), (vx - 20, vy - 60, vx - 200, vy + 60)):
        a0, b0, a1, b1 = path
        pts = [(a0 + (a1 - a0) * t + math.sin(t * 7) * 8, b0 + (b1 - b0) * t) for t in np.linspace(0, 1, 20)]
        pa.line(pts, (196, 60, 30), 3.0)
    pa.text((vx, vy + 84), "Le Grand Brasier", 20, ink, italic=True, bold=True)
    # le champ de lave à l'est du volcan
    for k in range(40):
        x, y = R.uniform(330, 420), R.uniform(600, 690)
        pa.line([(x, y), (x + R.uniform(-8, 8), y + R.uniform(-6, 6))], (180, 70, 40), 1.2)
    pa.text((375, 712), "Champ de lave", 14, ink, italic=True, bold=False)
    # sources de soufre
    for k in range(12):
        x, y = 342 + R.uniform(-24, 24), 566 + R.uniform(-10, 10)
        pa.ell(x, y, 3, 3, (220, 200, 60), shade=0, ol=0.8, inkc=ink)
    pa.text((352, 590), "Sources de soufre", 13, ink, italic=True, bold=False)
    # bois de cendre au sud-est
    for k in range(34):
        x, y = 790 + R.uniform(-70, 70), 640 + R.uniform(-40, 40)
        pa.line([(x, y), (x, y + 8)], (60, 40, 30), 1.2)
        pa.poly([(x - 6, y + 2), (x, y - 12), (x + 6, y + 2)], (70, 50, 46), shade=0, ol=0.8, inkc=ink)
        pa.ell(x + 1, y - 4, 1.4, 1.4, (220, 90, 30), shade=0, ol=0)
    pa.text((800, 700), "Bois de Cendre", 16, ink, italic=True, bold=True)
    # ruines au nord-ouest
    for k in range(9):
        x, y = 210 + R.uniform(-50, 50), 160 + R.uniform(-26, 26)
        pa.line([(x, y), (x + R.uniform(10, 24), y)], (90, 76, 64), 2.0)
        pa.line([(x, y), (x, y - R.uniform(4, 12))], (90, 76, 64), 2.0)
    pa.text((210, 200), "Ruines de l'Ancien Pandémonium", 14, ink, italic=True, bold=False)
    # le port au nord-est
    px_, py_ = 850, 150
    for k in range(3):
        a = math.radians(-40 + k * 30)
        pa.tubep([(px_ - 60 + k * 30, py_ + 70 - k * 10), (px_ - 60 + k * 30 + math.cos(a) * 70, py_ + 70 - k * 10 + math.sin(a) * 70)], 8, (130, 120, 110), shade=0, ol=1.2, inkc=ink)
    for (bx, by) in ((900, 100), (940, 160), (870, 60), (960, 230)):
        pa.poly([(bx - 14, by), (bx + 14, by), (bx + 9, by + 7), (bx - 9, by + 7)], (60, 40, 30), shade=0, ol=1.0, inkc=ink)
        pa.poly([(bx - 1, by - 2), (bx - 1, by - 22), (bx + 11, by - 4)], (34, 30, 30), shade=0, ol=0.8, inkc=ink)
        pa.ell(bx + 12, by - 2, 1.6, 1.6, (220, 40, 30), shade=0, ol=0)
    pa.rect(784, 70, 794, 100, (210, 200, 180), shade=0, ol=1.0, inkc=ink)
    pa.glow(789, 66, 8, (200, 30, 20), 1.0)
    pa.ell(789, 66, 3, 3, (240, 60, 40), shade=0, ol=0)
    pa.text((866, 262), "Port de Cendre", 18, ink, italic=True, bold=True, stroke=2.2, stroke_col=(214, 198, 160))
    pa.text((930, 300), "Rade", 14, (40, 60, 70), italic=True, bold=False)
    pa.text((930, 318), "de Cendre", 14, (40, 60, 70), italic=True, bold=False)
    pa.text((800, 130), "Taverne", 11, ink, italic=True, bold=False)
    pa.text((755, 92), "Phare", 11, ink, italic=True, bold=False)
    # la cité : remparts, quartiers
    cx, cy = 560, 390
    pa.ell(cx, cy, 262, 230, (204, 186, 150), shade=0, ol=2.4, inkc=ink)
    pa.ell(cx, cy, 255, 223, (0, 0, 0), shade=0, ol=1.0, alpha=0, inkc=ink)
    for k in range(16):
        a = k / 16 * TAU
        pa.rect(cx + math.cos(a) * 262 - 6, cy + math.sin(a) * 230 - 6, cx + math.cos(a) * 262 + 6, cy + math.sin(a) * 230 + 6, (170, 150, 120), shade=0, ol=1.2, inkc=ink)
    pa.ell(cx, cy, 160, 140, (196, 176, 140), shade=0, ol=2.0, inkc=ink)
    for k in range(12):
        a = k / 12 * TAU + 0.26
        pa.rect(cx + math.cos(a) * 160 - 5, cy + math.sin(a) * 140 - 5, cx + math.cos(a) * 160 + 5, cy + math.sin(a) * 140 + 5, (170, 150, 120), shade=0, ol=1.0, inkc=ink)
    # rues et maisons
    houses_r = rng(7405)
    for k in range(8):
        a = k / 8 * TAU
        pa.line([(cx + math.cos(a) * 92, cy + math.sin(a) * 80), (cx + math.cos(a) * 262, cy + math.sin(a) * 230)], (150, 130, 100), 5.0)
    for _ in range(420):
        a = houses_r.uniform(0, TAU)
        rr_ = houses_r.uniform(0.38, 0.97)
        if abs(((a / TAU * 8) % 1) - 0.5) > 0.42:
            continue
        rx_, ry_ = rr_ * 262, rr_ * 230
        if 0.58 < rr_ < 0.66:
            continue
        x, y = cx + math.cos(a) * rx_, cy + math.sin(a) * ry_
        w_, h_ = houses_r.uniform(5, 10), houses_r.uniform(4, 8)
        c = (150, 60, 44) if houses_r.random() < 0.5 else (90, 84, 88)
        pa.rect(x - w_ / 2, y - h_ / 2, x + w_ / 2, y + h_ / 2, c, shade=0, ol=0.7, inkc=ink)
    # grands édifices et noms
    labels = []

    def bldg(a_deg, rr_, label, draw, dy_lab=26, size=13):
        a = math.radians(a_deg)
        x, y = cx + math.cos(a) * 262 * rr_, cy + math.sin(a) * 230 * rr_
        draw(x, y)
        labels.append(((x, y + dy_lab), label, size))
    def tower_block(x, y):
        pa.rect(x - 16, y - 10, x + 16, y + 12, (120, 110, 104), shade=0, ol=1.2, inkc=ink)
        for sx in (-1, 1):
            pa.rect(x + sx * 16 - 4, y - 18, x + sx * 16 + 4, y + 12, (110, 100, 96), shade=0, ol=1.0, inkc=ink)
            pa.poly([(x + sx * 16 - 5, y - 18), (x + sx * 16, y - 28), (x + sx * 16 + 5, y - 18)], (70, 60, 70), shade=0, ol=1.0, inkc=ink)
    def cathedral(x, y):
        pa.poly([(x - 22, y + 12), (x - 22, y - 8), (x, y - 20), (x + 22, y - 8), (x + 22, y + 12)], (110, 100, 96), shade=0, ol=1.2, inkc=ink)
        pa.poly([(x - 5, y - 18), (x, y - 40), (x + 5, y - 18)], (80, 70, 74), shade=0, ol=1.0, inkc=ink)
        pa.glow(x, y, 14, (180, 60, 10), 0.5)
        pa.ell(x, y - 2, 5, 5, (240, 150, 40), shade=0, ol=1.0, inkc=ink)
    def place(x, y):
        pa.ell(x, y, 22, 16, (220, 200, 150), shade=0, ol=1.2, inkc=ink)
        for k in range(7):
            a = k / 7 * TAU
            pa.ell(x + math.cos(a) * 15, y + math.sin(a) * 10, 2.2, 2.2, (250, 180, 60), shade=0, ol=0.6, inkc=ink)
    def library(x, y):
        pa.rect(x - 20, y - 10, x + 20, y + 10, (120, 110, 100), shade=0, ol=1.2, inkc=ink)
        pa.poly([(x - 22, y - 10), (x, y - 22), (x + 22, y - 10)], (90, 60, 50), shade=0, ol=1.0, inkc=ink)
    def market(x, y):
        for k in range(6):
            pa.rect(x - 22 + (k % 3) * 15, y - 10 + (k // 3) * 12, x - 12 + (k % 3) * 15, y - 2 + (k // 3) * 12,
                    (200, 80, 50) if k % 2 else (220, 190, 90), shade=0, ol=0.8, inkc=ink)
    def arena(x, y):
        pa.ell(x, y, 30, 22, (150, 130, 110), shade=0, ol=1.4, inkc=ink)
        pa.ell(x, y, 18, 12, (220, 196, 150), shade=0, ol=1.2, inkc=ink)
    def thermes(x, y):
        pa.rect(x - 18, y - 9, x + 18, y + 9, (130, 120, 110), shade=0, ol=1.2, inkc=ink)
        pa.ell(x - 7, y, 6, 4, (210, 200, 90), shade=0, ol=0.8, inkc=ink)
        pa.ell(x + 8, y, 5, 4, (160, 200, 190), shade=0, ol=0.8, inkc=ink)
        for k in range(4):
            pa.ell(x - 30 + k * 6, y + 20 + (k % 2) * 4, 3.4, 3.4, (90, 110, 60), shade=0, ol=0.6, inkc=ink)
    def artisans(x, y):
        for k in range(4):
            pa.rect(x - 16 + k * 8, y - 6, x - 10 + k * 8, y + 6, (140, 100, 70), shade=0, ol=0.8, inkc=ink)
        pa.glow(x + 10, y, 6, (180, 80, 10), 0.6)
    bldg(225, 0.47, "Académie Infernale", tower_block, 30)
    bldg(90, 0.47, "Cathédrale-Forge", cathedral, 30)
    bldg(0, 0.48, "Grand-Place", place, 26)
    bldg(180, 0.48, "Bibliothèque", library, 26)
    bldg(315, 0.82, "Grand Marché", market, 24)
    bldg(45, 0.8, "Arène des Cornes", arena, 34)
    bldg(112, 0.8, "Thermes de Soufre", thermes, 36)
    bldg(180, 0.82, "Artisans", artisans, 24)
    pa.text((cx + 58, cy + 198), "Jardins de Cendre", 11, ink, italic=True, bold=False, stroke=2, stroke_col=(214, 198, 160))
    pa.text((cx + 196, cy + 84), "Basse-Ville", 14, (110, 70, 50), italic=True, bold=True, stroke=2, stroke_col=(214, 198, 160))
    pa.text((cx - 112, cy + 66), "Haute-Ville", 13, (110, 70, 50), italic=True, bold=True, stroke=2, stroke_col=(214, 198, 160))
    # le Cercle de Feu et la Citadelle
    pa.ell(cx, cy, 92, 80, (210, 70, 30), shade=0, ol=1.6, inkc=ink, grad=((240, 120, 40), (190, 40, 20), 90))
    pa.glow(cx, cy, 90, (120, 40, 10), 0.25)
    pa.ell(cx, cy, 72, 62, (176, 160, 130), shade=0, ol=1.6, inkc=ink)
    for k in range(4):
        a = k * TAU / 4
        x0_, y0_ = cx + math.cos(a) * 66, cy + math.sin(a) * 57
        x1_, y1_ = cx + math.cos(a) * 98, cy + math.sin(a) * 86
        pa.tubep([(x0_, y0_), (x1_, y1_)], 10, (186, 170, 140), shade=0, ol=1.2, inkc=ink)
    pa.ell(cx, cy, 44, 36, (150, 136, 120), shade=0, ol=1.4, inkc=ink)
    for (dx, dy) in ((-18, 0), (18, 0), (0, -14), (0, 14), (0, 0)):
        h_ = 26 if (dx, dy) == (0, 0) else 16
        pa.rect(cx + dx - 5, cy + dy - h_ * 0.5, cx + dx + 5, cy + dy + 6, (110, 100, 104), shade=0, ol=1.0, inkc=ink)
        pa.poly([(cx + dx - 6, cy + dy - h_ * 0.5), (cx + dx, cy + dy - h_ * 0.5 - 12), (cx + dx + 6, cy + dy - h_ * 0.5)], (60, 50, 60), shade=0, ol=0.8, inkc=ink)
    for xy, lab, sz in labels:
        pa.text(xy, lab, sz, ink, italic=True, bold=True, stroke=2.2, stroke_col=(214, 198, 160))
    pa.text((cx + 104, cy - 92), "le Cercle de Feu", 12, (150, 40, 20), italic=True, bold=True, stroke=2, stroke_col=(214, 198, 160))
    pa.text((cx, cy + 32), "La Citadelle", 11, ink, italic=True, bold=True, stroke=1.8, stroke_col=(186, 172, 150))
    pa.text((cx, cy + 45), "le Palais", 9, ink, italic=True, bold=False, stroke=1.6, stroke_col=(186, 172, 150))
    # titre, rose des vents, échelle
    pa.rect(56, 46, 372, 124, (226, 210, 172), shade=0, ol=1.8, inkc=ink)
    pa.outline([(62, 52), (366, 52), (366, 118), (62, 118)], 0.8, ink)
    pa.text((214, 78), "Pandémonia", 40, (120, 30, 22), italic=True, bold=True)
    pa.text((214, 108), "Plan de la Cité · Île de Braise", 15, ink, italic=True, bold=False)
    rx, ry = 930, 640
    for k in range(8):
        a = k * TAU / 8 - math.pi / 2
        L = 54 if k % 2 == 0 else 30
        b1, b2 = a + 0.25, a - 0.25
        pa.poly([(rx, ry), (rx + math.cos(b1) * 10, ry + math.sin(b1) * 10), (rx + math.cos(a) * L, ry + math.sin(a) * L), (rx + math.cos(b2) * 10, ry + math.sin(b2) * 10)],
                (120, 30, 22) if k == 0 else ((60, 44, 34) if k % 2 == 0 else (200, 180, 140)), shade=0, ol=1.0, inkc=ink)
    pa.outline(ellp(rx, ry, 40, 40, n=48), 1.0, ink)
    for lab, a in (("N", -90), ("E", 0), ("S", 90), ("O", 180)):
        pa.text((rx + math.cos(math.radians(a)) * 70, ry + math.sin(math.radians(a)) * 70), lab, 16, ink, bold=True)
    pa.rect(60, 712, 127, 718, (60, 44, 34), shade=0, ol=1.0, inkc=ink)
    pa.rect(127, 712, 195, 718, (226, 210, 172), shade=0, ol=1.0, inkc=ink)
    pa.text((127, 700), "100 m", 13, ink, italic=True, bold=False)
    pa.text((905, 548), "Plages de sable noir", 13, ink, italic=True, bold=False)
    pa.outline([(30, 30), (W - 30, 30), (W - 30, H - 30), (30, H - 30)], 2.4, ink)
    pa.outline([(38, 38), (W - 38, 38), (W - 38, H - 38), (38, H - 38)], 0.8, ink)
    rgb = _poster_finish(pa, R, folds=True)
    save_rgb(rgb, "plan_ville.png")


def wax_seal(pa, cx, cy, r, R, col=(150, 22, 18)):
    pts = []
    for k in range(40):
        a = k / 40 * TAU
        rr_ = r * (1 + 0.08 * math.sin(a * 5 + 1) + R.uniform(-0.05, 0.05))
        pts.append((cx + math.cos(a) * rr_, cy + math.sin(a) * rr_))
    pa.poly(pts, col, sm=2, shade=0.9, depth=r * 0.12, ol=1.2, inkc=(60, 10, 8))
    pa.ell(cx, cy, r * 0.72, r * 0.72, tuple(int(c * 0.86) for c in col), shade=-0.6, depth=r * 0.06, ol=0)
    horned_flame(pa, cx, cy + r * 0.12, r * 0.42, gold=tuple(int(c * 1.15) for c in col), deep=tuple(int(c * 0.75) for c in col),
                 horn=tuple(int(c * 1.05) for c in col), ol=0.8)


def contrat():
    """Un vieux contrat sur parchemin : lettrine rouge, écriture penchée, petites ornementations ;
    le texte (drôle et gentil) de l'engagement, deux lignes de signature (l'une encore vide,
    l'autre paraphée), un sceau de cire rouge à cornes et son ruban."""
    W, H = 512, 768
    R = rng(7405)
    pa = Paint(W, H, 2, seed=7405)
    pa.rgb[:] = paper_bg(R, pa.w, pa.h, (0.86, 0.77, 0.58), 0.5, 0.45)
    ink = (44, 28, 20)
    red = (150, 34, 26)
    pa.outline([(24, 24), (W - 24, 24), (W - 24, H - 24), (24, H - 24)], 1.6, red, alpha=0.8)
    pa.outline([(30, 30), (W - 30, 30), (W - 30, H - 30), (30, H - 30)], 0.8, red, alpha=0.7)
    for (x, y) in ((30, 30), (W - 30, 30), (30, H - 30), (W - 30, H - 30)):
        sx, sy = (1 if x < W / 2 else -1), (1 if y < H / 2 else -1)
        pa.line(bez((x, y + 40 * sy), (x + 20 * sx, y + 20 * sy), (x + 40 * sx, y)), red, 1.4, alpha=0.8)
        pa.ell(x + 14 * sx, y + 14 * sy, 3, 3, red, shade=0, ol=0)
    pa.text((W / 2, 78), "Contrat", 58, ink, italic=True)
    pa.text((W / 2, 118), "passé en la Cité de Pandémonia", 17, ink, italic=True, bold=False)
    pa.line(bez((150, 134), (256, 146), (362, 134)), red, 1.6)
    body = ("Par le présent contrat, le soussigné s'engage à garder l'espoir en toute circonstance, à bien se couvrir "
            "dans les Cercles glacés, à ne jamais tirer la queue du juge Minos et à offrir trois gâteaux de miel à qui "
            "possède trois bouches.")
    body2 = ("En échange, la Cité de Pandémonia lui promet un grog de soufre bien chaud, une place au coin du feu et "
             "l'amitié éternelle de tous ses habitants.")
    x0, x1 = 58, W - 58
    y = 176
    # lettrine
    pa.rect(x0, y - 22, x0 + 58, y + 44, (160, 40, 30), shade=0, ol=1.4, inkc=ink, alpha=0.9)
    pa.text((x0 + 29, y + 12), "P", 52, (240, 214, 140), bold=True, italic=False, stroke=1.2, stroke_col=(70, 20, 14))
    first = body[1:]
    lines = []
    cur = ""
    for w in first.split(" "):
        t = (cur + " " + w) if cur else w
        lim = (x1 - x0 - 66) if len(lines) < 3 else (x1 - x0)
        if pa.text_size(t, 17, True, False)[0] <= lim:
            cur = t
        else:
            lines.append(cur)
            cur = w
    lines.append(cur)
    for i, l_ in enumerate(lines):
        xs = x0 + 66 if i < 3 else x0
        pa.text((xs, y + i * 25), l_, 17, ink, anchor="lm", italic=True, bold=False)
    y = y + len(lines) * 25 + 18
    for l_ in wrap_lines(pa, body2, 17, x1 - x0):
        pa.text((x0, y), l_, 17, ink, anchor="lm", italic=True, bold=False)
        y += 25
    y += 14
    pa.text((W / 2, y), "Fait à Pandémonia, au pied du Grand Brasier.", 15, ink, italic=True, bold=False)
    y += 60
    pa.text((x0, y), "Le soussigné :", 16, ink, anchor="lm", italic=True, bold=True)
    pa.line([(x0 + 128, y + 8), (x1 - 10, y + 8)], ink, 1.0)
    y += 64
    pa.text((x0, y), "Pour l'Académie :", 16, ink, anchor="lm", italic=True, bold=True)
    pa.line([(x0 + 150, y + 8), (x0 + 330, y + 8)], ink, 1.0)
    sig = []
    sx_, sy_ = x0 + 160, y
    for k in range(140):
        t = k / 139 * 7 * math.pi
        sig.append((sx_ + 6 + t * 6.2 - 7 * math.sin(t), sy_ - 2 - 9 * math.cos(t) * (0.6 + 0.4 * math.sin(t * 0.3))))
    pa.line(sig, (30, 24, 60), 1.5)
    pa.line(bez((sx_ + 10, sy_ + 12), (sx_ + 90, sy_ + 18), (sx_ + 170, sy_ + 4)), (30, 24, 60), 1.2)
    pa.text((x0 + 250, y + 26), "Pr Malachar", 12, ink, italic=True, bold=False)
    # ruban et sceau
    for k, dx in enumerate((-14, 12)):
        pa.poly([(388 + dx, 650), (398 + dx, 650), (404 + dx + k * 10, 728), (394 + dx + k * 10, 718), (384 + dx + k * 10, 730)], (130, 24, 20), shade=0.4, depth=2, ol=1.0)
    wax_seal(pa, 394, 640, 44, R)
    rgb = _poster_finish(pa, R, folds=True)
    save_rgb(rgb, "contrat.png")


# =================================================================== sceaux lumineux (256 px, RGBA)

def _glow_rgba(mask, core=(1.0, 0.95, 0.72), mid=(1.0, 0.5, 0.08), halo=(0.95, 0.28, 0.03), groove=(0.12, 0.05, 0.03), K=4, out=256):
    """Rend un tracé (masque L, K fois plus grand) en gravure incandescente sur fond transparent :
    sillon sombre, cœur brûlant, auréole."""
    m = np.asarray(mask, np.float32) / 255.0
    def blur(a, r):
        return np.asarray(Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r)), np.float32) / 255.0
    gr = np.asarray(mask.filter(ImageFilter.MaxFilter(2 * K + 1)), np.float32) / 255.0
    gr = blur(gr, K * 0.6)
    h1 = blur(m, K * 3.0)
    h2 = blur(m, K * 9.0)
    hot = blur(m, K * 0.9) * m
    rgb = np.zeros(m.shape + (3,), np.float32)
    a = np.zeros(m.shape, np.float32)

    def over(col, al):
        nonlocal rgb, a
        col = np.asarray(col, np.float32)
        if col.ndim == 1:
            col = col[None, None, :]
        rgb = rgb * (1 - al[..., None]) + col * al[..., None]
        a = a + al * (1 - a)
    over(halo, np.clip(h2 * 2.0, 0, 1) * 0.8)
    over(mid, np.clip(h1 * 1.6, 0, 1) * 0.75)
    over(groove, np.clip(gr - m, 0, 1) * 0.85)
    cc = np.array(mid, np.float32) * (1 - hot[..., None]) + np.array(core, np.float32) * hot[..., None]
    over(cc, m)
    prem = np.dstack([rgb * a[..., None], a])
    small = down(prem, K) if out * K == m.shape[0] else prem
    al = small[..., 3]
    col = small[..., :3] / np.maximum(al[..., None], 1e-4)
    return np.dstack([np.clip(col, 0, 1), np.clip(al, 0, 1)])


def _sig_canvas(K=4, S=256):
    m = Image.new("L", (S * K, S * K), 0)
    return m, ImageDraw.Draw(m)


def _flame_ring(d, K, c=128, r=92, n=14, w=5):
    d.ellipse(((c - r) * K, (c - r) * K, (c + r) * K, (c + r) * K), outline=255, width=int(w * K))
    for k in range(n):
        a = k / n * TAU - math.pi / 2
        bx, by = c + math.cos(a) * r, c + math.sin(a) * r
        pts = []
        for t in np.linspace(0, 1, 9):
            ang = a - 0.11 + 0.22 * t
            pts.append((c + math.cos(ang) * r, c + math.sin(ang) * r))
        tip_a = a + 0.06
        tip = (c + math.cos(tip_a) * (r + 22), c + math.sin(tip_a) * (r + 22))
        ctrl1 = (c + math.cos(a - 0.12) * (r + 12), c + math.sin(a - 0.12) * (r + 12))
        ctrl2 = (c + math.cos(a + 0.14) * (r + 8), c + math.sin(a + 0.14) * (r + 8))
        fl = [pts[0]] + bez(pts[0], ctrl1, tip, 8)[1:] + bez(tip, ctrl2, pts[-1], 8)[1:]
        d.polygon([(x * K, y * K) for x, y in fl], fill=255)
    d.ellipse(((c - r + 14) * K, (c - r + 14) * K, (c + r - 14) * K, (c + r - 14) * K), outline=255, width=int(2 * K))


ROMAN = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]


def sceau_cercle(n):
    K = 4
    m, d = _sig_canvas(K)
    _flame_ring(d, K)
    txt = ROMAN[n - 1]
    size = 92 if len(txt) <= 2 else (78 if len(txt) == 3 else 62)
    f = font(size * K, bold=True)
    d.text((128 * K, 130 * K), txt, font=f, fill=255, anchor="mm")
    save_rgba(_glow_rgba(m, K=K), "cercle_%d.png" % n)


def sceau_contrat():
    K = 2
    S = 256
    R = rng(7501)
    pa = Paint(S, S, K, bg=(0, 0, 0), seed=7501)
    wax_seal(pa, 128, 132, 84, R, col=(156, 24, 20))
    rgb, cov = pa.result()
    mm = Image.new("L", (S * 4, S * 4), 0)
    pts = []
    # silhouette du sceau (même tirage que wax_seal)
    R2 = rng(7501)
    for k in range(40):
        a = k / 40 * TAU
        rr_ = 84 * (1 + 0.08 * math.sin(a * 5 + 1) + R2.uniform(-0.05, 0.05))
        pts.append((128 + math.cos(a) * rr_, 132 + math.sin(a) * rr_))
    pts = chaikin(pts, 2)
    ImageDraw.Draw(mm).polygon([(x * 4, y * 4) for x, y in pts], fill=255)
    seal_a = np.asarray(mm.resize((S, S), Image.LANCZOS), np.float32) / 255.0
    halo = np.asarray(mm.resize((S, S), Image.LANCZOS).filter(ImageFilter.GaussianBlur(14)), np.float32) / 255.0
    ha = np.clip(halo * 1.3, 0, 1) * 0.5 * (1 - seal_a)
    hc = np.array((1.0, 0.45, 0.1), np.float32)
    a = seal_a + ha * (1 - seal_a)
    col = (rgb * seal_a[..., None] + hc * ha[..., None] * (1 - seal_a[..., None])) / np.maximum(a[..., None], 1e-4)
    save_rgba(np.dstack([col, a]), "sceau_contrat.png")


def lanterne_sym():
    K = 4
    m, d = _sig_canvas(K)
    P = lambda pts: [(x * K, y * K) for x, y in pts]
    w = int(6 * K)
    d.ellipse((116 * K, 18 * K, 140 * K, 42 * K), outline=255, width=w)
    d.polygon(P([(98, 70), (158, 70), (140, 46), (116, 46)]), outline=255, width=w)
    d.line(P([(98, 70), (90, 84), (166, 84), (158, 70)]), fill=255, width=w)
    d.rectangle(P([(92, 84), (164, 196)])[0] + P([(92, 84), (164, 196)])[1], outline=255, width=w)
    d.line(P([(128, 84), (128, 104)]), fill=255, width=int(4 * K))
    d.line(P([(110, 84), (110, 196)]), fill=255, width=int(3 * K))
    d.line(P([(146, 84), (146, 196)]), fill=255, width=int(3 * K))
    d.polygon(P(_flame_pts(128, 172, 30, 56)), fill=255)
    d.line(P([(84, 196), (172, 196), (160, 214), (96, 214), (84, 196)]), fill=255, width=w)
    d.line(P([(110, 222), (146, 222)]), fill=255, width=w)
    save_rgba(_glow_rgba(m, K=K), "lanterne_sym.png")


def flamme_sym():
    K = 4
    m, d = _sig_canvas(K)
    P = lambda pts: [(x * K, y * K) for x, y in pts]
    d.line(P(_flame_pts(128, 206, 132, 190) + [_flame_pts(128, 206, 132, 190)[0]]), fill=255, width=int(7 * K), joint="curve")
    d.polygon(P(_flame_pts(128, 196, 64, 110, 0.05)), fill=255)
    for sx in (-1, 1):
        d.line(P(bez((128 + sx * 70, 206), (128 + sx * 96, 150), (128 + sx * 60, 110), (128 + sx * 78, 76), 16)), fill=255, width=int(4 * K), joint="curve")
    save_rgba(_glow_rgba(m, K=K), "flamme_sym.png")


def givre_sym():
    K = 4
    m, d = _sig_canvas(K)
    c = 128
    for k in range(6):
        a = k * TAU / 6 - math.pi / 2
        ex, ey = c + math.cos(a) * 104, c + math.sin(a) * 104
        d.line([(c * K, c * K), (ex * K, ey * K)], fill=255, width=int(7 * K))
        for t, L in ((0.42, 30), (0.68, 22), (0.88, 13)):
            bx, by = c + math.cos(a) * 104 * t, c + math.sin(a) * 104 * t
            for sg in (-1, 1):
                b = a + sg * math.radians(55)
                d.line([(bx * K, by * K), ((bx + math.cos(b) * L) * K, (by + math.sin(b) * L) * K)], fill=255, width=int(5 * K))
        d.polygon([((ex + math.cos(a) * 10) * K, (ey + math.sin(a) * 10) * K), ((ex + math.cos(a + 1.6) * 6) * K, (ey + math.sin(a + 1.6) * 6) * K),
                   ((ex - math.cos(a) * 6) * K, (ey - math.sin(a) * 6) * K), ((ex + math.cos(a - 1.6) * 6) * K, (ey + math.sin(a - 1.6) * 6) * K)], fill=255)
    hexp = [((c + math.cos(k * TAU / 6) * 26) * K, (c + math.sin(k * TAU / 6) * 26) * K) for k in range(6)]
    d.polygon(hexp, outline=255, width=int(5 * K))
    save_rgba(_glow_rgba(m, core=(0.93, 0.98, 1.0), mid=(0.45, 0.8, 1.0), halo=(0.2, 0.55, 1.0), groove=(0.03, 0.06, 0.12), K=K), "givre_sym.png")


def sceaux():
    for n in range(1, 10):
        sceau_cercle(n)
    sceau_contrat()
    lanterne_sym()
    flamme_sym()
    givre_sym()


def panneaux():
    fenetre_gothique()
    vitrail_rosace()
    vitrail_lancette()
    banniere_pandemonia()
    affiche_tournoi()
    affiche_fete()
    plan_ville()
    contrat()


# =================================================================== fresques des Neuf Cercles (1024 x 512)

FW, FH = 1024, 512


def fresco_frame(pa, caption=None):
    """Le cadre peint commun : bande rouge sombre, filets d'ocre, petites flammes, légende."""
    W, H = FW, FH
    band = (96, 28, 20)
    ochre = (196, 146, 64)
    m = pa._draw(lambda d: (d.rectangle((0, 0, pa.w, int(18 * pa.K)), fill=255), d.rectangle((0, pa.h - int(34 * pa.K), pa.w, pa.h), fill=255),
                            d.rectangle((0, 0, int(18 * pa.K), pa.h), fill=255), d.rectangle((pa.w - int(18 * pa.K), 0, pa.w, pa.h), fill=255)))
    pa.comp(m, band, tex=True)
    pa.outline([(18, 18), (W - 18, 18), (W - 18, H - 34), (18, H - 34)], 2.4, ochre)
    pa.outline([(8, 8), (W - 8, 8), (W - 8, H - 8), (8, H - 8)], 1.4, ochre, alpha=0.8)
    for k in range(int((W - 40) / 40)):
        x = 30 + k * 40
        pa.poly(_flame_pts(x, 15, 9, 10, 0.1), (214, 120, 40), shade=0, ol=0, alpha=0.9)
    if caption:
        pa.text((W / 2, H - 17), caption, 17, (236, 206, 140), italic=True, bold=True, stroke=1.2, stroke_col=(40, 12, 8))
    else:
        for k in range(int((W - 40) / 40)):
            x = 30 + k * 40
            pa.poly(_flame_pts(x, H - 10, 9, 14, 0.1), (214, 120, 40), shade=0, ol=0, alpha=0.9)


def fresco_finish(pa, R, name, loss=0.022, base=(0.25, 0.21, 0.18), keep=()):
    """Pose la peinture sur la pierre et la vieillit ; la légende (et les boîtes keep) ne s'écaillent pas."""
    rgb, cov = pa.result()
    H, W = rgb.shape[:2]
    stone = stone_bg(R, W, H, base=base, var=0.12)
    paint = np.dstack([rgb, np.clip(cov * 1.0, 0, 1)])
    prot = np.zeros((H, W), np.float32)
    prot[H - 40:, :] = 1.0
    for (x0, y0, x1, y1) in keep:
        prot[int(y0):int(y1), int(x0):int(x1)] = 1.0
    prot = gblur(prot, 3.0)
    col = age_panel(paint, R, stone, loss=loss, fade=0.08, protect=np.clip(prot * 1.5, 0, 1), cracks=0.7, vignette=0.32, damp=0.18)
    save_rgb(col, name)


def sky(pa, top, bot, y0=18, y1=FH - 34):
    pa.rect(18, y0, FW - 18, y1, top, grad=(top, bot, 90, (y0, y1)), shade=0, ol=0)


def ripples(pa, R, x0, x1, y0, y1, col, n=120, alpha=0.5):
    for _ in range(n):
        y = R.uniform(y0, y1)
        x = R.uniform(x0, x1)
        L = R.uniform(10, 50) * (0.5 + (y - y0) / max(1, y1 - y0))
        pa.line([(x, y), (x + L, y)], col, R.uniform(0.8, 1.8), alpha=alpha * R.uniform(0.4, 1.0))


def lantern(pa, x, y, s=1.0, lit=(255, 190, 80)):
    pa.glow(x, y + 10 * s, 70 * s, (150, 80, 20), 0.55)
    pa.glow(x, y + 10 * s, 22 * s, (255, 170, 60), 0.6)
    pa.line([(x, y - 18 * s), (x, y - 6 * s)], (30, 22, 18), 2.0 * s)
    pa.poly([(x - 9 * s, y - 6 * s), (x + 9 * s, y - 6 * s), (x + 6 * s, y - 12 * s), (x - 6 * s, y - 12 * s)], (50, 36, 26), shade=0.5, depth=2, ol=1.2)
    pa.rect(x - 8 * s, y - 6 * s, x + 8 * s, y + 18 * s, lit, shade=0, ol=1.6)
    pa.poly(_flame_pts(x, y + 14 * s, 7 * s, 14 * s), (255, 240, 180), shade=0, ol=0)
    for dx in (-8, 0, 8):
        pa.line([(x + dx * s, y - 6 * s), (x + dx * s, y + 18 * s)], (40, 28, 20), 1.2 * s)
    pa.rect(x - 10 * s, y + 18 * s, x + 10 * s, y + 22 * s, (50, 36, 26), shade=0.4, depth=1, ol=1.0)


def face(pa, x, y, s, skin, beard=None, horns=(232, 214, 176), eyes="open", hood=None, brows=(230, 226, 214), smile=True):
    """Un visage de face, gentil : nez, yeux, sourcils, sourire, barbe et cornes optionnelles."""
    if hood:
        pa.poly(ellp(x, y - 2 * s, 30 * s, 34 * s, 180, 360, 24) + [(x + 34 * s, y + 30 * s), (x - 34 * s, y + 30 * s)], hood, shade=0.7, depth=6 * s, ol=2.0)
    for sx in (-1, 1):
        if horns:
            hp = bez((x + sx * 12 * s, y - 16 * s), (x + sx * 24 * s, y - 26 * s), (x + sx * 26 * s, y - 40 * s), (x + sx * 18 * s, y - 50 * s), 14)
            pa.tubep(hp, 8 * s, horns, w1=1.0 * s, shade=0.7, depth=2 * s, ol=1.4)
    pa.ell(x, y, 20 * s, 23 * s, skin, shade=0.7, depth=5 * s, ol=1.8)
    for sx in (-1, 1):
        pa.ell(x + sx * 20 * s, y + 2 * s, 4 * s, 7 * s, skin, shade=0.6, depth=2 * s, ol=1.4)
    if beard:
        pa.poly([(x - 18 * s, y + 4 * s), (x - 14 * s, y + 30 * s), (x - 6 * s, y + 46 * s), (x, y + 54 * s), (x + 6 * s, y + 46 * s), (x + 14 * s, y + 30 * s),
                 (x + 18 * s, y + 4 * s), (x + 8 * s, y + 12 * s), (x, y + 10 * s), (x - 8 * s, y + 12 * s)], beard, sm=1, shade=0.6, depth=4 * s, ol=1.6)
        pa.poly([(x - 10 * s, y + 9 * s), (x, y + 6 * s), (x + 10 * s, y + 9 * s), (x + 8 * s, y + 14 * s), (x, y + 12 * s), (x - 8 * s, y + 14 * s)], beard, sm=1, shade=0.5, depth=2 * s, ol=1.2)
    for sx in (-1, 1):
        ex = x + sx * 7.5 * s
        if eyes == "open":
            pa.ell(ex, y - 3 * s, 3.4 * s, 2.6 * s, (246, 240, 220), shade=0, ol=1.0)
            pa.ell(ex, y - 2.6 * s, 1.6 * s, 1.8 * s, (40, 26, 20), shade=0, ol=0)
        else:
            pa.line(ellp(ex, y - 4 * s, 3.6 * s, 2.4 * s, 20, 160, 8), (40, 24, 18), 1.4 * s)
        pa.line([(ex - 5 * s * sx * -1, y - 9 * s), (ex + 4 * s * sx * -1, y - 10.5 * s)], brows, 2.0 * s)
    pa.poly([(x, y - 2 * s), (x + 3.4 * s, y + 7 * s), (x - 3 * s, y + 7.5 * s)], tuple(int(c * 0.88) for c in skin), shade=0.5, depth=1.5 * s, ol=1.0)
    if smile and not beard:
        pa.line(ellp(x, y + 9 * s, 7 * s, 4 * s, 20, 160, 10), (90, 30, 26), 1.4 * s)


def fresque_porte():
    """La porte des Neuf Cercles : sous un arc brisé peint, entre deux torches, l'inscription
    « Vous qui entrez ici, gardez l'espoir » et, plus petit, « (et prenez un manteau) », avec un
    manteau pendu à sa patère et quelques flocons ; frise de flammes."""
    R = rng(7601)
    pa = Paint(FW, FH, 2, seed=7601)
    sky(pa, (52, 26, 22), (34, 18, 16))
    cx = FW / 2
    pa.poly(arch_pts(cx - 330, cx + 330, 300, 470), (78, 40, 30), shade=0.3, depth=10, ol=2.6)
    pa.poly(arch_pts(cx - 306, cx + 306, 300, 470), (42, 22, 20), shade=0.2, depth=10, ol=1.6)
    for k in range(9):
        a = math.pi + k / 8 * math.pi
        pa.ell(cx + math.cos(a) * 0, 300, 0, 0, (0, 0, 0), alpha=0, ol=0)
    for sx in (-1, 1):
        x = cx + sx * 410
        pa.rect(x - 8, 210, x + 8, 300, (70, 50, 36), shade=0.6, depth=3, ol=1.6)
        pa.poly([(x - 16, 210), (x + 16, 210), (x + 10, 196), (x - 10, 196)], (60, 44, 34), shade=0.6, depth=3, ol=1.6)
        pa.glow(x, 170, 90, (160, 70, 20), 0.6)
        pa.poly(_flame_pts(x, 198, 30, 60, 0.05 * sx), (240, 120, 30), shade=0.5, depth=4, ol=1.4)
        pa.poly(_flame_pts(x, 196, 16, 34, 0.0), (255, 214, 110), shade=0.3, depth=2, ol=0)
    gold = ((250, 214, 120), (200, 130, 40))
    pa.text((cx, 196), "Vous qui entrez ici,", 62, gold[0], italic=True, stroke=3.0, stroke_col=(60, 14, 10), grad=(gold[0], gold[1], 90, (166, 226)),
            shadow=(3, 4, 0.6))
    pa.text((cx, 278), "gardez l'espoir", 74, gold[0], italic=True, stroke=3.2, stroke_col=(60, 14, 10), grad=(gold[0], gold[1], 90, (242, 314)),
            shadow=(3, 4, 0.6))
    pa.text((cx + 10, 362), "(et prenez un manteau)", 34, (230, 220, 200), italic=True, bold=True, stroke=2.0, stroke_col=(40, 14, 10), shadow=(2, 3, 0.5))
    # le manteau sur sa patère, à droite du texte
    hx, hy = cx + 238, 330
    pa.tubep([(hx - 10, hy - 4), (hx + 12, hy - 4)], 5, (70, 50, 36), shade=0.5, depth=1.5, ol=1.2)
    pa.poly([(hx - 14, hy + 2), (hx + 14, hy + 2), (hx + 34, hy + 14), (hx + 42, hy + 60), (hx + 32, hy + 62), (hx + 30, hy + 30), (hx + 26, hy + 92),
             (hx - 26, hy + 92), (hx - 30, hy + 30), (hx - 32, hy + 62), (hx - 42, hy + 60), (hx - 34, hy + 14)], (70, 76, 130), sm=1, shade=0.7, depth=6, ol=1.8)
    pa.poly(ellp(hx, hy + 2, 16, 12, 180, 360, 12) + [(hx + 16, hy + 8), (hx - 16, hy + 8)], (60, 64, 112), shade=0.6, depth=3, ol=1.4)
    pa.poly([(hx - 15, hy + 6), (hx, hy + 22), (hx + 15, hy + 6), (hx + 12, hy + 14), (hx, hy + 30), (hx - 12, hy + 14)], (236, 226, 206), shade=0.5, depth=2, ol=1.2)
    pa.line([(hx, hy + 30), (hx, hy + 90)], (40, 40, 70), 1.4)
    for k in range(3):
        pa.ell(hx + 5, hy + 44 + k * 16, 2.4, 2.4, (230, 190, 90), shade=0.5, depth=1, ol=0.8)
    for k in range(9):
        fx, fy = cx + R.uniform(-320, 320), R.uniform(80, 420)
        if abs(fy - 260) < 120 and abs(fx - cx) < 300:
            continue
        for a in range(3):
            ang = a * math.pi / 3
            pa.line([(fx - math.cos(ang) * 6, fy - math.sin(ang) * 6), (fx + math.cos(ang) * 6, fy + math.sin(ang) * 6)], (220, 236, 250), 1.4, alpha=0.8)
    for k in range(26):
        x = 40 + k * 37.5
        pa.poly(_flame_pts(x, 470, 26, 34 + 10 * math.sin(k * 1.7), 0.15 * math.sin(k)), (200, 70, 26), shade=0.4, depth=3, ol=1.2)
        pa.poly(_flame_pts(x, 470, 12, 18, 0.0), (250, 170, 60), shade=0, ol=0)
    fresco_frame(pa)
    fresco_finish(pa, R, "fresque_porte.png", loss=0.018, keep=((150, 130, 880, 400),))


def fresque_charon():
    """Charon : un vieux démon passeur, capuchon, longue barbe blanche, petites cornes, qui pousse
    sa barque à la perche sur le fleuve noir ; une lanterne pend à la proue et se reflète dans
    l'eau ; brume, rochers, l'autre rive qui rougeoie au loin."""
    R = rng(7602)
    pa = Paint(FW, FH, 2, seed=7602)
    sky(pa, (30, 18, 26), (82, 36, 26), 18, 270)
    for side in (-1, 1):
        pts = [(FW / 2 + side * 520, 280), (FW / 2 + side * 520, 60)]
        x = FW / 2 + side * 520
        while abs(x - FW / 2) > 180:
            x -= side * R.uniform(30, 60)
            pts.append((x, R.uniform(90, 230) + (520 - abs(x - FW / 2)) * 0.15))
        pts.append((x, 280))
        pa.poly(pts, (26, 16, 18), shade=0, ol=1.2)
    pa.glow(820, 260, 60, (160, 60, 20), 0.5)
    pa.poly([(700, 272), (760, 250), (840, 244), (900, 258), (940, 272)], (34, 20, 18), shade=0, ol=1.0)
    pa.rect(18, 268, FW - 18, FH - 34, (12, 14, 20), grad=((26, 22, 30), (8, 10, 14), 90, (268, 478)), shade=0, ol=0)
    ripples(pa, R, 30, FW - 30, 276, 470, (70, 70, 90), 160, 0.45)
    # le reflet de la lanterne
    for k in range(16):
        y = 330 + k * 9
        w_ = 26 - k * 1.2
        pa.line([(262 - w_ / 2 + R.uniform(-6, 6), y), (262 + w_ / 2 + R.uniform(-6, 6), y)], (240, 160, 60), 2.2, alpha=0.7 - k * 0.035)
    # la barque
    hull = [(230, 300), (300, 330), (640, 336), (760, 312), (790, 290), (770, 300), (640, 312), (320, 310), (250, 284)]
    pa.poly([(250, 300), (300, 340), (650, 346), (770, 318), (796, 286), (640, 312), (320, 312)], (70, 44, 30), sm=1, shade=0.7, depth=8, ol=2.0)
    pa.poly(hull, (96, 62, 40), sm=1, shade=0.6, depth=6, ol=1.8)
    for k in range(3):
        pa.line([(300 + k * 6, 322 + k * 6), (650 - k * 10, 330 + k * 4)], (50, 32, 22), 1.2)
    pa.tubep(bez((250, 290), (226, 270), (230, 236), (250, 222), 14), 9, (90, 58, 36), w1=6, shade=0.6, depth=3, ol=1.6)
    pa.ell(252, 218, 6, 6, (120, 80, 50), shade=0.6, depth=2, ol=1.2)
    pa.line(bez((252, 220), (262, 214), (276, 222)), (40, 28, 22), 2.0)
    lantern(pa, 276, 246, 1.1)
    pa.ell(450, 318, 5, 3, (240, 196, 80), shade=0.5, depth=1, ol=0.8)
    pa.glow(450, 318, 6, (200, 150, 40), 0.6)
    # Charon
    x, base = 660, 314
    pa.poly([(x - 46, base), (x - 40, base - 70), (x - 30, base - 118), (x - 14, base - 136), (x + 14, base - 136), (x + 34, base - 116), (x + 40, base - 70), (x + 44, base)],
            (66, 58, 60), sm=1, shade=0.7, depth=10, ol=2.0)
    pa.poly([(x - 10, base - 120), (x + 2, base - 60), (x - 4, base)], (54, 46, 50), shade=0.3, depth=4, ol=1.2)
    face(pa, x - 2, base - 152, 1.25, (176, 98, 86), beard=(232, 228, 216), hood=(60, 52, 58), horns=(226, 210, 170))
    # la perche, tenue à deux mains
    pa.tubep([(x + 40, base - 200), (x - 140, base + 150)], 6, (110, 76, 44), shade=0.6, depth=2, ol=1.4)
    for (hx, hy) in ((x + 8, base - 136), (x - 30, base - 62)):
        pa.ell(hx, hy, 8, 7, (176, 98, 86), shade=0.6, depth=2, ol=1.4)
    pa.poly([(x + 30, base - 116), (x + 14, base - 136), (x + 2, base - 132), (x + 20, base - 100)], (66, 58, 60), shade=0.5, depth=3, ol=1.4)
    pa.poly([(x - 30, base - 100), (x - 34, base - 66), (x - 22, base - 60), (x - 16, base - 96)], (66, 58, 60), shade=0.5, depth=3, ol=1.4)
    for k in range(5):
        pa.ell(R.uniform(80, 940), R.uniform(250, 300), R.uniform(60, 140), R.uniform(8, 16), (180, 170, 170), shade=0, ol=0, alpha=0.12)
    for side in (0, 1):
        x0 = 18 if side == 0 else FW - 18
        sx = 1 if side == 0 else -1
        pts = [(x0, FH - 34), (x0, 400)]
        for k in range(7):
            pts.append((x0 + sx * (20 + k * 18), 400 + R.uniform(-30, 40) + k * 8))
        pts.append((x0 + sx * 150, FH - 34))
        pa.poly(pts, (22, 16, 16), shade=0.3, depth=6, ol=1.4)
    fresco_frame(pa, "Charon, le passeur de l'Achéron · une obole pour la traversée")
    fresco_finish(pa, R, "fresque_charon.png")


def dog_head(pa, x, y, s, fur, muzzle):
    """Une grosse tête de chien endormie, de profil vers la gauche : crâne rond, museau carré,
    truffe, babines, oreille tombante, œil fermé."""
    dark = tuple(int(c * 0.72) for c in fur)
    pa.poly([(x + 6 * s, y - 20 * s), (x + 26 * s, y - 14 * s), (x + 30 * s, y + 18 * s), (x + 20 * s, y + 34 * s), (x + 8 * s, y + 20 * s)], dark, sm=2, shade=0.6, depth=3 * s, ol=1.6)
    pa.ell(x, y, 30 * s, 26 * s, fur, shade=0.75, depth=7 * s, ol=1.8)
    pa.poly([(x - 14 * s, y - 8 * s), (x - 46 * s, y - 4 * s), (x - 54 * s, y + 4 * s), (x - 52 * s, y + 18 * s), (x - 40 * s, y + 26 * s), (x - 12 * s, y + 24 * s)],
            muzzle, sm=2, shade=0.7, depth=5 * s, ol=1.8)
    pa.poly([(x - 44 * s, y + 14 * s), (x - 30 * s, y + 30 * s), (x - 14 * s, y + 28 * s), (x - 16 * s, y + 18 * s)], tuple(int(c * 0.9) for c in muzzle), sm=1, shade=0.5, depth=2 * s, ol=1.4)
    pa.ell(x - 51 * s, y + 3 * s, 7 * s, 5.5 * s, (26, 18, 16), shade=0.7, depth=1.5 * s, ol=1.0)
    pa.ell(x - 53 * s, y + 1 * s, 2 * s, 1.4 * s, (120, 110, 110), shade=0, ol=0)
    pa.line(ellp(x - 36 * s, y + 18 * s, 10 * s, 4 * s, 10, 120, 8), (60, 30, 26), 1.4)
    pa.line(ellp(x - 12 * s, y - 6 * s, 7 * s, 4 * s, 15, 165, 10), (26, 16, 14), 2.0)
    pa.line([(x - 18 * s, y - 13 * s), (x - 5 * s, y - 15 * s)], tuple(int(c * 1.3) for c in fur), 1.6)
    pa.poly([(x + 2 * s, y - 22 * s), (x + 16 * s, y - 20 * s), (x + 18 * s, y + 8 * s), (x + 8 * s, y + 22 * s), (x - 2 * s, y + 4 * s)], dark, sm=2, shade=0.6, depth=3 * s, ol=1.6)


def fresque_cerbere():
    """Cerbère, le grand chien à trois têtes, dort couché devant la porte, les trois mentons sur
    ses pattes ; devant lui, un plat de trois gâteaux de miel et un pot de miel ; un brasero
    réchauffe la salle ; de petits « Z » s'envolent."""
    R = rng(7603)
    pa = Paint(FW, FH, 2, seed=7603)
    sky(pa, (60, 30, 22), (36, 20, 16), 18, 330)
    pa.rect(18, 330, FW - 18, FH - 34, (74, 48, 34), grad=((80, 52, 36), (50, 32, 24), 90, (330, 478)), shade=0, ol=0)
    for k in range(9):
        y = 330 + k * 16
        pa.line([(18, y), (FW - 18, y)], (50, 32, 24), 1.0, alpha=0.5)
    pa.poly(arch_pts(380, 640, 210, 334), (40, 26, 22), shade=0.3, depth=8, ol=2.2)
    pa.poly(arch_pts(400, 620, 214, 334), (24, 14, 14), shade=0, ol=1.4)
    for k in range(7):
        x = 412 + k * 30
        pa.line([(x, 120), (x, 334)], (54, 50, 52), 4.0)
    pa.glow(510, 280, 80, (90, 30, 10), 0.4)
    for sx in (-1, 1):
        pa.rect(510 + sx * 140 - 16, 90, 510 + sx * 140 + 16, 334, (70, 54, 44), shade=0.6, depth=6, ol=1.8)
    # le brasero
    bx, by = 860, 330
    pa.glow(bx, by - 60, 140, (170, 80, 20), 0.55)
    for sx in (-1, 0, 1):
        pa.line([(bx + sx * 24, by + 50), (bx + sx * 6, by - 20)], (40, 30, 26), 3.0)
    pa.poly(ellp(bx, by - 26, 46, 18, 0, 180, 20), (60, 46, 40), shade=0.6, depth=3, ol=1.6)
    for k in range(3):
        pa.poly(_flame_pts(bx - 20 + k * 20, by - 30, 30, 60 + 16 * (k == 1), 0.1 * (k - 1)), (240, 120, 30), shade=0.4, depth=3, ol=1.2)
        pa.poly(_flame_pts(bx - 20 + k * 20, by - 30, 14, 30, 0.0), (255, 220, 120), shade=0, ol=0)
    # Cerbère couché
    fur = (74, 52, 44)
    muzzle = (140, 100, 78)
    tail = bez((640, 410), (720, 400), (730, 330), (680, 320), 20)
    pa.tubep(tail, 20, fur, w1=9, shade=0.6, depth=4, ol=1.8)
    pa.poly(ellp(500, 392, 175, 64, n=60), fur, shade=0.75, depth=18, ol=2.2)
    pa.poly(ellp(600, 418, 64, 40, n=40), tuple(int(c * 0.92) for c in fur), shade=0.6, depth=8, ol=1.8)
    pa.poly([(560, 440), (650, 436), (660, 456), (566, 458)], fur, sm=1, shade=0.6, depth=4, ol=1.8)
    for k in range(6):
        pa.line(ellp(420 + k * 34, 360, 14, 28, 200, 330, 8), (46, 32, 28), 1.4, alpha=0.6)
    for (px_, py_) in ((150, 446), (250, 452), (345, 450)):
        pa.poly([(px_ - 28, py_ - 12), (px_ + 60, py_ - 16), (px_ + 64, py_ + 6), (px_ - 32, py_ + 8)], fur, sm=1, shade=0.6, depth=4, ol=1.8)
        for t in range(3):
            pa.line([(px_ - 28 + t * 6, py_ - 4 + t * 3), (px_ - 20 + t * 6, py_ - 4 + t * 3)], (34, 22, 20), 1.2)
    heads = [(300, 366, 1.45), (176, 404, 1.5), (404, 412, 1.52)]
    for (hx, hy, hs) in heads:
        pa.tubep([(470, 386), (hx + 30 * hs, hy + 4)], 40 * hs, fur, shade=0.6, depth=8, ol=1.8)
    for (hx, hy, hs) in heads:
        pa.tubep([(hx + 26 * hs, hy - 24 * hs), (hx + 36 * hs, hy + 28 * hs)], 8, (160, 30, 26), shade=0.6, depth=2, ol=1.2)
        for k in range(3):
            pa.ell(hx + 28 * hs + k * 3.4 * hs, hy - 14 * hs + k * 17 * hs, 2.8, 2.8, (230, 190, 80), shade=0.6, depth=1, ol=0.8)
        dog_head(pa, hx, hy, hs, fur, muzzle)
    for (hx, hy, hs) in heads:
        zx, zy = hx + 4, hy - 46 * hs
        for j in range(3):
            pa.text((zx + j * 14, zy - j * 16), "z", 13 + j * 4, (236, 226, 200), italic=True, bold=True, stroke=1.0, stroke_col=(40, 20, 14), alpha=0.9)
    # les gâteaux de miel
    gx, gy = 640, 452
    pa.poly(ellp(gx, gy + 18, 92, 22, n=40), (200, 196, 186), shade=0.6, depth=4, ol=1.8)
    for k, dx in enumerate((-50, 0, 50)):
        x = gx + dx
        y = gy - (8 if k == 1 else 0)
        pa.poly(ellp(x, y + 6, 32, 12, 0, 180, 16) + ellp(x, y - 12, 32, 10, 180, 0, 16), (196, 132, 58), shade=0.7, depth=4, ol=1.6)
        pa.ell(x, y - 12, 32, 10, (226, 160, 60), shade=0.5, depth=3, ol=1.4)
        for j in range(4):
            dxx = -24 + j * 16
            pa.poly([(x + dxx - 4, y - 8), (x + dxx + 4, y - 8), (x + dxx + 3, y + 4 + (j % 2) * 5), (x + dxx, y + 8 + (j % 2) * 5), (x + dxx - 3, y + 4 + (j % 2) * 5)],
                    (236, 172, 50), shade=0.4, depth=1.5, ol=0, alpha=0.9)
        pa.ell(x - 8, y - 14, 6, 2.4, (255, 230, 160), shade=0, ol=0, alpha=0.8)
    pa.poly([(gx + 120, gy + 16), (gx + 112, gy - 30), (gx + 126, gy - 44), (gx + 170, gy - 44), (gx + 184, gy - 30), (gx + 176, gy + 16)], (200, 140, 60), sm=1, shade=0.7, depth=6, ol=1.8)
    pa.ell(gx + 148, gy - 44, 22, 6, (150, 96, 40), shade=0.5, depth=2, ol=1.4)
    pa.text((gx + 148, gy - 8), "MIEL", 12, (90, 40, 20), bold=True)
    pa.tubep([(gx + 160, gy - 46), (gx + 190, gy - 90)], 4, (140, 100, 60), shade=0.5, depth=1, ol=1.2)
    fresco_frame(pa, "Cerbère dort · trois gâteaux de miel pour trois gourmands")
    fresco_finish(pa, R, "fresque_cerbere.png")


def fresque_minos():
    """Minos, le juge : assis très haut derrière son pupitre, robe noire, chaîne d'or, cornes et
    lunettes, il écrit sur un long rouleau ; sa queue, interminable, s'enroule plusieurs fois
    autour de lui et de son siège ; colonnes et rosace dans la salle d'audience."""
    R = rng(7604)
    pa = Paint(FW, FH, 2, seed=7604)
    sky(pa, (70, 22, 20), (40, 16, 16))
    pa.glow(FW / 2, 120, 120, (150, 60, 20), 0.5)
    pa.ell(FW / 2, 120, 66, 66, (200, 110, 40), shade=0, ol=2.0)
    for k in range(8):
        a = k * TAU / 8
        pa.line([(FW / 2, 120), (FW / 2 + math.cos(a) * 66, 120 + math.sin(a) * 66)], (60, 20, 16), 3.0)
    pa.ell(FW / 2, 120, 18, 18, (240, 170, 70), shade=0, ol=2.0)
    for x in (110, 250, 774, 914):
        pa.rect(x - 22, 40, x + 22, 470, (84, 44, 36), shade=0.6, depth=8, ol=2.0)
        pa.rect(x - 30, 40, x + 30, 60, (100, 56, 44), shade=0.6, depth=3, ol=1.6)
        pa.rect(x - 30, 450, x + 30, 470, (100, 56, 44), shade=0.6, depth=3, ol=1.6)
    pa.rect(18, 420, FW - 18, FH - 34, (60, 30, 26), shade=0, ol=0)
    for k in range(24):
        x = 18 + k * 44
        pa.line([(x, 420), (x - 30 + (x - FW / 2) * 0.1, FH - 34)], (40, 20, 18), 1.2, alpha=0.6)
    cx = FW / 2
    # le haut siège
    pa.rect(cx - 70, 150, cx + 70, 420, (70, 40, 30), shade=0.6, depth=8, ol=2.0)
    pa.poly([(cx - 80, 150), (cx, 104), (cx + 80, 150)], (80, 46, 34), shade=0.6, depth=5, ol=2.0)
    # Minos
    pa.poly([(cx - 84, 400), (cx - 72, 270), (cx - 42, 232), (cx + 42, 232), (cx + 72, 270), (cx + 84, 400)], (34, 26, 30), sm=1, shade=0.7, depth=10, ol=2.2)
    pa.line(bez((cx - 44, 242), (cx, 292), (cx + 44, 242)), (230, 180, 60), 3.4)
    pa.ell(cx, 294, 10, 10, (240, 190, 70), shade=0.6, depth=2, ol=1.4)
    face(pa, cx, 194, 1.6, (176, 70, 60), beard=(70, 60, 64), horns=(232, 214, 176))
    for sx in (-1, 1):
        pa.outline(ellp(cx + sx * 12, 189, 8.5, 7, n=20), 1.6, (210, 176, 80))
    pa.line([(cx - 3.5, 189), (cx + 3.5, 189)], (210, 176, 80), 1.4)
    pa.poly([(cx - 34, 150), (cx - 24, 108), (cx + 24, 108), (cx + 34, 150)], (30, 24, 28), shade=0.6, depth=3, ol=1.8)
    pa.rect(cx - 36, 146, cx + 36, 154, (200, 160, 60), shade=0.5, depth=1, ol=1.2)
    pa.poly([(cx - 130, 330), (cx + 130, 330), (cx + 116, 430), (cx - 116, 430)], (110, 66, 40), shade=0.7, depth=8, ol=2.0)
    pa.poly([(cx - 76, 322), (cx + 76, 322), (cx + 70, 336), (cx - 70, 336)], (232, 220, 190), shade=0.4, depth=2, ol=1.4)
    pa.poly([(cx + 44, 330), (cx + 76, 330), (cx + 90, 400), (cx + 72, 470), (cx + 44, 474), (cx + 60, 400)], (232, 220, 190), sm=1, shade=0.4, depth=3, ol=1.4)
    for k in range(6):
        pa.line([(cx + 56 + k * 1.5, 348 + k * 18), (cx + 70 + k * 1.5, 348 + k * 18)], (90, 70, 60), 1.0)
    pa.ell(cx + 30, 310, 10, 8, (176, 70, 60), shade=0.6, depth=2, ol=1.4)
    pa.line([(cx + 30, 310), (cx + 52, 270)], (240, 230, 220), 2.2)
    pa.poly([(cx + 50, 274), (cx + 68, 246), (cx + 57, 276)], (240, 236, 226), shade=0, ol=1.0)
    pa.ell(cx - 34, 314, 10, 8, (176, 70, 60), shade=0.6, depth=2, ol=1.4)
    # la queue interminable, enroulée autour du siège
    tail_col = (150, 34, 30)
    turns = 2.4
    N = 240
    pts = []
    angs = []
    for k in range(N):
        t = k / (N - 1)
        a = -0.5 * math.pi + t * turns * TAU
        pts.append((cx + math.cos(a) * (176 - 24 * t), 452 - t * 132 + math.sin(a) * 26))
        angs.append(a)
    segs = []
    cur = [pts[0]]
    front = math.sin(angs[0]) > -0.05
    for i in range(1, N):
        f = math.sin(angs[i]) > -0.05
        if f != front:
            segs.append((front, cur + [pts[i]]))
            cur = [pts[i]]
            front = f
        else:
            cur.append(pts[i])
    segs.append((front, cur))
    for fr, sg in segs:
        if not fr and len(sg) > 1:
            pa.tubep(sg, 15, tuple(int(c * 0.7) for c in tail_col), shade=0.6, depth=3, ol=1.6)
    for fr, sg in segs:
        if fr and len(sg) > 1:
            pa.tubep(sg, 16, tail_col, shade=0.8, depth=3.5, ol=1.8)
    end = bez(pts[-1], (pts[-1][0] + 40, pts[-1][1] - 80), (cx + 150, 200), (cx + 92, 170), 30)
    pa.tubep(end, 16, tail_col, w1=11, shade=0.8, depth=3.5, ol=1.8)
    ex_, ey_ = end[-1]
    pa.poly([(ex_ + 6, ey_ - 8), (ex_ - 26, ey_ - 18), (ex_ - 10, ey_ + 14)], tail_col, shade=0.6, depth=2, ol=1.6)
    fresco_frame(pa, "Minos, le juge · répondez juste à ses trois questions")
    fresco_finish(pa, R, "fresque_minos.png")


def fresque_dite():
    """La cité de Dité : de hautes murailles de fer rivetées, crénelées, une grande porte close au
    liseré rougeoyant, et derrière, des tours rouges qui luisent comme des braises ; le ciel brûle,
    les trois Furies tournoient au-dessus de la porte ; le Styx noir au premier plan."""
    R = rng(7605)
    pa = Paint(FW, FH, 2, seed=7605)
    sky(pa, (40, 12, 14), (196, 76, 30), 18, 330)
    for k in range(60):
        x, y = R.uniform(30, FW - 30), R.uniform(40, 320)
        pa.ell(x, y, 1.4, 1.4, (255, 200, 120), shade=0, ol=0, alpha=R.uniform(0.3, 0.9))
    # tours rouges derrière la muraille
    for k in range(9):
        x = 90 + k * 106 + R.uniform(-20, 20)
        w = R.uniform(38, 56)
        top = R.uniform(70, 160)
        pa.rect(x - w / 2, top, x + w / 2, 300, (150, 34, 26), shade=0.6, depth=6, ol=2.0, grad=((190, 50, 30), (110, 24, 20), 0, (x - w / 2, x + w / 2)))
        if k % 3 == 1:
            pa.poly(ellp(x, top, w * 0.6, w * 0.7, 180, 360, 20), (170, 40, 28), shade=0.6, depth=5, ol=1.8)
            pa.line([(x, top - w * 0.7), (x, top - w * 0.7 - 22)], (40, 30, 30), 2.0)
        else:
            pa.poly([(x - w / 2 - 6, top), (x, top - w * 1.4), (x + w / 2 + 6, top)], (70, 30, 30), shade=0.6, depth=5, ol=1.8)
        for j in range(3):
            wy = top + 30 + j * 40
            if wy < 290:
                pa.poly(arch_pts(x - 6, x + 6, wy, wy + 18, n=8), (255, 190, 80), shade=0, ol=1.2)
                pa.glow(x, wy + 6, 16, (200, 80, 20), 0.5)
    # la muraille de fer
    wy0, wy1 = 230, 380
    pa.rect(18, wy0, FW - 18, wy1, (66, 70, 84), shade=0.3, depth=10, ol=2.0, grad=((84, 88, 104), (44, 46, 58), 90, (wy0, wy1)))
    for k in range(int((FW - 36) / 40) + 1):
        x = 18 + k * 40
        pa.rect(x, wy0 - 22, x + 24, wy0, (70, 74, 88), shade=0.5, depth=3, ol=1.6)
    for x in range(18, FW - 18, 80):
        pa.line([(x, wy0), (x, wy1)], (30, 32, 40), 1.6)
    for y in (wy0 + 50, wy0 + 100):
        pa.line([(18, y), (FW - 18, y)], (30, 32, 40), 1.6)
    for x in range(30, FW - 18, 20):
        for y in (wy0 + 8, wy0 + 58, wy0 + 108):
            pa.ell(x, y, 2.2, 2.2, (120, 124, 140), shade=0.6, depth=1, ol=0.6)
    pa.rect(18, wy0, FW - 18, wy1, (200, 60, 30), alpha=0.12, shade=0, ol=0)
    cx = FW / 2
    pa.poly(arch_pts(cx - 90, cx + 90, 300, wy1 + 2), (40, 40, 50), shade=0.5, depth=8, ol=2.4)
    pa.poly(arch_pts(cx - 78, cx + 78, 300, wy1), (54, 56, 68), shade=0.6, depth=6, ol=1.8)
    pa.line([(cx, 222), (cx, wy1)], (255, 140, 50), 3.0)
    pa.glow(cx, 300, 30, (200, 60, 10), 0.6)
    for sx in (-1, 1):
        pa.ell(cx + sx * 30, 320, 8, 8, (130, 120, 110), shade=0.6, depth=2, ol=1.4)
    for k, (fx, fy) in enumerate(((cx - 120, 120), (cx, 80), (cx + 120, 116))):
        for sx in (-1, 1):
            pa.poly([(fx, fy), (fx + sx * 40, fy - 24), (fx + sx * 54, fy - 4), (fx + sx * 34, fy + 2), (fx + sx * 40, fy + 14)], (40, 22, 30), sm=1, shade=0.4, depth=2, ol=1.4)
        pa.ell(fx, fy + 6, 8, 16, (90, 40, 70), shade=0.6, depth=2, ol=1.4)
        pa.ell(fx, fy - 12, 7, 7, (190, 120, 110), shade=0.6, depth=2, ol=1.2)
        for j in range(5):
            a = math.radians(200 + j * 35)
            pa.line(bez((fx, fy - 14), (fx + math.cos(a) * 10, fy - 14 + math.sin(a) * 10), (fx + math.cos(a) * 14, fy - 18 + math.sin(a) * 14)), (60, 120, 60), 1.6)
    pa.rect(18, wy1, FW - 18, FH - 34, (14, 12, 18), grad=((30, 16, 18), (8, 8, 12), 90, (wy1, FH - 34)), shade=0, ol=0)
    ripples(pa, R, 30, FW - 30, wy1 + 6, FH - 40, (200, 80, 40), 120, 0.4)
    fresco_frame(pa, "La cité de Dité · trois Furies gardent la porte de fer")
    fresco_finish(pa, R, "fresque_dite.png")


def fresque_geryon():
    """Géryon : un grand animal ailé au visage d'homme bon et barbu, aux pattes de lion, au corps
    bigarré et à la longue queue de serpent, emporte un voyageur sur son dos au-dessus du gouffre ;
    à gauche, la cascade de feu du Phlégéthon tombe dans le vide."""
    R = rng(7606)
    pa = Paint(FW, FH, 2, seed=7606)
    sky(pa, (24, 14, 20), (70, 28, 22))
    # cascade de feu
    for k in range(14):
        x = 66 + k * 9 + R.uniform(-3, 3)
        ph = R.uniform(0, TAU)
        pts = [(x + math.sin(t * 9 + ph) * 5 + t * R.uniform(-10, 10), 30 + t * 448) for t in np.linspace(0, 1, 40)]
        pa.line(pts, (250, 110 + k * 7, 30), R.uniform(3, 7), alpha=0.75)
    for k in range(5):
        x = 80 + k * 22
        pa.line([(x + math.sin(t * 7 + k) * 4, 30 + t * 448) for t in np.linspace(0, 1, 40)], (255, 230, 150), 1.6, alpha=0.7)
    pa.glow(130, 300, 130, (170, 70, 20), 0.6)
    pa.poly([(18, 30), (58, 30), (54, 200), (62, 330), (52, 478), (18, 478)], (30, 18, 18), shade=0.4, depth=6, ol=1.6)
    cliff = [(220, 478), (214, 380), (236, 330), (226, 270), (250, 230), (276, 260), (290, 340), (282, 400), (300, 478)]
    pa.poly(cliff, (40, 24, 22), shade=0.5, depth=6, ol=1.6)
    for k in range(8):
        pa.ell(R.uniform(300, 980), R.uniform(380, 470), R.uniform(60, 160), R.uniform(10, 22), (120, 80, 80), shade=0, ol=0, alpha=0.15)
    cx, cy = 600, 250
    body_c = (170, 120, 60)
    # queue de serpent
    tail = bez((cx + 120, cy + 20), (cx + 300, cy + 80), (cx + 330, cy - 100), (cx + 220, cy - 120), 40)
    tail += bez((cx + 220, cy - 120), (cx + 150, cy - 130), (cx + 160, cy - 60), (cx + 200, cy - 70), 20)[1:]
    pa.tubep(tail, 34, (80, 120, 90), w1=6, shade=0.8, depth=5, ol=2.0)
    for k in range(4, len(tail) - 4, 4):
        (ax, ay), (bx, by) = tail[k - 1], tail[k + 1]
        nx, ny = -(by - ay), bx - ax
        L = math.hypot(nx, ny) or 1
        w = 15 * (1 - k / len(tail))
        pa.line([(tail[k][0] - nx / L * w, tail[k][1] - ny / L * w), (tail[k][0] + nx / L * w, tail[k][1] + ny / L * w)], (40, 70, 50), 1.6, alpha=0.8)
    pa.ell(tail[-1][0], tail[-1][1], 6, 6, (230, 200, 90), shade=0.6, depth=2, ol=1.2)
    # ailes de chauve-souris
    for k, (dx, col) in enumerate(((-36, (86, 40, 52)), (16, (120, 52, 62)))):
        base = (cx + dx, cy - 26)
        tips = [(cx + dx - 170, cy - 170), (cx + dx - 90, cy - 230), (cx + dx + 10, cy - 236), (cx + dx + 110, cy - 190), (cx + dx + 150, cy - 110)]
        wing = [base, tips[0]]
        for i in range(len(tips) - 1):
            a_, b_ = tips[i], tips[i + 1]
            mx, my = (a_[0] + b_[0]) / 2, (a_[1] + b_[1]) / 2
            ctrl = (mx + (base[0] - mx) * 0.32, my + (base[1] - my) * 0.32)
            wing += bez(a_, ctrl, b_, 10)[1:]
        pa.poly(wing, col, shade=0.6, depth=8, ol=2.0)
        for t in tips:
            pa.tubep([base, t], 5, tuple(int(c * 0.6) for c in col), w1=2, shade=0.3, depth=1.5, ol=1.0)
    # corps bigarré
    pa.poly(ellp(cx + 20, cy + 10, 130, 54, n=60), body_c, shade=0.8, depth=14, ol=2.2)
    pa.poly(ellp(cx - 60, cy + 22, 52, 40, n=40), tuple(int(c * 1.06) for c in body_c), shade=0.7, depth=8, ol=1.6)
    pa.line(bez((cx - 80, cy - 34), (cx + 20, cy - 52), (cx + 140, cy - 22)), (110, 70, 40), 5.0, alpha=0.7)
    for k in range(14):
        a = R.uniform(0, TAU)
        rr_ = R.uniform(0.2, 0.85)
        pa.ell(cx + 20 + math.cos(a) * 120 * rr_, cy + 10 + math.sin(a) * 46 * rr_, R.uniform(5, 10), R.uniform(4, 8), (120, 70, 40), shade=0, ol=0, alpha=0.7)
    for (px_, py_) in ((cx - 70, cy + 50), (cx - 20, cy + 56), (cx + 90, cy + 50)):
        pa.poly([(px_ - 12, py_ - 10), (px_ + 12, py_ - 10), (px_ + 14, py_ + 30), (px_ + 22, py_ + 40), (px_ - 12, py_ + 40)], body_c, sm=1, shade=0.6, depth=4, ol=1.8)
        for t in range(3):
            pa.line([(px_ + 2 + t * 6, py_ + 34), (px_ + 4 + t * 6, py_ + 42)], (40, 24, 18), 1.2)
    # le visage d'homme bon, et sa crinière
    hx, hy = cx - 150, cy - 24
    pa.tubep([(cx - 80, cy + 4), (hx + 20, hy + 26)], 56, body_c, shade=0.6, depth=8, ol=2.0)
    mane = [(hx - 4, hy - 34), (hx + 30, hy - 40), (hx + 60, hy - 24), (hx + 82, hy + 4), (hx + 92, hy + 40), (hx + 70, hy + 34), (hx + 66, hy + 60),
            (hx + 44, hy + 44), (hx + 30, hy + 66), (hx + 16, hy + 40)]
    pa.poly(mane, (226, 222, 210), sm=2, shade=0.7, depth=6, ol=1.8)
    for k in range(6):
        pa.line(bez((hx + 10 + k * 12, hy - 30 + k * 6), (hx + 40 + k * 8, hy - 10 + k * 8), (hx + 50 + k * 6, hy + 30 + k * 4)), (170, 166, 156), 1.2, alpha=0.8)
    face(pa, hx, hy, 1.4, (216, 164, 134), beard=(238, 234, 224), horns=None, brows=(244, 240, 232))
    pa.line(ellp(hx, hy + 22, 9, 3.4, 10, 170, 8), (130, 50, 40), 1.6)
    # le voyageur
    tx, ty = cx + 30, cy - 52
    pa.poly([(tx - 18, ty + 20), (tx - 14, ty - 20), (tx + 14, ty - 20), (tx + 20, ty + 20)], (40, 90, 120), sm=1, shade=0.7, depth=4, ol=1.8)
    pa.rect(tx + 8, ty - 18, tx + 24, ty + 6, (120, 80, 40), shade=0.6, depth=2, ol=1.4)
    pa.ell(tx, ty - 32, 11, 12, (226, 180, 150), shade=0.6, depth=2, ol=1.6)
    pa.poly([(tx - 13, ty - 34), (tx, ty - 50), (tx + 13, ty - 34)], (150, 40, 30), shade=0.5, depth=2, ol=1.4)
    pa.ell(tx - 4, ty - 32, 1.4, 1.6, (30, 20, 16), shade=0, ol=0)
    pa.ell(tx + 4, ty - 32, 1.4, 1.6, (30, 20, 16), shade=0, ol=0)
    pa.line(ellp(tx, ty - 28, 4, 2, 20, 160, 6), (110, 40, 30), 1.2)
    pa.tubep([(tx - 10, ty - 14), (tx - 30, ty - 44)], 7, (40, 90, 120), shade=0.5, depth=1.5, ol=1.4)
    pa.ell(tx - 32, ty - 48, 5, 5, (226, 180, 150), shade=0.5, depth=1, ol=1.2)
    pa.poly([(tx - 16, ty + 18), (tx - 30, ty + 40), (tx - 20, ty + 44), (tx - 6, ty + 20)], (50, 60, 80), shade=0.5, depth=2, ol=1.4)
    for k in range(30):
        pa.ell(R.uniform(250, 980), R.uniform(30, 470), 1.4, 1.4, (255, 190, 90), shade=0, ol=0, alpha=R.uniform(0.3, 0.9))
    fresco_frame(pa, "Géryon, le porteur · il vole au-dessus du Phlégéthon")
    fresco_finish(pa, R, "fresque_geryon.png")


def fresque_cocyte():
    """Le Cocyte : un lac gelé au fond du monde, la glace craquelée, des congères ; au fond, le
    Titan de Givre se dresse à mi-corps hors de la glace, taillé dans le cristal bleu, couronne de
    pointes, yeux qui luisent ; deux petits voyageurs et leur lanterne, chaude, au premier plan."""
    R = rng(7607)
    pa = Paint(FW, FH, 2, seed=7607)
    sky(pa, (14, 18, 34), (40, 56, 84), 18, 300)
    for k in range(int((FW - 36) / 26)):
        x = 30 + k * 26 + R.uniform(-6, 6)
        L = R.uniform(14, 50)
        pa.poly([(x - 6, 18), (x + 6, 18), (x, 18 + L)], (150, 190, 220), shade=0.5, depth=2, ol=1.0)
    for side in (-1, 1):
        pts = [(FW / 2 + side * 500, 300)]
        x = FW / 2 + side * 500
        while abs(x - FW / 2) > 260:
            x -= side * R.uniform(40, 80)
            pts.append((x, R.uniform(120, 230)))
        pts.append((FW / 2 + side * 240, 300))
        pa.poly(pts, (90, 120, 160), shade=0.6, depth=10, ol=1.6)
    # le Titan de Givre, taillé dans le cristal
    cx, cy = FW / 2, 210
    rr = rng(7617)

    def facets(poly, base, n_in=1, light=1.0):
        px = sum(p_[0] for p_ in poly) / len(poly) + rr.uniform(-10, 10)
        py = sum(p_[1] for p_ in poly) / len(poly) + rr.uniform(-10, 10)
        for i in range(len(poly)):
            a_, b_ = poly[i], poly[(i + 1) % len(poly)]
            mx, my = (a_[0] + b_[0] + px) / 3, (a_[1] + b_[1] + py) / 3
            lv = 0.78 + 0.45 * max(0.0, (-(mx - px) * 0.5 - (my - py) * 0.7) / 40.0 + 0.4) * light + rr.uniform(-0.08, 0.08)
            c = tuple(int(min(255, v * lv)) for v in base)
            pa.poly([a_, b_, (px, py)], c, shade=0, ol=0)
            pa.line([a_, (px, py)], (230, 246, 255), 0.9, alpha=0.6)
        pa.outline(poly, 1.8, (40, 70, 110))
    ice = (140, 190, 224)
    for sx in (-1, 1):
        facets([(cx + sx * 120, 176), (cx + sx * 190, 196), (cx + sx * 226, 250), (cx + sx * 236, 298), (cx + sx * 196, 300), (cx + sx * 170, 240), (cx + sx * 126, 214)], ice)
        facets([(cx + sx * 196, 294), (cx + sx * 248, 290), (cx + sx * 276, 304), (cx + sx * 240, 316), (cx + sx * 190, 312)], (170, 210, 236))
    facets([(cx - 150, 300), (cx - 136, 206), (cx - 96, 156), (cx - 40, 140), (cx + 40, 140), (cx + 96, 156), (cx + 136, 206), (cx + 150, 300)], ice)
    facets([(cx - 70, 300), (cx - 60, 220), (cx, 196), (cx + 60, 220), (cx + 70, 300)], (160, 206, 232), light=1.2)
    for sx in (-1, 1):
        for k in range(3):
            bx_ = cx + sx * (96 + k * 22)
            by_ = 158 + k * 12
            facets([(bx_ - 12, by_ + 6), (bx_ + sx * 10, by_ - 70 + k * 14), (bx_ + 14, by_ + 4)], (196, 228, 246))
    head = [(cx - 50, 140), (cx - 58, 92), (cx - 40, 58), (cx, 48), (cx + 40, 58), (cx + 58, 92), (cx + 50, 140), (cx, 154)]
    facets(head, (176, 214, 238))
    for k in range(7):
        x = cx - 42 + k * 14
        facets([(x - 7, 60), (x, 60 - 22 - 12 * (k % 2) - 12 * (k == 3)), (x + 7, 60)], (214, 238, 250))
    for k in range(8):
        x = cx - 36 + k * 10.3
        L = 22 + 10 * math.sin(k * 1.7) + (14 if k in (3, 4) else 0)
        facets([(x - 5, 136), (x + 5, 136), (x, 136 + L)], (200, 232, 248))
    pa.poly([(cx - 46, 90), (cx - 10, 84), (cx - 10, 92), (cx - 46, 98)], (60, 90, 130), shade=0, ol=0, alpha=0.6)
    pa.poly([(cx + 46, 90), (cx + 10, 84), (cx + 10, 92), (cx + 46, 98)], (60, 90, 130), shade=0, ol=0, alpha=0.6)
    for sx in (-1, 1):
        pa.poly([(cx + sx * 34, 98), (cx + sx * 14, 102), (cx + sx * 32, 108)], (140, 236, 255), shade=0, ol=1.0)
        pa.glow(cx + sx * 24, 103, 16, (60, 170, 255), 1.0)
    for k in range(5):
        pa.ell(cx + rr.uniform(-30, 30), 150 - k * 6, 12 + k * 6, 4 + k * 2, (220, 240, 255), shade=0, ol=0, alpha=0.15)
    # le lac gelé
    pa.rect(18, 296, FW - 18, FH - 34, (170, 200, 222), grad=((150, 184, 212), (206, 226, 240), 90, (296, 478)), shade=0, ol=0)
    for k in range(18):
        x0 = R.uniform(40, FW - 40)
        y0 = R.uniform(310, 470)
        pts = [(x0, y0)]
        for j in range(4):
            pts.append((pts[-1][0] + R.uniform(-50, 50), pts[-1][1] + R.uniform(-10, 14)))
        pa.line(pts, (240, 250, 255), 1.4, alpha=0.8)
        pa.line([(px + 1, py + 1.5) for px, py in pts], (100, 130, 160), 1.0, alpha=0.6)
    for k in range(6):
        x = R.uniform(40, FW - 140)
        y = R.uniform(400, 470)
        pa.poly(ellp(x, y, R.uniform(50, 120), R.uniform(8, 14), 180, 360, 16), (236, 244, 250), shade=0.6, depth=3, ol=1.0)
    # les voyageurs et leur lanterne
    for k, (vx, col) in enumerate(((760, (140, 50, 40)), (800, (60, 80, 130)))):
        vy = 452 - k * 4
        pa.poly([(vx - 12, vy), (vx - 9, vy - 34), (vx + 9, vy - 34), (vx + 12, vy)], col, sm=1, shade=0.6, depth=3, ol=1.6)
        pa.ell(vx, vy - 42, 8, 8, (226, 180, 150), shade=0.6, depth=2, ol=1.4)
        pa.poly([(vx - 10, vy - 44), (vx, vy - 58), (vx + 10, vy - 44)], tuple(int(c * 0.8) for c in col), shade=0.5, depth=2, ol=1.2)
    lantern(pa, 820, 410, 0.7)
    pa.glow(800, 440, 70, (120, 70, 20), 0.35)
    for k in range(90):
        x, y = R.uniform(30, FW - 30), R.uniform(30, 470)
        r = R.uniform(1.0, 2.4)
        pa.ell(x, y, r, r, (240, 248, 255), shade=0, ol=0, alpha=R.uniform(0.4, 0.9))
    fresco_frame(pa, "Le Cocyte · le Titan de Givre garde la Flamme Éternelle")
    fresco_finish(pa, R, "fresque_cocyte.png", base=(0.24, 0.24, 0.26))


def fresques():
    fresque_porte()
    fresque_charon()
    fresque_cerbere()
    fresque_minos()
    fresque_dite()
    fresque_geryon()
    fresque_cocyte()


# =================================================================== icônes (128 px, comme les autres)

IS = 512


def ico_save(img, name):
    """Cerné et ombré comme les autres icônes (generate_items_v28), puis réduit à 128 px."""
    import generate_items_v28 as icons
    icons.OUT = ITEMS
    p = ITEMS / (name + ".png")
    img2 = icons.shadow(icons.outline(img))
    img2.resize((128, 128), Image.LANCZOS).save(p, optimize=True)
    _log(p)


def canvas_i():
    return Image.new("RGBA", (IS, IS), (0, 0, 0, 0))


def glow_i(img, cx, cy, r, col, k=1.0, inside=None):
    """Lueur douce (additive) ; si inside est donné (masque 0..1), elle reste dans la silhouette."""
    yy, xx = np.mgrid[0:IS, 0:IS].astype(np.float32)
    g = np.exp(-((xx - cx) ** 2 + (yy - cy) ** 2) / (r * r)) * k
    a = np.asarray(img, np.float32) / 255.0
    rgb = a[..., :3] + (np.array(col, np.float32) / 255.0)[None, None, :] * (g * (a[..., 3] if inside is None else inside))[..., None]
    out = np.dstack([np.clip(rgb, 0, 1), a[..., 3]])
    img.paste(Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGBA"))


def shape_i(fn):
    m = Image.new("L", (IS, IS), 0)
    fn(ImageDraw.Draw(m))
    return np.asarray(m, np.float32) / 255.0


def ic_obole():
    img = canvas_i()
    R = rng(7701)
    tex = 0.86 + 0.24 * tn(R, IS, (8, 16, 32, 64, 128), 0.6)
    disc = chaikin([(256 + math.cos(a) * 168 * (1 + 0.03 * math.sin(a * 5)), 262 + math.sin(a) * 160 * (1 + 0.03 * math.cos(a * 4))) for a in np.linspace(0, TAU, 40, endpoint=False)], 2)
    vol(img, lambda d: d.polygon(disc, fill=255), (182, 132, 66), depth=22, gloss=0.5, tex=tex)
    d = ImageDraw.Draw(img)
    d.ellipse((122, 130, 390, 394), outline=(120, 82, 40, 255), width=7)
    d.ellipse((128, 136, 384, 388), outline=(226, 186, 116, 200), width=3)
    for k in range(24):
        a = k / 24 * TAU
        x, y = 256 + math.cos(a) * 112, 262 + math.sin(a) * 112
        d.ellipse((x - 4, y - 4, x + 4, y + 4), fill=(130, 90, 44, 255))
    for (dx, dy, c) in ((-3, -3, (238, 200, 128, 255)), (0, 0, (112, 74, 36, 255))):
        hull = [(176 + dx, 286 + dy), (336 + dx, 286 + dy), (316 + dx, 314 + dy), (196 + dx, 314 + dy)]
        d.polygon(hull, fill=c)
        d.line([(186 + dx, 286 + dy), (166 + dx, 262 + dy)], fill=c, width=7)
        d.ellipse((276 + dx, 196 + dy, 302 + dx, 222 + dy), fill=c)
        d.polygon([(272 + dx, 222 + dy), (306 + dx, 222 + dy), (300 + dx, 286 + dy), (278 + dx, 286 + dy)], fill=c)
        d.line([(318 + dx, 210 + dy), (226 + dx, 334 + dy)], fill=c, width=6)
    for _ in range(9):
        x, y = R.uniform(150, 360), R.uniform(150, 370)
        r = R.uniform(4, 10)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(70, 150, 120, 150))
    ico_save(img, "obole")


def ic_cle_brasier():
    img = canvas_i()
    R = rng(7702)
    a = math.radians(45)
    ca, sa = math.cos(a), math.sin(a)
    def P(u, v):
        return (150 + u * ca - v * sa, 150 + u * sa + v * ca)
    shaft = [P(60, -14), P(330, -14), P(330, 14), P(60, 14)]
    bit = [P(250, 14), P(250, 70), P(272, 70), P(272, 46), P(292, 46), P(292, 78), P(316, 78), P(316, 14)]
    tex = 0.85 + 0.25 * tn(R, IS, (16, 32, 64, 128), 0.6)
    vol(img, lambda d: (d.polygon(shaft, fill=255), d.polygon(bit, fill=255)), (96, 90, 100), depth=8, gloss=0.5, tex=tex)
    ring = _flame_pts(150, 214, 210, 250)
    vol(img, lambda d: d.polygon(ring, fill=255), (110, 102, 112), depth=18, gloss=0.6, tex=tex)
    vol(img, lambda d: d.polygon(_flame_pts(150, 196, 150, 180), fill=255), (206, 152, 60), depth=10, gloss=0.7)
    hole = _flame_pts(150, 180, 92, 120)
    em = shape_i(lambda d: d.polygon(hole, fill=255))
    vol(img, lambda d: d.polygon(hole, fill=255), (240, 110, 30), depth=14, gloss=0.3)
    glow_i(img, 150, 150, 46, (255, 210, 120), 0.9, inside=em)
    vol(img, lambda d: d.polygon(_flame_pts(150, 168, 40, 62), fill=255), (255, 226, 130), depth=6, gloss=0.4)
    d = ImageDraw.Draw(img)
    for u in (90, 120, 200):
        d.line([P(u, -14), P(u, 14)], fill=(60, 56, 64, 255), width=6)
        d.line([P(u - 4, -14), P(u - 4, 14)], fill=(170, 164, 176, 255), width=2)
    ico_save(img, "cle_brasier")


def ic_gateau_miel():
    img = canvas_i()
    R = rng(7703)
    tex = 0.86 + 0.22 * tn(R, IS, (16, 32, 64, 128), 0.65)
    vol(img, lambda d: (d.rectangle((86, 250, 426, 380), fill=255), d.ellipse((86, 320, 426, 440), fill=255)), (186, 116, 52), depth=24, gloss=0.25, tex=tex)
    d = ImageDraw.Draw(img)
    for k in range(3):
        d.arc((90, 268 + k * 34, 422, 340 + k * 34), 10, 170, fill=(150, 88, 36, 255), width=4)
    vol(img, lambda d_: d_.ellipse((80, 190, 432, 310), fill=255), (238, 166, 44), depth=14, gloss=0.9)
    vol(img, lambda d_: [d_.ellipse((x - 16, 290, x + 16, 300 + L), fill=255) for x, L in ((120, 50), (170, 80), (232, 40), (300, 90), (360, 56), (404, 36))] +
        [d_.rectangle((x - 16, 270, x + 16, 300 + L - 16), fill=255) for x, L in ((120, 50), (170, 80), (232, 40), (300, 90), (360, 56), (404, 36))],
        (232, 156, 36), depth=8, gloss=0.9)
    for (x, y) in ((200, 232), (256, 222), (312, 236)):
        vol(img, lambda d_, x=x, y=y: d_.ellipse((x - 22, y - 16, x + 22, y + 16), fill=255), (150, 96, 50), depth=8, gloss=0.5)
    hx, hy = 256, 120
    cells = []
    for i in range(-1, 2):
        for j in range(2):
            cx, cy = hx + i * 34 + (j % 2) * 17, hy + j * 30
            cells.append([(cx + math.cos(k * TAU / 6) * 18, cy + math.sin(k * TAU / 6) * 18) for k in range(6)])
    vol(img, lambda d_: [d_.polygon(c, fill=255) for c in cells], (240, 190, 70), depth=6, gloss=0.6)
    d = ImageDraw.Draw(img)
    for c in cells:
        d.polygon(c, outline=(170, 110, 30, 255), width=4)
    ico_save(img, "gateau_miel")


def ic_flamme_eternelle():
    img = canvas_i()
    R = rng(7704)
    tex = 0.88 + 0.2 * tn(R, IS, (16, 32, 64), 0.6)
    vol(img, lambda d: d.polygon([(186, 470), (326, 470), (300, 440), (274, 430), (270, 380), (242, 380), (238, 430), (212, 440)], fill=255), (210, 158, 60), depth=10, gloss=0.8, tex=tex)
    vol(img, lambda d: d.chord((126, 250, 386, 410), 0, 180, fill=255), (220, 168, 64), depth=20, gloss=0.9, tex=tex)
    vol(img, lambda d: d.ellipse((120, 300, 392, 340), fill=255), (180, 120, 40), depth=6, gloss=0.6)
    d = ImageDraw.Draw(img)
    for k in range(6):
        x = 150 + k * 42
        d.ellipse((x - 9, 352, x + 9, 370), fill=(200, 40, 30, 255), outline=(120, 70, 20, 255), width=3)
    outer = _flame_pts(256, 330, 230, 300, 0.05)
    em = shape_i(lambda d_: d_.polygon(outer, fill=255))
    vol(img, lambda d_: d_.polygon(outer, fill=255), (232, 70, 24), depth=20, gloss=0.2)
    vol(img, lambda d_: d_.polygon(_flame_pts(256, 326, 160, 230, -0.04), fill=255), (250, 140, 30), depth=14, gloss=0.2)
    vol(img, lambda d_: d_.polygon(_flame_pts(256, 322, 96, 150, 0.03), fill=255), (255, 214, 80), depth=10, gloss=0.2)
    vol(img, lambda d_: d_.polygon(_flame_pts(256, 318, 46, 80, 0.0), fill=255), (255, 248, 210), depth=6, gloss=0.1)
    glow_i(img, 256, 230, 90, (255, 200, 120), 0.5, inside=em)
    ico_save(img, "flamme_eternelle")


def ic_corne_or():
    img = canvas_i()
    R = rng(7705)
    ctr = bez((120, 420), (150, 250), (300, 120), (420, 90), 40)
    poly = tube(ctr, 150, 14)
    tex = 0.88 + 0.2 * tn(R, IS, (16, 32, 64), 0.6)
    vol(img, lambda d: d.polygon(poly, fill=255), (226, 170, 56), depth=24, gloss=1.0, tex=tex)
    d = ImageDraw.Draw(img)
    for k in range(3, 36, 4):
        (ax, ay), (bx, by) = ctr[k - 1], ctr[k + 1]
        nx, ny = -(by - ay), bx - ax
        L = math.hypot(nx, ny) or 1
        w = (150 + (14 - 150) * k / 39) * 0.5
        d.line([(ctr[k][0] - nx / L * w, ctr[k][1] - ny / L * w), (ctr[k][0] + nx / L * w * 0.8, ctr[k][1] + ny / L * w * 0.8)], fill=(170, 110, 30, 255), width=5)
    vol(img, lambda d: d.ellipse((50, 370, 196, 470), fill=255), (232, 186, 80), depth=12, gloss=0.8)
    vol(img, lambda d: d.ellipse((76, 392, 170, 450), fill=255), (120, 70, 20), depth=6, gloss=0.2)
    vol(img, lambda d: d.polygon([(160, 300), (240, 330), (300, 420), (256, 410), (230, 350), (170, 330)], fill=255), (190, 30, 30), depth=6, gloss=0.4)
    vol(img, lambda d: d.polygon([(160, 300), (200, 340), (176, 440), (150, 420), (170, 350)], fill=255), (170, 24, 24), depth=6, gloss=0.4)
    ico_save(img, "corne_or")


def ic_lanterne_braise():
    img = canvas_i()
    R = rng(7706)
    tex = 0.86 + 0.24 * tn(R, IS, (16, 32, 64, 128), 0.6)
    d = ImageDraw.Draw(img)
    vol(img, lambda d: d.ellipse((222, 26, 290, 94), fill=255) or d.ellipse((240, 44, 272, 76), fill=0), (90, 84, 92), depth=6, gloss=0.5)
    glass = shape_i(lambda d_: d_.rectangle((170, 170, 342, 410), fill=255))
    vol(img, lambda d_: d_.rectangle((170, 170, 342, 410), fill=255), (250, 150, 50), depth=26, gloss=0.3)
    glow_i(img, 256, 330, 90, (255, 220, 120), 0.9, inside=glass)
    vol(img, lambda d_: d_.polygon(_flame_pts(256, 370, 70, 130), fill=255), (255, 236, 160), depth=10, gloss=0.2)
    vol(img, lambda d_: d_.polygon([(150, 176), (362, 176), (318, 100), (194, 100)], fill=255), (96, 88, 98), depth=12, gloss=0.6, tex=tex)
    vol(img, lambda d_: d_.rectangle((140, 404, 372, 444), fill=255), (96, 88, 98), depth=10, gloss=0.6, tex=tex)
    vol(img, lambda d_: [d_.rectangle((x - 9, 170, x + 9, 410), fill=255) for x in (172, 256, 340)], (80, 74, 84), depth=4, gloss=0.6)
    vol(img, lambda d_: d_.rectangle((168, 280, 344, 292), fill=255), (80, 74, 84), depth=4, gloss=0.6)
    ico_save(img, "lanterne_braise")


def ic_diplome_infernal():
    img = canvas_i()
    R = rng(7707)
    tex = 0.88 + 0.18 * tn(R, IS, (32, 64, 128), 0.6, oy=(8, 16, 32))
    vol(img, lambda d: d.rounded_rectangle((70, 170, 442, 290), radius=60, fill=255), (232, 214, 170), depth=30, gloss=0.3, tex=tex)
    for x0 in (70, 382):
        vol(img, lambda d, x0=x0: d.ellipse((x0, 170, x0 + 60, 290), fill=255), (220, 198, 150), depth=10, gloss=0.3, tex=tex)
    d = ImageDraw.Draw(img)
    for x0 in (70, 382):
        d.arc((x0 + 12, 186, x0 + 48, 274), 0, 360, fill=(170, 140, 90, 255), width=4)
        d.arc((x0 + 22, 206, x0 + 38, 254), 0, 360, fill=(150, 120, 70, 255), width=3)
    vol(img, lambda d: d.rectangle((236, 166, 276, 294), fill=255), (176, 30, 26), depth=8, gloss=0.5)
    vol(img, lambda d: (d.polygon([(256, 240), (190, 200), (196, 290)], fill=255), d.polygon([(256, 240), (322, 200), (316, 290)], fill=255)), (190, 34, 30), depth=8, gloss=0.5)
    vol(img, lambda d: (d.polygon([(250, 260), (220, 400), (244, 390), (262, 260)], fill=255), d.polygon([(262, 260), (300, 396), (276, 388), (252, 262)], fill=255)),
        (176, 28, 24), depth=6, gloss=0.4)
    seal = chaikin([(256 + math.cos(a) * 52 * (1 + 0.07 * math.sin(a * 5)), 400 + math.sin(a) * 52 * (1 + 0.07 * math.sin(a * 5))) for a in np.linspace(0, TAU, 30, endpoint=False)], 2)
    vol(img, lambda d: d.polygon(seal, fill=255), (170, 24, 20), depth=14, gloss=0.6)
    d = ImageDraw.Draw(img)
    for sx in (-1, 1):
        d.arc((256 + sx * 8 - 26, 368, 256 + sx * 8 + 10, 412), 200 if sx < 0 else 250, 320 if sx < 0 else 340, fill=(120, 14, 10, 255), width=6)
    d.polygon(_flame_pts(256, 422, 28, 44), fill=(120, 16, 12, 255))
    ico_save(img, "diplome_infernal")


def ic_piment_infernal():
    img = canvas_i()
    R = rng(7708)
    ctr = bez((330, 110), (390, 220), (330, 400), (150, 430), 40)
    poly = tube(ctr, 120, 10)
    vol(img, lambda d: d.polygon(poly, fill=255), (212, 30, 20), depth=26, gloss=1.0, tex=0.92 + 0.12 * tn(R, IS, (16, 32, 64), 0.6))
    vol(img, lambda d: d.polygon([(280, 120), (380, 100), (370, 140), (300, 150)], fill=255), (60, 130, 40), depth=8, gloss=0.4)
    vol(img, lambda d: d.polygon(tube(bez((330, 112), (330, 70), (360, 50), 10), 18, 10), fill=255), (70, 120, 40), depth=4, gloss=0.4)
    tip = _flame_pts(150, 432, 60, 96, -0.6)
    vol(img, lambda d: d.polygon(tip, fill=255), (250, 140, 30), depth=8, gloss=0.2)
    vol(img, lambda d: d.polygon(_flame_pts(146, 430, 28, 50, -0.6), fill=255), (255, 226, 120), depth=4, gloss=0.2)
    ico_save(img, "piment_infernal")


def ic_cafe_brasier():
    img = canvas_i()
    R = rng(7709)
    vol(img, lambda d: d.ellipse((60, 380, 452, 470), fill=255), (120, 30, 26), depth=10, gloss=0.6)
    vol(img, lambda d: d.ellipse((330, 250, 450, 370), fill=255) or d.ellipse((360, 280, 420, 340), fill=0), (110, 28, 24), depth=10, gloss=0.6)
    vol(img, lambda d: d.chord((96, 140, 380, 440), 0, 180, fill=255) or d.rectangle((96, 230, 380, 292), fill=255), (130, 34, 28), depth=28, gloss=0.8)
    vol(img, lambda d: d.ellipse((96, 200, 380, 262), fill=255), (100, 24, 20), depth=6, gloss=0.4)
    vol(img, lambda d: d.ellipse((112, 210, 364, 254), fill=255), (60, 34, 20), depth=10, gloss=0.6)
    d = ImageDraw.Draw(img)
    d.ellipse((150, 218, 326, 246), outline=(170, 110, 60, 255), width=4)
    for k in range(3):
        x = 180 + k * 58
        pts = [(x + math.sin(t * 6 + k) * 14, 200 - t * 150) for t in np.linspace(0, 1, 20)]
        d.line(pts, fill=(236, 230, 220, 220), width=10, joint="curve")
    for k in range(5):
        x = 140 + k * 50
        d.polygon(_flame_pts(x, 330, 16, 22), fill=(240, 150, 40, 255))
    ico_save(img, "cafe_brasier")


def ic_lave_glacee():
    img = canvas_i()
    R = rng(7710)
    vol(img, lambda d: d.polygon([(220, 380), (292, 380), (300, 450), (340, 470), (172, 470), (212, 450)], fill=255), (200, 226, 236), depth=10, gloss=0.8)
    vol(img, lambda d: d.chord((90, 190, 422, 420), 0, 180, fill=255), (196, 222, 236), depth=24, gloss=1.0, alpha=0.95)
    for (x, y, r, c) in ((180, 260, 78, (232, 96, 30)), (330, 260, 78, (214, 60, 26)), (256, 196, 84, (240, 120, 36))):
        vol(img, lambda d, x=x, y=y, r=r: d.ellipse((x - r, y - r, x + r, y + r), fill=255), c, depth=22, gloss=0.4,
            tex=0.85 + 0.25 * tn(R, IS, (16, 32, 64), 0.6))
    d = ImageDraw.Draw(img)
    for _ in range(40):
        x, y = R.uniform(120, 390), R.uniform(130, 300)
        if (x - 256) ** 2 / 170 ** 2 + (y - 240) ** 2 / 120 ** 2 > 1:
            continue
        r = R.uniform(4, 9)
        d.polygon([(x + math.cos(a) * r * R.uniform(0.6, 1.0), y + math.sin(a) * r * R.uniform(0.6, 1.0)) for a in np.linspace(0, TAU, 5, endpoint=False)], fill=(30, 22, 20, 255))
    d.line(chaikin([(150, 200), (200, 240), (250, 214), (310, 250), (360, 222)], 2, False), fill=(170, 20, 14, 255), width=10, joint="curve")
    vol(img, lambda d: d.polygon([(330, 160), (440, 60), (456, 74), (346, 176)], fill=255), (226, 200, 140), depth=6, gloss=0.5)
    d = ImageDraw.Draw(img)
    for k in range(5):
        x = 120 + k * 60
        d.line([(x, 330), (x + 20, 380)], fill=(255, 255, 255, 140), width=4)
    ico_save(img, "lave_glacee")


def ic_grog_soufre():
    img = canvas_i()
    R = rng(7711)
    tex = 0.86 + 0.22 * tn(R, IS, (16, 32, 64), 0.6, oy=(64, 128, 256))
    vol(img, lambda d: d.ellipse((330, 220, 460, 380), fill=255) or d.ellipse((364, 254, 428, 346), fill=0), (120, 78, 44), depth=10, gloss=0.4, tex=tex)
    vol(img, lambda d: d.rounded_rectangle((110, 170, 370, 460), radius=30, fill=255), (140, 92, 52), depth=26, gloss=0.4, tex=tex)
    d = ImageDraw.Draw(img)
    for y in (220, 410):
        d.rectangle((110, y, 370, y + 18), fill=(80, 76, 82, 255))
        d.line([(112, y + 3), (368, y + 3)], fill=(160, 156, 166, 255), width=3)
    vol(img, lambda d: d.ellipse((116, 150, 364, 210), fill=255), (232, 186, 50), depth=10, gloss=0.7)
    d = ImageDraw.Draw(img)
    for k in range(9):
        x, y = R.uniform(150, 330), R.uniform(162, 196)
        r = R.uniform(5, 11)
        d.ellipse((x - r, y - r * 0.6, x + r, y + r * 0.6), outline=(250, 226, 130, 255), width=3)
    vol(img, lambda d: d.polygon(tube([(290, 180), (360, 60)], 26), fill=255), (130, 70, 36), depth=6, gloss=0.4)
    d = ImageDraw.Draw(img)
    for k in range(4):
        d.line([(300 + k * 16, 160 - k * 26), (318 + k * 16, 168 - k * 26)], fill=(90, 46, 24, 255), width=3)
    for k in range(2):
        x = 180 + k * 60
        pts = [(x + math.sin(t * 6 + k) * 12, 140 - t * 110) for t in np.linspace(0, 1, 20)]
        d.line(pts, fill=(236, 230, 220, 210), width=9, joint="curve")
    ico_save(img, "grog_soufre")


def ic_fleur_braise():
    img = canvas_i()
    R = rng(7712)
    stem = bez((250, 470), (270, 380), (230, 320), (256, 250), 30)
    vol(img, lambda d: d.polygon(tube(stem, 18, 12), fill=255), (46, 36, 34), depth=5, gloss=0.3)
    for (x, y, a, L) in ((256, 400, -0.9, 120), (244, 350, -2.3, 110)):
        poly = leaf_poly(x + math.cos(a) * L * 0.45, y + math.sin(a) * L * 0.45, L, 44, a)
        vol(img, lambda d, poly=poly: d.polygon(poly, fill=255), (52, 40, 40), depth=8, gloss=0.4)
    cx, cy = 256, 210
    flower = shape_i(lambda d: d.ellipse((cx - 150, cy - 150, cx + 150, cy + 150), fill=255))
    for k in range(6):
        a = k * TAU / 6 + 0.3
        px, py = cx + math.cos(a) * 82, cy + math.sin(a) * 82
        petal = leaf_poly(px, py, 170, 104, a, tip=0.3)
        vol(img, lambda d, petal=petal: d.polygon(petal, fill=255), (200, 40, 24), depth=16, gloss=0.4)
    for k in range(6):
        a = k * TAU / 6 + 0.3 + TAU / 12
        px, py = cx + math.cos(a) * 60, cy + math.sin(a) * 60
        petal = leaf_poly(px, py, 120, 70, a, tip=0.3)
        vol(img, lambda d, petal=petal: d.polygon(petal, fill=255), (240, 110, 30), depth=12, gloss=0.4)
    glow_i(img, cx, cy, 90, (255, 200, 90), 0.8, inside=flower)
    vol(img, lambda d: d.ellipse((cx - 34, cy - 34, cx + 34, cy + 34), fill=255), (255, 226, 120), depth=10, gloss=0.4)
    d = ImageDraw.Draw(img)
    for _ in range(14):
        a = R.uniform(0, TAU)
        r = R.uniform(10, 30)
        d.ellipse((cx + math.cos(a) * r - 4, cy + math.sin(a) * r - 4, cx + math.cos(a) * r + 4, cy + math.sin(a) * r + 4), fill=(180, 60, 20, 255))
    ico_save(img, "fleur_braise")


def ic_cristal_soufre():
    img = canvas_i()
    R = rng(7713)
    vol(img, lambda d: d.ellipse((90, 380, 430, 470), fill=255), (110, 100, 90), depth=14, gloss=0.2, tex=0.8 + 0.3 * tn(R, IS, (16, 32, 64), 0.6))
    crystals = [(256, 420, -90, 330, 70), (170, 430, -125, 220, 56), (350, 430, -55, 240, 58), (120, 440, -150, 130, 44), (400, 440, -30, 140, 44)]
    for (x, y, ang, L, w) in crystals:
        a = math.radians(ang)
        ca, sa = math.cos(a), math.sin(a)
        nx, ny = -sa, ca
        tipx, tipy = x + ca * L, y + sa * L
        bx, by = x + ca * L * 0.78, y + sa * L * 0.78
        left = [(x + nx * w * 0.5, y + ny * w * 0.5), (bx + nx * w * 0.5, by + ny * w * 0.5), (tipx, tipy), (bx, by), (x, y)]
        right = [(x - nx * w * 0.5, y - ny * w * 0.5), (bx - nx * w * 0.5, by - ny * w * 0.5), (tipx, tipy), (bx, by), (x, y)]
        lit_left = (nx * -0.45 + ny * -0.6) > 0
        vol(img, lambda d, q=left: d.polygon(q, fill=255), (246, 226, 90) if lit_left else (206, 170, 40), depth=4, gloss=0.6)
        vol(img, lambda d, q=right: d.polygon(q, fill=255), (206, 170, 40) if lit_left else (246, 226, 90), depth=4, gloss=0.6)
        d = ImageDraw.Draw(img)
        d.line([(x, y), (bx, by), (tipx, tipy)], fill=(255, 246, 170, 255), width=3)
    ico_save(img, "cristal_soufre")


def ic_lettre():
    img = canvas_i()
    R = rng(7714)
    for sx in (-1, 1):
        feathers = []
        for k in range(4):
            yo = 210 + k * 22
            feathers.append([(256 + sx * 150, yo), (256 + sx * (250 - k * 18), yo - 50 + k * 6), (256 + sx * (236 - k * 22), yo + 14)])
        vol(img, lambda d, f=feathers: [d.polygon(q, fill=255) for q in f], (240, 238, 232), depth=6, gloss=0.4)
    tex = 0.9 + 0.14 * tn(R, IS, (32, 64, 128), 0.6)
    vol(img, lambda d: d.rectangle((96, 150, 416, 380), fill=255), (236, 220, 184), depth=12, gloss=0.2, tex=tex)
    d = ImageDraw.Draw(img)
    d.line([(96, 380), (256, 270), (416, 380)], fill=(190, 170, 130, 255), width=5)
    vol(img, lambda d: d.polygon([(96, 150), (256, 280), (416, 150)], fill=255), (226, 206, 166), depth=10, gloss=0.2, tex=tex)
    seal = chaikin([(256 + math.cos(a) * 40 * (1 + 0.07 * math.sin(a * 5)), 276 + math.sin(a) * 40 * (1 + 0.07 * math.sin(a * 5))) for a in np.linspace(0, TAU, 30, endpoint=False)], 2)
    vol(img, lambda d: d.polygon(seal, fill=255), (176, 28, 24), depth=12, gloss=0.7)
    d = ImageDraw.Draw(img)
    for sx in (-1, 1):
        d.polygon([(256, 276), (256 + sx * 26, 262), (256 + sx * 22, 274), (256 + sx * 12, 282)], fill=(120, 14, 10, 255))
    ico_save(img, "lettre")


def ic_plume_furie():
    img = canvas_i()
    pts = bez((120, 470), (160, 250), (330, 110), (430, 50), 60)
    so._feather(img, pts, [(28, 20, 30), (44, 22, 44), (66, 20, 48), (120, 24, 44), (184, 40, 40)], width=56)
    a = np.asarray(img, np.float32) / 255.0
    h = gblur(a[..., 3], 6)
    gx, gy = grads(h)
    lam = np.clip(0.75 - gx * 18 - gy * 18, 0.4, 1.4)
    a[..., :3] = np.clip(a[..., :3] * lam[..., None], 0, 1)
    img = Image.fromarray((a * 255 + 0.5).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(img)
    d.line(pts[:50], fill=(200, 180, 190, 255), width=5)
    ico_save(img, "plume_furie")


def ic_croc_cerbere():
    img = canvas_i()
    R = rng(7716)
    d = ImageDraw.Draw(img)
    cord = ellp(256, 120, 120, 70, 180, 360, 30)
    d.line(cord, fill=(120, 80, 44, 255), width=16, joint="curve")
    d.line(cord, fill=(160, 112, 66, 255), width=6, joint="curve")
    fang = chaikin([(186, 140), (326, 140), (330, 200), (300, 300), (250, 400), (196, 466), (210, 380), (220, 290), (190, 210)], 2)
    tex = 0.9 + 0.16 * tn(R, IS, (16, 32, 64), 0.6)
    vol(img, lambda d: d.polygon(fang, fill=255), (236, 226, 196), depth=22, gloss=0.8, tex=tex)
    vol(img, lambda d: d.rounded_rectangle((176, 120, 336, 176), radius=20, fill=255), (130, 86, 50), depth=10, gloss=0.3)
    d = ImageDraw.Draw(img)
    for k in range(4):
        x = 188 + k * 40
        d.line([(x, 122), (x + 16, 174)], fill=(90, 56, 30, 255), width=5)
    d.line(chaikin([(300, 200), (284, 280), (250, 360), (214, 430)], 2, False), fill=(200, 188, 156, 200), width=4)
    ico_save(img, "croc_cerbere")


def ic_eclat_givre():
    img = canvas_i()
    R = rng(7717)
    shard = [(250, 30), (330, 150), (350, 300), (300, 470), (210, 450), (160, 300), (190, 140)]
    facets = [[shard[0], shard[1], (262, 250)], [shard[1], shard[2], (262, 250)], [shard[2], shard[3], (262, 250)], [shard[3], shard[4], (262, 250)],
              [shard[4], shard[5], (262, 250)], [shard[5], shard[6], (262, 250)], [shard[6], shard[0], (262, 250)]]
    cols = [(220, 244, 255), (170, 214, 240), (120, 176, 220), (110, 160, 210), (150, 200, 236), (196, 232, 250), (232, 248, 255)]
    for f, c in zip(facets, cols):
        vol(img, lambda d, f=f: d.polygon(f, fill=255), c, depth=3, gloss=0.6, alpha=0.95)
    d = ImageDraw.Draw(img)
    for f in facets:
        d.line([f[1], f[2]], fill=(240, 250, 255, 230), width=3)
    vol(img, lambda d: d.polygon([(110, 470), (150, 360), (196, 470)], fill=255), (160, 210, 240), depth=4, gloss=0.6)
    vol(img, lambda d: d.polygon([(330, 470), (366, 330), (396, 470)], fill=255), (190, 226, 248), depth=4, gloss=0.6)
    d = ImageDraw.Draw(img)
    for (x, y, r) in ((226, 120, 22), (300, 330, 14)):
        d.line([(x - r, y), (x + r, y)], fill=(255, 255, 255, 255), width=4)
        d.line([(x, y - r), (x, y + r)], fill=(255, 255, 255, 255), width=4)
    ico_save(img, "eclat_givre")


def ic_huile_cornes():
    img = canvas_i()
    R = rng(7718)
    bottle = chaikin([(216, 160), (296, 160), (296, 220), (360, 270), (380, 360), (360, 440), (300, 470), (212, 470), (152, 440), (132, 360), (152, 270), (216, 220)], 2)
    m = shape_i(lambda d: d.polygon(bottle, fill=255))
    vol(img, lambda d: d.polygon(bottle, fill=255), (200, 220, 222), depth=24, gloss=1.0, alpha=0.9)
    vol(img, lambda d: d.polygon(chaikin([(140, 320), (372, 320), (378, 360), (360, 440), (300, 466), (212, 466), (152, 440), (134, 360)], 2), fill=255),
        (226, 150, 30), depth=18, gloss=0.6)
    glow_i(img, 230, 380, 60, (255, 210, 90), 0.5, inside=m)
    vol(img, lambda d: d.rectangle((210, 110, 302, 170), fill=255), (150, 104, 60), depth=8, gloss=0.3, tex=0.85 + 0.25 * tn(R, IS, (16, 32, 64), 0.6))
    vol(img, lambda d: d.polygon(tube(bez((256, 112), (240, 60), (280, 30), (300, 20), 16), 34, 8), fill=255), (226, 214, 180), depth=6, gloss=0.6)
    vol(img, lambda d: d.rounded_rectangle((170, 330, 342, 420), radius=10, fill=255), (236, 222, 186), depth=6, gloss=0.2)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((178, 338, 334, 412), radius=8, outline=(150, 40, 30, 255), width=4)
    hp = bez((220, 396), (226, 360), (262, 350), (296, 352), 12)
    d.line(hp, fill=(110, 40, 30, 255), width=12, joint="curve")
    d.line(hp[:9], fill=(180, 120, 90, 255), width=5, joint="curve")
    d.line([(176, 240), (196, 300)], fill=(255, 255, 255, 160), width=8)
    ico_save(img, "huile_cornes")


def ic_brioche_braise():
    img = canvas_i()
    R = rng(7719)
    tex = 0.86 + 0.22 * tn(R, IS, (16, 32, 64, 128), 0.65)
    base = []
    for k in range(48):
        a = k / 48 * TAU
        r = 1 + 0.08 * math.cos(a * 12)
        base.append((256 + math.cos(a) * 190 * r, 330 + math.sin(a) * 110 * r))
    vol(img, lambda d: d.polygon(base, fill=255), (186, 104, 40), depth=30, gloss=0.6, tex=tex)
    vol(img, lambda d: d.ellipse((96, 210, 416, 380), fill=255), (206, 124, 48), depth=26, gloss=0.8, tex=tex)
    vol(img, lambda d: d.ellipse((176, 110, 336, 250), fill=255), (214, 132, 52), depth=24, gloss=0.9, tex=tex)
    d = ImageDraw.Draw(img)
    for k in range(10):
        a = math.radians(200 + k * 14)
        d.line([(256 + math.cos(a) * 120, 300 + math.sin(a) * 60), (256 + math.cos(a) * 160, 300 + math.sin(a) * 76)], fill=(150, 78, 30, 255), width=4)
    for _ in range(30):
        x, y = R.uniform(140, 380), R.uniform(150, 330)
        if ((x - 256) / 150) ** 2 + ((y - 280) / 120) ** 2 > 1:
            continue
        r = R.uniform(3, 6)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 150, 40, 255), outline=(200, 70, 20, 255))
    glow_i(img, 256, 190, 60, (255, 160, 60), 0.25, inside=shape_i(lambda d_: d_.ellipse((176, 110, 336, 250), fill=255)))
    ico_save(img, "brioche_braise")


ICON_NAMES_V70 = ["obole", "cle_brasier", "gateau_miel", "flamme_eternelle", "corne_or", "lanterne_braise", "diplome_infernal",
                  "piment_infernal", "cafe_brasier", "lave_glacee", "grog_soufre", "fleur_braise", "cristal_soufre", "lettre",
                  "plume_furie", "croc_cerbere", "eclat_givre", "huile_cornes", "brioche_braise"]


def icones():
    """Les objets de l'Île de Braise (128 px, ombrés et cernés comme les autres icônes)."""
    for n in ICON_NAMES_V70:
        globals()["ic_" + n]()


# =================================================================== lancement

GROUPS = {"sols": sols, "bati": bati, "panneaux": panneaux, "enseignes": enseignes, "fresques": fresques, "sceaux": sceaux, "icones": icones}


def images():
    """Chaque image qu'on peut refaire seule, par son nom de fichier (sans .png)."""
    one = {}
    for fn in (cendre, basalte, sable_noir, mousse_braise, paves_basalte, obsidienne, soufre, roche_volcan, lave_croute, lave,
               pierre_gothique, brique_noire, enduit_rouge, marbre_rouge, marbre_noir, ardoise, tuiles_rouges, cuivre_vert, bois_brule,
               fer_forge, dalles_palais, mosaique_feu, pierre_abyssale, glace, givre, boue, sable_arene,
               fenetre_gothique, vitrail_rosace, vitrail_lancette, banniere_pandemonia, affiche_tournoi, affiche_fete, plan_ville, contrat,
               fresque_porte, fresque_charon, fresque_cerbere, fresque_minos, fresque_dite, fresque_geryon, fresque_cocyte,
               sceau_contrat, lanterne_sym, flamme_sym, givre_sym):
        one[fn.__name__] = fn
    for n in range(1, 10):
        one["cercle_%d" % n] = (lambda n=n: sceau_cercle(n))
    for k in ENSEIGNES:
        one["enseigne_" + k] = (lambda k=k: enseigne(k))
    for k in ICON_NAMES_V70:
        one[k] = globals()["ic_" + k]
    return one


def main():
    what = sys.argv[1:] or list(GROUPS)
    one = images()
    for w in what:
        w = w[:-4] if w.endswith(".png") else w
        if w in GROUPS:
            GROUPS[w]()
        elif w in one:
            one[w]()
        else:
            sys.exit("inconnu : %s (%s | <nom d'une image>)" % (w, " | ".join(GROUPS)))
    if STATS:
        print("moyennes RVB :")
        for k, v in STATS.items():
            print("  %-28s %6.1f %6.1f %6.1f   (%.1f)" % (k, v[0], v[1], v[2], v.mean()))


if __name__ == "__main__":
    main()
