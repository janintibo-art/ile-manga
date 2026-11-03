"""V101 : les fiches d'histoires des habitants du Village des Arbres-Maisons, sur l'Île Crayonnée
(data/histoires_v65/crayon.json) : l'histoire de chacun (des souvenirs racontés quand on le connaît mieux),
son rêve, sa question au voyageur, ses liens avec les autres (ce qu'il en pense, une anecdote, un petit
dialogue quand ils se croisent).
Textes écrits ici, versés au domaine public (CC0 1.0).
Lancement (depuis la racine du dépôt) : python3 -B pcvr/tools/histoires_crayon_v101.py
"""
import json
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "data" / "histoires_v65" / "crayon.json"


def H(titre, t):
    return {"titre": titre, "t": t}


def Q(texte, *reps):
    return {"texte": texte, "reponses": [{"label": a, "valeur": b, "t": c, "rappel": d} for a, b, c, d in reps]}


def LI(qui, nom, s, avis, anecdote, bav):
    return {"qui": qui, "nom": nom, "sentiment": s, "avis": avis, "anecdotes": [anecdote], "bavardage": bav}


FICHES = {
    "aquarelle": {"genre": "f", "prenom": "Grand-Mère Aquarelle",
        "histoire": [
            H("la cabane et l'échelle", "Quand je suis née, le Grand-Chêne n'avait qu'une cabane et une échelle de corde. Ma mère montait les seaux d'eau à la poulie, mon père sciait les planches en bas. Le soir, on dînait à quinze mètres du sol, et les étoiles étaient à portée de cuillère."),
            H("la première porte bleue", "Ma mère a peint la première porte du village. En bleu, avec le premier pot de la Palette. Tout le monde est venu la regarder, comme on regarde un lever de soleil. Le lendemain, il y avait douze portes à peindre."),
            H("la présidente", "On m'a élue présidente du Conseil parce que j'étais la seule à ne jamais crier. Je pleurais, c'est vrai, mais en silence. Augustin dit que c'est une très bonne qualité pour présider : on vous laisse parler pour que vous arrêtiez."),
            H("la nuit de l'Averse", "La nuit de la Grande Averse, je ne dormais pas. J'ai entendu la pluie, une pluie toute douce, sans un bruit de tonnerre. Au matin, j'ai ouvert les volets, et j'ai cru que j'avais perdu la vue des couleurs. C'était l'île qui les avait perdues. Pas moi. Ça m'a donné de l'espoir."),
            H("la promesse du voyageur", "Quand tu es arrivé, mon petit, je t'ai regardé monter l'escalier du Grand-Chêne. Tu avais des couleurs sur toi : ton sac, tes joues, tes yeux. Les seules couleurs de l'île. J'ai su tout de suite que tu étais la réponse. Je n'ai pas pleuré. Enfin, presque pas."),
        ],
        "reve": ["Voir les quatre géants du village en couleurs, le jour de mon anniversaire, avec des lampions sur toutes les passerelles et tout le village qui danse jusqu'au Belvédère."],
        "question": Q("Dis-moi, mon petit : quelle est ta couleur préférée ?",
            ("Le bleu, comme le ciel.", "bleu", "Le bleu… La couleur de la première porte du village. Tu as bon goût, mon petit.", "Toujours le bleu, mon petit ? Il te va bien."),
            ("Le vert, comme les feuilles.", "vert", "Le vert ! La couleur qui pousse toute seule. Rosalie va t'adorer.", "Toujours le vert ? Tu as la main verte, j'en suis sûre."),
            ("Toutes, je ne peux pas choisir.", "toutes", "Toutes ! C'est la meilleure réponse. Une palette, c'est fait pour qu'on n'ait pas à choisir.", "Toujours toutes les couleurs ? Comme la Palette.")),
        "liens": {
            "fusain": LI("mon vieux camarade,", "Gaspard Fusain", 0.9, "Gaspard et moi, on a été à l'école ensemble. Il noircissait ses dessins, je pleurais sur les miens. Aujourd'hui il guette, et moi je préside. On fait la paire.", "Un jour, il m'a offert un portrait de moi au fusain. Tout gris. J'ai pleuré dessus. Il est devenu tout flou. Il l'a encadré quand même.", [["a", "Gaspard, tu vois quelque chose ?"], ["b", "Du gris. Beaucoup de gris."], ["a", "Patience."]]),
            "augustin": LI("mon vieil ami,", "Papi Augustin", 0.85, "Augustin a appris à lire à tout le village. Il gomme tout ce qu'il écrit, alors on ne sait jamais ce qu'il a voulu dire. Mais on sait toujours qu'il l'a dit gentiment.", "Au Conseil, il prend des notes. À la fin, il les gomme. Le Conseil n'a jamais eu de compte-rendu. Personne ne s'en plaint.", [["a", "Augustin, tu as noté ?"], ["b", "Oui. Et gommé."], ["a", "Parfait."]]),
        }},
    "fusain": {"genre": "m", "prenom": "Gaspard Fusain",
        "histoire": [
            H("les cartes", "J'ai dessiné les cartes de toutes les îles de l'archipel, avec un bâton de fusain et une règle. Pour chaque île, je montais au point le plus haut et je dessinais ce que je voyais. Il m'a fallu quarante ans. Les cartes tiennent dans un seul tiroir."),
            H("la longue-vue", "Ma longue-vue vient d'un capitaine de Port-Azur. Je lui ai dessiné une carte de la mer en échange. Il m'a dit : « Avec ça, tu verras plus loin que tes cartes. » Il avait raison. J'ai vu des îles que je n'avais pas dessinées."),
            H("le guetteur", "Quand mes jambes n'ont plus voulu monter les montagnes, je suis monté au Belvédère. C'est moins haut qu'un sommet, mais on y voit toute l'île. Je guette les tempêtes, les bateaux, les incendies. Et maintenant, les couleurs."),
            H("le vieux chat", "Mon chat s'appelle Charbon. Il était noir. Depuis l'Averse, il est… noir aussi. C'est le seul de l'île qui n'a rien perdu. Il en est très fier. Il se promène devant tout le monde, la queue en l'air, comme pour dire : moi, je n'ai pas changé."),
            H("la carte du trésor", "Un jour, Lili m'a demandé de lui dessiner une carte au trésor. J'ai caché un caillou peint en bleu sous la balançoire, et j'ai dessiné la carte. Elle a cherché trois jours. Elle a trouvé le caillou, puis elle a dessiné sa propre carte, pour moi. Je cherche encore."),
        ],
        "reve": ["Dessiner une dernière carte : celle de l'Île Crayonnée en couleurs. La première carte en couleurs de ma vie. Au fusain, mais avec des petites notes dans la marge : « ici, c'est vert »."],
        "question": Q("Hm. Question de guetteur : toi, tu regardes plutôt loin, ou plutôt près ?",
            ("Loin, l'horizon.", "loin", "Hm. Un guetteur. Le problème, c'est qu'on trébuche sur les cailloux. Je le sais, j'en ai un bleu.", "Toujours à regarder loin ? Attention aux cailloux."),
            ("Près, les détails.", "pres", "Hm. Un dessinateur. Les détails, c'est là que se cachent les pots de couleur. Et les fourmis.", "Toujours les détails ? Bien. Tu trouveras des choses."),
            ("Les deux.", "deux", "Hm. Une longue-vue et une loupe. C'est ce qu'il faut. Je n'ai que la longue-vue.", "Les deux, toujours ? Tu me prêteras ta loupe.")),
        "liens": {
            "aquarelle": LI("la présidente,", "Grand-Mère Aquarelle", 0.9, "Aquarelle pleure pour un rien et décide de tout. C'est la meilleure présidente qu'on ait jamais eue. Elle ne le sait pas. Ne lui dites pas, elle pleurerait.", "Au mariage de sa fille, elle a pleuré si fort que le gâteau a fondu. Le gâteau était en sucre glace. On l'a mangé à la cuillère.", [["a", "Présidente, rien à signaler."], ["b", "Rien du tout ?"], ["a", "Du gris."]]),
            "lili": LI("la petite Lili,", "Lili Pinceau", 0.85, "Lili monte me voir au Belvédère pour regarder dans la longue-vue. Elle la tient à l'envers. Elle dit que l'île est toute petite. Elle a raison, vue comme ça.", "Elle m'a demandé si on pouvait voir la lune en plein jour. Je lui ai montré. Elle n'a plus dormi pendant deux nuits : elle voulait la voir disparaître.", [["a", "Lili, la longue-vue, c'est par l'autre bout."], ["b", "Je sais ! C'est plus drôle comme ça."]]),
        }},
    "basile_pinceau": {"genre": "m", "prenom": "Basile Pinceau",
        "histoire": [
            H("le premier volet", "J'avais six ans quand j'ai peint mon premier volet. Personne ne me l'avait demandé. Il était vert. Le volet était à la voisine. Elle a dit que c'était très beau. Puis elle a dit à ma mère de m'acheter des pinceaux à moi."),
            H("Bertrand", "Mon grand pinceau à façade, je l'ai acheté à Port-Azur avec ma première paie. Il était trop grand pour moi, il est toujours un peu trop grand. Je l'ai appelé Bertrand, parce qu'un outil qui fait la moitié de votre taille mérite un prénom."),
            H("Mélisse", "J'ai rencontré Mélisse en repeignant un phare. Elle peignait l'autre côté. On s'est retrouvés en haut, sur la galerie, avec deux couleurs différentes. On a fait les rayures. Le phare a des rayures depuis. Et moi, j'ai une femme."),
            H("l'échelle qui chante", "Quand on repeint une maison dans un arbre, il faut une échelle très longue. La mienne grince à chaque barreau, sur des notes différentes. Lili a appris à monter dessus en jouant une chanson. Maintenant, tout le village sait quand je travaille : on entend la chanson de l'échelle."),
            H("le pot sans couleur", "Après l'Averse, j'ai ouvert mes pots de peinture. Ils étaient tous gris. Tous. Même le jaune que je gardais pour la chambre de Lili. Je me suis assis et je n'ai rien dit pendant une heure. Puis Lili est venue me demander si on pouvait peindre en gris, en attendant. On a peint un éléphant."),
        ],
        "reve": ["Repeindre tout le village d'un coup, en une seule journée, avec toutes les couleurs de la Palette. Et que Mélisse, en rentrant, croie qu'elle s'est trompée d'île."],
        "question": Q("Dis donc, toi : si tu étais une couleur, tu serais laquelle ?",
            ("Le rouge, ça claque !", "rouge", "Le rouge ! Pour les portes, c'est le meilleur. Ça dit « entrez » avant qu'on frappe.", "Toujours rouge ? Je te garde un fond de pot."),
            ("Le bleu, c'est calme.", "bleu", "Bleu ! Comme notre porte. Avant. Tu viendras m'aider à la repeindre ?", "Toujours bleu ? Alors tu es de la famille."),
            ("Le blanc. J'aime bien le blanc.", "blanc", "Le blanc ? (Il regarde autour de lui, tout le gris, tout le blanc.) … Tu as de l'humour, toi. J'aime bien.", "Toujours le blanc ? Tu es servi, ici.")),
        "liens": {
            "lili": LI("ma fille,", "Lili", 1.0, "Lili veut tout faire : peintre, guetteuse, chercheuse de trésors. Elle a mon nez et la patience de sa mère. Enfin, celle que sa mère aura un jour.", "Elle a peint le chat du voisin en jaune pour qu'il ressemble à un soleil. Le chat était d'accord. Le voisin, moins.", [["a", "Lili ! Tu as encore du sable plein les poches !"], ["b", "C'est pour plus tard, Papa !"], ["a", "Plus tard quand ?"], ["b", "Je sais pas encore."]]),
            "achille": LI("notre poète,", "Achille Buvard", 0.7, "Achille écrit des poèmes sur tout. Même sur mes volets. Il dit qu'ils ont « la mélancolie du bois ». Moi je dis qu'ils ont besoin d'une deuxième couche.", "Il m'a demandé de peindre une rime sur sa porte. Je ne savais pas comment on peint une rime. J'ai peint deux points, côte à côte. Il était ravi.", [["a", "Achille, tu as fini ton poème ?"], ["b", "J'en suis à la première goutte."], ["a", "Il y en a combien ?"], ["b", "Des millions."]]),
        }},
    "lili": {"genre": "f", "prenom": "Lili Pinceau",
        "histoire": [
            H("le chat soleil", "Une fois, j'ai peint le chat de Monsieur Fusain en jaune. Pour qu'il ressemble à un soleil. Il s'est roulé dans l'herbe pendant une semaine. Après, c'était un soleil vert. Papa a dit que c'était de l'art moderne."),
            H("le château de l'Averse", "Le matin après l'Averse, la plage avait construit un château toute seule. Avec des tours ! Papa dit que c'est la pluie qui a tassé le sable. Moi, je crois que c'est la plage qui s'ennuyait."),
            H("les phares de Maman", "Maman peint les phares de toutes les îles. Elle m'envoie une carte de chaque phare. J'en ai sept. Ils sont tous à rayures. Quand je serai grande, je peindrai des phares à pois."),
            H("le trésor sous la balançoire", "Sous la balançoire, j'ai trouvé un caillou bleu ! Bleu, avant l'Averse. Monsieur Fusain dit qu'il ne sait pas d'où il vient. Il fait un drôle de sourire quand il le dit. Je l'ai gardé dans ma poche. Maintenant il est gris, mais je sais qu'il était bleu."),
            H("la peur du haut", "Avant, j'avais peur de monter tout en haut du Grand-Chêne. Papa m'a dit de compter les marches. Il y en a beaucoup trop, j'ai perdu le compte. Alors j'ai chanté. Arrivée en haut, j'avais oublié d'avoir peur. Maintenant je chante tout le temps, même quand je n'ai pas peur."),
        ],
        "reve": ["Monter à la balançoire si haut que je toucherai la passerelle avec les pieds. Et après, aller dans la lune avec la longue-vue de Gaspard."],
        "question": Q("Dis, tu préfères les châteaux de sable ou les cabanes dans les arbres ?",
            ("Les châteaux de sable !", "chateau", "Moi aussi ! Mais il faut se dépêcher, la mer les mange. C'est une mer très gourmande.", "On fait un château ? Le plus grand du monde ?"),
            ("Les cabanes dans les arbres !", "cabane", "T'as de la chance, ici c'est que des cabanes dans les arbres ! Des géantes ! Avec des maisons dedans !", "On grimpe ? Je connais un raccourci. Non, je mens, y'a pas de raccourci."),
            ("Les deux : un château dans un arbre !", "deux", "Un château dans un arbre ! (Ses yeux brillent.) Je vais demander à Papa. Il va dire non. Je vais demander à Papi Augustin.", "Alors, notre château dans l'arbre ? Papi Augustin dit qu'il faut un plan.")),
        "liens": {
            "basile_pinceau": LI("mon papa,", "Papa", 1.0, "Papa peint tout ce qui ne bouge pas. Et des fois ce qui bouge. Il a un pinceau géant qui s'appelle Bertrand. Je crois qu'il l'aime presque autant que moi.", "Une fois, il a peint toute la maison pendant que je dormais. Le matin, je me suis crue dans une autre maison. J'ai pleuré, puis j'ai trouvé ça super.", [["a", "Papa, je peux peindre Bertrand ?"], ["b", "On ne peint pas un pinceau, Lili."], ["a", "Pourquoi ?"], ["b", "… Bonne question."]]),
            "augustin": LI("mon Papi de la balançoire,", "Papi Augustin", 0.95, "Papi Augustin, c'est pas mon vrai papi, c'est le papa de Rosalie. Mais il pousse la balançoire mieux que tout le monde. Et il connaît toutes les capitales du monde. Même celles qui n'existent pas.", "Il m'a appris à écrire mon nom. Après, il l'a gommé. J'ai dû le réécrire. Maintenant, je l'écris partout, même sur le sable.", [["a", "Papi, plus haut !"], ["b", "Plus doucement !"], ["a", "Plus haut !"]]),
        }},
    "rosalie_gomme": {"genre": "f", "prenom": "Rosalie Gomme",
        "histoire": [
            H("la graine dans le cahier", "Petite, j'ai trouvé une graine dans le cahier de mon père. Il avait gommé toute la page autour, mais pas la graine. Je l'ai plantée. C'est devenu le pommier qui est au pied du Chêne-Pinceau. Mon père dit qu'il ne se souvient pas de l'avoir mise là."),
            H("les jardinières", "C'est moi qui ai eu l'idée des jardinières sous les fenêtres. Rouge chez les Buvard, jaune chez les Pinceau, bleu au Conseil. Le village ressemblait à un bouquet perché dans les arbres. Aujourd'hui, c'est un bouquet de mariée."),
            H("le hibou de la Souche", "Le hibou de la Souche Creuse est là depuis avant ma naissance. Il me regarde toujours de travers, comme s'il savait quelque chose que je ne sais pas. Je crois qu'il sait où j'ai oublié mon sécateur, l'été dernier."),
            H("les graines de couleur", "Après l'Averse, j'ai semé des graines de capucines orange. Elles ont poussé blanches. Toutes. J'ai cru qu'elles boudaient. Je leur ai parlé tous les jours, je leur ai dit qu'un voyageur viendrait. Elles ont attendu. Elles sont patientes, les fleurs. Plus que moi."),
            H("l'arrosoir de ma mère", "Mon arrosoir, c'était celui de ma mère. Il fuit un peu, sur le côté. Je n'ai jamais voulu le réparer : les fleurs du chemin sont arrosées en même temps. Ma mère disait que c'était un arrosoir généreux. Il arrose ceux qui n'ont rien demandé."),
        ],
        "reve": ["Planter une forêt entière de pommiers autour de la clairière, pour que le village ait toujours des pommes, et des fleurs au printemps, et de l'ombre l'été. Et que les géants aient des petits voisins."],
        "question": Q("Question de jardinière : tu parles à tes plantes, toi ?",
            ("Oui, tous les jours.", "oui", "Bien ! Elles écoutent. Pas toujours, mais quand elles écoutent, elles poussent.", "Tu leur parles toujours ? Dis-leur bonjour de ma part."),
            ("Non, ça ne sert à rien.", "non", "Ça ne sert à rien ? Essaie avec une fougère. Les fougères adorent les compliments.", "Tu as essayé, avec une fougère ?"),
            ("Je leur chante des chansons.", "chante", "Des chansons ! Pas trop fort, alors : les tomates rougissent, et les roses piquent.", "Toujours à chanter pour tes plantes ? Tu m'apprendras ?")),
        "liens": {
            "augustin": LI("mon père,", "Papa", 0.95, "Mon père gomme tout ce qu'il écrit. Moi, je plante tout ce que je touche. Maman disait qu'on était les deux bouts d'un même crayon.", "Il a gommé la liste de courses pendant que je faisais les courses. Je suis rentrée avec une citrouille et un parapluie.", [["a", "Papa, tu as vu mon sécateur ?"], ["b", "Je l'ai noté quelque part."], ["a", "Et gommé ?"], ["b", "Évidemment."]]),
            "capucine_buvard": LI("mon amie fleuriste,", "Capucine", 0.9, "Capucine vend mes fleurs, et moi je fais pousser les siennes. Enfin, c'est compliqué. On ne compte plus qui doit quoi à qui. On compte les bouquets.", "On s'est disputées une fois pour un coquelicot. On l'a partagé. Il n'a pas survécu, mais notre amitié, si.", [["a", "Capucine, tes coquelicots boudent."], ["b", "Ils sont vexés d'être blancs."], ["a", "On les comprend."]]),
        }},
    "augustin": {"genre": "m", "prenom": "Papi Augustin Gomme",
        "histoire": [
            H("l'école sur la passerelle", "Mon école était sur une passerelle, entre le Chêne-Gomme et le Chêne-Buvard. Les élèves s'asseyaient sur les planches, les jambes dans le vide. Personne n'a jamais rien fait tomber, sauf des gommes. Il y a des gommes partout dans l'herbe, en dessous."),
            H("pourquoi je gomme", "Je gomme tout ce que j'écris parce qu'un jour, j'ai écrit une bêtise sur le tableau, et toute la classe l'a recopiée. Depuis, je relis, je gomme, je recommence. Il ne me reste plus beaucoup de bêtises. Il ne me reste plus beaucoup de gomme non plus."),
            H("les neuf godets", "J'ai fait réciter les neuf godets de la Palette à tous mes élèves, pendant quarante ans. Un, le bleu. Deux, le vert… Aujourd'hui, tout le village les connaît par cœur. C'est bien utile, maintenant qu'il faut les retrouver."),
            H("le tableau noir", "Le tableau noir de mon école est toujours accroché sur la passerelle. Il pleut dessus, le vent l'use. Mais chaque matin, quelqu'un y écrit un mot. Je ne sais pas qui. Hier, c'était « courage ». Je ne l'ai pas gommé. C'est la première fois."),
            H("ma femme Hortense", "Hortense écrivait au crayon, comme moi, mais elle ne gommait jamais. Elle disait que les fautes, c'est la preuve qu'on a essayé. Ses cahiers sont dans un coffre, sous mon lit. Pleins de fautes. Ce sont les plus beaux cahiers du monde."),
        ],
        "reve": ["Écrire un livre, un seul, et ne pas le gommer. Je n'ai pas encore trouvé quoi écrire. Peut-être l'histoire de l'île qui a perdu ses couleurs et du voyageur qui les a retrouvées."],
        "question": Q("Interrogation surprise ! Combien de godets compte la Palette de pierre ?",
            ("Neuf !", "neuf", "Neuf ! Dix sur dix. Vous pouvez aller en récréation.", "Toujours neuf godets ? Bien, bien. Vous avez bonne mémoire."),
            ("Sept, comme l'arc-en-ciel.", "sept", "Sept ? (Il fronce les sourcils, sort sa gomme.) Non, non. Neuf. L'arc-en-ciel n'avait pas pensé au brun ni au rose. La Palette, si.", "Neuf, pas sept. Je vous ai gommé la mauvaise réponse."),
            ("Je ne sais pas.", "sais_pas", "Vous ne savez pas ? C'est honnête. C'est neuf. Répétez après moi : un, le bleu ; deux, le vert…", "Alors, combien de godets ? … Neuf ! Bravo.")),
        "liens": {
            "rosalie_gomme": LI("ma fille,", "Rosalie", 1.0, "Rosalie fait pousser tout ce qu'elle touche. Moi, j'efface. Elle répare tout ce que je gomme. C'est une très bonne fille, et une très bonne jardinière.", "Elle a planté une graine que j'avais oubliée dans un cahier. C'est devenu un pommier. Je ne me souviens pas de cette graine. Je l'ai sûrement gommée.", [["a", "Rosalie, tu as arrosé ?"], ["b", "Oui, Papa."], ["a", "Bien. Je note."]]),
            "lili": LI("ma petite élève,", "Lili Pinceau", 0.95, "Lili Pinceau est ma dernière élève. Je lui apprends à lire, à écrire et à pousser une balançoire en même temps. Elle est très douée pour les deux derniers.", "Elle m'a demandé pourquoi les gommes sont roses. Je n'ai pas su répondre. C'est la première fois en cinquante ans.", [["a", "Lili, les capitales ?"], ["b", "La capitale de la balançoire, c'est le ciel !"], ["a", "… Dix sur dix."]]),
        }},
    "capucine_buvard": {"genre": "f", "prenom": "Capucine Buvard",
        "histoire": [
            H("le poème sur la capucine", "Achille m'a écrit un poème sur une capucine. La fleur. Mais j'ai cru que c'était moi. Je l'ai épousé. Il ne m'a jamais dit la vérité, et je ne lui ai jamais dit que je l'avais devinée. On est très heureux comme ça."),
            H("la boutique des fleurs", "Ma boutique, c'est la terrasse du Chêne-Buvard. Les gens montent l'escalier pour acheter un bouquet. Ça fait des clients en forme. Le vieux Gaspard monte une fois par mois, pour Aquarelle. Il dit que c'est pour le Conseil."),
            H("Monsieur Paille", "J'ai fabriqué Monsieur Paille, l'épouvantail, pour protéger mes fleurs des corbeaux. Les corbeaux se sont assis sur ses bras. Maintenant, ils sont amis. Ils protègent les fleurs à sa place. C'est mieux comme ça."),
            H("le bouquet de l'Averse", "Le soir de l'Averse, j'avais préparé un bouquet pour l'anniversaire d'Aquarelle. Coquelicots, bleuets, boutons-d'or. Au matin, il était blanc comme un bouquet de mariée. Aquarelle l'a pris quand même. Elle a dit : « Il a juste besoin d'un peu de patience. » Elle l'a mis dans un livre."),
            H("le panier", "Mon panier a fait le tour de l'archipel. Il est parti plein de fleurs sur un bateau de Port-Azur, et il est revenu plein de coquillages, puis d'épices, puis de lettres. Chaque fois que je le remplis, je me demande d'où il reviendra la prochaine fois."),
        ],
        "reve": ["Faire le plus grand bouquet du monde, avec une fleur de chaque île de l'archipel, et l'offrir à toute l'Île Crayonnée le jour où elle aura retrouvé ses couleurs."],
        "question": Q("Dis-moi : tu offres des fleurs, toi, parfois ?",
            ("Oui, souvent !", "souvent", "Souvent ! Tu es mon client préféré, alors. Enfin, tu le seras quand mes fleurs auront de nouveau des couleurs.", "Toujours des fleurs ? Je te ferai un prix."),
            ("Jamais.", "jamais", "Jamais ? Oh, il faut essayer. Une seule fleur suffit. Même une pâquerette. Les gens se souviennent toute leur vie d'une pâquerette.", "Tu as essayé ? Une seule pâquerette ?"),
            ("Seulement à ma mère.", "mere", "C'est la plus belle des raisons. Les mères gardent les fleurs dans un livre, tu sais. Toutes. Pendant des années.", "Ta mère, elle a aimé ses fleurs ?")),
        "liens": {
            "achille": LI("mon poète de mari,", "Achille", 0.95, "Achille écrit sur tout, tache tout, oublie tout sauf mes anniversaires. Il m'écrit un poème chaque année. Ils sont tous dans un tiroir. Certains sont même terminés.", "Il a voulu m'écrire un poème sur un buvard, pour qu'il ne coule pas. Le poème a été absorbé. Il dit que c'était le plus beau.", [["a", "Achille, tu as encore de l'encre sur le nez."], ["b", "C'est une virgule."], ["a", "Une virgule ?"], ["b", "Je réfléchis."]]),
            "rosalie_gomme": LI("ma meilleure amie,", "Rosalie", 0.9, "Rosalie fait pousser les fleurs, je les vends. On est comme le pot et la fleur. Enfin, je ne sais pas qui est le pot.", "Un jour, elle a planté des capucines devant ma porte, pour mon anniversaire. Achille a cru que c'était pour lui. Il a écrit un poème. Encore.", [["a", "Rosalie, tu me gardes des pivoines ?"], ["b", "Blanches ou blanches ?"], ["a", "… Blanches, alors."]]),
        }},
    "achille": {"genre": "m", "prenom": "Achille Buvard",
        "histoire": [
            H("le buvard de l'arrière-grand-père", "Mon arrière-grand-père fabriquait le papier buvard du village. Il disait qu'un bon buvard boit l'encre sans boire les mots. Moi, j'ai hérité de son nom, et d'une tache d'encre à la naissance, sur le petit doigt. Elle est toujours là."),
            H("la première rime", "Ma première rime, je l'ai faite à sept ans, en classe, chez Augustin : « Le crayon est trop long, il faut le tailler, ou bien le gommer. » Augustin l'a gommée. Il a dit que « gommer » ne rimait pas avec « tailler ». J'ai décidé que si, depuis."),
            H("l'épopée de l'Averse", "J'écris l'épopée de la Grande Averse. J'en suis à la première goutte. Elle a déjà quarante pages. Capucine dit qu'à ce rythme, la pluie s'arrêtera avant mon poème. Elle n'a pas tort. Mais la pluie, elle, n'a pas de rimes."),
            H("le poème perdu", "J'ai écrit un poème si beau qu'il s'est envolé. Vraiment : je l'avais posé sur la rambarde, et le vent l'a emporté au-dessus de la cascade. Je ne l'ai jamais retrouvé. Quelque part sur l'île, il y a un poème qui sèche au soleil. Si tu le trouves, ne le lis pas trop fort."),
            H("le rocher de la cascade", "Je viens m'asseoir sur le rocher de la cascade pour écouter l'eau. L'eau ne parle pas en rimes, mais elle ne s'arrête jamais. C'est elle qui m'a appris qu'un poème n'a pas besoin de finir. Il suffit qu'il continue de couler."),
        ],
        "reve": ["Lire mon épopée de la Grande Averse en entier, en haut du Belvédère, devant tout le village. Toutes les gouttes. Il faudra trois jours. J'apporterai des sandwiches."],
        "question": Q("Ô voyageur, réponds à ma question : préfères-tu les poèmes qui riment, ou ceux qui ne riment pas ?",
            ("Ceux qui riment !", "rime", "Ah ! Un classique ! « Ô toi, voyageur aux souliers poussiéreux, qui aimes les rimes… et les… » (Il cherche.) Je te le finirai.", "Toujours les rimes ? Moi aussi. Quand je les trouve."),
            ("Ceux qui ne riment pas.", "libre", "Un moderne ! Les vers libres, c'est comme la cascade : ça tombe où ça veut. Je respecte.", "Toujours les vers libres ? Tu es plus libre que moi."),
            ("Je préfère les blagues.", "blagues", "Les blagues ? (Il réfléchit, très sérieux.) Une blague, c'est un poème qui rit. Tu as raison. Je vais en écrire une. Dans trois ans.", "Alors, ma blague ? Elle avance. J'en suis au début du début.")),
        "liens": {
            "capucine_buvard": LI("ma muse,", "Capucine", 1.0, "Capucine est ma muse, ma femme et ma première lectrice. Elle s'endort pendant les longs poèmes. Je les raccourcis. Grâce à elle, je suis devenu un poète concis. Enfin, moins long.", "Le jour de notre mariage, j'ai lu un poème de vingt pages. Elle a dit « oui » au milieu, pour gagner du temps.", [["a", "Capucine, écoute ce vers…"], ["b", "Il est long ?"], ["a", "Une ligne."], ["b", "Alors vas-y."]]),
            "basile_pinceau": LI("notre peintre,", "Basile Pinceau", 0.75, "Basile peint, j'écris. Il dit que ses volets ont plus de couleurs que mes poèmes. Depuis l'Averse, on est à égalité.", "Il a peint ma porte en rouge pour que je trouve l'inspiration. J'ai écrit douze pages sur le rouge. La porte s'est écaillée avant que je finisse.", [["a", "Basile, prête-moi une couleur."], ["b", "J'en ai plus, Achille."], ["a", "Alors prête-moi une rime."]]),
        }},
}


def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(FICHES, ensure_ascii=False, indent=1), encoding="utf-8")
    print("fiches V101 :", len(FICHES), "->", OUT)


if __name__ == "__main__":
    main()
