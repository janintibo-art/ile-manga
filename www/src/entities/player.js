// Contrôleur du joueur.
// Au départ : une capsule (placeholder). Plus tard : on remplace par un .glb
// avec animations intégrées via loadPlayerCharacter().

import { islandHeight } from "../world/island.js";
import { loadGLB } from "../utils/loader.js";

const SPEED = 12;

// Manette tactile (affichée seulement sur écran tactile, voir styles.css).
function setupTouchControls(input) {
  const joystick = document.getElementById("joystick");
  if (!joystick) return;

  let active = false;
  let centerX = 0;
  let centerY = 0;

  joystick.addEventListener("pointerdown", (e) => {
    active = true;
    const rect = joystick.getBoundingClientRect();
    centerX = rect.left + rect.width / 2;
    centerY = rect.top + rect.height / 2;
    joystick.setPointerCapture(e.pointerId);
    e.preventDefault();
  });

  joystick.addEventListener("pointermove", (e) => {
    if (!active) return;
    input.joyX = Math.max(-1, Math.min(1, (e.clientX - centerX) / 50));
    input.joyY = Math.max(-1, Math.min(1, -(e.clientY - centerY) / 50));
    e.preventDefault();
  });

  const reset = (e) => {
    active = false;
    input.joyX = 0;
    input.joyY = 0;
    if (e) e.preventDefault();
  };
  joystick.addEventListener("pointerup", reset);
  joystick.addEventListener("pointercancel", reset);
}

// Bascule entre animation "idle" et "marche" selon le mouvement.
function updateAnimation(player) {
  const md = player.metadata;
  if (!md.animationGroups) return;

  const target = md.moving ? md.walkAnim : md.idleAnim;
  if (!target || target === md.currentAnim) return;

  if (md.currentAnim) md.currentAnim.stop();
  target.start(true, 1.0, target.from, target.to, false);
  md.currentAnim = target;
}

export function createPlayer(scene, camera, shadowGenerator) {
  const player = BABYLON.MeshBuilder.CreateCapsule(
    "player",
    { radius: 0.5, height: 1.8 },
    scene
  );
  player.position.set(2, 6, 8);

  const mat = new BABYLON.StandardMaterial("playerMat", scene);
  mat.diffuseColor = new BABYLON.Color3(0.95, 0.45, 0.6); // rose : placeholder visible
  mat.specularColor = BABYLON.Color3.Black();
  player.material = mat;

  if (shadowGenerator) shadowGenerator.addShadowCaster(player);

  player.metadata = {
    moving: false,
    animationGroups: null,
    idleAnim: null,
    walkAnim: null,
    currentAnim: null,
  };

  // --- Entrées clavier ---
  const input = { joyX: 0, joyY: 0 };
  scene.onKeyboardObservable.add((kbInfo) => {
    const key = kbInfo.event.key.toLowerCase();
    const down = kbInfo.type === BABYLON.KeyboardEventTypes.KEYDOWN;
    input[key] = down;
  });

  setupTouchControls(input);

  // --- Boucle de déplacement ---
  scene.registerBeforeRender(() => {
    const dt = scene.getEngine().getDeltaTime() / 1000;

    // ZQSD + WASD + flèches, et axe Z/Y inversés pour "avancer".
    let mX = 0;
    let mZ = 0;
    if (input["z"] || input["w"] || input["arrowup"]) mZ += 1;
    if (input["s"] || input["arrowdown"]) mZ -= 1;
    if (input["q"] || input["a"] || input["arrowleft"]) mX -= 1;
    if (input["d"] || input["arrowright"]) mX += 1;
    mX += input.joyX;
    mZ += input.joyY;

    const moving = mX * mX + mZ * mZ > 0.02;
    player.metadata.moving = moving;

    if (moving) {
      // Déplacement relatif à la caméra.
      const forward = camera.getForwardRay().direction;
      forward.y = 0;
      forward.normalize();
      const right = BABYLON.Vector3.Cross(BABYLON.Axis.Y, forward).normalize();

      const move = forward.scale(mZ).add(right.scale(mX));
      move.normalize().scaleInPlace(SPEED * dt);

      player.position.x += move.x;
      player.position.z += move.z;
      player.rotation.y = Math.atan2(move.x, move.z);
    }

    // Suit le relief du sol (jamais sous l'eau).
    const groundY = Math.max(islandHeight(player.position.x, player.position.z), 0);
    player.position.y = groundY + 0.9;

    camera.target = player.position.clone();

    updateAnimation(player);
  });

  return player;
}

// Remplace la capsule par un personnage .glb (à appeler depuis game.js).
export async function loadPlayerCharacter(player, scene, folder, file, scale = 1) {
  const result = await loadGLB(scene, folder, file, { parent: player, scale });

  // Décale le modèle pour que les pieds touchent le sol.
  result.meshes[0].position = new BABYLON.Vector3(0, -0.9, 0);
  player.isVisible = false; // cache la capsule placeholder

  const groups = result.animationGroups || [];
  const md = player.metadata;
  md.animationGroups = groups;

  for (const g of groups) {
    const name = g.name.toLowerCase();
    if (!md.idleAnim && (name.includes("idle") || name.includes("stand") || name.includes("repos"))) {
      md.idleAnim = g;
    }
    if (!md.walkAnim && (name.includes("walk") || name.includes("run") || name.includes("marche") || name.includes("cours"))) {
      md.walkAnim = g;
    }
  }

  groups.forEach((g) => g.stop());
  if (md.idleAnim) {
    md.idleAnim.start(true, 1.0, md.idleAnim.from, md.idleAnim.to, false);
    md.currentAnim = md.idleAnim;
  }

  return result;
}
