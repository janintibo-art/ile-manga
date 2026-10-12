# Île Manga — édition PC VR native OpenXR (V2)

## Pourquoi une nouvelle édition ?

Le premier `.exe` dans `desktop/` chargeait l'ancien jeu Babylon.js dans
Electron, puis ouvrait un navigateur pour WebXR. Il ne lançait pas de session VR
Windows native. Ajouter ce fichier à la bibliothèque Meta ou Steam ne suffisait
pas à l'afficher dans le casque.

La V2 est un **nouveau portage Godot 4.7.2 avec OpenXR**, lancé directement
comme une application PC VR. Elle ne nécessite pas de navigateur.

## État de cette première version

- Terrain de l'île recréé à partir de la formule du jeu original.
- Ciel, océan, feu central, arbres stylisés, éclairages.
- Réutilisation des véritables modèles `Maison.glb`, `Petite_maison.glb`,
  `Ile_flottante.glb` et `hero.glb` présents dans le dépôt.
- Suivi stéréo du Quest 3 via OpenXR, si le runtime Windows est actif.
- Positions des deux manettes, marche au joystick gauche, rotation par paliers
  au joystick droit (suivant la carte d'actions OpenXR par défaut de Godot).
- Mode écran clavier/souris en secours pour diagnostiquer les démarrages.
- Un seul exécutable Windows exporté avec le fichier PCK intégré.

**Il ne s'agit pas encore d'un portage complet du gameplay Babylon.js.** Les
intérieurs, quêtes, PNJ évolués, animations et autres modèles n'y sont pas encore
reproduits. La priorité de V2 est **un casque reconnu par une vraie application
OpenXR**, puis l'ajout progressif des fonctionnalités de l'île. Seul un essai
sur ton casque permet de confirmer que le runtime et les contrôleurs fonctionnent.

## Télécharger

1. Après un `push` sur `main`, aller dans **GitHub > Actions**.
2. Choisir **Build PC VR OpenXR Natif EXE** puis le run vert.
3. Sous **Artifacts**, télécharger `ile-manga-pc-vr-openxr-natif-v2`.
4. Extraire le ZIP GitHub sur le PC (ne pas lancer le fichier dans l'archive).
5. Lancer `Ile_Manga_PC_VR_v2.exe` avec le Quest 3 connecté.

L'ancien `.exe` Electron est encore fourni par l'autre workflow pour préserver
la version écran précédente. Ne pas confondre les deux artefacts.

## Avec la bibliothèque Meta Quest Link PC

1. Sur le PC Windows, ouvrir **Meta Quest Link**, puis **Paramètres > Général**.
2. Autoriser les **Sources inconnues** (pour lancer ses propres jeux PC VR).
3. Relier le Quest 3 en **Quest Link** (câble USB) ou **Air Link**.
4. Vérifier que **Meta Quest Link** est le runtime OpenXR actif dans les
   paramètres de l'application PC.
5. Une fois connecté au mode PC VR, lancer l'EXE natif V2 **une première fois
   depuis Windows**.
6. Chercher ensuite **Ile_Manga_PC_VR_v2.exe** dans la bibliothèque Meta avec
   l'affichage des applications inconnues activé. Sa présence dépend des
   modalités de détection du logiciel Meta : ce n'est pas un ajout automatique
   garanti par la compilation.

Le jeu doit être lancé pendant que Quest Link et le casque sont connectés. En
cas de démarrage seulement à l'écran, fermer l'EXE, vérifier l'OpenXR runtime,
puis relancer. Le mode écran est un secours volontaire, pas une vraie session VR.

## Avec SteamVR

1. Connecter le casque au PC et lancer **SteamVR**.
2. Dans SteamVR > Paramètres > OpenXR, sélectionner **SteamVR comme runtime
   OpenXR actif** (l'option précise varie selon les versions).
3. Dans Steam sur PC, utiliser **Ajouter un jeu > Ajouter un jeu non Steam**.
4. Pointer vers `Ile_Manga_PC_VR_v2.exe`, puis lancer ce raccourci avec SteamVR
   et le casque actifs. Cette opération ajoute un raccourci, pas une fiche
   officielle Steam ni une publication sur le magasin.

Un seul runtime OpenXR doit être actif : Meta pour Quest Link direct, ou
SteamVR si tu préfères sa bibliothèque. Il n'est pas nécessaire de lancer les
DEUX runtimes en même temps pour la même partie.

## Commandes en cas d'erreur

- Réessayer avec le casque et le logiciel PC Link **déjà connectés**.
- Si écran uniquement : vérifier le **runtime OpenXR actif**.
- Si crash Windows : depuis PowerShell, lancer l'EXE avec `--verbose`, garder
  le texte du terminal et envoyer une capture du premier message d'erreur.
- Si GitHub échoue : envoyer le nom de la première étape rouge et ses logs.

Le dépôt original `www/`, le pipeline APK, les modèles et le lanceur Electron ne
sont **pas remplacés**. Seuls des fichiers sous `pcvr/`, un workflow et ce guide
sont ajoutés.
