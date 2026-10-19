"""V54 : textures du ciel — l'aigle géant Ventaile, l'île flottante et la Citadelle des Nuées.

aigle/  plumage.png (+_n) : plumes de couverture du corps, en écailles, brun et or ;
        remige.png        : une grande plume de vol (rachis, barbes, pointe sombre), avec alpha ;
        couverture.png    : une plume de couverture d'aile (plus courte, arrondie), avec alpha ;
        tete.png          : nuque dorée (aigle royal) ;
chateau/ pierre_chateau.png (+_n) : grand appareil de calcaire clair, coulures, mousse aux joints ;
        dalles_chateau.png (+_n) : dallage de la cour ;
        ardoise.png (+_n) : toits d'ardoise ;
        banniere.png      : bannière bleu nuit, aigle d'argent ;
        vitrail.png       : vitrail en ogive (alpha hors de l'ogive) ;
        tapis.png         : tapis rouge et or de la grande salle ;
ciel/   nuage.png         : une bouffée de nuage (alpha) ;
        roche_ciel.png (+_n) : roche feuilletée du dessous de l'île, veinée de cristaux bleus.
items/  plume_ventaile, cristal_levant, cristal_couchant, couronne_nuees, epee_nuees, selle_aigle.
Tout est dessiné ici (libre de droits).
Lancement depuis la racine du dépôt : python3 pcvr/tools/generate_ciel_v54.py
"""
from pathlib import Path
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
TEX = ROOT / "www" / "assets" / "textures"
rng = np.random.default_rng(5454)

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


def blocks(size, rows, min_w, max_w, groove, jitter_rows=False):
    """Appareil de blocs : (relief 0..1, teinte par bloc, identifiant de bloc)."""
    height = np.ones((size, size), dtype=np.float32)
    shade = np.ones((size, size), dtype=np.float32)
    ident = np.zeros((size, size), dtype=np.float32)
    yy, xx = np.mgrid[0:size, 0:size]
    row_h = size // rows
    bid = 0
    for r in range(rows):
        y0 = r * row_h
        x = int(rng.integers(0, max_w)) - max_w
        while x < size:
            w = int(rng.integers(min_w, max_w))
            k = 0.86 + rng.random() * 0.24
            bid += 1
            for xs in (x, x - size, x + size):
                xa, xb = max(xs, 0), min(xs + w, size)
                if xa >= xb:
                    continue
                sl = (slice(y0, y0 + row_h), slice(xa, xb))
                shade[sl] = k
                ident[sl] = (bid * 0.6180339) % 1.0
                dx = np.minimum(xx[sl] - xs, xs + w - xx[sl])
                dy = np.minimum(yy[sl] - y0, y0 + row_h - yy[sl])
                d = np.minimum(dx, dy).astype(np.float32)
                height[sl] = np.clip(d / (groove * 2.5), 0, 1) ** 0.55
            x += w
    return height, shade, ident


# =================================================================== château

def pierre_chateau():
    size = 1024
    h, shade, ident = blocks(size, 6, 150, 330, 9)
    grain = tile_noise(size)
    fine = tile_noise(size, (64, 128, 256, 512), 0.6)
    base = np.array([0.86, 0.82, 0.74], dtype=np.float32)
    col = base[None, None, :] * (0.78 + 0.32 * grain[..., None]) * shade[..., None]
    # Grain de calcaire (petits trous et fossiles), pierres un peu plus chaudes ou plus grises
    warm = (ident > 0.7)[..., None]
    col = np.where(warm, col * np.array([1.03, 0.98, 0.9]), col)
    cold = (ident < 0.18)[..., None]
    col = np.where(cold, col * np.array([0.93, 0.95, 0.97]), col)
    pits = (fine < 0.18)[..., None]
    col = np.where(pits, col * 0.82, col)
    # Coulures verticales sous les joints (pluie) : bandes sombres floues
    streak = np.zeros((size, size), dtype=np.float32)
    for _ in range(60):
        x = int(rng.integers(0, size))
        y = int(rng.integers(0, size))
        length = int(rng.integers(60, 260))
        w = int(rng.integers(2, 7))
        streak[y:y + length, max(0, x - w):x + w] += rng.random() * 0.5
    streak = np.asarray(Image.fromarray((np.clip(streak, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(5)), dtype=np.float32) / 255.0
    col *= (1.0 - 0.22 * streak[..., None])
    # Joints : mortier gris, mousse verte par endroits
    joint = (h < 0.3)[..., None]
    moss = (grain > 0.62)[..., None] & joint
    col = np.where(joint, col * 0.55 + np.array([0.18, 0.17, 0.15]) * 0.3, col)
    col = np.where(moss, np.array([0.24, 0.32, 0.16]) * (0.7 + 0.5 * fine[..., None]), col)
    col *= (0.82 + 0.18 * h[..., None])
    save_rgb(col, TEX / "chateau" / "pierre_chateau.png")
    normal_map(h + fine * 0.18 + grain * 0.08, 7.0).save(TEX / "chateau" / "pierre_chateau_n.png")


def dalles_chateau():
    size = 1024
    h, shade, ident = blocks(size, 4, 200, 300, 7)
    grain = tile_noise(size)
    fine = tile_noise(size, (64, 128, 256, 512), 0.6)
    base = np.array([0.66, 0.66, 0.65], dtype=np.float32)
    col = base[None, None, :] * (0.75 + 0.35 * grain[..., None]) * shade[..., None]
    col = np.where((ident > 0.75)[..., None], col * np.array([1.02, 0.98, 0.92]), col)
    # usure : centre des dalles plus clair et lisse, petites fissures
    col *= (0.86 + 0.16 * h[..., None])
    joint = (h < 0.3)[..., None]
    col = np.where(joint, np.array([0.22, 0.24, 0.17]) * (0.6 + 0.6 * fine[..., None]), col)
    save_rgb(col, TEX / "chateau" / "dalles_chateau.png")
    normal_map(h + fine * 0.12, 6.0).save(TEX / "chateau" / "dalles_chateau_n.png")


def ardoise():
    size = 1024
    rows = 16
    row_h = size // rows
    col = np.zeros((size, size, 3), dtype=np.float32)
    h = np.zeros((size, size), dtype=np.float32)
    yy, xx = np.mgrid[0:size, 0:size]
    grain = tile_noise(size, (16, 32, 64, 128, 256), 0.6)
    for r in range(rows):
        y0 = r * row_h
        off = (r % 2) * 32
        x = -off
        while x < size:
            w = int(rng.integers(52, 76))
            tone = np.array([0.24, 0.27, 0.32]) * (0.75 + rng.random() * 0.45)
            if rng.random() < 0.12:
                tone = tone * np.array([1.1, 1.05, 0.9])
            for xs in (x, x + size):
                xa, xb = max(xs, 0), min(xs + w - 3, size)
                if xa >= xb:
                    continue
                sl = (slice(y0, y0 + row_h), slice(xa, xb))
                # chaque ardoise : plus épaisse en bas (recouvrement), bord inférieur arrondi
                t = (yy[sl] - y0) / row_h
                col[sl] = tone * (0.75 + 0.35 * t[..., None])
                h[sl] = t
            x += w
    col *= (0.8 + 0.35 * grain[..., None])
    lichen = (grain > 0.86)[..., None]
    col = np.where(lichen, col * 0.8 + np.array([0.5, 0.5, 0.36]) * 0.2, col)
    save_rgb(col, TEX / "chateau" / "ardoise.png")
    normal_map(h + grain * 0.1, 5.0).save(TEX / "chateau" / "ardoise_n.png")


def _eagle_emblem(d, cx, cy, s, fill):
    """Un aigle héraldique aux ailes déployées."""
    pts = []
    for side in (-1, 1):
        wing = [(cx, cy - 0.05 * s), (cx + side * 0.18 * s, cy - 0.35 * s), (cx + side * 0.48 * s, cy - 0.42 * s),
                (cx + side * 0.42 * s, cy - 0.28 * s), (cx + side * 0.52 * s, cy - 0.22 * s), (cx + side * 0.4 * s, cy - 0.12 * s),
                (cx + side * 0.46 * s, cy - 0.04 * s), (cx + side * 0.3 * s, cy + 0.02 * s), (cx + side * 0.12 * s, cy + 0.08 * s)]
        d.polygon(wing, fill=fill)
    d.ellipse((cx - 0.11 * s, cy - 0.18 * s, cx + 0.11 * s, cy + 0.22 * s), fill=fill)
    d.ellipse((cx - 0.07 * s, cy - 0.34 * s, cx + 0.07 * s, cy - 0.18 * s), fill=fill)
    d.polygon([(cx + 0.05 * s, cy - 0.3 * s), (cx + 0.14 * s, cy - 0.27 * s), (cx + 0.05 * s, cy - 0.24 * s)], fill=fill)
    d.polygon([(cx - 0.12 * s, cy + 0.2 * s), (cx, cy + 0.42 * s), (cx + 0.12 * s, cy + 0.2 * s)], fill=fill)
    return pts


def banniere():
    w, h = 512, 1024
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # pointe en queue d'aronde en bas
    d.polygon([(0, 0), (w, 0), (w, h), (w // 2, h - 150), (0, h)], fill=(22, 36, 82, 255))
    gold = (214, 172, 74, 255)
    d.line([(14, 0), (14, h - 10)], fill=gold, width=12)
    d.line([(w - 14, 0), (w - 14, h - 10)], fill=gold, width=12)
    d.line([(0, 30), (w, 30)], fill=gold, width=14)
    _eagle_emblem(d, w // 2, 430, 420, (226, 230, 236, 255))
    for k in range(5):
        x = 90 + k * 83
        d.ellipse((x - 14, 760, x + 14, 788), fill=gold)
    arr = np.asarray(img, dtype=np.float32) / 255.0
    # plis du tissu : bandes verticales d'ombre et de lumière, et trame
    xs = np.arange(w, dtype=np.float32)
    fold = 0.86 + 0.14 * np.sin(xs / w * math.pi * 5.0 + 0.6) + 0.05 * np.sin(xs / w * math.pi * 13.0)
    weave = tile_noise(512, (128, 256, 512), 0.7)
    weave = np.asarray(Image.fromarray((weave * 255).astype(np.uint8)).resize((w, h)), dtype=np.float32) / 255.0
    arr[..., :3] *= fold[None, :, None] * (0.9 + 0.12 * weave[..., None])
    save_rgba(arr, TEX / "chateau" / "banniere.png")


def vitrail():
    w, h = 512, 1024
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    md.rectangle((0, 260, w, h), fill=255)
    md.pieslice((-w * 0.5, 0, w * 1.0, 520), 270, 360, fill=255)
    md.pieslice((0, 0, w * 1.5, 520), 180, 270, fill=255)
    md.rectangle((0, 0, w, 255), fill=0)
    # Ogive : intersection de deux arcs
    ogive = Image.new("L", (w, h), 0)
    od = ImageDraw.Draw(ogive)
    od.ellipse((-w * 0.5, 0, w * 1.5, 1000), fill=255)
    od2 = Image.new("L", (w, h), 0)
    ImageDraw.Draw(od2).ellipse((-w * 1.0, 0, w * 1.0, 1000), fill=255)
    od3 = Image.new("L", (w, h), 0)
    ImageDraw.Draw(od3).ellipse((0, 0, w * 2.0, 1000), fill=255)
    top = np.minimum(np.asarray(od2), np.asarray(od3))
    m = np.asarray(mask).copy()
    m[:300] = top[:300]
    m[300:] = 255
    palette = [(40, 70, 170), (190, 40, 50), (230, 180, 60), (40, 140, 90), (120, 60, 160), (60, 150, 210)]
    cells = 0
    for y in range(0, h, 72):
        for x in range(0, w, 64):
            c = palette[int(rng.integers(0, len(palette)))]
            j = (y // 72) % 2 * 32
            d.polygon([(x + j - 32, y), (x + j + 32, y), (x + j + 40, y + 72), (x + j - 24, y + 72)], fill=c + (255,))
            cells += 1
    # le grand médaillon central : l'aigle d'or sur bleu
    d.ellipse((96, 380, 416, 700), fill=(30, 50, 140, 255))
    _eagle_emblem(d, 256, 560, 300, (240, 200, 80, 255))
    # plombs
    lead = (24, 22, 20, 255)
    for y in range(0, h, 72):
        d.line([(0, y), (w, y)], fill=lead, width=6)
    for y in range(0, h, 72):
        j = (y // 72) % 2 * 32
        for x in range(0, w + 64, 64):
            d.line([(x + j - 32, y), (x + j - 24, y + 72)], fill=lead, width=6)
    d.ellipse((96, 380, 416, 700), outline=lead, width=10)
    arr = np.asarray(img, dtype=np.float32) / 255.0
    glass = tile_noise(512, (32, 64, 128), 0.6)
    glass = np.asarray(Image.fromarray((glass * 255).astype(np.uint8)).resize((w, h)), dtype=np.float32) / 255.0
    arr[..., :3] *= 0.78 + 0.35 * glass[..., None]
    alpha = (m.astype(np.float32) / 255.0)
    # cadre de pierre
    edge = np.asarray(Image.fromarray(m).filter(ImageFilter.MinFilter(15)), dtype=np.float32) / 255.0
    frame = (alpha > 0.5) & (edge < 0.5)
    arr[frame, :3] = np.array([0.62, 0.6, 0.55])
    arr[..., 3] = alpha
    save_rgba(arr, TEX / "chateau" / "vitrail.png")


def tapis():
    w, h = 512, 1024
    img = Image.new("RGB", (w, h), (120, 18, 24))
    d = ImageDraw.Draw(img)
    gold = (196, 150, 60)
    d.rectangle((24, 0, 48, h), fill=gold)
    d.rectangle((w - 48, 0, w - 24, h), fill=gold)
    for y in range(0, h, 128):
        cx, cy = w // 2, y + 64
        d.polygon([(cx, cy - 46), (cx + 46, cy), (cx, cy + 46), (cx - 46, cy)], outline=gold, width=8)
        d.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=gold)
        for sx in (-1, 1):
            d.line([(cx + sx * 120, cy - 30), (cx + sx * 150, cy), (cx + sx * 120, cy + 30)], fill=gold, width=6)
    arr = np.asarray(img, dtype=np.float32) / 255.0
    pile = tile_noise(512, (64, 128, 256, 512), 0.7)
    pile = np.asarray(Image.fromarray((pile * 255).astype(np.uint8)).resize((w, h)), dtype=np.float32) / 255.0
    arr *= 0.82 + 0.25 * pile[..., None]
    save_rgb(arr, TEX / "chateau" / "tapis.png")


# =================================================================== aigle

def plumage():
    """Plumes de couverture en écailles : chaque plume a un liseré clair et un cœur sombre."""
    size = 1024
    col = np.zeros((size, size, 3), dtype=np.float32)
    h = np.zeros((size, size), dtype=np.float32)
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    rows = 14
    row_h = size / rows
    fw = 82.0
    order = []
    for r in range(rows + 2):
        for c in range(int(size / fw) + 2):
            cx = c * fw + (r % 2) * fw * 0.5 + rng.uniform(-6, 6)
            cy = r * row_h + rng.uniform(-4, 4)
            order.append((cy, cx))
    # on peint du haut vers le bas : la plume du dessous recouvre (écailles)
    for cy, cx in sorted(order):
        tone = 0.82 + rng.random() * 0.3
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                x0, y0 = cx + ox, cy + oy
                xa, xb = int(max(x0 - fw * 0.62, 0)), int(min(x0 + fw * 0.62, size))
                ya, yb = int(max(y0 - row_h * 0.2, 0)), int(min(y0 + row_h * 1.65, size))
                if xa >= xb or ya >= yb:
                    continue
                sl = (slice(ya, yb), slice(xa, xb))
                u = (xx[sl] - x0) / (fw * 0.6)
                v = (yy[sl] - y0) / (row_h * 1.6)
                inside = (u * u + (v - 0.25) ** 2 * 1.4 < 1.0) & (v > -0.1)
                if not inside.any():
                    continue
                edge = 1.0 - (u * u + (v - 0.25) ** 2 * 1.4)
                rim = np.clip(1.0 - edge * 4.0, 0, 1)            # liseré clair au bord
                shaft = np.exp(-(u * 14.0) ** 2) * 0.25           # rachis
                dark = np.array([0.26, 0.17, 0.1]) * tone
                fringe = np.array([0.62, 0.44, 0.22]) * tone
                c = dark[None, None, :] * (1 - rim[..., None]) + fringe[None, None, :] * rim[..., None]
                c = c * (1.0 - shaft[..., None] * 0.5)
                # barbes : fines stries obliques
                barb = 0.92 + 0.08 * np.sin((u * 40.0 + v * 22.0 * np.sign(u + 1e-6)))
                c = c * barb[..., None]
                col[sl] = np.where(inside[..., None], c, col[sl])
                h[sl] = np.where(inside, 0.35 + 0.65 * np.clip(edge, 0, 1) ** 0.5 + v * 0.2, h[sl])
    save_rgb(col, TEX / "aigle" / "plumage.png")
    normal_map(h, 3.5).save(TEX / "aigle" / "plumage_n.png")


def tete():
    """La nuque dorée de l'aigle royal : plumes fines lancéolées, or fauve."""
    size = 512
    col = np.zeros((size, size, 3), dtype=np.float32)
    base = tile_noise(size, (16, 32, 64, 128, 256), 0.65)
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    streaks = np.sin(xx / size * math.pi * 90 + base * 6.0) * 0.5 + 0.5
    gold = np.array([0.72, 0.52, 0.22])
    brown = np.array([0.32, 0.2, 0.1])
    t = np.clip(yy / size * 1.3 - 0.15 + (base - 0.5) * 0.4, 0, 1)
    col = gold[None, None, :] * (1 - t[..., None]) + brown[None, None, :] * t[..., None]
    col *= (0.8 + 0.25 * streaks[..., None])
    save_rgb(col, TEX / "aigle" / "tete.png")


def _feather(w, h, dark_tip, base_col, tip_col, bands, round_tip=False, seed=0):
    """Une plume vue de dessus, alpha hors de la plume. Rachis au milieu, barbes obliques."""
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    v = yy / h                    # 0 = pointe, 1 = base (calamus)
    u = (xx - w * 0.5) / (w * 0.5)
    # Contour : vexille étroite côté avant (gauche), large côté arrière (droit), pointe effilée
    width_r = np.where(u >= 0, 0.92, 0.55)
    prof = np.clip(np.sin(np.clip(v, 0, 1) * math.pi * 0.5 + 0.08) ** (0.55 if round_tip else 0.9), 0, 1)
    prof *= np.clip((1.0 - v) * 6.0, 0, 1) ** 0.0 * np.clip((1.02 - v) * 12.0, 0, 1)
    halfw = width_r * prof
    inside = np.abs(u) < halfw
    edge = np.clip((halfw - np.abs(u)) * 12.0, 0, 1)
    # Barbes : stries obliques qui partent du rachis vers la pointe
    ang = np.abs(u) * 6.0 + v * 70.0
    barbs = 0.88 + 0.12 * np.sin(ang * 3.0)
    # Petites séparations des barbes (encoches) près du bord
    nr = np.random.default_rng(seed)
    gaps = np.ones_like(u)
    for _ in range(6):
        gv = nr.uniform(0.15, 0.85)
        gaps *= 1.0 - 0.9 * np.exp(-((v - gv - np.abs(u) * 0.18) * 160.0) ** 2) * (np.abs(u) > halfw * 0.35)
    t_tip = np.clip((dark_tip - v) / max(dark_tip, 1e-3), 0, 1) if dark_tip > 0 else np.zeros_like(v)
    c = np.array(base_col)[None, None, :] * (1 - t_tip[..., None]) + np.array(tip_col)[None, None, :] * t_tip[..., None]
    if bands > 0:
        band = 0.5 + 0.5 * np.sin(v * math.pi * bands * 2.0 + u * 0.8)
        c = c * (0.82 + 0.22 * band[..., None])
    c = c * barbs[..., None]
    # Rachis clair
    rach = np.exp(-(u / 0.035) ** 2) * (v > 0.02)
    c = c * (1 - rach[..., None] * 0.6) + np.array([0.75, 0.68, 0.55]) * rach[..., None] * 0.6
    # Calamus nu à la base
    cal = (v > 0.9) & (np.abs(u) < 0.06)
    alpha = np.where(inside, edge * gaps, 0.0)
    alpha = np.maximum(alpha, cal.astype(np.float32))
    rgba = np.zeros((h, w, 4), dtype=np.float32)
    rgba[..., :3] = np.clip(c, 0, 1)
    rgba[..., 3] = np.clip(alpha, 0, 1)
    return rgba


def remiges():
    rem = _feather(192, 1024, 0.35, (0.24, 0.17, 0.11), (0.07, 0.06, 0.05), 5, seed=1)
    save_rgba(rem, TEX / "aigle" / "remige.png")
    cov = _feather(192, 512, 0.0, (0.3, 0.2, 0.12), (0.3, 0.2, 0.12), 0, round_tip=True, seed=2)
    save_rgba(cov, TEX / "aigle" / "couverture.png")
    queue = _feather(192, 768, 0.22, (0.36, 0.3, 0.24), (0.12, 0.1, 0.08), 4, round_tip=True, seed=3)
    save_rgba(queue, TEX / "aigle" / "rectrice.png")


# =================================================================== ciel

def nuage():
    size = 512
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    acc = np.zeros((size, size), dtype=np.float32)
    for _ in range(26):
        cx = rng.uniform(0.25, 0.75) * size
        cy = rng.uniform(0.35, 0.7) * size
        r = rng.uniform(0.08, 0.2) * size
        acc = np.maximum(acc, np.clip(1.0 - ((xx - cx) ** 2 + (yy - cy) ** 2) / (r * r), 0, 1))
    n = tile_noise(size, (8, 16, 32, 64), 0.6)
    a = np.clip(acc * (0.6 + 0.6 * n) * 1.4 - 0.15, 0, 1)
    a = np.asarray(Image.fromarray((a * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(10)), dtype=np.float32) / 255.0
    # dessous légèrement gris (ombre propre), dessus blanc
    shade = 0.78 + 0.22 * np.clip(1.0 - yy / size * 1.2, 0, 1)
    rgba = np.zeros((size, size, 4), dtype=np.float32)
    rgba[..., 0] = shade
    rgba[..., 1] = shade * 1.0
    rgba[..., 2] = shade * 1.03
    rgba[..., 3] = a
    save_rgba(rgba, TEX / "ciel" / "nuage.png")


def roche_ciel():
    size = 1024
    n = tile_noise(size)
    fine = tile_noise(size, (64, 128, 256, 512), 0.6)
    yy = np.mgrid[0:size, 0:size][0].astype(np.float32)
    strata = np.sin(yy / size * math.pi * 14.0 + n * 5.0) * 0.5 + 0.5
    base = np.array([0.52, 0.48, 0.44])
    col = base[None, None, :] * (0.65 + 0.35 * strata[..., None]) * (0.8 + 0.3 * fine[..., None])
    # veines de cristal bleu pâle
    vein = np.abs(np.sin((yy / size * 9.0 + n * 3.0) * math.pi)) < 0.035
    col = np.where(vein[..., None], np.array([0.55, 0.78, 0.95]), col)
    save_rgb(col, TEX / "ciel" / "roche_ciel.png")
    normal_map(strata * 0.6 + fine * 0.4, 6.0).save(TEX / "ciel" / "roche_ciel_n.png")


# =================================================================== icônes

def icon_plume():
    img = icons.canvas()
    f = _feather(192, 820, 0.35, (0.5, 0.36, 0.2), (0.12, 0.09, 0.06), 4, seed=9)
    fi = Image.fromarray((f * 255).astype(np.uint8), "RGBA").resize((170, 470)).rotate(-35, expand=True, resample=Image.BICUBIC)
    img.alpha_composite(fi, (256 - fi.width // 2, 256 - fi.height // 2))
    d = ImageDraw.Draw(img)
    d.ellipse((330, 360, 372, 402), fill=(230, 190, 70, 255))
    icons.save(img, "plume_ventaile")


def icon_cristal(name, c):
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.polygon([(256, 40), (360, 200), (310, 470), (202, 470), (152, 200)], fill=tuple(int(x * 0.6) for x in c) + (255,))
    d.polygon([(256, 40), (300, 200), (256, 470), (202, 470), (152, 200)], fill=c + (255,))
    d.polygon([(256, 40), (230, 200), (256, 330)], fill=(255, 255, 255, 170))
    glow = Image.new("RGBA", img.size, c + (0,))
    ImageDraw.Draw(glow).ellipse((110, 90, 400, 440), fill=c + (90,))
    glow = glow.filter(ImageFilter.GaussianBlur(30))
    glow.alpha_composite(img)
    icons.save(glow, name)


def icon_couronne():
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    gold = (226, 182, 70, 255)
    d.polygon([(80, 380), (80, 190), (160, 280), (256, 140), (352, 280), (432, 190), (432, 380)], fill=gold)
    d.rectangle((80, 360, 432, 420), fill=(200, 155, 55, 255))
    for x, c in ((140, (70, 120, 220)), (256, (230, 240, 255)), (372, (70, 120, 220))):
        icons.shaded_ellipse(img, (x - 26, 362, x + 26, 414), c)
    for x, y in ((80, 190), (256, 140), (432, 190)):
        icons.shaded_ellipse(img, (x - 18, y - 18, x + 18, y + 18), (240, 240, 255))
    icons.save(img, "couronne_nuees")


def icon_epee():
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    icons.stick_polygon(d, (120, 400), (420, 90), 46, (205, 220, 240, 255))
    icons.stick_polygon(d, (150, 370), (420, 90), 12, (250, 252, 255, 255))
    icons.stick_polygon(d, (70, 330), (190, 450), 26, (226, 182, 70, 255))
    icons.stick_polygon(d, (130, 390), (60, 460), 26, (40, 50, 110, 255))
    icons.shaded_ellipse(img, (40, 440, 84, 484), (90, 160, 240))
    # éclair gravé sur la lame
    d.line([(300, 210), (270, 250), (300, 255), (262, 300)], fill=(90, 160, 240, 255), width=8)
    icons.save(img, "epee_nuees")


def icon_selle():
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.chord((70, 150, 442, 440), 180, 360, fill=(120, 66, 34, 255))
    d.rectangle((70, 290, 442, 330), fill=(96, 50, 26, 255))
    d.ellipse((200, 120, 312, 200), fill=(140, 80, 40, 255))
    d.line([(150, 320), (150, 470)], fill=(60, 34, 18, 255), width=14)
    d.line([(362, 320), (362, 470)], fill=(60, 34, 18, 255), width=14)
    d.rectangle((126, 450, 176, 480), outline=(190, 190, 200, 255), width=8)
    d.rectangle((338, 450, 388, 480), outline=(190, 190, 200, 255), width=8)
    icons.save(img, "selle_aigle")


if __name__ == "__main__":
    pierre_chateau()
    dalles_chateau()
    ardoise()
    banniere()
    vitrail()
    tapis()
    plumage()
    tete()
    remiges()
    nuage()
    roche_ciel()
    icon_plume()
    icon_cristal("cristal_levant", (250, 190, 90))
    icon_cristal("cristal_couchant", (120, 170, 250))
    icon_couronne()
    icon_epee()
    icon_selle()
