# Île Manga V3 — PC VR native OpenXR (Quest 3 / Meta Link / SteamVR)

La V3 remplace la petite démonstration de la V2 par une carte enrichie. La version Android, le site Babylon.js et l'ancien EXE Electron ne sont pas modifiés.

## Changements du rendu

- Terrain d'origine coloré remplacé par les **vraies textures** `grass.jpg`, `sand.jpg`, `stone.jpg` avec transitions progressives selon le relief.
- Eau texturée et légèrement animée, océan, ciel et soleil.
- Arbres avec couronnes rondes, plus proches du style manga que les anciens cônes de démonstration.
- Modèles originaux importés automatiquement sur GitHub depuis `www/assets/` : deux maisons, île flottante, héros, feu de camp, mur de son, table de mixage, distributeur et corde.
- Mode PC **Forward+** sous Vulkan, anticrénelage MSAA 4x. Les modèles sont encore lourds : baisser la qualité sera peut-être nécessaire en VR si la fluidité diminue.

**Ce n'est pas encore une copie exacte de la version Babylon.js** : le gameplay intérieur, les PNJ et les autres interactions devront être portés séparément.

## Pourquoi le Quest restait en mode écran

Sur la capture V2, le texte `Mode écran` confirme que Godot n'a pas initialisé OpenXR au démarrage. Le jeu n'apparaît pas automatiquement dans Meta tant qu'il n'est pas reconnu comme application VR externe. Godot/OpenXR sur Vulkan initialise le casque **au démarrage du processus**, pas à volonté au milieu d'une session.

1. Démarrer Meta Quest Link sur Windows.
2. Brancher le Quest 3 avec USB Link **ou** activer Air Link ; entrer dans l'environnement PC VR du casque et vérifier que Link indique une connexion active.
3. Ouvrir Meta Quest Link PC > **Paramètres > Général** et vérifier **Sources inconnues**.
4. Dans les paramètres OpenXR, rendre **Meta Quest Link** actif comme runtime (ne pas mettre SteamVR en même temps comme runtime principal).
5. Lancer ensuite `Ile_Manga_PC_VR_v3.exe` **depuis Windows**, et non le lanceur Electron V1.
6. Si l'écran affiche `OpenXR non connecté`, terminer la connexion Link puis cliquer **Reconnecter le Quest 3** ou presser **R** : le programme se ferme et redémarre en tentant de réinitialiser OpenXR.
7. Quand le casque est reconnu, l'interface Windows de secours disparaît et le suivi XR commence. Les manettes dépendent de la cartographie d'actions d'OpenXR ; si elles ne bougent pas, relever les logs.

Le bouton redémarre le programme : il ne peut pas forcer Meta Link à créer une session VR si le runtime n'est pas correctement installé/configuré.

## Ajouter l'exécutable à Meta ou SteamVR

- Avec Meta : afficher le filtre **Sources inconnues** dans la bibliothèque. Selon les versions de Meta Quest Link, utiliser le signe **+** de la bibliothèque pour chercher et ajouter manuellement l'EXE. Le nom peut être `Ile_Manga_PC_VR_v3.exe`. Les versions récentes de Link peuvent comporter des problèmes d'ajout des applications tierces. La détection ne peut pas être garantie par l'export Godot seul.
- Avec Steam : **Jeux > Ajouter un jeu non Steam** puis choisir le V3 EXE. Lancer SteamVR, l'établir comme runtime OpenXR actif, puis lancer le raccourci. Ce n'est pas une publication officielle Steam.

Ne confonds pas bibliothèque Meta et activation OpenXR : un raccourci peut exister sans que le jeu rende dans le casque.

## Compilation GitHub

Le workflow **Build PC VR OpenXR Natif EXE** publie l'artefact `ile-manga-pc-vr-openxr-natif-v3` avec le fichier `Ile_Manga_PC_VR_v3.exe`. Télécharge l'artefact du run vert et extrais-le sur Windows avant de lancer l'EXE.

Un workflow vert prouve la compilation, pas le fonctionnement dans le casque. Le test en vrai reste nécessaire.
