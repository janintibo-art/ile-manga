# Île Manga — Windows PC + Quest 3

Jeu d'exploration d'une île manga, fait avec **Godot 4.7.2**. GitHub Actions compile **deux jeux Windows** :

- `Ile_Manga_VR_vN.exe` : Quest 3 via Meta Quest Link ou SteamVR, en OpenXR natif.
- `Ile_Manga_PC_vN.exe` : écran Windows normal, clavier et souris, sans casque.

## Télécharger

**Actions > Build Windows EXE VR et PC > dernière exécution verte > Artifacts.**
Chaque artefact est un ZIP contenant un EXE.

## Commandes

**PC** : ZQSD (ou WASD / flèches) pour marcher, clic droit maintenu pour tourner la caméra,
Échap ou F9 pour le menu, F5 pour sauvegarder, F11 pour le plein écran, F6 pour la netteté ultra.

**VR** : joystick gauche pour marcher, joystick droit pour tourner par crans,
bouton ≡ de la manette gauche pour le menu. Dans le menu : joystick droit pour choisir, gâchette droite pour valider.

## Sauvegardes

Six emplacements plus une sauvegarde automatique toutes les 90 secondes, communs aux deux EXE.
Le menu permet de sauvegarder et de charger une autre partie à tout moment.

## Organisation

- `pcvr/` : le projet Godot (scène, scripts, shaders, préréglages d'export).
- `pcvr/scripts/main.gd` : construction du monde, joueurs, physique, sauvegardes.
- `pcvr/scripts/*_vNN.gd` : chaque série de décors ajoutée par version.
- `www/assets/` : source unique des modèles GLB et des textures, copiés dans Godot par `pcvr/stage_assets.py` au moment de la compilation.
- `.github/workflows/build-pcvr-native.yml` : contrôles et export des deux EXE.

## Nouvelle version

Le numéro de version se change **à un seul endroit** : `config/name` dans `pcvr/project.godot`
(par exemple `"Ile Manga VR V23"`). Le workflow en déduit le nom des EXE, des artefacts
et les numéros de version Windows.

Guide détaillé (Quest Link, SteamVR, dépannage) : [docs/PC_VR_NATIVE.md](docs/PC_VR_NATIVE.md).
