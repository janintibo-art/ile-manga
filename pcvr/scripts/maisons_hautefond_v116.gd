extends RefCounted
## V116 : les histoires des maisons de Hautefond, la ville-colonne « fantastique-vapeur » (maisons_v81 ;
## style « hautefond » : parquet à chevrons, papier peint damassé, lambris sombre, poutres de fer,
## tuyaux de cuivre, un poêle). En plus des histoires communes (maisons_scenes_v81), sept histoires à
## elles : la famille de liftiers et sa maquette d'ascenseur, la maison aux cent coucous, l'aéronaute
## et son dirigeable miniature, le petit-déjeuner à vapeur qui s'emballe, la Grande Colonne en
## allumettes, la poste pneumatique, et le piano mécanique qui fait danser la grand-mère.
## Chaque histoire : ses meubles, ses gens, ce qui bouge (un seul M.ctx["tick"] par maison), ce qu'on
## y fait, et ce dont la maison se souvient (M.state() : une récompense une seule fois).
## M : maisons_v81 ; S : maisons_scenes_v81 (les aides communes) ; I : maisons_iles_v82 (_part, _node…).

const S = preload("res://scripts/maisons_scenes_v81.gd")
const I = preload("res://scripts/maisons_iles_v82.gd")

## [id, poids, {style: [styles où elle peut arriver]}]
const SCENARIOS := [
	["hf_liftiers", 11, {"style": ["hautefond"]}], ["hf_coucous", 10, {"style": ["hautefond"]}],
	["hf_dirigeable", 11, {"style": ["hautefond"]}], ["hf_vapeur", 12, {"style": ["hautefond"]}],
	["hf_allumettes", 10, {"style": ["hautefond"]}], ["hf_pneumatique", 11, {"style": ["hautefond"]}],
	["hf_pianola", 11, {"style": ["hautefond"]}],
]

static var _rond: Texture2D


static func has(sc: String) -> bool:
	for e in SCENARIOS:
		if str(e[0]) == sc:
			return true
	return false


static func build(M, sc: String) -> void:
	match sc:
		"hf_liftiers":
			_liftiers(M)
		"hf_coucous":
			_coucous(M)
		"hf_dirigeable":
			_dirigeable(M)
		"hf_vapeur":
			_vapeur_matin(M)
		"hf_allumettes":
			_allumettes(M)
		"hf_pneumatique":
			_pneumatique(M)
		"hf_pianola":
			_pianola(M)


# =================================================================== aides

static func _r(M) -> RandomNumberGenerator:
	return M.ctx["rng"]


static func _pick(M, a: Array) -> Variant:
	return a[_r(M).randi() % a.size()]


## Toujours dans la même pièce ? (après un délai, on a pu sortir… ou entrer dans une autre maison)
static func _la(M, room0) -> bool:
	return is_instance_valid(room0) and M.inside and M.room == room0


## Le regard (en degrés, comme M.person) de (fx, fz) vers (tx, tz), en repère de la pièce.
static func _vers(fx: float, fz: float, tx: float, tz: float) -> float:
	return rad_to_deg(atan2(tx - fx, tz - fz))


## Un matériau partagé par plusieurs morceaux.
static func _mat(c: Color, metal: float = 0.0, rough: float = 0.6, emit: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = rough
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m


## Un morceau qui bouge (maillage + matériau partagé), en local du parent.
static func _p(parent: Node3D, mesh: Mesh, m: Material, pos: Vector3, scl: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.scale = scl
	mi.rotation = rot
	parent.add_child(mi)
	return mi


## Pas d'ombre (une maquette suspendue près de la lampe ferait une ombre géante sur les murs).
static func _sans_ombre(n: Node) -> void:
	for c in n.find_children("*", "GeometryInstance3D", true, false):
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## De la géométrie de la pièce (R.kit, regroupée) qu'on peut faire tourner et tomber autour de
## `centre` (monde) : R.movable la bâtit en coordonnées du monde, on la range dans un pivot.
static func _bloc(M, centre: Vector3, fn: Callable) -> Node3D:
	var piv: Node3D = I._node(M, centre)
	var n: Node3D = M.R.movable(fn)
	n.reparent(piv, true)
	return piv


## Une bulle qui monte et s'efface (« Coucou ! », « ♪ », « POP ! »…), à `at` (monde).
static func _bulle(M, at: Vector3, txt: String, c: Color = Color(1.0, 0.95, 0.8), size: int = 40, rise: float = 0.5, dur: float = 1.6) -> void:
	var lab := Label3D.new()
	lab.text = txt
	lab.font_size = size
	lab.pixel_size = 0.004
	lab.outline_size = 10
	lab.modulate = c
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.no_depth_test = true
	M.room.add_child(lab)
	lab.global_position = at
	var tw: Tween = M.room.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lab, "global_position", at + Vector3(0, rise, 0), dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(lab, "modulate:a", 0.0, dur * 0.45).set_delay(dur * 0.55)
	tw.tween_property(lab, "outline_modulate:a", 0.0, dur * 0.45).set_delay(dur * 0.55)
	tw.chain().tween_callback(lab.queue_free)


static func _tache() -> Texture2D:
	if _rond != null:
		return _rond
	var g := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 1))
	gr.set_color(1, Color(1, 1, 1, 0))
	g.gradient = gr
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.0, 0.5)
	g.width = 64
	g.height = 64
	_rond = g
	return _rond


## Une bouffée de vapeur, prête à partir (on la relance avec restart()).
static func _vapeur(M, at: Vector3, s: float = 1.0, n: int = 16) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = n
	p.lifetime = 1.5
	p.one_shot = true
	p.emitting = false
	p.explosiveness = 0.8
	p.direction = Vector3.UP
	p.spread = 24.0
	p.initial_velocity_min = 0.35 * s
	p.initial_velocity_max = 0.8 * s
	p.gravity = Vector3(0, 0.25, 0)
	p.damping_min = 0.3
	p.damping_max = 0.6
	p.scale_amount_min = 0.8
	p.scale_amount_max = 2.0
	var cv := Curve.new()
	cv.add_point(Vector2(0, 0.35))
	cv.add_point(Vector2(1, 1.0))
	p.scale_amount_curve = cv
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 0.7))
	gr.set_color(1, Color(1, 1, 1, 0.0))
	p.color_ramp = gr
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12) * s
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _tache()
	q.material = m
	p.mesh = q
	M.room.add_child(p)
	p.global_position = at
	return p


## Une curiosité qu'on n'a pas déjà dans le sac (sinon, `alt`).
static func _neuf(M, id: String, alt: String) -> String:
	var inv: Node = M.main.get("inventory_v28")
	if inv != null and inv.has_method("count") and int(inv.count(id)) > 0:
		return alt
	return id


## Le poêle de Hautefond contre un mur (yaw : il regarde la pièce) ; le mur derrière reste sans tableau.
static func _poele(M, x: float, z: float, yaw: float) -> void:
	var R = M.R
	R.foyer(x, z, yaw, true)
	var f: Vector3 = Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0, 0, 1)
	R.mark_wall(x - f.x * 0.6, 1.6, z - f.z * 0.6, 0.6)


## Des tableaux là où le mur est libre (fenêtres, poêle, coucous…) ; idx : l'image (-1 : au hasard).
static func _cadres(M, n: int, idx: int = -1) -> void:
	var R = M.R
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var y: float = minf(1.75, R.H - 0.7)
	var spots: Array = [[-hw + 0.02, -hd * 0.55, 90.0], [hw - 0.02, -hd * 0.55, -90.0], [-R.W * 0.3, -hd + 0.02, 0.0],
		[R.W * 0.3, -hd + 0.02, 0.0], [-hw + 0.02, hd * 0.3, 90.0], [hw - 0.02, hd * 0.3, -90.0]]
	var placed: int = 0
	for s in spots:
		if placed >= n:
			break
		var w: float = _r(M).randf_range(0.6, 0.9)
		if not R.wall_free(float(s[0]), y, float(s[1]), w * 0.5 + 0.15):
			continue
		R.tableau(float(s[0]), y, float(s[1]), float(s[2]), w, w * 0.75, idx)
		placed += 1


# =================================================================== la famille de liftiers

const DE_MON_TEMPS := [
	"De mon temps, la cabine, c'était un panier à salade au bout d'une corde. On montait en tirant, on descendait en priant. Et on arrivait presque toujours au bon étage.",
	"De mon temps, il n'y avait pas de sonnette : le liftier criait « DING ! » lui-même. J'avais la plus belle voix de la Colonne. Les pigeons venaient m'écouter.",
	"De mon temps, c'était la grand-mère de Maîtresse Capucine qui tenait le guichet. Elle comptait les passagers par-dessus ses lunettes. Pas une erreur en quarante ans.",
	"De mon temps, pas de chronomètre : on comptait en chantant « Huile tes rouages ». Un couplet, une montée. Deux couplets, c'est que la cabine faisait la sieste.",
]

const REGLEMENT := "LE RÈGLEMENT DES LIFTIERS (version de la maison). Article un : on tient la rampe. Article deux : on dit « Ça monte ! » en montant. Article trois : on ne nourrit pas les pigeons dans la cabine. Article quatre : on ne tire pas le levier pendant le trajet. Article cinq : Papi n'a droit qu'à dix « de mon temps » par jour."

## Une famille de liftiers : le petit s'entraîne sur une maquette d'ascenseur (une cabine dorée qui
## monte et descend dans sa cage de bois, avec sa poulie, son contrepoids, son cordon et sa sonnette),
## la mère chronomètre, le grand-père raconte « de son temps ». On peut tirer soi-même le levier
## (ding ! « Ça monte ! ») ; la première fois, le grand-père donne un rouage de sa première cabine.
static func _liftiers(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# la maquette contre le mur du fond, le poêle à gauche, le fauteuil du grand-père à droite
	var mx: float = R.W * 0.06
	var mz: float = -hd + 0.62
	R.reserve(mx, mz, 1.0, 1.0)
	R.tapis(mx - 0.2, mz + 1.35, 0, minf(2.6, R.W - 2.8), 1.5)
	_poele(M, -hw + 0.85, -hd + 0.6, 0)
	var fx: float = hw - 0.95
	var fz: float = -hd * 0.05
	R.fauteuil(fx, fz, -110, "vert")
	# la petite table : le règlement des Liftiers et la casquette à galon doré
	var tx: float = -hw + 0.75
	var tz: float = hd * 0.1
	R.table(tx, tz, 0, 0.8, 0.55, 0.76)
	R.kit.cyl(R.L(tx + 0.2, 0.76, tz), 0.1, 0.1, 0.07, "tissu_bleu", 14)
	R.kit.cyl(R.L(tx + 0.2, 0.775, tz), 0.104, 0.104, 0.018, "or", 14)
	R.kit.box(R.L(tx + 0.2, 0.765, tz + 0.12), Vector3(0.16, 0.01, 0.08), "noir", 1.0)
	S._mot(M, tx - 0.15, tz + 0.03, 0.76, REGLEMENT, "E : lire le règlement des liftiers")
	_cadres(M, 2)
	if R.is_free(hw - 0.45, hd - 1.7, 0.6, 0.6):
		R.plante(hw - 0.45, hd - 1.7)
	# les gens : le petit à côté de la maquette, la mère et son chronomètre, le grand-père
	var boy: bool = r.randf() < 0.5
	var kx: float = mx - 0.8
	var kz: float = mz + 0.95
	var kid: Node = M.person("garcon" if boy else "fille", kx, kz, _vers(kx, kz, mx, mz), "debout")
	kid.lines = ["Ça monte !", "Tenez la rampe, s'il vous plaît !", "Tout le monde descend !", "Prochain arrêt : le grenier !", "Je ne regarde pas en bas. Je suis professionnel." if boy else "Je ne regarde pas en bas. Je suis professionnelle."]
	kid.line_every = Vector2(5.0, 8.0)
	var ex: float = mx + 1.05
	var ez: float = mz + 1.05
	var mere: Node = M.person("femme", ex, ez, _vers(ex, ez, mx, mz), "bras_croises")
	mere.lines = ["Top chrono !", "Plus souple sur le cordon !", "On annonce l'étage, mon cœur !", "Quatre secondes. On peut faire mieux."]
	var papi: Node = M.person("vieux", fx, fz, -110, "assis")
	papi.lines = ["De mon temps, on montait à la corde !", "De mon temps, la cabine, c'était un panier à salade !", "De mon temps, on criait « ding » nous-mêmes !", "De mon temps, les pigeons payaient leur billet !"]
	papi.line_every = Vector2(9.0, 14.0)
	# la maquette : le socle, la cage de bois, les rails de laiton, les étages
	var bois := _mat(Color(0.45, 0.29, 0.16), 0.0, 0.7)
	var sombre := _mat(Color(0.24, 0.15, 0.09), 0.0, 0.7)
	var laiton := _mat(Color(0.86, 0.66, 0.3), 0.9, 0.35)
	var dore := _mat(Color(0.96, 0.77, 0.32), 1.0, 0.28)
	var lueur := _mat(Color(1.0, 0.85, 0.5), 0.0, 0.4, 1.4)
	var fer := _mat(Color(0.14, 0.14, 0.15), 0.6, 0.5)
	var rouge := _mat(Color(0.75, 0.12, 0.1), 0.0, 0.5)
	var mod: Node3D = I._node(M, R.P(mx, 0, mz), 0)
	_p(mod, I._boxm(Vector3(0.84, 0.12, 0.74)), sombre, Vector3(0, 0.06, 0))
	_p(mod, I._boxm(Vector3(0.84, 0.08, 0.74)), sombre, Vector3(0, 2.1, 0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_p(mod, I._boxm(Vector3(0.05, 1.96, 0.05)), bois, Vector3(sx * 0.36, 1.08, sz * 0.31))
		_p(mod, I._cyl(0.012, 0.012, 1.92, 8), laiton, Vector3(sx * 0.2, 1.08, 0.11))
		_p(mod, I._boxm(Vector3(0.03, 0.12, 0.03)), laiton, Vector3(sx * 0.07, 2.2, 0.0))
	for k in range(3):
		var ey: float = 0.62 + k * 0.48
		_p(mod, I._boxm(Vector3(0.72, 0.03, 0.03)), bois, Vector3(0, ey, -0.31))
		_p(mod, I._cyl(0.035, 0.035, 0.01), laiton, Vector3(0.36, ey + 0.1, 0.34), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	# la poulie (elle tourne), la cabine dorée, le contrepoids, les cordes
	var poulie := Node3D.new()
	mod.add_child(poulie)
	poulie.position = Vector3(0, 2.26, 0)
	_p(poulie, I._cyl(0.11, 0.11, 0.035, 20), laiton, Vector3.ZERO, Vector3.ONE, Vector3(0, 0, PI * 0.5))
	for k2 in range(2):
		_p(poulie, I._boxm(Vector3(0.04, 0.2, 0.02)), sombre, Vector3.ZERO, Vector3.ONE, Vector3(k2 * PI * 0.5, 0, 0))
	var cab := Node3D.new()
	mod.add_child(cab)
	cab.position = Vector3(0, 0.14, 0.11)
	_p(cab, I._boxm(Vector3(0.32, 0.38, 0.3)), dore, Vector3(0, 0.19, 0))
	_p(cab, I._boxm(Vector3(0.34, 0.03, 0.32)), laiton, Vector3(0, 0.015, 0))
	_p(cab, I._sph(0.17), dore, Vector3(0, 0.38, 0), Vector3(1.0, 0.45, 0.95))
	_p(cab, I._sph(0.028), lueur, Vector3(0, 0.47, 0))
	_p(cab, I._boxm(Vector3(0.2, 0.16, 0.01)), lueur, Vector3(0, 0.24, 0.151))
	for sx2 in [-1.0, 1.0]:
		_p(cab, I._boxm(Vector3(0.01, 0.14, 0.16)), lueur, Vector3(sx2 * 0.161, 0.24, 0))
	_p(cab, I._boxm(Vector3(0.005, 0.3, 0.004)), sombre, Vector3(0, 0.16, 0.153))
	var cw: MeshInstance3D = _p(mod, I._boxm(Vector3(0.12, 0.26, 0.06)), fer, Vector3(0, 1.85, -0.11))
	var c1: MeshInstance3D = _p(mod, I._cyl(0.006, 0.006, 1.0, 6), sombre, Vector3(0, 1.5, 0.11))
	var c2: MeshInstance3D = _p(mod, I._cyl(0.006, 0.006, 1.0, 6), sombre, Vector3(0, 2.1, -0.11))
	# le levier (sur le socle), la sonnette (en haut), le cordon rouge (sur le côté)
	var lev := Node3D.new()
	mod.add_child(lev)
	lev.position = Vector3(0.25, 0.12, 0.31)
	lev.rotation.x = -0.45
	_p(lev, I._cyl(0.012, 0.012, 0.32, 8), laiton, Vector3(0, 0.16, 0))
	_p(lev, I._sph(0.035), rouge, Vector3(0, 0.33, 0))
	_p(mod, I._boxm(Vector3(0.1, 0.03, 0.08)), laiton, Vector3(0.25, 0.135, 0.31))
	var bell := Node3D.new()
	mod.add_child(bell)
	bell.position = Vector3(-0.22, 2.14, 0.28)
	_p(bell, I._cyl(0.015, 0.05, 0.06, 12), dore, Vector3(0, 0.035, 0))
	_p(bell, I._sph(0.016), dore, Vector3(0, 0.075, 0))
	var cordon := Node3D.new()
	mod.add_child(cordon)
	cordon.position = Vector3(-0.4, 2.06, 0.3)
	_p(cordon, I._cyl(0.007, 0.007, 0.8, 6), rouge, Vector3(0, -0.4, 0))
	_p(cordon, I._sph(0.03), rouge, Vector3(0, -0.82, 0), Vector3(1.0, 1.5, 1.0))
	# ce qui bouge : la cabine monte (lvl de 0 à 1), sonne en haut, redescend ; et on recommence
	var y0: float = 0.14
	var y1: float = 1.54
	var st := {"lvl": 0.0, "cible": 0.0, "phase": "bas", "t": 3.0 + r.randf() * 2.0, "joueur": false, "chrono": 0.0, "histoire": r.randi() % DE_MON_TEMPS.size()}
	var maj := func() -> void:
		var yc: float = lerpf(y0, y1, float(st["lvl"]))
		cab.position.y = yc
		var yw: float = 1.85 - (yc - y0)
		cw.position.y = yw
		var top1: float = yc + 0.5
		c1.position.y = (2.26 + top1) * 0.5
		c1.scale.y = maxf(0.01, 2.26 - top1)
		var top2: float = yw + 0.13
		c2.position.y = (2.26 + top2) * 0.5
		c2.scale.y = maxf(0.01, 2.26 - top2)
		poulie.rotation.x = (yc - y0) / 0.11
	maj.call()
	var depart := func(joueur: bool) -> void:
		st["phase"] = "monte"
		st["cible"] = 1.0
		st["joueur"] = joueur
		st["chrono"] = 0.0
		M.main.sfx("ascenseur_tour", cab.global_position)
		var tw: Tween = M.room.create_tween()
		tw.tween_property(cordon, "rotation:x", 0.35, 0.15)
		tw.tween_property(cordon, "rotation:x", 0.0, 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		if joueur:
			_bulle(M, mod.global_position + Vector3(0, 2.45, 0.3), "Ça monte !", Color(1.0, 0.85, 0.4), 46)
		else:
			kid.say(str(_pick(M, ["Ça monte !", "Attention au départ !", "Tenez la rampe !", "Cabine numéro un, départ !"])), 2.5)
	var arrive := func() -> void:
		st["phase"] = "haut"
		st["t"] = 2.5
		M.main.sfx("clochette", bell.global_position)
		var twb: Tween = M.room.create_tween()
		twb.tween_property(bell, "rotation:z", 0.45, 0.08)
		twb.tween_property(bell, "rotation:z", -0.45, 0.14)
		twb.tween_property(bell, "rotation:z", 0.25, 0.12)
		twb.tween_property(bell, "rotation:z", 0.0, 0.1)
		_bulle(M, bell.global_position + Vector3(0, 0.2, 0), "Ding !", Color(1.0, 0.9, 0.5), 42)
		var tps: String = str(snappedf(float(st["chrono"]), 0.1)).replace(".", ",")
		kid.gesture("joie", 1.8)
		if not bool(st["joueur"]):
			mere.say(str(_pick(M, ["%s secondes ! Record de la maison !", "%s secondes. Plus souple sur le cordon !", "%s secondes ! Maîtresse Capucine serait fière !", "%s secondes. Et on annonce l'étage !"])) % tps, 3.5)
			return
		st["joueur"] = false
		if bool(M.state().get("hf_liftiers", false)):
			mere.say("%s secondes ! Plus rapide que la Grande Liftière !" % tps, 3.5)
			return
		M.state()["hf_liftiers"] = true
		papi.gesture("rire", 2.0)
		M.talk(papi, "Ha ! Un vrai coup de poignet de liftier ! De mon temps, on donnait un rouage au nouveau pour son premier « Ça monte ! ». Tiens : il vient de ma toute première cabine.",
			I._bye("Merci ! Ça monte !"), func(_i):
			M.give([["engrenage", 1], ["biscuit_engrenage", 1]], "")
			M.close_talk(), "ému")
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(cab):
			return
		var l: float = float(st["lvl"])
		var c: float = float(st["cible"])
		if l < c:
			l = minf(c, l + 0.26 * dt)
		elif l > c:
			l = maxf(c, l - 0.34 * dt)
		st["lvl"] = l
		maj.call()
		st["chrono"] = float(st["chrono"]) + dt
		match str(st["phase"]):
			"bas":
				st["t"] = float(st["t"]) - dt
				if float(st["t"]) <= 0.0:
					depart.call(false)
			"monte":
				if l >= 1.0:
					arrive.call()
			"haut":
				st["t"] = float(st["t"]) - dt
				if float(st["t"]) <= 0.0:
					st["phase"] = "descend"
					st["cible"] = 0.0
					M.main.sfx("mecanisme", cab.global_position)
					kid.say(str(_pick(M, ["Tout le monde descend !", "Attention, ça descend !", "Rez-de-chaussée : le salon !"])), 2.5)
			"descend":
				if l <= 0.0:
					st["phase"] = "bas"
					st["t"] = 8.0 + randf() * 5.0
	# ce qu'on fait : tirer le levier, parler à la mère, écouter le grand-père
	M.act(R.P(mx + 0.25, 0, mz + 0.9), "E : tirer le levier de la maquette", func() -> void:
		var tw: Tween = M.room.create_tween()
		tw.tween_property(lev, "rotation:x", 0.45, 0.15)
		tw.tween_property(lev, "rotation:x", -0.45, 0.45).set_delay(0.5)
		M.main.sfx("levier", lev.global_position)
		if str(st["phase"]) != "bas":
			kid.say(str(_pick(M, ["Pas pendant le trajet ! Article quatre du règlement !", "Attends qu'elle redescende !", "Une cabine à la fois, s'il vous plaît !"])), 3.0)
			return
		depart.call(true)
	, 1.1)
	var mere_cb := func() -> void:
		M.talk(mere, str(_pick(M, ["Bonjour ! Chut, on s'entraîne : un jour, le petit conduira une vraie cabine de la Colonne. Moi, je chronomètre." if boy else "Bonjour ! Chut, on s'entraîne : un jour, la petite conduira une vraie cabine de la Colonne. Moi, je chronomètre.",
			"Entrez, entrez ! Vous tombez en pleine séance : montée, sonnette, descente. Comme à la Colonne, en plus petit.",
			"Bienvenue chez les liftiers ! Chez nous, même le dîner arrive à l'heure. Et en sonnant."])),
			[{"id": "essai", "label": "Je peux essayer la maquette ?"}, {"id": "metier", "label": "Il y a des liftiers dans la famille ?"}, {"id": "fermer", "label": "Bon entraînement !"}], func(id):
			match id:
				"essai":
					M.talk(mere, "Bien sûr ! Le levier, là, sur le socle. Et on annonce : « Ça monte ! » C'est le règlement. Je lance le chronomètre.", I._bye("C'est parti !"), I._close(M))
				"metier":
					M.talk(mere, "Trois générations ! Grand-père a conduit la cabine numéro deux pendant quarante ans, moi je conduis la numéro trois. Et le petit sera liftier. C'est décidé. Il faut juste prévenir Maîtresse Capucine." if boy else "Trois générations ! Grand-père a conduit la cabine numéro deux pendant quarante ans, moi je conduis la numéro trois. Et la petite sera liftière. C'est décidé. Il faut juste prévenir Maîtresse Capucine.", I._bye("Bientôt une vraie cabine !"), I._close(M))
				_:
					M.close_talk()
		, "fière")
	M.talk_spot(mere, mere_cb)
	var papi_cb := func() -> void:
		M.talk(papi, str(_pick(M, ["Ah, de la visite ! Tu as vu mon petit-fils ? Un vrai talent. De mon temps, on n'avait pas de maquette : on s'entraînait sur l'armoire." if boy else "Ah, de la visite ! Tu as vu ma petite-fille ? Un vrai talent. De mon temps, on n'avait pas de maquette : on s'entraînait sur l'armoire.",
			"Bonjour, bonjour. Assieds-toi… Non ? Tu restes debout ? De mon temps, les jeunes restaient debout aussi. Par politesse."])),
			[{"id": "temps", "label": "Racontez-moi « de votre temps » !"}, {"id": "fermer", "label": "Au revoir, grand-père !"}], func(id):
			if id != "temps":
				M.close_talk()
				return
			var h: int = int(st["histoire"])
			st["histoire"] = h + 1
			papi.gesture("rire", 2.0)
			M.talk(papi, str(DE_MON_TEMPS[h % DE_MON_TEMPS.size()]), I._bye("Ha ha ! Merci, grand-père !"), I._close(M), "nostalgique")
		, "nostalgique")
	M.talk_spot(papi, papi_cb)
	M.ctx["entree"] = str(_pick(M, ["« Ça monte ! » Au fond du salon, une petite cabine dorée grimpe le long de sa cage de bois. Un enfant tient le cordon, très sérieux.",
		"Une famille de liftiers ! Une maquette d'ascenseur trône contre le mur, la maman tient un chronomètre, et le grand-père ses souvenirs.",
		"Ding ! Une minuscule cabine dorée arrive en haut de sa cage. « Quatre secondes ! » annonce une voix. Ici, on s'entraîne."]))


# =================================================================== la maison aux cent coucous

## Un coucou au mur (repère de la pièce : x, y, z sur le mur ; yaw : il regarde la pièce ; s : sa
## taille). La maisonnette, le toit, le cadran, les aiguilles, la porte de l'oiseau et les poids sont
## regroupés avec la pièce ; le balancier et l'oiseau (caché derrière sa porte) bougent.
static func _coucou_mur(M, x: float, y: float, z: float, yaw: float, s: float, m: Dictionary) -> Dictionary:
	var R = M.R
	var r := _r(M)
	var xf: Transform3D = R.L(x, y, z, yaw)
	R.kit.box(xf * Transform3D(Basis(), Vector3(0, 0, 0.07) * s), Vector3(0.3, 0.32, 0.14) * s, "bois", 1.0)
	for sx in [-1.0, 1.0]:
		R.kit.box(xf * Transform3D(Basis(Vector3.BACK, -sx * 0.6), Vector3(sx * 0.085, 0.2, 0.08) * s), Vector3(0.22, 0.03, 0.18) * s, "bois_sombre", 1.0)
	R.kit.cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.02, 0.14) * s), 0.075 * s, 0.075 * s, 0.01 * s, "ceramique", 14)
	R.kit.box(xf * Transform3D(Basis(Vector3.BACK, r.randf() * TAU), Vector3(0, -0.02, 0.153) * s), Vector3(0.008, 0.11, 0.004) * s, "noir", 1.0)
	R.kit.box(xf * Transform3D(Basis(Vector3.BACK, r.randf() * TAU), Vector3(0, -0.02, 0.156) * s), Vector3(0.01, 0.07, 0.004) * s, "noir", 1.0)
	R.kit.box(xf * Transform3D(Basis(), Vector3(0, 0.1, 0.141) * s), Vector3(0.065, 0.055, 0.004) * s, "noir", 1.0)
	for sx2 in [-1.0, 1.0]:
		var ch: float = r.randf_range(0.18, 0.4)
		R.kit.box(xf * Transform3D(Basis(), Vector3(sx2 * 0.05, -0.16 - ch * 0.5, 0.06) * s), Vector3(0.006, ch, 0.006) * s, "fer", 1.0)
		R.kit.cyl(xf * Transform3D(Basis(), Vector3(sx2 * 0.05, -0.27 - ch, 0.06) * s), 0.0, 0.026 * s, 0.11 * s, "cuivre", 8)
	var cn: Node3D = I._node(M, R.P(x, y, z), yaw)
	cn.scale = Vector3.ONE * s
	var pend := Node3D.new()
	cn.add_child(pend)
	pend.position = Vector3(0, -0.15, 0.1)
	_p(pend, m["tige"], m["laiton"], Vector3(0, -0.12, 0))
	_p(pend, m["disque"], m["laiton"], Vector3(0, -0.25, 0), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	var ois := Node3D.new()
	cn.add_child(ois)
	ois.position = Vector3(0, 0.1, 0.07)
	var pl: Array = m["plumes"]
	_p(ois, m["corps"], pl[r.randi() % pl.size()], Vector3.ZERO, Vector3(1.0, 0.9, 1.3))
	_p(ois, m["bec"], m["bec_m"], Vector3(0, 0.004, 0.035), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	return {"pend": pend, "ois": ois, "amp": r.randf_range(0.22, 0.34), "w": TAU / r.randf_range(0.9, 1.5), "ph": r.randf() * TAU,
		"marche": true, "x": x, "fond": absf(yaw) < 1.0, "bulle": xf * (Vector3(0, 0.34, 0.25) * s)}


## La maison aux cent coucous : des pendules partout aux murs (leurs balanciers battent) ; toutes les
## trente secondes environ, elles sonnent ensemble (les oiseaux sortent : « Coucou ! ») ; la vieille
## dame les remonte une à une avec sa grosse clé, en longeant le mur. La grosse pendule s'est arrêtée :
## on peut la remonter (trois tours de clé) ; la première fois, la dame offre un petit cadeau.
static func _coucous(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var laiton := _mat(Color(0.88, 0.68, 0.3), 0.9, 0.35)
	var m := {"tige": I._boxm(Vector3(0.008, 0.24, 0.006)), "disque": I._cyl(0.035, 0.035, 0.008, 14), "corps": I._sph(0.026),
		"bec": I._cyl(0.0, 0.009, 0.02, 6), "laiton": laiton, "bec_m": _mat(Color(0.95, 0.55, 0.1)),
		"plumes": [_mat(Color(0.95, 0.82, 0.25)), _mat(Color(0.35, 0.6, 0.85)), _mat(Color(0.85, 0.3, 0.25)), _mat(Color(0.4, 0.7, 0.35)), _mat(Color(0.95, 0.95, 0.9))]}
	# la grosse pendule (arrêtée) d'abord : sur un mur de côté, à hauteur de main, loin des fenêtres
	var cands: Array = [[hw - 0.02, -hd + 1.0, -90.0], [-hw + 0.02, -hd + 1.0, 90.0], [hw - 0.02, 0.0, -90.0], [-hw + 0.02, 0.0, 90.0], [hw - 0.02, hd - 1.9, -90.0], [-hw + 0.02, hd - 1.9, 90.0]]
	var gc: Array = cands[0]
	for c in cands:
		if R.wall_free(float(c[0]), 1.45, float(c[1]), 0.45):
			gc = c
			break
	var gros: Dictionary = _coucou_mur(M, float(gc[0]), 1.4, float(gc[1]), float(gc[2]), 1.7, m)
	R.mark_wall(float(gc[0]), 1.45, float(gc[1]), 0.5)
	gros["grosse"] = true
	gros["marche"] = bool(M.state().get("hf_coucous", false))
	var gside: float = signf(float(gc[0]))
	var gfront: Vector3 = R.P(float(gc[0]) - gside * 0.75, 0, float(gc[1]))
	R.reserve(float(gc[0]) - gside * 0.5, float(gc[1]), 1.0, 1.0)
	# le coin pour se reposer, de l'autre côté : un fauteuil (et son chat), un guéridon, une théière
	R.tapis(0.0, -0.2, 0, minf(2.6, R.W - 2.8), 1.6)
	var ax: float = -gside * (hw - 0.9)
	var az: float = hd * 0.05
	var ayaw: float = 90.0 if ax < 0.0 else -90.0
	R.fauteuil(ax, az, ayaw, "rouge")
	R.chat(ax, az, ayaw + 180.0, [Color(0.95, 0.6, 0.25), Color(0.15, 0.15, 0.17), Color(0.6, 0.6, 0.62)][r.randi() % 3], true, 0.47)
	R.table_ronde(ax, az - 0.95, 0.3, 0.6)
	R.kit.cyl(R.L(ax, 0.6, az - 0.95), 0.07, 0.08, 0.12, "ceramique", 12)
	R.kit.cyl(Transform3D(Basis(Vector3.BACK, -0.9), R.P(ax + 0.06, 0.65, az - 0.95)), 0.012, 0.02, 0.1, "ceramique", 6)
	M.act(R.P(ax, 0, az), "E : caresser le chat", func() -> void:
		M.main.sfx("ronron")
		M.say(str(_pick(M, ["Le chat ouvre un œil. Il est habitué aux coucous : il ne se réveille que pour celui de midi. Celui du déjeuner.", "Ronron. Le chat dort au milieu de cent tic-tac. Il appelle ça « le calme »."])), 4.0), 1.0)
	# les coucous, partout sur les murs (pas devant les fenêtres)
	var horloges: Array = [gros]
	var rangs: Array = [1.5, 2.05]
	var spots: Array = []
	var nx: int = int((R.W - 1.0) / 0.6)
	for i in range(nx + 1):
		spots.append([-hw + 0.5 + i * (R.W - 1.0) / maxf(1.0, nx), -hd + 0.02, 0.0, rangs[i % 2]])
	var nz: int = int((R.D - 2.0) / 0.6)
	for j in range(nz + 1):
		var zz: float = -hd + 0.5 + j * (R.D - 2.0) / maxf(1.0, nz)
		spots.append([-hw + 0.02, zz, 90.0, rangs[(j + 1) % 2]])
		spots.append([hw - 0.02, zz, -90.0, rangs[j % 2]])
	for s in spots:
		if horloges.size() >= 27:
			break
		var yy: float = float(s[3]) + r.randf_range(-0.06, 0.06)
		if not R.wall_free(float(s[0]), yy, float(s[1]), 0.22):
			continue
		horloges.append(_coucou_mur(M, float(s[0]), yy, float(s[1]), float(s[2]), r.randf_range(0.85, 1.1), m))
		R.mark_wall(float(s[0]), yy, float(s[1]), 0.2)
	# la vieille dame et sa grosse clé : elle remonte les coucous du mur du fond, un par un
	var zl: float = -hd + 0.8
	var stations: Array = []
	for h in horloges:
		if bool(h["fond"]):
			stations.append(float(h["x"]))
	if stations.is_empty():
		stations.append(0.0)
	var i0: int = r.randi() % stations.size()
	var dame: Node = M.person("vieille", float(stations[i0]), zl, 180, "bricoler")
	dame.lines = ["Et un tour… et deux tours…", "Allez, ma belle, encore un peu.", "Cent sept coucous, cent sept tours de clé !", "Celle-là retarde. Comme mon mari."]
	dame.line_every = Vector2(7.0, 11.0)
	var cle := Node3D.new()
	dame.npc.add_child(cle)
	cle.position = Vector3(0.0, 1.05, 0.42)
	_p(cle, I._cyl(0.012, 0.012, 0.22, 8), laiton, Vector3.ZERO, Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_p(cle, I._boxm(Vector3(0.13, 0.05, 0.012)), laiton, Vector3(0, 0, -0.12))
	_p(cle, I._boxm(Vector3(0.03, 0.02, 0.03)), laiton, Vector3(0, 0, 0.11))
	var dame_cb := func() -> void:
		M.talk(dame, str(_pick(M, ["Bonjour, mon petit ! Tu entends ? Cent sept coucous, et ils veulent tous leur tour de clé. Je fais ma tournée.",
			"Entre, entre, mais parle fort : ici, ça fait tic-tac du matin au soir. Et coucou toutes les demi-minutes."])),
			[{"id": "aider", "label": "Je peux vous aider ?"}, {"id": "pourquoi", "label": "Pourquoi autant de coucous ?"}, {"id": "fermer", "label": "Bonne tournée !"}], func(id):
			match id:
				"aider":
					if bool(gros["marche"]):
						M.talk(dame, "Tu m'as déjà aidée ! La grosse bat comme un cœur. Les autres, je m'en occupe : c'est ma promenade.", I._bye("Bonne promenade !"), I._close(M))
					else:
						M.talk(dame, "Oh, que c'est gentil ! La grosse pendule, là, sur le mur, s'est arrêtée cette nuit. La clé est dans sa serrure : trois tours, pas un de plus. Elle est chatouilleuse.", I._bye("J'y vais !"), I._close(M))
				"pourquoi":
					M.talk(dame, "Mon mari était horloger. À chaque anniversaire, il m'offrait un coucou. Il m'en a offert cent sept ! Maintenant, c'est lui qui fait la sieste, et moi qui les remonte.", I._bye("Quel beau cadeau !"), I._close(M))
				_:
					M.close_talk()
		, "joyeuse")
	var it_dame: Dictionary = M.talk_spot(dame, dame_cb)
	var st := {"t": 0.0, "son": 12.0 + r.randf() * 8.0, "pause": 4.0 + r.randf() * 3.0, "marche": false, "remonte": 0.0, "i": i0, "sens": 1, "tours": 0}
	var aller := func() -> void:
		var i: int = int(st["i"]) + int(st["sens"])
		if i < 0 or i >= stations.size():
			st["sens"] = -int(st["sens"])
			i = int(st["i"]) + int(st["sens"])
		i = clampi(i, 0, stations.size() - 1)
		st["i"] = i
		var to: Vector3 = R.P(float(stations[i]), 0, zl)
		var from: Vector3 = dame.npc.global_position
		var d: float = Vector2(to.x - from.x, to.z - from.z).length()
		if d < 0.05:
			st["remonte"] = 2.8
			return
		st["marche"] = true
		dame.set_pose("marcher", Vector3(to.x - from.x, 0, to.z - from.z))
		var tw: Tween = M.room.create_tween()
		tw.tween_property(dame.npc, "global_position", Vector3(to.x, from.y, to.z), d / 0.6)
		tw.tween_callback(func() -> void:
			st["marche"] = false
			st["remonte"] = 2.8
			dame.set_pose("bricoler", Vector3(0, 0, -1))
			M.main.sfx("rouage", to + Vector3(0, 1.4, 0)))
	var sonner := func() -> void:
		M.main.sfx("carillon", R.P(0, 1.8, -hd + 0.5))
		M.main.sfx("clochette", R.P(-hw + 0.5, 1.8, 0))
		M.main.sfx("clochette", R.P(hw - 0.5, 1.8, 0))
		var vus: Array = []
		for h in horloges:
			if not bool(h["marche"]):
				continue
			var ois: Node3D = h["ois"]
			var tw: Tween = M.room.create_tween()
			tw.tween_interval(randf() * 0.3 + (0.7 if bool(h.get("grosse", false)) else 0.0))
			for k in range(2):
				tw.tween_property(ois, "position:z", 0.2, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_interval(0.25)
				tw.tween_property(ois, "position:z", 0.07, 0.15)
				tw.tween_interval(0.15)
			vus.append(h)
		vus.shuffle()
		for j in range(mini(6, vus.size())):
			_bulle(M, vus[j]["bulle"], "Cou-cou ! Cou-cou !", Color(1.0, 0.95, 0.7), 34, 0.45, 1.8)
		dame.say(str(_pick(M, ["Et voilà l'heure !", "Toutes ensemble ! Enfin, presque.", "Ah, la chorale !", "Coucou, mes belles !"])), 3.0)
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(cle):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		for h in horloges:
			if bool(h["marche"]):
				(h["pend"] as Node3D).rotation.z = float(h["amp"]) * sin(t * float(h["w"]) + float(h["ph"]))
		it_dame["pos"] = dame.npc.global_position + Vector3.UP * 0.05
		if float(st["remonte"]) > 0.0:
			st["remonte"] = float(st["remonte"]) - dt
			cle.rotation.z += dt * 5.0
		if not bool(st["marche"]) and not bool(dame.talking):
			st["pause"] = float(st["pause"]) - dt
			if float(st["pause"]) <= 0.0:
				st["pause"] = 6.0 + randf() * 4.0
				aller.call()
		st["son"] = float(st["son"]) - dt
		if float(st["son"]) <= 0.0:
			st["son"] = 27.0 + randf() * 6.0
			sonner.call()
	# remonter la grosse pendule : trois tours de clé
	M.act(gfront, "E : remonter la grosse pendule", func() -> void:
		if bool(gros["marche"]):
			M.say(str(_pick(M, ["Tic… TAC. Tic… TAC. La grosse pendule bat un peu plus lentement que les autres, mais elle a l'air contente.",
				"La grosse pendule fait tic-tac. Son oiseau te regarde par sa petite porte. Il a l'air reconnaissant."])), 4.0)
			return
		st["tours"] = int(st["tours"]) + 1
		M.main.sfx("rouage", gros["bulle"])
		if int(st["tours"]) < 3:
			M.say(["Crrr… Un tour de clé. Le ressort se tend.", "Crrr… crrr… Deux tours. Encore un !"][int(st["tours"]) - 1], 2.5)
			return
		gros["marche"] = true
		M.main.sfx("carillon", gros["bulle"])
		var ois: Node3D = gros["ois"]
		var tw: Tween = M.room.create_tween()
		tw.tween_property(ois, "position:z", 0.2, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.6)
		tw.tween_property(ois, "position:z", 0.07, 0.2)
		_bulle(M, gros["bulle"], "COUCOU !", Color(1.0, 0.85, 0.4), 52, 0.6, 2.0)
		dame.gesture("joie", 2.0)
		if bool(M.state().get("hf_coucous", false)):
			return
		M.state()["hf_coucous"] = true
		var cad: String = _neuf(M, "montre_envers", "ressort")
		var txt: String = "Elle repart ! Tic, tac ! Tu as des doigts d'horloger. Tiens : la seule montre de la maison que je n'ai jamais su régler. Elle est juste, mais à l'envers." if cad == "montre_envers" else "Elle repart ! Tic, tac ! Tu as des doigts d'horloger. Tiens, un ressort de rechange : à Hautefond, ça sert toujours."
		M.talk(dame, txt, I._bye("Merci, madame !"), func(_i):
			M.give([[cad, 1], ["piece", 4 + r.randi() % 5]], "")
			M.close_talk(), "ravie")
	, 1.2)
	M.ctx["entree"] = str(_pick(M, ["Tic. Tac. Tic. Tac. Des coucous partout, sur tous les murs : on dirait une pluie très régulière.",
		"Une maison pleine de pendules ! Leurs balanciers battent tous en même temps… enfin, presque.",
		"Cent coucous ? Plus ! Une vieille dame passe de l'un à l'autre avec une clé grosse comme une cuillère à pot."]))


# =================================================================== l'aéronaute et son dirigeable

const TEMPETES := [
	"Un soir, au-dessus de la Pointe, un éclair a frôlé mon ballon. Toute la toile s'est mise à briller comme une lanterne ! Margot, au Phare, a cru que c'était un deuxième phare : elle m'a fait des signaux toute la nuit.",
	"Une fois, une bourrasque m'a emporté jusqu'au-dessus de la Cité des Nuées ! J'ai atterri dans une serre, au milieu des fraises géantes. Ils m'ont gardé à dîner. Le dessert était plus gros que moi.",
	"La pire tempête ? Celle où mon chapeau s'est envolé. Je l'ai poursuivi trois heures, à pleine vapeur, jusqu'au-dessus du Dôme d'Azur. Il flottait sur la mer, avec une mouette endormie dedans. Je le lui ai laissé.",
]

const CARTES_VENTS := [
	"Des cartes des vents : des flèches partout, des spirales, de petits nuages dessinés à l'encre bleue. Dans un coin : « Ici, le vent tourne trois fois avant de se décider. »",
	"Une carte de l'île couverte de flèches. Au-dessus de la Grande Colonne, quelqu'un a écrit : « Ne jamais passer à seize heures : le chocolat de Firmin siffle, et ça secoue. »",
	"Une carte des courants d'air de l'archipel. Une croix rouge, tout au bout : « Ballon rouge aperçu ici. H. N. » La Capitaine Héloïse le cherche toujours.",
]

## La maison d'un aéronaute (un ami de la Capitaine Héloïse Nimbus) : une maquette de dirigeable,
## suspendue au plafond, fait sa ronde (son hélice tourne) ; sur la table, les cartes des vents et une
## boussole dont l'aiguille tremble ; un enfant réclame des histoires de tempête. On peut pousser la
## maquette, lire les cartes, demander une histoire (trois tempêtes) ; après la première, l'aéronaute
## offre sa boussole de secours (ou un nuage en bocal, si on a déjà la boussole).
static func _dirigeable(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var nom_d: String = str(_pick(M, ["la Mouette", "le Cormoran", "la Libellule", "le Pélican", "la Bourrasque"]))
	var teinte: Color = [Color(0.25, 0.4, 0.7), Color(0.3, 0.55, 0.35), Color(0.9, 0.72, 0.28), Color(0.9, 0.86, 0.74)][r.randi() % 4]
	# la table des cartes, le poêle, la bibliothèque des carnets de bord, l'affiche, l'hélice au mur
	var tx: float = 0.0
	var tz: float = -hd * 0.3
	R.tapis(tx, tz + 0.2, 0, minf(2.6, R.W - 2.8), 1.8)
	var places: Array = S._table(M, tx, tz, 3, "")
	_poele(M, -hw + 0.85, -hd + 0.6, 0)
	if R.is_free(hw - 0.4, -hd * 0.45, 0.6, 1.1):
		R.etagere(hw - 0.22, -hd * 0.45, -90, 1.0, 1.8, true, 4)
	_cadres(M, 1, 0)
	_cadres(M, 1)
	var hx: float = R.W * 0.25
	if R.wall_free(hx, 2.0, -hd + 0.02, 0.5):
		R.mark_wall(hx, 2.0, -hd + 0.02, 0.5)
		R.kit.box(R.L(hx, 2.0, -hd + 0.06, 0) * Transform3D(Basis(Vector3.BACK, 0.4), Vector3.ZERO), Vector3(0.9, 0.09, 0.03), "bois", 1.0)
		R.kit.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), R.P(hx, 2.0, -hd + 0.04)), 0.05, 0.05, 0.06, "cuivre", 12)
	for k in range(2):
		var cx: float = tx - 0.3 + k * 0.55
		var cz: float = tz + (0.05 if k == 0 else -0.08)
		R.kit.box(R.L(cx, 0.765, cz, -12.0 + k * 20.0), Vector3(0.5, 0.004, 0.36), "papier", 1.0, 4)
		for j in range(5):
			R.kit.box(R.L(cx + r.randf_range(-0.18, 0.18), 0.769, cz + r.randf_range(-0.12, 0.12), r.randf_range(0, 180)), Vector3(r.randf_range(0.08, 0.2), 0.002, 0.008), "tissu_bleu", 1.0, 4)
	# la boussole (son aiguille tremble)
	var laiton := _mat(Color(0.86, 0.66, 0.3), 0.9, 0.35)
	var bous: Node3D = I._node(M, R.P(tx + 0.4, 0.76, tz + 0.22), 0)
	_p(bous, I._cyl(0.075, 0.08, 0.03, 20), laiton, Vector3(0, 0.015, 0))
	_p(bous, I._cyl(0.065, 0.065, 0.004, 20), _mat(Color(0.95, 0.93, 0.85)), Vector3(0, 0.031, 0))
	var aig := Node3D.new()
	bous.add_child(aig)
	aig.position = Vector3(0, 0.036, 0)
	_p(aig, I._boxm(Vector3(0.008, 0.004, 0.055)), _mat(Color(0.8, 0.1, 0.1)), Vector3(0, 0, 0.0275))
	_p(aig, I._boxm(Vector3(0.008, 0.004, 0.055)), _mat(Color(0.95, 0.95, 0.95)), Vector3(0, 0, -0.0275))
	# la maquette du dirigeable : elle tourne autour du milieu de la pièce, sous la lampe
	var yship: float = minf(2.15, R.H - 0.9)
	var piv: Node3D = I._node(M, R.P(0, R.H - 0.02, 0), r.randf() * 360.0)
	var ship := Node3D.new()
	piv.add_child(ship)
	var yloc: float = -(R.H - 0.02 - yship)
	ship.position = Vector3(0.36, yloc, 0)
	var env := _mat(teinte, 0.0, 0.55)
	var aile := _mat(teinte.darkened(0.35), 0.0, 0.6)
	var bois := _mat(Color(0.42, 0.27, 0.15), 0.0, 0.7)
	var fil := _mat(Color(0.2, 0.18, 0.16), 0.0, 0.9)
	var fl: float = -yloc - 0.12
	for wz in [-0.18, 0.18]:
		_p(ship, I._cyl(0.003, 0.003, fl, 4), fil, Vector3(0, 0.12 + fl * 0.5, wz))
	_p(ship, I._sph(0.12), env, Vector3.ZERO, Vector3(1.0, 1.0, 3.0))
	for bz in [-0.12, 0.12]:
		_p(ship, I._cyl(0.123, 0.123, 0.02, 20), laiton, Vector3(0, 0, bz), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_p(ship, I._sph(0.022), laiton, Vector3(0, 0, 0.355))
	for f in [[Vector3(0, 0.09, -0.3), Vector3(0.012, 0.12, 0.12)], [Vector3(0, -0.09, -0.3), Vector3(0.012, 0.12, 0.12)],
			[Vector3(0.09, 0, -0.3), Vector3(0.12, 0.012, 0.12)], [Vector3(-0.09, 0, -0.3), Vector3(0.12, 0.012, 0.12)]]:
		_p(ship, I._boxm(f[1]), aile, f[0])
	_p(ship, I._boxm(Vector3(0.07, 0.05, 0.2)), bois, Vector3(0, -0.165, 0.03))
	_p(ship, I._boxm(Vector3(0.074, 0.014, 0.15)), _mat(Color(1.0, 0.85, 0.5), 0.0, 0.4, 1.3), Vector3(0, -0.16, 0.03))
	for gz in [-0.04, 0.1]:
		_p(ship, I._cyl(0.003, 0.003, 0.06, 4), fil, Vector3(0, -0.12, gz))
	var hel := Node3D.new()
	ship.add_child(hel)
	hel.position = Vector3(0, -0.165, -0.085)
	_p(hel, I._boxm(Vector3(0.13, 0.022, 0.006)), bois, Vector3.ZERO)
	_p(hel, I._boxm(Vector3(0.022, 0.13, 0.006)), bois, Vector3.ZERO)
	_p(hel, I._sph(0.012), laiton, Vector3(0, 0, -0.004))
	_sans_ombre(piv)
	# l'aéronaute (il lit les cartes) et l'enfant (qui veut des tempêtes)
	var pilote: Node = S._asseoir(M, str(_pick(M, ["homme", "femme", "vieux"])), places[1], "lire")
	pilote.lines = ["Vent d'ouest, force trois…", "Hmm, une dépression sur les Arches.", "Où ai-je mis mon compas ?", "Par la Colonne, quel ciel !"]
	var boy: bool = r.randf() < 0.5
	var kid: Node = S._asseoir(M, "garcon" if boy else "fille", places[2], "assis")
	kid.lines = ["Raconte la tempête !", "Encore une histoire !", "Quand je serai grand, j'aurai un dirigeable rouge !" if boy else "Quand je serai grande, j'aurai un dirigeable rouge !", "Vrrrr ! Je suis un dirigeable !"]
	kid.line_every = Vector2(6.0, 9.0)
	var st := {"t": 0.0, "vite": 0.0, "histoire": r.randi() % TEMPETES.size(), "carte": r.randi() % CARTES_VENTS.size()}
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(piv):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var v: float = float(st["vite"])
		piv.rotation.y -= dt * (0.32 + v)
		st["vite"] = maxf(0.0, v - dt * 0.6)
		ship.position.y = yloc + 0.012 * sin(t * 1.3)
		ship.rotation.z = -0.1 * minf(v, 2.0) + 0.03 * sin(t * 0.9)
		hel.rotation.z += dt * (9.0 + v * 6.0)
		aig.rotation.y = 0.6 + 0.25 * sin(t * 1.7) + 0.08 * sin(t * 5.3)
	# pousser la maquette, lire les cartes, demander une histoire
	M.act(R.P(0.0, 0, 0.35), "E : pousser la maquette du dirigeable", func() -> void:
		st["vite"] = minf(4.0, float(st["vite"]) + 2.5)
		M.main.sfx("aeronef_moteur", ship.global_position)
		kid.say(str(_pick(M, ["Plus vite ! Plus vite !", "Vrrrrr ! Cap à l'ouest !", "Il va faire le tour du monde !"])), 2.5)
		if float(st["vite"]) > 3.5:
			pilote.say("Doucement ! %s a le mal de l'air, elle aussi." % nom_d.capitalize() if nom_d.begins_with("la") else "Doucement ! %s a le mal de l'air, lui aussi." % nom_d.capitalize(), 3.0)
	, 1.2)
	M.act(R.P(tx - 1.0, 0, tz), "E : regarder les cartes des vents", func() -> void:
		var c: int = int(st["carte"])
		st["carte"] = c + 1
		M.main.sfx("page")
		M.say(str(CARTES_VENTS[c % CARTES_VENTS.size()]), 6.0), 1.0)
	var raconter := func() -> void:
		var h: int = int(st["histoire"])
		st["histoire"] = h + 1
		M.main.sfx("bourrasque", ship.global_position)
		st["vite"] = 3.0
		kid.gesture("rire", 2.0)
		S._say_late(M, kid, str(_pick(M, ["Ouaaah ! Encore !", "Et après ? Et après ?", "Moi aussi, je veux une tempête !"])), 1.2)
		M.talk(pilote, str(TEMPETES[h % TEMPETES.size()]), [{"id": "ouah", "label": "Ouaaah !"}], func(_i):
			if bool(M.state().get("hf_dirigeable", false)):
				M.close_talk()
				return
			M.state()["hf_dirigeable"] = true
			var cad: String = _neuf(M, "boussole_sud", "bocal_nuage")
			var txt: String = "Tu as écouté sans avoir le mal de l'air : tu feras un bon aéronaute ! Tiens, ma boussole de secours. Elle indique le sud… des deux côtés. Impossible de se tromper." if cad == "boussole_sud" else "Tu as écouté sans avoir le mal de l'air : tu feras un bon aéronaute ! Tiens, un petit nuage que j'ai attrapé au-dessus de la Cité des Nuées."
			M.talk(pilote, txt, I._bye("Merci, capitaine !"), func(_j):
				M.give([[cad, 1], ["piece", 5 + r.randi() % 6]], "")
				M.close_talk(), "fier")
		, "conteur")
	var pilote_cb := func() -> void:
		M.talk(pilote, str(_pick(M, ["Ohé, visiteur ! Bienvenue à bord… enfin, chez moi. C'est pareil : ici aussi, ça tangue quand le vent souffle.",
			"Entrez ! Attention à la tête : %s fait sa ronde. C'est la maquette de mon dirigeable. Le vrai dort au Mât, à côté de l'Albatros." % nom_d])),
			[{"id": "histoire", "label": "Racontez une histoire de tempête !"}, {"id": "heloise", "label": "Vous connaissez la Capitaine Nimbus ?"}, {"id": "fermer", "label": "Bon vent !"}], func(id):
			match id:
				"histoire":
					raconter.call()
				"heloise":
					M.talk(pilote, "Héloïse ? Nous avons appris à voler ensemble ! Elle, à l'endroit. Moi, à l'envers, toute la première année. Elle dit que je suis le seul aéronaute qui ait vu ses propres pieds en plein ciel.", I._bye("Ha ha !"), I._close(M))
				_:
					M.close_talk()
		, "enthousiaste")
	M.talk_spot(pilote, pilote_cb)
	M.ctx["entree"] = str(_pick(M, ["Un petit dirigeable vole en rond sous le plafond ! Dessous, une table couverte de cartes, et un enfant qui réclame : « Une tempête ! Une tempête ! »",
		"Ça sent le cuir et la toile cirée. Des cartes des vents, une boussole, et un dirigeable miniature qui fait sa ronde au-dessus des têtes.",
		"« Attention à la tête ! » Une maquette de dirigeable passe en ronronnant. Ici habite un aéronaute, un ami de la Capitaine Héloïse Nimbus."]))


# =================================================================== le petit-déjeuner à vapeur

## Le petit-déjeuner à vapeur : sur la table, une machine de cuivre (chaudière, tuyaux, sifflet,
## manomètre) fait tout : le chocolat coule dans la tasse, les tartines sautent du grille-pain. De temps
## en temps, elle s'emballe : « TCHOUUU ! », des bouffées de vapeur, des tartines qui volent partout,
## et toute la famille rit. On peut tirer la manette d'arrêt (la première fois : un chocolat chaud et
## un petit cadeau)… ou appuyer sur le gros bouton rouge (une tartine finit dans le chocolat de Papa).
static func _vapeur_matin(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var room0: Node = M.room
	var tz: float = -hd * 0.15
	R.tapis(0.0, tz + 0.1, 0, minf(2.8, R.W - 2.6), 2.0)
	var places: Array = S._table(M, 0.0, tz, 4, "creme")
	_poele(M, -hw + 0.85, -hd + 0.6, 0)
	if R.is_free(hw - 1.5, -hd + 0.38, 2.6, 0.8):
		R.cuisine(hw - 1.5, -hd + 0.38, 0, minf(1.8, R.W * 0.28))
	_cadres(M, 2)
	# la famille à table (la place de devant est pour toi)
	var pere: Node = S._asseoir(M, "homme", places[1], "manger")
	var mere: Node = S._asseoir(M, "femme", places[2], "manger")
	var boy: bool = r.randf() < 0.5
	var kid: Node = S._asseoir(M, "garcon" if boy else "fille", places[3], "manger")
	var gens: Array = [pere, mere, kid]
	pere.lines = ["Encore une tartine ?", "Elle chauffe bien, ce matin.", "Le manomètre est dans le vert. Le vert foncé.", "Mmmh, ce chocolat !"]
	mere.lines = ["Qui veut du miel ?", "Pas les doigts dans le grille-pain !", "Elle siffle comme celle de Firmin.", "Tiens-toi droit, mon cœur."]
	kid.lines = ["Encore une qui saute !", "Je l'attrape ! … Raté.", "Elle va s'emballer, elle va s'emballer !", "Miam !"]
	# la machine, au milieu de la table
	var mach: Node3D = I._node(M, R.P(0.0, 0.76, tz), 0)
	var base_m: Vector3 = mach.position
	var cuivre := _mat(Color(0.8, 0.46, 0.26), 0.9, 0.32)
	var laiton := _mat(Color(0.88, 0.68, 0.3), 0.9, 0.35)
	var fer := _mat(Color(0.15, 0.15, 0.16), 0.6, 0.5)
	var porcelaine := _mat(Color(0.96, 0.95, 0.92), 0.0, 0.2)
	var choco := _mat(Color(0.32, 0.17, 0.1), 0.0, 0.3)
	var pain := _mat(Color(0.86, 0.62, 0.34), 0.0, 0.85)
	var rouge := _mat(Color(0.85, 0.08, 0.06), 0.0, 0.4, 0.6)
	_p(mach, I._boxm(Vector3(0.22, 0.06, 0.22)), fer, Vector3(0, 0.03, -0.05))
	_p(mach, I._boxm(Vector3(0.08, 0.03, 0.005)), _mat(Color(1.0, 0.5, 0.15), 0.0, 0.5, 2.5), Vector3(0, 0.03, 0.061))
	_p(mach, I._cyl(0.12, 0.12, 0.3, 18), cuivre, Vector3(0, 0.21, -0.05))
	_p(mach, I._sph(0.12), cuivre, Vector3(0, 0.36, -0.05), Vector3(1.0, 0.6, 1.0))
	_p(mach, I._cyl(0.015, 0.015, 0.16, 8), laiton, Vector3(0, 0.48, -0.05))
	_p(mach, I._cyl(0.025, 0.02, 0.06, 10), laiton, Vector3(0, 0.59, -0.05))
	_p(mach, I._sph(0.026), laiton, Vector3(0, 0.625, -0.05))
	_p(mach, I._cyl(0.05, 0.05, 0.012, 16), laiton, Vector3(0, 0.24, 0.072), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_p(mach, I._cyl(0.044, 0.044, 0.004, 16), porcelaine, Vector3(0, 0.24, 0.079), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	var aig := Node3D.new()
	mach.add_child(aig)
	aig.position = Vector3(0, 0.24, 0.083)
	_p(aig, I._boxm(Vector3(0.005, 0.036, 0.003)), rouge, Vector3(0, 0.016, 0))
	# les tuyaux, la chocolatière (le chocolat coule dans la tasse), le grille-pain
	_p(mach, I._cyl(0.013, 0.013, 0.2, 8), cuivre, Vector3(-0.2, 0.28, -0.05), Vector3.ONE, Vector3(0, 0, PI * 0.5))
	_p(mach, I._cyl(0.013, 0.013, 0.08, 8), cuivre, Vector3(-0.3, 0.24, -0.05))
	_p(mach, I._cyl(0.013, 0.013, 0.16, 8), cuivre, Vector3(0.19, 0.12, -0.05), Vector3.ONE, Vector3(0, 0, PI * 0.5))
	_p(mach, I._cyl(0.06, 0.065, 0.2, 14), cuivre, Vector3(-0.33, 0.1, -0.05))
	_p(mach, I._sph(0.06), laiton, Vector3(-0.33, 0.2, -0.05), Vector3(1.0, 0.5, 1.0))
	_p(mach, I._cyl(0.01, 0.01, 0.07, 8), laiton, Vector3(-0.33, 0.12, 0.02), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_p(mach, I._cyl(0.035, 0.03, 0.06, 12), porcelaine, Vector3(-0.33, 0.03, 0.06))
	_p(mach, I._cyl(0.032, 0.032, 0.004, 12), choco, Vector3(-0.33, 0.055, 0.06))
	var jet: MeshInstance3D = _p(mach, I._cyl(0.006, 0.006, 0.06, 6), choco, Vector3(-0.33, 0.085, 0.055))
	jet.visible = false
	_p(mach, I._boxm(Vector3(0.16, 0.12, 0.12)), laiton, Vector3(0.3, 0.06, -0.04))
	for sz in [-0.07, -0.01]:
		_p(mach, I._boxm(Vector3(0.13, 0.006, 0.022)), fer, Vector3(0.3, 0.121, sz))
	# le gros bouton rouge et la manette d'arrêt, devant la machine
	_p(mach, I._cyl(0.045, 0.045, 0.02, 14), laiton, Vector3(0.14, 0.01, 0.12))
	var bouton: MeshInstance3D = _p(mach, I._cyl(0.035, 0.035, 0.03, 14), rouge, Vector3(0.14, 0.035, 0.12))
	_p(mach, I._boxm(Vector3(0.06, 0.03, 0.05)), laiton, Vector3(-0.16, 0.015, 0.12))
	var man := Node3D.new()
	mach.add_child(man)
	man.position = Vector3(-0.16, 0.02, 0.12)
	man.rotation.x = -0.5
	_p(man, I._cyl(0.01, 0.01, 0.2, 8), fer, Vector3(0, 0.1, 0))
	_p(man, I._sph(0.03), _mat(Color(0.1, 0.1, 0.1)), Vector3(0, 0.21, 0))
	# les tartines : deux dans le grille-pain, une dans chaque assiette
	var tartines: Array = []
	for sz2 in [-0.07, -0.01]:
		tartines.append(_p(mach, I._boxm(Vector3(0.11, 0.1, 0.012)), pain, Vector3(0.3, 0.13, sz2)))
	var assiettes: Array = [Vector3(-0.3, 0.0, 0.3), Vector3(0.32, 0.0, -0.3), Vector3(0.52, 0.0, 0.08), Vector3(-0.52, 0.0, -0.08)]
	for a in assiettes:
		_p(mach, I._cyl(0.1, 0.09, 0.015, 16), porcelaine, a + Vector3(0, 0.008, 0))
		tartines.append(_p(mach, I._boxm(Vector3(0.09, 0.012, 0.08)), pain, a + Vector3(0, 0.022, 0), Vector3.ONE, Vector3(0, r.randf() * PI, 0)))
	for tn0 in tartines:
		(tn0 as Node3D).set_meta("base", (tn0 as Node3D).position)
		(tn0 as Node3D).set_meta("vol", false)
		(tn0 as Node3D).set_meta("garde", false)
	var jet_v: CPUParticles3D = _vapeur(M, mach.global_position + Vector3(0, 0.64, -0.05), 1.0, 14)
	var soupape: CPUParticles3D = _vapeur(M, mach.global_position + Vector3(0.13, 0.32, -0.05), 0.7, 10)
	var saute := func(tn: Node3D, h: float) -> void:
		if bool(tn.get_meta("vol", false)) or bool(tn.get_meta("garde", false)):
			return
		tn.set_meta("vol", true)
		var b: Vector3 = tn.get_meta("base")
		var up: float = 0.2 + h * 0.3
		var demi: Vector3 = Vector3(PI if h > 0.35 else 0.0, 0, 0)
		var tw: Tween = M.room.create_tween()
		tw.tween_property(tn, "position:y", b.y + h, up).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(tn, "rotation", tn.rotation + demi, up)
		tw.tween_property(tn, "position:y", b.y, up).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(tn, "rotation", tn.rotation + demi * 2.0, up)
		tw.tween_callback(func() -> void:
			tn.rotation.x = fmod(tn.rotation.x, TAU)
			tn.set_meta("vol", false))
	var st := {"t": 0.0, "mode": "calme", "d": 10.0 + r.randf() * 5.0, "pouf": 2.0, "saut": 3.0, "choco": 4.0, "verse": 0.0, "fort": 1.0}
	var emballer := func(fort: float) -> void:
		st["mode"] = "emballe"
		st["d"] = 6.0 + 2.0 * fort
		st["fort"] = fort
		st["pouf"] = 0.0
		st["saut"] = 0.0
		M.main.sfx("vapeur", mach.global_position + Vector3(0, 0.6, 0))
		M.main.sfx("piston", mach.global_position)
		jet_v.restart()
		_bulle(M, mach.global_position + Vector3(0, 0.85, 0), "TCHOUUUU !" if fort < 1.5 else "TCHOUUUUUUUU !", Color(1, 1, 1), 48, 0.6, 1.8)
		for f in gens:
			f.set_pose("rire_assis")
		pere.say(str(_pick(M, ["Elle s'emballe !", "Aux abris, les tartines !", "Pas encore !"])), 2.5)
		S._say_late(M, kid, str(_pick(M, ["Ha ha ha ! Les tartines volent !", "J'en attrape une ! … Raté !", "Encore ! Encore !"])), 1.0)
	var calmer := func(arret: bool) -> void:
		st["mode"] = "arret" if arret else "calme"
		st["d"] = 25.0 if arret else 12.0 + randf() * 6.0
		for f in gens:
			f.set_pose("manger")
		if not arret:
			mere.say(str(_pick(M, ["Ouf, elle s'est calmée.", "Bon. Qui a une tartine dans les cheveux ?", "Elle a eu son petit quart d'heure."])), 3.0)
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(mach):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var mode: String = str(st["mode"])
		st["d"] = float(st["d"]) - dt
		var fou: bool = mode == "emballe"
		if mode == "calme":
			aig.rotation.z = -0.6 + 0.15 * sin(t * 2.0)
		elif fou:
			aig.rotation.z = 1.1 + 0.35 * sin(t * 23.0)
		else:
			aig.rotation.z = -1.2
		mach.position = base_m + (Vector3(randf_range(-0.006, 0.006), randf_range(0.0, 0.008), randf_range(-0.006, 0.006)) if fou else Vector3.ZERO)
		if float(st["verse"]) > 0.0:
			st["verse"] = float(st["verse"]) - dt
		jet.visible = float(st["verse"]) > 0.0
		match mode:
			"calme":
				st["pouf"] = float(st["pouf"]) - dt
				if float(st["pouf"]) <= 0.0:
					st["pouf"] = 2.5 + randf() * 2.0
					soupape.restart()
				st["saut"] = float(st["saut"]) - dt
				if float(st["saut"]) <= 0.0:
					st["saut"] = 3.5 + randf() * 2.5
					saute.call(tartines[randi() % 2], 0.18)
					M.main.sfx("pop", mach.global_position + Vector3(0.3, 0.2, 0))
				st["choco"] = float(st["choco"]) - dt
				if float(st["choco"]) <= 0.0:
					st["choco"] = 6.0 + randf() * 4.0
					st["verse"] = 1.6
					M.main.sfx("verser", mach.global_position)
				if float(st["d"]) <= 0.0:
					emballer.call(1.0)
			"emballe":
				st["pouf"] = float(st["pouf"]) - dt
				if float(st["pouf"]) <= 0.0:
					st["pouf"] = 0.35 + randf() * 0.25
					if randf() < 0.5:
						jet_v.restart()
					else:
						soupape.restart()
				st["saut"] = float(st["saut"]) - dt
				if float(st["saut"]) <= 0.0:
					st["saut"] = 0.3 + randf() * 0.3
					saute.call(tartines[randi() % tartines.size()], randf_range(0.35, 0.8) * minf(1.3, float(st["fort"])))
					M.main.sfx("pop", mach.global_position + Vector3(0.3, 0.2, 0))
				if float(st["d"]) <= 0.0:
					calmer.call(false)
			"arret":
				if float(st["d"]) <= 0.0:
					st["mode"] = "calme"
					st["d"] = 12.0 + randf() * 6.0
					M.main.sfx("piston", mach.global_position)
					kid.say("Elle repart toute seule !", 2.5)
	# la manette d'arrêt (et la récompense, une fois), le gros bouton rouge (une tartine pour Papa)
	M.act(R.P(-0.35, 0, tz + 0.95), "E : tirer la manette d'arrêt", func() -> void:
		var tw: Tween = M.room.create_tween()
		tw.tween_property(man, "rotation:x", 0.55, 0.15)
		tw.tween_property(man, "rotation:x", -0.5, 0.5).set_delay(0.8)
		M.main.sfx("levier", man.global_position)
		if str(st["mode"]) == "arret":
			M.say("La machine est déjà à l'arrêt. Elle boude un peu. Elle repartira toute seule : elle a l'habitude.", 3.5)
			return
		M.main.sfx("vapeur", mach.global_position + Vector3(0, 0.6, 0))
		jet_v.restart()
		_bulle(M, mach.global_position + Vector3(0, 0.8, 0), "Pffffiiiiit…", Color(0.9, 0.95, 1.0), 40, 0.4, 2.0)
		calmer.call(true)
		pere.say("Ouf ! Merci !", 2.5)
		if bool(M.state().get("hf_vapeur", false)):
			return
		M.state()["hf_vapeur"] = true
		var cad: String = _neuf(M, "chaussettes_vapeur", "pain_miel")
		var txt: String = "Bravo, tu as trouvé la manette ! Personne ne la trouve jamais. Tiens, un chocolat bien chaud… et des chaussettes à vapeur : mon mari en a inventé quarante paires." if cad == "chaussettes_vapeur" else "Bravo, tu as trouvé la manette ! Personne ne la trouve jamais. Tiens, un chocolat bien chaud, et du pain de miel pour la route."
		M.talk(mere, txt, I._bye("Merci !"), func(_i):
			M.give([["chocolat_chaud", 1], [cad, 1]], "")
			M.close_talk(), "reconnaissante")
	, 1.0)
	M.act(R.P(0.35, 0, tz + 0.95), "E : appuyer sur le gros bouton rouge", func() -> void:
		var tw: Tween = M.room.create_tween()
		tw.tween_property(bouton, "scale:y", 0.4, 0.08)
		tw.tween_property(bouton, "scale:y", 1.0, 0.25)
		M.main.sfx("clic", bouton.global_position)
		emballer.call(2.0)
		for k in range(1, tartines.size()):
			saute.call(tartines[k], randf_range(0.5, 0.9))
		var tn: Node3D = tartines[0]
		if bool(tn.get_meta("vol", false)) or bool(tn.get_meta("garde", false)):
			return
		tn.set_meta("garde", true)
		var from: Vector3 = tn.position
		var to: Vector3 = (assiettes[1] as Vector3) + Vector3(0, 0.03, 0)
		var tw2: Tween = M.room.create_tween()
		tw2.tween_method(func(k2: float) -> void:
			tn.position = from.lerp(to, k2) + Vector3(0, sin(k2 * PI) * 0.7, 0)
			tn.rotation.x = k2 * PI * 2.5, 0.0, 1.0, 1.1)
		S._say_late(M, pere, "… Une tartine dans mon assiette. Pile dans le miel. Évidemment.", 1.4)
		await M.get_tree().create_timer(5.5).timeout
		if not _la(M, room0) or not is_instance_valid(tn):
			return
		var tw3: Tween = M.room.create_tween()
		tw3.tween_property(tn, "position", tn.get_meta("base"), 0.6).set_trans(Tween.TRANS_QUAD)
		tw3.parallel().tween_property(tn, "rotation", Vector3.ZERO, 0.6)
		tw3.tween_callback(func() -> void:
			tn.set_meta("garde", false))
	, 1.0)
	var mere_cb := func() -> void:
		M.talk(mere, str(_pick(M, ["Bonjour ! Assieds-toi, il reste une place. Notre machine fait tout : le chocolat, les tartines, le café… et parfois n'importe quoi.",
			"Entre ! Tu as faim ? Attention à la tête : chez nous, les tartines arrivent par la voie des airs."])),
			[{"id": "souvent", "label": "Elle s'emballe souvent ?"}, {"id": "fermer", "label": "Bon appétit !"}], func(id):
			if id == "souvent":
				M.talk(mere, "Tous les matins ! Mon mari dit que c'est la vapeur qui se réveille. Moi, je dis que c'est lui qui a serré le mauvais boulon.", I._bye("Ha ha !"), I._close(M))
			else:
				M.close_talk()
		, "amusée")
	M.talk_spot(mere, mere_cb)
	M.ctx["entree"] = str(_pick(M, ["Ça sent le chocolat et le pain grillé. Au milieu de la table, une machine de cuivre siffle, fume… et lance des tartines.",
		"« TCHOU ! » Une tartine passe devant ton nez. Une famille prend son petit-déjeuner autour d'une machine à vapeur très enthousiaste.",
		"Une machine de cuivre fait tout le petit-déjeuner : chocolat, tartines, sifflet. Toute la famille la surveille du coin de l'œil."]))


# =================================================================== la Grande Colonne en allumettes

## La Grande Colonne en allumettes : un grand-père termine une maquette de la Colonne (une tour fine
## d'un mètre et demi, faite d'allumettes dorées, avec son cœur de verre et ses cabines) ; l'enfant
## retient son souffle. On peut poser la dernière allumette au sommet : selon la maison (toujours pareil
## pour une maison donnée), ça tient (applaudissements, et elle reste finie) ou ça s'écroule (les
## morceaux tombent), tout le monde rit, et on recommence. La première fois, un petit cadeau.
static func _allumettes(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var room0: Node = M.room
	var tient: bool = posmod(hash(str(M.ctx["id"]) + "allumettes"), 2) == 0
	var tx: float = -R.W * 0.08
	var tz: float = -hd + 1.3
	# le guéridon de la tour, la table des boîtes d'allumettes, le poêle, le fauteuil
	R.tapis(tx, tz + 0.5, 0, 2.2, 1.6)
	R.table_ronde(tx, tz, 0.42, 0.3)
	_poele(M, hw - 0.85, -hd + 0.6, 0)
	R.fauteuil(hw - 0.95, 0.0, -100, "bleu")
	var bx: float = -hw + 0.75
	var bz: float = hd * 0.05
	R.table(bx, bz, 0, 0.8, 0.55, 0.76)
	for k in range(5):
		R.kit.box(R.L(bx - 0.25 + k * 0.12, 0.777, bz + r.randf_range(-0.1, 0.1), r.randf_range(-20, 20)), Vector3(0.1, 0.03, 0.06), "tissu_rouge" if k % 2 == 0 else "carton", 1.0)
	R.kit.cyl(R.L(bx + 0.25, 0.76, bz + 0.15), 0.04, 0.04, 0.08, "ceramique", 10)
	_cadres(M, 2)
	# la tour : quarante étages d'allumettes croisées, en huit morceaux (qui peuvent tomber)
	var y0: float = 0.3
	var nlv: int = 40
	var dh: float = 1.5 / float(nlv)
	var nch: int = 8
	var morceaux: Array = []
	for c in range(nch):
		var a: int = int(c * nlv / nch)
		var b: int = int((c + 1) * nlv / nch)
		var cy: float = y0 + (a + b) * 0.5 * dh
		var piv: Node3D = _bloc(M, R.P(tx, cy, tz), func() -> void:
			for lv in range(a, b):
				var y: float = y0 + lv * dh
				var h2: float = lerpf(0.12, 0.05, float(lv) / float(nlv))
				for s2 in [-1.0, 1.0]:
					if lv % 2 == 0:
						R.kit.box(R.L(tx, y + dh * 0.5, tz + s2 * h2, 0), Vector3(h2 * 2.0 + 0.03, dh * 0.8, 0.018), "or", 1.0)
					else:
						R.kit.box(R.L(tx + s2 * h2, y + dh * 0.5, tz, 90), Vector3(h2 * 2.0 + 0.03, dh * 0.8, 0.018), "or", 1.0)
			var ya: float = y0 + a * dh
			R.kit.cyl(R.L(tx, ya, tz), 0.03, 0.03, (b - a) * dh, "verre", 8)
			R.kit.box(R.L(tx, ya + (b - a) * dh * 0.5, tz), Vector3(0.05, 0.06, 0.05), "or", 1.0))
		morceaux.append([piv, piv.position])
	var top_piv: Node3D = morceaux[nch - 1][0]
	var top_y: float = y0 + nlv * dh
	var der_y: float = R.P(0, top_y + 0.0125, 0).y - (morceaux[nch - 1][1] as Vector3).y
	var der: MeshInstance3D = _p(top_piv, I._boxm(Vector3(0.13, 0.025, 0.018)), _mat(Color(1.0, 0.82, 0.35), 1.0, 0.3), Vector3(0, der_y, 0))
	var st := {"occupe": false, "fini": tient and bool(M.state().get("hf_colonne", false)), "essais": int(M.state().get("hf_essais", 0))}
	der.visible = bool(st["fini"])
	# le grand-père (il termine sa tour) et l'enfant (qui retient son souffle)
	var papi: Node = M.person("vieux", tx + 0.75, tz + 0.2, _vers(tx + 0.75, tz + 0.2, tx, tz), "mains_dos" if bool(st["fini"]) else "bricoler")
	papi.lines = ["Doucement… tout doucement…", "Une de plus. Une de moins à poser.", "Ne claque pas la porte, surtout !", "Ma colle sèche plus vite que moi."]
	papi.line_every = Vector2(8.0, 12.0)
	var boy: bool = r.randf() < 0.5
	var kx: float = tx - 0.75
	var kz: float = tz + 0.45
	var kid: Node = M.person("garcon" if boy else "fille", kx, kz, _vers(kx, kz, tx, tz), "debout")
	var souffle: String = "(Il retient son souffle.)" if boy else "(Elle retient son souffle.)"
	kid.lines = ["Chuuut…", "Personne ne respire !", "Papi, tes mains tremblent !", "Encore une… encore une…", souffle]
	kid.line_every = Vector2(6.0, 9.0)
	var poser := func() -> void:
		if bool(st["occupe"]) or bool(st["fini"]):
			return
		st["occupe"] = true
		st["essais"] = int(st["essais"]) + 1
		M.state()["hf_essais"] = int(st["essais"])
		var dpos: Vector3 = Vector3(0, der_y, 0)
		der.visible = true
		der.position = dpos + Vector3(0, 0.25, 0)
		var tw: Tween = M.room.create_tween()
		tw.tween_property(der, "position", dpos, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		M.main.sfx("touche_bois", der.global_position)
		kid.set_pose("cache")
		kid.say(str(_pick(M, [souffle, "Chhhhut…", "Personne ne respire !"])), 2.0)
		# la tour hésite… (elle penche un peu, de plus en plus fort vers le haut)
		for i in range(morceaux.size()):
			var pv: Node3D = morceaux[i][0]
			var p0: Vector3 = morceaux[i][1]
			var off: float = 0.012 * float(i + 1) / float(morceaux.size())
			var tw2: Tween = M.room.create_tween()
			tw2.tween_interval(0.6)
			tw2.tween_property(pv, "position:x", p0.x + off, 0.3).set_trans(Tween.TRANS_SINE)
			tw2.tween_property(pv, "position:x", p0.x - off, 0.45).set_trans(Tween.TRANS_SINE)
			tw2.tween_property(pv, "position:x", p0.x, 0.3).set_trans(Tween.TRANS_SINE)
		await M.get_tree().create_timer(1.9).timeout
		if not _la(M, room0):
			return
		kid.set_pose("debout")
		var premier: bool = not bool(M.state().get("hf_allumettes", false))
		M.state()["hf_allumettes"] = true
		if tient:
			st["fini"] = true
			M.state()["hf_colonne"] = true
			M.main.sfx("confettis", der.global_position)
			_bulle(M, der.global_position + Vector3(0, 0.3, 0), "Elle tient !", Color(1.0, 0.9, 0.4), 50, 0.6, 2.2)
			papi.set_pose("applaudir")
			kid.set_pose("applaudir")
			if premier:
				M.talk(papi, "ELLE TIENT ! Essai numéro %d, et c'est toi qui poses la dernière ! Tu as des mains d'horloger. Tiens, ta part du trésor : la boîte à biscuits de la victoire." % (46 + int(st["essais"])),
					I._bye("Bravo à vous !"), func(_i):
					M.give([["biscuit_engrenage", 1], ["piece", 8 + r.randi() % 8]], "")
					M.close_talk(), "ému")
			await M.get_tree().create_timer(4.0).timeout
			if _la(M, room0):
				papi.set_pose("mains_dos")
				kid.set_pose("debout")
			st["occupe"] = false
			return
		# patatras ! les morceaux tombent, du haut vers le bas
		M.main.sfx("touche_bois", R.P(tx, 1.0, tz))
		M.main.sfx("pop", R.P(tx, 1.5, tz))
		var cbt: Node = M.main.get("combat_v28")
		if cbt != null and cbt.has_method("puff"):
			cbt.puff(R.P(tx, 1.4, tz), Color(0.95, 0.75, 0.3))
		var sol: float = R.P(0, 0.07, 0).y
		for i2 in range(morceaux.size()):
			var pv2: Node3D = morceaux[i2][0]
			var p2: Vector3 = morceaux[i2][1]
			var ang: float = randf() * TAU
			var dist: float = 0.25 + 0.1 * i2 + randf() * 0.3
			var tw3: Tween = M.room.create_tween()
			tw3.tween_interval(float(morceaux.size() - 1 - i2) * 0.07)
			tw3.tween_property(pv2, "position", Vector3(p2.x + cos(ang) * dist, sol, p2.z + sin(ang) * dist), 0.5 + i2 * 0.05).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tw3.parallel().tween_property(pv2, "rotation", Vector3(randf_range(-1.5, 1.5), randf() * 3.0, randf_range(-1.5, 1.5)), 0.5 + i2 * 0.05)
		_bulle(M, R.P(tx, 1.9, tz), "Patatras !", Color(1.0, 0.8, 0.5), 50, 0.5, 2.0)
		papi.gesture("rire", 3.0)
		kid.gesture("rire", 3.0)
		if premier:
			M.talk(papi, "HA HA HA ! Patatras ! Ce n'est rien : c'est la prochaine qui sera la bonne. Tiens, un jus de pomme pour te remettre de tes émotions.",
				I._bye("Pardon !"), func(_i):
				M.give([["jus_pomme", 1], ["piece", 3 + r.randi() % 4]], "")
				M.close_talk(), "hilare")
		else:
			S._say_late(M, papi, str(_pick(M, ["Ha ha ! Essai numéro %d !" % (47 + int(st["essais"])), "Elle n'aime pas qu'on la presse, la Colonne !", "Encore ! J'adore quand elle fait ça."])), 1.0)
		# on ramasse tout en riant, et la Colonne est de nouveau debout
		await M.get_tree().create_timer(4.5).timeout
		if not _la(M, room0):
			return
		M.main.sfx("touche_bois", R.P(tx, 0.5, tz))
		for i3 in range(morceaux.size()):
			var pv3: Node3D = morceaux[i3][0]
			var tw4: Tween = M.room.create_tween()
			tw4.tween_interval(i3 * 0.12)
			tw4.tween_property(pv3, "position", morceaux[i3][1], 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw4.parallel().tween_property(pv3, "rotation", Vector3.ZERO, 0.5)
		der.visible = false
		der.position = dpos
		papi.say(str(_pick(M, ["Bon. On recommence. J'ai l'habitude.", "Hop ! Elle est debout. Il ne manque que la dernière… encore.", "Allez, on reconstruit. C'est le meilleur moment."])), 3.5)
		await M.get_tree().create_timer(1.5).timeout
		st["occupe"] = false
	# ce qui bouge tout seul : la tour tremble un tout petit peu quand on s'approche
	var centre: Vector3 = R.P(tx, 0, tz)
	st["t"] = 0.0
	M.ctx["tick"] = func(dt: float) -> void:
		if bool(st["occupe"]) or not is_instance_valid(top_piv):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var pp: Vector3 = M.main._player_pos_v27()
		var pres: float = clampf(1.0 - Vector2(pp.x - centre.x, pp.z - centre.z).length() / 1.6, 0.0, 1.0)
		for i in range(morceaux.size()):
			var pv: Node3D = morceaux[i][0]
			var p0: Vector3 = morceaux[i][1]
			pv.position.x = p0.x + pres * 0.004 * float(i + 1) / float(morceaux.size()) * sin(t * 9.0 + i * 0.4)
	M.act(R.P(tx, 0, tz + 0.75), "E : poser la dernière allumette au sommet", func(): poser.call(), 1.0, func(): return not bool(st["fini"]) and not bool(st["occupe"]))
	M.act(R.P(tx, 0, tz + 0.75), "E : admirer la Colonne en allumettes", func(): M.say("La Grande Colonne en allumettes, entière, avec sa dernière allumette tout en haut. Personne n'ose plus éternuer dans cette maison.", 5.0), 1.0, func(): return bool(st["fini"]))
	var papi_cb := func() -> void:
		if bool(st["fini"]):
			M.talk(papi, "Elle tient toujours ! Je ne la touche plus, je ne respire plus à côté, et je l'époussette avec une plume. Merci encore, petite main d'or.", I._bye("Elle est magnifique !"), I._close(M), "fier")
			return
		M.talk(papi, "Chut… Quatre mille deux cent douze allumettes : la Grande Colonne, au millième. Il ne manque que la dernière, tout en haut. Mes mains tremblent un peu… Tu veux la poser ?",
			[{"id": "poser", "label": "Je la pose !"}, {"id": "tombe", "label": "Et si elle tombe ?"}, {"id": "fermer", "label": "Je n'ose pas…"}], func(id):
			match id:
				"poser":
					M.close_talk()
					poser.call()
				"tombe":
					M.talk(papi, "Alors on rira, et on recommencera. C'est mon essai numéro %d. Ma femme dit que je suis têtu. Moi, je dis : patient." % (47 + int(st["essais"])), I._bye("Ha ha !"), I._close(M))
				_:
					M.close_talk()
		, "concentré")
	M.talk_spot(papi, papi_cb)
	if bool(st["fini"]):
		M.ctx["entree"] = "La Grande Colonne en allumettes trône au milieu du salon, entière, avec sa dernière allumette tout en haut. Le grand-père l'époussette avec une plume."
	else:
		M.ctx["entree"] = str(_pick(M, ["Chut ! Au milieu du salon, une Grande Colonne en allumettes, haute comme un enfant. Il ne manque que la dernière, tout en haut.",
			"Un grand-père, une pince, et une tour d'allumettes dorées : la Grande Colonne en miniature. Personne ne respire.",
			"Des boîtes d'allumettes partout. Au milieu, une tour fine et dorée tremble un tout petit peu quand on marche."]))


# =================================================================== la poste pneumatique

## [ce qu'on lit à voix haute, ce qu'on lit soi-même]
const CAPSULES := [
	["« Votre coucou chante un quart de ton trop haut. Rapportez-le. » Signé Gaspard.", "De Gaspard Ressort, horloger : « Cher client, votre coucou chante un quart de ton trop haut. Merci de le rapporter à la boutique. Il sait ce qu'il a fait. »"],
	["Facture du Piston Joyeux : nettoyage de moustache, deux pièces !", "Facture du Piston Joyeux : « Un chocolat chaud : 4 pièces. Nettoyage de la moustache (la vôtre, tombée dedans) : 2 pièces. Sifflet de seize heures : offert. » Signé : Firmin Bouilloire."],
	["« Le Bourgmestre répète ses discours devant sa glace. La glace a demandé un congé. »", "Potin du Grand Marché, signé Rosalie Cannelle : « Il paraît que le Bourgmestre répète ses discours devant sa glace. La glace a demandé un congé. Je n'ai rien dit. »"],
	["« Chère Pendule du salon, mon cœur fait tic-tac-tic. Ta Comtoise. »", "Un mot d'amour, d'une écriture très régulière : « Chère Pendule du salon, depuis que je t'ai entendue sonner midi, mon cœur fait tic-tac-tic. Je retarde quand tu n'es pas là. Ta Comtoise. »"],
	["Objets trouvés, cabine trois : un parapluie et le courage de Barnabé.", "De la Confrérie des Liftiers : « Objets trouvés dans la cabine numéro trois : un parapluie, un chapeau à plume et le courage de Barnabé. Merci de venir les réclamer au guichet. Surtout le courage. » Maîtresse Capucine Rouage."],
	["Invitation : la nouvelle poubelle de la Place. Discours de deux heures.", "Du Bourgmestre Hector Bellevue : « Vous êtes invité à l'inauguration de la nouvelle poubelle de la Place de la Colonne. Discours de deux heures. Tenue correcte exigée. Bâillements interdits. »"],
	["« Une étoile m'a fait un clin d'œil. Je vous écris pour avoir un témoin. »", "Du Professeur Octave Lunette, à l'Observatoire : « Une étoile m'a fait un clin d'œil hier soir, à vingt-trois heures douze. Je vous écris pour qu'il y ait un témoin. Gardez cette capsule. »"],
	["« Avez-vous des boulons ? Même un tout petit ? » Pimprenelle, neuf ans.", "D'une écriture toute ronde : « Bonjour, avez-vous des boulons ? Même un petit. Même un tout petit. Répondez par capsule, c'est urgent. Pimprenelle, neuf ans, future Grande Liftière. »"],
]

## La poste pneumatique : un tube de cuivre descend du plafond ; toutes les dix secondes environ,
## « Pfft… POP ! », une capsule de laiton jaillit et tombe dans le panier. Un notaire (ou une
## romancière) très occupé(e) les lit à voix haute : potins, factures absurdes, mots d'amour
## d'horloges… On peut lire une capsule soi-même (huit messages) ; si on aide à trier, la capsule
## « Au visiteur » qui attendait au fond du panier est pour nous (une seule fois).
static func _pneumatique(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# le bureau : sa chaise, ses piles de papiers, l'encrier et sa plume, la bougie
	var dx: float = -R.W * 0.18
	var dz: float = -hd + 1.3
	R.tapis(dx, dz + 0.3, 0, 2.2, 1.6)
	R.table(dx, dz, 0, 1.4, 0.75, 0.76)
	R.chaise(dx, dz - 0.62, 0)
	for k in range(3):
		var ph: float = 0.05 + r.randf() * 0.12
		R.kit.box(R.L(dx - 0.5 + k * 0.18, 0.76 + ph * 0.5, dz + 0.15, r.randf_range(-8, 8)), Vector3(0.16, ph, 0.22), "papier", 1.0)
	R.kit.cyl(R.L(dx + 0.45, 0.76, dz + 0.1), 0.035, 0.03, 0.06, "noir", 10)
	R.kit.box(R.L(dx + 0.47, 0.84, dz + 0.1) * Transform3D(Basis(Vector3.BACK, 0.35), Vector3.ZERO), Vector3(0.012, 0.2, 0.004), "tissu_blanc", 1.0)
	R.kit.box(R.L(dx + 0.1, 0.762, dz + 0.05, 8), Vector3(0.21, 0.004, 0.29), "papier", 1.0, 4)
	R.bougie(dx + 0.6, 0.76, dz - 0.15, true)
	_poele(M, hw - 0.85, -hd + 0.6, 0)
	if R.is_free(-hw + 0.4, hd * 0.15, 0.6, 1.1):
		R.etagere(-hw + 0.22, hd * 0.15, 90, 1.0, 1.8, true, 4)
	_cadres(M, 2)
	# le tube de cuivre (du plafond à sa bouche), et le panier au pied
	var px: float = dx + 1.25
	var pz: float = -hd + 0.16
	R.mark_wall(px, 1.6, -hd + 0.02, 0.35)
	R.kit.cyl(R.L(px, 1.05, pz), 0.07, 0.07, R.H - 1.05, "cuivre", 14)
	for k2 in range(3):
		R.kit.ring(R.L(px, 1.35 + k2 * 0.55, pz), 0.07, 0.085, 0.04, "or", 14)
	R.kit.box(R.L(px, 0.98, pz + 0.06), Vector3(0.22, 0.18, 0.2), "cuivre", 1.0)
	R.kit.box(R.L(px, 0.96, pz + 0.165), Vector3(0.14, 0.1, 0.01), "noir", 1.0)
	R.kit.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), R.P(px + 0.075, 1.04, pz + 0.16)), 0.018, 0.018, 0.02, "or", 8)
	var bz: float = pz + 0.65
	R.kit.cyl(R.L(px, 0.0, bz), 0.22, 0.22, 0.02, "bois_sombre", 16)
	R.kit.ring(R.L(px, 0.0, bz), 0.22, 0.245, 0.3, "bois_clair", 18)
	R.reserve(px, bz - 0.2, 0.7, 0.9)
	var bouche: Vector3 = R.P(px, 0.96, pz + 0.2)
	# les capsules (on les réutilise : le panier n'en garde que six)
	var laiton := _mat(Color(0.88, 0.68, 0.3), 0.9, 0.35)
	var cuivre := _mat(Color(0.8, 0.46, 0.26), 0.9, 0.32)
	var caps: Array = []
	for k3 in range(6):
		var cap := Node3D.new()
		M.room.add_child(cap)
		_p(cap, I._cyl(0.035, 0.035, 0.14, 12), laiton if k3 % 2 == 0 else cuivre, Vector3.ZERO, Vector3.ONE, Vector3(0, 0, PI * 0.5))
		_p(cap, I._sph(0.035), laiton, Vector3(0.07, 0, 0))
		_p(cap, I._sph(0.035), laiton, Vector3(-0.07, 0, 0))
		cap.global_position = R.P(px + r.randf_range(-0.1, 0.1), 0.06 + (k3 % 2) * 0.05, bz + r.randf_range(-0.1, 0.1))
		cap.rotation.y = r.randf() * PI
		cap.visible = k3 < 3
		caps.append(cap)
	# le notaire (ou la romancière), à son bureau
	var notaire: bool = r.randf() < 0.5
	var f: Node
	if notaire:
		f = M.person(str(_pick(M, ["homme", "vieux"])), dx, dz - 0.62, 0, "lire", "Maître " + str(_pick(M, ["Philémon Paraphe", "Aristide Tampon", "Honoré Virgule", "Anatole Codicille"])))
		f.lines = ["Signé, paraphé, tamponné !", "Encore une !", "Où ai-je mis mon tampon ?", "Classé. Suivant !"]
	else:
		f = M.person(str(_pick(M, ["femme", "vieille"])), dx, dz - 0.62, 0, "lire", "Madame " + str(_pick(M, ["Victorine Plume", "Hortense Chapitre", "Eulalie Encrier", "Léontine Feuilleton"])))
		f.lines = ["Quelle histoire !", "Chapitre douze !", "Ça, je le mets dans mon roman.", "Encore un rebondissement !"]
	f.line_every = Vector2(9.0, 14.0)
	var st := {"t": 6.0 + r.randf() * 3.0, "pfft": false, "n": 3, "lu": r.randi() % CAPSULES.size(), "lit": r.randi() % CAPSULES.size()}
	var arrivee := func() -> void:
		var cap2: Node3D = caps[int(st["n"]) % caps.size()]
		st["n"] = int(st["n"]) + 1
		cap2.visible = true
		cap2.global_position = bouche
		cap2.rotation = Vector3(0, PI * 0.5, 0)
		var to: Vector3 = R.P(px + randf_range(-0.12, 0.12), 0.06 + randf() * 0.06, bz + randf_range(-0.1, 0.1))
		var tw: Tween = M.room.create_tween()
		tw.tween_method(func(k4: float) -> void:
			cap2.global_position = bouche.lerp(to, k4) + Vector3(0, sin(k4 * PI) * 0.35, 0), 0.0, 1.0, 0.55)
		tw.parallel().tween_property(cap2, "rotation", Vector3(randf_range(-0.3, 0.3), randf() * TAU, TAU * 1.5), 0.55)
		M.main.sfx("pop", bouche)
		_bulle(M, bouche + Vector3(0, 0.35, 0.1), "POP !", Color(1.0, 0.85, 0.5), 44, 0.4, 1.2)
		var j: int = int(st["lit"])
		st["lit"] = j + 1
		if not bool(f.talking):
			S._say_late(M, f, str(CAPSULES[j % CAPSULES.size()][0]), 1.4, 5.0)
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(f.npc):
			return
		st["t"] = float(st["t"]) - dt
		if float(st["t"]) <= 0.8 and not bool(st["pfft"]):
			st["pfft"] = true
			M.main.sfx("vapeur", bouche + Vector3(0, 0.6, 0))
			_bulle(M, bouche + Vector3(0, 0.9, 0.1), "Pfft…", Color(0.9, 0.95, 1.0), 36, 0.3, 1.0)
		if float(st["t"]) <= 0.0:
			st["t"] = 9.0 + randf() * 3.0
			st["pfft"] = false
			arrivee.call()
	# lire une capsule soi-même ; aider à trier (la capsule « Au visiteur », une fois)
	M.act(R.P(px, 0, bz + 0.45), "E : lire une capsule", func() -> void:
		var i: int = int(st["lu"])
		st["lu"] = i + 1
		M.main.sfx("page")
		M.say(str(CAPSULES[i % CAPSULES.size()][1]), 8.0)
		if not bool(f.talking) and randf() < 0.5:
			S._say_late(M, f, str(_pick(M, ["Hé ! C'est mon courrier !", "Tu lis par-dessus mon épaule, toi ?", "Bon… tant que tu ne le répètes pas à Rosalie."])), 1.5)
	, 1.0)
	var f_cb := func() -> void:
		M.talk(f, str(_pick(M, ["Bonjour, bonjour ! Pardon, je n'ai qu'une minute : le tube n'arrête pas. Quarante capsules par jour !",
			"Entrez ! Attention au panier. Ici, le courrier arrive par le plafond, et il n'attend pas."])),
			[{"id": "courrier", "label": "Vous recevez beaucoup de courrier ?"}, {"id": "trier", "label": "Je peux vous aider à trier ?"}, {"id": "fermer", "label": "Je vous laisse travailler."}], func(id):
			match id:
				"courrier":
					M.talk(f, "À Hautefond, tout le monde s'écrit ! Même les voisins de palier. Surtout eux. Et moi, je suis notaire : on m'envoie tout ce qui est important. Et tout le reste." if notaire else "À Hautefond, tout le monde s'écrit ! Même les voisins de palier. Surtout eux. Et moi, je suis romancière : on m'envoie tout ce qui est important. Et tout le reste.", I._bye("Ha ha !"), I._close(M))
				"trier":
					if bool(M.state().get("hf_pneumatique", false)):
						M.talk(f, "Merci, mais tu as déjà tout trié l'autre jour ! Ah, non… en voilà trois autres. Pfft… POP ! Bon, on s'y remet.", I._bye("Courage !"), I._close(M))
						return
					M.state()["hf_pneumatique"] = true
					M.talk(f, "Volontiers ! Les potins à gauche, les factures à droite, les mots d'amour d'horloges au milieu… Merci ! Tiens, la capsule « Au visiteur » qui attendait au fond du panier : elle est pour toi.", I._bye("Pour moi ?"), func(_i):
						M.give([["piece", 6 + r.randi() % 6], ["boulon", 1]], "Dans la capsule : quelques pièces, et un boulon. Le boulon, c'est sûrement Pimprenelle. ")
						M.close_talk())
				_:
					M.close_talk()
		, "débordé" if notaire else "débordée")
	M.talk_spot(f, f_cb, "E : parler au notaire" if notaire else "E : parler à la romancière")
	M.ctx["entree"] = str(_pick(M, ["Pfft… POP ! Une capsule de laiton jaillit d'un tube de cuivre et tombe dans un panier. Derrière son bureau, quelqu'un soupire : « Encore une ! »",
		"Un tube de cuivre descend du plafond, un panier déborde de capsules. Ici, le courrier arrive tout seul. Et souvent.",
		"Des piles de papiers, un encrier, une bougie… et un tube de cuivre qui crache des capsules toutes les dix secondes."]))


# =================================================================== le piano mécanique

## Les trois rouleaux : [nom, titre de la bulle, couleur des notes, vitesse du rouleau, des touches,
## une note toutes les… secondes]
const AIRS := {
	"valse": ["Mettre la valse", "♪ La valse ! ♪", Color(1.0, 0.85, 0.55), 1.6, 3.0, 0.9],
	"marche": ["Mettre la marche des liftiers", "♪ La marche des liftiers ! ♪", Color(0.75, 0.9, 1.0), 2.6, 5.0, 0.55],
	"berceuse": ["Mettre la berceuse de la Colonne", "♪ La berceuse de la Colonne… ♪", Color(0.85, 0.75, 1.0), 0.7, 1.4, 1.6],
}

## Le piano mécanique : un piano qui joue tout seul (ses touches s'enfoncent, son rouleau tourne, des
## notes s'envolent en bulles) ; une grand-mère danse avec un enfant. On peut changer le rouleau, et
## ça change ce que font les gens : la valse (ils tournent ensemble), la marche des liftiers (l'enfant
## défile, la grand-mère tape dans ses mains), la berceuse de la Colonne (ils s'endorment sur le
## canapé). Danser avec eux, la première fois : un pain de miel.
static func _pianola(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# le piano contre le mur du fond (et son banc, vide), le canapé, le poêle
	var px: float = R.W * 0.12
	var pz: float = -hd + 0.45
	R.piano(px, pz, 0)
	R.banc(px, pz + 0.85, 0, 0.9)
	R.bougie(px - 0.55, 1.24, pz - 0.1, true)
	R.plante(px + 0.4, pz - 0.12, 1.24, 0.55)
	var sx: float = -hw + 0.62
	R.canape(sx, 0.0, 90, "rouge")
	_poele(M, hw - 0.6, -hd + 1.0, -90)
	_cadres(M, 2)
	var cx: float = -R.W * 0.1
	var cz: float = -hd * 0.1 + 0.15
	R.tapis(cx, cz, 0, 2.2, 1.8)
	# ce qui bouge sur le piano : quatorze touches, le rouleau perforé dans sa fenêtre de laiton
	var pia: Node3D = I._node(M, R.P(px, 0, pz), 0)
	var ivoire := _mat(Color(0.96, 0.94, 0.88), 0.0, 0.3)
	var laiton := _mat(Color(0.88, 0.68, 0.3), 0.9, 0.35)
	var papier := _mat(Color(0.93, 0.89, 0.78), 0.0, 0.9)
	var noir := _mat(Color(0.06, 0.06, 0.06), 0.0, 0.8)
	var touches: Array = []
	var kmesh: BoxMesh = I._boxm(Vector3(0.082, 0.02, 0.07))
	for k in range(14):
		touches.append([_p(pia, kmesh, ivoire, Vector3(-0.6 + k * 0.093, 0.782, 0.305)), r.randf() * TAU, r.randf_range(0.7, 1.3)])
	_p(pia, I._boxm(Vector3(0.62, 0.16, 0.02)), laiton, Vector3(0, 1.02, 0.155))
	_p(pia, I._boxm(Vector3(0.56, 0.12, 0.01)), noir, Vector3(0, 1.02, 0.166))
	for sxk in [-1.0, 1.0]:
		_p(pia, I._boxm(Vector3(0.02, 0.12, 0.08)), laiton, Vector3(sxk * 0.27, 1.02, 0.19))
	var rou := Node3D.new()
	pia.add_child(rou)
	rou.position = Vector3(0, 1.02, 0.2)
	_p(rou, I._cyl(0.05, 0.05, 0.5, 16), papier, Vector3.ZERO, Vector3.ONE, Vector3(0, 0, PI * 0.5))
	for k5 in range(10):
		var a5: float = r.randf() * TAU
		_p(rou, I._boxm(Vector3(0.03, 0.006, 0.012)), noir, Vector3(r.randf_range(-0.22, 0.22), cos(a5) * 0.051, sin(a5) * 0.051), Vector3.ONE, Vector3(a5, 0, 0))
	# la grand-mère et l'enfant
	var mamie: Node = M.person("vieille", cx - 0.42, cz, 90, "danse")
	var boy: bool = r.randf() < 0.5
	var kid: Node = M.person("garcon" if boy else "fille", cx + 0.42, cz, -90, "danse")
	var st := {"t": 0.0, "air": str(_pick(M, ["valse", "valse", "marche", "berceuse"])), "pret": false, "ang": PI, "ph": 0.0, "note": 1.0}
	var jouer := func(air: String, direct: bool) -> void:
		st["air"] = air
		st["pret"] = false
		st["ph"] = 0.0
		papier.albedo_color = Color(0.93, 0.89, 0.78).lerp(AIRS[air][2], 0.35)
		var tm: Vector3
		var tk: Vector3
		match air:
			"valse":
				var a: float = float(st["ang"])
				tm = R.P(cx + cos(a) * 0.42, 0, cz + sin(a) * 0.42)
				tk = R.P(cx - cos(a) * 0.42, 0, cz - sin(a) * 0.42)
				mamie.lines = ["Un, deux, trois ! Un, deux, trois !", "Tu me marches sur les pieds, mon trésor !", "Comme au bal des Liftiers !"]
				kid.lines = ["On tourne ! On tourne !", "J'ai le tournis !", "Plus vite, Mamie !"]
			"marche":
				tm = R.P(cx, 0, cz - 0.55)
				tk = R.P(cx, 0, cz + 0.25)
				mamie.lines = ["Une, deux ! Une, deux !", "Tenez la rampe !", "Le menton haut, liftier !", "Ça monte !"]
				kid.lines = ["Ça monte !", "Tout le monde descend !", "Une, deux ! Une, deux !", "Par la Colonne !"]
			_:
				tm = R.P(sx + 0.06, 0, -0.475)
				tk = R.P(sx + 0.06, 0, 0.475)
				mamie.lines = ["Zzz… ça monte… zzz…", "Zzz…"]
				kid.lines = ["Zzz…", "Mmh… encore une chanson… zzz…"]
		var fin := func() -> void:
			st["pret"] = true
			match air:
				"valse":
					mamie.set_pose("danse")
					kid.set_pose("danse")
				"marche":
					mamie.set_pose("applaudir", Vector3(0, 0, 1))
					kid.set_pose("marcher", Vector3(1, 0, 0))
				_:
					mamie.set_pose("dormir_assis", Vector3(1, 0, 0))
					kid.set_pose("dormir_assis", Vector3(1, 0, 0))
		if direct:
			mamie.npc.global_position = tm
			kid.npc.global_position = tk
			fin.call()
			return
		var tw: Tween = M.room.create_tween()
		tw.set_parallel(true)
		for e in [[mamie, tm], [kid, tk]]:
			var fg: Node = e[0]
			var to: Vector3 = e[1]
			var from: Vector3 = fg.npc.global_position
			if from.distance_to(to) > 0.05:
				fg.set_pose("marcher", Vector3(to.x - from.x, 0, to.z - from.z))
				tw.tween_property(fg.npc, "global_position", to, clampf(from.distance_to(to) / 0.7, 0.3, 3.0))
		tw.chain().tween_callback(fin)
	var changer := func(air: String) -> void:
		M.main.sfx("clic", rou.global_position)
		M.main.sfx("installe", rou.global_position)
		var tw2: Tween = M.room.create_tween()
		tw2.tween_property(rou, "position:x", 0.6, 0.35).set_trans(Tween.TRANS_QUAD)
		tw2.tween_property(rou, "position:x", 0.0, 0.35).set_trans(Tween.TRANS_QUAD)
		_bulle(M, pia.global_position + Vector3(0, 1.55, 0.1), str(AIRS[air][1]), AIRS[air][2], 40, 0.5, 2.2)
		jouer.call(air, false)
		M.main.sfx("luth", pia.global_position + Vector3(0, 1.0, 0))
	jouer.call(str(st["air"]), true)
	var choisir := func() -> void:
		var ch: Array = []
		for k6 in ["valse", "marche", "berceuse"]:
			if k6 != str(st["air"]):
				ch.append({"id": k6, "label": str(AIRS[k6][0])})
		ch.append({"id": "fermer", "label": "Laisser celui-là"})
		M.talk(mamie, "Le rouleau ? Il y en a trois dans le tiroir : la valse, la marche des liftiers, et la berceuse de la Colonne. Lequel ?", ch, func(id):
			M.close_talk()
			if id != "fermer":
				changer.call(str(id)), "malicieuse")
	var mamie_cb := func() -> void:
		var dort: bool = str(st["air"]) == "berceuse"
		var t0: String = "Hein ? Quoi ? Je ne dormais pas ! Je… réfléchissais en musique." if dort else str(_pick(M, ["Ah, de la visite ! Tu danses ? Ce piano joue tout seul depuis que mon mari l'a gagné à la tombola des Liftiers.",
			"Entre, entre ! Ici, on danse du matin au soir. Le piano ne connaît que trois airs, et nous aussi."]))
		M.talk(mamie, t0, [{"id": "danser", "label": "Je peux danser avec vous ?"}, {"id": "rouleau", "label": "Changer le rouleau"}, {"id": "fermer", "label": "Au revoir !"}], func(id):
			match id:
				"danser":
					if str(st["air"]) == "berceuse":
						changer.call("valse")
					if not bool(M.state().get("hf_pianola", false)):
						M.state()["hf_pianola"] = true
						M.talk(mamie, "Avec plaisir ! Un, deux, trois… un, deux, trois… Tu as le pied léger ! Tiens, un pain de miel : on danse mieux le ventre plein.", I._bye("Merci, mamie !"), func(_i):
							M.give([["pain_miel", 1], ["piece", 3 + r.randi() % 5]], "")
							M.close_talk())
					else:
						M.talk(mamie, "Encore ? Volontiers ! Un, deux, trois… Ha ha ! Tu danses mieux que mon mari. Ne le lui dis pas.", I._bye("Promis !"), I._close(M))
				"rouleau":
					choisir.call()
				_:
					M.close_talk()
		, "pétillante")
	var it_mamie: Dictionary = M.talk_spot(mamie, mamie_cb)
	M.act(R.P(px + 0.75, 0, pz + 0.85), "E : changer le rouleau du piano", func(): choisir.call(), 1.0)
	# le piano joue tout seul ; les gens dansent, défilent ou dorment selon le rouleau
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(rou):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var air: String = str(st["air"])
		var info: Array = AIRS[air]
		rou.rotation.x += dt * float(info[3])
		for e in touches:
			var v: float = sin(t * float(info[4]) * float(e[2]) + float(e[1]))
			(e[0] as Node3D).position.y = 0.782 - (0.012 if v > 0.75 else 0.0)
		st["note"] = float(st["note"]) - dt
		if float(st["note"]) <= 0.0:
			st["note"] = float(info[5]) * randf_range(0.8, 1.2)
			var n: String = ["♪", "♫", "♪ ♫", "♬"][randi() % 4] if air != "berceuse" else ["♪", "♪ zzz", "♫"][randi() % 3]
			_bulle(M, pia.global_position + Vector3(randf_range(-0.5, 0.5), 1.35, 0.1), n, info[2], 40, 0.6, 1.8)
		it_mamie["pos"] = mamie.npc.global_position + Vector3.UP * 0.05
		if not bool(st["pret"]) or bool(mamie.talking):
			return
		match air:
			"valse":
				var a: float = float(st["ang"]) + dt * 0.9
				st["ang"] = a
				var pm: Vector3 = R.P(cx + cos(a) * 0.42, 0, cz + sin(a) * 0.42)
				var pk: Vector3 = R.P(cx - cos(a) * 0.42, 0, cz - sin(a) * 0.42)
				mamie.npc.global_position = pm
				kid.npc.global_position = pk
				mamie.face_dir = pk - pm
				kid.face_dir = pm - pk
			"marche":
				var ph: float = float(st["ph"]) + dt * 0.8
				st["ph"] = ph
				kid.npc.global_position = R.P(cx + sin(ph) * 0.7, 0, cz + 0.25)
				kid.face_dir = Vector3(1, 0, 0) if cos(ph) > 0.0 else Vector3(-1, 0, 0)
	match str(st["air"]):
		"valse":
			M.ctx["entree"] = "♪ Un, deux, trois… ♪ Un piano joue tout seul, ses touches s'enfoncent comme par magie. Une grand-mère valse avec un enfant."
		"marche":
			M.ctx["entree"] = "♪ Pom, pom, pom ! ♪ Un piano mécanique joue la marche des liftiers. Un enfant défile au pas, sa grand-mère tape dans ses mains."
		_:
			M.ctx["entree"] = "♪ Dodo, la Colonne… ♪ Un piano joue tout seul une berceuse. Sur le canapé, une grand-mère et un enfant se sont endormis."
