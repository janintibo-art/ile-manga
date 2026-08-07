import { createLighting } from "./world/lighting.js";
import { createSky } from "./world/sky.js";
import { createWater } from "./world/water.js";
import { createIsland } from "./world/island.js";
import { createVillage } from "./world/village.js";
import { createDecor } from "./world/decor.js";
import { createInterior } from "./world/interior.js";
import { createPickups } from "./world/pickups.js";
import { createNPC } from "./world/npc.js";
import { createPlayer, loadPlayerCharacter } from "./entities/player.js";
import { setupXR } from "./xr.js";

export async function createGame(engine, canvas) {
  const scene = new BABYLON.Scene(engine);
  scene.clearColor = new BABYLON.Color4(0.53, 0.81, 0.92, 1);

  // Évite de tester des objets à chaque mouvement de doigt (gain CPU).
  scene.skipPointerMovePicking = true;

  // Rendu un peu plus "filmique" : tone mapping doux + léger contraste.
  // Subtil pour ne pas dénaturer les couleurs actuelles.
  const ip = scene.imageProcessingConfiguration;
  ip.toneMappingEnabled = true;
  ip.toneMappingType = BABYLON.ImageProcessingConfiguration.TONEMAPPING_ACES;
  ip.contrast = 1.1;
  ip.exposure = 1.05;

  // Brume légère pour la profondeur (rendu doux façon anime).
  scene.fogMode = BABYLON.Scene.FOGMODE_LINEAR;
  scene.fogColor = new BABYLON.Color3(0.78, 0.88, 0.97);
  scene.fogStart = 130;
  scene.fogEnd = 300;

  // Caméra 3e personne, orbitale, qui suit le joueur.
  const camera = new BABYLON.ArcRotateCamera(
    "camera",
    -Math.PI / 2,
    1.1, // angle un peu derrière l'épaule (style jeu vidéo)
    4.5, // distance rapprochée : caméra 3e personne proche du perso
    new BABYLON.Vector3(0, 3, 0),
    scene
  );
  camera.attachControl(canvas, true);
  camera.lowerRadiusLimit = 3;
  camera.upperRadiusLimit = 14;
  camera.lowerBetaLimit = 0.3; // évite de passer au-dessus à la verticale
  camera.upperBetaLimit = 1.45; // empêche de passer sous le sol
  camera.wheelDeltaPercentage = 0.01;
  camera.panningSensibility = 0; // désactive le panoramique, garde l'orbite
  camera.maxZ = 600; // rien d'utile au-delà (brume finit à 300) : petit gain

  // Pipeline d'image : FXAA (lissage des bords, remplace le MSAA coupé dans
  // main.js) + bloom léger (halo sur le feu et les hautes lumières).
  try {
    const pipe = new BABYLON.DefaultRenderingPipeline("rendu", false, scene, [camera]);
    pipe.fxaaEnabled = true;
    pipe.bloomEnabled = true;   // mets false si tu n'aimes pas le halo
    pipe.bloomThreshold = 0.85; // seuil : seules les zones très lumineuses brillent
    pipe.bloomWeight = 0.2;     // intensité du halo (0.1 discret -> 0.4 marqué)
    pipe.bloomKernel = 24;
    pipe.bloomScale = 0.5;
  } catch (e) {
    console.warn("Pipeline de rendu indisponible :", e);
  }

  const { shadowGenerator } = createLighting(scene);
  createSky(scene);
  const ground = createIsland(scene);
  createWater(scene);
  createVillage(scene, shadowGenerator);
  createDecor(scene, shadowGenerator); // maison .glb + île flottante

  const player = createPlayer(scene, camera, shadowGenerator);

  // Intérieur de maison explorable (on entre/sort près de la porte en 9,4).
  createInterior(scene, player, camera);

  // 8.6 à ramasser au district (plage DJ) pour refaire le plein d'endurance.
  createPickups(scene, player);

  // PNJ "smiley" doté d'une IA (flâne, te repère, vient te saluer, parle).
  createNPC(scene, player, camera, shadowGenerator);

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

  // Mode VR (casque type Quest, via son navigateur) : si l'appareil le permet,
  // un bouton "lunettes" apparaît en bas à droite. Sur téléphone : aucun effet.
  await setupXR(scene, ground);

  // Tout est en place : on gèle le mécanisme de "matériaux à revérifier"
  // (les lumières n'évoluent plus). Petit gain CPU constant.
  scene.blockMaterialDirtyMechanism = true;

  return scene;
}
