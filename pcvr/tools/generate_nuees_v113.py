"""V113 : textures de la Cité des Nuées, l'île flottante de Hautefond (futuriste et lumineuse : béton
blanc, verre clair, bois blond, panneaux solaires, jardins).

nuees/ — surfaces raccordables, chacune avec sa carte de relief <nom>_n.png :
          dalle_claire (+_n) : grandes dalles de pierre claire (60 x 120 cm, granit gris perle et
                               calcaire crème mêlés), joints fins, un poli léger (le sol de la ville ;
                               une tuile ≈ 6 m) ;
          beton_blanc (+_n)  : béton architectonique blanc, banches de 2,4 m x 1,2 m, trous de
                               tiges, très légères coulures (une tuile ≈ 2,4 m) ;
          bois_blond (+_n)   : platelage de bois blond (lames de 14 cm, vis inox, fil du bois) ;
          composite (+_n)    : panneau de façade blanc satiné, joints creux (les nacelles, les capsules) ;
          haie (+_n)         : une haie taillée (petites feuilles serrées) pour les jardinières.
        — non raccordables / sans relief :
          facade (1024 x 1024) : mur-rideau (4 travées de 1,5 m, 2 étages de 3,6 m) : verre clair un peu
                                 bleuté qui laisse voir l'intérieur (plafonds, rideaux, plantes) ;
          facade_lum            : la carte des fenêtres allumées le soir (même découpage) ;
          solaire (512 x 512)   : un panneau solaire (6 x 10 cellules, cadre d'aluminium) ;
          nuage (512 x 256, RGBA) : un flocon de nuage doux (les nuages sous l'île) ;
          enseigne_gare, _cumulus, _atelier, _serres, _institut, _port, _conseil, _residences,
          _ligne (512 x 256) : enseignes modernes (aluminium brossé, pictogramme, lettres Inter).

Tout est dessiné ici, procéduralement (libre de droits, aucune image tierce), avec les outils des
générateurs V69, V70 et V71. Déterministe.
Lancement depuis la racine du dépôt :
    python3 pcvr/tools/generate_nuees_v113.py [surfaces | facade | solaire | nuage | enseignes | <nom>]
"""
import math
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # pas de __pycache__ dans pcvr/tools

import numpy as np  # noqa: E402
from PIL import Image, ImageDraw, ImageFilter, ImageFont  # noqa: E402

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_montjoie_v71 as gm  # noqa: E402
from generate_soleils_v69 import (tn, smooth, mix, C, bake, per_id, masonry, speck, gblur)  # noqa: E402
from generate_braise_v70 import (grain, hshadow)  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "nuees"
TAU = math.tau
gm.OUT = OUT
FONT = "/usr/share/fonts/opentype/inter/"


def rng(seed):
    return np.random.default_rng(seed)


def font(size, weight="Medium"):
    for name in (f"Inter-{weight}.otf", "Inter-Regular.otf", "InterDisplay-Medium.otf"):
        p = Path(FONT) / name
        if p.is_file():
            return ImageFont.truetype(str(p), size)
    return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", size)


# =================================================================== surfaces

def dalle_claire():
    S = 1024
    R = rng(11301)
    rows = [102, 102, 102, 102, 102, 102, 102, 102, 102, 106]
    bid, e, u, v = masonry(R, S, rows, 204, 206, rr=1.5)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    gr = grain(R, S, 0.5)
    tone = per_id(bid, R, 0.94, 1.05)
    kind = per_id(bid, R, 0.0, 1.0)
    # deux pierres mêlées : un granit gris perle moucheté, un calcaire crème très fin
    granit = C(0.76, 0.74, 0.7) * (0.9 + 0.2 * gr[..., None])
    mica = speck(R, S, 0.02, 0.5)
    granit = mix(granit, C(0.42, 0.42, 0.43), np.clip(mica * 2.2, 0, 1) * 0.5)
    granit = mix(granit, C(0.88, 0.87, 0.85), np.clip(speck(R, S, 0.012, 0.5) * 2.0, 0, 1) * 0.4)
    calc = C(0.85, 0.8, 0.7) * (0.95 + 0.08 * fine[..., None]) * (0.96 + 0.06 * mot[..., None])
    calc = mix(calc, C(0.74, 0.7, 0.62), np.clip(speck(R, S, 0.002, 1.2) * 1.5, 0, 1) * 0.3)
    stone = np.where((kind < 0.55)[..., None], granit, calc) * tone[..., None]
    stone = stone * (0.94 + 0.1 * mot[..., None])
    # un peu de patine : des traces de pas plus mates, des taches d'eau qui ont séché
    wash = smooth(0.6, 0.85, tn(R, S, (8, 16, 32, 64), 0.6))
    stone = mix(stone, stone * C(0.95, 0.95, 0.95), wash * 0.5)
    jm = 1 - smooth(0.8, 2.2, e)
    joint = C(0.6, 0.58, 0.54) * (0.85 + 0.3 * gr[..., None])
    col = mix(stone, joint, jm)
    h = smooth(0.0, 4.0, e) * 0.4 + fine * 0.02 + mot * 0.02 - jm * 0.12 + per_id(bid, R, -0.015, 0.015)
    col = bake(col, h, 2.5, k=0.18, ao=0.2, ao_r=3)
    gm.save_surface("dalle_claire", col, h, 2.5)


def beton_blanc():
    S = 1024
    R = rng(11302)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    gr = grain(R, S, 0.7)
    # deux banches de 1,2 m l'une sur l'autre (la tuile fait 2,4 m de côté)
    ph = S // 2
    panel = (yy // ph).astype(np.int32)
    tone = np.where(panel == 0, 1.0, 0.975)[..., None]
    base = C(0.86, 0.86, 0.84) * tone * (0.95 + 0.07 * mot[..., None]) * (0.96 + 0.06 * fine[..., None]) * (0.97 + 0.04 * gr[..., None])
    # le bullage du béton : de petites alvéoles
    pores = speck(R, S, 0.0035, 0.6)
    base = base * (1 - 0.25 * np.clip(pores * 2.0, 0, 1)[..., None])
    # les joints de banche (fins, un léger relief) et les trous des tiges (bouchés, un peu plus gris)
    dy = np.minimum(yy % ph, ph - yy % ph)
    dx = np.minimum(xx % S, S - xx % S)
    joint = (1 - smooth(1.0, 3.0, dy)) + (1 - smooth(1.0, 3.0, dx))
    joint = np.clip(joint, 0, 1)
    holes = np.zeros((S, S), np.float32)
    for ix in (0.2, 0.8):
        for iy in (0.25, 0.75):
            cx, cy = ix * S, iy * S
            d = np.hypot(xx - cx, yy - cy)
            holes = np.maximum(holes, 1 - smooth(9.0, 12.0, d))
    col = mix(base, base * C(0.86, 0.86, 0.86), joint * 0.6)
    col = mix(col, C(0.7, 0.7, 0.69), holes * 0.7)
    # de très légères coulures sous les joints (la pluie, rare là-haut)
    stk = tn(R, S, (32, 64, 128, 256), 0.65, oy=(2, 4, 8, 16))
    streak = np.exp(-(yy % ph) / (30 + 80 * stk)) * smooth(0.55, 0.8, tn(R, S, (16, 32, 64), 0.6, oy=(2, 4, 8)))
    col = mix(col, col * C(0.88, 0.88, 0.87), np.clip(streak, 0, 1) * 0.3)
    h = mot * 0.03 + fine * 0.02 - pores * 0.1 - joint * 0.12 - holes * 0.18
    col = bake(col, h, 2.0, k=0.15, ao=0.15, ao_r=3)
    gm.save_surface("beton_blanc", col, h, 2.5)


def bois_blond():
    S = 1024
    R = rng(11303)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    n_boards = 8
    bw = S / n_boards
    bi = (yy // bw).astype(np.int32)
    # chaque lame : une longueur, un décalage, une teinte
    off = R.uniform(0, S, n_boards)
    length = R.uniform(0.45, 0.9, n_boards) * S
    seg = ((xx + off[bi]) // length[bi]).astype(np.int32)
    lid = bi * 100 + seg
    tone = per_id(lid, R, 0.88, 1.08)
    hue = per_id(lid, R, 0.0, 1.0)
    vb = (yy % bw) / bw
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    fil = tn(R, S, (2, 4, 8, 16), 0.6, oy=(16, 32, 64, 128))
    grain_l = np.sin((yy + fil * 60.0) / (2.0 + 2.0 * per_id(lid, R, 0, 1)) * TAU) * 0.5 + 0.5
    wood = mix(C(0.74, 0.6, 0.44), C(0.82, 0.68, 0.5), hue) * tone[..., None]
    wood = wood * (0.9 + 0.12 * grain_l[..., None]) * (0.95 + 0.08 * fine[..., None])
    # les nœuds, rares
    knots = speck(R, S, 0.000006, 3.0)
    wood = mix(wood, C(0.56, 0.42, 0.28), np.clip(knots * 6.0, 0, 1) * 0.5)
    gap = 1 - smooth(1.0, 3.5, np.minimum(yy % bw, bw - yy % bw))
    ends = 1 - smooth(0.5, 2.0, np.minimum((xx + off[bi]) % length[bi], length[bi] - (xx + off[bi]) % length[bi]))
    gap = np.maximum(gap, ends)
    # les vis inox, deux par lame, tous les 60 cm
    sx = (xx + off[bi]) % (S / 4.0)
    screw = (1 - smooth(2.5, 4.0, np.hypot(sx - 30.0, np.minimum(np.abs(vb * bw - bw * 0.22), np.abs(vb * bw - bw * 0.78)))))
    col = mix(wood, C(0.22, 0.18, 0.14), gap * 0.9)
    col = mix(col, C(0.7, 0.71, 0.72), screw * 0.9)
    h = 0.5 + grain_l * 0.04 + fine * 0.02 - gap * 0.5 + screw * 0.05
    sh = hshadow(h, 4.0, 8, 0.8)
    col = col * (1 - 0.2 * sh[..., None])
    col = bake(col, h, 3.0, k=0.2, ao=0.25, ao_r=3)
    gm.save_surface("bois_blond", col, h, 3.0)


def composite():
    S = 512
    R = rng(11304)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    fine = tn(R, S, (64, 128, 256, 512), 0.75)
    mot = tn(R, S, (4, 8, 16), 0.6)
    col = C(0.92, 0.93, 0.93) * (0.97 + 0.04 * fine[..., None]) * (0.98 + 0.03 * mot[..., None])
    d = np.minimum(np.minimum(yy % 256, 256 - yy % 256), np.minimum(xx % 512, 512 - xx % 512))
    jm = 1 - smooth(1.5, 3.5, d)
    col = mix(col, C(0.55, 0.57, 0.58), jm * 0.8)
    h = 0.5 - jm * 0.4 + fine * 0.01
    col = bake(col, h, 2.0, k=0.15, ao=0.2, ao_r=2)
    gm.save_surface("composite", col, h, 2.0)


def haie():
    """Une haie taillée (buis, troène) : des milliers de petites feuilles serrées, des ombres entre."""
    S = 512
    R = rng(11305)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    h = np.zeros((S, S), np.float32)
    col = np.zeros((S, S, 3), np.float32)
    col[:] = C(0.08, 0.14, 0.06)
    hue = tn(R, S, (4, 8, 16), 0.6)
    for k in range(9000):
        cx, cy = R.uniform(0, S), R.uniform(0, S)
        a = R.uniform(0, math.pi)
        L, Wd = R.uniform(7, 12), R.uniform(3.2, 5.0)
        x0, x1 = int(cx - L - 1), int(cx + L + 2)
        y0, y1 = int(cy - L - 1), int(cy + L + 2)
        ys = np.arange(y0, y1) % S
        xs = np.arange(x0, x1) % S
        gy, gx = np.meshgrid(np.arange(y0, y1) - cy, np.arange(x0, x1) - cx, indexing="ij")
        u = gx * math.cos(a) + gy * math.sin(a)
        v = -gx * math.sin(a) + gy * math.cos(a)
        m = (u / L) ** 2 + (v / Wd) ** 2 < 1.0
        z = R.uniform(0.2, 1.0)
        sub_h = h[np.ix_(ys, xs)]
        put = m & (z > sub_h)
        shade = np.clip(1.0 - (u / L) * 0.25 + (v / Wd) * 0.1, 0.6, 1.2)
        g = R.uniform(0.0, 1.0)
        base = mix(C(0.16, 0.3, 0.1), C(0.3, 0.46, 0.16), g) * (0.75 + 0.5 * z)
        cur = col[np.ix_(ys, xs)]
        cur[put] = base * shade[put][..., None]
        col[np.ix_(ys, xs)] = cur
        sub_h[put] = z
        h[np.ix_(ys, xs)] = sub_h
    col = col * (0.85 + 0.3 * hue[..., None])
    col = bake(col, h, 3.0, k=0.3, ao=0.4, ao_r=4)
    gm.save_surface("haie", col, h, 3.0)


SURFACES = {"haie": haie, "dalle_claire": dalle_claire, "beton_blanc": beton_blanc, "bois_blond": bois_blond, "composite": composite}


# =================================================================== la façade vitrée

def facade():
    """Mur-rideau : 4 travées de 1,5 m, 2 étages de 3,6 m (1024 px = 6 m de large, 7,2 m de haut)."""
    S = 1024
    R = rng(11310)
    bays, floors = 4, 2
    bw, fh = S / bays, S / floors
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    col = np.zeros((S, S, 3), np.float32)
    lum = np.zeros((S, S, 3), np.float32)
    sky = mix(C(0.62, 0.74, 0.84), C(0.86, 0.9, 0.94), (yy / S)[..., None] * 0.6)
    for f in range(floors):
        for b in range(bays):
            x0, y0 = int(b * bw), int(f * fh)
            x1, y1 = int((b + 1) * bw), int((f + 1) * fh)
            sub = (slice(y0, y1), slice(x0, x1))
            v = (yy[sub] - y0) / fh
            u = (xx[sub] - x0) / bw
            room = R.choice(["bureau", "salon", "plantes", "rideau", "vide"], p=[0.3, 0.25, 0.2, 0.15, 0.1])
            # l'intérieur, vu à travers le verre : un plafond clair, un fond, un sol, des formes
            inside = mix(C(0.46, 0.48, 0.5), C(0.66, 0.66, 0.64), (1 - v)[..., None] * 0.5)
            ceil = v < 0.12
            inside = np.where(ceil[..., None], C(0.8, 0.8, 0.78), inside)
            floor_band = v > 0.86
            inside = np.where(floor_band[..., None], C(0.36, 0.33, 0.3), inside)
            if room == "plantes":
                blobs = np.zeros_like(u)
                for _ in range(4):
                    cx, cy, rr = R.uniform(0.1, 0.9), R.uniform(0.55, 0.85), R.uniform(0.08, 0.16)
                    blobs = np.maximum(blobs, 1 - smooth(rr * 0.6, rr, np.hypot(u - cx, (v - cy) * 1.6)))
                inside = mix(inside, C(0.2, 0.34, 0.18), blobs * 0.9)
            elif room == "rideau":
                folds = 0.85 + 0.15 * np.sin(u * 40.0)
                inside = mix(inside, C(0.9, 0.88, 0.82) * folds[..., None], (v > 0.12) * 0.9)
            elif room == "bureau":
                desk = (v > 0.62) & (v < 0.66) & (u > 0.15) & (u < 0.85)
                inside = np.where(desk[..., None], C(0.82, 0.8, 0.76), inside)
                screen = (v > 0.5) & (v < 0.62) & (np.abs(u - 0.5) < 0.12)
                inside = np.where(screen[..., None], C(0.12, 0.13, 0.15), inside)
            elif room == "salon":
                sofa = (v > 0.66) & (v < 0.82) & (u > 0.2) & (u < 0.8)
                inside = np.where(sofa[..., None], C(0.62, 0.56, 0.46), inside)
                lamp = 1 - smooth(0.02, 0.05, np.hypot(u - 0.82, v - 0.45))
                inside = mix(inside, C(1.0, 0.9, 0.7), lamp)
            # le reflet du ciel sur le verre (plus fort en haut, et en biais)
            refl = np.clip(0.35 + 0.3 * (1 - v) + 0.15 * np.sin((u + v) * 3.0 + R.uniform(0, 6)), 0, 1)
            glass = mix(inside * C(0.8, 0.9, 0.94), sky[sub], refl[..., None] * 0.78)
            col[sub] = glass
            # le soir : les pièces allumées (pas toutes)
            if room != "vide" and R.random() < 0.7:
                warm = C(1.0, 0.82, 0.58) * R.uniform(0.6, 1.0)
                glow = (1 - floor_band) * (0.6 + 0.4 * (1 - v))
                if room == "rideau":
                    glow = glow * 1.1
                lum[sub] = warm * glow[..., None] * (1 - ceil[..., None] * 0.3)
    # les montants et les traverses (aluminium clair), le nez de dalle (béton blanc)
    du = np.minimum(xx % bw, bw - xx % bw)
    dv = np.minimum(yy % fh, fh - yy % fh)
    mull = 1 - smooth(5.0, 7.0, du)
    slab = 1 - smooth(18.0, 22.0, dv)
    trans = 1 - smooth(3.0, 4.5, np.abs((yy % fh) - fh * 0.18))
    frame = np.clip(mull + trans, 0, 1)
    col = mix(col, C(0.78, 0.8, 0.82), frame)
    col = mix(col, C(0.9, 0.9, 0.88) * (0.95 + 0.05 * tn(R, S, (16, 32, 64), 0.6)[..., None]), slab)
    lum = lum * (1 - frame[..., None]) * (1 - slab[..., None])
    gm.save_rgb(col, "facade.png")
    gm.save_rgb(lum, "facade_lum.png")


def solaire():
    S = 512
    R = rng(11311)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    nx, ny = 6, 10
    m = 16.0
    cw, ch = (S - 2 * m) / nx, (S - 2 * m) / ny
    cu = (xx - m) % cw
    cv = (yy - m) % ch
    inside = (xx > m) & (xx < S - m) & (yy > m) & (yy < S - m)
    gap = (1 - smooth(1.0, 2.5, np.minimum(cu, cw - cu))) + (1 - smooth(1.0, 2.5, np.minimum(cv, ch - cv)))
    gap = np.clip(gap, 0, 1)
    cell = C(0.08, 0.12, 0.24) * (0.9 + 0.15 * tn(R, S, (32, 64, 128), 0.6)[..., None])
    # les fins doigts d'argent et les deux barres de collecte
    fingers = (1 - smooth(0.3, 0.9, np.abs((cv % 6.0) - 3.0))) * 0.25
    bus = (1 - smooth(1.0, 2.0, np.minimum(np.abs(cu - cw * 0.33), np.abs(cu - cw * 0.66))))
    col = mix(cell, C(0.55, 0.58, 0.62), np.clip(fingers + bus * 0.8, 0, 1))
    col = mix(col, C(0.86, 0.88, 0.9), gap * 0.85)
    sheen = smooth(0.0, 1.0, (xx + yy) / (2 * S))
    col = col * (0.9 + 0.25 * sheen[..., None])
    col = np.where(inside[..., None], col, C(0.72, 0.74, 0.76) * (0.95 + 0.05 * grain(R, S, 0.6)[..., None]))
    gm.save_rgb(col, "solaire.png")


def nuage():
    W, H = 512, 256
    R = rng(11312)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    u = (xx - W / 2) / (W / 2)
    v = (yy - H * 0.62) / (H * 0.5)
    shape = np.zeros((H, W), np.float32)
    for k in range(16):
        cx = R.uniform(-0.62, 0.62)
        cy = R.uniform(-0.3, 0.05) - (0.42 - abs(cx) * 0.5)
        rr = R.uniform(0.3, 0.5) * (1.0 - abs(cx) * 0.55)
        d = np.hypot((u - cx) / 1.0, (v - cy) / 0.9)
        shape = np.maximum(shape, 1 - smooth(rr * 0.5, rr, d))
    flat = 1 - smooth(0.0, 0.25, v)  # un dessous plat, comme les vrais cumulus
    big = tn(R, 512, (4, 8, 16, 32, 64), 0.6)[:H, :W]
    a = np.clip(shape * flat * (0.75 + 0.5 * big) - 0.12, 0, 1)
    a = gblur(a, 2.0)
    a = np.clip(a * 1.3, 0, 1)
    # éclairé par dessus (blanc), plus gris en dessous
    shade = np.clip(0.75 + 0.35 * (-v) + 0.1 * (big - 0.5), 0.6, 1.0)
    col = np.dstack([shade * 0.98, shade * 0.99, shade * 1.0])
    # les bords se fondent : pas de bord dur dans la texture (raccord avec l'air)
    edge = smooth(0.0, 0.08, np.minimum(np.minimum(xx, W - 1 - xx) / W, np.minimum(yy, H - 1 - yy) / H))
    a = a * edge
    gm.save_rgba(np.dstack([col, a]), "nuage.png")


# =================================================================== les enseignes

def ic_capsule(d, cx, cy, s, c):
    d.rounded_rectangle([cx - 0.28 * s, cy - 0.5 * s, cx + 0.28 * s, cy + 0.5 * s], radius=0.18 * s, outline=c, width=int(0.07 * s))
    d.line([cx, cy - 0.85 * s, cx, cy - 0.5 * s], fill=c, width=int(0.06 * s))
    d.line([cx, cy + 0.5 * s, cx, cy + 0.85 * s], fill=c, width=int(0.06 * s))
    d.polygon([(cx, cy - 0.28 * s), (cx - 0.14 * s, cy - 0.06 * s), (cx + 0.14 * s, cy - 0.06 * s)], fill=c)
    d.polygon([(cx, cy + 0.3 * s), (cx - 0.14 * s, cy + 0.08 * s), (cx + 0.14 * s, cy + 0.08 * s)], fill=c)


def ic_tasse(d, cx, cy, s, c):
    w = int(0.07 * s)
    d.rounded_rectangle([cx - 0.42 * s, cy - 0.15 * s, cx + 0.22 * s, cy + 0.55 * s], radius=0.16 * s, outline=c, width=w)
    d.arc([cx + 0.05 * s, cy - 0.02 * s, cx + 0.48 * s, cy + 0.38 * s], -90, 90, fill=c, width=w)
    for k in (-0.2, 0.0):
        d.arc([cx + k * s - 0.12 * s, cy - 0.75 * s, cx + k * s + 0.12 * s, cy - 0.3 * s], 100, 260, fill=c, width=int(0.05 * s))
    # le nuage sur la tasse
    for (dx, dy, r) in ((-0.2, -0.15, 0.13), (-0.05, -0.22, 0.16), (0.1, -0.15, 0.12)):
        d.ellipse([cx + (dx - r) * s, cy + (dy - r) * s, cx + (dx + r) * s, cy + (dy + r) * s], fill=c)


def ic_engrenage(d, cx, cy, s, c):
    pts = []
    for k in range(32):
        a = k / 32 * TAU
        r = 0.5 if (k // 2) % 2 == 0 else 0.4
        pts.append((cx + math.cos(a) * r * s, cy + math.sin(a) * r * s))
    d.polygon(pts, outline=c, width=int(0.06 * s))
    d.ellipse([cx - 0.15 * s, cy - 0.15 * s, cx + 0.15 * s, cy + 0.15 * s], outline=c, width=int(0.06 * s))
    d.line([cx + 0.2 * s, cy + 0.55 * s, cx + 0.75 * s, cy - 0.35 * s], fill=c, width=int(0.07 * s))


def ic_feuille(d, cx, cy, s, c):
    d.arc([cx - 0.55 * s, cy - 0.6 * s, cx + 0.55 * s, cy + 0.6 * s], 200, 340, fill=c, width=int(0.07 * s))
    d.line([cx - 0.55 * s, cy + 0.0 * s, cx + 0.55 * s, cy + 0.0 * s], fill=c, width=int(0.05 * s))
    d.pieslice([cx - 0.35 * s, cy - 0.45 * s, cx + 0.35 * s, cy + 0.45 * s], 180, 360, outline=c, width=int(0.06 * s))
    d.line([cx, cy - 0.45 * s, cx, cy + 0.0 * s], fill=c, width=int(0.04 * s))
    d.line([cx, cy + 0.0 * s, cx, cy + 0.65 * s], fill=c, width=int(0.06 * s))


def ic_vent(d, cx, cy, s, c):
    w = int(0.07 * s)
    d.line([cx, cy - 0.1 * s, cx, cy + 0.8 * s], fill=c, width=w)
    for k in range(3):
        a = k / 3 * TAU - math.pi / 2
        d.line([cx, cy - 0.1 * s, cx + math.cos(a) * 0.6 * s, cy - 0.1 * s + math.sin(a) * 0.6 * s], fill=c, width=w)
    d.ellipse([cx - 0.09 * s, cy - 0.19 * s, cx + 0.09 * s, cy - 0.01 * s], fill=c)


def ic_dirigeable(d, cx, cy, s, c):
    d.ellipse([cx - 0.7 * s, cy - 0.38 * s, cx + 0.6 * s, cy + 0.18 * s], outline=c, width=int(0.07 * s))
    d.polygon([(cx + 0.55 * s, cy - 0.1 * s), (cx + 0.85 * s, cy - 0.35 * s), (cx + 0.85 * s, cy + 0.15 * s)], outline=c, width=int(0.05 * s))
    d.rounded_rectangle([cx - 0.2 * s, cy + 0.28 * s, cx + 0.15 * s, cy + 0.44 * s], radius=0.05 * s, outline=c, width=int(0.05 * s))
    d.line([cx - 0.15 * s, cy + 0.16 * s, cx - 0.15 * s, cy + 0.28 * s], fill=c, width=int(0.04 * s))
    d.line([cx + 0.1 * s, cy + 0.16 * s, cx + 0.1 * s, cy + 0.28 * s], fill=c, width=int(0.04 * s))


def ic_plume(d, cx, cy, s, c):
    pts_l = [(cx - 0.05 * s + math.sin(t * 2.6) * 0.32 * s * (1 - t), cy + 0.7 * s - t * 1.4 * s) for t in np.linspace(0, 1, 24)]
    pts_r = [(cx + 0.05 * s + math.sin(t * 2.6) * 0.32 * s * (1 - t) + 0.28 * s * math.sin(t * math.pi), cy + 0.7 * s - t * 1.4 * s) for t in np.linspace(0, 1, 24)]
    d.line(pts_l, fill=c, width=int(0.06 * s))
    d.line(pts_r, fill=c, width=int(0.06 * s))
    d.line([(cx - 0.05 * s, cy + 0.85 * s), (cx + 0.1 * s, cy - 0.6 * s)], fill=c, width=int(0.04 * s))


def ic_maison(d, cx, cy, s, c):
    w = int(0.07 * s)
    for k in range(3):
        y = cy + 0.5 * s - k * 0.34 * s
        x0 = cx - 0.6 * s + k * 0.12 * s
        x1 = cx + 0.6 * s - k * 0.12 * s
        d.rectangle([x0, y - 0.3 * s, x1, y], outline=c, width=w)
        d.line([x0 + 0.1 * s, y - 0.32 * s, x0 + 0.25 * s, y - 0.42 * s], fill=(110, 170, 110), width=int(0.08 * s))


ENSEIGNES = {
    "gare": ("Gare des Nuées", "Ligne des Nuées · Belvédère de Hautefond", ic_capsule),
    "cumulus": ("Café Cumulus", "Lait de nuage · Thé des sommets", ic_tasse),
    "atelier": ("Atelier des Inventeurs", "Mireille Volta · Ça marche presque", ic_engrenage),
    "serres": ("Serres d'Altitude", "Fruits, fleurs & papillons", ic_feuille),
    "institut": ("Institut des Vents", "Météorologie · Sustentateurs", ic_vent),
    "port": ("Port des Nuées", "Dirigeables · Planeurs", ic_dirigeable),
    "conseil": ("Maison du Conseil", "Cité des Nuées · Bon vent !", ic_plume),
    "residences": ("Résidences des Terrasses", "Jardins suspendus", ic_maison),
    "ligne": ("Ligne des Nuées", "Gare des Nuées · 130 m · Ça plane !", ic_capsule),
}


def enseigne(key):
    title, sub, icon = ENSEIGNES[key]
    W, H, K = 512, 256, 3
    R = rng(11320 + sum(map(ord, key)))
    img = Image.new("RGB", (W * K, H * K), (0, 0, 0))
    # l'aluminium brossé, un très léger dégradé, une bordure fine
    yy, xx = np.mgrid[0:H * K, 0:W * K].astype(np.float32)
    brush = tn(R, 1024, (4, 8, 16, 32), 0.6, oy=(64, 128, 256, 512))
    brush = np.asarray(Image.fromarray((brush * 255).astype(np.uint8)).resize((W * K, H * K), Image.BILINEAR), np.float32) / 255.0
    base = C(0.9, 0.91, 0.92) * (0.94 + 0.08 * brush[..., None]) * (1.02 - 0.06 * (yy / (H * K)))[..., None]
    img = Image.fromarray((np.clip(base, 0, 1) * 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    ink = (40, 70, 96)
    acc = (96, 150, 190)
    d.rounded_rectangle([6 * K, 6 * K, (W - 6) * K, (H - 6) * K], radius=14 * K, outline=(170, 176, 182), width=2 * K)
    # le pictogramme dans un cercle bleu ciel
    cx, cy, rr = 88 * K, H * K / 2, 62 * K
    d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=acc)
    icon(d, cx, cy, 72 * K, (250, 252, 255))
    # le nom, le sous-titre, un filet
    size1 = 44
    f1 = font(int(size1 * K), "SemiBold")
    while d.textlength(title, font=f1) > 314 * K and size1 > 20:
        size1 -= 2
        f1 = font(int(size1 * K), "SemiBold")
    size2 = 21
    f2 = font(int(size2 * K), "Regular")
    while d.textlength(sub, font=f2) > 314 * K and size2 > 12:
        size2 -= 1
        f2 = font(int(size2 * K), "Regular")
    d.text((172 * K, 74 * K), title, fill=ink, font=f1, anchor="lm")
    d.line([172 * K, 116 * K, 486 * K, 116 * K], fill=acc, width=3 * K)
    d.text((172 * K, 156 * K), sub, fill=(70, 88, 104), font=f2, anchor="lm")
    img = img.resize((W, H), Image.LANCZOS)
    gm.save_rgb(np.asarray(img, np.float32) / 255.0, "enseigne_" + key + ".png")


def enseignes():
    for k in ENSEIGNES:
        enseigne(k)


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else ""
    OUT.mkdir(parents=True, exist_ok=True)
    if arg in ("", "surfaces"):
        for f in SURFACES.values():
            f()
    if arg in ("", "facade"):
        facade()
    if arg in ("", "solaire"):
        solaire()
    if arg in ("", "nuage"):
        nuage()
    if arg in ("", "enseignes"):
        enseignes()
    if arg in SURFACES:
        SURFACES[arg]()
    if arg in ENSEIGNES:
        enseigne(arg)


if __name__ == "__main__":
    main()
