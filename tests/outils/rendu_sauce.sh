#!/bin/bash
# V217 : le héros couvert de sauce tomate, et les mains de la VR (voir rendu_sauce.gd), et une planche.
#     bash tests/outils/rendu_sauce.sh DOSSIER
# Il faut xvfb-run (un écran virtuel) : le rendu passe par OpenGL.
DEPOT="$(cd "$(dirname "$0")/../.." && pwd)"
COPIE="${TESTS_COPIE:-/root/t38}"
GODOT="${TESTS_GODOT:-$HOME/gd/godot}"
OUT="$1"
mkdir -p "$OUT"
rm -f "$OUT"/*.png "$OUT"/*.jpg
for f in pcvr/scripts/sauce_heros_v217.gd pcvr/shaders/sauce_heros_v217.gdshader pcvr/scripts/vr_mains_v199.gd pcvr/scripts/hero_v28.gd; do
  cp "$DEPOT/$f" "$COPIE/$f"
done
cp "$DEPOT/tests/outils/rendu_sauce.gd" "$COPIE/pcvr/rendu_sauce.gd"
cd "$COPIE" && flock /tmp/godot77.lock timeout 900 xvfb-run -a -s "-screen 0 1280x800x24" "$GODOT" --path pcvr \
  --rendering-method gl_compatibility --rendering-driver opengl3 --resolution "${RENDU_RES:-800x600}" --audio-driver Dummy \
  --script res://rendu_sauce.gd -- "$OUT" 2>&1 | grep -E "SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR: .*\.gd|RENDU|^ *[0-9]+ \\| " | head -60
rm -f "$COPIE/pcvr/rendu_sauce.gd"
python3 - "$OUT" <<'PY'
import sys, glob, os
from PIL import Image, ImageDraw
out = sys.argv[1]
files = sorted(glob.glob(os.path.join(out, "*.png")))
if not files:
    sys.exit(0)
w, h = Image.open(files[0]).size
cols = 2
rows = (len(files) + 1) // 2
sheet = Image.new("RGB", (w * cols, h * rows), (0, 0, 0))
for i, f in enumerate(files):
    sheet.paste(Image.open(f).convert("RGB"), ((i % cols) * w, (i // cols) * h))
    ImageDraw.Draw(sheet).text(((i % cols) * w + 6, (i // cols) * h + 4), os.path.basename(f)[:-4], fill=(255, 255, 255))
p = os.path.join(out, "planche.jpg")
sheet.save(p, quality=86)
print(p)
PY
