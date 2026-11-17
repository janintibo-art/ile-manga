extends SceneTree
## Des images des sols de l'île (V158 : avant / après la haute définition) et des pièces des maisons
## (lancé par tests/outils/rendu_maisons.sh).

const Maisons = preload("res://scripts/maisons_v81.gd")
const Pieces = preload("res://scripts/maisons_pieces_v81.gd")


class FakeMain:
	extends Node3D
	var xr_active: bool = false
	var cam: Camera3D
	var npcs_v31: Array = []
	var pending_pnj_v31: Dictionary = {}
	var game_started: bool = true
	var temps_v56: Node
	var inventory_v28: Node = null
	var dialogue_v31: Node = null
	var donjon_v35: Node = null

	func _player_pos_v27() -> Vector3:
		return cam.global_position - Vector3.UP * 1.6 if cam != null else Vector3.ZERO

	func _height_at(_x: float, _z: float) -> float:
		return 0.0

	func _npc_ctx_v31() -> Dictionary:
		return {"now": 0.0, "objets": {}, "vr": false}

	func sfx(_n: String, _at: Variant = null, _db: float = 0.0) -> void:
		pass

	func jingle(_n: String) -> void:
		pass

	func _show_message_v28(t: String) -> void:
		print("MESSAGE ", t)

	func place_player_v35(at: Vector3, facing: Vector3) -> void:
		facing.y = 0.0
		cam.global_position = at + Vector3.UP * 1.62
		cam.look_at(cam.global_position + facing.normalized(), Vector3.UP)

	func ask_v69(_a, _b, _c, _d, _e, _f) -> void:
		pass

	func _close_dialogue_v31() -> void:
		pass


class FakeTemps:
	extends Node
	var hour: float = 15.0
	var day_count: int = 3
	var lamps_on: bool = false

	func register_glow(_m: Variant, _a: Variant = null, _b: Variant = null) -> void:
		pass

	func register_lamp(_l: Variant, _e: Variant = null) -> void:
		pass


var out: String = ""
var cam: Camera3D
var n_img: int = 0


func _photo(nom: String) -> void:
	for k in range(8):
		await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	n_img += 1
	img.save_png("%s/%02d_%s.png" % [out, n_img, nom])
	print("RENDU ", nom)


func _vue(from: Vector3, to: Vector3) -> void:
	cam.global_position = from
	cam.look_at(to, Vector3.UP)


func _h(x: float, z: float) -> float:
	# une plage qui monte vers une prairie, puis une butte rocheuse
	var h: float = -0.9 + x * 0.12 + sin(z * 0.21) * 0.25 + sin(x * 0.13 + z * 0.07) * 0.35
	if x > 30.0:
		h += pow((x - 30.0) * 0.32, 2.0)
	return h


func _terrain(dossier: String) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 120
	for i in range(n):
		for j in range(n):
			var pts: Array = [[i, j], [i + 1, j], [i + 1, j + 1], [i, j], [i + 1, j + 1], [i, j + 1]]
			for p in pts:
				var x: float = float(p[0]) * 0.5 - 10.0
				var z: float = float(p[1]) * 0.5 - 30.0
				var e: float = 0.05
				var nm: Vector3 = Vector3(_h(x - e, z) - _h(x + e, z), 2.0 * e, _h(x, z - e) - _h(x, z + e)).normalized()
				st.set_normal(nm)
				st.add_vertex(Vector3(x, _h(x, z), z))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/terrain.gdshader")
	for tex in ["sand", "grass", "stone"]:
		m.set_shader_parameter(tex + "_tex", load("res://assets/textures/%s/%s.jpg" % [dossier, tex]))
		m.set_shader_parameter(tex + "_n", load("res://assets/textures/%s/%s_n.png" % [dossier, tex]))
	m.set_shader_parameter("extra_detail", true)
	mi.material_override = m
	return mi


func _initialize() -> void:
	out = str(OS.get_cmdline_user_args()[0])
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 35, 0)
	sun.shadow_enabled = true
	root.add_child(sun)
	var fm := FakeMain.new()
	root.add_child(fm)
	var tp := FakeTemps.new()
	fm.add_child(tp)
	fm.temps_v56 = tp
	cam = Camera3D.new()
	cam.fov = 70.0
	cam.near = 0.05
	cam.far = 2500.0
	root.add_child(cam)
	cam.current = true
	fm.cam = cam
	for k0 in range(3):
		await process_frame
	var mode: String = str(OS.get_cmdline_user_args()[1]) if OS.get_cmdline_user_args().size() > 1 else ""
	if mode == "" or mode == "sols":
		# les sols : avant (terrain_avant) et après
		var vues: Array = [
			["herbe", Vector3(24.0, _h(24, 0) + 1.65, 0.0), Vector3(25.6, _h(25.6, 0.8), 0.8)],
			["sable", Vector3(10.0, _h(10, -6) + 1.65, -6.0), Vector3(11.6, _h(11.6, -5.2), -5.2)],
			["roche", Vector3(33.0, _h(33, 4) + 1.65, 4.0), Vector3(37.0, _h(37, 4) + 0.3, 4.6)],
			["plage_loin", Vector3(4.0, _h(4, -20) + 1.8, -20.0), Vector3(30.0, 1.0, 5.0)],
		]
		for d in ["terrain_avant", "terrain"]:
			if not ResourceLoader.exists("res://assets/textures/%s/grass.jpg" % d):
				print("RENDU pas de ", d)
				continue
			var t := _terrain(d)
			root.add_child(t)
			for v in vues:
				_vue(v[1], v[2])
				await _photo("%s_%s" % [v[0], "avant" if d == "terrain_avant" else "apres"])
			t.queue_free()
			await process_frame
	if mode == "" or mode == "maisons":
		sun.visible = false
		Pieces.sondes = false
		var M = Maisons.new()
		fm.add_child(M)
		M.setup(fm)
		for st in ["azur", "montjoie", "perchee", "tazira", "nuees", "hautefond", "azur#2", "montjoie#3"]:
			for hr in [14.0, 22.0]:
				tp.hour = hr
				var sn: String = st.get_slice("#", 0)
				M.cur = {"id": "rendu_" + st, "style": sn, "w": 8.0, "d": 7.5}
				M.force_scenario = "famille"
				M._build()
				for k in range(3):
					await process_frame
				var R = M.R
				_vue(R.P(R.door_x, 1.65, R.D * 0.5 - 0.5), R.P(R.door_x * 0.3, 0.8, -R.D * 0.5))
				await _photo("%s_v%d_%s" % [sn, R.variante, "jour" if hr < 20.0 else "nuit"])
				if hr < 20.0:
					_vue(R.P(-R.W * 0.5 + 0.6, 1.5, -R.D * 0.5 + 0.6), R.P(R.W * 0.2, 0.4, R.D * 0.2))
					await _photo("%s_v%d_coin" % [sn, R.variante])
				M._teardown()
				await process_frame
	if mode == "sud":
		# V169 : les maisons d'Al Dente (chez chacun), de l'Île Crayonnée (en couleurs, puis en noir et
		# blanc : la porte dans une île encore blanche) et de Sombreval
		sun.visible = false
		Pieces.sondes = false
		var noir := Image.create(4, 4, false, Image.FORMAT_RGBA8)
		noir.fill(Color(0, 0, 0, 1))
		RenderingServer.global_shader_parameter_set("crayon_masque", ImageTexture.create_from_image(noir))
		var M2 = Maisons.new()
		fm.add_child(M2)
		M2.setup(fm)
		var cas: Array = [
			["pasta", "famille", {"owner": "lasagna"}, 14.0, "pates"], ["pasta", "vide", {"owner": "farfalle"}, 20.5, "autel"],
			["pasta", "vide", {"owner": "fusilli"}, 14.0, "savante"], ["pasta", "vide", {"owner": "macaroni"}, 14.0, "gong"],
			["pasta", "vide", {"owner": "penne"}, 14.0, "musique"], ["pasta", "vide", {"owner": "ravioli"}, 14.0, "tomates"],
			["pirate", "vide", {"owner": "rigatoni"}, 14.0, "capitaine"],
			["crayon", "cr_maison", {"maison_id": "pinceau", "door": Vector3(-500, 0, -500)}, 14.0, "pinceau_couleurs"],
			["crayon", "cr_maison", {"maison_id": "pinceau", "door": Vector3(1000, 0, 1450)}, 14.0, "pinceau_crayon"],
			["crayon", "cr_maison", {"maison_id": "gomme", "door": Vector3(-500, 0, -500)}, 21.0, "gomme_soir"],
			["crayon", "cr_maison", {"maison_id": "buvard", "door": Vector3(-500, 0, -500)}, 14.0, "buvard"],
			["crayon", "cr_conseil", {"maison_id": "grand", "door": Vector3(-500, 0, -500)}, 14.0, "conseil"],
			["crayon", "cr_conseil", {"maison_id": "grand", "door": Vector3(1000, 0, 1450)}, 14.0, "conseil_crayon"],
			["sombreval", "sv_souper", {}, 14.0, "souper"], ["sombreval", "sv_refuge", {}, 21.0, "refuge"],
			["sombreval", "sv_enfant", {}, 14.0, "enfant"], ["sombreval", "sv_chat", {}, 14.0, "chat"],
			["sombreval", "sv_pharmacie", {}, 14.0, "pharmacie"], ["sombreval", "sv_gare", {"w": 12.0, "d": 9.0}, 14.0, "gare"],
			["sombreval", "sv_beffroi", {"w": 6.0, "d": 6.0}, 14.0, "beffroi"], ["sombreval", "abandon", {}, 14.0, "abandon"],
		]
		var seul: String = str(OS.get_cmdline_user_args()[2]) if OS.get_cmdline_user_args().size() > 2 else ""
		for c in cas:
			if seul != "" and not str(c[4]).begins_with(seul):
				continue
			tp.hour = float(c[3])
			var cur: Dictionary = {"id": "rendu169_" + str(c[4]), "style": str(c[0]), "w": 8.0, "d": 7.5}
			for k2 in c[2]:
				cur[k2] = c[2][k2]
			M2.cur = cur
			M2.force_scenario = str(c[1])
			M2._build()
			for k3 in range(4):
				await process_frame
			var R2 = M2.R
			if str(c[0]) == "crayon":
				_vue(R2.P(0.0, 1.65, R2.D * 0.5 - 0.5), R2.P(0.0, 0.9, -R2.D * 0.3))
				await _photo("%s_porte" % str(c[4]))
				_vue(R2.P(-R2.W * 0.32, 1.6, -R2.D * 0.2), R2.P(R2.W * 0.3, 0.9, R2.D * 0.1))
				await _photo("%s_dedans" % str(c[4]))
			else:
				_vue(R2.P(R2.door_x, 1.65, R2.D * 0.5 - 0.5), R2.P(R2.door_x * 0.3, 0.8, -R2.D * 0.5))
				await _photo("%s_porte" % str(c[4]))
				_vue(R2.P(-R2.W * 0.5 + 0.6, 1.5, -R2.D * 0.5 + 0.6), R2.P(R2.W * 0.2, 0.5, R2.D * 0.2))
				await _photo("%s_coin" % str(c[4]))
				_vue(R2.P(R2.W * 0.5 - 0.6, 1.5, R2.D * 0.5 - 1.0), R2.P(-R2.W * 0.2, 0.6, -R2.D * 0.3))
				await _photo("%s_coin2" % str(c[4]))
			M2._teardown()
			await process_frame
	quit()
