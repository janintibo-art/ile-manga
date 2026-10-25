extends Node3D
## V54 : le ciel — Ventaile l'aigle géant, l'île flottante et la Citadelle des Nuées.
##
## La quête (après l'île des nains) :
##  1. Le roi Thorgal (une fois ses sujets aidés) parle du château dans le ciel et confie une
##     selle naine : seuls les grands aigles volent si haut. Ventaile, la dernière, est
##     prisonnière au bord du cratère : les golems l'ont enchaînée.
##  2. Au nid, on brise à l'arme la rune qui scelle la chaîne, puis on nourrit Ventaile
##     (trois poissons) ; on installe la selle : elle t'accepte, et te laisse une plume pour
##     l'appeler (G au PC, bouton X en VR, ou « Utiliser » dans l'inventaire).
##  3. Vol libre : au PC Z / S vitesse, Q / D virer, Espace monter, Ctrl descendre, E se poser ;
##     en VR stick gauche (virer, monter / descendre), gâchettes (accélérer / freiner), A se poser.
##  4. L'île flottante, à 150 m au-dessus de l'océan, au sud : on se pose sur l'Aire des Vents.
##  5. La Citadelle : gargouilles dans la cour ; la bibliothèque (le Chant des Quatre Cloches) ;
##     le beffroi (sonner les cloches dans l'ordre -> Cristal du Levant) ; la salle d'armes
##     (trois armures animées -> Cristal du Couchant) ; les deux cristaux ouvrent le Sceau des
##     Vents et la grande porte du donjon ; la salle du trône ; la Tour des Tempêtes et son
##     gardien, Sire Orage ; le trésor des Rois-Ciel.

const IleScript = preload("res://scripts/ile_celeste_v54.gd")
const ChateauScript = preload("res://scripts/chateau_v54.gd")
const AigleScript = preload("res://scripts/aigle_v54.gd")
const BossScript = preload("res://scripts/boss_orage_v54.gd")
const CibleScript = preload("res://scripts/cible_v54.gd")
const Rocks = preload("res://scripts/rocks_v26.gd")
const Decor = preload("res://scripts/decor_v53.gd")
const FISH := ["sardine", "maquereau", "dorade", "bar", "poisson_perroquet", "merou"]
const BELL_ORDER := ["vague", "soleil", "lune", "vent"]
const BELL_NAMES := {"vague": "de la Vague", "soleil": "du Soleil", "lune": "de la Lune", "vent": "du Vent"}
const NO_FLY_R: float = 36.0

var main: Node
var pc: bool = true
var ile: Node3D
var chateau: Node3D
var aigle: Node3D
var state: Dictionary = {}
var riding: bool = false
var fight: bool = false
var boss: Node3D
var nest_pos: Vector3
var nest_yaw: float = 0.0
var esplanade: Vector3
var _anchor: Node3D
var _chain: Node3D
var _chests: Dictionary = {}
var _bell_seq: Array = []
var _wave: Dictionary = {}
var _summoned: Array = []
var _mount_it: Dictionary = {}
var _feed_it: Dictionary = {}
var _clock: float = 0.0
var _warn_clock: float = 0.0
var _cry_clock: float = 20.0
var _was_on_sky: bool = false
var _vr_a: bool = false
var _last_flap: int = 0
var _bar_vr: Label3D


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	state = _defaults()


func _defaults() -> Dictionary:
	return {"aigle": "", "poissons": 0, "visite_ciel": false, "vue_ciel": false, "cour": false, "livre": false,
		"cloches": false, "coffre_levant": false, "armurerie": false, "coffre_couchant": false, "sceau": false,
		"salle": false, "boss": false, "tresor": false, "perche": [], "en_vol": []}


# =================================================================== construction

func build() -> void:
	ile = IleScript.new()
	ile.name = "Ile_celeste_v54"
	add_child(ile)
	ile.build(pc)
	chateau = ChateauScript.new()
	chateau.name = "Citadelle_des_Nuees_v54"
	add_child(chateau)
	chateau.position = Vector3(ile.CENTER.x + ile.CASTLE.x, ile.Y0 + ile.PLATEAU_H, ile.CENTER.z + ile.CASTLE.y)
	chateau.build(main, pc)
	_build_esplanade()
	_build_nest()
	aigle = AigleScript.new()
	add_child(aigle)
	aigle.setup(main)
	aigle.landed.connect(_on_landed)
	for id in ["coffre_levant", "coffre_couchant", "tresor"]:
		var at: Vector3
		match id:
			"coffre_levant":
				at = chateau.at("coffre_levant")
			"coffre_couchant":
				at = chateau.at("coffre_couchant")
			"tresor":
				at = chateau.at("arene") + Vector3(0, 0, -2.5)
		_chests[id] = _chest(at, 0.0 if id != "coffre_couchant" else PI * 0.5, id == "tresor")
	apply_state()
	print("ILE_MANGA_V54: île flottante (", ile.CENTER, "), Citadelle des Nuées, nid de Ventaile à ", nest_pos)


## L'Aire des Vents : un dallage rond au sud de l'île, un cercle de runes, une statue d'aigle.
func _build_esplanade() -> void:
	var l: Vector2 = ile.ESPLANADE
	esplanade = Vector3(ile.CENTER.x + l.x, ile.Y0 + ile.PLATEAU_H, ile.CENTER.z + l.y)
	var root := Node3D.new()
	root.name = "Aire_des_Vents"
	root.position = esplanade
	add_child(root)
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = ile.ESPLANADE_R
	cm.bottom_radius = ile.ESPLANADE_R + 0.3
	cm.height = 0.3
	cm.radial_segments = 40
	disc.mesh = cm
	disc.material_override = chateau._mat("dalles")
	disc.position = Vector3(0, -0.1, 0)
	root.add_child(disc)
	var rune := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = ile.ESPLANADE_R - 1.6
	tm.outer_radius = ile.ESPLANADE_R - 1.35
	tm.rings = 48
	tm.ring_segments = 4
	rune.mesh = tm
	rune.material_override = chateau._mat("rune")
	rune.scale = Vector3(1, 0.04, 1)
	rune.position.y = 0.06
	root.add_child(rune)
	for k in range(8):
		var a: float = TAU * k / 8.0
		var st := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.7, 1.6, 0.5)
		st.mesh = bm
		st.material_override = chateau._mat("pierre")
		st.position = Vector3(cos(a) * (ile.ESPLANADE_R + 0.2), 0.8, sin(a) * (ile.ESPLANADE_R + 0.2))
		st.rotation.y = -a
		root.add_child(st)
	# La statue : Ventaile en pierre, tournée vers le large
	var statue: Node3D = chateau._stone_eagle(chateau.to_local(esplanade + Vector3(0, 0, ile.ESPLANADE_R - 1.0)), PI, 0.6)
	statue.name = "Statue_aire"
	# Deux braseros éteints-allumés à l'entrée du chemin
	var ember := StandardMaterial3D.new()
	ember.albedo_color = Color(1.0, 0.45, 0.12)
	ember.emission_enabled = true
	ember.emission = Color(1.0, 0.4, 0.1)
	ember.emission_energy_multiplier = 2.4
	for sx in [-1.0, 1.0]:
		Decor.brazier(root, Vector3(sx * 3.6, 0, -ile.ESPLANADE_R - 0.5), ember)


## Le nid de Ventaile, au bord du cratère de la Montagne de Feu.
func _build_nest() -> void:
	var n: Node = main.nains_v46
	if n == null or n.ile == null:
		return
	var pk: Vector3 = n.ile.peak_world()
	var te: Vector3 = n.ile.trail_end
	var a0: float = atan2(te.z - pk.z, te.x - pk.x)
	var a: float = a0 + 0.42
	var r: float = n.ile.CRATER_R + 8.5
	var x: float = pk.x + cos(a) * r
	var z: float = pk.z + sin(a) * r
	var top: float = maxf(n.ile.height(x, z), te.y) + 0.9
	nest_pos = Vector3(x, top, z)
	var out := Vector2(cos(a), sin(a))
	nest_yaw = atan2(-out.x, -out.y) + PI          # regard vers le large
	var root := Node3D.new()
	root.name = "Nid_de_Ventaile"
	root.position = nest_pos
	add_child(root)
	var body := StaticBody3D.new()
	body.name = "Nid_collision"
	body.collision_layer = 1
	root.add_child(body)
	# Le promontoire : un gros rocher plat, et des marches vers le belvédère du sentier
	var rock_m: Material = Rocks.material(Color(0.32, 0.3, 0.3), 0.0, 0.25)
	var plat := MeshInstance3D.new()
	plat.mesh = Rocks.shape(5530, Vector3(11.0, 4.0, 10.0), 0.7, 0.18, 0.75, 24)
	plat.material_override = rock_m
	plat.position = Vector3(0, -2.05, 0)
	root.add_child(plat)
	body.add_child(Rocks.collision_for(plat.mesh, plat.transform))
	var to_trail := Vector3(te.x - x, 0, te.z - z)
	var steps: int = 3
	for k in range(steps):
		var t: float = (k + 1.0) / (steps + 1.0)
		var sp := Vector3(to_trail.x * t, lerpf(0.0, te.y - top, t) - 0.9, to_trail.z * t)
		var stone := MeshInstance3D.new()
		stone.mesh = Rocks.shape(5531 + k, Vector3(3.2, 1.8, 3.0), 0.75, 0.15, 0.7, 18)
		stone.material_override = rock_m
		stone.position = sp
		root.add_child(stone)
		body.add_child(Rocks.collision_for(stone.mesh, stone.transform))
	# Le nid : une couronne de branches entrelacées, du duvet, des os
	var wood := StandardMaterial3D.new()
	wood.albedo_texture = load("res://assets/textures/flora/bark.png")
	wood.albedo_color = Color(0.5, 0.4, 0.3)
	wood.roughness = 0.95
	var rng := RandomNumberGenerator.new()
	rng.seed = 5532
	for k in range(46):
		var ang: float = rng.randf() * TAU
		var rad: float = rng.randf_range(2.3, 3.4)
		var br := MeshInstance3D.new()
		var cy := CylinderMesh.new()
		cy.top_radius = rng.randf_range(0.04, 0.09)
		cy.bottom_radius = cy.top_radius * 1.3
		cy.height = rng.randf_range(1.6, 3.2)
		cy.radial_segments = 5
		cy.rings = 1
		br.mesh = cy
		br.material_override = wood
		br.position = Vector3(cos(ang) * rad, rng.randf_range(0.05, 0.45), sin(ang) * rad)
		br.rotation = Vector3(PI * 0.5 + rng.randf_range(-0.3, 0.3), -ang + rng.randf_range(-0.6, 0.6), rng.randf_range(-0.2, 0.2))
		root.add_child(br)
	var down := StandardMaterial3D.new()
	down.albedo_color = Color(0.72, 0.62, 0.48)
	down.roughness = 1.0
	var bed := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 2.6
	bc.bottom_radius = 2.2
	bc.height = 0.3
	bed.mesh = bc
	bed.material_override = down
	bed.position = Vector3(0, 0.0, 0)
	root.add_child(bed)
	# La chaîne des golems : un bloc de basalte, une rune bleue (on la brise à l'arme)
	var anchor_at := Vector3(cos(a + PI * 0.5) * 3.8, 0.0, sin(a + PI * 0.5) * 3.8)
	var block := MeshInstance3D.new()
	block.mesh = Rocks.shape(5540, Vector3(1.6, 1.4, 1.4), 0.6, 0.2)
	block.material_override = Rocks.material(Color(0.2, 0.19, 0.2), 0.0, 0.3)
	block.position = anchor_at + Vector3.UP * 0.5
	root.add_child(block)
	body.add_child(Rocks.collision_for(block.mesh, block.transform))
	_anchor = CibleScript.new()
	_anchor.name = "Rune_chaine"
	_anchor.hit_radius = 0.9
	_anchor.hit_height = 0.7
	_anchor.position = anchor_at + Vector3.UP * 0.05
	root.add_child(_anchor)
	_anchor.touched.connect(_on_rune_hit)
	var rune_m := StandardMaterial3D.new()
	rune_m.albedo_color = Color(0.35, 0.8, 1.0)
	rune_m.emission_enabled = true
	rune_m.emission = Color(0.35, 0.8, 1.0)
	rune_m.emission_energy_multiplier = 3.0
	var plaque := MeshInstance3D.new()
	var pb := BoxMesh.new()
	pb.size = Vector3(0.5, 0.5, 0.06)
	plaque.mesh = pb
	plaque.material_override = rune_m
	plaque.position = Vector3(0, 0.95, 0)
	plaque.look_at_from_position(anchor_at + Vector3.UP * 1.0, Vector3(0, 1.0, 0), Vector3.UP)
	plaque.position = Vector3(0, 0.95, 0) + (-anchor_at).normalized() * 0.55
	_anchor.add_child(plaque)
	plaque.name = "Rune"
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.35, 0.8, 1.0)
	glow.light_energy = 1.2
	glow.omni_range = 4.0
	glow.position = Vector3(0, 1.0, 0)
	_anchor.add_child(glow)
	_chain = Node3D.new()
	_chain.name = "Chaine"
	root.add_child(_chain)
	var iron: Material = Decor.forged_iron()
	var from: Vector3 = anchor_at + Vector3.UP * 0.6
	var to := Vector3(0.3, 0.35, 0.35)
	for k in range(12):
		var t2: float = (k + 0.5) / 12.0
		var p: Vector3 = from.lerp(to, t2) + Vector3.DOWN * sin(t2 * PI) * 0.35
		var link := MeshInstance3D.new()
		var lt := TorusMesh.new()
		lt.inner_radius = 0.07
		lt.outer_radius = 0.12
		lt.rings = 10
		lt.ring_segments = 6
		link.mesh = lt
		link.material_override = iron
		link.position = p
		link.look_at_from_position(p, to, Vector3.UP)
		link.rotate_object_local(Vector3.FORWARD, PI * 0.5 * (k % 2))
		link.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		_chain.add_child(link)


## Un coffre (bois et ferrures) avec son couvercle sur charnière, caché tant qu'il n'est pas gagné.
func _chest(at: Vector3, yaw: float, royal: bool) -> Node3D:
	var c := Node3D.new()
	c.name = "Coffre_ciel"
	add_child(c)
	c.global_position = at
	c.rotation.y = yaw
	var wood: Material = chateau._mat("bois")
	var band: Material = chateau._mat("or") if royal else Decor.forged_iron()
	var s: float = 1.3 if royal else 1.0
	_cbox(c, Vector3(1.1, 0.6, 0.7) * s, Vector3(0, 0.3 * s, 0), wood)
	for x in [-0.42, 0.0, 0.42]:
		_cbox(c, Vector3(0.06, 0.62, 0.72) * s, Vector3(x * s, 0.3 * s, 0), band)
	var hinge := Node3D.new()
	hinge.name = "Charniere"
	hinge.position = Vector3(0, 0.6 * s, -0.35 * s)
	c.add_child(hinge)
	_cbox(hinge, Vector3(1.1, 0.28, 0.7) * s, Vector3(0, 0.14 * s, 0.35 * s), wood)
	for x2 in [-0.42, 0.42]:
		_cbox(hinge, Vector3(0.06, 0.3, 0.72) * s, Vector3(x2 * s, 0.14 * s, 0.35 * s), band)
	_cbox(c, Vector3(0.14, 0.18, 0.06) * s, Vector3(0, 0.55 * s, 0.37 * s), chateau._mat("or"))
	c.visible = false
	return c


func _cbox(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)


## Les interactions (E / gâchette), les torches et les sons : quand le temple (qui les gère) existe.
func build_quest() -> void:
	var d: Node = main.donjon_v35
	var I: Array = d._interactions
	I.append({"id": "chaine_aigle", "pos": nest_pos, "radius": 4.6, "text": "E : examiner la chaîne", "vr": "Gâchette : examiner la chaîne",
		"call": _examine_chain, "when": func(): return str(state["aigle"]) == ""})
	_feed_it = {"id": "nourrir_aigle", "pos": nest_pos, "radius": 4.6, "text": "E : donner un poisson à Ventaile", "vr": "Gâchette : donner un poisson",
		"call": _feed, "when": func(): return str(state["aigle"]) == "libre"}
	I.append(_feed_it)
	I.append({"id": "seller_aigle", "pos": nest_pos, "radius": 4.6, "text": "E : installer la selle sur Ventaile", "vr": "Gâchette : installer la selle",
		"call": _saddle_up, "when": func(): return str(state["aigle"]) == "nourrie"})
	_mount_it = {"id": "monter_aigle", "pos": nest_pos, "radius": 4.3, "text": "E : monter sur Ventaile", "vr": "Gâchette : monter sur Ventaile",
		"call": mount, "when": func(): return str(state["aigle"]) == "amie" and not riding and aigle.is_landed()}
	I.append(_mount_it)
	# La Citadelle
	I.append({"id": "lutrin", "pos": chateau.at("lutrin"), "radius": 1.8, "text": "E : lire le grand livre", "vr": "Gâchette : lire le livre", "call": _read_book})
	I.append({"id": "beffroi_monter", "pos": chateau.at("beffroi_porte"), "radius": 2.4, "text": "E : monter au beffroi", "vr": "Gâchette : monter au beffroi",
		"call": func(): _climb("beffroi")})
	I.append({"id": "beffroi_descendre", "pos": chateau.at("beffroi_haut"), "radius": 1.8, "text": "E : redescendre dans la cour", "vr": "Gâchette : redescendre",
		"call": func(): _climb("cour_beffroi")})
	for b in BELL_ORDER:
		var bname: String = b
		I.append({"id": "cloche_" + bname, "pos": chateau.at("cloche_" + bname), "radius": 1.3, "text": "E : sonner la cloche %s" % BELL_NAMES[bname],
			"vr": "Gâchette : sonner la cloche", "call": func(): _ring(bname), "when": func(): return not bool(state["cloches"])})
	I.append({"id": "coffre_levant", "pos": chateau.at("coffre_levant"), "radius": 1.8, "text": "E : ouvrir le coffre", "vr": "Gâchette : ouvrir le coffre",
		"call": func(): _open_chest("coffre_levant"), "when": func(): return bool(state["cloches"]) and not bool(state["coffre_levant"])})
	I.append({"id": "coffre_couchant", "pos": chateau.at("coffre_couchant"), "radius": 1.8, "text": "E : ouvrir le coffre", "vr": "Gâchette : ouvrir le coffre",
		"call": func(): _open_chest("coffre_couchant"), "when": func(): return bool(state["armurerie"]) and not bool(state["coffre_couchant"])})
	I.append({"id": "sceau_vents", "pos": chateau.at("sceau"), "radius": 2.0, "text": "E : examiner le Sceau des Vents", "vr": "Gâchette : le Sceau des Vents",
		"call": _seal, "when": func(): return not bool(state["sceau"])})
	I.append({"id": "tour_monter", "pos": chateau.at("escalier_tour"), "radius": 1.8, "text": "E : monter à la Tour des Tempêtes", "vr": "Gâchette : monter à la tour",
		"call": func(): _climb("arene")})
	I.append({"id": "tour_descendre", "pos": chateau.at("arene_arrivee"), "radius": 1.6, "text": "E : redescendre dans la salle du trône", "vr": "Gâchette : redescendre",
		"call": func(): _climb("salle"), "when": func(): return not fight})
	I.append({"id": "tresor_ciel", "pos": chateau.at("arene") + Vector3(0, 0, -2.5), "radius": 2.0, "text": "E : ouvrir le trésor des Rois-Ciel", "vr": "Gâchette : ouvrir le trésor",
		"call": func(): _open_chest("tresor"), "when": func(): return bool(state["boss"]) and not bool(state["tresor"]) and not fight})
	# Les torches de la cour (le temple sait faire les flammes)
	for t in chateau.points.get("torches", []):
		d._torch(chateau, t[0], t[1], 1.4)
	# Les sons : les chutes, le vent là-haut, la fontaine
	var amb: Node = main.get("ambiance_v49")
	if amb != null:
		for f in ile.falls:
			amb.add_emitter(self, (f as Vector3) + Vector3.UP * 2.0, "emetteurs/cascade", 4.0, 26.0, 260.0)
		for s in ile.streams:
			var rim: Vector2 = s["rim"]
			amb.add_emitter(self, ile.world(rim * 0.95, 0.5), "emetteurs/cascade", -2.0, 8.0, 60.0)
			amb.add_emitter(self, ile.world(s["spring"], 0.4), "emetteurs/ruisseau", -8.0, 4.0, 26.0)
		amb.add_emitter(self, chateau.at("fontaine") + Vector3.UP * 1.0, "emetteurs/ruisseau", -10.0, 3.0, 22.0)


# =================================================================== état

func serialize() -> Dictionary:
	var d: Dictionary = state.duplicate(true)
	if aigle != null and str(state["aigle"]) == "amie":
		var p: Vector3 = aigle.global_position
		if riding:
			d["en_vol"] = [p.x, p.y, p.z, aigle.yaw]
			d["perche"] = []
		elif aigle.is_landed():
			d["perche"] = [p.x, p.y, p.z, aigle.yaw]
			d["en_vol"] = []
	return d


func load_data(d: Dictionary) -> void:
	if riding:
		_end_ride()
	_reset_fight()
	_despawn_wave()
	state = _defaults()
	for k in state:
		if d.has(k):
			var v: Variant = d[k]
			if state[k] is bool:
				state[k] = bool(v)
			elif state[k] is int:
				state[k] = int(v)
			elif state[k] is Array:
				state[k] = (v as Array).duplicate() if v is Array else []
			else:
				state[k] = str(v)
	_bell_seq.clear()
	apply_state()
	# Sauvegardé en plein vol : on reprend le vol là où on était
	var fly: Array = state["en_vol"]
	if str(state["aigle"]) == "amie" and fly.size() == 4:
		aigle.perch_at(Vector3(float(fly[0]), float(fly[1]), float(fly[2])), float(fly[3]))
		aigle.state = "vol"
		aigle.speed = aigle.CRUISE
		aigle._fold = 0.0
		aigle._tuck = 1.0
		_begin_ride(false)


func apply_state() -> void:
	if aigle == null:
		return
	var a: String = str(state["aigle"])
	_chain.visible = a == ""
	_anchor.active = a == ""
	_anchor.visible = a == ""
	aigle.show_saddle(a == "amie")
	var perch: Array = state["perche"]
	if a == "":
		aigle.chain_at(nest_pos, nest_yaw)
	elif a == "amie" and perch.size() == 4:
		aigle.perch_at(Vector3(float(perch[0]), float(perch[1]), float(perch[2])), float(perch[3]))
	else:
		aigle.perch_at(nest_pos, nest_yaw)
	chateau.show_seal(bool(state["sceau"]), bool(state["sceau"]))
	if bool(state["sceau"]):
		chateau.open_keep(true)
	else:
		chateau.close_keep()
	_show_chest("coffre_levant", bool(state["cloches"]), bool(state["coffre_levant"]))
	_show_chest("coffre_couchant", bool(state["armurerie"]), bool(state["coffre_couchant"]))
	_show_chest("tresor", bool(state["boss"]), bool(state["tresor"]))


func _show_chest(id: String, shown: bool, opened: bool) -> void:
	var c: Node3D = _chests[id]
	c.visible = shown
	(c.get_node("Charniere") as Node3D).rotation.x = -1.8 if opened else 0.0


func tamed() -> bool:
	return str(state["aigle"]) == "amie"


# =================================================================== lieux

## Le joueur est-il sur l'île flottante (ou dans sa Citadelle) ?
func on_sky(p: Vector3) -> bool:
	return ile != null and ile.near(p, 6.0) and p.y > ile.Y0 - 14.0


func hostile_zone(p: Vector3) -> bool:
	if chateau == null or not on_sky(p):
		return false
	var l: Vector3 = chateau.to_local(p)
	if absf(l.x) < chateau.HALF and absf(l.z) < chateau.HALF and l.y > -2.0 and l.y < 13.0:
		return true
	var ar: Vector3 = chateau.points["arene"]
	return Vector2(l.x - ar.x, l.z - ar.z).length() < chateau.ARENA_R + 2.0 and l.y > ar.y - 3.0 and l.y < ar.y + 8.0


func respawn_point() -> Array:
	return [esplanade + Vector3(0, 0.15, 3.0), Vector3(0, 0, -1)]


## Le joueur à pied sur l'île : il ne s'avance pas au-delà du bord (main._limit_on_foot_v29).
func walkable_at(p: Vector3) -> bool:
	return ile.walkable(p.x, p.z)


func _room(p: Vector3) -> String:
	var l: Vector3 = chateau.to_local(p)
	if l.y < -1.5 or l.y > 9.0:
		return ""
	var inner: float = chateau.HALF - chateau.WALL_T
	if absf(l.x) > inner or absf(l.z) > inner:
		return ""
	if l.z < chateau.KEEP_Z1 and absf(l.x) < chateau.KEEP_X:
		return "salle"
	if l.x < -inner + 8.0 and l.z > -5.0 and l.z < 11.0:
		return "armurerie"
	if l.x > inner - 8.0 and l.z > -5.0 and l.z < 11.0:
		return "bibliotheque"
	return "cour"


# =================================================================== chaque image

func _process(delta: float) -> void:
	if main == null or not main.game_started or ile == null:
		return
	_clock += delta
	_warn_clock = maxf(_warn_clock - delta, 0.0)
	var p: Vector3 = main._player_pos_v27()
	# Ventaile posée : l'invite « monter » la suit
	if not _mount_it.is_empty() and aigle != null:
		_mount_it["pos"] = aigle.global_position
		_feed_it["pos"] = aigle.global_position
	if riding:
		return
	var sky: bool = on_sky(p)
	if sky and ile.walkable(p.x, p.z) and p.y > ile.Y0 - 4.0:
		_was_on_sky = true
		if not bool(state["visite_ciel"]):
			state["visite_ciel"] = true
			main.jingle("decouverte")
			_say("L'île flottante. Le vent siffle, les nuages passent sous tes pieds, et au loin l'océan scintille, cent cinquante mètres plus bas… Au nord se dresse la Citadelle des Nuées.", 8.0)
	elif _was_on_sky and p.y < ile.Y0 - 25.0 and ile.near(p, 60.0):
		# Tombé de l'île : Ventaile (ou le vent) le rattrape et le repose sur l'Aire des Vents
		_was_on_sky = false
		var rp: Array = respawn_point()
		main.place_player_v35(rp[0], rp[1])
		_say("Ventaile plonge comme une pierre et te rattrape au vol ! Elle te repose sur l'Aire des Vents." if tamed() else "Une bourrasque te rattrape et te repose sur l'Aire des Vents.", 5.0)
		return
	elif not sky:
		_was_on_sky = false
	if sky:
		_tick_castle(p)


func _tick_castle(p: Vector3) -> void:
	var room: String = _room(p)
	# Les gardiens de chaque salle s'éveillent à notre entrée
	if _wave.is_empty():
		if room == "cour" and not bool(state["cour"]):
			_spawn_wave("cour")
		elif room == "armurerie" and not bool(state["armurerie"]):
			_spawn_wave("armurerie")
		elif room == "salle" and not bool(state["salle"]):
			_spawn_wave("salle")
	else:
		var alive: int = 0
		for m in _wave["monsters"]:
			if is_instance_valid(m) and m.state != "mort":
				alive += 1
		if alive == 0:
			_wave_done(str(_wave["room"]))
		elif not hostile_zone(p):
			_despawn_wave()
	# Le combat de la Tour des Tempêtes
	var l: Vector3 = chateau.to_local(p)
	var ar: Vector3 = chateau.points["arene"]
	var in_arena: bool = Vector2(l.x - ar.x, l.z - ar.z).length() < chateau.ARENA_R and absf(l.y - ar.y) < 3.0
	if not fight and not bool(state["boss"]) and in_arena:
		_start_fight()
	elif fight and not in_arena and boss != null and boss.state != "mort":
		_reset_fight()


# =================================================================== Ventaile : la chaîne, les poissons, la selle

func _examine_chain() -> void:
	_say("Une chaîne de fer noir, scellée dans un bloc de basalte par une rune bleue qui bourdonne : la marque des golems. Ventaile tire dessus, épuisée. Frappe la rune avec une arme pour la briser !", 7.0)


func _on_rune_hit(damage: int, _from_pos: Vector3) -> void:
	if str(state["aigle"]) != "":
		return
	var at: Vector3 = _anchor.global_position + Vector3.UP * 1.2
	if damage < 3:
		if main.combat_v28 != null:
			main.combat_v28.float_text(at, "Aïe ! Il faut une arme.", Color(1, 0.9, 0.8))
		return
	var hits: int = int(_anchor.get_meta("coups", 0)) + 1
	_anchor.set_meta("coups", hits)
	if main.combat_v28 != null:
		main.combat_v28.puff(at, Color(0.5, 0.8, 1.0))
		main.combat_v28.float_text(at + Vector3.UP * 0.4, "Crac !" if hits < 4 else "La rune vole en éclats !", Color(0.7, 0.9, 1.0))
	main.sfx("touche_pierre", at)
	if hits >= 4:
		state["aigle"] = "libre"
		_anchor.set_meta("coups", 0)
		main.sfx("grille", at)
		main.sfx("aigle_cri", aigle.global_position + Vector3.UP * 3.0)
		main.jingle("decouverte")
		apply_state()
		_say("La chaîne tombe ! Ventaile pousse un cri immense qui résonne dans le cratère… mais elle est trop faible pour s'envoler. Elle a faim : apporte-lui des poissons (trois).", 8.0)


func _has_fish() -> String:
	for f in FISH:
		if main.inventory_v28.count(f) > 0:
			return f
	return ""


func _feed() -> void:
	var f: String = _has_fish()
	if f == "":
		_say("Ventaile te regarde avec ses yeux d'or, puis regarde tes mains vides. Il lui faut du poisson : pêche-en (la canne de Barnabé) et reviens.", 6.0)
		return
	main.inventory_v28.remove(f, 1)
	state["poissons"] = int(state["poissons"]) + 1
	main.sfx("manger", aigle.global_position + Vector3.UP * 2.0)
	aigle._look_goal = Vector2(0, -0.6)
	var left: int = 3 - int(state["poissons"])
	if left > 0:
		_say("Ventaile avale %s d'un coup de bec. Elle en voudrait encore… (%d)" % [str(main.inventory_v28.ITEMS[f]["art"]), left], 4.0)
		return
	state["aigle"] = "nourrie"
	main.sfx("aigle_cri", aigle.global_position + Vector3.UP * 3.0)
	if main.inventory_v28.count("selle_aigle") > 0:
		_say("Ventaile a repris des forces ! Elle déploie ses ailes immenses, puis baisse la tête vers toi… Installe-lui la selle naine du roi Thorgal.", 7.0)
	else:
		_say("Ventaile a repris des forces ! Elle étire ses ailes immenses… Elle accepterait de te porter, mais sans selle, impossible de tenir sur son dos à cette altitude. Le roi Thorgal, à Forgefer, en saurait peut-être plus.", 8.0)


func _saddle_up() -> void:
	if main.inventory_v28.count("selle_aigle") <= 0:
		_say("Ventaile se laisse caresser les plumes du cou… mais il faudrait une selle pour monter sur son dos. Le roi Thorgal, à Forgefer, parlait des selles des anciens chevaucheurs d'aigles.", 7.0)
		return
	if not main.inventory_v28.can_accept([["plume_ventaile", 1]], [["selle_aigle", 1]]):
		_say("Ton sac est plein ! Fais un peu de place, puis reviens.", 4.0)
		return
	main.inventory_v28.remove("selle_aigle", 1)
	main.inventory_v28.add("plume_ventaile", 1)
	state["aigle"] = "amie"
	main.sfx("equiper", aigle.global_position + Vector3.UP * 2.0)
	main.jingle("victoire")
	apply_state()
	var how: String = "Approche-toi et appuie sur la gâchette pour monter. Pour l'appeler de loin : bouton X (main gauche)." if main.xr_active else "Approche-toi et appuie sur E pour monter. Pour l'appeler de loin : G (ou « Utiliser » la plume dans l'inventaire)."
	_say("Tu boucles les sangles de la selle naine. Ventaile se redresse, fière, et t'offre une plume dorée. Elle est à toi, et toi à elle. " + how, 10.0)


## Le sifflet (la plume) : Ventaile arrive et se pose près du joueur.
func call_eagle() -> void:
	if not tamed():
		return
	if riding:
		return
	var p: Vector3 = main._player_pos_v27()
	if main.donjon_v35 != null and main.donjon_v35.is_inside(p):
		_say("Sous terre, Ventaile ne peut pas t'entendre.", 3.5)
		return
	var space := get_world_3d().direct_space_state
	var roof := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * 2.2, p + Vector3.UP * 40.0, 1 | 256))
	if not roof.is_empty():
		_say("Ventaile ne peut pas entrer ici : sors à l'air libre pour l'appeler.", 3.5)
		return
	if chateau != null and _in_castle_zone(p, 4.0):
		_say("Le vent tourbillonne trop fort au-dessus de la Citadelle : Ventaile t'attendra sur l'Aire des Vents. Siffle-la depuis l'esplanade.", 5.0)
		return
	if aigle.is_landed() and aigle.global_position.distance_to(p) < 30.0:
		_say("Ventaile est déjà là, à quelques pas.", 3.0)
		return
	var spot: Variant = _landing_spot(p)
	if spot == null:
		_say("Pas assez de place ici pour qu'un aigle géant se pose. Va sur un terrain dégagé.", 4.0)
		return
	var from: Vector3 = (spot as Vector3) - p
	from.y = 0.0
	var dir: Vector3 = from.normalized() if from.length() > 0.1 else Vector3.FORWARD
	aigle.arrive_at(spot, dir.rotated(Vector3.UP, randf_range(-0.5, 0.5)))
	main.sfx("aigle_cri", p + dir * 60.0 + Vector3.UP * 40.0, 4.0)
	_say("Tu fais siffler la plume dorée… Un cri d'aigle répond, très loin. Ventaile arrive !", 4.0)


func _landing_spot(p: Vector3) -> Variant:
	for k in range(10):
		var a: float = TAU * k / 10.0
		var q: Vector3 = p + Vector3(cos(a) * 5.0, 0, sin(a) * 5.0)
		var g: Array = aigle.ground_below(q + Vector3.UP * 6.0)
		if bool(g[1]) and absf(float(g[0]) - p.y) < 2.5:
			var ok: bool = true
			# Pas d'arbre ni de mur sur la place
			var space := get_world_3d().direct_space_state
			for h in [1.5, 3.0]:
				var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * h, Vector3(q.x, float(g[0]) + h, q.z), 1))
				if not hit.is_empty():
					ok = false
			if ok:
				return Vector3(q.x, float(g[0]), q.z)
	return null


func _in_castle_zone(p: Vector3, extra: float = 0.0) -> bool:
	var c: Vector3 = chateau.global_position
	return Vector2(p.x - c.x, p.z - c.z).length() < NO_FLY_R + extra and p.y < c.y + 50.0 and p.y > c.y - 30.0


# =================================================================== le vol

func mount() -> void:
	if riding or not tamed() or not aigle.is_landed():
		return
	_begin_ride(true)
	main.sfx("ailes", aigle.global_position + Vector3.UP * 2.0)
	main.sfx("aigle_cri", aigle.global_position + Vector3.UP * 3.0)
	if main.xr_active:
		_say("En selle ! Stick gauche : vers l'avant pour monter, vers l'arrière pour descendre, à gauche ou à droite pour virer. Gâchette droite : plus vite, gâchette gauche : freiner. A : se poser.", 9.0)
	else:
		_say("En selle ! Z / S : plus vite / freiner, Q / D : virer, Espace : monter, Ctrl : descendre, E : se poser.", 8.0)


func _begin_ride(take_off: bool) -> void:
	riding = true
	aigle.set_physics_process(false)
	if take_off:
		aigle.take_off()
	if main.fishing_v32 != null:
		main.fishing_v32.cancel("")
	if main.inventory_v28 != null and main.inventory_v28.opened:
		main.inventory_v28.close()
	if main.xr_active:
		main.xr_origin.rotation.y = aigle.yaw
	elif main.hero_v28 != null:
		main.hero_v28.cam_distance = 1.6
	_vr_a = true


func riding_now() -> bool:
	return riding


func request_landing() -> void:
	if not riding or aigle.state != "vol":
		return
	if _in_castle_zone(aigle.global_position):
		_say("Pas dans la Citadelle : le vent y est trop violent. Pose-toi sur l'Aire des Vents, au sud de l'île.", 4.5)
		return
	var r: String = aigle.request_land()
	match r:
		"eau":
			_say("Pas de terre ferme sous Ventaile : survole une île pour te poser.", 3.5)
		"haut":
			_say("Trop haut pour se poser : descends d'abord (%s)." % ("stick gauche vers l'arrière" if main.xr_active else "Ctrl"), 3.5)


## Chaque image de vol (appelé par main.gd à la place de la marche).
func ride_tick(delta: float) -> void:
	var turn: float = 0.0
	var lift: float = 0.0
	var thr: float = 0.0
	if main.xr_active:
		var st: Vector2 = main.left_hand.get_vector2("primary")
		if st.length() > 0.2:
			turn = st.x
			lift = st.y
		thr = main.right_hand.get_float("trigger") - main.left_hand.get_float("trigger")
		var a_now: bool = main.right_hand.is_button_pressed("ax_button")
		if a_now and not _vr_a:
			request_landing()
		_vr_a = a_now
	else:
		var free: bool = main.inventory_v28 == null or not main.inventory_v28.opened
		if free:
			if Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
				thr += 1.0
			if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
				thr -= 1.0
			if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
				turn -= 1.0
			if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
				turn += 1.0
			if main.has_method("pad_move_v74"):
				var pad: Vector2 = main.pad_move_v74()
				thr = clampf(thr - pad.y, -1.0, 1.0)
				turn = clampf(turn + pad.x, -1.0, 1.0)
			if Input.is_key_pressed(KEY_SPACE):
				lift += 1.0
			if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_SHIFT):
				lift -= 1.0
	aigle.steer(turn, lift, thr)
	aigle._physics_process(delta)
	_no_fly(delta)
	if aigle.state == "vol" and not bool(state["vue_ciel"]) and aigle.global_position.distance_to(ile.CENTER + Vector3.UP * ile.Y0) < 260.0:
		state["vue_ciel"] = true
		_say("Là-bas, au-dessus de l'océan : l'île flottante ! Des cascades en tombent jusqu'à la mer, et sur son sommet, la Citadelle des Nuées. On peut se poser sur l'esplanade, au sud.", 8.0)
	# Bruits : battements d'ailes, cri de temps en temps
	var cycle: int = int(floor(aigle._flap_phase / TAU))
	if cycle != _last_flap:
		_last_flap = cycle
		if aigle._flap_amp > 0.3:
			main.sfx("ailes", aigle.global_position + Vector3.UP * 2.0, -2.0)
	_cry_clock -= delta
	if _cry_clock <= 0.0:
		_cry_clock = randf_range(25.0, 50.0)
		main.sfx("aigle_cri", aigle.global_position + Vector3.UP * 3.0 - Vector3(-sin(aigle.yaw), 0, -cos(aigle.yaw)) * -4.0, -4.0)
	_place_rider()
	if aigle.state == "perche":
		_end_ride()


func _place_rider() -> void:
	var seat: Transform3D = aigle.seat_transform()
	if main.xr_active:
		main.xr_origin.rotation.y = aigle.yaw
		var cam_local: Vector3 = main.xr_camera.position
		var offset: Vector3 = Basis(Vector3.UP, main.xr_origin.rotation.y) * Vector3(cam_local.x, 0.0, cam_local.z)
		main.xr_origin.position = Vector3(seat.origin.x - offset.x, seat.origin.y - 0.25, seat.origin.z - offset.z)
		main.vr_body.global_position = seat.origin + Vector3.UP * 0.4
		main.vr_body.velocity = Vector3.ZERO
	else:
		main.pc_root.rotation.y = aigle.yaw
		main.pc_root.position = seat.origin
		main.pc_body.global_position = seat.origin + Vector3.UP * 0.4
		main.pc_body.velocity = Vector3.ZERO
		if main.hero_v28 != null:
			main.hero_v28.ride(seat)


## Un vent furieux tourbillonne autour de la Citadelle : Ventaile ne s'en approche pas.
func _no_fly(delta: float) -> void:
	if aigle.state != "vol":
		return
	var p: Vector3 = aigle.global_position
	if not _in_castle_zone(p):
		return
	var c: Vector3 = chateau.global_position
	var out := Vector3(p.x - c.x, 0, p.z - c.z)
	out = out.normalized() if out.length() > 0.1 else Vector3.BACK
	aigle.global_position += out * 14.0 * delta
	var want: float = atan2(-out.x, -out.z)
	aigle.yaw = lerp_angle(aigle.yaw, want, clampf(delta * 2.5, 0.0, 1.0))
	if _warn_clock <= 0.0:
		_warn_clock = 6.0
		_say("Un vent furieux tourbillonne autour de la Citadelle : Ventaile refuse d'approcher. Pose-toi sur l'Aire des Vents, au sud de l'île.", 5.0)


func _on_landed() -> void:
	if riding:
		return
	# Arrivée après un appel : rien de plus (elle attend qu'on monte)


func _end_ride() -> void:
	riding = false
	aigle.set_physics_process(true)
	var side := Vector3(cos(aigle.yaw), 0, -sin(aigle.yaw))
	var spot: Vector3 = aigle.global_position + side * 3.3
	var g: Array = aigle.ground_below(spot + Vector3.UP * 3.0)
	if bool(g[1]):
		spot.y = float(g[0]) + 0.05
	else:
		spot = aigle.global_position + Vector3.UP * 0.1
	main.place_player_v35(spot, Vector3(-sin(aigle.yaw), 0, -cos(aigle.yaw)))
	if not main.xr_active and main.hero_v28 != null:
		main.hero_v28.leave_ride()
		main.hero_v28.cam_distance = 1.0
	main.sfx("atterrissage", spot)


# =================================================================== la Citadelle : salles et énigmes

func _say(text: String, seconds: float = 4.0) -> void:
	main.donjon_v35._say(text, seconds)


func _climb(where: String) -> void:
	var d: Node = main.donjon_v35
	match where:
		"beffroi":
			_say("Tu montes l'escalier en colimaçon du beffroi…", 2.5)
			await d._travel(chateau.at("beffroi_haut"), (chateau.at("coffre_levant") - chateau.at("beffroi_haut")).normalized())
			if not bool(state["cloches"]):
				_say("Le beffroi. Quatre cloches de bronze pendent sous la flèche, chacune marquée d'un signe : la Vague, le Soleil, la Lune, le Vent. Elles attendent qu'on les sonne… dans le bon ordre.", 7.0)
		"cour_beffroi":
			await d._travel(chateau.at("beffroi_porte") + Vector3(-1.0, 0.1, 1.0), Vector3(-1, 0, 1).normalized())
		"arene":
			if not bool(state["salle"]):
				_say("Des pas métalliques résonnent dans la salle… Les gardiens ne te laisseront pas monter.", 3.0)
				return
			_say("Tu gravis les marches de la Tour des Tempêtes… le vent hurle de plus en plus fort.", 3.0)
			await d._travel(chateau.at("arene_arrivee") + Vector3.UP * 0.1, (chateau.at("arene") - chateau.at("arene_arrivee")).normalized())
		"salle":
			await d._travel(chateau.at("escalier_tour") + Vector3.UP * 0.1, Vector3(0, 0, 1))


func _read_book() -> void:
	state["livre"] = true
	_say("« Le Chant des Quatre Cloches. Qui voudra le Cristal du Levant sonnera le beffroi comme chantaient les Rois-Ciel : la Vague porte le Soleil ; le Soleil chasse la Lune ; la Lune appelle le Vent. » Plus bas, d'une autre main : « Le Cristal du Couchant dort dans la salle d'armes. Ses gardiens, eux, ne dorment jamais. »", 12.0)


func _ring(bell: String) -> void:
	if bool(state["cloches"]):
		return
	chateau.ring(bell)
	main.sfx("cloche_" + bell, chateau.bells[bell].global_position)
	_bell_seq.append(bell)
	var good: bool = true
	for k in range(_bell_seq.size()):
		if _bell_seq[k] != BELL_ORDER[k]:
			good = false
	if not good:
		_bell_seq.clear()
		await get_tree().create_timer(0.8).timeout
		_say("Les cloches vibrent ensemble, discordantes, puis se taisent… Ce n'était pas le bon ordre." + ("" if bool(state["livre"]) else " Un livre, quelque part, en parle peut-être."), 5.0)
		return
	if _bell_seq.size() < BELL_ORDER.size():
		return
	state["cloches"] = true
	_bell_seq.clear()
	await get_tree().create_timer(1.2).timeout
	main.jingle("decouverte")
	_show_chest("coffre_levant", true, false)
	var c: Node3D = _chests["coffre_levant"]
	var y: float = c.position.y
	c.position.y = y - 0.8
	create_tween().tween_property(c, "position:y", y, 1.5).set_trans(Tween.TRANS_BACK)
	_say("Les quatre cloches chantent ensemble ! Le Chant des Rois-Ciel roule sur toute l'île… Au centre du beffroi, une dalle s'ouvre et un coffre remonte.", 7.0)


func _open_chest(id: String) -> void:
	var gives: Array = []
	var text: String = ""
	match id:
		"coffre_levant":
			gives = [["cristal_levant", 1], ["piece", 40]]
			text = "Dans le coffre : quarante pièces… et le Cristal du Levant, chaud comme un soleil levant. Il s'emboîtera dans le Sceau des Vents, devant le donjon."
		"coffre_couchant":
			gives = [["cristal_couchant", 1], ["piece", 40], ["piece_or", 1]]
			text = "Dans le coffre de la salle d'armes : quarante pièces, une pièce d'or… et le Cristal du Couchant, froid et bleu comme le soir. Le Sceau des Vents l'attend."
		"tresor":
			gives = [["epee_nuees", 1], ["couronne_nuees", 1], ["masque_plongee", 1], ["piece", 200], ["piece_or", 3], ["rubis", 2]]
			text = "Le trésor des Rois-Ciel ! Deux cents pièces, trois pièces d'or, deux rubis, la Couronne des Nuées, l'Épée des Nuées dont la lame crépite d'éclairs… et un étrange masque de plongée aux verres de cristal. Avec lui, on respire sous l'eau ! Tout en bas, sous la mer, au sud-ouest du village, une lumière brille…"
	if not main.inventory_v28.can_accept(gives):
		_say("Ton sac est plein ! Fais de la place avant d'ouvrir le coffre : son contenu t'attendra.", 4.5)
		return
	state[id] = true
	for g in gives:
		main.inventory_v28.add(str(g[0]), int(g[1]))
	main.sfx("coffre", (_chests[id] as Node3D).global_position)
	main.jingle("decouverte")
	var hinge: Node3D = (_chests[id] as Node3D).get_node("Charniere")
	create_tween().tween_property(hinge, "rotation:x", -1.8, 0.8).set_trans(Tween.TRANS_BACK)
	if main.combat_v28 != null:
		main.combat_v28.puff((_chests[id] as Node3D).global_position + Vector3.UP * 0.8, Color(1.0, 0.85, 0.4))
	_say(text, 8.0)


func _seal() -> void:
	var inv: Node = main.inventory_v28
	var lev: bool = inv.count("cristal_levant") > 0
	var cou: bool = inv.count("cristal_couchant") > 0
	if lev and cou:
		inv.remove("cristal_levant", 1)
		inv.remove("cristal_couchant", 1)
		state["sceau"] = true
		chateau.show_seal(true, true)
		main.sfx("pierre_glisse", chateau.at("porte_donjon"))
		main.jingle("decouverte")
		await get_tree().create_timer(1.0).timeout
		chateau.open_keep(false)
		main.sfx("grille", chateau.at("porte_donjon") + Vector3.UP * 3.0)
		_say("Tu poses les deux cristaux dans le Sceau des Vents : l'un rougeoie, l'autre bleuit… Un souffle de vent traverse la cour, et les grands battants du donjon s'ouvrent lentement.", 8.0)
		return
	var missing: Array = []
	if not lev:
		missing.append("le Cristal du Levant (le beffroi, à l'est)")
	if not cou:
		missing.append("le Cristal du Couchant (la salle d'armes, à l'ouest)")
	_say("Le Sceau des Vents : une stèle gravée d'une rose des vents, avec deux logements vides. La grande porte du donjon ne bouge pas. Il manque " + " et ".join(missing) + ".", 8.0)


# =================================================================== combats de la Citadelle

func _spawn_wave(room: String) -> void:
	var mo: Node = main.monstres_v36
	if mo == null:
		return
	var list: Array = []
	match room:
		"cour":
			for pp in chateau.points["perchoirs"]:
				var l: Vector3 = pp
				var home := Vector3(l.x * 0.7, 0.05, l.z * 0.7 + 1.0)
				list.append(["gargouille", chateau.to_global(home)])
			_say("Un crissement de pierre au-dessus de toi… Les gargouilles des remparts ouvrent les yeux !", 5.0)
		"armurerie":
			for s in chateau.points["armures"]:
				list.append(["armure", chateau.to_global(s)])
			_say("Dans un cliquetis, les trois armures de la salle d'armes tournent la tête vers toi… et tirent l'épée.", 5.0)
		"salle":
			for s2 in chateau.points["salle_monstres"]:
				list.append(["armure", chateau.to_global(s2)])
			list.append(["gargouille", chateau.to_global(Vector3(-5.0, 0.05, -11.0))])
			list.append(["gargouille", chateau.to_global(Vector3(5.0, 0.05, -11.0))])
			_say("La salle du trône. Des vitraux, des bannières, et au fond le trône des Rois-Ciel… Deux armures se détachent des piliers !", 6.0)
	var monsters: Array = []
	for e in list:
		var m: Node3D = mo.spawn_extra(str(e[0]), e[1])
		m.state = "veille"
		m.home = e[1]
		monsters.append(m)
	_wave = {"room": room, "monsters": monsters}


func _despawn_wave() -> void:
	if _wave.is_empty():
		return
	var mo: Node = main.monstres_v36 if main != null else null
	for m in _wave["monsters"]:
		if is_instance_valid(m):
			if mo != null:
				mo.monsters.erase(m)
			m.queue_free()
	_wave = {}


func _wave_done(room: String) -> void:
	_wave = {}
	state[room] = true
	main.jingle("victoire")
	match room:
		"cour":
			_say("Les gargouilles retombent en poussière. La cour d'honneur est à toi… À l'est, la bibliothèque ; à l'ouest, la salle d'armes ; au nord, le donjon, scellé.", 7.0)
		"armurerie":
			_show_chest("coffre_couchant", true, false)
			_say("Les armures s'effondrent dans un fracas de ferraille. Au fond de la salle d'armes, un coffre est apparu.", 6.0)
		"salle":
			_say("La salle du trône retrouve son silence. Derrière le trône, à droite, une porte mène à la Tour des Tempêtes…", 6.0)


func summon_gargoyles(n: int) -> void:
	var alive: int = 0
	for m in _summoned:
		if is_instance_valid(m) and m.state != "mort":
			alive += 1
	var c: Vector3 = chateau.at("arene")
	for k in range(mini(n, 3 - alive)):
		var a: float = randf() * TAU
		var at: Vector3 = c + Vector3(cos(a) * 5.5, 0.1, sin(a) * 5.5)
		var m: Node3D = main.monstres_v36.spawn_extra("gargouille", at)
		_summoned.append(m)
	if n > 0:
		_say("Des gargouilles fondent du haut des nuages !", 2.5)


func _start_fight() -> void:
	fight = true
	var d: Node = main.donjon_v35
	main.sfx("boss_cri", chateau.at("arene") + Vector3.UP * 4.0)
	var c: Vector3 = chateau.at("arene")
	var p: Vector3 = main._player_pos_v27()
	var face: Vector3 = Vector3(p.x - c.x, 0, p.z - c.z)
	face = face.normalized() if face.length() > 0.1 else Vector3.BACK
	boss = BossScript.new()
	add_child(boss)
	boss.setup(self, c, -face)
	boss.health_changed.connect(d._update_bar)
	boss.defeated.connect(_on_boss_defeated)
	d._bar_name = "Sire Orage, le Chevalier des Tempêtes"
	d._bar_label.text = d._bar_name
	d._bar_layer.visible = not main.xr_active
	if main.xr_active:
		_bar_vr = Label3D.new()
		_bar_vr.font_size = 48
		_bar_vr.pixel_size = 0.004
		_bar_vr.outline_size = 10
		_bar_vr.modulate = Color(0.7, 0.85, 1.0)
		_bar_vr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_bar_vr.no_depth_test = true
		_bar_vr.position = Vector3(0, 4.6, 0)
		boss.add_child(_bar_vr)
		d._bar_vr = _bar_vr
	d._update_bar(boss.hp, boss.HP_MAX)
	_say("Le ciel s'assombrit d'un coup. Un éclair frappe le centre de la plate-forme… Une armure immense en descend : SIRE ORAGE, LE CHEVALIER DES TEMPÊTES !", 6.0)


func _reset_fight() -> void:
	if not fight:
		return
	fight = false
	if boss != null:
		boss.queue_free()
		boss = null
	var d: Node = main.donjon_v35
	if d != null:
		d._bar_layer.visible = false
		d._bar_vr = null
	_bar_vr = null
	for m in _summoned:
		if is_instance_valid(m):
			m.queue_free()
	_summoned.clear()


func _on_boss_defeated() -> void:
	main.jingle("victoire")
	state["boss"] = true
	_say("Sire Orage pose un genou à terre… et se dissout dans le vent. La tempête s'apaise, le soleil revient sur la Tour. Au loin, sur la Montagne de Feu, les golems s'immobilisent. Un coffre d'or apparaît au milieu des runes.", 9.0)
	await get_tree().create_timer(2.5).timeout
	fight = false
	main.donjon_v35._bar_layer.visible = false
	main.donjon_v35._bar_vr = null
	for m in _summoned:
		if is_instance_valid(m) and m.state != "mort":
			m.take_hit(99, m.global_position + Vector3.UP)
	_summoned.clear()
	_show_chest("tresor", true, false)
	var c: Node3D = _chests["tresor"]
	var y: float = c.position.y
	c.position.y = y - 1.0
	create_tween().tween_property(c, "position:y", y, 2.0).set_trans(Tween.TRANS_BACK)
