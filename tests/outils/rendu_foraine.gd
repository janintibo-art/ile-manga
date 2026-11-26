extends SceneTree
## Des images de l'Île Foraine (V209), pour juger l'effet (lancé par tests/outils/rendu_foraine.sh) :
## l'île vue de haut, le Grand Portail, l'allée, le quai, la voie du Grand Frisson, puis ce qu'on voit
## du premier rang pendant le tour (« tour »). Un rendu d'atelier : l'île seule, un ciel et une mer simples.

const Foraine = preload("res://scripts/foraine_v209.gd")
const Ile = preload("res://scripts/ile_foraine_v209.gd")


class FakeMain:
	extends Node3D
	var xr_active: bool = false
	var cam: Camera3D
	var game_started: bool = true
	var temps_v56: Node
	var pc_root: Node3D
	var pc_body: CharacterBody3D
	var pc_camera: Camera3D
	var messages: Array = []

	func _player_pos_v27() -> Vector3:
		return cam.global_position if cam != null else Vector3.ZERO

	func sfx(_n: String, _at: Variant = null, _db: float = 0.0) -> void:
		pass

	func _show_message_v28(t: String) -> void:
		messages.append(t)

	func place_player_v35(at: Vector3, _face: Vector3) -> void:
		pc_root.position = at


class FakeTemps:
	extends Node
	var hour: float = 10.0
	var day_count: int = 3


var out: String = ""
var cam: Camera3D
var fm: FakeMain
var g: Node3D


func _initialize() -> void:
	out = str(OS.get_cmdline_user_args()[0])
	var quoi: String = str(OS.get_cmdline_user_args()[1]) if OS.get_cmdline_user_args().size() > 1 else "tout"
	_monde()
	fm = FakeMain.new()
	root.add_child(fm)
	var tp := FakeTemps.new()
	fm.add_child(tp)
	fm.temps_v56 = tp
	fm.pc_root = Node3D.new()
	fm.add_child(fm.pc_root)
	fm.pc_body = CharacterBody3D.new()
	fm.add_child(fm.pc_body)
	cam = Camera3D.new()
	cam.fov = 70.0
	cam.far = 4000.0
	cam.near = 0.1
	root.add_child(cam)
	cam.current = true
	fm.cam = cam
	fm.pc_camera = cam
	for k in range(4):
		await process_frame
	var t0: int = Time.get_ticks_msec()
	g = Foraine.new()
	fm.add_child(g)
	g.setup(fm)
	g.build_island()
	g.build_town()
	print("ILE_MANGA_V209 rendu : construite en ", Time.get_ticks_msec() - t0, " ms, ", g.huit.supports, " poteaux")
	var C: Vector3 = Ile.CENTER
	for k2 in range(12):
		await process_frame
	if quoi in ["tout", "vues"]:
		await _vue("01_dessus", C + Vector3(-40, 420, 260), C)
		await _vue("02_du_large", C + Vector3(-420, 30, 120), C + Vector3(0, 25, 0))
		await _vue("03_ponton", g.dock()[1] + Vector3(-2, 2.0, 3), C + Vector3(0, 18, 20))
		await _vue("04_portail", _sol(-176, 21) + Vector3(0, 1.7, 0), C + Vector3(-158, 8, 20))
		await _vue("05_guichet", _sol(-171, 17) + Vector3(0, 1.7, 0), C + Vector3(-165, 4.5, 10.5))
		await _vue("06_allee", _sol(-146, 20) + Vector3(0, 1.7, 0), C + Vector3(0, 16, 30))
		await _vue("07_place", _sol(-48, 22) + Vector3(0, 1.7, 0), C + Vector3(-20, 10, 20))
		await _vue("08_gare", _sol(-78, 36) + Vector3(0, 1.7, 0), C + Vector3(-78, 9, 66))
		await _vue("09_quai", C + Vector3(-90, 7.0, 64.5), C + Vector3(-60, 6.2, 69.5))
		await _vue("10_montee", _sol(-30, 44) + Vector3(0, 1.7, 0), C + Vector3(70, 46, 70))
		await _vue("11_boucle", _sol(-52, -4) + Vector3(0, 1.7, 0), C + Vector3(-52, 20, -33))
		await _vue("12_vrille", _sol(26, -8) + Vector3(0, 1.7, 0), C + Vector3(26, 11, -30))
		await _vue("13_chute", _sol(96, -8) + Vector3(0, 1.7, 0), C + Vector3(121, 30, 20))
		await _vue("14_butte", _sol(18, -116) + Vector3(0, 1.7, 0), C + Vector3(-60, 12, -20))
		await _vue("15_plage_nord", _sol(20, -182) + Vector3(0, 1.7, 0), C + Vector3(80, 4, -200))
		await _vue("16_sous_la_voie", _sol(118, -60) + Vector3(0, 1.7, 0), C + Vector3(121, 22, -88))
	if quoi in ["tout", "tour"]:
		g.offrir_billet()
		g.huit.attente = 0.5
		fm.pc_root.global_position = g.huit.quai_pos
		print("ILE_MANGA_V209 rendu : monter ", g.monter(), " ", fm.messages)
		var d: Dictionary = g.huit.d
		for arr in [["20_depart", 60], ["21_montee", 150], ["22_sommet", 222], ["23_chute", 262], ["24_bas_chute", 320], ["25_bosse", 388],
				["26_ras_eau", 560], ["27_remontee", 760], ["28_avant_boucle", 900], ["29_boucle_haut", 955], ["30_vrille", 1076],
				["31_sous_montee", 1220], ["32_sud", 1380], ["33_bosses", 1520], ["34_freins", 1665]]:
			var cible: int = int(arr[1])
			var garde: int = 0
			while int(g.huit._idx(g.huit.pos)) < cible and garde < 40000 and g.huit.a_bord:
				g.huit.avancer(0.02)
				garde += 1
			g.huit._porter(0.0)
			for k3 in range(5):
				await process_frame
			root.get_texture().get_image().save_png("%s/%s.png" % [out, str(arr[0])])
			print("ILE_MANGA_V209 rendu : ", arr[0], " v ", snappedf(float(g.huit.vitesse) * 3.6, 1.0), " km/h")
		var garde2: int = 0
		while g.huit.a_bord and garde2 < 60000:
			g.huit.avancer(0.02)
			garde2 += 1
		print("ILE_MANGA_V209 rendu : fin du tour, à bord ", g.huit.a_bord, " tours ", g.huit.tours, " ", fm.messages.back())
	if quoi in ["tout", "maneges"]:
		# V210 : les manèges à sensations, vus du sol puis de notre siège
		await _vue("40_marteau", _sol(60, 22) + Vector3(0, 1.7, 0), C + Vector3(36, 26, 44))
		await _vue("41_marteau_quai", _sol(40, 30) + Vector3(0, 1.7, 0), C + Vector3(36, 5, 44))
		await _vue("42_chute", _sol(22, -78) + Vector3(0, 1.7, 0), C + Vector3(18, 62, -116))
		await _vue("43_chute_pied", _sol(19, -104) + Vector3(0, 1.7, 0), C + Vector3(18, 24, -116))
		await _vue("44_balancoire", _sol(-28, 150) + Vector3(0, 1.7, 0), C + Vector3(20, 20, 160))
		await _vue("45_balancoire_quai", _sol(12, 150) + Vector3(0, 1.7, 0), C + Vector3(20, 6, 160))
		await _vue("46_ensemble", C + Vector3(-150, 70, 150), C + Vector3(20, 20, 0))
		g.offrir_billet()
		for spec in [["marteau", [4.0, 9.0, 12.5, 16.0, 22.0, 26.5, 28.0, 36.0]], ["chute", [6.0, 14.0, 22.0, 900.0, 901.2, 902.4, 903.2, 906.0]],
				["balancoire", [8.0, 20.0, 31.0, 33.5, 36.5, 39.0, 42.0, 55.0]]]:
			var m: Node3D = g.manege(str(spec[0]))
			m.etat = "quai"
			m.attente = 0.3
			fm.pc_root.global_position = m.quai_pos
			print("ILE_MANGA_V210 rendu : monter ", spec[0], " ", g.monter_manege(m))
			var n: int = 0
			var chute_t0: float = -1.0
			for cible in spec[1]:
				var but: float = float(cible)
				var garde: int = 0
				while garde < 60000 and m.a_bord:
					# la Chute : les instants après 900 se comptent depuis le lâcher
					if str(spec[0]) == "chute" and but >= 900.0:
						if chute_t0 < 0.0 and str(m.phase) == "chute":
							chute_t0 = float(m.t)
						if chute_t0 >= 0.0 and float(m.t) - chute_t0 >= but - 900.0:
							break
					elif m.etat == "marche" and float(m.t) >= but:
						break
					m.avancer(0.02)
					garde += 1
				m._porter(0.0)
				for k4 in range(5):
					await process_frame
				root.get_texture().get_image().save_png("%s/5%d_%s_%d.png" % [out, ["marteau", "chute", "balancoire"].find(str(spec[0])), str(spec[0]), n])
				print("ILE_MANGA_V210 rendu : ", spec[0], " t ", snappedf(float(m.t), 0.1), " v ", snappedf(float(m.vitesse) * 3.6, 1.0), " km/h, h ",
					snappedf(m.siege().origin.y - m.global_position.y, 0.1), " m, g ", snappedf(float(m.g_ressenti), 0.1), " haut.y ", snappedf(m.siege().basis.y.y, 0.01))
				n += 1
			var garde3: int = 0
			while m.a_bord and garde3 < 60000:
				m.avancer(0.02)
				garde3 += 1
			print("ILE_MANGA_V210 rendu : fin, à bord ", m.a_bord, " ", fm.messages.back())
	if quoi == "paliers":
		# V211 : l'île vue de loin, à plein détail puis avec le détail allégé (au téléobjectif, pour voir les défauts)
		var al = load("res://scripts/allege_loin_v211.gd").new()
		root.add_child(al)
		al.setup(null)
		print("ILE_MANGA_V211 rendu : ", al.recenser(root), " gros maillages")
		al.tout()
		print("ILE_MANGA_V211 rendu : %d allégés sur %d, de %d k à %d k triangles au plus léger, %.0f ms" % [al.gagnes, al.faits, al.tri_avant / 1000, al.tri_loin / 1000, al.ms_total])
		var fov0: float = cam.fov
		for d in [[300.0, 40.0, 70.0], [900.0, 60.0, 30.0], [2000.0, 80.0, 14.0]]:
			cam.fov = float(d[2])
			for seuil in [0.0, 0.6, 1.0]:
				root.mesh_lod_threshold = float(seuil)
				await _vue("6_paliers_%dm_seuil_%s" % [int(d[0]), str(seuil).replace(".", "")], C + Vector3(-float(d[0]), float(d[1]), float(d[0]) * 0.5), C + Vector3(0, 12, 0), 8)
				print("ILE_MANGA_V211 rendu : à %d m, seuil %.1f : %d k triangles dessinés" % [int(d[0]), float(seuil), int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)) / 1000])
		cam.fov = fov0
	quit()


func _sol(x: float, z: float) -> Vector3:
	var w: Vector3 = Ile.W(x, z)
	w.y = g.ile.height(w.x, w.z)
	return w


func _vue(nom: String, at: Vector3, look: Vector3, images: int = 6) -> void:
	cam.current = true
	cam.global_position = at
	cam.look_at(look)
	for k in range(images):
		await process_frame
	root.get_texture().get_image().save_png("%s/%s.png" % [out, nom])


func _monde() -> void:
	var env := Environment.new()
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
	env.fog_density = 0.0005
	env.fog_light_color = Color(0.7, 0.78, 0.86)
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-46, -35, 0)
	sun.shadow_enabled = true
	sun.light_energy = 1.25
	sun.directional_shadow_max_distance = 300.0
	root.add_child(sun)
	var sea := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(3000, 3000)
	sea.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.1, 0.32, 0.46)
	m.roughness = 0.15
	sea.material_override = m
	root.add_child(sea)
	sea.position = Ile.CENTER + Vector3(0, -0.42, 0)
