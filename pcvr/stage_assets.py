"""Prépare uniquement les vrais modèles déjà présents dans `www/` pour Godot.

L'archive de mise à jour reste minuscule : jamais de doublon des GLB dans Git.
Ce script s'exécute dans GitHub Actions avant import/export Godot.
"""
from __future__ import annotations

from pathlib import Path
import shutil
import sys

project = Path(__file__).resolve().parent
repo = project.parent
source = repo / "www" / "assets"
target = project / "assets"

selected = [
    "models/characters/hero.glb",
    "models/buildings/Maison.glb",
    "models/buildings/Petite_maison.glb",
    "models/buildings/Ile_flottante.glb",
]


def main() -> int:
    if not (repo / "www" / "src" / "game.js").exists():
        print("Erreur: le script attend la racine réelle du dépôt ile-manga", file=sys.stderr)
        return 1

    for rel in selected:
        path = source / rel
        if not path.is_file() or path.stat().st_size < 1_024:
            print("Asset absent ou trop petit : " + str(path), file=sys.stderr)
            return 1

    for rel in selected:
        dest = target / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source / rel, dest)
        print(f"Asset Godot: {rel} ({dest.stat().st_size // 1024 // 1024} Mo)")
    print("Modèles préparés ; les fichiers du navigateur Babylon.js restent inchangés.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
