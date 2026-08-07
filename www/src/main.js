import { createGame } from "./game.js";

const loading = document.getElementById("loading");

// Affiche un message d'erreur lisible directement à l'écran
// (au lieu de rester bloqué indéfiniment sur "Chargement…").
function showError(title, detail) {
  if (!loading) return;
  loading.style.display = "flex";
  loading.style.whiteSpace = "pre-wrap";
  loading.style.fontSize = "15px";
  loading.style.lineHeight = "1.4";
  loading.style.padding = "24px";
  loading.style.textAlign = "left";
  loading.style.overflow = "auto";
  loading.textContent = "⚠️ " + title + "\n\n" + (detail || "");
}

async function start() {
  // Le moteur Babylon.js est chargé depuis un CDN : s'il manque, c'est le réseau.
  if (typeof BABYLON === "undefined") {
    showError(
      "Babylon.js n'a pas pu se charger.",
      "Vérifie ta connexion internet (le moteur est téléchargé depuis un CDN au premier lancement), puis recharge la page."
    );
    return;
  }

  const canvas = document.getElementById("renderCanvas");
  // antialias:false -> on remplace le MSAA (coûteux) par le FXAA du pipeline.
  // preserveDrawingBuffer:false -> gain de perfs connu sur mobile.
  const engine = new BABYLON.Engine(canvas, false, {
    preserveDrawingBuffer: false,
    stencil: true,
    powerPreference: "high-performance",
  });

  // Compromis netteté / fluidité sur mobile.
  // 1.5 = bon équilibre. Plus net mais plus lourd : mets 2. Plus fluide : mets 1.25 ou 1.
  const pixelRatio = Math.min(window.devicePixelRatio || 1, 1.5);
  engine.setHardwareScalingLevel(1 / pixelRatio);

  try {
    const scene = await createGame(engine, canvas);
    if (loading) loading.style.display = "none";
    engine.runRenderLoop(() => scene.render());
    window.addEventListener("resize", () => engine.resize());

    // Résolution ADAPTATIVE : si les FPS chutent, on baisse un peu la résolution
    // (image légèrement plus douce) ; si ça tourne bien, on remonte vers le net.
    // En VR, on ne touche à rien : le casque gère sa propre résolution.
    const NIVEAU_NET = 1 / pixelRatio; // le plus net autorisé
    const NIVEAU_BAS = 1.15;           // le plus "économe" autorisé
    let niveau = NIVEAU_NET;
    setInterval(() => {
      if (scene.metadata && scene.metadata.inXR) return;
      const fps = engine.getFps();
      let cible = niveau;
      if (fps < 26) cible = Math.min(NIVEAU_BAS, niveau + 0.12);
      else if (fps > 45) cible = Math.max(NIVEAU_NET, niveau - 0.06);
      if (Math.abs(cible - niveau) > 0.001) {
        niveau = cible;
        engine.setHardwareScalingLevel(niveau);
      }
    }, 2500);
  } catch (err) {
    console.error(err);
    const msg = err && err.message ? err.message : String(err);
    const stack = err && err.stack ? err.stack : "";
    showError("Erreur au démarrage du jeu.", msg + "\n\n" + stack);
  }
}

start();
