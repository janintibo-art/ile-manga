// Petit village posé sur l'île : maisons colorées, arbres et un feu de camp.
// On réutilise islandHeight() pour poser chaque objet au sol.

import { islandHeight } from "./island.js";

// --- Maison simple type anime : murs + toit pyramidal + porte ---
function createHouse(scene, x, z, palette, shadowGenerator) {
  const root = new BABYLON.TransformNode("house", scene);

  const wallMat = new BABYLON.StandardMaterial("wallMat", scene);
  wallMat.diffuseColor = palette.wallColor;
  wallMat.specularColor = BABYLON.Color3.Black();

  const roofMat = new BABYLON.StandardMaterial("roofMat", scene);
  roofMat.diffuseColor = palette.roofColor;
  roofMat.specularColor = BABYLON.Color3.Black();

  const doorMat = new BABYLON.StandardMaterial("doorMat", scene);
  doorMat.diffuseColor = new BABYLON.Color3(0.4, 0.26, 0.15);
  doorMat.specularColor = BABYLON.Color3.Black();

  const walls = BABYLON.MeshBuilder.CreateBox(
    "walls",
    { width: 4, height: 3, depth: 4 },
    scene
  );
  walls.position.y = 1.5;
  walls.material = wallMat;
  walls.parent = root;

  // Toit pyramidal = cylindre à 4 côtés, pointe en haut.
  const roof = BABYLON.MeshBuilder.CreateCylinder(
    "roof",
    { diameterTop: 0, diameterBottom: 6.2, height: 2.4, tessellation: 4 },
    scene
  );
  roof.rotation.y = Math.PI / 4;
  roof.position.y = 4.2;
  roof.material = roofMat;
  roof.parent = root;

  const door = BABYLON.MeshBuilder.CreateBox(
    "door",
    { width: 1, height: 1.8, depth: 0.2 },
    scene
  );
  door.position.set(0, 0.9, 2.05);
  door.material = doorMat;
  door.parent = root;

  root.position.set(x, islandHeight(x, z), z);

  if (shadowGenerator) {
    shadowGenerator.addShadowCaster(walls);
    shadowGenerator.addShadowCaster(roof);
  }

  return root;
}

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

// --- Feu de camp : cercle de pierres + flamme + lumière vacillante ---
function createCampfire(scene, x, z) {
  const cy = islandHeight(x, z);

  const stoneMat = new BABYLON.StandardMaterial("stoneMat", scene);
  stoneMat.diffuseColor = new BABYLON.Color3(0.5, 0.5, 0.52);
  stoneMat.specularColor = BABYLON.Color3.Black();

  const r = 1.1;
  for (let i = 0; i < 6; i++) {
    const a = (i / 6) * Math.PI * 2;
    const stone = BABYLON.MeshBuilder.CreateBox("stone", { size: 0.5 }, scene);
    stone.position.set(x + Math.cos(a) * r, cy + 0.2, z + Math.sin(a) * r);
    stone.material = stoneMat;
  }

  const flameMat = new BABYLON.StandardMaterial("flameMat", scene);
  flameMat.diffuseColor = new BABYLON.Color3(1, 0.5, 0.12);
  flameMat.emissiveColor = new BABYLON.Color3(1, 0.5, 0.12); // brille même sans lumière
  flameMat.specularColor = BABYLON.Color3.Black();

  const flame = BABYLON.MeshBuilder.CreateCylinder(
    "flame",
    { diameterTop: 0, diameterBottom: 0.9, height: 1.3, tessellation: 8 },
    scene
  );
  flame.position.set(x, cy + 0.75, z);
  flame.material = flameMat;

  const fireLight = new BABYLON.PointLight(
    "fireLight",
    new BABYLON.Vector3(x, cy + 1, z),
    scene
  );
  fireLight.diffuse = new BABYLON.Color3(1, 0.6, 0.25);
  fireLight.range = 16;
  fireLight.intensity = 0.8;

  // Vacillement de la flamme et de la lumière.
  scene.registerBeforeRender(() => {
    const t = performance.now() * 0.008;
    fireLight.intensity = 0.7 + Math.sin(t) * 0.18 + Math.random() * 0.08;
    flame.scaling.y = 1 + Math.sin(t * 1.7) * 0.12;
  });
}

// Construit l'ensemble du village autour d'un centre.
export function createVillage(scene, shadowGenerator) {
  const cx = 0;
  const cz = 4;

  createCampfire(scene, cx, cz);

  // 5 maisons en cercle, chacune avec sa palette de couleurs.
  const palettes = [
    { wallColor: new BABYLON.Color3(0.96, 0.93, 0.82), roofColor: new BABYLON.Color3(0.82, 0.31, 0.27) }, // crème / rouge
    { wallColor: new BABYLON.Color3(0.74, 0.86, 0.66), roofColor: new BABYLON.Color3(0.31, 0.5, 0.78) },  // vert / bleu
    { wallColor: new BABYLON.Color3(0.97, 0.88, 0.55), roofColor: new BABYLON.Color3(0.9, 0.55, 0.2) },   // jaune / orange
    { wallColor: new BABYLON.Color3(0.84, 0.78, 0.9), roofColor: new BABYLON.Color3(0.55, 0.35, 0.7) },   // lilas / violet
    { wallColor: new BABYLON.Color3(0.72, 0.9, 0.84), roofColor: new BABYLON.Color3(0.2, 0.6, 0.58) },    // menthe / sarcelle
  ];

  const houseRing = 9;
  for (let i = 0; i < palettes.length; i++) {
    // L'emplacement i=0 (ancienne maison rouge) est réservé à la maison
    // détaillée Maison.glb, posée par createDecor() (voir decor.js).
    if (i === 0) continue;
    const a = (i / palettes.length) * Math.PI * 2;
    const hx = cx + Math.cos(a) * houseRing;
    const hz = cz + Math.sin(a) * houseRing;
    const house = createHouse(scene, hx, hz, palettes[i], shadowGenerator);
    // Oriente la maison vers le centre du village.
    house.rotation.y = Math.atan2(cx - hx, cz - hz);
  }

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
