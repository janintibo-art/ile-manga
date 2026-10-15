"""V47 : textures des nains et icônes des objets de l'île des nains (dessinées ici, libres de droits).

- nain_*.png : la texture du personnage recolorée en nain (peau rougeaude, laine et cuir,
  clous devenus fer ou bronze), à partir de la texture du modèle.
- icônes : minerai de fer, obsidienne, champignon de braise, plume de corbeau, cœur de magma,
  rune de golem, épée naine, ragoût, fromage de chèvre, chope de bière.
Lancement : python3 pcvr/tools/generate_nains_v47.py (depuis la racine du dépôt).
"""
from pathlib import Path
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_items_v28 as base  # noqa: E402
import generate_elfes_v41 as v41  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "nains"
OUT.mkdir(parents=True, exist_ok=True)


def dwarf_texture(name, skin, cloth, metal):
    img = v41.model_texture().resize((1024, 1024), Image.LANCZOS)
    a = np.asarray(img).astype(np.float32) / 255.0
    rgb = a[..., :3]
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    mx = rgb.max(axis=2)
    mn = rgb.min(axis=2)
    sat = (mx - mn) / np.maximum(mx, 1e-4)
    out = rgb.copy()
    yellow = (r > 0.55) & (g > 0.4) & (b < 0.45) & (r - b > 0.3)
    shade = np.clip(lum / 0.72, 0.35, 1.15)[..., None]
    out[yellow] = (np.array(skin)[None, None, :] * shade)[yellow]
    dark = (mx < 0.36) & ~yellow
    # Laine grossière : un léger grain sur l'étoffe
    rng = np.random.default_rng(len(name))
    grain = (rng.random(lum.shape) * 0.12 + 0.94)[..., None]
    cl = np.array(cloth)[None, None, :] * (0.45 + lum[..., None] * 2.4) * grain
    out[dark] = np.clip(cl, 0, 1)[dark]
    light = (lum > 0.55) & (sat < 0.25) & ~yellow
    out[light] = (np.array(metal)[None, None, :] * np.clip(lum, 0.6, 1.0)[..., None])[light]
    res = np.concatenate([np.clip(out, 0, 1), a[..., 3:4]], axis=2)
    Image.fromarray((res * 255).astype(np.uint8), "RGBA").save(OUT / f"{name}.png", optimize=True)
    print(name)


def glow(img, color, radius=16, k=2):
    g = img.split()[3].filter(ImageFilter.GaussianBlur(radius))
    halo = Image.new("RGBA", img.size, color + (0,))
    halo.putalpha(g.point(lambda v: v // k))
    halo.alpha_composite(img)
    return halo


def rock_poly(d, cx, cy, rx, ry, n, seed, fill):
    rng = np.random.default_rng(seed)
    pts = []
    for k in range(n):
        a = k / n * math.tau
        rr = 0.75 + rng.random() * 0.3
        pts.append((cx + math.cos(a) * rx * rr, cy + math.sin(a) * ry * rr))
    d.polygon(pts, fill=fill)
    return pts


def minerai_fer():
    img = base.canvas()
    d = ImageDraw.Draw(img)
    rock_poly(d, 256, 280, 175, 140, 11, 1, (95, 88, 84, 255))
    rock_poly(d, 236, 250, 120, 90, 9, 2, (120, 112, 106, 255))
    rng = np.random.default_rng(5)
    for k in range(9):
        x, y = 150 + rng.random() * 210, 190 + rng.random() * 160
        d.polygon([(x, y - 18), (x + 16, y), (x, y + 16), (x - 14, y)], fill=(178, 92, 52, 255))
        d.polygon([(x, y - 18), (x + 16, y), (x + 2, y - 2)], fill=(222, 140, 90, 255))
    base.save(img, "minerai_fer")


def obsidienne():
    img = base.canvas()
    d = ImageDraw.Draw(img)
    d.polygon([(256, 60), (360, 210), (320, 430), (190, 440), (140, 230)], fill=(22, 20, 30, 255))
    d.polygon([(256, 60), (360, 210), (270, 240)], fill=(70, 66, 92, 255))
    d.polygon([(140, 230), (256, 60), (230, 250)], fill=(40, 38, 56, 255))
    d.line((250, 90, 300, 300), fill=(140, 130, 180, 255), width=5)
    base.save(img, "obsidienne")


def champignon_braise():
    img = base.canvas()
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((220, 250, 292, 440), radius=24, fill=(70, 50, 45, 255))
    lay = base.canvas()
    base.shaded_ellipse(lay, (110, 120, 402, 300), (230, 80, 30))
    img.alpha_composite(lay)
    d = ImageDraw.Draw(img)
    for x, y in [(180, 180), (260, 160), (330, 190), (220, 230), (300, 240)]:
        d.ellipse((x - 14, y - 10, x + 14, y + 10), fill=(255, 210, 90, 255))
    base.save(glow(img, (255, 120, 40)), "champignon_braise")


def plume_corbeau():
    img = base.canvas()
    d = ImageDraw.Draw(img)
    d.line((140, 440, 380, 70), fill=(60, 60, 70, 255), width=8)
    for k in range(22):
        t = k / 21
        x = 150 + t * 220
        y = 425 - t * 340
        ln = 70 * math.sin(t * math.pi) + 10
        d.line((x, y, x - ln * 0.75, y - ln * 0.2), fill=(25, 25, 34, 255), width=10)
        d.line((x, y, x + ln * 0.2, y + ln * 0.7), fill=(35, 36, 48, 255), width=10)
    d.line((200, 330, 330, 130), fill=(80, 90, 130, 255), width=3)
    base.save(img, "plume_corbeau")


def coeur_magma():
    img = base.canvas()
    d = ImageDraw.Draw(img)
    rock_poly(d, 256, 260, 160, 160, 12, 7, (50, 30, 26, 255))
    for k in range(8):
        a = k / 8 * math.tau + 0.3
        d.line((256, 260, 256 + math.cos(a) * 140, 260 + math.sin(a) * 140), fill=(255, 120, 30, 255), width=12)
    lay = base.canvas()
    base.shaded_ellipse(lay, (190, 194, 322, 326), (255, 170, 40))
    img.alpha_composite(lay)
    base.save(glow(img, (255, 110, 20), 22, 1), "coeur_magma")


def rune_golem():
    img = base.canvas()
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((120, 90, 392, 430), radius=40, fill=(120, 116, 108, 255))
    d.rounded_rectangle((140, 110, 372, 410), radius=30, fill=(146, 140, 130, 255))
    c = (90, 200, 255, 255)
    d.line((256, 150, 256, 370), fill=c, width=14)
    d.line((256, 200, 190, 260), fill=c, width=14)
    d.line((256, 200, 322, 260), fill=c, width=14)
    d.line((200, 330, 312, 330), fill=c, width=14)
    base.save(glow(img, (90, 200, 255), 14, 2), "rune_golem")


def epee_naine():
    img = base.canvas()
    d = ImageDraw.Draw(img)
    d.polygon([(380, 70), (420, 92), (220, 330), (196, 306)], fill=(200, 205, 215, 255))
    d.polygon([(380, 70), (420, 92), (310, 210)], fill=(240, 244, 250, 255))
    d.line((196, 330, 300, 226), fill=(230, 180, 70, 255), width=26)
    d.line((205, 296, 110, 400), fill=(110, 70, 40, 255), width=26)
    d.ellipse((84, 386, 130, 432), fill=(230, 180, 70, 255))
    d.ellipse((240, 266, 262, 288), fill=(220, 40, 40, 255))
    base.save(img, "epee_naine")


def ragout_nain():
    img = base.canvas()
    d = ImageDraw.Draw(img)
    d.ellipse((90, 220, 422, 440), fill=(90, 60, 40, 255))
    d.ellipse((100, 210, 412, 330), fill=(150, 80, 40, 255))
    for x, y, c in [(180, 260, (210, 150, 70)), (260, 240, (120, 60, 40)), (320, 270, (230, 170, 80)), (230, 290, (90, 140, 60))]:
        d.ellipse((x - 26, y - 18, x + 26, y + 18), fill=c + (255,))
    for k in range(3):
        x = 190 + k * 70
        d.arc((x - 20, 100, x + 20, 200), 100, 260, fill=(240, 240, 240, 200), width=8)
    base.save(img, "ragout_nain")


def fromage_chevre():
    img = base.canvas()
    d = ImageDraw.Draw(img)
    d.ellipse((100, 260, 412, 420), fill=(220, 210, 180, 255))
    d.rectangle((100, 220, 412, 340), fill=(240, 232, 205, 255))
    d.ellipse((100, 150, 412, 290), fill=(250, 245, 225, 255))
    d.polygon([(256, 220), (412, 220), (412, 300)], fill=(235, 220, 170, 255))
    for x, y in [(200, 200), (300, 190), (250, 240)]:
        d.ellipse((x - 10, y - 6, x + 10, y + 6), fill=(225, 215, 185, 255))
    base.save(img, "fromage_chevre")


def biere_naine():
    img = base.canvas()
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((130, 150, 340, 440), radius=20, fill=(120, 80, 45, 255))
    for y in (190, 300, 400):
        d.rectangle((126, y, 344, y + 16), fill=(90, 90, 96, 255))
    d.arc((300, 200, 420, 360), 270, 90, fill=(120, 80, 45, 255), width=26)
    d.ellipse((120, 90, 350, 190), fill=(250, 245, 230, 255))
    d.ellipse((160, 70, 260, 140), fill=(255, 252, 240, 255))
    base.save(img, "biere_naine")


if __name__ == "__main__":
    dwarf_texture("nain_braise", (0.98, 0.72, 0.58), (0.42, 0.2, 0.12), (0.62, 0.62, 0.66))
    dwarf_texture("nain_suie", (0.92, 0.7, 0.58), (0.22, 0.22, 0.26), (0.85, 0.66, 0.35))
    dwarf_texture("nain_mousse", (1.0, 0.76, 0.62), (0.22, 0.32, 0.18), (0.6, 0.6, 0.62))
    dwarf_texture("nain_royal", (0.98, 0.74, 0.6), (0.38, 0.1, 0.12), (0.95, 0.78, 0.35))
    minerai_fer()
    obsidienne()
    champignon_braise()
    plume_corbeau()
    coeur_magma()
    rune_golem()
    epee_naine()
    ragout_nain()
    fromage_chevre()
    biere_naine()
