# Île Manga V5 — Qualité graphique PC et VR Quest 3

## Version V5 — Deux EXE uniquement

Depuis **Actions > Build Windows EXE VR et PC** :

- Artefact `Ile-Manga-VR-v5` → `Ile_Manga_VR_v5.exe` ; OpenXR natif Quest 3 via Meta Link / SteamVR.
- Artefact `Ile-Manga-PC-v5` → `Ile_Manga_PC_v5.exe` ; Windows normal sans casque.

GitHub Actions emballe chaque EXE dans un ZIP d'artefact. Extraire le ZIP pour récupérer le fichier EXE.
Aucun workflow APK, site web ou Electron n'est requis. Le dépôt conserve `www/assets` comme bibliothèque de modèles et textures pour le build Godot.

## Graphismes V5

- Sol : véritable mélange de sable, herbe, pierre par hauteur, pente, bruit spatial, avec détails secondaires PC.
- Océan : géométrie ondulée et surface animée ; mousse côtière stylisée opaque.
- Végétation : brins d'herbe MultiMesh (2700 PC, 850 VR) avec distance d'affichage adaptée.
- Éclairage : ambiance, ombres en cascades avec réglages PC/VR, brume très douce.
- **PC** : MSAA 4x, SSAO, SSIL, glow discret, retouche colorimétrique. Rendu en résolution native du moniteur.
- **VR** : MSAA 2x, ombres moins coûteuses, sans post-traitement d'écran coûteux. Résolution contrôlée par Quest Link / SteamVR ; aucun réglage artificiel de suréchantillonnage dans le jeu.

Les détails sont plus riches, mais ces changements ne convertissent pas encore toutes les quêtes, tous les intérieurs et tous les modèles de la version Babylon.js. La VR doit être testée sur casque.

## Commandes PC normal

- ZQSD / WASD : marche ; clic droit + souris : caméra ; Échap : quitter.
- **F11** : plein écran exclusif / fenêtre.
- **F6** : netteté ultra : suréchantillonnage 120 % (très exigeant en 4K). Nouvelle pression : 100 %.
- La résolution réelle dépend du moniteur. Un EXE ne rend pas automatiquement le PC en 4K si l'écran est en 1080p.

## Commandes VR

- Entrer dans Meta Quest Link ou SteamVR **avant** de lancer `Ile_Manga_VR_v5.exe`.
- Stick gauche : avant pour avancer, arrière pour reculer ; gauche et droite conservés.
- Stick droit : rotation par paliers.
- La fréquence VR (72/80/90/120 Hz selon configuration) et la résolution de rendu sont définies dans le logiciel PC Meta / SteamVR ; privilégier la fluidité et le confort.
- Si le casque n'est pas connecté, l'exécutable VR affiche le diagnostic, puis il peut être relancé après connexion.

## Vérification et limites

GitHub Actions importe les ressources, vérifie les scripts et génère **exactement deux EXE**. Un workflow vert ne prouve pas le rendu final ni les performances dans le casque. Tester d'abord le chargement, l'océan, les arbres et les déplacements. Les effets PC SSAO/SSIL et la végétation peuvent impacter les FPS, notamment en 4K.
