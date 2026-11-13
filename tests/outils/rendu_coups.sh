#!/bin/bash
# Des images des réactions aux coups et de l'onde de choc (V141), et une planche qui les rassemble.
#     bash tests/outils/rendu_coups.sh DOSSIER
# Il faut xvfb-run (un écran virtuel) : le rendu passe par OpenGL.
DEPOT="$(cd "$(dirname "$0")/../.." && pwd)"
COPIE="${TESTS_COPIE:-/root/t38}"
GODOT="${TESTS_GODOT:-$HOME/gd/godot}"
OUT="$1"
mkdir -p "$OUT"
rm -f "$OUT"/*.png
for f in pcvr/scripts/monstre_v139.gd pcvr/scripts/monstre_v140.gd pcvr/scripts/coups_v141.gd pcvr/scripts/combat_fx_v129.gd; do
  cp "$DEPOT/$f" "$COPIE/$f"
done
cp "$DEPOT/tests/outils/rendu_coups.gd" "$COPIE/pcvr/rendu_coups.gd"
cd "$COPIE" && flock /tmp/godot77.lock timeout 600 xvfb-run -a -s "-screen 0 1280x800x24" "$GODOT" --path pcvr \
  --rendering-method gl_compatibility --rendering-driver opengl3 --resolution 480x320 --audio-driver Dummy \
  --script res://rendu_coups.gd -- "$OUT" 2>&1 | grep -E "SCRIPT ERROR|Parse Error|ERROR: .*\.gd" | head -20
rm -f "$COPIE/pcvr/rendu_coups.gd"
python3 - "$OUT" <<'PY'
import sys, glob, os
from PIL import Image, ImageDraw
out = sys.argv[1]
files = sorted(glob.glob(os.path.join(out, "*.png")), key=lambda f: int(os.path.basename(f).split("_")[0]))
if not files:
    sys.exit(0)
w, h = Image.open(files[0]).size
cols = 2
rows = (len(files) + 1) // 2
sheet = Image.new("RGB", (w * cols, h * rows), (0, 0, 0))
for i, f in enumerate(files):
    sheet.paste(Image.open(f).convert("RGB"), ((i % cols) * w, (i // cols) * h))
    ImageDraw.Draw(sheet).text(((i % cols) * w + 6, (i // cols) * h + 4), os.path.basename(f)[:-4], fill=(255, 255, 255))
sheet.save(os.path.join(out, "planche.jpg"), quality=88)
print(os.path.join(out, "planche.jpg"))
PY
