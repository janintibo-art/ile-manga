// PNJ guide minimal. Ce module était importé par game.js mais absent du dépôt,
// ce qui bloquait le chargement du jeu même avant la version PC.
import { islandHeight } from "./island.js";

export function createNPC(scene, player, camera, shadowGenerator) {
  const x = -6;
  const z = 10;
  const y = islandHeight(x, z);
  const root = new BABYLON.TransformNode("villageGuide", scene);
  root.position.set(x, y, z);

  const body = BABYLON.MeshBuilder.CreateCapsule(
    "guideBody", { height: 1.55, radius: 0.43, tessellation: 12 }, scene
  );
  body.position.y = 0.78;
  body.parent = root;
  const shirt = new BABYLON.StandardMaterial("guideShirt", scene);
  shirt.diffuseColor = new BABYLON.Color3(0.17, 0.65, 0.87);
  shirt.specularColor = BABYLON.Color3.Black();
  body.material = shirt;

  const head = BABYLON.MeshBuilder.CreateSphere(
    "guideHead", { diameter: 0.76, segments: 16 }, scene
  );
  head.position.y = 1.77;
  head.parent = root;
  const face = new BABYLON.StandardMaterial("guideFace", scene);
  face.diffuseColor = new BABYLON.Color3(1, 0.83, 0.26);
  face.specularColor = BABYLON.Color3.Black();
  head.material = face;

  const dark = new BABYLON.StandardMaterial("guideEyes", scene);
  dark.diffuseColor = new BABYLON.Color3(0.12, 0.16, 0.23);
  dark.specularColor = BABYLON.Color3.Black();
  for (const offset of [-0.14, 0.14]) {
    const eye = BABYLON.MeshBuilder.CreateSphere(
      "guideEye", { diameter: 0.095, segments: 8 }, scene
    );
    eye.position.set(offset, 1.84, -0.34);
    eye.parent = root;
    eye.material = dark;
  }

  if (shadowGenerator) {
    shadowGenerator.addShadowCaster(body);
    shadowGenerator.addShadowCaster(head);
  }
  const hint = document.createElement("div");
  hint.textContent = "🙂 Bienvenue sur Île Manga ! Explore l'île et trouve la maison.";
  hint.style.cssText =
    "position:fixed;bottom:115px;left:50%;transform:translateX(-50%);" +
    "padding:10px 14px;border-radius:14px;background:rgba(15,39,64,.86);" +
    "color:#fff;font:600 14px/1.35 system-ui;z-index:8;display:none;pointer-events:none";
  document.body.appendChild(hint);

  scene.registerBeforeRender(() => {
    if (!player || !player.position) return;
    const dx = player.position.x - x;
    const dz = player.position.z - z;
    const near = dx * dx + dz * dz < 20;
    const inXR = !!(scene.metadata && scene.metadata.inXR);
    hint.style.display = near && !inXR ? "block" : "none";
    root.rotation.y = Math.atan2(-dx, -dz);
  });
  return root;
}
