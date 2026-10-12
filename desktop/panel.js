// Interface exclusive au build PC (sans modifier l'APK Android).
(() => {
  function banner(text) {
    const el = document.createElement("div");
    el.textContent = text;
    el.style.cssText =
      "position:fixed;top:14px;right:14px;z-index:40;max-width:340px;" +
      "padding:12px 15px;border-radius:14px;background:rgba(8,27,50,.9);" +
      "color:white;font:600 14px/1.4 system-ui,sans-serif;" +
      "box-shadow:0 5px 24px rgba(0,0,0,.4)";
    document.body.appendChild(el);
    return el;
  }
  window.addEventListener("DOMContentLoaded", async () => {
    const params = new URLSearchParams(location.search);
    if (window.ileMangaPCVR && params.has("desktop")) {
      const button = document.createElement("button");
      button.textContent = "🥽 Jouer en VR avec Quest 3";
      button.title = "Ouvre le navigateur WebXR du PC. Garde l'application PC ouverte.";
      button.style.cssText =
        "position:fixed;top:14px;right:14px;z-index:42;cursor:pointer;" +
        "padding:13px 19px;border:1px solid #8ce7ff;border-radius:14px;" +
        "background:rgba(12,54,85,.92);color:#fff;font:700 15px system-ui;" +
        "box-shadow:0 8px 24px rgba(0,0,0,.4)";
      button.addEventListener("click", async () => {
        button.disabled = true;
        try { await window.ileMangaPCVR.openVR(); }
        catch (error) { alert("Impossible d'ouvrir le navigateur : " + error.message); }
        finally { button.disabled = false; }
      });
      document.body.appendChild(button);
    } else if (params.has("pcvr")) {
      const status = banner("🥽 Recherche du casque Quest 3 via WebXR…");
      try {
        const supported = !!(navigator.xr &&
          await navigator.xr.isSessionSupported("immersive-vr"));
        status.textContent = supported
          ? "🥽 Casque détecté : clique sur le bouton lunettes pour entrer en VR."
          : "VR non détectée. Démarre Quest Link / Air Link et vérifie OpenXR dans Chrome ou Edge. Le jeu reste jouable à l'écran.";
      } catch (_) {
        status.textContent = "WebXR indisponible. Vérifie Quest Link et le navigateur.";
      }
    }
  });
})();
