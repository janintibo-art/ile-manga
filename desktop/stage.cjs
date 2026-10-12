"use strict";
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const source = path.join(root, "www");
const output = path.join(root, "pc-site");
const modules = path.join(__dirname, "node_modules");

function copyRequired(sourceFile, destinationFile) {
  if (!fs.existsSync(sourceFile)) throw new Error("Dépendance absente : " + sourceFile);
  fs.mkdirSync(path.dirname(destinationFile), { recursive: true });
  fs.copyFileSync(sourceFile, destinationFile);
}

function validateImports(dir) {
  for (const item of fs.readdirSync(dir, { withFileTypes: true })) {
    const target = path.join(dir, item.name);
    if (item.isDirectory()) validateImports(target);
    else if (item.isFile() && item.name.endsWith(".js")) {
      const code = fs.readFileSync(target, "utf8");
      const imported = /(?:\bfrom\s*|\bimport\s*)["'](\.{1,2}\/[^"']+)["']/g;
      for (const match of code.matchAll(imported)) {
        const destination = path.resolve(path.dirname(target), match[1]);
        if (!fs.existsSync(destination)) {
          throw new Error("Import manquant : " + path.relative(output, target) + " -> " + match[1]);
        }
      }
    }
  }
}

fs.rmSync(output, { recursive: true, force: true });
fs.cpSync(source, output, { recursive: true });
const vendorFiles = [
  ["babylonjs", "babylon.js", "babylon.js"],
  ["babylonjs-loaders", "babylonjs.loaders.min.js", "babylonjs.loaders.min.js"],
  ["babylonjs-materials", "babylonjs.materials.min.js", "babylonjs.materials.min.js"]
];
for (const [pkg, sourceFile, dest] of vendorFiles) {
  copyRequired(path.join(modules, pkg, sourceFile), path.join(output, "vendor", dest));
}

const indexFile = path.join(output, "index.html");
let html = fs.readFileSync(indexFile, "utf8");
const cdn = [
  ["https://cdn.babylonjs.com/babylon.js", "vendor/babylon.js"],
  ["https://cdn.babylonjs.com/loaders/babylonjs.loaders.min.js", "vendor/babylonjs.loaders.min.js"],
  ["https://cdn.babylonjs.com/materialsLibrary/babylonjs.materials.min.js", "vendor/babylonjs.materials.min.js"]
];
for (const [remote, local] of cdn) {
  if (!html.includes(remote)) throw new Error("Script Babylon introuvable : " + remote);
  html = html.replaceAll(remote, local);
}
const entry = '<script type="module" src="src/main.js"></script>';
if (!html.includes(entry)) throw new Error("Point d'entrée du jeu introuvable");
html = html.replace(entry, '<script defer src="desktop.js"></script>\n  ' + entry);
fs.writeFileSync(indexFile, html);
copyRequired(path.join(__dirname, "panel.js"), path.join(output, "desktop.js"));
validateImports(path.join(output, "src"));
console.log("Île Manga PC : ressources locales copiées, imports contrôlés.");
