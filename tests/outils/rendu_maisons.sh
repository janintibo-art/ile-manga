#!/bin/bash
# Des images des sols de l'île (V158 : avant / après) et des pièces des maisons, et des planches.
#     bash tests/outils/rendu_maisons.sh DOSSIER [sols|maisons|sud|boutiques [début du nom]]
# (V169 : « sud » : les maisons d'Al Dente, de l'Île Crayonnée et de Sombreval, chacune de deux ou trois points de vue)
# (V170 : « boutiques » : les boutiques et les bâtiments publics, « ville_id » ; « nuit » : tout, le soir)
# (V171 : « boutiques » montre aussi les temples, les palais, les tours : « egypte », « maya », « azteque »,
#  « arcanelle », « pirate » ; V172 : « tazira », « ramure », « boucan » ; V173 : « citadelle »,
#  « montjoie_phare », « montjoie_moulin », « montjoie_grange », « astralys », « sombreval » ; V174 : « geants »,
#  et « geants:nuit » pour une partie seulement, le soir ; V175 : « neo » (l'Arcade du Dragon-Pixel), « larsen »
#  (les bus peints))
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
# les sols d'avant (terrain/origine), pour comparer
mkdir -p "$COPIE/pcvr/assets/textures/terrain_avant"
for f in "$DEPOT"/www/assets/textures/terrain/origine/*; do
  cmp -s "$f" "$COPIE/pcvr/assets/textures/terrain_avant/$(basename "$f")" || cp "$f" "$COPIE/pcvr/assets/textures/terrain_avant/"
done
(cd "$COPIE" && python3 pcvr/stage_assets.py > /dev/null)
(cd "$COPIE" && flock /tmp/godot77.lock timeout 1800 "$GODOT" --headless --path pcvr --import > /dev/null 2>&1)
cp "$DEPOT/tests/outils/rendu_maisons.gd" "$COPIE/pcvr/rendu_maisons.gd"
cd "$COPIE" && flock /tmp/godot77.lock timeout 1800 xvfb-run -a -s "-screen 0 1280x800x24" "$GODOT" --path pcvr \
  --rendering-method gl_compatibility --rendering-driver opengl3 --resolution 960x600 --audio-driver Dummy \
  --script res://rendu_maisons.gd -- "$OUT" "${2:-}" "${3:-}" 2>&1 | grep -E "SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR: .*\.gd|ERROR: .*shader|RENDU|at: |^ *[0-9]+ \\| " | head -400
rm -f "$COPIE/pcvr/rendu_maisons.gd"
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
