// Objets à ramasser : des 8.6 posées au "district" (la plage DJ, vers z=60).
// En marchant dessus, le joueur refait le plein d'endurance. L'objet réapparaît
// après un délai. La géométrie n'est chargée qu'UNE fois (le reste = instances).

import { islandHeight } from "./island.js";
import { loadGLB } from "../utils/loader.js";

// Emplacements sur la plage du district (autour du mur de son / table / distributeur).
const SPOTS = [
  [5, 56],
  [-6, 57],
  [0, 64],
  [13, 63],
  [-13, 63],
];
const SCALE = 0.8; // taille de la canette
const PICK_R = 1.7; // rayon de ramassage
const RESPAWN = 12000; // ms avant réapparition
const REFILL = 100; // endurance rendue (= plein)

export function createPickups(scene, player) {
  loadGLB(scene, "assets/models/props/", "8_6.glb", {})
    .then((res) => {
      const src = res.meshes[0];
      const items = [];

      SPOTS.forEach((s, i) => {
        const x = s[0];
        const z = s[1];
        const gy = Math.max(islandHeight(x, z), -0.2);

        // Conteneur qui gère position, rotation (tournoiement) et taille.
        const wrap = new BABYLON.TransformNode("pickup" + i, scene);
        const baseY = gy + 0.95 * SCALE + 0.25; // pose + petit flottement
        wrap.position.set(x, baseY, z);
        wrap.scaling.set(SCALE, SCALE, SCALE);

        const node = i === 0 ? src : src.instantiateHierarchy(null);
        node.parent = wrap;
        node.position.set(0, 0, 0);

        items.push({ wrap, x, z, baseY, taken: false, takenAt: 0, phase: i });
      });

      scene.registerBeforeRender(() => {
        const now = performance.now();
        const p = player.position;
        for (const it of items) {
          if (it.taken) {
            if (now - it.takenAt > RESPAWN) {
              it.taken = false;
              it.wrap.setEnabled(true);
            } else {
              continue;
            }
          }
          // Flottement + tournoiement.
          it.wrap.position.y = it.baseY + Math.sin(now * 0.003 + it.phase) * 0.18;
          it.wrap.rotation.y += 0.02;

          // Ramassage (pas pendant qu'on est dans la maison).
          if (!player.metadata.interior) {
            const dx = p.x - it.x;
            const dz = p.z - it.z;
            if (dx * dx + dz * dz < PICK_R * PICK_R) {
              it.taken = true;
              it.takenAt = now;
              it.wrap.setEnabled(false);
              const md = player.metadata;
              md.stamina = Math.min(md.staminaMax || 100, (md.stamina || 0) + REFILL);
              if (md.staminaBar) md.staminaBar.flash();
            }
          }
        }
      });
    })
    .catch((e) => console.error("8_6.glb (pickups) :", e));
}
