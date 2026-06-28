// Île procédurale : générée entièrement par le code, sans textures au départ.
// La fonction islandHeight() est réutilisée par le joueur et le village
// pour poser les objets au sol sans raycasting (meilleure performance).

const ISLAND_SIZE = 200;
const ISLAND_HALF = ISLAND_SIZE / 2;

// Petit bruit basé sur des sinus : donne du relief naturel sans librairie externe.
function noise(x, z) {
  return (
    Math.sin(x * 0.05) * Math.cos(z * 0.05) * 4 +
    Math.sin(x * 0.13 + 1.3) * Math.cos(z * 0.11) * 2 +
    Math.sin(x * 0.31) * Math.cos(z * 0.27) * 0.8
  );
}

// Hauteur du terrain en un point (x, z).
// Relief + atténuation radiale (falloff) pour former une île entourée d'eau.
export function islandHeight(x, z) {
  const distNorm = Math.sqrt(x * x + z * z) / ISLAND_HALF;
  const falloff = Math.max(0, 1 - Math.pow(distNorm / 0.7, 3));
  return noise(x, z) * falloff + 6 * falloff - 2;
}

// Crée le maillage de l'île et le colore selon l'altitude (sable, herbe, roche).
export function createIsland(scene) {
  const ground = BABYLON.MeshBuilder.CreateGround(
    "island",
    { width: ISLAND_SIZE, height: ISLAND_SIZE, subdivisions: 128 },
    scene
  );

  const positions = ground.getVerticesData(BABYLON.VertexBuffer.PositionKind);
  const colors = [];

  for (let i = 0; i < positions.length; i += 3) {
    const x = positions[i];
    const z = positions[i + 2];
    const h = islandHeight(x, z);
    positions[i + 1] = h;

    let c;
    if (h < 0.4) c = [0.93, 0.86, 0.63]; // sable
    else if (h < 4) c = [0.45, 0.72, 0.36]; // herbe
    else if (h < 8) c = [0.34, 0.56, 0.29]; // herbe foncée
    else c = [0.78, 0.79, 0.82]; // roche

    colors.push(c[0], c[1], c[2], 1);
  }

  ground.updateVerticesData(BABYLON.VertexBuffer.PositionKind, positions);
  ground.setVerticesData(BABYLON.VertexBuffer.ColorKind, colors);
  ground.createNormals(true);
  ground.useVertexColors = true;

  const mat = new BABYLON.StandardMaterial("islandMat", scene);
  mat.diffuseColor = new BABYLON.Color3(1, 1, 1);
  mat.specularColor = new BABYLON.Color3(0, 0, 0); // pas de reflet : rendu plat type anime
  ground.material = mat;
  ground.receiveShadows = true;

  return ground;
}
