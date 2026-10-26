"""V76 : textures d'Astralys (l'île flottante des Lumens, des extraterrestres sages et lumineux venus de la
planète Ondelune il y a mille ans ; la cité de cristal et de lumière, la Flèche de Cristal, l'Agora des
Étoiles, le Spatioport), et les icônes des nouveaux objets de la V76.

astralys/ — surfaces raccordables, chacune avec sa carte de relief <nom>_n.png (« vert vers le bas »,
          comme toutes les normales du jeu) et, pour celles qui brillent, une carte d'émission
          <nom>_e.png (512 px, même placement UV, fond noir : seules les parties lumineuses).
          (« sols », 1024 px, une tuile couvre environ 4 m x 4 m ; relief en 512 px) :
          nacre (+_n, +_e)          : dalles de nacre irisée, joints d'argent lumineux, clous de cristal ;
          cristal_sol (+_n, +_e)    : dalles hexagonales de cristal translucide, cœurs lumineux ;
          mousse_astrale (+_n)      : mousse bleu-violet, sporanges lumineux (ÉMISSIVE telle quelle) ;
          roche_astrale (+_n, +_e)  : roche sombre facettée veinée de cristaux bleu-violet ;
          sable_stellaire (+_n, +_e): sable argenté pailleté (paillettes de couleur) ;
          herbe_lunaire (+_n, +_e)  : herbe argentée, petites fleurs-étoiles qui luisent.
          (« bâti », 1024 px, une tuile couvre environ 3 m x 3 m ; relief en 1024 px) :
          nacre_mur (+_n, +_e)      : panneaux nacrés encadrés d'argent, filets de lumière ;
          cristal_bleu, cristal_violet, cristal_rose (+_n, +_e) : cristal facetté, voiles et motifs
                                      internes (cercles lumens), inclusions ; l'émission = motifs ;
          metal_lumen (+_n, +_e)    : métal blanc perle brossé, plaques, rainures de lumière ;
          verre_holo (+_n)          : verre irisé (couches minces), micro-trame hexagonale ;
          lumiere_motif (+_n)       : motifs de lumière (circuits, cercles, glyphes) sur fond indigo
                                      presque noir (ÉMISSIF tel quel) ;
          coque_soucoupe (+_n, +_e) : métal de soucoupe (plaques courbes, rivets, hublots de feux).
          — panneaux (non raccordables, sans _n) :
          holo_1 … holo_6 (512 x 512, opaques sur fond noir : ÉMISSIFS tels quels, ou en mélange
                                      additif) : planète Ondelune, équations, carte stellaire, carte de
                                      l'archipel, plan de la Flèche, orbites du système d'Ondelune ;
          enseigne_<x> (512 x 256, verre sombre, lettrage lumineux : ÉMISSIVES telles quelles) :
                                      cafe, bazar, musee, academie, spatioport, observatoire, serre ;
          fresque_lumen_1 … 4 (1024 x 512) : fresques peintes sur la nacre (non émissives) ;
          feuille_lumineuse, petale_lumineux (512 x 512, RGBA, à découper par l'alpha : ÉMISSIFS).
items/    (« icones », 128 px, ombrées et cernées comme les autres) : voir ICON_NAMES_V76.

Tout est dessiné ici, procéduralement (libre de droits, aucune image tierce), avec les outils des
générateurs V69, V70 et V75. Polices : Inter / Inter Display (SIL OFL), Poppins (SIL OFL), Lora (SIL OFL).
Déterministe : chaque image a sa propre graine. Aucun fichier existant d'un autre générateur n'est
écrasé : le script n'écrit que les noms de ses listes (dossier astralys/ et icônes ICON_NAMES_V76).
Lancement depuis la racine du dépôt :
    python3 pcvr/tools/generate_astralys_v76.py [sols | bati | holos | enseignes | fresques | vegetation |
                                                 icones | <nom>]
(sans argument : tout ; <nom> : une seule image, par ex. « nacre » ou « holo_3 » ou « truffe »).
"""
import math
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # pas de __pycache__ dans pcvr/tools

import numpy as np  # noqa: E402
from PIL import Image, ImageDraw, ImageFilter  # noqa: E402

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_soleils_v69 import (tn, gblur, smooth, mix, C, grads, normal_img, bake, offs, to_img, from_img,  # noqa: E402
                                  per_id, worley, warp, masonry, chaikin, bez, ellp, tube, leaf_poly, blade_poly, down, vol)
from generate_braise_v70 import (grain, hshadow, scatter, domes, rock_poly, _veins, norm01,  # noqa: E402
                                 Paint, canvas_i, glow_i, IS)
from generate_boucan_v75 import (FONTS, ff, rell, star_pts, heart_pts, xform, union, shape, stroke, ptext, text_w,  # noqa: E402
                                 fit_size, sparkle, finish, up, stones_layer, crack_paths, INK, T, ipoly, iell, itext)

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "astralys"
ITEMS = ROOT / "www" / "assets" / "textures" / "items"
TAU = math.tau
STATS = {}

SOLS = ["nacre", "cristal_sol", "mousse_astrale", "roche_astrale", "sable_stellaire", "herbe_lunaire"]
BATI = ["nacre_mur", "cristal_bleu", "cristal_violet", "cristal_rose", "metal_lumen", "verre_holo", "lumiere_motif",
        "coque_soucoupe"]
HOLOS = ["holo_%d" % k for k in range(1, 7)]
ENSEIGNES_V76 = ["cafe", "bazar", "musee", "academie", "spatioport", "observatoire", "serre"]
FRESQUES = ["fresque_lumen_%d" % k for k in range(1, 5)]
VEGETATION = ["feuille_lumineuse", "petale_lumineux"]
ICON_NAMES_V76 = ["cristal_astral", "toile_voile", "engrenage", "fragment_meteorite", "sifflet_compagnons", "truffe",
                  "pelote_laine", "fromage_affine", "clochette_cochon", "carte_stellaire", "graine_lumineuse", "puce_holo",
                  "fleur_nebuleuse", "badge_visiteur", "appareil_holo", "the_stellaire", "gelee_cosmique",
                  "biscuit_lunaire", "coeur_fleche"]
OUT_NAMES = set(SOLS + BATI + HOLOS + FRESQUES + VEGETATION + ["enseigne_" + k for k in ENSEIGNES_V76])


# =================================================================== outils

def rng(seed):
    return np.random.default_rng(seed)


def _log(p):
    print(p.relative_to(ROOT), flush=True)


def _guard(p):
    """N'écrit que les fichiers de ce générateur (jamais une texture ou une icône d'une autre version)."""
    stem = p.stem
    if p.parent == ITEMS:
        ok = stem in ICON_NAMES_V76
    elif p.parent == OUT:
        base = stem[:-2] if stem.endswith(("_n", "_e")) else stem
        ok = base in OUT_NAMES
    else:
        ok = False
    if not ok:
        sys.exit("refus d'écrire hors des listes V76 : %s" % p)
    p.parent.mkdir(parents=True, exist_ok=True)
    return p


def save_rgb(arr, name, folder=None):
    p = _guard((folder or OUT) / name)
    img = (arr if isinstance(arr, Image.Image) else to_img(arr)).convert("RGB")
    img.save(p, optimize=True)
    STATS[name] = np.asarray(img, np.float32).reshape(-1, 3).mean(0)
    _log(p)


def save_rgba(arr, name, folder=None):
    p = _guard((folder or OUT) / name)
    if not isinstance(arr, Image.Image):
        arr = Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA")
    arr.save(p, optimize=True)
    _log(p)


def save_surface(name, col, h, strength):
    """Couleur + carte de relief (adoucie de 0,6 px). Sols : relief en 512 px (raccord gardé) ;
    bâti : relief en pleine résolution."""
    save_rgb(col, name + ".png")
    p = _guard(OUT / (name + "_n.png"))
    h = gblur(h.astype(np.float32), 0.6)
    if name in SOLS:
        normal_img(down(gblur(h, 0.5), 2), strength * 0.55).save(p, optimize=True)
    else:
        normal_img(h, strength * 1.1).save(p, optimize=True)
    _log(p)


def save_e(name, e):
    """Carte d'émission (fond noir) réduite à 512 px (même placement UV) ; raccordable comme la couleur."""
    e = np.clip(e, 0, 1).astype(np.float32)
    while e.shape[0] > 512:
        e = down(e, 2)
    e = np.where(e < 1.5 / 255, 0, e)  # vrai noir (fichier léger, rien ne brille par erreur)
    save_rgb(e, name + "_e.png")


def iri(t, sat=1.0):
    """Teinte irisée (couches minces) pour t (0..1 = un tour d'arc-en-ciel pastel)."""
    t = np.asarray(t, np.float32)[..., None]
    ph = np.array((0.0, 0.33, 0.67), np.float32)
    c = 0.5 + 0.5 * np.cos(TAU * (t + ph))
    return 1 - sat + sat * c


def hexcells(S, m, n):
    """Pavage hexagonal raccordable (m colonnes, n rangées paires, rangées impaires décalées d'une
    demi-case). Renvoie id de case, distance au joint (px), dx et dy vers le centre de la case."""
    dx, dy = S / m, S / n
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    r0 = np.floor(yy / dy).astype(np.int32)
    D, PX, PY, ID = [], [], [], []
    for dr in (-1, 0, 1):
        r = r0 + dr
        off = 0.5 * np.mod(r, 2)
        c0 = np.round(xx / dx - off - 0.5).astype(np.int32)
        for dc in (-1, 0, 1):
            c = c0 + dc
            px = (c + off + 0.5) * dx
            py = (r + 0.5) * dy
            D.append((xx - px) ** 2 + (yy - py) ** 2)
            PX.append(px)
            PY.append(py)
            ID.append(np.mod(r, n) * m + np.mod(c, m))
    D, PX, PY, ID = (np.stack(a) for a in (D, PX, PY, ID))
    k = np.argmin(D, 0)[None]
    d1 = np.take_along_axis(D, k, 0)[0]
    p1x = np.take_along_axis(PX, k, 0)[0]
    p1y = np.take_along_axis(PY, k, 0)[0]
    cid = np.take_along_axis(ID, k, 0)[0]
    L = np.sqrt((PX - p1x) ** 2 + (PY - p1y) ** 2)
    e = np.where(L > 1e-3, (D - d1) / (2 * np.maximum(L, 1e-3)), 1e9)
    edge = e.min(0)
    return cid, edge.astype(np.float32), (xx - p1x).astype(np.float32), (yy - p1y).astype(np.float32)


def star4(x, y, r, inner=0.18, rot=0.0):
    return star_pts(x, y, r, 4, inner, rot - 90)


def sparkle_map(R, S, n, rmin, rmax, H=None):
    """Petites étoiles à quatre branches (paillettes), raccordables : intensité 0..1."""
    H = H or S
    img = Image.new("L", (S, H), 0)
    d = ImageDraw.Draw(img)
    for _ in range(n):
        x, y = R.random() * S, R.random() * H
        r = R.uniform(rmin, rmax)
        v = int(R.uniform(140, 255))
        for ox, oy in offs(x, y, r + 1, S, H):
            d.polygon(star4(x + ox, y + oy, r, 0.16, R.uniform(0, 45)), fill=v)
    return np.asarray(img, np.float32) / 255.0


def _nacre_field(R, S, u, v, sid, sat=0.28, scale=90.0):
    """Nacre : couches ondulées et lignes de croissance, reflets irisés pastel ; (u, v) sont des
    coordonnées locales continues dans chaque pièce sid (le raccord suit les joints)."""
    ang = per_id(sid, R, 0, TAU)
    sc = per_id(sid, R, 0.5, 1.2)
    w1 = tn(R, S, (2, 4, 8, 16), 0.6)
    w2 = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    t = (u * np.cos(ang) + v * np.sin(ang)) / (scale * sc) + (w1 - 0.5) * 3.0 + (w2 - 0.5) * 0.8
    bands = 0.5 + 0.5 * np.sin(TAU * t * 3.0 + 2.0 * np.sin(TAU * t))
    growth = 0.5 + 0.5 * np.sin(TAU * t * 11.0 + 3.0 * (w2 - 0.5))
    fine = tn(R, S, (64, 128, 256, 512), 0.75)
    gr = grain(R, S, 0.6)
    hue = per_id(sid, R, 0, 1) + t * 0.18 + (fine - 0.5) * 0.12
    base = mix(C(0.85, 0.84, 0.86), C(0.93, 0.92, 0.94), bands * 0.7 + growth * 0.3)
    tint = per_id(sid, R, 0.0, 1.0)
    base = base * mix(C(1.0, 0.97, 0.97), C(0.96, 0.98, 1.0), tint)
    sheen = smooth(0.35, 0.9, tn(R, S, (4, 8, 16, 32), 0.6) * 0.6 + bands * 0.4)
    col = mix(base, base * iri(hue, sat) * 1.05, 0.12 + 0.3 * sheen)
    col = col * (0.95 + 0.06 * fine[..., None]) * (0.97 + 0.04 * gr[..., None])
    return col, bands, fine, w2


def _round_edge(u, v, W, H, rr):
    """Distance au bord d'un rectangle W x H à coins arrondis (u, v locaux)."""
    ex = np.minimum(u, W - u)
    ey = np.minimum(v, H - v)
    cx = np.maximum(rr - ex, 0)
    cy = np.maximum(rr - ey, 0)
    return np.where((cx > 0) & (cy > 0), rr - np.hypot(cx, cy), np.minimum(ex, ey)).astype(np.float32)


# =================================================================== les sols (une tuile ≈ 4 m)

def nacre():
    """Dalles de nacre en appareil décalé (≈ 1 m, coins arrondis) : couches nacrées ondulées, reflets
    irisés rose, vert d'eau et bleu ; joints d'argent avec un filet lumineux ; aux jonctions, des clous
    de cristal. Émission (_e) : filets des joints et clous."""
    S = 1024
    R = rng(7601)
    T = 256
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    row = np.floor(yy / T).astype(np.int32)
    xo = xx - (np.mod(row, 2) * T * 0.5)
    col_i = np.floor(np.mod(xo, S) / T).astype(np.int32)
    u = np.mod(xo, T)
    v = np.mod(yy, T)
    sid = row * 8 + col_i
    rr = 14.0
    ex = np.minimum(u, T - u)
    ey = np.minimum(v, T - v)
    cx = np.maximum(rr - ex, 0)
    cy = np.maximum(rr - ey, 0)
    edge = np.where((cx > 0) & (cy > 0), rr - np.hypot(cx, cy), np.minimum(ex, ey))
    col, bands, fine, w2 = _nacre_field(R, S, u, v, sid)
    # quelques veines nacrées plus claires (reflets)
    gl = np.exp(-((w2 - 0.5) / 0.02) ** 2) * smooth(0.5, 0.7, tn(R, S, (4, 8, 16), 0.6))
    col = col + gl[..., None] * 0.06
    # joints : rainure d'argent, filet lumineux au fond
    groove = smooth(5.0, 1.5, edge)
    line = np.exp(-(edge / 1.3) ** 2)
    silver = C(0.62, 0.64, 0.7) * (0.9 + 0.2 * fine[..., None])
    col = mix(col, silver, groove * 0.85)
    glowc = mix(C(0.55, 0.85, 1.0), C(0.8, 0.65, 1.0), smooth(0.3, 0.7, tn(R, S, (2, 4, 8), 0.6)))
    col = mix(col, glowc, line * 0.8)
    # clous de cristal aux jonctions en T (une sur deux)
    stud = np.zeros((S, S), np.float32)
    studc = np.zeros((S, S, 3), np.float32)
    for r_ in range(S // T + 1):
        for c_ in range(S // T * 2 + 1):
            if (r_ + c_) % 2:
                continue
            px, py = c_ * T * 0.5, r_ * T
            dd = np.hypot(np.mod(xx - px + S / 2, S) - S / 2, np.mod(yy - py + S / 2, S) - S / 2)
            dia = np.abs(np.mod(xx - px + S / 2, S) - S / 2) + np.abs(np.mod(yy - py + S / 2, S) - S / 2)
            m = smooth(15.0, 12.0, dia)
            stud = np.maximum(stud, m)
            studc = np.maximum(studc, (m * np.exp(-dd / 10.0))[..., None] * C(0.75, 0.9, 1.0))
    col = mix(col, C(0.7, 0.85, 1.0) * 0.8 + studc * 0.4, stud)
    h = 0.6 + 0.4 * smooth(0.0, 10.0, edge) - 0.5 * groove + bands * 0.02 + fine * 0.01
    h = np.where(stud > 0, np.maximum(h, 0.75 + 0.3 * stud), h)
    col = finish(col, h, shadow_hs=0.0, bake_s=3.0, k=0.25, ao=0.25, ao_r=4)
    save_surface("nacre", col, h, 3.0)
    e = glowc * line[..., None] * 0.85 + studc * 1.1 + C(0.6, 0.8, 1.0) * stud[..., None] * 0.35
    save_e("nacre", e)


def cristal_sol():
    """Dalles hexagonales de cristal (≈ 57 cm) serties d'argent : bleu-turquoise à lavande, profondeur
    (voiles internes, plans de clivage clairs, bulles), biseau brillant ; une dalle sur trois a un cœur
    lumineux. Émission (_e) : cœurs, plans de clivage et filet des sertis."""
    S = 1024
    R = rng(7602)
    cid, edge, dx, dy = hexcells(S, 7, 8)
    hue = per_id(cid, R, 0, 1)
    lit = per_id(cid, R, 0, 1) < 0.34
    deep = tn(R, S, (4, 8, 16, 32), 0.6)
    veil = tn(R, S, (8, 16, 32, 64, 128), 0.65)
    fine = tn(R, S, (128, 256, 512), 0.8)
    c1 = mix(C(0.1, 0.32, 0.42), C(0.22, 0.24, 0.46), hue)
    c2 = mix(C(0.32, 0.62, 0.72), C(0.5, 0.48, 0.78), hue)
    col = mix(c1, c2, smooth(0.25, 0.85, deep * 0.6 + veil * 0.4))
    # voiles internes (fantômes) : lignes de niveau douces décalées (effet de profondeur)
    ph = warp(veil, (deep - 0.5) * 40, (fine - 0.5) * 6)
    ghost = np.exp(-((np.mod(ph * 9, 1) - 0.5) / 0.08) ** 2) * 0.5
    col = col + ghost[..., None] * C(0.1, 0.16, 0.2)
    # plans de clivage : traits clairs dans chaque dalle (angle par dalle)
    a = per_id(cid, R, 0, math.pi)
    o = per_id(cid, R, -30, 30)
    cl = np.abs(dx * np.cos(a) + dy * np.sin(a) - o)
    a2 = a + per_id(cid, R, 0.6, 1.2)
    cl2 = np.abs(dx * np.cos(a2) + dy * np.sin(a2) + o * 0.7)
    has2 = per_id(cid, R, 0, 1) < 0.5
    fade = smooth(0.3, 0.7, tn(R, S, (8, 16, 32), 0.6))
    plane = np.exp(-(cl / 1.2) ** 2) * (0.4 + 0.6 * fade) + np.where(has2, np.exp(-(cl2 / 1.0) ** 2) * fade * 0.6, 0)
    plane = plane * smooth(4, 14, edge)
    col = col + plane[..., None] * C(0.45, 0.6, 0.7)
    # cœurs lumineux
    rad = np.hypot(dx, dy)
    core = np.where(lit, np.exp(-(rad / 26.0) ** 2) + 0.35 * np.exp(-(rad / 55.0) ** 2), 0)
    corec = mix(C(0.6, 0.95, 1.0), C(0.9, 0.7, 1.0), hue)
    col = col + core[..., None] * corec * 0.55
    # bulles et inclusions
    bub = sparkle_map(R, S, 900, 1.0, 2.2) * smooth(6, 12, edge)
    col = col + bub[..., None] * 0.35
    col = col * (0.94 + 0.1 * fine[..., None])
    # serti d'argent + biseau
    frame = smooth(4.5, 2.5, edge)
    bevel = smooth(4.5, 12.0, edge)
    hl = np.exp(-((edge - 6.0) / 1.6) ** 2)
    col = col + hl[..., None] * 0.18
    silver = C(0.66, 0.68, 0.74) * (0.9 + 0.2 * fine[..., None])
    col = mix(col, silver, frame)
    thread = np.exp(-(edge / 0.9) ** 2)
    col = mix(col, C(0.7, 0.92, 1.0), thread * 0.7)
    h = 0.35 + 0.55 * bevel - 0.2 * frame + 0.02 * veil + 0.25 * smooth(1.0, 3.5, edge) * frame
    col = finish(col, h, bake_s=3.0, k=0.3, ao=0.2, ao_r=4)
    save_surface("cristal_sol", col, h, 3.0)
    e = core[..., None] * corec * 0.95 + plane[..., None] * C(0.25, 0.4, 0.5) * 0.6 + thread[..., None] * C(0.5, 0.8, 1.0) * 0.6
    save_e("cristal_sol", e)


def mousse_astrale():
    """Mousse astrale : coussins bombés bleu nuit et violets, pousses étoilées, colonies de sporanges
    sur tiges dont les capsules luisent (lavande, rose, cyan). Fond sombre et points lumineux : la
    couleur sert telle quelle de carte d'émission."""
    S, K = 1024, 2
    S2 = S * K
    R = rng(7603)
    hue = tn(R, S, (4, 8, 16, 32), 0.7)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    cush = np.zeros((S, S), np.float32)
    for cells, amp in ((12, 1.0), (28, 0.6)):
        _, ed, cid, _, _ = worley(R, S, cells, 0.9)
        cush = np.maximum(cush, smooth(0.0, S / cells * 0.45, ed) ** 0.7 * per_id(cid, R, 0.7, 1.0) * amp)
    cush = 0.25 + 0.75 * gblur(cush, 3.0)
    base = mix(C(0.04, 0.035, 0.09), C(0.1, 0.08, 0.2), cush)
    img = to_img(up(base, K))
    d = ImageDraw.Draw(img)
    hm = Image.fromarray((np.clip(up(cush * 0.6, K), 0, 1) * 255).astype(np.uint8), "L")
    dh = ImageDraw.Draw(hm)
    violet = np.array((0.34, 0.24, 0.6))
    blue = np.array((0.16, 0.24, 0.56))
    teal = np.array((0.16, 0.42, 0.52))
    for layer, (count, bright, rr) in enumerate(((80000, 0.55, (4, 8)), (60000, 0.85, (3, 7)), (26000, 1.15, (2.5, 5)))):
        xs = R.random((count, 2)) * S2
        for x, y in xs:
            xi, yi = int(x / K) % S, int(y / K) % S
            cv = cush[yi, xi]
            if cv < 0.15 * layer:
                continue
            hv = hue[yi, xi]
            c = violet * (1 - hv) + blue * hv
            if R.random() < 0.07:
                c = teal
            c = c * bright * (0.35 + 0.8 * cv) * R.uniform(0.8, 1.2)
            colr = tuple(int(np.clip(v, 0, 1) * 255) for v in c)
            r = R.uniform(*rr)
            a0 = R.uniform(0, TAU)
            hvv = int(80 + 150 * cv + layer * 15)
            for ox, oy in offs(x, y, r + 2, S2):
                X, Y = x + ox, y + oy
                for k in range(5):
                    a = a0 + k * TAU / 5
                    d.line([(X, Y), (X + math.cos(a) * r, Y + math.sin(a) * r)], fill=colr, width=1)
                dh.ellipse((X - r * 0.6, Y - r * 0.6, X + r * 0.6, Y + r * 0.6), fill=hvv)
    glow = Image.new("L", (S2, S2), 0)
    dg = ImageDraw.Draw(glow)
    gcol = Image.new("RGB", (S2, S2), (0, 0, 0))
    dc = ImageDraw.Draw(gcol)
    for _ in range(170):
        cx, cy = R.random(2) * S2
        u = R.random()
        cc = (196, 160, 255) if u < 0.5 else ((255, 150, 220) if u < 0.75 else (130, 230, 255))
        for _ in range(int(R.integers(5, 22))):
            x, y = cx + R.normal(0, 22), cy + R.normal(0, 22)
            a = R.uniform(0, TAU)
            L = R.uniform(5, 14)
            r = R.uniform(2.0, 4.2)
            for ox, oy in offs(x, y, L + r * 5, S2):
                X, Y = x + ox, y + oy
                ex, ey = X + math.cos(a) * L, Y + math.sin(a) * L
                d.line([(X, Y), (ex, ey)], fill=(90, 80, 130), width=2)
                d.ellipse((ex - r, ey - r, ex + r, ey + r), fill=cc)
                d.ellipse((ex - r * 0.45, ey - r * 0.45, ex + r * 0.45, ey + r * 0.45), fill=(250, 245, 255))
                dh.ellipse((ex - r, ey - r, ex + r, ey + r), fill=255)
                dg.ellipse((ex - r, ey - r, ex + r, ey + r), fill=255)
                dc.ellipse((ex - r * 5, ey - r * 5, ex + r * 5, ey + r * 5), fill=cc)
    col = down(from_img(img), K)
    h = down(np.asarray(hm, np.float32) / 255.0, K)
    g = down(np.asarray(glow, np.float32) / 255.0, K)
    gc = gblur(down(from_img(gcol), K), 3.0)
    halo = gblur(g, 5.0)
    halo = np.clip(halo / (np.percentile(halo, 99.7) + 1e-6), 0, 1)
    col = finish(col, h, shadow_hs=6.0, bake_s=3.0, k=0.3, ao=0.5, ao_r=6)
    col = col * (0.9 + 0.2 * fine[..., None])
    col = col + gc * halo[..., None] * 0.35
    save_surface("mousse_astrale", col, h * 0.7 + cush * 0.3, 4.0)


def roche_astrale():
    """Roche sombre du dessous d'Astralys : basalte bleu-noir à facettes de cassure, grain fin, réseau
    de veines de cristal bleu-violet (plus clair au cœur), petits prismes le long des veines.
    Émission (_e) : les veines et les prismes."""
    S = 1024
    R = rng(7604)
    n = tn(R, S, (4, 8, 16, 32, 64, 128), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.6)
    # facettes : plans par cellule (deux échelles)
    hf = np.zeros((S, S), np.float32)
    edges = np.zeros((S, S), np.float32)
    for cells, amp in ((7, 1.0), (16, 0.5)):
        _, ed, cid, ddx, ddy = worley(R, S, cells, 0.95)
        gx = per_id(cid, R, -1, 1)
        gy = per_id(cid, R, -1, 1)
        hf += amp * ((ddx * gx + ddy * gy) / (S / cells) * 0.5 + per_id(cid, R, 0, 0.6))
        edges = np.maximum(edges, np.exp(-(ed / 1.6) ** 2) * amp)
    hf = norm01(hf)
    col = mix(C(0.1, 0.1, 0.14), C(0.22, 0.22, 0.27), smooth(0.2, 0.8, n * 0.5 + hf * 0.5))
    col = mix(col, C(0.16, 0.14, 0.22), smooth(0.55, 0.8, tn(R, S, (4, 8, 16), 0.6)) * 0.6)
    col = col * (0.85 + 0.3 * gr[..., None]) * (0.92 + 0.16 * fine[..., None])
    col = col * (1 - 0.35 * edges[..., None])
    # veines de cristal
    thin, halo = _veins(R, S, n_cells=4, warp_amp=120, lines=((0.5, 2.2), (0.32, 1.2)), net=0.55)
    vh = tn(R, S, (2, 4, 8), 0.6)
    vc = mix(C(0.42, 0.5, 1.0), C(0.72, 0.45, 1.0), smooth(0.35, 0.65, vh))
    core = smooth(0.55, 0.95, thin)
    col = mix(col, vc * 0.9, smooth(0.15, 0.5, thin))
    col = mix(col, C(0.85, 0.88, 1.0), core * 0.6)
    col = col + vc * halo[..., None] * 0.12
    # prismes le long des veines
    pr = np.zeros((S, S), np.float32)
    img = Image.new("L", (S, S), 0)
    dpr = ImageDraw.Draw(img)
    cand = np.argwhere(thin > 0.6)
    if len(cand):
        pick = cand[R.choice(len(cand), min(700, len(cand)), replace=False)]
        for y, x in pick:
            r = R.uniform(2.5, 6.5)
            a = R.uniform(0, 60)
            for ox, oy in offs(x, y, r + 1, S):
                dpr.polygon([(x + ox + math.cos(math.radians(a + k * 60)) * r, y + oy + math.sin(math.radians(a + k * 60)) * r * 0.8)
                             for k in range(6)], fill=int(R.uniform(150, 255)))
        pr = np.asarray(img, np.float32) / 255.0
    col = mix(col, mix(vc, C(0.95, 0.95, 1.0), 0.4), pr)
    h = hf * 0.6 + n * 0.25 + gr * 0.03 + fine * 0.03 - edges * 0.08 + thin * 0.05 + pr * 0.12
    col = finish(col, h, shadow_hs=8.0, bake_s=3.0, k=0.35, ao=0.35, ao_r=6)
    save_surface("roche_astrale", col, h, 5.0)
    e = vc * (smooth(0.2, 0.7, thin)[..., None] * 0.75 + halo[..., None] * 0.25) + C(0.9, 0.9, 1.0) * (core * 0.5 + pr * 0.6)[..., None]
    save_e("roche_astrale", e)


def sable_stellaire():
    """Sable argenté très fin (rides de vent), paillettes de toutes les couleurs, petites étoiles de
    cristal, quelques galets de lune nacrés. Émission (_e) : les paillettes."""
    S = 1024
    R = rng(7605)
    n = tn(R, S, (2, 4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (256, 512, 1024), 0.85)
    gr = grain(R, S, 0.5)
    gr2 = grain(R, S, 1.0)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    wx = (tn(R, S, (2, 4, 8, 16), 0.6) - 0.5) * 70
    ph = (yy + wx) / S * 24 * TAU + xx / S * 2 * TAU + (tn(R, S, (4, 8, 16), 0.6) - 0.5) * 4
    rip = 0.5 + 0.5 * np.sin(ph + 0.6 * np.sin(ph))
    amp = 0.4 + 0.6 * smooth(0.3, 0.7, tn(R, S, (4, 8, 16), 0.6))
    ripple = rip * amp
    col = mix(C(0.63, 0.64, 0.69), C(0.7, 0.71, 0.76), smooth(0.2, 0.8, n))
    col = mix(col, C(0.5, 0.5, 0.6), smooth(0.55, 0.95, (1 - rip) * amp) * 0.35)
    col = col * (0.84 + 0.32 * gr[..., None]) * (0.94 + 0.12 * gr2[..., None])
    sp = R.random((S, S))
    col = mix(col, C(0.95, 0.95, 1.0), (sp > 0.985) * 0.5)
    col = mix(col, C(0.3, 0.3, 0.38), (sp < 0.015) * 0.5)
    h = ripple * 0.3 + n * 0.25 + gr * 0.03 + fine * 0.02
    # galets de lune
    items = []
    for _ in range(90):
        r = R.uniform(3, 9)
        items.append((R.random() * S, R.random() * S, rock_poly(R, r, k=int(R.integers(6, 10)), jit=0.15, sm=1), r))
    pal = [((0.86, 0.86, 0.92), 0.5), ((0.8, 0.76, 0.9), 0.25), ((0.74, 0.84, 0.9), 0.25)]
    scol, sth, mask, prof, _ = stones_layer(R, S, items, pal, fine)
    ma = gblur(mask.astype(np.float32), 0.5)
    hue_s = tn(R, S, (8, 16, 32), 0.6)
    col = mix(col, scol * mix(C(1, 1, 1), iri(hue_s * 2, 0.4), prof * 0.5), ma)
    h = h + sth * mask * 0.4
    # paillettes : grains colorés (1 à 2 px) et petites étoiles de cristal
    glit = np.zeros((S, S, 3), np.float32)
    pts = R.random((9000, 2)) * S
    hues = R.random(9000)
    cols = iri(hues, 0.9) * 0.6 + 0.4
    xi = pts[:, 0].astype(int) % S
    yi = pts[:, 1].astype(int) % S
    glit[yi, xi] = cols * R.uniform(0.6, 1.0, (9000, 1))
    big = (R.random(9000) < 0.35)
    glit[yi[big], (xi[big] + 1) % S] = cols[big] * 0.7
    glit[(yi[big] + 1) % S, xi[big]] = cols[big] * 0.7
    stars = sparkle_map(R, S, 160, 3.0, 6.5)
    sh = tn(R, S, (4, 8, 16), 0.6)
    starc = mix(C(0.75, 0.9, 1.0), C(1.0, 0.8, 0.95), sh)
    gmask = np.clip(glit.max(-1), 0, 1)
    col = mix(col, glit, gmask * 0.9)
    col = mix(col, starc, stars)
    h = h + stars * 0.15
    col = finish(col, h, shadow_hs=5.0, bake_s=3.0, k=0.3, ao=0.2, ao_r=6)
    save_surface("sable_stellaire", col, h, 5.0)
    # à 512 px, chaque paillette garde de l'éclat : on étale un peu avant la réduction
    e = gblur(glit, 0.7) * 2.2 + starc * stars[..., None] * 1.1
    save_e("sable_stellaire", e)


def herbe_lunaire():
    """Herbe lunaire vue d'en haut : sol bleu-gris sombre, touffes de brins argentés (reflets lavande et
    vert d'eau), quelques graminées couchées, petites fleurs-étoiles qui luisent (cyan, rose, blanc).
    Émission (_e) : les fleurs."""
    S, K = 1024, 2
    S2 = S * K
    R = rng(7606)
    n = tn(R, S, (4, 8, 16, 32, 64, 128), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    cover = tn(R, S, (8, 16, 32, 64), 0.65)
    gr = grain(R, S, 0.6)
    soil = mix(C(0.2, 0.21, 0.27), C(0.3, 0.31, 0.37), smooth(0.3, 0.75, n))
    soil = soil * (0.85 + 0.3 * gr[..., None]) * (0.93 + 0.14 * fine[..., None])
    h0 = n * 0.15 + gr * 0.04
    soil = bake(soil, h0, 3.0, k=0.3, ao=0.3, ao_r=4)
    img = to_img(up(soil, K))
    d = ImageDraw.Draw(img)
    hm = Image.fromarray((np.clip(up(h0, K) * 0.5, 0, 1) * 255).astype(np.uint8), "L")
    dh = ImageDraw.Draw(hm)
    blades = [np.array(c) for c in ((0.62, 0.66, 0.74), (0.72, 0.75, 0.84), (0.55, 0.6, 0.68), (0.8, 0.82, 0.9),
                                     (0.64, 0.6, 0.78), (0.56, 0.68, 0.7))]
    for layer, (count, bright, hv, ls) in enumerate(((30000, 0.5, 90, 1.0), (34000, 0.72, 160, 0.95), (26000, 0.9, 230, 0.85))):
        centers = R.random((count // 9, 2)) * S2
        cv = cover[(centers[:, 1] / K).astype(int) % S, (centers[:, 0] / K).astype(int) % S]
        centers = centers[R.random(len(centers)) < smooth(0.15, 0.45, cv) * 0.85 + 0.15]
        for cx, cy in centers:
            for _ in range(int(R.integers(6, 15))):
                x = cx + R.normal(0, 7)
                y = cy + R.normal(0, 7)
                c = blades[int(R.integers(len(blades)))] * bright * R.uniform(0.82, 1.12)
                colr = tuple(int(np.clip(v, 0, 1) * 255) for v in c)
                a = R.uniform(0, TAU)
                L = R.uniform(30, 90) * ls
                poly = blade_poly(x, y, a, L, R.uniform(3.0, 5.5), R.uniform(-0.3, 0.3))
                hvv = int(hv + R.uniform(-25, 25))
                for ox, oy in offs(x, y, L + 6, S2):
                    pp = [(px + ox, py + oy) for px, py in poly]
                    d.polygon(pp, fill=colr)
                    dh.polygon(pp, fill=hvv)
                    # arête claire (reflet argenté)
                    if layer == 2 and R.random() < 0.3:
                        d.line(pp[:6], fill=tuple(min(255, int(v * 1.25)) for v in colr), width=1)
        if layer == 1:
            for _ in range(700):
                x, y = R.random(2) * S2
                a = R.uniform(0, TAU)
                L = R.uniform(70, 180)
                c = tuple(int(v * R.uniform(0.8, 1.05)) for v in (196, 200, 220))
                x2, y2 = x + math.cos(a) * L, y + math.sin(a) * L
                for ox, oy in offs(x, y, L + 12, S2):
                    d.line([(x + ox, y + oy), (x2 + ox, y2 + oy)], fill=c, width=2)
                    dh.line([(x + ox, y + oy), (x2 + ox, y2 + oy)], fill=200, width=2)
    # fleurs-étoiles lumineuses (par petits groupes)
    fl = Image.new("RGB", (S2, S2), (0, 0, 0))
    dfl = ImageDraw.Draw(fl)
    for _ in range(140):
        cx, cy = R.random(2) * S2
        u = R.random()
        cc = (150, 235, 255) if u < 0.45 else ((255, 170, 225) if u < 0.75 else (235, 235, 255))
        for _ in range(int(R.integers(2, 7))):
            x, y = cx + R.normal(0, 18), cy + R.normal(0, 18)
            r = R.uniform(5, 9)
            rot = R.uniform(0, 72)
            for ox, oy in offs(x, y, r + 2, S2):
                p = star_pts(x + ox, y + oy, r, 5, 0.42, rot)
                d.polygon(p, fill=cc)
                d.ellipse((x + ox - r * 0.3, y + oy - r * 0.3, x + ox + r * 0.3, y + oy + r * 0.3), fill=(255, 250, 220))
                dh.polygon(p, fill=250)
                dfl.polygon(p, fill=cc)
                dfl.ellipse((x + ox - r * 0.3, y + oy - r * 0.3, x + ox + r * 0.3, y + oy + r * 0.3), fill=(255, 250, 220))
    col = down(from_img(img), K)
    h = down(np.asarray(hm, np.float32) / 255.0, K)
    col = gblur(col, 0.3)
    h = gblur(h, 0.7)
    col = finish(col, h, shadow_hs=8.0, bake_s=3.0, k=0.25, ao=0.35, ao_r=5)
    save_surface("herbe_lunaire", col, h * 0.85 + n * 0.15, 4.0)
    f = down(from_img(fl), K)
    save_e("herbe_lunaire", f + gblur(f, 3.0) * 0.8)


def sols():
    for f in (nacre, cristal_sol, mousse_astrale, roche_astrale, sable_stellaire, herbe_lunaire):
        f()


# =================================================================== le bâti (une tuile ≈ 3 m)

def nacre_mur():
    """Panneaux nacrés (≈ 1 m x 1,5 m) à coins arrondis, cadres d'argent bombés, filet de lumière
    incrusté à 10 cm du bord et petit emblème lumen (anneau et point) en haut de chaque panneau.
    Émission (_e) : filets et emblèmes."""
    S = 1024
    R = rng(7611)
    W, H = S / 3, S / 2
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    u = np.mod(xx, W)
    v = np.mod(yy, H)
    sid = (np.floor(yy / H) * 3 + np.floor(xx / W)).astype(np.int32)
    edge = _round_edge(u, v, W, H, 22.0)
    col, bands, fine, w2 = _nacre_field(R, S, u, v, sid, sat=0.3, scale=120.0)
    col = col * C(0.98, 0.98, 1.0)
    # cadre d'argent (bombé) et fente entre panneaux
    frame = smooth(13.0, 11.0, edge)
    prof = np.sin(np.clip(edge / 12.0, 0, 1) * math.pi)
    silver = C(0.7, 0.72, 0.78) * (0.92 + 0.12 * fine[..., None])
    col = mix(col, silver * (0.85 + 0.25 * prof[..., None]), frame)
    gap = smooth(2.2, 0.6, edge)
    col = col * (1 - 0.7 * gap[..., None])
    # filet lumineux incrusté et emblème
    inlay = np.exp(-((edge - 36.0) / 1.5) ** 2)
    du, dv = u - W / 2, v - 64
    rd = np.hypot(du, dv)
    emb = np.exp(-((rd - 20.0) / 1.6) ** 2) + smooth(6.5, 4.5, rd) + np.exp(-((rd - 30.0) / 1.0) ** 2) * (np.abs(du) > 10) * 0.7
    emb = np.clip(emb, 0, 1)
    lum = np.clip(inlay + emb, 0, 1)
    gc = mix(C(0.6, 0.86, 1.0), C(0.84, 0.7, 1.0), smooth(0.3, 0.7, tn(R, S, (2, 4), 0.6)))
    col = mix(col, mix(gc, C(1, 1, 1), 0.4), lum * 0.85)
    h = 0.5 + 0.35 * frame * prof - 0.6 * gap + 0.02 * bands - 0.08 * lum + 0.01 * fine
    col = finish(col, h, bake_s=3.0, k=0.25, ao=0.25, ao_r=4)
    save_surface("nacre_mur", col, h, 3.0)
    save_e("nacre_mur", gc * lum[..., None] * 0.9 + gblur(gc * lum[..., None], 3.0) * 0.5)


CRISTAUX = {
    "cristal_bleu": dict(seed=7612, dark=(0.06, 0.13, 0.34), light=(0.48, 0.7, 0.98), glow=(0.5, 0.8, 1.0)),
    "cristal_violet": dict(seed=7613, dark=(0.15, 0.07, 0.32), light=(0.7, 0.54, 0.98), glow=(0.78, 0.6, 1.0)),
    "cristal_rose": dict(seed=7614, dark=(0.34, 0.09, 0.22), light=(1.0, 0.66, 0.84), glow=(1.0, 0.68, 0.88)),
}


def _lumen_motifs(R, S, n, K=2):
    """Motifs lumens (anneaux concentriques, couronnes de points, rayons, arcs), raccordables : 0..1."""
    S2 = S * K
    img = Image.new("L", (S2, S2), 0)
    d = ImageDraw.Draw(img)
    for _ in range(n):
        x, y = R.random(2) * S2
        r0 = R.uniform(40, 110) * K
        rings = int(R.integers(2, 4))
        nd = int(R.integers(6, 13))
        a0 = R.uniform(0, 360)
        w = max(2, int(2.2 * K))
        for ox, oy in offs(x, y, r0 * 1.5, S2):
            X, Y = x + ox, y + oy
            for k in range(rings):
                r = r0 * (1 - k * 0.3)
                if k == 0:
                    for j in range(3):
                        s = a0 + j * 120
                        d.arc((X - r, Y - r, X + r, Y + r), s, s + 95, fill=255, width=w)
                else:
                    d.ellipse((X - r, Y - r, X + r, Y + r), outline=200, width=w)
            for j in range(nd):
                a = math.radians(a0 + j * 360 / nd)
                px, py = X + math.cos(a) * r0 * 1.18, Y + math.sin(a) * r0 * 1.18
                rr = 3.2 * K
                d.ellipse((px - rr, py - rr, px + rr, py + rr), fill=255)
                if j % 3 == 0:
                    d.line([(X + math.cos(a) * r0 * 0.45, Y + math.sin(a) * r0 * 0.45), (X + math.cos(a) * r0 * 0.68, Y + math.sin(a) * r0 * 0.68)],
                           fill=230, width=w)
            rr = 6 * K
            d.ellipse((X - rr, Y - rr, X + rr, Y + rr), fill=255)
    return down(np.asarray(img, np.float32) / 255.0, K)


def cristal(name):
    """Cristal facetté (grandes faces planes et petites faces, arêtes claires), profondeur (dégradé
    interne, voiles fantômes, inclusions et bulles), et motifs lumens enfouis dans la masse.
    Émission (_e) : motifs, lueur interne faible, arêtes."""
    P = CRISTAUX[name]
    S = 1024
    R = rng(P["seed"])
    dark, light, glow = (np.array(P[k], np.float32) for k in ("dark", "light", "glow"))
    hf = np.zeros((S, S), np.float32)
    edges = np.zeros((S, S), np.float32)
    tone = None
    for cells, amp in ((5, 1.0), (11, 0.45)):
        _, ed, cid, ddx, ddy = worley(R, S, cells, 0.95)
        gx = per_id(cid, R, -1, 1)
        gy = per_id(cid, R, -1, 1)
        hf += amp * ((ddx * gx + ddy * gy) / (S / cells) * 0.6 + per_id(cid, R, 0, 0.5))
        edges = np.maximum(edges, np.exp(-(ed / 1.3) ** 2) * amp)
        if tone is None:
            tone = per_id(cid, R, 0.0, 1.0)
    hfn = norm01(hf)
    depth = tn(R, S, (2, 4, 8, 16), 0.6)
    veil = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    veil = warp(veil, (depth - 0.5) * 60, (hfn - 0.5) * 30)
    col = mix(dark, light, smooth(0.1, 0.95, depth * 0.45 + hfn * 0.25 + tone * 0.3))
    ghost = np.zeros((S, S), np.float32)
    for lv in (0.35, 0.5, 0.65):
        ghost = np.maximum(ghost, np.exp(-((veil - lv) / 0.02) ** 2))
    ghost = gblur(ghost, 1.5) * smooth(0.3, 0.7, tn(R, S, (4, 8, 16), 0.6))
    col = col + ghost[..., None] * mix(light, C(1, 1, 1), 0.5) * 0.18
    mot = _lumen_motifs(R, S, 5)
    mot_soft = gblur(mot, 2.5)
    mvis = 0.35 + 0.65 * smooth(0.3, 0.7, tn(R, S, (2, 4, 8), 0.6))
    mot_l = np.clip(mot * 0.6 + mot_soft * 0.8, 0, 1) * mvis
    col = col + mot_l[..., None] * glow * 0.45
    inc = sparkle_map(R, S, 500, 1.0, 2.6)
    col = col + inc[..., None] * 0.3
    specks = (R.random((S, S)) < 0.0015).astype(np.float32)
    col = col * (1 - 0.4 * gblur(specks, 0.7)[..., None])
    col = col + edges[..., None] * mix(light, C(1, 1, 1), 0.5) * 0.3
    h = hfn * 0.8 + veil * 0.015 - edges * 0.01
    col = finish(col, h, bake_s=7.0, k=0.45, ao=0.15, ao_r=6)
    save_surface(name, col, h, 3.5)
    e = glow * (mot_l[..., None] * 0.95 + 0.06 * smooth(0.2, 0.9, depth)[..., None] + edges[..., None] * 0.12)
    save_e(name, e)


def cristal_bleu():
    cristal("cristal_bleu")


def cristal_violet():
    cristal("cristal_violet")


def cristal_rose():
    cristal("cristal_rose")


def metal_lumen():
    """Métal blanc perle brossé (brossage horizontal, reflets nacrés à peine irisés), plaques de 1,5 m
    décalées, vis affleurantes à anneau ; dans les joints horizontaux, une rainure de lumière derrière
    un diffuseur dépoli. Émission (_e) : les rainures."""
    S = 1024
    R = rng(7615)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    br = tn(R, S, (2, 4, 8, 16, 32), 0.7, oy=(64, 128, 256, 512, 1024))
    br2 = tn(R, S, (8, 16, 32), 0.8, oy=(1024, 1024, 1024))
    low = tn(R, S, (2, 4, 8), 0.6)
    col = C(0.84, 0.84, 0.87) * (0.94 + 0.09 * br[..., None]) * (0.975 + 0.05 * br2[..., None])
    col = col * mix(C(1, 1, 1), iri(low * 1.4 + yy / S, 0.5), 0.1)
    PH = S / 2
    row = np.floor(yy / PH).astype(np.int32)
    vx = np.mod(xx - np.mod(row, 2) * S / 4, S / 2)
    dv = np.minimum(vx, S / 2 - vx)
    dyh = np.minimum(np.mod(yy, PH), PH - np.mod(yy, PH))
    pid = row * 2 + np.floor(np.mod(xx - np.mod(row, 2) * S / 4, S) / (S / 2)).astype(np.int32)
    col = col * per_id(pid, R, 0.96, 1.03)[..., None]
    vseam = smooth(2.0, 0.5, dv)
    chan = smooth(8.0, 6.5, dyh)
    lip = np.exp(-((dyh - 8.5) / 1.3) ** 2)
    col = col * (1 - 0.6 * vseam[..., None])
    diff = mix(C(0.8, 0.9, 1.0), C(0.95, 0.98, 1.0), np.exp(-(dyh / 2.5) ** 2))
    col = mix(col, diff, chan)
    col = col * (1 - 0.35 * lip[..., None])
    # vis affleurantes
    sc = np.zeros((S, S), np.float32)
    ring = np.zeros((S, S), np.float32)
    for r_ in range(2):
        for k in range(2):
            x0 = r_ * S / 4 + k * S / 2
            for dxp in (26, S / 2 - 26):
                for dyp in (26, PH - 26):
                    px, py = np.mod(x0 + dxp, S), r_ * PH + dyp
                    dd = np.hypot(np.mod(xx - px + S / 2, S) - S / 2, np.mod(yy - py + S / 2, S) - S / 2)
                    sc = np.maximum(sc, smooth(6.5, 5.0, dd))
                    ring = np.maximum(ring, np.exp(-((dd - 7.0) / 1.0) ** 2))
    col = mix(col, C(0.76, 0.77, 0.82), sc)
    col = col * (1 - 0.45 * ring[..., None])
    h = 0.6 - 0.5 * chan - 0.3 * vseam + 0.004 * br + 0.002 * br2 + 0.04 * sc - 0.1 * ring
    col = finish(col, h, bake_s=3.0, k=0.25, ao=0.25, ao_r=4)
    save_surface("metal_lumen", col, h, 3.0)
    e = C(0.62, 0.86, 1.0) * (chan * (0.55 + 0.45 * np.exp(-(dyh / 3.0) ** 2)))[..., None]
    save_e("metal_lumen", e)


def verre_holo():
    """Verre irisé (couches minces) : grandes nappes d'arc-en-ciel pastel qui ondulent sur un verre
    bleu nuit, micro-trame hexagonale gravée (≈ 12 cm), reflets en biais. Peut servir d'émission
    faible (la couleur entière) pour un verre qui « vibre »."""
    S = 1024
    R = rng(7616)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    th = tn(R, S, (1, 2, 4, 8), 0.6)
    th = warp(th, (tn(R, S, (2, 4, 8), 0.6) - 0.5) * 120, (tn(R, S, (2, 4, 8), 0.6) - 0.5) * 120)
    t = th * 3.2 + tn(R, S, (8, 16, 32), 0.6) * 0.3
    film = iri(t, 0.75)
    amt = 0.3 + 0.7 * smooth(0.2, 0.8, tn(R, S, (2, 4, 8), 0.6))
    col = C(0.3, 0.36, 0.48) + (film - 0.5) * (0.3 * amt)[..., None] + film * 0.08
    _, edge, _, _ = hexcells(S, 24, 28)
    line = np.exp(-(edge / 0.9) ** 2)
    col = col + line[..., None] * 0.1
    refl = 0.5 + 0.5 * np.sin(TAU * (xx + yy) / S * 2 + 1.0 + (th - 0.5) * 2)
    col = col + (smooth(0.8, 1.0, refl) * 0.07)[..., None]
    fine = tn(R, S, (128, 256, 512), 0.8)
    col = col * (0.98 + 0.04 * fine[..., None])
    h = 0.5 - 0.06 * line + 0.08 * th
    save_surface("verre_holo", col, h, 2.0)


def lumiere_motif():
    """Motifs de lumière lumens sur fond indigo presque noir : réseau de circuits (pistes orthogonales
    et biaises, nœuds annulaires), grands sceaux concentriques gradués, lignes de glyphes ; cyan,
    lavande et rose. ÉMISSIF tel quel (fond quasi noir)."""
    S, K = 1024, 2
    S2 = S * K
    R = rng(7617)
    pal = [np.array(c, np.float32) for c in ((0.45, 0.9, 1.0), (0.76, 0.6, 1.0), (1.0, 0.56, 0.86))]
    masks = [Image.new("L", (S2, S2), 0) for _ in pal]
    draws = [ImageDraw.Draw(m) for m in masks]
    G = 4
    cs = S2 / G

    def wline(di, pts, w):
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
        r = max(max(xs) - min(xs), max(ys) - min(ys)) / 2 + w
        for ox, oy in offs(cx, cy, r, S2):
            draws[di].line([(x + ox, y + oy) for x, y in pts], fill=255, width=int(w), joint="curve")

    def wring(di, x, y, r, w, fill=False):
        for ox, oy in offs(x, y, r + w, S2):
            X, Y = x + ox, y + oy
            if fill:
                draws[di].ellipse((X - r, Y - r, X + r, Y + r), fill=255)
            else:
                draws[di].ellipse((X - r, Y - r, X + r, Y + r), outline=255, width=int(w))

    def warc(di, x, y, r, a0, a1, w):
        for ox, oy in offs(x, y, r + w, S2):
            X, Y = x + ox, y + oy
            draws[di].arc((X - r, Y - r, X + r, Y + r), a0, a1, fill=255, width=int(w))
    nodes = {}
    for gy in range(G):
        for gx in range(G):
            nodes[(gx, gy)] = ((gx + 0.5) * cs + R.uniform(-cs * 0.2, cs * 0.2), (gy + 0.5) * cs + R.uniform(-cs * 0.2, cs * 0.2))
    # pistes entre voisins (droite et bas, en boucle) : un coude à 45°
    for (gx, gy), (x, y) in nodes.items():
        for dx_, dy_ in ((1, 0), (0, 1)):
            if R.random() < 0.25:
                continue
            nx_, ny_ = nodes[((gx + dx_) % G, (gy + dy_) % G)]
            nx_ += S2 if gx + dx_ >= G else 0
            ny_ += S2 if gy + dy_ >= G else 0
            di = int(R.integers(3))
            for lane in ([0] if R.random() < 0.5 else [-12 * K, 12 * K]):
                if dx_:
                    mx = x + (nx_ - x) * R.uniform(0.3, 0.7)
                    j = abs(ny_ - y)
                    pts = [(x, y + lane), (mx - j / 2, y + lane), (mx + j / 2, ny_ + lane), (nx_, ny_ + lane)]
                else:
                    my = y + (ny_ - y) * R.uniform(0.3, 0.7)
                    j = abs(nx_ - x)
                    pts = [(x + lane, y), (x + lane, my - j / 2), (nx_ + lane, my + j / 2), (nx_ + lane, ny_)]
                wline(di, pts, 3.6 * K)
            # petits points le long de la piste
            for k in range(int(R.integers(2, 6))):
                t = R.uniform(0.2, 0.8)
                px, py = x + (nx_ - x) * t, y + (ny_ - y) * t
                if R.random() < 0.3:
                    wring(di, px, py, 3.0 * K, 1, fill=True)
    # nœuds et sceaux
    for (gx, gy), (x, y) in nodes.items():
        di = int(R.integers(3))
        if R.random() < 0.35:
            r0 = R.uniform(70, 100) * K
            wring(di, x, y, r0, 3.4 * K)
            wring(di, x, y, r0 * 0.72, 2.4 * K)
            a0 = R.uniform(0, 360)
            for j in range(3):
                warc((di + 1) % 3, x, y, r0 * 0.86, a0 + j * 120, a0 + j * 120 + 70, 5.0 * K)
            for j in range(24):
                a = math.radians(j * 15)
                L = (10 if j % 3 == 0 else 5) * K
                wline(di, [(x + math.cos(a) * r0, y + math.sin(a) * r0), (x + math.cos(a) * (r0 + L), y + math.sin(a) * (r0 + L))], 2.4 * K)
            wring(di, x, y, 9 * K, 1, fill=True)
            wring((di + 2) % 3, x, y, 22 * K, 3.0 * K)
        else:
            wring(di, x, y, R.uniform(14, 24) * K, 3.4 * K)
            wring(di, x, y, 5 * K, 1, fill=True)
    # lignes de glyphes (petits signes lumens) : cercles, barres, demi-lunes
    for _ in range(18):
        x, y = R.random(2) * S2
        di = int(R.integers(3))
        horiz = R.random() < 0.6
        for k in range(int(R.integers(5, 11))):
            gx_, gy_ = (x + k * 22 * K, y) if horiz else (x, y + k * 22 * K)
            kind = int(R.integers(4))
            s = 7 * K
            if kind == 0:
                wring(di, gx_, gy_, s, 2.2 * K)
            elif kind == 1:
                wline(di, [(gx_, gy_ - s), (gx_, gy_ + s)], 2.6 * K)
                wring(di, gx_, gy_ - s, 1.8 * K, 1, fill=True)
            elif kind == 2:
                warc(di, gx_, gy_, s, 200, 340, int(2.4 * K))
                wring(di, gx_, gy_ + 2 * K, 1.6 * K, 1, fill=True)
            else:
                wline(di, [(gx_ - s, gy_ + s), (gx_, gy_ - s), (gx_ + s, gy_ + s)], 2.4 * K)
    ms = [down(np.asarray(m, np.float32) / 255.0, K) for m in masks]
    light = sum(m[..., None] * c for m, c in zip(ms, pal))
    anyl = np.clip(sum(ms), 0, 1)
    fine = tn(R, S, (32, 64, 128, 256), 0.7)
    gr = grain(R, S, 0.7)
    bg = C(0.03, 0.03, 0.07) * (0.85 + 0.3 * fine[..., None]) * (0.9 + 0.2 * gr[..., None])
    halo = gblur(light, 3.5)
    col = bg * (1 - anyl[..., None]) + light * 0.75 + anyl[..., None] * 0.25 + halo * 0.55
    h = 0.5 - 0.25 * gblur(anyl, 1.0) + 0.01 * fine
    save_surface("lumiere_motif", col, h, 3.0)


def coque_soucoupe():
    """Coque de soucoupe : plaques d'alliage argenté (rangées de 75 cm, longueurs variées), légère
    déformation des plaques, rangées de rivets, teinte de chauffe bleu-violet par endroits, traînées
    de vol ; quelques plaques portent un feu de position rond (ambre ou cyan) ou une grille.
    Émission (_e) : les feux."""
    S = 1024
    R = rng(7618)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    bid, e, u, v = masonry(R, S, [256] * 4, 240, 440, rr=8)
    tone = per_id(bid, R, 0.9, 1.06)
    n = tn(R, S, (4, 8, 16, 32), 0.6)
    fine = tn(R, S, (64, 128, 256, 512), 0.75)
    fl = tn(R, S, (2, 4, 8, 16), 0.7, oy=(16, 32, 64, 128))
    col = C(0.68, 0.7, 0.75) * tone[..., None] * (0.94 + 0.1 * n[..., None]) * (0.97 + 0.05 * fine[..., None])
    heat = smooth(0.58, 0.85, tn(R, S, (2, 4, 8, 16), 0.6))
    heatc = mix(C(0.95, 0.85, 0.6), C(0.62, 0.58, 0.95), smooth(0.3, 0.7, n))
    col = mix(col, col * heatc * 1.05, heat * 0.3)
    col = col * (1 - 0.12 * smooth(0.55, 0.9, fl)[..., None])
    bulge = np.sin(np.pi * u) * np.sin(np.pi * v)
    seam = smooth(2.2, 0.6, e)
    lip = np.exp(-((e - 3.0) / 1.2) ** 2)
    col = col * (1 - 0.65 * seam[..., None]) * (1 + 0.08 * lip[..., None])
    # rivets (rangées horizontales près des joints de rangées)
    riv = np.zeros((S, S), np.float32)
    step = S / 40
    for ry in range(4):
        for yo in (11.0, 245.0):
            py = ry * 256 + yo
            dyy = yy - py
            dxx = np.mod(xx, step) - step / 2
            dd = np.hypot(dxx, dyy)
            riv = np.maximum(riv, np.sqrt(np.clip(1 - (dd / 4.0) ** 2, 0, 1)))
    col = mix(col, C(0.78, 0.8, 0.85) * (0.8 + 0.3 * riv[..., None]), (riv > 0) * 0.9)
    # feux et grilles sur quelques plaques
    lights = np.zeros((S, S, 3), np.float32)
    grille = np.zeros((S, S), np.float32)
    ub = np.unique(bid)
    for b in ub:
        m = bid == b
        rr_ = R.random()
        if rr_ < 0.4:
            ys, xs_ = np.nonzero(m)
            cy = ys.mean()
            # centre robuste (la plaque peut passer le bord : on prend la position modulo)
            ang = np.angle(np.exp(1j * xs_ / S * TAU).mean())
            cx = np.mod(ang / TAU * S, S)
            dd = np.hypot(np.mod(xx - cx + S / 2, S) - S / 2, yy - cy)
            lc = C(1.0, 0.72, 0.3) if R.random() < 0.5 else C(0.4, 0.9, 1.0)
            core = smooth(9.0, 7.0, dd)
            ringm = np.exp(-((dd - 11.0) / 1.4) ** 2)
            col = mix(col, mix(lc, C(1, 1, 1), 0.5), core)
            col = col * (1 - 0.5 * ringm[..., None])
            lights += lc * (core + 0.5 * np.exp(-(dd / 14.0) ** 2))[..., None]
        elif rr_ < 0.52:
            ys, xs_ = np.nonzero(m)
            cy = ys.mean()
            ang = np.angle(np.exp(1j * xs_ / S * TAU).mean())
            cx = np.mod(ang / TAU * S, S)
            gxm = np.abs(np.mod(xx - cx + S / 2, S) - S / 2) < 40
            gym = np.abs(yy - cy) < 22
            slots = (np.mod(yy - cy + 22, 8) < 4)
            grille = np.maximum(grille, (gxm & gym & slots).astype(np.float32))
    col = col * (1 - 0.7 * gblur(grille, 0.6)[..., None])
    h = 0.5 + 0.06 * bulge - 0.4 * seam + 0.05 * lip + 0.25 * riv - 0.2 * grille + 0.005 * fine
    col = finish(col, h, bake_s=3.0, k=0.3, ao=0.3, ao_r=4)
    save_surface("coque_soucoupe", col, h, 3.0)
    save_e("coque_soucoupe", lights)


def bati():
    for f in (nacre_mur, cristal_bleu, cristal_violet, cristal_rose, metal_lumen, verre_holo, lumiere_motif, coque_soucoupe):
        f()


# =================================================================== hologrammes (512 x 512, fond noir)

FONTS.update({
    "disp": ["/usr/share/fonts/opentype/inter/InterDisplay-Medium.otf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"],
    "dispb": ["/usr/share/fonts/opentype/inter/InterDisplay-SemiBold.otf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"],
    "displ": ["/usr/share/fonts/opentype/inter/InterDisplay-Light.otf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"],
    "pm": ["/usr/share/fonts/truetype/google-fonts/Poppins-Medium.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"],
    "math": ["/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"],
    "mathb": ["/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"],
})


class Holo:
    """Une image de lumière : des calques (une couleur chacun) dessinés 2x, composés en additif sur un
    fond presque noir, avec halo doux et lignes de balayage. Utilisable telle quelle comme émission."""
    PAL = {"c": (0.42, 0.88, 1.0), "v": (0.76, 0.6, 1.0), "r": (1.0, 0.56, 0.84), "o": (1.0, 0.8, 0.42),
           "w": (0.86, 0.93, 1.0), "g": (0.5, 1.0, 0.7)}

    def __init__(self, W=512, H=512, K=2):
        self.W, self.H, self.K = W, H, K
        self.L = {k: Image.new("L", (W * K, H * K), 0) for k in self.PAL}
        self.D = {k: ImageDraw.Draw(m) for k, m in self.L.items()}
        self.acc = np.zeros((H * K, W * K, 3), np.float32)

    def _p(self, pts):
        return [(x * self.K, y * self.K) for x, y in pts]

    def _w(self, w):
        return max(1, int(round(w * self.K)))

    def line(self, k, pts, w=1.5, v=255):
        self.D[k].line(self._p(pts), fill=int(v), width=self._w(w), joint="curve")

    def ring(self, k, x, y, rx, ry=None, w=1.5, v=255):
        ry = rx if ry is None else ry
        K = self.K
        self.D[k].ellipse(((x - rx) * K, (y - ry) * K, (x + rx) * K, (y + ry) * K), outline=int(v), width=self._w(w))

    def disk(self, k, x, y, r, v=255):
        K = self.K
        self.D[k].ellipse(((x - r) * K, (y - r) * K, (x + r) * K, (y + r) * K), fill=int(v))

    def arc(self, k, x, y, r, a0, a1, w=1.5, v=255, ry=None):
        K = self.K
        ry = r if ry is None else ry
        self.D[k].arc(((x - r) * K, (y - ry) * K, (x + r) * K, (y + ry) * K), a0, a1, fill=int(v), width=self._w(w))

    def poly(self, k, pts, v=255, ol=None, w=1.5):
        q = self._p(pts)
        if v:
            self.D[k].polygon(q, fill=int(v))
        if ol:
            self.D[k].line(q + [q[0]], fill=int(ol), width=self._w(w), joint="curve")

    def dashed(self, k, pts, w=1.2, dash=6.0, gap=5.0, v=255):
        acc, on = 0.0, True
        for (x0, y0), (x1, y1) in zip(pts[:-1], pts[1:]):
            L = math.hypot(x1 - x0, y1 - y0)
            t = 0.0
            while t < L:
                step = min((dash if on else gap) - acc, L - t)
                if on:
                    a, b = t / L, (t + step) / L
                    self.line(k, [(x0 + (x1 - x0) * a, y0 + (y1 - y0) * a), (x0 + (x1 - x0) * b, y0 + (y1 - y0) * b)], w, v)
                t += step
                acc += step
                if acc >= (dash if on else gap) - 1e-6:
                    acc, on = 0.0, not on

    def text(self, k, xy, s, kind, size, v=255, anchor="mm", spacing=0.0):
        f = ff(kind, size * self.K)
        d = self.D[k]
        x, y = xy[0] * self.K, xy[1] * self.K
        if spacing:
            tw = sum(d.textlength(ch, font=f) for ch in s) + spacing * self.K * (len(s) - 1)
            cx = x - tw / 2 if anchor[0] == "m" else (x - tw if anchor[0] == "r" else x)
            for ch in s:
                d.text((cx, y), ch, font=f, fill=int(v), anchor="l" + anchor[1])
                cx += d.textlength(ch, font=f) + spacing * self.K
        else:
            d.text((x, y), s, font=f, fill=int(v), anchor=anchor)

    def cut(self, k, box):
        K = self.K
        self.D[k].rectangle(tuple(c * K for c in box), fill=0)

    def grid_xy(self):
        yy, xx = np.mgrid[0:self.H * self.K, 0:self.W * self.K].astype(np.float32)
        return xx / self.K, yy / self.K

    def result(self, bg=(0.012, 0.016, 0.035), scan=True, halo=1.0):
        from scipy import ndimage
        light = down(self.acc, self.K)
        for k, m in self.L.items():
            light = light + down(np.asarray(m, np.float32) / 255.0, self.K)[..., None] * np.array(self.PAL[k], np.float32)
        hl = np.dstack([ndimage.gaussian_filter(light[..., c], 2.5, mode="constant") * 0.5
                        + ndimage.gaussian_filter(light[..., c], 10.0, mode="constant") * 0.35 for c in range(3)])
        out = light + hl * halo
        if scan:
            y = np.arange(self.H, dtype=np.float32)
            out = out * (0.84 + 0.16 * (np.mod(y, 3) > 0.5))[:, None, None]
        R = rng(self.W * 7 + self.H)
        g = grain(R, max(self.W, self.H), 0.8)[:self.H, :self.W]
        return np.clip(np.array(bg, np.float32) * (0.8 + 0.4 * g[..., None]) + out, 0, 1)


def _corners(h, k="w", v=150, m=14, L=34, w=2.0):
    W, H = h.W, h.H
    for (x, y, sx, sy) in ((m, m, 1, 1), (W - m, m, -1, 1), (m, H - m, 1, -1), (W - m, H - m, -1, -1)):
        h.line(k, [(x, y + sy * L), (x, y), (x + sx * L, y)], w, v)


def holo_1():
    """La planète Ondelune (océans de vagues de lumière, anneau, deux lunes) et sa fiche."""
    h = Holo()
    R = rng(7631)
    _corners(h)
    h.text("c", (256, 38), "ONDELUNE", "dispb", 30, spacing=7)
    h.text("v", (256, 66), "planète natale des Lumens", "displ", 15, 220)
    cx, cy, Rp = 256, 262, 118
    # anneau, moitié arrière (cachée par la planète)
    for k_, (rx, ry, w) in enumerate(((212, 44, 3.0), (196, 40, 1.4), (226, 48, 1.2))):
        h.arc("o", cx, cy, rx, 180, 360, w, 230 - k_ * 40, ry=ry)
    h.disk("o", cx, cy, Rp, 0)
    # la planète (champ numérique : bord lumineux, vagues)
    xx, yy = h.grid_xy()
    dx, dy = (xx - cx) / Rp, (yy - cy) / Rp
    d = np.hypot(dx, dy)
    inside = smooth(1.0, 0.985, d)
    rim = smooth(0.7, 1.0, d) * 0.55
    waves = 0.5 + 0.5 * np.sin((dy * Rp + 9 * np.sin(dx * 7 + dy * 3)) / 7.0)
    lit = np.clip(0.75 - 0.5 * (dx * 0.6 + dy * 0.5), 0, 1)
    val = (rim + waves * 0.22 * lit + 0.06) * inside
    colp = mix(C(0.42, 0.88, 1.0), C(0.76, 0.6, 1.0), smooth(-0.8, 0.9, dy + dx * 0.3))
    h.acc += colp * val[..., None]
    for k_ in range(1, 6):
        lat = -math.pi / 2 + k_ * math.pi / 6
        yv = cy + math.sin(lat) * Rp
        hw = math.cos(lat) * Rp
        h.arc("c", cx, yv, hw, 0, 180, 1.0, 110, ry=hw * 0.18)
    for k_ in range(1, 6):
        rx = Rp * abs(math.cos(k_ * math.pi / 6))
        h.ring("c", cx, cy, max(rx, 1), Rp, 1.0, 90)
    h.ring("c", cx, cy, Rp, None, 2.2, 255)
    # anneau, moitié avant
    for k_, (rx, ry, w) in enumerate(((212, 44, 3.0), (196, 40, 1.4), (226, 48, 1.2))):
        h.arc("o", cx, cy, rx, 0, 180, w, 255 - k_ * 40, ry=ry)
    # lunes et orbites
    h.dashed("w", rell(cx, cy, 214, 168, -18, 120), 1.0, 5, 6, 120)
    h.disk("w", 92, 150, 15, 120)
    h.ring("w", 92, 150, 15, None, 2.0, 255)
    h.text("w", (92, 182), "Pipa", "disp", 13, 210)
    h.disk("r", 436, 372, 10, 130)
    h.ring("r", 436, 372, 10, None, 2.0, 255)
    h.text("r", (436, 400), "Lou", "disp", 13, 210)
    for k_, s_ in enumerate(("distance : 4 300 années-lumière", "climat : doux, avec vagues de lumière", "habitants partis en vacances : nous")):
        h.text("c", (30, 436 + k_ * 20), s_, "disp", 13, 200, anchor="lm")
    for k_ in range(3):
        h.arc("v", 462, 70, 22 + k_ * 7, -90 + k_ * 40, 120 + k_ * 50, 2.0, 220)
    # étoiles du fond
    for _ in range(80):
        x, y = R.uniform(20, 492), R.uniform(80, 420)
        if math.hypot(x - cx, y - cy) > Rp + 12:
            h.disk("w", x, y, R.uniform(0.5, 1.4), R.uniform(80, 200))
    save_rgb(h.result(), "holo_1.png")


def holo_2():
    """Le tableau d'équations du Professeur Quasar (dont une, ratée, barrée) : graphique, triangle."""
    h = Holo()
    _corners(h)
    h.text("w", (256, 34), "ACADÉMIE DES SCIENCES · TABLEAU 7", "disp", 15, 200, spacing=2)
    h.line("w", [(60, 50), (452, 50)], 1.0, 120)
    h.text("c", (40, 96), "E = mc²", "math", 36, anchor="lm")
    h.text("v", (250, 92), "∑ étoiles ÷ 2 = ∞", "math", 22, anchor="lm")
    h.text("w", (40, 160), "∫ lune · dt = 42", "math", 26, anchor="lm")
    h.text("o", (290, 150), "π ≈ 3,14159…", "math", 24, anchor="lm")
    h.text("r", (40, 224), "Pied-Lourd × thé = ami", "math", 25, anchor="lm")
    h.text("c", (318, 194), "√(nuage) ≈ pluie", "math", 18, 220, anchor="lm")
    h.text("o", (40, 284), "2 + 2 = 5", "mathb", 26, anchor="lm")
    h.line("r", [(32, 296), (170, 272)], 3.0)
    h.text("r", (186, 286), "← oups", "disp", 16, 230, anchor="lm")
    h.text("v", (300, 270), "g(Astralys) = g ÷ 3", "math", 18, 230, anchor="lm")
    # graphique
    ox, oy = 286, 456
    h.line("w", [(ox, oy), (486, oy)], 1.6, 200)
    h.line("w", [(ox, oy), (ox, 320)], 1.6, 200)
    h.line("w", [(480, oy - 5), (488, oy), (480, oy + 5)], 1.6, 200)
    h.line("w", [(ox - 5, 328), (ox, 320), (ox + 5, 328)], 1.6, 200)
    pts = [(ox + t, oy - 60 - 42 * math.sin(t / 22.0) * math.exp(-t / 260.0)) for t in np.linspace(0, 190, 80)]
    h.line("c", pts, 2.2)
    for t in range(10, 190, 30):
        h.disk("o", ox + t, oy - 60 - 42 * math.sin(t / 22.0) * math.exp(-t / 260.0), 3.2)
    h.text("w", (ox + 100, oy + 18), "humeur (temps)", "disp", 12, 180)
    # triangle et angle
    A, B, Cc = (50, 456), (220, 456), (70, 330)
    h.poly("g", [A, B, Cc], 0, ol=230, w=2.0)
    h.arc("g", A[0], A[1], 26, -82, 0, 1.6, 230)
    h.text("g", (134, 470), "a", "math", 15, 220)
    h.text("g", (48, 392), "b", "math", 15, 220)
    h.text("g", (156, 386), "c", "math", 15, 220)
    h.text("g", (90, 432), "θ", "math", 14, 220)
    save_rgb(h.result(), "holo_2.png")


def holo_3():
    """Carte du ciel des Lumens : cercle gradué, champ d'étoiles, cinq constellations à leur façon
    (la Théière, le Grand Glouglou, la Chaussette, le Pied-Lourd, la Méduse) et Ondelune."""
    h = Holo()
    R = rng(7633)
    cx, cy = 256, 262
    h.ring("c", cx, cy, 228, None, 2.0, 220)
    h.ring("c", cx, cy, 236, None, 1.0, 140)
    for k_ in range(72):
        a = math.radians(k_ * 5)
        L = 9 if k_ % 6 == 0 else 4
        h.line("c", [(cx + math.cos(a) * 228, cy + math.sin(a) * 228), (cx + math.cos(a) * (228 - L), cy + math.sin(a) * (228 - L))], 1.2, 200)
    for r_ in (70, 140, 200):
        h.ring("w", cx, cy, r_, None, 0.8, 60)
    for k_ in range(12):
        a = math.radians(k_ * 30)
        h.line("w", [(cx + math.cos(a) * 30, cy + math.sin(a) * 30), (cx + math.cos(a) * 220, cy + math.sin(a) * 220)], 0.7, 50)
    for s_, (x, y) in (("N", (cx, cy - 248)), ("S", (cx, cy + 250)), ("E", (cx + 248, cy)), ("O", (cx - 248, cy))):
        h.text("w", (x, y), s_, "dispb", 14, 230)
    for _ in range(320):
        a, r_ = R.uniform(0, TAU), 220 * math.sqrt(R.random())
        x, y = cx + math.cos(a) * r_, cy + math.sin(a) * r_
        h.disk("w", x, y, R.uniform(0.5, 1.6) if R.random() < 0.9 else R.uniform(1.6, 2.6), R.uniform(70, 230))
    CONS = [
        ("la Théière", "o", [(150, 150), (190, 140), (210, 170), (200, 205), (160, 210), (140, 185), (150, 150), (120, 168), (104, 160)],
         [(210, 170), (238, 150), (250, 132)]),
        ("le Grand Glouglou", "c", [(300, 120), (334, 108), (366, 120), (378, 150), (362, 178), (330, 186), (302, 172), (292, 146), (300, 120)], []),
        ("la Chaussette", "v", [(110, 270), (130, 270), (132, 330), (160, 352), (154, 370), (112, 362), (104, 336), (110, 270)], []),
        ("le Pied-Lourd", "r", [(330, 300), (338, 352), (384, 360), (400, 376), (340, 386), (318, 360), (330, 300)], []),
        ("la Méduse", "g", [(226, 380), (246, 362), (272, 362), (290, 380)], [(236, 384), (232, 420)]),
    ]
    for name, k, pts, extra in CONS:
        h.line(k, pts, 1.4, 200)
        if extra:
            h.line(k, extra, 1.4, 200)
        for (x, y) in pts + extra:
            h.disk(k, x, y, 2.6)
            h.disk("w", x, y, 1.3)
        if name == "la Méduse":
            for xo in (252, 266, 280):
                h.line(k, [(xo, 384), (xo + 4, 402), (xo - 2, 420)], 1.4, 200)
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        h.text(k, ((min(xs) + max(xs)) / 2, (436 if name == "la Méduse" else max(ys) + 16)), name, "disp", 13, 235)
    # Ondelune
    ox, oy = 410, 236
    h.disk("v", ox, oy, 6)
    h.arc("v", ox, oy, 13, 0, 360, 1.4, 230, ry=4)
    h.ring("v", ox, oy, 18, None, 1.0, 160)
    h.text("v", (ox, oy + 30), "Ondelune", "dispb", 14)
    h.dashed("v", [(ox - 18, oy + 6), (cx + 30, cy + 10)], 1.0, 4, 4, 150)
    h.text("w", (24, 24), "CARTE DU CIEL", "dispb", 15, 220, anchor="lm", spacing=2)
    h.text("w", (488, 24), "par Zénith", "displ", 13, 180, anchor="rm")
    save_rgb(h.result(), "holo_3.png")


def _island(R, cx, cy, r, n=11, el=1.0):
    pts = []
    for k_ in range(n):
        a = k_ / n * TAU
        rr = r * R.uniform(0.72, 1.12)
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr * el))
    return chaikin(pts, 3)


def holo_4():
    """L'archipel vu d'en haut (relevé de Sextant) : îles et courbes de niveau, routes des bateaux,
    Astralys au nord-ouest entre Arcanelle et les Trois Soleils, le rayon d'accueil et sa bouée."""
    h = Holo()
    R = rng(7634)
    _corners(h, "c", 140)
    for x in range(48, 480, 48):
        h.line("c", [(x, 50), (x, 470)], 0.6, 40)
    for y in range(50, 480, 42):
        h.line("c", [(24, y), (488, y)], 0.6, 40)
    isles = [("Arcanelle", 120, 300, 42, 0.8), ("Trois Soleils", 336, 96, 34, 0.9), ("Cliquetis", 410, 300, 58, 1.2),
             (None, 250, 250, 46, 0.85), (None, 220, 400, 30, 0.8), (None, 330, 420, 26, 1.0), (None, 90, 430, 22, 0.9),
             (None, 400, 170, 24, 0.9), (None, 300, 300, 16, 1.0), (None, 56, 196, 14, 1.0)]
    centers = []
    for name, x, y, r, el in isles:
        outline = _island(R, x, y, r, el=el)
        h.poly("g", outline, 30, ol=230, w=1.8)
        for s_ in (0.68, 0.4):
            h.line("g", [(x + (px - x) * s_, y + (py - y) * s_) for px, py in outline] + [(x + (outline[0][0] - x) * s_, y + (outline[0][1] - y) * s_)], 1.0, 150)
        centers.append((x, y))
        if name:
            h.text("w", (x, y + r * el + 16), name, "disp", 14, 230)
    for a, b in ((3, 0), (3, 2), (3, 4), (4, 5), (0, 6), (2, 7), (3, 1), (3, 8)):
        (x0, y0), (x1, y1) = centers[a], centers[b]
        mx, my = (x0 + x1) / 2 + R.uniform(-20, 20), (y0 + y1) / 2 + R.uniform(-20, 20)
        h.dashed("o", bez((x0, y0), (mx, my), (x1, y1), 20), 1.1, 5, 5, 150)
    # Astralys
    ax, ay = 150, 176
    h.poly("v", [(ax - 34, ay), (ax + 34, ay), (ax + 10, ay + 30), (ax, ay + 44), (ax - 12, ay + 28)], 60, ol=255, w=1.8)
    h.arc("v", ax, ay, 34, 0, 360, 2.0, 255, ry=9)
    h.line("v", [(ax, ay - 2), (ax, ay - 40)], 2.0)
    h.disk("r", ax, ay - 44, 4)
    for k_ in range(3):
        h.ring("r", ax, ay - 44, 9 + k_ * 7, None, 1.0, 200 - k_ * 50)
    h.text("v", (ax, ay - 74), "ASTRALYS", "dispb", 17, spacing=3)
    h.text("w", (ax + 64, ay + 2), "vous êtes ici", "displ", 12, 210, anchor="lm")
    h.dashed("w", [(ax + 36, ay + 2), (ax + 60, ay + 2)], 1.0, 3, 3, 200)
    bx, by = 196, 224
    h.dashed("c", [(ax + 8, ay + 40), (bx, by)], 1.6, 3, 3, 230)
    h.ring("c", bx, by, 4, None, 1.6)
    h.text("c", (bx - 8, by + 12), "bouée d'accueil", "displ", 12, 210, anchor="rm")
    # rose des vents
    rx_, ry_ = 446, 438
    h.ring("w", rx_, ry_, 22, None, 1.2, 180)
    h.poly("w", [(rx_, ry_ - 30), (rx_ + 6, ry_), (rx_, ry_ + 30), (rx_ - 6, ry_)], 120, ol=230, w=1.2)
    h.text("w", (rx_, ry_ - 40), "N", "dispb", 12)
    h.text("c", (24, 30), "L'ARCHIPEL", "dispb", 16, anchor="lm", spacing=3)
    h.text("c", (24, 50), "relevé de Sextant, vu d'en haut", "displ", 12, 200, anchor="lm")
    save_rgb(h.result(), "holo_4.png")


def holo_5():
    """Plan de la Flèche de Cristal (élévation filaire, 110 m), le Cœur qui pulse, sa courbe."""
    h = Holo()
    R = rng(7635)
    _corners(h)
    h.text("c", (256, 30), "FLÈCHE DE CRISTAL · PLAN", "dispb", 17, spacing=3)
    cx, base, top = 230, 400, 66
    hw = 46
    h.poly("c", [(cx - hw, base), (cx, top), (cx + hw, base)], 40, ol=255, w=2.0)
    h.line("c", [(cx, top + 20), (cx, base)], 1.0, 120)
    for k_ in range(1, 12):
        y = base - k_ * (base - top) / 12
        w_ = hw * (y - top) / (base - top)
        h.line("c", [(cx - w_, y), (cx + w_, y)], 1.0, 110)
    for sx in (-1, 1):
        h.poly("v", [(cx + sx * hw * 0.7, base), (cx + sx * (hw + 20), base - 120), (cx + sx * (hw + 26), base)], 30, ol=230, w=1.6)
        h.poly("v", [(cx + sx * (hw + 22), base), (cx + sx * (hw + 40), base - 60), (cx + sx * (hw + 50), base)], 20, ol=200, w=1.2)
    # le Cœur
    hy = 128
    h.disk("r", cx, hy, 9)
    for k_ in range(4):
        h.ring("r", cx, hy, 15 + k_ * 9, None, 1.4, 230 - k_ * 50)
    # sol, salle du Conseil, dessous
    h.line("w", [(70, base), (390, base)], 2.0, 220)
    h.poly("w", [(70, base), (390, base), (300, base + 40), (230, base + 70), (160, base + 36)], 25, ol=160, w=1.2)
    h.poly("o", [(cx - 70, base), (cx - 64, base - 24), (cx + 64, base - 24), (cx + 70, base)], 40, ol=240, w=1.6)
    # cotes et étiquettes
    xd = 420
    h.line("w", [(xd, top), (xd, base)], 1.2, 200)
    for y, s in ((top, 1), (base, -1)):
        h.line("w", [(xd - 5, y + s * 8), (xd, y), (xd + 5, y + s * 8)], 1.2, 200)
        h.line("w", [(xd - 10, y), (xd + 10, y)], 1.0, 160)
    h.text("w", (xd + 14, (top + base) / 2), "110 m", "dispb", 16, anchor="lm")
    for (lx, ly, tx, ty, s_, k) in ((cx + 40, hy, 300, 110, "Cœur de la Flèche", "r"), (cx - 70, base - 12, 24, 330, "Salle du Conseil", "o"),
                                    (cx + 18, 236, 300, 230, "Belvédère", "c")):
        if tx < cx:
            h.line(k, [(lx, ly), (tx + 118, ty + 8)], 1.0, 200)
        else:
            h.line(k, [(lx, ly), (tx - 6, ty)], 1.0, 200)
        h.text(k, (tx, ty), s_, "disp", 14, 235, anchor="lm")
    # courbe du cœur
    gx0, gy0 = 30, 470
    pts = []
    for k_ in range(220):
        t = k_ / 219
        x = gx0 + t * 452
        ph = (t * 5) % 1
        y = gy0 - (26 * math.exp(-((ph - 0.3) / 0.025) ** 2) - 9 * math.exp(-((ph - 0.38) / 0.03) ** 2) + 6 * math.exp(-((ph - 0.6) / 0.06) ** 2))
        pts.append((x, y))
    h.line("r", pts, 1.8)
    h.text("r", (482, 492), "72 pulsations par lune · un peu fatigué", "disp", 12, 220, anchor="rm")
    for _ in range(40):
        h.disk("w", R.uniform(20, 492), R.uniform(46, 380), R.uniform(0.5, 1.2), R.uniform(60, 160))
    save_rgb(h.result(), "holo_5.png")


def holo_6():
    """Le système de Lumiora (l'étoile d'Ondelune) : orbites inclinées, planètes, comète, et le trajet
    des Lumens « vers la Terre (vacances) »."""
    h = Holo()
    R = rng(7636)
    _corners(h, "o", 140)
    cx, cy = 236, 270
    h.disk("o", cx, cy, 16)
    h.disk("w", cx, cy, 8)
    for k_ in range(16):
        a = k_ / 16 * TAU
        L = 34 if k_ % 2 == 0 else 24
        h.line("o", [(cx + math.cos(a) * 22, cy + math.sin(a) * 22), (cx + math.cos(a) * L, cy + math.sin(a) * L)], 1.6, 220)
    orbits = [(70, 26, "c", None), (120, 46, "g", None), (176, 66, "v", "Ondelune"), (226, 88, "r", None)]
    for k_, (rx, ry, k, name) in enumerate(orbits):
        pts = rell(cx, cy, rx, ry, -14, 96)
        h.line(k, pts + [pts[0]], 1.2, 150)
        t = [1.0, 2.6, 5.3, 3.9][k_]
        px = cx + math.cos(t) * rx * math.cos(math.radians(-14)) - math.sin(t) * ry * math.sin(math.radians(-14))
        py = cy + math.cos(t) * rx * math.sin(math.radians(-14)) + math.sin(t) * ry * math.cos(math.radians(-14))
        h.disk(k, px, py, [4, 6, 8, 7][k_])
        if name:
            h.arc(k, px, py, 16, 0, 360, 1.4, 230, ry=5)
            h.text(k, (px, py + 26), name, "dispb", 14)
            for j, (mx, my) in enumerate(((px - 22, py - 14), (px + 24, py + 10))):
                h.disk("w", mx, my, 2.2)
            h.dashed("w", [(px + 10, py - 8), (430, 96), (476, 64)], 1.2, 6, 5, 220)
            h.line("w", [(466, 62), (478, 63), (472, 74)], 1.4, 230)
            h.text("w", (474, 46), "vers la Terre (vacances)", "disp", 13, 230, anchor="rm")
    # comète
    hx, hy = 110, 430
    for k_ in range(30):
        t = k_ / 29
        h.disk("c", hx - t * 70, hy + t * 34, 4.5 * (1 - t) + 0.6, 220 * (1 - t) + 20)
    h.disk("w", hx, hy, 3.5)
    h.text("o", (24, 24), "SYSTÈME DE LUMIORA", "dispb", 16, anchor="lm", spacing=3)
    h.text("o", (24, 44), "trajet : 4 300 années-lumière (avec escales)", "displ", 12, 200, anchor="lm")
    for _ in range(140):
        h.disk("w", R.uniform(10, 502), R.uniform(60, 500), R.uniform(0.4, 1.3), R.uniform(50, 170))
    save_rgb(h.result(), "holo_6.png")


def holo(k):
    globals()["holo_%d" % k]()


def holos():
    for k in range(1, 7):
        holo(k)


# =================================================================== enseignes (512 x 256, verre sombre)

def em_cafe(h, k, a, cx, cy):
    h.poly(k, chaikin([(cx - 30, cy - 4), (cx + 30, cy - 4), (cx + 24, cy + 30), (cx + 12, cy + 38), (cx - 12, cy + 38), (cx - 24, cy + 30)], 2), 50, ol=255, w=3.0)
    h.arc(k, cx + 32, cy + 12, 12, -80, 90, 3.0)
    h.arc(a, cx, cy + 42, 44, 0, 180, 2.4, ry=8)
    pts = [(cx + math.cos(t) * t * 2.4, cy - 30 + math.sin(t) * t * 1.4) for t in np.linspace(0.5, 4.2 * math.pi, 90)]
    h.line(a, pts, 2.2, 230)
    for (x, y) in ((cx - 30, cy - 46), (cx + 34, cy - 40), (cx + 4, cy - 62)):
        h.poly("w", star4(x, y, 6), 255)


def em_bazar(h, k, a, cx, cy):
    h.poly(k, [(cx - 32, cy - 10), (cx + 32, cy - 10), (cx + 28, cy + 40), (cx - 28, cy + 40)], 50, ol=255, w=3.0)
    h.arc(k, cx, cy - 10, 16, 180, 360, 3.0, ry=20)
    h.disk(a, cx + 26, cy - 34, 13, 120)
    h.ring(a, cx + 26, cy - 34, 13, None, 2.4)
    h.arc(a, cx + 26, cy - 34, 26, 0, 360, 2.0, 230, ry=6)
    h.poly("w", star4(cx - 6, cy + 14, 9), 255)


def em_musee(h, k, a, cx, cy):
    h.poly(k, [(cx - 22, cy + 6), (cx + 22, cy + 6), (cx + 18, cy + 38), (cx - 18, cy + 38)], 40, ol=255, w=2.6)
    h.line(k, [(cx - 30, cy + 6), (cx + 30, cy + 6)], 3.0)
    h.line(k, [(cx - 30, cy + 44), (cx + 30, cy + 44)], 3.0)
    for x in (cx - 8, cx + 8):
        h.line(k, [(x, cy + 12), (x, cy + 34)], 1.6, 200)
    h.disk(a, cx, cy - 16, 17, 130)
    h.ring(a, cx, cy - 16, 17, None, 2.6)
    for j in range(3):
        h.arc("w", cx, cy - 16, 28, 200 + j * 60, 230 + j * 60, 2.0)
    h.poly("w", star4(cx + 34, cy - 40, 7), 255)


def em_academie(h, k, a, cx, cy):
    for ang in (0, 60, 120):
        pts = rell(cx, cy, 44, 15, ang, 64)
        h.line(k, pts + [pts[0]], 2.4)
    h.disk(a, cx, cy, 8)
    for ang in (20, 140, 260):
        r = math.radians(ang)
        h.disk("w", cx + math.cos(r) * 44 * 0.75, cy + math.sin(r) * 30 * 0.6, 3.5)


def em_spatioport(h, k, a, cx, cy):
    h.arc(k, cx, cy - 6, 20, 180, 360, 2.6, ry=18)
    pts = rell(cx, cy, 46, 11, 0, 64)
    h.poly(k, pts, 60, ol=255, w=2.8)
    for j in range(5):
        h.disk(a, cx - 30 + j * 15, cy + 2, 2.6)
    for s in (-1, 1):
        h.line(a, [(cx + s * 16, cy + 14), (cx + s * 34, cy + 50)], 2.0, 170)
    for j in range(3):
        h.line(a, [(cx - 22 + j * 4, cy + 46 - j * 6), (cx + 22 - j * 4, cy + 46 - j * 6)], 1.4, 120 - j * 30)


def em_observatoire(h, k, a, cx, cy):
    h.arc(k, cx - 4, cy + 14, 32, 180, 360, 3.0, ry=28)
    h.line(k, [(cx - 40, cy + 14), (cx + 32, cy + 14)], 3.0)
    h.poly(k, [(cx - 34, cy + 14), (cx + 26, cy + 14), (cx + 26, cy + 40), (cx - 34, cy + 40)], 40, ol=255, w=2.6)
    h.line(a, [(cx - 2, cy - 4), (cx + 34, cy - 40)], 6.0)
    h.line(a, [(cx + 30, cy - 36), (cx + 40, cy - 46)], 9.0, 220)
    for (x, y, r) in ((cx - 32, cy - 38, 6), (cx + 6, cy - 54, 4.5), (cx + 44, cy - 10, 4)):
        h.poly("w", star4(x, y, r), 255)


def em_serre(h, k, a, cx, cy):
    h.arc(k, cx, cy + 34, 42, 180, 360, 3.0, ry=56)
    h.line(k, [(cx - 46, cy + 34), (cx + 46, cy + 34)], 3.0)
    for x in (-21, 0, 21):
        h.line(k, [(cx + x, cy + 34), (cx + x * 0.9, cy - 20 + abs(x) * 0.9)], 1.2, 140)
    h.arc(a, cx, cy + 4, 14, 180, 360, 2.6, ry=11)
    h.line(a, [(cx - 14, cy + 4), (cx + 14, cy + 4)], 2.0)
    for x in (-8, 0, 8):
        h.line(a, [(cx + x, cy + 6), (cx + x + 3, cy + 14), (cx + x - 2, cy + 22)], 1.6, 220)
    h.poly("g", leaf_poly(cx + 24, cy + 22, 26, 10, -0.9, 0.4), 120, ol=255, w=1.4)


ENSEIGNES = {
    "cafe": dict(k="r", a="o", l1="CAFÉ", l2="NÉBULEUSE", sub="thé stellaire · gelée cosmique · biscuits", em=em_cafe),
    "bazar": dict(k="o", a="v", l1="BAZAR", l2="GALACTIQUE", sub="de tout, de partout, pour tous", em=em_bazar),
    "musee": dict(k="v", a="c", l1="MUSÉE", l2="DES MONDES", sub="les trésors de toutes les îles", em=em_musee),
    "academie": dict(k="c", a="w", l1="ACADÉMIE", l2="DES SCIENCES", sub="on rate, on recommence, on apprend", em=em_academie),
    "spatioport": dict(k="w", a="c", l1="", l2="SPATIOPORT", sub="départs · arrivées · soucoupes", em=em_spatioport),
    "observatoire": dict(k="c", a="v", l1="", l2="OBSERVATOIRE", sub="les étoiles, de tout près", em=em_observatoire),
    "serre": dict(k="g", a="c", l1="SERRE", l2="DES ESPÈCES", sub="ne pas nourrir les glouglous", em=em_serre),
}


def enseigne(key):
    """Enseigne lumen : plaque de verre sombre (trame hexagonale à peine visible) dans un cadre de métal
    perle, filet de lumière, emblème en tubes de lumière à gauche, titre en capitales espacées dont le
    grand mot est fendu d'une fine ligne (lettrage « lumen »), sous-titre. Émissive telle quelle."""
    E = ENSEIGNES[key]
    W, H = 512, 256
    h = Holo(W, H)
    k, a = E["k"], E["a"]
    # verre et cadre (dans le champ numérique)
    xx, yy = h.grid_xy()
    S2 = max(W, H) * h.K
    _, edge, _, _ = hexcells(S2, 32, 36)
    hexl = np.exp(-(edge[:H * h.K, :W * h.K] / 1.0) ** 2)
    ed = _round_edge(xx, yy, W, H, 26.0)
    frame = smooth(13.0, 11.0, ed)
    glass = C(0.03, 0.028, 0.07) + C(0.02, 0.01, 0.04) * (1 - yy / H)[..., None]
    h.acc += glass * (1 - frame)[..., None] + hexl[..., None] * (1 - frame)[..., None] * C(0.02, 0.025, 0.04)
    h.acc += C(0.09, 0.09, 0.11) * (frame * (0.5 + 0.5 * np.sin(np.clip(ed / 12, 0, 1) * math.pi)))[..., None]
    inner = _round_edge(xx - 18, yy - 18, W - 36, H - 36, 16.0)
    h.acc += np.array(Holo.PAL[a], np.float32) * (np.exp(-(inner / 0.9) ** 2) * (xx > 18) * (xx < W - 18) * (yy > 18) * (yy < H - 18) * 0.55)[..., None]
    # emblème
    E["em"](h, k, a, 84, 126)
    h.line(a, [(150, 64), (150, 192)], 1.6, 200)
    for y in (64, 192):
        h.disk(a, 150, y, 3.0)
    # titre
    tx = 326
    if E["l1"]:
        h.text(a, (tx, 70), E["l1"], "pm", 24, 235, spacing=9)
        y2, size = 122, fit_size(E["l2"], "pm", 50, 286, 3)
    else:
        y2, size = 106, fit_size(E["l2"], "pm", 56, 286, 3)
    h.text(k, (tx, y2), E["l2"], "pm", size, spacing=3)
    f = ff("pm", size * h.K)
    bb = h.D[k].textbbox((tx * h.K, y2 * h.K), E["l2"], font=f, anchor="mm")
    top, bot = bb[1] / h.K, bb[3] / h.K
    ys = top + (bot - top) * 0.56
    h.cut(k, (160, ys - 0.9, 500, ys + 0.9))
    h.line(a, [(tx - 150, bot + 12), (tx - 40, bot + 12)], 1.2, 160)
    h.line(a, [(tx + 40, bot + 12), (tx + 150, bot + 12)], 1.2, 160)
    h.disk(a, tx, bot + 12, 2.6)
    sub_size = fit_size(E["sub"], "disp", 16, 290, 1)
    h.text("w", (tx, bot + 38), E["sub"], "disp", sub_size, 215, spacing=1)
    col = h.result(bg=(0.0, 0.0, 0.0), scan=False, halo=0.8)
    save_rgb(col, "enseigne_%s.png" % key)


def enseignes():
    for k in ENSEIGNES_V76:
        enseigne(k)


# =================================================================== fresques lumens (1024 x 512, sur la nacre)

def _sh(c, f):
    return tuple(int(np.clip(v * f, 0, 255)) for v in c)


def lumen_fig(pa, x, base, s, skin, robe, accent, hands=None, crest=True, hat=None):
    """Un Lumen debout (≈ 330 px pour s = 1.25) : longue robe, cou fin, grand crâne, grands yeux en
    amande, crête de cristal ou antennes à boules de lumière ; hands = cibles des deux mains."""
    sh_y = base - 200 * s
    head_y = base - 262 * s
    pa.glow(x, base - 150 * s, 100 * s, _sh(skin, 0.5), 0.16)
    robe_pts = chaikin([(x - 22 * s, sh_y), (x + 22 * s, sh_y), (x + 36 * s, base - 100 * s), (x + 60 * s, base - 4 * s),
                        (x + 30 * s, base + 3 * s), (x, base - 3 * s), (x - 30 * s, base + 3 * s), (x - 60 * s, base - 4 * s),
                        (x - 36 * s, base - 100 * s)], 2)
    shape(pa, robe_pts, robe, ol=2.4, shade=0.6, depth=10 * s)
    for k in range(3):
        t = 0.35 + k * 0.22
        yv = sh_y + (base - sh_y) * t
        hw = 22 * s + (40 * s) * t
        pa.line(bez((x - hw, yv), (x, yv + 8 * s), (x + hw, yv), 10), _sh(robe, 1.25), 1.6 * s, alpha=0.6)
    pa.line(bez((x - 34 * s, base - 108 * s), (x, base - 100 * s), (x + 34 * s, base - 108 * s), 10), accent, 4.5 * s)
    shape(pa, rell(x, sh_y + 26 * s, 6 * s, 7 * s), accent, ol=1.4, shade=0.2)
    pa.glow(x, sh_y + 26 * s, 12 * s, accent, 0.5)
    stroke(pa, [(x, sh_y + 6 * s), (x, head_y + 28 * s)], 13 * s, skin, 11 * s, ol=2.0)
    for side, tgt in zip((-1, 1), hands or (None, None)):
        sx0, sy0 = x + side * 20 * s, sh_y + 10 * s
        tx, ty = tgt or (x + side * 44 * s, base - 108 * s)
        mid = ((sx0 + tx) / 2 + side * 10 * s, (sy0 + ty) / 2 + 12 * s)
        stroke(pa, bez((sx0, sy0), mid, (tx, ty), 8), 14 * s, _sh(robe, 1.1), 8 * s, ol=2.2)
        shape(pa, rell(tx, ty, 8 * s, 7 * s), skin, ol=1.8, shade=0.3)
    union(pa, [rell(x, head_y, 29 * s, 37 * s), rell(x, head_y - 16 * s, 34 * s, 27 * s)], skin, ol=2.6, shade=0.6, depth=10 * s)
    for side in (-1, 1):
        shape(pa, rell(x + side * 13 * s, head_y + 1 * s, 8.5 * s, 12.5 * s, -side * 20), (34, 28, 70), ol=1.4, shade=0.2)
        shape(pa, rell(x + side * 11 * s, head_y - 4 * s, 3 * s, 3.6 * s), (255, 255, 255), ol=0, shade=0)
        shape(pa, rell(x + side * 21 * s, head_y + 16 * s, 6 * s, 3.5 * s), _sh(accent, 1.0), ol=0, shade=0, alpha=0.35)
    pa.line(bez((x - 7 * s, head_y + 21 * s), (x, head_y + 27 * s), (x + 7 * s, head_y + 21 * s), 8), INK, 2.0 * s)
    if hat:
        shape(pa, rell(x, head_y - 30 * s, 60 * s, 12 * s), hat, ol=2.2, shade=0.4)
        shape(pa, chaikin([(x - 30 * s, head_y - 30 * s), (x - 24 * s, head_y - 62 * s), (x + 24 * s, head_y - 62 * s), (x + 30 * s, head_y - 30 * s)], 2),
              hat, ol=2.2, shade=0.5)
        shape(pa, [(x - 28 * s, head_y - 40 * s), (x + 28 * s, head_y - 40 * s), (x + 29 * s, head_y - 33 * s), (x - 29 * s, head_y - 33 * s)], accent, ol=1.2)
    elif crest:
        for k, (dx, hh) in enumerate(((-16, 26), (0, 40), (16, 26))):
            bx = x + dx * s
            by = head_y - 38 * s + abs(dx) * 0.4 * s
            shape(pa, [(bx - 7 * s, by + 6 * s), (bx, by - hh * s), (bx + 7 * s, by + 6 * s)], accent, ol=1.8, shade=0.5)
        pa.glow(x, head_y - 60 * s, 26 * s, accent, 0.35)
    else:
        for side in (-1, 1):
            p = bez((x + side * 10 * s, head_y - 38 * s), (x + side * 22 * s, head_y - 76 * s), (x + side * 40 * s, head_y - 80 * s), 12)
            pa.line(p, _sh(skin, 0.8), 3.0 * s)
            shape(pa, rell(p[-1][0], p[-1][1], 6 * s, 6 * s), accent, ol=1.4, shade=0.2)
            pa.glow(p[-1][0], p[-1][1], 14 * s, accent, 0.5)
    shape(pa, star4(x, head_y - 18 * s, 6 * s, 0.4), accent, ol=1.0, shade=0)


def pied_lourd(pa, x, base, s, skin, top, pants, hair, hands=None, R=None):
    """Un Pied-Lourd (un humain, ≈ 210 px pour s = 1.1) : grosses chaussures, tête ronde, joues roses."""
    hip_y, sh_y, head_y = base - 72 * s, base - 140 * s, base - 172 * s
    for side in (-1, 1):
        stroke(pa, [(x + side * 12 * s, hip_y), (x + side * 15 * s, base - 22 * s)], 20 * s, pants, 18 * s, ol=2.2)
        shape(pa, rell(x + side * 20 * s, base - 9 * s, 24 * s, 13 * s), (96, 64, 44), ol=2.4, shade=0.6)
        pa.line([(x + side * 20 * s - 20 * s, base - 1 * s), (x + side * 20 * s + 20 * s, base - 1 * s)], (50, 34, 26), 3 * s)
    shape(pa, chaikin([(x - 28 * s, sh_y), (x + 28 * s, sh_y), (x + 34 * s, hip_y + 8 * s), (x - 34 * s, hip_y + 8 * s)], 2), top, ol=2.4, shade=0.6, depth=8 * s)
    for side, tgt in zip((-1, 1), hands or (None, None)):
        sx0, sy0 = x + side * 26 * s, sh_y + 8 * s
        tx, ty = tgt or (x + side * 40 * s, base - 70 * s)
        mid = ((sx0 + tx) / 2 + side * 6 * s, (sy0 + ty) / 2 + 8 * s)
        stroke(pa, bez((sx0, sy0), mid, (tx, ty), 8), 15 * s, top, 12 * s, ol=2.2)
        shape(pa, rell(tx, ty, 8.5 * s, 7.5 * s), skin, ol=1.8, shade=0.3)
    shape(pa, rell(x, head_y, 27 * s, 29 * s), skin, ol=2.6, shade=0.5, depth=8 * s)
    shape(pa, chaikin([(x - 28 * s, head_y - 2 * s), (x - 24 * s, head_y - 26 * s), (x, head_y - 34 * s), (x + 24 * s, head_y - 26 * s),
                       (x + 28 * s, head_y - 2 * s), (x + 14 * s, head_y - 16 * s), (x - 10 * s, head_y - 14 * s)], 2), hair, ol=2.0, shade=0.4)
    for side in (-1, 1):
        shape(pa, rell(x + side * 10 * s, head_y + 2 * s, 3 * s, 3.6 * s), INK, ol=0, shade=0)
        shape(pa, rell(x + side * 17 * s, head_y + 11 * s, 6 * s, 3.5 * s), (240, 120, 130), ol=0, shade=0, alpha=0.5)
    pa.line(bez((x - 8 * s, head_y + 13 * s), (x, head_y + 20 * s), (x + 8 * s, head_y + 13 * s), 8), INK, 2.0 * s)


def saucer(pa, cx, cy, s, body=(206, 212, 228), dome=(170, 226, 255), light=(255, 220, 120), beam=0, beamc=(200, 240, 255)):
    if beam:
        shape(pa, [(cx - 26 * s, cy + 12 * s), (cx + 26 * s, cy + 12 * s), (cx + 80 * s, cy + beam), (cx - 80 * s, cy + beam)], beamc, ol=0, shade=0,
              alpha=0.3, tex=False)
    shape(pa, rell(cx, cy + 8 * s, 56 * s, 14 * s), _sh(body, 0.75), ol=2.2, shade=0.5)
    shape(pa, rell(cx, cy, 90 * s, 20 * s), body, ol=2.6, shade=0.7, depth=6 * s)
    shape(pa, chaikin([(cx - 36 * s, cy - 6 * s), (cx - 30 * s, cy - 34 * s), (cx, cy - 46 * s), (cx + 30 * s, cy - 34 * s), (cx + 36 * s, cy - 6 * s)], 2),
          dome, ol=2.4, shade=0.5)
    shape(pa, rell(cx - 13 * s, cy - 30 * s, 8 * s, 4.5 * s, -25), (255, 255, 255), ol=0, shade=0, alpha=0.7)
    for k in range(7):
        lx = cx - 66 * s + k * 22 * s
        shape(pa, rell(lx, cy + 4 * s, 5 * s, 4 * s), light, ol=1.0, shade=0)
        pa.glow(lx, cy + 4 * s, 9 * s, light, 0.35)


def ile_flottante(pa, cx, cy, w, R, top=(170, 214, 196), rock=(74, 66, 104), vein=(170, 150, 255), falls=True):
    """L'île flottante : dessus herbu ovale, dessous en montagne renversée veinée de cristaux, chutes
    de lumière qui tombent dans le vide, îlots satellites."""
    pts = [(cx - w / 2, cy)]
    n = 9
    for k in range(1, n):
        t = k / n
        x = cx - w / 2 + w * t
        depth = math.sin(math.pi * t) ** 1.3 * w * 0.62 * (1 - 0.35 * abs(t - 0.55))
        pts.append((x + R.uniform(-w * 0.02, w * 0.02), cy + depth * R.uniform(0.85, 1.1)))
    pts.append((cx + w / 2, cy))
    shape(pa, pts, rock, ol=3.0, shade=0.8, depth=w * 0.04)
    for k in range(6):
        x0 = cx + R.uniform(-w * 0.35, w * 0.35)
        p = [(x0, cy + 10)]
        for j in range(5):
            p.append((p[-1][0] + R.uniform(-w * 0.04, w * 0.04), p[-1][1] + R.uniform(w * 0.04, w * 0.08)))
        pa.line(p, vein, 2.4, alpha=0.9)
        pa.glow(p[-1][0], p[-1][1], w * 0.03, vein, 0.6)
    for k in range(4):
        px, py = cx + R.uniform(-w * 0.3, w * 0.3), cy + R.uniform(w * 0.1, w * 0.35)
        shape(pa, [(px - 6, py), (px, py - 16), (px + 6, py), (px, py + 8)], (210, 200, 255), ol=1.4, shade=0.3)
        pa.glow(px, py, 22, vein, 0.4)
    if falls:
        for fx in (cx - w * 0.44, cx + w * 0.4):
            for j in range(3):
                pa.line([(fx + j * 4, cy + 6), (fx + j * 5 + 3, cy + w * 0.5)], (190, 236, 255), 3.0 - j * 0.6, alpha=0.6 - j * 0.12)
            pa.glow(fx, cy + w * 0.3, w * 0.06, (150, 220, 255), 0.25)
    shape(pa, rell(cx, cy, w / 2, w * 0.085), top, ol=3.0, shade=0.4, depth=6)
    for k in range(3):
        sx, sy = cx + R.choice((-1, 1)) * R.uniform(w * 0.55, w * 0.7), cy + R.uniform(-w * 0.1, w * 0.25)
        sw = w * R.uniform(0.05, 0.09)
        shape(pa, [(sx - sw, sy), (sx + sw, sy), (sx + sw * 0.2, sy + sw * 1.3)], rock, ol=2, shade=0.6)
        shape(pa, rell(sx, sy, sw, sw * 0.25), top, ol=2, shade=0.3)


def fleche(pa, x, base, hgt, w, R=None):
    """La Flèche de Cristal : une grande flèche facettée, deux contreforts de chaque côté, le Cœur."""
    for side in (-1, 1):
        for (dx, hh, ww) in ((0.55, 0.38, 0.32), (0.9, 0.2, 0.26)):
            bx = x + side * w * dx
            shape(pa, [(bx - w * ww / 2, base), (bx, base - hgt * hh), (bx + w * ww / 2, base)], (176, 196, 250), ol=2.2, shade=0.4,
                  grad=((220, 232, 255), (130, 150, 230), 90))
    shape(pa, [(x - w / 2, base), (x, base - hgt), (x + w / 2, base)], (200, 220, 255), ol=2.6, shade=0.4, grad=((236, 244, 255), (150, 176, 240), 90))
    shape(pa, [(x, base), (x, base - hgt), (x + w / 2, base)], (150, 168, 236), ol=0, shade=0, alpha=0.5)
    for k in range(1, 6):
        yv = base - hgt * k / 6
        hw = w / 2 * (1 - k / 6)
        pa.line([(x - hw, yv), (x + hw, yv)], (255, 255, 255), 1.4, alpha=0.5)
    hy = base - hgt * 0.8
    pa.glow(x, hy, w * 1.3, (255, 170, 230), 0.7)
    pa.glow(x, hy, w * 0.5, (255, 240, 250), 0.6)
    shape(pa, heart_pts(x, hy, w * 0.018), (255, 200, 236), ol=2.0, shade=0.4)


def ruban(pa, cx, cy, w, text, col=(240, 232, 252), tcol=(96, 70, 150), size=28):
    hh = 24
    for side in (-1, 1):
        ex = cx + side * w / 2
        tail = [(ex - side * 30, cy - hh + 14), (ex + side * 44, cy - hh + 14), (ex + side * 26, cy + 2 + 14), (ex + side * 44, cy + hh + 14),
                (ex - side * 30, cy + hh + 14)]
        shape(pa, tail, _sh(col, 0.82), ol=2.4, shade=0.4)
    top = bez((cx - w / 2, cy - hh), (cx, cy - hh - 16), (cx + w / 2, cy - hh), 24)
    bot = bez((cx + w / 2, cy + hh), (cx, cy + hh - 16), (cx - w / 2, cy + hh), 24)
    shape(pa, top + bot, col, ol=2.6, shade=0.5, depth=6)
    ptext(pa, (cx, cy - 7), text, "pm", fit_size(text, "pm", size, w - 50, 3), tcol, spacing=3)


def stars_bg(pa, R, n, y1, cols=((255, 255, 255), (220, 230, 255), (255, 230, 250))):
    for _ in range(n):
        x, y = R.uniform(10, pa.W - 10), R.uniform(10, y1)
        c = cols[int(R.integers(len(cols)))]
        if R.random() < 0.15:
            shape(pa, star4(x, y, R.uniform(5, 10), 0.22), c, ol=1.2, shade=0)
            pa.glow(x, y, 10, c, 0.25)
        else:
            r = R.uniform(0.8, 2.0)
            shape(pa, rell(x, y, r, r), c, ol=0, shade=0)


def fresque_finish(pa, R, name):
    """Cadre peint (argent et lavande, étoiles aux coins), grain de peinture, voile nacré."""
    W, H = pa.W, pa.H
    pa.outline([(10, 10), (W - 10, 10), (W - 10, H - 10), (10, H - 10)], 8, (222, 216, 240))
    pa.outline([(22, 22), (W - 22, 22), (W - 22, H - 22), (22, H - 22)], 2, (190, 180, 230))
    for (x, y) in ((22, 22), (W - 22, 22), (22, H - 22), (W - 22, H - 22)):
        shape(pa, star4(x, y, 15, 0.25), (250, 246, 255), ol=1.6, shade=0.3)
    rgb, cov = pa.result()
    big = max(W, H)
    g = grain(R, big, 0.7)[:H, :W]
    sheen = tn(R, big, (2, 4, 8), 0.6)[:H, :W]
    col = rgb * (0.95 + 0.08 * g[..., None])
    col = col + (iri(sheen * 1.5, 0.5) - 0.5) * 0.04 + 0.015
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    dedge = np.minimum(np.minimum(xx, W - 1 - xx), np.minimum(yy, H - 1 - yy))
    col = col * (1 - 0.15 * np.exp(-dedge / 40.0))[..., None]
    save_rgb(col, name)


FW, FH = 1024, 512


def fresque_lumen_1():
    """Ondelune, la planète natale : grande planète aux océans de vagues, anneau doré, lunes Pipa et Lou ;
    sur la colline, trois Lumens partent « en vacances » (valises, chapeau de soleil), une soucoupe
    chargée de bagages s'envole."""
    R = rng(7651)
    pa = Paint(FW, FH, K=2, bg=(0, 0, 0), seed=7651)
    pa.rect(-10, -10, FW + 10, FH + 10, (40, 30, 90), grad=((26, 22, 70), (96, 72, 160), 90), shade=0, ol=0)
    stars_bg(pa, R, 140, 420)
    cx, cy, Rp = 340, 220, 150
    ring_back = ellp(cx, cy, 250, 50, 180, 360, 60)
    pa.line(ring_back, (230, 200, 140), 12)
    pa.line(ring_back, (250, 230, 180), 4)
    pa.glow(cx, cy, Rp * 1.2, (160, 200, 255), 0.3)
    shape(pa, rell(cx, cy, Rp, Rp, 0, 96), (150, 210, 240), ol=3.2, shade=0.5, depth=14, grad=((170, 236, 250), (150, 130, 230), 70))
    for k in range(-6, 7):
        yb = cy + k * 21
        pts = []
        for x in np.linspace(cx - Rp, cx + Rp, 80):
            y = yb + 7 * math.sin((x - cx) / 22 + k)
            if (x - cx) ** 2 + (y - cy) ** 2 < (Rp - 5) ** 2:
                pts.append((x, y))
            elif len(pts) > 1:
                break
        if len(pts) > 1:
            pa.line(pts, (236, 248, 255), 2.4, alpha=0.55)
    shape(pa, rell(cx - 55, cy - 60, 36, 20, -30), (255, 255, 255), ol=0, shade=0, alpha=0.25)
    ring_front = ellp(cx, cy, 250, 50, 0, 180, 60)
    pa.line(ring_front, (230, 200, 140), 12)
    pa.line(ring_front, (250, 230, 180), 4)
    shape(pa, rell(110, 96, 34, 34), (236, 232, 250), ol=2.6, shade=0.7, depth=8)
    for (x, y, r) in ((100, 90, 6), (122, 108, 4), (114, 80, 3)):
        shape(pa, rell(x, y, r, r), (200, 196, 226), ol=1, shade=0.3)
    shape(pa, rell(612, 84, 20, 20), (250, 196, 226), ol=2.4, shade=0.7, depth=6)
    # la colline et les trois Lumens en partance
    hill = [(-20, 520), (-20, 440)] + [(x, 430 - 70 * math.exp(-((x - 760) / 260.0) ** 2) + 6 * math.sin(x / 40)) for x in np.linspace(0, 1024, 40)] + [(1044, 440), (1044, 520)]
    shape(pa, hill, (90, 170, 190), ol=3, shade=0.5, depth=12, grad=((120, 200, 210), (60, 120, 150), 90))
    for k in range(8):
        y = 450 + k * 9
        pa.line([(x, y + 4 * math.sin(x / 26 + k)) for x in np.linspace(20, 1004, 60)], (170, 230, 236), 1.6, alpha=0.4)
    fig = [(690, 372, (190, 220, 255), (120, 110, 200), (255, 220, 120), "wave", None),
           (790, 362, (220, 200, 255), (236, 160, 200), (130, 240, 255), None, (250, 230, 160)),
           (880, 374, (190, 240, 236), (100, 160, 200), (255, 150, 220), None, None)]
    for x, base, skin, robe, acc, pose, hat in fig:
        s = 0.62
        hands = ((x - 40 * s, base - 300 * s), None) if pose == "wave" else ((x - 46 * s, base - 100 * s), (x + 44 * s, base - 100 * s))
        if pose is None:
            sx = x + 56 * s
            shape(pa, [(sx - 4, base - 70 * s), (sx + 40 * s, base - 70 * s), (sx + 40 * s, base - 4), (sx - 4, base - 4)], _sh(acc, 0.85), ol=2.2, shade=0.5)
            pa.line([(sx + 8, base - 70 * s), (sx + 10, base - 82 * s), (sx + 28 * s, base - 82 * s), (sx + 30 * s, base - 70 * s)], INK, 2.4)
            hands = ((x - 44 * s, base - 108 * s), (sx + 18 * s, base - 82 * s))
        lumen_fig(pa, x, base, s, skin, robe, acc, hands=hands, crest=(x != 880), hat=hat)
    # la soucoupe chargée de valises
    sx, sy = 900, 120
    for (dx, w_, h_, c) in ((-40, 34, 22, (240, 150, 120)), (-6, 40, 28, (150, 200, 250)), (34, 30, 20, (250, 220, 120))):
        shape(pa, [(sx + dx - w_ / 2, sy - 44 - h_), (sx + dx + w_ / 2, sy - 44 - h_), (sx + dx + w_ / 2, sy - 40), (sx + dx - w_ / 2, sy - 40)],
              c, ol=2.2, shade=0.5)
    pa.line([(sx - 60, sy - 52), (sx + 54, sy - 58)], INK, 2.0)
    saucer(pa, sx, sy, 0.7)
    for k in range(3):
        pa.line([(sx + 30 + k * 16, sy + 22 + k * 9), (sx + 56 + k * 18, sy + 40 + k * 12)], (236, 240, 255), 2.4, alpha=0.6)
    ruban(pa, 250, 462, 400, "ONDELUNE, NOTRE PLANÈTE")
    fresque_finish(pa, R, "fresque_lumen_1.png")


def fresque_lumen_2():
    """L'arrivée des Lumens dans l'archipel, il y a mille ans : coucher de soleil sur la mer, îles à
    l'horizon, une escadrille de soucoupes qui descend dans des rayons de lumière, une barque de
    pêcheurs ébahis, des mouettes."""
    R = rng(7652)
    pa = Paint(FW, FH, K=2, bg=(0, 0, 0), seed=7652)
    pa.rect(-10, -10, FW + 10, 380, (200, 150, 180), grad=((110, 84, 170), (255, 190, 150), 90, (0, 370)), shade=0, ol=0)
    stars_bg(pa, R, 40, 150)
    pa.glow(512, 360, 200, (255, 200, 140), 0.6)
    shape(pa, ellp(512, 362, 74, 74, 180, 360, 40), (255, 214, 140), ol=2.6, shade=0.3)
    for (x, y, w_) in ((150, 120, 160), (760, 90, 200), (930, 180, 120)):
        shape(pa, rell(x, y, w_ / 2, 16), (255, 210, 220), ol=0, shade=0.2, alpha=0.5)
    pa.rect(-10, 360, FW + 10, FH + 10, (60, 100, 160), grad=((90, 120, 190), (40, 64, 120), 90), shade=0, ol=0)
    for k in range(14):
        y = 372 + k * 10
        pa.line([(x, y + 3 * math.sin(x / 18 + k * 1.7)) for x in np.linspace(0, 1024, 70)], (180, 200, 240), 1.4, alpha=0.35)
    for x in np.linspace(470, 554, 6):
        pa.line([(x, 368), (x + 10, 368)], (255, 220, 160), 2.4, alpha=0.7)
    for (x, w_, h_, c) in ((130, 220, 70, (70, 70, 110)), (380, 150, 46, (84, 76, 120)), (780, 260, 90, (64, 66, 104)), (960, 120, 34, (80, 74, 116))):
        shape(pa, chaikin([(x - w_ / 2, 364), (x - w_ * 0.3, 364 - h_ * 0.7), (x - w_ * 0.05, 364 - h_), (x + w_ * 0.2, 364 - h_ * 0.8),
                           (x + w_ / 2, 364)], 2), c, ol=2.2, shade=0.3)
        for j in range(int(w_ / 60)):
            tx = x - w_ * 0.25 + j * 40
            pa.line([(tx, 364 - h_ * 0.6), (tx, 364 - h_ * 0.6 - 26)], _sh(c, 0.7), 3)
            shape(pa, rell(tx, 364 - h_ * 0.6 - 30, 14, 9), _sh(c, 0.85), ol=1.6, shade=0.2)
    for i, (x, y, s, beam) in enumerate(((180, 90, 0.55, 0), (330, 150, 0.75, 210), (540, 140, 0.45, 0), (700, 170, 0.85, 190), (880, 110, 0.6, 250))):
        saucer(pa, x, y, s, beam=beam, light=((255, 220, 120), (140, 240, 255), (255, 160, 220))[i % 3])
    bx, by = 600, 440
    shape(pa, [(bx - 70, by - 10), (bx + 70, by - 10), (bx + 50, by + 18), (bx - 50, by + 18)], (170, 110, 70), ol=2.6, shade=0.5)
    for (dx, skin, hair) in ((-28, (240, 200, 170), (110, 70, 40)), (16, (200, 150, 110), (40, 30, 30))):
        shape(pa, rell(bx + dx, by - 26, 13, 14), skin, ol=2, shade=0.4)
        shape(pa, chaikin([(bx + dx - 13, by - 28), (bx + dx - 10, by - 40), (bx + dx + 10, by - 40), (bx + dx + 13, by - 28)], 1), hair, ol=1.6)
        shape(pa, rell(bx + dx, by - 20, 4, 5), INK, ol=0, shade=0)
        stroke(pa, [(bx + dx + 8, by - 14), (bx + dx + 22, by - 50)], 6, skin, ol=1.6)
    pa.line([(bx + 50, by - 10), (bx + 70, by - 80), (bx + 110, by - 40)], (90, 70, 50), 2.4)
    for (x, y, s) in ((300, 260, 1.0), (340, 240, 0.8), (640, 250, 0.9), (960, 290, 0.7)):
        pa.line(bez((x - 16 * s, y), (x - 8 * s, y - 10 * s), (x, y), 8) + bez((x, y), (x + 8 * s, y - 10 * s), (x + 16 * s, y), 8)[1:], (250, 250, 255), 2.4)
    ruban(pa, 512, 46, 420, "IL Y A MILLE ANS…")
    fresque_finish(pa, R, "fresque_lumen_2.png")


def fresque_lumen_3():
    """Les Lumens et les Pieds-Lourds se donnent la main, en ronde devant la Flèche ; cœurs et étoiles."""
    R = rng(7653)
    pa = Paint(FW, FH, K=2, bg=(0, 0, 0), seed=7653)
    pa.rect(-10, -10, FW + 10, FH + 10, (220, 200, 240), grad=((186, 180, 240), (252, 222, 232), 90), shade=0, ol=0)
    pa.glow(512, 180, 260, (255, 250, 255), 0.35)
    ile_flottante(pa, 512, 150, 300, R, top=(200, 230, 214), rock=(150, 140, 190), vein=(220, 200, 255), falls=False)
    fleche(pa, 512, 150, 130, 26)
    shape(pa, [(-10, 420)] + [(x, 410 + 10 * math.sin(x / 90)) for x in np.linspace(0, 1024, 30)] + [(1034, 420), (1034, 520), (-10, 520)],
          (150, 206, 170), ol=3, shade=0.4, grad=((170, 220, 180), (110, 170, 140), 90))
    for _ in range(90):
        x, y = R.uniform(30, 994), R.uniform(430, 490)
        c = [(255, 240, 250), (250, 200, 230), (220, 240, 255)][int(R.integers(3))]
        shape(pa, star_pts(x, y, R.uniform(3, 6), 5, 0.45), c, ol=0.8, shade=0)
    people = [("L", 110), ("H", 240), ("L", 370), ("H", 512), ("L", 654), ("H", 784), ("L", 914)]
    base = 470
    sL, sH = 1.08, 1.0
    hand_y = base - 118
    xs = [p[1] for p in people]
    for i, (kind, x) in enumerate(people):
        lt = ((xs[i - 1] + x) / 2, hand_y) if i > 0 else (x - 50, base - 120)
        rt = ((xs[i + 1] + x) / 2, hand_y) if i < len(people) - 1 else (x + 50, base - 120)
        if kind == "L":
            pal = [((190, 220, 255), (130, 120, 210), (255, 220, 120)), ((230, 210, 255), (230, 160, 210), (140, 240, 255)),
                   ((200, 245, 240), (90, 160, 200), (255, 160, 220)), ((236, 236, 244), (170, 150, 230), (255, 230, 150))][i // 2]
            lumen_fig(pa, x, base, sL, *pal, hands=(lt, rt), crest=(i % 4 == 0))
        else:
            pal = [((242, 204, 176), (230, 90, 80), (70, 90, 150), (90, 60, 40)), ((200, 150, 110), (250, 200, 70), (60, 120, 90), (30, 26, 30)),
                   ((250, 220, 196), (90, 170, 230), (110, 80, 70), (230, 180, 90))][i // 2]
            pied_lourd(pa, x, base, sH, *pal, hands=(lt, rt))
    for (x, y, kind) in ((240, 200, 0), (784, 200, 0), (60, 86, 1), (964, 86, 1), (176, 214, 2), (850, 222, 2), (300, 236, 2), (720, 240, 2)):
        if kind == 0:
            shape(pa, heart_pts(x, y, 1.4), (250, 120, 170), ol=2.2, shade=0.5)
        elif kind == 1:
            shape(pa, star_pts(x, y, 16, 5, 0.45), (255, 220, 120), ol=2.2, shade=0.5)
        else:
            shape(pa, star4(x, y, 8, 0.25), (255, 250, 255), ol=1.4, shade=0)
    ruban(pa, 512, 42, 440, "AMIS POUR TOUJOURS")
    fresque_finish(pa, R, "fresque_lumen_3.png")


def fresque_lumen_4():
    """La Flèche de Cristal sur Astralys, la nuit des aurores : l'île flottante, ses chutes de lumière,
    les dômes du Quartier des Bulles, le Cœur qui rayonne, deux soucoupes."""
    R = rng(7654)
    pa = Paint(FW, FH, K=2, bg=(0, 0, 0), seed=7654)
    pa.rect(-10, -10, FW + 10, FH + 10, (30, 26, 70), grad=((18, 18, 54), (64, 44, 116), 90), shade=0, ol=0)
    stars_bg(pa, R, 160, 470)
    for k, (c, y0, amp) in enumerate((((110, 250, 200), 90, 40), ((160, 140, 255), 130, 30), ((255, 140, 220), 60, 26))):
        pts = [(x, y0 + amp * math.sin(x / 150 + k * 1.3) + 14 * math.sin(x / 47 + k)) for x in np.linspace(-20, 1044, 60)]
        for w_, a_ in ((70, 0.12), (36, 0.18), (12, 0.3)):
            pa.line(pts, c, w_, alpha=a_)
    cx, cy = 512, 350
    ile_flottante(pa, cx, cy, 600, R)
    for (x, r, c) in ((330, 34, (200, 230, 255)), (390, 24, (240, 210, 255)), (650, 30, (210, 250, 240)), (710, 22, (255, 220, 240))):
        shape(pa, ellp(x, cy - 2, r, r * 0.9, 180, 360, 30), c, ol=2.2, shade=0.4, alpha=0.85)
        shape(pa, rell(x - r * 0.35, cy - r * 0.55, r * 0.22, r * 0.14, -30), (255, 255, 255), ol=0, shade=0, alpha=0.6)
    fleche(pa, cx, cy - 4, 300, 64)
    hy = cy - 4 - 300 * 0.8
    for k in range(3):
        pa.outline(rell(cx, hy, 70 + k * 40, 70 + k * 40), 2.4, (255, 200, 240), alpha=0.5 - k * 0.14)
    saucer(pa, 190, 170, 0.5, light=(140, 240, 255))
    saucer(pa, 850, 230, 0.4, light=(255, 220, 120))
    ruban(pa, 210, 470, 340, "LA FLÈCHE DE CRISTAL", size=24)
    fresque_finish(pa, R, "fresque_lumen_4.png")


def fresques():
    for k in range(1, 5):
        globals()["fresque_lumen_%d" % k]()


# =================================================================== végétation lumineuse (512 x 512, RGBA)

def _rgba_cutout(col, a, name):
    """Enregistre une découpe RGBA ; hors de la forme, la couleur du bord (pas de liseré sombre dans les
    mipmaps)."""
    from scipy import ndimage
    inside = a > 0.5
    idx = ndimage.distance_transform_edt(~inside, return_distances=False, return_indices=True)
    col = col[idx[0], idx[1]]
    save_rgba(np.dstack([np.clip(col, 0, 1), a]), name)


def feuille_lumineuse():
    """Feuille lumineuse des Jardins suspendus (pointe en haut, pétiole en bas) : limbe turquoise
    translucide, nervures claires qui luisent, liseré lumineux, petites spores. ÉMISSIVE (RGBA)."""
    S, K = 512, 2
    R = rng(7661)
    m = Image.new("L", (S * K, S * K), 0)
    lp = leaf_poly(256 * K, 262 * K, 470 * K, 300 * K, -math.pi / 2, 0.5)
    ImageDraw.Draw(m).polygon(lp, fill=255)
    ImageDraw.Draw(m).line([(256 * K, 470 * K), (256 * K, 510 * K)], fill=255, width=10 * K)
    a = down(np.asarray(m, np.float32) / 255.0, K)
    from scipy import ndimage
    dist = ndimage.distance_transform_edt(a > 0.5).astype(np.float32)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    cells = worley(R, S, 18, 0.9)[1]
    n = tn(R, S, (4, 8, 16, 32), 0.6)
    col = mix(C(0.06, 0.36, 0.42), C(0.22, 0.72, 0.7), smooth(2, 70, dist) * 0.7 + 0.3 * n)
    col = col * (0.9 + 0.12 * smooth(0, 6, cells)[..., None])
    vm = Image.new("L", (S * K, S * K), 0)
    dv = ImageDraw.Draw(vm)
    dv.line([(256 * K, 500 * K), (256 * K, 40 * K)], fill=255, width=6 * K)
    for side in (-1, 1):
        for k in range(9):
            y0 = 440 - k * 44
            L = 150 * math.sin(math.pi * (y0 - 20) / 470) + 20
            p = bez((256, y0), (256 + side * L * 0.5, y0 - 30), (256 + side * L, y0 - 80), 16)
            dv.line([(px * K, py * K) for px, py in p], fill=210, width=int(3 * K))
            for j in range(3):
                t = 0.3 + j * 0.25
                qx, qy = p[int(t * 16)]
                q = [(qx, qy), (qx + side * 26, qy + 10 - j * 6)]
                dv.line([(px * K, py * K) for px, py in q], fill=120, width=int(1.5 * K))
    veins = down(np.asarray(vm, np.float32) / 255.0, K) * a
    rim = np.exp(-(dist / 2.5) ** 2) * (a > 0.5)
    glowc = C(0.6, 1.0, 0.95)
    col = col + veins[..., None] * glowc * 0.75 + gblur(veins, 3.0)[..., None] * glowc * 0.35 + rim[..., None] * glowc * 0.45
    sp = sparkle_map(R, S, 70, 2.0, 4.0) * (dist > 8)
    col = col + sp[..., None] * C(1.0, 1.0, 0.85) * 0.8
    _rgba_cutout(col, a, "feuille_lumineuse.png")


def petale_lumineux():
    """Pétale lumineux (base étroite en bas, bout arrondi échancré en haut) : du magenta profond au rose
    puis au lavande pâle, nervures en éventail qui luisent, reflets nacrés, bord clair. ÉMISSIF (RGBA)."""
    S, K = 512, 2
    R = rng(7662)
    pts = chaikin([(256, 506), (226, 470), (150, 380), (72, 250), (62, 140), (112, 52), (192, 22), (256, 56), (320, 22), (400, 52), (450, 140),
                   (440, 250), (362, 380), (286, 470)], 3)
    m = Image.new("L", (S * K, S * K), 0)
    ImageDraw.Draw(m).polygon([(x * K, y * K) for x, y in pts], fill=255)
    a = down(np.asarray(m, np.float32) / 255.0, K)
    from scipy import ndimage
    dist = ndimage.distance_transform_edt(a > 0.5).astype(np.float32)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    t = np.clip((506 - yy) / 480, 0, 1)
    col = mix(C(0.5, 0.1, 0.42), C(0.95, 0.48, 0.78), smooth(0.0, 0.5, t))
    col = mix(col, C(0.94, 0.84, 1.0), smooth(0.5, 1.0, t))
    n = tn(R, S, (4, 8, 16, 32), 0.6)
    col = col * (1 + (iri(n * 1.3 + t * 0.5, 0.6) - 0.5) * 0.18)
    ang = np.arctan2(xx - 256, 506 - yy)
    fan = np.exp(-((np.mod(ang * 28 + (n - 0.5) * 1.5, 1.0) - 0.5) / 0.09) ** 2) * smooth(0.05, 0.3, t)
    col = col + fan[..., None] * C(1.0, 0.85, 1.0) * 0.28
    rim = np.exp(-(dist / 3.0) ** 2) * (a > 0.5)
    col = col + rim[..., None] * C(1.0, 0.9, 1.0) * 0.4
    sp = sparkle_map(R, S, 40, 2.0, 4.0) * (dist > 8)
    col = col + sp[..., None] * 0.7
    _rgba_cutout(col, a, "petale_lumineux.png")


def vegetation():
    feuille_lumineuse()
    petale_lumineux()


# =================================================================== icônes (128 px)

def ico_save(img, name):
    """Cerné et ombré comme les autres icônes (generate_items_v28), puis réduit à 128 px.
    N'écrit que les icônes de la V76 (aucune icône plus ancienne n'est touchée)."""
    import generate_items_v28 as icons
    if name not in ICON_NAMES_V76:
        sys.exit("icône inconnue : " + name)
    p = _guard(ITEMS / (name + ".png"))
    img2 = icons.shadow(icons.outline(img))
    img2.resize((128, 128), Image.LANCZOS).save(p, optimize=True)
    _log(p)


def ic_cristal_astral():
    img = canvas_i()
    R = rng(7701)
    glow_i(img, 256, 280, 200, (120, 120, 255), 0.0)
    for (cx, base, w, h, a, c) in ((180, 450, 70, 250, -18, (120, 110, 230)), (330, 450, 66, 220, 20, (150, 120, 240)),
                                   (256, 460, 92, 340, 0, (110, 150, 250))):
        pts = [(cx - w / 2, base), (cx - w / 2, base - h * 0.78), (cx, base - h), (cx + w / 2, base - h * 0.78), (cx + w / 2, base)]
        pts = xform(pts, cx, base, a)
        m = ipoly(img, pts, c, depth=10, gloss=1.2, tex=T(R, (8, 16, 32), 0.15))
        face = xform([(cx, base), (cx, base - h), (cx + w / 2, base - h * 0.78), (cx + w / 2, base)], cx, base, a)
        ipoly(img, face, tuple(int(v * 0.75) for v in c), depth=4, gloss=0.4, alpha=0.6)
        glow_i(img, *xform([(cx, base - h * 0.55)], cx, base, a)[0], 60, (200, 210, 255), 0.5, inside=m)
    ipoly(img, chaikin([(120, 470), (392, 470), (370, 440), (140, 440)], 1), (90, 84, 110), depth=8, gloss=0.3)
    for (x, y, r) in ((110, 150, 22), (400, 120, 18), (420, 300, 12)):
        ipoly(img, star4(x, y, r, 0.2), (255, 255, 255), depth=3, gloss=0.2)
    ico_save(img, "cristal_astral")


def ic_toile_voile():
    img = canvas_i()
    R = rng(7702)
    tex = T(R, (16, 32, 64, 128), 0.18)
    ipoly(img, [(96, 120), (300, 70), (430, 380), (140, 430)], (238, 228, 204), depth=14, gloss=0.3, tex=tex)
    d = ImageDraw.Draw(img)
    for k in range(1, 5):
        t = k / 5
        d.line([(96 + (300 - 96) * t, 120 + (70 - 120) * t), (140 + (430 - 140) * t, 430 + (380 - 430) * t)], fill=(190, 176, 150, 255), width=3)
    ipoly(img, [(300, 70), (430, 380), (360, 330)], (214, 200, 172), depth=6, gloss=0.2, tex=tex)
    m = iell(img, 150, 420, 70, 46, (226, 214, 188), depth=16, gloss=0.4, tex=tex)
    for r in (52, 34, 16):
        d.ellipse((150 - r * 1.35, 420 - r * 0.9, 150 + r * 1.35, 420 + r * 0.9), outline=(180, 164, 136, 255), width=3)
    pts = [(250 + math.sin(t * 9) * 8, 140 + t * 300) for t in np.linspace(0, 1, 40)]
    for w, c in ((16, (110, 80, 50)), (10, (170, 130, 80)), (4, (210, 175, 120))):
        d.line(pts, fill=c + (255,), width=w, joint="curve")
    for (x, y) in ((106, 130), (296, 82), (420, 372)):
        iell(img, x, y, 12, 12, (200, 170, 90), depth=4, gloss=1.0)
        iell(img, x, y, 5, 5, (80, 60, 40), depth=1)
    ico_save(img, "toile_voile")


def _gear(img, cx, cy, r, teeth, col, R, hole=0.32):
    pts = []
    for k in range(teeth * 4):
        a = k / (teeth * 4) * TAU
        rr = r if (k % 4) in (1, 2) else r * 0.82
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    m = ipoly(img, pts, col, depth=12, gloss=1.0, tex=T(R, (16, 32, 64), 0.15))
    iell(img, cx, cy, r * 0.62, r * 0.62, tuple(int(v * 0.85) for v in col), depth=6, gloss=0.6)
    hm = Image.new("L", (IS, IS), 0)
    ImageDraw.Draw(hm).ellipse((cx - r * hole, cy - r * hole, cx + r * hole, cy + r * hole), fill=255)
    for k in range(5):
        a = k / 5 * TAU + 0.3
        x, y = cx + math.cos(a) * r * 0.47, cy + math.sin(a) * r * 0.47
        ImageDraw.Draw(hm).ellipse((x - r * 0.09, y - r * 0.09, x + r * 0.09, y + r * 0.09), fill=255)
    img.putalpha(Image.fromarray(np.minimum(np.asarray(img.split()[3]), 255 - np.asarray(hm)).astype(np.uint8)))
    d = ImageDraw.Draw(img)
    d.ellipse((cx - r * hole, cy - r * hole, cx + r * hole, cy + r * hole), outline=tuple(int(v * 0.5) for v in col) + (255,), width=5)


def ic_engrenage():
    img = canvas_i()
    R = rng(7703)
    _gear(img, 330, 330, 130, 12, (130, 136, 150), R)
    _gear(img, 190, 196, 150, 14, (214, 168, 70), R)
    ico_save(img, "engrenage")


def ic_fragment_meteorite():
    img = canvas_i()
    R = rng(7704)
    pts = [(256 + math.cos(a) * 190 * R.uniform(0.75, 1.05), 270 + math.sin(a) * 150 * R.uniform(0.75, 1.05)) for a in np.linspace(0, TAU, 13)[:-1]]
    m = ipoly(img, pts, (80, 72, 84), depth=24, gloss=0.4, tex=T(R, (8, 16, 32, 64), 0.35))
    for _ in range(9):
        x, y, r = R.uniform(140, 370), R.uniform(170, 370), R.uniform(10, 26)
        if m[int(y), int(x)] > 0.9:
            iell(img, x, y, r, r * 0.8, (54, 48, 60), depth=6, gloss=0.1)
            iell(img, x - r * 0.15, y - r * 0.15, r * 0.6, r * 0.45, (40, 36, 46), depth=3, gloss=0.0)
    d = ImageDraw.Draw(img)
    for pts_, c in (([(170, 230), (220, 260), (250, 240), (300, 290), (340, 280)], (255, 150, 60)), ([(230, 330), (260, 310), (290, 340)], (190, 120, 255))):
        d.line(pts_, fill=c + (255,), width=9, joint="curve")
        d.line(pts_, fill=(255, 240, 220, 255), width=3, joint="curve")
    glow_i(img, 270, 270, 90, (255, 140, 60), 0.35, inside=m)
    for (x, y, r) in ((80, 110, 22), (430, 130, 16), (440, 420, 12)):
        ipoly(img, star4(x, y, r, 0.2), (255, 230, 180), depth=3, gloss=0.2)
    ico_save(img, "fragment_meteorite")


def ic_sifflet_compagnons():
    img = canvas_i()
    R = rng(7705)
    d = ImageDraw.Draw(img)
    cord = [(380, 380), (420, 470), (200, 500), (120, 420)]
    d.line(bez(*cord, 30), fill=(200, 60, 60, 255), width=12, joint="curve")
    d.line(bez(*cord, 30), fill=(240, 120, 110, 255), width=4, joint="curve")
    iell(img, 372, 372, 26, 26, (176, 180, 192), depth=6, gloss=1.2)
    iell(img, 372, 372, 13, 13, (60, 60, 70), depth=2)
    ipoly(img, [(50, 214), (250, 196), (250, 300), (50, 262)], (200, 204, 216), depth=12, gloss=1.4)
    iell(img, 52, 238, 12, 24, (60, 60, 70), depth=3)
    iell(img, 300, 270, 120, 110, (206, 210, 222), depth=24, gloss=1.4)
    ipoly(img, [(196, 196), (262, 192), (262, 214), (196, 216)], (40, 40, 50), depth=3, gloss=0.1)
    iell(img, 304, 290, 34, 30, (226, 160, 60), depth=6, gloss=0.8)
    for (dx, dy) in ((-28, -34), (0, -46), (28, -34)):
        iell(img, 304 + dx, 290 + dy, 10, 12, (226, 160, 60), depth=4, gloss=0.8)
    d = ImageDraw.Draw(img)
    for k in range(3):
        d.arc((300 + k * 22, 40 - k * 16, 380 + k * 34, 150 + k * 8), -150, -40, fill=(255, 255, 255, 255), width=7)
    ico_save(img, "sifflet_compagnons")


def ic_truffe():
    img = canvas_i()
    R = rng(7706)
    tex = T(R, (32, 64, 128, 256), 0.5)
    m = iell(img, 220, 270, 150, 140, (54, 42, 40), depth=26, gloss=0.3, tex=tex)
    d = ImageDraw.Draw(img)
    for _ in range(160):
        x, y = R.uniform(80, 370), R.uniform(140, 410)
        if m[int(y), int(x)] > 0.9:
            r = R.uniform(4, 9)
            d.ellipse((x - r, y - r, x + r, y + r), fill=(78, 64, 60, 255))
            d.ellipse((x - r * 0.4 - 2, y - r * 0.4 - 2, x + r * 0.2, y + r * 0.2), fill=(110, 92, 86, 255))
    sl = iell(img, 370, 340, 110, 96, (200, 176, 150), depth=10, gloss=0.3)
    for k in range(9):
        a0 = R.uniform(0, TAU)
        p = [(370 + math.cos(a0 + t * 1.5) * (20 + t * 70), 340 + math.sin(a0 + t * 1.5) * (16 + t * 60)) for t in np.linspace(0, 1, 14)]
        d.line(p, fill=(90, 66, 58, 255), width=6, joint="curve")
        d.line(p, fill=(240, 226, 210, 255), width=2, joint="curve")
    d.ellipse((260, 244, 480, 436), outline=(50, 38, 36, 255), width=12)
    ico_save(img, "truffe")


def ic_pelote_laine():
    img = canvas_i()
    R = rng(7707)
    base = (220, 70, 90)
    m = iell(img, 240, 260, 180, 180, base, depth=30, gloss=0.4)
    d = ImageDraw.Draw(img)
    for k in range(14):
        a = k / 14 * math.pi
        for j in range(3):
            pts = rell(240, 260, 168 - j * 8, (40 + k * 9) % 168 + 10, math.degrees(a) + j * 6, 60)
            pts = [p for p in pts]
            c = (250, 140, 150, 255) if (k + j) % 2 else (170, 40, 60, 255)
            d.line(pts + [pts[0]], fill=c, width=4)
    img.putalpha(Image.fromarray(np.minimum(np.asarray(img.split()[3]), (m * 255).astype(np.uint8))))
    tail = bez((390, 360), (470, 420), (420, 480), (330, 470), 30)
    d = ImageDraw.Draw(img)
    d.line(tail, fill=(200, 60, 80, 255), width=12, joint="curve")
    d.line(tail, fill=(250, 140, 150, 255), width=4, joint="curve")
    glow_i(img, 180, 190, 90, (255, 255, 255), 0.25, inside=m)
    ico_save(img, "pelote_laine")


def ic_fromage_affine():
    img = canvas_i()
    R = rng(7708)
    ipoly(img, [(70, 330), (420, 180), (440, 380), (90, 450)], (232, 196, 90), depth=16, gloss=0.4, tex=T(R, (16, 32, 64), 0.15))
    top = ipoly(img, [(70, 330), (420, 180), (440, 220), (300, 270), (100, 350)], (250, 222, 120), depth=10, gloss=0.6)
    ipoly(img, [(420, 180), (440, 220), (460, 400), (440, 380)], (196, 140, 60), depth=6, gloss=0.3, tex=T(R, (32, 64, 128), 0.4))
    ipoly(img, [(90, 450), (440, 380), (460, 400), (100, 470)], (180, 130, 60), depth=6, gloss=0.3, tex=T(R, (32, 64, 128), 0.4))
    for (x, y, r) in ((180, 380, 22), (290, 340, 16), (350, 400, 26), (230, 420, 12), (390, 300, 12), (150, 330, 10)):
        iell(img, x, y, r, r * 0.8, (200, 150, 50), depth=6, gloss=0.1)
    iell(img, 330, 120, 70, 44, (240, 236, 220), depth=8, gloss=0.4)
    itext(img, (330, 120), "AFFINÉ", "dispb", 26, (150, 100, 40))
    ico_save(img, "fromage_affine")


def ic_clochette_cochon():
    img = canvas_i()
    R = rng(7709)
    d = ImageDraw.Draw(img)
    rib = bez((40, 150), (256, 260), (472, 150), 40)
    d.line(rib, fill=(220, 90, 130, 255), width=40, joint="curve")
    d.line(rib, fill=(250, 160, 190, 255), width=10, joint="curve")
    for side in (-1, 1):
        ipoly(img, chaikin([(256, 230), (256 + side * 90, 170), (256 + side * 100, 270)], 1), (236, 110, 150), depth=10, gloss=0.6)
    iell(img, 256, 232, 24, 24, (220, 90, 130), depth=8, gloss=0.6)
    bell = chaikin([(256, 250), (300, 270), (330, 340), (350, 420), (380, 440), (132, 440), (162, 420), (182, 340), (212, 270)], 2)
    ipoly(img, bell, (236, 190, 70), depth=24, gloss=1.4, tex=T(R, (16, 32, 64), 0.12))
    ipoly(img, [(140, 430), (372, 430), (380, 450), (132, 450)], (200, 150, 50), depth=6, gloss=0.8)
    iell(img, 256, 466, 22, 22, (180, 130, 40), depth=8, gloss=1.0)
    for k in range(3):
        d.arc((380 + k * 16, 300 - k * 20, 430 + k * 26, 400 + k * 10), -60, 40, fill=(255, 240, 160, 255), width=6)
    ico_save(img, "clochette_cochon")


def ic_carte_stellaire():
    img = canvas_i()
    R = rng(7710)
    m = ipoly(img, [(90, 120), (420, 90), (440, 400), (110, 430)], (30, 40, 90), depth=12, gloss=0.3, tex=T(R, (8, 16, 32, 64), 0.2))
    d = ImageDraw.Draw(img)
    for _ in range(70):
        x, y = R.uniform(120, 410), R.uniform(130, 400)
        r = R.uniform(1.5, 4)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(240, 240, 255, 255))
    cons = [(150, 180), (210, 160), (260, 210), (330, 190), (380, 240), (340, 320), (250, 340), (180, 300)]
    d.line(cons, fill=(130, 220, 255, 255), width=4)
    for (x, y) in cons:
        d.polygon(star4(x, y, 12, 0.25), fill=(255, 230, 140, 255))
    d.ellipse((240, 240, 290, 290), outline=(255, 180, 230, 255), width=4)
    for (x0, y0, x1, y1) in ((80, 110, 110, 440), (410, 80, 450, 410)):
        ipoly(img, [(x0, y0), (x0 + 30, y0 - 6), (x1, y1 - 10), (x1 - 30, y1)], (226, 190, 90), depth=8, gloss=1.0)
    ico_save(img, "carte_stellaire")


def ic_graine_lumineuse():
    img = canvas_i()
    R = rng(7711)
    d = ImageDraw.Draw(img)
    for k in range(12):
        a = k / 12 * TAU
        d.line([(256 + math.cos(a) * 150, 300 + math.sin(a) * 150), (256 + math.cos(a) * 200, 300 + math.sin(a) * 200)], fill=(190, 255, 220, 200), width=8)
    m = ipoly(img, leaf_poly(256, 320, 250, 170, -math.pi / 2, 0.3), (110, 220, 160), depth=24, gloss=1.0)
    glow_i(img, 256, 320, 110, (220, 255, 230), 0.6, inside=m)
    d = ImageDraw.Draw(img)
    d.line(bez((256, 210), (240, 260), (256, 420), 20), fill=(60, 160, 110, 255), width=5)
    d.line(bez((256, 200), (250, 140), (270, 90), 20), fill=(80, 170, 90, 255), width=12)
    ipoly(img, leaf_poly(310, 100, 110, 50, -0.5, 0.3), (110, 200, 100), depth=8, gloss=0.6)
    ipoly(img, leaf_poly(210, 120, 90, 42, -2.7, 0.3), (120, 210, 110), depth=8, gloss=0.6)
    for (x, y, r) in ((100, 200, 16), (420, 240, 14), (380, 430, 12)):
        ipoly(img, star4(x, y, r, 0.2), (240, 255, 220), depth=3, gloss=0.2)
    ico_save(img, "graine_lumineuse")


def ic_puce_holo():
    img = canvas_i()
    R = rng(7712)
    d = ImageDraw.Draw(img)
    for k in range(6):
        for side in (-1, 1):
            x = 166 + k * 36
            d.rectangle((x - 7, 330 + side * 120 - 20, x + 7, 330 + side * 120 + 20), fill=(214, 180, 90, 255))
            y = 240 + k * 36
            d.rectangle((256 + side * 120 - 20, y - 7, 256 + side * 120 + 20, y + 7), fill=(214, 180, 90, 255))
    ipoly(img, [(146, 220), (366, 220), (366, 440), (146, 440)], (44, 50, 66), depth=10, gloss=0.6)
    yy, xx = np.mgrid[0:IS, 0:IS].astype(np.float32)
    top = ipoly(img, [(176, 250), (336, 250), (336, 410), (176, 410)], (200, 200, 220), depth=6, gloss=1.0)
    film = iri((xx + yy) / 260.0 + np.sin(xx / 30) * 0.1, 0.9)
    a = np.asarray(img, np.float32) / 255
    a[..., :3] = a[..., :3] * (1 - 0.6 * top[..., None]) + film * 0.6 * top[..., None]
    img.paste(Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), "RGBA"))
    d = ImageDraw.Draw(img)
    d.polygon([(206, 230), (306, 230), (380, 60), (132, 60)], fill=(120, 230, 255, 70))
    d.ellipse((216, 70, 296, 150), outline=(140, 240, 255, 255), width=5)
    d.ellipse((246, 100, 266, 120), fill=(255, 255, 255, 255))
    d.arc((196, 92, 316, 128), 0, 360, fill=(255, 170, 230, 255), width=4)
    ico_save(img, "puce_holo")


def ic_fleur_nebuleuse():
    img = canvas_i()
    R = rng(7713)
    d = ImageDraw.Draw(img)
    d.line(bez((256, 300), (230, 400), (260, 490), 20), fill=(70, 150, 110, 255), width=16)
    ipoly(img, leaf_poly(320, 420, 120, 50, -0.4, 0.3), (90, 180, 120), depth=8, gloss=0.5)
    cols = [(170, 110, 250), (240, 120, 210), (110, 150, 250), (200, 120, 240), (250, 150, 220), (130, 120, 240)]
    for k in range(6):
        a = k / 6 * TAU - math.pi / 2
        m = ipoly(img, leaf_poly(256 + math.cos(a) * 92, 230 + math.sin(a) * 92, 190, 120, a, 0.1), cols[k], depth=16, gloss=0.8)
        glow_i(img, 256 + math.cos(a) * 120, 230 + math.sin(a) * 120, 50, (255, 230, 255), 0.4, inside=m)
    m = iell(img, 256, 230, 54, 54, (40, 30, 90), depth=12, gloss=0.6)
    d = ImageDraw.Draw(img)
    for _ in range(14):
        x, y = 256 + R.normal(0, 22), 230 + R.normal(0, 22)
        d.ellipse((x - 3, y - 3, x + 3, y + 3), fill=(255, 250, 220, 255))
    d.polygon(star4(256, 230, 26, 0.22), fill=(255, 240, 180, 255))
    ico_save(img, "fleur_nebuleuse")


def ic_badge_visiteur():
    img = canvas_i()
    R = rng(7714)
    d = ImageDraw.Draw(img)
    d.line([(256, 20), (256, 90)], fill=(120, 200, 240, 255), width=22)
    vol(img, lambda dd: dd.rounded_rectangle((216, 70, 296, 110), 10, fill=255), (190, 196, 210), depth=6, gloss=1.2)
    vol(img, lambda dd: dd.rounded_rectangle((110, 100, 402, 470), 36, fill=255), (236, 236, 246), depth=14, gloss=0.6)
    vol(img, lambda dd: dd.rounded_rectangle((110, 100, 402, 200), 36, fill=255), (120, 100, 220), depth=6, gloss=0.6)
    vol(img, lambda dd: dd.rectangle((110, 160, 402, 200), fill=255), (120, 100, 220), depth=4, gloss=0.3)
    itext(img, (256, 150), "ASTRALYS", "dispb", 38, (255, 255, 255))
    ipoly(img, [(226, 400), (256, 230), (286, 400)], (150, 190, 255), depth=8, gloss=1.0)
    iell(img, 256, 270, 12, 12, (255, 150, 220), depth=4, gloss=1.0)
    itext(img, (256, 435), "VISITEUR", "dispb", 30, (90, 70, 170))
    ipoly(img, star4(170, 300, 22, 0.25), (255, 210, 90), depth=4, gloss=0.5)
    ipoly(img, star4(345, 320, 16, 0.25), (255, 210, 90), depth=4, gloss=0.5)
    ico_save(img, "badge_visiteur")


def ic_appareil_holo():
    img = canvas_i()
    R = rng(7715)
    d = ImageDraw.Draw(img)
    d.line(bez((90, 300), (60, 470), (256, 500), 30), fill=(90, 200, 120, 255), width=12)
    d.line(bez((256, 500), (450, 470), (420, 300), 30), fill=(90, 200, 120, 255), width=12)
    vol(img, lambda dd: dd.rounded_rectangle((80, 250, 432, 450), 40, fill=255), (120, 220, 150), depth=16, gloss=0.8, tex=T(R))
    vol(img, lambda dd: dd.rounded_rectangle((300, 220, 400, 260), 14, fill=255), (90, 180, 120), depth=6, gloss=0.8)
    iell(img, 230, 350, 84, 84, (60, 70, 90), depth=14, gloss=1.0)
    m = iell(img, 230, 350, 58, 58, (80, 160, 230), depth=10, gloss=1.4)
    glow_i(img, 210, 330, 40, (255, 255, 255), 0.6, inside=m)
    iell(img, 380, 300, 16, 16, (255, 80, 120), depth=4, gloss=1.0)
    d = ImageDraw.Draw(img)
    d.polygon([(200, 260), (260, 260), (380, 40), (90, 40)], fill=(130, 240, 255, 70))
    d.rectangle((140, 60, 330, 190), outline=(140, 240, 255, 255), width=5)
    d.polygon([(160, 175), (220, 110), (260, 150), (290, 120), (318, 175)], fill=(150, 240, 255, 200))
    d.ellipse((280, 76, 310, 106), fill=(255, 240, 160, 255))
    ico_save(img, "appareil_holo")


def ic_the_stellaire():
    img = canvas_i()
    R = rng(7716)
    iell(img, 240, 430, 200, 46, (220, 214, 236), depth=10, gloss=0.8)
    vol(img, lambda dd: dd.arc((320, 250, 440, 390), -80, 90, fill=255, width=26), (230, 226, 246), depth=6, gloss=1.0)
    cup = chaikin([(90, 240), (390, 240), (370, 360), (320, 420), (160, 420), (110, 360)], 2)
    ipoly(img, cup, (236, 232, 250), depth=20, gloss=1.2)
    m = iell(img, 240, 244, 150, 30, (70, 130, 240), depth=8, gloss=1.0)
    glow_i(img, 240, 244, 120, (160, 220, 255), 0.6, inside=m)
    d = ImageDraw.Draw(img)
    for (x, y) in ((180, 246), (260, 240), (310, 250)):
        d.polygon(star4(x, y, 9, 0.25), fill=(255, 255, 220, 255))
    spiral = [(240 + math.sin(t * 2.2) * 40 * (1 - t / 6), 210 - t * 26) for t in np.linspace(0, 6, 60)]
    d.line(spiral, fill=(220, 230, 255, 200), width=9, joint="curve")
    d.polygon(star4(250, 40, 22, 0.25), fill=(255, 240, 160, 255))
    ipoly(img, star_pts(240, 330, 34, 5, 0.45), (150, 130, 240), depth=4, gloss=0.6)
    ico_save(img, "the_stellaire")


def ic_gelee_cosmique():
    img = canvas_i()
    R = rng(7717)
    iell(img, 256, 420, 220, 56, (230, 230, 244), depth=10, gloss=1.0)
    jel = chaikin([(90, 420), (100, 260), (160, 150), (256, 120), (352, 150), (412, 260), (422, 420)], 3)
    m = ipoly(img, jel, (140, 70, 200), depth=36, gloss=1.6, alpha=0.92)
    d = ImageDraw.Draw(img)
    for _ in range(18):
        x, y = R.uniform(140, 370), R.uniform(170, 400)
        if m[int(y), int(x)] > 0.9:
            d.polygon(star4(x, y, R.uniform(6, 13), 0.22), fill=(255, 240, 200, 255))
    for (x, y, c) in ((200, 300, (255, 120, 200)), (310, 250, (120, 220, 255))):
        iell(img, x, y, 24, 24, c, depth=6, gloss=1.0, alpha=0.8)
    glow_i(img, 200, 200, 90, (255, 220, 255), 0.4, inside=m)
    for k in (-1, 1):
        d.arc((256 + k * 200 - 30, 160, 256 + k * 200 + 30, 260), 100 if k > 0 else -80, 260 if k > 0 else 80, fill=(255, 255, 255, 220), width=6)
    iell(img, 256, 112, 26, 26, (240, 60, 90), depth=8, gloss=1.4)
    ico_save(img, "gelee_cosmique")


def ic_biscuit_lunaire():
    img = canvas_i()
    R = rng(7718)
    outer = rell(256, 256, 200, 200, 0, 96)
    m = ipoly(img, outer, (226, 184, 110), depth=20, gloss=0.4, tex=T(R, (16, 32, 64, 128), 0.25))
    cut = Image.new("L", (IS, IS), 0)
    ImageDraw.Draw(cut).ellipse((256 + 30 - 170, 256 - 80 - 170, 256 + 30 + 170, 256 - 80 + 170), fill=255)
    img.putalpha(Image.fromarray(np.minimum(np.asarray(img.split()[3]), 255 - np.asarray(cut)).astype(np.uint8)))
    d = ImageDraw.Draw(img)
    for (x, y, r) in ((120, 330, 22), (200, 400, 16), (300, 420, 26), (110, 230, 14), (380, 380, 12)):
        d.ellipse((x - r, y - r, x + r, y + r), fill=(190, 140, 80, 255))
        d.ellipse((x - r * 0.7, y - r * 0.7, x + r * 0.5, y + r * 0.5), fill=(170, 120, 66, 255))
    for _ in range(50):
        x, y = R.uniform(70, 440), R.uniform(150, 450)
        a = np.asarray(img.split()[3])
        if a[int(y), int(x)] > 200:
            d.ellipse((x - 3, y - 3, x + 3, y + 3), fill=(255, 252, 240, 255))
    for (x, y, r) in ((360, 140, 26), (430, 230, 14)):
        ipoly(img, star4(x, y, r, 0.2), (255, 245, 200), depth=3, gloss=0.2)
    ico_save(img, "biscuit_lunaire")


def ic_coeur_fleche():
    img = canvas_i()
    R = rng(7719)
    d = ImageDraw.Draw(img)
    for k in range(16):
        a = k / 16 * TAU
        L = 230 if k % 2 == 0 else 190
        d.line([(256 + math.cos(a) * 160, 270 + math.sin(a) * 160), (256 + math.cos(a) * L, 270 + math.sin(a) * L)], fill=(255, 190, 235, 210), width=7)
    hp = heart_pts(256, 270, 11.5)
    m = ipoly(img, hp, (240, 120, 200), depth=26, gloss=1.4)
    for (pts, c) in (([(256, 200), (150, 160), (90, 220), (150, 330)], (255, 180, 230)), ([(256, 200), (330, 150), (420, 210), (360, 330)], (220, 100, 190)),
                     ([(150, 330), (256, 440), (256, 200)], (250, 150, 215)), ([(360, 330), (256, 440), (256, 200)], (200, 80, 170))):
        ipoly(img, pts, c, depth=4, gloss=0.6, alpha=0.55)
    a = np.asarray(img.split()[3]).astype(np.float32)
    img.putalpha(Image.fromarray(np.where(m > 0.5, 255, a).astype(np.uint8)))
    glow_i(img, 230, 240, 90, (255, 255, 255), 0.7, inside=m)
    ipoly(img, star4(330, 190, 30, 0.2), (255, 255, 255), depth=3, gloss=0.2)
    ico_save(img, "coeur_fleche")


def icones():
    """Les objets de la V76 (128 px, ombrés et cernés comme les autres icônes)."""
    for n in ICON_NAMES_V76:
        globals()["ic_" + n]()


# =================================================================== lancement

GROUPS = {"sols": sols, "bati": bati, "holos": holos, "enseignes": enseignes, "fresques": fresques,
          "vegetation": vegetation, "icones": icones}


def images():
    """Chaque image qu'on peut refaire seule, par son nom de fichier (sans .png)."""
    one = {}
    for n in SOLS + BATI + VEGETATION:
        if n in globals():
            one[n] = globals()[n]
    for k in range(1, 7):
        if "holo" in globals():
            one["holo_%d" % k] = (lambda k=k: holo(k))
    for k in range(1, 5):
        if "fresque_lumen_%d" % k in globals():
            one["fresque_lumen_%d" % k] = globals()["fresque_lumen_%d" % k]
    if "enseigne" in globals():
        for k in ENSEIGNES_V76:
            one["enseigne_" + k] = (lambda k=k: enseigne(k))
    for k in ICON_NAMES_V76:
        if "ic_" + k in globals():
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
