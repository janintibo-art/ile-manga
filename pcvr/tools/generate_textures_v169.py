"""V169 : les images des maisons d'Al Dente, de l'Île Crayonnée et de Sombreval (faites ici ; CC0 1.0).
Dossier www/assets/textures/beau169/.

  pa_icone        l'icône du Grand Spaghetti Volant (le fond d'or, l'arc de ciel, la pelote de
                  spaghettis, les deux boulettes, les yeux au bout de leurs tiges, le Mont Bolognaise).
  pa_nature_morte une nature morte d'Al Dente (les tomates et leur calice, l'ail, le basilic, la
                  bouteille d'huile, la botte de spaghettis, sur le bord d'une table).
  pa_volcan       le Mont Bolognaise vu du Borgo (la sauce qui coule, le panache, la mer, le temple).
  cr_affiche      l'affiche du Conseil : « Où sont passées nos couleurs ? » (à l'encre, sur papier).
  cr_dessin       un dessin d'enfant (l'arbre-maison, l'arc-en-ciel, le soleil, la famille).
  cr_carte        la carte de l'île du Conseil (le rivage, les chemins, la clairière, le mont, l'étang,
                  et neuf ronds numérotés : la place des godets).
  sv_decolle      une plaque de papier peint qui se décolle (le plâtre dessous, le bord déchiré, son
                  ombre ; transparent autour).
  sv_taches       des auréoles d'humidité (transparentes).
  sv_calendrier   la page de novembre, un samedi entouré de rouge.
  sv_dessins      des dessins d'enfant punaisés (le château aux fenêtres rouges, la maison et le chat).
  sv_horaires     le tableau des départs de la gare (tous les trains supprimés).
  sv_plan         le plan de la ville annoté par Solène.
  sv_avant        Sombreval avant le comte (un tableau : le beffroi, les maisons, les lanternes).
  sv_portrait     un portrait de famille (les deux parents) en silhouettes découpées, dans son ovale.

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_textures_v169.py [nom…]
"""
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

RACINE = Path(__file__).resolve().parents[2]
OUT = RACINE / "www" / "assets" / "textures" / "beau169"
FONTS = Path("/usr/share/fonts/truetype/dejavu")
SS = 2          # suréchantillonnage (on dessine en grand, on réduit : des bords doux)


def police(nom, taille):
    try:
        return ImageFont.truetype(str(FONTS / nom), int(taille * SS))
    except OSError:
        return ImageFont.load_default()


def valeur(cx, seed, w, h, cy=None):
    cy = cy or cx
    r = np.random.default_rng(seed)
    g = r.random((cy + 1, cx + 1))
    y = np.linspace(0, cy, h, endpoint=False)
    x = np.linspace(0, cx, w, endpoint=False)
    y0 = np.floor(y).astype(int)
    x0 = np.floor(x).astype(int)
    fy = (y - y0)[:, None]
    fx = (x - x0)[None, :]
    fy = fy * fy * (3 - 2 * fy)
    fx = fx * fx * (3 - 2 * fx)
    a = g[np.ix_(y0, x0)]
    b = g[np.ix_(y0, x0 + 1)]
    c = g[np.ix_(y0 + 1, x0)]
    d = g[np.ix_(y0 + 1, x0 + 1)]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def fbm(cell, oct_, seed, w, h):
    s = np.zeros((h, w))
    amp = tot = 1.0
    s += valeur(cell, seed, w, h)
    for o in range(1, oct_):
        amp *= 0.5
        s += amp * valeur(cell * 2 ** o, seed + o * 17, w, h)
        tot += amp
    return s / tot


def toile(w, h, base, seed, grain=0.06):
    """Un fond peint : la couleur de base, des variations lentes, le grain de la toile."""
    n = fbm(4, 4, seed, w, h)
    g = np.random.default_rng(seed + 5).random((h, w))
    c = np.array(base, float)[None, None, :] / 255.0 * (0.86 + 0.28 * n[..., None])
    c = c * (1.0 - grain * 0.5 + grain * g[..., None])
    return c


def vers_image(c):
    return Image.fromarray((np.clip(c, 0, 1) * 255).round().astype(np.uint8))


def peinture(img, seed, force=0.05):
    """Un peu de matière : flou léger, bruit coloré, vernis jauni."""
    a = np.asarray(img.convert("RGB"), float) / 255.0
    h, w = a.shape[:2]
    n = fbm(6, 3, seed, w, h)[..., None]
    a = a * (1.0 - force + 2 * force * n)
    a = a * np.array([1.02, 1.0, 0.94])
    return vers_image(a).filter(ImageFilter.GaussianBlur(0.6))


def grand(w, h, fond=(0, 0, 0, 0), mode="RGBA"):
    return Image.new(mode, (w * SS, h * SS), fond)


def petit(img, w, h):
    return img.resize((w, h), Image.LANCZOS)


def sauver(nom, img):
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / f"{nom}.png", optimize=True)
    print("  ", nom, img.size)


def P(*v):
    return [x * SS for x in v]


# =================================================================== Al Dente

def pa_icone():
    w, h = 512, 680
    fond = toile(w, h, (196, 150, 62), 1690, 0.1)
    # l'or : des reflets, un poinçonnage
    yy, xx = np.mgrid[0:h, 0:w]
    reflet = 0.85 + 0.25 * np.exp(-((xx - w * 0.35) ** 2 + (yy - h * 0.25) ** 2) / (2 * 160.0 ** 2))
    fond = fond * reflet[..., None]
    base = vers_image(fond).resize((w * SS, h * SS))
    d = ImageDraw.Draw(base, "RGBA")
    # l'arc de ciel
    ax0, ay0, ax1, ay1 = 70, 60, w - 70, h - 120
    d.rectangle(P(ax0, ay0 + 186, ax1, ay1), fill=(52, 86, 140))
    d.ellipse(P(ax0, ay0, ax1, ay0 + 372), fill=(52, 86, 140))
    for i in range(40):
        t = i / 40.0
        col = (int(52 + 120 * t), int(86 + 110 * t), int(140 + 80 * t), 18)
        d.rectangle(P(ax0, ay0 + 120 + t * (ay1 - ay0 - 120), ax1, ay1), fill=col)
    d.ellipse(P(ax0, ay0, ax1, ay0 + 372), outline=(120, 82, 30), width=6 * SS)
    d.line(P(ax0, ay0 + 186, ax0, ay1), fill=(120, 82, 30), width=6 * SS)
    d.line(P(ax1, ay0 + 186, ax1, ay1), fill=(120, 82, 30), width=6 * SS)
    # le Mont Bolognaise, en bas, et sa sauce
    d.polygon(P(ax0, ay1, 150, 430, 210, 400, 300, 405, 360, 432, ax1, ay1), fill=(118, 70, 46))
    d.polygon(P(210, 400, 300, 405, 290, 420, 222, 418), fill=(200, 40, 28))
    for k, x in enumerate([235, 255, 275]):
        d.line(P(x, 415, x - 20 + k * 18, ay1), fill=(190, 36, 26), width=7 * SS)
    # la pelote de spaghettis (beaucoup de boucles), au centre
    rng = np.random.default_rng(16901)
    cx, cy = w * 0.5, 270
    for k in range(150):
        a0 = rng.uniform(0, math.tau)
        rr = rng.uniform(25, 95)
        pts = []
        for s in range(18):
            a = a0 + s * 0.32
            r2 = rr * (0.7 + 0.3 * math.sin(s * 0.9 + k))
            pts.append((cx + math.cos(a) * r2 * 1.25 + rng.normal(0, 3), cy + math.sin(a) * r2 * 0.8 + rng.normal(0, 3)))
        d.line([(x * SS, y * SS) for x, y in pts], fill=(150, 112, 40, 255), width=int(5.5 * SS), joint="curve")
        d.line([(x * SS, y * SS) for x, y in pts], fill=(246, 214, 120, 255), width=int(3.4 * SS), joint="curve")
    # les spaghettis qui pendent (les « appendices »)
    for k in range(9):
        x0 = cx + rng.uniform(-90, 90)
        pts = [(x0 + 12 * math.sin(t * 0.5 + k), cy + 50 + t * 9) for t in range(14)]
        d.line([(x * SS, y * SS) for x, y in pts], fill=(150, 112, 40), width=int(5 * SS), joint="curve")
        d.line([(x * SS, y * SS) for x, y in pts], fill=(246, 214, 120), width=int(3 * SS), joint="curve")
    # les deux boulettes
    for bx in (cx - 62, cx + 62):
        d.ellipse(P(bx - 34, cy - 40, bx + 34, cy + 26), fill=(98, 52, 30))
        d.ellipse(P(bx - 22, cy - 32, bx + 4, cy - 12), fill=(150, 92, 58))
        for _ in range(14):
            px, py = bx + rng.uniform(-24, 24), cy - 7 + rng.uniform(-24, 20)
            d.ellipse(P(px - 2, py - 2, px + 2, py + 2), fill=(70, 34, 20))
    # les yeux au bout de leurs tiges
    for sx in (-1, 1):
        ex, ey = cx + sx * 40, cy - 150
        d.line(P(cx + sx * 12, cy - 60, ex, ey + 18), fill=(150, 112, 40), width=7 * SS)
        d.line(P(cx + sx * 12, cy - 60, ex, ey + 18), fill=(246, 214, 120), width=4 * SS)
        d.ellipse(P(ex - 22, ey - 22, ex + 22, ey + 22), fill=(250, 248, 240), outline=(60, 40, 20), width=2 * SS)
        d.ellipse(P(ex - 9 + sx * 4, ey - 6, ex + 9 + sx * 4, ey + 12), fill=(20, 16, 14))
        d.ellipse(P(ex - 3 + sx * 4, ey - 3, ex + 2 + sx * 4, ey + 2), fill=(255, 255, 255))
    # l'auréole
    d.ellipse(P(cx - 150, cy - 210, cx + 150, cy + 90), outline=(255, 226, 140, 120), width=3 * SS)
    # le cadre peint, l'inscription
    d.rectangle(P(18, 18, w - 18, h - 18), outline=(110, 74, 24), width=8 * SS)
    d.rectangle(P(34, 34, w - 34, h - 34), outline=(230, 190, 90), width=3 * SS)
    f = police("DejaVuSerif-Bold.ttf", 30)
    t = "RAMEN"
    tw = d.textlength(t, font=f)
    d.text(((w * SS - tw) / 2, (h - 100) * SS), t, font=f, fill=(90, 50, 14))
    sauver("pa_icone", peinture(petit(base, w, h), 16902, 0.06))


def tomate(d, x, y, r, rng):
    d.ellipse(P(x - r, y - r * 0.9, x + r, y + r * 0.9), fill=(178, 28, 20))
    d.ellipse(P(x - r * 0.85, y - r * 0.8, x + r * 0.55, y + r * 0.5), fill=(214, 46, 30))
    d.ellipse(P(x - r * 0.55, y - r * 0.62, x - r * 0.1, y - r * 0.25), fill=(250, 150, 120))
    for k in range(5):
        a = k * math.tau / 5 + rng.uniform(-0.2, 0.2)
        d.line(P(x, y - r * 0.82, x + math.cos(a) * r * 0.42, y - r * 0.82 + math.sin(a) * r * 0.22), fill=(40, 96, 30), width=4 * SS)
    d.line(P(x, y - r * 0.82, x + 3, y - r * 1.1), fill=(40, 96, 30), width=4 * SS)


def pa_nature_morte():
    w, h = 640, 480
    fond = toile(w, h, (58, 40, 28), 1693, 0.08)
    yy, xx = np.mgrid[0:h, 0:w]
    fond *= (0.7 + 0.5 * np.exp(-((xx - w * 0.45) ** 2 + (yy - h * 0.35) ** 2) / (2 * 220.0 ** 2)))[..., None]
    base = vers_image(fond).resize((w * SS, h * SS))
    d = ImageDraw.Draw(base, "RGBA")
    rng = np.random.default_rng(1694)
    # le bord de la table
    d.rectangle(P(0, 300, w, h), fill=(110, 72, 44))
    d.rectangle(P(0, 300, w, 312), fill=(150, 104, 66))
    for k in range(30):
        y = 316 + k * 6
        d.line(P(0, y, w, y + rng.uniform(-3, 3)), fill=(96, 62, 38, 90), width=SS)
    # la bouteille d'huile
    d.rectangle(P(420, 110, 470, 300), fill=(150, 150, 40, 220))
    d.polygon(P(420, 110, 470, 110, 455, 70, 435, 70), fill=(150, 150, 40, 220))
    d.rectangle(P(436, 40, 454, 72), fill=(130, 130, 40))
    d.rectangle(P(434, 30, 456, 42), fill=(90, 60, 30))
    d.rectangle(P(428, 120, 440, 290), fill=(230, 220, 120, 90))
    d.rectangle(P(424, 170, 466, 230), fill=(232, 224, 196))
    d.text(P(430, 190), "OLIO", font=police("DejaVuSerif-Bold.ttf", 12), fill=(70, 50, 30))
    # la botte de spaghettis, couchée
    for k in range(40):
        y = 286 + rng.uniform(-10, 10)
        d.line(P(70, y, 330, y + rng.uniform(-6, 6)), fill=(232, 200, 120), width=2 * SS)
    d.rectangle(P(190, 274, 204, 300), fill=(40, 90, 50))
    # l'ail
    for gx, gy in [(370, 280), (395, 290)]:
        d.ellipse(P(gx - 26, gy - 22, gx + 26, gy + 18), fill=(236, 226, 206))
        for k in range(4):
            d.arc(P(gx - 20 + k * 10, gy - 22, gx - 4 + k * 10, gy + 18), 200, 340, fill=(190, 170, 150), width=2 * SS)
        d.line(P(gx, gy - 22, gx + 6, gy - 40), fill=(210, 200, 170), width=4 * SS)
    # les tomates
    for tx, ty, tr in [(150, 250, 44), (230, 262, 38), (100, 284, 34), (300, 276, 30)]:
        tomate(d, tx, ty, tr, rng)
    # le basilic
    for k in range(9):
        lx, ly = 480 + rng.uniform(-40, 60), 290 + rng.uniform(-30, 10)
        a = rng.uniform(-0.8, 0.8)
        pts = [(lx + math.cos(a) * 26 * t - math.sin(a) * 10 * math.sin(t * math.pi), ly + math.sin(a) * 26 * t + math.cos(a) * 10 * math.sin(t * math.pi)) for t in np.linspace(0, 1, 9)]
        pts2 = [(lx + math.cos(a) * 26 * t + math.sin(a) * 10 * math.sin(t * math.pi), ly + math.sin(a) * 26 * t - math.cos(a) * 10 * math.sin(t * math.pi)) for t in np.linspace(1, 0, 9)]
        d.polygon([(x * SS, y * SS) for x, y in pts + pts2], fill=(46, 120, 40))
    sauver("pa_nature_morte", peinture(petit(base, w, h), 1695, 0.07))


def pa_volcan():
    w, h = 640, 480
    yy = np.linspace(0, 1, h)[:, None, None]
    ciel = np.array([0.42, 0.62, 0.9]) * (1 - yy) + np.array([0.86, 0.9, 0.92]) * yy
    fond = np.broadcast_to(ciel, (h, w, 3)).copy() * (0.94 + 0.08 * fbm(5, 3, 1696, w, h)[..., None])
    base = vers_image(fond).resize((w * SS, h * SS))
    d = ImageDraw.Draw(base, "RGBA")
    rng = np.random.default_rng(1697)
    # le panache
    for k in range(18):
        x, y, r = 330 + k * 6 + rng.uniform(-8, 8), 110 - k * 6, 22 + k * 2.4
        d.ellipse(P(x - r, y - r * 0.7, x + r, y + r * 0.7), fill=(236, 230, 226, 150))
    # le volcan
    d.polygon(P(60, 340, 270, 130, 390, 126, 600, 340), fill=(124, 84, 60))
    d.polygon(P(270, 130, 390, 126, 360, 150, 300, 150), fill=(196, 40, 26))
    for k in range(5):
        x0 = 290 + k * 18
        pts = [(x0 + 18 * math.sin(t * 0.7 + k), 140 + t * 16) for t in range(13)]
        d.line([(x * SS, y * SS) for x, y in pts], fill=(200, 42, 28), width=int((7 - k * 0.6) * SS), joint="curve")
    for k in range(40):
        x = rng.uniform(80, 580)
        y = rng.uniform(200, 330)
        d.line(P(x, y, x + rng.uniform(-30, 30), y + rng.uniform(4, 14)), fill=(96, 62, 44, 120), width=3 * SS)
    # la mer, les champs, le temple-passoire
    d.rectangle(P(0, 380, w, h), fill=(48, 110, 160))
    for k in range(25):
        y = 390 + rng.uniform(0, 80)
        x = rng.uniform(0, w)
        d.line(P(x, y, x + rng.uniform(20, 60), y), fill=(200, 226, 240, 140), width=2 * SS)
    d.polygon(P(0, 330, 640, 330, 640, 385, 0, 385), fill=(196, 176, 92))
    for k in range(14):
        x = k * 48
        d.line(P(x, 334, x + 30, 382), fill=(176, 150, 70, 160), width=3 * SS)
    d.chord(P(420, 300, 520, 380), 180, 360, fill=(196, 200, 206))
    for k in range(18):
        a = math.pi + k * math.pi / 18
        d.ellipse(P(470 + math.cos(a) * 34 - 2, 340 + math.sin(a) * 26 - 2, 470 + math.cos(a) * 34 + 2, 340 + math.sin(a) * 26 + 2), fill=(90, 96, 104))
    d.rectangle(P(424, 338, 516, 346), fill=(150, 146, 140))
    sauver("pa_volcan", peinture(petit(base, w, h), 1698, 0.06))


# =================================================================== l'Île Crayonnée

def papier(w, h, seed):
    c = toile(w, h, (246, 242, 230), seed, 0.04)
    return vers_image(c).resize((w * SS, h * SS))


def trait(d, pts, ep=2.4, col=(28, 26, 24), rng=None):
    rng = rng or np.random.default_rng(1)
    q = [(x * SS + rng.normal(0, 0.6 * SS), y * SS + rng.normal(0, 0.6 * SS)) for x, y in pts]
    d.line(q, fill=col, width=int(ep * SS), joint="curve")


def cr_affiche():
    w, h = 400, 560
    base = papier(w, h, 1699)
    d = ImageDraw.Draw(base, "RGBA")
    rng = np.random.default_rng(1700)
    d.rectangle(P(14, 14, w - 14, h - 14), outline=(30, 28, 26), width=3 * SS)
    f = police("DejaVuSerif-Bold.ttf", 44)
    for i, ligne in enumerate(["OÙ SONT", "PASSÉES", "NOS", "COULEURS ?"]):
        tw = d.textlength(ligne, font=f)
        d.text(((w * SS - tw) / 2, (40 + i * 52) * SS), ligne, font=f, fill=(26, 24, 22))
    # la palette et ses neuf godets vides
    cx, cy = w / 2, 370
    pts = [(cx + math.cos(a) * 130 * (1 + 0.08 * math.sin(3 * a)), cy + math.sin(a) * 78) for a in np.linspace(0, math.tau, 60)]
    trait(d, pts + [pts[0]], 3.2, rng=rng)
    d.ellipse(P(cx + 60, cy + 10, cx + 96, cy + 40), outline=(26, 24, 22), width=3 * SS)
    for k in range(9):
        a = math.pi * 1.1 + k * math.pi * 0.95 / 8
        gx, gy = cx + math.cos(a) * 92, cy + 6 + math.sin(a) * 50
        d.ellipse(P(gx - 13, gy - 10, gx + 13, gy + 10), outline=(26, 24, 22), width=2 * SS)
        d.text(P(gx - 4, gy - 8), str(k + 1), font=police("DejaVuSans.ttf", 12), fill=(26, 24, 22))
    f2 = police("DejaVuSerif-Italic.ttf", 17)
    for i, ligne in enumerate(["Réunion extraordinaire du Conseil :", "tout le monde cherche partout !"]):
        tw = d.textlength(ligne, font=f2)
        d.text(((w * SS - tw) / 2, (472 + i * 24) * SS), ligne, font=f2, fill=(36, 34, 30))
    sauver("cr_affiche", petit(base, w, h))


def cr_dessin():
    w, h = 512, 384
    base = papier(w, h, 1701)
    d = ImageDraw.Draw(base, "RGBA")
    rng = np.random.default_rng(1702)

    def crayon(pts, col, ep=7):
        for k in range(3):
            q = [(x + rng.normal(0, 1.5), y + rng.normal(0, 1.5)) for x, y in pts]
            d.line([(x * SS, y * SS) for x, y in q], fill=col + (150,), width=int(ep * SS * 0.6), joint="curve")

    # l'arc-en-ciel
    for i, col in enumerate([(220, 40, 40), (240, 140, 30), (240, 210, 40), (60, 170, 60), (50, 110, 210), (130, 70, 180)]):
        r = 190 - i * 12
        pts = [(256 + math.cos(a) * r, 250 - math.sin(a) * r * 0.85) for a in np.linspace(0.15, math.pi - 0.15, 30)]
        crayon(pts, col, 9)
    # le soleil
    crayon([(440 + math.cos(a) * 30, 60 + math.sin(a) * 30) for a in np.linspace(0, math.tau, 30)], (240, 190, 30), 8)
    for k in range(10):
        a = k * math.tau / 10
        crayon([(440 + math.cos(a) * 40, 60 + math.sin(a) * 40), (440 + math.cos(a) * 58, 60 + math.sin(a) * 58)], (240, 190, 30), 5)
    # l'arbre et sa maison ronde
    crayon([(110, 360), (116, 200)], (120, 80, 40), 14)
    crayon([(90 + math.cos(a) * 70, 160 + math.sin(a) * 55) for a in np.linspace(0, math.tau, 30)], (60, 160, 60), 10)
    crayon([(100, 175), (100, 140), (130, 120), (160, 140), (160, 175), (100, 175)], (200, 60, 50), 6)
    # la famille (trois bonshommes qui se tiennent la main)
    for k, (x, col) in enumerate([(280, (50, 90, 200)), (330, (220, 60, 120)), (370, (240, 150, 30))]):
        s = 1.0 if k < 2 else 0.7
        crayon([(x + math.cos(a) * 12 * s, 270 * 1 + (1 - s) * 40 + math.sin(a) * 12 * s) for a in np.linspace(0, math.tau, 16)], (40, 40, 40), 4)
        crayon([(x, 282 + (1 - s) * 40), (x, 320)], col, 6)
        crayon([(x - 14, 300), (x + 14, 300)], col, 4)
        crayon([(x, 320), (x - 10, 350)], (40, 40, 40), 4)
        crayon([(x, 320), (x + 10, 350)], (40, 40, 40), 4)
    # l'herbe
    for k in range(40):
        x = rng.uniform(10, 500)
        crayon([(x, 372), (x + rng.uniform(-4, 4), 352)], (60, 160, 60), 3)
    sauver("cr_dessin", petit(base, w, h))


def cr_carte():
    w = h = 512
    base = papier(w, h, 1703)
    d = ImageDraw.Draw(base, "RGBA")
    rng = np.random.default_rng(1704)
    # la carte est ronde : un double cercle, la rose des vents
    d.ellipse(P(6, 6, w - 6, h - 6), outline=(40, 34, 28), width=3 * SS)
    # le rivage (un rond irrégulier, de 175 m ; l'échelle : celle des godets, 1/190 × 0,85 sur 0,92)
    sc = 256 / 190.0 * 0.85 / 0.92

    def pt(x, z):
        return (256 + x * sc, 256 + z * sc)
    cote = []
    for a in np.linspace(0, math.tau, 90):
        rr = 172 + 10 * math.sin(3 * a + 1) + 7 * math.sin(7 * a)
        cote.append(pt(math.cos(a) * rr, math.sin(a) * rr))
    trait(d, cote + [cote[0]], 3.0, rng=rng)
    for k in range(60):
        a = k * math.tau / 60
        rr = 180 + 10 * math.sin(3 * a + 1)
        x0, y0 = pt(math.cos(a) * rr, math.sin(a) * rr)
        x1, y1 = pt(math.cos(a) * (rr + 8), math.sin(a) * (rr + 8))
        d.line(P(x0, y0, x1, y1), fill=(60, 54, 46), width=SS)
    # le Mont Fusain (des hachures), l'étang, la clairière et ses quatre chênes, les chemins
    mx, my = pt(-6, -90)
    for k in range(14):
        a = math.pi + k * math.pi / 13
        d.line(P(mx + math.cos(a) * 30, my + math.sin(a) * 22 + 20, mx + math.cos(a) * 10, my + math.sin(a) * 6), fill=(40, 34, 28), width=2 * SS)
    ex, ey = pt(40, -24)
    d.ellipse(P(ex - 26, ey - 16, ex + 26, ey + 16), outline=(40, 34, 28), width=2 * SS)
    for k in range(3):
        d.line(P(ex - 14 + k * 6, ey - 4 + k * 5, ex + 4 + k * 6, ey - 4 + k * 5), fill=(60, 54, 46), width=SS)
    cx, cy = pt(-40, 34)
    for k in range(4):
        a = k * math.tau / 4 + 0.3
        tx, ty = cx + math.cos(a) * 18, cy + math.sin(a) * 18
        d.ellipse(P(tx - 7, ty - 7, tx + 7, ty + 7), outline=(40, 34, 28), width=2 * SS)
    for a0, a1 in [((-40, 34), (4, 128)), ((-40, 34), (40, -24)), ((-40, 34), (-100, 45)), ((-40, 34), (-6, -90))]:
        p0, p1 = pt(*a0), pt(*a1)
        n = 14
        for k in range(n):
            if k % 2:
                continue
            t0, t1 = k / n, (k + 1) / n
            d.line(P(p0[0] + (p1[0] - p0[0]) * t0, p0[1] + (p1[1] - p0[1]) * t0, p0[0] + (p1[0] - p0[0]) * t1, p0[1] + (p1[1] - p0[1]) * t1), fill=(60, 54, 46), width=2 * SS)
    # la place des neuf godets (des ronds pointillés, numérotés)
    pots = [(40, -24), (-100, 45), (78, 80), (4, 128), (-40, 34), (-6, -90), (22, -56), (112, 12), (-78, 102)]
    f = police("DejaVuSans-Bold.ttf", 13)
    for i, (x, z) in enumerate(pots):
        px, py = pt(x, z)
        for k in range(16):
            a = k * math.tau / 16
            d.arc(P(px - 17, py - 17, px + 17, py + 17), math.degrees(a), math.degrees(a) + 12, fill=(40, 34, 28), width=2 * SS)
        d.text(((px + 18) * SS, (py - 20) * SS), str(i + 1), font=f, fill=(30, 26, 22))
    # la rose des vents
    rx, ry = 430, 90
    d.polygon(P(rx, ry - 30, rx + 7, ry, rx, ry + 30, rx - 7, ry), outline=(40, 34, 28), width=2 * SS)
    d.polygon(P(rx - 30, ry, rx, ry - 7, rx + 30, ry, rx, ry + 7), outline=(40, 34, 28), width=2 * SS)
    d.text(P(rx - 5, ry - 52), "N", font=f, fill=(30, 26, 22))
    sauver("cr_carte", petit(base, w, h))


# =================================================================== Sombreval

def sv_decolle():
    w = h = 512
    yy, xx = np.mgrid[0:h, 0:w] / float(w)
    # la forme : une déchirure irrégulière, plus haute que large, qui pend vers le bas
    n = fbm(4, 5, 1706, w, h)
    r = np.sqrt(((xx - 0.5) * 1.15) ** 2 + ((yy - 0.46) * 0.9) ** 2)
    forme = (0.36 - r) + (n - 0.5) * 0.22
    dedans = forme > 0.0
    # le plâtre : clair, lisse, quelques fissures fines et des restes de colle plus sombres
    pl = toile(w, h, (206, 198, 180), 1707, 0.03)
    fis = fbm(14, 3, 1708, w, h)
    pl *= (1.0 - 0.28 * (np.abs(fis - 0.5) < 0.006))[..., None]
    colle = fbm(8, 3, 1709, w, h)
    pl *= (0.94 + 0.06 * colle)[..., None]
    pl *= (1.0 - 0.1 * np.clip((colle - 0.6) * 4.0, 0, 1))[..., None]
    # l'ombre du papier soulevé, le long du bord
    ombre = np.clip(1.0 - forme / 0.045, 0, 1) * dedans
    pl *= (1.0 - 0.5 * ombre ** 1.5)[..., None]
    # le bord du papier : le dos (crème) d'une languette qui s'enroule, plus large en haut
    larg = 0.01 + 0.012 * np.clip(0.5 - yy, 0, 1)
    lisere = (forme > -larg) & (forme <= 0.0)
    rgb = np.where(lisere[..., None], np.array([0.88, 0.84, 0.72]) * (0.9 + 0.1 * n[..., None]), pl)
    alpha = np.where(dedans | lisere, 1.0, 0.0)
    img = np.dstack([np.clip(rgb, 0, 1), alpha])
    sauver("sv_decolle", Image.fromarray((img * 255).round().astype(np.uint8), "RGBA"))


def sv_taches():
    w = h = 512
    yy, xx = np.mgrid[0:h, 0:w] / float(w)
    a = np.zeros((h, w))
    rng = np.random.default_rng(1710)
    n = fbm(6, 4, 1711, w, h)
    for k in range(4):
        cx, cy, rr = rng.uniform(0.3, 0.7), rng.uniform(0.25, 0.55), rng.uniform(0.12, 0.26)
        d = np.sqrt(((xx - cx) * 1.0) ** 2 + ((yy - cy) * 1.3) ** 2) / rr + (n - 0.5) * 0.5
        anneau = np.exp(-((d - 1.0) ** 2) / 0.004) * 0.75 + np.clip(1.0 - d, 0, 1) * 0.28
        a = np.maximum(a, anneau)
    # les coulures vers le bas
    for k in range(6):
        x = rng.uniform(0.3, 0.7)
        col = np.exp(-((xx - x) ** 2) / 0.0004) * np.clip((yy - 0.45) / 0.3, 0, 1) * np.clip((0.95 - yy) / 0.2, 0, 1) * 0.35
        a = np.maximum(a, col)
    a = np.clip(a * (0.8 + 0.4 * n), 0, 0.85)
    rgb = np.ones((h, w, 3)) * np.array([0.36, 0.28, 0.16])
    img = np.dstack([rgb, a])
    sauver("sv_taches", Image.fromarray((img * 255).round().astype(np.uint8), "RGBA"))


def sv_calendrier():
    w, h = 300, 420
    base = papier(w, h, 1712)
    d = ImageDraw.Draw(base, "RGBA")
    # l'image du mois (le beffroi sous la neige, en gravure)
    d.rectangle(P(20, 20, w - 20, 150), fill=(196, 206, 214))
    d.rectangle(P(130, 40, 170, 150), fill=(110, 80, 70))
    d.polygon(P(124, 42, 176, 42, 150, 18), fill=(70, 70, 80))
    d.ellipse(P(138, 56, 162, 80), fill=(240, 236, 220))
    d.line(P(150, 68, 150, 58), fill=(20, 20, 20), width=2 * SS)
    for k in range(5):
        x = 30 + k * 52
        d.rectangle(P(x, 110 - (k % 2) * 14, x + 34, 150), fill=(150, 110, 90))
    d.rectangle(P(20, 140, w - 20, 150), fill=(250, 250, 250))
    f = police("DejaVuSerif-Bold.ttf", 26)
    t = "NOVEMBRE"
    d.text(((w * SS - d.textlength(t, font=f)) / 2, 158 * SS), t, font=f, fill=(40, 34, 30))
    fj = police("DejaVuSans-Bold.ttf", 11)
    for i, j in enumerate("LMMJVSD"):
        d.text(P(30 + i * 36, 196), j, font=fj, fill=(120, 30, 26) if j == "D" else (60, 56, 50))
    fn = police("DejaVuSans.ttf", 14)
    jour = 1
    for row in range(5):
        for col in range(7):
            if row == 0 and col < 4:
                continue
            if jour > 30:
                break
            x, y = 28 + col * 36, 218 + row * 34
            d.text(P(x, y), str(jour), font=fn, fill=(40, 36, 32))
            if jour == 16:
                d.ellipse(P(x - 9, y - 6, x + 26, y + 22), outline=(190, 30, 24), width=3 * SS)
                d.text(P(x - 20, y + 22), "Léa 8 ans !", font=police("DejaVuSans-Oblique.ttf", 11), fill=(190, 30, 24))
            jour += 1
    sauver("sv_calendrier", petit(base, w, h))


def sv_dessins():
    w, h = 600, 400
    base = vers_image(toile(w, h, (150, 120, 90), 1713, 0.1)).resize((w * SS, h * SS))
    d = ImageDraw.Draw(base, "RGBA")
    rng = np.random.default_rng(1714)

    def crayon(pts, col, ep=6):
        for k in range(2):
            q = [(x + rng.normal(0, 1.2), y + rng.normal(0, 1.2)) for x, y in pts]
            d.line([(x * SS, y * SS) for x, y in q], fill=col + (170,), width=int(ep * SS * 0.6), joint="curve")

    # deux feuilles
    for (x0, y0, x1, y1) in [(20, 30, 300, 380), (310, 50, 585, 370)]:
        d.rectangle(P(x0 + 4, y0 + 4, x1 + 4, y1 + 4), fill=(60, 46, 34, 120))
        d.rectangle(P(x0, y0, x1, y1), fill=(244, 240, 228))
        d.ellipse(P((x0 + x1) / 2 - 5, y0 + 6, (x0 + x1) / 2 + 5, y0 + 16), fill=(190, 30, 24))
    # 1 : le château sur sa colline, les fenêtres rouges, les chauves-souris, la lune
    crayon([(40, 340), (100, 250), (170, 230), (240, 250), (290, 340)], (90, 140, 70), 8)
    crayon([(110, 250), (110, 150), (230, 150), (230, 250)], (90, 90, 100), 7)
    for tx in (110, 170, 230):
        crayon([(tx - 18, 160), (tx - 18, 110), (tx + 18, 110), (tx + 18, 160)], (90, 90, 100), 6)
        crayon([(tx - 22, 110), (tx, 80), (tx + 22, 110)], (60, 60, 80), 6)
        d.rectangle(P(tx - 6, 125, tx + 6, 142), fill=(220, 30, 26))
    for bx, by in [(70, 90), (260, 70), (200, 60)]:
        crayon([(bx - 16, by), (bx - 8, by - 8), (bx, by), (bx + 8, by - 8), (bx + 16, by)], (30, 30, 30), 4)
    crayon([(270 + math.cos(a) * 18, 110 + math.sin(a) * 18) for a in np.linspace(0, math.tau, 20)], (230, 200, 40), 5)
    # 2 : la maison, le chat noir, le soleil
    crayon([(360, 330), (360, 220), (450, 160), (540, 220), (540, 330), (360, 330)], (200, 70, 50), 7)
    crayon([(430, 330), (430, 270), (470, 270), (470, 330)], (120, 80, 40), 6)
    crayon([(390, 240), (420, 240), (420, 270), (390, 270), (390, 240)], (50, 110, 200), 5)
    d.ellipse(P(480, 300, 530, 340), fill=(30, 30, 30))
    d.ellipse(P(500, 280, 528, 306), fill=(30, 30, 30))
    d.polygon(P(502, 286, 506, 272, 512, 284), fill=(30, 30, 30))
    d.polygon(P(516, 284, 522, 272, 526, 286), fill=(30, 30, 30))
    d.ellipse(P(506, 290, 511, 295), fill=(240, 220, 40))
    d.ellipse(P(518, 290, 523, 295), fill=(240, 220, 40))
    crayon([(530, 330), (550, 310), (548, 290)], (30, 30, 30), 6)
    crayon([(530 + math.cos(a) * 26, 95 + math.sin(a) * 26) for a in np.linspace(0, math.tau, 24)], (240, 190, 30), 7)
    d.text(P(470, 344), "MINUIT", font=police("DejaVuSans-Bold.ttf", 14), fill=(40, 40, 40, 200))
    sauver("sv_dessins", petit(base, w, h))


def sv_horaires():
    w, h = 800, 400
    fond = toile(w, h, (22, 24, 26), 1716, 0.12)
    base = vers_image(fond).resize((w * SS, h * SS))
    d = ImageDraw.Draw(base, "RGBA")
    fT = police("DejaVuSans-Bold.ttf", 34)
    d.text(P(30, 18), "DÉPARTS", font=fT, fill=(236, 230, 210))
    d.line(P(24, 64, w - 24, 64), fill=(200, 196, 180), width=2 * SS)
    fh = police("DejaVuSans-Bold.ttf", 14)
    for x, t in [(30, "HEURE"), (130, "DESTINATION"), (480, "VOIE"), (560, "OBSERVATIONS")]:
        d.text(P(x, 74), t, font=fh, fill=(200, 190, 150))
    fr = police("DejaVuSansMono-Bold.ttf", 21)
    lignes = [("06:42", "PORT DES BRUMES"), ("07:15", "LA MER"), ("08:03", "LES FAUBOURGS"), ("09:30", "LE CONTINENT"),
              ("12:10", "LA MER"), ("17:45", "PORT DES BRUMES"), ("23:59", "LE CONTINENT")]
    for i, (hh, dest) in enumerate(lignes):
        y = 104 + i * 34
        d.rectangle(P(26, y - 2, w - 26, y + 28), fill=(34, 36, 40) if i % 2 else (28, 30, 33))
        d.text(P(30, y), hh, font=fr, fill=(240, 220, 120))
        d.text(P(130, y), dest, font=fr, fill=(236, 232, 220))
        d.text(P(490, y), str(1 + i % 3), font=fr, fill=(236, 232, 220))
        d.text(P(560, y), "SUPPRIMÉ", font=fr, fill=(240, 90, 60))
    # la craie, en bas
    rng = np.random.default_rng(1717)
    fc = police("DejaVuSans-Oblique.ttf", 15)
    d.text(P(40, 352), "Plus aucun train depuis trois hivers.", font=fc, fill=(230, 230, 224, 200))
    sauver("sv_horaires", peinture(petit(base, w, h), 1718, 0.05))


def sv_plan():
    w, h = 600, 450
    base = papier(w, h, 1719)
    d = ImageDraw.Draw(base, "RGBA")
    rng = np.random.default_rng(1720)
    # les îlots (des carrés), la butte et le château au milieu, la mer en haut
    d.rectangle(P(0, 0, w, 40), fill=(170, 196, 214))
    for k in range(18):
        x = rng.uniform(0, w)
        d.line(P(x, 14 + rng.uniform(0, 20), x + 20, 14 + rng.uniform(0, 20)), fill=(110, 140, 170), width=SS)
    for i in range(7):
        for j in range(5):
            x0, y0 = 30 + i * 80, 60 + j * 76
            if abs(i - 3) <= 1 and abs(j - 2) <= 1:
                continue
            d.rectangle(P(x0, y0, x0 + 60, y0 + 56), outline=(60, 54, 46), width=2 * SS, fill=(226, 220, 204))
    d.ellipse(P(220, 165, 380, 305), outline=(60, 54, 46), width=2 * SS, fill=(210, 204, 190))
    d.rectangle(P(280, 215, 320, 255), fill=(60, 54, 46))
    for r in (95, 104, 113):
        d.ellipse(P(300 - r, 235 - r * 0.8, 300 + r, 235 + r * 0.8), outline=(200, 30, 26), width=2 * SS)
    f = police("DejaVuSans-Bold.ttf", 15)
    d.text(P(232, 330), "NE PAS Y ALLER", font=f, fill=(200, 30, 26))
    # les croix rouges, la flèche vers le port
    for k in range(9):
        x, y = rng.uniform(40, 560), rng.uniform(70, 420)
        if 200 < x < 400 and 150 < y < 330:
            continue
        d.line(P(x - 8, y - 8, x + 8, y + 8), fill=(200, 30, 26), width=3 * SS)
        d.line(P(x - 8, y + 8, x + 8, y - 8), fill=(200, 30, 26), width=3 * SS)
    d.line(P(120, 400, 140, 60), fill=(40, 40, 40), width=3 * SS)
    d.polygon(P(140, 50, 130, 70, 150, 70), fill=(40, 40, 40))
    d.text(P(150, 56), "bateau ?", font=police("DejaVuSans-Oblique.ttf", 16), fill=(40, 40, 40))
    d.text(P(400, 410), "SOMBREVAL", font=police("DejaVuSerif-Bold.ttf", 18), fill=(60, 54, 46))
    sauver("sv_plan", petit(base, w, h))


def sv_avant():
    w, h = 640, 480
    yy = np.linspace(0, 1, h)[:, None, None]
    ciel = np.array([0.98, 0.78, 0.52]) * yy + np.array([0.4, 0.58, 0.86]) * (1 - yy)
    fond = np.broadcast_to(ciel, (h, w, 3)).copy() * (0.95 + 0.08 * fbm(5, 3, 1721, w, h)[..., None])
    base = vers_image(fond).resize((w * SS, h * SS))
    d = ImageDraw.Draw(base, "RGBA")
    rng = np.random.default_rng(1722)
    # les toits et les façades colorées
    cols = [(200, 120, 90), (220, 190, 120), (150, 170, 190), (210, 150, 140), (180, 160, 110), (230, 210, 170)]
    x = 0
    while x < w:
        ww = rng.uniform(50, 90)
        hh = rng.uniform(140, 220)
        c = cols[rng.integers(len(cols))]
        d.rectangle(P(x, h - hh, x + ww, h), fill=c)
        d.polygon(P(x - 4, h - hh, x + ww + 4, h - hh, x + ww / 2, h - hh - 30), fill=(120, 70, 60))
        for fy in range(int(h - hh + 20), h - 40, 40):
            for fx in range(int(x + 10), int(x + ww - 14), 22):
                d.rectangle(P(fx, fy, fx + 12, fy + 18), fill=(250, 220, 140) if rng.random() < 0.5 else (60, 70, 90))
        x += ww + 2
    # le beffroi, son horloge
    d.rectangle(P(280, 100, 340, h - 120), fill=(170, 90, 70))
    d.polygon(P(272, 102, 348, 102, 310, 40), fill=(80, 80, 100))
    d.ellipse(P(292, 120, 328, 156), fill=(250, 246, 230))
    d.line(P(310, 138, 310, 124), fill=(20, 20, 20), width=3 * SS)
    d.line(P(310, 138, 320, 140), fill=(20, 20, 20), width=3 * SS)
    # les lanternes de la fête, en guirlande
    for g in range(3):
        y0 = 260 + g * 40
        pts = [(t, y0 + 25 * math.sin(t / w * math.pi)) for t in np.linspace(0, w, 40)]
        d.line([(a * SS, b * SS) for a, b in pts], fill=(60, 40, 30), width=SS)
        for k in range(10):
            t = (k + 0.5) / 10 * w
            yy2 = y0 + 25 * math.sin(t / w * math.pi)
            c2 = [(240, 90, 60), (250, 200, 80), (120, 200, 120), (240, 140, 200)][(k + g) % 4]
            d.ellipse(P(t - 8, yy2, t + 8, yy2 + 18), fill=c2)
    sauver("sv_avant", peinture(petit(base, w, h), 1723, 0.07))


def sv_portrait():
    w, h = 480, 600
    fond = toile(w, h, (70, 46, 36), 1724, 0.08)
    base = vers_image(fond).resize((w * SS, h * SS))
    d = ImageDraw.Draw(base, "RGBA")
    # l'ovale crème, son filet doré
    d.ellipse(P(50, 50, w - 50, h - 50), fill=(196, 160, 90))
    d.ellipse(P(62, 62, w - 62, h - 62), fill=(232, 222, 196))
    # trois silhouettes de profil (le père, la mère, l'enfant), découpées au ciseau
    noir = (24, 20, 18)

    # un profil (regardant à droite ; sens -1 : à gauche), de la tête au buste
    PROFIL = [(0, -60), (16, -55), (25, -44), (29, -30), (30, -22), (40, -11), (42, -7), (33, -4), (34, 1), (31, 4), (33, 9),
              (30, 14), (29, 21), (22, 27), (15, 31), (15, 46), (30, 60), (48, 74), (56, 112), (-66, 112), (-58, 74),
              (-36, 60), (-20, 48), (-22, 30), (-30, 14), (-38, -6), (-36, -30), (-26, -48), (-14, -57)]

    def profil(cx, cy, s, sens=1, chignon=False, enfant=False):
        pts = [((cx + sens * x * s) * SS, (cy + y * s) * SS) for x, y in PROFIL]
        d.polygon(pts, fill=noir, outline=(232, 222, 196) if enfant else None, width=4 * SS if enfant else 1)
        if chignon:
            d.ellipse(P(cx - sens * 46 * s - 15 * s, cy - 40 * s, cx - sens * 46 * s + 15 * s, cy - 10 * s), fill=noir)
            d.polygon([((cx + sens * x * s) * SS, (cy + y * s) * SS) for x, y in [(-18, 48), (-4, 40), (10, 44), (24, 56), (-30, 58)]], fill=(60, 50, 44))
        if enfant:
            for k in range(3):
                d.ellipse(P(cx - sens * (8 + k * 10) * s - 6 * s, cy - 64 * s, cx - sens * (8 + k * 10) * s + 6 * s, cy - 52 * s), fill=noir)
    profil(165, 245, 1.45, 1)
    profil(318, 255, 1.32, -1, chignon=True)
    d.rectangle(P(62, h - 120, w - 62, h - 62), fill=(232, 222, 196))
    f = police("DejaVuSerif-Italic.ttf", 20)
    t = "Famille Delorme, été"
    d.text(((w * SS - d.textlength(t, font=f)) / 2, (h - 108) * SS), t, font=f, fill=(90, 70, 50))
    img = petit(base, w, h)
    a = np.asarray(img, float) / 255.0
    gris = a.mean(axis=2, keepdims=True)
    a = 0.55 * a + 0.45 * gris * np.array([1.05, 0.95, 0.78])
    sauver("sv_portrait", peinture(vers_image(a), 1725, 0.08))


def main() -> int:
    import sys
    print("V169 : les images des maisons d'Al Dente, de l'Île Crayonnée et de Sombreval")
    for f in (pa_icone, pa_nature_morte, pa_volcan, cr_affiche, cr_dessin, cr_carte, sv_decolle, sv_taches,
              sv_calendrier, sv_dessins, sv_horaires, sv_plan, sv_avant, sv_portrait):
        if len(sys.argv) < 2 or f.__name__ in sys.argv[1:]:
            f()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
