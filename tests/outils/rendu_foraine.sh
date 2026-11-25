#!/bin/bash
# Des images de l'Île Foraine (V209) et des planches qui les rassemblent.
#     bash tests/outils/rendu_foraine.sh DOSSIER [tout | vues | tour]
# Il faut xvfb-run (un écran virtuel) : le rendu passe par OpenGL.
DEPOT="$(cd "$(dirname "$0")/../.." && pwd)"
COPIE="${TESTS_COPIE:-/root/t38}"
GODOT="${TESTS_GODOT:-$HOME/gd/godot}"
OUT="$1"
QUOI="${2:-tout}"
mkdir -p "$OUT"
rm -f "$OUT"/*.png
for f in pcvr/scripts/ile_foraine_v209.gd pcvr/scripts/foraine_v209.gd pcvr/scripts/foraine_kit_v209.gd pcvr/scripts/grand_huit_v209.gd \
    pcvr/scripts/grand_huit_trace_v209.gd pcvr/scripts/geants_kit_v142.gd pcvr/scripts/metal_kit_v160.gd pcvr/shaders/geants_sol_v142.gdshader; do
  cp "$DEPOT/$f" "$COPIE/$f"
done
cp "$DEPOT/tests/outils/rendu_foraine.gd" "$COPIE/pcvr/rendu_foraine.gd"
cd "$COPIE" && flock /tmp/godot77.lock timeout 1500 xvfb-run -a -s "-screen 0 1280x800x24" "$GODOT" --path pcvr \
  --rendering-method gl_compatibility --rendering-driver opengl3 --resolution "${RENDU_RES:-640x400}" --audio-driver Dummy \
  --script res://rendu_foraine.gd -- "$OUT" "$QUOI" 2>&1 | grep -E "SCRIPT ERROR|Parse Error|ERROR: .*\.gd|ILE_MANGA_V209|at: " | head -60
rm -f "$COPIE/pcvr/rendu_foraine.gd"
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
