#!/bin/bash
# Des images des bêtes sauvages (repos et attaque), et une planche qui les rassemble.
#     bash tests/outils/rendu_faune.sh DOSSIER [nuit] espèce espèce…
# Il faut xvfb-run (un écran virtuel) : le rendu passe par OpenGL.
DEPOT="$(cd "$(dirname "$0")/../.." && pwd)"
COPIE="${TESTS_COPIE:-/root/t38}"
GODOT="${TESTS_GODOT:-$HOME/gd/godot}"
OUT="$1"
shift
mkdir -p "$OUT"
rm -f "$OUT"/*.png
for f in pcvr/scripts/monstre_v132.gd pcvr/scripts/monstre_v133.gd pcvr/scripts/monstre_v135.gd pcvr/scripts/monstre_v136.gd pcvr/scripts/monstre_v137.gd pcvr/scripts/monstre_v138.gd pcvr/scripts/faune_v132.gd; do
  cp "$DEPOT/$f" "$COPIE/$f"
done
cp "$DEPOT/tests/outils/rendu_faune.gd" "$COPIE/pcvr/rendu_faune.gd"
cd "$COPIE" && flock /tmp/godot77.lock timeout 600 xvfb-run -a -s "-screen 0 1280x800x24" "$GODOT" --path pcvr \
  --rendering-method gl_compatibility --rendering-driver opengl3 --resolution 480x320 --audio-driver Dummy \
  --script res://rendu_faune.gd -- "$OUT" "$@" 2>&1 | grep -E "SCRIPT ERROR|Parse Error|ERROR: .*\.gd" | head -20
rm -f "$COPIE/pcvr/rendu_faune.gd"
python3 - "$OUT" <<'EOF'
import sys, glob, os
from PIL import Image, ImageDraw
out = sys.argv[1]
files = sorted(glob.glob(os.path.join(out, "*_repos.png")))
if not files:
    sys.exit(0)
w, h = Image.open(files[0]).size
sheet = Image.new("RGB", (w * 2, h * len(files)), (0, 0, 0))
for i, f in enumerate(files):
    for j, suf in enumerate(["_repos.png", "_attaque.png"]):
        p = f.replace("_repos.png", suf)
        if os.path.exists(p):
            sheet.paste(Image.open(p).convert("RGB"), (j * w, i * h))
    ImageDraw.Draw(sheet).text((6, i * h + 4), os.path.basename(f).replace("_repos.png", ""), fill=(255, 255, 255))
sheet.save(os.path.join(out, "planche.jpg"), quality=88)
print(os.path.join(out, "planche.jpg"))
EOF
