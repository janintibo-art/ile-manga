// Lumières : ambiance ensoleillée + soleil directionnel avec ombres douces.

export function createLighting(scene) {
  const hemi = new BABYLON.HemisphericLight("hemi", new BABYLON.Vector3(0.2, 1, 0.1), scene);
  hemi.intensity = 0.85;
  hemi.diffuse = new BABYLON.Color3(1, 0.99, 0.92);       // lumière du ciel, chaude
  hemi.groundColor = new BABYLON.Color3(0.45, 0.52, 0.4); // léger rebond verdâtre du sol
  hemi.specular = new BABYLON.Color3(0.2, 0.2, 0.2);

  const sun = new BABYLON.DirectionalLight("sun", new BABYLON.Vector3(-0.6, -1.3, -0.8), scene);
  sun.position = new BABYLON.Vector3(70, 130, 90);
  sun.intensity = 1.25;
  sun.diffuse = new BABYLON.Color3(1, 0.97, 0.86);        // soleil légèrement doré

  const shadowGenerator = new BABYLON.ShadowGenerator(1024, sun);
  shadowGenerator.useBlurExponentialShadowMap = true;
  shadowGenerator.blurKernel = 24;     // ombres bien douces
  shadowGenerator.darkness = 0.3;

  return { hemi, sun, shadowGenerator };
}
