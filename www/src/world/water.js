// Eau stylisée : grand plan translucide avec légères vagues animées.

export function createWater(scene) {
  const water = BABYLON.MeshBuilder.CreateGround(
    "water",
    { width: 400, height: 400, subdivisions: 40 },
    scene
  );
  water.position.y = 0;

  const mat = new BABYLON.StandardMaterial("waterMat", scene);
  mat.diffuseColor = new BABYLON.Color3(0.12, 0.5, 0.72);
  mat.specularColor = new BABYLON.Color3(0.35, 0.55, 0.65);
  mat.specularPower = 64;
  mat.alpha = 0.78;
  water.material = mat;

  // Animation des vagues (déplacement vertical des sommets).
  const positions = water.getVerticesData(BABYLON.VertexBuffer.PositionKind);
  const base = positions.slice();
  let t = 0;

  scene.registerBeforeRender(() => {
    t += scene.getEngine().getDeltaTime() * 0.001;
    for (let i = 0; i < positions.length; i += 3) {
      const x = base[i];
      const z = base[i + 2];
      positions[i + 1] = Math.sin(x * 0.08 + t) * 0.35 + Math.cos(z * 0.08 + t * 0.8) * 0.35;
    }
    water.updateVerticesData(BABYLON.VertexBuffer.PositionKind, positions);
  });

  return water;
}
