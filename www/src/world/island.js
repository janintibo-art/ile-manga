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
  const colors = [];

  for (let i = 0; i < positions.length; i += 3) {
    const x = positions[i];
    const z = positions[i + 2];
    const h = islandHeight(x, z);
    positions[i + 1] = h;

    let c;
    if (h < 0.6) c = [0.94, 0.87, 0.66];      // sable clair (plage)
    else if (h < 1.4) c = [0.74, 0.78, 0.5];  // herbe sèche (transition douce)
    else if (h < 4.2) c = [0.42, 0.7, 0.34];  // herbe
    else if (h < 6.5) c = [0.3, 0.55, 0.28];  // herbe foncée / forêt
    else c = [0.62, 0.6, 0.58];               // roche (sommets)

    colors.push(c[0], c[1], c[2], 1);
  }

  ground.updateVerticesData(BABYLON.VertexBuffer.PositionKind, positions);
  ground.setVerticesData(BABYLON.VertexBuffer.ColorKind, colors);
  ground.createNormals(true);
  ground.useVertexColors = true;

  const mat = new BABYLON.StandardMaterial("islandMat", scene);
  mat.diffuseColor = new BABYLON.Color3(1, 1, 1);
  mat.specularColor = new BABYLON.Color3(0, 0, 0); // rendu plat type anime
  ground.material = mat;
  ground.receiveShadows = true;

  return ground;
}
