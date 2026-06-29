// Petit utilitaire pour charger un modèle .glb / .gltf dans la scène.
// Gère le parent, la position, l'échelle, la rotation et les ombres.

export async function loadGLB(scene, folder, file, opts = {}) {
  const result = await BABYLON.SceneLoader.ImportMeshAsync("", folder, file, scene);
  const root = result.meshes[0];

  if (opts.parent) root.parent = opts.parent;
  if (opts.position) root.position.copyFrom(opts.position);
  if (opts.scale != null) root.scaling.scaleInPlace(opts.scale); // conserve la conversion glTF

  if (opts.rotationY != null) {
    // Les modèles glTF utilisent un quaternion : on compose au lieu d'écraser.
    if (root.rotationQuaternion) {
      root.rotationQuaternion = BABYLON.Quaternion.RotationAxis(
        BABYLON.Axis.Y,
        opts.rotationY
      ).multiply(root.rotationQuaternion);
    } else {
      root.rotation.y = opts.rotationY;
    }
  }

  if (opts.shadowGenerator) {
    result.meshes.forEach((m) => {
      if (m.getTotalVertices && m.getTotalVertices() > 0) {
        opts.shadowGenerator.addShadowCaster(m);
      }
    });
  }

  // Modèle statique : on fige matrices et matériaux pour soulager le CPU
  // (rien à recalculer chaque image). À ne PAS utiliser sur un objet animé.
  if (opts.static) {
    result.meshes.forEach((m) => {
      if (m.material && m.material.freeze) m.material.freeze();
      if (m.freezeWorldMatrix) m.freezeWorldMatrix();
    });
  }

  return result;
}
