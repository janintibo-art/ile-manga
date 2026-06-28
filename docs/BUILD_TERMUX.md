# Développer dans Termux et générer l'APK

## 1. Préparer Termux

```bash
pkg update
pkg install nodejs git
```

## 2. Récupérer le projet

Soit vous clonez votre dépôt existant :

```bash
git clone <URL_DE_VOTRE_DEPOT>
cd ile-manga-openworld
```

Soit vous partez de ce dossier décompressé directement.

## 3. Tester le jeu localement

```bash
npm run serve
```

Ouvrez **http://localhost:8080** dans le navigateur du téléphone.
Modifiez les fichiers dans `www/`, rechargez la page pour voir les changements.

## 4. Envoyer le projet sur GitHub

Créez un dépôt vide sur GitHub, puis :

```bash
git init
git add .
git commit -m "Premier jet : île + village"
git branch -M main
git remote add origin <URL_DE_VOTRE_DEPOT>
git push -u origin main
```

## 5. Laisser GitHub compiler l'APK

- Le fichier `.github/workflows/build-apk.yml` lance la compilation automatiquement
  à chaque `push` sur `main`.
- Vous pouvez aussi la lancer à la main : onglet **Actions** → **Build APK** →
  **Run workflow**.
- À la fin, ouvrez le job terminé → section **Artifacts** → téléchargez
  **`ile-manga-debug-apk`**. Décompressez pour obtenir `app-debug.apk`.

## 6. Installer l'APK

Transférez `app-debug.apk` sur le téléphone et installez-le.
Il faut autoriser l'installation depuis des **sources inconnues**.

> C'est un APK **debug** (non signé pour le Play Store), parfait pour tester.

---

## Pourquoi ne pas compiler l'APK directement dans Termux ?

Compiler un APK demande le SDK Android et Gradle, qui sont **mal supportés sur
l'architecture ARM de Termux**. Les builds échouent souvent ou sont très lents.
GitHub Actions fournit une machine Linux complète et gratuite : c'est le chemin
le plus simple et le plus fiable.

---

## Fonctionnement 100 % hors-ligne (optionnel)

Par défaut, Babylon.js est chargé depuis un CDN (internet requis au premier lancement).
Pour embarquer Babylon.js dans l'APK :

1. Téléchargez ces deux fichiers et placez-les dans un nouveau dossier `www/vendor/` :
   - `babylon.js`
   - `babylonjs.loaders.min.js`
2. Dans `www/index.html`, remplacez les `<script src="https://cdn.babylonjs.com/...">`
   par les chemins locaux :

```html
<script src="vendor/babylon.js"></script>
<script src="vendor/babylonjs.loaders.min.js"></script>
```

Le jeu n'aura alors plus besoin d'internet.

---

## Changer le nom et l'icône de l'application

- **Nom** et **identifiant** : dans `capacitor.config.json` (`appName`, `appId`).
- **Icône** : après `npx cap add android`, remplacez les images dans
  `android/app/src/main/res/mipmap-*/`, ou utilisez un générateur d'icônes Capacitor.
