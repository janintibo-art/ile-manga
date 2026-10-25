"""V71 : textures de l'Île de Montjoie, la ville fortifiée des aventuriers (Moyen Âge européen,
fantaisie chaleureuse), et ses nouveaux objets.

montjoie/ — surfaces 1024 px raccordables, chacune avec sa carte de relief <nom>_n.png
          (« sols » : une tuile couvre environ 4 m x 4 m ; paves et dalles environ 3 m) :
          prairie (+_n)        : prairie tempérée vue d'en haut : graminées, brins secs, trèfle,
                                 pâquerettes, boutons d'or, trèfle rouge ;
          champ (+_n)          : terre labourée en sillons (le long de x), mottes, chaumes, cailloux ;
          chemin (+_n)         : chemin de terre battue ocre, gravillons enfoncés, fentes, traces de sabots ;
          sous_bois (+_n)      : sol de chênaie : humus, feuilles de chêne mortes, brindilles, glands, mousse ;
          roche_crocs (+_n)    : roche calcaire gris-ocre en bancs, diaclases, coulures de rouille, lichens ;
          sable_lac (+_n)      : sable fin gris-beige du lac, rides, zones humides, galets, débris de roseaux ;
          paves (+_n)          : pavés de grès et de granit usés, joints de terre et de mousse ;
          dalles (+_n)         : grandes dalles de calcaire irrégulières, usées, fêlées.
          (« bati » : une tuile couvre environ 3 m x 3 m)
          enduit (+_n)         : crépi de chaux clair, coups de truelle, auréoles, coulures, petits manques ;
          pierre_rempart (+_n) : grand appareil de calcaire gris-ocre en assises, moussu (le rempart) ;
          moellons (+_n)       : maçonnerie de moellons irréguliers hourdés à la chaux ;
          tuiles (+_n)         : toit de tuiles plates en terre cuite rouge-orangé patinée, lichens ;
          bois_planches (+_n)  : planches de chêne patinées (fil le long de x), clous, nœuds ;
          chaume (+_n)         : toit de chaume (la pente descend vers le bas de l'image), mousse ;
          colombage_motif (+_n): pan de bois : sablières, poteaux, guettes en chevron, torchis enduit ;
          pierre_donjon (+_n)  : pierre sombre et humide du Donjon des Mille Marches, salpêtre ;
          dalles_donjon (+_n)  : dallage usé et fendu du donjon, crasse dans les joints ;
          mousse_donjon (+_n)  : pierre couverte de coussins de mousse ;
          gelee (+_n)          : la gelée verte de slime qui suinte (bulles, reflets).
          — panneaux (non raccordables, sans _n) :
          fenetre_plomb (256 x 512) : croisée de chêne, vitres en losanges sertis de plomb, de jour ;
          fenetre_plomb_nuit (256 x 512) : la même, éclairée de l'intérieur (lumière chaude) ;
          vitrail_aube (512 x 1024) : verrière en arc brisé du Temple de l'Aube : le soleil levant ;
          enseigne_guilde, _auberge, _forge, _magie, _apothicaire, _boulangerie, _couture, _agence
                                 (512 x 256) : enseignes peintes des boutiques ;
          banniere_montjoie (256 x 512, RGBA) : soleil d'or levant sur une butte verte, champ d'azur ;
          blason_guilde (512 x 512, RGBA) : écu de la Guilde, épée et plume croisées, banderole ;
          tableau_liege (1024 x 768) : le tableau de liège des quêtes, cadre de chêne, punaises ;
          affiche_quete_1 … affiche_quete_6, affiche_recherche (512 x 768) : les affiches de quêtes.
items/    (« icones », 128 px, ombrées et cernées comme les autres) carte_aventurier, chapelet_soleil,
          cristal_orage, chapeau_baron, page_grimoire, coeur_gelee, navet_dore, cuisse_grenouille,
          gelee_slime, croc_gobelin, cle_cuivre, cidre_montjoie, tourte_montjoie, pain_montjoie,
          titre_propriete, jus_pomme, banniere_gobelin.

Tout est dessiné ici, procéduralement (libre de droits, aucune image tierce), avec les outils des
générateurs V69 et V70. Polices : Lora (SIL OFL 1.1) et, pour l'écriture à la main des affiches,
TeX Gyre Chorus (licence GUST, libre) si elle est installée (sinon Lora italique).
Déterministe : chaque image a sa propre graine.
Lancement depuis la racine du dépôt :
    python3 pcvr/tools/generate_montjoie_v71.py [sols | bati | donjon | panneaux | enseignes | affiches | icones | <nom>]
(sans argument : tout ; <nom> : une seule image, par ex. « prairie » ou « affiche_quete_3 »).
"""
import math
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # pas de __pycache__ dans pcvr/tools

import numpy as np  # noqa: E402
from PIL import Image, ImageDraw, ImageFilter, ImageFont  # noqa: E402

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_soleils_v69 as so  # noqa: E402
import generate_braise_v70 as br  # noqa: E402
from generate_soleils_v69 import (tn, gblur, smooth, mix, C, grads, normal_img, bake, offs, to_img, from_img,  # noqa: E402
                                  per_id, masonry, worley, warp, speck, chaikin, bez, ellp, tube, leaf_poly,
                                  blade_poly, down, font, vol)
from generate_braise_v70 import (norm01, grain, warp_nn, wrap_edt, hshadow, scatter, domes, rock_poly,  # noqa: E402
                                 worley_xy, roof_rows, Paint, paper_bg, wrap_lines, arch_pts, _glass_cells,
                                 canvas_i, glow_i, shape_i, IS)

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "montjoie"
ITEMS = ROOT / "www" / "assets" / "textures" / "items"
TAU = math.tau
STATS = {}


# =================================================================== outils

def rng(seed):
    return np.random.default_rng(seed)


def _log(p):
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


def save_surface(name, col, h, strength):
    save_rgb(col, name + ".png")
    p = OUT / (name + "_n.png")
    normal_img(h, strength).save(p, optimize=True)
    _log(p)


def up(a, k):
    """Agrandit un champ (ou une image) k fois au plus proche voisin (raccord gardé)."""
    a = np.repeat(np.repeat(a, k, 0), k, 1)
    return a


def hand_font(size):
    """Écriture à la main (affiches) : TeX Gyre Chorus si présente, sinon Lora italique."""
    for p in ("/usr/share/texmf/fonts/opentype/public/tex-gyre/texgyrechorus-mediumitalic.otf",
              "/usr/share/texlive/texmf-dist/fonts/opentype/public/tex-gyre/texgyrechorus-mediumitalic.otf"):
        if Path(p).exists():
            return ImageFont.truetype(p, int(size))
    return font(size, italic=True)


def draw_wrapped(d, S, H, items):
    """Dessine des formes (fonction f(d, ox, oy)) en les répétant aux bords (raccord)."""
    for x, y, r, f in items:
        for ox, oy in offs(x, y, r, S, H):
            f(d, ox, oy)


def stones_layer(R, S, items, pal, fine, prof_pow=0.6, hmax=0.9, hdiv=26.0):
    """Cailloux (liste d'items de scatter) : couleur, hauteur et masque (raccordables)."""
    N = len(items)
    ids = scatter(S, items)
    hn, mask = domes(ids, N)
    kind = R.choice(len(pal), N, p=[q[1] for q in pal])
    base = np.array([pal[k][0] for k in kind], np.float32) * R.uniform(0.85, 1.15, (N, 1)).astype(np.float32)
    base = np.vstack([np.zeros((1, 3), np.float32), base])
    rad = np.concatenate([[0.0], np.array([it[3] for it in items], np.float32)])
    prof = np.clip(hn * 1.6, 0, 1) ** prof_pow
    stex = tn(R, S, (32, 64, 128, 256), 0.7)
    sth = (prof * (0.85 + 0.3 * stex)) * np.minimum(hmax, 0.12 + rad / hdiv)[ids]
    scol = base[ids] * (0.8 + 0.4 * stex[..., None]) * (0.9 + 0.2 * fine[..., None]) * (0.85 + 0.2 * prof[..., None])
    return scol, sth, mask, prof


# =================================================================== les sols (une tuile ≈ 4 m)

def prairie():
    """Prairie tempérée vue d'en haut : graminées en trois épaisseurs (dessous sombre, dessus clair),
    des plaques plus grasses et d'autres plus sèches où se mêlent des brins jaunis ; trèfle blanc,
    plantain ; quelques pâquerettes, boutons d'or et têtes de trèfle rouge ; un peu de terre."""
    S, K = 1024, 2
    S2 = S * K
    R = rng(7101)
    n = tn(R, S, (8, 16, 32, 64, 128, 256), 0.6)
    hue = tn(R, S, (4, 8, 16, 32, 64), 0.8)
    lush = tn(R, S, (4, 8, 16, 32, 64), 0.7)
    dry = tn(R, S, (4, 8, 16, 32), 0.7)
    clov = tn(R, S, (8, 16, 32, 64), 0.7)
    flw = tn(R, S, (8, 16, 32, 64), 0.7)
    soil = mix(C(0.13, 0.11, 0.06), C(0.2, 0.17, 0.1), n)
    soil = mix(soil, C(0.09, 0.12, 0.05), smooth(0.4, 0.7, lush) * 0.6)
    img = to_img(up(soil, K))
    d = ImageDraw.Draw(img)
    hm = Image.new("L", (S2, S2), 0)
    dh = ImageDraw.Draw(hm)
    deep = np.array([0.15, 0.27, 0.07])
    yel = np.array([0.38, 0.45, 0.12])
    blue = np.array([0.14, 0.3, 0.14])
    straw = np.array([0.6, 0.55, 0.34])
    tufts = R.random((9000, 2)) * S2
    for p, (count, bright, hv, ls) in enumerate(((52000, 0.48, 60, 1.0), (46000, 0.74, 140, 0.92), (30000, 1.0, 215, 0.8))):
        for _ in range(count):
            cx, cy = tufts[R.integers(len(tufts))]
            x = cx + R.normal(0, 11)
            y = cy + R.normal(0, 11)
            xi, yi = int(x / K) % S, int(y / K) % S
            g = hue[yi, xi]
            if R.random() < 0.06 + 0.3 * smooth(0.5, 0.8, dry[yi, xi]):
                c = straw * R.uniform(0.75, 1.1) * (0.7 + 0.3 * bright)
            else:
                c = deep * (1 - g) + yel * g if R.random() < 0.75 else blue
                c = c * bright * (0.75 + 0.5 * lush[yi, xi]) * R.uniform(0.82, 1.18)
            col = tuple(int(np.clip(v, 0, 1) * 255) for v in c)
            a = R.uniform(0, TAU)
            L = R.uniform(34, 92) * ls
            w = R.uniform(3.5, 6.5)
            poly = blade_poly(x, y, a, L, w, R.uniform(-0.35, 0.35))
            hvv = int(hv + R.uniform(-25, 25))
            for ox, oy in offs(x, y, L + 6, S2):
                pp = [(px + ox, py + oy) for px, py in poly]
                d.polygon(pp, fill=col)
                dh.polygon(pp, fill=hvv)
        if p == 1:
            # trèfle blanc et rosettes de plantain, entre deux couches d'herbe
            for _ in range(6500):
                x, y = R.random(2) * S2
                if clov[int(y / K) % S, int(x / K) % S] < 0.6 + R.random() * 0.12:
                    continue
                r = R.uniform(5.5, 9.0)
                a0 = R.uniform(0, TAU)
                t = R.random()
                cc = (int(46 + 26 * t), int(98 + 30 * t), int(36 + 14 * t))
                for k in range(3):
                    a = a0 + k * TAU / 3
                    lx, ly = x + math.cos(a) * r * 0.95, y + math.sin(a) * r * 0.95
                    for ox, oy in offs(lx, ly, r + 2, S2):
                        d.ellipse((lx + ox - r, ly + oy - r, lx + ox + r, ly + oy + r), fill=cc)
                        dh.ellipse((lx + ox - r, ly + oy - r, lx + ox + r, ly + oy + r), fill=180)
                        d.arc((lx + ox - r * 0.55, ly + oy - r * 0.55, lx + ox + r * 0.55, ly + oy + r * 0.55), 0, 360,
                              fill=(min(255, cc[0] + 40), min(255, cc[1] + 46), min(255, cc[2] + 30)))
            for _ in range(260):
                x, y = R.random(2) * S2
                a0 = R.uniform(0, TAU)
                cc = tuple(int(v) for v in (np.array((52, 92, 34)) * R.uniform(0.85, 1.15)))
                for k in range(int(R.integers(5, 8))):
                    a = a0 + k * TAU / 6 + R.uniform(-0.2, 0.2)
                    poly = leaf_poly(x + math.cos(a) * 16, y + math.sin(a) * 16, R.uniform(28, 40), R.uniform(11, 15), a, 0.3)
                    for ox, oy in offs(x, y, 60, S2):
                        pp = [(px + ox, py + oy) for px, py in poly]
                        d.polygon(pp, fill=cc)
                        dh.polygon(pp, fill=150)
    # fleurs : (pétales, cœur, rayon, part)
    kinds = [((246, 244, 236), (236, 196, 60), 6.0, 0.45), ((246, 206, 40), (220, 160, 20), 5.0, 0.3),
             ((196, 96, 140), (160, 60, 110), 6.5, 0.15), ((250, 214, 40), (230, 170, 20), 8.0, 0.1)]
    for _ in range(2200):
        x, y = R.random(2) * S2
        if flw[int(y / K) % S, int(x / K) % S] < 0.62 + R.random() * 0.25:
            continue
        u = R.random()
        acc = 0
        for petal, heart, r, pr in kinds:
            acc += pr
            if u <= acc:
                break
        r *= R.uniform(0.8, 1.25)
        for ox, oy in offs(x, y, r + 3, S2):
            X, Y = x + ox, y + oy
            if petal[0] > 240 and petal[1] > 240:  # pâquerette
                for k in range(12):
                    a = k / 12 * TAU
                    d.line([(X, Y), (X + math.cos(a) * r, Y + math.sin(a) * r)], fill=petal, width=2)
                d.ellipse((X - r * 0.35, Y - r * 0.35, X + r * 0.35, Y + r * 0.35), fill=heart)
            elif petal[0] < 210:  # trèfle rouge : une tête en boule
                for k in range(14):
                    a, rr = R.uniform(0, TAU), R.uniform(0, r * 0.8)
                    c2 = tuple(int(v * R.uniform(0.85, 1.12)) for v in petal)
                    d.ellipse((X + math.cos(a) * rr - 2, Y + math.sin(a) * rr - 2, X + math.cos(a) * rr + 2, Y + math.sin(a) * rr + 2), fill=c2)
            elif r > 7:  # pissenlit
                for k in range(20):
                    a = k / 20 * TAU
                    d.line([(X, Y), (X + math.cos(a) * r, Y + math.sin(a) * r)], fill=petal, width=2)
                d.ellipse((X - r * 0.4, Y - r * 0.4, X + r * 0.4, Y + r * 0.4), fill=heart)
            else:  # bouton d'or : cinq pétales ronds
                for k in range(5):
                    a = k / 5 * TAU
                    px, py = X + math.cos(a) * r * 0.5, Y + math.sin(a) * r * 0.5
                    d.ellipse((px - r * 0.5, py - r * 0.5, px + r * 0.5, py + r * 0.5), fill=petal)
                d.ellipse((X - r * 0.22, Y - r * 0.22, X + r * 0.22, Y + r * 0.22), fill=heart)
            dh.ellipse((X - r, Y - r, X + r, Y + r), fill=245)
    col = down(from_img(img), K)
    h = down(np.asarray(hm, np.float32) / 255.0, K)
    col = gblur(col, 0.35)
    h = gblur(h, 0.7)
    col = bake(col, h, 3.0, k=0.25, ao=0.4, ao_r=5)
    col *= (0.92 + 0.14 * lush[..., None])
    save_surface("prairie", col, h * 0.85 + n * 0.15, 4.0)


def champ():
    """Terre labourée : douze sillons par tuile (le long de x, légèrement ondulés), billons de mottes
    sèches et claires, fonds plus sombres et humides ; miettes de terre, chaumes de blé couchés,
    petits cailloux, rares pousses vertes."""
    S = 1024
    R = rng(7102)
    nf = 12
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    wy = (tn(R, S, (2, 4, 8, 16), 0.6) - 0.5) * 26
    wx = (tn(R, S, (8, 16, 32), 0.6) - 0.5) * 10
    ph = (yy + wy) / S * nf * TAU
    ridge = (0.5 + 0.5 * np.cos(ph)) ** 0.9
    n = tn(R, S, (4, 8, 16, 32, 64, 128), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.6)
    moist = tn(R, S, (4, 8, 16, 32), 0.6)
    _, ed, cid, _, _ = worley(R, S, 96, 0.95)
    ed = warp(ed, wx, wy * 0.2)
    cid = warp_nn(cid, wx, wy * 0.2)
    size = per_id(cid, R, 0.3, 1.0)
    clod = smooth(0.0, 4.5, ed) ** 0.7 * size * (0.35 + 0.65 * ridge)
    _, ed2, cid2, _, _ = worley(R, S, 230, 0.9)
    crumb = smooth(0.0, 1.8, ed2) * per_id(cid2, R, 0.4, 1.0)
    h = ridge * 0.55 + clod * 0.3 + crumb * 0.06 + n * 0.12 + fine * 0.04 + gr * 0.03
    wet = np.clip((1 - ridge) * 0.8 + (moist - 0.5) * 0.8, 0, 1)
    col = mix(C(0.43, 0.34, 0.24), C(0.22, 0.155, 0.105), wet)
    col = col * per_id(cid, R, 0.86, 1.12)[..., None]
    col = col * (0.82 + 0.36 * gr[..., None]) * (0.93 + 0.14 * fine[..., None]) * (0.9 + 0.2 * n[..., None])
    col = mix(col, col * C(1.12, 1.08, 1.02), smooth(0.4, 0.9, clod) * 0.35)
    sp = R.random((S, S)).astype(np.float32)
    col = mix(col, C(0.6, 0.55, 0.46), (sp > 0.992) * 0.5)
    col = mix(col, C(0.12, 0.09, 0.07), (sp < 0.03) * 0.4)
    # cailloux
    items = []
    for count, rlo, rhi in ((700, 1.5, 3.5), (90, 3.5, 7.5)):
        for _ in range(count):
            r = R.uniform(rlo, rhi)
            items.append((R.random() * S, R.random() * S, rock_poly(R, r, k=int(R.integers(5, 9)), jit=0.3, sm=1), r))
    pal = [((0.62, 0.58, 0.5), 0.45), ((0.5, 0.42, 0.32), 0.3), ((0.75, 0.72, 0.66), 0.15), ((0.36, 0.33, 0.3), 0.1)]
    scol, sth, mask, prof = stones_layer(R, S, items, pal, fine)
    scol = mix(scol, col, smooth(0.5, 0.75, tn(R, S, (16, 32, 64), 0.6))[..., None] * 0.4 * (1 - prof[..., None]))
    ma = gblur(mask.astype(np.float32), 0.5)
    col = mix(col, scol, ma)
    h = h + sth * mask * 0.5
    # chaumes et pousses, dessinés par-dessus
    img = to_img(col)
    d = ImageDraw.Draw(img)
    hm = Image.fromarray((np.clip(h, 0, 1) * 255).astype(np.uint8), "L")
    dh = ImageDraw.Draw(hm)
    for _ in range(1300):
        x, y = R.random(2) * S
        a = R.uniform(0, TAU)
        L = R.uniform(6, 22)
        c = tuple(int(v * R.uniform(0.7, 1.05)) for v in (196, 172, 112))
        x2, y2 = x + math.cos(a) * L, y + math.sin(a) * L
        for ox, oy in offs(x, y, L + 2, S):
            d.line([(x + ox, y + oy), (x2 + ox, y2 + oy)], fill=c, width=1)
            dh.line([(x + ox, y + oy), (x2 + ox, y2 + oy)], fill=200, width=1)
    for _ in range(70):
        x, y = R.random(2) * S
        a0 = R.uniform(0, TAU)
        for k in range(4):
            a = a0 + k * TAU / 4
            poly = leaf_poly(x + math.cos(a) * 3, y + math.sin(a) * 3, 7, 3, a, 0.3)
            for ox, oy in offs(x, y, 10, S):
                d.polygon([(px + ox, py + oy) for px, py in poly], fill=(72, 110, 40))
    col = from_img(img)
    h = np.asarray(hm, np.float32) / 255.0
    h = gblur(h, 0.6)
    sh = hshadow(h, 10.0, 16, 1.5)
    col = col * (1 - 0.32 * sh[..., None])
    col = bake(col, h, 5.0, k=0.35, ao=0.35, ao_r=6)
    save_surface("champ", col, h, 6.0)


def chemin():
    """Chemin de terre battue : terre ocre tassée, lissée par les roues et les sabots, poussière plus
    claire, plaques plus sombres et humides ; fines fentes de sécheresse ; gravillons et cailloux
    enfoncés ; empreintes de sabots ; quelques brins de paille."""
    S = 1024
    R = rng(7103)
    n = tn(R, S, (4, 8, 16, 32, 64, 128), 0.6)
    damp_n = tn(R, S, (4, 8, 16, 32), 0.6)
    dust_n = tn(R, S, (8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.6)
    wx = tn(R, S, (8, 16, 32), 0.6)
    wy = tn(R, S, (8, 16, 32), 0.6)
    col = mix(C(0.46, 0.37, 0.26), C(0.56, 0.47, 0.34), smooth(0.3, 0.8, n))
    damp = smooth(0.6, 0.82, damp_n)
    col = mix(col, C(0.32, 0.25, 0.18), damp * 0.45)
    dust = smooth(0.5, 0.8, dust_n) * (1 - damp)
    col = mix(col, C(0.64, 0.57, 0.45), dust * 0.4)
    col = col * (0.86 + 0.28 * gr[..., None]) * (0.94 + 0.12 * fine[..., None])
    # fentes de sécheresse
    _, ce, _, _, _ = worley(R, S, 20, 0.9)
    ce = warp(ce, (wy - 0.5) * 30, (wx - 0.5) * 30)
    crk = (1 - smooth(0.3, 1.2, ce)) * smooth(0.64, 0.74, tn(R, S, (4, 8, 16), 0.6)) * (1 - damp)
    col = col * (1 - 0.22 * crk[..., None])
    h = n * 0.25 + gr * 0.04 + fine * 0.05 - crk * 0.06 + dust * 0.03 - damp * 0.03
    # empreintes de sabots (fers en croissant)
    hoof = Image.new("L", (S, S), 0)
    dhf = ImageDraw.Draw(hoof)
    for _ in range(14):
        x, y = R.random(2) * S
        a = R.uniform(0, 360)
        r = R.uniform(11, 14)
        for ox, oy in offs(x, y, r + 4, S):
            dhf.ellipse((x + ox - r, y + oy - r * 1.15, x + ox + r, y + oy + r * 1.15), fill=70)
            dhf.arc((x + ox - r, y + oy - r * 1.15, x + ox + r, y + oy + r * 1.15), a, a + 230, fill=170, width=4)
    hf = gblur(np.asarray(hoof, np.float32) / 255.0, 1.6)
    col = col * (1 - 0.1 * hf[..., None])
    h = h - hf * 0.1
    # gravillons et cailloux
    items = []
    for count, rlo, rhi in ((3400, 1.2, 3.0), (650, 3.0, 6.5), (40, 7.0, 14.0)):
        for _ in range(count):
            r = R.uniform(rlo, rhi)
            items.append((R.random() * S, R.random() * S, rock_poly(R, r, k=int(R.integers(5, 9)), jit=0.32, sm=1), r))
    pal = [((0.6, 0.57, 0.52), 0.35), ((0.66, 0.54, 0.38), 0.25), ((0.42, 0.4, 0.38), 0.2), ((0.82, 0.8, 0.74), 0.1), ((0.5, 0.36, 0.26), 0.1)]
    scol, sth, mask, prof = stones_layer(R, S, items, pal, fine)
    bury = smooth(0.45, 0.75, tn(R, S, (16, 32, 64, 128), 0.6)) * (0.3 + 0.6 * (1 - prof))
    scol = mix(scol, col, bury[..., None] * 0.6)
    ma = gblur(mask.astype(np.float32), 0.5)
    col = mix(col, scol, ma)
    h = h + sth * mask * 0.6
    img = to_img(col)
    d = ImageDraw.Draw(img)
    for _ in range(140):
        x, y = R.random(2) * S
        a = R.uniform(0, TAU)
        L = R.uniform(8, 26)
        c = tuple(int(v * R.uniform(0.75, 1.05)) for v in (204, 182, 122))
        for ox, oy in offs(x, y, L + 2, S):
            d.line([(x + ox, y + oy), (x + ox + math.cos(a) * L, y + oy + math.sin(a) * L)], fill=c, width=1)
    col = from_img(img)
    sh = hshadow(h, 6.0, 12, 1.2)
    col = col * (1 - 0.3 * sh[..., None])
    col = bake(col, h, 4.0, k=0.35, ao=0.3, ao_r=5)
    save_surface("chemin", col, h, 5.0)


def oak_leaf(x, y, L, a, lobes=None, R=None):
    """Contour d'une feuille de chêne (lobes arrondis), pétiole compris, orientée a."""
    lobes = lobes or 5
    pts_l, pts_r = [], []
    n = 40
    for k in range(n + 1):
        t = k / n
        env = math.sin(math.pi * min(1.0, t * 1.08)) ** 0.75 * (0.75 + 0.35 * t)
        lob = 0.62 + 0.38 * abs(math.sin(t * math.pi * lobes))
        w = 0.32 * L * env * lob
        pts_l.append(((t - 0.45) * L, w))
        pts_r.append(((t - 0.45) * L, -w * (0.95 + 0.1 * math.sin(t * 9))))
    pts = [(-0.55 * L, 0.0)] + pts_l + pts_r[::-1]
    ca, sa = math.cos(a), math.sin(a)
    return [(x + u * ca - v * sa, y + u * sa + v * ca) for u, v in pts]


def sous_bois():
    """Sol de chênaie : humus noir-brun, épaisse litière de feuilles de chêne (brunes, fauves, rousses,
    quelques-unes encore vertes ou noircies), brindilles et petites branches, glands et cupules,
    plaques de mousse, rares cailloux."""
    S, K = 1024, 2
    S2 = S * K
    R = rng(7104)
    n = tn(R, S, (4, 8, 16, 32, 64, 128), 0.6)
    moss_n = tn(R, S, (4, 8, 16, 32, 64), 0.65)
    dens = tn(R, S, (4, 8, 16, 32), 0.6)
    gr = grain(R, S, 0.7)
    hum = mix(C(0.11, 0.075, 0.05), C(0.2, 0.14, 0.09), n) * (0.8 + 0.4 * gr[..., None])
    moss = smooth(0.62, 0.72, moss_n)
    mfine = grain(R, S, 0.8)
    mcol = mix(C(0.16, 0.22, 0.06), C(0.32, 0.4, 0.1), mfine) * (0.85 + 0.3 * n[..., None])
    hum = mix(hum, mcol, moss)
    img = to_img(up(hum, K))
    d = ImageDraw.Draw(img)
    h0 = np.clip(0.15 + moss * 0.15 + gr * 0.05, 0, 1)
    hm = Image.fromarray((up(h0, K) * 255).astype(np.uint8), "L")
    dh = ImageDraw.Draw(hm)

    def twig(x, y, a, L, w, depth=0):
        pts = [(x, y)]
        for k in range(6):
            a += R.uniform(-0.25, 0.25)
            x += math.cos(a) * L / 6
            y += math.sin(a) * L / 6
            pts.append((x, y))
        c = tuple(int(v * R.uniform(0.7, 1.15)) for v in (78, 62, 48))
        for ox, oy in offs(pts[0][0], pts[0][1], L + 20, S2):
            q = [(px + ox, py + oy) for px, py in pts]
            d.line(q, fill=c, width=int(w), joint="curve")
            d.line([(px - w * 0.2, py - w * 0.25) for px, py in q], fill=tuple(min(255, v + 34) for v in c), width=max(1, int(w * 0.3)))
            dh.line(q, fill=int(150 + 40 * R.random()), width=int(w))
        if depth < 2 and R.random() < 0.6:
            j = int(R.integers(2, 5))
            twig(pts[j][0], pts[j][1], a + R.choice([-1, 1]) * R.uniform(0.5, 1.0), L * 0.45, max(2, w * 0.6), depth + 1)
    for _ in range(90):
        twig(R.random() * S2, R.random() * S2, R.uniform(0, TAU), R.uniform(60, 220), R.uniform(3, 9))
    leaf_cols = [((92, 58, 30), 0.3), ((128, 84, 44), 0.22), ((150, 80, 32), 0.14), ((62, 42, 26), 0.18),
                 ((168, 120, 66), 0.1), ((112, 108, 48), 0.06)]
    pc = np.array([q[1] for q in leaf_cols])
    nleaf = 9000
    for i in range(nleaf):
        x, y = R.random(2) * S2
        if moss[int(y / K) % S, int(x / K) % S] > 0.5 and R.random() < 0.8:
            continue
        if dens[int(y / K) % S, int(x / K) % S] < 0.35 and R.random() < 0.5:
            continue
        L = R.uniform(40, 92)
        a = R.uniform(0, TAU)
        base = np.array(leaf_cols[R.choice(len(leaf_cols), p=pc / pc.sum())][0], np.float32) * R.uniform(0.8, 1.15)
        hv = int(60 + 190 * i / nleaf)
        if R.random() < 0.8:
            poly = oak_leaf(x, y, L, a, int(R.integers(4, 7)))
            half = poly[1:42]
        else:
            poly = leaf_poly(x, y, L * 0.85, L * 0.42, a, 0.4)
            half = poly[:10]
        c = tuple(int(np.clip(v, 0, 255)) for v in base)
        dark = tuple(int(v * 0.62) for v in base)
        lite = tuple(int(min(255, v * 1.18)) for v in base)
        side = tuple(int(min(255, v * R.choice([0.86, 1.12]))) for v in base)
        ca, sa = math.cos(a), math.sin(a)
        for ox, oy in offs(x, y, L, S2):
            pp = [(px + ox, py + oy) for px, py in poly]
            d.polygon(pp, fill=c)
            d.polygon([(px + ox, py + oy) for px, py in half], fill=side)
            d.line(pp + [pp[0]], fill=dark, width=1)
            dh.polygon(pp, fill=hv)
            mx0, my0 = x + ox - ca * L * 0.55, y + oy - sa * L * 0.55
            mx1, my1 = x + ox + ca * L * 0.5, y + oy + sa * L * 0.5
            d.line([(mx0, my0), (mx1, my1)], fill=dark, width=2)
            for k in range(1, 5):
                t = k / 5
                bx, by = mx0 + (mx1 - mx0) * t, my0 + (my1 - my0) * t
                for sgn in (-1, 1):
                    d.line([(bx, by), (bx + (ca * 0.4 - sa * sgn) * L * 0.18, by + (sa * 0.4 + ca * sgn) * L * 0.18)], fill=dark, width=1)
            if R.random() < 0.5:
                d.line([(mx0 + 2, my0 - 2), (mx1 + 2, my1 - 2)], fill=lite, width=1)
    # glands et cupules
    for _ in range(70):
        x, y = R.random(2) * S2
        a = R.uniform(0, TAU)
        ca, sa = math.cos(a), math.sin(a)
        for ox, oy in offs(x, y, 20, S2):
            X, Y = x + ox, y + oy
            body = [(X + ca * u - sa * v, Y + sa * u + ca * v) for u, v in ellp(0, 0, 11, 7.5, n=20)]
            d.polygon(body, fill=(132, 96, 46))
            d.line([(X + ca * 2 - sa * -3, Y + sa * 2 + ca * -3), (X + ca * 7 - sa * -2, Y + sa * 7 + ca * -2)], fill=(176, 136, 76), width=2)
            cup = [(X + ca * (u - 8) - sa * v, Y + sa * (u - 8) + ca * v) for u, v in ellp(0, 0, 6, 8.5, n=20)]
            d.polygon(cup, fill=(96, 82, 56))
            dh.polygon(body, fill=255)
            dh.polygon(cup, fill=250)
    col = down(from_img(img), K)
    h = down(np.asarray(hm, np.float32) / 255.0, K)
    h = gblur(h, 0.6)
    blot = tn(R, S, (32, 64, 128, 256), 0.7)
    col = col * (0.8 + 0.4 * blot[..., None]) * (0.92 + 0.16 * grain(R, S, 0.6)[..., None])
    rot = speck(R, S, 0.004, 1.6) * (1 - moss)
    col = mix(col, C(0.12, 0.08, 0.05), np.clip(rot, 0, 1) * 0.5)
    sh = hshadow(h, 5.0, 10, 0.8)
    col = col * (1 - 0.45 * sh[..., None])
    col = gblur(col, 0.3)
    col = bake(col, h, 3.0, k=0.25, ao=0.35, ao_r=5)
    save_surface("sous_bois", col, h, 4.0)


def roche_crocs():
    """Roche des Crocs : calcaire gris-ocre naturel (une tuile ≈ 4 m) : grandes facettes de
    cassure à plusieurs échelles, bancs de stratification ondulés qui font de petits ressauts,
    fissures fines et discontinues, surface rongée (cupules, alvéoles) ; coulures ocre de rouille,
    traînées sombres, lichens gris-vert, orangés et noirs ; terre et herbe sèche au fond des creux."""
    S = 1024
    R = rng(7105)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    wx = (tn(R, S, (2, 4, 8, 16), 0.6) - 0.5) * 70
    wy = (tn(R, S, (2, 4, 8, 16), 0.6) - 0.5) * 50
    h = np.zeros((S, S), np.float32)  # hauteur en pixels
    ids = []
    for n_, slope, step in ((4, 0.55, 0.12), (9, 0.4, 0.08), (22, 0.22, 0.04)):
        _, edg, cid, dx, dy = worley(R, S, n_, 0.9)
        dx, dy = warp(dx, wx * 0.5, wy * 0.5), warp(dy, wx * 0.5, wy * 0.5)
        cid = warp_nn(cid, wx * 0.5, wy * 0.5)
        ax = per_id(cid, R, -slope, slope)
        ay = per_id(cid, R, -slope, slope * 0.5)
        cell = S / n_
        off = per_id(cid, R, -step, step) * cell
        h += off + ax * dx + ay * dy
        ids.append(cid)
    h = gblur(h, 1.2)
    # bancs de stratification (ressauts) le long de x
    nl = 7
    sv = (yy + wy + (tn(R, S, (4, 8, 16), 0.6) - 0.5) * 30) / S * nl
    li = np.floor(sv).astype(np.int32) % nl
    fr = sv - np.floor(sv)
    loff = R.uniform(-0.25, 0.25, nl).astype(np.float32)
    h += (loff[li] * smooth(0.0, 0.06, fr) + loff[(li - 1) % nl] * (1 - smooth(0.0, 0.06, fr))) * 40
    bed = np.exp(-((np.minimum(fr, 1 - fr)) / 0.005) ** 2) * smooth(0.4, 0.6, tn(R, S, (8, 16, 32), 0.6))
    rough = tn(R, S, (16, 32, 64, 128, 256), 0.7)
    rid = 1 - np.abs(tn(R, S, (8, 16, 32, 64), 0.6) - 0.5) * 2
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.6)
    pits = br.pores(R, S, 900, 0.6, 1.8)
    h = h + rough * 14 + rid * 5 + fine * 2.0 + gr * 0.6 - pits * 1.5 - bed * 3
    # fissures fines, discontinues
    _, ce, _, _, _ = worley(R, S, 6, 0.9)
    ce = warp(ce, wx * 0.4 + (tn(R, S, (16, 32, 64), 0.6) - 0.5) * 16, wy * 0.4)
    crk = (1 - smooth(0.3, 1.4, ce)) * smooth(0.55, 0.62, tn(R, S, (4, 8, 16), 0.6))
    h = h - crk * 5
    hue = np.clip(per_id(ids[0], R, 0, 1) * 0.5 + per_id(ids[1], R, 0, 1) * 0.3 + (tn(R, S, (4, 8, 16, 32), 0.6) - 0.5) * 0.8, 0, 1)
    band = (loff[li] + 0.25) * 2
    stone = mix(C(0.55, 0.54, 0.51), C(0.62, 0.54, 0.41), hue)
    stone = stone * (0.9 + 0.12 * band[..., None]) * (0.84 + 0.28 * rough[..., None]) * (0.9 + 0.18 * fine[..., None]) * (0.93 + 0.12 * gr[..., None])
    stone = stone * (1 - 0.25 * pits[..., None])
    rust = smooth(0.6, 0.85, tn(R, S, (8, 16, 32, 64, 128), 0.65, oy=(2, 4, 8, 16, 32))) * smooth(0.45, 0.7, tn(R, S, (4, 8, 16), 0.6))
    stone = mix(stone, C(0.6, 0.4, 0.21) * (0.8 + 0.3 * fine[..., None]), rust * 0.4)
    grime = smooth(0.55, 0.85, tn(R, S, (16, 32, 64, 128, 256), 0.65, oy=(2, 4, 8, 16, 32))) * smooth(0.35, 0.65, tn(R, S, (4, 8, 16), 0.6))
    stone = stone * (1 - 0.28 * grime[..., None])
    cav = np.clip(gblur(h, 6) - h, 0, None)
    cav = cav / (np.percentile(cav, 99.5) + 1e-6)
    low = smooth(0.2, 0.8, cav)
    stone = mix(stone, C(0.3, 0.25, 0.18) * (0.7 + 0.5 * gr[..., None]), low * 0.6)
    weeds = low * smooth(0.6, 0.7, tn(R, S, (8, 16, 32), 0.6))
    stone = mix(stone, C(0.5, 0.46, 0.26) * (0.6 + 0.7 * gr[..., None]), weeds * 0.7)
    upf = 1 - low
    lich = speck(R, S, 0.0018, 2.6) * smooth(0.5, 0.65, tn(R, S, (8, 16, 32), 0.6)) * upf
    stone = mix(stone, C(0.74, 0.76, 0.68) * (0.85 + 0.3 * fine[..., None]), np.clip(lich * 1.4, 0, 1) * 0.55)
    lich2 = speck(R, S, 0.0007, 2.2) * smooth(0.55, 0.7, tn(R, S, (8, 16, 32), 0.6)) * upf
    stone = mix(stone, C(0.8, 0.56, 0.16), np.clip(lich2 * 1.4, 0, 1) * 0.6)
    lich3 = speck(R, S, 0.002, 1.2) * smooth(0.6, 0.7, tn(R, S, (8, 16, 32), 0.6))
    stone = mix(stone, C(0.18, 0.18, 0.17), np.clip(lich3 * 1.4, 0, 1) * 0.5)
    col = stone * (1 - 0.4 * crk[..., None]) * (1 - 0.2 * bed[..., None])
    sh = hshadow(h, 1.0, 40, 3.0)
    col = col * (1 - 0.35 * sh[..., None])
    col = bake(col, h, 0.8, k=0.35, ao=0.4, ao_r=6)
    save_surface("roche_crocs", col, h, 0.4)


def sable_lac():
    """Sable du lac : sable fin gris-beige (grains clairs, sombres et rosés), rides de courant
    douces par endroits, plaques humides plus sombres et lisses, galets ronds, débris de coquilles,
    brins de roseaux secs et petites laisses de débris."""
    S = 1024
    R = rng(7106)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    n = tn(R, S, (4, 8, 16, 32, 64, 128), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.5)
    wet_n = tn(R, S, (2, 4, 8, 16, 32), 0.6)
    wph = (tn(R, S, (2, 4, 8, 16), 0.6) - 0.5) * 6.0
    kx, ky = 3, 22
    ph = (xx * kx + yy * ky) / S * TAU + wph * 3
    rip = np.sin(ph) * 0.5 + 0.5
    rip = rip ** 1.6
    ramp = smooth(0.42, 0.65, tn(R, S, (2, 4, 8, 16), 0.6))
    wet = smooth(0.66, 0.78, wet_n) * 0.6
    col = mix(C(0.6, 0.55, 0.45), C(0.7, 0.65, 0.53), smooth(0.3, 0.8, n))
    col = col * (0.84 + 0.32 * gr[..., None]) * (0.95 + 0.1 * fine[..., None])
    sp = R.random((S, S)).astype(np.float32)
    col = mix(col, C(0.28, 0.26, 0.24), (sp < 0.05) * 0.5)
    col = mix(col, C(0.86, 0.84, 0.8), (sp > 0.975) * 0.45)
    col = mix(col, C(0.68, 0.5, 0.42), ((sp > 0.05) & (sp < 0.07)) * 0.4)
    col = col * (1 + 0.06 * (rip - 0.5) * ramp)[..., None]
    col = mix(col, col * C(0.66, 0.64, 0.62), wet * 0.8)
    h = n * 0.18 + rip * ramp * 0.12 * (1 - wet * 0.6) + gr * 0.05 * (1 - wet * 0.7) + fine * 0.03
    items = []
    for count, rlo, rhi in ((260, 2.0, 5.0), (80, 5.0, 11.0), (8, 12.0, 20.0)):
        for _ in range(count):
            r = R.uniform(rlo, rhi)
            items.append((R.random() * S, R.random() * S, rock_poly(R, r, k=int(R.integers(7, 11)), el=R.uniform(0.6, 0.95), jit=0.12, sm=2), r))
    pal = [((0.55, 0.53, 0.5), 0.35), ((0.42, 0.4, 0.38), 0.25), ((0.68, 0.6, 0.48), 0.2), ((0.78, 0.76, 0.72), 0.1), ((0.3, 0.3, 0.3), 0.1)]
    scol, sth, mask, prof = stones_layer(R, S, items, pal, fine, prof_pow=0.45)
    scol = scol * (1 - 0.3 * wet[..., None])
    ma = gblur(mask.astype(np.float32), 0.5)
    col = mix(col, scol, ma)
    h = h + sth * mask * 0.7
    img = to_img(col)
    d = ImageDraw.Draw(img)
    hm = Image.fromarray((np.clip(h, 0, 1) * 255).astype(np.uint8), "L")
    dh = ImageDraw.Draw(hm)
    for _ in range(90):  # éclats de coquilles
        x, y = R.random(2) * S
        r = R.uniform(2.5, 6)
        a = R.uniform(0, 360)
        for ox, oy in offs(x, y, r + 2, S):
            d.chord((x + ox - r, y + oy - r, x + ox + r, y + oy + r), a, a + 170, fill=(226, 218, 204))
            dh.chord((x + ox - r, y + oy - r, x + ox + r, y + oy + r), a, a + 170, fill=180)
    for _ in range(26):  # petites laisses : brins de roseaux secs
        cx, cy = R.random(2) * S
        for _ in range(int(R.integers(4, 12))):
            x, y = cx + R.normal(0, 12), cy + R.normal(0, 6)
            a = R.normal(0.2, 0.4)
            L = R.uniform(14, 50)
            c = tuple(int(v * R.uniform(0.6, 1.0)) for v in (170, 150, 104))
            for ox, oy in offs(x, y, L + 2, S):
                d.line([(x + ox, y + oy), (x + ox + math.cos(a) * L, y + oy + math.sin(a) * L)], fill=c, width=int(R.integers(1, 3)))
                dh.line([(x + ox, y + oy), (x + ox + math.cos(a) * L, y + oy + math.sin(a) * L)], fill=170, width=2)
    col = from_img(img)
    h = gblur(np.asarray(hm, np.float32) / 255.0, 0.5)
    sh = hshadow(h, 6.0, 12, 1.0)
    col = col * (1 - 0.3 * sh[..., None])
    col = bake(col, h, 4.0, k=0.3, ao=0.25, ao_r=4)
    save_surface("sable_lac", col, h, 4.0)


def paves():
    """Pavés de la ville (une tuile ≈ 3 m) : pavés de grès gris-beige et de granit gris-bleu, à peu
    près carrés (12 à 16 cm), posés en rangs un peu ondulés, chacun bombé, de travers, aux arêtes
    arrondies, poli et éclairci sur le dessus par les pas ; joints de sable et de terre sombre,
    mousse et brins d'herbe dans certains joints."""
    S = 1024
    R = rng(7107)
    rows = []
    while sum(rows) < S:
        rows.append(float(R.uniform(46, 58)))
    rows = np.array(rows)
    rows = list(rows * S / rows.sum())
    bid, e, u, v = masonry(R, S, rows, 40, 68, rr=14.0)
    wx = (tn(R, S, (4, 8, 16, 32), 0.6) - 0.5) * 14
    wy = (tn(R, S, (4, 8, 16, 32), 0.6) - 0.5) * 12
    e = warp(e, wx, wy)
    bid = warp_nn(bid, wx, wy)
    u = warp(u, wx, wy)
    v = warp(v, wx, wy)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    rough = tn(R, S, (32, 64, 128, 256), 0.7)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.6)
    shape_n = tn(R, S, (32, 64, 128), 0.6)
    jw = 2.4 + (shape_n - 0.5) * 5.0 + per_id(bid, R, -0.8, 1.6)
    ee = e - jw
    dome = np.clip(ee / 16.0, 0, 1)
    dome = np.sqrt(dome * (2 - dome))
    tx = per_id(bid, R, -0.12, 0.12)
    ty = per_id(bid, R, -0.12, 0.12)
    h = dome * 0.5 + per_id(bid, R, -0.07, 0.05) + (u - 0.5) * tx + (v - 0.5) * ty + rough * 0.07 + fine * 0.03
    h = np.where(ee < 0, -0.15 + gr * 0.05, h)
    kind = per_id(bid, R, 0.0, 1.0)
    tone = per_id(bid, R, 0.84, 1.12)
    gran = (kind < 0.4)
    stone = np.where(gran[..., None], C(0.47, 0.48, 0.5), np.where((kind < 0.8)[..., None], C(0.56, 0.52, 0.45), C(0.5, 0.45, 0.39)))
    stone = stone * tone[..., None] * (0.88 + 0.22 * mot[..., None]) * (0.86 + 0.26 * rough[..., None])
    sp = R.random((S, S)).astype(np.float32)
    sp = gblur(sp, 0.5)
    sp = (sp - sp.mean()) / sp.std()
    stone = np.where(gran[..., None], stone * (1 + 0.11 * sp[..., None]), stone * (1 + 0.05 * sp[..., None]))
    polish = smooth(0.35, 0.95, dome) * (0.6 + 0.4 * tn(R, S, (4, 8, 16), 0.6))
    stone = mix(stone, stone * C(1.14, 1.13, 1.1), polish * 0.55)
    stone = stone * (0.78 + 0.22 * smooth(0.0, 0.6, dome))[..., None]
    joint = 1 - smooth(-1.2, 0.8, ee)
    jcol = mix(C(0.17, 0.14, 0.11), C(0.4, 0.36, 0.29), grain(R, S, 0.8)) * (0.8 + 0.3 * fine[..., None])
    mossm = smooth(0.6, 0.74, tn(R, S, (8, 16, 32, 64), 0.6))
    jcol = mix(jcol, C(0.19, 0.26, 0.08) * (0.7 + 0.6 * gr[..., None]), mossm * 0.85)
    col = mix(stone, jcol, joint)
    mossedge = (1 - smooth(-1.0, 4.0, ee)) * mossm * smooth(0.45, 0.6, rough)
    col = mix(col, C(0.22, 0.3, 0.09) * (0.8 + 0.4 * gr[..., None]), mossedge * 0.5)
    dirt = smooth(0.55, 0.85, tn(R, S, (4, 8, 16, 32), 0.6))
    col = col * (1 - 0.16 * dirt[..., None])
    h = h + mossedge * 0.04
    img = to_img(col)
    d = ImageDraw.Draw(img)
    jm = (joint > 0.6) & (mossm > 0.45)
    ys, xs = np.nonzero(jm)
    if len(xs):
        pick = R.choice(len(xs), min(700, len(xs)), replace=False)
        for i in pick:
            x, y = float(xs[i]), float(ys[i])
            a = R.uniform(0, TAU)
            L = R.uniform(5, 13)
            c = tuple(int(v_ * R.uniform(0.8, 1.2)) for v_ in (70, 100, 38))
            for ox, oy in offs(x, y, L + 2, S):
                d.polygon(blade_poly(x + ox, y + oy, a, L, 2.0, R.uniform(-0.3, 0.3)), fill=c)
    col = from_img(img)
    sh = hshadow(h, 8.0, 12, 1.0)
    col = col * (1 - 0.35 * sh[..., None])
    col = bake(col, h, 5.0, k=0.3, ao=0.45, ao_r=4)
    save_surface("paves", col, h, 6.0)


def dalles():
    """Grandes dalles de calcaire (une tuile ≈ 3 m) en rangs de largeurs inégales : pierre beige-gris
    usée, polie au milieu par les pas, quelques dalles fêlées ou épaufrées, fossiles et veines
    discrètes ; joints de mortier sali, un peu de mousse dans les coins."""
    S = 1024
    R = rng(7108)
    rows = []
    while sum(rows) < S:
        rows.append(float(R.choice([150, 180, 205, 230, 256])))
    rows = np.array(rows)
    rows = list(rows * S / rows.sum())
    bid, e, u, v = masonry(R, S, rows, 150, 340, rr=3.0)
    wx = (tn(R, S, (8, 16, 32), 0.6) - 0.5) * 6
    wy = (tn(R, S, (8, 16, 32), 0.6) - 0.5) * 6
    e = warp(e, wx, wy)
    bid = warp_nn(bid, wx, wy)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    rough = tn(R, S, (32, 64, 128, 256), 0.7)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.6)
    chip = tn(R, S, (16, 32, 64, 128), 0.7)
    e2 = e - 2.6 - np.clip(chip - 0.66, 0, 1) * 40
    tone = per_id(bid, R, 0.86, 1.1)
    hue = per_id(bid, R, 0.0, 1.0)
    stone = mix(C(0.63, 0.6, 0.54), C(0.68, 0.62, 0.5), hue) * tone[..., None]
    stone = stone * (0.88 + 0.2 * mot[..., None]) * (0.9 + 0.16 * rough[..., None]) * (0.93 + 0.12 * gr[..., None])
    # veines et petits fossiles
    _, ve, _, _, _ = worley(R, S, 6, 0.9)
    ve = warp(ve, (tn(R, S, (8, 16, 32), 0.6) - 0.5) * 60, (tn(R, S, (8, 16, 32), 0.6) - 0.5) * 60)
    vein = (1 - smooth(0.0, 1.4, ve)) * smooth(0.5, 0.65, tn(R, S, (4, 8, 16), 0.6))
    stone = stone * (1 - 0.12 * vein[..., None])
    foss = speck(R, S, 0.00025, 2.0)
    stone = mix(stone, C(0.78, 0.75, 0.68), np.clip(foss * 1.3, 0, 1) * 0.5)
    wear = smooth(0.15, 0.55, np.minimum(np.minimum(u, 1 - u), np.minimum(v, 1 - v)) * 2) * smooth(0.4, 0.7, tn(R, S, (4, 8, 16), 0.6))
    stone = mix(stone, stone * 1.08, wear * 0.6)
    face = smooth(0.0, 3.0, e2) ** 0.6
    # fêlures
    _, fe, _, _, _ = worley(R, S, 5, 0.9)
    fe = warp(fe, (tn(R, S, (16, 32, 64), 0.6) - 0.5) * 30, (tn(R, S, (16, 32, 64), 0.6) - 0.5) * 30)
    crk = (1 - smooth(0.2, 1.2, fe)) * smooth(0.66, 0.71, per_id(bid, R, 0, 1) * 0.5 + tn(R, S, (4, 8), 0.6) * 0.5) * smooth(4.0, 10.0, e)
    stone = stone * (1 - 0.38 * crk[..., None])
    chipd = np.clip((e - 2.6 - e2) / 14.0, 0, 1) * smooth(1.0, 4.0, e)
    stone = mix(stone, stone * C(1.06, 1.05, 1.03) * (0.85 + 0.3 * gr[..., None]), chipd * 0.8)
    e2 = np.maximum(e2, e - 2.6 - np.clip(chip - 0.66, 0, 1) * 4.0)
    jm = 1 - smooth(-0.5, 1.5, e - 2.6 - (rough - 0.5) * 2.0)
    mortar = C(0.36, 0.33, 0.28) * (0.75 + 0.45 * grain(R, S, 0.8)[..., None])
    mossm = smooth(0.66, 0.78, tn(R, S, (8, 16, 32, 64), 0.6)) * (1 - smooth(0.0, 8.0, e))
    mortar = mix(mortar, C(0.2, 0.27, 0.09), smooth(0.66, 0.78, tn(R, S, (8, 16, 32, 64), 0.6)) * 0.7)
    col = mix(stone * (0.85 + 0.15 * face[..., None]), mortar, jm)
    col = mix(col, C(0.22, 0.3, 0.1) * (0.7 + 0.5 * gr[..., None]), mossm * 0.5)
    dirt = smooth(0.55, 0.85, tn(R, S, (4, 8, 16, 32), 0.6))
    col = col * (1 - 0.15 * dirt[..., None])
    tiltx = per_id(bid, R, -0.04, 0.04)
    h = face * 0.5 + (u - 0.5) * tiltx + mot * 0.05 + rough * 0.05 + fine * 0.02 - jm * 0.2 - crk * 0.15
    h = h - chipd * 0.25
    sh = hshadow(h, 4.0, 8, 0.8)
    col = col * (1 - 0.3 * sh[..., None])
    col = bake(col, h, 4.0, k=0.28, ao=0.3, ao_r=4)
    save_surface("dalles", col, h, 5.0)


def sols():
    prairie()
    champ()
    chemin()
    sous_bois()
    roche_crocs()
    sable_lac()
    paves()
    dalles()


# =================================================================== le bâti (une tuile ≈ 3 m)

def enduit():
    """Crépi de chaux clair, blanc cassé un peu chaud : grain de sable, coups de truelle, nuages plus
    gris ou plus jaunes, auréoles d'humidité, coulures de pluie grises, voile verdâtre par endroits,
    fines fêlures ; quelques petits manques qui montrent les moellons dessous."""
    S = 1024
    R = rng(7201)
    mot = tn(R, S, (2, 4, 8, 16, 32, 64), 0.65)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    gr = grain(R, S, 0.9)
    gr2 = grain(R, S, 0.5)
    b1 = tn(R, S, (8, 16, 32, 64), 0.7, oy=(16, 32, 64, 128))
    b2 = tn(R, S, (16, 32, 64, 128), 0.7, oy=(8, 16, 32, 64))
    sw = tn(R, S, (4, 8, 16), 0.6)
    trowel = np.where(sw > 0.5, b1, b2)
    col = mix(C(0.79, 0.76, 0.68), C(0.86, 0.83, 0.76), mot)
    col = mix(col, col * C(1.0, 0.97, 0.9), smooth(0.5, 0.8, tn(R, S, (4, 8, 16, 32), 0.6)) * 0.5)
    col = col * (0.95 + 0.07 * trowel[..., None]) * (0.95 + 0.06 * fine[..., None]) * (0.95 + 0.07 * gr[..., None])
    grey = smooth(0.55, 0.85, tn(R, S, (4, 8, 16, 32, 64), 0.6))
    col = mix(col, C(0.62, 0.6, 0.56), grey * 0.35)
    # auréoles d'humidité (bords plus sombres)
    hn = tn(R, S, (4, 8, 16, 32), 0.6)
    ring = np.exp(-((hn - 0.68) / 0.01) ** 2) * 0.5 + smooth(0.68, 0.8, hn) * 0.4
    col = col * (1 - 0.12 * ring[..., None])
    streak = smooth(0.58, 0.85, tn(R, S, (8, 16, 32, 64, 128), 0.65, oy=(1, 2, 4, 8, 16))) * smooth(0.4, 0.7, tn(R, S, (4, 8, 16), 0.6))
    col = mix(col, col * C(0.72, 0.72, 0.7), streak * 0.5)
    algae = smooth(0.66, 0.85, tn(R, S, (4, 8, 16, 32), 0.6))
    col = mix(col, col * C(0.9, 0.93, 0.86), algae * 0.35)
    # petits manques : la chaux, puis les moellons
    cv = tn(R, S, (16, 32, 64, 128), 0.6) + (tn(R, S, (256, 512), 0.7) - 0.5) * 0.08
    cv = cv - (1 - smooth(0.5, 0.7, tn(R, S, (2, 4, 8), 0.6))) * 0.3
    loss = smooth(0.84, 0.85, cv)
    rim = np.exp(-((cv - 0.84) / 0.005) ** 2)
    _, se, sid, _, _ = worley(R, S, 40, 0.8)
    under = mix(C(0.6, 0.58, 0.53), C(0.66, 0.6, 0.5), per_id(sid, R, 0, 1)) * (0.8 + 0.3 * fine[..., None])
    under = mix(C(0.7, 0.67, 0.6) * (0.8 + 0.3 * gr[..., None]), under, smooth(1.0, 3.0, se))
    col = mix(col, under, loss)
    col = col * (1 - 0.12 * rim[..., None])
    wx = tn(R, S, (8, 16, 32), 0.6)
    wy = tn(R, S, (8, 16, 32), 0.6)
    _, edge, _, _, _ = worley(R, S, 7, 0.9)
    edge = warp(edge, (wx - 0.5) * 40, (wy - 0.5) * 40)
    crack = (1 - smooth(0.2, 0.8, edge)) * smooth(0.66, 0.74, tn(R, S, (4, 8, 16), 0.6))
    col = col * (1 - 0.25 * crack[..., None])
    h = 0.6 + mot * 0.08 + trowel * 0.05 + gr * 0.06 + gr2 * 0.03 + fine * 0.03 - loss * (0.25 - smooth(1.0, 3.0, se) * 0.1) - crack * 0.12
    sh = hshadow(h, 4.0, 8, 0.6)
    col = col * (1 - 0.3 * sh[..., None])
    col = bake(col, h, 4.0, k=0.25, ao=0.25, ao_r=3)
    save_surface("enduit", col, h, 4.0)


def pierre_rempart():
    """Le rempart : grand appareil de calcaire gris-ocre en assises (40 à 50 cm), blocs de 60 cm à
    1,3 m, faces rustiques bombées, arêtes épaufrées ; joints de mortier de chaux en retrait ;
    mousse dans les joints et en coussins sur les arêtes, lichens gris et jaunes, coulures sombres
    sous les joints, plaques plus claires lavées par la pluie."""
    S = 1024
    R = rng(7202)
    rows = []
    while sum(rows) < S:
        rows.append(float(R.uniform(130, 165)))
    rows = np.array(rows)
    rows = list(rows * S / rows.sum())
    bid, e, u, v = masonry(R, S, rows, 200, 440, rr=5.0)
    wx = (tn(R, S, (8, 16, 32), 0.6) - 0.5) * 8
    wy = (tn(R, S, (8, 16, 32), 0.6) - 0.5) * 6
    e = warp(e, wx, wy)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    rough = tn(R, S, (16, 32, 64, 128, 256), 0.7)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    gr = grain(R, S, 0.6)
    chip = tn(R, S, (16, 32, 64, 128), 0.7)
    e2 = e - 4.0 - np.clip(chip - 0.6, 0, 1) * 50.0 - (rough - 0.5) * 8
    boss = smooth(0.0, 26.0, e2) ** 0.5
    tone = per_id(bid, R, 0.84, 1.12)
    hue = per_id(bid, R, 0.0, 1.0)
    stone = mix(C(0.58, 0.56, 0.51), C(0.64, 0.57, 0.44), np.clip(hue + (mot - 0.5) * 0.6, 0, 1)) * tone[..., None]
    stone = stone * (0.84 + 0.3 * rough[..., None]) * (0.9 + 0.18 * fine[..., None]) * (0.93 + 0.12 * gr[..., None])
    pits = br.pores(R, S, 1000, 0.5, 1.2)
    stone = stone * (1 - 0.2 * pits[..., None])
    chipd = np.clip((e - 4.0 - e2) / 30.0, 0, 1) * smooth(0.0, 4.0, e)
    stone = mix(stone, stone * C(1.1, 1.08, 1.04), chipd * 0.5)
    rhs = np.zeros_like(v)
    top = 0
    for hgt in rows:
        rhs[top:top + int(round(hgt))] = hgt
        top += int(round(hgt))
    below = v * rhs
    stk = tn(R, S, (32, 64, 128, 256), 0.65, oy=(2, 4, 8, 16))
    Lr = 20 + 80 * stk
    soot = np.exp(-below / Lr) * smooth(0.45, 0.75, tn(R, S, (64, 128, 256, 512), 0.7, oy=(4, 8, 16, 32))) * smooth(0.3, 0.6, tn(R, S, (4, 8, 16), 0.6))
    stone = mix(stone, C(0.2, 0.21, 0.17), np.clip(soot, 0, 1) * 0.5)
    wash = smooth(0.6, 0.85, tn(R, S, (16, 32, 64, 128), 0.6, oy=(2, 4, 8, 16)))
    stone = mix(stone, stone * C(1.12, 1.12, 1.1), wash * 0.4)
    li1 = speck(R, S, 0.0016, 2.8) * smooth(0.5, 0.65, tn(R, S, (8, 16, 32), 0.6))
    stone = mix(stone, C(0.76, 0.77, 0.72), np.clip(li1 * 1.4, 0, 1) * 0.55)
    li2 = speck(R, S, 0.0006, 2.4) * smooth(0.55, 0.7, tn(R, S, (8, 16, 32), 0.6))
    stone = mix(stone, C(0.8, 0.66, 0.2), np.clip(li2 * 1.4, 0, 1) * 0.6)
    stone = stone * (0.84 + 0.16 * boss[..., None])
    jm = 1 - smooth(1.5, 3.5, e)
    mortar = C(0.62, 0.6, 0.55) * (0.75 + 0.4 * grain(R, S, 0.8)[..., None]) * (0.9 + 0.2 * fine[..., None])
    col = mix(stone, mortar, jm)
    # mousse : dans les joints et en coussins sur les arêtes, par plaques
    mz = smooth(0.55, 0.75, tn(R, S, (4, 8, 16, 32, 64), 0.6))
    clump = tn(R, S, (16, 32, 64, 128), 0.6)
    reach = 3.0 + 60.0 * smooth(0.45, 0.85, clump) * (0.4 + 0.6 * (v > 0.5))
    near = 1 - smooth(reach * 0.4, reach, e)
    mfib = grain(R, S, 0.7)
    moss = np.clip(near * mz * 1.6, 0, 1) * smooth(0.3, 0.55, mfib * 0.4 + rough * 0.3 + clump * 0.3)
    mcol = mix(C(0.16, 0.22, 0.06), C(0.36, 0.42, 0.12), mfib) * (0.8 + 0.4 * mot[..., None])
    col = mix(col, mcol, moss * 0.95)
    tilt = per_id(bid, R, -0.05, 0.05)
    h = boss * 0.55 + (u - 0.5) * tilt + rough * 0.14 + fine * 0.04 + gr * 0.02 - jm * 0.18 - pits * 0.05 + moss * (0.12 + mfib * 0.08)
    h = h - np.clip((e - 4.0 - e2) / 40.0, 0, 0.5) * 0.4
    sh = hshadow(h, 9.0, 14, 1.0)
    col = col * (1 - 0.35 * sh[..., None])
    col = bake(col, h, 6.0, k=0.38, ao=0.35, ao_r=5)
    save_surface("pierre_rempart", col, h, 6.0)


def moellons():
    """Maçonnerie de moellons : pierres irrégulières (10 à 35 cm) grossièrement assisées, calcaire
    gris, ocre et brun, quelques grès rougeâtres, faces bossuées ; épais joints de mortier de chaux
    sableux, en retrait et un peu salis ; petites cales de pierre dans les joints."""
    S = 1024
    R = rng(7203)
    wx = (tn(R, S, (8, 16, 32), 0.6) - 0.5) * 14
    wy = (tn(R, S, (8, 16, 32), 0.6) - 0.5) * 10
    _, e, cid, dx, dy = worley_xy(R, S, S, 12, 17, jitter=0.85, rx=2, ry=1)
    e = warp(e, wx, wy)
    cid = warp_nn(cid, wx, wy)
    e = gblur(e, 3.0)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    rough = tn(R, S, (16, 32, 64, 128, 256), 0.7)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    gr = grain(R, S, 0.6)
    jw = 6.0 + (tn(R, S, (16, 32, 64), 0.6) - 0.5) * 9.0 + per_id(cid, R, -1.5, 4.0)
    ee = e - jw - (rough - 0.5) * 4
    dome = np.clip(ee / 28.0, 0, 1)
    dome = np.sqrt(dome * (2 - dome))
    kind = per_id(cid, R, 0, 1)
    tone = per_id(cid, R, 0.82, 1.15)
    pal = np.array([(0.55, 0.53, 0.49), (0.6, 0.55, 0.45), (0.5, 0.46, 0.4), (0.54, 0.45, 0.38), (0.64, 0.62, 0.57)], np.float32)
    ki = np.digitize(kind, [0.4, 0.65, 0.82, 0.9])
    stone = pal[ki] * tone[..., None] * (0.84 + 0.3 * rough[..., None]) * (0.9 + 0.18 * fine[..., None]) * (0.93 + 0.12 * gr[..., None])
    stone = stone * (0.85 + 0.15 * dome[..., None])
    li = speck(R, S, 0.0012, 2.2) * smooth(0.5, 0.65, tn(R, S, (8, 16, 32), 0.6))
    stone = mix(stone, C(0.74, 0.75, 0.7), np.clip(li * 1.4, 0, 1) * 0.45)
    joint = 1 - smooth(-1.0, 1.0, ee)
    mortar = C(0.68, 0.65, 0.58) * (0.72 + 0.5 * grain(R, S, 0.9)[..., None]) * (0.9 + 0.2 * fine[..., None])
    dirt = smooth(0.5, 0.85, tn(R, S, (8, 16, 32, 64), 0.6, oy=(4, 8, 16, 32)))
    mortar = mortar * (1 - 0.25 * dirt[..., None])
    col = mix(stone, mortar, joint)
    col = col * (1 - 0.12 * smooth(0.55, 0.85, tn(R, S, (4, 8, 16, 32), 0.6))[..., None])
    tx = per_id(cid, R, -0.15, 0.15)
    h = dome * 0.6 + per_id(cid, R, -0.05, 0.1) + dx / 60.0 * tx + rough * 0.12 + fine * 0.03
    h = np.where(ee < 0, -0.1 + grain(R, S, 0.8) * 0.06 - smooth(0.0, -4.0, ee) * 0.05, h)
    sh = hshadow(h, 14.0, 18, 1.2)
    col = col * (1 - 0.4 * sh[..., None])
    col = bake(col, h, 7.0, k=0.4, ao=0.45, ao_r=6)
    save_surface("moellons", col, h, 7.0)


def tuiles():
    """Toit de tuiles plates en terre cuite (tuiles de Bourgogne) : rangs décalés d'une demi-tuile,
    bas arrondi aux coins, chaque tuile un peu bombée et de travers ; cuissons variées (rouge
    orangé, brun-rouge, rose pâle, quelques noircies), parement sablé ; lichens jaunes et gris,
    mousse dans les joints, coulures sombres."""
    S = 1024
    R = rng(7204)
    nr, nc = 16, 12

    def corner(u):
        k = 0.22
        t = np.clip((np.abs(u) - (1 - k)) / k, 0, 1)
        return 1 - np.sqrt(np.clip(1 - t * t, 0, 1))
    bid, db, u, rr, cc = roof_rows(R, S, nr, nc, corner, 13.0, 1.2)
    rh = S / nr
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    gr = grain(R, S, 0.6)
    tone = per_id(bid, R, 0.84, 1.14)
    hue = per_id(bid, R, 0.0, 1.0)
    tx = per_id(bid, R, -0.05, 0.05)
    side = (1 - np.abs(u)) * S / nc * 0.5
    gap = 1 - smooth(0.6, 2.4, side)
    face = smooth(0.0, 2.5, db)
    slope = np.clip(db / (rh * 1.8), 0, 1)
    camber = 1 - u * u
    h = 0.72 - 0.28 * slope + u * tx + camber * 0.08 + mot * 0.04 + fine * 0.02 + gr * 0.015
    h = h * face + (1 - face) * (0.5 - 0.28 * slope)
    h = h - gap * 0.3
    pal = np.array([(0.58, 0.3, 0.2), (0.52, 0.28, 0.19), (0.62, 0.38, 0.26), (0.48, 0.31, 0.24), (0.66, 0.45, 0.34), (0.34, 0.21, 0.16)], np.float32)
    ki = np.digitize(hue, [0.32, 0.55, 0.72, 0.84, 0.94])
    col = pal[ki] * tone[..., None] * (0.86 + 0.24 * mot[..., None]) * (0.84 + 0.3 * gr[..., None]) * (0.92 + 0.14 * fine[..., None])
    sp = R.random((S, S)).astype(np.float32)
    col = mix(col, col * 0.7, (sp < 0.04) * 0.6)
    bot = smooth(30.0, 0.0, db)
    col = col * (1 - 0.1 * bot[..., None])
    top = smooth(rh * 0.9, rh * 1.4, db)
    col = col * (1 - 0.18 * top[..., None])
    li = speck(R, S, 0.0012, 2.6) * smooth(0.45, 0.65, tn(R, S, (4, 8, 16), 0.6))
    col = mix(col, C(0.78, 0.76, 0.66), np.clip(li * 1.5, 0, 1) * 0.55)
    lo = speck(R, S, 0.0009, 2.2) * smooth(0.5, 0.65, tn(R, S, (4, 8, 16), 0.6))
    col = mix(col, C(0.84, 0.62, 0.16), np.clip(lo * 1.5, 0, 1) * 0.6)
    bl = smooth(0.7, 0.8, tn(R, S, (16, 32, 64), 0.6)) * smooth(0.5, 0.6, fine)
    col = mix(col, C(0.16, 0.13, 0.11), bl * 0.25)
    streak = smooth(0.6, 0.85, tn(R, S, (32, 64, 128, 256), 0.65, oy=(2, 4, 8, 16)))
    col = col * (1 - 0.12 * streak[..., None])
    col = mix(col, col.mean(-1, keepdims=True) * C(1.1, 1.0, 0.92), 0.12)
    crev = smooth(8.0, 0.0, db) + gap
    moss = np.clip(crev, 0, 1) * smooth(0.6, 0.72, tn(R, S, (16, 32, 64), 0.6))
    col = mix(col, C(0.2, 0.25, 0.08) * (0.7 + 0.6 * gr[..., None]), moss * 0.7)
    col = col * (1 - 0.55 * gap[..., None])
    sh = hshadow(h, 6.0, 12, 0.8)
    col = col * (1 - 0.4 * sh[..., None])
    col = bake(col, h, 4.0, k=0.3, ao=0.35, ao_r=4)
    save_surface("tuiles", col, h, 5.0)


def wood_grain(R, S, H=None):
    """Champ de fil du bois (raccordable), étiré le long de x : (veines, lignes de cernes)."""
    H = H or S
    g1 = tn(R, S, (2, 4, 8, 16), 0.7, H=H, oy=(16, 32, 64, 128))
    g2 = tn(R, S, (4, 8, 16, 32, 64), 0.6, H=H, oy=(64, 128, 256, 512, 1024))
    return g1, g2


def bois_planches():
    """Plancher (ou bardage) de chêne patiné : dix planches par tuile, le fil le long de x, longueurs
    inégales aboutées ; cernes et maillures, quelques nœuds, fentes de bout ; bois brun-gris
    usé plus clair au milieu des planches, crasse dans les veines ; joints sombres, clous forgés."""
    S = 1024
    R = rng(7205)
    nrow = 10
    rh = S / nrow
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    r = np.floor(yy / rh).astype(np.int32)
    lv = yy - r * rh
    bid = np.zeros((S, S), np.int32)
    lu = np.zeros((S, S), np.float32)
    blen = np.zeros((S, S), np.float32)
    ends = []
    for k in range(nrow):
        ws = []
        while sum(ws) < S:
            ws.append(R.uniform(300, 900))
        ws = np.array(ws)
        ws *= S / ws.sum()
        cum = np.cumsum(ws)
        off = R.uniform(0, S)
        sl = slice(int(round(k * rh)), int(round((k + 1) * rh)))
        xr = np.mod(xx[sl] + off, S)
        idx = np.searchsorted(cum, xr, side="right")
        idx = np.minimum(idx, len(cum) - 1)
        left = np.where(idx > 0, cum[np.maximum(idx - 1, 0)], 0.0)
        bid[sl] = k * 100 + idx
        lu[sl] = xr - left
        blen[sl] = cum[idx] - left
        for c_ in cum:
            ends.append((float((c_ - off) % S), (k + 0.5) * rh))
    g1, g2 = wood_grain(R, S)
    ph = per_id(bid, R, 0, 50)
    fq = per_id(bid, R, 0.8, 1.4)
    yl = lv + (g1 - 0.5) * 60 + ph
    rings = np.abs(np.sin(yl * 0.22 * fq + g2 * 3.0))
    rings = 1 - smooth(0.0, 0.25, rings)
    ray = smooth(0.72, 0.8, tn(R, S, (32, 64, 128), 0.6, oy=(256, 512, 1024)))
    # nœuds
    knot = np.zeros((S, S), np.float32)
    for _ in range(9):
        kx, ky = R.random() * S, (int(R.integers(nrow)) + R.uniform(0.25, 0.75)) * rh
        rx, ry = R.uniform(7, 14), R.uniform(5, 9)
        dxk = np.mod(xx - kx + S / 2, S) - S / 2
        dyk = np.mod(yy - ky + S / 2, S) - S / 2
        dd = np.sqrt((dxk / rx) ** 2 + (dyk / ry) ** 2)
        knot = np.maximum(knot, smooth(1.3, 0.6, dd))
        rings = np.maximum(rings, np.exp(-((dd - 1.6) / 0.25) ** 2) * 0.8 * smooth(6, 2, dd) + np.exp(-((dd - 2.4) / 0.3) ** 2) * 0.5 * smooth(6, 2, dd))
    tone = per_id(bid, R, 0.82, 1.12)
    hue = per_id(bid, R, 0, 1)
    wood = mix(C(0.47, 0.36, 0.25), C(0.5, 0.45, 0.38), hue) * tone[..., None]
    fib = tn(R, S, (4, 8, 16, 32), 0.7, oy=(128, 256, 512, 1024))
    fib2 = grain(R, S, 0.5)
    wood = wood * (0.84 + 0.3 * g2[..., None]) * (1 - 0.3 * rings[..., None]) * (1 + 0.06 * ray[..., None]) * (0.8 + 0.4 * fib[..., None]) * (0.95 + 0.08 * fib2[..., None])
    wood = mix(wood, C(0.2, 0.14, 0.09), knot * 0.8)
    edge_d = np.minimum(lv, rh - lv)
    end_d = np.minimum(lu, blen - lu)
    mid = smooth(4.0, 30.0, edge_d)
    wood = mix(wood, wood * C(1.12, 1.1, 1.06), mid * smooth(0.45, 0.75, tn(R, S, (2, 4, 8), 0.6, oy=(8, 16, 32))) * 0.5)
    grey = smooth(0.5, 0.8, tn(R, S, (4, 8, 16, 32), 0.6, oy=(16, 32, 64, 128)))
    wood = mix(wood, C(0.52, 0.5, 0.46) * (0.8 + 0.4 * fib[..., None]), grey * 0.3)
    # fentes de bout
    split = np.zeros((S, S), np.float32)
    for k in range(nrow):
        pass
    sp_n = tn(R, S, (2, 4, 8), 0.6, oy=(64, 128, 256))
    split = smooth(0.8, 0.86, sp_n) * smooth(60.0, 0.0, end_d) * smooth(6.0, 12.0, edge_d)
    wood = wood * (1 - 0.6 * split[..., None])
    gap = 1 - smooth(1.2, 2.8, np.minimum(edge_d, end_d + 0.5))
    col = wood * (1 - 0.85 * gap[..., None])
    dirt = smooth(0.55, 0.85, tn(R, S, (8, 16, 32, 64), 0.6))
    col = col * (1 - 0.14 * dirt[..., None])
    cup = per_id(bid, R, 0.0, 0.08)
    h = 0.6 - cup * ((lv / rh - 0.5) * 2) ** 2 + per_id(bid, R, -0.04, 0.04) - rings * 0.06 + g2 * 0.04 + fib * 0.04 - split * 0.15 - gap * 0.4 + knot * 0.03
    img = to_img(col)
    d = ImageDraw.Draw(img)
    hm = Image.fromarray((np.clip(h, 0, 1) * 255).astype(np.uint8), "L")
    dh = ImageDraw.Draw(hm)
    for (ex, ey) in ends:
        for side_ in (-1, 1):
            if R.random() < 0.3:
                continue
            nx = ex + side_ * R.uniform(12, 18)
            for ny in (ey - rh * 0.25, ey + rh * 0.25):
                ny += R.uniform(-3, 3)
                rr_ = R.uniform(3.2, 4.2)
                for ox, oy in offs(nx, ny, 10, S):
                    d.ellipse((nx + ox - rr_, ny + oy - rr_, nx + ox + rr_, ny + oy + rr_), fill=(40, 34, 30))
                    d.ellipse((nx + ox - rr_ * 0.6 - 0.8, ny + oy - rr_ * 0.6 - 0.8, nx + ox + rr_ * 0.2, ny + oy + rr_ * 0.2), fill=(88, 80, 74))
                    dh.ellipse((nx + ox - rr_, ny + oy - rr_, nx + ox + rr_, ny + oy + rr_), fill=190)
    col = from_img(img)
    rust = np.zeros((S, S), np.float32)
    h = np.asarray(hm, np.float32) / 255.0
    col = bake(col, h, 4.0, k=0.25, ao=0.3, ao_r=3)
    save_surface("bois_planches", col, h, 4.0)


def chaume():
    """Toit de chaume (la pente descend vers le bas de l'image) : six rangs de bottes de roseau et
    de paille dont on voit les bouts coupés, tassés et peignés vers le bas ; paille dorée sous les
    rangs, grise et brune là où elle a vieilli ; ombre sous chaque rang, mousse par plaques."""
    S, K = 1024, 2
    S2 = S * K
    R = rng(7206)
    nr = 6
    rh2 = S2 / nr
    age = tn(R, S, (2, 4, 8, 16, 32), 0.6)
    mz = smooth(0.62, 0.78, tn(R, S, (4, 8, 16, 32), 0.6))
    base = mix(C(0.24, 0.2, 0.14), C(0.3, 0.25, 0.17), age)
    img = to_img(up(base, K))
    hm = Image.new("L", (S2, S2), 40)
    gold = np.array((0.7, 0.58, 0.34))
    grey = np.array((0.5, 0.46, 0.38))
    brown = np.array((0.42, 0.33, 0.22))
    rowjit = (tn(R, S2, (8, 16, 32), 0.6, H=64)[0] - 0.5) * 40  # bord du rang ondulé (le long de x)

    def draw_row(k, d, dh):
        top = k * rh2
        for _ in range(15000):
            x = R.random() * S2
            yb = top + rh2 + rowjit[int(x) % S2] + R.normal(0, 8)  # bout coupé
            L = R.uniform(rh2 * 0.75, rh2 * 1.3)
            a = math.pi / 2 + R.normal(0, 0.07)
            y0 = yb - L
            xi, yi = int(x / K) % S, int(yb / K) % S
            t = age[yi, xi]
            u_ = R.random()
            c = gold * (1 - t) + grey * t if u_ < 0.82 else brown
            c = c * R.uniform(0.72, 1.12)
            col = tuple(int(np.clip(v, 0, 1) * 255) for v in c)
            dk = tuple(int(v * 0.84) for v in col)
            w = int(round(R.uniform(2.0, 4.2)))
            x0 = x - math.cos(a) * L
            xm, ym = x - math.cos(a) * L * 0.35, yb - L * 0.35
            hv = int(140 + 80 * R.random())
            for ox, oy in offs(x, (y0 + yb) / 2, L / 2 + 8, S2):
                d.line([(x0 + ox, y0 + oy), (xm + ox, ym + oy)], fill=dk, width=w)
                d.line([(xm + ox, ym + oy), (x + ox, yb + oy)], fill=col, width=w)
                d.line([(xm + ox - 1, ym + oy), (x + ox - 1, yb + oy)], fill=tuple(min(255, int(v * 1.18)) for v in col), width=1)
                dh.line([(x0 + ox, y0 + oy), (xm + ox, ym + oy)], fill=hv - 40, width=w)
                dh.line([(xm + ox, ym + oy), (x + ox, yb + oy)], fill=hv, width=w)
                d.ellipse((x + ox - w * 0.5, yb + oy - w * 0.5, x + ox + w * 0.5, yb + oy + w * 0.5), fill=tuple(int(v * 0.85) for v in col))
    d = ImageDraw.Draw(img)
    dh = ImageDraw.Draw(hm)
    order = list(range(nr - 1, -1, -1))
    for k in order:
        draw_row(k, d, dh)
    # le dernier rang déborde sur le premier (raccord vertical) : on le redessine au-dessus, en bande
    lay = Image.new("RGB", (S2, S2))
    layh = Image.new("L", (S2, S2))
    st = R.bit_generator.state
    R.bit_generator.state = st
    draw_row(nr - 1, ImageDraw.Draw(lay), ImageDraw.Draw(layh))
    m = Image.new("L", (S2, S2), 0)
    dm = ImageDraw.Draw(m)
    dm.rectangle((0, 0, S2, 90), fill=255)
    msk = np.asarray(lay.convert("L"), np.float32) > 0
    mm = (np.asarray(m, np.float32) > 0) & msk
    a_img = np.asarray(img).copy()
    a_lay = np.asarray(lay)
    a_img[mm] = a_lay[mm]
    a_h = np.asarray(hm).copy()
    a_h[mm] = np.asarray(layh)[mm]
    col = down(a_img.astype(np.float32) / 255.0, K)
    h = down(a_h.astype(np.float32) / 255.0, K)
    # ombre sous chaque rang, rangs plus sombres au fond
    yy = np.mgrid[0:S, 0:S][0].astype(np.float32)
    h = gblur(h, 0.6)
    sh = hshadow(h, 10.0, 14, 1.2)
    col = col * (1 - 0.45 * sh[..., None])
    col = col * (0.88 + 0.2 * tn(R, S, (8, 16, 32, 64), 0.6)[..., None])
    mfib = grain(R, S, 0.8)
    moss = mz * smooth(0.35, 0.6, mfib * 0.5 + tn(R, S, (32, 64, 128), 0.6) * 0.5)
    col = mix(col, mix(C(0.18, 0.22, 0.08), C(0.36, 0.4, 0.16), mfib), moss * 0.85)
    h = h + moss * 0.08 * mfib
    col = bake(col, h, 3.0, k=0.25, ao=0.4, ao_r=5)
    save_surface("chaume", col, h, 4.0)


def colombage_motif():
    """Pan de bois (une tuile ≈ 3 m de large, un étage de haut) : sablière en haut et en bas (le
    même bois au raccord), deux poteaux, une entretoise, des guettes en chevron ; chêne vieilli
    brun sombre à gris, fentes du bois, chevilles ; entre les bois, torchis enduit à la chaux, un
    peu en retrait, sali le long des bois, fêlé au bord."""
    S = 1024
    R = rng(7207)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    beams = []  # (polygone, angle du fil en radians)
    sb = 30
    beams.append(([(-10, -sb), (S + 10, -sb), (S + 10, sb), (-10, sb)], 0.0))  # sablière (raccord haut/bas)
    for x0, w in ((0, 30), (512, 26)):
        beams.append(([(x0 - w, 0), (x0 + w, 0), (x0 + w, S), (x0 - w, S)], math.pi / 2))
    ye = 600
    beams.append(([(26, ye - 20), (486, ye - 20), (486, ye + 20), (26, ye + 20)], 0.0))
    beams.append(([(538, ye - 20), (S - 30, ye - 20), (S - 30, ye + 20), (538, ye + 20)], 0.0))
    # guettes : de bas en haut vers le poteau du milieu (chevron), sous l'entretoise et au-dessus
    for (xa, ya, xb, yb_) in ((30, S - 30, 486, ye + 20), (S - 30, S - 30, 538, ye + 20), (30, ye - 20, 486, 30), (S - 30, ye - 20, 538, 30)):
        a = math.atan2(yb_ - ya, xb - xa)
        nx, ny = -math.sin(a) * 19, math.cos(a) * 19
        beams.append(([(xa + nx, ya + ny), (xb + nx, yb_ + ny), (xb - nx, yb_ - ny), (xa - nx, ya - ny)], a))
    g1, g2 = wood_grain(R, S)
    tid = np.zeros((S, S), np.int32)
    ang = np.zeros((S, S), np.float32)
    for i, (pts, a) in enumerate(beams, 1):
        m = Image.new("L", (S, S), 0)
        dm = ImageDraw.Draw(m)
        for ox in (-S, 0, S):
            for oy in (-S, 0, S):
                dm.polygon([(x + ox, y + oy) for x, y in pts], fill=255)
        mm = np.asarray(m) > 127
        if i > 1 and a == 0.0:
            mm &= tid == 0
        tid = np.where(mm & ((tid == 0) | (i <= 3)), i, tid)
        ang = np.where(tid == i, a, ang)
    timber = tid > 0
    dtim = wrap_edt(timber, 64)
    dpl = wrap_edt(~timber, 64)
    ca, sa = np.cos(ang), np.sin(ang)
    U = xx * ca + yy * sa
    V = -xx * sa + yy * ca
    g1r = warp(g1, (U - xx), (V - yy))
    g2r = warp(g2, (U - xx), (V - yy))
    rings = 1 - smooth(0.0, 0.3, np.abs(np.sin((V + (g1r - 0.5) * 70) * 0.18 + g2r * 2.5)))
    tone = per_id(tid, R, 0.85, 1.12)
    fibr = warp(tn(R, S, (4, 8, 16, 32), 0.7, oy=(128, 256, 512, 1024)), (U - xx), (V - yy))
    wood = C(0.31, 0.23, 0.17) * tone[..., None] * (0.78 + 0.44 * g2r[..., None]) * (1 - 0.22 * rings[..., None]) * (0.6 + 0.8 * fibr[..., None])
    grey = smooth(0.4, 0.8, warp(tn(R, S, (4, 8, 16, 32), 0.6, oy=(16, 32, 64, 128)), (U - xx), (V - yy)))
    wood = mix(wood, C(0.44, 0.41, 0.37) * (0.6 + 0.8 * fibr[..., None]), grey * 0.5)
    wood = wood * (0.9 + 0.15 * grain(R, S, 0.6)[..., None])
    chk = smooth(0.78, 0.84, warp(tn(R, S, (2, 4, 8), 0.6, oy=(64, 128, 256)), (U - xx), (V - yy))) * smooth(4.0, 10.0, dpl)
    wood = wood * (1 - 0.75 * chk[..., None])
    wood = wood * (0.75 + 0.25 * smooth(0.0, 8.0, dpl))[..., None]
    # torchis enduit
    mot = tn(R, S, (2, 4, 8, 16, 32), 0.65)
    gr = grain(R, S, 0.9)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    pl = mix(C(0.8, 0.76, 0.66), C(0.86, 0.82, 0.73), mot) * (0.97 + 0.04 * grain(R, S, 0.5)[..., None]) * (0.96 + 0.05 * fine[..., None])
    pl = mix(pl, C(0.64, 0.62, 0.57), smooth(0.55, 0.85, tn(R, S, (4, 8, 16, 32, 64), 0.6)) * 0.3)
    grime = np.exp(-dtim / (10 + 25 * tn(R, S, (8, 16, 32), 0.6)))
    pl = mix(pl, pl * C(0.7, 0.66, 0.6), grime * 0.55)
    streak = smooth(0.6, 0.85, tn(R, S, (8, 16, 32, 64, 128), 0.65, oy=(1, 2, 4, 8, 16)))
    pl = mix(pl, pl * C(0.78, 0.77, 0.74), streak * 0.4)
    gapl = np.exp(-((dtim - 2.0) / 1.2) ** 2) * smooth(0.45, 0.6, tn(R, S, (8, 16, 32), 0.6))
    pl = pl * (1 - 0.45 * gapl[..., None])
    col = np.where(timber[..., None], wood, pl)
    edge = smooth(0.0, 2.0, np.where(timber, dpl, dtim))
    hw = 0.75 + smooth(0.0, 9.0, dpl) * 0.15 - rings * 0.04 + g2r * 0.04 + fibr * 0.05 - chk * 0.2
    hp = 0.45 + mot * 0.05 + gr * 0.015 + fine * 0.02 - gapl * 0.06
    h = np.where(timber, hw, hp)
    h = gblur(h, 0.6)
    img = to_img(col)
    d = ImageDraw.Draw(img)
    for (px, py) in ((0, sb - 12), (512, sb - 12), (0, S - sb + 12), (512, S - sb + 12), (0, ye), (512, ye), (40, ye), (476, ye), (548, ye), (S - 40, ye)):
        for ox, oy in offs(px, py, 10, S):
            d.ellipse((px + ox - 5, py + oy - 5, px + ox + 5, py + oy + 5), fill=(52, 38, 26))
            d.ellipse((px + ox - 3.5, py + oy - 4, px + ox + 2, py + oy + 1), fill=(84, 64, 44))
    col = from_img(img)
    sh = hshadow(h, 12.0, 16, 1.0)
    col = col * (1 - 0.35 * sh[..., None])
    col = bake(col, h, 4.0, k=0.25, ao=0.3, ao_r=4)
    save_surface("colombage_motif", col, h, 5.0)


def bati():
    enduit()
    pierre_rempart()
    moellons()
    tuiles()
    bois_planches()
    chaume()
    colombage_motif()


# =================================================================== le donjon (une tuile ≈ 3 m)

def _rows(R, S, lo, hi):
    rows = []
    while sum(rows) < S:
        rows.append(float(R.uniform(lo, hi)))
    rows = np.array(rows)
    return list(rows * S / rows.sum())


def pierre_donjon():
    """Les murs du Donjon des Mille Marches : vieux moellons équarris gris-brun sombre, assises
    irrégulières, faces rugueuses et bosselées, arêtes cassées ; joints creusés, mortier noirci ;
    suintements d'humidité qui luisent, croûtes blanches de salpêtre, algues noir-vert dans les
    joints, coulures sombres."""
    S = 1024
    R = rng(7301)
    rows = _rows(R, S, 90, 150)
    bid, e, u, v = masonry(R, S, rows, 120, 320, rr=6.0)
    wx = (tn(R, S, (8, 16, 32), 0.6) - 0.5) * 16
    wy = (tn(R, S, (8, 16, 32), 0.6) - 0.5) * 10
    e = warp(e, wx, wy)
    bid = warp_nn(bid, wx, wy)
    v = warp(v, wx, wy)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    rough = tn(R, S, (16, 32, 64, 128, 256), 0.7)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    gr = grain(R, S, 0.6)
    chip = tn(R, S, (16, 32, 64, 128), 0.7)
    e2 = e - 5.0 - np.clip(chip - 0.58, 0, 1) * 60.0 - (rough - 0.5) * 12
    face = smooth(0.0, 20.0, e2) ** 0.5
    tone = per_id(bid, R, 0.8, 1.15)
    hue = per_id(bid, R, 0, 1)
    stone = mix(C(0.27, 0.26, 0.245), C(0.31, 0.28, 0.24), hue) * tone[..., None]
    stone = stone * (0.8 + 0.4 * rough[..., None]) * (0.88 + 0.22 * fine[..., None]) * (0.92 + 0.14 * gr[..., None])
    stone = stone * (0.8 + 0.2 * face[..., None])
    wet = smooth(0.5, 0.75, tn(R, S, (4, 8, 16, 32), 0.6, oy=(8, 16, 32, 64)))
    seep = smooth(0.55, 0.8, tn(R, S, (16, 32, 64, 128), 0.65, oy=(2, 4, 8, 16))) * wet
    stone = stone * (1 - 0.3 * seep[..., None])
    gx, gy = grads(gblur(rough, 2.0))
    gloss = np.clip(-(gx * -0.45 + gy * -0.6) * 60, 0, 1) * seep
    stone = stone + (gloss * 0.12)[..., None]
    salt = smooth(0.6, 0.8, tn(R, S, (16, 32, 64, 128), 0.6)) * (1 - smooth(4.0, 30.0, e)) * smooth(0.5, 0.7, tn(R, S, (4, 8, 16), 0.6))
    salt = salt * smooth(0.3, 0.6, grain(R, S, 1.2))
    stone = mix(stone, C(0.66, 0.65, 0.61), salt * 0.45)
    jm = 1 - smooth(1.0, 4.0, e)
    mortar = C(0.2, 0.19, 0.17) * (0.7 + 0.5 * grain(R, S, 0.8)[..., None])
    algae = (1 - smooth(2.0, 14.0, e)) * smooth(0.5, 0.7, tn(R, S, (8, 16, 32, 64), 0.6))
    col = mix(stone, mortar, jm)
    col = mix(col, C(0.08, 0.11, 0.06) * (0.7 + 0.6 * gr[..., None]), algae * 0.7)
    tilt = per_id(bid, R, -0.06, 0.06)
    h = face * 0.55 + (u - 0.5) * tilt + rough * 0.2 + fine * 0.05 + gr * 0.02 - jm * 0.2 + salt * 0.03
    h = h - np.clip((e - 5.0 - e2) / 40.0, 0, 0.5) * 0.4
    sh = hshadow(h, 9.0, 14, 1.0)
    col = col * (1 - 0.4 * sh[..., None])
    col = bake(col, h, 6.0, k=0.38, ao=0.45, ao_r=6)
    save_surface("pierre_donjon", col, h, 6.0)


def dalles_donjon():
    """Sol du donjon : dalles sombres de toutes tailles, usées en cuvette, fendues, quelques-unes
    brisées en morceaux ; crasse noire et terre dans les joints, gravats, flaques mates et
    zones humides plus sombres, un peu de salpêtre."""
    S = 1024
    R = rng(7302)
    rows = _rows(R, S, 120, 240)
    bid, e, u, v = masonry(R, S, rows, 130, 300, rr=4.0)
    wx = (tn(R, S, (8, 16, 32), 0.6) - 0.5) * 10
    wy = (tn(R, S, (8, 16, 32), 0.6) - 0.5) * 10
    e = warp(e, wx, wy)
    bid = warp_nn(bid, wx, wy)
    # dalles brisées : on ajoute des fêlures franches (cellules de Voronoï) dans certaines dalles
    _, fe, fid, _, _ = worley(R, S, 14, 0.9)
    fe = warp(fe, (tn(R, S, (16, 32, 64), 0.6) - 0.5) * 20, (tn(R, S, (16, 32, 64), 0.6) - 0.5) * 20)
    broken = per_id(bid, R, 0, 1) < 0.16
    e = np.where(broken, np.minimum(e, fe * 1.6 + 1.6), e)
    bid = np.where(broken & (fe < 40), bid * 100 + fid, bid)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    rough = tn(R, S, (32, 64, 128, 256), 0.7)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    gr = grain(R, S, 0.6)
    chip = tn(R, S, (16, 32, 64, 128), 0.7)
    e2 = e - 2.5 - np.clip(chip - 0.64, 0, 1) * 30
    chipd = np.clip((e - 2.5 - e2) / 14.0, 0, 1) * smooth(1.0, 4.0, e)
    e2 = np.maximum(e2, e - 2.5 - np.clip(chip - 0.64, 0, 1) * 3.0)
    face = smooth(0.0, 6.0, e2) ** 0.6
    tone = per_id(bid, R, 0.8, 1.15)
    stone = mix(C(0.3, 0.29, 0.27), C(0.34, 0.31, 0.27), per_id(bid, R, 0, 1)) * tone[..., None]
    stone = stone * (0.84 + 0.3 * mot[..., None]) * (0.86 + 0.26 * rough[..., None]) * (0.92 + 0.14 * gr[..., None])
    wear = smooth(0.1, 0.5, np.minimum(np.minimum(u, 1 - u), np.minimum(v, 1 - v)) * 2)
    stone = mix(stone, stone * 1.12, wear * 0.5)
    damp = smooth(0.5, 0.8, tn(R, S, (2, 4, 8, 16, 32), 0.6))
    stone = stone * (1 - 0.2 * damp[..., None])
    puddle = smooth(0.7, 0.74, tn(R, S, (4, 8, 16, 32), 0.6)) * wear
    stone = mix(stone, C(0.12, 0.12, 0.12), puddle * 0.6)
    salt = smooth(0.66, 0.8, tn(R, S, (16, 32, 64), 0.6)) * (1 - smooth(3.0, 18.0, e)) * (1 - damp)
    stone = mix(stone, C(0.62, 0.61, 0.57), salt * smooth(0.3, 0.6, grain(R, S, 1.2)) * 0.6)
    jm = 1 - smooth(-0.5, 2.0, e2)
    grime = C(0.1, 0.09, 0.08) * (0.7 + 0.6 * grain(R, S, 0.8)[..., None])
    stone = mix(stone, stone * 0.8, chipd * 0.6)
    col = mix(stone * (0.8 + 0.2 * face[..., None]), grime, jm)
    col = col * (1 - 0.25 * (1 - smooth(0.0, 12.0, e))[..., None])
    h = face * 0.5 - chipd * 0.2 - (wear * 0.06) + rough * 0.06 + fine * 0.03 + per_id(bid, R, -0.06, 0.06) - jm * 0.25 - puddle * 0.03
    # gravats
    items = []
    for count, rlo, rhi in ((260, 1.5, 4.0), (40, 4.0, 9.0)):
        for _ in range(count):
            r = R.uniform(rlo, rhi)
            items.append((R.random() * S, R.random() * S, rock_poly(R, r, k=int(R.integers(5, 8)), jit=0.35), r))
    pal = [((0.32, 0.31, 0.29), 0.6), ((0.4, 0.38, 0.35), 0.3), ((0.55, 0.53, 0.5), 0.1)]
    scol, sth, mask, prof = stones_layer(R, S, items, pal, fine)
    ma = gblur(mask.astype(np.float32), 0.5)
    col = mix(col, scol, ma)
    h = h + sth * mask * 0.6
    sh = hshadow(h, 6.0, 12, 0.8)
    col = col * (1 - 0.4 * sh[..., None])
    col = bake(col, h, 4.0, k=0.32, ao=0.4, ao_r=4)
    save_surface("dalles_donjon", col, h, 5.0)


def mousse_donjon():
    """Pierre du donjon couverte de mousse : gros moellons sombres presque noyés sous des coussins
    de mousse serrée (vert profond à vert-jaune, pointes plus claires), plus épaisse dans les joints
    et vers le bas des pierres ; filaments, petites frondes, gouttes ; la pierre humide affleure."""
    S = 1024
    R = rng(7303)
    rows = _rows(R, S, 110, 170)
    bid, e, u, v = masonry(R, S, rows, 150, 340, rr=8.0)
    wx = (tn(R, S, (8, 16, 32), 0.6) - 0.5) * 18
    wy = (tn(R, S, (8, 16, 32), 0.6) - 0.5) * 12
    e = warp(e, wx, wy)
    bid = warp_nn(bid, wx, wy)
    v = warp(v, wx, wy)
    rough = tn(R, S, (16, 32, 64, 128, 256), 0.7)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    gr = grain(R, S, 0.6)
    face = smooth(0.0, 24.0, e - 4.0) ** 0.5
    stone = mix(C(0.24, 0.235, 0.22), C(0.29, 0.27, 0.23), per_id(bid, R, 0, 1)) * per_id(bid, R, 0.8, 1.15)[..., None]
    stone = stone * (0.8 + 0.4 * rough[..., None]) * (0.9 + 0.2 * fine[..., None]) * (0.8 + 0.2 * face[..., None])
    hs = face * 0.5 + rough * 0.15 + fine * 0.04
    # coussins de mousse
    cover = tn(R, S, (4, 8, 16, 32, 64), 0.6) + (1 - smooth(0.0, 40.0, e)) * 0.35 + (v - 0.5) * 0.25
    mask = smooth(0.48, 0.56, cover)
    _, ce, cid, cdx, cdy = worley(R, S, 34, 0.95)
    cush = np.clip(1 - np.hypot(cdx, cdy) / (S / 34 * 0.9), 0, 1) ** 0.8
    _, ce2, cid2, cdx2, cdy2 = worley(R, S, 260, 0.95)
    cush2 = np.clip(1 - np.hypot(cdx2, cdy2) / (S / 260 * 0.9), 0, 1) ** 0.6
    fib = grain(R, S, 0.55)
    fib2 = grain(R, S, 1.0)
    thick = smooth(0.48, 0.75, cover)
    hm = hs * (1 - mask) + mask * (hs * 0.3 + 0.35 + thick * 0.3 + cush * 0.1 + cush2 * 0.05 + fib * 0.08)
    tint = per_id(cid, R, 0, 1)
    mcol = mix(C(0.08, 0.13, 0.04), C(0.2, 0.3, 0.07), np.clip(tint * 0.6 + cush * 0.4, 0, 1))
    mcol = mix(mcol, C(0.34, 0.42, 0.12), smooth(0.7, 0.98, fib) * 0.5)
    mcol = mcol * (0.6 + 0.6 * fib[..., None]) * (0.85 + 0.25 * fib2[..., None]) * (0.8 + 0.25 * cush[..., None]) * (0.9 + 0.15 * cush2[..., None])
    mcol = mix(mcol, C(0.2, 0.24, 0.1), smooth(0.6, 0.8, tn(R, S, (8, 16, 32), 0.6)) * 0.4)
    col = mix(stone, mcol, mask)
    edge = np.exp(-((cover - 0.5) / 0.02) ** 2)
    col = col * (1 - 0.3 * edge[..., None])
    img = to_img(col)
    d = ImageDraw.Draw(img)
    hmi = Image.fromarray((np.clip(hm, 0, 1) * 255).astype(np.uint8), "L")
    dh = ImageDraw.Draw(hmi)
    ys, xs = np.nonzero(mask > 0.8)
    pick = R.choice(len(xs), 1800, replace=False)
    for i in pick:  # petites frondes et sporophytes
        x, y = float(xs[i]), float(ys[i])
        a = R.uniform(0, TAU)
        L = R.uniform(4, 11)
        c = tuple(int(v_ * R.uniform(0.7, 1.15)) for v_ in (76, 100, 32))
        for ox, oy in offs(x, y, L + 2, S):
            d.line([(x + ox, y + oy), (x + ox + math.cos(a) * L, y + oy + math.sin(a) * L)], fill=c, width=1)
            if R.random() < 0.15:
                d.ellipse((x + ox + math.cos(a) * L - 1.2, y + oy + math.sin(a) * L - 1.2, x + ox + math.cos(a) * L + 1.2, y + oy + math.sin(a) * L + 1.2), fill=(150, 110, 50))
            dh.line([(x + ox, y + oy), (x + ox + math.cos(a) * L, y + oy + math.sin(a) * L)], fill=230, width=1)
    col = from_img(img)
    h = np.asarray(hmi, np.float32) / 255.0
    sh = hshadow(h, 10.0, 14, 1.0)
    col = col * (1 - 0.4 * sh[..., None])
    col = bake(col, h, 5.0, k=0.3, ao=0.45, ao_r=5)
    save_surface("mousse_donjon", col, h, 5.0)


def gelee():
    """La gelée verte des slimes (une tuile ≈ 1 m) : masse translucide vert vif, plus sombre en
    profondeur, plus claire et jaune là où elle est mince ; volutes, bulles prises dedans (cerne
    clair, reflet), quelques grosses bulles en surface, reflets humides."""
    S = 1024
    R = rng(7304)
    big = tn(R, S, (2, 4, 8, 16), 0.6)
    sw1 = tn(R, S, (4, 8, 16, 32), 0.6)
    sw2 = tn(R, S, (4, 8, 16, 32), 0.6)
    swirl = warp(tn(R, S, (4, 8, 16, 32, 64), 0.6), (sw1 - 0.5) * 120, (sw2 - 0.5) * 120)
    band = np.abs(np.sin(swirl * 18.0))
    h = gblur(big * 0.6 + swirl * 0.25, 2.0)
    thin = smooth(0.35, 0.75, h)
    deep = C(0.05, 0.24, 0.05)
    mid = C(0.2, 0.62, 0.12)
    lite = C(0.62, 0.9, 0.3)
    col = mix(deep, mid, smooth(0.15, 0.6, h))
    col = mix(col, lite, thin * 0.6)
    col = col * (0.9 + 0.12 * (1 - band)[..., None])
    col = mix(col, C(0.75, 0.95, 0.45), smooth(0.92, 1.0, 1 - band) * thin * 0.25)
    # bulles prises dans la gelée et bulles en surface
    img = to_img(col)
    lay = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    hm = Image.new("L", (S, S), 0)
    dh = ImageDraw.Draw(hm)
    for k in range(520):
        x, y = R.random(2) * S
        r = R.uniform(2, 9) if k > 40 else R.uniform(12, 30)
        surf = k <= 40
        for ox, oy in offs(x, y, r + 3, S):
            X, Y = x + ox, y + oy
            if surf:
                d.ellipse((X - r, Y - r, X + r, Y + r), fill=(140, 230, 90, 80), outline=(30, 90, 20, 160), width=2)
                dh.ellipse((X - r, Y - r, X + r, Y + r), fill=255)
            else:
                d.ellipse((X - r, Y - r, X + r, Y + r), fill=(30, 110, 25, 70), outline=(190, 250, 140, 150), width=max(1, int(r / 4)))
            d.ellipse((X - r * 0.55, Y - r * 0.6, X - r * 0.15, Y - r * 0.25), fill=(240, 255, 230, 200))
    base = img.convert("RGBA")
    base.alpha_composite(lay)
    col = from_img(base.convert("RGB"))
    hb = gblur(np.asarray(hm, np.float32) / 255.0, 3.0)
    h = h + hb * 0.25
    gx, gy = grads(gblur(h, 3.0))
    spec = np.clip(-(gx * -0.45 + gy * -0.6) * 900, 0, 1) ** 3
    col = col + (spec * 0.45)[..., None] * C(0.9, 1.0, 0.85)
    col = bake(col, h, 25.0, k=0.25, ao=0.3, ao_r=8)
    save_surface("gelee", col, h, 25.0)


def donjon():
    pierre_donjon()
    dalles_donjon()
    mousse_donjon()
    gelee()


# =================================================================== panneaux : fenêtres, vitrail, bannière, blason, tableau

def htext(pa, xy, s, size, col, anchor="mm", alpha=1.0, rot=0.0):
    """Texte écrit à la main (TeX Gyre Chorus), encre un peu irrégulière."""
    f = hand_font(size * pa.K)
    m = Image.new("L", (pa.w, pa.h), 0)
    ImageDraw.Draw(m).text((xy[0] * pa.K, xy[1] * pa.K), s, font=f, fill=255, anchor=anchor)
    if rot:
        m = m.rotate(rot, center=(xy[0] * pa.K, xy[1] * pa.K), resample=Image.BICUBIC)
    pa.comp(m, col, alpha, tex=True)


def htext_size(pa, s, size):
    f = hand_font(size * pa.K)
    b = ImageDraw.Draw(Image.new("L", (8, 8))).textbbox((0, 0), s, font=f)
    return (b[2] - b[0]) / pa.K, (b[3] - b[1]) / pa.K


def oak_fill(R, pa, base=(0.33, 0.23, 0.15), vertical=False):
    """Un champ de chêne (non raccordable) de la taille de la peinture, pour remplir des pièces de bois."""
    H, W = pa.h, pa.w
    big = max(W, H)
    if vertical:
        g = tn(R, big, (16, 32, 64, 128), 0.65, oy=(1, 2, 4, 8))[:H, :W]
        f = tn(R, big, (64, 128, 256, 512), 0.7, oy=(2, 4, 8, 16))[:H, :W]
        xx = np.mgrid[0:H, 0:W][1].astype(np.float32)
        rings = 1 - smooth(0.0, 0.3, np.abs(np.sin((xx / pa.K + (g - 0.5) * 50) * 0.35)))
    else:
        g = tn(R, big, (1, 2, 4, 8), 0.65, oy=(16, 32, 64, 128))[:H, :W]
        f = tn(R, big, (2, 4, 8, 16), 0.7, oy=(64, 128, 256, 512))[:H, :W]
        yy = np.mgrid[0:H, 0:W][0].astype(np.float32)
        rings = 1 - smooth(0.0, 0.3, np.abs(np.sin((yy / pa.K + (g - 0.5) * 50) * 0.35)))
    w = np.array(base, np.float32) * (0.75 + 0.5 * f[..., None]) * (1 - 0.22 * rings[..., None])
    return w.astype(np.float32)


def paint_field(pa, mask_img, field, shade=0.5, depth=3.0):
    """Peint un champ RVB (0..1, taille de la peinture) dans un masque, avec un modelé."""
    m = np.asarray(mask_img, np.float32) / 255.0
    if shade:
        hb = np.asarray(mask_img.filter(ImageFilter.GaussianBlur(depth * pa.K)), np.float32) / 255.0
        gy, gx = np.gradient(hb)
        st = 2.2 * depth * pa.K
        nx, ny = -gx * st, -gy * st
        inv = 1.0 / np.sqrt(nx * nx + ny * ny + 1.0)
        ndl = (nx * pa.L[0] + ny * pa.L[1] + pa.L[2]) * inv
        fsh = np.clip(1.0 + shade * (ndl - pa.L[2]) / pa.L[2], 0.3, 1.7)
        field = field * fsh[..., None]
    pa.rgb = pa.rgb * (1 - m[..., None]) + field * m[..., None]
    pa.cov = np.maximum(pa.cov, m)


def _window(night):
    """Croisée de chêne à petits bois de plomb (256 x 512) : dormant, meneau, traverse, quatre jours ;
    de jour, verres vert-gris qui reflètent le ciel ; de nuit, éclairés de l'intérieur."""
    W, H = 256, 512
    R = rng(7401)
    pa = Paint(W, H, 2, bg=(40, 30, 22), seed=7401)
    ow = oak_fill(R, pa, (0.36, 0.26, 0.17) if not night else (0.3, 0.21, 0.14))
    ovw = oak_fill(rng(7402), pa, (0.36, 0.26, 0.17) if not night else (0.3, 0.21, 0.14), vertical=True)
    pa.rgb = ow.copy()
    fx0, fy0, fx1, fy1 = 14, 14, W - 14, H - 26
    mx = W / 2
    ty = 186
    lights = [(fx0 + 14, fy0 + 14, mx - 8, ty - 8), (mx + 8, fy0 + 14, fx1 - 14, ty - 8),
              (fx0 + 14, ty + 8, mx - 8, fy1 - 14), (mx + 8, ty + 8, fx1 - 14, fy1 - 14)]
    glass = Image.new("L", (pa.w, pa.h), 0)
    dg = ImageDraw.Draw(glass)
    for (a, b, c, d_) in lights:
        dg.rectangle((a * pa.K, b * pa.K, c * pa.K, d_ * pa.K), fill=255)
    if night:
        base = (255, 186, 92)
        _glass_cells(pa, glass, 34, 58, R, base, var=0.3, lead=1.1, glow_c=(W / 2, H * 0.62), glow_r=170, hue=0.05)
    else:
        _glass_cells(pa, glass, 34, 58, R, (142, 160, 156), var=0.3, lead=1.1, hue=0.04)
        yy, xx = np.mgrid[0:pa.h, 0:pa.w].astype(np.float32) / pa.K
        gm = np.asarray(glass, np.float32) / 255.0
        sky = np.clip(1.25 - yy / H * 0.9, 0.5, 1.3)
        sheen = np.exp(-(((xx - yy * 0.55 - 40) / 26.0) ** 2)) * 0.35 + np.exp(-(((xx - yy * 0.55 + 70) / 12.0) ** 2)) * 0.2
        wob = tn(R, max(pa.w, pa.h), (8, 16, 32, 64), 0.6)[:pa.h, :pa.w]
        lead_m = (pa.rgb.mean(-1) < 0.12)
        f = (sky * (0.85 + 0.3 * wob) + sheen)[..., None] * C(0.98, 1.02, 1.04)
        pa.rgb = np.where((gm > 0.5)[..., None] & ~lead_m[..., None], pa.rgb * f, pa.rgb)
    # bois : dormant, meneau, traverse, ouvrants
    def bar(x0, y0, x1, y1, vertical):
        m = pa._draw(lambda d: d.rectangle((x0 * pa.K, y0 * pa.K, x1 * pa.K, y1 * pa.K), fill=255))
        paint_field(pa, m, ovw if vertical else ow, shade=0.6, depth=2.5)
        pa.outline([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], 1.0, (22, 15, 10), alpha=0.8)
    for (a, b, c, d_) in lights:
        bar(a - 7, b - 7, c + 7, b + 1, False)
        bar(a - 7, d_ - 1, c + 7, d_ + 7, False)
        bar(a - 7, b - 7, a + 1, d_ + 7, True)
        bar(c - 1, b - 7, c + 7, d_ + 7, True)
    bar(fx0, fy0, fx1, fy0 + 8, False)
    bar(fx0, fy1 - 8, fx1, fy1, False)
    bar(fx0, fy0, fx0 + 8, fy1, True)
    bar(fx1 - 8, fy0, fx1, fy1, True)
    bar(mx - 9, fy0, mx + 9, fy1, True)
    bar(fx0, ty - 9, fx1, ty + 9, False)
    # appui de pierre
    pa.rect(0, H - 26, W, H, (150, 144, 132), shade=0.6, depth=3, ol=1.2)
    pa.rect(0, H - 26, W, H - 21, (178, 172, 160), shade=0, ol=0)
    # ferrures : fiches et loqueteaux
    iron = (36, 34, 34)
    for (a, b, c, d_) in lights:
        for yv in (b + 16, d_ - 16):
            xa = a - 4 if a < mx else c + 4
            pa.rect(xa - 3, yv - 9, xa + 3, yv + 9, iron, shade=0.5, depth=1, ol=0.6)
        xl = c - 2 if a < mx else a + 2
        pa.rect(xl - 2, (b + d_) / 2 - 10, xl + 2, (b + d_) / 2 + 10, iron, shade=0.5, depth=1, ol=0.6)
    if night:
        pa.glow(W / 2, H * 0.6, 150, (90, 50, 12), 0.25)
    rgb, _ = pa.result()
    return rgb


def fenetre_plomb():
    save_rgb(_window(False), "fenetre_plomb.png")


def fenetre_plomb_nuit():
    save_rgb(_window(True), "fenetre_plomb_nuit.png")


def _stone_wall(pa, R, base=(0.66, 0.63, 0.56), course=58, joint=(0.5, 0.47, 0.42)):
    big = max(pa.w, pa.h)
    n = tn(R, big, (4, 8, 16, 32, 64), 0.6)[:pa.h, :pa.w]
    f = tn(R, big, (64, 128, 256, 512), 0.75)[:pa.h, :pa.w]
    g = grain(R, big, 0.6)[:pa.h, :pa.w]
    pa.rgb = (np.array(base, np.float32) * (0.86 + 0.28 * n[..., None]) * (0.9 + 0.2 * f[..., None]) * (0.93 + 0.14 * g[..., None])).astype(np.float32)
    W, H = pa.W, pa.H
    y = -R.uniform(0, course)
    k = 0
    while y < H:
        pa.line([(0, y), (W, y)], tuple(int(c * 255) for c in joint), 2.0)
        x = -R.uniform(0, 80) if k % 2 else -R.uniform(80, 160)
        while x < W:
            pa.line([(x, y), (x, y + course)], tuple(int(c * 255) for c in joint), 2.0)
            x += R.uniform(110, 190)
        y += course
        k += 1


def vitrail_aube():
    """La verrière du Temple de l'Aube (512 x 1024) : lancette en arc brisé dans un mur de calcaire
    clair ; au pied, des collines vertes ; le soleil d'or se lève derrière elles, cerclé d'orange
    et de rose ; ses rayons, verres alternés or pâle et bleus, montent jusqu'à la pointe de l'arc ;
    bordure de perles d'or et de rouge ; dans la tête de l'arc, une étoile du matin ; plombs,
    barlotières, ébrasement mouluré."""
    W, H = 512, 1024
    R = rng(7403)
    pa = Paint(W, H, 2, seed=7403)
    _stone_wall(pa, R)
    x0, x1, ys, yb = 76, 436, 380, 968
    ink = (16, 14, 14)
    pa.poly(arch_pts(x0 - 44, x1 + 44, ys, yb + 30), (176, 168, 152), shade=0.7, depth=8, ol=1.4)
    pa.poly(arch_pts(x0 - 26, x1 + 26, ys, yb + 18), (150, 142, 128), shade=0.6, depth=5, ol=1.2)
    pa.poly(arch_pts(x0 - 12, x1 + 12, ys, yb + 8), (110, 104, 96), shade=0.5, depth=3, ol=1.2)
    arch = arch_pts(x0, x1, ys, yb, n=80)
    gm = pa._draw(lambda d: d.polygon(pa.P(arch), fill=255))
    m = np.asarray(gm, np.float32) / 255.0
    save_rgb_bg = pa.rgb.copy()
    cx, cy = W / 2, 790
    # rayons : secteurs découpés en anneaux
    nray = 22
    a_start, a_end = math.pi * 1.0, math.pi * 2.0
    for k in range(nray):
        a0 = a_start + (a_end - a_start) * k / nray
        a1 = a_start + (a_end - a_start) * (k + 1) / nray
        radii = [96, 170, 260, 360, 470, 620, 800]
        for j in range(len(radii) - 1):
            r0, r1 = radii[j], radii[j + 1]
            if k % 2 == 0:
                cols = [(250, 214, 96), (246, 196, 80), (236, 206, 130), (226, 214, 170), (200, 210, 214), (176, 196, 222)]
            else:
                cols = [(236, 120, 60), (214, 96, 96), (150, 80, 140), (70, 70, 160), (46, 60, 150), (34, 44, 124)]
            c = tuple(int(np.clip(v * R.uniform(0.86, 1.1), 0, 255)) for v in cols[j])
            pts = [(cx + math.cos(a0 + (a1 - a0) * t) * r0, cy + math.sin(a0 + (a1 - a0) * t) * r0) for t in np.linspace(0, 1, 6)]
            pts += [(cx + math.cos(a1 - (a1 - a0) * t) * r1, cy + math.sin(a1 - (a1 - a0) * t) * r1) for t in np.linspace(0, 1, 6)]
            pa.poly(pts, c, shade=0, ol=2.2, inkc=ink)
    # le soleil et ses cercles
    pa.ell(cx, cy, 96, 96, (238, 132, 70), shade=0, ol=2.4, inkc=ink)
    pa.ell(cx, cy, 78, 78, (248, 176, 70), shade=0, ol=2.4, inkc=ink)
    pa.ell(cx, cy, 58, 58, (255, 222, 110), shade=0, ol=2.4, inkc=ink)
    for k in range(8):
        a = k / 8 * TAU
        pa.line([(cx + math.cos(a) * 58, cy + math.sin(a) * 58), (cx + math.cos(a) * 78, cy + math.sin(a) * 78)], ink, 2.0)
    pa.glow(cx, cy - 10, 70, (255, 230, 150), 0.35)
    # nuages
    for (x, y, s) in ((150, 600, 1.0), (360, 560, 0.85), (300, 680, 0.7)):
        cl = [(x - 60 * s, y + 10 * s), (x - 46 * s, y - 14 * s), (x - 20 * s, y - 22 * s), (x + 6 * s, y - 34 * s), (x + 34 * s, y - 20 * s),
              (x + 58 * s, y - 8 * s), (x + 64 * s, y + 10 * s)]
        pa.poly(cl, (224, 196, 214), sm=2, shade=0, ol=2.2, inkc=ink)
        pa.line([(x - 30 * s, y + 2 * s), (x + 20 * s, y - 6 * s)], ink, 1.8)
    # collines
    hills = [([(x0 - 10, 830), (140, 800), (230, 812), (300, 840), (x1 + 10, 806), (x1 + 10, 1000), (x0 - 10, 1000)], (60, 132, 60)),
             ([(x0 - 10, 870), (120, 858), (200, 852), (290, 870), (380, 846), (x1 + 10, 860), (x1 + 10, 1000), (x0 - 10, 1000)], (40, 104, 48)),
             ([(x0 - 10, 920), (180, 900), (320, 916), (x1 + 10, 900), (x1 + 10, 1000), (x0 - 10, 1000)], (96, 150, 52))]
    for pts, c in hills:
        pa.poly(pts, c, sm=2, shade=0, ol=2.4, inkc=ink)
    for (tx, ty) in ((130, 852), (150, 846), (390, 842)):
        pa.ell(tx, ty - 14, 10, 13, (30, 84, 40), shade=0, ol=1.8, inkc=ink)
        pa.line([(tx, ty - 2), (tx, ty + 8)], ink, 2.2)
    # étoile du matin dans la tête de l'arc
    sx, sy = W / 2, 238
    star = []
    for k in range(16):
        a = -math.pi / 2 + k * TAU / 16
        r = 34 if k % 4 == 0 else (14 if k % 2 == 0 else 9)
        star.append((sx + math.cos(a) * r, sy + math.sin(a) * r))
    pa.ell(sx, sy, 44, 44, (40, 54, 140), shade=0, ol=2.4, inkc=ink)
    pa.poly(star, (252, 236, 170), shade=0, ol=2.0, inkc=ink)
    # bordure de perles
    border = arch_pts(x0, x1, ys, yb, d=9, n=120)
    acc, k = 0.0, 0
    for (ax, ay), (bx, by) in zip(border[:-1], border[1:]):
        seg = math.hypot(bx - ax, by - ay)
        t = 0.0
        while t < seg:
            px, py = ax + (bx - ax) * t / max(seg, 1e-6), ay + (by - ay) * t / max(seg, 1e-6)
            pa.ell(px, py, 6.5, 6.5, (236, 186, 60) if k % 2 == 0 else (176, 36, 30), shade=0, ol=1.8, inkc=ink)
            k += 1
            t += 15.0
    pa.outline(arch_pts(x0, x1, ys, yb, d=18, n=120)[:-1], 2.4, ink, closed=False)
    # lumière qui traverse : verres plus vifs, irréguliers ; barlotières
    big = max(pa.w, pa.h)
    streak = tn(R, big, (16, 32, 64, 128), 0.6, oy=(64, 128, 256, 512))[:pa.h, :pa.w]
    spot = tn(R, big, (32, 64, 128, 256), 0.7)[:pa.h, :pa.w]
    yy, xx = np.mgrid[0:pa.h, 0:pa.w].astype(np.float32) / pa.K
    glow = 0.85 + 0.3 * np.exp(-(((xx - cx) ** 2 + (yy - cy) ** 2) / (360.0 ** 2)))
    glass_rgb = pa.rgb * (glow * (0.86 + 0.24 * streak) * (0.92 + 0.12 * spot))[..., None]
    pa.rgb = save_rgb_bg * (1 - m[..., None]) + glass_rgb * m[..., None]
    for yv in (470, 610, 750, 890):
        pa.line([(x0 - 6, yv), (x1 + 6, yv)], (26, 24, 24), 4.0)
        pa.line([(x0 - 6, yv - 1.4), (x1 + 6, yv - 1.4)], (90, 86, 84), 1.0)
    pa.rect(x0 - 50, yb + 30, x1 + 50, yb + 50, (186, 178, 162), shade=0.6, depth=3, ol=1.2)
    rgb, _ = pa.result()
    save_rgb(rgb, "vitrail_aube.png")


def sun_rays(pa, cx, cy, r0, r1, n, col, ol=1.6, inkc=None, phase=0.0, wav=True):
    for k in range(n):
        a = phase + k / n * TAU
        if a % TAU < math.pi * 0.02 or a % TAU > math.pi * 0.98:
            pass
        w = TAU / n * 0.32
        if wav and k % 2:
            pts = [(cx + math.cos(a - w) * r0, cy + math.sin(a - w) * r0)]
            for t in np.linspace(0, 1, 10)[1:]:
                rr = r0 + (r1 * 0.85 - r0) * t
                off = math.sin(t * math.pi * 2) * w * 0.6
                pts.append((cx + math.cos(a + off) * rr, cy + math.sin(a + off) * rr))
            pts.append((cx + math.cos(a + w) * r0, cy + math.sin(a + w) * r0))
        else:
            pts = [(cx + math.cos(a - w) * r0, cy + math.sin(a - w) * r0), (cx + math.cos(a) * r1, cy + math.sin(a) * r1),
                   (cx + math.cos(a + w) * r0, cy + math.sin(a + w) * r0)]
        pa.poly(pts, col, shade=0.4, depth=2, ol=ol, inkc=inkc)


def banniere_montjoie():
    """La bannière de Montjoie (256 x 512, transparente autour) : drap d'azur, une butte verte
    au pied, un soleil d'or levant derrière elle, rayonnant ; bordure d'or, fourreau et anneaux en
    haut, pointe en queue d'aronde ; « MONTJOIE » brodé ; plis et grain de la laine."""
    W, H = 256, 512
    R = rng(7404)
    pa = Paint(W, H, 2, bg=(30, 50, 120), seed=7404)
    x0, x1, y0, yt, yn = 18, 238, 10, 500, 420
    shape = [(x0, y0), (x1, y0), (x1, yt), (128, yn), (x0, yt)]
    yy, xx = np.mgrid[0:pa.h, 0:pa.w].astype(np.float32) / pa.K
    big = max(pa.w, pa.h)
    weave = 0.93 + 0.07 * (np.sin(xx * 3.1) * np.sin(yy * 3.1) * 0.5 + 0.5)
    blue = np.array((0.12, 0.22, 0.52), np.float32) * weave[..., None] * (0.88 + 0.22 * tn(R, big, (8, 16, 32, 64), 0.6)[:pa.h, :pa.w, None])
    pa.rgb = blue.astype(np.float32)
    gold = (232, 182, 64)
    cx, cy = 128, 292
    sun_rays(pa, cx, cy, 54, 116, 16, gold, ol=1.4, wav=False)
    sun_rays(pa, cx, cy, 54, 92, 16, (246, 210, 110), ol=1.2, phase=TAU / 32, wav=False)
    pa.ell(cx, cy, 50, 50, gold, shade=0.6, depth=4, ol=1.6, grad=((252, 220, 120), (206, 140, 40), 90))
    pa.ell(cx - 16, cy - 16, 12, 9, (255, 240, 190), shade=0, ol=0, alpha=0.3)
    hill = [(x0, 368), (60, 330), (110, 310), (150, 312), (196, 332), (x1, 360), (x1, yt), (128, yn), (x0, yt)]
    pa.poly(hill, (52, 130, 58), sm=2, shade=0.6, depth=8, ol=1.8, grad=((84, 160, 70), (34, 96, 44), 90))
    for k in range(4):
        pa.line(bez((40 + k * 50, 352 - k * 6), (60 + k * 50, 340 - k * 8), (80 + k * 50, 348 - k * 6), 8), (36, 96, 44), 1.4)
    inner = [(x0 + 12, y0 + 30), (x1 - 12, y0 + 30), (x1 - 12, yt - 20), (128, yn - 13), (x0 + 12, yt - 20)]
    m_out = np.asarray(pa._draw(lambda d: d.polygon(pa.P(shape), fill=255)), np.float32) / 255.0
    m_in = np.asarray(pa._draw(lambda d: d.polygon(pa.P(inner), fill=255)), np.float32) / 255.0
    pa.comp(Image.fromarray((np.clip(m_out - m_in, 0, 1) * 255).astype(np.uint8)), (196, 150, 52), shade=0.5, depth=2)
    pa.outline(inner, 1.4, (90, 60, 20), alpha=0.9)
    pa.rect(x0, y0, x1, y0 + 22, (150, 110, 40), shade=0.6, depth=2, ol=1.4)
    for k in range(5):
        x = x0 + 22 + k * 44
        pa.ell(x, y0 + 4, 7, 7, (0, 0, 0), alpha=0, ol=2.2, inkc=(90, 84, 80))
    pa.text((128, 186), "MONTJOIE", 24, (240, 200, 90), stroke=1.4, stroke_col=(30, 22, 10), spacing=1.5, shade=0.4)
    # étoiles semées
    for (sx, sy) in ((56, 80), (200, 80), (128, 64), (60, 150), (196, 150)):
        st = [(sx + math.cos(-math.pi / 2 + k * TAU / 8) * (7 if k % 2 == 0 else 2.6), sy + math.sin(-math.pi / 2 + k * TAU / 8) * (7 if k % 2 == 0 else 2.6)) for k in range(8)]
        pa.poly(st, (236, 196, 90), shade=0, ol=0.8)
    gold_m = (pa.rgb[..., 0] > 0.55) & (pa.rgb[..., 2] < 0.45)
    hatch = 0.9 + 0.1 * np.sin((xx + yy) * 2.4)
    pa.rgb = np.where(gold_m[..., None], pa.rgb * hatch[..., None], pa.rgb)
    folds = 1 + 0.13 * np.sin(xx / 64 * TAU + 0.6) + 0.06 * np.sin(xx / 23 * TAU + 1.3)
    sag = 1 - 0.1 * smooth(200, 500, yy)
    pa.rgb = pa.rgb * (folds * sag)[..., None]
    rgb, _ = pa.result()
    am = Image.new("L", (W * 4, H * 4), 0)
    ImageDraw.Draw(am).polygon([(x * 4, y * 4) for x, y in shape], fill=255)
    alpha = np.asarray(am.resize((W, H), Image.LANCZOS), np.float32) / 255.0
    save_rgba(np.dstack([rgb, alpha]), "banniere_montjoie.png")


def shield_pts(cx, top, w, h, n=24):
    """Écu : haut droit, flancs droits puis courbes jusqu'à la pointe (de gauche à droite par le bas)."""
    ym = top + h * 0.42
    right = bez((cx + w / 2, ym), (cx + w / 2, top + h * 0.78), (cx + w * 0.18, top + h * 0.9), (cx, top + h), n)
    left = [(2 * cx - x, y) for x, y in right[::-1]]
    return [(cx - w / 2, top), (cx + w / 2, top)] + right + left[1:]


def sword_quill(pa, cx, cy, s, ink=(26, 20, 16)):
    """Épée et plume passées en sautoir."""
    # plume (de haut-gauche à bas-droite)
    a = math.radians(52)
    ca, sa = math.cos(a), math.sin(a)
    qx, qy = cx - ca * 0.62 * s, cy - sa * 0.62 * s
    vane = []
    for t in np.linspace(0, 1, 18):
        w = 0.17 * s * math.sin(math.pi * min(1, t * 1.2)) ** 0.7
        vane.append((qx + ca * t * 1.05 * s - sa * w, qy + sa * t * 1.05 * s + ca * w))
    for t in np.linspace(1, 0, 18):
        w = 0.12 * s * math.sin(math.pi * min(1, t * 1.2)) ** 0.7
        vane.append((qx + ca * t * 1.05 * s + sa * w, qy + sa * t * 1.05 * s - ca * w))
    pa.poly(vane, (240, 236, 222), shade=0.5, depth=3, ol=1.6, inkc=ink)
    for k in range(1, 9):
        t = k / 10
        bx, by = qx + ca * t * 1.05 * s, qy + sa * t * 1.05 * s
        pa.line([(bx, by), (bx + (ca * -0.25 - sa) * 0.12 * s, by + (sa * -0.25 + ca) * 0.12 * s)], (170, 164, 150), 1.0)
    pa.line([(qx - ca * 0.05 * s, qy - sa * 0.05 * s), (qx + ca * 1.3 * s, qy + sa * 1.3 * s)], (120, 100, 70), 2.0)
    # épée (de haut-droite à bas-gauche)
    a = math.radians(128)
    ca, sa = math.cos(a), math.sin(a)
    nx, ny = -sa, ca
    tipx, tipy = cx - ca * 0.72 * s, cy - sa * 0.72 * s
    gx, gy = cx + ca * 0.42 * s, cy + sa * 0.42 * s
    bw = 0.075 * s
    blade = [(gx + nx * bw, gy + ny * bw), (tipx + ca * 0.16 * s + nx * bw * 0.8, tipy + sa * 0.16 * s + ny * bw * 0.8), (tipx, tipy),
             (tipx + ca * 0.16 * s - nx * bw * 0.8, tipy + sa * 0.16 * s - ny * bw * 0.8), (gx - nx * bw, gy - ny * bw)]
    pa.poly(blade, (214, 218, 226), shade=0.8, depth=2.5, ol=1.6, inkc=ink, grad=((240, 244, 250), (150, 156, 170), 0))
    pa.line([(gx, gy), (tipx + ca * 0.2 * s, tipy + sa * 0.2 * s)], (130, 136, 150), 1.2)
    pa.tubep([(gx - nx * 0.24 * s, gy - ny * 0.24 * s), (gx + nx * 0.24 * s, gy + ny * 0.24 * s)], 0.07 * s, (214, 166, 60), shade=0.7, depth=2, ol=1.4, inkc=ink)
    hx, hy = gx + ca * 0.22 * s, gy + sa * 0.22 * s
    pa.tubep([(gx, gy), (hx, hy)], 0.07 * s, (110, 60, 34), shade=0.6, depth=2, ol=1.4, inkc=ink)
    pa.ell(hx + ca * 0.04 * s, hy + sa * 0.04 * s, 0.06 * s, 0.06 * s, (220, 170, 64), shade=0.8, depth=2, ol=1.4, inkc=ink)


def blason_guilde():
    """L'emblème de la Guilde des Aventuriers (512 x 512, transparent autour) : écu vert profond
    bordé d'or, une épée d'argent et une plume blanche passées en sautoir, une étoile d'or en chef ;
    banderole de parchemin « Guilde des Aventuriers » ; peint, un peu usé."""
    S = 512
    R = rng(7405)
    pa = Paint(S, S, 2, bg=(0, 0, 0), seed=7405)
    cx = S / 2
    outer = shield_pts(cx, 40, 360, 400)
    inner = shield_pts(cx, 58, 324, 364)
    pa.poly(outer, (206, 160, 60), shade=0.8, depth=8, ol=2.4, grad=((240, 200, 110), (170, 116, 36), 70))
    pa.poly(inner, (30, 92, 62), shade=0.5, depth=12, ol=1.8, grad=((44, 120, 80), (20, 64, 44), 90))
    st = [(cx + math.cos(-math.pi / 2 + k * TAU / 10) * (26 if k % 2 == 0 else 11), 112 + math.sin(-math.pi / 2 + k * TAU / 10) * (26 if k % 2 == 0 else 11)) for k in range(10)]
    pa.poly(st, (240, 200, 90), shade=0.6, depth=3, ol=1.6)
    sword_quill(pa, cx, 258, 200)
    # banderole
    by = 418
    rib = [(60, by - 26), (452, by - 26), (470, by + 2), (452, by + 30), (60, by + 30), (42, by + 2)]
    for sx in (-1, 1):
        ex = cx + sx * 176
        tail = [(ex, by - 14), (ex + sx * 64, by - 14), (ex + sx * 48, by + 8), (ex + sx * 64, by + 32), (ex, by + 32)]
        pa.poly(tail, (196, 176, 136), shade=0.6, depth=3, ol=1.8)
    pa.poly([(70, by - 26), (442, by - 26), (442, by + 30), (70, by + 30)], (236, 222, 186), shade=0.6, depth=4, ol=2.0,
            grad=((246, 236, 206), (210, 192, 150), 90))
    pa.text((cx, by + 3), "Guilde des Aventuriers", 31, (110, 30, 24), bold=True, shade=0.2)
    rgb, cov = pa.result()
    rr = rng(7406)
    wear = tn(rr, S, (8, 16, 32, 64), 0.6)
    rgb = rgb * (0.92 + 0.12 * wear[..., None])
    am = Image.new("L", (S * 4, S * 4), 0)
    da = ImageDraw.Draw(am)
    da.polygon([(x * 4, y * 4) for x, y in outer], fill=255)
    for sx in (-1, 1):
        ex = cx + sx * 176
        da.polygon([(x * 4, y * 4) for x, y in [(ex, by - 14), (ex + sx * 64, by - 14), (ex + sx * 48, by + 8), (ex + sx * 64, by + 32), (ex, by + 32)]], fill=255)
    da.polygon([(x * 4, y * 4) for x, y in [(70, by - 26), (442, by - 26), (442, by + 30), (70, by + 30)]], fill=255)
    alpha = np.asarray(am.filter(ImageFilter.MaxFilter(5)).resize((S, S), Image.LANCZOS), np.float32) / 255.0
    save_rgba(np.dstack([rgb, alpha]), "blason_guilde.png")


def tableau_liege():
    """Le tableau des quêtes (1024 x 768) : grand panneau de liège dans un cadre de chêne chevillé ;
    liège granuleux (grains fauves, bruns et noirs, pores), mille trous de punaises, traces plus
    claires d'anciennes affiches, quelques coins de papier déchirés restés sous leur clou, deux
    punaises de laiton ; plaque peinte « Tableau des Quêtes » sur le cadre du haut."""
    W, H = 1024, 768
    R = rng(7407)
    pa = Paint(W, H, 2, seed=7407)
    big = max(pa.w, pa.h)
    g1 = grain(R, big, 0.9)[:pa.h, :pa.w]
    g2 = grain(R, big, 2.0)[:pa.h, :pa.w]
    n = tn(R, big, (4, 8, 16, 32, 64), 0.6)[:pa.h, :pa.w]
    cork = mix(C(0.55, 0.39, 0.24), C(0.68, 0.52, 0.34), g1) * (0.85 + 0.25 * g2[..., None]) * (0.88 + 0.2 * n[..., None])
    sp = R.random((pa.h, pa.w)).astype(np.float32)
    sp = gblur(sp, 1.2)
    sp = (sp - sp.mean()) / sp.std()
    cork = mix(cork, C(0.26, 0.17, 0.1), smooth(1.6, 2.6, sp) * 0.8)
    cork = mix(cork, C(0.78, 0.64, 0.44), smooth(2.0, 3.0, -sp) * 0.5)
    pa.rgb = cork.astype(np.float32)
    yy, xx = np.mgrid[0:pa.h, 0:pa.w].astype(np.float32) / pa.K
    # anciennes affiches : rectangles plus clairs, trous de punaises
    for _ in range(9):
        w_, h_ = R.uniform(150, 230), R.uniform(200, 290)
        x, y = R.uniform(70, W - 70 - w_), R.uniform(80, H - 70 - h_)
        a = smooth(0.0, 6.0, np.minimum(np.minimum(xx - x, x + w_ - xx), np.minimum(yy - y, y + h_ - yy)))
        pa.rgb = pa.rgb * (1 + 0.1 * a[..., None])
    for _ in range(260):
        x, y = R.uniform(70, W - 70), R.uniform(80, H - 60)
        pa.ell(x, y, 1.3, 1.3, (30, 20, 12), shade=0, ol=0, alpha=0.8, tex=False)
    # restes de papier sous des clous
    for _ in range(6):
        x, y = R.uniform(90, W - 90), R.uniform(100, H - 90)
        pts = [(x + R.uniform(-30, -8), y + R.uniform(-14, -4)), (x + R.uniform(8, 34), y + R.uniform(-16, -4)),
               (x + R.uniform(10, 28), y + R.uniform(8, 30)), (x + R.uniform(-4, 6), y + R.uniform(2, 14)), (x + R.uniform(-26, -10), y + R.uniform(10, 26))]
        pa.poly(pts, (226, 212, 176), shade=0.3, depth=2, ol=0.8, inkc=(120, 100, 70))
        pa.ell(x, y, 4.0, 4.0, (60, 56, 54), shade=0.8, depth=1.5, ol=0.8)
    for (x, y) in ((R.uniform(300, 700), R.uniform(300, 500)), (R.uniform(120, 300), R.uniform(500, 650))):
        pa.ell(x + 3, y + 4, 9, 9, (0, 0, 0), shade=0, ol=0, alpha=0.35, tex=False)
        pa.ell(x, y, 9, 9, (206, 162, 64), shade=0.9, depth=3, ol=1.2)
        pa.ell(x - 3, y - 3, 3, 3, (255, 236, 170), shade=0, ol=0, alpha=0.7)
    # cadre de chêne
    ow = oak_fill(R, pa, (0.4, 0.28, 0.17))
    ovw = oak_fill(rng(7408), pa, (0.4, 0.28, 0.17), vertical=True)
    fw = 46
    for (x0, y0, x1, y1, vert) in ((0, 0, W, fw + 16, False), (0, H - fw, W, H, False), (0, 0, fw, H, True), (W - fw, 0, W, H, True)):
        m = pa._draw(lambda d, a=(x0, y0, x1, y1): d.rectangle(tuple(v * pa.K for v in a), fill=255))
        paint_field(pa, m, ovw if vert else ow, shade=0.7, depth=4)
        pa.outline([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], 1.4, (24, 16, 10), alpha=0.8)
    pa.outline([(fw, fw + 16), (W - fw, fw + 16), (W - fw, H - fw), (fw, H - fw)], 3.0, (20, 14, 10), alpha=0.9)
    for (x, y) in ((fw / 2, fw / 2 + 8), (W - fw / 2, fw / 2 + 8), (fw / 2, H - fw / 2), (W - fw / 2, H - fw / 2)):
        pa.ell(x, y, 6, 6, (70, 48, 30), shade=0.8, depth=2, ol=1.2)
    # plaque
    px0, px1, py0, py1 = W / 2 - 190, W / 2 + 190, 6, 58
    pa.rect(px0, py0, px1, py1, (120, 32, 26), shade=0.6, depth=4, ol=2.0, grad=((150, 44, 34), (96, 24, 20), 90))
    pa.outline([(px0 + 6, py0 + 6), (px1 - 6, py0 + 6), (px1 - 6, py1 - 6), (px0 + 6, py1 - 6)], 1.2, (226, 182, 90), alpha=0.9)
    pa.text((W / 2, (py0 + py1) / 2 + 1), "Tableau des Quêtes", 32, (244, 206, 112), stroke=1.2, stroke_col=(40, 12, 8), shade=0.5,
            shadow=(1.5, 2.0, 0.5))
    rgb, _ = pa.result()
    vig = 1 - 0.18 * ((np.abs(np.mgrid[0:H, 0:W][1] / W - 0.5) * 2) ** 4 + (np.abs(np.mgrid[0:H, 0:W][0] / H - 0.5) * 2) ** 4)
    rgb = rgb * vig[..., None]
    save_rgb(rgb, "tableau_liege.png")


def panneaux():
    fenetre_plomb()
    fenetre_plomb_nuit()
    vitrail_aube()
    banniere_montjoie()
    blason_guilde()
    tableau_liege()


# =================================================================== enseignes (512 x 256)

def em_guilde(pa, cx, cy, s):
    pa.poly(shield_pts(cx, cy - 0.78 * s, 1.3 * s, 1.6 * s), (206, 160, 60), shade=0.7, depth=4, ol=1.8)
    pa.poly(shield_pts(cx, cy - 0.7 * s, 1.14 * s, 1.44 * s), (30, 92, 62), shade=0.5, depth=6, ol=1.2)
    sword_quill(pa, cx, cy + 0.02 * s, 0.62 * s)


def em_grenouille(pa, cx, cy, s):
    """Une grenouille ronde et repue, serviette au cou, cuillère en bois à la main."""
    green, dark, belly = (96, 150, 60), (60, 104, 40), (214, 210, 150)
    for sx in (-1, 1):
        pa.poly([(cx + sx * 0.3 * s, cy + 0.5 * s), (cx + sx * 0.78 * s, cy + 0.42 * s), (cx + sx * 0.9 * s, cy + 0.66 * s),
                 (cx + sx * 0.5 * s, cy + 0.7 * s)], dark, sm=2, shade=0.6, depth=3, ol=1.6)
    pa.ell(cx, cy + 0.18 * s, 0.68 * s, 0.56 * s, green, shade=0.8, depth=s * 0.12, ol=1.8)
    pa.ell(cx, cy + 0.3 * s, 0.44 * s, 0.38 * s, belly, shade=0.6, depth=s * 0.08, ol=1.2)
    pa.ell(cx, cy - 0.36 * s, 0.56 * s, 0.34 * s, green, shade=0.8, depth=s * 0.1, ol=1.8)
    for sx in (-1, 1):
        ex = cx + sx * 0.3 * s
        pa.ell(ex, cy - 0.62 * s, 0.17 * s, 0.17 * s, green, shade=0.8, depth=3, ol=1.6)
        pa.ell(ex, cy - 0.63 * s, 0.11 * s, 0.11 * s, (250, 244, 214), shade=0.4, depth=2, ol=1.0)
        pa.poly(ellp(ex, cy - 0.6 * s, 0.07 * s, 0.03 * s, 180, 360, 12), (30, 24, 20), shade=0, ol=0)
    pa.line(bez((cx - 0.3 * s, cy - 0.3 * s), (cx, cy - 0.18 * s), (cx + 0.3 * s, cy - 0.3 * s), 12), (40, 30, 24), 2.0)
    pa.ell(cx - 0.36 * s, cy - 0.3 * s, 0.07 * s, 0.045 * s, (226, 130, 120), shade=0, ol=0, alpha=0.7)
    pa.ell(cx + 0.36 * s, cy - 0.3 * s, 0.07 * s, 0.045 * s, (226, 130, 120), shade=0, ol=0, alpha=0.7)
    pa.poly([(cx - 0.3 * s, cy - 0.06 * s), (cx + 0.3 * s, cy - 0.06 * s), (cx + 0.06 * s, cy + 0.36 * s), (cx - 0.06 * s, cy + 0.36 * s)],
            (240, 240, 236), shade=0.5, depth=2, ol=1.4)
    for k in range(3):
        pa.line([(cx - 0.18 * s + k * 0.12 * s, cy - 0.04 * s), (cx - 0.1 * s + k * 0.06 * s, cy + 0.2 * s)], (190, 60, 50), 1.6)
    pa.tubep([(cx + 0.55 * s, cy + 0.32 * s), (cx + 0.82 * s, cy - 0.32 * s)], 0.06 * s, (170, 120, 70), shade=0.6, depth=2, ol=1.2)
    pa.ell(cx + 0.84 * s, cy - 0.4 * s, 0.09 * s, 0.13 * s, (176, 124, 72), shade=0.6, depth=2, ol=1.2)
    pa.ell(cx + 0.56 * s, cy + 0.34 * s, 0.12 * s, 0.1 * s, green, shade=0.7, depth=2, ol=1.4)


def em_boule(pa, cx, cy, s):
    """Boule de cristal sur son pied, étoiles et lune dedans, scintillements autour."""
    pa.poly([(cx - 0.5 * s, cy + 0.72 * s), (cx + 0.5 * s, cy + 0.72 * s), (cx + 0.36 * s, cy + 0.42 * s), (cx - 0.36 * s, cy + 0.42 * s)],
            (180, 130, 60), shade=0.7, depth=3, ol=1.6)
    pa.ell(cx, cy - 0.08 * s, 0.56 * s, 0.56 * s, (90, 70, 170), shade=0.7, depth=s * 0.14, ol=1.8, grad=((170, 150, 240), (50, 30, 120), 60))
    for (dx, dy, r) in ((-0.18, -0.2, 0.06), (0.16, 0.1, 0.045), (0.05, -0.34, 0.035), (-0.05, 0.22, 0.03)):
        st = [(cx + dx * s + math.cos(-math.pi / 2 + k * TAU / 8) * (r if k % 2 == 0 else r * 0.35) * s,
               cy + dy * s + math.sin(-math.pi / 2 + k * TAU / 8) * (r if k % 2 == 0 else r * 0.35) * s) for k in range(8)]
        pa.poly(st, (255, 240, 190), shade=0, ol=0)
    pa.poly(ellp(cx + 0.22 * s, cy - 0.22 * s, 0.13 * s, 0.13 * s, 60, 300, 16) + ellp(cx + 0.28 * s, cy - 0.24 * s, 0.1 * s, 0.11 * s, 300, 60, 16)[::-1],
            (250, 230, 150), shade=0, ol=0)
    pa.ell(cx - 0.24 * s, cy - 0.3 * s, 0.12 * s, 0.07 * s, (255, 255, 255), shade=0, ol=0, alpha=0.55)
    pa.glow(cx, cy - 0.08 * s, 0.7 * s, (60, 40, 120), 0.35)
    for (dx, dy) in ((-0.75, -0.55), (0.72, -0.62), (0.8, 0.2)):
        x, y = cx + dx * s, cy + dy * s
        pa.line([(x - 0.08 * s, y), (x + 0.08 * s, y)], (255, 236, 170), 1.6)
        pa.line([(x, y - 0.08 * s), (x, y + 0.08 * s)], (255, 236, 170), 1.6)


def em_herbes(pa, cx, cy, s):
    """Mortier et pilon, brins de sauge et fiole verte."""
    for k, a in enumerate((-0.5, -0.15, 0.25)):
        base = (cx - 0.15 * s + k * 0.12 * s, cy - 0.05 * s)
        tip = (base[0] + math.sin(a) * 0.75 * s, base[1] - math.cos(a) * 0.75 * s)
        pa.line([base, tip], (70, 110, 50), 1.6)
        for j in range(4):
            t = 0.3 + j * 0.18
            px, py = base[0] + (tip[0] - base[0]) * t, base[1] + (tip[1] - base[1]) * t
            for sx in (-1, 1):
                pa.poly(leaf_poly(px + sx * 0.08 * s, py, 0.2 * s, 0.09 * s, a - math.pi / 2 + sx * 0.9, 0.3), (110, 150, 90), shade=0.4, depth=1.5, ol=1.0)
    pa.tubep([(cx + 0.3 * s, cy - 0.7 * s), (cx + 0.05 * s, cy + 0.05 * s)], 0.14 * s, (200, 190, 170), shade=0.6, depth=3, ol=1.4)
    pa.poly(ellp(cx, cy + 0.12 * s, 0.6 * s, 0.55 * s, 0, 180, 30), (190, 182, 166), shade=0.8, depth=s * 0.1, ol=1.8)
    pa.ell(cx, cy + 0.12 * s, 0.6 * s, 0.13 * s, (90, 120, 60), shade=0.4, depth=3, ol=1.4)
    pa.rect(cx - 0.3 * s, cy + 0.62 * s, cx + 0.3 * s, cy + 0.74 * s, (160, 152, 138), shade=0.5, depth=2, ol=1.2)
    fx, fy = cx - 0.72 * s, cy + 0.25 * s
    pa.rect(fx - 0.06 * s, fy - 0.5 * s, fx + 0.06 * s, fy - 0.2 * s, (190, 220, 210), shade=0.4, depth=2, ol=1.0)
    pa.rect(fx - 0.08 * s, fy - 0.58 * s, fx + 0.08 * s, fy - 0.48 * s, (140, 90, 50), shade=0.5, depth=2, ol=1.0)
    pa.ell(fx, fy, 0.24 * s, 0.26 * s, (90, 180, 110), shade=0.7, depth=3, ol=1.4, grad=((150, 230, 150), (40, 120, 70), 90))
    pa.ell(fx - 0.08 * s, fy - 0.08 * s, 0.05 * s, 0.07 * s, (255, 255, 255), shade=0, ol=0, alpha=0.6)


def em_maison(pa, cx, cy, s):
    """Une maisonnette à colombages, toit de chaume, et une grande clé."""
    pa.poly([(cx - 0.55 * s, cy - 0.05 * s), (cx + 0.55 * s, cy - 0.05 * s), (cx + 0.55 * s, cy + 0.62 * s), (cx - 0.55 * s, cy + 0.62 * s)],
            (236, 222, 190), shade=0.5, depth=4, ol=1.6)
    for x in (-0.55, -0.15, 0.15, 0.55):
        pa.line([(cx + x * s, cy - 0.05 * s), (cx + x * s, cy + 0.62 * s)], (90, 58, 34), 0.06 * s)
    pa.line([(cx - 0.55 * s, cy + 0.25 * s), (cx + 0.55 * s, cy + 0.25 * s)], (90, 58, 34), 0.05 * s)
    pa.line([(cx - 0.55 * s, cy + 0.62 * s), (cx - 0.15 * s, cy + 0.25 * s)], (90, 58, 34), 0.05 * s)
    pa.line([(cx + 0.55 * s, cy + 0.62 * s), (cx + 0.15 * s, cy + 0.25 * s)], (90, 58, 34), 0.05 * s)
    pa.rect(cx - 0.11 * s, cy + 0.3 * s, cx + 0.11 * s, cy + 0.62 * s, (120, 70, 40), shade=0.5, depth=2, ol=1.2)
    pa.poly([(cx - 0.75 * s, cy + 0.02 * s), (cx, cy - 0.68 * s), (cx + 0.75 * s, cy + 0.02 * s), (cx + 0.62 * s, cy + 0.06 * s), (cx - 0.62 * s, cy + 0.06 * s)],
            (196, 160, 90), sm=1, shade=0.7, depth=5, ol=1.8)
    for k in range(6):
        pa.line([(cx - 0.5 * s + k * 0.2 * s, cy), (cx - 0.3 * s + k * 0.12 * s, cy - 0.4 * s)], (150, 116, 60), 1.0)
    pa.rect(cx + 0.22 * s, cy - 0.62 * s, cx + 0.36 * s, cy - 0.3 * s, (140, 80, 60), shade=0.5, depth=2, ol=1.2)
    for (dx, dy) in ((-0.42, 0.05), (0.42, 0.05)):
        pa.ell(cx + dx * s - 0.12 * s, cy - 0.32 * s, 0.05 * s, 0.05 * s, (160, 120, 200), shade=0.3, depth=1, ol=0.8)
    # clé
    kx, ky = cx + 0.62 * s, cy + 0.5 * s
    pa.ell(kx, ky - 0.32 * s, 0.17 * s, 0.17 * s, (214, 170, 70), shade=0.8, depth=2, ol=1.4)
    pa.ell(kx, ky - 0.32 * s, 0.07 * s, 0.07 * s, (60, 40, 30), shade=0, ol=1.0)
    pa.rect(kx - 0.04 * s, ky - 0.16 * s, kx + 0.04 * s, ky + 0.38 * s, (214, 170, 70), shade=0.7, depth=1.5, ol=1.2)
    pa.rect(kx + 0.04 * s, ky + 0.2 * s, kx + 0.16 * s, ky + 0.26 * s, (214, 170, 70), shade=0.5, depth=1, ol=1.0)
    pa.rect(kx + 0.04 * s, ky + 0.3 * s, kx + 0.12 * s, ky + 0.36 * s, (214, 170, 70), shade=0.5, depth=1, ol=1.0)


EMBLEMS = {"guilde": em_guilde, "grenouille": em_grenouille, "enclume": br.em_enclume, "boule": em_boule, "herbes": em_herbes,
           "pain": br.em_pain, "ciseaux": br.em_ciseaux, "maison": em_maison}

ENSEIGNES = {
    # id : (texte, sous-titre, style, fond, lettres, emblème)
    "guilde": ("Guilde des Aventuriers", "Contrats · Inscriptions · Taverne", "bois", (78, 50, 30), "or", "guilde"),
    "auberge": ("La Grenouille Repue", "Auberge · Chambres & ragoûts", "peint", (40, 76, 46), "creme", "grenouille"),
    "forge": ("Forge", "Brunehaut · Armes, outils & fers", "fer", (50, 48, 50), "laiton", "enclume"),
    "magie": ("Magie & Curiosités", "Madame Olga · Achat & vente", "peint", (58, 34, 84), "or", "boule"),
    "apothicaire": ("Apothicaire", "Aubin · Potions & remèdes", "peint", (30, 70, 72), "creme", "herbes"),
    "boulangerie": ("Boulangerie", "Honorine · Pain chaud dès l'aube", "bois", (96, 60, 34), "or", "pain"),
    "couture": ("Couture", "Colombe · Robes, capes & tenues", "peint", (120, 52, 70), "creme", "ciseaux"),
    "agence": ("Prosper — Maisons à vendre", "", "peint", (32, 48, 92), "or", "maison"),
}

INKS = {"or": ((252, 216, 120), (186, 126, 40)), "laiton": ((240, 214, 140), (160, 116, 50)), "creme": ((246, 236, 210), (220, 200, 160))}


def enseigne(key):
    """Une enseigne de boutique (512 x 256), sur le modèle de celles de la V70 : planche de chêne à
    ferrures, tôle de fer rivetée ou panneau peint ; médaillon et emblème à gauche, nom en lettres
    dorées ou crème, sous-titre en italique ; patine, crasse, écailles."""
    title, sub, style, bg, ink, emb = ENSEIGNES[key]
    W, H = 512, 256
    seed = 7500 + sorted(ENSEIGNES).index(key)
    R = rng(seed)
    pa = Paint(W, H, 2, bg=bg, seed=seed)
    yy, xx = np.mgrid[0:pa.h, 0:pa.w].astype(np.float32) / pa.K
    big = pa.w
    if style == "bois":
        g = tn(R, big, (8, 16, 32, 64, 128), 0.65, oy=(1, 2, 4, 8, 16))[:pa.h, :pa.w]
        f = tn(R, big, (4, 8, 16, 32), 0.7, oy=(64, 128, 256, 512))[:pa.h, :pa.w]
        rings = np.sin((g * 9 + yy / 23.0) * TAU) * 0.5 + 0.5
        wood = np.array(bg, np.float32) / 255.0 * (0.72 + 0.4 * g[..., None]) * (0.9 + 0.12 * rings[..., None]) * (0.85 + 0.3 * f[..., None])
        for yp in (86, 171):
            wood = wood * (1 - 0.6 * np.exp(-((yy - yp) / 1.4) ** 2))[..., None]
        pa.rgb = wood.astype(np.float32)
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
        fr = INKS[ink][0]
        pa.outline([(12, 12), (W - 12, 12), (W - 12, H - 12), (12, H - 12)], 2.4, fr, alpha=0.95)
        pa.outline([(18, 18), (W - 18, 18), (W - 18, H - 18), (18, H - 18)], 1.0, fr, alpha=0.8)
        for (x, y) in ((18, 18), (W - 18, 18), (18, H - 18), (W - 18, H - 18)):
            pa.ell(x, y, 6, 6, fr, shade=0.5, depth=1.5, ol=1.0)
        # rinceaux aux coins
        for (x, y, sx, sy) in ((30, 30, 1, 1), (W - 30, 30, -1, 1), (30, H - 30, 1, -1), (W - 30, H - 30, -1, -1)):
            pa.line(bez((x, y + sy * 26), (x, y), (x + sx * 26, y), 10), fr, 1.4, alpha=0.8)
            pa.ell(x + sx * 30, y, 2.4, 2.4, fr, shade=0, ol=0)
            pa.ell(x, y + sy * 30, 2.4, 2.4, fr, shade=0, ol=0)
    ex, ey, es = 104, 128, 66
    med = (np.array(bg) * 0.6 + 20).astype(int)
    pa.ell(ex, ey, 84, 84, tuple(int(v) for v in med), shade=0.5, depth=6, ol=2.0)
    pa.outline(ellp(ex, ey, 78, 78, n=72), 1.4, INKS[ink][0], alpha=0.8)
    EMBLEMS[emb](pa, ex, ey, es)
    tx0, tx1 = 196, W - 26
    tw = tx1 - tx0
    lines, dash = br._split_title(pa, title, 54, tw)
    size = 54
    while size > 22 and max(pa.text_size(l_, size)[0] for l_ in lines) > tw:
        size -= 2
    size2 = size
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
    st_col = (24, 14, 10)
    for l_, y_, sz in zip(lines, ys, sizes):
        pa.text((tcx, y_), l_, sz, hi, stroke=2.2, stroke_col=st_col, grad=(hi, lo, 90, (y_ - sz * 0.4, y_ + sz * 0.4)),
                shadow=(2.5, 3.0, 0.55), shade=0.6)
    if dash:
        for sx in (-1, 1):
            pa.line([(tcx + sx * 30, 128), (tcx + sx * 90, 128)], hi, 1.6)
        pa.ell(tcx, 128, 4, 4, hi, shade=0.5, depth=1, ol=0.8)
    if has_sub:
        ssz = 21
        while pa.text_size(sub, ssz, italic=True, bold=False)[0] > tw and ssz > 14:
            ssz -= 1
        pa.text((tcx, 206 if len(lines) > 1 else 176), sub, ssz, INKS[ink][0], italic=True, bold=False, stroke=1.0, stroke_col=st_col, alpha=0.95)
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
        rgb = mix(rgb, C(0.36, 0.26, 0.17), chips * 0.8)
    save_rgb(rgb, "enseigne_%s.png" % key)


def enseignes():
    for k in ENSEIGNES:
        enseigne(k)


# =================================================================== affiches du tableau (512 x 768)

INK = (44, 30, 22)


def _wash(c, k=0.75):
    """Couleur d'aquarelle : la teinte, éclaircie vers le papier."""
    return tuple(int(v * k + 236 * (1 - k)) for v in c)


def dr_slime(pa, cx, by, s, col, mood="content"):
    """Un slime : goutte de gelée posée au sol, petit sommet pointu, yeux ronds, reflet."""
    pts = []
    for t in np.linspace(0, 1, 40):
        a = math.pi + t * math.pi
        x = cx + math.cos(a) * s
        y = by - 0.15 * s + math.sin(a) * s * 0.8 * (1 + 0.35 * max(0.0, 1 - abs(t - 0.5) * 4) ** 2)
        pts.append((x, y))
    pts += [(cx + s * 1.02, by - 0.05 * s), (cx + s * 0.8, by + 0.06 * s), (cx - s * 0.8, by + 0.06 * s), (cx - s * 1.02, by - 0.05 * s)]
    pa.ell(cx, by + 0.06 * s, s * 0.95, s * 0.12, (120, 100, 80), shade=0, ol=0, alpha=0.35)
    pa.poly(pts, _wash(col), sm=2, shade=0.5, depth=s * 0.12, ol=2.0, inkc=INK)
    pa.ell(cx - 0.45 * s, by - 0.75 * s, 0.16 * s, 0.1 * s, (255, 255, 255), shade=0, ol=0, alpha=0.8)
    for sx in (-1, 1):
        ex, ey = cx + sx * 0.3 * s, by - 0.42 * s
        if mood == "fache":
            pa.ell(ex, ey, 0.13 * s, 0.11 * s, (250, 248, 240), shade=0, ol=1.6, inkc=INK)
            pa.ell(ex + sx * -0.02 * s, ey + 0.02 * s, 0.06 * s, 0.06 * s, INK, shade=0, ol=0)
            pa.line([(ex - sx * 0.2 * s, ey - 0.1 * s), (ex + sx * 0.14 * s, ey - 0.24 * s)], INK, 3.0)
        else:
            pa.ell(ex, ey, 0.08 * s, 0.11 * s, INK, shade=0, ol=0)
            pa.ell(ex - 0.025 * s, ey - 0.04 * s, 0.03 * s, 0.035 * s, (255, 255, 255), shade=0, ol=0)
    if mood == "fache":
        pa.line(bez((cx - 0.22 * s, by - 0.12 * s), (cx, by - 0.24 * s), (cx + 0.22 * s, by - 0.12 * s), 10), INK, 2.2)
    else:
        pa.line(bez((cx - 0.14 * s, by - 0.24 * s), (cx, by - 0.12 * s), (cx + 0.14 * s, by - 0.24 * s), 10), INK, 2.0)


def dr_slimes(pa, cx, cy):
    dr_slime(pa, cx - 110, cy + 90, 62, (110, 190, 80))
    dr_slime(pa, cx + 100, cy + 100, 52, (90, 160, 220))
    dr_slime(pa, cx - 5, cy + 30, 86, (120, 200, 90))
    dr_slime(pa, cx + 30, cy + 140, 30, (230, 140, 170))
    dr_slime(pa, cx - 170, cy + 150, 24, (120, 200, 90))


def dr_grenouille(pa, cx, cy):
    """La grenouille géante du lac, assise dans les roseaux, qui darde sa langue vers une botte."""
    green, dark, belly = _wash((90, 150, 60)), _wash((60, 110, 40)), _wash((220, 214, 160))
    for k in range(6):
        x = cx + 100 + k * 18
        pa.line(bez((x, cy + 160), (x + 6, cy + 60), (x - 4 + k * 3, cy - 20 + k * 6), 10), _wash((110, 130, 60)), 3.0)
        pa.ell(x - 4 + k * 3, cy - 30 + k * 6, 4, 14, _wash((130, 90, 50)), shade=0, ol=1.4, inkc=INK)
    pa.ell(cx, cy + 162, 200, 16, _wash((110, 160, 200), 0.5), shade=0, ol=1.4, inkc=INK)
    for sx in (-1, 1):
        pa.poly([(cx + sx * 40, cy + 150), (cx + sx * 150, cy + 136), (cx + sx * 170, cy + 160), (cx + sx * 60, cy + 166)], dark, sm=2, shade=0.4, depth=4, ol=2.0, inkc=INK)
    pa.ell(cx, cy + 90, 120, 82, green, shade=0.5, depth=10, ol=2.2, inkc=INK)
    pa.ell(cx, cy + 112, 74, 54, belly, shade=0.4, depth=6, ol=1.6, inkc=INK)
    pa.ell(cx, cy + 6, 104, 58, green, shade=0.5, depth=8, ol=2.2, inkc=INK)
    for sx in (-1, 1):
        ex = cx + sx * 54
        pa.ell(ex, cy - 40, 30, 30, green, shade=0.5, depth=4, ol=2.2, inkc=INK)
        pa.ell(ex, cy - 42, 20, 20, (252, 246, 220), shade=0, ol=1.6, inkc=INK)
        pa.ell(ex + sx * 4, cy - 40, 9, 12, INK, shade=0, ol=0)
        pa.ell(ex + sx * 1, cy - 45, 3, 3.5, (255, 255, 255), shade=0, ol=0)
    for (x, y, r) in ((cx - 70, cy + 70, 8), (cx + 80, cy + 60, 10), (cx + 50, cy + 130, 7), (cx - 90, cy + 120, 6)):
        pa.ell(x, y, r, r * 0.8, dark, shade=0, ol=1.2, inkc=INK)
    # la langue
    tongue = bez((cx - 30, cy + 30), (cx - 120, cy + 10), (cx - 140, cy - 80), (cx - 150, cy - 120), 24)
    pa.tubep(tongue, 16, _wash((230, 120, 130)), w1=22, shade=0.4, depth=3, ol=1.8, inkc=INK)
    pa.line(bez((cx - 40, cy + 30), (cx, cy + 44), (cx + 50, cy + 32), 10), INK, 2.4)
    # la botte
    bx, by = cx - 150, cy - 140
    pa.poly([(bx + 20, by - 40), (bx - 8, by - 40), (bx - 10, by + 4), (bx - 40, by + 8), (bx - 42, by + 24), (bx + 22, by + 24)],
            _wash((120, 80, 50)), shade=0.4, depth=3, ol=2.0, inkc=INK)
    for k in range(3):
        a = math.pi + 0.6 - k * 0.6
        pa.line([(bx - 50 + math.cos(a) * 6, by - 30 + math.sin(a) * 6), (bx - 50 + math.cos(a) * 22, by - 30 + math.sin(a) * 22)], INK, 1.8)


def dr_gobelin(pa, cx, cy):
    """Un gobelin des bois (original) : grosse tête, longues oreilles, sourire à une dent, lance,
    et une chaussette rayée volée sous le bras."""
    skin, skin_d = _wash((140, 170, 80)), _wash((100, 130, 60))
    tunic = _wash((140, 100, 60))
    pa.tubep([(cx + 70, cy + 170), (cx + 106, cy - 128)], 8, _wash((150, 110, 70)), shade=0.4, depth=2, ol=1.8, inkc=INK)
    pa.poly([(cx + 100, cy - 128), (cx + 112, cy - 172), (cx + 120, cy - 126)], _wash((170, 170, 180)), shade=0.5, depth=2, ol=1.8, inkc=INK)
    for sx in (-1, 1):
        pa.tubep([(cx + sx * 22, cy + 90), (cx + sx * 30, cy + 160)], 18, skin_d, shade=0.4, depth=3, ol=1.8, inkc=INK)
        pa.ell(cx + sx * 36, cy + 166, 22, 10, skin_d, shade=0.4, depth=2, ol=1.8, inkc=INK)
    pa.poly([(cx - 48, cy - 4), (cx + 48, cy - 4), (cx + 60, cy + 104), (cx + 20, cy + 96), (cx, cy + 110), (cx - 24, cy + 96), (cx - 60, cy + 104)],
            tunic, sm=1, shade=0.4, depth=6, ol=2.0, inkc=INK)
    pa.line([(cx - 52, cy + 40), (cx + 54, cy + 40)], _wash((90, 60, 40)), 4.0)
    # la chaussette volée
    sock = [(cx - 100, cy + 4), (cx - 64, cy - 6), (cx - 52, cy + 76), (cx - 30, cy + 92), (cx - 40, cy + 112), (cx - 82, cy + 96), (cx - 86, cy + 70)]
    pa.poly(sock, (240, 236, 226), sm=1, shade=0.4, depth=4, ol=2.0, inkc=INK)
    for k in range(4):
        y = cy + 14 + k * 18
        pa.line([(cx - 96 + k * 2, y), (cx - 62 + k * 2, y - 6)], _wash((200, 60, 50), 0.9), 7.0)
    pa.tubep([(cx - 40, cy + 10), (cx - 60, cy + 60)], 16, skin, shade=0.4, depth=3, ol=1.8, inkc=INK)
    pa.tubep([(cx + 40, cy + 10), (cx + 84, cy + 40)], 16, skin, shade=0.4, depth=3, ol=1.8, inkc=INK)
    pa.ell(cx + 90, cy + 38, 14, 14, skin, shade=0.4, depth=2, ol=1.8, inkc=INK)
    # tête
    for sx in (-1, 1):
        ear = [(cx + sx * 50, cy - 90), (cx + sx * 150, cy - 128), (cx + sx * 64, cy - 56)]
        pa.poly(ear, skin, sm=1, shade=0.4, depth=4, ol=2.0, inkc=INK)
        pa.poly([(cx + sx * 64, cy - 86), (cx + sx * 124, cy - 116), (cx + sx * 70, cy - 66)], _wash((210, 150, 130)), sm=1, shade=0, ol=0)
    pa.ell(cx, cy - 70, 70, 64, skin, shade=0.5, depth=8, ol=2.2, inkc=INK)
    pa.poly([(cx - 40, cy - 130), (cx + 30, cy - 136), (cx + 10, cy - 168), (cx - 6, cy - 150), (cx - 20, cy - 170)], _wash((90, 60, 40)), sm=1, shade=0.3, depth=3, ol=1.8, inkc=INK)
    for sx in (-1, 1):
        ex = cx + sx * 26
        pa.ell(ex, cy - 82, 15, 13, (252, 248, 210), shade=0, ol=1.6, inkc=INK)
        pa.ell(ex + sx * 3, cy - 80, 6, 7, INK, shade=0, ol=0)
        pa.line([(ex - 14, cy - 102 + sx * 4), (ex + 14, cy - 102 - sx * 4)], INK, 3.0)
    pa.poly([(cx - 8, cy - 74), (cx + 6, cy - 72), (cx + 26, cy - 44), (cx - 2, cy - 48)], skin_d, sm=1, shade=0.4, depth=2, ol=1.8, inkc=INK)
    pa.poly(bez((cx - 40, cy - 38), (cx, cy - 6), (cx + 40, cy - 38), 14), (120, 50, 40), shade=0, ol=2.0, inkc=INK)
    pa.poly([(cx - 4, cy - 33), (cx + 8, cy - 33), (cx + 2, cy - 22)], (250, 246, 230), shade=0, ol=1.2, inkc=INK)


def dr_navets(pa, cx, cy):
    """Deux navets qui s'enfuient sur leurs petites jambes, traits de vitesse et gouttes de sueur."""
    def navet(x, y, s, lean):
        for k in range(4):
            a = -math.pi / 2 + (k - 1.5) * 0.35 + lean
            leaf = leaf_poly(x + math.cos(a) * 0.5 * s, y - 0.7 * s + math.sin(a) * 0.5 * s, 1.0 * s, 0.4 * s, a, 0.3)
            pa.poly(leaf, _wash((90, 150, 60)), shade=0.4, depth=2, ol=1.8, inkc=INK)
        for sx in (-1, 1):
            pa.line([(x + sx * 0.25 * s, y + 0.55 * s), (x + sx * 0.35 * s + lean * 30, y + 1.1 * s)], INK, 2.6)
            pa.line([(x + sx * 0.35 * s + lean * 30, y + 1.1 * s), (x + sx * 0.35 * s + lean * 30 + 0.22 * s, y + 1.12 * s)], INK, 2.6)
        body = [(x - 0.7 * s, y - 0.1 * s), (x - 0.5 * s, y - 0.62 * s), (x, y - 0.78 * s), (x + 0.5 * s, y - 0.62 * s), (x + 0.7 * s, y - 0.1 * s),
                (x + 0.45 * s, y + 0.45 * s), (x + 0.08 * s, y + 0.62 * s), (x, y + 0.95 * s), (x - 0.08 * s, y + 0.62 * s), (x - 0.45 * s, y + 0.45 * s)]
        pa.poly(body, (244, 238, 230), sm=2, shade=0.5, depth=s * 0.12, ol=2.2, inkc=INK)
        pa.poly([(x - 0.7 * s, y - 0.1 * s), (x - 0.5 * s, y - 0.62 * s), (x, y - 0.78 * s), (x + 0.5 * s, y - 0.62 * s), (x + 0.7 * s, y - 0.1 * s),
                 (x, y - 0.25 * s)], _wash((170, 90, 170)), sm=2, shade=0.4, depth=4, ol=0)
        for sx in (-1, 1):
            pa.ell(x + sx * 0.22 * s, y + 0.05 * s, 0.07 * s, 0.1 * s, INK, shade=0, ol=0)
        pa.ell(x, y + 0.3 * s, 0.1 * s, 0.08 * s, (150, 60, 50), shade=0, ol=1.2, inkc=INK)
        pa.ell(x + 0.55 * s, y - 0.5 * s, 0.06 * s, 0.1 * s, _wash((120, 180, 230)), shade=0, ol=1.2, inkc=INK)
        for k in range(3):
            yy_ = y - 0.2 * s + k * 0.3 * s
            pa.line([(x - 1.0 * s - k * 6, yy_), (x - 1.6 * s - k * 6, yy_)], INK, 2.0)
    navet(cx + 50, cy + 30, 78, 0.25)
    navet(cx - 120, cy + 110, 46, 0.2)
    pa.line([(cx - 220, cy + 175), (cx + 200, cy + 175)], INK, 1.6)


def dr_donjon(pa, cx, cy):
    """La vieille tour en ruine des Crocs, sa porte en arc et les marches qui descendent ; corbeaux."""
    rock = _wash((150, 140, 120))
    pa.poly([(cx - 220, cy + 170), (cx - 170, cy + 90), (cx - 90, cy + 70), (cx + 60, cy + 76), (cx + 150, cy + 60), (cx + 220, cy + 120), (cx + 220, cy + 170)],
            rock, sm=1, shade=0.4, depth=8, ol=2.2, inkc=INK)
    tw = [(cx - 70, cy + 80), (cx - 64, cy - 140), (cx - 40, cy - 152), (cx - 30, cy - 132), (cx - 6, cy - 166), (cx + 20, cy - 140), (cx + 34, cy - 156),
          (cx + 60, cy - 122), (cx + 70, cy + 80)]
    pa.poly(tw, _wash((170, 160, 140)), shade=0.5, depth=8, ol=2.4, inkc=INK)
    for k in range(8):
        y = cy - 118 + k * 26
        pa.line([(cx - 66, y), (cx + 66, y)], INK, 1.2, alpha=0.6)
        for j in range(4):
            x = cx - 50 + j * 34 + (k % 2) * 16
            pa.line([(x, y), (x, y + 26)], INK, 1.0, alpha=0.5)
    pa.poly(arch_pts(cx - 30, cx + 30, cy + 20, cy + 80, n=16), _wash((40, 34, 30), 0.95), shade=0, ol=2.2, inkc=INK)
    for k in range(4):
        pa.line([(cx - 24 + k * 3, cy + 46 + k * 9), (cx + 24 - k * 3, cy + 46 + k * 9)], _wash((150, 140, 120)), 2.0)
    pa.ell(cx - 14, cy - 80, 8, 14, _wash((40, 34, 30), 0.95), shade=0, ol=1.6, inkc=INK)
    pa.ell(cx + 20, cy - 20, 7, 12, _wash((40, 34, 30), 0.95), shade=0, ol=1.6, inkc=INK)
    for (x, y, s) in ((cx - 120, cy - 130, 1.0), (cx - 170, cy - 100, 0.8), (cx + 120, cy - 40, 0.9)):
        pa.line(bez((x - 18 * s, y - 2 * s), (x - 8 * s, y - 10 * s), (x, y), 8), INK, 2.2)
        pa.line(bez((x, y), (x + 8 * s, y - 10 * s), (x + 18 * s, y - 2 * s), 8), INK, 2.2)
    pa.text((cx, cy + 140), "1 000 marches…", 22, INK, italic=True, bold=False, alpha=0.85)


def dr_chapeau(pa, cx, cy):
    """Le chapeau à plume du Baron, emporté par le vent."""
    for k in range(4):
        y = cy - 120 + k * 50
        pa.line(bez((cx - 220, y), (cx - 140, y - 20), (cx - 90, y + 10), 12), INK, 2.0, alpha=0.8)
    a = math.radians(-14)
    ca, sa = math.cos(a), math.sin(a)

    def P(u, v):
        return (cx + u * ca - v * sa, cy + u * sa + v * ca)
    brim = [P(math.cos(t) * 170, 30 + math.sin(t) * 44) for t in np.linspace(0, TAU, 48, endpoint=False)]
    pa.poly(brim, _wash((60, 70, 120)), shade=0.5, depth=8, ol=2.2, inkc=INK)
    crown = [P(-90, 30), P(-80, -60), P(-40, -96), P(40, -96), P(80, -60), P(90, 30)]
    pa.poly(crown, _wash((70, 80, 140)), sm=2, shade=0.5, depth=8, ol=2.2, inkc=INK)
    band = [P(-90, 8), P(90, 8), P(90, 32), P(-90, 32)]
    pa.poly(band, _wash((200, 60, 50)), shade=0.4, depth=3, ol=2.0, inkc=INK)
    pa.ell(*P(60, 20), 14, 14, _wash((220, 180, 70)), shade=0.5, depth=2, ol=1.8, inkc=INK)
    feather = []
    root = P(60, 10)
    tip = P(-150, -180)
    for t in np.linspace(0, 1, 20):
        x = root[0] + (tip[0] - root[0]) * t + math.sin(t * math.pi) * 40
        y = root[1] + (tip[1] - root[1]) * t - math.sin(t * math.pi) * 20
        feather.append((x, y))
    pa.poly(tube(feather, 50, 4), _wash((80, 160, 80)), sm=1, shade=0.4, depth=4, ol=2.0, inkc=INK)
    pa.line(feather, INK, 1.8)


def dr_roi(pa, cx, cy):
    """Le Roi Gélatineux : énorme slime à petite couronne, l'air fâché ; deux petits slimes."""
    dr_slime(pa, cx - 170, cy + 170, 34, (110, 190, 80))
    dr_slime(pa, cx + 175, cy + 172, 30, (110, 190, 80))
    dr_slime(pa, cx, cy + 165, 150, (100, 186, 70), mood="fache")
    oy = 96
    crown = [(cx - 42, cy - 112 + oy), (cx - 50, cy - 168 + oy), (cx - 22, cy - 140 + oy), (cx, cy - 182 + oy), (cx + 22, cy - 140 + oy), (cx + 50, cy - 168 + oy), (cx + 42, cy - 112 + oy)]
    pa.poly(crown, _wash((236, 190, 60), 0.9), shade=0.6, depth=3, ol=2.2, inkc=INK)
    for (x, y, c) in ((cx, cy - 128 + oy, (200, 50, 50)), (cx - 26, cy - 124 + oy, (60, 110, 200)), (cx + 26, cy - 124 + oy, (60, 110, 200))):
        pa.ell(x, y, 6, 6, _wash(c, 0.9), shade=0.3, depth=1, ol=1.2, inkc=INK)
    for k in range(5):
        x = cx - 120 + k * 60
        pa.ell(x, cy + 172 + (k % 2) * 6, 10, 4, _wash((100, 186, 70)), shade=0, ol=1.2, inkc=INK)


def stamp(pa, cx, cy, r, rank, rot=-14.0, col=(170, 36, 30)):
    """Tampon de la Guilde : double cercle, « GUILDE · MONTJOIE · », le rang au milieu."""
    m = Image.new("L", (pa.w, pa.h), 0)
    d = ImageDraw.Draw(m)
    K = pa.K
    d.ellipse(((cx - r) * K, (cy - r) * K, (cx + r) * K, (cy + r) * K), outline=255, width=int(3 * K))
    d.ellipse(((cx - r * 0.72) * K, (cy - r * 0.72) * K, (cx + r * 0.72) * K, (cy + r * 0.72) * K), outline=255, width=int(1.6 * K))
    f = font(int(r * 0.24 * K), bold=True)
    txt = "GUILDE · MONTJOIE · "
    n = len(txt)
    for i, ch in enumerate(txt):
        a = -math.pi / 2 + i / n * TAU
        x, y = cx + math.cos(a) * r * 0.86, cy + math.sin(a) * r * 0.86
        g = Image.new("L", (int(r * 0.5 * K), int(r * 0.5 * K)), 0)
        ImageDraw.Draw(g).text((g.size[0] / 2, g.size[1] / 2), ch, font=f, fill=255, anchor="mm")
        g = g.rotate(-math.degrees(a) - 90, resample=Image.BICUBIC)
        m.paste(255, (int(x * K - g.size[0] / 2), int(y * K - g.size[1] / 2)), g)
    f2 = font(int(r * 0.55 * K), bold=True)
    d.text((cx * K, cy * K), rank, font=f2, fill=255, anchor="mm")
    f3 = font(int(r * 0.16 * K), bold=True)
    d.text((cx * K, (cy + r * 0.48) * K), "RANG", font=f3, fill=255, anchor="mm")
    m = m.rotate(rot, center=(cx * K, cy * K), resample=Image.BICUBIC)
    rr = rng(int(cx * 13 + cy))
    holes = (rr.random((pa.h, pa.w)) < 0.12).astype(np.float32)
    holes = gblur(holes, 1.2)
    ma = np.asarray(m, np.float32) / 255.0 * np.clip(1 - holes * 3.0, 0.2, 1)
    pa.comp(Image.fromarray((ma * 255).astype(np.uint8)), col, alpha=0.8, tex=False)


AFFICHES = {
    # n : (en-tête, titre, texte, récompense, rang, dessin, papier)
    1: ("CONTRAT", "On recherche :\n5 slimes", "Les slimes bouchent les puits de la Basse-Ville. Rapportez leur gelée à Églantine.",
        "Récompense : 20 pièces", "F", dr_slimes, (0.9, 0.84, 0.68)),
    2: ("ATTENTION !", "Grenouilles géantes\nau lac !", "Elles avalent les pêcheurs (et leurs bottes). Chassez-en trois, gardez vos distances.",
        "Récompense : 30 pièces", "E", dr_grenouille, (0.88, 0.85, 0.72)),
    3: ("CONTRAT", "Gobelins dans\nle Bois des Lutins", "Ils volent les chaussettes qui sèchent au lavoir. Chassez-en quatre et rendez les chaussettes.",
        "Récompense : 25 pièces", "E", dr_gobelin, (0.9, 0.83, 0.66)),
    4: ("URGENT", "Navets en fuite !", "Aidez Père Gaubert aux Champs du Sud. Filet fourni. Courir vite recommandé.",
        "1 pièce par navet attrapé", "F", dr_navets, (0.91, 0.86, 0.7)),
    5: ("EXPÉDITION", "Le Donjon\ndes Mille Marches", "Descendre au 2e étage et revenir entier. Voir Odon, le gardien, au pied des Crocs.",
        "Récompense : 40 pièces", "D", dr_donjon, (0.86, 0.81, 0.67)),
    6: ("PERDU", "Le chapeau à plume\ndu Baron", "Envolé par une fenêtre du château. Bleu, ruban rouge, grande plume verte. Le Baron est très triste.",
        "Récompense honnête", "F", dr_chapeau, (0.9, 0.86, 0.74)),
}


def _affiche(name, header, title, text, reward, rank, drawing, paper, seed, wanted=False):
    W, H = 512, 768
    R = rng(seed)
    pa = Paint(W, H, 2, seed=seed)
    pa.rgb[:] = paper_bg(R, pa.w, pa.h, paper, 0.45, 0.4)
    red = (156, 34, 26)
    pa.outline([(22, 22), (W - 22, 22), (W - 22, H - 22), (22, H - 22)], 2.0, INK, alpha=0.7)
    if wanted:
        pa.text((W / 2, 84), "AVIS DE", 40, INK, spacing=4, shade=0)
        pa.text((W / 2, 142), "RECHERCHE", 62, red, spacing=3, shade=0)
        pa.line([(60, 182), (W - 60, 182)], INK, 2.0)
        cy_d = 380
    else:
        pa.text((W / 2, 64), header, 34, red, spacing=3, shade=0)
        lines = title.split("\n")
        size = 48
        while size > 28 and max(htext_size(pa, l_, size)[0] for l_ in lines) > W - 80:
            size -= 2
        y = 118
        for l_ in lines:
            htext(pa, (W / 2, y), l_, size, INK)
            y += size * 0.92
        cy_d = 372
    drawing(pa, W / 2, cy_d)
    if wanted:
        pa.text((W / 2, 596), "Le Roi Gélatineux", 40, INK, italic=True, shade=0)
        ty = 638
    else:
        ty = 566
    for l_ in wrap_lines(pa, text, 21, W - 110, italic=True, bold=False):
        pa.text((W / 2, ty), l_, 21, INK, italic=True, bold=False, shade=0)
        ty += 28
    pa.text((W / 2, H - 62 if not wanted else H - 48), reward, 30 if not wanted else 34, red, bold=True, shade=0)
    stamp(pa, W - 84, 226 if not wanted else 236, 44, rank, rot=12.0)
    # le clou en haut, et son trou déchiré
    pa.ell(W / 2, 22, 10, 10, (0, 0, 0), alpha=0.3, shade=0, ol=0, tex=False)
    pa.ell(W / 2 - 1, 20, 7, 7, (80, 76, 72), shade=0.8, depth=2, ol=1.2)
    rgb = br._poster_finish(pa, R)
    save_rgb(rgb, name + ".png")


def affiche_quete(n):
    header, title, text, reward, rank, drawing, paper = AFFICHES[n]
    _affiche("affiche_quete_%d" % n, header, title, text, reward, rank, drawing, paper, 7600 + n)


def affiche_recherche():
    """Avis de recherche du Roi Gélatineux."""
    _affiche("affiche_recherche", "", "", "Vu au fond du Donjon des Mille Marches. Très collant ! Voir Maître Hugues.",
             "RÉCOMPENSE : 200 pièces", "D", dr_roi, (0.86, 0.79, 0.62), 7610, wanted=True)


def affiches():
    for n in AFFICHES:
        affiche_quete(n)
    affiche_recherche()


# =================================================================== icônes (128 px, comme les autres)

ICON_NAMES_V71 = ["carte_aventurier", "chapelet_soleil", "cristal_orage", "chapeau_baron", "page_grimoire", "coeur_gelee", "navet_dore",
                  "cuisse_grenouille", "gelee_slime", "croc_gobelin", "cle_cuivre", "cidre_montjoie", "tourte_montjoie", "pain_montjoie",
                  "titre_propriete", "jus_pomme", "banniere_gobelin"]


def ico_save(img, name):
    """Cerné et ombré comme les autres icônes (generate_items_v28), puis réduit à 128 px.
    N'écrase jamais une icône qui existait avant la V71."""
    import generate_items_v28 as icons
    p = ITEMS / (name + ".png")
    if name not in ICON_NAMES_V71:
        sys.exit("icône inconnue : " + name)
    img2 = icons.shadow(icons.outline(img))
    img2.resize((128, 128), Image.LANCZOS).save(p, optimize=True)
    _log(p)


def T(R, oct_=(16, 32, 64, 128), k=0.22):
    return (1 - k / 2) + k * tn(R, IS, oct_, 0.6)


def P_(d, pts, col, w=0):
    d.polygon(pts, fill=col)


def ic_carte_aventurier():
    img = canvas_i()
    R = rng(7801)
    a = math.radians(-8)
    ca, sa = math.cos(a), math.sin(a)

    def P(u, v):
        return (256 + u * ca - v * sa, 262 + u * sa + v * ca)

    def rrect(u0, v0, u1, v1, r=22, n=6):
        pts = []
        for (cu, cv, a0) in ((u1 - r, v0 + r, -90), (u1 - r, v1 - r, 0), (u0 + r, v1 - r, 90), (u0 + r, v0 + r, 180)):
            for k in range(n + 1):
                t = math.radians(a0 + 90 * k / n)
                pts.append(P(cu + math.cos(t) * r, cv + math.sin(t) * r))
        return pts
    vol(img, lambda d: d.polygon(rrect(-220, -150, 220, 150), fill=255), (232, 214, 170), depth=14, gloss=0.3, tex=T(R))
    vol(img, lambda d: d.polygon(rrect(-220, -150, 220, -92, 22), fill=255), (40, 104, 70), depth=6, gloss=0.3)
    d = ImageDraw.Draw(img)
    f = font(34, bold=True)
    tmp = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    ImageDraw.Draw(tmp).text((256, 140), "AVENTURIER", font=f, fill=(246, 226, 160, 255), anchor="mm")
    img.alpha_composite(tmp.rotate(8, center=(256, 262), resample=Image.BICUBIC))
    # portrait (silhouette) et lignes
    vol(img, lambda d_: d_.polygon(rrect(-196, -74, -86, 66, 8), fill=255), (196, 180, 150), depth=4, gloss=0.1)
    vol(img, lambda d_: (d_.ellipse((P(-141, -30)[0] - 26, P(-141, -30)[1] - 28, P(-141, -30)[0] + 26, P(-141, -30)[1] + 28), fill=255),
                         d_.chord((P(-141, 44)[0] - 46, P(-141, 44)[1] - 38, P(-141, 44)[0] + 46, P(-141, 44)[1] + 60), 180, 360, fill=255)),
        (110, 90, 70), depth=4, gloss=0.1)
    d = ImageDraw.Draw(img)
    for k, (u0, u1) in enumerate(((-60, 120), (-60, 90), (-60, 130), (-60, 70))):
        d.line([P(u0, -56 + k * 30), P(u1, -56 + k * 30)], fill=(120, 96, 70, 255), width=7)
    # rang F, tampon rouge
    vol(img, lambda d_: d_.ellipse((P(150, 70)[0] - 52, P(150, 70)[1] - 52, P(150, 70)[0] + 52, P(150, 70)[1] + 52), fill=255), (180, 40, 32), depth=8, gloss=0.4)
    tmp = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    ImageDraw.Draw(tmp).text(P(150, 72), "F", font=font(70, bold=True), fill=(250, 230, 200, 255), anchor="mm")
    img.alpha_composite(tmp)
    ico_save(img, "carte_aventurier")


def sun_disc(img, cx, cy, r, base=(222, 170, 60)):
    rays = []
    for k in range(24):
        a = k / 24 * TAU
        rr = r * (1.0 if k % 2 == 0 else 0.78)
        rays.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    vol(img, lambda d: d.polygon(rays, fill=255), base, depth=8, gloss=0.8)
    vol(img, lambda d: d.ellipse((cx - r * 0.58, cy - r * 0.58, cx + r * 0.58, cy + r * 0.58), fill=255), (240, 196, 80), depth=10, gloss=1.0)


def ic_chapelet_soleil():
    img = canvas_i()
    R = rng(7802)
    pts = []
    for k in range(26):
        t = k / 26 * TAU
        x = 256 + math.cos(t) * 150
        y = 196 + math.sin(t) * 120
        pts.append((x, y))
    d = ImageDraw.Draw(img)
    d.line(pts + [pts[0]], fill=(140, 110, 70, 255), width=4)
    for k, (x, y) in enumerate(pts):
        if abs(x - 256) < 40 and y > 280:
            continue
        r = 17 if k % 6 else 22
        col = (168, 112, 64) if k % 6 else (236, 230, 216)
        vol(img, lambda d_, x=x, y=y, r=r: d_.ellipse((x - r, y - r, x + r, y + r), fill=255), col, depth=6, gloss=0.8)
    d = ImageDraw.Draw(img)
    d.line([(256, 316), (256, 352)], fill=(140, 110, 70, 255), width=5)
    vol(img, lambda d_: d_.ellipse((240, 300, 272, 332), fill=255), (236, 230, 216), depth=6, gloss=0.8)
    sun_disc(img, 256, 410, 82)
    glow_i(img, 256, 400, 50, (255, 230, 150), 0.35)
    ico_save(img, "chapelet_soleil")


def ic_cristal_orage():
    img = canvas_i()
    R = rng(7803)
    tex = T(R, (8, 16, 32), 0.2)
    cr = [((256, 470), 26, 70, 300, 0.0, (110, 90, 210)), ((180, 470), 18, 52, 190, -0.4, (90, 80, 190)), ((336, 470), 20, 54, 220, 0.35, (120, 100, 220))]
    masks = []
    for (bx, by), _, w, L, a, col in cr:
        ca, sa = math.sin(a), -math.cos(a)
        nx, ny = -sa, ca
        tip = (bx + ca * L, by + sa * L)
        sh = (bx + ca * (L - w * 1.2), by + sa * (L - w * 1.2))
        poly = [(bx - nx * w, by - ny * w), (sh[0] - nx * w, sh[1] - ny * w), tip, (sh[0] + nx * w, sh[1] + ny * w), (bx + nx * w, by + ny * w)]
        masks.append(vol(img, lambda d, poly=poly: d.polygon(poly, fill=255), col, depth=8, gloss=0.9, tex=tex))
        d = ImageDraw.Draw(img)
        d.line([((poly[0][0] + poly[4][0]) / 2, (poly[0][1] + poly[4][1]) / 2), tip], fill=(190, 180, 250, 200), width=3)
    inside = np.clip(sum(masks), 0, 1)
    bolt = [(282, 176), (220, 306), (260, 306), (220, 430), (318, 278), (276, 280), (322, 176)]
    glow_i(img, 262, 310, 110, (150, 170, 255), 0.7, inside=inside)
    d = ImageDraw.Draw(img)
    d.polygon([(x + 3, y + 3) for x, y in bolt], fill=(70, 50, 140, 255))
    vol(img, lambda d: d.polygon(bolt, fill=255), (255, 236, 110), depth=4, gloss=0.5)
    glow_i(img, 262, 310, 50, (255, 255, 220), 0.6, inside=inside)
    vol(img, lambda d: d.polygon([(120, 470), (392, 470), (370, 436), (140, 436)], fill=255), (120, 110, 100), depth=8, gloss=0.2, tex=T(R))
    d = ImageDraw.Draw(img)
    for (x, y) in ((120, 160), (400, 200), (390, 120)):
        d.line([(x - 16, y), (x + 16, y)], fill=(255, 250, 200, 255), width=5)
        d.line([(x, y - 16), (x, y + 16)], fill=(255, 250, 200, 255), width=5)
    ico_save(img, "cristal_orage")


def ic_chapeau_baron():
    img = canvas_i()
    R = rng(7804)
    tex = T(R)
    vol(img, lambda d: d.ellipse((40, 280, 472, 420), fill=255), (60, 72, 140), depth=16, gloss=0.4, tex=tex)
    vol(img, lambda d: d.polygon(chaikin([(150, 350), (160, 220), (210, 170), (310, 170), (356, 220), (362, 350)], 2), fill=255), (72, 86, 160), depth=26, gloss=0.5, tex=tex)
    vol(img, lambda d: d.polygon([(150, 300), (362, 300), (362, 344), (150, 344)], fill=255), (190, 44, 40), depth=6, gloss=0.5)
    vol(img, lambda d: d.rectangle((226, 296, 270, 348), fill=255) or d.rectangle((236, 306, 260, 338), fill=0), (230, 186, 70), depth=4, gloss=0.9)
    ctr = bez((300, 310), (380, 200), (420, 90), (300, 40), 30)
    feather = tube(ctr, 70, 6)
    vol(img, lambda d: d.polygon(feather, fill=255), (70, 160, 80), depth=10, gloss=0.4)
    d = ImageDraw.Draw(img)
    d.line(ctr, fill=(220, 236, 200, 255), width=4)
    for k in range(3, 28, 3):
        (x, y) = ctr[k]
        d.line([(x, y), (x + 26, y + 10)], fill=(50, 120, 60, 255), width=3)
    ico_save(img, "chapeau_baron")


def ic_page_grimoire():
    img = canvas_i()
    R = rng(7805)
    tex = T(R, (8, 16, 32, 64), 0.25)
    page = [(100, 60), (380, 46), (410, 120), (398, 220), (420, 330), (396, 460), (120, 470), (96, 380), (110, 260), (88, 160)]
    vol(img, lambda d: d.polygon(chaikin(page, 1), fill=255), (226, 206, 160), depth=14, gloss=0.2, tex=tex)
    d = ImageDraw.Draw(img)
    cx, cy = 252, 230
    ink = (110, 50, 140, 255)
    d.ellipse((cx - 100, cy - 100, cx + 100, cy + 100), outline=ink, width=6)
    d.ellipse((cx - 78, cy - 78, cx + 78, cy + 78), outline=ink, width=3)
    tri = [(cx + math.cos(-math.pi / 2 + k * TAU / 3) * 78, cy + math.sin(-math.pi / 2 + k * TAU / 3) * 78) for k in range(3)]
    d.polygon(tri, outline=ink)
    d.line(tri + [tri[0]], fill=ink, width=4)
    d.ellipse((cx - 30, cy - 4, cx + 10, cy + 36), fill=ink)
    d.ellipse((cx - 18, cy - 10, cx + 22, cy + 30), fill=(226, 206, 160, 255))
    for k in range(3):
        x, y = tri[k]
        d.ellipse((x - 9, y - 9, x + 9, y + 9), fill=ink)
    for k in range(12):
        a = k / 12 * TAU
        x, y = cx + math.cos(a) * 89, cy + math.sin(a) * 89
        d.line([(x - 5, y - 5), (x + 5, y + 5)], fill=ink, width=3)
    for k in range(4):
        y = 370 + k * 24
        d.line([(140, y), (370 - (k % 2) * 60, y)], fill=(90, 70, 60, 255), width=5)
    glow_i(img, cx, cy, 90, (180, 120, 255), 0.35, inside=shape_i(lambda d_: d_.polygon(page, fill=255)))
    ico_save(img, "page_grimoire")


def heart_pts(cx, cy, s, n=60):
    pts = []
    for k in range(n):
        t = k / n * TAU
        x = 16 * math.sin(t) ** 3
        y = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
        pts.append((cx + x * s, cy + y * s))
    return pts


def ic_coeur_gelee():
    img = canvas_i()
    R = rng(7806)
    hp = heart_pts(256, 290, 11.5)
    m = vol(img, lambda d: d.polygon(hp, fill=255), (70, 190, 60), depth=40, gloss=1.4)
    glow_i(img, 256, 320, 110, (120, 255, 120), 0.45, inside=m)
    d = ImageDraw.Draw(img)
    for _ in range(14):
        x, y = R.uniform(170, 340), R.uniform(230, 380)
        r = R.uniform(5, 13)
        if shape_i(lambda d_: d_.polygon(hp, fill=255))[int(y), int(x)] > 0:
            d.ellipse((x - r, y - r, x + r, y + r), outline=(200, 255, 190, 200), width=2)
            d.ellipse((x - r * 0.5, y - r * 0.6, x - r * 0.1, y - r * 0.2), fill=(255, 255, 255, 220))
    vol(img, lambda d_: d_.ellipse((176, 196, 226, 236), fill=255), (230, 255, 220), depth=8, gloss=0.6, alpha=0.7)
    crown = [(196, 150), (186, 80), (226, 116), (256, 60), (286, 116), (326, 80), (316, 150)]
    vol(img, lambda d_: d_.polygon(crown, fill=255), (232, 184, 56), depth=8, gloss=1.0)
    for (x, y, c) in ((256, 128, (210, 40, 40)), (220, 134, (60, 120, 220)), (292, 134, (60, 120, 220))):
        vol(img, lambda d_, x=x, y=y: d_.ellipse((x - 10, y - 10, x + 10, y + 10), fill=255), c, depth=4, gloss=1.0)
    ico_save(img, "coeur_gelee")


def navet(img, R, cx, cy, s, body=(244, 238, 228), top=(170, 90, 170), leaf=(80, 150, 60), gloss=0.5):
    for k in range(5):
        a = -math.pi / 2 + (k - 2) * 0.32
        lp = leaf_poly(cx + math.cos(a) * 0.95 * s, cy - 0.6 * s + math.sin(a) * 0.95 * s, 1.3 * s, 0.55 * s, a, 0.3)
        vol(img, lambda d, lp=lp: d.polygon(lp, fill=255), tuple(int(v * R.uniform(0.85, 1.1)) for v in leaf), depth=6, gloss=0.3)
    bp = chaikin([(cx - 0.95 * s, cy), (cx - 0.7 * s, cy - 0.7 * s), (cx, cy - 0.9 * s), (cx + 0.7 * s, cy - 0.7 * s), (cx + 0.95 * s, cy),
                  (cx + 0.55 * s, cy + 0.6 * s), (cx + 0.1 * s, cy + 0.8 * s), (cx, cy + 1.3 * s), (cx - 0.1 * s, cy + 0.8 * s), (cx - 0.55 * s, cy + 0.6 * s)], 2)
    m = vol(img, lambda d: d.polygon(bp, fill=255), body, depth=18, gloss=gloss, tex=T(R, (16, 32, 64), 0.15))
    tp = chaikin([(cx - 0.95 * s, cy - 0.02 * s), (cx - 0.7 * s, cy - 0.7 * s), (cx, cy - 0.9 * s), (cx + 0.7 * s, cy - 0.7 * s), (cx + 0.95 * s, cy - 0.02 * s),
                  (cx, cy - 0.28 * s)], 2)
    vol(img, lambda d: d.polygon(tp, fill=255), top, depth=14, gloss=gloss)
    return m


def ic_navet_dore():
    img = canvas_i()
    R = rng(7807)
    m = navet(img, R, 256, 290, 140, body=(236, 190, 70), top=(214, 150, 40), gloss=1.0)
    glow_i(img, 210, 250, 70, (255, 240, 170), 0.35, inside=m)
    d = ImageDraw.Draw(img)
    for (x, y, r) in ((120, 200, 18), (390, 260, 14), (360, 420, 12)):
        d.polygon([(x, y - r), (x + r * 0.3, y - r * 0.3), (x + r, y), (x + r * 0.3, y + r * 0.3), (x, y + r), (x - r * 0.3, y + r * 0.3), (x - r, y), (x - r * 0.3, y - r * 0.3)],
                  fill=(255, 246, 190, 255))
    ico_save(img, "navet_dore")


def ic_cuisse_grenouille():
    img = canvas_i()
    R = rng(7808)
    # cuisse dodue (peau verte tachetée), jarret, pied palmé
    thigh = chaikin([(120, 150), (230, 110), (330, 160), (350, 240), (300, 300), (230, 300), (150, 260), (100, 200)], 2)
    shin = tube(bez((300, 270), (340, 330), (370, 380), (390, 410), 16), 70, 40)
    foot = [(360, 400), (470, 380), (430, 412), (476, 440), (424, 446), (450, 486), (396, 456), (376, 470)]
    vol(img, lambda d: d.polygon(foot, fill=255), (110, 160, 70), depth=8, gloss=0.4)
    d = ImageDraw.Draw(img)
    for (x, y) in ((470, 380), (476, 440), (450, 486)):
        d.ellipse((x - 9, y - 9, x + 9, y + 9), fill=(90, 140, 60, 255))
    vol(img, lambda d: d.polygon(shin, fill=255), (120, 170, 80), depth=14, gloss=0.5, tex=T(R))
    m = vol(img, lambda d: d.polygon(thigh, fill=255), (120, 176, 80), depth=30, gloss=0.6, tex=T(R))
    d = ImageDraw.Draw(img)
    for _ in range(16):
        x, y = R.uniform(140, 320), R.uniform(140, 280)
        if m[int(y), int(x)] > 0.5:
            r = R.uniform(7, 15)
            d.ellipse((x - r, y - r * 0.7, x + r, y + r * 0.7), fill=(70, 120, 50, 255))
    # le bout coupé : chair rose et os
    end = [(100 + math.cos(t) * 34 - math.sin(t) * 0, 205 + math.sin(t) * 62) for t in np.linspace(0, TAU, 40, endpoint=False)]
    vol(img, lambda d: d.polygon(end, fill=255), (232, 176, 160), depth=10, gloss=0.3)
    d = ImageDraw.Draw(img)
    d.polygon([(100 + math.cos(t) * 26, 205 + math.sin(t) * 52) for t in np.linspace(0, TAU, 40, endpoint=False)], outline=(200, 130, 120, 255))
    vol(img, lambda d: d.ellipse((96, 214, 120, 240), fill=255), (246, 240, 222), depth=4, gloss=0.6)
    ico_save(img, "cuisse_grenouille")


def ic_gelee_slime():
    img = canvas_i()
    R = rng(7809)
    jar = chaikin([(140, 150), (372, 150), (390, 200), (392, 420), (360, 470), (152, 470), (120, 420), (122, 200)], 2)
    vol(img, lambda d: d.polygon(jar, fill=255), (190, 220, 220), depth=20, gloss=1.2, alpha=0.6)
    jelly = chaikin([(132, 250), (200, 230), (260, 258), (320, 232), (384, 250), (386, 420), (356, 462), (156, 462), (126, 420)], 2)
    m = vol(img, lambda d: d.polygon(jelly, fill=255), (80, 196, 60), depth=26, gloss=0.9)
    glow_i(img, 256, 360, 100, (150, 255, 120), 0.35, inside=m)
    d = ImageDraw.Draw(img)
    for _ in range(12):
        x, y = R.uniform(160, 350), R.uniform(280, 440)
        r = R.uniform(6, 15)
        d.ellipse((x - r, y - r, x + r, y + r), outline=(200, 255, 180, 210), width=3)
        d.ellipse((x - r * 0.5, y - r * 0.6, x - r * 0.1, y - r * 0.2), fill=(255, 255, 255, 220))
    vol(img, lambda d: d.polygon([(150, 120), (362, 120), (370, 160), (142, 160)], fill=255), (166, 120, 72), depth=8, gloss=0.3, tex=T(R))
    vol(img, lambda d: d.rectangle((170, 70, 342, 124), fill=255), (190, 150, 96), depth=10, gloss=0.3, tex=T(R))
    d = ImageDraw.Draw(img)
    d.line([(140, 140), (372, 140)], fill=(200, 180, 140, 255), width=6)
    vol(img, lambda d: d.polygon([(150, 180), (180, 168), (180, 440), (150, 420)], fill=255), (255, 255, 255), depth=6, gloss=0.5, alpha=0.5)
    ico_save(img, "gelee_slime")


def ic_croc_gobelin():
    img = canvas_i()
    R = rng(7810)
    ctr = bez((250, 120), (290, 220), (300, 320), (230, 470), 30)
    poly = tube(ctr, 120, 10)
    m = vol(img, lambda d: d.polygon(poly, fill=255), (222, 206, 150), depth=20, gloss=0.6, tex=T(R, (16, 32, 64), 0.18))
    d = ImageDraw.Draw(img)
    for k in range(4):
        y = 160 + k * 20
        d.arc((190, y - 30, 320, y + 30), 20, 160, fill=(170, 150, 100, 255), width=3)
    vol(img, lambda d: d.polygon(tube(bez((206, 70), (230, 130), (296, 130), (310, 70), 16), 70, 70), fill=255), (130, 92, 60), depth=8, gloss=0.3)
    d = ImageDraw.Draw(img)
    d.ellipse((240, 70, 276, 106), fill=(0, 0, 0, 0))
    cord = bez((140, 60), (200, 10), (320, 10), (380, 60), 30)
    d.line(cord, fill=(110, 76, 44, 255), width=12, joint="curve")
    d.line([(c[0] - 1, c[1] - 3) for c in cord], fill=(160, 120, 80, 255), width=4)
    vol(img, lambda d_: d_.ellipse((120, 50, 160, 90), fill=255), (176, 60, 40), depth=6, gloss=0.8)
    vol(img, lambda d_: d_.ellipse((360, 50, 400, 90), fill=255), (60, 120, 160), depth=6, gloss=0.8)
    vol(img, lambda d_: d_.ellipse((236, 72, 276, 112), fill=255), (110, 76, 44), depth=6, gloss=0.4)
    ico_save(img, "croc_gobelin")


def ic_cle_cuivre():
    img = canvas_i()
    R = rng(7811)
    a = math.radians(40)
    ca, sa = math.cos(a), math.sin(a)

    def P(u, v):
        return (140 + u * ca - v * sa, 130 + u * sa + v * ca)
    tex = T(R, (16, 32, 64, 128), 0.28)
    copper = (192, 108, 58)
    vol(img, lambda d: d.polygon([P(70, -16), P(380, -16), P(380, 16), P(70, 16)], fill=255), copper, depth=8, gloss=0.8, tex=tex)
    vol(img, lambda d: d.polygon([P(290, 14), P(290, 84), P(316, 84), P(316, 56), P(340, 56), P(340, 92), P(372, 92), P(372, 14)], fill=255), copper, depth=8, gloss=0.8, tex=tex)
    bow = [P(math.cos(t) * 90 * (1 + 0.16 * math.cos(4 * t)), math.sin(t) * 90 * (1 + 0.16 * math.cos(4 * t))) for t in np.linspace(0, TAU, 64, endpoint=False)]
    vol(img, lambda d: d.polygon(bow, fill=255), (204, 118, 64), depth=18, gloss=0.9, tex=tex)
    hole = [P(math.cos(t) * 44 * (1 + 0.2 * math.cos(4 * t)), math.sin(t) * 44 * (1 + 0.2 * math.cos(4 * t))) for t in np.linspace(0, TAU, 48, endpoint=False)]
    d = ImageDraw.Draw(img)
    hm = Image.new("L", (IS, IS), 0)
    ImageDraw.Draw(hm).polygon(hole, fill=255)
    img.putalpha(Image.fromarray(np.minimum(np.asarray(img.split()[3]), 255 - np.asarray(hm)).astype(np.uint8)))
    d = ImageDraw.Draw(img)
    d.line(hole + [hole[0]], fill=(120, 60, 30, 255), width=5)
    for u in (110, 140, 230):
        d.line([P(u, -16), P(u, 16)], fill=(120, 64, 32, 255), width=6)
    for _ in range(26):
        u, v = R.uniform(-90, 380), R.uniform(-60, 60)
        x, y = P(u, v)
        if img.getpixel((int(x), int(y)))[3] > 200:
            r = R.uniform(4, 10)
            d.ellipse((x - r, y - r, x + r, y + r), fill=(80, 170, 140, 170))
    ico_save(img, "cle_cuivre")


def ic_cidre_montjoie():
    img = canvas_i()
    R = rng(7812)
    bottle = chaikin([(212, 60), (300, 60), (300, 150), (360, 220), (370, 470), (142, 470), (152, 220), (212, 150)], 2)
    m = vol(img, lambda d: d.polygon(bottle, fill=255), (80, 120, 70), depth=22, gloss=1.2)
    liquid = chaikin([(156, 250), (356, 250), (366, 466), (146, 466)], 1)
    lm = vol(img, lambda d: d.polygon(liquid, fill=255), (214, 150, 50), depth=18, gloss=0.8, alpha=0.75)
    glow_i(img, 256, 380, 90, (255, 200, 90), 0.3, inside=lm)
    vol(img, lambda d: d.rectangle((216, 36, 296, 84), fill=255), (176, 130, 80), depth=8, gloss=0.3, tex=T(R))
    d = ImageDraw.Draw(img)
    d.line([(208, 90), (304, 90)], fill=(220, 200, 160, 255), width=8)
    vol(img, lambda d_: d_.rectangle((168, 290, 344, 410), fill=255), (232, 214, 170), depth=6, gloss=0.2, tex=T(R))
    vol(img, lambda d_: d_.ellipse((222, 312, 290, 380), fill=255), (200, 50, 40), depth=10, gloss=0.8)
    d = ImageDraw.Draw(img)
    d.line([(256, 314), (262, 296)], fill=(90, 60, 30, 255), width=5)
    d.polygon(leaf_poly(276, 298, 30, 14, -0.4), fill=(70, 140, 60, 255))
    vol(img, lambda d_: d_.polygon([(176, 160), (196, 150), (186, 440), (166, 430)], fill=255), (255, 255, 255), depth=6, gloss=0.4, alpha=0.4)
    ico_save(img, "cidre_montjoie")


def ic_tourte_montjoie():
    img = canvas_i()
    R = rng(7813)
    tex = T(R, (16, 32, 64, 128), 0.25)
    vol(img, lambda d: d.ellipse((50, 210, 462, 450), fill=255), (130, 110, 100), depth=10, gloss=0.4)
    vol(img, lambda d: d.ellipse((66, 170, 446, 410), fill=255), (206, 140, 62), depth=30, gloss=0.6, tex=tex)
    d = ImageDraw.Draw(img)
    for k in range(28):
        a = k / 28 * TAU
        x, y = 256 + math.cos(a) * 176, 290 + math.sin(a) * 108
        d.ellipse((x - 16, y - 12, x + 16, y + 12), fill=(222, 160, 76, 255), outline=(170, 100, 40, 255), width=3)
    vol(img, lambda d_: d_.ellipse((110, 196, 402, 384), fill=255), (220, 156, 70), depth=26, gloss=0.7, tex=tex)
    d = ImageDraw.Draw(img)
    for k in range(3):
        a = -math.pi / 2 + k * TAU / 3 + 0.4
        lp = leaf_poly(256 + math.cos(a) * 52, 290 + math.sin(a) * 34, 80, 36, a, 0.4)
        d.polygon(lp, fill=(236, 176, 90, 255), outline=(170, 104, 40, 255))
        d.line([lp[0], lp[9]], fill=(170, 104, 40, 255), width=3)
    d.ellipse((240, 278, 272, 302), fill=(110, 50, 30, 255))
    for k in range(3):
        x = 220 + k * 34
        d.line([(x + math.sin(t * 6) * 8, 230 - t * 120) for t in np.linspace(0, 1, 14)], fill=(255, 255, 255, 170), width=6)
    ico_save(img, "tourte_montjoie")


def ic_pain_montjoie():
    img = canvas_i()
    R = rng(7814)
    tex = T(R, (16, 32, 64, 128), 0.3)
    vol(img, lambda d: d.ellipse((60, 140, 452, 440), fill=255), (180, 112, 52), depth=50, gloss=0.6, tex=tex)
    d = ImageDraw.Draw(img)
    for (p0, p1) in (((150, 230), (360, 360)), ((360, 230), (150, 360))):
        d.line([p0, p1], fill=(236, 200, 140, 255), width=18)
        d.line([(p0[0] + 4, p0[1] + 6), (p1[0] + 4, p1[1] + 6)], fill=(120, 70, 30, 255), width=6)
    sp = (R.random((IS, IS)) < 0.02).astype(np.float32)
    flour = gblur(sp, 1.0) * tn(R, IS, (4, 8, 16), 0.6)
    a = np.asarray(img, np.float32) / 255.0
    rgb = a[..., :3] + np.clip(flour * 6, 0, 0.5)[..., None] * (a[..., 3:] > 0.5)
    img.paste(Image.fromarray((np.dstack([np.clip(rgb, 0, 1), a[..., 3]]) * 255 + 0.5).astype(np.uint8), "RGBA"))
    ico_save(img, "pain_montjoie")


def ic_titre_propriete():
    img = canvas_i()
    R = rng(7815)
    tex = T(R, (8, 16, 32, 64), 0.22)
    vol(img, lambda d: d.rectangle((96, 90, 416, 420), fill=255), (232, 214, 172), depth=12, gloss=0.2, tex=tex)
    vol(img, lambda d: d.rounded_rectangle((70, 60, 442, 112), 26, fill=255), (214, 192, 146), depth=14, gloss=0.4, tex=tex)
    vol(img, lambda d: d.rounded_rectangle((70, 400, 442, 452), 26, fill=255), (214, 192, 146), depth=14, gloss=0.4, tex=tex)
    d = ImageDraw.Draw(img)
    ink = (90, 64, 44, 255)
    d.text((256, 146), "TITRE", font=font(38, bold=True), fill=ink, anchor="mm")
    # la chaumière esquissée
    d.polygon([(190, 280), (256, 210), (322, 280)], fill=(196, 160, 90, 255), outline=ink)
    d.rectangle((200, 280, 312, 350), fill=(240, 230, 204, 255), outline=ink, width=4)
    d.rectangle((244, 306, 270, 350), fill=(140, 90, 50, 255), outline=ink, width=3)
    for x in (214, 288):
        d.rectangle((x - 2, 296, x + 16, 314), fill=(150, 190, 220, 255), outline=ink, width=2)
    for k in range(3):
        d.ellipse((180 + k * 24, 270 + (k % 2) * 6, 196 + k * 24, 286 + (k % 2) * 6), fill=(190, 140, 210, 255))
    d.line([(130, 380), (300, 380)], fill=ink, width=4)
    # ruban et sceau
    vol(img, lambda d_: d_.polygon([(330, 340), (360, 470), (382, 440), (404, 474), (396, 340)], fill=255), (170, 40, 36), depth=6, gloss=0.4)
    seal = [(364 + math.cos(t) * 46 * (1 + 0.06 * math.sin(7 * t)), 350 + math.sin(t) * 46 * (1 + 0.06 * math.sin(7 * t))) for t in np.linspace(0, TAU, 40, endpoint=False)]
    vol(img, lambda d_: d_.polygon(seal, fill=255), (190, 36, 30), depth=10, gloss=0.9)
    d = ImageDraw.Draw(img)
    d.ellipse((338, 324, 390, 376), outline=(130, 20, 18, 255), width=4)
    d.text((364, 351), "P", font=font(34, bold=True), fill=(130, 20, 18, 255), anchor="mm")
    ico_save(img, "titre_propriete")


def ic_jus_pomme():
    img = canvas_i()
    R = rng(7816)
    glass = [(150, 120), (362, 120), (340, 460), (172, 460)]
    vol(img, lambda d: d.polygon(glass, fill=255), (210, 230, 230), depth=16, gloss=1.2, alpha=0.55)
    juice = [(160, 200), (352, 200), (338, 452), (174, 452)]
    lm = vol(img, lambda d: d.polygon(juice, fill=255), (232, 186, 70), depth=16, gloss=0.8, alpha=0.85)
    glow_i(img, 256, 330, 90, (255, 230, 140), 0.3, inside=lm)
    vol(img, lambda d: d.ellipse((160, 188, 352, 214), fill=255), (246, 214, 120), depth=4, gloss=0.6)
    vol(img, lambda d: d.polygon([(176, 140), (196, 140), (196, 440), (182, 440)], fill=255), (255, 255, 255), depth=4, gloss=0.4, alpha=0.5)
    # la pomme
    vol(img, lambda d: d.ellipse((300, 300, 470, 470), fill=255), (200, 46, 40), depth=26, gloss=1.0, tex=T(R, (16, 32, 64), 0.18))
    d = ImageDraw.Draw(img)
    d.line([(386, 310), (394, 270)], fill=(90, 60, 30, 255), width=8)
    vol(img, lambda d_: d_.polygon(leaf_poly(420, 276, 60, 28, -0.4), fill=255), (70, 150, 60), depth=6, gloss=0.4)
    ico_save(img, "jus_pomme")


def ic_banniere_gobelin():
    img = canvas_i()
    R = rng(7817)
    tex = T(R, (8, 16, 32, 64), 0.3)
    pole = tube([(150, 480), (156, 360), (146, 240), (152, 120), (146, 40)], 22, 18)
    vol(img, lambda d: d.polygon(pole, fill=255), (120, 84, 50), depth=8, gloss=0.3, tex=tex)
    cloth = [(160, 70), (420, 90), (404, 150), (430, 200), (398, 250), (420, 300), (390, 330), (340, 318), (300, 350), (250, 320), (200, 344), (160, 320)]
    m = vol(img, lambda d: d.polygon(cloth, fill=255), (150, 60, 40), depth=12, gloss=0.2, tex=tex)
    d = ImageDraw.Draw(img)
    # symbole grossier peint : une dent et deux traits
    d.polygon([(250, 130), (330, 130), (310, 200), (290, 270), (270, 200)], fill=(236, 210, 130, 255), outline=(60, 30, 20, 255))
    d.line([(214, 120), (214, 280)], fill=(236, 210, 130, 255), width=12)
    d.line([(366, 128), (366, 284)], fill=(236, 210, 130, 255), width=12)
    for _ in range(8):
        x, y = R.uniform(180, 400), R.uniform(100, 300)
        r = R.uniform(4, 9)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(100, 36, 26, 255))
    vol(img, lambda d: d.rectangle((138, 60, 172, 92), fill=255), (90, 70, 50), depth=4, gloss=0.2)
    for k, (x, c) in enumerate(((140, (230, 230, 220)), (160, (60, 50, 50)))):
        fp = leaf_poly(x - 30, 120 + k * 20, 70, 20, 1.9 + k * 0.3, 0.2)
        vol(img, lambda d_, fp=fp: d_.polygon(fp, fill=255), c, depth=4, gloss=0.3)
    ico_save(img, "banniere_gobelin")


def icones():
    """Les objets de l'Île de Montjoie (128 px, ombrés et cernés comme les autres icônes)."""
    for n in ICON_NAMES_V71:
        globals()["ic_" + n]()


# =================================================================== lancement

GROUPS = {"sols": sols, "bati": bati, "donjon": donjon, "panneaux": panneaux, "enseignes": enseignes, "affiches": affiches, "icones": icones}


def images():
    """Chaque image qu'on peut refaire seule, par son nom de fichier (sans .png)."""
    one = {}
    for fn in (prairie, champ, chemin, sous_bois, roche_crocs, sable_lac, paves, dalles,
               enduit, pierre_rempart, moellons, tuiles, bois_planches, chaume, colombage_motif,
               pierre_donjon, dalles_donjon, mousse_donjon, gelee,
               fenetre_plomb, fenetre_plomb_nuit, vitrail_aube, banniere_montjoie, blason_guilde, tableau_liege):
        one[fn.__name__] = fn
    for k in ENSEIGNES:
        one["enseigne_" + k] = (lambda k=k: enseigne(k))
    for n in AFFICHES:
        one["affiche_quete_%d" % n] = (lambda n=n: affiche_quete(n))
    one["affiche_recherche"] = affiche_recherche
    for k in ICON_NAMES_V71:
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
