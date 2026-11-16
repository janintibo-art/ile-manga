extends SceneTree
## Des images des tours de Néopolis (V153), pour juger l'effet (lancé par tests/outils/rendu_tours.sh) :
## une entrée vue de la rue, le hall, les bureaux, la cafétéria, la salle des serveurs, la direction et
## la vue par la fenêtre, un couloir de logements.

const Neo = preload("res://scripts/neo_v94.gd")


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
		return 1.4

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
	env.fog_enabled = true
	env.fog_density = 0.0015
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	root.add_child(sun)
	var fm := FakeMain.new()
	root.add_child(fm)
	var tp := FakeTemps.new()
	fm.add_child(tp)
	fm.temps_v56 = tp
	cam = Camera3D.new()
	cam.fov = 72.0
	cam.near = 0.05
	cam.far = 2500.0
	root.add_child(cam)
	cam.current = true
	fm.cam = cam
	for k0 in range(3):
		await process_frame
	var N: Node3D = Neo.new()
	fm.add_child(N)
	N.setup(fm)
	N.build_island()
	N.build_town()
	var T: Node3D = N.tours
	T.test_mode = true
	T.sondes = false
	for k in range(5):
		await process_frame
	if OS.get_cmdline_user_args().size() > 1 and str(OS.get_cmdline_user_args()[1]) == "quartiers":
		await _quartiers(T)
		quit()
		return
	if OS.get_cmdline_user_args().size() > 1 and str(OS.get_cmdline_user_args()[1]) == "dehors":
		await _dehors(T, fm)
		quit()
		return
	if OS.get_cmdline_user_args().size() > 1 and str(OS.get_cmdline_user_args()[1]) == "rue":
		await _rue(N, fm)
		quit()
		return
	if OS.get_cmdline_user_args().size() > 1 and str(OS.get_cmdline_user_args()[1]) == "vie":
		await _vie(T, fm)
		quit()
		return
	# la plus grande tour de bureaux
	var id: int = -1
	for t in T.tours:
		if str(t["type"]) == "bureaux" and (id < 0 or (t["etages"] as Array).size() > (T.tours[id]["etages"] as Array).size()):
			id = int(t["id"])
	var t0: Dictionary = T.tours[id]
	var s: Vector3 = t0["sortie"]
	var n: Vector3 = t0["n"]
	var side: Vector3 = n.cross(Vector3.UP)
	_vue(s + n * 9.0 + side * 3.0 + Vector3.UP * 2.2, s + Vector3.UP * 2.4)
	await _photo("entree_rue")
	await T.enter(id)
	var rect: Rect2 = T.info["rect"]
	var y: float = T.info["y"]
	_vue((t0["face"] as Vector3) - n * 0.8 + Vector3.UP * 1.9 + side * 1.0, T.info["ascenseur"] + Vector3.UP * 1.2)
	await _photo("hall")
	_vue(Vector3(rect.position.x + 1.0, y + 2.2, rect.position.y + 1.0), Vector3(rect.get_center().x, y + 1.0, rect.get_center().y))
	await _photo("hall_coin")
	for k in [1, 2]:
		await T.aller(k)
		rect = T.info["rect"]
		y = T.info["y"]
		_vue(Vector3(rect.position.x + 0.9, y + 2.2, rect.position.y + 0.9), Vector3(rect.get_center().x, y + 0.6, rect.get_center().y))
		await _photo("%s_%d" % [T.info["type"], k])
		_vue(Vector3(rect.end.x - 0.9, y + 1.7, rect.end.y - 0.9), Vector3(rect.get_center().x, y + 0.9, rect.get_center().y))
		await _photo("%s_%d_b" % [T.info["type"], k])
	var ns: int = (t0["etages"] as Array).size()
	for k2 in range(3, ns):
		if T.type_etage(id, k2) == "serveurs":
			await T.aller(k2)
			rect = T.info["rect"]
			y = T.info["y"]
			_vue(Vector3(rect.position.x + 0.9, y + 1.8, rect.position.y + 0.9), Vector3(rect.get_center().x, y + 1.0, rect.get_center().y))
			await _photo("serveurs")
			break
	await T.aller(ns - 1)
	rect = T.info["rect"]
	y = T.info["y"]
	_vue(Vector3(rect.get_center().x, y + 1.7, rect.position.y + 1.2), Vector3(rect.get_center().x + 3.0, y + 0.8, rect.end.y))
	await _photo("direction")
	# la vue : vers la fenêtre la plus proche
	_vue(Vector3(rect.position.x + 1.5, y + 1.7, rect.get_center().y), Vector3(rect.position.x - 30.0, y - 25.0, rect.get_center().y + 10.0))
	await _photo("vue_fenetre")
	await T.leave()
	# des logements
	var idl: int = -1
	for t2 in T.tours:
		if str(t2["type"]) == "logements" and (t2["etages"] as Array).size() >= 6:
			idl = int(t2["id"])
			break
	await T.enter(idl)
	await T.aller(3)
	var a: Vector3 = T.info["ascenseur"]
	var rg: Vector3 = T.info["regard"]
	_vue(a + Vector3.UP * 1.6 - rg * 0.5, a + Vector3.UP * 1.4 + rg.cross(Vector3.UP) * 6.0)
	await _photo("logements")
	_vue(a + Vector3.UP * 1.6 + rg * 0.3, a + Vector3.UP * 1.4 - rg.cross(Vector3.UP) * 6.0)
	await _photo("logements_b")
	await T.leave()
	_vue(Vector3(300, 60, 1150), Vector3(300, 30, 1400))
	await _photo("ville")
	quit()


# =================================================================== V155 : les quartiers

func _tour_rdc(T: Node, rdc: String, min_n: int = 2) -> int:
	var best: int = -1
	for t in T.tours:
		if str(t.get("rdc", "")) == rdc and (t["etages"] as Array).size() >= min_n:
			if best < 0 or (t["etages"] as Array).size() > (T.tours[best]["etages"] as Array).size():
				best = int(t["id"])
	return best


func _coin(T: Node, nom: String, h: float = 1.75) -> void:
	var rect: Rect2 = T.info["rect"]
	var y: float = T.info["y"]
	_vue(Vector3(rect.position.x + 0.9, y + h, rect.position.y + 0.9), Vector3(rect.get_center().x, y + 0.8, rect.get_center().y))
	await _photo(nom)


func _depuis_ascenseur(T: Node, nom: String) -> void:
	var a: Vector3 = T.info["ascenseur"]
	var rg: Vector3 = T.info["regard"]
	var side: Vector3 = rg.cross(Vector3.UP)
	_vue(a + Vector3.UP * 1.7 + rg * 0.2, a + Vector3.UP * 1.0 + rg * 4.0 + side * 3.0)
	await _photo(nom)


func _quartiers(T: Node) -> void:
	for rdc in ["hangar", "atelier", "nouilles", "boutique", "salle_jeux"]:
		var id: int = _tour_rdc(T, rdc)
		if id < 0:
			print("RENDU pas de ", rdc)
			continue
		await T.enter(id)
		await _coin(T, rdc)
		await _depuis_ascenseur(T, rdc + "_b")
		if rdc == "salle_jeux":
			await T.aller(1)
			await _coin(T, "karaoke", 1.6)
			await _depuis_ascenseur(T, "karaoke_b")
			await T.aller(2)
			await _coin(T, "capsules", 1.6)
			await _depuis_ascenseur(T, "capsules_b")
		await T.leave()
	# un appartement
	var idl: int = -1
	for t in T.tours:
		if str(t["type"]) == "logements" and str(t.get("rdc", "")) == "hall" and (t["etages"] as Array).size() >= 6:
			idl = int(t["id"])
			break
	await T.enter(idl)
	var fait: bool = false
	for k in range(1, 6):
		await T.aller(k)
		for it in T._its.duplicate():
			if str(it["id"]).begins_with("porte153_"):
				var c: Callable = it["call"]
				if c.get_bound_arguments().size() > 1 and bool(c.get_bound_arguments()[1]):
					var p: Vector3 = it["pos"]
					c.call()
					await process_frame
					# du couloir, par la porte ouverte ; puis dedans, vers la fenêtre ; puis vers l'entrée
					var core: Rect2 = T.info["core"]
					var dc: Vector3 = p - Vector3(core.get_center().x, p.y, core.get_center().y)
					var dir: Vector3 = Vector3(signf(dc.x), 0, 0) if absf(dc.x) * core.size.y > absf(dc.z) * core.size.x else Vector3(0, 0, signf(dc.z))
					_vue(p + Vector3.UP * 1.65 - dir * 0.3, p + dir * 5.0 + Vector3.UP * 1.0)
					await _photo("appartement")
					var lat: Vector3 = dir.cross(Vector3.UP)
					_vue(p + dir * 2.0 + Vector3.UP * 1.65 + lat * 0.8, p + dir * 6.0 - lat * 1.5 + Vector3.UP * 0.7)
					await _photo("appartement_b")
					_vue(p + dir * 4.5 + Vector3.UP * 1.65, p + dir * 1.0 + Vector3.UP * 0.9 + lat * 1.2)
					await _photo("appartement_c")
					fait = true
					break
		if fait:
			break
	await T.aller(0)
	await T.leave()
	# les toits : une résidence, une tour de bureaux
	for ty in ["logements", "bureaux"]:
		var id2: int = -1
		for t2 in T.tours:
			if str(t2["type"]) == ty and (t2["etages"] as Array).size() >= 8:
				if id2 < 0 or (ty == "bureaux" and (t2["etages"] as Array).size() > (T.tours[id2]["etages"] as Array).size()):
					id2 = int(t2["id"])
		await T.enter(id2)
		await T.aller((T.tours[id2]["etages"] as Array).size() - 1)
		await T.aller_toit()
		var a: Vector3 = T.info["ascenseur"]
		var rg: Vector3 = T.info["regard"]
		_vue(a + Vector3.UP * 1.7, a + rg * 8.0 + Vector3.UP * 0.5)
		await _photo("toit_" + ty)
		var rr: Rect2 = T.info["rect"]
		_vue(Vector3(rr.get_center().x, T.info["y"] + 2.2, rr.get_center().y) - rg * 0.0 + Vector3(0, 0, 0) + (Vector3(rr.end.x - 1.5, 0, rr.end.y - 1.5) - Vector3(rr.get_center().x, 0, rr.get_center().y)), Vector3(rr.position.x, T.info["y"], rr.position.y))
		await _photo("toit_%s_b" % ty)
		await T.aller(0)
		await T.leave()


# =================================================================== V156 : la beauté et la vie

## Une tour et un étage de ce type (la plus haute tour qui en a un).
func _etage_de(T: Node, ty: String) -> Array:
	var best: Array = []
	for t in T.tours:
		var n: int = (t["etages"] as Array).size()
		for k in range(n):
			if T.type_etage(int(t["id"]), k) == ty:
				if best.is_empty() or n > (T.tours[int(best[0])]["etages"] as Array).size():
					best = [int(t["id"]), k]
				break
	return best


func _vie(T: Node, fm: Node) -> void:
	for ty in ["hall", "bureaux", "labo", "studio", "jardin", "sport", "piscine"]:
		var tk: Array = _etage_de(T, ty) if ty != "hall" else []
		if ty == "hall":
			for t in T.tours:
				if str(t["type"]) == "bureaux" and (tk.is_empty() or (t["etages"] as Array).size() > (T.tours[int(tk[0])]["etages"] as Array).size()):
					tk = [int(t["id"]), 0]
		if tk.is_empty():
			print("RENDU pas de ", ty)
			continue
		await T.enter(int(tk[0]))
		if int(tk[1]) > 0:
			await T.aller(int(tk[1]))
		for k in range(4):
			await process_frame
		await _coin(T, ty, 1.7)
		await _depuis_ascenseur(T, ty + "_b")
		if ty == "piscine":
			var B: Rect2 = T.info["bassin"]
			var y: float = T.info["y"]
			_vue(Vector3(B.position.x - 0.6, y + 1.7, B.position.y - 0.6), Vector3(B.get_center().x, y - 0.6, B.get_center().y))
			await _photo("piscine_c")
		if ty == "bureaux":
			# la nuit
			await T.aller(int(tk[1]) + (1 if int(tk[1]) > 1 else 2))
			fm.temps_v56.hour = 23.0
			await T.aller(int(tk[1]))
			await _coin(T, "bureaux_nuit", 1.7)
			fm.temps_v56.hour = 15.0
		if ty == "hall":
			# l'ascenseur ouvert
			var a: Vector3 = T.info["ascenseur"]
			var rg: Vector3 = T.info["regard"]
			T._portes_asc(true, 0.0, 0.0)
			for k2 in range(3):
				await process_frame
			_vue(a + rg * 1.6 + Vector3.UP * 1.65 + rg.cross(Vector3.UP) * 0.6, a - rg * 1.3 + Vector3.UP * 1.2)
			await _photo("ascenseur_ouvert")
		if int(tk[1]) > 0:
			await T.aller(0)
		await T.leave()


# =================================================================== V157 : Néopolis dehors

func _dehors(T: Node, fm: Node) -> void:
	var choix: Array = []
	for q in ["ruelles", "residences", "hauts", "quai", "arcades"]:
		for t in T.tours:
			if str(t["quartier"]) == q and (t["etages"] as Array).size() >= 4:
				choix.append(t)
				break
	for nuit in [false, true]:
		fm.temps_v56.hour = 22.5 if nuit else 15.0
		for k in range(40):
			await process_frame
		for t in choix:
			var f: Vector3 = t["face"]
			var n: Vector3 = t["n"]
			var side: Vector3 = n.cross(Vector3.UP)
			_vue(f + n * 9.0 + side * 5.0 + Vector3.UP * 1.7, f + Vector3.UP * 6.0 - side * 3.0)
			await _photo("%s_%s" % [t["quartier"], "nuit" if nuit else "jour"])
			if str(t["quartier"]) in ["residences", "hauts"]:
				_vue(f + n * 3.0 + Vector3.UP * 12.0 + side * 2.0, f + Vector3.UP * 13.0 - side * 4.0 - n * 0.5)
				await _photo("%s_%s_fenetres" % [t["quartier"], "nuit" if nuit else "jour"])


# =================================================================== V161 : la rue (les feux, les bornes, le sol)

func _rue(N: Node3D, fm: Node) -> void:
	var up := Vector3.UP
	for nuit in [false, true]:
		fm.temps_v56.hour = 22.5 if nuit else 15.0
		for k in range(40):
			await process_frame
		var j: String = "nuit" if nuit else "jour"
		_vue(N._ground(9.0, 80.0) + up * 1.7, N._ground(0.0, 61.0) + up * 2.2)
		await _photo("carrefour_" + j)
		_vue(N._ground(8.2, 98.0) + up * 1.7, N._ground(8.6, 130.0) + up * 0.8)
		await _photo("boulevard_" + j)
		if not nuit:
			_vue(N._ground(66.0, 98.0) + up * 1.7, N._ground(60.0, 122.0) + up * 1.0)
			await _photo("rue_" + j)
			_vue(N._ground(5.0, 26.0) + up * 1.6, N._ground(2.6, 31.0))
			await _photo("sol_" + j)
