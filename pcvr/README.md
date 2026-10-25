# Les Mondes de Travers — Godot 4.7.2 pour PC et Quest 3

Le workflow `Build Windows EXE VR et PC` génère exactement deux exécutables :

- `Les_Mondes_de_Travers_VR_vN.exe` : PC VR OpenXR ;
- `Les_Mondes_de_Travers_PC_vN.exe` : PC Windows normal, OpenXR désactivé.

Terrain et eau sous `shaders/` ; deux niveaux de rendu dans `scripts/main.gd`.
Assets GLB originaux préparés temporairement par `stage_assets.py` depuis `www/assets/`.
Voir `../docs/PC_VR_NATIVE.md`.

V7 : détails du village dans `scripts/village_details.gd`, sans changement OpenXR.
