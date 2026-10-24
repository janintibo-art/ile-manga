"""V69 : textures de l'Île des Trois Soleils (Per-Hâpy l'égyptienne, Yaxché la maya, Aztlán l'aztèque).

soleils/  — surfaces 1024 px raccordables, chacune avec sa carte de relief <nom>_n.png
          (« sols » : une tuile couvre environ 4 m x 4 m) :
          herbe (+_n)          : prairie tropicale grasse, verts profonds, trèfle, fleurettes ;
          jungle (+_n)         : sol de la forêt pluviale : litière noire mouillée, fougères, mousse, racines ;
          sable (+_n)          : sable doré du plateau de Rê, rides du vent, quelques cailloux ;
          limon (+_n)          : limon noir du fleuve Iterou, luisant, fentes de retrait, débris de roseaux ;
          roche (+_n)          : andésite gris-brun du Mont Fumant, rugueuse, fissures, lichens ;
          (« bati » : une tuile couvre environ 3 m x 3 m)
          calcaire (+_n)       : parement de calcaire blanc de Toura (la pyramide), grands blocs, joints fins ;
          gres (+_n)           : grès doré en assises réglées (temples), arêtes usées, litage ;
          brique (+_n)         : briques crues à la paille (40 x 20 cm), en partie enduites de limon ;
          enduit (+_n)         : enduit de chaux blanchi, presque neutre (teinté en jeu), taches, fêlures ;
          hieroglyphes (+_n)   : grès gravé et peint de colonnes de hiéroglyphes (raccordable dans les deux sens) ;
          pierre_maya (+_n)    : moellons de calcaire gris maya, mousse et coulures de lichen noir ;
          stuc_rouge (+_n)     : stuc rouge d'hématite, usé jusqu'à l'enduit blanc par endroits ;
          glyphes_maya (+_n)   : panneau de calcaire sculpté de blocs de glyphes mayas en grille ;
          tezontle (+_n)       : blocs de tezontle, pierre volcanique rouge-brun poreuse (Aztlán) ;
          frise_azteque (+_n)  : frise peinte sur stuc blanc : grecques à degrés, pierres de jade, étoiles ;
          dalles_soleil (+_n)  : grandes dalles irrégulières de calcaire clair (places, sols) ;
          pierre_sombre (+_n)  : pierre de taille sombre des souterrains, humide, noircie de suie.
          — panneaux peints ou sculptés (« panneaux », non raccordables, sans _n) :
          fresque_pesee        : la pesée du cœur (Anubis, la balance, le cœur et la plume de Maât, Thot, Ammit) ;
          fresque_barque       : Rê dans sa barque de nuit, Apophis enroulé et transpercé ;
          fresque_osiris       : Osiris sur le lit à tête de lion, Isis et Nephthys ailées ;
          fresque_nil          : la vie au bord du fleuve : pêcheurs, moisson, chadouf, oiseaux du papyrus ;
          papyrus_thot         : le papyrus de Thot ; le cartouche royal : ibis, œil d'Horus, disque solaire
                                 (de haut en bas) ;
          fresque_jumeaux      : les Jumeaux Hunahpu et Xbalanque, sarbacanes, balle de caoutchouc, le moustique ;
          fresque_xibalba      : les Seigneurs de Xibalba sur leur banc de trônes, et deux mannequins de bois ;
          stele_4ahau          : (512 x 1024) la stèle de la place : le souverain, et la date 4 Ahau
                                 (quatre points à côté du visage d'Ahau) ;
          fresque_kukulkan     : le serpent à plumes descendant la pyramide à degrés ;
          codex_soleils        : (1024 x 1024) page de codex : le Cinquième Soleil au centre, les quatre
                                 soleils autour, numérotés (points aztèques) et fléchés : 1 Jaguar (en haut à
                                 droite), 2 Vent (en bas à droite), 3 Pluie de feu (en bas à gauche), 4 Eau (en
                                 haut à gauche) ;
          fresque_tlaloc       : Tlaloc, yeux cerclés et crocs, la pluie et le maïs ;
          fresque_huitzilopochtli : le guerrier colibri, rouge et bleu, et le serpent de feu ;
          fresque_nanahuatzin  : le grand feu de Teotihuacan : Nanahuatzin s'y jette, Tecciztécatl hésite ;
          pierre_soleil        : (1024 x 1024, RGBA) la Pierre du Soleil, disque de basalte sculpté.
          — symboles d'énigme (« symboles », 256 x 256 RGBA, pierre sculptée un peu peinte) :
          sym_ankh, sym_oeil, sym_ibis, sym_soleil, sym_scarabee, sym_plume ;
          sym_num_1 … sym_num_13 (chiffres mayas : point = 1, barre = 5) ;
          sym_jour_imix, _ik, _akbal, _kan, _chicchan, _cimi, _manik, _lamat, _muluc, _oc, _chuen, _eb,
          _ben, _ix, _men, _cib, _caban, _etznab, _cauac, _ahau (les 20 jours, nom écrit dessous) ;
          sym_soleil_jaguar, sym_soleil_vent, sym_soleil_feu, sym_soleil_eau, sym_ollin (4 points chacun).
items/    (« icones », 128 px, ombrées et cernées comme les autres) oeil_horus, masque_jade,
          plume_quetzal, fragment_osiris, plume_ara, viande_cerf, os_jaguar, copal, jarre_pluie, conque,
          moustique, glyphe_jaguar, glyphe_vent, glyphe_feu, glyphe_eau, scarabee, papyrus_thot,
          pain_egypte, galette_mais, cacao, biere_heqet, cempasuchil (pas de « dattes » : l'icône existe déjà).

Tout est dessiné ici, procéduralement (libre de droits). Police : Lora (SIL OFL 1.1).
Déterministe : chaque image a sa propre graine (on peut n'en refaire qu'une).
Lancement depuis la racine du dépôt :
    python3 pcvr/tools/generate_soleils_v69.py [sols | bati | panneaux | symboles | icones | <nom>]
(sans argument : tout ; <nom> : une seule image, par ex. « herbe » ou « codex_soleils »).
"""
from pathlib import Path
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_azur_v56 as az  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "soleils"
ITEMS = ROOT / "www" / "assets" / "textures" / "items"
TAU = math.tau

# Les cartes _n existantes (azur, pirates…) codent le vert « vers le bas de l'image » ; on fait de même
# pour que tout l'archipel soit éclairé pareil. Mettre True pour un vert « vers le haut ».
NORMAL_Y_UP = False


# =================================================================== outils

def rng(seed):
    return np.random.default_rng(seed)


def _up(layer, W, H):
    """Agrandit une grille aléatoire en bicubique, de façon périodique (raccordable)."""
    oy, ox = layer.shape
    if ox >= W and oy >= H:
        return layer[:H, :W]
    p = 2
    big = np.pad(layer, p, mode="wrap")
    cw, ch = W / ox, H / oy
    im = Image.fromarray(big, "F").resize((int(round((ox + 2 * p) * cw)), int(round((oy + 2 * p) * ch))), Image.BICUBIC)
    a = np.asarray(im, np.float32)
    x0, y0 = int(round(p * cw)), int(round(p * ch))
    return a[y0:y0 + H, x0:x0 + W]


def tn(R, S, octaves=(4, 8, 16, 32, 64, 128, 256), falloff=0.55, H=None, oy=None):
    """Bruit fractal raccordable (S de large, H de haut), 0..1, moyenne 0.5.
    oy : nombres de cellules verticaux (bruit étiré : traînées, coulures)."""
    H = H or S
    acc = np.zeros((H, S), np.float32)
    amp = 1.0
    for k, ox in enumerate(octaves):
        oyk = oy[k] if oy is not None else max(1, int(round(ox * H / S)))
        layer = R.random((oyk, ox)).astype(np.float32)
        acc += _up(layer, S, H) * amp
        amp *= falloff
    acc -= acc.mean()
    acc /= (acc.std() + 1e-6)
    return np.clip(0.5 + acc * 0.2, 0, 1).astype(np.float32)


def gblur(a, sigma):
    """Flou gaussien périodique (par FFT) : raccordable et sans perte de précision."""
    if sigma <= 0:
        return a
    H, W = a.shape[:2]
    fy = np.fft.fftfreq(H)[:, None]
    fx = np.fft.rfftfreq(W)[None, :]
    g = np.exp(-2.0 * (math.pi * sigma) ** 2 * (fx * fx + fy * fy))
    if a.ndim == 2:
        return np.fft.irfft2(np.fft.rfft2(a) * g, s=(H, W)).astype(np.float32)
    return np.dstack([np.fft.irfft2(np.fft.rfft2(a[..., c]) * g, s=(H, W)).astype(np.float32) for c in range(a.shape[2])])


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def mix(a, b, t):
    t = np.asarray(t, np.float32)
    if t.ndim == 2:
        t = t[..., None]
    return np.asarray(a, np.float32) * (1 - t) + np.asarray(b, np.float32) * t


def C(*rgb):
    return np.array(rgb, np.float32)


def grads(h):
    gx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5
    gy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5
    return gx, gy


def normal_img(h, strength):
    gx, gy = grads(h.astype(np.float32))
    nx = -gx * strength
    ny = (gy if NORMAL_Y_UP else -gy) * strength
    inv = 1.0 / np.sqrt(nx * nx + ny * ny + 1.0)
    n = np.dstack((nx * inv, ny * inv, inv))
    return Image.fromarray(((n * 0.5 + 0.5) * 255 + 0.5).astype(np.uint8), "RGB")


def bake(col, h, strength, k=0.3, ao=0.0, ao_r=6.0, light=(-0.45, -0.6, 0.66)):
    """Grave un peu de lumière (venant d'en haut à gauche) et d'occlusion dans la couleur."""
    gx, gy = grads(h)
    nx, ny = -gx * strength, -gy * strength
    inv = 1.0 / np.sqrt(nx * nx + ny * ny + 1.0)
    L = np.array(light, np.float32)
    L /= np.linalg.norm(L)
    lam = (nx * L[0] + ny * L[1] + L[2]) * inv / L[2]
    out = col * (1.0 + k * (lam - 1.0))[..., None]
    if ao > 0:
        cav = np.clip(gblur(h, ao_r) - h, 0, None)
        cav = cav / (cav.max() + 1e-6)
        out = out * (1.0 - ao * np.sqrt(cav))[..., None]
    return out


def offs(x, y, r, S, H=None):
    """Décalages où redessiner une forme pour qu'elle se raccorde aux bords."""
    H = H or S
    xs = [0] + ([S] if x - r < 0 else []) + ([-S] if x + r > S else [])
    ys = [0] + ([H] if y - r < 0 else []) + ([-H] if y + r > H else [])
    return [(ox, oy) for ox in xs for oy in ys]


def to_img(col):
    return Image.fromarray((np.clip(col, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB")


def from_img(img):
    return np.asarray(img, np.float32) / 255.0


def save_rgb(arr, name, folder=None):
    p = (folder or OUT) / name
    p.parent.mkdir(parents=True, exist_ok=True)
    (arr if isinstance(arr, Image.Image) else to_img(arr)).convert("RGB").save(p, optimize=True)
    print(p.relative_to(ROOT))


def save_rgba(arr, name, folder=None):
    p = (folder or OUT) / name
    p.parent.mkdir(parents=True, exist_ok=True)
    if not isinstance(arr, Image.Image):
        arr = Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA")
    arr.save(p, optimize=True)
    print(p.relative_to(ROOT))


def save_surface(name, col, h, strength):
    save_rgb(col, name + ".png")
    p = OUT / (name + "_n.png")
    normal_img(h, strength).save(p, optimize=True)
    print(p.relative_to(ROOT))


def per_id(ids, R, lo, hi):
    u, inv = np.unique(ids, return_inverse=True)
    v = R.uniform(lo, hi, len(u)).astype(np.float32)
    return v[inv].reshape(ids.shape)


def masonry(R, S, rows, wmin, wmax, rr=0.0):
    """Appareil de blocs raccordable : rangées de hauteurs données (somme = S), largeurs tirées.
    Renvoie id du bloc, distance au joint (px, coins arrondis de rayon rr), u, v dans le bloc."""
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    bid = np.zeros((S, S), np.int32)
    e = np.zeros((S, S), np.float32)
    u = np.zeros((S, S), np.float32)
    v = np.zeros((S, S), np.float32)
    top = 0.0
    for ri, hgt in enumerate(rows):
        y0, y1 = int(round(top)), int(round(top + hgt))
        top += hgt
        ws = []
        while sum(ws) < S:
            ws.append(R.uniform(wmin, wmax))
        ws = np.array(ws)
        ws *= S / ws.sum()
        cum = np.cumsum(ws)
        off = R.uniform(0, S)
        sl = slice(y0, y1)
        xr = np.mod(xx[sl] + off, S)
        idx = np.minimum(np.searchsorted(cum, xr, side="right"), len(cum) - 1)
        left = np.where(idx > 0, cum[np.maximum(idx - 1, 0)], 0.0)
        right = cum[idx]
        dx = np.minimum(xr - left, right - xr)
        dy = np.minimum(yy[sl] - y0 + 0.5, y1 - yy[sl] - 0.5)
        ee = np.minimum(dx, dy)
        if rr > 0:
            corner = (dx < rr) & (dy < rr)
            ee = np.where(corner, rr - np.hypot(rr - dx, rr - dy), ee)
        e[sl] = ee
        bid[sl] = ri * 1000 + idx
        u[sl] = (xr - left) / (right - left)
        v[sl] = (yy[sl] - y0) / max(1, (y1 - y0))
    return bid, e, u, v


def worley(R, S, n, jitter=0.8):
    """Cellules de Voronoï raccordables (une graine par case d'une grille n x n).
    Renvoie d1, distance exacte à la frontière la plus proche, id de cellule, dx et dy vers la graine."""
    pts = (0.5 + (R.random((n, n, 2)) - 0.5) * jitter).astype(np.float32)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    xx = xx / S * n
    yy = yy / S * n
    cx = np.floor(xx).astype(np.int32)
    cy = np.floor(yy).astype(np.int32)
    cand = []
    for oy in (-1, 0, 1):
        for ox in (-1, 0, 1):
            nx = (cx + ox) % n
            ny = (cy + oy) % n
            px = cx + ox + pts[ny, nx, 0]
            py = cy + oy + pts[ny, nx, 1]
            cand.append((px, py, ny * n + nx))
    d1 = np.full((S, S), 99.0, np.float32)
    i1 = np.zeros((S, S), np.int32)
    p1x = np.zeros((S, S), np.float32)
    p1y = np.zeros((S, S), np.float32)
    for px, py, cid in cand:
        d = np.hypot(xx - px, yy - py)
        c = d < d1
        d1 = np.where(c, d, d1)
        i1 = np.where(c, cid, i1)
        p1x = np.where(c, px, p1x)
        p1y = np.where(c, py, p1y)
    edge = np.full((S, S), 99.0, np.float32)
    for px, py, cid in cand:
        mx, my = (px + p1x) * 0.5, (py + p1y) * 0.5
        ux, uy = px - p1x, py - p1y
        L = np.hypot(ux, uy)
        valid = L > 1e-4
        dd = np.where(valid, ((mx - xx) * ux + (my - yy) * uy) / np.maximum(L, 1e-4), 99.0)
        edge = np.minimum(edge, np.where(valid, dd, 99.0))
    return d1 * S / n, edge * S / n, i1, (xx - p1x) * S / n, (yy - p1y) * S / n


def warp(a, dx, dy):
    """Déforme un champ (raccordable) : a(x + dx, y + dy), interpolation bilinéaire."""
    H, W = a.shape[:2]
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    x = xx + dx
    y = yy + dy
    x0 = np.floor(x).astype(np.int32)
    y0 = np.floor(y).astype(np.int32)
    fx = (x - x0)
    fy = (y - y0)
    x0 %= W
    y0 %= H
    x1 = (x0 + 1) % W
    y1 = (y0 + 1) % H
    if a.ndim == 3:
        fx = fx[..., None]
        fy = fy[..., None]
    return ((a[y0, x0] * (1 - fx) + a[y0, x1] * fx) * (1 - fy) + (a[y1, x0] * (1 - fx) + a[y1, x1] * fx) * fy).astype(np.float32)


def leaf_poly(x, y, L, W, a, tip=0.55):
    """Une feuille (losange arrondi) de longueur L, largeur W, orientée a (centrée en x, y)."""
    pts = []
    n = 9
    for k in range(n + 1):
        t = k / n
        r = W * 0.5 * math.sin(math.pi * t) ** 0.8 * (1 - tip * t * t * 0.6)
        pts.append(((t - 0.5) * L, r))
    for k in range(n - 1, 0, -1):
        t = k / n
        r = W * 0.5 * math.sin(math.pi * t) ** 0.8 * (1 - tip * t * t * 0.6)
        pts.append(((t - 0.5) * L, -r))
    ca, sa = math.cos(a), math.sin(a)
    return [(x + u * ca - v * sa, y + u * sa + v * ca) for u, v in pts]


def blade_poly(x, y, a, L, w, curv):
    """Un brin d'herbe effilé, légèrement courbe, qui part de (x, y) dans la direction a."""
    ca, sa = math.cos(a), math.sin(a)
    px, py = -sa, ca
    left, right = [], []
    for k in range(6):
        t = k / 5
        cx = x + ca * L * t + px * curv * L * t * t
        cy = y + sa * L * t + py * curv * L * t * t
        ww = w * 0.5 * (1 - t) ** 0.9
        left.append((cx + px * ww, cy + py * ww))
        right.append((cx - px * ww, cy - py * ww))
    return left + right[::-1]


def chaikin(pts, n=2, closed=True):
    """Arrondit une ligne brisée (algorithme de Chaikin)."""
    p = [tuple(map(float, q)) for q in pts]
    for _ in range(n):
        q = []
        m = len(p) if closed else len(p) - 1
        if not closed:
            q.append(p[0])
        for i in range(m):
            a, b = p[i], p[(i + 1) % len(p)]
            q.append((a[0] * 0.75 + b[0] * 0.25, a[1] * 0.75 + b[1] * 0.25))
            q.append((a[0] * 0.25 + b[0] * 0.75, a[1] * 0.25 + b[1] * 0.75))
        if not closed:
            q.append(p[-1])
        p = q
    return p


def bez(p0, p1, p2, p3=None, n=16):
    """Courbe de Bézier (quadratique ou cubique) en points ; bez(a, b, c, n) = quadratique."""
    if isinstance(p3, (int, float)):
        p3, n = None, int(p3)
    out = []
    for k in range(n + 1):
        t = k / n
        if p3 is None:
            x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
            y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
        else:
            x = (1 - t) ** 3 * p0[0] + 3 * (1 - t) ** 2 * t * p1[0] + 3 * (1 - t) * t * t * p2[0] + t ** 3 * p3[0]
            y = (1 - t) ** 3 * p0[1] + 3 * (1 - t) ** 2 * t * p1[1] + 3 * (1 - t) * t * t * p2[1] + t ** 3 * p3[1]
        out.append((x, y))
    return out


def font(size, italic=False, bold=False):
    return az.font(int(size), italic=italic, bold=bold)


# =================================================================== les sols (une tuile ≈ 4 m)

def herbe():
    """Prairie tropicale grasse : touffes d'herbe en trois épaisseurs (le dessous sombre, le dessus
    clair), des verts qui tirent tantôt vers le jaune, tantôt vers le bleu ; taches de trèfle,
    fleurettes blanches, jaunes, roses et mauves."""
    S = 1024
    R = rng(6901)
    n = tn(R, S, (8, 16, 32, 64, 128, 256), 0.6)
    hue = tn(R, S, (4, 8, 16, 32, 64), 0.8)
    lush = tn(R, S, (8, 16, 32, 64), 0.75)
    clov = tn(R, S, (8, 16, 32, 64), 0.7)
    flw = tn(R, S, (16, 32, 64), 0.7)
    base = mix(C(0.09, 0.12, 0.04), C(0.17, 0.2, 0.07), n)
    img = to_img(base)
    d = ImageDraw.Draw(img)
    hm = Image.new("L", (S, S), 0)
    dh = ImageDraw.Draw(hm)
    deep = np.array([0.13, 0.33, 0.12])
    blue = np.array([0.16, 0.4, 0.2])
    yel = np.array([0.42, 0.55, 0.13])
    tufts = R.random((5200, 2)) * S
    for p, (count, bright, hv, ls) in enumerate(((30000, 0.5, 60, 1.0), (26000, 0.78, 140, 0.92), (17000, 1.05, 215, 0.78))):
        for _ in range(count):
            cx, cy = tufts[R.integers(len(tufts))]
            x = cx + R.normal(0, 5)
            y = cy + R.normal(0, 5)
            xi, yi = int(x) % S, int(y) % S
            g = hue[yi, xi]
            c = deep * (1 - g) + yel * g if R.random() < 0.7 else blue
            c = c * bright * (0.75 + 0.5 * lush[yi, xi]) * R.uniform(0.82, 1.18)
            col = tuple(int(np.clip(v, 0, 1) * 255) for v in c)
            a = R.uniform(0, TAU)
            L = R.uniform(18, 48) * ls
            w = R.uniform(2.0, 3.8)
            poly = blade_poly(x, y, a, L, w, R.uniform(-0.35, 0.35))
            hvv = int(hv + R.uniform(-25, 25))
            for ox, oy in offs(x, y, L + 4, S):
                pp = [(px + ox, py + oy) for px, py in poly]
                d.polygon(pp, fill=col)
                dh.polygon(pp, fill=hvv)
        if p == 1:
            # le trèfle, entre deux couches d'herbe
            for _ in range(5200):
                x, y = R.random(2) * S
                if clov[int(y), int(x)] < 0.6 + R.random() * 0.12:
                    continue
                r = R.uniform(2.8, 4.6)
                a0 = R.uniform(0, TAU)
                t = R.random()
                cc = (int(44 + 30 * t), int(104 + 34 * t), int(40 + 16 * t))
                for k in range(3):
                    a = a0 + k * TAU / 3
                    lx, ly = x + math.cos(a) * r * 0.95, y + math.sin(a) * r * 0.95
                    for ox, oy in offs(lx, ly, r + 1, S):
                        d.ellipse((lx + ox - r, ly + oy - r, lx + ox + r, ly + oy + r), fill=cc)
                        dh.ellipse((lx + ox - r, ly + oy - r, lx + ox + r, ly + oy + r), fill=185)
                        d.point((lx + ox + math.cos(a) * r * 0.2, ly + oy + math.sin(a) * r * 0.2), fill=(min(255, cc[0] + 70), min(255, cc[1] + 70), min(255, cc[2] + 50)))
    # fleurettes
    kinds = [((246, 244, 236), (236, 196, 60), 3.0, 0.42), ((248, 214, 60), (200, 150, 30), 2.4, 0.22),
             ((232, 120, 170), (250, 220, 120), 2.2, 0.18), ((170, 130, 220), (250, 240, 200), 2.0, 0.18)]
    for _ in range(2600):
        x, y = R.random(2) * S
        if flw[int(y), int(x)] < 0.6 + R.random() * 0.25:
            continue
        u = R.random()
        acc = 0
        for petal, heart, r, pr in kinds:
            acc += pr
            if u <= acc:
                break
        r *= R.uniform(0.8, 1.25)
        for ox, oy in offs(x, y, r + 2, S):
            if petal[0] > 240 and petal[1] > 240:
                for k in range(6):
                    a = k / 6 * TAU
                    px, py = x + ox + math.cos(a) * r * 0.75, y + oy + math.sin(a) * r * 0.75
                    d.ellipse((px - r * 0.5, py - r * 0.5, px + r * 0.5, py + r * 0.5), fill=petal)
            else:
                d.ellipse((x + ox - r, y + oy - r, x + ox + r, y + oy + r), fill=petal)
            d.ellipse((x + ox - r * 0.35, y + oy - r * 0.35, x + ox + r * 0.35, y + oy + r * 0.35), fill=heart)
            dh.ellipse((x + ox - r, y + oy - r, x + ox + r, y + oy + r), fill=250)
    col = gblur(from_img(img), 0.45)
    h = gblur(np.asarray(hm, np.float32) / 255.0, 0.9)
    col = bake(col, h, 3.0, k=0.25, ao=0.35, ao_r=5)
    col *= (0.94 + 0.12 * lush[..., None])
    save_surface("herbe", col, h * 0.85 + n * 0.15, 4.0)


def _fern(d, dh, x, y, a, L, S, col, hv):
    """Une fronde de fougère : un rachis courbe et ses pinnules, vues d'en haut."""
    bend = (math.pi / 2) * 0.25 * (1 if (x * 7 + y) % 2 > 1 else -1)
    pts = []
    for k in range(int(L / 4) + 1):
        t = k * 4 / L
        aa = a + bend * t
        if not pts:
            pts.append((x, y, aa))
        else:
            px, py, _ = pts[-1]
            pts.append((px + math.cos(aa) * 4, py + math.sin(aa) * 4, aa))
    for ox, oy in offs(x, y, L + 20, S):
        for i, (px, py, aa) in enumerate(pts[1:]):
            t = i / max(1, len(pts) - 1)
            pl = 10 * (1 - t) ** 0.8 + 2.5
            for sgn in (-1, 1):
                b = aa + sgn * 1.05
                cx, cy = px + ox + math.cos(b) * pl * 0.5, py + oy + math.sin(b) * pl * 0.5
                poly = leaf_poly(cx, cy, pl, pl * 0.34, b)
                d.polygon(poly, fill=col)
                dh.polygon(poly, fill=hv)
        d.line([(px + ox, py + oy) for px, py, _ in pts], fill=tuple(int(c * 0.7) for c in col), width=2)


def jungle():
    """Sol de la forêt pluviale : terre noire mouillée sous une litière épaisse de grandes feuilles
    brunes pourrissantes, des racines qui courent, de la mousse vert vif, de jeunes fougères et des
    pousses ; plus sombre et plus vert que le sous-bois de la Balafre."""
    S = 1024
    R = rng(6902)
    n = tn(R, S, (8, 16, 32, 64, 128, 256), 0.6)
    moss_n = tn(R, S, (8, 16, 32, 64), 0.7)
    fernz = tn(R, S, (4, 8, 16), 0.6)
    img = to_img(mix(C(0.05, 0.04, 0.03), C(0.11, 0.085, 0.055), n))
    d = ImageDraw.Draw(img)
    hm = Image.new("L", (S, S), 20)
    dh = ImageDraw.Draw(hm)

    def leaves(count, hlo, hhi):
        for _ in range(count):
            x, y = R.random(2) * S
            L = R.uniform(20, 62)
            W = L * R.uniform(0.32, 0.5)
            a = R.uniform(0, TAU)
            t = R.random()
            u = R.random()
            if u < 0.5:
                c = (int(38 + 34 * t), int(25 + 20 * t), int(13 + 10 * t))       # brun mouillé
            elif u < 0.8:
                c = (int(20 + 16 * t), int(16 + 12 * t), int(10 + 7 * t))        # presque noir
            elif u < 0.88:
                c = (int(78 + 34 * t), int(52 + 22 * t), int(22 + 10 * t))       # tombé d'hier
            else:
                c = (int(40 + 24 * t), int(48 + 26 * t), int(20 + 10 * t))       # encore olive
            poly = leaf_poly(x, y, L, W, a, tip=0.7)
            hv = int(R.uniform(hlo, hhi))
            vein = tuple(int(v * 0.6) for v in c)
            for ox, oy in offs(x, y, L * 0.6, S):
                pp = [(px + ox, py + oy) for px, py in poly]
                d.polygon(pp, fill=c)
                dh.polygon(pp, fill=hv)
                ca, sa = math.cos(a), math.sin(a)
                d.line([(x + ox - ca * L * 0.5, y + oy - sa * L * 0.5), (x + ox + ca * L * 0.5, y + oy + sa * L * 0.5)], fill=vein, width=1)
                for k in (-0.25, 0.0, 0.2):
                    bx, by = x + ox + ca * L * k, y + oy + sa * L * k
                    for sg in (-1, 1):
                        d.line([(bx, by), (bx + math.cos(a + sg * 0.8) * W * 0.4, by + math.sin(a + sg * 0.8) * W * 0.4)], fill=vein, width=1)

    leaves(8000, 40, 140)
    # racines
    for _ in range(16):
        x, y = R.random(2) * S
        a = R.uniform(0, TAU)
        w = R.uniform(7, 15)
        pts = [(x, y)]
        for k in range(46):
            a += R.normal(0, 0.18)
            x += math.cos(a) * 9
            y += math.sin(a) * 9
            pts.append((x, y))
        t = R.random()
        c = (int(58 + 30 * t), int(42 + 22 * t), int(28 + 14 * t))
        hi = (int(96 + 30 * t), int(76 + 20 * t), int(52 + 12 * t))
        for ox in (-S, 0, S):
            for oy in (-S, 0, S):
                for i in range(len(pts) - 1):
                    ww = max(2, int(w * (1 - i / len(pts) * 0.7)))
                    seg = [(pts[i][0] + ox, pts[i][1] + oy), (pts[i + 1][0] + ox, pts[i + 1][1] + oy)]
                    d.line(seg, fill=c, width=ww)
                    dh.line(seg, fill=200, width=ww)
                    d.line([(seg[0][0] - 1, seg[0][1] - ww * 0.25), (seg[1][0] - 1, seg[1][1] - ww * 0.25)], fill=hi, width=max(1, ww // 4))
    leaves(3000, 120, 200)
    # couvre-sol : petites feuilles vert sombre, par plaques
    cover = tn(R, S, (8, 16, 32, 64), 0.65)
    for _ in range(14000):
        x, y = R.random(2) * S
        if cover[int(y), int(x)] < 0.5 + R.random() * 0.1:
            continue
        L = R.uniform(7, 18)
        a = R.uniform(0, TAU)
        t = R.random()
        c = (int(18 + 24 * t), int(40 + 36 * t), int(14 + 14 * t))
        poly = leaf_poly(x, y, L, L * R.uniform(0.35, 0.55), a)
        hv = int(170 + R.uniform(0, 50))
        for ox, oy in offs(x, y, L, S):
            pp = [(px + ox, py + oy) for px, py in poly]
            d.polygon(pp, fill=c)
            dh.polygon(pp, fill=hv)
    # brindilles
    for _ in range(320):
        x, y = R.random(2) * S
        a = R.uniform(0, TAU)
        L = R.uniform(14, 60)
        for ox, oy in offs(x, y, L, S):
            d.line([(x + ox, y + oy), (x + ox + math.cos(a) * L, y + oy + math.sin(a) * L)], fill=(30, 22, 16), width=2)
            dh.line([(x + ox, y + oy), (x + ox + math.cos(a) * L, y + oy + math.sin(a) * L)], fill=170, width=2)
    col = from_img(img)
    h = np.asarray(hm, np.float32) / 255.0
    # mousse : un velours vert vif, piqueté, qui couvre les creux et le pied des racines
    fine = tn(R, S, (128, 256, 512, 1024), 0.8)
    mm = smooth(0.55, 0.63, moss_n + (fine - 0.5) * 0.14)
    moss = mix(C(0.06, 0.13, 0.03), C(0.2, 0.33, 0.07), fine) * (0.8 + 0.4 * n[..., None])
    col = mix(col, moss, mm * 0.95)
    h = h * (1 - mm) + (0.35 + 0.25 * fine) * mm
    # fougères et pousses, par bouquets
    img = to_img(col)
    d = ImageDraw.Draw(img)
    hm = Image.fromarray((np.clip(h, 0, 1) * 255).astype(np.uint8))
    dh = ImageDraw.Draw(hm)
    for _ in range(70):
        x, y = R.random(2) * S
        if fernz[int(y), int(x)] < 0.5:
            continue
        k = int(R.integers(2, 5))
        a0 = R.uniform(0, TAU)
        t = R.random()
        c = (int(22 + 24 * t), int(56 + 36 * t), int(16 + 14 * t))
        for j in range(k):
            _fern(d, dh, x, y, a0 + j * TAU / k + R.normal(0, 0.5), R.uniform(36, 80), S, c, int(215 + R.uniform(0, 40)))
    for _ in range(160):
        x, y = R.random(2) * S
        a = R.uniform(0, TAU)
        t = R.random()
        c = (int(40 + 30 * t), int(84 + 34 * t), int(24 + 16 * t))
        for sg in (-1, 1):
            poly = leaf_poly(x + math.cos(a + sg * 1.4) * 5, y + math.sin(a + sg * 1.4) * 5, 11, 6, a + sg * 1.4)
            for ox, oy in offs(x, y, 14, S):
                pp = [(px + ox, py + oy) for px, py in poly]
                d.polygon(pp, fill=c)
                dh.polygon(pp, fill=235)
    col = gblur(from_img(img), 0.4)
    h = gblur(np.asarray(hm, np.float32) / 255.0, 0.8)
    col = bake(col, h, 3.0, k=0.3, ao=0.5, ao_r=7)
    # luisant de l'humidité (reflets froids sur la litière)
    wet = smooth(0.6, 0.8, tn(R, S, (8, 16, 32, 64), 0.6)) * (1 - mm)
    col = col + wet[..., None] * C(0.03, 0.035, 0.04)
    save_surface("jungle", col, h, 5.0)


def sable():
    """Sable doré du plateau de Rê : grains fins, rides du vent douces (pente longue au vent,
    courte sous le vent) qui se divisent, grains plus foncés au creux des rides, quelques cailloux
    (silex brun, quartz blanc, grès rouge)."""
    S = 1024
    R = rng(6903)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    w1 = tn(R, S, (2, 4, 8), 0.5)
    w2 = tn(R, S, (8, 16, 32), 0.55)
    ph = (yy / S * 26.0 + xx / S * 2.0 + (w1 - 0.5) * 2.6 + (w2 - 0.5) * 0.9)
    f = ph - np.floor(ph)
    prof = np.where(f < 0.75, f / 0.75, (1 - f) / 0.25)
    prof = gblur(prof.astype(np.float32), 1.6)
    amp = 0.35 + 0.65 * smooth(0.3, 0.7, tn(R, S, (2, 4, 8, 16), 0.6))
    rip = prof * amp
    grain = tn(R, S, (256, 512, 1024), 0.85)
    big = tn(R, S, (2, 4, 8, 16, 32), 0.6)
    base = mix(C(0.8, 0.6, 0.36), C(0.89, 0.72, 0.47), big)
    col = base * (0.86 + 0.18 * grain[..., None]) * (0.93 + 0.1 * rip[..., None])
    trough = (1 - prof) * amp
    col = mix(col, col * C(0.86, 0.8, 0.76), smooth(0.55, 0.95, trough) * 0.6)
    sp = R.random((S, S)).astype(np.float32)
    col = mix(col, C(0.42, 0.3, 0.2), (sp < 0.012).astype(np.float32) * 0.55)
    col = mix(col, C(0.97, 0.93, 0.84), (sp > 0.992).astype(np.float32) * 0.5)
    h = rip * 0.6 + grain * 0.12 + big * 0.1
    img = to_img(col).convert("RGBA")
    pb = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(pb)
    sh = Image.new("L", (S, S), 0)
    ds = ImageDraw.Draw(sh)
    hm = Image.new("L", (S, S), 0)
    dh = ImageDraw.Draw(hm)
    pal = [(118, 78, 46), (92, 64, 44), (226, 220, 206), (156, 84, 56), (70, 60, 52), (176, 150, 110)]
    for _ in range(190):
        x, y = R.random(2) * S
        r = R.uniform(1.6, 6.5) if R.random() < 0.85 else R.uniform(7, 11)
        c = pal[R.integers(len(pal))]
        k = int(R.integers(6, 10))
        a0 = R.uniform(0, TAU)
        poly = [(math.cos(a0 + j / k * TAU) * r * R.uniform(0.7, 1.0), math.sin(a0 + j / k * TAU) * r * R.uniform(0.6, 0.95)) for j in range(k)]
        for ox, oy in offs(x, y, r + 4, S):
            d.polygon([(x + ox + px, y + oy + py) for px, py in poly], fill=c + (255,))
            ds.polygon([(x + ox + px + r * 0.35, y + oy + py + r * 0.45) for px, py in poly], fill=150)
            dh.polygon([(x + ox + px, y + oy + py) for px, py in poly], fill=255)
    sha = gblur(np.asarray(sh, np.float32) / 255.0, 1.6)
    arr = from_img(img.convert("RGB")) * (1 - 0.45 * sha[..., None])
    pa = np.asarray(pb, np.float32) / 255.0
    ph_ = gblur(np.asarray(hm, np.float32) / 255.0, 1.2)
    stone = pa[..., :3] * (0.75 + 0.5 * np.clip(ph_ * 1.5, 0, 1))[..., None]
    arr = mix(arr, stone, pa[..., 3])
    arr = gblur(arr, 0.35)
    h = h + ph_ * 0.5
    arr = bake(arr, h, 4.0, k=0.35)
    save_surface("sable", arr, h, 4.5)


def limon():
    """Limon noir des berges de l'Iterou : boue grasse et luisante là où elle est mouillée,
    gris-brun et fendue en plaques (fentes de retrait) là où elle sèche ; débris de roseaux et de
    papyrus, petites flaques qui reflètent le ciel."""
    S = 1024
    R = rng(6904)
    n = tn(R, S, (4, 8, 16, 32, 64, 128), 0.6)
    fine = tn(R, S, (128, 256, 512), 0.75)
    dry_n = tn(R, S, (4, 8, 16, 32), 0.65)
    dry = smooth(0.5, 0.62, dry_n)
    wd1 = tn(R, S, (4, 8, 16), 0.6)
    wd2 = tn(R, S, (4, 8, 16), 0.6)
    d1, edge, cid, _, _ = worley(R, S, 13, 0.9)
    edge = warp(edge, (wd1 - 0.5) * 22, (wd2 - 0.5) * 22)
    d2, edge2, _, _, _ = worley(R, S, 34, 0.9)
    edge2 = warp(edge2, (wd2 - 0.5) * 10, (wd1 - 0.5) * 10)
    wcr = (1.2 + 1.8 * fine) * dry
    crack = 1 - smooth(wcr * 0.6, wcr + 0.8, edge)
    crack2 = (1 - smooth(0.3, 1.1, edge2)) * smooth(0.68, 0.85, dry_n) * 0.6
    cr = np.clip(crack + crack2, 0, 1) * (dry > 0.05)
    curl = smooth(12, 0, edge) * dry
    wet_col = mix(C(0.1, 0.08, 0.058), C(0.18, 0.14, 0.1), n) * (0.88 + 0.22 * fine[..., None])
    dry_col = mix(C(0.24, 0.2, 0.15), C(0.33, 0.28, 0.21), n) * (0.85 + 0.25 * fine[..., None])
    col = mix(wet_col, dry_col, dry)
    col = col * (1 + 0.18 * curl[..., None])
    col = mix(col, C(0.04, 0.03, 0.02), cr)
    # luisant : reflets du ciel sur la boue mouillée, petites flaques
    sheen = smooth(0.58, 0.8, tn(R, S, (16, 32, 64, 128), 0.65)) * (1 - dry)
    col = col + sheen[..., None] * C(0.045, 0.05, 0.055)
    pud = smooth(0.7, 0.73, tn(R, S, (8, 16, 32, 64), 0.6)) * (1 - dry)
    col = mix(col, C(0.11, 0.115, 0.12) * (0.85 + 0.3 * fine[..., None]), pud * 0.8)
    h = n * 0.25 + fine * 0.12 + dry * 0.25 + curl * 0.15 - cr * 0.45 - pud * 0.1
    img = to_img(col)
    d = ImageDraw.Draw(img)
    hm = Image.new("L", (S, S), 0)
    dh = ImageDraw.Draw(hm)
    drift = tn(R, S, (4, 8, 16), 0.6)
    for _ in range(260):
        x, y = R.random(2) * S
        if drift[int(y), int(x)] < 0.5 + R.random() * 0.15:
            continue
        a = 0.5 + R.normal(0, 0.45) + (math.pi if R.random() < 0.5 else 0)
        L = R.uniform(24, 120)
        w = R.uniform(2.0, 5.0)
        t = R.random()
        u = R.random()
        if u < 0.55:
            c = (int(150 + 50 * t), int(126 + 40 * t), int(78 + 30 * t))
        elif u < 0.8:
            c = (int(96 + 30 * t), int(86 + 24 * t), int(64 + 16 * t))
        else:
            c = (int(90 + 30 * t), int(104 + 30 * t), int(52 + 16 * t))
        ca, sa = math.cos(a), math.sin(a)
        x2, y2 = x + ca * L, y + sa * L
        for ox, oy in offs(x + ca * L / 2, y + sa * L / 2, L, S):
            if R.random() < 0.35:
                poly = leaf_poly(x + ox + ca * L / 2, y + oy + sa * L / 2, L, w * 2.2, a, tip=0.2)
                d.polygon(poly, fill=c)
                dh.polygon(poly, fill=150)
            else:
                d.line([(x + ox, y + oy), (x2 + ox, y2 + oy)], fill=c, width=int(round(w)))
                dh.line([(x + ox, y + oy), (x2 + ox, y2 + oy)], fill=170, width=int(round(w)))
                d.line([(x + ox - sa, y + oy + ca), (x2 + ox - sa, y2 + oy + ca)], fill=tuple(int(v * 0.65) for v in c), width=1)
                for k in range(1, int(L // 24) + 1):
                    nx_, ny_ = x + ox + ca * k * 24, y + oy + sa * k * 24
                    d.line([(nx_ - sa * w * 0.6, ny_ + ca * w * 0.6), (nx_ + sa * w * 0.6, ny_ - ca * w * 0.6)], fill=tuple(int(v * 0.6) for v in c), width=2)
    col = gblur(from_img(img), 0.4)
    rh = gblur(np.asarray(hm, np.float32) / 255.0, 0.8)
    h = h + rh * 0.35
    col = bake(col, h, 4.0, k=0.3, ao=0.3, ao_r=4)
    save_surface("limon", col, h, 5.0)


def roche():
    """Andésite du Mont Fumant : roche gris-brun, rugueuse, débitée en facettes ; petits cristaux
    clairs (feldspath) et aiguilles noires (hornblende) ; fissures ; lichens gris-vert et orangés,
    points noirs."""
    S = 1024
    R = rng(6905)
    n = tn(R, S, (4, 8, 16, 32, 64, 128, 256), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    wx = tn(R, S, (4, 8, 16), 0.6)
    wy = tn(R, S, (4, 8, 16), 0.6)
    # facettes : chaque cellule est un plan incliné au hasard
    d1, edge, cid, dx, dy = worley(R, S, 7, 0.85)
    tx = per_id(cid, R, -0.006, 0.006)
    ty = per_id(cid, R, -0.006, 0.006)
    tz = per_id(cid, R, 0.0, 0.25)
    facet = tx * dx + ty * dy + tz
    facet = warp(facet, (wx - 0.5) * 30, (wy - 0.5) * 30)
    edge_w = warp(edge, (wx - 0.5) * 30, (wy - 0.5) * 30)
    _, e2, _, _, _ = worley(R, S, 4, 0.9)
    e2 = warp(e2, (wy - 0.5) * 40, (wx - 0.5) * 40)
    fis = (1 - smooth(0.5, 2.6 + 2.0 * n, e2)) * smooth(0.45, 0.6, tn(R, S, (4, 8, 16), 0.6))
    seam = (1 - smooth(0.5, 2.0, edge_w)) * smooth(0.55, 0.7, tn(R, S, (4, 8, 16), 0.6))
    ridge = 1 - np.abs(tn(R, S, (8, 16, 32, 64, 128), 0.65) - 0.5) * 2
    h = facet * 1.2 + n * 0.35 + ridge * 0.3 + fine * 0.1 - fis * 0.5 - seam * 0.15
    tone = per_id(cid, R, 0.9, 1.08)
    col = mix(C(0.33, 0.31, 0.29), C(0.47, 0.43, 0.38), np.clip(n * 1.2 - 0.1, 0, 1)) * tone[..., None]
    col = col * (0.8 + 0.3 * fine[..., None])
    sp = R.random((S, S)).astype(np.float32)
    feld = gblur((sp < 0.006).astype(np.float32), 0.7) * 3.0
    col = mix(col, C(0.78, 0.76, 0.72), np.clip(feld, 0, 1) * 0.8)
    horn = gblur((sp > 0.995).astype(np.float32), 0.6) * 3.0
    col = mix(col, C(0.08, 0.07, 0.07), np.clip(horn, 0, 1) * 0.7)
    col = mix(col, C(0.1, 0.09, 0.08), np.clip(fis + seam * 0.5, 0, 1))
    col = col * (0.85 + 0.3 * ridge[..., None])
    # rouille et lichens
    rust = smooth(0.62, 0.8, tn(R, S, (4, 8, 16, 32), 0.6))
    col = mix(col, col * C(1.2, 0.92, 0.75), rust * 0.6)
    li = tn(R, S, (8, 16, 32, 64), 0.6) * 0.6 + tn(R, S, (32, 64, 128), 0.6) * 0.4
    lg = smooth(0.66, 0.7, li) * smooth(0.4, 0.6, fine)
    col = mix(col, C(0.58, 0.62, 0.52) * (0.85 + 0.3 * fine[..., None]), lg * 0.6)
    lo_ = smooth(0.72, 0.75, tn(R, S, (16, 32, 64, 128), 0.6))
    col = mix(col, C(0.72, 0.5, 0.24) * (0.85 + 0.3 * fine[..., None]), lo_ * 0.55)
    blk = gblur((R.random((S, S)) < 0.0015).astype(np.float32), 1.4) * 6
    col = mix(col, C(0.06, 0.06, 0.05), np.clip(blk, 0, 1) * smooth(0.45, 0.6, li) * 0.8)
    h = h + lg * 0.05 + lo_ * 0.03
    col = bake(col, h, 6.0, k=0.45, ao=0.35, ao_r=8)
    save_surface("roche", col, h, 7.0)


def sols():
    herbe()
    jungle()
    sable()
    limon()
    roche()


# =================================================================== le bâti (une tuile ≈ 3 m)

def speck(R, S, density, blur=0.6, H=None):
    """Grains isolés (0..1) raccordables."""
    H = H or S
    a = (R.random((H, S)) < density).astype(np.float32)
    if blur <= 0:
        return a
    b = gblur(a, blur)
    return np.clip(b / (b.max() + 1e-6) * 1.2, 0, 1)


def calcaire():
    """Parement de calcaire fin de Toura (la pyramide) : trois assises d'environ un mètre, blocs
    de 1 à 1,5 m, joints très fins, pierre blanc crème presque lisse ; patine légère : traînées
    verticales, voile de poussière ocre au pied des blocs, rares épaufrures et piqûres."""
    S = 1024
    R = rng(6911)
    bid, e, u, v = masonry(R, S, [352, 336, 336], 330, 520, rr=3.0)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    chip = tn(R, S, (16, 32, 64, 128), 0.7)
    e2 = e - np.clip(chip - 0.7, 0, 1) * 60.0
    tone = per_id(bid, R, 0.95, 1.035)
    warm = per_id(bid, R, -0.018, 0.018)
    tilt = per_id(bid, R, -0.04, 0.04)
    col = C(0.89, 0.86, 0.79) * tone[..., None] + warm[..., None] * C(1.0, 0.5, -0.6)
    col = col * (0.95 + 0.07 * mot[..., None]) * (0.975 + 0.05 * fine[..., None])
    streak = tn(R, S, (32, 64, 128, 256), 0.65, oy=(2, 4, 8, 16))
    col = col * (1 - 0.06 * smooth(0.55, 0.85, streak)[..., None])
    dust = smooth(0.55, 1.0, v) * smooth(0.4, 0.7, tn(R, S, (8, 16, 32), 0.6))
    col = mix(col, col * C(1.0, 0.93, 0.8), dust * 0.5)
    grey = smooth(0.62, 0.85, tn(R, S, (8, 16, 32, 64), 0.6))
    col = mix(col, col * C(0.88, 0.88, 0.87), grey * 0.4)
    pits = speck(R, S, 0.0025, 0.9)
    col = col * (1 - 0.35 * pits[..., None])
    fos = speck(R, S, 0.0006, 1.6)
    col = col * (1 - 0.12 * fos[..., None])
    chipd = np.clip((e - e2) / 18.0, 0, 1) * smooth(0.0, 3.0, e)
    col = mix(col, col * C(0.97, 0.93, 0.86), chipd * 0.6)
    joint = 1 - smooth(0.7, 1.8, e)
    col = mix(col, C(0.58, 0.55, 0.5), joint * 0.85)
    face = smooth(0.0, 5.0, np.maximum(e2, np.minimum(e, 1.0)))
    h = face * 0.7 + (u - 0.5) * tilt + mot * 0.08 + fine * 0.03 - pits * 0.1 - fos * 0.03
    h = h - np.clip((e - e2) / 40.0, 0, 0.5) * 0.4
    col = bake(col, h, 4.0, k=0.25, ao=0.15, ao_r=3)
    save_surface("calcaire", col, h, 4.0)


def gres():
    """Grès doré en assises réglées (temples) : six assises, blocs de 60 cm à 1,2 m, arêtes et
    coins arrondis par l'érosion, litage oblique dans chaque bloc, taches ferrugineuses, alvéoles
    d'érosion par endroits, joints de mortier sableux en retrait."""
    S = 1024
    R = rng(6912)
    bid, e, u, v = masonry(R, S, [176, 160, 184, 168, 172, 164], 210, 420, rr=16.0)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    ero = tn(R, S, (16, 32, 64, 128), 0.65)
    e2 = e - np.clip(ero - 0.42, 0, 1) * 26.0 - (fine - 0.5) * 3.0
    tone = per_id(bid, R, 0.88, 1.08)
    hue = per_id(bid, R, 0.0, 1.0)
    ang = per_id(bid, R, -0.09, 0.09)
    per = per_id(bid, R, 5.0, 11.0)
    wv = tn(R, S, (8, 16, 32), 0.6)
    strata = np.sin((yy * np.cos(ang) + xx * np.sin(ang)) / per * TAU + wv * 3.0)
    strata2 = np.sin((yy * np.cos(ang * 1.7) + xx * np.sin(ang * 1.7)) / (per * 4.3) * TAU + wv * 2.0)
    base = mix(C(0.78, 0.62, 0.42), C(0.84, 0.7, 0.5), hue)
    base = mix(base, C(0.78, 0.56, 0.4), smooth(0.8, 0.95, hue) * 0.8)
    col = base * tone[..., None] * (0.88 + 0.18 * mot[..., None]) * (0.93 + 0.12 * fine[..., None])
    col = col * (1 + 0.012 * strata[..., None] + 0.035 * strata2[..., None])
    iron = smooth(0.68, 0.82, tn(R, S, (8, 16, 32, 64), 0.6))
    col = mix(col, col * C(0.95, 0.72, 0.55), iron * 0.55)
    d1, edge, cid, _, _ = worley(R, S, 48, 0.9)
    alv = smooth(0.68, 0.8, tn(R, S, (8, 16, 32), 0.6)) * smooth(0.3, 0.8, d1 / (S / 48)) * smooth(30.0, 6.0, e)
    col = col * (1 - 0.18 * alv[..., None])
    face = smooth(0.0, 18.0, e2) ** 0.6
    joint = 1 - smooth(1.5, 3.5, e2)
    col = col * (0.75 + 0.25 * face[..., None])
    mortar = C(0.66, 0.56, 0.42) * (0.85 + 0.3 * fine[..., None])
    col = mix(col, mortar, joint)
    dirt = smooth(0.6, 0.85, tn(R, S, (16, 32, 64), 0.6, oy=(2, 4, 8)))
    col = col * (1 - 0.1 * dirt[..., None])
    h = face * 0.75 + mot * 0.1 + fine * 0.05 + strata * 0.006 - alv * 0.1 - joint * 0.1
    col = bake(col, h, 4.0, k=0.3, ao=0.25, ao_r=4)
    save_surface("gres", col, h, 5.0)


def brique():
    """Mur de briques crues (limon et paille) : briques de 40 x 20 cm en appareil alterné,
    bords mous, mortier de boue épais ; brins de paille ; un enduit de limon par plaques, écaillé."""
    S = 1024
    R = rng(6913)
    rows = 14
    rh = S / rows
    per_row = 7
    bw = S / per_row
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    r = np.floor(yy / rh).astype(np.int32)
    roff = (r % 2) * bw * 0.5 + np.take(R.uniform(-12, 12, rows).astype(np.float32), r)
    xr = np.mod(xx + roff, S)
    cidx = np.floor(xr / bw).astype(np.int32)
    bid = r * 100 + cidx
    lu = xr - cidx * bw
    lv = yy - r * rh
    dx = np.minimum(lu, bw - lu)
    dy = np.minimum(lv, rh - lv)
    rr = 9.0
    e = np.where((dx < rr) & (dy < rr), rr - np.hypot(rr - dx, rr - dy), np.minimum(dx, dy))
    wob = tn(R, S, (16, 32, 64, 128), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    e2 = e - 5.0 - (wob - 0.5) * 9.0 - np.clip(tn(R, S, (32, 64, 128), 0.7) - 0.65, 0, 1) * 30
    tone = per_id(bid, R, 0.85, 1.12)
    hue = per_id(bid, R, 0.0, 1.0)
    brick = mix(C(0.4, 0.33, 0.26), C(0.53, 0.43, 0.31), hue) * tone[..., None]
    brick = brick * (0.85 + 0.25 * mot[..., None]) * (0.9 + 0.18 * fine[..., None])
    face = smooth(0.0, 9.0, e2) ** 0.7
    mortar = C(0.46, 0.39, 0.3) * (0.85 + 0.3 * fine[..., None])
    jm = 1 - smooth(0.0, 2.5, e2)
    col = mix(brick * (0.78 + 0.22 * face[..., None]), mortar, jm)
    holes = speck(R, S, 0.0016, 1.3)
    col = col * (1 - 0.4 * holes[..., None])
    h = face * 0.6 + mot * 0.1 + fine * 0.06 - holes * 0.15
    pl = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    edge_n = tn(R, S, (64, 128, 256), 0.7)
    pv = pl + (edge_n - 0.5) * 0.08
    pm = smooth(0.585, 0.6, pv)
    trow = tn(R, S, (8, 16, 32, 64), 0.6, oy=(16, 32, 64, 128))
    plaster = C(0.6, 0.51, 0.39) * (0.86 + 0.16 * mot[..., None]) * (0.93 + 0.1 * fine[..., None]) * (0.95 + 0.1 * trow[..., None])
    rim = smooth(0.57, 0.585, pv) * (1 - pm)
    col = mix(col, plaster, pm)
    col = col * (1 - 0.25 * rim[..., None])
    h = h * (1 - pm) + (0.85 + mot * 0.08 + fine * 0.03 + trow * 0.04) * pm
    img = to_img(col)
    d = ImageDraw.Draw(img)
    for _ in range(5200):
        x, y = R.random(2) * S
        a = R.uniform(0, TAU)
        L = R.uniform(4, 13)
        t = R.random()
        c = (int(170 + 50 * t), int(140 + 40 * t), int(80 + 30 * t)) if R.random() < 0.7 else (int(120 + 30 * t), int(100 + 20 * t), int(66 + 16 * t))
        for ox, oy in offs(x, y, L, S):
            d.line([(x + ox, y + oy), (x + ox + math.cos(a) * L, y + oy + math.sin(a) * L)], fill=c, width=1)
    col = from_img(img)
    col = bake(col, h, 4.0, k=0.3, ao=0.35, ao_r=4)
    save_surface("brique", col, h, 5.0)


def enduit():
    """Enduit de chaux blanchi : blanc cassé presque neutre (la couleur viendra du matériau),
    surface un peu ondulée, coups de brosse du lait de chaux, auréoles d'humidité, salissures,
    fêlures fines et quelques éclats qui montrent la couche grise du dessous."""
    S = 1024
    R = rng(6914)
    und = tn(R, S, (4, 8, 16, 32), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    b1 = tn(R, S, (8, 16, 32, 64, 128), 0.7, oy=(32, 64, 128, 256, 512))
    b2 = tn(R, S, (32, 64, 128, 256, 512), 0.7, oy=(8, 16, 32, 64, 128))
    brush = np.where(tn(R, S, (4, 8, 16), 0.6) > 0.5, b1, b2)
    v = 0.86 + 0.035 * (und - 0.5) + 0.03 * (fine - 0.5) + 0.03 * (brush - 0.5)
    col = np.dstack([v * 1.0, v * 0.99, v * 0.965]).astype(np.float32)
    st = tn(R, S, (4, 8, 16, 32), 0.6)
    inside = smooth(0.6, 0.66, st)
    tide = np.exp(-((st - 0.6) / 0.008) ** 2)
    col = mix(col, col * C(0.95, 0.93, 0.89), inside * 0.5)
    col = mix(col, col * C(0.88, 0.85, 0.8), tide * 0.4)
    grime = smooth(0.6, 0.85, tn(R, S, (16, 32, 64, 128), 0.6, oy=(4, 8, 16, 32)))
    col = col * (1 - 0.08 * grime[..., None])
    wx = tn(R, S, (8, 16, 32), 0.6)
    wy = tn(R, S, (8, 16, 32), 0.6)
    _, edge, _, _, _ = worley(R, S, 9, 0.9)
    edge = warp(edge, (wx - 0.5) * 30, (wy - 0.5) * 30)
    cm = smooth(0.55, 0.62, tn(R, S, (4, 8, 16), 0.6))
    crack = (1 - smooth(0.3, 1.1, edge)) * cm
    _, edge2, _, _, _ = worley(R, S, 22, 0.9)
    edge2 = warp(edge2, (wy - 0.5) * 20, (wx - 0.5) * 20)
    crack = np.maximum(crack, (1 - smooth(0.2, 0.9, edge2)) * cm * smooth(0.0, 12.0, 30 - edge) * 0.7)
    col = col * (1 - 0.4 * crack[..., None])
    sp = tn(R, S, (16, 32, 64, 128), 0.65)
    spall = smooth(0.79, 0.8, sp)
    srim = smooth(0.775, 0.79, sp) * (1 - spall)
    col = mix(col, C(0.72, 0.7, 0.66) * (0.85 + 0.3 * fine[..., None]), spall)
    col = col * (1 - 0.15 * srim[..., None])
    h = und * 0.3 + fine * 0.05 + brush * 0.05 - crack * 0.25 - spall * 0.35
    col = bake(col, h, 3.0, k=0.25, ao=0.2, ao_r=3)
    save_surface("enduit", col, h, 3.0)


def pierre_maya():
    """Moellons de calcaire gris des Mayas : pierres à peu près équarries, coins arrondis, larges
    joints de mortier ; trous de dissolution, plaques de gris foncé, mousse dans les joints et sur
    les arêtes, longues coulures de lichen noir."""
    S = 1024
    R = rng(6915)
    bid, e, u, v = masonry(R, S, [118, 104, 126, 110, 122, 98, 120, 112, 114], 130, 280, rr=22.0)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    wob = tn(R, S, (16, 32, 64), 0.6)
    e2 = e - 7.0 - (wob - 0.5) * 12.0 - np.clip(tn(R, S, (32, 64, 128), 0.7) - 0.6, 0, 1) * 30
    tone = per_id(bid, R, 0.85, 1.1)
    hue = per_id(bid, R, 0.0, 1.0)
    stone = mix(C(0.6, 0.6, 0.57), C(0.66, 0.63, 0.56), hue) * tone[..., None]
    stone = stone * (0.82 + 0.3 * mot[..., None]) * (0.9 + 0.18 * fine[..., None])
    dark = smooth(0.58, 0.75, tn(R, S, (8, 16, 32, 64), 0.6))
    stone = mix(stone, stone * C(0.66, 0.66, 0.64), dark * 0.7)
    pits = speck(R, S, 0.003, 1.2)
    stone = stone * (1 - 0.5 * pits[..., None])
    face = smooth(0.0, 14.0, e2) ** 0.6
    jm = 1 - smooth(-1.0, 1.5, e2)
    mortar = C(0.56, 0.54, 0.48) * (0.75 + 0.45 * fine[..., None]) * (0.9 + 0.2 * mot[..., None])
    col = mix(stone * (0.72 + 0.28 * face[..., None]), mortar, jm)
    mz = tn(R, S, (8, 16, 32, 64), 0.6)
    near = smooth(10.0, 0.0, e2) * (1 - jm * 0.3) + jm
    moss = smooth(0.5, 0.65, mz) * np.clip(near + smooth(0.3, 0.0, v) * smooth(0.6, 0.7, mz), 0, 1)
    moss = moss * smooth(0.3, 0.6, fine + 0.15)
    col = mix(col, C(0.26, 0.34, 0.14) * (0.7 + 0.5 * fine[..., None]), moss * 0.85)
    stk = tn(R, S, (32, 64, 128, 256), 0.65, oy=(4, 8, 16, 32))
    stm = tn(R, S, (8, 16, 32), 0.6)
    black = smooth(0.6, 0.85, stk) * smooth(0.5, 0.65, stm) * (0.6 + 0.4 * fine)
    col = mix(col, C(0.14, 0.14, 0.13), black * 0.5)
    h = face * 0.7 + mot * 0.12 + fine * 0.08 - pits * 0.15 - jm * 0.1 + moss * 0.08
    col = bake(col, h, 4.0, k=0.3, ao=0.35, ao_r=5)
    save_surface("pierre_maya", col, h, 6.0)


def stuc_rouge():
    """Stuc rouge maya (hématite) : rouge profond, coups de lissoir, plus rosé là où il a pâli ;
    usé par plaques jusqu'à l'enduit blanc, et par endroits jusqu'à la pierre grise ; salissures,
    fêlures."""
    S = 1024
    R = rng(6916)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    b1 = tn(R, S, (8, 16, 32, 64), 0.7, oy=(32, 64, 128, 256))
    b2 = tn(R, S, (32, 64, 128, 256), 0.7, oy=(8, 16, 32, 64))
    brush = np.where(tn(R, S, (4, 8, 16), 0.6) > 0.5, b1, b2)
    red = mix(C(0.5, 0.14, 0.1), C(0.64, 0.2, 0.13), mot) * (0.92 + 0.12 * brush[..., None]) * (0.95 + 0.08 * fine[..., None])
    pale = smooth(0.55, 0.8, tn(R, S, (4, 8, 16, 32), 0.6))
    red = mix(red, C(0.68, 0.36, 0.3), pale * 0.35)
    wear = tn(R, S, (8, 16, 32, 64, 128), 0.6)
    edge_n = tn(R, S, (128, 256, 512), 0.7)
    wv = wear + (edge_n - 0.5) * 0.06
    white = smooth(0.7, 0.715, wv)
    stone = smooth(0.83, 0.85, wv)
    rim = np.exp(-((wv - 0.708) / 0.006) ** 2)
    plaster = C(0.86, 0.82, 0.74) * (0.9 + 0.12 * fine[..., None]) * (0.95 + 0.06 * mot[..., None])
    plaster = mix(plaster, C(0.8, 0.62, 0.55), smooth(0.74, 0.72, wv) * 0.35)
    grey = C(0.6, 0.58, 0.53) * (0.8 + 0.35 * fine[..., None])
    col = mix(red, plaster, white)
    col = mix(col, grey, stone)
    col = col * (1 - 0.3 * rim[..., None])
    grime = smooth(0.6, 0.85, tn(R, S, (16, 32, 64), 0.6, oy=(4, 8, 16)))
    col = col * (1 - 0.2 * grime[..., None])
    wx = tn(R, S, (8, 16, 32), 0.6)
    wy = tn(R, S, (8, 16, 32), 0.6)
    _, edge, _, _, _ = worley(R, S, 10, 0.9)
    edge = warp(edge, (wx - 0.5) * 30, (wy - 0.5) * 30)
    crack = (1 - smooth(0.3, 1.2, edge)) * smooth(0.5, 0.6, tn(R, S, (4, 8, 16), 0.6))
    col = col * (1 - 0.45 * crack[..., None])
    h = 0.6 - white * 0.15 - stone * 0.2 + mot * 0.1 + fine * 0.04 + brush * 0.03 - crack * 0.2
    col = bake(col, h, 4.0, k=0.25, ao=0.2, ao_r=3)
    save_surface("stuc_rouge", col, h, 4.0)


def tezontle():
    """Blocs de tezontle (Aztlán) : pierre volcanique poreuse rouge-brun, lie-de-vin, presque
    noire pour quelques blocs, criblée de vacuoles ; joints larges de mortier de chaux gris clair
    piqué d'éclats de tezontle."""
    S = 1024
    R = rng(6917)
    bid, e, u, v = masonry(R, S, [150, 170, 160, 180, 190, 174], 160, 300, rr=20.0)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    wob = tn(R, S, (16, 32, 64), 0.6)
    e2 = e - 8.0 - (wob - 0.5) * 12.0 - np.clip(tn(R, S, (32, 64, 128), 0.7) - 0.6, 0, 1) * 34
    tone = per_id(bid, R, 0.85, 1.12)
    hue = per_id(bid, R, 0.0, 1.0)
    base = np.where((hue < 0.45)[..., None], C(0.46, 0.22, 0.16),
                    np.where((hue < 0.75)[..., None], C(0.36, 0.17, 0.14),
                             np.where((hue < 0.92)[..., None], C(0.54, 0.29, 0.2), C(0.22, 0.13, 0.12))))
    stone = base * tone[..., None] * (0.8 + 0.35 * mot[..., None]) * (0.85 + 0.3 * fine[..., None])
    img = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(img)
    for _ in range(26000):
        x, y = R.random(2) * S
        r = R.uniform(0.8, 2.2) if R.random() < 0.8 else R.uniform(2.2, 5.5)
        k = R.uniform(0.6, 1.0)
        for ox, oy in offs(x, y, r + 1, S):
            d.ellipse((x + ox - r, y + oy - r * k, x + ox + r, y + oy + r * k), fill=255)
    pore = gblur(np.asarray(img, np.float32) / 255.0, 0.6)
    psh = warp(pore, -1.2, -1.2)
    stone = stone * (1 - 0.7 * pore[..., None]) * (1 + 0.25 * np.clip(psh - pore, 0, 1)[..., None])
    face = smooth(0.0, 14.0, e2) ** 0.6
    jm = 1 - smooth(-1.0, 1.5, e2)
    mortar = C(0.66, 0.64, 0.6) * (0.8 + 0.35 * fine[..., None]) * (0.92 + 0.14 * mot[..., None])
    chips = speck(R, S, 0.004, 1.0)
    mortar = mix(mortar, C(0.42, 0.2, 0.15), np.clip(chips * 3, 0, 1) * 0.8)
    col = mix(stone * (0.75 + 0.25 * face[..., None]), mortar, jm)
    dirt = smooth(0.6, 0.85, tn(R, S, (16, 32, 64), 0.6, oy=(4, 8, 16)))
    col = col * (1 - 0.15 * dirt[..., None])
    h = face * 0.6 + mot * 0.1 + fine * 0.12 - pore * (1 - jm) * 0.35 - jm * 0.1
    col = bake(col, h, 4.0, k=0.3, ao=0.3, ao_r=4)
    save_surface("tezontle", col, h, 6.0)


def dalles_soleil():
    """Grandes dalles irrégulières de calcaire clair (places, sols des temples) : polygones de
    60 cm à 1 m, chacune un peu penchée, polie au centre, arêtes émoussées ; joints de terre où
    pousse un peu d'herbe ; fossiles, piqûres, quelques fêlures, lichens blancs et orangés."""
    S = 1024
    R = rng(6918)
    wx = tn(R, S, (8, 16, 32), 0.6)
    wy = tn(R, S, (8, 16, 32), 0.6)
    d1, edge, cid, dx, dy = worley(R, S, 5, 0.75)
    ax, ay = (wx - 0.5) * 16, (wy - 0.5) * 16
    edge = warp(edge, ax, ay)
    cidw = np.round(warp(cid.astype(np.float32), ax, ay)).astype(np.int32)
    dx = warp(dx, ax, ay)
    dy = warp(dy, ax, ay)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    chip = tn(R, S, (16, 32, 64, 128), 0.7)
    e2 = edge - 2.6 - np.clip(chip - 0.66, 0, 1) * 14.0
    tone = per_id(cidw, R, 0.86, 1.08)
    hue = per_id(cidw, R, 0.0, 1.0)
    tx = per_id(cidw, R, -0.0008, 0.0008)
    ty = per_id(cidw, R, -0.0008, 0.0008)
    slab = mix(C(0.84, 0.8, 0.7), C(0.86, 0.79, 0.66), hue) * tone[..., None]
    slab = slab * (0.9 + 0.14 * mot[..., None]) * (0.95 + 0.08 * fine[..., None])
    polish = smooth(10.0, 60.0, edge)
    slab = slab * (0.96 + 0.05 * polish[..., None])
    fos = speck(R, S, 0.0008, 1.5)
    pits = speck(R, S, 0.002, 0.9)
    slab = slab * (1 - 0.15 * fos[..., None] - 0.35 * pits[..., None])
    grime = smooth(24.0, 3.0, e2) * (0.5 + 0.5 * tn(R, S, (16, 32, 64), 0.6))
    slab = mix(slab, slab * C(0.84, 0.8, 0.74), grime * 0.5)
    li = smooth(0.7, 0.74, tn(R, S, (16, 32, 64, 128), 0.6))
    slab = mix(slab, C(0.92, 0.92, 0.88), li * 0.35)
    lo = smooth(0.78, 0.8, tn(R, S, (32, 64, 128), 0.6)) * smooth(0.5, 0.6, fine)
    slab = mix(slab, C(0.8, 0.6, 0.32), lo * 0.45)
    _, e3, _, _, _ = worley(R, S, 9, 0.9)
    e3 = warp(e3, (wy - 0.5) * 40, (wx - 0.5) * 40)
    crk = (1 - smooth(0.3, 1.3, e3)) * smooth(0.6, 0.66, tn(R, S, (4, 8, 16), 0.6)) * smooth(2.0, 8.0, e2)
    slab = slab * (1 - 0.45 * crk[..., None])
    face = smooth(0.0, 10.0, e2) ** 0.6
    jm = 1 - smooth(-1.0, 1.0, e2)
    soil = C(0.42, 0.36, 0.27) * (0.7 + 0.5 * fine[..., None])
    gr = smooth(0.55, 0.7, tn(R, S, (16, 32, 64), 0.6)) * smooth(0.45, 0.6, fine)
    soil = mix(soil, C(0.24, 0.36, 0.12) * (0.7 + 0.5 * fine[..., None]), gr)
    col = mix(slab * (0.8 + 0.2 * face[..., None]), soil, jm)
    h = face * 0.6 + (tx * dx + ty * dy) * 20.0 * face + mot * 0.06 + fine * 0.03 - pits * 0.1 - crk * 0.15 - jm * 0.1 + gr * jm * 0.12
    col = bake(col, h, 4.0, k=0.3, ao=0.3, ao_r=4)
    save_surface("dalles_soleil", col, h, 5.0)


def pierre_sombre():
    """Pierre de taille sombre des souterrains : gros blocs gris-brun, arêtes épaufrées,
    suintements et coulures d'eau, efflorescences blanches de salpêtre le long des joints,
    algues noir-vert, grandes traînées de suie au-dessus des anciennes torches."""
    S = 1024
    R = rng(6919)
    bid, e, u, v = masonry(R, S, [256, 256, 256, 256], 300, 560, rr=6.0)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    chip = tn(R, S, (16, 32, 64, 128), 0.7)
    e2 = e - 2.0 - np.clip(chip - 0.55, 0, 1) * 40.0
    tone = per_id(bid, R, 0.82, 1.12)
    hue = per_id(bid, R, 0.0, 1.0)
    stone = mix(C(0.29, 0.27, 0.25), C(0.34, 0.31, 0.27), hue) * tone[..., None]
    stone = stone * (0.8 + 0.35 * mot[..., None]) * (0.88 + 0.2 * fine[..., None])
    wet = smooth(0.5, 0.75, tn(R, S, (8, 16, 32, 64), 0.6, oy=(4, 8, 16, 32)))
    stone = mix(stone, stone * C(0.66, 0.68, 0.7), wet * 0.7)
    drip = smooth(0.62, 0.85, tn(R, S, (32, 64, 128, 256), 0.65, oy=(4, 8, 16, 32))) * smooth(0.45, 0.6, mot)
    stone = stone * (1 - 0.18 * drip[..., None])
    soot = smooth(0.45, 0.85, tn(R, S, (4, 8, 16, 32, 64), 0.7, oy=(2, 4, 8, 16, 32)))
    stone = mix(stone, C(0.06, 0.055, 0.05), soot * 0.55)
    face = smooth(0.0, 8.0, e2) ** 0.6
    jm = 1 - smooth(-0.5, 2.0, e2)
    mortar = C(0.2, 0.19, 0.18) * (0.8 + 0.4 * fine[..., None])
    col = mix(stone * (0.7 + 0.3 * face[..., None]), mortar, jm)
    salt = smooth(16.0, 0.0, e2) * smooth(0.6, 0.75, tn(R, S, (16, 32, 64, 128), 0.65)) * (1 - soot)
    col = mix(col, C(0.66, 0.66, 0.62) * (0.8 + 0.4 * fine[..., None]), salt * 0.55)
    alg = smooth(14.0, 0.0, e2) * smooth(0.55, 0.7, tn(R, S, (8, 16, 32, 64), 0.6)) * smooth(0.4, 1.0, v)
    col = mix(col, C(0.08, 0.12, 0.07), alg * 0.6)
    col = col + (wet * smooth(0.6, 0.8, fine))[..., None] * C(0.03, 0.035, 0.04)
    h = face * 0.6 + mot * 0.12 + fine * 0.08 - jm * 0.1 - np.clip((e - e2) / 40.0, 0, 0.5) * 0.4
    col = bake(col, h, 4.0, k=0.35, ao=0.35, ao_r=5)
    save_surface("pierre_sombre", col, h, 6.0)


# =================================================================== le crayon : signes, glyphes

def down(a, k):
    """Réduction exacte k x k (moyenne) : garde le raccord d'une image raccordable."""
    H, W = a.shape[:2]
    if a.ndim == 2:
        return a.reshape(H // k, k, W // k, k).mean(axis=(1, 3)).astype(np.float32)
    return a.reshape(H // k, k, W // k, k, a.shape[2]).mean(axis=(1, 3)).astype(np.float32)


def ellp(cx, cy, rx, ry, a0=0.0, a1=360.0, n=36):
    """Points d'une ellipse (angles en degrés, 0 = droite, 90 = bas)."""
    return [(cx + rx * math.cos(math.radians(a0 + (a1 - a0) * k / n)), cy + ry * math.sin(math.radians(a0 + (a1 - a0) * k / n))) for k in range(n + 1)]


def tube(pts, w0, w1=None):
    """Un boudin de largeur w0 -> w1 autour d'une ligne (serpents, bras, tiges)."""
    w1 = w0 if w1 is None else w1
    n = len(pts)
    left, right = [], []
    for i, (x, y) in enumerate(pts):
        a = pts[max(i - 1, 0)]
        b = pts[min(i + 1, n - 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dy) or 1e-6
        nx, ny = -dy / L, dx / L
        w = (w0 + (w1 - w0) * i / max(1, n - 1)) * 0.5
        left.append((x + nx * w, y + ny * w))
        right.append((x - nx * w, y - ny * w))
    return left + right[::-1]


PAL_EG = {"ink": (30, 24, 20, 255), "red": (172, 62, 38, 255), "blue": (44, 98, 156, 255), "green": (48, 122, 92, 255),
          "yellow": (216, 164, 64, 255), "white": (236, 228, 206, 255), "skin": (170, 84, 50, 255), "gold": (214, 164, 62, 255),
          "black": (34, 30, 28, 255), "lskin": (222, 170, 110, 255), "cream": (240, 232, 210, 255)}


class Pen:
    """Dessine dans une boîte (x0, y0, largeur, hauteur) en coordonnées 0..1 (y vers le bas) :
    la couleur (RGBA), la silhouette (L, « shp ») et les traits intérieurs (L, « lin »).
    Les mêmes signes servent aux murs peints, aux papyrus, aux pierres gravées et aux icônes."""

    def __init__(self, box, col=None, shp=None, lin=None, pal=None, lw=0.035, flip=False, ink=None):
        self.x0, self.y0, self.w, self.h = box
        self.dc = ImageDraw.Draw(col) if col is not None else None
        self.ds = ImageDraw.Draw(shp) if shp is not None else None
        self.dl = ImageDraw.Draw(lin) if lin is not None else None
        self.pal = dict(PAL_EG)
        if pal:
            self.pal.update(pal)
        if ink is not None:
            self.pal["ink"] = ink
        self.lw = lw
        self.flip = flip
        self.s = min(self.w, self.h)

    def sub(self, x, y, w, h, flip=None):
        """Un crayon pour une sous-boîte (coordonnées de cette boîte-ci)."""
        p = Pen.__new__(Pen)
        p.__dict__.update(self.__dict__)
        if self.flip:
            x = 1 - x - w
        p.x0, p.y0, p.w, p.h = self.x0 + x * self.w, self.y0 + y * self.h, w * self.w, h * self.h
        p.s = min(p.w, p.h)
        p.flip = self.flip if flip is None else (self.flip != flip)
        return p

    def P(self, pts):
        if self.flip:
            return [(self.x0 + (1 - x) * self.w, self.y0 + y * self.h) for x, y in pts]
        return [(self.x0 + x * self.w, self.y0 + y * self.h) for x, y in pts]

    def c(self, k):
        return self.pal.get(k, (255, 0, 255, 255)) if isinstance(k, str) else k

    def W(self, w=None):
        return max(1, int(round((self.lw if w is None else w) * self.s)))

    def _ol(self, q, w=None, closed=True):
        if closed:
            q = q + [q[0]]
        ww = self.W(w)
        if self.dc:
            self.dc.line(q, fill=self.c("ink"), width=ww, joint="curve")
        if self.dl:
            self.dl.line(q, fill=255, width=ww, joint="curve")
        if self.ds:
            self.ds.line(q, fill=255, width=ww, joint="curve")

    def poly(self, pts, fill="red", ol=True, w=None, sm=0):
        if sm:
            pts = chaikin(pts, sm)
        q = self.P(pts)
        if fill is not None:
            if self.dc:
                self.dc.polygon(q, fill=self.c(fill))
            if self.ds:
                self.ds.polygon(q, fill=255)
            if self.dl:
                self.dl.polygon(q, fill=0)
        if ol:
            self._ol(q, w)

    def ell(self, cx, cy, rx, ry, fill="red", ol=True, w=None):
        self.poly(ellp(cx, cy, rx, ry, n=40), fill, ol, w)

    def cut(self, pts, sm=0):
        """Une surface creusée (et encrée) : un trou du dessin, gravé."""
        if sm:
            pts = chaikin(pts, sm)
        q = self.P(pts)
        if self.dc:
            self.dc.polygon(q, fill=self.c("ink"))
        if self.dl:
            self.dl.polygon(q, fill=255)

    def hole(self, pts, sm=0, ol=True):
        """Un vrai trou (transparent) dans la silhouette."""
        if sm:
            pts = chaikin(pts, sm)
        q = self.P(pts)
        if self.dc:
            self.dc.polygon(q, fill=(0, 0, 0, 0))
        if self.ds:
            self.ds.polygon(q, fill=0)
        if self.dl:
            self.dl.polygon(q, fill=0)
        if ol:
            self._ol(q)

    def line(self, pts, w=None, c="ink"):
        q = self.P(pts)
        ww = self.W(w)
        if self.dc:
            self.dc.line(q, fill=self.c(c), width=ww, joint="curve")
        if self.dl:
            self.dl.line(q, fill=255, width=ww, joint="curve")

    def stroke(self, pts, w, fill="red", ol=True):
        """Un trait épais qui fait partie de la forme (bâton, anneau, tige)."""
        q = self.P(pts)
        ww = self.W(w)
        ow = ww + 2 * self.W()
        if ol:
            if self.dc:
                self.dc.line(q, fill=self.c("ink"), width=ow, joint="curve")
                for e in (q[0], q[-1]):
                    self.dc.ellipse((e[0] - ow / 2, e[1] - ow / 2, e[0] + ow / 2, e[1] + ow / 2), fill=self.c("ink"))
            if self.dl:
                self.dl.line(q, fill=255, width=ow, joint="curve")
        if self.dc:
            self.dc.line(q, fill=self.c(fill), width=ww, joint="curve")
            for e in (q[0], q[-1]):
                self.dc.ellipse((e[0] - ww / 2, e[1] - ww / 2, e[0] + ww / 2, e[1] + ww / 2), fill=self.c(fill))
        if self.ds:
            self.ds.line(q, fill=255, width=ow if ol else ww, joint="curve")
            for e in (q[0], q[-1]):
                r = (ow if ol else ww) / 2
                self.ds.ellipse((e[0] - r, e[1] - r, e[0] + r, e[1] + r), fill=255)
        if self.dl:
            self.dl.line(q, fill=0, width=max(1, ww - 1), joint="curve")

    def dot(self, cx, cy, r, c="ink"):
        q = self.P([(cx - r, cy - r), (cx + r, cy + r)])
        rr = r * self.s
        (x, y) = self.P([(cx, cy)])[0]
        if self.dc:
            self.dc.ellipse((x - rr, y - rr, x + rr, y + rr), fill=self.c(c))
        if self.dl:
            self.dl.ellipse((x - rr, y - rr, x + rr, y + rr), fill=255)
        del q

    def ring(self, cx, cy, r, w=None, c="ink"):
        (x, y) = self.P([(cx, cy)])[0]
        rr = r * self.s
        ww = self.W(w)
        if self.dc:
            self.dc.ellipse((x - rr, y - rr, x + rr, y + rr), outline=self.c(c), width=ww)
        if self.dl:
            self.dl.ellipse((x - rr, y - rr, x + rr, y + rr), outline=255, width=ww)

    def disc(self, cx, cy, r, fill="red", ol=True):
        """Un disque vraiment rond (rayon en unités de la petite dimension)."""
        (x, y) = self.P([(cx, cy)])[0]
        rr = r * self.s
        ow = self.W() if ol else 0
        if self.dc:
            if ol:
                self.dc.ellipse((x - rr - ow / 2, y - rr - ow / 2, x + rr + ow / 2, y + rr + ow / 2), fill=self.c("ink"))
            self.dc.ellipse((x - rr + ow / 2, y - rr + ow / 2, x + rr - ow / 2, y + rr - ow / 2), fill=self.c(fill))
        if self.ds:
            self.ds.ellipse((x - rr - ow / 2, y - rr - ow / 2, x + rr + ow / 2, y + rr + ow / 2), fill=255)
        if self.dl:
            if ol:
                self.dl.ellipse((x - rr - ow / 2, y - rr - ow / 2, x + rr + ow / 2, y + rr + ow / 2), fill=255)
            self.dl.ellipse((x - rr + ow / 2, y - rr + ow / 2, x + rr - ow / 2, y + rr - ow / 2), fill=0)


# ------------------------------------------------------------------- hiéroglyphes (tournés vers la gauche)

def eg_vulture(p):
    p.poly([(0.3, 0.3), (0.46, 0.2), (0.66, 0.24), (0.84, 0.42), (0.99, 0.74), (0.84, 0.76), (0.62, 0.68), (0.4, 0.64), (0.28, 0.5)], "yellow", sm=1)
    p.line(bez((0.42, 0.34), (0.66, 0.4), (0.92, 0.7)), 0.03)
    p.line(bez((0.46, 0.5), (0.66, 0.56), (0.86, 0.72)), 0.03)
    p.poly([(0.36, 0.32), (0.27, 0.16), (0.16, 0.08), (0.07, 0.1), (0.03, 0.17), (0.12, 0.19), (0.19, 0.24), (0.27, 0.42)], "blue", sm=1)
    p.dot(0.13, 0.13, 0.02)
    for x0, x1 in ((0.45, 0.42), (0.58, 0.6)):
        p.stroke([(x0, 0.64), (x1, 0.94)], 0.05, "red")
    p.line([(0.33, 0.96), (0.47, 0.96)], 0.04)
    p.line([(0.55, 0.96), (0.69, 0.96)], 0.04)


def eg_reed(p):
    p.poly([(0.6, 0.0), (0.82, 0.22), (0.92, 0.55), (0.84, 0.9), (0.55, 1.0), (0.24, 0.94), (0.1, 0.62), (0.18, 0.32), (0.38, 0.24), (0.3, 0.15), (0.48, 0.1)], "green", sm=1)
    p.line(bez((0.55, 0.12), (0.52, 0.5), (0.55, 0.94)), 0.05)


def eg_arm(p):
    p.poly([(1.0, 0.22), (0.34, 0.28), (0.26, 0.02), (0.15, 0.04), (0.17, 0.32), (0.03, 0.36), (0.0, 0.62), (0.12, 0.82), (0.32, 0.86), (1.0, 0.82)], "skin", sm=1)


def eg_foot(p):
    p.poly([(0.6, 0.0), (0.88, 0.0), (0.9, 0.62), (0.98, 0.84), (0.94, 1.0), (0.03, 1.0), (0.0, 0.88), (0.1, 0.8), (0.5, 0.66), (0.6, 0.5)], "skin", sm=1)


def eg_stool(p):
    p.poly([(0.1, 0.1), (0.9, 0.1), (0.9, 0.9), (0.1, 0.9)], "blue")
    p.line([(0.1, 0.72), (0.9, 0.72)], 0.05)


def eg_viper(p):
    body = [(0.13, 0.42), (0.17, 0.68), (0.34, 0.8), (0.6, 0.76), (0.82, 0.74), (0.95, 0.6), (0.9, 0.44)]
    p.poly(tube(chaikin(body, 2, False), 0.26, 0.08), "yellow", sm=0)
    p.poly([(0.04, 0.38), (0.1, 0.25), (0.22, 0.26), (0.24, 0.44), (0.1, 0.48)], "yellow", sm=1)
    p.line([(0.1, 0.27), (0.06, 0.02)], 0.05)
    p.line([(0.18, 0.27), (0.22, 0.04)], 0.05)
    for x in (0.3, 0.44, 0.58, 0.72):
        p.dot(x, 0.76, 0.04, "red")


def eg_owl(p):
    p.poly([(0.22, 0.32), (0.66, 0.26), (0.84, 0.5), (0.98, 0.9), (0.62, 0.94), (0.32, 0.86), (0.2, 0.6)], "yellow", sm=1)
    p.line(bez((0.4, 0.4), (0.7, 0.45), (0.92, 0.86)), 0.03)
    p.ell(0.33, 0.22, 0.24, 0.2, "yellow")
    p.ring(0.23, 0.2, 0.06, 0.03)
    p.ring(0.43, 0.2, 0.06, 0.03)
    p.poly([(0.31, 0.27), (0.35, 0.27), (0.33, 0.35)], "ink", ol=False)
    for x in (0.36, 0.52):
        p.stroke([(x, 0.86), (x, 0.97)], 0.05, "red")


def eg_water(p):
    n = 9
    top = [(k / (2 * n), 0.22 if k % 2 == 0 else 0.02) for k in range(2 * n + 1)]
    bot = [(x, y + 0.72) for x, y in top]
    p.poly(top + bot[::-1], "blue", w=0.05)


def eg_mouth(p):
    top = [(x, 0.5 - 0.44 * math.sin(math.pi * x) ** 0.7) for x in np.linspace(0, 1, 20)]
    bot = [(x, 0.5 + 0.44 * math.sin(math.pi * x) ** 0.7) for x in np.linspace(1, 0, 20)]
    p.poly(top + bot, "red")
    p.line([(0.12, 0.5), (0.88, 0.5)], 0.04)


def eg_shelter(p):
    p.stroke([(0.38, 0.14), (0.1, 0.14), (0.1, 0.9), (0.9, 0.9), (0.9, 0.14), (0.62, 0.14)], 0.13, "blue")
    p.stroke([(0.62, 0.14), (0.62, 0.6)], 0.1, "blue")


def eg_flax(p):
    p.stroke([(0.5, 0.04), (0.5, 0.96)], 0.12, "green")
    for y in (0.16, 0.42, 0.68):
        p.stroke(ellp(0.5, y, 0.4, 0.12, 200, 520, 30), 0.12, "green")


def eg_placenta(p):
    p.disc(0.5, 0.5, 0.42, "yellow")
    for k in range(-2, 3):
        o = k * 0.16
        p.line([(0.25 + o, 0.2 + abs(o) * 0.1), (0.75 + o, 0.8 - abs(o) * 0.1)], 0.04)


def eg_cloth(p):
    p.poly([(0.24, 1.0), (0.76, 1.0), (0.72, 0.4), (0.9, 0.16), (0.62, 0.0), (0.3, 0.14), (0.28, 0.4)], "red", sm=1)
    p.line(bez((0.32, 0.38), (0.6, 0.3), (0.8, 0.18)), 0.04)


def eg_pool(p):
    p.poly([(0.02, 0.06), (0.98, 0.06), (0.98, 0.94), (0.02, 0.94)], "blue")
    for y in (0.3, 0.52, 0.74):
        p.line([(0.1 + k * 0.08, y + (0.06 if k % 2 else -0.04)) for k in range(11)], 0.03)


def eg_hill(p):
    p.poly(ellp(0.5, 0.95, 0.48, 0.85, 180, 360, 30), "yellow")
    for (x, y) in ((0.3, 0.7), (0.5, 0.5), (0.7, 0.7), (0.4, 0.85), (0.6, 0.85), (0.5, 0.3)):
        p.dot(x, y, 0.05, "red")


def eg_basket(p):
    p.poly([(0.02, 0.1)] + ellp(0.42, 0.1, 0.4, 0.85, 180, 0, 24)[::-1] + [(0.82, 0.1)], "green")
    p.stroke(ellp(0.86, 0.62, 0.12, 0.22, 0, 360, 24), 0.08, "green")
    for x in (0.18, 0.32, 0.46, 0.6):
        p.line([(x, 0.16), (x + 0.06, 0.7)], 0.03)


def eg_jarstand(p):
    p.poly([(0.0, 0.05), (1.0, 0.05), (0.88, 0.5), (1.0, 0.95), (0.0, 0.95), (0.12, 0.5)], "red", sm=1)


def eg_bread(p):
    p.poly(ellp(0.5, 0.95, 0.5, 0.9, 180, 360, 30), "red")


def eg_hand(p):
    p.poly([(1.0, 0.3), (0.62, 0.26), (0.56, 0.0), (0.44, 0.02), (0.46, 0.28), (0.06, 0.32), (0.0, 0.48), (0.06, 0.62), (0.3, 0.66),
            (0.08, 0.7), (0.04, 0.84), (0.6, 0.92), (1.0, 0.82)], "skin", sm=1)
    p.line([(0.08, 0.48), (0.4, 0.48)], 0.03)


def eg_cobra(p):
    coil = chaikin([(0.3, 0.86), (0.6, 0.94), (0.92, 0.88), (0.9, 0.7), (0.6, 0.68), (0.4, 0.72)], 2, False)
    p.poly(tube(coil, 0.14, 0.1), "green")
    p.poly([(0.36, 0.82), (0.22, 0.6), (0.12, 0.34), (0.16, 0.12), (0.3, 0.02), (0.44, 0.14), (0.46, 0.4), (0.5, 0.7)], "green", sm=1)
    p.poly([(0.16, 0.12), (0.02, 0.14), (0.04, 0.2), (0.18, 0.2)], "green", sm=1)
    p.line(bez((0.3, 0.12), (0.32, 0.4), (0.44, 0.72)), 0.03)


def eg_ankh(p, fill="blue"):
    p.stroke(ellp(0.5, 0.24, 0.24, 0.2, 0, 360, 36), 0.13, fill)
    p.poly([(0.42, 0.42), (0.58, 0.42), (0.66, 1.0), (0.34, 1.0)], fill)
    p.poly([(0.02, 0.43), (0.98, 0.43), (0.98, 0.57), (0.02, 0.57)], fill)


def eg_djed(p):
    p.poly([(0.32, 0.4), (0.68, 0.4), (0.7, 0.92), (0.3, 0.92)], "green")
    p.poly([(0.2, 0.92), (0.8, 0.92), (0.8, 1.0), (0.2, 1.0)], "green")
    for k in range(4):
        y = 0.04 + k * 0.095
        p.poly([(0.04, y), (0.96, y), (0.96, y + 0.07), (0.04, y + 0.07)], "blue" if k % 2 == 0 else "red")


def eg_was(p):
    p.stroke([(0.52, 0.18), (0.5, 0.86)], 0.18, "yellow")
    p.poly([(0.42, 0.22), (0.1, 0.1), (0.04, 0.02), (0.48, 0.04), (0.62, 0.0), (0.62, 0.2)], "yellow", sm=1)
    p.stroke([(0.5, 0.84), (0.3, 1.0)], 0.12, "yellow")
    p.stroke([(0.5, 0.84), (0.7, 1.0)], 0.12, "yellow")


def eg_sun(p, fill="red"):
    p.disc(0.5, 0.5, 0.44, fill)
    p.dot(0.5, 0.5, 0.09)


def eg_house(p):
    p.stroke([(0.4, 0.9), (0.08, 0.9), (0.08, 0.1), (0.92, 0.1), (0.92, 0.9), (0.6, 0.9)], 0.15, "red")


def eg_scarab(p, fill="blue"):
    for k, y in enumerate((0.38, 0.56, 0.74)):
        for sg in (-1, 1):
            p.stroke([(0.5 + sg * 0.25, y), (0.5 + sg * 0.42, y + (-0.1 if k == 0 else 0.06)), (0.5 + sg * 0.46, y + (-0.04 if k == 0 else 0.14))], 0.05, "ink", ol=False)
    p.ell(0.5, 0.62, 0.27, 0.34, fill)
    p.line([(0.5, 0.4), (0.5, 0.95)], 0.03)
    p.line(bez((0.24, 0.42), (0.5, 0.48), (0.76, 0.42)), 0.03)
    p.ell(0.5, 0.26, 0.17, 0.1, fill)
    p.poly([(0.36, 0.2), (0.5, 0.06), (0.64, 0.2)], fill, sm=1)


def eg_feather(p, fill="white"):
    pts = [(0.3, 1.0), (0.28, 0.5), (0.34, 0.16), (0.52, 0.0), (0.84, 0.04), (0.86, 0.14), (0.66, 0.16), (0.68, 0.5), (0.62, 1.0)]
    p.poly(pts, fill, sm=1)
    p.line(bez((0.46, 0.98), (0.44, 0.5), (0.5, 0.12)), 0.03)
    for y in (0.3, 0.5, 0.7):
        p.line([(0.32, y), (0.64, y - 0.03)], 0.02, "blue")


def eg_nfr(p):
    p.ell(0.5, 0.74, 0.34, 0.24, "red")
    p.stroke([(0.5, 0.04), (0.5, 0.5)], 0.08, "ink", ol=False)
    for y in (0.18, 0.3):
        p.line([(0.34, y), (0.66, y)], 0.05)


def eg_star(p):
    pts = []
    for k in range(10):
        a = -90 + k * 36
        r = 0.48 if k % 2 == 0 else 0.16
        pts.append((0.5 + math.cos(math.radians(a)) * r, 0.52 + math.sin(math.radians(a)) * r))
    p.poly(pts, "yellow")


def eg_neb(p):
    p.poly([(0.0, 0.08), (1.0, 0.08)] + ellp(0.5, 0.08, 0.5, 0.88, 0, 180, 24), "green")
    for x in (0.2, 0.35, 0.5, 0.65, 0.8):
        p.line([(x, 0.14), (x, 0.7 - abs(x - 0.5) * 0.6)], 0.03)


def eg_seated(p):
    p.poly([(0.36, 0.3), (0.58, 0.32), (0.66, 0.62), (0.96, 0.66), (0.96, 0.98), (0.42, 0.98), (0.36, 0.7)], "white", sm=1)
    p.poly([(0.2, 0.68), (0.52, 0.64), (0.54, 0.74), (0.2, 0.78)], "skin", sm=1)
    p.ell(0.45, 0.17, 0.17, 0.15, "skin")
    p.poly([(0.42, 0.02), (0.66, 0.06), (0.66, 0.34), (0.5, 0.36), (0.5, 0.14)], "black", sm=1)
    p.stroke([(0.2, 0.98), (0.4, 0.98)], 0.05, "skin", ol=False)


def eg_sedge(p):
    p.stroke([(0.5, 0.18), (0.5, 1.0)], 0.1, "green")
    p.poly([(0.5, 0.6), (0.14, 0.24), (0.06, 0.06), (0.26, 0.2), (0.52, 0.48)], "green", sm=1)
    p.poly([(0.5, 0.6), (0.86, 0.24), (0.94, 0.06), (0.74, 0.2), (0.48, 0.48)], "green", sm=1)
    p.poly([(0.4, 0.2), (0.5, 0.0), (0.6, 0.2)], "yellow")


def eg_duck(p):
    p.poly([(0.18, 0.34), (0.4, 0.4), (0.72, 0.42), (1.0, 0.32), (0.86, 0.62), (0.6, 0.84), (0.3, 0.8), (0.16, 0.6)], "white", sm=1)
    p.poly([(0.36, 0.48), (0.66, 0.5), (0.86, 0.46), (0.6, 0.66), (0.4, 0.64)], "blue", sm=1)
    p.poly([(0.22, 0.38), (0.18, 0.12), (0.1, 0.04), (0.0, 0.1), (0.1, 0.14), (0.14, 0.36)], "green", sm=1)
    p.dot(0.1, 0.08, 0.03)
    p.stroke([(0.42, 0.82), (0.4, 0.98)], 0.06, "red")


def eg_lion(p):
    p.poly([(0.22, 0.4), (0.4, 0.34), (0.78, 0.38), (0.94, 0.5), (0.96, 0.86), (0.6, 0.9), (0.06, 0.92), (0.04, 0.8), (0.24, 0.76)], "yellow", sm=1)
    p.poly([(0.06, 0.3), (0.16, 0.1), (0.32, 0.06), (0.4, 0.3), (0.36, 0.6), (0.18, 0.64), (0.06, 0.52), (0.0, 0.42)], "yellow", sm=1)
    p.line(bez((0.32, 0.1), (0.44, 0.4), (0.3, 0.66)), 0.04)
    p.dot(0.14, 0.26, 0.04)
    p.line(bez((0.94, 0.56), (1.0, 0.3), (0.86, 0.16)), 0.05)


def eg_ibis(p, fill="white", head="black"):
    """L'ibis sacré debout (Thot), tourné vers la gauche : corps blanc, tête, cou et queue noirs,
    long bec courbe vers le bas, hautes pattes."""
    p.stroke(chaikin([(0.36, 0.44), (0.3, 0.3), (0.3, 0.2), (0.25, 0.12)], 2, False), 0.075, head)
    p.poly([(0.84, 0.4), (1.0, 0.5), (0.98, 0.62), (0.82, 0.56)], head, sm=1)
    p.poly([(0.34, 0.44), (0.48, 0.34), (0.7, 0.32), (0.88, 0.4), (0.94, 0.5), (0.78, 0.6), (0.52, 0.62), (0.36, 0.56)], fill, sm=1)
    p.line(bez((0.48, 0.42), (0.68, 0.42), (0.88, 0.5)), 0.022)
    p.ell(0.235, 0.12, 0.065, 0.055, head)
    p.stroke(chaikin([(0.18, 0.12), (0.08, 0.16), (0.03, 0.26), (0.02, 0.4)], 2, False), 0.032, head)
    p.dot(0.235, 0.11, 0.012, "white")
    for (x0, x1) in ((0.56, 0.52), (0.66, 0.7)):
        p.stroke([(x0, 0.6), (x1, 0.95)], 0.032, head)
    p.stroke([(0.42, 0.96), (0.56, 0.96)], 0.026, head)
    p.stroke([(0.66, 0.96), (0.8, 0.96)], 0.026, head)


def eg_wedjat(p, iris="black", white="white", brow="blue"):
    """L'œil d'Horus (oudjat) : sourcil, œil, pupille, la larme droite et la spirale (œil gauche
    du faucon, tourné vers la gauche)."""
    p.poly([(0.12, 0.2), (0.4, 0.06), (0.78, 0.06), (0.94, 0.14), (0.9, 0.2), (0.7, 0.16), (0.4, 0.17), (0.16, 0.27)], brow, sm=1)
    eye = [(0.06, 0.44), (0.28, 0.28), (0.56, 0.26), (0.8, 0.36), (1.0, 0.36), (0.98, 0.42), (0.8, 0.44), (0.56, 0.56), (0.28, 0.56)]
    p.poly(eye, white, sm=1)
    p.disc(0.44, 0.41, 0.13, iris, ol=False)
    p.stroke([(0.46, 0.56), (0.46, 0.94)], 0.07, brow)
    p.stroke(chaikin([(0.36, 0.56), (0.24, 0.7), (0.16, 0.86), (0.24, 0.96), (0.36, 0.92), (0.32, 0.84)], 2, False), 0.06, brow)


EG_SIGNS = {  # nom : (fonction, largeur / hauteur, catégorie)
    "vautour": (eg_vulture, 1.0, "big"), "roseau": (eg_reed, 0.36, "tall"), "bras": (eg_arm, 2.6, "flat"),
    "caille": (eg_owl, 0.8, "big"), "pied": (eg_foot, 1.5, "flat"), "tabouret": (eg_stool, 1.0, "small"),
    "vipere": (eg_viper, 2.4, "flat"), "eau": (eg_water, 5.0, "flat"), "bouche": (eg_mouth, 2.6, "flat"),
    "abri": (eg_shelter, 1.0, "big"), "lin": (eg_flax, 0.36, "tall"), "placenta": (eg_placenta, 1.0, "small"),
    "etoffe": (eg_cloth, 0.4, "tall"), "bassin": (eg_pool, 2.4, "flat"), "colline": (eg_hill, 1.4, "small"),
    "panier": (eg_basket, 1.6, "flat"), "support": (eg_jarstand, 2.4, "flat"), "pain": (eg_bread, 2.0, "small"),
    "main": (eg_hand, 2.3, "flat"), "cobra": (eg_cobra, 0.85, "big"), "ankh": (eg_ankh, 0.55, "tall"),
    "djed": (eg_djed, 0.45, "tall"), "ouas": (eg_was, 0.3, "tall"), "maison": (eg_house, 1.5, "flat"),
    "nefer": (eg_nfr, 0.45, "tall"), "etoile": (eg_star, 1.0, "small"), "neb": (eg_neb, 2.6, "flat"),
    "assis": (eg_seated, 0.8, "big"), "souchet": (eg_sedge, 0.6, "tall"), "canard": (eg_duck, 1.3, "big"),
    "lion": (eg_lion, 2.0, "flat"), "plume": (eg_feather, 0.32, "tall"), "scarabee": (eg_scarab, 0.8, "big"),
}


def fit(box, aspect, fill=0.92):
    """Place un signe de proportions données au milieu d'une boîte."""
    x, y, w, h = box
    if aspect * h <= w:
        hh = h * fill
        ww = aspect * hh
    else:
        ww = w * fill
        hh = ww / aspect
    return (x + (w - ww) / 2, y + (h - hh) / 2, ww, hh)


# ------------------------------------------------------------------- jours mayas (dans un cartouche)

def mj_cartouche(p, fill="f"):
    """Le cartouche des jours : un carré arrondi épais, et son petit socle à trois pieds."""
    out = chaikin([(0.08, 0.04), (0.92, 0.04), (0.96, 0.08), (0.96, 0.76), (0.92, 0.8), (0.08, 0.8), (0.04, 0.76), (0.04, 0.08)], 2)
    p.poly(out, fill)
    inn = chaikin([(0.16, 0.12), (0.84, 0.12), (0.88, 0.16), (0.88, 0.68), (0.84, 0.72), (0.16, 0.72), (0.12, 0.68), (0.12, 0.16)], 2)
    p.line(inn + [inn[0]], 0.025)
    for x in (0.22, 0.5, 0.78):
        p.poly([(x - 0.08, 0.8), (x + 0.08, 0.8), (x + 0.06, 0.9), (x - 0.06, 0.9)], fill)


def _mj_imix(p):
    p.poly([(0.12, 0.06), (0.88, 0.06), (0.88, 0.36), (0.12, 0.36)], "f")
    for x in (0.26, 0.42, 0.58, 0.74):
        p.line([(x, 0.08), (x, 0.34)], 0.045)
    p.ell(0.5, 0.68, 0.3, 0.26, "f")
    p.line([(0.5, 0.44), (0.5, 0.74)], 0.05)
    for a in range(0, 181, 36):
        p.dot(0.5 + math.cos(math.radians(a)) * 0.2, 0.7 + math.sin(math.radians(a)) * 0.16, 0.035)


def _mj_ik(p):
    p.cut([(0.24, 0.26), (0.76, 0.26), (0.76, 0.42), (0.58, 0.42), (0.58, 0.8), (0.42, 0.8), (0.42, 0.42), (0.24, 0.42)])
    p.dot(0.5, 0.12, 0.05)


def _mj_akbal(p):
    for sg in (-1, 1):
        p.line(bez((0.5, 0.36), (0.5 + sg * 0.1, 0.06), (0.5 + sg * 0.34, 0.12), (0.5 + sg * 0.3, 0.34), 14), 0.06)
    p.line([(0.1, 0.48), (0.9, 0.48)], 0.06)
    p.cut(ellp(0.5, 0.48, 0.3, 0.26, 0, 180, 20))
    for x in (0.34, 0.5, 0.66):
        p.dot(x, 0.86, 0.05)


def _mj_kan(p):
    q = [(0.38, 0.1), (0.62, 0.1), (0.62, 0.38), (0.9, 0.38), (0.9, 0.62), (0.62, 0.62), (0.62, 0.9), (0.38, 0.9), (0.38, 0.62), (0.1, 0.62), (0.1, 0.38), (0.38, 0.38)]
    p.line(chaikin(q, 1) + [chaikin(q, 1)[0]], 0.055)
    p.ring(0.5, 0.5, 0.07, 0.05)


def _mj_chicchan(p):
    band = tube(bez((0.08, 0.86), (0.4, 0.66), (0.62, 0.3), (0.94, 0.12), 18), 0.32)
    p.poly(band, "f")
    for k in range(1, 9):
        t = k / 9
        x, y = 0.08 + t * 0.86, 0.86 - t * 0.74
        p.line([(x - 0.12, y - 0.06), (x + 0.06, y + 0.12)], 0.025)
        p.line([(x - 0.06, y + 0.12), (x + 0.12, y - 0.04)], 0.025)
    p.dot(0.2, 0.22, 0.07)


def _mj_cimi(p):
    p.ring(0.3, 0.26, 0.12, 0.05)
    p.dot(0.3, 0.26, 0.04)
    p.line(bez((0.78, 0.12), (0.5, 0.45), (0.24, 0.84)), 0.07)
    p.ring(0.7, 0.66, 0.12, 0.05)
    p.dot(0.7, 0.66, 0.04)


def _mj_manik(p):
    p.poly([(0.16, 0.86), (0.2, 0.46), (0.3, 0.2), (0.62, 0.14), (0.84, 0.22), (0.88, 0.5), (0.74, 0.62), (0.58, 0.6), (0.6, 0.86)], "f", sm=1)
    for y in (0.3, 0.42, 0.54):
        p.line([(0.42, y), (0.86, y - 0.04)], 0.035)
    p.line(bez((0.3, 0.3), (0.2, 0.5), (0.36, 0.66)), 0.04)
    p.line([(0.2, 0.74), (0.58, 0.74)], 0.04)


def _mj_lamat(p):
    p.line([(0.18, 0.18), (0.82, 0.82)], 0.12)
    p.line([(0.82, 0.18), (0.18, 0.82)], 0.12)
    for (x, y) in ((0.5, 0.18), (0.5, 0.82), (0.18, 0.5), (0.82, 0.5)):
        p.dot(x, y, 0.07)


def _mj_muluc(p):
    p.ring(0.5, 0.52, 0.22, 0.06)
    p.dot(0.5, 0.52, 0.08)
    p.line(bez((0.18, 0.2), (0.06, 0.5), (0.18, 0.84)), 0.06)
    p.line(bez((0.82, 0.2), (0.94, 0.5), (0.82, 0.84)), 0.06)
    for x in (0.36, 0.5, 0.64):
        p.dot(x, 0.14, 0.035)


def _mj_oc(p):
    p.poly([(0.88, 0.3), (0.62, 0.12), (0.34, 0.16), (0.16, 0.34), (0.06, 0.5), (0.1, 0.64), (0.3, 0.66), (0.42, 0.8), (0.7, 0.86), (0.9, 0.7)], "f", sm=1)
    p.poly([(0.6, 0.16), (0.82, 0.18), (0.86, 0.52), (0.72, 0.56), (0.64, 0.36)], "f", sm=1)
    p.ring(0.38, 0.38, 0.06, 0.04)
    p.line([(0.1, 0.6), (0.34, 0.58)], 0.04)
    p.dot(0.1, 0.46, 0.035)


def _mj_chuen(p):
    p.poly([(0.84, 0.2), (0.5, 0.14), (0.24, 0.28), (0.16, 0.5), (0.24, 0.76), (0.56, 0.86), (0.84, 0.76)], "f", sm=1)
    p.ring(0.44, 0.4, 0.1, 0.05)
    p.dot(0.44, 0.4, 0.04)
    p.line(bez((0.2, 0.62), (0.36, 0.74), (0.52, 0.62), (0.44, 0.54), 12), 0.05)
    for x in (0.4, 0.56, 0.72):
        p.line([(x, 0.16), (x - 0.04, 0.02)], 0.04)


def _mj_eb(p):
    p.poly([(0.88, 0.16), (0.46, 0.1), (0.2, 0.24), (0.12, 0.5), (0.2, 0.84), (0.6, 0.9), (0.88, 0.74)], "f", sm=1)
    for (x, y) in ((0.6, 0.22), (0.72, 0.3), (0.66, 0.42), (0.78, 0.48), (0.54, 0.34)):
        p.dot(x, y, 0.035)
    p.line(bez((0.18, 0.56), (0.36, 0.62), (0.4, 0.84)), 0.05)
    for x in (0.24, 0.32):
        p.line([(x, 0.66), (x, 0.78)], 0.035)
    p.ring(0.36, 0.38, 0.05, 0.035)


def _mj_ben(p):
    p.poly([(0.1, 0.12), (0.9, 0.12), (0.9, 0.36), (0.1, 0.36)], "f")
    for k in range(6):
        x = 0.16 + k * 0.13
        p.line([(x, 0.14), (x + 0.08, 0.34)], 0.03)
    p.poly([(0.28, 0.4), (0.42, 0.4), (0.42, 0.9), (0.28, 0.9)], "f")
    p.poly([(0.58, 0.4), (0.72, 0.4), (0.72, 0.9), (0.58, 0.9)], "f")


def _mj_ix(p):
    for (x, y) in ((0.32, 0.32), (0.68, 0.32), (0.5, 0.68)):
        p.ring(x, y, 0.13, 0.05)
        p.dot(x, y, 0.05)
    for (x, y) in ((0.5, 0.18), (0.22, 0.66), (0.78, 0.66)):
        p.dot(x, y, 0.035)


def _mj_men(p):
    p.poly([(0.88, 0.26), (0.6, 0.12), (0.34, 0.16), (0.2, 0.3), (0.12, 0.5), (0.24, 0.6), (0.18, 0.72), (0.36, 0.86), (0.7, 0.88), (0.9, 0.7)], "f", sm=1)
    p.poly([(0.2, 0.3), (0.04, 0.42), (0.1, 0.56), (0.22, 0.5)], "f", sm=1)
    p.ring(0.42, 0.36, 0.08, 0.045)
    p.dot(0.42, 0.36, 0.035)
    for k in range(3):
        p.line([(0.62 + k * 0.08, 0.14), (0.7 + k * 0.08, 0.02)], 0.04)


def _mj_cib(p):
    pts = []
    for k in range(60):
        t = k / 59
        a = t * 2.4 * TAU
        r = 0.04 + t * 0.34
        pts.append((0.5 + math.cos(a) * r, 0.5 + math.sin(a) * r * 0.9))
    p.line(pts, 0.06)
    p.line([(0.16, 0.86), (0.84, 0.86)], 0.05)


def _mj_caban(p):
    p.line(bez((0.78, 0.2), (0.3, 0.06), (0.14, 0.5), (0.5, 0.56), 18), 0.08)
    p.line(bez((0.5, 0.56), (0.66, 0.5), (0.6, 0.38), 8), 0.07)
    for (x, y) in ((0.3, 0.78), (0.5, 0.82), (0.7, 0.78)):
        p.dot(x, y, 0.055)


def _mj_etznab(p):
    for a, b in (((0.12, 0.12), (0.88, 0.88)), ((0.88, 0.12), (0.12, 0.88))):
        mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        dx, dy = b[1] - a[1], -(b[0] - a[0])
        L = math.hypot(dx, dy)
        nx, ny = dx / L * 0.12, dy / L * 0.12
        p.line(bez(a, (mx + nx, my + ny), b), 0.05)
        p.line(bez(a, (mx - nx, my - ny), b), 0.05)
    p.dot(0.5, 0.5, 0.05)


def _mj_cauac(p):
    for cx in (0.3, 0.7):
        for (dx, dy) in ((-0.07, 0.0), (0.07, 0.0), (0.0, 0.11)):
            p.ring(cx + dx, 0.3 + dy, 0.065, 0.035)
    p.line([(0.12 + k * 0.095, 0.66 + (0.08 if k % 2 else 0.0)) for k in range(9)], 0.05)
    p.line([(0.2, 0.86), (0.8, 0.86)], 0.04)


def _mj_ahau(p):
    """Ahau : le visage du seigneur-soleil, deux grands yeux ronds et la bouche ronde."""
    p.ring(0.31, 0.36, 0.13, 0.06)
    p.ring(0.69, 0.36, 0.13, 0.06)
    p.dot(0.31, 0.38, 0.05)
    p.dot(0.69, 0.38, 0.05)
    p.ring(0.5, 0.74, 0.14, 0.06)
    p.dot(0.5, 0.74, 0.045)


MAYA_DAYS = [("imix", "Imix", _mj_imix), ("ik", "Ik", _mj_ik), ("akbal", "Akbal", _mj_akbal), ("kan", "Kan", _mj_kan),
             ("chicchan", "Chicchan", _mj_chicchan), ("cimi", "Cimi", _mj_cimi), ("manik", "Manik", _mj_manik),
             ("lamat", "Lamat", _mj_lamat), ("muluc", "Muluc", _mj_muluc), ("oc", "Oc", _mj_oc), ("chuen", "Chuen", _mj_chuen),
             ("eb", "Eb", _mj_eb), ("ben", "Ben", _mj_ben), ("ix", "Ix", _mj_ix), ("men", "Men", _mj_men), ("cib", "Cib", _mj_cib),
             ("caban", "Caban", _mj_caban), ("etznab", "Etznab", _mj_etznab), ("cauac", "Cauac", _mj_cauac), ("ahau", "Ahau", _mj_ahau)]


def maya_day(p, key, pedestal=True):
    """Un jour maya complet : le cartouche (et son socle) et le signe dedans."""
    fn = dict((k, f) for k, _, f in MAYA_DAYS)[key]
    if pedestal:
        mj_cartouche(p)
        fn(p.sub(0.17, 0.13, 0.66, 0.58))
    else:
        out = chaikin([(0.06, 0.02), (0.94, 0.02), (0.98, 0.06), (0.98, 0.94), (0.94, 0.98), (0.06, 0.98), (0.02, 0.94), (0.02, 0.06)], 2)
        p.poly(out, "f")
        fn(p.sub(0.14, 0.12, 0.72, 0.76))


def maya_number(p, n, vertical=False):
    """Chiffre maya en points et barres (point = 1, barre = 5) : les barres en bas, les points
    au-dessus ; en colonne (vertical=True) les points s'empilent quand le chiffre est à gauche."""
    bars, dots = n // 5, n % 5
    if not vertical:
        total = bars * 0.25 + (0.25 if dots else 0)
        y = 0.5 + total / 2
        for b in range(bars):
            y -= 0.25
            p.poly(chaikin([(0.04, y + 0.03), (0.96, y + 0.03), (0.96, y + 0.22), (0.04, y + 0.22)], 2), "f")
            p.line([(0.16, y + 0.125), (0.84, y + 0.125)], 0.025)
        if dots:
            y -= 0.25
            sp = 0.235
            x0 = 0.5 - (dots - 1) * sp / 2
            for k in range(dots):
                p.disc(x0 + k * sp, y + 0.125, 0.1, "f")
                p.dot(x0 + k * sp, y + 0.125, 0.03)
    else:
        total = bars * 0.2 + (0.22 if dots else 0)
        x = 0.5 + total / 2
        for b in range(bars):
            x -= 0.2
            p.poly(chaikin([(x + 0.03, 0.08), (x + 0.17, 0.08), (x + 0.17, 0.92), (x + 0.03, 0.92)], 2), "f")
        if dots:
            x -= 0.22
            sp = 0.2
            y0 = 0.5 - (dots - 1) * sp / 2
            for k in range(dots):
                p.disc(x + 0.11, y0 + k * sp, 0.08, "f")
                p.dot(x + 0.11, y0 + k * sp, 0.025)


def maya_head(p, R):
    """Une tête de profil (glyphe « tête ») : grand œil, nez busqué, ornement d'oreille, coiffe."""
    p.poly([(0.92, 0.22), (0.6, 0.06), (0.32, 0.12), (0.18, 0.3), (0.06, 0.42), (0.14, 0.52), (0.1, 0.62), (0.22, 0.7), (0.24, 0.86), (0.6, 0.94), (0.92, 0.82)], "f", sm=1)
    p.ring(0.36, 0.38, 0.09, 0.04)
    p.dot(0.34, 0.4, 0.035)
    p.ring(0.66, 0.56, 0.12, 0.045)
    p.dot(0.66, 0.56, 0.04)
    p.line([(0.12, 0.64), (0.3, 0.66)], 0.035)
    k = int(R.integers(3))
    if k == 0:
        for x in (0.4, 0.55, 0.7):
            p.line([(x, 0.1), (x - 0.04, -0.02)], 0.04)
    elif k == 1:
        p.line(bez((0.3, 0.12), (0.5, -0.04), (0.8, 0.12)), 0.05)
    else:
        p.dot(0.5, 0.2, 0.05)
        p.dot(0.66, 0.2, 0.05)


# ------------------------------------------------------------------- signes aztèques

PAL_AZ = {"ink": (24, 20, 18, 255), "red": (190, 48, 36, 255), "blue": (40, 150, 170, 255), "dblue": (36, 80, 150, 255),
          "yellow": (232, 182, 56, 255), "white": (240, 234, 216, 255), "green": (70, 140, 70, 255), "skin": (200, 120, 80, 255),
          "brown": (130, 76, 40, 255), "black": (30, 26, 24, 255), "orange": (230, 120, 40, 255), "pink": (226, 150, 140, 255)}


def az_dots(p, n=4, y=0.9, r=0.055, fill="red"):
    sp = 0.2
    x0 = 0.5 - (n - 1) * sp / 2
    for k in range(n):
        p.disc(x0 + k * sp, y, r, fill)


def az_jaguar(p):
    """Tête de jaguar de profil (vers la gauche), gueule ouverte, crocs, taches."""
    p.poly([(0.9, 0.3), (0.74, 0.12), (0.5, 0.1), (0.3, 0.18), (0.14, 0.3), (0.06, 0.42), (0.1, 0.5), (0.28, 0.52), (0.14, 0.62),
            (0.2, 0.74), (0.46, 0.8), (0.78, 0.82), (0.94, 0.62)], "yellow", sm=1)
    p.poly([(0.62, 0.16), (0.72, 0.0), (0.84, 0.06), (0.82, 0.22)], "yellow", sm=1)
    p.cut([(0.1, 0.5), (0.3, 0.52), (0.44, 0.6), (0.3, 0.66), (0.14, 0.62)], sm=1)
    p.poly([(0.16, 0.5), (0.22, 0.5), (0.19, 0.62)], "white", ol=False)
    p.poly([(0.32, 0.53), (0.37, 0.55), (0.32, 0.64)], "white", ol=False)
    p.ring(0.36, 0.3, 0.07, 0.04)
    p.dot(0.34, 0.3, 0.03)
    p.dot(0.06, 0.4, 0.025)
    for (x, y) in ((0.58, 0.32), (0.74, 0.42), (0.6, 0.56), (0.8, 0.62), (0.5, 0.7), (0.66, 0.72)):
        p.ring(x, y, 0.045, 0.03)


def az_ehecatl(p):
    """Tête du dieu du vent : masque à bec rouge (le souffle), œil, ornement d'oreille, bonnet."""
    p.poly([(0.88, 0.28), (0.66, 0.08), (0.42, 0.08), (0.3, 0.2), (0.32, 0.4), (0.38, 0.8), (0.86, 0.84), (0.94, 0.56)], "skin", sm=1)
    p.poly([(0.36, 0.36), (0.04, 0.42), (0.0, 0.56), (0.12, 0.66), (0.4, 0.66)], "red", sm=1)
    p.line([(0.06, 0.54), (0.36, 0.52)], 0.03)
    p.ring(0.46, 0.28, 0.07, 0.04)
    p.dot(0.45, 0.28, 0.03)
    p.ring(0.7, 0.5, 0.1, 0.05, "ink")
    p.disc(0.7, 0.5, 0.06, "blue", ol=False)
    p.poly([(0.38, 0.12), (0.5, -0.02), (0.8, 0.0), (0.9, 0.2), (0.66, 0.1)], "black", sm=1)
    for k, y in enumerate((0.36, 0.72)):
        p.line(bez((0.06, 0.52), (0.0, y), (0.1, y - 0.08 + 0.16 * k)), 0.035)
        p.ring(0.12, y - 0.08 + 0.16 * k + (0.04 if k else -0.04), 0.04, 0.03)


def az_tlaloc_face(p, drops="blue"):
    """Visage de Tlaloc (signe Quiahuitl, la pluie) : œil cerclé « à lunettes », lèvre en
    volute, crocs ; des gouttes tombent dessous."""
    p.poly([(0.9, 0.2), (0.6, 0.04), (0.3, 0.08), (0.12, 0.24), (0.08, 0.46), (0.16, 0.58), (0.5, 0.62), (0.9, 0.56)], "dblue", sm=1)
    p.disc(0.38, 0.28, 0.13, "white")
    p.dot(0.38, 0.28, 0.05)
    p.stroke(bez((0.12, 0.5), (0.3, 0.4), (0.5, 0.5)), 0.07, "red")
    for x in (0.2, 0.3, 0.4):
        p.poly([(x - 0.035, 0.52), (x + 0.035, 0.52), (x, 0.66)], "white")
    p.ring(0.7, 0.32, 0.08, 0.04)
    for k, x in enumerate((0.2, 0.38, 0.56, 0.74)):
        y = 0.7 + (0.06 if k % 2 else 0.0)
        p.poly([(x, y), (x + 0.05, y + 0.1), (x, y + 0.14), (x - 0.05, y + 0.1)], drops, sm=1)


def az_atl(p):
    """Atl, l'eau : un bassin de flots bleus à vagues, bordé de pierres de jade, qui déborde en
    deux courants terminés par une conque et une goutte."""
    top = [(0.1 + k * 0.1, 0.18 + (0.06 if k % 2 else 0.0)) for k in range(9)]
    body = top + [(0.9, 0.62), (0.7, 0.66), (0.5, 0.62), (0.3, 0.66), (0.1, 0.62)]
    p.poly(body, "blue", sm=1)
    for y in (0.34, 0.48):
        p.line([(0.16 + k * 0.08, y + (0.04 if k % 2 else -0.02)) for k in range(10)], 0.025)
    for x in (0.18, 0.5, 0.82):
        p.disc(x, 0.18 + (0.06 if x == 0.5 else 0.0) - 0.02, 0.045, "white")
    p.poly(tube(bez((0.22, 0.64), (0.14, 0.8), (0.22, 0.94)), 0.1, 0.05), "blue")
    p.poly(tube(bez((0.76, 0.64), (0.86, 0.78), (0.78, 0.9)), 0.1, 0.05), "blue")
    p.poly([(0.26, 0.86), (0.4, 0.84), (0.44, 0.94), (0.34, 1.0), (0.24, 0.96)], "white", sm=1)
    p.poly([(0.7, 0.88), (0.76, 0.98), (0.66, 0.98)], "blue", sm=1)


def az_fire_rain(p):
    """La pluie de feu : un nuage, des gouttes de feu qui tombent, des flammes au sol."""
    cloud = []
    for k in range(5):
        cloud += ellp(0.18 + k * 0.16, 0.14, 0.11, 0.1, 180, 360, 8)
    p.poly(cloud + [(0.86, 0.24), (0.14, 0.24)], "dblue", sm=1)
    for k, (x, y) in enumerate(((0.2, 0.34), (0.42, 0.3), (0.64, 0.34), (0.86, 0.3), (0.3, 0.52), (0.54, 0.5), (0.76, 0.52))):
        p.poly([(x, y), (x + 0.055, y + 0.09), (x, y + 0.13), (x - 0.055, y + 0.09)], "red", sm=1)
        p.dot(x, y + 0.085, 0.022, "yellow")
    az_fire(p.sub(0.08, 0.66, 0.84, 0.34))


def az_fire(p):
    """Flammes (pluie de feu) : trois langues de feu jaunes et rouges."""
    for cx, s in ((0.3, 0.8), (0.55, 1.0), (0.78, 0.75)):
        pts = [(cx - 0.14 * s, 0.9), (cx - 0.16 * s, 0.6), (cx - 0.04 * s, 0.4), (cx - 0.08 * s, 0.2), (cx + 0.04 * s, 0.32),
               (cx + 0.06 * s, 0.06), (cx + 0.16 * s, 0.4), (cx + 0.16 * s, 0.9)]
        p.poly(pts, "red", sm=1)
        p.poly([(cx - 0.07 * s, 0.88), (cx - 0.07 * s, 0.66), (cx + 0.02 * s, 0.5), (cx + 0.08 * s, 0.66), (cx + 0.08 * s, 0.88)], "yellow", sm=1)


def az_ollin(p):
    """Ollin, le mouvement : deux bandes courbes entrelacées en X, l'œil au milieu."""
    for sg in (-1, 1):
        a = (0.08, 0.14) if sg < 0 else (0.92, 0.14)
        b = (0.92, 0.86) if sg < 0 else (0.08, 0.86)
        mid = (0.5 + sg * 0.12, 0.5)
        p.poly(tube(bez(a, mid, b, None, 20), 0.2, 0.2), "blue" if sg < 0 else "red", sm=0)
        p.line(bez(a, mid, b, None, 20), 0.025)
    p.disc(0.5, 0.5, 0.15, "white")
    p.disc(0.5, 0.5, 0.06, "black", ol=False)
    for (x, y) in ((0.5, 0.14), (0.5, 0.86)):
        p.disc(x, y, 0.06, "yellow")


SUNS = [("jaguar", "Nahui Ocelotl", az_jaguar), ("vent", "Nahui Ehecatl", az_ehecatl), ("feu", "Nahui Quiahuitl", None),
        ("eau", "Nahui Atl", az_atl), ("ollin", "Nahui Ollin", az_ollin)]


def az_sun_sign(p, key, frame=True, dots=True):
    """Un soleil aztèque : le cartouche carré, le signe, et les quatre points (« Nahui » = 4)."""
    if frame:
        out = chaikin([(0.04, 0.02), (0.96, 0.02), (0.98, 0.04), (0.98, 0.98), (0.96, 1.0), (0.04, 1.0), (0.02, 0.98), (0.02, 0.04)], 1)
        p.poly(out, "f")
        p.line([(0.06, 0.78), (0.94, 0.78)], 0.02)
    q = p.sub(0.12, 0.06, 0.76, 0.68)
    if key == "jaguar":
        az_jaguar(q)
    elif key == "vent":
        az_ehecatl(q)
    elif key == "feu":
        az_fire_rain(q)
    elif key == "eau":
        az_atl(q)
    else:
        az_ollin(q)
    if dots:
        az_dots(p, 4, 0.89, 0.06)


def step_fret(p, fill="red", w=None):
    """Une grecque à degrés (xicalcoliuhqui) dans une case 0..1 : un escalier qui monte, puis une
    spirale carrée."""
    u = 1 / 12.0
    pts = [(0, 1), (0, 1 - u * 2), (u * 2, 1 - u * 2), (u * 2, 1 - u * 4), (u * 4, 1 - u * 4), (u * 4, 1 - u * 6), (u * 6, 1 - u * 6),
           (u * 6, u * 1), (u * 11, u * 1), (u * 11, u * 8), (u * 8, u * 8), (u * 8, u * 4), (u * 9.5, u * 4), (u * 9.5, u * 6.5),
           (u * 9.5 + u * 0.01, u * 6.5), (u * 9.6, u * 6.5), (u * 9.6, u * 2.5), (u * 7.5, u * 2.5), (u * 7.5, 1 - u * 4.5),
           (u * 5.5, 1 - u * 4.5), (u * 5.5, 1 - u * 2.5), (u * 3.5, 1 - u * 2.5), (u * 3.5, 1 - u * 0.5), (u * 1.5, 1 - u * 0.5), (u * 1.5, 1)]
    p.poly(pts, fill, w=w)


# ------------------------------------------------------------------- les murs gravés (raccordables)

def _layers(W, H):
    return Image.new("RGBA", (W, H), (0, 0, 0, 0)), Image.new("L", (W, H), 0), Image.new("L", (W, H), 0)


def _arr(img):
    return np.asarray(img, np.float32) / 255.0


def hieroglyphes():
    """Paroi de grès gravée en creux de colonnes de hiéroglyphes peints (bleu égyptien, ocre
    rouge, vert, jaune, cernés de noir), séparées par des traits bleus ; la peinture s'écaille,
    la pierre est patinée. Raccordable dans les deux sens (8 colonnes de 8 cadrats)."""
    S = 1024
    K = 2
    SS = S * K
    R = rng(6920)
    col, shp, lin = _layers(SS, SS)
    pal = {"blue": (40, 90, 150, 255), "red": (160, 56, 34, 255), "green": (44, 116, 86, 255), "yellow": (206, 156, 58, 255),
           "white": (226, 216, 190, 255), "skin": (162, 76, 44, 255), "ink": (26, 22, 20, 255), "black": (30, 26, 24, 255)}
    pools = {}
    for name, (fn, asp, cat) in EG_SIGNS.items():
        pools.setdefault(cat, []).append((name, fn, asp))
    q = 128 * K
    m = 14 * K
    for cx in range(8):
        # traits de séparation (gravés et peints) : à cheval sur le bord de la tuile
        for x in ((cx * q,) if cx else (0, SS)):
            p = Pen((x - 5 * K, 0, 10 * K, SS), col, shp, lin, pal, lw=0.0)
            p.poly([(0, -0.01), (1, -0.01), (1, 1.01), (0, 1.01)], "blue", ol=False)
        for cy in range(8):
            x0, y0 = cx * q + m, cy * q + m
            w = q - 2 * m
            u = R.random()

            def put(cat, box, fill=0.92):
                name, fn, asp = pools[cat][R.integers(len(pools[cat]))]
                bx = fit(box, asp, fill)
                fn(Pen(bx, col, shp, lin, pal, lw=0.05))

            if u < 0.28:
                put("tall", (x0, y0, w * 0.47, w))
                put("tall", (x0 + w * 0.53, y0, w * 0.47, w))
            elif u < 0.5:
                put("big", (x0, y0, w, w), 0.9)
            elif u < 0.72:
                put("flat", (x0, y0, w, w * 0.46))
                put("flat", (x0, y0 + w * 0.54, w, w * 0.46))
            elif u < 0.88:
                put("flat", (x0, y0, w, w * 0.42))
                put("small", (x0, y0 + w * 0.52, w * 0.46, w * 0.46), 0.8)
                put("small", (x0 + w * 0.54, y0 + w * 0.52, w * 0.46, w * 0.46), 0.8)
            else:
                put("tall", (x0, y0, w * 0.4, w))
                put("small", (x0 + w * 0.48, y0 + w * 0.05, w * 0.5, w * 0.42), 0.85)
                put("flat", (x0 + w * 0.44, y0 + w * 0.56, w * 0.56, w * 0.4))
    pc = down(_arr(col), K)
    sh = down(_arr(shp), K)
    ln = down(_arr(lin), K)
    del col, shp, lin
    # la pierre : grès, deux assises, joints discrets
    bid, e, u_, v_ = masonry(R, S, [512, 512], 420, 700, rr=4.0)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    tone = per_id(bid, R, 0.93, 1.06)
    stone = C(0.8, 0.66, 0.47) * tone[..., None] * (0.86 + 0.2 * mot[..., None]) * (0.92 + 0.12 * fine[..., None])
    jm = 1 - smooth(0.5, 2.0, e)
    stone = mix(stone, C(0.56, 0.46, 0.34), jm * 0.8)
    # gravure en creux : le fond du signe est plus bas, ses bords en biseau
    cv = gblur(sh, 1.2)
    h = 0.6 + mot * 0.08 + fine * 0.04 - cv * 0.35 - ln * 0.08 - jm * 0.15
    inside = smooth(0.4, 0.8, sh)
    stone = stone * (1 - 0.12 * inside[..., None])
    # la peinture : passée, écaillée (plus usée en bas), un peu salie
    keep = smooth(0.38, 0.48, tn(R, S, (8, 16, 32, 64, 128), 0.65) + (fine - 0.5) * 0.15)
    a = pc[..., 3] * (0.35 + 0.65 * keep) * 0.92
    paint = pc[..., :3] / np.maximum(pc[..., 3:4], 1e-3)
    paint = mix(paint, stone, 0.18)
    out = mix(stone, paint * (0.9 + 0.12 * fine[..., None]), a)
    dirt = smooth(0.55, 0.85, tn(R, S, (8, 16, 32, 64), 0.6, oy=(2, 4, 8, 16)))
    out = out * (1 - 0.12 * dirt[..., None])
    out = bake(out, h, 4.0, k=0.35, ao=0.3, ao_r=3)
    save_surface("hieroglyphes", out, h, 5.0)


def maya_block(p, R):
    """Un bloc de glyphe maya : signe principal, préfixe à gauche et/ou suffixe en haut."""
    u = R.random()
    pre = u < 0.6
    sup = (u > 0.35) or not pre
    mx = 0.3 if pre else 0.0
    my = 0.28 if sup else 0.0
    main = p.sub(mx, my, 1 - mx, 1 - my)
    k = R.random()
    if k < 0.55:
        key = MAYA_DAYS[R.integers(len(MAYA_DAYS))][0]
        maya_day(main, key, pedestal=False)
    elif k < 0.85:
        maya_head(main, R)
    else:
        main.poly(chaikin([(0.1, 0.1), (0.9, 0.1), (0.9, 0.9), (0.1, 0.9)], 2), "f")
        for a in range(4):
            ang = a * 90 + 45
            main.ell(0.5 + math.cos(math.radians(ang)) * 0.2, 0.5 + math.sin(math.radians(ang)) * 0.2, 0.13, 0.13, "f")
        main.dot(0.5, 0.5, 0.06)
    if pre:
        pp = p.sub(0.0, my, 0.29, 1 - my)
        c = R.random()
        if c < 0.4:
            maya_number(pp, int(R.integers(1, 14)), vertical=True)
        elif c < 0.7:
            pp.poly(chaikin([(0.15, 0.06), (0.85, 0.06), (0.85, 0.94), (0.15, 0.94)], 2), "f")
            for y in (0.25, 0.45, 0.65):
                pp.line([(0.25, y), (0.75, y)], 0.08)
        else:
            pp.poly(chaikin([(0.2, 0.1), (0.9, 0.1), (0.9, 0.9), (0.2, 0.9), (0.05, 0.5)], 2), "f")
            pp.dot(0.55, 0.3, 0.1)
            pp.dot(0.55, 0.7, 0.1)
    if sup:
        ps = p.sub(mx, 0.0, 1 - mx, 0.27)
        c = R.random()
        if c < 0.35:
            maya_number(ps, int(R.integers(1, 14)))
        elif c < 0.7:
            ps.poly(chaikin([(0.06, 0.15), (0.94, 0.15), (0.94, 0.85), (0.06, 0.85)], 2), "f")
            for x in (0.3, 0.5, 0.7):
                ps.dot(x, 0.5, 0.12)
        else:
            ps.poly(chaikin([(0.1, 0.1), (0.9, 0.1), (0.8, 0.9), (0.2, 0.9)], 2), "f")
            ps.line(bez((0.25, 0.3), (0.5, 0.95), (0.75, 0.3)), 0.12)


def glyphes_maya():
    """Panneau de calcaire sculpté : une grille de blocs de glyphes mayas (6 x 6 par tuile) en
    bas-relief : cartouches arrondis, têtes de profil, mains, points et barres ; le fond est
    taillé plus bas et noirci, la pierre grise est rongée, tachée de lichen. Raccordable."""
    S = 1024
    K = 2
    SS = S * K
    R = rng(6921)
    _, shp, lin = _layers(SS, SS)
    n = 6
    q = SS / n
    for gy in range(n):
        for gx in range(n):
            m = q * 0.045
            maya_block(Pen((gx * q + m, gy * q + m, q - 2 * m, q - 2 * m), None, shp, lin, lw=0.05), R)
    sh = down(_arr(shp), K)
    ln = down(_arr(lin), K) * sh
    del shp, lin
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    ero = tn(R, S, (16, 32, 64, 128), 0.65)
    relief = gblur(sh, 1.6)
    relief = relief * (1 - 0.2 * smooth(0.6, 0.8, ero))
    h = 0.25 + relief * 0.6 - ln * 0.25 + mot * 0.06 + fine * 0.05
    stone = C(0.76, 0.73, 0.66) * (0.86 + 0.22 * mot[..., None]) * (0.9 + 0.16 * fine[..., None])
    back = 1 - smooth(0.2, 0.6, relief)
    stone = mix(stone, stone * C(0.46, 0.44, 0.41), back * 0.85)
    stone = stone * (1 - 0.5 * ln[..., None])
    red = smooth(0.45, 0.65, tn(R, S, (8, 16, 32, 64), 0.6)) * back * smooth(0.3, 0.6, fine)
    stone = mix(stone, C(0.42, 0.2, 0.16), red * 0.3)
    li = smooth(0.66, 0.74, tn(R, S, (16, 32, 64), 0.6)) * smooth(0.45, 0.6, fine)
    stone = mix(stone, C(0.2, 0.2, 0.18), li * 0.4)
    lg = smooth(0.72, 0.75, tn(R, S, (16, 32, 64, 128), 0.6)) * (1 - back)
    stone = mix(stone, C(0.66, 0.68, 0.58), lg * 0.3)
    pits = speck(R, S, 0.002, 1.0)
    stone = stone * (1 - 0.3 * pits[..., None])
    out = bake(stone, h, 4.0, k=0.45, ao=0.35, ao_r=4)
    save_surface("glyphes_maya", out, h, 6.0)


def _fret_rects(u, x0, y0, flip=False):
    """La grecque à degrés en rectangles (cellule de 14 x 8 unités)."""
    path = [(0, 7), (2, 7), (2, 5), (4, 5), (4, 3), (6, 3), (6, 1), (12, 1), (12, 7), (8, 7), (8, 3), (10, 3), (10, 5)]
    rects = []
    for (ax, ay), (bx, by) in zip(path[:-1], path[1:]):
        if flip:
            ax, bx = 14 - ax, 14 - bx
        xa, xb = sorted((ax, bx))
        ya, yb = sorted((ay, by))
        rects.append((x0 + (xa - 0.5) * u, y0 + (ya - 0.5) * u, x0 + (xb + 0.5) * u, y0 + (yb + 0.5) * u))
    return rects


def frise_azteque():
    """Frise peinte aztèque sur stuc blanc : deux bandes de grecques à degrés (xicalcoliuhqui),
    rouge sur ocre et turquoise sur rouge ; une bande de pierres de jade (chalchihuitl) ; des
    dents noires et ocre ; des « yeux d'étoiles » sur fond noir ; filets rouges, noirs, turquoise.
    Raccordable dans les deux sens."""
    S = 1024
    K = 2
    SS = S * K
    R = rng(6922)
    img = Image.new("RGB", (SS, SS), (238, 232, 216))
    d = ImageDraw.Draw(img)
    ink = (26, 22, 20)
    red = (176, 46, 34)
    turq = (44, 150, 160)
    ochre = (222, 170, 70)
    blk = (32, 28, 26)
    white = (238, 232, 216)

    def band(y0, y1, c):
        d.rectangle((0, y0 * K, SS, y1 * K - 1), fill=c)

    def outline_rects(rects, fill):
        for (a, b, c_, e) in rects:
            d.rectangle((a * K - 3 * K, b * K - 3 * K, c_ * K + 3 * K, e * K + 3 * K), fill=ink)
        for (a, b, c_, e) in rects:
            d.rectangle((a * K, b * K, c_ * K, e * K), fill=fill)

    band(40, 52, red)
    # grecques 1 : rouge sur ocre
    u = S / (14 * 3)
    band(58, 58 + 8 * u, ochre)
    d.rectangle((0, 58 * K, SS, 58 * K + 3 * K), fill=ink)
    d.rectangle((0, int((58 + 8 * u) * K) - 3 * K, SS, int((58 + 8 * u) * K)), fill=ink)
    rects = []
    for k in range(-1, 4):
        rects += _fret_rects(u, k * 14 * u, 58)
    outline_rects(rects, red)
    y = 58 + 8 * u + 12
    band(y, y + 10, blk)
    # pierres de jade sur fond rouge
    y0 = y + 22
    band(y0, y0 + 112, red)
    d.rectangle((0, y0 * K, SS, y0 * K + 3 * K), fill=ink)
    d.rectangle((0, (y0 + 112) * K - 3 * K, SS, (y0 + 112) * K), fill=ink)
    for k in range(9):
        cx, cy = k * 128 * K, (y0 + 56) * K
        for r, c in ((44, ink), (41, turq), (30, ink), (27, white), (16, ink), (13, turq)):
            d.ellipse((cx - r * K, cy - r * K, cx + r * K, cy + r * K), fill=c)
        for sx in (-1, 1):
            x = cx + sx * 64 * K
            d.ellipse((x - 8 * K, cy - 8 * K, x + 8 * K, cy + 8 * K), fill=ink)
            d.ellipse((x - 5 * K, cy - 5 * K, x + 5 * K, cy + 5 * K), fill=ochre)
    y = y0 + 112 + 18
    band(y, y + 10, red)
    # dents
    y0 = y + 22
    for k in range(17):
        x = k * 64 * K
        c = blk if k % 2 == 0 else ochre
        d.polygon([(x, y0 * K), (x + 64 * K, y0 * K), (x + 32 * K, (y0 + 96) * K)], fill=ink)
        d.polygon([(x + 5 * K, y0 * K + 3 * K), (x + 59 * K, y0 * K + 3 * K), (x + 32 * K, (y0 + 90) * K)], fill=c)
    band(y0, y0 + 4, ink)
    y = y0 + 110
    # yeux d'étoiles sur fond noir
    y0 = y + 12
    band(y0, y0 + 116, blk)
    for row, off in ((0, 0), (1, 64)):
        for k in range(9):
            cx = (k * 128 + off) * K
            cy = (y0 + 30 + row * 56) * K
            d.ellipse((cx - 20 * K, cy - 20 * K, cx + 20 * K, cy + 20 * K), fill=white)
            d.ellipse((cx - 9 * K, cy - 9 * K, cx + 9 * K, cy + 9 * K), fill=red)
            d.ellipse((cx - 20 * K, cy - 20 * K, cx + 20 * K, cy + 20 * K), outline=ink, width=3 * K)
    y = y0 + 116 + 18
    band(y, y + 10, turq)
    # grecques 2 : turquoise sur rouge, dans l'autre sens
    y0 = y + 22
    band(y0, y0 + 8 * u, red)
    d.rectangle((0, y0 * K, SS, y0 * K + 3 * K), fill=ink)
    d.rectangle((0, int((y0 + 8 * u) * K) - 3 * K, SS, int((y0 + 8 * u) * K)), fill=ink)
    rects = []
    for k in range(-1, 4):
        rects += _fret_rects(u, k * 14 * u + 7 * u, y0, flip=True)
    outline_rects(rects, turq)
    y = y0 + 8 * u + 12
    band(y, y + 12, red)
    paint = down(np.asarray(img, np.float32) / 255.0, K)
    del img, d
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    stucco = C(0.9, 0.87, 0.8) * (0.9 + 0.12 * mot[..., None]) * (0.95 + 0.08 * fine[..., None])
    isw = np.clip((paint - np.array([238, 232, 216], np.float32) / 255.0) ** 2, 0, 1).sum(axis=2) < 0.002
    pa = np.where(isw, 0.0, 1.0).astype(np.float32)
    pa = gblur(pa, 0.6)
    keep = smooth(0.26, 0.34, tn(R, S, (8, 16, 32, 64, 128), 0.65) + (fine - 0.5) * 0.2)
    a = pa * (0.45 + 0.55 * keep)
    pnt = mix(paint, stucco, 0.12) * (0.9 + 0.14 * fine[..., None])
    out = mix(stucco, pnt, a)
    wx = tn(R, S, (8, 16, 32), 0.6)
    wy = tn(R, S, (8, 16, 32), 0.6)
    _, edge, _, _, _ = worley(R, S, 8, 0.9)
    edge = warp(edge, (wx - 0.5) * 30, (wy - 0.5) * 30)
    crack = (1 - smooth(0.3, 1.2, edge)) * smooth(0.5, 0.6, tn(R, S, (4, 8, 16), 0.6))
    out = out * (1 - 0.4 * crack[..., None])
    sp = tn(R, S, (16, 32, 64, 128), 0.65)
    spall = smooth(0.8, 0.81, sp)
    out = mix(out, C(0.76, 0.72, 0.66) * (0.85 + 0.3 * fine[..., None]), spall)
    grime = smooth(0.6, 0.85, tn(R, S, (16, 32, 64, 128), 0.6, oy=(4, 8, 16, 32)))
    out = out * (1 - 0.1 * grime[..., None])
    h = 0.5 + mot * 0.12 + fine * 0.04 + a * 0.03 - crack * 0.2 - spall * 0.3
    out = bake(out, h, 3.0, k=0.25, ao=0.2, ao_r=3)
    save_surface("frise_azteque", out, h, 3.0)


def bati():
    calcaire()
    gres()
    brique()
    enduit()
    hieroglyphes()
    pierre_maya()
    stuc_rouge()
    glyphes_maya()
    tezontle()
    frise_azteque()
    dalles_soleil()
    pierre_sombre()


# =================================================================== symboles d'énigme (256 px, RGBA)

STONES = {"eg": (C(0.84, 0.72, 0.54), (150, 52, 34)), "maya": (C(0.74, 0.72, 0.66), (150, 46, 36)),
          "az": (C(0.56, 0.55, 0.52), (160, 50, 36))}


def carve(draw, seed, culture="eg", W=1024, paint=0.6, text=None, out=256, rim=True):
    """Rend un symbole en pierre sculptée (relief, bords biseautés, traits gravés, un peu de
    peinture usée) sur fond transparent. draw(pen) dessine dans une boîte W x W."""
    R = rng(seed)
    col, shp, lin = _layers(W, W)
    pal = {"f": (0, 0, 0, 0), "ink": (0, 0, 0, 0)}
    if culture == "az":
        pal.update({k: v for k, v in PAL_AZ.items() if k != "ink"})
        pal["ink"] = (0, 0, 0, 0)
    draw(Pen((0, 0, W, W), col, shp, lin, pal, lw=0.035))
    if text:
        d = ImageDraw.Draw(shp)
        f = font(int(W * 0.13), bold=True)
        d.text((W / 2, W * 0.86), text, font=f, fill=255, anchor="mm", stroke_width=int(W * 0.012), stroke_fill=255)
        dl = ImageDraw.Draw(lin)
        dl.text((W / 2, W * 0.86), text, font=f, fill=255, anchor="mm")
    sh = _arr(shp)
    ln = _arr(lin.filter(ImageFilter.MaxFilter(5)))
    pc = _arr(col)
    stone, groove_col = STONES[culture]
    mot = tn(R, W, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, W, (64, 128, 256, 512), 0.75)
    inner = smooth(0.9, 0.99, gblur(sh, W / 160))
    ln = ln * inner
    bev = gblur(sh, W / 110)
    h = bev * 0.9 - gblur(ln, W / 500) * 0.35 + mot * 0.05 + fine * 0.03
    base = stone * (0.85 + 0.22 * mot[..., None]) * (0.9 + 0.16 * fine[..., None])
    wear = smooth(0.2, 0.3, tn(R, W, (8, 16, 32, 64, 128), 0.6) + (fine - 0.5) * 0.25)
    pa = pc[..., 3] * paint * wear
    pcol = pc[..., :3] / np.maximum(pc[..., 3:4], 1e-3)
    colr = mix(base, pcol * (0.85 + 0.2 * fine[..., None]), pa)
    gc = np.array(groove_col, np.float32) / 255.0
    colr = mix(colr, colr * 0.45 + gc * 0.25, gblur(ln, W / 600) * 0.9)
    colr = bake(colr, h, W / 140.0, k=0.9, ao=0.4, ao_r=W / 120)
    alpha = smooth(0.35, 0.65, sh)
    if rim:
        halo = np.clip(gblur(sh, W / 120) * 1.6, 0, 1)
        a2 = np.maximum(alpha, halo * 0.55)
        colr = mix(C(0.1, 0.08, 0.07), colr, alpha / np.maximum(a2, 1e-3))
        alpha = a2
    img = Image.fromarray((np.clip(np.dstack([colr, alpha]), 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA")
    if out != W:
        img = img.resize((out, out), Image.LANCZOS)
    return img


def _fitpen(p, aspect, margin=0.06):
    x, y, w, h = fit((margin, margin, 1 - 2 * margin, 1 - 2 * margin), aspect, 1.0)
    return p.sub(x, y, w, h)


EG_SYMS = [("sym_ankh", lambda p: eg_ankh(_fitpen(p, 0.55), "blue")),
           ("sym_oeil", lambda p: eg_wedjat(_fitpen(p, 1.25))),
           ("sym_ibis", lambda p: eg_ibis(_fitpen(p, 1.0))),
           ("sym_soleil", lambda p: eg_sun(_fitpen(p, 1.0, 0.1))),
           ("sym_scarabee", lambda p: eg_scarab(_fitpen(p, 0.8), "blue")),
           ("sym_plume", lambda p: eg_feather(_fitpen(p, 0.34)))]


def symboles():
    """Les symboles des cylindres et des roues : égyptiens, chiffres et jours mayas, soleils
    aztèques."""
    for k, (name, fn) in enumerate(EG_SYMS):
        save_rgba(carve(fn, 6930 + k, "eg", paint=0.75), name + ".png")
    for n in range(1, 14):
        save_rgba(carve(lambda p, n=n: maya_number(p.sub(0.06, 0.06, 0.88, 0.88), n), 6940 + n, "maya", paint=0.5), "sym_num_%d.png" % n)
    for k, (key, label, _) in enumerate(MAYA_DAYS):
        save_rgba(carve(lambda p, key=key: maya_day(p.sub(0.08, 0.0, 0.84, 0.8), key), 6960 + k, "maya", paint=0.5, text=label), "sym_jour_%s.png" % key)
    for k, (key, _, _) in enumerate(SUNS):
        name = "sym_ollin" if key == "ollin" else "sym_soleil_" + key
        save_rgba(carve(lambda p, key=key: az_sun_sign(p.sub(0.04, 0.04, 0.92, 0.92), key), 6990 + k, "az", paint=0.6), name + ".png")


# =================================================================== panneaux peints et gravés

def age_panel(paint, R, base, loss=0.1, fade=0.18, protect=None, cracks=1.0, vignette=0.3, damp=0.25):
    """Vieillit une peinture (RGBA, 0..1) posée sur un fond (RGB) : couleurs passées, écailles
    (la peinture tombe, sauf sur les indices protégés), craquelures, auréoles, bords assombris."""
    H, W = paint.shape[:2]
    big = max(W, H)
    rgb = paint[..., :3]
    a = paint[..., 3]
    fine = tn(R, big, (64, 128, 256, 512), 0.75)[:H, :W]
    chip = tn(R, big, (8, 16, 32, 64, 128), 0.65)[:H, :W]
    lose = smooth(1 - loss - 0.03, 1 - loss + 0.03, chip + (fine - 0.5) * 0.1)
    if protect is not None:
        lose = lose * (1 - protect)
    keep = 1 - lose
    pal = rgb * (1 - fade) + base * fade
    col = base * (1 - (a * keep)[..., None]) + pal * (a * keep)[..., None]
    col = col * (0.93 + 0.1 * fine[..., None])
    if cracks > 0:
        cr = Image.new("L", (W, H), 0)
        d = ImageDraw.Draw(cr)
        for _ in range(int(W * H / 26000 * cracks)):
            x, y = R.uniform(0, W), R.uniform(0, H)
            ang = R.uniform(0, TAU)
            pts = [(x, y)]
            for k in range(int(R.integers(4, 12))):
                ang += R.normal(0, 0.6)
                x += math.cos(ang) * R.uniform(6, 22)
                y += math.sin(ang) * R.uniform(6, 22)
                pts.append((x, y))
            d.line(pts, fill=255, width=1)
        c = np.asarray(cr.filter(ImageFilter.GaussianBlur(0.6)), np.float32)[..., None] / 255.0
        col = col * (1 - 0.4 * c)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    vig = 1 - vignette * (np.abs(xx / W - 0.5) * 2) ** 4 - vignette * (np.abs(yy / H - 0.5) * 2) ** 4
    dmp = smooth(0.62, 0.8, tn(R, big, (2, 4, 8, 16), 0.6)[:H, :W])
    col = col * vig[..., None] * (1 - damp * dmp[..., None])
    return col


def plaster_bg(R, W, H, color, var=0.12):
    big = max(W, H)
    n = tn(R, big, (4, 8, 16, 32, 64), 0.6)[:H, :W]
    f = tn(R, big, (128, 256, 512), 0.8)[:H, :W]
    return np.array(color, np.float32)[None, None, :] * (1 - var + 2 * var * n[..., None]) * (0.95 + 0.1 * f[..., None])


def canvas(W, H, K=2):
    img = Image.new("RGBA", (W * K, H * K), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def finish(img, K):
    a = np.asarray(img, np.float32) / 255.0
    return down(a, K) if K > 1 else a


def pen(img, box, pal=None, lw=0.006, flip=False, ink=None):
    return Pen(box, img, None, None, pal, lw=lw, flip=flip, ink=ink)


# ------------------------------------------------------------------- personnages égyptiens

def eg_head(p, kind="human", skin="skin", wig="black", sex="m"):
    """Tête de profil tournée vers la gauche (boîte du personnage : v = 0 en haut, 1 aux pieds)."""
    if kind in ("human", "osiris", "female"):
        if kind == "female":
            p.poly([(0.44, 0.0), (0.56, -0.01), (0.64, 0.04), (0.66, 0.2), (0.62, 0.3), (0.56, 0.3), (0.55, 0.16), (0.47, 0.13)], wig, sm=1)
        face = [(0.44, 0.02), (0.425, 0.05), (0.41, 0.075), (0.395, 0.088), (0.41, 0.095), (0.405, 0.106), (0.415, 0.114), (0.43, 0.13),
                (0.48, 0.14), (0.53, 0.14), (0.56, 0.06), (0.52, 0.0)]
        p.poly(face, skin, sm=1)
        if kind != "female":
            p.poly([(0.43, 0.012), (0.5, -0.008), (0.6, 0.02), (0.62, 0.17), (0.56, 0.2), (0.53, 0.12), (0.47, 0.06), (0.45, 0.04)], wig, sm=1)
        p.poly([(0.43, 0.06), (0.445, 0.052), (0.47, 0.058), (0.445, 0.07)], "white", w=0.004)
        p.dot(0.448, 0.061, 0.006)
        p.line([(0.47, 0.058), (0.49, 0.062)], 0.004)
        if kind == "osiris":
            p.poly([(0.43, 0.13), (0.45, 0.13), (0.445, 0.19), (0.425, 0.185)], "black", w=0.004)
    elif kind == "jackal":
        p.poly([(0.47, 0.02), (0.5, -0.1), (0.53, -0.1), (0.54, 0.0), (0.56, -0.09), (0.585, -0.08), (0.58, 0.04),
                (0.58, 0.12), (0.5, 0.14), (0.44, 0.1), (0.32, 0.09), (0.31, 0.065), (0.42, 0.04)], "black", sm=1)
        p.poly([(0.42, 0.06), (0.445, 0.05), (0.46, 0.06), (0.44, 0.068)], "yellow", w=0.003)
        p.poly([(0.55, 0.04), (0.62, 0.05), (0.63, 0.2), (0.56, 0.22), (0.53, 0.13)], wig, sm=1)
        for y in (0.08, 0.12, 0.16):
            p.line([(0.555, y), (0.625, y + 0.005)], 0.004, "yellow")
    elif kind == "ibis":
        p.poly([(0.52, 0.0), (0.57, 0.05), (0.56, 0.13), (0.49, 0.14), (0.44, 0.09), (0.43, 0.05), (0.47, 0.01)], "black", sm=1)
        p.stroke(chaikin([(0.44, 0.06), (0.37, 0.08), (0.32, 0.13), (0.3, 0.21)], 2, False), 0.02, "black")
        p.ell(0.475, 0.05, 0.012, 0.012, "white", w=0.003)
        p.dot(0.475, 0.05, 0.005)
        p.poly([(0.52, 0.04), (0.62, 0.05), (0.63, 0.2), (0.56, 0.22), (0.53, 0.12)], wig, sm=1)
        for y in (0.08, 0.12, 0.16):
            p.line([(0.535, y), (0.625, y + 0.005)], 0.004, "yellow")
    elif kind == "falcon":
        p.poly([(0.5, 0.0), (0.56, 0.03), (0.57, 0.12), (0.5, 0.14), (0.45, 0.11), (0.43, 0.09), (0.415, 0.1), (0.42, 0.07), (0.44, 0.03)], "green", sm=1)
        p.poly([(0.44, 0.06), (0.42, 0.075), (0.42, 0.1), (0.4, 0.09), (0.405, 0.065)], "yellow", w=0.003)
        p.ell(0.475, 0.055, 0.012, 0.012, "white", w=0.003)
        p.dot(0.473, 0.055, 0.006)
        p.line(bez((0.475, 0.07), (0.47, 0.1), (0.49, 0.12)), 0.006)
        p.poly([(0.54, 0.03), (0.62, 0.05), (0.63, 0.2), (0.56, 0.22), (0.54, 0.12)], wig, sm=1)
        for y in (0.08, 0.12, 0.16):
            p.line([(0.545, y), (0.625, y + 0.005)], 0.004, "yellow")


def eg_figure(p, head="human", skin="skin", kilt="white", wig="black", arms=None, female=False, dress="white",
              crown=None, collar=("blue", "red", "green"), pose="stand"):
    """Personnage égyptien debout tourné vers la gauche (épaules de face, hanches et jambes de
    profil). Boîte : v = 0 sommet de la tête, v = 1 sous les pieds. arms : ((coude, poignet)
    du bras arrière, (coude, poignet) du bras avant), en coordonnées de la boîte."""
    sk = skin
    if arms is None:
        arms = (((0.63, 0.32), (0.62, 0.45)), ((0.36, 0.31), (0.3, 0.42)))
    (be, bw), (fe, fw) = arms
    dark = tuple(int(c * 0.82) for c in p.c(sk)[:3]) + (255,)
    # bras arrière
    p.poly(tube([(0.6, 0.19), be, bw], 0.05, 0.034), dark)
    p.ell(bw[0], bw[1] + 0.012, 0.02, 0.022, dark, w=0.004)
    if female:
        p.poly([(0.47, 0.6), (0.43, 0.97), (0.39, 0.97), (0.43, 0.6)], dark)
        p.poly([(0.42, 0.97), (0.3, 1.0), (0.43, 1.0)], dark, sm=0)
        p.poly([(0.53, 0.6), (0.55, 0.97), (0.51, 0.97), (0.5, 0.6)], sk)
        p.poly([(0.56, 0.97), (0.46, 1.0), (0.58, 1.0)], sk)
        p.poly([(0.38, 0.17), (0.62, 0.17), (0.6, 0.3), (0.58, 0.5), (0.6, 0.92), (0.44, 0.94), (0.42, 0.5), (0.39, 0.3)], sk, sm=1)
        p.poly([(0.41, 0.26), (0.61, 0.26), (0.59, 0.5), (0.61, 0.93), (0.43, 0.95), (0.42, 0.5)], dress, sm=1)
        p.ell(0.4, 0.25, 0.025, 0.028, sk, w=0.004)
        p.line([(0.5, 0.17), (0.49, 0.27)], 0.006, "red")
        p.line([(0.55, 0.17), (0.57, 0.27)], 0.006, "red")
    else:
        p.poly(tube([(0.53, 0.46), (0.56, 0.72), (0.6, 0.97)], 0.075, 0.035), dark)
        p.poly([(0.63, 0.975), (0.5, 1.0), (0.64, 1.0)], dark)
        p.poly(tube([(0.47, 0.46), (0.42, 0.72), (0.38, 0.97)], 0.075, 0.035), sk)
        p.poly([(0.41, 0.975), (0.27, 1.0), (0.42, 1.0)], sk)
        p.poly([(0.36, 0.17), (0.64, 0.17), (0.62, 0.26), (0.57, 0.36), (0.565, 0.45), (0.445, 0.45), (0.42, 0.36), (0.38, 0.26)], sk, sm=1)
        p.poly([(0.43, 0.43), (0.57, 0.43), (0.6, 0.66), (0.41, 0.66), (0.31, 0.62), (0.42, 0.48)], kilt, sm=0)
        for x in (0.46, 0.5, 0.54):
            p.line([(x, 0.47), (x + 0.02, 0.65)], 0.003)
        p.poly([(0.43, 0.42), (0.57, 0.42), (0.575, 0.45), (0.43, 0.45)], "red", w=0.003)
    if collar:
        pts = [(0.37, 0.17), (0.63, 0.17)] + ellp(0.5, 0.17, 0.13, 0.09, 0, 180, 16)
        p.poly(pts, collar[0])
        p.line(ellp(0.5, 0.17, 0.1, 0.065, 10, 170, 14), 0.007, collar[1])
        p.line(ellp(0.5, 0.17, 0.115, 0.078, 10, 170, 14), 0.005, collar[2])
    p.poly([(0.47, 0.11), (0.54, 0.11), (0.545, 0.17), (0.465, 0.17)], sk, w=0.004)
    eg_head(p, head, sk if head in ("human", "osiris", "female") else sk, wig)
    if crown == "hedjet":
        p.poly([(0.44, 0.03), (0.42, -0.06), (0.455, -0.16), (0.49, -0.2), (0.52, -0.16), (0.55, -0.06), (0.56, 0.04)], "white", sm=1)
        p.poly([(0.4, 0.02), (0.36, -0.14), (0.42, -0.04)], "white", sm=1)
        p.poly([(0.6, 0.02), (0.64, -0.14), (0.58, -0.04)], "white", sm=1)
    elif crown == "sun":
        p.disc(0.5, -0.085, 0.09, "yellow")
        p.disc(0.5, -0.085, 0.075, "red", ol=False)
        p.poly([(0.41, -0.01), (0.39, -0.08), (0.41, -0.13), (0.435, -0.08), (0.43, 0.0)], "green", w=0.003)
    elif crown == "isis":
        p.poly([(0.46, -0.06), (0.54, -0.06), (0.54, 0.0), (0.46, 0.0)], "yellow", w=0.004)
        p.poly([(0.48, -0.1), (0.52, -0.1), (0.52, -0.06), (0.48, -0.06)], "yellow", w=0.004)
    elif crown == "nephthys":
        p.poly([(0.44, -0.07), (0.56, -0.07), (0.56, -0.02), (0.44, -0.02)], "yellow", w=0.004)
        p.poly(ellp(0.5, -0.07, 0.05, 0.04, 180, 360, 10), "yellow", w=0.004)
    # bras avant
    p.poly(tube([(0.4, 0.19), fe, fw], 0.05, 0.034), sk)
    p.ell(fw[0], fw[1] + 0.012, 0.02, 0.022, sk, w=0.004)
    return fw, bw


def eg_wings(p, shoulder, tip_dir=-1, span=0.55, cols=("blue", "red", "green")):
    """Des ailes de déesse déployées vers l'avant (rangées de plumes colorées)."""
    sx, sy = shoulder
    for k, c in enumerate(cols):
        t = k / len(cols)
        y0 = sy + t * 0.12
        pts = [(sx, y0), (sx + tip_dir * span * (1 - t * 0.25), y0 - 0.12 + t * 0.06),
               (sx + tip_dir * span * (1 - t * 0.25), y0 - 0.05 + t * 0.06), (sx, y0 + 0.06)]
        p.poly(pts, c, sm=1, w=0.004)
        for j in range(1, 9):
            x = sx + tip_dir * span * (1 - t * 0.25) * j / 9
            p.line([(x, y0 - 0.1 * j / 9 + t * 0.05), (x, y0 + 0.04 - 0.02 * j / 9 + t * 0.05)], 0.003)


def eg_borders(d, W, H, K, top=True, bottom=True):
    """Bandeaux égyptiens : frise de khékérou en haut, filets de couleur en bas."""
    cols = [(44, 98, 156), (172, 62, 38), (48, 122, 92), (216, 164, 64)]
    if top:
        d.rectangle((0, 0, W * K, 46 * K), fill=(236, 228, 206, 255))
        for k in range(0, W * K, 26 * K):
            c = cols[(k // (26 * K)) % 3]
            d.rounded_rectangle((k + 4 * K, 4 * K, k + 20 * K, 36 * K), radius=7 * K, fill=c + (255,), outline=(30, 24, 20, 255), width=K)
            d.ellipse((k + 7 * K, 30 * K, k + 17 * K, 42 * K), fill=c + (255,), outline=(30, 24, 20, 255), width=K)
        for i, c in enumerate(((30, 24, 20), (44, 98, 156), (216, 164, 64), (172, 62, 38))):
            d.rectangle((0, (46 + i * 5) * K, W * K, (51 + i * 5) * K), fill=c + (255,))
    if bottom:
        for i, c in enumerate(((172, 62, 38), (216, 164, 64), (44, 98, 156), (30, 24, 20), (172, 62, 38))):
            d.rectangle((0, (H - 34 + i * 7) * K, W * K, (H - 27 + i * 7) * K), fill=c + (255,))


def eg_text_column(img, R, x, y, w, h, n=4, pal=None, exclude=("scarabee",)):
    """Une petite colonne de hiéroglyphes décoratifs."""
    names = [k for k in EG_SIGNS if k not in exclude]
    cy = y
    step = h / n
    for k in range(n):
        name = names[R.integers(len(names))]
        fn, asp, cat = EG_SIGNS[name]
        fn(Pen(fit((x, cy, w, step), asp, 0.82), img, None, None, pal, lw=0.05))
        cy += step


def heart_jar(p):
    """Le cœur « ib » : un petit vase à anses."""
    p.poly([(0.3, 0.2), (0.7, 0.2), (0.82, 0.45), (0.78, 0.8), (0.6, 0.98), (0.4, 0.98), (0.22, 0.8), (0.18, 0.45)], "red", sm=1)
    p.poly([(0.36, 0.06), (0.64, 0.06), (0.66, 0.22), (0.34, 0.22)], "red")
    for sx in (0.16, 0.84):
        p.ell(sx, 0.3, 0.07, 0.07, "red")


def scales(d, img, cx, top, bottom, beam, K, pal, half=170):
    """La grande balance : le montant, le fléau, les deux plateaux et le fil à plomb."""
    p = pen(img, (cx - half * K, top, 2 * half * K, bottom - top), pal, lw=0.004)
    ink = p.c("ink")
    p.poly([(0.475, 0.06), (0.525, 0.06), (0.53, 0.96), (0.47, 0.96)], "yellow")
    p.poly([(0.36, 0.96), (0.64, 0.96), (0.68, 1.0), (0.32, 1.0)], "white")
    p.poly([(0.44, 0.0), (0.56, 0.0), (0.53, 0.08), (0.47, 0.08)], "green")
    p.poly([(0.06, 0.1), (0.94, 0.1), (0.94, 0.125), (0.06, 0.125)], "yellow")
    p.line([(0.5, 0.125), (0.5, 0.24)], 0.003)
    p.poly([(0.48, 0.24), (0.52, 0.24), (0.5, 0.28)], "yellow")
    pans = []
    for x in (0.13, 0.87):
        for dx in (-0.1, 0.0, 0.1):
            p.line([(x, 0.125), (x + dx, 0.5)], 0.0025)
        p.poly(ellp(x, 0.5, 0.12, 0.035, 0, 180, 16), "yellow")
        pans.append((x, 0.5))
    del ink
    return p, pans


def ammit(p):
    """Ammit la Dévoreuse, assise, tournée vers la gauche : tête de crocodile, avant de lion,
    arrière d'hippopotame."""
    p.poly([(0.55, 0.45), (0.8, 0.4), (0.98, 0.52), (1.0, 0.8), (0.92, 1.0), (0.62, 1.0), (0.56, 0.8)], "skin", sm=1)
    p.poly([(0.84, 0.82), (0.86, 1.0), (0.96, 1.0), (0.95, 0.8)], "skin")
    p.poly([(0.3, 0.38), (0.56, 0.4), (0.62, 0.62), (0.58, 0.8), (0.44, 0.82), (0.32, 0.62)], "yellow", sm=1)
    for x0 in (0.34, 0.46):
        p.poly([(x0, 0.7), (x0 + 0.08, 0.7), (x0 + 0.08, 0.97), (x0 + 0.1, 1.0), (x0 - 0.04, 1.0), (x0, 0.96)], "yellow")
    p.poly([(0.28, 0.2), (0.42, 0.16), (0.5, 0.3), (0.5, 0.5), (0.36, 0.56), (0.26, 0.44)], "blue", sm=1)
    for y in (0.26, 0.34, 0.42):
        p.line([(0.3, y), (0.48, y + 0.02)], 0.006, "yellow")
    p.poly([(0.36, 0.16), (0.2, 0.15), (0.0, 0.2), (0.0, 0.25), (0.18, 0.26), (0.0, 0.3), (0.02, 0.34), (0.26, 0.34), (0.38, 0.3)], "green", sm=0)
    for x in np.linspace(0.04, 0.2, 6):
        p.poly([(x, 0.245), (x + 0.012, 0.275), (x + 0.024, 0.245)], "white", w=0.002)
    p.dot(0.3, 0.19, 0.012)
    p.line(bez((0.6, 0.6), (0.7, 0.55), (0.78, 0.62)), 0.005)


def fresque_pesee():
    """La pesée du cœur : Anubis règle la balance ; sur un plateau le cœur, sur l'autre la plume
    de Maât ; Thot à tête d'ibis écrit le verdict ; Ammit attend, assise sur son socle."""
    W, H, K = 1024, 512, 2
    R = rng(6971)
    img, d = canvas(W, H, K)
    eg_borders(d, W, H, K)
    pal = None
    base_y = (H - 40) * K
    fh = 330 * K
    # la balance
    p, pans = scales(d, img, 430 * K, 150 * K, base_y, 0, K, pal, half=170)
    sc = p
    lp = sc.sub(pans[0][0] - 0.1, pans[0][1] - 0.15, 0.2, 0.15)
    heart_jar(lp)
    rp = sc.sub(pans[1][0] - 0.1, pans[1][1] - 0.3, 0.2, 0.3)
    eg_feather(rp.sub(0.25, 0.0, 0.5, 1.0), "white")
    # Anubis, à gauche, la main sur le fil à plomb
    pa = pen(img, (165 * K - fh // 2, base_y - fh, fh, fh), pal, flip=True)
    eg_figure(pa, head="jackal", skin="skin", kilt="white", wig="blue",
              arms=(((0.66, 0.32), (0.72, 0.42)), ((0.3, 0.27), (0.14, 0.3))))
    # Ammit sur son socle, tournée vers la balance
    d.rectangle((640 * K, base_y - 70 * K, 790 * K, base_y), fill=(236, 228, 206, 255), outline=(30, 24, 20, 255), width=2 * K)
    for k in range(5):
        d.line([(640 * K, base_y - (14 + k * 12) * K), (790 * K, base_y - (14 + k * 12) * K)], fill=(44, 98, 156, 255) if k % 2 else (172, 62, 38, 255), width=3 * K)
    ammit(pen(img, (628 * K, base_y - 70 * K - 170 * K, 170 * K, 170 * K), pal))
    # Thot écrit, tourné vers la gauche
    pt = pen(img, (900 * K - fh // 2, base_y - fh, fh, fh), pal)
    fw, bw = eg_figure(pt, head="ibis", skin="skin", kilt="white", wig="blue",
                       arms=(((0.6, 0.32), (0.5, 0.3)), ((0.38, 0.28), (0.36, 0.22))))
    pt.poly([(0.3, 0.16), (0.37, 0.15), (0.38, 0.3), (0.31, 0.31)], "white", w=0.004)
    pt.line([(0.33, 0.19), (0.33, 0.27)], 0.003, "red")
    pt.line([(0.35, 0.19), (0.35, 0.27)], 0.003)
    pt.line([(0.48, 0.29), (0.34, 0.2)], 0.005, "black")
    # inscriptions
    for x in (30, 66, 640, 676, 712, 748, 990):
        eg_text_column(img, R, x * K - 14 * K, 70 * K, 28 * K, 104 * K, 4)
    paint = finish(img, K)
    base = plaster_bg(R, W, H, (0.88, 0.8, 0.62))
    save_rgb(age_panel(paint, R, base, loss=0.07), "fresque_pesee.png")


def barque(p, fill="yellow"):
    """La barque solaire : coque en croissant, proue et poupe en ombelle de papyrus."""
    hull = [(0.02, 0.1), (0.1, 0.5), (0.3, 0.72), (0.7, 0.72), (0.9, 0.5), (0.98, 0.1), (0.94, 0.12), (0.84, 0.46), (0.7, 0.56),
            (0.3, 0.56), (0.16, 0.46), (0.06, 0.12)]
    p.poly(hull, fill, sm=1)
    p.poly([(0.06, 0.1), (0.0, 0.0), (0.12, 0.02)], "green")
    p.poly([(0.94, 0.1), (1.0, 0.0), (0.88, 0.02)], "green")
    for x in np.linspace(0.25, 0.75, 9):
        p.line([(x, 0.58), (x, 0.7)], 0.004)


def apophis(p, R):
    """Apophis, le grand serpent du chaos, enroulé en boucles, percé de couteaux."""
    pts = []
    for k in range(160):
        t = k / 159
        x = 0.06 + t * 0.84
        y = 0.52 + 0.34 * math.sin(t * TAU * 3.0) * (0.7 + 0.3 * t)
        pts.append((x, y))
    p.poly(tube(pts, 0.07, 0.15), "yellow")
    for k in range(2, 158, 3):
        (x0, y0), (x1, y1) = pts[k - 1], pts[k + 1]
        nx, ny = -(y1 - y0), (x1 - x0)
        L = math.hypot(nx, ny) or 1
        w = (0.07 + 0.08 * k / 159) * 0.45
        p.line([(pts[k][0] - nx / L * w * 0.18, pts[k][1] - ny / L * w), (pts[k][0] + nx / L * w * 0.18, pts[k][1] + ny / L * w)], 0.006)
    for k in range(0, 160, 6):
        x, y = pts[k]
        p.dot(x, y, 0.012, "red")
    hx, hy = pts[-1]
    p.poly([(hx - 0.02, hy - 0.08), (hx + 0.07, hy - 0.06), (hx + 0.08, hy - 0.02), (hx + 0.03, hy + 0.0), (hx + 0.08, hy + 0.03),
            (hx + 0.06, hy + 0.07), (hx - 0.02, hy + 0.07)], "yellow", sm=1)
    p.dot(hx + 0.035, hy - 0.04, 0.01)
    for t in (0.12, 0.3, 0.46, 0.63, 0.8):
        x, y = pts[int(t * 159)]
        p.poly([(x - 0.004, y), (x + 0.004, y), (x + 0.026, y - 0.3), (x + 0.012, y - 0.3)], "white", w=0.003)
        p.poly([(x + 0.01, y - 0.3), (x + 0.03, y - 0.3), (x + 0.036, y - 0.44), (x + 0.016, y - 0.44)], "red", w=0.003)


def fresque_barque():
    """Le voyage de nuit : Rê, tête de faucon coiffée du disque, dans sa barque sous les
    étoiles ; dessous, Apophis enroulé, transpercé par la lance du gardien de la proue."""
    W, H, K = 1024, 512, 2
    R = rng(6972)
    img, d = canvas(W, H, K)
    d.rectangle((0, 0, W * K, H * K), fill=(22, 30, 58, 255))
    for _ in range(140):
        x, y = R.uniform(0, W * K), R.uniform(60 * K, 300 * K)
        r = R.uniform(4, 9) * K
        pts = []
        for k in range(10):
            a = -math.pi / 2 + k * math.pi / 5
            rr = r if k % 2 == 0 else r * 0.4
            pts.append((x + math.cos(a) * rr, y + math.sin(a) * rr))
        d.polygon(pts, fill=(230, 196, 90, 255))
    eg_borders(d, W, H, K)
    # l'eau de la Douat
    for k in range(4):
        y = (318 + k * 12) * K
        d.line([(x * K, y + (6 * K if (x // 12) % 2 else 0)) for x in range(0, W + 12, 12)], fill=(70, 130, 190, 255), width=3 * K)
    # la barque
    pb = pen(img, (250 * K, 210 * K, 560 * K, 140 * K))
    barque(pb)
    # le naos et Rê
    for x in (462, 618):
        d.rectangle(((x - 4) * K, 108 * K, (x + 4) * K, 296 * K), fill=(214, 164, 62, 255), outline=(30, 24, 20, 255), width=K)
    d.rectangle((452 * K, 100 * K, 628 * K, 112 * K), fill=(48, 122, 92, 255), outline=(30, 24, 20, 255), width=K)
    for k in range(15):
        d.line([(456 * K + k * 12 * K, 100 * K), (460 * K + k * 12 * K, 90 * K)], fill=(172, 62, 38, 255), width=3 * K)
    fh = 200 * K
    pr = pen(img, (540 * K - fh // 2, 298 * K - fh, fh, fh), flip=True)
    fw, _ = eg_figure(pr, head="falcon", skin="skin", kilt="white", wig="blue", crown="sun",
                      arms=(((0.64, 0.32), (0.6, 0.44)), ((0.36, 0.3), (0.28, 0.28))))
    pr.stroke([(0.27, 0.04), (0.29, 0.98)], 0.018, "yellow")
    pr.poly([(0.23, 0.05), (0.31, 0.02), (0.33, 0.06)], "yellow")
    # le gardien de la proue et sa lance
    fh2 = 160 * K
    pg = pen(img, (330 * K - fh2 // 2, 290 * K - fh2, fh2, fh2))
    eg_figure(pg, head="human", skin="skin", kilt="white", wig="black",
              arms=(((0.56, 0.3), (0.46, 0.4)), ((0.4, 0.3), (0.36, 0.42))))
    d.line([(345 * K, 210 * K), (196 * K, 450 * K)], fill=(30, 24, 20, 255), width=6 * K)
    d.line([(345 * K, 210 * K), (196 * K, 450 * K)], fill=(214, 164, 62, 255), width=3 * K)
    d.polygon([(196 * K, 450 * K), (206 * K, 428 * K), (190 * K, 432 * K)], fill=(220, 220, 214, 255), outline=(30, 24, 20, 255))
    # Apophis
    pa = pen(img, (150 * K, 352 * K, 760 * K, 120 * K), lw=0.008, flip=True)
    apophis(pa, R)
    paint = finish(img, K)
    base = plaster_bg(R, W, H, (0.84, 0.76, 0.58))
    prot = np.zeros((H, W), np.float32)
    prot[60:310, 430:650] = 1.0
    prot[340:480, 140:920] = 0.8
    save_rgb(age_panel(paint, R, base, loss=0.06, fade=0.12, protect=prot), "fresque_barque.png")


def lion_bier(p):
    """Le lit funéraire à tête et pattes de lion (tourné vers la droite)."""
    p.poly([(0.06, 0.32), (0.86, 0.32), (0.88, 0.42), (0.06, 0.42)], "yellow")
    for x in (0.12, 0.78):
        p.poly([(x, 0.42), (x + 0.06, 0.42), (x + 0.07, 0.86), (x + 0.1, 0.92), (x - 0.01, 0.94), (x, 0.86)], "yellow")
    p.poly([(0.84, 0.32), (0.9, 0.04), (0.98, 0.02), (1.0, 0.1), (0.96, 0.2), (0.92, 0.36)], "yellow", sm=1)
    p.dot(0.95, 0.07, 0.012)
    p.line(bez((0.9, 0.08), (0.88, 0.2), (0.92, 0.3)), 0.006)
    p.line(bez((0.06, 0.34), (0.0, 0.2), (0.04, 0.06)), 0.012, "yellow")


def fresque_osiris():
    """Osiris momifié, vert, couronne blanche, crosse et fouet, couché sur le lit à tête de lion ;
    Isis à la tête et Nephthys aux pieds le protègent de leurs ailes ; quatre vases canopes."""
    W, H, K = 1024, 512, 2
    R = rng(6973)
    img, d = canvas(W, H, K)
    eg_borders(d, W, H, K)
    pb = pen(img, (250 * K, 268 * K, 520 * K, 190 * K), lw=0.006)
    lion_bier(pb)
    # Osiris couché sur le dos, la tête à droite (côté lion), le visage vers le ciel
    po = pen(img, (280 * K, 216 * K, 380 * K, 60 * K), lw=0.012)
    po.poly([(0.0, 0.8), (0.02, 0.45), (0.12, 0.3), (0.82, 0.2), (0.86, 0.6), (0.82, 0.96), (0.08, 0.98)], "white", sm=1)
    for x in np.linspace(0.1, 0.78, 14):
        po.line([(x, 0.3), (x - 0.02, 0.95)], 0.012)
    po.poly([(0.8, 0.18), (0.88, 0.0), (0.97, 0.02), (1.0, 0.4), (0.97, 0.85), (0.86, 0.9), (0.81, 0.6)], "green", sm=1)
    po.poly([(0.88, 0.02), (0.9, -0.12), (0.92, -0.02)], "green")
    po.poly([(0.84, 0.04), (0.82, -0.3), (0.8, -0.34), (0.86, -0.3), (0.86, 0.04)], "black")
    po.dot(0.93, 0.25, 0.05)
    po.poly([(0.97, 0.1), (1.14, 0.18), (1.2, 0.42), (1.14, 0.68), (0.97, 0.75)], "white", sm=1)
    po.ell(1.2, 0.42, 0.03, 0.12, "white")
    for k, (c, a) in enumerate((("blue", -0.55), ("yellow", -0.25))):
        po.stroke([(0.5, 0.3), (0.5 + a * 0.2, -0.9)], 0.07, c)
    po.stroke(chaikin([(0.39, -0.9), (0.36, -1.15), (0.3, -1.2), (0.27, -1.08)], 2, False), 0.07, "blue")
    for k in range(3):
        po.line([(0.45, -0.9), (0.4 + k * 0.05, -1.35)], 0.04, "red")
    po.ell(0.48, 0.15, 0.06, 0.22, "green")
    # Isis (à la tête, à droite) et Nephthys (aux pieds, à gauche), ailes tendues vers lui
    fh = 300 * K
    pi = pen(img, (905 * K - fh // 2, (H - 40) * K - fh, fh, fh))
    eg_wings(pi, (0.4, 0.22), -1, 0.36)
    eg_figure(pi, head="female", skin="lskin", female=True, dress="red", wig="black", crown="isis",
              arms=(((0.66, 0.26), (0.7, 0.18)), ((0.34, 0.24), (0.22, 0.2))))
    pn = pen(img, (125 * K - fh // 2, (H - 40) * K - fh, fh, fh), flip=True)
    eg_wings(pn, (0.4, 0.22), -1, 0.4)
    eg_figure(pn, head="female", skin="lskin", female=True, dress="green", wig="black", crown="nephthys",
              arms=(((0.66, 0.26), (0.7, 0.18)), ((0.34, 0.24), (0.22, 0.2))))
    # vases canopes
    for k, hd in enumerate(("human", "jackal", "falcon", "human")):
        x = 360 + k * 70
        pc = pen(img, (x * K, 380 * K, 46 * K, 70 * K), lw=0.03)
        pc.poly([(0.15, 0.3), (0.85, 0.3), (0.9, 0.7), (0.75, 1.0), (0.25, 1.0), (0.1, 0.7)], "white", sm=1)
        pc.ell(0.5, 0.18, 0.3, 0.18, "blue" if hd != "human" else "yellow")
    for x in (330, 366, 402, 600, 636, 672):
        eg_text_column(img, R, x * K - 14 * K, 64 * K, 28 * K, 96 * K, 4)
    paint = finish(img, K)
    base = plaster_bg(R, W, H, (0.9, 0.8, 0.56))
    save_rgb(age_panel(paint, R, base, loss=0.07), "fresque_osiris.png")


def papyrus_plant(p, n=7, R=None):
    """Un fourré de papyrus : tiges vertes fines et ombelles en éventail."""
    for k in range(n):
        x = 0.06 + 0.88 * k / max(1, n - 1)
        top = 0.14 + 0.22 * ((k * 37) % 7) / 7
        tilt = (x - 0.5) * 0.35
        p.stroke([(x, 1.0), (x + tilt, top)], 0.016, "green")
        tx = x + tilt
        fan = [(tx, top)] + ellp(tx, top, 0.11, 0.14, 205, 335, 10)
        p.poly(fan, "green", sm=0, w=0.004)
        p.poly(ellp(tx, top, 0.11, 0.14, 205, 335, 10) + ellp(tx, top - 0.1, 0.1, 0.05, 335, 205, 10)[::-1][::-1], "yellow", w=0.004)


def fish(p, fill="blue"):
    p.poly([(0.0, 0.5), (0.2, 0.15), (0.6, 0.12), (0.8, 0.4), (1.0, 0.1), (1.0, 0.9), (0.8, 0.6), (0.6, 0.88), (0.2, 0.85)], fill, sm=1)
    p.dot(0.16, 0.42, 0.06)
    for x in (0.4, 0.55):
        p.line([(x, 0.25), (x, 0.75)], 0.03)


def bird_fly(p, fill="white"):
    p.poly([(0.0, 0.5), (0.2, 0.42), (0.6, 0.45), (1.0, 0.55), (0.6, 0.6), (0.2, 0.58)], fill, sm=1)
    p.poly([(0.35, 0.45), (0.6, 0.0), (0.75, 0.05), (0.6, 0.48)], "blue", sm=1)
    p.poly([(0.4, 0.55), (0.5, 1.0), (0.62, 0.95), (0.58, 0.56)], "green", sm=1)
    p.dot(0.08, 0.48, 0.04)


def fresque_nil():
    """La vie au bord de l'Iterou : en haut la moisson (faucilles, gerbes, une glaneuse) et un
    chadouf qui puise l'eau du canal ; en bas, deux barques de papyrus et leurs pêcheurs tirent
    un filet plein de poissons ; à gauche, le fourré de papyrus et ses oiseaux."""
    W, H, K = 1024, 512, 2
    R = rng(6974)
    img, d = canvas(W, H, K)
    eg_borders(d, W, H, K)
    ink = (30, 24, 20, 255)
    mid = 268
    d.rectangle((0, (mid - 4) * K, W * K, mid * K), fill=ink)
    # registre du haut : le champ de blé
    for k in range(70):
        x = (330 + k * 7.5) * K
        if 640 * K < x < 700 * K:
            continue
        d.line([(x, (mid - 4) * K), (x + 4 * K, (mid - 70 - (k % 3) * 6) * K)], fill=(150, 120, 40, 255), width=2 * K)
        d.ellipse((x - 2 * K, (mid - 88 - (k % 3) * 6) * K, x + 9 * K, (mid - 66 - (k % 3) * 6) * K), fill=(222, 178, 70, 255), outline=ink, width=K)
    fh = 150 * K
    for k, x in enumerate((420, 520, 610)):
        pm = pen(img, (x * K - fh // 2, (mid - 4) * K - fh, fh, fh), lw=0.008, flip=True)
        eg_figure(pm, head="human", skin="skin", kilt="white", wig="black", collar=None,
                  arms=(((0.6, 0.34), (0.52, 0.4)), ((0.34, 0.32), (0.24, 0.38))))
        pm.stroke(chaikin([(0.24, 0.38), (0.16, 0.34), (0.12, 0.42), (0.16, 0.48)], 2, False), 0.012, "white")
    pw = pen(img, (300 * K - fh // 2, (mid - 4) * K - fh, fh, fh), lw=0.008, flip=True)
    eg_figure(pw, head="female", skin="lskin", female=True, dress="white", collar=None,
              arms=(((0.66, 0.24), (0.62, 0.12)), ((0.36, 0.24), (0.38, 0.12))))
    pw.poly([(0.3, 0.02), (0.7, 0.02), (0.66, 0.11), (0.34, 0.11)], "yellow")
    for x in (0.36, 0.48, 0.6):
        pw.stroke([(x, 0.02), (x + 0.03, -0.08)], 0.012, "yellow")
    # le chadouf
    sx = 820
    d.rectangle((sx * K, (mid - 150) * K, (sx + 10) * K, (mid - 4) * K), fill=(150, 100, 56, 255), outline=ink, width=K)
    d.line([((sx - 70) * K, (mid - 170) * K), ((sx + 110) * K, (mid - 110) * K)], fill=ink, width=7 * K)
    d.line([((sx - 70) * K, (mid - 170) * K), ((sx + 110) * K, (mid - 110) * K)], fill=(170, 120, 66, 255), width=4 * K)
    d.ellipse(((sx + 92) * K, (mid - 124) * K, (sx + 132) * K, (mid - 88) * K), fill=(110, 80, 50, 255), outline=ink, width=K)
    d.line([((sx - 70) * K, (mid - 170) * K), ((sx - 70) * K, (mid - 70) * K)], fill=ink, width=2 * K)
    d.rounded_rectangle(((sx - 84) * K, (mid - 72) * K, (sx - 56) * K, (mid - 48) * K), radius=6 * K, fill=(172, 62, 38, 255), outline=ink, width=K)
    d.rectangle(((sx - 130) * K, (mid - 30) * K, (sx - 20) * K, (mid - 4) * K), fill=(70, 130, 190, 255), outline=ink, width=K)
    pf = pen(img, ((sx + 70) * K - fh // 2, (mid - 4) * K - fh, fh, fh), lw=0.008)
    eg_figure(pf, head="human", skin="skin", kilt="white", wig="black", collar=None,
              arms=(((0.58, 0.24), (0.52, 0.12)), ((0.4, 0.24), (0.36, 0.1))))
    # registre du bas : le fleuve
    d.rectangle((150 * K, (mid + 118) * K, W * K, (H - 36) * K), fill=(64, 112, 168, 255))
    for k in range(6):
        y = (mid + 126 + k * 15) * K
        d.line([(x * K, y + (5 * K if (x // 10) % 2 else 0)) for x in range(150, W + 10, 10)], fill=(26, 30, 40, 255), width=2 * K)
    # le filet entre les barques
    for k in range(8):
        d.line([((560 + k * 14) * K, (mid + 86) * K), ((540 + k * 18) * K, (mid + 150) * K)], fill=ink, width=K)
    for k in range(5):
        d.line([(548 * K, (mid + 90 + k * 13) * K), (690 * K, (mid + 90 + k * 13) * K)], fill=ink, width=K)
    for (x, y, c) in ((560, 118, "blue"), (610, 132, "yellow"), (650, 112, "blue"), (590, 145, "green")):
        fish(pen(img, (x * K, (mid + y - 9) * K, 36 * K, 18 * K), lw=0.05), c)
    for bx, flip in ((330, False), (780, True)):
        pbt = pen(img, ((bx - 110) * K, (mid + 70) * K, 220 * K, 60 * K), lw=0.02)
        pbt.poly([(0.0, 0.0), (0.12, 0.7), (0.3, 1.0), (0.7, 1.0), (0.88, 0.7), (1.0, 0.0), (0.84, 0.5), (0.16, 0.5)], "green", sm=1)
        for x in np.linspace(0.18, 0.82, 10):
            pbt.line([(x, 0.55), (x, 0.95)], 0.02, "yellow")
        for j, off in enumerate((-40, 30)):
            pm = pen(img, ((bx + off) * K - 60 * K, (mid + 100) * K - 120 * K, 120 * K, 120 * K), lw=0.01, flip=(not flip))
            eg_figure(pm, head="human", skin="skin", kilt="white", wig="black", collar=None,
                      arms=(((0.6, 0.3), (0.5, 0.42)), ((0.38, 0.3), (0.26, 0.42))))
    # le fourré de papyrus et ses oiseaux
    papyrus_plant(pen(img, (6 * K, (mid - 130) * K, 200 * K, (H - 36 - mid + 130) * K), lw=0.01), 13)
    for (x, y, s) in ((40, 90, 60), (120, 76, 54), (210, 100, 50), (70, 140, 46)):
        bird_fly(pen(img, (x * K, y * K, s * K, s * 0.6 * K), lw=0.04), "white")
    paint = finish(img, K)
    base = plaster_bg(R, W, H, (0.88, 0.8, 0.6))
    save_rgb(age_panel(paint, R, base, loss=0.07), "fresque_nil.png")


def cartouche_ring(p):
    """L'anneau du cartouche royal (vertical) et sa barre d'attache en bas."""
    out = ellp(0.5, 0.47, 0.46, 0.46, 0, 360, 60)
    p.stroke(out, 0.035, "white")
    p.stroke([(0.1, 0.97), (0.9, 0.97)], 0.04, "white")


def papyrus_thot():
    """Le papyrus de Thot : une feuille de papyrus jaunie aux bords roulés ; Thot à tête d'ibis
    désigne le cartouche du roi, qui contient de haut en bas : l'ibis, l'œil d'Horus, le soleil."""
    W, H, K = 1024, 512, 2
    R = rng(6975)
    img, d = canvas(W, H, K)
    pal = {"ink": (24, 20, 16, 255), "red": (176, 52, 32, 255), "blue": (40, 96, 150, 255), "white": (246, 236, 210, 255),
           "skin": (184, 92, 54, 255), "yellow": (214, 164, 64, 255)}
    # filets rouges et noirs
    for y in (64, 70, 442, 448):
        d.line([(80 * K, y * K), (944 * K, y * K)], fill=(150, 40, 28, 255) if y in (70, 442) else pal["ink"], width=2 * K)
    # Thot
    fh = 330 * K
    pt = pen(img, (270 * K - fh // 2, 430 * K - fh, fh, fh), pal, lw=0.006, flip=True)
    eg_figure(pt, head="ibis", skin="skin", kilt="white", wig="blue",
              arms=(((0.64, 0.32), (0.62, 0.44)), ((0.3, 0.18), (0.13, 0.14))))
    pt.poly([(0.13, 0.12), (0.06, 0.115), (0.06, 0.13), (0.13, 0.14)], "skin", w=0.003)
    pt.stroke([(0.62, 0.42), (0.6, 0.98)], 0.012, "yellow")
    # le cartouche : ibis, œil d'Horus, soleil (de haut en bas), grands et nets
    cx, top, ch, cw = 560, 84, 350, 170
    pc = pen(img, ((cx - cw // 2) * K, top * K, cw * K, ch * K), pal, lw=0.022)
    ring = chaikin([(0.1, 0.08), (0.5, 0.0), (0.9, 0.08), (0.98, 0.5), (0.9, 0.92), (0.5, 0.97), (0.1, 0.92), (0.02, 0.5)], 3)
    pc.stroke(ring + [ring[0]], 0.06, "white")
    pc.stroke([(0.12, 1.0), (0.88, 1.0)], 0.07, "white")
    eg_ibis(pc.sub(0.19, 0.04, 0.62, 0.3))
    eg_wedjat(pc.sub(0.13, 0.37, 0.74, 0.27))
    eg_sun(pc.sub(0.27, 0.68, 0.46, 0.25))
    # colonnes de texte, à l'encre
    names = [k for k in EG_SIGNS if k not in ("scarabee", "plume")]
    inkpal = {k: pal["ink"] for k in ("blue", "green", "yellow", "white", "skin", "gold", "black", "lskin", "cream")}
    inkpal["ink"] = pal["ink"]
    inkpal["red"] = pal["red"]
    for c in range(6):
        x = 700 + c * 40
        y = 90
        for k in range(7):
            name = names[R.integers(len(names))]
            fn, asp, cat = EG_SIGNS[name]
            box = fit((x * K, y * K, 30 * K, 46 * K), asp, 0.8)
            fp = Pen(box, img, None, None, {k2: (v if c != 0 or k != 0 else pal["red"]) for k2, v in inkpal.items()}, lw=0.06)
            fp.pal = {k2: (0, 0, 0, 0) if k2 != "ink" else pal["ink"] for k2 in inkpal}
            fp.pal["ink"] = pal["red"] if (c == 0 and k < 2) else pal["ink"]
            fn(fp)
            y += 50
    for c in range(3):
        x = 100 + c * 40
        y = 90
        for k in range(7):
            name = names[R.integers(len(names))]
            fn, asp, cat = EG_SIGNS[name]
            fp = Pen(fit((x * K, y * K, 30 * K, 46 * K), asp, 0.8), img, None, None, None, lw=0.06)
            fp.pal = {k2: (0, 0, 0, 0) for k2 in PAL_EG}
            fp.pal["ink"] = pal["ink"]
            fn(fp)
            y += 50
    paint = finish(img, K)
    # la feuille de papyrus : fibres croisées, jaunie, bords roulés et usés
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    fh_ = tn(R, 1024, (512, 1024), 0.9, oy=(8, 16))[:H, :W]
    fv = tn(R, 1024, (8, 16), 0.9, oy=(1024, 1024))[:H, :W]
    strip = tn(R, 1024, (16, 32), 0.7, oy=(1, 2))[:H, :W]
    base = C(0.86, 0.76, 0.54) * (0.88 + 0.1 * fh_[..., None] + 0.06 * fv[..., None]) * (0.95 + 0.08 * strip[..., None])
    blot = smooth(0.6, 0.85, tn(R, 1024, (4, 8, 16, 32), 0.6)[:H, :W])
    base = mix(base, base * C(0.82, 0.72, 0.56), blot * 0.6)
    for x in (340, 680):
        base = base * (1 - 0.06 * np.exp(-((xx - x) / 3.0) ** 2))[..., None]
    prot = np.zeros((H, W), np.float32)
    prot[70:440, 150:660] = 1.0
    col = age_panel(paint, R, base, loss=0.04, fade=0.08, protect=prot, cracks=0.4, vignette=0.0, damp=0.15)
    # les rouleaux aux deux bouts
    for x0, x1 in ((0, 56), (W - 56, W)):
        u = (xx[:, x0:x1] - x0) / (x1 - x0)
        cyl = np.sqrt(np.clip(1 - (u * 2 - 1) ** 2, 0, 1))
        col[:, x0:x1] = base[:, x0:x1] * (0.45 + 0.6 * cyl[..., None])
        col[:, x0:x1] *= (1 - 0.15 * (np.sin(u * 30) * 0.5 + 0.5))[..., None]
    edge = np.minimum(np.minimum(yy, H - 1 - yy), 9999)
    torn = tn(R, 1024, (16, 32, 64), 0.6)[:H, :W]
    col = col * (0.55 + 0.45 * smooth(0, 20, edge - torn * 12))[..., None]
    save_rgb(col, "papyrus_thot.png")


# ------------------------------------------------------------------- personnages mayas

PAL_MAYA = {"ink": (28, 20, 18, 255), "red": (176, 48, 36, 255), "blue": (70, 150, 160, 255), "green": (52, 130, 80, 255),
            "yellow": (226, 176, 70, 255), "white": (238, 228, 204, 255), "skin": (166, 92, 58, 255), "black": (30, 26, 24, 255),
            "jade": (60, 160, 110, 255), "f": (234, 220, 186, 255), "wood": (150, 98, 52, 255), "bone": (236, 230, 210, 255),
            "grey": (120, 116, 110, 255), "orange": (220, 120, 50, 255), "brown": (110, 64, 36, 255)}


def maya_fig(p, skin="skin", marks=None, loin="white", head="human", plume="green", arms=None, legs="walk", R=None):
    """Personnage maya de profil, tourné vers la gauche (v = 0 sommet du crâne, 1 sous les pieds) :
    front fuyant, grand nez, ornement d'oreille de jade, bandeau et plumes, pagne blanc à bords
    rouges, sandales. marks : « points » (Hunahpu) ou « jaguar » (Xbalanque)."""
    if arms is None:
        arms = (((0.6, 0.3), (0.56, 0.42)), ((0.4, 0.3), (0.32, 0.4)))
    (be, bw), (fe, fw) = arms
    sk = skin
    dark = tuple(int(c * 0.8) for c in p.c(sk)[:3]) + (255,)
    p.poly(tube([(0.55, 0.2), be, bw], 0.06, 0.04), dark)
    p.ell(bw[0], bw[1] + 0.015, 0.022, 0.025, dark, w=0.004)
    if legs == "walk":
        bl = [(0.54, 0.5), (0.6, 0.74), (0.62, 0.96)]
        fl = [(0.47, 0.5), (0.4, 0.73), (0.38, 0.96)]
    else:
        bl = [(0.53, 0.5), (0.55, 0.74), (0.55, 0.96)]
        fl = [(0.47, 0.5), (0.45, 0.74), (0.45, 0.96)]
    p.poly(tube(bl, 0.09, 0.045), dark)
    p.poly([(bl[-1][0] + 0.03, 0.96), (bl[-1][0] - 0.1, 0.995), (bl[-1][0] + 0.04, 1.0)], dark)
    p.poly(tube(fl, 0.09, 0.045), sk)
    p.poly([(fl[-1][0] + 0.03, 0.96), (fl[-1][0] - 0.1, 0.995), (fl[-1][0] + 0.04, 1.0)], sk)
    for (x, _) in (bl[-1], fl[-1]):
        p.poly([(x - 0.09, 0.99), (x + 0.04, 0.99), (x + 0.04, 1.005), (x - 0.09, 1.005)], "brown", w=0.003)
        p.line([(x - 0.03, 0.95), (x + 0.03, 0.97)], 0.006, "red")
    p.poly([(0.44, 0.17), (0.56, 0.16), (0.6, 0.24), (0.6, 0.42), (0.57, 0.52), (0.44, 0.52), (0.41, 0.4), (0.4, 0.26)], sk, sm=1)
    if marks == "points":
        for (x, y) in ((0.46, 0.26), (0.52, 0.34), (0.47, 0.42), (0.55, 0.28), (0.42, 0.62), (0.4, 0.82), (0.6, 0.66)):
            p.dot(x, y, 0.012, "black")
    elif marks == "jaguar":
        for (x, y) in ((0.47, 0.27), (0.53, 0.37), (0.46, 0.44), (0.42, 0.64), (0.4, 0.84), (0.59, 0.68)):
            p.disc(x, y, 0.02, "yellow")
            p.ring(x, y, 0.02, 0.006)
    # pagne
    p.poly([(0.42, 0.46), (0.59, 0.46), (0.6, 0.53), (0.42, 0.53)], loin)
    p.poly([(0.41, 0.52), (0.48, 0.52), (0.47, 0.7), (0.39, 0.7)], loin)
    p.poly([(0.39, 0.66), (0.47, 0.66), (0.47, 0.7), (0.39, 0.7)], "red", w=0.003)
    p.poly([(0.57, 0.52), (0.63, 0.52), (0.68, 0.64), (0.62, 0.66)], loin)
    # tête
    if head == "human":
        face = [(0.52, 0.0), (0.45, 0.015), (0.425, 0.04), (0.41, 0.065), (0.385, 0.085), (0.4, 0.095), (0.405, 0.105), (0.41, 0.115),
                (0.43, 0.13), (0.47, 0.15), (0.54, 0.15), (0.58, 0.1), (0.58, 0.04)]
        p.poly([(0.47, 0.13), (0.54, 0.13), (0.55, 0.18), (0.47, 0.18)], sk, w=0.004)
        p.poly(face, sk, sm=1)
        p.poly([(0.45, 0.015), (0.52, -0.01), (0.6, 0.02), (0.62, 0.1), (0.57, 0.12), (0.54, 0.05), (0.47, 0.035)], "black", sm=1)
        p.poly([(0.44, 0.02), (0.6, 0.0), (0.61, 0.03), (0.45, 0.045)], "white", w=0.003)
        p.poly([(0.43, 0.06), (0.445, 0.054), (0.465, 0.06), (0.445, 0.068)], "white", w=0.003)
        p.dot(0.446, 0.061, 0.005)
        p.disc(0.54, 0.09, 0.022, "jade")
        p.dot(0.54, 0.09, 0.008)
        if marks == "points":
            p.dot(0.45, 0.1, 0.01, "black")
            p.dot(0.48, 0.115, 0.008, "black")
        elif marks == "jaguar":
            p.disc(0.47, 0.105, 0.013, "yellow")
            p.ring(0.47, 0.105, 0.013, 0.004)
        for k in range(4):
            a = -100 + k * 18
            x0, y0 = 0.56, 0.0
            p.poly([(x0, y0), (x0 + math.cos(math.radians(a - 8)) * 0.18, y0 + math.sin(math.radians(a - 8)) * 0.18),
                    (x0 + math.cos(math.radians(a)) * 0.22, y0 + math.sin(math.radians(a)) * 0.22),
                    (x0 + math.cos(math.radians(a + 8)) * 0.18, y0 + math.sin(math.radians(a + 8)) * 0.18)], plume, w=0.003)
    # bras avant
    p.poly(tube([(0.47, 0.2), fe, fw], 0.06, 0.04), sk)
    p.ell(fw[0], fw[1] + 0.015, 0.022, 0.025, sk, w=0.004)
    p.poly([(fw[0] - 0.03, fw[1] - 0.02), (fw[0] + 0.03, fw[1] - 0.02), (fw[0] + 0.03, fw[1] + 0.0), (fw[0] - 0.03, fw[1] + 0.0)], "jade", w=0.003)


def mosquito(p):
    """Le moustique, vu de profil : ailes claires, corps rayé, longues pattes, trompe."""
    p.poly([(0.38, 0.4), (0.62, 0.0), (0.74, 0.04), (0.5, 0.44)], (236, 240, 240, 200), w=0.01)
    p.poly([(0.44, 0.42), (0.86, 0.12), (0.92, 0.2), (0.52, 0.46)], (236, 240, 240, 200), w=0.01)
    for (a, b) in (((0.36, 0.5), (0.2, 0.86)), ((0.42, 0.52), (0.4, 0.96)), ((0.5, 0.52), (0.62, 0.94)), ((0.56, 0.5), (0.8, 0.84)),
                   ((0.32, 0.5), (0.08, 0.7)), ((0.6, 0.48), (0.96, 0.62))):
        p.line([a, ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2 - 0.08), b], 0.012)
    p.poly([(0.42, 0.42), (0.7, 0.48), (0.98, 0.6), (0.96, 0.66), (0.66, 0.6), (0.42, 0.54)], "brown", sm=1)
    for x in (0.6, 0.72, 0.84):
        p.line([(x, 0.5 + (x - 0.6) * 0.4), (x - 0.02, 0.6 + (x - 0.6) * 0.4)], 0.015, "white")
    p.ell(0.36, 0.46, 0.08, 0.07, "brown")
    p.ell(0.25, 0.44, 0.05, 0.05, "black")
    p.line([(0.22, 0.46), (0.0, 0.6)], 0.02)
    p.line([(0.24, 0.4), (0.12, 0.3)], 0.01)
    p.line([(0.26, 0.4), (0.18, 0.28)], 0.01)


def maya_frame(d, W, H, K, col=(160, 40, 30)):
    ink = (28, 20, 18, 255)
    d.rectangle((0, 0, W * K, 22 * K), fill=col + (255,))
    d.rectangle((0, (H - 22) * K, W * K, H * K), fill=col + (255,))
    d.rectangle((0, 0, 16 * K, H * K), fill=col + (255,))
    d.rectangle(((W - 16) * K, 0, W * K, H * K), fill=col + (255,))
    d.rectangle((16 * K, 22 * K, (W - 16) * K, (H - 22) * K), outline=ink, width=3 * K)


def maya_caption(img, R, x, y, w, rows=2, cols=1, pal=None):
    """Une légende de glyphes peints (blocs de glyphes en rouge-brun sur crème)."""
    p0 = dict(PAL_MAYA)
    if pal:
        p0.update(pal)
    for r in range(rows):
        for c in range(cols):
            maya_block(Pen((x + c * w, y + r * w, w * 0.94, w * 0.94), img, None, None, p0, lw=0.05), R)


def fresque_jumeaux():
    """Les Jumeaux divins : Hunahpu (taches noires) et Xbalanque (taches de jaguar) visent de leurs
    sarbacanes l'oiseau Vucub-Caquix perché sur son arbre ; la balle de caoutchouc est à leurs
    pieds ; le moustique vole au-dessus d'eux."""
    W, H, K = 1024, 512, 2
    R = rng(6976)
    img, d = canvas(W, H, K)
    d.rectangle((0, 0, W * K, H * K), fill=(96, 166, 168, 255))
    d.rectangle((0, 420 * K, W * K, H * K), fill=(176, 120, 70, 255))
    d.line([(0, 420 * K), (W * K, 420 * K)], fill=(28, 20, 18, 255), width=3 * K)
    pal = PAL_MAYA
    # l'arbre et l'oiseau
    pt = pen(img, (430 * K, 120 * K, 160 * K, 300 * K), pal, lw=0.012)
    pt.poly([(0.42, 1.0), (0.44, 0.3), (0.3, 0.12), (0.36, 0.1), (0.48, 0.24), (0.5, 0.0), (0.56, 0.0), (0.56, 0.26), (0.7, 0.1),
             (0.76, 0.14), (0.58, 0.32), (0.58, 1.0)], "brown", sm=1)
    for (x, y, r) in ((0.25, 0.08, 0.2), (0.75, 0.1, 0.2), (0.5, -0.05, 0.24), (0.1, 0.2, 0.14), (0.9, 0.22, 0.14)):
        pt.ell(x, y, r, r * 0.55, "green")
        pt.dot(x + 0.05, y + 0.02, 0.02, "orange")
    pb = pen(img, (470 * K, 52 * K, 110 * K, 90 * K), pal, lw=0.02)
    pb.poly([(0.3, 0.5), (0.5, 0.2), (0.8, 0.3), (0.9, 0.6), (0.7, 0.75), (0.4, 0.72)], "red", sm=1)
    pb.poly([(0.6, 0.62), (1.0, 1.0), (0.9, 1.0), (0.55, 0.72)], "blue", sm=1)
    pb.poly([(0.5, 0.4), (0.8, 0.45), (0.7, 0.62), (0.5, 0.6)], "yellow", sm=1)
    pb.ell(0.28, 0.32, 0.13, 0.13, "red")
    pb.poly([(0.17, 0.3), (0.04, 0.38), (0.12, 0.46), (0.2, 0.4)], "white")
    pb.disc(0.27, 0.28, 0.04, "white")
    pb.dot(0.27, 0.28, 0.015)
    # Hunahpu (à gauche, tourné vers la droite) et Xbalanque (à droite, tourné vers la gauche)
    fh = 300 * K
    ph = pen(img, (240 * K - fh // 2, 420 * K - fh, fh, fh), pal, lw=0.006, flip=True)
    maya_fig(ph, marks="points", plume="green",
             arms=(((0.42, 0.26), (0.36, 0.13)), ((0.38, 0.24), (0.32, 0.1))))
    px = pen(img, (790 * K - fh // 2, 420 * K - fh, fh, fh), pal, lw=0.006)
    maya_fig(px, marks="jaguar", plume="blue",
             arms=(((0.42, 0.26), (0.36, 0.13)), ((0.38, 0.24), (0.32, 0.1))))
    for (x0, y0, x1, y1) in ((240 + 0.11 * 300, 420 - 0.9 * 300, 455, 78), (790 - 0.11 * 300, 420 - 0.9 * 300, 600, 80)):
        d.line([(x0 * K, y0 * K), (x1 * K, y1 * K)], fill=(28, 20, 18, 255), width=9 * K)
        d.line([(x0 * K, y0 * K), (x1 * K, y1 * K)], fill=(196, 160, 90, 255), width=5 * K)
    # la balle de caoutchouc
    bx, by, br = 606, 386, 34
    d.ellipse(((bx - br) * K, (by - br) * K, (bx + br) * K, (by + br) * K), fill=(28, 24, 22, 255), outline=(10, 8, 8, 255), width=3 * K)
    d.ellipse(((bx - br * 0.55) * K, (by - br * 0.7) * K, (bx - br * 0.1) * K, (by - br * 0.35) * K), fill=(110, 104, 96, 255))
    # le moustique
    mosquito(pen(img, (318 * K, 196 * K, 104 * K, 76 * K), pal, lw=0.02, flip=True))
    maya_caption(img, R, 40 * K, 50 * K, 52 * K, 2, 1, {"f": (230, 214, 176, 255), "ink": (130, 40, 30, 255)})
    maya_caption(img, R, 930 * K, 50 * K, 52 * K, 2, 1, {"f": (230, 214, 176, 255), "ink": (130, 40, 30, 255)})
    maya_frame(d, W, H, K)
    paint = finish(img, K)
    base = plaster_bg(R, W, H, (0.86, 0.8, 0.68))
    prot = np.zeros((H, W), np.float32)
    prot[180:290, 300:440] = 1.0
    prot[330:440, 560:660] = 1.0
    save_rgb(age_panel(paint, R, base, loss=0.08, fade=0.15, protect=prot), "fresque_jumeaux.png")


def maya_seated(p, kind="lord", cloth="red", hat="black", R=None):
    """Un seigneur assis sur son siège, de face (v = 0 en haut de la coiffe, 1 sous les pieds).
    kind : « lord » (visage de mort, os, plumes de hibou) ou « wood » (mannequin de bois raide,
    visage lisse, sans traits)."""
    if kind == "wood":
        wood = "wood"
        p.poly([(0.34, 0.12), (0.66, 0.12), (0.68, 0.3), (0.32, 0.3)], wood, sm=1)
        p.poly([(0.32, 0.3), (0.68, 0.3), (0.66, 0.66), (0.34, 0.66)], wood)
        for x in (0.18, 0.74):
            p.poly([(x, 0.32), (x + 0.08, 0.32), (x + 0.08, 0.66), (x, 0.66)], wood)
            p.ring(x + 0.04, 0.34, 0.03, 0.006)
            p.ring(x + 0.04, 0.5, 0.03, 0.006)
        p.poly([(0.34, 0.66), (0.48, 0.66), (0.48, 0.98), (0.34, 0.98)], wood)
        p.poly([(0.52, 0.66), (0.66, 0.66), (0.66, 0.98), (0.52, 0.98)], wood)
        for (x, y) in ((0.41, 0.8), (0.59, 0.8)):
            p.ring(x, y, 0.03, 0.006)
        p.ell(0.5, 0.2, 0.15, 0.14, wood)
        for k in range(7):
            y = 0.36 + k * 0.045
            p.line([(0.34, y), (0.42, y + 0.01), (0.5, y - 0.005), (0.58, y + 0.01), (0.66, y)], 0.004, "brown")
        for k in range(3):
            p.line(ellp(0.5, 0.2, 0.06 + k * 0.035, 0.05 + k * 0.03, 200, 340, 10), 0.004, "brown")
        p.line([(0.2, 0.36), (0.2, 0.62)], 0.004, "brown")
        p.line([(0.8, 0.36), (0.8, 0.62)], 0.004, "brown")
        p.line([(0.4, 0.7), (0.41, 0.95)], 0.004, "brown")
        p.line([(0.6, 0.7), (0.59, 0.95)], 0.004, "brown")
        return
    big = kind == "great"
    tall = 0.0 if not big else 0.1
    for k in range(5):
        a = -150 + k * 30
        p.poly([(0.5, 0.14), (0.5 + math.cos(math.radians(a - 9)) * (0.22 + tall), 0.14 + math.sin(math.radians(a - 9)) * (0.22 + tall)),
                (0.5 + math.cos(math.radians(a)) * (0.27 + tall), 0.14 + math.sin(math.radians(a)) * (0.27 + tall)),
                (0.5 + math.cos(math.radians(a + 9)) * (0.22 + tall), 0.14 + math.sin(math.radians(a + 9)) * (0.22 + tall))],
               "white" if k % 2 else hat, w=0.004)
    p.poly([(0.3, 0.32), (0.7, 0.32), (0.74, 0.62), (0.26, 0.62)], "grey", sm=1)
    for k in range(4):
        y = 0.38 + k * 0.05
        p.line([(0.36, y), (0.64, y)], 0.008, "bone")
    p.line([(0.5, 0.34), (0.5, 0.58)], 0.008, "bone")
    for x in (0.12, 0.76):
        p.poly([(x, 0.34), (x + 0.12, 0.34), (x + 0.12, 0.56), (x, 0.56)], "grey", sm=1)
    p.poly([(0.26, 0.58), (0.74, 0.58), (0.78, 0.74), (0.22, 0.74)], cloth, w=0.005)
    p.poly([(0.3, 0.74), (0.46, 0.74), (0.46, 0.98), (0.3, 0.98)], "grey")
    p.poly([(0.54, 0.74), (0.7, 0.74), (0.7, 0.98), (0.54, 0.98)], "grey")
    p.ell(0.5, 0.21, 0.15, 0.13, "bone")
    p.ell(0.44, 0.19, 0.04, 0.045, "black")
    p.ell(0.56, 0.19, 0.04, 0.045, "black")
    p.poly([(0.48, 0.25), (0.52, 0.25), (0.5, 0.28)], "black", ol=False)
    p.poly([(0.4, 0.29), (0.6, 0.29), (0.58, 0.34), (0.42, 0.34)], "bone", w=0.004)
    for x in np.linspace(0.43, 0.57, 6):
        p.line([(x, 0.29), (x, 0.34)], 0.004)
    p.dot(0.36, 0.42, 0.012, "black")
    p.dot(0.66, 0.48, 0.012, "black")


def fresque_xibalba():
    """La cour de Xibalba : douze sièges sur un banc de pierre ; les Seigneurs de la Mort (visages
    de crâne, os, plumes de hibou) y sont assis, Hun-Camé et Vucub-Camé au milieu, plus grands ;
    deux des « seigneurs » sont des mannequins de bois, raides, au visage lisse, sans traits."""
    W, H, K = 1024, 512, 2
    R = rng(6977)
    img, d = canvas(W, H, K)
    d.rectangle((0, 0, W * K, H * K), fill=(66, 30, 24, 255))
    for k in range(9):
        d.rectangle((0, (30 + k * 8) * K, W * K, (34 + k * 8) * K), fill=(80 + k * 4, 34, 26, 255))
    d.rectangle((0, 420 * K, W * K, H * K), fill=(48, 40, 36, 255))
    pal = PAL_MAYA
    ink = (20, 14, 12, 255)
    # le banc et les sièges
    d.rectangle((30 * K, 360 * K, (W - 30) * K, 430 * K), fill=(110, 104, 96, 255), outline=ink, width=3 * K)
    for k in range(14):
        d.line([((40 + k * 70) * K, 365 * K), ((40 + k * 70) * K, 425 * K)], fill=(70, 66, 60, 255), width=2 * K)
    n = 12
    sw = (W - 80) / n
    cloths = ["red", "black", "yellow", "blue", "green", "orange"]
    for i in range(n):
        x0 = 40 + i * sw
        d.rectangle(((x0 + 6) * K, 210 * K, (x0 + sw - 6) * K, 362 * K), fill=(150, 120, 70, 255), outline=ink, width=2 * K)
        d.rectangle(((x0 + 12) * K, 216 * K, (x0 + sw - 12) * K, 356 * K), fill=(200, 160, 80, 255))
        for k in range(4):
            cx = x0 + 20 + k * (sw - 40) / 3
            d.ellipse(((cx - 5) * K, (240 + k * 30) * K, (cx + 5) * K, (250 + k * 30) * K), fill=(60, 40, 20, 255))
        if i in (3, 8):
            kind = "wood"
        elif i in (5, 6):
            kind = "great"
        else:
            kind = "lord"
        fh = 190 if kind != "great" else 210
        top = 400 - fh
        maya_seated(pen(img, (x0 * K, top * K, sw * K, fh * K), pal, lw=0.012), kind, cloths[i % len(cloths)],
                    "black" if i % 2 else "white", R)
    # torches
    for x in (24, W - 24):
        d.rectangle(((x - 4) * K, 130 * K, (x + 4) * K, 200 * K), fill=(90, 60, 30, 255), outline=ink, width=K)
        d.polygon([((x - 12) * K, 132 * K), (x * K, 90 * K), ((x + 12) * K, 132 * K)], fill=(240, 150, 40, 255), outline=ink)
    maya_caption(img, R, 380 * K, 40 * K, 60 * K, 1, 4, {"f": (200, 150, 90, 255), "ink": (30, 20, 16, 255)})
    maya_frame(d, W, H, K, (120, 30, 24))
    paint = finish(img, K)
    base = plaster_bg(R, W, H, (0.7, 0.6, 0.5))
    prot = np.zeros((H, W), np.float32)
    prot[180:430, 30:1000] = 0.85
    save_rgb(age_panel(paint, R, base, loss=0.07, fade=0.1, protect=prot), "fresque_xibalba.png")


def relief_render(sh, ln, R, stone, back_dark=0.55, red=0.3, groove=0.55):
    """Rend un bas-relief (silhouette sh en saillie, traits ln gravés) dans la pierre."""
    H, W = sh.shape
    big = max(W, H)
    mot = tn(R, big, (4, 8, 16, 32, 64), 0.6)[:H, :W]
    fine = tn(R, big, (128, 256, 512, 1024), 0.75)[:H, :W]
    ero = tn(R, big, (16, 32, 64, 128), 0.65)[:H, :W]
    relief = gblur(sh, 1.6) * (1 - 0.25 * smooth(0.62, 0.82, ero))
    ln = ln * smooth(0.5, 0.9, gblur(sh, 2.0))
    h = 0.25 + relief * 0.6 - gblur(ln, 0.7) * 0.3 + mot * 0.06 + fine * 0.05
    col = np.array(stone, np.float32)[None, None, :] * (0.84 + 0.24 * mot[..., None]) * (0.9 + 0.16 * fine[..., None])
    back = 1 - smooth(0.2, 0.6, relief)
    col = mix(col, col * back_dark, back * 0.8)
    col = col * (1 - groove * ln[..., None])
    rp = smooth(0.4, 0.62, tn(R, big, (8, 16, 32, 64), 0.6)[:H, :W]) * smooth(0.3, 0.6, fine)
    col = mix(col, C(0.52, 0.18, 0.13), rp[..., None][..., 0] * red * (0.5 + 0.5 * back))
    li = smooth(0.66, 0.74, tn(R, big, (16, 32, 64), 0.6)[:H, :W]) * smooth(0.45, 0.6, fine)
    col = mix(col, C(0.18, 0.18, 0.16), li * 0.45)
    lg = smooth(0.7, 0.74, tn(R, big, (16, 32, 64, 128), 0.6)[:H, :W]) * (1 - back)
    col = mix(col, C(0.66, 0.68, 0.58), lg * 0.3)
    return bake(col, h, 4.0, k=0.5, ao=0.35, ao_r=4)


def stele_4ahau():
    """La stèle de la place de Yaxché (calcaire, 512 x 1024) : en haut le souverain debout, la
    grande coiffe de plumes, la barre-serpent dans les bras ; en bas, seule dans son cadre, la date
    de la création : 4 Ahau — quatre gros points en colonne, à côté du visage d'Ahau dans son
    cartouche."""
    W, H, K = 512, 1024, 2
    R = rng(6978)
    shp = Image.new("L", (W * K, H * K), 0)
    lin = Image.new("L", (W * K, H * K), 0)
    ds = ImageDraw.Draw(shp)
    # cadre
    ds.rectangle((0, 0, W * K, H * K), fill=255)
    ds.rectangle((26 * K, 26 * K, (W - 26) * K, 600 * K), fill=0)
    ds.rectangle((26 * K, 630 * K, (W - 26) * K, (H - 26) * K), fill=0)
    # le souverain
    fh = 430 * K
    p = Pen((W * K / 2 - fh / 2 + 10 * K, 590 * K - fh, fh, fh), None, shp, lin, lw=0.007)
    maya_fig(p, marks=None, plume="green", legs="stand", arms=(((0.6, 0.3), (0.62, 0.36)), ((0.4, 0.3), (0.38, 0.36))))
    p.poly([(0.22, 0.33), (0.78, 0.33), (0.78, 0.38), (0.22, 0.38)], "f")
    for x in (0.2, 0.8):
        p.ell(x, 0.355, 0.06, 0.045, "f")
        p.dot(x + (-0.02 if x < 0.5 else 0.02), 0.35, 0.012)
    for k in range(7):
        p.line([(0.27 + k * 0.075, 0.335), (0.27 + k * 0.075, 0.375)], 0.006)
    for k in range(7):
        a = -150 + k * 20
        p.poly([(0.52, -0.02), (0.52 + math.cos(math.radians(a - 6)) * 0.28, -0.02 + math.sin(math.radians(a - 6)) * 0.28),
                (0.52 + math.cos(math.radians(a)) * 0.34, -0.02 + math.sin(math.radians(a)) * 0.34),
                (0.52 + math.cos(math.radians(a + 6)) * 0.28, -0.02 + math.sin(math.radians(a + 6)) * 0.28)], "f")
        p.line([(0.52, -0.02), (0.52 + math.cos(math.radians(a)) * 0.3, -0.02 + math.sin(math.radians(a)) * 0.3)], 0.005)
    p.poly([(0.3, 0.98), (0.72, 0.98), (0.74, 1.04), (0.28, 1.04)], "f")
    # la date : 4 Ahau
    q = Pen((50 * K, 660 * K, 412 * K, 330 * K), None, shp, lin, lw=0.02)
    for k in range(4):
        q.disc(0.15, 0.13 + k * 0.245, 0.11, "f")
        q.dot(0.15, 0.13 + k * 0.245, 0.03)
    maya_day(q.sub(0.3, 0.0, 0.7, 1.0), "ahau")
    sh = down(_arr(shp), K)
    ln = down(_arr(lin), K)
    col = relief_render(sh, ln, R, (0.78, 0.75, 0.68), back_dark=0.5, red=0.45)
    save_rgb(col, "stele_4ahau.png")


def fresque_kukulkan():
    """Kukulkan, le serpent à plumes, descend le grand escalier de la pyramide à neuf degrés :
    la queue à crotales en haut près du temple, le corps ondulant le long de la rampe, la tête
    aux mâchoires ouvertes au pied ; le soleil brille au-dessus."""
    W, H, K = 1024, 512, 2
    R = rng(6979)
    img, d = canvas(W, H, K)
    ink = (28, 20, 18, 255)
    d.rectangle((0, 0, W * K, H * K), fill=(104, 176, 176, 255))
    d.rectangle((0, 440 * K, W * K, H * K), fill=(170, 130, 80, 255))
    # le soleil
    sx, sy = 880, 100
    for k in range(16):
        a = k / 16 * TAU
        d.polygon([((sx + math.cos(a - 0.12) * 46) * K, (sy + math.sin(a - 0.12) * 46) * K), ((sx + math.cos(a) * 74) * K, (sy + math.sin(a) * 74) * K),
                   ((sx + math.cos(a + 0.12) * 46) * K, (sy + math.sin(a + 0.12) * 46) * K)], fill=(240, 190, 60, 255), outline=ink)
    d.ellipse(((sx - 46) * K, (sy - 46) * K, (sx + 46) * K, (sy + 46) * K), fill=(236, 120, 40, 255), outline=ink, width=3 * K)
    pf = pen(img, ((sx - 36) * K, (sy - 36) * K, 72 * K, 72 * K), PAL_MAYA, lw=0.04)
    _mj_ahau(pf.sub(0.15, 0.1, 0.7, 0.8))
    # la pyramide
    cx = 470
    base_y, top_y = 440, 150
    nlev = 9
    for k in range(nlev):
        y1 = base_y - k * (base_y - top_y) / nlev
        y0 = y1 - (base_y - top_y) / nlev
        hw = 380 - k * 30
        d.rectangle(((cx - hw) * K, y0 * K, (cx + hw) * K, y1 * K), fill=(214, 200, 170, 255), outline=ink, width=2 * K)
        d.rectangle(((cx - hw) * K, (y1 - 8) * K, (cx + hw) * K, y1 * K), fill=(180, 160, 128, 255), outline=ink, width=K)
        for x in range(int(cx - hw + 20), int(cx + hw - 10), 40):
            d.rectangle((x * K, (y0 + 6) * K, (x + 18) * K, (y1 - 12) * K), outline=(150, 130, 100, 255), width=K)
    # l'escalier
    sw = 60
    d.rectangle(((cx - sw) * K, top_y * K, (cx + sw) * K, base_y * K), fill=(226, 214, 186, 255), outline=ink, width=2 * K)
    for k in range(52):
        y = top_y + k * (base_y - top_y) / 52
        d.line([((cx - sw) * K, y * K), ((cx + sw) * K, y * K)], fill=(150, 130, 100, 255), width=K)
    for x in (cx - sw - 12, cx + sw):
        d.rectangle((x * K, top_y * K, (x + 12) * K, base_y * K), fill=(196, 180, 150, 255), outline=ink, width=K)
    # le temple
    d.rectangle(((cx - 90) * K, (top_y - 80) * K, (cx + 90) * K, top_y * K), fill=(206, 190, 160, 255), outline=ink, width=2 * K)
    d.rectangle(((cx - 100) * K, (top_y - 96) * K, (cx + 100) * K, (top_y - 80) * K), fill=(176, 50, 36, 255), outline=ink, width=2 * K)
    for x in (cx - 50, cx, cx + 50):
        d.rectangle(((x - 14) * K, (top_y - 60) * K, (x + 14) * K, top_y * K), fill=(40, 30, 26, 255))
    # Kukulkan : le corps ondule le long de la rampe droite
    pts = []
    for k in range(60):
        t = k / 59
        y = top_y + 10 + t * (base_y - top_y - 50)
        x = cx + sw + 6 + 26 * math.sin(t * TAU * 2.5)
        pts.append((x, y))
    body = [(x * K, y * K) for x, y in pts]
    pk = Pen((0, 0, W * K, H * K), img, None, None, PAL_MAYA, lw=0.0025)
    rel = [(x / W, y / H) for x, y in pts]
    for k in range(2, 58, 3):
        x, y = rel[k]
        side = 1 if (k // 3) % 2 else -1
        pk.poly([(x, y), (x + 0.05, y - 0.03 + side * 0.01), (x + 0.07, y + 0.0), (x + 0.04, y + 0.02)], "green", sm=1)
        pk.poly([(x, y), (x - 0.035, y - 0.02), (x - 0.045, y + 0.01), (x - 0.02, y + 0.02)], "jade", sm=1)
    pk.poly(tube(rel, 0.022, 0.034), "blue")
    for k in range(1, 59, 2):
        x, y = rel[k]
        pk.line([(x - 0.012, y), (x + 0.012, y)], 0.002, "yellow")
    x, y = rel[0]
    for j in range(4):
        pk.ell(x, y - 0.015 - j * 0.022, 0.012, 0.011, "yellow")
    hx, hy = pts[-1]
    ph = pen(img, ((hx - 60) * K, (hy - 10) * K, 150 * K, 80 * K), PAL_MAYA, lw=0.02)
    ph.poly([(0.3, 0.0), (0.7, 0.05), (0.95, 0.3), (1.0, 0.55), (0.8, 0.6), (0.6, 0.5), (0.75, 0.75), (0.95, 0.85), (0.6, 1.0),
             (0.3, 0.9), (0.15, 0.5)], "blue", sm=1)
    ph.poly([(0.6, 0.5), (0.8, 0.6), (0.75, 0.75)], "red")
    ph.line([(0.85, 0.68), (1.05, 0.62), (1.1, 0.56)], 0.02, "red")
    ph.line([(1.05, 0.62), (1.1, 0.7)], 0.02, "red")
    for x in (0.7, 0.8, 0.88):
        ph.poly([(x, 0.52), (x + 0.03, 0.52), (x + 0.015, 0.62)], "white", w=0.008)
    ph.disc(0.55, 0.28, 0.1, "white")
    ph.dot(0.57, 0.28, 0.04)
    for k in range(6):
        a = -160 + k * 22
        ph.poly([(0.35, 0.2), (0.35 + math.cos(math.radians(a - 8)) * 0.35, 0.2 + math.sin(math.radians(a - 8)) * 0.5),
                 (0.35 + math.cos(math.radians(a)) * 0.45, 0.2 + math.sin(math.radians(a)) * 0.65),
                 (0.35 + math.cos(math.radians(a + 8)) * 0.35, 0.2 + math.sin(math.radians(a + 8)) * 0.5)], "green" if k % 2 else "jade")
    del body
    maya_caption(img, R, 40 * K, 40 * K, 56 * K, 3, 1, {"f": (236, 220, 180, 255), "ink": (130, 40, 30, 255)})
    maya_frame(d, W, H, K)
    paint = finish(img, K)
    base = plaster_bg(R, W, H, (0.86, 0.8, 0.68))
    prot = np.zeros((H, W), np.float32)
    prot[120:470, 480:720] = 0.9
    save_rgb(age_panel(paint, R, base, loss=0.08, fade=0.14, protect=prot), "fresque_kukulkan.png")


# ------------------------------------------------------------------- personnages aztèques (style des codex)

PAL_CODEX = dict(PAL_AZ)
PAL_CODEX.update({"f": (240, 234, 216, 255), "gold": (236, 190, 60, 255), "jade": (60, 160, 120, 255), "heron": (246, 244, 236, 255),
                  "flesh": (214, 140, 96, 255), "grey": (150, 146, 140, 255), "wood": (160, 104, 56, 255)})


def az_figure(p, skin="flesh", head="human", loin="white", cape=None, hair="black", arms=None, legs="walk", sandals=True, pustules=False):
    """Personnage de codex aztèque, de profil, tourné vers la gauche : grosse tête, corps trapu,
    cerne noir épais (v = 0 sommet de la tête, 1 sous les pieds)."""
    if arms is None:
        arms = (((0.6, 0.44), (0.56, 0.54)), ((0.4, 0.44), (0.32, 0.5)))
    (be, bw), (fe, fw) = arms
    dark = tuple(int(c * 0.82) for c in p.c(skin)[:3]) + (255,)
    if cape:
        p.poly([(0.48, 0.3), (0.66, 0.31), (0.76, 0.66), (0.7, 0.74), (0.56, 0.7)], cape, sm=1)
        p.line([(0.66, 0.4), (0.72, 0.66)], 0.006)
    p.poly(tube([(0.56, 0.34), be, bw], 0.07, 0.055), dark)
    p.disc(bw[0], bw[1] + 0.02, 0.03, dark)
    if legs == "walk":
        bl = [(0.55, 0.62), (0.6, 0.8), (0.62, 0.95)]
        fl = [(0.45, 0.62), (0.4, 0.8), (0.38, 0.95)]
    else:
        bl = [(0.54, 0.62), (0.55, 0.8), (0.55, 0.95)]
        fl = [(0.46, 0.62), (0.45, 0.8), (0.45, 0.95)]
    for leg, c in ((bl, dark), (fl, skin)):
        p.poly(tube(leg, 0.1, 0.07), c)
        x = leg[-1][0]
        p.poly([(x + 0.04, 0.93), (x - 0.09, 0.97), (x - 0.09, 1.0), (x + 0.05, 1.0)], c)
        if sandals:
            p.poly([(x - 0.1, 0.985), (x + 0.06, 0.985), (x + 0.06, 1.01), (x - 0.1, 1.01)], "black", w=0.004)
            p.poly([(x + 0.02, 0.93), (x + 0.07, 0.93), (x + 0.07, 0.99), (x + 0.02, 0.99)], "white", w=0.004)
    p.poly([(0.4, 0.31), (0.6, 0.31), (0.62, 0.48), (0.6, 0.62), (0.42, 0.62), (0.38, 0.48)], skin, sm=1)
    p.poly([(0.39, 0.56), (0.61, 0.56), (0.61, 0.62), (0.39, 0.62)], loin, w=0.005)
    p.poly([(0.37, 0.6), (0.46, 0.6), (0.45, 0.76), (0.35, 0.76)], loin, w=0.005)
    p.poly([(0.35, 0.72), (0.45, 0.72), (0.45, 0.76), (0.35, 0.76)], "red", w=0.004)
    if pustules:
        for (x, y) in ((0.44, 0.38), (0.52, 0.42), (0.48, 0.5), (0.56, 0.36), (0.42, 0.68), (0.4, 0.86), (0.58, 0.72), (0.6, 0.86)):
            p.disc(x, y, 0.014, "yellow")
            p.dot(x, y, 0.006, "red")
    # tête
    face = [(0.62, 0.08), (0.5, 0.0), (0.39, 0.04), (0.365, 0.1), (0.31, 0.15), (0.345, 0.165), (0.335, 0.19), (0.37, 0.23),
            (0.45, 0.27), (0.6, 0.25)]
    p.poly([(0.44, 0.24), (0.56, 0.24), (0.56, 0.33), (0.44, 0.33)], skin, w=0.006)
    p.poly(face, skin, sm=1)
    if pustules:
        for (x, y) in ((0.42, 0.18), (0.47, 0.22), (0.5, 0.12)):
            p.disc(x, y, 0.012, "yellow")
    if head == "human":
        p.poly([(0.42, 0.0), (0.52, -0.02), (0.64, 0.04), (0.66, 0.2), (0.6, 0.24), (0.56, 0.12), (0.44, 0.06)], hair, sm=1)
    p.poly(ellp(0.41, 0.12, 0.035, 0.022, 180, 360, 8), "white", w=0.005)
    p.dot(0.39, 0.115, 0.01)
    p.disc(0.55, 0.16, 0.035, "jade")
    p.dot(0.55, 0.16, 0.012)
    # bras avant
    p.poly(tube([(0.44, 0.34), fe, fw], 0.07, 0.055), skin)
    p.disc(fw[0], fw[1] + 0.02, 0.03, skin)


def codex_frame(d, W, H, K, m=14):
    red = (176, 40, 30, 255)
    d.rectangle((0, 0, W * K, H * K), outline=red, width=m * K)
    d.rectangle((m * K + 6 * K, m * K + 6 * K, (W - m) * K - 6 * K, (H - m) * K - 6 * K), outline=red, width=3 * K)


def flames(p, n=5):
    """Le grand feu (style codex) : langues de flammes rouges, orange et jaunes en volutes."""
    for k in range(n):
        x = 0.1 + 0.8 * k / max(1, n - 1)
        h = 0.55 + 0.4 * math.sin(k * 1.7 + 0.5) ** 2
        pts = [(x - 0.12, 1.0), (x - 0.14, 1 - h * 0.5), (x - 0.04, 1 - h * 0.75), (x - 0.06, 1 - h), (x + 0.06, 1 - h * 0.8),
               (x + 0.1, 1 - h * 0.95), (x + 0.14, 1 - h * 0.5), (x + 0.12, 1.0)]
        p.poly(pts, "red", sm=1, w=0.006)
        p.poly([(x - 0.07, 1.0), (x - 0.08, 1 - h * 0.45), (x, 1 - h * 0.65), (x + 0.08, 1 - h * 0.45), (x + 0.07, 1.0)], "orange", sm=1, w=0.004)
        p.poly([(x - 0.035, 1.0), (x - 0.04, 1 - h * 0.25), (x, 1 - h * 0.4), (x + 0.04, 1 - h * 0.25), (x + 0.035, 1.0)], "yellow", sm=1, w=0.003)


def rain(d, W, K, y0, y1, x0, x1, R, col=(60, 120, 200)):
    for _ in range(int((x1 - x0) * (y1 - y0) / 900)):
        x, y = R.uniform(x0, x1), R.uniform(y0, y1)
        d.line([(x * K, y * K), ((x - 4) * K, (y + 18) * K)], fill=col + (255,), width=2 * K)
        d.ellipse(((x - 6) * K, (y + 16) * K, (x + 2) * K, (y + 26) * K), fill=col + (255,), outline=(24, 20, 18, 255), width=K)


def maize(p):
    """Un pied de maïs : tige, longues feuilles, deux épis jaunes et la panicule."""
    p.stroke([(0.5, 1.0), (0.5, 0.06)], 0.06, "green")
    for k, y in enumerate((0.8, 0.6, 0.42, 0.26)):
        sg = 1 if k % 2 else -1
        p.poly([(0.5, y), (0.5 + sg * 0.3, y - 0.12), (0.5 + sg * 0.48, y - 0.06), (0.5 + sg * 0.28, y - 0.06)], "green", sm=1, w=0.01)
    for (x, y) in ((0.6, 0.5), (0.4, 0.66)):
        p.ell(x, y, 0.07, 0.12, "yellow")
        for j in range(3):
            p.line([(x - 0.04, y - 0.06 + j * 0.06), (x + 0.04, y - 0.06 + j * 0.06)], 0.01)
    for a in (-30, 0, 30):
        p.line([(0.5, 0.06), (0.5 + math.sin(math.radians(a)) * 0.15, 0.0)], 0.015, "yellow")


def fresque_tlaloc():
    """Tlaloc, le dieu de la pluie (style codex) : visage bleu-noir, yeux cerclés « à lunettes »,
    moustache en volute, crocs ; coiffe de plumes de héron et de quetzal ; il tient l'éclair-serpent
    et un pied de maïs ; la pluie tombe des nuages sur le maïs."""
    W, H, K = 1024, 512, 2
    R = rng(6980)
    img, d = canvas(W, H, K)
    pal = PAL_CODEX
    # nuages
    pc = pen(img, (30 * K, 34 * K, 964 * K, 70 * K), pal, lw=0.01)
    pts = []
    for k in range(13):
        pts += ellp(0.04 + k * 0.077, 0.62, 0.05, 0.5, 180, 360, 8)
    pc.poly([(0.0, 0.8)] + pts + [(1.0, 0.8), (1.0, 1.0), (0.0, 1.0)], "dblue", sm=1)
    for k in range(12):
        pc.ring(0.08 + k * 0.077, 0.8, 0.12, 0.08, "white")
    rain(d, W, K, 110, 330, 40, 360, R)
    rain(d, W, K, 110, 330, 660, 990, R)
    # le maïs
    for x in (60, 140, 220, 780, 860, 940):
        maize(pen(img, ((x - 40) * K, 300 * K, 80 * K, 170 * K), pal, lw=0.02))
    d.rectangle((24 * K, 466 * K, (W - 24) * K, 490 * K), fill=(40, 150, 170, 255), outline=(24, 20, 18, 255), width=2 * K)
    for x in range(40, W - 30, 40):
        d.ellipse(((x - 7) * K, 471 * K, (x + 7) * K, 485 * K), fill=(240, 234, 216, 255), outline=(24, 20, 18, 255), width=K)
    # Tlaloc
    fh = 360 * K
    pt = pen(img, (520 * K - fh // 2, 470 * K - fh, fh, fh), pal, lw=0.007, flip=True)
    az_figure(pt, skin="dblue", head="tlaloc", loin="white", cape="blue",
              arms=(((0.66, 0.42), (0.7, 0.32)), ((0.36, 0.42), (0.26, 0.36))))
    pt.poly([(0.36, 0.0), (0.46, -0.04), (0.6, -0.02), (0.68, 0.06), (0.68, 0.22), (0.6, 0.26), (0.56, 0.12), (0.4, 0.06)], "black", sm=1)
    pt.disc(0.42, 0.11, 0.05, "white")
    pt.ring(0.42, 0.11, 0.05, 0.012, "blue")
    pt.dot(0.41, 0.11, 0.015)
    pt.stroke(chaikin([(0.44, 0.19), (0.38, 0.17), (0.32, 0.19), (0.31, 0.22), (0.34, 0.22)], 2, False), 0.025, "blue")
    for x in (0.34, 0.38, 0.42):
        pt.poly([(x - 0.012, 0.21), (x + 0.012, 0.21), (x, 0.26)], "white", w=0.004)
    for k in range(6):
        a = -150 + k * 18
        pt.poly([(0.56, 0.0), (0.56 + math.cos(math.radians(a - 6)) * 0.2, math.sin(math.radians(a - 6)) * 0.2),
                 (0.56 + math.cos(math.radians(a)) * 0.26, math.sin(math.radians(a)) * 0.26),
                 (0.56 + math.cos(math.radians(a + 6)) * 0.2, math.sin(math.radians(a + 6)) * 0.2)], "heron" if k % 2 else "green", w=0.004)
    # l'éclair-serpent et le maïs dans ses mains
    zig = [(0.26, 0.36), (0.22, 0.28), (0.28, 0.2), (0.2, 0.12), (0.26, 0.04), (0.2, -0.04)]
    pt.stroke(zig, 0.03, "yellow")
    pt.poly([(0.17, -0.06), (0.24, -0.1), (0.25, -0.03)], "red")
    maize(pt.sub(0.62, 0.02, 0.2, 0.42))
    codex_frame(d, W, H, K)
    paint = finish(img, K)
    base = plaster_bg(R, W, H, (0.93, 0.9, 0.82), var=0.06)
    prot = np.zeros((H, W), np.float32)
    prot[20:480, 330:720] = 0.9
    save_rgb(age_panel(paint, R, base, loss=0.05, fade=0.1, cracks=0.6, damp=0.15, protect=prot), "fresque_tlaloc.png")


def shield(p):
    """Le bouclier rond (chimalli) aux cinq boules de duvet, frangé de plumes."""
    p.disc(0.5, 0.45, 0.42, "blue")
    p.disc(0.5, 0.45, 0.34, "dblue")
    for (x, y) in ((0.5, 0.45), (0.34, 0.3), (0.66, 0.3), (0.34, 0.6), (0.66, 0.6)):
        p.disc(x, y, 0.07, "heron")
    for k in range(7):
        x = 0.24 + k * 0.087
        p.poly([(x - 0.03, 0.82), (x + 0.03, 0.82), (x + 0.02, 1.0), (x - 0.02, 1.0)], "green" if k % 2 else "yellow", w=0.006)


def xiuhcoatl(p):
    """Le serpent de feu (xiuhcoatl) : corps turquoise à segments, museau retroussé, queue en
    rayons de feu."""
    pts = [(0.04 + t * 0.82, 0.55 + 0.18 * math.sin(t * TAU * 1.5)) for t in np.linspace(0, 1, 40)]
    p.poly(tube(pts, 0.16, 0.1), "blue")
    for k in range(3, 40, 4):
        x, y = pts[k]
        p.line([(x, y - 0.07), (x, y + 0.07)], 0.012)
        p.poly([(x - 0.02, y - 0.07), (x + 0.02, y - 0.07), (x, y - 0.16)], "red", w=0.004)
    x, y = pts[0]
    p.poly([(x + 0.06, y - 0.12), (x - 0.04, y - 0.1), (x - 0.06, y - 0.3), (x - 0.0, y - 0.32), (x + 0.02, y - 0.16), (x + 0.1, y - 0.06),
            (x + 0.08, y + 0.1), (x - 0.02, y + 0.06)], "blue", sm=1)
    p.disc(x + 0.02, y - 0.06, 0.035, "white")
    p.dot(x + 0.015, y - 0.06, 0.012)
    p.poly([(x - 0.02, y + 0.04), (x + 0.06, y + 0.06), (x + 0.0, y + 0.1)], "red")
    x, y = pts[-1]
    for k, a in enumerate((-50, -20, 10, 40)):
        p.poly([(x, y), (x + math.cos(math.radians(a)) * 0.14, y + math.sin(math.radians(a)) * 0.3 - 0.02),
                (x + math.cos(math.radians(a + 12)) * 0.14, y + math.sin(math.radians(a + 12)) * 0.3 + 0.02)], "orange" if k % 2 else "yellow", w=0.005)


def fresque_huitzilopochtli():
    """Huitzilopochtli, le guerrier colibri (style codex) : casque en tête de colibri, visage
    rayé de jaune et de bleu, corps rayé de bleu, bouclier aux cinq boules de duvet, et le serpent
    de feu à la main ; le soleil et les flammes de la guerre sacrée."""
    W, H, K = 1024, 512, 2
    R = rng(6981)
    img, d = canvas(W, H, K)
    pal = PAL_CODEX
    # le soleil derrière
    ps = pen(img, (70 * K, 60 * K, 220 * K, 220 * K), pal, lw=0.01)
    for k in range(12):
        a = k / 12 * 360
        ps.poly([(0.5 + math.cos(math.radians(a - 8)) * 0.3, 0.5 + math.sin(math.radians(a - 8)) * 0.3),
                 (0.5 + math.cos(math.radians(a)) * 0.48, 0.5 + math.sin(math.radians(a)) * 0.48),
                 (0.5 + math.cos(math.radians(a + 8)) * 0.3, 0.5 + math.sin(math.radians(a + 8)) * 0.3)], "yellow")
    ps.disc(0.5, 0.5, 0.31, "red")
    ps.disc(0.5, 0.5, 0.2, "yellow")
    for x in (760, 860, 950):
        flames(pen(img, ((x - 50) * K, 330 * K, 100 * K, 140 * K), pal, lw=0.01), 3)
    # le guerrier
    fh = 360 * K
    pt = pen(img, (520 * K - fh // 2, 470 * K - fh, fh, fh), pal, lw=0.007)
    az_figure(pt, skin="flesh", head="huitzi", loin="red", cape="red",
              arms=(((0.66, 0.44), (0.74, 0.4)), ((0.36, 0.42), (0.24, 0.42))))
    for y in (0.36, 0.42, 0.48, 0.54, 0.7, 0.8, 0.88):
        pt.line([(0.4, y), (0.62, y)], 0.016, "dblue")
    pt.poly([(0.4, 0.02), (0.52, -0.06), (0.66, -0.02), (0.7, 0.12), (0.66, 0.24), (0.58, 0.2), (0.56, 0.08), (0.44, 0.06)], "green", sm=1)
    pt.poly([(0.44, 0.0), (0.12, 0.04), (0.12, 0.06), (0.42, 0.06)], "black")
    pt.disc(0.5, 0.02, 0.025, "white")
    pt.dot(0.5, 0.02, 0.01)
    for k in range(6):
        a = -120 + k * 16
        pt.poly([(0.6, -0.04), (0.6 + math.cos(math.radians(a - 6)) * 0.22, -0.04 + math.sin(math.radians(a - 6)) * 0.22),
                 (0.6 + math.cos(math.radians(a)) * 0.28, -0.04 + math.sin(math.radians(a)) * 0.28),
                 (0.6 + math.cos(math.radians(a + 6)) * 0.22, -0.04 + math.sin(math.radians(a + 6)) * 0.22)], "green" if k % 2 else "jade", w=0.004)
    for k, y in enumerate((0.1, 0.14, 0.18, 0.22)):
        pt.line([(0.33 + 0.02 * k, y), (0.5, y)], 0.018, "yellow" if k % 2 else "dblue")
    pt.disc(0.41, 0.115, 0.018, "white")
    pt.dot(0.4, 0.115, 0.008)
    shield(pt.sub(0.68, 0.24, 0.3, 0.38))
    xiuhcoatl(pt.sub(-0.42, 0.24, 0.72, 0.34))
    codex_frame(d, W, H, K)
    paint = finish(img, K)
    base = plaster_bg(R, W, H, (0.93, 0.9, 0.82), var=0.06)
    prot = np.zeros((H, W), np.float32)
    prot[20:480, 200:720] = 0.85
    save_rgb(age_panel(paint, R, base, loss=0.05, fade=0.1, cracks=0.6, damp=0.15, protect=prot), "fresque_huitzilopochtli.png")


def az_seated(p, cape="red", hat="green", skin="flesh"):
    """Un dieu assis à la manière des codex : enveloppé dans sa cape, les genoux remontés."""
    p.poly([(0.3, 0.38), (0.7, 0.36), (0.8, 0.92), (0.72, 1.0), (0.24, 1.0), (0.2, 0.7)], cape, sm=1)
    p.line([(0.3, 0.6), (0.76, 0.62)], 0.012)
    p.poly(tube([(0.3, 0.6), (0.2, 0.62)], 0.08, 0.07), skin)
    p.poly([(0.36, 0.06), (0.5, 0.0), (0.66, 0.06), (0.68, 0.3), (0.56, 0.38), (0.42, 0.36), (0.34, 0.28), (0.28, 0.22), (0.34, 0.18)], skin, sm=1)
    p.poly(ellp(0.4, 0.16, 0.04, 0.025, 180, 360, 8), "white", w=0.008)
    p.dot(0.385, 0.155, 0.012)
    for k in range(4):
        a = -140 + k * 25
        p.poly([(0.52, 0.04), (0.52 + math.cos(math.radians(a - 8)) * 0.3, 0.04 + math.sin(math.radians(a - 8)) * 0.3),
                (0.52 + math.cos(math.radians(a)) * 0.38, 0.04 + math.sin(math.radians(a)) * 0.38),
                (0.52 + math.cos(math.radians(a + 8)) * 0.3, 0.04 + math.sin(math.radians(a + 8)) * 0.3)], hat, w=0.006)


def fresque_nanahuatzin():
    """Le grand feu de Teotihuacan : les dieux assis tout autour ; Nanahuatzin, le pauvre au corps
    couvert de pustules, en simple pagne, se jette dans le feu (à ses pieds ses humbles offrandes :
    roseaux verts et épines d'agave) ; Tecciztécatl, couvert d'or et de plumes de quetzal, recule et
    hésite (à ses pieds, ses offrandes riches : plumes et boules d'or)."""
    W, H, K = 1024, 512, 2
    R = rng(6982)
    img, d = canvas(W, H, K)
    pal = PAL_CODEX
    ink = (24, 20, 18, 255)
    # les dieux assis, de part et d'autre
    for k, (x, cape, hat) in enumerate(((70, "dblue", "green"), (150, "yellow", "red"), (870, "green", "yellow"), (950, "red", "heron"))):
        az_seated(pen(img, ((x - 50) * K, 300 * K, 100 * K, 150 * K), pal, lw=0.012, flip=(x > 512)), cape, hat)
    # le foyer et le grand feu
    d.polygon([(360 * K, 470 * K), (660 * K, 470 * K), (630 * K, 430 * K), (390 * K, 430 * K)], fill=(150, 146, 140, 255), outline=ink, width=3 * K)
    for x in range(400, 630, 34):
        d.rectangle((x * K, 420 * K, (x + 26) * K, 436 * K), fill=(130, 76, 40, 255), outline=ink, width=2 * K)
    flames(pen(img, (380 * K, 120 * K, 260 * K, 310 * K), pal, lw=0.008), 5)
    # Nanahuatzin plonge dans le feu (dessiné à part puis penché)
    lay, _ = canvas(400, 400, K)
    pn = pen(lay, (50 * K, 50 * K, 300 * K, 300 * K), pal, lw=0.008, flip=True)
    az_figure(pn, skin="flesh", head="human", loin="white", pustules=True, sandals=False,
              arms=(((0.46, 0.24), (0.42, 0.08)), ((0.4, 0.24), (0.34, 0.06))))
    lay = lay.rotate(-125, resample=Image.BICUBIC, center=(200 * K, 200 * K))
    img.alpha_composite(lay, (int(150 * K), int(0 * K)))
    # ses offrandes : roseaux et épines
    for k in range(5):
        x = 250 + k * 10
        d.line([(x * K, 470 * K), ((x + 8) * K, 400 * K)], fill=(60, 140, 70, 255), width=5 * K)
    d.line([(246 * K, 446 * K), (304 * K, 446 * K)], fill=(220, 190, 120, 255), width=6 * K)
    for k in range(4):
        x = 300 + k * 14
        d.polygon([(x * K, 470 * K), ((x + 4) * K, 470 * K), ((x + 2) * K, 430 * K)], fill=(120, 140, 80, 255), outline=ink)
        d.ellipse(((x - 1) * K, 428 * K, (x + 5) * K, 434 * K), fill=(190, 30, 30, 255))
    # Tecciztécatl recule
    lay, _ = canvas(400, 440, K)
    pt = pen(lay, (60 * K, 80 * K, 300 * K, 300 * K), pal, lw=0.008, flip=False)
    az_figure(pt, skin="flesh", head="human", loin="yellow", cape="blue",
              arms=(((0.6, 0.4), (0.5, 0.28)), ((0.4, 0.36), (0.3, 0.24))))
    for k in range(7):
        a = -150 + k * 15
        pt.poly([(0.56, 0.0), (0.56 + math.cos(math.radians(a - 5)) * 0.3, math.sin(math.radians(a - 5)) * 0.3),
                 (0.56 + math.cos(math.radians(a)) * 0.4, math.sin(math.radians(a)) * 0.4),
                 (0.56 + math.cos(math.radians(a + 5)) * 0.3, math.sin(math.radians(a + 5)) * 0.3)], "green" if k % 2 else "jade", w=0.004)
    for (x, y) in ((0.55, 0.16), (0.5, 0.33), (0.44, 0.36), (0.62, 0.42)):
        pt.disc(x, y, 0.03, "gold")
    pt.poly([(0.38, 0.31), (0.62, 0.31), (0.6, 0.36), (0.4, 0.36)], "gold")
    lay = lay.rotate(-12, resample=Image.BICUBIC, center=(200 * K, 380 * K))
    img.alpha_composite(lay, (int(600 * K), int(30 * K)))
    for k in range(4):
        x = 690 + k * 16
        d.polygon([(x * K, 470 * K), ((x - 10) * K, 410 * K), ((x + 4) * K, 404 * K), ((x + 8) * K, 470 * K)], fill=(50, 150, 90, 255), outline=ink, width=K)
    for k in range(3):
        x = 760 + k * 22
        d.ellipse((x * K, 450 * K, (x + 18) * K, 468 * K), fill=(236, 190, 60, 255), outline=ink, width=2 * K)
    codex_frame(d, W, H, K)
    paint = finish(img, K)
    base = plaster_bg(R, W, H, (0.93, 0.9, 0.82), var=0.06)
    prot = np.zeros((H, W), np.float32)
    prot[40:480, 160:820] = 0.85
    save_rgb(age_panel(paint, R, base, loss=0.05, fade=0.1, cracks=0.6, damp=0.15, protect=prot), "fresque_nanahuatzin.png")


def tonatiuh(p):
    """Le visage de Tonatiuh, le Soleil : face ronde, langue en couteau de silex, boucles d'oreille."""
    p.disc(0.5, 0.5, 0.36, "yellow")
    p.poly(ellp(0.36, 0.42, 0.07, 0.04, 180, 360, 8), "white", w=0.012)
    p.poly(ellp(0.64, 0.42, 0.07, 0.04, 180, 360, 8), "white", w=0.012)
    p.dot(0.36, 0.4, 0.02)
    p.dot(0.64, 0.4, 0.02)
    p.poly([(0.47, 0.44), (0.53, 0.44), (0.55, 0.56), (0.45, 0.56)], "yellow", w=0.01)
    p.poly([(0.38, 0.62), (0.62, 0.62), (0.58, 0.68), (0.42, 0.68)], "white", w=0.01)
    p.poly([(0.44, 0.66), (0.56, 0.66), (0.52, 0.86), (0.48, 0.86)], "red", w=0.01)
    for x in (0.14, 0.86):
        p.disc(x, 0.5, 0.07, "jade")
        p.dot(x, 0.5, 0.025)
    p.poly([(0.22, 0.2), (0.78, 0.2), (0.7, 0.28), (0.3, 0.28)], "red", w=0.01)


def order_badge(p, n, fill="white"):
    """Le numéro d'ordre : un rond cerné de rouge, n gros points noirs dedans."""
    p.disc(0.5, 0.5, 0.46, "red")
    p.disc(0.5, 0.5, 0.38, fill)
    pos = {1: [(0.5, 0.5)], 2: [(0.34, 0.5), (0.66, 0.5)], 3: [(0.3, 0.6), (0.5, 0.32), (0.7, 0.6)],
           4: [(0.34, 0.34), (0.66, 0.34), (0.34, 0.66), (0.66, 0.66)], 5: [(0.3, 0.3), (0.7, 0.3), (0.5, 0.5), (0.3, 0.7), (0.7, 0.7)]}[n]
    for (x, y) in pos:
        p.disc(x, y, 0.1, "black", ol=False)


def arrow(d, pts, K, col=(176, 40, 30), w=12):
    """Une flèche épaisse, cernée de noir, le long d'une ligne (coordonnées finales)."""
    ink = (24, 20, 18, 255)
    q = [(x * K, y * K) for x, y in pts]
    d.line(q, fill=ink, width=(w + 6) * K, joint="curve")
    d.line(q, fill=col + (255,), width=w * K, joint="curve")
    (x0, y0), (x1, y1) = pts[-2], pts[-1]
    a = math.atan2(y1 - y0, x1 - x0)
    tip = (x1 + math.cos(a) * 26, y1 + math.sin(a) * 26)
    l = (x1 + math.cos(a + 2.2) * 26, y1 + math.sin(a + 2.2) * 26)
    r = (x1 + math.cos(a - 2.2) * 26, y1 + math.sin(a - 2.2) * 26)
    d.polygon([(tip[0] * K, tip[1] * K), (l[0] * K, l[1] * K), (r[0] * K, r[1] * K)], fill=col + (255,), outline=ink, width=3 * K)


def codex_soleils():
    """Page de codex (peau de cerf enduite de blanc) : la légende des Soleils. Au centre le
    Cinquième Soleil (le visage de Tonatiuh sur le signe Ollin) ; autour, les quatre soleils
    passés, chacun dans son cartouche avec ses quatre points (« Nahui ») et son numéro d'ordre en
    gros points dans un rond rouge : 1 Jaguar en haut à droite, 2 Vent en bas à droite, 3 Pluie de
    feu en bas à gauche, 4 Eau en haut à gauche ; des flèches rouges font le tour dans cet ordre et
    mènent au centre (5)."""
    W = H = 1024
    K = 2
    R = rng(6983)
    img, d = canvas(W, H, K)
    pal = PAL_CODEX
    # la peau de cerf autour, la page blanche
    d.rectangle((0, 0, W * K, H * K), fill=(176, 130, 86, 255))
    d.rounded_rectangle((34 * K, 34 * K, (W - 34) * K, (H - 34) * K), radius=20 * K, fill=(242, 236, 220, 255))
    d.rectangle((52 * K, 52 * K, (W - 52) * K, (H - 52) * K), outline=(176, 40, 30, 255), width=6 * K)
    d.rectangle((64 * K, 64 * K, (W - 64) * K, (H - 64) * K), outline=(176, 40, 30, 255), width=2 * K)
    # le centre : Ollin et Tonatiuh, entourés de rayons
    pcx = pen(img, (512 * K - 150 * K, 512 * K - 150 * K, 300 * K, 300 * K), pal, lw=0.008)
    for k in range(16):
        a = k / 16 * 360 + 11.25
        pcx.poly([(0.5 + math.cos(math.radians(a - 7)) * 0.36, 0.5 + math.sin(math.radians(a - 7)) * 0.36),
                  (0.5 + math.cos(math.radians(a)) * 0.5, 0.5 + math.sin(math.radians(a)) * 0.5),
                  (0.5 + math.cos(math.radians(a + 7)) * 0.36, 0.5 + math.sin(math.radians(a + 7)) * 0.36)], "yellow" if k % 2 else "red")
    pcx.disc(0.5, 0.5, 0.38, "red")
    az_ollin(pcx.sub(0.17, 0.17, 0.66, 0.66))
    tonatiuh(pcx.sub(0.33, 0.33, 0.34, 0.34))
    az_dots(pcx.sub(0.3, 0.84, 0.4, 0.12), 4, 0.5, 0.11)
    # les quatre soleils passés, leur numéro d'ordre au coin tourné vers le centre
    cards = {"jaguar": (792, 232), "vent": (792, 792), "feu": (232, 792), "eau": (232, 232)}
    order = ["jaguar", "vent", "feu", "eau"]
    S = 240
    for k, key in enumerate(order):
        cx, cy = cards[key]
        pc = pen(img, ((cx - S / 2) * K, (cy - S / 2) * K, S * K, S * K), dict(pal, f=(246, 240, 224, 255)), lw=0.012)
        az_sun_sign(pc, key)
    for k, key in enumerate(order):
        cx, cy = cards[key]
        bx = cx + (-132 if cx > 512 else 132)
        by = cy + (-132 if cy > 512 else 132)
        order_badge(pen(img, ((bx - 42) * K, (by - 42) * K, 84 * K, 84 * K), pal, lw=0.04), k + 1)
    order_badge(pen(img, ((512 - 40) * K, (300 - 40) * K, 80 * K, 80 * K), pal, lw=0.04), 5)
    # les flèches : 1 -> 2 -> 3 -> 4 -> 5 (le centre)
    arrow(d, [(934, 376), (946, 512), (934, 640)], K)
    arrow(d, [(648, 934), (512, 946), (376, 934)], K)
    arrow(d, [(90, 648), (78, 512), (90, 384)], K)
    arrow(d, [(376, 150), (430, 170), (452, 236)], K)
    paint = finish(img, K)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    base = plaster_bg(R, W, H, (0.93, 0.9, 0.82), var=0.05)
    hide = plaster_bg(R, W, H, (0.66, 0.48, 0.32), var=0.1)
    border = np.minimum(np.minimum(xx, W - 1 - xx), np.minimum(yy, H - 1 - yy))
    base = mix(hide, base, smooth(30, 40, border))
    prot = np.ones((H, W), np.float32) * 0.9
    col = age_panel(paint, R, base, loss=0.04, fade=0.08, protect=prot, cracks=0.5, vignette=0.15, damp=0.12)
    save_rgb(col, "codex_soleils.png")


def pierre_soleil():
    """La Pierre du Soleil : disque de basalte gris sculpté en relief (fond transparent) : au centre
    le visage de Tonatiuh ; autour, les quatre soleils passés dans le signe Ollin (placés comme
    sur le codex : Jaguar en haut à droite, Vent en bas à droite, Pluie de feu en bas à gauche,
    Eau en haut à gauche) ; l'anneau des vingt jours ; les rayons ; deux serpents de feu ; traces
    de peinture rouge et ocre."""
    S = 1024
    K = 2
    SS = S * K
    R = rng(6984)
    col, shp, lin = _layers(SS, SS)
    pal = dict(PAL_CODEX)
    pal.update({"f": (0, 0, 0, 0), "ink": (0, 0, 0, 0)})
    p = Pen((0, 0, SS, SS), col, shp, lin, pal, lw=0.003)
    c = 0.5
    # anneaux
    for r, w in ((0.488, 0.006), (0.37, 0.004), (0.295, 0.004), (0.225, 0.004)):
        p.stroke(ellp(c, c, r, r, 0, 360, 120), w, "f", ol=False)
    # serpents de feu (anneau extérieur)
    for side in (-1, 1):
        for k in range(18):
            a0 = 90 + side * (14 + k * 9.0)
            a1 = a0 + side * 8.0
            r0, r1 = 0.39, 0.475
            q = ellp(c, c, r0, r0, a0, a1, 4) + ellp(c, c, r1, r1, a1, a0, 4)
            p.poly(q, "red" if k % 3 == 0 else "f", ol=True, w=0.002)
            am = math.radians((a0 + a1) / 2)
            p.poly([(c + math.cos(am) * 0.475, c + math.sin(am) * 0.475), (c + math.cos(am + side * 0.03) * 0.5, c + math.sin(am + side * 0.03) * 0.5),
                    (c + math.cos(am + side * 0.06) * 0.475, c + math.sin(am + side * 0.06) * 0.475)], "f", w=0.002)
        hx = c + side * 0.06
        p.poly([(hx - 0.07, 0.86), (hx + 0.07, 0.86), (hx + 0.06, 0.97), (hx - 0.06, 0.97)], "f", w=0.002)
        p.disc(hx + side * 0.02, 0.9, 0.016, "f")
        p.dot(hx + side * 0.02, 0.9, 0.006)
        for j in range(4):
            p.poly([(hx - 0.05 + j * 0.03, 0.95), (hx - 0.04 + j * 0.03, 0.95), (hx - 0.045 + j * 0.03, 0.975)], "f", w=0.0015)
    p.poly([(0.46, 0.015), (0.54, 0.015), (0.54, 0.09), (0.46, 0.09)], "f", w=0.002)
    for j in range(13 if False else 3):
        p.dot(0.48 + j * 0.02, 0.05, 0.007)
    # les rayons
    for k in range(8):
        a = k * 45 - 90
        am = math.radians(a)
        p.poly([(c + math.cos(am - 0.12) * 0.3, c + math.sin(am - 0.12) * 0.3), (c + math.cos(am) * 0.385, c + math.sin(am) * 0.385),
                (c + math.cos(am + 0.12) * 0.3, c + math.sin(am + 0.12) * 0.3)], "red" if k % 2 else "f", w=0.002)
        am2 = math.radians(a + 22.5)
        p.poly([(c + math.cos(am2 - 0.05) * 0.3, c + math.sin(am2 - 0.05) * 0.3), (c + math.cos(am2) * 0.35, c + math.sin(am2) * 0.35),
                (c + math.cos(am2 + 0.05) * 0.3, c + math.sin(am2 + 0.05) * 0.3)], "f", w=0.002)
    for k in range(40):
        am = math.radians(k * 9)
        p.ring(c + math.cos(am) * 0.31, c + math.sin(am) * 0.31, 0.006, 0.0015)
    # les vingt jours
    for k, (key, _, fn) in enumerate(MAYA_DAYS):
        a = math.radians(-90 + (k + 0.5) * 18)
        x, y = c + math.cos(a) * 0.26, c + math.sin(a) * 0.26
        box = p.sub(x - 0.032, y - 0.032, 0.064, 0.064)
        box.poly([(0.02, 0.02), (0.98, 0.02), (0.98, 0.98), (0.02, 0.98)], "f", w=0.04)
        fn(box.sub(0.1, 0.1, 0.8, 0.8))
    # le signe Ollin et les quatre soleils
    p.disc(c, c, 0.215, "f", ol=False)
    for key, (dx, dy) in (("jaguar", (1, -1)), ("vent", (1, 1)), ("feu", (-1, 1)), ("eau", (-1, -1))):
        x, y = c + dx * 0.115, c + dy * 0.115
        box = p.sub(x - 0.065, y - 0.065, 0.13, 0.13)
        box.poly([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)], "f", w=0.03)
        az_sun_sign(box, key, frame=False)
    p.disc(c, c, 0.09, "f")
    tonatiuh(p.sub(c - 0.085, c - 0.085, 0.17, 0.17))
    sh = down(_arr(shp), K)
    ln = down(_arr(lin), K)
    pc = down(_arr(col), K)
    del col, shp, lin
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    rr = np.hypot(xx - S / 2 + 0.5, yy - S / 2 + 0.5)
    disc = smooth(0.0, 1.5, 506 - rr)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    ero = tn(R, S, (16, 32, 64, 128), 0.65)
    relief = gblur(sh, 1.4) * (1 - 0.25 * smooth(0.62, 0.82, ero))
    lnn = ln * smooth(0.5, 0.9, gblur(sh, 1.5))
    h = 0.3 + relief * 0.5 - gblur(lnn, 0.6) * 0.3 + mot * 0.06 + fine * 0.05 - smooth(480, 506, rr) * 0.2
    stone = C(0.5, 0.49, 0.47) * (0.85 + 0.24 * mot[..., None]) * (0.88 + 0.2 * fine[..., None])
    back = 1 - smooth(0.2, 0.6, relief)
    stone = mix(stone, stone * 0.55, back * 0.7)
    stone = stone * (1 - 0.4 * lnn[..., None])
    wear = smooth(0.3, 0.5, tn(R, S, (8, 16, 32, 64), 0.6) + (fine - 0.5) * 0.3)
    pa = pc[..., 3] * 0.32 * wear
    pcol = pc[..., :3] / np.maximum(pc[..., 3:4], 1e-3)
    stone = mix(stone, mix(pcol, stone, 0.3) * 0.85, pa)
    rp = smooth(0.45, 0.65, tn(R, S, (8, 16, 32), 0.6)) * back
    stone = mix(stone, C(0.5, 0.2, 0.14), rp * 0.4)
    stone = bake(stone, h, 4.0, k=0.55, ao=0.35, ao_r=4)
    stone = stone * (0.75 + 0.25 * smooth(470, 440, rr))[..., None]
    save_rgba(np.dstack([stone, disc]), "pierre_soleil.png")


def panneaux():
    fresque_pesee()
    fresque_barque()
    fresque_osiris()
    fresque_nil()
    papyrus_thot()
    fresque_jumeaux()
    fresque_xibalba()
    stele_4ahau()
    fresque_kukulkan()
    codex_soleils()
    fresque_tlaloc()
    fresque_huitzilopochtli()
    fresque_nanahuatzin()
    pierre_soleil()


# =================================================================== icônes (128 px, comme les autres)

IS = 512


def vol(img, draw, base, depth=14, gloss=0.4, strength=60.0, tex=None, alpha=1.0):
    """Une forme en volume : draw(ImageDraw) dessine la silhouette en blanc ; ombrée comme les
    autres icônes (clair en haut à gauche, bords sombres, petit reflet)."""
    m = Image.new("L", (IS, IS), 0)
    draw(ImageDraw.Draw(m))
    a = np.asarray(m, np.float32) / 255.0
    h = gblur(a, depth)
    gx, gy = grads(h)
    nx, ny = -gx * strength, -gy * strength
    inv = 1.0 / np.sqrt(nx * nx + ny * ny + 1.0)
    L = np.array((-0.45, -0.55, 0.7), np.float32)
    L /= np.linalg.norm(L)
    lam = np.clip((nx * L[0] + ny * L[1] + L[2]) * inv, 0, 1)
    col = np.array(base, np.float32)[None, None, :] / 255.0
    if tex is not None:
        col = col * tex[..., None]
    col = col * (0.32 + 0.78 * lam[..., None])
    if gloss:
        col = col + (lam ** 24 * gloss)[..., None]
    layer = np.dstack([np.clip(col, 0, 1), a * alpha])
    img.alpha_composite(Image.fromarray((layer * 255 + 0.5).astype(np.uint8), "RGBA"))
    return a


def ico_save(img, name):
    import generate_items_v28 as icons
    icons.OUT = ITEMS
    img2 = icons.shadow(icons.outline(img))
    p = ITEMS / (name + ".png")
    img2.resize((128, 128), Image.LANCZOS).save(p, optimize=True)
    print(p.relative_to(ROOT))


def ico_pen(img, box, pal=None, lw=0.03):
    return Pen(box, img, None, None, pal, lw=lw)


def ic_oeil_horus():
    img = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    lay, shp, _ = _layers(IS, IS)
    pal = {"blue": (40, 70, 170, 255), "black": (20, 24, 60, 255), "white": (240, 236, 220, 255), "ink": (190, 140, 40, 255)}
    eg_wedjat(Pen((40, 70, 432, 380), lay, shp, None, pal, lw=0.03), iris="black", white="white", brow="blue")
    sh = _arr(shp.filter(ImageFilter.MaxFilter(9)))
    vol(img, lambda d: d.bitmap((0, 0), shp.filter(ImageFilter.MaxFilter(9)), fill=255), (226, 176, 60), depth=8, gloss=0.6)
    la = np.asarray(lay, np.float32) / 255.0
    inner = la[..., 3] * (1 - (np.abs(la[..., 0] - 190 / 255.0) < 0.02))
    h = gblur(la[..., 3], 4)
    gx, gy = grads(h)
    lam = np.clip(0.7 - gx * 30 - gy * 30, 0, 1.2)
    col = la[..., :3] * (0.6 + 0.5 * lam[..., None])
    a = inner * 0.95
    img.alpha_composite(Image.fromarray((np.dstack([np.clip(col, 0, 1), a]) * 255).astype(np.uint8), "RGBA"))
    d = ImageDraw.Draw(img)
    d.ellipse((222, 156, 240, 174), fill=(255, 255, 255, 200))
    del sh
    ico_save(img, "oeil_horus")


def ic_masque_jade():
    img = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    face = [(256, 40), (360, 60), (420, 150), (420, 290), (380, 400), (300, 470), (212, 470), (132, 400), (92, 290), (92, 150), (152, 60)]
    face = chaikin(face, 2)
    R = rng(7001)
    # tesselles de jade
    yy, xx = np.mgrid[0:IS, 0:IS].astype(np.float32)
    pts = R.random((140, 2)) * IS
    d1 = np.full((IS, IS), 1e9, np.float32)
    d2 = np.full((IS, IS), 1e9, np.float32)
    idx = np.zeros((IS, IS), np.int32)
    for i, (px, py) in enumerate(pts):
        dd = np.hypot(xx - px, yy - py)
        c = dd < d1
        d2 = np.where(c, d1, np.minimum(d2, dd))
        idx = np.where(c, i, idx)
        d1 = np.where(c, dd, d1)
    tone = R.uniform(0.75, 1.15, len(pts)).astype(np.float32)[idx]
    grout = smooth(1.0, 3.0, d2 - d1)
    tex = tone * (0.35 + 0.65 * grout)
    vol(img, lambda d: d.polygon(face, fill=255), (60, 170, 110), depth=26, gloss=0.5, tex=tex)
    d = ImageDraw.Draw(img)
    for sx in (-1, 1):
        cx = 256 + sx * 80
        d.polygon([(cx - 56, 200), (cx - 10 * sx * 0 - 20, 182), (cx + 30, 186), (cx + 56, 206), (cx + 20, 222), (cx - 30, 220)], fill=(240, 236, 222, 255), outline=(30, 40, 30, 255))
        d.ellipse((cx - 16, 190, cx + 16, 222), fill=(18, 18, 22, 255))
        d.ellipse((cx - 8, 194, cx - 1, 202), fill=(200, 200, 210, 255))
        d.line([(cx - 60, 170), (cx + 50, 162)], fill=(30, 70, 50, 255), width=10)
    d.polygon([(256, 210), (284, 300), (256, 320), (228, 300)], fill=(50, 140, 90, 255), outline=(20, 50, 30, 255))
    d.polygon([(200, 360), (312, 360), (296, 392), (216, 392)], fill=(160, 40, 34, 255), outline=(30, 20, 20, 255), width=3)
    for x in range(214, 300, 16):
        d.rectangle((x, 362, x + 10, 374), fill=(240, 236, 222, 255))
    for sx in (-1, 1):
        d.ellipse((256 + sx * 190 - 34, 230, 256 + sx * 190 + 34, 298), fill=(70, 180, 120, 255), outline=(20, 60, 40, 255), width=5)
        d.ellipse((256 + sx * 190 - 12, 252, 256 + sx * 190 + 12, 276), fill=(20, 60, 40, 255))
    ico_save(img, "masque_jade")


def _feather(img, base_pts, cols, width=46, curl=0.0, vane=True):
    """Une longue plume : tige courbe, barbes en dégradé de couleurs (de la base à la pointe)."""
    d = ImageDraw.Draw(img)
    n = len(base_pts)
    for i in range(n - 1):
        t = i / (n - 1)
        (x0, y0), (x1, y1) = base_pts[i], base_pts[i + 1]
        a = math.atan2(y1 - y0, x1 - x0)
        w = width * math.sin(math.pi * min(1.0, 0.15 + t * 0.95)) ** 0.6
        k = min(len(cols) - 1, int(t * len(cols)))
        c0 = cols[k]
        c1 = cols[min(len(cols) - 1, k + 1)]
        f = t * len(cols) - k
        c = tuple(int(c0[j] * (1 - f) + c1[j] * f) for j in range(3))
        for sgn in (-1, 1):
            b = a + sgn * 1.15
            xe, ye = x0 + math.cos(b) * w, y0 + math.sin(b) * w
            d.line([(x0, y0), (xe + math.cos(a) * w * 0.4, ye + math.sin(a) * w * 0.4)], fill=c + (255,), width=7)
            d.line([(x0, y0), (xe + math.cos(a) * w * 0.4, ye + math.sin(a) * w * 0.4)], fill=tuple(int(v * 0.75) for v in c) + (255,), width=2)
    d.line(base_pts, fill=(250, 244, 220, 255), width=6, joint="curve")


def ic_plume_quetzal():
    img = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    pts = bez((110, 470), (170, 200), (420, 40), None, 60)
    _feather(img, pts, [(30, 120, 60), (40, 170, 90), (30, 150, 140), (60, 190, 110), (170, 200, 70)], width=40)
    ico_save(img, "plume_quetzal")


def ic_plume_ara():
    img = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    pts = bez((120, 460), (230, 300), (400, 70), None, 50)
    _feather(img, pts, [(240, 200, 60), (226, 40, 30), (214, 30, 26), (210, 30, 30), (40, 90, 200)], width=52)
    ico_save(img, "plume_ara")


def ic_fragment_osiris():
    img = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    broken = [(150, 470), (170, 420), (140, 380), (172, 330), (160, 300), (352, 300), (346, 350), (372, 390), (340, 430), (360, 470)]
    vol(img, lambda d: d.polygon(broken, fill=255), (60, 150, 120), depth=14, gloss=0.4)
    vol(img, lambda d: d.polygon(chaikin([(196, 120), (318, 120), (334, 220), (316, 300), (256, 330), (196, 300), (178, 220)], 2), fill=255), (70, 170, 110), depth=18, gloss=0.5)
    vol(img, lambda d: d.polygon(chaikin([(196, 136), (206, 80), (226, 40), (238, 14), (274, 14), (286, 40), (306, 80), (316, 136)], 1), fill=255), (238, 234, 218), depth=14, gloss=0.4)
    vol(img, lambda d: d.ellipse((236, 0, 276, 34), fill=255), (238, 234, 218), depth=8, gloss=0.4)
    d = ImageDraw.Draw(img)
    for sx in (-1, 1):
        d.polygon([(256 + sx * 28 - 20, 200), (256 + sx * 28, 190), (256 + sx * 28 + 20, 200), (256 + sx * 28, 210)], fill=(240, 236, 222, 255), outline=(20, 20, 20, 255), width=3)
        d.ellipse((256 + sx * 28 - 6, 194, 256 + sx * 28 + 6, 206), fill=(20, 20, 20, 255))
    d.line([(256, 206), (248, 250), (262, 254)], fill=(30, 80, 50, 255), width=4)
    d.polygon([(240, 300), (272, 300), (266, 352), (246, 352)], fill=(40, 34, 30, 255))
    d.line([(196, 330), (300, 440)], fill=(60, 90, 190, 255), width=14)
    d.arc((172, 300, 222, 350), 140, 330, fill=(60, 90, 190, 255), width=14)
    d.line([(316, 330), (212, 440)], fill=(230, 186, 70, 255), width=14)
    for k in range(3):
        d.line([(316, 330), (330 + k * 14, 290)], fill=(230, 186, 70, 255), width=6)
    d.line(broken[-1:] + broken[:2], fill=(170, 210, 190, 255), width=5)
    ico_save(img, "fragment_osiris")


def ic_viande_cerf():
    img = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    R = rng(7004)
    tex = 0.85 + 0.25 * tn(R, IS, (8, 16, 32, 64), 0.6)
    vol(img, lambda d: d.ellipse((110, 150, 410, 400), fill=255), (176, 56, 46), depth=26, gloss=0.35, tex=tex)
    d = ImageDraw.Draw(img)
    for k in range(5):
        d.arc((150 + k * 20, 190 + k * 12, 370 - k * 18, 370 - k * 10), 200, 320, fill=(230, 210, 200, 255), width=5)
    vol(img, lambda d: (d.line([(380, 210), (460, 120)], fill=255, width=34), d.ellipse((440, 84, 492, 136), fill=255), d.ellipse((418, 70, 466, 118), fill=255)), (240, 232, 210), depth=8, gloss=0.4)
    leaf = [(70, 300), (150, 220), (280, 300), (360, 360), (420, 410), (300, 470), (160, 440)]
    vol(img, lambda d: d.polygon(chaikin(leaf, 2), fill=255), (70, 150, 60), depth=14, gloss=0.3)
    d = ImageDraw.Draw(img)
    d.line([(90, 330), (240, 380), (400, 420)], fill=(150, 210, 110, 255), width=4)
    for k in range(6):
        x = 130 + k * 45
        d.line([(x, 340 + k * 8), (x + 30, 300 + k * 10)], fill=(50, 120, 50, 255), width=3)
        d.line([(x, 340 + k * 8), (x + 26, 400 + k * 6)], fill=(50, 120, 50, 255), width=3)
    d.line([(220, 300), (300, 440)], fill=(210, 190, 140, 255), width=8)
    ico_save(img, "viande_cerf")


def _bone(d, a, b, w):
    d.line([a, b], fill=255, width=w)
    ang = math.atan2(b[1] - a[1], b[0] - a[0])
    for (x, y), s in ((a, -1), (b, 1)):
        for o in (-1, 1):
            cx = x + math.cos(ang + o * math.pi / 2) * w * 0.55 + math.cos(ang) * s * w * 0.2
            cy = y + math.sin(ang + o * math.pi / 2) * w * 0.55 + math.sin(ang) * s * w * 0.2
            d.ellipse((cx - w * 0.6, cy - w * 0.6, cx + w * 0.6, cy + w * 0.6), fill=255)


def ic_os_jaguar():
    img = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    vol(img, lambda d: _bone(d, (120, 380), (390, 130), 46), (236, 226, 196), depth=10, gloss=0.35)
    vol(img, lambda d: _bone(d, (130, 150), (400, 400), 40), (228, 216, 182), depth=10, gloss=0.35)
    d = ImageDraw.Draw(img)
    for (x, y) in ((220, 260), (300, 320), (180, 200)):
        d.ellipse((x - 4, y - 4, x + 4, y + 4), fill=(170, 150, 110, 255))
    ico_save(img, "os_jaguar")


def ic_copal():
    img = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    R = rng(7006)
    tex = 0.85 + 0.25 * tn(R, IS, (8, 16, 32), 0.6)
    lump = chaikin([(120, 300), (150, 200), (230, 150), (330, 170), (400, 240), (410, 340), (340, 410), (220, 420), (140, 380)], 2)
    vol(img, lambda d: d.polygon(lump, fill=255), (240, 214, 130), depth=30, gloss=0.8, tex=tex)
    vol(img, lambda d: d.polygon(chaikin([(300, 330), (360, 300), (420, 340), (400, 410), (330, 420)], 2), fill=255), (236, 200, 110), depth=16, gloss=0.8, tex=tex)
    d = ImageDraw.Draw(img)
    for (x, y, r) in ((220, 260, 10), (280, 220, 7), (250, 330, 6)):
        d.ellipse((x - r, y - r, x + r, y + r), fill=(200, 160, 70, 200))
    for k in range(3):
        x = 200 + k * 50
        d.arc((x - 20, 40, x + 20, 140), 100, 260, fill=(220, 220, 224, 170), width=8)
    ico_save(img, "copal")


def ic_jarre_pluie():
    img = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    jar = chaikin([(170, 110), (342, 110), (330, 150), (410, 230), (420, 330), (370, 430), (256, 470), (142, 430), (92, 330), (102, 230), (182, 150)], 2)
    vol(img, lambda d: d.polygon(jar, fill=255), (50, 110, 190), depth=34, gloss=0.5)
    vol(img, lambda d: d.ellipse((150, 80, 362, 140), fill=255), (40, 90, 160), depth=6, gloss=0.3)
    d = ImageDraw.Draw(img)
    d.ellipse((180, 92, 332, 128), fill=(18, 30, 60, 255))
    for sx in (-1, 1):
        cx = 256 + sx * 62
        d.ellipse((cx - 44, 200, cx + 44, 288), fill=(236, 236, 240, 255), outline=(20, 20, 30, 255), width=6)
        d.ellipse((cx - 24, 220, cx + 24, 268), fill=(40, 90, 170, 255))
        d.ellipse((cx - 10, 234, cx + 10, 254), fill=(16, 16, 20, 255))
    d.line(chaikin([(180, 330), (220, 300), (256, 316), (292, 300), (332, 330)], 2, False), fill=(200, 50, 40, 255), width=18, joint="curve")
    for x in (226, 256, 286):
        d.polygon([(x - 10, 330), (x + 10, 330), (x, 372)], fill=(244, 240, 228, 255), outline=(20, 20, 20, 255))
    for k in range(3):
        x = 140 + k * 116
        d.polygon([(x, 400), (x + 12, 424), (x, 436), (x - 12, 424)], fill=(120, 190, 240, 255))
    ico_save(img, "jarre_pluie")


def _rot(pts, cx, cy, a):
    ca, sa = math.cos(a), math.sin(a)
    return [(cx + (x - cx) * ca - (y - cy) * sa, cy + (x - cx) * sa + (y - cy) * ca) for x, y in pts]


def ic_conque():
    """La conque d'Ehécatl : spire à étages en haut à droite, épaules à bosses, grande ouverture
    rose au bord évasé, canal en pointe en bas à gauche."""
    img = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    a = -0.72
    cx, cy = 236, 286
    body = _rot(ellp(cx, cy, 190, 112, 0, 360, 48), cx, cy, a)
    canal = _rot([(cx - 150, cy - 30), (cx - 250, cy + 4), (cx - 252, cy + 16), (cx - 150, cy + 50)], cx, cy, a)
    vol(img, lambda d: d.polygon(canal, fill=255), (232, 214, 196), depth=10, gloss=0.4)
    for k in range(5):
        t = k / 5
        sx, sy = cx + 120 + t * 120, cy
        r = 70 * (1 - t * 0.8)
        whorl = _rot(ellp(sx, sy, r * 0.7, r, 0, 360, 24), cx, cy, a)
        vol(img, lambda d, w=whorl: d.polygon(w, fill=255), (236, 220, 200), depth=10, gloss=0.4)
    vol(img, lambda d: d.polygon(body, fill=255), (240, 226, 210), depth=34, gloss=0.5)
    for k in range(6):
        kx, ky = cx - 100 + k * 40, cy - 100 - 6 * math.sin(k)
        knob = _rot([(kx - 18, ky + 14), (kx, ky - 30), (kx + 18, ky + 14)], cx, cy, a)
        vol(img, lambda d, kn=knob: d.polygon(kn, fill=255), (230, 212, 190), depth=6, gloss=0.4)
    lip = _rot(chaikin([(cx - 150, cy + 10), (cx - 40, cy + 40), (cx + 100, cy + 30), (cx + 120, cy + 90), (cx + 20, cy + 150),
                        (cx - 120, cy + 110)], 2), cx, cy, a)
    vol(img, lambda d: d.polygon(lip, fill=255), (246, 200, 196), depth=20, gloss=0.6)
    hole = _rot(chaikin([(cx - 120, cy + 40), (cx - 20, cy + 56), (cx + 80, cy + 56), (cx + 60, cy + 100), (cx - 40, cy + 112)], 2), cx, cy, a)
    vol(img, lambda d: d.polygon(hole, fill=255), (214, 110, 120), depth=14, gloss=0.3)
    d = ImageDraw.Draw(img)
    for k in range(4):
        st = _rot(ellp(cx - 20 + k * 40, cy - 10, 30, 80, 250, 290, 6), cx, cy, a)
        d.line(st, fill=(190, 160, 140, 255), width=4)
    ico_save(img, "conque")


def ic_moustique():
    img = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    R = rng(7011)
    tex = 0.88 + 0.2 * tn(R, IS, (8, 16, 32, 64), 0.6)
    gourd = chaikin([(250, 470), (150, 440), (110, 370), (140, 290), (210, 250), (220, 200), (210, 150), (240, 120), (290, 130), (300, 190), (300, 250),
                     (370, 290), (400, 370), (360, 440)], 2)
    vol(img, lambda d: d.polygon(gourd, fill=255), (214, 168, 80), depth=30, gloss=0.4, tex=tex)
    d = ImageDraw.Draw(img)
    d.line([(150, 340), (360, 340)], fill=(150, 100, 50, 255), width=8)
    d.ellipse((232, 112, 280, 136), fill=(60, 40, 24, 255))
    d.line([(256, 116), (276, 60)], fill=(120, 90, 50, 255), width=8)
    mosquito(Pen((230, 20, 230, 170), img, None, None, dict(PAL_MAYA, ink=(20, 16, 14, 255)), lw=0.025, flip=True))
    ico_save(img, "moustique")


def ic_glyphe(key, name, seed):
    img = carve(lambda p: az_sun_sign(p.sub(0.08, 0.08, 0.84, 0.84), key), seed, "az", W=1024, paint=0.6, out=IS, rim=False)
    ico_save(img, name)


def ic_scarabee():
    img = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    d0 = None
    vol(img, lambda d: [d.line([(256 + sx * 90, y), (256 + sx * 170, y + dy)], fill=255, width=22) for sx in (-1, 1) for (y, dy) in ((200, -50), (290, 10), (360, 70))],
        (30, 70, 130), depth=4, gloss=0.4)
    vol(img, lambda d: d.ellipse((130, 170, 382, 470), fill=255), (40, 110, 200), depth=34, gloss=0.8)
    vol(img, lambda d: d.chord((166, 80, 346, 220), 180, 360, fill=255), (40, 110, 200), depth=16, gloss=0.8)
    d = ImageDraw.Draw(img)
    d.line([(256, 200), (256, 460)], fill=(20, 50, 110, 255), width=6)
    d.arc((150, 190, 362, 280), 200, 340, fill=(20, 50, 110, 255), width=6)
    for x in (200, 236, 276, 312):
        d.line([(x, 110), (x - (256 - x) * 0.1, 146)], fill=(20, 50, 110, 255), width=4)
    del d0
    ico_save(img, "scarabee")


def ic_papyrus_thot():
    img = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    R = rng(7017)
    fib = 0.85 + 0.2 * tn(R, IS, (64, 128, 256), 0.7, oy=(4, 8, 16))
    vol(img, lambda d: d.polygon([(150, 120), (380, 120), (380, 420), (150, 420)], fill=255), (226, 200, 140), depth=6, gloss=0.1, tex=fib)
    d = ImageDraw.Draw(img)
    pal = {k: (40, 30, 22, 255) for k in PAL_EG}
    for k2 in pal:
        pal[k2] = (0, 0, 0, 0)
    pal["ink"] = (40, 30, 22, 255)
    for c, x in enumerate((180, 240, 300)):
        for r, name in enumerate(list(EG_SIGNS)[c * 4:(c * 4) + 4]):
            fn, asp, cat = EG_SIGNS[name]
            fn(Pen(fit((x, 150 + r * 64, 50, 56), asp, 0.85), img, None, None, pal, lw=0.07))
    for x0 in (110, 380):
        vol(img, lambda d, x0=x0: d.rounded_rectangle((x0 - 26, 90, x0 + 26, 450), radius=26, fill=255), (214, 186, 124), depth=12, gloss=0.3, tex=fib)
    d = ImageDraw.Draw(img)
    for x0 in (110, 380):
        d.ellipse((x0 - 26, 74, x0 + 26, 108), fill=(196, 166, 104, 255), outline=(120, 90, 50, 255), width=3)
        d.ellipse((x0 - 12, 82, x0 + 12, 100), fill=(150, 116, 66, 255))
    d.line([(84, 270), (136, 270)], fill=(190, 40, 30, 255), width=12)
    ico_save(img, "papyrus_thot")


def ic_pain_egypte():
    img = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    R = rng(7018)
    tex = 0.85 + 0.25 * tn(R, IS, (16, 32, 64, 128), 0.65)
    vol(img, lambda d: d.ellipse((60, 150, 452, 420), fill=255), (200, 140, 70), depth=40, gloss=0.3, tex=tex)
    d = ImageDraw.Draw(img)
    for k in range(-2, 3):
        d.arc((150 + k * 40, 200, 330 + k * 40, 380), 230, 310, fill=(140, 86, 40, 255), width=7)
    for _ in range(40):
        x, y = R.uniform(140, 380), R.uniform(200, 360)
        d.ellipse((x - 3, y - 2, x + 3, y + 2), fill=(240, 220, 170, 255))
    ico_save(img, "pain_egypte")


def ic_galette_mais():
    img = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    R = rng(7019)
    for k, (dx, dy) in enumerate(((-20, 70), (20, 20), (-10, -30))):
        tex = 0.88 + 0.18 * tn(R, IS, (16, 32, 64, 128), 0.65)
        vol(img, lambda d, dx=dx, dy=dy: d.ellipse((80 + dx, 170 + dy, 432 + dx, 330 + dy), fill=255), (232, 204, 130), depth=10, gloss=0.25, tex=tex)
        d = ImageDraw.Draw(img)
        for _ in range(16):
            x, y = R.uniform(150 + dx, 360 + dx), R.uniform(200 + dy, 300 + dy)
            r = R.uniform(4, 10)
            d.ellipse((x - r, y - r * 0.6, x + r, y + r * 0.6), fill=(150, 100, 50, 200))
    ico_save(img, "galette_mais")


def ic_cacao():
    img = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    R = rng(7020)
    vol(img, lambda d: d.polygon(chaikin([(100, 210), (412, 210), (390, 380), (330, 450), (182, 450), (122, 380)], 2), fill=255), (176, 80, 46), depth=30, gloss=0.3)
    d = ImageDraw.Draw(img)
    for k in range(9):
        x = 140 + k * 30
        d.line([(x, 300), (x + 10, 330)], fill=(240, 220, 180, 255), width=5)
    d.line([(130, 260), (382, 260)], fill=(240, 220, 180, 255), width=6)
    foam = chaikin([(96, 214), (130, 150), (200, 120), (300, 116), (380, 150), (416, 214)], 2)
    tex = 0.8 + 0.3 * tn(R, IS, (32, 64, 128), 0.6)
    vol(img, lambda d: d.polygon(foam, fill=255), (196, 150, 104), depth=22, gloss=0.4, tex=tex)
    d = ImageDraw.Draw(img)
    for _ in range(26):
        x, y = R.uniform(140, 370), R.uniform(140, 205)
        r = R.uniform(5, 13)
        d.ellipse((x - r, y - r, x + r, y + r), outline=(236, 214, 180, 255), width=3)
    vol(img, lambda d: d.ellipse((370, 330, 470, 470), fill=255), (180, 110, 40), depth=16, gloss=0.4)
    d = ImageDraw.Draw(img)
    for k in range(3):
        d.arc((380 + k * 14, 336, 460 - k * 14, 466), 250, 290, fill=(120, 70, 30, 255), width=4)
    ico_save(img, "cacao")


def ic_biere_heqet():
    img = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    R = rng(7021)
    tex = 0.88 + 0.2 * tn(R, IS, (16, 32, 64, 128), 0.65)
    jar = chaikin([(200, 120), (312, 120), (370, 200), (380, 300), (330, 410), (270, 476), (242, 476), (182, 410), (132, 300), (142, 200)], 2)
    vol(img, lambda d: d.polygon(jar, fill=255), (190, 104, 64), depth=34, gloss=0.3, tex=tex)
    vol(img, lambda d: d.ellipse((190, 60, 322, 150), fill=255), (110, 84, 60), depth=16, gloss=0.2, tex=tex)
    d = ImageDraw.Draw(img)
    for k in range(3):
        d.line([(150, 220 + k * 18), (362, 220 + k * 18)], fill=(130, 60, 34, 255), width=4)
    d.ellipse((236, 86, 276, 110), fill=(160, 130, 90, 255), outline=(80, 60, 40, 255), width=3)
    for k in range(2):
        x = 400 + k * 30
        d.line([(x, 470), (x - 10, 290)], fill=(200, 170, 80, 255), width=6)
        for j in range(6):
            y = 300 + j * 16
            d.ellipse((x - 22 - j * 0.6, y, x - 6, y + 14), fill=(226, 190, 90, 255), outline=(150, 110, 50, 255))
            d.ellipse((x - 10, y + 6, x + 6, y + 20), fill=(226, 190, 90, 255), outline=(150, 110, 50, 255))
    ico_save(img, "biere_heqet")


def ic_cempasuchil():
    """Un petit bouquet de cempasúchil (œillets d'Inde orangés)."""
    img = Image.new("RGBA", (IS, IS), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for (x0, y0) in ((180, 200), (300, 170), (250, 300), (360, 290)):
        d.line([(x0, y0), (256, 470)], fill=(60, 120, 50, 255), width=10)
    for (x, y, a) in ((200, 380, -0.6), (320, 400, 0.5), (240, 430, -0.3), (290, 350, 0.8)):
        poly = leaf_poly(x, y, 90, 26, a - math.pi / 2)
        vol(img, lambda d, poly=poly: d.polygon(poly, fill=255), (70, 140, 50), depth=6, gloss=0.2)
    for (cx, cy, r) in ((180, 200, 80), (310, 170, 78), (250, 300, 84), (370, 290, 66)):
        vol(img, lambda d, cx=cx, cy=cy, r=r: d.ellipse((cx - r, cy - r * 0.9, cx + r, cy + r * 0.9), fill=255), (236, 120, 20), depth=20, gloss=0.25)
        d = ImageDraw.Draw(img)
        for ring, (n, rr, col) in enumerate(((18, 0.85, (250, 160, 40)), (14, 0.6, (240, 130, 20)), (10, 0.36, (250, 170, 50)))):
            for k in range(n):
                a = k / n * TAU + ring * 0.3
                px, py = cx + math.cos(a) * r * rr, cy + math.sin(a) * r * rr * 0.9
                pr = r * 0.2 * (1 - ring * 0.2)
                d.chord((px - pr, py - pr, px + pr, py + pr), math.degrees(a) - 90, math.degrees(a) + 90, fill=col + (255,), outline=(180, 70, 10, 255))
        d.ellipse((cx - r * 0.12, cy - r * 0.12, cx + r * 0.12, cy + r * 0.12), fill=(200, 90, 10, 255))
    ico_save(img, "cempasuchil")


def icones():
    """Les objets de l'Île des Trois Soleils (128 px, ombrés et cernés comme les autres icônes)."""
    ic_oeil_horus()
    ic_masque_jade()
    ic_plume_quetzal()
    ic_fragment_osiris()
    ic_plume_ara()
    ic_viande_cerf()
    ic_os_jaguar()
    ic_copal()
    ic_jarre_pluie()
    ic_conque()
    ic_moustique()
    ic_glyphe("jaguar", "glyphe_jaguar", 7012)
    ic_glyphe("vent", "glyphe_vent", 7013)
    ic_glyphe("feu", "glyphe_feu", 7014)
    ic_glyphe("eau", "glyphe_eau", 7015)
    ic_scarabee()
    ic_papyrus_thot()
    ic_pain_egypte()
    ic_galette_mais()
    ic_cacao()
    ic_biere_heqet()
    ic_cempasuchil()


# =================================================================== lancement

GROUPS = {"sols": sols, "bati": bati, "panneaux": panneaux, "symboles": symboles, "icones": icones}


def main():
    what = sys.argv[1:] or list(GROUPS)
    for w in what:
        if w in GROUPS:
            GROUPS[w]()
        elif w in globals() and callable(globals()[w]) and not w.startswith("_"):
            globals()[w]()
        elif "ic_" + w in globals():
            globals()["ic_" + w]()
        else:
            sys.exit("inconnu : %s (sols | bati | panneaux | symboles | icones | <nom d'une image>)" % w)


if __name__ == "__main__":
    main()
