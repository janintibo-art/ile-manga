# V220 — en VR, changer d'arme et de pouvoir d'un geste

## Le constat

Le casque a peu de boutons. La magie avait déjà sa roue (V145 : gâchette gauche tenue, la roue des sorts
s'ouvre autour de la main gauche). Pour les armes, rien de rapide : il fallait ouvrir le sac (Y) et descendre
dans la liste. Pour les pouvoirs des sceaux, B tenu passait au suivant, à l'aveugle. Sur PC, les touches
suffisent : rien ne change.

## Ce qui change : `roue_armes_v220.gd`

Le même geste que la roue des sorts, pour la main droite. **Main gauche : la magie ; main droite : les armes.**

| Bouton | Tapé | Tenu |
|---|---|---|
| Poignée droite (libre jusqu'ici) | on reprend ce qu'on tenait juste avant (mains nues et rien d'avant : la meilleure arme) | la roue des armes s'ouvre autour de la main droite ; on pousse la main vers une case, on relâche : c'est en main |
| B (main droite) | lancer le pouvoir choisi (comme avant) | la roue des pouvoirs des sceaux, de la même façon |
| Gâchette gauche (V145, inchangé) | lancer le sort choisi | la roue des sorts |

- **La roue des armes** : « mains nues » en haut, puis tout ce qu'on possède et qu'on peut tenir : les armes,
  la canne à pêche, la pelle, le pinceau, toujours dans le même ordre (une arme ne change pas de place quand
  on range son sac). Douze cases au plus : au-delà, les armes les plus faibles restent au sac. Ce qu'on tient
  déjà porte un second liseré ; la case désignée grossit et s'éclaire, la manette vibre ; le nom (et les
  dégâts d'une arme) s'affiche à côté de la case, vers le dehors de la roue (au milieu, il tomberait sur la
  main et sur l'arme qu'elle tient). Des disques sombres et pleins, pour que les objets se lisent devant le
  ciel comme devant la roche.
- **La roue s'ouvre autour de la main**, là où elle est, face à la tête : rien n'est désigné tant que la main
  ne s'écarte pas de 4,5 cm.
- **La roue des pouvoirs** : les quatre pouvoirs ; ceux qui dorment encore sont gris et ne se choisissent pas.
- **Personne n'est puni d'avoir appuyé un peu long** : une roue ouverte sans rien désigner et relâchée avant
  six dixièmes de seconde compte pour un coup bref.
- **La main doit être posée.** Beaucoup serrent la poignée par habitude en frappant : si la main bouge pendant
  l'appui (plus de 7 cm), la poignée ne fait rien du tout — ni roue, ni changement d'arme. B, lui, lance
  simplement le pouvoir.
- **Pour annuler**, on éloigne la main de la roue (plus d'une trentaine de centimètres) : elle se referme sans
  rien changer, et le bouton attend d'être relâché. Un coup d'épée donné la poignée serrée la referme donc
  aussi.
- **Le jeu passe à autre chose** (le sac, le menu, une conversation, une échelle, un véhicule) : la roue se
  referme d'elle-même, sans rien prendre. Et un bouton encore tenu quand le jeu revient ne compte pas : fermer
  une conversation avec B ne lance plus le pouvoir, jeter un objet avec la poignée ne change pas d'arme.
- **Dans l'eau**, B sert à plonger : pas de roue des pouvoirs, B garde son usage d'avant.
- **La main droite ne frappe pas** pendant qu'elle choisit dans sa roue.
- **Sans à-coup** : dans le casque, les images dessinées des roues (pastilles, icônes) sont préparées pendant
  le chargement. Mesuré sur la machine d'essai : à sa première ouverture, la roue des armes arrêtait le jeu
  16 ms, celle des pouvoirs 55 ms, et la roue des sorts de la V145 (sept icônes) 370 ms ; plus rien.
- **Un rappel**, une seule fois (retenu dans `user://roue_v220.cfg`), après quelques secondes de jeu dans le
  casque ; et deux astuces de plus à l'écran de chargement.

Le déplacement au joystick n'est pas touché ; la roue se choisit avec la main, pas avec le joystick.

## Les essais

`tests/series/65_roue_armes.gd` : gestes simulés (comme `65_roue`) — la poignée tapée, la roue, les douze
cases, la main qui bouge, la roue annulée (la main partie loin, le jeu ailleurs), B tapé et tenu, l'eau, les
icônes, l'anglais.

`tests/outils/rendu_roue_armes.sh DOSSIER` : des images de la roue vue depuis la tête, avec la vraie main et
la vraie arme du jeu (un atelier, pas le casque ; `TAILLE=1920x1200` pour de grandes images).

## Pour la suite

- La même roue pour les objets qu'on utilise souvent (une potion, de quoi manger) ?
- Choisir aussi avec le joystick droit, pour ceux qui préfèrent (il faudrait suspendre la rotation pendant
  que la roue est ouverte).
