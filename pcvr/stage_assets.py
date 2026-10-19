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
    "textures/pnj/habitant_sobre.png",
    "textures/ui/ile_manga_logo.png",
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
    "textures/jungle/palm_frond.png",
    "textures/jungle/broadleaf.png",
    "textures/jungle/canopy_leaves.png",
    "textures/jungle/canopy_leaves_n.png",
    "textures/jungle/palm_trunk.png",
    "textures/jungle/thatch.png",
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
    "textures/items/boussole.png",
    "textures/items/canne_peche.png",
    "textures/items/sardine.png",
    "textures/items/maquereau.png",
    "textures/items/dorade.png",
    "textures/items/bar.png",
    "textures/items/poisson_perroquet.png",
    "textures/items/merou.png",
    "textures/items/poisson_lune.png",
    "textures/items/vieille_botte.png",
    "textures/items/pelle.png",
    "textures/items/hache.png",
    "textures/items/epee.png",
    "textures/items/buche.png",
    "textures/items/noix_coco.png",
    "textures/items/miel.png",
    "textures/items/perle.png",
    "textures/items/bague.png",
    "textures/items/rubis.png",
    "textures/items/piece_or.png",
    "textures/items/fragment_amulette.png",
    "textures/items/amulette_serpent.png",
    "textures/items/ecaille_naga.png",
    "textures/items/fiole_vide.png",
    "textures/items/eau_source.png",
    "textures/items/fleur_lune.png",
    "textures/items/graine_or.png",
    "textures/items/boussole_elfique.png",
    "textures/elfes/elfe_lyra.png",
    "textures/elfes/elfe_azur.png",
    "textures/elfes/elfe_pourpre.png",
    "textures/elfes/elfe_ivoire.png",
    "textures/elfes/elfe_crepuscule.png",
    "textures/items/potion_seve.png",
    "textures/items/tisane_lune.png",
    "textures/items/pain_miel.png",
    "textures/items/lanterne_fee.png",
    "textures/items/poussiere_fee.png",
    "textures/items/goutte_rosee.png",
    "textures/items/baguette_fee.png",
    "textures/items/eclat_cristal.png",
    "textures/items/nectar_fee.png",
    "textures/items/carte_naine.png",
    "textures/volcan/sable_noir.png",
    "textures/volcan/cendre.png",
    "textures/volcan/herbe_brulee.png",
    "textures/volcan/basalte.png",
    "textures/items/minerai_fer.png",
    "textures/items/obsidienne.png",
    "textures/items/champignon_braise.png",
    "textures/items/plume_corbeau.png",
    "textures/items/coeur_magma.png",
    "textures/items/rune_golem.png",
    "textures/items/epee_naine.png",
    "textures/items/ragout_nain.png",
    "textures/items/fromage_chevre.png",
    "textures/items/biere_naine.png",
    "textures/nains/nain_braise.png",
    "textures/nains/nain_suie.png",
    "textures/nains/nain_mousse.png",
    "textures/nains/nain_royal.png",
    "textures/temple/temple_wall.png",
    "textures/temple/temple_wall_n.png",
    "textures/temple/temple_floor.png",
    "textures/temple/temple_floor_n.png",
    "textures/temple/glyph_lune.png",
    "textures/temple/glyph_vague.png",
    "textures/temple/glyph_soleil.png",
    "textures/temple/glyph_serpent.png",
    "textures/temple/fresque.png",
    "textures/items/epee_bois.png",
    "textures/items/coeur_plein.png",
    "textures/items/coeur_moitie.png",
    "textures/items/coeur_vide.png",
    "textures/interior/ceiling.png",
    # V54 : Ventaile, l'île flottante, la Citadelle des Nuées
    "textures/aigle/plumage.png",
    "textures/aigle/plumage_n.png",
    "textures/aigle/tete.png",
    "textures/aigle/remige.png",
    "textures/aigle/couverture.png",
    "textures/aigle/rectrice.png",
    "textures/chateau/pierre_chateau.png",
    "textures/chateau/pierre_chateau_n.png",
    "textures/chateau/dalles_chateau.png",
    "textures/chateau/dalles_chateau_n.png",
    "textures/chateau/ardoise.png",
    "textures/chateau/ardoise_n.png",
    "textures/chateau/banniere.png",
    "textures/chateau/vitrail.png",
    "textures/chateau/tapis.png",
    "textures/ciel/nuage.png",
    "textures/ciel/roche_ciel.png",
    "textures/ciel/roche_ciel_n.png",
    "textures/items/plume_ventaile.png",
    "textures/items/cristal_levant.png",
    "textures/items/cristal_couchant.png",
    "textures/items/couronne_nuees.png",
    "textures/items/epee_nuees.png",
    "textures/items/selle_aigle.png",
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
    # V49 : tous les sons (ambiances, émetteurs, sons ponctuels)
    sons = source / "sons"
    if sons.is_dir():
        for f in sorted(sons.rglob("*.ogg")):
            rel = f.relative_to(source)
            dest = target / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, dest)
        print(f"Sons Godot: {len(list(sons.rglob('*.ogg')))} fichiers")
    print("Modèles et textures préparés pour Godot.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
