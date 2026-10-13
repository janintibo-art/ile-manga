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
    "models/props/Feu.glb",
    "models/props/Mur_de_son.glb",
    "models/props/Table_de_mixage.glb",
    "models/props/Distributeur_8_6.glb",
    "models/props/Corde.glb",
    "textures/terrain/grass.jpg",
    "textures/terrain/sand.jpg",
    "textures/terrain/stone.jpg",
    "textures/water/water.jpg",
    "textures/terrain/grass_n.png",
    "textures/terrain/sand_n.png",
    "textures/terrain/stone_n.png",
    "textures/water/water_n.png",
    "textures/flora/leaves.png",
    "textures/flora/leaves_n.png",
    "textures/flora/bark.png",
    "textures/flora/bark_n.png",
    "textures/flora/flowers.png",
    "textures/flora/fern.png",
    "textures/terrain/rock.jpg",
    "textures/terrain/rock_n.png",
    "textures/doors/door_wood.png",
    "textures/doors/door_wood_n.png",
    "textures/doors/wood_plain.png",
    "textures/doors/plaster.png",
    "textures/doors/plaster_n.png",
    "textures/interior/floor.png",
    "textures/jungle/jungle_soil.png",
    "textures/jungle/jungle_soil_n.png",
    "textures/jungle/jungle_moss.png",
    "textures/jungle/jungle_moss_n.png",
    "textures/jungle/jungle_rock.png",
    "textures/jungle/jungle_rock_n.png",
    "textures/items/pomme.png",
    "textures/items/champignon.png",
    "textures/items/baies.png",
    "textures/items/baton.png",
    "textures/items/caillou.png",
    "textures/items/coquillage.png",
    "textures/items/piece.png",
    "textures/items/epee_bois.png",
    "textures/items/coeur_plein.png",
    "textures/items/coeur_moitie.png",
    "textures/items/coeur_vide.png",
    "textures/interior/ceiling.png",
]


def main() -> int:
    if not (repo / "pcvr" / "project.godot").exists() or not source.is_dir():
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
    print("Modèles et textures préparés pour Godot.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
