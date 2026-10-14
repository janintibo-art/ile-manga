"""V41 : textures et icônes des elfes (dessinées ici, libres de droits).

- elfe_lyra.png : la texture du personnage, recolorée en elfe (peau claire, vêtements
  vert forêt, clous et fermetures devenus argent) à partir de la texture du modèle.
- icônes : fiole vide, eau de source, fleur de lune, graine d'or, boussole elfique.
Lancement : python3 pcvr/tools/generate_elfes_v41.py (depuis la racine du dépôt).
"""
from pathlib import Path
import io
import json
import math
import struct
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_items_v28 as base  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "www" / "assets" / "textures" / "elfes"
OUT.mkdir(parents=True, exist_ok=True)


def model_texture():
    data = (ROOT / "www" / "assets" / "models" / "characters" / "hero.glb").read_bytes()
    jlen = struct.unpack("<I", data[12:16])[0]
    gltf = json.loads(data[20:20 + jlen])
    bin_start = 20 + jlen + 8
    view = gltf["bufferViews"][gltf["images"][0]["bufferView"]]
    off = bin_start + view.get("byteOffset", 0)
    return Image.open(io.BytesIO(data[off:off + view["byteLength"]])).convert("RGBA")


def elf_texture(name, skin, cloth, metal):
    img = model_texture().resize((1024, 1024), Image.LANCZOS)
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
    cl = np.array(cloth)[None, None, :] * (0.45 + lum[..., None] * 2.4)
    out[dark] = np.clip(cl, 0, 1)[dark]
    light = (lum > 0.55) & (sat < 0.25) & ~yellow
    out[light] = (np.array(metal)[None, None, :] * np.clip(lum, 0.6, 1.0)[..., None])[light]
    res = np.concatenate([np.clip(out, 0, 1), a[..., 3:4]], axis=2)
    Image.fromarray((res * 255).astype(np.uint8), "RGBA").save(OUT / f"{name}.png", optimize=True)
    print(name)


def flask(name, water):
    img = base.canvas()
    d = ImageDraw.Draw(img)
    glass = (200, 230, 240, 120)
    d.rectangle((226, 70, 286, 160), fill=glass)
    d.rectangle((216, 52, 296, 82), fill=(150, 110, 70, 255))
    d.ellipse((140, 140, 372, 440), fill=glass)
    if water:
        layer = base.canvas()
        base.shaded_ellipse(layer, (150, 210, 362, 432), (80, 170, 230))
        mask = Image.new("L", (512, 512), 0)
        ImageDraw.Draw(mask).rectangle((0, 260, 512, 512), fill=255)
        img.paste(layer, (0, 0), Image.composite(layer.split()[3], Image.new("L", (512, 512), 0), mask))
        d = ImageDraw.Draw(img)
        for k in range(6):
            x = 190 + k * 26
            d.ellipse((x, 300 + (k % 3) * 30, x + 10, 310 + (k % 3) * 30), fill=(230, 250, 255, 255))
    d.arc((140, 140, 372, 440), 200, 300, fill=(255, 255, 255, 220), width=10)
    base.save(img, name)


def fleur_lune():
    img = base.canvas()
    d = ImageDraw.Draw(img)
    d.line((256, 300, 250, 470), fill=(60, 130, 70, 255), width=14)
    d.ellipse((150, 380, 250, 420), fill=(70, 150, 80, 255))
    for k in range(7):
        a = math.radians(k * 360 / 7 - 90)
        cx, cy = int(256 + math.cos(a) * 95), int(230 + math.sin(a) * 95)
        lay = base.canvas()
        base.shaded_ellipse(lay, (cx - 62, cy - 62, cx + 62, cy + 62), (235, 240, 255))
        img.alpha_composite(lay)
    lay = base.canvas()
    base.shaded_ellipse(lay, (210, 184, 302, 276), (190, 230, 255))
    img.alpha_composite(lay)
    glow = img.split()[3].filter(ImageFilter.GaussianBlur(18))
    halo = Image.new("RGBA", img.size, (170, 210, 255, 0))
    halo.putalpha(glow.point(lambda v: v // 2))
    halo.alpha_composite(img)
    base.save(halo, "fleur_lune")


def graine_or():
    img = base.canvas()
    base.shaded_ellipse(img, (150, 110, 362, 420), (230, 180, 50))
    d = ImageDraw.Draw(img)
    d.arc((170, 130, 342, 400), 250, 290, fill=(150, 100, 20, 255), width=8)
    d.polygon([(256, 70), (240, 130), (272, 130)], fill=(110, 170, 70, 255))
    base.save(img, "graine_or")


def boussole_elfique():
    img = base.canvas()
    base.shaded_ellipse(img, (70, 70, 442, 442), (205, 210, 220))
    base.shaded_ellipse(img, (110, 110, 402, 402), (40, 80, 70), gloss=False)
    d = ImageDraw.Draw(img)
    for k in range(8):
        a = math.radians(k * 45)
        d.line((256 + math.cos(a) * 120, 256 + math.sin(a) * 120, 256 + math.cos(a) * 140, 256 + math.sin(a) * 140), fill=(220, 230, 200, 255), width=6)
    d.polygon([(256, 120), (284, 256), (256, 392), (228, 256)], fill=(120, 255, 180, 255))
    d.polygon([(256, 120), (284, 256), (256, 256)], fill=(200, 255, 225, 255))
    d.ellipse((240, 240, 272, 272), fill=(230, 240, 255, 255))
    base.save(img, "boussole_elfique")


if __name__ == "__main__":
    elf_texture("elfe_lyra", (1.0, 0.9, 0.82), (0.16, 0.42, 0.3), (0.86, 0.88, 0.92))
    flask("fiole_vide", False)
    flask("eau_source", True)
    fleur_lune()
    graine_or()
    boussole_elfique()
