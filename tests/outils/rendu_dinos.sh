#!/bin/bash
# V217 : les animaux du Parc du Volcan en atelier (voir rendu_dinos.gd), une planche par animal.
#     bash tests/outils/rendu_dinos.sh DOSSIER [long_cou,grosse_dent,raptor,corne,plaques,grand_bec,squelette,oeuf]
# Il faut xvfb-run (un écran virtuel) : le rendu passe par OpenGL.
DEPOT="$(cd "$(dirname "$0")/../.." && pwd)"
COPIE="${TESTS_COPIE:-/root/t38}"
GODOT="${TESTS_GODOT:-$HOME/gd/godot}"
OUT="$1"
mkdir -p "$OUT"
rm -f "$OUT"/*.png "$OUT"/*.jpg
for f in pcvr/scripts/prehistoire_v217.gd pcvr/scripts/animaux_v75.gd; do
  cp "$DEPOT/$f" "$COPIE/$f"
done
cp "$DEPOT/tests/outils/rendu_dinos.gd" "$COPIE/pcvr/rendu_dinos.gd"
cd "$COPIE" && flock /tmp/godot77.lock timeout 900 xvfb-run -a -s "-screen 0 1280x800x24" "$GODOT" --path pcvr \
  --rendering-method gl_compatibility --rendering-driver opengl3 --resolution "${RENDU_RES:-640x480}" --audio-driver Dummy \
  --script res://rendu_dinos.gd -- "$OUT" "${2:-}" 2>&1 | grep -E "SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR: .*\.gd|RENDU .*:|^ *[0-9]+ \\| " | head -60
rm -f "$COPIE/pcvr/rendu_dinos.gd"
python3 - "$OUT" <<'PY'
import sys, glob, os
from PIL import Image, ImageDraw
out = sys.argv[1]
noms = sorted(set(os.path.basename(f).rsplit("_", 2)[0] if f.count("_") else f for f in glob.glob(os.path.join(out, "*.png"))))
groupes = {}
for f in sorted(glob.glob(os.path.join(out, "*.png"))):
    b = os.path.basename(f)[:-4]
    for v in ("_1_cote", "_2_trois_quarts", "_3_face", "_4_arriere"):
        if b.endswith(v):
            groupes.setdefault(b[: -len(v)], []).append(f)
for nom, fs in groupes.items():
    w, h = Image.open(fs[0]).size
    sheet = Image.new("RGB", (w * 2, h * 2))
    for i, f in enumerate(fs[:4]):
        sheet.paste(Image.open(f).convert("RGB"), ((i % 2) * w, (i // 2) * h))
    ImageDraw.Draw(sheet).text((6, 4), nom, fill=(255, 255, 255))
    p = os.path.join(out, "planche_%s.jpg" % nom)
    sheet.save(p, quality=86)
    print(p)
PY
