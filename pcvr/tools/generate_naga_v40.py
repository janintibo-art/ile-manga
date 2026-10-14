"""V40 : icône de l'Écaille de Nâga (dessinée ici, libre de droits).

Lancement : python3 pcvr/tools/generate_naga_v40.py (depuis la racine du dépôt).
"""
from pathlib import Path
import sys

from PIL import ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_items_v28 as base  # noqa: E402


def ecaille_naga():
    img = base.canvas()
    # Une grande écaille en goutte, verte et brillante, avec ses stries et un reflet
    base.shaded_ellipse(img, (110, 70, 402, 450), (45, 120, 85))
    d = ImageDraw.Draw(img)
    for k in range(5):
        x = 180 + k * 38
        d.arc((x - 150, 120, x + 150, 520), 250, 290, fill=(20, 70, 45, 255), width=6)
    d.line((256, 96, 256, 430), fill=(130, 230, 160, 255), width=8)
    base.save(img, "ecaille_naga")


if __name__ == "__main__":
    ecaille_naga()
