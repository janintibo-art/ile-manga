"""V58 : textures du royaume des fées et d'Yggdrasil, l'Arbre-Monde.

fees/   ecorce_ygg.png (+_n) : écorce millénaire d'Yggdrasil — profonds sillons verticaux,
                              crêtes argentées, mousse et lichens dans les creux (raccordable) ;
        fleurs_arbre.png      : une grappe de fleurs de cerisier (pétales roses et blancs, cœurs
                              dorés, rameaux), avec alpha, pour les cartes de feuillage ;
        cernes.png (+_n)      : une coupe de bois vivant (cernes, rayons, fentes, mousse au bord),
                              pour les planchers du tronc creux et la couronne d'Yggdrasil ;
        runes_porte.png       : la porte d'Yggdrasil — deux vantaux d'écorce gravés de runes
                              (alpha hors de l'arche), et le masque des runes qui luisent.
items/  champignon_magique, graine_yggdrasil.
Tout est dessiné ici (libre de droits).
Lancement depuis la racine du dépôt : python3 pcvr/tools/generate_fees_v58.py
"""
from pathlib import Path
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
TEX = ROOT / "www" / "assets" / "textures"
OUT = TEX / "fees"
rng = np.random.default_rng(5858)

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_items_v28 as icons  # noqa: E402


# =================================================================== outils

def tile_noise(w, h, ox=(4, 8, 16, 32, 64, 128), oy=None, falloff=0.55):
    """Bruit fractal raccordable (0..1), fréquences séparées en x et en y."""
    oy = oy or ox
    acc = np.zeros((h, w), dtype=np.float32)
    amp, total = 1.0, 0.0
    for fx, fy in zip(ox, oy):
        layer = rng.random((fy, fx)).astype(np.float32)
        big = Image.fromarray((np.tile(layer, (3, 3)) * 255).astype(np.uint8)).resize((w * 3, h * 3), Image.BICUBIC)
        acc += np.asarray(big, dtype=np.float32)[h:h * 2, w:w * 2] / 255.0 * amp
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


def save_n(h, strength, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    normal_map(h, strength).save(path, optimize=True)
    print(path.relative_to(ROOT))


# =================================================================== écorce d'Yggdrasil

def ecorce():
    S = 1024
    # Sillons verticaux : un bruit très étiré (beaucoup de variations en x, peu en y)
    furrow = tile_noise(S, S, ox=(12, 24, 48, 96, 192), oy=(2, 3, 6, 12, 24), falloff=0.6)
    ridge = 1.0 - np.abs(furrow * 2.0 - 1.0)
    ridge = ridge ** 2.2
    # Plaques d'écorce : coupures horizontales irrégulières
    plates = tile_noise(S, S, ox=(6, 12, 24, 48), oy=(10, 20, 40, 80), falloff=0.5)
    crack = np.clip((np.abs(plates - 0.5) - 0.02) * 30.0, 0, 1)
    fine = tile_noise(S, S, ox=(64, 128, 256), oy=(32, 64, 128), falloff=0.6)
    h = ridge * 0.75 * (0.65 + 0.35 * crack) + fine * 0.2
    h = np.clip(h, 0, 1)
    # Couleurs : crêtes gris argenté, creux brun profond, mousse vert vif dans les creux humides
    deep = np.array([0.16, 0.12, 0.09])
    mid = np.array([0.42, 0.36, 0.3])
    crest = np.array([0.72, 0.7, 0.64])
    col = deep + (mid - deep) * np.clip(h * 1.6, 0, 1)[..., None]
    col = col + (crest - col) * np.clip((h - 0.55) * 2.4, 0, 1)[..., None]
    moss_n = tile_noise(S, S, ox=(4, 8, 16, 32, 64), falloff=0.6)
    moss = np.clip((moss_n - 0.48) * 4.0, 0, 1) * np.clip((0.42 - h) * 4.0, 0, 1)
    moss_col = np.array([0.33, 0.48, 0.16]) * (0.8 + 0.4 * fine[..., None])
    col = col * (1 - moss[..., None]) + moss_col * moss[..., None]
    # Lichens pâles en taches sur les crêtes
    lich_n = tile_noise(S, S, ox=(16, 32, 64, 128), falloff=0.5)
    lich = np.clip((lich_n - 0.7) * 6.0, 0, 1) * np.clip((h - 0.45) * 3.0, 0, 1)
    col = col * (1 - lich[..., None] * 0.7) + np.array([0.78, 0.82, 0.68]) * lich[..., None] * 0.7
    col *= (0.85 + 0.3 * fine)[..., None]
    save_rgb(col, OUT / "ecorce_ygg.png")
    save_n(h + moss * 0.05, 9.0, OUT / "ecorce_ygg_n.png")


# =================================================================== fleurs de cerisier

def fleurs():
    S = 512
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Rameaux sombres qui portent les grappes
    for k in range(7):
        x0, y0 = rng.uniform(40, 470), rng.uniform(40, 470)
        a = rng.uniform(0, math.tau)
        pts = [(x0, y0)]
        for s in range(6):
            a += rng.uniform(-0.5, 0.5)
            pts.append((pts[-1][0] + math.cos(a) * 34, pts[-1][1] + math.sin(a) * 34))
        d.line(pts, fill=(70, 42, 34, 255), width=int(rng.uniform(4, 7)))
    # Fleurs à cinq pétales, du rose tendre au blanc, cœur doré
    flowers = []
    for k in range(150):
        r = rng.uniform(20, 235)
        a = rng.uniform(0, math.tau)
        x = 256 + math.cos(a) * r * rng.uniform(0.6, 1.0)
        y = 256 + math.sin(a) * r * rng.uniform(0.6, 1.0)
        flowers.append((x, y, rng.uniform(13, 24), rng.uniform(0, math.tau), rng.uniform(0, 1)))
    flowers.sort(key=lambda f: f[1])
    for (x, y, rad, rot, tone) in flowers:
        petal = (int(255), int(196 + 50 * tone), int(214 + 36 * tone))
        dark = (int(232), int(140 + 40 * tone), int(170 + 30 * tone))
        for p in range(5):
            a = rot + p * math.tau / 5
            cx, cy = x + math.cos(a) * rad * 0.55, y + math.sin(a) * rad * 0.55
            pr = rad * 0.52
            d.ellipse((cx - pr, cy - pr, cx + pr, cy + pr), fill=dark + (255,))
            d.ellipse((cx - pr * 0.82, cy - pr * 0.82, cx + pr * 0.82, cy + pr * 0.82), fill=petal + (255,))
        d.ellipse((x - rad * 0.25, y - rad * 0.25, x + rad * 0.25, y + rad * 0.25), fill=(236, 120, 150, 255))
        for s in range(7):
            a = rot + s * math.tau / 7
            sx, sy = x + math.cos(a) * rad * 0.3, y + math.sin(a) * rad * 0.3
            d.ellipse((sx - 2, sy - 2, sx + 2, sy + 2), fill=(255, 214, 90, 255))
    # Quelques jeunes feuilles vert tendre
    for k in range(26):
        x, y = rng.uniform(40, 470), rng.uniform(40, 470)
        a = rng.uniform(0, math.tau)
        L = rng.uniform(18, 30)
        pts = [(x + math.cos(a + t) * L * (1 if t == 0 else 0.35), y + math.sin(a + t) * L * (1 if t == 0 else 0.35)) for t in (0, 1.6, math.pi, -1.6)]
        d.polygon(pts, fill=(118, 160, 70, 255))
    arr = np.asarray(img, dtype=np.float32) / 255.0
    # Léger ombrage : le cœur de la grappe un peu plus sombre
    yy, xx = np.mgrid[0:S, 0:S]
    rr = np.sqrt((xx - 256) ** 2 + (yy - 256) ** 2) / 256
    arr[..., :3] *= (0.8 + 0.2 * np.clip(rr, 0, 1))[..., None]
    save_rgba(arr, OUT / "fleurs_arbre.png")


# =================================================================== coupe de bois (cernes)

def cernes():
    S = 1024
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    u = (xx - S / 2) / (S / 2)
    v = (yy - S / 2) / (S / 2)
    r = np.sqrt(u * u + v * v)
    a = np.arctan2(v, u)
    wob = tile_noise(S, S, ox=(4, 8, 16), falloff=0.6) - 0.5
    rings_r = r * 150.0 + wob * 6.0 + np.sin(a * 3.0 + 1.0) * 0.8
    ring = 0.5 + 0.5 * np.cos(rings_r * math.tau)
    # cernes fins, d'épaisseur inégale ; par endroits des années plus marquées
    year = tile_noise(S, S, ox=(4, 8, 16), falloff=0.5)
    ring = (ring ** 4) * (0.35 + 0.4 * np.clip((np.sin(r * 23.0 + wob * 2.0) * 0.5 + 0.5) + year - 0.5, 0, 1))
    grain = tile_noise(S, S, ox=(64, 128, 256), falloff=0.6)
    # Rayons médullaires et fentes de séchage
    rays = np.clip(np.abs(np.sin(a * 41.0)) ** 40 * 0.6, 0, 1) * np.clip(r * 2.0, 0, 1)
    cracks = np.zeros_like(r)
    for k in range(6):
        ca = rng.uniform(-math.pi, math.pi)
        width = rng.uniform(0.008, 0.02)
        da = np.abs(np.angle(np.exp(1j * (a - ca))))
        cracks += np.clip(1.0 - da / width, 0, 1) * np.clip((r - rng.uniform(0.25, 0.5)) * 6.0, 0, 1)
    cracks = np.clip(cracks, 0, 1)
    light = np.array([0.86, 0.7, 0.5])
    late = np.array([0.56, 0.38, 0.24])
    col = light * (1 - ring[..., None]) + late * ring[..., None]
    col *= (0.88 + 0.24 * grain)[..., None]
    col += rays[..., None] * 0.08
    col *= (1.0 - cracks * 0.75)[..., None]
    # Cœur plus sombre, aubier clair, écorce et mousse au bord
    col *= (0.8 + 0.2 * np.clip(r * 3.0, 0, 1))[..., None]
    bark = np.clip((r - 0.93) * 25.0, 0, 1)
    col = col * (1 - bark[..., None]) + np.array([0.3, 0.24, 0.18]) * bark[..., None]
    moss_n = tile_noise(S, S, ox=(8, 16, 32, 64), falloff=0.6)
    moss = np.clip((r - 0.8) * 6.0, 0, 1) * np.clip((moss_n - 0.45) * 4.0, 0, 1)
    col = col * (1 - moss[..., None]) + np.array([0.3, 0.46, 0.15]) * moss[..., None] * (0.8 + 0.4 * grain[..., None])
    save_rgb(col, OUT / "cernes.png")
    h = (1 - ring) * 0.3 + grain * 0.2 - cracks * 0.6 + moss * 0.2
    save_n(h, 6.0, OUT / "cernes_n.png")


# =================================================================== la porte aux runes

RUNES = [
    [(0, -1), (0, 1), None, (0, -0.2), (0.7, -0.9)],
    [(0, -1), (0, 1), None, (-0.6, -0.5), (0.6, 0.5)],
    [(-0.6, 1), (0, -1), (0.6, 1)],
    [(0, -1), (0, 1), None, (0, -1), (0.6, -0.4), (0, 0.2)],
    [(-0.6, -1), (0.6, 1), None, (0.6, -1), (-0.6, 1)],
    [(0, -1), (0, 1), None, (-0.6, -0.3), (0, 0.3), (0.6, -0.3)],
    [(-0.5, -1), (-0.5, 1), None, (0.5, -1), (0.5, 1), None, (-0.5, 0), (0.5, 0)],
    [(0, -1), (-0.6, -0.1), (0, 0.8), (0.6, -0.1), (0, -1)],
]


def draw_rune(d, cx, cy, s, k, fill, width):
    seg = []
    for p in RUNES[k % len(RUNES)] + [None]:
        if p is None:
            if len(seg) > 1:
                d.line(seg, fill=fill, width=width, joint="curve")
            seg = []
        else:
            seg.append((cx + p[0] * s, cy + p[1] * s))


def porte():
    W, H = 512, 1024
    bark = np.asarray(Image.open(OUT / "ecorce_ygg.png").convert("RGB").resize((W, H)), dtype=np.float32) / 255.0
    bark = bark * 0.75
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    # Arche : rectangle surmonté d'un arc en ogive
    cx = W / 2
    inside = np.zeros((H, W), dtype=bool)
    spring = 360
    for y in range(H):
        if y >= spring:
            inside[y, 24:W - 24] = True
        else:
            # deux arcs de cercle qui se rejoignent en pointe
            R = 560.0
            dy = spring - y
            half = math.sqrt(max(0.0, R * R - dy * dy)) - (R - (W / 2 - 24))
            if half > 0:
                inside[y, int(max(24, cx - half)):int(min(W - 24, cx + half))] = True
    alpha = inside.astype(np.float32)
    # Le joint entre les deux vantaux, et un cadre sombre
    seam = np.clip(1.0 - np.abs(xx - cx) / 4.0, 0, 1)
    col = bark * (1.0 - seam[..., None] * 0.8)
    edge = np.array(Image.fromarray((alpha * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(31)), dtype=np.float32) / 255.0
    col *= (0.55 + 0.45 * edge)[..., None]
    rgba = np.dstack((col, alpha))
    img = Image.fromarray((np.clip(rgba, 0, 1) * 255).astype(np.uint8), "RGBA")
    glow = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(img)
    dg = ImageDraw.Draw(glow)
    # Une colonne de runes de chaque côté, un grand arbre stylisé au centre
    k = 0
    for side in (-1, 1):
        for i in range(7):
            x = cx + side * 150
            y = 300 + i * 100
            draw_rune(d, x, y, 26, k, (40, 30, 24, 255), 9)
            draw_rune(dg, x, y, 26, k, 255, 7)
            k += 3
    # L'arbre-monde : tronc, branches en éventail, racines
    for g in (d, dg):
        fill = (40, 30, 24, 255) if g is d else 255
        wd = 10 if g is d else 7
        g.line([(cx - 30, 760), (cx - 30, 470)], fill=fill, width=wd)
        g.line([(cx + 30, 760), (cx + 30, 470)], fill=fill, width=wd)
        for b in range(7):
            a = math.pi * (0.15 + 0.7 * b / 6)
            g.line([(cx, 480), (cx - math.cos(a) * 120, 480 - math.sin(a) * 150)], fill=fill, width=wd)
        g.arc((cx - 130, 300, cx + 130, 560), 180, 360, fill=fill, width=wd)
        for b in range(5):
            a = math.pi * (0.1 + 0.8 * b / 4)
            g.line([(cx, 760), (cx - math.cos(a) * 110, 760 + math.sin(a) * 90)], fill=fill, width=wd)
    img.save(OUT / "runes_porte.png", optimize=True)
    print((OUT / "runes_porte.png").relative_to(ROOT))
    glow = glow.filter(ImageFilter.GaussianBlur(3))
    ga = np.asarray(glow, dtype=np.float32) / 255.0 * alpha
    em = np.dstack((ga * 0.55, ga * 1.0, ga * 0.75))
    save_rgb(em, OUT / "runes_porte_lueur.png")


# =================================================================== icônes

def icon_champignon_magique():
    img = icons.canvas()
    glow = Image.new("RGBA", img.size, (120, 160, 255, 0))
    ImageDraw.Draw(glow).ellipse((60, 60, 452, 452), fill=(140, 170, 255, 110))
    glow = glow.filter(ImageFilter.GaussianBlur(40))
    img.alpha_composite(glow)
    stem = icons.canvas()
    icons.shaded_ellipse(stem, (204, 236, 308, 470), (232, 236, 250), gloss=False)
    img.alpha_composite(stem)
    cap = icons.canvas()
    icons.shaded_ellipse(cap, (74, 80, 438, 330), (110, 80, 210))
    cut = Image.new("L", (icons.S, icons.S), 0)
    ImageDraw.Draw(cut).rectangle((0, 0, icons.S, 262), fill=255)
    cap.putalpha(Image.fromarray(np.minimum(np.array(cap.split()[3]), np.array(cut))))
    img.alpha_composite(cap)
    d = ImageDraw.Draw(img)
    d.rectangle((90, 256, 422, 270), fill=(170, 210, 255, 255))
    for (x, y, r) in [(160, 176, 20), (250, 136, 17), (336, 180, 22), (210, 222, 13), (300, 226, 12), (120, 230, 10), (390, 228, 10)]:
        halo = Image.new("RGBA", img.size, (0, 0, 0, 0))
        ImageDraw.Draw(halo).ellipse((x - r * 2, y - r * 2, x + r * 2, y + r * 2), fill=(160, 230, 255, 120))
        img.alpha_composite(halo.filter(ImageFilter.GaussianBlur(8)))
        d.ellipse((x - r, y - r, x + r, y + r), fill=(200, 245, 255, 255))
    for (x, y) in [(110, 120), (420, 140), (90, 330), (430, 360), (256, 40)]:
        d.polygon([(x, y - 16), (x + 5, y - 5), (x + 16, y), (x + 5, y + 5), (x, y + 16), (x - 5, y + 5), (x - 16, y), (x - 5, y - 5)], fill=(255, 250, 200, 255))
    icons.save(img, "champignon_magique")


def icon_graine():
    img = icons.canvas()
    glow = Image.new("RGBA", img.size, (255, 220, 120, 0))
    ImageDraw.Draw(glow).ellipse((70, 60, 442, 470), fill=(255, 220, 120, 130))
    glow = glow.filter(ImageFilter.GaussianBlur(44))
    img.alpha_composite(glow)
    seed = icons.canvas()
    icons.shaded_ellipse(seed, (150, 96, 362, 440), (196, 140, 60))
    img.alpha_composite(seed)
    d = ImageDraw.Draw(img)
    # Veines dorées lumineuses, en forme d'arbre
    d.line([(256, 420), (256, 160)], fill=(255, 236, 150, 255), width=10)
    for k, (dx, y) in enumerate([(-60, 220), (60, 250), (-50, 300), (55, 330), (-40, 370)]):
        d.line([(256, y + 30), (256 + dx, y)], fill=(255, 230, 140, 255), width=7)
    # Germe vert à la pointe
    leaf = icons.canvas()
    icons.shaded_ellipse(leaf, (250, 50, 360, 120), (110, 190, 70), gloss=False)
    leaf = leaf.rotate(-25, center=(300, 90))
    img.alpha_composite(leaf)
    d.line([(256, 104), (290, 80)], fill=(90, 150, 60, 255), width=8)
    icons.save(img, "graine_yggdrasil")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    ecorce()
    fleurs()
    cernes()
    porte()
    icon_champignon_magique()
    icon_graine()
