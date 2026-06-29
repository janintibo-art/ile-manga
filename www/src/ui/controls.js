// Contrôles tactiles : joystick analogique flottant, boutons d'action
// (Courir / Saut / Danse) et un menu. Renvoie un objet `input` que le
// contrôleur du joueur lit chaque frame : { moveX, moveY, sprint }.
// callbacks : { onJump, onEmote, onRecenter }

export function createControls(callbacks = {}) {
  const onJump = callbacks.onJump || (() => {});
  const onEmote = callbacks.onEmote || (() => {});
  const onRecenter = callbacks.onRecenter || (() => {});

  // Cache l'ancien HUD statique et l'ancien joystick.
  const oldHud = document.getElementById("hud");
  if (oldHud) oldHud.style.display = "none";
  const oldJoy = document.getElementById("joystick");
  if (oldJoy) oldJoy.style.display = "none";

  const input = { moveX: 0, moveY: 0, sprint: false };

  // ---------- Joystick flottant (moitié gauche de l'écran) ----------
  const MAXR = 36;
  const zone = document.createElement("div");
  zone.style.cssText =
    "position:fixed;left:0;bottom:0;width:50%;height:58%;z-index:8;touch-action:none";
  const base = document.createElement("div");
  base.style.cssText =
    "position:fixed;width:100px;height:100px;margin:-50px 0 0 -50px;border-radius:50%;" +
    "border:2px solid rgba(255,255,255,.5);background:rgba(255,255,255,.12);z-index:8;display:none;pointer-events:none";
  const knob = document.createElement("div");
  knob.style.cssText =
    "position:fixed;width:44px;height:44px;margin:-22px 0 0 -22px;border-radius:50%;" +
    "background:rgba(255,255,255,.5);z-index:9;display:none;pointer-events:none";

  let joyId = null;
  let bx = 0;
  let by = 0;
  const showJoy = (x, y) => {
    bx = x;
    by = y;
    base.style.left = knob.style.left = x + "px";
    base.style.top = knob.style.top = y + "px";
    base.style.display = knob.style.display = "block";
  };
  const moveJoy = (x, y) => {
    const dx = x - bx;
    const dy = y - by;
    const dist = Math.hypot(dx, dy);
    const m = Math.min(dist, MAXR);
    const a = Math.atan2(dy, dx);
    const kx = Math.cos(a) * m;
    const ky = Math.sin(a) * m;
    knob.style.left = bx + kx + "px";
    knob.style.top = by + ky + "px";
    input.moveX = kx / MAXR;
    input.moveY = -ky / MAXR; // haut de l'écran = vers l'avant
  };
  const endJoy = () => {
    joyId = null;
    base.style.display = knob.style.display = "none";
    input.moveX = 0;
    input.moveY = 0;
  };
  zone.addEventListener("pointerdown", (e) => {
    joyId = e.pointerId;
    zone.setPointerCapture(e.pointerId);
    showJoy(e.clientX, e.clientY);
    moveJoy(e.clientX, e.clientY);
    e.preventDefault();
  });
  zone.addEventListener("pointermove", (e) => {
    if (e.pointerId !== joyId) return;
    moveJoy(e.clientX, e.clientY);
    e.preventDefault();
  });
  const jend = (e) => {
    if (e.pointerId !== joyId) return;
    endJoy();
  };
  zone.addEventListener("pointerup", jend);
  zone.addEventListener("pointercancel", jend);

  // ---------- Boutons d'action (bas droite) ----------
  const mkBtn = (label, sub) => {
    const b = document.createElement("button");
    b.innerHTML =
      label + (sub ? `<span style="display:block;font-size:10px;opacity:.85">${sub}</span>` : "");
    b.style.cssText =
      "width:66px;height:66px;border-radius:50%;border:0;background:rgba(0,0,0,.42);color:#fff;" +
      "font:600 22px system-ui;display:flex;flex-direction:column;align-items:center;justify-content:center;touch-action:none";
    b.addEventListener("contextmenu", (e) => e.preventDefault());
    return b;
  };
  const btnWrap = document.createElement("div");
  btnWrap.style.cssText =
    "position:fixed;right:18px;bottom:calc(env(safe-area-inset-bottom,0px) + 26px);z-index:9;" +
    "display:flex;flex-direction:column;gap:12px;align-items:center";
  const btnDance = mkBtn("🕺", "Danse");
  const btnJump = mkBtn("⬆️", "Saut");
  const btnRun = mkBtn("🏃", "Courir");
  btnWrap.append(btnDance, btnJump, btnRun);

  const tap = (btn, fn) =>
    btn.addEventListener("pointerdown", (e) => {
      e.preventDefault();
      fn();
    });
  tap(btnJump, onJump);
  tap(btnDance, onEmote);

  // Courir = maintenir
  btnRun.addEventListener("pointerdown", (e) => {
    e.preventDefault();
    btnRun.setPointerCapture(e.pointerId);
    input.sprint = true;
  });
  const runUp = () => {
    input.sprint = false;
  };
  btnRun.addEventListener("pointerup", runUp);
  btnRun.addEventListener("pointercancel", runUp);

  // ---------- Menu (bouton + panneau) ----------
  const menuBtn = document.createElement("button");
  menuBtn.textContent = "☰ Menu";
  menuBtn.style.cssText =
    "position:fixed;top:calc(env(safe-area-inset-top,0px) + 10px);left:12px;z-index:12;" +
    "padding:8px 12px;border:0;border-radius:10px;background:rgba(0,0,0,.5);color:#fff;font:600 14px system-ui";

  const overlay = document.createElement("div");
  overlay.style.cssText =
    "position:fixed;inset:0;z-index:20;display:none;align-items:center;justify-content:center;background:rgba(0,0,0,.55)";
  const card = document.createElement("div");
  card.style.cssText =
    "background:#10243a;color:#fff;padding:20px;border-radius:16px;width:min(86vw,340px);" +
    "font:14px/1.5 system-ui;box-shadow:0 12px 40px rgba(0,0,0,.5)";
  card.innerHTML =
    '<h2 style="margin:0 0 10px;font-size:18px">🏝️ Île Manga</h2>' +
    '<p style="opacity:.85;margin:0 0 6px">Déplacement : joystick (gauche) ou ZQSD / WASD.<br>' +
    "Caméra : glisser à droite (elle suit le perso quand tu avances).<br>" +
    "Zoom : pincer. Boutons : 🏃 Courir · ⬆️ Saut · 🕺 Danse.</p>";
  const mkItem = (txt) => {
    const b = document.createElement("button");
    b.textContent = txt;
    b.style.cssText =
      "width:100%;padding:11px;margin-top:8px;border:0;border-radius:10px;background:#1d4e7a;color:#fff;font:600 14px system-ui";
    return b;
  };
  const itResume = mkItem("▶️ Reprendre");
  const itRecenter = mkItem("🎥 Recentrer la caméra");
  const itFs = mkItem("⛶ Plein écran");
  card.append(itResume, itRecenter, itFs);
  overlay.appendChild(card);

  menuBtn.onclick = () => (overlay.style.display = "flex");
  const closeMenu = () => (overlay.style.display = "none");
  itResume.onclick = closeMenu;
  overlay.addEventListener("pointerdown", (e) => {
    if (e.target === overlay) closeMenu();
  });
  itRecenter.onclick = () => {
    onRecenter();
    closeMenu();
  };
  itFs.onclick = () => {
    if (!document.fullscreenElement) document.documentElement.requestFullscreen?.();
    else document.exitFullscreen?.();
  };

  document.body.append(zone, base, knob, btnWrap, menuBtn, overlay);
  return input;
}
