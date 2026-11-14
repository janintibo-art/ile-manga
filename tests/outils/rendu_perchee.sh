#!/bin/bash
# Des images de l'Île Perchée (V146) et une planche qui les rassemble.
#     bash tests/outils/rendu_perchee.sh DOSSIER [tout | ile | bourg]
# Il faut xvfb-run (un écran virtuel) : le rendu passe par OpenGL.
DEPOT="$(cd "$(dirname "$0")/../.." && pwd)"
COPIE="${TESTS_COPIE:-/root/t38}"
GODOT="${TESTS_GODOT:-$HOME/gd/godot}"
OUT="$1"
QUOI="${2:-tout}"
mkdir -p "$OUT"
rm -f "$OUT"/*.png
cp "$DEPOT/pcvr/stage_assets.py" "$COPIE/pcvr/stage_assets.py"
for f in "$DEPOT"/pcvr/scripts/*_v146.gd "$DEPOT"/pcvr/scripts/pnj/*_v146.gd "$DEPOT"/pcvr/shaders/*_v146.gdshader "$DEPOT"/pcvr/scripts/dirigeable_v61.gd; do
  [ -f "$f" ] || continue
  r="${f#$DEPOT/}"
  mkdir -p "$(dirname "$COPIE/$r")"
  cp "$f" "$COPIE/$r"
done
NOUVEAU=0
for f in "$DEPOT"/www/assets/textures/perchee/*.png; do
  [ -f "$f" ] || continue
  mkdir -p "$COPIE/www/assets/textures/perchee"
  d="$COPIE/www/assets/textures/perchee/$(basename "$f")"
  if ! cmp -s "$f" "$d"; then cp "$f" "$d"; NOUVEAU=1; fi
  i="$COPIE/pcvr/assets/textures/perchee/$(basename "$f").import"
  if [ ! -f "$i" ] || ! grep -q "^path" "$i"; then NOUVEAU=1; fi
done
(cd "$COPIE" && python3 pcvr/stage_assets.py > /dev/null)
if [ "$NOUVEAU" = "1" ]; then
  (cd "$COPIE" && flock /tmp/godot77.lock timeout 900 "$GODOT" --headless --path pcvr --import > /dev/null 2>&1)
fi
cp "$DEPOT/tests/outils/rendu_perchee.gd" "$COPIE/pcvr/rendu_perchee.gd"
cd "$COPIE" && flock /tmp/godot77.lock timeout 1500 xvfb-run -a -s "-screen 0 1280x800x24" "$GODOT" --path pcvr \
  --rendering-method gl_compatibility --rendering-driver opengl3 --resolution 640x400 --audio-driver Dummy \
  --script res://rendu_perchee.gd -- "$OUT" "$QUOI" 2>&1 | grep -E "SCRIPT ERROR|Parse Error|ERROR: .*\.g|ILE_MANGA_V146|at: " | head -30
rm -f "$COPIE/pcvr/rendu_perchee.gd"
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
