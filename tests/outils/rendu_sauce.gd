extends SceneTree
## V217 : le héros couvert de sauce tomate (sauce_heros_v217.gdshader), en photo (lancé par
## tests/outils/rendu_sauce.sh) : quatre héros en rang (propre, tout juste sorti de la sauce, à moitié sec,
## presque sec), de face, de trois quarts, de dos ; puis de près ; puis les mains de la VR (vr_mains_v199).

const HeroLib = preload("res://scripts/hero_v28.gd")
const Mains = preload("res://scripts/vr_mains_v199.gd")
const SHADER := "res://shaders/sauce_heros_v217.gdshader"
const QUANTITES := [0.0, 1.0, 0.55, 0.25]

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


func _couche(q: float, grain: float, main_vr: Node3D = null) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(SHADER)
	m.set_shader_parameter("quantite", q)
	m.set_shader_parameter("grain", grain)
	m.set_shader_parameter("epaisseur", 0.004 if main_vr == null else 0.0015)
	m.set_shader_parameter("espace", 0 if main_vr == null else 1)
	if main_vr != null:
		m.set_shader_parameter("repere", Projection(main_vr.global_transform.affine_inverse()))
	m.render_priority = 20
	return m


func _habiller(n: Node, q: float, grain: float = 30.0, main_vr: Node3D = null) -> int:
	var m: ShaderMaterial = _couche(q, grain, main_vr)
	var c: int = 0
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_overlay = m
		c += 1
	return c


func _initialize() -> void:
	out = str(OS.get_cmdline_user_args()[0])
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.62, 0.7)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.85, 0.9)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 28, 0)
	sun.shadow_enabled = true
	root.add_child(sun)
	var sol := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	sol.mesh = pm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.78, 0.7, 0.52)
	sol.material_override = sm
	root.add_child(sol)
	cam = Camera3D.new()
	cam.fov = 40.0
	cam.near = 0.02
	cam.far = 200.0
	root.add_child(cam)
	cam.current = true
	await _attendre(2)
	var hauteur: float = 1.8
	for i in range(QUANTITES.size()):
		var h: Node3D = (load("res://assets/models/characters/hero.glb") as PackedScene).instantiate()
		root.add_child(h)
		h.position = Vector3(i * 1.3, 0, 0)
		var ap: AnimationPlayer = h.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var sks: Array = h.find_children("*", "Skeleton3D", true, false)
		if ap != null and sks.size() > 0:
			var lib = HeroLib.new()
			lib.hero = h
			lib.anim = ap
			lib.skel = sks[0]
			lib._build_animations()
			ap.play("v28/idle", 0.0)
			ap.seek(0.4, true)
			ap.pause()
		print("RENDU héros ", i, " : sauce ", QUANTITES[i], " sur ", _habiller(h, float(QUANTITES[i])), " maillages")
		if i == 0:
			for mi in h.find_children("*", "MeshInstance3D", true, false):
				var mm: MeshInstance3D = mi
				print("RENDU maillage ", mm.name, " échelle ", mm.global_transform.basis.get_scale(), " surfaces ", mm.mesh.get_surface_count(), " override ", mm.material_override, " peau ", mm.skin != null)
				for si in range(mm.mesh.get_surface_count()):
					var ma: Material = mm.get_active_material(si)
					if ma is BaseMaterial3D:
						print("RENDU   surface ", si, " ", ma.resource_name, " transparence ", (ma as BaseMaterial3D).transparency, " profondeur ", (ma as BaseMaterial3D).depth_draw_mode, " priorité ", ma.render_priority, " culling ", (ma as BaseMaterial3D).cull_mode)
					else:
						print("RENDU   surface ", si, " ", ma)
		if i == 0:
			await _attendre(2)
			var b: AABB = AABB()
			var premier: bool = true
			for mi in h.find_children("*", "MeshInstance3D", true, false):
				var bb: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
				b = bb if premier else b.merge(bb)
				premier = false
			hauteur = clampf(b.end.y, 0.8, 3.0)
			print("RENDU taille du héros ", snappedf(hauteur, 0.01), " m")
	var mil: Vector3 = Vector3(1.95, hauteur * 0.5, 0)
	await _photo("01_face", mil + Vector3(0, 0.25, 7.2), mil)
	await _photo("02_trois_quarts", mil + Vector3(4.6, 0.6, 5.6), mil)
	await _photo("03_dos", mil + Vector3(0, 0.4, -7.2), mil)
	var un: Vector3 = Vector3(1.3, hauteur * 0.62, 0)
	await _photo("04_pres_face", un + Vector3(0.3, 0.1, 2.3), un)
	await _photo("05_pres_dos", un + Vector3(-0.4, 0.2, -2.3), un)
	# les mains de la VR : une propre, une couverte, et la paire couverte comme le joueur la voit
	var mains_q: Array = [[Vector3(20.0, 1.2, 0.0), false, 0.0], [Vector3(20.25, 1.2, 0.0), true, 1.0], [Vector3(20.6, 1.2, 0.0), false, 1.0], [Vector3(20.85, 1.2, 0.0), true, 0.5]]
	for mq in mains_q:
		var ctrl := XRController3D.new()
		root.add_child(ctrl)
		ctrl.position = mq[0]
		ctrl.rotation_degrees = Vector3(-20, 0, 0)
		var m = Mains.new()
		m.setup(ctrl, bool(mq[1]))
		m.essai_ferme = 0.15
		print("RENDU main ", mq[1], " : sauce ", mq[2], " sur ", _habiller(m, float(mq[2]), 15.0, m), " maillages")
	await _attendre(3)
	await _photo("06_mains", Vector3(20.42, 1.36, 0.62), Vector3(20.42, 1.18, 0.0))
	await _photo("07_mains_dessus", Vector3(20.42, 1.62, 0.2), Vector3(20.42, 1.15, -0.05))
	quit()
