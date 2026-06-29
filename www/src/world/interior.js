// Intérieur de maison explorable : une pièce texturée (sol bois, murs plâtre,
// plafond bois), située à l'écart du monde pour ne rien chevaucher.
// On entre/sort en marchant sur un tapis lumineux (devant la porte / à l'intérieur).

import { islandHeight } from "./island.js";

// --- Emplacement et dimensions de la pièce ---
const RX = 500; // centre X (loin de l'île)
const RZ = 500; // centre Z
const FLOOR_Y = 0; // hauteur du sol intérieur
const SIZE = 60; // côté de la pièce (immense : effet "plus grand à l'intérieur")
const HALF = SIZE / 2;
const WALL_H = 16; // hauteur des murs (hall cathédrale)
const WALL_T = 0.3; // épaisseur des murs

// --- Zones d'entrée / sortie (= position des tapis lumineux) ---
// Entrée : tapis devant la porte de la maison (ajuste X,Z si besoin).
const ENTER = new BABYLON.Vector3(5.5, 0, 4);
const ENTER_R = 2;
// Réapparition à l'intérieur, vers le fond de la pièce.
const INSIDE_SPAWN = new BABYLON.Vector3(RX, FLOOR_Y + 0.9, RZ + HALF - 6);
// Sortie : tapis près de la porte intérieure (mur +Z).
const EXIT = new BABYLON.Vector3(RX, 0, RZ + HALF - 2.5);
const EXIT_R = 2;
// Réapparition dehors, devant la maison (hors zone d'entrée).
const OUTSIDE_SPAWN = new BABYLON.Vector3(1.5, 0, 4);

function texMat(scene, name, file, uRepeat, vRepeat) {
  const m = new BABYLON.StandardMaterial(name, scene);
  const t = new BABYLON.Texture(file, scene);
  t.uScale = uRepeat;
  t.vScale = vRepeat == null ? uRepeat : vRepeat;
  t.anisotropicFilteringLevel = 4; // textures nettes dans le grand hall
  m.diffuseTexture = t;
  m.specularColor = BABYLON.Color3.Black();
  m.backFaceCulling = false; // on est à l'intérieur : visible des deux côtés
  return m;
}

// Petit tapis rond lumineux qui pulse, pour marquer une entrée/sortie.
function makeMat(scene, name, x, y, z, color) {
  const disc = BABYLON.MeshBuilder.CreateCylinder(
    name,
    { diameter: 3, height: 0.08, tessellation: 28 },
    scene
  );
  disc.position.set(x, y, z);
  const m = new BABYLON.StandardMaterial(name + "Mat", scene);
  m.diffuseColor = color.scale(0.3);
  m.emissiveColor = color; // brille tout seul
  m.specularColor = BABYLON.Color3.Black();
  disc.material = m;
  return disc;
}

export function createInterior(scene, player, camera) {
  scene.collisionsEnabled = true;

  const dir = "assets/textures/interior/";
  const floorMat = texMat(scene, "intFloorMat", dir + "floor.png", 15);
  const wallMat = texMat(scene, "intWallMat", dir + "wall.png", 9, 10);
  const ceilMat = texMat(scene, "intCeilMat", dir + "ceiling.png", 15);

  // Sol
  const floor = BABYLON.MeshBuilder.CreateGround("intFloor", { width: SIZE, height: SIZE }, scene);
  floor.position.set(RX, FLOOR_Y, RZ);
  floor.material = floorMat;

  // Plafond (normale vers le bas)
  const ceil = BABYLON.MeshBuilder.CreateGround("intCeil", { width: SIZE, height: SIZE }, scene);
  ceil.position.set(RX, FLOOR_Y + WALL_H, RZ);
  ceil.rotation.x = Math.PI;
  ceil.material = ceilMat;
  ceil.checkCollisions = true;

  // Murs
  const mkWall = (w, d, x, z) => {
    const wall = BABYLON.MeshBuilder.CreateBox(
      "intWall",
      { width: w, height: WALL_H, depth: d },
      scene
    );
    wall.position.set(x, FLOOR_Y + WALL_H / 2, z);
    wall.material = wallMat;
    wall.checkCollisions = true;
    return wall;
  };
  mkWall(SIZE, WALL_T, RX, RZ - HALF); // fond (-Z)
  mkWall(WALL_T, SIZE, RX - HALF, RZ); // gauche (-X)
  mkWall(WALL_T, SIZE, RX + HALF, RZ); // droite (+X)

  // Mur avant (+Z) avec une porte (ouverture centrale)
  const doorW = 3.2;
  const side = (SIZE - doorW) / 2;
  mkWall(side, WALL_T, RX - (doorW / 2 + side / 2), RZ + HALF);
  mkWall(side, WALL_T, RX + (doorW / 2 + side / 2), RZ + HALF);
  const lintelH = WALL_H - 3;
  const lintel = BABYLON.MeshBuilder.CreateBox(
    "intLintel",
    { width: doorW, height: lintelH, depth: WALL_T },
    scene
  );
  lintel.position.set(RX, FLOOR_Y + 3 + lintelH / 2, RZ + HALF);
  lintel.material = wallMat;
  lintel.checkCollisions = true;

  // Lumière chaude pour une ambiance cosy (portée élargie pour le grand hall).
  const lamp = new BABYLON.PointLight(
    "intLamp",
    new BABYLON.Vector3(RX, FLOOR_Y + WALL_H - 2, RZ),
    scene
  );
  lamp.diffuse = new BABYLON.Color3(1, 0.92, 0.78);
  lamp.intensity = 0.85;
  lamp.range = 80;

  // Tapis lumineux : entrée (sur l'île, devant la maison) + sortie (dans la pièce).
  const enterMat = makeMat(
    scene, "enterPad",
    ENTER.x, islandHeight(ENTER.x, ENTER.z) + 0.06, ENTER.z,
    new BABYLON.Color3(1, 0.82, 0.3) // doré
  );
  const exitMat = makeMat(
    scene, "exitPad",
    EXIT.x, FLOOR_Y + 0.05, EXIT.z,
    new BABYLON.Color3(0.4, 0.85, 1) // bleu clair
  );
  scene.registerBeforeRender(() => {
    const s = 1 + Math.sin(performance.now() * 0.004) * 0.12;
    enterMat.scaling.x = enterMat.scaling.z = s;
    exitMat.scaling.x = exitMat.scaling.z = s;
  });

  // Indice à l'écran (apparaît quand on est près d'une porte).
  const hint = document.createElement("div");
  hint.id = "door-hint";
  hint.style.cssText =
    "position:fixed;left:50%;bottom:130px;transform:translateX(-50%);z-index:45;" +
    "color:#fff;background:rgba(0,0,0,.62);padding:9px 16px;border-radius:22px;" +
    "font:600 15px system-ui,sans-serif;pointer-events:none;display:none;white-space:nowrap";
  document.body.appendChild(hint);
  const showHint = (t) => {
    if (hint.textContent !== t) hint.textContent = t;
    hint.style.display = "block";
  };
  const hideHint = () => {
    hint.style.display = "none";
  };

  // Bornes pour rester dans la pièce (utilisées par player.js).
  const bounds = {
    minX: RX - HALF + 0.6,
    maxX: RX + HALF - 0.6,
    minZ: RZ - HALF + 0.6,
    maxZ: RZ + HALF - 0.6,
    floorY: FLOOR_Y,
  };

  let inside = false;
  let lockUntil = 0;
  const dist2 = (p, q) => {
    const dx = p.x - q.x;
    const dz = p.z - q.z;
    return dx * dx + dz * dz;
  };

  let savedRadius = 12; // zoom extérieur mémorisé

  const enterRoom = () => {
    savedRadius = camera.radius;
    player.position.copyFrom(INSIDE_SPAWN);
    player.metadata.interior = bounds;
    camera.lowerRadiusLimit = 2.5;
    camera.upperRadiusLimit = 14; // on peut reculer pour admirer le grand hall
    camera.radius = 6;
    camera.checkCollisions = true;
    camera.collisionRadius = new BABYLON.Vector3(0.5, 0.5, 0.5);
    inside = true;
  };

  const leaveRoom = () => {
    player.metadata.interior = null;
    player.position.copyFrom(OUTSIDE_SPAWN);
    player.position.y = islandHeight(OUTSIDE_SPAWN.x, OUTSIDE_SPAWN.z) + 0.9;
    camera.checkCollisions = false;
    camera.lowerRadiusLimit = 3;
    camera.upperRadiusLimit = 14;
    camera.radius = savedRadius; // restitue le zoom d'avant
    inside = false;
  };

  scene.registerBeforeRender(() => {
    const now = performance.now();
    const p = player.position;
    const free = now >= lockUntil;

    if (!inside) {
      const d = dist2(p, ENTER);
      if (free && d < ENTER_R * ENTER_R) {
        enterRoom();
        lockUntil = now + 900;
        hideHint();
      } else if (d < (ENTER_R + 1.6) * (ENTER_R + 1.6)) {
        showHint("🚪 Marche sur le tapis pour entrer");
      } else {
        hideHint();
      }
    } else {
      const d = dist2(p, EXIT);
      if (free && d < EXIT_R * EXIT_R) {
        leaveRoom();
        lockUntil = now + 900;
        hideHint();
      } else if (d < (EXIT_R + 1.6) * (EXIT_R + 1.6)) {
        showHint("🚪 Marche sur le tapis pour sortir");
      } else {
        hideHint();
      }
    }
  });
}
