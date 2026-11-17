#!/bin/bash
# Des images d'une île seule (V159 à V167) et des planches.
#     bash tests/outils/rendu_iles.sh DOSSIER elfes|village|nains|forgefer|moai|nuees|nuees_mur|strates|strates_four|dome|dome_v160|celeste|jungle|jungle_piton|atlantide|azur|fees|teuf|facade|carene|tazira|cliquetis|ramure|porte|carene_hd|tazira_hd|cliquetis_hd|ramure_hd|arcanelle|coutelas|soleils|pandemonia|montjoie|boucan|astralys|pixel|larsen
# Il faut xvfb-run (un écran virtuel) : le rendu passe par OpenGL.
DEPOT="$(cd "$(dirname "$0")/../.." && pwd)"
COPIE="${TESTS_COPIE:-/root/t38}"
GODOT="${TESTS_GODOT:-$HOME/gd/godot}"
OUT="$1"
QUOI="${2:-elfes}"
mkdir -p "$OUT"
rm -f "$OUT"/*.png "$OUT"/*.jpg
(cd "$DEPOT" && git ls-files -m -o --exclude-standard pcvr www) | while read -r r; do
  [ -f "$DEPOT/$r" ] || continue
  mkdir -p "$(dirname "$COPIE/$r")"
  cmp -s "$DEPOT/$r" "$COPIE/$r" || cp "$DEPOT/$r" "$COPIE/$r"
done
(cd "$COPIE" && python3 pcvr/stage_assets.py > /dev/null)
(cd "$COPIE" && flock /tmp/godot77.lock timeout 1800 "$GODOT" --headless --path pcvr --import > /dev/null 2>&1)
cp "$DEPOT/tests/outils/rendu_iles.gd" "$COPIE/pcvr/rendu_iles.gd"
cd "$COPIE" && flock /tmp/godot77.lock timeout 5400 xvfb-run -a -s "-screen 0 1280x800x24" "$GODOT" --path pcvr \
  --rendering-method gl_compatibility --rendering-driver opengl3 --resolution 800x500 --audio-driver Dummy \
  --script res://rendu_iles.gd -- "$OUT" "$QUOI" 2>&1 | grep -E "SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR: .*\.gd|RENDU|at: |^ *[0-9]+ \\| " | grep -v "openxr\|vsync" | head -40
rm -f "$COPIE/pcvr/rendu_iles.gd"
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
