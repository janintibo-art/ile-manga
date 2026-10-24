extends Node
## V70 : la Nuit des Lanternes (la quête de Lumina, la lanternière). Sept Grandes Lanternes
## dans la cité (le port, le marché, l'arène, les thermes, l'Académie, la Cathédrale-Forge, la
## Grand-Place) attendent leur flamme : on les allume une à une avec la lanterne de braise de
## Lumina. Quand les sept brillent et que les fusées de Zigomar sont prêtes, la nuit venue
## (après 20 h), toute la cité vient danser sur la Grand-Place : la violoniste joue, les feux
## d'artifice éclatent, des centaines de lanternes montent dans le ciel.

const NAMES := {"port": "du Port de Cendre", "marche": "du Grand Marché", "arene": "de l'Arène des Cornes", "thermes": "des Thermes de Soufre",
	"academie": "de l'Académie Infernale", "forge": "de la Cathédrale-Forge", "place": "de la Grand-Place"}
const DURATION: float = 150.0
const COLORS := [Color(1.0, 0.35, 0.15), Color(1.0, 0.8, 0.25), Color(0.4, 0.7, 1.0), Color(0.75, 0.35, 1.0), Color(0.4, 1.0, 0.5), Color(1.0, 0.95, 0.85)]

var main: Node
var braise: Node
var lanterns: Dictionary = {}
var active: bool = false
var ctr := Vector3.ZERO
var _t: float = 0.0
var _check_t: float = 0.0
var _boom_t: float = 0.0
var _pool: Array = []
var _pool_i: int = 0
var _sky: CPUParticles3D
var _lit_mat: StandardMaterial3D
var _dark_mat: StandardMaterial3D
var _fires: Dictionary = {}
var _said_rockets: bool = false


func setup(main_node: Node, braise_node: Node) -> void:
	main = main_node
	braise = braise_node
	if braise.city == null:
		return
	lanterns = braise.city.lanterns
	var sp: Dictionary = braise.city.spots.get("place_fontaine", {})
	if not sp.is_empty():
		ctr = (sp["pos"] as Vector3) + braise.city.radial(0.0) * 4.3
	_lit_mat = StandardMaterial3D.new()
	_lit_mat.albedo_color = Color(1.0, 0.82, 0.5)
	_lit_mat.emission_enabled = true
	_lit_mat.emission = Color(1.0, 0.6, 0.25)
	_lit_mat.emission_energy_multiplier = 3.2
	_lit_mat.roughness = 0.2
	_dark_mat = StandardMaterial3D.new()
	_dark_mat.albedo_color = Color(0.12, 0.09, 0.08)
	_dark_mat.roughness = 0.15
	_dark_mat.metallic_specular = 0.8
	apply_state()


func _lit(k: String) -> bool:
	return bool((braise.state.get("lanternes", {}) as Dictionary).get(k, false))


func lit_count() -> int:
	var n: int = 0
	for k in lanterns:
		if _lit(str(k)):
			n += 1
	return n


## L'allure de chaque lanterne (allumée ou non).
func apply_state() -> void:
	for k in lanterns:
		var L: Dictionary = lanterns[k]
		var on: bool = _lit(str(k))
		var g: MeshInstance3D = L["glass"]
		if g != null:
			g.material_override = _lit_mat if on else _dark_mat
		var l: OmniLight3D = L["light"]
		if l != null:
			l.light_energy = 2.6 if on else 0.0
			l.distance_fade_enabled = true
			l.distance_fade_begin = 140.0
			l.distance_fade_length = 30.0
		if on and not _fires.has(k) and braise.has_method("_make_fire"):
			_fires[k] = braise._make_fire(L["flame"], 1.2, true)
		elif not on and _fires.has(k):
			(_fires[k] as Node3D).queue_free()
			_fires.erase(k)
	if active and not bool(braise.state.get("fete", false)):
		_end(false)


func register_interactions(d: Node) -> void:
	var me = self
	for k in lanterns:
		var kk: String = str(k)
		var L: Dictionary = lanterns[k]
		d._interactions.append({"id": "braise_lanterne_" + kk, "pos": (L["pos"] as Vector3) + Vector3.UP * 0.6, "radius": 2.8,
			"text": "E : allumer la Grande Lanterne " + str(NAMES.get(kk, "")), "vr": "Gâchette : allumer la Grande Lanterne",
			"call": func(): me._light(kk), "when": func(): return not me._lit(kk)})


func register_services(journal: Node) -> void:
	for k in lanterns:
		journal.lieux["grande_lanterne_" + str(k)] = lanterns[k]["pos"]
	journal.lieux["grand_place"] = ctr


func _light(k: String) -> void:
	var inv: Node = main.inventory_v28
	if inv.count("lanterne_braise") <= 0:
		braise._say("Une Grande Lanterne éteinte, aussi haute qu'un réverbère de géant. Pour l'allumer, il faudrait une flamme de braise vivante : Lumina, la lanternière, en garde dans sa lanterne.", 6.0)
		return
	if not braise.state.has("lanternes") or not (braise.state["lanternes"] is Dictionary):
		braise.state["lanternes"] = {}
	braise.state["lanternes"][k] = true
	apply_state()
	if main.has_method("sfx"):
		main.sfx("lanterne_allume", (lanterns[k]["pos"] as Vector3) + Vector3.UP * 6.0)
	var n: int = lit_count()
	if n < lanterns.size():
		braise._say("Tu tends la lanterne de braise vers la cage de fer : la flamme saute dedans, et la Grande Lanterne %s s'embrase d'or ! (%d sur %d)" % [str(NAMES.get(k, "")), n, lanterns.size()], 6.0)
	else:
		if main.has_method("jingle"):
			main.jingle("decouverte")
		braise._say("La septième Grande Lanterne s'allume ! D'un bout à l'autre, Pandémonia brille comme un collier de braises. Lumina va être folle de joie. Et la nuit venue, sur la Grand-Place… la fête !", 8.0)


func _fusees() -> bool:
	if bool(braise.state.get("fusees", false)):
		return true
	var j: Node = main.get("journal_v56")
	if j != null and str(j.state("br_artifice")) == "finie":
		braise.state["fusees"] = true
		return true
	return false


func _process(delta: float) -> void:
	if main == null or lanterns.is_empty():
		return
	if active:
		_tick_party(delta)
		return
	_check_t -= delta
	if _check_t > 0.0:
		return
	_check_t = 1.0
	if bool(braise.state.get("fete", false)) or lit_count() < lanterns.size():
		return
	var p: Vector3 = main._player_pos_v27()
	if Vector2(p.x - ctr.x, p.z - ctr.z).length() > 40.0:
		return
	var h: float = braise.hour()
	if not (h >= 20.0 or h < 3.0):
		return
	if not _fusees():
		if not _said_rockets:
			_said_rockets = true
			braise._say("Les sept Grandes Lanternes brillent sur la cité… mais Lumina secoue la tête : « Pas de Nuit des Lanternes sans les fusées de Zigomar ! Il lui manque ses cristaux de soufre, je crois. »", 8.0)
		return
	_start()


# =================================================================== la fête

func _start() -> void:
	active = true
	_t = 0.0
	_boom_t = 2.0
	braise._say("La cloche de la Cathédrale sonne douze coups… LA NUIT DES LANTERNES COMMENCE ! De toutes les rues, les démons arrivent sur la Grand-Place, en riant, en chantant. Calcine attaque une gigue endiablée.", 9.0)
	if main.has_method("sfx"):
		main.sfx("cloche_cathedrale", ctr + Vector3.UP * 20.0)
	# tout le monde sur la place : une ronde à deux cercles autour de la fontaine
	var i: int = 0
	var n: int = braise.habitants.size()
	for npc in braise.habitants:
		if not is_instance_valid(npc) or npc.has_meta("agenda_v70"):
			continue
		var id: String = str(npc.profile.get("id", ""))
		var spot_name: String = "place_musique" if id == "calcine" else "fete_%d" % i
		if id != "calcine":
			var ring: float = 7.0 if i % 2 == 0 else 10.5
			var a: float = TAU * float(i) / float(maxi(n, 1)) + (0.0 if i % 2 == 0 else 0.25)
			var pos: Vector3 = ctr + Vector3(cos(a) * ring, 0.05, sin(a) * ring)
			braise.city.spots[spot_name] = {"pos": pos, "face": ctr, "pose": "danse", "node": braise.city._nearest_point(pos)}
			i += 1
		npc.set_meta("agenda_fete", npc.agenda)
		npc.agenda = [[0, 24, spot_name]]
		npc.slot = -2
	# les lanternes qui s'envolent
	_sky = CPUParticles3D.new()
	_sky.name = "Lanternes_volantes"
	_sky.amount = 90 if braise.pc else 40
	_sky.lifetime = 24.0
	_sky.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_sky.emission_sphere_radius = 14.0
	_sky.direction = Vector3(0.15, 1, 0.05)
	_sky.spread = 12.0
	_sky.initial_velocity_min = 1.0
	_sky.initial_velocity_max = 1.8
	_sky.gravity = Vector3(0.12, 0.05, 0.04)
	_sky.scale_amount_min = 0.8
	_sky.scale_amount_max = 1.3
	var q := QuadMesh.new()
	q.size = Vector2(0.5, 0.65)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.7, 0.35)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.55, 0.2)
	m.emission_energy_multiplier = 3.0
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = m
	_sky.mesh = q
	_sky.visibility_aabb = AABB(Vector3(-60, -5, -60), Vector3(120, 160, 120))
	add_child(_sky)
	_sky.global_position = ctr + Vector3.UP * 3.0
	# la réserve de bouquets de feux d'artifice
	_pool.clear()
	for k in range(6):
		var b := CPUParticles3D.new()
		b.emitting = false
		b.one_shot = true
		b.amount = 90 if braise.pc else 50
		b.lifetime = 2.2
		b.explosiveness = 0.95
		b.direction = Vector3.UP
		b.spread = 180.0
		b.initial_velocity_min = 9.0
		b.initial_velocity_max = 13.0
		b.gravity = Vector3(0, -4.0, 0)
		b.damping_min = 2.0
		b.damping_max = 3.0
		b.scale_amount_min = 0.7
		b.scale_amount_max = 1.2
		var bq := QuadMesh.new()
		bq.size = Vector2(0.45, 0.45)
		var bm := StandardMaterial3D.new()
		bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		bm.vertex_color_use_as_albedo = true
		if main.has_method("_soft_dot_v24"):
			bm.albedo_texture = main._soft_dot_v24()
		bq.material = bm
		b.mesh = bq
		b.visibility_aabb = AABB(Vector3(-30, -30, -30), Vector3(60, 60, 60))
		var l := OmniLight3D.new()
		l.omni_range = 60.0
		l.light_energy = 0.0
		l.shadow_enabled = false
		b.add_child(l)
		add_child(b)
		_pool.append(b)


func _tick_party(delta: float) -> void:
	_t += delta
	_boom_t -= delta
	if _boom_t <= 0.0 and _t < DURATION - 6.0:
		_boom_t = randf_range(0.6, 1.6)
		_burst()
	for b in _pool:
		var l: OmniLight3D = (b as Node).get_child(0)
		l.light_energy = maxf(l.light_energy - delta * 3.0, 0.0)
	var p: Vector3 = main._player_pos_v27()
	var far: bool = Vector2(p.x - ctr.x, p.z - ctr.z).length() > 140.0
	if _t > DURATION or far:
		_end(true)


func _burst() -> void:
	var b: CPUParticles3D = _pool[_pool_i % _pool.size()]
	_pool_i += 1
	var c: Color = COLORS[randi() % COLORS.size()]
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.add_point(0.15, c)
	grad.set_color(1, Color(c.r, c.g, c.b, 0.0))
	b.color_ramp = grad
	b.global_position = ctr + Vector3(randf_range(-30, 30), randf_range(38, 58), randf_range(-30, 30))
	var l: OmniLight3D = b.get_child(0)
	l.light_color = c
	l.light_energy = 6.0
	b.restart()
	b.emitting = true
	if main.has_method("sfx"):
		if randf() < 0.5:
			main.sfx("artifice_depart", ctr + Vector3(randf_range(-10, 10), 2.0, randf_range(-10, 10)))
		main.sfx("artifice_eclat", b.global_position)


func _end(done: bool) -> void:
	active = false
	if done:
		braise.state["fete"] = true
	for npc in braise.habitants:
		if is_instance_valid(npc) and npc.has_meta("agenda_fete"):
			npc.agenda = npc.get_meta("agenda_fete")
			npc.remove_meta("agenda_fete")
			npc.slot = -2
	for k in braise.city.spots.keys():
		if str(k).begins_with("fete_"):
			braise.city.spots.erase(k)
	if _sky != null:
		_sky.emitting = false
		var s: Node = _sky
		get_tree().create_timer(25.0).timeout.connect(func(): if is_instance_valid(s): s.queue_free())
		_sky = null
	for b in _pool:
		(b as Node).queue_free()
	_pool.clear()
	if done:
		if main.has_method("jingle"):
			main.jingle("victoire")
		braise._say("Les derniers feux s'éteignent dans le ciel, les lanternes volantes deviennent des étoiles. Lumina pleure de joie dans les bras de Bobor. « La plus belle Nuit des Lanternes depuis mille ans ! » (La fête, elle, continuera jusqu'à l'aube.)", 10.0)


func trouvailles() -> Dictionary:
	return {"sept_lanternes": 1 if lit_count() >= lanterns.size() and not lanterns.is_empty() else 0, "fete_lanternes": 1 if bool(braise.state.get("fete", false)) else 0}


func after_reply(_r: Dictionary, _npc: Node) -> void:
	pass
