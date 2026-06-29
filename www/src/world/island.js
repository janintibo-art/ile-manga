// Île procédurale : générée entièrement par le code, sans textures au départ.
// La fonction islandHeight() est réutilisée par le joueur et le village
// pour poser les objets au sol sans raycasting (meilleure performance).

const ISLAND_SIZE = 200;
const ISLAND_HALF = ISLAND_SIZE / 2;

// Relief basé sur des sinus (aucune librairie externe).
// Les hautes fréquences sont volontairement faibles : terrain doux,
// sans "taches" de sable au milieu de l'herbe.
function noise(x, z) {
  return (
    Math.sin(x * 0.045) * Math.cos(z * 0.045) * 3.2 +
    Math.sin(x * 0.10 + 1.3) * Math.cos(z * 0.085) * 1.3 +
    Math.sin(x * 0.21) * Math.cos(z * 0.19) * 0.35
  );
}

// Hauteur du terrain en un point (x, z).
// Dôme central nettement émergé + plage en bordure, puis fond marin.
export function islandHeight(x, z) {
  const distNorm = Math.sqrt(x * x + z * z) / ISLAND_HALF;
  const falloff = Math.max(0, 1 - Math.pow(distNorm / 0.72, 2.5));
  const base = 7 * falloff - 2.2; // forme générale de l'île
  return noise(x, z) * falloff * 0.6 + base;
}

// Crée le maillage de l'île et le colore selon l'altitude.
export function createIsland(scene) {
  const ground = BABYLON.MeshBuilder.CreateGround(
    "island",
    { width: ISLAND_SIZE, height: ISLAND_SIZE, subdivisions: 160, updatable: true },
    scene
  );

  const positions = ground.getVerticesData(BABYLON.VertexBuffer.PositionKind);
  for (let i = 0; i < positions.length; i += 3) {
    positions[i + 1] = islandHeight(positions[i], positions[i + 2]);
  }
  ground.updateVerticesData(BABYLON.VertexBuffer.PositionKind, positions);
  ground.createNormals(true);

  // Matériau terrain : mélange sable / herbe / pierre selon l'altitude,
  // piloté par mix.png (R = sable, G = herbe, B = pierre).
  const dir = "assets/textures/terrain/";
  const mat = new BABYLON.TerrainMaterial("islandMat", scene);
  mat.mixTexture = new BABYLON.Texture(dir + "mix.png", scene);
  mat.diffuseTexture1 = new BABYLON.Texture(dir + "sand.jpg", scene); // canal R
  mat.diffuseTexture2 = new BABYLON.Texture(dir + "grass.jpg", scene); // canal G
  mat.diffuseTexture3 = new BABYLON.Texture(dir + "stone.jpg", scene); // canal B
  for (const t of [mat.diffuseTexture1, mat.diffuseTexture2, mat.diffuseTexture3]) {
    t.uScale = 18; // répétition (détail) sur les 200 unités de l'île
    t.vScale = 18;
    t.anisotropicFilteringLevel = 4; // sol net même en perspective rasante
  }
  mat.specularColor = new BABYLON.Color3(0, 0, 0); // rendu plat type anime
  mat.maxSimultaneousLights = 4;
  ground.material = mat;
  ground.receiveShadows = true;

  // Terrain statique : on fige matrice et matériau (gain CPU).
  ground.freezeWorldMatrix();
  mat.freeze();

  return ground;
}
