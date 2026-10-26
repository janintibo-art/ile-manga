"""V75 : textures de l'Île du Boucan (Port-Boucan, la friche industrielle et portuaire réoccupée par des
punks bienveillants, des artistes et des familles ; la Cathédrale des Spores ; l'Usine Grise de
Lisse & Fils), et ses nouveaux objets.

boucan/   — surfaces raccordables, chacune avec sa carte de relief <nom>_n.png
          (« sols », 1024 px, une tuile couvre environ 4 m x 4 m) :
          herbe_seche (+_n)    : herbe sèche de friche vue d'en haut, terre caillouteuse, plantes rudérales ;
          gravier (+_n)        : gravier concassé anguleux (ballast, calcaire, basalte), poussière ;
          beton (+_n)          : dalle de béton fissurée, joints sciés, herbes et mousse dans les fentes ;
          asphalte (+_n)       : enrobé usé, granulats à nu, faïençage, fissures pontées au goudron ;
          terre_noire (+_n)    : terre noire grumeleuse, escarbilles, éclats de brique, racines ;
          galets (+_n)         : galets de plage arrondis (granit, quartz, basalte, calcaire) ;
          mousse_spores (+_n)  : mousse bleu-vert de la Cathédrale, sporanges lumineux (ÉMISSIF) ;
          sable_gris (+_n)     : sable gris, rides de vent, coquilles brisées, algues sèches.
          (« bâti », 1024 px, une tuile couvre environ 3 m x 3 m)
          brique (+_n)         : brique rouge d'usine (appareil anglais), suie, efflorescences ;
          brique_peinte (+_n)  : brique peinte en blanc cassé, peinture écaillée ;
          beton_brut (+_n)     : béton banché : empreintes de planches, trous de banches, coulures ;
          tole_rouille (+_n)   : tôle ondulée rouillée (ondes verticales), recouvrements, vis ;
          tole_peinte (+_n)    : tôle ondulée peinte (bleu-vert passé), éclats, rouille aux vis ;
          bardage (+_n)        : bardage de planches verticales grisées, couvre-joints, clous ;
          acier_rouille (+_n)  : tôle d'acier rouillée, piqûres, écailles, soudures ;
          metal_rivete (+_n)   : plaques d'acier rivetées peintes en gris-vert, usées ;
          carrelage_usine (+_n): carreaux de faïence blancs d'usine, craquelés, joints encrassés ;
          paves_port (+_n)     : pavés de granit du port, joints sombres ;
          coque_cargo (+_n)    : acier de coque peint en rouge, soudures, coulures de rouille.
          (« donjon », 512 px, une tuile ≈ 2 m)
          moquette_bureau, faux_plafond, beton_usine, tapis_roulant, carrelage_bureau (+_n).
          (« champignons » : chapeaux 1024 px, lamelles et pied 512 px)
          chapeau_bleu, chapeau_violet, chapeau_orange (+_n) : dessus de chapeau féerique (ÉMISSIF) ;
          lamelles (+_n) : lames (le long de y), lueur entre les lames (ÉMISSIF) ;
          pied_champi (+_n) : pied fibreux (fibres le long de y), un peu luminescent.
          — panneaux (non raccordables, sans _n) :
          fresque_1 … fresque_8 (1024 x 512) : grandes fresques peintes sur la brique ;
          graffiti_1 … graffiti_12 (1024 x 512, RGBA) : graffitis à la bombe que le joueur peint ;
          affiche_concert_1 … _4 (512 x 768) : affiches des Rats de Cale à la Halle Hurlante ;
          panneau_lisse (1024 x 512) : panneau publicitaire « BIENTÔT ICI : LE LISSE-CENTER » ;
          enseigne_<x> (512 x 256) : halle, cantine, gratuiterie, velo, imprimerie, radio, lisse,
                                    conserverie (lettrage fantôme), soins ;
          fanzine_couverture (512 x 768) : couverture photocopiée du fanzine « Le Boucanier ».
items/    (« icones », 128 px, ombrées et cernées comme les autres) : voir ICON_NAMES_V75.

Tout est dessiné ici, procéduralement (libre de droits, aucune image tierce), avec les outils des
générateurs V69 et V70. Polices présentes sur le système : Inter (SIL OFL), TeX Gyre Heros Cn,
Cursor et Chorus (licence GUST), Lora (SIL OFL) ; repli sur DejaVu.
Déterministe : chaque image a sa propre graine.
Lancement depuis la racine du dépôt :
    python3 pcvr/tools/generate_boucan_v75.py [sols | bati | donjon | champignons | fresques | graffitis |
                                               affiches | enseignes | icones | <nom>]
(sans argument : tout ; <nom> : une seule image, par ex. « brique » ou « graffiti_3 »).
"""
import math
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # pas de __pycache__ dans pcvr/tools

import numpy as np  # noqa: E402
from PIL import Image, ImageDraw, ImageFilter, ImageFont  # noqa: E402
from scipy import ndimage  # noqa: E402

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_soleils_v69 import (tn, gblur, smooth, mix, C, grads, normal_img, bake, offs, to_img, from_img,  # noqa: E402
                                  per_id, masonry, worley, warp, chaikin, bez, ellp, tube, leaf_poly,
                                  blade_poly, down, vol)
from generate_braise_v70 import (grain, hshadow, scatter, domes, rock_poly,  # noqa: E402
                                 Paint, paper_bg, canvas_i, glow_i, IS)

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "boucan"
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


HALF_N = {"herbe_seche", "gravier", "beton", "asphalte", "terre_noire", "galets", "mousse_spores", "sable_gris", "paves_port",
          "chapeau_bleu", "chapeau_violet", "chapeau_orange"}


def save_surface(name, col, h, strength):
    """Couleur + carte de relief. Le relief est très légèrement adouci (0,6 px) avant le calcul des
    normales : moins de bruit d'un pixel (scintillement, poids du fichier), même lecture des formes.
    Pour les sols et les chapeaux (HALF_N), la carte de relief est en demi-résolution (512 px, toujours
    raccordable) : le grain fin est déjà dans la couleur, et le dossier reste léger."""
    save_rgb(col, name + ".png")
    p = OUT / (name + "_n.png")
    h = gblur(h.astype(np.float32), 0.6)
    if name in HALF_N:
        normal_img(down(gblur(h, 0.5), 2), strength * 0.55).save(p, optimize=True)
    else:
        normal_img(h, strength * 1.1).save(p, optimize=True)
    _log(p)


def up(a, k):
    """Agrandit un champ k fois au plus proche voisin (raccord gardé)."""
    return np.repeat(np.repeat(a, k, 0), k, 1)


FONTS = {
    "black": ["/usr/share/fonts/opentype/inter/Inter-Black.otf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"],
    "xbold": ["/usr/share/fonts/opentype/inter/Inter-ExtraBold.otf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"],
    "bold": ["/usr/share/fonts/opentype/inter/Inter-Bold.otf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"],
    "semi": ["/usr/share/fonts/opentype/inter/Inter-SemiBold.otf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"],
    "reg": ["/usr/share/fonts/opentype/inter/Inter-Regular.otf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"],
    "light": ["/usr/share/fonts/opentype/inter/Inter-Light.otf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-ExtraLight.ttf"],
    "cond": ["/usr/share/texmf/fonts/opentype/public/tex-gyre/texgyreheroscn-bold.otf",
             "/usr/share/texlive/texmf-dist/fonts/opentype/public/tex-gyre/texgyreheroscn-bold.otf",
             "/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf"],
    "type": ["/usr/share/texmf/fonts/opentype/public/tex-gyre/texgyrecursor-bold.otf",
             "/usr/share/texlive/texmf-dist/fonts/opentype/public/tex-gyre/texgyrecursor-bold.otf",
             "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"],
    "hand": ["/usr/share/texmf/fonts/opentype/public/tex-gyre/texgyrechorus-mediumitalic.otf",
             "/usr/share/texlive/texmf-dist/fonts/opentype/public/tex-gyre/texgyrechorus-mediumitalic.otf",
             "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Italic.ttf"],
    "serif": [str(ROOT / "www/assets/fonts/Lora-Bold.ttf"), "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"],
    "serifi": [str(ROOT / "www/assets/fonts/Lora-BoldItalic.ttf"), "/usr/share/fonts/truetype/dejavu/DejaVuSerif-BoldItalic.ttf"],
    "pop": ["/usr/share/fonts/truetype/google-fonts/Poppins-Bold.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"],
    "popi": ["/usr/share/fonts/truetype/google-fonts/Poppins-BoldItalic.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-BoldOblique.ttf"],
}
_FCACHE = {}


def ff(kind, size):
    key = (kind, int(size))
    if key not in _FCACHE:
        for p in FONTS[kind]:
            if Path(p).exists():
                _FCACHE[key] = ImageFont.truetype(p, max(4, int(size)))
                break
        else:
            _FCACHE[key] = ImageFont.load_default()
    return _FCACHE[key]


def crack_paths(R, S, n, seg=(6, 16), steps=(10, 40), turn=0.35, branch=0.25, H=None, start=None):
    """Chemins de fissures (marche aléatoire), liste de (points, largeur)."""
    H = H or S
    out = []
    for i in range(n):
        x, y = start[i] if start is not None else (R.random() * S, R.random() * H)
        a = R.uniform(0, TAU)
        w = R.uniform(1.0, 2.6)
        stack = [(x, y, a, w, int(R.integers(*steps)))]
        while stack:
            x, y, a, w, ns = stack.pop()
            pts = [(x, y)]
            for _ in range(ns):
                a += R.normal(0, turn)
                L = R.uniform(*seg)
                x += math.cos(a) * L
                y += math.sin(a) * L
                pts.append((x, y))
                if R.random() < branch * 0.12 and w > 0.8:
                    stack.append((x, y, a + R.choice((-1, 1)) * R.uniform(0.5, 1.3), w * 0.6, int(ns * 0.5) + 2))
            out.append((pts, w))
    return out


def draw_paths(S, paths, H=None, K=1, val=255, wscale=1.0, img=None):
    """Trace les chemins (fissures, racines) dans un masque L raccordable (dessin à l'échelle K)."""
    H = H or S
    img = img or Image.new("L", (S * K, H * K), 0)
    d = ImageDraw.Draw(img)
    for pts, w in paths:
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        oxs = [0] + ([S] if min(xs) < 0 else []) + ([-S] if max(xs) > S else [])
        oys = [0] + ([H] if min(ys) < 0 else []) + ([-H] if max(ys) > H else [])
        for ox in oxs:
            for oy in oys:
                q = [((px + ox) * K, (py + oy) * K) for px, py in pts]
                d.line(q, fill=val, width=max(1, int(round(w * wscale * K))), joint="curve")
    return img


def wstones(R, S, n, fill, rmin, rmax, jitter=0.9, rough=0.12, el=(0.6, 1.0)):
    """Granulats / cailloux par cellules de Voronoï (une pierre par cellule, rayon relatif à la cellule) :
    masque, dôme 0..1 (0 au bord), id de cellule, r normalisé. Raccordable et entièrement vectorisé."""
    _, edge, cid, dx, dy = worley(R, S, n, jitter)
    ang = per_id(cid, R, 0, TAU)
    elo = per_id(cid, R, el[0], el[1])
    ca, sa = np.cos(ang), np.sin(ang)
    u = dx * ca + dy * sa
    v = (-dx * sa + dy * ca) / elo
    th = np.arctan2(v, u)
    ph1 = per_id(cid, R, 0, TAU)
    ph2 = per_id(cid, R, 0, TAU)
    r = np.hypot(u, v) * (1 + rough * np.sin(3 * th + ph1) + rough * 0.6 * np.sin(5 * th + ph2))
    rr = per_id(cid, R, rmin, rmax) * (S / n) * 0.5
    keep = per_id(cid, R, 0, 1) < fill
    t = r / rr
    m = (t < 1) & keep
    dome = np.where(m, np.sqrt(np.clip(1 - t * t, 0, 1)), 0).astype(np.float32)
    return m, dome, cid, edge


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
    return scol, sth, mask, prof, ids


def pal_pick(R, pal, n):
    k = R.choice(len(pal), n, p=[q[1] for q in pal])
    return np.array([pal[i][0] for i in k], np.float32)


def tuft(d, dh, x, y, R, size, cols, n=None, hv=(150, 230), w=(2.0, 4.0), spread=TAU, a0=0.0, S=None):
    """Une touffe d'herbe vue d'en haut : des brins qui rayonnent depuis (x, y)."""
    n = n or int(R.integers(6, 14))
    for _ in range(n):
        a = a0 + R.uniform(-spread / 2, spread / 2)
        L = size * R.uniform(0.45, 1.0)
        c = cols[int(R.integers(len(cols)))]
        c = tuple(int(np.clip(v * R.uniform(0.8, 1.15), 0, 255)) for v in c)
        poly = blade_poly(x, y, a, L, R.uniform(*w), R.uniform(-0.4, 0.4))
        hvv = int(R.uniform(*hv))
        for ox, oy in offs(x, y, L + 4, S):
            pp = [(px + ox, py + oy) for px, py in poly]
            d.polygon(pp, fill=c)
            if dh is not None:
                dh.polygon(pp, fill=hvv)


def finish(col, h, shadow_hs=0.0, bake_s=4.0, k=0.3, ao=0.3, ao_r=6):
    if shadow_hs:
        sh = hshadow(h, shadow_hs, 16, 1.5)
        col = col * (1 - 0.3 * sh[..., None])
    return bake(col, h, bake_s, k=k, ao=ao, ao_r=ao_r)


def rust_palette(t, n2):
    """Rouille : de l'orange vif au brun noir (t 0..1), variée par n2."""
    c0 = C(0.62, 0.3, 0.11)
    c1 = C(0.45, 0.2, 0.08)
    c2 = C(0.27, 0.13, 0.07)
    c3 = C(0.72, 0.42, 0.18)
    col = mix(c0, c1, smooth(0.3, 0.6, t))
    col = mix(col, c2, smooth(0.6, 0.9, t))
    col = mix(col, c3, smooth(0.62, 0.85, n2) * 0.5)
    return col


# =================================================================== les sols (une tuile ≈ 4 m)

def herbe_seche():
    """Friche vue d'en haut : terre sèche caillouteuse, plaques d'herbes sèches (paille, brins gris-vert),
    rosettes vertes (pissenlit, plantain), quelques séneçons jaunes, éclats de brique et graviers."""
    S, K = 1024, 2
    S2 = S * K
    R = rng(7501)
    n = tn(R, S, (4, 8, 16, 32, 64, 128), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    cover = tn(R, S, (4, 8, 16, 32), 0.65)
    green = tn(R, S, (4, 8, 16, 32), 0.7)
    gr = grain(R, S, 0.6)
    soil = mix(C(0.36, 0.31, 0.24), C(0.47, 0.41, 0.32), smooth(0.3, 0.75, n))
    soil = soil * (0.85 + 0.3 * gr[..., None]) * (0.93 + 0.14 * fine[..., None])
    # graviers et éclats de brique dans la terre nue
    items = []
    for count, rlo, rhi in ((2600, 1.2, 3.0), (500, 3.0, 6.0), (40, 6, 11)):
        for _ in range(count):
            r = R.uniform(rlo, rhi)
            items.append((R.random() * S, R.random() * S, rock_poly(R, r, k=int(R.integers(4, 8)), jit=0.35), r))
    pal = [((0.58, 0.56, 0.52), 0.4), ((0.66, 0.6, 0.5), 0.2), ((0.55, 0.27, 0.18), 0.15), ((0.38, 0.37, 0.36), 0.15), ((0.8, 0.78, 0.72), 0.1)]
    scol, sth, mask, prof, _ = stones_layer(R, S, items, pal, fine)
    ma = gblur(mask.astype(np.float32), 0.5)
    soil = mix(soil, scol, ma)
    h0 = n * 0.15 + gr * 0.04 + sth * mask * 0.4
    soil = bake(soil, h0, 3.0, k=0.3, ao=0.3, ao_r=4)
    img = to_img(up(soil, K))
    d = ImageDraw.Draw(img)
    hm = Image.fromarray((np.clip(up(h0, K) * 0.5, 0, 1) * 255).astype(np.uint8), "L")
    dh = ImageDraw.Draw(hm)
    straw = [np.array(c) for c in ((0.66, 0.58, 0.38), (0.58, 0.5, 0.32), (0.74, 0.68, 0.5), (0.5, 0.42, 0.28), (0.62, 0.52, 0.36))]
    greys = [np.array(c) for c in ((0.42, 0.44, 0.28), (0.34, 0.38, 0.2), (0.5, 0.5, 0.32))]
    # rosettes (sous les herbes)
    for _ in range(320):
        x, y = R.random(2) * S2
        a0 = R.uniform(0, TAU)
        base_c = np.array((0.24, 0.36, 0.14)) * R.uniform(0.8, 1.2)
        if R.random() < 0.4:
            base_c = np.array((0.32, 0.36, 0.18)) * R.uniform(0.85, 1.1)
        nl = int(R.integers(5, 9))
        Ls = R.uniform(30, 64)
        for k in range(nl):
            a = a0 + k * TAU / nl + R.uniform(-0.2, 0.2)
            L = Ls * R.uniform(0.7, 1.1)
            lp = leaf_poly(x + math.cos(a) * L * 0.5, y + math.sin(a) * L * 0.5, L, L * R.uniform(0.25, 0.4), a, 0.25)
            c = tuple(int(np.clip(v * R.uniform(0.85, 1.15), 0, 1) * 255) for v in base_c)
            for ox, oy in offs(x, y, L + 4, S2):
                pp = [(px + ox, py + oy) for px, py in lp]
                d.polygon(pp, fill=c)
                dh.polygon(pp, fill=140)
                d.line([(x + ox, y + oy), (x + ox + math.cos(a) * L * 0.9, y + oy + math.sin(a) * L * 0.9)],
                       fill=tuple(min(255, int(v * 1.25)) for v in c), width=2)
    # herbes : trois couches, plus dense là où cover est haut
    for layer, (count, bright, hv, ls) in enumerate(((26000, 0.6, 90, 1.0), (30000, 0.8, 160, 0.95), (22000, 1.0, 230, 0.85))):
        centers = R.random((count // 9, 2)) * S2
        cv = cover[(centers[:, 1] / K).astype(int) % S, (centers[:, 0] / K).astype(int) % S]
        centers = centers[R.random(len(centers)) < smooth(0.35, 0.65, cv) * 0.95 + 0.05]
        for cx, cy in centers:
            gi = green[int(cy / K) % S, int(cx / K) % S]
            for _ in range(int(R.integers(6, 15))):
                x = cx + R.normal(0, 7)
                y = cy + R.normal(0, 7)
                if R.random() < 0.15 + 0.5 * smooth(0.55, 0.8, gi):
                    c = greys[int(R.integers(len(greys)))]
                else:
                    c = straw[int(R.integers(len(straw)))]
                c = c * bright * R.uniform(0.82, 1.15)
                col = tuple(int(np.clip(v, 0, 1) * 255) for v in c)
                a = R.uniform(0, TAU)
                L = R.uniform(30, 90) * ls
                poly = blade_poly(x, y, a, L, R.uniform(3.0, 5.5), R.uniform(-0.3, 0.3))
                hvv = int(hv + R.uniform(-25, 25))
                for ox, oy in offs(x, y, L + 6, S2):
                    pp = [(px + ox, py + oy) for px, py in poly]
                    d.polygon(pp, fill=col)
                    dh.polygon(pp, fill=hvv)
        if layer == 1:
            # tiges sèches couchées (graminées, avec épis)
            for _ in range(900):
                x, y = R.random(2) * S2
                a = R.uniform(0, TAU)
                L = R.uniform(70, 200)
                c = tuple(int(v * R.uniform(0.75, 1.05)) for v in (196, 176, 128))
                x2, y2 = x + math.cos(a) * L, y + math.sin(a) * L
                for ox, oy in offs(x, y, L + 12, S2):
                    d.line([(x + ox, y + oy), (x2 + ox, y2 + oy)], fill=c, width=2)
                    dh.line([(x + ox, y + oy), (x2 + ox, y2 + oy)], fill=200, width=2)
                    if R.random() < 0.5:
                        ex, ey = x2 + ox, y2 + oy
                        lp = leaf_poly(ex + math.cos(a) * 9, ey + math.sin(a) * 9, 22, 6, a, 0.5)
                        d.polygon(lp, fill=tuple(int(v * 0.92) for v in c))
    # séneçons et pissenlits (rares) ; carottes sauvages blanches
    for _ in range(260):
        x, y = R.random(2) * S2
        kind = R.random()
        r = R.uniform(4, 7)
        for ox, oy in offs(x, y, 30, S2):
            X, Y = x + ox, y + oy
            if kind < 0.6:
                for k in range(int(R.integers(3, 7))):
                    px, py = X + R.normal(0, 9), Y + R.normal(0, 9)
                    d.ellipse((px - r, py - r, px + r, py + r), fill=(232, 192, 40))
                    d.ellipse((px - r * 0.4, py - r * 0.4, px + r * 0.4, py + r * 0.4), fill=(200, 140, 20))
                    dh.ellipse((px - r, py - r, px + r, py + r), fill=250)
            else:
                rr = r * 2.6
                for k in range(40):
                    a, q = R.uniform(0, TAU), R.uniform(0, rr)
                    px, py = X + math.cos(a) * q, Y + math.sin(a) * q
                    d.ellipse((px - 1.6, py - 1.6, px + 1.6, py + 1.6), fill=(236, 234, 222))
                dh.ellipse((X - rr, Y - rr, X + rr, Y + rr), fill=250)
    col = down(from_img(img), K)
    h = down(np.asarray(hm, np.float32) / 255.0, K)
    col = gblur(col, 0.3)
    h = gblur(h, 0.7)
    col = finish(col, h, shadow_hs=8.0, bake_s=3.0, k=0.25, ao=0.35, ao_r=5)
    save_surface("herbe_seche", col, h * 0.85 + n * 0.15, 4.0)


def gravier():
    """Gravier concassé (ballast) : pierres anguleuses serrées, calcaire gris clair, basalte sombre,
    quelques grès beige et cailloux tachés de rouille ; poussière claire dans les creux."""
    S = 1024
    R = rng(7502)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    n = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    gr = grain(R, S, 0.6)
    dust = mix(C(0.42, 0.4, 0.37), C(0.55, 0.53, 0.49), n) * (0.85 + 0.3 * gr[..., None])
    items = []
    for count, rlo, rhi in ((500, 15.0, 21.0), (2400, 10.0, 15.0), (5200, 6.0, 10.0), (5000, 3.0, 6.0)):
        for _ in range(count):
            r = R.uniform(rlo, rhi)
            items.append((R.random() * S, R.random() * S, rock_poly(R, r, k=int(R.integers(4, 8)), jit=0.38, el=R.uniform(0.5, 0.95)), r))
    pal = [((0.62, 0.61, 0.58), 0.34), ((0.5, 0.49, 0.47), 0.2), ((0.32, 0.31, 0.31), 0.16), ((0.66, 0.6, 0.5), 0.12),
           ((0.76, 0.75, 0.72), 0.1), ((0.55, 0.42, 0.3), 0.08)]
    N = len(items)
    ids = scatter(S, items)
    hn, mask = domes(ids, N)
    base = pal_pick(R, pal, N) * R.uniform(0.85, 1.12, (N, 1)).astype(np.float32)
    base = np.vstack([np.zeros((1, 3), np.float32), base])
    rad = np.concatenate([[1.0], np.array([it[3] for it in items], np.float32)])
    cxs = np.concatenate([[0.0], np.array([it[0] for it in items], np.float32)])
    cys = np.concatenate([[0.0], np.array([it[1] for it in items], np.float32)])
    # facettes : chaque pierre a une pente plane (cassure) en plus du dôme
    fa = np.concatenate([[0.0], R.uniform(0, TAU, N)]).astype(np.float32)
    fs = np.concatenate([[0.0], R.uniform(0.0, 0.6, N)]).astype(np.float32)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    ddx = (xx - cxs[ids] + S / 2) % S - S / 2
    ddy = (yy - cys[ids] + S / 2) % S - S / 2
    plane = (np.cos(fa)[ids] * ddx + np.sin(fa)[ids] * ddy) / rad[ids] * fs[ids]
    prof = np.clip(hn * 1.8, 0, 1) ** 0.45
    stex = tn(R, S, (16, 32, 64, 128), 0.65)
    hst = (prof * (0.85 + 0.3 * stex) + plane * 0.25 * prof) * np.minimum(1.0, 0.3 + rad / 20)[ids]
    scol = base[ids] * (0.85 + 0.3 * stex[..., None]) * (0.95 + 0.1 * fine[..., None])
    scol = scol * (1 + 0.08 * np.clip(-plane, -1, 1))[..., None]
    rust = smooth(0.7, 0.85, tn(R, S, (32, 64, 128), 0.6)) * (base[ids][..., 0] > 0.5)
    scol = mix(scol, scol * C(1.1, 0.8, 0.6), rust * 0.5)
    ma = gblur(mask.astype(np.float32), 0.5)
    col = mix(dust, scol, ma)
    h = np.clip(hst, 0, None) * mask * 0.85 + n * 0.1 + gr * 0.03
    h = gblur(h, 0.6)
    col = finish(col, h, shadow_hs=7.0, bake_s=3.0, k=0.3, ao=0.5, ao_r=4)
    save_surface("gravier", col, h, 7.0)


def _weeds_in(d, dh, R, pts_list, S, K, dens=0.08, size=(14, 40)):
    greens = [(84, 112, 44), (66, 96, 38), (108, 128, 56), (128, 132, 70), (150, 146, 92)]
    for pts, w in pts_list:
        for (x, y) in pts:
            if R.random() < dens:
                tuft(d, dh, x * K, y * K, R, R.uniform(*size) * K, greens, n=int(R.integers(4, 11)), w=(1.5 * K, 3.0 * K), S=S * K)


def lichen_layer(R, S, dens=0.5, H=None):
    """Lichens : plaques irrégulières gris-vert pâle et quelques taches orange (couleur, alpha)."""
    H = H or S
    big = max(S, H)
    a1 = smooth(0.74 - 0.08 * dens, 0.8 - 0.08 * dens, tn(R, big, (16, 32, 64, 128, 256), 0.75)[:H, :S])
    a1 = a1 * smooth(0.45, 0.6, tn(R, big, (4, 8, 16), 0.6)[:H, :S])
    a2 = smooth(0.86, 0.89, tn(R, big, (32, 64, 128, 256), 0.75)[:H, :S]) * smooth(0.55, 0.65, tn(R, big, (4, 8, 16), 0.6)[:H, :S])
    c1 = mix(C(0.66, 0.68, 0.6), C(0.74, 0.76, 0.66), tn(R, big, (64, 128, 256), 0.7)[:H, :S])
    col = mix(c1, C(0.72, 0.52, 0.26), smooth(0.2, 0.5, a2))
    return col, np.clip(a1 * 0.7 + a2 * 0.7, 0, 1)


def beton():
    """Dalle de béton de friche : quatre dalles de 2 m (joints sciés), béton gris clair au grain de sable,
    granulats à nu là où c'est usé, salissures dans les creux, fines fissures épaufrées où poussent mousse
    et touffes d'herbe, lichens, auréoles d'huile et de rouille."""
    S = 1024
    R = rng(7503)
    n = tn(R, S, (2, 4, 8, 16, 32, 64), 0.6)
    n2 = tn(R, S, (8, 16, 32, 64, 128), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.5)
    gr2 = grain(R, S, 1.2)
    col = mix(C(0.5, 0.49, 0.46), C(0.6, 0.59, 0.56), smooth(0.2, 0.8, n))
    col = col * (1 + 0.06 * (n2 - 0.5))[..., None]
    col = col * (0.86 + 0.28 * gr[..., None]) * (0.94 + 0.12 * gr2[..., None]) * (0.96 + 0.08 * fine[..., None])
    # granulats à nu (usure)
    m, dome, cid, _ = wstones(R, S, 200, 0.6, 0.4, 0.95)
    wear = smooth(0.45, 0.7, tn(R, S, (4, 8, 16, 32), 0.6))
    agg = pal_pick(R, [((0.6, 0.58, 0.54), 0.45), ((0.42, 0.41, 0.4), 0.3), ((0.66, 0.6, 0.5), 0.25)], 200 * 200)[cid]
    am = m * wear
    col = mix(col, agg * (0.82 + 0.3 * dome[..., None]), am * 0.7)
    h = n * 0.12 + gr * 0.05 + fine * 0.03 + dome * am * 0.08
    from generate_braise_v70 import pores
    po = pores(R, S, 3000, 0.5, 1.6)
    col = col * (1 - 0.4 * po[..., None])
    h = h - po * 0.05
    # joints sciés (x = 512, y = 512, et les bords)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    dj = np.minimum(np.minimum(np.abs(xx - 512), np.minimum(xx + 0.5, S - 0.5 - xx)), np.minimum(np.abs(yy - 512), np.minimum(yy + 0.5, S - 0.5 - yy)))
    joint = np.exp(-(dj / 1.8) ** 2)
    chip = smooth(0.62, 0.72, tn(R, S, (32, 64, 128), 0.6)) * np.exp(-(dj / 6) ** 2)
    col = col * (1 - 0.65 * joint[..., None]) * (1 - 0.18 * chip[..., None])
    h = h - joint * 0.25 - chip * 0.05
    slab = ((xx >= 512).astype(int) + 2 * (yy >= 512).astype(int))
    tint = np.array([[1.0, 1.0, 1.0], [0.96, 0.96, 0.97], [1.03, 1.02, 1.0], [0.97, 0.96, 0.94]], np.float32)
    col = col * tint[slab]
    # salissures : poussière brune dans les creux, coulures sombres, huile, rouille
    dirt = smooth(0.0, 0.6, gblur(joint, 8) * 6) * 0.6 + smooth(0.6, 0.85, tn(R, S, (4, 8, 16, 32, 64), 0.65)) * 0.5
    col = mix(col, col * C(0.85, 0.82, 0.76), np.clip(dirt, 0, 1) * 0.35)
    oil = smooth(0.74, 0.84, tn(R, S, (4, 8, 16, 32, 64), 0.6))
    col = col * (1 - 0.28 * oil[..., None])
    rst = smooth(0.76, 0.86, tn(R, S, (8, 16, 32, 64), 0.6))
    col = mix(col, col * C(1.12, 0.86, 0.64), rst * 0.55)
    # fissures fines, épaufrées
    paths = crack_paths(R, S, 7, seg=(4, 11), steps=(25, 60), turn=0.42, branch=0.35)
    cm = np.asarray(draw_paths(S, paths, K=2, wscale=0.9).resize((S, S), Image.LANCZOS), np.float32) / 255.0
    cw = np.asarray(draw_paths(S, paths, K=1, wscale=3.0).filter(ImageFilter.GaussianBlur(1.5)), np.float32) / 255.0
    spall = cw * smooth(0.5, 0.65, tn(R, S, (32, 64, 128, 256), 0.7))
    col = col * (1 - 0.8 * cm[..., None]) * (1 - 0.12 * spall[..., None])
    h = h - cm * 0.3 - spall * 0.06
    # mousse étroite dans les fissures et joints
    moss_n = tn(R, S, (32, 64, 128, 256, 512), 0.75)
    moss = np.clip(cw * 1.3 + joint * 0.9, 0, 1) * smooth(0.4, 0.62, tn(R, S, (8, 16, 32), 0.6))
    moss = smooth(0.25, 0.7, moss * (0.6 + 0.8 * moss_n))
    mcol = mix(C(0.12, 0.16, 0.06), C(0.25, 0.3, 0.1), moss_n) * (0.8 + 0.4 * gr[..., None])
    col = mix(col, mcol, moss * 0.85)
    h = h + moss * 0.06 * moss_n
    lc, la = lichen_layer(R, S, 0.0)
    col = mix(col, lc * (0.9 + 0.2 * gr[..., None]), la * 0.75)
    h = h + la * 0.02
    # touffes d'herbe dans les fissures et les joints
    K = 2
    img = to_img(up(col, K))
    hm = Image.fromarray((np.clip(up(h, K) * 0.5 + 0.25, 0, 1) * 255).astype(np.uint8), "L")
    d, dh = ImageDraw.Draw(img), ImageDraw.Draw(hm)
    greens = [(84, 112, 44), (66, 96, 38), (108, 128, 56), (128, 132, 70), (164, 156, 100), (186, 172, 120)]
    spots = [p for pts, w in paths for p in pts[::3]]
    spots += [(512, t) for t in R.uniform(0, S, 12)] + [(t, 512) for t in R.uniform(0, S, 12)] + [(0, t) for t in R.uniform(0, S, 8)] + [(t, 0) for t in R.uniform(0, S, 8)]
    for (x, y) in spots:
        if R.random() > 0.22:
            continue
        sz = R.uniform(14, 40)
        for _ in range(int(R.integers(1, 4))):
            tuft(d, dh, (x + R.normal(0, 3)) * K, (y + R.normal(0, 3)) * K, R, sz * K, greens, n=int(R.integers(10, 22)),
                 w=(1.6 * K, 3.2 * K), S=S * K)
    col = down(from_img(img), K)
    h = down(np.asarray(hm, np.float32) / 255.0, K)
    col = finish(col, h, shadow_hs=6.0, bake_s=4.0, k=0.3, ao=0.3, ao_r=5)
    save_surface("beton", col, h, 5.0)


def asphalte():
    """Enrobé usé : liant oxydé gris, granulats à nu de toutes tailles, faïençage en peau de crocodile
    par endroits, fissures pontées au goudron (lisse et brillant), taches d'huile, poussière dans les creux."""
    S = 1024
    R = rng(7504)
    n = tn(R, S, (2, 4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.5)
    binder = mix(C(0.21, 0.21, 0.21), C(0.26, 0.255, 0.25), smooth(0.2, 0.8, n))
    col = binder * (0.85 + 0.3 * gr[..., None])
    h = n * 0.08 + gr * 0.05
    wear = smooth(0.25, 0.75, tn(R, S, (4, 8, 16, 32), 0.6))
    for (cells, fill, rlo, rhi, ht) in ((128, 0.35, 0.5, 0.95, 0.2), (220, 0.55, 0.45, 0.95, 0.12), (400, 0.6, 0.4, 0.9, 0.06)):
        m, dome, cid, _ = wstones(R, S, cells, fill, rlo, rhi, rough=0.2)
        sc = pal_pick(R, [((0.44, 0.43, 0.42), 0.4), ((0.35, 0.345, 0.34), 0.3), ((0.52, 0.49, 0.45), 0.2), ((0.27, 0.27, 0.28), 0.1)], cells * cells)[cid]
        expo = m * (0.35 + 0.65 * wear) * smooth(0.0, 0.45, dome)
        col = mix(col, sc * (0.82 + 0.3 * dome[..., None]) * (0.92 + 0.16 * fine[..., None]), expo * 0.85)
        h = h + dome * m * ht
    # faïençage
    _, ed, _, _, _ = worley(R, S, 24, 0.9)
    wx, wy = tn(R, S, (8, 16, 32), 0.6), tn(R, S, (8, 16, 32), 0.6)
    ed = warp(ed, (wx - 0.5) * 16, (wy - 0.5) * 16)
    zone = smooth(0.58, 0.7, tn(R, S, (2, 4, 8, 16), 0.6))
    croc = (1 - smooth(0.3, 1.4, ed)) * zone
    spall = (1 - smooth(1.0, 5.0, ed)) * zone * smooth(0.55, 0.7, tn(R, S, (32, 64, 128), 0.6))
    col = col * (1 - 0.65 * croc[..., None]) * (1 - 0.15 * spall[..., None])
    h = h - croc * 0.2 - spall * 0.05
    # fissures pontées au goudron
    paths = crack_paths(R, S, 4, seg=(8, 20), steps=(25, 60), turn=0.22, branch=0.2)
    tar = np.asarray(draw_paths(S, paths, K=1, wscale=3.2).filter(ImageFilter.GaussianBlur(1.6)), np.float32) / 255.0
    tar = smooth(0.25, 0.55, tar * (0.8 + 0.4 * tn(R, S, (16, 32, 64), 0.6)))
    crk = np.asarray(draw_paths(S, paths, K=1, wscale=0.9).filter(ImageFilter.GaussianBlur(0.5)), np.float32) / 255.0
    col = mix(col, C(0.09, 0.09, 0.095) * (0.85 + 0.3 * fine[..., None]), tar * 0.85)
    h = h * (1 - tar) + tar * (h.mean() + 0.03) - crk * 0.05 * (1 - tar)
    oil = smooth(0.74, 0.86, tn(R, S, (4, 8, 16, 32, 64), 0.6))
    col = col * (1 - 0.15 * oil[..., None])
    cav = np.clip(gblur(h, 3) - h, 0, None)
    col = mix(col, C(0.45, 0.42, 0.38), smooth(0.0, 0.06, cav)[..., None] * 0.3 * (1 - tar[..., None]))
    col = finish(col, h, shadow_hs=4.0, bake_s=4.0, k=0.35, ao=0.3, ao_r=3)
    save_surface("asphalte", col, h, 5.0)


def terre_noire():
    """Terre noire de friche : grumeaux d'humus de toutes tailles, plaques un peu humides, escarbilles
    noires brillantes, éclats de brique, petits cailloux, radicelles et brindilles."""
    S = 1024
    R = rng(7505)
    n = tn(R, S, (4, 8, 16, 32, 64, 128), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.6)
    moist = smooth(0.55, 0.8, tn(R, S, (4, 8, 16, 32), 0.6))
    col = mix(C(0.16, 0.13, 0.105), C(0.12, 0.095, 0.08), moist) * (0.75 + 0.5 * gr[..., None])
    h = n * 0.12 + gr * 0.05
    for cells, fill, rlo, rhi, ht, lift in ((40, 0.5, 0.5, 1.0, 0.35, 1.12), (90, 0.6, 0.5, 1.0, 0.2, 1.08), (200, 0.7, 0.5, 1.0, 0.1, 1.05)):
        m, dome, cid, _ = wstones(R, S, cells, fill, rlo, rhi, rough=0.25, el=(0.65, 1.0))
        tint = per_id(cid, R, 0.85, 1.2)
        c = col * (tint * lift * (0.75 + 0.35 * dome))[..., None]
        a = smooth(0.0, 0.35, dome) * m
        col = mix(col, c, a)
        h = h + dome * m * ht
    col = col * (0.9 + 0.2 * fine[..., None])
    items = []
    for count, rlo, rhi in ((1200, 1.2, 3.0), (260, 3.0, 6.0), (30, 6, 10)):
        for _ in range(count):
            r = R.uniform(rlo, rhi)
            items.append((R.random() * S, R.random() * S, rock_poly(R, r, k=int(R.integers(4, 8)), jit=0.35), r))
    pal = [((0.42, 0.4, 0.37), 0.35), ((0.48, 0.24, 0.16), 0.2), ((0.06, 0.06, 0.07), 0.25), ((0.56, 0.53, 0.48), 0.2)]
    scol, sth, mask, prof, ids = stones_layer(R, S, items, pal, fine)
    bury = smooth(0.45, 0.75, tn(R, S, (16, 32, 64, 128), 0.6)) * (0.3 + 0.6 * (1 - prof))
    scol = mix(scol, col, bury[..., None] * 0.6)
    col = mix(col, scol, gblur(mask.astype(np.float32), 0.5))
    shine = mask & (scol.sum(-1) < 0.35)
    col = col + (shine * smooth(0.5, 0.95, prof) * 0.1)[..., None]
    h = h + sth * mask * 0.5
    img = to_img(col)
    d = ImageDraw.Draw(img)
    hm = Image.fromarray((np.clip(h * 0.8, 0, 1) * 255).astype(np.uint8), "L")
    dh = ImageDraw.Draw(hm)
    for pts, w in crack_paths(R, S, 40, seg=(3, 8), steps=(6, 18), turn=0.5, branch=0.5):
        c = tuple(int(v * R.uniform(0.8, 1.1)) for v in (96, 78, 58))
        for ox in (-S, 0, S):
            for oy in (-S, 0, S):
                q = [(px + ox, py + oy) for px, py in pts]
                d.line(q, fill=c, width=1)
                dh.line(q, fill=200, width=1)
    for _ in range(120):
        x, y = R.random(2) * S
        a = R.uniform(0, TAU)
        L = R.uniform(10, 36)
        c = tuple(int(v * R.uniform(0.7, 1.1)) for v in (84, 64, 44))
        wd = int(R.integers(2, 4))
        for ox, oy in offs(x, y, L + 2, S):
            seg = [(x + ox, y + oy), (x + ox + math.cos(a) * L, y + oy + math.sin(a) * L)]
            d.line(seg, fill=c, width=wd)
            d.line([(p[0] - 0.5, p[1] - 0.7) for p in seg], fill=tuple(min(255, int(v * 1.35)) for v in c), width=1)
            dh.line(seg, fill=230, width=wd)
    col = from_img(img)
    h = gblur(np.asarray(hm, np.float32) / 255.0, 0.6)
    col = finish(col, h, shadow_hs=7.0, bake_s=5.0, k=0.35, ao=0.45, ao_r=4)
    save_surface("terre_noire", col, h, 6.0)


def galets():
    """Plage de galets : galets arrondis serrés (granit moucheté, quartz blanc, basalte, calcaire beige,
    quelques veinés), petits graviers et sable gris dans les creux."""
    S = 1024
    R = rng(7506)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.6)
    n = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    sand = mix(C(0.36, 0.35, 0.33), C(0.48, 0.47, 0.44), n) * (0.8 + 0.4 * gr[..., None])
    # placement serré par rejet (grille de voisinage)
    cell = 64
    G = S // cell
    grid = [[[] for _ in range(G)] for _ in range(G)]
    peb = []

    def ok(x, y, r):
        gx, gy = int(x // cell), int(y // cell)
        for i in range(-2, 3):
            for j in range(-2, 3):
                for (px, py, pr, _) in grid[(gy + j) % G][(gx + i) % G]:
                    dx = (x - px + S / 2) % S - S / 2
                    dy = (y - py + S / 2) % S - S / 2
                    if dx * dx + dy * dy < ((r + pr) * 0.86) ** 2:
                        return False
        return True
    for rlo, rhi, tries in ((22, 40, 1600), (13, 24, 5000), (7, 14, 9000), (3, 7, 12000)):
        for _ in range(tries):
            x, y = R.random(2) * S
            r = R.uniform(rlo, rhi)
            if ok(x, y, r):
                el = R.uniform(0.6, 0.95)
                peb.append((x, y, r, el))
                grid[int(y // cell)][int(x // cell)].append((x, y, r, el))
    items = []
    for (x, y, r, el) in peb:
        a = R.uniform(0, TAU)
        ca, sa = math.cos(a), math.sin(a)
        pts = []
        for t in np.linspace(0, TAU, 28, endpoint=False):
            rr = r * (1 + 0.05 * math.sin(2 * t + a) + 0.03 * math.sin(3 * t))
            px, py = math.cos(t) * rr, math.sin(t) * rr * el
            pts.append((px * ca - py * sa, px * sa + py * ca))
        items.append((x, y, pts, r))
    N = len(items)
    ids = scatter(S, items)
    hn, mask = domes(ids, N)
    pal = [((0.6, 0.58, 0.56), 0.28), ((0.38, 0.37, 0.37), 0.2), ((0.82, 0.8, 0.76), 0.12), ((0.66, 0.6, 0.5), 0.16),
           ((0.22, 0.22, 0.23), 0.12), ((0.56, 0.48, 0.44), 0.12)]
    base = np.vstack([np.zeros((1, 3), np.float32), pal_pick(R, pal, N) * R.uniform(0.88, 1.1, (N, 1)).astype(np.float32)])
    rad = np.concatenate([[0.0], np.array([it[3] for it in items], np.float32)])
    prof = np.sqrt(np.clip(hn * 1.15, 0, 1))
    # mouchetures (granit) sur une partie des galets, veines de quartz sur d'autres
    speck_on = np.concatenate([[0], R.random(N) < 0.45])[ids]
    sp = (R.random((S, S)) < 0.08).astype(np.float32)
    sp = gblur(sp, 0.45) * 1.6
    vein_on = np.concatenate([[0], R.random(N) < 0.12])[ids]
    vang = np.concatenate([[0.0], R.uniform(0, TAU, N)]).astype(np.float32)[ids]
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    vw = (tn(R, S, (8, 16, 32), 0.6) - 0.5) * 30
    vein = np.exp(-((np.sin((xx * np.cos(vang) + yy * np.sin(vang) + vw) / 11.0)) / 0.1) ** 2)
    stex = tn(R, S, (32, 64, 128, 256), 0.7)
    scol = base[ids] * (0.86 + 0.28 * stex[..., None]) * (0.94 + 0.12 * fine[..., None])
    scol = mix(scol, scol * 0.6, np.clip(sp, 0, 1) * speck_on * 0.6)
    scol = mix(scol, C(0.88, 0.86, 0.82), vein * vein_on * 0.85)
    col = mix(sand, scol, gblur(mask.astype(np.float32), 0.6))
    hst = prof * np.minimum(1.0, 0.2 + rad / 30)[ids]
    h = hst * mask * 0.9 + n * 0.05 + gr * 0.02 * (1 - mask)
    h = gblur(h, 0.7)
    # sable resté sur le bas des galets (vers le bas de l'image : dépôt)
    col = finish(col, h, shadow_hs=18.0, bake_s=5.0, k=0.45, ao=0.4, ao_r=6)
    # petit reflet lisse
    gx, gy = grads(h)
    spec = np.clip(-(gx * 0.45 + gy * 0.6) * 40, 0, 1) ** 3 * mask
    col = col + spec[..., None] * 0.08
    save_surface("galets", col, h, 6.0)


def mousse_spores():
    """Mousse de la Cathédrale des Spores : coussins bombés bleu-vert serrés (creux sombres), pousses
    étoilées fines, et, en petites colonies, des sporanges sur tiges dont les capsules luisent (cyan,
    turquoise, quelques violettes). Fond sombre et points lumineux : utilisable comme carte d'émission."""
    S, K = 1024, 2
    S2 = S * K
    R = rng(7507)
    hue = tn(R, S, (4, 8, 16, 32), 0.7)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    cush = np.zeros((S, S), np.float32)
    for cells, amp in ((14, 1.0), (30, 0.6)):
        _, ed, cid, dx, dy = worley(R, S, cells, 0.9)
        cush = np.maximum(cush, smooth(0.0, S / cells * 0.45, ed) ** 0.7 * per_id(cid, R, 0.7, 1.0) * amp)
    cush = 0.25 + 0.75 * gblur(cush, 3.0)
    base = mix(C(0.03, 0.07, 0.065), C(0.06, 0.15, 0.13), cush)
    img = to_img(up(base, K))
    d = ImageDraw.Draw(img)
    hm = Image.fromarray((np.clip(up(cush * 0.6, K), 0, 1) * 255).astype(np.uint8), "L")
    dh = ImageDraw.Draw(hm)
    teal = np.array((0.12, 0.46, 0.4))
    blue = np.array((0.1, 0.32, 0.46))
    lime = np.array((0.3, 0.52, 0.28))
    for layer, (count, bright, rr) in enumerate(((90000, 0.55, (4, 8)), (70000, 0.85, (3, 7)), (30000, 1.15, (2.5, 5)))):
        xs = R.random((count, 2)) * S2
        for x, y in xs:
            xi, yi = int(x / K) % S, int(y / K) % S
            cv = cush[yi, xi]
            if cv < 0.15 * layer:
                continue
            hv = hue[yi, xi]
            c = teal * (1 - hv) + blue * hv
            if R.random() < 0.08:
                c = lime
            c = c * bright * (0.35 + 0.8 * cv) * R.uniform(0.8, 1.2)
            col = tuple(int(np.clip(v, 0, 1) * 255) for v in c)
            r = R.uniform(*rr)
            a0 = R.uniform(0, TAU)
            hvv = int(80 + 150 * cv + layer * 15)
            for ox, oy in offs(x, y, r + 2, S2):
                X, Y = x + ox, y + oy
                for k in range(5):
                    a = a0 + k * TAU / 5
                    d.line([(X, Y), (X + math.cos(a) * r, Y + math.sin(a) * r)], fill=col, width=1)
                dh.ellipse((X - r * 0.6, Y - r * 0.6, X + r * 0.6, Y + r * 0.6), fill=hvv)
    glow = Image.new("L", (S2, S2), 0)
    dg = ImageDraw.Draw(glow)
    gcol = Image.new("RGB", (S2, S2), (0, 0, 0))
    dc = ImageDraw.Draw(gcol)
    for _ in range(150):
        cx, cy = R.random(2) * S2
        u = R.random()
        cc = (110, 255, 236) if u < 0.6 else ((140, 210, 255) if u < 0.88 else (196, 150, 255))
        for _ in range(int(R.integers(5, 22))):
            x, y = cx + R.normal(0, 22), cy + R.normal(0, 22)
            a = R.uniform(0, TAU)
            L = R.uniform(5, 14)
            r = R.uniform(2.0, 4.2)
            for ox, oy in offs(x, y, L + r * 5, S2):
                X, Y = x + ox, y + oy
                ex, ey = X + math.cos(a) * L, Y + math.sin(a) * L
                d.line([(X, Y), (ex, ey)], fill=(70, 120, 100), width=2)
                d.ellipse((ex - r, ey - r, ex + r, ey + r), fill=cc)
                d.ellipse((ex - r * 0.45, ey - r * 0.45, ex + r * 0.45, ey + r * 0.45), fill=(235, 255, 250))
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
    save_surface("mousse_spores", col, h * 0.7 + cush * 0.3, 4.0)


def sable_gris():
    """Sable gris de la côte : grain fin, rides de vent (minéraux sombres dans les creux), zones plus
    claires et sèches, coquilles brisées, petits galets, débris d'algues sèches."""
    S = 1024
    R = rng(7508)
    n = tn(R, S, (2, 4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (256, 512, 1024), 0.85)
    gr = grain(R, S, 0.5)
    gr2 = grain(R, S, 1.0)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    wx = (tn(R, S, (2, 4, 8, 16), 0.6) - 0.5) * 70
    wy = (tn(R, S, (2, 4, 8), 0.6) - 0.5) * 30
    ph = (yy + wx) / S * 28 * TAU + xx / S * 3 * TAU + (tn(R, S, (4, 8, 16), 0.6) - 0.5) * 4
    rip = 0.5 + 0.5 * np.sin(ph + 0.6 * np.sin(ph))
    amp = 0.45 + 0.55 * smooth(0.3, 0.7, tn(R, S, (4, 8, 16), 0.6))
    ripple = rip * amp
    col = mix(C(0.5, 0.49, 0.46), C(0.58, 0.57, 0.53), smooth(0.25, 0.75, n))
    trough = (1 - rip) * amp
    col = mix(col, C(0.36, 0.36, 0.36), smooth(0.55, 0.95, trough) * 0.3)
    col = col * (0.82 + 0.36 * gr[..., None]) * (0.93 + 0.14 * gr2[..., None])
    sp = R.random((S, S))
    col = mix(col, C(0.85, 0.83, 0.78), (sp > 0.985) * 0.6)
    col = mix(col, C(0.12, 0.12, 0.13), (sp < 0.02) * 0.6)
    h = ripple * 0.3 + n * 0.25 + gr * 0.03 + fine * 0.02
    # coquilles et galets
    items = []
    for count, rlo, rhi in ((260, 1.5, 4), (70, 4, 9)):
        for _ in range(count):
            r = R.uniform(rlo, rhi)
            items.append((R.random() * S, R.random() * S, rock_poly(R, r, k=int(R.integers(5, 9)), jit=0.25, sm=1), r))
    pal = [((0.86, 0.82, 0.76), 0.35), ((0.74, 0.62, 0.55), 0.15), ((0.42, 0.42, 0.44), 0.3), ((0.62, 0.6, 0.58), 0.2)]
    scol, sth, mask, prof, _ = stones_layer(R, S, items, pal, fine)
    col = mix(col, scol, gblur(mask.astype(np.float32), 0.5))
    h = h + sth * mask * 0.4
    img = to_img(col)
    d = ImageDraw.Draw(img)
    hm = Image.fromarray((np.clip(h, 0, 1) * 255).astype(np.uint8), "L")
    dh = ImageDraw.Draw(hm)
    # coquilles striées (moules, coques) brisées
    for _ in range(70):
        x, y = R.random(2) * S
        r = R.uniform(4, 8)
        a = R.uniform(0, 360)
        dark = R.random() < 0.25
        for ox, oy in offs(x, y, r + 2, S):
            box = (x + ox - r, y + oy - r * 0.8, x + ox + r, y + oy + r * 0.8)
            if dark:
                d.pieslice(box, a, a + R.uniform(120, 220), fill=(58, 60, 72))
                d.arc(box, a, a + 180, fill=(120, 130, 150), width=1)
            else:
                d.pieslice(box, a, a + R.uniform(140, 260), fill=(226, 214, 196))
                for k in range(min(4, int(r * 0.7 / 2))):
                    d.arc((box[0] + k * 2, box[1] + k * 2, box[2] - k * 2, box[3] - k * 2), a, a + 160, fill=(180, 160, 140), width=1)
            dh.pieslice(box, a, a + 180, fill=200)
    # laisse d'algues sèches
    for pts, w in crack_paths(R, S, 30, seg=(3, 8), steps=(4, 12), turn=0.6, branch=0.5):
        c = tuple(int(v * R.uniform(0.7, 1.1)) for v in (54, 46, 34))
        for ox in (-S, 0, S):
            for oy in (-S, 0, S):
                q = [(px + ox, py + oy) for px, py in pts]
                d.line(q, fill=c, width=2 if w > 1.5 else 1)
                dh.line(q, fill=190, width=2)
    col = from_img(img)
    h = gblur(np.asarray(hm, np.float32) / 255.0, 0.7)
    col = finish(col, h, shadow_hs=5.0, bake_s=3.0, k=0.3, ao=0.25, ao_r=6)
    save_surface("sable_gris", col, h, 5.0)


def sols():
    for f in (herbe_seche, gravier, beton, asphalte, terre_noire, galets, mousse_spores, sable_gris):
        f()
# =================================================================== le bâti (une tuile ≈ 3 m)

def run_down(src, L, H=None):
    """Coulures : chaque source s'étire vers le bas (décroissance exponentielle sur L px), raccordable."""
    Hh = src.shape[0]
    y = np.arange(Hh, dtype=np.float32)
    k = np.exp(-y / L)
    k[0] = 1.0
    k = k / k.sum() * (L / 2)
    Fk = np.fft.rfft(k)
    out = np.fft.irfft(np.fft.rfft(src, axis=0) * Fk[:, None], n=Hh, axis=0)
    return np.clip(out, 0, None).astype(np.float32)


def vstreak(R, S, octs=(16, 32, 64, 128, 256), fall=0.65, stretch=8, H=None):
    """Bruit étiré verticalement (coulures, ruissellements), raccordable."""
    H = H or S
    return tn(R, S, octs, fall, H=H, oy=tuple(max(1, o * H // S // stretch) for o in octs))


def brick_layout(W, H, courses, per_row, bond="english", jw=3.0, rr=2.0):
    """Appareil de briques (raccordable si W/per_row et H/courses tombent juste) :
    id de brique, distance au bord (px), u, v, rang."""
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    ch = H / courses
    row = np.floor(yy / ch).astype(np.int32)
    v = (yy - row * ch) / ch
    P = W / per_row
    if bond == "english":
        st = (row % 2 == 0)
        period = np.where(st, P, P / 2)
        off = np.where(st, 0.0, P / 4)
    else:
        period = np.full_like(xx, P)
        off = (row % 2) * (P / 2)
    xr = np.mod(xx + off, W)
    idx = np.floor(xr / period).astype(np.int32)
    u = (xr - idx * period) / period
    dx = np.minimum(u, 1 - u) * period
    dy = np.minimum(v, 1 - v) * ch
    e = np.minimum(dx, dy)
    corner = (dx < rr + jw / 2) & (dy < rr + jw / 2)
    cx, cy = rr + jw / 2 - dx, rr + jw / 2 - dy
    e = np.where(corner, rr + jw / 2 - np.hypot(np.maximum(cx, 0), np.maximum(cy, 0)), e)
    bid = row * 1000 + idx
    return bid, e, u, v, row


BRICK_RED = [((0.5, 0.22, 0.15), 0.3), ((0.43, 0.19, 0.14), 0.22), ((0.56, 0.28, 0.18), 0.14), ((0.36, 0.16, 0.13), 0.12),
             ((0.6, 0.34, 0.22), 0.07), ((0.28, 0.14, 0.13), 0.08), ((0.46, 0.27, 0.22), 0.07)]


def brick_surface(R, W, H, courses, per_row, bond="english", jw=3.2, pal=None, soot=0.5, efflo=0.5, spall=0.04):
    """Mur de briques industrielles : couleur, hauteur, masque de mortier (0..1), id. Cuissons variées
    (rouges, orangées, recuites sombres), arêtes émoussées, piqûres, mortier creusé et sableux, suie en
    coulures verticales, efflorescences blanches, quelques briques épaufrées."""
    big = max(W, H)
    bid, e, u, v, row = brick_layout(W, H, courses, per_row, bond, jw)
    en = tn(R, big, (32, 64, 128, 256), 0.7)[:H, :W]
    e2 = e + (en - 0.5) * 3.0
    face = smooth(jw * 0.5, jw * 0.5 + 2.2, e2)
    mortar = 1 - smooth(jw * 0.5 - 0.6, jw * 0.5 + 0.6, e2)
    pal = pal or BRICK_RED
    ub, inv = np.unique(bid, return_inverse=True)
    inv = inv.reshape(bid.shape)
    nb = len(ub)
    bc = pal_pick(R, pal, nb) * R.uniform(0.88, 1.1, (nb, 1)).astype(np.float32)
    col = bc[inv]
    # dégradé de cuisson dans la brique, taches, mouchetures
    gdir = R.uniform(-1, 1, nb).astype(np.float32)[inv]
    col = col * (1 + 0.12 * gdir * (u - 0.5))[..., None]
    n1 = tn(R, big, (16, 32, 64, 128), 0.6)[:H, :W]
    f1 = tn(R, big, (128, 256, 512), 0.8)[:H, :W]
    g1 = grain(R, big, 0.5)[:H, :W]
    col = col * (0.86 + 0.28 * n1[..., None]) * (0.9 + 0.2 * g1[..., None]) * (0.95 + 0.1 * f1[..., None])
    sp = R.random((H, W))
    col = mix(col, col * 0.55, (sp < 0.012) * 0.8)
    col = mix(col, C(0.82, 0.74, 0.6), (sp > 0.994) * 0.5)
    from generate_braise_v70 import pores
    po = pores(R, big, int(W * H / 420), 0.5, 1.5)[:H, :W]
    col = col * (1 - 0.35 * po[..., None])
    # briques épaufrées
    spl = (R.random(nb) < spall).astype(np.float32)[inv] * smooth(0.45, 0.6, tn(R, big, (8, 16, 32), 0.6)[:H, :W])
    col = mix(col, col * C(1.18, 1.12, 1.0) * (0.85 + 0.3 * g1[..., None]), spl * face)
    # mortier : chaux grise sableuse, creusée
    mcol = mix(C(0.5, 0.48, 0.44), C(0.62, 0.6, 0.55), tn(R, big, (32, 64, 128), 0.6)[:H, :W]) * (0.8 + 0.4 * g1[..., None])
    col = mix(mcol, col, face)
    h = face * (0.75 + 0.15 * n1 + 0.06 * f1) - po * 0.05 - spl * 0.25 + mortar * (0.15 + 0.15 * g1)
    # suie (coulures verticales) et salissures
    st = vstreak(R, W, (16, 32, 64, 128, 256), 0.75, 5, H=H)
    sootm = smooth(0.45, 0.85, st) * soot * (0.7 + 0.3 * tn(R, big, (8, 16), 0.6)[:H, :W])
    col = col * (1 - 0.4 * sootm[..., None])
    col = mix(col, C(0.12, 0.11, 0.1), sootm * 0.2)
    # efflorescences : voile blanc autour des joints, par plaques
    jb = gblur(mortar, 2.5)
    ef = smooth(0.58, 0.78, tn(R, big, (8, 16, 32, 64, 128), 0.65)[:H, :W]) * efflo
    efm = np.clip(ef * (0.4 + jb * 1.8) * (0.7 + 0.6 * f1), 0, 1)
    col = mix(col, C(0.86, 0.85, 0.8), efm * 0.65)
    return col.astype(np.float32), h.astype(np.float32), mortar, face, inv


def brique():
    """Brique rouge d'usine (appareil anglais : un rang de panneresses, un rang de boutisses),
    cuissons variées, suie, efflorescences. 40 rangs pour 3 m."""
    S = 1024
    R = rng(7521)
    col, h, mortar, face, inv = brick_surface(R, S, S, 40, 13, "english", soot=0.55, efflo=0.55)
    col = finish(col, h, shadow_hs=3.0, bake_s=4.0, k=0.3, ao=0.35, ao_r=3)
    save_surface("brique", col, h, 5.0)


def peel_mask(R, S, cover, H=None, scale=(4, 8, 16, 32, 64, 128), sharp=0.03):
    """Masque d'écaillage (1 = peinture présente) et bord de l'écaille (pour l'ombre)."""
    H = H or S
    big = max(S, H)
    t = tn(R, big, scale, 0.62)[:H, :S] + (tn(R, big, (128, 256, 512), 0.7)[:H, :S] - 0.5) * 0.08
    thr = np.quantile(t, 1 - cover)
    m = smooth(thr - sharp, thr + sharp, t)
    edge = np.exp(-((t - thr) / (sharp * 1.6)) ** 2)
    return m.astype(np.float32), edge.astype(np.float32)


def brique_peinte():
    """Brique peinte en blanc cassé (badigeon de friche), écaillée par plaques : on voit la brique rouge,
    parfois une vieille couche vert d'eau ; coulures grises, salissures en bas des joints."""
    S = 1024
    R = rng(7522)
    col, h, mortar, face, inv = brick_surface(R, S, S, 40, 13, "stretcher", soot=0.2, efflo=0.2)
    paint, pedge = peel_mask(R, S, 0.8, scale=(8, 16, 32, 64, 128, 256))
    old, oedge = peel_mask(R, S, 0.4, scale=(16, 32, 64, 128))
    gr = grain(R, S, 0.6)
    fine = tn(R, S, (64, 128, 256, 512), 0.75)
    pc = mix(C(0.8, 0.78, 0.72), C(0.88, 0.86, 0.8), fine) * (0.94 + 0.12 * gr[..., None])
    oc = C(0.56, 0.68, 0.6) * (0.9 + 0.2 * gr[..., None])
    col = mix(col, oc, old * (1 - paint) * 0.9)
    col = mix(col, pc * (0.88 + 0.12 * face[..., None]), paint)
    col = col * (1 - 0.3 * pedge[..., None] * (1 - paint[..., None]))
    st = vstreak(R, S, (16, 32, 64, 128, 256), 0.65, 6)
    dirt = smooth(0.5, 0.85, st)
    col = mix(col, col * C(0.62, 0.6, 0.56), dirt * 0.5)
    jd = run_down(gblur(mortar, 1.0) * (1 - smooth(0.4, 0.6, tn(R, S, (16, 32, 64), 0.6))), 14.0)
    col = col * (1 - 0.18 * np.clip(jd, 0, 1)[..., None] * paint[..., None])
    h = h + paint * 0.04 + pedge * 0.03
    col = finish(col, h, shadow_hs=3.0, bake_s=4.0, k=0.3, ao=0.3, ao_r=3)
    save_surface("brique_peinte", col, h, 5.0)


def beton_brut():
    """Béton banché : empreintes horizontales des planches de coffrage (veinage du bois, petites
    bavures aux joints), trous de banches bouchés en grille, bullage, coulures de pluie verticales,
    traînées blanches de calcite, mousse et lichens rares."""
    S = 1024
    R = rng(7523)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    nb = 20
    bh = S / nb
    brow = np.floor(yy / bh).astype(np.int32)
    v = (yy - brow * bh) / bh
    # chaque planche : longueur, décalage, veinage propre
    grain_w = tn(R, S, (64, 128, 256, 512), 0.7, oy=(4, 8, 16, 32))
    wood = tn(R, S, (8, 16, 32, 64), 0.6, oy=(64, 128, 256, 512))
    wood = np.sin(wood * 60 + (tn(R, S, (4, 8), 0.6) - 0.5) * 30) * 0.5 + 0.5
    boff = R.uniform(0, S, nb).astype(np.float32)[brow]
    blen = R.choice([S / 2, S / 4, S], nb).astype(np.float32)[brow]
    bu = np.mod(xx + boff, blen)
    bx_edge = np.minimum(bu, blen - bu)
    bdy = np.minimum(v, 1 - v) * bh
    seam = np.exp(-(bdy / 1.2) ** 2)
    butt = np.exp(-(bx_edge / 1.2) ** 2)
    plank_lvl = R.uniform(-1, 1, nb * 8).astype(np.float32)[(brow * 8 + np.mod(np.floor((xx + boff) / blen), np.round(S / blen)).astype(np.int32))]
    n = tn(R, S, (2, 4, 8, 16, 32), 0.6)
    gr = grain(R, S, 0.5)
    col = mix(C(0.52, 0.52, 0.5), C(0.6, 0.6, 0.57), n)
    col = col * (1 + 0.06 * plank_lvl)[..., None] * (0.9 + 0.1 * wood[..., None]) * (0.88 + 0.24 * gr[..., None])
    h = 0.5 + plank_lvl * 0.04 + wood * 0.05 + grain_w * 0.04 + gr * 0.03
    fin = seam * smooth(0.35, 0.6, tn(R, S, (32, 64, 128), 0.6))
    col = col * (1 - 0.35 * seam[..., None]) * (1 + 0.15 * fin[..., None]) * (1 - 0.2 * butt[..., None])
    h = h - seam * 0.12 + fin * 0.15 - butt * 0.08
    from generate_braise_v70 import pores
    po = pores(R, S, 1400, 0.5, 1.5)
    col = col * (1 - 0.35 * po[..., None])
    h = h - po * 0.12
    # trous de banches : grille 5 x 4 (60 cm x 75 cm)
    ties = np.zeros((S, S), np.float32)
    plug = np.zeros((S, S), np.float32)
    for i in range(5):
        for j in range(4):
            cx = (i + 0.5) * S / 5
            cy = (j + 0.5) * S / 4 + bh * 0.5
            dd = np.hypot((xx - cx + S / 2) % S - S / 2, (yy - cy + S / 2) % S - S / 2)
            ties = np.maximum(ties, 1 - smooth(5.5, 7.0, dd))
            plug = np.maximum(plug, np.exp(-((dd - 7.5) / 1.6) ** 2))
    col = mix(col, C(0.32, 0.31, 0.3) * (0.8 + 0.4 * gr[..., None]), ties * 0.9)
    col = col * (1 - 0.2 * plug[..., None])
    h = h - ties * 0.2 - plug * 0.03
    # coulures sous les trous et ruissellements
    st = vstreak(R, S, (16, 32, 64, 128, 256), 0.6, 8)
    rain = smooth(0.52, 0.85, st) * 0.7
    tie_run = run_down(ties, 40.0) * 0.35 * (0.5 + vstreak(R, S, (32, 64, 128), 0.6, 4))
    col = col * (1 - 0.35 * rain[..., None]) * (1 - 0.4 * np.clip(tie_run, 0, 1)[..., None])
    col = mix(col, col * C(1.05, 0.9, 0.75), np.clip(tie_run, 0, 1) * 0.4)
    cal = smooth(0.7, 0.88, vstreak(R, S, (16, 32, 64, 128), 0.6, 10)) * smooth(0.5, 0.7, tn(R, S, (4, 8), 0.6))
    col = mix(col, C(0.86, 0.86, 0.83), cal * 0.5)
    lc, la = lichen_layer(R, S, -0.4)
    col = mix(col, lc, la * 0.5)
    col = finish(col, h, shadow_hs=2.0, bake_s=4.0, k=0.25, ao=0.25, ao_r=4)
    save_surface("beton_brut", col, h, 4.0)


def corrugation(S, waves, H=None):
    """Profil d'une tôle ondulée (ondes verticales : le long de y), hauteur 0..1 et pente."""
    H = H or S
    xx = np.arange(S, dtype=np.float32)[None, :].repeat(H, 0)
    ph = xx / S * waves * TAU
    return (0.5 + 0.5 * np.sin(ph)).astype(np.float32), np.cos(ph).astype(np.float32)


def sheet_seams(R, S, waves, rows=1):
    """Recouvrement horizontal des tôles (une ligne par tuile) et rangées de vis (sur les crêtes)."""
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    ys = [S * (k + 0.62) / rows for k in range(rows)]
    lap = np.zeros((S, S), np.float32)
    screws = np.zeros((S, S), np.float32)
    for y0 in ys:
        dy = (yy - y0 + S / 2) % S - S / 2
        lap = np.maximum(lap, np.exp(-(dy / 2.0) ** 2))
        for k in range(waves):
            if k % 2:
                continue
            cx = (k + 0.25) * S / waves
            sy = y0 - 14
            dd = np.hypot((xx - cx + S / 2) % S - S / 2, (yy - sy + S / 2) % S - S / 2)
            screws = np.maximum(screws, 1 - smooth(3.0, 4.6, dd))
    above = np.zeros((S, S), np.float32)
    for y0 in ys:
        dy = (yy - y0 + S / 2) % S - S / 2
        above = np.maximum(above, smooth(-60, -1, dy) * (dy < 0))
    return lap, screws, above


def tole_rouille():
    """Tôle ondulée galvanisée rongée de rouille : ondes verticales (40 par 3 m), recouvrement horizontal
    vissé, zinc gris encore visible par plaques, rouille orange à brun noir plus forte dans les creux et
    sous le recouvrement, coulures, quelques trous rongés."""
    S = 1024
    R = rng(7524)
    waves = 40
    prof, slope = corrugation(S, waves)
    lap, screws, above = sheet_seams(R, S, waves)
    n = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    n2 = tn(R, S, (16, 32, 64, 128, 256), 0.7)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.5)
    st = vstreak(R, S, (16, 32, 64, 128, 256), 0.65, 8)
    n = tn(R, S, (16, 32, 64, 128), 0.65)
    zinc = mix(C(0.42, 0.43, 0.42), C(0.54, 0.55, 0.53), n2) * (0.88 + 0.24 * gr[..., None])
    rust_t = np.clip(n * 0.6 + st * 0.5 + (1 - prof) * 0.25 + lap * 0.3 - 0.15, 0, 1)
    gr2 = grain(R, S, 0.9)
    rcover = smooth(0.26, 0.31, rust_t + (fine - 0.5) * 0.3 + (gr2 - 0.5) * 0.12)
    rcol = rust_palette(np.clip(rust_t + (gr2 - 0.5) * 0.3, 0, 1), n2) * (0.72 + 0.56 * gr[..., None]) * (0.85 + 0.3 * fine[..., None])
    col = mix(zinc, rcol, rcover)
    # écailles de rouille (plus sombres, en relief)
    scale = smooth(0.62, 0.7, n2 * 0.6 + rust_t * 0.6) * rcover
    col = col * (1 - 0.25 * scale[..., None])
    # coulures sous les vis et le recouvrement
    run = np.clip(run_down(screws * 1.0 + lap * 0.25, 90.0), 0, 1) * (0.6 + 0.6 * st)
    col = mix(col, C(0.4, 0.18, 0.07), np.clip(run, 0, 1) * 0.55)
    # trous rongés
    holes = smooth(0.9, 0.92, tn(R, S, (32, 64, 128, 256), 0.65) * 0.5 + rust_t * 0.6) * (1 - prof * 0.8)
    hrim = np.clip(gblur(holes, 2.5) * 3, 0, 1)
    col = mix(col, C(0.5, 0.22, 0.08), hrim * 0.6)
    col = mix(col, C(0.03, 0.025, 0.02), smooth(0.4, 0.7, holes))
    # vis : tête hexagonale, rondelle
    col = mix(col, C(0.35, 0.33, 0.3) * (0.8 + 0.4 * fine[..., None]), screws)
    h = prof * 0.8 + lap * 0.06 + scale * 0.03 * fine + screws * 0.15 - smooth(0.4, 0.7, holes) * 0.3 + gr * 0.01
    h = h + above * 0.04
    col = finish(col, h, shadow_hs=2.0, bake_s=6.0, k=0.35, ao=0.25, ao_r=4)
    save_surface("tole_rouille", col, h, 8.0)


def tole_peinte():
    """Tôle ondulée peinte (bleu-vert passé, farinée par le soleil) : éclats de peinture jusqu'au zinc,
    rouille aux vis et sous le recouvrement, rayures, coulures sombres."""
    S = 1024
    R = rng(7525)
    waves = 40
    prof, slope = corrugation(S, waves)
    lap, screws, above = sheet_seams(R, S, waves)
    n = tn(R, S, (2, 4, 8, 16, 32), 0.6)
    n2 = tn(R, S, (16, 32, 64, 128, 256), 0.7)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.5)
    st = vstreak(R, S, (16, 32, 64, 128, 256), 0.65, 8)
    n = tn(R, S, (8, 16, 32, 64), 0.6)
    paint = mix(C(0.2, 0.37, 0.39), C(0.28, 0.46, 0.46), n) * (0.94 + 0.12 * gr[..., None])
    chalk = smooth(0.4, 0.8, n2) * prof
    paint = mix(paint, C(0.55, 0.66, 0.64), chalk * 0.35)
    zinc = mix(C(0.5, 0.52, 0.52), C(0.64, 0.65, 0.64), n2)
    pm, pedge = peel_mask(R, S, 0.88, scale=(16, 32, 64, 128, 256), sharp=0.02)
    rust_t = np.clip(n2 * 0.5 + st * 0.4, 0, 1)
    rcol = rust_palette(rust_t, n) * (0.85 + 0.3 * gr[..., None])
    under = mix(zinc, rcol, smooth(0.45, 0.6, rust_t + (1 - prof) * 0.2))
    col = mix(under, paint, pm)
    col = col * (1 - 0.25 * pedge[..., None] * (1 - pm[..., None]))
    # rouille autour des vis et sous le recouvrement
    sr = gblur(screws, 2.5) * 3 * smooth(0.3, 0.6, fine + 0.2)
    rz = np.clip(sr + lap * 0.8 * smooth(0.45, 0.6, n2), 0, 1)
    col = mix(col, rcol, smooth(0.2, 0.6, rz) * 0.85)
    run = np.clip(run_down(screws + lap * 0.3, 110.0), 0, 1) * (0.5 + 0.7 * st)
    col = mix(col, C(0.42, 0.2, 0.08), np.clip(run, 0, 1) * 0.5)
    dirt = smooth(0.55, 0.85, st)
    col = col * (1 - 0.25 * dirt[..., None])
    # rayures horizontales
    img = to_img(col)
    d = ImageDraw.Draw(img)
    for _ in range(40):
        x, y = R.uniform(0, S), R.uniform(0, S)
        L = R.uniform(30, 160)
        a = R.normal(0, 0.15)
        for ox, oy in offs(x, y, L, S):
            d.line([(x + ox, y + oy), (x + ox + math.cos(a) * L, y + oy + math.sin(a) * L)], fill=(120, 132, 128), width=1)
    col = mix(col, from_img(img), 0.6)
    col = mix(col, C(0.35, 0.33, 0.3), screws)
    h = prof * 0.8 + lap * 0.06 + screws * 0.15 + pm * 0.02 + above * 0.04 + gr * 0.01
    col = finish(col, h, shadow_hs=2.0, bake_s=6.0, k=0.35, ao=0.25, ao_r=4)
    save_surface("tole_peinte", col, h, 8.0)


def bardage():
    """Bardage de planches verticales (16 par 3 m) grisées par les intempéries : fil du bois le long de y,
    gerces, nœuds, joints sombres entre les planches, aboutements, clous rouillés et leurs coulures,
    quelques planches remplacées plus brunes, traces d'une vieille peinture rouge."""
    S = 1024
    R = rng(7526)
    nbd = 16
    bw = S / nbd
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    bi = np.floor(xx / bw).astype(np.int32)
    u = (xx - bi * bw) / bw
    # aboutement : chaque planche a une coupure à une hauteur propre
    cut = R.uniform(0, S, nbd).astype(np.float32)[bi]
    dyc = (yy - cut + S / 2) % S - S / 2
    seg = (dyc > 0).astype(np.int32)
    pid = bi * 2 + seg
    np_ = nbd * 2
    tone = R.uniform(0.85, 1.12, np_).astype(np.float32)[pid]
    brown = (R.random(np_) < 0.15).astype(np.float32)[pid]
    redp = (R.random(np_) < 0.2).astype(np.float32)[pid]
    shift = R.uniform(0, S, np_).astype(np.float32)[pid]
    ys = (yy + shift) % S
    # veinage : bruit très étiré le long de y, décalé par planche
    fib = tn(R, S, (32, 64, 128, 256, 512, 1024), 0.95, oy=(1, 2, 3, 6, 12, 24))
    fib2 = tn(R, S, (128, 256, 512, 1024), 1.0, oy=(2, 4, 8, 16))
    rings = tn(R, S, (4, 8, 16), 0.6, oy=(1, 1, 2))
    xs = np.mod(xx + bi * 37.0 + seg * 113.0, S)
    fibs = fib[ys.astype(np.int32) % S, xs.astype(np.int32) % S]
    fib2s = fib2[ys.astype(np.int32) % S, xs.astype(np.int32) % S]
    ring = np.sin((rings[ys.astype(np.int32) % S, xs.astype(np.int32) % S] * 40 + u * 3)) * 0.5 + 0.5
    gr = grain(R, S, 0.6)
    grey = mix(C(0.4, 0.38, 0.35), C(0.6, 0.58, 0.54), fibs)
    col = mix(grey, mix(C(0.36, 0.27, 0.19), C(0.5, 0.39, 0.28), fibs), brown * 0.85)
    col = col * tone[..., None] * (0.9 + 0.1 * ring[..., None]) * (0.78 + 0.44 * fib2s[..., None]) * (0.9 + 0.2 * gr[..., None])
    # gerces (fentes le long du fil)
    chk = smooth(0.84, 0.9, fib2s) * smooth(0.6, 0.72, tn(R, S, (8, 16, 32), 0.6, oy=(1, 2, 4)))
    col = col * (1 - 0.45 * chk[..., None])
    # vieille peinture rouge en traces
    gr = grain(R, S, 0.6)
    pt = smooth(0.7, 0.73, tn(R, S, (32, 64, 128, 256), 0.75, oy=(4, 8, 16, 32)) + (gr - 0.5) * 0.12) * redp
    col = mix(col, C(0.52, 0.17, 0.13) * (0.85 + 0.3 * gr[..., None]), pt * 0.85)
    # nœuds
    knots = np.zeros((S, S), np.float32)
    for _ in range(14):
        kx = (int(R.integers(nbd)) + R.uniform(0.25, 0.75)) * bw
        ky = R.uniform(0, S)
        r = R.uniform(4, 9)
        dd = np.hypot(xx - kx, ((yy - ky + S / 2) % S - S / 2) * 0.55)
        knots = np.maximum(knots, 1 - smooth(r * 0.6, r, dd))
        ringk = np.exp(-((dd - r * 1.4) / 1.5) ** 2) * (dd < r * 3)
        col = col * (1 - 0.15 * ringk[..., None])
    col = mix(col, C(0.2, 0.15, 0.11), knots * 0.85)
    # joints entre planches et aboutements
    ed = np.minimum(u, 1 - u) * bw
    gap = 1 - smooth(0.6, 1.8, ed)
    bev = np.exp(-((ed - 2.5) / 1.6) ** 2)
    butt = 1 - smooth(0.5, 1.6, np.abs(dyc))
    col = col * (1 - 0.85 * gap[..., None]) * (1 - 0.18 * bev[..., None]) * (1 - 0.8 * butt[..., None])
    h = 0.6 + tone * 0.1 + fibs * 0.06 + fib2s * 0.05 - chk * 0.15 - gap * 0.5 - bev * 0.05 - butt * 0.4 + (u - 0.5) * 0.05 * R.uniform(-1, 1)
    # clous (deux par planche, à deux hauteurs fixes de lisses) et coulures
    nails = np.zeros((S, S), np.float32)
    for rail in (S * 0.18, S * 0.68):
        for b in range(nbd):
            for side in (0.3, 0.7):
                nx_, ny_ = (b + side + R.normal(0, 0.03)) * bw, rail + R.normal(0, 3)
                dd = np.hypot(xx - nx_, (yy - ny_ + S / 2) % S - S / 2)
                nails = np.maximum(nails, 1 - smooth(2.0, 3.2, dd))
    run = np.clip(run_down(nails, 50.0) * (0.4 + vstreak(R, S, (32, 64, 128), 0.6, 4)), 0, 1)
    col = mix(col, C(0.36, 0.2, 0.1), run * 0.6)
    col = mix(col, C(0.2, 0.12, 0.08), nails)
    h = h + nails * 0.08
    # salissure : bas de la tuile légèrement plus sombre ? non (raccord) : coulures grises
    st = smooth(0.55, 0.85, vstreak(R, S, (16, 32, 64, 128), 0.6, 6))
    col = col * (1 - 0.25 * st[..., None])
    lc, la = lichen_layer(R, S, -0.2)
    col = mix(col, lc, la * 0.4)
    col = finish(col, h, shadow_hs=3.0, bake_s=5.0, k=0.3, ao=0.3, ao_r=3)
    save_surface("bardage", col, h, 5.0)


def weld_bead(S, line_pos, axis, R, width=5.0, H=None):
    """Cordon de soudure (raccordable) le long d'une ligne horizontale (axis 0) ou verticale (axis 1) :
    hauteur 0..1 avec ondulations des passes."""
    H = H or S
    yy, xx = np.mgrid[0:H, 0:S].astype(np.float32)
    if axis == 0:
        d = (yy - line_pos + H / 2) % H - H / 2
        t = xx
    else:
        d = (xx - line_pos + S / 2) % S - S / 2
        t = yy
    wob = (tn(R, max(S, H), (16, 32, 64), 0.6)[:H, :S] - 0.5) * 2.0
    prof = np.clip(1 - ((d - wob) / width) ** 2, 0, 1)
    rip = 0.85 + 0.15 * np.sin(t / 2.2 + d * 0.4)
    return (np.sqrt(prof) * rip).astype(np.float32), np.exp(-((d - wob) / (width * 2.2)) ** 2).astype(np.float32)


def acier_rouille():
    """Tôle d'acier épaisse rouillée : calamine sombre, rouille orange et brune granuleuse, piqûres,
    plaques d'écailles soulevées, une soudure horizontale et une verticale (tôles de 1,5 m), coulures."""
    S = 1024
    R = rng(7527)
    n = tn(R, S, (8, 16, 32, 64), 0.6)
    n2 = tn(R, S, (32, 64, 128, 256), 0.7)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.5)
    gr2 = grain(R, S, 1.0)
    st = vstreak(R, S, (16, 32, 64, 128, 256), 0.65, 6)
    t = np.clip(n * 0.7 + st * 0.3 + (gr2 - 0.5) * 0.3, 0, 1)
    col = rust_palette(t, n2) * (0.72 + 0.56 * gr[..., None]) * (0.85 + 0.3 * fine[..., None])
    mill = smooth(0.62, 0.68, tn(R, S, (16, 32, 64, 128), 0.65) + (gr2 - 0.5) * 0.1)
    col = mix(col, C(0.2, 0.19, 0.19) * (0.8 + 0.4 * gr[..., None]), mill * 0.85)
    # écailles soulevées
    _, ed, cid, _, _ = worley(R, S, 60, 0.9)
    flk = smooth(0.62, 0.7, per_id(cid, R, 0, 1) * 0.6 + n2 * 0.5) * smooth(1.0, 4.0, ed)
    fedge = flk * (1 - smooth(1.0, 6.0, ed))
    col = mix(col, rust_palette(np.full_like(t, 0.75), n2) * (0.8 + 0.4 * gr[..., None]), flk * 0.6)
    from generate_braise_v70 import pores
    pits = pores(R, S, 2500, 0.5, 1.6)
    col = col * (1 - 0.35 * pits[..., None])
    wb1, wh1 = weld_bead(S, 640, 0, R, 6.0)
    wb2, wh2 = weld_bead(S, 300, 1, R, 6.0)
    wb = np.maximum(wb1, wb2)
    heat = np.maximum(wh1, wh2)
    col = mix(col, C(0.25, 0.2, 0.18), heat * 0.35)
    col = mix(col, rust_palette(np.full_like(t, 0.55), n2) * (0.7 + 0.6 * gr[..., None]), smooth(0.05, 0.3, wb) * 0.8)
    run = np.clip(run_down(smooth(0.05, 0.3, wb1) * 0.6 + pits * 0.2, 80.0), 0, 1) * (0.5 + st)
    col = mix(col, C(0.38, 0.17, 0.07), np.clip(run, 0, 1) * 0.4)
    h = 0.5 + n * 0.05 + gr * 0.04 + fine * 0.03 + flk * 0.08 + fedge * 0.05 - pits * 0.12 + wb * 0.35
    col = finish(col, h, shadow_hs=2.0, bake_s=5.0, k=0.3, ao=0.3, ao_r=3)
    save_surface("acier_rouille", col, h, 5.0)


def metal_rivete():
    """Plaques d'acier rivetées (4 x 3 par 3 m) peintes en gris-vert industriel, usées : recouvrements,
    rangées de rivets à tête ronde, peinture écaillée aux arêtes et autour des rivets (rouille dessous),
    coulures de rouille, éraflures, taches d'huile."""
    S = 1024
    R = rng(7528)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    nx_, ny_ = 4, 3
    pw, ph = S / nx_, S / ny_
    ry = np.floor(yy / ph).astype(np.int32)
    offx = (ry % 2) * (pw / 2)
    xr = np.mod(xx + offx, S)
    rx = np.floor(xr / pw).astype(np.int32)
    u = (xr - rx * pw) / pw
    v = (yy - ry * ph) / ph
    pid = ry * 10 + rx
    ex = np.minimum(u, 1 - u) * pw
    ey = np.minimum(v, 1 - v) * ph
    e = np.minimum(ex, ey)
    n = tn(R, S, (4, 8, 16, 32), 0.6)
    n2 = tn(R, S, (32, 64, 128, 256), 0.7)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.5)
    st = vstreak(R, S, (16, 32, 64, 128, 256), 0.65, 6)
    tone = per_id(pid, R, 0.9, 1.08)
    paint = mix(C(0.3, 0.35, 0.32), C(0.4, 0.45, 0.41), n) * tone[..., None] * (0.92 + 0.16 * gr[..., None])
    paint = mix(paint, C(0.52, 0.56, 0.52), smooth(0.55, 0.85, n2) * 0.3)
    # rivets : rangées le long des bords, pas 1/12 du côté
    riv = np.zeros((S, S), np.float32)
    pitch = pw / 8
    for off in (9.0,):
        # bords verticaux
        cxl = off
        dxl = np.minimum(np.abs(u * pw - cxl), np.abs((1 - u) * pw - cxl))
        dyl = np.abs(np.mod(v * ph + pitch / 2, pitch) - pitch / 2)
        riv = np.maximum(riv, np.clip(1 - (dxl ** 2 + dyl ** 2) / 4.2 ** 2, 0, 1))
        dyt = np.minimum(np.abs(v * ph - off), np.abs((1 - v) * ph - off))
        dxt = np.abs(np.mod(u * pw + pitch / 2, pitch) - pitch / 2)
        riv = np.maximum(riv, np.clip(1 - (dxt ** 2 + dyt ** 2) / 4.2 ** 2, 0, 1))
    rivm = (riv > 0).astype(np.float32)
    rdome = np.sqrt(riv)
    # écaillage aux arêtes et aux rivets
    wearz = np.clip(np.exp(-e / 5.0) * 0.9 + gblur(rivm, 3.0) * 1.2 * (1 - rivm), 0, 1)
    chip = smooth(0.55, 0.6, wearz * 0.6 + n2 * 0.5 + (gr - 0.5) * 0.1)
    pm, pedge = peel_mask(R, S, 0.93, scale=(16, 32, 64, 128, 256), sharp=0.02)
    keep = pm * (1 - chip)
    rcol = rust_palette(np.clip(n2 + (gr - 0.5) * 0.3, 0, 1), n) * (0.75 + 0.5 * gr[..., None])
    col = mix(rcol, paint, keep)
    col = col * (1 - 0.25 * pedge[..., None] * (1 - keep[..., None]))
    run = np.clip(run_down((1 - keep) * 0.25 + rivm * 0.4, 70.0), 0, 1) * (0.4 + 0.8 * st)
    col = mix(col, C(0.4, 0.2, 0.09), np.clip(run, 0, 1) * 0.55)
    dirt = smooth(0.55, 0.85, st)
    col = col * (1 - 0.2 * dirt[..., None])
    # recouvrements : la plaque du dessus (y plus petit) recouvre ; joint sombre
    seam = 1 - smooth(0.4, 1.6, e)
    lip = np.exp(-((ey - 2.5) / 1.5) ** 2) * (v > 0.5)
    col = col * (1 - 0.75 * seam[..., None]) * (1 - 0.2 * lip[..., None])
    col = mix(col, col * 1.15, rdome[..., None] * 0.25)
    h = 0.5 + (1 - v) * 0.04 - seam * 0.3 + rdome * 0.35 + keep * 0.02 + n * 0.03 + gr * 0.01
    col = finish(col, h, shadow_hs=3.0, bake_s=5.0, k=0.3, ao=0.3, ao_r=3)
    save_surface("metal_rivete", col, h, 6.0)


def carrelage_usine():
    """Faïence blanche d'usine (carreaux 15 x 7,5 cm posés en quinconce), émail légèrement bombé et
    craquelé, joints gris encrassés, éclats montrant le biscuit beige, coulures de rouille et de crasse,
    deux carreaux tombés (colle peignée grise)."""
    S = 1024
    R = rng(7529)
    cols_, rows_ = 20, 40
    bid, e, u, v, row = brick_layout(S, S, rows_, cols_, "stretcher", jw=2.4, rr=3.0)
    ub, inv = np.unique(bid, return_inverse=True)
    inv = inv.reshape(bid.shape)
    nb = len(ub)
    n = tn(R, S, (4, 8, 16, 32), 0.6)
    fine = tn(R, S, (128, 256, 512), 0.8)
    gr = grain(R, S, 0.6)
    tone = R.uniform(0.94, 1.03, nb).astype(np.float32)[inv]
    tint = R.uniform(-0.02, 0.02, nb).astype(np.float32)[inv]
    glaze = C(0.86, 0.86, 0.82) * tone[..., None] + np.dstack([tint, tint * 0.5, -tint])
    face = smooth(1.2, 3.5, e)
    bulge = np.clip(np.sin(np.clip(u, 0, 1) * math.pi) * np.sin(np.clip(v, 0, 1) * math.pi), 0, 1) ** 0.3
    # craquelures de l'émail
    _, ce, _, _, _ = worley(R, S, 90, 0.9)
    wx, wy = tn(R, S, (16, 32, 64), 0.6), tn(R, S, (16, 32, 64), 0.6)
    ce = warp(ce, (wx - 0.5) * 8, (wy - 0.5) * 8)
    craz = (1 - smooth(0.2, 0.9, ce)) * smooth(0.6, 0.75, tn(R, S, (8, 16, 32), 0.6))
    col = glaze * (1 - 0.12 * craz[..., None])
    # éclats (biscuit)
    chips = smooth(0.86, 0.88, tn(R, S, (32, 64, 128), 0.65) + np.exp(-e / 4.0) * 0.2) * face
    col = mix(col, C(0.7, 0.62, 0.5) * (0.8 + 0.4 * gr[..., None]), chips)
    # carreaux tombés
    missing = np.isin(inv, R.choice(nb, 2, replace=False)).astype(np.float32)
    comb = 0.5 + 0.5 * np.sin(np.mgrid[0:S, 0:S][1] / 3.0 + np.mgrid[0:S, 0:S][0] / 3.0)
    adh = C(0.5, 0.5, 0.48) * (0.85 + 0.15 * comb[..., None]) * (0.85 + 0.3 * gr[..., None])
    grout = mix(C(0.4, 0.38, 0.34), C(0.52, 0.5, 0.45), n) * (0.8 + 0.4 * gr[..., None])
    col = mix(grout, col, face)
    col = mix(col, adh, missing)
    # crasse : voile gris-brun, coulures de rouille, traînées
    st = vstreak(R, S, (16, 32, 64, 128, 256), 0.65, 6)
    grime = smooth(0.45, 0.85, st * 0.7 + n * 0.5)
    col = mix(col, col * C(0.72, 0.68, 0.6), grime * 0.55)
    rs = smooth(0.82, 0.92, vstreak(R, S, (16, 32, 64, 128), 0.6, 10)) * smooth(0.4, 0.6, tn(R, S, (4, 8, 16), 0.6))
    col = mix(col, C(0.55, 0.32, 0.16), rs * 0.6)
    jd = run_down((1 - face) * smooth(0.5, 0.7, tn(R, S, (16, 32, 64), 0.6)), 10.0)
    col = col * (1 - 0.15 * np.clip(jd, 0, 1)[..., None])
    h = face * (0.6 + 0.03 * bulge) - chips * 0.12 - craz * 0.01 - missing * 0.5 + (1 - face) * 0.05 * gr + missing * comb * 0.05
    col = finish(col, h, shadow_hs=2.0, bake_s=3.0, k=0.2, ao=0.3, ao_r=3)
    # reflet de l'émail (léger)
    gx, gy = grads(gblur(h, 1.0))
    spec = np.clip(-(gx * 0.45 + gy * 0.6) * 30, 0, 1) ** 2 * face * (1 - missing) * (1 - chips)
    col = col + spec[..., None] * 0.06
    save_surface("carrelage_usine", col, h, 4.0)


def paves_port():
    """Pavés de granit du port (rangs de 15 cm, pavés de 18 à 28 cm ; une tuile ≈ 4 m) : granit gris et
    rosé moucheté, dessus bombés polis par les roues, arêtes épaufrées, joints de terre sombre et d'huile,
    un peu d'herbe et de mousse."""
    S = 1024
    R = rng(7530)
    rows = [S / 28] * 28
    bid, e, u, v = masonry(R, S, rows, 44, 84, rr=6.0)
    ub, inv = np.unique(bid, return_inverse=True)
    inv = inv.reshape(bid.shape)
    nb = len(ub)
    en = tn(R, S, (16, 32, 64, 128, 256), 0.7)
    e2 = e + (en - 0.5) * 7.0
    face = smooth(2.0, 5.5, e2)
    dome = smooth(2.0, 14.0, e2) ** 0.6
    pal = [((0.46, 0.45, 0.44), 0.4), ((0.55, 0.52, 0.5), 0.25), ((0.5, 0.42, 0.4), 0.15), ((0.36, 0.36, 0.37), 0.15), ((0.62, 0.6, 0.57), 0.05)]
    bc = pal_pick(R, pal, nb) * R.uniform(0.88, 1.1, (nb, 1)).astype(np.float32)
    n = tn(R, S, (4, 8, 16, 32), 0.6)
    fine = tn(R, S, (128, 256, 512), 0.8)
    gr = grain(R, S, 0.5)
    sp = R.random((S, S)).astype(np.float32)
    col = bc[inv] * (0.9 + 0.2 * fine[..., None])
    col = mix(col, col * 0.45, (sp < 0.07) * 0.8)
    col = mix(col, C(0.85, 0.83, 0.8), (sp > 0.95) * 0.5)
    col = mix(col, col * C(1.0, 0.86, 0.82), (gblur((sp > 0.9).astype(np.float32), 0.8) > 0.25) * 0.3)
    col = gblur(col, 0.5)
    polish = dome * smooth(0.4, 0.7, n)
    col = col * (0.88 + 0.18 * polish[..., None])
    joint = mix(C(0.13, 0.11, 0.09), C(0.22, 0.19, 0.15), tn(R, S, (16, 32, 64), 0.6)) * (0.8 + 0.4 * gr[..., None])
    col = mix(joint, col, face)
    # mousse et herbe dans les joints
    moss = (1 - face) * smooth(0.55, 0.7, tn(R, S, (16, 32, 64, 128), 0.65))
    col = mix(col, C(0.2, 0.27, 0.09) * (0.8 + 0.4 * gr[..., None]), moss * 0.85)
    oil = smooth(0.74, 0.84, tn(R, S, (8, 16, 32, 64), 0.6))
    col = col * (1 - 0.18 * oil[..., None])
    h = face * (0.4 + 0.45 * dome) + gr * 0.02 + moss * 0.1
    col = finish(col, h, shadow_hs=5.0, bake_s=5.0, k=0.35, ao=0.45, ao_r=4)
    save_surface("paves_port", col, h, 6.0)


def coque_cargo():
    """Acier de coque peint en rouge (« La Baleine Rouillée ») : tôles soudées (soudures horizontales tous
    les 1,5 m, verticales décalées), cordons en relief, peinture rouge passée et reprise par plaques,
    cloques et écailles montrant l'apprêt gris et la rouille, longues coulures de rouille sous les
    soudures, éraflures horizontales des quais."""
    S = 1024
    R = rng(7531)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    n = tn(R, S, (8, 16, 32, 64), 0.6)
    n2 = tn(R, S, (32, 64, 128, 256), 0.7)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.5)
    st = vstreak(R, S, (16, 32, 64, 128, 256), 0.65, 6)
    red = mix(C(0.5, 0.12, 0.09), C(0.62, 0.17, 0.12), n) * (0.93 + 0.14 * gr[..., None])
    fade = smooth(0.45, 0.85, n2)
    red = mix(red, C(0.66, 0.32, 0.28), fade * 0.35)
    rep = smooth(0.64, 0.66, tn(R, S, (4, 8, 16), 0.6))
    red = mix(red, C(0.56, 0.1, 0.08) * (0.95 + 0.1 * gr[..., None]), rep * 0.8)
    wbs = []
    for y0 in (180.0, 180.0 + S / 2):
        wbs.append(weld_bead(S, y0, 0, R, 5.0))
    for x0, yr in ((240.0, (180, 180 + S / 2)), (760.0, (180 + S / 2, 180 + S))):
        wb, wh = weld_bead(S, x0, 1, R, 5.0)
        band = ((yy - yr[0]) % S) < (yr[1] - yr[0])
        wbs.append((wb * band, wh * band))
    wb = np.max([w[0] for w in wbs], axis=0)
    wseam = smooth(0.05, 0.3, wb)
    pm, pedge = peel_mask(R, S, 0.84, scale=(16, 32, 64, 128, 256), sharp=0.02)
    near = np.clip(gblur(wseam, 6.0) * 4, 0, 1)
    pm = pm * (1 - smooth(0.55, 0.62, near * 0.5 + n2 * 0.5))
    primer = C(0.46, 0.46, 0.44) * (0.85 + 0.3 * gr[..., None])
    rcol = rust_palette(np.clip(n2 + (gr - 0.5) * 0.3, 0, 1), n) * (0.72 + 0.56 * gr[..., None])
    under = mix(primer, rcol, smooth(0.45, 0.55, n2 + (fine - 0.5) * 0.3))
    col = mix(under, red, pm)
    col = col * (1 - 0.3 * pedge[..., None] * (1 - pm[..., None]))
    run = np.clip(run_down(wseam * 0.35 + (1 - pm) * 0.12, 160.0), 0, 1) * (0.3 + 0.9 * st)
    col = mix(col, C(0.42, 0.2, 0.08), np.clip(run, 0, 1) * 0.6)
    col = mix(col, rcol * 0.9, wseam * 0.6)
    # éraflures horizontales
    img = to_img(col)
    d = ImageDraw.Draw(img)
    for _ in range(26):
        x, y = R.uniform(0, S), R.uniform(0, S)
        L = R.uniform(80, 400)
        w = int(R.integers(1, 4))
        c = (110, 104, 98) if R.random() < 0.6 else (90, 50, 30)
        for ox, oy in offs(x, y, L, S):
            pts = [(x + ox + t * L, y + oy + math.sin(t * 3) * 3) for t in np.linspace(0, 1, 12)]
            d.line(pts, fill=c, width=w)
    col = mix(col, from_img(img), 0.75)
    dirt = smooth(0.55, 0.85, st)
    col = col * (1 - 0.2 * dirt[..., None])
    h = 0.5 + wb * 0.3 + pm * 0.03 + pedge * 0.03 + n * 0.04 + gr * 0.015
    col = finish(col, h, shadow_hs=2.0, bake_s=5.0, k=0.3, ao=0.25, ao_r=3)
    save_surface("coque_cargo", col, h, 5.0)


def bati():
    for f in (brique, brique_peinte, beton_brut, tole_rouille, tole_peinte, bardage, acier_rouille, metal_rivete,
              carrelage_usine, paves_port, coque_cargo):
        f()


# =================================================================== le donjon : l'Usine Grise (512 px, une tuile ≈ 2 m)

def moquette_bureau():
    """Moquette de bureau en dalles de 50 cm (4 x 4 par tuile de 2 m), posées en damier de sens de
    velours : bouclettes serrées bleu-gris chiné, joints discrets, chemin d'usure, taches de café."""
    S = 512
    R = rng(7541)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    tw = S / 4
    ti = np.floor(xx / tw).astype(np.int32)
    tj = np.floor(yy / tw).astype(np.int32)
    rot = ((ti + tj) % 2).astype(np.float32)
    gr = grain(R, S, 0.5)
    gr2 = grain(R, S, 0.9)
    # bouclettes : rangées de petites boucles, orientées selon la dalle
    a = np.where(rot > 0, xx, yy)
    b = np.where(rot > 0, yy, xx)
    loops = (0.5 + 0.5 * np.sin(a * TAU / 3.2)) * (0.5 + 0.5 * np.sin(b * TAU / 2.6 + np.sin(a * 0.9)))
    yarn = R.random((S, S)).astype(np.float32)
    flk = (yarn > 0.93).astype(np.float32) * 0.5 + (yarn < 0.06).astype(np.float32) * -0.4
    base = mix(C(0.22, 0.25, 0.3), C(0.3, 0.33, 0.38), tn(R, S, (8, 16, 32), 0.6))
    col = base * (0.78 + 0.3 * loops[..., None]) * (0.85 + 0.3 * gr[..., None]) * (1 + 0.35 * gblur(flk, 0.5)[..., None])
    col = col * (1 + 0.04 * (rot - 0.5))[..., None]
    ed = np.minimum(np.mod(xx, tw), np.mod(yy, tw))
    ed = np.minimum(ed, np.minimum(tw - np.mod(xx, tw), tw - np.mod(yy, tw)))
    seam = 1 - smooth(0.3, 1.4, ed)
    col = col * (1 - 0.35 * seam[..., None])
    wear = smooth(0.5, 0.8, tn(R, S, (2, 4, 8), 0.6))
    col = mix(col, col * C(1.12, 1.1, 1.05) * 0.95, wear * 0.4)
    stains = Image.new("L", (S, S), 0)
    ds = ImageDraw.Draw(stains)
    for _ in range(5):
        x, y = R.random(2) * S
        r = R.uniform(6, 16)
        for ox, oy in offs(x, y, r + 2, S):
            ds.ellipse((x + ox - r, y + oy - r * 0.8, x + ox + r, y + oy + r * 0.8), fill=150)
            ds.arc((x + ox - r, y + oy - r * 0.8, x + ox + r, y + oy + r * 0.8), 0, 360, fill=255, width=2)
    st = gblur(np.asarray(stains, np.float32) / 255.0, 1.2)
    col = mix(col, col * C(0.75, 0.62, 0.5), st * 0.6)
    h = loops * 0.3 + gr * 0.2 + gr2 * 0.2 - seam * 0.3 - wear * 0.05
    col = finish(col, h, bake_s=2.0, k=0.2, ao=0.2, ao_r=2)
    save_surface("moquette_bureau", col, h, 3.0)


def faux_plafond():
    """Faux plafond : dalles minérales de 60 cm (2 x 2 par tuile) au motif fissuré, ossature en T en
    acier laqué blanc, une dalle jaunie par une auréole d'eau, poussière dans les angles."""
    S = 512
    R = rng(7542)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    tw = S / 2
    ex = np.minimum(np.mod(xx, tw), tw - np.mod(xx, tw))
    ey = np.minimum(np.mod(yy, tw), tw - np.mod(yy, tw))
    e = np.minimum(ex, ey)
    tid = (np.floor(xx / tw) + 2 * np.floor(yy / tw)).astype(np.int32)
    gr = grain(R, S, 0.6)
    tile = C(0.84, 0.83, 0.79) * (0.94 + 0.1 * gr[..., None])
    # fissures : petits vers sombres
    worms = Image.new("L", (S, S), 0)
    dw = ImageDraw.Draw(worms)
    for _ in range(2600):
        x, y = R.random(2) * S
        a = R.uniform(0, TAU)
        pts = [(x, y)]
        for k in range(int(R.integers(2, 6))):
            a += R.normal(0, 0.8)
            x += math.cos(a) * 2.2
            y += math.sin(a) * 2.2
            pts.append((x, y))
        for ox, oy in offs(x, y, 14, S):
            dw.line([(px + ox, py + oy) for px, py in pts], fill=255, width=1)
    for _ in range(3000):
        x, y = R.random(2) * S
        dw.point((x, y), fill=200)
    wm = gblur(np.asarray(worms, np.float32) / 255.0, 0.5)
    col = tile * (1 - 0.35 * wm[..., None])
    stain_t = int(R.integers(4))
    cx, cy = (stain_t % 2 + 0.5) * tw + R.uniform(-30, 30), (stain_t // 2 + 0.5) * tw + R.uniform(-30, 30)
    dd = np.hypot(xx - cx, yy - cy) + (tn(R, S, (8, 16, 32), 0.6) - 0.5) * 30
    stain = (1 - smooth(50, 80, dd)) * (tid == stain_t)
    ring = np.exp(-((dd - 78) / 3) ** 2) * (tid == stain_t)
    col = mix(col, col * C(0.95, 0.85, 0.62), stain * 0.5 + ring * 0.6)
    dust = np.exp(-e / 10.0) * 0.25
    col = col * (1 - dust[..., None] * 0.4)
    grid = 1 - smooth(4.0, 5.0, e)
    gcol = C(0.9, 0.9, 0.88)
    col = mix(col, gcol * (1 - 0.15 * np.exp(-((e - 3.0) / 1.0) ** 2))[..., None], grid)
    shadow = np.exp(-((e - 5.5) / 1.6) ** 2)
    col = col * (1 - 0.25 * shadow[..., None])
    h = 0.4 - wm * 0.12 + gr * 0.03 + grid * 0.45 + 0.05 * grid * np.exp(-((e - 2) / 1.5) ** 2)
    col = finish(col, h, bake_s=3.0, k=0.2, ao=0.25, ao_r=3)
    save_surface("faux_plafond", col, h, 4.0)


def beton_usine():
    """Sol d'usine en béton lissé et ciré gris (une tuile ≈ 2 m) : traces de truelle, peinture époxy usée
    par plaques, traces de pneus des chariots, taches d'huile, joint scié en bordure, fines fissures."""
    S = 512
    R = rng(7543)
    n = tn(R, S, (2, 4, 8, 16, 32), 0.6)
    fine = tn(R, S, (64, 128, 256, 512), 0.8)
    gr = grain(R, S, 0.5)
    col = mix(C(0.44, 0.45, 0.45), C(0.54, 0.55, 0.54), n) * (0.93 + 0.12 * gr[..., None]) * (0.96 + 0.08 * fine[..., None])
    # truelle : arcs clairs
    tr = Image.new("L", (S, S), 0)
    dt = ImageDraw.Draw(tr)
    for _ in range(90):
        x, y = R.random(2) * S
        r = R.uniform(40, 120)
        a0 = R.uniform(0, 360)
        for ox, oy in offs(x, y, r + 4, S):
            dt.arc((x + ox - r, y + oy - r, x + ox + r, y + oy + r), a0, a0 + R.uniform(30, 80), fill=int(R.uniform(60, 140)), width=int(R.integers(4, 12)))
    trm = gblur(np.asarray(tr, np.float32) / 255.0, 2.0)
    col = col * (1 + 0.08 * trm[..., None])
    ep, eedge = peel_mask(R, S, 0.45, scale=(4, 8, 16, 32, 64), sharp=0.04)
    col = mix(col, mix(C(0.42, 0.47, 0.44), C(0.5, 0.55, 0.52), fine) * (0.95 + 0.1 * gr[..., None]), ep * 0.6)
    tyres = Image.new("L", (S, S), 0)
    dty = ImageDraw.Draw(tyres)
    for _ in range(6):
        x, y = R.random(2) * S
        r = R.uniform(150, 400)
        a0 = R.uniform(0, 360)
        for k in (0, 26):
            for ox, oy in offs(x, y, r + 30, S):
                dty.arc((x + ox - r - k, y + oy - r - k, x + ox + r + k, y + oy + r + k), a0, a0 + R.uniform(20, 50), fill=int(R.uniform(80, 170)), width=9)
    ty = gblur(np.asarray(tyres, np.float32) / 255.0, 2.5) * (0.5 + 0.5 * fine)
    col = col * (1 - 0.25 * ty[..., None])
    oil = smooth(0.76, 0.86, tn(R, S, (8, 16, 32, 64), 0.6))
    col = col * (1 - 0.18 * oil[..., None])
    paths = crack_paths(R, S, 1, seg=(4, 10), steps=(15, 35), turn=0.4, branch=0.3)
    cm = np.asarray(draw_paths(S, paths, K=1, wscale=0.8).filter(ImageFilter.GaussianBlur(0.5)), np.float32) / 255.0
    col = col * (1 - 0.5 * cm[..., None])
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    dj = np.minimum(np.minimum(xx + 0.5, S - 0.5 - xx), np.minimum(yy + 0.5, S - 0.5 - yy))
    joint = np.exp(-(dj / 1.5) ** 2)
    col = col * (1 - 0.55 * joint[..., None])
    h = 0.5 + n * 0.04 + gr * 0.02 + ep * 0.02 + eedge * 0.01 - cm * 0.1 - joint * 0.2
    col = finish(col, h, bake_s=3.0, k=0.2, ao=0.2, ao_r=3)
    save_surface("beton_usine", col, h, 3.0)


def tapis_roulant():
    """Bande de tapis roulant en caoutchouc noir (défile le long de y) : nervures en chevrons tous les
    8 cm, surface grenue, poussière grise dans les creux, bords renforcés, usure plus claire au milieu."""
    S = 512
    R = rng(7544)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    gr = grain(R, S, 0.5)
    fine = tn(R, S, (64, 128, 256), 0.8)
    period = S / 12
    vv = np.mod(yy + np.abs(xx - S / 2) * 0.55, period)
    dv = np.minimum(vv, period - vv)
    rib = np.clip(1 - (dv / 5.0) ** 2, 0, 1) ** 0.5
    edge = np.minimum(xx, S - 1 - xx)
    rim = smooth(10, 26, edge)
    rib = rib * rim
    base = C(0.075, 0.075, 0.08) * (0.8 + 0.4 * gr[..., None]) * (0.9 + 0.2 * fine[..., None])
    mid = np.exp(-((xx - S / 2) / (S * 0.3)) ** 2)
    col = mix(base, base * 1.6, rib * 0.4 * mid)
    dust = np.clip(1 - rib, 0, 1) * smooth(0.55, 0.8, tn(R, S, (16, 32, 64, 128), 0.65)) * rim
    col = mix(col, C(0.3, 0.29, 0.27) * (0.8 + 0.4 * gr[..., None]), dust * 0.3)
    border = (1 - rim)
    col = mix(col, C(0.11, 0.11, 0.12) * (0.85 + 0.3 * gr[..., None]), border * 0.5)
    stitch = np.exp(-((edge - 6) / 1.2) ** 2) * (np.mod(yy, 10) < 6)
    col = mix(col, C(0.3, 0.3, 0.3), stitch * 0.6)
    h = rib * 0.5 + gr * 0.05 + border * 0.25 - stitch * 0.05
    col = finish(col, h, bake_s=4.0, k=0.35, ao=0.3, ao_r=3)
    save_surface("tapis_roulant", col, h, 5.0)


def carrelage_bureau():
    """Dalles de sol de bureau (grès cérame gris moucheté, 50 cm, 4 x 4 par tuile de 2 m), joints fins
    clairs, traces de talons noires, rayures, un peu de poussière le long des joints."""
    S = 512
    R = rng(7545)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    tw = S / 4
    tid = (np.floor(xx / tw) + 4 * np.floor(yy / tw)).astype(np.int32)
    ex = np.minimum(np.mod(xx, tw), tw - np.mod(xx, tw))
    ey = np.minimum(np.mod(yy, tw), tw - np.mod(yy, tw))
    e = np.minimum(ex, ey)
    gr = grain(R, S, 0.5)
    sp = R.random((S, S)).astype(np.float32)
    tone = per_id(tid, R, 0.95, 1.04)
    col = C(0.6, 0.6, 0.58) * tone[..., None] * (0.94 + 0.1 * gr[..., None])
    col = mix(col, C(0.32, 0.32, 0.33), (sp < 0.05) * 0.6)
    col = mix(col, C(0.82, 0.8, 0.76), (sp > 0.96) * 0.5)
    col = mix(col, C(0.5, 0.44, 0.38), ((sp > 0.9) & (sp < 0.92)) * 0.4)
    col = gblur(col, 0.4)
    joint = 1 - smooth(1.0, 2.0, e)
    col = mix(col, C(0.7, 0.69, 0.66), joint)
    dust = np.exp(-e / 6.0) * 0.2
    col = col * (1 - dust[..., None] * 0.35)
    marks = Image.new("L", (S, S), 0)
    dm = ImageDraw.Draw(marks)
    for _ in range(40):
        x, y = R.random(2) * S
        a = R.uniform(0, TAU)
        L = R.uniform(4, 22)
        for ox, oy in offs(x, y, L + 2, S):
            dm.line([(x + ox, y + oy), (x + ox + math.cos(a) * L, y + oy + math.sin(a) * L)], fill=int(R.uniform(90, 200)), width=int(R.integers(1, 4)))
    mk = gblur(np.asarray(marks, np.float32) / 255.0, 0.6)
    col = col * (1 - 0.6 * mk[..., None])
    h = 0.5 - joint * 0.25 + gr * 0.02
    col = finish(col, h, bake_s=3.0, k=0.2, ao=0.2, ao_r=2)
    save_surface("carrelage_bureau", col, h, 3.0)


def donjon():
    for f in (moquette_bureau, faux_plafond, beton_usine, tapis_roulant, carrelage_bureau):
        f()


# =================================================================== champignons féeriques


CAPS = {
    # base sombre, base claire, verrues, lueur, veines
    "bleu": ((0.04, 0.12, 0.34), (0.12, 0.38, 0.72), (0.78, 0.94, 1.0), (0.45, 0.85, 1.0), (0.3, 0.75, 1.0)),
    "violet": ((0.16, 0.04, 0.26), (0.46, 0.16, 0.62), (0.98, 0.86, 1.0), (0.85, 0.55, 1.0), (0.95, 0.5, 1.0)),
    "orange": ((0.38, 0.1, 0.02), (0.86, 0.38, 0.06), (1.0, 0.95, 0.78), (1.0, 0.8, 0.35), (1.0, 0.72, 0.25)),
}


def chapeau(key):
    """Dessus d'un chapeau de champignon féerique géant : peau satinée aux nuances profondes, fines veines
    luminescentes sinueuses, verrues claires en relief bien espacées (grandes et petites) qui luisent,
    petits points de lumière. Couleurs franches mais matière réaliste (peau, rides, reflets)."""
    S = 1024
    R = rng(7550 + list(CAPS).index(key))
    dark, light, wart, glowc, vein = (np.array(c, np.float32) for c in CAPS[key])
    n = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    n2 = tn(R, S, (16, 32, 64, 128), 0.65)
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    gr = grain(R, S, 0.6)
    col = mix(dark, light, smooth(0.15, 0.85, n * 0.7 + n2 * 0.3))
    col = col * (0.92 + 0.12 * fine[..., None]) * (0.96 + 0.08 * gr[..., None])
    # fibrilles de la peau
    fib = tn(R, S, (64, 128, 256, 512), 0.9, oy=(16, 32, 64, 128))
    col = col * (0.94 + 0.1 * fib[..., None])
    # veines sinueuses (lignes de niveau d'un bruit)
    from generate_braise_v70 import iso_lines
    vn = tn(R, S, (4, 8, 16, 32), 0.6)
    veins = np.maximum(iso_lines(vn, 0.5, 1.3), iso_lines(vn, 0.36, 1.0) * 0.7) * smooth(0.3, 0.55, n2)
    vn2 = tn(R, S, (8, 16, 32, 64), 0.6)
    veins = np.maximum(veins, iso_lines(vn2, 0.62, 0.8) * 0.6 * smooth(0.45, 0.6, n))
    col = mix(col, vein * 0.85, veins[..., None] * 0.5)
    # verrues bien espacées (placement par rejet)
    items = []
    placed = []
    for count, rlo, rhi in ((40, 30, 48), (140, 14, 26), (500, 5, 11)):
        tries = 0
        k = 0
        while k < count and tries < count * 30:
            tries += 1
            x, y = R.random(2) * S
            r = R.uniform(rlo, rhi)
            ok = True
            for (px, py, pr) in placed:
                dx = (x - px + S / 2) % S - S / 2
                dy = (y - py + S / 2) % S - S / 2
                if dx * dx + dy * dy < (r + pr + 10) ** 2:
                    ok = False
                    break
            if not ok:
                continue
            placed.append((x, y, r))
            items.append((x, y, rock_poly(R, r, k=int(R.integers(7, 12)), jit=0.15, el=R.uniform(0.75, 1.0), sm=2), r))
            k += 1
    N = len(items)
    ids = scatter(S, items)
    hn, mask = domes(ids, N)
    prof = np.sqrt(np.clip(hn * 1.3, 0, 1))
    wcol = wart * (0.8 + 0.2 * prof[..., None]) * (0.9 + 0.15 * fine[..., None])
    _, we, _, _, _ = worley(R, S, 110, 0.9)
    wcrack = (1 - smooth(0.2, 0.8, we)) * mask * smooth(0.5, 0.8, prof) * smooth(0.5, 0.65, n2)
    wcol = wcol * (1 - 0.12 * wcrack[..., None])
    ma = gblur(mask.astype(np.float32), 0.8)
    halo = np.clip(gblur(mask.astype(np.float32), 6.0) - ma, 0, 1) * 2
    col = col * (1 - 0.3 * halo[..., None])
    col = mix(col, wcol, ma)
    rad = np.concatenate([[0.0], np.array([it[3] for it in items], np.float32)])
    h = n * 0.25 + fine * 0.02 + fib * 0.02 - veins * 0.03 + prof * mask * np.minimum(1.0, 0.25 + rad / 50)[ids] * 0.6
    sp = (R.random((S, S)) > 0.9992).astype(np.float32)
    spark = np.clip(gblur(sp, 1.0) * 6, 0, 1)
    col = finish(col, h, shadow_hs=4.0, bake_s=4.0, k=0.3, ao=0.35, ao_r=6)
    glow_w = gblur(mask.astype(np.float32) * prof, 8.0)
    col = col + glowc * (glow_w * 0.22 + spark * 0.6 + veins * 0.2)[..., None]
    gx, gy = grads(gblur(h, 2.0))
    sheen = np.clip(-(gx * 0.45 + gy * 0.6) * 25, 0, 1) ** 2
    col = col + sheen[..., None] * 0.08
    save_surface("chapeau_" + key, col, h, 6.0)


def chapeau_bleu():
    chapeau("bleu")


def chapeau_violet():
    chapeau("violet")


def chapeau_orange():
    chapeau("orange")


def lamelles():
    """Dessous du chapeau : lames serrées (le long de y), alternance de grandes lames et de lamelles plus
    courtes, crème nacrée ; une lueur douce monte entre les lames (pensé pour l'émission)."""
    S = 512
    R = rng(7553)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    nl = 48
    pitch = S / nl
    wob = (tn(R, S, (2, 4, 8), 0.6) - 0.5) * 6
    xw = xx + wob
    k = np.floor(xw / pitch).astype(np.int32)
    u = (xw - k * pitch) / pitch
    lam = np.clip(1 - np.abs(u - 0.5) * 2 / 0.86, 0, 1) ** 0.5
    short = (np.mod(k, 2) == 1)
    lenmask = np.where(short, smooth(0.35, 0.45, tn(R, S, (8, 16, 32), 0.6, oy=(1, 2, 4))), 1.0)
    lam = lam * lenmask
    gr = grain(R, S, 0.6)
    fine = tn(R, S, (64, 128, 256), 0.8, oy=(4, 8, 16))
    plate = mix(C(0.78, 0.72, 0.66), C(0.92, 0.88, 0.8), fine) * (0.93 + 0.1 * gr[..., None])
    slit = C(0.16, 0.12, 0.16)
    col = mix(slit, plate * (0.6 + 0.4 * lam[..., None]), smooth(0.0, 0.3, lam))
    glow = (1 - smooth(0.0, 0.35, lam)) * (0.6 + 0.4 * fine)
    col = col + C(0.75, 0.8, 0.9) * glow[..., None] * 0.3
    edge = np.exp(-((lam - 0.15) / 0.08) ** 2)
    col = col + C(0.9, 0.9, 1.0) * edge[..., None] * 0.08
    h = lam * 0.8 + gr * 0.02 + fine * 0.03
    save_surface("lamelles", col, h, 6.0)


def pied_champi():
    """Pied de champignon féerique : chair blanc-crème fibreuse (fibres le long de y), fines mèches et
    écailles en chevrons plus foncées, quelques points luminescents."""
    S = 512
    R = rng(7554)
    fib = tn(R, S, (32, 64, 128, 256, 512), 0.95, oy=(1, 2, 4, 8, 16))
    n = tn(R, S, (2, 4, 8, 16), 0.6)
    gr = grain(R, S, 0.6)
    col = mix(C(0.78, 0.74, 0.66), C(0.92, 0.9, 0.84), fib) * (0.92 + 0.1 * n[..., None]) * (0.95 + 0.08 * gr[..., None])
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    # écailles en chevrons
    sc = Image.new("L", (S, S), 0)
    ds = ImageDraw.Draw(sc)
    for _ in range(420):
        x, y = R.random(2) * S
        w = R.uniform(6, 16)
        hgt = R.uniform(3, 7)
        for ox, oy in offs(x, y, w + 2, S):
            ds.polygon([(x + ox - w, y + oy), (x + ox, y + oy + hgt), (x + ox + w, y + oy), (x + ox, y + oy + hgt * 0.4)], fill=int(R.uniform(100, 220)))
    scm = gblur(np.asarray(sc, np.float32) / 255.0, 0.8) * smooth(0.4, 0.6, tn(R, S, (4, 8, 16), 0.6))
    col = mix(col, col * C(0.72, 0.66, 0.6), scm * 0.6)
    sp = (R.random((S, S)) > 0.9993).astype(np.float32)
    spark = np.clip(gblur(sp, 0.9) * 5, 0, 1)
    h = fib * 0.3 + scm * 0.25 + gr * 0.03
    col = finish(col, h, bake_s=3.0, k=0.25, ao=0.25, ao_r=3)
    col = col + C(0.5, 0.8, 1.0) * spark[..., None] * 0.5
    save_surface("pied_champi", col, h, 4.0)


def champignons():
    for f in (chapeau_bleu, chapeau_violet, chapeau_orange, lamelles, pied_champi):
        f()


# =================================================================== peintures : outils de dessin

INK = (26, 20, 28)


def rell(cx, cy, rx, ry, ang=0.0, n=48):
    """Ellipse tournée (ang en degrés)."""
    a = math.radians(ang)
    ca, sa = math.cos(a), math.sin(a)
    out = []
    for k in range(n):
        t = k / n * TAU
        x, y = math.cos(t) * rx, math.sin(t) * ry
        out.append((cx + x * ca - y * sa, cy + x * sa + y * ca))
    return out


def star_pts(x, y, r, n=5, inner=0.45, rot=-90.0):
    pts = []
    for k in range(n * 2):
        rr = r if k % 2 == 0 else r * inner
        a = math.radians(rot) + k * math.pi / n
        pts.append((x + math.cos(a) * rr, y + math.sin(a) * rr))
    return pts


def heart_pts(cx, cy, s, n=60):
    pts = []
    for k in range(n):
        t = k / n * TAU
        x = 16 * math.sin(t) ** 3
        y = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
        pts.append((cx + x * s, cy + y * s))
    return pts


def xform(pts, cx, cy, ang=0.0, sx=1.0, sy=None):
    """Tourne et met à l'échelle des points autour de (cx, cy)."""
    sy = sx if sy is None else sy
    a = math.radians(ang)
    ca, sa = math.cos(a), math.sin(a)
    return [(cx + ((x - cx) * sx) * ca - ((y - cy) * sy) * sa, cy + ((x - cx) * sx) * sa + ((y - cy) * sy) * ca) for x, y in pts]


def union(pa, polys, col, ol=2.5, shade=0.5, depth=6.0, grad=None, inkc=None, alpha=1.0, tex=True):
    """Plusieurs formes peintes d'une seule couleur, avec un seul contour extérieur."""
    qs = [pa.P(p) for p in polys]
    if ol:
        w = max(1, int(round(ol * 2 * pa.K)))

        def dr_ink(d):
            for q in qs:
                d.polygon(q, fill=255)
                d.line(q + [q[0]], fill=255, width=w, joint="curve")
        pa.comp(pa._draw(dr_ink), inkc or INK, alpha * 0.95, tex=False)

    def dr(d):
        for q in qs:
            d.polygon(q, fill=255)
    pa.comp(pa._draw(dr), col, alpha, shade=shade, depth=depth, grad=grad, tex=tex)


def shape(pa, pts, col, ol=2.5, shade=0.5, depth=6.0, grad=None, sm=0, inkc=None, alpha=1.0, tex=True):
    if sm:
        pts = chaikin(pts, sm)
    union(pa, [pts], col, ol, shade, depth, grad, inkc, alpha, tex)


def stroke(pa, pts, w0, col, w1=None, ol=2.0, shade=0.4, depth=4.0):
    union(pa, [tube(pts, w0, w1)], col, ol, shade, depth)


def ptext(pa, xy, s, kind, size, col, anchor="mm", stroke_w=0.0, stroke_col=None, rot=0.0, shadow=None, alpha=1.0, shade=0.0,
          grad=None, spacing=0.0):
    """Texte (polices du système) dans une peinture Paint, avec contour, ombre portée et rotation."""
    f = ff(kind, size * pa.K)
    x, y = xy[0] * pa.K, xy[1] * pa.K

    def mk(sw):
        m = Image.new("L", (pa.w, pa.h), 0)
        d = ImageDraw.Draw(m)
        if spacing:
            tw = sum(d.textlength(ch, font=f) for ch in s) + spacing * pa.K * (len(s) - 1)
            cx = x - tw / 2 if anchor[0] == "m" else (x - tw if anchor[0] == "r" else x)
            for ch in s:
                d.text((cx, y), ch, font=f, fill=255, anchor="l" + anchor[1], stroke_width=sw, stroke_fill=255)
                cx += d.textlength(ch, font=f) + spacing * pa.K
        else:
            d.text((x, y), s, font=f, fill=255, anchor=anchor, stroke_width=sw, stroke_fill=255)
        if rot:
            m = m.rotate(rot, center=(x, y), resample=Image.BICUBIC)
        return m
    if shadow:
        dx, dy, sa = shadow
        m = mk(int(stroke_w * pa.K))
        sh = Image.new("L", m.size, 0)
        sh.paste(m, (int(dx * pa.K), int(dy * pa.K)))
        pa.comp(sh, shadow[3] if len(shadow) > 3 else (0, 0, 0), sa, tex=False)
    if stroke_w:
        pa.comp(mk(int(stroke_w * pa.K)), stroke_col or INK, alpha, tex=False)
    pa.comp(mk(0), col, alpha, shade=shade, depth=1.2, grad=grad, tex=False)


def text_w(s, kind, size, spacing=0.0):
    f = ff(kind, size)
    d = ImageDraw.Draw(Image.new("L", (8, 8)))
    return d.textlength(s, font=f) + spacing * (len(s) - 1)


def fit_size(s, kind, size, maxw, spacing=0.0):
    while size > 6 and text_w(s, kind, size, spacing) > maxw:
        size -= 1
    return size


def note(pa, x, y, s, col, double=False, ang=0.0):
    """Une note de musique (croche, ou deux croches liées)."""
    parts = []
    heads = [(x, y)] + ([(x + 34 * s, y - 8 * s)] if double else [])
    for hx, hy in heads:
        parts.append(rell(hx, hy, 11 * s, 7.5 * s, -25))
        parts.append(tube([(hx + 9 * s, hy - 2 * s), (hx + 9 * s, hy - 52 * s)], 4.2 * s))
    if double:
        parts.append([(x + 7 * s, y - 50 * s), (x + 45 * s, y - 60 * s), (x + 45 * s, y - 49 * s), (x + 7 * s, y - 39 * s)])
    else:
        parts.append(tube(bez((x + 9 * s, y - 52 * s), (x + 30 * s, y - 40 * s), (x + 28 * s, y - 20 * s), 10), 6 * s, 2 * s))
    if ang:
        parts = [xform(p, x, y, ang) for p in parts]
    union(pa, parts, col, ol=2.2 * max(0.6, s), shade=0.4, depth=3)


def sparkle(pa, x, y, r, col, ol=1.5):
    pts = []
    for k in range(8):
        rr = r if k % 2 == 0 else r * 0.22
        a = k * math.pi / 4 - math.pi / 2
        pts.append((x + math.cos(a) * rr, y + math.sin(a) * rr))
    shape(pa, pts, col, ol=ol, shade=0.0)


def bolt(pa, x, y, s, col, ang=0.0):
    pts = [(0, -60), (28, -60), (12, -14), (34, -14), (-18, 64), (-2, 6), (-24, 6)]
    pts = [(x + px * s, y + py * s) for px, py in pts]
    shape(pa, xform(pts, x, y, ang), col, ol=2.5, shade=0.4)


def cloud(pa, cx, cy, w, h, col=(250, 250, 252), R=None, ol=2.5, shade=0.6, n=7):
    R = R or rng(int(cx * 7 + cy))
    parts = [rell(cx, cy + h * 0.15, w * 0.5, h * 0.35)]
    for k in range(n):
        t = (k + 0.5) / n
        x = cx - w * 0.42 + t * w * 0.84
        r = h * (0.28 + 0.28 * math.sin(t * math.pi)) * R.uniform(0.85, 1.15)
        parts.append(rell(x, cy - r * 0.35 + h * 0.05, r * 1.1, r))
    union(pa, parts, col, ol=ol, shade=shade, depth=h * 0.18)


def sunburst(pa, cx, cy, n, c1, c2, r=1600, rot=0.0):
    for k in range(n):
        a0 = math.radians(rot) + k * TAU / n
        a1 = a0 + TAU / n
        pa.poly([(cx, cy), (cx + math.cos(a0) * r, cy + math.sin(a0) * r), (cx + math.cos(a1) * r, cy + math.sin(a1) * r)],
                c1 if k % 2 == 0 else c2, shade=0, ol=0)


def bg_grad(pa, c1, c2, ang=90.0):
    pa.rect(-10, -10, pa.W + 10, pa.H + 10, c1, grad=(c1, c2, ang), shade=0, ol=0)


def guitar(pa, cx, cy, s, ang, body=(214, 40, 44), guard=(246, 240, 230)):
    """Guitare électrique originale (corps à double pan coupé), manche vers +x avant rotation."""
    bodyp = chaikin([(-70, -10), (-62, -44), (-30, -50), (-8, -36), (14, -46), (34, -34), (30, -8), (40, 18), (20, 46), (-24, 52), (-62, 40)], 3)
    neck = [(30, -7), (190, -6), (190, 6), (30, 7)]
    head = [(188, -10), (226, -16), (232, -2), (226, 12), (188, 10)]
    guardp = chaikin([(-40, 8), (-20, -20), (10, -18), (14, 10), (-6, 34), (-36, 34)], 2)

    def T(p):
        return xform([(cx + x * s, cy + y * s) for x, y in p], cx, cy, ang)
    shape(pa, T(neck), (150, 96, 54), ol=2, shade=0.4, depth=3)
    shape(pa, T(head), (40, 34, 36), ol=2, shade=0.4, depth=3)
    shape(pa, T(bodyp), body, ol=2.6, shade=0.7, depth=12)
    shape(pa, T(guardp), guard, ol=1.6, shade=0.3, depth=4)
    for fx in range(46, 190, 18):
        pa.line(T([(fx, -6), (fx, 6)]), (220, 210, 190), 1.2 * s)
    for k in (-4, -1.3, 1.3, 4):
        pa.line(T([(-46, k), (226, k * 0.6)]), (236, 236, 236), 0.7 * s, alpha=0.9)
    for px, py in ((-16, -4), (-2, 14)):
        shape(pa, T([(px - 9, py - 4), (px + 9, py - 4), (px + 9, py + 4), (px - 9, py + 4)]), (40, 40, 44), ol=1, shade=0.2)
    for kx, ky in ((-50, 30), (-38, 40)):
        shape(pa, T(rell(kx, ky, 5, 5)), (230, 210, 120), ol=1, shade=0.5)


def rat(pa, cx, cy, s, crest=((236, 48, 60), (255, 120, 40)), fur=(128, 124, 136), jacket=True, guitar_col=(214, 40, 44),
        play=True, flip=False):
    """Le rat musicien (debout, de profil vers la droite) : crête colorée, veste noire cloutée, guitare."""
    def P(pts):
        q = [(cx + x * s, cy + y * s) for x, y in pts]
        if flip:
            q = [(2 * cx - x, y) for x, y in q]
        return q

    def E(x, y, rx, ry, a=0.0):
        return P(rell(x, y, rx, ry, a))
    pink = (236, 160, 170)
    light = tuple(min(255, int(v * 1.45)) for v in fur)
    # queue
    stroke(pa, P(bez((-40, 50), (-150, 90), (-190, -10), (-130, -70), 30)), 16 * s, (214, 156, 166), 4 * s, ol=2.2)
    # pattes
    for lx, fx in ((-22, -30), (26, 30)):
        stroke(pa, P([(lx, 40), (lx + (fx - lx) * 0.5, 80), (fx, 112)]), 30 * s, fur, 24 * s, ol=2.4)
        shape(pa, E(fx + 10, 118, 34, 13), pink, ol=2.4)
    # oreille arrière
    shape(pa, E(42, -192, 26, 28, 10), tuple(int(v * 0.85) for v in fur), ol=2.4)
    # corps
    shape(pa, E(0, -10, 64, 86), fur, ol=2.8, shade=0.7, depth=16)
    shape(pa, E(14, 10, 38, 58), light, ol=0, shade=0.3, depth=8)
    if jacket:
        jk = [(-62, -20), (-52, -70), (-20, -94), (30, -92), (56, -60), (58, -10), (46, 40), (24, 34), (14, -40), (-4, 34), (-50, 50)]
        shape(pa, P(jk), (36, 34, 42), ol=2.4, shade=0.6, depth=8, sm=1)
        for k in range(9):
            t = k / 8
            x, y = -50 + 6 * t, -60 + 100 * t
            shape(pa, E(x, y, 3.2, 3.2), (220, 220, 226), ol=0.8, shade=0.6, depth=1)
        shape(pa, P([(-44, 0), (-18, -4), (-16, 20), (-42, 24)]), (250, 210, 60), ol=1.6, shade=0.2)
        shape(pa, E(-30, 10, 6, 6), (220, 50, 60), ol=1.0, shade=0.2)
    # tête
    head = rell(24, -140, 54, 48, -8)
    snout = chaikin([(46, -176), (110, -150), (132, -132), (120, -114), (60, -100)], 2)
    union(pa, [P(head), P(snout)], fur, ol=2.8, shade=0.7, depth=14)
    shape(pa, E(126, -128, 10, 9), pink, ol=1.8)
    # crête
    for k in range(6):
        t = k / 5
        bx, by = -26 + t * 70, -176 - math.sin(t * math.pi) * 14
        h = 46 + math.sin(t * math.pi) * 26
        lean = -18 + t * 8
        c = crest[k % len(crest)]
        shape(pa, P([(bx - 13, by + 14), (bx + lean, by - h), (bx + 13, by + 12)]), c, ol=2.2, shade=0.5, depth=4)
    # oreille avant
    shape(pa, E(-6, -176, 31, 33, -15), fur, ol=2.6, shade=0.5)
    shape(pa, E(-4, -174, 20, 22, -15), pink, ol=0, shade=0.3)
    # œil, sourire, dents, moustaches
    shape(pa, E(64, -150, 13, 15), (252, 252, 250), ol=2.0, shade=0.2)
    shape(pa, E(68, -149, 7.5, 8.5), (24, 20, 26), ol=0, shade=0)
    shape(pa, E(71, -153, 2.6, 2.6), (255, 255, 255), ol=0, shade=0)
    pa.line(P(bez((84, -108), (100, -98), (116, -110), 10)), INK, 2.6 * s)
    shape(pa, P([(104, -114), (114, -114), (113, -100), (105, -101)]), (252, 250, 236), ol=1.4, shade=0)
    for k in (-1, 0, 1):
        pa.line(P([(118, -126 + k * 6), (166, -136 + k * 18)]), INK, 1.4 * s)
    if play:
        guitar(pa, cx + (-2 if not flip else 2) * s, cy + 18 * s, s, -24 if not flip else 204, body=guitar_col)
        # bras : main qui gratte, main sur le manche
        stroke(pa, P([(-30, -60), (-40, -10), (-14, 22)]), 24 * s, fur, 20 * s, ol=2.4)
        shape(pa, E(-10, 24, 13, 11), pink, ol=2)
        stroke(pa, P([(34, -66), (90, -70), (126, -60)]), 22 * s, fur, 18 * s, ol=2.4)
        shape(pa, E(130, -58, 12, 11), pink, ol=2)


def gull(pa, cx, cy, s, ang=0.0, bandana=None, flap=0.0):
    """Mouette goguenarde, ailes déployées (vue de face légèrement de trois quarts)."""
    def P(pts):
        return xform([(cx + x * s, cy + y * s) for x, y in pts], cx, cy, ang)
    white = (246, 246, 244)
    grey = (168, 178, 190)
    for side in (-1, 1):
        wing = [(0, -10), (side * 80, -50 - flap), (side * 190, -80 - flap * 1.5), (side * 300, -40 - flap * 2), (side * 330, -10 - flap * 2),
                (side * 250, 4 - flap), (side * 160, 20), (side * 60, 34)]
        shape(pa, P(chaikin(wing, 2)), grey, ol=2.6, shade=0.6, depth=12)
        tip = [(side * 250, -64 - flap * 1.8), (side * 300, -40 - flap * 2), (side * 332, -10 - flap * 2), (side * 280, -4 - flap * 1.6),
               (side * 236, -20 - flap * 1.4)]
        shape(pa, P(chaikin(tip, 1)), (36, 36, 40), ol=1.8, shade=0.4)
        for k in range(4):
            fx = side * (110 + k * 40)
            pa.line(P([(fx, -40 - flap * (0.6 + k * 0.3)), (fx + side * 10, 10 - k * 4)]), (130, 140, 154), 1.4 * s)
    shape(pa, P(chaikin([(-46, 0), (-30, -48), (0, -70), (30, -48), (46, 0), (30, 60), (0, 80), (-30, 60)], 2)), white, ol=2.8, shade=0.6, depth=14)
    shape(pa, P([(-14, 76), (0, 120), (14, 76)]), white, ol=2.2, shade=0.4)
    shape(pa, P(rell(0, -92, 44, 40)), white, ol=2.8, shade=0.6, depth=12)
    if bandana:
        shape(pa, P([(-44, -100), (0, -128), (44, -100), (40, -86), (0, -108), (-40, -86)]), bandana, ol=2, shade=0.4)
        for k in range(6):
            shape(pa, P(rell(-28 + k * 11, -108 + abs(k - 2.5) * 2, 2.2, 2.2)), (250, 250, 250), ol=0, shade=0)
    shape(pa, P([(-8, -86), (40, -84), (66, -76), (40, -68), (-6, -70)]), (250, 196, 50), ol=2.2, shade=0.4)
    shape(pa, P(rell(46, -73, 5, 4)), (226, 50, 40), ol=0, shade=0)
    for ex in (-18, 18):
        shape(pa, P(rell(ex, -100, 8, 9)), (255, 255, 255), ol=1.8, shade=0)
        shape(pa, P(rell(ex + 2, -99, 4, 5)), (240, 190, 40), ol=0, shade=0)
        shape(pa, P(rell(ex + 2, -99, 2, 2.4)), (20, 20, 20), ol=0, shade=0)
        pa.line(P([(ex - 10, -112 - (2 if ex < 0 else -2)), (ex + 10, -110 + (3 if ex < 0 else -3))]), INK, 2.2 * s)
    for fx in (-14, 14):
        stroke(pa, P([(fx, 70), (fx * 1.4, 96)]), 6 * s, (240, 140, 50), ol=1.6)


def whale(pa, cx, cy, s, body=(58, 110, 196), belly=(206, 222, 236)):
    """Baleine à bosse stylisée (vers la gauche), un village sur le dos."""
    def P(pts):
        return [(cx + x * s, cy + y * s) for x, y in pts]
    tail = chaikin([(250, -10), (330, -80), (380, -120), (360, -60), (420, -96), (400, -40), (330, 10), (270, 30)], 2)
    shape(pa, P(tail), body, ol=3, shade=0.6, depth=10)
    bodyp = chaikin([(-300, 20), (-280, -50), (-200, -96), (-60, -110), (100, -96), (230, -50), (300, 0), (240, 40), (100, 80), (-80, 96), (-240, 80)], 3)
    shape(pa, P(bodyp), body, ol=3.2, shade=0.7, depth=26)
    bel = chaikin([(-290, 30), (-200, 54), (-60, 70), (100, 60), (230, 30), (200, 56), (90, 84), (-80, 96), (-240, 80)], 2)
    shape(pa, P(bel), belly, ol=0, shade=0.3, depth=8)
    for k in range(7):
        x0 = -250 + k * 60
        pa.line(P(bez((x0, 46 + k * 3), (x0 + 30, 62 + k * 2), (x0 + 60, 66 + k), 8)), (150, 170, 196), 1.6 * s)
    shape(pa, P(chaikin([(-40, 40), (10, 70), (60, 130), (20, 120), (-30, 80)], 2)), tuple(int(v * 0.85) for v in body), ol=2.6, shade=0.5)
    shape(pa, P(rell(-215, -30, 11, 12)), (255, 255, 255), ol=2, shade=0)
    shape(pa, P(rell(-212, -29, 6, 7)), (20, 20, 30), ol=0, shade=0)
    shape(pa, P(rell(-210, -32, 2, 2)), (255, 255, 255), ol=0, shade=0)
    pa.line(P(bez((-296, 18), (-260, 34), (-230, 26), 10)), INK, 2.4 * s)
    shape(pa, P(rell(-190, 0, 14, 8)), (240, 150, 170), ol=0, shade=0, alpha=0.6)


def house(pa, x, base, w, h, wall, roof, s=1.0, R=None):
    R = R or rng(int(x * 13))
    shape(pa, [(x - w / 2, base), (x - w / 2, base - h), (x + w / 2, base - h), (x + w / 2, base)], wall, ol=2, shade=0.4, depth=4)
    shape(pa, [(x - w / 2 - 5 * s, base - h), (x, base - h - w * 0.55), (x + w / 2 + 5 * s, base - h)], roof, ol=2, shade=0.4, depth=4)
    ww = w * 0.22
    shape(pa, [(x - ww, base - h * 0.62), (x + ww * 0.3, base - h * 0.62), (x + ww * 0.3, base - h * 0.3), (x - ww, base - h * 0.3)],
          (255, 222, 120), ol=1.5, shade=0)


def mushroom(pa, cx, base, h, capw, cap, spots=(250, 250, 240), stem=(240, 230, 210), glow=None, R=None, tilt=0.0):
    """Champignon féerique (pied, chapeau bombé, pois)."""
    R = R or rng(int(cx * 7 + h))
    sw = capw * 0.18
    top = base - h
    stroke(pa, [(cx, base), (cx + tilt * 0.5, base - h * 0.5), (cx + tilt, top + capw * 0.1)], sw * 1.3, stem, sw, ol=2.4)
    capp = chaikin([(cx + tilt - capw / 2, top + capw * 0.12), (cx + tilt - capw * 0.42, top - capw * 0.18), (cx + tilt - capw * 0.18, top - capw * 0.36),
                    (cx + tilt + capw * 0.18, top - capw * 0.36), (cx + tilt + capw * 0.42, top - capw * 0.18), (cx + tilt + capw / 2, top + capw * 0.12),
                    (cx + tilt, top + capw * 0.04)], 3)
    if glow:
        pa.glow(cx + tilt, top - capw * 0.1, capw * 0.8, glow, 0.35)
    shape(pa, capp, cap, ol=2.6, shade=0.7, depth=capw * 0.08)
    placed = []
    for _ in range(80):
        if len(placed) >= int(capw / 40) + 4:
            break
        u = R.uniform(-0.4, 0.4)
        ytop = top - capw * 0.34 * max(0.0, 1 - (u / 0.5) ** 2) ** 0.8
        ybot = top + capw * 0.08
        py = ytop + R.uniform(0.18, 0.8) * (ybot - ytop)
        px = cx + tilt + u * capw
        r = capw * R.uniform(0.035, 0.065)
        if any((px - qx) ** 2 + (py - qy) ** 2 < (r + qr + capw * 0.02) ** 2 for qx, qy, qr in placed):
            continue
        placed.append((px, py, r))
        shape(pa, rell(px, py, r * 1.25, r), spots, ol=1.2, shade=0.3)


def person(pa, x, base, s, skin, top, pants, hair, pose=0, R=None, mohawk=True):
    """Danseur stylisé (pogo) : tête, crête, tee-shirt, bras levés, jambes en saut."""
    R = R or rng(int(x * 3 + base))
    hip = (x, base - 70 * s)
    neck = (x, base - 130 * s)
    legs = [((-12, 0), (-26, 36), (-20, 70)), ((12, 0), (30, 30), (24, 70))] if pose % 2 == 0 else [((-10, 0), (-6, 36), (-24, 64)), ((10, 0), (34, 20), (40, 52))]
    for (a, b, c) in legs:
        stroke(pa, [(hip[0] + a[0] * s, hip[1] + a[1] * s), (hip[0] + b[0] * s, hip[1] + b[1] * s), (hip[0] + c[0] * s, hip[1] + c[1] * s)], 18 * s, pants, 15 * s, ol=2)
        shape(pa, rell(hip[0] + c[0] * s + 6 * s, hip[1] + c[1] * s + 4 * s, 13 * s, 7 * s), (30, 28, 30), ol=1.8)
    arms = [((-18, 6), (-46, -26), (-50, -70)), ((18, 6), (48, -30), (40, -72))] if pose in (0, 1) else [((-18, 6), (-50, -10), (-70, -40)), ((18, 6), (40, -36), (30, -80))]
    for (a, b, c) in arms:
        stroke(pa, [(neck[0] + a[0] * s, neck[1] + 12 * s + a[1] * s), (neck[0] + b[0] * s, neck[1] + b[1] * s), (neck[0] + c[0] * s, neck[1] + c[1] * s)], 12 * s, skin, 10 * s, ol=2)
        shape(pa, rell(neck[0] + c[0] * s, neck[1] + c[1] * s - 3 * s, 6 * s, 6.5 * s), skin, ol=1.6)
    shape(pa, chaikin([(x - 24 * s, neck[1] + 4 * s), (x + 24 * s, neck[1] + 4 * s), (x + 20 * s, hip[1]), (x - 20 * s, hip[1])], 1), top, ol=2.2, shade=0.5)
    shape(pa, rell(x, neck[1] - 18 * s, 17 * s, 19 * s), skin, ol=2.2, shade=0.4)
    if mohawk:
        for k in range(4):
            bx = x - 9 * s + k * 6 * s
            shape(pa, [(bx - 5 * s, neck[1] - 32 * s), (bx - 2 * s, neck[1] - (60 + R.uniform(0, 10)) * s), (bx + 5 * s, neck[1] - 32 * s)], hair, ol=1.6, shade=0.3)
    else:
        shape(pa, chaikin([(x - 18 * s, neck[1] - 16 * s), (x - 14 * s, neck[1] - 40 * s), (x + 14 * s, neck[1] - 40 * s), (x + 18 * s, neck[1] - 16 * s), (x, neck[1] - 30 * s)], 2),
              hair, ol=1.8, shade=0.3)
    pa.line(bez((x - 7 * s, neck[1] - 12 * s), (x, neck[1] - 6 * s), (x + 7 * s, neck[1] - 12 * s), 8), INK, 1.8 * s)
    for ex in (-6, 6):
        shape(pa, rell(x + ex * s, neck[1] - 22 * s, 2.2 * s, 2.6 * s), INK, ol=0, shade=0)


# =================================================================== fresques (1024 x 512, sur brique)

FW, FH = 1024, 512


def mural_canvas(seed):
    return Paint(FW, FH, K=3, bg=(0, 0, 0), seed=seed)


def mural_finish(pa, R, name, W=1024, H=512, margin=True):
    """Pose la fresque sur un mur de briques : le relief des briques et les joints se voient à travers la
    peinture, petites écailles, bords irréguliers, voile de salissure."""
    rgb = down(np.clip(pa.rgb, 0, 1), pa.K * pa.W // W)
    cov = down(pa.cov, pa.K * pa.W // W)
    bcol, bh, mortar, face, inv = brick_surface(R, W, H, 48, 33, "stretcher", jw=2.2, soot=0.25, efflo=0.3)
    shade = bake(np.ones((H, W, 3), np.float32), bh, 4.0, k=0.4, ao=0.35, ao_r=3)[..., 0]
    gr = grain(R, max(W, H), 0.6)[:H, :W]
    big = max(W, H)
    paint = rgb * shade[..., None] * (1 - 0.28 * mortar[..., None]) * (0.94 + 0.08 * gr[..., None])
    keep, pedge = peel_mask(R, W, 0.988, H=H, scale=(32, 64, 128, 256), sharp=0.02)
    a = np.clip(cov, 0, 1) * keep
    if margin:
        yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
        dedge = np.minimum(np.minimum(xx, W - 1 - xx), np.minimum(yy, H - 1 - yy))
        rag = 10 + 14 * tn(R, big, (8, 16, 32, 64), 0.6)[:H, :W]
        a = a * smooth(rag - 2, rag + 2, dedge)
    bsh = bake(bcol, bh, 4.0, k=0.3, ao=0.3, ao_r=3)
    col = bsh * (1 - a[..., None]) + paint * a[..., None]
    col = col * (1 - 0.18 * pedge[..., None] * (1 - keep[..., None]))
    dirt = smooth(0.55, 0.9, vstreak(R, W, (16, 32, 64, 128), 0.6, 6, H=H))
    col = col * (1 - 0.12 * dirt[..., None])
    fade = tn(R, big, (2, 4, 8), 0.6)[:H, :W]
    col = col * (0.95 + 0.07 * fade[..., None]) + 0.02 * (1 - fade[..., None])
    save_rgb(col, name)


def fresque_1():
    """Le rat guitariste des Rats de Cale sur une scène de caisses, rayons de soleil, notes et éclairs."""
    R = rng(7561)
    pa = mural_canvas(7561)
    sunburst(pa, 512, 330, 28, (252, 206, 64), (246, 150, 52))
    pa.glow(512, 300, 260, (255, 240, 200), 0.4)
    shape(pa, rell(512, 250, 210, 210), (232, 70, 120), ol=4, shade=0.3, depth=20)
    shape(pa, rell(512, 250, 182, 182), (250, 120, 150), ol=0, shade=0.2, depth=20)
    # amplis
    for x0 in (60, 820):
        shape(pa, [(x0, 470), (x0, 270), (x0 + 150, 270), (x0 + 150, 470)], (40, 38, 46), ol=3, shade=0.5)
        shape(pa, [(x0 + 8, 292), (x0 + 142, 292), (x0 + 142, 278), (x0 + 8, 278)], (200, 190, 170), ol=1.4, shade=0.2)
        for cy in (340, 420):
            shape(pa, rell(x0 + 75, cy, 50, 34), (70, 68, 78), ol=2.4, shade=0.6)
            shape(pa, rell(x0 + 75, cy, 18, 13), (24, 22, 28), ol=1.6, shade=0.4)
    # scène de caisses
    for k in range(5):
        x0 = 230 + k * 116
        shape(pa, [(x0, 512), (x0, 448), (x0 + 112, 448), (x0 + 112, 512)], (176, 120, 66), ol=2.6, shade=0.5)
        for yy_ in (468, 490):
            pa.line([(x0 + 6, yy_), (x0 + 106, yy_)], (130, 84, 44), 2.2)
    rat(pa, 470, 300, 1.0)
    for (x, y, s, c, dbl, a) in ((180, 140, 1.2, (60, 200, 230), False, -10), (800, 120, 1.3, (120, 230, 90), True, 8), (870, 230, 0.9, (255, 255, 255), False, 12),
                                 (130, 250, 0.8, (255, 255, 255), True, -6), (720, 70, 0.8, (250, 230, 60), False, 0), (300, 80, 0.9, (190, 120, 250), True, -12)):
        note(pa, x, y, s, c, dbl, a)
    bolt(pa, 680, 210, 0.8, (255, 236, 60), 20)
    bolt(pa, 330, 230, 0.6, (255, 236, 60), -25)
    for (x, y, r) in ((240, 40, 14), (640, 30, 12), (960, 60, 16), (60, 60, 12), (400, 470, 0)):
        if r:
            sparkle(pa, x, y, r, (255, 255, 255))
    ptext(pa, (512, 52), "JOUE FORT, SOIS GENTIL !", "black", 40, (255, 255, 255), stroke_w=4, stroke_col=INK, rot=2,
          shadow=(4, 5, 0.6))
    mural_finish(pa, R, "fresque_1.png")


def fresque_2():
    """La mouette géante au bandana au-dessus du port : grues, conteneurs, soleil."""
    R = rng(7562)
    pa = mural_canvas(7562)
    bg_grad(pa, (110, 196, 236), (252, 230, 170))
    shape(pa, rell(800, 150, 90, 90), (255, 214, 90), ol=3, shade=0.2)
    pa.glow(800, 150, 160, (255, 230, 150), 0.5)
    for k in range(3):
        cloud(pa, 140 + k * 360, 90 + (k % 2) * 40, 170, 60, (255, 255, 255), R)
    # mer
    pa.rect(-10, 410, FW + 10, FH + 10, (40, 120, 170), grad=((40, 130, 180), (24, 80, 130), 90), shade=0, ol=0)
    for k in range(40):
        x, y = R.uniform(0, FW), R.uniform(420, 505)
        pa.line([(x, y), (x + R.uniform(20, 60), y)], (190, 230, 250), 2.0, alpha=0.8)
    # grues et conteneurs
    for x0, hgt in ((90, 300), (880, 280)):
        shape(pa, [(x0, 412), (x0 + 14, 412), (x0 + 14, 412 - hgt), (x0, 412 - hgt)], (230, 120, 40), ol=2.4, shade=0.4)
        shape(pa, [(x0 - 60, 412 - hgt), (x0 + 170, 412 - hgt), (x0 + 170, 400 - hgt), (x0 - 60, 400 - hgt)], (230, 120, 40), ol=2.4, shade=0.4)
        pa.line([(x0 + 150, 400 - hgt), (x0 + 150, 330)], INK, 1.6)
        shape(pa, [(x0 + 140, 330), (x0 + 160, 330), (x0 + 160, 344), (x0 + 140, 344)], (60, 60, 64), ol=1.4)
        for k in range(6):
            pa.line([(x0, 412 - k * hgt / 6), (x0 + 14, 412 - (k + 1) * hgt / 6)], INK, 1.2)
    ccols = [(214, 60, 50), (60, 130, 200), (250, 196, 60), (70, 160, 100), (240, 120, 160), (90, 90, 180)]
    k = 0
    for row, y0 in enumerate((412, 372, 332)):
        for i in range(6 - row * 2):
            x0 = 300 + row * 60 + i * 76
            c = ccols[(k * 7 + row) % len(ccols)]
            k += 1
            shape(pa, [(x0, y0), (x0, y0 - 40), (x0 + 74, y0 - 40), (x0 + 74, y0)], c, ol=2.2, shade=0.4, depth=4)
            for j in range(1, 7):
                pa.line([(x0 + j * 10.5, y0 - 36), (x0 + j * 10.5, y0 - 4)], tuple(int(v * 0.75) for v in c), 1.6)
    ptext(pa, (448, 352), "PORT-BOUCAN", "black", 16, (255, 255, 255), stroke_w=0, rot=0)
    gull(pa, 520, 230, 1.2, ang=-4, bandana=(220, 40, 50), flap=10)
    for (x, y) in ((200, 200), (860, 300), (680, 90)):
        pa.line(bez((x - 18, y), (x - 8, y - 10), (x, y), 8) + bez((x, y), (x + 8, y - 10), (x + 18, y), 8), INK, 2.6)
    mural_finish(pa, R, "fresque_2.png")


def fresque_3():
    """La baleine qui nage dans le ciel de nuit, un petit village et un jardin sur son dos, cerfs-volants."""
    R = rng(7563)
    pa = mural_canvas(7563)
    bg_grad(pa, (24, 30, 90), (40, 140, 160))
    for _ in range(90):
        x, y = R.uniform(0, FW), R.uniform(0, 330)
        r = R.uniform(1.0, 3.0)
        shape(pa, rell(x, y, r, r), (255, 250, 210), ol=0, shade=0)
    for (x, y, r) in ((120, 70, 12), (900, 50, 14), (700, 120, 9), (330, 40, 10)):
        sparkle(pa, x, y, r, (255, 246, 200))
    shape(pa, rell(880, 110, 46, 46), (250, 240, 200), ol=2.6, shade=0.3)
    shape(pa, rell(902, 98, 40, 40), (34, 50, 110), ol=0, shade=0)
    for (x, y, w) in ((150, 430, 300), (520, 470, 380), (900, 430, 300), (330, 200, 160)):
        cloud(pa, x, y, w, w * 0.32, (232, 236, 250), R)
    whale(pa, 520, 300, 1.0)
    # village sur le dos
    for (x, w, h, wc, rc) in ((380, 44, 34, (240, 200, 90), (200, 60, 50)), (432, 36, 48, (120, 190, 230), (60, 70, 140)), (480, 50, 30, (240, 150, 170), (130, 60, 120)),
                              (560, 40, 40, (150, 210, 120), (200, 90, 40))):
        base = 300 - 104 + (abs(x - 470) ** 1.6) * 0.004
        house(pa, x, base + 6, w, h, wc, rc)
    stroke(pa, [(612, 196), (614, 150)], 6, (110, 80, 50), ol=1.6)
    cloud(pa, 614, 138, 56, 40, (80, 170, 90), R, shade=0.5)
    # cerfs-volants
    for (x, y, c) in ((250, 150, (240, 80, 90)), (760, 210, (250, 210, 60))):
        shape(pa, [(x, y - 28), (x + 20, y), (x, y + 34), (x - 20, y)], c, ol=2, shade=0.3)
        pa.line([(x, y + 34), (x + 20, y + 80), (x + 60, y + 110)], (250, 250, 250), 1.4)
        for k in range(3):
            shape(pa, rell(x + 6 + k * 16, y + 50 + k * 22, 6, 3, 40), (250, 250, 250), ol=1, shade=0)
    mural_finish(pa, R, "fresque_3.png")


def hand(pa, wx, wy, ang, s, skin, sleeve=None):
    """Bras et main ouverte (paume vers le centre) ; (wx, wy) = poignet ; ang = direction des doigts."""
    def P(pts):
        return xform([(wx + x * s, wy + y * s) for x, y in pts], wx, wy, ang)
    stroke(pa, P([(-260, 0), (-120, 0), (0, 0)]), 60 * s, skin, 46 * s, ol=2.6)
    if sleeve:
        shape(pa, P([(-262, -36), (-150, -34), (-150, 34), (-262, 36)]), sleeve, ol=2.6, shade=0.5)
        pa.line(P([(-150, -34), (-150, 34)]), INK, 2.4)
    palm = chaikin([(-6, -26), (40, -32), (62, -24), (66, 22), (40, 34), (-4, 26)], 2)
    fingers = []
    for k, (dy, L) in enumerate(((-21, 46), (-7, 54), (7, 52), (20, 42))):
        fingers.append(tube([(58, dy * 1.05), (58 + L * 0.6, dy * 1.12), (58 + L, dy * 1.18)], 14, 11))
    thumb = tube([(20, -26), (44, -52), (66, -62)], 16, 12)
    union(pa, [P(palm)] + [P(f) for f in fingers] + [P(thumb)], skin, ol=2.6, shade=0.6, depth=8)
    pa.line(P(bez((14, 14), (30, 4), (44, 18), 8)), tuple(int(v * 0.7) for v in skin), 1.6 * s)


def fresque_4():
    """Des mains de toutes les couleurs qui portent ensemble un grand cœur : arcs-en-ciel, « ENTRAIDE »."""
    R = rng(7564)
    pa = mural_canvas(7564)
    bg_grad(pa, (250, 236, 200), (250, 214, 170))
    rain = [(232, 64, 72), (246, 146, 50), (252, 214, 64), (90, 190, 100), (60, 150, 220), (130, 90, 200)]
    for k, c in enumerate(rain):
        r = 470 - k * 34
        shape(pa, rell(512, 300, r, r * 0.86), c, ol=0, shade=0.15, depth=10)
    shape(pa, rell(512, 300, 266, 230), (250, 236, 200), ol=0, shade=0.1)
    skins = [(240, 196, 160), (196, 130, 90), (130, 84, 56), (90, 56, 40), (226, 170, 120), (110, 200, 220), (170, 120, 220), (120, 210, 120)]
    sleeves = [(220, 50, 60), (40, 40, 50), (60, 120, 200), (250, 200, 60), (90, 170, 90), (230, 120, 170), (40, 40, 50), (240, 140, 40)]
    n = 8
    for k in range(n):
        a = -90 + k * 360 / n + 22.5
        ar = math.radians(a)
        wx = 512 + math.cos(ar) * 236
        wy = 270 + math.sin(ar) * 190
        hand(pa, wx, wy, a + 180, 0.92, skins[k], sleeves[k])
    shape(pa, heart_pts(512, 262, 8.2), (226, 40, 60), ol=4, shade=0.8, depth=26)
    shape(pa, rell(470, 220, 26, 16, -30), (255, 150, 160), ol=0, shade=0, alpha=0.7)
    for (x, y, r) in ((380, 120, 12), (650, 110, 14), (420, 420, 10), (640, 420, 12)):
        sparkle(pa, x, y, r, (255, 255, 255))
    shape(pa, [(300, 470), (724, 470), (744, 500), (280, 500)], (40, 40, 52), ol=3, shade=0.4)
    ptext(pa, (512, 486), "ENTRAIDE", "black", 30, (255, 236, 90), spacing=8)
    mural_finish(pa, R, "fresque_4.png")


def fresque_5():
    """Le phare tagué dont le faisceau répand des notes de musique sur la mer au couchant."""
    R = rng(7565)
    pa = mural_canvas(7565)
    bg_grad(pa, (70, 40, 120), (252, 150, 80))
    shape(pa, rell(200, 330, 80, 80), (255, 200, 90), ol=0, shade=0.1)
    pa.glow(200, 330, 140, (255, 200, 120), 0.5)
    pa.rect(-10, 350, FW + 10, FH + 10, (40, 70, 130), grad=((60, 90, 150), (20, 40, 90), 90), shade=0, ol=0)
    for k in range(50):
        x, y = R.uniform(0, FW), R.uniform(360, 505)
        pa.line([(x, y), (x + R.uniform(20, 70), y)], (250, 190, 140) if x < 360 else (150, 190, 240), 2.0, alpha=0.7)
    # rochers
    shape(pa, chaikin([(560, 420), (600, 360), (680, 340), (800, 350), (880, 380), (920, 440), (540, 450)], 2), (70, 64, 70), ol=3, shade=0.6, depth=14)
    # faisceaux
    for (a0, a1, c) in ((-170, -150, (255, 240, 160)), (-20, -2, (255, 240, 160))):
        pts = [(730, 110)]
        for a in (a0, a1):
            pts.append((730 + math.cos(math.radians(a)) * 900, 110 + math.sin(math.radians(a)) * 900))
        pa.poly(pts, c, shade=0, ol=0, alpha=0.5)
    # le phare
    body = [(690, 350), (702, 140), (758, 140), (770, 350)]
    shape(pa, body, (250, 250, 246), ol=3, shade=0.6, depth=12)
    for k in range(4):
        y0 = 350 - k * 54 - 28
        y1 = y0 - 26
        t0, t1 = (350 - y0) / 210, (350 - y1) / 210
        shape(pa, [(690 + 12 * t0, y0), (770 - 12 * t0, y0), (770 - 12 * t1, y1), (690 + 12 * t1, y1)], (220, 50, 50), ol=1.6, shade=0.5)
    shape(pa, [(690, 140), (770, 140), (770, 128), (690, 128)], (40, 40, 48), ol=2, shade=0.3)
    shape(pa, [(704, 128), (756, 128), (756, 90), (704, 90)], (255, 230, 120), ol=2.4, shade=0)
    pa.glow(730, 110, 60, (255, 230, 140), 0.8)
    shape(pa, [(698, 90), (762, 90), (730, 62)], (220, 50, 50), ol=2.4, shade=0.4)
    shape(pa, [(712, 350), (712, 316), (728, 306), (744, 316), (744, 350)], (90, 60, 40), ol=2, shade=0.3)
    # tags sur le phare
    ptext(pa, (730, 250), "BOUM", "popi", 14, (60, 180, 240), stroke_w=1.5, stroke_col=INK, rot=8)
    ptext(pa, (728, 196), "♥", "bold", 16, (240, 80, 160))
    for (x, y, s, c, dbl, a) in ((560, 60, 1.0, (255, 255, 255), False, -10), (430, 110, 1.1, (120, 230, 250), True, 0), (300, 70, 0.9, (255, 230, 90), False, 10),
                                 (150, 150, 0.8, (255, 160, 200), True, -8), (880, 60, 0.9, (255, 255, 255), True, 8), (960, 140, 0.8, (180, 255, 160), False, 4)):
        note(pa, x, y, s, c, dbl, a)
    for (x, y) in ((340, 230), (420, 260), (620, 200)):
        pa.line(bez((x - 14, y), (x - 6, y - 8), (x, y), 8) + bez((x, y), (x + 6, y - 8), (x + 14, y), 8), INK, 2.2)
    mural_finish(pa, R, "fresque_5.png")


def fresque_6():
    """La cathédrale des champignons : un grand champignon-dôme lumineux, des champignons-colonnes,
    des vitraux-spores, de petits habitants émerveillés."""
    R = rng(7566)
    pa = mural_canvas(7566)
    bg_grad(pa, (30, 20, 70), (90, 50, 130))
    for _ in range(70):
        x, y = R.uniform(0, FW), R.uniform(0, 300)
        r = R.uniform(1, 2.6)
        shape(pa, rell(x, y, r, r), (255, 240, 255), ol=0, shade=0)
    pa.rect(-10, 440, FW + 10, FH + 10, (40, 90, 70), grad=((50, 110, 80), (20, 60, 50), 90), shade=0, ol=0)
    # colonnes latérales
    for (cx, h, w, cap, glow) in ((150, 250, 150, (150, 70, 200), (200, 120, 255)), (300, 320, 170, (240, 120, 40), (255, 180, 80)),
                                  (724, 320, 170, (240, 120, 40), (255, 180, 80)), (874, 250, 150, (150, 70, 200), (200, 120, 255))):
        mushroom(pa, cx, 460, h, w, cap, glow=glow, R=R)
    # le dôme central
    mushroom(pa, 512, 470, 330, 330, (40, 130, 220), spots=(220, 250, 255), glow=(120, 200, 255), R=R)
    # vitraux dans le grand pied : arcs brisés colorés
    for k, (x, c) in enumerate(((482, (255, 120, 160)), (512, (255, 230, 120)), (542, (120, 230, 255)))):
        top = 330 if k == 1 else 350
        pts = [(x - 11, 440)] + [(x - 11 + 22 * (0.5 - 0.5 * math.cos(t * math.pi)), top - 22 * math.sin(t * math.pi)) for t in np.linspace(0, 1, 12)] + [(x + 11, 440)]
        shape(pa, pts, c, ol=2, shade=0)
        pa.glow(x, 400, 26, c, 0.35)
    # spores lumineuses
    for _ in range(60):
        x, y = R.uniform(0, FW), R.uniform(40, 430)
        r = R.uniform(2, 5)
        c = [(170, 255, 240), (255, 220, 140), (220, 170, 255)][int(R.integers(3))]
        pa.glow(x, y, r * 3, c, 0.5)
        shape(pa, rell(x, y, r, r), c, ol=0, shade=0)
    # petits habitants (silhouettes) et un rat
    for (x, c, hc) in ((420, (60, 50, 70), (250, 80, 120)), (610, (60, 50, 70), (90, 220, 120))):
        person(pa, x, 470, 0.45, (230, 180, 140), c, (50, 50, 70), hc, pose=0, R=R)
    mural_finish(pa, R, "fresque_6.png")


def ship(pa, cx, cy, s, hull=(200, 50, 40), name="LA BALEINE ROUILLÉE"):
    """Le cargo (vers la droite), coque rouge, château blanc, cheminée à l'emblème du rat."""
    def P(pts):
        return [(cx + x * s, cy + y * s) for x, y in pts]
    shape(pa, P([(-300, -20), (300, -20), (360, -60), (330, 50), (-270, 50), (-320, -40)]), hull, ol=3, shade=0.6, depth=10)
    shape(pa, P([(-292, 26), (334, 26), (330, 50), (-270, 50)]), (40, 40, 50), ol=0, shade=0.3)
    ptext(pa, (cx + 10 * s, cy + 6 * s), name, "black", 15 * s, (250, 240, 220))
    for k in range(5):
        x0 = -120 + k * 64
        c = [(60, 130, 200), (250, 196, 60), (70, 160, 100), (240, 120, 160), (214, 60, 50)][k]
        shape(pa, P([(x0, -20), (x0, -56), (x0 + 60, -56), (x0 + 60, -20)]), c, ol=2, shade=0.4)
    shape(pa, P([(-280, -20), (-280, -120), (-180, -120), (-170, -20)]), (246, 244, 236), ol=2.6, shade=0.5)
    for k in range(4):
        shape(pa, P(rell(-260 + k * 24, -96, 7, 7)), (120, 200, 240), ol=1.4, shade=0)
        shape(pa, P(rell(-260 + k * 24, -60, 7, 7)), (120, 200, 240), ol=1.4, shade=0)
    shape(pa, P([(-246, -120), (-246, -184), (-206, -184), (-206, -120)]), (40, 40, 50), ol=2.4, shade=0.4)
    shape(pa, P([(-246, -168), (-206, -168), (-206, -150), (-246, -150)]), (250, 200, 60), ol=1.4, shade=0.2)
    shape(pa, P([(-300, -20), (-300, -40), (-280, -40)]), hull, ol=2, shade=0.3)
    stroke(pa, P([(-110, -56), (-110, -190)]), 5 * s, (60, 60, 64), ol=1.4)
    stroke(pa, P([(240, -20), (240, -150)]), 5 * s, (60, 60, 64), ol=1.4)
    shape(pa, P([(240, -150), (290, -140), (240, -128)]), (240, 60, 70), ol=1.6, shade=0.2)
    pa.line(P([(-110, -190), (240, -150)]), INK, 1.4)
    for k in range(7):
        x = -100 + k * 46
        y = -186 + k * 5
        shape(pa, P([(x, y), (x + 14, y + 2), (x + 7, y + 16)]), [(240, 80, 90), (250, 210, 60), (90, 200, 120), (80, 160, 240)][k % 4], ol=1, shade=0)


def fresque_7():
    """Le cargo « La Baleine Rouillée » qui navigue sur une mer de nuages, sa fumée fait des cœurs et des notes."""
    R = rng(7567)
    pa = mural_canvas(7567)
    bg_grad(pa, (90, 170, 240), (220, 236, 250))
    sunburst(pa, 880, 90, 20, (255, 240, 180), (170, 214, 250), rot=5)
    shape(pa, rell(880, 90, 60, 60), (255, 220, 100), ol=3, shade=0.2)
    for (x, y, w) in ((120, 330, 340), (900, 350, 360), (500, 420, 520), (150, 480, 380), (820, 490, 420)):
        cloud(pa, x, y, w, w * 0.3, (250, 250, 255), R, shade=0.5)
    ship(pa, 520, 300, 1.0)
    for (x, y, w) in ((260, 440, 380), (780, 450, 380), (520, 490, 520)):
        cloud(pa, x, y, w, w * 0.25, (244, 246, 255), R, shade=0.5)
    # fumée en cœurs et notes
    for k, (x, y) in enumerate(((290, 120), (330, 80), (380, 46))):
        shape(pa, heart_pts(x, y, 1.6 + k * 0.4), (250, 120, 150), ol=2, shade=0.4)
    note(pa, 420, 40, 0.7, (255, 255, 255), True, 10)
    for (x, y) in ((620, 120), (700, 160), (130, 140)):
        pa.line(bez((x - 16, y), (x - 7, y - 9), (x, y), 8) + bez((x, y), (x + 7, y - 9), (x + 16, y), 8), INK, 2.4)
    mural_finish(pa, R, "fresque_7.png")


def fresque_8():
    """La foule qui danse le pogo devant la scène : projecteurs, enceintes, notes, banderole."""
    R = rng(7568)
    pa = mural_canvas(7568)
    bg_grad(pa, (60, 20, 90), (240, 90, 120))
    for (x, c) in ((150, (255, 230, 120)), (420, (120, 230, 255)), (640, (255, 140, 200)), (900, (180, 255, 140))):
        pa.poly([(x, -10), (x - 120, 520), (x + 120, 520)], c, shade=0, ol=0, alpha=0.18)
    pa.rect(-10, 60, FW + 10, 90, (40, 30, 50), shade=0, ol=0)
    shape(pa, [(250, 18), (774, 18), (790, 80), (234, 80)], (250, 220, 60), ol=3, shade=0.3)
    ptext(pa, (512, 50), "LA HALLE HURLANTE", "black", 34, (220, 40, 60), spacing=2)
    for x0 in (20, 900):
        shape(pa, [(x0, 470), (x0, 200), (x0 + 104, 200), (x0 + 104, 470)], (34, 32, 40), ol=3, shade=0.5)
        for cy in (260, 360):
            shape(pa, rell(x0 + 52, cy, 38, 38), (64, 62, 74), ol=2, shade=0.6)
            shape(pa, rell(x0 + 52, cy, 14, 14), (20, 20, 24), ol=1.4, shade=0.4)
    skins = [(240, 196, 160), (196, 130, 90), (130, 84, 56), (90, 56, 40), (226, 170, 120)]
    tops = [(220, 50, 60), (40, 40, 50), (60, 120, 200), (250, 200, 60), (90, 170, 90), (230, 120, 170), (250, 250, 250), (240, 140, 40)]
    hairs = [(240, 40, 60), (60, 220, 100), (60, 140, 250), (250, 100, 200), (250, 240, 240), (170, 80, 240), (255, 200, 40)]
    xs = [200, 305, 410, 515, 620, 725, 830]
    for row, (yb, sc) in enumerate(((505, 1.55),)):
        for i, x in enumerate(xs):
            person(pa, x + R.uniform(-12, 12), yb + R.uniform(-20, 4), sc, skins[(i + row) % 5], tops[(i * 3 + row) % 8], (40, 40, 60) if i % 2 else (60, 60, 110),
                   hairs[(i + row * 2) % 7], pose=(i + row) % 4, R=R, mohawk=(i + row) % 3 != 2)
    for (x, y, s, c, dbl, a) in ((120, 130, 0.9, (255, 255, 255), True, -10), (880, 140, 1.0, (255, 230, 90), False, 8), (300, 120, 0.7, (120, 230, 255), False, 0),
                                 (720, 120, 0.8, (255, 160, 200), True, 6)):
        note(pa, x, y, s, c, dbl, a)
    for (x, y, r) in ((200, 180, 10), (820, 200, 12), (520, 140, 9)):
        sparkle(pa, x, y, r, (255, 255, 255))
    mural_finish(pa, R, "fresque_8.png")


def fresques():
    for k in range(1, 9):
        globals()["fresque_%d" % k]()


# =================================================================== graffitis (1024 x 512, transparents)

def _dil(mask, r):
    """Dilatation d'un masque booléen de r px (distance euclidienne)."""
    if r <= 0:
        return mask
    return ndimage.distance_transform_edt(~mask) <= r


def _over(rgb, a, col, alpha):
    """Compose une couche (couleur ou image, alpha) par-dessus (rgb, a) non prémultipliés."""
    alpha = np.clip(alpha, 0, 1)
    col = np.asarray(col, np.float32)
    if col.ndim == 1:
        col = col[None, None, :]
    na = alpha + a * (1 - alpha)
    out = (col * alpha[..., None] + rgb * (a * (1 - alpha))[..., None]) / np.maximum(na, 1e-6)[..., None]
    return out.astype(np.float32), na.astype(np.float32)


GRAF = {
    1: ("BOUCAN", None, ((255, 214, 40), (255, 90, 40)), (40, 200, 230), (110, 30, 120)),
    2: ("LIBRE", None, ((120, 240, 120), (20, 150, 110)), (255, 120, 200), (20, 60, 70)),
    3: ("DIY", None, ((255, 120, 200), (180, 40, 200)), (255, 230, 60), (40, 20, 80)),
    4: ("ENTRAIDE", None, ((100, 200, 255), (40, 90, 220)), (255, 170, 60), (20, 30, 90)),
    5: ("RATS", "DE CALE", ((255, 70, 70), (180, 20, 60)), (250, 250, 250), (40, 30, 40)),
    6: ("PORT-", "BOUCAN", ((255, 180, 60), (240, 70, 120)), (90, 220, 200), (60, 20, 70)),
}


def graffiti_text(n):
    """Lettrage à la bombe : lettres bombées et dansantes, contour noir épais, extrusion 3D, nuage de
    fond, dégradé et reflets blancs, coulures, poussière de peinture autour (PNG transparent)."""
    word, word2, (c1, c2), cloud_c, ext_c = GRAF[n]
    R = rng(7580 + n)
    W, H = 2048, 1024
    m = Image.new("L", (W, H), 0)
    lines = [word] if not word2 else [word, word2]
    nl = len(lines)
    for li, line in enumerate(lines):
        maxw = 1640
        maxh = 600 if nl == 1 else 330
        size = 520 if nl == 1 else 300
        while size > 40:
            f = ff("black", size)
            widths = [ImageDraw.Draw(Image.new("L", (8, 8))).textlength(ch, font=f) * 0.9 for ch in line]
            bb = ImageDraw.Draw(Image.new("L", (8, 8))).textbbox((0, 0), line, font=f)
            if sum(widths) <= maxw and bb[3] - bb[1] <= maxh:
                break
            size -= 10
        f = ff("black", size)
        cy = H / 2 if nl == 1 else (H / 2 - 175 + li * 340)
        x = (W - sum(widths)) / 2
        for ch, w in zip(line, widths):
            if ch == " ":
                x += w
                continue
            g = Image.new("L", (int(size * 1.6), int(size * 1.6)), 0)
            gd = ImageDraw.Draw(g)
            gd.text((g.size[0] / 2, g.size[1] / 2), ch, font=f, fill=255, anchor="mm")
            sc = R.uniform(0.92, 1.12)
            g = g.resize((int(g.size[0] * sc), int(g.size[1] * sc)), Image.BICUBIC).rotate(R.uniform(-9, 9), resample=Image.BICUBIC)
            px = int(x + w / 2 - g.size[0] / 2)
            py = int(cy - g.size[1] / 2 + R.uniform(-22, 22))
            m.paste(255, (px, py), g)
            x += w
    a = np.asarray(m, np.float32) / 255.0
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    dx = (tn(R, W, (8, 16, 32), 0.6, H=H) - 0.5) * 36
    dy = (tn(R, W, (8, 16, 32), 0.6, H=H) - 0.5) * 36
    a = ndimage.map_coordinates(a, [yy + dy, xx + dx], order=1, mode="constant")
    a = ndimage.gaussian_filter(a, 7)
    fill = a > 0.5
    outline = _dil(fill, 16)
    ext = np.zeros_like(fill)
    for k in range(1, 30, 2):
        ext |= np.roll(np.roll(outline, k, 0), k, 1)
    ext_out = _dil(ext, 4)
    cloudm = ndimage.gaussian_filter(_dil(outline | ext, 46).astype(np.float32), 14) > 0.5
    cloud_out = _dil(cloudm, 9)
    halo = ndimage.gaussian_filter(_dil(cloud_out, 30).astype(np.float32), 22)
    rgb = np.zeros((H, W, 3), np.float32)
    al = np.zeros((H, W), np.float32)
    sp = R.random((H, W)).astype(np.float32)
    rgb, al = _over(rgb, al, np.array(cloud_c, np.float32) / 255, halo * 0.35 * (sp < 0.5))
    rgb, al = _over(rgb, al, np.array(INK, np.float32) / 255, cloud_out.astype(np.float32))
    ccol = np.array(cloud_c, np.float32) / 255 * (0.9 + 0.15 * tn(R, W, (16, 32, 64), 0.6, H=H)[..., None])
    rgb, al = _over(rgb, al, ccol, cloudm.astype(np.float32))
    # bulles et étoiles décoratives dans le nuage
    deco = Image.new("L", (W, H), 0)
    dd = ImageDraw.Draw(deco)
    ys, xs = np.nonzero(cloudm & ~_dil(outline | ext, 20))
    for _ in range(14):
        if len(xs) == 0:
            break
        i = int(R.integers(len(xs)))
        x0, y0, r = xs[i], ys[i], R.uniform(8, 20)
        dd.ellipse((x0 - r, y0 - r, x0 + r, y0 + r), outline=255, width=5)
    rgb, al = _over(rgb, al, np.array((255, 255, 255), np.float32) / 255, np.asarray(deco, np.float32) / 255 * 0.9)
    rgb, al = _over(rgb, al, np.array(INK, np.float32) / 255, ext_out.astype(np.float32))
    eg = np.array(ext_c, np.float32) / 255
    rgb, al = _over(rgb, al, eg * (0.7 + 0.5 * ((yy / H)[..., None])), (ext & ~outline).astype(np.float32))
    rgb, al = _over(rgb, al, np.array(INK, np.float32) / 255, outline.astype(np.float32))
    # remplissage : dégradé vertical par ligne + bande claire, grain de bombe
    t = np.clip((yy - yy[fill].min()) / max(1, (yy[fill].max() - yy[fill].min())), 0, 1) if fill.any() else yy / H
    if nl == 2:
        t = np.where(yy < H / 2, np.clip((yy - (H / 2 - 175 - 150)) / 300, 0, 1), np.clip((yy - (H / 2 + 165 - 150)) / 300, 0, 1))
    fc = mix(np.array(c1, np.float32) / 255, np.array(c2, np.float32) / 255, t[..., None])
    band = np.exp(-((t - 0.42) / 0.06) ** 2)
    fc = mix(fc, np.minimum(fc * 1.35 + 0.1, 1), band[..., None] * 0.6)
    fc = fc * (0.94 + 0.1 * grain(R, W, 0.7, H=H)[..., None])
    rgb, al = _over(rgb, al, fc, fill.astype(np.float32))
    # reflets : arête haut-gauche intérieure, petits traits
    shine = fill & ~np.roll(np.roll(fill, 9, 0), 9, 1)
    rgb, al = _over(rgb, al, np.array((255, 255, 255), np.float32) / 255, shine.astype(np.float32) * 0.85)
    sh = Image.new("L", (W, H), 0)
    ds = ImageDraw.Draw(sh)
    ys, xs = np.nonzero(fill & ~_dil(~fill, 22))
    for _ in range(10):
        if len(xs) == 0:
            break
        i = int(R.integers(len(xs)))
        x0, y0 = xs[i], ys[i]
        ds.line([(x0, y0), (x0 + 16, y0 - 16)], fill=255, width=9)
        ds.ellipse((x0 + 22, y0 - 30, x0 + 32, y0 - 20), fill=255)
    rgb, al = _over(rgb, al, np.array((255, 255, 255), np.float32) / 255, (np.asarray(sh, np.float32) / 255) * fill)
    # coulures depuis le bas des lettres
    dr = Image.new("L", (W, H), 0)
    dc = Image.new("RGB", (W, H), (0, 0, 0))
    ddr, ddc = ImageDraw.Draw(dr), ImageDraw.Draw(dc)
    bottoms = fill & ~np.roll(fill, -1, 0)
    ys, xs = np.nonzero(bottoms)
    for _ in range(16):
        if len(xs) == 0:
            break
        i = int(R.integers(len(xs)))
        x0, y0 = int(xs[i]), int(ys[i])
        L = R.uniform(30, 170)
        w = R.uniform(8, 15)
        col = tuple(int(v * 255) for v in fc[min(H - 1, y0), x0])
        ddr.line([(x0, y0 - 4), (x0, y0 + L)], fill=255, width=int(w + 8))
        ddr.ellipse((x0 - w / 2 - 4, y0 + L - w / 2 - 4, x0 + w / 2 + 4, y0 + L + w * 0.9 + 4), fill=255)
        ddc.line([(x0, y0 - 4), (x0, y0 + L)], fill=col, width=int(w))
        ddc.ellipse((x0 - w / 2, y0 + L - w / 2, x0 + w / 2, y0 + L + w * 0.9), fill=col)
    dm = np.asarray(dr, np.float32) / 255
    dcol = np.asarray(dc, np.float32) / 255
    inner = (dcol.sum(-1) > 0).astype(np.float32)
    rgb, al = _over(rgb, al, np.array(INK, np.float32) / 255, dm * (1 - fill))
    rgb, al = _over(rgb, al, dcol, inner)
    # brouillard de bombe et petites projections
    spl = (sp > 0.9993).astype(np.float32) * ndimage.gaussian_filter(cloud_out.astype(np.float32), 40) * 3
    rgb, al = _over(rgb, al, np.array(c2, np.float32) / 255, np.clip(ndimage.gaussian_filter(spl, 1.2) * 4, 0, 1))
    out = np.dstack([rgb, al])
    img = Image.fromarray((np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").resize((1024, 512), Image.LANCZOS)
    save_rgba(img, "graffiti_%d.png" % n)


def graffiti_paint(n, draw, drip_cols, seed):
    """Dessin à la bombe (Paint) transformé en graffiti : halo de peinture, gros contour, coulures."""
    R = rng(seed)
    pa = Paint(1024, 512, K=2, bg=(0, 0, 0), seed=seed)
    draw(pa, R)
    rgb = np.clip(pa.rgb, 0, 1)
    cov = np.clip(pa.cov, 0, 1)
    H, W = cov.shape
    fill = cov > 0.5
    outline = _dil(fill, 10)
    halo = ndimage.gaussian_filter(_dil(outline, 18).astype(np.float32), 16)
    sp = R.random((H, W)).astype(np.float32)
    base = np.zeros((H, W, 3), np.float32)
    al = np.zeros((H, W), np.float32)
    hc = np.array(drip_cols[0], np.float32) / 255
    base, al = _over(base, al, hc, halo * 0.3 * (sp < 0.55))
    base, al = _over(base, al, np.array(INK, np.float32) / 255, outline.astype(np.float32))
    base, al = _over(base, al, rgb, cov)
    dr = Image.new("L", (W, H), 0)
    dc = Image.new("RGB", (W, H), (0, 0, 0))
    ddr, ddc = ImageDraw.Draw(dr), ImageDraw.Draw(dc)
    bottoms = fill & ~np.roll(fill, -1, 0)
    ys, xs = np.nonzero(bottoms)
    for _ in range(10):
        if len(xs) == 0:
            break
        i = int(R.integers(len(xs)))
        x0, y0 = int(xs[i]), int(ys[i])
        L = R.uniform(30, 140)
        if y0 + L > H - 20:
            continue
        w = R.uniform(7, 13)
        col = tuple(int(v * 255) for v in rgb[max(0, y0 - 3), x0])
        ddr.line([(x0, y0 - 4), (x0, y0 + L)], fill=255, width=int(w + 7))
        ddr.ellipse((x0 - w / 2 - 4, y0 + L - w / 2 - 4, x0 + w / 2 + 4, y0 + L + w + 4), fill=255)
        ddc.line([(x0, y0 - 4), (x0, y0 + L)], fill=col, width=int(w))
        ddc.ellipse((x0 - w / 2, y0 + L - w / 2, x0 + w / 2, y0 + L + w), fill=col)
    dm = np.asarray(dr, np.float32) / 255
    dcol = np.asarray(dc, np.float32) / 255
    base, al = _over(base, al, np.array(INK, np.float32) / 255, dm * (1 - fill))
    base, al = _over(base, al, dcol, (dcol.sum(-1) > 0).astype(np.float32))
    out = np.dstack([base, al])
    img = Image.fromarray((np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").resize((1024, 512), Image.LANCZOS)
    save_rgba(img, "graffiti_%d.png" % n)


def _g_sardine(pa, R):
    body = chaikin([(250, 260), (330, 180), (500, 150), (680, 170), (770, 230), (790, 260), (770, 300), (680, 350), (500, 370), (330, 340)], 3)
    tail = chaikin([(300, 260), (150, 160), (130, 180), (180, 260), (130, 340), (150, 360)], 1)
    shape(pa, tail, (60, 140, 220), ol=4, shade=0.6)
    shape(pa, body, (150, 200, 240), ol=5, shade=0.8, depth=30, grad=((120, 180, 240), (230, 240, 250), 90))
    shape(pa, chaikin([(330, 190), (500, 160), (680, 180), (700, 220), (500, 215), (340, 240)], 2), (50, 110, 200), ol=0, shade=0.4)
    for k in range(6):
        shape(pa, rell(380 + k * 55, 280, 9, 9), (255, 255, 255), ol=0, shade=0)
    shape(pa, chaikin([(460, 175), (520, 90), (590, 110), (590, 180)], 1), (60, 140, 220), ol=4, shade=0.5)
    shape(pa, rell(690, 230, 26, 28), (255, 255, 255), ol=3.5, shade=0.2)
    shape(pa, rell(698, 232, 13, 15), (20, 20, 30), ol=0, shade=0)
    shape(pa, rell(703, 225, 5, 5), (255, 255, 255), ol=0, shade=0)
    pa.line(bez((690, 300), (740, 330), (785, 280), 16), INK, 7)
    shape(pa, rell(650, 300, 18, 10), (255, 140, 170), ol=0, shade=0, alpha=0.8)
    for (x, y, r) in ((860, 150, 26), (880, 300, 16), (120, 110, 18)):
        sparkle(pa, x, y, r, (255, 240, 80), ol=3)


def _g_mushroom(pa, R):
    mushroom(pa, 512, 470, 250, 500, (230, 40, 50), spots=(255, 255, 250), stem=(250, 236, 210), R=R)
    for ex in (470, 554):
        shape(pa, rell(ex, 360, 14, 20), (30, 24, 30), ol=0, shade=0)
        shape(pa, rell(ex + 4, 352, 5, 6), (255, 255, 255), ol=0, shade=0)
    pa.line(bez((480, 400), (512, 425), (544, 400), 14), INK, 6)
    for x in (468, 556):
        shape(pa, rell(x, 392, 9, 5), (255, 150, 170), ol=0, shade=0, alpha=0.8)
    for (x, y, r) in ((170, 120, 24), (860, 130, 30), (880, 380, 18)):
        sparkle(pa, x, y, r, (120, 240, 255), ol=3)


def _g_star(pa, R):
    for k in range(4):
        y = 180 + k * 50
        stroke(pa, [(130 + k * 26, y), (310, y)], 14, (255, 255, 255), ol=3)
    shape(pa, star_pts(560, 260, 230, 5, 0.48, -80), (255, 220, 40), ol=5, shade=0.8, depth=30, grad=((255, 240, 80), (255, 150, 30), 90))
    for ex in (520, 600):
        shape(pa, rell(ex, 245, 14, 22), (30, 24, 30), ol=0, shade=0)
        shape(pa, rell(ex + 4, 236, 5, 7), (255, 255, 255), ol=0, shade=0)
    pa.line(bez((520, 300), (560, 335), (606, 296), 14), INK, 7)
    for x in (480, 640):
        shape(pa, rell(x, 290, 18, 10), (255, 130, 100), ol=0, shade=0, alpha=0.8)


def _g_heart(pa, R):
    shape(pa, heart_pts(512, 250, 15), (230, 30, 70), ol=5, shade=0.8, depth=36, grad=((255, 80, 120), (190, 20, 60), 90))
    shape(pa, rell(420, 160, 40, 22, -30), (255, 170, 190), ol=0, shade=0, alpha=0.8)
    bolt(pa, 530, 270, 2.6, (255, 230, 40), 12)
    for (x, y, r) in ((200, 120, 26), (830, 140, 22), (820, 400, 16)):
        sparkle(pa, x, y, r, (255, 255, 255), ol=3)


def _g_rat(pa, R):
    rat(pa, 470, 300, 1.05, crest=((60, 230, 90), (40, 200, 240), (250, 70, 200)), play=False)
    stroke(pa, [(500, 230), (580, 190), (640, 120)], 22, (128, 124, 136), 18, ol=3)
    shape(pa, rell(646, 110, 16, 14), (236, 160, 170), ol=3)
    for k in range(3):
        pa.line(bez((680 + k * 14, 70 + k * 20), (700 + k * 14, 90 + k * 20), (690 + k * 14, 110 + k * 20), 8), INK, 5)


def _g_gull(pa, R):
    gull(pa, 512, 290, 1.4, ang=-6, bandana=(40, 140, 230), flap=-10)


GRAF_DRAW = {7: (_g_sardine, ((90, 180, 240),)), 8: (_g_mushroom, ((240, 60, 70),)), 9: (_g_star, ((255, 210, 40),)),
             10: (_g_heart, ((240, 60, 100),)), 11: (_g_rat, ((80, 230, 120),)), 12: (_g_gull, ((80, 170, 240),))}


def graffiti(n):
    if n in GRAF:
        graffiti_text(n)
    else:
        fn, cols = GRAF_DRAW[n]
        graffiti_paint(n, fn, cols, 7580 + n)


def graffitis():
    for n in range(1, 13):
        graffiti(n)


# =================================================================== affiches, panneau Lisse, fanzine

def tmask(W, H, s, kind, size, xy, anchor="mm", rot=0.0, spacing=0.0, maxw=None):
    """Masque (0..1) d'un texte (W x H px), taille réduite si besoin pour tenir dans maxw."""
    if maxw:
        size = fit_size(s, kind, size, maxw, spacing)
    m = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(m)
    f = ff(kind, size)
    if spacing:
        tw = sum(d.textlength(ch, font=f) for ch in s) + spacing * (len(s) - 1)
        x = xy[0] - tw / 2 if anchor[0] == "m" else (xy[0] - tw if anchor[0] == "r" else xy[0])
        for ch in s:
            d.text((x, xy[1]), ch, font=f, fill=255, anchor="l" + anchor[1])
            x += d.textlength(ch, font=f) + spacing
    else:
        d.text(xy, s, font=f, fill=255, anchor=anchor)
    if rot:
        m = m.rotate(rot, center=xy, resample=Image.BICUBIC)
    return np.asarray(m, np.float32) / 255.0


def halftone(L, period=7.0, ang=15.0, gain=1.0):
    """Trame de points (sérigraphie / photocopie) : 1 là où l'encre se pose, pour un ton 1 - L."""
    H, W = L.shape
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    a = math.radians(ang)
    u = (xx * math.cos(a) + yy * math.sin(a)) / period
    v = (-xx * math.sin(a) + yy * math.cos(a)) / period
    d = np.hypot(u - np.round(u), v - np.round(v))
    t = np.clip((1 - L) * gain, 0, 1)
    return smooth(-0.04, 0.04, np.sqrt(t) * 0.62 - d)


POSTERS = {
    1: dict(paper=(0.96, 0.86, 0.36), ink=(24, 20, 22), acc=(214, 40, 50), ill="rat", top="LES RATS", top2="DE CALE",
            lines=["La Halle Hurlante", "CE SOIR 21 H", "Entrée à prix libre"]),
    2: dict(paper=(0.96, 0.72, 0.78), ink=(30, 20, 60), acc=(40, 110, 220), ill="gull", top="LE GRAND", top2="BOUCAN",
            lines=["Les Rats de Cale + les invités des îles", "SAMEDI 21 H", "La Halle Hurlante · Port-Boucan"]),
    3: dict(paper=(0.74, 0.9, 0.7), ink=(20, 40, 30), acc=(150, 60, 200), ill="mush", top="LES RATS", top2="DE CALE",
            lines=["Concert des champignons", "VENDREDI 21 H", "Limonades et sirops au bar"]),
    4: dict(paper=(0.95, 0.93, 0.86), ink=(26, 24, 30), acc=(240, 110, 30), ill="ship", top="RATS DE CALE", top2="EN CONCERT",
            lines=["La Halle Hurlante", "TOUS LES SOIRS 21 H", "Venez comme vous êtes !"]),
}


def _ill(kind, W, H, R):
    pa = Paint(W, H, K=1, bg=(255, 255, 255), seed=int(R.integers(1 << 30)))
    if kind == "rat":
        rat(pa, W * 0.47, H * 0.62, W / 420, crest=((150, 150, 150),), fur=(150, 150, 150), guitar_col=(90, 90, 90))
        for (x, y, s) in ((0.15, 0.25, 0.9), (0.85, 0.3, 1.0), (0.8, 0.75, 0.7)):
            note(pa, W * x, H * y, s * W / 420, (40, 40, 40), x > 0.5)
    elif kind == "gull":
        gull(pa, W * 0.5, H * 0.55, W / 760, ang=-6, bandana=(110, 110, 110), flap=-8)
        for k in range(5):
            bolt(pa, W * (0.12 + 0.19 * k), H * 0.9, W / 900, (60, 60, 60), (-1) ** k * 15)
    elif kind == "mush":
        for (x, h, w, c) in ((0.3, 0.42, 0.34, (120, 120, 120)), (0.66, 0.6, 0.46, (70, 70, 70)), (0.86, 0.3, 0.22, (150, 150, 150))):
            mushroom(pa, W * x, H * 0.95, H * h, W * w, c, spots=(255, 255, 255), stem=(225, 225, 225), R=R)
        for _ in range(16):
            sparkle(pa, R.uniform(0.05, 0.95) * W, R.uniform(0.05, 0.5) * H, R.uniform(5, 11), (40, 40, 40), ol=0)
    else:
        ship(pa, W * 0.5, H * 0.55, W / 760, hull=(90, 90, 90), name="")
        for (x, y, w) in ((0.25, 0.78, 0.5), (0.72, 0.8, 0.55), (0.5, 0.92, 0.8)):
            cloud(pa, W * x, H * y, W * w, W * w * 0.3, (235, 235, 235), R, ol=2)
    return np.clip(pa.rgb, 0, 1).mean(-1)


def affiche_concert(n):
    """Affiche sérigraphiée / photocopiée des Rats de Cale : deux encres (noir et une couleur) en
    trame, léger décalage de repérage, grain du papier, bouts de scotch."""
    P = POSTERS[n]
    R = rng(7590 + n)
    W, H = 1024, 1536
    paper = paper_bg(R, W, H, base=P["paper"], stains=0.25, edge=0.15)
    ink = np.array(P["ink"], np.float32) / 255
    acc = np.array(P["acc"], np.float32) / 255
    # illustration (au milieu), tramée
    iw, ih = 900, 760
    L = _ill(P["ill"], iw, ih, R)
    ox, oy = 62, 420
    Lf = np.ones((H, W), np.float32)
    Lf[oy:oy + ih, ox:ox + iw] = L
    dark = smooth(0.32, 0.22, Lf)
    mid = halftone(np.clip(Lf * 1.15, 0, 1), 9.0, 15.0) * (1 - dark) * (Lf < 0.97)
    # cadre et bandeaux d'accent
    acc_m = np.zeros((H, W), np.float32)
    acc_m[60:420, 40:W - 40] = 1.0
    acc_m = acc_m * (0.85 + 0.15 * halftone(np.full((H, W), 0.3, np.float32), 6.0, 45.0))
    t1 = tmask(W, H, P["top"], "cond", 180, (W / 2, 150), maxw=W - 140)
    t2 = tmask(W, H, P["top2"], "cond", 180, (W / 2, 315), maxw=W - 140)
    acc_m = acc_m * (1 - np.clip(t1 + t2, 0, 1))
    ink_m = dark
    acc_m2 = np.roll(np.roll(mid, 3, 0), -2, 1)
    lines = P["lines"]
    txt = tmask(W, H, lines[0], "serifi", 64, (W / 2, 1240), maxw=W - 120)
    big = tmask(W, H, lines[1], "black", 112, (W / 2, 1360), maxw=W - 180)
    low = tmask(W, H, lines[2], "semi", 48, (W / 2, 1460), maxw=W - 120)
    pill = np.zeros((H, W), np.float32)
    pill[1298:1424, 60:W - 60] = 1
    pill_ink = pill * (1 - big)
    col = paper.copy()
    col = mix(col, col * acc * 1.05, np.clip(acc_m + acc_m2 * 0.9, 0, 1) * 0.92)
    col = mix(col, ink, np.clip(ink_m + txt + low + pill_ink * 0.95, 0, 1) * 0.94)
    col = mix(col, np.minimum(acc * 1.2 + 0.1, 1), big * 0.95)
    # grain d'encre et taches de photocopie
    g = grain(R, max(W, H), 0.8)[:H, :W]
    col = col * (0.95 + 0.08 * g[..., None])
    sp = R.random((H, W)).astype(np.float32)
    col = mix(col, ink, (gblur((sp > 0.9993).astype(np.float32), 1.0) > 0.08) * 0.7)
    # scotch en haut
    for (x0, a) in ((90, -20), (W - 90, 20)):
        m = Image.new("L", (W, H), 0)
        ImageDraw.Draw(m).polygon(xform([(x0 - 70, 10), (x0 + 70, 10), (x0 + 70, 60), (x0 - 70, 60)], x0, 35, a), fill=255)
        tm = np.asarray(m, np.float32) / 255
        col = mix(col, C(0.95, 0.93, 0.82), tm * 0.55)
    save_rgb(down(col, 2), "affiche_concert_%d.png" % n)


def affiches():
    for n in POSTERS:
        affiche_concert(n)
    panneau_lisse()
    fanzine_couverture()


def panneau_lisse():
    """Panneau publicitaire de Lisse & Fils, tout lisse et tout gris : rendu fade du « Lisse-Center »
    (boîte grise, vitres, arbres en pot taillés en boule), slogan creux, petit astérisque comique."""
    R = rng(7599)
    pa = Paint(1024, 512, K=2, bg=(200, 204, 210), seed=7599)
    pa.brush[:] = 1.0  # tout est lisse chez Lisse
    bg_grad(pa, (176, 196, 214), (226, 230, 234))
    pa.glow(760, 120, 200, (255, 255, 255), 0.3)
    # sol et bâtiment
    pa.rect(-10, 380, 1034, 520, (150, 154, 160), grad=((160, 164, 170), (120, 124, 130), 90), shade=0, ol=0)
    shape(pa, [(470, 380), (470, 180), (980, 180), (980, 380)], (178, 182, 190), ol=1.4, shade=0.3, depth=10, inkc=(90, 94, 100))
    shape(pa, [(440, 186), (1010, 186), (1010, 166), (440, 166)], (150, 154, 160), ol=1.4, shade=0.2, inkc=(90, 94, 100))
    shape(pa, [(490, 360), (490, 240), (960, 240), (960, 360)], (120, 160, 196), ol=1.2, shade=0, inkc=(90, 94, 100),
          grad=((150, 190, 220), (90, 130, 170), 60))
    for k in range(1, 9):
        pa.line([(490 + k * 52, 240), (490 + k * 52, 360)], (200, 206, 214), 2)
    for k in range(5):
        pa.line([(500 + k * 90, 360), (560 + k * 90, 240)], (220, 236, 250), 3, alpha=0.4)
    ptext(pa, (725, 210), "LISSE-CENTER", "light", 28, (90, 94, 104), spacing=6)
    for x in (430, 520, 620, 830, 930, 1000):
        shape(pa, [(x - 12, 400), (x + 12, 400), (x + 9, 378), (x - 9, 378)], (110, 114, 120), ol=1, shade=0.3, inkc=(80, 80, 86))
        stroke(pa, [(x, 380), (x, 350)], 4, (100, 90, 80), ol=0.8)
        shape(pa, rell(x, 338, 20, 20), (110, 150, 120), ol=1, shade=0.6, inkc=(80, 90, 86))
    # le cadre de texte
    shape(pa, [(30, 30), (420, 30), (420, 470), (30, 470)], (246, 247, 248), ol=1.2, shade=0.1, inkc=(150, 154, 160), tex=False)
    ptext(pa, (225, 80), "BIENTÔT ICI :", "light", 30, (110, 116, 126), spacing=3)
    ptext(pa, (225, 150), "LE LISSE-", "black", 58, (64, 70, 82))
    ptext(pa, (225, 212), "CENTER", "black", 70, (64, 70, 82), spacing=4)
    pa.rect(70, 252, 380, 255, (180, 186, 196), shade=0, ol=0)
    ptext(pa, (225, 290), "Galerie marchande", "reg", 30, (96, 102, 114))
    ptext(pa, (225, 328), "éternelle*", "reg", 30, (96, 102, 114))
    # le logo
    shape(pa, rell(110, 410, 34, 34), (90, 96, 108), ol=0, shade=0.4)
    ptext(pa, (110, 412), "L", "black", 40, (240, 242, 246))
    ptext(pa, (160, 400), "LISSE & FILS", "bold", 22, (80, 86, 98), anchor="lm")
    ptext(pa, (160, 426), "promoteurs depuis toujours", "light", 15, (120, 126, 136), anchor="lm")
    ptext(pa, (720, 432), "* Ouvert tous les jours, même ceux qui n'existent pas.", "reg", 13, (60, 64, 72))
    ptext(pa, (720, 452), "Parking de 40 000 places. Sourire obligatoire.", "reg", 13, (60, 64, 72))
    rgb, cov = pa.result()
    H, W = rgb.shape[:2]
    # cadre métallique, reflet glacé, un petit autocollant rebelle
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    dedge = np.minimum(np.minimum(xx, W - 1 - xx), np.minimum(yy, H - 1 - yy))
    frame = dedge < 12
    col = rgb.copy()
    col = mix(col, C(0.55, 0.57, 0.6) * (0.9 + 0.1 * (yy / H))[..., None], frame.astype(np.float32))
    col = col * (1 - 0.35 * np.exp(-((dedge - 12) / 2.0) ** 2))[..., None]
    gloss = np.exp(-(((xx - yy * 0.9) - 600) / 90.0) ** 2) * 0.12
    col = col + gloss[..., None]
    pa2 = Paint(W, H, K=2, bg=(0, 0, 0), seed=1)
    shape(pa2, rell(980, 60, 26, 26), (240, 60, 70), ol=1.6, shade=0.2)
    ptext(pa2, (980, 61), "BOUCAN", "black", 9, (255, 255, 255), rot=-12)
    r2, c2 = pa2.result()
    col = mix(col, r2, c2)
    save_rgb(col, "panneau_lisse.png")


def fanzine_couverture():
    """Couverture du fanzine « Le Boucanier » : photocopie noir et blanc, titre en lettres découpées,
    dessin du rat tramé, gros titres tapés à la machine, une touche de rose (risographie)."""
    R = rng(7598)
    W, H = 1024, 1536
    paper = C(0.95, 0.94, 0.91) * (0.97 + 0.04 * grain(R, max(W, H), 0.8)[:H, :W][..., None])
    ink = C(0.08, 0.08, 0.09)
    pink = C(0.95, 0.35, 0.6)
    col = paper.copy()
    ink_m = np.zeros((H, W), np.float32)
    pink_m = np.zeros((H, W), np.float32)
    # titre en lettres découpées
    title = "LE BOUCANIER"
    kinds = ["black", "serif", "cond", "type", "pop", "black", "serifi", "cond", "black", "type", "pop", "serif"]
    x = 50
    for i, ch in enumerate(title):
        if ch == " ":
            x += 34
            continue
        k = kinds[i % len(kinds)]
        size = int(R.uniform(84, 104))
        f = ff(k, size)
        w = ImageDraw.Draw(Image.new("L", (8, 8))).textlength(ch, font=f)
        bw = w + 18
        cy = 160 + R.uniform(-12, 12)
        inv = (i % 3 == 1)
        box = Image.new("L", (W, H), 0)
        ImageDraw.Draw(box).polygon(xform([(x, cy - 62), (x + bw, cy - 62), (x + bw, cy + 62), (x, cy + 62)], x + bw / 2, cy, R.uniform(-6, 6)), fill=255)
        bm = np.asarray(box, np.float32) / 255
        tm = tmask(W, H, ch, k, size, (x + bw / 2, cy), rot=R.uniform(-8, 8))
        if inv:
            ink_m = np.maximum(ink_m, bm * (1 - tm))
        elif i % 3 == 2:
            pink_m = np.maximum(pink_m, bm * (1 - tm))
            ink_m = np.maximum(ink_m, tm * bm)
        else:
            ink_m = np.maximum(ink_m, tm)
            ink_m = np.maximum(ink_m, np.clip(bm - np.asarray(box.filter(ImageFilter.MinFilter(7)), np.float32) / 255, 0, 1))
        x += bw + 2
    sub = tmask(W, H, "fanzine de Port-Boucan · n° 12 · prix libre", "type", 34, (W / 2, 300), maxw=W - 120)
    ink_m = np.maximum(ink_m, sub)
    # dessin tramé dans un cadre déchiré
    iw, ih = 620, 620
    L = _ill("rat", iw, ih, R)
    ox, oy = 50, 360
    Lf = np.ones((H, W), np.float32)
    Lf[oy:oy + ih, ox:ox + iw] = L
    ink_m = np.maximum(ink_m, smooth(0.35, 0.25, Lf))
    ink_m = np.maximum(ink_m, halftone(np.clip(Lf * 1.1, 0, 1), 8.0, 45.0) * (Lf < 0.97))
    fr = np.zeros((H, W), np.float32)
    fr[oy - 10:oy + ih + 10, ox - 10:ox + iw + 10] = 1
    fr[oy - 4:oy + ih + 4, ox - 4:ox + iw + 4] = 0
    ink_m = np.maximum(ink_m, fr)
    # colonne de titres
    heads = ["SPÉCIAL", "GRAND", "BOUCAN !", "", "La soupe", "de Lentille :", "la recette", "", "Réparer", "sa chambre", "à air", "", "Champignons :", "on regarde,", "on ne mange", "pas !"]
    y = 400
    for hl in heads:
        if hl:
            k = "black" if hl.isupper() else "type"
            sz = 46 if hl.isupper() else 32
            ink_m = np.maximum(ink_m, tmask(W, H, hl, k, sz, (700, y), anchor="lm", maxw=300))
        y += 44 if hl else 22
    pink_m = np.maximum(pink_m, np.where((np.mgrid[0:H, 0:W][0] > 370) & (np.mgrid[0:H, 0:W][0] < 520) & (np.mgrid[0:H, 0:W][1] > 690) & (np.mgrid[0:H, 0:W][1] < 990), 0.85, 0))
    # bas de page
    low = ["Assemblée jeudi à la Conserverie : tout le monde a la parole.", "Gratuiterie : on donne, on prend, on partage.",
           "Atelier vélo ouvert tous les après-midi.", "Fais ton propre fanzine : l'imprimerie te prête la machine !"]
    for i, t in enumerate(low):
        ink_m = np.maximum(ink_m, tmask(W, H, t, "type", 26, (60, 1080 + i * 44), anchor="lm", maxw=W - 120))
    star = Image.new("L", (W, H), 0)
    ImageDraw.Draw(star).polygon(star_pts(860, 1340, 120, 12, 0.72), fill=255)
    sm = np.asarray(star, np.float32) / 255
    pink_m = np.maximum(pink_m, sm)
    ink_m = np.maximum(ink_m, tmask(W, H, "GRATUIT", "black", 40, (860, 1320), rot=12) * sm)
    ink_m = np.maximum(ink_m, tmask(W, H, "ou presque", "type", 24, (860, 1366), rot=12) * sm)
    ink_m = np.maximum(ink_m, tmask(W, H, "Fait main, à la colle et aux ciseaux.", "hand", 46, (60, 1360), anchor="lm"))
    # photocopie : bruit de toner, bords sombres, décalage du rose
    sp = R.random((H, W)).astype(np.float32)
    tone = gblur((sp > 0.997).astype(np.float32), 0.8) > 0.12
    pink_m = np.roll(np.roll(pink_m, 4, 0), 3, 1) * (0.88 + 0.12 * grain(R, max(W, H), 1.0)[:H, :W])
    col = mix(col, col * pink, np.clip(pink_m, 0, 1) * 0.9)
    col = mix(col, ink, np.clip(ink_m * (0.9 + 0.1 * grain(R, max(W, H), 0.7)[:H, :W]) + tone * 0.6, 0, 1))
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    dedge = np.minimum(np.minimum(xx, W - 1 - xx), np.minimum(yy, H - 1 - yy))
    col = col * (1 - 0.35 * np.exp(-dedge / 14.0))[..., None]
    img = to_img(col).rotate(-0.8, resample=Image.BICUBIC, fillcolor=(236, 234, 228))
    save_rgb(img.resize((512, 768), Image.LANCZOS), "fanzine_couverture.png")


# =================================================================== enseignes (512 x 256)

def _sign_base(kind, R, W=1024, H=512):
    """Fonds d'enseigne (2x) : tôle peinte, planches peintes, panneau de récup, plaque lisse, brique."""
    n = tn(R, W, (4, 8, 16, 32), 0.6, H=H)
    gr = grain(R, W, 0.6, H=H)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    if kind[0] == "metal":
        c = np.array(kind[1], np.float32) / 255
        col = c * (0.9 + 0.12 * n[..., None]) * (0.94 + 0.1 * gr[..., None])
        dedge = np.minimum(np.minimum(xx, W - 1 - xx), np.minimum(yy, H - 1 - yy))
        rust = smooth(0.55, 0.62, np.exp(-dedge / 26.0) * 0.6 + tn(R, W, (16, 32, 64), 0.6, H=H) * 0.5)
        col = mix(col, rust_palette(n, gr) * (0.8 + 0.4 * gr[..., None]), rust * 0.9)
        run = np.clip(run_down(rust * (yy < H * 0.4), 60.0), 0, 1)
        col = mix(col, C(0.4, 0.2, 0.1), run * 0.35)
        for (x, y) in ((24, 24), (W - 24, 24), (24, H - 24), (W - 24, H - 24)):
            dd = np.hypot(xx - x, yy - y)
            col = mix(col, C(0.55, 0.53, 0.5), (dd < 9).astype(np.float32))
            col = col * (1 - 0.4 * np.exp(-((dd - 10) / 2.5) ** 2))[..., None]
        return col
    if kind[0] == "wood":
        cols = [np.array(c, np.float32) / 255 for c in kind[1]]
        nb = 4
        bh = H / nb
        bi = np.floor(yy / bh).astype(np.int32)
        fibx = tn(R, W, (4, 8, 16, 32, 64, 128), 0.9, H=H, oy=(16, 32, 64, 128, 256, 512))
        col = np.zeros((H, W, 3), np.float32)
        for k in range(nb):
            c = cols[k % len(cols)]
            col[bi == k] = c
        col = col * (0.85 + 0.25 * fibx[..., None]) * (0.94 + 0.1 * gr[..., None])
        pm, pedge = peel_mask(R, W, 0.95, H=H, scale=(32, 64, 128, 256), sharp=0.03)
        wood = mix(C(0.45, 0.36, 0.26), C(0.6, 0.5, 0.38), fibx)
        col = mix(wood, col, pm)
        seam = np.exp(-(np.minimum(np.mod(yy, bh), bh - np.mod(yy, bh)) / 2.0) ** 2)
        col = col * (1 - 0.6 * seam[..., None])
        return col
    if kind[0] == "smooth":
        c1, c2 = (np.array(c, np.float32) / 255 for c in kind[1])
        t = yy / H
        col = mix(c1, c2, t)
        gloss = np.exp(-(((xx * 0.4 - yy) - 120) / 60.0) ** 2) * 0.08
        return col + gloss[..., None]
    if kind[0] == "brick":
        bcol, bh, mortar, face, inv = brick_surface(R, W, H, 22, 18, "stretcher", jw=3.0, soot=0.4, efflo=0.45)
        return bake(bcol, bh, 4.0, k=0.35, ao=0.3, ao_r=3)
    raise ValueError(kind)


def em_halle(pa, cx, cy, s):
    shape(pa, rell(cx, cy, 70 * s, 70 * s), (40, 38, 46), ol=3, shade=0.5)
    shape(pa, rell(cx, cy, 48 * s, 48 * s), (90, 88, 100), ol=2, shade=0.7)
    shape(pa, rell(cx, cy, 18 * s, 18 * s), (20, 20, 24), ol=1.6, shade=0.4)
    bolt(pa, cx - 70 * s, cy - 40 * s, 0.7 * s, (255, 220, 40), -20)
    bolt(pa, cx + 74 * s, cy + 30 * s, 0.6 * s, (255, 220, 40), 20)


def em_cantine(pa, cx, cy, s):
    for k in range(3):
        x = cx - 30 * s + k * 30 * s
        pa.line([(x + math.sin(t * 6) * 7 * s, cy - 20 * s - t * 70 * s) for t in np.linspace(0, 1, 16)], (250, 250, 250), 5 * s, alpha=0.9)
    shape(pa, chaikin([(cx - 80 * s, cy - 10 * s), (cx + 80 * s, cy - 10 * s), (cx + 60 * s, cy + 50 * s), (cx - 60 * s, cy + 50 * s)], 2), (240, 120, 50), ol=3, shade=0.6)
    shape(pa, rell(cx, cy - 10 * s, 80 * s, 12 * s), (250, 200, 80), ol=2, shade=0.3)
    stroke(pa, [(cx + 30 * s, cy - 20 * s), (cx + 70 * s, cy - 80 * s), (cx + 80 * s, cy - 92 * s)], 10 * s, (200, 200, 210), ol=2)


def em_gratuiterie(pa, cx, cy, s):
    shape(pa, [(cx - 70 * s, cy - 10 * s), (cx + 70 * s, cy - 10 * s), (cx + 70 * s, cy + 60 * s), (cx - 70 * s, cy + 60 * s)], (200, 150, 90), ol=3, shade=0.5)
    shape(pa, [(cx - 70 * s, cy - 10 * s), (cx - 100 * s, cy - 40 * s), (cx - 30 * s, cy - 40 * s), (cx, cy - 10 * s)], (220, 170, 110), ol=2.4, shade=0.4)
    shape(pa, [(cx + 70 * s, cy - 10 * s), (cx + 100 * s, cy - 40 * s), (cx + 30 * s, cy - 40 * s), (cx, cy - 10 * s)], (220, 170, 110), ol=2.4, shade=0.4)
    shape(pa, heart_pts(cx, cy - 60 * s, 2.6 * s), (230, 50, 80), ol=2.6, shade=0.6)


def em_velo(pa, cx, cy, s):
    for wx in (cx - 60 * s, cx + 60 * s):
        shape(pa, rell(wx, cy + 20 * s, 42 * s, 42 * s), (30, 30, 34), ol=0, shade=0)
        shape(pa, rell(wx, cy + 20 * s, 34 * s, 34 * s), (250, 220, 60), ol=0, shade=0, tex=False)
        for k in range(8):
            a = k * math.pi / 8
            pa.line([(wx - math.cos(a) * 33 * s, cy + 20 * s - math.sin(a) * 33 * s), (wx + math.cos(a) * 33 * s, cy + 20 * s + math.sin(a) * 33 * s)], (60, 60, 64), 1.6 * s)
    fr = (240, 60, 70)
    for (a, b) in (((cx - 60, cy + 20), (cx - 5, cy + 20)), ((cx - 5, cy + 20), (cx + 30, cy - 30)), ((cx + 30, cy - 30), (cx - 30, cy - 30)),
                   ((cx - 30, cy - 30), (cx - 60, cy + 20)), ((cx - 30, cy - 30), (cx - 5, cy + 20)), ((cx + 30, cy - 30), (cx + 60, cy + 20)),
                   ((cx + 30, cy - 30), (cx + 22, cy - 52)), ((cx - 30, cy - 30), (cx - 34, cy - 44))):
        stroke(pa, [(cx + (a[0] - cx) * s, cy + (a[1] - cy) * s), (cx + (b[0] - cx) * s, cy + (b[1] - cy) * s)], 8 * s, fr, ol=1.6)
    stroke(pa, [(cx + 12 * s, cy - 56 * s), (cx + 36 * s, cy - 50 * s)], 7 * s, (40, 40, 44), ol=1.4)
    shape(pa, rell(cx - 36 * s, cy - 46 * s, 16 * s, 5 * s), (40, 40, 44), ol=1.4)


def em_imprimerie(pa, cx, cy, s):
    shape(pa, [(cx - 60 * s, cy - 70 * s), (cx + 40 * s, cy - 70 * s), (cx + 60 * s, cy - 50 * s), (cx + 60 * s, cy + 70 * s), (cx - 60 * s, cy + 70 * s)],
          (246, 244, 236), ol=3, shade=0.3)
    for k in range(5):
        pa.line([(cx - 44 * s, cy - 30 * s + k * 18 * s), (cx + (40 - (k % 2) * 30) * s, cy - 30 * s + k * 18 * s)], (60, 60, 70), 3 * s)
    shape(pa, rell(cx - 20 * s, cy - 50 * s, 12 * s, 12 * s), (240, 70, 140), ol=1.6, shade=0.3)
    drop = chaikin([(cx + 70 * s, cy - 10 * s), (cx + 96 * s, cy + 30 * s), (cx + 96 * s, cy + 50 * s), (cx + 70 * s, cy + 66 * s), (cx + 44 * s, cy + 50 * s), (cx + 44 * s, cy + 30 * s)], 2)
    shape(pa, drop, (40, 120, 230), ol=2.6, shade=0.6)


def em_radio(pa, cx, cy, s):
    stroke(pa, [(cx + 30 * s, cy - 40 * s), (cx + 66 * s, cy - 100 * s)], 5 * s, (180, 180, 190), ol=1.4)
    shape(pa, rell(cx + 66 * s, cy - 100 * s, 7 * s, 7 * s), (240, 60, 70), ol=1.6)
    for k in range(3):
        r = (18 + k * 14) * s
        pa.line(ellp(cx + 66 * s, cy - 100 * s, r, r, -60, 30, 16), (120, 230, 255), 3.4 * s)
    shape(pa, chaikin([(cx - 80 * s, cy - 40 * s), (cx + 80 * s, cy - 40 * s), (cx + 80 * s, cy + 56 * s), (cx - 80 * s, cy + 56 * s)], 1), (200, 70, 50), ol=3, shade=0.5)
    shape(pa, rell(cx - 32 * s, cy + 8 * s, 32 * s, 32 * s), (230, 220, 190), ol=2, shade=0.4)
    for k in range(5):
        pa.line([(cx - 56 * s, cy - 12 * s + k * 10 * s), (cx - 8 * s, cy - 12 * s + k * 10 * s)], (120, 100, 80), 2 * s)
    shape(pa, [(cx + 14 * s, cy - 24 * s), (cx + 66 * s, cy - 24 * s), (cx + 66 * s, cy + 4 * s), (cx + 14 * s, cy + 4 * s)], (250, 220, 120), ol=2, shade=0)
    pa.line([(cx + 40 * s, cy - 22 * s), (cx + 40 * s, cy + 2 * s)], (220, 40, 40), 2.4 * s)
    for x in (cx + 26 * s, cx + 54 * s):
        shape(pa, rell(x, cy + 30 * s, 9 * s, 9 * s), (60, 50, 50), ol=1.6, shade=0.5)


def em_lisse(pa, cx, cy, s):
    shape(pa, rell(cx, cy, 64 * s, 64 * s), (70, 76, 88), ol=0, shade=0.5, tex=False)
    ptext(pa, (cx, cy + 4 * s), "L", "black", 80 * s, (240, 242, 246))


def em_soins(pa, cx, cy, s):
    shape(pa, heart_pts(cx, cy + 4 * s, 4.4 * s), (70, 190, 130), ol=3, shade=0.6)
    for ang in (35, -35):
        band = xform([(cx - 62 * s, cy - 14 * s), (cx + 62 * s, cy - 14 * s), (cx + 62 * s, cy + 14 * s), (cx - 62 * s, cy + 14 * s)], cx, cy, ang)
        shape(pa, band, (250, 226, 190), ol=2, shade=0.3)
    shape(pa, xform([(cx - 16 * s, cy - 12 * s), (cx + 16 * s, cy - 12 * s), (cx + 16 * s, cy + 12 * s), (cx - 16 * s, cy + 12 * s)], cx, cy, 35), (240, 200, 170), ol=1.4, shade=0.2)
    for k in range(4):
        shape(pa, rell(cx - 6 * s + (k % 2) * 12 * s, cy - 5 * s + (k // 2) * 10 * s, 1.8 * s, 1.8 * s), (200, 160, 130), ol=0, shade=0)


ENSEIGNES = {
    "halle": dict(base=("metal", (28, 26, 32)), em=em_halle, title="La Halle Hurlante", tf="black", tc=(255, 214, 40), sc=(220, 40, 60),
                  sub="Concerts tous les soirs · 21 h", subc=(240, 240, 240)),
    "cantine": dict(base=("wood", ((60, 120, 100), (50, 110, 92))), em=em_cantine, title="Cantine à prix libre", tf="pop", tc=(255, 240, 200),
                    sc=(30, 40, 36), sub="Soupe du jour · paie ce que tu peux", subc=(255, 214, 120)),
    "gratuiterie": dict(base=("wood", ((240, 190, 60), (230, 110, 140), (90, 170, 220), (120, 190, 100))), em=em_gratuiterie, title="Gratuiterie",
                        tf="black", tc=(255, 255, 255), sc=(40, 30, 40), sub="On donne · on prend · on partage", subc=(40, 30, 40), sub_stroke=0),
    "velo": dict(base=("metal", (40, 110, 170)), em=em_velo, title="Atelier vélo", tf="black", tc=(255, 255, 255), sc=(20, 30, 50),
                 sub="Répare ton vélo avec nous", subc=(255, 230, 120)),
    "imprimerie": dict(base=("wood", ((236, 230, 214), (226, 220, 204))), em=em_imprimerie, title="Imprimerie du Boucanier", tf="type", tc=(30, 30, 36),
                       sc=None, sub="Fanzines · affiches · sérigraphie", subc=(200, 40, 110), sub_stroke=0),
    "radio": dict(base=("metal", (30, 40, 70)), em=em_radio, title="Radio Boucan", tf="black", tc=(120, 230, 255), sc=(10, 20, 40),
                  sub="98.7", subc=(255, 120, 200), sub_size=58, glow=(80, 200, 255)),
    "lisse": dict(base=("smooth", ((232, 234, 238), (196, 200, 206))), em=em_lisse, title="LISSE & FILS", tf="bold", tc=(64, 70, 82), sc=None,
                  sub="On rase. On bâtit. On encaisse.", subc=(110, 116, 126), sub_stroke=0, sub_font="light", spacing=6),
    "soins": dict(base=("wood", ((246, 244, 238), (238, 236, 230))), em=em_soins, title="Point Soins", tf="pop", tc=(40, 140, 100), sc=None,
                  sub="Pansements, câlins et conseils", subc=(80, 80, 90), sub_stroke=0),
}


def enseigne(key):
    """Enseigne peinte (512 x 256) : fond de matière, emblème à gauche, titre et sous-titre."""
    if key == "conserverie":
        return enseigne_conserverie()
    E = ENSEIGNES[key]
    R = rng(7600 + sorted(list(ENSEIGNES) + ["conserverie"]).index(key))
    W, H = 512, 256
    pa = Paint(W, H, K=2, bg=(0, 0, 0), seed=7600)
    pa.rgb[:] = _sign_base(E["base"], R)
    if E["base"][0] == "smooth":
        pa.brush[:] = 1.0
    E["em"](pa, 88, 128, 0.68)
    tx = 340
    sp = E.get("spacing", 0)
    words = E["title"]
    size = fit_size(words, E["tf"], 64, 300, sp)
    if size < 44 and " " in words:
        parts = words.split(" ")
        cut = max(range(1, len(parts)), key=lambda i: -abs(len(" ".join(parts[:i])) - len(" ".join(parts[i:]))))
        l1, l2 = " ".join(parts[:cut]), " ".join(parts[cut:])
        size = min(fit_size(l1, E["tf"], 60, 300, sp), fit_size(l2, E["tf"], 60, 300, sp))
        ys = [(l1, 82), (l2, 82 + size * 1.05)]
    else:
        ys = [(words, 104)]
    if E.get("glow"):
        for s_, y in ys:
            pa.glow(tx, y, 150, E["glow"], 0.25)
    for s_, y in ys:
        ptext(pa, (tx, y), s_, E["tf"], size, E["tc"], stroke_w=4 if E["sc"] else 0, stroke_col=E["sc"], spacing=sp,
              shadow=(3, 4, 0.45) if E["sc"] else None)
    sy = ys[-1][1] + size * 0.62 + 30
    ss = E.get("sub_size", 26)
    sf = E.get("sub_font", "semi" if ss < 40 else "black")
    ptext(pa, (tx, sy), E["sub"], sf, fit_size(E["sub"], sf, ss, 310), E["subc"], stroke_w=2 if E.get("sub_stroke", 1) else 0, stroke_col=(20, 20, 24))
    rgb, cov = pa.result()
    if E["base"][0] != "smooth":
        g = grain(R, W, 0.7, H=H)
        rgb = rgb * (0.95 + 0.08 * g[..., None])
        keep, pedge = peel_mask(R, W, 0.992, H=H, scale=(32, 64, 128), sharp=0.02)
        under = _sign_base(E["base"], R)
        under = down(under, 2) * 0.8 + C(0.1, 0.08, 0.06)
        rgb = mix(under, rgb, keep)
    save_rgb(rgb, "enseigne_%s.png" % key)


def enseigne_conserverie():
    """Lettrage fantôme peint sur la brique : « Conserverie Sardinière », vieux filets, une boîte de
    sardines, tout pâli et lessivé par un siècle de pluie."""
    R = rng(7609)
    W, H = 512, 256
    pa = Paint(W, H, K=2, bg=(0, 0, 0), seed=7609)
    shape(pa, [(14, 14), (498, 14), (498, 242), (14, 242)], (34, 50, 72), ol=0, shade=0)
    pa.outline([(24, 24), (488, 24), (488, 232), (24, 232)], 3, (236, 226, 200))
    ptext(pa, (256, 70), "CONSERVERIE", "serif", 54, (240, 228, 196), spacing=3)
    ptext(pa, (256, 132), "Sardinière", "serifi", 50, (236, 190, 80))
    pa.line([(70, 166), (442, 166)], (236, 226, 200), 2.2)
    ptext(pa, (256, 196), "SARDINES À L'HUILE · FONDÉE EN 1898", "serif", 17, (240, 228, 196), spacing=1)
    for x in (58, 454):
        shape(pa, rell(x, 128, 28, 18), (190, 196, 200), ol=1.4, shade=0.2, inkc=(236, 226, 200))
        shape(pa, chaikin([(x - 20, 128), (x - 4, 118), (x + 16, 124), (x + 22, 128), (x + 16, 132), (x - 4, 138)], 1), (120, 150, 180), ol=1.2, shade=0, inkc=(236, 226, 200))
    rgb, cov = pa.result()
    base = _sign_base(("brick",), R)
    base = down(base, 2)
    big = max(W, H)
    wash = tn(R, big, (4, 8, 16, 32, 64), 0.6)[:H, :W]
    keep, pedge = peel_mask(R, W, 0.82, H=H, scale=(16, 32, 64, 128), sharp=0.05)
    st = vstreak(R, W, (16, 32, 64, 128), 0.6, 6, H=H)
    alpha = cov * keep * (0.45 + 0.35 * wash) * (1 - 0.4 * smooth(0.5, 0.85, st))
    lum = base.mean(-1, keepdims=True)
    paint = rgb * (0.6 + 0.6 * lum / max(1e-3, lum.mean()))
    col = mix(base, paint * 0.9 + 0.08, alpha)
    save_rgb(col, "enseigne_conserverie.png")


def enseignes():
    for k in list(ENSEIGNES) + ["conserverie"]:
        enseigne(k)


# =================================================================== icônes (128 px)

ICON_NAMES_V75 = ["affiche_concert", "guitare_rouille", "ampli", "baguettes", "champi_ressort", "champi_lune", "champi_babil",
                  "champi_arcenciel", "champi_geant", "panier_legumes", "pieces_velo", "antenne_radio", "bombe_peinture", "fanzine",
                  "badge_usine", "plans_lisse", "soupe_prix_libre", "limonade_boucan", "sirop_menthe", "boulon", "ressort", "patch_rat",
                  "os_sardine", "bail_collectif", "cle_baleine"]


def ico_save(img, name):
    """Cerné et ombré comme les autres icônes (generate_items_v28), puis réduit à 128 px.
    N'écrit que les icônes de la V75 (aucune icône plus ancienne n'est touchée)."""
    import generate_items_v28 as icons
    if name not in ICON_NAMES_V75:
        sys.exit("icône inconnue : " + name)
    p = ITEMS / (name + ".png")
    img2 = icons.shadow(icons.outline(img))
    img2.resize((128, 128), Image.LANCZOS).save(p, optimize=True)
    _log(p)


def T(R, oct_=(16, 32, 64, 128), k=0.22):
    return (1 - k / 2) + k * tn(R, IS, oct_, 0.6)


def ipoly(img, pts, col, depth=12, gloss=0.4, tex=None, alpha=1.0, sm=0):
    if sm:
        pts = chaikin(pts, sm)
    return vol(img, lambda d: d.polygon(pts, fill=255), col, depth=depth, gloss=gloss, tex=tex, alpha=alpha)


def iell(img, cx, cy, rx, ry, col, depth=12, gloss=0.4, tex=None, alpha=1.0, ang=0.0):
    return ipoly(img, rell(cx, cy, rx, ry, ang, 64), col, depth, gloss, tex, alpha)


def iline(img, pts, col, w):
    ImageDraw.Draw(img).line(pts, fill=col + (255,) if len(col) == 3 else col, width=int(w), joint="curve")


def itext(img, xy, s, kind, size, col, rot=0.0, anchor="mm"):
    tmp = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    ImageDraw.Draw(tmp).text(xy, s, font=ff(kind, size), fill=col + (255,), anchor=anchor)
    if rot:
        tmp = tmp.rotate(rot, center=xy, resample=Image.BICUBIC)
    img.alpha_composite(tmp)


def ic_affiche_concert():
    img = canvas_i()
    R = rng(7701)
    page = xform([(110, 50), (402, 50), (402, 470), (110, 470)], 256, 260, -6)
    ipoly(img, page, (244, 214, 80), depth=10, gloss=0.2, tex=T(R, (8, 16, 32, 64), 0.2))
    ipoly(img, xform([(126, 66), (386, 66), (386, 176), (126, 176)], 256, 260, -6), (214, 40, 50), depth=4, gloss=0.2)
    itext(img, (256, 100), "RATS", "cond", 56, (250, 230, 120), rot=6)
    itext(img, (256, 150), "DE CALE", "cond", 44, (250, 230, 120), rot=6)
    # tête de rat à crête (silhouette noire)
    ink = (36, 32, 38)
    iell(img, 214, 260, 32, 34, ink, depth=4, gloss=0.1)
    iell(img, 214, 260, 18, 20, (214, 40, 50), depth=2, gloss=0.1)
    ipoly(img, chaikin([(220, 280), (250, 240), (300, 262), (360, 300), (350, 318), (300, 330), (240, 336)], 2), ink, depth=4, gloss=0.1)
    iell(img, 360, 308, 11, 10, (214, 40, 50), depth=2)
    iell(img, 290, 282, 9, 10, (244, 214, 80), depth=1)
    for k in range(5):
        x = 238 + k * 15
        ipoly(img, [(x - 8, 262 - k * 2), (x - 14 + k * 2, 196 - abs(k - 2) * -6), (x + 8, 258 - k * 2)], (214, 40, 50), depth=2, gloss=0.1)
    itext(img, (256, 412), "21 H", "black", 54, (30, 28, 30), rot=6)
    for (x, y) in ((140, 56), (372, 44)):
        ipoly(img, xform([(x - 34, y - 12), (x + 34, y - 12), (x + 34, y + 12), (x - 34, y + 12)], x, y, 15 if x > 200 else -15), (240, 236, 220), depth=3, gloss=0.3, alpha=0.8)
    ico_save(img, "affiche_concert")


def ic_guitare_rouille():
    img = canvas_i()
    R = rng(7702)
    a = -48

    def P(pts):
        return xform([(256 + x, 256 + y) for x, y in pts], 256, 256, a)
    ipoly(img, P([(10, -14), (230, -12), (230, 12), (10, 14)]), (150, 96, 54), depth=6, gloss=0.4, tex=T(R))
    ipoly(img, P([(226, -24), (290, -30), (300, 0), (290, 28), (226, 22)]), (40, 34, 36), depth=6, gloss=0.5)
    body = chaikin([(-190, -20), (-170, -92), (-100, -104), (-40, -76), (10, -96), (60, -74), (50, -16), (70, 36), (30, 96), (-70, 108), (-170, 84)], 3)
    m = ipoly(img, P(body), (190, 50, 44), depth=26, gloss=1.0, tex=T(R, (16, 32, 64, 128), 0.3))
    ipoly(img, P(chaikin([(-110, 16), (-60, -40), (0, -36), (8, 20), (-30, 70), (-100, 70)], 2)), (244, 238, 226), depth=6, gloss=0.5)
    # rouille et autocollants
    rr = (R.random((IS, IS)) < 0.006).astype(np.float32)
    rust = np.clip(gblur(rr, 6) * 60, 0, 1) * m * smooth(0.5, 0.7, tn(R, IS, (8, 16, 32), 0.6))
    arr = np.asarray(img, np.float32) / 255
    rgb = mix(arr[..., :3], C(0.6, 0.3, 0.12), rust * 0.8)
    img.paste(Image.fromarray((np.dstack([rgb, arr[..., 3]]) * 255 + 0.5).astype(np.uint8), "RGBA"))
    d = ImageDraw.Draw(img)
    for k in (-6, -2, 2, 6):
        d.line(P([(-100, k), (296, k * 0.5)]), fill=(236, 236, 236, 255), width=2)
    for fx in range(30, 230, 26):
        d.line(P([(fx, -12), (fx, 12)]), fill=(220, 210, 190, 255), width=3)
    for (px, py) in ((-60, -10), (-36, 24)):
        ipoly(img, P([(px - 14, py - 7), (px + 14, py - 7), (px + 14, py + 7), (px - 14, py + 7)]), (40, 40, 44), depth=3)
    cx, cy = P([(-140, 30)])[0]
    ipoly(img, star_pts(cx, cy, 30, 5, 0.45, -90), (250, 210, 60), depth=4, gloss=0.4)
    cx, cy = P([(-130, -50)])[0]
    iell(img, cx, cy, 22, 22, (60, 160, 230), depth=4, gloss=0.4)
    itext(img, (cx, cy), "G", "black", 26, (255, 255, 255))
    ico_save(img, "guitare_rouille")


def ic_ampli():
    img = canvas_i()
    R = rng(7703)
    ipoly(img, [(80, 120), (432, 120), (432, 460), (80, 460)], (44, 40, 46), depth=16, gloss=0.4, tex=T(R, (32, 64, 128), 0.3))
    ipoly(img, [(96, 136), (416, 136), (416, 200), (96, 200)], (210, 190, 150), depth=6, gloss=0.5)
    for k in range(6):
        iell(img, 130 + k * 50, 168, 11, 11, (40, 40, 44), depth=4, gloss=1.0)
    ipoly(img, [(100, 216), (412, 216), (412, 444), (100, 444)], (90, 80, 70), depth=8, gloss=0.2, tex=T(R, (64, 128, 256), 0.4))
    d = ImageDraw.Draw(img)
    for k in range(0, 230, 10):
        d.line([(100, 216 + k), (412, 216 + k)], fill=(70, 62, 54, 255), width=2)
    iell(img, 256, 330, 84, 84, (60, 56, 52), depth=14, gloss=0.4)
    iell(img, 256, 330, 30, 30, (30, 28, 28), depth=8, gloss=0.6)
    ipoly(img, [(200, 120), (312, 120), (300, 84), (212, 84)], (30, 30, 34), depth=6, gloss=0.4)
    glow_i(img, 140, 168, 30, (255, 180, 80), 0.6)
    itext(img, (380, 430), "Boum", "hand", 30, (230, 220, 200), rot=10)
    ico_save(img, "ampli")


def ic_baguettes():
    img = canvas_i()
    R = rng(7704)
    for (a, c) in ((-35, (214, 176, 120)), (-55, (200, 160, 104))):
        def P(pts):
            return xform([(256 + x, 256 + y) for x, y in pts], 256, 256, a)
        stick = P([(-200, -11), (150, -9), (180, -6), (196, 0), (180, 6), (150, 9), (-200, 11)])
        ipoly(img, stick, c, depth=8, gloss=0.8, tex=T(R, (4, 8, 16, 32), 0.15))
        cx, cy = P([(196, 0)])[0]
        iell(img, cx, cy, 14, 12, (236, 220, 190), depth=6, gloss=0.8)
        ipoly(img, P([(-200, -12), (-110, -12), (-110, 12), (-200, 12)]), (220, 40, 50), depth=6, gloss=0.4)
    for (x, y, r) in ((380, 110, 18), (430, 200, 12), (120, 120, 14)):
        ipoly(img, star_pts(x, y, r, 4, 0.3, -90), (255, 236, 120), depth=3, gloss=0.4)
    ico_save(img, "baguettes")


def _mush_icon(img, R, cx, base, h, capw, cap, spots, stem=(244, 232, 210), stem_path=None, glowc=None):
    sp = stem_path or [(cx, base), (cx, base - h * 0.5), (cx, base - h)]
    sw = capw * 0.22
    ms = ipoly(img, tube(sp, sw * 1.2, sw), stem, depth=12, gloss=0.5, tex=T(R, (16, 32, 64), 0.12))
    top = base - h
    capp = chaikin([(cx - capw / 2, top + capw * 0.14), (cx - capw * 0.44, top - capw * 0.2), (cx - capw * 0.2, top - capw * 0.4), (cx + capw * 0.2, top - capw * 0.4),
                    (cx + capw * 0.44, top - capw * 0.2), (cx + capw / 2, top + capw * 0.14), (cx, top + capw * 0.06)], 3)
    mc = ipoly(img, capp, cap, depth=30, gloss=1.1, tex=T(R, (8, 16, 32, 64), 0.15))
    for (u, v, r) in spots:
        iell(img, cx + u * capw, top - v * capw, r * capw, r * capw * 0.8, (252, 250, 242), depth=5, gloss=0.6)
    if glowc:
        glow_i(img, cx, top - capw * 0.15, capw * 0.6, glowc, 0.5, inside=mc)
    return mc, ms


SPOTS = [(-0.25, 0.12, 0.07), (0.05, 0.28, 0.08), (0.28, 0.1, 0.06), (-0.05, 0.08, 0.05), (0.18, 0.25, 0.045), (-0.3, -0.02, 0.045)]


def ic_champi_ressort():
    img = canvas_i()
    R = rng(7705)
    # pied en ressort
    d = ImageDraw.Draw(img)
    pts = []
    for k in range(120):
        t = k / 119
        pts.append((256 + math.sin(t * 7 * TAU) * 52, 460 - t * 200))
    for w, c in ((22, (60, 50, 50)), (14, (240, 230, 214)), (5, (255, 255, 255))):
        d.line(pts, fill=c + (255,), width=w, joint="curve")
    _mush_icon(img, R, 256, 270, 10, 330, (240, 120, 30), SPOTS, stem_path=[(256, 270), (256, 262), (256, 258)])
    for (x, y) in ((110, 330), (400, 330)):
        d = ImageDraw.Draw(img)
        d.arc((x - 40, y - 40, x + 40, y + 40), 200 if x < 256 else -20, 340 if x < 256 else 120, fill=(255, 240, 160, 255), width=8)
    itext(img, (256, 494), "BOÏNG", "black", 38, (255, 220, 60))
    ico_save(img, "champi_ressort")


def ic_champi_lune():
    img = canvas_i()
    R = rng(7706)
    mc, ms = _mush_icon(img, R, 256, 470, 200, 330, (110, 130, 220), [], stem=(214, 222, 246), glowc=(90, 120, 200))
    # croissant de lune sur le chapeau
    vol(img, lambda d: (d.ellipse((196, 126, 304, 234), fill=255), d.ellipse((222, 104, 318, 200), fill=0)), (255, 236, 130), depth=8, gloss=0.6)
    for (x, y) in ((170, 230), (330, 200), (210, 160)):
        ipoly(img, star_pts(x, y, 10, 4, 0.35, -90), (240, 248, 255), depth=2, gloss=0.4)
    for (x, y, r) in ((130, 120, 16), (390, 100, 20), (420, 260, 12), (90, 250, 12)):
        ipoly(img, star_pts(x, y, r, 4, 0.3, -90), (230, 240, 255), depth=3, gloss=0.4)
    glow_i(img, 256, 260, 170, (90, 120, 200), 0.15, inside=np.clip(mc + ms, 0, 1))
    ico_save(img, "champi_lune")


def ic_champi_babil():
    img = canvas_i()
    R = rng(7707)
    mc, ms = _mush_icon(img, R, 250, 470, 170, 340, (90, 190, 110), SPOTS[:4])
    d = ImageDraw.Draw(img)
    # visage : yeux, grande bouche-lamelles
    for ex in (205, 295):
        iell(img, ex, 350, 18, 22, (255, 255, 255), depth=4, gloss=0.4)
        iell(img, ex + 4, 352, 9, 11, (30, 30, 30), depth=2, gloss=0.6)
    iell(img, 250, 412, 40, 26, (120, 40, 60), depth=6, gloss=0.4)
    for k in range(7):
        d.line([(218 + k * 10, 392), (220 + k * 10, 432)], fill=(240, 200, 200, 255), width=3)
    # bulle de dialogue
    ipoly(img, chaikin([(330, 60), (480, 60), (490, 150), (420, 160), (390, 196), (392, 158), (330, 150)], 2), (255, 255, 255), depth=8, gloss=0.3)
    itext(img, (410, 108), "Bla!", "black", 40, (40, 40, 60))
    ico_save(img, "champi_babil")


def ic_champi_arcenciel():
    img = canvas_i()
    R = rng(7708)
    mc, ms = _mush_icon(img, R, 256, 470, 190, 360, (255, 255, 255), [])
    rain = [(232, 64, 72), (246, 146, 50), (252, 214, 64), (90, 190, 100), (60, 150, 220), (140, 90, 210)]
    arr = np.asarray(img, np.float32) / 255
    yy, xx = np.mgrid[0:IS, 0:IS].astype(np.float32)
    band = np.clip(((yy - 110) + (xx - 256) * 0.25) / 26, 0, 5.99).astype(np.int32)
    rc = np.array(rain, np.float32)[band] / 255
    rgb = mix(arr[..., :3], arr[..., :3] * rc * 1.15, mc * (1 - 0.0))
    img.paste(Image.fromarray((np.dstack([np.clip(rgb, 0, 1), arr[..., 3]]) * 255 + 0.5).astype(np.uint8), "RGBA"))
    for (u, v, r) in SPOTS[:5]:
        iell(img, 256 + u * 360, 280 - v * 360, r * 360, r * 288, (255, 255, 255), depth=5, gloss=0.6)
    for (x, y, r, c) in ((100, 360, 16, rain[0]), (420, 380, 14, rain[4]), (80, 200, 12, rain[2]), (440, 160, 14, rain[3])):
        ipoly(img, star_pts(x, y, r, 4, 0.3, -90), c, depth=3, gloss=0.4)
    ico_save(img, "champi_arcenciel")


def ic_champi_geant():
    img = canvas_i()
    R = rng(7709)
    mc, ms = _mush_icon(img, R, 256, 480, 150, 440, (210, 34, 40), [(-0.28, 0.14, 0.07), (0.0, 0.3, 0.09), (0.26, 0.16, 0.08), (-0.1, 0.05, 0.05), (0.14, 0.03, 0.05)],
                        stem=(246, 236, 214))
    d = ImageDraw.Draw(img)
    # biceps ! (un petit bras musclé de chaque côté du pied)
    for side in (-1, 1):
        x0 = 256 + side * 60
        arm = tube([(x0, 420), (x0 + side * 60, 400), (x0 + side * 70, 350)], 34, 26)
        ipoly(img, arm, (246, 236, 214), depth=10, gloss=0.5)
        iell(img, x0 + side * 72, 340, 22, 20, (246, 236, 214), depth=8, gloss=0.5)
    for ex in (232, 280):
        iell(img, ex, 400, 8, 11, (30, 30, 30), depth=2, gloss=0.6)
    d = ImageDraw.Draw(img)
    d.arc((236, 410, 276, 440), 20, 160, fill=(40, 30, 30, 255), width=4)
    ico_save(img, "champi_geant")


def ic_panier_legumes():
    img = canvas_i()
    R = rng(7710)
    # légumes derrière
    stroke_cols = [(70, 150, 60), (90, 170, 70)]
    for (x, a) in ((170, -20), (330, 18)):
        lp = leaf_poly(x, 130, 160, 50, math.radians(-90 + a), 0.3)
        ipoly(img, lp, stroke_cols[0], depth=6, gloss=0.3)
    ipoly(img, chaikin([(150, 250), (180, 120), (210, 110), (220, 250)], 2), (240, 120, 30), depth=12, gloss=0.6)
    iell(img, 300, 220, 70, 62, (210, 40, 40), depth=24, gloss=1.1)
    iline(img, [(300, 160), (306, 136)], (80, 120, 40), 8)
    iell(img, 240, 236, 52, 44, (120, 70, 150), depth=20, gloss=1.0)
    iell(img, 360, 260, 48, 40, (110, 170, 60), depth=18, gloss=0.6)
    # panier en osier
    m = ipoly(img, [(70, 250), (442, 250), (400, 460), (112, 460)], (180, 130, 70), depth=16, gloss=0.4, tex=T(R, (32, 64, 128), 0.3))
    d = ImageDraw.Draw(img)
    for k in range(9):
        y = 262 + k * 22
        d.line([(76 + k * 4.2, y), (436 - k * 4.2, y)], fill=(130, 90, 46, 255), width=4)
    for k in range(12):
        x = 100 + k * 28
        d.line([(x, 256), (x + (256 - x) * 0.12, 456)], fill=(150, 104, 56, 255), width=3)
    ipoly(img, tube([(60, 252), (256, 248), (452, 252)], 28), (200, 150, 86), depth=8, gloss=0.4, tex=T(R))
    ico_save(img, "panier_legumes")


def ic_pieces_velo():
    img = canvas_i()
    R = rng(7711)
    # chaîne, pignon, sonnette
    d = ImageDraw.Draw(img)
    gear = []
    for k in range(48):
        a = k / 48 * TAU
        r = 120 if (k // 2) % 2 == 0 else 104
        gear.append((210 + math.cos(a) * r, 230 + math.sin(a) * r))
    mg = ipoly(img, gear, (176, 180, 188), depth=12, gloss=1.0, tex=T(R, (16, 32, 64), 0.15))
    for k in range(5):
        a = k / 5 * TAU
        iell(img, 210 + math.cos(a) * 60, 230 + math.sin(a) * 60, 22, 22, (60, 60, 66), depth=4, gloss=0.2)
    iell(img, 210, 230, 26, 26, (120, 124, 130), depth=8, gloss=1.0)
    pts = [(80 + t * 360, 410 + math.sin(t * 5) * 24) for t in np.linspace(0, 1, 18)]
    for (x, y) in pts:
        iell(img, x, y, 14, 10, (90, 92, 98), depth=4, gloss=0.8)
    iell(img, 390, 330, 64, 50, (230, 190, 60), depth=22, gloss=1.2)
    iell(img, 390, 300, 18, 12, (200, 160, 40), depth=6, gloss=0.8)
    ico_save(img, "pieces_velo")


def ic_antenne_radio():
    img = canvas_i()
    R = rng(7712)
    d = ImageDraw.Draw(img)
    ipoly(img, [(236, 470), (276, 470), (262, 150), (250, 150)], (180, 184, 196), depth=6, gloss=1.0)
    for k, y in enumerate((210, 290, 370)):
        w = 70 + k * 30
        ipoly(img, tube([(256 - w, y), (256 + w, y)], 10), (180, 184, 196), depth=4, gloss=1.0)
    iell(img, 256, 140, 22, 22, (230, 50, 60), depth=8, gloss=1.2)
    glow_i(img, 256, 140, 50, (255, 80, 80), 0.6)
    for k in range(3):
        r = 50 + k * 34
        d.arc((256 - r, 140 - r, 256 + r, 140 + r), 200, 250, fill=(120, 230, 255, 255), width=8)
        d.arc((256 - r, 140 - r, 256 + r, 140 + r), 290, 340, fill=(120, 230, 255, 255), width=8)
    ipoly(img, [(196, 470), (316, 470), (300, 440), (212, 440)], (60, 60, 66), depth=6, gloss=0.4)
    ico_save(img, "antenne_radio")


def ic_bombe_peinture():
    img = canvas_i()
    R = rng(7713)
    m = ipoly(img, [(160, 150), (352, 150), (352, 460), (160, 460)], (60, 200, 120), depth=26, gloss=1.2)
    iell(img, 256, 460, 96, 22, (40, 150, 90), depth=8, gloss=0.6)
    ipoly(img, chaikin([(160, 160), (190, 110), (322, 110), (352, 160)], 2), (190, 196, 204), depth=12, gloss=1.2)
    ipoly(img, [(222, 70), (290, 70), (290, 116), (222, 116)], (240, 240, 244), depth=8, gloss=0.8)
    iell(img, 206, 92, 6, 6, (40, 40, 40), depth=2)
    ipoly(img, [(160, 250), (352, 250), (352, 360), (160, 360)], (250, 220, 60), depth=6, gloss=0.4)
    itext(img, (256, 305), "DIY", "black", 64, (220, 40, 100))
    # nuage de peinture
    d = ImageDraw.Draw(img)
    for _ in range(140):
        a = R.uniform(math.pi * 0.9, math.pi * 1.2)
        r = R.uniform(30, 150)
        x, y = 210 + math.cos(a) * r, 90 + math.sin(a) * r * 0.6
        rr = R.uniform(2, 6)
        d.ellipse((x - rr, y - rr, x + rr, y + rr), fill=(255, 90, 170, 230))
    ico_save(img, "bombe_peinture")


def ic_fanzine():
    img = canvas_i()
    R = rng(7714)
    page = xform([(120, 50), (400, 50), (400, 460), (120, 460)], 256, 256, 8)
    ipoly(img, xform([(130, 60), (410, 60), (410, 470), (130, 470)], 256, 256, 14), (220, 216, 206), depth=6, gloss=0.2)
    ipoly(img, page, (246, 244, 236), depth=8, gloss=0.2, tex=T(R, (32, 64, 128), 0.12))
    for i, ch in enumerate("BOUCAN"):
        x = 160 + i * 38
        inv = i % 2 == 0
        cx, cy = xform([(x, 110)], 256, 256, 8)[0]
        if inv:
            ipoly(img, rell(cx, cy, 20, 24), (30, 30, 34), depth=2, gloss=0.1)
        itext(img, (cx, cy), ch, ["black", "serif", "type"][i % 3], 34, (250, 250, 250) if inv else (30, 30, 34), rot=-8)
    cx, cy = xform([(260, 270)], 256, 256, 8)[0]
    iell(img, cx, cy, 90, 90, (240, 100, 160), depth=4, gloss=0.2)
    iell(img, cx - 10, cy + 10, 44, 54, (40, 38, 42), depth=4, gloss=0.1)
    iell(img, cx + 16, cy - 40, 32, 26, (40, 38, 42), depth=4, gloss=0.1)
    d = ImageDraw.Draw(img)
    for k in range(4):
        a, b = xform([(160, 390 + k * 18), (360 - (k % 2) * 60, 390 + k * 18)], 256, 256, 8)
        d.line([a, b], fill=(60, 60, 66, 255), width=6)
    ico_save(img, "fanzine")


def ic_badge_usine():
    img = canvas_i()
    R = rng(7715)
    iline(img, [(256, 30), (210, 110)], (60, 60, 70), 10)
    iline(img, [(256, 30), (302, 110)], (60, 60, 70), 10)
    ipoly(img, chaikin([(120, 110), (392, 110), (392, 470), (120, 470)], 1), (226, 230, 236), depth=12, gloss=1.0)
    ipoly(img, [(120, 120), (392, 120), (392, 196), (120, 196)], (90, 96, 110), depth=4, gloss=0.6)
    itext(img, (256, 158), "LISSE & FILS", "bold", 30, (240, 242, 246))
    ipoly(img, [(150, 220), (260, 220), (260, 350), (150, 350)], (180, 186, 196), depth=4, gloss=0.3)
    iell(img, 205, 270, 30, 32, (130, 134, 146), depth=4)
    iell(img, 205, 350, 46, 30, (130, 134, 146), depth=4)
    d = ImageDraw.Draw(img)
    for k in range(3):
        d.line([(280, 236 + k * 30), (370 - k * 20, 236 + k * 30)], fill=(110, 116, 128, 255), width=7)
    for k in range(18):
        w = 3 if k % 3 else 6
        d.rectangle((150 + k * 12, 390, 150 + k * 12 + w, 446), fill=(30, 30, 36, 255))
    ipoly(img, [(220, 96), (292, 96), (292, 126), (220, 126)], (120, 124, 134), depth=4, gloss=0.8)
    ico_save(img, "badge_usine")


def ic_plans_lisse():
    img = canvas_i()
    R = rng(7716)
    ipoly(img, [(70, 90), (440, 90), (440, 430), (70, 430)], (60, 110, 190), depth=10, gloss=0.3, tex=T(R, (16, 32, 64), 0.12))
    d = ImageDraw.Draw(img)
    for k in range(0, 340, 28):
        d.line([(70 + k, 90), (70 + k, 430)], fill=(90, 140, 210, 255), width=1)
    for k in range(0, 340, 28):
        d.line([(70, 90 + k), (440, 90 + k)], fill=(90, 140, 210, 255), width=1)
    wc = (236, 244, 255, 255)
    d.rectangle((130, 180, 380, 360), outline=wc, width=5)
    d.rectangle((160, 220, 240, 330), outline=wc, width=3)
    d.rectangle((270, 220, 350, 330), outline=wc, width=3)
    d.line([(130, 380), (380, 380)], fill=wc, width=3)
    itext(img, (256, 136), "LISSE-CENTER", "bold", 34, (236, 244, 255))
    ipoly(img, tube([(56, 80), (56, 440)], 40), (40, 90, 170), depth=12, gloss=0.6)
    ipoly(img, tube([(454, 80), (454, 440)], 40), (40, 90, 170), depth=12, gloss=0.6)
    ipoly(img, xform([(300, 400), (470, 400), (470, 440), (300, 440)], 385, 420, -20), (210, 40, 50), depth=4, gloss=0.4, alpha=0.9)
    itext(img, (385, 420), "ANNULÉ", "black", 30, (255, 255, 255), rot=20)
    ico_save(img, "plans_lisse")


def ic_soupe_prix_libre():
    img = canvas_i()
    R = rng(7717)
    for k in range(3):
        x = 200 + k * 56
        iline(img, [(x + math.sin(t * 6) * 10, 230 - t * 160) for t in np.linspace(0, 1, 16)], (255, 255, 255, 170), 9)
    iell(img, 256, 290, 196, 50, (226, 150, 60), depth=8, gloss=0.6)
    ipoly(img, chaikin([(60, 290), (452, 290), (400, 440), (112, 440)], 2), (60, 120, 190), depth=26, gloss=0.9)
    iell(img, 256, 286, 182, 40, (234, 160, 64), depth=10, gloss=0.8, tex=T(R, (8, 16, 32), 0.2))
    for (x, y, c) in ((200, 282, (240, 120, 30)), (290, 276, (90, 170, 60)), (240, 296, (250, 210, 80)), (330, 292, (240, 120, 30))):
        iell(img, x, y, 16, 10, c, depth=4, gloss=0.6)
    ipoly(img, tube([(330, 270), (410, 140), (430, 110)], 18), (200, 204, 214), depth=6, gloss=1.0)
    iell(img, 256, 380, 34, 34, (250, 214, 80), depth=8, gloss=1.0)
    itext(img, (256, 382), "?", "black", 44, (160, 110, 30))
    ico_save(img, "soupe_prix_libre")


def _bottle_icon(img, R, liquid, label, label_txt, txt_col):
    bottle = chaikin([(212, 50), (300, 50), (300, 130), (356, 200), (366, 470), (146, 470), (156, 200), (212, 130)], 2)
    vol(img, lambda d: d.polygon(bottle, fill=255), (200, 226, 230), depth=22, gloss=1.2, alpha=0.6)
    liq = chaikin([(160, 220), (352, 220), (362, 466), (150, 466)], 1)
    lm = vol(img, lambda d: d.polygon(liq, fill=255), liquid, depth=18, gloss=0.8, alpha=0.88)
    glow_i(img, 256, 360, 90, tuple(min(255, int(v * 1.2)) for v in liquid), 0.25, inside=lm)
    d = ImageDraw.Draw(img)
    for _ in range(14):
        x, y, r = R.uniform(170, 340), R.uniform(240, 450), R.uniform(3, 8)
        d.ellipse((x - r, y - r, x + r, y + r), outline=(255, 255, 255, 200), width=2)
    vol(img, lambda d_: d_.rectangle((206, 26, 306, 64), fill=255), (220, 60, 60), depth=6, gloss=1.0)
    vol(img, lambda d_: d_.rounded_rectangle((168, 280, 344, 400), 14, fill=255), label, depth=6, gloss=0.2, tex=T(R))
    itext(img, (256, 340), label_txt, "black", 40, txt_col)
    vol(img, lambda d_: d_.polygon([(176, 150), (196, 140), (186, 440), (166, 430)], fill=255), (255, 255, 255), depth=6, gloss=0.4, alpha=0.45)


def ic_limonade_boucan():
    img = canvas_i()
    R = rng(7718)
    _bottle_icon(img, R, (250, 230, 120), (250, 246, 230), "LIMO", (220, 60, 60))
    iell(img, 380, 150, 54, 54, (250, 220, 60), depth=14, gloss=0.8)
    iell(img, 380, 150, 40, 40, (255, 244, 170), depth=6, gloss=0.6)
    d = ImageDraw.Draw(img)
    for k in range(8):
        a = k / 8 * TAU
        d.line([(380, 150), (380 + math.cos(a) * 38, 150 + math.sin(a) * 38)], fill=(240, 210, 80, 255), width=3)
    ico_save(img, "limonade_boucan")


def ic_sirop_menthe():
    img = canvas_i()
    R = rng(7719)
    _bottle_icon(img, R, (60, 200, 110), (240, 250, 240), "MENTHE", (30, 120, 70))
    for k, (x, y, a) in enumerate(((380, 130, -0.6), (420, 180, 0.2))):
        ipoly(img, leaf_poly(x, y, 90, 44, a, 0.3), (70, 170, 80), depth=8, gloss=0.5)
    ico_save(img, "sirop_menthe")


def ic_boulon():
    img = canvas_i()
    R = rng(7720)
    ipoly(img, [(226, 200), (286, 200), (286, 470), (226, 470)], (150, 154, 162), depth=8, gloss=1.0)
    d = ImageDraw.Draw(img)
    for y in range(220, 470, 14):
        d.line([(226, y), (286, y + 7)], fill=(100, 104, 112, 255), width=4)
    hexa = [(256 + math.cos(k * math.pi / 3) * 110, 160 + math.sin(k * math.pi / 3) * 64) for k in range(6)]
    ipoly(img, [(p[0], p[1] + 40) for p in hexa], (120, 124, 132), depth=8, gloss=0.6)
    ipoly(img, hexa, (176, 180, 190), depth=12, gloss=1.2, tex=T(R, (16, 32, 64), 0.15))
    hexb = [(256 + math.cos(k * math.pi / 3 + 0.5) * 90, 390 + math.sin(k * math.pi / 3 + 0.5) * 54) for k in range(6)]
    ipoly(img, hexb, (170, 174, 184), depth=10, gloss=1.0)
    iell(img, 256, 390, 30, 18, (90, 94, 100), depth=4)
    ico_save(img, "boulon")


def ic_ressort():
    img = canvas_i()
    R = rng(7721)
    d = ImageDraw.Draw(img)
    pts = [(256 + math.sin(t * 8 * TAU) * 110, 460 - t * 400 + math.cos(t * 8 * TAU) * 16) for t in np.linspace(0, 1, 400)]
    for w, c in ((34, (60, 62, 70)), (24, (160, 166, 176)), (10, (220, 224, 232)), (3, (255, 255, 255))):
        d.line(pts, fill=c + (255,), width=w, joint="curve")
    ico_save(img, "ressort")


def ic_patch_rat():
    img = canvas_i()
    R = rng(7722)
    m = iell(img, 256, 256, 210, 210, (30, 28, 34), depth=10, gloss=0.2, tex=T(R, (64, 128, 256), 0.3))
    d = ImageDraw.Draw(img)
    for k in range(90):
        a = k / 90 * TAU
        d.line([(256 + math.cos(a) * 198, 256 + math.sin(a) * 198), (256 + math.cos(a) * 214, 256 + math.sin(a) * 214)], fill=(220, 40, 50, 255), width=5)
    iell(img, 230, 290, 70, 80, (150, 146, 158), depth=10, gloss=0.4)
    iell(img, 286, 210, 64, 54, (150, 146, 158), depth=10, gloss=0.4)
    ipoly(img, chaikin([(316, 190), (400, 220), (316, 250)], 1), (150, 146, 158), depth=8, gloss=0.4)
    iell(img, 398, 220, 10, 9, (240, 150, 170), depth=4)
    iell(img, 250, 160, 34, 34, (150, 146, 158), depth=8, gloss=0.4)
    iell(img, 250, 160, 20, 20, (240, 150, 170), depth=4)
    for k in range(5):
        x = 270 + k * 18
        ipoly(img, [(x - 10, 168), (x - 4, 100 - abs(k - 2) * -8 - 20), (x + 10, 168)], [(240, 40, 60), (255, 140, 40)][k % 2], depth=4, gloss=0.4)
    iell(img, 330, 200, 10, 12, (255, 255, 255), depth=2)
    iell(img, 332, 201, 5, 6, (20, 20, 20), depth=2)
    itext(img, (256, 420), "RATS DE CALE", "black", 36, (250, 214, 60))
    ico_save(img, "patch_rat")


def ic_os_sardine():
    img = canvas_i()
    R = rng(7723)
    a = -30

    def P(pts):
        return xform([(256 + x, 256 + y) for x, y in pts], 256, 256, a)
    ipoly(img, P([(-150, -26), (150, -26), (150, 26), (-150, 26)]), (244, 232, 206), depth=12, gloss=0.6, tex=T(R, (16, 32, 64), 0.12))
    for sx in (-1, 1):
        for sy in (-1, 1):
            cx, cy = P([(sx * 160, sy * 30)])[0]
            iell(img, cx, cy, 46, 46, (244, 232, 206), depth=16, gloss=0.6)
    cx, cy = P([(0, 0)])[0]
    ipoly(img, P([(-60, -44), (60, -44), (60, 44), (-60, 44)]), (220, 40, 50), depth=6, gloss=0.4)
    for k in range(6):
        iell(img, *P([(-46 + k * 18, -30)])[0], 3.4, 3.4, (255, 255, 255), depth=1)
        iell(img, *P([(-46 + k * 18, 30)])[0], 3.4, 3.4, (255, 255, 255), depth=1)
    ico_save(img, "os_sardine")


def ic_bail_collectif():
    img = canvas_i()
    R = rng(7724)
    tex = T(R, (8, 16, 32, 64), 0.2)
    ipoly(img, [(96, 80), (416, 80), (416, 440), (96, 440)], (240, 230, 206), depth=12, gloss=0.2, tex=tex)
    d = ImageDraw.Draw(img)
    itext(img, (256, 124), "BAIL COLLECTIF", "serif", 32, (60, 44, 34))
    itext(img, (256, 160), "de Port-Boucan", "serifi", 26, (60, 44, 34))
    for k in range(4):
        d.line([(130, 200 + k * 26), (380 - (k % 2) * 40, 200 + k * 26)], fill=(120, 100, 80, 255), width=5)
    # plein de signatures colorées
    cols = [(220, 40, 60), (40, 120, 220), (40, 160, 90), (200, 80, 200), (240, 140, 30), (40, 40, 40)]
    for k in range(9):
        x0, y0 = 130 + (k % 3) * 90, 330 + (k // 3) * 32
        pts = [(x0 + t * 70, y0 + math.sin(t * 9 + k) * 8) for t in np.linspace(0, 1, 14)]
        d.line(pts, fill=cols[k % 6] + (255,), width=4, joint="curve")
    seal = [(380 + math.cos(t) * 48 * (1 + 0.06 * math.sin(7 * t)), 400 + math.sin(t) * 48 * (1 + 0.06 * math.sin(7 * t))) for t in np.linspace(0, TAU, 40, endpoint=False)]
    ipoly(img, seal, (220, 40, 60), depth=10, gloss=0.9)
    shape_r = heart_pts(380, 402, 1.6)
    ipoly(img, shape_r, (255, 220, 220), depth=4, gloss=0.4)
    ico_save(img, "bail_collectif")


def ic_cle_baleine():
    img = canvas_i()
    R = rng(7725)
    a = math.radians(40)
    ca, sa = math.cos(a), math.sin(a)

    def P(u, v):
        return (150 + u * ca - v * sa, 140 + u * sa + v * ca)
    tex = T(R, (16, 32, 64, 128), 0.3)
    iron = (150, 120, 96)
    ipoly(img, [P(70, -16), P(380, -16), P(380, 16), P(70, 16)], iron, depth=8, gloss=0.8, tex=tex)
    ipoly(img, [P(290, 14), P(290, 84), P(316, 84), P(316, 56), P(340, 56), P(340, 92), P(372, 92), P(372, 14)], iron, depth=8, gloss=0.8, tex=tex)
    # anneau en forme de baleine
    wh = chaikin([(-100, 10), (-80, -50), (-20, -70), (50, -50), (90, 0), (130, -40), (140, 10), (120, 40), (80, 30), (30, 60), (-50, 60)], 3)
    m = ipoly(img, [P(u, v) for u, v in wh], (176, 96, 60), depth=18, gloss=0.9, tex=tex)
    hole = [P(-20 + math.cos(t) * 34, 0 + math.sin(t) * 22) for t in np.linspace(0, TAU, 40, endpoint=False)]
    hm = Image.new("L", (IS, IS), 0)
    ImageDraw.Draw(hm).polygon(hole, fill=255)
    img.putalpha(Image.fromarray(np.minimum(np.asarray(img.split()[3]), 255 - np.asarray(hm)).astype(np.uint8)))
    iell(img, *P(-70, -20), 7, 7, (30, 30, 30), depth=2)
    d = ImageDraw.Draw(img)
    d.line(hole + [hole[0]], fill=(110, 60, 30, 255), width=5)
    for _ in range(22):
        x, y = P(R.uniform(-90, 380), R.uniform(-50, 50))
        if img.getpixel((int(x), int(y)))[3] > 200:
            r = R.uniform(4, 10)
            d.ellipse((x - r, y - r, x + r, y + r), fill=(170, 80, 30, 190))
    ico_save(img, "cle_baleine")


def icones():
    """Les objets de l'Île du Boucan (128 px, ombrés et cernés comme les autres icônes)."""
    for n in ICON_NAMES_V75:
        globals()["ic_" + n]()


# =================================================================== lancement

GROUPS = {"sols": sols, "bati": bati, "donjon": donjon, "champignons": champignons, "fresques": fresques, "graffitis": graffitis,
          "affiches": affiches, "enseignes": enseignes, "icones": icones}


def images():
    """Chaque image qu'on peut refaire seule, par son nom de fichier (sans .png)."""
    one = {}
    for fn in (herbe_seche, gravier, beton, asphalte, terre_noire, galets, mousse_spores, sable_gris,
               brique, brique_peinte, beton_brut, tole_rouille, tole_peinte, bardage, acier_rouille, metal_rivete,
               carrelage_usine, paves_port, coque_cargo, moquette_bureau, faux_plafond, beton_usine, tapis_roulant,
               carrelage_bureau, chapeau_bleu, chapeau_violet, chapeau_orange, lamelles, pied_champi,
               panneau_lisse, fanzine_couverture):
        one[fn.__name__] = fn
    for k in range(1, 9):
        one["fresque_%d" % k] = globals()["fresque_%d" % k]
    for k in range(1, 13):
        one["graffiti_%d" % k] = (lambda k=k: graffiti(k))
    for k in POSTERS:
        one["affiche_concert_%d" % k] = (lambda k=k: affiche_concert(k))
    for k in list(ENSEIGNES) + ["conserverie"]:
        one["enseigne_" + k] = (lambda k=k: enseigne(k))
    for k in ICON_NAMES_V75:
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
