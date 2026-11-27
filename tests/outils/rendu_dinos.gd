extends SceneTree
## V217 : les animaux du Parc du Volcan en atelier (lancé par tests/outils/rendu_dinos.sh) : chacun seul,
## sur un sol neutre, de côté, de trois quarts avant, de face et de trois quarts arrière, pour juger leurs
## formes (sans les plantes du parc qui les cachent en partie).

const P := "res://scripts/prehistoire_v217.gd"

var out: String = ""
var cam: Camera3D


func _attendre(n: int) -> void:
	for k in range(n):
		await process_frame


func _photo(nom: String, at: Vector3, vers: Vector3) -> void:
	cam.global_position = at
	cam.look_at(vers)
	await _attendre(4)
	root.get_texture().get_image().save_png("%s/%s.png" % [out, nom])
	print("RENDU ", nom)


func _initialize() -> void:
	out = str(OS.get_cmdline_user_args()[0])
	var seul: String = str(OS.get_cmdline_user_args()[1]) if OS.get_cmdline_user_args().size() > 1 else ""
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.7, 0.78)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.82, 0.88)
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 35, 0)
	sun.shadow_enabled = true
	root.add_child(sun)
	var sol := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	sol.mesh = pm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.46, 0.43, 0.4)
	sol.material_override = sm
	root.add_child(sol)
	cam = Camera3D.new()
	cam.fov = 45.0
	cam.near = 0.05
	cam.far = 500.0
	root.add_child(cam)
	cam.current = true
	var pre = load(P).new()
	root.add_child(pre)
	var liste: Array = [["long_cou", pre._mesh_long_cou(), pre._peau()], ["grosse_dent", pre._mesh_theropode(false), pre._peau()],
		["raptor", pre._mesh_theropode(true), pre._peau()], ["corne", pre._mesh_corne(), pre._peau()], ["plaques", pre._mesh_plaques(), pre._peau()],
		["grand_bec", pre._mesh_grand_bec(), pre._peau()], ["squelette", pre._mesh_squelette(), pre._os()], ["oeuf", pre._mesh_oeuf(), pre._peau()]]
	var x: float = 0.0
	for e in liste:
		if seul != "" and not str(e[0]) in seul.split(","):
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = e[1]
		mi.material_override = e[2]
		root.add_child(mi)
		var ech: float = 0.3 if str(e[0]) == "raptor" else 1.0
		mi.transform = Transform3D(Basis().scaled(Vector3.ONE * ech), Vector3(x, 0, 0))
		await _attendre(2)
		var bo: AABB = mi.global_transform * mi.get_aabb()
		var c: Vector3 = bo.get_center()
		var r: float = maxf(bo.size.length() * 0.5, 0.4)
		var d: float = r / tan(deg_to_rad(cam.fov * 0.5)) * 1.05
		print("RENDU ", e[0], " : taille ", bo.size.snapped(Vector3(0.01, 0.01, 0.01)), " triangles ", (e[1] as ArrayMesh).surface_get_array_len(0) / 3)
		for v in [["1_cote", 90.0, 0.08], ["2_trois_quarts", 35.0, 0.12], ["3_face", 0.0, 0.08], ["4_arriere", 150.0, 0.2]]:
			var a: float = deg_to_rad(float(v[1]))
			var at: Vector3 = c + Vector3(sin(a), float(v[2]), cos(a)).normalized() * d
			at.y = maxf(at.y, 0.6)
			await _photo("%s_%s" % [e[0], v[0]], at, c)
		mi.visible = false
		x += 60.0
	quit()
