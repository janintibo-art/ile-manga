extends Node3D
## V90 : l'Île Pixelithique — le chef d'orchestre. Une île préhistorique où TOUT est en petits cubes
## (le sol en blocs de 50 cm peints de pixels fins, les plantes, les rochers, les bêtes, les gens) :
## le Mont Fumant et son lac de lave, les Falaises du Clan et leurs grottes, le Campement au pied de
## la falaise (le feu, le totem, les séchoirs), le Lac des Long-Cous (les brachiosaures), la Plaine
## des Cornes (les tricératops), la Jungle des Fougères (les raptors), le Cirque des Os (Grosse-Dent,
## le tyrannosaure), la Plage des Œufs et son ponton.
## Le Clan des hommes des cavernes vit là : pour eux, le héros est une drôle de chose venue d'un autre
## monde (il est tout LISSE, sans un seul pixel !).
## Modules : ile_pixel_v90 (le relief), vox_v90 (les modèles), pnj/caverne_v90 (les habitants),
## pnj/clan_textes_v90 (ce qu'ils disent), grottes_v90 (les grottes), faune_pixel_v90 (les
## long-cous et les grand-becs qui planent), monstre_v90 (les dinosaures qu'on combat).

const IleScript = preload("res://scripts/ile_pixel_v90.gd")
const Vox = preload("res://scripts/vox_v90.gd")
const Caverne = preload("res://scripts/pnj/caverne_v90.gd")
const Textes = preload("res://scripts/pnj/clan_textes_v90.gd")
const Grottes = preload("res://scripts/grottes_v90.gd")
const Faune = preload("res://scripts/faune_pixel_v90.gd")

## Les habitants du Clan : [id, x, z (repère île), pose, objet tenu]
const CLAN := [
	["ougha", -44.0, 8.0, "garde", "massue"], ["ocre", -68.0, -8.0, "peindre", "pinceau"], ["mamie_silex", -47.0, 2.5, "debout", ""],
	["grok", -36.0, 16.0, "garde", "lance"], ["ploc", -42.0, 14.0, "debout", ""], ["pika", -40.0, 12.5, "debout", ""],
	["vieux_flint", -53.0, 9.5, "assis", ""], ["boum", -55.0, 4.0, "tambour", ""],
]
const FEU := Vector2(-49.0, 6.0)
## Les entrées des grottes, dans la face est de la falaise : [id, z]
const GROTTES := [["clan", 2.0], ["peintures", -14.0]]
## Les repaires des dinosaures : [id, centre (repère île), rayon d'apparition, repousse (s), [[espèce, x, z], …]]
const REPAIRES := [
	["raptors_jungle", Vector2(58.0, 44.0), 55.0, 240.0, [["raptor", 54.0, 40.0], ["raptor", 60.0, 48.0], ["raptor", 64.0, 40.0]]],
	["raptors_est", Vector2(96.0, 2.0), 55.0, 240.0, [["raptor", 92.0, -2.0], ["raptor", 100.0, 6.0]]],
	["cornes_1", Vector2(-38.0, -62.0), 50.0, 300.0, [["triceratops", -38.0, -62.0]]],
	["cornes_2", Vector2(-70.0, -96.0), 50.0, 300.0, [["triceratops", -70.0, -96.0]]],
	["massues", Vector2(36.0, -36.0), 45.0, 300.0, [["ankylosaure", 36.0, -36.0]]],
	["massues_est", Vector2(112.0, -48.0), 45.0, 300.0, [["ankylosaure", 112.0, -48.0]]],
	["becs_plage", Vector2(62.0, 108.0), 55.0, 240.0, [["pteranodon", 58.0, 104.0], ["pteranodon", 68.0, 112.0]]],
	["becs_falaise", Vector2(-104.0, -34.0), 55.0, 240.0, [["pteranodon", -100.0, -30.0], ["pteranodon", -108.0, -40.0]]],
]
const PLACES := {"plage": "la Plage des Œufs", "camp": "le Campement du Clan", "falaises": "les Falaises du Clan", "lac": "le Lac des Long-Cous",
	"cirque": "le Cirque des Os", "volcan": "le Mont Fumant", "plaine": "la Plaine des Cornes", "jungle": "la Jungle des Fougères", "ile": "l'île"}

var main: Node
var ile: Node3D
var grottes: Node3D
var faune: Node3D
var pc: bool = true
var state: Dictionary = {}
var objets: Dictionary = {}
var clan: Dictionary = {}                # id -> Caverne
var lairs: Array = []
var boss: Node3D                         # Grosse-Dent (quand il est là)
var dodo: Node3D                         # Grosse-Dent endormi (une fois vaincu)
var _feu_light: OmniLight3D
var _lava_light: OmniLight3D
var _clock: float = 0.0
var _zone_t: float = 0.0
var _lair_t: float = 0.0
var _registered: bool = false
var _danse_t: float = 0.0
var _rng := RandomNumberGenerator.new()


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_rng.seed = 9090
	state = _fresh_state()


func _fresh_state() -> Dictionary:
	return {"visite": false, "visites": {}, "rencontre": false, "quete": "", "trex": false, "portrait": false, "galettes": 0,
		"galette_t": -1e9, "danse": false, "grotte_clan": false, "grotte_peintures": false, "parle": {}}


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	add_child(ile)
	ile.build(pc)


func dock() -> Array:
	return [IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y), IleScript.W(IleScript.DOCK_B.x, IleScript.DOCK_B.y)]


func _ground(x: float, z: float) -> Vector3:
	var w: Vector3 = IleScript.W(x, z)
	w.y = ile.height(w.x, w.z)
	return w


func build_town() -> void:
	var t0: int = Time.get_ticks_msec()
	if ile == null or not ile.ok:
		return
	_flore()
	_campement()
	_volcan()
	_cirque()
	_decor()
	grottes = Grottes.new()
	add_child(grottes)
	grottes.setup(main, self)
	faune = Faune.new()
	add_child(faune)
	faune.setup(main, self)
	_lairs_init()
	_sync()
	objets["plage"] = _ground(18.0, 118.0)
	objets["camp"] = _ground(FEU.x, FEU.y)
	objets["lac"] = _ground(-30.0, 60.0)
	objets["cirque"] = _ground(IleScript.CIRQUE[0], IleScript.CIRQUE[1] + 30.0)
	objets["volcan"] = _ground(48.0, -40.0)
	print("ILE_MANGA_V90: l'Île Pixelithique est prête (%d ms)" % (Time.get_ticks_msec() - t0))


## Les plantes et les rochers (posés par l'outil) : par espèce et par carré de 60 m, en MultiMesh ;
## les troncs et les rochers arrêtent le joueur.
func _flore() -> void:
	var pl: Dictionary = Vox.plantes()
	var variantes := {"fougere_arbo": 3, "cycas": 2, "araucaria": 2, "preles": 2, "fougere_basse": 2, "touffe": 2}
	var portee := {"fougere_arbo": 420.0, "cycas": 260.0, "araucaria": 600.0, "preles": 200.0, "fougere_basse": 120.0, "touffe": 55.0,
		"rocher_0": 360.0, "rocher_1": 360.0}
	var troncs := {"fougere_arbo": 0.22, "cycas": 0.35, "araucaria": 0.32}
	var body := StaticBody3D.new()
	body.name = "Flore_collision"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for nom in pl:
		var arr: PackedFloat32Array = pl[nom]
		var nv: int = int(variantes.get(nom, 1))
		var cells: Dictionary = {}
		for i in range(arr.size() / 5):
			var x: float = arr[i * 5]
			var y: float = arr[i * 5 + 1]
			var z: float = arr[i * 5 + 2]
			var yaw: float = arr[i * 5 + 3]
			var s: float = arr[i * 5 + 4]
			var mname: String = ("%s_%d" % [nom, i % nv]) if nv > 1 or not Vox.has(nom) else nom
			if not Vox.has(mname):
				continue
			var key: String = "%s|%d|%d" % [mname, int(floor(x / 60.0)), int(floor(z / 60.0))]
			if not cells.has(key):
				cells[key] = []
			var w: Vector3 = IleScript.W(x, z, y)
			(cells[key] as Array).append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * s), w))
			if troncs.has(nom):
				var cs := CollisionShape3D.new()
				var cy := CylinderShape3D.new()
				cy.radius = float(troncs[nom]) * s
				cy.height = 3.0
				cs.shape = cy
				body.add_child(cs)
				cs.global_position = w + Vector3.UP * 1.5
			elif str(nom).begins_with("rocher"):
				var cs2 := CollisionShape3D.new()
				var sp := SphereShape3D.new()
				sp.radius = 1.05 * s
				cs2.shape = sp
				body.add_child(cs2)
				cs2.global_position = w + Vector3.UP * 0.35 * s
		for key2 in cells:
			var mn: String = str(key2).split("|")[0]
			var xf: Array = cells[key2]
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = Vox.mesh(mn)
			mm.instance_count = xf.size()
			for k in range(xf.size()):
				mm.set_instance_transform(k, xf[k])
			var mmi := MultiMeshInstance3D.new()
			mmi.name = "Flore_pixel_" + str(key2).replace("|", "_")
			mmi.multimesh = mm
			mmi.material_override = Vox.material()
			mmi.visibility_range_end = float(portee.get(nom, 300.0))
			mmi.visibility_range_end_margin = 15.0
			mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			if nom in ["touffe", "fougere_basse", "preles"]:
				mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mmi)


## Le Campement : le feu, le totem, les séchoirs, les peaux, les tambours… et le Clan.
func _campement() -> void:
	var f: Vector3 = _ground(FEU.x, FEU.y)
	Vox.objet(self, "feu", f)
	_flammes(f, 1.0)
	_feu_light = OmniLight3D.new()
	_feu_light.light_color = Color(1.0, 0.62, 0.3)
	_feu_light.light_energy = 2.4
	_feu_light.omni_range = 14.0
	_feu_light.shadow_enabled = true
	add_child(_feu_light)
	_feu_light.global_position = f + Vector3.UP * 1.2
	_solide(f + Vector3.UP * 0.2, Vector3(1.4, 0.4, 1.4))
	Vox.objet(self, "totem", _ground(-58.0, 16.0), PI * 0.6)
	_solide(_ground(-58.0, 16.0) + Vector3.UP * 2.0, Vector3(0.7, 4.0, 0.7))
	for e in [[-38.0, -4.0, 0.3], [-60.0, -6.0, 1.2], [-33.0, 4.0, 2.0]]:
		Vox.objet(self, "sechoir", _ground(float(e[0]), float(e[1])), float(e[2]))
	for e2 in [[-52.0, 13.0, 0.2], [-45.0, 11.0, 1.4], [-56.0, 0.0, 2.6]]:
		Vox.objet(self, "peau", _ground(float(e2[0]), float(e2[1])) + Vector3.UP * 0.02, float(e2[2]))
	Vox.objet(self, "tambour", _ground(-55.6, 4.9), 0.0)
	for k in range(6):
		Vox.objet(self, "os", _ground(-44.0 + _rng.randf_range(-8, 8), 2.0 + _rng.randf_range(-6, 8)) + Vector3.UP * 0.02, _rng.randf() * TAU)
	# les gens
	for c in CLAN:
		var id: String = str(c[0])
		var at: Vector3 = _ground(float(c[1]), float(c[2]))
		var face: Vector3 = (f - at)
		face.y = 0.0
		var m: Node3D = Caverne.spawn(self, main, id, str(Textes.NOMS[id]), at, face.normalized(), str(c[3]), str(c[4]))
		m.lines = Textes.BULLES.get(id, [])
		m.ground = Callable(ile, "height")
		m.set_meta("maison", at)
		clan[id] = m
	objets["feu_du_clan"] = f


## Des flammes en petits cubes qui montent et s'éteignent.
func _flammes(at: Vector3, s: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Flammes_pixels"
	p.amount = 40
	p.lifetime = 0.9
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.3, 0.05, 0.3) * s
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 12.0
	pm.initial_velocity_min = 0.8 * s
	pm.initial_velocity_max = 1.6 * s
	pm.gravity = Vector3(0, 0.5, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.85, 0.3))
	g.set_color(1, Color(0.9, 0.2, 0.05))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	var sc := Curve.new()
	sc.add_point(Vector2(0, 1))
	sc.add_point(Vector2(1, 0.1))
	var st := CurveTexture.new()
	st.curve = sc
	pm.scale_curve = st
	p.process_material = pm
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE * 0.12 * s
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	bm.material = mat
	p.draw_pass_1 = bm
	add_child(p)
	p.global_position = at + Vector3.UP * 0.15
	return p


func _solide(at: Vector3, size: Vector3) -> void:
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	add_child(sb)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	sb.add_child(cs)
	sb.global_position = at


## Le Mont Fumant : la lueur de la lave, la fumée en cubes qui monte.
func _volcan() -> void:
	var v: Array = IleScript.VOLCAN
	var c: Vector3 = IleScript.W(float(v[0]), float(v[1]), float(v[5]))
	_lava_light = OmniLight3D.new()
	_lava_light.light_color = Color(1.0, 0.45, 0.15)
	_lava_light.light_energy = 3.5
	_lava_light.omni_range = 26.0
	add_child(_lava_light)
	_lava_light.global_position = c + Vector3.UP * 3.0
	var p := GPUParticles3D.new()
	p.name = "Fumee_pixels"
	p.amount = 90
	p.lifetime = 14.0
	p.preprocess = 14.0
	p.visibility_aabb = AABB(Vector3(-40, -5, -40), Vector3(80, 120, 80))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 6.0
	pm.direction = Vector3(0.15, 1, 0.05)
	pm.spread = 10.0
	pm.initial_velocity_min = 3.0
	pm.initial_velocity_max = 5.0
	pm.gravity = Vector3(0.4, 0.3, 0.0)
	pm.scale_min = 1.0
	pm.scale_max = 2.4
	pm.angle_min = 0.0
	pm.angle_max = 90.0
	var sc := Curve.new()
	sc.add_point(Vector2(0, 0.4))
	sc.add_point(Vector2(1, 2.2))
	var st := CurveTexture.new()
	st.curve = sc
	pm.scale_curve = st
	var g := Gradient.new()
	g.set_color(0, Color(0.42, 0.4, 0.4, 0.9))
	g.set_color(1, Color(0.7, 0.7, 0.72, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	p.process_material = pm
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE * 1.6
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 1.0
	bm.material = mat
	p.draw_pass_1 = bm
	add_child(p)
	p.global_position = c + Vector3.UP * 2.0
	objets["cratere"] = _ground(float(v[0]), float(v[1]) - 22.0)


## Le Cirque des Os : le grand squelette, des os partout.
func _cirque() -> void:
	var a: Array = IleScript.CIRQUE
	Vox.objet(self, "squelette", _ground(float(a[0]) + 10.0, float(a[1]) - 8.0), 0.7)
	for k in range(14):
		var r: float = _rng.randf_range(4.0, float(a[2]) - 2.0)
		var t: float = _rng.randf() * TAU
		Vox.objet(self, "os", _ground(float(a[0]) + cos(t) * r, float(a[1]) + sin(t) * r) + Vector3.UP * 0.02, _rng.randf() * TAU, _rng.randf_range(0.8, 1.6))


## Les nids de la Plage des Œufs, un squelette dans la plaine.
func _decor() -> void:
	for e in [[30.0, 108.0], [-4.0, 112.0], [48.0, 100.0]]:
		Vox.objet(self, "nid", _ground(float(e[0]), float(e[1])), _rng.randf() * TAU)
	Vox.objet(self, "squelette", _ground(-20.0, -76.0), 2.2, 0.8)


# =================================================================== les gens du Clan

func _register_interactions() -> void:
	if _registered:
		return
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	_registered = true
	for id in clan:
		var m: Node3D = clan[id]
		var it := {"id": "pixel_" + str(id), "pos": m.global_position, "radius": 2.0,
			"text": "E : parler à " + str(m.display_name), "vr": "Gâchette : parler à " + str(m.display_name), "call": _parler.bind(str(id))}
		d._interactions.append(it)
		m.set_meta("it", it)
	if grottes != null:
		grottes.register(d)


func _parler(id: String) -> void:
	var m: Node3D = clan.get(id)
	if m == null:
		return
	(state["parle"] as Dictionary)[id] = true
	if not bool(state.get("rencontre", false)) and id != "ploc" and id != "pika":
		_rencontre()
		return
	m.begin_talk()
	match id:
		"ougha":
			if bool(state.get("trex", false)):
				if str(state.get("quete", "")) != "fini":
					state["quete"] = "fini"
					_ask(m, "content", Textes.OUGHA_VICTOIRE, [{"id": "fete", "label": "Une fête ? Génial !"}], _ougha_fete)
					return
				_ask(m, "content", str(Textes.OUGHA_APRES[randi() % Textes.OUGHA_APRES.size()]), [{"id": "fermer", "label": "À bientôt, Ougha !"}], _bye.bind(id))
			elif str(state.get("quete", "")) == "en_cours":
				_ask(m, "serieux", str(Textes.OUGHA_ENCOURS[randi() % Textes.OUGHA_ENCOURS.size()]), [{"id": "fermer", "label": "J'y vais !"}], _bye.bind(id))
			else:
				_ask(m, "serieux", Textes.QUETE, Textes.QUETE_CHOIX, _quete_choix)
		"ocre":
			if bool(state.get("portrait", false)):
				_ask(m, "content", str(Textes.OCRE_APRES[randi() % Textes.OCRE_APRES.size()]), [{"id": "fermer", "label": "Merci, Ocre !"}], _bye.bind(id))
			else:
				_ask(m, "malin", Textes.OCRE, Textes.OCRE_CHOIX, _ocre_choix)
		"mamie_silex":
			var now: float = Time.get_ticks_msec() / 1000.0
			if int(state.get("galettes", 0)) == 0:
				_ask(m, "de bonne humeur", Textes.MAMIE, [{"id": "merci", "label": "Merci, Mamie Silex !"}], _mamie_donne.bind(2))
			elif now - float(state.get("galette_t", -1e9)) > 240.0:
				_ask(m, "de bonne humeur", str(Textes.MAMIE_ENCORE[randi() % Textes.MAMIE_ENCORE.size()]), [{"id": "merci", "label": "Miam, merci !"}], _mamie_donne.bind(1))
			else:
				_ask(m, "de bonne humeur", str(Textes.MAMIE_PLUS[randi() % Textes.MAMIE_PLUS.size()]), [{"id": "fermer", "label": "D'accord !"}], _bye.bind(id))
		"grok":
			_ask(m, "serieux", Textes.GROK, Textes.GROK_CHOIX, _grok_choix)
		"ploc", "pika":
			_ask(m, "farceur", Textes.PLOC if id == "ploc" else Textes.PIKA, Textes.ENFANTS_CHOIX, _enfants_choix.bind(id))
		"vieux_flint":
			_ask(m, "sage", Textes.FLINT, Textes.FLINT_CHOIX, _flint_choix)
		"boum":
			_ask(m, "de bonne humeur", Textes.BOUM, Textes.BOUM_CHOIX, _boum_choix)


func _ask(m: Node3D, mood: String, text: String, choices: Array, cb: Callable) -> void:
	main.ask_v69(m, str(m.display_name), mood, text, choices, cb)


func _bye(_id: String, who: String) -> void:
	main._close_dialogue_v31()
	var m: Node3D = clan.get(who)
	if m != null:
		m.end_talk()


func _close(who: String) -> void:
	main._close_dialogue_v31()
	var m: Node3D = clan.get(who)
	if m != null:
		m.end_talk()


## La première rencontre : le Clan se cache, puis Ougha s'avance.
func _rencontre() -> void:
	state["rencontre"] = true
	for id in clan:
		var m: Node3D = clan[id]
		if id != "ougha":
			m.gesture("peur", 2.5)
	var o: Node3D = clan["ougha"]
	o.begin_talk()
	o.gesture("colere", 1.5)
	_ask(o, "inquiet", Textes.RENCONTRE, Textes.RENCONTRE_CHOIX, _rencontre_rep)


func _rencontre_rep(id: String) -> void:
	var o: Node3D = clan["ougha"]
	for k in clan:
		(clan[k] as Node3D).gesture("rire" if id == "bouh" else "joie", 2.5)
	_ask(o, "content", str(Textes.RENCONTRE_REP.get(id, "")), [{"id": "suite", "label": "…"}], _rencontre_suite)


func _rencontre_suite(_id: String) -> void:
	var o: Node3D = clan["ougha"]
	_ask(o, "serieux", Textes.QUETE, Textes.QUETE_CHOIX, _quete_choix)


func _quete_choix(id: String) -> void:
	var o: Node3D = clan["ougha"]
	if id == "oui":
		state["quete"] = "en_cours"
		o.gesture("joie", 2.0)
		_ask(o, "content", Textes.QUETE_OUI, [{"id": "fermer", "label": "Compris !"}], _bye.bind("ougha"))
		var j: Node = main.get("journal_v56")
		if j != null:
			j.lieux["cirque_des_os"] = objets.get("cirque", Vector3.ZERO)
	else:
		_ask(o, "serieux", Textes.QUETE_NON, [{"id": "fermer", "label": "À plus tard !"}], _bye.bind("ougha"))


func _ougha_fete(_id: String) -> void:
	_close("ougha")
	_danse(14.0)
	var mv: Node = main.get("maisons_v81")
	if mv != null:
		mv.give([["piece", 60], ["piece_or", 2]], "Le Clan te couvre de cadeaux (surtout des pièces brillantes trouvées dans la rivière). ")


func _ocre_choix(id: String) -> void:
	var m: Node3D = clan["ocre"]
	if id != "essaie":
		_close("ocre")
		return
	m.gesture("peindre", 3.0)
	_ask(m, "content", Textes.OCRE_PORTRAIT, [{"id": "merci", "label": "Il est magnifique ! (Il est très carré.)"}], _ocre_fin)


func _ocre_fin(_id: String) -> void:
	_close("ocre")
	if not bool(state.get("portrait", false)):
		state["portrait"] = true
		var mv: Node = main.get("maisons_v81")
		if mv != null:
			mv.give([["peinture_clan", 1]], "")
		if grottes != null:
			grottes.refresh()


func _mamie_donne(_id: String, n: int) -> void:
	_close("mamie_silex")
	state["galettes"] = int(state.get("galettes", 0)) + n
	state["galette_t"] = Time.get_ticks_msec() / 1000.0
	var mv: Node = main.get("maisons_v81")
	if mv != null:
		mv.give([["galette_fougere", n]], "")


func _grok_choix(id: String) -> void:
	var m: Node3D = clan["grok"]
	if id == "fermer" or not Textes.GROK_REP.has(id):
		_close("grok")
		return
	m.gesture("pointer", 1.5)
	_ask(m, "serieux", str(Textes.GROK_REP[id]), Textes.GROK_CHOIX, _grok_choix)


func _enfants_choix(id: String, who: String) -> void:
	_close(who)
	if id == "jouer":
		for k in ["ploc", "pika"]:
			var c: Node3D = clan[k]
			c.gesture("joie", 2.0)
			c.say(str(Textes.ENFANTS_JEU[randi() % Textes.ENFANTS_JEU.size()]), 5.0)
			var a: float = randf() * TAU
			c.walk_to(c.global_position + Vector3(cos(a) * 6.0, 0, sin(a) * 6.0), 3.2)


func _flint_choix(id: String) -> void:
	var m: Node3D = clan["vieux_flint"]
	if id == "fermer" or not Textes.FLINT_REP.has(id):
		_close("vieux_flint")
		return
	_ask(m, "sage", str(Textes.FLINT_REP[id]), Textes.FLINT_CHOIX, _flint_choix)


func _boum_choix(id: String) -> void:
	_close("boum")
	if id == "danse":
		say(Textes.BOUM_DANSE, 5.0)
		_danse(10.0)


## Tout le Clan danse autour du feu (Boum au tambour).
func _danse(seconds: float) -> void:
	state["danse"] = true
	_danse_t = seconds
	main.sfx("tambour")
	for id in clan:
		var m: Node3D = clan[id]
		if id == "boum":
			continue
		m.set_meta("pose_avant", m.pose)
		m.set_pose("danse")


func _danse_tick(delta: float) -> void:
	if _danse_t <= 0.0:
		return
	_danse_t -= delta
	if fmod(_danse_t, 0.55) < delta:
		main.sfx("tambour", clan["boum"].global_position, -6.0)
	if _danse_t <= 0.0:
		for id in clan:
			var m: Node3D = clan[id]
			if m.has_meta("pose_avant"):
				m.set_pose(str(m.get_meta("pose_avant")))
				m.remove_meta("pose_avant")


# =================================================================== les dinosaures

func _lairs_init() -> void:
	lairs.clear()
	for L in REPAIRES:
		lairs.append({"id": str(L[0]), "c": _ground((L[1] as Vector2).x, (L[1] as Vector2).y), "r": float(L[2]), "respawn": float(L[3]),
			"list": L[4], "monsters": [], "dead_t": -1e15})


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _lairs_tick() -> void:
	var ms: Node = main.get("monstres_v36")
	if ms == null:
		return
	var p: Vector3 = main._player_pos_v27()
	for L in lairs:
		var d: float = Vector2(p.x - L["c"].x, p.z - L["c"].z).length()
		var mons: Array = (L["monsters"] as Array).filter(func(m): return is_instance_valid(m) and str(m.get("state")) != "mort")
		L["monsters"] = mons
		if mons.is_empty() and d < float(L["r"]) and _now() - float(L["dead_t"]) > float(L["respawn"]):
			for e in L["list"]:
				var at: Vector3 = _ground(float(e[1]), float(e[2])) + Vector3.UP * 0.3
				var m: Node3D = ms.spawn_extra(str(e[0]), at)
				if m != null:
					m.set("home", at)
					m.set("state", "veille")
					mons.append(m)
			L["monsters"] = mons
			L["dead_t"] = _now()
		elif not mons.is_empty() and d > float(L["r"]) + 70.0:
			for m2 in mons:
				if is_instance_valid(m2):
					m2.queue_free()
			L["monsters"] = []
			L["dead_t"] = -1e15
	# Grosse-Dent : dans son cirque, tant qu'il n'est pas vaincu
	var a: Array = IleScript.CIRQUE
	var cc: Vector3 = _ground(float(a[0]), float(a[1]))
	var dc: float = Vector2(p.x - cc.x, p.z - cc.z).length()
	if not bool(state.get("trex", false)):
		if (boss == null or not is_instance_valid(boss)) and dc < float(a[2]) + 26.0:
			boss = ms.spawn_extra("trex", cc + Vector3(0, 0.3, -8.0))
			if boss != null:
				boss.set("home", cc)
				boss.set("state", "veille")
				boss.died.connect(_on_trex)
		elif boss != null and is_instance_valid(boss) and dc > float(a[2]) + 90.0 and str(boss.get("state")) != "mort":
			boss.queue_free()
			boss = null


func _on_trex(_m: Node3D) -> void:
	state["trex"] = true
	if main.has_method("jingle"):
		main.jingle("victoire")
	await get_tree().create_timer(4.0).timeout
	say("Grosse-Dent s'écroule… et se met à RONFLER. Il dort comme un bébé (un bébé de huit tonnes). Le Clan va en parler pendant des générations ! Retourne voir Ougha au Campement.", 9.0)
	_sync()


## L'état visible : Grosse-Dent endormi dans son cirque (une fois vaincu).
func _sync() -> void:
	if bool(state.get("trex", false)):
		if dodo == null:
			dodo = Faune.trex_endormi(self, _ground(float(IleScript.CIRQUE[0]), float(IleScript.CIRQUE[1]) - 6.0))
	elif dodo != null:
		dodo.queue_free()
		dodo = null


# =================================================================== services du jeu

func say(text: String, seconds: float = 6.0) -> void:
	var d: Node = main.get("donjon_v35")
	if d != null and d.has_method("_say"):
		d._say(text, seconds)
	else:
		main._show_message_v28(text)


func register_services(journal: Node) -> void:
	for k in objets:
		journal.lieux["pixel_" + str(k)] = objets[k]
	journal.lieux["pixel"] = respawn_point()[0]
	_register_interactions()


func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z) and p.y > -45.0


## À pied : partout sur la terre ferme… sauf dans la lave du volcan.
func walkable(p: Vector3) -> bool:
	if not contains(p):
		return false
	if ile.in_lava(p.x, p.z):
		return false
	return ile.height(p.x, p.z) > -0.3 or p.y > 1.0


func owns_point(p: Vector3) -> bool:
	return contains(p) or (grottes != null and grottes.contains(p))


func zone_at(p: Vector3) -> String:
	if not contains(p):
		return ""
	var l: Vector2 = IleScript.L(p.x, p.z)
	var a: Array = IleScript.CIRQUE
	if l.distance_to(Vector2(float(a[0]), float(a[1]))) < float(a[2]) + 8.0:
		return "cirque"
	var v: Array = IleScript.VOLCAN
	if l.distance_to(Vector2(float(v[0]), float(v[1]))) < float(v[2]) * 0.8:
		return "volcan"
	if l.distance_to(FEU) < 32.0 and l.x > IleScript.FALAISE_X - 1.0:
		return "camp"
	if l.x < IleScript.FALAISE_X - 2.0 and absf(l.y) < 70.0:
		return "falaises"
	var lc: Array = IleScript.LAC
	if l.distance_to(Vector2(float(lc[0]), float(lc[1]))) < float(lc[2]) + 12.0:
		return "lac"
	if l.y > IleScript.PLAGE_Z - 12.0:
		return "plage"
	if l.x < 10.0 and l.y < -20.0:
		return "plaine"
	if l.x > 20.0:
		return "jungle"
	return "ile"


func place_name(p: Vector3) -> String:
	if grottes != null and grottes.contains(p):
		return grottes.place_name(p)
	return "L'Île Pixelithique, " + str(PLACES.get(zone_at(p), "l'île"))


func village_point(_id: String) -> Array:
	return respawn_point()


func respawn_point() -> Array:
	var p: Vector3 = _ground(18.0, 118.0) + Vector3.UP * 0.3
	return [p, Vector3(0, 0, -1)]


func on_faint(p: Vector3) -> void:
	var at: Array = respawn_point()
	if grottes != null and grottes.contains(p):
		at = grottes.respawn_point()
	elif zone_at(p) in ["camp", "falaises", "cirque", "plaine", "lac"]:
		at = [_ground(FEU.x + 3.0, FEU.y + 3.0) + Vector3.UP * 0.3, Vector3(-1, 0, 0)]
	main.place_player_v35(at[0], at[1])
	if zone_at(p) == "cirque":
		say("Tu te réveilles près du feu du Clan. Mamie Silex te tamponne le front avec de la mousse froide : « Grosse-Dent trop fort ? Manger d'abord. Après, retourner taper. »", 8.0)


func hour() -> float:
	var t: Node = main.get("temps_v56")
	return float(t.hour) if t != null else 12.0


func _process(delta: float) -> void:
	if main == null or ile == null:
		return
	_clock += delta
	if _feu_light != null:
		_feu_light.light_energy = 2.2 + 0.5 * sin(_clock * 13.0) * sin(_clock * 7.3)
	if _lava_light != null:
		_lava_light.light_energy = 3.2 + 0.6 * sin(_clock * 1.7)
	_danse_tick(delta)
	var p: Vector3 = main._player_pos_v27()
	if not ile.contains(p.x, p.z):
		return
	# les gens du Clan suivent leur interaction (les enfants bougent)
	for id in clan:
		var m: Node3D = clan[id]
		if m.has_meta("it"):
			(m.get_meta("it") as Dictionary)["pos"] = m.global_position
		# les enfants reviennent jouer près du feu
		if id in ["ploc", "pika"] and bool(m.get("arrived")) and randf() < delta * 0.08:
			var a: float = randf() * TAU
			m.walk_to(_ground(FEU.x + cos(a) * 8.0, FEU.y + sin(a) * 8.0), 1.6)
	_lair_t -= delta
	if _lair_t <= 0.0:
		_lair_t = 0.5
		_lairs_tick()
	if not bool(state["visite"]) and ile.height(p.x, p.z) > -0.2 and bool(main.get("game_started")):
		state["visite"] = true
		main._show_message_v28("L'Île Pixelithique — ici, tout est en petits carrés… sauf toi")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	_zone_t -= delta
	if _zone_t > 0.0:
		return
	_zone_t = 1.0
	var z: String = zone_at(p)
	var vis: Dictionary = state["visites"]
	if z != "" and z != "ile" and not bool(vis.get(z, false)):
		vis[z] = true
		var msg := {"camp": "Le Campement du Clan — un feu, un totem, des séchoirs… et des yeux carrés qui t'observent derrière les rochers",
			"cirque": "Le Cirque des Os — des os partout. Et, quelque part, un souffle énorme",
			"volcan": "Le Mont Fumant — il fume, il gronde, il crache du rouge. Ne marche pas sur le rouge !",
			"lac": "Le Lac des Long-Cous — des cous si longs qu'ils broutent la cime des arbres",
			"plaine": "La Plaine des Cornes — attention aux Corne-Sur-Nez, ils sont grincheux",
			"jungle": "La Jungle des Fougères — des fougères grandes comme des arbres, et des sifflements entre les feuilles",
			"falaises": "Les Falaises du Clan — les grottes du Clan sont creusées dans la roche",
			"plage": "La Plage des Œufs — des nids, des œufs… ne les dérange pas"}
		if msg.has(z):
			main._show_message_v28(str(msg[z]))


func trouvailles() -> Dictionary:
	var vis: Dictionary = state.get("visites", {})
	return {"pixel": 1 if bool(state.get("visite", false)) else 0, "pixel_clan": 1 if bool(state.get("rencontre", false)) else 0,
		"pixel_volcan": 1 if bool(vis.get("volcan", false)) else 0, "pixel_lac": 1 if bool(vis.get("lac", false)) else 0,
		"pixel_cirque": 1 if bool(vis.get("cirque", false)) else 0, "pixel_trex": 1 if bool(state.get("trex", false)) else 0,
		"pixel_portrait": 1 if bool(state.get("portrait", false)) else 0, "pixel_grottes": 1 if bool(state.get("grotte_clan", false)) and bool(state.get("grotte_peintures", false)) else 0,
		"pixel_danse": 1 if bool(state.get("danse", false)) else 0}


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	state = _fresh_state()
	for k in state:
		if d.has(k):
			state[k] = d[k] if not (d[k] is Dictionary) else (d[k] as Dictionary).duplicate(true)
	if grottes != null and grottes.inside:
		grottes.teardown()
	_sync()
	if grottes != null:
		grottes.refresh()
