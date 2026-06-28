// Ciel dégradé façon anime.
// Le dégradé est dessiné sur une petite texture dynamique (moteur de base
// uniquement, aucune bibliothèque externe : robuste même en cas de réseau lent).

export function createSky(scene) {
  const dome = BABYLON.MeshBuilder.CreateSphere(
    "sky",
    { diameter: 1000, segments: 24 },
    scene
  );

  // Texture verticale : bleu en haut, pâle vers l'horizon.
  const tex = new BABYLON.DynamicTexture("skyTex", { width: 16, height: 256 }, scene, false);
  const ctx = tex.getContext();
  const grad = ctx.createLinearGradient(0, 0, 0, 256);
  grad.addColorStop(0, "#4a8cf2"); // haut
  grad.addColorStop(1, "#dbeeff"); // bas (horizon)
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, 16, 256);
  tex.update();

  const mat = new BABYLON.StandardMaterial("skyMat", scene);
  mat.backFaceCulling = false;   // on voit l'intérieur du dôme
  mat.disableLighting = true;    // couleur pure, non éclairée
  mat.emissiveTexture = tex;     // le dégradé EST la couleur du ciel
  mat.diffuseColor = new BABYLON.Color3(0, 0, 0);
  dome.material = mat;

  dome.infiniteDistance = true;  // suit la caméra (effet skybox)
  dome.isPickable = false;

  return dome;
}
