"use strict";

const { app, BrowserWindow, Menu, ipcMain, shell } = require("electron");
const fs = require("node:fs");
const http = require("node:http");
const path = require("node:path");

let server;
let window;
let gameUrl;

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
  ".webp": "image/webp", ".glb": "model/gltf-binary",
  ".gltf": "model/gltf+json", ".bin": "application/octet-stream",
  ".ktx2": "image/ktx2", ".hdr": "application/octet-stream",
  ".wasm": "application/wasm", ".mp3": "audio/mpeg",
  ".ogg": "audio/ogg", ".wav": "audio/wav"
};

function createLocalServer(folder) {
  const root = path.resolve(folder);
  if (!fs.existsSync(path.join(root, "index.html"))) {
    throw new Error("Fichiers du jeu introuvables : " + root);
  }
  server = http.createServer((req, res) => {
    if (req.method !== "GET" && req.method !== "HEAD") {
      res.writeHead(405); res.end(); return;
    }
    let file;
    try {
      const pathname = decodeURIComponent(new URL(req.url, "http://127.0.0.1").pathname);
      if (pathname.includes("\0")) throw new Error("Chemin invalide");
      file = path.resolve(root, "." + (pathname === "/" ? "/index.html" : pathname));
      const relative = path.relative(root, file);
      if (relative === ".." || relative.startsWith(".." + path.sep) || path.isAbsolute(relative)) {
        throw new Error("Accès hors du dossier");
      }
    } catch (_) {
      res.writeHead(400); res.end("Requête invalide"); return;
    }
    fs.stat(file, (error, stat) => {
      if (error || !stat.isFile()) {
        res.writeHead(404); res.end("Fichier introuvable"); return;
      }
      res.writeHead(200, {
        "Content-Type": MIME[path.extname(file).toLowerCase()] || "application/octet-stream",
        "Content-Length": stat.size,
        "X-Content-Type-Options": "nosniff",
        "Cache-Control": "no-cache"
      });
      if (req.method === "HEAD") { res.end(); return; }
      const stream = fs.createReadStream(file);
      stream.on("error", () => res.destroy());
      stream.pipe(res);
    });
  });
  return new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", () => {
      resolve("http://127.0.0.1:" + server.address().port);
    });
  });
}

async function openVR() {
  // Le moteur immersif est celui du navigateur PC : Electron ne garantit pas WebXR.
  await shell.openExternal(gameUrl + "/?pcvr=1");
  if (window && !window.isDestroyed()) window.minimize();
  return true;
}

async function start() {
  const gameRoot = app.isPackaged
    ? path.join(process.resourcesPath, "game")
    : path.resolve(__dirname, "../pc-site");
  gameUrl = await createLocalServer(gameRoot);
  ipcMain.handle("ile-manga:open-vr", openVR);
  Menu.setApplicationMenu(Menu.buildFromTemplate([
    { label: "Île Manga", submenu: [
      { label: "Jouer en VR (Quest Link / Air Link)", click: openVR },
      { type: "separator" },
      { label: "Quitter", role: "quit" }
    ] }
  ]));
  window = new BrowserWindow({
    width: 1440, height: 900, minWidth: 960, minHeight: 600,
    title: "Île Manga - PC / VR", backgroundColor: "#10243a",
    autoHideMenuBar: false,
    webPreferences: {
      preload: path.join(__dirname, "preload.cjs"),
      nodeIntegration: false, contextIsolation: true, sandbox: true
    }
  });
  window.webContents.setWindowOpenHandler(() => ({ action: "deny" }));
  await window.loadURL(gameUrl + "/?desktop=1");
}

app.whenReady().then(start).catch((err) => {
  console.error("Île Manga PC :", err);
  app.quit();
});
app.on("window-all-closed", () => app.quit());
app.on("before-quit", () => { if (server) server.close(); });
