# Habitants V64 — générateur des corps, visages, coiffures et vêtements

Tous les habitants (sauf le héros) ont un corps à eux, construit hors du jeu à partir de
MakeHuman 1.x et MPFB2 (données sous licence CC0), puis assemblé dans le jeu par
`scripts/pnj/corps_v64.gd`.

## Préparation

1. Données MakeHuman / MPFB2 : variables `MAKEHUMAN_DATA` (dossier `makehuman/data`) et
   `MPFB_DATA` (dossier `src/mpfb/data`).
2. Fiches des habitants et squelette du héros (écrits dans `V64_CACHE`, par défaut
   `~/.cache/ile_manga_v64`) :

        godot --headless --path pcvr -s res://tools/habitants_v64/extraire_fiches.gd
        godot --headless --path pcvr -s res://tools/habitants_v64/extraire_squelette.gd

3. Python 3 avec numpy, scipy et Pillow.

## Génération

    python3 pcvr/tools/habitants_v64/generer.py tout
    python3 pcvr/tools/habitants_v64/generer.py corps leon,odette

Étapes : `ao` (occlusion du corps neutre), `peau` (teint, masques, grain, rides),
`yeux` (iris, cils, atlas des mèches), `tissus` (trames, coutures, plis), `cheveux`
(coiffures et barbes en mèches), `habits` (coques ajustées au corps), `amples` (jupes,
tabliers, capes…), `chapeaux`, `corps` (un fichier par habitant : forme, squelette,
visage, teint, coiffure, tenue).

Sorties : `www/assets/models/pnj64/*.bin` et `www/assets/textures/pnj64/*.png`
(copiées dans `pcvr/assets` par `stage_assets.py`, avec leurs fichiers `.import`).

## Modules

| module | rôle |
|---|---|
| `mh.py` | maillage de base, cibles, macros, rig mixamo |
| `rig.py` | ajustement sur le squelette du héros, poids de peau |
| `export.py` | base partagée (topologie, UV, poids, expressions) et corps par habitant |
| `appearance.py` | décisions d'apparence par habitant (graine = identifiant) |
| `skin_tex.py`, `eye_tex.py`, `hair_tex.py`, `cloth_tex.py` | textures |
| `hair.py`, `hair_styles.py`, `proxy.py`, `proxy_export.py` | mèches et accrochage au corps |
| `clothes.py`, `loose.py`, `hats.py` | vêtements ajustés, amples, chapeaux |
| `maps.py`, `uvraster.py`, `landmarks.py` | cartes dans l'espace UV, repères du visage |
| `gdvar.py` | encodage binaire des Variant de Godot |
