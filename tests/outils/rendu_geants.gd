extends SceneTree
## Des images de l'Île des Géants (V142), pour juger l'effet (lancé par tests/outils/rendu_geants.sh) :
## l'île vue de haut, l'arrivée au ponton, la ferme, le potager, le moulin, la mare, le verger, les
## géants à leur travail, un géant agenouillé qui parle au tout petit visiteur (un repère de 1,75 m).
## V174 : « fenetres » : ce qu'on voit par les fenêtres de la maison et du moulin (generate_textures_v174.py
## vues) ; « portes » : la chatière de la maison et le trou de souris du moulin (les portes des Petits).
## V177 : « chateau » : le château de sable de Pâquerette (la motte, la porte du rempart, la cour, la porte
## du donjon, ses hublots) ; « vue_donjon » : ce qu'on voit par sa meurtrière (generate_textures_v174.py vues).

const Geants = preload("res://scripts/geants_v142.gd")
const Ile = preload("res://scripts/ile_geants_v142.gd")
const Kit = preload("res://scripts/geants_kit_v142.gd")


class FakeMain:
	extends Node3D
	var xr_active: bool = false
	var cam: Camera3D
	var geants: Node
	var npcs_v31: Array = []
	var pending_pnj_v31: Dictionary = {}
	var game_started: bool = false
	var temps_v56: Node

	func _player_pos_v27() -> Vector3:
		return cam.global_position if cam != null else Vector3.ZERO

	func _height_at(x: float, z: float) -> float:
		return geants.ile.height(x, z) if geants != null and geants.ile != null else 0.0

	func _npc_ctx_v31() -> Dictionary:
		return {"now": 0.0, "objets": {}, "vr": false}

	func sfx(_n: String, _at: Variant = null, _db: float = 0.0) -> void:
		pass

	func _show_message_v28(_t: String) -> void:
		pass


class FakeTemps:
	extends Node
	var hour: float = 10.0


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
	tp.hour = 9.5
	fm.add_child(tp)
	fm.temps_v56 = tp
	cam = Camera3D.new()
	cam.fov = 60.0
	cam.far = 3000.0
	cam.near = 0.1
	root.add_child(cam)
	cam.current = true
	fm.cam = cam
	for k in range(4):
		await process_frame
	g = Geants.new()
	fm.add_child(g)
	fm.geants = g
	g.setup(fm)
	g.build_island()
	g.build_town()
	for n in g.habitants:
		n.body64_build()
	var C: Vector3 = Ile.CENTER
	for k2 in range(20):
		await process_frame
	if quoi in ["tout", "vues"]:
		await _vue("01_dessus", C + Vector3(-60, 380, 300), C + Vector3(0, 0, 0))
		await _vue("02_ponton", g.dock()[1] + Vector3(4, 2.2, -6), C + Vector3(0, 30, 0))
		await _vue("03_chemin", _sol(20, -150) + Vector3(0, 1.7, 0), C + Vector3(0, 25, 0))
		await _vue("04_cour", _sol(-20, -95) + Vector3(0, 1.7, 0), C + Vector3(5, 18, -20))
		await _vue("05_porte", _sol(-6, -50) + Vector3(0, 1.7, 0), C + Vector3(0, 14, -30))
		await _vue("06_potager", _sol(64, -60) + Vector3(0, 1.8, 0), C + Vector3(100, 6, -10))
		await _vue("07_choux", _sol(88, -30) + Vector3(0, 1.7, 0), C + Vector3(100, 2, -20))
		await _vue("08_citrouilles", _sol(70, 2) + Vector3(0, 1.8, 0), C + Vector3(90, 3, 25))
		await _vue("09_moulin", _sol(-100, -60) + Vector3(0, 1.7, 0), C + Vector3(-150, 50, -100))
		await _vue("10_mare", _sol(-80, 100) + Vector3(0, 1.8, 0), C + Vector3(-112, 4, 135))
		await _vue("11_verger", _sol(70, 80) + Vector3(0, 1.8, 0), C + Vector3(110, 14, 125))
		await _vue("12_ble", _sol(10, 62) + Vector3(0, 1.8, 0), C + Vector3(10, 4, 100))
		await _vue("13_linge", _sol(-46, 82) + Vector3(0, 1.8, 0), C + Vector3(-48, 9, 46))
		await _vue("14_grange", _sol(-70, -60) + Vector3(0, 1.8, 0), C + Vector3(-98, 12, 0))
		await _vue("15_chateau_sable", _sol(60, -214) + Vector3(0, 1.8, 0), C + Vector3(92, 4, -196))
		await _vue("16_porte_pres", _sol(4, -40) + Vector3(0, 1.7, 0), C + Vector3(0, 12, -28))
	if quoi == "fenetres":
		# V174 : ce qu'on voit par les fenêtres de la maison et du moulin (sans les géants : une image
		# fixe ne doit pas garder un géant planté devant la vitre) ; generate_textures_v174.py vues
		for n2 in g.habitants:
			n2.visible = false
		await process_frame
		var yf: float = Ile.PLATEAU_Y + 6.8 + 5.25
		var fxs := [-31.0, -16.0, 16.0, 31.0]
		for i2 in range(4):
			var fx: float = fxs[i2]
			await _vue("vue_nord_%d" % (i2 + 1), C + Vector3(fx, yf, -31.0), C + Vector3(fx, yf + 9.0, -131.0))
			await _vue("vue_sud_%d" % (i2 + 1), C + Vector3(fx, yf, 31.0), C + Vector3(fx, yf + 9.0, 131.0))
		await _vue("vue_est", C + Vector3(45.0, yf, -6.0), C + Vector3(145.0, yf + 9.0, -6.0))
		await _vue("vue_ouest", C + Vector3(-45.0, yf, -6.0), C + Vector3(-145.0, yf + 9.0, -6.0))
		var mc: Vector3 = Ile.W(Ile.MOULIN.x, Ile.MOULIN.y, Ile.MOULIN_Y - 0.5)
		var fa: Vector3 = Vector3(0.62, 0, 0.78).normalized()
		var am: float = atan2(fa.z, fa.x) + 0.35
		var dm := Vector3(cos(am), 0, sin(am))
		var rr: float = lerpf(12.5, 9.6, 14.0 / 38.0)
		await _vue("vue_moulin", mc + dm * (rr + 2.5) + Vector3.UP * 16.5, mc + dm * (rr + 102.5) + Vector3.UP * 10.0)
	if quoi == "portes":
		# V174 : les deux portes des Petits (lieux_v174) : la chatière de la maison, le trou de souris du moulin
		var dm: Vector3 = g.reperes["maison"]["porte"]
		var chm: Vector3 = g.reperes["maison"]["chatiere"]
		await _vue("40_chatiere", chm + Vector3(-1.2, 1.4, -4.5), chm + Vector3(0, 1.0, 0.6))
		await _vue("41_porte_maison", dm + Vector3(-6.0, 1.7, -14.0), dm + Vector3(0, 6.0, 0))
		var tr: Vector3 = g.reperes["moulin"]["trou"]
		var to: Vector3 = g.reperes["moulin"]["trou_out"]
		var side: Vector3 = Vector3.UP.cross(to).normalized()
		await _vue("42_trou_souris", tr + to * 3.2 + side * 1.4 + Vector3.UP * 1.2, tr - to * 1.6 + Vector3.UP * 1.0)
		await _vue("43_moulin_trou", tr + to * 14.0 + side * 5.0 + Vector3.UP * 1.7, tr + Vector3.UP * 6.0)
	if quoi == "vue_donjon":
		# V177 : ce qu'on voit par la meurtrière du donjon de Pâquerette (la mer, au nord) ; puis
		# python3 -B pcvr/tools/generate_textures_v174.py vues DOSSIER
		for n4 in g.habitants:
			n4.visible = false
		await process_frame
		var cd: Vector3 = _sol(Ile.CHATEAU_SABLE.x, Ile.CHATEAU_SABLE.y)
		var yv: float = cd.y - 0.3 + 2.0 + 5.75
		var rv: float = Kit.DONJON_R0 + (Kit.DONJON_R1 - Kit.DONJON_R0) * clampf((2.0 + 5.75 - 1.6) / 9.0, 0.0, 1.0)
		await _vue("vue_donjon", Vector3(cd.x, yv, cd.z - rv - 0.6), Vector3(cd.x, yv, cd.z - 104.0))
	if quoi == "chateau":
		# V177 : le château de sable de Pâquerette (la porte côté mer, la cour, le donjon et sa porte) ; la
		# cour est en haut de la motte (2 m au-dessus du pied)
		var cs: Vector3 = _sol(Ile.CHATEAU_SABLE.x, Ile.CHATEAU_SABLE.y)
		var haut: float = cs.y - 0.3 + 2.0
		for n3 in g.habitants:
			n3.visible = false
		await process_frame
		var bas: Array = []
		for k5 in range(16):
			var a5: float = TAU * k5 / 16.0
			for r5 in [Kit.MOTTE_R1, 15.0, Kit.MOTTE_R0]:
				var q5: Vector3 = _sol(Ile.CHATEAU_SABLE.x + cos(a5) * r5, Ile.CHATEAU_SABLE.y + sin(a5) * r5)
				bas.append("%d°/%.0f:%+.2f" % [int(rad_to_deg(a5)), r5, q5.y - cs.y])
		print("ILE_MANGA_V142: CHATEAU sol autour (par rapport au centre) ", " ".join(bas))
		await _vue("50_chateau_dessus", cs + Vector3(-22, 26, -30), cs)
		await _vue("51_chateau_mer", _motte(Ile.CHATEAU_SABLE.x - 4.0, Ile.CHATEAU_SABLE.y - 26.0) + Vector3(0, 1.7, 0), cs + Vector3(0, 4.0, 0))
		await _vue("52_porte_rempart", _motte(Ile.CHATEAU_SABLE.x + 1.0, Ile.CHATEAU_SABLE.y - 15.5) + Vector3(0, 1.7, 0), Vector3(cs.x, haut + 1.6, cs.z - 6.0))
		await _vue("53_porte_donjon", Vector3(cs.x - 0.6, haut + 1.65, cs.z - 7.1), Vector3(cs.x, haut + 1.4, cs.z - 4.0))
		await _vue("54_cour", Vector3(cs.x + 4.4, haut + 1.65, cs.z - 3.6), Vector3(cs.x + 2.0, haut + 1.2, cs.z + 5.0))
		await _vue("55_chateau_jouets", _sol(Ile.CHATEAU_SABLE.x + 4.0, Ile.CHATEAU_SABLE.y + 28.0) + Vector3(0, 2.0, 0), cs + Vector3(0, 3.0, 0))
		await _vue("56_motte_cote", _motte(Ile.CHATEAU_SABLE.x - 22.0, Ile.CHATEAU_SABLE.y - 12.0) + Vector3(0, 1.7, 0), cs + Vector3(0, 1.0, 0))
		await _vue("57_hublots", Vector3(cs.x + 5.2, haut + 1.65, cs.z + 2.4), Vector3(cs.x, haut + 1.9, cs.z + 3.6))
	if quoi in ["tout", "geants"]:
		var noms := ["mathurine_gt", "eustache_gt", "ernestine_gt", "paquerette_gt", "theophile_gt"]
		for i in range(noms.size()):
			var n: Node3D = g.by_id.get(noms[i])
			if n == null:
				continue
			var fwd := Vector3(sin(n.rotation.y), 0, cos(n.rotation.y))
			var at: Vector3 = n.global_position + fwd * 7.0
			at.y = fm._height_at(at.x, at.z) + 1.6
			# (le temps que le géant voie le visiteur et s'agenouille : la pose a le temps de se poser)
			cam.global_position = at
			for k3 in range(60):
				cam.look_at(n.global_position + Vector3.UP * float(n.face_height()) * 0.8)
				await process_frame
			await _vue("2%d_%s_pres" % [i, noms[i]], at, n.global_position + Vector3.UP * float(n.face_height()) * 0.8, 10)
			var at2: Vector3 = n.global_position + fwd * 30.0 + fwd.cross(Vector3.UP) * 10.0
			at2.y = fm._height_at(at2.x, at2.z) + 3.0
			await _vue("3%d_%s_loin" % [i, noms[i]], at2, n.global_position + Vector3.UP * float(n.taille) * 0.5, 40)
	quit()


## V177 : le dessus du sol ou de la motte du château de sable (repère île).
func _motte(x: float, z: float) -> Vector3:
	var w: Vector3 = _sol(x, z)
	var cs: Vector3 = _sol(Ile.CHATEAU_SABLE.x, Ile.CHATEAU_SABLE.y)
	var r: float = Vector2(x - Ile.CHATEAU_SABLE.x, z - Ile.CHATEAU_SABLE.y).length()
	var y: float = cs.y - 0.3 + 2.0 - maxf(0.0, r - Kit.MOTTE_R1) * (2.0 + Kit.MOTTE_BAS) / (Kit.MOTTE_R0 - Kit.MOTTE_R1)
	w.y = maxf(w.y, y)
	return w


func _sol(x: float, z: float) -> Vector3:
	var w: Vector3 = Ile.W(x, z)
	w.y = g.ile.height(w.x, w.z)
	return w


func _vue(nom: String, at: Vector3, look: Vector3, images: int = 6) -> void:
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
	# (celui du jeu, main.gd : AgX ; avec Filmic, le sable clair sortait blanc)
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.0
	env.fog_enabled = true
	env.fog_density = 0.0006
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
	pm.size = Vector2(2000, 2000)
	sea.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.1, 0.32, 0.46)
	m.roughness = 0.15
	sea.material_override = m
	root.add_child(sea)
	sea.position = Ile.CENTER + Vector3(0, -0.42, 0)
