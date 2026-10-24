extends "res://scripts/soleils_kit_v69.gd"
## V69 : la boîte à outils des trois grands donjons de l'Île des Trois Soleils (la Pyramide de Rê,
## Xibalba, les Cinq Soleils). Les formes des villages (soleils_kit_v69 : colonnes papyriformes,
## statues assises, stèles, têtes de serpent, troncs de pyramide…) et, en plus, les outils des
## souterrains (repris du kit du Cœur-de-Pierre, coeur_kit_v63) :
##  - room() : une salle (sol, plafond, quatre murs percés d'ouvertures) ; solid() ;
##  - ramp() : un escalier (marches dessinées, collision en rampe) ;
##  - column(), arch(), torch(), brazier63(), glow_light(), fire().
## On change de « root » entre deux salles et on fait commit() : un maillage par matière et par
## salle (les salles qu'on ne voit pas ne sont pas dessinées).

var main: Node
var pc: bool = true
var torches: Array = []                  # OmniLight3D des torches


func setup69(parent: Node3D, main_node: Node, high_quality: bool) -> void:
	setup(parent, null)
	main = main_node
	pc = high_quality


## Une boîte pleine (dessinée et solide).
func solid(xf: Transform3D, size: Vector3, key: String, tile: float = 2.0, faces: int = 63) -> void:
	box(xf, size, key, tile, faces)
	col_box(xf, size)


## Une salle (repère xf) : sol, plafond, quatre murs percés d'ouvertures
## [côté ("n" = -Z, "s" = +Z, "e" = +X, "w" = -X), centre, largeur, hauteur].
func room(xf: Transform3D, x0: float, x1: float, z0: float, z1: float, y0: float, h: float, wall: String, floor_k: String, openings: Array = [], ceiling: String = "", t: float = 0.8, tile: float = 3.0) -> void:
	var cx: float = (x0 + x1) * 0.5
	var cz: float = (z0 + z1) * 0.5
	if floor_k != "":
		solid(xf * Transform3D(Basis(), Vector3(cx, y0 - 0.3, cz)), Vector3(x1 - x0 + 2 * t, 0.6, z1 - z0 + 2 * t), floor_k, tile, 4)
	if ceiling != "":
		solid(xf * Transform3D(Basis(), Vector3(cx, y0 + h + 0.4, cz)), Vector3(x1 - x0 + 2 * t, 0.8, z1 - z0 + 2 * t), ceiling, tile, 8)
	for side in ["n", "s", "e", "w"]:
		var along_x: bool = side in ["n", "s"]
		var a0: float = x0 - t if along_x else z0
		var a1: float = x1 + t if along_x else z1
		var fixed: float = (z0 - t * 0.5) if side == "n" else ((z1 + t * 0.5) if side == "s" else ((x1 + t * 0.5) if side == "e" else (x0 - t * 0.5)))
		var gaps: Array = []
		for o in openings:
			if str(o[0]) == side:
				gaps.append([float(o[1]) - float(o[2]) * 0.5, float(o[1]) + float(o[2]) * 0.5, float(o[3])])
		gaps.sort_custom(func(p, q): return p[0] < q[0])
		var cur: float = a0
		for g in gaps:
			if g[0] > cur:
				_wall(xf, along_x, fixed, cur, g[0], y0, h, t, wall, tile)
			if float(g[2]) < h:
				_wall(xf, along_x, fixed, g[0], g[1], y0 + float(g[2]), h - float(g[2]), t, wall, tile)
			cur = g[1]
		if cur < a1:
			_wall(xf, along_x, fixed, cur, a1, y0, h, t, wall, tile)


func _wall(xf: Transform3D, along_x: bool, fixed: float, a: float, b: float, y0: float, h: float, t: float, key: String, tile: float) -> void:
	if b - a < 0.01 or h < 0.01:
		return
	var mid: float = (a + b) * 0.5
	if along_x:
		solid(xf * Transform3D(Basis(), Vector3(mid, y0 + h * 0.5, fixed)), Vector3(b - a, h, t), key, tile)
	else:
		solid(xf * Transform3D(Basis(), Vector3(fixed, y0 + h * 0.5, mid)), Vector3(t, h, b - a), key, tile)


## Un escalier de a (bas) à b (haut), largeur w : marches dessinées, collision en rampe lisse.
func ramp(xf: Transform3D, a: Vector3, b: Vector3, w: float, key: String, side_key: String = "") -> void:
	var flat := Vector3(b.x - a.x, 0, b.z - a.z)
	var run: float = flat.length()
	var rise: float = b.y - a.y
	if run < 0.01:
		return
	var dir: Vector3 = flat / run
	var yaw: float = atan2(dir.x, dir.z)
	var bs := Basis(Vector3.UP, yaw)
	var n: int = maxi(int(round(absf(rise) / 0.22)), 1)
	for i in range(n):
		var t0: float = float(i) / n
		var p := a + Vector3(dir.x, 0, dir.z) * run * (t0 + 0.5 / n)
		var top: float = a.y + rise * float(i + 1) / n
		var hgt: float = top - a.y + 0.02
		box(xf * Transform3D(bs, Vector3(p.x, a.y + hgt * 0.5 - 0.02, p.z)), Vector3(w, hgt, run / n + 0.02), key, 1.5)
	var slope: float = atan2(rise, run)
	var mid := (a + b) * 0.5
	var len3: float = sqrt(run * run + rise * rise)
	var cb: Basis = bs * Basis(Vector3.RIGHT, -slope)
	col_box(xf * Transform3D(cb, mid + cb * Vector3(0, -0.15, 0)), Vector3(w, 0.3, len3 + 0.2))
	if side_key != "":
		for s in [-1.0, 1.0]:
			var off: Vector3 = bs * Vector3(s * (w * 0.5 + 0.15), 0, 0)
			box(xf * Transform3D(cb, mid + off + cb * Vector3(0, 0.35, 0)), Vector3(0.3, 0.7, len3 + 0.3), side_key, 1.5)


## Une colonne : base, fût, chapiteau (posée sur xf.origin).
func column(xf: Transform3D, r: float, h: float, key: String, cap_key: String = "") -> void:
	var ck: String = cap_key if cap_key != "" else key
	box(xf * Transform3D(Basis(), Vector3(0, 0.2, 0)), Vector3(r * 2.6, 0.4, r * 2.6), ck, 1.0)
	cyl(xf * Transform3D(Basis(), Vector3(0, 0.4, 0)), r, r * 0.92, h - 0.9, key, 14, false, 1.2)
	box(xf * Transform3D(Basis(), Vector3(0, h - 0.25, 0)), Vector3(r * 2.7, 0.5, r * 2.7), ck, 1.0)
	col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(r * 1.8, h, r * 1.8))


## Un encadrement de porte (deux piédroits et un linteau) dans le plan XY de xf, l'ouverture
## centrée sur l'origine (sol), largeur w, hauteur h.
func door_frame(xf: Transform3D, w: float, h: float, depth: float, key: String, lintel_key: String = "") -> void:
	var lk: String = lintel_key if lintel_key != "" else key
	for s in [-1.0, 1.0]:
		var jxf: Transform3D = xf * Transform3D(Basis(), Vector3(s * (w * 0.5 + 0.35), h * 0.5, 0))
		box(jxf, Vector3(0.7, h, depth), key, 1.5)
		col_box(jxf, Vector3(0.7, h, depth))
	box(xf * Transform3D(Basis(), Vector3(0, h + 0.35, 0)), Vector3(w + 1.6, 0.7, depth + 0.1), lk, 1.5)


## Une torche murale (support de fer, flamme, lumière). Renvoie la lumière.
func torch(parent: Node3D, pos: Vector3, facing: Vector3, energy: float = 1.6, lit: bool = true) -> OmniLight3D:
	var D = preload("res://scripts/decor_v53.gd")
	var r := Node3D.new()
	r.name = "Torche_v69"
	parent.add_child(r)
	r.global_position = pos
	r.rotation.y = atan2(facing.x, facing.z)
	var fe: Material = D.forged_iron()
	D.box(r, Vector3(0.16, 0.26, 0.03), Vector3(0, -0.02, 0.0), fe)
	D.box(r, Vector3(0.04, 0.04, 0.2), Vector3(0, -0.06, 0.1), fe)
	D.cyl(r, 0.055, 0.055, 0.04, Vector3(0, -0.04, 0.2), fe, 10)
	var handle: MeshInstance3D = D.cyl(r, 0.045, 0.03, 0.5, Vector3(0, 0.06, 0.2), mat("bois69"), 8)
	handle.rotation.x = 0.3
	var head: MeshInstance3D = D.cyl(r, 0.06, 0.05, 0.14, Vector3(0, 0.3, 0.27), mat("noir69"), 8)
	head.rotation.x = 0.3
	var core := MeshInstance3D.new()
	core.name = "Flamme"
	var cs := SphereMesh.new()
	cs.radius = 0.055
	cs.height = 0.2
	core.mesh = cs
	core.material_override = D.flame_core()
	core.position = Vector3(0, 0.43, 0.3)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	r.add_child(core)
	var f: CPUParticles3D = fire(r, Vector3(0, 0.42, 0.3), 0.08, 18)
	f.name = "Feu"
	var light := OmniLight3D.new()
	light.name = "Lumiere"
	light.light_color = Color(1.0, 0.62, 0.3)
	light.light_energy = energy if lit else 0.0
	light.omni_range = 15.0
	light.omni_attenuation = 1.0
	light.position = Vector3(0, 0.45, 0.35)
	light.set_meta("energie", energy)
	r.add_child(light)
	core.visible = lit
	f.emitting = lit
	torches.append(light)
	return light


## Allume ou éteint une torche (sa lumière, sa flamme, ses particules).
static func set_torch(light: OmniLight3D, on: bool) -> void:
	if light == null:
		return
	var r: Node = light.get_parent()
	light.light_energy = float(light.get_meta("energie", 1.6)) if on else 0.0
	var core: Node3D = r.get_node_or_null("Flamme")
	if core != null:
		core.visible = on
	var f: CPUParticles3D = r.get_node_or_null("Feu")
	if f != null:
		f.emitting = on


## Flammes en particules (additives).
func fire(parent: Node3D, pos: Vector3, radius: float, amount: int) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = 0.7
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radius
	p.direction = Vector3.UP
	p.spread = 12.0
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 1.0
	p.gravity = Vector3(0, 1.2, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	var q := QuadMesh.new()
	q.size = Vector2(0.22, 0.3) * (radius / 0.12)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.disable_receive_shadows = true
	m.vertex_color_use_as_albedo = true
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	q.material = m
	p.mesh = q
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.85, 0.4, 1.0))
	grad.set_color(1, Color(0.9, 0.2, 0.05, 0.0))
	p.color_ramp = grad
	p.position = pos
	parent.add_child(p)
	return p


## Un brasero sur pied de pierre (allumé ou non). Renvoie {node, fire, light, coals, energy, lit}.
func brazier63(parent: Node3D, pos: Vector3, lit: bool, bowl_key: String = "bronze69", energy: float = 2.2, foot_key: String = "calc69") -> Dictionary:
	var r := Node3D.new()
	r.name = "Brasero_v69"
	parent.add_child(r)
	r.global_position = pos
	var foot := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = 0.18
	fm.bottom_radius = 0.3
	fm.height = 0.92
	fm.radial_segments = 12
	foot.mesh = fm
	foot.material_override = mat(foot_key)
	foot.position = Vector3(0, 0.46, 0)
	r.add_child(foot)
	var bowl := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.42
	bm.bottom_radius = 0.2
	bm.height = 0.28
	bm.radial_segments = 18
	bowl.mesh = bm
	bowl.material_override = mat(bowl_key)
	bowl.position = Vector3(0, 1.05, 0)
	r.add_child(bowl)
	var coals := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.36
	cm.bottom_radius = 0.36
	cm.height = 0.04
	coals.mesh = cm
	coals.material_override = mat("lueur69_rouge") if lit else mat("noir69")
	coals.position = Vector3(0, 1.17, 0)
	coals.name = "Braises"
	r.add_child(coals)
	var f: CPUParticles3D = fire(r, Vector3(0, 1.25, 0), 0.22, 28)
	f.emitting = lit
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.28)
	light.light_energy = energy if lit else 0.0
	light.omni_range = 15.0
	light.omni_attenuation = 1.1
	light.position = Vector3(0, 1.7, 0)
	r.add_child(light)
	col_cyl(pos, 0.35, 1.2)
	return {"node": r, "fire": f, "light": light, "coals": coals, "energy": energy, "lit": lit}


func set_brazier(b: Dictionary, on: bool) -> void:
	b["lit"] = on
	(b["fire"] as CPUParticles3D).emitting = on
	(b["coals"] as MeshInstance3D).material_override = mat("lueur69_rouge") if on else mat("noir69")
	var light: OmniLight3D = b["light"]
	var tw: Tween = light.create_tween()
	tw.tween_property(light, "light_energy", float(b["energy"]) if on else 0.0, 0.6)


## Une lumière d'ambiance (sans flamme), sans ombre sauf demande.
func glow_light(parent: Node3D, pos: Vector3, c: Color, energy: float, rng_m: float, shadow: bool = false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = energy
	l.omni_range = rng_m
	l.omni_attenuation = 1.2
	l.shadow_enabled = shadow and pc
	parent.add_child(l)
	l.global_position = pos
	return l


## Un panneau peint (fresque, papyrus, codex) dans un cadre de pierre, accroché à un mur : xf
## regarde vers +Z (la face peinte), centré sur l'origine.
func panel(xf: Transform3D, w: float, h: float, key: String, frame_key: String = "calc69") -> void:
	box(xf * Transform3D(Basis(), Vector3(0, 0, -0.06)), Vector3(w + 0.3, h + 0.3, 0.12), frame_key, 1.0)
	quadz(xf * Transform3D(Basis(), Vector3(0, 0, 0.005)), w, h, key)


## Un sarcophage (cuve et couvercle) : xf au sol, long selon Z.
func sarcophagus(xf: Transform3D, open: bool, key: String = "gres69", lid_key: String = "or69") -> void:
	box(xf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(1.0, 0.9, 2.3), key, 1.0)
	if open:
		box(xf * Transform3D(Basis(), Vector3(0, 0.88, 0)), Vector3(0.8, 0.06, 2.0), "noir69", 1.0)
		box(xf * Transform3D(Basis(Vector3.UP, 0.4), Vector3(1.3, 0.25, 0.4)), Vector3(0.95, 0.16, 2.2), lid_key, 1.0)
	else:
		box(xf * Transform3D(Basis(), Vector3(0, 0.98, 0)), Vector3(1.04, 0.16, 2.34), lid_key, 1.0)
	col_box(xf * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(1.0, 1.0, 2.3))


## Un prisme droit à n faces (un tambour à symboles) autour de l'axe X local, chaque face portant
## une matière de « faces » ; renvoie le nœud (pour le faire tourner).
func drum(parent: Node3D, pos: Vector3, r: float, length: float, faces: Array, body_key: String = "gres69") -> Node3D:
	var n: int = faces.size()
	var node := Node3D.new()
	parent.add_child(node)
	node.global_position = pos
	var apothem: float = r * cos(PI / n)
	var side: float = 2.0 * r * sin(PI / n)
	for i in range(n):
		var a: float = TAU * i / n
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(length, side * 0.98, 0.06)
		mi.mesh = bm
		mi.material_override = mat(body_key)
		mi.transform = Transform3D(Basis(Vector3.RIGHT, -a), Basis(Vector3.RIGHT, -a) * Vector3(0, 0, apothem - 0.03))
		node.add_child(mi)
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(minf(length * 0.8, side * 0.85), side * 0.85)
		q.mesh = qm
		q.material_override = mat(str(faces[i]))
		q.transform = Transform3D(Basis(Vector3.RIGHT, -a), Basis(Vector3.RIGHT, -a) * Vector3(0, 0, apothem + 0.005))
		node.add_child(q)
	for s in [-1.0, 1.0]:
		var cap := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = r * 1.06
		cm.bottom_radius = r * 1.06
		cm.height = 0.08
		cm.radial_segments = n
		cap.mesh = cm
		cap.material_override = mat("bronze69")
		cap.rotation.z = PI * 0.5
		cap.position = Vector3(s * length * 0.5, 0, 0)
		node.add_child(cap)
	return node


## Des éboulis et des rochers (rocks_v26) posés sur le sol.
func rocks(parent: Node3D, pts: Array, seed_v: int, key: String = "roche69", size_min: float = 0.6, size_max: float = 1.6) -> void:
	var Rk = preload("res://scripts/rocks_v26.gd")
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = seed_v
	var m: Material = mat(key)
	for i in range(pts.size()):
		var s: float = rng2.randf_range(size_min, size_max)
		var mi := MeshInstance3D.new()
		mi.mesh = Rk.shape(seed_v * 7 + i, Vector3(s * rng2.randf_range(1.0, 1.5), s * rng2.randf_range(0.6, 1.1), s), 0.75, 0.18)
		mi.material_override = m
		parent.add_child(mi)
		mi.global_position = (pts[i] as Vector3) + Vector3.UP * s * 0.25
		mi.rotation.y = rng2.randf() * TAU
