extends "res://scripts/pnj/pnj_lumen_v76.gd"
## V95 : un habitant de Néopolis. Même vie réglée par l'heure que les autres (et toutes les postures
## des îles d'avant : holo, méditer, danser, acclamer, observer, cuisiner, peindre…), avec en plus ce
## qui fait un habitant de Néopolis (fiche « neo ») :
##  - la peau d'un androïde (polymère, joints, circuits, yeux qui luisent) et l'implant d'un
##    « modifié » (l'avant-bras et la tempe gauches en métal) : dans le corps (corps_v64, peau_v64) ;
##  - les petites pièces posées sur la vraie tête (repères V64) : la visière (une bande de verre
##    teinté, lumineuse, devant les yeux), les diodes des tempes, le collier lumineux, l'antenne du
##    vieux modèle, le monocle du réparateur, les oreillettes de la danseuse ; elles pulsent doucement ;
##  - l'objet à la main (tablette holographique, clé, arrosoir, casque audio…).

const NEO_LUMEN_OBJ := ["tablette_holo", "baton_lumiere", "plateau", "appareil_holo", "livre"]

var _neo: Dictionary = {}
var _glows: Array = []                    # [StandardMaterial3D, énergie, vitesse, phase, clignote]
var _neo_t: float = 0.0


func setup_azur(manager: Node, data: Dictionary) -> void:
	super.setup_azur(manager, data)
	neo_props(data.get("neo", {}))


func _neo_glow(c: Color, energy: float, speed: float = 2.0, blink: bool = false, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.roughness = 0.2
	m.metallic_specular = 0.7
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glows.append([m, energy, speed, _rng2.randf() * TAU, blink])
	return m


func _circ() -> Color:
	var c: Array = _neo.get("circuit", [0.3, 0.9, 1.0])
	return Color(float(c[0]), float(c[1]), float(c[2]))


## La tête du vrai corps : centre (entre l'avant et l'arrière), hauteur des yeux, demi-largeur.
func _head_frame() -> Dictionary:
	var t: Dictionary = _tete64
	var ey: Array = t.get("yeux", [0.0, 0.07, 0.08])
	var zc: float = (float(t.get("avant", 0.1)) + float(t.get("arriere", -0.09))) * 0.5
	return {"ey": Vector3(float(ey[0]), float(ey[1]), float(ey[2])), "dx": float(t.get("yeux_dx", 0.031)), "zc": zc,
		"cote": float(t.get("cote", 0.075)), "haut": float(t.get("haut", 0.14)), "avant": float(t.get("avant", 0.1))}


func _head_attach(node: Node3D) -> void:
	if not v64.is_empty():
		_attach("Head", Vector3.ZERO, node, Vector3.ZERO, true)
	else:
		_attach("Head", Vector3(0, 12.0, 2.0), node)


func neo_props(ne: Dictionary) -> void:
	if skel == null or ne.is_empty() or not _neo.is_empty():
		return
	_neo = ne
	var c: Color = _circ()
	var hf: Dictionary = _head_frame()
	var ey: Vector3 = hf["ey"]
	var cote: float = hf["cote"]
	var zc: float = hf["zc"]
	var metal := _m(Color(0.2, 0.21, 0.23), 0.3, 0.9)
	for p in ne.get("props", []):
		match str(p):
			"visiere":
				var v := Node3D.new()
				v.name = "Visiere"
				var r: float = maxf(cote, float(hf["avant"]) - zc) + 0.016
				var band: ArrayMesh = _arc_band(r, 0.028, deg_to_rad(62.0))
				_part(v, band, _neo_glow(c.darkened(0.35), 0.9, 1.4, false, 0.38), Vector3(0, ey.y, zc))
				_part(v, _arc_band(r + 0.002, 0.004, deg_to_rad(66.0)), metal, Vector3(0, ey.y + 0.016, zc))
				_part(v, _arc_band(r + 0.002, 0.003, deg_to_rad(66.0)), _neo_glow(c, 2.2, 2.0), Vector3(0, ey.y - 0.0155, zc))
				for sx in [-1.0, 1.0]:
					_part(v, _cyl(0.012, 0.012, 0.008), metal, Vector3(sx * (cote + 0.006), ey.y, zc - 0.005), Vector3.ONE, Vector3(0, 0, 90))
				_head_attach(v)
			"led_tempe":
				var l := Node3D.new()
				l.name = "Diodes_tempes"
				for sx in [-1.0, 1.0]:
					var at := Vector3(sx * (cote + 0.001), ey.y + 0.012, zc + 0.012)
					var tm := TorusMesh.new()
					tm.inner_radius = 0.008
					tm.outer_radius = 0.012
					tm.rings = 16
					tm.ring_segments = 6
					_part(l, tm, metal, at, Vector3.ONE, Vector3(0, 0, 90))
					_part(l, _cyl(0.0082, 0.0082, 0.003), _neo_glow(c, 2.4, 1.8), at, Vector3.ONE, Vector3(0, 0, 90))
				_head_attach(l)
			"antenne":
				var a := Node3D.new()
				a.name = "Antenne"
				var top := Vector3(cote * 0.45, float(hf["haut"]) - 0.006, zc - 0.012)
				_part(a, _cyl(0.008, 0.012, 0.012), metal, top)
				_part(a, _cyl(0.0025, 0.0025, 0.09), _m(Color(0.75, 0.76, 0.78), 0.3, 0.9), top + Vector3(0, 0.05, 0))
				_part(a, _sphere(0.009), _neo_glow(c, 3.0, 3.0, true), top + Vector3(0, 0.1, 0))
				_head_attach(a)
			"monocle":
				var mo := Node3D.new()
				mo.name = "Monocle"
				var dx: float = float(hf["dx"])
				# du côté de l'implant (la tempe gauche du personnage)
				var eye := ey + Vector3(-dx, 0.0, 0.018)
				var tm2 := TorusMesh.new()
				tm2.inner_radius = 0.0135
				tm2.outer_radius = 0.0175
				tm2.rings = 20
				tm2.ring_segments = 6
				_part(mo, tm2, metal, eye, Vector3.ONE, Vector3(90, 0, 0))
				_part(mo, _cyl(0.0135, 0.0135, 0.0015), _neo_glow(Color(1.0, 0.3, 0.12), 0.35, 1.0, false, 0.22), eye, Vector3.ONE, Vector3(90, 0, 0))
				_part(mo, _sphere(0.0028), _neo_glow(Color(1.0, 0.15, 0.05), 3.0, 3.0), eye + Vector3(0.006, 0.006, 0.002))
				_part(mo, _box_mesh_np(Vector3(0.005, 0.005, 0.05)), metal, Vector3(-cote + 0.004, ey.y, eye.z - 0.03))
				_head_attach(mo)
			"oreillettes":
				var o := Node3D.new()
				o.name = "Oreillettes"
				for sx2 in [-1.0, 1.0]:
					var at2 := Vector3(sx2 * (cote + 0.004), ey.y - 0.022, zc - 0.004)
					_part(o, _cyl(0.014, 0.012, 0.012), _m(Color(0.95, 0.95, 0.97), 0.25, 0.2), at2, Vector3.ONE, Vector3(0, 0, 90))
					var tm3 := TorusMesh.new()
					tm3.inner_radius = 0.01
					tm3.outer_radius = 0.0135
					_part(o, tm3, _neo_glow(c, 2.5, 2.6), at2 + Vector3(sx2 * 0.007, 0, 0), Vector3.ONE, Vector3(0, 0, 90))
				_head_attach(o)
			"collier":
				var cl := Node3D.new()
				cl.name = "Collier_lumineux"
				var tm4 := TorusMesh.new()
				tm4.inner_radius = 0.068
				tm4.outer_radius = 0.074
				_part(cl, tm4, metal, Vector3.ZERO, Vector3(1.0, 1.0, 1.12))
				var tm5 := TorusMesh.new()
				tm5.inner_radius = 0.0735
				tm5.outer_radius = 0.0755
				_part(cl, tm5, _neo_glow(c, 1.8, 1.2), Vector3(0, 0.002, 0), Vector3(1.0, 1.0, 1.12))
				_attach("Neck", Vector3(0, -3, 1), cl, Vector3(-18, 0, 0))
			"casque_audio":
				punk_props({"objet": "casque_audio"})
	var obj: String = str(ne.get("objet", ""))
	if obj != "":
		if obj in NEO_LUMEN_OBJ:
			lumen_props({"objet": obj})
		elif _punk.is_empty():
			punk_props({"objet": obj})


## Une bande courbe (un arc de cylindre vertical, face vers +z) : rayon, hauteur, demi-angle.
func _arc_band(r: float, h: float, half: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 18
	for i in range(n):
		var a0: float = lerpf(-half, half, float(i) / n)
		var a1: float = lerpf(-half, half, float(i + 1) / n)
		var p0 := Vector3(sin(a0) * r, 0, cos(a0) * r)
		var p1 := Vector3(sin(a1) * r, 0, cos(a1) * r)
		var n0 := Vector3(sin(a0), 0, cos(a0))
		var n1 := Vector3(sin(a1), 0, cos(a1))
		var dy := Vector3(0, h * 0.5, 0)
		for e in [[p0 - dy, n0], [p1 - dy, n1], [p1 + dy, n1], [p0 - dy, n0], [p1 + dy, n1], [p0 + dy, n0]]:
			st.set_normal(e[1])
			st.add_vertex(e[0])
	return st.commit()


func _activity(delta: float, dist: float, to_player: Vector3) -> void:
	_neo_t += delta
	for g in _glows:
		var m: StandardMaterial3D = g[0]
		var k: float
		if bool(g[4]):
			k = 0.15 if fmod(_neo_t + float(g[3]), 1.6) > 0.25 else 1.0
		else:
			k = 0.72 + 0.28 * sin(_neo_t * float(g[2]) + float(g[3]))
		m.emission_energy_multiplier = float(g[1]) * k
	super._activity(delta, dist, to_player)
