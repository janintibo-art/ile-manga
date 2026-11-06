"""V115 : textures du Dôme d'Azur (au fond de la mer, sous Hautefond).

dome115/ — surfaces raccordables, avec leur carte de relief <nom>_n.png :
          terrazzo (+_n) : un terrazzo blanc poli, des éclats de nacre (blancs, rosés, bleutés) et de
                           pierre grise dans un ciment clair ; de grandes dalles de 2 m, joints fins de
                           laiton (une tuile ≈ 4 m) : le sol des dômes ;
        — non raccordables (sans relief) :
          enseigne_gare, _ligne, _conque, _comptoir, _atelier, _ecole, _conseil, _serres, _institut,
          _aquarium, _bassin, _jardin, _belvedere (512 x 256) : les enseignes du Dôme (une plaque de
          verre bleu nuit cerclée de nacre, un pictogramme dans un cercle aigue-marine, des lettres qui
          luisent) ;
          gorgone (1024 x 512, transparente) : un éventail de mer, son filet de rameaux, ses polypes ;
          eponge (512, transparente, raccordable) : le treillis d'une éponge de verre.
Et, aux Strates (strates/), l'enseigne de la Ligne du Dôme d'Azur, rouverte (enseigne_dome).

Tout est dessiné ici, procéduralement (libre de droits, aucune image tierce), avec les outils des
générateurs V69, V70, V71 et V113. Déterministe.
Lancement depuis la racine du dépôt :
    python3 pcvr/tools/textures_dome_v115.py [terrazzo | enseignes | strates | vie | gorgone | eponge | <nom>]
"""
import math
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # pas de __pycache__ dans pcvr/tools

import numpy as np  # noqa: E402
from PIL import Image, ImageDraw, ImageFilter  # noqa: E402

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_montjoie_v71 as gm  # noqa: E402
import generate_nuees_v113 as nu  # noqa: E402
from generate_soleils_v69 import tn, smooth, mix, C, bake, per_id, masonry, speck  # noqa: E402
from generate_braise_v70 import grain  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "dome115"
TAU = math.tau


def rng(seed):
    return np.random.default_rng(seed)


# =================================================================== le terrazzo

def terrazzo():
    S = 1024
    R = rng(11501)
    gm.OUT = OUT
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    # de grandes dalles de 2 m (la tuile fait 4 m) : deux rangées, joints de laiton
    rows = [512, 512]
    bid, e, u, v = masonry(R, S, rows, 512, 512, rr=0.0)
    tone = per_id(bid, R, 0.97, 1.03)
    mot = tn(R, S, (4, 8, 16, 32, 64), 0.6)
    fine = tn(R, S, (128, 256, 512, 1024), 0.75)
    gr = grain(R, S, 0.4)
    base = C(0.9, 0.9, 0.88) * (0.97 + 0.05 * mot[..., None]) * (0.98 + 0.04 * fine[..., None]) * (0.985 + 0.03 * gr[..., None])
    base = base * tone[..., None]
    # les éclats : des polygones au hasard, dessinés avec raccord
    img = Image.fromarray((np.clip(base, 0, 1) * 255).astype(np.uint8))
    hmap = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(img)
    dh = ImageDraw.Draw(hmap)
    cols = [((246, 244, 240), 0.5), ((236, 222, 222), 0.14), ((214, 232, 238), 0.14), ((150, 154, 158), 0.12), ((112, 116, 122), 0.06), ((226, 214, 190), 0.04)]
    weights = np.array([c[1] for c in cols])
    weights /= weights.sum()
    n_chips = 5200
    for k in range(n_chips):
        cx, cy = R.uniform(0, S), R.uniform(0, S)
        big = R.random() < 0.08
        r = R.uniform(5.0, 13.0) if big else R.uniform(1.5, 5.0)
        ci = R.choice(len(cols), p=weights)
        col = cols[ci][0]
        jit = R.uniform(-10, 10)
        col = tuple(int(np.clip(c + jit, 0, 255)) for c in col)
        n = R.integers(4, 8)
        a0 = R.uniform(0, TAU)
        pts = []
        for j in range(n):
            a = a0 + j / n * TAU + R.uniform(-0.3, 0.3)
            rr = r * R.uniform(0.55, 1.0)
            pts.append((math.cos(a) * rr, math.sin(a) * rr))
        for ox in (-S, 0, S):
            for oy in (-S, 0, S):
                if cx + ox + r < 0 or cx + ox - r > S or cy + oy + r < 0 or cy + oy - r > S:
                    continue
                pp = [(cx + ox + px, cy + oy + py) for px, py in pts]
                d.polygon(pp, fill=col)
                dh.polygon(pp, fill=int(40 + R.uniform(0, 30)))
    col = np.asarray(img, np.float32) / 255.0
    hh = np.asarray(hmap, np.float32) / 255.0
    # la nacre : un reflet irisé à peine (rose, bleu) sur les éclats clairs
    iri = tn(R, S, (16, 32, 64, 128), 0.6)
    light = np.clip((col.mean(-1) - 0.85) * 6.0, 0, 1)
    col = mix(col, col * C(1.02, 0.97, 1.03), light * smooth(0.4, 0.7, iri) * 0.6)
    col = mix(col, col * C(0.96, 1.01, 1.04), light * smooth(0.4, 0.7, 1 - iri) * 0.6)
    # les joints de laiton
    jm = 1 - smooth(0.6, 1.6, e)
    col = mix(col, C(0.72, 0.6, 0.36), jm * 0.85)
    h = 0.5 + hh * 0.06 + fine * 0.01 - jm * 0.04
    col = bake(col, h, 1.5, k=0.1, ao=0.05, ao_r=2)
    gm.save_surface("terrazzo", col, h, 1.2)


# =================================================================== les enseignes

def _w(s):
    return max(1, int(0.07 * s))


def ic_funi(d, cx, cy, s, c):
    """Une bulle de verre qui descend un tube en pente."""
    w = _w(s)
    d.line([cx - 0.75 * s, cy - 0.62 * s, cx + 0.75 * s, cy + 0.28 * s], fill=c, width=w)
    d.line([cx - 0.75 * s, cy - 0.12 * s, cx + 0.75 * s, cy + 0.78 * s], fill=c, width=w)
    d.rounded_rectangle([cx - 0.3 * s, cy - 0.2 * s, cx + 0.3 * s, cy + 0.32 * s], radius=0.2 * s, fill=(36, 160, 178), outline=c, width=w)
    d.line([cx - 0.2 * s, cy + 0.0 * s, cx + 0.2 * s, cy + 0.0 * s], fill=c, width=max(1, w // 2))


def ic_conque(d, cx, cy, s, c):
    """Une conque en spirale."""
    w = _w(s)
    pts = []
    for k in range(60):
        t = k / 59.0
        a = t * 3.2 * math.pi
        r = 0.08 * s + t * 0.62 * s
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r * 0.85))
    d.line(pts, fill=c, width=w)
    d.line([pts[-1], (pts[-1][0] + 0.12 * s, pts[-1][1] + 0.22 * s)], fill=c, width=w)


def ic_coquille(d, cx, cy, s, c):
    """Une coquille Saint-Jacques."""
    w = _w(s)
    base = (cx, cy + 0.6 * s)
    for k in range(7):
        a = math.pi + (k + 0.5) / 7 * math.pi
        d.line([base, (cx + math.cos(a) * 0.75 * s, cy + 0.15 * s + math.sin(a) * 0.65 * s)], fill=c, width=max(1, w // 2))
    d.arc([cx - 0.75 * s, cy - 0.5 * s, cx + 0.75 * s, cy + 0.8 * s], 180, 360, fill=c, width=w)
    d.line([cx - 0.75 * s, cy + 0.15 * s, cx - 0.2 * s, cy + 0.6 * s], fill=c, width=w)
    d.line([cx + 0.75 * s, cy + 0.15 * s, cx + 0.2 * s, cy + 0.6 * s], fill=c, width=w)


def ic_casque(d, cx, cy, s, c):
    """Un casque de scaphandrier (le gros hublot)."""
    w = _w(s)
    d.ellipse([cx - 0.62 * s, cy - 0.66 * s, cx + 0.62 * s, cy + 0.5 * s], outline=c, width=w)
    d.ellipse([cx - 0.3 * s, cy - 0.32 * s, cx + 0.3 * s, cy + 0.22 * s], outline=c, width=w)
    d.rectangle([cx - 0.55 * s, cy + 0.5 * s, cx + 0.55 * s, cy + 0.7 * s], outline=c, width=w)
    for a in (0, 90, 180, 270):
        ra = math.radians(a)
        d.ellipse([cx + math.cos(ra) * 0.38 * s - 0.05 * s, cy - 0.05 * s + math.sin(ra) * 0.36 * s - 0.05 * s,
                   cx + math.cos(ra) * 0.38 * s + 0.05 * s, cy - 0.05 * s + math.sin(ra) * 0.36 * s + 0.05 * s], fill=c)


def ic_livre(d, cx, cy, s, c):
    w = _w(s)
    d.line([cx, cy - 0.4 * s, cx, cy + 0.55 * s], fill=c, width=w)
    d.polygon([(cx, cy - 0.4 * s), (cx - 0.7 * s, cy - 0.5 * s), (cx - 0.7 * s, cy + 0.45 * s), (cx, cy + 0.55 * s)], outline=c, width=w)
    d.polygon([(cx, cy - 0.4 * s), (cx + 0.7 * s, cy - 0.5 * s), (cx + 0.7 * s, cy + 0.45 * s), (cx, cy + 0.55 * s)], outline=c, width=w)
    for k in range(3):
        y = cy - 0.15 * s + k * 0.2 * s
        d.line([cx - 0.55 * s, y, cx - 0.15 * s, y + 0.03 * s], fill=c, width=max(1, w // 2))
        d.line([cx + 0.15 * s, y + 0.03 * s, cx + 0.55 * s, y], fill=c, width=max(1, w // 2))


def ic_vague(d, cx, cy, s, c):
    w = _w(s)
    for k in range(3):
        y = cy - 0.35 * s + k * 0.35 * s
        pts = [(cx - 0.75 * s + t * 1.5 * s, y + math.sin(t * TAU * 1.5) * 0.12 * s) for t in np.linspace(0, 1, 30)]
        d.line(pts, fill=c, width=w)


def ic_feuille(d, cx, cy, s, c):
    nu.ic_feuille(d, cx, cy, s, c)


def ic_meduse(d, cx, cy, s, c):
    w = _w(s)
    d.chord([cx - 0.6 * s, cy - 0.7 * s, cx + 0.6 * s, cy + 0.3 * s], 180, 360, outline=c, width=w)
    for k in range(5):
        x = cx - 0.45 * s + k * 0.225 * s
        pts = [(x + math.sin(t * TAU + k) * 0.08 * s, cy - 0.2 * s + t * 0.95 * s) for t in np.linspace(0, 1, 20)]
        d.line(pts, fill=c, width=max(1, w // 2 + 1))


def ic_poisson(d, cx, cy, s, c):
    w = _w(s)
    d.ellipse([cx - 0.65 * s, cy - 0.35 * s, cx + 0.35 * s, cy + 0.35 * s], outline=c, width=w)
    d.polygon([(cx + 0.3 * s, cy), (cx + 0.75 * s, cy - 0.35 * s), (cx + 0.75 * s, cy + 0.35 * s)], outline=c, width=w)
    d.ellipse([cx - 0.42 * s, cy - 0.12 * s, cx - 0.28 * s, cy + 0.02 * s], fill=c)


def ic_bathy(d, cx, cy, s, c):
    w = _w(s)
    d.ellipse([cx - 0.5 * s, cy - 0.45 * s, cx + 0.5 * s, cy + 0.45 * s], outline=c, width=w)
    d.ellipse([cx - 0.22 * s, cy - 0.2 * s, cx + 0.18 * s, cy + 0.2 * s], outline=c, width=w)
    d.line([cx, cy - 0.45 * s, cx, cy - 0.75 * s], fill=c, width=w)
    d.line([cx - 0.3 * s, cy + 0.42 * s, cx - 0.45 * s, cy + 0.7 * s], fill=c, width=w)
    d.line([cx + 0.3 * s, cy + 0.42 * s, cx + 0.45 * s, cy + 0.7 * s], fill=c, width=w)
    d.line([cx + 0.5 * s, cy, cx + 0.78 * s, cy], fill=c, width=w)


def ic_corail(d, cx, cy, s, c):
    w = _w(s)

    def br(x, y, a, ln, depth):
        if depth == 0 or ln < 0.06 * s:
            return
        x2, y2 = x + math.cos(a) * ln, y + math.sin(a) * ln
        d.line([x, y, x2, y2], fill=c, width=max(1, int(w * (0.5 + depth * 0.2))))
        br(x2, y2, a - 0.45, ln * 0.7, depth - 1)
        br(x2, y2, a + 0.4, ln * 0.68, depth - 1)

    br(cx, cy + 0.75 * s, -math.pi / 2, 0.45 * s, 4)


def ic_baleine(d, cx, cy, s, c):
    w = _w(s)
    d.chord([cx - 0.8 * s, cy - 0.45 * s, cx + 0.5 * s, cy + 0.4 * s], 170, 360, outline=c, width=w)
    d.line([cx - 0.78 * s, cy - 0.02 * s, cx + 0.5 * s, cy - 0.02 * s], fill=c, width=w)
    d.polygon([(cx + 0.45 * s, cy - 0.05 * s), (cx + 0.82 * s, cy - 0.4 * s), (cx + 0.7 * s, cy - 0.05 * s), (cx + 0.82 * s, cy + 0.25 * s)], outline=c, width=w)
    d.ellipse([cx - 0.52 * s, cy - 0.22 * s, cx - 0.42 * s, cy - 0.12 * s], fill=c)
    for k in range(3):
        d.arc([cx - 0.35 * s - k * 0.1 * s, cy - 0.85 * s - k * 0.1 * s, cx - 0.15 * s + k * 0.1 * s, cy - 0.6 * s + k * 0.1 * s], 200, 340, fill=c, width=max(1, w // 2))


ENSEIGNES = {
    "gare": ("Gare d'Azur", "Funiculaire d'Azur · Les Strates · Hautefond", ic_funi),
    "ligne": ("Funiculaire d'Azur", "Ligne du Dôme d'Azur · 140 m sous la mer", ic_funi),
    "conque": ("La Conque", "Cuisine de la mer · Soupes & galettes", ic_conque),
    "comptoir": ("Comptoir des Courants", "Tout ce qui flotte · et ce qui coule", ic_coquille),
    "atelier": ("Atelier des Scaphandres", "Réparations · Hublots · Pression", ic_casque),
    "ecole": ("École des Abysses", "Ici, on apprend le dessus", ic_livre),
    "conseil": ("Conseil des Marées", "Le Dôme d'Azur · Respirez bien !", ic_vague),
    "serres": ("Dôme des Serres", "Spiruline · Fruits · Fleurs", ic_feuille),
    "institut": ("Institut des Abysses", "Sciences de la mer profonde", ic_meduse),
    "aquarium": ("Grand Aquarium", "Ne tapez pas sur les vitres", ic_poisson),
    "bassin": ("Bassin des Bathyscaphes", "Le Petit Plongeon · Plongées", ic_bathy),
    "jardin": ("Jardin des Coraux", "Coraux lumineux · Ne pas toucher", ic_corail),
    "belvedere": ("Belvédère des Abysses", "Écoutez la Grande Chanteuse", ic_baleine),
}


def enseigne(key):
    title, sub, icon = ENSEIGNES[key]
    W, H, K = 512, 256, 3
    R = rng(11520 + sum(map(ord, key)))
    yy, xx = np.mgrid[0:H * K, 0:W * K].astype(np.float32)
    # une plaque de verre bleu nuit (un dégradé, un reflet doux en biais), cerclée de nacre
    sheen = np.clip(1.0 - np.abs((xx / (W * K)) * 0.8 + (yy / (H * K)) * 0.6 - 0.55) * 3.0, 0, 1) ** 2
    base = mix(C(0.03, 0.07, 0.12), C(0.05, 0.14, 0.22), (1.0 - yy / (H * K))[..., None] * 0.8)
    base = base + C(0.08, 0.12, 0.14) * sheen[..., None] * 0.6
    img = Image.fromarray((np.clip(base, 0, 1) * 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([5 * K, 5 * K, (W - 5) * K, (H - 5) * K], radius=26 * K, outline=(232, 234, 230), width=5 * K)
    d.rounded_rectangle([12 * K, 12 * K, (W - 12) * K, (H - 12) * K], radius=20 * K, outline=(90, 200, 215), width=1 * K)
    # le pictogramme dans un cercle aigue-marine (et son halo)
    cx, cy, rr = 90 * K, H * K / 2, 62 * K
    halo = Image.new("L", img.size, 0)
    ImageDraw.Draw(halo).ellipse([cx - rr - 10 * K, cy - rr - 10 * K, cx + rr + 10 * K, cy + rr + 10 * K], fill=150)
    halo = halo.filter(ImageFilter.GaussianBlur(14 * K))
    img = Image.composite(Image.new("RGB", img.size, (60, 200, 215)), img, halo)
    d = ImageDraw.Draw(img)
    d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=(36, 160, 178))
    d.ellipse([cx - rr + 4 * K, cy - rr + 4 * K, cx + rr - 4 * K, cy + rr - 4 * K], outline=(150, 230, 238), width=2 * K)
    icon(d, cx, cy, 58 * K, (240, 252, 255))
    # le nom (blanc qui luit), un filet aigue-marine, le sous-titre
    size1 = 44
    f1 = nu.font(int(size1 * K), "SemiBold")
    while d.textlength(title, font=f1) > 312 * K and size1 > 20:
        size1 -= 2
        f1 = nu.font(int(size1 * K), "SemiBold")
    size2 = 21
    f2 = nu.font(int(size2 * K), "Regular")
    while d.textlength(sub, font=f2) > 312 * K and size2 > 12:
        size2 -= 1
        f2 = nu.font(int(size2 * K), "Regular")
    glow = Image.new("L", img.size, 0)
    ImageDraw.Draw(glow).text((174 * K, 74 * K), title, fill=200, font=f1, anchor="lm", stroke_width=3 * K)
    glow = glow.filter(ImageFilter.GaussianBlur(5 * K))
    img = Image.composite(Image.new("RGB", img.size, (70, 190, 210)), img, glow)
    d = ImageDraw.Draw(img)
    d.text((174 * K, 74 * K), title, fill=(244, 252, 255), font=f1, anchor="lm")
    d.line([174 * K, 116 * K, 484 * K, 116 * K], fill=(90, 210, 220), width=3 * K)
    d.text((174 * K, 156 * K), sub, fill=(170, 220, 228), font=f2, anchor="lm")
    img = img.resize((W, H), Image.LANCZOS)
    gm.OUT = OUT
    gm.save_rgb(np.asarray(img, np.float32) / 255.0, "enseigne_" + key + ".png")


def enseignes():
    for k in ENSEIGNES:
        enseigne(k)


def strates():
    """L'enseigne de la Ligne du Dôme d'Azur, à la Gare des Strates : rouverte !"""
    import textures_strates_v114 as ts
    ts.ENSEIGNES["dome"] = ("Ligne du Dôme d'Azur", "Rouverte ! · Funiculaire d'Azur", "fer", (24, 56, 80), "creme", "colonne")
    gm.OUT = ts.OUT
    gm.ENSEIGNES.clear()
    gm.ENSEIGNES.update(ts.ENSEIGNES)
    gm.enseigne("dome")


# =================================================================== la vie du fond

def gorgone():
    """Une gorgone (un éventail de mer) vue de face, sur fond transparent : un tronc court, des branches
    qui se divisent en éventail, et entre elles un filet serré de rameaux soudés ; des polypes clairs.
    Gris clair (la matière le teinte). Entre les mailles, un voile à 35 % d'opacité : invisible de près
    (le seuil est à 50 %), il épaissit l'éventail de loin, quand les mailles se fondent."""
    W, H = 1024, 512
    K = 2
    R = rng(11502)
    ox, oy = W * K / 2, (H - 6) * K
    a_ax, b_ax = 0.47 * W * K, 0.9 * H * K

    def rmax(th):
        base = 0.86 + 0.07 * math.sin(th * 5.0 + 1.3) + 0.05 * math.sin(th * 11.0 + 0.4) + 0.03 * math.sin(th * 23.0)
        return base * (0.4 + 0.6 * math.sqrt(max(math.sin(th), 0.0)))

    def inside(x, y, m=1.0):
        dx, dy = (x - ox) / a_ax, (oy - y) / b_ax
        if dy < 0.02:
            return False
        return math.hypot(dx, dy) < rmax(math.atan2(dy, dx)) * m

    img = Image.new("RGBA", (W * K, H * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # le voile (sous le filet)
    poly = []
    for i in range(121):
        th = math.radians(4 + 172 * i / 120)
        rr = rmax(th) * 0.97
        poly.append((ox + math.cos(th) * rr * a_ax, oy - math.sin(th) * rr * b_ax))
    poly.append((ox, oy))
    d.polygon(poly, fill=(150, 150, 150, 90))
    segs = []

    def grow(x, y, ang, w, depth):
        while True:
            ln = (18 + R.random() * 12) * K
            nx, ny = x + math.cos(ang) * ln, y - math.sin(ang) * ln
            if not inside(nx, ny):
                return
            segs.append((x, y, nx, ny, w))
            x, y = nx, ny
            rad = math.atan2(oy - y, x - ox)
            ang = ang * 0.8 + rad * 0.2 + R.normal(0, 0.1)
            if R.random() < 0.2 and depth < 5:
                spr = 0.25 + R.random() * 0.25
                grow(x, y, ang + spr, max(w * 0.72, 2.6 * K), depth + 1)
                ang -= spr * 0.5
                w = max(w * 0.82, 2.6 * K)

    trunk_top = oy - 30 * K
    segs.append((ox, oy, ox, trunk_top, 13 * K))
    for k in range(7):
        grow(ox + R.normal(0, 3) * K, trunk_top, math.radians(14 + k * 25.3 + R.normal(0, 3)), 7.5 * K, 2)
    # le filet : des points à peu près réguliers (un tirage de Poisson, grille de hachage), reliés à
    # leurs plus proches voisins
    sp = 20 * K
    cs = sp / math.sqrt(2)
    grid = {}
    pts = []
    for _ in range(90000):
        x = ox + (R.random() * 2 - 1) * a_ax
        y = oy - R.random() * b_ax
        if not inside(x, y, 0.985):
            continue
        gx, gy = int(x / cs), int(y / cs)
        ok = True
        for ix in range(gx - 2, gx + 3):
            for iy in range(gy - 2, gy + 3):
                q = grid.get((ix, iy))
                if q is not None and (q[0] - x) ** 2 + (q[1] - y) ** 2 < sp * sp:
                    ok = False
                    break
            if not ok:
                break
        if ok:
            grid[(gx, gy)] = (x, y)
            pts.append((x, y))
    P_ = np.array(pts)
    for i, (x, y) in enumerate(pts):
        dd = np.hypot(P_[:, 0] - x, P_[:, 1] - y)
        order = np.argsort(dd)[1:4]
        for j in order:
            if dd[j] < sp * 1.6:
                d.line([x, y, P_[j, 0], P_[j, 1]], fill=(196, 196, 196, 255), width=int(2.6 * K))
    for (x0, y0, x1, y1, w) in segs:
        d.line([x0, y0, x1, y1], fill=(214, 214, 214, 255), width=int(w))
        d.ellipse([x1 - w / 2, y1 - w / 2, x1 + w / 2, y1 + w / 2], fill=(214, 214, 214, 255))
    # les polypes : de petits points clairs, sur les rameaux
    for _ in range(2600):
        if R.random() < 0.5 and segs:
            s0 = segs[R.integers(len(segs))]
            t = R.random()
            x, y = s0[0] + (s0[2] - s0[0]) * t, s0[1] + (s0[3] - s0[1]) * t
        else:
            x, y = pts[R.integers(len(pts))]
        r0 = (1.6 + R.random() * 1.2) * K
        d.ellipse([x - r0, y - r0, x + r0, y + r0], fill=(255, 250, 244, 255))
    img = img.resize((W, H), Image.LANCZOS)
    gm.OUT = OUT
    gm.save_rgba(img, "gorgone.png")


def eponge():
    """Le treillis d'une éponge de verre (une corbeille de Vénus) : une grille de baguettes de silice,
    croisées en diagonale dans chaque maille, et de grosses côtes en spirale. Raccordable (u : le tour ;
    v : la hauteur). Entre les baguettes, un voile à 35 % (voir gorgone())."""
    S = 512
    K = 2
    R = rng(11503)
    img = Image.new("RGBA", (S * K, S * K), (170, 166, 156, 88))
    d = ImageDraw.Draw(img)
    cell = 32 * K
    n = S * K // cell
    col = (226, 220, 206, 255)
    for i in range(n + 1):
        for off in (-S * K, 0, S * K):
            x = i * cell
            d.line([x, 0, x, S * K], fill=col, width=int(4.5 * K))
            d.line([0, x, S * K, x], fill=col, width=int(3.5 * K))
    for i in range(n):
        for j in range(n):
            x0, y0 = i * cell, j * cell
            d.line([x0, y0, x0 + cell, y0 + cell], fill=col, width=int(2.2 * K))
            d.line([x0 + cell, y0, x0, y0 + cell], fill=col, width=int(2.2 * K))
    # les côtes en spirale (raccordables : pente 1, période S)
    for k in range(4):
        x0 = k * S * K / 4
        for off in (-S * K, 0, S * K):
            d.line([x0 + off, 0, x0 + off + S * K, S * K], fill=(238, 233, 220, 255), width=int(7 * K))
    # des aspérités
    for _ in range(1400):
        x, y = R.random() * S * K, R.random() * S * K
        r0 = (1.2 + R.random()) * K
        d.ellipse([x - r0, y - r0, x + r0, y + r0], fill=(240, 236, 226, 255))
    img = img.resize((S, S), Image.LANCZOS)
    gm.OUT = OUT
    gm.save_rgba(img, "eponge.png")


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else ""
    OUT.mkdir(parents=True, exist_ok=True)
    if arg in ("", "terrazzo"):
        terrazzo()
    if arg in ("", "enseignes"):
        enseignes()
    if arg in ("", "strates"):
        strates()
    if arg in ("", "vie", "gorgone"):
        gorgone()
    if arg in ("", "vie", "eponge"):
        eponge()
    if arg in ENSEIGNES:
        enseigne(arg)


if __name__ == "__main__":
    main()
