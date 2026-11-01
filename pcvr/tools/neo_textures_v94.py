"""V94 : les images de Néopolis (dessinées ici, versées au domaine public, CC0 1.0).

  textures/neo/ecrans_larges.png   4 réclames de 1024 x 512, côte à côte (les grands écrans des façades) :
                                   Néo-Ramen, Synthé-Soda, le Monorail, Robo-Chat
  textures/neo/ecrans_hauts.png    4 réclames de 512 x 1024, côte à côte (les écrans en hauteur) :
                                   la Tour Axiome, l'Arcade du Dragon-Pixel, les Lunettes Holo, « la ville
                                   qui ne dort jamais »
  textures/neo/neon_<nom>.png      les enseignes au néon (lumière sur fond transparent) : à plat
                                   (1024 x 256) ou en colonne (256 x 1024)
Toutes les marques sont inventées. Les lettres japonaises (katakana) sont dessinées avec la police
Noto Sans CJK (SIL OFL) ; seule l'image est livrée, pas la police.
Lancement (depuis la racine du dépôt) :
    python3 -B pcvr/tools/neo_textures_v94.py
"""
from pathlib import Path
import math

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "neo"
CJK = "/usr/share/fonts/opentype/noto/NotoSansCJK-Black.ttc"
LATIN = ROOT / "www" / "assets" / "fonts" / "DejaVuSans.ttf"
RNG = np.random.default_rng(9494)

CYAN = (40, 230, 255)
ROSE = (255, 60, 200)
AMBRE = (255, 170, 40)
VERT = (60, 255, 140)
ROUGE = (255, 50, 60)
VIOLET = (170, 90, 255)
BLANC = (240, 240, 255)


def police(taille: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(CJK, taille)
    except OSError:
        return ImageFont.truetype(str(LATIN), taille)


def lueur(base: Image.Image, couleur, rayons=(26, 12, 5)) -> Image.Image:
    """Un tracé blanc (L) devient un néon : des halos de couleur, et un cœur presque blanc."""
    w, h = base.size
    out = np.zeros((h, w, 4), np.float32)
    m = np.asarray(base, np.float32) / 255.0
    col = np.array(couleur, np.float32) / 255.0
    for r, a in zip(rayons, (0.55, 0.8, 1.0)):
        g = np.asarray(base.filter(ImageFilter.GaussianBlur(r)), np.float32) / 255.0
        g = np.clip(g * 2.2, 0, 1) * a
        out[..., :3] += col * g[..., None]
        out[..., 3] = np.maximum(out[..., 3], g)
    coeur = np.clip(m * 1.0, 0, 1)
    out[..., :3] = out[..., :3] * (1 - coeur[..., None]) + (col * 0.35 + 0.65) * coeur[..., None]
    out[..., 3] = np.maximum(out[..., 3], coeur)
    out = np.clip(out, 0, 1)
    return Image.fromarray((out * 255).astype(np.uint8), "RGBA")


def tube(w, h, dessin) -> Image.Image:
    img = Image.new("L", (w, h), 0)
    dessin(ImageDraw.Draw(img))
    return img


def texte_centre(d, w, h, txt, taille, epais=0, dy=0):
    f = police(taille)
    bb = d.textbbox((0, 0), txt, font=f)
    x = (w - (bb[2] - bb[0])) / 2 - bb[0]
    y = (h - (bb[3] - bb[1])) / 2 - bb[1] + dy
    d.text((x, y), txt, font=f, fill=255, stroke_width=epais, stroke_fill=255)


def neon_plat(nom, txt, couleur, cadre=True, taille=150):
    w, h = 1024, 256

    def des(d):
        # on écrit le contour des lettres (les tubes suivent le bord), puis on creuse l'intérieur
        texte_centre(d, w, h, txt, taille, epais=4)
        if cadre:
            d.rounded_rectangle((18, 18, w - 18, h - 18), radius=40, outline=255, width=7)

    t = tube(w, h, des)
    creux = tube(w, h, lambda d: texte_centre(d, w, h, txt, taille, epais=0))
    creux = creux.filter(ImageFilter.MinFilter(9))
    t = Image.fromarray(np.clip(np.asarray(t, np.int16) - np.asarray(creux, np.int16), 0, 255).astype(np.uint8))
    lueur(t, couleur).save(OUT / f"neon_{nom}.png")


def neon_colonne(nom, lettres, couleur):
    w, h = 256, 1024
    n = len(lettres)
    pas = (h - 60) / n

    def des(d):
        for i, c in enumerate(lettres):
            f = police(int(min(pas * 0.82, 190)))
            bb = d.textbbox((0, 0), c, font=f)
            x = (w - (bb[2] - bb[0])) / 2 - bb[0]
            y = 30 + i * pas + (pas - (bb[3] - bb[1])) / 2 - bb[1]
            d.text((x, y), c, font=f, fill=255, stroke_width=3, stroke_fill=255)
        d.rounded_rectangle((12, 12, w - 12, h - 12), radius=30, outline=255, width=6)

    lueur(tube(w, h, des), couleur, rayons=(20, 9, 4)).save(OUT / f"neon_{nom}.png")


# =================================================================== les réclames

def fond(w, h, haut, bas):
    y = np.linspace(0, 1, h)[:, None, None]
    a = np.array(haut, np.float32)[None, None, :]
    b = np.array(bas, np.float32)[None, None, :]
    g = a * (1 - y) + b * y
    return Image.fromarray(np.broadcast_to(g, (h, w, 3)).astype(np.uint8)).convert("RGBA")


def ecrire(d, xy, txt, taille, couleur, ancre="la"):
    d.text(xy, txt, font=police(taille), fill=couleur, anchor=ancre)


def pub_ramen():
    im = fond(1024, 512, (60, 8, 30), (180, 30, 40))
    d = ImageDraw.Draw(im)
    # le bol fumant
    d.ellipse((560, 230, 960, 470), fill=(30, 30, 40))
    d.pieslice((560, 150, 960, 470), 0, 180, fill=(240, 240, 235))
    d.ellipse((580, 270, 940, 330), fill=(230, 170, 70))
    for k in range(9):
        x = 610 + k * 36
        d.arc((x, 250, x + 60, 340), 200, 340, fill=(255, 230, 150), width=8)
    d.ellipse((700, 262, 770, 300), fill=(255, 250, 240))
    d.ellipse((722, 272, 748, 292), fill=(250, 190, 40))
    for k in range(3):
        x = 660 + k * 90
        d.line([(x, 220), (x + 20, 170), (x - 10, 120), (x + 10, 70)], fill=(255, 255, 255, 160), width=10, joint="curve")
    d.line([(800, 120), (980, 300)], fill=(150, 90, 40), width=12)
    d.line([(830, 110), (1000, 290)], fill=(150, 90, 40), width=12)
    ecrire(d, (60, 60), "NÉO-RAMEN", 84, (255, 240, 120))
    ecrire(d, (64, 200), "ラーメン", 90, (255, 255, 255))
    ecrire(d, (64, 340), "Des nouilles chaudes,", 44, (255, 220, 200))
    ecrire(d, (64, 396), "jour et nuit !", 44, (255, 220, 200))
    return im


def pub_soda():
    im = fond(1024, 512, (10, 30, 70), (20, 140, 170))
    d = ImageDraw.Draw(im)
    for k in range(40):
        x, y, r = RNG.uniform(0, 1024), RNG.uniform(0, 512), RNG.uniform(4, 16)
        d.ellipse((x - r, y - r, x + r, y + r), outline=(200, 255, 255), width=3)
    # la canette
    d.rounded_rectangle((720, 70, 900, 450), radius=30, fill=(255, 60, 170))
    d.rectangle((720, 200, 900, 300), fill=(40, 230, 255))
    d.ellipse((720, 50, 900, 100), fill=(200, 200, 210))
    ecrire(d, (810, 250), "S", 110, (255, 255, 255), "mm")
    ecrire(d, (60, 70), "SYNTHÉ-SODA", 80, (120, 255, 255))
    ecrire(d, (64, 230), "Le goût du futur !", 56, (255, 255, 255))
    ecrire(d, (64, 320), "Pétillant aux fruits", 44, (255, 160, 230))
    ecrire(d, (64, 380), "de la Lune", 44, (255, 160, 230))
    return im


def pub_monorail():
    im = fond(1024, 512, (20, 10, 50), (70, 30, 110))
    d = ImageDraw.Draw(im)
    # la ville au fond
    for k in range(18):
        x = k * 60
        hh = RNG.uniform(120, 330)
        d.rectangle((x, 512 - hh, x + 50, 512), fill=(30, 20, 60))
        for j in range(int(hh / 22)):
            if RNG.random() < 0.5:
                d.rectangle((x + 8, 512 - hh + 8 + j * 22, x + 18, 512 - hh + 16 + j * 22), fill=(255, 210, 120))
    # le rail et le train
    d.rectangle((0, 300, 1024, 318), fill=(180, 180, 200))
    d.rounded_rectangle((180, 220, 820, 300), radius=40, fill=(235, 240, 250))
    d.rectangle((200, 240, 800, 270), fill=(40, 200, 255))
    d.line([(180, 288), (820, 288)], fill=(255, 60, 170), width=6)
    ecrire(d, (512, 40), "MONORAIL DE NÉOPOLIS", 70, (255, 255, 255), "ma")
    ecrire(d, (512, 380), "Toute la ville en 4 minutes", 52, (120, 240, 255), "ma")
    return im


def pub_chat():
    im = fond(1024, 512, (40, 40, 50), (20, 20, 30))
    d = ImageDraw.Draw(im)
    # le robo-chat : tête ronde, oreilles, yeux d'écran
    cx, cy = 820, 290
    d.ellipse((cx - 150, cy - 130, cx + 150, cy + 150), fill=(210, 215, 225))
    d.polygon([(cx - 140, cy - 60), (cx - 120, cy - 200), (cx - 40, cy - 110)], fill=(210, 215, 225))
    d.polygon([(cx + 140, cy - 60), (cx + 120, cy - 200), (cx + 40, cy - 110)], fill=(210, 215, 225))
    d.rounded_rectangle((cx - 110, cy - 50, cx + 110, cy + 40), radius=30, fill=(20, 30, 40))
    d.arc((cx - 85, cy - 30, cx - 25, cy + 20), 200, 340, fill=(60, 255, 200), width=10)
    d.arc((cx + 25, cy - 30, cx + 85, cy + 20), 200, 340, fill=(60, 255, 200), width=10)
    d.polygon([(cx - 12, cy + 60), (cx + 12, cy + 60), (cx, cy + 74)], fill=(255, 120, 170))
    for s in (-1, 1):
        for k in range(3):
            d.line([(cx + s * 60, cy + 80 + k * 14), (cx + s * 170, cy + 66 + k * 24)], fill=(120, 130, 140), width=4)
    # les ondes du Wi-Fi
    for k in range(3):
        r = 40 + k * 32
        d.arc((cx - r, cy - 260 - r, cx + r, cy - 260 + r), 225, 315, fill=(60, 255, 200), width=8)
    ecrire(d, (60, 80), "ROBO-CHAT", 92, (255, 255, 255))
    ecrire(d, (64, 240), "Il ronronne", 60, (60, 255, 200))
    ecrire(d, (64, 320), "en Wi-Fi.", 60, (60, 255, 200))
    ecrire(d, (64, 420), "(Croquettes non comprises.)", 30, (190, 190, 200))
    return im


def pub_tour():
    im = fond(512, 1024, (10, 20, 60), (60, 10, 70))
    d = ImageDraw.Draw(im)
    d.polygon([(256, 140), (330, 330), (330, 1024), (182, 1024), (182, 330)], fill=(30, 40, 70))
    for k in range(60):
        y = 340 + k * 12
        d.line([(190, y), (322, y)], fill=(80, 200, 255) if k % 5 else (255, 80, 200), width=2)
    d.ellipse((150, 280, 362, 330), outline=(80, 240, 255), width=6)
    ecrire(d, (256, 40), "TOUR", 90, (255, 255, 255), "ma")
    ecrire(d, (256, 870), "AXIOME", 80, (120, 240, 255), "ma")
    ecrire(d, (256, 960), "la Terrasse du Ciel", 34, (255, 200, 240), "ma")
    return im


def pub_arcade():
    im = fond(512, 1024, (30, 0, 40), (0, 0, 0))
    d = ImageDraw.Draw(im)
    # un dragon en gros pixels
    motif = ["..XXX.....", ".XXXXX....", "XX.XXXX...", "XXXXXXXXX.", "....XXXXXX", "...XXXXX.X", "..XXXXX...", ".XX..XX...", "XX....XX.."]
    p = 40
    for j, row in enumerate(motif):
        for i, c in enumerate(row):
            if c == "X":
                d.rectangle((56 + i * p, 300 + j * p, 56 + i * p + p - 4, 300 + j * p + p - 4), fill=(80, 255, 120))
    d.rectangle((56 + 2 * p, 300 + 2 * p, 56 + 3 * p - 4, 300 + 3 * p - 4), fill=(255, 255, 255))
    for k in range(5):
        d.rectangle((420 + k * 6, 360 + k * 30, 440 + k * 6, 380 + k * 30), fill=(255, 140, 40))
    ecrire(d, (256, 60), "ARCADE", 96, (255, 80, 220), "ma")
    ecrire(d, (256, 170), "ゲーム", 70, (255, 255, 255), "ma")
    ecrire(d, (256, 760), "DRAGON-PIXEL", 52, (80, 255, 120), "ma")
    ecrire(d, (256, 840), "1 pièce = 3 vies", 40, (255, 255, 255), "ma")
    return im


def pub_lunettes():
    im = fond(512, 1024, (240, 240, 250), (170, 190, 230))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((70, 420, 240, 520), radius=40, outline=(30, 30, 50), width=14, fill=(120, 230, 255))
    d.rounded_rectangle((272, 420, 442, 520), radius=40, outline=(30, 30, 50), width=14, fill=(255, 140, 220))
    d.line([(240, 460), (272, 460)], fill=(30, 30, 50), width=14)
    ecrire(d, (256, 100), "Lunettes", 70, (30, 30, 60), "ma")
    ecrire(d, (256, 190), "HOLO", 120, (200, 40, 160), "ma")
    ecrire(d, (256, 640), "Voyez la ville", 48, (30, 30, 60), "ma")
    ecrire(d, (256, 700), "en couleurs", 48, (30, 30, 60), "ma")
    ecrire(d, (256, 760), "qui n'existent pas.", 48, (30, 30, 60), "ma")
    return im


def pub_ville():
    im = fond(512, 1024, (5, 5, 20), (40, 10, 60))
    d = ImageDraw.Draw(im)
    d.ellipse((150, 120, 360, 330), fill=(255, 80, 160))
    for k in range(10):
        d.rectangle((0, 160 + k * 16, 512, 166 + k * 16), fill=(5, 5, 20) if k % 2 else (40, 10, 60))
    for k in range(9):
        x = k * 58
        hh = RNG.uniform(200, 520)
        d.rectangle((x, 1024 - hh, x + 52, 1024), fill=(10, 10, 30))
        for j in range(int(hh / 26)):
            if RNG.random() < 0.55:
                d.rectangle((x + 10, 1024 - hh + 10 + j * 26, x + 22, 1024 - hh + 20 + j * 26), fill=(60, 230, 255) if RNG.random() < 0.5 else (255, 200, 120))
    ecrire(d, (256, 380), "NÉOPOLIS", 86, (255, 255, 255), "ma")
    ecrire(d, (256, 480), "la ville qui", 46, (120, 240, 255), "ma")
    ecrire(d, (256, 536), "ne dort jamais", 46, (120, 240, 255), "ma")
    return im


def assembler(pages, nom):
    w, h = pages[0].size
    atlas = Image.new("RGBA", (w * len(pages), h))
    for i, p in enumerate(pages):
        atlas.paste(p, (i * w, 0))
    atlas.convert("RGB").save(OUT / nom, optimize=True)


NEONS_PLATS = [
    ("ramen", "RAMEN", ROUGE), ("hotel", "HÔTEL NÉO", VIOLET), ("arcade", "ARCADE", ROSE), ("ouvert", "OUVERT 24/24", VERT),
    ("karaoke", "KARAOKÉ", AMBRE), ("nouilles", "NOUILLES", CYAN), ("cybercafe", "CYBER-CAFÉ", CYAN), ("reparations", "RÉPARATIONS", AMBRE),
    ("the", "SALON DE THÉ", VERT), ("data", "DATA", BLANC), ("jus", "BAR À JUS", ROSE), ("pharmacie", "+ PHARMACIE +", VERT),
    ("robots", "ROBOTS & CIE", CYAN), ("dumplings", "RAVIOLIS", ROUGE), ("bijoux", "BIJOUX", VIOLET), ("monorail", "MONORAIL", BLANC),
]
NEONS_COLONNES = [("c_ramen", "ラーメン", ROUGE), ("c_neo", "ネオ", CYAN), ("c_game", "ゲーム", ROSE), ("c_hotel", "HÔTEL", VIOLET),
                  ("c_cafe", "CAFÉ", AMBRE), ("c_open", "OPEN", VERT)]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    assembler([pub_ramen(), pub_soda(), pub_monorail(), pub_chat()], "ecrans_larges.png")
    assembler([pub_tour(), pub_arcade(), pub_lunettes(), pub_ville()], "ecrans_hauts.png")
    for nom, txt, c in NEONS_PLATS:
        neon_plat(nom, txt, c, taille=150 if len(txt) < 8 else (118 if len(txt) < 11 else 96))
    for nom, txt, c in NEONS_COLONNES:
        neon_colonne(nom, list(txt), c)
    print("V94 : %d enseignes, 8 réclames" % (len(NEONS_PLATS) + len(NEONS_COLONNES)))


if __name__ == "__main__":
    main()
