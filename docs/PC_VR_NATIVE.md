# Île Manga V4 — deux exécutables Windows (sans APK ni site web)

## Livraison GitHub Actions

Un seul workflow `Build Windows EXE VR et PC` produit deux artefacts :

- `Ile-Manga-VR-v4` contient un seul `Ile_Manga_VR_v4.exe`.
- `Ile-Manga-PC-v4` contient un seul `Ile_Manga_PC_v4.exe`.

Le téléchargement depuis GitHub Actions est un ZIP, mais **à l'intérieur se
trouve un EXE Windows unique**, directement utilisable après extraction.
Ces EXE embarquent les ressources du jeu (PCK Godot intégrée).

La compilation APK, le déploiement GitHub Pages et la compilation de l'ancien
lanceur Electron sont supprimés des workflows, sans supprimer les modèles
3D d'origine sous `www/assets/`, qui restent la source des ressources natives.

## Version VR : Ile_Manga_VR_v4.exe

- Connecter le Quest 3 dans **Meta Quest Link** (USB ou Air Link) ou dans
  **SteamVR** avec son runtime OpenXR actif.
- Entrer dans l'environnement Link sur le casque AVANT de lancer l'EXE VR.
- Marcher au joystick gauche : avant = avancer, arrière = reculer.
- Gauche et droite restent inchangés. Rotation par paliers au stick droit.
- OpenXR est activé dans le projet VR ; si le casque n'est pas prêt, la
  fenêtre diagnostic sur le PC permet de relancer après connexion.

Un export VR natif ne garantit pas à lui seul une apparition automatique dans
la bibliothèque Meta. Il peut être ajouté comme application inconnue ou comme
raccourci non-Steam selon les options disponibles dans ces logiciels.

## Version PC : Ile_Manga_PC_v4.exe

- Se lance normalement sur Windows, sans Quest ni runtime OpenXR.
- ZQSD / WASD / flèches pour avancer, reculer et se déplacer latéralement.
- Maintenir le clic droit et bouger la souris pour tourner la caméra.
- Échap pour fermer le jeu.
- La configuration du **deuxième export désactive explicitement OpenXR** au
  démarrage, et la scène utilise le tag d'export `ile_manga_pc` pour imposer
  la caméra PC.

## Précision sur les ressources

Les deux versions sont basées sur le même projet Godot, utilisent les mêmes
textures et modèles originaux de la V3, et sont compilées à la suite. Ce
portage continue de reprendre progressivement les fonctions de la version
historique Babylon.js ; il ne réimplémente pas encore toutes les quêtes et
interactions présentes dans les anciens fichiers web.

## Procédure après la V4

Pour les versions suivantes, seul le workflow `Build Windows EXE VR et PC`
sera maintenu. Les workflows `build-apk.yml`, `deploy-pages.yml` et
`build-pc-vr.yml` doivent être supprimés avec `git rm` lors de l'envoi de
l'archive V4. Les anciennes exécutions resteront visibles dans l'historique
GitHub Actions, mais elles ne seront plus générées.
