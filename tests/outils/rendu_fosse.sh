#!/bin/bash
# Des images de la Fosse aux Dés (V147 : la salle, les tables, assis aux tables) et une planche.
#     bash tests/outils/rendu_fosse.sh DOSSIER
# Il faut xvfb-run (un écran virtuel) : le rendu passe par OpenGL.
DEPOT="$(cd "$(dirname "$0")/../.." && pwd)"
COPIE="${TESTS_COPIE:-/root/t38}"
GODOT="${TESTS_GODOT:-$HOME/gd/godot}"
OUT="$1"
mkdir -p "$OUT"
rm -f "$OUT"/*.png
(cd "$DEPOT" && git ls-files -m -o --exclude-standard pcvr www) | while read -r r; do
  [ -f "$DEPOT/$r" ] || continue
  mkdir -p "$(dirname "$COPIE/$r")"
  cmp -s "$DEPOT/$r" "$COPIE/$r" || cp "$DEPOT/$r" "$COPIE/$r"
done
cp "$DEPOT/tests/outils/rendu_fosse.gd" "$COPIE/pcvr/rendu_fosse.gd"
cd "$COPIE" && flock /tmp/godot77.lock timeout 900 xvfb-run -a -s "-screen 0 1280x800x24" "$GODOT" --path pcvr \
  --rendering-method gl_compatibility --rendering-driver opengl3 --resolution 960x600 --audio-driver Dummy \
  --script res://rendu_fosse.gd -- "$OUT" 2>&1 | grep -E "SCRIPT ERROR|Parse Error|ERROR: .*\.gd|RENDU|MESSAGE|at: " | head -40
rm -f "$COPIE/pcvr/rendu_fosse.gd"
python3 - "$OUT" <<'PY'
import sys, glob, os
from PIL import Image, ImageDraw
out = sys.argv[1]
files = sorted(glob.glob(os.path.join(out, "*.png")))
if not files:
    sys.exit(0)
w, h = Image.open(files[0]).size
for page in range(0, len(files), 8):
    chunk = files[page:page + 8]
    rows = (len(chunk) + 1) // 2
    sheet = Image.new("RGB", (w * 2, h * rows))
    for i, f in enumerate(chunk):
        sheet.paste(Image.open(f).convert("RGB"), ((i % 2) * w, (i // 2) * h))
        ImageDraw.Draw(sheet).text(((i % 2) * w + 6, (i // 2) * h + 4), os.path.basename(f)[:-4], fill=(255, 255, 255))
    p = os.path.join(out, "planche_%d.jpg" % (page // 8))
    sheet.save(p, quality=86)
    print(p)
PY
