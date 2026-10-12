# Île Manga V10 — menu panoramique animé

- Panorama **3D en temps réel** visible derrière le menu PC : caméra lente indépendante, sans modifier la position sauvegardée du personnage.
- Menu PC semi-transparent bleu nuit et or, logo existant, apparition douce, boutons soignés.
- Navigation VR 3D d'origine conservée, sans mouvement artificiel de caméra (confort).
- Six sauvegardes V8/V9 conservées (`user://saves`), pas de remise à zéro.
- Exports VR et PC distincts, uniquement des fichiers Windows EXE.

## Installation

Depuis la racine du dépôt, après extraction de `ile_manga_v10.zip` :

```sh
python3 pcvr/apply_v10.py
```

Le script vérifie les marqueurs V9. Il s'arrête si la base a changé au lieu d'écraser arbitrairement les fichiers.

## Test après compilation

PC : lancer l'EXE, vérifier le panorama lent, Nouvelle partie, sauvegarde/chargement et retour au menu (Échap).
VR : vérifier que le menu ne fait pas tourner la tête et que manettes, joystick et sauvegardes fonctionnent.
