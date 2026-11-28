extends SceneTree
## V219 : des images de la magie, pour juger l'effet (lancé par tests/outils/rendu_magie.sh). Un atelier (un
## sol, un ciel simple, un mur, un sanglier et un poteau de 1,80 m pour l'échelle) ; chaque sort, image par
## image : la boule de feu en vol, son explosion, le souffle de givre, la foudre, et l'ennemi touché (en feu,
## pris par la glace, électrisé). « avant » : les effets d'avant la V219 (le jeu sans magie_v219) ; « apres » :
## ceux de magie_v219.gd, par le même chemin que le jeu. Le temps avance d'un pas fixe (--fixed-fps) : les
## images sont prises aux mêmes instants d'un rendu à l'autre.

const Bete := preload("res://scripts/monstre_v140.gd")
const Fx := preload("res://scripts/combat_fx_v129.gd")
const Coups := preload("res://scripts/coups_v141.gd")
const Elements := preload("res://scripts/elements_v143.gd")
const Combat := preload("res://scripts/combat_v28.gd")


class FakeMain:
	extends Node3D
	var combat_fx_v129: Node = null
	var combat_v28: Node = null
	var coups_v141: Node = null
	var inventory_v28: Node = null
	var elements_v143: Node = null
	var magie_v219: Node = null
	var pc_body: Node = null
	var vr_body: Node = null
	var xr_active: bool = false

	func _height_at(_x: float, _z: float) -> float:
		return 0.0

	func sfx(_n: String, _at: Vector3 = Vector3.ZERO, _v: float = 0.0) -> void:
		pass

	func _show_message_v28(_t: String) -> void:
		pass

	func _player_pos_v27() -> Vector3:
		return Vector3(0, 0, 60)


class FakeMgr:
	extends Node3D
	var main: Node
	var active: bool = false

	func night() -> bool:
		return false

	func alert(_m: Node) -> void:
		pass

	func hurt_player(_a: int, _f: Vector3) -> void:
		pass

	func take_token(_b: Node) -> bool:
		return true

	func release_token(_b: Node) -> void:
		pass

	func shove(_v: Vector3) -> void:
		pass


var out: String = ""
var quoi: String = "tout"
var nuit: bool = false
var cam: Camera3D
var mgr: Node3D
var fm: FakeMain
var fx: Node
var el: Node
var M: Node
var sun: DirectionalLight3D
var n_img: int = 0
var bete: CharacterBody3D
## le jeu passe-t-il déjà par magie_v219 ? (sinon l'outil l'appelle lui-même, pour la mise au point)
var branche: bool = false


func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	out = str(a[0])
	quoi = str(a[1]) if a.size() > 1 else "tout"
	nuit = a.size() > 2 and str(a[2]) == "nuit"
	_monde()
	fm = FakeMain.new()
	root.add_child(fm)
	fx = Fx.new()
	fm.add_child(fx)
	fx.setup(fm)
	fm.combat_fx_v129 = fx
	var cp: Node = Coups.new()
	fm.add_child(cp)
	cp.setup(fm)
	fm.coups_v141 = cp
	var cb: Node = Combat.new()
	fm.add_child(cb)
	cb.set("main", fm)
	fm.combat_v28 = cb
	el = Elements.new()
	fm.add_child(el)
	el.setup(fm)
	fm.elements_v143 = el
	M = load("res://scripts/magie_v219.gd").new()
	fm.add_child(M)
	M.setup(fm)
	branche = (Elements as GDScript).source_code.contains("magie_v219")
	print("RENDU le jeu passe par magie_v219 : ", branche)
	mgr = FakeMgr.new()
	mgr.main = fm
	root.add_child(mgr)
	cam = Camera3D.new()
	cam.fov = 50.0
	root.add_child(cam)
	cam.current = true
	# l'échelle : un sanglier, un poteau de 1,80 m
	bete = Bete.new()
	mgr.add_child(bete)
	bete.setup(mgr, "sanglier", Vector3(2.2, 0, -1.0))
	bete.set_physics_process(false)
	bete.set_process(false)
	var poteau := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.08
	cm.bottom_radius = 0.08
	cm.height = 1.8
	poteau.mesh = cm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.5, 0.36, 0.22)
	poteau.material_override = pmat
	poteau.position = Vector3(-2.4, 0.9, -0.6)
	root.add_child(poteau)
	for i in 30:
		await process_frame
	if quoi in ["tout", "feu"]:
		await _feu("apres")
		await _feu("avant")
	if quoi in ["tout", "givre"]:
		await _givre("apres")
		await _givre("avant")
	if quoi in ["tout", "foudre"]:
		await _foudre("apres")
		await _foudre("avant")
	if quoi in ["tout", "ennemi"]:
		await _ennemi("apres")
		await _ennemi("avant")
	quit()


## « apres » : le jeu avec magie_v219 ; « avant » : sans.
func _version(version: String) -> bool:
	var neuf: bool = version == "apres"
	fm.magie_v219 = M if neuf else null
	return neuf


## Entre deux scènes : on laisse les effets finir, puis on enlève ce qui reste (les marques au sol).
func _menage(s: float = 1.6) -> void:
	await _attendre(s)
	for c in M.get_children():
		c.queue_free()
	M.marques.clear()
	M.givres.clear()
	await process_frame


func _vise(at: Vector3, d: float, haut: float = 0.3, tour: float = 0.55) -> void:
	cam.global_position = at + Vector3(sin(tour) * d, d * haut, cos(tour) * d)
	cam.look_at(at, Vector3.UP)


func _attendre(s: float) -> void:
	await create_timer(s).timeout


func _shot(nom: String) -> void:
	await process_frame
	n_img += 1
	var img: Image = root.get_texture().get_image()
	img.save_png("%s/%02d_%s.png" % [out, n_img, nom])
	print("RENDU ", nom)


func _feu(version: String) -> void:
	_vise(Vector3(0, 1.3, 0), 9.5)
	# la boule en vol : de la gauche vers le milieu
	var ball := Node3D.new()
	fm.add_child(ball)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.55, 0.2)
	light.light_energy = 2.2
	light.omni_range = 6.0
	ball.add_child(light)
	var core := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.17
	sm.height = 0.34
	core.mesh = sm
	var cm := StandardMaterial3D.new()
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.albedo_color = Color(1.0, 0.8, 0.4)
	cm.emission_enabled = true
	cm.emission = Color(1.0, 0.55, 0.15)
	cm.emission_energy_multiplier = 4.0
	core.material_override = cm
	ball.add_child(core)
	var depart := Vector3(-7.0, 1.4, 1.0)
	var but := Vector3(0.0, 0.5, 0.0)
	ball.global_position = depart
	ball.set_meta("dir_v219", (but - depart).normalized())
	var neuf: bool = _version(version)
	if neuf and not branche:
		M.habiller_boule(ball)
	else:
		fx.dress_fireball(ball)
	var dir: Vector3 = (but - depart).normalized()
	var fait: float = 0.0
	var pris: bool = false
	while ball.global_position.distance_to(but) > 0.3:
		await process_frame
		var pas: float = 17.0 / 30.0
		ball.global_position += dir * minf(pas, ball.global_position.distance_to(but))
		fait += pas
		if not pris and fait > 3.4:
			pris = true
			await _shot("feu_%s_1_en_vol" % version)
	ball.queue_free()
	if neuf and not branche:
		M.explosion(but)
	else:
		fx.explosion(but)
	for e in [["2_eclat", 0.03], ["3_boule", 0.1], ["4_flammes", 0.2], ["5_fumee", 0.4], ["6_colonne", 0.8], ["7_braises_au_sol", 2.0]]:
		await _attendre(float(e[1]))
		await _shot("feu_%s_%s" % [version, e[0]])
	await _menage()


func _givre(version: String) -> void:
	_vise(Vector3(0.5, 0.9, 0), 10.5, 0.36, 0.2)
	var o := Vector3(-4.5, 1.2, 0.4)
	var dir := Vector3(1, -0.05, -0.05).normalized()
	var neuf: bool = _version(version)
	if neuf:
		M.givre(o, dir)
	fx.frost(o, dir)
	for e in [["1_souffle", 0.07], ["2_cone", 0.17], ["3_brume", 0.35], ["4_givre_au_sol", 0.9], ["5_reste", 3.0]]:
		await _attendre(float(e[1]))
		await _shot("givre_%s_%s" % [version, e[0]])
	await _menage()


func _foudre(version: String) -> void:
	_vise(Vector3(0.0, 1.5, 0), 11.0, 0.3, 0.35)
	var a := Vector3(-6.0, 1.4, 1.0)
	var b := Vector3(2.2, 0.7, -1.0)
	var neuf: bool = _version(version)
	if neuf and not branche:
		M.eclair(a, b, 1.0)
		M.frappe_foudre(b)
	else:
		el.eclair(a, b, 1.0)
		el._frappe_fx(b)
	await _shot("foudre_%s_1_eclair" % version)
	for e in [["2_tremble", 0.04], ["3_arcs", 0.12], ["4_apres", 0.4]]:
		await _attendre(float(e[1]))
		await _shot("foudre_%s_%s" % [version, e[0]])
	await _menage()


## L'ennemi touché : en feu, pris par la glace, électrisé.
func _ennemi(version: String) -> void:
	var neuf: bool = _version(version)
	var r: float = maxf(float(bete.get("hit_radius")), 0.3)
	var h: float = maxf(float(bete.get("hit_height")), 0.3)
	var c: Vector3 = bete.global_position + Vector3.UP * h * 0.5
	_vise(c + Vector3.UP * 0.4, 6.5, 0.28, 0.5)
	# en feu
	el.enflammer(bete)
	var flammes: Array = []
	if neuf and not branche:
		flammes = M.embraser(bete, r, h)
	await _attendre(0.5)
	await _shot("ennemi_%s_1_en_feu" % version)
	await _attendre(0.9)
	await _shot("ennemi_%s_2_en_feu" % version)
	el._efface(bete)
	for f in flammes:
		if is_instance_valid(f):
			(f as Node).queue_free()
	await _menage(1.2)
	# pris par la glace
	el.geler(bete, 3.0)
	if neuf and not branche:
		M.saisir_glace(c, r, h)
	await _attendre(0.1)
	await _shot("ennemi_%s_3_saisi" % version)
	await _attendre(0.5)
	await _shot("ennemi_%s_4_gele" % version)
	el._efface(bete)
	await _menage(1.2)
	# électrisé
	if neuf and not branche:
		M.electriser(bete, r, h, 0.8)
	else:
		el._arcs(c, 7)
	await _attendre(0.1)
	await _shot("ennemi_%s_5_electrise" % version)
	await _attendre(0.25)
	await _shot("ennemi_%s_6_electrise" % version)
	await _menage(1.2)


func _monde() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	if nuit:
		psm.sky_top_color = Color(0.01, 0.015, 0.04)
		psm.sky_horizon_color = Color(0.04, 0.05, 0.09)
		psm.ground_bottom_color = Color(0.01, 0.01, 0.02)
		psm.ground_horizon_color = Color(0.04, 0.05, 0.09)
	sky.sky_material = psm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.35 if nuit else 1.0
	# comme dans le jeu (main.gd) : AgX, la lueur des matières vives
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.15
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 35, 0)
	sun.shadow_enabled = true
	sun.light_energy = 0.12 if nuit else 1.2
	sun.light_color = Color(0.6, 0.7, 1.0) if nuit else Color(1.0, 0.96, 0.9)
	root.add_child(sun)
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	g.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.33, 0.39, 0.22)
	gm.roughness = 0.95
	g.material_override = gm
	root.add_child(g)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(60, 1, 60)
	cs.shape = bs
	cs.position.y = -0.5
	body.add_child(cs)
	root.add_child(body)
	# un mur, pour voir la lumière des sorts sur le décor
	var mur := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(9, 3.2, 0.5)
	mur.mesh = bm
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(0.55, 0.52, 0.48)
	mm.roughness = 0.9
	mur.material_override = mm
	mur.position = Vector3(1.0, 1.6, -4.5)
	root.add_child(mur)
