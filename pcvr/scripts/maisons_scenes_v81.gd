extends RefCounted
## V81 : ce qui se passe dans les maisons qu'on visite (maisons_v81.gd construit la pièce et
## appelle build() puis on_enter()). Chaque scénario installe ses meubles et ses habitants, et ce
## qu'on peut y faire (parler, ouvrir, soulever le tapis, tirer un livre…). Les textes ont des
## variantes (selon la ville, l'heure, la maison), pour que deux maisons qui racontent la même
## histoire ne se ressemblent pas tout à fait.
##
## M : maisons_v81 (M.R : la pièce, M.ctx : la maison, M.state() : ce qu'elle a retenu).

## [id, poids, conditions]  (conditions : "grand" la pièce est assez grande, "nuit"/"jour")
const SCENARIOS := [
	["famille", 10, {}], ["fou_rire", 7, {}], ["pyjama", 7, {}], ["dormeur", 6, {}],
	["abandon", 7, {}], ["fantome", 4, {}], ["cave", 7, {}], ["biblio", 5, {"grand": true}],
	["chats", 5, {}], ["surprise", 4, {"grand": true}], ["inventeur", 5, {}], ["cache_cache", 5, {}],
	["musicien", 5, {}], ["mamie", 6, {}], ["travaux", 4, {}], ["sportif", 4, {}],
	["collection", 5, {}], ["envers", 3, {}], ["dispute", 5, {}], ["mime", 3, {}],
	["coucou", 4, {}], ["vide", 9, {}],
]

const Iles = preload("res://scripts/maisons_iles_v82.gd")

const BLAGUES := [
	["Qu'est-ce qui est jaune et qui attend ?", "Jonathan !"],
	["Pourquoi les plongeurs plongent-ils toujours en arrière ?", "Parce que sinon, ils tombent dans le bateau !"],
	["Que dit une imprimante dans l'eau ?", "J'ai papier !"],
	["Quel est le comble pour un électricien ?", "De ne pas être au courant !"],
	["Qu'est-ce qui a des dents mais ne mord jamais ?", "Un peigne !"],
	["Que fait une fraise sur un cheval ?", "Tagada, tagada !"],
	["Pourquoi le livre de calcul est-il triste ?", "Parce qu'il a trop de problèmes !"],
	["Qu'est-ce qui est vert, qui monte et qui descend ?", "Un petit pois dans un ascenseur !"],
	["C'est un escargot sur le dos d'une tortue. Qu'est-ce qu'il crie ?", "« Wouhouuu ! Ça va trop vite ! »"],
	["Monsieur et Madame Térieur ont deux fils. Comment s'appellent-ils ?", "Alex et Alain !"],
	["Quel est le sport préféré des insectes ?", "Le cricket !"],
	["Qu'est-ce qu'un canif ?", "Un petit fien !"],
	["Pourquoi les poissons vivent-ils dans l'eau salée ?", "Parce que dans l'eau poivrée, ils éternuent !"],
	["Comment appelle-t-on un chien qui n'a pas de pattes ?", "On ne l'appelle pas : on va le chercher !"],
	["Que dit un oignon quand il se cogne ?", "Aïe !"],
	["Quel est l'animal le plus heureux ?", "Le hibou, parce que sa femme est chouette !"],
	["Pourquoi les fantômes sont-ils de si mauvais menteurs ?", "Parce qu'on voit à travers !"],
	["Qu'est-ce qui fait « Oh ! Oh ! Oh ! » ?", "Le Père Noël qui marche à reculons !"],
]

const RIRES := ["HA HA HA !", "Hi hi hi hi !", "Arrête, j'en peux plus !", "Ho ho ho !", "Pfff… HA HA !", "J'ai mal au ventre !", "Hiii hiii !", "Mouhahaha !"]


# =================================================================== choisir

static func region(style: String) -> String:
	match style:
		"montjoie":
			return "montjoie"
		"braise":
			return "braise"
		"boucan", "boucan_entrepot", "boucan_conteneur":
			return "boucan"
		"tazira", "cliquetis", "ramure", "carene":
			return "grande"
		"arcanelle":
			return "arcanelle"
		"pirate":
			return "balafre"
		"egypte", "maya", "azteque":
			return "soleils"
	return "azur"


## Ce qu'on mange dans cette ville (sans alcool, on est en famille).
static func food(style: String) -> Array:
	match style:
		"montjoie":
			return ["pain_montjoie", "tourte_montjoie", "jus_pomme"]
		"braise":
			return ["brioche_braise", "lave_glacee", "cafe_brasier"]
		"boucan", "boucan_entrepot", "boucan_conteneur":
			return ["soupe_prix_libre", "limonade_boucan", "sirop_menthe"]
		"tazira":
			return ["tajine_poisson", "the_menthe", "dattes"]
		"cliquetis":
			return ["biscuit_engrenage", "cafe_vapeur"]
		"ramure":
			return ["pain_carotte", "gateau_lune", "tisane_brume"]
		"arcanelle":
			return ["tarte_potiron", "potion_mana"]
		"pirate":
			return ["ragout_pirate", "noix_coco", "brochette_poisson"]
		"carene":
			return ["galette_sarrasin", "sardines_grillees"]
		"egypte":
			return ["pain_egypte", "gateau_miel", "dattes"]
		"maya", "azteque":
			return ["galette_mais", "cacao"]
		"astralys":
			return ["the_stellaire", "gelee_cosmique", "biscuit_lunaire"]
	return ["croissant", "bouillabaisse", "glace"]


## Le plat du jour, en toutes lettres.
static func plat(style: String) -> String:
	match style:
		"montjoie":
			return "de la tourte aux champignons"
		"braise":
			return "du ragoût de lave douce"
		"boucan", "boucan_entrepot", "boucan_conteneur":
			return "de la soupe à prix libre"
		"tazira":
			return "du tajine de poisson"
		"cliquetis":
			return "des biscuits-engrenages"
		"ramure":
			return "du pain de carotte"
		"arcanelle":
			return "de la tarte au potiron"
		"pirate":
			return "du ragoût de pirate (sans les os, promis)"
		"carene":
			return "des galettes de sarrasin"
		"egypte":
			return "du pain au miel"
		"maya", "azteque":
			return "des galettes de maïs"
		"astralys":
			return "de la gelée cosmique"
	return "de la bouillabaisse"


## V83 : cette histoire existe-t-elle (encore) ?
static func has_scenario(sc: String) -> bool:
	if sc in ["chez", "fee"] or Iles.has(sc):
		return true
	for e in SCENARIOS:
		if str(e[0]) == sc:
			return true
	return false


static func pick(M) -> String:
	var ctx: Dictionary = M.ctx
	if str(ctx["style"]) == "fee":
		return "fee"
	if str(ctx.get("owner", "")) != "" and ctx.get("owner_node", null) != null:
		return "chez"
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(ctx["id"]) + "scenario")
	var grand: bool = float(ctx["W"]) >= 6.5 and float(ctx["D"]) >= 5.6
	var total: float = 0.0
	var cands: Array = []
	for sc in SCENARIOS:
		var cond: Dictionary = sc[2]
		if bool(cond.get("grand", false)) and not grand:
			continue
		if str(ctx["style"]) == "boucan_conteneur" and str(sc[0]) in ["biblio", "envers", "surprise", "cave"]:
			continue
		cands.append(sc)
		total += float(sc[1])
	# V82 : les histoires propres à l'île
	for sc3 in Iles.SCENARIOS:
		if Iles.allowed(sc3, str(ctx["style"])):
			cands.append(sc3)
			total += float(sc3[1])
	var x: float = rng.randf() * total
	for sc2 in cands:
		x -= float(sc2[1])
		if x <= 0.0:
			return str(sc2[0])
	return "vide"


static func build(M) -> void:
	_garde_entree(M)
	match str(M.ctx["scenario"]):
		"famille":
			_b_famille(M)
		"fou_rire":
			_b_fou_rire(M)
		"pyjama":
			_b_pyjama(M)
		"dormeur":
			_b_dormeur(M)
		"abandon":
			_b_abandon(M, false)
		"fantome":
			_b_abandon(M, true)
		"cave":
			_b_cave(M)
		"biblio":
			_b_biblio(M)
		"chats":
			_b_chats(M)
		"surprise":
			_b_surprise(M)
		"inventeur":
			_b_inventeur(M)
		"cache_cache":
			_b_cache(M)
		"musicien":
			_b_musicien(M)
		"mamie":
			_b_mamie(M)
		"travaux":
			_b_travaux(M)
		"sportif":
			_b_sportif(M)
		"collection":
			_b_collection(M)
		"envers":
			_b_envers(M)
		"dispute":
			_b_dispute(M)
		"mime":
			_b_mime(M)
		"coucou":
			_b_coucou(M)
		"chez":
			_b_chez(M)
		_:
			if Iles.has(str(M.ctx["scenario"])):
				Iles.build(M, str(M.ctx["scenario"]))
			else:
				_b_vide(M)


static func on_enter(M, first: bool) -> void:
	var sc: String = str(M.ctx["scenario"])
	var cb: Variant = M.ctx.get("on_enter", null)
	if cb is Callable and (cb as Callable).is_valid():
		(cb as Callable).call(first)
		return
	if first:
		var t: String = str(M.ctx.get("entree", ""))
		if t != "":
			M.say(t, 6.0)


# =================================================================== aides

static func _r(M) -> RandomNumberGenerator:
	return M.ctx["rng"]


static func _pick(M, a: Array) -> Variant:
	return a[_r(M).randi() % a.size()]


## Le passage devant la porte reste libre.
static func _garde_entree(M) -> void:
	var R = M.R
	R.reserve(R.door_x, R.D * 0.5 - 0.9, 1.7, 1.9)


## Des tableaux sur les murs (pas devant les fenêtres).
static func _murs(M, n: int = 3) -> void:
	var R = M.R
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var y: float = minf(1.75, R.H - 0.7)
	var spots: Array = []
	var zs: Array = [-hd * 0.55, hd * 0.45] if R.D < 7.0 else [0.0]
	for z in zs:
		spots.append([-hw + 0.02, y, z, 90.0])
		spots.append([hw - 0.02, y, z, -90.0])
	spots.append([R.W * 0.25 if R.W > 7.5 else -R.W * 0.28, y, -hd + 0.02, 0.0])
	spots.shuffle()
	for i in range(mini(n, spots.size())):
		var s: Array = spots[i]
		R.tableau(float(s[0]), float(s[1]), float(s[2]), float(s[3]), _r(M).randf_range(0.6, 0.95), _r(M).randf_range(0.5, 0.75))


## Une table et ses chaises (renvoie les places : [x, z, yaw] des chaises).
static func _table(M, tx: float, tz: float, n: int, nappe: String = "") -> Array:
	var R = M.R
	var w: float = 1.5 if n > 4 else 1.25
	R.table(tx, tz, 0, w, 0.85, 0.76, nappe)
	var places: Array = []
	var seats: Array = [[tx - w * 0.25, tz + 0.72, 180.0], [tx + w * 0.25, tz - 0.72, 0.0], [tx + w * 0.5 + 0.45, tz, -90.0], [tx - w * 0.5 - 0.45, tz, 90.0],
		[tx + w * 0.25, tz + 0.72, 180.0], [tx - w * 0.25, tz - 0.72, 0.0]]
	for i in range(mini(n, seats.size())):
		var s: Array = seats[i]
		R.chaise(float(s[0]), float(s[1]), float(s[2]), "" if _r(M).randf() < 0.6 else str(_pick(M, ["rouge", "vert", "jaune", "bleu"])))
		places.append(s)
	return places


## Un salon ordinaire : la table, le foyer, l'armoire, une étagère, un tapis, des tableaux, une plante.
static func _salon(M, table_n: int = 4, foyer: bool = true) -> Array:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	if foyer:
		R.foyer(R.W * 0.18, -hd + 0.38, 0, true)
	R.armoire(-hw + 0.35, -hd * 0.25, 90, 1.1, minf(2.0, R.H - 0.5))
	if r.randf() < 0.7:
		R.etagere(hw - 0.22, -hd * 0.45, -90, 1.0, minf(1.8, R.H - 0.6), r.randf() < 0.7, 4)
	R.tapis(0.0, 0.2, 0, minf(2.6, R.W - 2.6), minf(1.8, R.D - 2.6))
	var places: Array = _table(M, -0.2, 0.15, table_n, str(_pick(M, ["", "creme", "rouge", "blanc", "vert"])))
	_murs(M, 3)
	if r.randf() < 0.7:
		R.plante(hw - 0.45, hd - 0.5)
	if r.randf() < 0.5:
		R.etagere_murale(-R.W * 0.15, 1.6, -hd + 0.15, 0, 1.2, str(_pick(M, ["ceramique", "terre_cuite", "cuivre", "verre"])), 5)
	return places


## Un petit mot posé sur la table (on peut le lire).
static func _mot(M, x: float, z: float, y: float, text: String, label: String = "E : lire le petit mot") -> void:
	var R = M.R
	R.kit.box(R.L(x, y + 0.004, z, _r(M).randf_range(-25, 25)), Vector3(0.2, 0.006, 0.14), "papier", 1.0, 4)
	M.act(R.P(x, 0, z), label, func(): M.say(text, 9.0), 1.3)


## Mettre quelqu'un à une place de table (assis, ou une autre pose).
static func _asseoir(M, role: String, place: Array, pose: String = "assis", nom: String = "") -> Node:
	return M.person(role, float(place[0]), float(place[1]), float(place[2]), pose, nom)


static func _say_late(M, f: Node, text: String, delay: float, seconds: float = 4.0) -> void:
	await M.get_tree().create_timer(delay).timeout
	if is_instance_valid(f) and M.inside:
		f.say(text, seconds)


static func _heure_txt(h: float) -> String:
	var hh: int = int(h) % 24
	var mm: int = int((h - floorf(h)) * 60.0)
	return "%d h %02d" % [hh, mm] if mm > 0 else "%d heures" % hh


static func _nuit(M) -> bool:
	var h: float = float(M.ctx["hour"])
	return h >= 22.0 or h < 6.5


# =================================================================== la famille à table

static func _b_famille(M) -> void:
	var R = M.R
	var r := _r(M)
	var places: Array = _salon(M, 4)
	if R.is_free(-R.W * 0.5 + 1.6, -R.D * 0.5 + 0.35, 2.8, 0.8):
		R.cuisine(-R.W * 0.5 + 1.6, -R.D * 0.5 + 0.35, 0, minf(2.0, R.W * 0.3))
	var h: float = float(M.ctx["hour"])
	var nuit: bool = _nuit(M)
	var matin: bool = h >= 6.5 and h < 10.5
	R.couverts(-0.2, 0.15, 0.79, [Vector2(-0.3, 0.3), Vector2(0.3, -0.3), Vector2(0.55, 0.0), Vector2(-0.55, 0.0)], "soupe" if not matin else "pain")
	var roles: Array = ["homme", "femme", str(_pick(M, ["garcon", "fille"])), str(_pick(M, ["fille", "garcon", "vieille", "vieux"]))]
	var gens: Array = []
	var n: int = 3 if r.randf() < 0.5 else 4
	for i in range(n):
		gens.append(_asseoir(M, roles[i], places[i], "manger" if not nuit else "assis"))
	var pere: Node = gens[0]
	var mere: Node = gens[1]
	var kid: Node = gens[2]
	var st: String = str(M.ctx["style"])
	var p: String = plat(st)
	if nuit:
		kid.lines = ["J'ai pas sommeil !", "Encore une partie !", "C'est moi qui gagne !"]
		pere.lines = ["Un six ! Enfin !", "Qui a triché ?", "Hmm… je passe mon tour."]
	elif matin:
		kid.lines = ["Je veux de la confiture !", "Il est où, mon bol ?", "J'ai fait un rêve avec un dragon !"]
		mere.lines = ["Mange, tu vas être en retard !", "Pas les doigts dans le pot !"]
	else:
		kid.lines = ["J'aime pas les légumes…", "Encore un peu !", "On mange quoi au dessert ?", "Regarde, je fais un bateau avec ma purée !"]
		mere.lines = ["On ne joue pas avec la nourriture !", "Qui veut du rab ?", "Tiens-toi droit."]
		pere.lines = ["Délicieux !", "Passe-moi le sel, s'il te plaît.", "Mmmh !"]
	var talk := func() -> void:
		var stt: Dictionary = M.state()
		if bool(stt.get("repas", false)):
			M.talk(mere, ["Re-bonjour ! Il n'y a plus " + p.trim_prefix("de ").trim_prefix("du ").trim_prefix("des ") + " : tu as tout mangé la dernière fois !", "Te revoilà ! Tu as aimé notre cuisine, hein ? Reviens quand tu veux !"][r.randi() % 2],
				[{"id": "fermer", "label": "Merci encore ! Au revoir."}], func(_id): M.close_talk())
			return
		var q: String
		if nuit:
			q = "Oh ! Un visiteur, à cette heure-ci ? On fait une partie de dés. Tu veux une tisane ?"
		elif matin:
			q = "Bonjour ! Tu tombes bien, c'est l'heure du petit-déjeuner. Tu as faim ?"
		else:
			q = "Oh ! Un invité ! Il reste %s, tu en veux ?" % p
		M.talk(mere, q, [{"id": "oui", "label": "Oui, avec plaisir !"}, {"id": "non", "label": "Non merci, je ne fais que passer."}], func(id):
			if id == "oui":
				M.state()["repas"] = true
				var hero: Node = M.main.get("hero_v28")
				if hero != null and hero.has_method("heal"):
					hero.heal(20)
				M.main.sfx("manger")
				var it: Array = food(st)
				M.give([[str(it[r.randi() % it.size()]), 1]], "Tu t'installes avec eux. C'est délicieux (et tout le monde te regarde manger). Tes cœurs sont remplis ! Pour la route : ")
				kid.say(["Il mange comme moi !", "Encore un peu ?", "T'as de la sauce sur le nez !"][r.randi() % 3], 4.0)
				M.close_talk()
			else:
				M.talk(mere, ["Tant pis ! Ça en fera plus pour %s." % str(kid.npc.display_name), "Une autre fois, alors ! Notre porte est toujours ouverte. Enfin… tu as vu, tu es entré."][r.randi() % 2],
					[{"id": "fermer", "label": "Bon appétit !"}], func(_i): M.close_talk())
		)
	M.talk_spot(mere, talk)
	M.talk_spot(pere, talk)
	M.ctx["on_enter"] = func(first: bool) -> void:
		if first:
			pere.say(["Oh ! Bonjour, toi !", "Tiens, de la visite !", "Entre, entre, ne reste pas dans le courant d'air !"][r.randi() % 3], 4.0)
			_say_late(M, kid, ["C'est qui ?", "Maman, y'a quelqu'un !", "Bonjouuur !"][r.randi() % 3], 1.6)
		else:
			mere.say("Ah, te revoilà !", 3.5)


# =================================================================== le fou rire

static func _b_fou_rire(M) -> void:
	var R = M.R
	var r := _r(M)
	var places: Array = _salon(M, 4)
	R.couverts(-0.2, 0.15, 0.79, [Vector2(-0.3, 0.3), Vector2(0.3, -0.3), Vector2(0.55, 0.0)], str(_pick(M, ["gateau", "fromage", "pain"])))
	var gens: Array = []
	var roles: Array = ["homme", "femme", str(_pick(M, ["vieux", "vieille", "homme", "femme"]))]
	for i in range(3):
		var f: Node = _asseoir(M, roles[i], places[i], "rire_assis")
		f.lines = RIRES
		f.line_every = Vector2(3.0, 6.0)
		gens.append(f)
	var talk := func() -> void:
		var b: Array = BLAGUES[(hash(str(M.ctx["id"])) + int(M.state().get("blagues", 0))) % BLAGUES.size()]
		M.talk(gens[0], "Ha ha ha ! Pardon… pardon… " + str(b[0]),
			[{"id": "quoi", "label": "Je ne sais pas… quoi ?"}, {"id": "fermer", "label": "(Repartir sur la pointe des pieds)"}], func(id):
			if id != "quoi":
				M.close_talk()
				return
			M.state()["blagues"] = int(M.state().get("blagues", 0)) + 1
			for g in gens:
				g.gesture("rire", 3.0)
			M.main.sfx("ui_quete")
			M.talk(gens[1], str(b[1]) + "  HA HA HA !", [{"id": "drole", "label": "Ha ha ! Elle est bonne !"}, {"id": "nul", "label": "… Je ne comprends pas."}, {"id": "encore", "label": "Une autre !"}], func(id2):
				if id2 == "drole":
					gens[2].say("Lui, il a de l'humour !", 3.5)
					if not bool(M.state().get("cadeau", false)):
						M.state()["cadeau"] = true
						var it: Array = food(str(M.ctx["style"]))
						M.give([[str(it[0]), 1]], "Pour la peine, ils t'offrent un morceau de ce qu'il y a sur la table. ")
					M.close_talk()
				elif id2 == "nul":
					M.talk(gens[2], "C'est justement ÇA qui est drôle ! HA HA HA !", [{"id": "fermer", "label": "Ah… d'accord."}], func(_i): M.close_talk())
				else:
					M.close_talk()
					(M.ctx["fou_talk"] as Callable).call()
			))
	M.ctx["fou_talk"] = talk
	for g2 in gens:
		M.talk_spot(g2, talk, "E : demander ce qui les fait rire")
	M.ctx["entree"] = str(_pick(M, ["Trois amis à table, pliés de rire. Personne ne t'a remarqué.", "Ça rit tellement fort ici que la vaisselle tremble sur les étagères.", "Un fou rire général. Quelqu'un pleure de rire dans sa serviette."]))


# =================================================================== qu'est-ce que tu fiches chez moi ?!

static func _b_pyjama(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var bain: bool = not _nuit(M) and r.randf() < 0.35
	R.lit(-hw + 0.65, -hd * 0.2, 90, 1.2, str(_pick(M, ["bleu", "rouge", "vert", "violet"])))
	R.armoire(hw - 0.35, -hd * 0.3, -90)
	R.tapis(0.2, 0.2, 0, 2.0, 1.4)
	R.foyer(R.W * 0.15, -hd + 0.38, 0, true)
	_murs(M, 2)
	var f: Node
	if bain:
		R.baignoire(hw - 1.1, hd * 0.25, 90)
		f = M.person(str(_pick(M, ["homme", "vieux", "femme"])), hw - 1.1, hd * 0.25 + 0.35, 180, "assis")
		f.npc.global_position.y -= 0.32
	else:
		f = M.person(str(_pick(M, ["homme", "vieux", "vieille", "femme"])), R.door_x * 0.4, 0.2, 180, "colere")
		_bonnet_de_nuit(f, r)
	var nm: String = str(f.npc.display_name)
	M.ctx["on_enter"] = func(first: bool) -> void:
		var st: Dictionary = M.state()
		if int(st.get("pyjama_vu", 0)) >= 1:
			st["pyjama_vu"] = int(st.get("pyjama_vu", 0)) + 1
			f.gesture("colere", 3.0)
			f.say(["ENCORE TOI ?!", "NON MAIS C'EST PAS VRAI !", "TOI ! DEHORS !"][r.randi() % 3], 3.0)
			M.expel(str(_pick(M, ["%s t'a mis dehors avant même que tu aies dit bonjour." % nm, "Tu n'as pas eu le temps de dire « bonjour ». La porte s'est refermée toute seule. Enfin, pas toute seule.", "Dehors ! Comme la dernière fois. Mais plus vite."])))
			return
		st["pyjama_vu"] = 1
		f.gesture("sursaut", 0.8)
		await M.get_tree().create_timer(0.7).timeout
		if not M.inside:
			return
		var q: String
		if bain:
			q = "AAAAH ! Mais… mais… TU NE VOIS PAS QUE JE PRENDS MON BAIN ?!"
		elif _nuit(M):
			q = "Mais… QU'EST-CE QUE TU FICHES CHEZ MOI ?! Il est %s ! Les honnêtes gens dorment !" % _heure_txt(float(M.ctx["hour"]))
		else:
			q = str(_pick(M, ["Mais… QU'EST-CE QUE TU FICHES CHEZ MOI ?!", "Hé ! Ho ! On frappe, avant d'entrer chez les gens !", "QUI T'A DIT D'ENTRER ?!"]))
		var dehors := func(t: String) -> void:
			M.talk(f, t, [{"id": "sortir", "label": "(Sortir. Vite.)"}], func(_i):
				M.close_talk()
				M.expel(""), "furieux")
		var reponses := {"porte": "Trompé de porte… C'est vrai qu'elles se ressemblent toutes, dans cette rue. Allez, file. Et ferme bien derrière toi !",
			"tour": "Le TOUR des maisons ?! Ce n'est pas un musée, ici ! DEHORS !",
			"pyjama": "… Merci. C'est ma grand-mère qui l'a tricoté. … DEHORS !" if not bain else "… Il s'appelle Amiral. … DEHORS, J'AI DIT !",
			"wc": "Les toilettes ? Au fond à gauche. … NON ! Pas du tout ! DEHORS !"}
		M.talk(f, q, [{"id": "porte", "label": "Pardon ! Je me suis trompé de porte."}, {"id": "tour", "label": "Je fais le tour des maisons."},
			{"id": "pyjama", "label": "Joli pyjama !" if not bain else "Joli canard en bois !"}, {"id": "wc", "label": "Je cherche les toilettes."}], func(id):
			dehors.call(str(reponses.get(id, reponses["wc"]))), "furieux")


## Un bonnet de nuit (un cône de tissu et son pompon), posé sur la tête.
static func _bonnet_de_nuit(f: Node, r: RandomNumberGenerator) -> void:
	var npc: Node3D = f.npc
	var skel: Skeleton3D = npc.get("skel")
	if skel == null:
		return
	var head: int = skel.find_bone("Head")
	if head < 0:
		return
	var att := BoneAttachment3D.new()
	att.bone_name = "Head"
	skel.add_child(att)
	var c: Color = [Color(0.2, 0.3, 0.7), Color(0.75, 0.15, 0.15), Color(0.25, 0.55, 0.3), Color(0.9, 0.9, 0.85)][r.randi() % 4]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	var cone := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = 0.105
	cm.height = 0.32
	cm.radial_segments = 12
	cone.mesh = cm
	cone.material_override = m
	cone.position = Vector3(0, 0.27, -0.03)
	cone.rotation = Vector3(-0.6, 0, 0.2)
	att.add_child(cone)
	var pom := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.04
	sm.height = 0.08
	pom.mesh = sm
	var mw := StandardMaterial3D.new()
	mw.albedo_color = Color(0.97, 0.97, 0.95)
	pom.material_override = mw
	pom.position = Vector3(0.04, 0.38, -0.15)
	att.add_child(pom)


# =================================================================== le dormeur

const REVES := ["Non… pas les brocolis… pitié…", "Cinq minutes… encore cinq minutes…", "Le dragon… il a mangé mes chaussettes…",
	"Je suis le roi… le roi des sardines…", "Mmmh… une tarte… grande comme la maison…", "Attention… le canard… il sait voler…",
	"Non, maman, c'est pas moi qui ai mangé le gâteau…", "Trois… quatre… cinq moutons… six… un mouton qui fait du vélo…",
	"Je vole… je voooole…", "Zzz… gratte-moi le dos… plus à gauche…"]

static func _b_dormeur(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var bx: float = -hw + 0.7
	var bz: float = -hd * 0.15
	R.lit(bx, bz, 90, 1.2, str(_pick(M, ["bleu", "rouge", "vert", "jaune", "violet", "rose"])))
	R.kit.box(R.L(bx + 0.05, 0.45, bz + 1.35), Vector3(0.45, 0.5, 0.4), "bois", 1.0)
	R.bougie(bx + 0.05, 0.7, bz + 1.35, false)
	R.armoire(hw - 0.35, -hd * 0.35, -90)
	R.tapis(0.3, 0.3, 0, 1.8, 1.3)
	R.etagere(hw - 0.22, hd * 0.35, -90, 0.9, 1.5, true, 3)
	_murs(M, 2)
	# le réveil, sur la table de chevet
	var rv: Vector3 = R.P(bx + 0.05, 0.71, bz + 1.35)
	R.kit.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), rv + Vector3(0.12, 0.05, 0)), 0.06, 0.06, 0.04, "cuivre", 12)
	var f: Node = M.person(str(_pick(M, ["homme", "vieux", "femme", "vieille"])), bx + 0.1, bz - 0.2, 90, "debout")
	f.lie(R.P(bx + 0.88, 0.5, bz), Vector3(-1, 0, 0))
	_bonnet_de_nuit(f, r)
	f.follow = false
	f.lines = ["Zzz…", "Rrrron… pfff…", "Zzzzz…", "Mmmh… ronron…"]
	f.line_every = Vector2(3.0, 5.5)
	var nm: String = str(f.npc.display_name)
	M.talk_spot(f, func() -> void:
		var reve: String = str(REVES[(int(M.state().get("reves", 0)) + hash(str(M.ctx["id"]))) % REVES.size()])
		M.state()["reves"] = int(M.state().get("reves", 0)) + 1
		M.talk(f, "(%s parle en dormant.) « %s »" % [nm, reve], [{"id": "secouer", "label": "Le secouer un peu"}, {"id": "chut", "label": "(Repartir sans bruit)"}], func(id):
			if id == "secouer":
				M.talk(f, str(_pick(M, ["Hein ?! Quoi ? … Ah, c'est un rêve. Bonne nuit, le rêve.", "Mmh… pas maintenant… je suis occupé… à dormir…", "Gné ?… Si c'est le facteur, posez ça sur la table… zzz…"])),
					[{"id": "fermer", "label": "(Le laisser dormir)"}], func(_i): M.close_talk(), "endormi")
			else:
				M.close_talk()
		, "endormi"), "E : écouter " + nm.split(" ")[0])
	M.act(rv + Vector3(0, -0.7, 0.6), "E : remonter le réveil", func() -> void:
		M.main.sfx("alerte_cloche", rv)
		f.stand_up(R.P(bx + 1.25, 0, bz + 0.3), Vector3(0, 0, 1))
		f.gesture("sursaut", 1.0)
		f.say("AAAAH ! LE RÉVEIL !", 2.5)
		await M.get_tree().create_timer(2.8).timeout
		if not M.inside:
			return
		M.talk(f, str(_pick(M, ["Ah, c'est toi ? Merci ! J'allais rater… ma sieste de l'après-midi. Bon. Bonne nuit.", "Quelle heure il est ? … Oh, c'est encore très tôt. Ou très tard. Bonne nuit !", "Tu m'as fait une de ces peurs ! J'ai cru que c'était lundi."])),
			[{"id": "fermer", "label": "Désolé ! Dors bien."}], func(_i):
			M.close_talk()
			f.lie(R.P(bx + 0.88, 0.5, bz), Vector3(-1, 0, 0)), "ensommeillé")
	, 1.0)
	M.ctx["entree"] = str(_pick(M, ["Chut… Quelqu'un dort. Et il ronfle comme un soufflet de forge.", "Une chambre dans la pénombre. Sous la couette, quelqu'un ronfle paisiblement.", "On entend des ronflements. Puis un sifflement. Puis encore des ronflements."]))


# =================================================================== la maison abandonnée (et son fantôme)

const HISTOIRES := [
	"« Nous partons chercher fortune à Astralys. On dit que là-haut, les rues sont pavées de cristal. Si tu lis ceci, prends ce qu'il y a dans le coffre : nous n'en aurons plus besoin. — La famille Delaunay »",
	"« Journal du capitaine Bourrache, jour 1 : j'achète cette maison. Jour 2 : une fuite au plafond. Jour 3 : deux fuites. Jour 4 : je repars en mer. C'est plus sec. »",
	"« À qui trouvera ce mot : j'ai caché mes économies dans le coffre, pour mes vieux jours. Je suis vieux maintenant. Et j'ai oublié où était la maison. Si tu me retrouves, garde tout. »",
	"« Chère maison, je te quitte pour une plus grande. Ce n'est pas toi, c'est moi. Enfin, c'est surtout les souris. »",
	"« Ici a vécu Gaspard, inventeur de la soupe froide chaude. Il est parti la faire goûter au roi. Il n'est jamais revenu. Le roi non plus, d'ailleurs. »",
	"« Partis en vacances. Revenons bientôt. — 12 ans plus tard : pas encore revenus. Les vacances, c'est bien. »",
]

static func _b_abandon(M, fantome: bool) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# la lumière est faible : le plafonnier est mort, un rai de jour (ou de lune) par les volets
	for l in R.lights:
		(l as OmniLight3D).light_energy *= 0.35
	R.drape(-0.2, 0.0, 0, 1.4, 0.9, 0.78)
	R.drape(-hw + 0.5, -hd * 0.3, 90, 1.2, 0.6, 1.9)
	R.drape(hw - 0.6, hd * 0.2, -90, 1.9, 0.85, 0.75)
	R.foyer(R.W * 0.18, -hd + 0.38, 0, false)
	R.toiles(4)
	R.poussiere(50)
	# une chaise renversée, des planches, des papiers par terre
	R.kit.box(R.L(0.9, 0.22, 1.0, 30) * Transform3D(Basis(Vector3.BACK, 1.45), Vector3.ZERO), Vector3(0.44, 0.05, 0.42), "bois_sombre", 1.0)
	for k in range(4):
		R.kit.box(R.L(r.randf_range(-hw + 1, hw - 1), 0.02, r.randf_range(-hd + 1, hd - 1.5), r.randf_range(0, 180)), Vector3(1.0, 0.03, 0.12), "bois_sombre", 1.0)
	for k2 in range(5):
		R.kit.box(R.L(r.randf_range(-hw + 0.8, hw - 0.8), 0.006, r.randf_range(-hd + 0.8, hd - 1.2), r.randf_range(0, 180)), Vector3(0.21, 0.004, 0.3), "papier", 1.0, 4)
	var ck: Vector3 = Vector3(hw - 0.9, 0, -hd + 0.75)
	M.chest(ck.x, ck.z, -20, M.loot(1.3))
	var histoire: String = str(HISTOIRES[hash(str(M.ctx["id"])) % HISTOIRES.size()])
	_mot(M, -0.5, 0.1, 0.79, "Un carnet couvert de poussière. Sur la dernière page : " + histoire, "E : lire le carnet poussiéreux")
	if r.randf() < 0.35 and not fantome:
		_trappe(M, 1.2, hd * 0.25, "abandon")
	if fantome:
		_fantome(M)
	else:
		M.ctx["entree"] = str(_pick(M, ["Personne n'habite plus ici depuis longtemps. Ça sent la poussière et le vieux bois.", "Une maison abandonnée. Les meubles dorment sous des draps blancs.", "Brrr. Une maison vide, des toiles d'araignée dans tous les coins… et un coffre, là-bas, au fond."]))
		M.ctx["on_enter"] = func(first: bool) -> void:
			if first:
				M.say(str(M.ctx["entree"]), 6.0)
			await M.get_tree().create_timer(4.0).timeout
			if M.inside:
				M.main.sfx("couinement_rat")


## Le « fantôme » : un drap qui flotte… et, dessous, un enfant du quartier très fier de lui.
static func _fantome(M) -> void:
	var R = M.R
	var r := _r(M)
	var gx: float = -R.W * 0.15
	var gz: float = -R.D * 0.2
	var kid: Node = M.person(str(_pick(M, ["garcon", "fille"])), gx, gz, 0, "debout")
	kid.follow = true
	var drap := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.18
	cm.bottom_radius = 0.42
	cm.height = 1.25
	cm.radial_segments = 16
	drap.mesh = cm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.95, 0.95, 0.93)
	m.roughness = 1.0
	drap.material_override = m
	kid.npc.add_child(drap)
	drap.position = Vector3(0, 0.62, 0)
	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.22
	sm.height = 0.44
	head.mesh = sm
	head.material_override = m
	head.position = Vector3(0, 1.3, 0)
	kid.npc.add_child(head)
	var eye := StandardMaterial3D.new()
	eye.albedo_color = Color(0.02, 0.02, 0.03)
	for sx in [-1.0, 1.0]:
		var e := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.045
		es.height = 0.09
		e.mesh = es
		e.material_override = eye
		e.position = Vector3(sx * 0.08, 1.35, 0.19)
		kid.npc.add_child(e)
	var model: Node3D = kid.npc.get("model")
	if model != null:
		model.visible = false
	var parts: Array = [drap, head]
	for c in kid.npc.get_children():
		if c is MeshInstance3D and c != drap and c != head:
			parts.append(c)
	kid.lines = ["Bouuuh…", "Hou hou hou…", "Je suis le fantôôôme de la maisoooon…"]
	kid.line_every = Vector2(4.0, 7.0)
	var reveal := func() -> void:
		for p in parts:
			if is_instance_valid(p):
				(p as Node3D).visible = false
		if model != null:
			model.visible = true
		M.state()["fantome"] = true
	if bool(M.state().get("fantome", false)):
		reveal.call()
		kid.lines = ["Tu reviens jouer ?", "Cette fois, je vais te faire peur pour de vrai !"]
	M.talk_spot(kid, func() -> void:
		if bool(M.state().get("fantome", false)):
			M.talk(kid, "Tu ne le diras à personne, que c'était moi, hein ? Je prépare un fantôme encore plus effrayant. Avec des chaînes. Et une casserole.",
				[{"id": "fermer", "label": "Promis !"}], func(_i): M.close_talk())
			return
		M.talk(kid, "BOUUUUH ! … Hé. Tu n'as même pas eu peur ?", [{"id": "peur", "label": "Si ! Très, très peur !"}, {"id": "non", "label": "Pas du tout. On voit tes pieds."}, {"id": "qui", "label": "Qui est sous ce drap ?"}], func(id):
			match id:
				"peur":
					reveal.call()
					kid.gesture("joie", 2.5)
					M.give([[str(_pick(M, ["coquillage", "caillou_chantant", "gland_dore", "etoile_mer", "plume_corbeau"])), 1]], "Le drap tombe : c'est un enfant du quartier, ravi. « Vrai ? Génial ! Tiens, mon trésor, pour ton courage ! » ")
					M.close_talk()
				"non":
					reveal.call()
					M.talk(kid, "Zut. Je m'entraîne depuis trois semaines… Ne le dis à personne, d'accord ?", [{"id": "fermer", "label": "Promis. Tu feras peur au prochain."}], func(_i): M.close_talk())
				_:
					M.talk(kid, "Personne ! Je suis un vrai fantôme ! Un fantôme qui doit rentrer avant le dîner, mais un vrai !", [{"id": "fermer", "label": "D'accord, d'accord…"}], func(_i): M.close_talk())
		)
		M.noop(), "E : approcher du fantôme")
	M.ctx["on_enter"] = func(first: bool) -> void:
		if first and not bool(M.state().get("fantome", false)):
			M.main.sfx("ombre_murmure")
			M.say("Une maison abandonnée… et, au milieu de la pièce, quelque chose de blanc qui flotte. Brrr.", 5.0)


# =================================================================== la cave secrète

static func _b_cave(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.foyer(R.W * 0.18, -hd + 0.38, 0, true)
	R.armoire(-hw + 0.35, -hd * 0.3, 90)
	R.fauteuil(hw - 0.8, -hd * 0.35, -120, str(_pick(M, ["rouge", "vert", "brun", "bleu"])))
	R.table_ronde(hw - 1.5, hd * 0.25, 0.5)
	_murs(M, 3)
	R.plante(-hw + 0.45, hd - 0.5)
	_trappe(M, -0.4, 0.2, str(_pick(M, ["fromages", "confitures", "tresor", "groupe", "champignons"])))
	var t: String = str(_pick(M, ["Une maison tranquille. Personne. Juste un beau tapis au milieu de la pièce… un peu bombé, d'ailleurs.", "Il n'y a personne. Le parquet craque sous tes pas. Surtout près du tapis.", "Une jolie maison vide. Sur la table, un mot : « Si tu trouves ma cave, je te laisse goûter. »"]))
	M.ctx["entree"] = t


## Un tapis qu'on soulève, une trappe, et une cave dessous (avec ce qu'il y a dedans).
static func _trappe(M, x: float, z: float, contenu: String) -> void:
	var R = M.R
	var r := _r(M)
	var tp: Vector3 = R.trappe(x, z)
	var rug: Node3D = R.movable(func(): R.kit.box(R.L(x, 0.055, z), Vector3(2.2, 0.012, 1.6), "tapis_0", 2.2, 4 + 16 + 32 + 1 + 2))
	var st: Dictionary = M.state()
	if bool(st.get("tapis", false)):
		rug.position = Vector3(1.6, 0, 0.6)
	var cave_at: Vector3 = M.STAGE + Vector3(0, M.CAVE_DY, 0)
	var C = (load("res://scripts/maisons_pieces_v81.gd") as Script).new()
	C.setup(M.room, M.main, cave_at, 6.0, 5.0, "cave", hash(str(M.ctx["id"]) + "cave"), float(M.ctx["hour"]))
	C.door_x = 0.0
	C.shell(false)
	_cave_contenu(M, C, contenu)
	C.echelle(0.0, 2.1, 180, 2.6)
	C.commit()
	var up: Vector3 = C.P(0.0, 0.05, 1.5)
	M.act(C.P(0.0, 0, 1.9), "E : remonter l'échelle", func(): M.go(tp + Vector3(0.9, 0.05, 0.6), Vector3(0, 0, -1)), 1.3)
	M.act(tp, "E : soulever le tapis", func() -> void:
		M.state()["tapis"] = true
		var tw: Tween = M.room.create_tween()
		tw.tween_property(rug, "position", Vector3(1.6, 0, 0.6), 0.6).set_trans(Tween.TRANS_QUAD)
		M.main.sfx("touche_bois")
		M.say("Sous le tapis… une trappe !", 4.0), 1.5, func(): return not bool(M.state().get("tapis", false)))
	M.act(tp, "E : descendre à la cave", func() -> void:
		M.main.sfx("grille")
		M.go(up, Vector3(0, 0, -1))
		if not bool(M.state().get("cave", false)):
			M.state()["cave"] = true
			await M.get_tree().create_timer(1.0).timeout
			M.say(str(M.ctx.get("cave_txt", "Une cave.")), 7.0)
	, 1.5, func(): return bool(M.state().get("tapis", false)))


static func _cave_contenu(M, C, contenu: String) -> void:
	var r := _r(M)
	C.toiles(3)
	C.foyer(-2.2, -1.8, 45, true)
	match contenu:
		"fromages":
			for i in range(3):
				C.etagere(-1.0 + i * 1.3, -2.25, 0, 1.2, 1.8, false, 4)
				for row in range(4):
					for k in range(3):
						C.kit.cyl(C.L(-1.4 + i * 1.3 + k * 0.38, 0.12 + row * 0.42, -2.25), 0.16, 0.16, 0.1, "fromage", 14)
			C.tonneau(2.3, -1.0)
			M.ctx["cave_txt"] = "Une cave à fromages ! Des dizaines de meules… et une odeur à faire pleurer un oignon."
			_mot_c(M, C, 1.2, 0.5, "Sur une ardoise : « Défense de goûter. Sauf toi, voyageur. Une seule. — Le fromager du dessus »")
			M.chest(2.0, 0.6, -90, [["fromage_chevre", 2], ["piece", 8 + r.randi() % 10]], "coffre_cave")
		"confitures":
			for i in range(3):
				C.etagere(-1.0 + i * 1.3, -2.25, 0, 1.2, 1.9, false, 5)
				for row in range(5):
					for k in range(5):
						C.kit.cyl(C.L(-1.45 + i * 1.3 + k * 0.22, 0.1 + row * 0.36, -2.25), 0.06, 0.06, 0.13, ["confiture", "pomme", "fromage", "soupe"][(row + k + i) % 4], 10)
			M.ctx["cave_txt"] = "Une cave pleine de pots de confiture. Des centaines. Il y a même une confiture de… cornichons ?"
			_mot_c(M, C, 1.2, 0.5, "Une étiquette sur la porte : « Réserve de Mamie. 412 pots. Je les ai comptés. Prends-en un, va. »")
			M.chest(2.0, 0.6, -90, [["miel", 1], ["jus_pomme", 1], ["piece", 5 + r.randi() % 8]], "coffre_cave")
		"tresor":
			C.tonneau(-2.3, 1.2)
			C.tonneau(-1.6, 1.6)
			C.caisse(2.2, -1.2, 0.7)
			C.caisse(2.3, -0.4, 0.5)
			M.ctx["cave_txt"] = "Une vieille cave voûtée. Au fond, un coffre cerclé de fer… Le trésor du grand-père ?"
			M.chest(0.0, -1.7, 0, M.loot(2.0) + [["piece_or", 1]], "coffre_cave")
			_mot_c(M, C, 1.2, 0.8, "Gravé sur une poutre : « Le trésor de Papi : à partager avec qui le trouvera. Sauf les pièces en chocolat : celles-là, c'est pour moi. »")
		"groupe":
			for k2 in range(3):
				C.kit.cyl(C.L(-1.2 + k2 * 0.8, 0, -1.6), 0.25, 0.25, 0.5 + k2 * 0.05, ["tissu_rouge", "tissu_noir", "argent"][k2], 14)
			C.kit.box(C.L(1.5, 0.6, -2.4), Vector3(1.0, 1.2, 0.5), "noir", 1.0)
			C.tableau(0.0, 1.5, -2.48, 0, 1.2, 0.9)
			C.tapis(0.0, -0.8, 0, 2.6, 1.8)
			M.ctx["cave_txt"] = "Une salle de répétition secrète ! Une batterie, un ampli, des affiches… et des boules de coton sur les murs pour que les voisins n'entendent rien."
			_mot_c(M, C, 1.2, 0.5, "Une affiche : « LES TAUPES HURLANTES — concert samedi — entrée : un gâteau » ")
			M.chest(2.0, 0.6, -90, [["piece", 12 + r.randi() % 10], ["partition", 1]], "coffre_cave")
		_:
			for k3 in range(14):
				var p := Vector3(r.randf_range(-2.4, 2.4), 0, r.randf_range(-2.0, 0.8))
				C.kit.cyl(C.L(p.x, 0, p.z), 0.03, 0.035, 0.25, "ceramique", 8)
				C.kit.cyl(C.L(p.x, 0.25, p.z), 0.14, 0.02, 0.08, "pomme", 12)
			var l := OmniLight3D.new()
			l.light_color = Color(0.5, 1.0, 0.7)
			l.light_energy = 0.8
			l.omni_range = 5.0
			C.root.add_child(l)
			l.global_position = C.P(0, 0.5, -0.6)
			M.ctx["cave_txt"] = "Une champignonnière secrète ! Des champignons partout… et certains brillent dans le noir."
			M.chest(2.0, 0.6, -90, [["champignon", 3], ["champignon_lune", 1], ["piece", 6 + r.randi() % 8]], "coffre_cave")


static func _mot_c(M, C, x: float, z: float, text: String) -> void:
	C.kit.box(C.L(x, 0.9, z), Vector3(0.6, 0.04, 0.4), "bois", 1.0)
	C.kit.box(C.L(x, 0.45, z), Vector3(0.08, 0.9, 0.08), "bois_sombre", 1.0)
	C.kit.box(C.L(x, 0.925, z, 15), Vector3(0.2, 0.006, 0.14), "papier", 1.0, 4)
	M.act(C.P(x, 0, z), "E : lire", func(): M.say(text, 8.0), 1.2)


# =================================================================== la bibliothèque qui pivote

static func _b_biblio(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# des bibliothèques sur le fond et les côtés
	var n: int = maxi(2, int((R.W - 1.0) / 1.25))
	var secret_i: int = r.randi() % n
	var secret_x: float = 0.0
	for i in range(n):
		var x: float = -hw + 0.7 + i * ((R.W - 1.4) / maxf(1.0, n - 1))
		if i == secret_i:
			secret_x = x
			continue
		R.etagere(x, -hd + 0.22, 0, 1.2, minf(2.3, R.H - 0.3), true, 5)
	R.etagere(-hw + 0.22, hd * 0.25, 90, 1.2, minf(2.3, R.H - 0.3), true, 5)
	R.fauteuil(hw - 1.0, 0.2, -110, str(_pick(M, ["rouge", "vert", "brun"])))
	R.table_ronde(hw - 1.9, 0.6, 0.45)
	R.pile(0.6, 0.0, "livres", 6)
	R.pile(-0.8, 0.9, "livres", 4)
	R.tapis(0.0, 0.3, 0, 2.6, 1.8)
	R.bougie(hw - 1.9, 0.76, 0.6)
	var lecteur: Node = null
	if r.randf() < 0.5:
		lecteur = M.person(str(_pick(M, ["vieux", "vieille", "homme", "femme"])), hw - 1.0, 0.2, -110, "lire")
		lecteur.lines = ["Chut… je lis.", "Mmh… passionnant.", "Encore un chapitre…"]
	# le mur derrière la bibliothèque secrète est percé : un passage
	R.kit.box(R.L(secret_x, 1.05, -hd - 0.01), Vector3(1.0, 2.1, 0.02), "noir", 1.0, 16)
	var shelf: Node3D = R.movable(func():
		R.etagere(secret_x, -hd + 0.22, 0, 1.2, minf(2.3, R.H - 0.3), true, 5)
		R.kit.box(R.L(secret_x + 0.35, 1.35, -hd + 0.33), Vector3(0.06, 0.3, 0.22), "tissu_rouge", 1.0))
	var st: Dictionary = M.state()
	if bool(st.get("passage", false)):
		shelf.position = Vector3(1.25, 0, 0)
	# la pièce secrète, à côté
	var sec_at: Vector3 = M.STAGE + Vector3(M.SECRET_DX, 0, 0)
	var S = (load("res://scripts/maisons_pieces_v81.gd") as Script).new()
	S.setup(M.room, M.main, sec_at, 4.6, 4.2, str(M.ctx["style"]), hash(str(M.ctx["id"]) + "secret"), float(M.ctx["hour"]))
	S.door_x = 0.0
	S.shell(false)
	var quoi: String = str(_pick(M, ["canards", "chat", "trone", "plans", "tresor"]))
	_secret_contenu(M, S, quoi)
	S.commit()
	M.act(S.P(0, 0, 1.6), "E : repasser par la bibliothèque", func(): M.go(R.P(secret_x, 0.05, -hd + 1.0), Vector3(0, 0, 1)), 1.3)
	var book: Vector3 = R.P(secret_x, 0, -hd + 0.9)
	M.act(book, "E : tirer le livre rouge", func() -> void:
		M.state()["passage"] = true
		M.main.sfx("mecanisme", book)
		var tw: Tween = M.room.create_tween()
		tw.tween_interval(0.4)
		tw.tween_property(shelf, "position", Vector3(1.25, 0, 0), 1.6).set_trans(Tween.TRANS_SINE)
		M.main.sfx("pierre_glisse", book)
		if lecteur != null:
			lecteur.say("Oh. Tu as trouvé. Bon… ne dis rien à personne.", 4.0)
		else:
			M.say("Clic. La bibliothèque pivote… un passage secret !", 4.0)
	, 1.3, func(): return not bool(M.state().get("passage", false)))
	M.act(book, "E : entrer dans le passage secret", func() -> void:
		M.go(S.P(0, 0.05, 1.2), Vector3(0, 0, -1))
		if not bool(M.state().get("secret_vu", false)):
			M.state()["secret_vu"] = true
			await M.get_tree().create_timer(1.0).timeout
			M.say(str(M.ctx.get("secret_txt", "")), 7.0)
	, 1.3, func(): return bool(M.state().get("passage", false)))
	M.ctx["entree"] = str(_pick(M, ["Des livres du sol au plafond. Ça sent le vieux papier… et le mystère.", "Une bibliothèque immense pour une si petite maison. Un des livres, tout rouge, dépasse un peu.", "Que de livres ! Tous bien rangés… sauf un, rouge, qui n'est pas tout à fait à sa place."]))


static func _secret_contenu(M, S, quoi: String) -> void:
	var r := _r(M)
	match quoi:
		"canards":
			S.etagere(-1.4, -1.85, 0, 1.4, 2.0, false, 4)
			S.etagere(1.0, -1.85, 0, 1.4, 2.0, false, 4)
			for i in range(2):
				for row in range(4):
					for k in range(6):
						var x: float = (-2.0 if i == 0 else 0.4) + k * 0.21
						var y: float = 0.11 + row * 0.47
						S.kit.cyl(S.L(x, y, -1.85), 0.07, 0.06, 0.08, "fromage", 10)
						S.kit.cyl(S.L(x + 0.04, y + 0.08, -1.85), 0.045, 0.04, 0.06, "fromage", 10)
						S.kit.box(S.L(x + 0.1, y + 0.1, -1.85), Vector3(0.04, 0.015, 0.03), "terre_cuite", 1.0)
			M.ctx["secret_txt"] = "Le musée secret du canard en caoutchouc ! Cent quarante-quatre canards, rangés par taille. Et un panneau : « NE PAS LES FAIRE COUINER »."
			M.chest(1.6, 0.5, -90, [["canard_mecanique", 1], ["piece", 10 + r.randi() % 10]], "coffre_secret")
		"chat":
			for k2 in range(6):
				S.tableau(-1.8 + k2 * 0.72, 1.5 + (k2 % 2) * 0.35, -2.08, 0, 0.55, 0.45)
			S.fauteuil(0, -0.8, 0, "rouge")
			S.chat(0.0, -0.75, 0, Color(0.95, 0.6, 0.25), true, 0.48)
			M.ctx["secret_txt"] = "Une pièce secrète… pleine de portraits du même chat. Le chat en personne trône dans un fauteuil de velours. Il te regarde comme si TU étais l'intrus."
			M.chest(1.6, 0.5, -90, [["sardine", 2], ["piece", 8 + r.randi() % 10]], "coffre_secret")
		"trone":
			for k3 in range(10):
				S.kit.box(S.L(r.randf_range(-0.6, 0.6), 0.15 + k3 * 0.12, -1.3 + r.randf_range(-0.3, 0.3), r.randf_range(0, 90)), Vector3(0.6, 0.14, 0.5), "tissu_" + str(_pick(M, ["rouge", "violet", "jaune", "bleu", "rose"])), 1.0)
			S.kit.cyl(S.L(0, 1.45, -1.3), 0.14, 0.17, 0.12, "or", 8, false)
			M.ctx["secret_txt"] = "Une pièce secrète, et au fond, un trône… fait de coussins empilés, coiffé d'une couronne en papier doré. Sur une pancarte : « Ici règne Sa Majesté le Roi des Coussins. »"
			M.chest(1.6, 0.5, -90, [["piece_or", 1], ["piece", 6 + r.randi() % 10]], "coffre_secret")
		"plans":
			S.table(0, -1.0, 0, 1.6, 0.9)
			for k4 in range(5):
				S.kit.box(S.L(r.randf_range(-0.6, 0.6), 0.795, -1.0 + r.randf_range(-0.3, 0.3), r.randf_range(-40, 40)), Vector3(0.3, 0.005, 0.22), "papier", 1.0, 4)
			S.tableau(0, 1.6, -2.08, 0, 1.4, 0.9)
			M.ctx["secret_txt"] = "Une pièce secrète, des plans partout sur la table."
			_mot(M, 0.0, -1.0, 0.0, "« PLAN POUR CONQUÉRIR LE MONDE. Étape 1 : se lever tôt. Étape 2 : prendre un bon petit-déjeuner. Étape 3 : … bon, on verra demain. »", "E : lire les plans")
			M.chest(1.6, 0.5, -90, [["boussole_sud", 1], ["piece", 8 + r.randi() % 10]], "coffre_secret")
		_:
			S.tonneau(-1.6, -1.4)
			S.caisse(-0.9, -1.6, 0.6)
			M.ctx["secret_txt"] = "Une petite pièce secrète. Un seul meuble : un coffre. Le genre de coffre qu'on cache derrière une bibliothèque."
			M.chest(0.4, -1.3, 0, M.loot(1.8), "coffre_secret")


# =================================================================== la dame aux chats

const NOMS_CHATS := ["Moustache", "Pompon", "Caramel", "Réglisse", "Plume", "Sardine", "Grisou", "Biscotte", "Filou", "Pacha", "Noisette", "Mistigri", "Patapouf", "Cornichon", "Brioche", "Moka"]

static func _b_chats(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.foyer(R.W * 0.18, -hd + 0.38, 0, true)
	R.fauteuil(-hw + 1.1, -hd * 0.2, 60, str(_pick(M, ["rose", "rouge", "violet"])))
	R.tapis(0.0, 0.0, 0, 2.6, 1.8)
	R.armoire(hw - 0.35, -hd * 0.35, -90)
	_murs(M, 3)
	# l'arbre à chat, les gamelles, les pelotes
	R.kit.cyl(R.L(hw - 1.0, 0, hd * 0.3), 0.08, 0.08, 1.6, "tissu_creme", 8)
	for y in [0.5, 1.0, 1.6]:
		R.kit.box(R.L(hw - 1.0, y, hd * 0.3), Vector3(0.6, 0.06, 0.5), "tissu_creme", 1.0)
	for k in range(4):
		R.kit.cyl(R.L(-0.8 + k * 0.4, 0, hd - 1.3), 0.12, 0.1, 0.06, "ceramique", 12)
	for k2 in range(3):
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.08
		sm.height = 0.16
		mi.mesh = sm
		mi.material_override = R.mat("tissu_" + str(["rouge", "bleu", "jaune"][k2]))
		M.room.add_child(mi)
		mi.global_position = R.P(r.randf_range(-1.5, 1.5), 0.08, r.randf_range(-0.5, 1.0))
	var cols: Array = [Color(0.95, 0.6, 0.25), Color(0.15, 0.15, 0.17), Color(0.92, 0.92, 0.9), Color(0.55, 0.55, 0.58), Color(0.6, 0.42, 0.28), Color(0.95, 0.85, 0.7)]
	var spots: Array = [[0.4, 0.3, false, 0.0], [-0.6, -0.3, true, 0.0], [hw - 1.0, hd * 0.3, true, 1.66], [hw - 1.0, hd * 0.3, false, 1.06], [1.2, 0.8, true, 0.0],
		[-hw + 1.1, -hd * 0.2 + 0.05, true, 0.52], [0.0, hd - 1.3, false, 0.0], [R.W * 0.18, -hd + 1.2, true, 0.0], [-1.4, 1.0, false, 0.0]]
	var n: int = 6 + r.randi() % 4
	for i in range(mini(n, spots.size())):
		var s: Array = spots[i]
		R.chat(float(s[0]), float(s[1]), r.randf_range(0, 360), cols[r.randi() % cols.size()], bool(s[2]), float(s[3]))
	var dame: Node = M.person(str(_pick(M, ["vieille", "vieille", "vieux", "femme"])), -hw + 1.1, -hd * 0.2, 60, "tricot")
	dame.lines = ["Pompon, descends de là.", "Qui veut des croquettes ?", "Mistigri, laisse la pelote !", "Mes bébés…"]
	var noms: Array = NOMS_CHATS.duplicate()
	noms.shuffle()
	M.talk_spot(dame, func() -> void:
		var choices: Array = [{"id": "noms", "label": "Comment ils s'appellent ?"}, {"id": "combien", "label": "Vous avez combien de chats ?"}]
		var inv: Node = M.main.get("inventory_v28")
		var fish: String = ""
		if inv != null:
			for f in ["sardine", "maquereau", "dorade", "bar"]:
				if int(inv.count(f)) > 0:
					fish = f
					break
		if fish != "" and not bool(M.state().get("poisson", false)):
			choices.append({"id": "poisson", "label": "Tenez, un poisson pour eux !"})
		choices.append({"id": "fermer", "label": "Au revoir, et au revoir les chats !"})
		M.talk(dame, str(_pick(M, ["Bonjour, mon petit ! Attention où tu mets les pieds : il y a un chat partout.", "Oh, de la visite ! Les chats adorent la visite. Enfin… certains.", "Entre, entre ! Et ferme la porte, sinon Filou va encore filer."])), choices, func(id):
			match id:
				"noms":
					M.talk(dame, "Alors… %s, %s, %s, %s, %s… et le gros, là, c'est %s. Il est au régime. Il ne le sait pas." % [noms[0], noms[1], noms[2], noms[3], noms[4], noms[5]],
						[{"id": "fermer", "label": "Ils sont adorables."}], func(_i): M.close_talk())
				"combien":
					M.talk(dame, str(_pick(M, ["Onze. Ou douze. %s compte pour deux." % noms[0], "Je ne les compte plus. C'est eux qui me comptent, le soir.", "Neuf ! Comme les vies d'un chat. C'est pratique, ça fait un chat par vie."])),
						[{"id": "fermer", "label": "Ah oui, quand même !"}], func(_i): M.close_talk())
				"poisson":
					M.main.inventory_v28.remove(fish, 1)
					M.state()["poisson"] = true
					M.main.sfx("chat_miaou")
					M.give([["piece", 15 + r.randi() % 10], [["clochette_argent", "plume_corbeau", "gland_dore"][r.randi() % 3], 1]], "Tous les chats accourent ! La dame est ravie : « Tu es adopté. Par eux. C'est un honneur ! » ")
					M.close_talk()
				_:
					M.close_talk()
		), "E : parler à la dame aux chats" if Gens_role_f(dame) else "")
	M.ctx["on_enter"] = func(first: bool) -> void:
		M.main.sfx("miaou")
		if first:
			M.say(str(_pick(M, ["Des chats. Partout. Sur le fauteuil, sous la table, en haut de l'armoire…", "Miaou. Miaou ? Miaaaou. Cette maison appartient visiblement aux chats.", "Un chat roux te fixe. Puis un noir. Puis un blanc. Tu es en infériorité numérique."])), 5.0)
		for i in range(3):
			await M.get_tree().create_timer(5.0 + i * 6.0).timeout
			if M.inside:
				M.main.sfx(["miaou", "ronron", "chat_miaou"][i % 3])


static func Gens_role_f(f: Node) -> bool:
	var p: Dictionary = f.npc.get("profile")
	return bool(p.get("femme", false))


# =================================================================== la fête surprise

static func _b_surprise(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.table(0.0, -hd * 0.35, 0, 1.6, 0.9, 0.76, "rose")
	R.gateau(0.0, 0.79, -hd * 0.35)
	R.couverts(0.0, -hd * 0.35 + 0.0, 0.79, [Vector2(-0.55, 0.2), Vector2(0.55, 0.2), Vector2(-0.55, -0.2), Vector2(0.55, -0.2)], "gateau")
	R.guirlande(R.P(-hw + 0.1, R.H - 0.3, -hd + 0.4), R.P(hw - 0.1, R.H - 0.3, -hd + 0.4), 14)
	R.guirlande(R.P(-hw + 0.1, R.H - 0.35, hd * 0.3), R.P(hw - 0.1, R.H - 0.35, hd * 0.3), 14)
	for k in range(7):
		R.ballon(r.randf_range(-hw + 0.6, hw - 0.6), R.H - 0.35 - r.randf_range(0.0, 0.3), r.randf_range(-hd + 0.6, hd - 1.2), str(_pick(M, ["rouge", "jaune", "bleu", "vert", "rose", "orange", "violet"])))
	R.canape(-hw + 0.6, hd * 0.15, 90, str(_pick(M, ["vert", "bleu", "jaune"])))
	R.armoire(hw - 0.35, hd * 0.1, -90)
	_murs(M, 2)
	var heros: String = str(_pick(M, ["Gérard", "Tante Ursule", "Bernadette", "Tonton Firmin", "Mamie Lou", "Hector", "Pépita", "Grand-Oncle Barnabé"]))
	var cache: Array = [[-hw + 1.3, hd * 0.15 - 0.6, 90.0], [hw - 1.0, hd * 0.1 + 0.75, -90.0], [0.0, -hd * 0.35 - 0.8, 0.0], [-0.9, -hd * 0.35 + 0.9, 180.0]]
	var gens: Array = []
	var roles: Array = ["femme", "homme", str(_pick(M, ["garcon", "fille"])), str(_pick(M, ["vieux", "vieille", "femme"]))]
	var fete_finie: bool = bool(M.state().get("fete", false))
	for i in range(4):
		var c: Array = cache[i]
		var f: Node = M.person(roles[i], float(c[0]), float(c[1]), float(c[2]), "cache" if not fete_finie else "danse")
		gens.append(f)
	if fete_finie:
		for g in gens:
			g.lines = ["Encore du gâteau ?", "Quelle fête !", heros + " a pleuré de joie !", "On danse !"]
		M.talk_spot(gens[0], func() -> void:
			M.talk(gens[0], str(_pick(M, [heros + " est venu, finalement ! Bon… il est reparti chercher des chaises. Reste danser avec nous !", "La fête est réussie ! " + heros + " a soufflé ses bougies du premier coup. Bon, du troisième."])),
				[{"id": "fermer", "label": "Bonne fête à tous !"}], func(_i): M.close_talk())
		)
		M.ctx["entree"] = "La fête bat son plein ! Les ballons, la musique, des miettes de gâteau partout."
		return
	for l in R.lights:
		(l as OmniLight3D).visible = false
	M.ctx["on_enter"] = func(first: bool) -> void:
		await M.get_tree().create_timer(1.1).timeout
		if not M.inside:
			return
		for l in R.lights:
			if is_instance_valid(l):
				(l as OmniLight3D).visible = true
		M.main.sfx("confettis_canon")
		for g in gens:
			g.set_pose("applaudir", Vector3.ZERO)
			g.say("SURPRIIIISE !", 2.5)
		var cp := CPUParticles3D.new()
		cp.one_shot = true
		cp.amount = 120
		cp.lifetime = 2.5
		cp.explosiveness = 0.9
		cp.direction = Vector3.UP
		cp.spread = 60.0
		cp.initial_velocity_min = 2.0
		cp.initial_velocity_max = 4.0
		cp.gravity = Vector3(0, -2.0, 0)
		var q := QuadMesh.new()
		q.size = Vector2(0.05, 0.05)
		var qm := StandardMaterial3D.new()
		qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		qm.vertex_color_use_as_albedo = true
		q.material = qm
		cp.mesh = q
		var grad := Gradient.new()
		grad.set_color(0, Color(1, 0.3, 0.4))
		grad.add_point(0.33, Color(0.3, 0.6, 1))
		grad.add_point(0.66, Color(1, 0.9, 0.2))
		grad.set_color(grad.get_point_count() - 1, Color(0.4, 1, 0.5))
		cp.color_ramp = grad
		cp.color_initial_ramp = grad
		M.room.add_child(cp)
		cp.global_position = R.P(0, 1.2, 0)
		cp.emitting = true
		await M.get_tree().create_timer(2.6).timeout
		if not M.inside:
			return
		for g in gens:
			g.set_pose("debout", Vector3.ZERO)
		M.talk(gens[0], "… Ah. Ce n'est pas %s." % heros, [{"id": "joyeux", "label": "Joyeux anniversaire… à %s ?" % heros}, {"id": "gateau", "label": "Je peux avoir du gâteau quand même ?"}, {"id": "cacher", "label": "Je me cache avec vous ?"}], func(id):
			M.state()["fete"] = true
			match id:
				"joyeux":
					M.talk(gens[1], "C'est gentil ! On le lui dira. Tiens, prends une part de gâteau, on en a fait beaucoup trop.", [{"id": "fermer", "label": "Merci !"}], func(_i):
						M.give([[_gateau_item(str(M.ctx["style"])), 1]], "")
						M.close_talk())
				"gateau":
					M.talk(gens[2], "Ouiii ! Moi aussi je veux du gâteau !", [{"id": "fermer", "label": "(Partager le gâteau)"}], func(_i):
						M.give([[_gateau_item(str(M.ctx["style"])), 1]], "Une part de gâteau rien que pour toi ! ")
						M.close_talk())
				_:
					M.talk(gens[3], "Vite, vite ! Derrière le canapé ! … Bon, il ne viendra peut-être pas avant ce soir. Tu veux une part de gâteau, en attendant ?", [{"id": "fermer", "label": "Avec plaisir !"}], func(_i):
						M.give([[_gateau_item(str(M.ctx["style"])), 1]], "")
						M.close_talk())
			for g in gens:
				g.set_pose("danse", Vector3.ZERO)
				g.lines = ["Quelle fête !", "Encore du gâteau ?", "Où est passé " + heros + " ?"]
		)


static func _gateau_item(style: String) -> String:
	match style:
		"ramure":
			return "gateau_lune"
		"egypte":
			return "gateau_miel"
		"astralys":
			return "biscuit_lunaire"
		"braise":
			return "brioche_braise"
		"cliquetis":
			return "biscuit_engrenage"
	return "gateau_miel"


# =================================================================== l'inventeur

const GADGETS := ["montre_envers", "boite_a_rien", "canard_mecanique", "tasse_tourneuse", "lunettes_kaleido", "chaussettes_vapeur", "sifflet_muet", "boussole_sud", "parapluie_helice", "chapeau_ventilateur"]

static func _b_inventeur(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.etabli(-hw + 1.3, -hd + 0.55, 0, 2.0)
	var bouton: Vector3 = R.machine(hw - 1.3, -hd + 0.9, -20)
	R.etagere(hw - 0.22, hd * 0.25, -90, 1.0, 1.8, false, 4)
	for k in range(6):
		R.kit.cyl(R.L(hw - 0.22, 0.15 + (k % 4) * 0.45, hd * 0.25 - 0.35 + (k % 3) * 0.3), 0.08, 0.06, 0.14, ["cuivre", "fer", "verre", "or"][k % 4], 10)
	R.pile(0.5, 0.8, "papier", 6)
	R.caisse(-hw + 0.6, hd * 0.3, 0.6)
	R.caisse(-hw + 0.6, hd * 0.3, 0.45, 0.6)
	R.tableau(-hw + 0.02, 1.7, -hd * 0.1, 90, 1.0, 0.7)
	var f: Node = M.person(str(_pick(M, ["vieux", "homme", "femme", "vieille"])), -hw + 1.3, -hd + 1.25, 180, "bricoler")
	f.lines = ["Encore un boulon…", "Eurêka ! … non.", "Où est ma clé de 12 ?", "Ça devrait marcher. En théorie."]
	var nm: String = str(f.npc.display_name)
	var boum := func() -> void:
		M.main.sfx("boum", bouton)
		var cb: Node = M.main.get("combat_v28")
		if cb != null and cb.has_method("puff"):
			for k2 in range(4):
				cb.puff(bouton + Vector3(r.randf_range(-0.5, 0.5), 0.8 + k2 * 0.3, r.randf_range(-0.5, 0.5)), Color(0.25, 0.24, 0.22))
		f.gesture("sursaut", 1.2)
		await M.get_tree().create_timer(1.4).timeout
		if not M.inside:
			return
		if not bool(M.state().get("gadget", false)):
			M.state()["gadget"] = true
			var g: String = str(GADGETS[hash(str(M.ctx["id"])) % GADGETS.size()])
			M.talk(f, str(_pick(M, ["Parfait ! … Enfin, presque. Tiens, pour ta peine : ma dernière invention. Ne me demande pas à quoi elle sert.", "*tousse* Formidable ! On a un résultat ! Je ne sais pas lequel, mais on en a un. Prends ça, tu l'as bien mérité.", "Ha ha ! La machine a parlé ! Elle a dit « BOUM », mais elle a parlé ! Garde ce petit souvenir."])),
				[{"id": "fermer", "label": "Euh… merci ?"}], func(_i):
				M.give([[g, 1]], "")
				M.close_talk())
		else:
			M.talk(f, str(_pick(M, ["Encore ?! Tu aimes les explosions, toi. Moi aussi.", "Toujours BOUM. C'est constant, au moins. La science avance !"])), [{"id": "fermer", "label": "Ha ha !"}], func(_i): M.close_talk())
	M.talk_spot(f, func() -> void:
		M.talk(f, str(_pick(M, ["Ah ! Un assistant ! Tu tombes à pic. Appuie sur le bouton rouge, là-bas. Non, pas celui-là. L'autre. Voilà.", "Bienvenue dans mon atelier ! Attention aux fils. Et aux étincelles. Et au chat. Tu veux m'aider à tester ma machine ?", "Chut ! Je suis à deux doigts d'une découverte. Ou d'une explosion. Tu veux appuyer sur le bouton ?"])),
			[{"id": "appuyer", "label": "Appuyer sur le bouton rouge"}, {"id": "non", "label": "Ça m'a l'air dangereux…"}], func(id):
			if id == "appuyer":
				M.close_talk()
				boum.call()
			else:
				M.talk(f, "Sage décision. La dernière fois, j'ai perdu mes sourcils. Ils ont repoussé, mais à l'envers.", [{"id": "fermer", "label": "Bon courage !"}], func(_i): M.close_talk())
		, "un peu fou"))
	M.act(bouton, "E : appuyer sur le bouton rouge", func(): boum.call(), 1.1)
	M.ctx["entree"] = str(_pick(M, ["Un atelier en désordre. Des engrenages, des fils, une machine qui fume un peu… et quelqu'un qui marmonne des calculs.", "Ça sent l'huile et le brûlé. Au fond, une machine pleine de voyants clignote joyeusement.", "Des plans au mur, des outils partout. Un inventeur, penché sur son établi, ne t'a pas entendu entrer."]))


# =================================================================== cache-cache

static func _b_cache(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var bx: float = -hw + 0.7
	R.lit(bx, -hd * 0.15, 90, 1.0, "rouge", true)
	R.armoire(hw - 0.35, -hd * 0.3, -90)
	R.tonneau(hw - 0.6, hd * 0.35)
	R.coffre_deco(0.5, -hd + 0.5, 0)
	R.tapis(0.3, 0.3, 0, 2.0, 1.4)
	R.pile(0.0, 0.8, "livres", 3)
	for k in range(5):
		R.kit.box(R.L(r.randf_range(-1, 1.5), 0.05, r.randf_range(-0.5, 1.0), r.randf_range(0, 90)), Vector3(0.12, 0.1, 0.12), ["tissu_rouge", "tissu_bleu", "tissu_jaune", "bois_clair"][k % 4], 1.0)
	_murs(M, 2)
	var caches: Array = [
		["armoire", R.P(hw - 0.9, 0, -hd * 0.3), "E : ouvrir l'armoire", R.P(hw - 1.0, 0, -hd * 0.3 + 0.2)],
		["lit", R.P(bx + 0.9, 0, -hd * 0.15), "E : regarder sous le lit", R.P(bx + 1.0, 0, -hd * 0.15 + 0.4)],
		["tonneau", R.P(hw - 1.2, 0, hd * 0.35), "E : regarder derrière le tonneau", R.P(hw - 1.1, 0, hd * 0.35 - 0.4)],
		["coffre", R.P(0.5, 0, -hd + 1.1), "E : ouvrir le coffre à jouets", R.P(0.5, 0, -hd + 1.2)],
	]
	var visite: int = int(M.state().get("cache_n", 0))
	var ou: int = (hash(str(M.ctx["id"])) + visite) % caches.size()
	var kid: Node = M.person(str(_pick(M, ["garcon", "fille"])), 0, 0, 0, "cache")
	kid.npc.visible = false
	var trouve: Array = [false]
	var rates := {"armoire": "Des vêtements, une chaussette orpheline… et une odeur de naphtaline. Personne.", "lit": "Sous le lit : trois moutons de poussière et une bille. Personne.",
		"tonneau": "Derrière le tonneau : une araignée qui te regarde. Elle non plus n'a vu personne.", "coffre": "Dans le coffre : des jouets, une épée en bois, un ours en peluche borgne. Personne."}
	for i in range(caches.size()):
		var c: Array = caches[i]
		var ii: int = i
		M.act(c[1], str(c[2]), func() -> void:
			if trouve[0]:
				return
			if ii == ou:
				trouve[0] = true
				kid.npc.visible = true
				kid.npc.global_position = c[3]
				kid.set_pose("debout", (R.P(R.door_x, 0, 0) - (c[3] as Vector3)))
				kid.gesture("joie", 2.0)
				M.state()["cache_n"] = visite + 1
				if not bool(M.state().get("cache_cadeau", false)):
					M.state()["cache_cadeau"] = true
					M.talk(kid, str(_pick(M, ["Ooooh ! Tu m'as trouvé ! Personne ne me trouve jamais ! Tiens, c'est mon trésor. Enfin, un de mes trésors.", "Trouvé ! Zut ! T'es trop fort. Tiens, pour le gagnant !", "Ah non ! Pas déjà ! … Bon, d'accord, t'as gagné. Voilà ton prix."])),
						[{"id": "fermer", "label": "Merci ! Tu te caches bien, tu sais."}], func(_i):
						M.give([[str(_pick(M, ["coquillage", "caillou_chantant", "gland_dore", "etoile_mer", "cochonnet", "plume_corbeau"])), 1], ["piece", 3 + r.randi() % 5]], "")
						M.close_talk())
				else:
					M.talk(kid, "Encore trouvé ! La prochaine fois, je me cache dans la cheminée. Non, je rigole. Ou pas.", [{"id": "fermer", "label": "Ha ha ! À la prochaine !"}], func(_i): M.close_talk())
			else:
				M.say(str(rates[str(c[0])]), 4.0)
				await M.get_tree().create_timer(1.2).timeout
				if M.inside and not trouve[0]:
					M.say("Une petite voix étouffée : « Hi hi hi… froid… tout froid ! »", 3.5)
		, 1.2, func(): return not trouve[0])
	M.ctx["on_enter"] = func(first: bool) -> void:
		await M.get_tree().create_timer(0.8).timeout
		if M.inside:
			M.say(str(_pick(M, ["Une petite voix, quelque part : « Un, deux, trois… Non ! C'est toi qui cherches ! Tu ne me trouveras jamais ! »", "On entend un gloussement étouffé. Quelqu'un joue à cache-cache… et compte sur toi pour chercher.", "« Je suis caché ! Cherche-moi ! » dit une voix d'enfant. La chambre est en désordre : il y a des cachettes partout."])), 7.0)


# =================================================================== le musicien

static func _b_musicien(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var inst: String = str(_pick(M, ["violon", "guitare"]))
	if r.randf() < 0.4:
		R.piano(-hw + 1.4, -hd + 0.45, 0)
	R.tapis(0.2, 0.0, 0, 2.2, 1.6)
	R.canape(hw - 0.6, 0.0, -90, str(_pick(M, ["rouge", "vert", "violet"])))
	R.etagere(-hw + 0.22, hd * 0.2, 90, 1.0, 1.7, true, 4)
	R.kit.box(R.L(0.8, 0.6, -hd * 0.3, 10), Vector3(0.05, 1.2, 0.05), "fer", 1.0)
	R.kit.box(R.L(0.8, 1.2, -hd * 0.3, 10) * Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3.ZERO), Vector3(0.45, 0.3, 0.02), "papier", 1.0)
	_murs(M, 3)
	var f: Node = M.person(str(_pick(M, ["homme", "femme", "vieux", "garcon", "fille"])), 0.4, -hd * 0.1, 180, inst)
	f.lines = ["♪ Pouêêêt ♪", "♫ Scriiiiii ♫", "♪ Plonk… plonk… ♪", "♫ Grrriiinng ♫", "Attends, je reprends…", "♪ La la… ♪"]
	f.line_every = Vector2(2.5, 4.5)
	f.follow = false
	var nm: String = str(f.npc.display_name)
	M.talk_spot(f, func() -> void:
		M.talk(f, str(_pick(M, ["Oh ! Un public ! Je répète pour la fête du quartier. Tu veux écouter mon morceau ?", "Chut… ah, c'est toi. Tu tombes bien : j'ai besoin d'un avis. Tu veux écouter ?", "Je l'ai composé moi-même ! Il s'appelle « Symphonie pour un chat qui éternue ». Tu veux l'entendre ?"])),
			[{"id": "oui", "label": "Oui, vas-y !"}, {"id": "non", "label": "Une autre fois…"}], func(id):
			if id != "oui":
				M.talk(f, "Tant pis. Mais tu rates quelque chose ! Enfin… les voisins disent que non, mais toi, si.", [{"id": "fermer", "label": "Bonne répétition !"}], func(_i): M.close_talk())
				return
			M.main.sfx("luth" if inst == "guitare" else "cymbale")
			f.say("♪ POUÊÊÊT ♫ SCRIIII ♪ PLONK ♫", 3.0)
			M.talk(f, "(Il joue. C'est… très fort. Un chat s'enfuit par la fenêtre. Un pot de fleurs se fêle. Quelque part, un chien hurle.) … Alors ? Alors ?",
				[{"id": "bravo", "label": "Magnifique !"}, {"id": "original", "label": "C'était… original."}, {"id": "changer", "label": "Tu devrais peut-être changer d'instrument ?"}], func(id2):
				match id2:
					"bravo":
						f.gesture("joie", 2.5)
						if not bool(M.state().get("partition", false)):
							M.state()["partition"] = true
							M.talk(f, "C'est vrai ?! Personne ne m'avait jamais dit ça ! Tiens, garde une page de ma partition. Elle vaudra une fortune quand je serai célèbre.", [{"id": "fermer", "label": "J'en prendrai soin."}], func(_i):
								M.give([["partition", 1]], "")
								M.close_talk())
						else:
							M.talk(f, "Merci ! Tu es mon plus grand fan. Mon seul fan, mais le plus grand.", [{"id": "fermer", "label": "Ha ha !"}], func(_i): M.close_talk())
					"original":
						M.talk(f, "Original ! C'est exactement ce que dit ma mère ! Elle dit aussi « tu ne veux pas plutôt faire de la peinture ? », mais je crois qu'elle plaisante.", [{"id": "fermer", "label": "Sûrement…"}], func(_i): M.close_talk())
					_:
						M.talk(f, "J'ai essayé le tambour. Les voisins ont signé une pétition. Puis la trompette : ils ont déménagé. Il en reste deux, je les aurai.", [{"id": "fermer", "label": "Bon… courage !"}], func(_i): M.close_talk())
			)))
	M.ctx["entree"] = str(_pick(M, ["Quelqu'un répète un morceau de musique. Enfin… on dirait un morceau de musique.", "♪ Pouêêêt ♪ — Tu viens d'entrer chez un musicien. Un musicien très… motivé.", "Des partitions partout, un pupitre, et un artiste qui joue les yeux fermés. Heureusement pour lui."]))


# =================================================================== mamie gâteaux

static func _b_mamie(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.cuisine(-hw + 1.7, -hd + 0.38, 0, minf(2.2, R.W * 0.35))
	R.foyer(hw - 0.8, -hd + 0.38, 0, true)
	var places: Array = _table(M, 0.3, 0.4, 2, "rouge")
	for k in range(4):
		R.kit.cyl(R.L(0.0 + k * 0.22, 0.79, 0.3), 0.09, 0.09, 0.02, "ceramique", 12)
		R.kit.cyl(R.L(0.0 + k * 0.22, 0.81, 0.3), 0.06, 0.05, 0.04, ["gateau", "chocolat", "pain", "confiture"][k], 10)
	R.etagere_murale(hw - 0.15, 1.5, 0.3, -90, 1.4, "terre_cuite", 6)
	R.tapis(0.3, 0.9, 0, 1.8, 1.2)
	R.plante(hw - 0.45, hd - 0.5)
	_murs(M, 2)
	var f: Node = M.person(str(_pick(M, ["vieille", "vieille", "vieux"])), -hw + 1.7, -hd + 1.0, 180, "cuisiner")
	f.lines = ["Ça sent bon, hein ?", "Encore une fournée !", "Qui veut goûter ?", "Le secret, c'est le beurre."]
	var it: Array = food(str(M.ctx["style"]))
	var offert: Array = [0]
	var talk_cb := func() -> void:
		if offert[0] >= 3:
			M.talk(f, "Plus rien ! Tu as tout mangé, petit gourmand. Reviens demain, j'en refais !", [{"id": "fermer", "label": "Merci pour tout !"}], func(_i): M.close_talk(), "rayonnant")
			return
		var txt: Array = ["Oh, mon petit, tu es tout maigre ! Mange donc quelque chose.", "Encore un ? Tu as bon appétit, ça fait plaisir à voir !", "Allez, un dernier pour la route. Et je t'en mets un pour demain !"]
		M.talk(f, str(txt[offert[0]]), [{"id": "oui", "label": "Avec plaisir, merci !"}, {"id": "non", "label": "Non merci, je n'ai plus faim."}], func(id):
			offert[0] += 1
			if id == "non":
				M.talk(f, str(_pick(M, ["Pas de chichis ! Tiens. Tu me remercieras plus tard.", "Plus faim ? À ton âge ? Allons donc ! Tiens."])), [{"id": "fermer", "label": "… Merci."}], func(_i):
					M.give([[str(it[r.randi() % it.size()]), 1]], "")
					M.close_talk(), "rayonnant")
				return
			M.give([[str(it[(offert[0]) % it.size()]), 1]], "")
			M.main.sfx("manger")
			M.close_talk(), "rayonnant")
	M.talk_spot(f, talk_cb)
	M.ctx["entree"] = str(_pick(M, ["Ça sent le gâteau chaud. Dans la cuisine, quelqu'un sort une plaque du four.", "Une odeur de pain d'épices et de beurre fondu. Tu as soudain très faim.", "Des gâteaux sur la table, des gâteaux sur le buffet, des gâteaux qui refroidissent sur la fenêtre."]))


# =================================================================== les travaux

static func _b_travaux(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# la moitié du mur du fond est déjà repeinte (en rose ? en vert ?)
	var c1: String = str(_pick(M, ["rose", "vert", "jaune", "turquoise", "orange"]))
	R.kit.box(R.L(-hw * 0.5, R.H * 0.5, -hd + 0.03), Vector3(hw, R.H - 0.2, 0.02), "tissu_" + c1, 2.0, 16)
	R.kit.box(R.L(-hw + 0.03, R.H * 0.5, -hd * 0.4, 90), Vector3(hd * 1.1, R.H - 0.2, 0.02), "tissu_" + c1, 2.0, 16)
	R.drape(0.3, -0.2, 0, 1.6, 1.0, 0.8)
	R.drape(hw - 0.6, 0.4, -90, 1.8, 0.8, 0.9)
	R.echelle(-hw * 0.2, -hd + 0.5, 0, 2.4)
	for k in range(5):
		var pp := Vector3(r.randf_range(-hw + 0.6, hw - 0.6), 0, r.randf_range(-hd + 0.8, hd - 1.5))
		R.kit.cyl(R.L(pp.x, 0, pp.z), 0.13, 0.13, 0.2, "metal", 12)
		R.kit.cyl(R.L(pp.x, 0.2, pp.z), 0.12, 0.12, 0.01, "tissu_" + str(_pick(M, ["rose", "vert", "jaune", "bleu"])), 12)
	for k2 in range(6):
		R.kit.box(R.L(r.randf_range(-hw + 0.5, hw - 0.5), 0.004, r.randf_range(-hd + 0.5, hd - 1.2), r.randf_range(0, 180)), Vector3(r.randf_range(0.15, 0.45), 0.004, r.randf_range(0.1, 0.3)), "tissu_" + c1, 1.0, 4)
	R.kit.box(R.L(-hw * 0.25, 0.01, 0.3), Vector3(2.2, 0.01, 1.6), "drap", 1.0, 4)
	var f: Node = M.person(str(_pick(M, ["homme", "femme", "homme"])), -hw * 0.2, -hd + 1.0, 0, "peindre")
	f.lines = ["Attention, peinture fraîche !", "Encore une couche…", "Ne touche à rien !", "Zut, j'ai peint le chat."]
	var autre: String = "vert" if c1 != "vert" else "bleu"
	M.talk_spot(f, func() -> void:
		M.talk(f, "Tu cherches quoi ? Ici, c'est le chantier du siècle. Ma moitié voulait du %s. Moi, je voulais du %s. Résultat : on fait les deux. Un mur chacun." % [c1, autre],
			[{"id": "aider", "label": "Je peux aider ?"}, {"id": "joli", "label": "C'est très joli !"}, {"id": "fermer", "label": "Bon courage !"}], func(id):
			if id == "aider":
				if bool(M.state().get("aide", false)):
					M.talk(f, "Tu as déjà fait ta part ! Et tu as encore de la peinture dans les cheveux.", [{"id": "fermer", "label": "Ha ha, oui."}], func(_i): M.close_talk())
					return
				M.state()["aide"] = true
				M.talk(f, "Tiens, tiens le pot. … (Tu tiens le pot. Il en met partout. Surtout sur toi.) … Parfait ! Tiens, pour le coup de main.", [{"id": "fermer", "label": "(Essuyer la peinture sur ton nez)"}], func(_i):
					M.give([["piece", 10 + r.randi() % 10]], "")
					M.close_talk())
			elif id == "joli":
				M.talk(f, "Merci ! Ne le dis pas trop fort : sinon on va devoir repeindre la cuisine aussi.", [{"id": "fermer", "label": "Promis."}], func(_i): M.close_talk())
			else:
				M.close_talk()
		))
	M.ctx["entree"] = str(_pick(M, ["Ça sent la peinture fraîche. Des bâches partout, une échelle, des pots… Une maison en plein chantier.", "Attention où tu marches : des pots de peinture traînent partout. Quelqu'un repeint la maison… en deux couleurs.", "Une maison en travaux. Un mur est fini. L'autre aussi, mais d'une autre couleur."]))


# =================================================================== le sportif

static func _b_sportif(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.tapis(0.0, 0.0, 0, 2.4, 1.6)
	for k in range(4):
		var x: float = hw - 0.6
		var z: float = -hd + 0.8 + k * 0.5
		R.kit.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5), R.P(x + 0.25, 0.1, z)), 0.1, 0.1, 0.06, "fer", 12)
		R.kit.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5), R.P(x - 0.25, 0.1, z)), 0.1, 0.1, 0.06, "fer", 12)
		R.kit.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5), R.P(x + 0.25, 0.1, z)), 0.02, 0.02, 0.5, "metal", 6)
	R.banc(-hw + 0.8, 0.0, 90, 1.4)
	R.kit.box(R.L(-hw + 0.3, 1.6, -hd * 0.3, 90), Vector3(1.2, 0.9, 0.02), "verre", 1.0)
	R.armoire(-hw + 0.35, hd * 0.35, 90, 0.9)
	_murs(M, 2)
	var f: Node = M.person(str(_pick(M, ["homme", "femme", "homme"])), 0.2, -0.2, 90, "debout")
	var pf: Vector3 = R.P(-0.6, 0.0, 0.1)
	f.plank(pf, Vector3(1, 0, 0))
	f.follow = false
	f.lines = ["… 97… 98… 99…", "Encore une série !", "Hop ! Hop ! Hop !", "Respire… souffle…", "100 ! … On recommence."]
	f.line_every = Vector2(3.0, 5.0)
	M.talk_spot(f, func() -> void:
		f.stand_up(R.P(0.4, 0, 0.1), Vector3(0, 0, 1))
		M.talk(f, str(_pick(M, ["Salut ! Toi aussi tu veux des bras comme ça ? Allez, dix pompes avec moi !", "Ah, un sportif ! Ça se voit tout de suite. Une petite série de pompes ?", "Le secret de la forme ? Cent pompes le matin, cent le soir, et une tarte le midi. Tu t'y mets ?"])),
			[{"id": "oui", "label": "D'accord !"}, {"id": "non", "label": "Une autre fois…"}], func(id):
			if id == "oui":
				M.close_talk()
				var dj: Node = M.main.get("donjon_v35")
				if dj != null:
					await dj._fade_to(1.0, 0.4)
					await M.get_tree().create_timer(0.8).timeout
					await dj._fade_to(0.0, 0.4)
				if not M.inside:
					return
				var first: bool = not bool(M.state().get("pompes", false))
				M.state()["pompes"] = true
				M.talk(f, str(_pick(M, ["Pas mal ! Trois pompes ! Bon, deux et demie. C'est un début !", "Bravo ! Tu as tenu… presque une minute ! La prochaine fois, on attaque les abdos."])) + (" Tiens, une boisson pour récupérer." if first else ""),
					[{"id": "fermer", "label": "(Reprendre ton souffle)"}], func(_i):
					if first:
						M.give([[str(_pick(M, ["jus_pomme", "sirop_menthe", "the_menthe"])), 1]], "")
					M.close_talk()
					f.plank(pf, Vector3(1, 0, 0)))
			else:
				M.talk(f, "Pas de souci ! La porte est toujours ouverte. Comme mes muscles. Euh… enfin, tu m'as compris.", [{"id": "fermer", "label": "Ha ha, oui."}], func(_i):
					M.close_talk()
					f.plank(pf, Vector3(1, 0, 0)))
		, "à fond"))
	M.ctx["entree"] = str(_pick(M, ["« … 98… 99… 100 ! » Quelqu'un fait des pompes au milieu du salon.", "Des haltères partout, un tapis, et quelqu'un qui souffle comme une locomotive.", "Une salle de sport. Enfin, un salon transformé en salle de sport."]))


# =================================================================== le collectionneur

const COLLECTIONS := [
	["chaussettes", "des chaussettes dépareillées", "Pas une seule paire ! Rien que des chaussettes seules. Elles ont toutes une histoire. Celle-là a fait le tour de l'archipel dans une botte de pêcheur."],
	["cuilleres", "des petites cuillères", "Mille deux cent douze petites cuillères. Celle-là a servi à goûter la soupe du roi. Celle-ci, à remuer le thé d'un dragon. Enfin, c'est ce qu'on m'a dit."],
	["cailloux", "des cailloux", "Rien que des cailloux. Ronds, plats, gris, un peu moins gris… Celui-là ressemble à ma tante. Celui-là aussi, d'ailleurs."],
	["tasses", "des tasses", "Des tasses de tous les pays ! Il ne m'en manque qu'une : la tasse parfaite. Je la cherche depuis quarante ans."],
	["horloges", "des horloges arrêtées", "Elles se sont toutes arrêtées à une heure différente. Comme ça, il y en a toujours une qui a raison. Deux fois par jour."],
	["boutons", "des boutons", "Des boutons ! Boutons de chemise, de manteau, de culotte… Un jour, je me coudrai un manteau rien qu'avec eux."],
]

static func _b_collection(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var col: Array = COLLECTIONS[hash(str(M.ctx["id"])) % COLLECTIONS.size()]
	var key: String = str(col[0])
	var keys: Dictionary = {"chaussettes": ["tissu_rouge", "tissu_bleu", "tissu_jaune", "tissu_vert", "tissu_rose", "tissu_violet"], "cuilleres": ["argent"], "cailloux": ["pierre_lisse", "noir", "terre_cuite"],
		"tasses": ["ceramique", "tissu_bleu", "tissu_rouge", "terre_cuite"], "horloges": ["or", "bois_sombre", "cuivre"], "boutons": ["tissu_rouge", "tissu_noir", "or", "bois_clair", "tissu_bleu"]}
	var ks: Array = keys[key]
	var n: int = maxi(2, int((R.W - 1.0) / 1.3))
	for i in range(n):
		var x: float = -hw + 0.75 + i * ((R.W - 1.5) / maxf(1.0, n - 1))
		R.etagere(x, -hd + 0.22, 0, 1.2, minf(2.1, R.H - 0.4), false, 5)
		for row in range(5):
			for k in range(6):
				var px: float = x - 0.48 + k * 0.19
				var py: float = 0.1 + row * ((minf(2.1, R.H - 0.4) - 0.12) / 5.0)
				var m: String = str(ks[(i + row + k) % ks.size()])
				match key:
					"chaussettes":
						R.kit.box(R.L(px, py + 0.1, -hd + 0.22, r.randf_range(-10, 10)), Vector3(0.07, 0.2, 0.03), m, 1.0)
						R.kit.box(R.L(px + 0.03, py + 0.02, -hd + 0.22), Vector3(0.11, 0.05, 0.035), m, 1.0)
					"cuilleres":
						R.kit.box(R.L(px, py + 0.01, -hd + 0.22, r.randf_range(-20, 20)), Vector3(0.025, 0.012, 0.14), m, 1.0)
						R.kit.cyl(R.L(px, py + 0.012, -hd + 0.15), 0.025, 0.02, 0.01, m, 8)
					"cailloux":
						R.kit.cyl(R.L(px, py, -hd + 0.22, r.randf_range(0, 90)), r.randf_range(0.04, 0.07), r.randf_range(0.03, 0.05), r.randf_range(0.04, 0.07), m, 7)
					"tasses":
						R.kit.cyl(R.L(px, py, -hd + 0.22), 0.045, 0.05, 0.08, m, 10)
					"horloges":
						R.kit.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), R.P(px, py + 0.08, -hd + 0.2)), 0.07, 0.07, 0.03, m, 12)
					_:
						R.kit.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), R.P(px, py + 0.05, -hd + 0.2)), 0.04, 0.04, 0.015, m, 10)
	R.tapis(0.0, 0.3, 0, 2.4, 1.6)
	R.fauteuil(hw - 0.9, 0.5, -110, "brun")
	_murs(M, 2)
	var f: Node = M.person(str(_pick(M, ["vieux", "homme", "vieille", "femme"])), -0.3, 0.0, 180, "mains_dos")
	f.lines = ["Ne touche pas, regarde avec les yeux.", "Celle-là est rarissime.", "Il m'en manque une…", "Magnifique, n'est-ce pas ?"]
	M.talk_spot(f, func() -> void:
		var choices: Array = [{"id": "quoi", "label": "Qu'est-ce que vous collectionnez ?"}]
		var inv: Node = M.main.get("inventory_v28")
		if inv != null and int(inv.count("vieille_botte")) > 0:
			choices.append({"id": "botte", "label": "J'ai une vieille botte, ça vous intéresse ?"})
		choices.append({"id": "fermer", "label": "Au revoir !"})
		M.talk(f, "Bienvenue au musée ! Enfin… chez moi. Mais c'est un musée. Tu as vu ma collection ?", choices, func(id):
			match id:
				"quoi":
					M.talk(f, "Je collectionne %s ! %s" % [str(col[1]), str(col[2])] + " … Ah, et si un jour tu pêches une vieille botte, apporte-la-moi : j'en achète.",
						[{"id": "fermer", "label": "Passionnant !"}], func(_i): M.close_talk(), "passionné")
				"botte":
					M.main.inventory_v28.remove("vieille_botte", 1)
					M.main.sfx("ramasse_pieces")
					M.talk(f, "Une VRAIE vieille botte ?! Avec le trou au bout ?! Merveilleux ! Je la mets à côté de mes autres trésors. Tiens, c'est bien payé !", [{"id": "fermer", "label": "Marché conclu !"}], func(_i):
						M.give([["piece", 25 + r.randi() % 15]], "")
						M.close_talk(), "aux anges")
				_:
					M.close_talk()
		))
	M.ctx["entree"] = "Des étagères du sol au plafond, remplies… %s. Rien que %s." % [str(col[1]), str(col[1])]


# =================================================================== la maison à l'envers

static func _b_envers(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var ceil: Node3D = R.movable(func():
		R.table(-0.2, 0.1, 0, 1.3, 0.8)
		R.chaise(-0.5, 0.8, 180)
		R.chaise(0.1, -0.6, 0)
		R.armoire(-hw + 0.35, -hd * 0.25, 90)
		R.lit(hw - 0.7, -hd * 0.1, -90, 1.0, "rouge")
		R.tapis(0.0, 0.2, 0, 2.2, 1.6)
		R.plante(hw - 0.5, hd - 0.6)
		R.coffre_deco(0.5, -hd + 0.5, 0))
	var pivot: Vector3 = R.P(0, R.H * 0.5, 0)
	ceil.global_transform = Transform3D(Basis(Vector3(0, 0, 1), PI), pivot) * Transform3D(Basis(), -pivot)
	_murs(M, 2)
	R.tapis(0.0, 0.2, 0, 2.2, 1.6)
	var f: Node = M.person(str(_pick(M, ["homme", "vieux", "femme", "vieille"])), 0.3, 0.6, 180, "lire")
	f.lines = ["Tout est normal.", "Tu as la tête à l'envers, toi.", "Attention à ne pas tomber… vers le haut."]
	M.talk_spot(f, func() -> void:
		M.talk(f, str(_pick(M, ["Quoi ? Ah, les meubles ? C'est le reste du monde qui est à l'envers. Moi, je suis très bien comme ça.", "Bonjour ! Excuse le désordre. Enfin, l'ordre. Enfin… tout est au plafond, quoi.", "Tu trouves que c'est bizarre ? Moi je trouve bizarre que vous mettiez tous vos meubles par terre. C'est là qu'on marche !"])),
			[{"id": "comment", "label": "Mais… comment ça tient ?"}, {"id": "dormir", "label": "Et pour dormir ?"}, {"id": "fermer", "label": "(Repartir, la tête qui tourne)"}], func(id):
			match id:
				"comment":
					M.talk(f, "Avec beaucoup de clous. Et de la bonne volonté. Surtout des clous.", [{"id": "fermer", "label": "Évidemment."}], func(_i): M.close_talk())
				"dormir":
					M.talk(f, "Je dors comme une chauve-souris, la tête en bas. Les rêves sont bien meilleurs : ils tombent tout seuls dans la tête.", [{"id": "fermer", "label": "Logique…"}], func(_i): M.close_talk())
				_:
					M.close_talk()
		), "tout à fait normal")
	M.ctx["entree"] = str(_pick(M, ["Euh… La table, les chaises, le lit, l'armoire… tout est au PLAFOND.", "Tu lèves les yeux. Une table te regarde, les pieds en l'air. Tout le mobilier est accroché au plafond !", "Une maison à l'envers. Littéralement."]))


# =================================================================== la dispute

const DISPUTES := [
	["le dernier biscuit", "C'est TOI qui as mangé le dernier biscuit !", "Pas du tout ! C'est le chat !", "Le pain, on le range dans le tiroir ou dans la boîte à pain ?", "Dans le tiroir !", "Dans la boîte !"],
	["les chaussettes", "On met les chaussettes AVANT le pantalon !", "Non, APRÈS ! Tout le monde sait ça !", "Les chaussettes : avant ou après le pantalon ?", "Avant !", "Après !"],
	["la confiture", "La confiture, c'est avec des morceaux !", "Sans morceaux ! Des morceaux, c'est de la compote !", "La confiture : avec ou sans morceaux ?", "Avec !", "Sans !"],
	["le nom du chat", "Il s'appelle Pompon !", "Il s'appelle Moustache ! Regarde ses moustaches !", "Le chat : Pompon ou Moustache ?", "Pompon !", "Moustache !"],
	["le rideau", "Le rideau bleu, c'est plus joli !", "Le jaune ! Le bleu, on dirait la mer un jour de pluie !", "Le rideau : bleu ou jaune ?", "Bleu !", "Jaune !"],
	["les étoiles", "On les compte, les étoiles !", "Non, on les REGARDE ! Si tu les comptes, tu les perds !", "Les étoiles : on les compte ou on les regarde ?", "On les compte !", "On les regarde !"],
]

static func _b_dispute(M) -> void:
	var R = M.R
	var r := _r(M)
	var places: Array = _salon(M, 2)
	var d: Array = DISPUTES[hash(str(M.ctx["id"])) % DISPUTES.size()]
	var a: Node = M.person(str(_pick(M, ["homme", "vieux"])), -0.9, 0.9, 90, "colere")
	var b: Node = M.person(str(_pick(M, ["femme", "vieille"])), 0.5, 0.9, -90, "colere")
	a.lines = [str(d[1]), "Je te dis que si !", "Absolument !"]
	b.lines = [str(d[2]), "Certainement pas !", "N'importe quoi !"]
	a.line_every = Vector2(4.0, 6.0)
	b.line_every = Vector2(4.5, 6.5)
	var fini: bool = bool(M.state().get("dispute", false))
	if fini:
		a.set_pose("rire", Vector3.ZERO)
		b.set_pose("rire", Vector3.ZERO)
		a.lines = ["Tu te souviens de notre dispute ?", "Ha ha ha !"]
		b.lines = ["On était bêtes !", "Hi hi hi !"]
	var cb := func() -> void:
		if bool(M.state().get("dispute", false)):
			M.talk(a, "Ah, notre arbitre ! Depuis ta visite, on ne se dispute plus. Enfin, presque plus. Hier, c'était à propos des cuillères.", [{"id": "fermer", "label": "Ha ha ! Bonne journée !"}], func(_i): M.close_talk())
			return
		M.talk(a, "Toi ! Tu tombes bien ! Dis-lui, toi : " + str(d[3]), [{"id": "a", "label": str(d[4])}, {"id": "b", "label": str(d[5])}, {"id": "c", "label": "Les deux se valent !"}], func(id):
			M.state()["dispute"] = true
			var t: String
			match id:
				"a":
					t = "HA ! Tu vois ! … Bon. D'accord. C'est un peu bête de se disputer pour %s." % str(d[0])
				"b":
					t = "Quoi ?! … Bon. Bon, bon, bon. Tu as peut-être raison. Ou pas. Enfin… on s'en fiche, de %s, non ?" % str(d[0])
				_:
					t = "Les deux ? … Les deux. Mais oui ! Pourquoi on n'y a pas pensé ?"
			M.talk(b, t, [{"id": "fermer", "label": "Voilà qui est réglé !"}], func(_i):
				a.set_pose("rire", Vector3.ZERO)
				b.set_pose("rire", Vector3.ZERO)
				a.lines = ["Ha ha ha !", "On est bêtes, hein ?"]
				b.lines = ["Hi hi hi !", "Allez, viens, on fait la paix."]
				M.give([["piece", 6 + r.randi() % 6]], "Ils éclatent de rire tous les deux. « Merci, arbitre ! Tiens, pour ta peine. » ")
				M.close_talk())
		)
	M.talk_spot(a, cb)
	M.talk_spot(b, cb)
	M.ctx["entree"] = "Deux personnes se disputent au milieu du salon. Le sujet : " + str(d[0]) + "." if not fini else "Ils rient encore de leur dispute de la dernière fois."


# =================================================================== le mime

static func _b_mime(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.tapis(0.0, 0.0, 0, 2.4, 1.8)
	R.armoire(-hw + 0.35, -hd * 0.3, 90)
	R.kit.box(R.L(hw - 0.4, 0.9, -hd * 0.2, -90), Vector3(1.2, 1.8, 0.04), "verre", 1.0)
	R.kit.box(R.L(hw - 0.4, 0.9, -hd * 0.2 - 0.04, -90), Vector3(1.3, 1.9, 0.02), "bois_sombre", 1.0)
	R.kit.box(R.L(0.0, R.H - 0.2, -hd + 0.03), Vector3(2.4, 0.3, 0.02), "tissu_rouge", 1.0, 16)
	_murs(M, 2)
	var f: Node = M.person(str(_pick(M, ["homme", "femme"])), 0.0, -0.4, 180, "mime")
	f.lines = ["…", "(…)", "(Il te fait coucou. Sans un mot.)"]
	f.line_every = Vector2(8.0, 14.0)
	M.talk_spot(f, func() -> void:
		M.talk(f, "(Un mime. Il fait semblant d'être coincé dans une boîte invisible. Il tape sur les murs invisibles. Il a l'air très inquiet.)",
			[{"id": "aider", "label": "L'aider à sortir de la boîte"}, {"id": "bravo", "label": "Applaudir"}, {"id": "parler", "label": "Bonjour ! Ça va ?"}], func(id):
			match id:
				"aider":
					M.talk(f, "(Tu ouvres une porte invisible. Il sort, soulagé, te serre la main… et se cogne aussitôt dans un mur invisible.)", [{"id": "fermer", "label": "(Rire)"}], func(_i): M.close_talk())
				"bravo":
					f.gesture("salut", 2.0)
					if not bool(M.state().get("mime", false)):
						M.state()["mime"] = true
						M.talk(f, "(Il salue bien bas. Il te tend un chapeau invisible. Tu y mets une pièce invisible. Il a l'air ravi… et il te donne une vraie pièce en échange !)", [{"id": "fermer", "label": "Merci !"}], func(_i):
							M.give([["piece", 5]], "")
							M.close_talk())
					else:
						M.talk(f, "(Il salue encore. Il est très content d'avoir un public.)", [{"id": "fermer", "label": "(Applaudir encore)"}], func(_i): M.close_talk())
				_:
					M.talk(f, "(Il met un doigt devant sa bouche : chut. Puis il fait semblant de te tendre une tasse de thé. Invisible. Il attend que tu boives.)", [{"id": "fermer", "label": "(Boire le thé invisible)"}], func(_i): M.close_talk())
		))
	M.ctx["entree"] = "Le silence. Au milieu de la pièce, quelqu'un au visage très pâle fait de grands gestes… sans un bruit."


# =================================================================== les coucous

static func _b_coucou(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var grande: Vector3 = R.horloge(-hw + 0.5, -hd * 0.3, 90)
	R.horloge(hw - 0.5, -hd * 0.3, -90)
	var murs: Array = []
	for k in range(7):
		var x: float = -hw + 0.8 + k * ((R.W - 1.6) / 6.0)
		var y: float = 1.4 + (k % 3) * 0.35
		var c: Vector3 = R.P(x, y, -hd + 0.06)
		R.kit.box(Transform3D(Basis(), c), Vector3(0.36, 0.42, 0.12), "bois", 1.0)
		R.kit.box(Transform3D(Basis(), c + Vector3(0, 0.27, 0)), Vector3(0.44, 0.08, 0.16), "bois_sombre", 1.0)
		R.kit.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), c + Vector3(0, -0.05, 0.06)), 0.12, 0.12, 0.01, "ceramique", 14)
		R.kit.box(Transform3D(Basis(), c + Vector3(0, -0.45, 0.02)), Vector3(0.01, 0.5, 0.01), "or", 1.0)
		murs.append(c + Vector3(0, 0.12, 0.1))
	R.fauteuil(0.6, 0.3, 180, "vert")
	R.tapis(0.3, 0.3, 0, 2.0, 1.4)
	var dort: bool = r.randf() < 0.5
	var f: Node = null
	if dort:
		f = M.person(str(_pick(M, ["vieux", "vieille"])), 0.6, 0.3, 180, "dormir_assis")
		f.follow = false
		f.lines = ["Zzz…", "Tic… tac… zzz…"]
	M.act(grande, "E : regarder derrière le balancier", func() -> void:
		if bool(M.state().get("cle", false)):
			M.say("Derrière le balancier, il n'y a plus rien. Juste le tic-tac.", 3.0)
			return
		M.state()["cle"] = true
		M.main.sfx("clochette", grande)
		M.give([["petite_cle", 1]], "Derrière le balancier de la grande horloge, accrochée à un clou : une petite clé ! ")
		if f != null:
			f.say("Hein ? Quelle heure est-il ? … Zzz…", 3.0)
	, 1.2)
	M.ctx["on_enter"] = func(first: bool) -> void:
		if first:
			M.say(str(_pick(M, ["Tic. Tac. Tic. Tac. Des horloges partout… et aucune n'indique la même heure.", "Le tic-tac de vingt horloges remplit la pièce. On dirait une pluie très régulière.", "Des coucous, des pendules, des horloges comtoises… Ici, le temps ne manque pas."])), 6.0)
		var k: int = 0
		while M.inside and k < 20:
			await M.get_tree().create_timer(9.0 + r.randf() * 6.0).timeout
			if not M.inside:
				return
			var p: Vector3 = murs[r.randi() % murs.size()]
			M.main.sfx("clochette", p)
			var lab := Label3D.new()
			lab.text = "Coucou !"
			lab.font_size = 42
			lab.pixel_size = 0.004
			lab.outline_size = 10
			lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			lab.no_depth_test = true
			M.room.add_child(lab)
			lab.global_position = p + Vector3(0, 0.3, 0.2)
			var tw: Tween = M.room.create_tween()
			tw.tween_property(lab, "global_position", p + Vector3(0, 0.6, 0.3), 1.5)
			tw.tween_callback(lab.queue_free)
			k += 1


# =================================================================== personne

const MOTS := [
	"Un mot sur la table : « Liste de courses : du pain, des œufs, un dragon (petit), du fromage. Ne pas oublier le fromage. »",
	"Un mot sur la table : « Partis à la plage. Si c'est toi, Gérard : le chat a DÉJÀ mangé. Ne l'écoute pas. »",
	"Un mot sur la table : « Ne pas toucher au gâteau. Signé : Maman. » Dessous, d'une autre écriture : « Quel gâteau ? »",
	"Un mot sur la table : « Le plombier passera mardi. Ou mercredi. Ou jamais. Mettre une bassine sous la fuite. »",
	"Un mot sur la table : « Cher voleur, il n'y a rien à voler ici, sauf la vaisselle sale. Sers-toi. »",
	"Un mot sur la table : « Si tu lis ce mot, tu es chez moi. Tant qu'à faire, arrose les plantes. Merci ! »",
	"Un mot sur la table : « Recette de la soupe de Mémé : de l'eau, des légumes, et beaucoup de patience. Surtout de la patience. »",
	"Un mot sur la table : « RAPPEL : demain, c'est l'anniversaire de Tonton. Acheter un cadeau. PAS des chaussettes. »",
]

static func _b_vide(M) -> void:
	var R = M.R
	var r := _r(M)
	var places: Array = _salon(M, 3)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	if R.is_free(hw - 0.7, hd * 0.25, 1.0, 2.2):
		R.lit(hw - 0.7, hd * 0.25 - 0.9, -90, 1.0, str(_pick(M, ["bleu", "vert", "rouge", "jaune"])))
	_mot(M, 0.1, 0.3, 0.79, str(MOTS[hash(str(M.ctx["id"])) % MOTS.size()]))
	var extra: int = r.randi() % 4
	match extra:
		0:
			# un bocal de bonbons « servez-vous (un seul !) »
			R.kit.cyl(R.L(-0.6, 0.79, 0.0), 0.11, 0.11, 0.22, "verre", 14)
			for k in range(8):
				R.kit.cyl(R.L(-0.6 + r.randf_range(-0.06, 0.06), 0.8 + k * 0.025, r.randf_range(-0.06, 0.06)), 0.02, 0.02, 0.02, ["pomme", "fromage", "tissu_vert", "tissu_bleu"][k % 4], 6)
			M.act(R.P(-0.6, 0, 0.0), "E : prendre un bonbon (UN seul !)", func() -> void:
				M.state()["bonbon"] = true
				M.give([["baies", 1]], "Une étiquette sur le bocal : « Servez-vous (UN seul !) ». Tu en prends un. Un seul. Promis. "), 1.2, func(): return not bool(M.state().get("bonbon", false)))
		1:
			R.chat(0.9, 0.9, r.randf_range(0, 360), [Color(0.95, 0.6, 0.25), Color(0.15, 0.15, 0.17), Color(0.92, 0.92, 0.9)][r.randi() % 3], true)
			M.act(R.P(0.9, 0, 0.9), "E : caresser le chat", func() -> void:
				M.main.sfx("ronron")
				M.say(str(_pick(M, ["Le chat ronronne. Puis il te mord gentiment, pour la forme. Puis il ronronne encore.", "Le chat ouvre un œil, te juge, et se rendort. Tu es accepté.", "Ronron. Le chat se roule sur le dos. C'est un piège, tout le monde le sait."])), 4.0), 1.0)
		2:
			# un poisson rouge dans son bocal
			R.kit.cyl(R.L(R.W * 0.18 - 0.6, 1.32, -hd + 0.4), 0.14, 0.12, 0.22, "verre", 14)
			var fish := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.035
			sm.height = 0.05
			fish.mesh = sm
			var fm := StandardMaterial3D.new()
			fm.albedo_color = Color(1.0, 0.45, 0.1)
			fm.emission_enabled = true
			fm.emission = Color(0.4, 0.15, 0.02)
			fish.material_override = fm
			M.room.add_child(fish)
			fish.global_position = R.P(R.W * 0.18 - 0.6, 1.43, -hd + 0.4)
			var tw: Tween = M.room.create_tween().set_loops()
			tw.tween_property(fish, "global_position:x", fish.global_position.x + 0.07, 1.6).set_trans(Tween.TRANS_SINE)
			tw.tween_property(fish, "global_position:x", fish.global_position.x - 0.07, 1.6).set_trans(Tween.TRANS_SINE)
			M.act(R.P(R.W * 0.18 - 0.6, 0, -hd + 1.0), "E : regarder le poisson rouge", func(): M.say(str(_pick(M, ["Le poisson rouge fait des tours. Il a l'air de réfléchir. À quoi ? Mystère.", "Le poisson rouge te regarde. Glouglou. Tu as l'impression qu'il te juge.", "Sur le bocal, une étiquette : « Fernand. Ne pas nourrir (il ment). »"])), 4.0), 1.0)
		_:
			M.act(R.P(-R.W * 0.5 + 1.0, 0, -hd * 0.25), "E : ouvrir l'armoire", func() -> void:
				if bool(M.state().get("armoire", false)):
					M.say("Des vêtements bien pliés. Rien d'autre.", 3.0)
					return
				M.state()["armoire"] = true
				M.main.sfx("touche_bois")
				M.give([["piece", 2 + r.randi() % 4]], str(_pick(M, ["Dans la poche d'un vieux manteau : ", "Au fond de l'armoire, dans une chaussette : ", "Sous une pile de draps : "])) + "quelques pièces oubliées… "), 1.2)
	M.ctx["entree"] = str(_pick(M, ["Il n'y a personne. Une maison bien rangée, qui sent la cire et le pain.", "Personne à la maison. Une horloge fait tic-tac. Tu chuchotes sans savoir pourquoi.", "La maison est vide, mais il fait bon : quelqu'un vient de partir, le feu brûle encore.", "Personne. Juste le craquement du parquet et le silence d'une maison tranquille."]))


# =================================================================== chez un habitant connu

static func _b_chez(M) -> void:
	var R = M.R
	var r := _r(M)
	var owner: Node = M.ctx["owner_node"]
	var prof: Dictionary = owner.get("profile")
	var nom: String = str(owner.get("display_name"))
	var titre: String = str(prof.get("titre", ""))
	var places: Array = _salon(M, 2)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	if R.is_free(hw - 0.7, hd * 0.25, 1.0, 2.2):
		R.lit(hw - 0.7, hd * 0.25 - 0.9, -90, 1.0, str(_pick(M, ["bleu", "vert", "rouge", "jaune"])))
	# son portrait au mur, au-dessus du foyer
	var pid: String = str(prof.get("id", ""))
	var tex_path: String = "res://assets/textures/portraits/%s.png" % pid
	if ResourceLoader.exists(tex_path):
		var pm := StandardMaterial3D.new()
		pm.albedo_texture = load(tex_path)
		pm.roughness = 0.7
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.55, 0.55)
		q.mesh = qm
		q.material_override = pm
		M.room.add_child(q)
		q.global_position = R.P(R.W * 0.18, minf(2.05, R.H - 0.45), -hd + 0.04)
		R.kit.box(R.L(R.W * 0.18, minf(2.05, R.H - 0.45), -hd + 0.025), Vector3(0.66, 0.66, 0.02), "or", 1.0, 16)
	var home: bool = bool(owner.get("hidden_home"))
	if home:
		var p: Dictionary = prof.duplicate(true)
		var cls: String = "lumen"
		var scr: String = str((owner.get_script() as Script).resource_path)
		if scr.contains("pirate"):
			cls = "pirate"
		elif scr.contains("ramure"):
			cls = "ramure"
		p["classe"] = cls
		var place: Array = places[0]
		var Fig = load("res://scripts/pnj/figurant_v81.gd")
		var f: Node = Fig.spawn(M.room, M.main, p, R.P(float(place[0]), 0, float(place[1])), Basis(Vector3.UP, deg_to_rad(float(place[2]))) * Vector3(0, 0, 1), "assis")
		M.people.append(f)
		var acc: Array = (prof.get("repliques", {}) as Dictionary).get("lui", [])
		M.talk_spot(f, func() -> void:
			var t: String = str(_pick(M, ["Oh ! Tu es venu me voir chez moi ? Quelle bonne surprise ! Fais comme chez toi.", "Ah, c'est toi ! Entre, entre. Excuse le désordre, je ne m'attendais pas à de la visite.", "Bienvenue chez moi ! C'est petit, mais c'est chaud et ça sent bon."]))
			var choices: Array = [{"id": "maison", "label": "Elle est jolie, ta maison !"}]
			if not acc.is_empty():
				choices.append({"id": "lui", "label": "Parle-moi un peu de toi."})
			choices.append({"id": "fermer", "label": "Je ne fais que passer. À bientôt !"})
			M.talk(f, t, choices, func(id):
				match id:
					"maison":
						if not bool(M.state().get("cadeau_chez", false)):
							M.state()["cadeau_chez"] = true
							var it: Array = food(str(M.ctx["style"]))
							M.talk(f, "Merci ! Tiens, prends donc ça pour la route. On ne repart pas de chez moi le ventre vide !", [{"id": "fermer", "label": "Merci beaucoup !"}], func(_i):
								M.give([[str(it[r.randi() % it.size()]), 1]], "")
								M.close_talk())
						else:
							M.talk(f, "Merci ! Reviens quand tu veux, la porte est toujours ouverte.", [{"id": "fermer", "label": "À bientôt !"}], func(_i): M.close_talk())
					"lui":
						var l: Variant = acc[r.randi() % acc.size()]
						M.talk(f, str((l as Dictionary).get("t", "")) if l is Dictionary else str(l), [{"id": "fermer", "label": "Merci de m'avoir raconté."}], func(_i): M.close_talk())
					_:
						M.close_talk()
			))
		M.ctx["entree"] = "Tu es chez %s%s." % [nom, (", " + titre) if titre != "" else ""]
	else:
		_mot(M, 0.1, 0.3, 0.79, str(_pick(M, ["Un mot de %s : « Parti travailler. Retour ce soir. Si c'est toi, maman : il y a de la soupe. »" % nom, "Un mot sur la table : « Partie faire un tour. — %s »" % nom, "Une liste, de la main de %s : « Aujourd'hui : travailler, saluer les voisins, ranger la maison (demain). »" % nom])))
		M.ctx["entree"] = "C'est la maison de %s%s. Il n'y a personne : on doit être dehors, en train de travailler." % [nom, (", " + titre) if titre != "" else ""]
