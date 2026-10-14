extends RefCounted
## V33 : fiche de personnalité d'Octave Taillefer, le rival de Barnabé.
## Ancien charpentier-forgeron de « La Mouette Têtue », le navire où Barnabé était cartographe.
## Le naufrage ? D'après Octave, la carte de Barnabé était fausse ; d'après Barnabé, c'est
## Octave qui tenait la barre. Vingt-deux ans qu'ils ne se parlent plus, chacun d'un côté de
## l'île. Octave vit dans une cabane perchée dans un fromager, à l'est, avec Clou, son
## ouistiti voleur de pièces. Il forge et vend des outils et des armes, rachète le poisson.
## Bougon, radin, fier de son travail ; il respecte ceux qui travaillent et paient comptant.
## Même cerveau que Barnabé (pnj_brain_v31.gd) : conditions et variables décrites dans
## barnabe_v31.gd ; en plus pour la boutique : {objet} {prix} {pieces} {depense}.

const DATA := {
	"id": "octave",
	"nom": "Octave Taillefer",
	"titre": "forgeron de la cabane perchée",
	"teinte": [0.84, 0.66, 0.54],
	"humeur_base": -0.05,
	"energie_base": 0.75,
	"affinite_depart": 5.0,
	"traits": {"bavard": 0.5, "humour": 0.3, "curiosite": 0.4, "susceptible": 0.6, "rancunier": 0.8, "radin": 0.8},
	"surnoms": [[0, "client"], [20, "l'ami"], [45, "apprenti"], [70, "compagnon"], [90, "associé"]],
	"aime": {"piece": 1.5, "baton": 1.0, "caillou": 0.6, "vieille_botte": 2.5, "merou": 2.0, "poisson_lune": 4.0, "bar": 1.0, "dorade": 1.0},
	"deteste": {"coquillage": -1.2, "baies": -0.3},
	"refuse": ["pelle", "hache", "epee"],
	"quete": {"objet": "baton", "nombre": 6, "recompense": [["piece", 12]], "affinite": 15.0,
		"sujet": "À propos de tes bâtons…", "souvenir": "Et tu m'as rapporté de quoi faire six manches de pelle. Ça, je n'oublie pas."},
	"boutique": {
		"vend": {"pelle": 12, "hache": 28, "epee": 50},
		"achete": {"sardine": 1, "maquereau": 2, "dorade": 4, "bar": 5, "poisson_perroquet": 6, "merou": 12, "poisson_lune": 60,
			"coquillage": 3, "champignon": 1, "vieille_botte": 8},
	},
	"compagnon": "Clou",

	"prefixes": {
		"joie": ["Hé !", "Pas mal, pas mal.", "Bon !", "Ha."],
		"neutre": ["Hmm.", "Bon.", "Ouais.", "Voyons."],
		"triste": ["Pfff.", "Mouais.", "Hmmmf.", "Encore toi."],
		"colere": ["Grmbl.", "Quoi ?!", "Fiche le camp.", "Tss."],
	},
	"tics": ["Le fer, ça ne ment pas.", "Clou, lâche ça !", "Comptant, toujours comptant.", "Vingt-deux ans, et toujours pas d'excuses.",
		"Un bon outil, c'est un bon manche.", "Je dis ça, je dis rien."],
	"compagnon_lignes": ["Clou (en fouillant ta poche) : « Hiii hi hi ! »", "Clou te tire la manche et tend la main.",
		"Clou fait tinter une pièce qu'il vient de te prendre… et Octave la récupère.", "Clou : « Ouk ouk ! »",
		"Clou s'est caché derrière le comptoir. On voit juste sa queue."],
	"humeur_mots": [[0.6, "content (c'est rare)"], [0.25, "aimable"], [-0.25, "renfrogné"], [-0.6, "bougon"], [-2.0, "furieux"]],

	"repliques": {
		# ------------------------------------------------------------ accueil
		"accueil": [
			{"t": "Qui monte à mon échelle sans prévenir ? … Un client, peut-être. Octave Taillefer, forgeron. Ici on vend, on achète, on ne bavarde pas. Enfin, pas trop.", "si": {"visites_max": 1}, "geste": "salut"},
			{"t": "Encore toi, {surnom}. Tu as des pièces, j'espère.", "si": {"visites_min": 2, "humeur_max": 0.2}},
			{"t": "Ah, {surnom} ! Entre, entre. Enfin, monte. Tu es déjà monté. Bon.", "si": {"visites_min": 2, "humeur_min": 0.2}},
			{"t": "Ça fait {absence}. Je croyais que les crabes t'avaient eu. Ou pire : Barnabé.", "si": {"visites_min": 2, "absent_min": 900}},
			{"t": "Tu reviens après m'avoir frappé ? Les prix ont augmenté. Pour toi.", "si": {"fait": "frappe", "humeur_max": 0.0}, "geste": "colere"},
			{"t": "Mon épée te va bien. Évidemment : c'est moi qui l'ai forgée.", "si": {"tient": "epee"}, "geste": "rire"},
			{"t": "Ma hache ! Tu en prends soin ? Pas sur les cailloux, hein.", "si": {"tient": "hache"}},
			{"t": "Avec ta pelle sur l'épaule, tu as l'air d'un vrai chercheur de trésor. Tu as trouvé quelque chose ?", "si": {"tient": "pelle"}},
			{"t": "Cette canne… c'est moi qui l'ai taillée, il y a vingt-deux ans, sur le pont de la Mouette Têtue. Barnabé te l'a donnée ? Le voleur.", "si": {"tient": "canne_peche"}, "geste": "colere"},
			{"t": "Tu as une tête de déterré, {surnom}. Assieds-toi. Et mange quelque chose avant de tomber de mon échelle.", "si": {"vie_basse": true}},
			{"t": "Mon meilleur client ! Clou, sors le tabouret.", "si": {"achats_min": 40, "visites_min": 3}, "geste": "rire"},
			{"t": "Tu viens de chez Barnabé, toi. Ça se sent : tu sens le coquillage et le radotage.", "si": {"a_rencontre": "barnabe", "visites_min": 2}},
		],
		# ------------------------------------------------------------ comment ça va
		"humeur": [
			{"t": "Ça va. Le soufflet tire bien, le fer chauffe, personne ne me dérange. Enfin, presque personne.", "si": {"humeur_min": -0.1}},
			{"t": "Bien. Très bien, même. J'ai vendu une pelle ce matin. À toi, peut-être ?", "si": {"humeur_min": 0.3, "a_achete": "pelle"}, "geste": "rire"},
			{"t": "Mal. Clou a caché mon marteau. Et il ne dit pas où.", "si": {"humeur_max": 0.0}},
			{"t": "Comment ça va ? Ça va qu'il y a un rival de l'autre côté de l'île qui raconte des sornettes sur moi.", "si": {"humeur_max": 0.2, "a_rencontre": "barnabe"}},
			{"t": "Fatigué. J'ai battu le fer toute la nuit. Une épée, ça ne se fait pas en chantant.", "si": {"energie_max": 0.4}},
			{"t": "Ne me parle pas. Je suis de très mauvaise humeur. Achète ou va-t'en.", "si": {"humeur_max": -0.4}, "geste": "colere"},
			{"t": "Ça va mieux depuis que tu passes. Ne t'habitue pas, je reste un vieil ours.", "si": {"affinite_min": 50}},
		],
		# ------------------------------------------------------------ qui es-tu
		"lui": [
			{"t": "Moi ? Charpentier et forgeron de la Mouette Têtue, le plus beau trois-mâts du royaume. Jusqu'au rocher.", "si": {"sujet_min": ["lui", 0]}},
			{"t": "Pourquoi un arbre ? Pour voir venir les bateaux. Et pour ne pas voir la cabane de Barnabé.", "si": {"sujet_min": ["lui", 1]}},
			{"t": "Barnabé dessinait les cartes. Sa carte disait « mer libre ». La mer disait « rocher ». J'ai cru la carte. Vingt-deux ans que je le regrette.", "si": {"sujet_min": ["lui", 1]}},
			{"t": "Clou ? Il est arrivé un matin, il a volé ma dernière pièce, et il est resté. On s'entend bien : on aime tous les deux l'argent.", "si": {"sujet_min": ["lui", 1]}},
			{"t": "Tu veux te rendre utile, {surnom} ? Rapporte-moi {manque} bâtons bien droits. Il me faut des manches de pelle. Je paie, évidemment. Pas cher.", "si": {"quete": "", "sujet_min": ["lui", 2]}, "action": "quete_demande"},
			{"t": "Mes bâtons, tu y penses ? Il m'en faut {manque}. Sans manche, une pelle, c'est un caillou plat.", "si": {"quete": "demandee"}},
			{"t": "Grâce à tes bâtons, j'ai de quoi travailler tout l'hiver. Enfin, il n'y a pas d'hiver ici. Toute l'année, alors.", "si": {"quete": "finie"}},
			{"t": "Entre nous… ce n'était peut-être pas que la carte. J'avais peut-être un peu bu, à la barre. Ne le répète JAMAIS à Barnabé.", "si": {"affinite_min": 55, "sujet_min": ["lui", 3]}, "humeur": -0.1},
		],
		# ------------------------------------------------------------ l'île
		"ile": [
			{"t": "L'île ? Du bois partout, du bon. Ce fromager, là, sous tes pieds : il tient ma cabane depuis vingt ans sans broncher.", "si": {}},
			{"t": "Avec une pelle, on trouve de tout dans le sable de la plage : des coquillages, des pièces de naufragés… J'en vends, des pelles. Je dis ça.", "si": {}},
			{"t": "Les pitons de pierre, je les escaladais, avant. Maintenant j'ai une échelle, et des genoux qui grincent.", "si": {}},
			{"t": "Côté est, la mer est plus profonde. Les gros mérous y traînent. Ramène-m'en un, je te le paie bien.", "si": {}},
			{"t": "Il y a un trésor enterré quelque part sur cette île. Le coffre de paie de la Mouette Têtue. Il n'a jamais été retrouvé. Creuse, {surnom}. Creuse.", "si": {"affinite_min": 30}},
		],
		# ------------------------------------------------------------ rumeurs
		"rumeur": [
			{"t": "Des rumeurs ? Je n'en vends pas. Ça ne rapporte rien.", "si": {"affinite_max": 24}},
			{"t": "Il paraît que de l'autre côté de l'île vit un vieux fou qui parle aux coquillages. Barnabé, qu'il s'appelle. Ne crois rien de ce qu'il dit sur moi.", "si": {"pas_rencontre": "barnabe", "affinite_min": 10}},
			{"t": "Barnabé t'a parlé de moi ? Laisse-moi deviner : « c'est Octave qui tenait la barre ». Il ne changera jamais de disque.", "si": {"a_rencontre": "barnabe"}},
			{"t": "On dit qu'un poisson-lune doré nage au large. Si tu le pêches, je te l'achète une fortune. Barnabé n'aura jamais assez de coquillages pour le payer, lui.", "si": {"affinite_min": 25}},
			{"t": "Un secret : le coffre de paie de la Mouette était en bois de fer, cerclé de cuivre. Si ta pelle cogne sur du métal, appelle-moi. On partage. Soixante-quarante. Pour moi.", "si": {"affinite_min": 45}},
		],
		# ------------------------------------------------------------ boutique
		"boutique": [
			{"t": "Voilà la marchandise. Tout est forgé ici, dans l'arbre. Tu as {pieces} pièces : choisis bien.", "si": {}},
			{"t": "Pelle, hache, épée. Rien de superflu. Et je rachète le poisson, les coquillages et les champignons.", "si": {}},
			{"t": "Pour toi, {surnom}, les prix d'ami. Enfin, presque d'ami.", "si": {"affinite_min": 40}},
			{"t": "Je te préviens : avec ta tête du jour, c'est le prix fort.", "si": {"humeur_max": -0.15}},
		],
		"boutique_fermee": [
			{"t": "La boutique est FERMÉE. Pour toi. Reviens quand j'aurai digéré tes coups.", "si": {"fait": "frappe"}, "geste": "colere"},
			{"t": "Pas aujourd'hui. Je ne suis pas d'humeur à vendre. Ni à parler. Ni à rien.", "si": {}, "geste": "colere"},
		],
		"achat": [
			{"t": "Marché conclu. {objet}, pour {prix} pièces. Tu ne le regretteras pas.", "si": {}, "geste": "salut"},
		],
		"achat_pelle": [
			{"t": "Une pelle. Le meilleur ami du chercheur de trésor. Plante-la dans le sable de la plage et appuie : clic, et ça creuse. Chaque coin ne se creuse qu'une fois, alors bouge.", "si": {}, "geste": "salut"},
		],
		"achat_hache": [
			{"t": "La hache ! Bien en main, le fil vers l'avant. Elle coupe le bois… et le reste. Fais attention à tes pieds.", "si": {}, "geste": "rire"},
		],
		"achat_epee": [
			{"t": "Mon épée d'acier. Trois semaines de forge, trempée dans l'eau de mer. Tiens-la bien : c'est mon chef-d'œuvre. Ne la laisse pas rouiller.", "si": {}, "geste": "rire", "humeur": 0.15},
		],
		"achat_pauvre": [
			{"t": "{prix} pièces, et tu en as {pieces}. Ici, on ne fait pas crédit. C'est écrit en bas de l'échelle.", "si": {}},
			{"t": "Pas assez de pièces, {surnom}. Va pêcher et rapporte-moi du poisson, je te l'achète.", "si": {}},
		],
		"achat_deja": [
			{"t": "Tu en as déjà une. Une seule suffit : ce que je forge ne casse pas.", "si": {}},
		],
		"achat_plein": [
			{"t": "Ton sac déborde. Fais de la place, et reviens.", "si": {}},
		],
		"vente": [
			{"t": "Je te prends {objet} : {prix} en cuivre. Ne discute pas.", "si": {}},
			{"t": "Bon, pour {objet}, ça fera {prix}. Clou, range ça. Non, ne le mange pas.", "si": {}},
		],
		"vente_lot": [
			{"t": "Tout ça ? D'accord. {prix} pièces le lot. Tu fais une bonne affaire, et moi une meilleure.", "si": {}, "geste": "rire"},
		],
		"vente_coquillage": [
			{"t": "Un coquillage ? Je le prends. Pas pour moi, hein : pour que Barnabé ne l'ait pas. Hé hé hé.", "si": {}, "geste": "rire"},
		],
		"vente_vieille_botte": [
			{"t": "Cette botte… c'est celle de Barnabé ! Je la reconnais, je l'ai ressemelée moi-même. Je te l'achète {prix} pièces. Il ne la reverra jamais. HA !", "si": {}, "geste": "rire", "humeur": 0.2},
		],
		"vente_poisson_lune": [
			{"t": "Le… le poisson-lune doré. Ma parole. {prix} pièces, et c'est une affaire pour toi. Clou, ferme la bouche.", "si": {}, "geste": "rire", "humeur": 0.3},
		],
		"marchande_oui": [
			{"t": "Pfff. Tu as de la chance, je suis de bonne composition. Quinze pour cent, pour aujourd'hui seulement.", "si": {}},
			{"t": "Tu marchandes bien, pour un {surnom}. Allez : un petit rabais. Ne le dis à personne.", "si": {}, "geste": "rire"},
		],
		"marchande_non": [
			{"t": "Un prix ? C'est déjà un prix. Le fer coûte, le charbon coûte, Clou coûte. Non.", "si": {}},
			{"t": "Ha ! Non. Et la prochaine fois que tu marchandes, c'est plus cher.", "si": {}, "geste": "colere"},
		],
		"marchande_deja": [
			{"t": "On a déjà discuté prix aujourd'hui. C'est réglé.", "si": {}},
		],
		# ------------------------------------------------------------ cadeaux
		"cadeau_aime": [
			{"t": "{dernier_cadeau} ? Pour moi ? Hmm. Merci. Ça, c'est utile.", "geste": "salut"},
			{"t": "Des pièces ! Gratuites ! Tu es fou… mais je les garde.", "si": {"dernier_cadeau": "piece"}, "geste": "rire"},
			{"t": "Des bâtons bien droits : de futurs manches. Tu as l'œil.", "si": {"dernier_cadeau": "baton"}},
			{"t": "La botte de Barnabé ! Je vais la clouer au-dessus de ma porte. Comme un trophée.", "si": {"dernier_cadeau": "vieille_botte"}, "geste": "rire", "humeur": 0.25},
			{"t": "Un mérou… Je vais le fumer au-dessus de la forge. Tu reviendras goûter.", "si": {"dernier_cadeau": "merou"}, "geste": "rire"},
		],
		"cadeau_neutre": [
			{"t": "{dernier_cadeau}. Bon. Je trouverai bien à quoi ça sert.", "si": {}},
		],
		"cadeau_deteste": [
			{"t": "Un coquillage ?! Tu me prends pour Barnabé ? Remporte… non, laisse. Clou le jettera.", "si": {"dernier_cadeau": "coquillage"}, "geste": "colere"},
			{"t": "{dernier_cadeau} ? C'est une blague ?", "geste": "colere"},
		],
		"cadeau_refus": [
			{"t": "Me rendre mon propre travail ? Garde-le. Ce qui est vendu est vendu.", "si": {}},
		],
		"quete_fin": [
			{"t": "Six bâtons, et droits en plus. Tiens, douze pièces. Et la prochaine pelle te coûtera moins cher : tu es presque de la maison.", "geste": "salut", "humeur": 0.3},
		],
		"quete_manque": [
			{"t": "Tu n'as que {coquillages} bâtons. Il m'en faut {manque}. Les bois de l'île en sont pleins.", "si": {}},
		],
		"quete_inconnue": [
			{"t": "Mes bâtons ? Je ne t'ai rien demandé. Pas encore.", "si": {}},
		],
		"souvenir": [
			{"t": "Si je me souviens de toi ? Je me souviens de tous mes clients. Surtout de ceux qui ne paient pas.", "si": {}},
			{"t": "Évidemment. Je tiens les comptes, {surnom}.", "si": {}},
		],
		"au_revoir": [
			{"t": "C'est ça. Attention à la troisième marche de l'échelle, elle grince.", "si": {}},
			{"t": "À la prochaine, {surnom}. Reviens avec des pièces.", "si": {"humeur_min": 0.0}, "geste": "salut"},
			{"t": "Bon vent. Et si tu vois Barnabé… ne lui dis rien.", "si": {"a_rencontre": "barnabe"}},
			{"t": "Va. Et ne reviens pas les mains vides.", "si": {"humeur_max": -0.2}},
		],
		"interpelle": [
			{"t": "Hé, là-dessous ! Monte par l'échelle si tu veux faire affaire !", "si": {"visites_max": 0}},
			{"t": "Qui va là ? Un client ou un voleur ?", "si": {"visites_max": 0}},
			{"t": "Tiens, {surnom} ! Monte, j'ai du neuf. Enfin, du pareil.", "si": {"visites_min": 1, "humeur_min": -0.1}},
			{"t": "Encore toi…", "si": {"visites_min": 1, "humeur_max": -0.1}},
			{"t": "Clou, cache la caisse, voilà du monde !", "si": {"visites_min": 2}},
		],
		"frappe": [
			{"t": "AÏE ! Dans MA cabane ?! Les prix doublent !", "geste": "colere"},
			{"t": "Clou, tu as vu ? Il frappe le marchand ! Je m'en souviendrai.", "geste": "colere"},
			{"t": "Encore ! Dehors ! La boutique est fermée !", "si": {"fait": "frappe"}, "geste": "colere"},
		],
	},

	"questions": [
		{"id": "metier", "si": {"visites_max": 1}, "texte": "Tu sais te servir de tes mains, au moins ?",
			"reponses": [
				{"label": "Oui, je bricole un peu.", "valeur": "bricoleur", "affinite": 4.0, "humeur": 0.1, "t": "Bien. Un bricoleur, c'est un futur client. Un bon outil change tout, tu verras."},
				{"label": "Je préfère acheter tout fait.", "valeur": "acheteur", "affinite": 2.0, "humeur": 0.15, "t": "Ha ! La meilleure réponse que j'aie entendue depuis vingt ans. Bienvenue."},
				{"label": "Je me bats surtout à mains nues.", "valeur": "bagarreur", "affinite": 0.0, "humeur": -0.05, "t": "À mains nues ? Tu changeras d'avis devant mon épée. Elle coûte cher, mais elle convainc."},
			]},
		{"id": "barnabe", "si": {"a_rencontre": "barnabe", "visites_min": 1}, "texte": "Dis-moi… tu connais ce vieux fou de Barnabé, de l'autre côté ?",
			"reponses": [
				{"label": "C'est mon ami.", "valeur": "ami", "affinite": -3.0, "humeur": -0.15, "t": "Ton ami. Hmpf. Chacun ses fréquentations. Tant que tu paies…"},
				{"label": "Il est un peu bizarre.", "valeur": "bizarre", "affinite": 4.0, "humeur": 0.2, "t": "Un peu ? Il parle à un perroquet ET à des coquillages. Toi, tu es quelqu'un de sensé."},
				{"label": "Il regrette votre dispute, je crois.", "valeur": "regrets", "affinite": 2.0, "humeur": 0.05, "t": "… Il a dit ça ? Non. Il n'a pas dit ça. Il ne dit jamais ça. … Il a vraiment dit ça ?"},
			]},
		{"id": "clou", "si": {"visites_min": 3, "affinite_min": 25}, "texte": "Clou veut savoir s'il peut fouiller tes poches. Il demande, c'est nouveau.",
			"reponses": [
				{"label": "Vas-y, Clou.", "valeur": "oui", "affinite": 5.0, "humeur": 0.25, "t": "Clou fouille, trouve une miette, la mange, et s'endort sur ton épaule. Il t'a adopté. Moi aussi, un peu."},
				{"label": "Pas question !", "valeur": "non", "affinite": -1.0, "humeur": -0.05, "t": "Sage décision. Il ne rend jamais rien."},
			]},
	],
}
