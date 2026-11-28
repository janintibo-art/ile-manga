# V218 — le processeur : ce qui est loin du joueur ne travaille plus à chaque image

## Le constat (casque Quest 3 par Link, RTX 4070, 72 Hz)

- Dans le casque, le jeu tenait **36 images par seconde** au lieu de 72, et aucun réglage d'image n'y
  changeait rien (sans lissage, sans ombres, image à 85 % : toujours 36). Ce n'est donc pas la carte
  graphique qui freinait.
- Le casque laisse **13,9 ms** par image. Le cœur principal du processeur en prenait environ **12** pour les
  seuls calculs du jeu (on le voit quand le casque décroche : le jeu ne dessine plus rien et plafonne quand
  même à 85 images par seconde). Il ne restait rien pour préparer l'image : le casque retombait à la moitié.
- Le Gestionnaire des tâches affiche pourtant « 10 à 20 % » : c'est normal, un seul cœur est saturé, les
  autres attendent.

## La mesure : `tests/outils/audit_calculs.py`

Le jeu tourne sans image, au rythme du casque (72 images et 72 pas de physique par seconde), avec le
débogueur local de Godot (`-d`), qui sait relever le temps passé dans chaque fonction du jeu.

- **Le temps de travail d'une image** = le pas de physique + le pas de calculs (sans l'attente entre deux
  images). C'est ce que le cœur principal doit faire tenir dans les 13,9 ms.
- **Le relevé des fonctions** : par fichier et par fonction (en propre, avec ce qu'elle appelle, appels par
  image). Il gonfle un peu les temps : ce sont les proportions qui comptent.
- **Les familles du moteur** (particules, squelettes, animations) : on endort une famille quelques images,
  on la réveille, des dizaines de fois de suite, et on compare les médianes ; un témoin (on n'endort rien)
  donne le bruit de la mesure.
- **La veille coupée puis remise**, dans la même partie : la mesure la plus sûre de ce qu'elle rapporte.
- La machine d'essai n'est pas régulière d'une partie à l'autre (±25 %) : on compare deux relevés par leurs
  proportions, ou par les essais faits dans la même partie. `Performance.TIME_PROCESS` ne convient pas :
  ce compteur du moteur donne le pire moment de chaque seconde, pas le temps de chaque image.

## Ce que la mesure a montré

Pas un gros coupable : des centaines de petites choses qui tournaient à chaque image, où que soit le joueur.

| Quoi | Avant |
|---|---|
| Les 540 habitants et leurs visages | appelés 72 fois par seconde chacun pour répondre « je dors » ; 548 squelettes mis à jour |
| Les points d'interaction (« E : … ») | plus de 500, tous interrogés (avec leur question) deux fois par image |
| L'habitant le plus proche | cherché parmi les 540, jusqu'à trois fois par image en VR |
| Les particules calculées par le processeur | plus de 500 jeux, tous recalculés à chaque image |
| L'état du jeu (`_npc_ctx_v31`) | rebâti en entier plusieurs fois par seconde pour n'en lire que les « trouvailles » |
| Le contrôle des îles aériennes (V215) | 150 objets par image, même regard immobile |
| La sauvegarde automatique | 45 à 100 ms d'arrêt toutes les 90 secondes |
| La route des bateaux | jusqu'à plusieurs dizaines de millisecondes d'un coup |

## Ce qui a été fait

- **`veille_v218.gd`** : les habitants endormis (loin) ou rentrés chez eux passent « au ralenti » (mode de
  calcul arrêté ; la veille les visite deux fois par seconde avec le temps écoulé) ; les particules lointaines
  sont recalculées moins souvent (36, 18, 12 fois par seconde au-delà de 120, 300, 600 m), plus du tout hors
  de leur portée d'affichage ; les décors animés d'Ombrelac s'arrêtent à plus d'un kilomètre.
  - Un habitant repasse à chaque image **avant** sa distance de veille : il apparaît où et quand il
    apparaissait avant.
  - Chaque sorte d'habitant dit elle-même si elle peut passer au ralenti (`ralenti_ok_v218`) : jamais en
    conversation, en bagarre, en course.
  - On ne touche ni à `visible` ni à `set_process` des habitants (le jeu s'en sert : compagnons, arène) : la
    veille n'utilise que leur mode de calcul (`process_mode`).
- **`donjon_v35`** : une liste courte des points proches (refaite cinq fois par seconde), la distance avant
  la question, une recherche par pas de physique ; la liste entière quand on appuie pour agir.
- **`main.gd`** : `_nearest_npc_v31` une fois par pas, parmi les éveillés ; `_trouvailles_v218()` pour ceux
  qui ne veulent que les trouvailles ; les noms des objets rangés une fois.
- **`cache_v215`** : le nombre d'objets contrôlés par image suit la vitesse du regard.
- **`save_manager.gd`** : l'écriture de la sauvegarde automatique se fait à part (`WorkerThreadPool`), sur
  une copie complète de la partie ; toute lecture ou écriture attend la fin d'une écriture en cours.
- **`trafic_v103`** : la recherche de route par tranches d'une milliseconde.
- et de petits allègements : indicateurs, musique, ambiance, tours, étincelles de Port-Azur, Ventaile au nid.

## Résultat (machine d'essai, sans image)

| Endroit | V217 | V218 |
|---|---|---|
| Près de Néopolis | 16 à 20 ms | 6,3 à 7,5 ms |
| Village | 15 à 18 ms | 7,8 à 9,6 ms |
| Parc du Volcan | 14 à 17 ms | 4,8 à 5,9 ms |
| Rue de Néopolis | 15 ms | 5,5 ms |

Reste à confirmer dans le casque (une sonde qui ne fait qu'écouter : elle ne change aucun réglage).

## Pour la suite

- Ce qui reste est plat : les oiseaux autour du joueur, les navettes, la hauteur du sol (`_height_at`, une
  quarantaine d'appels par image), les habitants éveillés tout près.
- La sauvegarde automatique prend encore une quinzaine de millisecondes sur le cœur principal (rassembler la
  partie : les 540 habitants surtout).
- Ne plus jamais changer un réglage d'image depuis une sonde dans le casque (lissage, taille de l'image,
  ombres) : le casque a décroché (écran noir) juste après.
