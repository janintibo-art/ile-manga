"""Images de l'installateur Windows (Inno Setup 6.7) tirées de l'affiche du jeu.

fond_*.png   : l'image de fond de toutes les pages (rapport 497:360 imposé par Inno Setup),
               le héros et son chat à gauche, les îles qui s'assombrissent vers la droite
               pour que le texte reste lisible.
petite_*.png : la petite image carrée en haut à droite des pages intérieures (l'icône du jeu).
Lancer depuis pcvr : python3 tools/generate_installateur.py
"""
from pathlib import Path
from PIL import Image, ImageFilter, ImageEnhance, ImageDraw

ici = Path(__file__).resolve().parent.parent
repo = ici.parent
out = ici / "installateur"
out.mkdir(exist_ok=True)
(out / ".gdignore").write_text("")
affiche = Image.open(repo / "site" / "img" / "affiche.jpg").convert("RGB")
icone = Image.open(repo / "www" / "assets" / "textures" / "ui" / "les_mondes_de_travers_icon.png").convert("RGBA")
NUIT = (9, 13, 28)


def fond(w, h):
    aw, ah = affiche.size
    # Le décor : les îles de droite, floutées et assombries, sur toute la largeur.
    deco = affiche.crop((1250, 450, aw, ah)).resize((w, h), Image.LANCZOS)
    deco = deco.filter(ImageFilter.GaussianBlur(w / 260))
    deco = ImageEnhance.Brightness(deco).enhance(0.42)
    deco = ImageEnhance.Color(deco).enhance(0.8)
    # Le héros et son chat, nets, en bas à gauche, dans un masque doux en ellipse
    # (le haut du titre de l'affiche reste dehors).
    hero = affiche.crop((110, 320, 900, ah))
    hh = int(h * 0.9)
    hw = int(hero.width * hh / hero.height)
    hero = hero.resize((hw, hh), Image.LANCZOS)
    masque = Image.new("L", (hw, hh), 0)
    ImageDraw.Draw(masque).ellipse([-hw * 0.45, hh * 0.1, hw * 0.9, hh * 1.6], fill=255)
    masque = masque.filter(ImageFilter.GaussianBlur(hw / 16))
    deco.paste(hero, (0, h - hh), masque)
    # Un voile nuit qui monte vers la droite (zone du texte) et un vignettage doux.
    voile = Image.new("RGB", (w, h), NUIT)
    m = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(m)
    for x in range(w):
        t = x / w
        a = 25 if t < 0.38 else int(25 + 175 * min(1.0, (t - 0.38) / 0.3))
        d.line([(x, 0), (x, h)], fill=a)
    img = Image.composite(voile, deco, m)
    vig = Image.new("L", (w, h), 255)
    ImageDraw.Draw(vig).rectangle([w // 14, h // 14, w - w // 14, h - h // 14], fill=0)
    vig = vig.filter(ImageFilter.GaussianBlur(w / 18)).point(lambda v: int(v * 0.55))
    img = Image.composite(Image.new("RGB", (w, h), (0, 0, 0)), img, vig)
    return img


TAILLES = [(596, 432), (796, 576), (994, 720), (1272, 922), (1630, 1148)]
for w, h in TAILLES:
    fond(w, h).save(out / f"fond_{w}.png", optimize=True)
for s in (58, 73, 87, 116, 145):
    p = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    p.alpha_composite(icone.resize((s, s), Image.LANCZOS))
    p.save(out / f"petite_{s}.png", optimize=True)
print("images de l'installateur :", sorted(f.name for f in out.glob("*.png")))
