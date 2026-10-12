# Île Manga — Windows PC + Quest 3 (V5)

Le projet Godot 4.7.2 `pcvr/` conserve le monde manga et exporte exclusivement **deux jeux Windows** :

- `Ile_Manga_VR_v5.exe` pour Quest 3 via Meta Quest Link / SteamVR, en OpenXR natif.
- `Ile_Manga_PC_v5.exe` pour écran Windows normal, clavier et souris, sans casque.

## Télécharger

**GitHub Actions > Build Windows EXE VR et PC > dernière exécution verte > Artifacts**.
Chaque artefact est un ZIP contenant un EXE : `Ile-Manga-VR-v5` et `Ile-Manga-PC-v5`.

## V5 : détails visuels

Shader terrain multifréquence, sable/herbe/roche, océan animé avec mousse côtière, herbes instanciées, ombres et traitement de l'image adaptés PC ou VR. PC : F11 pour plein écran ; F6 pour netteté ultra (1,2× de chaque dimension de rendu, selon viewport), Échap pour quitter. En VR, Quest Link/SteamVR gère la résolution stéréoscopique.

Aucun APK ni site web n'est compilé. Les anciens fichiers sous `www/` servent de source aux modèles GLB et textures natifs : ils sont conservés, mais ne sont pas déployés.

Guide détaillé : [docs/PC_VR_NATIVE.md](docs/PC_VR_NATIVE.md).
