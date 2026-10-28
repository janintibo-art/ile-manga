extends RefCounted
## V82 : les histoires propres à chaque île, dans les maisons qu'on visite (maisons_v81.gd).
## Chaque ville a la sienne (le chevalier de Montjoie, le petit démon peureux de Pandémonia, la
## répétition punk de Port-Boucan, le thé à Tazira, la pièce en apesanteur d'Astralys, le
## robot-majordome de Cliquetis, le tanuki-théière de Ramure, la potion ratée d'Arcanelle, le
## perroquet bavard de Port-Coutelas, la bouteille de Carène, le chat sacré de Per-Hâpy, le
## chocolat de Yaxché, les plumes d'Aztlán, le peintre de Port-Azur, la chanteuse elfe, la
## maison-aquarium des Atlantes) ; les fées ont leur maison à elles.
## M : maisons_v81 ; S : maisons_scenes_v81 (les aides communes).

const S = preload("res://scripts/maisons_scenes_v81.gd")

## [id, poids, {style: [styles où elle peut arriver]}]
const SCENARIOS := [
	["chevalier", 16, {"style": ["montjoie"]}], ["demon_peureux", 16, {"style": ["braise"]}],
	["repetition", 16, {"style": ["boucan", "boucan_entrepot"]}], ["the", 16, {"style": ["tazira"]}],
	["apesanteur", 18, {"style": ["astralys"]}], ["robot", 18, {"style": ["cliquetis"]}],
	["tanuki", 18, {"style": ["ramure"]}], ["potion", 18, {"style": ["arcanelle"]}],
	["perroquet", 18, {"style": ["pirate"]}], ["bouteille", 18, {"style": ["carene"]}],
	["chat_sacre", 18, {"style": ["egypte"]}], ["chocolat", 18, {"style": ["maya"]}],
	["plumes", 18, {"style": ["azteque"]}], ["peintre", 14, {"style": ["azur"]}],
	["chant_elfe", 22, {"style": ["elfe"]}], ["aquarium", 22, {"style": ["atlante"]}],
]


static func has(sc: String) -> bool:
	for e in SCENARIOS:
		if str(e[0]) == sc:
			return true
	return sc == "fee"


static func allowed(sc: Array, style: String) -> bool:
	var st: Array = (sc[2] as Dictionary).get("style", [])
	return st.is_empty() or style in st


static func build(M, sc: String) -> void:
	match sc:
		"chevalier":
			_chevalier(M)
		"demon_peureux":
			_demon(M)
		"repetition":
			_repetition(M)
		"the":
			_the(M)
		"apesanteur":
			_apesanteur(M)
		"robot":
			_robot(M)
		"tanuki":
			_tanuki(M)
		"potion":
			_potion(M)
		"perroquet":
			_perroquet(M)
		"bouteille":
			_bouteille(M)
		"chat_sacre":
			_chat_sacre(M)
		"chocolat":
			_chocolat(M)
		"plumes":
			_plumes(M)
		"peintre":
			_peintre(M)
		"chant_elfe":
			_chant_elfe(M)
		"aquarium":
			_aquarium(M)
		"fee":
			_fee(M)


# =================================================================== aides

static func _r(M) -> RandomNumberGenerator:
	return M.ctx["rng"]


static func _pick(M, a: Array) -> Variant:
	return a[_r(M).randi() % a.size()]


## Un objet simple fait de maillages (pour ce qui doit bouger : robot, théière, grenouille…).
static func _part(parent: Node3D, mesh: Mesh, c: Color, pos: Vector3, scl: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO, emit: float = 0.0, metal: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.5 if metal > 0.0 else 0.8
	m.metallic = metal
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	mi.material_override = m
	mi.position = pos
	mi.scale = scl
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func _sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 16
	s.rings = 8
	return s


static func _cyl(top: float, bot: float, h: float, seg: int = 16) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bot
	c.height = h
	c.radial_segments = seg
	return c


static func _boxm(sz: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = sz
	return b


## Met un nœud « mobile » (géométrie en coordonnées du monde) à l'échelle s autour de son pied.
static func _grow(n: Node3D, s: Vector3) -> void:
	var b: Vector3 = n.get_meta("base", Vector3.ZERO)
	n.scale = s
	n.position = b - b * s


static func _node(M, at: Vector3, yaw: float = 0.0) -> Node3D:
	var n := Node3D.new()
	M.room.add_child(n)
	n.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), at)
	return n


static func _close(M) -> Callable:
	return func(_i): M.close_talk()


static func _bye(label: String) -> Array:
	return [{"id": "fermer", "label": label}]


# =================================================================== Montjoie : le chevalier et son armure

static func _chevalier(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	S._salon(M, 2)
	# l'armure sur son mannequin, contre le mur de droite
	var ax: float = hw - 0.6
	var az: float = hd * 0.2
	var arm: Node3D = _node(M, R.P(ax, 0, az), -90)
	var steel := Color(0.78, 0.8, 0.84)
	_part(arm, _boxm(Vector3(0.5, 0.04, 0.5)), Color(0.35, 0.25, 0.15), Vector3(0, 0.02, 0))
	_part(arm, _cyl(0.03, 0.03, 0.9), Color(0.35, 0.25, 0.15), Vector3(0, 0.47, 0))
	for sx in [-1.0, 1.0]:
		_part(arm, _cyl(0.07, 0.06, 0.75), steel, Vector3(sx * 0.11, 0.42, 0), Vector3.ONE, Vector3.ZERO, 0.0, 0.85)
		_part(arm, _cyl(0.06, 0.05, 0.55), steel, Vector3(sx * 0.26, 1.15, 0), Vector3.ONE, Vector3(0, 0, sx * 0.12), 0.0, 0.85)
		_part(arm, _sph(0.1), steel, Vector3(sx * 0.24, 1.43, 0), Vector3(1.2, 0.8, 1.0), Vector3.ZERO, 0.0, 0.85)
	_part(arm, _cyl(0.2, 0.17, 0.62), steel, Vector3(0, 1.18, 0), Vector3(1.0, 1.0, 0.75), Vector3.ZERO, 0.0, 0.85)
	var helm: MeshInstance3D = _part(arm, _cyl(0.12, 0.13, 0.28), steel, Vector3(0, 1.66, 0), Vector3.ONE, Vector3.ZERO, 0.0, 0.85)
	_part(arm, _boxm(Vector3(0.18, 0.02, 0.01)), Color(0.05, 0.05, 0.05), Vector3(0, 1.68, 0.13))
	_part(arm, _cyl(0.0, 0.04, 0.22), Color(0.8, 0.1, 0.1), Vector3(0, 1.88, 0))
	var k: Node = M.person("homme", ax - 1.2, az + 0.2, 90, "bras_croises", str(_pick(M, ["Sire Gauvain", "Messire Bertrand", "Sire Aymeric", "Messire Godefroy"])))
	k.lines = ["Elle brille, hein ?", "Une armure, ça s'entretient !", "Pour l'honneur de Montjoie !"]
	var cb := func() -> void:
		M.talk(k, str(_pick(M, ["Ah ! Un futur chevalier, je le vois à ton regard ! Tu veux devenir mon écuyer ?", "Halte ! Qui va là ? … Oh, un visiteur. Pardon, l'habitude. Tu veux voir mon armure ?", "Bienvenue chez un chevalier de Montjoie ! Je lustre mon armure pour le tournoi. Tu veux m'aider ?"])),
			[{"id": "ecuyer", "label": "Oui, je veux être écuyer !"}, {"id": "armure", "label": "Je peux essayer le casque ?"}, {"id": "fermer", "label": "Bon tournoi !"}], func(id):
			if id == "ecuyer":
				if bool(M.state().get("adoube", false)):
					M.talk(k, "Tu es déjà mon écuyer, mon brave ! Le premier devoir d'un écuyer : revenir me voir. Tu l'as fait. Bravo.", _bye("À vos ordres !"), _close(M))
					return
				M.state()["adoube"] = true
				k.gesture("salut", 2.0)
				M.talk(k, "À genoux ! … Bon, pas la peine, le sol est froid. Par le pouvoir qui m'est conféré par… moi-même, je te nomme Écuyer d'Honneur de Montjoie ! Voici ta solde.", _bye("Merci, Sire !"), func(_i):
					M.give([["piece", 15 + r.randi() % 10], ["tourte_montjoie", 1]], "")
					M.close_talk())
			elif id == "armure":
				helm.visible = false
				M.main.sfx("pas_armure")
				M.talk(k, "Vas-y, mets le casque ! … (Il est beaucoup trop grand. Tu ne vois plus rien. Tu entends le chevalier rire.) HA HA ! Il te va… très bien ! Enfin, tes oreilles, oui.", _bye("(Rendre le casque)"), func(_i):
					helm.visible = true
					M.close_talk())
			else:
				M.close_talk(), "fier")
	M.talk_spot(k, cb)
	M.act(R.P(ax - 0.6, 0, az), "E : regarder l'armure", func(): M.say("Une armure étincelante, polie comme un miroir. Sur le plastron, quelqu'un a gravé : « Propriété de Sire Fanfaron. Ne pas toucher. Sauf pour la faire briller. »", 6.0), 1.0)
	M.ctx["entree"] = str(_pick(M, ["Une armure complète trône au milieu du salon. Son propriétaire la regarde comme un trésor.", "Ça sent le cuir et l'huile de chevalier. Une armure brille contre le mur.", "« Halte-là ! » … Ah non, c'est juste une armure sur un mannequin. Son chevalier est juste à côté."]))


# =================================================================== Pandémonia : le petit démon peureux

static func _demon(M) -> void:
	var R = M.R
	var r := _r(M)
	var places: Array = S._salon(M, 3)
	var kid: Node = M.person(str(_pick(M, ["garcon", "fille"])), -0.2, 0.15, 180, "cache")
	kid.follow = false
	var maman: Node = M.person("femme", R.W * 0.5 - 1.0, -R.D * 0.25, -90, "bras_croises")
	maman.lines = ["Il est timide.", "Allez, sors de là, mon petit charbon !", "Il n'a jamais vu d'humain."]
	kid.lines = ["UN HUMAIN !", "Il va me manger !", "Maman, il a pas de cornes !", "Pas de queue non plus !"]
	kid.line_every = Vector2(3.0, 5.0)
	var calme: Array = [bool(M.state().get("calme", false))]
	if calme[0]:
		kid.set_pose("debout", Vector3(0, 0, 1))
		kid.lines = ["C'est mon ami l'humain !", "Tu reviens jouer ?", "Regarde, je fais une flamme !"]
	var cb := func() -> void:
		if calme[0]:
			M.talk(kid, "C'est toi ! Mon ami l'humain sans cornes ! Regarde, j'ai appris à faire une flamme ! … Bon, c'est une petite flamme. Une étincelle. Mais elle est à moi !", _bye("Elle est très belle !"), _close(M))
			return
		M.talk(kid, "AAAAH ! Un… un HUMAIN ! Ne me mange pas ! Je suis tout petit ! Et je suis trop épicé, je te préviens !",
			[{"id": "gentil", "label": "N'aie pas peur, je suis gentil."}, {"id": "grimace", "label": "(Faire une grimace)"}, {"id": "cornes", "label": "Moi aussi j'ai peur des démons, tu sais."}], func(id):
			match id:
				"gentil":
					calme[0] = true
					M.state()["calme"] = true
					kid.set_pose("debout", Vector3(0, 0, 1))
					kid.gesture("joie", 2.0)
					M.talk(kid, "C'est… c'est vrai ? Tu ne manges pas les petits démons ? … Ouf ! Tiens, c'est ma brioche préférée. Tu peux l'avoir. Mais juste une !", _bye("Merci !"), func(_i):
						M.give([["brioche_braise", 1]], "")
						M.close_talk())
				"grimace":
					kid.gesture("sursaut", 1.0)
					M.talk(maman, "Ha ha ! Tu vois, mon trésor, les humains aussi font des grimaces ! Ils sont comme nous… en plus pâles.", _bye("(Sourire)"), _close(M))
				_:
					calme[0] = true
					M.state()["calme"] = true
					kid.set_pose("debout", Vector3(0, 0, 1))
					M.talk(kid, "Vrai ?! Toi aussi ?! … Alors on n'a qu'à avoir peur ensemble ! Comme ça, on aura moins peur ! Tiens, ça porte bonheur.", _bye("Marché conclu !"), func(_i):
						M.give([["piment_infernal", 1], ["piece", 4 + r.randi() % 5]], "")
						M.close_talk())
		, "terrifié")
	M.talk_spot(kid, cb, "E : rassurer le petit démon")
	M.ctx["entree"] = "Un petit démon plonge sous la table en te voyant. « MAMAAAN ! UN HUMAIN ! »" if not calme[0] else "Le petit démon court vers toi : « C'est mon ami l'humain ! »"


# =================================================================== Port-Boucan : la répétition

static func _repetition(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.tapis(0.0, -hd * 0.3, 0, 3.0, 2.0)
	# la batterie, l'ampli, les affiches
	var bx: float = 0.0
	var bz: float = -hd + 0.9
	for k in range(3):
		R.kit.cyl(R.L(bx - 0.5 + k * 0.5, 0, bz), 0.25 - k * 0.04, 0.25 - k * 0.04, 0.45 + k * 0.05, ["tissu_rouge", "tissu_noir", "argent"][k], 14)
	R.kit.cyl(R.L(bx + 0.75, 0.9, bz + 0.1), 0.22, 0.22, 0.01, "or", 16)
	R.kit.cyl(R.L(bx + 0.75, 0, bz + 0.1), 0.01, 0.01, 0.9, "metal", 6)
	R.kit.box(R.L(-hw + 0.5, 0.45, -hd + 0.6, 25), Vector3(0.7, 0.9, 0.45), "noir", 1.0)
	R.kit.box(R.L(-hw + 0.5, 0.45, -hd + 0.84, 25), Vector3(0.55, 0.6, 0.01), "tissu_gris", 1.0, 16)
	S._murs(M, 4)
	R.canape(hw - 0.6, hd * 0.2, -90, "violet")
	var g: Node = M.person(str(_pick(M, ["homme", "femme"])), -0.9, -hd * 0.1, 160, "debout")
	var b: Node = M.person(str(_pick(M, ["femme", "homme"])), 0.9, -hd * 0.1, -160, "debout")
	g.npc.call("_play", "bo/guitare", 0.3)
	b.npc.call("_play", "bo/basse", 0.3)
	g.pose = "guitare_bo"
	b.pose = "basse_bo"
	g.follow = false
	b.follow = false
	for f in [g, b]:
		f.lines = ["♪ 1, 2, 3, 4 ! ♪", "♫ BOUCAAAAN ! ♫", "Encore une fois, depuis le refrain !", "♪ GRAAANG ! ♪", "Plus fort !"]
		f.line_every = Vector2(3.0, 5.0)
	var cb := func() -> void:
		M.talk(g, str(_pick(M, ["Yo ! On répète pour le concert de samedi. Il nous manque un chanteur. Tu sais chanter ?", "Salut ! Tu tombes à pic : notre chanteur a perdu sa voix. Littéralement. Il l'a cherchée partout. Tu veux le remplacer ?", "Hé ! Bienvenue au local de répète ! Il nous faut une voix. Tu veux essayer le micro ?"])),
			[{"id": "chanter", "label": "Je chante !"}, {"id": "nom", "label": "C'est quoi le nom du groupe ?"}, {"id": "fermer", "label": "Je ne fais qu'écouter."}], func(id):
			match id:
				"chanter":
					M.main.sfx("larsen_micro")
					M.main.sfx("guitare_riff")
					g.gesture("joie", 2.5)
					b.gesture("joie", 2.5)
					var first: bool = not bool(M.state().get("chante", false))
					M.state()["chante"] = true
					M.talk(b, "(Tu cries dans le micro. Le larsen fait sauter un pot de fleurs. Le chien du voisin se met à hurler en rythme.) … OUAIS ! C'ÉTAIT PARFAIT ! Tu es engagé !" + (" Tiens, notre fanzine dédicacé !" if first else ""), _bye("ROCK'N'ROLL !"), func(_i):
						if first:
							M.give([["fanzine", 1]], "")
						M.close_talk())
				"nom":
					M.talk(b, str(_pick(M, ["Les Clous Rouillés ! Avant, on s'appelait Les Clous Neufs, mais on a vieilli.", "Les Taupes Hurlantes. On répétait dans une cave. Les taupes ont déménagé.", "Bruit de Fond ! C'est ce que dit la voisine. On a pris ça pour un compliment."])), _bye("Super nom !"), _close(M))
				_:
					M.close_talk()
		, "à fond")
	M.talk_spot(g, cb)
	M.talk_spot(b, cb)
	M.ctx["on_enter"] = func(first: bool) -> void:
		M.main.sfx("guitare_riff")
		if first:
			M.say(str(_pick(M, ["♪ GRAAAANG ! ♪ Tu viens d'entrer en pleine répétition. Les murs tremblent.", "Un ampli, une batterie, deux musiciens qui secouent la tête… et des boules Quies sur la table, pour les invités.", "Ça joue fort ! Très fort ! Le lustre se balance en rythme."])), 6.0)
		for i in range(4):
			await M.get_tree().create_timer(7.0 + i * 5.0).timeout
			if M.inside:
				M.main.sfx(["guitare_riff", "batterie_roulement", "cymbale"][i % 3])


# =================================================================== Tazira : le thé à la menthe

static func _the(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.tapis(0.0, -0.2, 0, 3.2, 2.4, 0)
	R.table_ronde(0.0, -0.2, 0.55, 0.35)
	# les coussins tout autour, le plateau, la théière, les verres
	for k in range(6):
		var a: float = TAU * k / 6.0
		R.kit.cyl(R.L(cos(a) * 1.1, 0, -0.2 + sin(a) * 1.1), 0.3, 0.32, 0.18, "tissu_" + ["rouge", "orange", "jaune", "turquoise", "violet", "vert"][k], 12)
	R.kit.cyl(R.L(0.0, 0.35, -0.2), 0.38, 0.38, 0.015, "cuivre", 20)
	R.kit.cyl(R.L(0.0, 0.365, -0.2), 0.11, 0.13, 0.16, "argent", 12)
	R.kit.cyl(R.L(0.0, 0.525, -0.2), 0.06, 0.1, 0.06, "argent", 12)
	for k2 in range(5):
		var a2: float = TAU * k2 / 5.0 + 0.3
		R.kit.cyl(R.L(cos(a2) * 0.25, 0.365, -0.2 + sin(a2) * 0.25), 0.03, 0.025, 0.08, "verre", 8)
	R.etagere_murale(-hw + 0.15, 1.5, 0.0, 90, 1.4, "terre_cuite", 6)
	R.foyer(hw - 0.8, -hd + 0.5, 0, true)
	S._murs(M, 3)
	var hote: Node = M.person(str(_pick(M, ["vieux", "homme", "vieille", "femme"])), 1.1, -0.2, -90, "assis")
	hote.npc.global_position.y -= 0.27
	hote.lines = ["Assieds-toi, assieds-toi !", "Le thé, ça ne se presse pas.", "Encore un verre ?"]
	var verres: Array = [int(M.state().get("verres", 0))]
	var cb := func() -> void:
		var txt: Array = ["Bienvenue ! Chez nous, on ne laisse pas repartir un visiteur sans un verre de thé. Le premier verre est doux comme la vie…",
			"Le deuxième verre est fort comme l'amour… Tiens.",
			"Et le troisième est suave comme la mort ! … Non, je plaisante, il est surtout très sucré. Tiens, garde la menthe pour la route."]
		if verres[0] >= 3:
			M.talk(hote, "Trois verres, c'est la tradition ! Le quatrième, c'est pour les gourmands… Reviens demain, je ferai une nouvelle théière.", _bye("Merci pour le thé !"), _close(M), "radieux")
			return
		M.talk(hote, str(txt[verres[0]]), [{"id": "boire", "label": "(Boire le verre de thé)"}, {"id": "fermer", "label": "Merci, une autre fois."}], func(id):
			if id != "boire":
				M.close_talk()
				return
			M.main.sfx("boire")
			verres[0] += 1
			M.state()["verres"] = verres[0]
			var hero: Node = M.main.get("hero_v28")
			if hero != null and hero.has_method("heal"):
				hero.heal(4)
			if verres[0] >= 3:
				M.give([["the_menthe", 1], ["dattes", 1]], "Trois verres de thé ! Tu es requinqué. ")
			M.close_talk()
		, "radieux")
	M.talk_spot(hote, cb)
	M.ctx["entree"] = str(_pick(M, ["Ça sent la menthe fraîche. Autour d'une petite table basse, des coussins de toutes les couleurs.", "« Entre, entre ! » Quelqu'un verse du thé de très haut, sans en renverser une goutte.", "Un plateau de cuivre, une théière d'argent, des verres colorés : c'est l'heure du thé."]))


# =================================================================== Astralys : la pièce en apesanteur

static func _apesanteur(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var nodes: Array = []
	nodes.append(R.movable(func(): R.table_ronde(-0.6, 0.0, 0.5)))
	nodes.append(R.movable(func(): R.chaise(-1.3, 0.2, 90)))
	nodes.append(R.movable(func(): R.chaise(0.2, -0.6, 0)))
	nodes.append(R.movable(func(): R.fauteuil(hw - 1.0, -hd * 0.3, -110, "violet")))
	nodes.append(R.movable(func(): R.pile(0.8, 0.8, "livres", 5)))
	nodes.append(R.movable(func(): R.plante(-hw + 0.6, hd * 0.2)))
	nodes.append(R.movable(func(): R.lit(-hw + 0.7, -hd * 0.25, 90, 1.0, "violet")))
	R.foyer(hw - 0.6, hd * 0.25, -90, true)
	S._murs(M, 3)
	var flot: Array = [true]
	var t0: float = r.randf() * 10.0
	for i in range(nodes.size()):
		var n: Node3D = nodes[i]
		var up: float = 0.5 + r.randf() * 0.9
		n.position = Vector3(0, up, 0)
		var tw: Tween = M.room.create_tween().set_loops()
		tw.tween_property(n, "position:y", up + 0.25, 2.5 + i * 0.3).set_trans(Tween.TRANS_SINE)
		tw.tween_property(n, "position:y", up - 0.15, 2.5 + i * 0.3).set_trans(Tween.TRANS_SINE)
	var l: Node = M.person(str(_pick(M, ["homme", "femme", "vieux", "vieille"])), 0.3, 0.5, 180, "debout")
	l.npc.call("_play", "lu/leviter", 0.3)
	l.pose = "leviter"
	l.follow = false
	var ly: float = l.npc.global_position.y
	var tw2: Tween = M.room.create_tween().set_loops()
	tw2.tween_property(l.npc, "global_position:y", ly + 0.6, 3.0).set_trans(Tween.TRANS_SINE)
	tw2.tween_property(l.npc, "global_position:y", ly + 0.3, 3.0).set_trans(Tween.TRANS_SINE)
	l.lines = ["Wiii !", "Attention à la tête !", "On s'habitue, tu verras.", "Tout flotte chez moi !"]
	var cb := func() -> void:
		M.talk(l, str(_pick(M, ["Oh, un Pied-Lourd ! Bienvenue ! Excuse le désordre : j'ai encore oublié de rallumer le régulateur de gravité. Tu veux que je le rallume ?", "Salut ! Tu flottes, toi aussi ? Non ? Ah, les Pieds-Lourds… Bon, je rallume la gravité, ou tu préfères que tout flotte ?"])),
			[{"id": "rallumer", "label": "Rallume la gravité !"}, {"id": "flotter", "label": "Non, j'adore quand ça flotte !"}], func(id):
			if id == "rallumer":
				M.main.sfx("holo_bip")
				for n2 in nodes:
					var tw3: Tween = M.room.create_tween()
					tw3.tween_property(n2, "position", Vector3.ZERO, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
				M.main.sfx("touche_bois")
				if not bool(M.state().get("gravite", false)):
					M.state()["gravite"] = true
					M.talk(l, "BOUM ! … Voilà, tout est par terre. Même moi, presque. Merci, tiens, un biscuit de chez nous. Il flotte aussi, attention.", _bye("Merci !"), func(_i):
						M.give([["biscuit_lunaire", 1], ["piece", 6 + r.randi() % 6]], "")
						M.close_talk())
				else:
					M.talk(l, "Et voilà, tout est par terre. Je la rééteindrai ce soir, c'est plus reposant pour dormir.", _bye("Bonne nuit, alors !"), _close(M))
			else:
				M.talk(l, "Ha ha ! Un Pied-Lourd qui aime flotter ! Tu es presque un Lumen. Reviens quand tu veux, la gravité, c'est surfait.", _bye("Ha ha !"), _close(M))
		, "lumineux")
	M.talk_spot(l, cb)
	M.ctx["entree"] = str(_pick(M, ["Tout flotte ! La table, les chaises, les livres… et même la plante verte, qui a l'air ravie.", "Une pièce sans gravité : les meubles se balancent doucement dans l'air, comme des bateaux.", "Attention à la tête : un fauteuil passe au-dessus de toi, tranquillement."]))


# =================================================================== Cliquetis : le robot-majordome

static func _robot(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var places: Array = S._salon(M, 2)
	var rb: Node3D = _node(M, R.P(0.6, 0, 1.0), 180)
	var cu := Color(0.78, 0.5, 0.25)
	_part(rb, _cyl(0.2, 0.25, 0.1), Color(0.2, 0.2, 0.22), Vector3(0, 0.08, 0), Vector3.ONE, Vector3.ZERO, 0.0, 0.6)
	var body: Node3D = Node3D.new()
	rb.add_child(body)
	_part(body, _cyl(0.22, 0.26, 0.7), cu, Vector3(0, 0.5, 0), Vector3.ONE, Vector3.ZERO, 0.0, 0.8)
	_part(body, _sph(0.2), cu, Vector3(0, 1.05, 0), Vector3(1, 0.85, 1), Vector3.ZERO, 0.0, 0.8)
	for sx in [-1.0, 1.0]:
		_part(body, _sph(0.05), Color(0.3, 0.9, 1.0), Vector3(sx * 0.08, 1.08, 0.17), Vector3.ONE, Vector3.ZERO, 3.0)
		_part(body, _cyl(0.035, 0.035, 0.45), Color(0.3, 0.3, 0.32), Vector3(sx * 0.3, 0.6, 0.05), Vector3.ONE, Vector3(0.4, 0, sx * 0.2), 0.0, 0.7)
	_part(body, _cyl(0.01, 0.01, 0.2), Color(0.3, 0.3, 0.32), Vector3(0, 1.3, 0))
	var bulb: MeshInstance3D = _part(body, _sph(0.04), Color(1.0, 0.3, 0.2), Vector3(0, 1.42, 0), Vector3.ONE, Vector3.ZERO, 2.5)
	_part(body, _cyl(0.2, 0.2, 0.02), Color(0.85, 0.86, 0.88), Vector3(0.3, 0.85, 0.3), Vector3.ONE, Vector3.ZERO, 0.0, 0.9)
	_part(body, _cyl(0.04, 0.035, 0.08), Color(0.95, 0.95, 0.92), Vector3(0.3, 0.9, 0.3))
	var tw: Tween = M.room.create_tween().set_loops()
	tw.tween_property(body, "position:y", 0.04, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(body, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	var tw2: Tween = M.room.create_tween().set_loops()
	tw2.tween_property(bulb, "scale", Vector3.ONE * 1.4, 0.5)
	tw2.tween_property(bulb, "scale", Vector3.ONE, 0.5)
	var maitre: Node = S._asseoir(M, str(_pick(M, ["vieux", "vieille", "homme"])), places[0], "lire")
	maitre.lines = ["Bielle, mon thé !", "Ah, ce robot…", "Il faut que je resserre ses boulons."]
	var lab := Label3D.new()
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 36
	lab.pixel_size = 0.003
	lab.outline_size = 10
	lab.no_depth_test = true
	lab.position = Vector3(0, 1.75, 0)
	rb.add_child(lab)
	var dire := func(t: String) -> void:
		lab.text = t
		M.main.sfx("robot_voix", rb.global_position)
	dire.call("BIP. BONJOUR, INVITÉ.")
	var cb := func() -> void:
		M.main.sfx("robot_bip", rb.global_position)
		M.talk(maitre, "Je te présente Bielle, mon majordome mécanique ! Il est très poli. Un peu trop. Bielle, sers donc un thé à notre invité !",
			[{"id": "the", "label": "Oui, un thé, s'il vous plaît !"}, {"id": "danse", "label": "Il sait danser ?"}, {"id": "fermer", "label": "Non merci !"}], func(id):
			match id:
				"the":
					dire.call("THÉ. EN COURS. BIP. BIP. BIIIIP.")
					var tw3: Tween = M.room.create_tween()
					tw3.tween_property(rb, "rotation:y", rb.rotation.y + TAU * 3.0, 1.5)
					M.main.sfx("vapeur", rb.global_position)
					await M.get_tree().create_timer(1.6).timeout
					if not M.inside:
						return
					dire.call("VOICI. UNE SOUPE. AUX BOULONS.")
					M.talk(maitre, "… Une soupe aux boulons. C'est la troisième fois cette semaine. Bon, garde les boulons, ils peuvent toujours servir.", _bye("Merci, Bielle !"), func(_i):
						if not bool(M.state().get("boulons", false)):
							M.state()["boulons"] = true
							M.give([["boulon", 2], ["cafe_vapeur", 1]], "")
						M.close_talk())
				"danse":
					dire.call("DANSE. MODE. ACTIVÉ.")
					var tw4: Tween = M.room.create_tween()
					for k in range(4):
						tw4.tween_property(body, "rotation:z", 0.3, 0.2)
						tw4.tween_property(body, "rotation:z", -0.3, 0.2)
					tw4.tween_property(body, "rotation:z", 0.0, 0.2)
					M.main.sfx("robot_servo", rb.global_position)
					M.talk(maitre, "Ha ha ! Il ne connaît qu'une danse : la valse du tournevis. Mais il la danse avec cœur. Enfin, avec un piston.", _bye("Bravo, Bielle !"), _close(M))
				_:
					dire.call("DOMMAGE. BIP.")
					M.close_talk()
		, "amusé")
	M.talk_spot(maitre, cb)
	M.act(rb.global_position + Vector3(0, 0, -0.5), "E : parler au robot", cb, 1.2)
	M.ctx["entree"] = str(_pick(M, ["« BIP. BONJOUR. INVITÉ. » Un petit robot de cuivre roule vers toi, un plateau à la main.", "Un majordome mécanique t'accueille en clignotant de partout. Il a l'air très fier de son plateau.", "Un robot ! Il fait une révérence, perd un boulon, le ramasse, et refait la révérence."]))


# =================================================================== Ramure : le tanuki-théière

static func _tanuki(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.tapis(0.0, 0.0, 0, 2.4, 1.8)
	R.table_ronde(0.4, -0.3, 0.45, 0.4)
	R.foyer(-hw + 1.0, -hd + 0.9, 45, true)
	R.etagere(hw - 0.22, 0.0, -90, 1.0, 1.6, false, 4)
	for k in range(6):
		R.kit.cyl(R.L(hw - 0.22, 0.12 + (k % 3) * 0.5, -0.3 + (k / 3) * 0.5), 0.07, 0.08, 0.12, ["terre_cuite", "ceramique", "cuivre"][k % 3], 10)
	S._murs(M, 2)
	# la « théière » (le tanuki transformé), sur la table basse
	var tp: Node3D = _node(M, R.P(0.4, 0.41, -0.3), 30)
	var brun := Color(0.5, 0.36, 0.22)
	_part(tp, _sph(0.17), brun, Vector3(0, 0.15, 0), Vector3(1, 0.9, 1))
	_part(tp, _cyl(0.06, 0.09, 0.06), brun, Vector3(0, 0.3, 0))
	_part(tp, _cyl(0.025, 0.035, 0.18), brun, Vector3(0.2, 0.2, 0), Vector3.ONE, Vector3(0, 0, -0.9))
	_part(tp, _sph(0.06), brun, Vector3(-0.17, 0.2, 0), Vector3(1, 1.6, 0.4))
	var queue: MeshInstance3D = _part(tp, _sph(0.06), Color(0.42, 0.3, 0.2), Vector3(-0.22, 0.05, 0), Vector3(1.6, 0.8, 0.8))
	queue.visible = true
	var tw: Tween = M.room.create_tween().set_loops()
	tw.tween_property(queue, "rotation:y", 0.5, 0.5)
	tw.tween_property(queue, "rotation:y", -0.5, 0.5)
	var tanuki: Node = M.person(str(_pick(M, ["homme", "vieux", "femme"])), 0.4, 0.4, 180, "rire")
	tanuki.npc.visible = false
	var trouve: Array = [false]
	var cb := func() -> void:
		if trouve[0]:
			M.talk(tanuki, "Hi hi ! Tu veux que je me retransforme ? Non ? Dommage, j'étais une très belle théière.", _bye("La plus belle !"), _close(M))
			return
		trouve[0] = true
		tp.visible = false
		M.main.sfx("champignard_pouf")
		var cb2: Node = M.main.get("combat_v28")
		if cb2 != null and cb2.has_method("puff"):
			cb2.puff(tp.global_position + Vector3.UP * 0.3, Color(0.9, 0.9, 0.85))
		tanuki.npc.visible = true
		tanuki.gesture("rire", 2.5)
		var first: bool = not bool(M.state().get("tanuki", false))
		M.state()["tanuki"] = true
		M.talk(tanuki, str(_pick(M, ["POUF ! Ha ha ha ! Tu as vu la tête que tu as faite ?! Une théière qui remue la queue, ça ne t'a pas mis la puce à l'oreille ?", "Démasqué ! Ha ha ! Personne ne m'avait jamais trouvé aussi vite. Enfin… à part ma grand-mère. Et le chat."])) + (" Tiens, pour le gagnant !" if first else ""),
			_bye("Ha ha ! Bien joué, toi aussi."), func(_i):
			if first:
				M.give([["gland_dore", 1], ["pain_carotte", 1]], "")
			M.close_talk())
	M.act(tp.global_position, "E : examiner la théière", cb, 1.4)
	M.ctx["entree"] = str(_pick(M, ["Il n'y a personne… juste une théière sur la table basse. Une théière avec… une queue touffue ?", "Une maison vide. Sur la table, une jolie théière brune. Elle vient de remuer, non ?", "Personne. Une théière. Une théière qui te regarde. Les théières ne regardent pas, d'habitude."]))


# =================================================================== Arcanelle : la potion ratée

const INGREDIENTS := [["queue", "Une queue de lézard"], ["pomme", "Une pomme bien rouge"], ["chaussette", "Une chaussette sale"], ["plume", "Une plume de chouette"]]

static func _potion(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.etagere(-hw + 0.22, -hd * 0.2, 90, 1.3, 2.0, true, 5)
	R.etagere_murale(hw - 0.15, 1.5, -hd * 0.3, -90, 1.4, "verre", 7)
	R.etagere_murale(hw - 0.15, 1.1, -hd * 0.3, -90, 1.4, "terre_cuite", 6)
	R.tapis(0.0, 0.3, 0, 2.6, 1.8)
	S._murs(M, 2)
	# le chaudron qui bouillonne (vert)
	var cx: float = 0.3
	var cz: float = -hd + 1.3
	R.kit.cyl(R.L(cx, 0, cz), 0.35, 0.45, 0.55, "fer", 16)
	R.kit.cyl(R.L(cx, 0.53, cz), 0.36, 0.36, 0.02, "feuillage", 16)
	R.fire(R.P(cx, 0.05, cz), 0.5)
	var bub := CPUParticles3D.new()
	bub.amount = 24
	bub.lifetime = 1.4
	bub.direction = Vector3.UP
	bub.spread = 15.0
	bub.initial_velocity_min = 0.2
	bub.initial_velocity_max = 0.5
	bub.gravity = Vector3.ZERO
	bub.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	bub.emission_sphere_radius = 0.25
	var q := SphereMesh.new()
	q.radius = 0.04
	q.height = 0.08
	var qm := StandardMaterial3D.new()
	qm.albedo_color = Color(0.4, 1.0, 0.5, 0.7)
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.emission_enabled = true
	qm.emission = Color(0.3, 1.0, 0.4)
	q.material = qm
	bub.mesh = q
	M.room.add_child(bub)
	bub.global_position = R.P(cx, 0.6, cz)
	# le maître… changé en grenouille, sur une chaise, avec son chapeau pointu
	R.chaise(-0.9, 0.0, 30)
	var fr: Node3D = _node(M, R.P(-0.9, 0.48, 0.0), 30)
	var vert := Color(0.3, 0.65, 0.25)
	_part(fr, _sph(0.16), vert, Vector3(0, 0.12, 0), Vector3(1.0, 0.75, 1.1))
	for sx in [-1.0, 1.0]:
		_part(fr, _sph(0.055), vert, Vector3(sx * 0.08, 0.24, 0.08))
		_part(fr, _sph(0.03), Color(0.05, 0.05, 0.05), Vector3(sx * 0.08, 0.26, 0.12))
		_part(fr, _sph(0.06), vert, Vector3(sx * 0.13, 0.03, 0.06), Vector3(1.2, 0.5, 1.6))
	_part(fr, _cyl(0.0, 0.1, 0.25), Color(0.2, 0.18, 0.42), Vector3(0, 0.38, 0))
	_part(fr, _cyl(0.17, 0.17, 0.015), Color(0.2, 0.18, 0.42), Vector3(0, 0.26, 0))
	var twf: Tween = M.room.create_tween().set_loops()
	twf.tween_property(fr, "scale", Vector3(1.0, 1.08, 1.0), 0.8)
	twf.tween_property(fr, "scale", Vector3.ONE, 0.8)
	var app: Node = M.person(str(_pick(M, ["garcon", "fille"])), cx + 0.8, cz + 0.3, -60, "debout")
	app.lines = ["Oh là là là là…", "Il va être furieux…", "C'était quoi, déjà, la formule ?", "Croâ… euh, pardon, Maître."]
	var bonne: int = hash(str(M.ctx["id"])) % INGREDIENTS.size()
	var fini: Array = [bool(M.state().get("potion", false))]
	var maitre: Array = [null]
	var redevenir := func() -> void:
		fr.visible = false
		var f2: Node = M.person("vieux", -0.9, 0.3, 30, "colere")
		maitre[0] = f2
		f2.lines = ["Croâ… hum. Pardon.", "J'ai encore envie de manger des mouches.", "Plus jamais de potion le lundi !"]
	if fini[0]:
		redevenir.call()
	var cb := func() -> void:
		if fini[0]:
			M.talk(app, "Le maître est redevenu normal ! Enfin… il a encore envie de manger des mouches, des fois. Merci encore !", _bye("De rien !"), _close(M))
			return
		var ch: Array = []
		for ing in INGREDIENTS:
			ch.append({"id": str(ing[0]), "label": str(ing[1]) + " dans le chaudron"})
		M.talk(app, "Oh non oh non oh non ! J'ai raté la potion de beauté, et maintenant… le maître est une GRENOUILLE ! Il manque un ingrédient pour inverser le sort. Mais lequel ?! Aide-moi !", ch, func(id):
			M.main.sfx("bulles", bub.global_position)
			if id == str(INGREDIENTS[bonne][0]):
				fini[0] = true
				M.state()["potion"] = true
				M.main.sfx("sort_lumiere")
				var cbt: Node = M.main.get("combat_v28")
				if cbt != null and cbt.has_method("puff"):
					cbt.puff(fr.global_position + Vector3.UP * 0.3, Color(0.6, 1.0, 0.6))
				redevenir.call()
				app.gesture("joie", 2.5)
				M.talk(app, "Ça a marché !!! Maître ! Vous êtes redevenu… vous ! Merci, merci ! Tiens, prends ça, c'est une potion réussie. Enfin, je crois.", _bye("Bravo !"), func(_i):
					M.give([["potion_mana", 1], ["piece", 8 + r.randi() % 8]], "")
					M.close_talk())
			else:
				var rates := {"queue": "La potion devient violette et sent le chou. La grenouille éternue. Raté !",
					"pomme": "La potion fait « plop » et sent la tarte. La grenouille a l'air intéressée, mais elle reste grenouille.",
					"chaussette": "La potion fume, une odeur terrible envahit la pièce. La grenouille se bouche le nez. Enfin, elle essaie.",
					"plume": "La potion se met à hululer. La grenouille cligne des yeux, très inquiète."}
				M.talk(app, str(rates.get(id, "Raté !")) + " … Essaie autre chose !", _bye("Je réfléchis…"), _close(M))
		, "paniqué")
	M.talk_spot(app, cb)
	M.act(fr.global_position, "E : regarder la grenouille", func(): M.say("Une grenouille à chapeau pointu, assise très dignement sur une chaise. Elle te regarde d'un air sévère. « Croâ. »", 5.0), 1.0, func(): return not fini[0])
	M.ctx["entree"] = str(_pick(M, ["Un chaudron qui bouillonne, une odeur de soufre… et une grenouille en chapeau de sorcier, assise sur une chaise.", "« AU SECOURS ! » Un apprenti sorcier tourne en rond autour de son chaudron. Sur une chaise, une grenouille le regarde, furieuse."])) if not fini[0] else "Le maître sorcier, redevenu humain, regarde son apprenti d'un air sévère. Il a encore un peu la peau verte."


# =================================================================== Port-Coutelas : le perroquet bavard

static func _perroquet(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.kit.cyl(R.L(-hw + 0.8, 1.7, -hd * 0.2), 0.01, 0.01, 0.9, "cuir", 4)
	R.kit.box(R.L(-hw + 0.8, 1.15, -hd * 0.2, 90), Vector3(1.8, 0.04, 0.8), "tissu_creme", 1.0)
	var pirate: Node = M.person(str(_pick(M, ["homme", "vieux"])), -hw + 0.8, -hd * 0.2 + 0.1, 90, "dormir")
	pirate.lie(R.P(-hw + 0.8 + 0.85, 1.2, -hd * 0.2), Vector3(-1, 0, 0))
	pirate.lines = ["Rrron… à l'abordage… zzz…", "Zzz… mon trésor…", "Rrrron… pfff…"]
	R.tonneau(hw - 0.6, -hd + 0.6)
	R.tonneau(hw - 1.3, -hd + 0.6)
	R.tonneau(hw - 0.6, -hd + 1.3, true)
	R.coffre_deco(0.0, -hd + 0.5, 0)
	R.table(0.6, 0.6, 15, 1.1, 0.7)
	R.tableau(0.0, 1.6, -hd + 0.02, 0, 1.0, 0.7, 0)
	R.tapis(0.0, 0.3, 0, 2.0, 1.4)
	# le perroquet, sur son perchoir
	var pr: Node3D = _node(M, R.P(1.3, 0, -0.6), 200)
	_part(pr, _cyl(0.02, 0.02, 1.3), Color(0.35, 0.25, 0.15), Vector3(0, 0.65, 0))
	_part(pr, _cyl(0.02, 0.02, 0.4), Color(0.35, 0.25, 0.15), Vector3(0, 1.3, 0), Vector3.ONE, Vector3(0, 0, PI * 0.5))
	var bird: Node3D = Node3D.new()
	pr.add_child(bird)
	bird.position = Vector3(0, 1.32, 0)
	_part(bird, _sph(0.09), Color(0.85, 0.1, 0.1), Vector3(0, 0.1, 0), Vector3(1, 1.3, 1))
	_part(bird, _sph(0.06), Color(0.85, 0.1, 0.1), Vector3(0, 0.25, 0.03))
	_part(bird, _cyl(0.0, 0.025, 0.05), Color(0.95, 0.85, 0.3), Vector3(0, 0.25, 0.09), Vector3.ONE, Vector3(PI * 0.55, 0, 0))
	_part(bird, _sph(0.05), Color(0.15, 0.5, 0.85), Vector3(0, 0.0, -0.08), Vector3(1, 2.0, 0.5), Vector3(0.5, 0, 0))
	for sx in [-1.0, 1.0]:
		_part(bird, _sph(0.05), Color(0.2, 0.7, 0.3), Vector3(sx * 0.08, 0.1, 0), Vector3(0.4, 1.4, 1.0))
	var tw: Tween = M.room.create_tween().set_loops()
	tw.tween_property(bird, "rotation:y", 0.6, 0.7)
	tw.tween_property(bird, "rotation:y", -0.4, 0.9)
	var lab := Label3D.new()
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 34
	lab.pixel_size = 0.003
	lab.outline_size = 10
	lab.no_depth_test = true
	lab.position = Vector3(0, 1.85, 0)
	pr.add_child(lab)
	var cache: String = str(_pick(M, ["tonneau", "coffre", "tableau"]))
	var cachettes := {"tonneau": "LE TONNEAU QUI DORT ! LE TONNEAU QUI DORT !", "coffre": "SOUS LE COFFRE ! SOUS LE COFFRE ! COCO VEUT UN BISCUIT !", "tableau": "DERRIÈRE LA CARTE ! DERRIÈRE LA CARTE ! RRRAAAH !"}
	var cri := func(t: String) -> void:
		lab.text = t
		M.main.sfx("perroquet", bird.global_position)
	cri.call("RRRAAAH ! BONJOURRR !")
	var dit: Array = [0]
	var cb := func() -> void:
		var phrases: Array = ["BONJOURRR ! COCO EST BEAU !", "LE TRÉSORRR ! LE TRÉSORRR DU CAPITAINE !", "CHUT ! C'EST UN SECRRRET !", str(cachettes[cache]), "COCO N'A RIEN DIT ! RIEN DIT !"]
		cri.call(str(phrases[dit[0] % phrases.size()]))
		dit[0] += 1
		if dit[0] == 4:
			M.say("Le perroquet a vendu la mèche… Le trésor du capitaine est caché quelque part par ici !", 5.0)
	M.act(bird.global_position - Vector3(0, 1.0, 0) + (R.P(0, 0, 0) - bird.global_position).normalized() * 0.4 * Vector3(1, 0, 1), "E : parler au perroquet", cb, 1.3)
	var trouve := func(where: String) -> void:
		if where != cache:
			M.say(str(_pick(M, ["Rien… à part une vieille chaussette de pirate. Beurk.", "Rien. Le perroquet ricane.", "Rien du tout. Le pirate grogne dans son sommeil."])), 3.5)
			return
		if bool(M.state().get("tresor", false)):
			M.say("La cachette est vide : tu as déjà pris le trésor. Le perroquet te regarde d'un air entendu.", 4.0)
			return
		M.state()["tresor"] = true
		M.main.sfx("coffre_pieces")
		pirate.say("Zzz… mon trésor… zzz…", 3.0)
		M.give([["piece_or", 1], ["piece", 15 + r.randi() % 15], ["noix_coco", 1]], "Bien caché, un petit sac de pièces ! Le trésor du capitaine ! (Il dort. Il ne saura jamais que son perroquet a parlé.) ")
	M.act(R.P(hw - 0.9, 0, -hd + 1.4), "E : fouiller le tonneau couché", func(): trouve.call("tonneau"), 1.1)
	M.act(R.P(0.0, 0, -hd + 1.1), "E : regarder sous le coffre", func(): trouve.call("coffre"), 1.1)
	M.act(R.P(0.4, 0, -hd + 0.8), "E : regarder derrière la carte", func(): trouve.call("tableau"), 0.9)
	M.ctx["entree"] = "Un pirate ronfle dans son hamac. Sur son perchoir, un perroquet rouge te regarde… et a très, très envie de bavarder."


# =================================================================== Carène : le bateau en bouteille

static func _bouteille(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.etabli(0.0, -hd + 0.55, 0, 2.2)
	for k in range(4):
		var bx: float = -hw + 0.8 + k * 0.6
		R.kit.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5), R.P(bx - 0.15, 1.62, -hd + 0.2)), 0.07, 0.07, 0.3, "verre", 12)
		R.kit.box(R.L(bx, 1.62, -hd + 0.2), Vector3(0.16, 0.04, 0.05), "bois_sombre", 1.0)
		R.kit.box(R.L(bx, 1.67, -hd + 0.2), Vector3(0.01, 0.08, 0.06), "drap", 1.0)
	R.kit.box(R.L(-hw * 0.4, 1.55, -hd + 0.15), Vector3(2.6, 0.04, 0.25), "bois", 1.0)
	R.lit(hw - 0.7, hd * 0.15, -90, 1.0, "bleu")
	R.tapis(0.0, 0.5, 0, 2.0, 1.4)
	S._murs(M, 2)
	var f: Node = M.person(str(_pick(M, ["vieux", "vieille", "homme"])), 0.0, -hd + 1.2, 180, "bricoler")
	f.lines = ["Doucement… doucement…", "Tire sur le fil… voilà…", "Un mât de plus !"]
	var cb := func() -> void:
		M.talk(f, str(_pick(M, ["Chut ! Je fais entrer un trois-mâts dans une bouteille. Il ne reste plus qu'à tirer sur le fil pour lever les mâts. Tu veux le faire ?", "Ah, un visiteur ! Tu veux savoir le secret des bateaux en bouteille ? On les fait entrer couchés, et on tire sur le fil. Tu veux essayer ?"])),
			[{"id": "tirer", "label": "Tirer doucement sur le fil"}, {"id": "fort", "label": "Tirer d'un coup sec !"}, {"id": "fermer", "label": "Non, j'ai peur de tout casser."}], func(id):
			match id:
				"tirer":
					var first: bool = not bool(M.state().get("bouteille", false))
					M.state()["bouteille"] = true
					M.main.sfx("ui_quete")
					M.talk(f, "Les mâts se lèvent… les voiles se déplient… PARFAIT ! Tu as des doigts de fée ! Tiens, celle-là est pour toi." if first else "Encore une réussite ! Tu devrais ouvrir ta propre boutique.", _bye("Merci !"), func(_i):
						if first:
							M.give([["carte_postale", 1], ["piece", 10 + r.randi() % 8]], "")
						M.close_talk())
				"fort":
					M.main.sfx("jarre_casse")
					M.talk(f, "… Le mât est passé à travers le bouchon. Le bouchon est passé à travers la fenêtre. Bon. On va dire que c'est un sous-marin.", _bye("Pardon !"), _close(M))
				_:
					M.close_talk()
		, "concentré")
	M.talk_spot(f, cb)
	M.ctx["entree"] = "Des bouteilles partout, et dans chacune, un bateau minuscule. Penché sur son établi, un vieux marin retient son souffle."


# =================================================================== Per-Hâpy : le chat sacré

static func _chat_sacre(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# l'autel du chat : une estrade, un coussin, des lampes, une statue
	R.kit.box(R.L(0.0, 0.2, -hd + 0.8), Vector3(1.6, 0.4, 1.0), "pierre_lisse", 1.0)
	R.kit.box(R.L(0.0, 0.45, -hd + 0.8), Vector3(0.8, 0.1, 0.6), "tissu_rouge", 1.0)
	R.chat(0.0, -hd + 0.8, 0, Color(0.85, 0.7, 0.45), true, 0.5)
	for sx in [-1.0, 1.0]:
		R.kit.cyl(R.L(sx * 1.1, 0, -hd + 0.7), 0.08, 0.12, 1.0, "or", 10)
		R.bougie(sx * 1.1, 1.0, -hd + 0.7, sx > 0.0)
	R.tapis(0.0, 0.3, 0, 2.4, 1.6)
	S._murs(M, 3)
	var gens: Array = []
	for k in range(2):
		var f: Node = M.person(["homme", "femme"][k], -0.6 + k * 1.2, 0.3, 180, "assis")
		f.npc.global_position.y -= 0.42
		f.lines = ["Ô grande Bastet !", "Elle a cligné de l'œil !", "Silence, elle dort."]
		gens.append(f)
	var cb := func() -> void:
		M.talk(gens[0], "Chut ! Tu es devant Nefer-Miou, la chatte sacrée de la maison. Elle descend de la grande Bastet elle-même. On lui doit le respect !",
			[{"id": "saluer", "label": "(S'incliner devant Nefer-Miou)"}, {"id": "caresser", "label": "(Lui gratter le menton)"}, {"id": "fermer", "label": "C'est juste un chat…"}], func(id):
			match id:
				"saluer":
					M.main.sfx("ronron")
					if not bool(M.state().get("bastet", false)):
						M.state()["bastet"] = true
						M.talk(gens[1], "Elle ronronne ! Nefer-Miou t'a accepté ! C'est un grand honneur. Prends ce gâteau de miel : c'est elle qui l'aurait voulu.", _bye("Merci, ô Nefer-Miou !"), func(_i):
							M.give([["gateau_miel", 1], ["piece", 6 + r.randi() % 6]], "")
							M.close_talk())
					else:
						M.talk(gens[1], "Elle se souvient de toi ! Elle ronronne encore plus fort que la dernière fois.", _bye("(S'incliner encore)"), _close(M))
				"caresser":
					M.main.sfx("chat_miaou")
					M.talk(gens[1], "… Elle a ronronné. Elle n'a jamais ronronné pour personne ! Pas même pour le grand prêtre ! Tu es peut-être… béni ?", _bye("Peut-être !"), _close(M))
				_:
					M.main.sfx("miaou")
					M.talk(gens[0], "JUSTE UN CHAT ?! Elle t'a entendu ! Regarde, elle te tourne le dos ! C'est la pire insulte, chez les chats sacrés !", _bye("Oups… pardon, Nefer-Miou."), _close(M))
		, "dévot")
	for g in gens:
		M.talk_spot(g, cb)
	M.ctx["entree"] = "Deux personnes sont agenouillées devant… un chat. Allongé sur un coussin, entre deux lampes à huile, il fait semblant de dormir."


# =================================================================== Yaxché : le chocolat

static func _chocolat(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.foyer(-hw + 1.0, -hd + 0.9, 45, true)
	for k in range(5):
		R.kit.cyl(R.L(hw - 0.5, 0, -hd + 0.6 + k * 0.55), 0.18, 0.22, 0.5 + (k % 2) * 0.15, "terre_cuite", 12)
	R.tapis(0.0, 0.0, 0, 2.4, 1.8)
	R.kit.box(R.L(0.2, 0.15, -0.3), Vector3(1.0, 0.3, 0.6), "pierre_lisse", 1.0)
	R.kit.cyl(R.L(0.0, 0.3, -0.3), 0.12, 0.15, 0.2, "terre_cuite", 12)
	R.kit.cyl(R.L(0.0, 0.48, -0.3), 0.11, 0.11, 0.01, "chocolat", 12)
	R.kit.cyl(R.L(0.45, 0.3, -0.3), 0.1, 0.12, 0.16, "terre_cuite", 12)
	S._murs(M, 2)
	var f: Node = M.person(str(_pick(M, ["femme", "vieille", "homme"])), 0.2, 0.4, 180, "cuisiner")
	f.lines = ["Plus de mousse !", "On verse de haut, comme ça…", "Le cacao, c'est la boisson des dieux !"]
	var cb := func() -> void:
		M.talk(f, "Bienvenue ! Je prépare le cacao. Le secret, c'est la mousse : on verse d'un pot à l'autre, de très haut. Tu veux essayer ?",
			[{"id": "verser", "label": "Verser de très haut !"}, {"id": "piment", "label": "Il y a du piment dedans ?"}, {"id": "fermer", "label": "Non merci."}], func(id):
			match id:
				"verser":
					M.main.sfx("verser")
					var first: bool = not bool(M.state().get("cacao", false))
					M.state()["cacao"] = true
					M.talk(f, ("Quelle mousse ! Tu es doué ! Un peu en a giclé sur le plafond, mais c'est le signe d'un bon cacao. Tiens, goûte !" if r.randf() < 0.5 else "Oh ! Belle mousse ! … Et belle moustache en chocolat, aussi. Tiens, tu l'as bien mérité."), _bye("Miam !"), func(_i):
						if first:
							M.give([["cacao", 1], ["galette_mais", 1]], "")
						M.close_talk())
				"piment":
					M.talk(f, "Bien sûr ! Du cacao, du piment, un peu de vanille, et de l'eau. Le sucre ? Qu'est-ce que c'est, le sucre ?", _bye("Ah… d'accord."), _close(M))
				_:
					M.close_talk()
		, "joyeux")
	M.talk_spot(f, cb)
	M.ctx["entree"] = "Ça sent le chocolat chaud et la vanille. Quelqu'un verse un liquide brun et mousseux d'un pot à l'autre, de très, très haut."


# =================================================================== Aztlán : l'atelier des plumes

const PLUMES := [["rouge", "rouge comme le feu"], ["bleu", "bleue comme le ciel"], ["vert", "verte comme le quetzal"], ["jaune", "jaune comme le soleil"]]

static func _plumes(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.table(0.0, -hd + 0.9, 0, 1.6, 0.8, 0.76)
	for k in range(14):
		var c: String = str(PLUMES[k % 4][0])
		R.kit.box(R.L(-0.7 + k * 0.1, 0.8, -hd + 0.9 + r.randf_range(-0.2, 0.2), r.randf_range(-30, 30)), Vector3(0.03, 0.01, 0.35), "tissu_" + c, 1.0)
	# la coiffe en cours, sur un mannequin
	var cf: Node3D = _node(M, R.P(hw - 0.8, 0, -hd * 0.1), -90)
	_part(cf, _cyl(0.04, 0.04, 1.4), Color(0.4, 0.28, 0.16), Vector3(0, 0.7, 0))
	_part(cf, _sph(0.14), Color(0.55, 0.4, 0.28), Vector3(0, 1.5, 0))
	var plumes: Node3D = Node3D.new()
	cf.add_child(plumes)
	for k2 in range(9):
		var a: float = -1.1 + k2 * 0.275
		_part(plumes, _boxm(Vector3(0.05, 0.5, 0.01)), [Color(0.85, 0.15, 0.1), Color(0.1, 0.55, 0.3), Color(0.95, 0.75, 0.15)][k2 % 3], Vector3(sin(a) * 0.18, 1.75 + cos(a) * 0.1, -0.05), Vector3.ONE, Vector3(0, 0, -a))
	R.tapis(0.0, 0.4, 0, 2.2, 1.6)
	S._murs(M, 2)
	var f: Node = M.person(str(_pick(M, ["homme", "femme", "vieux"])), 0.0, -hd + 1.6, 180, "bricoler")
	f.lines = ["Encore une plume…", "Le quetzal, c'est la plus précieuse.", "Cette coiffe sera magnifique !"]
	var cb := func() -> void:
		var ch: Array = []
		for p in PLUMES:
			ch.append({"id": str(p[0]), "label": "La plume " + str(p[1])})
		M.talk(f, "Je fais une coiffe pour la fête du Soleil ! Il me manque la dernière plume, celle du milieu. Laquelle choisirais-tu ?", ch, func(id):
			var nom: String = ""
			for p2 in PLUMES:
				if str(p2[0]) == id:
					nom = str(p2[1])
			var mid := MeshInstance3D.new()
			mid.mesh = _boxm(Vector3(0.06, 0.65, 0.01))
			var m := StandardMaterial3D.new()
			m.albedo_color = (M.R.mat("tissu_" + id) as StandardMaterial3D).albedo_color
			mid.material_override = m
			plumes.add_child(mid)
			mid.position = Vector3(0, 1.95, -0.04)
			f.gesture("joie", 2.0)
			var first: bool = not bool(M.state().get("plume", false))
			M.state()["plume"] = true
			M.talk(f, "Une plume %s ! Parfait ! La coiffe est finie ! Le grand prêtre va être jaloux." % nom + (" Tiens, garde celle-là en souvenir." if first else ""), _bye("Elle est magnifique !"), func(_i):
				if first:
					M.give([["plume_ara", 1]], "")
				M.close_talk())
		, "inspiré")
	M.talk_spot(f, cb)
	M.ctx["entree"] = "Des plumes de toutes les couleurs, partout ! Sur un mannequin, une coiffe magnifique attend sa dernière plume."


# =================================================================== Port-Azur : le peintre

static func _peintre(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# le chevalet
	var ex: float = 0.3
	var ez: float = -hd + 1.4
	var ev: Node3D = _node(M, R.P(ex, 0, ez), 160)
	for sx in [-1.0, 1.0]:
		_part(ev, _boxm(Vector3(0.04, 1.6, 0.04)), Color(0.45, 0.32, 0.2), Vector3(sx * 0.3, 0.8, 0), Vector3.ONE, Vector3(0.15, 0, 0))
	_part(ev, _boxm(Vector3(0.04, 1.5, 0.04)), Color(0.45, 0.32, 0.2), Vector3(0, 0.75, -0.3), Vector3.ONE, Vector3(-0.3, 0, 0))
	var toile: MeshInstance3D = _part(ev, _boxm(Vector3(0.8, 0.6, 0.02)), Color(0.96, 0.95, 0.9), Vector3(0, 1.25, 0.1), Vector3.ONE, Vector3(0.15, 0, 0))
	R.tabouret(-0.8, 0.6)
	R.tapis(0.0, 0.4, 0, 2.4, 1.6)
	for k in range(5):
		R.tableau(-hw + 0.02 if k < 2 else hw - 0.02, 1.4 + (k % 2) * 0.6, -hd * 0.4 + (k % 3) * 0.8, 90 if k < 2 else -90, 0.7, 0.55)
	R.etagere_murale(-R.W * 0.15, 1.6, -hd + 0.15, 0, 1.4, "terre_cuite", 6)
	var f: Node = M.person(str(_pick(M, ["homme", "femme", "vieux"])), ex + 0.4, ez + 0.5, -150, "peindre")
	f.lines = ["Ne bouge pas !", "La lumière est parfaite…", "Un génie au travail !"]
	var cb := func() -> void:
		M.talk(f, "Ah ! Un modèle ! Ne bouge plus ! Tu veux bien poser pour moi ? Choisis ta pose !",
			[{"id": "heros", "label": "La pose du héros (poing sur la hanche)"}, {"id": "penseur", "label": "La pose du penseur"}, {"id": "grimace", "label": "Une grimace !"}, {"id": "fermer", "label": "Non, je suis timide."}], func(id):
			if id == "fermer":
				M.close_talk()
				return
			var dj: Node = M.main.get("donjon_v35")
			M.close_talk()
			if dj != null:
				await dj._fade_to(1.0, 0.35)
			var c: Color = {"heros": Color(0.85, 0.55, 0.3), "penseur": Color(0.4, 0.5, 0.75), "grimace": Color(0.55, 0.8, 0.35)}.get(id, Color.WHITE)
			(toile.material_override as StandardMaterial3D).albedo_color = c
			if dj != null:
				await M.get_tree().create_timer(0.6).timeout
				await dj._fade_to(0.0, 0.4)
			if not M.inside:
				return
			var txt := {"heros": "Voilà ! Héroïque ! Bon, je t'ai fait un peu plus grand. Et avec une cape. Tu n'avais pas de cape ? Maintenant si.",
				"penseur": "Magnifique ! Tu as l'air de réfléchir à quelque chose de très important. À quoi pensais-tu ? … Au goûter ? Parfait.",
				"grimace": "HA HA ! C'est mon chef-d'œuvre ! Je l'appellerai « Le visiteur qui a mangé un citron »."}
			var first: bool = not bool(M.state().get("portrait", false))
			M.state()["portrait"] = true
			M.talk(f, str(txt.get(id, "Voilà !")) + (" Tiens, une petite carte de ton portrait, en souvenir !" if first else ""), _bye("Merci, maître !"), func(_i):
				if first:
					M.give([["carte_postale", 1]], "")
				M.close_talk())
		, "inspiré")
	M.talk_spot(f, cb)
	M.ctx["entree"] = "Ça sent la peinture à l'huile. Des toiles partout, et un artiste qui te regarde en plissant les yeux : « Toi ! Tu as une tête intéressante ! »"


# =================================================================== les elfes : la chanteuse et les plantes

static func _chant_elfe(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.tapis(0.0, 0.0, 0, 2.6, 2.0)
	R.foyer(hw - 0.7, -hd + 0.7, -30, true)
	R.lit(-hw + 0.7, -hd * 0.2, 90, 1.0, "vert")
	S._murs(M, 2)
	var pots: Array = []
	for k in range(5):
		var a: float = PI * (0.15 + 0.7 * k / 4.0)
		var px: float = cos(a) * 1.3
		var pz: float = -0.2 - sin(a) * 1.0
		R.kit.cyl(R.L(px, 0, pz), 0.14, 0.18, 0.26, "terre_cuite", 12)
		var pl: Node3D = R.movable(func(): R.plante(px, pz, 0.0, 1.0))
		pl.set_meta("base", R.P(px, 0.26, pz))
		_grow(pl, Vector3(1, 0.25, 1))
		pots.append(pl)
	var f: Node = M.person(str(_pick(M, ["femme", "vieille", "homme"])), 0.0, 0.6, 180, "debout")
	f.lines = ["♪ Lá… lalá… ♪", "♪ Pousse, petite pousse… ♪", "Les plantes aiment la musique."]
	f.line_every = Vector2(4.0, 6.0)
	var grandir := func() -> void:
		for i in range(pots.size()):
			var n: Node3D = pots[i]
			var tw: Tween = M.room.create_tween()
			tw.tween_interval(i * 0.3)
			tw.tween_method(func(k: float): _grow(n, Vector3(1, 0.25, 1).lerp(Vector3(1.3, 1.8, 1.3), k)), 0.0, 1.0, 1.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if bool(M.state().get("chant", false)):
		for n2 in pots:
			_grow(n2, Vector3(1.3, 1.8, 1.3))
	var cb := func() -> void:
		M.talk(f, "Mae govannen, voyageur. Chez nous, les plantes poussent quand on leur chante. Tu veux chanter avec moi ?",
			[{"id": "chanter", "label": "♪ Chanter avec elle ♪"}, {"id": "siffler", "label": "Je ne sais que siffler…"}, {"id": "fermer", "label": "Une autre fois."}], func(id):
			if id == "fermer":
				M.close_talk()
				return
			M.main.sfx("cristal_chante")
			grandir.call()
			var first: bool = not bool(M.state().get("chant", false))
			M.state()["chant"] = true
			M.talk(f, ("Regarde ! Elles poussent ! Tu as une jolie voix… pour un humain." if id == "chanter" else "Ça marche aussi ! Les plantes aiment toutes les musiques. Même les sifflements un peu faux.") + (" Prends ce thé de lune, il vient de mon jardin." if first else ""), _bye("Merci !"), func(_i):
				if first:
					M.give([["tisane_lune", 1], ["baies", 2]], "")
				M.close_talk())
		, "serein")
	M.talk_spot(f, cb)
	M.ctx["entree"] = "Une maison ronde, toute en bois clair, au parfum de fleurs. Une elfe fredonne doucement à des petites pousses dans leurs pots."


# =================================================================== les Atlantes : la maison-aquarium

static func _aquarium(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	R.tapis(0.0, 0.0, 0, 2.6, 1.8)
	R.canape(hw - 0.6, 0.0, -90, "turquoise")
	R.table_ronde(-0.6, -0.4, 0.5)
	S._murs(M, 3)
	# des poissons qui nagent dans l'air (l'eau est retenue par un sort de bulle)
	var cols: Array = [Color(1.0, 0.5, 0.1), Color(0.2, 0.7, 1.0), Color(1.0, 0.85, 0.2), Color(0.9, 0.3, 0.6), Color(0.4, 1.0, 0.7)]
	for k in range(9):
		var piv: Node3D = _node(M, R.P(r.randf_range(-1.0, 1.0), 0.0, r.randf_range(-1.0, 0.8)))
		var fish := Node3D.new()
		piv.add_child(fish)
		var rad: float = r.randf_range(0.6, 1.6)
		fish.position = Vector3(rad, r.randf_range(1.0, 2.2), 0)
		var c: Color = cols[k % cols.size()]
		_part(fish, _sph(0.06), c, Vector3.ZERO, Vector3(0.6, 1.0, 1.6), Vector3.ZERO, 0.4)
		_part(fish, _cyl(0.0, 0.06, 0.08, 6), c, Vector3(0, 0, -0.12), Vector3(0.3, 1, 1), Vector3(-PI * 0.5, 0, 0), 0.4)
		var tw: Tween = M.room.create_tween().set_loops()
		var dur: float = r.randf_range(5.0, 9.0)
		tw.tween_property(piv, "rotation:y", piv.rotation.y + TAU * (1.0 if k % 2 == 0 else -1.0), dur)
		if k % 2 == 1:
			fish.rotation.y = PI
	var bub := CPUParticles3D.new()
	bub.amount = 30
	bub.lifetime = 4.0
	bub.preprocess = 4.0
	bub.direction = Vector3.UP
	bub.spread = 10.0
	bub.initial_velocity_min = 0.2
	bub.initial_velocity_max = 0.4
	bub.gravity = Vector3.ZERO
	bub.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	bub.emission_box_extents = Vector3(R.W * 0.4, 0.1, R.D * 0.4)
	var q := SphereMesh.new()
	q.radius = 0.03
	q.height = 0.06
	var qm := StandardMaterial3D.new()
	qm.albedo_color = Color(0.8, 0.95, 1.0, 0.5)
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = qm
	bub.mesh = q
	M.room.add_child(bub)
	bub.global_position = R.P(0, 0.1, 0)
	var f: Node = M.person(str(_pick(M, ["femme", "homme", "vieux"])), -0.6, 0.4, 180, "debout")
	f.lines = ["Ils sont beaux, mes poissons ?", "Attention, ne marche pas sur Bulle !", "Glou glou…"]
	var cb := func() -> void:
		M.talk(f, "Bienvenue ! Chez nous, les poissons nagent dans toute la maison : c'est plus gai. Tu veux les nourrir ?",
			[{"id": "nourrir", "label": "Oui, nourrir les poissons !"}, {"id": "comment", "label": "Mais… comment ils respirent ?"}, {"id": "fermer", "label": "Au revoir !"}], func(id):
			match id:
				"nourrir":
					M.main.sfx("bulles")
					var first: bool = not bool(M.state().get("poissons", false))
					M.state()["poissons"] = true
					M.talk(f, "Regarde-les se bousculer ! Le gros orange, c'est Amiral : il mange toujours en premier. Merci ! Tiens, une perle de mon jardin." if first else "Ils te reconnaissent ! Amiral te fait un clin d'œil. Enfin, je crois.", _bye("Ils sont adorables !"), func(_i):
						if first:
							M.give([["perle", 1]], "")
						M.close_talk())
				"comment":
					M.talk(f, "Un petit sort de bulle : l'air de la maison est un peu mouillé, juste assez pour eux. Toi, tu ne sens rien. Sauf peut-être un peu d'humidité dans les cheveux.", _bye("Ah, d'accord !"), _close(M))
				_:
					M.close_talk()
		, "serein")
	M.talk_spot(f, cb)
	M.ctx["entree"] = "Des poissons de toutes les couleurs nagent… dans l'air du salon ! Des bulles montent doucement du sol."


# =================================================================== chez une fée

static func _fee(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var owner: Node = M.ctx.get("owner_node", null)
	var nom: String = str(owner.get("display_name")) if owner != null and is_instance_valid(owner) else "la fée"
	# un lit-pétale, des dés à coudre en tabourets, une tasse-gland, des gouttes de rosée qui brillent
	for k in range(6):
		var a: float = TAU * k / 6.0
		R.kit.box(R.L(-hw + 1.0 + cos(a) * 0.45, 0.2, -hd * 0.25 + sin(a) * 0.45, -rad_to_deg(a)), Vector3(0.7, 0.05, 0.4), "tissu_rose", 1.0)
	R.kit.cyl(R.L(-hw + 1.0, 0, -hd * 0.25), 0.25, 0.3, 0.2, "feuillage", 12)
	for k2 in range(3):
		R.kit.cyl(R.L(0.4 + k2 * 0.6, 0, 0.4), 0.22, 0.18, 0.4, ["tissu_rose", "tissu_jaune", "tissu_turquoise"][k2], 14)
	R.kit.cyl(R.L(1.0, 0, -0.3), 0.3, 0.25, 0.45, "bois_clair", 14)
	R.kit.cyl(R.L(1.0, 0.45, -0.3), 0.31, 0.31, 0.03, "bois_sombre", 14)
	for k3 in range(7):
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.08
		sm.height = 0.16
		mi.mesh = sm
		mi.material_override = R.mat("cristal")
		M.room.add_child(mi)
		mi.global_position = R.P(hw - 0.3, 0.5 + k3 * 0.22, -hd + 0.5 + (k3 % 3) * 0.3)
	R.tapis(0.0, 0.2, 0, 2.2, 1.6)
	S._murs(M, 2)
	R.poussiere(80)
	var mot: String = str(_pick(M, ["« Partie danser sur la place. Si tu as faim, il y a du nectar dans la tasse-gland. Ne touche pas aux gouttes de rosée : elles chatouillent. — %s »" % nom,
		"« Chère personne-géante : bienvenue chez moi ! Oui, c'est petit. Non, ce n'est pas une maison de poupée. Bisous scintillants, %s »" % nom,
		"« Je suis à la cascade de lumière. Si c'est encore toi, Grommelot : rends-moi mon dé à coudre ! — %s »" % nom]))
	S._mot(M, 1.0, -0.3, 0.48, mot, "E : lire le petit mot (écrit tout petit)")
	M.chest(hw - 1.2, hd * 0.25, -60, [["poussiere_fee", 1], ["nectar_fee", 1], ["piece", 5 + r.randi() % 6]], "coffre_fee", "E : ouvrir le coffret de la fée")
	M.ctx["entree"] = "Tu entres chez %s… La maison semble s'agrandir autour de toi, par magie. Tout scintille, et ça sent le miel et les fleurs." % nom
