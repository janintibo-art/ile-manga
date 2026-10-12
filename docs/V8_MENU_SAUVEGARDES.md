# Île Manga V8 : menu et sauvegardes

Deux exports : Ile_Manga_VR_v8.exe (OpenXR) et Ile_Manga_PC_v8.exe.

- Menu de démarrage : Continuer, Nouvelle partie, Charger / sauvegarder, Paramètres, Quitter.
- Six emplacements de sauvegarde dans `user://saves/slot_1.json` à `slot_6.json`.
- Autosave dans `user://saves/autosave.json`, toutes les 90 secondes de jeu.
- Chaque entrée conserve la position, l'orientation, la date et le temps de jeu.
- Les sauvegardes sont partagées par les deux exécutables du même projet Godot,
  sous réserve que leur nom d'application conduise au même chemin `user://`.
- Sur PC : souris sur le menu, Echap pour le rouvrir, F5 pour sauvegarder dans
  l'emplacement courant, F9 pour rouvrir le menu.
- En VR : menu 3D devant le casque, joystick droit vertical pour naviguer,
  gâchette droite pour confirmer. Les boutons dépendent du profil OpenXR et
  nécessitent une validation dans le casque.

La V8 corrige les erreurs GDScript V7 de typage des coordonnées et corrige les
noms du workflow, les versions des deux artefacts et la vérification du script.

Ne pas désinstaller la V5 qui fonctionne avant de confirmer que les deux
fichiers Windows de la V8 se lancent correctement.
