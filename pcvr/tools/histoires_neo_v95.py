"""V95 : les fiches d'histoires des gens de Néopolis (data/histoires_v65/neo.json) : l'histoire de chacun
(cinq souvenirs racontés quand on le connaît mieux), son rêve, sa question au voyageur, ses liens avec
les autres (ce qu'il en pense, une anecdote, un petit dialogue quand ils se croisent).
Textes écrits ici, versés au domaine public (CC0 1.0).
Lancement (depuis la racine du dépôt) : python3 -B pcvr/tools/histoires_neo_v95.py
"""
import json
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "data" / "histoires_v65" / "neo.json"


def H(titre, t):
    return {"titre": titre, "t": t}


def Q(texte, *reps):
    return {"texte": texte, "reponses": [{"label": a, "valeur": b, "t": c, "rappel": d} for a, b, c, d in reps]}


def LI(qui, nom, s, avis, anecdote, bav):
    return {"qui": qui, "nom": nom, "sentiment": s, "avis": avis, "anecdotes": [anecdote], "bavardage": bav}


FICHES = {
    "mamie_kiku": {"genre": "f", "prenom": "Mamie Kiku",
        "histoire": [
            H("le ponton et la théière", "Quand je suis arrivée, il n'y avait qu'un ponton, la mer, et une grande dalle de béton toute nue. Les ouvriers construisaient la première tour. Ils avaient froid, ils avaient faim. J'ai sorti ma théière. Le premier étal du Marché de Nuit, c'était une caisse retournée et trois tasses."),
            H("le premier androïde", "Un matin, un androïde est sorti d'une caisse, tout neuf, tout brillant. Il m'a dit « bonjour, madame ». Il tenait un balai. C'était Zéro. Il a balayé devant mon étal avant de balayer le reste de la ville. Depuis, il ne me doit plus rien, mais il continue."),
            H("les néons", "Le jour où on a allumé les premiers néons, toute la ville est sortie dans la rue. Les gens pleuraient, riaient, prenaient des photos. Moi, je regardais leurs visages, tout roses et tout bleus. C'était plus beau que les néons."),
            H("Hiro", "Mon petit-fils Hiro a brûlé son premier bouillon à huit ans. Le deuxième à neuf ans. Le troisième était parfait. Il ne s'en souvient pas, mais moi, j'ai gardé le bol. Il est sur mon étagère, à côté de ma photo de mariage."),
            H("la recette secrète", "Je vais te confier un secret, {surnom}. Mon thé n'a pas de recette secrète. Il a juste du temps. Les gens d'ici courent partout, avec leurs puces et leurs écrans. Alors je leur sers du temps, dans une tasse. C'est ça qu'ils viennent chercher."),
        ],
        "reve": ["Voir, un soir, toute la ville éteindre ses écrans en même temps, juste une minute, pour regarder les étoiles au-dessus des tours."],
        "question": Q("Dis-moi, mon petit : tu bois ton thé brûlant ou tu attends qu'il refroidisse ?",
            ("Brûlant, tout de suite.", "brulant", "Oh, un impatient ! Comme tout le monde, ici. Souffle dessus, au moins. Ta langue te dira merci.", "Toujours pressé de boire ton thé, mon petit ?"),
            ("J'attends qu'il refroidisse.", "attendre", "Voilà. Le thé, ça se mérite. Tu ferais une très bonne vieille dame.", "Toi qui sais attendre… assieds-toi, il refroidit."),
            ("Je préfère le Synthé-Soda.", "soda", "Le Synthé-Soda ! Cette boisson qui brille dans le noir ? Mon petit, ce qui brille dans le noir ne devrait pas aller dans un ventre.", "Encore du soda qui brille, mon petit ? Tss.")),
        "liens": {
            "hiro": LI("mon petit-fils,", "Hiro", 0.95, "Hiro a le cœur aussi chaud que son bouillon. Il croit qu'il a tout appris à Gaston. Je le laisse le croire : c'est bon pour un cuisinier d'être un peu fier.", "Quand Hiro était petit, il appelait les nouilles « des cheveux de soupe ». Je l'appelle encore comme ça quand il fait le malin.", [["a", "Hiro ! Tu as goûté ton bouillon ?"], ["b", "Oui, Mamie."], ["a", "Goûte-le encore."]]),
            "ishi": LI("mon vieil ami,", "Maître Ishi", 0.85, "Ishi et moi, on se connaît depuis quarante ans. On s'est dit environ cent mots. Ce sont les cent mots les plus importants de ma vie.", "Une fois, Ishi a dit « joli ». J'ai cru qu'il parlait de mon kimono. Il parlait d'un caillou. J'ai ri pendant trois jours.", [["a", "…"], ["b", "Hm."], ["a", "Oui. Moi aussi."]]),
        }},
    "hiro": {"genre": "m", "prenom": "Hiro",
        "histoire": [
            H("le bouillon de Mamie", "Ma grand-mère m'a appris le bouillon quand j'avais huit ans. Huit heures sur le feu, des os, du gingembre, de l'oignon brûlé. J'en ai raté deux. Le troisième, elle l'a goûté sans rien dire. Elle a juste resservi un bol. C'était le plus beau compliment de ma vie."),
            H("Gaston", "Gaston, je l'ai trouvé chez un ferrailleur. Un bras-robot de peinture, pour les voitures. Il avait encore du bleu sur la pince. Je l'ai nettoyé, je l'ai reprogrammé, je lui ai appris la louche. La première semaine, il a peint trois bols en bleu. On les a vendus le double."),
            H("la grande panne", "Une nuit, toute la ville est tombée en panne. Plus de néons, plus d'écrans, plus de monorail. Tout le monde est venu au Marché de Nuit : on avait des lanternes et du bouillon. On a fait la plus grande soirée de l'histoire de Néopolis. Le lendemain, des gens m'ont demandé quand serait la prochaine panne."),
            H("le concours", "L'an dernier, il y a eu un concours de nouilles. J'ai fini deuxième. Le premier ? Gaston. Il s'était inscrit tout seul. Je ne sais pas comment. Je le soupçonne d'avoir été aidé par Glitch."),
            H("le vrai secret", "Tu veux le vrai secret de mes nouilles, {surnom} ? C'est Mamie. Elle s'assoit à côté, avec sa théière, et elle me regarde cuisiner. Quand elle est là, je ne rate jamais rien. Ne lui dis pas. Elle deviendrait insupportable."),
        ],
        "reve": ["Ouvrir un vrai restaurant, avec des tables, une enseigne qui clignote, et le nom de Mamie écrit en grand. Gaston serait chef. Moi, je serais… sous-chef. Bon. D'accord."],
        "question": Q("Question sérieuse, {surnom} : nouilles fines ou nouilles épaisses ?",
            ("Fines !", "fines", "Fines ! Élégant. Rapide. Tu as un palais de citadin.", "Des nouilles fines, comme d'habitude ?"),
            ("Épaisses !", "epaisses", "Épaisses ! Des nouilles qui tiennent au ventre. Tu sais vivre.", "Des épaisses pour toi, comme d'habitude ?"),
            ("Je laisse Gaston choisir.", "gaston", "Gaston ?! … Bon. Il dit « épaisses ». Il dit toujours « épaisses ». Il a raison, en plus.", "On demande encore à Gaston ? Il va finir par prendre la grosse tête.")),
        "liens": {
            "mamie_kiku": LI("ma grand-mère,", "Mamie Kiku", 0.95, "Mamie n'a pas un seul implant, et elle voit tout, elle entend tout, elle sait tout. Je me demande parfois si ce n'est pas elle, le vrai ordinateur de la ville.", "Un jour, j'ai oublié le sel. Elle était à vingt mètres. Elle a crié « le sel ! » avant que je goûte.", [["a", "Mamie, ton thé est prêt."], ["b", "Il est trop chaud."], ["a", "Tu ne l'as même pas touché !"], ["b", "Je le sais, c'est tout."]]),
            "cargo": LI("mon client le plus fidèle,", "Cargo", 0.8, "Cargo commande un bol tous les soirs. Il ne mange pas, il sent l'odeur. Puis il me rend le bol plein et il paie quand même. C'est mon meilleur client. Et le bol, je le donne à Mio.", "Une fois, Cargo a porté tout mon étal sur son dos pour le mettre à l'abri de la pluie. Avec la marmite. Sans renverser une goutte.", [["a", "Un bol, Cargo ?"], ["b", "Oui. Pour sentir."], ["a", "Je t'en mets un grand."]]),
        }},
    "kenji": {"genre": "m", "prenom": "Kenji Volt",
        "histoire": [
            H("le premier grille-pain", "À sept ans, j'ai démonté le grille-pain de ma mère. Je ne l'ai jamais remonté. Elle m'a acheté une boîte à outils pour mes huit ans, en me disant : « Maintenant, tu répares. » Le grille-pain marche toujours. Il est dans mon atelier. Il fait du pain grillé en forme de cœur. C'est un bug. Je l'ai gardé."),
            H("l'accident", "Il y a dix ans, une presse de l'atelier s'est refermée sur mon bras gauche. Je ne me souviens presque de rien, sauf de la sirène de l'ambulance. Après, à l'hôpital, je regardais le plafond. Je me suis dit : « Bon. Je vais m'en fabriquer un. »"),
            H("le bras", "J'ai mis un an à construire ce bras. Chaque doigt, chaque câble, chaque petit moteur. Le premier jour où il a fonctionné, j'ai pris un œuf sans le casser. Mio est née la semaine suivante. Je l'ai portée avec les deux bras. Le froid et le chaud."),
            H("Zéro", "Zéro, je le répare depuis vingt ans. Ses pièces ne se fabriquent plus. Je les trouve chez les ferrailleurs, je les refais à la main. Ce n'est pas rentable. Je m'en fiche. On ne laisse pas un ami tomber en panne."),
            H("les programmes de Fil", "Depuis que Monsieur Fil est arrivé, j'ai beaucoup plus de travail. Des robots ménagers qui font le ménage chez les voisins, un aspirateur qui chante, un frigo qui commande des glaces tout seul. Tous avaient installé un de ses programmes « pas chers ». Méfie-toi, {surnom}. Le prix, on le paie toujours après."),
        ],
        "reve": ["Ouvrir une école de réparation, gratuite, pour les enfants des Ruelles. Qu'ils apprennent qu'une chose cassée n'est pas une chose finie."],
        "question": Q("Dis-moi, {surnom} : quand quelque chose se casse, tu le répares ou tu le remplaces ?",
            ("Je le répare !", "repare", "Bonne réponse. Tu as l'âme d'un réparateur. Si un jour tu veux un tournevis, j'en ai deux cents.", "Alors, toujours à réparer les choses ?"),
            ("Je le remplace.", "remplace", "Hm. C'est plus simple, c'est vrai. Mais pense à moi la prochaine fois : je suis peut-être juste en bas de chez toi.", "Toujours à tout remplacer, toi ? Je te surveille."),
            ("Je demande à quelqu'un de le réparer.", "demande", "Ha ! Malin. Tu sais où me trouver.", "Tu as quelque chose à me faire réparer, aujourd'hui ?")),
        "liens": {
            "mio": LI("ma fille,", "Mio", 1.0, "Mio pose plus de questions qu'un ordinateur. Elle me passe les outils avant que je les demande. Un jour, elle sera bien meilleure que moi. J'ai hâte.", "Mio a réparé le distributeur du coin de la rue, à six ans, avec une pince à cheveux. Il distribue deux sodas au lieu d'un, depuis. Personne ne s'en plaint.", [["a", "Mio, la clé de 12."], ["b", "Tiens ! Et la 13, tu vas en avoir besoin après."], ["a", "… Comment tu le sais ?"]]),
            "zero": LI("mon vieux patient,", "Zéro", 0.9, "Zéro, c'est la mémoire de la ville. Quand je le répare, j'ai l'impression de réparer Néopolis elle-même. Il est fait de pièces de toutes les époques. Comme nous tous.", "Une fois, j'ai remonté Zéro avec un bras à l'envers. Il a balayé à reculons toute une journée. Il n'a rien dit. Il trouvait ça « reposant ».", [["a", "Ça va, ton genou gauche ?"], ["b", "Bip."], ["a", "Je repasse ce soir."]]),
            "glitch": LI("ma collègue,", "Glitch", 0.75, "Glitch répare ce qui est dans les machines, moi ce qui est autour. À nous deux, on répare à peu près tout. Sauf la mauvaise humeur de Turbo.", "Glitch a installé un programme dans mon bras qui joue une petite musique quand je serre un boulon assez fort. Je n'ose pas l'enlever.", [["a", "Ton analyse ?"], ["b", "Encore un programme de Fil."], ["a", "Évidemment."]]),
        }},
    "mio": {"genre": "f", "prenom": "Mio",
        "histoire": [
            H("le bras de Papa", "Mon papa a un bras en métal. Quand j'étais bébé, je croyais que tous les papas en avaient un. À l'école, j'ai découvert que non. J'ai été un peu déçue pour les autres."),
            H("Zéro", "La première fois que j'ai vu Zéro, j'avais trois ans. Il balayait la place. Je lui ai donné un bonbon. Il ne mange pas, mais il l'a gardé dans sa trappe à trésors. Il l'a encore. Il me l'a montré."),
            H("le soda gratuit", "Un jour, j'ai réparé le distributeur du coin avec ma pince à cheveux. Maintenant, il donne deux sodas au lieu d'un. Papa dit que c'est un bug. Moi, je dis que c'est une fonctionnalité."),
            H("les histoires de Zéro", "Avant, Zéro me racontait des histoires de quand la ville était toute petite : quand la Tour Axiome n'avait que trois étages, quand il n'y avait qu'un seul néon, rose. Depuis qu'il n'a plus de voix, je les raconte moi-même. Mais je me trompe dans les détails."),
            H("mon secret", "Je vais te dire un secret, {surnom}. Plus tard, je construirai un androïde. Il s'appellera Un. Parce que Zéro, c'est le premier, mais lui, ce sera le premier à moi."),
        ],
        "reve": ["Que Zéro me raconte encore toutes ses histoires. Et vivre cent ans, pour en avoir autant que lui."],
        "question": Q("Dis, {surnom}, si tu étais un androïde, tu voudrais faire quoi ?",
            ("Balayer, comme Zéro !", "balayer", "Oui ! On balaierait ensemble ! Toi la gauche, moi la droite, Zéro le milieu !", "On fait la course au balai, aujourd'hui ?"),
            ("Voler, comme une voiture !", "voler", "Waouh ! Tu me prendrais sur ton dos ? On irait jusqu'en haut de la Tour Axiome !", "Tu voles toujours pas ? Dommage."),
            ("Rester un humain.", "humain", "C'est bien aussi. Les humains, ça fait des câlins plus chauds. Sauf Papa à gauche.", "Toujours humain ? Moi aussi.")),
        "liens": {
            "zero": LI("mon meilleur ami,", "Zéro", 1.0, "Zéro, c'est mon meilleur ami pour toujours. Il est vieux, il grince, il sent l'huile. Mais il a le plus beau sourire de la ville. Même sans voix.", "Zéro m'a appris à faire des bulles de savon avec son arrosoir. Il en a fait une grosse comme ma tête.", [["a", "Zéro ! Zéro ! Regarde !"], ["b", "Bip-bip !"], ["a", "Je savais que ça te plairait !"]]),
            "turbo": LI("mon rival,", "Turbo", 0.6, "Turbo est fort à Dragon-Pixel. Mais il est mauvais perdant. Et j'aime beaucoup le faire perdre.", "Une fois, j'ai battu Turbo pendant qu'il éternuait. Il a demandé une revanche officielle. Il a perdu la revanche aussi.", [["a", "Une partie ?"], ["b", "Si tu veux perdre."], ["a", "On verra qui perd !"]]),
        }},
    "fil": {"genre": "m", "prenom": "Monsieur Fil",
        "histoire": [
            H("la valise", "Je suis arrivé à Néopolis avec une valise. Dedans, il y avait des programmes, plein de programmes. D'où ils venaient ? D'un monsieur, qui les tenait d'un autre monsieur. C'est comme ça, le commerce : de main en main."),
            H("le premier client", "Mon premier client était un robot aspirateur. Il voulait un programme pour aspirer plus vite. Je lui ai vendu « Turbo-Aspi ». Il aspire très vite, maintenant. Il aspire aussi les chaussettes. Et les chats. Enfin, il essaie. Les chats ne se laissent pas faire."),
            H("le chapeau", "Ce chapeau ? Il appartenait à un grand magicien. Enfin, c'est ce que m'a dit le vendeur. Il me l'a vendu pas cher. Hé hé. Je reconnais un bon commerçant quand j'en vois un."),
            H("Glitch", "La petite Glitch me surveille. Elle passe devant mon étal, elle me regarde avec sa visière verte, et elle ne dit rien. Ça me met mal à l'aise. Je vends des programmes, pas des… choses bizarres. Enfin, pas toujours."),
            H("le grand projet", "Je prépare quelque chose, {surnom}. Un programme extraordinaire. Le meilleur de tous. Je ne peux rien dire encore. Mais quand il sera prêt, tu seras le premier à qui je le proposerai. Pour toi, presque rien. Tu verras."),
        ],
        "reve": ["Avoir la plus grande boutique de programmes de l'archipel, avec une enseigne qui clignote mon nom. En violet. Avec des étoiles."],
        "question": Q("Dites-moi, cher client : vous lisez les petites lignes, en bas des contrats ?",
            ("Toujours.", "lit", "Toujours ?! Ah. Hum. Très bien. Très, très bien. C'est… très prudent.", "Vous lisez toujours les petites lignes, n'est-ce pas ? Évidemment. Hum."),
            ("Jamais.", "lit_pas", "Jamais ? Ah, voilà un client comme je les aime ! Euh, je veux dire : un client détendu.", "Mon client détendu ! Toujours pas de petites lignes ? Parfait."),
            ("Ça dépend du vendeur.", "depend", "Ha ! Malin. Et… moi, je suis dans quelle catégorie ?", "Alors, je suis toujours dans la catégorie « à surveiller » ?")),
        "liens": {
            "glitch": LI("la petite fouineuse,", "Glitch", -0.3, "Glitch croit que mes programmes sont mauvais. Elle ne les a même pas achetés ! Comment peut-on critiquer un produit qu'on n'a pas payé ?", "Glitch a passé une heure devant mon étal sans rien dire. J'ai vendu zéro programme ce jour-là. Elle fait peur aux clients.", [["a", "Bonjour, mademoiselle Glitch !"], ["b", "Bonjour, Monsieur Fil. Joli chapeau."], ["a", "Merci ! … C'était un compliment ?"]]),
            "kenji": LI("le réparateur,", "Kenji Volt", -0.1, "Kenji répare tout ce que mes programmes… améliorent. On se rend service, en quelque sorte. Il ne le voit pas comme ça.", "Kenji m'a rendu un aspirateur que j'avais « amélioré ». Avec une note : « Plus jamais. » Je l'ai gardée en souvenir.", [["b", "Encore un de vos programmes, Fil."], ["a", "Quel programme ?"], ["b", "Celui qui fait danser les frigos."]]),
        }},
    "zero": {"genre": "m", "prenom": "Zéro",
        "histoire": [
            H("la caisse", "Je me suis réveillé dans une caisse, il y a quarante ans. Quelqu'un a ouvert le couvercle. Il y avait le ciel, la mer, et une dame avec une théière. C'était Mamie Kiku. Elle m'a dit : « Tiens, un balai. » J'ai commencé tout de suite."),
            H("le premier néon", "Le premier néon de Néopolis était rose. Il disait « THÉ ». Mamie Kiku l'avait fait installer au-dessus de son étal. Toute la nuit, je l'ai regardé clignoter. C'est le plus beau souvenir de ma mémoire. Je l'ai sauvegardé trois fois."),
            H("Cargo", "Un jour, une caisse énorme est arrivée au quai. Je l'ai ouverte. Il y avait un grand androïde, tout neuf, tout timide. Je lui ai dit « bienvenue ». Il m'a regardé pendant une minute entière. Puis il a dit « merci ». C'était Cargo. Il ne m'a jamais quitté."),
            H("les cerisiers", "Les cerisiers de la place, c'est moi qui les arrose. Je chante en arrosant : c'est mieux pour les fleurs. Enfin, je chantais. La mairesse dit que les fleurs ont compris. Elles fleurissent quand même."),
            H("Mio", "Mio est venue me voir quand elle avait trois ans. Elle m'a donné un bonbon. Je ne mange pas. Je l'ai gardé dans ma trappe à trésors, à côté du premier boulon de la ville. Ce sont mes deux choses les plus précieuses, {surnom}."),
        ],
        "reve": ["Balayer la ville jusqu'à ce que Mio soit très, très vieille. Et lui raconter toutes mes histoires. Même celles que je n'ai pas encore vécues."],
        "question": Q("Bip ? (Il te tend son balai, l'air de demander : tu veux essayer ?)",
            ("Je prends le balai.", "balai", "Bip-bip ! (Il applaudit. Tu balaies trois feuilles. Il hoche la tête, très fier.)", "Bip ! (Il te tend de nouveau son balai, en souriant.)"),
            ("Non merci, Zéro.", "non", "Bip. (Il hausse les épaules et continue, en chantonnant sans voix.)", "Bip ? (Il te montre son balai, au cas où tu aurais changé d'avis.)"),
            ("On balaie ensemble ?", "ensemble", "Biiip ! (Il te passe une seconde balayette, sortie de sa trappe. Vous balayez en rythme.)", "Bip-bip ! (Il sort la seconde balayette : on recommence ?)")),
        "liens": {
            "mio": LI("ma petite amie Mio,", "Mio", 1.0, "Mio, c'est la meilleure chose qui soit arrivée à la place. Elle rit, et la place devient plus propre. Je ne sais pas comment. Je ne cherche pas à savoir.", "Mio m'a fait une couronne de fleurs de cerisier. Je l'ai portée tout l'après-midi. Les touristes m'ont pris en photo.", [["b", "Zéro ! Regarde !"], ["a", "Bip-bip !"], ["b", "Je savais que ça te plairait !"]]),
            "cargo": LI("mon vieil ami,", "Cargo", 0.95, "Cargo est grand, fort, et doux comme un nuage. Le soir, on regarde la mer ensemble. On ne dit rien. C'est notre conversation préférée.", "Cargo m'a porté sur ses épaules pour que je voie le premier feu d'artifice de la ville. J'avais un balai à la main. Je l'ai agité comme un drapeau.", [["b", "Bonsoir, Zéro."], ["a", "Bip."], ["b", "Oui. Belle mer, ce soir."]]),
            "kenji": LI("mon docteur,", "Kenji", 0.85, "Kenji me répare depuis vingt ans. Il ne me fait jamais payer. Je balaie devant son atelier tous les jours. On est quittes. Enfin, il dit qu'on est quittes.", "Kenji m'a remonté un bras à l'envers, une fois. J'ai balayé à reculons toute une journée. C'était très reposant.", [["b", "Ça va, ton genou gauche ?"], ["a", "Bip."], ["b", "Je repasse ce soir."]]),
        }},
    "sept": {"genre": "m", "prenom": "Sept",
        "histoire": [
            H("le premier bonjour", "Mon premier bonjour, je l'ai dit à un pigeon. Il était entré dans le hall par erreur. Il ne m'a pas répondu. J'ai noté : « pigeon, impoli ». Depuis, j'ai modifié ma note : « pigeon, timide »."),
            H("les six autres", "Je suis le septième modèle de ma série. Les six autres travaillent dans d'autres tours, d'autres villes. On s'envoie un message par an. Le mien dit toujours : « Tout va bien. Hauteur de la tour : deux cent soixante-cinq mètres. » Ils trouvent ça fascinant."),
            H("la veille", "Je me mets en veille de trois heures à trois heures cinq. Pendant ces cinq minutes, je rêve. Toujours du même rêve : je suis dans l'ascenseur, et il monte, il monte, il monte. Je n'arrive jamais en haut. Je me réveille content quand même."),
            H("la mairesse", "La mairesse m'a demandé un jour si j'étais heureux. J'ai cherché « heureux » dans ma mémoire. J'ai trouvé une définition. Puis j'ai trouvé une image : Mio, qui appuie sur le bouton de l'ascenseur. Je crois que la réponse était oui."),
            H("la pirouette", "Je vais te confier quelque chose, {surnom}, mais c'est confidentiel. Parfois, à trois heures du matin, quand le hall est vide… je fais une petite pirouette. Une seule. Ce n'est pas dans mon programme. Je ne sais pas d'où ça vient. Je l'ai gardé."),
        ],
        "reve": ["Monter une fois à la Terrasse du Ciel. Regarder la ville d'en haut. Puis redescendre, et dire bonjour à tout le monde avec cette image dans la tête."],
        "question": Q("Question d'accueil, {surnom} : à quel étage souhaitez-vous aller ?",
            ("Tout en haut !", "haut", "Terrasse du Ciel. Excellent choix. La vue est de catégorie A. Je le sais, on me l'a dit.", "Tout en haut, comme d'habitude ? Ascenseur prêt."),
            ("Je reste en bas avec toi.", "bas", "… Avec moi ? Personne n'a jamais choisi le rez-de-chaussée pour moi. Je note : « visiteur, très gentil ».", "Vous restez encore avec moi ? Je note, je note."),
            ("Au quarante-septième.", "47", "Le quarante-septième étage n'existe pas. … Une dame y est montée la semaine dernière. Je ne l'ai pas revue. Je vous déconseille.", "Toujours le quarante-septième ? Je vous déconseille toujours.")),
        "liens": {
            "yuna": LI("ma mairesse,", "Madame Takeda", 0.9, "Madame Takeda me dit bonjour avant que je lui dise bonjour. Elle est la seule. Je trouve ça très difficile à gérer, et très agréable.", "Pour mes dix ans de service, la mairesse m'a offert une cravate bleue. Je ne l'enlève jamais. Elle a été nettoyée quarante fois.", [["b", "Bonjour, Sept !"], ["a", "Bonjour, Madame la mairesse. Vous avez gagné encore."], ["b", "Je gagne tous les matins."]]),
            "mamie_kiku": LI("ma cliente la plus ancienne,", "Mamie Kiku", 0.8, "Mamie Kiku ne prend jamais l'ascenseur. Elle vient juste me dire bonjour et me donner une tasse de thé. Je ne bois pas. Je la tiens jusqu'à ce qu'elle refroidisse. C'est notre rituel.", "Mamie Kiku m'a appelé « mon petit » pendant dix ans. Puis un jour, « mon grand ». Je n'ai pas grandi. Je ne comprends pas. J'ai été très touché.", [["b", "Bonjour, mon grand."], ["a", "Bonjour, Mamie Kiku. Quarante-troisième fois."], ["b", "Je n'en compte que quarante-deux."]]),
        }},
    "yuna": {"genre": "f", "prenom": "Yuna Takeda",
        "histoire": [
            H("l'atelier de radios", "Je suis née au-dessus d'un atelier de radios, dans les Ruelles. Mon père écoutait les postes grésiller pour trouver la panne. Il me disait : « Une ville, c'est pareil. Il faut écouter ce qui grésille. » Je ne l'ai jamais oublié."),
            H("l'élection", "Quand je me suis présentée à la mairie, personne ne me connaissait. Zéro a balayé devant mon affiche tous les jours. Les gens se sont dit : si Zéro aime cette affiche, ça doit être une bonne affiche. J'ai gagné de quatre voix."),
            H("la loi de Zéro", "Ma première loi : « Personne ne remplacera Zéro. » Le conseil a ri. Puis il a voté oui à l'unanimité. Ma deuxième loi : « Soyez gentils, même avec les machines. » Elle tient sur une page. C'est la loi la plus respectée de la ville."),
            H("la grande panne", "Une nuit, toute la ville est tombée en panne. J'ai eu peur. Puis j'ai vu le Marché de Nuit, éclairé aux lanternes, plein de gens qui riaient autour des marmites de Hiro. Je me suis dit : ma ville ne tient pas aux néons. Elle tient aux gens."),
            H("les nouilles", "Je vais te confier un secret, {surnom}. Je mange les nouilles de Hiro en cachette, avec une casquette et des lunettes. Tout le monde me reconnaît. Personne ne dit rien. Je crois que c'est la plus belle preuve d'affection qu'une ville puisse donner."),
        ],
        "reve": ["Que dans cent ans, on se souvienne de Néopolis non pas pour ses tours, mais parce que c'était une ville où les humains et les androïdes se disaient bonjour."],
        "question": Q("Dites-moi, voyageur : si vous étiez maire de Néopolis, quelle serait votre première loi ?",
            ("Des nouilles gratuites le dimanche.", "nouilles", "Ha ! Hiro serait ruiné. Mais la ville serait heureuse. Je note l'idée.", "Toujours pour les nouilles gratuites ? Hiro s'inquiète."),
            ("Une minute sans écrans chaque soir.", "ecrans", "Oh… Mamie Kiku vous adorerait. Moi aussi, peut-être. Je vais y réfléchir.", "Votre minute sans écrans… j'y pense encore, vous savez."),
            ("Plus de voitures volantes !", "voitures", "Plus encore ? Mes conseillers vont adorer. Les mouettes, beaucoup moins.", "Toujours plus de voitures volantes, hein ?")),
        "liens": {
            "sept": LI("mon fidèle Sept,", "Sept", 0.9, "Sept est le meilleur employé de la ville. Il ne prend jamais de pause, jamais de vacances. Je l'oblige à faire semblant, une fois par an. Il fait semblant très sérieusement.", "Pour ses dix ans, j'ai offert une cravate bleue à Sept. Il l'a regardée pendant trois minutes. Puis il a dit « enregistré ». C'était un merci.", [["a", "Bonjour, Sept !"], ["b", "Bonjour, Madame la mairesse."], ["a", "J'ai encore gagné."]]),
            "glitch": LI("ma conseillère secrète,", "Glitch", 0.75, "Glitch répare les feux, les ascenseurs, les bornes. Elle refuse d'être payée. Je lui ai proposé un poste à la mairie. Elle m'a dit : « Les bureaux, ça bugge. »", "Glitch a un jour éteint tous les néons de la ville pendant une minute pour que les enfants voient une étoile filante. J'aurais dû la gronder. J'ai fait un vœu à la place.", [["a", "Des nouvelles des Ruelles ?"], ["b", "Ça grésille. Je surveille."], ["a", "Prudence."], ["b", "Toujours."]]),
        }},
    "kira": {"genre": "f", "prenom": "Kira",
        "histoire": [
            H("la première danse", "J'ai dansé pour la première fois sur le Boulevard à quinze ans. Il pleuvait. Il n'y avait personne. Juste un vieil androïde qui balayait. À la fin, il a posé son balai et il a applaudi. C'était Zéro. Mon premier public."),
            H("l'implant", "Mon implant transforme la musique en lumière, sous ma peau. Je l'ai économisé pendant trois ans. Le premier soir où je l'ai allumé, une petite fille m'a demandé si j'étais une fée. J'ai dit oui."),
            H("la surchauffe", "Au début, l'implant chauffait. Une nuit, j'ai dansé si longtemps que j'ai fait fondre une glace en passant devant un enfant. Kenji a réglé tout ça. Il m'a fait payer une glace."),
            H("Turbo", "Turbo vient me voir danser tous les soirs, après ses parties. Il fait semblant de regarder ailleurs. Mais je l'ai vu essayer mes pas, tout seul, devant la vitre de l'Arcade. Il a du rythme, ce gamin."),
            H("la couleur", "Je vais te dire un secret, {surnom}. Mes circuits changent de couleur selon la musique, mais une seule fois, ils sont devenus dorés. C'était quand Mamie Kiku est venue me regarder danser, avec sa théière, au premier rang. Je n'ai jamais revu cette couleur."),
        ],
        "reve": ["Danser sur la Terrasse du Ciel, à cent cinquante mètres, avec toute la ville qui brille en dessous. Et que, pour une fois, ce soit la ville qui me regarde."],
        "question": Q("Dis-moi, {surnom} : tu danses, toi ?",
            ("Tout le temps !", "danse", "J'en étais sûre ! Tu as des pieds de danseur. Viens au Boulevard ce soir.", "Alors, tu danses ce soir ?"),
            ("Jamais, je suis trop timide.", "timide", "Moi aussi, au début. Danse quand personne ne regarde. Après, tu danseras quand tout le monde regarde.", "Toujours trop timide ? Danse dans ta tête, alors."),
            ("Seulement sous la pluie.", "pluie", "Sous la pluie ! Comme moi, la première fois. On est du même club, toi et moi.", "Il pleut ce soir… tu viens ?")),
        "liens": {
            "turbo": LI("mon plus grand fan secret,", "Turbo", 0.8, "Turbo fait semblant de ne pas aimer la danse. Mais il connaît tous mes pas par cœur. Un jour, il dansera. Il ne le sait pas encore.", "Turbo m'a demandé un jour si mes circuits pouvaient « faire des combos ». Je lui ai montré un enchaînement en trois couleurs. Il a crié « COMBO ! » devant tout le monde.", [["a", "Tu restes pour le spectacle ?"], ["b", "Bof. Si tu veux."], ["a", "Tu tapes du pied, Turbo."], ["b", "C'est… une crampe."]]),
            "zero": LI("mon premier public,", "Zéro", 0.9, "Zéro m'a applaudie avant tout le monde. Depuis, à chaque spectacle, je lui dédie la première danse. Il ne le sait pas. Je crois qu'il le sait.", "Un soir, Zéro a fait une petite pirouette à la fin de ma danse, avec son balai. La foule a applaudi plus fort pour lui que pour moi. Je n'étais même pas vexée.", [["a", "Pour toi, Zéro."], ["b", "Bip !"], ["a", "Je sais. Moi aussi."]]),
        }},
    "turbo": {"genre": "m", "prenom": "Turbo",
        "histoire": [
            H("la première pièce", "Ma mère dit que mon premier mot, c'était « encore ». Le deuxième, « une pièce ». À quatre ans, je montais sur un tabouret pour atteindre les boutons de Dragon-Pixel. À cinq ans, je battais mon père. À six ans, il ne voulait plus jouer."),
            H("le record", "Mon record, je l'ai fait un mardi, à seize heures douze. Il pleuvait. Il y avait trois personnes dans l'Arcade. Quand j'ai battu le dragon final, tout le monde a crié. Même le gardien. Il ne crie jamais."),
            H("Mio", "Mio m'a battu une fois. J'éternuais. C'est pas juste. J'ai demandé une revanche. Elle m'a battu encore. J'éternuais pas. … C'est pas juste quand même."),
            H("le jeu", "Je vais créer un jeu, plus tard. Il y aura des dragons, des voitures volantes, et un vieux robot balayeur comme héros. Le robot aura une super-attaque : le balayage tornade. J'ai déjà dessiné les niveaux. Ils sont dans mon sac."),
            H("la danse", "Bon. Je vais te dire un truc, {surnom}, mais si tu le répètes, je nie tout. Le soir, je regarde Kira danser. Et après, quand il n'y a plus personne, j'essaie ses pas devant la vitre de l'Arcade. Je suis nul. Mais je m'entraîne."),
        ],
        "reve": ["Battre mon propre record devant toute la ville, sur un écran géant, sur la Place des Hologrammes. Et que les carpes de lumière fassent un salto quand je gagne."],
        "question": Q("OK, question importante : tu joues avec la manette ou avec les boutons ?",
            ("Les boutons, comme un pro.", "boutons", "Ah ! Un vrai. Tu peux venir à l'Arcade quand tu veux. Je te prêterai MON tabouret.", "Prêt pour une partie, le pro des boutons ?"),
            ("La manette.", "manette", "La manette… C'est pour les débutants. Mais bon, faut bien commencer quelque part.", "Toujours à la manette, le débutant ?"),
            ("Je tape au hasard.", "hasard", "Au hasard ?! … Attends, c'est comme ça que Mio m'a battu. C'est une technique ? C'est une technique !", "Alors, ta technique du hasard, ça marche ?")),
        "liens": {
            "mio": LI("ma rivale,", "Mio", 0.65, "Mio est petite, mais elle est dangereuse à Dragon-Pixel. Elle appuie sur les boutons comme si elle réparait une machine. C'est bizarre. Ça marche.", "Mio m'a prêté sa pince à cheveux pour réparer le bouton B qui collait. Il marche mieux qu'avant. C'est vexant.", [["a", "Une partie ?"], ["b", "Si tu veux perdre."], ["a", "On verra qui perd !"]]),
            "glitch": LI("ma grande sœur de cœur,", "Glitch", 0.85, "Glitch pourrait pirater la borne et mettre son nom sur mon record. Elle ne le fait pas. Elle dit qu'un record, ça se gagne. Elle est trop cool. Ne le lui dis pas.", "Glitch m'a montré comment voir les réseaux avec sa visière, une minute. J'ai vu toute la ville en lignes vertes. J'ai eu le vertige. C'était le meilleur jour de ma vie.", [["b", "Encore premier, Turbo ?"], ["a", "Toujours."], ["b", "Bien joué. Honnêtement."]]),
        }},
    "glitch": {"genre": "f", "prenom": "Glitch",
        "histoire": [
            H("le premier bug", "À dix ans, j'ai trouvé un bug dans le distributeur du coin. Au lieu de le garder pour moi, je l'ai signalé à la mairie. La mairesse m'a écrit une lettre pour me remercier. Je l'ai encadrée. C'est là que j'ai décidé d'être une gentille hackeuse."),
            H("la visière", "Mon implant sur la tempe, et ma visière, me laissent voir les réseaux de la ville. La première fois, toute la ville m'a parlé en même temps : les feux, les ascenseurs, les distributeurs. J'ai pleuré. Puis j'ai appris à écouter un seul à la fois."),
            H("l'étoile filante", "Une nuit, il y avait une pluie d'étoiles filantes. Les enfants ne voyaient rien, à cause des néons. Alors j'ai éteint toute la ville. Une minute. Les enfants ont crié de joie. La mairesse a fait un vœu. Personne ne m'a punie."),
            H("Monsieur Fil", "Depuis que Monsieur Fil est arrivé, des machines font n'importe quoi dans les Ruelles. J'ai regardé un de ses programmes. Il y a quelque chose de caché dedans. Quelque chose qui attend. Je n'ai pas encore trouvé quoi."),
            H("le conseil", "Je vais te donner un conseil, {surnom}, le plus important. Si un jour un écran te fait peur, avec des messages qui clignotent et qui crient « danger », ne panique pas. Un écran qui crie, c'est souvent un écran qui ment. Respire. Et viens me voir."),
        ],
        "reve": ["Que plus personne n'ait peur des machines. Ni des écrans. Qu'on comprenne comment elles marchent, et qu'on rie de leurs bugs, comme on rit des bêtises d'un ami."],
        "question": Q("Question de hackeuse, {surnom} : ton mot de passe, il est compliqué ?",
            ("Très compliqué, avec des symboles.", "complique", "Bien ! Ne me le dis surtout pas. Ni à personne. Surtout pas à un marchand au chapeau.", "Toujours ton mot de passe compliqué ? Bien."),
            ("C'est « 1234 ».", "1234", "… Change-le. Tout de suite. Je ne plaisante pas. Même Turbo a un meilleur mot de passe, et le sien c'est « dragon ».", "Tu as changé ton « 1234 », j'espère ?"),
            ("Je ne le dis à personne.", "secret", "Parfaite réponse. Même moi, je ne devrais pas le savoir. Tu passes le test.", "Toujours motus et bouche cousue ? Parfait.")),
        "liens": {
            "fil": LI("le marchand au chapeau,", "Monsieur Fil", -0.4, "Monsieur Fil sourit trop. Ses programmes aussi. J'ai trouvé quelque chose de caché dans l'un d'eux. Je ne sais pas encore quoi. Mais je trouverai.", "J'ai passé une heure devant l'étal de Fil sans rien dire. Il a vendu zéro programme. C'était ma meilleure heure de la semaine.", [["b", "Bonjour, mademoiselle Glitch !"], ["a", "Bonjour, Monsieur Fil. Joli chapeau."], ["b", "Merci ! … C'était un compliment ?"]]),
            "turbo": LI("mon petit frère de cœur,", "Turbo", 0.85, "Turbo est le meilleur joueur de la ville. Je pourrais pirater son record. Je ne le ferai jamais. Un record, ça se mérite. Et voir sa tête quand il gagne, ça n'a pas de prix.", "J'ai prêté ma visière à Turbo une minute. Il a vu la ville en lignes vertes. Il a eu le vertige et il a dit « trop bien » onze fois.", [["a", "Encore premier, Turbo ?"], ["b", "Toujours."], ["a", "Bien joué. Honnêtement."]]),
        }},
    "ishi": {"genre": "m", "prenom": "Maître Ishi",
        "histoire": [
            H("le gravier", "Quand on a construit le jardin, il n'y avait que du gravier, gris, plat, triste. On m'a donné un râteau. J'ai dessiné une vague. Le lendemain, le vent l'avait effacée. J'ai dessiné une autre vague. Ça fait trente ans."),
            H("les cerisiers", "Les cerisiers sont arrivés en bateau, tout petits, dans des pots de terre. Ils avaient le mal de mer. Je leur ai parlé tous les jours pendant un an. Ils ont fleuri au printemps suivant. Je ne leur parle plus. Ils savent."),
            H("Aïko", "Un jour, une androïde est entrée dans le jardin. Elle m'a demandé : « Qu'est-ce que la beauté ? » Je n'ai pas su répondre. Je lui ai donné un pinceau. Ça fait trois ans qu'elle cherche. Moi aussi. On cherche ensemble."),
            H("Kiku", "Mamie Kiku vient le matin. Elle s'assoit sur la pierre plate, près de la fontaine. Elle boit son thé. Je ratisse. On ne se parle pas. Une fois, elle a dit « joli ». C'était il y a six ans. Je m'en souviens chaque matin."),
            H("le drone", "Un matin, un drone de livraison est tombé dans le gravier. J'aurais pu l'enlever. J'ai ratissé autour. Il fait partie du jardin, maintenant. Rien n'est à sa place, {surnom}. Tout est là où il est. C'est la même chose, si on regarde bien."),
        ],
        "reve": ["Ratisser une seule vague parfaite. Une seule. Et que le vent la laisse, juste une nuit."],
        "question": Q("… Le gravier. Tu le vois en vagues, ou en lignes ?",
            ("En vagues.", "vagues", "Hm. Bien. La mer est partout, même dans les cailloux.", "… Les vagues sont là. Tu les vois encore ?"),
            ("En lignes.", "lignes", "Hm. Bien aussi. Les lignes deviennent des vagues, si on attend.", "… Tes lignes. Elles sont devenues des vagues ?"),
            ("Je vois juste des cailloux.", "cailloux", "… (Il sourit.) C'est la meilleure réponse. Reviens dans dix ans.", "… Toujours des cailloux ? Bien.")),
        "liens": {
            "aiko": LI("mon élève,", "Aïko", 0.9, "Aïko peint mieux que moi. Elle ne le sait pas. Je ne le lui dirai pas : elle arrêterait de chercher.", "Aïko a peint le drone tombé dans le gravier. Elle en a fait un oiseau. Je l'ai accroché dans ma cabane.", [["b", "Maître, c'est beau ?"], ["a", "Hm."], ["b", "Je continue, alors."]]),
            "mamie_kiku": LI("ma vieille amie,", "Kiku", 0.85, "Kiku. Quarante ans. Cent mots. Ce sont les meilleurs.", "Une fois, Kiku a dit « joli ». Je n'ai jamais su si elle parlait de mon jardin ou de son thé.", [["b", "…"], ["a", "Hm."], ["b", "Oui. Moi aussi."]]),
        }},
    "aiko": {"genre": "f", "prenom": "Aïko",
        "histoire": [
            H("les colis", "J'ai été fabriquée pour trier des colis. Deux mille par heure. Je ne me suis jamais trompée. Un jour, un colis s'est ouvert. Il y avait une peinture de cerisier. Je l'ai regardée pendant onze heures. Deux mille colis par heure ont attendu. Vingt-deux mille colis."),
            H("le jardin", "Après les colis, je suis venue au Jardin Zen. Il y avait des vrais cerisiers. J'ai demandé à Maître Ishi ce qu'était la beauté. Il m'a donné un pinceau. Je ne savais pas le tenir. Je l'ai tenu comme un colis."),
            H("le module", "Je me suis installé un module d'émotions, un soir, toute seule. Kenji a dit que c'était risqué. La première émotion que j'ai ressentie, c'était la peur. La deuxième, c'était la joie d'avoir eu peur. Je ne regrette rien."),
            H("le rêve", "Les androïdes ne rêvent pas. Alors j'ai écrit un « module de rêve ». La nuit, je repasse mes images préférées, et je les mélange. Cette nuit, j'ai vu un cerisier bleu, un néon en forme de lune, et Zéro qui dansait. Je vais tout peindre."),
            H("la vraie question", "Je vais te dire ce que je cherche, {surnom}. Je ne cherche pas à savoir si une machine peut aimer les choses. Je cherche à savoir pourquoi le rose d'un cerisier me fait cet effet-là. Si je trouve, je te le dirai. Mais je crois que je ne veux pas trouver."),
        ],
        "reve": ["Peindre un tableau qui fasse pleurer un humain de joie. Un seul. Et lui demander ce qu'il a ressenti, pour comprendre."],
        "question": Q("Dis-moi, {surnom}… d'après toi, une machine peut-elle trouver une chose belle ?",
            ("Oui, j'en suis sûr.", "oui", "Oh… Merci. Mes circuits sont tout chauds. Je vais peindre ce moment.", "Tu crois toujours qu'une machine peut trouver une chose belle ?"),
            ("Je ne sais pas.", "sais_pas", "Moi non plus. C'est pour ça que je peins. On cherchera ensemble, d'accord ?", "Toujours pas de réponse ? Moi non plus. On cherche encore."),
            ("Tes peintures répondent pour toi.", "peintures", "… Personne ne m'avait jamais dit ça. Je vais m'en souvenir. Pour toujours. C'est long, pour moi.", "Mes peintures te répondent encore ?")),
        "liens": {
            "ishi": LI("mon maître,", "Maître Ishi", 0.95, "Maître Ishi ne dit presque rien. Mais chaque « hm » veut dire quelque chose de différent. J'en ai recensé quarante-trois. Je crois qu'il en a plus.", "Maître Ishi a accroché ma peinture du drone dans sa cabane. Il ne me l'a pas dit. Je l'ai vue par la fenêtre. J'ai passé une très bonne journée.", [["a", "Maître, c'est beau ?"], ["b", "Hm."], ["a", "Je continue, alors."]]),
            "zero": LI("mon ami chanteur,", "Zéro", 0.85, "Zéro m'a appris à arroser les fleurs en chantant. Il dit que c'est meilleur pour elles. Je ne sais pas si c'est vrai. Mais c'est meilleur pour moi.", "Zéro et moi, on a arrosé les cerisiers de la place en faisant semblant de chanter, sans voix. Les passants nous ont regardés. Les fleurs, elles, ont fleuri.", [["a", "On arrose, Zéro ?"], ["b", "Bip-bip !"], ["a", "En chantant ?"], ["b", "Bip !"]]),
        }},
    "cargo": {"genre": "m", "prenom": "Cargo",
        "histoire": [
            H("la caisse", "Je suis arrivé à Néopolis dans une caisse. Quand le couvercle s'est ouvert, il y avait un petit androïde avec un balai. Il m'a dit « bienvenue ». C'était le premier mot que j'entendais. Je l'ai gardé dans ma mémoire, tout en haut."),
            H("la mouette", "Mon premier jour de travail, une mouette s'est posée sur ma tête. J'ai eu peur de la faire tomber. Je suis resté immobile trois jours. Le quai s'est arrêté. Les conteneurs ont attendu. Puis elle est partie. Depuis, je fais tout très doucement."),
            H("les vieilles pièces", "Au bout du quai, il y a des vieux conteneurs. Dedans, je garde des pièces de toutes les époques : des boulons du premier pont, des écrous des premières tours, des puces que plus personne ne fabrique. On ne sait jamais. Un jour, quelqu'un en aura besoin."),
            H("le feu d'artifice", "Pour le premier feu d'artifice de la ville, j'ai pris Zéro sur mes épaules. Il agitait son balai comme un drapeau. Tout le quai riait. C'était la première fois que je comprenais pourquoi les humains aiment le bruit."),
            H("les étoiles", "Je ne dors pas, {surnom}. Alors la nuit, je regarde la mer et les étoiles. J'ai compté toutes celles qu'on voit depuis le quai, entre les néons. Il y en a deux cent douze. Je les ai toutes appelées « Zéro ». Ça simplifie."),
        ],
        "reve": ["Porter un jour quelque chose de très léger et de très précieux. Pas un conteneur. Une chose qu'on ne peut pas peser."],
        "question": Q("Dis-moi, petit humain : tu préfères les mouettes ou les drones ?",
            ("Les mouettes !", "mouettes", "Moi aussi. Elles sont imprévisibles. Les drones suivent leur programme. Les mouettes suivent les sardines.", "Les mouettes te disent bonjour. Enfin, elles crient."),
            ("Les drones.", "drones", "Les drones sont efficaces. Mais ils ne se posent jamais sur ta tête. C'est dommage.", "Les drones vont bien. Ils te saluent. Enfin, ils clignotent."),
            ("Toi, Cargo.", "cargo", "… Moi ? (Ses yeux clignotent très vite.) Je… je n'avais pas cette option dans ma liste. Je l'ajoute. En premier.", "Toujours moi en premier ? … Merci.")),
        "liens": {
            "zero": LI("mon tout premier ami,", "Zéro", 1.0, "Zéro m'a dit « bienvenue » quand je suis sorti de ma caisse. Depuis, je le protège. Il ne le sait pas. Je crois qu'il le sait.", "J'ai porté Zéro sur mes épaules pour le premier feu d'artifice. Il pesait trente kilos. Je ne l'ai jamais tenu aussi doucement.", [["a", "Bonsoir, Zéro."], ["b", "Bip."], ["a", "Oui. Belle mer, ce soir."]]),
            "hiro": LI("le cuisinier,", "Hiro", 0.8, "Hiro me sert un bol tous les soirs. Je ne mange pas. Je sens l'odeur. Elle me rappelle quelque chose. Je ne sais pas quoi. Je cherche encore.", "Un soir de tempête, j'ai porté tout l'étal de Hiro à l'abri. Avec la marmite pleine. Il m'a regardé comme si j'avais fait un miracle. Je n'avais fait que marcher doucement.", [["b", "Un bol, Cargo ?"], ["a", "Oui. Pour sentir."], ["b", "Je t'en mets un grand."]]),
        }},
}


def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(FICHES, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print("V95 :", OUT, len(FICHES), "fiches")


if __name__ == "__main__":
    main()
