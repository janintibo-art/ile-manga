# Île Manga — PC classique et Quest 3 PC VR

Projet Godot 4.7.2 de jeu 3D sur une île manga. Les deux versions Windows
sont produites ensemble par GitHub Actions :

- **Île Manga VR** : `Ile_Manga_VR_v4.exe`, pour Quest 3 via Meta Quest Link
  (USB / Air Link) ou SteamVR et OpenXR.
- **Île Manga PC** : `Ile_Manga_PC_v4.exe`, pour jouer sur un PC Windows sans VR.

Les contrôles avant / arrière du joystick gauche Quest ont été corrigés en V4.

## Télécharger

Ouvrir **Actions > Build Windows EXE VR et PC > dernier run réussi** et
récupérer `Ile-Manga-VR-v4` et/ou `Ile-Manga-PC-v4` sous **Artifacts**.
Extraire le ZIP GitHub pour obtenir l'exécutable correspondant.

## Organisation

- `pcvr/` : jeu Godot PC / VR, shaders, scènes, contrôles, scripts d'export.
- `www/assets/` : modèles et textures d'origine réutilisés lors du build.
- `www/` et `desktop/` : anciens prototypes conservés pour récupérer leur
  contenu ; ils ne sont plus compilés ni déployés automatiquement.
- `.github/workflows/build-pcvr-native.yml` : unique workflow actif.

La compilation APK, la publication web et le lanceur Electron ne sont plus
utilisés. Voir [docs/PC_VR_NATIVE.md](docs/PC_VR_NATIVE.md) pour le détail.
