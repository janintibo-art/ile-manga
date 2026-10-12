# Île Manga — Windows PC et Meta Quest 3 (PC VR)

## Ce que construit GitHub

Le workflow **Build PC VR Windows EXE** produit un exécutable portable Windows x64
qui se trouve dans l'artefact **ile-manga-pc-vr-windows-exe** de GitHub Actions.
Le workflow APK Android existant est conservé.

Le moteur et les ressources Babylon.js sont copiés en local dans l'exécutable :
pas de CDN requis pour les éléments du jeu qui sont déjà dans le dépôt.
Le programme démarre un serveur HTTP local sur `127.0.0.1` et un port libre.
Ce serveur n'est pas accessible sur le réseau local et doit rester ouvert pour WebXR.

## Lancer le jeu sur PC

1. Sur GitHub, aller dans **Actions > Build PC VR Windows EXE > dernier run réussi**.
2. Télécharger l'artefact **ile-manga-pc-vr-windows-exe**.
3. Décompresser l'archive téléchargée depuis GitHub Actions.
4. Sur le PC Windows 64 bits, lancer **Ile-Manga-PC-VR-v0.2.0-x64.exe**.
   Le programme n'étant pas signé, SmartScreen peut demander une confirmation.
   N'autoriser le fichier que s'il provient bien de ton dépôt GitHub.
5. Le jeu s'affiche normalement à l'écran (clavier et souris).

## Mode Quest 3 en PC VR

1. Installer l'application **Meta Quest Link** sur Windows et connecter le Quest 3
   via câble USB **Quest Link** ou **Air Link**.
2. Vérifier qu'un runtime **OpenXR** compatible est actif sur le PC.
3. Lancer le fichier EXE Windows et cliquer sur **Jouer en VR avec Quest 3**.
4. Le navigateur PC s'ouvre sur l'adresse locale du jeu. Utiliser Chrome ou Edge
   à jour ; si le navigateur par défaut n'est pas adapté, copier son adresse
   locale dans Chrome ou Edge.
5. Si le navigateur détecte le casque et le mode **immersive-vr**, cliquer
   sur le bouton **lunettes VR** généré par Babylon.js dans le jeu.
6. La téléportation sur le terrain est fournie par l'intégration WebXR déjà
   présente. Garder le programme EXE lancé en arrière-plan : sinon le serveur
   de jeu sera arrêté et la page navigateur ne fonctionnera plus.

**Limite importante :** Electron sert de lanceur Windows 3D, pas de moteur
OpenXR natif. Pour le casque, c'est le navigateur PC qui doit offrir WebXR.
Selon la version du navigateur, le runtime OpenXR et Quest Link, le mode
immersif peut ne pas être disponible. Une compilation GitHub verte prouve
seulement que l'EXE a été créé, pas que la VR a été validée sur casque.

## Contrôles

- Écran PC : ZQSD / WASD / flèches, souris, Maj pour courir, espace pour sauter.
- VR navigateur : pointeur de manette et téléportation WebXR de Babylon.js.
- Déplacement continu au joystick Quest, mains et interactions avancées :
  **pas encore ajoutés ni testés** dans cette première version.

## Ce qui est corrigé

Le module `www/src/world/npc.js` était absent alors que `game.js` l'importait.
Un PNJ guide léger a été ajouté pour rétablir le chargement.

## Développer sur Windows

Après installation de Node.js 22, dans le dossier `desktop` :

```bash
npm install
```

```bash
npm run stage
```

```bash
npx electron .
```

Pour reconstruire l'EXE portable sur Windows :

```bash
npm run dist
```

La compilation GitHub évite ces étapes manuelles. Le dossier temporaire
`pc-site/` et `dist/pcvr/` ne doivent pas être committés.
