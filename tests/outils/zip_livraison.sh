#!/bin/bash
# Le zip de livraison : les fichiers changés par rapport à origin/main, rangés dans le dossier
# ile_manga_pcvr/ (le dossier du projet sur le téléphone), dans /home/claude/ile_manga_pcvr_vN.zip.
#     bash tests/outils/zip_livraison.sh N
set -e
N="$1"
test -n "$N"
DEPOT="$(cd "$(dirname "$0")/../.." && pwd)"
SORTIE="/home/claude/ile_manga_pcvr_v$N.zip"
cd "$DEPOT"
TMP="$(mktemp -d)"
mkdir "$TMP/ile_manga_pcvr"
n=0
for f in $( (git diff --name-only origin/main; git ls-files -o --exclude-standard) | sort -u ); do
  if [ -f "$f" ]; then
    mkdir -p "$TMP/ile_manga_pcvr/$(dirname "$f")"
    cp "$f" "$TMP/ile_manga_pcvr/$f"
    n=$((n+1))
  fi
done
rm -f "$SORTIE"
(cd "$TMP" && zip -qr "$SORTIE" ile_manga_pcvr)
rm -rf "$TMP"
echo "$n fichier(s) dans $SORTIE"
