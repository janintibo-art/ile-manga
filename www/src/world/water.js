// Eau stylisée : grand plan OPAQUE avec de légères ondulations.
// Opaque = rendu net, sans artefact de transparence qui faisait "baver"
// l'eau par-dessus le terrain.

export function createWater(scene) {
  const water = BABYLON.MeshBuilder.CreateGround(
    "water",
    { width: 700, height: 700, subdivisions: 48, updatable: true },
    scene
  );
  // Légèrement sous le niveau 0 : laisse une bande de sable visible sur la plage.
  water.position.y = -0.4;

  const mat = new BABYLON.StandardMaterial("waterMat", scene);
  mat.diffuseColor = new BABYLON.Color3(0.13, 0.5, 0.66);  // turquoise
  mat.specularColor = new BABYLON.Color3(0.5, 0.65, 0.72); // reflets de soleil
  mat.specularPower = 128;
  mat.alpha = 1; // opaque
  water.material = mat;

  // Ondulations douces (déplacement vertical des sommets).
  const positions = water.getVerticesData(BABYLON.VertexBuffer.PositionKind);
  const base = positions.slice();
  let t = 0;

  scene.registerBeforeRender(() => {
    t += scene.getEngine().getDeltaTime() * 0.0012;
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
