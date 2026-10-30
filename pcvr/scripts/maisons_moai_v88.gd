extends RefCounted
## V88 : les maisons des petits Moaïs, dans le ventre des Moaïs de la ronde du Plateau des Anciens
## (Île aux Moaïs). Chaque porte a son histoire (moai_v87 la donne à la porte : « histoire ») :
##  - grimaces : le grand concours de grimaces… où tout le monde a la même tête ;
##  - blagues : le cabaret des cailloux, son comique, son public (et on peut raconter la sienne) ;
##  - statues : « 1, 2, 3, Moaï ! » : ils avancent quand on ne les regarde pas ;
##  - sieste : le dormeur de huit cents ans (une conque pour le réveiller) ;
##  - four : le four de terre, et ce qu'il y a dedans ;
##  - cache : cache-cache sous les rochers ;
##  - chorale : la chorale des pierres chantantes (on la dirige) ;
##  - mer : le petit Moaï qui n'a jamais vu la mer (tous les Moaïs regardent l'intérieur de l'île) ;
##  - doyenne : la doyenne raconte la légende du Grand Moaï et de ses yeux perdus (V89).
## M : maisons_v81 ; S : maisons_scenes_v81 ; I : maisons_iles_v82 ; les habitants sont des petits
## Moaïs (pnj/mini_moai_v88.gd : maisons_v81.person les fait naître dans le style « moai »).

const S = preload("res://scripts/maisons_scenes_v81.gd")
const I = preload("res://scripts/maisons_iles_v82.gd")
const Statue = preload("res://scripts/moai_statue_v87.gd")

const HISTOIRES := ["grimaces", "blagues", "statues", "sieste", "four", "cache", "chorale", "mer", "doyenne"]

## Les blagues des petits Moaïs (le cabaret, les promeneurs du plateau).
const BLAGUES := [
	["Pourquoi les Moaïs ont-ils de si grandes oreilles ?", "Pour entendre la mer… même quand ils lui tournent le dos !"],
	["Comment appelle-t-on un Moaï qui danse ?", "Un rock !"],
	["Pourquoi les Moaïs n'ont-ils jamais froid ?", "Parce qu'ils sont en pierre… polaire !"],
	["Quel est le jeu préféré des Moaïs ?", "Caillou-papier-ciseaux. Ils jouent toujours caillou. Ils gagnent une fois sur trois."],
	["Comment un Moaï dit-il bonjour ?", "Il hoche la tête. Ça prend trois semaines."],
	["Pourquoi le Grand Moaï ne joue-t-il jamais à cache-cache ?", "Trente mètres de haut : il se cache derrière quoi ?"],
	["Qu'est-ce qu'un Moaï met sur ses frites ?", "Du sel… de roche !"],
	["Quel est le métier préféré des petits Moaïs ?", "Rock star !"],
	["Pourquoi les Moaïs regardent-ils toujours l'intérieur de l'île ?", "Parce que la mer, ils l'ont déjà vue. Une fois. En 1342. Elle était mouillée."],
	["Que dit un caillou à un autre caillou ?", "Rien. Ils sont de pierre, ils parlent avec leurs… roches. Euh. Leurs proches. Bon."],
]

static func has(sc: String) -> bool:
	return sc in HISTOIRES


static func build(M, sc: String) -> void:
	match sc:
		"grimaces":
			_grimaces(M)
		"blagues":
			_blagues(M)
		"statues":
			_statues(M)
		"sieste":
			_sieste(M)
		"four":
			_four(M)
		"cache":
			_cache(M)
		"chorale":
			_chorale(M)
		"mer":
			_mer(M)
		"doyenne":
			_doyenne(M)


static func _r(M) -> RandomNumberGenerator:
	return M.ctx["rng"]


static func _pick(M, a: Array) -> Variant:
	return a[_r(M).randi() % a.size()]


static func _ile(M) -> Node:
	return M.main.get("moai_v87")


## Une blague entendue (pour l'épreuve des cinq blagues).
static func _rire(M) -> void:
	var mo: Node = _ile(M)
	if mo != null:
		mo.state["toc"] = int(mo.state.get("toc", 0)) + 1


static func _nom(M, used: Array) -> String:
	var Mini = load("res://scripts/pnj/mini_moai_v88.gd")
	for k in range(20):
		var n: String = str(Mini.NOMS[_r(M).randi() % Mini.NOMS.size()])
		if not (n in used):
			used.append(n)
			return n
	return "Caillou"


static func _moai(M, used: Array, x: float, z: float, yaw: float, pose: String = "debout", opts: Dictionary = {}) -> Node:
	return M.person_moai(_nom(M, used), x, z, yaw, pose, opts)


## Des nattes et des calebasses : le mobilier des petits Moaïs.
static func _natte(M, x: float, z: float, yaw: float, w: float, d: float, c: String = "creme") -> void:
	var R = M.R
	R.kit.box(R.L(x, 0.012, z, yaw), Vector3(w, 0.02, d), "tissu_" + c, 1.0)
	for k in range(int(w / 0.12)):
		R.kit.box(R.L(x - w * 0.5 + 0.06 + k * 0.12, 0.024, z, yaw), Vector3(0.02, 0.004, d * 0.96), "tissu_brun", 1.0)


static func _calebasse(M, x: float, z: float, s: float = 1.0) -> void:
	var R = M.R
	R.kit.cyl(R.L(x, 0, z), 0.09 * s, 0.14 * s, 0.14 * s, "terre_cuite", 12)
	R.kit.cyl(R.L(x, 0.14 * s, z), 0.14 * s, 0.05 * s, 0.14 * s, "terre_cuite", 12)
	R.kit.cyl(R.L(x, 0.28 * s, z), 0.035 * s, 0.03 * s, 0.1 * s, "bois_sombre", 8)


# =================================================================== le concours de grimaces

static func _grimaces(M) -> void:
	var R = M.R
	var hd: float = R.D * 0.5
	var used: Array = []
	S._murs(M, 2)
	_natte(M, 0.0, -hd * 0.3, 0, 3.2, 1.4, "jaune")
	R.etagere_murale(0.0, 1.5, -hd + 0.15, 0, 1.4, "or", 3)
	var juges: Array = []
	for i in range(3):
		var m: Node = _moai(M, used, -1.1 + i * 1.1, -hd * 0.3, 0, "debout", {"parure": ["fleurs", "lunettes", "feuilles"][i]})
		m.lines = ["Grrr !", "Bouh !", "Regarde-moi CETTE tête !", "Hi hi !"]
		juges.append(m)
	var mid: Node = juges[1]
	var cb := func() -> void:
		M.talk(mid, "Bienvenue au Grand Concours de Grimaces ! Regarde bien, on y va : un, deux, trois… GRIMACE ! … (Ils font tous les trois… exactement la même tête. La même que d'habitude.) Alors ? Qui a gagné ?",
			[{"id": "0", "label": str(juges[0].display_name) + " !"}, {"id": "2", "label": str(juges[2].display_name) + " !"}, {"id": "meme", "label": "Vous avez tous la même tête…"}], func(id):
			_rire(M)
			if id == "meme":
				for j in juges:
					j.gesture("rire", 2.5)
				M.talk(mid, "HA HA HA ! Tu as remarqué ! On fait ce concours depuis mille ans, et c'est égalité à chaque fois. Tiens, tu as l'œil : une médaille de coquillage !", I._bye("Merci !"), func(_i):
					if not bool(M.state().get("medaille", false)):
						M.state()["medaille"] = true
						M.give([["coquillage", 2], ["piece", 8]], "")
					M.close_talk())
			else:
				var w: Node = juges[int(id)]
				w.gesture("joie", 2.0)
				for j2 in juges:
					if j2 != w:
						j2.gesture("colere", 1.5)
				S._say_late(M, juges[0] if w != juges[0] else juges[2], "Hmpf. … C'était pourtant ma plus belle grimace.", 2.0, 3.5)
				M.talk(mid, "Le jury a parlé ! " + str(w.display_name) + " gagne… la même tête que d'habitude ! Bravo !", I._bye("Bravo !"), I._close(M))
		, "de bonne humeur")
	M.talk_spot(mid, cb)
	M.ctx["entree"] = str(_pick(M, ["Trois petits Moaïs, alignés, très concentrés, font une grimace. Enfin… ils essaient.", "« UN, DEUX, TROIS : GRIMACE ! » Rien ne change sur leurs visages de pierre. Ils ont l'air très fiers.", "Une pancarte gravée : « GRAND CONCOURS DE GRIMACES — 1 147e édition »."]))


# =================================================================== le cabaret des cailloux

static func _blagues(M) -> void:
	var R = M.R
	var hd: float = R.D * 0.5
	var used: Array = []
	# la scène : une estrade de bois, et un rideau
	R.kit.box(R.L(0, 0.15, -hd + 0.9), Vector3(2.6, 0.3, 1.5), "bois", 1.0)
	R.kit.col_box(R.L(0, 0.15, -hd + 0.9), Vector3(2.6, 0.3, 1.5))
	R.reserve(0, -hd + 0.9, 2.8, 1.7)
	for sx in [-1.0, 1.0]:
		R.kit.box(R.L(sx * 1.4, 1.2, -hd + 0.35), Vector3(0.5, 2.4, 0.06), "tissu_rouge", 1.0)
	R.kit.box(R.L(0, 2.4, -hd + 0.35), Vector3(3.3, 0.3, 0.08), "tissu_rouge", 1.0)
	var comique: Node = M.person_moai(_nom(M, used), 0.0, -hd + 0.95, 0, "debout", {"parure": "lunettes", "h": 1.05})
	comique.npc.global_position.y += 0.3
	comique.lines = ["Elle est bonne, celle-là !", "Attendez, j'en ai une autre !", "Silence dans la salle !"]
	var public: Array = []
	for i in range(5):
		var x: float = -1.6 + i * 0.8
		var p: Node = _moai(M, used, x, -hd + 2.6 + (i % 2) * 0.5, 180, "assis")
		p.lines = ["Hi hi !", "Une autre !", "Ha ha !"]
		public.append(p)
	var tour: Array = [0]
	var raconte := func() -> void:
		var b: Array = BLAGUES[(tour[0] + _r(M).randi()) % BLAGUES.size()]
		tour[0] += 1
		_rire(M)
		comique.gesture("salut", 1.0)
		await M.get_tree().create_timer(2.0).timeout
		for p2 in public:
			if is_instance_valid(p2):
				p2.gesture("rire", 2.5)
				p2.say(str(_pick(M, ["HA HA HA !", "Hi hi hi !", "Ho ho !", "J'ai mal aux joues !"])), 2.5)
	var cb := func() -> void:
		var b2: Array = BLAGUES[tour[0] % BLAGUES.size()]
		M.talk(comique, "Bienvenue au Cabaret des Cailloux ! Tiens, écoute celle-là : " + str(b2[0]) + " … " + str(b2[1]),
			[{"id": "encore", "label": "Encore une !"}, {"id": "moi", "label": "Je peux en raconter une ?"}, {"id": "fermer", "label": "(Applaudir et partir)"}], func(id):
			match id:
				"encore":
					M.close_talk()
					raconte.call()
				"moi":
					var ch: Array = []
					var picks: Array = S.BLAGUES.duplicate()
					picks.shuffle()
					for k in range(3):
						ch.append({"id": "b:" + str(S.BLAGUES.find(picks[k])), "label": str(picks[k][0])})
					M.talk(comique, "Toi ?! Sur MA scène ? … D'accord. Vas-y, le public est chaud. Enfin, tiède. Enfin, il est en pierre.", ch, func(id2):
						var bb: Array = S.BLAGUES[int(str(id2).substr(2))]
						M.close_talk()
						M.say("Tu racontes : « " + str(bb[0]) + " … " + str(bb[1]) + " »", 6.0)
						_rire(M)
						await M.get_tree().create_timer(2.5).timeout
						for p3 in public:
							if is_instance_valid(p3):
								p3.gesture("joie", 2.0)
								p3.say("HA HA HA HA !", 3.0)
						comique.gesture("colere", 2.0)
						comique.say("… Elle est meilleure que les miennes. Je démissionne. (Je plaisante.)", 4.0)
						if not bool(M.state().get("scene", false)):
							M.state()["scene"] = true
							await M.get_tree().create_timer(2.0).timeout
							if M.inside:
								M.give([["piece", 10], ["coquillage", 1]], "Le public te lance des pièces (et un coquillage). ")
					)
				_:
					M.close_talk()
		, "de bonne humeur")
	M.talk_spot(comique, cb)
	M.ctx["entree"] = str(_pick(M, ["Une petite salle de spectacle : une estrade, un rideau rouge, et un public de petits Moaïs qui attendent en gloussant.", "« Et c'est l'histoire d'un caillou… » Toute la salle éclate de rire avant même la fin.", "Le Cabaret des Cailloux. Ce soir : le plus drôle des petits Moaïs. (C'est lui qui l'a écrit sur l'affiche.)"]))


# =================================================================== « 1, 2, 3, Moaï ! »

static func _statues(M) -> void:
	var R = M.R
	var hd: float = R.D * 0.5
	var hw: float = R.W * 0.5
	var used: Array = []
	S._murs(M, 2)
	var chef: Node = _moai(M, used, -hw + 0.9, 0.0, 90, "debout", {"parure": "chignon", "h": 1.1})
	chef.lines = ["On joue ?", "Je suis imbattable.", "Psst… tu veux jouer ?"]
	var joueurs: Array = []
	var start: Array = []
	for i in range(4):
		var x: float = -1.5 + i * 1.0
		var z: float = -hd + 0.8
		var j: Node = _moai(M, used, x, z, 0, "debout")
		joueurs.append(j)
		start.append(R.P(x, 0, z))
	var jeu := {"on": false, "t": 0.0, "parties": int(M.state().get("parties", 0))}
	var timer := Timer.new()
	timer.wait_time = 0.1
	M.room.add_child(timer)
	var reset := func() -> void:
		for k in range(joueurs.size()):
			if is_instance_valid(joueurs[k]):
				joueurs[k].global_position = start[k]
				joueurs[k].freeze(false)
	var tick := func() -> void:
		if not bool(jeu["on"]) or not M.inside:
			return
		jeu["t"] = float(jeu["t"]) + 0.1
		var cam: Camera3D = M.get_viewport().get_camera_3d()
		var p: Vector3 = M.main._player_pos_v27()
		var fwd: Vector3 = -cam.global_basis.z if cam != null else Vector3.FORWARD
		fwd.y = 0.0
		fwd = fwd.normalized()
		for j2 in joueurs:
			if not is_instance_valid(j2):
				continue
			var to: Vector3 = j2.global_position - p
			to.y = 0.0
			var seen: bool = to.length() > 0.01 and fwd.dot(to.normalized()) > 0.55
			j2.freeze(seen)
			if not seen:
				var step: Vector3 = (p - j2.global_position)
				step.y = 0.0
				if step.length() < 0.85:
					jeu["on"] = false
					timer.stop()
					for j3 in joueurs:
						j3.freeze(false)
						j3.gesture("joie", 2.0)
					chef.say("TOUCHÉ ! Hi hi hi ! On a gagné ! On recommence quand tu veux.", 4.0)
					await M.get_tree().create_timer(2.5).timeout
					reset.call()
					return
				j2.global_position += step.normalized() * 0.09
		if float(jeu["t"]) >= 30.0:
			jeu["on"] = false
			timer.stop()
			for j4 in joueurs:
				j4.freeze(false)
				j4.gesture("colere", 1.5)
			chef.gesture("salut", 2.0)
			chef.say("Trente secondes ! Personne ne t'a touché ! … Tu as des yeux derrière la tête, c'est ça ?", 5.0)
			if not bool(M.state().get("gagne", false)):
				M.state()["gagne"] = true
				M.give([["perle", 1], ["piece", 12]], "Les petits Moaïs, beaux joueurs, te donnent leur trésor. ")
			await M.get_tree().create_timer(3.0).timeout
			reset.call()
	timer.timeout.connect(tick)
	var cb := func() -> void:
		if bool(jeu["on"]):
			return
		M.talk(chef, "On joue à « 1, 2, 3, Moaï » ? C'est simple : quand tu nous regardes, on ne bouge pas. On est des statues, c'est notre métier. Mais quand tu ne regardes pas… on avance ! Si on te touche, on gagne. Si tu tiens trente secondes, tu gagnes.",
			[{"id": "go", "label": "D'accord, on joue !"}, {"id": "fermer", "label": "Une autre fois."}], func(id):
			M.close_talk()
			if id != "go":
				return
			reset.call()
			jeu["t"] = 0.0
			jeu["on"] = true
			M.state()["parties"] = int(M.state().get("parties", 0)) + 1
			M.say("C'est parti ! Garde-les à l'œil… tous les quatre.", 3.0)
			timer.start()
		, "de bonne humeur")
	M.talk_spot(chef, cb)
	M.ctx["entree"] = str(_pick(M, ["Quatre petits Moaïs, immobiles au fond de la pièce. Très immobiles. Trop immobiles.", "Tu as l'impression que les petits Moaïs du fond ont bougé. Mais non. … Si ?", "Un petit Moaï te fait signe : « Psst ! Tu connais “1, 2, 3, Moaï” ? »"]))


# =================================================================== le dormeur de huit cents ans

static func _sieste(M) -> void:
	var R = M.R
	var hd: float = R.D * 0.5
	var hw: float = R.W * 0.5
	var used: Array = []
	S._murs(M, 2)
	_natte(M, -hw + 1.2, -hd + 1.3, 90, 1.4, 2.2, "bleu")
	var d: Node = _moai(M, used, -hw + 1.2, -hd + 1.3, 90, "dormir", {"parure": "fleur_oreille", "h": 1.0})
	d.lines = ["Rrrrr… pfff…", "Zzz… cinq minutes… zzz…", "Rrrr… non, pas les cailloux… rrrr…", "Zzzz…"]
	d.line_every = Vector2(3.0, 6.0)
	R.table_ronde(hw - 1.2, 0.2, 0.4, 0.6)
	var conque: Node3D = I._node(M, R.P(hw - 1.2, 0.6, 0.2), 30)
	I._part(conque, I._cyl(0.0, 0.09, 0.26), Color(0.98, 0.85, 0.75), Vector3(0, 0.08, 0), Vector3(1, 1, 1), Vector3(0, 0, 80))
	I._part(conque, I._sph(0.07), Color(1.0, 0.7, 0.62), Vector3(-0.02, 0.08, 0), Vector3(1, 0.9, 0.9))
	M.act(R.P(hw - 1.2, 0, 0.2), "E : prendre la conque", func() -> void:
		M.state()["conque"] = true
		conque.visible = false
		M.say("Une grosse conque rose. Elle sent la mer. Elle a l'air de pouvoir faire beaucoup, BEAUCOUP de bruit.", 5.0)
	, 1.2, func(): return not bool(M.state().get("conque", false)))
	var cb := func() -> void:
		if bool(M.state().get("reveil", false)):
			M.talk(d, "Ah, c'est toi ! Merci de m'avoir réveillé. J'ai tout raté : la fête de l'an 1300, la fête de l'an 1400… Bon. Je vais faire une petite sieste pour me remettre.", I._bye("Bonne sieste !"), I._close(M), "de bonne humeur")
			return
		var ch: Array = [{"id": "chatouille", "label": "Le chatouiller"}]
		if bool(M.state().get("conque", false)):
			ch.append({"id": "conque", "label": "Souffler dans la conque"})
		ch.append({"id": "fermer", "label": "Le laisser dormir"})
		M.talk(d, "Rrrrrr… pfffff… (Il dort. Profondément. Il y a de la mousse sur son épaule.)", ch, func(id):
			match id:
				"chatouille":
					d.gesture("rire", 2.0)
					M.talk(d, "Hi… hi hi… rrrrr… (Il rit en dormant. Puis il ronfle de plus belle.)", I._bye("Bon…"), I._close(M), "endormi")
				"conque":
					M.close_talk()
					M.main.sfx("cloche")
					M.say("BWOOOOOOOOOOOOOOOOOOOOOOOOOM !", 3.0)
					d.set_pose("debout")
					d.gesture("sursaut", 1.0)
					_rire(M)
					await M.get_tree().create_timer(1.2).timeout
					if not M.inside:
						return
					M.state()["reveil"] = true
					M.talk(d, "QUOI ?! QUI ?! QUELLE ANNÉE ?! … Huit cents ans ?! J'avais dit « juste cinq minutes » ! … Bon. Merci, hein. Tiens, j'ai rêvé de ça toute ma sieste, je te le donne.", I._bye("Bonjour, au fait !"), func(_i):
						M.give([["coquillage", 3], ["piece", 10]], "")
						M.close_talk())
				_:
					M.close_talk()
		, "endormi")
	M.talk_spot(d, cb)
	M.ctx["entree"] = str(_pick(M, ["Ça ronfle. Fort. Sur une natte, un petit Moaï dort, couvert de mousse.", "« Rrrrr… pfff… » La pièce entière vibre doucement au rythme d'un ronflement de pierre.", "Sur la porte, un écriteau : « NE PAS DÉRANGER. (Depuis 1226.) »"]))


# =================================================================== le four de terre

static func _four(M) -> void:
	var R = M.R
	var hd: float = R.D * 0.5
	var used: Array = []
	S._murs(M, 2)
	# le four : un tas de pierres chaudes sous des feuilles de bananier, la fumée qui s'échappe
	var cx: float = 0.6
	var cz: float = -hd + 1.4
	for k in range(14):
		var a: float = TAU * k / 14.0
		R.kit.cyl(R.L(cx + cos(a) * 0.7, 0.0, cz + sin(a) * 0.55, k * 30.0), 0.14, 0.16, 0.18, "pierre", 7)
	for k2 in range(6):
		R.kit.box(R.L(cx, 0.24 + k2 * 0.02, cz, k2 * 30.0), Vector3(1.3, 0.02, 0.36), "feuillage", 1.0)
	R.fire(R.P(cx + 0.75, 0.05, cz + 0.2), 0.5)
	R.reserve(cx, cz, 2.0, 1.6)
	for k3 in range(3):
		_calebasse(M, -R.W * 0.5 + 0.5 + k3 * 0.35, -hd + 0.5, 1.0 + 0.2 * k3)
	var cuisinier: Node = _moai(M, used, cx - 1.3, cz + 0.4, 60, "debout", {"parure": "feuilles"})
	cuisinier.lines = ["Ça cuit, ça cuit…", "Plus que trois heures !", "Mmm, ça sent bon, non ?"]
	var cb := func() -> void:
		M.talk(cuisinier, "Le four de terre ! On creuse, on chauffe les pierres, on enterre, on attend, on déterre. C'est prêt dans trois heures. Ou trois cents ans. Je ne me souviens jamais.",
			[{"id": "gouter", "label": "Je peux goûter ?"}, {"id": "quoi", "label": "Qu'est-ce qu'il y a dedans ?"}, {"id": "fermer", "label": "Bon appétit !"}], func(id):
			match id:
				"gouter":
					if bool(M.state().get("goute", false)):
						M.talk(cuisinier, "Encore ?! Tu as un estomac de Moaï, toi ! … Reviens demain, il faut que ça recuise.", I._bye("D'accord !"), I._close(M))
						return
					M.state()["goute"] = true
					cuisinier.gesture("joie", 1.5)
					M.talk(cuisinier, "Bien sûr ! On déterre, on déterre… Voilà ! Du poisson grillé, de la noix de coco, et… ah non, ça c'est une pierre chaude. Ne la mange pas. Enfin, si tu veux, mais ça craque.", I._bye("Miam !"), func(_i):
						M.give([["brochette_poisson", 2], ["noix_coco", 1]], "")
						M.close_talk())
				"quoi":
					_rire(M)
					M.talk(cuisinier, "Du poisson, des patates douces, des bananes… et la pierre préférée de mon grand-père. Pour le goût. Il dit que c'est le secret. Il est en pierre, alors forcément, il trouve que la pierre, c'est bon.", I._bye("Ha ha !"), I._close(M))
				_:
					M.close_talk()
		, "de bonne humeur")
	M.talk_spot(cuisinier, cb)
	M.ctx["entree"] = str(_pick(M, ["Ça sent le feu de bois, la noix de coco et le poisson grillé. Au fond, un tas de pierres fume doucement.", "Un petit Moaï surveille un tas de feuilles qui fume. « Ne marche pas dessus ! C'est le dîner ! »", "La cuisine des petits Moaïs : un four creusé dans la terre, des calebasses, et beaucoup de patience."]))


# =================================================================== cache-cache sous les rochers

static func _cache(M) -> void:
	var R = M.R
	var hd: float = R.D * 0.5
	var hw: float = R.W * 0.5
	var r := _r(M)
	var used: Array = []
	S._murs(M, 1)
	var meneur: Node = _moai(M, used, R.door_x + 1.0, hd - 1.6, 180, "debout", {"parure": "fleurs"})
	meneur.lines = ["Ils sont bien cachés, hein ?", "Je ne dirai rien !", "Chaud… froid… tiède !"]
	var spots: Array = [[-hw + 1.0, -hd + 1.0], [hw - 1.0, -hd + 1.0], [0.0, -hd + 1.3], [-hw + 1.0, 0.2], [hw - 1.0, 0.2], [-1.2, -0.6], [1.3, -0.4], [0.2, 0.8]]
	var cache: Array = [1, 3, 6] if r.randf() < 0.5 else [0, 4, 5]
	var trouves: Array = [0]
	for i in range(spots.size()):
		var sp: Array = spots[i]
		var at: Vector3 = R.P(float(sp[0]), 0, float(sp[1]))
		var rock: Node3D = I._node(M, at, r.randf_range(0, 360))
		var mi: MeshInstance3D = I._part(rock, I._sph(0.62), Color(1, 1, 1), Vector3(0, 0.2, 0), Vector3(1.2, 0.9, 1.0))
		mi.material_override = Statue.stone_mat("ahu", Color(0.95, 0.92, 0.88))
		R.reserve(float(sp[0]), float(sp[1]), 1.4, 1.2)
		var hidden: Node = null
		if i in cache:
			hidden = _moai(M, used, float(sp[0]), float(sp[1]), 180, "debout", {"h": 0.8})
			hidden.visible = false
		var idx: int = i
		M.act(at, "E : regarder sous ce rocher", func() -> void:
			if bool(rock.get_meta("vu", false)):
				return
			rock.set_meta("vu", true)
			var tw: Tween = M.room.create_tween()
			tw.tween_property(rock, "position", rock.position + Vector3(0.0, 0.9, 0.0), 0.4)
			tw.tween_property(rock, "position", rock.position + R.xf0.basis * Vector3(0.9, 0.0, 0.4), 0.3)
			M.main.sfx("touche_pierre", at)
			if hidden != null:
				hidden.visible = true
				hidden.gesture("sursaut", 0.8)
				hidden.say(str(_pick(M, ["Oh non ! Trouvé !", "Zut ! J'étais si bien caché !", "Comment tu as su ?!"])), 3.0)
				trouves[0] += 1
				if trouves[0] >= 3:
					await M.get_tree().create_timer(1.5).timeout
					meneur.gesture("applaudir", 2.0)
					meneur.say("Tous trouvés ! Tu es le champion du cache-cache !", 4.0)
					_rire(M)
					if not bool(M.state().get("cache_gagne", false)):
						M.state()["cache_gagne"] = true
						M.give([["perle", 1], ["piece", 8]], "")
			else:
				M.say(str(_pick(M, ["Un rocher. Un vrai. Il a l'air un peu vexé qu'on l'ait soulevé.", "Rien ! Juste un ver de terre, qui te regarde d'un air surpris.", "Personne. Mais quelqu'un a laissé un petit mot : « Pas ici ! Hi hi ! »"])), 4.0)
		, 1.2, func(): return not bool(rock.get_meta("vu", false)))
	var cb := func() -> void:
		M.talk(meneur, "Chut ! On joue à cache-cache ! Trois petits Moaïs se sont cachés sous les rochers. Trouve-les ! … Et ne soulève pas les vrais rochers trop fort, ils sont susceptibles.", I._bye("Je les trouve !"), I._close(M), "de bonne humeur")
	M.talk_spot(meneur, cb)
	M.ctx["entree"] = str(_pick(M, ["Une pièce pleine de gros rochers ronds. Un petit Moaï, devant la porte, se retient très fort de rire.", "Des rochers partout. L'un d'eux vient de glousser. Les rochers ne gloussent pas, d'habitude.", "« Ils sont cachés ! Trouve-les ! » chuchote un petit Moaï. Les rochers retiennent leur souffle."]))


# =================================================================== la chorale des pierres chantantes

static func _chorale(M) -> void:
	var R = M.R
	var hd: float = R.D * 0.5
	var used: Array = []
	S._murs(M, 2)
	var chanteurs: Array = []
	for i in range(5):
		var a: float = deg_to_rad(-60.0 + i * 30.0)
		var m: Node = _moai(M, used, sin(a) * 1.8, -hd + 1.6 - cos(a) * 0.6 + 0.6, 0, "debout")
		m.lines = [["Laaa !", "La la laaa !"], ["Dou dou dou !", "Bom… bom…"], ["Lalalala !", "Ouh ouh !"], ["Tralala !", "La… la ?"], ["BOM !", "Bom bom bom !"]][i]
		m.line_every = Vector2(2.0, 4.0)
		chanteurs.append(m)
	R.kit.box(R.L(0.0, 0.55, 0.2), Vector3(0.4, 1.1, 0.3), "bois", 1.0)
	R.kit.box(R.L(0.0, 1.15, 0.12, 0), Vector3(0.5, 0.04, 0.35), "bois_sombre", 1.0)
	var chef: Node = _moai(M, used, 0.0, 0.8, 180, "debout", {"parure": "lunettes"})
	chef.lines = ["Un peu plus juste, s'il vous plaît.", "Et… un, deux…", "Magnifique ! Presque."]
	var cb := func() -> void:
		M.talk(chef, "La Chorale des Pierres Chantantes ! Nous répétons pour la fête de la pleine lune. Tu veux diriger ? Prends la baguette !",
			[{"id": "vite", "label": "Plus vite !"}, {"id": "fort", "label": "Plus fort !"}, {"id": "doux", "label": "Plus doucement…"}, {"id": "fermer", "label": "Bravo !"}], func(id):
			M.close_talk()
			match id:
				"vite":
					for c in chanteurs:
						c.gesture("applaudir", 3.0)
						c.say("Lalalalalalalalala !", 3.0)
					chef.say("TROP vite ! Ils vont se décrocher la mâchoire !", 3.5)
				"fort":
					M.main.sfx("tambour")
					for c2 in chanteurs:
						c2.gesture("rire", 2.0)
						c2.say("LA LA LAAAAAA !", 3.0)
					M.say("Le sol tremble. Quelque part dehors, un oiseau tombe de sa branche, vexé.", 4.0)
				"doux":
					for c3 in chanteurs:
						c3.set_pose("dormir")
						c3.say("La… la… zzz…", 3.0)
					chef.say("… Ils se sont endormis. C'est la troisième fois cette semaine.", 4.0)
					await M.get_tree().create_timer(4.0).timeout
					for c4 in chanteurs:
						if is_instance_valid(c4):
							c4.set_pose("debout")
							c4.gesture("sursaut", 0.8)
			if id != "fermer" and not bool(M.state().get("dirige", false)):
				M.state()["dirige"] = true
				_rire(M)
				await M.get_tree().create_timer(3.5).timeout
				if M.inside:
					M.give([["coquillage", 2], ["piece", 6]], "La chorale te remercie avec ce qu'elle a. ")
		, "de bonne humeur")
	M.talk_spot(chef, cb)
	M.ctx["entree"] = str(_pick(M, ["« La la laaaa ! » Cinq petits Moaïs chantent en demi-cercle. Pas tous la même chanson.", "Une chorale ! Le chef d'orchestre agite une brindille. Les chanteurs font de leur mieux. Leur mieux est très fort.", "Des voix de pierre, graves et rondes, qui font vibrer les murs. C'est beau. Presque."]))


# =================================================================== le petit Moaï qui n'a jamais vu la mer

static func _mer(M) -> void:
	var R = M.R
	var hd: float = R.D * 0.5
	var hw: float = R.W * 0.5
	var used: Array = []
	S._murs(M, 2)
	_natte(M, -hw + 1.0, 0.0, 90, 1.2, 1.8, "turquoise")
	# des dessins de vagues partout (il en rêve)
	for k in range(4):
		R.kit.box(R.L(-hw + 0.03, 1.2 + (k % 2) * 0.5, -hd * 0.5 + k * 0.7, 90), Vector3(0.5, 0.35, 0.01), "papier", 1.0)
		R.kit.box(R.L(-hw + 0.04, 1.2 + (k % 2) * 0.5, -hd * 0.5 + k * 0.7, 90), Vector3(0.4, 0.06, 0.01), "tissu_bleu", 1.0)
	var p: Node = _moai(M, used, -hw + 1.0, 0.0, 90, "debout", {"h": 0.8, "parure": "coquillages"})
	p.follow = false
	p.lines = ["Tu crois qu'elle est grande, la mer ?", "Paraît qu'elle est bleue…", "Et salée ! Comme les larmes. Mais en plus grand."]
	var cb := func() -> void:
		if bool(M.state().get("vu_mer", false)):
			M.talk(p, "Je la vois ! Elle est toujours là ! Elle bouge tout le temps ! Elle ne fatigue jamais ? … Merci, ami. Merci.", I._bye("Elle est belle, hein ?"), I._close(M), "rayonnant")
			return
		M.talk(p, "Tu sais, tous les Moaïs regardent l'intérieur de l'île. C'est la tradition. Alors moi… je n'ai jamais vu la mer. Jamais. Pas une seule fois. On dit qu'elle est grande, et bleue, et qu'elle chante.",
			[{"id": "tourner", "label": "Viens, je te retourne vers la fenêtre !"}, {"id": "raconte", "label": "Je te la raconte : elle est immense…"}, {"id": "fermer", "label": "Un jour, tu la verras."}], func(id):
			match id:
				"tourner":
					M.close_talk()
					M.state()["vu_mer"] = true
					var tw: Tween = M.room.create_tween()
					tw.tween_property(p, "rotation:y", p.rotation.y + PI, 1.5).set_trans(Tween.TRANS_SINE)
					p.face_dir = -p.face_dir
					await M.get_tree().create_timer(1.8).timeout
					if not M.inside:
						return
					p.gesture("joie", 2.5)
					p.say("OH ! … C'est… c'est BLEU ! C'est TRÈS bleu ! Et ça bouge ! Elle me fait coucou !", 5.0)
					await M.get_tree().create_timer(3.0).timeout
					if M.inside:
						M.give([["perle", 1]], "Les yeux de pierre brillent. « Tiens. Je l'ai trouvée dans mon rêve. C'est pour toi. » ")
				"raconte":
					p.gesture("rire", 1.5)
					M.talk(p, "Immense ? Plus grande que le Grand Moaï ? … PLUS GRANDE ?! … Je ne te crois pas. Si ? Oh là là. Oh là là là.", I._bye("Promis."), I._close(M), "rêveur")
				_:
					M.close_talk()
		, "rêveur")
	M.talk_spot(p, cb)
	M.ctx["entree"] = str(_pick(M, ["Des dessins de vagues sur tous les murs. Au milieu, un tout petit Moaï regarde le mur, très sérieux.", "« Tu l'as vue, toi, la mer ? » demande une toute petite voix de pierre.", "Une petite pièce pleine de coquillages. Celui qui les collectionne n'a jamais vu la plage."]))


# =================================================================== la doyenne et la légende

static func _legende(M, d: Node, petits: Array) -> void:
	M.talk(d, "Il y a très, très longtemps, le Grand Moaï avait des yeux. Deux yeux de corail blanc qui voyaient tout : le ciel, la mer, et ce qui chante sous la terre. Sous lui, un escalier descend vers la Salle du Chant, où dort la mémoire de l'île.",
		[{"id": "suite", "label": "Et ensuite ?"}], func(_i): _legende2(M, d, petits), "mystérieux")


static func _legende2(M, d: Node, petits: Array) -> void:
	M.talk(d, "Un jour de grand vent, ses yeux sont tombés. L'un a roulé dans l'eau qui regarde le ciel. L'autre s'est caché sous les têtes qui regardent les nuages. Depuis, sa porte est fermée. Le jour où quelqu'un lui rendra ses yeux… il ouvrira son ventre de pierre. Voilà.",
		[{"id": "comprendre", "label": "« L'eau qui regarde le ciel »… le lac du cratère ?"}, {"id": "fin", "label": "Merci, Mamie."}], func(id3): _legende3(M, d, petits, str(id3)), "mystérieux")


static func _legende3(M, d: Node, petits: Array, id3: String) -> void:
	var mo: Node = _ile(M)
	if mo != null:
		mo.state["legende"] = true
	for pm2 in petits:
		if is_instance_valid(pm2):
			pm2.set_pose("dormir")
	if id3 == "comprendre":
		M.talk(d, "Hm hm. Tu es plus malin que mes petits-enfants. … Regarde : ils dorment tous. Comme d'habitude. Va, voyageur. Et si tu trouves les yeux… le Grand Moaï t'attend.", I._bye("J'y vais !"), I._close(M), "rayonnant")
	else:
		M.close_talk()
		M.say("La légende des yeux du Grand Moaï : un œil dans « l'eau qui regarde le ciel », l'autre « sous les têtes qui regardent les nuages ».", 7.0)


static func _doyenne(M) -> void:
	var R = M.R
	var hd: float = R.D * 0.5
	var used: Array = []
	S._murs(M, 3)
	_natte(M, 0.0, -hd + 1.4, 0, 2.2, 1.6, "rouge")
	R.foyer(R.W * 0.25, -hd + 0.5, 0, true)
	for k in range(4):
		_calebasse(M, -R.W * 0.5 + 0.5, -hd + 0.6 + k * 0.4, 0.8 + 0.1 * k)
	var d: Node = M.person_moai("Mamie Basalte", 0.0, -hd + 1.4, 0, "assis", {"h": 1.25, "v": 2, "parure": "chignon"})
	d.lines = ["Approche, approche…", "Hmm, ce n'était pas hier, ça…", "Les jeunes Moaïs ne savent plus rien."]
	var petits: Array = []
	for i in range(3):
		var pm: Node = _moai(M, used, -0.9 + i * 0.9, -hd + 2.6, 180, "assis", {"h": 0.75})
		pm.lines = ["Encore la légende !", "Raconte, Mamie !", "Chut, c'est le meilleur moment !"]
		petits.append(pm)
	var cb := func() -> void:
		M.talk(d, "Ah ! Un visiteur aux pieds pas en pierre. Assieds-toi. Tu veux connaître la légende du Grand Moaï ? Tout le monde la connaît, ici. Mais personne ne l'écoute jusqu'au bout. Ils s'endorment tous.",
			[{"id": "legende", "label": "Racontez-moi la légende."}, {"id": "age", "label": "Vous avez quel âge ?"}, {"id": "fermer", "label": "Une autre fois, Mamie."}], func(id):
			match id:
				"legende":
					_legende(M, d, petits)
				"age":
					_rire(M)
					d.gesture("rire", 2.0)
					M.talk(d, "Quel âge ?! On ne demande pas son âge à une dame de pierre ! … Mille deux cent quarante ans. Et demi. Mais j'en parais mille, non ?", I._bye("Pas plus de neuf cents !"), I._close(M), "flatté")
				_:
					M.close_talk()
		, "de bonne humeur")
	M.talk_spot(d, cb)
	M.ctx["entree"] = str(_pick(M, ["Près du feu, une vieille Moaï couverte de lichen. Autour d'elle, trois tout petits Moaïs attendent une histoire.", "Ça sent la fumée et le vieux bois. « Approche, voyageur », dit une voix de pierre, lente et douce.", "La maison de la doyenne : des calebasses, des nattes, et des gravures partout sur les murs."]))
