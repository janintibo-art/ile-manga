# Ajouter vos textures et vos personnages

Les chemins d'assets sont **relatifs** (`assets/...`, sans `/` au début) pour que
tout fonctionne aussi bien sur le serveur local que dans l'APK.

---

## Ajouter des dalles de textures

1. Placez vos images dans `www/assets/textures/terrain/` (ou `water/`).

2. Pour texturer l'île, modifiez `www/src/world/island.js`. Remplacez la couleur
   par une texture répétée et désactivez les couleurs de sommets :

```js
const mat = new BABYLON.StandardMaterial("islandMat", scene);
const tex = new BABYLON.Texture("assets/textures/terrain/herbe.png", scene);
tex.uScale = 40;   // répétition horizontale
tex.vScale = 40;   // répétition verticale
mat.diffuseTexture = tex;
mat.specularColor = new BABYLON.Color3(0, 0, 0);
ground.material = mat;
ground.useVertexColors = false; // important : laisser la texture s'afficher
```

3. Pour animer l'eau avec une texture (dans `www/src/world/water.js`) :

```js
const tex = new BABYLON.Texture("assets/textures/water/eau.png", scene);
waterMat.diffuseTexture = tex;
scene.registerBeforeRender(() => {
  tex.uOffset += 0.0008;
  tex.vOffset += 0.0005;
});
```

---

## Ajouter un personnage jouable (.glb)

1. Exportez votre modèle en **.glb** avec les **textures intégrées** et les
   **animations** nommées clairement. Le code reconnaît automatiquement les noms
   contenant : `idle` / `stand` / `repos` pour l'attente, et
   `walk` / `run` / `marche` / `cours` pour le déplacement.

2. Placez le fichier dans `www/assets/models/characters/`,
   par exemple `heros.glb`.

3. Dans `www/src/game.js`, importez la fonction et appelez-la après la création
   du joueur :

```js
import { createPlayer, loadPlayerCharacter } from "./entities/player.js";

const player = createPlayer(scene, camera, lighting.shadowGenerator);

// Remplace la capsule par votre modèle animé :
loadPlayerCharacter(player, scene, "assets/models/characters/", "heros.glb", 1);
```

La capsule rose disparaît, votre modèle prend sa place, et l'animation passe
automatiquement de « attente » à « marche » selon le mouvement.

> Si le personnage est trop grand/petit, ajustez le dernier paramètre (l'échelle).
> S'il s'enfonce dans le sol ou flotte, ajustez la ligne
> `result.meshes[0].position = new BABYLON.Vector3(0, -0.9, 0);` dans `player.js`.

---

## Ajouter des bâtiments ou décors (.glb)

1. Placez le `.glb` dans `www/assets/models/buildings/`.

2. Chargez-le où vous voulez (par exemple dans `village.js`) :

```js
import { loadGLB } from "../utils/loader.js";

loadGLB(scene, "assets/models/buildings/", "tour.glb", {
  position: new BABYLON.Vector3(10, islandHeight(10, 5), 5),
  scale: 1.5,
  rotationY: Math.PI / 2,
  shadowGenerator: shadowGenerator,
});
```

Pensez à poser l'objet au sol avec `islandHeight(x, z)` pour la coordonnée Y.
