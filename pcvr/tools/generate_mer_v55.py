"""V55 : textures de la mer — le fond marin, la vie sous-marine et l'Atlantide.

mer/        sable_fond.png (+_n)  : sable du fond, rides de courant, débris de coquilles ;
            roche_recif.png (+_n) : roche de récif encroûtée (algues calcaires roses, éponges) ;
            caustiques.png        : réseau lumineux des caustiques (gris, raccordable) ;
            algue.png             : une lame de laminaire (alpha) ;
            herbier.png           : touffe de posidonies (alpha) ;
            poissons.png          : 8 espèces de profil, 4 x 2 cases (alpha) ;
            bulle.png             : une bulle d'air (alpha) ;
            carapace.png          : écailles de carapace de tortue ;
            epave_bois.png (+_n)  : bordages de l'épave, bois gorgé d'eau ;
atlantide/  marbre.png (+_n)      : marbre blanc veiné de gris-bleu ;
            mosaique.png (+_n)    : mosaïque de sol, vagues turquoise et or ;
            cuivre_vert.png (+_n) : cuivre patiné (vert-de-gris) des toits et des dômes ;
            frise.png             : frise à la grecque (or sur bleu profond) ;
            fresque.png           : fresque du temple (la cité, la baleine, le cristal) ;
pnj/        atlante_turquoise.png, atlante_nacre.png, atlante_corail.png, atlante_abysse.png :
            vêtements des Atlantes (recoloration des tenues elfiques) ;
items/      masque_plongee, perle_lumiere, trident_marees, palmes_atlante, dent_requin, galette_algue.
Tout est dessiné ici (libre de droits).
Lancement depuis la racine du dépôt : python3 pcvr/tools/generate_mer_v55.py
"""
from pathlib import Path
import colorsys
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
TEX = ROOT / "www" / "assets" / "textures"
rng = np.random.default_rng(5555)

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_items_v28 as icons  # noqa: E402


# =================================================================== outils

def tile_noise(size, octaves=(8, 16, 32, 64, 128, 256), falloff=0.55):
    """Bruit fractal raccordable (0..1)."""
    acc = np.zeros((size, size), dtype=np.float32)
    amp, total = 1.0, 0.0
    for o in octaves:
        layer = rng.random((o, o)).astype(np.float32)
        big = Image.fromarray((np.tile(layer, (3, 3)) * 255).astype(np.uint8)).resize((size * 3, size * 3), Image.BICUBIC)
        acc += np.asarray(big, dtype=np.float32)[size:size * 2, size:size * 2] / 255.0 * amp
        total += amp
        amp *= falloff
    acc /= total
    return np.clip((acc - acc.mean()) * 1.8 + 0.5, 0, 1)


def normal_map(h, strength):
    gy, gx = np.gradient(h)
    n = np.dstack((-gx * strength, -gy * strength, np.ones_like(h)))
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    return Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8), "RGB")


def save_rgb(arr, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGB").save(path, optimize=True)
    print(path.relative_to(ROOT))


def save_rgba(arr, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA").save(path, optimize=True)
    print(path.relative_to(ROOT))


def save_img(img, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)
    print(path.relative_to(ROOT))


def wrap_dist(ax, ay, bx, by, size):
    dx = np.abs(ax - bx)
    dy = np.abs(ay - by)
    dx = np.minimum(dx, size - dx)
    dy = np.minimum(dy, size - dy)
    return np.sqrt(dx * dx + dy * dy)


def voronoi(size, n, seed_pts=None):
    """Distances aux deux germes les plus proches (raccordable) : (f1, f2, identifiant)."""
    pts = seed_pts if seed_pts is not None else rng.random((n, 2)) * size
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    f1 = np.full((size, size), 1e9, np.float32)
    f2 = np.full((size, size), 1e9, np.float32)
    ident = np.zeros((size, size), np.int32)
    for i, (px, py) in enumerate(pts):
        d = wrap_dist(xx, yy, px, py, size)
        closer = d < f1
        f2 = np.where(closer, f1, np.minimum(f2, d))
        ident = np.where(closer, i, ident)
        f1 = np.where(closer, d, f1)
    return f1, f2, ident


# =================================================================== fond marin

def sable_fond():
    size = 1024
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    warp = tile_noise(size, (4, 8, 16), 0.6)
    warp2 = tile_noise(size, (8, 16, 32), 0.5)
    # Rides de sable : ondulations asymétriques, déformées par le courant
    ph = (yy / size * 22.0 + warp * 3.2 + xx / size * 2.0) * math.pi * 2.0
    ripple = np.sin(ph) * 0.5 + 0.5
    ripple = ripple ** 1.6 * (0.75 + 0.25 * warp2)
    grain = tile_noise(size, (128, 256, 512), 0.7)
    h = ripple * 0.75 + grain * 0.25
    base = np.array([0.80, 0.74, 0.60])
    shade = 0.78 + 0.22 * h + (grain - 0.5) * 0.12
    col = base[None, None, :] * shade[..., None]
    # zones plus claires (sable corallien) et plus grises
    patch = tile_noise(size, (4, 8), 0.5)
    col = col * (0.92 + 0.12 * patch[..., None])
    col[..., 2] *= 0.97 + 0.04 * patch
    # débris : petits éclats de coquilles et grains sombres
    img = Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB")
    d = ImageDraw.Draw(img)
    for _ in range(900):
        x, y = rng.random(2) * size
        r = rng.uniform(1.0, 3.5)
        c = rng.choice([(236, 228, 214), (210, 196, 176), (120, 108, 92), (250, 236, 226), (205, 150, 140)])
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                if rng.random() < 0.5:
                    d.ellipse((x + ox - r, y + oy - r * 0.6, x + ox + r, y + oy + r * 0.6), fill=tuple(int(v) for v in c))
                else:
                    d.polygon([(x + ox, y + oy - r), (x + ox + r, y + oy + r * 0.5), (x + ox - r * 0.8, y + oy + r * 0.7)], fill=tuple(int(v) for v in c))
    img = img.filter(ImageFilter.GaussianBlur(0.5))
    save_img(img, TEX / "mer" / "sable_fond.png")
    normal_map(h, 7.0).save(TEX / "mer" / "sable_fond_n.png")


def roche_recif():
    size = 1024
    f1, f2, ident = voronoi(size, 70)
    edge = np.clip((f2 - f1) / 18.0, 0, 1)
    n = tile_noise(size)
    fine = tile_noise(size, (64, 128, 256, 512), 0.7)
    h = edge ** 0.5 * 0.2 + n * 0.55 + fine * 0.25
    base = np.array([0.42, 0.40, 0.36])
    shade = n * 0.65 + fine * 0.35
    col = base[None, None, :] * (0.6 + 0.55 * shade[..., None]) * (0.9 + 0.1 * edge[..., None] ** 0.5)
    # encroûtements d'algues calcaires (rose-mauve), éponges orangées, mousse verte
    crust = tile_noise(size, (8, 16, 32, 64), 0.6)
    pink = np.array([0.66, 0.46, 0.5])
    orange = np.array([0.72, 0.5, 0.3])
    green = np.array([0.30, 0.42, 0.26])
    m1 = np.clip((crust - 0.6) * 4.0, 0, 1)[..., None]
    col = col * (1 - m1 * 0.55) + pink[None, None, :] * (0.55 + 0.35 * fine[..., None]) * m1 * 0.55
    sp = tile_noise(size, (16, 32, 64), 0.5)
    m2 = np.clip((sp - 0.8) * 6.0, 0, 1)[..., None] * 0.7
    col = col * (1 - m2) + orange[None, None, :] * (0.6 + 0.3 * fine[..., None]) * m2
    gr = tile_noise(size, (8, 16), 0.5)
    m3 = np.clip((gr - 0.6) * 4.0, 0, 1)[..., None] * (1 - edge[..., None]) * 0.7
    col = col * (1 - m3) + green[None, None, :] * m3
    # petits trous (vers, oursins)
    holes = (rng.random((size, size)) < 0.0004).astype(np.float32)
    holes = np.asarray(Image.fromarray((holes * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(1.2)), np.float32) / 255.0
    col *= (1 - holes[..., None] * 0.45)
    save_rgb(col, TEX / "mer" / "roche_recif.png")
    normal_map(h - holes * 0.4 + m1[..., 0] * 0.15, 8.0).save(TEX / "mer" / "roche_recif_n.png")


def caustiques():
    size = 512
    acc = np.zeros((size, size), np.float32)
    for k, n in enumerate((26, 42)):
        f1, f2, _ = voronoi(size, n)
        line = np.exp(-((f2 - f1) / (2.2 + k)) ** 2)
        acc += line * (0.75 if k == 0 else 0.45)
    acc = np.asarray(Image.fromarray((np.clip(acc, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.4)), np.float32) / 255.0
    acc = np.clip(acc * 1.3, 0, 1)
    img = Image.fromarray((acc * 255).astype(np.uint8), "L").convert("RGB")
    save_img(img, TEX / "mer" / "caustiques.png")


def algue():
    w, h = 128, 512
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    v = yy / h                  # 0 en haut (pointe) .. 1 en bas (pied)
    u = (xx + 0.5) / w * 2 - 1
    # largeur de la lame : fine au pied, large au milieu, pointe arrondie, bord ondulé
    width = 0.25 + 0.7 * np.clip(np.sin(np.clip(1 - v, 0, 1) ** 0.8 * math.pi), 0, 1) ** 0.7
    width *= 1.0 + 0.08 * np.sin(v * 70.0)
    width = np.where(v > 0.92, 0.12, width)
    inside = np.abs(u) < width
    edge = np.clip((width - np.abs(u)) * 30.0, 0, 1)
    col = np.zeros((h, w, 4), np.float32)
    base = np.array([0.36, 0.3, 0.12])
    tip = np.array([0.62, 0.52, 0.2])
    mix = (1 - v)[..., None]
    c = base * (1 - mix) + tip * mix
    rib = np.exp(-(u / 0.06) ** 2) * 0.25
    wrinkle = 0.94 + 0.06 * np.sin(v * 140.0 + u * 6.0) + 0.05 * np.sin(v * 23.0 + u * 2.0)
    c = c * (wrinkle[..., None] + rib[..., None])
    col[..., :3] = c
    col[..., 3] = np.where(inside, edge, 0)
    save_rgba(col, TEX / "mer" / "algue.png")


def herbier():
    w, h = 256, 256
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for k in range(14):
        x0 = rng.uniform(40, 216)
        lean = rng.uniform(-50, 50)
        top = rng.uniform(10, 80)
        g = rng.uniform(0.75, 1.1)
        col = (int(70 * g), int(118 * g), int(52 * g), 255)
        pts = []
        steps = 12
        for s in range(steps + 1):
            f = s / steps
            x = x0 + lean * f * f
            y = h - f * (h - top)
            pts.append((x, y))
        for s in range(steps):
            wdt = 7.0 * (1 - s / steps * 0.6)
            p0, p1 = pts[s], pts[s + 1]
            icons.stick_polygon(d, p0, p1, wdt, col)
    img = img.filter(ImageFilter.GaussianBlur(0.6))
    save_img(img, TEX / "mer" / "herbier.png")


def _fish(d, box, body, belly, fin, pattern, eye_r=0.06):
    """Un poisson de profil (tête à droite) dans la case box = (x0, y0, x1, y1)."""
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    cx, cy = x0 + w * 0.47, y0 + h * 0.5
    bw, bh = w * 0.36, h * 0.30 * pattern.get("haut", 1.0)
    # queue
    tail = [(x0 + w * 0.13, cy), (x0 + w * 0.02, cy - h * 0.30), (x0 + w * 0.06, cy), (x0 + w * 0.02, cy + h * 0.30)]
    d.polygon(tail, fill=fin)
    # nageoires dorsale et anale
    d.polygon([(cx - bw * 0.5, cy - bh * 0.8), (cx - bw * 0.1, cy - bh * 1.55), (cx + bw * 0.35, cy - bh * 0.85)], fill=fin)
    d.polygon([(cx - bw * 0.45, cy + bh * 0.75), (cx - bw * 0.1, cy + bh * 1.35), (cx + bw * 0.15, cy + bh * 0.8)], fill=fin)
    # corps
    d.ellipse((cx - bw, cy - bh, cx + bw, cy + bh), fill=body)
    d.ellipse((cx - bw * 0.85, cy, cx + bw * 0.9, cy + bh * 0.95), fill=belly)
    # motifs
    for band in pattern.get("bandes", []):
        bx, bwid, bc = band
        d.rectangle((cx + bw * bx - bwid, cy - bh, cx + bw * bx + bwid, cy + bh), fill=bc)
    for spot in pattern.get("points", []):
        sx, sy, sr, sc = spot
        d.ellipse((cx + bw * sx - sr, cy + bh * sy - sr, cx + bw * sx + sr, cy + bh * sy + sr), fill=sc)
    if "ligne" in pattern:
        d.line([(cx - bw * 0.9, cy - bh * 0.05), (cx + bw * 0.85, cy - bh * 0.1)], fill=pattern["ligne"], width=max(2, int(h * 0.04)))
    # nageoire pectorale
    d.polygon([(cx + bw * 0.35, cy + bh * 0.1), (cx + bw * 0.05, cy + bh * 0.45), (cx + bw * 0.12, cy + bh * 0.05)], fill=fin)
    # opercule et œil
    d.arc((cx + bw * 0.3, cy - bh * 0.7, cx + bw * 0.75, cy + bh * 0.7), 120, 240, fill=(0, 0, 0, 90), width=3)
    er = h * eye_r
    ex, ey = cx + bw * 0.72, cy - bh * 0.22
    d.ellipse((ex - er, ey - er, ex + er, ey + er), fill=(245, 240, 220, 255))
    d.ellipse((ex - er * 0.6, ey - er * 0.6, ex + er * 0.6, ey + er * 0.6), fill=(15, 12, 10, 255))


def poissons():
    cw, ch = 256, 128
    img = Image.new("RGBA", (cw * 4, ch * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    species = [
        # poisson-clown : orange, bandes blanches liserées de noir
        dict(body=(240, 110, 20, 255), belly=(250, 140, 50, 255), fin=(235, 95, 15, 255),
             pattern={"bandes": [(-0.55, 10, (20, 20, 20, 255)), (-0.55, 7, (250, 250, 245, 255)), (0.1, 12, (20, 20, 20, 255)), (0.1, 9, (250, 250, 245, 255)), (0.62, 9, (20, 20, 20, 255)), (0.62, 6, (250, 250, 245, 255))], "haut": 1.1}),
        # chirurgien bleu : bleu roi, motif noir, queue jaune
        dict(body=(30, 80, 200, 255), belly=(45, 105, 215, 255), fin=(250, 210, 30, 255),
             pattern={"ligne": (15, 20, 40, 255), "haut": 1.15}),
        # demoiselle jaune
        dict(body=(250, 215, 40, 255), belly=(255, 235, 110, 255), fin=(245, 200, 30, 255), pattern={"haut": 1.2}),
        # sardine argentée : dos bleu, ventre argent
        dict(body=(70, 110, 140, 255), belly=(205, 215, 225, 255), fin=(150, 170, 185, 220), pattern={"haut": 0.65, "points": [(0.3, -0.35, 3, (30, 50, 70, 255)), (0.0, -0.35, 3, (30, 50, 70, 255))]}),
        # poisson-ange : bandes jaunes et bleues
        dict(body=(40, 60, 150, 255), belly=(60, 80, 170, 255), fin=(250, 200, 40, 255),
             pattern={"bandes": [(-0.6, 5, (250, 210, 50, 255)), (-0.25, 5, (250, 210, 50, 255)), (0.1, 5, (250, 210, 50, 255)), (0.45, 5, (250, 210, 50, 255))], "haut": 1.5}),
        # mérou tacheté
        dict(body=(120, 90, 60, 255), belly=(170, 140, 100, 255), fin=(100, 75, 50, 255),
             pattern={"points": [(rx, ry, 5, (70, 50, 35, 255)) for rx, ry in [(-0.6, -0.3), (-0.3, 0.2), (0.0, -0.4), (0.2, 0.3), (0.4, -0.1), (-0.1, 0.0), (-0.45, 0.45), (0.5, 0.45)]], "haut": 1.05}),
        # poisson-perroquet : vert et turquoise, écailles roses
        dict(body=(40, 170, 140, 255), belly=(90, 200, 190, 255), fin=(230, 110, 160, 255),
             pattern={"points": [(rx, ry, 4, (240, 130, 170, 255)) for rx, ry in [(-0.5, -0.2), (-0.2, 0.25), (0.1, -0.3), (0.35, 0.15), (-0.35, 0.5)]], "haut": 1.0}),
        # rouget : rose-rouge, ventre blanc, ligne dorée
        dict(body=(215, 90, 80, 255), belly=(245, 210, 200, 255), fin=(225, 120, 100, 230), pattern={"ligne": (245, 200, 80, 255), "haut": 0.85}),
    ]
    for i, s in enumerate(species):
        cx, cy = (i % 4) * cw, (i // 4) * ch
        _fish(d, (cx + 6, cy + 6, cx + cw - 6, cy + ch - 6), s["body"], s["belly"], s["fin"], s["pattern"])
    img = img.filter(ImageFilter.GaussianBlur(0.7))
    # léger reflet nacré sur le dos
    save_img(img, TEX / "mer" / "poissons.png")


def bulle():
    size = 64
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    u = (xx + 0.5) / size * 2 - 1
    v = (yy + 0.5) / size * 2 - 1
    r = np.sqrt(u * u + v * v)
    rim = np.exp(-((r - 0.86) / 0.08) ** 2)
    hi = np.exp(-(((u + 0.35) ** 2 + (v + 0.35) ** 2) / 0.02))
    a = np.clip(rim * 0.85 + hi * 0.95 + np.where(r < 0.86, 0.08, 0.0), 0, 1) * (r < 1.0)
    col = np.dstack([np.full_like(a, 0.9), np.full_like(a, 0.97), np.ones_like(a), a])
    save_rgba(col, TEX / "mer" / "bulle.png")


def carapace():
    size = 512
    pts = []
    for row in range(5):
        for colm in range(5):
            pts.append(((colm + 0.5 + (row % 2) * 0.5) * size / 5 + rng.uniform(-12, 12), (row + 0.5) * size / 5 + rng.uniform(-12, 12)))
    f1, f2, ident = voronoi(size, len(pts), np.array(pts))
    edge = np.clip((f2 - f1) / 10.0, 0, 1)
    # chaque écaille : rayons bruns et ambrés partant du centre
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    ang = np.zeros((size, size), np.float32)
    for i, (px, py) in enumerate(pts):
        m = ident == i
        ang[m] = np.arctan2(yy[m] - py, xx[m] - px)
    rays = 0.5 + 0.5 * np.sin(ang * 9.0 + tile_noise(size, (16, 32), 0.5) * 6.0)
    growth = 0.5 + 0.5 * np.sin(f1 * 0.35)
    dark = np.array([0.22, 0.15, 0.08])
    amber = np.array([0.62, 0.42, 0.18])
    t = (rays * 0.6 + growth * 0.4)[..., None]
    col = dark * (1 - t) + amber * t
    col *= (0.4 + 0.6 * edge[..., None])
    save_rgb(col, TEX / "mer" / "carapace.png")


def epave_bois():
    size = 1024
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    planks = 8
    pid = (yy / size * planks).astype(np.int32)
    v = (yy / size * planks) % 1.0
    groove = np.clip(np.minimum(v, 1 - v) * 40.0, 0, 1)
    grain_n = tile_noise(size, (8, 16, 32), 0.6)
    grain = 0.5 + 0.5 * np.sin((yy / size * 120.0 + grain_n * 10.0 + pid * 3.0))
    rot = tile_noise(size, (8, 16, 32, 64), 0.55)
    base = np.array([0.30, 0.26, 0.20])
    col = base[None, None, :] * (0.6 + 0.3 * grain[..., None] + 0.2 * rot[..., None])
    # algues et vase sur le bois, clous rouillés
    slime = np.clip((rot - 0.55) * 4.0, 0, 1)[..., None]
    col = col * (1 - slime * 0.7) + np.array([0.28, 0.33, 0.18]) * slime * 0.7
    col *= groove[..., None] * 0.6 + 0.4
    img = Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB")
    d = ImageDraw.Draw(img)
    for p in range(planks):
        for k in range(6):
            x = (k + 0.5 + (p % 2) * 0.5) * size / 6
            y = (p + 0.5) * size / planks
            d.ellipse((x - 5, y - 5, x + 5, y + 5), fill=(110, 60, 30))
    save_img(img, TEX / "mer" / "epave_bois.png")
    normal_map(grain * 0.3 + groove * 0.7 + rot * 0.2, 5.0).save(TEX / "mer" / "epave_bois_n.png")


# =================================================================== Atlantide

def marbre():
    size = 1024
    n = tile_noise(size, (4, 8, 16, 32, 64), 0.6)
    n2 = tile_noise(size, (8, 16, 32, 64, 128), 0.6)
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    # veines : bandes très fines d'un bruit turbulent
    t = (xx / size * 3.0 + yy / size * 2.0) * math.pi * 2 + n * 9.0
    vein = np.abs(np.sin(t))
    vein = np.clip(1 - vein / 0.05, 0, 1) * (0.5 + 0.5 * n2)
    t2 = (xx / size * 5.0 - yy / size * 3.0) * math.pi * 2 + n2 * 12.0
    vein2 = np.clip(1 - np.abs(np.sin(t2)) / 0.03, 0, 1) * 0.5
    base = np.array([0.93, 0.93, 0.91])
    col = base[None, None, :] * (0.93 + 0.07 * n[..., None])
    vc = np.array([0.55, 0.62, 0.68])
    m = np.clip(vein + vein2, 0, 1)[..., None] * 0.7
    col = col * (1 - m) + vc * m
    save_rgb(col, TEX / "atlantide" / "marbre.png")
    normal_map(n * 0.15 - m[..., 0] * 0.05, 2.0).save(TEX / "atlantide" / "marbre_n.png")


def mosaique():
    size = 1024
    tiles = 64
    cell = size // tiles
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    ty, tx = (yy // cell), (xx // cell)
    u = (xx % cell) / cell
    v = (yy % cell) / cell
    joint = np.clip(np.minimum(np.minimum(u, 1 - u), np.minimum(v, 1 - v)) * 10.0, 0, 1)
    # motif : vagues (sinus) or sur fond de turquoises variées, cercles concentriques
    cxn, cyn = (tx + 0.5) / tiles, (ty + 0.5) / tiles
    wave = np.sin(cxn * math.pi * 8.0) * 0.06
    band = ((cyn + wave) * 8.0) % 1.0
    gold = (band > 0.44) & (band < 0.56)
    deep = (band > 0.56) & (band < 0.7)
    jitter = rng.random((tiles, tiles)).astype(np.float32)
    jt = jitter[ty.astype(int) % tiles, tx.astype(int) % tiles]
    turq = np.array([0.15, 0.62, 0.66])
    pale = np.array([0.55, 0.82, 0.82])
    navy = np.array([0.07, 0.22, 0.38])
    gold_c = np.array([0.86, 0.68, 0.28])
    col = turq * (1 - jt[..., None]) + pale * jt[..., None] * 0.6 + turq * jt[..., None] * 0.4
    col = np.where(deep[..., None], navy * (0.8 + 0.4 * jt[..., None]), col)
    col = np.where(gold[..., None], gold_c * (0.85 + 0.3 * jt[..., None]), col)
    grout = np.array([0.82, 0.8, 0.74])
    col = col * joint[..., None] + grout * (1 - joint[..., None])
    col *= 0.92 + 0.08 * tile_noise(size, (16, 32, 64), 0.5)[..., None]
    save_rgb(col, TEX / "atlantide" / "mosaique.png")
    normal_map(joint * 0.6, 3.0).save(TEX / "atlantide" / "mosaique_n.png")


def cuivre_vert():
    size = 512
    n = tile_noise(size)
    n2 = tile_noise(size, (16, 32, 64, 128), 0.6)
    yy = np.mgrid[0:size, 0:size][0].astype(np.float32)
    seams = np.clip(np.abs(((yy / size) * 8.0 % 1.0) - 0.5) * 2.0 * 12.0 - 10.5, 0, 1)
    verd = np.array([0.30, 0.62, 0.52])
    copper = np.array([0.55, 0.32, 0.18])
    t = np.clip((n - 0.12) * 2.6, 0, 1)[..., None]
    col = verd * (0.8 + 0.3 * n2[..., None]) * t + copper * (1 - t)
    streak = np.clip((tile_noise(size, (32, 64), 0.5) - 0.5) * 3.0, 0, 1)[..., None] * 0.3
    col = col * (1 - streak) + np.array([0.6, 0.82, 0.74]) * streak
    col *= 1 - seams[..., None] * 0.35
    save_rgb(col, TEX / "atlantide" / "cuivre_vert.png")
    normal_map(n2 * 0.3 + seams * 0.5, 3.0).save(TEX / "atlantide" / "cuivre_vert_n.png")


def frise():
    w, h = 1024, 128
    img = Image.new("RGB", (w, h), (18, 44, 80))
    d = ImageDraw.Draw(img)
    gold = (222, 178, 80)
    d.rectangle((0, 0, w, 10), fill=gold)
    d.rectangle((0, h - 10, w, h), fill=gold)
    # vagues déferlantes (motif « vitruvien »)
    step = 128
    for k in range(w // step):
        x = k * step
        pts = []
        for s in range(41):
            f = s / 40
            ang = f * math.pi * 1.6
            r = 34 * (1 - f * 0.55)
            pts.append((x + 40 + math.cos(-ang + math.pi) * r * -1 + f * 70, 64 - math.sin(ang) * r))
        d.line(pts, fill=gold, width=12, joint="curve")
        d.line([(x, 96), (x + step, 96)], fill=gold, width=10)
    img = img.filter(ImageFilter.GaussianBlur(0.8))
    save_img(img, TEX / "atlantide" / "frise.png")


def fresque():
    w, h = 1024, 512
    img = Image.new("RGB", (w, h), (0, 0, 0))
    # fond : dégradé marin
    arr = np.zeros((h, w, 3), np.float32)
    v = np.linspace(0, 1, h)[:, None]
    top = np.array([0.22, 0.52, 0.62])
    bot = np.array([0.05, 0.18, 0.3])
    arr[:] = top * (1 - v[..., None]) + bot * v[..., None]
    img = Image.fromarray((arr * 255).astype(np.uint8), "RGB")
    d = ImageDraw.Draw(img)
    # rayons de lumière
    for k in range(6):
        x = 120 + k * 160
        d.polygon([(x, 0), (x + 40, 0), (x + 140, h), (x + 60, h)], fill=(70, 130, 150))
    # la baleine
    d.ellipse((560, 70, 940, 200), fill=(40, 60, 80))
    d.polygon([(560, 140), (480, 90), (500, 140), (480, 190)], fill=(40, 60, 80))
    d.ellipse((880, 120, 892, 132), fill=(230, 230, 220))
    d.chord((600, 140, 900, 215), 0, 180, fill=(200, 205, 200))
    # la cité sous le dôme
    d.chord((150, 210, 650, 650), 180, 360, fill=(120, 190, 200))
    d.chord((165, 225, 635, 640), 180, 360, fill=(30, 90, 110))
    for i, (x, hh) in enumerate([(230, 120), (290, 170), (360, 240), (430, 170), (500, 130), (560, 100)]):
        d.rectangle((x - 22, 430 - hh, x + 22, 430), fill=(230, 225, 210))
        d.chord((x - 26, 430 - hh - 26, x + 26, 430 - hh + 26), 180, 360, fill=(80, 160, 140))
    # le Grand Cristal au sommet
    d.polygon([(400, 190), (430, 240), (400, 300), (370, 240)], fill=(220, 250, 255))
    glow = Image.new("RGB", (w, h), (0, 0, 0))
    ImageDraw.Draw(glow).ellipse((330, 170, 470, 310), fill=(150, 240, 255))
    glow = glow.filter(ImageFilter.GaussianBlur(28))
    img = Image.fromarray(np.clip(np.asarray(img, np.float32) + np.asarray(glow, np.float32) * 0.6, 0, 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    # les trois perles
    for x, y in ((90, 440), (760, 420), (960, 460)):
        d.ellipse((x - 20, y - 20, x + 20, y + 20), fill=(250, 245, 230))
        d.ellipse((x - 10, y - 14, x - 2, y - 6), fill=(255, 255, 255))
    # vieillissement : craquelures et usure
    n = tile_noise(512, (8, 16, 32, 64), 0.6)
    n = np.asarray(Image.fromarray((n * 255).astype(np.uint8)).resize((w, h)), np.float32) / 255.0
    arr = np.asarray(img, np.float32) / 255.0
    arr = arr * (0.8 + 0.25 * n[..., None])
    worn = (n > 0.78)[..., None]
    arr = np.where(worn, arr * 0.4 + np.array([0.75, 0.72, 0.66]) * 0.6, arr)
    save_rgb(arr, TEX / "atlantide" / "fresque.png")


# =================================================================== tenues des Atlantes

def atlantes():
    src = Image.open(TEX / "elfes" / "elfe_azur.png").convert("RGB")
    a = np.asarray(src, np.float32) / 255.0
    hsv = np.zeros_like(a)
    flat = a.reshape(-1, 3)
    out_h = np.zeros(flat.shape[0], np.float32)
    out_s = np.zeros(flat.shape[0], np.float32)
    out_v = np.zeros(flat.shape[0], np.float32)
    mx = flat.max(axis=1)
    mn = flat.min(axis=1)
    out_v = mx
    out_s = np.where(mx > 1e-5, (mx - mn) / np.maximum(mx, 1e-5), 0)
    # teinte (vectorisée)
    r, g, b = flat[:, 0], flat[:, 1], flat[:, 2]
    d = np.maximum(mx - mn, 1e-6)
    hh = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) / 6.0
    out_h = np.where(mx - mn < 1e-6, 0, hh)
    cloth = (out_s > 0.28) & (out_v < 0.92)
    variants = {
        "atlante_turquoise": (0.47, 1.0, 1.15),
        "atlante_nacre": (0.12, 0.25, 1.9),
        "atlante_corail": (0.02, 0.85, 1.6),
        "atlante_abysse": (0.72, 0.9, 1.0),
    }
    for name, (hue, sat_k, val_k) in variants.items():
        nh = np.where(cloth, hue + (out_h - 0.6) * 0.15, out_h)
        ns = np.where(cloth, np.clip(out_s * sat_k, 0, 1), out_s)
        nv = np.where(cloth, np.clip(out_v * val_k, 0, 1), out_v)
        # hsv -> rgb (vectorisé)
        i = np.floor(nh * 6.0) % 6
        f = nh * 6.0 - np.floor(nh * 6.0)
        p = nv * (1 - ns)
        q = nv * (1 - f * ns)
        t = nv * (1 - (1 - f) * ns)
        rgb = np.zeros_like(flat)
        for k, (rr, gg, bb) in enumerate([(nv, t, p), (q, nv, p), (p, nv, t), (p, q, nv), (t, p, nv), (nv, p, q)]):
            m = i == k
            rgb[m, 0] = rr[m]
            rgb[m, 1] = gg[m]
            rgb[m, 2] = bb[m]
        save_rgb(rgb.reshape(a.shape), TEX / "pnj" / f"{name}.png")


# =================================================================== icônes

def icon_masque():
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    # sangle
    d.arc((40, 120, 472, 420), 200, 340, fill=(30, 30, 35, 255), width=30)
    # jupe de caoutchouc noir, deux verres trempés dans du laiton
    d.rounded_rectangle((70, 170, 442, 380), radius=90, fill=(25, 28, 32, 255))
    for x0 in (95, 265):
        d.rounded_rectangle((x0, 195, x0 + 152, 345), radius=60, fill=(190, 150, 70, 255))
        d.rounded_rectangle((x0 + 14, 209, x0 + 138, 331), radius=50, fill=(70, 150, 190, 255))
        d.polygon([(x0 + 30, 225), (x0 + 75, 225), (x0 + 40, 300)], fill=(200, 235, 250, 200))
    d.polygon([(220, 330), (292, 330), (276, 400), (236, 400)], fill=(25, 28, 32, 255))
    icons.save(img, "masque_plongee")


def icon_perle():
    img = icons.canvas()
    glow = Image.new("RGBA", img.size, (120, 230, 255, 0))
    ImageDraw.Draw(glow).ellipse((70, 70, 442, 442), fill=(120, 230, 255, 110))
    glow = glow.filter(ImageFilter.GaussianBlur(40))
    img.alpha_composite(glow)
    icons.shaded_ellipse(img, (136, 136, 376, 376), (238, 246, 252))
    d = ImageDraw.Draw(img)
    d.ellipse((190, 175, 245, 225), fill=(255, 255, 255, 230))
    icons.save(img, "perle_lumiere")


def icon_trident():
    tri = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    d = ImageDraw.Draw(tri)
    gold = (226, 182, 70, 255)
    dark = (170, 128, 45, 255)
    d.rectangle((244, 190, 268, 500), fill=gold)
    d.rectangle((262, 190, 268, 500), fill=dark)
    d.rounded_rectangle((170, 170, 342, 196), radius=12, fill=gold)
    for x in (182, 256, 330):
        top = 40 if x == 256 else 70
        d.rectangle((x - 10, top + 30, x + 10, 185), fill=gold)
        d.polygon([(x - 22, top + 40), (x, top), (x + 22, top + 40)], fill=gold)
    d.rectangle((236, 300, 276, 330), fill=(40, 90, 120, 255))
    tri = tri.rotate(-35, resample=Image.BICUBIC)
    img = icons.canvas()
    img.alpha_composite(tri)
    icons.shaded_ellipse(img, (226, 150, 286, 210), (110, 220, 240))
    icons.save(img, "trident_marees")


def icon_palmes():
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    for x0, c in ((90, (40, 150, 160, 255)), (270, (30, 130, 145, 255))):
        d.polygon([(x0 + 30, 120), (x0 + 120, 120), (x0 + 160, 440), (x0 + 75, 480), (x0 - 10, 440)], fill=c)
        d.rounded_rectangle((x0 + 20, 90, x0 + 130, 200), radius=40, fill=(25, 60, 70, 255))
        for k in range(3):
            d.line([(x0 + 50 + k * 25, 210), (x0 + 30 + k * 45, 450)], fill=(220, 190, 90, 255), width=6)
    icons.save(img, "palmes_atlante")


def icon_dent():
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.polygon([(150, 400), (256, 70), (362, 400), (300, 440), (212, 440)], fill=(240, 236, 222, 255))
    d.polygon([(256, 70), (300, 400), (362, 400)], fill=(205, 198, 182, 255))
    for k in range(9):
        y = 380 - k * 32
        d.line([(256 - (380 - y) * 0.25, y), (256 - (380 - y) * 0.25 - 8, y - 8)], fill=(170, 160, 140, 255), width=4)
    d.rectangle((170, 420, 342, 470), fill=(140, 96, 60, 255))
    icons.save(img, "dent_requin")


def icon_galette():
    img = icons.canvas()
    icons.shaded_ellipse(img, (80, 150, 432, 400), (88, 108, 48), gloss=False)
    d = ImageDraw.Draw(img)
    for _ in range(60):
        x, y = rng.uniform(120, 390), rng.uniform(190, 360)
        d.line([(x, y), (x + rng.uniform(-30, 30), y + rng.uniform(-8, 8))], fill=(50, 70, 28, 255), width=5)
    icons.save(img, "galette_algue")


if __name__ == "__main__":
    sable_fond()
    roche_recif()
    caustiques()
    algue()
    herbier()
    poissons()
    bulle()
    carapace()
    epave_bois()
    marbre()
    mosaique()
    cuivre_vert()
    frise()
    fresque()
    atlantes()
    icon_masque()
    icon_perle()
    icon_trident()
    icon_palmes()
    icon_dent()
    icon_galette()
