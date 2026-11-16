extends SceneTree
## Des images d'une île seule (V159), pour juger l'effet (lancé par tests/outils/rendu_iles.sh) :
##   elfes     le Bois-Doré (le ponton, le sentier de lanternes, la place, les arbres-maisons)
##   nains     la Montagne de Feu (la côte, les orgues de basalte, la terrasse de Forgefer, le cratère)
##   forgefer  la Grande Halle de Forgefer, sous la montagne
##   moai      l'Île aux Moaïs (les trois volcans, le lac du cratère, la plage, le Grand Moaï)


class FakeDonjon:
	extends Node
	var _interactions: Array = []
	var spawn: Dictionary = {}

	func _fire(_a: Variant, _b: Variant = null, _c: Variant = null, _d: Variant = null) -> void:
		pass


class FakeMain:
	extends Node3D
	var xr_active: bool = false
	var cam: Camera3D
	var ile_node: Node = null
	var npcs_v31: Array = []
	var pending_pnj_v31: Dictionary = {}
	var game_started: bool = false
	var temps_v56: Node
	var donjon_v35: Node = null
	var inventory_v28: Node = null
	var dialogue_v31: Node = null
	var combat_v28: Node = null
	var boat_v29: Node = null
	var ciel_v54: Node = null
	var hero_v28: Node = null
	var monstres_v36: Node = null
	var sfx_v50: Node = null
	var flora_v30: Node = null
	var jungle_v29: Node = null
	var ROOMS_V27: Array = []

	func _player_pos_v27() -> Vector3:
		return cam.global_position - Vector3.UP * 1.6 if cam != null else Vector3.ZERO

	func _height_at(x: float, z: float) -> float:
		if ile_node != null and ile_node.has_method("height"):
			return ile_node.height(x, z)
		return -5.0

	func _npc_ctx_v31() -> Dictionary:
		return {"now": 0.0, "objets": {}, "vr": false}

	func sfx(_n: String, _at: Variant = null, _db: float = 0.0) -> void:
		pass

	func jingle(_n: String) -> void:
		pass

	func _show_message_v28(_t: String) -> void:
		pass

	func place_player_v35(at: Vector3, facing: Vector3) -> void:
		pass

	func _soft_dot_v24() -> GradientTexture2D:
		var grad := Gradient.new()
		grad.set_color(0, Color(1, 1, 1, 1))
		grad.set_color(1, Color(1, 1, 1, 0))
		var tex := GradientTexture2D.new()
		tex.gradient = grad
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(0.5, 0.0)
		tex.width = 64
		tex.height = 64
		return tex


class FakeTemps:
	extends Node
	var hour: float = 10.0
	var day_count: int = 3
	var lamps_on: bool = false

	func register_glow(_m: Variant, _a: Variant = null, _b: Variant = null) -> void:
		pass

	func register_lamp(_l: Variant, _e: Variant = null) -> void:
		pass


var out: String = ""
var cam: Camera3D
var fm: FakeMain
var sun: DirectionalLight3D
var env: Environment


func _initialize() -> void:
	out = str(OS.get_cmdline_user_args()[0])
	var quoi: String = str(OS.get_cmdline_user_args()[1]) if OS.get_cmdline_user_args().size() > 1 else "elfes"
	_monde()
	fm = FakeMain.new()
	root.add_child(fm)
	var tp := FakeTemps.new()
	fm.add_child(tp)
	fm.temps_v56 = tp
	var dj := FakeDonjon.new()
	fm.add_child(dj)
	fm.donjon_v35 = dj
	cam = Camera3D.new()
	cam.fov = 64.0
	cam.far = 3000.0
	cam.near = 0.08
	root.add_child(cam)
	cam.current = true
	fm.cam = cam
	for k in range(4):
		await process_frame
	match quoi:
		"elfes", "village":
			await _elfes(quoi == "village")
		"nains", "forgefer":
			await _nains(quoi == "forgefer")
		"moai":
			await _moai()
	quit()


# =================================================================== le Bois-Doré

func _elfes(sans_foret: bool = false) -> void:
	var E: Node3D = load("res://scripts/elfes_v41.gd").new()
	fm.add_child(E)
	E.setup(fm)
	E.pc = true
	E.build_island()
	fm.ile_node = E.ile
	_mer(E.ile.CENTER)
	if sans_foret:
		E.flora.visible = false
	for k in range(10):
		await process_frame
	var G: Vector3 = E.ile.glade_world()
	var ds: Vector3 = E.ile.dock_start
	var de: Vector3 = E.ile.dock_end
	await _vue("01_arrivee", de + (de - ds).normalized() * 6.0 + Vector3.UP * 3.0, G + Vector3.UP * 10.0)
	var to_g: Vector3 = (G - ds) * Vector3(1, 0, 1)
	var p1: Vector3 = ds + to_g * 0.35
	await _vue("02_sentier", _sol(p1) + Vector3.UP * 1.7, G + Vector3.UP * 4.0)
	var p2: Vector3 = G - to_g.normalized() * 16.0
	await _vue("03_place", _sol(p2) + Vector3.UP * 1.7, G + Vector3.UP * 5.0)
	await _vue("04_place_dessus", G - to_g.normalized() * 30.0 + Vector3.UP * 26.0, G)
	var t0: Dictionary = E.tree_spots[0]
	var tp: Vector3 = t0["pos"]
	var a: float = float(t0["angle"])
	var near: Vector3 = tp + Vector3(cos(a + PI) * 13.0, 0, sin(a + PI) * 13.0)
	await _vue("05_arbre_maison", _sol(near) + Vector3.UP * 1.7, tp + Vector3.UP * 9.5)
	var plat: Vector3 = tp + Vector3(cos(a + PI) * 5.5, E.PLATFORM_H + 1.7, sin(a + PI) * 5.5)
	plat.y = tp.y + E.PLATFORM_H + 1.7
	var hc: Vector3 = tp + Vector3(cos(a) * 4.7, E.PLATFORM_H, sin(a) * 4.7)
	var cote: Vector3 = Vector3(cos(a + PI * 0.5), 0, sin(a + PI * 0.5))
	await _vue("06_plateforme", tp + cote * 5.4 + Vector3(cos(a), 0, sin(a)) * 1.5 + Vector3.UP * (E.PLATFORM_H + 1.7), hc + Vector3.UP * 2.4)
	var t1: Dictionary = E.tree_spots[1]
	var mid: Vector3 = (tp + (t1["pos"] as Vector3)) * 0.5 + Vector3.UP * (E.PLATFORM_H + 1.0)
	await _vue("07_passerelle", tp + Vector3.UP * (E.PLATFORM_H + 1.7) + ((t1["pos"] as Vector3) - tp).normalized() * 6.0, mid + Vector3.DOWN * 0.5)
	await _vue("08_fontaine", G + Vector3(4.0, 0, 18.0) + Vector3.UP * (_sol(G + Vector3(4.0, 0, 18.0)).y - G.y + 1.7), G + Vector3(0, 1.0, 13.5))
	await _vue("09_ile", E.ile.CENTER + Vector3(-200, 90, 60), E.ile.CENTER + Vector3(0, 10, 0))
	await _vue("10_foret", _sol(E.ile.CENTER + Vector3(40, 0, 50)) + Vector3.UP * 1.7, E.ile.CENTER + Vector3(60, 8, 80))


# =================================================================== la Montagne de Feu, Forgefer

func _nains(dedans: bool) -> void:
	var N: Node3D = load("res://scripts/nains_v46.gd").new()
	fm.add_child(N)
	N.setup(fm)
	N.pc = true
	N.build_island()
	fm.ile_node = N.ile
	_mer(N.ile.CENTER)
	for k in range(10):
		await process_frame
	if dedans:
		var F: Node3D = load("res://scripts/forgefer_v47.gd").new()
		N.add_child(F)
		F.setup(N)
		F.sondes = false
		F.build()
		N.forgefer = F
		env.fog_enabled = false
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.02, 0.015, 0.012)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.32, 0.24, 0.2)
		env.ambient_light_energy = 0.5
		sun.visible = false
		for k2 in range(10):
			await process_frame
		var S: Node3D = F.s
		var L := func(x: float, y: float, z: float) -> Vector3: return S.to_global(Vector3(x, y, z))
		await _vue("21_entree", L.call(0, 1.7, 24.0), L.call(0, 3.0, -10.0))
		await _vue("22_nef", L.call(-4.0, 2.5, 16.0), L.call(2.0, 4.0, -20.0))
		await _vue("23_trone", L.call(0, 1.8, -6.0), L.call(0, 3.0, -22.0))
		await _vue("24_forge_royale", L.call(10.0, 1.8, 4.0), L.call(22.0, 1.5, -4.0))
		await _vue("25_taverne", L.call(-10.0, 1.8, 4.0), L.call(-22.0, 1.5, 4.0))
		await _vue("26_piliers", L.call(-7.0, 1.7, 14.0), L.call(-9.0, 8.0, -16.0))
		await _vue("27_dessus", L.call(0, 12.5, 24.0), L.call(0, 0, -6.0))
		return
	var C: Vector3 = N.ile.CENTER
	var T: Vector3 = N.ile.terrace
	var top: Vector3 = N.ile.peak_world()
	var ds: Vector3 = N.ile.dock_start
	var de: Vector3 = N.ile.dock_end
	await _vue("11_arrivee", de + (de - ds).normalized() * 6.0 + Vector3.UP * 3.0, top)
	var td: Vector3 = (T - C) * Vector3(1, 0, 1)
	await _vue("12_terrasse", _sol(T + td.normalized() * 14.0) + Vector3.UP * 1.7, T + Vector3.UP * 4.0 - td.normalized() * 8.0)
	await _vue("13_porte", N.gate_front + (N.gate_front - top) * Vector3(1, 0, 1).normalized() * 0.0 + td.normalized() * 6.0 + Vector3.UP * 1.7, N.gate_front + Vector3.UP * 4.0)
	await _vue("14_pente", _sol(C + Vector3(30, 0, 50)) + Vector3.UP * 1.7, top + Vector3.DOWN * 10.0)
	await _vue("15_cratere", top + Vector3(N.ile.CRATER_R + 4.0, 10.0, 6.0), top)
	await _vue("16_ile", C + Vector3(220, 120, 80), C + Vector3(-10, 25, 0))
	await _vue("17_cote", _sol(C + Vector3(-60, 0, 95)) + Vector3.UP * 1.7, C + Vector3(-20, 15, 0))
	var og: Node = N.get_node_or_null("Orgues_de_basalte_v159")
	if og != null:
		var o0: Vector3 = (og as MultiMeshInstance3D).multimesh.get_instance_transform(0).origin
		var dirc: Vector3 = ((o0 - C) * Vector3(1, 0, 1)).normalized()
		await _vue("18_orgues", _sol(o0 + dirc * 9.0 + dirc.cross(Vector3.UP) * 3.0) + Vector3.UP * 1.7, o0 + Vector3.UP * 1.5)
	else:
		await _vue("18_orgues", _sol(C + Vector3(70, 0, -40)) + Vector3.UP * 1.7, C + Vector3(30, 10, -60))
	var fa: Node3D = N.forge_root.get_node("Grande_porte")
	await _vue("19_statue", fa.to_global(Vector3(3.5, 2.2, 9.5)), fa.to_global(Vector3(8.0, 5.2, 0.8)))
	await _vue("20_statue_pres", fa.to_global(Vector3(6.0, 3.0, 5.0)), fa.to_global(Vector3(8.0, 7.0, 0.8)))


# =================================================================== l'Île aux Moaïs

func _moai() -> void:
	var M: Node3D = load("res://scripts/moai_v87.gd").new()
	fm.add_child(M)
	M.setup(fm)
	M.pc = true
	M.build_island()
	fm.ile_node = M.ile
	M.build_town()
	_mer(M.ile.CENTER)
	for k in range(10):
		await process_frame
	var I = load("res://scripts/ile_moai_v87.gd")
	var C: Vector3 = I.CENTER
	var lac: Array = I.VOLCANS["lac"]
	var ven: Array = I.VOLCANS["venteux"]
	var car: Array = I.VOLCANS["carriere"]
	await _vue("31_ile", C + Vector3(-60, 160, 330), C)
	await _vue("32_plage", _w(I, 6, 92) + Vector3.UP * 1.7, _w(I, 0, 0) + Vector3.UP * 12.0)
	await _vue("33_lac_bord", _w(I, -96, 24) + Vector3.UP * 1.7, I.W(float(lac[0]), float(lac[1]), I.LAC_Y))
	await _vue("33b_lac_pres", I.W(float(lac[0]) + 12.0, float(lac[1]) + 14.0, I.LAC_Y + 7.0), I.W(float(lac[0]) - 4.0, float(lac[1]) - 4.0, I.LAC_Y))
	await _vue("34_lac_cratere", I.W(float(lac[0]) + 30.0, float(lac[1]) + 10.0, I.LAC_Y + 22.0), I.W(float(lac[0]), float(lac[1]), I.LAC_Y))
	await _vue("35_volcan_lac", _w(I, -40, 40) + Vector3.UP * 1.7, I.W(float(lac[0]), float(lac[1]), 18.0))
	await _vue("36_venteux", _w(I, 0, -60) + Vector3.UP * 1.7, I.W(float(ven[0]), float(ven[1]), 18.0))
	await _vue("37_venteux_sommet", I.W(float(ven[0]), float(ven[1]) + 12.0, 0) * Vector3(1, 0, 1) + Vector3.UP * (M.ile.height(I.W(float(ven[0]), float(ven[1]) + 12.0, 0).x, I.W(float(ven[0]), float(ven[1]) + 12.0, 0).z) + 1.7), I.W(float(ven[0]), float(ven[1]) - 40.0, 5.0))
	await _vue("38_carriere", _w(I, 60, 40) + Vector3.UP * 1.7, I.W(float(car[0]), float(car[1]), 10.0))
	await _vue("39_grand_moai", _w(I, 0, 30) + Vector3.UP * 1.7, _w(I, 0, -4) + Vector3.UP * 15.0)
	await _vue("40_falaises", I.W(-170.0, 60.0, 4.0), _w(I, -120, 40) + Vector3.UP * 4.0)


func _w(I, x: float, z: float) -> Vector3:
	var w: Vector3 = I.W(x, z)
	w.y = fm._height_at(w.x, w.z)
	return w


# =================================================================== outils

func _sol(p: Vector3) -> Vector3:
	return Vector3(p.x, fm._height_at(p.x, p.z), p.z)


func _vue(nom: String, at: Vector3, look: Vector3, images: int = 3) -> void:
	cam.global_position = at
	if (look - at).length() > 0.01:
		cam.look_at(look)
	for k in range(images):
		await process_frame
	root.get_texture().get_image().save_png("%s/%s.png" % [out, nom])
	print("RENDU ", nom)


func _mer(c: Vector3) -> void:
	var sea := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(3000, 3000)
	sea.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.1, 0.32, 0.46)
	m.roughness = 0.15
	sea.material_override = m
	root.add_child(sea)
	sea.position = c + Vector3(0, -0.42, 0)


func _monde() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.32, 0.52, 0.82)
	sm.sky_horizon_color = Color(0.7, 0.8, 0.9)
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.0
	env.fog_enabled = true
	env.fog_density = 0.0008
	env.fog_light_color = Color(0.7, 0.78, 0.86)
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-46, -35, 0)
	sun.shadow_enabled = true
	sun.light_energy = 1.25
	sun.directional_shadow_max_distance = 300.0
	root.add_child(sun)
