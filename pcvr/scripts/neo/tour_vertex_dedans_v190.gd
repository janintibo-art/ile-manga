extends "res://scripts/neo/tour_kumo_dedans_v188.gd"
## V190 : la Tour Vertex, dedans : la banque Vertex Finances, étage par étage (onze étages, chacun de 43 m sur
## 20). Elle reprend les outils de la Tour Kumo (le repère d'un étage, les gens, les canapés, les plantes, ce qui
## bouge), et rien de son décor : ici, le marbre, le bronze, l'or, le cuir, la lumière chaude.
##   rez-de-chaussée : la salle des guichets et la salle des coffres ; 1er : les conseillers ;
##   2e : le restaurant « La Corbeille » ; 3e : la salle des marchés ; 4e : la comptabilité ;
##   5e : le grand livre (les serveurs) ; 6e : la sécurité ; 7e : l'orangerie ; 8e : le club ;
##   9e : l'atelier des pièces ; 10e : la direction.
## Les murs de chaque étage reprennent la façade du dehors (tour_vertex_v189.gd) : les grandes baies de la
## colonnade, les portes de bronze, les deux vitres par travée et leur lame d'or, la loge du jardin d'hiver,
## la terrasse de la direction.

const FAITS9 := {0: "guichets", 1: "conseillers", 2: "corbeille", 3: "marches", 4: "compta", 5: "livre", 6: "securite", 7: "orangerie", 8: "club", 9: "atelier", 10: "direction9"}
const NOMS9 := {0: "la salle des guichets", 1: "les conseillers", 2: "le restaurant « La Corbeille »", 3: "la salle des marchés", 4: "la comptabilité",
	5: "le grand livre (les serveurs)", 6: "la sécurité", 7: "l'orangerie", 8: "le club", 9: "l'atelier des pièces", 10: "la direction"}
const L_CAISSE := ["Vertex Finances, bonjour. Dépôt, retrait, ou simple admiration ?", "Guichet suivant. Non, celui-ci est fermé : il réfléchit.", "Votre solde est de douze pièces. C'est un début. C'est toujours un début.",
	"Nous gardons votre argent mieux que vous. C'est écrit sur la porte. En or."]
const L_ACCUEIL9 := ["Bienvenue chez Vertex Finances. La salle des coffres est au fond. On regarde, on ne touche pas.", "L'ascenseur est derrière moi. La fortune aussi, dit-on."]
const L_CLIENT9 := ["Je viens déposer trois pièces. Ils m'ont offert un café. Je crois que je suis riche.", "La tirelire d'or, là-bas ? On dit qu'elle est pleine. Personne n'a la clé.",
	"Mon grand-père avait un compte ici. Il lui manque un centime depuis 2091.", "Chez Kumo on livre en vingt minutes. Ici on vous rend la monnaie en vingt jours."]
const L_GARDE := ["SURVEILLANCE. TOUT EST CALME. C'EST SUSPECT.", "CIRCULEZ. LENTEMENT. AVEC ÉLÉGANCE.", "LA PORTE PÈSE NEUF TONNES. JE LA TROUVE LÉGÈRE."]
const L_COFFRES := ["Quatre cents coffres. Dans le 217, il y a un sandwich. Depuis longtemps.", "Les lingots ? On peut regarder. On peut même soupirer.", "La porte ronde ferme à dix-huit heures. Elle n'attend personne."]
const L_TRADER := ["J'ACHÈTE ! Non. JE VENDS ! Non. J'attends. C'est un métier.", "Le pigeon monte de douze points. Ne me demandez pas pourquoi.", "Les nouilles sont en hausse. Kumo en mange trop.",
	"Quand la cloche sonne, tout le monde crie. Personne ne sait ce que ça change.", "J'ai six écrans. Cinq affichent la même chose. Le sixième, la météo.", "Parapluies en baisse : il fait beau. Je suis ruiné."]
const L_CHEF_MARCHES := ["Bienvenue à la salle des marchés. Ne dites pas « krach » trop fort.", "Ici, le temps, c'est de l'argent. Asseyez-vous, ça coûte moins cher."]
const L_ORANGERIE := ["Ces orangers ont cent ans. Ils rapportent plus que la salle des marchés.", "On vient ici pour oublier les chiffres. Il y en a quand même sur les étiquettes.", "La fontaine ? De l'eau. Simplement de l'eau. J'ai vérifié.",
	"Une orange par employé et par jour. C'est dans le contrat. Page douze."]
const L_VERTEX := ["Monsieur Vertex. Je vous écoute. Trente secondes : le temps, vous savez.", "Vous voyez la tour d'en face ? Des drones. Ça passe devant ma fenêtre toute la journée. J'ai acheté une longue-vue.",
	"Mon arrière-grand-père a ouvert cette banque avec une pièce. Nous l'avons toujours. Elle est au coffre.", "Madame Kumo livre plus vite. Moi, je compte mieux."]
const L_SECRETAIRE9 := ["Monsieur Vertex est en réunion. Avec lui-même. C'est la plus efficace.", "Vous avez rendez-vous ? … Dans ce cas, attendez comme tout le monde : sur un canapé à neuf cents pièces."]

const L_CONSEIL := ["Un prêt ? Bien sûr. Il me faut trois garanties, deux témoins et votre goûter.", "L'épargne, c'est simple : vous nous donnez une pièce, on vous rend la même. Plus tard.",
	"Je vous conseille de placer. Où ? Je lance la fléchette et je vous dis.", "Assurance contre les pigeons : très demandée cette année.", "Signez ici. Les petites lignes ? Personne ne les a jamais lues. Moi non plus."]
const L_CLIENT_CONSEIL := ["Je veux emprunter pour acheter un drone. Ils m'ont proposé un parapluie.", "J'attends depuis ce matin. J'ai le numéro 3. Ils en sont au 2.", "Le simulateur de prêt dit toujours non. Mais poliment."]
const L_MAITRE := ["Bienvenue à La Corbeille. Vous avez réservé ? … En 2091 ? Alors votre table est prête.", "Le plat du jour : le filet d'or. C'est du poisson. Le nom fait monter le prix."]
const L_CORBEILLE := ["L'addition fait trois mètres. Je la garde en souvenir.", "Le pianiste ne joue que quand les cours montent. Aujourd'hui, il joue.", "Ici, on déjeune entre gens sérieux. J'ai commandé des frites.",
	"Un restaurant dans une banque : on paie avant, pendant et après.", "Le serveur ne renverse jamais rien. Il a été programmé par un comptable."]
const L_SERVEUR9 := ["MONSIEUR EST SERVI. MADAME AUSSI. LE COMPTE EST BON.", "JE RECOMMANDE LE DESSERT. IL EST DÉJÀ SUR LA NOTE."]
const L_COMPTA := ["Il manque un centime depuis 2091. Je le cherche. Mon père le cherchait déjà.", "Deux et deux font quatre. Sauf le vendredi, on arrondit.", "La machine compte neuf cents pièces à la minute. Elle se trompe d'une. On ne sait pas laquelle.",
	"Je porte une visière verte. C'est obligatoire. Personne ne sait pourquoi.", "Le boulier ? En cas de panne. Il n'est jamais tombé en panne, lui."]
const L_CHEF_COMPTA := ["Bienvenue à la comptabilité. Ne respirez pas trop fort : les piles tiennent par habitude.", "Si vous trouvez un centime par terre, criez. On organise une fête."]

const L_LIVRE := ["Le Grand Livre. Chaque pièce de l'archipel y est écrite. Même celle que vous avez perdue sous le canapé.", "Les machines retiennent tout. Le livre aussi. On garde les deux : ils ne sont jamais d'accord.",
	"Chut. Ici, on ne parle pas fort : ça fait trembler les virgules.", "La plume écrit toute seule depuis 1893. Personne n'a osé lui dire d'arrêter."]
const L_TECH9 := ["Baie 12 : tout va bien. Baie 13 : on ne la regarde pas, elle est susceptible.", "Il fait frais, c'est pour les machines. Moi, j'ai un pull. Deux, en fait.", "Une sauvegarde par heure. Et une de la sauvegarde. Et une de celle-là."]
const L_SECU := ["POSTE DE SÉCURITÉ. CENT ÉCRANS. QUATRE-VINGT-DIX-NEUF MONTRENT UN COULOIR VIDE.", "LE CENTIÈME MONTRE UN PIGEON. NOUS L'AVONS À L'ŒIL.", "ALERTE NIVEAU ZÉRO. COMME HIER. COMME DEMAIN."]
const L_CHEF_SECU := ["Trente ans de maison, zéro cambriolage. Bon, une fois, quelqu'un a pris un stylo.", "Les rayons rouges ? C'est pour l'entraînement. La pièce, au bout, est en chocolat.", "Médor 3000 dort. Ne le réveillez pas : il veut jouer, et il pèse deux cents kilos."]
const L_CONFISQUE := ["Objets confisqués : une fausse moustache, un pistolet à eau, un grappin. Le grappin, c'était le facteur.", "Chaque objet a son étiquette. Chaque étiquette a son étiquette."]
const L_CLUB := ["Le club. On y entre sur recommandation. Ou par l'ascenseur, visiblement.", "Je lis le même journal depuis une semaine. Les nouvelles sont meilleures quand on les connaît.", "Chut… Sir Édouard dort. Depuis mardi.",
	"Au billard, on joue des fortunes. Hier, j'ai perdu un trombone.", "Le feu ne s'éteint jamais. On ne sait pas qui met les bûches.", "Une partie d'échecs commencée en 2101. C'est à lui de jouer."]
const L_MAJORDOME := ["MONSIEUR DÉSIRE-T-IL UN THÉ ? UN FAUTEUIL ? UN SILENCE ?", "LE CLUB RAPPELLE À SES MEMBRES QUE RONFLER EST TOLÉRÉ, PAS ENCOURAGÉ."]
const L_ATELIER := ["Ici, on frappe la monnaie de l'archipel. Une pièce toutes les deux secondes. Bouchez-vous les oreilles.", "L'or fond à mille degrés. Mon sandwich aussi, je l'ai posé trop près.", "Chaque pièce est pesée. Trop lourde : on la refond. Trop légère : on la refond. Parfaite : on s'étonne.",
	"Le polissage, c'est le meilleur poste. On voit sa tête dans chaque pièce.", "Une pièce ratée ? Jamais. On dit : une pièce de collection."]
const L_GRAVEUR := ["Je grave le modèle. Un an pour une face. Le pigeon de la pièce de deux, c'est moi. Il a posé.", "Regardez la grande : c'est la même que dans votre poche, en plus sincère."]

var _f_nt: int = 0


static func fait(k: int) -> bool:
	return FAITS9.has(k)


static func nom(k: int) -> String:
	return str(NOMS9.get(k, ""))


func etage(tours: Node, lot: Kit.Batch, r: RandomNumberGenerator, t: Dictionary, k: int) -> String:
	_debut(tours, lot, r, t)
	match str(FAITS9.get(k, "")):
		"guichets":
			return _guichets()
		"marches":
			return _marches()
		"orangerie":
			return _orangerie()
		"direction9":
			return _direction9()
		"conseillers":
			return _conseillers()
		"corbeille":
			return _corbeille()
		"compta":
			return _compta()
		"livre":
			return _livre()
		"securite":
			return _securite()
		"club":
			return _club()
		"atelier":
			return _atelier()
	return ""


# =================================================================== les murs (ils reprennent la façade du dehors)

func facade(tours: Node, lot: Kit.Batch, a: Vector3, c: Vector3, dedans: Vector3, h: float, k: int, sorte: String) -> void:
	T = tours
	b = lot
	var L: float = a.distance_to(c)
	var u: Vector3 = (c - a).normalized()
	var long_x: bool = absf(u.x) > 0.5
	var nord: bool = dedans.z > 0.5
	var est: bool = dedans.x < -0.5
	var ouest: bool = dedans.x > 0.5
	var mb := func(key: String, s0: float, s1: float, h0: float, h1: float, t0: float, t1: float, col: bool) -> void:
		var at: Vector3 = a + u * ((s0 + s1) * 0.5) + dedans * ((t0 + t1) * 0.5) + Vector3.UP * ((h0 + h1) * 0.5)
		var sz := Vector3(absf(s1 - s0), absf(h1 - h0), absf(t1 - t0)) if long_x else Vector3(absf(t1 - t0), absf(h1 - h0), absf(s1 - s0))
		T._boite(b, key, at, sz, col)
	var nt: int = 11 if long_x else 5
	var Le: float = L + 0.6
	var mur_col := func() -> void:
		T._col(a + u * (L * 0.5) + dedans * 0.1 + Vector3.UP * (h * 0.5), Vector3(L, h, 0.3) if long_x else Vector3(0.3, h, L))
	# ---- la direction : le vitrage en retrait, la terrasse (on y sort, au nord, face à la mer)
	if k == 10:
		T._col(a + u * (L * 0.5) - dedans * 0.05 + Vector3.UP * 0.6, Vector3(L, 1.2, 0.12) if long_x else Vector3(0.12, 1.2, L))
		mb.call("k189_pierre_sombre", 0.0, L, -0.02, 0.012, 0.0, 1.4, false)
		mb.call("k189_bronze", 1.4, L - 1.4, h - 0.3, h, 1.34, 1.46, false)
		for i in range(nt + 1):
			var sb: float = clampf(Le * i / float(nt) - 0.3, 1.4, L - 1.4)
			mb.call("k189_bronze", sb - 0.06, sb + 0.06, 0.0, h - 0.3, 1.34, 1.46, true)
		for i2 in range(nt):
			var s0: float = clampf(Le * i2 / float(nt) - 0.3, 1.4, L - 1.4) + 0.06
			var s1: float = clampf(Le * (i2 + 1) / float(nt) - 0.3, 1.4, L - 1.4) - 0.06
			if nord and (i2 == 3 or i2 == 7):
				continue                          # (deux portes ouvertes sur la terrasse)
			mb.call("in_vitre", s0, s1, 0.0, h - 0.3, 1.38, 1.42, true)
		return
	# ---- le grand livre (les serveurs) : un mur plein
	if sorte == "serveurs":
		mb.call("in_mur_gris", 0.0, L, 0.0, h, 0.0, 0.2, false)
		for hh in [0.5, 2.6]:
			mb.call("k189_bronze", 0.3, L - 0.3, hh, hh + 0.08, 0.2, 0.34, false)
		mur_col.call()
		return
	# ---- le rez-de-chaussée, à l'ouest et au sud : des murs de pierre (dehors, les guichets automatiques, la ruelle)
	if k == 0 and not nord and not est:
		mb.call("k189_pierre", 0.0, L, 0.0, h, 0.0, 0.2, false)
		mb.call("k189_pierre_sombre", 0.0, L, 0.0, 0.9, 0.2, 0.26, false)
		mb.call("k189_or", 0.0, L, 0.9, 0.94, 0.2, 0.28, false)
		if ouest:
			for i3 in range(1, 4):                # (l'envers des guichets automatiques : trois portes de service)
				var m3: float = Le * (i3 + 0.5) / 5.0 - 0.3
				mb.call("k189_bronze", m3 - 0.55, m3 + 0.55, 0.0, 2.2, 0.2, 0.27, false)
				mb.call("k189_or", m3 - 0.45, m3 + 0.45, 1.5, 1.62, 0.27, 0.28, false)
				mb.call("k189_or", m3 + 0.35, m3 + 0.42, 1.0, 1.1, 0.27, 0.32, false)
		mur_col.call()
		return
	# ---- les piles de pierre, à chaque travée
	for i4 in range(nt + 1):
		var sp: float = Le * i4 / float(nt) - 0.3
		mb.call("k189_pierre", clampf(sp - 0.3, 0.0, L), clampf(sp + 0.3, 0.0, L), 0.0, h, 0.0, 0.34, false)
	for i5 in range(nt):
		var t0: float = Le * i5 / float(nt) - 0.3 + 0.3
		var t1: float = Le * (i5 + 1) / float(nt) - 0.3 - 0.3
		var m: float = (t0 + t1) * 0.5
		# la loge du jardin d'hiver (7e et 8e, au milieu du quai) : le vitrage en retrait ; au 7e, ses arbres
		if nord and (k == 7 or k == 8) and i5 >= 4 and i5 <= 6:
			mb.call("in_vitre", t0 - 0.3, t1 + 0.3, 0.0, h, 2.58, 2.62, true)
			mb.call("k189_bronze", t0 - 0.36, t0 - 0.24, 0.0, h, 2.54, 2.66, false)
			mb.call("k189_bronze", t1 + 0.24, t1 + 0.36, 0.0, h, 2.54, 2.66, false)
			var pied: Vector3 = a + u * m + dedans * 1.3
			if k == 7:
				mb.call("bois", t0 - 0.3, t1 + 0.3, -0.02, 0.06, 0.0, 2.58, false)
				mb.call("k189_pierre_sombre", t0 + 0.1, t1 - 0.1, 0.06, 0.5, 0.7, 1.9, false)
				_vegetal(Flora.tree(1890 + i5, 7.0, 260), pied + Vector3.UP * 0.5, Vector3(0.75, 0.72, 0.75), i5 * 1.7)
				_vegetal(Flora.bush(1893 + i5), a + u * (t0 + 0.6) + dedans * 1.0 + Vector3.UP * 0.5, Vector3(0.7, 0.7, 0.7), 0.4)
				_vegetal(Flora.bush(1896 + i5), a + u * (t1 - 0.6) + dedans * 1.5 + Vector3.UP * 0.5, Vector3(0.6, 0.6, 0.6), 1.9)
			else:
				_vegetal(Flora.tree(1890 + i5, 7.0, 260), pied + Vector3.UP * (0.5 - h), Vector3(0.75, 0.72, 0.75), i5 * 1.7)
			if i5 == 4:
				mb.call("in_vitre", t0 - 0.32, t0 - 0.28, 0.0, h, 0.34, 2.6, true)
			if i5 == 6:
				mb.call("in_vitre", t1 + 0.28, t1 + 0.32, 0.0, h, 0.34, 2.6, true)
			continue
		if k == 0:
			# la colonnade : la grande baie (ou, à l'est, au milieu, les deux portes de bronze)
			if est and i5 == 2:
				mb.call("k189_pierre", t0, t1, h - 0.5, h, 0.0, 0.3, false)
				for sg in [-1.0, 1.0]:
					mb.call("k189_bronze", m + sg * 0.02, m + sg * 1.72, 0.0, h - 0.5, 0.06, 0.16, false)
					for hh2 in [0.4, 1.6]:
						mb.call("k189_or", m + sg * 0.25, m + sg * 1.5, hh2, hh2 + 1.0, 0.16, 0.175, false)
						mb.call("k189_bronze", m + sg * 0.33, m + sg * 1.42, hh2 + 0.08, hh2 + 0.92, 0.175, 0.19, false)
					mb.call("k189_or", m + sg * 0.1, m + sg * 0.16, 1.05, 1.35, 0.16, 0.24, false)
				continue
			mb.call("k189_pierre_sombre", t0, t1, 0.0, 0.9, 0.0, 0.26, false)
			mb.call("k189_bronze", t0, t1, 0.9, 0.96, 0.0, 0.3, false)
			mb.call("in_vitre", t0, t1, 0.96, h, 0.1, 0.13, false)
			mb.call("k189_bronze", m - 0.04, m + 0.04, 0.96, h, 0.06, 0.18, false)
			mb.call("k189_bronze", t0, t1, 2.66, 2.74, 0.06, 0.18, false)
			continue
		if k == 1 and (nord or est):
			# le haut des grandes baies : le verre depuis le sol, le linteau de pierre
			mb.call("in_vitre", t0, t1, 0.0, 1.93, 0.1, 0.13, false)
			mb.call("k189_bronze", m - 0.04, m + 0.04, 0.0, 1.93, 0.06, 0.18, false)
			mb.call("k189_bronze", t0, t1, 1.0, 1.05, 0.14, 0.2, false)
			mb.call("k189_pierre", t0, t1, 1.93, h, 0.0, 0.26, false)
			continue
		# un étage courant : l'allège, deux vitres, la lame d'or entre elles
		mb.call("in_mur", t0, t1, 0.0, 0.95, 0.0, 0.2, false)
		mb.call("k189_bronze", t0, t1, 0.95, 1.0, 0.0, 0.27, false)
		mb.call("in_vitre", t0, t1, 1.0, h, 0.08, 0.11, false)
		mb.call("k189_or", m - 0.05, m + 0.05, 1.0, h, 0.02, 0.16, false)
	mur_col.call()


# =================================================================== ce qui sert à plusieurs étages de la banque

func _coeur() -> Array:
	var core: Rect2 = T.info["core"]
	return [core.position.x - X0, core.end.x - X0, core.position.y - Z0, core.end.y - Z0]


## Un sol posé sur celui de l'étage (du marbre, un parquet), partout sauf dans le cœur.
func _sol(key: String) -> void:
	var q: Array = _coeur()
	_bx(key, 0.0, W, 0.0, 0.012, 0.0, float(q[2]))
	_bx(key, 0.0, W, 0.0, 0.012, float(q[3]), D)
	_bx(key, 0.0, float(q[0]), 0.0, 0.012, float(q[2]), float(q[3]))
	_bx(key, float(q[1]), W, 0.0, 0.012, float(q[2]), float(q[3]))


## Le plafond de la banque : un enduit clair (il cache les dalles de bureau), des poutres de bronze.
func _plafond(key: String = "k189_pierre", poutres: bool = true) -> void:
	var q: Array = _coeur()
	_bx(key, 0.3, W - 0.3, hc - 0.05, hc - 0.03, 0.3, D - 0.3)
	if not poutres:
		return
	var px: float = 4.0
	while px < W - 1.0:
		if px > float(q[0]) - 0.3 and px < float(q[1]) + 0.3:
			_bx("k189_bronze", px - 0.08, px + 0.08, hc - 0.18, hc - 0.05, 0.4, float(q[2]))
			_bx("k189_bronze", px - 0.08, px + 0.08, hc - 0.18, hc - 0.05, float(q[3]), D - 0.4)
		else:
			_bx("k189_bronze", px - 0.08, px + 0.08, hc - 0.18, hc - 0.05, 0.4, D - 0.4)
		px += 4.0
	for lz2 in [float(q[2]) - 0.9, float(q[3]) + 0.9]:
		_bx("k189_bronze", 0.4, W - 0.4, hc - 0.22, hc - 0.05, lz2 - 0.08, lz2 + 0.08)
	# (les dalles lumineuses sont cachées : des pastilles de lumière dans l'enduit)
	var lx: float = 2.0
	while lx < W - 1.0:
		for lz in [2.6, D - 2.6]:
			b.cyl_at("lampe_chaude", _p(lx, hc - 0.062, lz), 0.14, 0.14, 0.012, 12)
			b.cyl_at("k189_or", _p(lx, hc - 0.066, lz), 0.18, 0.18, 0.014, 12)
		lx += 4.0


## Les piliers de la tour deviennent des colonnes rondes : la pierre, le socle sombre, le chapiteau d'or.
func _colonnes(or_seul: bool = false) -> void:
	for p in T.info.get("piliers", []):
		var at := Vector3((p as Vector2).x, y, (p as Vector2).y)
		b.cyl_at("k189_pierre_sombre", at, 0.52, 0.52, 0.25, 18)
		b.cyl_at("k189_or" if or_seul else "k189_pierre", at + Vector3.UP * 0.25, 0.42, 0.42, hc - 0.6, 18)
		b.cyl_at("k189_or", at + Vector3.UP * (hc - 0.35), 0.42, 0.55, 0.12, 18)
		b.cyl_at("k189_pierre", at + Vector3.UP * (hc - 0.23), 0.56, 0.56, 0.23, 18)


## Un lustre : la tige, deux cercles de bronze, leurs ampoules.
func _lustre(lx: float, lz: float, r: float = 0.9) -> void:
	b.cyl_at("k189_bronze", _p(lx, hc - 0.55, lz), 0.02, 0.02, 0.55, 6)
	for q in [[r, hc - 0.62, 12], [r * 0.55, hc - 0.45, 8]]:
		var n: int = q[2]
		for i in range(n):
			var a0: float = i * TAU / n
			var a1: float = (i + 1) * TAU / n
			b.tube("k189_or", _p(lx + cos(a0) * float(q[0]), float(q[1]), lz + sin(a0) * float(q[0])), _p(lx + cos(a1) * float(q[0]), float(q[1]), lz + sin(a1) * float(q[0])), 0.02, 5)
			b.blob("lampe_chaude", _p(lx + cos(a0) * float(q[0]), float(q[1]) + 0.07, lz + sin(a0) * float(q[0])), Vector3(0.045, 0.06, 0.045), 6)
		for j in range(4):
			b.tube("k189_bronze", _p(lx, float(q[1]) + 0.2, lz), _p(lx + cos(j * TAU / 4.0) * float(q[0]), float(q[1]), lz + sin(j * TAU / 4.0) * float(q[0])), 0.008, 4)
	var o := OmniLight3D.new()
	o.light_color = Color(1.0, 0.85, 0.6)
	o.light_energy = 1.1
	o.omni_range = 7.0
	(T.get("_node") as Node3D).add_child(o)
	o.global_position = _p(lx, hc - 0.9, lz)


## Un potelet doré (une file d'attente, un cordon devant un trésor).
func _potelet(lx: float, lz: float) -> void:
	b.cyl_at("k189_or", _p(lx, 0.0, lz), 0.13, 0.13, 0.025, 12)
	b.cyl_at("k189_or", _p(lx, 0.0, lz), 0.022, 0.022, 0.95, 8)
	b.blob("k189_or", _p(lx, 0.98, lz), Vector3(0.045, 0.045, 0.045), 6)


func _cordon(lx0: float, lz0: float, lx1: float, lz1: float) -> void:
	var m: Vector3 = (_p(lx0, 0.78, lz0) + _p(lx1, 0.78, lz1)) * 0.5
	b.tube("tissu_rouge", _p(lx0, 0.9, lz0), m, 0.022, 5)
	b.tube("tissu_rouge", m, _p(lx1, 0.9, lz1), 0.022, 5)


## Une pile de lingots (une pyramide de « n » lingots à la base).
func _lingots(lx: float, h: float, lz: float, n: int) -> void:
	var niv: int = 0
	while n - niv > 0:
		for i in range(n - niv):
			for j in range(maxi(1, n - niv - 1)):
				b.box("k189_or", Transform3D(Basis(), _p(lx + (i - (n - niv - 1) * 0.5) * 0.23, h + 0.04 + niv * 0.08, lz + (j - (maxi(1, n - niv - 1) - 1) * 0.5) * 0.12)), Vector3(0.2, 0.075, 0.1))
		niv += 1


## Un sac de pièces (la toile, le nœud, le signe de la maison).
func _sac(lx: float, h: float, lz: float, s: float = 1.0) -> void:
	b.blob("in_bois_clair", _p(lx, h + 0.16 * s, lz), Vector3(0.17, 0.17, 0.17) * s, 8)
	b.cyl_at("in_bois_clair", _p(lx, h + 0.28 * s, lz), 0.05 * s, 0.09 * s, 0.1 * s, 8)
	b.cyl_at("k189_or", _p(lx, h + 0.285 * s, lz), 0.056 * s, 0.056 * s, 0.02 * s, 8)


## Un mur de petits coffres : la plaque de bronze, les rangs, les colonnes, les serrures d'or.
func _mur_coffres(at: Vector3, face: Vector3, larg: float, haut: float) -> void:
	var bs := Basis(Vector3.UP, atan2(face.x, face.z))
	b.box("k189_bronze", Transform3D(bs, at + Vector3.UP * (haut * 0.5)), Vector3(larg, haut, 0.08))
	var nr: int = int(haut / 0.3)
	var nc: int = int(larg / 0.42)
	for r in range(nr + 1):
		b.box("metal_noir", Transform3D(bs, at + Vector3.UP * (haut * r / float(nr)) + bs * Vector3(0, 0, 0.042)), Vector3(larg, 0.015, 0.01))
	for c in range(nc + 1):
		b.box("metal_noir", Transform3D(bs, at + Vector3.UP * (haut * 0.5) + bs * Vector3(larg * (c / float(nc) - 0.5), 0, 0.042)), Vector3(0.015, haut, 0.01))
	for r2 in range(nr):
		for c2 in range(nc):
			b.box("k189_or", Transform3D(bs, at + Vector3.UP * (haut * (r2 + 0.5) / float(nr)) + bs * Vector3(larg * ((c2 + 0.5) / float(nc) - 0.5) + 0.1, 0, 0.045)), Vector3(0.035, 0.035, 0.01))


# ------------------------------------------------------------------ le rez-de-chaussée : la salle des guichets
func _guichets() -> String:
	var q: Array = _coeur()
	var cx0: float = q[0]
	var cx1: float = q[1]
	var cz0: float = q[2]
	var cz1: float = q[3]
	var cm: float = (cz0 + cz1) * 0.5
	_sol("in_marbre_blanc")
	_colonnes()
	# le tapis rouge, de la porte à l'ascenseur ; ses deux filets d'or
	_bx("tissu_rouge", cx1 + 1.7, W - 0.5, 0.012, 0.022, cm - 0.8, cm + 0.8)
	for sg in [-0.86, 0.86]:
		_bx("k189_or", cx1 + 1.7, W - 0.5, 0.012, 0.024, cm + sg - 0.03, cm + sg + 0.03)
	# le plafond à poutres de bronze, les lustres
	_plafond()
	_lustre(34.5, cm, 1.0)
	_lustre(9.5, cm, 1.0)
	_lustre(34.8, 16.4, 0.8)
	_lustre(5.5, 16.9, 0.8)
	# ---- les guichets (au nord-est) : le comptoir, la grille de bronze, les numéros, les lampes vertes
	var g0: float = cx1 + 2.6
	var ng: int = 5
	var g1: float = g0 + ng * 2.0
	_bx("in_bois", g0, g1, 0.0, 1.05, 5.6, 6.2, true)
	_bx("in_marbre_noir", g0 - 0.06, g1 + 0.06, 1.05, 1.09, 5.5, 6.3)
	_bx("k189_or", g0, g1, 0.5, 0.56, 6.2, 6.215)
	_bx("k189_bronze", g0, g1, 2.3, 2.42, 5.84, 5.96)
	for sx in [g0, g1]:
		_bx("in_bois", sx - 0.06, sx + 0.06, 0.0, 1.05, 0.4, 5.6, true)
		_bx("in_marbre_noir", sx - 0.1, sx + 0.1, 1.05, 1.09, 0.4, 5.6)
	for i in range(ng + 1):
		_bx("k189_bronze", g0 + i * 2.0 - 0.04, g0 + i * 2.0 + 0.04, 1.09, 2.3, 5.86, 5.94)
	for i2 in range(ng):
		var gx: float = g0 + i2 * 2.0 + 1.0
		var bx: float = g0 + i2 * 2.0 + 0.2
		while bx < g0 + (i2 + 1) * 2.0 - 0.1:
			if absf(bx - gx) < 0.45:
				b.cyl_at("k189_or", _p(bx, 1.75, 5.9), 0.012, 0.012, 0.55, 5)       # (au-dessus de l'ouverture)
			else:
				b.cyl_at("k189_or", _p(bx, 1.09, 5.9), 0.012, 0.012, 1.21, 5)
			bx += 0.2
		_bx("k189_bronze", gx - 0.45, gx + 0.45, 1.72, 1.76, 5.87, 5.93)
		_bx("k189_or", gx - 0.3, gx + 0.3, 2.42, 2.72, 5.87, 5.93)
		_texte(str(i2 + 1), 40, Color(0.2, 0.13, 0.05), _p(gx, 2.57, 5.94), Vector3(0, 0, 1))
		# la lampe de banquier, le sous-main, le tampon
		b.cyl_at("k189_or", _p(gx + 0.6, 1.09, 5.7), 0.06, 0.06, 0.015, 8)
		b.cyl_at("k189_or", _p(gx + 0.6, 1.09, 5.7), 0.012, 0.012, 0.26, 5)
		b.box("tissu_vert", Transform3D(Basis(), _p(gx + 0.6, 1.38, 5.7)), Vector3(0.26, 0.07, 0.12))
		b.box("lampe_chaude", Transform3D(Basis(), _p(gx + 0.6, 1.342, 5.7)), Vector3(0.22, 0.01, 0.09))
		_bx("tissu_vert", gx - 0.3, gx + 0.3, 1.09, 1.095, 5.6, 6.0)
		if i2 == 2:
			_bx("in_noir", gx - 0.35, gx + 0.35, 1.25, 1.5, 5.9, 5.93)
			_texte("FERMÉ", 22, Color(1.0, 0.8, 0.4), _p(gx, 1.38, 5.94), Vector3(0, 0, 1))
		else:
			_gens("femme" if i2 % 2 == 0 else "homme", gx, 4.95, Vector3(0, 0, 1), "comptoir", L_CAISSE, false, i2 == 0)
	# la file : deux rangs de potelets dorés, leurs cordons rouges
	for fz in [7.4, 8.8]:
		for i3 in range(5):
			_potelet(g0 + 1.0 + i3 * 2.0, fz)
			if i3 < 4:
				_cordon(g0 + 1.0 + i3 * 2.0, fz, g0 + 3.0 + i3 * 2.0, fz)
	_gens("homme", g0 + 1.0, 6.85, Vector3(0, 0, -1), "debout", L_CLIENT9, false, true)
	_gens("femme", g0 + 4.2, 8.1, Vector3(-1, 0, 0), "debout", L_CLIENT9)
	_gens("homme", g0 + 6.0, 8.1, Vector3(-1, 0, 0), "bras_croises", L_CLIENT9)
	# ---- l'accueil (près de la porte), les deux gardes
	_bx("in_bois", W - 5.4, W - 2.8, 0.0, 1.05, cm + 1.7, cm + 2.3, true)
	_bx("in_marbre_noir", W - 5.46, W - 2.74, 1.05, 1.09, cm + 1.62, cm + 2.38)
	for sv in [-1.0, 1.0]:
		b.box("k189_or", Transform3D(Basis(Vector3(0, 0, 1), -sv * 0.32), _p(W - 4.1 + sv * 0.14, 0.55, cm + 1.69)), Vector3(0.09, 0.8, 0.02))
	b.cyl_at("k189_or", _p(W - 3.2, 1.09, cm + 2.0), 0.07, 0.03, 0.05, 10)                    # (la sonnette)
	_gens("femme", W - 4.1, cm + 3.0, Vector3(0, 0, -1), "comptoir", L_ACCUEIL9, false, true)
	_gens("homme", W - 1.5, cm - 2.0, Vector3(-1, 0, 0), "bras_croises", L_GARDE, true, true)
	# ---- les pupitres (au nord-ouest, sous les fenêtres) : le plan incliné, la lampe, la plume au bout de sa chaîne
	var n_p: int = 0
	for ux in [6.5, 9.5, 14.5]:
		_bx("in_bois", ux - 0.6, ux + 0.6, 0.0, 1.0, 0.9, 1.5, true)
		b.box("tissu_vert", Transform3D(Basis(Vector3(1, 0, 0), 0.22), _p(ux, 1.07, 1.2)), Vector3(1.2, 0.03, 0.66))
		b.cyl_at("k189_or", _p(ux + 0.45, 1.12, 1.0), 0.012, 0.012, 0.3, 5)
		b.blob("lampe_chaude", _p(ux + 0.45, 1.45, 1.0), Vector3(0.06, 0.05, 0.06), 6)
		b.tube("k189_or", _p(ux - 0.45, 1.13, 1.0), _p(ux - 0.2, 1.1, 1.25), 0.004, 3)
		b.box("peinture_blanche", Transform3D(Basis(Vector3(1, 0, 0), 0.22), _p(ux + 0.05, 1.09, 1.22)), Vector3(0.22, 0.004, 0.3))
		if n_p == 1:
			_gens("femme", ux, 2.1, Vector3(0, 0, -1), "comptoir", L_CLIENT9)
		n_p += 1
	# ---- la Tirelire d'or (à l'ouest) : sur son socle, derrière son cordon, sous sa lumière
	var tx: float = 8.0
	var tz: float = 6.2
	b.cyl_at("in_marbre_noir", _p(tx, 0.0, tz), 1.0, 1.0, 0.6, 28)
	b.cyl_at("k189_or", _p(tx, 0.6, tz), 0.92, 0.92, 0.015, 28)
	T._col(_p(tx, 0.8, tz), Vector3(2.0, 1.6, 2.0))
	b.blob("k189_or", _p(tx, 1.35, tz), Vector3(0.72, 0.52, 0.5), 14)
	b.blob("k189_or", _p(tx + 0.6, 1.42, tz), Vector3(0.36, 0.36, 0.36), 12)
	b.cyl("k189_or", Transform3D(Basis(Vector3(0, 0, 1), -PI * 0.5), _p(tx + 0.98, 1.38, tz)), 0.16, 0.18, 0.14, 12)
	for sg2 in [-1.0, 1.0]:
		b.blob("metal_noir", _p(tx + 1.055, 1.38, tz + sg2 * 0.06), Vector3(0.02, 0.035, 0.025), 5)
		b.blob("metal_noir", _p(tx + 0.84, 1.56, tz + sg2 * 0.17), Vector3(0.035, 0.035, 0.035), 6)
		b.cyl_at("k189_or", _p(tx + 0.55, 1.68, tz + sg2 * 0.24), 0.11, 0.01, 0.2, 6)
		for lx2 in [-0.4, 0.4]:
			b.cyl_at("k189_or", _p(tx + lx2, 0.6, tz + sg2 * 0.28), 0.1, 0.13, 0.4, 10)
	for i4 in range(5):                                 # (la queue en tire-bouchon)
		var a0: float = i4 * 1.3
		var a1: float = (i4 + 1) * 1.3
		b.tube("k189_or", _p(tx - 0.72 - i4 * 0.05, 1.45 + cos(a0) * 0.09, tz + sin(a0) * 0.09), _p(tx - 0.77 - i4 * 0.05, 1.45 + cos(a1) * 0.09, tz + sin(a1) * 0.09), 0.025, 5)
	_bx("metal_noir", tx - 0.2, tx + 0.2, 1.84, 1.87, tz - 0.03, tz + 0.03)
	b.cyl("k189_or", Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), _p(tx, 2.0, tz)), 0.2, 0.2, 0.03, 20)
	for i5 in range(4):
		var pa: float = i5 * TAU / 4.0 + PI * 0.25
		_potelet(tx + cos(pa) * 1.75, tz + sin(pa) * 1.75)
		if i5 != 1:
			_cordon(tx + cos(pa) * 1.75, tz + sin(pa) * 1.75, tx + cos(pa + TAU / 4.0) * 1.75, tz + sin(pa + TAU / 4.0) * 1.75)
	_texte("La Tirelire d'or (1893)", 26, Color(1.0, 0.85, 0.5), _p(tx, 0.4, tz + 1.02), Vector3(0, 0, 1))
	_texte("Pleine, dit-on. Personne n'a la clé.", 16, Color(0.95, 0.92, 0.85), _p(tx, 0.24, tz + 1.02), Vector3(0, 0, 1))
	# ---- le pneumatique (contre le mur de l'ouest) : trois tubes de verre, les cartouches qui montent
	for i6 in range(3):
		var pz: float = 2.3 + i6 * 0.5
		b.cyl_at("verre", _p(0.55, 0.9, pz), 0.09, 0.09, hc - 0.9, 10)
		for hh in [0.9, 1.9, hc - 0.1]:
			b.cyl_at("k189_or", _p(0.55, hh, pz), 0.105, 0.105, 0.05, 10)
		var lotc := Kit.Batch.new()
		lotc.cyl("plastique_rouge" if i6 != 1 else "k189_or", Transform3D(Basis(), Vector3(0, 0.1, 0)), 0.065, 0.065, 0.2, 8)
		var cart := MeshInstance3D.new()
		cart.mesh = _maillage(lotc)
		_anime().add_child(cart)
		_anime().tapis.append([cart, _p(0.55, 0.95, pz), Vector3.UP, hc - 1.3, i6 * 0.37, 1.1 + i6 * 0.5])
	_bx("in_bois", 0.3, 0.9, 0.0, 0.9, 2.0, 3.6, true)
	_bx("in_marbre_noir", 0.28, 0.94, 0.9, 0.93, 1.96, 3.64)
	_texte("Le pneumatique", 22, Color(1.0, 0.85, 0.5), _p(0.92, 0.62, 2.8), Vector3(1, 0, 0))
	_texte("Votre argent voyage à quarante à l'heure.", 13, Color(0.95, 0.92, 0.85), _p(0.92, 0.42, 2.8), Vector3(1, 0, 0))
	# ---- le salon (au sud-ouest) : le tapis, les canapés de cuir, la table, les journaux, les plantes
	_bx("tissu_vert", 1.6, 9.4, 0.012, 0.022, 14.6, 19.3)
	_canape(5.5, 15.2, Vector3(0, 0, 1), 2.6)
	_canape(5.5, 18.7, Vector3(0, 0, -1), 2.6)
	_canape(2.3, 16.95, Vector3(1, 0, 0), 1.0)
	_canape(8.7, 16.95, Vector3(-1, 0, 0), 1.0)
	_bx("in_marbre_noir", 4.6, 6.4, 0.38, 0.42, 16.5, 17.4, true)
	for qq in [[4.7, 16.6], [6.3, 16.6], [4.7, 17.3], [6.3, 17.3]]:
		b.cyl_at("k189_or", _p(qq[0], 0.0, qq[1]), 0.02, 0.02, 0.38, 6)
	for i7 in range(3):
		_bx("peinture_blanche", 4.8 + i7 * 0.4, 5.1 + i7 * 0.4, 0.42, 0.43 + i7 * 0.004, 16.7, 17.1)
	_plante_pot(1.0, 14.2, 1.5)
	_plante_pot(1.0, 19.4, 1.4, true)
	_plante_pot(10.6, 19.4, 1.5)
	_gens("homme", 5.0, 15.3, Vector3(0, 0, 1), "assis", L_CLIENT9)
	_gens("femme", 6.0, 18.6, Vector3(0, 0, -1), "assis", L_CLIENT9)
	# ---- la salle des coffres (au sud, derrière le cœur) : ses murs, sa porte ronde entrouverte
	var v0: float = 14.6
	var v1: float = cx1 + 2.0
	var vn: float = cz1 + 0.5
	_bx("k189_pierre", v0, v1, 0.0, hc, cz1, vn, true)
	_bx("k189_pierre", v0, v0 + 0.3, 0.0, hc, vn, D - 0.2, true)
	_bx("k189_pierre", v1 - 0.3, v1, 0.0, hc, vn, 15.8, true)
	_bx("k189_pierre", v1 - 0.3, v1, 0.0, hc, 17.6, D - 0.2, true)
	_bx("k189_pierre", v1 - 0.3, v1, 2.45, hc, 15.8, 17.6)
	_bx("in_marbre_noir", v0 + 0.3, v1 - 0.3, 0.012, 0.024, vn, D - 0.2)
	for e in [[15.74, 15.86, 0.0, 2.45], [17.54, 17.66, 0.0, 2.45]]:
		_bx("k189_bronze", v1 - 0.36, v1 + 0.06, e[2], e[3], e[0], e[1])
	_bx("k189_bronze", v1 - 0.36, v1 + 0.06, 2.39, 2.51, 15.74, 17.66)
	_texte("SALLE DES COFFRES", 34, Color(1.0, 0.82, 0.45), _p(v1 + 0.02, 2.8, 16.7), Vector3(1, 0, 0))
	# la porte : un disque de neuf tonnes, ouvert vers la salle ; son volant, ses verrous
	var couche := Basis(Vector3(1, 0, 0), PI * 0.5)
	var pc: Vector3 = _p(v1 + 1.25, 1.25, 15.62)
	b.cyl("k189_bronze", Transform3D(couche, pc), 1.2, 1.2, 0.34, 36)
	b.cyl("metal_noir", Transform3D(couche, pc + Vector3(0, 0, 0.18)), 0.95, 0.95, 0.03, 36)
	b.cyl("k189_or", Transform3D(couche, pc + Vector3(0, 0, 0.2)), 0.6, 0.6, 0.02, 28)
	b.cyl("k189_bronze", Transform3D(couche, pc + Vector3(0, 0, 0.24)), 0.16, 0.16, 0.1, 14)
	for a in range(6):
		var dir := Vector3(cos(a * TAU / 6.0), sin(a * TAU / 6.0), 0)
		b.tube("chrome", pc + Vector3(0, 0, 0.27), pc + Vector3(0, 0, 0.27) + dir * 0.5, 0.028, 6)
		b.blob("k189_or", pc + Vector3(0, 0, 0.27) + dir * 0.53, Vector3(0.05, 0.05, 0.05), 6)
		b.cyl("chrome", Transform3D(couche, pc + Vector3(0, 0, -0.2) + dir * 1.0), 0.07, 0.07, 0.14, 8)
	_bx("k189_bronze", v1 - 0.05, v1 + 0.2, 0.3, 2.2, 15.6, 15.76)                           # (la charnière)
	T._col(pc, Vector3(2.4, 2.5, 0.5))
	_gens("homme", v1 + 1.3, 18.4, Vector3(1, 0, 0), "bras_croises", L_GARDE, true, true)
	# dedans : les murs de petits coffres, la table des lingots, les sacs, la première pièce sous sa cloche
	_mur_coffres(_p((v0 + v1) * 0.5, 0.2, vn + 0.05), Vector3(0, 0, 1), v1 - v0 - 1.0, 2.4)
	_mur_coffres(_p(v0 + 0.35, 0.2, (vn + D) * 0.5), Vector3(1, 0, 0), D - vn - 1.0, 2.4)
	_mur_coffres(_p(v0 + 2.4, 0.2, D - 0.26), Vector3(0, 0, -1), 3.4, 2.4)
	_mur_coffres(_p(v1 - 2.4, 0.2, D - 0.26), Vector3(0, 0, -1), 3.4, 2.4)
	var dm: float = W * 0.5                             # (l'envers de la porte de la ruelle, au milieu du mur du sud)
	b.cyl("k189_bronze", Transform3D(couche, _p(dm, 1.5, D - 0.3)), 1.45, 1.45, 0.14, 36)
	b.cyl("metal_noir", Transform3D(couche, _p(dm, 1.5, D - 0.4)), 1.1, 1.1, 0.03, 36)
	b.cyl("k189_or", Transform3D(couche, _p(dm, 1.5, D - 0.43)), 0.35, 0.35, 0.03, 20)
	for a2 in range(8):
		var d2 := Vector3(cos(a2 * TAU / 8.0), sin(a2 * TAU / 8.0), 0)
		b.cyl("k189_or", Transform3D(couche, _p(dm, 1.5, D - 0.4) + d2 * 1.28), 0.06, 0.06, 0.08, 8)
	var tm: float = (v0 + v1) * 0.5
	_bx("in_marbre_noir", tm - 1.5, tm + 1.5, 0.76, 0.82, 16.0, 17.3, true)
	_bx("k189_bronze", tm - 1.3, tm + 1.3, 0.0, 0.76, 16.2, 17.1)
	_lingots(tm - 0.6, 0.82, 16.65, 4)
	_lingots(tm + 0.75, 0.82, 16.4, 2)
	_lingots(tm + 0.8, 0.82, 16.95, 3)
	for i8 in range(7):
		_sac(v0 + 1.0 + (i8 % 4) * 0.42, 0.024 + (0.3 if i8 >= 4 else 0.0), 18.6 + (i8 % 2) * 0.35 + (0.15 if i8 >= 4 else 0.0), 1.0 + (i8 % 3) * 0.12)
	b.cyl_at("in_marbre_blanc", _p(v1 - 1.6, 0.0, 14.4), 0.3, 0.3, 1.0, 16)
	b.cyl_at("tissu_rouge", _p(v1 - 1.6, 1.0, 14.4), 0.26, 0.26, 0.03, 16)
	b.cyl("k189_or", Transform3D(Basis(Vector3(1, 0, 0), 1.1), _p(v1 - 1.6, 1.09, 14.4)), 0.1, 0.1, 0.012, 16)
	b.blob("verre", _p(v1 - 1.6, 1.03, 14.4), Vector3(0.28, 0.42, 0.28), 12)
	_texte("La première pièce (1893)", 16, Color(1.0, 0.85, 0.5), _p(v1 - 1.6, 0.6, 14.71), Vector3(0, 0, 1))
	T._col(_p(v1 - 1.6, 0.7, 14.4), Vector3(0.7, 1.4, 0.7))
	for vl in [tm - 3.0, tm + 3.0]:
		var o := OmniLight3D.new()
		o.light_color = Color(1.0, 0.85, 0.6)
		o.light_energy = 1.2
		o.omni_range = 6.0
		(T.get("_node") as Node3D).add_child(o)
		o.global_position = _p(vl, 2.5, 16.6)
	_gens("femme", tm + 2.6, 17.9, Vector3(-1, 0, -0.3).normalized(), "debout", L_COFFRES, false, true)
	# ---- devant la salle des coffres (au sud-est) : un canapé, les plantes
	_canape(W - 6.5, D - 1.0, Vector3(0, 0, -1), 2.6)
	_plante_pot(W - 0.9, D - 0.9, 1.5)
	_plante_pot(W - 9.0, D - 0.9, 1.3, true)
	_plante_pot(W - 0.9, 0.9, 1.4)
	T.info["sans_promeneurs"] = true                    # (on ne fait pas le tour du cœur : la salle des coffres y est adossée)
	return ""


# ------------------------------------------------------------------ le 3e : la salle des marchés
func _marches() -> String:
	var q: Array = _coeur()
	var cx0: float = q[0]
	var cx1: float = q[1]
	var cz0: float = q[2]
	var cz1: float = q[3]
	var cm: float = (cz0 + cz1) * 0.5
	var mxc: float = (cx0 + cx1) * 0.5
	_colonnes()
	# la pénombre dorée : un plafond sombre, les écrans font le reste
	for ch in (T.get("_node") as Node3D).get_children():
		if ch is OmniLight3D:
			(ch as OmniLight3D).light_energy *= 0.5
			(ch as OmniLight3D).light_color = Color(1.0, 0.85, 0.65)
	_bx("in_noir", 0.3, W - 0.3, hc - 0.09, hc - 0.07, 0.3, D - 0.3)
	# ---- les rangées de pupitres (deux au nord, deux au sud) ; au-dessus de chacune, le bandeau des cours
	var n_t: int = 0
	for rg in [[2.2, 1.0], [5.9, -1.0], [14.6, 1.0], [18.0, -1.0]]:
		var rz: float = rg[0]
		var sg: float = rg[1]
		for i in range(11):
			var px: float = 3.4 + i * 3.6
			if absf(px - 20.0) < 0.9 and rz < 7.0:
				px += 0.9                       # (le pilier du milieu)
			_poste_marche(px, rz, sg, n_t)
			var assis: bool = (n_t * 7 + 3) % 5 < 2
			if assis and n_t % 2 == 0:
				_gens("homme" if n_t % 4 == 0 else "femme", px, rz + sg * 0.8, Vector3(0, 0, -sg), "assis", L_TRADER, false, n_t == 0)
			n_t += 1
		_bx("metal_noir", 2.0, W - 2.0, 2.5, 2.92, rz - 0.06, rz + 0.06)
		_quad("k189_ticker", _p(W * 0.5, 2.71, rz - 0.065), Vector3(0, 0, -1), W - 4.2, 0.34, Vector2((W - 4.2) / 26.0, 1))
		_quad("k189_ticker", _p(W * 0.5, 2.71, rz + 0.065), Vector3(0, 0, 1), W - 4.2, 0.34, Vector2((W - 4.2) / 26.0, 1))
		var hx: float = 4.0
		while hx < W - 2.0:
			_bx("metal_noir", hx - 0.012, hx + 0.012, 2.92, hc, rz - 0.012, rz + 0.012)
			hx += 5.0
	# trois courtiers debout, au milieu de l'allée (ils crient)
	_gens("homme", 8.6, 3.9, Vector3(1, 0, 0), "debout", L_TRADER, false, true)
	_gens("femme", 31.5, 4.0, Vector3(-1, 0, 0), "bras_croises", L_TRADER)
	_gens("homme", 30.0, 16.3, Vector3(-1, 0, 0), "debout", L_TRADER, false, true)
	# ---- le grand tableau des cours (sur le cœur, au nord et au sud)
	var cours: Array = [["KUMO EXPRESS", "▲ 4,2", true], ["HIKARI SYSTÈMES", "▲ 1,6", true], ["NOUILLES (le bol)", "▲ 9,9", true], ["PARAPLUIES", "▼ 7,1", false],
		["PIGEON", "▲ 12,0", true], ["PIANOS (livrés seuls)", "▼ 0,3", false], ["THÉ AU JASMIN", "▲ 0,1", true], ["CENTIME DE 2091", "— introuvable", false]]
	for cf in [[cz0 - 0.05, Vector3(0, 0, -1)], [cz1 + 0.05, Vector3(0, 0, 1)]]:
		var fz: float = cf[0]
		var fn: Vector3 = cf[1]
		_bx("in_noir", cx0 + 0.3, cx1 - 0.3, 0.7, 2.75, fz - 0.03, fz + 0.03)
		_texte("LES COURS DU JOUR", 40, Color(1.0, 0.8, 0.4), _p(mxc, 2.52, fz + fn.z * 0.04), fn)
		for i2 in range(cours.size()):
			var col: Color = Color(0.4, 1.0, 0.55) if bool(cours[i2][2]) else Color(1.0, 0.4, 0.35)
			var lig: float = 2.2 - i2 * 0.19
			_texte(str(cours[i2][0]), 24, Color(0.95, 0.93, 0.88), _p(mxc - fn.z * 1.6, lig, fz + fn.z * 0.04), fn)
			_texte(str(cours[i2][1]), 24, col, _p(mxc + fn.z * 2.6, lig, fz + fn.z * 0.04), fn)
	# ---- la cloche et le pupitre de la cheffe (à l'est, face à l'ascenseur)
	_bx("in_bois", W - 5.0, W - 2.2, 0.0, 0.35, cm - 1.6, cm + 1.6, true)
	_bx("k189_or", W - 5.02, W - 5.0, 0.3, 0.35, cm - 1.6, cm + 1.6)
	_bx("in_bois", W - 4.6, W - 3.9, 0.35, 1.45, cm - 0.5, cm + 0.5)
	b.box("in_ecran_ui_graphes", Transform3D(Basis(Vector3(0, 0, 1), -0.4), _p(W - 4.2, 1.5, cm)), Vector3(0.6, 0.01, 0.8))
	b.cyl_at("k189_bronze", _p(W - 2.7, 0.35, cm - 1.2), 0.05, 0.05, 2.0, 8)
	b.tube("k189_bronze", _p(W - 2.7, 2.35, cm - 1.2), _p(W - 3.2, 2.35, cm - 1.2), 0.03, 6)
	b.cyl_at("k189_or", _p(W - 3.2, 1.95, cm - 1.2), 0.2, 0.08, 0.3, 16)
	b.cyl_at("k189_or", _p(W - 3.2, 2.25, cm - 1.2), 0.05, 0.03, 0.1, 8)
	b.cyl_at("in_bois", _p(W - 3.2, 1.55, cm - 1.2), 0.012, 0.012, 0.4, 4)
	_texte("Ouverture : neuf heures.", 20, Color(1.0, 0.85, 0.5), _p(W - 5.03, 0.22, cm), Vector3(-1, 0, 0))
	_gens("femme", W - 3.3, cm + 0.2, Vector3(-1, 0, 0), "bras_croises", L_CHEF_MARCHES, false, true)
	# ---- les horloges des îles (sur le cœur, à l'ouest), le taureau et l'ours
	var iles: Array = [["Néopolis", 2.1], ["Tazira", 3.4], ["Port-Azur", 0.6], ["Montjoie", 5.2], ["Cliquetis", 4.3]]
	for i3 in range(iles.size()):
		var hz: float = cz0 + 0.6 + i3 * (cz1 - cz0 - 1.2) / 4.0
		var rond := Basis(Vector3(0, 0, 1), PI * 0.5)
		b.cyl("k189_or", Transform3D(rond, _p(cx0 - 0.04, 2.1, hz)), 0.4, 0.4, 0.06, 24)
		b.cyl("lampe_blanche", Transform3D(rond, _p(cx0 - 0.075, 2.1, hz)), 0.35, 0.35, 0.012, 24)
		var ah: float = float(iles[i3][1])
		b.tube("metal_noir", _p(cx0 - 0.09, 2.1, hz), _p(cx0 - 0.09, 2.1 + cos(ah) * 0.2, hz + sin(ah) * 0.2), 0.014, 4)
		b.tube("metal_noir", _p(cx0 - 0.09, 2.1, hz), _p(cx0 - 0.09, 2.1 + cos(ah * 5.0) * 0.3, hz + sin(ah * 5.0) * 0.3), 0.009, 4)
		_texte(str(iles[i3][0]), 18, Color(1.0, 0.85, 0.5), _p(cx0 - 0.05, 1.55, hz), Vector3(-1, 0, 0))
	for bt2 in [[cx0 - 3.0, cm - 1.5, "k189_or", "Le taureau : il monte."], [cx0 - 3.0, cm + 1.5, "k189_bronze", "L'ours : il attend."]]:
		var ax: float = bt2[0]
		var az: float = bt2[1]
		var mat: String = bt2[2]
		_bx("in_marbre_noir", ax - 0.75, ax + 0.75, 0.0, 0.7, az - 0.45, az + 0.45, true)
		b.blob(mat, _p(ax, 1.15, az), Vector3(0.55, 0.36, 0.3), 10)
		b.blob(mat, _p(ax - 0.55, 1.3, az), Vector3(0.24, 0.24, 0.22), 8)
		for sl in [[-0.35, -0.15], [-0.35, 0.15], [0.35, -0.15], [0.35, 0.15]]:
			b.cyl_at(mat, _p(ax + sl[0], 0.7, az + sl[1]), 0.07, 0.09, 0.3, 8)
		if mat == "k189_or":
			for sc in [-0.14, 0.14]:
				b.tube(mat, _p(ax - 0.6, 1.48, az + sc), _p(ax - 0.78, 1.7, az + sc * 1.6), 0.03, 5)
		else:
			for sc2 in [-0.14, 0.14]:
				b.blob(mat, _p(ax - 0.5, 1.52, az + sc2), Vector3(0.07, 0.07, 0.05), 6)
		_texte(str(bt2[3]), 16, Color(1.0, 0.85, 0.5), _p(ax + 0.76, 0.4, az), Vector3(1, 0, 0))
	# ---- le café (au sud-ouest) : la machine, « le carburant » ; les papiers par terre, partout
	_bx("in_bois", 0.4, 1.0, 0.0, 1.0, cz0, cz1, true)
	_bx("in_marbre_noir", 0.38, 1.06, 1.0, 1.04, cz0 - 0.04, cz1 + 0.04)
	_bx("in_inox", 0.45, 0.95, 1.04, 1.6, cm - 0.5, cm + 0.5)
	_bx("in_led_ambre", 0.95, 0.96, 1.4, 1.44, cm - 0.3, cm - 0.2)
	for i4 in range(8):
		b.cyl_at("peinture_blanche", _p(0.7, 1.04, cz0 + 0.3 + i4 * 0.22), 0.035, 0.04, 0.08, 8)
	_texte("Le carburant", 20, Color(1.0, 0.85, 0.5), _p(1.02, 0.6, cm), Vector3(1, 0, 0))
	_gens("homme", 1.8, cm + 1.0, Vector3(-1, 0, 0), "comptoir", L_TRADER)
	for i5 in range(46):
		var fx: float = rng.randf_range(1.5, W - 1.5)
		var fz2: float = rng.randf_range(1.0, D - 1.0)
		if fx > cx0 - 0.3 and fx < cx1 + 0.3 and fz2 > cz0 - 0.3 and fz2 < cz1 + 0.3:
			continue
		b.box("peinture_blanche", Transform3D(Basis(Vector3.UP, rng.randf() * TAU), _p(fx, 0.014 + (i5 % 3) * 0.001, fz2)), Vector3(0.21, 0.002, 0.3))
	_plante_pot(W - 0.9, 0.9, 1.4)
	_plante_pot(W - 0.9, D - 0.9, 1.4, true)
	_plante_pot(0.9, D - 0.9, 1.3)
	return "bip"


## Un poste de la salle des marchés : le pupitre, ses cinq écrans (trois en bas, deux en haut), le téléphone,
## la tasse, la chaise. « sg » : de quel côté s'assoit le courtier (1 : au sud du pupitre).
func _poste_marche(lx: float, lz: float, sg: float, n: int) -> void:
	_bx("in_bureau", lx - 0.85, lx + 0.85, 0.72, 0.76, lz - 0.4, lz + 0.4, true)
	_bx("in_noir", lx - 0.85, lx + 0.85, 0.0, 0.72, lz - sg * 0.38 - 0.02, lz - sg * 0.38 + 0.02)
	for sx in [-0.8, 0.8]:
		_bx("in_noir", lx + sx - 0.02, lx + sx + 0.02, 0.0, 0.72, lz - 0.38, lz + 0.38)
	var ecrans: Array = ["in_ecran_ui_graphes", "in_ecran_ui_code", "in_ecran_vert", "in_ecran_ui_messages"]
	var face := Basis(Vector3.UP, 0.0 if sg > 0.0 else PI)
	for j in range(5):
		var haut: bool = j >= 3
		var ex: float = (j - 1) * 0.54 if not haut else (j - 3.5) * 0.58
		var xf := Transform3D(face * Basis(Vector3.UP, -ex * 0.5 * sg) * Basis(Vector3(1, 0, 0), -0.25 if haut else 0.0), _p(lx + ex, 1.44 if haut else 1.02, lz - sg * (0.22 - absf(ex) * 0.12)))
		b.box("in_noir", xf, Vector3(0.52, 0.34, 0.03))
		b.box(str(ecrans[(n + j) % ecrans.size()]), xf * Transform3D(Basis(), Vector3(0, 0, 0.017)), Vector3(0.48, 0.3, 0.004))
	_bx("in_noir", lx - 0.03, lx + 0.03, 0.76, 1.3, lz - sg * 0.3 - 0.03, lz - sg * 0.3 + 0.03)
	_bx("in_noir", lx - 0.25, lx + 0.2, 0.76, 0.775, lz + sg * 0.12, lz + sg * 0.28)
	_bx("in_noir", lx + 0.5, lx + 0.72, 0.76, 0.8, lz + sg * 0.05, lz + sg * 0.25)
	b.tube("in_noir", _p(lx + 0.52, 0.83, lz + sg * 0.1), _p(lx + 0.7, 0.83, lz + sg * 0.2), 0.022, 5)
	b.cyl_at(["peinture_blanche", "rouge_laque", "k189_or", "tissu_vert"][n % 4], _p(lx - 0.6, 0.76, lz + sg * 0.15), 0.035, 0.04, 0.08, 8)
	T._chaise(b, _p(lx, 0.0, lz + sg * 0.8), Vector3(0, 0, -sg))


# ------------------------------------------------------------------ le 7e : l'orangerie
func _orangerie() -> String:
	var q: Array = _coeur()
	var cx0: float = q[0]
	var cx1: float = q[1]
	var cz0: float = q[2]
	var cz1: float = q[3]
	var cm: float = (cz0 + cz1) * 0.5
	_sol("in_marbre_blanc")
	_colonnes()
	_plafond()
	# la promenade du sud : un damier noir et blanc, deux rangs d'orangers en caisse
	for i in range(20):
		for j in range(2):
			if (i + j) % 2 == 0:
				_bx("in_marbre_noir", 1.4 + i * 2.0, 3.4 + i * 2.0, 0.012, 0.02, 14.6 + j * 2.0, 16.6 + j * 2.0)
	var n_o: int = 0
	for ox in [3.0, 7.6, 12.2, 16.8, 21.4, 26.0, 30.6, 35.2, 39.8]:
		_oranger(ox, 13.9, n_o)
		_oranger(ox, 19.3, n_o + 3)
		n_o += 1
	for bx in [9.9, 23.7, 32.9]:
		_banc_pierre(bx, 19.3, Vector3(0, 0, -1))
	_lustre(12.0, 16.6, 0.8)
	_lustre(31.0, 16.6, 0.8)
	# ---- la fontaine (au nord-ouest) : le bassin, la vasque, le poisson d'or et ses quatre jets ; les poissons rouges
	var fx: float = 8.0
	var fz: float = 6.2
	b.cyl_at("k189_pierre", _p(fx, 0.0, fz), 2.3, 2.3, 0.5, 24)
	b.cyl_at("k189_pierre_sombre", _p(fx, 0.5, fz), 2.35, 2.35, 0.06, 24)
	b.cyl_at("eau", _p(fx, 0.5, fz), 2.05, 2.05, 0.065, 24)
	b.cyl_at("k189_pierre", _p(fx, 0.0, fz), 0.22, 0.3, 1.3, 12)
	b.cyl_at("k189_pierre", _p(fx, 1.3, fz), 0.9, 0.3, 0.2, 18)
	b.cyl_at("eau", _p(fx, 1.5, fz), 0.82, 0.82, 0.01, 18)
	b.blob("k189_or", _p(fx, 1.8, fz), Vector3(0.14, 0.26, 0.2), 8)
	b.blob("k189_or", _p(fx, 2.0, fz - 0.14), Vector3(0.03, 0.12, 0.12), 6)
	for a in range(4):
		var d := Vector3(cos(a * TAU / 4.0), 0, sin(a * TAU / 4.0))
		var p0: Vector3 = _p(fx, 1.95, fz)
		for sgm in range(5):
			var u0: float = sgm / 5.0
			var u1: float = (sgm + 1) / 5.0
			b.tube("eau", p0 + d * (u0 * 1.5) + Vector3.UP * (0.5 * u0 - 1.9 * u0 * u0), p0 + d * (u1 * 1.5) + Vector3.UP * (0.5 * u1 - 1.9 * u1 * u1), 0.02, 5)
	T._col(_p(fx, 0.5, fz), Vector3(4.6, 1.0, 4.6))
	for i2 in range(4):
		var lotp := Kit.Batch.new()
		lotp.blob("k187_orange" if i2 % 2 == 0 else "peinture_blanche", Vector3(1.1 + i2 * 0.2, 0, 0), Vector3(0.1, 0.05, 0.035), 6)
		lotp.blob("k187_orange", Vector3(1.1 + i2 * 0.2, 0, 0.1), Vector3(0.035, 0.045, 0.05), 5)
		var po := MeshInstance3D.new()
		po.mesh = _maillage(lotp)
		_anime().add_child(po)
		po.global_position = _p(fx, 0.5, fz)
		po.rotate_y(i2 * 1.6)
		_anime().tourne.append([po, 0.35 + i2 * 0.08])
	for a2 in range(4):
		_oranger(fx + cos(a2 * TAU / 4.0 + 0.785) * 3.9, fz + sin(a2 * TAU / 4.0 + 0.785) * 3.4, a2 + 5)
	_banc_pierre(fx + 3.4, fz, Vector3(-1, 0, 0))
	_gens("femme", fx + 3.4, fz - 0.3, Vector3(-1, 0, 0), "assis", L_ORANGERIE)
	# ---- devant la loge (au nord, au milieu) : trois bancs face aux arbres et à la mer
	for bx2 in [17.8, 21.45, 25.1]:
		_banc_pierre(bx2, 4.1, Vector3(0, 0, -1))
	_gens("homme", 21.3, 4.1, Vector3(0, 0, -1), "assis", L_ORANGERIE, false, true)
	# ---- la volière (au nord-est) : la cage d'or, son dôme, les canaris de Monsieur Vertex
	var vx: float = 34.5
	var vz: float = 4.6
	b.cyl_at("k189_pierre", _p(vx, 0.0, vz), 1.9, 1.9, 0.3, 24)
	for a3 in range(28):
		var an: float = a3 * TAU / 28.0
		b.cyl_at("k189_or", _p(vx + cos(an) * 1.75, 0.3, vz + sin(an) * 1.75), 0.012, 0.012, 2.0, 4)
		b.tube("k189_or", _p(vx + cos(an) * 1.75, 2.3, vz + sin(an) * 1.75), _p(vx, 2.95, vz), 0.01, 4)
	for hh in [0.32, 1.3, 2.3]:
		for a4 in range(28):
			var b0: float = a4 * TAU / 28.0
			var b1: float = (a4 + 1) * TAU / 28.0
			b.tube("k189_or", _p(vx + cos(b0) * 1.75, hh, vz + sin(b0) * 1.75), _p(vx + cos(b1) * 1.75, hh, vz + sin(b1) * 1.75), 0.018, 4)
	b.blob("k189_or", _p(vx, 2.98, vz), Vector3(0.09, 0.14, 0.09), 8)
	b.cyl_at("in_bois", _p(vx, 0.3, vz), 0.04, 0.04, 1.7, 6)
	for pr in [[0.9, 0.0], [1.3, 1.6], [1.7, 3.1]]:
		b.tube("in_bois", _p(vx - cos(pr[1]) * 0.9, pr[0], vz - sin(pr[1]) * 0.9), _p(vx + cos(pr[1]) * 0.9, pr[0], vz + sin(pr[1]) * 0.9), 0.018, 5)
	for i3 in range(7):
		var ca: float = i3 * 0.9
		var cr: float = 0.3 + (i3 % 3) * 0.25
		var chh: float = [0.94, 1.34, 1.74][i3 % 3]
		var lotc := Kit.Batch.new()
		lotc.blob("tissu_jaune", Vector3.ZERO, Vector3(0.09, 0.09, 0.13), 7)
		lotc.blob("tissu_jaune", Vector3(0, 0.09, 0.09), Vector3(0.06, 0.06, 0.06), 6)
		lotc.blob("k187_orange", Vector3(0, 0.09, 0.16), Vector3(0.02, 0.018, 0.035), 4)
		lotc.blob("tissu_jaune", Vector3(0, 0.02, -0.14), Vector3(0.03, 0.015, 0.07), 4)
		var can := MeshInstance3D.new()
		can.mesh = _maillage(lotc)
		_anime().add_child(can)
		var cp: Vector3 = _p(vx + cos(ca) * cr * ([1.0, -1.0][i3 % 2]), chh, vz + sin(ca) * cr)
		can.global_position = cp
		can.rotate_y(ca * 2.0)
		if i3 % 3 == 0:
			_anime().flotte.append([can, cp + Vector3.UP * 0.25, 0.22, 2.2 + i3 * 0.3, i3 * 1.0])
	T._col(_p(vx, 1.5, vz), Vector3(3.6, 3.0, 3.6))
	_texte("Les canaris de Monsieur Vertex", 22, Color(1.0, 0.85, 0.5), _p(vx, 0.17, vz + 1.92), Vector3(0, 0, 1))
	_gens("homme", vx - 0.6, vz + 2.9, Vector3(0, 0, -1), "debout", L_ORANGERIE)
	# ---- le parterre (à l'ouest du cœur) : quatre carrés de buis, leurs fleurs, le cadran solaire
	for pq in [[3.0, cz0 + 0.2], [9.0, cz0 + 0.2], [3.0, cz1 + 0.3 - 2.6], [9.0, cz1 + 0.3 - 2.6]]:
		var x0: float = pq[0]
		var z0: float = pq[1]
		_bx("k189_pierre_sombre", x0, x0 + 4.0, 0.0, 0.22, z0, z0 + 2.3, true)
		_bx("terre_bac", x0 + 0.12, x0 + 3.88, 0.22, 0.24, z0 + 0.12, z0 + 2.18)
		for i4 in range(7):
			_vegetal(Flora.bush(1900 + i4 % 4), _p(x0 + 0.4 + i4 * 0.53, 0.2, z0 + 0.35), Vector3(0.36, 0.42, 0.36), i4 * 0.9)
			_vegetal(Flora.bush(1902 + i4 % 4), _p(x0 + 0.4 + i4 * 0.53, 0.2, z0 + 1.95), Vector3(0.36, 0.42, 0.36), i4 * 1.3)
		for i5 in range(4):
			_fleurs(_p(x0 + 0.7 + i5 * 0.85, 0.24, z0 + 1.15), [Color(1.0, 0.75, 0.2), Color(1.0, 1.0, 1.0), Color(1.0, 0.5, 0.2), Color(1.0, 0.9, 0.5)][(i5 + int(x0)) % 4], 0.8)
	b.cyl_at("k189_pierre", _p(8.0, 0.0, cm + 0.1), 0.3, 0.36, 0.9, 12)
	b.cyl_at("k189_or", _p(8.0, 0.9, cm + 0.1), 0.34, 0.34, 0.02, 20)
	b.box("k189_or", Transform3D(Basis(Vector3(1, 0, 0), 0.6), _p(8.0, 1.03, cm + 0.1)), Vector3(0.012, 0.3, 0.2))
	T._col(_p(8.0, 0.5, cm + 0.1), Vector3(0.7, 1.0, 0.7))
	# ---- le jardinier et son arrosoir ; les palmiers de l'ascenseur
	b.cyl_at("k189_or", _p(29.3, 0.0, 14.6), 0.14, 0.12, 0.26, 10)
	b.tube("k189_or", _p(29.42, 0.18, 14.6), _p(29.75, 0.32, 14.6), 0.025, 5)
	_gens("homme", 29.0, 13.6, Vector3(0.3, 0, 1).normalized(), "debout", L_ORANGERIE, false, true)
	_plante_pot(cx1 + 1.0, cz0 + 0.3, 1.6)
	_plante_pot(cx1 + 1.0, cz1 - 0.3, 1.6)
	return ""


## Un oranger en caisse : la caisse verte, ses boules d'or, l'arbre taillé, ses oranges.
func _oranger(lx: float, lz: float, n: int) -> void:
	_bx("tissu_vert", lx - 0.45, lx + 0.45, 0.012, 0.72, lz - 0.45, lz + 0.45, true)
	_bx("k189_or", lx - 0.47, lx + 0.47, 0.3, 0.34, lz - 0.47, lz + 0.47)
	for sx in [-0.45, 0.45]:
		for sz in [-0.45, 0.45]:
			_bx("peinture_blanche", lx + sx - 0.04, lx + sx + 0.04, 0.0, 0.76, lz + sz - 0.04, lz + sz + 0.04)
			b.blob("k189_or", _p(lx + sx, 0.82, lz + sz), Vector3(0.06, 0.06, 0.06), 6)
	_bx("terre_bac", lx - 0.4, lx + 0.4, 0.72, 0.74, lz - 0.4, lz + 0.4)
	var k: float = (hc - 0.95) / 7.0
	_vegetal(Flora.tree(1910 + n % 5, 7.0, 240), _p(lx, 0.7, lz), Vector3(k * 1.1, k, k * 1.1), n * 1.9)
	for i in range(9):
		var a: float = i * 2.4 + n
		var r: float = 0.35 + (i % 3) * 0.16
		b.blob("k187_orange", _p(lx + cos(a) * r, hc - 1.25 + (i % 4) * 0.22, lz + sin(a) * r), Vector3(0.055, 0.055, 0.055), 6)


## Un banc de pierre (il regarde vers « face »).
func _banc_pierre(lx: float, lz: float, face: Vector3) -> void:
	var o: Vector3 = _p(lx, 0.0, lz)
	var bs := Basis(Vector3.UP, atan2(face.x, face.z))
	_pc("k189_pierre", o, bs, Vector3(0, 0.42, 0), Vector3(1.9, 0.1, 0.5))
	for sx in [-0.7, 0.7]:
		_pc("k189_pierre_sombre", o, bs, Vector3(sx, 0.2, 0), Vector3(0.2, 0.38, 0.44))
	T._col(o + Vector3.UP * 0.25, Vector3(1.9, 0.5, 0.5), atan2(face.x, face.z))


# ------------------------------------------------------------------ le 10e : la direction
func _direction9() -> String:
	var q: Array = _coeur()
	var cx0: float = q[0]
	var cx1: float = q[1]
	var cz0: float = q[2]
	var cz1: float = q[3]
	var cm: float = (cz0 + cz1) * 0.5
	var mxc: float = (cx0 + cx1) * 0.5
	_colonnes()
	_plafond()
	_lustre(8.5, cm, 1.1)
	_lustre(27.0, 5.6, 0.8)
	_lustre(30.0, 16.2, 0.8)
	# ---- le bureau de Monsieur Vertex (à l'ouest) : le grand tapis, le bureau de marbre, le fauteuil
	_bx("tissu_rouge", 2.4, 13.4, 0.012, 0.022, cm - 3.8, cm + 3.8)
	for e in [[2.4, 13.4, cm - 3.8, cm - 3.65], [2.4, 13.4, cm + 3.65, cm + 3.8], [2.4, 2.55, cm - 3.8, cm + 3.8], [13.25, 13.4, cm - 3.8, cm + 3.8]]:
		_bx("k189_or", e[0], e[1], 0.012, 0.025, e[2], e[3])
	var bx: float = 5.6
	_bx("k189_bronze", bx - 0.5, bx + 0.5, 0.0, 0.8, cm - 1.5, cm + 1.5, true)
	_bx("in_marbre_noir", bx - 0.7, bx + 0.7, 0.8, 0.86, cm - 1.75, cm + 1.75)
	for sv in [-1.0, 1.0]:
		b.box("k189_or", Transform3D(Basis(Vector3(1, 0, 0), sv * 0.32), _p(bx + 0.505, 0.42, cm + sv * 0.13)), Vector3(0.012, 0.6, 0.08))
	_bx("k189_or", bx + 0.45, bx + 0.5, 0.86, 0.94, cm - 0.35, cm + 0.35)                    # (la plaque)
	_texte("M. VERTEX", 14, Color(0.2, 0.13, 0.05), _p(bx + 0.505, 0.9, cm), Vector3(1, 0, 0))
	_bx("k189_or", bx - 0.2, bx + 0.1, 0.86, 0.9, cm + 1.0, cm + 1.3)                       # (le téléphone d'or)
	b.tube("k189_or", _p(bx - 0.18, 0.94, cm + 1.05), _p(bx + 0.08, 0.94, cm + 1.25), 0.03, 6)
	b.cyl_at("k189_or", _p(bx, 0.86, cm - 1.2), 0.07, 0.07, 0.015, 10)
	b.cyl_at("k189_or", _p(bx, 0.86, cm - 1.2), 0.012, 0.012, 0.3, 5)
	b.box("tissu_vert", Transform3D(Basis(), _p(bx, 1.19, cm - 1.2)), Vector3(0.14, 0.08, 0.3))
	_bx("tissu_vert", bx - 0.35, bx + 0.35, 0.86, 0.865, cm - 0.45, cm + 0.45)
	_lingots(bx + 0.2, 0.86, cm - 0.75, 2)
	for i in range(3):
		_bx("peinture_blanche", bx - 0.3 + i * 0.02, bx + 0.0 + i * 0.02, 0.865 + i * 0.01, 0.875 + i * 0.01, cm + 0.5, cm + 0.75)
	_bx("in_cuir", bx - 1.55, bx - 0.85, 0.34, 0.5, cm - 0.4, cm + 0.4, true)
	b.box("in_cuir", Transform3D(Basis(Vector3(0, 0, 1), 0.14), _p(bx - 1.6, 1.05, cm)), Vector3(0.12, 1.2, 0.8))
	for sg in [-0.45, 0.45]:
		_bx("in_cuir", bx - 1.55, bx - 0.95, 0.5, 0.74, cm + sg - 0.05, cm + sg + 0.05)
	b.cyl_at("k189_or", _p(bx - 1.2, 0.04, cm), 0.04, 0.04, 0.3, 8)
	_gens("homme", bx - 1.2, cm, Vector3(1, 0, 0), "assis", L_VERTEX, false, true)
	_canape(bx + 2.5, cm - 0.9, Vector3(-1, 0, 0), 1.0)
	_canape(bx + 2.5, cm + 0.9, Vector3(-1, 0, 0), 1.0)
	# la longue-vue, braquée sur la tour d'en face (les drones de Madame Kumo)
	for a in range(3):
		var an: float = a * TAU / 3.0 + 0.5
		b.tube("in_bois", _p(2.6, 1.3, cm + 3.0), _p(2.6 + cos(an) * 0.45, 0.0, cm + 3.0 + sin(an) * 0.45), 0.018, 5)
	b.tube("k189_or", _p(3.0, 1.26, cm + 3.0), _p(1.9, 1.4, cm + 3.0), 0.05, 10)
	b.tube("k189_bronze", _p(1.9, 1.4, cm + 3.0), _p(1.6, 1.44, cm + 3.0), 0.065, 10)
	T._col(_p(2.6, 0.7, cm + 3.0), Vector3(0.9, 1.4, 0.8))
	_texte("« Des drones. Toute la journée. »", 14, Color(1.0, 0.85, 0.5), _p(2.6, 0.5, cm + 3.5), Vector3(1, 0, 0.5).normalized())
	# le grand globe (il tourne), la maquette de la tour sous sa cloche
	var lotg := Kit.Batch.new()
	lotg.blob("plastique_bleu", Vector3.ZERO, Vector3(0.7, 0.7, 0.7), 18)
	for i2 in range(9):
		var ga: float = i2 * 2.1
		var gb: float = sin(i2 * 1.7) * 0.9
		lotg.blob("tissu_vert" if i2 % 3 != 0 else "k189_or", Vector3(cos(ga) * cos(gb), sin(gb), sin(ga) * cos(gb)) * 0.62, Vector3(0.2, 0.16, 0.2) * (0.6 + (i2 % 3) * 0.3), 7)
	var globe := MeshInstance3D.new()
	globe.mesh = _maillage(lotg)
	_anime().add_child(globe)
	globe.global_transform = Transform3D(Basis(Vector3(0, 0, 1), 0.4), _p(4.0, 1.25, cm - 3.0))
	_anime().tourne.append([globe, 0.25])
	b.cyl_at("k189_bronze", _p(4.0, 0.0, cm - 3.0), 0.5, 0.4, 0.08, 16)
	b.cyl_at("k189_bronze", _p(4.0, 0.0, cm - 3.0), 0.05, 0.05, 0.5, 8)
	for a2 in range(12):
		var c0: float = a2 * PI / 12.0 - PI * 0.5
		var c1: float = (a2 + 1) * PI / 12.0 - PI * 0.5
		b.tube("k189_or", _p(4.0 + cos(c0) * 0.78, 1.25 + sin(c0) * 0.78, cm - 3.0), _p(4.0 + cos(c1) * 0.78, 1.25 + sin(c1) * 0.78, cm - 3.0), 0.02, 5)
	T._col(_p(4.0, 1.0, cm - 3.0), Vector3(1.6, 2.0, 1.6))
	var mqx: float = 11.5
	var mqz: float = cm - 3.0
	_bx("in_marbre_noir", mqx - 0.6, mqx + 0.6, 0.0, 0.9, mqz - 0.4, mqz + 0.4, true)
	_bx("k189_pierre", mqx - 0.42, mqx + 0.42, 0.9, 1.62, mqz - 0.2, mqz + 0.2)
	for i3 in range(8):
		_bx("k189_or", mqx - 0.4 + i3 * 0.114, mqx - 0.39 + i3 * 0.114, 1.05, 1.6, mqz - 0.21, mqz + 0.21)
	_bx("metal_noir", mqx - 0.43, mqx + 0.43, 1.03, 1.045, mqz - 0.21, mqz + 0.21)
	b.cyl_at("k189_verriere", _p(mqx - 0.15, 1.62, mqz), 0.14, 0.0, 0.12, 4)
	_bx("in_vitre", mqx - 0.55, mqx + 0.55, 0.9, 1.9, mqz - 0.35, mqz + 0.35)
	_texte("La Tour Vertex (au 1/60)", 14, Color(1.0, 0.85, 0.5), _p(mqx, 0.6, mqz + 0.41), Vector3(0, 0, 1))
	# ---- le coffre secret (sur le cœur, derrière le portrait qui pivote)
	var sz: float = cz0 + 1.0
	_bx("in_inox", cx0 - 0.05, cx0, 1.2, 2.0, sz - 0.45, sz + 0.45)
	_bx("k189_bronze", cx0 - 0.06, cx0, 1.14, 2.06, sz - 0.51, sz - 0.45)
	_bx("k189_bronze", cx0 - 0.06, cx0, 1.14, 2.06, sz + 0.45, sz + 0.51)
	b.cyl("k189_or", Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), _p(cx0 - 0.08, 1.6, sz)), 0.12, 0.12, 0.05, 16)
	b.tube("metal_noir", _p(cx0 - 0.11, 1.6, sz), _p(cx0 - 0.11, 1.7, sz + 0.03), 0.01, 4)
	_bx("k189_or", cx0 - 0.07, cx0 - 0.05, 1.5, 1.7, sz + 0.3, sz + 0.36)
	_portrait(_p(cx0 - 0.5, 1.6, sz + 1.02), Vector3(-0.5, 0, -0.87).normalized(), 0, "")
	_texte("(Ne le dites à personne.)", 12, Color(0.95, 0.92, 0.85), _p(cx0 - 0.06, 1.08, sz), Vector3(-1, 0, 0))
	# ---- la salle du conseil (au nord) : la longue table, ses fauteuils, les suspensions d'or
	var t0: float = cx0 + 3.6
	var t1: float = cx1 + 7.6
	_bx("in_bois", t0, t1, 0.72, 0.78, 4.9, 6.3, true)
	_bx("in_marbre_noir", t0 + 0.6, t1 - 0.6, 0.78, 0.79, 5.25, 5.95)
	var tx: float = t0 + 0.8
	while tx < t1 - 0.5:
		_bx("k189_bronze", tx - 0.06, tx + 0.06, 0.0, 0.72, 5.3, 5.9)
		var libre: bool = true
		for p in T.info.get("piliers", []):
			if absf((p as Vector2).x - X0 - tx) < 0.75:
				libre = false
		if libre:
			T._chaise(b, _p(tx, 0.0, 4.4), Vector3(0, 0, 1))
		T._chaise(b, _p(tx, 0.0, 6.8), Vector3(0, 0, -1))
		b.cyl_at("k189_or", _p(tx, 1.9, 5.6), 0.004, 0.004, hc - 1.9, 4)
		b.cyl_at("k189_or", _p(tx, 1.76, 5.6), 0.17, 0.05, 0.14, 12)
		b.cyl_at("lampe_chaude", _p(tx, 1.75, 5.6), 0.15, 0.15, 0.012, 12)
		_bx("peinture_blanche", tx - 0.12, tx + 0.12, 0.79, 0.793, 6.0, 6.25)
		tx += 1.5
	_gens("femme", t0 + 0.8 + 1.5 * 2.0, 6.8, Vector3(0, 0, -1), "assis", L_SECRETAIRE9)
	_gens("homme", t0 + 0.8 + 1.5 * 5.0, 6.8, Vector3(0, 0, -1), "assis", L_VERTEX)
	# ---- l'accueil (à l'est, face à l'ascenseur) : le bureau de la secrétaire, le canapé « à neuf cents pièces »
	_bx("in_bois", W - 8.6, W - 8.0, 0.0, 1.05, cm - 1.4, cm + 1.4, true)
	_bx("in_marbre_noir", W - 8.68, W - 7.92, 1.05, 1.09, cm - 1.48, cm + 1.48)
	for sv2 in [-1.0, 1.0]:
		b.box("k189_or", Transform3D(Basis(Vector3(1, 0, 0), sv2 * 0.32), _p(W - 8.62, 0.55, cm + sv2 * 0.14)), Vector3(0.02, 0.8, 0.09))
	_gens("femme", W - 7.3, cm, Vector3(-1, 0, 0), "comptoir", L_SECRETAIRE9, false, true)
	_canape(W - 3.2, cm, Vector3(-1, 0, 0), 2.6)
	_gens("homme", W - 3.3, cm + 0.5, Vector3(-1, 0, 0), "assis", L_CLIENT9)
	_plante_pot(W - 2.4, cz0 - 0.2, 1.5)
	_plante_pot(W - 2.4, cz1 + 0.2, 1.5, true)
	# ---- la galerie des présidents (sur le cœur, au sud) ; le salon, le meuble aux carafes
	var noms: Array = ["Vertex Iᵉʳ, le Fondateur\n(une pièce)", "Vertex II, le Prudent", "Vertex III, l'Audacieux\n(ruiné deux fois)", "La Présidente Vertex,\nqui inventa le centime", "Vertex V, le Distrait\n(voir 2091)"]
	for i4 in range(5):
		var gx: float = cx0 + 1.0 + i4 * (cx1 - cx0 - 2.0) / 4.0
		_portrait(_p(gx, 1.75, cz1 + 0.05), Vector3(0, 0, 1), i4 + 1, str(noms[i4]))
	_bx("tissu_vert", mxc - 3.4, mxc + 3.4, 0.012, 0.022, cz1 + 2.0, D - 2.2)
	_canape(mxc, D - 2.6, Vector3(0, 0, -1), 2.6)
	_canape(mxc - 2.8, cz1 + 3.3, Vector3(1, 0, 0), 1.0)
	_canape(mxc + 2.8, cz1 + 3.3, Vector3(-1, 0, 0), 1.0)
	_bx("in_marbre_noir", mxc - 0.7, mxc + 0.7, 0.38, 0.42, cz1 + 2.9, cz1 + 3.7, true)
	_lingots(mxc, 0.42, cz1 + 3.3, 2)
	_bx("in_bois", W - 12.0, W - 10.0, 0.0, 0.9, D - 2.2, D - 1.6, true)
	_bx("in_marbre_noir", W - 12.05, W - 9.95, 0.9, 0.93, D - 2.25, D - 1.55)
	for i5 in range(5):
		b.cyl_at(["verre_fume", "rouge_laque", "verre", "verre_fume", "k189_or"][i5], _p(W - 11.7 + i5 * 0.35, 0.93, D - 1.9), 0.04, 0.05, 0.22 + (i5 % 2) * 0.06, 8)
	_gens("homme", W - 11.0, D - 2.9, Vector3(0, 0, 1), "comptoir", L_GARDE, true)
	_plante_pot(15.0, D - 2.0, 1.5)
	_plante_pot(15.0, 2.0, 1.5, true)
	return ""


## Un portrait dans son cadre d'or : la toile sombre, un buste (chacun sa coiffe, sa moustache), son nom dessous.
func _portrait(at: Vector3, face: Vector3, n: int, nom_p: String) -> void:
	var bs := Basis(Vector3.UP, atan2(face.x, face.z))
	b.box("k189_or", Transform3D(bs, at), Vector3(1.1, 1.4, 0.05))
	b.box(["k189_vert", "in_tissu_rouge", "in_noir", "plastique_bleu", "k189_bronze", "k189_vert"][n % 6], Transform3D(bs, at + bs * Vector3(0, 0, 0.02)), Vector3(0.92, 1.22, 0.03))
	b.blob("in_noir" if n % 2 == 0 else "in_tissu_gris", at + bs * Vector3(0, -0.36, 0.035), Vector3(0.34, 0.26, 0.02), 8)
	b.blob("sakura", at + bs * Vector3(0, 0.08, 0.04), Vector3(0.15, 0.19, 0.02), 10)
	match n % 6:
		0, 1:
			b.cyl("in_noir", Transform3D(bs * Basis(Vector3(1, 0, 0), PI * 0.5), at + bs * Vector3(0, 0.36, 0.04)), 0.14, 0.14, 0.02, 10)
			b.box("in_noir", Transform3D(bs, at + bs * Vector3(0, 0.24, 0.045)), Vector3(0.44, 0.03, 0.02))
		2:
			b.blob("peinture_blanche", at + bs * Vector3(0, 0.26, 0.04), Vector3(0.17, 0.08, 0.02), 8)
		3:
			b.blob("k189_or", at + bs * Vector3(0, 0.3, 0.04), Vector3(0.12, 0.05, 0.02), 6)
		4:
			b.blob("in_bois", at + bs * Vector3(0, 0.22, 0.04), Vector3(0.2, 0.12, 0.02), 8)
		_:
			b.box("peinture_blanche", Transform3D(bs, at + bs * Vector3(0, 0.27, 0.045)), Vector3(0.3, 0.05, 0.02))
	if n % 2 == 1:
		b.box("in_noir", Transform3D(bs, at + bs * Vector3(0, 0.0, 0.055)), Vector3(0.2, 0.03, 0.01))      # (la moustache)
	if nom_p != "":
		var lab: Label3D = _texte(nom_p, 13, Color(1.0, 0.85, 0.5), at + bs * Vector3(0, -0.92, 0.03), face)
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER



# ------------------------------------------------------------------ le 1er : les conseillers
func _conseillers() -> String:
	var q: Array = _coeur()
	var cx0: float = q[0]
	var cx1: float = q[1]
	var cz0: float = q[2]
	var cz1: float = q[3]
	var cm: float = (cz0 + cz1) * 0.5
	_colonnes()
	_plafond()
	_lustre(34.0, cm, 0.9)
	_lustre(8.5, cm, 0.9)
	# ---- quatre bureaux vitrés, au nord (deux à l'ouest, deux à l'est) : chacun son conseiller, sa spécialité
	var titres: Array = ["Prêts", "Épargne", "Assurances", "Placements"]
	var n: int = 0
	for bx0 in [0.5, 8.3, 26.6, 34.5]:
		var bx1: float = bx0 + 7.6
		var mb: float = (bx0 + bx1) * 0.5
		# la cloison de verre (une porte ouverte au milieu), les cloisons de côté
		_bx("in_cloison_verre", bx0, mb - 0.7, 0.0, hc - 0.1, 6.58, 6.62, true)
		_bx("in_cloison_verre", mb + 0.7, bx1, 0.0, hc - 0.1, 6.58, 6.62, true)
		_bx("k189_bronze", mb - 0.76, mb - 0.7, 0.0, hc - 0.1, 6.54, 6.66)
		_bx("k189_bronze", mb + 0.7, mb + 0.76, 0.0, hc - 0.1, 6.54, 6.66)
		_bx("k189_bronze", bx0, bx1, 2.2, 2.26, 6.56, 6.64)
		_bx("in_cloison_verre", bx1 - 0.02, bx1 + 0.02, 0.0, hc - 0.1, 0.4, 6.6, true)
		_texte(str(titres[n]), 34, Color(1.0, 0.82, 0.45), _p(mb, 2.5, 6.66), Vector3(0, 0, 1))
		_bx("in_moquette_bleue" if n % 2 == 0 else "tissu_vert", bx0 + 0.2, bx1 - 0.2, 0.012, 0.02, 0.5, 6.4)
		# le bureau, le conseiller, les deux fauteuils des clients
		_bx("in_bois", mb - 1.1, mb + 1.1, 0.0, 0.76, 2.0, 2.8, true)
		_bx("in_marbre_noir", mb - 1.2, mb + 1.2, 0.76, 0.8, 1.9, 2.9)
		_bx("in_noir", mb - 0.75, mb - 0.2, 0.8, 1.2, 2.1, 2.13)
		_bx("in_ecran_ui_graphes", mb - 0.72, mb - 0.23, 0.83, 1.17, 2.08, 2.1)
		b.cyl_at("k189_or", _p(mb + 0.8, 0.8, 2.3), 0.06, 0.06, 0.015, 8)
		b.cyl_at("k189_or", _p(mb + 0.8, 0.8, 2.3), 0.012, 0.012, 0.26, 5)
		b.box("tissu_vert", Transform3D(Basis(), _p(mb + 0.8, 1.09, 2.3)), Vector3(0.26, 0.07, 0.12))
		for i in range(3):
			_bx("peinture_blanche", mb + 0.1 + i * 0.02, mb + 0.4 + i * 0.02, 0.8 + i * 0.008, 0.808 + i * 0.008, 2.3, 2.7)
		T._chaise(b, _p(mb, 0.0, 1.35), Vector3(0, 0, 1))
		_gens("homme" if n % 2 == 0 else "femme", mb, 1.35, Vector3(0, 0, 1), "assis", L_CONSEIL, false, n == 0)
		_canape(mb - 0.8, 4.0, Vector3(0, 0, -1), 1.0)
		_canape(mb + 0.8, 4.0, Vector3(0, 0, -1), 1.0)
		if n == 0 or n == 3:
			_gens("femme" if n == 0 else "homme", mb - 0.8, 3.9, Vector3(0, 0, -1), "assis", L_CLIENT_CONSEIL)
		_plante_pot(bx0 + 0.8, 5.8, 1.2, n % 2 == 1)
		# la spécialité de la maison
		var sx: float = bx1 - 1.3
		match n:
			0:                                # (les prêts : la maquette d'une maison, sa clé d'or)
				_bx("in_bois", sx - 0.5, sx + 0.5, 0.0, 0.8, 0.7, 1.5, true)
				_bx("peinture_blanche", sx - 0.3, sx + 0.3, 0.8, 1.1, 0.9, 1.3)
				b.box("rouge_laque", Transform3D(Basis(Vector3(1, 0, 0), 0.7), _p(sx, 1.2, 1.0)), Vector3(0.66, 0.03, 0.34))
				b.box("rouge_laque", Transform3D(Basis(Vector3(1, 0, 0), -0.7), _p(sx, 1.2, 1.2)), Vector3(0.66, 0.03, 0.34))
				_bx("in_bois", sx - 0.05, sx + 0.05, 0.8, 0.98, 1.3, 1.31)
				b.tube("k189_or", _p(sx + 0.38, 0.82, 1.1), _p(sx + 0.38, 0.82, 1.35), 0.012, 5)
			1:                                # (l'épargne : le grand sablier)
				_bx("in_bois", sx - 0.4, sx + 0.4, 0.0, 0.5, 0.8, 1.6, true)
				b.cyl_at("k189_or", _p(sx, 0.5, 1.2), 0.3, 0.3, 0.05, 14)
				b.cyl_at("verre", _p(sx, 0.55, 1.2), 0.26, 0.04, 0.6, 14)
				b.cyl_at("verre", _p(sx, 1.15, 1.2), 0.04, 0.26, 0.6, 14)
				b.cyl_at("tissu_jaune", _p(sx, 0.55, 1.2), 0.22, 0.1, 0.25, 12)
				b.cyl_at("tissu_jaune", _p(sx, 1.5, 1.2), 0.15, 0.2, 0.12, 12)
				b.cyl_at("tissu_jaune", _p(sx, 0.8, 1.2), 0.006, 0.006, 0.7, 4)
				b.cyl_at("k189_or", _p(sx, 1.75, 1.2), 0.3, 0.3, 0.05, 14)
				for a in range(3):
					b.cyl_at("k189_or", _p(sx + cos(a * TAU / 3.0) * 0.28, 0.55, 1.2 + sin(a * TAU / 3.0) * 0.28), 0.015, 0.015, 1.2, 5)
			2:                                # (les assurances : les parapluies, le casque, la bouée)
				b.cyl_at("k189_bronze", _p(sx, 0.0, 1.2), 0.22, 0.26, 0.6, 12)
				for i2 in range(5):
					b.cyl_at(["in_noir", "plastique_rouge", "plastique_bleu", "tissu_jaune", "in_noir"][i2], _p(sx + cos(i2 * 1.3) * 0.1, 0.1, 1.2 + sin(i2 * 1.3) * 0.1), 0.03, 0.018, 0.9, 6)
				for a2 in range(12):
					b.tube("plastique_rouge" if a2 % 2 == 0 else "peinture_blanche", _p(sx - 0.9 + cos(a2 * TAU / 12.0) * 0.3, 1.6 + sin(a2 * TAU / 12.0) * 0.3, 0.42), _p(sx - 0.9 + cos((a2 + 1) * TAU / 12.0) * 0.3, 1.6 + sin((a2 + 1) * TAU / 12.0) * 0.3, 0.42), 0.06, 6)
			_:                                # (les placements : la cible, les cours, les fléchettes)
				var cz: float = 0.5
				var rond := Basis(Vector3(1, 0, 0), PI * 0.5)
				for rr in range(4):
					b.cyl(["in_noir", "peinture_blanche", "plastique_rouge", "k189_or"][rr], Transform3D(rond, _p(sx - 0.6, 1.7, cz + rr * 0.006)), 0.42 - rr * 0.11, 0.42 - rr * 0.11, 0.02, 20)
				for i3 in range(3):
					var fa: float = i3 * 2.3 + 0.4
					var fp: Vector3 = _p(sx - 0.6 + cos(fa) * (0.1 + i3 * 0.1), 1.7 + sin(fa) * (0.1 + i3 * 0.1), cz + 0.03)
					b.tube("in_inox", fp, fp + Vector3(0, 0.02, 0.14), 0.006, 4)
					b.box("plastique_rouge" if i3 != 1 else "plastique_bleu", Transform3D(Basis(), fp + Vector3(0, 0.025, 0.16)), Vector3(0.05, 0.05, 0.005))
				_texte("KUMO   NOUILLES   PIGEON", 12, Color(0.2, 0.13, 0.05), _p(sx - 0.6, 2.2, cz + 0.03), Vector3(0, 0, 1))
		n += 1
	# ---- l'accueil et l'attente (à l'est, face à l'ascenseur) : la borne à tickets, le numéro appelé
	_bx("in_bois", W - 6.2, W - 5.6, 0.0, 1.05, cm - 1.4, cm + 1.4, true)
	_bx("in_marbre_noir", W - 6.28, W - 5.52, 1.05, 1.09, cm - 1.48, cm + 1.48)
	_gens("femme", W - 4.9, cm, Vector3(-1, 0, 0), "comptoir", L_ACCUEIL9, false, true)
	_bx("k189_bronze", cx1 + 2.6, cx1 + 3.0, 0.0, 1.3, cm + 1.9, cm + 2.3, true)
	_bx("in_ecran_vert", cx1 + 2.59, cx1 + 2.6, 0.9, 1.15, cm + 1.98, cm + 2.22)
	_bx("peinture_blanche", cx1 + 2.58, cx1 + 2.6, 0.6, 0.75, cm + 2.05, cm + 2.15)
	_bx("in_noir", W - 0.5, W - 0.44, 1.9, 2.6, cm - 1.2, cm + 1.2)
	_texte("NUMÉRO APPELÉ", 22, Color(1.0, 0.82, 0.45), _p(W - 0.52, 2.42, cm), Vector3(-1, 0, 0))
	_texte("2", 60, Color(0.4, 1.0, 0.55), _p(W - 0.52, 2.12, cm), Vector3(-1, 0, 0))
	for i4 in range(4):
		T._chaise(b, _p(W - 2.0, 0.0, cz1 + 1.0 + i4 * 0.9), Vector3(-1, 0, 0))
	_gens("homme", W - 2.0, cz1 + 1.9, Vector3(-1, 0, 0), "assis", L_CLIENT_CONSEIL, false, true)
	_gens("femme", W - 2.0, cz1 + 3.7, Vector3(-1, 0, 0), "assis", L_CLIENT_CONSEIL)
	# ---- le simulateur de prêt (au sud-est) : la machine de bronze, ses cadrans, son levier, sa réponse
	var mx0: float = W - 12.0
	_bx("k189_bronze", mx0, mx0 + 2.4, 0.0, 2.1, D - 1.3, D - 0.4, true)
	_bx("k189_or", mx0 - 0.04, mx0 + 2.44, 2.1, 2.18, D - 1.34, D - 0.4)
	for i5 in range(3):
		var rd := Basis(Vector3(1, 0, 0), PI * 0.5)
		b.cyl("k189_or", Transform3D(rd, _p(mx0 + 0.5 + i5 * 0.7, 1.6, D - 1.31)), 0.22, 0.22, 0.03, 18)
		b.cyl("peinture_blanche", Transform3D(rd, _p(mx0 + 0.5 + i5 * 0.7, 1.6, D - 1.33)), 0.18, 0.18, 0.012, 18)
		b.tube("plastique_rouge", _p(mx0 + 0.5 + i5 * 0.7, 1.6, D - 1.345), _p(mx0 + 0.5 + i5 * 0.7 + cos(2.4 + i5) * 0.14, 1.6 + sin(2.4 + i5) * 0.14, D - 1.345), 0.008, 4)
	_bx("in_noir", mx0 + 0.5, mx0 + 1.9, 0.95, 1.25, D - 1.32, D - 1.3)
	_texte("RÉSULTAT : NON.", 24, Color(1.0, 0.45, 0.35), _p(mx0 + 1.2, 1.1, D - 1.33), Vector3(0, 0, -1))
	_texte("Simulateur de prêt", 26, Color(1.0, 0.85, 0.5), _p(mx0 + 1.2, 1.95, D - 1.31), Vector3(0, 0, -1))
	b.tube("chrome", _p(mx0 + 2.45, 1.0, D - 0.85), _p(mx0 + 2.8, 1.55, D - 0.85), 0.025, 6)
	b.blob("plastique_rouge", _p(mx0 + 2.82, 1.6, D - 0.85), Vector3(0.07, 0.07, 0.07), 8)
	_bx("peinture_blanche", mx0 + 1.05, mx0 + 1.35, 0.5, 0.9, D - 1.31, D - 1.305)
	_gens("homme", mx0 + 1.3, D - 2.2, Vector3(0, 0, 1), "debout", L_CLIENT_CONSEIL)
	# ---- l'employé du mois (sur le cœur, au sud) : six cadres, toujours le même
	for i6 in range(6):
		_portrait(_p(cx0 + 0.9 + i6 * (cx1 - cx0 - 1.8) / 5.0, 1.8, cz1 + 0.05), Vector3(0, 0, 1), 3, "")
	_texte("L'EMPLOYÉ DU MOIS", 30, Color(1.0, 0.82, 0.45), _p((cx0 + cx1) * 0.5, 2.75, cz1 + 0.06), Vector3(0, 0, 1))
	_texte("Bernard. Bernard. Bernard. Bernard. Bernard. Bernard.", 16, Color(0.95, 0.92, 0.85), _p((cx0 + cx1) * 0.5, 0.95, cz1 + 0.06), Vector3(0, 0, 1))
	# ---- les archives (au sud-ouest) : les classeurs à tiroirs, la table des dossiers
	for i7 in range(9):
		var ax: float = 0.9 + i7 * 1.0
		_bx("in_inox", ax - 0.45, ax + 0.45, 0.0, 1.8, D - 0.95, D - 0.35, true)
		for t in range(4):
			_bx("k189_bronze", ax - 0.4, ax + 0.4, 0.08 + t * 0.44, 0.48 + t * 0.44, D - 0.97, D - 0.95)
			_bx("k189_or", ax - 0.1, ax + 0.1, 0.3 + t * 0.44, 0.33 + t * 0.44, D - 0.99, D - 0.97)
		if i7 % 3 == 1:
			_bx("k189_bronze", ax - 0.4, ax + 0.4, 0.96, 1.36, D - 1.35, D - 0.97)
			for dd in range(5):
				_bx(["peinture_blanche", "tissu_jaune", "in_bois_clair"][dd % 3], ax - 0.35, ax + 0.35, 1.0, 1.3, D - 1.32 + dd * 0.06, D - 1.28 + dd * 0.06)
	_bx("in_bois", 3.0, 7.0, 0.72, 0.78, D - 4.4, D - 3.0, true)
	for qq in [[3.1, D - 4.3], [6.9, D - 4.3], [3.1, D - 3.1], [6.9, D - 3.1]]:
		_bx("in_bois", qq[0] - 0.04, qq[0] + 0.04, 0.0, 0.72, qq[1] - 0.04, qq[1] + 0.04)
	for i8 in range(7):
		var ph: float = rng.randf_range(0.1, 0.5)
		_bx(["peinture_blanche", "in_bois_clair", "tissu_jaune"][i8 % 3], 3.2 + i8 * 0.52, 3.55 + i8 * 0.52, 0.78, 0.78 + ph, D - 4.0, D - 3.5)
	_gens("femme", 5.0, D - 2.3, Vector3(0, 0, -1), "comptoir", L_COMPTA)
	_plante_pot(0.9, cz0 + 0.3, 1.4)
	_plante_pot(W - 0.9, D - 0.9, 1.4, true)
	return ""


# ------------------------------------------------------------------ le 2e : le restaurant « La Corbeille »
func _corbeille() -> String:
	var q: Array = _coeur()
	var cx0: float = q[0]
	var cx1: float = q[1]
	var cz0: float = q[2]
	var cz1: float = q[3]
	var cm: float = (cz0 + cz1) * 0.5
	var mxc: float = (cx0 + cx1) * 0.5
	_colonnes()
	_plafond()
	for lq in [[8.0, cm], [34.5, cm], [20.0, 16.6], [8.0, 16.6], [34.5, 16.6]]:
		_lustre(lq[0], lq[1], 0.85)
	# ---- le pupitre du maître d'hôtel (face à l'ascenseur), le cordon de velours
	_bx("in_bois", cx1 + 3.2, cx1 + 3.8, 0.0, 1.15, cm - 0.4, cm + 0.4, true)
	b.box("in_cuir", Transform3D(Basis(Vector3(0, 0, 1), 0.3), _p(cx1 + 3.5, 1.2, cm)), Vector3(0.6, 0.04, 0.7))
	b.box("peinture_blanche", Transform3D(Basis(Vector3(0, 0, 1), 0.3), _p(cx1 + 3.5, 1.225, cm)), Vector3(0.5, 0.01, 0.6))
	_gens("homme", cx1 + 4.4, cm, Vector3(-1, 0, 0), "comptoir", L_MAITRE, false, true)
	_potelet(cx1 + 3.5, cm - 1.2)
	_potelet(cx1 + 3.5, cm - 2.6)
	_cordon(cx1 + 3.5, cm - 1.2, cx1 + 3.5, cm - 2.6)
	# ---- les tables nappées (au nord et au sud) ; les convives
	var n_t: int = 0
	for tq in [[4.0, 1.9, 2], [8.0, 2.6, 4], [16.0, 2.4, 2], [24.0, 2.4, 4], [32.0, 2.4, 2], [39.0, 2.6, 4], [3.5, 16.2, 4], [8.5, 18.2, 2], [13.5, 16.0, 4], [30.5, 15.8, 4], [35.5, 18.0, 2], [39.5, 15.4, 2]]:
		_table_nappe(tq[0], tq[1], tq[2])
		if n_t in [1, 3, 6, 9]:
			_gens("femme" if n_t % 2 == 1 else "homme", float(tq[0]) + 0.98, tq[1], Vector3(-1, 0, 0), "assis", L_CORBEILLE, false, n_t == 1)
			_gens("homme" if n_t % 2 == 1 else "femme", float(tq[0]) - 0.98, tq[1], Vector3(1, 0, 0), "assis", L_CORBEILLE)
		n_t += 1
	# ---- le bar (contre le mur de l'ouest) : le comptoir de marbre, les tabourets, le mur de bouteilles
	_bx("in_bois", 1.6, 2.2, 0.0, 1.08, cz0 - 1.0, cz1 + 1.0, true)
	_bx("in_marbre_noir", 1.5, 2.35, 1.08, 1.12, cz0 - 1.1, cz1 + 1.1)
	_bx("k189_or", 2.2, 2.215, 0.2, 0.26, cz0 - 1.0, cz1 + 1.0)
	_bx("in_bois", 0.3, 0.7, 0.0, hc - 0.2, cz0 - 1.0, cz1 + 1.0, true)
	for niv in range(4):
		_bx("k189_bronze", 0.7, 0.95, 1.1 + niv * 0.42, 1.13 + niv * 0.42, cz0 - 0.9, cz1 + 0.9)
		var bz: float = cz0 - 0.8
		while bz < cz1 + 0.8:
			b.cyl_at(["verre_fume", "rouge_laque", "tissu_vert", "k189_or", "verre"][rng.randi() % 5], _p(0.83, 1.13 + niv * 0.42, bz), 0.035, 0.04, rng.randf_range(0.2, 0.3), 7)
			bz += rng.randf_range(0.11, 0.2)
	for i in range(5):
		var sz: float = cz0 - 0.4 + i * 1.5
		b.cyl_at("k189_or", _p(2.9, 0.0, sz), 0.16, 0.16, 0.02, 12)
		b.cyl_at("k189_or", _p(2.9, 0.0, sz), 0.025, 0.025, 0.7, 6)
		b.cyl_at("in_cuir", _p(2.9, 0.7, sz), 0.18, 0.18, 0.06, 14)
		b.cyl_at("verre", _p(1.95, 1.12, sz + 0.2), 0.03, 0.025, 0.11, 8)
	_gens("femme", 1.15, cm, Vector3(1, 0, 0), "comptoir", L_CORBEILLE, false, true)
	# ---- l'estrade et le piano à queue (au nord-est) ; le pianiste
	var ex: float = W - 5.5
	b.cyl_at("in_bois", _p(ex, 0.0, 5.6), 2.6, 2.6, 0.2, 28)
	b.cyl_at("k189_or", _p(ex, 0.2, 5.6), 2.62, 2.62, 0.02, 28)
	var po: Vector3 = _p(ex + 0.3, 0.2, 5.4)
	b.box("in_noir", Transform3D(Basis(), po + Vector3(0, 0.82, 0.0)), Vector3(1.5, 0.3, 1.3))
	b.blob("in_noir", po + Vector3(0, 0.82, -1.0), Vector3(0.75, 0.15, 0.9), 12)
	b.box("in_noir", Transform3D(Basis(Vector3(0, 0, 1), 0.5), po + Vector3(0.45, 1.3, -0.5)), Vector3(1.5, 0.03, 2.0))
	b.tube("k189_or", po + Vector3(0.6, 0.98, -0.3), po + Vector3(0.95, 1.5, -0.3), 0.012, 5)
	b.box("peinture_blanche", Transform3D(Basis(), po + Vector3(0, 0.9, 0.72)), Vector3(1.3, 0.03, 0.16))
	for i2 in range(18):
		if i2 % 7 != 2 and i2 % 7 != 6:
			b.box("in_noir", Transform3D(Basis(), po + Vector3(-0.61 + i2 * 0.072, 0.925, 0.68)), Vector3(0.035, 0.02, 0.09))
	for lg in [[-0.65, 0.5], [0.65, 0.5], [0.0, -1.6]]:
		b.cyl_at("in_noir", po + Vector3(lg[0], 0.0, lg[1]), 0.05, 0.07, 0.68, 8)
		b.cyl_at("k189_or", po + Vector3(lg[0], 0.0, lg[1]), 0.05, 0.05, 0.06, 8)
	_bx("in_cuir", ex - 0.1, ex + 0.7, 0.6, 0.7, 6.7, 7.1, true)
	for bq in [[ex, 6.75], [ex + 0.6, 6.75], [ex, 7.05], [ex + 0.6, 7.05]]:
		b.cyl_at("in_noir", _p(bq[0], 0.2, bq[1]), 0.02, 0.02, 0.4, 5)
	T._col(po + Vector3(0, 0.6, -0.5), Vector3(1.6, 1.2, 2.6))
	_gens("homme", ex + 0.3, 6.9, Vector3(0, 0, -1), "assis", L_CORBEILLE, false, true)
	# ---- la cave (sur le cœur, au nord) : le casier à bouteilles
	_bx("in_bois", cx0 + 0.3, cx1 - 0.3, 0.0, 2.6, cz0 - 0.08, cz0)
	T._col(_p(mxc, 1.3, cz0 - 0.2), Vector3(cx1 - cx0 - 0.6, 2.6, 0.4))
	for mt in range(14):
		_bx("in_bois", cx0 + 0.3 + mt * (cx1 - cx0 - 0.64) / 13.0, cx0 + 0.34 + mt * (cx1 - cx0 - 0.64) / 13.0, 0.0, 2.6, cz0 - 0.4, cz0 - 0.08)
	for r in range(7):
		_bx("in_bois", cx0 + 0.3, cx1 - 0.3, 0.3 + r * 0.33, 0.32 + r * 0.33, cz0 - 0.4, cz0 - 0.08)
		for c in range(26):
			if (r * 5 + c * 3) % 7 != 0:
				b.cyl(["tissu_vert", "rouge_laque", "k189_vert", "in_noir"][(r + c) % 4], Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), _p(cx0 + 0.55 + c * 0.32, 0.39 + r * 0.33, cz0 - 0.27)), 0.05, 0.05, 0.3, 8)
	_texte("LA CAVE", 30, Color(1.0, 0.82, 0.45), _p(mxc, 2.8, cz0 - 0.42), Vector3(0, 0, -1))
	# ---- la desserte des desserts, l'addition de trois mètres, le serveur
	_bx("k189_or", 20.4, 21.8, 0.0, 0.04, 14.3, 15.0)
	_bx("in_marbre_blanc", 20.4, 21.8, 0.85, 0.89, 14.3, 15.0, true)
	_bx("in_marbre_blanc", 20.4, 21.8, 0.4, 0.43, 14.3, 15.0)
	for cq in [[20.42, 14.32], [21.78, 14.32], [20.42, 14.98], [21.78, 14.98]]:
		b.cyl_at("k189_or", _p(cq[0], 0.0, cq[1]), 0.015, 0.015, 0.89, 5)
	for i3 in range(4):
		b.cyl_at(["sakura", "peinture_blanche", "in_bois", "tissu_jaune"][i3], _p(20.65 + i3 * 0.3, 0.89, 14.65), 0.1, 0.1, 0.07, 12)
		b.blob("plastique_rouge", _p(20.65 + i3 * 0.3, 0.98, 14.65), Vector3(0.02, 0.02, 0.02), 5)
	b.blob("verre", _p(21.5, 0.89, 14.5), Vector3(0.16, 0.2, 0.16), 10)
	_gens("homme", 22.6, 15.6, Vector3(-1, 0, 0), "debout", L_SERVEUR9, true, true)
	for i4 in range(10):
		b.box("peinture_blanche", Transform3D(Basis(Vector3(1, 0, 0), sin(i4 * 0.8) * 0.15), _p(14.12, 0.78 - i4 * 0.07, 16.3 + i4 * 0.02)), Vector3(0.12, 0.004, 0.09))
	_plante_pot(W - 0.9, 0.9, 1.5)
	_plante_pot(W - 0.9, D - 0.9, 1.5, true)
	_plante_pot(0.9, D - 0.9, 1.5)
	_plante_pot(0.9, 0.9, 1.4, true)
	return ""


## Une table ronde nappée de blanc : la nappe jusqu'au sol, les assiettes cerclées d'or, les verres, la bougie.
func _table_nappe(lx: float, lz: float, n: int) -> void:
	b.cyl_at("peinture_blanche", _p(lx, 0.02, lz), 0.62, 0.7, 0.74, 20)
	b.cyl_at("peinture_blanche", _p(lx, 0.76, lz), 0.72, 0.72, 0.015, 20)
	T._col(_p(lx, 0.4, lz), Vector3(1.3, 0.8, 1.3))
	b.cyl_at("k189_or", _p(lx, 0.775, lz), 0.05, 0.03, 0.02, 8)
	b.cyl_at("peinture_blanche", _p(lx, 0.795, lz), 0.012, 0.012, 0.16, 5)
	b.blob("lampe_chaude", _p(lx, 0.98, lz), Vector3(0.015, 0.03, 0.015), 5)
	for i in range(n):
		var a: float = i * TAU / n
		T._chaise(b, _p(lx + cos(a) * 1.05, 0.0, lz + sin(a) * 1.05), Vector3(-cos(a), 0, -sin(a)))
		b.cyl_at("k189_or", _p(lx + cos(a) * 0.45, 0.775, lz + sin(a) * 0.45), 0.15, 0.15, 0.006, 14)
		b.cyl_at("peinture_blanche", _p(lx + cos(a) * 0.45, 0.781, lz + sin(a) * 0.45), 0.13, 0.13, 0.006, 14)
		b.cyl_at("verre", _p(lx + cos(a + 0.5) * 0.5, 0.775, lz + sin(a + 0.5) * 0.5), 0.03, 0.02, 0.12, 7)


# ------------------------------------------------------------------ le 4e : la comptabilité
func _compta() -> String:
	var q: Array = _coeur()
	var cx0: float = q[0]
	var cx1: float = q[1]
	var cz0: float = q[2]
	var cz1: float = q[3]
	var cm: float = (cz0 + cz1) * 0.5
	var mxc: float = (cx0 + cx1) * 0.5
	_colonnes()
	_plafond()
	_lustre(34.0, cm, 0.9)
	_lustre(8.5, cm, 0.9)
	# ---- les pupitres des comptables (au nord, deux rangs) : la machine à calculer, le rouleau, les piles, la lampe verte
	var n: int = 0
	for rz in [2.0, 5.7]:
		for i in range(9):
			var px: float = 3.0 + i * 4.4
			if absf(px - 20.0) < 1.2 or (rz > 5.0 and px > cx1 + 0.4 and px < cx1 + 3.0):
				n += 1
				continue
			_bx("in_bois", px - 0.9, px + 0.9, 0.72, 0.78, rz - 0.4, rz + 0.4, true)
			for sx in [-0.85, 0.85]:
				_bx("in_bois", px + sx - 0.04, px + sx + 0.04, 0.0, 0.72, rz - 0.38, rz + 0.38)
			_bx("tissu_vert", px - 0.4, px + 0.4, 0.78, 0.785, rz - 0.3, rz + 0.3)
			_bx("in_noir", px - 0.75, px - 0.5, 0.78, 0.9, rz - 0.2, rz + 0.1)                   # (la machine à calculer, son rouleau)
			b.box("in_noir", Transform3D(Basis(Vector3(1, 0, 0), 0.5), _p(px - 0.62, 0.94, rz - 0.02)), Vector3(0.22, 0.02, 0.2))
			b.tube("peinture_blanche", _p(px - 0.62, 0.92, rz - 0.22), _p(px - 0.62, 0.79, rz - 0.36), 0.035, 6)
			for j in range(6):
				b.box("peinture_blanche", Transform3D(Basis(Vector3(1, 0, 0), 0.2 * sin(j * 1.1)), _p(px - 0.62, 0.72 - j * 0.11, rz - 0.42 - (j % 2) * 0.02)), Vector3(0.07, 0.12, 0.003))
			var ph: float = 0.1 + ((n * 7) % 5) * 0.12
			_bx("peinture_blanche", px + 0.4, px + 0.7, 0.78, 0.78 + ph, rz - 0.25, rz + 0.15)
			_bx("in_cuir", px + 0.1, px + 0.36, 0.78, 0.84, rz - 0.3, rz + 0.1)
			b.cyl_at("k189_or", _p(px + 0.7, 0.78, rz + 0.3), 0.05, 0.05, 0.015, 8)
			b.cyl_at("k189_or", _p(px + 0.7, 0.78, rz + 0.3), 0.01, 0.01, 0.24, 5)
			b.box("tissu_vert", Transform3D(Basis(), _p(px + 0.7, 1.05, rz + 0.3)), Vector3(0.22, 0.06, 0.1))
			T._chaise(b, _p(px, 0.0, rz + 0.8), Vector3(0, 0, -1))
			if n % 3 != 2:
				_gens("homme" if n % 2 == 0 else "femme", px, rz + 0.8, Vector3(0, 0, -1), "assis", L_COMPTA, false, n == 0)
			n += 1
	# ---- la machine à compter les pièces (au sud) : la trémie, le tapis où roulent les pièces, les tubes, les sacs
	var m0: float = 9.0
	var mz: float = 16.6
	_bx("k189_bronze", m0, m0 + 2.0, 0.0, 1.5, mz - 0.9, mz + 0.9, true)
	b.cyl_at("k189_or", _p(m0 + 1.0, 1.5, mz), 0.5, 1.0, 0.8, 16)
	b.cyl_at("k189_or", _p(m0 + 1.0, 2.28, mz), 0.95, 0.95, 0.02, 16)
	for i2 in range(14):
		b.cyl("k189_or", Transform3D(Basis(Vector3(1, 0, 0), rng.randf_range(-0.6, 0.6)) * Basis(Vector3(0, 0, 1), rng.randf_range(-0.6, 0.6)), _p(m0 + 1.0 + rng.randf_range(-0.6, 0.6), 2.3 + (i2 % 3) * 0.03, mz + rng.randf_range(-0.6, 0.6))), 0.09, 0.09, 0.014, 10)
	_bx("in_inox", m0 + 2.0, m0 + 10.0, 0.86, 0.92, mz - 0.25, mz + 0.25, true)
	_bx("plastique_noir", m0 + 2.0, m0 + 10.0, 0.92, 0.935, mz - 0.2, mz + 0.2)
	for sg in [-0.23, 0.23]:
		_bx("k189_bronze", m0 + 2.0, m0 + 10.0, 0.92, 0.99, mz + sg - 0.02, mz + sg + 0.02)
	var lx2: float = m0 + 2.4
	while lx2 < m0 + 10.0:
		_bx("in_inox", lx2 - 0.04, lx2 + 0.04, 0.0, 0.86, mz - 0.22, mz + 0.22)
		lx2 += 1.9
	var lotp := Kit.Batch.new()
	lotp.cyl("k189_or", Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), Vector3(0, 0.09, 0)), 0.09, 0.09, 0.016, 12)
	var mp: ArrayMesh = _maillage(lotp)
	for i3 in range(16):
		var pm := MeshInstance3D.new()
		pm.mesh = mp
		_anime().add_child(pm)
		_anime().tapis.append([pm, _p(m0 + 2.1, 0.935, mz + (i3 % 3 - 1) * 0.1), Vector3(1, 0, 0), 7.8, float(i3) / 16.0, 0.7])
	for i4 in range(4):                               # (les quatre tubes de tri, leurs sacs)
		var tx: float = m0 + 4.0 + i4 * 1.8
		b.tube("verre", _p(tx, 0.92, mz + 0.25), _p(tx, 0.45, mz + 0.9), 0.07, 8)
		b.cyl_at("k189_or", _p(tx, 0.9, mz + 0.27), 0.08, 0.08, 0.04, 8)
		_sac(tx, 0.0, mz + 1.0, 1.3)
		_sac(tx + 0.45, 0.0, mz + 1.25, 1.1)
	_bx("k189_bronze", m0 + 10.0, m0 + 10.8, 0.0, 0.8, mz - 0.5, mz + 0.5, true)
	for i5 in range(9):
		_sac(m0 + 11.4 + (i5 % 3) * 0.42, 0.3 if i5 >= 6 else 0.0, mz - 0.4 + (i5 % 2) * 0.4, 1.2)
	_bx("in_noir", m0 + 0.3, m0 + 1.7, 0.9, 1.3, mz - 0.92, mz - 0.9)
	_texte("9 000 000 041", 22, Color(0.4, 1.0, 0.55), _p(m0 + 1.0, 1.1, mz - 0.93), Vector3(0, 0, -1))
	_texte("pièces comptées (à une près)", 13, Color(1.0, 0.85, 0.5), _p(m0 + 1.0, 0.8, mz - 0.91), Vector3(0, 0, -1))
	_gens("homme", m0 + 5.5, mz - 1.2, Vector3(0, 0, 1), "bras_croises", L_COMPTA, false, true)
	# ---- le grand boulier (à l'ouest, contre le cœur) : son cadre, ses tringles, ses boules
	var b0: float = cz0 + 0.3
	var b1: float = cz1 - 0.3
	_bx("in_bois", cx0 - 0.2, cx0, 0.5, 0.62, b0, b1)
	_bx("in_bois", cx0 - 0.2, cx0, 2.5, 2.62, b0, b1)
	_bx("in_bois", cx0 - 0.2, cx0, 0.5, 2.62, b0 - 0.12, b0)
	_bx("in_bois", cx0 - 0.2, cx0, 0.5, 2.62, b1, b1 + 0.12)
	for r in range(7):
		var hh: float = 0.82 + r * 0.26
		b.tube("k189_or", _p(cx0 - 0.1, hh, b0), _p(cx0 - 0.1, hh, b1), 0.012, 5)
		var gauche: int = (r * 3 + 2) % 7 + 1
		for k in range(10):
			var kz: float = b0 + 0.15 + k * 0.2 if k < gauche else b1 - 0.15 - (9 - k) * 0.2
			b.blob(["plastique_rouge", "k189_or", "tissu_vert", "plastique_bleu", "in_noir", "k187_orange", "peinture_blanche"][r], _p(cx0 - 0.1, hh, kz), Vector3(0.09, 0.1, 0.09), 8)
	_texte("En cas de panne.", 18, Color(1.0, 0.85, 0.5), _p(cx0 - 0.21, 0.35, cm), Vector3(-1, 0, 0))
	# ---- le centime de 2091 (à l'ouest) : sa vitrine vide, son coussin, l'avis de recherche
	_bx("in_marbre_noir", 4.2, 5.0, 0.0, 1.0, cm - 0.4, cm + 0.4, true)
	_bx("tissu_rouge", 4.4, 4.8, 1.0, 1.05, cm - 0.2, cm + 0.2)
	_bx("in_vitre", 4.25, 4.95, 1.0, 1.45, cm - 0.35, cm + 0.35)
	_texte("Le centime de 2091", 22, Color(1.0, 0.85, 0.5), _p(5.02, 0.7, cm), Vector3(1, 0, 0))
	_texte("Emplacement réservé.", 15, Color(0.95, 0.92, 0.85), _p(5.02, 0.5, cm), Vector3(1, 0, 0))
	for i6 in range(4):
		_potelet(4.6 + [-1.3, 1.3, 1.3, -1.3][i6], cm + [-1.2, -1.2, 1.2, 1.2][i6])
	_cordon(3.3, cm - 1.2, 5.9, cm - 1.2)
	_cordon(3.3, cm + 1.2, 5.9, cm + 1.2)
	_cordon(3.3, cm - 1.2, 3.3, cm + 1.2)
	_gens("femme", 7.0, cm + 0.4, Vector3(-1, 0, 0), "debout", L_CHEF_COMPTA, false, true)
	# ---- les registres (au sud-est) : les rayons de grands livres, l'échelle, les tours de papier
	for niv in range(5):
		_bx("in_bois", W - 12.0, W - 0.6, 0.2 + niv * 0.5, 0.24 + niv * 0.5, D - 0.85, D - 0.4)
		var lxb: float = W - 11.9
		while lxb < W - 0.8:
			var wb: float = rng.randf_range(0.07, 0.13)
			if rng.randf() < 0.9:
				_bx(["k189_vert", "k189_bronze", "in_tissu_rouge", "in_noir"][rng.randi() % 4], lxb, lxb + wb, 0.24 + niv * 0.5, 0.24 + niv * 0.5 + rng.randf_range(0.34, 0.44), D - 0.8, D - 0.5)
				_bx("k189_or", lxb, lxb + wb, 0.34 + niv * 0.5, 0.36 + niv * 0.5, D - 0.81, D - 0.8)
			lxb += wb + 0.008
	for pxx in [W - 12.0, W - 8.2, W - 4.4, W - 0.6]:
		_bx("in_bois", pxx - 0.03, pxx + 0.03, 0.0, 2.75, D - 0.87, D - 0.4)
	T._col(_p(W - 6.3, 1.3, D - 0.62), Vector3(11.5, 2.7, 0.5))
	for i7 in range(8):
		var tx2: float = W - 11.0 + rng.randf_range(0.0, 9.0)
		var tz2: float = D - 2.2 - rng.randf_range(0.0, 1.6)
		var th: float = rng.randf_range(0.4, 1.5)
		_bx("peinture_blanche", tx2 - 0.16, tx2 + 0.16, 0.012, th, tz2 - 0.22, tz2 + 0.22, true)
		_bx("in_cuir", tx2 - 0.17, tx2 + 0.17, th, th + 0.05, tz2 - 0.23, tz2 + 0.23)
	_plante_pot(W - 0.9, 0.9, 1.4)
	_plante_pot(0.9, D - 0.9, 1.4, true)
	return ""



## Un objet qui bouge : un lot fabriqué autour de zéro, posé « at » ; on le range ensuite dans tapis, tourne, flotte.
func _mobile(lot: Kit.Batch, at: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _maillage(lot)
	_anime().add_child(mi)
	mi.global_position = at
	return mi


func _lueur(lx: float, h: float, lz: float, couleur: Color, force: float, portee: float) -> void:
	var o := OmniLight3D.new()
	o.light_color = couleur
	o.light_energy = force
	o.omni_range = portee
	(T.get("_node") as Node3D).add_child(o)
	o.global_position = _p(lx, h, lz)


# ------------------------------------------------------------------ le 5e : le grand livre (les serveurs)
func _livre() -> String:
	var q: Array = _coeur()
	var cx0: float = q[0]
	var cx1: float = q[1]
	var cz0: float = q[2]
	var cz1: float = q[3]
	var cm: float = (cz0 + cz1) * 0.5
	if not Kit._mcache.has("k188_baie"):
		var bm := ShaderMaterial.new()
		bm.shader = load("res://shaders/baie_v188.gdshader")
		Kit._mcache["k188_baie"] = bm
	# la pénombre dorée des machines
	for ch in (T.get("_node") as Node3D).get_children():
		if ch is OmniLight3D:
			(ch as OmniLight3D).light_energy *= 0.3
			(ch as OmniLight3D).light_color = Color(1.0, 0.75, 0.45)
	_bx("in_noir", 0.3, W - 0.3, hc - 0.09, hc - 0.07, 0.3, D - 0.3)
	_colonnes(true)
	# ---- les baies (au nord et au sud, en travées) : le bronze, les voyants, les câbles d'or au plafond
	for rz in [1.6, D - 1.6, D - 4.6]:
		var x0: float = 1.2
		while x0 < W - 4.0:
			var x1: float = x0 + 0.62 * 5.0
			var libre: bool = true
			for p in T.info.get("piliers", []):
				if absf((p as Vector2).y - Z0 - rz) < 1.2 and (p as Vector2).x - X0 > x0 - 0.7 and (p as Vector2).x - X0 < x1 + 0.7:
					libre = false
			if libre and not (rz > D - 6.0 and rz < D - 3.0 and x0 < 14.0):
				_bx("in_rack", x0, x1, 0.0, 2.1, rz - 0.45, rz + 0.45, true)
				_quad("k188_baie", _p((x0 + x1) * 0.5, 1.05, rz - 0.455), Vector3(0, 0, -1), x1 - x0, 2.0, Vector2(5, 1))
				_quad("k188_baie", _p((x0 + x1) * 0.5, 1.05, rz + 0.455), Vector3(0, 0, 1), x1 - x0, 2.0, Vector2(5, 1))
				_bx("k189_bronze", x0 - 0.03, x1 + 0.03, 2.1, 2.16, rz - 0.48, rz + 0.48)
				_bx("k189_or", x0 - 0.03, x0, 0.0, 2.1, rz - 0.47, rz + 0.47)
				_bx("k189_or", x1, x1 + 0.03, 0.0, 2.1, rz - 0.47, rz + 0.47)
				b.tube("k189_or", _p((x0 + x1) * 0.5, 2.16, rz), _p((x0 + x1) * 0.5, hc - 0.4, rz), 0.03, 6)
			x0 += 0.62 * 5.0 + 1.3
		for i in range(3):
			b.tube(["k189_or", "k189_bronze", "k187_orange"][i], _p(1.0, hc - 0.4 + i * 0.05, rz - 0.1 + i * 0.1), _p(W - 1.0, hc - 0.4 + i * 0.05, rz - 0.1 + i * 0.1), 0.025, 5)
	# ---- le Grand Livre (à l'est, face à l'ascenseur) : l'estrade, le pupitre, le livre ouvert, la plume qui écrit
	var gx: float = W - 8.0
	b.cyl_at("in_marbre_noir", _p(gx, 0.0, cm), 3.0, 3.0, 0.18, 32)
	b.cyl_at("k189_or", _p(gx, 0.18, cm), 3.02, 3.02, 0.02, 32)
	_bx("k189_bronze", gx - 0.5, gx + 0.5, 0.2, 0.95, cm - 1.0, cm + 1.0, true)
	b.box("in_bois", Transform3D(Basis(Vector3(0, 0, 1), -0.35), _p(gx - 0.1, 1.08, cm)), Vector3(1.5, 0.08, 2.9))
	for sg in [-1.0, 1.0]:
		b.box("in_cuir", Transform3D(Basis(Vector3(0, 0, 1), -0.35), _p(gx - 0.12, 1.14, cm + sg * 0.68)), Vector3(1.3, 0.05, 1.32))
		for pg in range(5):
			b.box("peinture_blanche", Transform3D(Basis(Vector3(0, 0, 1), -0.35) * Basis(Vector3(1, 0, 0), sg * (0.03 + pg * 0.012)), _p(gx - 0.13 - pg * 0.004, 1.18 + pg * 0.012, cm + sg * 0.66)), Vector3(1.22, 0.012, 1.24))
		for lg in range(9):
			var fx: float = 0.45 - lg * 0.11
			b.box("in_noir", Transform3D(Basis(Vector3(0, 0, 1), -0.35), _p(gx - 0.14 + fx * cos(0.35), 1.245 - fx * sin(0.35), cm + sg * 0.66)), Vector3(0.012, 0.004, 0.9 if (lg + int(sg)) % 4 != 0 else 0.5))
	b.box("tissu_rouge", Transform3D(Basis(Vector3(0, 0, 1), -0.35), _p(gx - 0.2, 1.21, cm)), Vector3(1.5, 0.01, 0.06))
	var lotq := Kit.Batch.new()
	lotq.tube("peinture_blanche", Vector3(0, 0, 0), Vector3(0.12, 0.5, 0.05), 0.012, 5)
	lotq.blob("peinture_blanche", Vector3(0.1, 0.38, 0.04), Vector3(0.05, 0.2, 0.012), 6)
	lotq.tube("k189_or", Vector3(0, 0, 0), Vector3(0.03, 0.12, 0.012), 0.016, 5)
	var plume: MeshInstance3D = _mobile(lotq, _p(gx - 0.25, 1.24, cm + 0.5))
	_anime().tapis.append([plume, _p(gx - 0.25, 1.24, cm + 0.25), Vector3(0, 0, 1), 0.85, 0.0, 0.12])
	for a in range(6):
		_potelet(gx + cos(a * TAU / 6.0 + 0.52) * 2.3, cm + sin(a * TAU / 6.0 + 0.52) * 2.3)
	for a2 in [0, 1, 2, 4, 5]:
		_cordon(gx + cos(a2 * TAU / 6.0 + 0.52) * 2.3, cm + sin(a2 * TAU / 6.0 + 0.52) * 2.3, gx + cos((a2 + 1) * TAU / 6.0 + 0.52) * 2.3, cm + sin((a2 + 1) * TAU / 6.0 + 0.52) * 2.3)
	b.cyl_at("k189_bronze", _p(gx, hc - 0.5, cm), 0.5, 0.2, 0.42, 14)
	b.cyl_at("lampe_chaude", _p(gx, hc - 0.52, cm), 0.42, 0.42, 0.02, 14)
	_lueur(gx, hc - 1.0, cm, Color(1.0, 0.86, 0.6), 2.4, 6.0)
	_texte("LE GRAND LIVRE", 40, Color(1.0, 0.82, 0.45), _p(W - 0.42, 2.5, cm), Vector3(-1, 0, 0))
	_texte("Chaque pièce de l'archipel, depuis 1893.", 20, Color(0.95, 0.9, 0.8), _p(W - 0.42, 2.15, cm), Vector3(-1, 0, 0))
	_gens("femme", gx - 2.0, cm + 1.9, Vector3(1, 0, -0.5), "debout", L_LIVRE, false, true)
	_gens("homme", gx + 0.4, cm - 3.6, Vector3(-0.2, 0, 1), "bras_croises", L_LIVRE)
	# ---- les bandes (à l'ouest, sur le cœur) : les armoires, leurs bobines qui tournent
	for i2 in range(4):
		var az: float = cz0 + 0.75 + i2 * 1.27
		if absf(az - cm) < 0.9:
			continue
		_bx("k189_bronze", cx0 - 0.5, cx0, 0.0, 2.2, az - 0.5, az + 0.5, true)
		_bx("in_noir", cx0 - 0.52, cx0 - 0.5, 1.05, 2.05, az - 0.42, az + 0.42)
		for bh in [1.35, 1.8]:
			var lotb := Kit.Batch.new()
			lotb.cyl("k189_or", Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), Vector3.ZERO), 0.17, 0.17, 0.03, 16)
			for sp in range(3):
				lotb.box("in_noir", Transform3D(Basis(Vector3(0, 0, 1), sp * TAU / 3.0), Vector3(0, 0, 0.018)), Vector3(0.05, 0.3, 0.004))
			var bob: MeshInstance3D = _mobile(lotb, _p(cx0 - 0.54, bh, az))
			bob.rotation.y = -PI * 0.5
			_anime().vrille.append([bob, 1.6 if bh < 1.5 else -1.1])
		for v in range(6):
			b.blob(["neon_cyan", "lampe_chaude", "neon_rouge"][(v + i2) % 3], _p(cx0 - 0.52, 0.8, az - 0.35 + v * 0.14), Vector3(0.018, 0.018, 0.018), 5)
	# ---- le pupitre du veilleur (au sud-ouest) : trois écrans, le thermomètre, le pull sur la chaise
	_bx("in_bois", 4.0, 7.6, 0.0, 0.78, D - 5.2, D - 4.3, true)
	_bx("in_marbre_noir", 3.95, 7.65, 0.78, 0.82, D - 5.25, D - 4.25)
	for i3 in range(3):
		_bx("in_noir", 4.3 + i3 * 1.1, 5.2 + i3 * 1.1, 0.9, 1.5, D - 4.6, D - 4.57)
		_bx(["in_ecran_ui_code", "in_ecran_ui_graphes", "in_ecran_ui_messages"][i3], 4.33 + i3 * 1.1, 5.17 + i3 * 1.1, 0.93, 1.47, D - 4.63, D - 4.6)
	T._chaise(b, _p(5.8, 0.0, D - 5.9), Vector3(0, 0, 1))
	b.box("in_tissu_rouge", Transform3D(Basis(Vector3(0, 0, 1), 0.2), _p(7.2, 0.86, D - 4.8)), Vector3(0.5, 0.08, 0.4))
	_gens("homme", 5.8, D - 5.9, Vector3(0, 0, 1), "assis", L_TECH9, false, true)
	_gens("femme", 11.5, D - 3.1, Vector3(0, 0, 1), "debout", L_TECH9)
	_bx("peinture_blanche", 0.42, 0.46, 1.2, 2.2, cm - 0.1, cm + 0.1)
	_bx("plastique_bleu", 0.46, 0.47, 1.25, 1.55, cm - 0.03, cm + 0.03)
	_texte("12 °", 30, Color(0.5, 0.85, 1.0), _p(0.47, 2.4, cm), Vector3(1, 0, 0))
	return ""


# ------------------------------------------------------------------ le 6e : la sécurité
func _securite() -> String:
	var q: Array = _coeur()
	var cx0: float = q[0]
	var cx1: float = q[1]
	var cz0: float = q[2]
	var cz1: float = q[3]
	var cm: float = (cz0 + cz1) * 0.5
	_colonnes()
	_plafond("in_mur_gris", false)
	# ---- le mur des cent écrans (à l'est) et son pupitre en arc
	_bx("in_noir", W - 0.6, W - 0.42, 0.5, hc - 0.2, cm - 5.2, cm + 5.2)
	for r in range(5):
		for c in range(20):
			var ez: float = cm - 4.95 + c * 0.52
			var cle: String = ["in_noir", "in_ecran_ui_graphes", "metal_noir", "in_ecran_vert", "in_noir", "in_ecran_ui_code", "metal_noir"][(r * 5 + c * 3) % 7]
			_bx(cle, W - 0.63, W - 0.6, 0.62 + r * 0.44, 1.0 + r * 0.44, ez - 0.23, ez + 0.23)
	_texte("PIGEON", 14, Color(1.0, 0.4, 0.3), _p(W - 0.65, 2.42, cm + 2.36), Vector3(-1, 0, 0))
	for i in range(5):
		var a: float = (i - 2) * 0.42
		var px: float = W - 6.2 + (1.0 - cos(a)) * 3.0
		var pz: float = cm + sin(a) * 5.4
		var bs := Basis(Vector3.UP, -a)
		b.box("metal_noir", Transform3D(bs, _p(px, 0.45, pz)), Vector3(0.8, 0.9, 2.1))
		b.box("in_inox", Transform3D(bs * Basis(Vector3(0, 0, 1), -0.25), _p(px, 0.95, pz)), Vector3(0.85, 0.05, 2.1))
		T._col(_p(px, 0.5, pz), Vector3(0.9, 1.0, 2.0), -a)
		for v in range(8):
			b.blob(["neon_rouge", "neon_cyan", "lampe_chaude", "tissu_vert"][v % 4], _p(px, 1.0, pz) + bs * Vector3(0.1 + (v % 2) * 0.15, 0.0, -0.8 + v * 0.22), Vector3(0.025, 0.02, 0.025), 5)
		if i % 2 == 0:
			_gens("homme", px - 1.0 - (1.0 - cos(a)) * 0.2, pz + sin(a) * 0.9, Vector3(1, 0, -sin(a) * 0.4), "debout", L_SECU, true, i == 2)
	# ---- le couloir d'entraînement (au nord) : les rayons rouges, et la pièce au bout, sur son coussin
	_bx("in_mur_gris", 3.0, 3.1, 0.0, hc - 0.1, 0.5, 3.2, true)
	_bx("in_mur_gris", 15.0, 15.1, 0.0, hc - 0.1, 0.5, 3.2, true)
	_bx("in_cloison_verre", 3.1, 8.0, 0.0, hc - 0.1, 3.18, 3.22, true)
	_bx("in_cloison_verre", 9.4, 15.0, 0.0, hc - 0.1, 3.18, 3.22, true)
	_bx("in_noir", 3.1, 15.0, 0.012, 0.02, 0.5, 3.2)
	for i2 in range(11):
		var rx: float = 4.4 + i2 * 0.9
		var h0: float = 0.25 + ((i2 * 5) % 7) * 0.3
		var h1: float = 0.25 + ((i2 * 3 + 2) % 7) * 0.3
		b.tube("neon_rouge", _p(rx, h0, 0.55), _p(rx + 0.3, h1, 3.15), 0.009, 4)
		b.blob("metal_noir", _p(rx, h0, 0.55), Vector3(0.04, 0.04, 0.04), 5)
	_lueur(9.0, 1.4, 1.9, Color(1.0, 0.25, 0.2), 1.2, 5.0)
	_bx("in_marbre_noir", 3.5, 4.1, 0.0, 0.9, 1.6, 2.2, true)
	_bx("tissu_rouge", 3.6, 4.0, 0.9, 0.96, 1.7, 2.1)
	b.cyl("k189_or", Transform3D(Basis(Vector3(1, 0, 0), 1.2), _p(3.8, 1.02, 1.9)), 0.11, 0.11, 0.02, 14)
	_texte("Entraînement. La pièce est en chocolat.", 16, Color(1.0, 0.85, 0.5), _p(8.7, 2.3, 3.24), Vector3(0, 0, 1))
	_gens("femme", 10.5, 4.6, Vector3(0, 0, -1), "bras_croises", L_CHEF_SECU, false, true)
	# ---- Médor 3000 (au nord-est) : le chien de garde, sa niche, sa gamelle de boulons
	var mx: float = 31.5
	_bx("metal_noir", mx - 1.4, mx + 1.4, 0.0, 1.5, 0.6, 2.6, true)
	b.box("k189_bronze", Transform3D(Basis(Vector3(0, 0, 1), 0.5), _p(mx - 0.75, 1.82, 1.6)), Vector3(1.8, 0.06, 2.2))
	b.box("k189_bronze", Transform3D(Basis(Vector3(0, 0, 1), -0.5), _p(mx + 0.75, 1.82, 1.6)), Vector3(1.8, 0.06, 2.2))
	_bx("in_noir", mx - 0.7, mx + 0.7, 0.0, 1.1, 2.6, 2.62)
	_texte("MÉDOR 3000", 22, Color(1.0, 0.82, 0.45), _p(mx, 1.3, 2.64), Vector3(0, 0, 1))
	b.box("in_inox", Transform3D(Basis(), _p(mx, 0.35, 3.6)), Vector3(0.7, 0.45, 1.3))                      # (il dort, la tête sur les pattes)
	b.box("in_inox", Transform3D(Basis(Vector3(1, 0, 0), 0.15), _p(mx, 0.28, 4.5)), Vector3(0.5, 0.36, 0.55))
	b.box("metal_noir", Transform3D(Basis(), _p(mx, 0.2, 4.82)), Vector3(0.3, 0.2, 0.2))
	for sg in [-1.0, 1.0]:
		b.box("metal_noir", Transform3D(Basis(Vector3(0, 0, 1), sg * 0.5), _p(mx + sg * 0.22, 0.52, 4.35)), Vector3(0.05, 0.2, 0.16))
		b.box("in_inox", Transform3D(Basis(), _p(mx + sg * 0.3, 0.08, 4.3)), Vector3(0.16, 0.14, 0.7))
		b.blob("in_noir", _p(mx + sg * 0.13, 0.36, 4.78), Vector3(0.035, 0.012, 0.02), 5)
	b.tube("in_inox", _p(mx, 0.5, 2.95), _p(mx + 0.25, 0.75, 2.7), 0.03, 5)
	T._col(_p(mx, 0.3, 3.9), Vector3(0.8, 0.6, 2.0))
	b.cyl_at("in_inox", _p(mx + 1.0, 0.0, 4.3), 0.16, 0.2, 0.1, 10)
	for bo in range(6):
		b.cyl_at("metal_noir", _p(mx + 1.0 + cos(bo * 1.1) * 0.08, 0.08 + (bo % 2) * 0.02, 4.3 + sin(bo * 1.1) * 0.08), 0.025, 0.025, 0.03, 6)
	var lotz := Kit.Batch.new()
	lotz.box("peinture_blanche", Transform3D(Basis(), Vector3.ZERO), Vector3(0.12, 0.02, 0.01))
	lotz.box("peinture_blanche", Transform3D(Basis(Vector3(0, 0, 1), 0.9), Vector3(0, 0.07, 0)), Vector3(0.17, 0.02, 0.01))
	lotz.box("peinture_blanche", Transform3D(Basis(), Vector3(0, 0.14, 0)), Vector3(0.12, 0.02, 0.01))
	for zz in range(3):
		var zn: MeshInstance3D = _mobile(lotz, _p(mx + 0.3, 0.9, 4.6))
		zn.scale = Vector3.ONE * (0.7 + zz * 0.3)
		_anime().tapis.append([zn, _p(mx + 0.2 + zz * 0.15, 0.8, 4.6), Vector3(0.15, 1, 0), 1.3, zz / 3.0, 0.35])
	# ---- les objets confisqués (au sud-est) : les étagères grillagées, chaque objet et son étiquette
	for niv in range(4):
		_bx("in_inox", W - 13.0, W - 3.0, 0.4 + niv * 0.55, 0.43 + niv * 0.55, D - 0.95, D - 0.4)
	for px2 in [W - 13.0, W - 9.7, W - 6.3, W - 3.0]:
		_bx("metal_noir", px2 - 0.025, px2 + 0.025, 0.0, 2.5, D - 0.95, D - 0.4)
	T._col(_p(W - 8.0, 1.2, D - 0.68), Vector3(10.0, 2.4, 0.6))
	var no: int = 0
	for niv2 in range(4):
		var ox: float = W - 12.6
		while ox < W - 3.4:
			var oh: float = 0.43 + niv2 * 0.55
			match no % 7:
				0:                                    # (le pistolet à eau)
					_bx("plastique_bleu", ox - 0.12, ox + 0.12, oh + 0.1, oh + 0.17, D - 0.72, D - 0.66)
					_bx("k187_orange", ox - 0.12, ox - 0.05, oh, oh + 0.1, D - 0.72, D - 0.66)
				1:                                    # (la fausse moustache, sur son socle)
					b.cyl_at("in_bois", _p(ox, oh, D - 0.7), 0.06, 0.07, 0.03, 8)
					b.blob("in_noir", _p(ox - 0.05, oh + 0.09, D - 0.7), Vector3(0.06, 0.025, 0.02), 6)
					b.blob("in_noir", _p(ox + 0.05, oh + 0.09, D - 0.7), Vector3(0.06, 0.025, 0.02), 6)
				2:                                    # (le grappin et sa corde)
					for g in range(3):
						b.tube("in_inox", _p(ox, oh + 0.12, D - 0.7), _p(ox + cos(g * TAU / 3.0) * 0.1, oh + 0.02, D - 0.7 + sin(g * TAU / 3.0) * 0.1), 0.012, 4)
					b.cyl_at("in_bois_clair", _p(ox + 0.2, oh, D - 0.7), 0.09, 0.09, 0.07, 10)
				3:                                    # (le lance-pierres)
					b.tube("in_bois", _p(ox, oh, D - 0.7), _p(ox, oh + 0.14, D - 0.7), 0.014, 5)
					b.tube("in_bois", _p(ox, oh + 0.14, D - 0.7), _p(ox - 0.07, oh + 0.26, D - 0.7), 0.012, 5)
					b.tube("in_bois", _p(ox, oh + 0.14, D - 0.7), _p(ox + 0.07, oh + 0.26, D - 0.7), 0.012, 5)
				4:                                    # (le masque de carnaval)
					b.blob("peinture_blanche", _p(ox, oh + 0.14, D - 0.7), Vector3(0.11, 0.14, 0.03), 8)
					b.blob("in_noir", _p(ox - 0.04, oh + 0.17, D - 0.725), Vector3(0.025, 0.018, 0.01), 5)
					b.blob("in_noir", _p(ox + 0.04, oh + 0.17, D - 0.725), Vector3(0.025, 0.018, 0.01), 5)
				5:                                    # (le sac marqué d'une pièce… rempli de boutons)
					_sac(ox, oh, D - 0.7, 0.9)
				_:                                    # (le parapluie pliant)
					b.tube("in_noir", _p(ox - 0.15, oh + 0.03, D - 0.7), _p(ox + 0.15, oh + 0.03, D - 0.7), 0.03, 6)
					b.tube("in_bois", _p(ox + 0.15, oh + 0.03, D - 0.7), _p(ox + 0.22, oh + 0.03, D - 0.7), 0.012, 5)
			_bx("tissu_jaune", ox - 0.05, ox + 0.05, oh - 0.07, oh - 0.01, D - 0.96, D - 0.955)
			no += 1
			ox += rng.randf_range(0.6, 0.95)
	_texte("OBJETS CONFISQUÉS", 28, Color(1.0, 0.82, 0.45), _p(W - 8.0, 2.75, D - 0.5), Vector3(0, 0, -1))
	_gens("homme", W - 8.0, D - 2.2, Vector3(0, 0, -1), "debout", L_CONFISQUE, false, true)
	# ---- le vestiaire des gardes (au sud-ouest) : les casiers, le banc, les lampes torches en charge
	for i3 in range(10):
		var cxl: float = 1.2 + i3 * 0.75
		_bx("metal_noir" if i3 % 2 == 0 else "in_inox", cxl - 0.35, cxl + 0.35, 0.0, 2.0, D - 0.95, D - 0.4, true)
		_bx("k189_or", cxl + 0.2, cxl + 0.24, 1.0, 1.12, D - 0.97, D - 0.95)
		for f in range(3):
			_bx("in_noir", cxl - 0.2, cxl + 0.2, 1.7 + f * 0.06, 1.72 + f * 0.06, D - 0.96, D - 0.95)
	_bx("in_bois", 1.5, 7.5, 0.42, 0.48, D - 2.4, D - 2.0, true)
	for bq in [1.7, 4.5, 7.3]:
		_bx("metal_noir", bq - 0.03, bq + 0.03, 0.0, 0.42, D - 2.35, D - 2.05)
	_bx("metal_noir", 9.5, 12.5, 1.1, 1.16, D - 0.6, D - 0.4)
	for l in range(7):
		b.cyl_at("in_noir", _p(9.8 + l * 0.4, 1.16, D - 0.5), 0.035, 0.03, 0.22, 7)
		b.cyl_at("lampe_blanche", _p(9.8 + l * 0.4, 1.38, D - 0.5), 0.045, 0.035, 0.03, 7)
		b.blob("tissu_vert" if l != 3 else "neon_rouge", _p(9.8 + l * 0.4, 1.12, D - 0.6), Vector3(0.012, 0.012, 0.012), 4)
	_gens("femme", 5.0, D - 3.0, Vector3(0, 0, -1), "debout", L_SECU, true)
	# ---- la maquette de la tour (à l'ouest) : onze étages de verre, une lampe d'alarme par étage
	_bx("in_marbre_noir", 6.0, 8.0, 0.0, 0.8, cm - 0.7, cm + 0.7, true)
	for e in range(11):
		_bx("in_cloison_verre", 6.3, 7.7, 0.82 + e * 0.13, 0.93 + e * 0.13, cm - 0.4, cm + 0.4)
		_bx("k189_bronze", 6.28, 7.72, 0.93 + e * 0.13, 0.95 + e * 0.13, cm - 0.42, cm + 0.42)
		b.blob("tissu_vert" if e != 8 else "neon_rouge", _p(6.26, 0.88 + e * 0.13, cm), Vector3(0.02, 0.02, 0.02), 5)
	_texte("Étage 8 : quelqu'un ronfle.", 15, Color(1.0, 0.5, 0.4), _p(7.0, 0.55, cm + 0.71), Vector3(0, 0, 1))
	return ""


# ------------------------------------------------------------------ le 8e : le club
func _club() -> String:
	var q: Array = _coeur()
	var cx0: float = q[0]
	var cx1: float = q[1]
	var cz0: float = q[2]
	var cz1: float = q[3]
	var cm: float = (cz0 + cz1) * 0.5
	_colonnes()
	_plafond("in_bois")
	_sol("in_bois")
	for lq in [[8.0, cm], [35.0, cm], [12.0, 16.5], [31.0, 16.5]]:
		_lustre(lq[0], lq[1], 0.8)
	# ---- la cheminée (au mur de l'ouest) : le manteau de marbre, le feu, les deux fauteuils, celui qui dort
	_bx("in_marbre_noir", 0.3, 1.0, 0.0, 1.5, cm - 1.5, cm - 0.9, true)
	_bx("in_marbre_noir", 0.3, 1.0, 0.0, 1.5, cm + 0.9, cm + 1.5, true)
	_bx("in_marbre_noir", 0.3, 1.1, 1.5, 1.75, cm - 1.7, cm + 1.7)
	_bx("in_noir", 0.3, 0.5, 0.0, 1.5, cm - 0.9, cm + 0.9)
	_bx("in_marbre_noir", 0.3, 1.6, 0.0, 0.06, cm - 1.7, cm + 1.7)
	for lg in range(3):
		b.tube("in_bois", _p(0.65, 0.14 + (lg % 2) * 0.1, cm - 0.55), _p(0.75, 0.14 + (lg % 2) * 0.1, cm + 0.55), 0.08, 7)
	for fl in range(7):
		b.blob("lampe_chaude" if fl % 2 == 0 else "k187_orange", _p(0.7, 0.42 + (fl % 3) * 0.1, cm - 0.45 + fl * 0.15), Vector3(0.07, 0.2 + (fl % 3) * 0.07, 0.07), 6)
	_lueur(1.4, 0.7, cm, Color(1.0, 0.55, 0.2), 2.2, 6.0)
	_portrait(_p(0.45, 2.45, cm), Vector3(1, 0, 0), 1, "Le fondateur du club")
	b.cyl_at("k189_or", _p(1.0, 1.75, cm - 1.2), 0.07, 0.05, 0.3, 8)
	b.cyl_at("k189_or", _p(1.0, 1.75, cm + 1.2), 0.07, 0.05, 0.3, 8)
	_bx("in_tissu_rouge", 1.6, 5.6, 0.012, 0.02, cm - 2.2, cm + 2.2)
	_canape(3.6, cm - 1.5, Vector3(-0.6, 0, 0.8).normalized(), 1.0)
	_canape(3.6, cm + 1.5, Vector3(-0.6, 0, -0.8).normalized(), 1.0)
	_gens("homme", 3.5, cm - 1.4, Vector3(-0.6, 0, 0.8).normalized(), "assis", L_CLUB, false, true)
	_gens("femme", 3.5, cm + 1.4, Vector3(-0.6, 0, -0.8).normalized(), "assis", L_CLUB, false, true)
	b.cyl_at("in_bois", _p(2.6, 0.0, cm), 0.3, 0.3, 0.5, 12)
	b.cyl_at("peinture_blanche", _p(2.6, 0.5, cm), 0.08, 0.06, 0.07, 8)
	# ---- la bibliothèque (le mur du sud, à l'ouest) : les rayons, l'échelle qui roule, les lampes de lecture
	for niv in range(6):
		_bx("in_bois", 0.5, 14.0, 0.15 + niv * 0.45, 0.19 + niv * 0.45, D - 0.85, D - 0.4)
		var lx: float = 0.6
		while lx < 13.9:
			var wb: float = rng.randf_range(0.05, 0.1)
			if rng.randf() < 0.93:
				_bx(["k189_vert", "in_tissu_rouge", "in_cuir", "k189_bronze", "in_noir"][rng.randi() % 5], lx, lx + wb, 0.19 + niv * 0.45, 0.19 + niv * 0.45 + rng.randf_range(0.28, 0.4), D - 0.8, D - 0.5)
			lx += wb + 0.006
	for pxb in [0.5, 5.0, 9.5, 14.0]:
		_bx("in_bois", pxb - 0.04, pxb + 0.04, 0.0, 2.9, D - 0.87, D - 0.4)
	T._col(_p(7.25, 1.4, D - 0.62), Vector3(13.6, 2.8, 0.5))
	b.tube("k189_or", _p(0.5, 2.6, D - 0.9), _p(14.0, 2.6, D - 0.9), 0.02, 5)
	for sg in [-0.25, 0.25]:
		b.tube("in_bois", _p(7.0 + sg, 0.0, D - 1.6), _p(7.0 + sg, 2.6, D - 0.92), 0.025, 5)
	for ba in range(8):
		b.tube("in_bois", _p(6.75, 0.3 + ba * 0.3, D - 1.6 + (0.3 + ba * 0.3) * 0.26), _p(7.25, 0.3 + ba * 0.3, D - 1.6 + (0.3 + ba * 0.3) * 0.26), 0.018, 5)
	_bx("in_bois", 3.0, 6.0, 0.72, 0.78, D - 4.2, D - 3.0, true)
	for qq in [[3.1, D - 4.1], [5.9, D - 4.1], [3.1, D - 3.1], [5.9, D - 3.1]]:
		_bx("in_bois", qq[0] - 0.04, qq[0] + 0.04, 0.0, 0.72, qq[1] - 0.04, qq[1] + 0.04)
	for lp in [3.7, 5.3]:
		b.cyl_at("k189_or", _p(lp, 0.78, D - 3.6), 0.07, 0.07, 0.015, 8)
		b.cyl_at("k189_or", _p(lp, 0.78, D - 3.6), 0.012, 0.012, 0.3, 5)
		b.box("tissu_vert", Transform3D(Basis(), _p(lp, 1.11, D - 3.6)), Vector3(0.14, 0.07, 0.3))
	b.box("peinture_blanche", Transform3D(Basis(Vector3.UP, 0.2), _p(4.5, 0.79, D - 3.6)), Vector3(0.6, 0.012, 0.42))
	T._chaise(b, _p(4.5, 0.0, D - 4.9), Vector3(0, 0, 1))
	_gens("homme", 4.5, D - 4.9, Vector3(0, 0, 1), "assis", L_CLUB)
	# ---- le billard (au sud-est) : le tapis vert, les boules, les queues au râtelier, la lampe basse
	var bx: float = 31.0
	var bz: float = 16.4
	_bx("in_bois", bx - 1.5, bx + 1.5, 0.3, 0.82, bz - 0.85, bz + 0.85, true)
	_bx("tissu_vert", bx - 1.38, bx + 1.38, 0.82, 0.83, bz - 0.73, bz + 0.73)
	for cq in [[-1.4, -0.75], [1.4, -0.75], [-1.4, 0.75], [1.4, 0.75]]:
		b.cyl_at("in_bois", _p(bx + cq[0], 0.0, bz + cq[1]), 0.07, 0.09, 0.3, 8)
		b.cyl_at("in_noir", _p(bx + cq[0] * 0.98, 0.825, bz + cq[1] * 0.96), 0.06, 0.06, 0.008, 8)
	for sgz in [-0.8, 0.8]:
		_bx("in_bois", bx - 1.5, bx + 1.5, 0.82, 0.88, bz + sgz - 0.06, bz + sgz + 0.06)
	for sgx in [-1.45, 1.45]:
		_bx("in_bois", bx + sgx - 0.06, bx + sgx + 0.06, 0.82, 0.88, bz - 0.85, bz + 0.85)
	for bl in range(9):
		b.blob(["peinture_blanche", "plastique_rouge", "tissu_jaune", "plastique_bleu", "in_noir", "k187_orange", "tissu_vert", "plastique_rouge", "tissu_jaune"][bl], _p(bx - 1.0 + ((bl * 37) % 20) * 0.1, 0.86, bz - 0.55 + ((bl * 53) % 11) * 0.1), Vector3(0.03, 0.03, 0.03), 7)
	b.tube("in_bois_clair", _p(bx - 0.9, 0.9, bz + 0.2), _p(bx + 0.5, 0.93, bz + 0.6), 0.012, 5)
	b.cyl_at("k189_bronze", _p(bx, hc - 1.3, bz), 0.012, 0.012, 1.3, 4)
	b.box("tissu_vert", Transform3D(Basis(), _p(bx, hc - 1.4, bz)), Vector3(2.2, 0.16, 0.5))
	b.box("lampe_chaude", Transform3D(Basis(), _p(bx, hc - 1.49, bz)), Vector3(2.0, 0.02, 0.4))
	_lueur(bx, 1.7, bz, Color(1.0, 0.9, 0.7), 1.6, 4.0)
	_bx("in_bois", bx + 4.0, bx + 5.4, 1.0, 2.0, D - 0.5, D - 0.4)
	for qc in range(5):
		b.tube("in_bois_clair", _p(bx + 4.2 + qc * 0.25, 0.3, D - 0.52), _p(bx + 4.2 + qc * 0.25, 1.9, D - 0.52), 0.012, 5)
	_gens("homme", bx - 0.4, bz - 1.5, Vector3(0, 0, 1), "debout", L_CLUB, false, true)
	_gens("femme", bx + 2.3, bz + 0.3, Vector3(-1, 0, 0), "bras_croises", L_CLUB)
	# ---- la partie d'échecs commencée en 2101 (au nord-ouest) : la table, les pièces, la toile d'araignée
	var ex: float = 8.0
	var ez: float = 2.3
	_bx("in_bois", ex - 0.5, ex + 0.5, 0.0, 0.74, ez - 0.5, ez + 0.5, true)
	for cxe in range(8):
		for cze in range(8):
			_bx("peinture_blanche" if (cxe + cze) % 2 == 0 else "in_noir", ex - 0.4 + cxe * 0.1, ex - 0.3 + cxe * 0.1, 0.74, 0.745, ez - 0.4 + cze * 0.1, ez - 0.3 + cze * 0.1)
	for pc in range(14):
		var pcx: int = (pc * 5 + 1) % 8
		var pcz: int = (pc * 3 + (pc >> 2)) % 8
		b.cyl_at("peinture_blanche" if pc % 2 == 0 else "in_noir", _p(ex - 0.35 + pcx * 0.1, 0.745, ez - 0.35 + pcz * 0.1), 0.02, 0.03, 0.07 + (pc % 3) * 0.025, 7)
	b.tube("peinture_blanche", _p(ex - 0.05, 0.85, ez - 0.05), _p(ex + 0.25, 0.86, ez + 0.15), 0.002, 3)
	b.tube("peinture_blanche", _p(ex - 0.05, 0.85, ez - 0.05), _p(ex + 0.15, 0.9, ez - 0.25), 0.002, 3)
	_canape(ex - 1.3, ez, Vector3(1, 0, 0), 1.0)
	_canape(ex + 1.3, ez, Vector3(-1, 0, 0), 1.0)
	_gens("homme", ex + 1.2, ez, Vector3(-1, 0, 0), "assis", L_CLUB, false, true)
	_texte("Partie commencée en 2101.", 14, Color(1.0, 0.85, 0.5), _p(ex, 0.45, ez + 0.51), Vector3(0, 0, 1))
	# ---- le petit golf (au nord-est) : la bande de gazon, le trou, le drapeau, les coupes dans la vitrine
	_bx("tissu_vert", 24.0, 37.0, 0.012, 0.03, 1.0, 2.6)
	_bx("in_bois", 24.0, 37.0, 0.012, 0.08, 0.9, 1.0)
	_bx("in_bois", 24.0, 37.0, 0.012, 0.08, 2.6, 2.7)
	b.cyl_at("in_noir", _p(36.0, 0.028, 1.8), 0.08, 0.08, 0.006, 10)
	b.cyl_at("peinture_blanche", _p(36.0, 0.03, 1.8), 0.008, 0.008, 1.0, 4)
	_bx("plastique_rouge", 36.0, 36.3, 0.84, 1.03, 1.795, 1.805)
	b.blob("peinture_blanche", _p(33.2, 0.055, 1.9), Vector3(0.025, 0.025, 0.025), 6)
	b.tube("in_inox", _p(25.6, 0.05, 1.5), _p(25.9, 0.95, 1.3), 0.01, 4)
	b.box("in_inox", Transform3D(Basis(), _p(25.55, 0.05, 1.5)), Vector3(0.12, 0.04, 0.03))
	_gens("femme", 26.3, 1.5, Vector3(1, 0, 0.2), "debout", L_CLUB)
	_bx("in_bois", W - 4.2, W - 1.4, 0.0, 0.9, 0.45, 0.95, true)
	_bx("in_vitre", W - 4.2, W - 1.4, 0.9, 2.0, 0.45, 0.95)
	for cp in range(5):
		var cpx: float = W - 3.9 + cp * 0.55
		b.cyl_at("in_bois", _p(cpx, 0.9, 0.7), 0.07, 0.07, 0.05, 8)
		b.cyl_at("k189_or", _p(cpx, 0.95, 0.7), 0.02, 0.03, 0.12 + (cp % 2) * 0.05, 6)
		b.cyl_at("k189_or", _p(cpx, 1.07 + (cp % 2) * 0.05, 0.7), 0.05, 0.1, 0.16, 10)
	_texte("Tournoi du 8e étage", 16, Color(1.0, 0.85, 0.5), _p(W - 2.8, 2.2, 0.96), Vector3(0, 0, 1))
	# ---- le thé (à l'est, face à l'ascenseur) : le chariot, la théière d'argent, le majordome
	_bx("k189_or", W - 9.2, W - 8.0, 0.4, 0.43, cm + 1.9, cm + 2.6)
	_bx("k189_or", W - 9.2, W - 8.0, 0.85, 0.88, cm + 1.9, cm + 2.6, true)
	for cq2 in [[W - 9.18, cm + 1.92], [W - 8.02, cm + 1.92], [W - 9.18, cm + 2.58], [W - 8.02, cm + 2.58]]:
		b.cyl_at("k189_or", _p(cq2[0], 0.0, cq2[1]), 0.015, 0.015, 0.88, 5)
	b.blob("in_inox", _p(W - 8.8, 0.99, cm + 2.25), Vector3(0.11, 0.11, 0.11), 8)
	b.tube("in_inox", _p(W - 8.7, 0.98, cm + 2.25), _p(W - 8.55, 1.06, cm + 2.25), 0.015, 5)
	for ts in range(4):
		b.cyl_at("peinture_blanche", _p(W - 8.4 + (ts % 2) * 0.2, 0.88, cm + 2.05 + (ts >> 1) * 0.35), 0.04, 0.03, 0.05, 7)
	_gens("homme", W - 7.3, cm + 1.3, Vector3(-1, 0, -0.3), "debout", L_MAJORDOME, true, true)
	# ---- les journaux (sur le cœur, au nord) : les baguettes, les quotidiens, les fauteuils de lecture
	for jn in range(6):
		var jx: float = cx0 + 1.0 + jn * 1.4
		b.tube("in_bois", _p(jx - 0.45, 1.7, cz0 - 0.08), _p(jx + 0.45, 1.7, cz0 - 0.08), 0.015, 5)
		_bx("peinture_blanche", jx - 0.4, jx + 0.4, 0.9, 1.7, cz0 - 0.1, cz0 - 0.07)
		_bx("in_noir", jx - 0.35, jx + 0.35, 1.52, 1.6, cz0 - 0.105, cz0 - 0.1)
		for li in range(5):
			_bx("in_mur_gris", jx - 0.35, jx + 0.35 - (li % 2) * 0.2, 1.0 + li * 0.09, 1.03 + li * 0.09, cz0 - 0.105, cz0 - 0.1)
	_canape(14.5, 5.6, Vector3(0, 0, -1), 1.0)
	_canape(30.0, 5.6, Vector3(0, 0, -1), 1.0)
	_gens("homme", 30.0, 5.5, Vector3(0, 0, -1), "assis", L_CLUB)
	_plante_pot(W - 0.9, D - 0.9, 1.5)
	_plante_pot(0.9, 0.9, 1.5, true)
	_plante_pot(16.0, D - 0.9, 1.4)
	return ""


# ------------------------------------------------------------------ le 9e : l'atelier des pièces
func _atelier() -> String:
	var q: Array = _coeur()
	var cx0: float = q[0]
	var cx1: float = q[1]
	var cz0: float = q[2]
	var cz1: float = q[3]
	var cm: float = (cz0 + cz1) * 0.5
	_colonnes()
	_plafond("in_mur_gris", false)
	_sol("in_sol_technique")
	# ---- le four (au nord-ouest) : la brique, la gueule rouge, le creuset d'or, les lingotières
	_bx("in_tissu_rouge", 1.0, 4.2, 0.0, 2.4, 0.5, 2.6, true)
	for bq in range(8):
		_bx("metal_noir", 0.98, 4.22, 0.28 + bq * 0.3, 0.3 + bq * 0.3, 0.48, 2.62)
	_bx("k189_bronze", 0.9, 4.3, 2.4, 2.5, 0.4, 2.7)
	b.cyl_at("metal_noir", _p(2.6, 2.5, 1.5), 0.3, 0.3, hc - 2.6, 10)
	_bx("in_noir", 1.8, 3.4, 0.5, 1.5, 2.6, 2.62)
	_bx("k187_orange", 1.9, 3.3, 0.55, 1.4, 2.62, 2.63)
	_bx("lampe_chaude", 2.1, 3.1, 0.6, 1.1, 2.63, 2.64)
	_lueur(2.6, 1.0, 3.6, Color(1.0, 0.45, 0.15), 2.6, 6.0)
	b.cyl_at("metal_noir", _p(5.6, 0.0, 2.2), 0.3, 0.4, 0.5, 10)
	b.cyl_at("metal_noir", _p(5.6, 0.5, 2.2), 0.42, 0.36, 0.55, 12)
	b.cyl_at("lampe_chaude", _p(5.6, 1.0, 2.2), 0.34, 0.34, 0.04, 12)
	b.tube("metal_noir", _p(5.2, 0.9, 2.2), _p(4.3, 1.2, 2.2), 0.03, 5)
	for lgt in range(5):
		_bx("metal_noir", 7.0 + lgt * 0.5, 7.4 + lgt * 0.5, 0.5, 0.6, 1.2, 1.5)
		_bx("lampe_chaude" if lgt < 2 else "k189_or", 7.04 + lgt * 0.5, 7.36 + lgt * 0.5, 0.56, 0.61, 1.24, 1.46)
	_bx("in_inox", 6.9, 9.6, 0.0, 0.5, 1.0, 1.7, true)
	_lingots(10.6, 0.0, 1.4, 4)
	_gens("homme", 5.9, 3.6, Vector3(-0.3, 0, -1), "debout", L_ATELIER, false, true)
	# ---- le laminoir (au nord) : les deux rouleaux, la bande d'or qui en sort
	_bx("k189_bronze", 14.0, 14.4, 0.0, 1.5, 1.0, 2.6, true)
	_bx("k189_bronze", 15.6, 16.0, 0.0, 1.5, 1.0, 2.6, true)
	b.tube("in_inox", _p(14.4, 1.05, 1.8), _p(15.6, 1.05, 1.8), 0.18, 12)
	b.tube("in_inox", _p(14.4, 0.67, 1.8), _p(15.6, 0.67, 1.8), 0.18, 12)
	_bx("k189_or", 14.6, 15.4, 0.85, 0.87, 0.6, 5.2)
	b.cyl("k189_or", Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), _p(15.0, 0.6, 5.4)), 0.4, 0.4, 0.8, 16)
	b.cyl("metal_noir", Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), _p(15.0, 0.6, 5.4)), 0.08, 0.08, 1.2, 8)
	for sgl in [-0.55, 0.55]:
		_bx("metal_noir", 15.0 + sgl - 0.04, 15.0 + sgl + 0.04, 0.0, 0.65, 5.3, 5.5)
	T._col(_p(15.0, 0.5, 5.4), Vector3(1.3, 1.0, 0.9))
	# ---- la presse (au nord-est) : le bâti, le marteau qui frappe, les pièces qui sortent sur le tapis
	var px: float = 32.2
	var pz: float = 2.6
	for sgp in [-0.9, 0.9]:
		_bx("k189_bronze", px + sgp - 0.2, px + sgp + 0.2, 0.0, 2.7, pz - 0.4, pz + 0.4, true)
	_bx("k189_bronze", px - 1.1, px + 1.1, 2.7, 3.1, pz - 0.5, pz + 0.5)
	_bx("metal_noir", px - 0.7, px + 0.7, 0.0, 0.9, pz - 0.45, pz + 0.45, true)
	b.cyl_at("in_inox", _p(px, 0.9, pz), 0.25, 0.25, 0.06, 14)
	var lotm := Kit.Batch.new()
	lotm.cyl_at("in_inox", Vector3(0, 0, 0), 0.22, 0.22, 0.5, 14)
	lotm.cyl_at("metal_noir", Vector3(0, 0.5, 0), 0.12, 0.12, 1.2, 10)
	var mart: MeshInstance3D = _mobile(lotm, _p(px, 1.4, pz))
	_anime().flotte.append([mart, _p(px, 1.35, pz), 0.36, 3.1, 0.0])
	_texte("LA FRAPPE", 26, Color(1.0, 0.82, 0.45), _p(px, 2.9, pz + 0.51), Vector3(0, 0, 1))
	b.cyl_at("k189_or", _p(px + 1.6, 2.2, pz), 0.3, 0.3, 0.02, 14)
	b.cyl_at("in_inox", _p(px + 1.6, 1.2, pz), 0.02, 0.02, 1.0, 5)
	_bx("in_inox", px - 0.2, px + 0.2, 0.8, 0.86, pz + 0.45, pz + 9.0, true)
	_bx("plastique_noir", px - 0.16, px + 0.16, 0.86, 0.875, pz + 0.45, pz + 9.0)
	var lzs: float = pz + 1.0
	while lzs < pz + 9.0:
		_bx("in_inox", px - 0.18, px + 0.18, 0.0, 0.8, lzs - 0.04, lzs + 0.04)
		lzs += 2.0
	var lotp := Kit.Batch.new()
	lotp.cyl_at("k189_or", Vector3.ZERO, 0.07, 0.07, 0.014, 12)
	var mp: ArrayMesh = _maillage(lotp)
	for i in range(14):
		var pm := MeshInstance3D.new()
		pm.mesh = mp
		_anime().add_child(pm)
		_anime().tapis.append([pm, _p(px, 0.876, pz + 0.5), Vector3(0, 0, 1), 8.4, float(i) / 14.0, 0.8])
	_gens("femme", px - 1.9, pz + 1.3, Vector3(1, 0, -0.4), "bras_croises", L_ATELIER, false, true)
	# ---- le polissage (au bout du tapis) : le tonneau qui tourne, la caisse des pièces finies
	var tz: float = pz + 10.0
	var lott := Kit.Batch.new()
	lott.cyl_at("k189_bronze", Vector3(0, 0, 0), 0.7, 0.7, 0.9, 8)
	for a in range(8):
		lott.box("k189_or", Transform3D(Basis(Vector3.UP, a * TAU / 8.0), Vector3(cos(-a * TAU / 8.0) * 0.69, 0.45, sin(-a * TAU / 8.0) * 0.69)), Vector3(0.03, 0.9, 0.12))
	var ton: MeshInstance3D = _mobile(lott, _p(px, 0.35, tz))
	_anime().tourne.append([ton, 0.9])
	b.cyl_at("metal_noir", _p(px, 0.0, tz), 0.5, 0.6, 0.35, 10)
	T._col(_p(px, 0.6, tz), Vector3(1.4, 1.3, 1.4))
	_bx("in_bois", px + 1.4, px + 2.6, 0.0, 0.5, tz - 0.5, tz + 0.5, true)
	for pc in range(40):
		b.cyl("k189_or", Transform3D(Basis(Vector3(1, 0, 0), rng.randf_range(-0.5, 0.5)) * Basis(Vector3(0, 0, 1), rng.randf_range(-0.5, 0.5)), _p(px + 2.0 + rng.randf_range(-0.5, 0.5), 0.5 + rng.randf_range(0.0, 0.12), tz + rng.randf_range(-0.4, 0.4))), 0.07, 0.07, 0.014, 8)
	_gens("homme", px - 1.6, tz + 0.2, Vector3(1, 0, 0), "debout", L_ATELIER)
	# ---- la pesée (à l'est, face à l'ascenseur) : la grande balance, la pièce étalon sous cloche
	var bx: float = W - 6.5
	b.cyl_at("k189_bronze", _p(bx, 0.0, cm), 0.4, 0.5, 0.12, 14)
	b.cyl_at("k189_or", _p(bx, 0.12, cm), 0.05, 0.07, 1.9, 8)
	b.tube("k189_or", _p(bx, 1.95, cm - 1.1), _p(bx, 2.1, cm + 1.1), 0.03, 6)
	for sgb in [-1.0, 1.0]:
		var bh: float = 2.02 + sgb * 0.075
		for a2 in range(3):
			b.tube("k189_bronze", _p(bx, bh, cm + sgb * 1.1), _p(bx + cos(a2 * TAU / 3.0) * 0.35, bh - 0.8, cm + sgb * 1.1 + sin(a2 * TAU / 3.0) * 0.35), 0.006, 3)
		b.cyl_at("k189_or", _p(bx, bh - 0.82, cm + sgb * 1.1), 0.4, 0.3, 0.04, 14)
	b.cyl("k189_or", Transform3D(Basis(Vector3(1, 0, 0), 0.2), _p(bx, 1.17, cm - 1.1)), 0.09, 0.09, 0.016, 12)
	b.blob("peinture_blanche", _p(bx, 1.36, cm + 1.1), Vector3(0.05, 0.02, 0.1), 6)
	T._col(_p(bx, 1.0, cm), Vector3(0.9, 2.0, 3.0))
	_texte("Une pièce pèse exactement une plume. De très gros oiseau.", 14, Color(1.0, 0.85, 0.5), _p(W - 0.42, 1.2, cm), Vector3(-1, 0, 0))
	_gens("femme", bx - 1.3, cm + 0.2, Vector3(1, 0, 0), "debout", L_ATELIER, false, true)
	# ---- l'établi du graveur (au sud-ouest) : le grand modèle de plâtre, les burins, la loupe, la lampe
	_bx("in_bois", 3.0, 7.0, 0.82, 0.9, D - 2.0, D - 0.8, true)
	for qq in [[3.1, D - 1.9], [6.9, D - 1.9], [3.1, D - 0.9], [6.9, D - 0.9]]:
		_bx("in_bois", qq[0] - 0.05, qq[0] + 0.05, 0.0, 0.82, qq[1] - 0.05, qq[1] + 0.05)
	var rd := Basis(Vector3(1, 0, 0), PI * 0.5 - 0.25)
	b.cyl("peinture_blanche", Transform3D(rd, _p(4.2, 1.5, D - 1.0)), 0.6, 0.6, 0.06, 28)
	b.cyl("in_mur_gris", Transform3D(rd, _p(4.2, 1.5, D - 1.04)), 0.5, 0.5, 0.02, 28)
	b.blob("peinture_blanche", _p(4.2, 1.52, D - 1.07), Vector3(0.22, 0.16, 0.03), 8)                 # (le pigeon de la pièce de deux)
	b.blob("peinture_blanche", _p(4.38, 1.68, D - 1.08), Vector3(0.08, 0.08, 0.03), 6)
	b.blob("peinture_blanche", _p(4.49, 1.67, D - 1.1), Vector3(0.05, 0.02, 0.015), 5)
	for bu in range(6):
		b.tube("in_bois", _p(5.4 + bu * 0.13, 0.91, D - 1.5), _p(5.42 + bu * 0.13, 0.91, D - 1.25), 0.012, 5)
		b.tube("in_inox", _p(5.42 + bu * 0.13, 0.91, D - 1.25), _p(5.43 + bu * 0.13, 0.91, D - 1.12), 0.004, 4)
	b.cyl("k189_or", Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), _p(6.4, 1.15, D - 1.4)), 0.11, 0.11, 0.015, 14)
	b.cyl("verre", Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), _p(6.4, 1.15, D - 1.4)), 0.095, 0.095, 0.02, 14)
	b.tube("k189_or", _p(6.4, 0.9, D - 1.4), _p(6.4, 1.04, D - 1.4), 0.01, 4)
	T._chaise(b, _p(5.0, 0.0, D - 2.7), Vector3(0, 0, 1))
	_gens("homme", 5.0, D - 2.7, Vector3(0, 0, 1), "assis", L_GRAVEUR, false, true)
	_lueur(5.0, 2.0, D - 2.0, Color(1.0, 0.9, 0.75), 1.4, 4.0)
	# ---- les pièces de l'archipel (sur le cœur, au sud) : le tableau de velours, une pièce par île
	_bx("in_bois", cx0 + 0.5, cx1 - 0.5, 0.9, 2.5, cz1, cz1 + 0.06)
	_bx("in_tissu_rouge", cx0 + 0.6, cx1 - 0.6, 1.0, 2.4, cz1 + 0.06, cz1 + 0.07)
	var iles: Array = ["Île Manga", "Néopolis", "Île Perchée", "Hautefond", "Le Volcan", "Les Brumes", "Le Récif"]
	for i2 in range(7):
		var ix: float = cx0 + 1.3 + i2 * (cx1 - cx0 - 2.6) / 6.0
		b.cyl(["k189_or", "peinture_blanche", "k187_orange"][i2 % 3], Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), _p(ix, 1.85, cz1 + 0.085)), 0.2 + (i2 % 2) * 0.05, 0.2 + (i2 % 2) * 0.05, 0.025, 20)
		_texte(str(iles[i2]), 13, Color(1.0, 0.88, 0.6), _p(ix, 1.4, cz1 + 0.075), Vector3(0, 0, 1))
	_texte("LES PIÈCES DE L'ARCHIPEL", 28, Color(1.0, 0.82, 0.45), _p((cx0 + cx1) * 0.5, 2.7, cz1 + 0.07), Vector3(0, 0, 1))
	# ---- les caisses prêtes à partir (au sud) : scellées, étiquetées, sur leurs palettes
	for ca in range(6):
		var cxa: float = 10.0 + ca * 1.5
		_bx("in_bois_clair", cxa - 0.55, cxa + 0.55, 0.0, 0.12, D - 2.0, D - 0.9)
		_bx("in_bois", cxa - 0.5, cxa + 0.5, 0.12, 0.8 + (ca % 2) * 0.6, D - 1.95, D - 0.95, true)
		_bx("k189_bronze", cxa - 0.51, cxa + 0.51, 0.4, 0.46, D - 1.96, D - 0.94)
		_bx("peinture_blanche", cxa - 0.2, cxa + 0.2, 0.55, 0.72, D - 1.96, D - 1.95)
	_sac(19.2, 0.0, D - 1.4, 1.4)
	_sac(19.8, 0.0, D - 1.2, 1.2)
	_gens("femme", 14.0, D - 3.0, Vector3(0, 0, 1), "debout", L_ATELIER)
	return ""
