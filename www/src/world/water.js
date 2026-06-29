// Eau stylisée : grand plan OPAQUE avec de légères ondulations.
// Opaque = rendu net, sans artefact de transparence qui faisait "baver"
// l'eau par-dessus le terrain.

export function createWater(scene) {
  const water = BABYLON.MeshBuilder.CreateGround(
    "water",
    { width: 700, height: 700, subdivisions: 24, updatable: true },
    scene
  );
  // Légèrement sous le niveau 0 : laisse une bande de sable visible sur la plage.
  water.position.y = -0.4;

  const mat = new BABYLON.StandardMaterial("waterMat", scene);
  const tex = new BABYLON.Texture("assets/textures/water/water.jpg", scene);
  tex.uScale = 40;
  tex.vScale = 40;
  tex.anisotropicFilteringLevel = 4; // texture nette en perspective
  mat.diffuseTexture = tex;
  mat.diffuseColor = new BABYLON.Color3(0.7, 0.85, 0.95); // légère teinte fraîche
  mat.specularColor = new BABYLON.Color3(0.5, 0.65, 0.72); // reflets de soleil
  mat.specularPower = 128;
  mat.alpha = 1; // opaque
  water.material = mat;

  // Ondulations douces (déplacement vertical des sommets).
  const positions = water.getVerticesData(BABYLON.VertexBuffer.PositionKind);
  const base = positions.slice();
  let t = 0;
  let frame = 0;

  scene.registerBeforeRender(() => {
    const dt = scene.getEngine().getDeltaTime();
    t += dt * 0.0012;
    // Défilement lent de la texture (eau vivante) — chaque image, c'est léger.
    tex.uOffset += 0.00015 * dt;
    tex.vOffset += 0.0001 * dt;

    // Recalcul des vagues une image sur deux (gain CPU, invisible à l'œil).
    frame++;
    if (frame % 2 !== 0) return;
    for (let i = 0; i < positions.length; i += 3) {
      const x = base[i];
      const z = base[i + 2];
      positions[i + 1] =
        Math.sin(x * 0.12 + t) * 0.08 + Math.cos(z * 0.1 + t * 0.8) * 0.08;
    }
    water.updateVerticesData(BABYLON.VertexBuffer.PositionKind, positions);
  });

  return water;
}
