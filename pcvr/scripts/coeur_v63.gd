extends Node3D
## V63 : les règles du donjon du Cœur-de-Pierre (la géométrie est dans coeur_salles_v63.gd).
## Le donjon n'est construit qu'à la première descente (ou au chargement d'une partie sauvée
## dedans) : il ne coûte rien tant qu'on reste à la surface.
##  - Les invites « E » passent par donjon_v35._interactions ; les pouvoirs des sceaux visent
##    des cibles inscrites dans pouvoirs_v63.
##  - Chaque salle a son point de reprise : une chute dans un gouffre, ou un évanouissement, y
##    ramène (une chute coûte un cœur ; dans le bassin des Marées, on nage jusqu'au rebord).
##  - Les pièges (geysers, vagues, sables mouvants, lames, dards, pistons, tapis roulants,
##    mains d'ombre) tournent à chaque image, seulement dans l'aile où l'on est.
##  - Les monstres d'une salle arrivent la première fois qu'on y entre (à chaque descente) ;
##    les gardiens des ailes et le Gardien du Cœur restent vaincus une fois pour toutes.

const Salles = preload("res://scripts/coeur_salles_v63.gd")
const BossScript = preload("res://scripts/boss_coeur_v63.gd")
const O := Vector3(940.0, -120.0, -150.0)
const WINGS := ["marees", "sables", "rouages", "lune"]
const BOSS_OF := {"marees": "garde_maree", "sables": "scorpion_roi", "rouages": "colosse", "lune": "loup_brumes"}
const WATER := [-4.6, -2.3, -0.3]                  # niveaux de l'eau des écluses (sous le rebord)
const BRAZIER_ORDER := ["est", "sud", "ouest", "nord"]
const PHASES := ["la nouvelle lune", "la lune croissante", "la pleine lune", "la lune décroissante"]
const DIAL_GOAL := [2, 3, 0, 1]
const DIAL_START := [0, 0, 1, 2]
const ORDINAL := ["premier", "deuxième", "troisième", "quatrième"]
## Les monstres de chaque salle : [espèce, x, z] dans le repère de l'aile (z compté depuis le
## bout du couloir d'entrée).
const ROOM_SPAWNS := {
	"marees_a": [["ondin", -6.0, 28.0], ["ondin", 6.0, 28.0]],
	"marees_b": [["crabe", -2.0, 46.0], ["crabe", 2.5, 58.0], ["ondin", 0.0, 66.0]],
	"sables_a": [["scorpion", 11.0, 9.0], ["scorpion", -11.0, 21.0], ["scorpion", 6.0, 27.0]],
	"sables_b": [["scorpion", -2.0, 50.0], ["scorpion", 2.0, 64.0]],
	"rouages_a": [["automate", -5.0, 28.0], ["automate", 5.0, 28.0]],
	"rouages_b": [["automate", -3.0, 40.0], ["armure", 3.0, 70.0]],
	"lune_a": [["spectre", 0.0, 16.0], ["spectre", 3.0, 28.0]],
	"lune_b": [["spectre", -2.0, 58.0], ["spectre", 2.0, 70.0]],
}

var main: Node
var salles: Node3D
var built: bool = false
var state: Dictionary = {}
var fight: bool = false                         # un gardien (ou le Gardien du Cœur) combat
var room: String = ""
var checkpoint: Array = []                      # [position, regard]
var _boss: Node3D
var _boss_wing: String = ""
var _bar_vr: Label3D
var _room_monsters: Dictionary = {}             # salle -> [monstres]
var _crystals: Dictionary = {}                  # aile -> {node, mat}
var _circles: Dictionary = {}
var _heart_exit: Node3D
var _beam: Node3D
var _was_in: bool = false
var _clock: float = 0.0
var _said: Dictionary = {}
var _final_wait: float = -1.0
var _victory: bool = false
# pièges
var _water_y: float = 0.0
var _water_target: float = 0.0
var _geyser_fx: Array = []
var _wave_hit: bool = false
var _sink_t: float = 0.0
var _braziers_lit: Array = []
var _dart_cd: Dictionary = {}
var _darts: Array = []
var _blade_cd: float = 0.0
var _plat_t: float = 0.0
var _plat_run: float = 0.0
var _piston_cd: float = 0.0
var _shadow_t: float = 0.0
var _hands: Array = []
var _fall_cd: float = 0.0


func setup(main_node: Node) -> void:
	main = main_node
	state = _defaults()


func _defaults() -> Dictionary:
	var d := {"visite": false, "coeur_ouvert": false, "gardien": false, "marees_eau": 0, "marees_pont": false, "marees_coffre": false,
		"lune_cadrans": DIAL_START.duplicate()}
	for n in WINGS:
		d[n + "_a"] = false
		d[n + "_boss"] = false
		d[n + "_cristal"] = false
	return d


func _say(text: String, seconds: float = 5.0) -> void:
	main.donjon_v35._say(text, seconds)


func _once(key: String, text: String, seconds: float = 6.0) -> void:
	if _said.has(key):
		return
	_said[key] = true
	_say(text, seconds)


## Le joueur (les pieds).
func _feet() -> Vector3:
	if main.xr_active:
		return main.vr_body.global_position
	return main.pc_body.global_position


func region_contains(p: Vector3) -> bool:
	return Vector2(p.x - O.x, p.z - O.z).length() < 165.0 and p.y < O.y + 32.0 and p.y > O.y - 45.0


func lit_count() -> int:
	var n: int = 0
	for w in WINGS:
		if bool(state[w + "_cristal"]):
			n += 1
	return n


# =================================================================== construction

func ensure_built() -> void:
	if built:
		return
	built = true
	var t0: int = Time.get_ticks_msec()
	salles = Salles.new()
	salles.name = "Salles_coeur_v63"
	add_child(salles)
	salles.build(main, OS.has_feature("ile_manga_pc"))
	_register()
	_apply_built()
	_hide_all(false)
	print("ILE_MANGA_V63: le Cœur-de-Pierre construit en %d ms" % (Time.get_ticks_msec() - t0))


func _w(n: String) -> Dictionary:
	return salles.wings[n]


func _wl(n: String, local: Vector3) -> Vector3:
	return salles.W(n, local)


func _local(n: String, p: Vector3) -> Vector3:
	return (salles.wxf(n) as Transform3D).affine_inverse() * p


func _fwd(n: String) -> Vector3:
	return (salles.wxf(n) as Transform3D).basis * Vector3(0, 0, 1)


# =================================================================== entrer, sortir

func enter() -> void:
	ensure_built()
	var first: bool = not bool(state["visite"])
	state["visite"] = true
	await main.donjon_v35._travel(salles.points["arrivee"], Vector3(1, 0, 0))
	checkpoint = [salles.points["arrivee"], Vector3(1, 0, 0)]
	if first:
		_say("Le Vestibule des Quatre Peuples. Quatre statues de pierre : un marin, une caravanière, un berger, une renarde. Au-dessus de l'escalier, une fresque. Devant toi, un balcon… et en bas, une salle immense où bat une lumière rouge.", 10.0)


func _leave() -> void:
	_reset_fight()
	var ile: Node = main.grande_v59.ile
	var face: Vector3 = Basis(Vector3.UP, float(ile.door_yaw)) * Vector3(0, 0, 1)
	await main.donjon_v35._travel(ile.door_front(), face)
	_say("De retour à la lumière, devant la Porte aux Quatre Sceaux.", 4.0)


func _go(to: Vector3, face: Vector3) -> void:
	await main.donjon_v35._travel(to, face)
	checkpoint = [to, face]


# =================================================================== invites et cibles

func _register() -> void:
	var I: Array = main.donjon_v35._interactions
	var P: Dictionary = salles.points
	I.append({"id": "co63_sortir", "pos": P["sortie"], "radius": 2.2, "text": "E : remonter à la surface", "vr": "Gâchette : remonter", "call": _leave})
	I.append({"id": "co63_statues", "pos": salles.H(Vector3(-28.0, 5.0, 0.0)), "radius": 1.6, "text": "E : examiner les statues et la fresque", "vr": "Gâchette : les statues",
		"call": func(): _say("Quatre statues de pierre, chacune avec son médaillon : un marin (la vague), une caravanière (le soleil), un berger (la roue dentée), une renarde (la lune). Sur la fresque, au-dessus de l'escalier, les quatre peuples se tiennent la main devant la grande porte ; au-dessus d'eux, un cœur de pierre rouge, relié par quatre rayons à quatre cristaux.", 10.0)})
	I.append({"id": "co63_sceau_coeur", "pos": salles.H(Vector3(0, 0, 3.4)), "radius": 2.4, "text": "E : examiner le sceau du Cœur", "vr": "Gâchette : le sceau",
		"call": _hub_seal_text, "when": func(): return not bool(state["coeur_ouvert"])})
	I.append({"id": "co63_descendre_coeur", "pos": salles.H(Vector3(0, 0, 3.4)), "radius": 3.0, "text": "E : descendre dans la Salle du Cœur", "vr": "Gâchette : descendre",
		"call": _go_heart, "when": func(): return bool(state["coeur_ouvert"])})
	for n in WINGS:
		var nn: String = n
		var pts: Dictionary = _w(n)["pts"]
		I.append({"id": "co63_cristal_" + n, "pos": pts["cristal"], "radius": 2.6, "text": "E : toucher le cristal", "vr": "Gâchette : le cristal",
			"call": func(): _touch_crystal(nn), "when": func(): return bool(state[nn + "_boss"]) and not bool(state[nn + "_cristal"]) and not fight})
		I.append({"id": "co63_retour_" + n, "pos": pts["retour"], "radius": 1.5, "text": "E : entrer dans le cercle de lumière (vers la Rose des Sceaux)", "vr": "Gâchette : le cercle",
			"call": func(): _go(salles.points["hub_" + nn], -_fwd(nn)), "when": func(): return bool(state[nn + "_cristal"])})
	# les Marées
	var M: Dictionary = _w("marees")
	I.append({"id": "co63_roue_marees", "pos": M["roue_marees"], "radius": 1.8, "text": "E : tourner la roue des marées", "vr": "Gâchette : la roue",
		"call": _turn_tide})
	I.append({"id": "co63_coffre_marees", "pos": _wl("marees", Vector3(9.0, float(M["wy"]) - 1.8, float(M["L"]) + 8.0)), "radius": 1.5, "text": "E : ouvrir le coffre englouti", "vr": "Gâchette : le coffre",
		"call": _marees_chest, "when": func(): return not bool(state["marees_coffre"])})
	# les Sables
	var S: Dictionary = _w("sables")
	I.append({"id": "co63_stele_soleil", "pos": S["stele"], "radius": 1.6, "text": "E : lire la stèle", "vr": "Gâchette : la stèle",
		"call": func(): _say("Sur la stèle, un soleil gravé et ces mots : « Je me lève à l'est, je brûle au sud, je me couche à l'ouest, et je dors au nord. Rallume ma course, et la porte s'ouvrira. »", 9.0)})
	# la Lune : les cadrans
	var Lw: Dictionary = _w("lune")
	for i in range(4):
		var ii: int = i
		I.append({"id": "co63_cadran_%d" % i, "pos": _wl("lune", Vector3(-3.0 + i * 2.0, float(Lw["wy"]), float(Lw["L"]) + 28.6)), "radius": 0.95,
			"text": "E : tourner le %s cadran" % ORDINAL[i], "vr": "Gâchette : le cadran", "call": func(): _turn_dial(ii), "when": func(): return not bool(state["lune_a"])})
	# la Salle du Cœur
	I.append({"id": "co63_coeur_monter", "pos": salles.points["coeur_arrivee"], "radius": 2.0, "text": "E : remonter l'escalier (vers la Rose des Sceaux)", "vr": "Gâchette : remonter",
		"call": func(): _go(salles.points["hub_centre"], Vector3(0, 0, -1)), "when": func(): return not fight})
	I.append({"id": "co63_coeur_sortie", "pos": salles.points["coeur_retour"], "radius": 1.6, "text": "E : entrer dans le cercle de lumière (vers la surface)", "vr": "Gâchette : le cercle",
		"call": _leave, "when": func(): return bool(state["gardien"]) and not fight})
	# les pouvoirs
	var pw: Node = main.get("pouvoirs_v63")
	if pw == null:
		return
	pw.register({"id": "co63_moulin", "power": "vent", "pos": (M["moulin"] as Node3D).global_position, "radius": 4.5, "call": _mill,
		"when": func(): return built and not bool(state["marees_pont"])})
	var bp: Dictionary = S["braseros_pos"]
	for k in bp:
		var kk: String = k
		pw.register({"id": "co63_brasero_" + k, "power": "flamme", "pos": bp[k], "radius": 1.1, "call": func(): _light_brazier(kk),
			"when": func(): return built and not bool(state["sables_a"]) and not _braziers_lit.has(kk)})
	var R: Dictionary = _w("rouages")
	pw.register({"id": "co63_moteur", "power": "rouage", "pos": R["moteur_pos"], "radius": 2.5, "call": _start_motor, "when": func(): return built})
	var trues: Array = Lw["ponts_vrais"]
	for i2 in range(trues.size()):
		var body: Node3D = trues[i2]
		pw.register({"id": "co63_pont_vrai_%d" % i2, "power": "lune", "pos": body.global_position, "radius": 4.0,
			"call": func(on: bool): (body.get_node("Lumiere") as Node3D).visible = on})
	var fakes: Array = Lw["ponts_faux"]
	for i3 in range(fakes.size()):
		var fake: Node3D = fakes[i3]
		pw.register({"id": "co63_pont_faux_%d" % i3, "power": "lune", "pos": fake.global_position, "radius": 5.0,
			"call": func(on: bool): _fade_fake(fake, on)})
	var ink: Node3D = Lw["encre"]
	pw.register({"id": "co63_encre", "power": "lune", "pos": ink.global_position, "radius": 6.0, "call": func(on: bool): _show_ink(ink, on)})


func _fade_fake(fake: Node3D, on: bool) -> void:
	fake.visible = not on
	if on:
		_once("faux_pont", "Sous la Lueur de lune, un des beaux ponts d'ardoise… s'efface : ce n'était qu'une illusion ! Et d'autres ponts, de lumière, apparaissent là où il n'y avait rien.", 7.0)


func _show_ink(ink: Node3D, on: bool) -> void:
	ink.visible = on
	if on:
		_once("encre", "Sous la Lueur de lune, des lettres d'argent apparaissent au-dessus de la porte : quatre lunes, dans l'ordre. Pleine, décroissante, nouvelle, croissante.", 7.0)


# =================================================================== l'état, appliqué aux salles

func _apply_built() -> void:
	if not built:
		return
	var M: Dictionary = _w("marees")
	_water_y = float(M["wy"]) + float(WATER[int(state["marees_eau"])])
	_water_target = _water_y
	_set_water(_water_y)
	_set_bridge(0.0 if bool(state["marees_pont"]) else PI * 0.5)
	(M["moulin"] as Node3D).rotation.z = 0.0
	for n in WINGS:
		var g: Node3D = salles.gates[n + "_a"]
		g.position.y = float(g.get_meta("bas")) + (4.6 if bool(state[n + "_a"]) else 0.0)
		var gc: Node3D = salles.gates[n + "_c"]
		gc.position.y = float(gc.get_meta("bas")) + 4.6
		if bool(state[n + "_boss"]) and not _crystals.has(n):
			_crystals[n] = salles.wing_crystal(n)
		if _crystals.has(n):
			(_crystals[n]["node"] as Node3D).visible = bool(state[n + "_boss"])
		_light_hub(n, bool(state[n + "_cristal"]), false)
		if bool(state[n + "_cristal"]) and not _circles.has(n):
			_circles[n] = salles.return_circle(_w(n)["root"], _w(n)["pts"]["retour"], salles.WING_DEF[n]["couleur"])
		if _circles.has(n):
			(_circles[n] as Node3D).visible = bool(state[n + "_cristal"])
	_braziers_lit.clear()
	var S: Dictionary = _w("sables")
	for k in S["braseros"]:
		salles.kit.set_brazier(S["braseros"][k], bool(state["sables_a"]))
	_place_dials(false)
	_open_hub_seal(bool(state["coeur_ouvert"]), false)
	_heart_calm(bool(state["gardien"]))


func _light_hub(n: String, on: bool, animate: bool) -> void:
	var c: Dictionary = salles.hub_crystals[n]
	var m: StandardMaterial3D = c["mat"]
	var l: OmniLight3D = c["light"]
	if animate:
		create_tween().tween_property(m, "emission_energy_multiplier", 3.0 if on else 0.0, 2.0)
		create_tween().tween_property(l, "light_energy", 2.0 if on else 0.0, 2.0)
	else:
		m.emission_energy_multiplier = 3.0 if on else 0.0
		l.light_energy = 2.0 if on else 0.0


## Le sceau du Cœur ouvert : il a tourné d'un quart de tour, une colonne de lumière en monte.
func _open_hub_seal(on: bool, animate: bool) -> void:
	var seal: Node3D = salles.hub_seal
	if on and _beam == null:
		_beam = _make_beam()
	if _beam != null:
		_beam.visible = on
	if animate and on:
		seal.rotation.y = 0.0
		create_tween().tween_property(seal, "rotation:y", PI * 0.5, 4.0).set_trans(Tween.TRANS_SINE)
		_beam.scale = Vector3(1, 0.01, 1)
		create_tween().tween_property(_beam, "scale", Vector3.ONE, 3.0).set_delay(2.0)
	else:
		seal.rotation.y = PI * 0.5 if on else 0.0


func _make_beam() -> Node3D:
	var n := Node3D.new()
	n.name = "Colonne_du_coeur"
	salles.hub_root.add_child(n)
	n.global_position = O + Vector3(0, 0.2, 0)
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.6
	cm.bottom_radius = 2.0
	cm.height = 10.0
	cm.cap_top = false
	cm.cap_bottom = false
	mi.mesh = cm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(1.0, 0.35, 0.15, 0.16)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = 5.0
	n.add_child(mi)
	var motes := CPUParticles3D.new()
	motes.amount = 50
	motes.lifetime = 3.0
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	motes.emission_sphere_radius = 1.6
	motes.direction = Vector3.UP
	motes.spread = 6.0
	motes.gravity = Vector3(0, 1.2, 0)
	motes.initial_velocity_min = 0.4
	motes.initial_velocity_max = 1.2
	var q := QuadMesh.new()
	q.size = Vector2(0.08, 0.08)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	qm.albedo_color = Color(1.0, 0.6, 0.3, 0.9)
	q.material = qm
	motes.mesh = q
	n.add_child(motes)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.4, 0.2)
	l.light_energy = 1.6
	l.omni_range = 9.0
	l.position.y = 1.2
	n.add_child(l)
	return n


func _heart_calm(calm: bool) -> void:
	if salles.w_heart_mat != null:
		salles.w_heart_mat.emission = Color(1.0, 0.78, 0.35) if calm else Color(1.0, 0.22, 0.08)
		salles.w_heart_mat.albedo_color = Color(0.9, 0.62, 0.25, 0.9) if calm else Color(0.6, 0.08, 0.05, 0.9)
	salles.heart_light.light_color = Color(1.0, 0.82, 0.5) if calm else Color(1.0, 0.28, 0.12)
	salles.heart_mat.emission = Color(1.0, 0.78, 0.35) if calm else Color(1.0, 0.2, 0.08)
	salles.hub_heart_light.light_color = Color(1.0, 0.8, 0.5) if calm else Color(1.0, 0.3, 0.15)
	if calm and _heart_exit == null:
		_heart_exit = salles.return_circle(salles.heart_root, salles.points["coeur_retour"], Color(1.0, 0.85, 0.5))


# =================================================================== la Rose des Sceaux, le Cœur

func _hub_seal_text() -> void:
	var lit: int = lit_count()
	_say("Le sceau du Cœur : un grand disque de pierre sombre cerclé d'or, et quatre cristaux tournés vers les quatre ailes : bleu-vert vers les Marées, orange vers les Sables, or vers les Rouages, argent vers la Lune. %s" % ("Aucun ne brille encore. Il faudra sans doute réveiller le cristal de chaque aile." if lit == 0 else "%d sur quatre brillent." % lit), 9.0)


func _go_heart() -> void:
	await _go(salles.points["coeur_arrivee"], Vector3(0, 0, -1))
	if bool(state["gardien"]):
		_say("La Salle du Cœur. Le grand cristal bat doucement, d'une lumière d'or. Tout est calme.", 5.0)
	else:
		_say("La Salle du Cœur. Une caverne immense, ronde, des veines de feu dans le sol. Au milieu, suspendu à des chaînes, un cristal rouge plus grand qu'une maison… qui bat. Et sous lui, quelque chose se lève.", 8.0)


func _start_final() -> void:
	var mo: Node = main.get("monstres_v36")
	if mo == null:
		return
	fight = true
	_boss_wing = "coeur"
	var at: Vector3 = salles.points["coeur_centre"]
	var b: Node3D = BossScript.new()
	mo.add_child(b)
	b.setup(mo, "gardien_coeur", at)
	b.died.connect(mo._on_died)
	mo.monsters.append(b)
	b.state = "chasse"
	_boss = b
	main.sfx("boss_coeur_cri", at + Vector3.UP * 5.0)
	_show_bar("Le Gardien du Cœur", 999)
	_say("Un colosse de roche se dresse sous le cristal : LE GARDIEN DU CŒUR ! Quatre runes brillent sur lui, aux couleurs des quatre sceaux.", 7.0)


func _on_final_dead() -> void:
	fight = false
	state["gardien"] = true
	_boss = null
	_boss_wing = ""
	_victory = true
	_hide_bar()
	_kill_minions()
	main.jingle("victoire")
	_say("Le Gardien du Cœur s'effondre… Les veines de feu pâlissent. Au-dessus, le grand cristal cesse de battre si fort ; sa lumière rouge devient dorée, douce comme un soleil du soir.", 8.0)
	await get_tree().create_timer(3.0).timeout
	_heart_calm(true)
	main.sfx("esprit", salles.heart_crystal.global_position)
	await get_tree().create_timer(5.0).timeout
	_say("Une voix, très grave, qui semble venir de toute la montagne : « Deux cents ans… Deux cents ans que la colère de la terre brûlait en moi. Les quatre peuples m'avaient endormi ; toi, tu m'as apaisé. Prends ceci : un éclat de mon cœur. Et dis-leur… dis-leur de revenir chanter devant la porte, une fois par an, comme avant. »", 14.0)
	await get_tree().create_timer(2.0).timeout
	_rewards()


func _rewards() -> void:
	var inv: Node = main.inventory_v28
	if inv.add("lame_coeur", 1) <= 0:
		inv.spawn_pickup("coeur63_lame", "lame_coeur", 1, salles.points["coeur_centre"] + Vector3(0, 0.3, 3.0))
	inv.add("piece", 200)
	var j: Node = main.get("journal_v56")
	if j != null:
		if not j.titres.has("Héros des Quatre Peuples"):
			j.titres.append("Héros des Quatre Peuples")
		j.bonus["coeur"] = int(j.bonus["coeur"]) + 1
		j.apply_bonuses()
	var hero: Node = main.get("hero_v28")
	if hero != null:
		hero.set_health(int(hero.HP_MAX))
	main._show_message_v28("Le Gardien du Cœur est apaisé ! La Lame du Cœur, 200 pièces, un cœur de plus, et un titre : « Héros des Quatre Peuples ». Le cercle de lumière, au nord de la salle, te ramènera à la surface.")
	main.jingle("decouverte")


func _kill_minions() -> void:
	var mo: Node = main.get("monstres_v36")
	if mo == null:
		return
	for m in mo.monsters.duplicate():
		if is_instance_valid(m) and str(m.state) != "mort" and region_contains((m as Node3D).global_position) and _room_of((m as Node3D).global_position) == room:
			m.take_hit(99, (m as Node3D).global_position + Vector3.UP)


# =================================================================== les gardiens des ailes

func _start_wing_boss(n: String) -> void:
	var mo: Node = main.get("monstres_v36")
	if mo == null:
		return
	fight = true
	_boss_wing = n
	var g: Node3D = salles.gates[n + "_c"]
	create_tween().tween_property(g, "position:y", float(g.get_meta("bas")), 0.5).set_trans(Tween.TRANS_QUAD)
	main.sfx("grille", g.global_position + Vector3.UP * 2.0)
	await get_tree().create_timer(1.2).timeout
	if not fight or _boss_wing != n:
		return
	var at: Vector3 = _w(n)["pts"]["boss"]
	var b: Node3D = mo.spawn_extra(BOSS_OF[n], at + Vector3.UP * 0.1)
	b.home = at
	b.state = "chasse"
	_boss = b
	if main.combat_v28 != null:
		main.combat_v28.puff(at + Vector3.UP, salles.WING_DEF[n]["couleur"])
	var nom: String = str(b.spec["nom"])
	_show_bar(nom.substr(0, 1).to_upper() + nom.substr(1), int(b.spec["pv"]))
	_say("La herse retombe derrière toi… %s se dresse au milieu de l'arène !" % (nom.substr(0, 1).to_upper() + nom.substr(1)), 5.0)


func _on_wing_boss_dead(n: String) -> void:
	fight = false
	_boss = null
	_boss_wing = ""
	_hide_bar()
	_kill_minions()
	state[n + "_boss"] = true
	main.jingle("victoire")
	var g: Node3D = salles.gates[n + "_c"]
	create_tween().tween_property(g, "position:y", float(g.get_meta("bas")) + 4.6, 2.0).set_trans(Tween.TRANS_SINE)
	if not _crystals.has(n):
		_crystals[n] = salles.wing_crystal(n)
	var cn: Node3D = _crystals[n]["node"]
	cn.visible = true
	var target: Vector3 = _w(n)["pts"]["cristal"]
	cn.global_position = target + Vector3.DOWN * 2.2
	create_tween().tween_property(cn, "global_position", target, 3.0).set_trans(Tween.TRANS_SINE)
	main.sfx("cristal_eveil", target)
	_say("Le gardien de %s est vaincu ! Au fond de l'arène, sur l'estrade, un cristal monte lentement du sol, et la herse se relève. (E : toucher le cristal)" % str(salles.WING_DEF[n]["nom"]), 7.0)


func _touch_crystal(n: String) -> void:
	state[n + "_cristal"] = true
	main.sfx("sceau_eveil", _w(n)["pts"]["cristal"])
	main.jingle("decouverte")
	_light_hub(n, true, true)
	if not _circles.has(n):
		_circles[n] = salles.return_circle(_w(n)["root"], _w(n)["pts"]["retour"], salles.WING_DEF[n]["couleur"])
	(_circles[n] as Node3D).visible = true
	var lit: int = lit_count()
	var t: String = "Le cristal s'illumine sous ta main. Un rayon de lumière part vers la Rose des Sceaux : là-bas, un des quatre cristaux du sceau du Cœur s'allume (%d sur 4). Un cercle de lumière s'est ouvert à côté de l'estrade : il te ramènera à la Rose des Sceaux." % lit
	if lit == 4:
		t = "Le dernier cristal s'illumine ! Très loin, dans la Rose des Sceaux, un long grondement… Le cercle de lumière, à côté de l'estrade, t'y ramènera."
	_say(t, 9.0)


func _show_bar(label: String, hp_max: int) -> void:
	var d: Node = main.donjon_v35
	d._bar_name = label
	d._bar_label.text = label
	d._bar_layer.visible = not main.xr_active
	if main.xr_active and _boss != null:
		_bar_vr = Label3D.new()
		_bar_vr.font_size = 48
		_bar_vr.pixel_size = 0.004
		_bar_vr.outline_size = 10
		_bar_vr.modulate = Color(1.0, 0.75, 0.5)
		_bar_vr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_bar_vr.no_depth_test = true
		_bar_vr.position = Vector3(0, float(_boss.hit_height) * 2.0 + 2.2, 0)
		_boss.add_child(_bar_vr)
		d._bar_vr = _bar_vr
	d._update_bar(hp_max, hp_max)


func _hide_bar() -> void:
	var d: Node = main.donjon_v35
	d._bar_layer.visible = false
	d._bar_vr = null
	if _bar_vr != null and is_instance_valid(_bar_vr):
		_bar_vr.queue_free()
	_bar_vr = null


## Évanoui, ou sorti du donjon : les combats reprendront à zéro (les gardiens vaincus le restent).
func _reset_fight() -> void:
	var mo: Node = main.get("monstres_v36")
	if fight:
		_hide_bar()
	fight = false
	_boss = null
	if _boss_wing in WINGS and built:
		var g: Node3D = salles.gates[_boss_wing + "_c"]
		g.position.y = float(g.get_meta("bas")) + 4.6
	_boss_wing = ""
	if mo != null:
		for m in mo.monsters.duplicate():
			if is_instance_valid(m) and region_contains((m as Node3D).global_position):
				mo.monsters.erase(m)
				(m as Node).queue_free()
	_room_monsters.clear()
	_final_wait = -1.0
	for h in _hands:
		(h as Node).queue_free()
	_hands.clear()
	for d in _darts:
		(d["node"] as Node).queue_free()
	_darts.clear()
	_unsink()


# =================================================================== où est le joueur ?

func _room_of(p: Vector3) -> String:
	if not built or not region_contains(p):
		return ""
	var l: Vector3 = p - O
	if l.y < -16.0 and Vector2(l.x, l.z).length() < 32.0:
		return "coeur"
	if l.x < -17.5 and l.x > -47.0 and absf(l.z) < 6.0 and l.y > 3.0:
		return "vestibule"
	if absf(l.x) < 19.0 and absf(l.z) < 19.0 and l.y > -2.0:
		return "hub"
	for n in WINGS:
		var lw: Vector3 = _local(n, p)
		var L: float = float(_w(n)["L"])
		if lw.z < -0.5 or lw.z > L + 106.0 or absf(lw.x) > 14.5:
			continue
		if lw.z < L:
			return n + "_couloir"
		if lw.z < L + 30.0:
			return n + "_a"
		if lw.z < L + 36.0:
			return n + "_ab"
		if lw.z < L + 74.0:
			return n + "_b"
		if lw.z < L + 78.0:
			return n + "_bc"
		return n + "_c"
	return "hub"


func _wing_of(r: String) -> String:
	for n in WINGS:
		if r.begins_with(n + "_"):
			return n
	return ""


# =================================================================== chaque image

func _physics_process(delta: float) -> void:
	if main == null or not bool(main.game_started) or not built:
		return
	_clock += delta
	var p: Vector3 = _feet()
	var r: String = _room_of(p)
	if r == "":
		if _was_in:
			_was_in = false
			_reset_fight()
			_hide_all(false)
			room = ""
			_said.clear()
		return
	_was_in = true
	if r != room:
		var old: String = room
		room = r
		_enter_room(old, r)
	_visibility(r)
	_tick_pulse(delta)
	var n: String = _wing_of(r)
	if n != "sables" and n != "lune":
		_unsink()
	match n:
		"marees":
			_tick_marees(delta, p, r)
		"sables":
			_tick_sables(delta, p, r)
		"rouages":
			_tick_rouages(delta, p, r)
		"lune":
			_tick_lune(delta, p, r)
	if n != "rouages":
		_tick_platforms(delta)
	_tick_falls(delta, p, r)
	_tick_room_monsters()
	_tick_boss()
	# le gardien d'une aile se lève quand on s'avance dans son arène
	if n != "" and r == n + "_c" and not fight and not bool(state[n + "_boss"]) and _local(n, p).z > float(_w(n)["L"]) + 80.0:
		_start_wing_boss(n)
	# le Gardien du Cœur, quelques secondes après l'arrivée dans la salle
	if r == "coeur" and not fight and not bool(state["gardien"]) and _final_wait >= 0.0:
		_final_wait -= delta
		if _final_wait < 0.0:
			_start_final()


func _tick_pulse(delta: float) -> void:
	var beat: float = pow(maxf(0.0, sin(_clock * 2.2)), 8.0) + 0.6 * pow(maxf(0.0, sin(_clock * 2.2 - 0.6)), 8.0)
	var calm: bool = bool(state["gardien"])
	salles.hub_heart_light.light_energy = (0.9 if calm else 1.0) + beat * (0.4 if calm else 1.6)
	salles.heart_mat.emission_energy_multiplier = 1.2 + beat * (0.5 if calm else 2.0)
	if room == "coeur":
		salles.heart_light.light_energy = 2.4 + beat * (0.8 if calm else 3.0)
		salles.heart_crystal.rotate_y(delta * 0.12)


## Les salles qu'on ne voit pas ne sont pas dessinées.
func _visibility(r: String) -> void:
	var n: String = _wing_of(r)
	salles.vest_root.visible = r == "vestibule" or r == "hub"
	salles.hub_root.visible = r == "vestibule" or r == "hub" or r.ends_with("_couloir") or r.ends_with("_a")
	salles.heart_root.visible = r == "coeur"
	for w in WINGS:
		(_w(w)["root"] as Node3D).visible = w == n or r == "hub"


func _hide_all(on: bool) -> void:
	if not built:
		return
	salles.vest_root.visible = on
	salles.hub_root.visible = on
	salles.heart_root.visible = on
	for w in WINGS:
		(_w(w)["root"] as Node3D).visible = on


func _enter_room(old: String, r: String) -> void:
	var n: String = _wing_of(r)
	# le point de reprise de la salle
	if n != "":
		var pts: Dictionary = _w(n)["pts"]
		if r == n + "_a":
			checkpoint = [pts["entree_a"], _fwd(n)]
		elif r == n + "_b":
			checkpoint = [pts["entree_b"], _fwd(n)]
		elif r == n + "_c":
			checkpoint = [_wl(n, Vector3(0, float(_w(n)["wy"]) + 0.1, float(_w(n)["L"]) + 75.5)), _fwd(n)]
	elif r == "hub":
		checkpoint = [salles.points["hub_centre"], Vector3(0, 0, -1)]
	elif r == "coeur":
		checkpoint = [salles.points["coeur_arrivee"], Vector3(0, 0, -1)]
		if not bool(state["gardien"]) and not fight:
			_final_wait = 4.0
	# premières fois, monstres, mécanismes
	if r.ends_with("_a") or r.ends_with("_b"):
		_spawn_room(r)
	match r:
		"hub":
			_once("hub", "La Rose des Sceaux. Une salle ronde comme une place, quatre colonnes, quatre portes. Au sol, une rose des vents gravée, et au centre un sceau rond sous quatre cristaux éteints. Sous la voûte, un cristal rouge suspendu bat comme un cœur.", 9.0)
			if lit_count() == 4 and not bool(state["coeur_ouvert"]):
				_open_heart()
		"marees_a":
			_once("marees_a", "L'Aile des Marées. Un grand bassin, des radeaux qui flottent tout en bas, et au fond, une porte sur un rebord, hors d'atteinte. Près de toi, une grande roue de bronze : la roue des marées. Au-dessus du rebord du fond, les ailes immobiles d'un moulin…", 9.0)
		"marees_b":
			_once("marees_b", "Une longue galerie, un canal au milieu, des niches dans les murs… Au loin, un grondement d'eau qui roule. Ces niches ne sont pas là pour décorer.", 7.0)
		"sables_a":
			_once("sables_a", "L'Aile des Sables. Au milieu, un sable qui bouge… des sables mouvants ! Des chemins de dalles les traversent. Quatre braseros éteints, aux quatre points cardinaux, et une stèle au centre.", 8.0)
		"sables_b":
			_once("sables_b", "Le couloir des lames : quatre grandes lames qui se balancent d'un mur à l'autre, des dalles plus sombres que les autres… et du sable au bout. Regarde bien, et passe au bon moment.", 7.0)
		"rouages_a":
			_once("rouages_a", "L'Aile des Rouages. Un gouffre noir, des plates-formes de fonte immobiles sur leurs rails, et sur le rebord, contre le mur, un gros moteur à engrenages, à l'arrêt. Grippé, peut-être ?", 8.0)
		"rouages_b":
			_once("rouages_b", "La forge des pistons : d'énormes marteaux de fonte qui écrasent le sol en cadence, et entre eux, des tapis roulants qui te ramènent en arrière. Compte les coups…", 7.0)
		"lune_a":
			_once("lune_a", "L'Aile de la Lune. Un gouffre sans fond, une île de pierre au milieu, et deux beaux ponts d'ardoise qui y mènent… Trop beaux, peut-être. Au fond, sur le rebord, une porte et quatre cadrans.", 8.0)
		"lune_b":
			_once("lune_b", "Une galerie froide, des dalles noires comme des trous dans la nuit… Quelque chose bouge dedans.", 6.0)
	if r.ends_with("_c") and n != "" and not bool(state[n + "_boss"]):
		_once(r, "L'arène du gardien de %s. Le silence… Avance, si tu l'oses." % str(salles.WING_DEF[n]["nom"]), 5.0)


func _open_heart() -> void:
	state["coeur_ouvert"] = true
	_open_hub_seal(true, true)
	main.sfx("porte_coeur", O + Vector3.UP)
	main.jingle("decouverte")
	_say("Les quatre cristaux brillent ensemble ! Le sceau du Cœur tourne sur lui-même avec un long grondement, et une colonne de lumière rouge monte du sol, là où il était scellé. (E, au centre : descendre dans la Salle du Cœur)", 9.0)


## Les monstres d'une salle, une fois par descente.
func _spawn_room(r: String) -> void:
	if _room_monsters.has(r) or not ROOM_SPAWNS.has(r):
		return
	_room_monsters[r] = []
	var mo: Node = main.get("monstres_v36")
	if mo == null:
		return
	var n: String = _wing_of(r)
	var wy: float = float(_w(n)["wy"])
	var L: float = float(_w(n)["L"])
	for e in ROOM_SPAWNS[r]:
		var at: Vector3 = _wl(n, Vector3(float(e[1]), wy + 0.1, L + float(e[2])))
		var m: Node3D = mo.spawn_extra(str(e[0]), at)
		m.home = at
		m.state = "veille"
		(_room_monsters[r] as Array).append(m)


func _tick_room_monsters() -> void:
	for r in _room_monsters:
		for m in _room_monsters[r]:
			if not is_instance_valid(m) or str(m.get("state")) == "mort":
				continue
			# un monstre tombé dans un gouffre revient à son poste
			var mm: Node3D = m
			var home: Vector3 = mm.get("home")
			if mm.global_position.y < home.y - 3.0:
				mm.global_position = home
				mm.set("velocity", Vector3.ZERO)
				mm.set("state", "veille")


func _tick_boss() -> void:
	if not fight or _boss == null:
		return
	if not is_instance_valid(_boss):
		_boss = null
		return
	var d: Node = main.donjon_v35
	if _boss_wing == "coeur":
		var b: Node = _boss
		if int(b.phase) == 1:
			var broken: int = 4 - int(b.runes_left())
			d._bar_name = "Le Gardien du Cœur — runes brisées : %d / 4" % broken
			d._bar_label.text = d._bar_name
			d._update_bar(4 - broken, 4)
		else:
			d._bar_name = "Le Gardien du Cœur"
			d._bar_label.text = d._bar_name
			d._update_bar(maxi(int(b.hp), 0), int(b.PV_COEUR))
		if str(b.state) == "mort":
			_on_final_dead()
		return
	d._update_bar(maxi(int(_boss.hp), 0), int(_boss.spec["pv"]))
	if str(_boss.state) == "mort":
		_on_wing_boss_dead(_boss_wing)


# =================================================================== chutes, reprise, évanouissement

func _tick_falls(delta: float, p: Vector3, r: String) -> void:
	_fall_cd = maxf(_fall_cd - delta, 0.0)
	if _fall_cd > 0.0 or checkpoint.is_empty():
		return
	var n: String = _wing_of(r)
	if n != "" and p.y < O.y + float(_w(n)["wy"]) - 3.0:
		_fall_cd = 1.5
		if n == "marees" and int(state["marees_eau"]) >= 1:
			_fall_back("Plouf ! Tu nages dans l'eau froide jusqu'au rebord d'entrée, et tu t'y hisses, trempé.", 0)
			main.sfx("gros_plouf", p + Vector3.UP)
		else:
			_fall_back("Tu tombes… et tu te retrouves, étourdi, au bord de la salle.", 2)
	elif p.y < O.y - 36.0:
		_fall_cd = 1.5
		_fall_back("Tu tombes… et tu te retrouves, étourdi, au bord de la salle.", 2)


func _fall_back(text: String, dmg: int) -> void:
	if checkpoint.is_empty():
		return
	_unsink()
	main.place_player_v35(checkpoint[0], checkpoint[1])
	if dmg > 0:
		var hero: Node = main.get("hero_v28")
		if hero != null:
			hero.hurt_cooldown = 0.0
		_hurt(dmg, (checkpoint[0] as Vector3) + Vector3(0, 1.0, 0.01))
	_say(text, 3.5)


## Évanoui sous le Cœur-de-Pierre : au point de reprise de la salle, les cœurs pleins ; le
## gardien en cours de combat s'en va (on le retrouvera en revenant).
func respawn() -> void:
	ensure_built()
	_reset_fight()
	var at: Array = checkpoint if not checkpoint.is_empty() else [salles.points["arrivee"], Vector3(1, 0, 0)]
	main.place_player_v35(at[0], at[1])
	var hero: Node = main.get("hero_v28")
	if hero != null:
		hero.hp = hero.HP_MAX
		hero.stamina = hero.STAMINA_MAX
		hero.state = "sol"
		hero.hurt_cooldown = 0.0
		hero.health_changed.emit(hero.hp, hero.HP_MAX)
	main.donjon_v35.update_inside(true)
	main._show_message_v28("Vous vous êtes évanoui… et réveillé à l'entrée de la salle. La lumière rouge du Cœur bat toujours.")
	room = ""


## Pousse le joueur (tapis roulants, vagues, lames…) sans traverser les murs.
func push_player(offset: Vector3) -> void:
	var body: CharacterBody3D = main.vr_body if main.xr_active else main.pc_body
	if body == null:
		return
	if main.xr_active:
		var head: Vector3 = main.xr_camera.global_position
		var off := Vector3(head.x - main.xr_origin.global_position.x, 0.0, head.z - main.xr_origin.global_position.z)
		body.move_and_collide(offset)
		main.xr_origin.position = Vector3(body.global_position.x - off.x, body.global_position.y, body.global_position.z - off.z)
	else:
		body.move_and_collide(offset)
		main.pc_root.position = body.global_position


func _hurt(dmg: int, from: Vector3) -> void:
	var mo: Node = main.get("monstres_v36")
	if mo != null:
		mo.hurt_player(dmg, from)


func _unsink() -> void:
	var hero: Node = main.get("hero_v28")
	if hero != null and (float(hero.sink) > 0.0 or float(hero.sol_mult) != 1.0):
		hero.sink = 0.0
		hero.sol_mult = 1.0
	_sink_t = 0.0
	_shadow_t = 0.0


# =================================================================== l'Aile des Marées

func _turn_tide() -> void:
	var i: int = (int(state["marees_eau"]) + 1) % WATER.size()
	state["marees_eau"] = i
	var M: Dictionary = _w("marees")
	_water_target = float(M["wy"]) + float(WATER[i])
	main.sfx("mecanisme", M["roue_marees"])
	main.sfx("eau_vanne", M["roue_marees"], -4.0)
	var wheel: Node3D = M["roue_node"]
	create_tween().tween_property(wheel, "rotation:z", wheel.rotation.z + PI * 0.66, 1.2).set_trans(Tween.TRANS_SINE)
	_say(["Tu tournes la grande roue : des vannes s'ouvrent quelque part, l'eau s'en va en grondant… Le bassin se vide, les radeaux descendent tout au fond.",
		"Tu tournes la grande roue : l'eau monte à mi-hauteur, les radeaux avec elle. Le coffre posé sur le pilier, à droite, est maintenant à leur niveau…",
		"Tu tournes la grande roue : l'eau monte, monte, jusqu'au bord ! Les radeaux arrivent à hauteur du rebord."][i], 6.0)


func _set_water(y: float) -> void:
	var M: Dictionary = _w("marees")
	(M["eau"] as Node3D).global_position.y = O.y + y
	for raft in M["radeaux"]:
		var r: Node3D = raft
		var base: Transform3D = r.get_meta("base_xf")
		r.global_transform = Transform3D(base.basis, Vector3(base.origin.x, O.y + y + 0.25, base.origin.z))


## Le pont-levis (0 : baissé ; PI / 2 : levé contre le rebord du fond).
func _set_bridge(ang: float) -> void:
	var bridge: Node3D = _w("marees")["pont"]
	bridge.global_transform = (bridge.get_meta("base_xf") as Transform3D) * Transform3D(Basis(Vector3.RIGHT, ang), Vector3.ZERO)


func _mill() -> void:
	if bool(state["marees_pont"]):
		return
	state["marees_pont"] = true
	state["marees_a"] = true
	var M: Dictionary = _w("marees")
	var mill: Node3D = M["moulin"]
	create_tween().tween_property(mill, "rotation:z", mill.rotation.z - TAU * 3.0, 5.0).set_trans(Tween.TRANS_SINE)
	main.sfx("mecanisme", mill.global_position)
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_method(_set_bridge, PI * 0.5, 0.0, 2.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	var g: Node3D = salles.gates["marees_a"]
	tw.tween_property(g, "position:y", float(g.get_meta("bas")) + 4.6, 2.0).set_trans(Tween.TRANS_SINE)
	main.jingle("decouverte")
	_say("La Bourrasque prend dans les ailes du moulin ! Elles se mettent à tourner, une chaîne grince… et un pont-levis s'abat du rebord du fond jusqu'au dernier radeau. La porte du fond se lève.", 7.0)


func _marees_chest() -> void:
	if not main.inventory_v28.can_accept([["piece", 40], ["perle", 2]]):
		_say("Ton sac est plein !", 3.0)
		return
	state["marees_coffre"] = true
	var M: Dictionary = _w("marees")
	main.sfx("coffre", _wl("marees", Vector3(9.0, float(M["wy"]) - 1.5, float(M["L"]) + 8.6)))
	var a: int = main.inventory_v28.add("piece", 40)
	main.inventory_v28.add("perle", 2)
	_say("Le coffre englouti, couvert de coquillages : %d pièces et deux perles. Les marins d'autrefois savaient cacher leurs trésors." % a, 6.0)


func _tick_marees(delta: float, p: Vector3, r: String) -> void:
	var M: Dictionary = _w("marees")
	var L: float = M["L"]
	var wy: float = M["wy"]
	# l'eau monte ou descend doucement (et les radeaux avec)
	if absf(_water_y - _water_target) > 0.001:
		_water_y = move_toward(_water_y, _water_target, delta * 1.4)
		_set_water(_water_y)
	var lp: Vector3 = _local("marees", p)
	if r == "marees_a":
		_tick_geysers(delta, p, M)
	elif r == "marees_b":
		# la vague : toutes les 10 s, elle roule du fond vers l'entrée ; on s'abrite dans une niche
		var b0: float = L + 36.0
		var period: float = 10.0
		var t2: float = fmod(_clock, period)
		var wave: Node3D = M["vague"]
		if t2 < 3.6:
			wave.visible = true
			var z: float = lerpf(b0 + 37.0, b0 + 1.0, t2 / 3.6)
			wave.global_position = _wl("marees", Vector3(0, wy, z))
			if absf(lp.z - z) < 1.2 and absf(lp.x) < 5.2 and lp.y - wy < 3.0 and not _wave_hit:
				_wave_hit = true
				_hurt(1, _wl("marees", Vector3(0, wy + 1.0, z + 2.0)))
				var back: Vector3 = (salles.wxf("marees") as Transform3D).basis * Vector3(0, 0, -0.7)
				var tw := create_tween()
				for k in range(8):
					tw.tween_callback(push_player.bind(back))
					tw.tween_interval(0.03)
				_once("vague", "La vague t'emporte ! Abrite-toi dans une niche, sur les côtés, quand tu l'entends gronder.", 5.0)
		else:
			wave.visible = false
			_wave_hit = false
		if t2 >= period - 2.0 and t2 - delta < period - 2.0:
			main.sfx("vague", _wl("marees", Vector3(0, wy + 1.0, b0 + 36.0)))
	else:
		(M["vague"] as Node3D).visible = false


## Les geysers : 2 s toutes les 6 s, décalés ; les bulles préviennent juste avant.
func _tick_geysers(delta: float, p: Vector3, M: Dictionary) -> void:
	var gs: Array = M["geysers"]
	if _geyser_fx.is_empty():
		for gp in gs:
			_geyser_fx.append(_make_geyser(M["root"], gp))
	for i in range(gs.size()):
		var gp2: Vector3 = gs[i]
		var t: float = fmod(_clock + i * 3.0, 6.0)
		var fx: Dictionary = _geyser_fx[i]
		var surf := Vector3(gp2.x, O.y + _water_y, gp2.z)
		(fx["jet"] as CPUParticles3D).emitting = t < 2.0
		(fx["bulles"] as CPUParticles3D).emitting = t > 4.8
		(fx["jet"] as Node3D).global_position = surf
		(fx["bulles"] as Node3D).global_position = surf + Vector3.UP * 0.05
		if t < delta:
			main.sfx("geyser", surf)
		if t < 2.0 and Vector2(p.x - gp2.x, p.z - gp2.z).length() < 1.9 and p.y > surf.y - 0.6:
			var away := Vector3(p.x - gp2.x, 0, p.z - gp2.z)
			away = away.normalized() if away.length() > 0.05 else Vector3.RIGHT
			push_player(away * 0.14 + Vector3.UP * 0.06)
			if not bool(fx.get("touche", false)):
				fx["touche"] = true
				_hurt(1, surf)
				_once("geyser", "Un geyser ! L'eau jaillit du fond du bassin et te projette. Regarde les bulles : elles préviennent.", 5.0)
		elif t >= 2.0:
			fx["touche"] = false


func _make_geyser(parent: Node3D, at: Vector3) -> Dictionary:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.82, 0.95, 1.0, 0.6)
	if main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	var jet := CPUParticles3D.new()
	jet.amount = 70
	jet.lifetime = 1.0
	jet.local_coords = false
	jet.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	jet.emission_sphere_radius = 0.4
	jet.direction = Vector3.UP
	jet.spread = 8.0
	jet.initial_velocity_min = 7.0
	jet.initial_velocity_max = 10.0
	jet.gravity = Vector3(0, -9.0, 0)
	jet.scale_amount_min = 1.0
	jet.scale_amount_max = 2.2
	var q := QuadMesh.new()
	q.size = Vector2(0.45, 0.45)
	q.material = m
	jet.mesh = q
	jet.emitting = false
	parent.add_child(jet)
	jet.global_position = at
	var bub := CPUParticles3D.new()
	bub.amount = 24
	bub.lifetime = 0.6
	bub.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	bub.emission_sphere_radius = 0.7
	bub.direction = Vector3.UP
	bub.initial_velocity_min = 0.5
	bub.initial_velocity_max = 1.2
	bub.gravity = Vector3.ZERO
	var q2 := QuadMesh.new()
	q2.size = Vector2(0.14, 0.14)
	q2.material = m
	bub.mesh = q2
	bub.emitting = false
	parent.add_child(bub)
	bub.global_position = at
	return {"jet": jet, "bulles": bub}


# =================================================================== l'Aile des Sables

func _light_brazier(k: String) -> void:
	if bool(state["sables_a"]) or _braziers_lit.has(k):
		return
	var S: Dictionary = _w("sables")
	salles.kit.set_brazier(S["braseros"][k], true)
	main.sfx("flamme_impact", S["braseros_pos"][k])
	_braziers_lit.append(k)
	for i in range(_braziers_lit.size()):
		if _braziers_lit[i] != BRAZIER_ORDER[i]:
			_braziers_lit.clear()
			_say("La flamme prend… puis toutes les flammes s'étouffent d'un coup, dans un souffle de sable. Ce n'était pas la course du soleil.", 5.0)
			main.sfx("ui_erreur")
			await get_tree().create_timer(0.8).timeout
			for k2 in S["braseros"]:
				salles.kit.set_brazier(S["braseros"][k2], false)
			return
	if _braziers_lit.size() < 4:
		_say(["Le brasero de l'est flambe : le soleil se lève.", "Le brasero du sud flambe : le soleil brûle à midi.", "Le brasero de l'ouest flambe : le soleil se couche."][_braziers_lit.size() - 1], 3.5)
		return
	state["sables_a"] = true
	main.jingle("decouverte")
	var g: Node3D = salles.gates["sables_a"]
	create_tween().tween_property(g, "position:y", float(g.get_meta("bas")) + 4.6, 3.0).set_trans(Tween.TRANS_SINE)
	main.sfx("pierre_glisse", g.global_position)
	_say("Le brasero du nord s'allume : le soleil dort. Les quatre flammes rugissent ensemble… et la grande dalle du fond glisse vers le haut.", 7.0)


func _in_rects(lp: Vector3, rects: Array) -> bool:
	for r in rects:
		if (r as Rect2).has_point(Vector2(lp.x, lp.z)):
			return true
	return false


func _tick_sables(delta: float, p: Vector3, r: String) -> void:
	var S: Dictionary = _w("sables")
	var L: float = S["L"]
	var wy: float = S["wy"]
	var lp: Vector3 = _local("sables", p)
	var hero: Node = main.get("hero_v28")
	var on_floor: bool = absf(lp.y - wy) < 0.45
	# les sables mouvants
	var in_sand: bool = on_floor and _in_rects(lp, S["sables_mouvants"]) and not _in_rects(lp, S["chemins_a"]) and not _in_rects(lp, S["gues"])
	if in_sand:
		_sink_t += delta
		if hero != null:
			hero.sol_mult = 0.45
			hero.sink = minf(_sink_t * 0.35, 0.8)
		_once("sable", "Des sables mouvants ! Tu t'enfonces… Sors-en vite, et reste sur les dalles.", 4.0)
		if _sink_t > 2.4:
			_fall_back("Le sable t'avale… Tu te débats, et tu ressors, à bout de souffle, à l'entrée de la salle.", 1)
	elif _sink_t > 0.0:
		_sink_t = maxf(_sink_t - delta * 2.0, 0.0)
		if hero != null:
			hero.sol_mult = 1.0
			hero.sink = maxf(float(hero.sink) - delta * 1.5, 0.0)
	if r != "sables_b":
		return
	# les lames qui balancent (le disque tranche en travers du couloir)
	_blade_cd = maxf(_blade_cd - delta, 0.0)
	var b0: float = L + 36.0
	var blades: Array = S["lames"]
	for i in range(blades.size()):
		var piv: Node3D = blades[i]
		var ang: float = sin(_clock * 1.7 + float(piv.get_meta("phase"))) * 1.05
		piv.rotation.z = ang
		var z: float = b0 + 7.0 + i * 7.0
		var bx: float = 5.5 * sin(ang)
		var by: float = 6.6 - 5.5 * cos(ang)
		var feet: float = lp.y - wy
		if absf(lp.z - z) < 0.75 and absf(lp.x - bx) < 1.5 and by - 0.75 < feet + 1.8 and by + 0.75 > feet and _blade_cd <= 0.0:
			_blade_cd = 1.0
			_hurt(2, _wl("sables", Vector3(bx, wy + 1.0, z + 1.0)))
			push_player((salles.wxf("sables") as Transform3D).basis * Vector3(0, 0, -1.4))
			main.sfx("lame", p + Vector3.UP)
			_once("lame", "Une lame t'a fauché ! Attends qu'elle passe, puis fonce.", 4.0)
	# les dalles à dards
	for pp in S["dalles_dards"]:
		var key: String = str(pp)
		_dart_cd[key] = maxf(float(_dart_cd.get(key, 0.0)) - delta, 0.0)
		var pv: Vector3 = pp
		if on_floor and Vector2(p.x - pv.x, p.z - pv.z).length() < 0.85 and float(_dart_cd[key]) <= 0.0:
			_dart_cd[key] = 2.5
			main.sfx("dalle_clic", pv)
			_fire_darts(pv)
	_tick_darts(delta, p)


func _fire_darts(at: Vector3) -> void:
	var xf: Transform3D = salles.wxf("sables")
	var side: Vector3 = xf.basis * Vector3(1, 0, 0)
	var fwd: Vector3 = xf.basis * Vector3(0, 0, 1)
	for k in range(3):
		var d := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.03
		cm.height = 0.35
		cm.radial_segments = 6
		d.mesh = cm
		d.material_override = salles.kit.mat("fonte_c")
		salles.add_child(d)
		var from: Vector3 = at - side * 4.8 + Vector3.UP * (0.8 + k * 0.4) + fwd * ((k - 1) * 0.35)
		d.global_position = from
		d.global_basis = Basis.looking_at(side, Vector3.UP) * Basis(Vector3.RIGHT, -PI * 0.5)
		_darts.append({"node": d, "from": from, "dir": side, "t": -0.3, "hit": false})
	main.sfx("dard", at - side * 4.8 + Vector3.UP)


func _tick_darts(delta: float, p: Vector3) -> void:
	for i in range(_darts.size() - 1, -1, -1):
		var d: Dictionary = _darts[i]
		d["t"] = float(d["t"]) + delta
		var t: float = float(d["t"])
		var node: Node3D = d["node"]
		if t < 0.0:
			continue
		var pos: Vector3 = (d["from"] as Vector3) + (d["dir"] as Vector3) * t * 22.0
		node.global_position = pos
		if not bool(d["hit"]) and Vector2(pos.x - p.x, pos.z - p.z).length() < 0.5 and pos.y > p.y and pos.y < p.y + 1.9:
			d["hit"] = true
			_hurt(1, d["from"])
			_once("dards", "Des dards jaillissent des murs ! Ces dalles plus sombres sont piégées.", 4.0)
		if t > 0.5:
			node.queue_free()
			_darts.remove_at(i)


# =================================================================== l'Aile des Rouages

func _start_motor() -> void:
	var first: bool = _plat_run <= 0.0
	_plat_run = 45.0
	var R: Dictionary = _w("rouages")
	main.sfx("mecanisme", R["moteur_pos"])
	if first:
		_say("Le Rouage prend dans le moteur ! Les engrenages grippés se décollent, tournent… et les plates-formes se mettent en route au-dessus du gouffre. Pour combien de temps ?", 7.0)


## Les plates-formes du gouffre (elles avancent tant que le moteur tourne).
func _tick_platforms(delta: float) -> void:
	var R: Dictionary = _w("rouages")
	if _plat_run > 0.0:
		_plat_run -= delta
		_plat_t += delta
		(R["moteur"] as Node3D).rotate_object_local(Vector3.UP, delta * 2.5)
		if _plat_run <= 0.0 and room.begins_with("rouages"):
			main.sfx("mecanisme", R["moteur_pos"], -6.0)
			_say("Le moteur s'essouffle… et s'arrête. Les plates-formes s'immobilisent.", 4.0)
	var plats: Array = R["plates_formes"]
	for i in range(plats.size()):
		var pl: Dictionary = plats[i]
		var u: float = fmod(_plat_t + i * 1.5, 9.0) / 9.0
		var f: float = 1.0 - clampf(absf(u * 2.0 - 1.0) * 1.25 - 0.125, 0.0, 1.0)
		f = smoothstep(0.0, 1.0, f)
		var body: Node3D = pl["body"]
		body.global_position = (pl["a"] as Vector3).lerp(pl["b"], f)
		if _plat_run > 0.0:
			(pl["gear"] as Node3D).rotate_object_local(Vector3.UP, delta * 3.0)


func _tick_rouages(delta: float, p: Vector3, r: String) -> void:
	var R: Dictionary = _w("rouages")
	var L: float = R["L"]
	var wy: float = R["wy"]
	var lp: Vector3 = _local("rouages", p)
	_tick_platforms(delta)
	if r == "rouages_a" and not bool(state["rouages_a"]) and lp.z > L + 26.2 and absf(lp.y - wy) < 0.6:
		state["rouages_a"] = true
		var g: Node3D = salles.gates["rouages_a"]
		create_tween().tween_property(g, "position:y", float(g.get_meta("bas")) + 4.6, 2.5).set_trans(Tween.TRANS_SINE)
		main.sfx("grille", g.global_position)
		main.jingle("decouverte")
		_say("Tu as traversé le gouffre ! Sous tes pieds, une dalle s'enfonce d'un cran : la grille du fond se lève en grinçant.", 6.0)
	if r != "rouages_b":
		return
	# les pistons : tous les 4 s, décalés
	_piston_cd = maxf(_piston_cd - delta, 0.0)
	var b0: float = L + 36.0
	var pistons: Array = R["pistons"]
	for i in range(pistons.size()):
		var head: Node3D = pistons[i]
		var t: float = fmod(_clock + float(head.get_meta("phase")), 4.0)
		var y: float = 5.6
		if t < 0.22:
			y = lerpf(5.6, 0.0, t / 0.22)
		elif t < 1.0:
			y = 0.0
		elif t < 2.6:
			y = lerpf(0.0, 5.6, (t - 1.0) / 1.6)
		var z: float = b0 + 8.0 + i * 7.0
		head.global_position = _wl("rouages", Vector3(0, wy + y, z))
		if t >= 0.2 and t - delta < 0.2:
			main.sfx("piston", head.global_position)
			if main.combat_v28 != null:
				main.combat_v28.puff(head.global_position + Vector3.UP * 0.1, Color(0.85, 0.85, 0.88))
		# il écrase : on est chassé de dessous juste avant le contact
		if t < 0.22 and y < 2.4 and absf(lp.z - z) < 1.6 and absf(lp.x) < 5.0 and lp.y - wy < 2.0 and _piston_cd <= 0.0:
			_piston_cd = 1.0
			_hurt(2, _wl("rouages", Vector3(0, wy + 1.0, z)))
			var dirz: float = -1.0 if lp.z < z else 1.0
			push_player((salles.wxf("rouages") as Transform3D).basis * Vector3(0, 0.05, dirz * (1.7 - absf(lp.z - z) + 0.6)))
			_once("piston", "Écrasé par un piston ! Compte : il frappe, il remonte… passe pendant qu'il est en haut.", 5.0)
	# les tapis roulants : ils ramènent vers l'entrée
	if absf(lp.y - wy) < 0.5 and _in_rects(lp, R["tapis"]):
		push_player((salles.wxf("rouages") as Transform3D).basis * Vector3(0, 0, -1.7 * delta))


# =================================================================== l'Aile de la Lune

func _turn_dial(i: int) -> void:
	var a: Array = state["lune_cadrans"]
	a[i] = (int(a[i]) + 1) % 4
	main.sfx("clochette", (_w("lune")["cadrans"][i] as Node3D).global_position, -6.0)
	_place_dials(true)
	main._show_message_v28("Le %s cadran montre %s." % [ORDINAL[i], PHASES[int(a[i])]])
	for k in range(4):
		if int(a[k]) != DIAL_GOAL[k]:
			return
	state["lune_a"] = true
	main.jingle("decouverte")
	var g: Node3D = salles.gates["lune_a"]
	create_tween().tween_property(g, "position:y", float(g.get_meta("bas")) + 4.6, 3.0).set_trans(Tween.TRANS_SINE)
	main.sfx("pierre_glisse", g.global_position)
	_say("Pleine, décroissante, nouvelle, croissante : les quatre cadrans s'alignent, un tintement de cristal… et la porte d'ardoise s'efface vers le haut.", 7.0)


func _place_dials(animate: bool) -> void:
	if not built:
		return
	var a: Array = state["lune_cadrans"]
	var dials: Array = _w("lune")["cadrans"]
	for i in range(dials.size()):
		var d: Node3D = dials[i]
		var target: float = -float(int(a[i])) * TAU / 4.0
		if animate:
			var cur: float = d.rotation.z
			while target > cur + 0.01:
				target -= TAU
			create_tween().tween_property(d, "rotation:z", target, 0.35).set_trans(Tween.TRANS_BACK)
		else:
			d.rotation.z = target


func _tick_lune(delta: float, p: Vector3, r: String) -> void:
	if r != "lune_b":
		if not _hands.is_empty():
			_clear_hands()
		_unsink()
		return
	var Lw: Dictionary = _w("lune")
	var wy: float = Lw["wy"]
	var lp: Vector3 = _local("lune", p)
	var hero: Node = main.get("hero_v28")
	var pw: Node = main.get("pouvoirs_v63")
	var moon: bool = pw != null and pw.lune_active()
	var on_dark: bool = absf(lp.y - wy) < 0.45 and _in_rects(lp, Lw["ombres"])
	if on_dark and not moon:
		_shadow_t += delta
		if hero != null:
			hero.sol_mult = 0.4
		if _hands.is_empty():
			_spawn_hands(p)
		for h in _hands:
			var hn: Node3D = h
			hn.global_position = hn.global_position.lerp(p + (hn.get_meta("off") as Vector3), clampf(delta * 6.0, 0.0, 1.0))
		if _shadow_t > 1.4:
			_shadow_t = 0.0
			_hurt(1, p + Vector3(0.5, 0, 0.5))
			_once("ombres", "Des mains d'ombre sortent des dalles noires et t'agrippent ! Elles craignent sûrement la lumière… celle de la lune ?", 6.0)
	else:
		_shadow_t = 0.0
		if hero != null and float(hero.sol_mult) < 1.0:
			hero.sol_mult = 1.0
		if not _hands.is_empty():
			_clear_hands()
			if moon:
				_once("ombres_lune", "Les mains d'ombre reculent devant la Lueur de lune et rentrent sous les dalles !", 4.0)


func _clear_hands() -> void:
	for h in _hands:
		var hn: Node3D = h
		var tw := hn.create_tween()
		tw.tween_property(hn, "scale", Vector3(1, 0.01, 1), 0.3)
		tw.tween_callback(hn.queue_free)
	_hands.clear()


func _spawn_hands(p: Vector3) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.02, 0.02, 0.04)
	m.roughness = 1.0
	m.emission_enabled = true
	m.emission = Color(0.14, 0.08, 0.3)
	for k in range(4):
		var h := Node3D.new()
		salles.add_child(h)
		var arm := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.035
		cm.bottom_radius = 0.1
		cm.height = 1.0
		cm.radial_segments = 8
		arm.mesh = cm
		arm.material_override = m
		arm.position.y = 0.5
		h.add_child(arm)
		for f in range(4):
			var finger := MeshInstance3D.new()
			var fm := CylinderMesh.new()
			fm.top_radius = 0.004
			fm.bottom_radius = 0.022
			fm.height = 0.28
			fm.radial_segments = 5
			finger.mesh = fm
			finger.material_override = m
			finger.position = Vector3((f - 1.5) * 0.04, 1.08, 0)
			finger.rotation.z = (f - 1.5) * 0.25
			finger.rotation.x = 0.5
			h.add_child(finger)
		var a: float = TAU * k / 4.0 + 0.4
		var off := Vector3(cos(a) * 0.45, -0.1, sin(a) * 0.45)
		h.set_meta("off", off)
		h.global_position = p + off + Vector3.DOWN * 0.8
		h.rotation = Vector3(sin(a) * 0.45, 0, -cos(a) * 0.45)
		_hands.append(h)
	main.sfx("ombre_mains", p + Vector3.UP * 0.3)


# =================================================================== sauvegarde, trouvailles

func trouvailles() -> Dictionary:
	var t := {"entree_coeur": 1 if bool(state["visite"]) else 0, "coeur_ouvert": 1 if bool(state["coeur_ouvert"]) else 0,
		"gardien_coeur": 1 if bool(state["gardien"]) else 0}
	for n in WINGS:
		t["aile_" + n] = 1 if bool(state[n + "_cristal"]) else 0
	return t


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	_reset_fight()
	state = _defaults()
	for k in state:
		if not d.has(k):
			continue
		if state[k] is Array:
			var a: Variant = d[k]
			if a is Array and (a as Array).size() == (state[k] as Array).size():
				var out: Array = []
				for v in a:
					out.append(int(v) % 4)
				state[k] = out
		elif state[k] is int:
			state[k] = clampi(int(d[k]), 0, WATER.size() - 1)
		else:
			state[k] = bool(d[k])
	_said.clear()
	room = ""
	checkpoint = []
	_plat_run = 0.0
	_plat_t = 0.0
	_victory = false
	if built:
		_apply_built()
