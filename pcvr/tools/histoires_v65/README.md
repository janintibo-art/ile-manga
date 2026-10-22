# Histoires des habitants (V65)

Les fiches d'histoire des 211 personnages sont dans `pcvr/data/histoires_v65/<groupe>.json`
(une par village : heros, azur, teuf, carene, tazira, cliquetis, ramure, elfes, nains, atlantes, fees).
Le jeu les lit au démarrage (`scripts/pnj/societe_v65.gd`) ; le cerveau (`scripts/pnj/pnj_brain_v31.gd`)
s'en sert pour l'histoire en chapitres, les gens connus, le rêve, la question au joueur, les échos et
les nouvelles ; `scripts/pnj/bavardages_v65.gd` pour les bavardages entre habitants.

- `consignes.md`, `format.md`, `quetes.md` : les règles d'écriture et le format d'une fiche.
- `bible/` : le plan de Port-Azur, Tazira, Ramure et Cliquetis (faits partagés, liens des deux côtés).
- `roster.json` : identifiant, nom, titre et groupe de chaque personnage.
- `valider.py fichier.json` : vérifie une fiche (longueurs, variables, liens, réciprocité).
- `qa.py` : contrôles d'ensemble sur les fichiers du jeu (noms, doublons, statistiques).
- `fusion.py` : rassemble des fiches écrites par lots (`out/*.json`) dans `pcvr/data/histoires_v65/`.

Pour ajouter un habitant : écrire sa fiche selon `format.md`, ajouter son identifiant à `roster.json`,
ajouter le lien réciproque chez les personnes qu'il connaît, puis `python3 valider.py` sur le fichier.
