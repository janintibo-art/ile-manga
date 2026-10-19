"""V53 : les habitants ne portent plus les clous et les pointes du héros.

Tous les habitants sont construits sur le modèle du héros (hero.glb), dont la tenue punk
a des clous, des pointes aux épaules et des chaînes. Ce script :
  1. lit la texture du modèle et repère les zones « métal » (gris clair, peu saturé) ;
  2. écrit ce masque (512 x 512, 1 bit par pixel) dans pcvr/scripts/pnj/masque_clous_v53.gd :
     au chargement, pnj_v31.gd aplatit les sommets du maillage situés sur ces zones
     (les pointes rentrent dans le vêtement) — uniquement pour les habitants ;
  3. efface ces zones des textures des elfes et des nains (les pixels sont reconstruits à
     partir du tissu autour), et crée textures/pnj/habitant_sobre.png pour les autres.
À relancer après generate_elfes_v41/v42.py ou generate_nains_v47.py, qui recréent les
textures avec leurs clous.
Lancement : python3 pcvr/tools/generate_pnj_v53.py (depuis la racine du dépôt).
"""
from pathlib import Path
import base64
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_elfes_v41 import model_texture  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
TEX = ROOT / "www" / "assets" / "textures"
MASK_GD = ROOT / "pcvr" / "scripts" / "pnj" / "masque_clous_v53.gd"


def metal_mask(img: Image.Image) -> np.ndarray:
    a = np.asarray(img.convert("RGB")).astype(np.float32) / 255.0
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    mx = a.max(axis=2)
    mn = a.min(axis=2)
    sat = (mx - mn) / np.maximum(mx, 1e-4)
    yellow = (r > 0.55) & (g > 0.4) & (b < 0.45) & (r - b > 0.3)
    return (lum > 0.45) & (sat < 0.28) & ~yellow


def dilate(m: np.ndarray, n: int) -> np.ndarray:
    out = m.copy()
    for _ in range(n):
        p = np.pad(out, 1)
        out = out | p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]
    return out


def inpaint(rgb: np.ndarray, hole: np.ndarray) -> np.ndarray:
    """Remplit les trous par moyenne itérative des voisins connus (diffusion)."""
    out = rgb.copy()
    known = ~hole
    out[hole] = 0.0
    for _ in range(200):
        if known.all():
            break
        p = np.pad(out * known[..., None], ((1, 1), (1, 1), (0, 0)))
        k = np.pad(known.astype(np.float32), 1)
        s = p[:-2, 1:-1] + p[2:, 1:-1] + p[1:-1, :-2] + p[1:-1, 2:]
        c = k[:-2, 1:-1] + k[2:, 1:-1] + k[1:-1, :-2] + k[1:-1, 2:]
        fill = (~known) & (c > 0)
        out[fill] = s[fill] / c[fill][..., None]
        known = known | fill
    return out


def clean_texture(path: Path, mask_hi: np.ndarray, dest: Path | None = None) -> None:
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    m = Image.fromarray((mask_hi * 255).astype(np.uint8)).resize((w, h), Image.BILINEAR)
    hole = dilate(np.asarray(m) > 60, 2)
    a = np.asarray(img).astype(np.float32) / 255.0
    rgb = inpaint(a[..., :3], hole)
    # un léger grain de tissu pour ne pas laisser de plages lisses
    noise = np.random.default_rng(53).normal(0.0, 0.018, rgb.shape[:2])[..., None]
    rgb[hole] = np.clip(rgb[hole] + noise[hole], 0, 1)
    res = np.concatenate([rgb, a[..., 3:4]], axis=2)
    (dest or path).parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray((res * 255).astype(np.uint8), "RGBA").save(dest or path, optimize=True)
    print("  propre :", (dest or path).relative_to(ROOT), int(hole.sum()), "pixels")


def main() -> None:
    hero = model_texture()
    mask = metal_mask(hero)
    print("masque métal :", round(mask.mean() * 100, 2), "% de la texture")
    # masque des sommets (512 x 512), un peu dilaté pour attraper les bords des pointes
    small = np.asarray(Image.fromarray((dilate(mask, 2) * 255).astype(np.uint8)).resize((512, 512), Image.BOX)) > 40
    bits = np.packbits(small.astype(np.uint8), axis=None)
    b64 = base64.b64encode(bits.tobytes()).decode()
    lines = [b64[i:i + 100] for i in range(0, len(b64), 100)]
    MASK_GD.write_text(
        "extends RefCounted\n"
        "## V53 : zones « métal » (clous, pointes, chaînes) de la texture du héros, 512 x 512,\n"
        "## 1 bit par pixel, ligne par ligne (généré par pcvr/tools/generate_pnj_v53.py).\n\n"
        "const SIZE: int = 512\n"
        "const DATA: String = \"" + b64 + "\"\n\n"
        "static var _bytes: PackedByteArray = PackedByteArray()\n\n\n"
        "## Vrai si le point de texture (u, v) tombe sur du métal.\n"
        "static func is_metal(uv: Vector2) -> bool:\n"
        "\tif _bytes.is_empty():\n"
        "\t\t_bytes = Marshalls.base64_to_raw(DATA)\n"
        "\tvar x: int = clampi(int(fposmod(uv.x, 1.0) * SIZE), 0, SIZE - 1)\n"
        "\tvar y: int = clampi(int(fposmod(uv.y, 1.0) * SIZE), 0, SIZE - 1)\n"
        "\tvar i: int = y * SIZE + x\n"
        "\treturn (_bytes[i >> 3] >> (7 - (i & 7))) & 1 == 1\n",
        encoding="utf-8")
    print("  ", MASK_GD.relative_to(ROOT), len(b64), "caractères")
    for f in sorted((TEX / "elfes").glob("*.png")) + sorted((TEX / "nains").glob("*.png")):
        clean_texture(f, mask)
    hero.resize((1024, 1024), Image.LANCZOS).save("/tmp/heros_1024.png")
    clean_texture(Path("/tmp/heros_1024.png"), mask, TEX / "pnj" / "habitant_sobre.png")


if __name__ == "__main__":
    main()
