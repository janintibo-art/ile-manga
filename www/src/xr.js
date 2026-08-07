// Mode VR (WebXR) : pour un casque type Meta Quest, via SON navigateur.
// Si l'appareil ne gère pas la VR (téléphone), cette fonction ne change RIEN :
// le jeu reste identique. Sur casque, un bouton "lunettes" apparaît en bas à
// droite ; on se téléporte en visant le sol avec la manette (gâchette).

export async function setupXR(scene, ground) {
  try {
    if (!navigator.xr || !BABYLON.WebXRSessionManager) return null;
    const ok = await BABYLON.WebXRSessionManager.IsSessionSupportedAsync("immersive-vr");
    if (!ok) return null;

    const xr = await scene.createDefaultXRExperienceAsync({
      floorMeshes: ground ? [ground] : [],
    });

    // Drapeau lu par la résolution adaptative (le casque gère sa propre résolution).
    scene.metadata = scene.metadata || {};
    xr.baseExperience.onStateChangedObservable.add((state) => {
      scene.metadata.inXR = state === BABYLON.WebXRState.IN_XR;
    });

    console.log("WebXR prêt : bouton VR disponible.");
    return xr;
  } catch (e) {
    console.warn("WebXR indisponible :", e);
    return null;
  }
}
