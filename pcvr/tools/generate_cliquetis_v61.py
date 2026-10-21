"""V61 : textures de Cliquetis, la cité des ingénieurs fous (le nord de la grande île).

cliquetis/  cuivre.png (+_n)    : tôles de cuivre rivetées, patine vert-de-gris qui coule des rivets ;
            laiton.png (+_n)    : laiton martelé, doré, poli par endroits ;
            brique.png (+_n)    : brique rouge d'usine, joints sombres, suie au-dessus des fenêtres ;
            ardoise.png (+_n)   : toits d'ardoise en écailles ;
            fonte.png (+_n)     : plaques de fonte striées, rivets (quais, plates-formes, passerelles) ;
            verriere.png        : verrière à petits carreaux (alpha dans le verre) ;
            cadran.png          : le cadran de la grande horloge (chiffres romains, alpha autour) ;
            affiches            : affiche_foire, affiche_dirigeable, affiche_telepherique ;
            enseignes           : enseigne_bazar, enseigne_bielle, enseigne_foire, enseigne_aerodrome, enseigne_boum.
items/      engrenage_or (quête), cafe_vapeur, biscuit_engrenage, et les curiosités du Bazar des
            Inutilités : parapluie_helice, chapeau_ventilateur, montre_envers, boite_a_rien,
            canard_mecanique, tasse_tourneuse, lunettes_kaleido, chaussettes_vapeur, sifflet_muet,
            boussole_sud.
Tout est dessiné ici (libre de droits).
Lancement depuis la racine du dépôt : python3 pcvr/tools/generate_cliquetis_v61.py [textures | enseignes | icones]
"""
from pathlib import Path
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_carene_v59 as gc  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "cliquetis"
FONTS = ROOT / "www" / "assets" / "fonts"
rng = np.random.default_rng(6161)
tile_noise = gc.tile_noise


def save_rgb(arr, name):
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGB").save(OUT / name, optimize=True)
    print("cliquetis/" + name)


def save_rgba(arr, name):
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA").save(OUT / name, optimize=True)
    print("cliquetis/" + name)


def save_n(h, strength, name):
    OUT.mkdir(parents=True, exist_ok=True)
    gc.normal_map(h, strength).save(OUT / name, optimize=True)
    print("cliquetis/" + name)


def rivets(S, h, col, xs, ys, r, tone):
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    for x in xs:
        for y in ys:
            d2 = (xx - x) ** 2 + (yy - y) ** 2
            m = d2 < r * r
            dome = np.sqrt(np.clip(1 - d2 / (r * r), 0, 1))
            h[m] += dome[m] * 1.6
            col[m] = col[m] * 0.35 + np.array(tone) * (0.55 + 0.6 * dome[m, None]) * 0.65


# =================================================================== métaux

def cuivre():
    """Tôles de cuivre : 4 x 3 plaques par tuile, rivets, patine verte qui coule vers le bas."""
    S = 1024
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    n1 = tile_noise(S, S, ox=(4, 8, 16, 32, 64, 128), falloff=0.6)
    n2 = tile_noise(S, S, ox=(8, 16, 32, 64), falloff=0.6)
    base = np.array([0.72, 0.4, 0.24], np.float32)
    col = base[None, None, :] * (0.78 + 0.35 * n1[..., None])
    pw, ph = S / 4, S / 3
    px = np.floor(xx / pw)
    py = np.floor(yy / ph)
    for i in range(4):
        for j in range(3):
            m = (px == i) & (py == j)
            col[m] *= rng.uniform(0.85, 1.12)
    h = n1 * 0.4
    # recouvrement des plaques (le bord du dessus chevauche)
    ex = np.minimum(np.mod(xx, pw), pw - np.mod(xx, pw))
    ey = np.mod(yy, ph)
    edge = np.clip(1.0 - ex / 4.0, 0, 1) + np.clip(1.0 - ey / 5.0, 0, 1)
    col *= (1.0 - 0.35 * np.clip(edge, 0, 1))[..., None]
    h -= edge * 0.8
    # patine : vert-de-gris en coulures sous les rivets et dans les recoins
    run = tile_noise(S, S, ox=(64, 128, 256), oy=(4, 8, 16), falloff=0.6)
    yrel = np.mod(yy, ph) / ph
    pat = np.clip((n2 - 0.66) * 3.0, 0, 1) * 0.5 + np.clip((run - 0.72) * 3.0, 0, 1) * (0.2 + 0.6 * yrel)
    verd = np.array([0.32, 0.62, 0.52], np.float32)
    col = col * (1 - pat[..., None] * 0.85) + verd * (0.75 + 0.35 * n1[..., None]) * pat[..., None] * 0.85
    # reflets polis
    shine = np.clip((n2 - 0.75) * 4, 0, 1) * (1 - pat)
    col += shine[..., None] * np.array([0.25, 0.15, 0.08])
    rivets(S, h, col, [k * pw + 12 for k in range(4)] + [k * pw + pw - 12 for k in range(4)], [k * ph + 14 + t * (ph - 28) / 5 for k in range(3) for t in range(6)], 6, (0.62, 0.36, 0.22))
    save_rgb(col, "cuivre.png")
    save_n(h, 4.0, "cuivre_n.png")


def laiton():
    S = 512
    n1 = tile_noise(S, S, ox=(4, 8, 16, 32, 64), falloff=0.6)
    hammer = tile_noise(S, S, ox=(32, 64, 128), falloff=0.7)
    col = np.array([0.82, 0.64, 0.3], np.float32)[None, None, :] * (0.8 + 0.3 * n1[..., None])
    col += np.clip((hammer - 0.6) * 2.5, 0, 1)[..., None] * np.array([0.2, 0.16, 0.08])
    dark = np.clip((n1 - 0.68) * 3, 0, 1)
    col *= (1 - 0.35 * dark)[..., None]
    save_rgb(col, "laiton.png")
    save_n(hammer * 0.8 + n1 * 0.3, 3.0, "laiton_n.png")


def fonte():
    """Plaques de fonte striées (losanges en relief), rivets aux angles."""
    S = 512
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    n1 = tile_noise(S, S, ox=(4, 8, 16, 32, 64), falloff=0.6)
    col = np.array([0.3, 0.3, 0.31], np.float32)[None, None, :] * (0.75 + 0.4 * n1[..., None])
    a = np.mod(xx + yy, 32.0)
    b = np.mod(xx - yy, 32.0)
    ridge = ((np.abs(a - 16) < 2.5) | (np.abs(b - 16) < 2.5)).astype(np.float32) * ((np.mod(xx, 64) < 32) ^ (np.mod(yy, 64) < 32))
    h = ridge * 1.0 + n1 * 0.3
    col *= (1 + 0.2 * ridge)[..., None]
    seam = (np.mod(xx, 256) < 3) | (np.mod(yy, 256) < 3)
    col[seam] *= 0.4
    h[seam] -= 1.0
    rust = np.clip((tile_noise(S, S, ox=(8, 16, 32), falloff=0.6) - 0.65) * 3, 0, 1)
    col = col * (1 - rust[..., None] * 0.6) + np.array([0.42, 0.22, 0.1]) * rust[..., None] * 0.6
    rivets(S, h, col, [14, 242, 270, 498], [14, 242, 270, 498], 7, (0.4, 0.4, 0.42))
    save_rgb(col, "fonte.png")
    save_n(h, 4.0, "fonte_n.png")


# =================================================================== maçonnerie

def brique():
    """Brique rouge d'usine : 16 rangs par tuile (4 m), joints sombres, suie, briques brûlées."""
    S = 1024
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    rows = 16
    rh = S / rows
    bw = rh * 3.4
    row = np.floor(yy / rh)
    xo = xx + (row % 2) * bw * 0.5
    bx = np.floor(xo / bw)
    n1 = tile_noise(S, S, ox=(8, 16, 32, 64, 128), falloff=0.6)
    seed = (bx * 7.13 + row * 3.71) % 1.0
    tint = 0.78 + 0.36 * np.mod(np.sin(bx * 12.9898 + row * 78.233) * 43758.5453, 1.0)
    base = np.array([0.6, 0.24, 0.16], np.float32)
    col = base[None, None, :] * tint[..., None] * (0.82 + 0.3 * n1[..., None])
    burnt = np.mod(np.sin(bx * 4.1 + row * 9.3) * 1000.0, 1.0) > 0.86
    col[burnt] *= np.array([0.55, 0.5, 0.55])
    jx = np.minimum(np.mod(xo, bw), bw - np.mod(xo, bw))
    jy = np.minimum(np.mod(yy, rh), rh - np.mod(yy, rh))
    joint = (jx < 3.0) | (jy < 3.0)
    col[joint] = np.array([0.24, 0.22, 0.2]) * (0.8 + 0.4 * n1[joint, None])
    h = n1 * 0.4 - joint * 1.2
    soot = tile_noise(S, S, ox=(2, 4, 8, 16), falloff=0.6)
    s = np.clip((soot - 0.6) * 2.5, 0, 1) * (1.0 - yy / S)
    col *= (1 - 0.45 * s)[..., None]
    save_rgb(col, "brique.png")
    save_n(h, 5.0, "brique_n.png")


def ardoise():
    """Ardoises en écailles (rangées décalées, bord arrondi)."""
    S = 512
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    rh = S / 10
    tw = S / 8
    row = np.floor(yy / rh)
    xo = xx + (row % 2) * tw * 0.5
    cx = np.floor(xo / tw) * tw + tw / 2
    u = (xo - cx) / (tw / 2)
    v = (yy - row * rh) / rh
    scale = (v + u * u * 0.35) < 1.0
    n1 = tile_noise(S, S, ox=(8, 16, 32, 64), falloff=0.6)
    tone = 0.75 + 0.3 * np.mod(np.sin(np.floor(xo / tw) * 12.9 + row * 78.2) * 4375.5, 1.0)
    col = np.array([0.26, 0.28, 0.33], np.float32)[None, None, :] * tone[..., None] * (0.85 + 0.25 * n1[..., None])
    edge = ~scale
    col[edge] *= 0.5
    h = v * 0.8 + n1 * 0.2 - edge * 0.6
    lichen = np.clip((tile_noise(S, S, ox=(8, 16, 32), falloff=0.6) - 0.72) * 4, 0, 1)
    col = col * (1 - lichen[..., None] * 0.5) + np.array([0.6, 0.6, 0.4]) * lichen[..., None] * 0.5
    save_rgb(col, "ardoise.png")
    save_n(h, 4.0, "ardoise_n.png")


def verriere():
    """Verrière : petits carreaux légèrement teintés (alpha), montants de fer noir."""
    S = 512
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    cw, chh = S / 4, S / 6
    n1 = tile_noise(S, S, ox=(4, 8, 16, 32), falloff=0.6)
    col = np.array([0.62, 0.78, 0.74], np.float32)[None, None, :] * (0.8 + 0.3 * n1[..., None])
    alpha = 0.32 + 0.18 * n1
    frame = (np.minimum(np.mod(xx, cw), cw - np.mod(xx, cw)) < 5) | (np.minimum(np.mod(yy, chh), chh - np.mod(yy, chh)) < 4)
    col[frame] = np.array([0.08, 0.08, 0.09])
    alpha[frame] = 1.0
    grime = np.clip((tile_noise(S, S, ox=(8, 16, 32), falloff=0.6) - 0.6) * 2, 0, 1)
    alpha = np.where(frame, alpha, np.clip(alpha + grime * 0.3, 0, 0.9))
    save_rgba(np.dstack([col, alpha]), "verriere.png")


def cadran():
    S = 512
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = S // 2
    d.ellipse((6, 6, S - 6, S - 6), fill=(200, 160, 80, 255))
    d.ellipse((26, 26, S - 26, S - 26), fill=(238, 230, 206, 255))
    f = ImageFont.truetype(str(FONTS / "Lora-Bold.ttf"), 48) if (FONTS / "Lora-Bold.ttf").exists() else ImageFont.truetype(str(FONTS / "Lora-BoldItalic.ttf"), 48)
    num = ["XII", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI"]
    for k in range(12):
        a = k * math.tau / 12 - math.pi / 2
        r = S * 0.36
        x, y = c + math.cos(a) * r, c + math.sin(a) * r
        tw = d.textlength(num[k], font=f)
        d.text((x - tw / 2, y - 28), num[k], fill=(30, 26, 22, 255), font=f)
    for k in range(60):
        a = k * math.tau / 60
        r0 = S * 0.45 if k % 5 else S * 0.43
        d.line((c + math.cos(a) * r0, c + math.sin(a) * r0, c + math.cos(a) * S * 0.465, c + math.sin(a) * S * 0.465), fill=(30, 26, 22, 255), width=3 if k % 5 else 6)
    # le mécanisme visible au centre (cadran squelette)
    for k in range(12):
        a = k * math.tau / 12
        d.polygon([(c + math.cos(a) * 60, c + math.sin(a) * 60), (c + math.cos(a + 0.12) * 74, c + math.sin(a + 0.12) * 74),
                   (c + math.cos(a + 0.4) * 74, c + math.sin(a + 0.4) * 74), (c + math.cos(a + 0.52) * 60, c + math.sin(a + 0.52) * 60)], fill=(150, 110, 50, 255))
    d.ellipse((c - 62, c - 62, c + 62, c + 62), fill=(150, 110, 50, 255))
    d.ellipse((c - 40, c - 40, c + 40, c + 40), fill=(60, 50, 40, 255))
    arr = np.asarray(img, np.float32) / 255.0
    arr[..., :3] *= (0.85 + 0.2 * tile_noise(S, S, ox=(8, 16, 32), falloff=0.6)[..., None])
    save_rgba(arr, "cadran.png")


def textures():
    cuivre()
    laiton()
    fonte()
    brique()
    ardoise()
    verriere()
    cadran()


# =================================================================== enseignes et affiches

def _font(name, size):
    p = FONTS / name
    return ImageFont.truetype(str(p if p.exists() else FONTS / "Lora-BoldItalic.ttf"), size)


def gear_shape(d, cx, cy, r, teeth, fill, hole=None):
    pts = []
    for k in range(teeth * 4):
        a = k * math.tau / (teeth * 4)
        rr = r if (k % 4) in (1, 2) else r * 0.8
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    d.polygon(pts, fill=fill)
    if hole:
        d.ellipse((cx - r * 0.3, cy - r * 0.3, cx + r * 0.3, cy + r * 0.3), fill=hole)


def enseigne(name, title, sub, bg, ink, frame, icon):
    W, H = 512, 256
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # un panneau de laiton riveté, coins coupés
    poly = [(20, 8), (W - 20, 8), (W - 8, 20), (W - 8, H - 20), (W - 20, H - 8), (20, H - 8), (8, H - 20), (8, 20)]
    d.polygon(poly, fill=frame + (255,))
    inner = [(30, 20), (W - 30, 20), (W - 20, 30), (W - 20, H - 30), (W - 30, H - 20), (30, H - 20), (20, H - 30), (20, 30)]
    d.polygon(inner, fill=bg + (255,))
    for (x, y) in ((22, 22), (W - 22, 22), (22, H - 22), (W - 22, H - 22), (W // 2, 14), (W // 2, H - 14)):
        d.ellipse((x - 5, y - 5, x + 5, y + 5), fill=(90, 70, 40, 255))
    arr = np.asarray(img, np.float32) / 255.0
    n = tile_noise(W, H, ox=(8, 16, 32, 64), falloff=0.6)
    arr[..., :3] *= (0.82 + 0.25 * n[..., None])
    img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(img)
    f1 = _font("Lora-BoldItalic.ttf", 44 if len(title) < 20 else 36)
    f2 = _font("Lora-Italic.ttf", 23)
    tw = d.textlength(title, font=f1)
    d.text(((W - tw) / 2, 104), title, fill=ink + (255,), font=f1)
    sw = d.textlength(sub, font=f2)
    d.text(((W - sw) / 2, 164), sub, fill=ink + (235,), font=f2)
    cx, cy = W // 2, 62
    if icon == "engrenage":
        gear_shape(d, cx - 22, cy, 30, 10, ink + (255,), bg + (255,))
        gear_shape(d, cx + 26, cy - 8, 20, 8, ink + (255,), bg + (255,))
    elif icon == "tasse":
        d.rounded_rectangle((cx - 26, cy - 18, cx + 18, cy + 24), 8, fill=ink)
        d.arc((cx + 6, cy - 10, cx + 34, cy + 16), 270, 90, fill=ink, width=6)
        for k in range(3):
            d.arc((cx - 20 + k * 14, cy - 46, cx - 6 + k * 14, cy - 22), 180, 360, fill=ink, width=3)
    elif icon == "dirigeable":
        d.ellipse((cx - 60, cy - 22, cx + 60, cy + 16), fill=ink)
        d.polygon([(cx - 60, cy - 6), (cx - 80, cy - 26), (cx - 80, cy + 14)], fill=ink)
        d.rectangle((cx - 16, cy + 18, cx + 18, cy + 30), fill=ink)
    elif icon == "boum":
        pts = []
        for k in range(16):
            a = k * math.tau / 16
            r = 36 if k % 2 == 0 else 18
            pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
        d.polygon(pts, fill=ink)
    elif icon == "bazar":
        d.ellipse((cx - 30, cy - 30, cx + 30, cy + 30), outline=ink, width=6)
        d.text((cx - 14, cy - 34), "?", fill=ink, font=_font("Lora-BoldItalic.ttf", 52))
    img = img.filter(ImageFilter.GaussianBlur(0.4))
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / name, optimize=True)
    print("cliquetis/" + name)


def affiche(name, title, lines, bg, ink, accent, icon):
    W, H = 360, 512
    img = Image.new("RGB", (W, H), bg)
    d = ImageDraw.Draw(img)
    d.rectangle((14, 14, W - 14, H - 14), outline=ink, width=5)
    d.rectangle((24, 24, W - 24, H - 24), outline=accent, width=2)
    f1 = _font("Lora-BoldItalic.ttf", 40)
    f2 = _font("Lora-Italic.ttf", 22)
    y = 40
    for word in title.split("|"):
        tw = d.textlength(word, font=f1)
        d.text(((W - tw) / 2, y), word, fill=ink, font=f1)
        y += 46
    cx, cy = W // 2, y + 110
    if icon == "foire":
        gear_shape(d, cx, cy, 90, 14, accent, bg)
        gear_shape(d, cx + 88, cy + 70, 44, 9, ink, bg)
        gear_shape(d, cx - 86, cy + 64, 38, 8, ink, bg)
    elif icon == "dirigeable":
        d.ellipse((cx - 130, cy - 54, cx + 120, cy + 40), fill=accent)
        for k in range(1, 6):
            d.arc((cx - 130 + k * 40, cy - 54, cx - 70 + k * 40, cy + 40), 270, 90, fill=ink, width=2)
        d.polygon([(cx - 120, cy - 10), (cx - 160, cy - 60), (cx - 160, cy + 40)], fill=ink)
        d.rectangle((cx - 40, cy + 46, cx + 40, cy + 70), fill=ink)
        for k in range(4):
            d.line((cx - 40 + k * 26, cy + 40, cx - 36 + k * 26, cy + 46), fill=ink, width=2)
    elif icon == "telepherique":
        d.line((20, cy + 80, W - 20, cy - 80), fill=ink, width=4)
        d.line((20, cy + 90, W - 20, cy - 70), fill=ink, width=2)
        d.line((cx, cy - 6, cx, cy + 24), fill=ink, width=4)
        d.rounded_rectangle((cx - 50, cy + 24, cx + 50, cy + 104), 12, fill=accent, outline=ink, width=4)
        for k in range(3):
            d.rectangle((cx - 40 + k * 28, cy + 36, cx - 18 + k * 28, cy + 64), fill=bg)
    y = cy + 150
    for ln in lines:
        tw = d.textlength(ln, font=f2)
        d.text(((W - tw) / 2, y), ln, fill=ink, font=f2)
        y += 30
    arr = np.asarray(img, np.float32) / 255.0
    n = tile_noise(W, H, ox=(4, 8, 16, 32, 64), falloff=0.6)
    arr *= (0.8 + 0.26 * n[..., None])
    stain = np.clip((tile_noise(W, H, ox=(4, 8, 16), falloff=0.6) - 0.7) * 2, 0, 1)
    arr = arr * (1 - stain[..., None] * 0.3) + np.array([0.5, 0.4, 0.25]) * stain[..., None] * 0.3
    save_rgb(arr, name)


def signs():
    enseigne("enseigne_bazar.png", "Bazar des Inutilités", "tout ce dont vous n'avez pas besoin", (60, 30, 70), (240, 214, 140), (190, 150, 70), "bazar")
    enseigne("enseigne_bielle.png", "Café de la Bielle", "café à vapeur — service par robot", (30, 52, 46), (236, 210, 150), (176, 120, 60), "tasse")
    enseigne("enseigne_foire.png", "Grande Foire des Inventions", "démonstrations tous les jours", (120, 30, 26), (246, 226, 170), (200, 160, 70), "engrenage")
    enseigne("enseigne_aerodrome.png", "Aérodrome", "dirigeable : Tazira, Carène", (24, 40, 70), (230, 214, 160), (176, 140, 70), "dirigeable")
    enseigne("enseigne_boum.png", "Atelier du Pr Boum", "entrée à vos risques et périls", (230, 196, 40), (30, 24, 20), (40, 36, 32), "boum")
    affiche("affiche_foire.png", "GRANDE|FOIRE", ["des Inventions de Cliquetis", "machines, automates, prodiges", "entrée libre — jury à midi"], (232, 214, 170), (60, 30, 20), (170, 60, 30), "foire")
    affiche("affiche_dirigeable.png", "LE|ZÉPHYR", ["dirigeable de ligne", "Cliquetis — Tazira — Carène", "départs sans arrêt, gratuit"], (210, 222, 220), (24, 36, 60), (180, 120, 60), "dirigeable")
    affiche("affiche_telepherique.png", "TÉLÉ-|PHÉRIQUE", ["du port à la cité", "en quarante secondes", "ne pas se pencher"], (236, 200, 120), (40, 26, 20), (120, 160, 150), "telepherique")


# =================================================================== icônes

def icones():
    import generate_items_v28 as ic
    S = 512

    def gear_layer(cx, cy, r, teeth, base):
        lay = ic.canvas()
        mask = Image.new("L", (S, S), 0)
        dm = ImageDraw.Draw(mask)
        gear_shape(dm, cx, cy, r, teeth, 255, 0)
        sh = ic.canvas()
        ic.shaded_ellipse(sh, (cx - r, cy - r, cx + r, cy + r), base)
        lay.paste(sh, (0, 0), mask)
        return lay

    # engrenage d'or (quête)
    img = gear_layer(256, 256, 200, 14, (236, 186, 60))
    d = ImageDraw.Draw(img)
    d.ellipse((196, 196, 316, 316), fill=(0, 0, 0, 0))
    img2 = ic.canvas()
    img2.alpha_composite(img)
    ImageDraw.Draw(img2).ellipse((206, 206, 306, 306), fill=(120, 80, 20, 255))
    ImageDraw.Draw(img2).ellipse((226, 226, 286, 286), fill=(0, 0, 0, 0))
    ic.save(img2, "engrenage_or")
    # café vapeur : tasse de laiton, vapeur
    img = ic.canvas()
    ic.shaded_ellipse(img, (120, 230, 380, 450), (196, 150, 70))
    d = ImageDraw.Draw(img)
    d.rectangle((120, 230, 380, 340), fill=(0, 0, 0, 0))
    d2 = ic.canvas()
    ic.shaded_ellipse(d2, (120, 180, 380, 460), (190, 140, 64))
    img.alpha_composite(d2)
    d = ImageDraw.Draw(img)
    d.ellipse((140, 186, 360, 246), fill=(60, 34, 18))
    d.arc((340, 250, 450, 370), 270, 90, fill=(170, 120, 50), width=22)
    for k in range(3):
        d.arc((170 + k * 60, 60, 230 + k * 60, 180), 200, 340, fill=(240, 240, 240, 220), width=12)
    ic.save(img, "cafe_vapeur")
    # biscuit-engrenage
    img = gear_layer(256, 256, 190, 10, (214, 160, 90))
    d = ImageDraw.Draw(img)
    for k in range(10):
        a = k * math.tau / 10
        d.ellipse((256 + math.cos(a) * 110 - 10, 256 + math.sin(a) * 110 - 10, 256 + math.cos(a) * 110 + 10, 256 + math.sin(a) * 110 + 10), fill=(150, 96, 50))
    d.ellipse((216, 216, 296, 296), fill=(110, 60, 30))
    ic.save(img, "biscuit_engrenage")
    # parapluie à hélice
    img = ic.canvas()
    d = ImageDraw.Draw(img)
    d.pieslice((70, 170, 442, 470), 180, 360, fill=(170, 40, 60))
    for k in range(1, 6):
        x = 70 + k * 62
        d.line((256, 172, x, 320), fill=(110, 20, 40), width=4)
    d.line((256, 320, 256, 470), fill=(60, 40, 30), width=14)
    d.arc((210, 430, 270, 490), 0, 180, fill=(60, 40, 30), width=14)
    d.line((256, 80, 256, 175), fill=(120, 120, 126), width=10)
    d.polygon([(256, 80), (130, 60), (130, 100)], fill=(200, 170, 80))
    d.polygon([(256, 80), (382, 60), (382, 100)], fill=(200, 170, 80))
    d.ellipse((240, 64, 272, 96), fill=(150, 120, 60))
    ic.save(img, "parapluie_helice")
    # chapeau-ventilateur
    img = ic.canvas()
    ic.shaded_ellipse(img, (70, 330, 442, 420), (50, 46, 50))
    d = ImageDraw.Draw(img)
    d.rectangle((150, 180, 362, 380), fill=(56, 52, 58))
    d.ellipse((150, 160, 362, 210), fill=(70, 66, 74))
    d.rectangle((150, 330, 362, 352), fill=(160, 40, 40))
    d.line((256, 60, 256, 170), fill=(140, 140, 146), width=10)
    for a in (0.3, 2.4, 4.5):
        d.polygon([(256, 64), (256 + math.cos(a) * 120, 64 + math.sin(a) * 40), (256 + math.cos(a + 0.5) * 120, 64 + math.sin(a + 0.5) * 40)], fill=(200, 200, 210))
    ic.save(img, "chapeau_ventilateur")
    # montre qui tourne à l'envers
    img = ic.canvas()
    ic.shaded_ellipse(img, (90, 110, 422, 442), (210, 170, 80))
    d = ImageDraw.Draw(img)
    d.ellipse((120, 140, 392, 412), fill=(240, 234, 214))
    for k in range(12):
        a = -k * math.tau / 12 - math.pi / 2
        d.ellipse((256 + math.cos(a) * 110 - 7, 276 + math.sin(a) * 110 - 7, 256 + math.cos(a) * 110 + 7, 276 + math.sin(a) * 110 + 7), fill=(40, 30, 20))
    d.line((256, 276, 196, 210), fill=(40, 30, 20), width=10)
    d.line((256, 276, 300, 190), fill=(40, 30, 20), width=6)
    d.arc((170, 190, 342, 362), 200, 320, fill=(200, 40, 40), width=8)
    d.polygon([(178, 248), (160, 262), (186, 270)], fill=(200, 40, 40))
    d.rectangle((236, 70, 276, 112), fill=(190, 150, 70))
    ic.save(img, "montre_envers")
    # boîte à rien
    img = ic.canvas()
    d = ImageDraw.Draw(img)
    d.polygon([(110, 220), (330, 180), (410, 230), (190, 280)], fill=(150, 100, 60))
    d.polygon([(110, 220), (190, 280), (190, 440), (110, 380)], fill=(110, 70, 40))
    d.polygon([(190, 280), (410, 230), (410, 390), (190, 440)], fill=(130, 84, 50))
    d.polygon([(110, 220), (330, 180), (300, 110), (90, 150)], fill=(170, 116, 70))
    d.text((250, 300), "RIEN", fill=(240, 220, 160), font=_font("Lora-BoldItalic.ttf", 48))
    ic.save(img, "boite_a_rien")
    # canard mécanique
    img = ic.canvas()
    ic.shaded_ellipse(img, (110, 250, 400, 430), (230, 190, 60))
    ic.shaded_ellipse(img, (290, 140, 420, 270), (232, 196, 70))
    d = ImageDraw.Draw(img)
    d.polygon([(410, 200), (480, 214), (410, 232)], fill=(220, 110, 40))
    d.ellipse((350, 180, 372, 202), fill=(20, 20, 20))
    d.ellipse((60, 280, 150, 370), outline=(160, 130, 60), width=16)
    d.line((105, 325, 150, 325), fill=(160, 130, 60), width=14)
    for k in range(3):
        d.ellipse((150 + k * 70, 300, 186 + k * 70, 336), fill=(160, 110, 30))
    ic.save(img, "canard_mecanique")
    # tasse tourneuse
    img = ic.canvas()
    ic.shaded_ellipse(img, (130, 200, 380, 450), (232, 232, 236))
    d = ImageDraw.Draw(img)
    d.ellipse((140, 190, 370, 250), fill=(110, 70, 40))
    d.arc((340, 260, 450, 380), 270, 90, fill=(220, 220, 226), width=22)
    d.line((256, 220, 256, 70), fill=(150, 150, 156), width=10)
    d.rectangle((226, 50, 286, 80), fill=(190, 150, 70))
    d.arc((180, 180, 330, 260), 190, 350, fill=(230, 200, 150), width=6)
    for k in range(3):
        d.line((236 + k * 20, 40, 230 + k * 20, 20), fill=(240, 220, 120), width=4)
    ic.save(img, "tasse_tourneuse")
    # lunettes kaléidoscope
    img = ic.canvas()
    d = ImageDraw.Draw(img)
    for cx in (160, 352):
        ic.shaded_ellipse(img, (cx - 90, 170, cx + 90, 350), (180, 140, 60))
        d = ImageDraw.Draw(img)
        for k in range(6):
            a = k * math.tau / 6
            col = [(220, 60, 80), (60, 160, 220), (240, 200, 60), (80, 200, 120), (180, 80, 220), (240, 130, 40)][k]
            d.pieslice((cx - 66, 194, cx + 66, 326), math.degrees(a), math.degrees(a) + 60, fill=col)
    d.arc((222, 230, 290, 290), 200, 340, fill=(140, 100, 40), width=12)
    d.line((70, 240, 20, 220), fill=(140, 100, 40), width=12)
    d.line((442, 240, 492, 220), fill=(140, 100, 40), width=12)
    ic.save(img, "lunettes_kaleido")
    # chaussettes à vapeur
    img = ic.canvas()
    d = ImageDraw.Draw(img)
    for ox, colr in ((0, (200, 60, 60)), (150, (60, 120, 190))):
        d.rounded_rectangle((90 + ox, 120, 190 + ox, 360), 30, fill=colr)
        d.rounded_rectangle((90 + ox, 300, 270 + ox, 400), 46, fill=colr)
        for k in range(4):
            d.rectangle((90 + ox, 140 + k * 40, 190 + ox, 152 + k * 40), fill=(240, 236, 220))
        d.rectangle((110 + ox, 90, 130 + ox, 130), fill=(170, 130, 60))
        for k in range(2):
            d.arc((96 + ox + k * 30, 30, 136 + ox + k * 30, 90), 200, 340, fill=(240, 240, 240), width=8)
    ic.save(img, "chaussettes_vapeur")
    # sifflet muet
    img = ic.canvas()
    ic.shaded_ellipse(img, (110, 210, 330, 400), (200, 200, 206))
    d = ImageDraw.Draw(img)
    d.rectangle((300, 260, 460, 330), fill=(196, 196, 202))
    d.rectangle((250, 230, 290, 260), fill=(60, 60, 70))
    d.line((130, 160, 380, 440), fill=(200, 40, 40), width=18)
    ic.save(img, "sifflet_muet")
    # boussole qui indique le sud
    img = ic.canvas()
    ic.shaded_ellipse(img, (90, 90, 422, 422), (180, 140, 70))
    d = ImageDraw.Draw(img)
    d.ellipse((120, 120, 392, 392), fill=(236, 230, 210))
    d.polygon([(256, 380), (230, 256), (282, 256)], fill=(200, 40, 40))
    d.polygon([(256, 132), (230, 256), (282, 256)], fill=(60, 60, 70))
    d.text((240, 140), "S", fill=(40, 30, 20), font=_font("Lora-BoldItalic.ttf", 40))
    d.text((240, 330), "S", fill=(40, 30, 20), font=_font("Lora-BoldItalic.ttf", 40))
    ic.save(img, "boussole_sud")


if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else ""
    if what in ("", "textures"):
        textures()
    if what in ("", "enseignes"):
        signs()
    if what in ("", "icones"):
        icones()
