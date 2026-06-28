// Modèles .glb décoratifs : maison détaillée (remplace l'ancienne maison rouge
// du village) + île flottante dans le ciel.

import { loadGLB } from "../utils/loader.js";
import { islandHeight } from "./island.js";

export function createDecor(scene, shadowGenerator) {
  // --- Maison détaillée : occupe l'emplacement réservé du village (i=0) ---
  const hx = 9;                    // même position que l'ancienne maison rouge
  const hz = 4;
  const hScale = 4.5;              // taille (augmente cette valeur pour plus grand)
  const hRotation = -Math.PI / 2;  // orientation (ajoute Math.PI pour pivoter de 180°)
  loadGLB(scene, "assets/models/buildings/", "Maison.glb", {
    position: new BABYLON.Vector3(hx, islandHeight(hx, hz) + 0.8 * hScale, hz),
    scale: hScale,
    rotationY: hRotation,
    shadowGenerator,
  }).catch((e) => console.error("Maison.glb :", e));

  // --- Île flottante dans le ciel, avec un léger flottement vertical ---
  const iScale = 12;
  loadGLB(scene, "assets/models/buildings/", "Ile_flottante.glb", {
    position: new BABYLON.Vector3(20, 18, -15),
    scale: iScale,
  })
    .then((res) => {
      const root = res.meshes[0];
      const baseY = root.position.y;
      scene.registerBeforeRender(() => {
        root.position.y = baseY + Math.sin(performance.now() * 0.0006) * 1.2;
      });
    })
    .catch((e) => console.error("Ile_flottante.glb :", e));
}
