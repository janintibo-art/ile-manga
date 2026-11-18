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

	func _fire(_a: Variant, _b: Variant = null, _c: Variant = null, _d: Variant = null) -> CPUParticles3D:
		# V167 : comme le vrai donjon, une particule de feu accrochée au parent (Larsen nomme la sienne)
		var p := CPUParticles3D.new()
		p.emitting = false
		if _a is Node3D:
			(_a as Node3D).add_child(p)
			if _b is Vector3:
				p.position = _b
		return p


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
	var nains_v46: Node = null
	var hero_v28: Node = null
	var monstres_v36: Node = null
	var sfx_v50: Node = null
	var flora_v30: Node = null
	var jungle_v29: Node = null
	var ROOMS_V27: Array = []
	var pc_root: Node3D = null

	func _player_pos_v27() -> Vector3:
		return cam.global_position - Vector3.UP * 1.6 if cam != null else Vector3.ZERO

	var sol_plat: bool = false

	func _height_at(x: float, z: float) -> float:
		if sol_plat:
			return 0.0
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
	fm.pc_root = cam
	for k in range(4):
		await process_frame
	match quoi:
		"elfes", "village":
			await _elfes(quoi == "village")
		"nains", "forgefer":
			await _nains(quoi == "forgefer")
		"moai":
			await _moai()
		"nuees", "strates", "dome", "nuees_mur", "strates_four", "dome_v160":
			await _hautefond(quoi)
		"celeste":
			await _celeste()
		"jungle", "jungle_piton":
			await _jungle(quoi == "jungle_piton")
		"azur":
			await _azur()
		"fees":
			await _fees()
		"teuf":
			await _teuf()
		"facade":
			await _facade()
		"carene", "tazira", "cliquetis", "ramure":
			await _grande(quoi)
		"porte":
			await _porte()
		"arcanelle", "coutelas", "soleils", "pandemonia", "montjoie", "boucan", "astralys", "pixel", "larsen", "pasta", "crayon", "sombreval":
			await _systeme(quoi)
		"carene_hd", "tazira_hd", "cliquetis_hd", "ramure_hd":
			await _grande(quoi.trim_suffix("_hd"), true)
		"atlantide":
			await _atlantide()
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


# =================================================================== Port-Azur, le royaume des fées, la teuf (V163)

func _azur() -> void:
	var Az: Node3D = load("res://scripts/azur_v56.gd").new()
	fm.add_child(Az)
	Az.setup(fm)
	Az.pc = true
	Az.build_island()
	fm.ile_node = Az.ile
	Az.build_town()
	for k in range(6):
		await process_frame
	await physics_frame
	var I: Node3D = Az.ile
	_mer(Vector3(I.CENTER.x, 0.0, I.CENTER.z))
	var P: Node3D = Az.port
	await _vue("101_quai", P.T(4.0, 3.0, 1.7), P.T(0.0, 30.0, 6.0))
	await _vue("109_fenetres", P.T(13.0, 3.5, 4.2), P.T(10.0, 10.0, 6.0))
	await _vue("110_facade", P.T(-22.0, 4.0, 1.7), P.T(-27.0, 10.0, 3.0))
	await _vue("102_front_de_mer", P.T(-30.0, 6.0, 1.7), P.T(10.0, 14.0, 5.0))
	await _vue("103_place", P.T(-8.0, 36.0, 1.7), P.T(0.0, 55.0, 4.0))
	await _vue("104_hotel", P.T(-40.0, 4.0, 1.7), P.T(-60.0, 24.0, 8.0))
	await _vue("105_plage", P.T(-80.0, 2.0, 1.7), P.T(-55.0, 18.0, 2.0))
	await _vue("106_phare", P.T(55.0, 2.0, 1.7), P.T(80.0, -10.0, 14.0))
	await _vue("107_ruelle", P.T(10.0, 50.0, 1.7), P.T(20.0, 70.0, 4.0))
	await _vue("108_dessus", I.CENTER + Vector3(170, 130, 170), I.CENTER + Vector3(0, 10, 0))
	# le soir : les fenêtres allumées
	var fk: Material = P.kit.mats.get("fenetre_nuit")
	if fk is ShaderMaterial:
		(fk as ShaderMaterial).set_shader_parameter("glow", 1.6)
	_nuit()
	await _vue("10d_soir_fenetres", P.T(13.0, 3.5, 4.2), P.T(10.0, 10.0, 6.0))
	await _vue("10e_soir_place", P.T(-8.0, 36.0, 1.7), P.T(0.0, 55.0, 4.0))


## La Grande Île (V164) : le relief, la porte aux Quatre Sceaux, la végétation et une seule ville
## (Carène, Tazira, Cliquetis ou Ramure). Les vues : de haut, la porte, puis devant les lieux
## d'activité des habitants (les étals, les comptoirs, les ateliers), comme un passant les voit.
## V165 : une île et ses villes (Arcanelle ; Port-Coutelas ; Per-Hâpy, Yaxché, Aztlán ; V166 : Pandémonia,
## Montjoie, Port-Boucan) : de haut, puis
## devant les lieux d'activité des habitants.
func _systeme(nom: String) -> void:
	var scr: String = {"arcanelle": "res://scripts/arcanelle_v67.gd", "coutelas": "res://scripts/pirates_v68.gd", "soleils": "res://scripts/soleils_v69.gd",
		"pandemonia": "res://scripts/braise_v70.gd", "montjoie": "res://scripts/montjoie_v71.gd", "boucan": "res://scripts/boucan_v75.gd",
		"astralys": "res://scripts/astrale_v76.gd", "pixel": "res://scripts/pixel_v90.gd", "larsen": "res://scripts/larsen_v91.gd",
		"pasta": "res://scripts/pasta_v97.gd", "crayon": "res://scripts/crayon_v99.gd", "sombreval": "res://scripts/sombreval_v121.gd"}[nom]
	var Sy: Node3D = load(scr).new()
	fm.add_child(Sy)
	Sy.setup(fm)
	Sy.pc = true
	Sy.build_island()
	fm.ile_node = Sy.ile
	Sy.build_town()
	for k in range(6):
		await process_frame
	await physics_frame
	var villes: Array = []
	match nom:
		"arcanelle":
			villes = [Sy.bourg]
		"coutelas":
			villes = [Sy.port]
		"soleils":
			villes = [Sy.egypte, Sy.maya, Sy.azteque]
		"pandemonia", "montjoie", "boucan", "astralys":
			villes = [Sy.city]
		"larsen", "pasta":
			villes = [Sy.ville]
	var c: Vector3 = Sy.ile.CENTER
	c.y = fm._height_at(c.x, c.z)
	_mer(c)
	await _vue("141_dessus", c + Vector3(170, 140, 170), c)
	var par: int = 6 / maxi(villes.size(), 1)
	var k2: int = 0
	# des lieux choisis (les Trois Soleils : le four et les jarres, le potier ; le metate, le jeu de balle ;
	# la place, le potier d'Aztlán ; V166 : les places, les marchés, les fontaines)
	var choix: Dictionary = {"soleils": [["four", "potier"], ["metate", "balle_2"], ["place_a2", "potier_az"]],
		"pandemonia": [["marche_flane_1", "place_fontaine", "place_lanterne", "forge_coeur", "port_quai_1", "jardin_banc"]],
		"montjoie": [["place_fontaine", "marche_fruits", "lavoir_1", "puits", "forge_enclume", "chaumiere_jardin"]],
		"boucan": [["place_fontaine", "place_banc_1", "jardins_1", "mur_expression_1", "conserverie_assemblee", "cantine_comptoir"]],
		"astralys": [["agora_fontaine", "cafe_comptoir", "jardins_1", "observatoire_telescope", "spatioport_aire_1", "bulles_no_1"]],
		"larsen": [["arbre_rubans", "tissage", "garage_chant", "cafe_terrasse_1", "disquaire_1", "scene_1"]],
		"pasta": [["four", "piazza_banc_1", "piazza_violon", "sechoir_1", "tomates_1", "oliviers"]]}
	# V167 : l'Île Pixelithique n'a pas de rues : des vues choisies (repère île : d'où, vers où)
	var vues_ile: Dictionary = {
		"pixel": [["150_camp", Vector2(-36, 20), Vector2(-50, 5)], ["151_falaises", Vector2(-52, 34), Vector2(-78, 6)], ["152_lac", Vector2(-18, 92), Vector2(-44, 76)],
			["153_plage", Vector2(34, 102), Vector2(22, 136)], ["154_cirque", Vector2(14, -98), Vector2(-8, -118)], ["155_volcan", Vector2(36, -36), Vector2(72, -72)]],
		# V168 : l'Île Crayonnée (la clairière et ses arbres-maisons, l'étang, le carrefour, la plage, le mont)
		"crayon": [["150_clairiere", Vector2(-20, 50), Vector2(-40, 34)], ["151_arbre", Vector2(-40, 34), Vector2(-62, 20)], ["152_etang", Vector2(48, -14), Vector2(32, -30)],
			["153_carrefour", Vector2(14, 110), Vector2(2, 98)], ["154_plage", Vector2(6, 120), Vector2(10, 151)], ["155_mont", Vector2(10, -40), Vector2(8, -80)]],
		# V168 : Sombreval (une rue, la place du marché, le cimetière, la gare, la jetée, le château)
		"sombreval": [["150_rue", Vector2(-100, -190), Vector2(-100, -110)], ["151_marche", Vector2(-12, -115), Vector2(-21, -125)], ["152_cimetiere", Vector2(116, 110), Vector2(130, 128)],
			["153_gare", Vector2(125, 3), Vector2(125, -25)], ["154_port", Vector2(0, -246), Vector2(0, -190)], ["155_chateau", Vector2(-34, 24), Vector2(0, 0)]],
	}
	if vues_ile.has(nom):
		var vp: Array = vues_ile[nom]
		for v in vp:
			var a: Vector3 = Sy.ile.W((v[1] as Vector2).x, (v[1] as Vector2).y)
			var b: Vector3 = Sy.ile.W((v[2] as Vector2).x, (v[2] as Vector2).y)
			a.y = fm._height_at(a.x, a.z) + 1.7
			b.y = fm._height_at(b.x, b.z) + 1.0
			await _vue(str(v[0]), a, b)
		await _portes173(nom)
		return
	var iv: int = 0
	for V in villes:
		var noms: Array = V.spots.keys()
		noms.sort()
		var pas: int = maxi(1, noms.size() / par)
		if choix.has(nom):
			noms = choix[nom][iv]
			pas = 1
		iv += 1
		var n: int = 0
		for i in range(0, noms.size(), pas):
			if n >= par:
				break
			if not V.spots.has(noms[i]):
				continue
			var sp: Dictionary = V.spots[noms[i]]
			var pos: Vector3 = sp["pos"]
			var face: Vector3 = sp["face"]
			var d := Vector3(face.x - pos.x, 0, face.z - pos.z)
			if face.length() < 1.5:
				# (une direction, pas un point visé)
				d = Vector3(face.x, 0, face.z)
			if d.length() < 0.1:
				d = Vector3(0, 0, 1)
			d = d.normalized()
			await _vue("15%d_%s" % [k2, str(noms[i]).substr(0, 18)], pos - d * 3.2 + Vector3.UP * 1.65, pos + d * 6.0 + Vector3.UP * 1.3)
			n += 1
			k2 += 1
	await _portes173(nom)


## V173 : les portes des lieux de lieux_v173 de cette île (de face, un peu de côté).
func _portes173(nom: String) -> void:
	# (V175 : et les portes des bus peints de l'Île de Larsen)
	var st: String = {"celeste": "citadelle", "montjoie": "montjoie", "astralys": "astralys", "sombreval": "sombreval", "larsen": "larsen"}.get(nom, "")
	if st == "":
		return
	var Kit56 = load("res://scripts/azur_kit_v56.gd")
	var n: int = 0
	for e in Kit56.PORTES_V81:
		if not (str(e.get("histoire", "")) in ["b173", "b175"]) or str(e.get("style", "")) != st:
			continue
		var dp: Vector3 = e["door"]
		var o: Vector3 = e["out"]
		var sd: Vector3 = o.cross(Vector3.UP)
		var loin: float = 4.0 if st == "astralys" else 6.5
		await _vue("173%d_%s" % [n, str(e.get("metier", ""))], dp + o * loin + sd * 1.5 + Vector3.UP * 1.8, dp - o * 1.5 + Vector3.UP * 1.6)
		n += 1


## La Porte aux Quatre Sceaux seule (V164) : le relief de la Grande Île, sans les villes.
func _porte() -> void:
	var G: Node3D = load("res://scripts/grande_v59.gd").new()
	G.name = "Grande_v59"
	fm.add_child(G)
	G.setup(fm)
	G.pc = true
	G.build_island()
	fm.ile_node = G.ile
	for k in range(4):
		await process_frame
	var dp: Vector3 = G.ile.door_pos
	var gx: Transform3D = G.ile.door_gate.global_transform
	_mer(dp)
	await _vue("161_porte_face", gx * Vector3(0, 2.0, 24.0), gx * Vector3(0, 9.0, 0))
	await _vue("162_porte_biais", gx * Vector3(-14, 1.8, 14.0), gx * Vector3(0, 8.0, 0))
	await _vue("163_vantail", gx * Vector3(3.0, 6.0, 7.0), gx * Vector3(-1.0, 9.0, 0))
	await _vue("164_brasero", gx * Vector3(-4.0, 2.2, 10.0), gx * Vector3(-7.6, 2.6, 5.5))
	await _vue("165_frise", gx * Vector3(0, 12.0, 14.0), gx * Vector3(0, 19.5, 0))
	_nuit()
	await _vue("166_porte_nuit", gx * Vector3(0, 2.0, 24.0), gx * Vector3(0, 9.0, 0))


func _grande(ville: String, hd: bool = false) -> void:
	var G: Node3D = load("res://scripts/grande_v59.gd").new()
	G.name = "Grande_v59"
	fm.add_child(G)
	G.setup(fm)
	G.pc = true
	G.build_island()
	fm.ile_node = G.ile
	var V: Node3D = null
	match ville:
		"carene":
			V = load("res://scripts/carene_v59.gd").new()
			V.name = "Carene_v59"
			G.add_child(V)
			G.carene = V
			V.build(fm, G.epave, G.ile, true)
		"tazira":
			V = load("res://scripts/tazira_v60.gd").new()
			V.name = "Tazira_v60"
			G.add_child(V)
			G.tazira = V
			V.build(fm, G.ile, true)
		"cliquetis":
			V = load("res://scripts/cliquetis_v61.gd").new()
			V.name = "Cliquetis_v61"
			G.add_child(V)
			G.cliquetis = V
			V.build(fm, G.ile, true)
		"ramure":
			V = load("res://scripts/ramure_v62.gd").new()
			V.name = "Ramure_v62"
			G.add_child(V)
			G.ramure = V
			V.build(fm, G.ile, true)
	if not hd:
		var fl: Node3D = load("res://scripts/grande_flore_v59.gd").new()
		fl.name = "Flore_grande_ile_v59"
		G.add_child(fl)
		G.flore = fl
		fl.build_island(G.ile, G.epave, true)
	for k in range(6):
		await process_frame
	await physics_frame
	var noms: Array = V.spots.keys()
	noms.sort()
	var c := Vector3.ZERO
	for n in noms:
		c += V.spots[n]["pos"]
	c /= maxf(1.0, float(noms.size()))
	_mer(c)
	if not hd:
		await _vue("141_dessus", c + Vector3(110, 85, 110), c)
	var dp: Vector3 = G.ile.door_pos
	if hd:
		await _vues_hd(ville, V)
		return
	if ville == "carene":
		await _vue("142_porte", dp + Vector3(-16, 2.0, 5), dp + Vector3(0, 5, 0))
	var pas: int = maxi(1, noms.size() / 6)
	var k2: int = 0
	for i in range(0, noms.size(), pas):
		if k2 >= 6:
			break
		var sp: Dictionary = V.spots[noms[i]]
		var pos: Vector3 = sp["pos"]
		var face: Vector3 = sp["face"]
		var d := Vector3(face.x - pos.x, 0, face.z - pos.z)
		if d.length() < 0.1:
			d = Vector3(0, 0, 1)
		d = d.normalized()
		await _vue("15%d_%s" % [k2, str(noms[i]).substr(0, 18)], pos - d * 3.2 + Vector3.UP * 1.65, pos + d * 6.0 + Vector3.UP * 1.3)
		k2 += 1


## V164 : les vues des nouveautés de chaque ville (devant des lieux nommés).
func _vues_hd(ville: String, V: Node3D) -> void:
	var noms: Array = []
	match ville:
		"carene":
			noms = ["tav_poele"]
		"tazira":
			noms = ["place_fontaine_1", "fondouk_terrasse_1", "fete_danse_4"]
		"ramure":
			noms = ["cercle_banc_6", "cercle_enfants_2", "jeux_enfants_1"]
		_:
			var ks: Array = V.spots.keys()
			ks.sort()
			noms = ks.slice(0, 3)
	var k2: int = 0
	for n in noms:
		if not V.spots.has(n):
			continue
		var sp: Dictionary = V.spots[n]
		var pos: Vector3 = sp["pos"]
		var face: Vector3 = sp["face"]
		var d := Vector3(face.x - pos.x, 0, face.z - pos.z)
		if d.length() < 0.1:
			d = Vector3(0, 0, 1)
		d = d.normalized()
		await _vue("17%d_%s" % [k2, str(n).substr(0, 18)], pos - d * 3.2 + Vector3.UP * 1.65, pos + d * 6.0 + Vector3.UP * 1.3)
		k2 += 1
	if ville == "cliquetis":
		var rp: Vector3 = V._rail_pts[0]
		var gp: Vector3 = rp - Vector3.UP * V.RAIL_H
		await _vue("175_monorail", gp + Vector3(6.0, 1.7, 5.0), rp + Vector3(0, -2.0, 0))
	if ville == "carene":
		var an: Transform3D = V.TW(47.0, -26.0, 30.0)
		await _vue("178_ancre", an * Vector3(3.5, 1.7, 3.0), an * Vector3(0, 1.4, 0))
		var fc: Transform3D = V.TW(44.0, -54.0)
		await _vue("179_feu", fc * Vector3(3.0, 1.5, 2.2), fc * Vector3(0, 0.3, 0))
		_nuit()
		var t: Node = fm.temps_v56
		t.lamps_on = true
		V._clock = 1.0
		if V.fire_flamme_v164 != null:
			V.fire_flamme_v164.set_shader_parameter("glow", 1.0)
			V.fire_mat.emission_energy_multiplier = 2.6
			V.fire_light.light_energy = 1.8
		await _vue("17a_feu_nuit", fc * Vector3(3.0, 1.5, 2.2), fc * Vector3(0, 0.3, 0))


## Trois façades de Port-Azur seules (V163) : pour voir de près l'enduit et les fenêtres, vite.
func _facade() -> void:
	fm.sol_plat = true
	var r3 := Node3D.new()
	root.add_child(r3)
	var kit = load("res://scripts/azur_kit_v56.gd").new()
	kit.hd_v163 = true
	kit.sol_v163 = 0.0
	kit.setup(r3, fm.temps_v56)
	kit.box(Transform3D(Basis(), Vector3(0, -0.05, 2.0)), Vector3(60, 0.1, 30), "dalles", 4.0, 4)
	var specs: Array = [
		{"w": 10.0, "floors": [3.6, 3.0, 3.0], "color": "rose", "volets": "bordeaux", "rdc": "porte", "balcons": [1], "pas_v81": true},
		{"w": 9.0, "floors": [3.6, 3.0, 3.0], "color": "jaune", "volets": "vert", "rdc": "boutique", "auvent": "turquoise"},
		{"w": 12.0, "floors": [3.6, 3.0], "color": "ocre", "volets": "bleu", "rdc": "porte", "pas_v81": true, "lit": 1.0},
	]
	var x: float = -11.0
	for sp in specs:
		kit.building(Transform3D(Basis(), Vector3(x, 0, 0)), sp)
		x += 10.6
	kit.commit()
	for k in range(4):
		await process_frame
	await _vue("131_facades", Vector3(0.0, 1.7, -13.0), Vector3(0.0, 4.5, 0.0))
	await _vue("132_fenetre", Vector3(-9.5, 5.0, -2.6), Vector3(-11.0, 5.0, 0.0))
	await _vue("133_rasant", Vector3(-17.0, 1.7, -3.0), Vector3(0.0, 4.0, 0.0))
	await _vue("134_rdc", Vector3(10.0, 1.6, -3.5), Vector3(10.6, 1.4, 0.0))
	var fk: Material = kit.mats.get("fenetre_nuit")
	if fk is ShaderMaterial:
		(fk as ShaderMaterial).set_shader_parameter("glow", 1.6)
	_nuit()
	await _vue("135_soir", Vector3(0.0, 1.7, -13.0), Vector3(0.0, 4.5, 0.0))
	await _vue("136_soir_fenetre", Vector3(9.0, 4.6, -2.8), Vector3(10.6, 4.8, 0.0))


func _fees() -> void:
	var Fe: Node3D = load("res://scripts/feerie_v58.gd").new()
	fm.add_child(Fe)
	Fe.setup(fm)
	Fe.pc = true
	Fe.build()
	fm.ile_node = Fe.ile
	for k in range(6):
		await process_frame
	await physics_frame
	var I: Node3D = Fe.ile
	var C: Vector3 = I.CENTER + Vector3.UP * I.Y0
	await _vue("111_prairie", I.world(Vector2(0, 40), 1.7), I.world(I.TREE, 20.0))
	await _vue("112_yggdrasil", I.world(Vector2(6, 8), 1.7), I.world(I.TREE, 26.0))
	await _vue("113_etang", I.world(I.POND + Vector2(11, 9), 1.7), I.world(I.POND, 0.0))
	await _vue("114_fleurs", I.world(Vector2(-30, 22), 1.4), I.world(Vector2(-48, 4), 2.0))
	await _vue("115_clairiere", I.world(Vector2(10, 50), 1.7), I.world(Vector2(-5, 62), 3.0))
	await _vue("116_dessous", C + Vector3(90, -80, 90), C + Vector3(0, -40, 0))
	await _vue("117_vue", C + Vector3(130, 60, 130), C + Vector3(0, 5, 0))
	await _vue("118_bord", I.world(Vector2(40, -30), 1.7), I.world(Vector2(80, -60), -30.0))


func _teuf() -> void:
	fm.sol_plat = true
	var sol := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 200)
	sol.mesh = pm
	var sm := StandardMaterial3D.new()
	sm.albedo_texture = load("res://assets/textures/terrain/sand.jpg")
	sm.albedo_color = Color(0.72, 0.66, 0.56)
	sm.uv1_scale = Vector3(40, 40, 1)
	sm.roughness = 0.95
	sol.material_override = sm
	root.add_child(sol)
	for g in [["Mur_de_son", Vector3(0, 3.75, 60), 6.0, PI], ["Table_de_mixage", Vector3(9, 0.988, 60), 2.5, 0.0], ["Distributeur_8_6", Vector3(-9, 1.712, 60), 1.8, PI]]:
		var ps: PackedScene = load("res://assets/models/props/%s.glb" % g[0])
		var n3: Node3D = ps.instantiate()
		n3.position = g[1]
		n3.scale = Vector3.ONE * float(g[2])
		n3.rotation.y = float(g[3])
		root.add_child(n3)
	var Tf: Node3D = load("res://scripts/teuf_v57.gd").new()
	fm.add_child(Tf)
	Tf.setup(fm)
	for k in range(6):
		await process_frame
	await _vue("121_piste", Vector3(3.0, 1.7, 38.0), Vector3(1.0, 3.0, 60.0))
	await _vue("122_mur", Vector3(-6.0, 1.7, 51.0), Vector3(0.0, 3.0, 60.0))
	await _vue("123_platines", Vector3(12.5, 2.2, 55.5), Vector3(9.0, 1.0, 60.0))
	await _vue("124_estrade", Vector3(18.0, 1.7, 64.0), Vector3(9.0, 1.5, 60.5))
	await _vue("125_banderole", Vector3(8.0, 1.6, 54.5), Vector3(9.0, 1.1, 59.0))
	await _vue("126_palettes", Vector3(-6.0, 1.6, 47.0), Vector3(-12.5, 0.4, 52.0))
	await _vue("127_portique", Vector3(2.0, 1.7, 47.0), Vector3(0.0, 7.0, 57.0))
	await _vue("128_large", Vector3(22.0, 9.0, 30.0), Vector3(0.0, 2.0, 52.0))
	# la nuit : les guirlandes, les flambeaux, les lyres et leurs faisceaux
	fm.temps_v56.lamps_on = true
	var D: Node = Tf.decor_v163
	if D != null:
		D.ampoules_mat.emission_energy_multiplier = 1.6
		D.flamme_mat.set_shader_parameter("glow", 1.0)
	_nuit()
	await _vue("12a_nuit_piste", Vector3(3.0, 1.7, 38.0), Vector3(1.0, 3.0, 60.0))
	await _vue("12b_nuit_large", Vector3(22.0, 9.0, 30.0), Vector3(0.0, 2.0, 52.0))
	await _vue("12c_nuit_danse", Vector3(-4.0, 1.7, 44.0), Vector3(4.0, 3.5, 57.0))


# =================================================================== l'île de la jungle et l'Atlantide (V162)

func _jungle(pitons: bool = false) -> void:
	var J: Node3D = load("res://scripts/jungle_v29.gd").new()
	fm.add_child(J)
	J.build(true)
	fm.ile_node = J
	var F: Node3D = load("res://scripts/jungle_flora_v30.gd").new()
	fm.add_child(F)
	F.build(J, true)
	for k in range(6):
		await process_frame
	await physics_frame
	await physics_frame
	_mer(J.CENTER)
	var C: Vector3 = J.CENTER
	if pitons:
		for i in range(3):
			var tw: Array = J.TOWERS[i]
			var tc: Vector3 = C + Vector3((tw[0] as Vector2).x, 0, (tw[0] as Vector2).y)
			var dir := Vector3(1, 0, 0.6).normalized().rotated(Vector3.UP, i * 2.1)
			var cam_at: Vector3 = _sol(tc + dir * (float(tw[1]) + 9.0)) + Vector3.UP * 1.7
			await _vue("99_piton_%d" % i, cam_at, _sol(tc) + Vector3.UP * 9.0)
		return
	var ds: Vector3 = J.dock_start
	var de: Vector3 = J.dock_end
	var terre: Vector3 = ds + (ds - de).normalized() * 6.0
	await _vue("91_plage", _sol(terre) + Vector3.UP * 1.7, _sol(terre + (ds - de).normalized() * 40.0) + Vector3.UP * 8.0)
	await _vue("92_baie", de + Vector3(0, 2.5, 0) + (de - ds).normalized() * 6.0, _sol(terre) + Vector3.UP * 6.0)
	await _vue("93_foret", _sol(C + Vector3(10, 0, 40)) + Vector3.UP * 1.7, _sol(C + Vector3(20, 0, 10)) + Vector3.UP * 5.0)
	await _vue("94_sous_bois", _sol(C + Vector3(-30, 0, 20)) + Vector3.UP * 1.7, _sol(C + Vector3(-50, 0, 0)) + Vector3.UP * 3.0)
	var t0: Array = J.TOWERS[1]
	var tp: Vector3 = C + Vector3((t0[0] as Vector2).x, 0, (t0[0] as Vector2).y)
	await _vue("95_piton", _sol(tp + Vector3(28, 0, 28)) + Vector3.UP * 1.7, _sol(tp) + Vector3.UP * 20.0)
	await _vue("96_canopee", C + Vector3(60, 45, 90), C + Vector3(0, 10, 0))
	await _vue("97_geant", _sol(C + Vector3(0, 0, -20)) + Vector3.UP * 1.7, _sol(C + Vector3(0, 0, -40)) + Vector3.UP * 14.0)
	await _vue("98_dessus", C + Vector3(-120, 160, 220), C)


func _atlantide() -> void:
	var A: Node3D = load("res://scripts/atlantide_v55.gd").new()
	fm.add_child(A)
	A.build(fm)
	for k in range(6):
		await process_frame
	var C: Vector3 = A.C
	await _vue("71_place", A.at(150.0, 22.0, 1.7), C + Vector3(0, 8.0, 0))
	await _vue("72_tour", A.at(200.0, 12.0, 1.7), C + Vector3(0, 14.0, 0))
	await _vue("73_palais", A.at(0.0, 14.0, 1.7), A.at(0.0, 34.0, 5.0))
	await _vue("74_atelier", A.at(90.0, 18.0, 1.7), A.at(90.0, 34.0, 3.0))
	await _vue("75_archives", A.at(270.0, 18.0, 1.7), A.at(270.0, 34.0, 3.0))
	await _vue("76_maisons", A.at(45.0, 26.0, 1.7), A.at(60.0, 38.0, 2.0))
	await _vue("77_porte", A.at(180.0, 30.0, 1.7), A.at(180.0, 46.0, 4.0))
	await _vue("78_canal", A.at(120.0, 20.0, 1.7), A.at(70.0, 20.0, 0.5))
	await _vue("79_dessus", C + Vector3(50, 40, 60), C)


# =================================================================== l'île flottante et la Citadelle des Nuées (V161)

func _celeste() -> void:
	var Cv: Node3D = load("res://scripts/ciel_v54.gd").new()
	fm.add_child(Cv)
	fm.ciel_v54 = Cv
	Cv.setup(fm)
	Cv.pc = true
	Cv.build()
	fm.ile_node = Cv.ile
	for k in range(6):
		await process_frame
	await physics_frame
	await physics_frame
	var I: Node3D = Cv.ile
	var C: Vector3 = I.CENTER + Vector3.UP * I.Y0
	_mer(Vector3(I.CENTER.x, 0.0, I.CENTER.z))
	var K: Node3D = Cv.chateau
	var esp: Vector3 = I.world(I.ESPLANADE)
	await _vue("81_esplanade", esp + Vector3(4, 1.7, 8), K.global_position + Vector3(0, 9, 0))
	await _vue("82_porte", K.at("porte") + Vector3(3, 1.7, 9), K.at("porte") + Vector3(0, 4, 0))
	await _vue("83_cour", K.at("cour") + Vector3(-6, 1.7, 6), K.at("porte_donjon") + Vector3(0, 4, 0))
	await _portes173("celeste")
	await _vue("84_salle", K.at("salle") + Vector3(0, 1.7, 5), K.at("salle") + Vector3(0, 1.5, -6))
	await _vue("85_lutrin", K.at("lutrin") + Vector3(2.5, 1.7, 3), K.at("lutrin") + Vector3(0, 1.0, 0))
	await _vue("86_trone", K.at("trone") + Vector3(0, 1.7, 9), K.at("trone") + Vector3(0, 2.0, 0))
	await _vue("87_dessous", C + Vector3(95, -70, 95), C + Vector3(0, -35, 0))
	var f0: Vector3 = I.falls[0] if I.falls.size() > 0 else C
	await _vue("88_cascade", f0 + Vector3(35, 25, 35), f0 + Vector3(0, 40, 0))
	await _vue("89_vue_haut", C + Vector3(110, 70, 120), C + Vector3(0, 8, 0))
	await _vue("90_bord", I.world(Vector2(30, 30)) + Vector3(0, 1.7, 0), I.world(Vector2(60, 60)) + Vector3(0, -20, 0))


# =================================================================== Hautefond : la Cité des Nuées, les Strates, le Dôme d'Azur (V160)

func _hautefond(quoi: String) -> void:
	var Hf: Node3D = load("res://scripts/hautefond_v112.gd").new()
	fm.add_child(Hf)
	Hf.setup(fm)
	Hf.pc = true
	Hf.build_island()
	fm.ile_node = Hf.ile
	Hf.build_town()
	for k in range(6):
		await process_frame
	await physics_frame
	await physics_frame
	if quoi == "nuees_mur":
		# le mur-rideau de près (V160), le jour puis le soir
		_mer(Hf.ile.CENTER)
		var Rm = load("res://scripts/ile_nuees_v113.gd")
		var cm: Vector3 = Rm.CENTER
		await _vue("49a_tour_pres", _ray(cm + Vector3(-8, 0, -30), cm.y + 80.0) + Vector3.UP * 1.7, _ray(cm + Vector3(-6, 0, -52), cm.y + 80.0) + Vector3.UP * 9.0)
		await _vue("49b_tour_haut", _ray(cm + Vector3(4, 0, -36), cm.y + 80.0) + Vector3.UP * 1.7, _ray(cm + Vector3(0, 0, -62), cm.y + 80.0) + Vector3.UP * 30.0)
		await _vue("49c_esplanade", _ray(cm + Vector3(26, 0, 22), cm.y + 80.0) + Vector3.UP * 1.7, _ray(cm, cm.y + 80.0) + Vector3.UP * 4.0)
		load("res://scripts/nuees_mats_v113.gd").night(1.0)
		sun.light_energy = 0.05
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.02, 0.03, 0.06)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.3, 0.35, 0.5)
		env.ambient_light_energy = 0.25
		env.fog_enabled = false
		await _vue("49d_soir", _ray(cm + Vector3(-8, 0, -30), cm.y + 80.0) + Vector3.UP * 1.7, _ray(cm + Vector3(-6, 0, -52), cm.y + 80.0) + Vector3.UP * 9.0)
		await _vue("49e_soir_esplanade", _ray(cm + Vector3(26, 0, 22), cm.y + 80.0) + Vector3.UP * 1.7, _ray(cm, cm.y + 80.0) + Vector3.UP * 4.0)
		return
	if quoi == "nuees":
		_mer(Hf.ile.CENTER)
		var Rn = load("res://scripts/ile_nuees_v113.gd")
		var c: Vector3 = Rn.CENTER
		await _vue("41_esplanade", _ray(c + Vector3(26, 0, 22), c.y + 80.0) + Vector3.UP * 1.7, _ray(c, c.y + 80.0) + Vector3.UP * 4.0)
		await _vue("42_esplanade_b", _ray(c + Vector3(-20, 0, 18), c.y + 80.0) + Vector3.UP * 1.7, _ray(c + Vector3(10, 0, -10), c.y + 80.0) + Vector3.UP * 6.0)
		await _vue("43_residences", _ray(c + Vector3(-30, 0, 40), c.y + 80.0) + Vector3.UP * 1.7, _ray(c + Vector3(-55, 0, 55), c.y + 80.0) + Vector3.UP * 8.0)
		await _vue("44_serres", _ray(c + Vector3(40, 0, 10), c.y + 80.0) + Vector3.UP * 1.7, _ray(c + Vector3(70, 0, 0), c.y + 80.0) + Vector3.UP * 5.0)
		await _vue("45_institut", _ray(c + Vector3(0, 0, -40), c.y + 80.0) + Vector3.UP * 1.7, _ray(c + Vector3(0, 0, -75), c.y + 80.0) + Vector3.UP * 8.0)
		await _vue("46_vue_haut", c + Vector3(90, 70, 110), c)
		await _vue("47_gare", _ray(c + Vector3(45, 0, 45), c.y + 80.0) + Vector3.UP * 1.7, _ray(c + Vector3(65, 0, 65), c.y + 80.0) + Vector3.UP * 5.0)
		await _vue("48_parc", _ray(c + Vector3(-35, 0, -25), c.y + 80.0) + Vector3.UP * 1.7, _ray(c + Vector3(-58, 0, -40), c.y + 80.0) + Vector3.UP * 3.0)
		return
	# sous terre et au fond de la mer : la lumière vient de la ville
	sun.visible = false
	env.fog_enabled = false
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.025, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.45, 0.5)
	env.ambient_light_energy = 0.6
	if quoi == "strates_four":
		Hf.strates_roche.visible = true
		Hf.strates.visible = true
		var cf: Transform3D = Hf.strates.cadres118["forge"]
		await _vue("54b_four", cf * Vector3(-3.6, 1.7, 1.5), cf * Vector3(-6.5, 1.2, -4.2))
		await _vue("54c_fours", cf * Vector3(0, 1.7, 9.5), cf * Vector3(0, 2.5, -5.0))
		var o2: Vector3 = load("res://scripts/strates_roche_v114.gd").O
		await _vue("58b_champignons", _ray(o2 + Vector3(10, 0, 75), -80.0) + Vector3.UP * 1.7, _ray(o2 + Vector3(8, 0, 100), -80.0) + Vector3.UP * 3.0)
		await _vue("58c_champignon_pres", _ray(o2 + Vector3(4, 0, 88), -80.0) + Vector3.UP * 1.2, _ray(o2 + Vector3(9, 0, 100), -80.0) + Vector3.UP * 2.5)
		return
	if quoi == "strates":
		Hf.strates_roche.visible = true
		Hf.strates.visible = true
		var o: Vector3 = load("res://scripts/strates_roche_v114.gd").O
		var y0: float = -80.0
		await _vue("51_place", _ray(o + Vector3(14, 0, 14), y0) + Vector3.UP * 1.7, _ray(o, y0) + Vector3.UP * 6.0)
		await _vue("52_place_b", _ray(o + Vector3(-16, 0, 10), y0) + Vector3.UP * 1.7, _ray(o + Vector3(10, 0, -10), y0) + Vector3.UP * 5.0)
		await _vue("53_maisons", _ray(o + Vector3(30, 0, -20), y0) + Vector3.UP * 1.7, _ray(o + Vector3(55, 0, -35), y0) + Vector3.UP * 5.0)
		await _vue("54_forge", _ray(o + Vector3(30, 0, -30), y0) + Vector3.UP * 1.7, _ray(o + Vector3(50, 0, -50), y0) + Vector3.UP * 6.0)
		await _vue("55_caverne", o + Vector3(-40, -70, 40), o + Vector3(0, -90, 0))
		await _vue("56_galeries", _ray(o + Vector3(0, 0, -30), y0) + Vector3.UP * 1.7, o + Vector3(0, -82, -70))
		await _vue("57_marmite", _ray(o + Vector3(30, 0, 30), y0) + Vector3.UP * 1.7, _ray(o + Vector3(50, 0, 50), y0) + Vector3.UP * 4.0)
		await _vue("58_jardins", _ray(o + Vector3(10, 0, 75), y0) + Vector3.UP * 1.7, _ray(o + Vector3(8, 0, 100), y0) + Vector3.UP * 3.0)
		return
	Hf.dome_fosse.visible = true
	Hf.dome.visible = true
	Hf.dome_vie.visible = true
	var od: Vector3 = load("res://scripts/fosse_azur_v115.gd").O
	var yd: float = od.y + 30.0
	if quoi == "dome_v160":
		# le Jardin des Coraux de près, les tours (le mur-rideau sous la mer)
		var cj: Vector3 = Hf.dome.objets["jardin"]
		await _vue("69a_coraux", cj + Vector3(3.5, 1.6, 6.5), cj + Vector3(0.0, 1.0, 0.0))
		await _vue("69b_corail_pres", cj + Vector3(1.6, 1.5, 2.6), cj + Vector3(0.0, 1.1, 0.0))
		await _vue("69c_tours", _ray(od + Vector3(20, 0, 20), yd) + Vector3.UP * 1.7, _ray(od + Vector3(-60, 0, 10), yd) + Vector3.UP * 14.0)
		await _vue("69d_tour_pres", _ray(od + Vector3(-24, 0, 10), yd) + Vector3.UP * 1.7, _ray(od + Vector3(-40, 0, 2), yd) + Vector3.UP * 12.0)
		return
	await _vue("61_place_perle", _ray(od + Vector3(20, 0, 20), yd) + Vector3.UP * 1.7, _ray(od, yd) + Vector3.UP * 8.0)
	await _vue("62_place_b", _ray(od + Vector3(-24, 0, 10), yd) + Vector3.UP * 1.7, _ray(od + Vector3(10, 0, -10), yd) + Vector3.UP * 6.0)
	await _vue("63_maisons", _ray(od + Vector3(30, 0, -25), yd) + Vector3.UP * 1.7, _ray(od + Vector3(50, 0, -40), yd) + Vector3.UP * 4.0)
	await _vue("64_dome_haut", od + Vector3(40, 35, 40), od + Vector3(0, 5, 0))
	await _vue("65_serres", _ray(od + Vector3(-110, 0, -10), yd) + Vector3.UP * 1.7, _ray(od + Vector3(-130, 0, -16), yd) + Vector3.UP * 4.0)
	await _vue("66_institut", _ray(od + Vector3(110, 0, 20), yd) + Vector3.UP * 1.7, _ray(od + Vector3(126, 0, 24), yd) + Vector3.UP * 4.0)
	await _vue("67_promenade", _ray(od + Vector3(0, 0, 55), yd) + Vector3.UP * 1.7, od + Vector3(0, 8, 90))
	await _vue("68_tours", _ray(od + Vector3(-30, 0, 30), yd) + Vector3.UP * 1.7, _ray(od + Vector3(-45, 0, 45), yd) + Vector3.UP * 12.0)


## Le sol sous (x, z) : un rayon tiré de y_haut vers le bas (les villes ont leurs collisions).
func _ray(p: Vector3, y_haut: float) -> Vector3:
	var ss: PhysicsDirectSpaceState3D = root.world_3d.direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, y_haut, p.z), Vector3(p.x, y_haut - 200.0, p.z))
	var r: Dictionary = ss.intersect_ray(q)
	if r.is_empty():
		return Vector3(p.x, fm._height_at(p.x, p.z), p.z)
	return r["position"]


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


## La nuit (V163) : le soleil presque éteint, un ciel noir bleuté, un peu de lune.
func _nuit() -> void:
	sun.light_energy = 0.06
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.03, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.35, 0.5)
	env.ambient_light_energy = 0.22
	env.fog_enabled = false


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
	sea.position = Vector3(c.x, -0.42, c.z)


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
