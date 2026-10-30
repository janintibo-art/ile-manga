"""V87 : textures de l'Île aux Moaïs.

moai/   — surfaces raccordables, chacune avec sa carte de relief <nom>_n.png (1024 px) :
          pierre_moai (+_n) : le tuf volcanique des Moaïs (une tuile ≈ 2 m) : gris-brun à grain fin,
                              alvéoles, cupules d'érosion, coulures verticales, lichens jaunes et
                              orangés en taches ;
          pukao (+_n)       : la scorie rouge des chignons de pierre (une tuile ≈ 1 m) : rouge brique
                              poreux, bulles, traînées plus sombres ;
          ahu (+_n)         : le mur des plateformes (une tuile ≈ 3 m) : grands blocs de basalte
                              ajustés, joints serrés, galets dans les joints, mousse au pied.
Tout est dessiné ici, procéduralement (outils des générateurs V69).
Lancement depuis la racine du dépôt :
    python3 pcvr/tools/generate_moai_v87.py
"""
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # pas de __pycache__ dans pcvr/tools

import numpy as np  # noqa: E402

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_soleils_v69 import tn, gblur, smooth, mix, C, normal_img, bake, to_img, worley  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "moai"
S = 1024


def rng(seed):
    return np.random.default_rng(seed)


def save(name, col, h, strength):
    OUT.mkdir(parents=True, exist_ok=True)
    to_img(col).save(OUT / (name + ".png"), optimize=True)
    normal_img(gblur(h.astype(np.float32), 0.6), strength).save(OUT / (name + "_n.png"), optimize=True)
    print("textures/moai/" + name, flush=True)


def pits(R, n, rmin, rmax):
    """Des alvéoles : petites cuvettes rondes (raccordables), 0 = rien, 1 = fond du trou."""
    h = np.zeros((S, S), np.float32)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    for _ in range(n):
        cx, cy = R.random() * S, R.random() * S
        r = R.uniform(rmin, rmax)
        x0, x1 = int(cx - r - 2), int(cx + r + 3)
        y0, y1 = int(cy - r - 2), int(cy + r + 3)
        ys = np.arange(y0, y1) % S
        xs = np.arange(x0, x1) % S
        dy = (np.arange(y0, y1) - cy)[:, None]
        dx = (np.arange(x0, x1) - cx)[None, :]
        d = np.sqrt(dx * dx + dy * dy) / r
        v = np.clip(1.0 - d * d, 0, 1)
        h[np.ix_(ys, xs)] = np.maximum(h[np.ix_(ys, xs)], v)
    return h


def pierre_moai():
    R = rng(8701)
    base = tn(R, S, (4, 8, 16, 32, 64, 128, 256, 512), 0.6)
    fine = tn(R, S, (128, 256, 512), 0.7)
    streak = tn(R, S, (8, 16, 32, 64), 0.6, oy=(64, 128, 256, 512))
    p = pits(R, 2600, 1.5, 6.0)
    cup = pits(R, 60, 10.0, 28.0)
    h = 0.55 * base + 0.18 * fine - 0.35 * p - 0.25 * gblur(cup, 2.0) + 0.08 * streak
    col = mix(C(0.47, 0.43, 0.38), C(0.38, 0.35, 0.31), base)
    col = mix(col, C(0.52, 0.47, 0.4), smooth(0.55, 0.8, fine) * 0.5)
    col = mix(col, C(0.3, 0.28, 0.26), smooth(0.45, 0.75, streak) * 0.35)
    col = col * (1.0 - 0.35 * p[..., None]) * (1.0 - 0.2 * gblur(cup, 3.0)[..., None])
    # les lichens : taches jaunes, orangées, gris-vert
    lich = tn(R, S, (6, 12, 24, 48, 96), 0.55)
    dots = tn(R, S, (64, 128, 256), 0.6)
    yel = smooth(0.62, 0.7, lich) * smooth(0.4, 0.6, dots)
    ora = smooth(0.66, 0.72, 1.0 - lich) * smooth(0.5, 0.62, dots)
    gre = smooth(0.58, 0.66, tn(R, S, (5, 10, 20, 40), 0.55)) * 0.6
    col = mix(col, C(0.7, 0.64, 0.4), yel * 0.45)
    col = mix(col, C(0.66, 0.44, 0.26), ora * 0.4)
    col = mix(col, C(0.46, 0.47, 0.4), gre * 0.25)
    h = h + 0.06 * (yel + ora)
    col = bake(col, h, 3.0, k=0.25, ao=0.25, ao_r=5)
    save("pierre_moai", col, h, 3.2)


def pukao():
    R = rng(8702)
    base = tn(R, S, (4, 8, 16, 32, 64, 128, 256), 0.6)
    p = pits(R, 4200, 1.2, 7.0)
    big = pits(R, 160, 6.0, 16.0)
    h = 0.5 * base - 0.45 * p - 0.3 * big
    col = mix(C(0.58, 0.24, 0.16), C(0.42, 0.16, 0.11), base)
    col = mix(col, C(0.66, 0.34, 0.22), smooth(0.6, 0.85, tn(R, S, (16, 32, 64, 128), 0.6)) * 0.5)
    col = col * (1.0 - 0.45 * np.maximum(p, big)[..., None])
    col = bake(col, h, 3.0, k=0.3, ao=0.3, ao_r=4)
    save("pukao", col, h, 3.6)


def ahu():
    R = rng(8703)
    d1, edge, cid, dx, dy = worley(R, S, 6, 0.7)
    # pierres : hauteur bombée au centre de chaque cellule, joints creux
    joint = smooth(1.0, 9.0, edge)
    ids = (cid.astype(np.int64) * 7919) % 997
    tint = (np.random.default_rng(8704).random(997).astype(np.float32))[ids]
    grain = tn(R, S, (16, 32, 64, 128, 256, 512), 0.6)
    h = 0.6 * joint + 0.25 * grain + 0.1 * tint
    col = mix(C(0.24, 0.23, 0.22), C(0.36, 0.34, 0.31), tint)
    col = mix(col, C(0.42, 0.4, 0.36), smooth(0.6, 0.85, grain) * 0.4)
    col = col * (0.55 + 0.45 * joint[..., None])
    moss = smooth(0.62, 0.74, tn(R, S, (4, 8, 16, 32, 64), 0.55)) * (1.0 - joint * 0.5)
    col = mix(col, C(0.33, 0.38, 0.24), moss * 0.55)
    col = bake(col, h, 3.0, k=0.3, ao=0.35, ao_r=6)
    save("ahu", col, h, 3.0)


# =================================================================== V88 : les gravures des maisons

def _carve(draw_fn, name, seed):
    """Une pierre plate (512 px) où l'on a gravé un dessin : le trait est creusé, ocre, un peu usé."""
    from PIL import Image as _I, ImageDraw as _D
    R = rng(seed)
    n = 512
    base = tn(R, n, (4, 8, 16, 32, 64, 128), 0.6)
    col = mix(C(0.5, 0.45, 0.38), C(0.4, 0.36, 0.31), base)
    mask = _I.new("L", (n, n), 0)
    d = _D.Draw(mask)
    draw_fn(d, n)
    m = np.asarray(mask, np.float32) / 255.0
    m = gblur(m, 1.2)
    wear = smooth(0.3, 0.7, tn(R, n, (8, 16, 32, 64), 0.6))
    col = mix(col, C(0.72, 0.5, 0.3), m * (0.6 + 0.4 * wear))
    col = col * (1.0 - 0.25 * m[..., None])
    h = base * 0.4 - m * 0.6
    col = bake(col, h, 3.0, k=0.3, ao=0.3, ao_r=4)
    OUT.mkdir(parents=True, exist_ok=True)
    to_img(col).save(OUT / (name + ".png"), optimize=True)
    print("textures/moai/" + name, flush=True)


def fresques():
    def tortue(d, n):
        w = 9
        d.ellipse((140, 150, 372, 360), outline=255, width=w)
        d.ellipse((205, 205, 307, 305), outline=255, width=w)
        d.ellipse((226, 80, 286, 150), outline=255, width=w)
        for (x, y, a) in ((150, 170, -1), (362, 170, 1), (150, 340, -1), (362, 340, 1)):
            d.line((x, y, x + a * 60, y + (-50 if y < 250 else 50)), fill=255, width=w)
        d.line((256, 360, 256, 420), fill=255, width=w)
        for k in range(6):
            import math as _m
            a2 = k * _m.tau / 6
            d.line((256, 255, 256 + 50 * _m.cos(a2), 255 + 50 * _m.sin(a2)), fill=255, width=6)

    def oiseau(d, n):
        w = 9
        d.ellipse((200, 120, 300, 220), outline=255, width=w)
        d.polygon(((300, 160), (380, 180), (300, 195)), outline=255, width=w)
        d.ellipse((238, 150, 258, 170), fill=255)
        d.line((250, 220, 250, 360), fill=255, width=w)
        d.line((250, 240, 150, 200), fill=255, width=w)
        d.line((150, 200, 120, 260), fill=255, width=w)
        d.line((250, 240, 350, 270), fill=255, width=w)
        d.line((250, 360, 200, 440), fill=255, width=w)
        d.line((250, 360, 300, 440), fill=255, width=w)
        d.arc((60, 40, 452, 472), 200, 340, fill=255, width=6)

    def poissons(d, n):
        w = 8
        for (x, y, s) in ((120, 140, 1.0), (300, 230, 1.2), (140, 360, 0.9)):
            d.ellipse((x, y - 35 * s, x + 130 * s, y + 35 * s), outline=255, width=w)
            d.polygon(((x, y), (x - 50 * s, y - 40 * s), (x - 50 * s, y + 40 * s)), outline=255, width=w)
            d.ellipse((x + 95 * s, y - 10 * s, x + 110 * s, y + 5 * s), fill=255)
        for k in range(5):
            d.arc((40 + k * 90, 440, 120 + k * 90, 500), 180, 360, fill=255, width=6)

    def soleil(d, n):
        import math as _m
        w = 9
        d.ellipse((176, 176, 336, 336), outline=255, width=w)
        d.ellipse((216, 226, 236, 246), fill=255)
        d.ellipse((276, 226, 296, 246), fill=255)
        d.arc((216, 236, 296, 300), 20, 160, fill=255, width=w)
        for k in range(12):
            a = k * _m.tau / 12
            d.line((256 + 105 * _m.cos(a), 256 + 105 * _m.sin(a), 256 + 170 * _m.cos(a), 256 + 170 * _m.sin(a)), fill=255, width=w)

    _carve(tortue, "fresque_tortue", 8810)
    _carve(oiseau, "fresque_oiseau", 8811)
    _carve(poissons, "fresque_poissons", 8812)
    _carve(soleil, "fresque_soleil", 8813)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "fresques":
        fresques()
    else:
        pierre_moai()
        pukao()
        ahu()
        fresques()
