#!/bin/bash
# Des images de la roue de la main droite (V220 : la roue des armes, la grande roue, la roue des pouvoirs), et une planche.
#     bash tests/outils/rendu_roue_armes.sh DOSSIER
# Il faut xvfb-run (un écran virtuel) : le rendu passe par OpenGL.
# SOURCE : le dossier où prendre roue_armes_v220.gd et cet outil (par défaut : le dépôt).
# TAILLE : la taille des images (par défaut 960x600).
ICI="$(cd "$(dirname "$0")/../.." && pwd)"
SOURCE="${SOURCE:-$ICI}"
COPIE="${TESTS_COPIE:-/root/t38}"
GODOT="${TESTS_GODOT:-$HOME/gd/godot}"
OUT="$1"
TAILLE="${TAILLE:-960x600}"
mkdir -p "$OUT"
rm -f "$OUT"/*.png
cp "$SOURCE/pcvr/scripts/roue_armes_v220.gd" "$COPIE/pcvr/scripts/roue_armes_v220.gd"
cp "$SOURCE/tests/outils/rendu_roue_armes.gd" "$COPIE/pcvr/rendu_roue_armes.gd"
cd "$COPIE" && flock /tmp/godot77.lock timeout "${DELAI:-600}" xvfb-run -a -s "-screen 0 ${TAILLE}x24" "$GODOT" --path pcvr \
  --rendering-method gl_compatibility --rendering-driver opengl3 --resolution "$TAILLE" --audio-driver Dummy \
  --script res://rendu_roue_armes.gd -- "$OUT" > "$OUT/journal.txt" 2>&1
grep -E "SCRIPT ERROR|Parse Error|ERROR: .*\.gd" "$OUT/journal.txt" | head -20
rm -f "$COPIE/pcvr/rendu_roue_armes.gd"
python3 - "$OUT" <<'PY'
import sys, glob, os
from PIL import Image, ImageDraw
out = sys.argv[1]
files = sorted(glob.glob(os.path.join(out, "*.png")))
if not files:
    print("aucune image")
    sys.exit(0)
w, h = Image.open(files[0]).size
sheet = Image.new("RGB", (w * len(files), h), (0, 0, 0))
for i, f in enumerate(files):
    sheet.paste(Image.open(f).convert("RGB"), (i * w, 0))
    ImageDraw.Draw(sheet).text((i * w + 6, 4), os.path.basename(f)[:-4], fill=(255, 255, 255))
sheet.save(os.path.join(out, "planche.jpg"), quality=90)
print(os.path.join(out, "planche.jpg"))
PY
