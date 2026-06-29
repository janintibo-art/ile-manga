import { createLighting } from "./world/lighting.js";
import { createSky } from "./world/sky.js";
import { createWater } from "./world/water.js";
import { createIsland } from "./world/island.js";
import { createVillage } from "./world/village.js";
import { createDecor } from "./world/decor.js";
import { createInterior } from "./world/interior.js";
import { createPlayer, loadPlayerCharacter } from "./entities/player.js";

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
    12, // distance de départ rapprochée (on voit bien le personnage)
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
  createDecor(scene, shadowGenerator); // maison .glb + île flottante

  const player = createPlayer(scene, camera, shadowGenerator);

  // Intérieur de maison explorable (on entre/sort près de la porte en 9,4).
  createInterior(scene, player, camera);

  // Personnage 3D (Punk Emoji Rocker).
  // Animations disponibles dans hero.glb :
  //   Formal_Bow · Knock_Down · Lie_Down_Hands_Spread · Motivational_Cheer
  //   Punch_Combo_5 · Running · Seated_Fist_Pump · Skip_Forward · Stand_and_Drink
  //   Talk_with_Right_Hand_Open · Walking_Scan_with_Sudden_Look_Back · Walking
  // Change idleName / walkName pour utiliser d'autres animations.
  try {
    await loadPlayerCharacter(player, scene, "assets/models/characters/", "hero.glb", {
      scale: 1,
      idleName: "Stand_and_Drink", // animation à l'arrêt
      walkName: "Walking",         // animation en déplacement
      facingOffset: 0,             // orientation de base correcte (0 ou Math.PI si à l'envers)
      shadowGenerator,
    });
  } catch (e) {
    // Si le .glb ne charge pas, on garde la capsule et le jeu continue.
    console.warn("Personnage .glb non chargé :", e);
  }

  return scene;
}
