extends "res://scripts/pnj/pnj_v31.gd"
## V56 : un habitant de Port-Azur qui vit selon l'heure. Sa fiche porte un « agenda » :
## [heure de début, heure de fin, lieu ou liste de lieux], et une maison (une porte).
## Le jour il travaille (au comptoir, à son étal, sur le quai…), il déjeune en terrasse,
## se promène, se baigne ; le soir il va au bar ou sur la promenade ; la nuit il rentre
## chez lui (on ne le voit plus) ou à l'hôtel. Il marche par les rues (graphe de port_azur)
## et, loin du joueur, il « saute » directement là où il devrait être.
## Postures : debout, assis (chaise, banc), allonge (serviette), boire (au comptoir),
## comptoir (accoudé), guitare, peindre, petanque, jouer (enfants), lire, course (joggeur).

const SPEED_WALK: float = 1.15
const SPEED_RUN: float = 3.0

var azur: Node                         # azur_v56.gd (lieux, heure)
var agenda: Array = []
var home: String = ""                  # point « porte_… » ou « villa_… »
var slot: int = -2
var target_spot: String = ""           # lieu de l'activité en cours
var pose: String = "debout"
var hidden_home: bool = false
var _check: float = 0.0
var _gest: float = 0.0
var _pair: Array = []                  # lieux entre lesquels on va et vient (enfants, service)
var _run_loop: Array = []              # boucle de jogging
var _run_i: int = 0
var _prop: Node3D                      # guitare, livre, pinceau…
var _rng2 := RandomNumberGenerator.new()


func setup_azur(manager: Node, data: Dictionary) -> void:
	azur = manager
	agenda = data.get("agenda", [])
	home = str(data.get("maison", ""))
	_rng2.seed = hash(str(data.get("id", "x")))
	sleep_far = 70.0
	var size_k: float = float((data.get("azur", {}) as Dictionary).get("taille", 1.0))
	if not v64.is_empty():
		size_k = body_height() / 1.7
	if bubble != null:
		bubble.position.y = 2.35 - (1.0 - size_k) * 1.8
	if vr_label != null:
		vr_label.position.y = 2.0 - (1.0 - size_k) * 1.8
	_build_extra_poses()
	_make_prop(str(data.get("accessoire", "")))


# =================================================================== postures en plus

func _build_extra_poses() -> void:
	if anim == null or skel == null or anim.has_animation_library("v56"):
		return
	var lib = HeroLib.new()
	lib.hero = model
	lib.anim = anim
	lib.skel = skel
	var poses := AnimationLibrary.new()
	var seated := {"LeftUpLeg": Vector3(-88, 0, 6), "RightUpLeg": Vector3(-88, 0, -6), "LeftLeg": Vector3(85, 0, 0), "RightLeg": Vector3(85, 0, 0),
		"LeftFoot": Vector3(-5, 0, 0), "RightFoot": Vector3(-5, 0, 0), "Spine02": Vector3(4, 0, 0)}
	var lean := {"Spine02": Vector3(16, 0, 0), "Spine01": Vector3(4, 0, 0), "LeftArm": Vector3(-42, 0, -6), "RightArm": Vector3(-42, 0, 6),
		"LeftForeArm": Vector3(-55, 0, 0), "RightForeArm": Vector3(-55, 0, 0), "Head": Vector3(-10, 0, 0)}
	var lean_b := lean.duplicate()
	lean_b["Head"] = Vector3(-8, 10, 0)
	lean_b["Spine02"] = Vector3(14, 3, 0)
	poses.add_animation("comptoir", lib._clip(5.0, true, [[0.0, lean, Vector3.ZERO], [2.5, lean_b, Vector3(0, -0.5, 0)], [5.0, lean, Vector3.ZERO]]))
	var g_a := lib._merge(seated, {"LeftArm": Vector3(-58, 30, 28), "LeftForeArm": Vector3(-70, 0, 0), "RightArm": Vector3(-22, 0, -28), "RightForeArm": Vector3(-92, 0, 0), "Head": Vector3(12, -8, 0)})
	var g_b := g_a.duplicate()
	g_b["RightForeArm"] = Vector3(-104, 0, 0)
	g_b["Head"] = Vector3(10, -4, 0)
	poses.add_animation("guitare", lib._clip(0.5, true, [[0.0, g_a, Vector3(0, -38, 0)], [0.25, g_b, Vector3(0, -38, 0)], [0.5, g_a, Vector3(0, -38, 0)]]))
	var p_a := {"RightArm": Vector3(-82, 0, -6), "RightForeArm": Vector3(-30, 0, 0), "LeftArm": Vector3(-28, 0, -10), "LeftForeArm": Vector3(-82, 0, 0), "Head": Vector3(4, 0, 0)}
	var p_b := p_a.duplicate()
	p_b["RightArm"] = Vector3(-92, 0, -14)
	p_b["RightForeArm"] = Vector3(-18, 0, 0)
	poses.add_animation("peindre", lib._clip(2.4, true, [[0.0, p_a, Vector3.ZERO], [0.7, p_b, Vector3.ZERO], [1.3, p_a, Vector3.ZERO], [1.8, p_b, Vector3.ZERO], [2.4, p_a, Vector3.ZERO]]))
	var cross := {"LeftArm": Vector3(-38, 0, -34), "RightArm": Vector3(-36, 0, 34), "LeftForeArm": Vector3(-118, 0, 0), "RightForeArm": Vector3(-122, 0, 0)}
	var cross_b := cross.duplicate()
	cross_b["Head"] = Vector3(0, 18, 0)
	poses.add_animation("bras_croises", lib._clip(6.0, true, [[0.0, cross, Vector3.ZERO], [3.0, cross_b, Vector3(0, -0.4, 0)], [6.0, cross, Vector3.ZERO]]))
	var read := lib._merge(seated, {"LeftArm": Vector3(-42, 0, -16), "RightArm": Vector3(-42, 0, 16), "LeftForeArm": Vector3(-100, 0, 0), "RightForeArm": Vector3(-100, 0, 0), "Head": Vector3(22, 0, 0)})
	var read_b := read.duplicate()
	read_b["Head"] = Vector3(20, 6, 0)
	poses.add_animation("lire", lib._clip(5.0, true, [[0.0, read, Vector3(0, -38, 0)], [2.5, read_b, Vector3(0, -38, 0)], [5.0, read, Vector3(0, -38, 0)]]))
	anim.add_animation_library("v56", poses)
	lib.free()


func _make_prop(kind: String) -> void:
	if skel == null or kind == "" or (kind == "tablier" and not v64.is_empty()):
		return
	var holder := Node3D.new()
	match kind:
		"guitare":
			var body := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.2
			sm.height = 0.12
			body.mesh = sm
			body.material_override = _mat(Color(0.62, 0.36, 0.16), 0.5)
			body.scale = Vector3(1.0, 1.0, 1.25)
			holder.add_child(body)
			var neck := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.05, 0.03, 0.55)
			neck.mesh = bm
			neck.material_override = _mat(Color(0.25, 0.16, 0.1))
			neck.position = Vector3(0, 0.02, -0.42)
			holder.add_child(neck)
			_attach("Spine02", Vector3(4.0, -6.0, 14.0), holder, Vector3(0, 70, -25))
		"livre":
			var b := MeshInstance3D.new()
			var bx := BoxMesh.new()
			bx.size = Vector3(0.18, 0.03, 0.24)
			b.mesh = bx
			b.material_override = _mat(Color(0.5, 0.15, 0.12))
			holder.add_child(b)
			_attach("RightHand", Vector3(0, -6, 4), holder, Vector3(60, 0, 0))
		"pinceau":
			var p := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.008
			cm.bottom_radius = 0.01
			cm.height = 0.25
			p.mesh = cm
			p.material_override = _mat(Color(0.7, 0.55, 0.3))
			holder.add_child(p)
			_attach("RightHand", Vector3(0, -8, 3), holder, Vector3(90, 0, 0))
		"chapeau":
			var h := MeshInstance3D.new()
			var cm2 := CylinderMesh.new()
			cm2.top_radius = 0.12
			cm2.bottom_radius = 0.24
			cm2.height = 0.1
			h.mesh = cm2
			h.material_override = _mat(Color(0.88, 0.78, 0.5))
			holder.add_child(h)
			_attach("Head", Vector3(0, 19, 1), holder)
		"casquette":
			var c := MeshInstance3D.new()
			var cm3 := CylinderMesh.new()
			cm3.top_radius = 0.1
			cm3.bottom_radius = 0.11
			cm3.height = 0.08
			c.mesh = cm3
			c.material_override = _mat(Color(0.12, 0.18, 0.35))
			holder.add_child(c)
			var v := MeshInstance3D.new()
			var vb := BoxMesh.new()
			vb.size = Vector3(0.16, 0.012, 0.09)
			v.mesh = vb
			v.material_override = _mat(Color(0.05, 0.05, 0.05))
			v.position = Vector3(0, -0.03, 0.1)
			holder.add_child(v)
			_attach("Head", Vector3(0, 17, 1), holder)
		"tablier":
			var t := MeshInstance3D.new()
			var tb := BoxMesh.new()
			tb.size = Vector3(0.36, 0.55, 0.02)
			t.mesh = tb
			t.material_override = _mat(Color(0.95, 0.94, 0.9))
			holder.add_child(t)
			_attach("Spine", Vector3(0, -12, 12), holder)
		_:
			holder.free()
			return
	_prop = holder


# =================================================================== l'allure

## Fiche "azur" : visage (couleur des yeux), cheveux [r,g,b], coiffure (court, long, chignon,
## queue, boucles, carre, chauve), barbe ("", moustache, courte, longue), chapeau ("",
## paille, casquette, beret, capeline, marin, cuisinier, kepi), haut [r,g,b], robe [r,g,b]
## (sinon pantalon du modèle), tablier [r,g,b], lunettes, foulard [r,g,b], taille, carrure.
func _accessories() -> void:
	if not profile.has("azur"):
		super._accessories()
		return
	var az: Dictionary = profile["azur"]
	if not v64.is_empty():
		# V64 : visage, cheveux, barbe et vêtements viennent du vrai corps ; restent lunettes et chapeau.
		if bool(az.get("lunettes", false)):
			_glasses64(_mat(Color(0.12, 0.1, 0.08), 0.4))
		return
	var c_hair: Array = az.get("cheveux", [0.3, 0.2, 0.12])
	var hair := _mat(Color(float(c_hair[0]), float(c_hair[1]), float(c_hair[2])), 0.6)
	var tint: Array = profile.get("teinte", [1.0, 0.85, 0.72])
	var skin := _mat(Color(float(tint[0]), float(tint[1]) * 0.94, float(tint[2]) * 0.9), 0.6)
	# le visage (grands yeux, sourcils, nez, bouche, joues)
	var face := Node3D.new()
	var R: float = 0.228
	_part(face, _sphere(R), skin, Vector3.ZERO)
	var eyes: Array = az.get("yeux", [0.35, 0.25, 0.15])
	var white := _mat(Color(0.98, 0.98, 0.97), 0.3)
	var iris := _mat(Color(float(eyes[0]), float(eyes[1]), float(eyes[2])), 0.2)
	var dark := _mat(Color(0.08, 0.06, 0.06), 0.4)
	dark.emission_energy_multiplier = 0.05
	var shine := _mat(Color(1, 1, 1), 0.1)
	shine.emission_energy_multiplier = 1.5
	var lips := _mat(Color(0.8, 0.42, 0.42), 0.5)
	var brow_mat := _mat(Color(float(c_hair[0]) * 0.8, float(c_hair[1]) * 0.75, float(c_hair[2]) * 0.7), 0.7)
	var old: bool = bool(az.get("vieux", false))
	var on_face := func(x: float, y: float, lift: float) -> Vector3:
		return Vector3(x, y, sqrt(maxf(R * R - x * x - y * y, 0.0)) + lift)
	for sx in [-1.0, 1.0]:
		var ex: float = sx * 0.072
		var eh: float = 0.95 if old else 1.2
		_part(face, _sphere(0.044), white, on_face.call(ex, 0.005, -0.012), Vector3(1.0, eh, 0.4))
		_part(face, _sphere(0.031), iris, on_face.call(ex, 0.0, -0.004), Vector3(1.0, eh, 0.35))
		_part(face, _sphere(0.016), dark, on_face.call(ex, -0.002, 0.002), Vector3(1.0, eh, 0.35))
		_part(face, _sphere(0.008), shine, on_face.call(ex + sx * -0.012, 0.014, 0.006))
		_part(face, _box_mesh_np(Vector3(0.1, 0.012, 0.012)), dark, on_face.call(ex, 0.055, -0.002), Vector3.ONE, Vector3(0, sx * -18.0, sx * -8.0))
		_part(face, _box_mesh_np(Vector3(0.08, 0.014 if not old else 0.02, 0.012)), brow_mat, on_face.call(ex, 0.098, -0.003), Vector3.ONE, Vector3(0, sx * -18.0, sx * 6.0))
		# oreilles rondes (V62 : pas pour les gens de Ramure, qui ont des oreilles d'animal)
		if not profile.has("kemo"):
			var ear := Node3D.new()
			_part(ear, _sphere(0.04), skin, Vector3.ZERO, Vector3(0.45, 1.0, 0.8))
			_attach("Head", Vector3(sx * 22.0, 18.0, 3.0), ear)
	_part(face, _sphere(0.016), skin, on_face.call(0.0, -0.032, 0.004), Vector3(0.9, 1.1, 1.3))
	for sx2 in [-1.0, 1.0]:
		_part(face, _box_mesh_np(Vector3(0.028, 0.008, 0.01)), lips, on_face.call(sx2 * 0.012, -0.08, -0.002), Vector3.ONE, Vector3(0, sx2 * -10.0, sx2 * 14.0))
	if bool(az.get("lunettes", false)):
		var frame := _mat(Color(0.12, 0.1, 0.08), 0.4)
		for sx3 in [-1.0, 1.0]:
			var tm := TorusMesh.new()
			tm.inner_radius = 0.036
			tm.outer_radius = 0.044
			tm.rings = 16
			tm.ring_segments = 4
			_part(face, tm, frame, on_face.call(sx3 * 0.072, 0.004, 0.012), Vector3.ONE, Vector3(90, 0, 0))
		_part(face, _box_mesh_np(Vector3(0.05, 0.008, 0.008)), frame, on_face.call(0.0, 0.012, 0.014))
	var beard: String = str(az.get("barbe", ""))
	if beard != "":
		match beard:
			"moustache":
				for sx4 in [-1.0, 1.0]:
					_part(face, _sphere(0.03), hair, on_face.call(sx4 * 0.03, -0.058, 0.004), Vector3(1.4, 0.55, 0.6), Vector3(0, 0, sx4 * -15.0))
			"courte":
				_part(face, _sphere(0.17), hair, Vector3(0, -0.1, 0.06), Vector3(1.15, 0.75, 0.95))
				for sx5 in [-1.0, 1.0]:
					_part(face, _sphere(0.03), hair, on_face.call(sx5 * 0.03, -0.058, 0.006), Vector3(1.4, 0.55, 0.6))
			_:
				_part(face, _sphere(0.16), hair, Vector3(0, -0.18, 0.08), Vector3(1.05, 1.5, 0.8))
	_attach("Head", Vector3(0, 18.0, 2.5), face)
	# la chevelure
	var style: String = str(az.get("coiffure", "court"))
	if style != "chauve":
		var fringe := Node3D.new()
		_part(fringe, _sphere(0.2), hair, Vector3.ZERO, Vector3(1.15, 0.38, 0.76))
		_attach("Head", Vector3(0, 35.0, 10.0), fringe, Vector3(-20, 0, 0))
	var hh := Node3D.new()
	if style == "chauve":
		_part(hh, _sphere(0.25), skin, Vector3(0, -0.02, 0), Vector3(1.12, 0.98, 0.98))
		for sx6 in [-1.0, 1.0]:
			_part(hh, _sphere(0.06), hair, Vector3(sx6 * 0.2, -0.12, -0.08), Vector3(0.55, 0.9, 1.1))
	else:
		_part(hh, _sphere(0.26), hair, Vector3.ZERO, Vector3(1.16, 1.06, 0.98))
	match style:
		"long":
			_part(hh, _sphere(0.2), hair, Vector3(0, -0.32, -0.1), Vector3(1.05, 1.9, 0.42), Vector3(8, 0, 0))
			for sx7 in [-1.0, 1.0]:
				_part(hh, _sphere(0.08), hair, Vector3(sx7 * 0.2, -0.18, 0.06), Vector3(0.55, 2.0, 0.6))
		"carre":
			_part(hh, _sphere(0.24), hair, Vector3(0, -0.14, -0.04), Vector3(1.12, 0.9, 0.95))
			for sx8 in [-1.0, 1.0]:
				_part(hh, _sphere(0.08), hair, Vector3(sx8 * 0.21, -0.14, 0.06), Vector3(0.55, 1.2, 0.7))
		"chignon":
			_part(hh, _sphere(0.11), hair, Vector3(0, 0.12, -0.2), Vector3(1.0, 0.9, 0.9))
		"queue":
			for k in range(6):
				var f: float = float(k) / 5.0
				_part(hh, _sphere(lerpf(0.075, 0.04, f)), hair, Vector3(0, 0.02 - f * 0.45, -0.3 - sin(f * 1.6) * 0.05), Vector3(1.0, 1.7, 0.85), Vector3(-10, 0, 0))
		"boucles":
			for k2 in range(14):
				var a: float = TAU * k2 / 14.0
				_part(hh, _sphere(0.085), hair, Vector3(cos(a) * 0.22, 0.06 + sin(a * 2.0) * 0.04, sin(a) * 0.2 - 0.04))
		_:
			_part(hh, _sphere(0.2), hair, Vector3(0, -0.08, -0.1), Vector3(1.15, 0.8, 0.8))
	_attach("Head", Vector3(0, 30.0, -7.0), hh)
	_azur_hat(az)
	# le haut (gilet, chemisier) et la robe
	if az.has("haut"):
		var tc: Array = az["haut"]
		var top := Node3D.new()
		_part(top, _sphere(0.215), _mat(Color(float(tc[0]), float(tc[1]), float(tc[2])), 0.85), Vector3.ZERO, Vector3(1.02 * float(az.get("carrure", 1.0)), 1.08, 0.8 * float(az.get("carrure", 1.0))))
		_attach("Spine02", Vector3(0, 0.0, 2.0), top)
	if az.has("robe"):
		var rc: Array = az["robe"]
		var skirt := Node3D.new()
		var rm := _mat(Color(float(rc[0]), float(rc[1]), float(rc[2])), 0.8)
		var long_dress: bool = bool(az.get("robe_longue", false))
		_part(skirt, _cyl(0.2, 0.36 if long_dress else 0.32, 0.8 if long_dress else 0.5), rm, Vector3(0, -0.4 if long_dress else -0.25, 0))
		_attach("Hips", Vector3(0, 4.0, 0.0), skirt)
	if az.has("tablier"):
		var ac: Array = az["tablier"]
		var ap := Node3D.new()
		_part(ap, _box_mesh_np(Vector3(0.36, 0.6, 0.02)), _mat(Color(float(ac[0]), float(ac[1]), float(ac[2])), 0.9), Vector3(0, -0.2, 0))
		_attach("Hips", Vector3(0, 8.0, 14.0), ap, Vector3(-4, 0, 0))
	if az.has("foulard"):
		var fc: Array = az["foulard"]
		var sc := Node3D.new()
		var tm2 := TorusMesh.new()
		tm2.inner_radius = 0.07
		tm2.outer_radius = 0.13
		_part(sc, tm2, _mat(Color(float(fc[0]), float(fc[1]), float(fc[2])), 0.8), Vector3.ZERO)
		_attach("neck", Vector3(0, 0.0, 1.0), sc)
	var size_k: float = float(az.get("taille", 1.0))
	if absf(size_k - 1.0) > 0.01:
		model.scale = Vector3.ONE * size_k


func _azur_hat(az: Dictionary) -> void:
	# le chapeau
	var hat_kind: String = str(az.get("chapeau", ""))
	if hat_kind != "":
		var hat := Node3D.new()
		var hc: Array = az.get("chapeau_c", [0.9, 0.78, 0.48])
		var hm := _mat(Color(float(hc[0]), float(hc[1]), float(hc[2])), 0.85)
		match hat_kind:
			"paille":
				_part(hat, _cyl(0.36, 0.38, 0.025), hm, Vector3.ZERO)
				_part(hat, _cyl(0.17, 0.2, 0.15), hm, Vector3(0, 0.08, 0))
				_part(hat, _cyl(0.202, 0.202, 0.04), _mat(Color(0.2, 0.25, 0.55)), Vector3(0, 0.03, 0))
			"capeline":
				_part(hat, _cyl(0.42, 0.44, 0.02), hm, Vector3.ZERO)
				_part(hat, _cyl(0.17, 0.19, 0.13), hm, Vector3(0, 0.07, 0))
				_part(hat, _cyl(0.192, 0.192, 0.04), _mat(Color(0.85, 0.3, 0.4)), Vector3(0, 0.03, 0))
			"casquette", "kepi", "marin":
				_part(hat, _cyl(0.2, 0.22, 0.12 if hat_kind != "kepi" else 0.18), hm, Vector3(0, 0.05, 0))
				_part(hat, _box_mesh_np(Vector3(0.24, 0.015, 0.14)), _mat(Color(0.06, 0.06, 0.07)), Vector3(0, -0.005, 0.2))
				if hat_kind == "marin":
					_part(hat, _cyl(0.23, 0.23, 0.03), _mat(Color(0.95, 0.95, 0.95)), Vector3(0, 0.12, 0))
			"beret":
				_part(hat, _sphere(0.24), hm, Vector3(0.03, 0.04, 0), Vector3(1.0, 0.32, 1.0))
			"cuisinier":
				_part(hat, _cyl(0.21, 0.2, 0.12), _mat(Color(0.97, 0.97, 0.96)), Vector3(0, 0.05, 0))
				_part(hat, _sphere(0.25), _mat(Color(0.97, 0.97, 0.96)), Vector3(0, 0.24, 0), Vector3(1.0, 0.7, 1.0))
		_attach("Head", Vector3(0, 39.0, 1.0), hat, Vector3(-6, 0, 0))


# =================================================================== l'emploi du temps

func _slot_now() -> int:
	var h: float = float(azur.hour())
	for i in range(agenda.size()):
		var e: Array = agenda[i]
		var a: float = float(e[0])
		var b: float = float(e[1])
		if (a <= b and h >= a and h < b) or (a > b and (h >= a or h < b)):
			return i
	return -1


func _slot_target(i: int) -> String:
	if i < 0:
		return ""
	var what: Variant = agenda[i][2]
	if what is Array:
		var arr: Array = what
		var free: Array = arr.filter(func(s): return azur.spot_free(str(s), self))
		if free.is_empty():
			free = arr
		return str(free[_rng2.randi() % free.size()])
	return str(what)


## Le lieu (ou « maison ») de l'activité ; renvoie le nœud du graphe à atteindre.
func _node_of(target: String) -> String:
	if target == "maison":
		return home
	if target.begins_with("course:"):
		return str(_run_loop[0]) if not _run_loop.is_empty() else home
	var sp: Dictionary = azur.spot(target)
	return str(sp.get("node", home))


func _start_slot(i: int, teleport: bool) -> void:
	slot = i
	_free_spot()
	target_spot = _slot_target(i)
	_pair.clear()
	_run_loop.clear()
	if target_spot.begins_with("course:"):
		_run_loop = target_spot.substr(7).split(",")
		_run_i = 0
	elif i >= 0 and agenda[i].size() > 3:
		for extra in agenda[i][3]:
			_pair.append(str(extra))
		_pair.append(target_spot)
	if target_spot != "" and target_spot != "maison" and not target_spot.begins_with("course:"):
		azur.claim_spot(target_spot, self)
	var goal: String = _node_of(target_spot) if target_spot != "" else home
	if goal == "" or not points.has(goal):
		goal = home if points.has(home) else at_point
	if teleport:
		_jump_to(goal)
		_arrive()
	else:
		_set_hidden(false)
		route = _route_to(goal)
		if route.is_empty() and goal != at_point:
			_jump_to(goal)
			_arrive()
		elif route.is_empty():
			_arrive()
		else:
			state = "marche"


func _free_spot() -> void:
	if target_spot != "" and azur != null:
		azur.release_spot(target_spot, self)


func _jump_to(node: String) -> void:
	if not points.has(node):
		return
	at_point = node
	route.clear()
	global_position = points[node]
	_snap_to_floor()


func _arrive() -> void:
	state = "repos"
	idle_clock = 1e9
	pose = "debout"
	if target_spot == "maison" or target_spot == "":
		_set_hidden(true)
		return
	_set_hidden(false)
	if target_spot.begins_with("course:"):
		return
	var sp: Dictionary = azur.spot(target_spot)
	if sp.is_empty():
		return
	pose = str(sp.get("pose", "debout"))
	var p: Vector3 = sp["pos"]
	if pose in ["assis", "allonge", "guitare", "lire"]:
		global_position = p
		_body.global_transform = Transform3D(Basis(Vector3.UP, rotation.y), global_position)
	var f: Vector3 = _spot_face(sp)
	f.y = 0.0
	if f.length() > 0.01:
		rotation.y = atan2(f.x, f.z)
	_gest = _rng2.randf_range(4.0, 12.0)
	current_anim = ""



## V75 : le « face » d'un lieu est un point à regarder (Port-Azur) ou une direction (les îles d'après,
## dont les lieux donnent un vecteur unité) : avant, les habitants de ces îles-là regardaient tous
## vers le centre du monde.
func _spot_face(sp: Dictionary) -> Vector3:
	var fv: Vector3 = sp.get("face", Vector3.ZERO)
	if fv.length() < 1.5:
		return fv
	return fv - global_position


func _set_hidden(h: bool) -> void:
	if h == hidden_home:
		return
	hidden_home = h
	visible = not h
	if _body != null:
		_body.process_mode = Node.PROCESS_MODE_DISABLED if h else Node.PROCESS_MODE_INHERIT
		for c in _body.get_children():
			if c is CollisionShape3D:
				(c as CollisionShape3D).disabled = h


func is_hittable() -> bool:
	return not hidden_home


# =================================================================== chaque image

func _process(delta: float) -> void:
	if azur == null or agenda.is_empty():
		super._process(delta)
		return
	_check -= delta
	if _check <= 0.0:
		_check = 1.0 + _rng2.randf() * 0.5
		var s: int = _slot_now()
		if s != slot and state != "parle":
			var far: bool = global_position.distance_to(main._player_pos_v27()) > sleep_far
			_start_slot(s, far or slot == -2)
	if hidden_home:
		return
	var far2: bool = global_position.distance_to(main._player_pos_v27()) > sleep_far
	if far2 != _asleep:
		_asleep = far2
		model.visible = not far2
		if anim != null:
			if far2:
				if anim.is_playing():
					anim.pause()
			else:
				current_anim = ""
	if far2:
		# loin du joueur : on finit le trajet d'un coup
		if state == "marche" and not route.is_empty():
			_jump_to(route[-1])
			_arrive()
		return
	brain.tick(delta)
	if bubble_clock > 0.0:
		bubble_clock -= delta
		bubble.modulate.a = clampf(bubble_clock, 0.0, 1.0)
		if bubble_clock <= 0.0:
			bubble.visible = false
	called_clock = maxf(called_clock - delta, 0.0)
	gesture_clock = maxf(gesture_clock - delta, 0.0)
	var player: Vector3 = main._player_pos_v27()
	var to_player: Vector3 = player - global_position
	var dist: float = Vector2(to_player.x, to_player.z).length()
	if vr_label != null:
		vr_label.visible = main.xr_active and state != "parle" and dist < TALK_REACH
	var near: bool = dist < 9.0 and absf(to_player.y) < 5.0
	if near and not player_was_near and called_clock <= 0.0 and state != "parle":
		var now: int = Time.get_ticks_msec()
		if now - int(main.get_meta("pnj_appel_v42", -100000)) > 3000:
			var line: String = brain.call_out(main._npc_ctx_v31())
			if line != "":
				say_bubble(line, 4.5)
				main.set_meta("pnj_appel_v42", now)
		called_clock = 90.0
	player_was_near = near
	match state:
		"parle":
			_face(to_player, delta)
			if gesture_clock <= 0.0:
				if pose in ["assis", "guitare", "lire"]:
					_play("v28/sit", 0.3)
				else:
					_play("Talk_with_Right_Hand_Open", 0.3, 0.9)
		"marche":
			_walk_azur(delta, dist)
		_:
			# V65 : en plein bavardage avec un voisin, il reste là et se tourne vers lui (s'il est debout)
			if chat_hold > 0.0 and _run_loop.is_empty():
				chat_hold = maxf(chat_hold - delta, 0.0)
				if is_instance_valid(chat_partner) and pose in ["debout", "comptoir", "bras_croises", "boire", "jouer", "petanque"]:
					_face(chat_partner.global_position - global_position, delta, 3.0)
					if gesture_clock <= 0.0 and current_anim != "v28/idle" and current_anim != "Stand_and_Drink":
						_play("v28/idle", 0.4)
				elif gesture_clock <= 0.0:
					_activity(delta, 99.0, to_player)
			elif not _run_loop.is_empty():
				_jog(delta)
			elif gesture_clock <= 0.0:
				_activity(delta, dist, to_player)


func _activity(delta: float, dist: float, to_player: Vector3) -> void:
	if dist < 3.0 and pose in ["debout", "comptoir", "bras_croises"]:
		_face(to_player, delta, 3.0)
	_gest -= delta
	match pose:
		"assis":
			_play("v28/sit", 0.4)
		"lire":
			_play("v56/lire", 0.4)
		"guitare":
			_play("v56/guitare", 0.3)
		"allonge":
			_play("Lie_Down_Hands_Spread", 0.6)
			if anim != null and anim.current_animation == "Lie_Down_Hands_Spread" and anim.current_animation_position > anim.current_animation_length - 0.15:
				anim.pause()
		"boire":
			if current_anim != "Stand_and_Drink":
				_play("Stand_and_Drink", 0.4)
		"comptoir":
			if _gest <= 0.0:
				_gest = _rng2.randf_range(6.0, 14.0)
				_play("Talk_with_Right_Hand_Open", 0.3, 0.8)
				gesture_clock = 2.5
			else:
				_play("v56/comptoir", 0.4)
		"peindre":
			_play("v56/peindre", 0.4)
		"bras_croises":
			_play("v56/bras_croises", 0.4)
		"petanque":
			if _gest <= 0.0:
				_gest = _rng2.randf_range(7.0, 13.0)
				_play("v28/pickup", 0.2, 0.8, 0.0)
				gesture_clock = 1.2
			else:
				_play("v28/idle", 0.4)
		"jouer":
			if _gest <= 0.0 and not _pair.is_empty():
				_gest = _rng2.randf_range(3.0, 7.0)
				var nxt: String = str(_pair[_rng2.randi() % _pair.size()])
				var sp: Dictionary = azur.spot(nxt)
				if not sp.is_empty():
					route = [str(sp["node"])] if points.has(str(sp["node"])) else []
					if not route.is_empty():
						state = "marche"
						return
			_play("v28/idle", 0.4)
		_:
			# debout : regarder autour, parfois un geste, parfois un pas vers un lieu voisin
			if _gest <= 0.0:
				_gest = _rng2.randf_range(8.0, 16.0)
				if not _pair.is_empty() and _rng2.randf() < 0.6:
					var nxt2: String = str(_pair[_rng2.randi() % _pair.size()])
					var sp2: Dictionary = azur.spot(nxt2)
					if not sp2.is_empty() and points.has(str(sp2["node"])):
						target_spot = nxt2
						route = _route_to(str(sp2["node"]))
						if not route.is_empty():
							state = "marche"
							return
				_play("Walking_Scan_with_Sudden_Look_Back" if _rng2.randf() < 0.3 else "v28/idle", 0.4)
			elif current_anim != "Walking_Scan_with_Sudden_Look_Back" or (anim != null and not anim.is_playing()):
				_play("v28/idle", 0.4)


func _walk_azur(delta: float, player_dist: float) -> void:
	if route.is_empty():
		_arrive()
		return
	if player_dist < 1.6:
		_play("v28/idle", 0.3)
		return
	var goal: Vector3 = points[route[0]]
	var to_goal: Vector3 = goal - global_position
	to_goal.y = 0.0
	var speed: float = SPEED_WALK * (1.25 if pose == "jouer" else 1.0)
	if to_goal.length() < 0.15:
		at_point = route.pop_front()
		if route.is_empty():
			_arrive()
		return
	_face(to_goal, delta, 6.0)
	var step: Vector3 = to_goal.normalized() * minf(speed * delta, to_goal.length())
	global_position += step
	_snap_to_floor()
	_play("Skip_Forward" if pose == "jouer" else "Walking", 0.3, speed / 1.05)


func _jog(delta: float) -> void:
	if _run_loop.is_empty():
		return
	var goal_name: String = str(_run_loop[_run_i % _run_loop.size()])
	if not points.has(goal_name):
		_run_i += 1
		return
	var goal: Vector3 = points[goal_name]
	var to_goal: Vector3 = goal - global_position
	to_goal.y = 0.0
	if to_goal.length() < 0.4:
		_run_i += 1
		at_point = goal_name
		return
	_face(to_goal, delta, 6.0)
	global_position += to_goal.normalized() * minf(SPEED_RUN * delta, to_goal.length())
	_snap_to_floor()
	_play("Running", 0.3, 1.0)


func end_talk() -> void:
	state = "repos"
	idle_clock = 1e9
	gesture_clock = 0.0
	current_anim = ""
	if pose in ["assis", "guitare", "lire", "allonge"] and not target_spot.begins_with("course:"):
		_arrive()


func _pick_destination() -> void:
	pass
