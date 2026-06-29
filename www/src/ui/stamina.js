// Petite barre d'endurance en bas de l'écran (⚡).
// set(pct, ready) : remplit la barre ; verte si on peut sprinter, rouge sinon.
// flash() : éclair bleu bref quand on ramasse une 8.6.

export function createStaminaBar() {
  const wrap = document.createElement("div");
  wrap.id = "stamina-bar";
  wrap.style.cssText =
    "position:fixed;left:50%;bottom:14px;transform:translateX(-50%);z-index:40;" +
    "width:180px;height:12px;background:rgba(0,0,0,.45);border-radius:8px;overflow:hidden;" +
    "border:1px solid rgba(255,255,255,.25);box-shadow:0 1px 4px rgba(0,0,0,.4)";
  const fill = document.createElement("div");
  fill.style.cssText =
    "height:100%;width:100%;background:#36d36b;transition:width .08s linear,background .2s";
  wrap.appendChild(fill);

  const icon = document.createElement("div");
  icon.textContent = "⚡";
  icon.style.cssText =
    "position:fixed;left:calc(50% - 106px);bottom:9px;z-index:40;font-size:16px;" +
    "filter:drop-shadow(0 1px 2px rgba(0,0,0,.6));pointer-events:none";

  document.body.appendChild(wrap);
  document.body.appendChild(icon);

  let flashUntil = 0;
  return {
    set(pct, ready) {
      fill.style.width = Math.max(0, Math.min(1, pct)) * 100 + "%";
      if (performance.now() < flashUntil) fill.style.background = "#7fe9ff";
      else fill.style.background = ready ? "#36d36b" : "#ff5a5a";
    },
    flash() {
      flashUntil = performance.now() + 350;
    },
  };
}
