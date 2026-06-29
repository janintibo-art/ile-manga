// Registre partagé des zones bloquantes (collisions simples, peu coûteuses).
// Chaque obstacle est un cercle ou une boîte (vu de dessus, plan X-Z).
// player.js empêche le joueur d'y pénétrer.

export const obstacles = [];

export function addCircle(x, z, r) {
  obstacles.push({ type: "circle", x, z, r });
}

export function addBox(x, z, hx, hz) {
  obstacles.push({ type: "box", x, z, hx, hz });
}

export function clearObstacles() {
  obstacles.length = 0;
}
