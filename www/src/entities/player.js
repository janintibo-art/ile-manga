// Contrôleur du joueur.
// Au départ : une capsule (placeholder). Plus tard : on remplace par un .glb
// avec animations intégrées via loadPlayerCharacter().

import { islandHeight } from "../world/island.js";
import { loadGLB } from "../utils/loader.js";

const SPEED = 4;

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

// Applique l'orientation : directement sur le modèle .glb si présent
// (en conservant la conversion de repère glTF), sinon sur la capsule.
function applyFacing(player) {
  const md = player.metadata;
  const fy = md.facingY + md.facingOffset;
  if (md.charModel) {
    const q = BABYLON.Quaternion.RotationAxis(BABYLON.Axis.Y, fy);
    // On écrit la rotation du modèle à chaque frame : il tourne vraiment.
    md.charModel.rotationQuaternion = q.multiply(md.charBaseQuat);
  } else {
    player.rotation.y = fy;
  }
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
    facingY: 0,          // orientation courante (lissée), en radians
    facingOffset: 0,     // correction d'orientation du modèle (0 ou Math.PI)
    charModel: null,     // racine du modèle .glb à tourner
    charBaseQuat: null,  // quaternion de conversion de repère glTF
    interior: null,      // si défini : on est dans une pièce (sol plat + murs)
  };

  // --- Entrées clavier ---
  const input = { joyX: 0, joyY: 0 };
  scene.onKeyboardObservable.add((kbInfo) => {
    const key = kbInfo.event.key.toLowerCase();
    input[key] = kbInfo.type === BABYLON.KeyboardEventTypes.KEYDOWN;
  });

  setupTouchControls(input);

  // --- Boucle de déplacement (s'exécute APRÈS les animations) ---
  scene.registerBeforeRender(() => {
    const dt = scene.getEngine().getDeltaTime() / 1000;

    // ZQSD + WASD + flèches.
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

      // Oriente EN DOUCEUR vers la direction du mouvement (plus court chemin).
      const target = Math.atan2(move.x, move.z);
      let diff = target - player.metadata.facingY;
      while (diff > Math.PI) diff -= Math.PI * 2;
      while (diff < -Math.PI) diff += Math.PI * 2;
      player.metadata.facingY += diff * Math.min(1, dt * 12);
    }

    applyFacing(player);

    // À l'intérieur : sol plat + on reste dans la pièce. Sinon : relief de l'île.
    const interior = player.metadata.interior;
    if (interior) {
      player.position.x = Math.min(interior.maxX, Math.max(interior.minX, player.position.x));
      player.position.z = Math.min(interior.maxZ, Math.max(interior.minZ, player.position.z));
      player.position.y = interior.floorY + 0.9;
    } else {
      const groundY = Math.max(islandHeight(player.position.x, player.position.z), 0);
      player.position.y = groundY + 0.9;
    }

    camera.target = player.position.clone();

    updateAnimation(player);
  });

  return player;
}

// Remplace la capsule par un personnage .glb (à appeler depuis game.js).
// opts : { scale, yOffset, facingOffset, idleName, walkName, shadowGenerator }
export async function loadPlayerCharacter(player, scene, folder, file, opts = {}) {
  const scale = opts.scale != null ? opts.scale : 1;
  const yOffset = opts.yOffset != null ? opts.yOffset : -0.9;
  const facingOffset = opts.facingOffset != null ? opts.facingOffset : 0;

  const result = await loadGLB(scene, folder, file, {});
  const model = result.meshes[0];

  // Le modèle suit la position du joueur ; sa rotation, on la pilote nous-mêmes.
  model.parent = player;
  player.rotation.y = 0; // la capsule ne tourne plus
  model.position = new BABYLON.Vector3(0, yOffset, 0);
  model.scaling.scaleInPlace(scale); // conserve la conversion glTF (signe inclus)

  if (!model.rotationQuaternion) {
    model.rotationQuaternion = BABYLON.Quaternion.Identity();
  }

  const md = player.metadata;
  md.charModel = model;
  md.charBaseQuat = model.rotationQuaternion.clone(); // conversion de repère de base
  md.facingOffset = facingOffset;

  player.isVisible = false; // cache la capsule

  // Le personnage projette une ombre à la place de la capsule.
  if (opts.shadowGenerator) {
    result.meshes.forEach((m) => {
      if (m.getTotalVertices && m.getTotalVertices() > 0) {
        opts.shadowGenerator.addShadowCaster(m);
      }
    });
  }

  // --- Animations ---
  const groups = result.animationGroups || [];
  md.animationGroups = groups;

  const findByName = (wanted) =>
    wanted ? groups.find((g) => g.name.toLowerCase() === wanted.toLowerCase()) : null;

  md.idleAnim = findByName(opts.idleName) || null;
  md.walkAnim = findByName(opts.walkName) || null;

  for (const g of groups) {
    const n = g.name.toLowerCase();
    if (!md.idleAnim && (n.includes("idle") || n.includes("stand") || n.includes("repos"))) md.idleAnim = g;
    if (!md.walkAnim && (n.includes("walk") || n.includes("run") || n.includes("marche") || n.includes("cours"))) md.walkAnim = g;
  }
  if (!md.idleAnim && groups.length) md.idleAnim = groups[0];
  if (!md.walkAnim) md.walkAnim = md.idleAnim;

  groups.forEach((g) => g.stop());
  if (md.idleAnim) {
    md.idleAnim.start(true, 1.0, md.idleAnim.from, md.idleAnim.to, false);
    md.currentAnim = md.idleAnim;
  }

  return result;
}
