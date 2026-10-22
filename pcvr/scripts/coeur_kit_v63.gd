extends "res://scripts/azur_kit_v56.gd"
## V63 : la boîte à outils des souterrains de la grande île — le donjon du Cœur-de-Pierre et
## les deux sanctuaires de la grande enquête (le tombeau de la Dune qui Marche, la Bergerie du
## Vent). Même principe que les autres kits : géométrie regroupée par matériau (un maillage
## par matériau et par salle : on change de « root » entre deux salles et on fait commit()),
## collisions dans un seul corps statique. En plus :
##  - les pierres du Cœur : granit appareillé, dalles, grès gravé, pierre marine à coraux,
##    ardoise aux étoiles d'argent, bronze, laiton, or, et les fresques ;
##  - room() : une salle (sol, plafond, quatre murs percés d'ouvertures) ;
##  - ramp() : un escalier (marches dessinées, collision en rampe) ;
##  - column(), arch(), torch(), brazier().

const CT := "res://assets/textures/coeur/"
const CL := "res://assets/textures/cliquetis/"
const TR := "res://assets/textures/terrain/"

var main: Node
var pc: bool = true
var torches: Array = []                  # OmniLight3D des torches (pour les allumer / éteindre)


func setup63(parent: Node3D, main_node: Node, high_quality: bool) -> void:
	setup(parent, null)
	main = main_node
	pc = high_quality
	body.name = "Collisions_souterrains_v63"


func _t(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


func _stone(tex: String, normal: String, tint: Color, rough: float, nscale: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _t(tex)
	m.albedo_color = tint
	if _t(normal) != null:
		m.normal_enabled = true
		m.normal_texture = _t(normal)
		m.normal_scale = nscale
	m.roughness = rough
	return m


func _glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


func mat(key: String) -> Material:
	if mats.has(key):
		return mats[key]
	var m: StandardMaterial3D = null
	match key:
		"granit":
			m = _stone(CT + "pierre.png", CT + "pierre_n.png", Color(0.92, 0.9, 0.86), 0.88, 1.2)
		"granit_sombre":
			m = _stone(CT + "pierre.png", CT + "pierre_n.png", Color(0.55, 0.53, 0.5), 0.9, 1.2)
		"dalles_c":
			m = _stone(CT + "dalles.png", CT + "dalles_n.png", Color(0.95, 0.93, 0.9), 0.82, 1.1)
		"gres":
			m = _stone(CT + "gres.png", CT + "gres_n.png", Color(1.0, 0.97, 0.92), 0.86, 1.1)
		"gres_sombre":
			m = _stone(CT + "gres.png", CT + "gres_n.png", Color(0.62, 0.52, 0.42), 0.9, 1.1)
		"corail":
			m = _stone(CT + "corail.png", CT + "corail_n.png", Color(0.9, 0.95, 0.96), 0.42, 1.3)
			m.metallic_specular = 0.7
		"ardoise_c":
			m = _stone(CT + "ardoise.png", CT + "ardoise_n.png", Color(0.95, 0.96, 1.0), 0.55, 1.0)
		"laiton_c":
			m = _stone(CL + "laiton.png", CL + "laiton_n.png", Color(1.0, 0.92, 0.75), 0.42, 1.0)
			m.metallic = 0.45
		"fonte_c":
			m = _stone(CL + "fonte.png", CL + "fonte_n.png", Color(0.8, 0.8, 0.82), 0.6, 1.0)
			m.metallic = 0.35
		"cuivre_c":
			m = _stone(CL + "cuivre.png", CL + "cuivre_n.png", Color(1, 1, 1), 0.45, 1.0)
			m.metallic = 0.45
		"bronze":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.62, 0.42, 0.22)
			m.albedo_texture = _t(CL + "cuivre.png")
			m.metallic = 0.5
			m.roughness = 0.45
		"or_c":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(1.0, 0.78, 0.36)
			m.metallic = 0.6
			m.roughness = 0.3
		"argent_c":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.86, 0.88, 0.92)
			m.metallic = 0.55
			m.roughness = 0.28
		"bois_c":
			m = _stone("res://assets/textures/ramure/planches.png", "res://assets/textures/ramure/planches_n.png", Color(0.62, 0.5, 0.4), 0.9)
		"poutre_c":
			m = _stone("res://assets/textures/ramure/rondins.png", "res://assets/textures/ramure/rondins_n.png", Color(0.7, 0.6, 0.5), 0.9)
		"paille_c":
			m = _stone("res://assets/textures/ramure/chaume.png", "res://assets/textures/ramure/chaume_n.png", Color(1.0, 0.95, 0.8), 0.95)
		"sable_c":
			m = _stone(TR + "sand.jpg", TR + "sand_n.png", Color(1.0, 0.86, 0.66), 0.95)
			m.uv1_triplanar = true
			m.uv1_scale = Vector3.ONE * 0.25
		"roche_c":
			m = _stone(TR + "rock.jpg", TR + "rock_n.png", Color(0.72, 0.68, 0.62), 0.92, 1.2)
			m.uv1_triplanar = true
			m.uv1_scale = Vector3.ONE * 0.18
		"roche_neige":
			m = _stone(TR + "rock.jpg", TR + "rock_n.png", Color(0.8, 0.8, 0.8), 0.92, 1.2)
			m.uv1_triplanar = true
			m.uv1_scale = Vector3.ONE * 0.18
		"mousse_c":
			m = _stone(TR + "grass.jpg", TR + "grass_n.png", Color(0.42, 0.55, 0.3), 0.95)
			m.uv1_triplanar = true
			m.uv1_scale = Vector3.ONE * 0.6
		"goudron_c":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.1, 0.07, 0.05)
			m.roughness = 0.9
		"noir":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.0, 0.0, 0.0)
			m.roughness = 1.0
		"eau_c":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.05, 0.18, 0.2, 0.82)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.roughness = 0.05
			m.metallic = 0.3
			m.normal_enabled = true
			m.normal_texture = _t(TR + "sand_n.png")
			m.normal_scale = 0.25
			m.uv1_scale = Vector3(3, 3, 3)
		"glow_or":
			m = _glow(Color(1.0, 0.72, 0.3), 2.6)
		"glow_bleu":
			m = _glow(Color(0.35, 0.75, 1.0), 2.6)
		"glow_vert":
			m = _glow(Color(0.35, 1.0, 0.8), 2.4)
		"glow_argent":
			m = _glow(Color(0.75, 0.82, 1.0), 2.2)
		"glow_rouge":
			m = _glow(Color(1.0, 0.35, 0.15), 2.6)
		_:
			if key.begins_with("img_"):
				m = StandardMaterial3D.new()
				m.albedo_texture = _t(CT + key.trim_prefix("img_") + ".png")
				m.roughness = 0.9
	if m == null:
		return super.mat(key)
	mats[key] = m
	return m


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
	var n: int = maxi(int(round(rise / 0.22)), 1)
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


## Un encadrement de porte en arc (deux piédroits, un arc de claveaux) dans le plan XY de xf,
## l'ouverture centrée sur l'origine (sol), largeur w, hauteur des piédroits h.
func arch(xf: Transform3D, w: float, h: float, depth: float, key: String, solid_frame: bool = true) -> void:
	var jw: float = 0.7
	for s in [-1.0, 1.0]:
		var jxf: Transform3D = xf * Transform3D(Basis(), Vector3(s * (w * 0.5 + jw * 0.5), h * 0.5, 0))
		box(jxf, Vector3(jw, h, depth), key, 1.5)
		if solid_frame:
			col_box(jxf, Vector3(jw, h, depth))
	var r: float = w * 0.5 + jw * 0.5
	var seg: int = 9
	for i in range(seg):
		var a: float = PI * (i + 0.5) / seg
		var c := Vector3(cos(a) * r, h + sin(a) * r, 0)
		box(xf * Transform3D(Basis(Vector3.BACK, a - PI * 0.5), c), Vector3(PI * r / seg + 0.04, jw, depth + 0.02), key, 1.5)
	if solid_frame:
		col_box(xf * Transform3D(Basis(), Vector3(0, h + r * 0.75, 0)), Vector3(w, r * 0.5, depth))


## Une torche murale (support de fer, flamme, lumière). Renvoie la lumière.
func torch(parent: Node3D, pos: Vector3, facing: Vector3, energy: float = 1.6, lit: bool = true) -> OmniLight3D:
	var D = preload("res://scripts/decor_v53.gd")
	var r := Node3D.new()
	r.name = "Torche_v63"
	parent.add_child(r)
	r.global_position = pos
	r.rotation.y = atan2(facing.x, facing.z)
	var fe: Material = D.forged_iron()
	D.box(r, Vector3(0.16, 0.26, 0.03), Vector3(0, -0.02, 0.0), fe)
	D.box(r, Vector3(0.04, 0.04, 0.2), Vector3(0, -0.06, 0.1), fe)
	D.cyl(r, 0.055, 0.055, 0.04, Vector3(0, -0.04, 0.2), fe, 10)
	var handle: MeshInstance3D = D.cyl(r, 0.045, 0.03, 0.5, Vector3(0, 0.06, 0.2), mat("bois_c"), 8)
	handle.rotation.x = 0.3
	var head: MeshInstance3D = D.cyl(r, 0.06, 0.05, 0.14, Vector3(0, 0.3, 0.27), mat("goudron_c"), 8)
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
	light.omni_range = 11.0
	light.omni_attenuation = 1.15
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


## Un brasero sur trépied (allumé ou non). Renvoie {node, fire, light, core}.
func brazier(parent: Node3D, pos: Vector3, lit: bool, bowl_key: String = "bronze", energy: float = 2.2) -> Dictionary:
	var r := Node3D.new()
	r.name = "Brasero_v63"
	parent.add_child(r)
	r.global_position = pos
	var D = preload("res://scripts/decor_v53.gd")
	var fe: Material = D.forged_iron()
	for k in range(3):
		var a: float = TAU * k / 3.0
		var leg: MeshInstance3D = D.cyl(r, 0.03, 0.035, 1.0, Vector3(cos(a) * 0.22, 0.48, sin(a) * 0.22), fe, 6)
		leg.rotation = Vector3(sin(a) * 0.25, 0, -cos(a) * 0.25)
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
	coals.material_override = mat("glow_rouge") if lit else mat("goudron_c")
	coals.position = Vector3(0, 1.17, 0)
	coals.name = "Braises"
	r.add_child(coals)
	var f: CPUParticles3D = fire(r, Vector3(0, 1.25, 0), 0.22, 28)
	f.emitting = lit
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.28)
	light.light_energy = energy if lit else 0.0
	light.omni_range = 11.0
	light.omni_attenuation = 1.3
	light.position = Vector3(0, 1.7, 0)
	r.add_child(light)
	var sc := CollisionShape3D.new()
	var cyl_s := CylinderShape3D.new()
	cyl_s.radius = 0.35
	cyl_s.height = 1.2
	sc.shape = cyl_s
	body.add_child(sc)
	sc.global_position = pos + Vector3(0, 0.6, 0)
	return {"node": r, "fire": f, "light": light, "coals": coals, "energy": energy, "lit": lit}


func set_brazier(b: Dictionary, on: bool) -> void:
	b["lit"] = on
	(b["fire"] as CPUParticles3D).emitting = on
	(b["coals"] as MeshInstance3D).material_override = mat("glow_rouge") if on else mat("goudron_c")
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


## Des éboulis et des rochers (rocks_v26) posés sur le sol.
func rocks(parent: Node3D, pts: Array, seed_v: int, key: String = "roche_c", size_min: float = 0.6, size_max: float = 1.6) -> void:
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
