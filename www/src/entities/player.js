// Contrôleur du joueur : déplacement (joystick + clavier), course, saut,
// danse (emotes), orientation lissée et caméra qui suit derrière le perso.

import { islandHeight } from "../world/island.js";
import { loadGLB } from "../utils/loader.js";
import { createControls } from "../ui/controls.js";
import { obstacles } from "../world/obstacles.js";
import { createStaminaBar } from "../ui/stamina.js";

const SPEED = 3;
const SPRINT_MULT = 1.9;
const JUMP_SPEED = 7.5;
const GRAVITY = 24;
const PLAYER_RADIUS = 0.45;

// --- Endurance (sprint) ---
const STAMINA_MAX = 100;
const STAMINA_DRAIN = 28; // par seconde en sprint
const STAMINA_REGEN = 14; // par seconde au repos
const STAMINA_REARM = 20; // seuil pour pouvoir re-sprinter après épuisement

// Empêche le joueur de pénétrer dans les obstacles (cercles + boîtes, plan X-Z).
// On corrige la position en la repoussant hors de chaque zone ; deux passes
// suffisent quand des zones se touchent. Le glissement le long des murs est
// naturel (on ressort par l'axe le moins enfoncé).
function resolveCollisions(pos) {
  for (let pass = 0; pass < 2; pass++) {
    for (const o of obstacles) {
      if (o.type === "circle") {
        const dx = pos.x - o.x;
        const dz = pos.z - o.z;
        const min = o.r + PLAYER_RADIUS;
        const d2 = dx * dx + dz * dz;
        if (d2 < min * min) {
          const d = Math.sqrt(d2) || 0.0001;
          const push = (min - d) / d;
          pos.x += dx * push;
          pos.z += dz * push;
        }
      } else {
        const minx = o.x - o.hx - PLAYER_RADIUS;
        const maxx = o.x + o.hx + PLAYER_RADIUS;
        const minz = o.z - o.hz - PLAYER_RADIUS;
        const maxz = o.z + o.hz + PLAYER_RADIUS;
        if (pos.x > minx && pos.x < maxx && pos.z > minz && pos.z < maxz) {
          const pl = pos.x - minx;
          const pr = maxx - pos.x;
          const pd = pos.z - minz;
          const pu = maxz - pos.z;
          const m = Math.min(pl, pr, pd, pu);
          if (m === pl) pos.x = minx;
          else if (m === pr) pos.x = maxx;
          else if (m === pd) pos.z = minz;
          else pos.z = maxz;
        }
      }
    }
  }
}

// Oriente le modèle .glb (ou la capsule) vers la direction courante.
function applyFacing(player) {
  const md = player.metadata;
  const fy = md.facingY + md.facingOffset;
  if (md.charModel) {
    const q = BABYLON.Quaternion.RotationAxis(BABYLON.Axis.Y, fy);
    md.charModel.rotationQuaternion = q.multiply(md.charBaseQuat);
  } else {
    player.rotation.y = fy;
  }
}

// Bascule idle / marche (la danse est prioritaire le cas échéant).
function updateAnimation(player, sprint) {
  const md = player.metadata;
  if (!md.animationGroups) return;
  if (md.emoting) return;

  const target = md.moving ? md.walkAnim : md.idleAnim;
  if (target && target !== md.currentAnim) {
    if (md.currentAnim) md.currentAnim.stop();
    target.start(true, 1.0, target.from, target.to, false);
    md.currentAnim = target;
  }
  // Marche plus rapide quand on court.
  if (md.currentAnim === md.walkAnim && md.walkAnim) {
    md.walkAnim.speedRatio = sprint ? 1.6 : 1.0;
  }
}

export function createPlayer(scene, camera, shadowGenerator) {
  const player = BABYLON.MeshBuilder.CreateCapsule(
    "player",
    { radius: 0.5, height: 1.8 },
    scene
  );
  player.position.set(2, 6, 8);

  const mat = new BABYLON.StandardMaterial("playerMat", scene);
  mat.diffuseColor = new BABYLON.Color3(0.95, 0.45, 0.6);
  mat.specularColor = BABYLON.Color3.Black();
  player.material = mat;

  if (shadowGenerator) shadowGenerator.addShadowCaster(player);

  player.metadata = {
    moving: false,
    animationGroups: null,
    idleAnim: null,
    walkAnim: null,
    emoteAnims: null,
    currentAnim: null,
    currentEmote: null,
    emoting: false,
    facingY: 0,
    facingOffset: 0,
    charModel: null,
    charBaseQuat: null,
    interior: null,
    vy: 0,
    jumping: false,
    stamina: STAMINA_MAX,
    staminaMax: STAMINA_MAX,
    canSprint: true,
    staminaBar: null,
  };
  const md = player.metadata;
  md.staminaBar = createStaminaBar();

  // --- Actions ---
  const doJump = () => {
    if (!md.jumping) {
      md.vy = JUMP_SPEED;
      md.jumping = true;
    }
  };
  const doEmote = () => {
    if (!md.emoteAnims || !md.emoteAnims.length || md.emoting) return;
    const g = md.emoteAnims[Math.floor(Math.random() * md.emoteAnims.length)];
    if (md.currentAnim) md.currentAnim.stop();
    md.emoting = true;
    md.currentEmote = g;
    g.start(false, 1.0, g.from, g.to, false);
  };

  // --- Caméra qui suit derrière le perso ---
  let lastManualRotate = 0;
  let recenter = false;
  scene.onPointerObservable.add((pi) => {
    if (pi.type === BABYLON.PointerEventTypes.POINTERMOVE && pi.event.buttons > 0) {
      lastManualRotate = performance.now();
    }
  });
  const doRecenter = () => {
    recenter = true;
  };

  // --- Entrées ---
  const keys = {};
  scene.onKeyboardObservable.add((kb) => {
    const key = kb.event.key.toLowerCase();
    const down = kb.type === BABYLON.KeyboardEventTypes.KEYDOWN;
    const was = keys[key];
    keys[key] = down;
    if (down && !was) {
      if (key === " " || key === "spacebar") doJump();
      if (key === "e") doEmote();
    }
  });
  const input = createControls({ onJump: doJump, onEmote: doEmote, onRecenter: doRecenter });

  // --- Boucle ---
  scene.registerBeforeRender(() => {
    const dt = scene.getEngine().getDeltaTime() / 1000;

    let mX = 0;
    let mZ = 0;
    if (keys["z"] || keys["w"] || keys["arrowup"]) mZ += 1;
    if (keys["s"] || keys["arrowdown"]) mZ -= 1;
    if (keys["q"] || keys["a"] || keys["arrowleft"]) mX -= 1;
    if (keys["d"] || keys["arrowright"]) mX += 1;
    mX += input.moveX;
    mZ += input.moveY;

    // Magnitude analogique (joystick partiel = plus lent), bornée à 1.
    const mag = Math.hypot(mX, mZ);
    if (mag > 1) {
      mX /= mag;
      mZ /= mag;
    }
    const moving = mag > 0.12;
    md.moving = moving;

    // Endurance : on ne sprinte que s'il en reste ; sinon ça régénère.
    const wantSprint = (input.sprint || !!keys["shift"]) && moving;
    if (md.stamina <= 0) md.canSprint = false;
    else if (md.stamina >= STAMINA_REARM) md.canSprint = true;
    const sprint = wantSprint && md.canSprint;
    if (sprint) md.stamina = Math.max(0, md.stamina - STAMINA_DRAIN * dt);
    else md.stamina = Math.min(md.staminaMax, md.stamina + STAMINA_REGEN * dt);
    if (md.staminaBar) md.staminaBar.set(md.stamina / md.staminaMax, md.canSprint);

    if (moving) {
      const forward = camera.getForwardRay().direction;
      forward.y = 0;
      forward.normalize();
      const right = BABYLON.Vector3.Cross(BABYLON.Axis.Y, forward).normalize();

      const move = forward.scale(mZ).add(right.scale(mX));
      const speed = SPEED * (sprint ? SPRINT_MULT : 1);
      move.scaleInPlace(speed * dt); // garde la magnitude analogique

      player.position.x += move.x;
      player.position.z += move.z;
      if (!md.interior) resolveCollisions(player.position);

      const target = Math.atan2(move.x, move.z);
      let diff = target - md.facingY;
      while (diff > Math.PI) diff -= Math.PI * 2;
      while (diff < -Math.PI) diff += Math.PI * 2;
      md.facingY += diff * Math.min(1, dt * 12);
    }

    applyFacing(player);

    // Hauteur du sol (île ou pièce intérieure).
    let floorY;
    const interior = md.interior;
    if (interior) {
      player.position.x = Math.min(interior.maxX, Math.max(interior.minX, player.position.x));
      player.position.z = Math.min(interior.maxZ, Math.max(interior.minZ, player.position.z));
      floorY = interior.floorY + 0.9;
    } else {
      floorY = Math.max(islandHeight(player.position.x, player.position.z), 0) + 0.9;
    }

    // Saut / gravité.
    if (md.jumping) {
      md.vy -= GRAVITY * dt;
      player.position.y += md.vy * dt;
      if (player.position.y <= floorY) {
        player.position.y = floorY;
        md.vy = 0;
        md.jumping = false;
      }
    } else {
      player.position.y = floorY;
    }

    // Vise un peu au-dessus des pieds (meilleur cadrage de près).
    camera.target = player.position.add(new BABYLON.Vector3(0, 0.6, 0));

    // Caméra : recentrage demandé, sinon suivi doux quand on avance.
    const targetAlpha = Math.atan2(-Math.cos(md.facingY), -Math.sin(md.facingY));
    if (recenter) {
      let da = targetAlpha - camera.alpha;
      while (da > Math.PI) da -= Math.PI * 2;
      while (da < -Math.PI) da += Math.PI * 2;
      camera.alpha += da * Math.min(1, dt * 6);
      if (Math.abs(da) < 0.03) recenter = false;
    } else if (moving && performance.now() - lastManualRotate > 1800) {
      let da = targetAlpha - camera.alpha;
      while (da > Math.PI) da -= Math.PI * 2;
      while (da < -Math.PI) da += Math.PI * 2;
      camera.alpha += da * Math.min(1, dt * 1.3);
    }

    // Fin de la danse : terminée, ou annulée si on se déplace.
    if (md.emoting && (moving || (md.currentEmote && !md.currentEmote.isPlaying))) {
      if (md.currentEmote && moving) md.currentEmote.stop();
      md.emoting = false;
      md.currentAnim = null;
    }
    updateAnimation(player, sprint);
  });

  return player;
}

// Remplace la capsule par un personnage .glb.
// opts : { scale, yOffset, facingOffset, idleName, walkName, shadowGenerator }
export async function loadPlayerCharacter(player, scene, folder, file, opts = {}) {
  const scale = opts.scale != null ? opts.scale : 1;
  const yOffset = opts.yOffset != null ? opts.yOffset : -0.9;
  const facingOffset = opts.facingOffset != null ? opts.facingOffset : 0;

  const result = await loadGLB(scene, folder, file, {});
  const model = result.meshes[0];

  model.parent = player;
  player.rotation.y = 0;
  model.position = new BABYLON.Vector3(0, yOffset, 0);
  model.scaling.scaleInPlace(scale);

  if (!model.rotationQuaternion) {
    model.rotationQuaternion = BABYLON.Quaternion.Identity();
  }

  const md = player.metadata;
  md.charModel = model;
  md.charBaseQuat = model.rotationQuaternion.clone();
  md.facingOffset = facingOffset;

  player.isVisible = false;

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
    if (!md.walkAnim && (n.includes("walk") || n.includes("marche"))) md.walkAnim = g;
  }
  if (!md.idleAnim && groups.length) md.idleAnim = groups[0];
  if (!md.walkAnim) md.walkAnim = md.idleAnim;

  // Les autres animations servent d'emotes (danse / salut / etc.).
  md.emoteAnims = groups.filter((g) => g !== md.idleAnim && g !== md.walkAnim);

  groups.forEach((g) => g.stop());
  if (md.idleAnim) {
    md.idleAnim.start(true, 1.0, md.idleAnim.from, md.idleAnim.to, false);
    md.currentAnim = md.idleAnim;
  }

  return result;
}
