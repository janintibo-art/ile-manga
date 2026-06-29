// Modèles .glb décoratifs : maison détaillée + île flottante + accessoires
// d'accès à l'île (corde, échelle, chemin), avec un panneau de placement
// en direct pour positionner les accessoires facilement.

import { loadGLB } from "../utils/loader.js";
import { islandHeight } from "./island.js";
import { addBox, addCircle } from "./obstacles.js";

// Positions de départ des accessoires (réglées ensuite via le panneau).
// NB : les fichiers ont des noms inversés -> Echelle.glb = le chemin (plat),
// Chemin.glb = l'échelle (haute et fine). On corrige ici les rôles.
const PROPS = [
  { name: "Corde", file: "Corde.glb", pos: [16, 10, -9], scale: 6, rotY: 0 },
  { name: "Echelle", file: "Chemin.glb", pos: [13, 9.8, -6], scale: 5.5, rotY: 0 },
  { name: "Chemin", file: "Echelle.glb", pos: [7, 6.2, -2], scale: 4, rotY: 0 },
];

export function createDecor(scene, shadowGenerator) {
  // --- Maison détaillée (emplacement réservé du village, en 9,4) ---
  const hx = 9;
  const hz = 4;
  const hScale = 4.5;
  loadGLB(scene, "assets/models/buildings/", "Maison.glb", {
    position: new BABYLON.Vector3(hx, islandHeight(hx, hz) + 0.8 * hScale, hz),
    scale: hScale,
    rotationY: -Math.PI / 2,
    static: true,
  }).catch((e) => console.error("Maison.glb :", e));

  // Zone bloquante de la maison (le tapis d'entrée reste accessible :
  // la téléportation se déclenche avant d'atteindre ce mur).
  addBox(hx, hz, 3.4, 3.4);

  // --- Petite maison (à gauche du village) ---
  const pmX = -11;
  const pmZ = 9;
  const pmScale = 3;
  loadGLB(scene, "assets/models/buildings/", "Petite_maison.glb", {
    position: new BABYLON.Vector3(pmX, islandHeight(pmX, pmZ) + 0.748 * pmScale, pmZ),
    scale: pmScale,
    rotationY: Math.PI / 2, // oriente la façade (essaie 0, -Math.PI/2, Math.PI)
    static: true,
  }).catch((e) => console.error("Petite_maison.glb :", e));

  addBox(pmX, pmZ, 2.6, 2.6);

  // --- Île flottante dans le ciel, avec léger flottement vertical ---
  loadGLB(scene, "assets/models/buildings/", "Ile_flottante.glb", {
    position: new BABYLON.Vector3(20, 18, -15),
    scale: 12,
  })
    .then((res) => {
      const root = res.meshes[0];
      const baseY = root.position.y;
      scene.registerBeforeRender(() => {
        root.position.y = baseY + Math.sin(performance.now() * 0.0006) * 1.2;
      });
    })
    .catch((e) => console.error("Ile_flottante.glb :", e));

  // --- Mur de son sur la plage (réglages faciles ici) ---
  const murX = 0; // position sur la plage
  const murZ = 60;
  const murScale = 6;
  const murRotY = Math.PI; // orientation (essaie 0, Math.PI, Math.PI/2, -Math.PI/2)
  loadGLB(scene, "assets/models/props/", "Mur_de_son.glb", {
    position: new BABYLON.Vector3(murX, islandHeight(murX, murZ) + 0.625 * murScale, murZ),
    scale: murScale,
    rotationY: murRotY,
    static: true,
  }).catch((e) => console.error("Mur_de_son.glb :", e));

  // Zone bloquante du mur de son (large en X, fin en Z).
  addBox(murX, murZ, 5.7, 2.5);

  // --- Table de mixage à côté du mur de son ---
  const tabX = 9;
  const tabZ = 60;
  const tabScale = 2.5;
  const tabRotY = Math.PI; // même orientation que le mur (essaie 0 pour l'autre sens)
  loadGLB(scene, "assets/models/props/", "Table_de_mixage.glb", {
    position: new BABYLON.Vector3(tabX, islandHeight(tabX, tabZ) + 0.395 * tabScale, tabZ),
    scale: tabScale,
    rotationY: tabRotY,
    static: true,
  }).catch((e) => console.error("Table_de_mixage.glb :", e));

  // Zone bloquante de la table de mixage.
  addCircle(tabX, tabZ, 2.0);

  // --- Distributeur 8.6 à gauche du mur de son ---
  const distX = -9;
  const distZ = 60;
  const distScale = 1.8;
  const distRotY = Math.PI; // même orientation que le mur
  loadGLB(scene, "assets/models/props/", "Distributeur_8_6.glb", {
    position: new BABYLON.Vector3(distX, islandHeight(distX, distZ) + 0.951 * distScale, distZ),
    scale: distScale,
    rotationY: distRotY,
    static: true,
  }).catch((e) => console.error("Distributeur_8_6.glb :", e));

  // Zone bloquante du distributeur.
  addCircle(distX, distZ, 0.95);

  // --- Accessoires + panneau de placement ---
  const reg = PROPS.map((p) => ({
    name: p.name,
    root: null,
    base: null,
    ready: false,
    st: { x: p.pos[0], y: p.pos[1], z: p.pos[2], s: p.scale, rx: 0, ry: p.rotY, rz: 0 },
  }));

  PROPS.forEach((p, i) => {
    loadGLB(scene, "assets/models/props/", p.file, {
      position: new BABYLON.Vector3(p.pos[0], p.pos[1], p.pos[2]),
      scale: p.scale,
      rotationY: p.rotY,
    })
      .then((res) => {
        const e = reg[i];
        e.root = res.meshes[0];
        e.base = e.root.rotationQuaternion
          ? e.root.rotationQuaternion.clone()
          : BABYLON.Quaternion.Identity();
        e.ready = true;
      })
      .catch((err) => console.error(p.file, err));
  });

  buildPositioner(reg);
}

function buildPositioner(reg) {
  let active = 0;

  const apply = (e) => {
    if (!e.ready) return;
    e.root.position.set(e.st.x, e.st.y, e.st.z);
    e.root.scaling.set(e.st.s, e.st.s, e.st.s);
    const q = BABYLON.Quaternion.RotationYawPitchRoll(e.st.ry, e.st.rx, e.st.rz);
    e.root.rotationQuaternion = q.multiply(e.base);
  };

  const panel = document.createElement("div");
  panel.style.cssText =
    "position:fixed;top:88px;right:8px;z-index:50;display:none;background:rgba(0,0,0,.74);" +
    "color:#fff;padding:8px;border-radius:10px;font:12px system-ui,sans-serif;width:188px;user-select:none";

  const sel = document.createElement("div");
  sel.style.cssText = "display:flex;gap:4px;margin-bottom:6px";
  const selBtns = reg.map((e, i) => {
    const b = document.createElement("button");
    b.textContent = e.name;
    b.style.cssText = "flex:1;padding:5px 0;border:0;border-radius:6px;font-size:11px;color:#fff";
    b.onclick = () => {
      active = i;
      refresh();
    };
    sel.appendChild(b);
    return b;
  });

  const ctrl = document.createElement("div");
  ctrl.style.cssText =
    "display:grid;grid-template-columns:54px 1fr 1fr;gap:4px;align-items:center";
  const after = () => {
    apply(reg[active]);
    refresh();
  };
  const addRow = (label, minus, plus) => {
    const l = document.createElement("span");
    l.textContent = label;
    const bm = document.createElement("button");
    bm.textContent = "−";
    const bp = document.createElement("button");
    bp.textContent = "+";
    for (const b of [bm, bp])
      b.style.cssText = "padding:7px 0;border:0;border-radius:6px;font-size:15px;background:#556;color:#fff";
    bm.onclick = () => {
      minus();
      after();
    };
    bp.onclick = () => {
      plus();
      after();
    };
    ctrl.append(l, bm, bp);
  };
  const P = 1;
  const R = Math.PI / 12; // 15°
  addRow("X", () => (reg[active].st.x -= P), () => (reg[active].st.x += P));
  addRow("Y (haut)", () => (reg[active].st.y -= P), () => (reg[active].st.y += P));
  addRow("Z", () => (reg[active].st.z -= P), () => (reg[active].st.z += P));
  addRow("Taille", () => (reg[active].st.s /= 1.15), () => (reg[active].st.s *= 1.15));
  addRow("Rot Y", () => (reg[active].st.ry -= R), () => (reg[active].st.ry += R));
  addRow("Pencher X", () => (reg[active].st.rx -= R), () => (reg[active].st.rx += R));
  addRow("Pencher Z", () => (reg[active].st.rz -= R), () => (reg[active].st.rz += R));

  const out = document.createElement("div");
  out.style.cssText =
    "margin-top:6px;font:11px/1.35 monospace;color:#9fe;white-space:pre-wrap;word-break:break-word";

  const refresh = () => {
    const e = reg[active];
    selBtns.forEach((b, i) => {
      b.style.background = i === active ? "#2a7d5a" : "#555";
      b.style.opacity = reg[i].ready ? "1" : "0.45";
    });
    const f = (n) => Math.round(n * 100) / 100;
    const d = (r) => Math.round((r * 180) / Math.PI);
    out.textContent =
      `${e.name}${e.ready ? "" : " (chargement…)"}\n` +
      `pos: [${f(e.st.x)}, ${f(e.st.y)}, ${f(e.st.z)}]\n` +
      `scale: ${f(e.st.s)}\n` +
      `rotX:${d(e.st.rx)}  rotY:${d(e.st.ry)}  rotZ:${d(e.st.rz)}`;
  };

  const close = document.createElement("button");
  close.textContent = "✕";
  close.style.cssText =
    "position:absolute;top:3px;right:5px;border:0;background:transparent;color:#fff;font-size:15px";

  panel.append(sel, ctrl, out, close);
  document.body.appendChild(panel);

  const toggle = document.createElement("button");
  toggle.textContent = "⚙️ Placer";
  toggle.style.cssText =
    "position:fixed;top:88px;right:8px;z-index:51;padding:6px 10px;border:0;border-radius:8px;" +
    "background:rgba(0,0,0,.74);color:#fff;font-size:13px";

  const open = () => {
    panel.style.display = "block";
    toggle.style.display = "none";
    refresh();
  };
  const hide = () => {
    panel.style.display = "none";
    toggle.style.display = "block";
  };
  toggle.onclick = open;
  close.onclick = hide;
  document.body.appendChild(toggle);

  // Rafraîchit l'état "prêt" pendant le chargement des modèles.
  let ticks = 0;
  const iv = setInterval(() => {
    refresh();
    if (++ticks > 30) clearInterval(iv);
  }, 700);

  refresh();
}
