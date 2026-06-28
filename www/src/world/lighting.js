// Lumières : ambiance douce + soleil directionnel avec ombres portées.

export function createLighting(scene) {
  const hemi = new BABYLON.HemisphericLight("hemi", new BABYLON.Vector3(0, 1, 0), scene);
  hemi.intensity = 0.75;
  hemi.diffuse = new BABYLON.Color3(1, 1, 0.96);
  hemi.groundColor = new BABYLON.Color3(0.42, 0.5, 0.42);

  const sun = new BABYLON.DirectionalLight("sun", new BABYLON.Vector3(-1, -2, -1), scene);
  sun.position = new BABYLON.Vector3(80, 140, 80);
  sun.intensity = 1.05;

  const shadowGenerator = new BABYLON.ShadowGenerator(1024, sun);
  shadowGenerator.useBlurExponentialShadowMap = true;
  shadowGenerator.blurKernel = 16;
  shadowGenerator.darkness = 0.35;

  return { hemi, sun, shadowGenerator };
}
