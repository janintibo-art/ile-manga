"""V92 : les icônes des objets de l'Île de Larsen (dessinées ici, versées au domaine public, CC0 1.0).

  items/bouquet_tournesols.png   trois tournesols noués d'un ruban jaune
  items/parapluie_rainville.png  le parapluie noir de Mère Averse, des tournesols peints dessous
  items/corde_chanvre.png        un rouleau de corde de chanvre
  items/chocolat_chaud.png       une grande tasse fumante, un nuage de crème
  items/attrape_reves.png        un cercle tressé, son filet, des perles et des plumes
Dessinées en 512 × 512 puis réduites en 128 × 128 (bords doux).
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/icones_v92.py
"""
from pathlib import Path
import math

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "items"
S = 512


def toile():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def ombre(img, dx=10, dy=14, flou=10, a=110):
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    alpha = img.split()[3].point(lambda v: v * a // 255)
    sh.putalpha(alpha)
    sh = sh.filter(ImageFilter.GaussianBlur(flou))
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.alpha_composite(sh, (dx, dy))
    out.alpha_composite(img)
    return out


def finir(img, nom):
    img = ombre(img)
    img = img.resize((128, 128), Image.LANCZOS)
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / f"{nom}.png")


def fleur(d, cx, cy, r, petales=(250, 196, 30), coeur=(90, 52, 20)):
    for k in range(18):
        a = 2 * math.pi * k / 18
        px, py = cx + math.cos(a) * r * 0.78, cy + math.sin(a) * r * 0.78
        q = r * 0.34
        d.ellipse([px - q, py - q * 0.6, px + q, py + q * 0.6], fill=petales + (255,))
        d.ellipse([px - q * 0.6, py - q, px + q * 0.6, py + q], fill=tuple(int(c * 0.92) for c in petales) + (255,))
    d.ellipse([cx - r * 0.5, cy - r * 0.5, cx + r * 0.5, cy + r * 0.5], fill=coeur + (255,))
    for k in range(40):
        a = k * 2.4
        rr = r * 0.45 * math.sqrt(k / 40)
        x, y = cx + math.cos(a) * rr, cy + math.sin(a) * rr
        d.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(60, 34, 12, 255))


def bouquet():
    img = toile()
    d = ImageDraw.Draw(img)
    for (x0, x1) in [(256, 170), (256, 256), (256, 340)]:
        d.line([(256, 470), (x1, 150)], fill=(56, 112, 40, 255), width=14)
    for (cx, cy, s) in [(240, 330, 1), (290, 300, -1)]:
        d.polygon([(256, cy), (256 + s * 90, cy - 40), (256 + s * 60, cy + 20)], fill=(70, 135, 50, 255))
    d.rectangle([228, 395, 284, 425], fill=(250, 220, 70, 255))
    d.polygon([(256, 410), (200, 470), (230, 470)], fill=(250, 220, 70, 255))
    d.polygon([(256, 410), (312, 470), (282, 470)], fill=(250, 220, 70, 255))
    fleur(d, 170, 150, 78)
    fleur(d, 340, 150, 78)
    fleur(d, 256, 110, 88)
    finir(img, "bouquet_tournesols")


def parapluie():
    img = toile()
    d = ImageDraw.Draw(img)
    # la toile, en demi-cercle festonné, vue d'un peu en dessous (les tournesols peints)
    d.pieslice([56, 70, 456, 470], 180, 360, fill=(22, 22, 26, 255))
    for k in range(4):
        x = 56 + 100 * k
        d.chord([x, 225, x + 100, 315], 0, 180, fill=(22, 22, 26, 255))
    d.pieslice([96, 120, 416, 400], 180, 360, fill=(40, 40, 46, 255))
    for k in range(5):
        a = math.pi + math.pi * (k + 0.5) / 5
        cx, cy = 256 + math.cos(a) * 110, 262 + math.sin(a) * 100
        fleur(d, cx, cy, 28)
    for k in range(9):
        a = math.pi + math.pi * k / 8
        d.line([(256, 270), (256 + math.cos(a) * 200, 270 + math.sin(a) * 200)], fill=(70, 70, 76, 255), width=4)
    d.line([(256, 60), (256, 440)], fill=(90, 55, 30, 255), width=14)
    d.arc([206, 400, 266, 470], 0, 180, fill=(90, 55, 30, 255), width=14)
    d.ellipse([244, 44, 268, 68], fill=(200, 200, 205, 255))
    finir(img, "parapluie_rainville")


def corde():
    img = toile()
    d = ImageDraw.Draw(img)
    for k in range(7):
        r = 190 - k * 22
        col = (170 - k * 4, 132 - k * 3, 80 - k * 2, 255)
        d.ellipse([256 - r, 256 - r * 0.62, 256 + r, 256 + r * 0.62], outline=col, width=20)
        for t in range(0, 360, 12):
            a = math.radians(t + k * 7)
            x, y = 256 + math.cos(a) * r, 256 + math.sin(a) * r * 0.62
            d.line([(x - 6, y - 8), (x + 6, y + 8)], fill=(120, 92, 54, 255), width=4)
    d.line([(420, 270), (470, 400)], fill=(165, 128, 78, 255), width=20)
    finir(img, "corde_chanvre")


def chocolat():
    img = toile()
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([130, 200, 360, 440], radius=40, fill=(176, 58, 46, 255))
    d.ellipse([130, 170, 360, 240], fill=(150, 46, 38, 255))
    d.ellipse([145, 180, 345, 230], fill=(90, 50, 30, 255))
    d.arc([330, 250, 440, 380], -80, 80, fill=(176, 58, 46, 255), width=26)
    for (x, y, r) in [(220, 190, 45), (275, 180, 50), (245, 160, 40)]:
        d.ellipse([x - r, y - r * 0.7, x + r, y + r * 0.7], fill=(250, 248, 240, 255))
    for k, x in enumerate([200, 256, 310]):
        pts = [(x + 12 * math.sin(t / 8 + k), 120 - t * 2) for t in range(0, 45)]
        d.line(pts, fill=(255, 255, 255, 140), width=8)
    finir(img, "chocolat_chaud")


def attrape_reves():
    img = toile()
    d = ImageDraw.Draw(img)
    cx, cy, r = 256, 200, 150
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(150, 100, 55, 255), width=22)
    pts = [(cx + math.cos(2 * math.pi * k / 9) * (r - 12), cy + math.sin(2 * math.pi * k / 9) * (r - 12)) for k in range(9)]
    for i in range(9):
        d.line([pts[i], pts[(i + 4) % 9]], fill=(240, 236, 220, 255), width=4)
    d.ellipse([cx - 18, cy - 18, cx + 18, cy + 18], outline=(240, 236, 220, 255), width=5)
    for k, (dx, col) in enumerate([(-80, (220, 70, 90)), (0, (70, 140, 220)), (80, (240, 200, 60))]):
        x = cx + dx
        top = cy + r * 0.92 - abs(dx) * 0.35
        d.line([(x, top), (x, top + 120)], fill=(150, 110, 70, 255), width=5)
        d.ellipse([x - 14, top + 40, x + 14, top + 68], fill=col + (255,))
        d.polygon([(x, top + 80), (x - 26, top + 150), (x, top + 210), (x + 26, top + 150)], fill=(245, 242, 235, 255))
        d.line([(x, top + 80), (x, top + 210)], fill=(180, 170, 160, 255), width=4)
    finir(img, "attrape_reves")


if __name__ == "__main__":
    bouquet()
    parapluie()
    corde()
    chocolat()
    attrape_reves()
    print("V92 : 5 icônes")
