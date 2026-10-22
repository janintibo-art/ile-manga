# Formats V65

## Fiches finales (`out/<lot>.json`)

Un objet JSON : identifiant du personnage → fiche. Exemple complet (personnage inventé, pour le format
seulement — ne pas réutiliser) :

```json
{
  "exemple": {
    "genre": "f",
    "prenom": "Mireille",
    "histoire": [
      {"titre": "mon enfance au-dessus du four",
       "t": "Je suis née au-dessus du four de mon père, rue des Mouettes. L'hiver, le plancher était chaud comme une brioche. Je m'endormais avec l'odeur du levain et je me réveillais avec de la farine dans les cheveux."},
      {"titre": "comment j'ai volé la recette",
       "t": "À quinze ans, j'ai recopié en cachette le carnet de recettes de mon père. Il l'a su le jour même : j'avais oublié le carnet ouvert sur la table, avec mes taches de beurre dessus. Il n'a rien dit. Il m'a donné un tablier."},
      {"titre": "l'année du grand incendie",
       "t": "L'été de mes vingt ans, le four a pris feu. Toute la rue a fait la chaîne avec des seaux, même Gédéon, qui ne me parlait plus depuis l'histoire du gâteau. On a tout reconstruit en un mois. Le pain de la réouverture, je l'ai raté. Tout le monde l'a mangé quand même."},
      {"titre": "ma boutique aujourd'hui",
       "t": "Aujourd'hui, la boutique est à moi. Je me lève à trois heures, je chante faux, et Paulin m'apporte le lait à cinq heures en faisant semblant de passer par hasard. Ça fait onze ans qu'il passe par hasard."},
      {"titre": "la lettre que je n'ai jamais envoyée",
       "t": "Je vais te dire un secret, {surnom}. Il y a une lettre pour Paulin dans la boîte à farine depuis onze ans. Chaque matin je me dis : aujourd'hui. Et chaque matin, je fais des croissants à la place."}
    ],
    "reve": [
      "Ouvrir une deuxième boutique sur la plage, avec des chaises bleues. Et peut-être y donner enfin la lettre. Peut-être."
    ],
    "question": {
      "texte": "Dis-moi, toi qui voyages : tu es plutôt sucré ou salé ?",
      "reponses": [
        {"label": "Sucré, toujours.", "valeur": "sucre",
         "t": "Je le savais ! Tu as une tête de pain au chocolat. C'est un compliment.",
         "rappel": "Toi, le bec sucré, je t'ai mis de côté un chausson aux pommes. En pensée, seulement."},
        {"label": "Salé.", "valeur": "sale",
         "t": "Un amateur de fougasse ! Il en faut. Pas beaucoup, mais il en faut.",
         "rappel": "Je n'ai pas oublié que tu préfères le salé. Je te pardonne, c'est déjà ça."},
        {"label": "Je mange ce qu'on me donne.", "valeur": "tout",
         "t": "La réponse d'un vrai voyageur. Ou d'un affamé. Tiens-toi droit, on dirait que tu n'as pas mangé depuis trois jours.",
         "rappel": "Tu m'avais dit que tu mangeais ce qu'on te donne. Alors je te donne un conseil : mange."}
      ]
    },
    "liens": {
      "paulin": {
        "qui": "mon laitier",
        "nom": "Paulin",
        "sentiment": 0.9,
        "avis": "Paulin ? Le plus gentil des hommes et le plus mauvais menteur de l'île. Il « passe par hasard » depuis onze ans.",
        "anecdotes": [
          "Une fois, Paulin a voulu m'offrir des fleurs. Il les a cachées dans le bidon de lait pour que personne ne les voie. Mon lait a eu un goût de violette pendant une semaine, et j'ai fait semblant de ne rien remarquer.",
          "L'hiver dernier, la neige bloquait la rue. À cinq heures, Paulin est arrivé quand même, à quatre pattes, le bidon sur le dos. Il a dit : « Je passais par hasard. »"
        ],
        "bavardage": [
          ["a", "Paulin ! Encore par hasard ?"],
          ["b", "Pur hasard, Mireille. Le lait, il faut bien qu'il passe quelque part."],
          ["a", "Alors passe demain aussi. Par hasard."]
        ]
      },
      "gedeon": {
        "qui": "ce grincheux de",
        "nom": "Gédéon",
        "sentiment": -0.4,
        "avis": "Gédéon me boude depuis que j'ai gagné le concours du gâteau. Il dit que j'ai triché. J'avais juste mis du beurre.",
        "anecdotes": [
          "Au concours de la Saint-Jean, Gédéon a présenté un gâteau en forme de phare. Il a penché pendant le discours du maire et il est tombé dans la fontaine. Moi j'ai gagné avec une tarte aux pommes toute simple. Il ne s'en est jamais remis.",
          "Le soir de l'incendie, c'est Gédéon qui portait les seaux les plus lourds. Il n'a pas dit un mot. Le lendemain, il me boudait de nouveau. Mais je sais ce que je sais."
        ],
        "bavardage": [
          ["a", "Bonjour, Gédéon. Toujours fâché ?"],
          ["b", "Toujours. Ta tarte avait trop de beurre."],
          ["a", "Tu en as repris deux fois."]
        ]
      }
    }
  }
}
```
(Un vrai personnage a **4 à 7 liens** ; l'exemple en montre 2 pour rester court.)

Passants (`elfe_N`, `nain_N`, `atlante_N`) : 3 chapitres, 1 ou 2 rêves, **pas de `question`**, 2 à 4 liens avec
1 ou 2 anecdotes chacun.

## Bible (`bible/<groupe>.json`) — le plan d'un village, avant l'écriture

Même structure, en résumé, pour que plusieurs auteurs écrivent ensuite le même village sans se contredire :

```json
{
  "exemple": {
    "genre": "f",
    "prenom": "Mireille",
    "plan": [
      "mon enfance au-dessus du four — née au-dessus du four de son père, rue des Mouettes ; l'odeur du levain.",
      "comment j'ai volé la recette — à 15 ans, recopie le carnet de son père, qui lui donne un tablier.",
      "l'année du grand incendie — à 20 ans le four brûle ; toute la rue fait la chaîne, même Gédéon ; réouverture ratée.",
      "ma boutique aujourd'hui — levée à 3 h ; Paulin passe « par hasard » à 5 h depuis 11 ans.",
      "(confidence) la lettre jamais envoyée — une lettre d'amour pour Paulin cachée dans la boîte à farine."
    ],
    "reve": "une deuxième boutique sur la plage, avec des chaises bleues ; y donner la lettre",
    "question": "sucré ou salé ? (sucre / sale / tout) — elle taquine le joueur dans les trois cas",
    "liens": {
      "paulin": {"qui": "mon laitier", "nom": "Paulin", "sentiment": 0.9,
                 "fond": "Il lui livre le lait à 5 h depuis 11 ans ; amour réciproque jamais avoué. Anecdotes : les fleurs cachées dans le bidon (lait à la violette) ; venu à quatre pattes dans la neige. Bavardage : « encore par hasard ? »."},
      "gedeon": {"qui": "ce grincheux de", "nom": "Gédéon", "sentiment": -0.4,
                 "fond": "Il la boude depuis le concours de la Saint-Jean (son gâteau-phare tombé dans la fontaine) ; il a pourtant porté les seaux le soir de l'incendie. Anecdotes : le concours ; l'incendie. Bavardage : la tarte trop beurrée dont il a repris deux fois."}
    }
  }
}
```
Dans la bible, chaque relation figure **des deux côtés** (dans la fiche de A et dans celle de B) avec les mêmes
faits ; le `fond` donne les faits partagés et les idées d'anecdotes et de bavardage.
