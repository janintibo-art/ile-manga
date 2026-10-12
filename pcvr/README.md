# Île Manga — V4 PC et Quest 3

Portage Godot OpenXR à deux modes, compilés par un seul workflow GitHub :

- `Ile_Manga_VR_v4.exe` : vrai PC VR Meta Quest Link / SteamVR.
- `Ile_Manga_PC_v4.exe` : jeu Windows 3D normal, sans OpenXR.

`stage_assets.py` copie au moment du build les modèles GLB et les textures
déjà présents dans `www/assets/` ; on n'ajoute jamais ces gros fichiers au ZIP.

`set_pc_export.py` désactive OpenXR dans la configuration CI après l'export VR.
Les tags d'export Godot `ile_manga_vr` et `ile_manga_pc` sélectionnent le mode.

Voir `../docs/PC_VR_NATIVE.md` pour la marche à suivre.
