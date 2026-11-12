#!/bin/bash
# Vérifie la syntaxe de scripts du jeu (et de ce qu'ils chargent), dans la copie de travail.
#     bash tests/outils/analyser.sh pcvr/scripts/monstre_v135.gd pcvr/scripts/faune_v132.gd
# (les fichiers du dépôt sont d'abord recopiés dans la copie de travail)
DEPOT="$(cd "$(dirname "$0")/../.." && pwd)"
COPIE="${TESTS_COPIE:-/root/t38}"
GODOT="${TESTS_GODOT:-$HOME/gd/godot}"
args=()
for f in "$@"; do
  mkdir -p "$COPIE/$(dirname "$f")"
  cp "$DEPOT/$f" "$COPIE/$f"
  args+=("res://${f#pcvr/}")
done
cp "$DEPOT/tests/outils/analyser_scripts.gd" "$COPIE/pcvr/analyser_scripts.gd"
cd "$COPIE" && flock /tmp/godot77.lock timeout 300 "$GODOT" --headless --path pcvr --script res://analyser_scripts.gd -- "${args[@]}" 2>&1 \
  | grep -E "^(OK|ÉCHEC|ANALYSE)|Parse Error|SCRIPT ERROR|ERROR: .*\.gd" | grep -v "^ERROR: .*autoload" | head -40
rm -f "$COPIE/pcvr/analyser_scripts.gd"
