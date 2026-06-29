// Petit village posé sur l'île : arbres (fusionnés) et un feu de camp.
// On réutilise islandHeight() pour poser chaque objet au sol.

import { islandHeight } from "./island.js";
import { loadGLB } from "../utils/loader.js";
import { addCircle } from "./obstacles.js";

// Texture de particule générée à la volée (dégradé radial doux, sans fichier).
let flameTexCache = null;
function makeFlameTexture(scene) {
  if (flameTexCache) return flameTexCache;
  const size = 64;
  const dt = new BABYLON.DynamicTexture("flameTex", size, scene, false);
  const ctx = dt.getContext();
  const g = ctx.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size / 2);
  g.addColorStop(0, "rgba(255,255,255,1)");
  g.addColorStop(0.4, "rgba(255,255,255,0.6)");
  g.addColorStop(1, "rgba(255,255,255,0)");
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, size, size);
  dt.hasAlpha = true;
  dt.update();
  flameTexCache = dt;
  return dt;
}

// Feu vivant : flammes additives qui montent + braises qui s'envolent.
function createFireParticles(scene, x, y, z) {
  const tex = makeFlameTexture(scene);

  // --- Flammes ---
  const flames = new BABYLON.ParticleSystem("flames", 300, scene);
  flames.particleTexture = tex;
  flames.emitter = new BABYLON.Vector3(x, y, z);
  flames.minEmitBox = new BABYLON.Vector3(-0.35, 0, -0.35);
  flames.maxEmitBox = new BABYLON.Vector3(0.35, 0.2, 0.35);
  flames.color1 = new BABYLON.Color4(1, 0.75, 0.25, 1);
  flames.color2 = new BABYLON.Color4(1, 0.35, 0.08, 1);
  flames.colorDead = new BABYLON.Color4(0.1, 0, 0, 0);
  flames.minSize = 0.45;
  flames.maxSize = 1.1;
  flames.minLifeTime = 0.25;
  flames.maxLifeTime = 0.55;
  flames.emitRate = 140;
  flames.blendMode = BABYLON.ParticleSystem.BLENDMODE_ONEONE; // additif = lumineux
  flames.gravity = new BABYLON.Vector3(0, 0, 0);
  flames.direction1 = new BABYLON.Vector3(-0.4, 2.2, -0.4);
  flames.direction2 = new BABYLON.Vector3(0.4, 3.0, 0.4);
  flames.minEmitPower = 0.6;
  flames.maxEmitPower = 1.4;
  flames.updateSpeed = 0.012;
  flames.minAngularSpeed = 0;
  flames.maxAngularSpeed = Math.PI;
  flames.start();

  // --- Braises / étincelles ---
  const embers = new BABYLON.ParticleSystem("embers", 80, scene);
  embers.particleTexture = tex;
  embers.emitter = new BABYLON.Vector3(x, y + 0.2, z);
  embers.minEmitBox = new BABYLON.Vector3(-0.3, 0, -0.3);
  embers.maxEmitBox = new BABYLON.Vector3(0.3, 0.2, 0.3);
  embers.color1 = new BABYLON.Color4(1, 0.8, 0.3, 1);
  embers.color2 = new BABYLON.Color4(1, 0.5, 0.1, 1);
  embers.colorDead = new BABYLON.Color4(0, 0, 0, 0);
  embers.minSize = 0.04;
  embers.maxSize = 0.12;
  embers.minLifeTime = 0.6;
  embers.maxLifeTime = 1.4;
  embers.emitRate = 30;
  embers.blendMode = BABYLON.ParticleSystem.BLENDMODE_ONEONE;
  embers.gravity = new BABYLON.Vector3(0, 1.2, 0); // flottent vers le haut
  embers.direction1 = new BABYLON.Vector3(-0.6, 2.5, -0.6);
  embers.direction2 = new BABYLON.Vector3(0.6, 4.0, 0.6);
  embers.minEmitPower = 0.5;
  embers.maxEmitPower = 1.2;
  embers.updateSpeed = 0.012;
  embers.start();

  return { flames, embers };
}

// Crée les meshes d'un arbre (tronc + 3 feuillages) en coordonnées MONDE,
// non parentés, pour pouvoir les fusionner ensuite (gros gain de perfs).
function buildTreeMeshes(scene, x, z, trunks, leaves) {
  const groundY = islandHeight(x, z);

  const trunk = BABYLON.MeshBuilder.CreateCylinder(
    "trunk",
    { diameterTop: 0.4, diameterBottom: 0.6, height: 2.5, tessellation: 6 },
    scene
  );
  trunk.position.set(x, groundY + 1.25, z);
  trunks.push(trunk);

  for (let i = 0; i < 3; i++) {
    const leaf = BABYLON.MeshBuilder.CreateSphere(
      "leaf",
      { diameter: 3 - i * 0.6, segments: 8 },
      scene
    );
    leaf.position.set(x, groundY + 2.9 + i * 0.85, z);
    leaves.push(leaf);
  }
}

// --- Feu de camp : modèle .glb + lumière chaude vacillante ---
function createCampfire(scene, x, z) {
  const cy = islandHeight(x, z);

  // Modèle de feu détaillé (bûches + flammes). minY ≈ -0.863.
  const scale = 1.2;
  loadGLB(scene, "assets/models/props/", "Feu.glb", {
    position: new BABYLON.Vector3(x, cy + 0.863 * scale, z),
    scale: scale,
    static: true,
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

  // Flammes + braises animées, juste au-dessus des bûches.
  createFireParticles(scene, x, cy + 0.25, z);

  // Zone bloquante autour du feu.
  addCircle(x, z, 1.1);

  scene.registerBeforeRender(() => {
    const t = performance.now() * 0.008;
    fireLight.intensity = 0.7 + Math.sin(t) * 0.18 + Math.random() * 0.08;
  });
}

// Réglage des arbres :
//   MAPLE_COUNT > 0 -> érables RÉELS (Erable.glb, TRÈS lourd : 2,3 M triangles).
//                      Géométrie chargée 1 seule fois, le reste en instances.
//                      Si ça rame ou ne charge pas : baisse ce nombre (même 1),
//                      ou mets 0 pour revenir aux arbres légers d'origine.
//   MAPLE_COUNT = 0 -> arbres stylisés légers (tronc + feuillages fusionnés).
// Par défaut 0 (sûr). Passe à 5 APRÈS avoir copié Erable.glb sur le téléphone
// (idéalement décimé dans Blender d'abord, sinon ça peut ramer/planter).
const MAPLE_COUNT = 0;
const MAPLE_SCALE = 3;

// Choisit des positions d'arbres dispersées (ni dans le village, ni dans l'eau).
function pickTreeSpots(cx, cz, count) {
  const spots = [];
  let tries = 0;
  while (spots.length < count && tries < 800) {
    tries++;
    const tx = (Math.random() - 0.5) * 144; // ±72
    const tz = (Math.random() - 0.5) * 144;
    const ty = islandHeight(tx, tz);
    const d = Math.sqrt((tx - cx) ** 2 + (tz - cz) ** 2);
    if (ty > 0.8 && ty < 7 && d > 16) spots.push([tx, tz]);
  }
  return spots;
}

// Construit l'ensemble du village autour d'un centre.
export function createVillage(scene, shadowGenerator) {
  const cx = 0;
  const cz = 4;
  createCampfire(scene, cx, cz);

  if (MAPLE_COUNT > 0) {
    const spots = pickTreeSpots(cx, cz, MAPLE_COUNT);
    spots.forEach((s) => addCircle(s[0], s[1], 0.8)); // troncs bloquants

    // Érables réels en instances (la lourde géométrie n'est chargée qu'une fois).
    loadGLB(scene, "assets/models/props/", "Erable.glb", {})
      .then((res) => {
        const src = res.meshes[0];
        spots.forEach((s, i) => {
          const gy = islandHeight(s[0], s[1]);
          const wrap = new BABYLON.TransformNode("maple" + i, scene);
          wrap.position.set(s[0], gy + 0.95 * MAPLE_SCALE, s[1]);
          wrap.rotation.y = Math.random() * Math.PI * 2;
          wrap.scaling.set(MAPLE_SCALE, MAPLE_SCALE, MAPLE_SCALE);
          const node = i === 0 ? src : src.instantiateHierarchy(null);
          node.parent = wrap;
          node.position.set(0, 0, 0);
        });
      })
      .catch((e) => console.error("Erable.glb :", e));
    return;
  }

  // --- Repli : arbres stylisés légers (tronc + feuillages fusionnés) ---
  const trunkMat = new BABYLON.StandardMaterial("trunkMat", scene);
  trunkMat.diffuseColor = new BABYLON.Color3(0.45, 0.3, 0.18);
  trunkMat.specularColor = BABYLON.Color3.Black();
  const leafMat = new BABYLON.StandardMaterial("leafMat", scene);
  leafMat.diffuseColor = new BABYLON.Color3(0.3, 0.66, 0.32);
  leafMat.specularColor = BABYLON.Color3.Black();

  const spots = pickTreeSpots(cx, cz, 24);
  const trunks = [];
  const leaves = [];
  spots.forEach((s) => {
    buildTreeMeshes(scene, s[0], s[1], trunks, leaves);
    addCircle(s[0], s[1], 0.6);
  });
  if (trunks.length) {
    const trunkMesh = BABYLON.Mesh.MergeMeshes(trunks, true, true);
    trunkMesh.material = trunkMat;
    if (shadowGenerator) shadowGenerator.addShadowCaster(trunkMesh);
    trunkMesh.freezeWorldMatrix();
  }
  if (leaves.length) {
    const leafMesh = BABYLON.Mesh.MergeMeshes(leaves, true, true);
    leafMesh.material = leafMat;
    if (shadowGenerator) shadowGenerator.addShadowCaster(leafMesh);
    leafMesh.freezeWorldMatrix();
  }
  trunkMat.freeze();
  leafMat.freeze();
}
