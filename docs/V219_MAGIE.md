# V219 — la magie spectaculaire

## Le constat

Les sorts d'attaque avaient les bonnes règles (le feu brûle, la glace fige, la foudre saute d'un ennemi à
l'autre, les réactions entre éléments) mais une image pauvre : quelques dizaines de points lumineux calculés
par le processeur. La boule de feu était une bille suivie de points ; son explosion, un flash et des points ;
le gel, soixante-dix points bleus et des pics alignés ; la foudre, un trait de trois centimètres pendant un
sixième de seconde.

## Le principe : rien de droit, rien de régulier

Une première version avait de vraies flammes, mais gardait des formes raides : des étincelles en traits, un
anneau parfait pour l'onde de choc, un éclair en zigzag régulier, des pics de glace alignés. Le feu était le
plus réussi : des bouffées souples, rongées par un bruit qui défile. Tout le reste a été refait dans le même
esprit : **pas de trait, pas d'anneau parfait, pas d'alignement** — des formes qui ondulent, tourbillonnent,
scintillent.

## Ce qui change : `magie_v219.gd` et `shaders/magie_v219/`

De vraies matières, calculées par la carte graphique. Le processeur ne fait que **lancer** l'effet (créer
quelques objets) ; il n'anime rien image par image (le module n'a pas de `_process`).

| Sort | Avant | Maintenant |
|---|---|---|
| Boule de feu, en vol | une bille, des points | un cœur en fusion, une chevelure de flammes continue, des braises qui tournoient, une traînée de fumée ; sa lumière palpite |
| Boule de feu, à l'impact | un flash, des points, un anneau | un éclat, une boule de flammes qui gonfle et monte, des braises que l'air chaud emporte en tourbillons, une colonne de fumée qui s'enroule, une vague de feu irrégulière au sol, le sol noirci où des braises rougeoient |
| Gel | 70 points bleus, des pics alignés | un cône de brume glacée qui s'enroule, des bouquets de cristaux inégaux qui poussent en éventail puis volent en poussière, une poussière de givre qui flotte et scintille, le givre qui dessine des courbes sur le sol puis fond |
| Foudre | un trait fin, un flash | un éclair brisé à toutes les échelles, ramifié, qui ondule sans cesse ; deux filaments violets qui s'enroulent autour ; un éclat qui éclaire tout le décor, une poussière électrique, une vague au sol, des arcs qui rampent encore en se tordant |
| Ennemi en feu | des points orange | de vraies flammes qui l'enveloppent et le suivent, des braises, une fumée |
| Ennemi gelé | la gangue de glace, des pics | la gangue, des bouquets de cristaux, un souffle de brume, la poussière de givre, le givre à ses pieds |
| Ennemi foudroyé | rien | des arcs s'enroulent autour de son corps tant que dure sa secousse |
| Vapeur, Éclats, Électrocuté | des points | un nuage de vapeur qui s'enroule ; des éclats et une poussière de givre ; des arcs qui rampent |

### Comment c'est fait

- **Les bouffées** (flammes, fumée, brume, vapeur) : des particules de la carte graphique (`GPUParticles3D`).
  Chaque bouffée est un carré qui fait face au regard ; son dessin est rongé par un bruit qui défile, de plus
  en plus avec l'âge ; la flamme va du blanc-jaune à l'orange puis au rouge sombre ; la fumée est éclairée
  comme une boule (le soleil et les lampes la modèlent) et garde un instant la lueur du feu qu'elle enferme.
- **La poussière lumineuse** (`poussiere.gdshader` : braises, paillettes de givre, poussière électrique) : des
  points doux qui scintillent, sans aucun trait. Les remous de l'air (`turbulence` des particules) tordent
  leur course : aucune ne va droit.
- **La vague au sol** (`onde.gdshader`) : un front dont le rayon ondule autour du cercle, à deux échelles,
  ourlé de mèches qui s'effilochent derrière lui ; chaque vague a sa graine.
- **L'éclair** (`eclair.gdshader`) : un tracé coupé en deux encore et encore, le milieu poussé de côté à
  chaque fois (brisé à toutes les échelles, jamais deux fois le même) ; des branches qui se ramifient ; deux
  hélices autour. Le ruban est bâti une fois, rebâti une fois ; entre-temps c'est la carte graphique qui le
  fait onduler (chaque point glisse de côté selon un bruit qui défile) et qui fait courir des pulsations le
  long de lui.
- **Les cristaux** (`glace.gdshader`) : quatre formes de bouquets faites au démarrage (un grand cristal, les
  autres en éventail, penchés, inégaux). Bleu profond au pied, pâle à la pointe, les arêtes allumées à
  contre-jour, des paillettes. Ils jaillissent (une échelle animée), tiennent une seconde, volent en
  poussière.
- **Les marques au sol** (brûlure, givre) : un carré posé sur le sol, trouvé par un rayon (ce qui bouge — une
  bête, un habitant, un bateau — n'est pas le sol) ; dix brûlures et vingt-quatre plaques de givre au plus,
  les plus vieilles s'effacent (en une demi-seconde, pas d'un coup). Le dessin du givre est tordu par un
  bruit : il courbe comme des fougères.
- **Ce qui suit un objet** (les flammes de la boule, d'un ennemi) n'est pas son enfant : une attache
  (`RemoteTransform3D`) donne sa place au jet. Quand l'objet disparaît, le jet cesse d'émettre et ses
  dernières particules finissent leur vie : rien ne s'éteint d'un coup.
- **Au démarrage**, chaque matière est montrée une fois loin sous le monde (`prechauffer`) : la carte
  graphique prépare ses programmes d'avance, le tout premier sort ne saccade pas.

### Le branchement

`combat_fx_v129` (boule, explosion, gel), `elements_v143` (éclair, frappe, états, réactions, cristaux de la
gangue), `sorts_v67` (souffle de givre) et `pouvoirs_v63` (la boule dit où elle va ; ni la bille ni les
points d'avant ne sont créés ; plus de points par-dessus l'explosion) passent par `main.magie_v219` quand il
existe ; sans lui, les effets d'avant servent encore (vérifié par l'essai). La secousse de l'écran (PC) et
la vibration de la manette (VR) restent celles de `combat_fx_v129`.

Les objets créés par le module ont des noms **sans chiffre final** (« Brulure_magie », pas « Brulure_v219 ») :
le moteur numérote les frères de même nom en faisant monter ce chiffre (« Brulure_v220 »…).

`portee_v192` : un objet créé puis détruit dans la même image n'y fait plus écrire d'erreur par le moteur
(son argument n'a plus de type, comme dans `vr_fluidite_v199`).

### Pour le casque

- Aucune secousse d'écran en VR (comme avant), pas de déformation de l'image.
- De tout près, l'éclat d'une explosion ou d'un éclair est modéré (il remplirait la vue de blanc), plus
  encore dans le casque ; la lumière ne clignote pas : elle décroît d'un seul trait.
- Une explosion : environ 85 particules ; un souffle de givre : une centaine, plus huit bouquets de
  cristaux ; tout est calculé par la carte graphique.
- Aucune ombre portée par les effets ; les lumières des sorts n'en projettent pas non plus.

## Les outils

- `tests/outils/rendu_magie.sh DOSSIER [tout|feu|givre|foudre|ennemi] [jour|nuit]` : des planches d'images,
  avant et après, dans un atelier (rendu simplifié de la machine d'essai : sur le PC, la lueur devrait être
  plus forte).
- `tests/series/63_magie.gd` : les sorts passent par le module, les jets suivent leur cible, les bouquets de
  cristaux ne sont jamais alignés et volent en poussière, rien ne reste après, dix brûlures au plus, les
  effets d'avant servent encore sans le module.

## Pour la suite

- Les quatre autres sorts (Lumière, Lévitation, Télékinésie, Soin) et les pouvoirs des sceaux.
- La mort par le feu ou la glace (cendres, statue qui se brise).
- Les batailles elles-mêmes (l'impact des coups, le nombre d'ennemis, la variété des attaques).
