"""V170 : les images des boutiques et des bâtiments publics (faites ici ; CC0 1.0).
Dossier www/assets/textures/beau170/.

  cartes_postales   le tourniquet des Souvenirs de Port-Azur (huit cartes : le phare, le port, la plage…).
  cours_or          le cours de l'or de la Banque de l'Écu Perché (le tableau des prix, la courbe qui monte).
  tarifs_poste      les tarifs postaux (et un timbre à un sou).
  avis_recherche    trois avis de recherche (le Voleur de Tartes, le Siffleur Fou, un bon pianiste).
  carte_campagne    la carte de la caserne (l'île, le fort, les drapeaux, la rose des vents).
  plan_mine         le plan de la mine du vieux Pépite (les puits, les galeries, le filon… peut-être).
  decor_theatre     la toile du Théâtre des Mirages (le désert au couchant, les mesas, le cactus doré).
  affiche_theatre   l'affiche : « Le Mirage du Cactus Doré ».
  horaires_azur     le tableau des départs de la gare maritime de Port-Azur.
  tarifs_location   les tarifs de la location de bateaux de Yannick.
  carte_marine      la carte marine (les îles, la rose des vents, le serpent de mer).
  ardoise_*         les ardoises de Chez Paulo, du Café de la Place, du Café de la Bielle (sans alcool).
  planches_botanique deux planches de botanique (l'apothicaire, l'herboriste).
  tarifs_cornes     les tarifs de Tiburce, barbe et cornes.
  schema_robot, schema_fusee  des plans bleus (la fabrique de robots, l'atelier de l'inventeur).
  suie              une tache de suie (transparente).
  tableau_noir      le tableau de l'Académie des Ingénieurs (les rouages, « = MERVEILLEUX »).
  carte_ciel        la carte du ciel de l'observatoire.

Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/generate_textures_v170.py [nom…]
"""
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

RACINE = Path(__file__).resolve().parents[2]
OUT = RACINE / "www" / "assets" / "textures" / "beau170"
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


def papier(w, h, seed):
    c = toile(w, h, (246, 242, 230), seed, 0.04)
    return vers_image(c).resize((w * SS, h * SS))


def trait(d, pts, ep=2.4, col=(28, 26, 24), rng=None):
    rng = rng or np.random.default_rng(1)
    q = [(x * SS + rng.normal(0, 0.6 * SS), y * SS + rng.normal(0, 0.6 * SS)) for x, y in pts]
    d.line(q, fill=col, width=int(ep * SS), joint="curve")




def centre(d, y, t, f, col, w):
    tw = d.textlength(t, font=f)
    d.text(((w * SS - tw) / 2, y * SS), t, font=f, fill=col)


def lignes_prix(d, x0, x1, y0, pas, items, f, col, pointilles=(120, 110, 100)):
    for i, (a, b) in enumerate(items):
        y = y0 + i * pas
        d.text(P(x0, y), a, font=f, fill=col)
        tw = d.textlength(b, font=f)
        d.text((x1 * SS - tw, y * SS), b, font=f, fill=col)
        aw = d.textlength(a, font=f) / SS
        for xx in np.arange(x0 + aw + 6, x1 - tw / SS - 6, 7):
            d.ellipse(P(xx, y + 14, xx + 1.6, y + 15.6), fill=pointilles)


def cadre_double(d, w, h, col, m=12):
    d.rectangle(P(m, m, w - m, h - m), outline=col, width=3 * SS)
    d.rectangle(P(m + 7, m + 7, w - m - 7, h - m - 7), outline=col, width=1 * SS)


# =================================================================== Pile-ou-Face

def cartes_postales():
    w, h = 256, 512
    base = grand(w, h, (240, 236, 226, 255), "RGBA")
    d = ImageDraw.Draw(base, "RGBA")
    rng = np.random.default_rng(1701)
    scenes = ["phare", "port", "plage", "soleil", "bateaux", "ville", "mouettes", "phare"]
    f = police("DejaVuSans-Bold.ttf", 11)
    for i, sc in enumerate(scenes):
        cx, cy = (i % 2) * 128, (i // 2) * 128
        x0, y0, x1, y1 = cx + 8, cy + 10, cx + 120, cy + 118
        d.rectangle(P(x0 - 3, y0 - 3, x1 + 3, y1 + 3), fill=(252, 250, 244))
        ciel = [(120, 190, 235), (250, 180, 120), (110, 175, 230), (255, 205, 130)][i % 4]
        d.rectangle(P(x0, y0, x1, y0 + 62), fill=ciel)
        d.rectangle(P(x0, y0 + 62, x1, y1), fill=(30, 110, 170))
        for k in range(6):
            yy = y0 + 70 + k * 7
            d.line(P(x0 + 4, yy, x1 - 4, yy), fill=(90, 160, 210), width=SS)
        if sc in ("soleil", "plage", "mouettes"):
            d.ellipse(P(x1 - 40, y0 + 12, x1 - 14, y0 + 38), fill=(255, 230, 120))
        if sc == "phare":
            d.polygon(P(x0 + 50, y0 + 70, x0 + 62, y0 + 70, x0 + 59, y0 + 22, x0 + 53, y0 + 22), fill=(245, 245, 240))
            for s in range(3):
                d.rectangle(P(x0 + 51, y0 + 32 + s * 13, x0 + 61, y0 + 37 + s * 13), fill=(210, 50, 40))
            d.rectangle(P(x0 + 51, y0 + 14, x0 + 61, y0 + 22), fill=(255, 220, 120))
            d.rectangle(P(x0 + 20, y0 + 64, x0 + 92, y0 + 72), fill=(150, 130, 100))
        if sc in ("port", "bateaux", "ville"):
            for k in range(5):
                bx = x0 + 10 + k * 21
                d.rectangle(P(bx, y0 + 38 - k % 2 * 6, bx + 18, y0 + 62), fill=[(240, 200, 150), (230, 140, 120), (245, 225, 170), (200, 150, 130), (250, 240, 220)][k])
                d.polygon(P(bx - 2, y0 + 38 - k % 2 * 6, bx + 9, y0 + 30 - k % 2 * 6, bx + 20, y0 + 38 - k % 2 * 6), fill=(190, 80, 50))
        if sc in ("bateaux", "port", "plage"):
            for k in range(2):
                bx = x0 + 25 + k * 45
                d.polygon(P(bx, y0 + 82, bx + 30, y0 + 82, bx + 25, y0 + 90, bx + 5, y0 + 90), fill=(250, 250, 250))
                d.polygon(P(bx + 15, y0 + 80, bx + 15, y0 + 58, bx + 30, y0 + 78), fill=(250, 245, 230))
        if sc == "mouettes":
            for k in range(4):
                mx, my = x0 + 20 + k * 22, y0 + 20 + (k % 2) * 12
                d.arc(P(mx, my, mx + 10, my + 8), 200, 340, fill=(40, 40, 50), width=2 * SS)
                d.arc(P(mx + 9, my, mx + 19, my + 8), 200, 340, fill=(40, 40, 50), width=2 * SS)
        d.text(P(x0 + 4, y1 - 16), "PORT-AZUR", font=f, fill=(255, 255, 255))
    sauver("cartes_postales", peinture(petit(base, w, h), 1702, 0.03))


def cours_or():
    w, h = 400, 520
    base = papier(w, h, 1703)
    d = ImageDraw.Draw(base, "RGBA")
    cadre_double(d, w, h, (60, 50, 30))
    centre(d, 34, "COURS DE L'OR", police("DejaVuSerif-Bold.ttf", 34), (40, 30, 20), w)
    centre(d, 78, "— cette semaine, à l'Écu Perché —", police("DejaVuSerif-Italic.ttf", 15), (70, 60, 40), w)
    items = [("Pépite (la pièce)", "10 p."), ("Pièce d'or", "12 p."), ("Perle", "14 p."), ("Rubis", "22 p.")]
    lignes_prix(d, 44, w - 44, 120, 34, items, police("DejaVuSerif.ttf", 19), (30, 26, 20))
    # la courbe qui monte
    x0, y0, x1, y1 = 60, 290, w - 60, 430
    d.line(P(x0, y1, x1, y1), fill=(40, 34, 26), width=2 * SS)
    d.line(P(x0, y1, x0, y0), fill=(40, 34, 26), width=2 * SS)
    pts = [(x0 + k * (x1 - x0) / 8, y1 - 18 - 12 * k - 10 * math.sin(k * 1.7)) for k in range(9)]
    d.line([(px * SS, py * SS) for px, py in pts], fill=(180, 140, 30), width=4 * SS, joint="curve")
    d.polygon(P(x1 - 4, pts[-1][1] - 12, x1 + 10, pts[-1][1] - 2, x1 - 6, pts[-1][1] + 6), fill=(180, 140, 30))
    d.ellipse(P(w - 120, h - 90, w - 50, h - 30), outline=(150, 30, 30), width=3 * SS)
    f = police("DejaVuSans-Bold.ttf", 10)
    d.text(P(w - 113, h - 66), "ÉCU PERCHÉ", font=f, fill=(150, 30, 30))
    sauver("cours_or", peinture(petit(base, w, h), 1704, 0.04))


def tarifs_poste():
    w, h = 400, 500
    base = papier(w, h, 1705)
    d = ImageDraw.Draw(base, "RGBA")
    cadre_double(d, w, h, (30, 50, 90))
    centre(d, 34, "TARIFS POSTAUX", police("DejaVuSerif-Bold.ttf", 32), (24, 40, 80), w)
    items = [("Lettre", "1 p."), ("Carte postale", "2 p."), ("Colis (petit)", "5 p."), ("Colis (gros)", "9 p."), ("Télégramme, le mot", "1 p."), ("Pigeon voyageur", "à voir")]
    lignes_prix(d, 44, w - 44, 104, 34, items, police("DejaVuSerif.ttf", 19), (24, 30, 50))
    # un timbre
    tx, ty = w / 2 - 50, 330
    d.rectangle(P(tx, ty, tx + 100, ty + 120), fill=(250, 248, 240))
    for k in range(11):
        for (a, b) in ((tx + k * 10, ty), (tx + k * 10, ty + 120)):
            d.ellipse(P(a - 3, b - 3, a + 3, b + 3), fill=(236, 230, 214))
    for k in range(13):
        for (a, b) in ((tx, ty + k * 10), (tx + 100, ty + k * 10)):
            d.ellipse(P(a - 3, b - 3, a + 3, b + 3), fill=(236, 230, 214))
    d.rectangle(P(tx + 10, ty + 10, tx + 90, ty + 110), fill=(60, 110, 170))
    d.ellipse(P(tx + 30, ty + 30, tx + 70, ty + 70), fill=(250, 220, 120))
    d.polygon(P(tx + 10, ty + 110, tx + 50, ty + 72, tx + 90, ty + 110), fill=(80, 140, 80))
    d.text(P(tx + 14, ty + 88), "1 p.", font=police("DejaVuSans-Bold.ttf", 16), fill=(255, 255, 255))
    sauver("tarifs_poste", peinture(petit(base, w, h), 1706, 0.04))


def avis_recherche():
    w, h = 768, 336
    base = grand(w, h, (0, 0, 0, 0))
    rng = np.random.default_rng(1707)
    titres = [("LE VOLEUR", "DE TARTES", "Moustaches, quatre pattes.", "Récompense : une tarte"),
              ("LE SIFFLEUR", "FOU", "Siffle faux. La nuit.", "Récompense : le silence"),
              ("UN BON", "PIANISTE", "Pour le Saloon.", "Bien payé !")]
    for i, (t1, t2, l1, l2) in enumerate(titres):
        x0 = i * 256
        p = papier(256, 336, 1708 + i)
        base.paste(p, (x0 * SS, 0))
        d = ImageDraw.Draw(base, "RGBA")
        d.rectangle(P(x0 + 8, 8, x0 + 248, 328), outline=(70, 50, 30), width=2 * SS)
        fT = police("DejaVuSerif-Bold.ttf", 30)
        tw = d.textlength("RECHERCHÉ", font=fT)
        d.text(((x0 + 128) * SS - tw / 2, 16 * SS), "RECHERCHÉ", font=fT, fill=(60, 30, 20))
        cx, cy = x0 + 128, 150
        d.rectangle(P(cx - 70, cy - 66, cx + 70, cy + 54), fill=(225, 210, 180), outline=(70, 50, 30), width=SS)
        if i == 0:
            d.ellipse(P(cx - 40, cy - 40, cx + 40, cy + 34), fill=(210, 140, 60))
            d.polygon(P(cx - 38, cy - 22, cx - 30, cy - 56, cx - 12, cy - 34), fill=(210, 140, 60))
            d.polygon(P(cx + 38, cy - 22, cx + 30, cy - 56, cx + 12, cy - 34), fill=(210, 140, 60))
            for s in (-1, 1):
                d.ellipse(P(cx + s * 16 - 6, cy - 14, cx + s * 16 + 6, cy - 2), fill=(30, 30, 20))
                for k in range(3):
                    d.line(P(cx + s * 10, cy + 10 + k * 4, cx + s * 44, cy + 4 + k * 8), fill=(40, 30, 20), width=SS)
            d.polygon(P(cx - 5, cy + 4, cx + 5, cy + 4, cx, cy + 10), fill=(200, 90, 90))
            d.pieslice(P(cx + 20, cy + 20, cx + 66, cy + 52), 180, 360, fill=(230, 180, 90))
        elif i == 1:
            d.ellipse(P(cx - 26, cy - 50, cx + 26, cy + 4), fill=(90, 70, 50))
            d.rectangle(P(cx - 36, cy + 2, cx + 36, cy + 54), fill=(90, 70, 50))
            d.ellipse(P(cx - 6, cy - 22, cx + 6, cy - 12), fill=(40, 30, 20))
            for k in range(3):
                nx, ny = cx + 34 + k * 10, cy - 40 - k * 8
                d.ellipse(P(nx, ny, nx + 8, ny + 6), fill=(40, 30, 20))
                d.line(P(nx + 8, ny + 3, nx + 8, ny - 14), fill=(40, 30, 20), width=2 * SS)
            d.text(P(cx - 50, cy - 60), "?", font=police("DejaVuSans-Bold.ttf", 28), fill=(60, 40, 30))
        else:
            d.rectangle(P(cx - 56, cy - 30, cx + 56, cy + 40), fill=(40, 25, 15))
            d.rectangle(P(cx - 52, cy + 4, cx + 52, cy + 18), fill=(245, 240, 230))
            for k in range(14):
                d.line(P(cx - 52 + k * 7.5, cy + 4, cx - 52 + k * 7.5, cy + 18), fill=(40, 30, 20), width=SS)
                if k % 7 not in (2, 6):
                    d.rectangle(P(cx - 49 + k * 7.5, cy + 4, cx - 46 + k * 7.5, cy + 12), fill=(20, 15, 10))
            for k in range(4):
                nx, ny = cx - 40 + k * 26, cy - 54 + (k % 2) * 8
                d.ellipse(P(nx, ny, nx + 9, ny + 7), fill=(40, 30, 20))
                d.line(P(nx + 9, ny + 3, nx + 9, ny - 14), fill=(40, 30, 20), width=2 * SS)
        f2 = police("DejaVuSerif-Bold.ttf", 22)
        for j, t in enumerate((t1, t2)):
            tw = d.textlength(t, font=f2)
            d.text(((x0 + 128) * SS - tw / 2, (214 + j * 26) * SS), t, font=f2, fill=(50, 30, 20))
        f3 = police("DejaVuSerif-Italic.ttf", 14)
        for j, t in enumerate((l1, l2)):
            tw = d.textlength(t, font=f3)
            d.text(((x0 + 128) * SS - tw / 2, (272 + j * 20) * SS), t, font=f3, fill=(60, 40, 30))
        d.ellipse(P(x0 + 122, 10, x0 + 134, 22), fill=(150, 150, 150))
    sauver("avis_recherche", peinture(petit(base, w, h).convert("RGB"), 1710, 0.05))


def carte_campagne():
    w, h = 680, 360
    fond = toile(w, h, (226, 206, 160), 1711, 0.07)
    base = vers_image(fond).resize((w * SS, h * SS))
    d = ImageDraw.Draw(base, "RGBA")
    rng = np.random.default_rng(1712)
    pts = []
    for k in range(80):
        a = k / 80 * math.tau
        r = 1.0 + 0.12 * math.sin(3 * a + 1) + 0.07 * math.sin(7 * a)
        pts.append((w / 2 + math.cos(a) * 260 * r, h / 2 + math.sin(a) * 130 * r))
    d.polygon([(x * SS, y * SS) for x, y in pts], fill=(196, 182, 130), outline=(90, 70, 40))
    d.line([(x * SS, y * SS) for x, y in pts + [pts[0]]], fill=(90, 70, 40), width=3 * SS)
    for k in range(9):
        x, y = rng.uniform(140, 540), rng.uniform(90, 270)
        d.polygon(P(x, y - 10, x - 9, y + 6, x + 9, y + 6), fill=(110, 100, 70))
    d.rectangle(P(w / 2 - 26, h / 2 - 22, w / 2 + 26, h / 2 + 18), fill=(120, 70, 50), outline=(60, 30, 20), width=2 * SS)
    for k in range(4):
        d.rectangle(P(w / 2 - 26 + k * 15, h / 2 - 32, w / 2 - 18 + k * 15, h / 2 - 22), fill=(120, 70, 50))
    for k in range(18):
        a = k / 18 * math.tau
        x, y = w / 2 + math.cos(a) * 150, h / 2 + math.sin(a) * 70
        d.ellipse(P(x - 2, y - 2, x + 2, y + 2), fill=(150, 30, 30))
    cx, cy = w - 80, h - 70
    for a in range(8):
        ang = a * math.pi / 4
        r = 40 if a % 2 == 0 else 22
        d.polygon(P(cx, cy, cx + math.cos(ang - 0.2) * 10, cy + math.sin(ang - 0.2) * 10, cx + math.cos(ang) * r, cy + math.sin(ang) * r, cx + math.cos(ang + 0.2) * 10, cy + math.sin(ang + 0.2) * 10), fill=(80, 50, 30) if a % 2 == 0 else (150, 110, 70))
    d.text(P(cx - 5, cy - 58), "N", font=police("DejaVuSerif-Bold.ttf", 16), fill=(60, 40, 20))
    sauver("carte_campagne", peinture(petit(base, w, h), 1713, 0.05))


def plan_mine():
    w, h = 520, 380
    fond = toile(w, h, (214, 196, 158), 1714, 0.08)
    base = vers_image(fond).resize((w * SS, h * SS))
    d = ImageDraw.Draw(base, "RGBA")
    rng = np.random.default_rng(1715)
    col = (70, 50, 30)
    centre(d, 14, "MINE DU VIEUX PÉPITE", police("DejaVuSerif-Bold.ttf", 24), col, w)
    d.line(P(30, 70, w - 30, 70), fill=(110, 140, 60), width=4 * SS)
    for x in (110, 300, 430):
        d.line(P(x, 70, x, 330), fill=col, width=6 * SS)
        for y in range(80, 330, 14):
            d.line(P(x - 5, y, x + 5, y), fill=col, width=SS)
    for (a, b, y) in ((110, 300, 150), (300, 430, 220), (60, 110, 260), (110, 300, 310)):
        trait(d, [(a, y), ((a + b) / 2, y + rng.uniform(-8, 8)), (b, y)], 7, col, rng)
    for (x, y) in ((200, 140), (360, 212), (80, 252)):
        d.ellipse(P(x - 6, y - 6, x + 6, y + 6), fill=(220, 170, 40))
    d.line(P(390, 290, 420, 320), fill=(170, 30, 30), width=4 * SS)
    d.line(P(420, 290, 390, 320), fill=(170, 30, 30), width=4 * SS)
    f = police("DejaVuSerif-Italic.ttf", 15)
    d.text(P(330, 330), "le filon ? (peut-être)", font=f, fill=(150, 30, 30))
    d.text(P(118, 76), "puits n° 1", font=f, fill=col)
    d.text(P(308, 76), "puits n° 2", font=f, fill=col)
    sauver("plan_mine", peinture(petit(base, w, h), 1716, 0.05))


def decor_theatre():
    w, h = 1024, 384
    y = np.linspace(0, 1, h)[:, None]
    haut = np.array([250, 150, 90]) / 255.0
    bas = np.array([255, 215, 140]) / 255.0
    ciel = haut[None, None, :] * (1 - y[..., None]) + bas[None, None, :] * y[..., None]
    ciel = np.repeat(ciel, w, axis=1)
    base = vers_image(ciel).resize((w * SS, h * SS))
    d = ImageDraw.Draw(base, "RGBA")
    rng = np.random.default_rng(1717)
    d.ellipse(P(w / 2 - 70, 170, w / 2 + 70, 310), fill=(255, 235, 170, 230))
    for (x0, x1, top, col) in ((-40, 300, 150, (170, 80, 50)), (620, 1080, 120, (160, 70, 45)), (240, 520, 210, (190, 100, 60))):
        d.polygon(P(x0, 300, x0 + 30, top, x1 - 30, top, x1, 300), fill=col)
        for k in range(6):
            yy = top + 15 + k * 22
            d.line(P(x0 + 30, yy, x1 - 30, yy), fill=(140, 60, 40), width=2 * SS)
    d.rectangle(P(0, 290, w, h), fill=(225, 175, 110))
    for k in range(40):
        x, yy = rng.uniform(0, w), rng.uniform(300, h)
        d.ellipse(P(x, yy, x + 6, yy + 3), fill=(200, 150, 90))
    def cactus(x, base_y, s, col):
        d.rounded_rectangle(P(x - 9 * s, base_y - 80 * s, x + 9 * s, base_y), radius=9 * s * SS, fill=col)
        d.rounded_rectangle(P(x - 34 * s, base_y - 55 * s, x - 22 * s, base_y - 25 * s), radius=6 * s * SS, fill=col)
        d.rectangle(P(x - 30 * s, base_y - 30 * s, x - 8 * s, base_y - 22 * s), fill=col)
        d.rounded_rectangle(P(x + 22 * s, base_y - 65 * s, x + 34 * s, base_y - 35 * s), radius=6 * s * SS, fill=col)
        d.rectangle(P(x + 8 * s, base_y - 40 * s, x + 30 * s, base_y - 32 * s), fill=col)
    cactus(120, 340, 1.2, (60, 110, 60))
    cactus(880, 350, 1.4, (55, 100, 55))
    cactus(560, 300, 0.9, (240, 190, 50))
    for k in range(10):
        a = k / 10 * math.tau
        d.line(P(560 + math.cos(a) * 40, 260 + math.sin(a) * 40, 560 + math.cos(a) * 60, 260 + math.sin(a) * 60), fill=(255, 230, 120, 200), width=3 * SS)
    d.rectangle(P(700, 250, 780, 300), fill=(150, 90, 60))
    d.polygon(P(694, 250, 740, 228, 786, 250), fill=(120, 60, 40))
    d.rectangle(P(728, 270, 752, 300), fill=(80, 40, 25))
    sauver("decor_theatre", peinture(petit(base, w, h).convert("RGB"), 1718, 0.06))


def affiche_theatre():
    w, h = 320, 460
    base = papier(w, h, 1719)
    d = ImageDraw.Draw(base, "RGBA")
    d.rectangle(P(0, 0, w, h), fill=(120, 20, 30, 70))
    cadre_double(d, w, h, (230, 190, 90), 10)
    centre(d, 26, "THÉÂTRE", police("DejaVuSerif-Bold.ttf", 30), (250, 220, 140), w)
    centre(d, 60, "DES MIRAGES", police("DejaVuSerif-Bold.ttf", 22), (250, 220, 140), w)
    d.ellipse(P(w / 2 - 70, 110, w / 2 + 70, 250), fill=(250, 200, 110))
    d.rounded_rectangle(P(w / 2 - 12, 140, w / 2 + 12, 250), radius=12 * SS, fill=(230, 170, 40))
    d.rounded_rectangle(P(w / 2 - 44, 170, w / 2 - 28, 210), radius=8 * SS, fill=(230, 170, 40))
    d.rectangle(P(w / 2 - 40, 204, w / 2 - 10, 214), fill=(230, 170, 40))
    d.rounded_rectangle(P(w / 2 + 28, 160, w / 2 + 44, 200), radius=8 * SS, fill=(230, 170, 40))
    d.rectangle(P(w / 2 + 10, 194, w / 2 + 40, 204), fill=(230, 170, 40))
    centre(d, 270, "LE MIRAGE", police("DejaVuSerif-Bold.ttf", 26), (255, 240, 210), w)
    centre(d, 302, "DU CACTUS DORÉ", police("DejaVuSerif-Bold.ttf", 22), (255, 240, 210), w)
    centre(d, 350, "avec Achille Mirage", police("DejaVuSerif-Italic.ttf", 15), (250, 230, 190), w)
    centre(d, 372, "& Mimi Poussière", police("DejaVuSerif-Italic.ttf", 15), (250, 230, 190), w)
    centre(d, 412, "TOUS LES SAMEDIS SOIR", police("DejaVuSans-Bold.ttf", 14), (250, 220, 140), w)
    sauver("affiche_theatre", peinture(petit(base, w, h), 1720, 0.05))


# =================================================================== Port-Azur

def horaires_azur():
    w, h = 800, 400
    fond = toile(w, h, (20, 46, 92), 1721, 0.08)
    base = vers_image(fond).resize((w * SS, h * SS))
    d = ImageDraw.Draw(base, "RGBA")
    d.rectangle(P(10, 10, w - 10, h - 10), outline=(240, 240, 235), width=4 * SS)
    fh = police("DejaVuSans-Bold.ttf", 14)
    for x, t in [(30, "HEURE"), (130, "NAVIRE"), (330, "DESTINATION"), (610, "ÉTAT")]:
        d.text(P(x, 24), t, font=fh, fill=(250, 220, 120))
    fr = police("DejaVuSansMono-Bold.ttf", 19)
    lignes = [("08:30", "L'HIRONDELLE", "LES ÎLES DU LARGE", "À L'HEURE"), ("10:15", "L'HIRONDELLE", "LE GRAND PHARE", "À L'HEURE"),
              ("12:00", "LE PETIT BAC", "LA PLAGE DES SARDINES", "À L'HEURE"), ("14:45", "L'HIRONDELLE", "MONTJOIE", "RETARD : SIESTE"),
              ("17:20", "LE PETIT BAC", "LA CRIQUE AUX PERLES", "À L'HEURE"), ("19:05", "L'HIRONDELLE", "CLIQUETIS", "SI LE VENT VEUT")]
    for i, (hh, nav, dest, et) in enumerate(lignes):
        y = 54 + i * 52
        d.rectangle(P(22, y - 4, w - 22, y + 36), fill=(26, 56, 108) if i % 2 else (22, 50, 100))
        d.text(P(30, y + 4), hh, font=fr, fill=(250, 230, 130))
        d.text(P(130, y + 4), nav, font=fr, fill=(240, 244, 250))
        d.text(P(330, y + 4), dest, font=fr, fill=(240, 244, 250))
        d.text(P(610, y + 4), et, font=police("DejaVuSansMono-Bold.ttf", 14), fill=(120, 230, 120) if et == "À L'HEURE" else (250, 160, 70))
    sauver("horaires_azur", peinture(petit(base, w, h), 1722, 0.03))


def tarifs_location():
    w, h = 360, 440
    fond = toile(w, h, (238, 242, 244), 1723, 0.05)
    base = vers_image(fond).resize((w * SS, h * SS))
    d = ImageDraw.Draw(base, "RGBA")
    d.rectangle(P(0, 0, w, 70), fill=(30, 110, 170))
    centre(d, 14, "LOCATION", police("DejaVuSans-Bold.ttf", 28), (255, 255, 255), w)
    centre(d, 46, "de bateaux", police("DejaVuSans-Oblique.ttf", 16), (230, 240, 250), w)
    items = [("Barque (l'heure)", "5 p."), ("Pédalo cygne", "3 p."), ("Canne à pêche", "2 p."), ("Gilet", "offert"), ("Rames perdues", "8 p.")]
    lignes_prix(d, 30, w - 30, 92, 34, items, police("DejaVuSans.ttf", 18), (30, 40, 60))
    d.polygon(P(70, 330, 290, 330, 260, 380, 100, 380), fill=(200, 80, 50))
    d.rectangle(P(70, 326, 290, 334), fill=(240, 230, 210))
    for k in range(5):
        d.arc(P(20 + k * 70, 380, 90 + k * 70, 410), 180, 360, fill=(60, 140, 200), width=3 * SS)
    sauver("tarifs_location", peinture(petit(base, w, h), 1724, 0.03))


def carte_marine():
    w, h = 1024, 600
    fond = toile(w, h, (232, 222, 190), 1725, 0.06)
    base = vers_image(fond).resize((w * SS, h * SS))
    d = ImageDraw.Draw(base, "RGBA")
    rng = np.random.default_rng(1726)
    iles = [(220, 180, 90, 55, "PORT-AZUR"), (640, 140, 70, 45, "MONTJOIE"), (820, 380, 80, 50, "CLIQUETIS"), (360, 430, 60, 40, "PANDÉMONIA"), (520, 300, 40, 26, "L'ÎLE PERCHÉE")]
    for (x, y, rx, ry, nom) in iles:
        for k in range(4, 0, -1):
            d.ellipse(P(x - rx - k * 14, y - ry - k * 10, x + rx + k * 14, y + ry + k * 10), outline=(150, 175, 190), width=SS)
        pts = []
        for k in range(40):
            a = k / 40 * math.tau
            r = 1 + 0.15 * math.sin(3 * a + x) + 0.08 * math.sin(7 * a + y)
            pts.append(((x + math.cos(a) * rx * r) * SS, (y + math.sin(a) * ry * r) * SS))
        d.polygon(pts, fill=(214, 196, 150), outline=(90, 70, 50))
        f = police("DejaVuSerif-Italic.ttf", 16)
        tw = d.textlength(nom, font=f)
        d.text((x * SS - tw / 2, (y + ry + 12) * SS), nom, font=f, fill=(70, 50, 30))
    cx, cy = 900, 110
    for k in range(16):
        a = k * math.tau / 16
        d.line(P(cx, cy, cx + math.cos(a) * 900, cy + math.sin(a) * 900), fill=(170, 120, 110, 90), width=SS)
    for a in range(8):
        ang = a * math.pi / 4
        r = 60 if a % 2 == 0 else 32
        d.polygon(P(cx, cy, cx + math.cos(ang - 0.22) * 14, cy + math.sin(ang - 0.22) * 14, cx + math.cos(ang) * r, cy + math.sin(ang) * r, cx + math.cos(ang + 0.22) * 14, cy + math.sin(ang + 0.22) * 14), fill=(120, 40, 40) if a % 2 == 0 else (60, 60, 80))
    sx, sy = 120, 470
    for k in range(5):
        d.arc(P(sx + k * 34, sy - 16, sx + k * 34 + 34, sy + 16), 180 if k % 2 == 0 else 0, 360 if k % 2 == 0 else 180, fill=(60, 110, 70), width=7 * SS)
    d.ellipse(P(sx - 18, sy - 14, sx + 6, sy + 6), fill=(60, 110, 70))
    d.text(P(sx - 10, sy + 26), "Ici, peut-être, un serpent de mer", font=police("DejaVuSerif-Italic.ttf", 14), fill=(70, 50, 30))
    sauver("carte_marine", peinture(petit(base, w, h), 1727, 0.05))


def ardoise(nom, titre, items, seed):
    w, h = 360, 480
    fond = toile(w, h, (34, 38, 36), seed, 0.12)
    base = vers_image(fond).resize((w * SS, h * SS))
    d = ImageDraw.Draw(base, "RGBA")
    d.rectangle(P(0, 0, w, h), outline=(120, 80, 50), width=14 * SS)
    craie = (236, 236, 228, 230)
    centre(d, 30, titre, police("DejaVuSerif-BoldItalic.ttf", 30), craie, w)
    d.line(P(60, 76, w - 60, 76), fill=craie, width=2 * SS)
    f = police("DejaVuSans-Oblique.ttf", 19)
    for i, (a, b) in enumerate(items):
        y = 100 + i * 52
        d.text(P(36, y), a, font=f, fill=craie)
        tw = d.textlength(b, font=f)
        d.text(((w - 36) * SS - tw, y * SS), b, font=f, fill=(250, 220, 140, 230))
    sauver(nom, peinture(petit(base, w, h), seed + 1, 0.03))


def ardoises():
    ardoise("ardoise_paulo", "Chez Paulo", [("Bouillabaisse", "18 p."), ("Sardines grillées", "9 p."), ("Poisson du jour", "12 p."), ("Croissant", "3 p."), ("Glace au citron", "4 p."), ("Jus d'orange", "3 p.")], 1728)
    ardoise("ardoise_cafe", "Café de la Place", [("Café", "2 p."), ("Chocolat chaud", "4 p."), ("Sirop de grenadine", "2 p."), ("Citronnade", "3 p."), ("Tarte du jour", "5 p."), ("Croissant", "3 p.")], 1730)
    ardoise("ardoise_bielle", "Café de la Bielle", [("Café à vapeur", "3 p."), ("Biscuit-engrenage", "4 p."), ("Galette de sarrasin", "6 p."), ("Thé qui tourne", "3 p."), ("Huile de robot", "robots"), ("Chocolat chaud", "4 p.")], 1732)


# =================================================================== Pandémonia, Montjoie, Cliquetis

def planches_botanique():
    w, h = 480, 360
    base = grand(w, h, (0, 0, 0, 255), "RGBA")
    rng = np.random.default_rng(1734)
    noms = ["Herba Fievrosa", "Lunaria Nocturna"]
    for i in range(2):
        p = papier(240, 360, 1735 + i)
        base.paste(p, (i * 240 * SS, 0))
        d = ImageDraw.Draw(base, "RGBA")
        x0 = i * 240
        d.rectangle(P(x0 + 10, 10, x0 + 230, 350), outline=(90, 80, 60), width=SS)
        cx = x0 + 120
        trait(d, [(cx, 300), (cx + 4, 220), (cx - 3, 150), (cx + 2, 80)], 3, (60, 90, 40), rng)
        for k in range(6):
            y = 270 - k * 32
            s = -1 if k % 2 else 1
            d.ellipse(P(min(cx + s * 4, cx + s * 60), y - 10, max(cx + s * 4, cx + s * 60), y + 10), fill=(90, 140, 60), outline=(50, 80, 30), width=SS)
            d.line(P(cx, y, cx + s * 56, y), fill=(50, 80, 30), width=SS)
        col = (220, 200, 90) if i == 0 else (170, 150, 220)
        for k in range(5):
            a = k / 5 * math.tau
            d.ellipse(P(cx + math.cos(a) * 14 - 10, 64 + math.sin(a) * 14 - 10, cx + math.cos(a) * 14 + 10, 64 + math.sin(a) * 14 + 10), fill=col)
        d.ellipse(P(cx - 6, 58, cx + 6, 70), fill=(230, 150, 50))
        d.line(P(cx - 40, 300, cx + 40, 300), fill=(120, 90, 60), width=2 * SS)
        f = police("DejaVuSerif-Italic.ttf", 16)
        tw = d.textlength(noms[i], font=f)
        d.text((cx * SS - tw / 2, 316 * SS), noms[i], font=f, fill=(60, 50, 40))
    sauver("planches_botanique", peinture(petit(base, w, h).convert("RGB"), 1737, 0.04))


def tarifs_cornes():
    w, h = 360, 450
    fond = toile(w, h, (60, 16, 18), 1738, 0.1)
    base = vers_image(fond).resize((w * SS, h * SS))
    d = ImageDraw.Draw(base, "RGBA")
    cadre_double(d, w, h, (220, 170, 80), 10)
    centre(d, 28, "TIBURCE", police("DejaVuSerif-Bold.ttf", 32), (240, 200, 110), w)
    centre(d, 66, "barbe & cornes", police("DejaVuSerif-Italic.ttf", 18), (240, 210, 150), w)
    items = [("Polissage de cornes", "5 p."), ("Rasage", "3 p."), ("Moustache en spirale", "4 p."), ("Cire de sabots", "2 p."), ("Huile de cornes", "8 p.")]
    lignes_prix(d, 30, w - 30, 110, 40, items, police("DejaVuSerif.ttf", 18), (245, 225, 190), (160, 120, 80))
    for s in (-1, 1):
        cx = w / 2 + s * 60
        d.polygon(P(cx, 400, cx + s * 30, 330, cx + s * 10, 400), fill=(230, 210, 180))
    sauver("tarifs_cornes", peinture(petit(base, w, h), 1739, 0.04))


def plan_bleu(nom, w, h, seed, titre, dessin):
    fond = toile(w, h, (28, 70, 140), seed, 0.06)
    base = vers_image(fond).resize((w * SS, h * SS))
    d = ImageDraw.Draw(base, "RGBA")
    for x in range(0, w, 20):
        d.line(P(x, 0, x, h), fill=(255, 255, 255, 25), width=SS)
    for y in range(0, h, 20):
        d.line(P(0, y, w, y), fill=(255, 255, 255, 25), width=SS)
    blanc = (235, 242, 250)
    dessin(d, blanc)
    d.text(P(14, h - 30), titre, font=police("DejaVuSansMono-Bold.ttf", 14), fill=blanc)
    sauver(nom, peinture(petit(base, w, h), seed + 1, 0.03))


def schema_robot():
    def dessin(d, c):
        cx = 170
        d.rectangle(P(cx - 50, 60, cx + 50, 110), outline=c, width=2 * SS)
        d.ellipse(P(cx - 28, 74, cx - 12, 90), outline=c, width=2 * SS)
        d.ellipse(P(cx + 12, 74, cx + 28, 90), outline=c, width=2 * SS)
        d.rectangle(P(cx - 70, 120, cx + 70, 220), outline=c, width=2 * SS)
        d.ellipse(P(cx - 20, 150, cx + 20, 190), outline=c, width=2 * SS)
        for s in (-1, 1):
            d.line(P(cx + s * 70, 130, cx + s * 110, 200), fill=c, width=2 * SS)
            d.line(P(cx + s * 30, 220, cx + s * 34, 290), fill=c, width=2 * SS)
        d.line(P(cx - 90, 60, cx - 90, 290), fill=c, width=SS)
        d.text(P(cx - 150, 170), "1,6 m", font=police("DejaVuSansMono.ttf", 13), fill=c)
        d.line(P(300, 60, 460, 60), fill=c, width=SS)
        for k in range(5):
            d.text(P(300, 80 + k * 30), ["tête : laiton", "yeux : lanternes", "cœur : ressort", "bras : 2 (ou 3)", "humeur : polie"][k], font=police("DejaVuSansMono.ttf", 14), fill=c)
    plan_bleu("schema_robot", 480, 340, 1740, "PLAN : ROBOT MAJORDOME N° 7", dessin)


def schema_fusee():
    def dessin(d, c):
        cx = 180
        d.polygon(P(cx, 40, cx - 30, 100, cx + 30, 100), outline=c)
        d.line(P(cx, 40, cx - 30, 100), fill=c, width=2 * SS)
        d.line(P(cx, 40, cx + 30, 100), fill=c, width=2 * SS)
        d.rectangle(P(cx - 30, 100, cx + 30, 240), outline=c, width=2 * SS)
        for s in (-1, 1):
            d.polygon(P(cx + s * 30, 200, cx + s * 60, 260, cx + s * 30, 240), outline=c)
            d.line(P(cx + s * 30, 200, cx + s * 60, 260), fill=c, width=2 * SS)
        for k in range(8):
            a = k / 8 * math.tau
            d.line(P(290 + math.cos(a) * 14, 80 + math.sin(a) * 14, 290 + math.cos(a) * 34, 80 + math.sin(a) * 34), fill=c, width=2 * SS)
        d.text(P(40, 290), "poudre : très peu !", font=police("DejaVuSansMono.ttf", 14), fill=c)
    plan_bleu("schema_fusee", 360, 360, 1742, "FUSÉE DE FÊTE (MODÈLE PAF)", dessin)


def suie():
    w, h = 256, 192
    n = fbm(5, 4, 1744, w, h)
    y, x = np.mgrid[0:h, 0:w]
    r = np.sqrt(((x - w / 2) / (w * 0.42)) ** 2 + ((y - h / 2) / (h * 0.42)) ** 2)
    a = np.clip((1.0 - r) * 1.6 + (n - 0.5) * 1.2, 0, 1) * 0.75
    img = np.zeros((h, w, 4))
    img[..., 0] = 0.08
    img[..., 1] = 0.07
    img[..., 2] = 0.06
    img[..., 3] = a
    sauver("suie", Image.fromarray((img * 255).round().astype(np.uint8), "RGBA"))


def tableau_noir():
    w, h = 1024, 390
    fond = toile(w, h, (30, 52, 40), 1745, 0.1)
    base = vers_image(fond).resize((w * SS, h * SS))
    d = ImageDraw.Draw(base, "RGBA")
    rng = np.random.default_rng(1746)
    craie = (235, 238, 228, 220)
    def roue(cx, cy, r, n):
        d.ellipse(P(cx - r, cy - r, cx + r, cy + r), outline=craie, width=3 * SS)
        d.ellipse(P(cx - r * 0.25, cy - r * 0.25, cx + r * 0.25, cy + r * 0.25), outline=craie, width=2 * SS)
        for k in range(n):
            a = k / n * math.tau
            d.line(P(cx + math.cos(a) * r, cy + math.sin(a) * r, cx + math.cos(a) * (r + 12), cy + math.sin(a) * (r + 12)), fill=craie, width=5 * SS)
    roue(150, 170, 70, 14)
    roue(262, 210, 38, 8)
    d.arc(P(110, 60, 190, 140), 200, 330, fill=craie, width=2 * SS)
    d.polygon(P(186, 92, 196, 100, 182, 104), fill=craie)
    f = police("DejaVuSans-Oblique.ttf", 30)
    d.text(P(360, 60), "VAPEUR + ROUAGE", font=f, fill=craie)
    d.text(P(420, 110), "= MOUVEMENT", font=f, fill=craie)
    d.text(P(360, 190), "MOUVEMENT + IDÉE", font=f, fill=craie)
    d.text(P(420, 240), "= MERVEILLEUX", font=police("DejaVuSans-BoldOblique.ttf", 34), fill=(250, 230, 150, 230))
    d.line(P(410, 288, 700, 288), fill=craie, width=2 * SS)
    d.text(P(760, 60), "Leçon n° 12 :", font=police("DejaVuSans-Oblique.ttf", 28), fill=craie)
    d.text(P(760, 104), "ne rien faire", font=police("DejaVuSans-Oblique.ttf", 26), fill=craie)
    d.text(P(760, 142), "exploser", font=police("DejaVuSans-Oblique.ttf", 26), fill=craie)
    d.text(P(760, 180), "(si possible)", font=police("DejaVuSans-Oblique.ttf", 22), fill=craie)
    for k in range(40):
        x, y = rng.uniform(0, w), rng.uniform(0, h)
        d.line(P(x, y, x + rng.uniform(10, 60), y + rng.uniform(-3, 3)), fill=(235, 238, 228, 18), width=6 * SS)
    sauver("tableau_noir", peinture(petit(base, w, h), 1747, 0.03))


def carte_ciel():
    w, h = 720, 480
    fond = toile(w, h, (16, 22, 52), 1748, 0.06)
    base = vers_image(fond).resize((w * SS, h * SS))
    d = ImageDraw.Draw(base, "RGBA")
    rng = np.random.default_rng(1749)
    d.ellipse(P(30, 30, w - 30, h - 30), outline=(200, 180, 120), width=2 * SS)
    for k in range(240):
        x, y = rng.uniform(40, w - 40), rng.uniform(40, h - 40)
        r = rng.uniform(0.6, 2.4)
        d.ellipse(P(x - r, y - r, x + r, y + r), fill=(250, 245, 220))
    consts = [[(140, 120), (190, 100), (240, 130), (280, 110), (320, 150)], [(420, 300), (470, 260), (520, 290), (500, 350), (440, 360), (420, 300)],
              [(200, 330), (240, 300), (280, 320), (300, 380)], [(500, 120), (560, 90), (600, 140), (580, 190)]]
    noms = ["LA GRANDE ROUE", "LE CHAUDRON", "LE CHAT", "LA LUNETTE"]
    for c, n in zip(consts, noms):
        d.line([(x * SS, y * SS) for x, y in c], fill=(200, 210, 255, 160), width=SS)
        for x, y in c:
            d.ellipse(P(x - 3.5, y - 3.5, x + 3.5, y + 3.5), fill=(255, 250, 220))
        d.text(P(c[0][0] - 10, c[0][1] + 10), n, font=police("DejaVuSerif-Italic.ttf", 12), fill=(220, 200, 150))
    d.line(P(560, 400, 640, 360), fill=(255, 250, 220, 150), width=4 * SS)
    d.ellipse(P(636, 354, 648, 366), fill=(255, 250, 230))
    for k in range(4):
        x = 60 + k * 36
        d.ellipse(P(x, h - 70, x + 26, h - 44), fill=(240, 235, 200))
        d.ellipse(P(x + 6 * (k + 1) - 6, h - 70, x + 6 * (k + 1) + 20, h - 44), fill=(16, 22, 52))
    sauver("carte_ciel", peinture(petit(base, w, h), 1750, 0.03))


def main() -> int:
    import sys
    print("V170 : les images des boutiques")
    for f in (cartes_postales, cours_or, tarifs_poste, avis_recherche, carte_campagne, plan_mine, decor_theatre, affiche_theatre,
              horaires_azur, tarifs_location, carte_marine, ardoises, planches_botanique, tarifs_cornes, schema_robot, schema_fusee,
              suie, tableau_noir, carte_ciel):
        if len(sys.argv) < 2 or f.__name__ in sys.argv[1:]:
            f()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
