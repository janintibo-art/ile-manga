// Petit village posé sur l'île : arbres et un feu de camp.
// On réutilise islandHeight() pour poser chaque objet au sol.

import { islandHeight } from "./island.js";
import { loadGLB } from "../utils/loader.js";

// --- Arbre stylisé : tronc + 3 boules de feuillage empilées ---
function createTree(scene, x, z, shadowGenerator) {
  const root = new BABYLON.TransformNode("tree", scene);

  const trunkMat = new BABYLON.StandardMaterial("trunkMat", scene);
  trunkMat.diffuseColor = new BABYLON.Color3(0.45, 0.3, 0.18);
  trunkMat.specularColor = BABYLON.Color3.Black();

  const leafMat = new BABYLON.StandardMaterial("leafMat", scene);
  leafMat.diffuseColor = new BABYLON.Color3(0.3, 0.66, 0.32);
  leafMat.specularColor = BABYLON.Color3.Black();

  const trunk = BABYLON.MeshBuilder.CreateCylinder(
    "trunk",
    { diameterTop: 0.4, diameterBottom: 0.6, height: 2.5, tessellation: 6 },
    scene
  );
  trunk.position.y = 1.25;
  trunk.material = trunkMat;
  trunk.parent = root;
  if (shadowGenerator) shadowGenerator.addShadowCaster(trunk);

  for (let i = 0; i < 3; i++) {
    const leaf = BABYLON.MeshBuilder.CreateSphere(
      "leaf",
      { diameter: 3 - i * 0.6, segments: 8 },
      scene
    );
    leaf.position.y = 2.9 + i * 0.85;
    leaf.material = leafMat;
    leaf.parent = root;
    if (shadowGenerator) shadowGenerator.addShadowCaster(leaf);
  }

  root.position.set(x, islandHeight(x, z), z);
  return root;
}

// --- Feu de camp : modèle .glb + lumière chaude vacillante ---
function createCampfire(scene, x, z) {
  const cy = islandHeight(x, z);

  // Modèle de feu détaillé (bûches + flammes). minY ≈ -0.863.
  const scale = 1.2;
  loadGLB(scene, "assets/models/props/", "Feu.glb", {
    position: new BABYLON.Vector3(x, cy + 0.863 * scale, z),
    scale: scale,
  }).catch((e) => console.error("Feu.glb :", e));

  // Lumière chaude vacillante (éclaire les environs).
  const fireLight = new BABYLON.PointLight(
    "fireLight",
    new BABYLON.Vector3(x, cy + 1, z),
    scene
  );
  fireLight.diffuse = new BABYLON.Color3(1, 0.6, 0.25);
  fireLight.range = 16;
  fireLight.intensity = 0.8;

  scene.registerBeforeRender(() => {
    const t = performance.now() * 0.008;
    fireLight.intensity = 0.7 + Math.sin(t) * 0.18 + Math.random() * 0.08;
  });
}

// Construit l'ensemble du village autour d'un centre.
export function createVillage(scene, shadowGenerator) {
  const cx = 0;
  const cz = 4;

  createCampfire(scene, cx, cz);

  // Arbres dispersés sur l'île, en évitant le village et l'eau.
  let placed = 0;
  let tries = 0;
  while (placed < 24 && tries < 600) {
    tries++;
    const tx = (Math.random() - 0.5) * 144; // ±72
    const tz = (Math.random() - 0.5) * 144;
    const ty = islandHeight(tx, tz);
    const distCenter = Math.sqrt((tx - cx) ** 2 + (tz - cz) ** 2);
    if (ty > 0.8 && ty < 7 && distCenter > 16) {
      createTree(scene, tx, tz, shadowGenerator);
      placed++;
    }
  }
}
