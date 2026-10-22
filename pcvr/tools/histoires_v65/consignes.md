# Île Manga V65 — le « cerveau » des habitants : histoires, liens, mémoire

Île Manga est un jeu d'aventure en 3D (PC et casque VR) sur un archipel. Le joueur est un jeune aventurier
(« tu », jamais nommé) arrivé par la mer. Les 211 habitants ont déjà des répliques (accueil, humeur, rumeurs,
cadeaux, quêtes…). En V65, chacun reçoit **sa propre histoire**, des **liens** avec d'autres habitants (dont il
raconte des anecdotes), un **rêve** et une **question** posée au joueur, dont il se souviendra.

Tu écris en **français**, dans la voix de chaque personnage. C'est le cœur du travail : du texte vivant,
précis, drôle ou touchant, cohérent avec ce que le personnage dit déjà dans le jeu.

## Le monde (pour situer les histoires)

- **L'île du village** (l'île de départ) : la cabane de Barnabé Coquillard, l'ermite de la plage (naufragé il y a
  longtemps, avec son perroquet Gaston) ; la jungle et le grand fromager où Octave Taillefer, forgeron, a sa
  cabane perchée ; la teuf de la plage (DJ Mistral et ses teufeurs, nuit et jour devant le mur de son) ; la
  clairière de l'Arbre sacré où veillait Lyra, une elfe ; un temple et des souterrains (le joueur y a vaincu
  Nâga, le grand serpent) ; la cascade et sa grotte.
- **L'île des elfes, le Bois-Doré** : l'Arbre-Mère, le village des elfes sur des plates-formes. Dessous, le
  **Royaume des Racines** des fées (la Reine des Ronces, vaincue par le joueur).
- **L'île des nains** : la Montagne de Feu, la cité de **Forgefer** (le roi Thorgal, les forges, la taverne de la
  Chope Ardente).
- **L'île céleste** : Ventaile (un grand oiseau qu'on apprivoise), la Citadelle des Nuées, Sire Orage.
- **L'Atlantide** : la cité engloutie sous une bulle d'air, au sud-ouest du village (la reine Néréa).
- **Port-Azur** : la grande île touristique (le port, la place, le phare, le Grand Hôtel, la plage), reliée au
  village par le bateau de ligne *L'Hirondelle* (Capitaine Léon).
- **Le royaume des fées d'Yggdrasil**, au-dessus d'une mer de nuages : on y arrive en mangeant un champignon
  qui brille, offert par Lulu à la teuf (la reine Oriane).
- **La grande île de l'est** : **Carène** (port bâti dans l'épave du Léviathan, côte ouest ; descendants de
  naufragés bretons, cidre, galettes, goudron) ; **Tazira** (grand port de pêche au bord du désert, côte sud :
  barques bleues, criée, souk, auberge du Fondouk, la garde de la Skala, et les pirates de la Murène Noire qui
  boivent à La Murène Ivre) ; **Cliquetis** (cité des ingénieurs fous sur les hautes terres du nord : vapeur,
  robots, explosions, la Foire des Inventions) ; **Ramure** (village des « oreilles », dans la forêt des brumes à
  l'est : des gens à oreilles et queue d'animal — renards, lapins, chats, ours, loups, tanukis, chouettes,
  écureuils, biches — perchés dans six arbres géants ; la lune y est toujours pleine) ; au centre, le massif du
  **Cœur-de-Pierre** et sa Porte aux Quatre Sceaux. Le dirigeable **Zéphyr** relie Cliquetis, Tazira, Carène et
  Ramure.

## Ce que le jeu fait de chaque champ (lis bien : c'est ce qui décide comment écrire)

### `histoire` — 5 chapitres (3 pour un passant `elfe_N`, `nain_N`, `atlante_N`)
Le joueur demande « Raconte-moi ton histoire. » ; le personnage raconte **un chapitre par fois**, dans l'ordre,
au fil des conversations. Le chapitre 1 est accessible tout de suite ; les suivants se débloquent avec l'amitié ;
**le dernier est une confidence** (un secret, un regret, une peur, un amour, une faute) qu'il ne dit qu'à un ami.
Arc conseillé : 1. d'où il vient (enfance, famille) ; 2. comment il est arrivé là / à son métier ; 3. un tournant
ou une épreuve ; 4. sa vie aujourd'hui, ses gens ; 5. la confidence.
- `t` : 2 à 4 phrases, **140 à 460 caractères**, à la première personne, dans sa voix (ses tics, son registre ;
  tutoiement ou vouvoiement comme dans ses répliques existantes). Chaque chapitre se comprend seul, mais
  l'ensemble raconte une vraie vie, avec des détails concrets (un nom, un objet, une date, un lieu).
  On peut y citer d'autres habitants **par leur nom** (cohérent avec les liens).
- `titre` : un groupe nominal court (≤ 48 caractères) qui se lit après « La dernière fois, je t'ai raconté… » :
  « mon enfance sur les quais », « la nuit où le phare s'est éteint », « pourquoi je ne chante plus ».
  Minuscule au début (sauf nom propre).

### `reve` — 1 ou 2 répliques (40 à 300 caractères)
Réponse à « Et toi, de quoi tu rêves ? » : son projet, son envie secrète ou naïve, dans sa voix.

### `question` — une question qu'il pose au joueur (pas pour les passants)
Posée une fois, au début d'une conversation. Le personnage **se souviendra** de la réponse.
- `texte` (20 à 220 caractères) : la question, dans sa voix, en rapport avec sa vie (« Tu as déjà eu le mal de mer ? »).
- `reponses` : exactement 3, chacune `{"label", "valeur", "t", "rappel"}` :
  - `label` (≤ 48) : ce que répond le joueur, à la première personne, court (« Jamais. », « Une fois, sur L'Hirondelle… »).
  - `valeur` : identifiant court en minuscules (`jamais`, `une_fois`, `toujours`).
  - `t` (20 à 280) : sa réaction, dans sa voix.
  - `rappel` (15 à 170) : comment il **s'en souviendra** plus tard, en reparlant au joueur
    (« Toi qui n'as jamais eu le mal de mer, tu devrais essayer la barque de Fañch un jour de houle. »,
    « Tu m'as avoué que tu avais peur du noir. Je n'en ai parlé à personne. »).

### `liens` — les gens qu'il connaît : 4 à 7 (2 à 4 pour un passant), clé = identifiant de l'autre
Le joueur demande « Parle-moi des gens que tu connais. » puis choisit une personne : la première fois, le
personnage donne son **avis** puis raconte une **anecdote** ; les fois suivantes, l'anecdote suivante.
Quand les deux personnes se croisent au village, elles échangent le **bavardage** (des bulles au-dessus de leur
tête). Si l'un parle de l'autre au joueur, l'autre le saura (« Alors comme ça, Odette t'a parlé de moi ? ») et
répondra avec **son propre avis**. Et les nouvelles circulent : si le joueur offre un cadeau à quelqu'un, l'aide,
ou le frappe, ses proches l'apprennent et réagissent selon le `sentiment`.
- `qui` (≤ 34) : ce qui se place **devant le nom**, en minuscules, du point de vue du personnage : « ma sœur »,
  « mon vieux copain », « ma voisine », « mon apprenti », « le patron du café », « cette pipelette de ».
  Le jeu écrit par exemple « Il paraît que tu as offert des fleurs à **ma voisine Rose** » : il faut que
  « qui + nom » sonne juste.
- `nom` (≤ 30) : le nom par lequel il l'appelle, utilisable aussi par le joueur (« Parle-moi de **Fernand**. »).
- `sentiment` : de -1 (il ne le supporte pas) à 1 (il l'adore). Mélange : famille, couples, amis, rivaux,
  collègues, voisins, maître et apprenti… **environ un lien sur quatre est négatif ou ambivalent** (une rivalité,
  une brouille, une jalousie, une vieille dette) : c'est ce qui rend un village vivant.
- `avis` (30 à 230) : ce qu'il pense de la personne, 1 ou 2 phrases.
- `anecdotes` : 2 ou 3 (1 ou 2 pour un passant), **100 à 400 caractères** chacune : de vraies petites histoires
  vécues avec ou sur la personne, concrètes, drôles ou touchantes, avec un détail qu'on retient. Elles doivent
  être cohérentes avec l'histoire de la personne et ses répliques. Pas de généralités (« elle est gentille »).
- `bavardage` : 2 à 4 répliques **courtes (≤ 95 caractères)** que les deux s'échangent en se croisant :
  `["a", "…"]` = le personnage de la fiche, `["b", "…"]` = l'autre (la première est toujours `"a"`).
  Elles font allusion à leur histoire commune, dans la voix de chacun. Pas de narration, que des paroles.
- **Réciprocité** : si A connaît B, B connaît A (mêmes faits ; les sentiments peuvent différer : on peut aimer
  quelqu'un qui nous trouve agaçant). Personne ne doit rester sans lien.

## Règles d'écriture
- Lis **toutes** les répliques existantes de tes personnages (fichier de contexte + source `.gd`) et ne les
  contredis jamais (métier, famille, passé, quête, caractère). Appuie-toi dessus : si quelqu'un dit déjà « Mon
  défunt mari était pêcheur. Fernand l'a connu », c'est un fait à développer, pas à changer. Ne recopie pas les
  répliques existantes : écris du neuf.
- Une seule variable est permise : `{surnom}` (le petit nom qu'il donne au joueur, qui change avec l'amitié).
  Aucune autre accolade.
- Typographie : guillemets « », apostrophe droite ' (comme dans le jeu), points de suspension « … », pas de
  double espace, pas de retour à la ligne dans un texte. JSON valide, UTF-8.
- Tout public : humour, tendresse, petits mystères, chagrins pudiques. Ni violence crue, ni contenu sexuel, ni
  marque réelle. Pas de mécanique de jeu (boutons, points, quêtes au sens « jeu »).
- Chaque personnage doit **sonner différemment** : un vieux pêcheur, une gamine, un savant fêlé, une reine elfe,
  un pirate ne parlent pas pareil. Garde leurs tics et leur humeur.

## Liens entre groupes (à écrire des deux côtés, par chacun des groupes concernés)
- `barnabe` ↔ `octave` : vieux amis (voir leurs répliques).
- `barnabe` ↔ `lyra`, `octave` ↔ `lyra` : la quête de l'Arbre sacré ; la graine d'or que Barnabé avait trouvée sur
  une plage il y a vingt ans.
- `lyra` ↔ `aelwen`, `faelar`, `nimiel`, `sylwen` : les elfes du Bois-Doré parlent déjà d'elle.
- `faelar` ↔ `barnabe` : la chanson de Barnabé sur le vainqueur de Nâga, que Faelar connaît.
- `barnabe` ↔ `marley` (teuf ; il cultive des bananes dans un coin près de la cabane de Barnabé, contre des
  régimes) ; `barnabe` ↔ `gaspard` (teuf ; Barnabé lui a appris à construire des cabanes) ;
  `octave` ↔ `gaspard` (Octave trouve que ses cabanes à lui sont mieux).
- `octave` ↔ `borin` (nains) : rivalité de forgerons (« Une épée d'acier d'Octave ? Pas mal… pour un grand. »).
- `ursule` (Ramure, forgeronne) ↔ `borin` (nains) : quand Ursule ne peut plus améliorer une lame, elle envoie le
  joueur chez Borin (« Dis-lui qu'Ursule t'envoie. Il grognera. C'est bon signe. »).
- `fanny` (teuf) ↔ `margaux` (Port-Azur) : Fanny est apprentie à la boulangerie de Margaux et prend le bateau le
  soir pour venir danser.
- `lulu` (teuf) ↔ `oriane` (fées) : les champignons qui brillent de Lulu, que les fées font pousser.
- `croc` (Tazira, capitaine pirate de la Murène Noire) ↔ `morgane` (Carène, amirale) : vieux adversaires en mer.
- `salome` (Carène, Marché de la Cale) ↔ `aicha` (Tazira, épices) : elles commercent.
- `basidi` (Tazira) ↔ `corentin` (Carène) ↔ `tilleul` (Ramure) : les trois conteurs de la grande île se
  connaissent tous (trois liens : basidi–corentin, corentin–tilleul, basidi–tilleul).
- `zelie` (Cliquetis, commandante de l'aérodrome du Zéphyr) ↔ `plumette` (Ramure, postière) : le courrier.
- `mbarek` (Tazira, caravanier) ↔ `bedaine` (Ramure, maître du Grand Troc) : le commerce.
Ces liens comptent dans les 4 à 7. Tu ne peux pas lire ce que l'autre groupe écrit : reste sur les faits donnés
ici et dans les répliques existantes, et laisse l'autre personnage dans son caractère connu.

## Vérification
`python3 pcvr/tools/histoires_v65/valider.py [--bible] <fichier.json>`
doit finir sans ERREUR. Les ATTENTION sur la réciprocité avec un personnage d'un autre lot sont normales ; à
l'intérieur de ton lot, corrige-les.
