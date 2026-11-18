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
| `53_faune_nord` | la faune V136 (Île aux Moaïs, Île de la Balafre, Île de Larsen) |
| `54_faune_ciel` | la faune V137 (royaume des fées, île flottante, Astralys ; le sol des îles du ciel) |
| `55_faune_ouest` | la faune V138 (Arcanelle, Île de Braise, Hautefond) |
| `56_faune_sud` | la faune V139 (Île du Boucan, Néopolis, Sombreval, Cité des Nuées) |
| `57_faune_est` | la faune V140 (Île de Montjoie, Port-Azur, Île Pixelithique) |
| `60_combat` | butin et expérience, chaque arme, les six sorts, les quatre pouvoirs des sceaux |
| `61_coups` | les sensations des coups V141 (plier, tituber, tomber ; coup final, coup plongeant, sol frappé ; le sang en Public averti) |
| `62_geants` | l'Île des Géants V142 (la ferme, les cinq géants : leur taille, parler de loin, ils s'agenouillent, leurs pas, la nuit ; les nénuphars ; la bague, les limaces, le cache-cache ; la sauvegarde ; l'anglais) |
| `63_elements` | la magie élémentaire V143 (familles et faiblesses ; brûlure, glace, trempé ; Brisé, Vapeur, Éclats, Surcharge, Électrocuté, Gelé à cœur, Attisé ; la Foudre et sa chaîne ; les armes à élément ; la leçon de l'archimage ; la sauvegarde ; l'anglais) |
| `64_cibles` | la lisibilité et le ciblage V144 (la barre de vie : la part perdue, le nom, l'état, la faiblesse ; l'anneau de la cible ; le verrouillage : C, suivant, relâcher ; les sorts et les coups vers la cible verrouillée ; l'alerte « ! » ; l'anglais) |
| `65_roue` | la roue des sorts et les gestes V145 (les icônes ; PC : B tapé, B maintenu, la souris, Échap, le temps ralenti ; VR, gestes simulés : la gâchette tapée, la roue autour de la main, le lancer dans la direction du geste, la main levée, la main sur le cœur, la main gauche qui ne frappe plus ; l'anglais) |
| `66_perchee` | l'Île Perchée V146 (le relief, le dessous, la mesa, la chute, les Pierres-de-Ciel ; le bourg de Pile-ou-Face, ses maisons où l'on entre, la porte du saloon ; la Roue qui tourne ; les quatorze habitants et leurs corps, la Veuve Clou devant son bazar ; le bord et le filet ; la Grande Chaîne jusqu'au Ponton et retour ; la Navette des Nuées jusqu'au Mât de Hautefond ; une pépite du ruisseau ; la sauvegarde ; l'anglais) |
| `67_des` | les dés de Pile-ou-Face V147 (les faces des dés ; la règle du Menteur et vingt parties entre adversaires ; la Fosse aux Dés : la porte, on y entre, les trois tables, la Caisse, les habitués ; les jetons du jour et un lot ; douze coups au Grand Lancer, le Sept et ses gains ; une partie de Menteur jusqu'au bout ; la réputation, de pigeon à maître du jeu ; Échap pour se lever ; les pièces et une pépite misée en Public averti ; la sauvegarde ; on se lève en sortant ; l'anglais) |
| `68_blackjack` | le blackjack V148 (le sabot de quatre jeux, les valeurs, l'as souple, le blackjack, le règlement, la stratégie des voisins ; le Tripot de la Dame de Pique : la porte, on y entre, la table en demi-lune, la donneuse, Gédéon et Fanchon, la Caisse ; dix mains jusqu'au bout, tirer, rester, doubler, les comptes justes ; se lever au milieu d'une main ; sortir pendant une main ; l'anglais) |
| `69_poker` | le poker V149 (les combinaisons, de la hauteur à la quinte flush, la petite quinte, les départages ; la meilleure main de sept cartes ; des mains entières entre adversaires en Texas Hold'em et à cinq cartes, le pot juste ; l'échange ; le Saloon du Chien qui Mise, la grande table, cinq mains de Hold'em ; le Coupe-Chou et le Club des Moustaches, quatre mains à cinq cartes ; se coucher et se lever ; V150 : Joker le chien qui mise, le banjo, le pot en jetons ; l'anglais) |
| `70_sac` | le sac qui grandit V151 (32 cases au niveau 1, 90 au niveau 30 ; sac plein : rien n'entre ; Faelar refuse puis donne sa lanterne de fée ; un niveau ouvre des cases ; la grille du carnet se resserre ; la sauvegarde) |
| `71_lac` | Montjoie V152 (la cabane d'Yvon, la ferme de Gaubert, la cabane d'Odon s'ouvrent ; on entre dans le Lac des Grenouilles, on y nage à sa hauteur, on plonge, on remonte, on se hisse sur le ponton ; le menu « Voyager » du mode testeur en pages) |
| `72_tours` | Néopolis V153 (chaque tour a sa porte côté rue ; on entre dans le hall ; les collisions de la façade se coupent, celles de l'étage tiennent ; l'ascenseur : un, cinq, le dernier étage, le hall ; l'escalier ; les bureaux, la cafétéria, la salle des serveurs, la direction, les couloirs des logements ; on frappe aux portes ; un étage est toujours le même ; on ressort ; le filet de sécurité ; la sauvegarde ; l'anglais) |
| `73_quartiers` | Néopolis V155 (le rez-de-chaussée selon le quartier : le hangar du Quai, l'atelier, le comptoir de nouilles et la boutique des Ruelles, la salle de jeux des Arcades ; le karaoké, l'hôtel capsule ; une porte qui s'ouvre, l'appartement, ses habitants, ses murs ; le toit par l'ascenseur, le parapet, la longue-vue ; debout sur un toit : il se bâtit ; l'anglais) |
| `74_vie` | Néopolis V156 (les étages à part : le laboratoire, le studio de télévision, le jardin suspendu, la salle de sport, la piscine sous verrière, on descend dans le bassin ; des passants qui marchent ; les portes de l'ascenseur qui s'ouvrent et se referment ; la nuit, les bureaux se vident, le vigile et le robot de ménage ; les matières en vraies textures ; V157 : les façades et le béton de la ville en textures ; l'anglais) |
| `75_beaute` | la beauté du monde V158 (les textures du monde compressées avec leurs mipmaps, sauf l'interface, le pixel art et les découpes fines ; les cartes de relief en haute qualité ; les sols de l'île en 2048 ; le plancher des maisons du village ; une maison : le bois des meubles, les tissus, le cuir, le relief des murs, la sonde de reflets ; toutes les textures des maisons ont leur relief ; les plants de tomates des Géants sans partie vide) |
| `76_beaute_iles` | la beauté des îles V159 (le Bois-Doré : le village regroupé par matière, le toit d'écailles, le bois et la pierre en relief, on tient debout sur la place ; la Montagne de Feu : les deux rois sculptés, les orgues de basalte, la lave vivante et le bord du lac de lave, les sols volcaniques et leur relief, la pierre taillée et le fer martelé, on tient debout devant la Grande Porte ; Forgefer : la sonde de reflets, les bannières brodées ; l'Île aux Moaïs : l'eau du lac du cratère et ses roselières) |
| `77_beaute_villes` | la beauté des villes V160 (le kit des métaux : le grain, le relief et la rugosité du laiton patiné, de l'acier brossé, du fer forgé, du vert-de-gris, à Hautefond, à la Cité des Nuées, aux Strates, au Dôme d'Azur et à l'Île Perchée, les peintures restent lisses ; le mur-rideau en profondeur, des pièces derrière les vitres et le ciel dans les vitres, dans les tours des Nuées ; le soir, les pièces s'allument ; sous le Dôme, la vitre reflète la mer et des pièces sont allumées le jour ; les toiles tendues laissent passer le soleil ; les champignons lumineux des Strates, leurs taches et leurs lamelles ; les coraux du Dôme et leurs polypes) |
| `78_beaute_lieux` | la beauté des lieux V161 (la Citadelle des Nuées : la pierre vieillie, coulures, mousse et lichens ; le trône sculpté ; le lutrin et le grand livre ; les vitraux sertis de plomb ; les racines et les lianes sous l'île flottante ; l'Île des Géants : le bois peint qui s'écaille, le zinc galvanisé, le fer forgé, le caoutchouc, la terre cuite, les géraniums en fleurs, la balle ronde en spirale, la corde, la toile, le tweed ; Néopolis : les feux tricolores qui marchent, les conteneurs en tôle ondulée, le métal brossé, la rue meublée, le sol et ses plaques d'égout, avaloirs et bandes podotactiles) |
| `79_beaute_mer` | la beauté de la mer et de la jungle V162 (l'Atlantide : les colonnes ioniques sculptées et les colonnes brisées de l'avenue, la mosaïque romaine, l'or patiné et les portes de bronze, les caustiques qui ondulent sur le sol ; la jungle : le calcaire des pitons, ses cannelures, ses coulures, ses lichens) |
| `81_beaute_ports` | la beauté de Port-Azur, de la teuf et du royaume des fées V163 (Port-Azur : l'enduit vieilli des façades, les fenêtres en profondeur avec leur pièce et leurs rideaux, les dalles de calcaire blond, la pierre fine, les autres villes du kit inchangées ; la teuf : le portique et ses quatre lyres qui suivent les projecteurs, les faisceaux la nuit, les guirlandes guinguette et les fanions, les flambeaux, la banderole « DJ MISTRAL », les flight-cases et les canapés de palettes, rien sur la piste, tout sur la plage ; les fées : la prairie et le trèfle, l'herbe plus drue, les fleurs en touffes, les ruisseaux clairs, les cristaux, les racines d'Yggdrasil tournées vers dehors) |
| `82_beaute_grande` | la beauté de la Grande Île V164 (la Porte aux Quatre Sceaux sculptée : les vantaux gravés, la frise du linteau, la pierre de taille vieillie, les braseros aux flammes bleues, la porte qui s'enfonce toujours d'un bloc ; Carène : le vieux pont de chêne, les métaux vieillis, le feu de camp refait qui s'allume la nuit, les bancs de rondins, l'ancre de fer, le poêle de fonte et le fauteuil club ; Tazira : le pisé, la chaux vieillie ; Cliquetis : le monorail sur ses colonnes de fonte, la fonte vieillie ; Ramure : le sous-bois, le feu du Cercle de la Lune, la mousse, les rondins) |
| `83_beaute_iles` | la beauté d'Arcanelle, de Port-Coutelas et des Trois Soleils V165 (Arcanelle : les neuf menhirs de vraie pierre, les ruches de paille tressée, l'autel de la Pierre-Lune sculpté ; Port-Coutelas : les planches grises de sel, la peinture qui s'écaille, la vraie enclume sur son billot ; les Trois Soleils : l'enduit de terre et de chaux vieilli, le stuc rouge des Mayas, l'enduit tombé par plaques sur les briques crues ou la pierre, les briques crues, la terre cuite, la pierre volcanique rouge d'Aztlán, le dallage des places ; les jarres tournées, les fours à pain, le metate ; les donjons gardent leurs matières) |
| `84_beaute_cites` | la beauté de Pandémonia, de Montjoie et de Port-Boucan V166 (les étals sculptés : les poteaux tournés, le comptoir de planches, la toile rayée tissée et ses festons ; les fioles qui luisent, les jattes d'épices, les corbeilles de fruits ; Pandémonia : la fontaine de feu tournée, le Cœur-Brasier à godrons ; Montjoie : la fontaine du Fondateur, le puits et son treuil, le foyer et l'enclume de la forge ; Port-Boucan : la brique peinte vieillie, la baignoire-fontaine en fonte, les potagers, le faisceau du phare levé) |
| `85_beaute_astres` | la beauté d'Astralys, de Larsen et de l'Île Pixelithique V167 (Astralys : la fontaine de nacre et ses anneaux d'or flottants, le grand télescope ; Larsen : le métier à tisser, les tabourets, les djembés à cordes, les tables de bistrot sous leurs parasols, les chaises cintrées ; l'Île Pixelithique : de loin, les blocs et les strates des falaises restent visibles) |
| `86_beaute_sud` | la beauté d'Al Dente, de l'Île Crayonnée et de Sombreval V168 (Al Dente : le four à pain à la napolitaine, les feuilles à cinq lobes de la treille, les tomates rondes et leur calice ; l'Île Crayonnée garde son coloriage : un troisième sens de hachures, la pression du crayon, le grain du papier ; Sombreval : les tombes sculptées du vieux cimetière, la fontaine à sec de la place) |
| `87_maisons_sud` | on entre dans tous les bâtiments d'Al Dente, de l'Île Crayonnée et de Sombreval V169 (les portes : le Borgo, la Barque-Maison, les quatre arbres-maisons, chaque immeuble et maison de Sombreval, la gare, le beffroi ; on entre dans chaque sorte de pièce et l'on y tient debout ; l'arbre-maison dessiné comme l'île, rendu en sortant ; des histoires variées à Sombreval) |
| `88_boutiques` | on entre dans les boutiques et les bâtiments publics V170 de Pile-ou-Face, Port-Azur, Pandémonia, Montjoie et Cliquetis (chaque boutique a sa porte, plus aucune porte « fermée » à Pile-ou-Face ; on entre dans chaque métier, quelqu'un tient la boutique, on tient debout, on peut aller lui parler ; la vraie Margaux derrière son comptoir, et la vraie conversation ; pas d'alcool ; la scène du théâtre, les chambres de l'hôtel) |
| `89_lieux` | on entre dans les temples, les palais, les ateliers et les tours V171 des Trois Soleils, d'Arcanelle et de Port-Coutelas (chaque lieu a sa porte, les portes des quêtes ne bougent pas ; les cases des chinampas et la case de Brutus ; on entre dans chaque lieu, quelqu'un le tient — la vraie personne quand elle existe —, on tient debout, on peut aller lui parler) |
| `70_heros` | marcher, sauter, courir, nager, tomber, lever les yeux, se relever, le niveau |
| `80_sauvegarde` | sauvegarder, nouvelle partie, recharger, copie de secours, Tout public / Public averti |
| `90_langues` | anglais et espagnol (échantillon des tables, objets, textes à trous, menu) |

Une nouvelle version ajoute sa série (`series/vNNN_sujet.gd`) ou complète une série existante.

Les séries de la faune se posent dans un coin sauvage tiré au hasard : pour que le terrain ne décide
pas du résultat, une bête posée près du héros l'est là où la voie est libre (`_voie_libre`, dans
`_commun.gd` : ni rocher, ni arbre, ni talus entre eux), et les essais qui demandent qu'une bête
arrive jusqu'au héros (l'ours, le crocodile) recommencent ailleurs, trois fois au plus, si elle n'y
arrive pas ; les séries 63 et 64 cherchent un coin plat et dégagé (`_plat`).

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
- `rendu_faune.sh DOSSIER [nuit] espèce…` : des images des bêtes (repos, attaque) et une planche ; il faut xvfb-run. Le cadrage de chaque espèce est dans la table CADRE de `rendu_faune.gd` (distance, hauteur visée, et au besoin l'avancée du point visé, pour regarder une tête de près).
- `rendu_geants.sh DOSSIER [tout | vues | geants]` : des images de l'Île des Géants (V142 : l'île vue de haut, la ferme, le potager, le moulin, la mare, le verger, le blé ; les cinq géants de près et de loin) et des planches ; il faut xvfb-run (les nouvelles textures sont importées au besoin).
- `rendu_elements.sh DOSSIER` : des images de la magie élémentaire (V143 : un ennemi en feu, pris dans la glace, trempé ; la glace qui se brise, le nuage de vapeur, l'éclair de la Foudre qui saute d'un ennemi à l'autre) et une planche ; il faut xvfb-run.
- `rendu_cibles.sh DOSSIER` : des images de la lisibilité du combat (V144 : les barres de vie, l'anneau de la cible, l'anneau rouge du verrouillage, le « ! » de l'alerte, la faiblesse) et une planche ; il faut xvfb-run.
- `rendu_roue.sh DOSSIER` : des images de la roue des sorts (V145 : la rangée des sorts et ses icônes, la roue de l'écran, un sort inconnu, la roue autour de la main en VR) et une planche ; il faut xvfb-run.
- `rendu_perchee.sh DOSSIER [tout | ile | bourg]` : des images de l'Île Perchée (V146 : l'île de loin et de dessous, la chute, la mesa, le ruisseau, la mare ; le bourg de Pile-ou-Face, la place de la Roue, les rues, le quai, la Grande Chaîne, la chapelle) et des planches ; il faut xvfb-run.
- `rendu_fosse.sh DOSSIER [fosse | tripot | saloon | barbier]` : des images de la Fosse aux Dés (V147 ; V149 : le Saloon, le Coupe-Chou et son Terrier, une main de poker ; V148 : le Tripot de la Dame de Pique, la table de blackjack, une main : la salle, les trois tables, Monsieur Rouage, la Caisse, le Tableau des réputations ; assis aux tables, le tapis de jeu et les dés lancés) et des planches ; il faut xvfb-run.
- `rendu_maisons.sh DOSSIER [sols | maisons | sud | boutiques [début du nom]]` : des images des sols et des pièces des maisons (V169 : « sud » : les maisons d'Al Dente — chez chacun —, les arbres-maisons de l'Île Crayonnée en couleurs et en noir et blanc, les histoires de Sombreval, la gare, le beffroi ; V170 : « boutiques » : chaque boutique et bâtiment public, « ville_id » pour n'en voir qu'une partie, « nuit » pour tout voir le soir) et des planches ; il faut xvfb-run.
- `rendu_tours.sh DOSSIER [quartiers | vie | dehors]` : des images des tours de Néopolis (V153 : une entrée, le hall, l'ascenseur, les bureaux, la cafétéria, les serveurs, la direction, les logements, la vue par la fenêtre ; « quartiers », V155 : le hangar, l'atelier, les nouilles, la boutique, la salle de jeux, le karaoké, l'hôtel capsule, un appartement, deux toits ; « vie », V156 : le hall de marbre, l'ascenseur ouvert, les bureaux le jour et la nuit, le laboratoire, le studio, le jardin, la salle de sport, la piscine ; « dehors », V157 : les façades de chaque quartier vues de la rue, le jour et la nuit, et leurs fenêtres de près) et des planches ; il faut xvfb-run (les textures neo156 sont importées au besoin).
- `zip_livraison.sh N` : le zip de livraison `ile_manga_pcvr_vN.zip` (fichiers changés, dans `ile_manga_pcvr/`).
