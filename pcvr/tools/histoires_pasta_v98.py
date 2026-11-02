"""V98 : les fiches d'histoires des adeptes de l'Île Al Dente (data/histoires_v65/pasta.json) : l'histoire
de chacun (des souvenirs racontés quand on le connaît mieux), son rêve, sa question au voyageur, ses
liens avec les autres (ce qu'il en pense, une anecdote, un petit dialogue quand ils se croisent).
Textes écrits ici, versés au domaine public (CC0 1.0).
Lancement (depuis la racine du dépôt) : python3 -B pcvr/tools/histoires_pasta_v98.py
"""
import json
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "data" / "histoires_v65" / "pasta.json"


def H(titre, t):
    return {"titre": titre, "t": t}


def Q(texte, *reps):
    return {"texte": texte, "reponses": [{"label": a, "valeur": b, "t": c, "rappel": d} for a, b, c, d in reps]}


def LI(qui, nom, s, avis, anecdote, bav):
    return {"qui": qui, "nom": nom, "sentiment": s, "avis": avis, "anecdotes": [anecdote], "bavardage": bav}


FICHES = {
    "farfalle": {"genre": "m", "prenom": "Révérend Père Farfalle",
        "histoire": [
            H("la marmite renversée", "J'étais cuisinier sur un grand voilier. Un soir de tempête, le bateau a penché, et ma marmite de spaghettis s'est renversée sur le pont. Les nouilles ont glissé, se sont emmêlées… et ont dessiné un visage. Deux boulettes pour les yeux. Il me souriait. Tout l'équipage a vu. Le capitaine a dit : « C'est la fatigue. » Moi, j'ai su que c'était un appel."),
            H("l'île sans nom", "Le voilier m'a déposé ici. Il n'y avait qu'un volcan qui sentait la tomate, des champs de blé sauvage et trois pêcheurs. J'ai planté une louche dans le sable, et j'ai dit : « Ici, on mangera ensemble. » Les pêcheurs ont dit oui. Surtout pour le « mangera »."),
            H("la plus grande passoire", "Le temple, on l'a construit en sept ans. Tout le monde voulait un toit. J'ai dit : un toit plein, c'est une prison ; un toit percé, c'est une prière. On a fait une passoire. Le premier jour de soleil, la lumière est tombée par mille trous sur nos têtes. Personne n'a parlé pendant une heure. C'était la plus belle messe de ma vie."),
            H("le jour où il est apparu", "Un matin, au-dessus du temple, il y avait… lui. Le Grand Spaghetti Volant. Il flottait, il nous regardait, il a cligné des yeux. Mamma Lasagna a laissé tomber sa pâte. Nonno Tortellini a dit : « Il m'a fait un clin d'œil. » Moi, je me suis mis à genoux. Ma passoire est tombée. Il a rigolé, je crois. Une nouille a frétillé."),
            H("le secret du Révérend", "Je vais te dire un secret, {surnom}. Je ne sais pas comment il tient en l'air. Je ne sais pas d'où il vient. Je sais seulement que, depuis qu'il est là, tout le monde mange ensemble, personne ne mange seul, et on rit beaucoup. C'est peut-être ça, le miracle. Le reste, c'est de la sauce."),
        ],
        "reve": ["Voir un jour toutes les îles de l'archipel assises à la même table, une immense Grande Tablée d'une rive à l'autre, avec une seule nappe à carreaux, et le Grand Spaghetti qui sert tout le monde avec ses nouilles."],
        "question": Q("Dis-moi, mon enfant : quand tu manges des spaghettis, tu les enroules ou tu les aspires ?",
            ("Je les enroule autour de la fourchette.", "enrouler", "Bien ! Avec patience, avec respect. Comme on enroule une prière autour de son cœur. Ramen.", "Toujours à enrouler tes spaghettis, mon enfant ? Bien, bien."),
            ("Je les aspire, slurp !", "aspirer", "Slurp ! Ha ha ! Le Grand Spaghetti aime le bruit. C'est la preuve qu'on aime ce qu'on mange. Mais essuie ton menton.", "Toujours slurp, mon enfant ? Ne mens pas, j'ai vu ton menton."),
            ("Je les coupe au couteau.", "couper", "Au… au couteau ? (Il chancelle.) Mon enfant… Assieds-toi. Respire. Nous allons parler de la Recommandation numéro trois.", "Tu ne les coupes plus au couteau, j'espère ? Mon cœur ne le supporterait pas.")),
        "liens": {
            "penne": LI("ma cheffe de chœur,", "Sœur Penne", 0.85, "Sœur Penne chante faux, très fort, et avec tout son cœur. Le Grand Spaghetti a les oreilles sensibles, mais il ne dit rien. Moi non plus. La foi, c'est aussi ça.", "Un jour, elle a chanté si fort que ma passoire a vibré. J'ai entendu le cantique dans ma tête pendant trois jours.", [["a", "Sœur Penne, un peu moins fort, peut-être ?"], ["b", "Plus fort, Révérend ? D'accord !"], ["a", "… Ramen."]]),
            "linguini": LI("mon novice,", "Frère Linguini", 0.9, "Linguini casse tout, oublie tout, s'endort pendant la prière. Mais il a le cœur le plus doux de l'île. Un jour, il sera un grand prêtre. Si le temple tient jusque-là.", "Il a voulu repeindre l'autel en doré. Il a peint le chat de Mamma Lasagna. Le chat était très fier.", [["a", "Frère Linguini, où est l'assiette éternelle ?"], ["b", "Sur l'autel, Révérend !"], ["a", "Bien."], ["b", "… Enfin, presque toute."]]),
            "rigatoni": LI("le vieux pirate,", "Capitaine Rigatoni", 0.8, "Les pirates sont les premiers fidèles du Grand Spaghetti. Le Capitaine le sait, et il en profite : il vient à la messe avec son perroquet, et Pesto répond « Ramen » avant tout le monde.", "Le Capitaine m'a juré qu'il avait perdu la Râpe d'Or. Il me l'a juré sur sa barbe. Sa barbe a rougi.", [["a", "Capitaine, vous viendrez à la messe ?"], ["b", "Arrr, si Pesto est d'accord."], ["a", "Pesto est toujours d'accord."]]),
        }},
    "penne": {"genre": "f", "prenom": "Sœur Penne",
        "histoire": [
            H("le dernier rang", "À l'opéra de la grande ville, j'étais au dernier rang du chœur, derrière une colonne. Pendant dix ans, personne n'a vu mon visage. Le soir de mon dernier spectacle, j'ai chanté si fort que la colonne a tremblé. On m'a demandé de partir. J'ai pris un bateau pour l'endroit le plus loin possible."),
            H("la première messe", "Le premier soir sur l'île, il y avait une messe. Ils chantaient tous, mal, avec de la sauce sur le menton. Je me suis levée, j'ai chanté. Le Révérend a ouvert de grands yeux. Puis il a dit : « Enfin quelqu'un qui chante plus faux que moi, mais plus fort ! » J'ai été nommée cheffe de chœur le lendemain."),
            H("le cantique de la boulette", "J'ai écrit un cantique, « Ô Boulette, ronde et brune ». Sept couplets. Le refrain dit seulement « Ramen ». Tout le monde le connaît par cœur, même Pesto, le perroquet. Surtout Pesto. Il le chante la nuit."),
            H("Tagliatelle", "J'ai rencontré Tagliatelle sur la plage. Elle jouait du violon à trois cordes. Je chantais. Le Capitaine nous a dit que les mouettes s'étaient enfuies. On a décidé de vivre ensemble : comme ça, on ne gêne que nos voisins, et pas les oiseaux."),
            H('le diapason', "Le Révérend m'a offert un diapason en argent pour mes dix ans de chœur. Je ne m'en sers jamais : je chante toujours un peu plus haut que la note. Mais je le garde contre mon cœur. Quand je le fais sonner, la nuit, Tagliatelle grogne, et le Grand Spaghetti ouvre un œil."),
        ],
        "reve": ["Faire chanter toute l'île en même temps, du Borgo jusqu'à la Marmite, et que le Grand Spaghetti tape du pied. S'il a des pieds. Il doit bien avoir des pieds quelque part."],
        "question": Q("Question de cheffe de chœur, {surnom} : tu chantes sous la douche ?",
            ("Oui, très fort !", "fort", "Bravo ! La douche, c'est la meilleure salle de concert du monde. Viens au chœur, on a besoin de puissance.", "Toujours à chanter sous la douche ? On t'entend d'ici, tu sais."),
            ("Non, jamais.", "jamais", "Jamais ? Oh, {surnom}… Il faut essayer ! Commence par un petit « Ramen ». Tout doucement. Voilà.", "Tu as essayé, sous la douche ? Même un tout petit Ramen ?"),
            ("Seulement quand personne n'écoute.", "secret", "Ha ! Un chanteur timide. Les plus belles voix se cachent toujours. Je finirai par t'entendre.", "Personne n'écoute, là. Tu chantes un peu ? Non ?")),
        "liens": {
            "tagliatelle": LI("ma colocataire,", "Tagliatelle", 0.95, "Tagliatelle peint de travers et joue du violon tout droit. On se dispute pour la salle de bains, on se réconcilie à la tarentelle. C'est ma sœur de cœur.", "Une nuit, elle m'a peinte en train de chanter. Sur le tableau, on voit le son qui sort de ma bouche. Il est jaune.", [["a", "Tu m'accompagnes ce soir ?"], ["b", "Si tu chantes en fa."], ["a", "Je ne connais que le fa !"]]),
            "farfalle": LI("notre Révérend,", "Révérend Père Farfalle", 0.85, "Le Révérend m'a donné ma place. Je chante pour lui, pour le Grand Spaghetti, pour tout le monde. Il ferme les yeux quand je monte dans les aigus. Je crois qu'il prie très fort.", "Il a voulu chanter un solo, une fois. Toute l'île s'est mise à applaudir avant la fin. Il a cru que c'était un triomphe. On l'a laissé croire.", [["a", "Révérend, on répète demain ?"], ["b", "Si le Grand Spaghetti le veut."], ["a", "Il veut. Je lui ai demandé."]]),
        }},
    "linguini": {"genre": "m", "prenom": "Frère Linguini",
        "histoire": [
            H("les métiers ratés", "J'ai essayé boulanger : j'ai brûlé le four. Facteur : j'ai mangé une lettre (elle sentait le gâteau). Gardien de phare : je me suis endormi et le phare s'est éteint. On m'a dit : « Linguini, tu n'es fait pour rien. » Alors je suis parti chercher l'endroit où l'on est fait pour rien."),
            H("la première assiette", "En arrivant, je n'avais rien. Mamma Lasagna m'a vu sur le ponton et m'a mis une assiette de spaghettis dans les mains. Sans rien demander. J'ai pleuré dans mes pâtes. Elle a dit : « Ça sale. » Je suis resté."),
            H("la passoire trop grande", "Le jour où je suis devenu novice, le Révérend m'a donné ma passoire. Elle était trop grande. Elle m'est tombée sur les yeux pendant la cérémonie. Tout le monde a ri, moi aussi. Le Révérend a dit : « Tu grandiras dedans. » Ça fait un an. J'ai grandi d'un centimètre. Elle, non."),
            H("le troisième coup", "La première fois que j'ai frappé le Couvercle Sacré trois fois, c'était pour voir. La deuxième fois, c'était par accident. La troisième fois… c'était pour Gnocchi, il voulait voir le volcan cracher. On a été nettoyés à la louche par Mamma Lasagna. Ça valait le coup."),
            H('le balai', "Mon balai, je l'ai fait moi-même, avec des spaghettis secs. Il ne balaie pas très bien. Il casse un peu. Après, il faut balayer les morceaux du balai. Ça m'occupe toute la matinée, et le Révérend dit que je suis très appliqué."),
        ],
        "reve": ["Devenir un vrai prêtre, avec une passoire à ma taille. Et réussir, une fois, une seule fois, à porter l'assiette éternelle de l'autel jusqu'au parvis sans la faire tomber."],
        "question": Q("Dis, {surnom}… tu as déjà cassé quelque chose de très, très important ?",
            ("Oui, plein de fois.", "oui", "Ouf ! Je ne suis pas tout seul ! On devrait fonder un club. Le Club des Mains-qui-Glissent. Ramen !", "Alors, membre du club, tu as cassé quoi, cette semaine ?"),
            ("Non, jamais.", "non", "Jamais ? Wouah. Tu es comme… un saint. Un saint qui ne casse rien. Tu peux m'apprendre ?", "Toujours rien cassé, toi ? Je t'admire, tu sais."),
            ("Une fois, et je l'ai réparé.", "repare", "Tu l'as réparé ! Voilà, c'est ça, le secret : on casse, on répare, on recommence. Je vais essayer la partie « réparer ».", "Tu as réparé d'autres choses, depuis ?")),
        "liens": {
            "ravioli": LI("ma grande sœur,", "Signorina Ravioli", 0.95, "Ravioli fait pousser des tomates en leur chantant des berceuses. Moi, je fais tomber des assiettes en marchant. On n'a pas les mêmes talents, mais on a les mêmes taches de rousseur.", "Quand on était petits, elle me cachait des tomates-cerises dans les poches pour que j'aie toujours un goûter. Elle le fait encore.", [["a", "Ravioli, je peux t'aider à arroser ?"], ["b", "Oui, mais tu poses l'arrosoir doucement."], ["a", "Doucement… d'accord… oups."]]),
            "gnocchi": LI("mon petit complice,", "Gnocchi", 0.85, "Gnocchi veut devenir novice comme moi. Il a déjà une passoire plus grande que la mienne. Je crois qu'il va être meilleur que moi. Ce n'est pas difficile.", "On a construit ensemble un château de sable en forme de temple. La mer l'a mangé. Gnocchi a dit que c'était une offrande. Il a raison.", [["b", "Linguini ! On frappe le Couvercle ?"], ["a", "Une fois, Gnocchi. Juste une."], ["b", "Ou trois ?"], ["a", "UNE."]]),
            "macaroni": LI("le gardien,", "Macaroni", 0.5, "Macaroni me surveille. Toujours. Même quand je dors, je crois. Je l'aime bien, mais je marche sur la pointe des pieds quand je passe devant le Couvercle.", "Un jour, j'ai fait tomber mon balai contre le Couvercle. Ça a fait « bong ». Un tout petit bong. Macaroni a compté « un » à voix haute en me fixant.", [["b", "Linguini. Le balai."], ["a", "Il est loin du Couvercle !"], ["b", "Je compte."]]),
        }},
    "macaroni": {"genre": "m", "prenom": "Macaroni",
        "histoire": [
            H("la barrière", "Pendant vingt ans, j'ai gardé une barrière de chemin de fer. Deux trains par jour. Je levais, je baissais. Je ne me suis jamais trompé. Le jour où on a supprimé la ligne, je suis resté une semaine à côté de la barrière, au cas où. Puis j'ai pris le bateau."),
            H("le premier coup de trop", "À mon arrivée, le Couvercle n'avait pas de gardien. Un dimanche, quelqu'un l'a frappé trois fois, pour s'amuser. La Marmite a craché tout l'après-midi. Le Borgo était rouge du sol aux toits. Le lendemain, j'ai demandé au Révérend : « Il vous faut un gardien. » Il a dit : « Il nous faut un gardien. » On a été d'accord tout de suite."),
            H("le tambourin", "Le soir, quand la tarentelle commence, je pose mon regard de gardien et je prends mon tambourin. Personne ne savait que je jouais. La première fois, Tagliatelle a laissé tomber son archet. Maintenant, c'est moi qui donne le rythme. Une, deux, trois… Là, trois, c'est permis."),
            H('le képi', "Mon képi, je l'ai gardé de la barrière. Ici, personne n'en porte. Le premier jour, Gnocchi m'a demandé si j'étais un général. J'ai dit : « Non, je suis gardien. » Il a dit : « C'est mieux. » Depuis, il me salue tous les matins. Je lui rends son salut. On est très sérieux."),
            H('la nuit du Couvercle', "Une nuit, j'ai entendu un pas près du Couvercle. J'ai crié : « Halte ! » C'était Bucatini, qui venait goûter la sauce au clair de lune. On s'est assis. On a goûté ensemble. Il manquait un peu de sel. Je ne l'ai dit à personne. Sauf à toi."),
        ],
        "reve": ["Passer une année entière sans une seule éruption de travers. Et peut-être, un jour, frapper le Couvercle moi-même, une seule fois, pour un grand jour. Le plus beau coup de gong de l'histoire."],
        "question": Q("Question de gardien : tu sais compter jusqu'à deux ?",
            ("Un, deux.", "deux", "Parfait. Et après deux ? … Rien. Après deux, on s'arrête. Tu as tout compris.", "Un, deux, et on s'arrête. Tu t'en souviens ?"),
            ("Un, deux, trois !", "trois", "STOP ! … (Il se calme.) Pardon. Le trois, ici, on ne le dit pas trop fort. Le volcan écoute.", "Tu ne dis plus « trois » à voix haute, j'espère ?"),
            ("Ça dépend de quoi.", "depend", "De quoi ? Du Couvercle, toujours du Couvercle. Pour le reste, compte comme tu veux. Les spaghettis, tu peux en compter cent.", "Tu comptes quoi, aujourd'hui ? Pas des coups de Couvercle, j'espère.")),
        "liens": {
            "bucatini": LI("mon cousin,", "Bucatini", 0.8, "Bucatini garde la Marmite, en haut ; moi, le Couvercle, en bas. Il croit que son travail est plus important. Il a tort. Mais je l'aime quand même. Le dimanche, on en discute. Il a encore tort.", "Un jour, il est descendu avec un pot de sauce pour me la faire goûter. « Il manque un peu de sel », j'ai dit. Il n'est pas redescendu pendant un mois.", [["a", "Cousin. La sauce ?"], ["b", "Elle mijote. Le Couvercle ?"], ["a", "Il est gardé."], ["b", "Bien."]]),
            "linguini": LI("le novice,", "Frère Linguini", 0.55, "Linguini a un balai, des mains qui glissent et une passoire qui lui tombe sur les yeux. C'est le danger numéro un du parvis. Mais il dit bonjour à tout le monde, même aux mouettes. C'est un bon garçon.", "Il m'a apporté une focaccia pour s'excuser du dernier coup de trop. Elle était à moitié mangée. Il a dit qu'il avait goûté pour vérifier.", [["a", "Linguini. Recule d'un pas."], ["b", "Je suis à trois mètres !"], ["a", "Quatre, c'est mieux."]]),
        }},
    "lasagna": {"genre": "f", "prenom": "Mamma Lasagna",
        "histoire": [
            H("la cuisine de la nonna", "Ma nonna avait une cuisine grande comme un mouchoir et une table grande comme un bateau. Tous les dimanches, il y avait vingt personnes. Elle faisait les pâtes à la main, sur la table, et moi je tirais la pâte de l'autre côté. Quand j'ai eu dix ans, elle m'a dit : « Maintenant, c'est toi qui tires. »"),
            H("le concours", "J'ai rencontré Tortellini à un concours de pâtes. Il avait fait des tortellinis en forme de nombril. C'était raté, mais c'était tendre. J'ai gagné, il a fini dernier. Il est venu me demander ma recette. Je lui ai dit : « Épouse-moi, et tu la mangeras tous les jours. » Il a dit oui avant que je finisse la phrase."),
            H("la Grande Tablée", "Quand on est arrivés sur l'île, chacun mangeait chez soi. J'ai sorti ma grande table, je l'ai mise au milieu du Borgo, et j'ai crié : « À table ! » Personne n'est venu. Le lendemain, j'ai recommencé, avec une focaccia. Trois personnes sont venues. Le troisième jour, tout le monde. Depuis, on ne s'est plus jamais arrêtés."),
            H("le four", "Le four à pain, c'est Tortellini qui l'a construit, pierre par pierre. Il s'est trompé dans la coupole : elle penche un peu. Le pain y cuit mieux qu'ailleurs. Je ne lui ai jamais dit. Il croit que c'est grâce à mes mains. C'est un peu grâce à son erreur."),
            H("le secret de Mamma", "Mon secret, {surnom} ? Je fais toujours une assiette de trop. Toujours. Parce qu'il y a toujours quelqu'un qui arrive en retard, quelqu'un qui n'a pas osé venir, quelqu'un qui a eu une mauvaise journée. Cette assiette-là, c'est la plus importante. Aujourd'hui, c'était peut-être la tienne."),
        ],
        "reve": ["Avoir assez de place à la Grande Tablée pour tout le monde. Même les gens de Néopolis, avec leurs nouilles en machine. Je leur montrerai ce que c'est, une vraie pâte."],
        "question": Q("Une question très sérieuse, {surnom} : tu es plutôt sauce tomate ou sauce au beurre ?",
            ("Sauce tomate, évidemment !", "tomate", "Évidemment ! Ici, on a un volcan entier de sauce tomate, ce serait malpoli de prendre autre chose.", "Une petite assiette à la sauce tomate ? Je savais."),
            ("Sauce au beurre, toute simple.", "beurre", "Au beurre ? Hm. Simple, doux, comme un câlin. Je t'en ferai une en cachette. Ne le dis pas au volcan.", "J'ai mis un peu de beurre de côté pour toi. Chut."),
            ("Les deux à la fois !", "deux", "Les deux ? (Elle réfléchit longtemps.) … Tu sais quoi ? Ce n'est pas bête. Je vais essayer. Si c'est bon, je l'appelle « la sauce du voyageur ».", "La sauce du voyageur est prête, {surnom} ! Moitié tomate, moitié beurre. Tout le monde adore.")),
        "liens": {
            "tortellini": LI("mon mari,", "Nonno Tortellini", 0.95, "Tortellini fait pousser le blé, je fais les pâtes. Il dit que c'est son blé qui fait mes pâtes bonnes ; je dis que ce sont mes mains. On a raison tous les deux. Ça fait cinquante ans qu'on a raison tous les deux.", "Pour nos noces d'or, il m'a offert un épi de blé doré. Un vrai, peint en or par Tagliatelle. Je l'ai mis au-dessus du four. Le pain est meilleur depuis.", [["a", "Tortellini ! À table !"], ["b", "J'arrive, ma pâte d'amour."], ["a", "Tu traînes depuis cinquante ans."]]),
            "gnocchi": LI("mon petit-fils,", "Gnocchi", 1.0, "Gnocchi est tout rond, tout doux, et toujours affamé. Un vrai gnocchi. Il veut être pirate, novice, volcan. Moi, je veux juste qu'il finisse son assiette.", "Il a caché une boulette dans sa poche pour la donner au Grand Spaghetti. Elle y est restée une semaine. On l'a trouvée à l'odeur.", [["a", "Gnocchi, ton assiette !"], ["b", "Elle est finie, Nonna !"], ["a", "Et sous la table ?"], ["b", "… Elle est presque finie."]]),
            "farfalle": LI("le Révérend,", "Révérend Père Farfalle", 0.75, "Le Révérend prie très bien et mange très mal. Il oublie l'heure, il oublie de manger, il oublie qu'il a oublié. Alors je lui garde une assiette. Toujours la même : la plus grande.", "Il m'a bénie une fois avec la louche. Elle était pleine de sauce. J'ai été bénie jusqu'aux genoux.", [["a", "Révérend ! Vous avez mangé ?"], ["b", "Je… je crois ?"], ["a", "Asseyez-vous."]]),
        }},
    "tortellini": {"genre": "m", "prenom": "Nonno Tortellini",
        "histoire": [
            H("1987", "C'était en 1987. Il faisait une chaleur de four. Je moissonnais seul. J'ai levé la tête pour m'essuyer le front, et il était là, au-dessus du champ, tout petit encore, gros comme une assiette. Il m'a regardé. Et il m'a fait un clin d'œil. Avec l'œil gauche. Puis il est parti derrière le volcan. Le lendemain, il était au-dessus du temple, grand comme une maison."),
            H("le blé sauvage", "Quand on est arrivés, le blé poussait tout seul, sauvage, entre les cailloux. Je l'ai goûté. Il avait le goût du soleil et de la cendre. J'ai dit à Lasagna : « Avec ça, tu vas faire les meilleures pâtes du monde. » Elle a dit : « Je le fais déjà. » Mais elle a goûté. Elle a souri."),
            H("le four penché", "J'ai construit le four à pain du Borgo. Je me suis trompé dans la coupole : elle penche d'un côté. J'ai voulu la refaire. Lasagna a dit : « Non, laisse. » Je ne sais pas pourquoi. Le pain y est très bon. C'est sûrement grâce à ses mains."),
            H("la méduse", "Rigatoni raconte qu'il a vu le Grand Spaghetti en pleine mer, avant tout le monde. Moi, je dis que c'était une méduse. Ça fait quarante ans qu'on se dispute. En vrai, je le crois. Mais si je le dis, il va devenir insupportable."),
            H('la paille', "Ma paille, je la mâchouille depuis soixante ans. Pas toujours la même, hein. Ravioli dit que ça me donne l'air d'un épouvantail. Je lui réponds que les épouvantails, c'est les seuls qui ne se fatiguent jamais dans un champ."),
        ],
        "reve": ["Revoir le clin d'œil, une deuxième fois, pour que tout le monde me croie. Ou alors, que le Grand Spaghetti le fasse à Rigatoni, devant moi. Comme ça, on serait deux."],
        "question": Q("Dis-moi, petit : tu crois à mon clin d'œil de 1987 ?",
            ("Oui, je vous crois !", "crois", "Ah ! Enfin ! Quelqu'un ! Viens, je te raconte encore une fois, avec tous les détails. Il faisait chaud…", "Toi qui me crois… tu veux que je te la raconte encore ?"),
            ("Ce n'était pas plutôt un rayon de soleil ?", "soleil", "Un rayon de soleil ! (Il rit.) Lasagna dit pareil. Mais un rayon de soleil, ça ne cligne pas. Hé hé.", "Toujours ton rayon de soleil, petit ? Je t'aurai, un jour."),
            ("C'était peut-être une méduse.", "meduse", "Une méduse ?! Tu parles comme Rigatoni ! … Attends. C'est moi qui dis « méduse », d'habitude. Bon. On est quittes.", "Méduse, méduse… Tu traînes trop avec le Capitaine, toi.")),
        "liens": {
            "lasagna": LI("ma femme,", "Mamma Lasagna", 0.95, "Lasagna, c'est la meilleure cuisinière de l'archipel et la plus grande râleuse. Les deux vont ensemble. Elle crie « à table ! » si fort que les mouettes s'assoient.", "Pour nos noces d'or, elle m'a fait cinquante tortellinis, chacun avec un souvenir écrit dedans, sur un tout petit papier. J'en ai mangé un avec le papier. Elle n'a rien dit.", [["b", "Tortellini ! À table !"], ["a", "J'arrive, ma pâte d'amour."], ["b", "Tu traînes depuis cinquante ans."]]),
            "rigatoni": LI("mon vieux rival,", "Capitaine Rigatoni", 0.75, "Rigatoni et moi, on se dispute depuis quarante ans pour savoir qui a vu le Grand Spaghetti en premier. Le dimanche, on fait une partie de cartes. Celui qui perd dit « c'était une méduse ».", "Une fois, il a triché aux cartes avec l'aide de Pesto. Le perroquet criait « Ramen ! » à chaque fois que j'avais un as.", [["a", "Capitaine. La méduse va bien ?"], ["b", "Arrr. Et ton clin d'œil, vieux blé ?"], ["a", "Il cligne toujours."]]),
        }},
    "gnocchi": {"genre": "m", "prenom": "Gnocchi",
        "histoire": [
            H("la passoire de grand-père", "Ma passoire, c'est celle de Nonno quand il était petit. Elle est trop grande. Quand je cours, elle fait « tong, tong » sur ma tête. Nonno dit que c'est comme ça qu'on devient sage : petit à petit, à coups de passoire."),
            H("le château-temple", "Avec Frère Linguini, on a construit un château de sable en forme de temple, avec des trous partout, comme la vraie passoire. La mer l'a mangé. J'étais triste. Linguini a dit : « C'est une offrande pour le Grand Spaghetti. » Maintenant, j'en fais un tous les jours."),
            H("Pesto", "Pesto, le perroquet du Capitaine, m'a appris un mot. C'est « Ramen ». Il ne connaît que celui-là. Moi, je lui ai appris « Gnocchi ». Il ne veut pas le dire. Mais un jour, je l'ai entendu dire « Gnocc… RAMEN ! ». C'est presque."),
            H("le coucou", "Tous les matins, je fais coucou au Grand Spaghetti. Avant, il remuait une nouille pour me répondre. Une seule, toute petite. C'est notre secret. Personne ne le sait. Sauf toi, maintenant."),
            H('le gros mot', "Un jour, j'ai dit un gros mot. C'était « couteau ». Le Révérend est devenu tout blanc. Mamma m'a envoyé au coin, à côté du four. Il faisait chaud et ça sentait le pain. Je recommencerai peut-être."),
        ],
        "reve": ["Monter sur le Grand Spaghetti Volant et faire le tour de l'archipel accroché à une nouille. Et lancer des boulettes aux mouettes. Et revenir pour le goûter."],
        "question": Q("Dis, tu préfères être un pirate ou un volcan ?",
            ("Un pirate !", "pirate", "Moi aussi ! À l'abordage ! On va attaquer… la Grande Tablée ! Pour le dessert !", "Pirate un jour, pirate toujours ! Arrr !"),
            ("Un volcan !", "volcan", "Un volcan ! BOUM ! SPLOTCH ! Tu craches de la sauce sur tout le monde ! Trop bien ! Mais Nonna va crier.", "BOUM ! T'es toujours un volcan, toi ?"),
            ("Un pirate-volcan.", "les_deux", "Un pirate-volcan… (Ses yeux brillent.) C'est la meilleure idée du monde. Je vais être ça. Je commence demain.", "Pirate-volcan ! Je m'entraîne, regarde : Arrr-BOUM !")),
        "liens": {
            "rigatoni": LI("mon capitaine,", "Capitaine Rigatoni", 1.0, "Le Capitaine, c'est le plus grand pirate du monde. Il a un perroquet, un cache-œil et une maison-bateau. Plus tard, je serai son second. Il a dit peut-être. Peut-être, c'est presque oui.", "Il m'a appris à faire un nœud de marin. J'ai attaché le chat de Nonna à la treille. Pas fort. Le chat a dit « miaou ». Le Capitaine a dit « bravo, mais détache-le ».", [["a", "Capitaine ! Une histoire !"], ["b", "Arrr. La baleine ou la tempête ?"], ["a", "Les deux !"]]),
            "lasagna": LI("ma nonna,", "Mamma Lasagna", 1.0, "Nonna, elle fait les meilleures pâtes du monde, et elle a toujours une focaccia cachée dans son tablier. Toujours. Je ne sais pas comment elle fait.", "Une fois, j'ai essayé de faire des pâtes tout seul. J'ai mis de la farine partout, même sur le chat. Nonna a ri si fort qu'elle a dû s'asseoir.", [["b", "Gnocchi, ton assiette !"], ["a", "Elle est finie, Nonna !"], ["b", "Et sous la table ?"]]),
        }},
    "ravioli": {"genre": "f", "prenom": "Signorina Ravioli",
        "histoire": [
            H("la graine dans les roses", "À Port-Azur, je vendais des roses. Un matin, dans un de mes pots, une graine de tomate avait poussé. Elle a grandi plus haut que les roses, en trois semaines, et elle a donné des tomates grosses comme des poings. J'ai fermé la boutique. Je suis partie chercher le pays des tomates."),
            H("la berceuse", "Ici, la première année, mes tomates ne poussaient pas. Une nuit, je me suis assise au milieu du jardin, et j'ai chanté la berceuse de ma mère. Le lendemain, elles avaient grandi d'une main. Depuis, je chante tous les matins. Le Révérend dit que c'est un miracle. Bucatini dit que c'est la cendre. Moi, je dis que c'est la berceuse."),
            H("Linguini", "Mon petit frère est arrivé sur l'île un an après moi, sans rien, avec juste un sac et un sourire. Il casse tout, mais quand il touche une plante, elle pousse. Je l'ai vu ressusciter un basilic tout sec rien qu'en le regardant. Je ne lui ai pas dit. Il le casserait."),
            H("les noms", "Chacune de mes tomates a un nom. Bolognaise, Napolitaine, Arrabbiata, Petite-Sauce, Madame-Ketchup… Quand on les cueille, je leur dis au revoir. Ça a l'air bête. Mais elles sont meilleures quand on leur a dit au revoir."),
            H('la capeline', "Ma capeline, je l'ai tressée avec la paille de Nonno Tortellini. Il ne le sait pas. Il croit que des oiseaux lui volent sa paille. Il a même construit un épouvantail. L'épouvantail porte un chapeau. Je l'ai tressé aussi."),
        ],
        "reve": ["Faire pousser la plus grosse tomate du monde, grosse comme une boulette du parvis, et l'offrir au Grand Spaghetti pour son anniversaire. Personne ne sait quand c'est. Moi, j'ai choisi le premier jour du printemps."],
        "question": Q("Dis-moi, {surnom} : tu crois que les plantes nous entendent ?",
            ("Oui, j'en suis sûr.", "oui", "Ah ! Je le savais ! Alors parle-leur gentiment. Elles retiennent tout, surtout les compliments.", "Tu as parlé à une plante, aujourd'hui ? Elles adorent."),
            ("Non, ce sont des plantes.", "non", "Hm. Les tomates, là, viennent de rougir. De vexation, je crois. Tu devrais t'excuser.", "Tu t'es excusé auprès de mes tomates ? Elles boudent encore."),
            ("Peut-être, si on chante bien.", "chanter", "Exactement ! Le secret, c'est de chanter juste. Ne le dis pas à Sœur Penne, mais c'est pour ça qu'elle chante pour le Grand Spaghetti, et pas pour mes tomates.", "Tu as chanté pour une plante ? Juste, hein, pas comme Penne.")),
        "liens": {
            "linguini": LI("mon petit frère,", "Frère Linguini", 0.95, "Linguini est la personne la plus maladroite que je connaisse, et la plus gentille. Il a les mains qui glissent et le cœur qui tient bon.", "Pour mon anniversaire, il m'a offert un pot de fleurs. Il l'a cassé en me le donnant. La fleur, elle, n'a rien eu. Elle est toujours à ma fenêtre.", [["a", "Linguini, l'arrosoir. Doucement."], ["b", "Doucement… d'accord… oups."], ["a", "… Pas grave. Elles avaient soif."]]),
            "bucatini": LI("mon meilleur client,", "Bucatini", 0.7, "Bucatini prend mes tomates pour la Marmite. Il ne leur dit jamais au revoir. Je le lui reproche. Il dit que la sauce, c'est un au revoir qui dure longtemps. C'est assez joli, pour un homme qui ne parle presque pas.", "Un jour, il m'a rapporté un pot de sauce avec un ruban. « Ce sont tes tomates », il a dit. C'est la seule fois que je l'ai vu sourire.", [["b", "Un panier de tomates. Pour la Marmite."], ["a", "Tu leur dis au revoir ?"], ["b", "… Au revoir."]]),
        }},
    "fusilli": {"genre": "f", "prenom": "Professeure Fusilli",
        "histoire": [
            H("l'université", "J'étais professeure dans une grande université, très sérieuse. Je mesurais des choses. N'importe quoi : les étoiles, les nuages, la longueur des discours du doyen. Un jour, un collègue m'a parlé d'une île où un spaghetti géant flottait dans le ciel. J'ai ri. Puis j'ai acheté un billet. Pour mesurer."),
            H("la première mesure", "En arrivant, j'ai sorti mon double mètre et je me suis mise au pied du temple. Le Grand Spaghetti m'a regardée. Je l'ai regardé. Il a cligné des yeux. J'ai noté : « Clignement, 14 h 32. » Il a cligné encore. Puis encore. Au bout d'une heure, j'avais rempli un carnet. Je ne suis jamais repartie."),
            H("pirates et climat", "Mon livre le plus célèbre montre que moins il y a de pirates sur les mers, plus il fait chaud. Les courbes sont parfaites. Le Capitaine Rigatoni dit que c'est parce que les pirates ouvrent les fenêtres. Je n'ai pas trouvé mieux comme explication. Je l'ai mise dans la deuxième édition."),
            H("l'observatoire", "Sur mon toit, il y a un petit observatoire en cuivre. La nuit, je ne regarde pas les étoiles : je regarde le Grand Spaghetti. Je veux savoir s'il dort. Il ne dort pas. Mais une nuit, je l'ai vu bâiller. J'ai pris la photo. Elle est floue. Évidemment."),
            H("l'unité de mesure", "J'ai inventé une unité de mesure : le spaghetti. Un spaghetti, c'est vingt-cinq centimètres. Le temple mesure quatre-vingt-dix spaghettis de large. Le Grand Spaghetti, lui, se mesure en lui-même, ce qui pose un problème que je n'ai pas encore résolu."),
        ],
        "reve": ["Comprendre, une bonne fois pour toutes, comment il tient en l'air. Puis, sans doute, ne le dire à personne. Certaines choses sont plus belles sans explication. Mais je veux savoir quand même."],
        "question": Q("Question scientifique, {surnom} : combien de nouilles compte, selon vous, le Grand Spaghetti ?",
            ("Cent douze, plus ou moins une.", "112", "Exactement ! Vous avez lu mes travaux ! Ou vous avez compté. Dans les deux cas, je suis impressionnée.", "Toujours cent douze ? J'en ai peut-être recompté une de plus ce matin."),
            ("Mille !", "mille", "Mille ? Hm. C'est beaucoup. Mais je ne peux pas l'exclure : il y a peut-être des nouilles cachées. Je vais recompter. Encore.", "J'ai recompté. Toujours pas mille. Mais je cherche encore."),
            ("Une seule, très, très longue.", "une", "Une seule… très longue… (Elle laisse tomber son crayon.) … Mon dieu. Ça expliquerait tout. Je dois tout recommencer.", "Une seule nouille… Je n'en dors plus, vous savez. Merci.")),
        "liens": {
            "farfalle": LI("le Révérend,", "Révérend Père Farfalle", 0.8, "Le Révérend croit, je mesure. Nous ne sommes jamais d'accord, et nous finissons toujours à la même table. Il dit que la foi n'a pas besoin de double mètre. Je dis que le double mètre n'a pas besoin de foi. Puis on mange.", "Il m'a demandé de mesurer sa passoire dorée. Quarante-deux centimètres. Il a dit : « C'est le nombre parfait. » Je n'ai pas osé le contredire.", [["b", "Professeure, combien aujourd'hui ?"], ["a", "Cent douze nouilles."], ["b", "Ramen."], ["a", "… Ramen, d'accord."]]),
            "rigatoni": LI("ma source,", "Capitaine Rigatoni", 0.7, "Le Capitaine est ma meilleure source sur les pirates. Il exagère tout, mais il exagère toujours dans le même sens. Pour une scientifique, c'est très pratique : il suffit de diviser par trois.", "Il m'a raconté qu'il avait combattu une baleine. J'ai divisé par trois : il a vu un gros poisson. C'est déjà pas mal.", [["a", "Capitaine, combien de pirates aujourd'hui ?"], ["b", "Arrr. Un. Moi."], ["a", "Alors il va faire chaud."]]),
        }},
    "tagliatelle": {"genre": "f", "prenom": "Tagliatelle",
        "histoire": [
            H("le violon du grenier", "Le violon, je l'ai trouvé dans un grenier, sans étui et sans une corde. J'ai joué trois ans sur trois cordes. Quand on m'a offert la quatrième, j'ai pleuré, puis je ne savais plus quoi en faire. Elle sert pour les grands soirs. Les autres soirs, je fais semblant qu'elle n'est pas là."),
            H("les couleurs de travers", "Mon professeur de dessin disait que je peignais de travers. Le ciel en vert, la mer en orange. Il a écrit à mes parents. Ici, personne ne dit rien : le volcan est rouge, la cascade est rouge, la mer est rouge par endroits. À côté, mes couleurs sont presque raisonnables."),
            H("la bannière", "La grande bannière du parvis, vert, blanc, rouge, avec la fourchette dorée, c'est moi. Chaque printemps, je la repeins, et je cache un petit dessin quelque part. Cette année, des pirates minuscules dans les coins. L'an dernier, Gnocchi en train de manger. Personne ne cherche. C'est très reposant."),
            H("la tarentelle", "Le soir, je prends le violon. Macaroni sort son tambourin, Sœur Penne se met à chanter, et le Borgo se met à danser. On commence doucement. On accélère. À la fin, je ne sens plus mes doigts, et Nonno Tortellini danse avec une chaise."),
            H('le portrait du Spaghetti', "J'ai voulu peindre le Grand Spaghetti. Il bougeait tout le temps. J'ai fini par peindre une assiette de spaghettis posée sur le chevalet, et j'ai dit à tout le monde que c'était lui, de loin. Le Révérend l'a accrochée dans le temple. Il ne sait pas."),
        ],
        "reve": ["Peindre le Grand Spaghetti exactement comme il est, une seule fois. Pas plus beau, pas plus laid. Juste lui. Je crois que c'est impossible. C'est pour ça que j'essaie."],
        "question": Q("Dis-moi, {surnom} : de quelle couleur est le volcan ?",
            ("Rouge, bien sûr.", "rouge", "Rouge… Oui. C'est ce qu'il veut qu'on voie. Mais regarde bien, le soir : il y a du violet, de l'orange, et même un peu de vert.", "Tu as regardé le volcan, hier soir ? Tu as vu le vert ?"),
            ("Bleu, comme sur ton tableau.", "bleu", "Ha ! Tu as vu mon tableau ! Personne n'a jamais dit qu'il était bleu. Merci. Tu as l'œil d'un artiste.", "Bleu, toujours ? Tu es le seul à me croire."),
            ("De la couleur de la sauce.", "sauce", "De la couleur de la sauce… C'est la meilleure réponse. Il n'y a pas de nom pour cette couleur-là. Il faudrait en inventer un.", "J'ai inventé un nom pour la couleur du volcan : « bolognaise ». Qu'en dis-tu ?")),
        "liens": {
            "penne": LI("ma colocataire,", "Sœur Penne", 0.95, "Penne chante faux et elle le sait, et elle chante quand même, très fort. C'est la personne la plus courageuse que je connaisse.", "Le jour de mon anniversaire, elle m'a chanté une chanson qu'elle avait écrite. Elle parlait d'une tagliatelle qui voulait voler. J'ai pleuré. Les voisins aussi, mais pas pour les mêmes raisons.", [["b", "Tu m'accompagnes ce soir ?"], ["a", "Si tu chantes en fa."], ["b", "Je ne connais que le fa !"]]),
            "macaroni": LI("mon percussionniste,", "Macaroni", 0.8, "Macaroni est le gardien le plus sévère de l'île et le meilleur tambourin de l'archipel. Le jour, il compte jusqu'à deux. Le soir, il compte jusqu'à l'infini.", "Le soir où il a joué pour la première fois, j'ai laissé tomber mon archet. Il a continué tout seul pendant dix minutes, sans sourire, parfaitement en rythme. Puis il a dit : « On reprend ? »", [["a", "Macaroni, on commence doucement ?"], ["b", "Doucement. Puis vite."], ["a", "Puis très vite !"]]),
        }},
    "bucatini": {"genre": "m", "prenom": "Bucatini",
        "histoire": [
            H("la première louche", "La première fois que je suis monté là-haut, c'était pour goûter. Juste goûter. J'ai pris une louche, j'ai soufflé, j'ai goûté. Et j'ai su. Il manquait un peu de sel. Il en manque toujours un peu. C'est pour ça que je reste : un jour, peut-être, elle sera parfaite."),
            H("la sauce qui colle", "Un été, la sauce a commencé à coller au fond de la Marmite. Le volcan grondait, crachait, s'énervait. Je suis descendu au bord avec la grande louche, et j'ai remué. Trois jours et trois nuits. Il s'est calmé. Depuis, je remue tous les jours. Un volcan, ça se remue comme une sauce : doucement, et souvent."),
            H("le panier de tomates", "Tous les dimanches, Ravioli me donne un panier de tomates pour la Marmite. Je les jette dedans, une par une. Elle me demande de leur dire au revoir. Je ne dis rien. Mais je le pense très fort. Je crois qu'elle le sait."),
            H('le carnet de sel', "J'ai un carnet. Chaque jour, j'écris combien de sel il manque à la Marmite. « Une pincée. » « Une petite pincée. » « Une toute petite pincée. » Ça fait des années. Un jour, j'écrirai : « Rien. » Ce jour-là, je descendrai à la plage, et je ferai la sieste."),
            H('le belvédère', "Là-haut, au bord, on voit toute l'île. Le temple, le Borgo, la barque du Capitaine, les champs de Nonno. Les gens sont tout petits. Ils font de grands gestes. Je les entends rire jusqu'ici, quand le vent est bon. C'est la plus belle soupe du monde, une île qui rit."),
        ],
        "reve": ["Goûter, un jour, la sauce, et ne rien trouver à redire. Rien du tout. Puis redescendre, m'asseoir à la Grande Tablée, et manger des pâtes avec. Pour une fois, en bas."],
        "question": Q("Question de gardien de Marmite : tu salerais la sauce, toi ?",
            ("Oui, un peu.", "un_peu", "Un peu. Voilà. Un peu. Tout le monde dit beaucoup, ou pas du tout. Un peu, c'est le plus difficile.", "Un peu de sel. Toujours un peu. Tu as raison."),
            ("Non, elle est parfaite.", "parfaite", "Parfaite ? (Il goûte.) … Non. Il manque un peu de sel. Mais merci. Personne ne m'avait jamais dit ça.", "Tu la trouves toujours parfaite ? … Merci."),
            ("Je goûterais d'abord.", "gouter", "Recommandation numéro quatre : goûter avant de saler. Tu as tout compris. Tu pourrais garder la Marmite, un jour.", "Tu goûtes toujours avant de saler ? Bien.")),
        "liens": {
            "macaroni": LI("mon cousin,", "Macaroni", 0.8, "Macaroni garde le Couvercle. Il croit que c'est le plus important. Ce n'est pas vrai. Mais sans lui, je recevrais la sauce sur la tête tous les jours. Alors je le remercie. Dans ma tête.", "Il m'a offert un tambourin pour mon anniversaire. Je ne sais pas en jouer. Je l'utilise pour poser la louche.", [["b", "Cousin. La sauce ?"], ["a", "Elle mijote. Le Couvercle ?"], ["b", "Il est gardé."], ["a", "Bien."]]),
            "ravioli": LI("la jardinière,", "Signorina Ravioli", 0.75, "Ravioli fait pousser les tomates de la sauce sacrée. Elle chante pour elles. Je les jette dans le volcan. On fait le même métier, en deux morceaux.", "Une fois, je lui ai rapporté un pot de sauce avec un ruban. Elle a pleuré. Je ne savais pas quoi faire. J'ai dit : « Il manque un peu de sel. » Elle a ri.", [["a", "Un panier. Pour la Marmite."], ["b", "Tu leur dis au revoir ?"], ["a", "… Au revoir."]]),
        }},
    "rigatoni": {"genre": "m", "prenom": "Capitaine Rigatoni",
        "histoire": [
            H("le mousse", "J'ai embarqué à douze ans comme mousse sur un bateau de pêche. Le capitaine m'a dit : « Tu veux être pirate ? Alors apprends d'abord à éplucher les patates. » J'ai épluché des patates pendant cinq ans. Puis j'ai eu mon propre bateau. Je l'ai appelé la Patate Hardie."),
            H("la vision", "Il y a cinquante ans, au coucher du soleil, en pleine mer, j'ai vu une forme dorée au-dessus des vagues. Une pelote de nouilles, avec deux yeux. Elle m'a regardé, puis elle a tendu une nouille vers l'horizon. J'ai mis le cap dessus. Trois jours plus tard, j'ai vu le volcan qui fumait la tomate. Tortellini dit que c'était une méduse. Arrr."),
            H("la Râpe d'Or", "La Râpe d'Or, je l'ai gagnée à un vieux pirate, aux cartes, sur une île sans nom. Il disait qu'elle râpait le meilleur parmesan du monde. C'était vrai. Je l'ai enterrée près de ma barque, pour la protéger. Et puis j'ai oublié où. Enfin… j'ai fait semblant d'oublier. C'était plus simple que de la prêter."),
            H("la barque à l'envers", "Ma barque, la Patate Hardie, je l'ai retournée sur le sable le jour où j'ai pris ma retraite. Elle me protège de la pluie comme elle me protégeait des vagues. Le soir, j'entends la mer taper doucement dessus. Je m'endors comme quand j'étais mousse."),
            H('Pesto', "Pesto, je l'ai trouvé dans une caisse de basilic, sur un quai lointain. Il était tout vert, tout petit, il sentait l'ail. Je l'ai appelé Pesto. Il m'a mordu le doigt. On est amis depuis trente ans. Il me mord encore le doigt. C'est notre façon de se dire bonjour."),
        ],
        "reve": ["Repartir une dernière fois en mer, avec Gnocchi comme second et Pesto à la vigie, faire le tour de l'archipel, et revenir pour la Grande Tablée. Juste une fois. Un pirate ne prend jamais vraiment sa retraite."],
        "question": Q("Arrr, moussaillon : la mer, tu l'aimes calme ou déchaînée ?",
            ("Calme, comme un miroir.", "calme", "Calme ! Sage moussaillon. Une mer calme, c'est une mer qui réfléchit. Et toi aussi, tu réfléchis.", "La mer est calme, aujourd'hui. Elle pense à toi."),
            ("Déchaînée, avec des vagues énormes !", "dechainee", "Arrr ! Une âme de pirate ! Les grosses vagues, c'est là qu'on apprend à tenir debout. Et à tenir son déjeuner.", "Pas de tempête aujourd'hui, moussaillon. Désolé pour toi."),
            ("Rouge, comme près de la cascade.", "rouge", "Rouge ! Ha ! Près de la cascade, la mer sent la bolognaise. Les poissons de par ici ont tous un petit goût d'ail. Pesto les adore.", "Tu es retourné voir la mer rouge ? Elle sent bon, hein ?")),
        "liens": {
            "gnocchi": LI("mon futur second,", "Gnocchi", 0.95, "Gnocchi veut être pirate. Il a déjà le cri, la démarche et la passoire. Il lui manque juste un bateau et dix ans. Je lui garde la place de second.", "Il a essayé de monter sur le mât avec ma longue-vue entre les dents. Il est arrivé à mi-hauteur, il a vu la Grande Tablée, et il est redescendu pour le goûter. Un vrai pirate.", [["b", "Capitaine ! Une histoire !"], ["a", "Arrr. La baleine ou la tempête ?"], ["b", "Les deux !"]]),
            "tortellini": LI("mon vieux rival,", "Nonno Tortellini", 0.75, "Tortellini dit que j'ai vu une méduse. Moi, je dis que son clin d'œil, c'était une poussière. On a raison tous les deux, et on se le dit tous les dimanches, aux cartes.", "Il m'a fait goûter son premier pain, il y a quarante ans. Il était dur comme une ancre. Je l'ai gardé. Il me sert de presse-papier.", [["b", "Capitaine. La méduse va bien ?"], ["a", "Arrr. Et ton clin d'œil, vieux blé ?"], ["b", "Il cligne toujours."]]),
            "farfalle": LI("le Révérend,", "Révérend Père Farfalle", 0.8, "Le Révérend m'appelle « le premier des fidèles ». C'est parce que je suis pirate. Je ne vais pas le contredire : il me donne toujours la meilleure place à la messe, celle près de la sortie.", "Il m'a demandé un jour si je regrettais la mer. J'ai dit non. Pesto a dit « RAMEN ». Le Révérend a dit : « Votre perroquet est plus honnête que vous. »", [["b", "Capitaine, vous viendrez à la messe ?"], ["a", "Arrr, si Pesto est d'accord."], ["b", "Pesto est toujours d'accord."]]),
        }},
}


def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(FICHES, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print("V98 :", OUT, len(FICHES), "fiches")


if __name__ == "__main__":
    main()
