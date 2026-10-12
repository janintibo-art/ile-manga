"use strict";
const { contextBridge, ipcRenderer } = require("electron");
contextBridge.exposeInMainWorld("ileMangaPCVR", Object.freeze({
  openVR: () => ipcRenderer.invoke("ile-manga:open-vr")
}));
