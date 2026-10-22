extends "res://scripts/pnj/pnj_tazira_v60.gd"
## V61 : un habitant de Cliquetis, la cité des ingénieurs fous. Même vie réglée par l'heure
## (pnj_azur_v56.gd, pnj_tazira_v60.gd), avec deux postures en plus :
##  - bricoler : penché sur un établi, un marteau qui tape, une clé qui tourne ;
##  - observer : la tête levée, une main en visière (le ciel, le Zéphyr, Achille qui passe).
## Et la tenue des ingénieurs : haut-de-forme, lunettes d'aviateur sur le front, monocle,
## blouse de laboratoire, nœud papillon, bras mécanique de laiton, chaudière dorsale qui fume,
## casque d'aviateur.


func setup_azur(manager: Node, data: Dictionary) -> void:
	super.setup_azur(manager, data)
	_build_cq_poses()
	_cq_accessories(data.get("cq", {}))


func _build_cq_poses() -> void:
	if anim == null or skel == null or anim.has_animation_library("cq"):
		return
	var lib = HeroLib.new()
	lib.hero = model
	lib.anim = anim
	lib.skel = skel
	var poses := AnimationLibrary.new()
	# bricoler : penché, la main droite qui tape, la gauche qui tient la pièce
	var b_a := {"Spine02": Vector3(24, 0, 0), "Spine01": Vector3(8, 0, 0), "Head": Vector3(18, 0, 0),
		"RightArm": Vector3(-70, 0, 10), "RightForeArm": Vector3(-60, 0, 0), "LeftArm": Vector3(-46, 0, -10), "LeftForeArm": Vector3(-80, 0, 0),
		"LeftUpLeg": Vector3(-6, 0, 0), "LeftLeg": Vector3(10, 0, 0), "RightUpLeg": Vector3(-6, 0, 0), "RightLeg": Vector3(10, 0, 0)}
	var b_b := lib._merge(b_a, {"RightArm": Vector3(-96, 0, 10), "RightForeArm": Vector3(-30, 0, 0)})
	var b_c := lib._merge(b_a, {"LeftForeArm": Vector3(-92, 20, 0), "Head": Vector3(22, 6, 0)})
	poses.add_animation("bricoler", lib._clip(2.0, true, [[0.0, b_a, Vector3.ZERO], [0.25, b_b, Vector3.ZERO], [0.4, b_a, Vector3.ZERO], [0.65, b_b, Vector3.ZERO], [0.8, b_a, Vector3.ZERO], [1.4, b_c, Vector3.ZERO], [2.0, b_a, Vector3.ZERO]]))
	# observer : la tête levée, la main droite en visière
	var o_a := {"Head": Vector3(-26, 0, 0), "Spine02": Vector3(-6, 0, 0), "RightArm": Vector3(-120, 0, 30), "RightForeArm": Vector3(-110, 0, 0), "LeftArm": Vector3(-14, 0, -8), "LeftForeArm": Vector3(-20, 0, 0)}
	var o_b := lib._merge(o_a, {"Head": Vector3(-24, 18, 0), "Spine02": Vector3(-6, 8, 0)})
	var o_c := lib._merge(o_a, {"Head": Vector3(-28, -16, 0), "Spine02": Vector3(-6, -6, 0)})
	poses.add_animation("observer", lib._clip(9.0, true, [[0.0, o_a, Vector3.ZERO], [3.0, o_b, Vector3.ZERO], [6.0, o_c, Vector3.ZERO], [9.0, o_a, Vector3.ZERO]]))
	anim.add_animation_library("cq", poses)
	lib.free()


func _activity(delta: float, dist: float, to_player: Vector3) -> void:
	match pose:
		"bricoler":
			if dist < 2.5:
				_face(to_player, delta, 3.0)
				_play("v28/idle", 0.4)
			else:
				_play("cq/bricoler", 0.4)
		"observer":
			_play("cq/observer", 0.5)
		_:
			super._activity(delta, dist, to_player)


## Fiche "cq" : haut_de_forme [r,g,b], lunettes_aviateur, monocle, blouse [r,g,b],
## noeud_papillon [r,g,b], bras_mecanique, sac_vapeur, casque_aviateur [r,g,b].
func _cq_accessories(t: Dictionary) -> void:
	if skel == null or t.is_empty():
		return
	var brass := _mat(Color(0.85, 0.66, 0.32), 0.3)
	brass.metallic = 0.85
	var copper := _mat(Color(0.78, 0.45, 0.28), 0.35)
	copper.metallic = 0.75
	var glass := _mat(Color(0.55, 0.8, 0.85), 0.05)
	glass.metallic_specular = 1.0
	if t.has("haut_de_forme") and v64.is_empty():
		var c: Array = t["haut_de_forme"]
		var hm := _mat(Color(float(c[0]), float(c[1]), float(c[2])), 0.6)
		var hat := Node3D.new()
		_part(hat, _cyl(0.3, 0.3, 0.025), hm, Vector3(0, 0.4, -0.06))
		_part(hat, _cyl(0.19, 0.2, 0.36), hm, Vector3(0, 0.58, -0.07))
		_part(hat, _cyl(0.205, 0.205, 0.06), _mat(Color(0.55, 0.15, 0.12), 0.6), Vector3(0, 0.45, -0.07))
		if t.has("engrenage_chapeau"):
			var g := TorusMesh.new()
			g.inner_radius = 0.04
			g.outer_radius = 0.07
			_part(hat, g, brass, Vector3(0.2, 0.47, -0.07), Vector3.ONE, Vector3(0, 0, 90))
		_attach("Head", Vector3(0, 18.0, 2.5), hat)
	if t.has("casque_aviateur") and v64.is_empty():
		var c2: Array = t["casque_aviateur"]
		var cm := _mat(Color(float(c2[0]), float(c2[1]), float(c2[2])), 0.7)
		var ca := Node3D.new()
		_part(ca, _sphere(0.29), cm, Vector3(0, 0.12, -0.1), Vector3(1.22, 1.06, 1.02))
		for sx in [-1.0, 1.0]:
			_part(ca, _box_mesh_np(Vector3(0.06, 0.24, 0.12)), cm, Vector3(sx * 0.31, -0.06, -0.02))
		_attach("Head", Vector3(0, 18.0, 2.5), ca)
	if t.has("lunettes_aviateur"):
		var lu := Node3D.new()
		var strap := _mat(Color(0.3, 0.2, 0.12), 0.8)
		var band := TorusMesh.new()
		band.inner_radius = 0.255
		band.outer_radius = 0.278
		_part(lu, band, strap, Vector3(0, 0.27, -0.05), Vector3(1.06, 1.0, 1.04), Vector3(-14, 0, 0))
		for sx2 in [-1.0, 1.0]:
			_part(lu, _cyl(0.07, 0.07, 0.07), brass, Vector3(sx2 * 0.09, 0.32, 0.21), Vector3.ONE, Vector3(70, 0, 0))
			_part(lu, _cyl(0.055, 0.055, 0.075), glass, Vector3(sx2 * 0.09, 0.325, 0.215), Vector3.ONE, Vector3(70, 0, 0))
		_attach("Head", Vector3(0, 18.0, 2.5), lu)
	if t.has("monocle") and not v64.is_empty():
		var ey: Array = _tete64.get("yeux", [0.0, 0.04, 0.07])
		var dx: float = float(_tete64.get("yeux_dx", 0.031))
		var mo2 := Node3D.new()
		var tm0 := TorusMesh.new()
		tm0.inner_radius = 0.017
		tm0.outer_radius = 0.02
		_part(mo2, tm0, brass, Vector3(dx, 0, 0), Vector3.ONE, Vector3(90, 0, 0))
		_part(mo2, _box_mesh_np(Vector3(0.0015, 0.12, 0.0015)), brass, Vector3(dx + 0.02, -0.06, -0.01))
		_attach("Head", Vector3(0, float(ey[1]) * 100.0, (float(ey[2]) + 0.014) * 100.0), mo2, Vector3.ZERO, true)
	elif t.has("monocle"):
		var mo := Node3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.035
		tm.outer_radius = 0.045
		_part(mo, tm, brass, Vector3(0.072, 0.006, 0.24), Vector3.ONE, Vector3(90, 0, 0))
		_part(mo, _box_mesh_np(Vector3(0.006, 0.2, 0.006)), brass, Vector3(0.11, -0.1, 0.2))
		_attach("Head", Vector3(0, 18.0, 2.5), mo)
	if t.has("blouse") and v64.is_empty():
		var c3: Array = t["blouse"]
		var bm := _mat(Color(float(c3[0]), float(c3[1]), float(c3[2])), 0.9)
		var bl := Node3D.new()
		_part(bl, _cyl(0.24, 0.34, 0.9), bm, Vector3(0, -0.42, 0))
		_attach("Hips", Vector3(0, 6.0, 0.0), bl)
		var top := Node3D.new()
		_part(top, _sphere(0.22), bm, Vector3.ZERO, Vector3(1.06, 1.1, 0.84))
		_attach("Spine02", Vector3(0, 0.0, 2.0), top)
	if t.has("noeud_papillon"):
		var c4: Array = t["noeud_papillon"]
		var nm := _mat(Color(float(c4[0]), float(c4[1]), float(c4[2])), 0.6)
		var np := Node3D.new()
		for sx3 in [-1.0, 1.0]:
			_part(np, _sphere(0.045), nm, Vector3(sx3 * 0.05, 0, 0), Vector3(1.4, 0.9, 0.5), Vector3(0, 0, sx3 * 20.0))
		_part(np, _sphere(0.022), nm, Vector3.ZERO)
		_attach("neck", Vector3(0, -2.0, 9.0), np)
	if t.has("bras_mecanique"):
		var ba := Node3D.new()
		_part(ba, _cyl(0.07, 0.06, 0.3), brass, Vector3(0, -0.15, 0))
		for k in range(3):
			_part(ba, _cyl(0.075, 0.075, 0.02), copper, Vector3(0, -0.05 - k * 0.1, 0))
		_attach("RightForeArm", Vector3(0, 12.0, 0), ba)
		var sh := Node3D.new()
		_part(sh, _sphere(0.09), brass, Vector3.ZERO)
		_attach("RightArm", Vector3(0, 2.0, 0), sh)
	if t.has("sac_vapeur"):
		var sv := Node3D.new()
		_part(sv, _cyl(0.13, 0.13, 0.42), copper, Vector3(0, 0, 0))
		_part(sv, _sphere(0.13), copper, Vector3(0, 0.21, 0), Vector3(1, 0.5, 1))
		_part(sv, _cyl(0.03, 0.03, 0.25), _mat(Color(0.1, 0.1, 0.1), 0.5), Vector3(0.08, 0.3, 0))
		for k2 in range(2):
			_part(sv, _cyl(0.14, 0.14, 0.02), brass, Vector3(0, -0.12 + k2 * 0.2, 0))
		_attach("Spine02", Vector3(0, 2.0, -20.0), sv)
