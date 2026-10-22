"""V62 : textures de Ramure, le village des oreilles, perché dans les arbres géants de la forêt
des brumes (l'est de la grande île).

ramure/  ecorce.png (+_n)    : l'écorce des arbres géants, profondes crevasses verticales, plaques
                              grises et rousses, lichens ;
         planches.png (+_n)  : le plancher des plates-formes (larges planches cirées, chevilles) ;
         rondins.png (+_n)   : les murs des cabanes en rondins ;
         chaume.png (+_n)    : le chaume des toits coniques (rangées de paille) ;
         papier.png          : le papier des lanternes (washi, nervures de bambou) ;
         noren_*.png         : les rideaux-enseignes des échoppes (troc, simples, boulangerie,
                              forge, poste, pêcherie, course) ;
         banniere_lune.png   : la bannière du festival de la pleine lune ;
         records.png         : le tableau des records de la Grande Course.
items/   champignon_lune (quête), caillou_chantant, gland_dore, plume_lune, fiole_brume,
         clochette_argent, oreilles_renard, coupe_course, grelot_tanuki, pain_carotte,
         gateau_lune, tisane_brume, brochette_poisson.
Tout est dessiné ici (libre de droits).
Lancement depuis la racine du dépôt : python3 pcvr/tools/generate_ramure_v62.py [textures | enseignes | icones]
"""
from pathlib import Path
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_carene_v59 as gc  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "ramure"
FONTS = ROOT / "www" / "assets" / "fonts"
rng = np.random.default_rng(6262)
gc.rng = np.random.default_rng(6263)
tile_noise = gc.tile_noise


def save_rgb(arr, name):
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGB").save(OUT / name, optimize=True)
    print("ramure/" + name)


def save_rgba(arr, name):
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA").save(OUT / name, optimize=True)
    print("ramure/" + name)


def save_n(h, strength, name):
    OUT.mkdir(parents=True, exist_ok=True)
    gc.normal_map(h, strength).save(OUT / name, optimize=True)
    print("ramure/" + name)


def _font(name, size):
    return ImageFont.truetype(str(FONTS / name), size)


def _warp_sample(field, dx, dy):
    """Échantillonne un champ tuilable à des coordonnées décalées (déformation de domaine)."""
    H, W = field.shape
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    x = np.mod(xx + dx, W)
    y = np.mod(yy + dy, H)
    x0 = np.floor(x).astype(int) % W
    y0 = np.floor(y).astype(int) % H
    x1 = (x0 + 1) % W
    y1 = (y0 + 1) % H
    fx = x - np.floor(x)
    fy = y - np.floor(y)
    return (field[y0, x0] * (1 - fx) * (1 - fy) + field[y0, x1] * fx * (1 - fy) + field[y1, x0] * (1 - fx) * fy + field[y1, x1] * fx * fy)


# =================================================================== l'écorce des géants

def ecorce():
    """Écorce de chêne/séquoia géant : de longues crêtes fibreuses séparées par des crevasses
    brun-roux qui serpentent, se divisent et se rejoignent ; le dessus des crêtes est usé, plus
    gris ; lichens pâles, mousse au fond des creux. La tuile couvre environ 3 m x 3 m d'écorce."""
    S = 1024
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    # les crevasses : les lignes de niveau 0,5 d'un bruit très étiré à la verticale (elles
    # serpentent, se divisent et se rejoignent naturellement), plus un réseau plus fin
    n_a = tile_noise(S, S, ox=(16, 32), oy=(2, 4), falloff=0.5)
    n_b = tile_noise(S, S, ox=(32, 64), oy=(3, 6), falloff=0.5)
    gate = np.clip((tile_noise(S, S, ox=(4, 8), oy=(4, 8), falloff=0.6) - 0.45) / 0.3, 0, 1)
    ga = np.abs(n_a - 0.5)
    gb = np.abs(n_b - 0.5) + (1.0 - gate) * 0.2
    # distance approximative à la ligne : |n - 0,5| / |gradient|
    gya, gxa = np.gradient(n_a)
    gyb, gxb = np.gradient(n_b)
    dist = np.minimum(ga / (np.hypot(gxa, gya) + 1e-4), gb / (np.hypot(gxb, gyb) + 1e-4))
    dist = np.clip(dist, 0, 60.0)
    wn = tile_noise(S, S, ox=(8, 16, 32), oy=(8, 16, 32), falloff=0.6)
    w = 14.0 + 10.0 * wn
    t = np.clip(dist / w, 0, 1)
    plate = t * t * (3 - 2 * t)
    groove = 1.0 - plate
    crest = np.clip(dist / 23.0, 0, 1) ** 0.6
    ch = tile_noise(S, S, ox=(16, 32), oy=(2, 3), falloff=0.6)
    fib = tile_noise(S, S, ox=(256, 512), oy=(8, 16), falloff=0.7)
    fib2 = tile_noise(S, S, ox=(64, 128), oy=(4, 8), falloff=0.7)
    strands = np.clip(0.3 + fib * 0.7 + (fib2 - 0.5) * 0.5, 0, 1)
    n1 = tile_noise(S, S, ox=(8, 16, 32, 64, 128), falloff=0.6)
    h = plate * (0.5 + 0.35 * crest + 0.1 * ch) + strands * 0.1 * plate - groove * 0.7 + n1 * 0.06
    grey = np.array([0.42, 0.38, 0.33], np.float32)
    brown = np.array([0.38, 0.27, 0.19], np.float32)
    worn = np.array([0.58, 0.55, 0.50], np.float32)
    inner = np.array([0.19, 0.11, 0.07], np.float32)
    mixp = np.clip(ch * 0.7 + (n1 - 0.5) * 0.6, 0, 1)[..., None]
    col = grey * (1 - mixp) + brown * mixp
    col = col * (1 - crest[..., None] * 0.3) + worn * crest[..., None] * 0.3
    col = col * (0.76 + 0.34 * strands[..., None]) * (0.88 + 0.24 * n1[..., None])
    g3 = groove[..., None]
    col = col * (1 - g3) + inner * (0.6 + 0.4 * n1[..., None]) * g3
    li = tile_noise(S, S, ox=(16, 32, 64, 128), falloff=0.55)
    lich = (np.clip((li - 0.8) * 5.0, 0, 1) * plate * crest)[..., None]
    col = col * (1 - lich * 0.55) + np.array([0.64, 0.68, 0.56]) * lich * 0.55
    mo = tile_noise(S, S, ox=(8, 16, 32, 64), falloff=0.6)
    moss = (np.clip((mo - 0.62) * 3.0, 0, 1) * groove)[..., None]
    col = col * (1 - moss * 0.4) + np.array([0.16, 0.22, 0.09]) * moss * 0.4
    save_rgb(col, "ecorce.png")
    save_n(h, 7.0, "ecorce_n.png")


def planches():
    """Plancher des plates-formes : 6 planches par tuile, bois blond-roux ciré, veines, chevilles,
    joints sombres ; usé au milieu des planches."""
    S = 512
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    n1 = tile_noise(S, S, ox=(4, 8, 16, 32, 64), falloff=0.6)
    grain = tile_noise(S, S, ox=(2, 4, 8), oy=(32, 64, 128), falloff=0.7)
    pw = S / 6.0
    k = np.floor(xx / pw)
    tone = np.zeros((S, S), np.float32)
    for i in range(6):
        tone[k == i] = rng.uniform(0.82, 1.15)
    veins = np.abs(np.sin((xx / pw * 9.0 + grain * 7.0) * math.pi))
    col = np.array([0.6, 0.42, 0.26], np.float32)[None, None, :] * tone[..., None]
    col *= (0.78 + 0.22 * veins[..., None]) * (0.85 + 0.3 * n1[..., None])
    ex = np.mod(xx, pw)
    gap = np.clip(1.0 - np.minimum(ex, pw - ex) / 2.5, 0, 1)
    # abouts des planches (décalés d'une planche à l'autre)
    endpos = np.array([rng.uniform(0, S) for _ in range(6)])
    ey = np.abs(np.mod(yy - endpos[np.clip(k, 0, 5).astype(int)], S) - S / 2)
    endgap = np.clip(1.0 - (S / 2 - ey) / 2.0, 0, 1)
    col *= (1 - 0.75 * np.clip(gap + endgap, 0, 1))[..., None]
    wear = np.clip(1.0 - np.abs(ex - pw / 2) / (pw / 2), 0, 1) * n1
    col += wear[..., None] * np.array([0.07, 0.05, 0.03])
    h = veins * 0.25 + n1 * 0.3 - gap * 1.2 - endgap * 1.0
    for i in range(6):
        for y0 in (endpos[i] + 18, endpos[i] - 18):
            cx, cy = i * pw + pw / 2, y0 % S
            for sx in (-pw * 0.28, pw * 0.28):
                d2 = (xx - (cx + sx)) ** 2 + (yy - cy) ** 2
                m = d2 < 25
                col[m] *= 0.55
                h[m] -= 0.4
    save_rgb(col, "planches.png")
    save_n(h, 3.5, "planches_n.png")


def rondins():
    """Murs de rondins : 5 rondins horizontaux par tuile, arrondis, écorce par plaques, calfeutrés
    de mousse entre eux."""
    S = 512
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    n1 = tile_noise(S, S, ox=(4, 8, 16, 32, 64), falloff=0.6)
    grain = tile_noise(S, S, ox=(32, 64, 128), oy=(2, 4, 8), falloff=0.7)
    ph = S / 5.0
    v = np.mod(yy, ph) / ph
    round_ = np.sqrt(np.clip(1 - (v * 2 - 1) ** 2, 0, 1))
    k = np.floor(yy / ph)
    tone = np.zeros((S, S), np.float32)
    for i in range(5):
        tone[k == i] = rng.uniform(0.85, 1.12)
    col = np.array([0.5, 0.36, 0.24], np.float32)[None, None, :] * tone[..., None]
    col *= (0.55 + 0.5 * round_[..., None]) * (0.8 + 0.3 * grain[..., None]) * (0.9 + 0.2 * n1[..., None])
    bark = np.clip((tile_noise(S, S, ox=(16, 32, 64), falloff=0.6) - 0.6) * 3, 0, 1) * round_
    col = col * (1 - bark[..., None] * 0.35) + np.array([0.3, 0.23, 0.17]) * bark[..., None] * 0.35
    seam = np.clip(1 - round_ * 3.0, 0, 1)
    col = col * (1 - seam[..., None]) + np.array([0.2, 0.28, 0.12]) * (0.7 + 0.4 * n1[..., None]) * seam[..., None]
    h = round_ * 1.2 + grain * 0.2 + bark * 0.25
    save_rgb(col, "rondins.png")
    save_n(h, 3.0, "rondins_n.png")


def chaume():
    """Chaume : rangées de paille qui se recouvrent (le haut de chaque rangée sous la suivante),
    brins dorés et gris, plus sombre et moussu dans le bas des rangées."""
    S = 512
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    straw = tile_noise(S, S, ox=(64, 128, 256), oy=(4, 8, 16), falloff=0.75)
    n1 = tile_noise(S, S, ox=(4, 8, 16, 32), falloff=0.6)
    rows = 7.0
    v = np.mod(yy / S * rows + (n1 - 0.5) * 0.4, 1.0)
    shade = 0.45 + 0.55 * v ** 0.6
    col = np.array([0.66, 0.55, 0.34], np.float32)[None, None, :] * (0.7 + 0.45 * straw[..., None]) * shade[..., None]
    grey = np.clip((tile_noise(S, S, ox=(8, 16, 32), falloff=0.6) - 0.45) * 2, 0, 1)
    col = col * (1 - grey[..., None] * 0.35) + np.array([0.42, 0.4, 0.34]) * grey[..., None] * 0.35
    moss = np.clip((n1 - 0.6) * 3, 0, 1) * (1 - v)
    col = col * (1 - moss[..., None] * 0.5) + np.array([0.25, 0.32, 0.14]) * moss[..., None] * 0.5
    h = straw * 0.6 + v * 1.2
    save_rgb(col, "chaume.png")
    save_n(h, 4.0, "chaume_n.png")


def papier():
    """Papier washi des lanternes : fibres, nervures de bambou verticales et deux cerclages."""
    S = 256
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    fib = tile_noise(S, S, ox=(16, 32, 64, 128), falloff=0.7)
    col = np.array([0.98, 0.86, 0.62], np.float32)[None, None, :] * (0.88 + 0.16 * fib[..., None])
    for k in range(8):
        x0 = k * S / 8.0
        m = np.abs(xx - x0) < 1.6
        col[m] *= 0.62
    for y0 in (8, S - 8):
        m = np.abs(yy - y0) < 4
        col[m] = np.array([0.32, 0.18, 0.1])
    save_rgb(col, "papier.png")


def textures():
    ecorce()
    planches()
    rondins()
    chaume()
    papier()


# =================================================================== les rideaux-enseignes

def _ears(d, cx, cy, s, kind, ink):
    """Une tête stylisée d'animal (pour les enseignes) : renard, lapin, ours, tanuki, chouette."""
    if kind == "renard":
        d.polygon([(cx - s, cy - s * 0.2), (cx - s * 0.55, cy - s * 1.3), (cx - s * 0.1, cy - s * 0.45)], fill=ink)
        d.polygon([(cx + s, cy - s * 0.2), (cx + s * 0.55, cy - s * 1.3), (cx + s * 0.1, cy - s * 0.45)], fill=ink)
        d.polygon([(cx - s, cy - s * 0.4), (cx + s, cy - s * 0.4), (cx, cy + s * 0.9)], fill=ink)
    elif kind == "lapin":
        d.ellipse((cx - s * 0.6, cy - s * 1.9, cx - s * 0.15, cy - s * 0.2), fill=ink)
        d.ellipse((cx + s * 0.15, cy - s * 1.9, cx + s * 0.6, cy - s * 0.2), fill=ink)
        d.ellipse((cx - s * 0.75, cy - s * 0.55, cx + s * 0.75, cy + s * 0.8), fill=ink)
    elif kind == "ours":
        d.ellipse((cx - s * 0.95, cy - s * 0.95, cx - s * 0.35, cy - s * 0.35), fill=ink)
        d.ellipse((cx + s * 0.35, cy - s * 0.95, cx + s * 0.95, cy - s * 0.35), fill=ink)
        d.ellipse((cx - s * 0.8, cy - s * 0.7, cx + s * 0.8, cy + s * 0.85), fill=ink)
    elif kind == "tanuki":
        d.ellipse((cx - s * 0.9, cy - s * 0.9, cx - s * 0.4, cy - s * 0.4), fill=ink)
        d.ellipse((cx + s * 0.4, cy - s * 0.9, cx + s * 0.9, cy - s * 0.4), fill=ink)
        d.ellipse((cx - s * 0.85, cy - s * 0.65, cx + s * 0.85, cy + s * 0.75), fill=ink)
    elif kind == "chouette":
        d.ellipse((cx - s * 0.8, cy - s * 0.8, cx + s * 0.8, cy + s * 0.9), fill=ink)
        d.polygon([(cx - s * 0.8, cy - s * 0.5), (cx - s * 0.6, cy - s * 1.25), (cx - s * 0.25, cy - s * 0.75)], fill=ink)
        d.polygon([(cx + s * 0.8, cy - s * 0.5), (cx + s * 0.6, cy - s * 1.25), (cx + s * 0.25, cy - s * 0.75)], fill=ink)
    elif kind == "chat":
        d.polygon([(cx - s * 0.85, cy - s * 0.3), (cx - s * 0.7, cy - s * 1.2), (cx - s * 0.15, cy - s * 0.6)], fill=ink)
        d.polygon([(cx + s * 0.85, cy - s * 0.3), (cx + s * 0.7, cy - s * 1.2), (cx + s * 0.15, cy - s * 0.6)], fill=ink)
        d.ellipse((cx - s * 0.85, cy - s * 0.7, cx + s * 0.85, cy + s * 0.75), fill=ink)


def noren(name, title, cloth, ink, icon):
    """Un noren : rideau de tissu fendu en trois pans, accroché à une tringle de bambou ; un
    grand symbole et le nom de l'échoppe peints à la main."""
    W, H = 512, 512
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    gap = 8
    pw = (W - 2 * gap) / 3.0
    for i in range(3):
        x0 = i * (pw + gap)
        d.rectangle((x0, 24, x0 + pw, H - 6), fill=cloth + (255,))
    # la tringle
    d.rectangle((0, 8, W, 30), fill=(150, 116, 60, 255))
    for k in range(6):
        d.line((k * W / 6, 8, k * W / 6, 30), fill=(110, 84, 40, 255), width=3)
    arr = np.asarray(img, np.float32) / 255.0
    n = tile_noise(W, H, ox=(8, 16, 32, 64, 128), falloff=0.65)
    weave = tile_noise(W, H, ox=(128, 256), falloff=0.8)
    arr[..., :3] *= (0.86 + 0.18 * n[..., None]) * (0.95 + 0.1 * weave[..., None])
    img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(img)
    cx, cy = W // 2, 210
    # le symbole, dans un cercle
    d.ellipse((cx - 118, cy - 118, cx + 118, cy + 118), outline=ink + (255,), width=10)
    if icon in ("renard", "lapin", "ours", "tanuki", "chouette", "chat"):
        _ears(d, cx, cy + 16, 62, icon, ink + (255,))
    elif icon == "feuille":
        d.ellipse((cx - 50, cy - 90, cx + 50, cy + 70), fill=ink + (255,))
        d.line((cx, cy - 70, cx, cy + 100), fill=cloth + (255,), width=6)
        for k in range(4):
            d.line((cx, cy - 40 + k * 28, cx - 36, cy - 64 + k * 28), fill=cloth + (255,), width=4)
            d.line((cx, cy - 40 + k * 28, cx + 36, cy - 64 + k * 28), fill=cloth + (255,), width=4)
    elif icon == "carotte":
        d.polygon([(cx - 34, cy - 50), (cx + 34, cy - 50), (cx, cy + 96)], fill=ink + (255,))
        for a in (-0.5, 0.0, 0.5):
            d.ellipse((cx - 14 + a * 60, cy - 110, cx + 14 + a * 60, cy - 46), fill=ink + (255,))
    elif icon == "marteau":
        d.rectangle((cx - 80, cy - 70, cx + 60, cy - 22), fill=ink + (255,))
        d.rectangle((cx - 12, cy - 30, cx + 12, cy + 100), fill=ink + (255,))
    elif icon == "poisson":
        d.ellipse((cx - 90, cy - 44, cx + 50, cy + 44), fill=ink + (255,))
        d.polygon([(cx + 40, cy), (cx + 100, cy - 50), (cx + 100, cy + 50)], fill=ink + (255,))
        d.ellipse((cx - 62, cy - 14, cx - 44, cy + 4), fill=cloth + (255,))
    elif icon == "course":
        _ears(d, cx - 20, cy + 10, 50, "lapin", ink + (255,))
        for k in range(3):
            d.line((cx + 50, cy - 30 + k * 30, cx + 104, cy - 30 + k * 30), fill=ink + (255,), width=9)
    f = _font("Lora-BoldItalic.ttf", 50 if len(title) < 12 else 40)
    tw = d.textlength(title, font=f)
    d.text(((W - tw) / 2, 372), title, fill=ink + (255,), font=f)
    img = img.filter(ImageFilter.GaussianBlur(0.5))
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / name, optimize=True)
    print("ramure/" + name)


def banniere_lune():
    """La bannière du festival : une pleine lune dorée, deux silhouettes d'oreilles (renard et
    lapin) qui la regardent, sur un tissu indigo étoilé ; franges en bas."""
    W, H = 256, 640
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle((10, 18, W - 10, H - 40), fill=(28, 34, 78, 255))
    for k in range(14):
        x = 10 + k * (W - 20) / 13.0
        d.line((x, H - 40, x, H - 4), fill=(210, 170, 70, 255), width=5)
    d.rectangle((0, 4, W, 22), fill=(150, 116, 60, 255))
    arr = np.asarray(img, np.float32) / 255.0
    n = tile_noise(W, H, ox=(8, 16, 32, 64), falloff=0.65)
    arr[..., :3] *= (0.85 + 0.2 * n[..., None])
    img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(img)
    for _ in range(40):
        x, y = rng.uniform(20, W - 20), rng.uniform(30, H - 60)
        r = rng.uniform(1.0, 3.0)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(240, 230, 190, 255))
    d.ellipse((48, 70, 208, 230), fill=(246, 214, 120, 255))
    d.ellipse((70, 100, 104, 128), fill=(226, 190, 100, 255))
    d.ellipse((140, 160, 170, 184), fill=(226, 190, 100, 255))
    ink = (14, 16, 36, 255)
    _ears(d, 86, 380, 40, "renard", ink)
    _ears(d, 170, 392, 34, "lapin", ink)
    d.rectangle((40, 430, 216, 470), fill=ink)
    f = _font("Lora-BoldItalic.ttf", 34)
    t = "Pleine lune"
    d.text(((W - d.textlength(t, font=f)) / 2, 500), t, fill=(246, 214, 120, 255), font=f)
    img = img.filter(ImageFilter.GaussianBlur(0.4))
    img.save(OUT / "banniere_lune.png", optimize=True)
    print("ramure/banniere_lune.png")


def records():
    """Le tableau des records de la Grande Course : planche de bois, noms peints, temps."""
    W, H = 512, 384
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((6, 6, W - 6, H - 6), 18, fill=(112, 76, 44, 255))
    d.rounded_rectangle((22, 22, W - 22, H - 22), 12, fill=(176, 132, 82, 255))
    arr = np.asarray(img, np.float32) / 255.0
    g = tile_noise(W, H, ox=(64, 128, 256), oy=(4, 8, 16), falloff=0.7)
    arr[..., :3] *= (0.8 + 0.3 * g[..., None])
    img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(img)
    ink = (52, 30, 16, 255)
    f1 = _font("Lora-BoldItalic.ttf", 40)
    f2 = _font("Lora-Italic.ttf", 28)
    t = "La Grande Course"
    d.text(((W - d.textlength(t, font=f1)) / 2, 36), t, fill=ink, font=f1)
    d.line((60, 92, W - 60, 92), fill=ink, width=3)
    rows = [("1. Bondi le lapin", "1 min 42"), ("2. Grisou le loup", "1 min 47"), ("3. Éclair la chatte", "1 min 51"), ("4. Ursule l'ourse", "3 min 05"), ("Et toi ?", "…")]
    for i, (n, tm) in enumerate(rows):
        y = 112 + i * 46
        d.text((56, y), n, fill=ink, font=f2)
        d.text((W - 56 - d.textlength(tm, font=f2), y), tm, fill=ink, font=f2)
    _ears(d, W - 70, 56, 16, "lapin", ink)
    img = img.filter(ImageFilter.GaussianBlur(0.4))
    img.save(OUT / "records.png", optimize=True)
    print("ramure/records.png")


def signs():
    OUT.mkdir(parents=True, exist_ok=True)
    noren("noren_troc.png", "Le Grand Troc", (150, 60, 36), (246, 228, 196), "tanuki")
    noren("noren_simples.png", "Les Simples", (40, 72, 52), (236, 230, 200), "feuille")
    noren("noren_boulangerie.png", "Boulangerie", (210, 150, 70), (70, 36, 20), "carotte")
    noren("noren_forge.png", "La Forge", (56, 50, 50), (232, 160, 70), "marteau")
    noren("noren_poste.png", "La Poste", (40, 46, 96), (236, 226, 190), "chouette")
    noren("noren_peche.png", "Pêcherie", (34, 74, 110), (240, 236, 220), "poisson")
    noren("noren_course.png", "La Course", (176, 36, 40), (246, 232, 196), "course")
    banniere_lune()
    records()


# =================================================================== icônes

def icones():
    import generate_items_v28 as ic

    # champignon de lune (quête) : chapeau bleu pâle luminescent, pied blanc, halo
    img = ic.canvas()
    d = ImageDraw.Draw(img)
    halo = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    ImageDraw.Draw(halo).ellipse((60, 40, 452, 360), fill=(150, 210, 255, 90))
    img.alpha_composite(halo.filter(ImageFilter.GaussianBlur(30)))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((206, 230, 306, 470), 40, fill=(236, 236, 228))
    ic.shaded_ellipse(img, (90, 110, 422, 300), (150, 200, 240))
    d = ImageDraw.Draw(img)
    for (x, y, r) in ((170, 170, 18), (260, 150, 22), (340, 190, 16), (230, 220, 14), (310, 240, 12)):
        d.ellipse((x - r, y - r, x + r, y + r), fill=(230, 250, 255))
    ic.save(img, "champignon_lune")
    # caillou qui chante : galet gris veiné, notes de musique
    img = ic.canvas()
    ic.shaded_ellipse(img, (90, 190, 420, 430), (150, 156, 160))
    d = ImageDraw.Draw(img)
    d.arc((130, 230, 380, 400), 200, 340, fill=(230, 230, 236), width=8)
    for (x, y) in ((360, 110), (410, 160)):
        d.ellipse((x - 22, y - 16, x + 22, y + 16), fill=(60, 50, 90))
        d.line((x + 18, y, x + 18, y - 80), fill=(60, 50, 90), width=8)
    d.line((378, 30, 428, 80), fill=(60, 50, 90), width=8)
    ic.save(img, "caillou_chantant")
    # gland doré
    img = ic.canvas()
    ic.shaded_ellipse(img, (156, 200, 356, 470), (232, 184, 60))
    ic.shaded_ellipse(img, (130, 130, 382, 270), (150, 104, 50))
    d = ImageDraw.Draw(img)
    for k in range(6):
        d.line((150 + k * 40, 150, 140 + k * 40, 260), fill=(120, 80, 36), width=6)
    d.line((256, 130, 270, 60), fill=(110, 72, 34), width=14)
    ic.save(img, "gland_dore")
    # plume de lune : longue plume argent-bleuté
    img = ic.canvas()
    d = ImageDraw.Draw(img)
    pts = []
    for k in range(40):
        t = k / 39
        x = 120 + t * 290
        y = 440 - t * 380 + math.sin(t * math.pi) * 40
        pts.append((x, y))
    for i, (x, y) in enumerate(pts[3:]):
        t = i / 37
        w = 70 * math.sin(t * math.pi) + 6
        d.line((x, y, x - w * 0.8, y - w * 0.6), fill=(196, 214, 236), width=10)
        d.line((x, y, x + w * 0.6, y + w * 0.8), fill=(176, 196, 226), width=10)
    d.line(pts, fill=(240, 244, 250), width=8)
    ic.save(img, "plume_lune")
    # fiole de brume : fiole ronde pleine de brume nacrée
    img = ic.canvas()
    ic.shaded_ellipse(img, (120, 180, 392, 452), (200, 216, 230))
    d = ImageDraw.Draw(img)
    d.ellipse((150, 240, 362, 430), fill=(226, 232, 240))
    d.rectangle((216, 90, 296, 200), fill=(196, 214, 228))
    d.rectangle((206, 60, 306, 100), fill=(140, 100, 60))
    for k in range(3):
        d.arc((170 + k * 40, 260 + k * 30, 300 + k * 30, 360 + k * 20), 180, 360, fill=(250, 250, 255), width=10)
    ic.save(img, "fiole_brume")
    # clochette d'argent
    img = ic.canvas()
    ic.shaded_ellipse(img, (140, 140, 372, 420), (200, 204, 212))
    d = ImageDraw.Draw(img)
    d.rectangle((140, 300, 372, 420), fill=(0, 0, 0, 0))
    img2 = ic.canvas()
    d2 = ImageDraw.Draw(img2)
    d2.polygon([(170, 300), (342, 300), (400, 400), (112, 400)], fill=(196, 200, 210))
    img.alpha_composite(img2)
    d = ImageDraw.Draw(img)
    d.ellipse((226, 380, 286, 440), fill=(120, 120, 130))
    d.arc((216, 70, 296, 150), 180, 360, fill=(170, 60, 50), width=14)
    ic.save(img, "clochette_argent")
    # serre-tête oreilles de renard
    img = ic.canvas()
    d = ImageDraw.Draw(img)
    d.arc((70, 150, 442, 520), 190, 350, fill=(60, 36, 24), width=26)
    for sx in (-1, 1):
        cx = 256 + sx * 120
        d.polygon([(cx - 80, 300), (cx + 80, 300), (cx + sx * 20, 70)], fill=(214, 110, 40))
        d.polygon([(cx - 46, 290), (cx + 46, 290), (cx + sx * 14, 130)], fill=(246, 230, 210))
        d.polygon([(cx + sx * 20 - 20, 110), (cx + sx * 20 + 20, 110), (cx + sx * 20, 70)], fill=(40, 26, 20))
    ic.save(img, "oreilles_renard")
    # coupe de la Grande Course : coupe de bois dorée, oreilles de lapin sur les anses
    img = ic.canvas()
    d = ImageDraw.Draw(img)
    d.rectangle((196, 400, 316, 450), fill=(120, 80, 40))
    d.rectangle((236, 320, 276, 400), fill=(214, 170, 64))
    ic.shaded_ellipse(img, (126, 120, 386, 340), (230, 184, 60))
    d = ImageDraw.Draw(img)
    d.rectangle((126, 100, 386, 200), fill=(0, 0, 0, 0))
    img3 = ic.canvas()
    ic.shaded_ellipse(img3, (126, 150, 386, 340), (232, 188, 64))
    img = ic.canvas()
    img.alpha_composite(img3)
    d = ImageDraw.Draw(img)
    d.rectangle((196, 400, 316, 450), fill=(120, 80, 40))
    d.rectangle((236, 320, 276, 400), fill=(214, 170, 64))
    d.ellipse((136, 150, 376, 200), fill=(170, 120, 40))
    for sx in (-1, 1):
        d.ellipse((256 + sx * 150 - 26, 60, 256 + sx * 150 + 26, 230), fill=(232, 188, 64))
    ic.save(img, "coupe_course")
    # grelot de tanuki : gros grelot doré, cordon rouge
    img = ic.canvas()
    ic.shaded_ellipse(img, (126, 150, 386, 410), (226, 180, 60))
    d = ImageDraw.Draw(img)
    d.line((140, 280, 372, 280), fill=(150, 110, 30), width=8)
    d.ellipse((236, 300, 276, 340), fill=(60, 40, 20))
    d.line((256, 320, 256, 400), fill=(60, 40, 20), width=8)
    d.arc((200, 60, 312, 170), 180, 360, fill=(190, 40, 40), width=16)
    d.line((256, 60, 256, 20), fill=(190, 40, 40), width=12)
    ic.save(img, "grelot_tanuki")
    # pain de carotte : miche orangée, fanes vertes
    img = ic.canvas()
    ic.shaded_ellipse(img, (90, 220, 422, 430), (216, 130, 54))
    d = ImageDraw.Draw(img)
    for k in range(4):
        d.arc((140 + k * 50, 260, 210 + k * 50, 330), 200, 340, fill=(160, 84, 30), width=8)
    for a in (-0.6, -0.2, 0.2, 0.6):
        d.line((256, 230, 256 + a * 150, 90), fill=(70, 140, 50), width=14)
    ic.save(img, "pain_carotte")
    # gâteau de lune : rond, doré, motif de lune et d'oreilles en relief
    img = ic.canvas()
    ic.shaded_ellipse(img, (100, 140, 412, 420), (206, 150, 76))
    d = ImageDraw.Draw(img)
    d.ellipse((150, 190, 362, 372), outline=(150, 96, 40), width=10)
    d.ellipse((216, 236, 296, 316), fill=(236, 200, 120))
    _ears(d, 256, 300, 26, "lapin", (150, 96, 40))
    ic.save(img, "gateau_lune")
    # tisane de brume : bol de bois, vapeur
    img = ic.canvas()
    d = ImageDraw.Draw(img)
    d.pieslice((100, 160, 412, 440), 0, 180, fill=(130, 86, 50))
    d.ellipse((100, 230, 412, 310), fill=(150, 104, 62))
    d.ellipse((120, 240, 392, 300), fill=(170, 196, 160))
    for k in range(3):
        d.arc((160 + k * 60, 80, 230 + k * 60, 220), 200, 340, fill=(236, 240, 244, 220), width=10)
    ic.save(img, "tisane_brume")
    # brochette de poisson grillé
    img = ic.canvas()
    d = ImageDraw.Draw(img)
    d.line((60, 450, 452, 60), fill=(170, 130, 80), width=12)
    for k in range(3):
        cx, cy = 160 + k * 90, 350 - k * 90
        ic.shaded_ellipse(img, (cx - 60, cy - 36, cx + 60, cy + 36), (200, 136, 70))
        d = ImageDraw.Draw(img)
        d.line((cx - 40, cy + 10, cx + 30, cy - 20), fill=(110, 60, 30), width=6)
    ic.save(img, "brochette_poisson")


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else ""
    if what in ("", "textures"):
        textures()
    if what in ("", "enseignes"):
        signs()
    if what in ("", "icones"):
        icones()


if __name__ == "__main__":
    main()
