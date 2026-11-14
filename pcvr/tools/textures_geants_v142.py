"""V142 : les textures de l'Île des Géants (fabriquées ici ; versées au domaine public, CC0 1.0).

  geants/chou.png, chou_n.png              une feuille de chou (vert bleuté, la grosse nervure blanche au
                                           milieu, les nervures qui partent en arc) ; v = 1 au pied
  geants/citrouille.png, citrouille_n.png  la peau d'une citrouille (orange, marbrures, sillons sombres
                                           entre les côtes : 10 côtes sur le tour, u = 0..1)
  geants/tournesol.png                     le cœur d'un tournesol (les graines en spirales de Fibonacci)
  geants/ble.png                           un épi de blé mûr, ses barbes (détouré)
  geants/nenuphar.png                      une feuille de nénuphar (ronde, échancrée, nervures en rayons)
  geants/feuille_citrouille.png            une grande feuille de citrouille, lobée, nervurée (détourée)
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/textures_geants_v142.py
"""
from pathlib import Path
import math

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "geants"
RNG = np.random.default_rng(14242)


def noise(n, scales=(4, 8, 16, 32, 64), amp=0.55, tile=True):
    out = np.zeros((n, n), np.float32)
    a = 1.0
    tot = 0.0
    for s in scales:
        k = max(2, n // s)
        g = RNG.standard_normal((k, k)).astype(np.float32)
        if tile:
            g = np.pad(g, ((0, 1), (0, 1)), mode="wrap")
            up = np.asarray(Image.fromarray(g).resize((n + n // k, n + n // k), Image.BICUBIC), np.float32)[:n, :n]
        else:
            up = np.asarray(Image.fromarray(g).resize((n, n), Image.BICUBIC), np.float32)
        out += up * a
        tot += a
        a *= amp
    out /= tot
    return (out - out.min()) / (out.max() - out.min() + 1e-9)


def normal_map(h, strength):
    gx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5
    gy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5
    nrm = np.stack([-gx * strength, gy * strength, np.ones_like(h)], -1)
    nrm /= np.linalg.norm(nrm, axis=-1, keepdims=True)
    return Image.fromarray(((nrm * 0.5 + 0.5) * 255).astype(np.uint8), "RGB")


def save(img, name):
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / name, optimize=True)
    print(name)


def mix(a, b, t):
    t = np.asarray(t)[..., None]
    return np.asarray(a, np.float32) * (1 - t) + np.asarray(b, np.float32) * t


# ------------------------------------------------------------------ la feuille de chou
def chou():
    n = 512
    v, u = np.mgrid[0:n, 0:n] / (n - 1.0)          # v : 0 en haut (le bout), 1 en bas (le pied)
    x = (u - 0.5) * 2.0
    nz = noise(n)
    nz2 = noise(n, scales=(16, 32, 64, 128))
    base = mix([0.36, 0.55, 0.42], [0.62, 0.74, 0.55], np.clip(v * 0.8 + nz * 0.25, 0, 1))
    edge = np.clip(np.abs(x) - 0.55, 0, 1) / 0.45
    col = mix(base, [0.26, 0.42, 0.38], edge * 0.8)
    # la grosse nervure du milieu, plus large au pied
    w = 0.025 + 0.06 * v
    mid = np.exp(-(x / w) ** 2)
    # les nervures en arc : elles partent de la nervure centrale vers le haut et le bord
    vein = np.zeros_like(x)
    for k in range(9):
        v0 = 0.12 + k * 0.1
        # le long de chaque nervure : v = v0 - 0.35 * |x| ** 1.3
        d = v - (v0 - 0.38 * np.abs(x) ** 1.25)
        vein = np.maximum(vein, np.exp(-(d / 0.009) ** 2) * (np.abs(x) < 0.97))
    fine = np.zeros_like(x)
    for k in range(26):
        v0 = 0.05 + k * 0.038
        d = v - (v0 - 0.3 * np.abs(x) ** 1.2)
        fine = np.maximum(fine, np.exp(-(d / 0.004) ** 2) * 0.5)
    pale = np.array([0.82, 0.88, 0.74], np.float32)
    col = mix(col, pale, np.clip(mid * 0.95, 0, 1))
    col = mix(col, pale * 0.92, np.clip(vein * 0.7, 0, 1))
    col = mix(col, col * 1.12, np.clip(fine * 0.6, 0, 1))
    # la pruine (le voile bleuté) et des cloques entre les nervures
    col *= (0.9 + 0.2 * nz2)[..., None]
    save(Image.fromarray(np.clip(col * 255, 0, 255).astype(np.uint8), "RGB"), "chou.png")
    h = mid * 1.0 + vein * 0.6 + fine * 0.2 + nz2 * 0.35
    save(normal_map(h, 6.0), "chou_n.png")


# ------------------------------------------------------------------ la peau de citrouille
def citrouille():
    n = 512
    v, u = np.mgrid[0:n, 0:n] / (n - 1.0)
    nz = noise(n)
    nz2 = noise(n, scales=(32, 64, 128))
    rib = 0.5 + 0.5 * np.cos(u * 10 * 2 * math.pi)     # 1 au milieu d'une côte, 0 dans le sillon
    col = mix([0.78, 0.32, 0.05], [0.96, 0.55, 0.12], np.clip(rib * 0.7 + nz * 0.4, 0, 1))
    col = mix(col, [0.55, 0.2, 0.03], np.clip((1 - rib) ** 6, 0, 1) * 0.8)
    # les marbrures plus claires, les petits points
    col = mix(col, [1.0, 0.7, 0.3], np.clip((nz2 - 0.6) * 2.5, 0, 1) * 0.5)
    spots = (RNG.random((n, n)) > 0.9975).astype(np.float32)
    spots = np.asarray(Image.fromarray((spots * 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(1.2)), np.float32) / 255.0
    col = mix(col, [0.98, 0.82, 0.52], np.clip(spots * 3.0, 0, 1) * 0.6)
    # le haut et le bas (près de la queue et du « nombril ») un peu plus verts
    pole = np.clip(1.0 - np.minimum(v, 1 - v) / 0.12, 0, 1)
    col = mix(col, [0.5, 0.42, 0.12], pole * 0.6)
    save(Image.fromarray(np.clip(col * 255, 0, 255).astype(np.uint8), "RGB"), "citrouille.png")
    save(normal_map(rib * 0.6 + nz2 * 0.4 + spots * 0.3, 4.0), "citrouille_n.png")


# ------------------------------------------------------------------ le cœur du tournesol
def tournesol():
    n = 512
    img = np.zeros((n, n, 4), np.float32)
    yy, xx = np.mgrid[0:n, 0:n]
    c = (n - 1) / 2.0
    r = np.hypot(xx - c, yy - c) / c
    golden = math.pi * (3 - math.sqrt(5))
    seeds = 2200
    col = np.zeros((n, n, 3), np.float32)
    col[:] = [0.16, 0.1, 0.05]
    acc = np.zeros((n, n), np.float32)
    for i in range(seeds):
        rr = math.sqrt(i / seeds) * 0.97
        a = i * golden
        sx = c + math.cos(a) * rr * c
        sy = c + math.sin(a) * rr * c
        rad = 3.2 + 2.0 * rr
        x0, x1 = int(max(sx - rad - 1, 0)), int(min(sx + rad + 2, n))
        y0, y1 = int(max(sy - rad - 1, 0)), int(min(sy + rad + 2, n))
        if x1 <= x0 or y1 <= y0:
            continue
        gx, gy = np.meshgrid(np.arange(x0, x1), np.arange(y0, y1))
        d = np.hypot(gx - sx, gy - sy) / rad
        bump = np.clip(1 - d, 0, 1)
        acc[y0:y1, x0:x1] = np.maximum(acc[y0:y1, x0:x1], bump)
    seed_col = mix([0.1, 0.06, 0.03], [0.34, 0.22, 0.1], acc)
    # le centre vert-jaune (les fleurons pas encore ouverts), l'anneau de fleurons dorés au bord
    seed_col = mix(seed_col, [0.42, 0.4, 0.12], np.clip(1 - r / 0.22, 0, 1))
    seed_col = mix(seed_col, [0.72, 0.45, 0.08], np.clip((r - 0.85) / 0.12, 0, 1) * 0.8)
    img[..., :3] = seed_col
    img[..., 3] = (r < 1.0).astype(np.float32)
    save(Image.fromarray(np.clip(img * 255, 0, 255).astype(np.uint8), "RGBA"), "tournesol.png")


# ------------------------------------------------------------------ l'épi de blé
def ble():
    w, h = 160, 512
    px = np.zeros((h, w, 4), np.float32)
    yy, xx = np.mgrid[0:h, 0:w]
    cx = w / 2
    # la tige, sous l'épi
    stem = (np.abs(xx - cx) < 2.2) & (yy > h * 0.74)
    px[stem] = [0.8, 0.68, 0.38, 1]
    rows = 18
    order = []
    for k in range(rows):
        t = k / (rows - 1)
        yc = h * (0.75 - t * 0.62)
        for side in (-1, 1):
            order.append((yc, side, t))
    # les grains : des ovales serrés, penchés vers l'extérieur ; les barbes : de longs traits fins
    for yc, side, t in order:
        ex = cx + side * (7.5 - 2.0 * t)
        ey = yc - side * 3.0
        ang = side * 0.35
        ca, sa = math.cos(ang), math.sin(ang)
        dx, dy = xx - ex, yy - ey
        u = (dx * ca + dy * sa) / (8.2 - 2.0 * t)
        v = (-dx * sa + dy * ca) / (13.0 - 3.0 * t)
        d = u * u + v * v
        m = d < 1
        shade = (0.75 + 0.25 * (1 - d)) * (0.9 + 0.1 * np.clip(-u, -1, 1))
        px[m, 0] = 0.92 * shade[m]
        px[m, 1] = 0.76 * shade[m]
        px[m, 2] = 0.4 * shade[m]
        px[m, 3] = 1
    img = Image.fromarray(np.clip(px * 255, 0, 255).astype(np.uint8), "RGBA")
    # les barbes : de longs traits fins, qui montent en s'écartant (dessinés derrière les grains)
    barbes = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dr = ImageDraw.Draw(barbes)
    for yc, side, t in order:
        ex = cx + side * (7.5 - 2.0 * t)
        ey = yc - side * 3.0 - 8
        dr.line([(ex, ey), (ex + side * (30 - 10 * t), ey - 170 + 40 * t)], fill=(222, 196, 130, 235), width=1)
    barbes.alpha_composite(img)
    save(barbes, "ble.png")


# ------------------------------------------------------------------ la feuille de nénuphar
def nenuphar():
    n = 512
    yy, xx = np.mgrid[0:n, 0:n]
    c = (n - 1) / 2.0
    dx, dy = (xx - c) / c, (yy - c) / c
    r = np.hypot(dx, dy)
    a = np.arctan2(dy, dx)
    nz = noise(n)
    col = mix([0.18, 0.36, 0.12], [0.36, 0.52, 0.2], np.clip(nz * 0.8 + r * 0.3, 0, 1))
    veins = np.clip(1 - np.abs(np.sin(a * 13)) * 12 * (r + 0.05), 0, 1) * (r > 0.05)
    col = mix(col, [0.5, 0.62, 0.3], veins * 0.55)
    col = mix(col, [0.45, 0.28, 0.12], np.clip((r - 0.9) / 0.1, 0, 1) * 0.6)
    notch = (np.abs(a - math.pi / 2) < 0.12 + 0.02 * r) & (r > 0.02)
    alpha = ((r < 0.98) & ~notch).astype(np.float32)
    img = np.dstack([col, alpha])
    save(Image.fromarray(np.clip(img * 255, 0, 255).astype(np.uint8), "RGBA"), "nenuphar.png")


# ------------------------------------------------------------------ la feuille de citrouille
def feuille_citrouille():
    n = 512
    yy, xx = np.mgrid[0:n, 0:n]
    c = (n - 1) / 2.0
    dx, dy = (xx - c) / c, (c - yy) / c
    r = np.hypot(dx, dy)
    a = np.arctan2(dy, dx)
    # cinq lobes (vers le haut), le pétiole en bas
    lobe = 0.72 + 0.24 * np.cos(5 * (a - math.pi / 2)) ** 2
    shape = r < lobe * (0.92 + 0.08 * np.cos(17 * a))
    shape &= ~((np.abs(a + math.pi / 2) < 0.3) & (r > 0.5))
    nz = noise(n)
    col = mix([0.16, 0.34, 0.1], [0.32, 0.5, 0.18], np.clip(nz * 0.9, 0, 1))
    vein = np.zeros_like(r)
    for k in range(5):
        ang = math.pi / 2 + (k - 2) * 0.62
        d = np.abs(np.sin(a - ang)) * r
        vein = np.maximum(vein, np.exp(-(d / 0.012) ** 2) * (np.cos(a - ang) > 0))
    col = mix(col, [0.62, 0.72, 0.42], vein * 0.7)
    img = np.dstack([col, shape.astype(np.float32)])
    save(Image.fromarray(np.clip(img * 255, 0, 255).astype(np.uint8), "RGBA"), "feuille_citrouille.png")


def main():
    chou()
    citrouille()
    tournesol()
    ble()
    nenuphar()
    feuille_citrouille()


if __name__ == "__main__":
    main()
