"""V119 : les affiches du Dôme d'Azur (dans les maisons-bulles et les grands lieux) : la Grande Chanteuse
(la baleine), le Petit Plongeon (le bathyscaphe jaune), la Grande Perle sur la Cheminée d'Air. Des formes
simples, des aplats, sans texte. Écrit www/assets/textures/dome119/affiche_*.png."""
import math, os, random
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "www", "assets", "textures", "dome119")
W, H = 384, 512


def fond(dr, haut, bas):
    for y in range(H):
        t = y / (H - 1)
        c = tuple(int(haut[i] + (bas[i] - haut[i]) * t) for i in range(3))
        dr.line([(0, y), (W, y)], fill=c)


def neige(dr, rnd, n=90):
    for _ in range(n):
        x, y = rnd.randint(0, W), rnd.randint(0, H)
        r = rnd.choice([1, 1, 2])
        dr.ellipse([x - r, y - r, x + r, y + r], fill=(200, 230, 240))


def grain(im, rnd):
    px = im.load()
    for y in range(H):
        for x in range(W):
            g = rnd.randint(-6, 6)
            r0, g0, b0 = px[x, y]
            px[x, y] = (max(0, min(255, r0 + g)), max(0, min(255, g0 + g)), max(0, min(255, b0 + g)))
    return im.filter(ImageFilter.GaussianBlur(0.6))


def chanteuse():
    rnd = random.Random(1191)
    im = Image.new("RGB", (W, H))
    dr = ImageDraw.Draw(im)
    fond(dr, (40, 110, 150), (6, 22, 44))
    neige(dr, rnd)
    # la baleine : un grand corps allongé, la nageoire, la queue
    cx, cy = 190, 230
    dr.ellipse([cx - 150, cy - 50, cx + 120, cy + 55], fill=(30, 52, 78))
    dr.polygon([(cx + 100, cy - 10), (cx + 180, cy - 60), (cx + 170, cy - 5), (cx + 185, cy + 40), (cx + 100, cy + 20)], fill=(30, 52, 78))
    dr.polygon([(cx - 40, cy + 40), (cx - 10, cy + 110), (cx + 10, cy + 45)], fill=(26, 46, 70))
    dr.ellipse([cx - 150, cy - 10, cx + 90, cy + 55], fill=(70, 100, 125))
    for k in range(6):
        x = cx - 120 + k * 32
        dr.line([(x, cy + 18), (x + 18, cy + 50)], fill=(46, 72, 98), width=4)
    dr.ellipse([cx - 112, cy - 18, cx - 102, cy - 8], fill=(220, 235, 240))
    # le chant : des arcs qui montent
    for k in range(4):
        r = 40 + k * 26
        dr.arc([cx - 220 - r, cy - 120 - r, cx - 220 + r, cy - 120 + r], 300, 30, fill=(150, 220, 230), width=5)
    # la bande du bas
    dr.rectangle([0, H - 80, W, H], fill=(230, 214, 170))
    for k in range(3):
        dr.rectangle([40, H - 64 + k * 18, 40 + rnd.randint(140, 300), H - 56 + k * 18], fill=(40, 70, 90))
    return grain(im, rnd)


def plongeon():
    rnd = random.Random(1192)
    im = Image.new("RGB", (W, H))
    dr = ImageDraw.Draw(im)
    fond(dr, (24, 90, 130), (4, 14, 30))
    neige(dr, rnd, 60)
    # le bathyscaphe jaune : une sphère, le flotteur au-dessus, le hublot, le phare
    cx, cy = 192, 270
    dr.rounded_rectangle([cx - 120, cy - 120, cx + 120, cy - 60], 28, fill=(240, 196, 40))
    dr.ellipse([cx - 80, cy - 80, cx + 80, cy + 80], fill=(250, 210, 50))
    dr.ellipse([cx - 40, cy - 30, cx + 40, cy + 50], fill=(230, 236, 240))
    dr.ellipse([cx - 32, cy - 22, cx + 32, cy + 42], fill=(40, 120, 160))
    dr.ellipse([cx - 14, cy - 8, cx, cy + 6], fill=(200, 240, 250))
    # le faisceau du phare, vers le bas
    dr.polygon([(cx + 60, cy + 50), (cx + 170, H - 90), (cx + 20, H - 90)], fill=(90, 160, 170))
    dr.ellipse([cx + 48, cy + 38, cx + 72, cy + 62], fill=(255, 250, 200))
    # des bulles
    for k in range(9):
        r = rnd.randint(5, 14)
        x, y = cx - 100 + rnd.randint(-20, 30), cy - 140 - k * 22
        dr.ellipse([x - r, y - r, x + r, y + r], outline=(200, 240, 250), width=3)
    dr.rectangle([0, H - 80, W, H], fill=(250, 210, 50))
    for k in range(3):
        dr.rectangle([40, H - 64 + k * 18, 40 + rnd.randint(140, 300), H - 56 + k * 18], fill=(30, 50, 70))
    return grain(im, rnd)


def perle():
    rnd = random.Random(1193)
    im = Image.new("RGB", (W, H))
    dr = ImageDraw.Draw(im)
    fond(dr, (90, 60, 150), (16, 20, 60))
    # la Cheminée d'Air (une colonne blanche) et la Grande Perle enfilée dessus, qui rayonne
    cx = 192
    dr.rectangle([cx - 18, 0, cx + 18, H], fill=(236, 236, 244))
    for k in range(5, 0, -1):
        r = 70 + k * 18
        c = (int(120 + 20 * k), int(100 + 20 * k), int(190 + 10 * k))
        dr.ellipse([cx - r, 210 - r, cx + r, 210 + r], fill=c)
    dr.ellipse([cx - 70, 140, cx + 70, 280], fill=(250, 244, 230))
    dr.ellipse([cx - 40, 165, cx - 5, 200], fill=(255, 255, 255))
    # les dômes, en bas : trois coupoles
    for (x0, r) in [(70, 70), (192, 110), (320, 70)]:
        dr.pieslice([x0 - r, H - 110 - r, x0 + r, H - 110 + r], 180, 360, fill=(180, 220, 235))
        dr.arc([x0 - r, H - 110 - r, x0 + r, H - 110 + r], 180, 360, fill=(240, 250, 255), width=4)
    dr.rectangle([0, H - 110, W, H], fill=(240, 232, 214))
    for k in range(3):
        dr.rectangle([40, H - 90 + k * 20, 40 + rnd.randint(140, 300), H - 82 + k * 20], fill=(60, 50, 110))
    return grain(im, rnd)


def main():
    os.makedirs(OUT, exist_ok=True)
    chanteuse().save(os.path.join(OUT, "affiche_chanteuse.png"))
    plongeon().save(os.path.join(OUT, "affiche_plongeon.png"))
    perle().save(os.path.join(OUT, "affiche_perle.png"))
    print("écrit affiche_chanteuse, affiche_plongeon, affiche_perle")


if __name__ == "__main__":
    main()
