#!/bin/bash
# Des images de l'Île des Géants (V142) et une planche qui les rassemble.
#     bash tests/outils/rendu_geants.sh DOSSIER [tout | vues | geants]
# Il faut xvfb-run (un écran virtuel) : le rendu passe par OpenGL.
DEPOT="$(cd "$(dirname "$0")/../.." && pwd)"
COPIE="${TESTS_COPIE:-/root/t38}"
GODOT="${TESTS_GODOT:-$HOME/gd/godot}"
OUT="$1"
QUOI="${2:-tout}"
mkdir -p "$OUT"
rm -f "$OUT"/*.png
cp "$DEPOT/pcvr/stage_assets.py" "$COPIE/pcvr/stage_assets.py"
for f in pcvr/scripts/ile_geants_v142.gd pcvr/scripts/geants_v142.gd pcvr/scripts/geants_kit_v142.gd pcvr/scripts/geants_flore_v142.gd \
    pcvr/scripts/limace_v142.gd pcvr/scripts/pnj/pnj_geant_v142.gd pcvr/scripts/pnj/geants_habitants_v142.gd \
    pcvr/shaders/geants_sol_v142.gdshader pcvr/shaders/linge_v142.gdshader; do
  cp "$DEPOT/$f" "$COPIE/$f"
done
# les textures et les corps des géants passent par la copie de test (www), puis stage_assets.py (qui écrit
# les réglages d'import), puis l'import de Godot si quelque chose a changé
mkdir -p "$COPIE/www/assets/textures/geants"
NOUVEAU=0
for f in "$DEPOT"/www/assets/textures/geants/*.png; do
  d="$COPIE/www/assets/textures/geants/$(basename "$f")"
  if ! cmp -s "$f" "$d"; then cp "$f" "$d"; NOUVEAU=1; fi
  i="$COPIE/pcvr/assets/textures/geants/$(basename "$f").import"
  if [ ! -f "$i" ] || ! grep -q "^path" "$i"; then NOUVEAU=1; fi
done
for f in "$DEPOT"/www/assets/models/pnj64/*_gt.bin; do
  cp "$f" "$COPIE/www/assets/models/pnj64/"
done
(cd "$COPIE" && python3 pcvr/stage_assets.py > /dev/null)
if [ "$NOUVEAU" = "1" ]; then
  (cd "$COPIE" && flock /tmp/godot77.lock timeout 900 "$GODOT" --headless --path pcvr --import > /dev/null 2>&1)
fi
cp "$DEPOT/tests/outils/rendu_geants.gd" "$COPIE/pcvr/rendu_geants.gd"
cd "$COPIE" && flock /tmp/godot77.lock timeout 1500 xvfb-run -a -s "-screen 0 1280x800x24" "$GODOT" --path pcvr \
  --rendering-method gl_compatibility --rendering-driver opengl3 --resolution 640x400 --audio-driver Dummy \
  --script res://rendu_geants.gd -- "$OUT" "$QUOI" 2>&1 | grep -E "SCRIPT ERROR|Parse Error|ERROR: .*\.gd|ILE_MANGA_V142|at: " | head -30
rm -f "$COPIE/pcvr/rendu_geants.gd"
python3 - "$OUT" <<'PY'
import sys, glob, os
from PIL import Image, ImageDraw
out = sys.argv[1]
files = sorted(glob.glob(os.path.join(out, "*.png")))
if not files:
    sys.exit(0)
w, h = Image.open(files[0]).size
cols = 2
for page in range(0, len(files), 8):
    chunk = files[page:page + 8]
    rows = (len(chunk) + 1) // 2
    sheet = Image.new("RGB", (w * cols, h * rows), (0, 0, 0))
    for i, f in enumerate(chunk):
        sheet.paste(Image.open(f).convert("RGB"), ((i % cols) * w, (i // cols) * h))
        ImageDraw.Draw(sheet).text(((i % cols) * w + 6, (i // cols) * h + 4), os.path.basename(f)[:-4], fill=(255, 255, 255))
    p = os.path.join(out, "planche_%d.jpg" % (page // 8))
    sheet.save(p, quality=86)
    print(p)
PY
