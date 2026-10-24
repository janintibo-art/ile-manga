extends Node3D
## V70 : l'Île de Braise — le chef d'orchestre. Il construit l'île (ile_braise_v70), la cité
## (pandemonia_v70, ses grands lieux, son port), ce qu'il y a dehors (braise_dehors_v70 : les
## Ruines, les sources de soufre, le belvédère…) et la végétation (braise_flore_v70) ; il tient
## la lave (le Cercle de Feu, les coulées, le cratère : elle brûle !), les feux, les fumées, la
## vapeur, la lueur des fenêtres et des lanternes à la nuit ; il fait vivre les démons de
## Pandémonia selon l'heure ; il réveille les monstres de l'île quand on s'en approche ; il tient
## le donjon des Neuf Cercles (neuf_cercles_v70), l'Arène des Cornes (arene_v70) et la Nuit des
## Lanternes (fete_v70).

const IleScript = preload("res://scripts/ile_braise_v70.gd")
const CityScript = preload("res://scripts/pandemonia_v70.gd")
const FloreScript = preload("res://scripts/braise_flore_v70.gd")
const DehorsScript = preload("res://scripts/braise_dehors_v70.gd")
const Mats = preload("res://scripts/braise_mats_v70.gd")
const HABITANTS := "res://scripts/pnj/braise_habitants_v70.gd"
const PNJ := "res://scripts/pnj/pnj_braise_v70.gd"
const DONJON := "res://scripts/neuf_cercles_v70.gd"
const ARENE := "res://scripts/arene_v70.gd"
const FETE := "res://scripts/fete_v70.gd"

## Les repaires de l'île : [id, centre local (x, z), rayon d'éveil, quand ("" toujours, "nuit"),
## réapparition (s), [[sorte, x, z], …]].
const LAIRS := [
	["champ_lave", Vector2(-60.0, 214.0), 44.0, "", 480.0, [["chien_enfer", -70.0, 204.0], ["chien_enfer", -50.0, 222.0], ["chien_enfer", -66.0, 230.0]]],
	["ruines", Vector2(-236.0, -190.0), 42.0, "", 540.0, [["gargouille", -228.0, -184.0], ["gargouille", -246.0, -194.0], ["gargouille", -232.0, -204.0]]],
	["bois_nuit", Vector2(206.0, 236.0), 38.0, "nuit", 420.0, [["diablotin", 198.0, 230.0], ["diablotin", 212.0, 240.0], ["diablotin", 204.0, 248.0]]],
]

var main: Node
var ile: Node3D
var city: Node3D                         # Pandémonia (pandemonia_v70)
var dehors: Node3D
var flore: Node3D
var pc: bool = true
var habitants: Array = []
var by_id: Dictionary = {}
var state := {}
var lairs: Array = []
var dungeon: Node3D                      # les Neuf Cercles
var arena: Node                          # l'Arène des Cornes (le tournoi)
var fete: Node                           # la Nuit des Lanternes
var lava_meshes: Array = []
var coeur_fire: Node3D                   # le Cœur-Brasier : son feu (faible, puis vif)
var _claims: Dictionary = {}
var _clock: float = 0.0
var _rng := RandomNumberGenerator.new()
var _fires: Array = []
var _smoke: Array = []
var _night: bool = false
var _night_t: float = 0.0
var _lair_t: float = 0.0
var _lava_t: float = 0.0
var _safe := Vector3.INF                 # le dernier endroit sûr du joueur (loin de la lave)
var _puppies: Array = []
var _interactions: Array = []


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_rng.seed = 7090
	state = _fresh_state()


func _fresh_state() -> Dictionary:
	return {"visite": false, "visites": {}, "coeur": false, "porte": false, "flamme": false, "lanternes": {}, "fusees": false, "fete": false,
		"pepin": false, "chiens": false, "gargouilles": false, "fleurs": {}, "cristaux": {}, "tournoi": 0, "champion": false,
		"examens": {}, "courrier": {}, "nuits": 0}


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_braise_v70"
	add_child(ile)
	ile.build(pc)


## Après le relief et l'heure du jour : la cité, le dehors, la végétation, la lave, les feux,
## le donjon, l'arène, la fête.
func build_town() -> void:
	var t0: int = Time.get_ticks_msec()
	city = CityScript.new()
	city.name = "Pandemonia_v70"
	add_child(city)
	city.build(main, ile, pc)
	dehors = DehorsScript.new()
	dehors.name = "Braise_dehors_v70"
	add_child(dehors)
	dehors.build(self)
	_build_lava()
	flore = FloreScript.new()
	flore.name = "Flore_braise_v70"
	add_child(flore)
	for a in city.flora_avoid:
		flore.avoid.append(a)
	for a2 in dehors.flora_avoid:
		flore.avoid.append(a2)
	flore.build_braise(ile, pc, {"arbres": city.tree_spots, "massifs": city.basse.garden_spots})
	# les feux (braseros, statues, fontaines, forges : ils brûlent jour et nuit), les fumées
	for f in city.fire_spots:
		_fires.append([_make_fire(f[0], float(f[1]), true), true])
	for f2 in dehors.fire_spots:
		_fires.append([_make_fire(f2[0], float(f2[1]), true), true])
	var n_smoke: int = 0
	for sp in city.smoke_spots:
		if n_smoke < (60 if pc else 25):
			_smoke.append(_make_smoke(sp, Color(0.36, 0.34, 0.33, 0.28)))
			n_smoke += 1
	for vp in city.basse.vapeur:
		_smoke.append(_make_smoke(vp, Color(0.95, 0.92, 0.82, 0.16), 0.6))
	for sp2 in IleScript.SPRINGS:
		var w: Vector3 = IleScript.W(sp2.x, sp2.y, IleScript.SPRING_Y)
		for k in range(3):
			_smoke.append(_make_smoke(w + Vector3(_rng.randf_range(-3.0, 3.0), -0.6, _rng.randf_range(-3.0, 3.0)), Color(0.95, 0.9, 0.7, 0.2), 0.8))
	_make_plume()
	_glows()
	_build_coeur()
	_build_puppies()
	_build_lairs()
	# le donjon (construit seulement à la première descente), l'arène, la fête
	if ResourceLoader.exists(DONJON):
		dungeon = load(DONJON).new()
		dungeon.name = "Neuf_Cercles_v70"
		add_child(dungeon)
		dungeon.setup(main, self)
	if ResourceLoader.exists(ARENE):
		arena = load(ARENE).new()
		arena.name = "Arene_v70"
		add_child(arena)
		arena.setup(main, self)
	if ResourceLoader.exists(FETE):
		fete = load(FETE).new()
		fete.name = "Fete_v70"
		add_child(fete)
		fete.setup(main, self)
	print("ILE_MANGA_V70: l'Île de Braise est prête (%d ms)" % (Time.get_ticks_msec() - t0))


## La lave : l'anneau du Cercle de Feu (posé par la cité), les coulées, le lac du cratère ;
## leurs lumières.
func _build_lava() -> void:
	var mat: Material = Mats.make("lave70")
	for fw in ile.flows_world:
		var pts: Array = fw[0]
		var hw: float = float(fw[1])
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var acc: float = 0.0
		for i in range(pts.size() - 1):
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			var d: Vector3 = (b - a)
			d.y = 0.0
			var side: Vector3 = Vector3(-d.z, 0, d.x).normalized() * (hw + 0.6)
			var l0: float = acc
			acc += a.distance_to(b)
			var quad := [[a - side, Vector2(l0, 0)], [b - side, Vector2(acc, 0)], [b + side, Vector2(acc, hw * 2.0)], [a + side, Vector2(l0, hw * 2.0)]]
			for v in [quad[0], quad[2], quad[1], quad[0], quad[3], quad[2]]:
				st.set_normal(Vector3.UP)
				st.set_uv(v[1])
				st.add_vertex(v[0])
			if i % 12 == 6:
				_lava_light(a + Vector3.UP * 1.6, 2.0, 14.0)
		st.generate_tangents()
		var mi := MeshInstance3D.new()
		mi.name = "Coulee_de_lave"
		mi.mesh = st.commit()
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		lava_meshes.append(mi)
	# le lac du cratère
	var cc: Vector3 = IleScript.W(IleScript.VOLCANO.x, IleScript.VOLCANO.y, IleScript.CRATER_LAVA_Y)
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r: float = IleScript.CRATER_R + 2.5
	for i2 in range(40):
		var a0: float = TAU * i2 / 40.0
		var a1: float = TAU * (i2 + 1) / 40.0
		for v2 in [[cc, Vector2(0, 0)], [cc + Vector3(cos(a1) * r, 0, sin(a1) * r), Vector2(cos(a1) * r, sin(a1) * r)], [cc + Vector3(cos(a0) * r, 0, sin(a0) * r), Vector2(cos(a0) * r, sin(a0) * r)]]:
			st2.set_normal(Vector3.UP)
			st2.set_uv(v2[1])
			st2.add_vertex(v2[0])
	st2.generate_tangents()
	var lake := MeshInstance3D.new()
	lake.name = "Lac_de_lave_du_cratere"
	lake.mesh = st2.commit()
	lake.material_override = mat
	lake.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lake)
	lava_meshes.append(lake)
	for k in range(3):
		var a3: float = TAU * k / 3.0
		_lava_light(cc + Vector3(cos(a3) * 9.0, 4.0, sin(a3) * 9.0), 5.0, 34.0)
	lava_meshes.append(city.lava_ring)


func _lava_light(at: Vector3, energy: float, rng_m: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.42, 0.12)
	l.light_energy = energy
	l.omni_range = rng_m
	l.omni_attenuation = 1.3
	l.shadow_enabled = false
	l.light_volumetric_fog_energy = 1.4
	l.distance_fade_enabled = true
	l.distance_fade_begin = 220.0
	l.distance_fade_length = 40.0
	add_child(l)
	l.position = at
	return l


## La lueur des fenêtres, des vitraux, des lanternes, de la lave et des arbres de braise monte
## à la nuit tombée (temps_v56).
func _glows() -> void:
	var t: Node = main.get("temps_v56") if main != null else null
	if t == null or not t.has_method("register_glow"):
		Mats.night(0.0)
		return
	t.register_glow(Mats.make("fenetre70"), 2.4, 0.15)
	t.register_glow(Mats.make("vitrail70_rosace"), 1.8, 0.35)
	t.register_glow(Mats.make("vitrail70_lancette"), 1.8, 0.35)
	t.register_glow(Mats.make("verre70"), 3.4, 0.6)
	t.register_glow(Mats.make("lave70"), 4.2, 3.0)
	for c in ile.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).material_override is ShaderMaterial:
			t.register_glow((c as MeshInstance3D).material_override, 1.7, 0.9)
			break
	for g in flore.glow_mats:
		t.register_glow(g[0], float(g[1]), float(g[2]))


# =================================================================== le Cœur-Brasier

## Le grand feu de la Cathédrale-Forge : pâle et bleuté (il faiblit) tant que la Flamme
## Éternelle n'est pas revenue des Neuf Cercles ; puis une grande flamme d'or.
func _build_coeur() -> void:
	var at: Vector3 = city.lieux.coeur["pos"]
	coeur_fire = Node3D.new()
	coeur_fire.name = "Coeur_Brasier"
	add_child(coeur_fire)
	coeur_fire.position = at
	var p := CPUParticles3D.new()
	p.name = "Flammes"
	p.amount = 90 if pc else 40
	p.lifetime = 1.3
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 1.4
	p.direction = Vector3.UP
	p.spread = 14.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.6
	p.gravity = Vector3(0, 1.6, 0)
	p.scale_amount_min = 0.9
	p.scale_amount_max = 2.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	var qm := QuadMesh.new()
	qm.size = Vector2(0.7, 0.9)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	qm.material = m
	p.mesh = qm
	coeur_fire.add_child(p)
	var l := OmniLight3D.new()
	l.name = "Lumiere"
	l.omni_range = 22.0
	l.omni_attenuation = 1.1
	l.shadow_enabled = pc
	l.position = Vector3.UP * 1.6
	coeur_fire.add_child(l)
	_apply_coeur()


func _apply_coeur() -> void:
	if coeur_fire == null:
		return
	var vif: bool = bool(state.get("coeur", false))
	var p: CPUParticles3D = coeur_fire.get_node("Flammes")
	var l: OmniLight3D = coeur_fire.get_node("Lumiere")
	var grad := Gradient.new()
	if vif:
		grad.set_color(0, Color(1.0, 0.9, 0.5, 1.0))
		grad.set_color(1, Color(1.0, 0.25, 0.05, 0.0))
		p.amount = 90 if pc else 40
		p.initial_velocity_max = 2.8
		p.emission_sphere_radius = 1.4
		l.light_color = Color(1.0, 0.62, 0.28)
		l.light_energy = 4.0
	else:
		grad.set_color(0, Color(0.6, 0.75, 1.0, 0.8))
		grad.set_color(1, Color(0.2, 0.3, 0.9, 0.0))
		p.amount = 24
		p.initial_velocity_max = 1.0
		p.emission_sphere_radius = 0.5
		l.light_color = Color(0.5, 0.65, 1.0)
		l.light_energy = 1.2
	p.color_ramp = grad


## Pépin s'est perdu dans le Bois de Cendre (la quête de Zébuline) : tant qu'on ne l'a pas
## retrouvé, il attend dans le bois, assis derrière un tronc.
func _tick_pepin() -> void:
	var npc: Node = by_id.get("pepin_braise", null)
	if npc == null or not is_instance_valid(npc):
		return
	var j: Node = main.get("journal_v56")
	var lost: bool = j != null and str(j.state("br_pepin")) == "en_cours" and not bool(state.get("pepin", false))
	if lost and not npc.has_meta("agenda_v70"):
		npc.set_meta("agenda_v70", npc.agenda)
		npc.agenda = [[0, 24, "bois_pepin"]]
		npc.slot = -2
	elif not lost and npc.has_meta("agenda_v70"):
		release_pepin()
	# on le trouve en s'approchant de sa cachette (il répond à son nom… ou on lui parle)
	if lost and dehors != null and dehors.pepin_hide != Vector3.ZERO:
		var p: Vector3 = main._player_pos_v27()
		if p.distance_to(dehors.pepin_hide) < 4.5 and dehors.has_method("_found_pepin"):
			dehors._found_pepin()


func release_pepin() -> void:
	var npc: Node = by_id.get("pepin_braise", null)
	if npc == null or not is_instance_valid(npc) or not npc.has_meta("agenda_v70"):
		return
	npc.agenda = npc.get_meta("agenda_v70")
	npc.remove_meta("agenda_v70")
	npc.slot = -2


## La Flamme Éternelle rendue au Cœur-Brasier (la quête de l'Archiduchesse).
func _rekindle() -> void:
	var inv: Node = main.inventory_v28
	if inv.count("flamme_eternelle") <= 0:
		_say("Le Cœur-Brasier n'est plus qu'une petite flamme bleue. Il lui faut la Flamme Éternelle, perdue au fond des Neuf Cercles.")
		return
	inv.remove("flamme_eternelle", 1)
	state["coeur"] = true
	_apply_coeur()
	if main.has_method("sfx"):
		main.sfx("feu_souffle", coeur_fire.global_position)
	if main.has_method("jingle"):
		main.jingle("victoire")
	_say("La Flamme Éternelle bondit dans le Cœur-Brasier ! Une grande flamme d'or monte jusqu'aux voûtes, et toute la cité se réchauffe d'un coup. Va le dire à l'Archiduchesse !")


# =================================================================== les interactions

func _register_interactions() -> void:
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	var me = self
	var door: Vector3 = city.lieux.porte_cercles
	_ia(d, {"id": "braise_porte_cercles", "pos": door, "radius": 2.2, "text": "E : descendre dans les Neuf Cercles", "vr": "Gâchette : descendre dans les Neuf Cercles",
		"call": func(): me._enter_dungeon(), "when": func(): return true})
	_ia(d, {"id": "braise_coeur", "pos": city.lieux.coeur["base"] + Vector3.UP * 0.6, "radius": 4.2, "text": "E : rendre la Flamme Éternelle au Cœur-Brasier",
		"vr": "Gâchette : rendre la Flamme Éternelle", "call": func(): me._rekindle(),
		"when": func(): return not bool(me.state.get("coeur", false)) and me.main.inventory_v28.count("flamme_eternelle") > 0})
	if dehors != null and dehors.has_method("register_interactions"):
		dehors.register_interactions(d, self)
	if arena != null and arena.has_method("register_interactions"):
		arena.register_interactions(d)
	if fete != null and fete.has_method("register_interactions"):
		fete.register_interactions(d)


func _ia(d: Node, it: Dictionary) -> void:
	d._interactions.append(it)
	_interactions.append(it)


func _enter_dungeon() -> void:
	if dungeon == null:
		return
	if not bool(state.get("porte", false)):
		if main.inventory_v28.count("cle_brasier") <= 0:
			_say("La grande porte de fer est fermée à clé. « Vous qui entrez ici, gardez l'espoir (et prenez un manteau). » Frère Cendrin, le gardien du Cœur-Brasier, garde la Clé du Brasier.")
			return
		state["porte"] = true
		if main.has_method("sfx"):
			main.sfx("grande_porte", city.lieux.porte_cercles)
		_say("La Clé du Brasier tourne dans la serrure. La porte de fer s'ouvre sur un escalier qui descend… et un air glacé monte des profondeurs.")
	dungeon.enter()


func _say(text: String, seconds: float = 6.0) -> void:
	if main != null and main.get("donjon_v35") != null:
		main.donjon_v35._say(text, seconds)
	elif main != null:
		main._show_message_v28(text)


# =================================================================== les repères des autres

func dock() -> Array:
	return [IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y), IleScript.W(IleScript.DOCK_B.x, IleScript.DOCK_B.y)]


func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z) and p.y > -45.0


func on_structure(p: Vector3) -> bool:
	return city != null and city.on_structure(p)


## À pied : on peut marcher ici (la terre ferme, les ponts, les quais) ? Pas dans la lave (on y
## entre, mais elle brûle et l'on est ramené : voir _tick_lava).
func walkable(p: Vector3) -> bool:
	if not contains(p):
		return false
	if on_structure(p):
		return true
	return ile.height(p.x, p.z) > -0.3 or p.y > 1.0


func blocks_boat(p: Vector3) -> bool:
	if city == null or city.basse == null:
		return false
	for k in city.basse.ships:
		var sh: Node = city.basse.ships[k]
		if sh != null and sh.has_method("blocks_boat") and sh.blocks_boat(p):
			return true
	return false


## La zone du joueur (pour la musique et les ambiances).
func zone_at(p: Vector3) -> String:
	if dungeon != null and dungeon.contains(p):
		return "braise_cercles"
	if ile == null or not ile.contains(p.x, p.z) or p.y < -20.0:
		return ""
	# la Nuit des Lanternes : toute la Grand-Place danse
	if fete != null and bool(fete.get("active")) and Vector2(p.x - fete.ctr.x, p.z - fete.ctr.z).length() < 60.0:
		return "braise_fete"
	var cz: String = city.zone_at(p) if city != null else ""
	if cz != "":
		return cz
	var l: Vector2 = IleScript.L(p.x, p.z)
	var h: float = ile.height(p.x, p.z)
	if h < -0.42 and p.y < 2.0 and not on_structure(p):
		return "" if IleScript.coast_q(l.x, l.y) > 1.12 else "braise_rivage"
	if l.distance_to(IleScript.VOLCANO) < 30.0 and p.y > 80.0:
		return "braise_cratere"
	for sp in IleScript.SPRINGS:
		if l.distance_to(sp) < 22.0:
			return "braise_sources"
	if l.distance_to(IleScript.LAVA_FIELD) < IleScript.LAVA_FIELD_R:
		return "braise_champ"
	if l.distance_to(IleScript.RUINS) < IleScript.RUINS_R + 14.0:
		return "braise_ruines"
	if l.distance_to(IleScript.FOREST) < IleScript.FOREST_R:
		return "braise_bois"
	if l.distance_to(IleScript.VOLCANO) < 125.0:
		return "braise_volcan"
	if IleScript.coast_q(l.x, l.y) > 0.9:
		return "braise_rivage"
	return "braise_landes"


## La région « culturelle » d'un point (pour les ambiances) : la cité, ou l'île sauvage.
func people_at(p: Vector3) -> String:
	var z: String = zone_at(p)
	if z == "":
		return ""
	if z in ["braise_rivage", "braise_landes", "braise_volcan", "braise_bois", "braise_ruines", "braise_champ", "braise_sources", "braise_cratere"]:
		return "sauvage"
	return "cite"


## Les points d'arrivée de la téléportation (teleport_v58).
func village_point(id: String) -> Array:
	match id:
		"pandemonia":
			return respawn_point()
		"pandemonia_port":
			return [city.points["po_rampe"] + Vector3.UP * 0.3, Vector3(0, 0, -1)]
	return []


## Le nom du lieu (pour le carnet, la page des personnages) : « Île de Braise, … ».
func place_name(p: Vector3) -> String:
	var z: String = zone_at(p)
	return "Île de Braise, " + str({"braise_palais": "la Citadelle", "braise_trone": "la salle du trône", "braise_haute": "Pandémonia, la Haute-Ville",
		"braise_cercle": "le Cercle de Feu", "braise_basse": "Pandémonia, la Basse-Ville", "braise_place": "la Grand-Place des Lanternes",
		"braise_cathedrale": "la Cathédrale-Forge", "braise_bibliotheque": "la Bibliothèque des Âmes", "braise_academie": "l'Académie Infernale",
		"braise_arene": "l'Arène des Cornes", "braise_thermes": "les Thermes de Soufre", "braise_taverne": "la taverne « Au Diable Repu »",
		"braise_port": "la Rade de Cendre", "braise_cercles": "les Neuf Cercles", "braise_cratere": "le cratère du Grand Brasier",
		"braise_volcan": "le Grand Brasier", "braise_sources": "les sources de soufre", "braise_champ": "le champ de lave",
		"braise_ruines": "les Ruines de l'Ancien Pandémonium", "braise_bois": "le Bois de Cendre", "braise_rivage": "le rivage de sable noir",
		"braise_landes": "les landes de cendre"}.get(z, "l'île"))


func respawn_point() -> Array:
	var at: Vector3 = city.points.get("pl_o", city.PW(0.0, 82.5, city.HY))
	return [at + Vector3.UP * 0.3, -city.radial(0.0)]


## Les monstres de l'île sont éveillés (monstres_v36 : « dehors »).
func hostile_zone(p: Vector3) -> bool:
	for L in lairs:
		if not (L["monsters"] as Array).is_empty() and Vector2(p.x - L["c"].x, p.z - L["c"].z).length() < float(L["r"]) + 20.0:
			return true
	if arena != null and arena.has_method("is_fighting") and arena.is_fighting():
		return true
	return false


func hour() -> float:
	return float(main.temps_v56.hour) if main != null and main.get("temps_v56") != null and main.temps_v56 != null else 12.0


func _now() -> float:
	return float(main.game_menu.seconds) if main != null and main.game_menu != null else 0.0


# =================================================================== les habitants (lieux)

func spot(name: String) -> Dictionary:
	if city != null and (city.spots as Dictionary).has(name):
		return city.spots[name]
	return {}


func spot_free(name: String, who: Node) -> bool:
	var c: Variant = _claims.get(name, null)
	return c == null or c == who or not is_instance_valid(c)


func claim_spot(name: String, who: Node) -> void:
	_claims[name] = who


func release_spot(name: String, who: Node) -> void:
	if _claims.get(name, null) == who:
		_claims.erase(name)


func spawn_npcs() -> void:
	if not habitants.is_empty() or city == null or not ResourceLoader.exists(HABITANTS) or not ResourceLoader.exists(PNJ):
		return
	var H = load(HABITANTS)
	var P = load(PNJ)
	for data in H.all_profiles():
		var home: String = str(data.get("maison", ""))
		var start: String = home if city.points.has(home) else str(city.points.keys()[0])
		var npc: Node3D = P.new()
		main.add_child(npc)
		npc.setup(main, data, city.points, city.graph, start)
		npc.setup_azur(self, data)
		var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			npc.load_data(saved)
		main.npcs_v31.append(npc)
		habitants.append(npc)
		by_id[str(data["id"])] = npc
	print("ILE_MANGA_V70: %d démons à Pandémonia" % habitants.size())


## Les services (les comptoirs : objets_v66 ; les quêtes : journal_v56 ; les lieux des quêtes).
func register_services(journal: Node) -> void:
	for k in city.objets:
		journal.lieux[str(k)] = city.objets[k]
	if dehors != null:
		for k2 in dehors.objets:
			journal.lieux[str(k2)] = dehors.objets[k2]
	journal.lieux["pandemonia"] = respawn_point()[0]
	journal.lieux["cathedrale_forge"] = city.lieux.porte_cercles
	journal.lieux["arene"] = city.basse.arena["porte"]
	if dungeon != null and dungeon.has_method("register"):
		dungeon.register(journal)
	if arena != null and arena.has_method("register_services"):
		arena.register_services(journal)
	if fete != null and fete.has_method("register_services"):
		fete.register_services(journal)
	_register_interactions()


func after_reply(r: Dictionary, npc: Node) -> void:
	if arena != null and arena.has_method("after_reply"):
		arena.after_reply(r, npc)
	if fete != null and fete.has_method("after_reply"):
		fete.after_reply(r, npc)


# =================================================================== les repaires

func _build_lairs() -> void:
	lairs.clear()
	for L in LAIRS:
		var c: Vector3 = IleScript.W((L[1] as Vector2).x, (L[1] as Vector2).y)
		c.y = ile.height(c.x, c.z)
		lairs.append({"id": str(L[0]), "c": c, "r": float(L[2]), "quand": str(L[3]), "respawn": float(L[4]), "list": L[5], "monsters": [], "dead_t": -1e15})


func _lairs_tick() -> void:
	var ms: Node = main.get("monstres_v36")
	if ms == null:
		return
	var p: Vector3 = main._player_pos_v27()
	var night: bool = hour() >= 20.0 or hour() < 5.5
	for L in lairs:
		var d: float = Vector2(p.x - L["c"].x, p.z - L["c"].z).length()
		var mons: Array = L["monsters"]
		var before: int = mons.size()
		mons = mons.filter(func(m): return is_instance_valid(m) and str(m.get("state")) != "mort")
		L["monsters"] = mons
		if before > 0 and mons.is_empty() and d < float(L["r"]) + 60.0:
			match str(L["id"]):
				"champ_lave":
					state["chiens"] = true
				"ruines":
					state["gargouilles"] = true
		var allowed: bool = str(L["quand"]) == "" or (str(L["quand"]) == "nuit" and night)
		if mons.is_empty() and allowed and d < float(L["r"]) and _now() - float(L["dead_t"]) > float(L["respawn"]):
			for e in L["list"]:
				var at: Vector3 = IleScript.W(float(e[1]), float(e[2]))
				at.y = ile.height(at.x, at.z) + 0.2
				var m: Node3D = ms.spawn_extra(str(e[0]), at)
				if m != null:
					m.set("home", at)
					m.set("state", "veille")
					mons.append(m)
			L["monsters"] = mons
			L["dead_t"] = _now()
		elif not mons.is_empty() and (d > float(L["r"]) + 60.0 or not allowed and d > float(L["r"]) + 10.0):
			for m2 in mons:
				if is_instance_valid(m2):
					m2.queue_free()
			L["monsters"] = []
			L["dead_t"] = -1e15


# =================================================================== la vie de l'île

func _process(delta: float) -> void:
	if main == null or ile == null:
		return
	var p: Vector3 = main._player_pos_v27()
	if not ile.contains(p.x, p.z):
		return
	if not bool(state["visite"]) and (ile.height(p.x, p.z) > -0.2 or on_structure(p)) and bool(main.get("game_started")):
		state["visite"] = true
		main._show_message_v28("L'Île de Braise — Pandémonia, la cité des démons (ils sont très gentils)")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	if city == null:
		return
	var pv: String = people_at(p)
	if pv == "cite" and not bool((state["visites"] as Dictionary).get("cite", false)):
		state["visites"]["cite"] = true
		main._show_message_v28("Pandémonia, la cité aux mille lanternes")
	_clock += delta
	_lair_t -= delta
	if _lair_t <= 0.0:
		_lair_t = 0.5
		_lairs_tick()
	_lava_t -= delta
	if _lava_t <= 0.0:
		_lava_t = 0.2
		_tick_lava(p)
	# la surface vue d'en dessous suit le plongeur (la mer de l'île est loin du centre du monde)
	var mer: Node = main.get("mer_v55")
	if mer != null and mer.get("_underside") != null:
		(mer._underside as Node3D).global_position = Vector3(snappedf(p.x, 40.0), (mer._underside as Node3D).global_position.y, snappedf(p.z, 40.0))
	_night_t -= delta
	if _night_t <= 0.0:
		_night_t = 2.0
		var h: float = hour()
		_night = h >= 19.0 or h < 6.0
		_tick_pepin()
	# les oriflammes, les chiots
	for i in range(city.kit.flags.size()):
		var fl: MeshInstance3D = city.kit.flags[i]
		var base: Transform3D = fl.get_meta("base")
		fl.transform = base * Transform3D(Basis(Vector3.UP, sin(_clock * 1.7 + i) * 0.2) * Basis(Vector3.RIGHT, sin(_clock * 2.9 + i * 2.0) * 0.05), Vector3.ZERO)
	for k in range(_puppies.size()):
		var pu: Node3D = _puppies[k]
		pu.rotation.y = float(pu.get_meta("yaw")) + sin(_clock * 0.7 + k * 2.0) * 0.6
		(pu.get_node("Queue") as Node3D).rotation.y = sin(_clock * 9.0 + k) * 0.6


## La lave brûle : on y perd deux cœurs, et l'on se retrouve au dernier endroit sûr.
func _tick_lava(p: Vector3) -> void:
	if main.get("boat_v29") != null and bool(main.boat_v29.get("driving")):
		return
	var ly: float = ile.lava_at(p.x, p.z)
	if ly > -1e9 and p.y < ly + 0.7 and p.y > ly - 6.0 and not on_structure(p):
		var back: Vector3 = _safe if _safe != Vector3.INF else respawn_point()[0]
		main.place_player_v35(back + Vector3.UP * 0.2, Vector3(0, 0, 1))
		var mo: Node = main.get("monstres_v36")
		if mo != null:
			mo.hurt_player(2, p + Vector3.UP)
		if main.has_method("sfx"):
			main.sfx("lave_gerbe", p)
		main._show_message_v28("Aïe ! La lave brûle ! (Les démons, eux, s'y baignent les pieds… pas toi.)")
		return
	# un endroit sûr : à au moins quatre mètres de toute lave
	var safe: bool = true
	for o in [Vector2(4, 0), Vector2(-4, 0), Vector2(0, 4), Vector2(0, -4)]:
		var l2: float = ile.lava_at(p.x + o.x, p.z + o.y)
		if l2 > -1e9 and p.y < l2 + 3.0:
			safe = false
	if safe and (ile.height(p.x, p.z) > -0.3 or on_structure(p)):
		_safe = p


func _make_smoke(at: Vector3, col: Color, scale_k: float = 1.0) -> CPUParticles3D:
	var s := CPUParticles3D.new()
	s.name = "Fumee"
	s.amount = 12
	s.lifetime = 5.0
	s.emitting = true
	s.direction = Vector3(0.2, 1, 0.1)
	s.spread = 12.0
	s.initial_velocity_min = 0.5
	s.initial_velocity_max = 0.9
	s.gravity = Vector3(0.2, 0.12, 0.05)
	s.scale_amount_min = 0.6 * scale_k
	s.scale_amount_max = 1.4 * scale_k
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.3))
	curve.add_point(Vector2(1.0, 1.6))
	s.scale_amount_curve = curve
	var qm := QuadMesh.new()
	qm.size = Vector2(0.9, 0.9)
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	qm.material = m
	s.mesh = qm
	s.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 12, 6))
	add_child(s)
	s.position = at
	return s


## Le panache du Grand Brasier : une fumée sombre qui monte du cratère, rougie par la lave.
func _make_plume() -> void:
	var c: Vector3 = IleScript.W(IleScript.VOLCANO.x, IleScript.VOLCANO.y, IleScript.CRATER_LAVA_Y + 3.0)
	var s := CPUParticles3D.new()
	s.name = "Panache_Grand_Brasier"
	s.amount = 40 if pc else 18
	s.lifetime = 16.0
	s.preprocess = 16.0
	s.emitting = true
	s.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	s.emission_sphere_radius = 8.0
	s.direction = Vector3(0, 1, 0)
	s.spread = 10.0
	s.initial_velocity_min = 2.4
	s.initial_velocity_max = 3.6
	s.gravity = Vector3(0.55, 0.05, 0.25)
	s.angular_velocity_min = -6.0
	s.angular_velocity_max = 6.0
	s.scale_amount_min = 0.8
	s.scale_amount_max = 1.3
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.35))
	curve.add_point(Vector2(0.4, 1.4))
	curve.add_point(Vector2(1.0, 2.8))
	s.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(0.45, 0.2, 0.12, 0.0))
	grad.set_color(1, Color(0.5, 0.48, 0.46, 0.0))
	grad.add_point(0.1, Color(0.42, 0.24, 0.16, 0.5))
	grad.add_point(0.6, Color(0.38, 0.36, 0.35, 0.3))
	s.color_ramp = grad
	var qm := QuadMesh.new()
	qm.size = Vector2(11.0, 11.0)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1, 1, 1, 1)
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	qm.material = m
	s.mesh = qm
	s.visibility_aabb = AABB(Vector3(-60, -10, -60), Vector3(160, 130, 120))
	add_child(s)
	s.position = c


## Un feu (flammes en particules et une lumière orangée).
func _make_fire(at: Vector3, s: float, on: bool) -> Node3D:
	var root := Node3D.new()
	root.name = "Feu"
	add_child(root)
	root.position = at
	var p := CPUParticles3D.new()
	p.amount = int(22 * s) + 8
	p.lifetime = 0.8
	p.direction = Vector3.UP
	p.spread = 15.0
	p.initial_velocity_min = 0.6 * s
	p.initial_velocity_max = 1.4 * s
	p.gravity = Vector3(0, 1.2, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.2 * s
	p.scale_amount_min = 0.5 * s
	p.scale_amount_max = 1.0 * s
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.85, 0.4, 1.0))
	grad.set_color(1, Color(0.9, 0.2, 0.05, 0.0))
	p.color_ramp = grad
	var qm := QuadMesh.new()
	qm.size = Vector2(0.35, 0.45)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	qm.material = m
	p.mesh = qm
	p.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 5, 4))
	root.add_child(p)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.25)
	l.light_energy = 1.5 * s
	l.omni_range = 6.0 * s + 2.0
	l.shadow_enabled = false
	l.position = Vector3.UP * 0.4
	l.distance_fade_enabled = true
	l.distance_fade_begin = 60.0
	l.distance_fade_length = 12.0
	root.add_child(l)
	root.visible = on
	return root


## Les chiots d'enfer du chenil de Flammèche : de petits chiens noirs aux cornes de bébé, aux
## yeux de braise ; ils remuent la queue.
func _build_puppies() -> void:
	var fur := StandardMaterial3D.new()
	fur.albedo_color = Color(0.08, 0.06, 0.06)
	fur.roughness = 0.9
	var horn := StandardMaterial3D.new()
	horn.albedo_color = Color(0.85, 0.78, 0.66)
	horn.roughness = 0.5
	var eye := StandardMaterial3D.new()
	eye.albedo_color = Color(1.0, 0.5, 0.1)
	eye.emission_enabled = true
	eye.emission = Color(1.0, 0.45, 0.1)
	eye.emission_energy_multiplier = 2.5
	for pp in city.basse.puppies:
		var root := Node3D.new()
		root.name = "Chiot_enfer"
		add_child(root)
		root.position = pp[0]
		root.set_meta("yaw", float(pp[1]))
		var parts := [[Vector3(0, 0.26, 0), Vector3(0.2, 0.18, 0.36), fur], [Vector3(0, 0.42, 0.24), Vector3(0.15, 0.14, 0.16), fur],
			[Vector3(0, 0.38, 0.36), Vector3(0.08, 0.06, 0.1), fur]]
		for p in parts:
			var mi := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.5
			sm.height = 1.0
			mi.mesh = sm
			mi.scale = p[1] * 2.0
			mi.position = p[0]
			mi.material_override = p[2]
			root.add_child(mi)
		for s in [-1.0, 1.0]:
			var leg := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.04
			cm.bottom_radius = 0.035
			cm.height = 0.2
			leg.mesh = cm
			leg.material_override = fur
			leg.position = Vector3(s * 0.1, 0.1, 0.18)
			root.add_child(leg)
			var leg2: MeshInstance3D = leg.duplicate()
			leg2.position = Vector3(s * 0.1, 0.1, -0.18)
			root.add_child(leg2)
			var h := MeshInstance3D.new()
			var hm := CylinderMesh.new()
			hm.top_radius = 0.0
			hm.bottom_radius = 0.025
			hm.height = 0.08
			h.mesh = hm
			h.material_override = horn
			h.position = Vector3(s * 0.06, 0.55, 0.24)
			h.rotation_degrees = Vector3(-20, 0, -s * 20)
			root.add_child(h)
			var e := MeshInstance3D.new()
			var em := SphereMesh.new()
			em.radius = 0.022
			em.height = 0.044
			e.mesh = em
			e.material_override = eye
			e.position = Vector3(s * 0.055, 0.45, 0.385)
			root.add_child(e)
		var tail := Node3D.new()
		tail.name = "Queue"
		tail.position = Vector3(0, 0.32, -0.34)
		root.add_child(tail)
		var tm := MeshInstance3D.new()
		var tc := CylinderMesh.new()
		tc.top_radius = 0.01
		tc.bottom_radius = 0.025
		tc.height = 0.28
		tm.mesh = tc
		tm.material_override = fur
		tm.position = Vector3(0, 0.08, -0.1)
		tm.rotation_degrees = Vector3(-55, 0, 0)
		tail.add_child(tm)
		_puppies.append(root)


# =================================================================== s'évanouir

func owns_point(p: Vector3) -> bool:
	if contains(p):
		return true
	return dungeon != null and dungeon.contains(p)


func on_faint(p: Vector3) -> void:
	if dungeon != null and dungeon.contains(p):
		dungeon.respawn()
		return
	if arena != null and arena.has_method("on_faint") and arena.on_faint(p):
		return
	var at: Array = respawn_point()
	main.place_player_v35(at[0], at[1])
	main._show_message_v28("Vous vous êtes évanoui… Des démons vous ont porté jusqu'à la Grand-Place, et Mère Brasille vous a fait boire un bouillon de piment. Ça réveille !")


# =================================================================== carnet, sauvegarde

func trouvailles() -> Dictionary:
	var ds: Dictionary = dungeon.state if dungeon != null else {}
	var t := {"braise": 1 if bool(state["visite"]) else 0, "pandemonia": 1 if bool((state["visites"] as Dictionary).get("cite", false)) else 0,
		"coeur_vif": 1 if bool(state["coeur"]) else 0, "porte_cercles": 1 if bool(state["porte"]) else 0,
		"cercles": 1 if bool(ds.get("fini", false)) else 0, "titan_givre": 1 if bool(ds.get("boss", false)) else 0,
		"chiens_champ": 1 if bool(state["chiens"]) else 0, "gargouilles_ruines": 1 if bool(state["gargouilles"]) else 0,
		"pepin_trouve": 1 if bool(state["pepin"]) else 0, "fusees_pretes": 1 if bool(state["fusees"]) else 0,
		"tournoi": 1 if bool(state["champion"]) else 0, "fete_lanternes": 1 if bool(state["fete"]) else 0,
		"sept_lanternes": 1 if (state["lanternes"] as Dictionary).size() >= 7 else 0,
		"miroirs_limbes": 1 if bool(ds.get("limbes", false)) else 0, "minos": 1 if bool(ds.get("minos", false)) else 0,
		"cerbere": 1 if bool(ds.get("cerbere", false)) else 0, "poids_avares": 1 if bool(ds.get("avares", false)) else 0,
		"porte_dite": 1 if bool(ds.get("dite", false)) else 0}
	if fete != null and fete.has_method("trouvailles"):
		t.merge(fete.trouvailles(), true)
	if arena != null and arena.has_method("trouvailles"):
		t.merge(arena.trouvailles(), true)
	if dehors != null and dehors.has_method("trouvailles"):
		t.merge(dehors.trouvailles(), true)
	return t


func serialize() -> Dictionary:
	var d: Dictionary = state.duplicate(true)
	if dungeon != null:
		d["donjon"] = dungeon.serialize()
	return d


func ensure_dungeon_at(p: Vector3) -> void:
	if dungeon != null and dungeon.near(p):
		dungeon.ensure_built()


func load_data(d: Dictionary) -> void:
	state = _fresh_state()
	for k in state:
		if d.has(k):
			state[k] = d[k] if not (d[k] is Dictionary) else (d[k] as Dictionary).duplicate(true)
	_claims.clear()
	if dungeon != null:
		var dd: Variant = d.get("donjon", {})
		dungeon.load_data(dd if dd is Dictionary else {})
	for L in lairs:
		for m in L["monsters"]:
			if is_instance_valid(m):
				m.queue_free()
		L["monsters"] = []
		L["dead_t"] = -1e15
	_apply_coeur()
	if fete != null and fete.has_method("apply_state"):
		fete.apply_state()
	if arena != null and arena.has_method("apply_state"):
		arena.apply_state()
	if dehors != null and dehors.has_method("apply_state"):
		dehors.apply_state()
