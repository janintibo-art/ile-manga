"""V59 : textures de Carène, le port bâti dans l'épave du Léviathan, sur la grande île de l'est.

carene/  bordage.png (+_n)     : le bordé extérieur de la coque — virures de chêne vieilli, coutures
                                 calfatées au brai, chevilles de bois, abouts décalés, restes de
                                 peinture (ocre, rouge sang de bœuf, noir) délavés par le sel ;
         bordage_int.png (+_n) : le vaigrage intérieur — planches brutes, goudronnées, plus sombres ;
         pont.png (+_n)        : le pont — longues planches blanchies, coutures noires, clous ;
         salissures.png (+_n)  : la carène sous la ligne de flottaison — anatifes, balanes, moules,
                                 algues vertes, coulures de rouille ;
         voile.png             : une voile déchirée, rapiécée, tachée (alpha dans les trous) ;
         toile_rouge.png, toile_bleue.png : toiles rayées des étals ;
         planches_cabane.png (+_n) : les cabanes du pont, faites de planches de récupération.
         enseignes : enseigne_bordee.png (la taverne), enseigne_cale.png (le marché),
                     enseigne_forge.png, enseigne_voilerie.png, enseigne_capitainerie_carene.png.
Tout est dessiné ici (libre de droits).
items/   galette_sarrasin, grog_bordee, cidre_carene (argument « icones »).
Lancement depuis la racine du dépôt : python3 pcvr/tools/generate_carene_v59.py
"""
from pathlib import Path
import math

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "carene"
FONTS = ROOT / "www" / "assets" / "fonts"
rng = np.random.default_rng(5959)


def tile_noise(w, h, ox=(4, 8, 16, 32, 64, 128), oy=None, falloff=0.55):
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


def save_rgb(arr, name):
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGB").save(OUT / name, optimize=True)
    print("carene/" + name)


def save_rgba(arr, name):
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA").save(OUT / name, optimize=True)
    print("carene/" + name)


def save_n(h, strength, name):
    OUT.mkdir(parents=True, exist_ok=True)
    normal_map(h, strength).save(OUT / name, optimize=True)
    print("carene/" + name)


def wood_grain(w, h, along_x=True, scale=1.0):
    """Veinage du bois : bruit très étiré dans le sens des fibres."""
    if along_x:
        g = tile_noise(w, h, ox=(2, 4, 8, 16), oy=(32, 64, 128, 256), falloff=0.6)
    else:
        g = tile_noise(w, h, ox=(32, 64, 128, 256), oy=(2, 4, 8, 16), falloff=0.6)
    return g


# =================================================================== bordé extérieur

def planks(S, rows, colors, paint_bands, seam_dark, bleach, name, nname, butt_len=(0.3, 0.7), tar=0.0):
    """Des virures horizontales : chaque rangée a sa teinte, ses abouts décalés."""
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    grain = wood_grain(S, S, True)
    fine = tile_noise(S, S, ox=(64, 128, 256), oy=(16, 32, 64), falloff=0.6)
    blot = tile_noise(S, S, ox=(3, 6, 12, 24), falloff=0.6)
    row_h = S / rows
    row = np.floor(yy / row_h).astype(int)
    in_row = (yy - row * row_h) / row_h
    col = np.zeros((S, S, 3), np.float32)
    h = np.zeros((S, S), np.float32)
    seams = np.zeros((S, S), np.float32)
    for r in range(rows):
        m = row == r
        base = np.array(colors[rng.integers(0, len(colors))], np.float32) * rng.uniform(0.85, 1.12)
        c = base[None, :] * (0.78 + 0.4 * grain[m])[:, None]
        col[m] = c
        # abouts (joints entre deux planches de la même virure)
        L = S * rng.uniform(*butt_len)
        off = rng.uniform(0, L)
        bx = np.mod(xx[m] + off, L)
        butt = np.clip(1.0 - np.minimum(bx, L - bx) / 2.2, 0, 1)
        seams[m] = np.maximum(seams[m], butt)
    # coutures entre virures (calfatage au brai)
    edge = np.minimum(in_row, 1.0 - in_row) * row_h
    seam_h = np.clip(1.0 - edge / 2.6, 0, 1)
    seams = np.maximum(seams, seam_h)
    # chevilles (gournables) : deux par membrure
    for r in range(rows):
        for k in range(int(S / 64)):
            for d in (0.3, 0.7):
                cx = k * 64 + 20 + rng.uniform(-3, 3)
                cy = (r + d) * row_h
                rr = 2.6
                m2 = (xx - cx) ** 2 + (yy - cy) ** 2 < rr * rr
                col[m2] *= 0.72
                h[m2] -= 0.15
    # bandes de peinture délavée
    for (y0, y1, pc, strength) in paint_bands:
        band = (yy >= y0 * S) & (yy < y1 * S)
        flake = np.clip((blot + fine * 0.5 - 0.55) * 3.0, 0, 1)
        k = band * flake * strength
        col = col * (1 - k[..., None]) + np.array(pc, np.float32) * (0.7 + 0.3 * fine[..., None]) * k[..., None]
    # sel et soleil : blanchiment par plaques, coulures verticales
    streak = tile_noise(S, S, ox=(64, 128, 256), oy=(2, 4, 8), falloff=0.6)
    bl = np.clip((blot - 0.45) * 2.0, 0, 1) * bleach + np.clip((streak - 0.6) * 2.5, 0, 1) * bleach * 0.6
    col = col * (1 - bl[..., None]) + np.array([0.72, 0.7, 0.66]) * bl[..., None]
    if tar > 0:
        t = np.clip((tile_noise(S, S, ox=(4, 8, 16, 32), falloff=0.6) - 0.5) * 3.0, 0, 1) * tar
        col *= (1.0 - 0.55 * t)[..., None]
    col *= (1.0 - seams * seam_dark)[..., None]
    h += grain * 0.25 + fine * 0.12 - seams * 0.7 - (in_row - 0.5) ** 2 * 0.3
    save_rgb(col, name)
    save_n(h, 7.0, nname)


def salissures():
    S = 1024
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    base_n = tile_noise(S, S, ox=(4, 8, 16, 32, 64), falloff=0.6)
    col = np.dstack([0.24 + 0.1 * base_n, 0.23 + 0.1 * base_n, 0.17 + 0.06 * base_n])
    h = base_n * 0.3
    img = Image.fromarray((col * 255).astype(np.uint8), "RGB")
    hi = Image.fromarray((h * 255).astype(np.uint8), "L")
    d = ImageDraw.Draw(img)
    dh = ImageDraw.Draw(hi)
    # moules (amas d'ovales sombres)
    for k in range(260):
        cx, cy = rng.uniform(0, S), rng.uniform(0, S)
        for j in range(rng.integers(3, 9)):
            x = cx + rng.normal(0, 14)
            y = cy + rng.normal(0, 14)
            a = rng.uniform(5, 11)
            b = a * rng.uniform(1.6, 2.2)
            ang = rng.uniform(0, 180)
            el = Image.new("L", (int(b * 2 + 4), int(b * 2 + 4)), 0)
            ImageDraw.Draw(el).ellipse((b - a + 2, 2, b + a + 2, b * 2 + 2), fill=255)
            el = el.rotate(ang)
            tone = int(rng.uniform(18, 45))
            img.paste((tone, tone + 6, int(tone * 1.4)), (int(x - b), int(y - b)), el)
            hi.paste(170, (int(x - b), int(y - b)), el)
    # balanes (petits cônes blancs avec un trou)
    for k in range(900):
        x, y = rng.uniform(0, S), rng.uniform(0, S)
        r = rng.uniform(3, 8)
        g = int(rng.uniform(175, 225))
        d.ellipse((x - r, y - r, x + r, y + r), fill=(g, g - 6, g - 18))
        d.ellipse((x - r * 0.4, y - r * 0.4, x + r * 0.4, y + r * 0.4), fill=(70, 66, 60))
        dh.ellipse((x - r, y - r, x + r, y + r), fill=230)
        dh.ellipse((x - r * 0.4, y - r * 0.4, x + r * 0.4, y + r * 0.4), fill=120)
    arr = np.asarray(img, np.float32) / 255.0
    harr = np.asarray(hi.filter(ImageFilter.GaussianBlur(1.2)), np.float32) / 255.0
    # algues vertes en filaments qui pendent
    algae = tile_noise(S, S, ox=(32, 64, 128, 256), oy=(4, 8, 16, 32), falloff=0.6)
    am = np.clip((algae - 0.52) * 4.0, 0, 1)
    arr = arr * (1 - am[..., None] * 0.7) + np.array([0.15, 0.24, 0.1]) * am[..., None] * 0.7 * (0.7 + 0.6 * base_n[..., None])
    # coulures de rouille
    rust = tile_noise(S, S, ox=(16, 32, 64), oy=(2, 4, 8), falloff=0.6)
    rm = np.clip((rust - 0.7) * 4.0, 0, 1)
    arr = arr * (1 - rm[..., None] * 0.5) + np.array([0.45, 0.22, 0.1]) * rm[..., None] * 0.5
    save_rgb(arr, "salissures.png")
    save_n(harr + algae * 0.1, 6.0, "salissures_n.png")


def voile():
    W, H = 1024, 1024
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    weave = 0.5 + 0.5 * np.sin(xx * 1.4) * np.sin(yy * 1.4)
    stain = tile_noise(W, H, ox=(3, 6, 12, 24, 48), falloff=0.6)
    col = np.dstack([0.86 + 0.0 * xx, 0.8 + 0.0 * xx, 0.68 + 0.0 * xx])
    col *= (0.92 + 0.06 * weave)[..., None]
    col *= (0.78 + 0.3 * stain)[..., None]
    # coutures des laizes (bandes verticales de toile)
    lz = np.mod(xx, 128)
    col *= (1.0 - 0.18 * np.clip(1.0 - np.abs(lz - 2) / 3.0, 0, 1))[..., None]
    alpha = np.ones((H, W), np.float32)
    img = Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB")
    d = ImageDraw.Draw(img)
    # pièces rapportées
    for k in range(9):
        x0, y0 = rng.uniform(40, W - 200), rng.uniform(40, H - 200)
        w, h = rng.uniform(70, 170), rng.uniform(60, 160)
        tone = tuple(int(v) for v in (np.array([200, 185, 150]) * rng.uniform(0.75, 1.05)))
        d.rectangle((x0, y0, x0 + w, y0 + h), fill=tone, outline=(120, 105, 80), width=3)
    col = np.asarray(img, np.float32) / 255.0
    # déchirures : des trous irréguliers (alpha 0), bords effilochés et plus sombres
    holes = tile_noise(W, H, ox=(4, 8, 16, 32, 64), falloff=0.55)
    edge_y = np.clip(1.0 - yy / H, 0, 1)
    m = (holes + edge_y * 0.12) > 0.88
    tear = Image.fromarray((m * 255).astype(np.uint8), "L")
    for k in range(3):
        x0 = rng.uniform(0, W)
        pts = [(x0, H)]
        for s in range(8):
            pts.append((pts[-1][0] + rng.uniform(-40, 40), pts[-1][1] - rng.uniform(40, 110)))
        ImageDraw.Draw(tear).line(pts, fill=255, width=int(rng.uniform(5, 14)))
    tm = np.asarray(tear.filter(ImageFilter.MaxFilter(3)), np.float32) / 255.0
    alpha = 1.0 - tm
    near = np.asarray(tear.filter(ImageFilter.MaxFilter(9)), np.float32) / 255.0
    col *= (1.0 - 0.35 * near * (1 - tm))[..., None]
    save_rgba(np.dstack([col, alpha]), "voile.png")


def toile(name, c1, c2):
    S = 512
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    stripe = (np.mod(xx, 128) < 64)
    col = np.where(stripe[..., None], np.array(c1, np.float32), np.array(c2, np.float32))
    weave = 0.5 + 0.5 * np.sin(xx * 1.6) * np.sin(yy * 1.6)
    stain = tile_noise(S, S, ox=(3, 6, 12, 24), falloff=0.6)
    col = col * (0.9 + 0.08 * weave)[..., None] * (0.82 + 0.25 * stain)[..., None]
    save_rgb(col, name)


def cabane():
    """Planches de récupération : verticales, de largeurs et de teintes toutes différentes."""
    S = 1024
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    grain = wood_grain(S, S, False)
    col = np.zeros((S, S, 3), np.float32)
    h = np.zeros((S, S), np.float32)
    x = 0
    palette = [(0.5, 0.4, 0.3), (0.42, 0.34, 0.27), (0.6, 0.55, 0.48), (0.35, 0.3, 0.27), (0.55, 0.3, 0.2), (0.3, 0.38, 0.42), (0.62, 0.5, 0.3)]
    while x < S:
        w = int(rng.uniform(40, 110))
        c = np.array(palette[rng.integers(0, len(palette))], np.float32) * rng.uniform(0.8, 1.1)
        m = (xx >= x) & (xx < x + w)
        col[m] = c * (0.75 + 0.45 * grain[m])[:, None]
        e = np.minimum(xx - x, x + w - xx)
        seam = np.clip(1.0 - e / 3.0, 0, 1)
        col[m] *= (1.0 - 0.6 * seam[m])[:, None]
        h[m] = grain[m] * 0.3 - seam[m] * 0.8
        # clous
        for k in range(3):
            cy = rng.uniform(0, S)
            for cx in (x + 8, x + w - 8):
                mm = (xx - cx) ** 2 + (yy - cy) ** 2 < 9
                col[mm] = np.array([0.25, 0.18, 0.12])
        x += w
    blot = tile_noise(S, S, ox=(3, 6, 12, 24), falloff=0.6)
    bl = np.clip((blot - 0.5) * 2.0, 0, 1) * 0.45
    col = col * (1 - bl[..., None]) + np.array([0.7, 0.68, 0.62]) * bl[..., None]
    save_rgb(col, "planches_cabane.png")
    save_n(h, 6.0, "planches_cabane_n.png")


def enseigne(name, title, sub, bg, ink, icon):
    W, H = 512, 256
    bg = tuple(int(v * 255) for v in bg)
    ink = tuple(int(v * 255) for v in ink)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # une planche découpée, bords irréguliers
    pts = [(10, 18), (W - 14, 8), (W - 6, H - 20), (14, H - 10)]
    d.polygon(pts, fill=bg + (255,))
    grain = wood_grain(W, H, True)
    arr = np.asarray(img, np.float32) / 255.0
    arr[..., :3] *= (0.75 + 0.45 * grain)[..., None]
    img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(img)
    try:
        f1 = ImageFont.truetype(str(FONTS / "Lora-BoldItalic.ttf"), 44)
        f2 = ImageFont.truetype(str(FONTS / "Lora-Italic.ttf"), 26)
    except Exception:
        f1 = f2 = ImageFont.load_default()
    tw = d.textlength(title, font=f1)
    d.text(((W - tw) / 2, 44), title, fill=ink + (255,), font=f1)
    sw = d.textlength(sub, font=f2)
    d.text(((W - sw) / 2, 112), sub, fill=ink + (230,), font=f2)
    # petit motif peint
    cx, cy = W // 2, 196
    if icon == "ancre":
        d.ellipse((cx - 10, cy - 30, cx + 10, cy - 10), outline=ink, width=5)
        d.line((cx, cy - 10, cx, cy + 34), fill=ink, width=6)
        d.arc((cx - 28, cy - 4, cx + 28, cy + 40), 0, 180, fill=ink, width=6)
    elif icon == "chope":
        d.rectangle((cx - 18, cy - 20, cx + 14, cy + 26), outline=ink, width=5)
        d.arc((cx + 4, cy - 10, cx + 30, cy + 16), 270, 90, fill=ink, width=5)
    elif icon == "marteau":
        d.line((cx - 20, cy + 30, cx + 14, cy - 10), fill=ink, width=7)
        d.rectangle((cx + 2, cy - 30, cx + 30, cy - 12), fill=ink)
    elif icon == "voile":
        d.polygon([(cx - 22, cy + 30), (cx, cy - 34), (cx + 26, cy + 30)], outline=ink, width=5)
    elif icon == "baril":
        d.ellipse((cx - 20, cy - 30, cx + 20, cy + 30), outline=ink, width=5)
        d.line((cx - 20, cy - 8, cx + 20, cy - 8), fill=ink, width=4)
        d.line((cx - 20, cy + 8, cx + 20, cy + 8), fill=ink, width=4)
    img = img.filter(ImageFilter.GaussianBlur(0.4))
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / name, optimize=True)
    print("carene/" + name)


def textures(oak):
    # V59 : chêne nu, vieilli ; la peinture (bandes noire et ocre) est posée par le shader selon la hauteur
    planks(1024, 22, oak, [], 0.55, 0.38, "bordage.png", "bordage_n.png")
    dark = [(0.26, 0.21, 0.16), (0.3, 0.24, 0.18), (0.22, 0.18, 0.14), (0.34, 0.27, 0.2)]
    planks(1024, 16, dark, [], 0.65, 0.12, "bordage_int.png", "bordage_int_n.png", tar=0.6)
    deck = [(0.56, 0.52, 0.46), (0.6, 0.56, 0.5), (0.5, 0.46, 0.41), (0.64, 0.6, 0.53), (0.54, 0.49, 0.42)]
    planks(1024, 12, deck, [], 0.8, 0.35, "pont.png", "pont_n.png", butt_len=(0.45, 0.95))
    salissures()
    voile()
    toile("toile_rouge.png", (0.62, 0.16, 0.12), (0.86, 0.8, 0.66))
    toile("toile_bleue.png", (0.16, 0.3, 0.52), (0.86, 0.82, 0.7))
    cabane()


def signs():
    enseigne("enseigne_bordee.png", "La Dernière Bordée", "taverne — on y mange, on y chante", (0.18, 0.12, 0.08), (0.95, 0.8, 0.45), "chope")
    enseigne("enseigne_cale.png", "Le Marché de la Cale", "tout ce que la mer rapporte", (0.12, 0.2, 0.26), (0.92, 0.88, 0.72), "baril")
    enseigne("enseigne_forge.png", "La Forge du Canon", "fer, clous, lames", (0.16, 0.14, 0.13), (0.95, 0.6, 0.3), "marteau")
    enseigne("enseigne_voilerie.png", "Voilerie Nolwenn", "voiles, cordages, filets", (0.85, 0.8, 0.68), (0.22, 0.3, 0.45), "voile")
    enseigne("enseigne_capitainerie_carene.png", "Capitainerie", "Carène — port de l'épave", (0.2, 0.25, 0.4), (0.95, 0.9, 0.75), "ancre")


# =================================================================== icônes d'objets (items/)

def icones():
    import sys as _sys
    _sys.path.insert(0, str(Path(__file__).resolve().parent))
    import generate_items_v28 as icons
    S = icons.S
    # galette de sarrasin, pliée en carré, un œuf au milieu
    img = icons.canvas()
    gal = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(gal)
    d.polygon([(256, 50), (462, 256), (256, 462), (50, 256)], fill=(150, 92, 44, 255))
    arr = np.array(gal).astype(np.float32)
    n = rng.random((S // 8, S // 8)).astype(np.float32)
    n = np.asarray(Image.fromarray((n * 255).astype(np.uint8)).resize((S, S), Image.BICUBIC), dtype=np.float32) / 255.0
    lace = (rng.random((S, S)) > 0.985).astype(np.float32)
    lace = np.asarray(Image.fromarray((lace * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(3)), dtype=np.float32) / 255.0
    k = (0.75 + 0.45 * n - lace * 0.9)[..., None]
    arr[..., :3] = np.clip(arr[..., :3] * k, 0, 255)
    gal = Image.fromarray(arr.astype(np.uint8), "RGBA")
    img.alpha_composite(gal)
    d = ImageDraw.Draw(img)
    for (a, b) in [((256, 50), (150, 256)), ((462, 256), (256, 150))]:
        pass
    d.polygon([(256, 120), (392, 256), (256, 392), (120, 256)], outline=(110, 62, 28, 255), width=8)
    egg = icons.canvas()
    ImageDraw.Draw(egg).ellipse((170, 180, 342, 332), fill=(250, 246, 236, 255))
    img.alpha_composite(egg)
    yolk = icons.canvas()
    icons.shaded_ellipse(yolk, (222, 218, 290, 286), (245, 170, 30))
    img.alpha_composite(yolk)
    icons.save(img, "galette_sarrasin")
    # grog de la Bordée : une chope fumante, rhum ambré, citron
    img = icons.canvas()
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((120, 150, 360, 450), 26, fill=(190, 110, 40, 255))
    d.rectangle((120, 150, 360, 196), fill=(230, 160, 70, 255))
    for x in (150, 210, 270, 330):
        d.line([(x, 200), (x, 440)], fill=(160, 88, 30, 255), width=6)
    d.rounded_rectangle((116, 140, 364, 168), 10, fill=(90, 70, 55, 255))
    d.rounded_rectangle((116, 420, 364, 452), 10, fill=(90, 70, 55, 255))
    d.arc((300, 200, 450, 380), -80, 80, fill=(90, 70, 55, 255), width=28)
    lemon = icons.canvas()
    icons.shaded_ellipse(lemon, (90, 110, 190, 210), (250, 220, 60))
    img.alpha_composite(lemon)
    for k2, x in enumerate((180, 240, 300)):
        pts = [(x + 14 * math.sin(t / 8 + k2), 120 - t * 2.2) for t in range(0, 40)]
        steam = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        ImageDraw.Draw(steam).line(pts, fill=(255, 255, 255, 150), width=12)
        img.alpha_composite(steam.filter(ImageFilter.GaussianBlur(4)))
    icons.save(img, "grog_bordee")
    # cidre de Carène : une bouteille verte, bouchon de liège, étiquette
    img = icons.canvas()
    bottle = icons.canvas()
    bd = ImageDraw.Draw(bottle)
    bd.rounded_rectangle((176, 190, 336, 470), 40, fill=(60, 120, 50, 255))
    bd.polygon([(196, 200), (226, 120), (286, 120), (316, 200)], fill=(60, 120, 50, 255))
    bd.rectangle((226, 70, 286, 130), fill=(60, 120, 50, 255))
    img.alpha_composite(bottle)
    shine = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(shine).rounded_rectangle((196, 220, 222, 440), 12, fill=(200, 255, 190, 110))
    img.alpha_composite(shine.filter(ImageFilter.GaussianBlur(3)))
    d = ImageDraw.Draw(img)
    d.rectangle((232, 40, 280, 82), fill=(200, 160, 110, 255))
    d.rounded_rectangle((186, 290, 326, 400), 10, fill=(240, 228, 196, 255))
    apple = icons.canvas()
    icons.shaded_ellipse(apple, (226, 310, 286, 370), (200, 50, 40))
    img.alpha_composite(apple)
    d.line([(256, 312), (262, 296)], fill=(90, 60, 30, 255), width=5)
    icons.save(img, "cidre_carene")


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "icones":
        icones()
        raise SystemExit
    only_signs = len(sys.argv) > 1 and sys.argv[1] == "enseignes"
    oak = [(0.46, 0.38, 0.29), (0.52, 0.42, 0.31), (0.4, 0.34, 0.27), (0.56, 0.48, 0.38), (0.44, 0.38, 0.32)]
    if len(sys.argv) > 1 and sys.argv[1] == "bordage":
        planks(1024, 22, oak, [], 0.55, 0.38, "bordage.png", "bordage_n.png")
        raise SystemExit
    if not only_signs:
        textures(oak)
        icones()
    signs()
