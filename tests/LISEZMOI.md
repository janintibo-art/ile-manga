# Les tests du jeu

Ces fichiers ne vont pas dans le jeu (le projet Godot est dans `pcvr/` ; ici, on est à côté) :
ils servent à vérifier chaque version avant de la livrer.

## Les séries (`series/`)

Chaque série est collée à la fin de `pcvr/scripts/main.gd` (elle voit donc tout le jeu), précédée
des outils communs (`series/_commun.gd`), et le jeu est lancé sans écran.

| Série | Ce qu'elle passe en revue |
|---|---|
| `01_demarrage` | le monde est construit, une nouvelle partie commence au village, l'heure avance, le mode testeur s'ouvre |
| `10_voyages` | toutes les îles et grandes places, et un quart des lieux de quête (un autre quart à chaque version) : on y arrive et l'on tient debout |
| `20_habitants` | tous les habitants : chacun parle et a des sujets ; un sur quatre en anglais, un sur quatre en espagnol |
| `30_maisons` | toutes les histoires de maisons : on entre, la pièce est construite |
| `40_lieux_speciaux` | souterrain du Grand Moaï, Île Pixelithique, château du comte et ses souterrains, les six donjons à énigmes |
| `50_faune_iles` | la faune V132 (village paisible, Bois-Doré, Montagne de Feu) |
| `51_faune_grande` | la faune V133 (grande île par région, Al Dente, Crayonnée) |
| `52_faune_jungle_soleils` | la faune V135 (île de la jungle ; Trois Soleils côté égyptien, maya, aztèque) |
| `60_combat` | butin et expérience, chaque arme, les six sorts, les quatre pouvoirs des sceaux |
| `70_heros` | marcher, sauter, courir, nager, tomber, lever les yeux, se relever, le niveau |
| `80_sauvegarde` | sauvegarder, nouvelle partie, recharger, copie de secours, Tout public / Public averti |
| `90_langues` | anglais et espagnol (échantillon des tables, objets, textes à trous, menu) |

Une nouvelle version ajoute sa série (`series/vNNN_sujet.gd`) ou complète une série existante.

## Lancer

    python3 tests/lancer.py                 # toutes les séries
    python3 tests/lancer.py 60_combat       # une seule
    python3 tests/lancer.py --seul ...      # une série par lancement du jeu

Un lancement du jeu sans écran coûte presque 2 minutes (construction du monde) : `lancer.py` fait
donc tourner plusieurs séries dans le même lancement. Une série qui échoue dans un groupe est
relancée seule ; seul ce résultat compte. Toute la base prend environ 25 minutes. Les séries à faire tourner toujours seules se notent dans
`isolees.txt`. Les journaux vont dans `tests/sorties/` (hors du dépôt).

Il faut Godot 4.7.2 (`~/gd/godot`, ou la variable `TESTS_GODOT`) et une copie de travail du dépôt
déjà importée (`/root/t38`, ou `TESTS_COPIE`) :

    tar --exclude=.git -cf - . | (mkdir -p /root/t38 && cd /root/t38 && tar -xf -)
    cd /root/t38 && python3 pcvr/stage_assets.py && ~/gd/godot --headless --path pcvr --import

## Outils (`outils/`)

- `verifier_workflow.py` : rejoue les contrôles de la compilation GitHub (sans l'export Windows).
- `analyser.sh fichier.gd…` : vérifie la syntaxe de scripts du jeu (et de ce qu'ils chargent).
- `rendu_faune.sh DOSSIER [nuit] espèce…` : des images des bêtes (repos, attaque) et une planche ; il faut xvfb-run.
- `zip_livraison.sh N` : le zip de livraison `ile_manga_pcvr_vN.zip` (fichiers changés, dans `ile_manga_pcvr/`).
