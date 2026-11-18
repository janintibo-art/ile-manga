"""V171 : les images des temples, des palais et des ateliers (Trois Soleils, Arcanelle, Port-Coutelas).
Faites ici ; CC0 1.0. Dossier www/assets/textures/beau171/.

  ciel_nout       le plafond des temples d'Égypte : le bleu de lapis et les étoiles d'or à cinq branches
                  (le corps de Nout, la déesse du ciel) ; se répète.
  natte           une natte de roseaux tressés (le petate des Mayas et des Aztèques, la natte des
                  scribes) ; se répète.
  rideau_etoiles  un velours de nuit, ses lunes et ses étoiles d'argent (la roulotte d'Agathe, la Tour
                  d'Astrelune) ; se répète.
  portrait_gouverneur  le portrait (très flatteur) du Gouverneur Lagrange, à la résidence de
                  Port-Coutelas : le tricorne, la moustache, l'habit rouge, l'écharpe, la médaille.

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_textures_v171.py [nom…]
"""
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

RACINE = Path(__file__).resolve().parents[2]
OUT = RACINE / "www" / "assets" / "textures" / "beau171"
SS = 2


def bruit(cell, seed, n):
    """Un bruit de valeur qui se répète (n × n pixels, cell cases)."""
    r = np.random.default_rng(seed)
    g = r.random((cell + 1, cell + 1))
    g[cell, :] = g[0, :]
    g[:, cell] = g[:, 0]
    t = np.linspace(0, cell, n, endpoint=False)
    i0 = np.floor(t).astype(int)
    f = t - i0
    f = f * f * (3 - 2 * f)
    a = g[np.ix_(i0, i0)]
    b = g[np.ix_(i0, i0 + 1)]
    c = g[np.ix_(i0 + 1, i0)]
    d = g[np.ix_(i0 + 1, i0 + 1)]
    fy = f[:, None]
    fx = f[None, :]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def fbm(cell, oct_, seed, n):
    s = bruit(cell, seed, n)
    amp = tot = 1.0
    for o in range(1, oct_):
        amp *= 0.5
        s = s + amp * bruit(cell * 2 ** o, seed + o * 13, n)
        tot += amp
    return s / tot


def vers_image(c):
    return Image.fromarray((np.clip(c, 0, 1) * 255).round().astype(np.uint8))


def sauver(nom, img):
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / f"{nom}.png", optimize=True)
    print("  ", nom, img.size)


def etoile(d, cx, cy, r, col, branches=5, creux=0.42, rot=-math.pi / 2):
    pts = []
    for k in range(branches * 2):
        a = rot + math.pi * k / branches
        rr = r if k % 2 == 0 else r * creux
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    d.polygon(pts, fill=col)


def ciel_nout():
    n = 512
    base = np.array([18, 34, 92], float) / 255.0
    v = fbm(4, 4, 171, n)[..., None]
    g = np.random.default_rng(3).random((n, n))[..., None]
    c = base * (0.8 + 0.4 * v) * (0.96 + 0.08 * g)
    img = vers_image(c).resize((n * SS, n * SS), Image.BICUBIC).convert("RGBA")
    calque = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(calque)
    pas = n * SS / 4
    for j in range(4):
        for i in range(4):
            cx = (i + 0.5 + (0.5 if j % 2 else 0.0)) * pas
            cy = (j + 0.5) * pas
            for ox in (-n * SS, 0, n * SS):
                x = cx + ox
                etoile(d, x, cy, pas * 0.3, (228, 182, 72, 255), 5, 0.36)
                etoile(d, x, cy, pas * 0.22, (250, 210, 110, 255), 5, 0.36)
    calque = calque.filter(ImageFilter.GaussianBlur(0.8))
    # l'usure de la peinture : par endroits, l'or s'efface
    use = fbm(8, 3, 9, n * SS)
    a = np.asarray(calque, float)
    a[..., 3] *= np.clip(0.8 + (use - 0.4) * 1.5, 0.72, 1.0)
    calque = Image.fromarray(a.astype(np.uint8))
    img.alpha_composite(calque)
    sauver("ciel_nout", img.convert("RGB").resize((n, n), Image.LANCZOS))


def natte():
    n = 512
    img = np.zeros((n, n, 3))
    bandes = 16
    w = n / bandes
    paille = np.array([0.82, 0.68, 0.42])
    sombre = np.array([0.55, 0.4, 0.22])
    rouge = np.array([0.62, 0.22, 0.14])
    yy, xx = np.mgrid[0:n, 0:n]
    bx = (xx // w).astype(int)
    by = (yy // w).astype(int)
    fx = (xx % w) / w
    fy = (yy % w) / w
    # un sergé : chaque brin passe sur deux, sous deux, décalé d'un à chaque rang
    dessus_h = ((bx + by) // 2) % 2 == 0
    fibre = np.where(dessus_h, np.sin(fy * math.pi), np.sin(fx * math.pi))
    stries = np.where(dessus_h, 0.5 + 0.5 * np.sin(yy * 0.9), 0.5 + 0.5 * np.sin(xx * 0.9))
    col = paille[None, None, :] * np.ones((n, n, 1))
    # quelques brins teints (le motif de la natte)
    teint_h = (by % 8 == 3)
    teint_v = (bx % 8 == 3)
    col = np.where((dessus_h & teint_h)[..., None], rouge, col)
    col = np.where((~dessus_h & teint_v)[..., None], sombre, col)
    v = fbm(8, 3, 21, n)[..., None]
    lum = (0.55 + 0.45 * fibre)[..., None] * (0.9 + 0.1 * stries[..., None]) * (0.85 + 0.3 * v)
    img = col * lum
    sauver("natte", vers_image(img).filter(ImageFilter.GaussianBlur(0.5)))


def rideau_etoiles():
    n = 512
    base = np.array([40, 22, 66], float) / 255.0
    yy = np.mgrid[0:n, 0:n][1]
    plis = 0.82 + 0.18 * np.sin(yy / n * math.pi * 2 * 6) ** 2
    v = fbm(4, 3, 77, n)
    c = base * (plis * (0.85 + 0.3 * v))[..., None]
    img = vers_image(c).resize((n * SS, n * SS), Image.BICUBIC).convert("RGBA")
    calque = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(calque)
    rng = np.random.default_rng(171)
    N = n * SS
    argent = (222, 226, 240, 255)
    for k in range(26):
        x, y = rng.random() * N, rng.random() * N
        r = (0.012 + 0.02 * rng.random()) * N
        for ox in (-N, 0, N):
            for oy in (-N, 0, N):
                etoile(d, x + ox, y + oy, r, argent, 5 if k % 3 else 4, 0.42 if k % 3 else 0.3, rng.random())
    for k in range(5):
        x, y = rng.random() * N, rng.random() * N
        r = (0.045 + 0.02 * rng.random()) * N
        for ox in (-N, 0, N):
            for oy in (-N, 0, N):
                d.ellipse([x + ox - r, y + oy - r, x + ox + r, y + oy + r], fill=(236, 214, 140, 255))
                d.ellipse([x + ox - r * 0.55, y + oy - r * 1.05, x + ox + r * 1.4, y + oy + r * 0.85], fill=(0, 0, 0, 0))
    calque = calque.filter(ImageFilter.GaussianBlur(0.7))
    img.alpha_composite(calque)
    sauver("rideau_etoiles", img.convert("RGB").resize((n, n), Image.LANCZOS))


def portrait_gouverneur():
    w, h = 384, 512
    W, H = w * SS, h * SS
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.sqrt(((xx - w * 0.5) / w) ** 2 + ((yy - h * 0.42) / h) ** 2)
    v = fbm(4, 4, 5, max(w, h))[:h, :w]
    fond = np.array([0.24, 0.18, 0.1]) * (1.15 - d * 1.2)[..., None] * (0.85 + 0.3 * v[..., None])
    img = vers_image(fond).resize((W, H), Image.BICUBIC).convert("RGBA")
    dr = ImageDraw.Draw(img)
    S = SS

    def P(*c):
        return [x * S for x in c]

    # l'habit rouge, l'écharpe bleue, les épaulettes, le jabot, les boutons, la médaille
    dr.polygon(P(70, 512, 92, 330, 140, 300, 244, 300, 292, 330, 314, 512), fill=(150, 22, 26))
    dr.polygon(P(110, 512, 120, 380, 150, 330, 192, 316, 234, 330, 264, 380, 274, 512), fill=(170, 30, 32))
    dr.polygon(P(128, 312, 300, 512, 262, 512, 104, 336), fill=(40, 70, 150))
    for ex in (112, 272):
        dr.ellipse(P(ex - 42, 300, ex + 42, 336), fill=(220, 175, 60))
        for f in range(9):
            fx = ex - 36 + f * 9
            dr.line(P(fx, 330, fx + (f - 4) * 1.5, 362), fill=(200, 150, 40), width=4 * S)
    for k in range(6):
        y0 = 312 + k * 14
        dr.ellipse(P(192 - 30 + k * 2, y0, 192 + 30 - k * 2, y0 + 22), fill=(245, 242, 232), outline=(200, 196, 186), width=S)
    for b in range(4):
        dr.ellipse(P(176, 410 + b * 26, 186, 420 + b * 26), fill=(230, 190, 70))
    dr.ellipse(P(222, 380, 252, 410), fill=(232, 192, 64), outline=(160, 120, 30), width=2 * S)
    dr.polygon(P(230, 360, 244, 360, 248, 382, 226, 382), fill=(40, 70, 150))
    # la tête : le cou, le visage, les joues roses, les yeux contents d'eux, le nez, la moustache en crocs
    dr.rectangle(P(170, 260, 214, 312), fill=(226, 176, 140))
    dr.ellipse(P(132, 150, 252, 290), fill=(232, 184, 148))
    for cx in (160, 224):
        dr.ellipse(P(cx - 16, 228, cx + 16, 252), fill=(236, 140, 130))
    for cx in (166, 218):
        dr.ellipse(P(cx - 9, 200, cx + 9, 212), fill=(250, 248, 244))
        dr.ellipse(P(cx - 4, 201, cx + 4, 211), fill=(50, 34, 24))
        dr.arc(P(cx - 14, 188, cx + 14, 204), 200, 340, fill=(80, 50, 30), width=3 * S)
        dr.arc(P(cx - 10, 202, cx + 10, 216), 20, 160, fill=(170, 110, 90), width=2 * S)
    dr.polygon(P(192, 206, 184, 240, 200, 240), fill=(214, 150, 120))
    dr.ellipse(P(182, 234, 204, 246), fill=(212, 140, 112))
    for sx in (-1, 1):
        pts = []
        for t in range(13):
            a = t / 12.0
            x = 192 + sx * (6 + 46 * a)
            y = 250 + 10 * math.sin(a * math.pi) - 26 * a ** 3
            pts.append((x * S, y * S))
        dr.line(pts, fill=(92, 56, 30), width=9 * S, joint="curve")
        dr.ellipse(P(192 + sx * 52 - 6, 222 - 6, 192 + sx * 52 + 6, 222 + 6), fill=(92, 56, 30))
    dr.arc(P(176, 252, 208, 270), 20, 160, fill=(150, 60, 50), width=3 * S)
    # la perruque poudrée (les rouleaux sur les côtés) et le grand tricorne bordé d'or
    for sx in (-1, 1):
        for r in range(3):
            cx = 192 + sx * 64
            cy = 200 + r * 30
            dr.ellipse(P(cx - 20, cy - 14, cx + 20, cy + 14), fill=(236, 234, 228), outline=(200, 198, 192), width=S)
    dr.polygon(P(78, 168, 192, 70, 306, 168, 268, 150, 192, 158, 116, 150), fill=(28, 24, 26))
    dr.polygon(P(110, 156, 192, 98, 274, 156, 192, 140), fill=(40, 34, 36))
    dr.line(P(78, 168, 116, 150, 192, 158, 268, 150, 306, 168), fill=(222, 180, 64), width=6 * S, joint="curve")
    dr.ellipse(P(178, 112, 206, 140), fill=(200, 30, 36), outline=(222, 180, 64), width=3 * S)
    for f in range(7):
        dr.line(P(196, 120, 222 + f * 6, 70 + f * 4), fill=(245, 245, 240), width=3 * S)
    # le cartouche doré
    dr.rectangle(P(62, 468, 322, 502), fill=(196, 156, 58), outline=(120, 88, 30), width=3 * S)
    img = img.filter(ImageFilter.GaussianBlur(1.6))
    try:
        from PIL import ImageFont
        f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf", 12 * S)
        ImageDraw.Draw(img).text((192 * S, 485 * S), "S. E. LE GOUVERNEUR LAGRANGE", font=f, fill=(70, 46, 16), anchor="mm")
    except OSError:
        pass
    a = np.asarray(img.convert("RGB"), float) / 255.0
    a = a.reshape(h, S, w, S, 3).mean(axis=(1, 3))
    toile = fbm(64, 2, 13, max(w, h))[:h, :w][..., None]
    a = a * (0.94 + 0.12 * toile) * np.array([1.03, 1.0, 0.9])
    sauver("portrait_gouverneur", vers_image(a))


TOUT = {"ciel_nout": ciel_nout, "natte": natte, "rideau_etoiles": rideau_etoiles, "portrait_gouverneur": portrait_gouverneur}

if __name__ == "__main__":
    noms = sys.argv[1:] or list(TOUT)
    for nm in noms:
        TOUT[nm]()
