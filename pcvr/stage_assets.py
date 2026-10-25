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
    "textures/ui/les_mondes_de_travers_logo.png",
    "textures/ui/les_mondes_de_travers_icon.png",
    "textures/ui/les_mondes_de_travers_icon.ico",
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
    # V55 : la mer, la vie sous-marine, l'Atlantide
    "textures/mer/sable_fond.png",
    "textures/mer/sable_fond_n.png",
    "textures/mer/roche_recif.png",
    "textures/mer/roche_recif_n.png",
    "textures/mer/caustiques.png",
    "textures/mer/algue.png",
    "textures/mer/herbier.png",
    "textures/mer/poissons.png",
    "textures/mer/bulle.png",
    "textures/mer/carapace.png",
    "textures/mer/epave_bois.png",
    "textures/mer/epave_bois_n.png",
    "textures/atlantide/marbre.png",
    "textures/atlantide/marbre_n.png",
    "textures/atlantide/mosaique.png",
    "textures/atlantide/mosaique_n.png",
    "textures/atlantide/cuivre_vert.png",
    "textures/atlantide/cuivre_vert_n.png",
    "textures/atlantide/frise.png",
    "textures/atlantide/fresque.png",
    "textures/pnj/atlante_turquoise.png",
    "textures/pnj/atlante_nacre.png",
    "textures/pnj/atlante_corail.png",
    "textures/pnj/atlante_abysse.png",
    "textures/items/masque_plongee.png",
    "textures/items/perle_lumiere.png",
    "textures/items/trident_marees.png",
    "textures/items/palmes_atlante.png",
    "textures/items/dent_requin.png",
    "textures/items/galette_algue.png",
]


IMPORT_V64 = """[remap]

importer="texture"
type="CompressedTexture2D"

[params]

compress/mode=2
compress/high_quality={hq}
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map={nm}
compress/channel_pack=0
mipmaps/generate=true
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=0
"""


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
    # V56 : Port-Azur (textures de la ville), la carte, les portraits, toutes les icônes d'objets
    # V58 : le royaume des fées et Yggdrasil (textures/fees)
    # V63 : la grande enquête et le donjon du Cœur-de-Pierre (textures/coeur)
    n56 = 0
    for folder in ("textures/azur", "textures/carte", "textures/portraits", "textures/items", "textures/fees", "textures/carene", "textures/tazira", "textures/cliquetis", "textures/ramure", "textures/coeur"):
        d = source / folder
        if not d.is_dir():
            continue
        for f in sorted(list(d.glob("*.png")) + list(d.glob("*.jpg"))):
            dest = target / f.relative_to(source)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, dest)
            n56 += 1
    print(f"Textures V56: {n56} fichiers")
    # V64 : les vrais corps des habitants (formes, cheveux, vêtements) et leurs textures ;
    # les textures sont importées compressées avec mipmaps (sinon moirés et scintillement).
    n64 = 0
    corps = source / "models" / "pnj64"
    if corps.is_dir():
        for f in sorted(corps.rglob("*.bin")):
            dest = target / f.relative_to(source)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, dest)
            n64 += 1
    tex64 = source / "textures" / "pnj64"
    if tex64.is_dir():
        for f in sorted(tex64.glob("*.png")):
            dest = target / f.relative_to(source)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, dest)
            normal = f.name.endswith("_n.png")
            hq = f.name.startswith(("yeux", "peau_masques"))
            imp = dest.with_name(dest.name + ".import")
            if not imp.is_file() or "mipmaps/generate=true" not in imp.read_text():
                imp.write_text(IMPORT_V64.format(nm=1 if normal else 2, hq="true" if hq else "false"))
            n64 += 1
    print(f"Habitants V64: {n64} fichiers")
    # V66 : les objets qu'on casse et les coffres (bois, osier, terre cuite, fer) : importés
    # compressés avec mipmaps, comme les habitants (vus de près en VR, et de loin sans moiré).
    n66 = 0
    tex66 = source / "textures" / "objets"
    if tex66.is_dir():
        for f in sorted(tex66.glob("*.png")):
            dest = target / f.relative_to(source)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, dest)
            imp = dest.with_name(dest.name + ".import")
            if not imp.is_file() or "mipmaps/generate=true" not in imp.read_text():
                imp.write_text(IMPORT_V64.format(nm=1 if f.name.endswith("_n.png") else 2, hq="false"))
            n66 += 1
    print(f"Objets V66: {n66} fichiers")
    # V67 : Arcanelle, l'île des sorciers (sols, murs, toits, vitraux, runes) : importés
    # compressés avec mipmaps, comme les objets V66.
    # Les sols (le shader du terrain lit le bleu des cartes de reliefs) : sans perte.
    n67 = 0
    tex67 = source / "textures" / "arcanelle"
    sols67 = {"galets", "tourbe", "lande", "bruyere", "schiste"}
    if tex67.is_dir():
        for f in sorted(tex67.glob("*.png")):
            dest = target / f.relative_to(source)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, dest)
            imp = dest.with_name(dest.name + ".import")
            old = imp.read_text() if imp.is_file() else ""
            if f.stem.removesuffix("_n") in sols67:
                if "compress/mode=0" not in old or "compress/normal_map=0" not in old or "mipmaps/generate=true" not in old:
                    imp.write_text(IMPORT_V64.replace("compress/mode=2", "compress/mode=0").format(nm=0, hq="false"))
            elif "mipmaps/generate=true" not in old:
                imp.write_text(IMPORT_V64.format(nm=1 if f.name.endswith("_n.png") else 2, hq="false"))
            n67 += 1
    print(f"Arcanelle V67: {n67} fichiers")
    # V68 : l'Île de la Balafre, l'île des pirates (sols, bois, toiles, voiles, pavillons,
    # enseignes) : même règle que pour Arcanelle (les sols sans perte).
    n68 = 0
    tex68 = source / "textures" / "pirates"
    sols68 = {"sable", "terre", "sousbois", "basalte", "vase"}
    if tex68.is_dir():
        for f in sorted(tex68.glob("*.png")):
            dest = target / f.relative_to(source)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, dest)
            imp = dest.with_name(dest.name + ".import")
            old = imp.read_text() if imp.is_file() else ""
            if f.stem.removesuffix("_n") in sols68:
                if "compress/mode=0" not in old or "compress/normal_map=0" not in old or "mipmaps/generate=true" not in old:
                    imp.write_text(IMPORT_V64.replace("compress/mode=2", "compress/mode=0").format(nm=0, hq="false"))
            elif "mipmaps/generate=true" not in old:
                imp.write_text(IMPORT_V64.format(nm=1 if f.name.endswith("_n.png") else 2, hq="false"))
            n68 += 1
    print(f"Balafre V68: {n68} fichiers")
    # V69 : l'Île des Trois Soleils (sols, pierres, enduits, fresques, symboles des énigmes) :
    # même règle (les sols sans perte ; les fresques et les symboles, des images nettes).
    n69 = 0
    tex69 = source / "textures" / "soleils"
    sols69 = {"herbe", "jungle", "sable", "limon", "roche", "dalles_soleil"}
    if tex69.is_dir():
        for f in sorted(tex69.glob("*.png")):
            dest = target / f.relative_to(source)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, dest)
            imp = dest.with_name(dest.name + ".import")
            old = imp.read_text() if imp.is_file() else ""
            if f.stem.removesuffix("_n") in sols69:
                if "compress/mode=0" not in old or "compress/normal_map=0" not in old or "mipmaps/generate=true" not in old:
                    imp.write_text(IMPORT_V64.replace("compress/mode=2", "compress/mode=0").format(nm=0, hq="false"))
            elif "mipmaps/generate=true" not in old:
                imp.write_text(IMPORT_V64.format(nm=1 if f.name.endswith("_n.png") else 2, hq="false"))
            n69 += 1
    print(f"Trois Soleils V69: {n69} fichiers")
    # V70 : l'Île de Braise et Pandémonia, la cité des démons (sols volcaniques, pierres gothiques,
    # vitraux, fresques des Neuf Cercles, enseignes) : même règle (les sols sans perte).
    n70 = 0
    tex70 = source / "textures" / "braise"
    sols70 = {"mousse_braise", "cendre", "sable_noir", "basalte", "roche_volcan", "paves_basalte", "lave_croute", "soufre"}
    if tex70.is_dir():
        for f in sorted(tex70.glob("*.png")):
            dest = target / f.relative_to(source)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, dest)
            imp = dest.with_name(dest.name + ".import")
            old = imp.read_text() if imp.is_file() else ""
            if f.stem.removesuffix("_n") in sols70:
                if "compress/mode=0" not in old or "compress/normal_map=0" not in old or "mipmaps/generate=true" not in old:
                    imp.write_text(IMPORT_V64.replace("compress/mode=2", "compress/mode=0").format(nm=0, hq="false"))
            elif "mipmaps/generate=true" not in old:
                imp.write_text(IMPORT_V64.format(nm=1 if f.name.endswith("_n.png") else 2, hq="false"))
            n70 += 1
    print(f"Braise V70: {n70} fichiers")
    # V71 : l'Île de Montjoie (sols de campagne, pavés, crépis, colombages, tuiles, enseignes,
    # affiches, pierres du donjon) : même règle (les sols sans perte).
    n71 = 0
    tex71 = source / "textures" / "montjoie"
    sols71 = {"prairie", "champ", "chemin", "sous_bois", "roche_crocs", "sable_lac", "paves", "dalles"}
    if tex71.is_dir():
        for f in sorted(tex71.glob("*.png")):
            dest = target / f.relative_to(source)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, dest)
            imp = dest.with_name(dest.name + ".import")
            old = imp.read_text() if imp.is_file() else ""
            if f.stem.removesuffix("_n") in sols71:
                if "compress/mode=0" not in old or "compress/normal_map=0" not in old or "mipmaps/generate=true" not in old:
                    imp.write_text(IMPORT_V64.replace("compress/mode=2", "compress/mode=0").format(nm=0, hq="false"))
            elif "mipmaps/generate=true" not in old:
                imp.write_text(IMPORT_V64.format(nm=1 if f.name.endswith("_n.png") else 2, hq="false"))
            n71 += 1
    print(f"Montjoie V71: {n71} fichiers")
    # V56 : les polices du carnet (Lora, et DejaVu Sans pour les symboles ★ ⚓ ♥ ✓)
    fonts = source / "fonts"
    if fonts.is_dir():
        for f in sorted(fonts.iterdir()):
            if f.suffix in (".ttf", ".otf", ".txt"):
                dest = target / "fonts" / f.name
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(f, dest)
    print("Modèles et textures préparés pour Godot.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
