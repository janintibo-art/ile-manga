#!/bin/bash
# Des images de la magie (V219), avant et après, et des planches qui les rassemblent.
#     bash tests/outils/rendu_magie.sh DOSSIER [tout | feu | givre | foudre | ennemi] [jour | nuit]
# Il faut xvfb-run (un écran virtuel) : le rendu passe par OpenGL. Le temps avance d'un pas fixe.
# SOURCE : le dossier où prendre magie_v219.gd, ses shaders et cet outil (par défaut : le dépôt).
ICI="$(cd "$(dirname "$0")/../.." && pwd)"
SOURCE="${SOURCE:-$ICI}"
COPIE="${TESTS_COPIE:-/root/t38}"
GODOT="${TESTS_GODOT:-$HOME/gd/godot}"
OUT="$1"
QUOI="${2:-tout}"
QUAND="${3:-jour}"
mkdir -p "$OUT"
rm -f "$OUT"/*.png
mkdir -p "$COPIE/pcvr/shaders/magie_v219"
cp "$SOURCE/pcvr/scripts/magie_v219.gd" "$COPIE/pcvr/scripts/magie_v219.gd"
cp "$SOURCE"/pcvr/shaders/magie_v219/*.gdshader "$COPIE/pcvr/shaders/magie_v219/"
cp "$SOURCE/tests/outils/rendu_magie.gd" "$COPIE/pcvr/rendu_magie.gd"
cd "$COPIE" && flock /tmp/godot77.lock timeout "${DELAI:-1500}" xvfb-run -a -s "-screen 0 1280x800x24" "$GODOT" --path pcvr \
  --rendering-method gl_compatibility --rendering-driver opengl3 --resolution 800x500 --audio-driver Dummy --fixed-fps 30 \
  --script res://rendu_magie.gd -- "$OUT" "$QUOI" "$QUAND" > "$OUT/journal.txt" 2>&1
grep -E "SCRIPT ERROR|Parse Error|ERROR|SHADER|error" "$OUT/journal.txt" | head -40
rm -f "$COPIE/pcvr/rendu_magie.gd"
python3 - "$OUT" <<'PY'
import sys, glob, os
from PIL import Image, ImageDraw
out = sys.argv[1]
files = sorted(glob.glob(os.path.join(out, "*.png")))
if not files:
    print("aucune image")
    sys.exit(0)
groupes = {}
for f in files:
    nom = os.path.basename(f)[3:-4]            # feu_apres_2_eclat
    sort, version = nom.split("_")[0], nom.split("_")[1]
    groupes.setdefault((sort, version), []).append(f)
w, h = Image.open(files[0]).size
for (sort, version), fs in groupes.items():
    cols = 3 if len(fs) > 4 else 2
    rows = (len(fs) + cols - 1) // cols
    sheet = Image.new("RGB", (w * cols, h * rows), (0, 0, 0))
    for i, f in enumerate(fs):
        sheet.paste(Image.open(f).convert("RGB"), ((i % cols) * w, (i // cols) * h))
        d = ImageDraw.Draw(sheet)
        d.rectangle(((i % cols) * w, (i // cols) * h, (i % cols) * w + 250, (i // cols) * h + 18), fill=(0, 0, 0))
        d.text(((i % cols) * w + 6, (i // cols) * h + 3), os.path.basename(f)[3:-4], fill=(255, 255, 255))
    p = os.path.join(out, "planche_%s_%s.jpg" % (sort, version))
    sheet.save(p, quality=88)
    print(p)
PY
