import { createLighting } from "./world/lighting.js";
import { createSky } from "./world/sky.js";
import { createWater } from "./world/water.js";
import { createIsland } from "./world/island.js";
import { createVillage } from "./world/village.js";
import { createPlayer /*, loadPlayerCharacter */ } from "./entities/player.js";

export async function createGame(engine, canvas) {
  const scene = new BABYLON.Scene(engine);
  scene.clearColor = new BABYLON.Color4(0.53, 0.81, 0.92, 1);

  // Brume légère pour la profondeur (rendu doux façon anime).
  scene.fogMode = BABYLON.Scene.FOGMODE_LINEAR;
  scene.fogColor = new BABYLON.Color3(0.78, 0.88, 0.97);
  scene.fogStart = 130;
  scene.fogEnd = 300;

  // Caméra 3e personne, orbitale, qui suit le joueur.
  const camera = new BABYLON.ArcRotateCamera(
    "camera",
    -Math.PI / 2,
    1.0, // angle de départ plus en hauteur (meilleure vue d'ensemble)
    26,
    new BABYLON.Vector3(0, 3, 0),
    scene
  );
  camera.attachControl(canvas, true);
  camera.lowerRadiusLimit = 8;
  camera.upperRadiusLimit = 50;
  camera.lowerBetaLimit = 0.3; // évite de passer au-dessus à la verticale
  camera.upperBetaLimit = 1.45; // empêche de passer sous le sol
  camera.wheelDeltaPercentage = 0.01;
  camera.panningSensibility = 0; // désactive le panoramique, garde l'orbite

  const { shadowGenerator } = createLighting(scene);
  createSky(scene);
  createIsland(scene);
  createWater(scene);
  createVillage(scene, shadowGenerator);

  const player = createPlayer(scene, camera, shadowGenerator);

  // ▼▼ Quand tu auras un personnage .glb (animations nommées "idle"/"walk") :
  //    1) ajoute loadPlayerCharacter à l'import ci-dessus ;
  //    2) décommente la ligne suivante en adaptant le nom du fichier.
  // await loadPlayerCharacter(player, scene, "assets/models/characters/", "hero.glb", 1);

  return scene;
}
