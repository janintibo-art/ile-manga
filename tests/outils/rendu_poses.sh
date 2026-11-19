#!/bin/bash
# V179 : les poses des habitants en photo (voir rendu_poses.gd), et des planches (8 poses par planche,
# chacune de face, de trois quarts et de profil).
#     bash tests/outils/rendu_poses.sh DOSSIER [corps] [poses]
#     ex. : bash tests/outils/rendu_poses.sh /tmp/poses "montjoie:0,montjoie:1,pirate:0" "bras_croises,colere"
#     RENDU_OS=1 : les articulations des bras en petites boules (rouges à gauche, bleues à droite) ;
#     RENDU_SANS_EPAULES=1 : sans corps_v64.Epaules (les épaules qui suivent le bras), pour comparer
# Il faut xvfb-run (un écran virtuel) : le rendu passe par OpenGL.
DEPOT="$(cd "$(dirname "$0")/../.." && pwd)"
COPIE="${TESTS_COPIE:-/root/t38}"
GODOT="${TESTS_GODOT:-$HOME/gd/godot}"
OUT="$1"
mkdir -p "$OUT"
rm -f "$OUT"/*.png "$OUT"/*.jpg
(cd "$DEPOT" && git ls-files -m -o --exclude-standard pcvr www) | while read -r r; do
  [ -f "$DEPOT/$r" ] || continue
  mkdir -p "$(dirname "$COPIE/$r")"
  cmp -s "$DEPOT/$r" "$COPIE/$r" || cp "$DEPOT/$r" "$COPIE/$r"
done
(cd "$COPIE" && python3 pcvr/stage_assets.py > /dev/null)
(cd "$COPIE" && flock /tmp/godot77.lock timeout 1800 "$GODOT" --headless --path pcvr --import > /dev/null 2>&1)
cp "$DEPOT/tests/outils/rendu_poses.gd" "$COPIE/pcvr/rendu_poses.gd"
cd "$COPIE" && flock /tmp/godot77.lock timeout 3600 xvfb-run -a -s "-screen 0 1280x800x24" "$GODOT" --path pcvr \
  --rendering-method gl_compatibility --rendering-driver opengl3 --resolution 640x480 --audio-driver Dummy \
  --script res://rendu_poses.gd -- "$OUT" "${2:-}" "${3:-}" 2>&1 | grep -E "SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR: .*\.gd|RENDU|at: |^ *[0-9]+ \\| " | head -400
rm -f "$COPIE/pcvr/rendu_poses.gd"
python3 - "$OUT" <<'PY'
import sys, glob, os
from PIL import Image, ImageDraw
out = sys.argv[1]
files = sorted(glob.glob(os.path.join(out, "*__face.png")))
if not files:
    sys.exit(0)
w, h = Image.open(files[0]).size
cells = []
for f in files:
    base = f[:-len("__face.png")]
    vues = [base + "__" + v + ".png" for v in ("face", "trois_quarts", "profil")]
    cell = Image.new("RGB", (w * 3, h))
    for k, v in enumerate(vues):
        if os.path.exists(v):
            cell.paste(Image.open(v).convert("RGB"), (k * w, 0))
    d = ImageDraw.Draw(cell)
    d.rectangle([0, 0, w * 3, 18], fill=(0, 0, 0))
    d.text((6, 3), os.path.basename(base).replace("__", "  "), fill=(255, 255, 255))
    cells.append(cell)
for page in range(0, len(cells), 8):
    chunk = cells[page:page + 8]
    rows = (len(chunk) + 1) // 2
    sheet = Image.new("RGB", (w * 6 + 8, h * rows + 4 * rows), (255, 255, 255))
    for i, c in enumerate(chunk):
        sheet.paste(c, ((i % 2) * (w * 3 + 8), (i // 2) * (h + 4)))
    p = os.path.join(out, "planche_%02d.jpg" % (page // 8))
    sheet.save(p, quality=85)
    print(p)
PY
