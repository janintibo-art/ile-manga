# Extension « Le Château d'Ombrelac »

Une nouvelle île tout au nord de l'archipel (au nord de l'Île aux Moaïs), avec un château géant à
explorer : l'Académie d'Ombrelac. Tout est original (noms, architecture, textures).

## Ce qu'il y a sur l'île

- **Le relief** : les Monts Gris au nord (forêts d'épicéas, lande de bruyère), le **Lac d'Ombre**
  au milieu (sombre et profond), la **gorge du Torrent** qui vide le lac dans la mer, la **Colline
  du Guet** au sud, le **débarcadère** et la route en lacets qui monte jusqu'au Guet.
- **Le Roc d'Ombrelac** : un éperon de roche aux falaises à pic, plongeant dans le lac ; tout en
  haut, à 52 m, le château.
- **Le château** (environ 150 m de large ; le haut de la flèche du donjon à plus de 180 m au-dessus
  de la mer) :
  - l'enceinte crénelée et ses tours rondes, tout autour du plateau ;
  - la **Porte du Viaduc** (deux grosses tours, la herse) et le **grand viaduc** de sept arches qui
    enjambe la gorge depuis la Colline du Guet, avec ses lanternes ;
  - la **Cour d'Honneur** ;
  - la **Grande Salle** : contreforts, hautes baies en vitraux, rose à l'est, flèche ajourée sur le
    toit, grand porche voûté. **On y entre** : murs épais percés de leurs baies, dallage, plafond
    lambrissé peint et charpente à blochets, estrade et table d'honneur, trois longues tables avec
    leurs bancs, la vaisselle dorée et les chandeliers, la grande cheminée à hotte et son feu,
    quatre lustres de fer à bougies, les bannières de l'Académie, le tapis de l'allée. Le jour, les
    vitraux flamboient vus du dedans ; la nuit, les bougies éclairent davantage ;
  - la **Tour de l'Astrolabe** (le donjon) : carrée, puis octogonale, puis une flèche d'ardoise ;
  - la **Tour de l'Horloge** et ses quatre cadrans dorés ;
  - l'**Aile des Dortoirs**, la **Grosse Tour** du nord-est ;
  - l'**Aile des Études**, qui abrite la **Bibliothèque de l'Académie** (**on y entre**, par la
    cour) : une grande salle sur toute la hauteur, deux rangs de baies, des épis de rayonnages
    chargés de livres, une table de lecture et sa lampe à abat-jour vert dans chaque alcôve, une
    longue table dans l'allée, une galerie de chêne tout autour (on peut y monter par le grand
    escalier), l'échelle de bibliothèque, la sphère armillaire, les lanternes, le plafond peint ;
  - le **Cloître** (galeries d'arcades, jardin, fontaine) ;
  - la **Tour des Sortilèges**, au-dessus du lac ;
  - le **Pont Couvert**, qui file au-dessus du lac jusqu'à la **Tour des Vents**, sur l'Aiguille ;
  - les **Serres** de la terrasse est.
- **Les graphismes** : toits d'ardoises taillées en écailles (shader), pierre de taille vieillie
  (coulures, mousse, lichens), baies en ogive à petits losanges sertis de plomb, vitraux de couleur,
  fenêtres qui s'allument le soir (lumière de bougie qui vacille) et s'éteignent à l'aube, eau sombre
  du lac et du torrent.
- **Dans le jeu** : on y va en bateau (la mer de l'île rejoint celle de l'Île aux Moaïs) ; on peut
  ensuite s'y téléporter (le débarcadère, la Cour d'Honneur) ; les lieux ont leur nom dans le carnet ;
  la visite est enregistrée avec la partie.

Pour la suite (pas encore faits) : les autres intérieurs (les salles d'étude, les dortoirs, les
tours), les habitants de l'Académie, les cours et les quêtes.

## Les fichiers

Nouveaux (tout le code de l'extension est rangé à part) :

| Fichier | Rôle |
|---|---|
| `pcvr/scripts/ext_chateau/ombrelac.gd` | le chef d'orchestre (ce que `main.gd` appelle) |
| `pcvr/scripts/ext_chateau/ile_ombrelac.gd` | le relief de l'île (carte des hauteurs, carte des sols, collision) |
| `pcvr/scripts/ext_chateau/chateau_ombrelac.gd` | le château, bâtiment par bâtiment |
| `pcvr/scripts/ext_chateau/archi_ombrelac.gd` | la boîte à outils de l'architecte (tours, toits, flèches, créneaux, baies, roses, contreforts…) |
| `pcvr/scripts/ext_chateau/interieurs_ombrelac.gd` | les intérieurs : la Grande Salle (meubles, charpente, cheminée, lustres, bannières, lumières) |
| `pcvr/scripts/ext_chateau/bibliotheque_ombrelac.gd` | la Bibliothèque (rayonnages, galerie, escalier, tables, lampes, sphère armillaire) |
| `pcvr/scripts/ext_chateau/flore_ombrelac.gd` | la végétation et les rochers (reprend les outils de `grande_flore_v59.gd`) |
| `pcvr/shaders/ext_chateau/ombrelac_ardoise.gdshader` | les toits d'ardoises en écailles |
| `pcvr/shaders/ext_chateau/ombrelac_vitre.gdshader` | les fenêtres et les vitraux (jour / nuit, vus du dehors et du dedans) |
| `pcvr/shaders/ext_chateau/ombrelac_flamme.gdshader` | les flammes des bougies et du feu |
| `pcvr/shaders/ext_chateau/ombrelac_tissu.gdshader` | les bannières et le tapis |
| `pcvr/shaders/ext_chateau/ombrelac_lambris.gdshader` | les plafonds peints (bleu de nuit semé d'étoiles d'or) |
| `pcvr/shaders/ext_chateau/ombrelac_livres.gdshader` | les livres sur les rayons (dos de cuir, nerfs et filets dorés) |
| `pcvr/tools/ext_chateau_textures.py` | fabrique les textures du château (à lancer une fois) |
| `www/assets/textures/ext_chateau/*.png` | pierre de taille, pierre fine, dalles (et leur relief) |
| `tests/series/48_ombrelac.gd` | la série de tests de l'extension |
| `docs/EXT_CHATEAU_OMBRELAC.md` | ce fichier |

Fichiers existants modifiés (des lignes ajoutées ; dans `grande_ile_v59.gd`, deux lignes complétées ; rien d'enlevé ni de déplacé) :

| Fichier | Ce qui est ajouté |
|---|---|
| `pcvr/scripts/main.gd` | la variable `ombrelac_ext` ; le relief de l'île dans `_height_land_v55` ; la création de l'île et de son débarcadère (après l'Île Perchée) ; `_create_ombrelac_ext()` dans `_ready` ; la sauvegarde (`extra["ombrelac"]`), le chargement et la nouvelle partie |
| `pcvr/scripts/grande_ile_v59.gd` | la mer de l'île dans `sea_contains` et `sea_clamp` (pour le bateau) |
| `pcvr/scripts/teleport_v58.gd` | deux destinations (le débarcadère, la Cour d'Honneur) et la reconnaissance de l'île |
| `pcvr/scripts/journal_v56.gd` | le nom des lieux de l'île |
| `pcvr/stage_assets.py` | la copie des textures `textures/ext_chateau/` |

Pour retirer l'extension : enlever ces lignes ajoutées et les fichiers nouveaux.

## Tests

```
python3 tests/lancer.py 48_ombrelac
```
