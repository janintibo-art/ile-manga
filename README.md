# Île Manga — Open World Babylon.js

Point de départ d'un jeu **monde ouvert** dans un univers drôle façon anime/manga,
construit avec **Babylon.js**. La première zone est une **île avec un petit village**.
Tout est prêt pour être développé dans **Termux** et compilé en **APK via GitHub Actions**.

## Contenu de départ

- Île **générée par le code** (relief, plage, herbe, roche) — aucune texture requise au lancement.
- Petit **village** : 5 maisons colorées, feu de camp avec lumière vacillante, arbres dispersés.
- **Eau** animée tout autour de l'île.
- **Ciel** en dégradé et **ombres** dynamiques (soleil directionnel).
- **Personnage jouable** (capsule au départ) avec :
  - déplacement clavier **ZQSD / WASD / flèches**,
  - **manette tactile** sur mobile,
  - caméra qui suit, déplacement relatif à la caméra,
  - le sol est suivi automatiquement (pas de chute sous l'eau).
- Emplacements prêts pour vos **dalles de textures** et vos **personnages .glb animés**.

## Démarrer dans Termux

```bash
pkg install nodejs git
git clone <URL_DE_VOTRE_DEPOT>
cd ile-manga-openworld
npm run serve
```

Ouvrez ensuite **http://localhost:8080** dans le navigateur du téléphone.

> Un petit serveur local est nécessaire : les modules JavaScript ne fonctionnent pas
> en ouvrant le fichier directement (`file://`).

## Générer l'APK via GitHub Actions

1. Envoyez le projet sur GitHub (voir `docs/BUILD_TERMUX.md`).
2. Le workflow se lance automatiquement à chaque `push` sur `main`
   (ou manuellement depuis l'onglet **Actions**).
3. Quand il est terminé, ouvrez le job → section **Artifacts** → téléchargez
   **`ile-manga-debug-apk`** (contient `app-debug.apk`).
4. Installez l'APK sur le téléphone (autorisez les sources inconnues).

La compilation de l'APK se fait **sur GitHub**, pas dans Termux : compiler un APK
directement sous Termux n'est pas fiable (SDK Android peu supporté sur ARM/Termux).

## Documentation

- `docs/BUILD_TERMUX.md` — développement Termux, envoi GitHub, build de l'APK, mode hors-ligne.
- `docs/ADD_ASSETS.md` — ajouter vos textures et vos personnages .glb.

## Structure

```
ile-manga-openworld/
├── README.md
├── package.json
├── capacitor.config.json
├── .gitignore
├── .github/workflows/build-apk.yml   # build APK automatique
├── docs/
│   ├── BUILD_TERMUX.md
│   └── ADD_ASSETS.md
└── www/                              # l'application web (webDir Capacitor)
    ├── index.html
    ├── styles.css
    ├── src/
    │   ├── main.js                   # init moteur + boucle de rendu
    │   ├── game.js                   # scène, caméra, assemblage
    │   ├── world/
    │   │   ├── lighting.js
    │   │   ├── sky.js
    │   │   ├── water.js
    │   │   ├── island.js             # île procédurale + islandHeight()
    │   │   └── village.js
    │   ├── entities/
    │   │   └── player.js             # contrôleur + chargement .glb
    │   └── utils/
    │       └── loader.js             # chargement des modèles .glb
    └── assets/
        ├── textures/                 # vos dalles ici
        ├── models/                   # vos .glb ici
        └── audio/
```

## Note sur Babylon.js (CDN)

Babylon.js est chargé depuis un CDN, donc une connexion internet est nécessaire
**au premier lancement**. Pour un fonctionnement 100 % hors-ligne, voir la section
correspondante de `docs/BUILD_TERMUX.md`.
