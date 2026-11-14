extends RefCounted
## V146 : les gens de Pile-ou-Face, le bourg de l'Île Perchée (un Far West bâti sur de vieilles pierres et
## rafistolé à la vapeur ; ici, on mise tout, mais on ne triche jamais : le Shérif y veille).
##  - la grand-rue : la Veuve Clou (le Bazar ; une main de laiton à ressorts), Bartholomé Pattes-de-Velours
##    (le Saloon du Chien qui Mise, et Banco, le chien qui mise), Madame Pique (le Tripot de la Dame de
##    Pique ; une voilette, des devinettes), Cornélius « Grand-Dé » (la Fosse aux Dés ; il rit comme on
##    lance les dés), Doc Cornemuse (l'apothicaire qui soigne à la cornemuse), la Shérif Augustine Plomb
##    (une cuirasse de chevalier sous son gilet), Gédéon Tic (l'horloger, des lunettes à loupes), Abélard
##    Pépite (le vieux prospecteur qui parle à sa batée), Fanchon (la chapelière aux chapeaux à vapeur),
##    Hilda Enclume (la forgeronne au marteau-pilon), Rosemonde (l'épicerie Clous & Confitures) et
##    Pistache (dix ans, crieur du « Courrier Perché ») ;
##  - les accès : Marius Maillon (le gardien de la Grande Chaîne, qui compte les maillons) et Zoé Nuée
##    (l'aviatrice de la Navette des Nuées).
## Les tables de jeu (les dés, le blackjack, le poker) viendront ensuite ; les joueurs en parlent déjà.
## Corps V64 : tools/generate_perchee_v146.gd (des mélanges de corps d'habitants déjà faits).
## Identifiants suffixés « _pp » (Pile-ou-Face) pour ne rien croiser ailleurs dans l'archipel.

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "À la revoyure, {surnom} ! Et garde ta mise près du cœur.", "si": {}, "geste": "salut"},
		{"t": "Bonne route ! Si la Roue s'arrête quand tu passes, c'est que tu as de la chance. Ou qu'elle a besoin d'huile.", "si": {}, "geste": "rire"},
		{"t": "Bonne nuit ! Ici, la nuit, les saloons chantent et les étoiles misent entre elles.", "si": {"soir": true}, "geste": "rire"},
	],
	"frappe": [
		{"t": "Hé ! Range tes poings, cow-boy ! À Pile-ou-Face, on se dispute aux dés, pas aux coups. Sinon, la Shérif s'en mêle.", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Aïe ! Tu veux un duel ? Alors au bras de fer, chez Bartholomé. Et c'est le perdant qui paie la salsepareille.", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Pour moi ? Merci, {surnom}. Je le garde. Peut-être que je le miserai un jour. Peut-être pas.", "si": {}},
		{"t": "C'est gentil. Ici, on dit qu'un cadeau, c'est une mise qu'on fait sur l'amitié. Tu viens de gagner.", "si": {}},
	],
	"cadeau_aime": [
		{"t": "Oh ! {dernier_cadeau} ! Ça, c'est un coup de maître, {surnom} ! Double ou rien ? Non : double, point.", "si": {}, "geste": "rire"},
		{"t": "Par la Roue ! Tu as tiré le bon numéro, {surnom}. Merci !", "si": {}},
	],
	"cadeau_deteste": [{"t": "Euh… merci. C'est ce qu'on appelle une mauvaise donne. Je le garde quand même, par politesse.", "si": {}, "humeur": -0.1}],
	"cadeau_refus": [{"t": "Une arme ? Non merci. À Pile-ou-Face, les seules armes, ce sont les cartes et les dés. Et le sourire du Shérif.", "si": {}}],
	"souvenir": [{"t": "Si je me souviens de toi ? Bien sûr. Ici, on retient les visages. Surtout ceux qui ont de la chance.", "si": {}}],
	"quete_inconnue": [{"t": "Hein ? Je ne t'ai rien demandé. Pas encore. À Pile-ou-Face, tout vient à point à qui sait miser.", "si": {}, "geste": "rire"}],
	"blague": [
		{"t": "Pourquoi les dés ne mentent jamais ? Parce qu'ils ont six faces, et aucune de cachée.", "si": {}, "geste": "rire"},
		{"t": "Un cow-boy entre au saloon avec un nuage en laisse. Bartholomé lui dit : « Pas d'animaux. » Le cow-boy répond : « Ce n'est pas un animal, c'est mon parapluie. »", "si": {}, "geste": "rire"},
		{"t": "Quelle est la différence entre un joueur et un horloger ? L'horloger sait toujours quand il faut s'arrêter.", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Regarde, choisis, prends ce qu'il te faut. Tu as {pieces} pièces.", "si": {}}],
	"boutique_fermee": [{"t": "Non. Pour toi, la boutique est fermée. Reviens quand tu auras de meilleures manières.", "si": {}, "geste": "colere"}],
	"achat": [{"t": "Et voilà : {objet}, pour {prix} pièces. Marché conclu, topons là !", "si": {}, "geste": "salut"}],
	"achat_pauvre": [{"t": "C'est {prix} pièces, et tu n'en as que {pieces}… Même au poker, on ne mise pas ce qu'on n'a pas.", "si": {}}],
	"achat_deja": [{"t": "Tu en as déjà un, non ? Un seul suffit, crois-moi.", "si": {}}],
	"achat_plein": [{"t": "Ton sac est plein comme un saloon un samedi soir, {surnom}.", "si": {}, "geste": "rire"}],
	"vente": [{"t": "Pour ça ? Je t'en donne {prix} pièces. Pas une de plus, pas une de moins.", "si": {}}],
	"vente_lot": [{"t": "Tout le lot ? Allez : {prix} pièces, et une poignée de main en prime !", "si": {}, "geste": "rire"}],
	"marchande_oui": [{"t": "Bon… tu as une bonne tête de joueur. Un petit geste. Mais ne le crie pas sur la place.", "si": {}, "geste": "rire"}],
	"marchande_non": [{"t": "Marchander ? Mes prix sont comme les dés de Grand-Dé : ils ne se discutent pas.", "si": {}}],
	"marchande_deja": [{"t": "On a déjà marchandé aujourd'hui. Ne pousse pas ta chance, {surnom}.", "si": {}}],
}

const BASE := {
	"prefixes": {
		"joie": ["Par la Roue !", "Banco !", "Ha ha !", "Quelle veine !"],
		"neutre": ["Bon.", "Voyons…", "Hm.", "Alors…"],
		"triste": ["Hélas…", "Mauvaise donne…", "Pfff…", "Tout le monde se couche…"],
		"colere": ["Par tous les as !", "Ça suffit !", "Grrr.", "Tss."],
	},
	"tics": ["Banco !", "Par la Roue !", "Pile ou face ?", "Qui ne mise rien n'a rien."],
	"humeur_mots": [[0.6, "en veine"], [0.25, "de bonne humeur"], [-0.25, "un peu à sec"], [-0.6, "dans la mauvaise passe"], [-2.0, "complètement ruiné"]],
	"surnoms": [[0, "étranger"], [25, "voyageur"], [50, "mon partenaire"], [75, "as de cœur"], [95, "enfant de Pile-ou-Face"]],
}

const PEAU := [[1.0, 0.86, 0.74], [0.98, 0.8, 0.66], [0.92, 0.72, 0.56], [0.82, 0.6, 0.44], [0.66, 0.46, 0.34], [0.5, 0.34, 0.24], [1.0, 0.9, 0.8]]
const NOIR := [0.08, 0.06, 0.05]
const BRUN := [0.3, 0.19, 0.11]
const CHATAIN := [0.45, 0.3, 0.17]
const ROUX := [0.82, 0.3, 0.1]
const BLANC := [0.93, 0.92, 0.9]
const GRIS := [0.6, 0.6, 0.58]
const BLOND := [0.86, 0.68, 0.32]
const Y_BRUN := [0.32, 0.2, 0.12]
const Y_VERT := [0.3, 0.5, 0.28]
const Y_BLEU := [0.25, 0.45, 0.7]
const Y_GRIS := [0.45, 0.5, 0.55]


static func L(t: String, si: Dictionary = {}, geste: String = "") -> Dictionary:
	return Azur.L(t, si, geste)


static func complete(d: Dictionary) -> Dictionary:
	var out: Dictionary = d.duplicate(true)
	var rep: Dictionary = out.get("repliques", {})
	for k in COMMON:
		if not rep.has(k):
			rep[k] = COMMON[k]
	out["repliques"] = rep
	for k in ["prefixes", "tics", "humeur_mots", "surnoms"]:
		if not out.has(k):
			out[k] = BASE[k]
	out = Azur.complete(out)
	out["groupe"] = "perchee"
	return out


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out


static func _all() -> Array:
	return [
		# ================================================================ la grand-rue
		{"id": "veuve_clou_pp", "nom": "la Veuve Clou", "titre": "marchande du Bazar de la Veuve Clou", "maison": "porte_bazar", "village": "perchee", "vouvoie": true,
			"agenda": [[6, 20, "devant_bazar"], [20, 22, "banc_0"], [22, 6, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "chignon", "yeux": Y_GRIS, "robe": [0.1, 0.09, 0.1], "robe_longue": true, "haut": [0.12, 0.1, 0.12], "lunettes": true, "taille": 0.88},
			"teinte": PEAU[0], "mj": {"tenue": "marchand", "objet": "canne"},
			"humeur_base": 0.35, "traits": {"bavard": 0.6, "humour": 0.8, "curiosite": 0.7, "susceptible": 0.5, "rancunier": 0.4},
			"aime": {"engrenage": 2.0, "ressort": 2.0, "the_menthe": 1.5, "boulon": 1.5, "chocolat_chaud": 1.5}, "deteste": {"gelee_slime": -2.0, "vieille_botte": -0.5},
			"tics": ["Clic, clac.", "Un clou chasse l'autre.", "Hm hm.", "De mon temps…"],
			"surnoms": [[0, "jeune homme"], [25, "mon petit clou"], [50, "ma vis préférée"], [75, "mon boulon d'or"], [95, "mon trésor"]],
			"boutique": {"vend": {"corde_chanvre": 4, "pelle": 8, "canne_peche": 12, "boussole": 10, "ressort": 2, "engrenage": 3, "boulon": 1}, "achete": {"boulon": 1, "ressort": 1, "engrenage": 2, "vieille_botte": 1, "minerai_fer": 2, "corde_chanvre": 2}},
			"repliques": {
				"accueil": [
					L("Approchez, approchez. Clic, clac. Ne faites pas attention à ma main : elle est en laiton, à ressorts, et elle serre plus fort que la vôtre. Feu mon mari l'a fabriquée. Il était inventeur. Il est parti dans un ballon de sa fabrication, et le ballon ne l'a jamais rendu.", {"visites_max": 1}),
					L("Tiens, {surnom} ! Ma main vous a reconnu avant moi. Elle a fait « clic ». Elle fait « clic » pour les gens qu'elle aime bien.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Bonne. J'ai vendu un tire-bouchon à quelqu'un qui n'avait pas de bouteille. Il m'a dit : « On ne sait jamais. » C'est la devise de mon bazar.", {}, "rire"),
					L("Le soir, je m'assois sur un banc de la place et je regarde la Roue tourner. Mon mari disait : « Quand elle s'arrêtera, je reviendrai. » Elle ne s'arrête jamais. Alors je reviens, moi, tous les soirs.", {"soir": true}),
				],
				"lui": [
					L("On m'appelle la Veuve Clou. Je ne suis pas sûre d'être veuve : peut-être que Clou plane encore quelque part, au-dessus des nuages, en train de bricoler son ballon. Il en serait bien capable.", {}),
					L("Dans mon bazar, il y a de tout : des clous, des vis, des cordes, des boussoles qui indiquent le sud, une lampe qui s'éteint quand on lui parle… Si vous cherchez quelque chose, je l'ai. Si je ne l'ai pas, c'est que vous ne le cherchez pas vraiment.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Pile-ou-Face, c'était un château, autrefois. Les vieilles pierres sont encore là, sous les planches. Puis les chercheurs d'or sont arrivés, les joueurs ensuite, et la vapeur en dernier. Aujourd'hui, tout le monde mise. Moi, je mise sur les clous. Ça rapporte peu, mais ça ne perd jamais.", {}),
					L("L'île flotte grâce aux Pierres-de-Ciel, sous nos pieds, dans leurs cages de fer. Mon mari disait qu'elles chantent la nuit. Moi, je n'entends que les saloons.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Entre nous : Madame Pique, au Tripot, ne retire jamais sa voilette. Pas même pour boire son thé. Elle le boit à la paille. J'ai vu la paille.", {}, "rire"),
					L("Bartholomé dit que son chien sait compter jusqu'à vingt et un. Moi, je dis qu'il sait surtout compter les saucisses.", {}, "rire"),
				],
				"interpelle": [L("Psst ! Vous ! Il vous manque un clou, ça se voit.", {"visites_max": 0}), L("{surnom} ! Ma main vous fait coucou. Clic.", {"visites_min": 1}, "salut")],
				"boutique": [L("Clous, cordes, ressorts, boussoles… Tout ce qu'il faut, et un peu de ce qu'il ne faut pas. Vous avez {pieces} pièces.", {})],
			}},
		{"id": "bartholome_pp", "nom": "Bartholomé Pattes-de-Velours", "titre": "patron du Saloon du Chien qui Mise", "maison": "porte_saloon", "village": "perchee",
			"agenda": [[9, 2, "comptoir_saloon"], [2, 9, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "court", "barbe": "moustache", "yeux": Y_BRUN, "chapeau": "haut_de_forme", "chapeau_c": [0.1, 0.08, 0.08], "haut": [0.62, 0.12, 0.1], "tablier": [0.95, 0.94, 0.9], "taille": 1.1, "carrure": 1.2},
			"teinte": PEAU[2], "mj": {"tenue": "cuisinier", "objet": "plateau"},
			"humeur_base": 0.7, "traits": {"bavard": 0.9, "humour": 0.9, "curiosite": 0.6, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"chocolat_chaud": 2.0, "miel": 1.5, "tarte_figue": 2.5, "haricots_ranch": 2.0, "cacao": 2.0}, "deteste": {"gelee_slime": -1.5, "soda_neon": -1.0},
			"tics": ["Banco !", "À la vôtre !", "Par ma moustache !", "Une autre ?"],
			"surnoms": [[0, "étranger"], [25, "cow-boy"], [50, "habitué"], [75, "pilier du comptoir"], [95, "mon as de cœur"]],
			"boutique": {"vend": {"salsepareille": 3, "haricots_ranch": 5, "tarte_figue": 6, "cafe_vapeur": 3, "chocolat_chaud": 4}, "achete": {"miel": 4, "cacao": 3, "pomme": 1, "baies": 1}},
			"repliques": {
				"accueil": [
					L("Bienvenue au Saloon du Chien qui Mise, étranger ! Bartholomé Pattes-de-Velours, pour vous servir. On m'appelle comme ça parce que je marche sans bruit. Et parce que je ne renverse jamais un verre. Jamais. Sauf les mardis.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Ta salsepareille t'attend. Elle commençait à s'inquiéter.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Excellente ! Banco a gagné trois parties de dés ce matin. Il a misé un os, il a gagné trois os. Ce chien est un génie. Un génie qui mâchonne mes chaussons, mais un génie.", {}, "rire"),
					L("Le soir, le saloon chante. Il y a le piano mécanique, les cartes qui claquent, les dés qui roulent. Et moi, je cire ma moustache. Une moustache bien cirée, c'est la moitié du métier.", {"soir": true}),
				],
				"lui": [
					L("Banco, c'est mon chien. Il s'assoit à la table de dés, il regarde les joueurs, et quand il aboie une fois, c'est « pair ». Deux fois, « impair ». Il se trompe souvent. Mais il y croit tellement que personne n'ose lui dire.", {}, "rire"),
					L("Ici, pas une goutte de whisky : de la salsepareille, du café à la vapeur, du chocolat. On a la tête claire pour jouer. Et on a la tête claire pour perdre, ce qui est plus important.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Bientôt, on va monter les grandes tables, au saloon et dans tout le bourg : les dés, le blackjack, le poker. Les gens viendront de tout l'archipel ! On pourra miser des pièces, des objets… et se faire une réputation. De pigeon, ou de maître du jeu. À vous de voir.", {}),
					L("Pile-ou-Face a une règle, une seule : on ne triche pas. Celui qui triche, la Shérif Plomb le met au pilori, sur la place. Le pilori, c'est un banc où tout le monde vient vous raconter ses histoires. Très longues. C'est terrible.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Grand-Dé, à la Fosse, a des dés qui portent un nom. Il y en a un qui s'appelle Gaston. Gaston fait toujours six. Enfin, Gaston dit qu'il fait toujours six.", {}, "rire"),
					L("Au fond de chez le barbier, il paraît qu'il y a une salle secrète. On y joue au poker, la nuit. Je n'en sais rien. Je n'en parle pas. Je n'en ai jamais parlé.", {}),
				],
				"interpelle": [L("Hé, étranger ! Une salsepareille ? C'est la maison qui… non, c'est vous qui offrez.", {"visites_max": 0}, "rire"), L("{surnom} ! Viens, Banco t'a gardé ta place !", {"visites_min": 1}, "salut")],
				"boutique": [L("Salsepareille glacée, haricots du ranch, tarte aux figues de Barbarie… Vous avez {pieces} pièces. Banco, tu ne touches pas à la tarte.", {}, "rire")],
			}},
		{"id": "dame_pique_pp", "nom": "Madame Pique", "titre": "la Dame de Pique, patronne du Tripot", "maison": "porte_tripot", "village": "perchee", "vouvoie": true,
			"agenda": [[15, 3, "devant_tripot"], [3, 15, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "long", "yeux": Y_VERT, "robe": [0.06, 0.05, 0.06], "robe_longue": true, "haut": [0.35, 0.05, 0.08], "chapeau": "capeline", "chapeau_c": [0.05, 0.04, 0.05]},
			"teinte": PEAU[1], "mj": {"tenue": "noble"},
			"humeur_base": 0.4, "traits": {"bavard": 0.4, "humour": 0.6, "curiosite": 0.9, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"the_menthe": 2.0, "rubis": 2.5, "perle": 2.0, "fleur_nebuleuse": 2.0, "bouquet_tournesols": 1.0}, "deteste": {"gelee_slime": -2.0},
			"tics": ["Hm.", "Les cartes le savent.", "Devinez.", "Coupez."],
			"surnoms": [[0, "voyageur"], [25, "joueur"], [50, "valet"], [75, "roi de cœur"], [95, "mon atout"]],
			"repliques": {
				"accueil": [
					L("Bonsoir. Ne cherchez pas mon visage derrière la voilette : il n'y a rien à voir, qu'une joueuse. On m'appelle la Dame de Pique. Devinez pourquoi.", {"visites_max": 1}),
					L("{surnom}. Je vous attendais. Non, je ne lis pas l'avenir. Je lis les gens. C'est plus facile, et ça se trompe moins.", {"visites_min": 2}),
				],
				"humeur": [
					L("Calme. Comme une main de cinq cartes avant qu'on la retourne.", {}),
					L("La nuit, mon tripot s'allume. Les lampes sont vertes, les tables sont vertes, et les joueurs aussi, quand ils perdent.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Une devinette : j'ai un cœur, mais je ne bats pas ; j'ai une tête, mais je ne pense pas ; j'ai un roi, mais pas de royaume. Qui suis-je ? … Un jeu de cartes, voyons.", {}, "rire"),
					L("Au blackjack, il faut s'approcher de vingt et un sans jamais le dépasser. Comme dans la vie : vouloir beaucoup, mais savoir s'arrêter. Bientôt, ma table sera ouverte. Nous verrons si vous savez vous arrêter.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Les gens d'ici vous appelleront « pigeon » si vous perdez trop, et « maître du jeu » si vous gagnez avec élégance. L'élégance compte plus que les gains. Retenez-le.", {}),
					L("Je suis arrivée par la Grande Chaîne, il y a longtemps, avec une valise et un jeu de cartes. La valise est vide. Le jeu de cartes, lui, a tout gagné.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Gédéon Tic veut construire une machine qui bat les cartes toute seule. Je lui ai dit qu'une machine ne sait pas bluffer. Il m'a répondu : « Justement. »", {}),
					L("Pistache, le petit crieur, sait tout avant tout le monde. Je soupçonne qu'il écrit les nouvelles avant qu'elles n'arrivent.", {}, "rire"),
				],
				"interpelle": [L("Vous. Oui, vous. Approchez. Les cartes veulent vous voir.", {"visites_max": 0}), L("{surnom}. Coupez le jeu, voulez-vous.", {"visites_min": 1})],
			}},
		{"id": "grand_de_pp", "nom": "Cornélius « Grand-Dé »", "titre": "maître de la Fosse aux Dés", "maison": "porte_fosse", "village": "perchee",
			"agenda": [[10, 1, "devant_fosse"], [1, 10, "maison"]],
			"azur": {"cheveux": ROUX, "coiffure": "court", "barbe": "courte", "yeux": Y_BLEU, "haut": [0.85, 0.82, 0.7], "tablier": [0.4, 0.25, 0.15], "taille": 0.86, "carrure": 1.5},
			"teinte": PEAU[0], "mj": {"tenue": "artisan"},
			"humeur_base": 0.85, "traits": {"bavard": 1.0, "humour": 1.0, "curiosite": 0.5, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"haricots_ranch": 2.5, "salsepareille": 2.0, "galette_mais": 1.5, "pain_miel": 1.5}, "deteste": {"des_pipes": -2.5},
			"tics": ["HA HA !", "Ça roule !", "Six et six, douze !", "Rien ne va plus !"],
			"surnoms": [[0, "petit"], [25, "lanceur"], [50, "mon double-six"], [75, "roi des dés"], [95, "mon jackpot"]],
			"repliques": {
				"accueil": [
					L("HA HA ! Un nouveau ! Bienvenue à la Fosse aux Dés ! Cornélius, dit Grand-Dé. Grand, parce que je ris fort. Dé, parce que… eh bien, regarde autour de toi. Ici, tout roule !", {"visites_max": 1}, "rire"),
					L("{surnom} ! Te voilà ! Tu as la main chaude, je le sens. Ça roule ?", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Formidable ! Hier soir, un joueur a fait trois doubles-six d'affilée. On a tous crié si fort que les corbeaux du Vieux-Pic ont applaudi.", {}, "rire"),
					L("Bientôt, la Fosse rouvre en grand ! On jouera au Menteur, à la Ronde des Six et au Grand Lancer. Tu mises, tu lances, tu cries. Surtout, tu cries.", {}),
				],
				"lui": [
					L("Mes dés ont des noms. Gaston, Pétula, Bobine, Fernand, Clémentine et Lulu. Gaston fait toujours six. Enfin, il le dit. Pétula ne dit rien. C'est la plus dangereuse.", {}, "rire"),
					L("On ne triche pas, chez moi. Jamais. Celui qui sort des dés pipés, je les lui confisque, je les cloue au mur, et il doit danser la gigue devant toute la Fosse. Personne n'a envie de danser la gigue devant moi.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("La Fosse, c'était le cellier du vieux château. Une cave de pierre voûtée. Le son des dés y résonne comme le tonnerre. Quand je lance, tout Pile-ou-Face l'entend !", {}),
					L("Les pigeons et les maîtres du jeu, c'est ce qu'on dit ici. Moi, je dis : il y a ceux qui s'amusent, et ceux qui ne s'amusent pas. Les premiers gagnent toujours, même quand ils perdent.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Doc Cornemuse a essayé de soigner mon hoquet en jouant de la cornemuse. Le hoquet est parti. Les voisins aussi.", {}, "rire"),
					L("Hilda, la forgeronne, m'a battu au bras de fer. Trois fois. Je l'ai laissée gagner. Les trois fois. Exprès. HA HA ! … Non, ce n'est pas vrai.", {}, "rire"),
				],
				"interpelle": [L("Hé, toi ! Tu as une tête à faire un double-six !", {"visites_max": 0}, "rire"), L("{surnom} ! Ça roule ?!", {"visites_min": 1}, "rire")],
			}},
		{"id": "cornemuse_pp", "nom": "Doc Cornemuse", "titre": "apothicaire", "maison": "porte_apothicaire", "village": "perchee",
			"agenda": [[7, 19, "devant_apothicaire"], [19, 21, "place_roue"], [21, 7, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "court", "barbe": "longue", "yeux": Y_GRIS, "chapeau": "haut_de_forme", "chapeau_c": [0.22, 0.3, 0.2], "haut": [0.2, 0.35, 0.25], "taille": 1.12, "carrure": 0.8, "lunettes": true},
			"teinte": PEAU[1], "mj": {"tenue": "savant", "objet": "livre"},
			"humeur_base": 0.55, "traits": {"bavard": 0.8, "humour": 0.7, "curiosite": 0.9, "susceptible": 0.5, "rancunier": 0.2},
			"aime": {"miel": 2.0, "champignon": 1.5, "tisane_lune": 2.0, "fleur_lune": 2.0, "the_menthe": 1.5}, "deteste": {"piment_infernal": -1.5},
			"tics": ["Respirez.", "Tirez la langue.", "Hmm, je vois.", "Un petit air ?"],
			"surnoms": [[0, "mon patient"], [25, "mon cher patient"], [50, "mon patient préféré"], [75, "mon cas fascinant"], [95, "mon miracle"]],
			"boutique": {"vend": {"potion_mana": 12, "remontant_doc": 8, "tisane_lune": 4, "potion_seve": 6, "miel": 4}, "achete": {"champignon": 2, "baies": 1, "miel": 4, "truffe": 8}},
			"repliques": {
				"accueil": [
					L("Ah ! Un patient ! Doc Cornemuse, apothicaire diplômé de… euh… d'un endroit très sérieux. Tirez la langue. Hmm. Vous avez une langue. C'est bon signe.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Comment va le hoquet ? Vous n'en avez pas ? Dommage. J'avais préparé un air spécial.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Très bonne. J'ai guéri trois hoquets, un éternuement coincé et une crise de fou rire. Le fou rire, c'était moi. Je me suis guéri tout seul, en lisant mon propre diplôme.", {}, "rire"),
					L("Le soir, je joue de la cornemuse sur la place. Les gens disent que ça soigne la mélancolie. Ou que ça la fait fuir. Le résultat est le même.", {"soir": true}, "rire"),
				],
				"lui": [
					L("La cornemuse, c'est ma méthode. Une note grave pour le mal de dos, une note aiguë pour le hoquet, et le grand air des Hautes-Terres pour les cœurs brisés. Ça marche une fois sur deux. L'autre fois, ça fait rire, et rire, ça soigne aussi.", {}),
					L("Mes potions, je les fais avec les plantes de l'île : la fleur de cactus, l'armoise, le miel des abeilles de la prairie. Et une pincée de vapeur. La vapeur, ça rend tout plus scientifique.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Sur cette île, il y a de l'air pur, du soleil, des mesas rouges, et des gens qui misent leur chapeau sur un coup de dé. L'air pur, c'est bon pour les poumons. Le reste, c'est bon pour mes affaires.", {}, "rire"),
					L("Au bord du ruisseau de l'Orpailleur poussent des herbes à fièvre. Je n'y touche pas : il paraît qu'elles soignent mieux là où elles poussent. Mais le miel et les champignons, rapportez-m'en, je vous en donne un bon prix.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("La Shérif Plomb porte une cuirasse de chevalier sous son gilet. Elle dit que c'est pour le dos. Moi, je dis qu'elle a peur des chatouilles.", {}, "rire"),
					L("Le vieux Pépite parle à sa batée. Je l'ai examiné : il va très bien. C'est la batée qui m'inquiète. Elle répond.", {}, "rire"),
				],
				"interpelle": [L("Vous ! Vous avez une petite mine. Approchez, que je vous ausculte.", {"visites_max": 0}), L("{surnom} ! Un petit air de cornemuse ?", {"visites_min": 1}, "rire")],
				"boutique": [L("Potions, tisanes, remontants… et la consultation est gratuite. La cornemuse aussi, malheureusement. Vous avez {pieces} pièces.", {}, "rire")],
			}},
		{"id": "sherif_plomb_pp", "nom": "la Shérif Augustine Plomb", "titre": "shérif de Pile-ou-Face", "maison": "porte_sherif", "village": "perchee",
			"agenda": [[6, 12, "devant_sherif"], [12, 14, "place_roue"], [14, 20, "devant_sherif"], [20, 23, "banc_1"], [23, 6, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "queue", "yeux": Y_BRUN, "chapeau": "stetson", "chapeau_c": [0.42, 0.3, 0.18], "haut": [0.55, 0.56, 0.6], "foulard": [0.7, 0.12, 0.1], "taille": 1.05, "carrure": 1.1},
			"teinte": PEAU[3], "mj": {"tenue": "garde"},
			"humeur_base": 0.45, "traits": {"bavard": 0.4, "humour": 0.5, "curiosite": 0.6, "susceptible": 0.4, "rancunier": 0.3},
			"aime": {"cafe_vapeur": 2.5, "haricots_ranch": 1.5, "pain_miel": 1.0, "boussole": 1.5}, "deteste": {"des_pipes": -3.0, "gelee_slime": -1.0},
			"tics": ["Hm.", "Circulez.", "Pas d'histoires.", "La loi, c'est la loi."],
			"surnoms": [[0, "étranger"], [25, "citoyen"], [50, "adjoint"], [75, "mon adjoint préféré"], [95, "mon bras droit"]],
			"repliques": {
				"accueil": [
					L("Halte. Shérif Augustine Plomb. Ici, une seule loi : pas de triche. Le reste, c'est votre affaire. Bienvenue à Pile-ou-Face.", {"visites_max": 1}),
					L("{surnom}. Toujours honnête ? Bien. Continuez comme ça.", {"visites_min": 2}),
				],
				"humeur": [
					L("Tranquille. Personne n'a triché depuis trois jours. Ça me laisse le temps de polir ma cuirasse.", {}),
					L("Le soir, je fais ma ronde, puis je m'assois sur la place. J'écoute. Un dé qui sonne faux, je l'entends de l'autre bout de la rue.", {"soir": true}),
				],
				"lui": [
					L("Cette cuirasse ? Elle était à mon arrière-arrière-grand-mère, chevalier du vieux château. Je la porte sous mon gilet. Elle arrête les bousculades, les coups de coude au comptoir, et les mauvaises pensées.", {}),
					L("Mon donjon, derrière le bureau, a mille ans. Au sommet, j'ai installé une sirène à vapeur. Quand quelqu'un triche, elle hurle. Elle n'a hurlé que deux fois. Les deux fois, c'était un chat.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Vous voulez miser ? Allez-y. Mais misez ce que vous pouvez perdre. Ceux qui misent leur chemise finissent comme pigeons. Ceux qui savent s'arrêter deviennent maîtres. C'est tout ce que j'ai à dire.", {}),
					L("Si vous tombez du bord, le grand filet vous rattrapera. Mais n'en faites pas une habitude : le filet râle à chaque fois.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("On me dit qu'il y a une salle de poker secrète en ville. Je le sais. Tout le monde sait que je le sais. Tant qu'on y joue honnêtement, je ne la trouve pas.", {}),
					L("Bartholomé a promis à son chien une étoile de shérif en fer-blanc. S'il la lui donne, je démissionne. Le chien ferait un meilleur travail.", {}, "rire"),
				],
				"interpelle": [L("Vous. Pas d'histoires, hein.", {"visites_max": 0}), L("{surnom}. Tout va bien ?", {"visites_min": 1}, "salut")],
			}},
		{"id": "gedeon_tic_pp", "nom": "Gédéon Tic", "titre": "horloger-mécanicien de l'Horlogerie Tic & Tac", "maison": "porte_horloger", "village": "perchee",
			"agenda": [[8, 20, "devant_horloger"], [20, 8, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "boucles", "yeux": Y_VERT, "haut": [0.5, 0.42, 0.3], "tablier": [0.3, 0.2, 0.12], "lunettes": true, "taille": 0.95, "carrure": 0.85},
			"teinte": PEAU[2], "mj": {"tenue": "artisan", "objet": "marteau"},
			"humeur_base": 0.6, "traits": {"bavard": 0.8, "humour": 0.6, "curiosite": 1.0, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"engrenage": 3.0, "ressort": 2.5, "montre_envers": 2.0, "cristal_astral": 2.0, "biscuit_engrenage": 1.5}, "deteste": {"boite_a_rien": -1.0},
			"tics": ["Tic !", "Tac !", "Fascinant.", "Attendez, je règle."],
			"surnoms": [[0, "visiteur"], [25, "apprenti"], [50, "mécanicien"], [75, "mon rouage"], [95, "mon grand ressort"]],
			"boutique": {"vend": {"montre_envers": 14, "canard_mecanique": 18, "boussole_sud": 15, "ressort": 2, "engrenage": 3, "lunettes_kaleido": 12}, "achete": {"engrenage": 2, "ressort": 1, "boulon": 1, "cristal_astral": 8, "fragment_meteorite": 6}},
			"repliques": {
				"accueil": [
					L("Tic ! Pardon. Tac ! Gédéon Tic, horloger-mécanicien. Ne regardez pas mes lunettes, elles ont sept loupes et elles grossissent tout, même les politesses. Bonjour. BONJOUR. Voilà.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Vous tombez à pic : je viens de finir une machine qui ne sert à rien. Elle le fait très bien.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Excellente. J'ai réglé la Roue de la Fortune ce matin. Elle tourne à la vitesse idéale : assez lente pour qu'on rêve, assez rapide pour qu'on n'ait pas le temps d'y croire.", {}),
					L("Je travaille sur une machine à battre les cartes, pour Madame Pique. Elle bat les cartes. Elle bat aussi les œufs, les tapis et, une fois, mon chapeau.", {}, "rire"),
				],
				"lui": [
					L("Tous les rouages qui tournent dans le bourg, c'est moi : les roues sur les façades, l'éolienne, le treuil de la Grande Chaîne. J'aime que les choses tournent. C'est la preuve qu'elles sont vivantes.", {}),
					L("Mon rêve ? Une horloge qui donnerait l'heure de la chance. Pas l'heure qu'il est : l'heure où il faut miser. Je la règle depuis dix ans. Pour l'instant, elle sonne toujours trop tard.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Les Pierres-de-Ciel, sous l'île, je les ai mesurées. Elles vibrent à la fréquence d'un la. Un la parfait. Doc Cornemuse essaie de jouer avec elles. Les Pierres ne sont pas d'accord.", {}, "rire"),
					L("Pour les grandes tables de jeu, je fabrique des machines : un sabot qui distribue les cartes, un gobelet qui secoue les dés tout seul. Bientôt, vous verrez !", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Fanchon, la chapelière, m'a commandé un chapeau à hélice. Je lui ai fait. Elle s'est envolée jusqu'au château d'eau. Elle était ravie.", {}, "rire"),
					L("Marius, à la Chaîne, compte les maillons. Il en a compté neuf mille quatre cent douze. Moi, j'en compte neuf mille quatre cent treize. Nous ne nous parlons plus.", {}, "rire"),
				],
				"interpelle": [L("Tic ! Vous, là ! Vous aimez ce qui tourne ?", {"visites_max": 0}), L("{surnom} ! Tac !", {"visites_min": 1}, "rire")],
				"boutique": [L("Ressorts, engrenages, montres qui reculent, canards qui marchent… Tout est garanti un an. Ou un tour. Vous avez {pieces} pièces.", {}, "rire")],
			}},
		{"id": "pepite_pp", "nom": "le vieil Abélard Pépite", "titre": "prospecteur, au Comptoir des Prospecteurs", "maison": "porte_prospecteurs", "village": "perchee",
			"agenda": [[6, 10, "abreuvoir"], [10, 18, "devant_prospecteurs"], [18, 22, "banc_2"], [22, 6, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "court", "barbe": "longue", "yeux": Y_BLEU, "chapeau": "stetson", "chapeau_c": [0.5, 0.42, 0.3], "haut": [0.55, 0.35, 0.22], "taille": 0.92, "carrure": 0.9},
			"teinte": PEAU[3], "mj": {"tenue": "paysan", "objet": "panier"},
			"humeur_base": 0.6, "traits": {"bavard": 1.0, "humour": 0.8, "curiosite": 0.6, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"pepite_or": 3.0, "haricots_ranch": 2.0, "cafe_vapeur": 1.5, "galette_mais": 1.5}, "deteste": {"gelee_slime": -1.0},
			"tics": ["Hé hé.", "Pas vrai, Ginette ?", "Ça brille !", "De l'or, petit, de l'or !"],
			"surnoms": [[0, "petit"], [25, "fiston"], [50, "mon associé"], [75, "mon filon"], [95, "ma grosse pépite"]],
			"boutique": {"vend": {"pepite_or": 12, "pelle": 8, "galette_mais": 3}, "achete": {"pepite_or": 8, "minerai_fer": 3, "eclat_cristal": 7, "obsidienne": 4, "cristal_soufre": 5, "rubis": 20, "piece_or": 10}},
			"repliques": {
				"accueil": [
					L("Hé hé ! Un jeunot ! Abélard Pépite, prospecteur. Et voici Ginette, ma batée. Dis bonjour, Ginette. … Elle est timide. Elle a trouvé sa première pépite en dix-huit cent… euh… il y a longtemps.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Ginette parlait de toi justement. En bien. Enfin, je crois. Elle parle bas.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Bonne ! Ce matin, au ruisseau de l'Orpailleur, j'ai trouvé trois paillettes. Ginette en a trouvé quatre. Elle triche, je crois. Ne le dis pas à la Shérif.", {}, "rire"),
					L("Le soir, je m'assois sur la place et je raconte mes histoires à qui veut. Et à qui ne veut pas. Surtout à qui ne veut pas : ce sont les meilleurs auditeurs.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Je suis arrivé ici avant le bourg, avant les saloons, avant la vapeur. Il n'y avait que la prairie, les mesas, et le vieux château en ruine. Et l'or du ruisseau. J'ai planté ma tente au bord de l'eau. La tente est toujours là. Moi, j'ai déménagé au Comptoir.", {}),
					L("L'or du ruisseau vient de la Chute, qui le ramène… non, attends, la Chute descend. Alors d'où vient l'or ? Mystère. Ginette dit que ça vient des Pierres-de-Ciel. Ginette lit trop.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Si tu trouves de l'or, des cristaux, du minerai, apporte-les-moi. Je les achète bon prix. Pas trop bon. Mais bon.", {}),
					L("Au Vieux-Pic, il y a des corbeaux qui ramassent tout ce qui brille. Un jour, je grimperai voir leur nid. Il doit y avoir un trésor. Ou des cuillères. Beaucoup de cuillères.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Pistache vend son journal un sou. Il y a tout dedans, même ce qui n'est pas encore arrivé. Hier, il a annoncé ma mort. J'ai acheté trois exemplaires pour vérifier.", {}, "rire"),
					L("Rosemonde fait une tarte aux figues de Barbarie qui pique. Pas à cause des épines. À cause du piment. Elle dit que c'est la recette de sa grand-mère. Sa grand-mère était cracheuse de feu.", {}, "rire"),
				],
				"interpelle": [L("Hé, jeunot ! Tu as vu briller quelque chose ?", {"visites_max": 0}, "rire"), L("{surnom} ! Ginette te salue !", {"visites_min": 1}, "salut")],
				"boutique": [L("De l'or, des pelles, et des galettes pour la route. Montre-moi ce que tu as trouvé. Tu as {pieces} pièces.", {})],
			}},
		{"id": "fanchon_pp", "nom": "Fanchon Fil-d'Or", "titre": "chapelière, Au Chapeau Pointu", "maison": "porte_chapelier", "village": "perchee",
			"agenda": [[9, 19, "devant_chapelier"], [19, 22, "devant_theatre"], [22, 9, "maison"]],
			"azur": {"cheveux": [0.85, 0.35, 0.5], "coiffure": "boucles", "yeux": Y_VERT, "robe": [0.3, 0.55, 0.5], "haut": [0.95, 0.85, 0.6], "chapeau": "capeline", "chapeau_c": [0.9, 0.5, 0.2], "taille": 0.97},
			"teinte": PEAU[4], "mj": {"tenue": "barde"},
			"humeur_base": 0.8, "traits": {"bavard": 0.9, "humour": 0.8, "curiosite": 0.8, "susceptible": 0.5, "rancunier": 0.1},
			"aime": {"plume_perroquet": 2.5, "plume_ara": 2.5, "plume_corbeau": 1.5, "chapeau_ventilateur": 2.0, "bouquet_tournesols": 2.0}, "deteste": {"vieille_botte": -1.5},
			"tics": ["Divin !", "Ça vous irait à ravir !", "Un chapeau, c'est une humeur.", "Tournez-vous !"],
			"surnoms": [[0, "tête nue"], [25, "mon client"], [50, "mon mannequin"], [75, "ma muse"], [95, "mon chef-d'œuvre"]],
			"boutique": {"vend": {"chapeau_stetson": 25, "chapeau_ventilateur": 22, "plume_perroquet": 6}, "achete": {"plume_perroquet": 4, "plume_ara": 5, "plume_corbeau": 3, "toile_voile": 3}},
			"repliques": {
				"accueil": [
					L("Oh ! Une tête nue ! Quelle tragédie ! Fanchon Fil-d'Or, chapelière. Asseyez-vous, je prends vos mesures. Tour de tête : courageux. Forme du crâne : aventureuse. Il vous faut un stetson. Évidemment.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Tournez-vous ! … Non, toujours pas de chapeau. Je vais pleurer.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Divine ! J'ai inventé un chapeau à vapeur : quand on se met en colère, il siffle. Bartholomé en a acheté un. Il siffle tout le temps. Il est pourtant de très bonne humeur. Je dois revoir le réglage.", {}, "rire"),
					L("Le soir, je vais au Théâtre des Mirages. Pour la pièce ? Non. Pour les chapeaux des spectateurs. Il y a toujours des idées à prendre. Et des chapeaux à refaire.", {"soir": true}),
				],
				"lui": [
					L("Un chapeau, c'est une humeur. Le stetson, c'est l'aventure. Le haut-de-forme, la dignité. Le melon, la ponctualité. Et la capeline, c'est l'été. Moi, j'ai des humeurs toute l'année, alors j'ai des chapeaux toute l'année.", {}),
					L("J'ai appris le métier à la ville, en bas, très loin. Puis j'ai vu l'Île Perchée passer dans le ciel, avec ses saloons et ses gens à chapeaux. J'ai pris la Grande Chaîne le jour même. On ne laisse pas passer une île pleine de têtes.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Rapportez-moi des plumes ! Des plumes de perroquet, d'ara, de corbeau… Les corbeaux du Vieux-Pic en perdent beaucoup. Ils sont très coquets.", {}),
					L("Pour les grandes parties de cartes qui se préparent, je couds des chapeaux de joueur : un pour le chanceux, un pour le malchanceux. Le même, en fait. Tout dépend de comment on le porte.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Madame Pique m'a commandé une voilette plus épaisse. Plus épaisse ! On ne verra plus rien. Ni ses yeux, ni son bluff. C'est peut-être le but.", {}),
					L("Hilda, la forgeronne, porte un bandana depuis quinze ans. Le même. Je lui ai proposé trente chapeaux. Elle a dit non trente fois. Je respecte. Mais je souffre.", {}, "rire"),
				],
				"interpelle": [L("Vous ! Votre tête me fait de la peine. Venez !", {"visites_max": 0}, "rire"), L("{surnom} ! Un nouveau chapeau ?", {"visites_min": 1}, "salut")],
				"boutique": [L("Des chapeaux pour toutes les humeurs, et des plumes pour les jours de fête. Vous avez {pieces} pièces. Tournez-vous !", {}, "rire")],
			}},
		{"id": "hilda_pp", "nom": "Hilda Enclume", "titre": "forgeronne de la Forge du Marteau-Pilon", "maison": "porte_forge", "village": "perchee",
			"agenda": [[6, 18, "devant_forge"], [18, 22, "comptoir_forge"], [22, 6, "maison"]],
			"azur": {"cheveux": BLOND, "coiffure": "tresse", "yeux": Y_BLEU, "haut": [0.75, 0.72, 0.65], "tablier": [0.25, 0.16, 0.1], "foulard": [0.6, 0.1, 0.08], "taille": 1.14, "carrure": 1.45},
			"teinte": PEAU[1], "mj": {"tenue": "forgeron", "objet": "marteau"},
			"humeur_base": 0.6, "traits": {"bavard": 0.3, "humour": 0.6, "curiosite": 0.4, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"minerai_fer": 2.5, "haricots_ranch": 2.0, "salsepareille": 1.5, "coeur_magma": 2.5}, "deteste": {"gelee_slime": -1.5},
			"tics": ["BANG.", "Hm.", "Solide.", "Ça tiendra."],
			"surnoms": [[0, "maigrichon"], [25, "costaud"], [50, "mon marteau"], [75, "mon enclume"], [95, "ma forge"]],
			"boutique": {"vend": {"pelle": 8, "hache": 14, "canne_peche": 12, "boulon": 1}, "achete": {"minerai_fer": 3, "boulon": 1, "vieille_botte": 1, "obsidienne": 4, "coeur_magma": 15}},
			"repliques": {
				"accueil": [
					L("Hm. Hilda. Forgeronne. Le marteau-pilon, là, derrière, c'est moi qui l'ai construit. Il tape à ma place quand je bois ma salsepareille. BANG. Voilà, il vous a salué.", {"visites_max": 1}),
					L("{surnom}. Bien. Assieds-toi sur l'enclume, elle ne mord pas.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Bonne. J'ai forgé une ancre pour Marius, à la Chaîne. Il voulait une ancre pour une île qui flotte. Je n'ai pas posé de questions.", {}),
					L("Le soir, je laisse refroidir la forge et je reste à côté. Le fer qui refroidit chante. Un petit « tic, tic ». Gédéon dit que c'est de la physique. Moi, je dis qu'il est content.", {"soir": true}),
				],
				"lui": [
					L("Je viens du nord, d'un pays de neige. Là-bas, on forge les épées des chevaliers. Ici, je forge les fers des chevaux, les cercles des tonneaux et les jetons de cuivre des tables de jeu. C'est moins glorieux. C'est plus utile.", {}),
					L("Grand-Dé dit qu'il m'a laissée gagner au bras de fer. Il dit ça à tout le monde. Moi, je ne dis rien. Je souris. Ça l'énerve davantage.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Du minerai de fer, apporte-m'en. Il y en a dans les rochers, au pied des mesas. Je paie comptant.", {}),
					L("Les cages des Pierres-de-Ciel, sous l'île, c'est l'œuvre de ma grand-mère. Chaque printemps, je descends les vérifier. Au bout d'une corde. Avec mon marteau. BANG, BANG. Tout tient.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Bartholomé a peur de son propre chien. Si. Quand Banco aboie deux fois, il se cache derrière le comptoir.", {}, "rire"),
					L("La Shérif est venue faire redresser sa cuirasse. Une bosse, là, sur le ventre. Elle a dit : « Le comptoir. » Je n'ai pas posé de questions.", {}, "rire"),
				],
				"interpelle": [L("Hm. Toi. Besoin d'outils ?", {"visites_max": 0}), L("{surnom}. BANG.", {"visites_min": 1}, "salut")],
				"boutique": [L("Pelles, haches, cannes. Solides. Tu as {pieces} pièces.", {})],
			}},
		{"id": "rosemonde_pp", "nom": "Rosemonde Confiture", "titre": "épicière de Clous & Confitures", "maison": "porte_epicerie", "village": "perchee",
			"agenda": [[7, 19, "devant_epicerie"], [19, 22, "chapelle"], [22, 7, "maison"]],
			"azur": {"cheveux": BRUN, "coiffure": "chignon", "yeux": Y_BRUN, "robe": [0.6, 0.25, 0.32], "haut": [0.95, 0.85, 0.8], "tablier": [0.95, 0.94, 0.88], "taille": 0.98, "carrure": 1.2},
			"teinte": PEAU[5], "mj": {"tenue": "cuisinier", "objet": "louche"},
			"humeur_base": 0.75, "traits": {"bavard": 0.9, "humour": 0.8, "curiosite": 0.8, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"miel": 2.5, "pomme": 1.5, "baies": 2.0, "fraise_geante": 2.5, "dattes": 1.5}, "deteste": {"gelee_slime": -2.0},
			"tics": ["Mon sucre !", "Goûte !", "Ça colle, c'est bon signe.", "Hmmm !"],
			"surnoms": [[0, "mon sucre"], [25, "ma confiture"], [50, "mon caramel"], [75, "ma praline"], [95, "mon pot de miel"]],
			"boutique": {"vend": {"pain_miel": 4, "miel": 4, "pomme": 1, "baies": 1, "haricots_ranch": 5, "tarte_figue": 6, "salsepareille": 3, "jus_pomme": 3}, "achete": {"pomme": 1, "baies": 1, "miel": 4, "champignon": 2, "fraise_geante": 3, "truffe": 9}},
			"repliques": {
				"accueil": [
					L("Entre, mon sucre ! Rosemonde Confiture. Oui, c'est mon vrai nom. Et la boutique s'appelle « Clous & Confitures » parce que ma voisine, la Veuve Clou, vend les clous. Moi, je vends tout le reste. Surtout ce qui colle.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Goûte ma nouvelle confiture ! Figue de Barbarie et piment doux. Ça pique, puis ça console.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Délicieuse ! Comme ma tarte. J'ai cueilli des figues de Barbarie sur la terre rouge, ce matin. Trois épines dans le pouce. Rien du tout. Ça fait partie de la recette.", {}, "rire"),
					L("Le soir, je vais à la chapelle allumer une bougie pour tous ceux qui ont perdu au jeu. Il en faut beaucoup, des bougies, à Pile-ou-Face.", {"soir": true}),
				],
				"lui": [
					L("Mes haricots du ranch mijotent trois jours dans le pot de fonte de ma mère, avec du sirop d'érable et une feuille de laurier. Les cow-boys en mangent avant de jouer. Ils disent que ça porte chance. Moi, je dis que ça tient au ventre.", {}),
					L("La salsepareille, c'est une boisson de racines, pétillante, sucrée, un peu amère. Pas d'alcool : la Shérif goûte chaque tonneau. Elle en goûte même beaucoup.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Près de l'Abreuvoir, les cotonniers perdent leur coton au printemps. Toute la prairie devient blanche, comme une neige qui ne fond pas. Les enfants font des bonshommes de coton.", {}),
					L("Si tu trouves des baies, des pommes, du miel, apporte-les-moi. J'en fais des confitures, et tu en auras un pot.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Pistache, le petit crieur, c'est mon neveu. Il dit que mes tartes sont « la deuxième meilleure nouvelle de la journée ». Je voudrais bien savoir quelle est la première.", {}, "rire"),
					L("Zoé, l'aviatrice, achète chaque matin un pot de confiture de lait. Elle dit que c'est pour le moteur de la Navette. Je ne la crois pas. Le moteur n'a pas de cuillère.", {}, "rire"),
				],
				"interpelle": [L("Hé, mon sucre ! Viens goûter !", {"visites_max": 0}, "salut"), L("{surnom} ! J'ai une tarte qui t'attend !", {"visites_min": 1}, "rire")],
				"boutique": [L("Haricots du ranch, tarte aux figues, salsepareille, pain au miel… Goûte d'abord ! Tu as {pieces} pièces.", {}, "rire")],
			}},
		{"id": "pistache_pp", "nom": "Pistache", "titre": "crieur du « Courrier Perché »", "maison": "porte_m_ps_1", "village": "perchee", "enfant": true,
			"agenda": [[7, 12, "place_roue"], [12, 16, "tableau"], [16, 20, "devant_poste"], [20, 7, "maison"]],
			"azur": {"cheveux": ROUX, "coiffure": "court", "yeux": Y_VERT, "chapeau": "casquette", "chapeau_c": [0.4, 0.3, 0.2], "haut": [0.85, 0.82, 0.72], "taille": 0.72, "carrure": 0.8},
			"teinte": PEAU[0], "mj": {"tenue": "enfant"},
			"humeur_base": 0.9, "traits": {"bavard": 1.0, "humour": 0.9, "curiosite": 1.0, "susceptible": 0.2, "rancunier": 0.0},
			"aime": {"chouquettes": 2.5, "tarte_figue": 2.0, "salsepareille": 2.0, "cerf_volant": 2.0, "chocolat_chaud": 2.0}, "deteste": {"tisane_lune": -0.5},
			"tics": ["Demandez le Courrier !", "Extra ! Extra !", "Scoop !", "C'est dans le journal !"],
			"surnoms": [[0, "m'sieur-dame"], [25, "lecteur"], [50, "mon abonné"], [75, "mon informateur"], [95, "mon rédacteur en chef"]],
			"repliques": {
				"accueil": [
					L("Demandez le Courrier Perché ! Un sou le numéro ! Extra, extra : un voyageur arrive à Pile-ou-Face ! … C'est vous. Vous êtes en première page. Je m'appelle Pistache. Je suis le crieur. Et le journaliste. Et l'imprimeur. J'ai dix ans.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Scoop ! Vous êtes revenu ! Je le savais, je l'avais écrit hier.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Génial ! Aujourd'hui, dans le Courrier : « La Roue a failli s'arrêter ! » Bon, elle ne s'est pas arrêtée. Mais elle a failli. C'est quand même une nouvelle.", {}, "rire"),
					L("Le soir, je vais devant la poste écouter le télégraphe. Ça fait tic-tic-tac. Ernest, le télégraphiste, m'apprend à lire les messages. Hier, j'ai lu : « Arrivée navette. Stop. Apportez parapluie. Stop. » Il pleuvait des nuages.", {"soir": true}),
				],
				"lui": [
					L("Plus tard, je veux être maître du jeu. Le plus grand ! Celui qui ne perd jamais, parce qu'il sait quand s'arrêter. La Shérif dit que c'est le secret. Pour l'instant, je m'entraîne aux billes. Je ne sais pas encore m'arrêter.", {}, "rire"),
					L("Ma tante Rosemonde dit que je suis trop curieux. Moi, je dis que les journaux, c'est fait pour ça. Si personne n'était curieux, il n'y aurait que des pages blanches.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Exclusif ! Bientôt, les grandes tables de jeu ouvrent ! Les dés à la Fosse, le blackjack au Tripot, le poker au Saloon… et peut-être ailleurs, en secret. Vous lirez tout dans le Courrier.", {}, "rire"),
					L("Vous avez vu la Chute de l'Orpailleur ? Elle tombe jusqu'à la mer ! Un jour, j'ai jeté une bouteille avec un message dedans. Un pêcheur de Hautefond l'a trouvée. Il m'a répondu : « Arrête de jeter des bouteilles. »", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Scoop : Madame Pique a un chat ! Noir. Il s'appelle As. Il s'assoit sur les cartes pendant qu'elle joue. Personne n'ose le déranger.", {}, "rire"),
					L("Scoop : Grand-Dé a perdu une partie de dés contre Banco, le chien du saloon. Il dit que le chien a triché. La Shérif enquête. Le chien a un alibi : il dormait.", {}, "rire"),
				],
				"interpelle": [L("Extra, extra ! Demandez le Courrier !", {"visites_max": 0}, "salut"), L("{surnom} ! Scoop !", {"visites_min": 1}, "rire")],
			}},
		# ================================================================ les accès
		{"id": "maillon_pp", "nom": "Marius Maillon", "titre": "gardien de la Grande Chaîne", "maison": "porte_m_ps_3", "village": "perchee",
			"agenda": [[6, 22, "potence_quai"], [22, 6, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "court", "barbe": "longue", "yeux": Y_GRIS, "chapeau": "marin", "chapeau_c": [0.14, 0.18, 0.3], "haut": [0.2, 0.24, 0.36], "taille": 0.95, "carrure": 1.2},
			"teinte": PEAU[2], "mj": {"tenue": "marin"},
			"humeur_base": 0.5, "traits": {"bavard": 0.5, "humour": 0.6, "curiosite": 0.4, "susceptible": 0.6, "rancunier": 0.3},
			"aime": {"sardines_grillees": 2.0, "cafe_vapeur": 2.0, "corde_chanvre": 1.5, "boulon": 1.0}, "deteste": {"gelee_slime": -1.0},
			"tics": ["Neuf mille quatre cent douze.", "Accrochez-vous.", "Ça grince, c'est bon.", "Mille sabords."],
			"surnoms": [[0, "moussaillon"], [25, "passager"], [50, "matelot"], [75, "maître d'équipage"], [95, "mon second"]],
			"repliques": {
				"accueil": [
					L("Bienvenue à la Potence, moussaillon. Marius Maillon, gardien de la Grande Chaîne. La cage descend jusqu'à la mer, deux cent soixante-dix mètres. Et elle remonte. En général.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Tu montes, tu descends ? Les deux, ça se fait aussi.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Bonne. J'ai recompté les maillons ce matin : neuf mille quatre cent douze. Gédéon dit neuf mille quatre cent treize. Il compte le crochet. Le crochet n'est pas un maillon. C'est un crochet.", {}),
					L("Quand le vent souffle, la chaîne chante. Une note longue, très grave. Les baleines, en bas, lui répondent. Je ne mens pas. Demande au Ponton.", {}),
				],
				"lui": [
					L("J'étais marin, avant. Puis j'ai vu cette île passer au-dessus de mon bateau. Une île dans le ciel ! Je me suis dit : il faut un marin, là-haut. Quelqu'un qui connaît les cordages. Et me voilà, au bout d'une chaîne.", {}),
					L("En bas, sur le Ponton de la Chaîne, tu peux amarrer ta barque. Elle t'attendra. Les mouettes la surveillent. Elles ne la volent pas : elles n'ont pas de mains.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("La cage attend une dizaine de secondes, grille ouverte, puis elle part. Monte dedans, assieds-toi sur la banquette, et regarde la mer s'éloigner. Ou se rapprocher. Ça dépend dans quel sens tu vas.", {}),
					L("Il y a deux cages : quand l'une monte, l'autre descend. Elles se croisent à mi-chemin et se font un petit salut. Je les ai peintes en face pour qu'elles se reconnaissent.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Zoé, la pilote de la Navette, dit que son dirigeable est plus rapide que ma chaîne. Plus rapide, peut-être. Plus solide, sûrement pas.", {}),
					L("Hilda m'a forgé une ancre. Pour quoi faire, sur une île qui flotte ? Pour le jour où elle voudra s'en aller, pardi.", {}, "rire"),
				],
				"interpelle": [L("Ohé, moussaillon ! La cage part bientôt !", {"visites_max": 0}, "salut"), L("{surnom} ! Accroche-toi !", {"visites_min": 1}, "rire")],
			}},
		{"id": "zoe_pp", "nom": "Zoé Nuée", "titre": "aviatrice de la Navette des Nuées", "maison": "porte_hotel", "village": "perchee",
			"agenda": [[7, 21, "quai_kiosque"], [21, 7, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "court", "yeux": Y_BRUN, "chapeau": "casquette", "chapeau_c": [0.4, 0.26, 0.14], "haut": [0.45, 0.3, 0.18], "foulard": [0.95, 0.94, 0.9], "taille": 1.0},
			"teinte": PEAU[4], "mj": {"tenue": "aventurier"},
			"humeur_base": 0.8, "traits": {"bavard": 0.8, "humour": 0.8, "curiosite": 0.9, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"chocolat_chaud": 2.0, "lait_nuage": 2.5, "boussole_nuages": 2.5, "plume_vent": 2.0}, "deteste": {"gelee_slime": -1.0},
			"tics": ["Contact !", "Plein gaz !", "Vent arrière !", "On décolle !"],
			"surnoms": [[0, "terrien"], [25, "passager"], [50, "copilote"], [75, "mon navigateur"], [95, "as des nuages"]],
			"repliques": {
				"accueil": [
					L("Salut, terrien ! Zoé Nuée, pilote de la Navette des Nuées. Le gros ballon rayé, là, c'est ma Capucine. Elle fait la navette avec Hautefond, au Mât des Nuées. Monte quand elle est à quai, c'est gratuit !", {"visites_max": 1}, "salut"),
					L("{surnom} ! On décolle bientôt. Tu viens ?", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Au top ! Ce matin, on a traversé un nuage en forme de lapin. Les passagers ont applaudi. Le lapin aussi, je crois.", {}, "rire"),
					L("La nuit, je dors à l'Hôtel des Nuages, chambre douze, la plus haute. J'ai besoin de voir le ciel avant de fermer les yeux. Sinon, je rêve de terre ferme, et ça me donne le mal de mer.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Mon grand-père pilotait le Zéphyr, le dirigeable de la grande île. Il m'a appris : « Ne te bats jamais contre le vent. Fais-en ton ami. » Depuis, le vent et moi, on se tutoie.", {}),
					L("La Capucine monte à trois cents mètres, passe au-dessus de l'île et redescend sur le quai. Pendant le vol, regarde par le hublot : tu verras les mesas, la chute, et la Roue qui tourne. De là-haut, tout Pile-ou-Face ressemble à un jeu de société.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Pour monter ici, il y a ma Navette depuis Hautefond, ou la Grande Chaîne depuis la mer. Les gens pressés prennent la Navette. Les gens courageux prennent la Chaîne. Les gens très courageux prennent les deux, pour comparer.", {}, "rire"),
					L("Le Mât des Nuées, à Hautefond, est au bout d'un ponton qui avance au-dessus de la falaise du sud. La première fois, les gens ne regardent pas en bas. La deuxième fois, ils ne regardent que ça.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Marius dit que sa chaîne est plus solide que mon ballon. Je lui ai proposé une course. Il a dit : « Une course, c'est un pari. » Ici, on n'y échappe pas.", {}, "rire"),
					L("Rosemonde croit que je mets de la confiture de lait dans le moteur. N'importe quoi. Je la mange en vol. Le moteur, lui, préfère le charbon.", {}, "rire"),
				],
				"interpelle": [L("Hé, terrien ! La Navette part bientôt !", {"visites_max": 0}, "salut"), L("{surnom} ! Plein gaz ?", {"visites_min": 1}, "rire")],
			}},
	]
