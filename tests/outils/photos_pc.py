#!/usr/bin/env python3
"""Les photos de contrôle sur le PC de l'auteur (V182) : prépare ce qu'on dépose dans le dossier
Mondes_de_Travers_controle du PC.

    python3 tests/outils/photos_pc.py SORTIE LISTE.json

SORTIE reçoit :
  - main.gd : le main.gd du dépôt, puis tests/series/_commun.gd et tests/outils/photos_pc.gd (comme une
    série) : à déposer dans jeu/scripts/main.gd ;
  - project.godot : celui du dépôt, mais ses sauvegardes à part (IleManga_controle : les parties du vrai
    jeu ne sont pas touchées), à déposer dans jeu/project.godot ;
  - photos_liste.json : la liste des photos (voir photos_pc.gd), à déposer à côté du dossier jeu.
Sur le PC, 3_photos.bat lance le jeu ; les photos arrivent dans le dossier photos.
"""
import json
import os
import re
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(ICI))


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 1
    sortie, liste = sys.argv[1], sys.argv[2]
    os.makedirs(sortie, exist_ok=True)
    lire = lambda p: open(p, encoding="utf-8").read()
    main_gd = lire(os.path.join(REPO, "pcvr/scripts/main.gd"))
    commun = lire(os.path.join(REPO, "tests/series/_commun.gd"))
    photos = lire(os.path.join(ICI, "photos_pc.gd"))
    with open(os.path.join(sortie, "main.gd"), "w", encoding="utf-8", newline="\n") as f:
        f.write(main_gd + "\n\n" + commun + "\n\n" + photos)
    projet = lire(os.path.join(REPO, "pcvr/project.godot"))
    projet = re.sub(r'config/custom_user_dir_name="[^"]*"', 'config/custom_user_dir_name="IleManga_controle"', projet)
    projet = re.sub(r'config/name="([^"]*)"', r'config/name="\1 (controle)"', projet, count=1)
    with open(os.path.join(sortie, "project.godot"), "w", encoding="utf-8", newline="\n") as f:
        f.write(projet)
    donnees = json.load(open(liste, encoding="utf-8"))
    with open(os.path.join(sortie, "photos_liste.json"), "w", encoding="utf-8") as f:
        json.dump(donnees, f, ensure_ascii=False, indent=1)
    print("prêt :", sortie, len(donnees), "entrées")
    return 0


if __name__ == "__main__":
    sys.exit(main())
