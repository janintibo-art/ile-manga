extends RefCounted
## V117 : les histoires des maisons de la Cité des Nuées, l'île flottante au-dessus de Hautefond
## (maisons_v81 ; style « nuees » : parquet de bois blond, murs blancs, ni poutres ni cimaise, de
## grandes baies vitrées sur les murs de côté, un plafonnier rond et plat, une cheminée à l'éthanol).
## En plus des histoires communes (maisons_scenes_v81), sept histoires à elles : le nuage de
## compagnie, le grand cerf-volant de la Fête des Vents, l'appartement-jardin et son drone
## d'arrosage, le planeur dans le salon, la petite météorologue, la harpe éolienne et ses carillons,
## la chambre aux papillons.
## Chaque histoire : ses meubles (clairs et modernes), ses gens (et leur nuit : on dort, on chuchote),
## ce qui bouge (un seul M.ctx["tick"] par maison), ce qu'on y fait, et ce dont la maison se souvient
## (M.state() : une récompense une seule fois).
## M : maisons_v81 ; S : maisons_scenes_v81 (les aides communes) ; I : maisons_iles_v82 (_part, _node…).

const S = preload("res://scripts/maisons_scenes_v81.gd")
const I = preload("res://scripts/maisons_iles_v82.gd")

## [id, poids, {style: [styles où elle peut arriver]}]
const SCENARIOS := [
	["nu_nuage", 11, {"style": ["nuees"]}], ["nu_cerfvolant", 11, {"style": ["nuees"]}],
	["nu_jardin", 10, {"style": ["nuees"]}], ["nu_planeur", 10, {"style": ["nuees"]}],
	["nu_meteo", 11, {"style": ["nuees"]}], ["nu_harpe", 10, {"style": ["nuees"]}],
	["nu_papillons", 12, {"style": ["nuees"]}],
]

static var _rond: Texture2D


static func has(sc: String) -> bool:
	for e in SCENARIOS:
		if str(e[0]) == sc:
			return true
	return false


static func build(M, sc: String) -> void:
	_mats(M)
	match sc:
		"nu_nuage":
			_nuage(M)
		"nu_cerfvolant":
			_cerf_volant(M)
		"nu_jardin":
			_jardin(M)
		"nu_planeur":
			_planeur(M)
		"nu_meteo":
			_meteo(M)
		"nu_harpe":
			_harpe(M)
		"nu_papillons":
			_papillons(M)


# =================================================================== aides

static func _r(M) -> RandomNumberGenerator:
	return M.ctx["rng"]


static func _pick(M, a: Array) -> Variant:
	return a[_r(M).randi() % a.size()]


## Toujours dans la même pièce ? (après un délai, on a pu sortir… ou entrer dans une autre maison)
static func _la(M, room0) -> bool:
	return is_instance_valid(room0) and M.inside and M.room == room0


## La nuit des Nuées (avant 7 h, après 21 h) : on dort, on chuchote.
static func _nuit(M) -> bool:
	var h: float = float(M.ctx["hour"])
	return h < 7.0 or h >= 21.0


## Le regard (en degrés, comme M.person) de (fx, fz) vers (tx, tz), en repère de la pièce.
static func _vers(fx: float, fz: float, tx: float, tz: float) -> float:
	return rad_to_deg(atan2(tx - fx, tz - fz))


## Une position (repère de la pièce) ramenée dans la partie permise : loin des murs, la porte libre.
static func _dedans(M, x: float, z: float) -> Vector2:
	var R = M.R
	return Vector2(clampf(x, -R.W * 0.5 + 0.5, R.W * 0.5 - 0.5), clampf(z, -R.D * 0.5 + 0.5, R.D * 0.5 - 1.6))


## Un matériau partagé par plusieurs morceaux.
static func _mat(c: Color, metal: float = 0.0, rough: float = 0.6, emit: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = rough
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m


## Un matériau transparent (verre, nuage, voilage).
static func _verre(c: Color, a: float, emit: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, a)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.15
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m


## Un morceau qui bouge (maillage + matériau partagé), en local du parent.
static func _p(parent: Node3D, mesh: Mesh, m: Material, pos: Vector3, scl: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.scale = scl
	mi.rotation = rot
	parent.add_child(mi)
	return mi


## Pas d'ombre (ce qui flotte près du plafonnier ferait des ombres géantes sur les murs).
static func _sans_ombre(n: Node) -> void:
	for c in n.find_children("*", "GeometryInstance3D", true, false):
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## De la géométrie de la pièce (R.kit, regroupée) qu'on peut faire bouger autour de `centre`
## (monde) : R.movable la bâtit en coordonnées du monde, on la range dans un pivot.
static func _bloc(M, centre: Vector3, fn: Callable) -> Node3D:
	var piv: Node3D = I._node(M, centre)
	var n: Node3D = M.R.movable(fn)
	n.reparent(piv, true)
	return piv


## Une bulle qui monte et s'efface (« ♪ », « Pschhh ! »…), à `at` (monde).
static func _bulle(M, at: Vector3, txt: String, c: Color = Color(1.0, 0.97, 0.88), size: int = 40, rise: float = 0.5, dur: float = 1.6) -> void:
	var lab := Label3D.new()
	lab.text = txt
	lab.font_size = size
	lab.pixel_size = 0.004
	lab.outline_size = 10
	lab.modulate = c
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.no_depth_test = true
	M.room.add_child(lab)
	lab.global_position = at
	var tw: Tween = M.room.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lab, "global_position", at + Vector3(0, rise, 0), dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(lab, "modulate:a", 0.0, dur * 0.45).set_delay(dur * 0.55)
	tw.tween_property(lab, "outline_modulate:a", 0.0, dur * 0.45).set_delay(dur * 0.55)
	tw.chain().tween_callback(lab.queue_free)


static func _tache() -> Texture2D:
	if _rond != null:
		return _rond
	var g := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 1))
	gr.set_color(1, Color(1, 1, 1, 0))
	g.gradient = gr
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.0, 0.5)
	g.width = 64
	g.height = 64
	_rond = g
	return _rond


## Une curiosité qu'on n'a pas déjà dans le sac (sinon, `alt`).
static func _neuf(M, id: String, alt: String) -> String:
	var inv: Node = M.main.get("inventory_v28")
	if inv != null and inv.has_method("count") and int(inv.count(id)) > 0:
		return alt
	return id


## Les matières en plus des Nuées (verts des plantes, ardoise et craie, couleurs vives).
static func _mats(M) -> void:
	var R = M.R
	if R.kit.mats.has("nu_vert"):
		return
	R._put("nu_vert", R._col(Color(0.3, 0.56, 0.27), 0.8))
	R._put("nu_vert_clair", R._col(Color(0.5, 0.72, 0.34), 0.8))
	R._put("nu_vert_sombre", R._col(Color(0.15, 0.34, 0.19), 0.85))
	R._put("nu_ardoise", R._col(Color(0.11, 0.16, 0.14), 0.92))
	R._put("nu_craie", R._col(Color(0.94, 0.94, 0.9), 1.0))
	R._put("nu_bleu", R._col(Color(0.45, 0.68, 0.92), 0.4))
	R._put("nu_jaune", R._col(Color(1.0, 0.82, 0.3), 0.6))
	R._put("nu_rose", R._col(Color(0.96, 0.6, 0.72), 0.7))
	R._put("nu_rouge", R._col(Color(0.88, 0.16, 0.18), 0.45))
	R._put("nu_lavande", R._col(Color(0.68, 0.6, 0.92), 0.8))
	R._put("nu_blanc", R._col(Color(0.97, 0.97, 0.96), 0.35))


## La baie du fond d'un côté (la plus loin de la porte) : [x du mur, z, côté (-1 : x < 0, 1 : x > 0)].
## Les baies sont celles de maisons_pieces_v81._windows (une par côté, deux si la pièce est profonde).
static func _baie(M, cote: float) -> Array:
	var R = M.R
	var nz: int = 1 if R.D < 7.0 else 2
	return [cote * R.W * 0.5, -R.D * 0.5 + R.D * 0.5 / nz, cote]


## Le vantail coulissant d'une baie (b : _baie) : un panneau de verre cerclé d'argent devant une
## moitié de la baie ; ouvert, il glisse devant l'autre moitié. Repère local : x le long du mur,
## y vers le haut, z vers la pièce (comme maisons_pieces_v81.window).
static func _vantail(M, b: Array) -> Dictionary:
	var R = M.R
	var c: float = float(b[2])
	var n: Node3D = I._node(M, R.P(c * (R.W * 0.5 - 0.02), 1.22, float(b[1])), -90.0 * c)
	var pan := Node3D.new()
	n.add_child(pan)
	var vitre := _verre(Color(0.82, 0.92, 1.0), 0.16)
	var alu := _mat(Color(0.86, 0.87, 0.9), 0.9, 0.3)
	_p(pan, I._boxm(Vector3(0.86, 2.04, 0.012)), vitre, Vector3(0.44, 0, 0.06))
	for sx in [0.02, 0.86]:
		_p(pan, I._boxm(Vector3(0.035, 2.06, 0.03)), alu, Vector3(sx, 0, 0.06))
	for sy in [-1.02, 1.02]:
		_p(pan, I._boxm(Vector3(0.88, 0.035, 0.03)), alu, Vector3(0.44, sy, 0.06))
	_p(pan, I._boxm(Vector3(0.025, 0.3, 0.03)), alu, Vector3(0.1, 0.0, 0.095))
	_sans_ombre(n)
	return {"n": n, "pan": pan, "ouvert": false, "cote": c}


## Ouvrir (ou fermer) le vantail : il glisse devant l'autre moitié de la baie.
static func _coulisser(M, v: Dictionary, ouvrir: bool) -> void:
	v["ouvert"] = ouvrir
	var pan: Node3D = v["pan"]
	var tw: Tween = M.room.create_tween()
	tw.tween_property(pan, "position:x", -0.86 if ouvrir else 0.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	M.main.sfx("porte_ouvre" if ouvrir else "porte_ferme", pan.global_position)


## Un point dans la baie (repère local du vantail : x le long du mur, z vers la pièce), en monde.
static func _dans_baie(v: Dictionary, loc: Vector3) -> Vector3:
	return (v["n"] as Node3D).to_global(loc)


## Tend un cylindre de hauteur 1 (I._cyl(r, r, 1.0)) entre a et b (monde) : une ficelle, un fil.
static func _tendre(mi: Node3D, a: Vector3, b: Vector3) -> void:
	var d: Vector3 = b - a
	var l: float = d.length()
	if l < 0.001:
		mi.visible = false
		return
	mi.visible = true
	var y: Vector3 = d / l
	var ref: Vector3 = Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x: Vector3 = y.cross(ref).normalized()
	var z: Vector3 = x.cross(y).normalized()
	mi.global_transform = Transform3D(Basis(x, y * l, z), (a + b) * 0.5)


## De fines gouttes de pluie (emitting = true : il pleut ; false : ça s'arrête).
static func _gouttes(M, n: int = 40) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = n
	p.lifetime = 0.8
	p.emitting = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.18, 0.02, 0.14)
	p.direction = Vector3.DOWN
	p.spread = 4.0
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.0
	p.gravity = Vector3(0, -5.0, 0)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.006, 0.05, 0.006)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.72, 0.86, 1.0, 0.75)
	bm.material = m
	p.mesh = bm
	M.room.add_child(p)
	return p


## L'air du dehors qui entre par une baie ouverte : de petites taches claires emportées vers la
## pièce (dir : la direction du vent, monde ; la bouche est verticale, le long du mur).
static func _souffle(M, at: Vector3, dir: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 32
	p.lifetime = 1.8
	p.emitting = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.05 + absf(dir.z) * 0.38, 0.85, 0.05 + absf(dir.x) * 0.38)
	p.direction = dir
	p.spread = 14.0
	p.initial_velocity_min = 1.4
	p.initial_velocity_max = 2.4
	p.gravity = Vector3.ZERO
	p.damping_min = 0.4
	p.damping_max = 0.8
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	gr.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.0)])
	p.color_ramp = gr
	var q := QuadMesh.new()
	q.size = Vector2(0.06, 0.06)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _tache()
	q.material = m
	p.mesh = q
	M.room.add_child(p)
	p.global_position = at
	return p


## Un petit arc-en-ciel (six bandes fines, en demi-cercle, toujours tourné vers nous) ; invisible
## au départ : on le fait apparaître en montant l'alpha de son matériau.
static func _arc_en_ciel(M, r0: float, r1: float) -> MeshInstance3D:
	var cols: Array = [Color(0.95, 0.25, 0.25), Color(1.0, 0.6, 0.2), Color(1.0, 0.92, 0.3), Color(0.35, 0.85, 0.4), Color(0.35, 0.6, 1.0), Color(0.62, 0.42, 0.95)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nb: int = cols.size()
	var seg: int = 24
	for b in range(nb):
		var ra: float = lerpf(r1, r0, float(b) / nb)
		var rb: float = lerpf(r1, r0, float(b + 1) / nb)
		var col: Color = cols[b]
		for i in range(seg):
			var a0: float = PI * float(i) / seg
			var a1: float = PI * float(i + 1) / seg
			var pts: Array = [Vector3(cos(a0) * ra, sin(a0) * ra, 0), Vector3(cos(a1) * ra, sin(a1) * ra, 0), Vector3(cos(a1) * rb, sin(a1) * rb, 0),
				Vector3(cos(a0) * ra, sin(a0) * ra, 0), Vector3(cos(a1) * rb, sin(a1) * rb, 0), Vector3(cos(a0) * rb, sin(a0) * rb, 0)]
			for v in pts:
				st.set_color(col)
				st.set_normal(Vector3(0, 0, 1))
				st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.albedo_color = Color(1, 1, 1, 0)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	M.room.add_child(mi)
	return mi


## Un tableau des Nuées (les couchers de soleil d'Ombeline, le plan de l'île…), cadre fin.
static func _tableau(M, x: float, y: float, z: float, yaw: float, w: float, h: float, idx: int = -1) -> void:
	var R = M.R
	R.mark_wall(x, y, z, w * 0.5 + 0.15)
	var n: int = (R.pal["tableaux"] as Array).size()
	var k: int = idx if idx >= 0 else _r(M).randi() % n
	var xf: Transform3D = R.L(x, y, z, yaw)
	R.kit.box(xf * Transform3D(Basis(), Vector3(0, 0, 0.02)), Vector3(w, h, 0.02), "tableau_%d" % (k % n), maxf(w, h), 16)
	var cadre: String = "argent" if _r(M).randf() < 0.5 else "bois_clair"
	for s in [-1.0, 1.0]:
		R.kit.box(xf * Transform3D(Basis(), Vector3(s * (w * 0.5 + 0.015), 0, 0.025)), Vector3(0.03, h + 0.06, 0.03), cadre, 1.0)
		R.kit.box(xf * Transform3D(Basis(), Vector3(0, s * (h * 0.5 + 0.015), 0.025)), Vector3(w + 0.06, 0.03, 0.03), cadre, 1.0)


## Des tableaux là où le mur est libre (baies, cheminée, tableau noir…) ; idx : l'image (-1 : au hasard).
static func _cadres(M, n: int, idx: int = -1) -> void:
	var R = M.R
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var y: float = minf(1.7, R.H - 0.8)
	var spots: Array = [[-R.W * 0.3, -hd + 0.02, 0.0], [R.W * 0.3, -hd + 0.02, 0.0], [-hw + 0.02, -hd * 0.6, 90.0], [hw - 0.02, -hd * 0.6, -90.0],
		[-hw + 0.02, hd * 0.35, 90.0], [hw - 0.02, hd * 0.35, -90.0], [0.0, -hd + 0.02, 0.0]]
	var placed: int = 0
	for s in spots:
		if placed >= n:
			break
		var w: float = _r(M).randf_range(0.6, 0.95)
		if not R.wall_free(float(s[0]), y, float(s[1]), w * 0.5 + 0.15):
			continue
		_tableau(M, float(s[0]), y, float(s[1]), float(s[2]), w, w * 0.7, idx)
		placed += 1


## La cheminée à l'éthanol, contre le mur du fond, en x.
static func _foyer(M, x: float) -> void:
	M.R.foyer(x, -M.R.D * 0.5 + 0.22, 0, true)


## Une table basse de céramique blanche aux pieds d'argent.
static func _table_basse(M, x: float, z: float, w: float = 1.0, d: float = 0.55) -> void:
	var R = M.R
	R.kit.box(R.L(x, 0.36, z), Vector3(w, 0.04, d), "ceramique", 1.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			R.kit.cyl(R.L(x + sx * (w * 0.5 - 0.06), 0.0, z + sz * (d * 0.5 - 0.06)), 0.015, 0.015, 0.34, "argent", 8, false)
	R.kit.col_box(R.L(x, 0.19, z), Vector3(w, 0.38, d))
	R.reserve(x, z, w + 0.2, d + 0.2)


## Un lampadaire d'argent à l'abat-jour blanc.
static func _lampadaire(M, x: float, z: float) -> void:
	var R = M.R
	R.kit.cyl(R.L(x, 0, z), 0.16, 0.16, 0.025, "argent", 16)
	R.kit.cyl(R.L(x, 0.02, z), 0.012, 0.012, 1.42, "argent", 8, false)
	R.kit.cyl(R.L(x, 1.36, z), 0.04, 0.04, 0.08, "lumiere", 8)
	R.kit.cyl(R.L(x, 1.3, z), 0.21, 0.14, 0.26, "tissu_blanc", 16, false)
	R.reserve(x, z, 0.45, 0.45)


## Un pot de céramique blanche et sa plante (fleur : la matière des fleurs, "" : pas de fleurs).
static func _pot(M, x: float, z: float, y: float = 0.0, s: float = 1.0, fleur: String = "") -> void:
	var R = M.R
	var r := _r(M)
	R.kit.cyl(R.L(x, y, z), 0.13 * s, 0.1 * s, 0.26 * s, "ceramique", 12)
	R.kit.cyl(R.L(x, y + 0.25 * s, z), 0.12 * s, 0.12 * s, 0.01, "terreau", 12)
	for k in range(6):
		var a: float = TAU * k / 6.0 + r.randf()
		var lx: Transform3D = R.L(x, y + 0.26 * s, z) * Transform3D(Basis(Vector3.UP, -a) * Basis(Vector3.RIGHT, r.randf_range(0.35, 0.8)), Vector3.ZERO)
		R.kit.box(lx * Transform3D(Basis(), Vector3(0, 0.17 * s, 0)), Vector3(0.09 * s, 0.34 * s, 0.015), "nu_vert" if k % 2 == 0 else "nu_vert_clair", 1.0)
	if fleur != "":
		for k2 in range(5):
			var a2: float = TAU * k2 / 5.0 + r.randf()
			R.kit.box(R.L(x + cos(a2) * 0.08 * s, y + (0.4 + r.randf() * 0.12) * s, z + sin(a2) * 0.08 * s, r.randf() * 90.0), Vector3(0.06, 0.035, 0.06) * s, fleur, 1.0)
	if y < 0.1:
		R.reserve(x, z, 0.4 * s, 0.4 * s)


# =================================================================== le nuage de compagnie

## Un petit nuage tout blanc (des boules douces, un peu translucides, qui respirent) se promène dans le
## salon : c'est le compagnon de l'enfant, un nuage orphelin recueilli par le Docteur Aurèle et confié
## à la famille. On peut le caresser : il va pleuvoir sur les plantes de la baie, puis il fait un petit
## arc-en-ciel (la première fois, un nuage en bocal). On peut ouvrir la baie : il va jeter un œil
## dehors… et revient. La nuit, l'enfant dort sur le canapé et le nuage lui fait une veilleuse.
static func _nuage(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var nuit: bool = _nuit(M)
	var s: float = 1.0 if r.randf() < 0.5 else -1.0
	var b: Array = _baie(M, s)
	var bz: float = float(b[1])
	var v: Dictionary = _vantail(M, b)
	var ni: int = r.randi() % 3
	var boy: bool = r.randf() < 0.5
	# la cheminée au fond, le canapé contre le mur d'en face (il regarde la baie), la table basse
	_foyer(M, R.W * 0.22 if R.W > 7.5 else s * R.W * 0.22)
	var cx: float = -s * (hw - 0.55)
	var cz: float = clampf(-0.25, -hd + 1.2, hd - 2.0)
	R.canape(cx, cz, 90.0 * s, str(_pick(M, ["blanc", "creme", "gris", "bleu"])))
	R.tapis(cx + s * 1.05, cz, 90, minf(2.2, R.D - 2.4), 1.5)
	_table_basse(M, cx + s * 1.05, cz, 0.5, 0.9)
	R.kit.cyl(R.L(cx + s * 1.05, 0.38, cz - 0.2), 0.05, 0.04, 0.09, "ceramique", 10)
	R.kit.cyl(R.L(cx + s * 1.05 - 0.1, 0.38, cz + 0.22), 0.07, 0.07, 0.03, "nu_bleu", 12)
	if R.is_free(cx, cz - 1.3, 0.45, 0.45):
		_lampadaire(M, cx, cz - 1.3)
	# la jardinière, devant la moitié fixe de la baie : c'est là qu'il pleut
	var jx: float = s * (hw - 0.2)
	var jz: float = bz - 0.44 * s
	R.kit.box(R.L(jx, 0.2, jz), Vector3(0.3, 0.4, 0.86), "ceramique", 1.0)
	R.kit.box(R.L(jx, 0.405, jz), Vector3(0.26, 0.01, 0.82), "terreau", 1.0)
	for k in range(9):
		var lz: float = jz - 0.36 + k * 0.09
		var lxf: Transform3D = R.L(jx + r.randf_range(-0.06, 0.06), 0.4, lz) * Transform3D(Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, r.randf_range(-0.5, 0.5)), Vector3.ZERO)
		R.kit.box(lxf * Transform3D(Basis(), Vector3(0, 0.14, 0)), Vector3(0.1, 0.28, 0.015), "nu_vert" if k % 2 == 0 else "nu_vert_clair", 1.0)
		if k % 3 == 1:
			R.kit.box(R.L(jx + r.randf_range(-0.05, 0.05), 0.6 + r.randf() * 0.08, lz, r.randf() * 90.0), Vector3(0.06, 0.035, 0.06), str(_pick(M, ["nu_rose", "nu_jaune", "nu_lavande"])), 1.0)
	R.kit.col_box(R.L(jx, 0.2, jz), Vector3(0.3, 0.4, 0.86))
	R.reserve(jx, jz, 0.6, 1.0)
	_cadres(M, 2)
	# les gens : le parent lit sur le canapé, l'enfant suit son nuage des yeux ; la nuit, l'enfant dort
	# sur le canapé et le parent veille, debout, en chuchotant
	var parent: Node
	var kid: Node
	if nuit:
		var nx: float = cx + s * 0.95
		var nz: float = cz - 0.95
		parent = M.person(str(_pick(M, ["homme", "femme"])), nx, nz, _vers(nx, nz, cx, cz), "mains_dos")
		parent.lines = ["Chut… il dort.", "Doucement, il fait de beaux rêves.", "Regarde : le nuage veille sur lui.", "Pas de pluie cette nuit, d'accord ?"]
		parent.line_every = Vector2(10.0, 15.0)
		kid = M.person("garcon" if boy else "fille", cx, cz, 90.0 * s, "dormir")
		kid.lie(R.P(cx + s * 0.06, 0.47, cz + 0.75), Vector3(0, 0, -1))
		kid.lines = ["Zzz…", ["Zzz… Pompon… pas sur l'oreiller… zzz…", "Zzz… Guimauve… pas sur l'oreiller… zzz…", "Zzz… Flocon… pas sur l'oreiller… zzz…"][ni], "Mmh… encore un arc-en-ciel… zzz…"]
		kid.line_every = Vector2(9.0, 14.0)
	else:
		parent = M.person(str(_pick(M, ["homme", "femme"])), cx + s * 0.05, cz - 0.475, 90.0 * s, "lire")
		parent.lines = ["Pas sur le canapé, le nuage ! … Bon, d'accord.", "Il a encore bu toute la rosée des fougères.", "Qui a laissé la bouilloire ouverte ? Il est tout gonflé !", "Bon vent, petit nuage."]
		var kx: float = s * 0.35
		var kz: float = clampf(cz + 0.6, -hd + 0.5, hd - 1.6)
		kid = M.person("garcon" if boy else "fille", kx, kz, _vers(kx, kz, 0.0, -0.3), "debout")
		kid.lines = [["Pompon, au pied ! … Enfin, au plafond !", "Guimauve, au pied ! … Enfin, au plafond !", "Flocon, au pied ! … Enfin, au plafond !"][ni],
			"Il fait des bulles quand il rit !", "Attention, il goutte !", "Plus tard, moi aussi, je serai un nuage."]
		kid.line_every = Vector2(6.0, 10.0)
	# le nuage : des boules blanches, deux yeux, deux joues roses, un sourire
	var nuage: Node3D = I._node(M, R.P(0, 1.85, -0.3), 0)
	var corps := Node3D.new()
	nuage.add_child(corps)
	var blanc := _verre(Color(1, 1, 1), 0.93, 0.9 if nuit else 0.35)
	blanc.roughness = 1.0
	var boule: SphereMesh = I._sph(1.0)
	for e in [[Vector3(0, 0, 0), 0.2], [Vector3(0.17, -0.03, 0.02), 0.15], [Vector3(-0.17, -0.03, 0.0), 0.15], [Vector3(0.06, 0.1, -0.03), 0.16],
			[Vector3(-0.08, 0.09, 0.04), 0.13], [Vector3(0.0, -0.06, -0.1), 0.13], [Vector3(0.29, -0.07, 0.0), 0.1], [Vector3(-0.29, -0.07, 0.02), 0.1]]:
		_p(corps, boule, blanc, e[0], Vector3.ONE * float(e[1]))
	var oeil := _mat(Color(0.12, 0.13, 0.2), 0.0, 0.3)
	var joue := _verre(Color(1.0, 0.6, 0.7), 0.55)
	var yeux: Array = []
	for sx in [-1.0, 1.0]:
		yeux.append(_p(corps, I._sph(0.02), oeil, Vector3(sx * 0.06, 0.03, 0.192), Vector3(1.0, 1.35, 0.6)))
		_p(corps, I._sph(0.022), joue, Vector3(sx * 0.11, -0.03, 0.17), Vector3(1.0, 0.7, 0.5))
	_p(corps, I._boxm(Vector3(0.035, 0.007, 0.006)), oeil, Vector3(0, -0.035, 0.198))
	_sans_ombre(nuage)
	var pluie: CPUParticles3D = _gouttes(M, 36)
	var arc: MeshInstance3D = _arc_en_ciel(M, 0.2, 0.32)
	var arc_m: StandardMaterial3D = arc.material_override
	# où il va : sa promenade, au-dessus de la jardinière, à la baie, au-dessus du canapé (la nuit)
	var dodo: Vector3 = R.P(cx + s * 0.2, 1.25, cz + 0.1)
	var pluie_at: Vector3 = R.P(jx - s * 0.12, 1.45, jz)
	var a_baie: Vector3 = _dans_baie(v, Vector3(0.44, 0.3, 0.75))
	var dehors: Vector3 = _dans_baie(v, Vector3(0.44, 0.25, -0.16))
	var retour: Vector3 = _dans_baie(v, Vector3(0.44, 0.4, 1.2))
	var ax: float = maxf(0.3, (R.W - 2.4) * 0.4)
	var az: float = maxf(0.3, (R.D - 3.0) * 0.4)
	var wz: float = -0.4
	var sol: float = R.P(0, 0, 0).y
	var depart: Vector3 = dodo if nuit else R.P(0.0, 1.85, wz)
	nuage.global_position = depart
	var st := {"t": r.randf() * 20.0, "mode": "dodo" if nuit else "balade", "phase": "", "d": 0.0, "pos": depart, "gris": 0.0, "cligne": 3.0, "coucou": 30.0}
	var balade := func(t: float) -> Vector3:
		return R.P(ax * sin(t * 0.17 + 0.6), 1.85 + 0.15 * sin(t * 0.41), wz + az * sin(t * 0.23 + 1.7))
	var montrer_arc := func(a: float) -> void:
		var tw: Tween = M.room.create_tween()
		tw.tween_property(arc_m, "albedo_color:a", a, 0.8)
		M.main.sfx("carillon", nuage.global_position)
	var cacher_arc := func() -> void:
		var tw: Tween = M.room.create_tween()
		tw.tween_property(arc_m, "albedo_color:a", 0.0, 1.0)
	var recompense := func() -> void:
		if bool(M.state().get("nu_nuage", false)):
			if nuit:
				parent.say("Il ne fait ses arcs-en-lune que pour les amis.", 3.5)
			else:
				kid.say(str(_pick(M, ["Encore ! Encore un arc-en-ciel !", "Il est fier, regarde ses joues !", "Bravo, mon nuage !"])), 3.0)
			return
		M.state()["nu_nuage"] = true
		var txt: String = "Un arc-en-lune… Il n'en fait que pour les gens qu'il aime bien. Tenez, tout bas : un tout petit nuage en bocal, son cousin. Il fait de minuscules averses." if nuit else "Il vous a fait son arc-en-ciel ! Il ne le fait que pour les gens qu'il aime bien. Tenez : un tout petit nuage en bocal, son cousin. Il fait de minuscules averses, comme lui."
		M.talk(parent, txt, I._bye("Merci, petit nuage !"), func(_i):
			M.give([["bocal_nuage", 1]], "")
			M.close_talk(), "à voix basse" if nuit else "sur un petit nuage")
	# le caresser (l'endroit où l'on appuie suit le nuage)
	var caresser := func() -> void:
		var mode0: String = str(st["mode"])
		if mode0 != "balade" and mode0 != "dodo":
			return
		M.main.sfx("ronron", nuage.global_position)
		_bulle(M, nuage.global_position + Vector3(0, 0.35, 0), "♥", Color(1.0, 0.72, 0.82), 46, 0.5, 1.4)
		if mode0 == "dodo":
			st["mode"] = "veille"
			st["d"] = 3.6
			montrer_arc.call(0.45)
			M.say(str(_pick(M, ["Le petit nuage ronronne tout bas. Il ne veut pas pleuvoir : l'enfant dort dessous. Alors il fait un arc-en-ciel tout pâle. Un arc-en-lune.",
				"Le nuage frissonne de plaisir, sans une goutte. Au-dessus de lui s'allume un arc-en-ciel très pâle, pour ne réveiller personne."])), 5.0)
			return
		st["mode"] = "pluie"
		st["phase"] = "va"
		kid.gesture("joie", 1.6)
		kid.say(str(_pick(M, ["Il adore ça ! Attention, il va pleuvoir !", "Il ronronne ! Enfin, il bruine.", "Caresse-le encore, il va faire son tour !"])), 3.0)
	var it_car: Dictionary = M.act(Vector3(depart.x, sol, depart.z), "E : caresser le petit nuage", caresser, 1.4, func(): return str(st["mode"]) == "balade" or str(st["mode"]) == "dodo")
	# ce qui bouge : sa promenade, sa respiration, ses yeux qui clignent, la pluie, l'arc-en-ciel
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(nuage):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var mode: String = str(st["mode"])
		var phase: String = str(st["phase"])
		var p0: Vector3 = st["pos"]
		var cible: Vector3 = balade.call(t)
		match mode:
			"dodo", "veille":
				cible = dodo + Vector3(0, 0.05 * sin(t * 0.5), 0)
				if mode == "veille":
					st["d"] = float(st["d"]) - dt
					if float(st["d"]) <= 0.0:
						st["mode"] = "dodo"
						cacher_arc.call()
						recompense.call()
			"pluie":
				cible = pluie_at
				if phase == "va" and p0.distance_to(pluie_at) < 0.1:
					st["phase"] = "averse"
					st["d"] = 2.8
					pluie.emitting = true
					M.main.sfx("verser", pluie_at)
					_bulle(M, pluie_at + Vector3(0, 0.3, 0), "Plic, ploc…", Color(0.75, 0.88, 1.0), 34, 0.4, 1.8)
				elif phase == "averse":
					st["d"] = float(st["d"]) - dt
					st["gris"] = minf(1.0, float(st["gris"]) + dt * 2.0)
					if float(st["d"]) <= 0.0:
						pluie.emitting = false
						st["phase"] = "arc"
						st["d"] = 3.4
						montrer_arc.call(0.8)
						kid.gesture("joie", 2.0)
						kid.say(str(_pick(M, ["Son arc-en-ciel ! Regarde !", "Il est content ! Il fait son arc-en-ciel !", "Ouaaah ! Les couleurs !"])), 3.0)
				elif phase == "arc":
					st["d"] = float(st["d"]) - dt
					if float(st["d"]) <= 0.0:
						st["mode"] = "balade"
						st["phase"] = ""
						cacher_arc.call()
						recompense.call()
			"dehors":
				if phase == "va":
					cible = a_baie
					if p0.distance_to(a_baie) < 0.12:
						st["phase"] = "regarde"
						st["d"] = 2.6
						_bulle(M, a_baie + Vector3(0, 0.35, 0), "?", Color(1, 1, 1), 46, 0.4, 1.4)
				elif phase == "regarde":
					cible = dehors
					st["d"] = float(st["d"]) - dt
					if float(st["d"]) <= 0.0:
						st["phase"] = "revient"
						kid.say(str(_pick(M, ["Reviens ! Reviens !", "Ne pars pas trop loin !", "Il dit bonjour aux grands nuages !"])), 2.5)
				else:
					cible = retour
					if p0.distance_to(retour) < 0.2:
						st["mode"] = "balade"
						st["phase"] = ""
						st["coucou"] = 30.0
						parent.say(str(_pick(M, ["Il revient toujours. Dehors, les autres nuages sont trop grands.", "Le voilà. Il préfère les plantes vertes aux grands courants d'air.", "Tu vois ? Il rentre toujours pour le goûter."])), 4.0)
		var vite: float = 0.8 if mode == "balade" else 1.4
		var p: Vector3 = p0.lerp(cible, 1.0 - exp(-dt * vite))
		st["pos"] = p
		nuage.global_position = p
		pluie.global_position = p + Vector3(0, -0.14, 0)
		arc.global_position = p + Vector3(0, 0.2, 0)
		it_car["pos"] = Vector3(p.x, sol, p.z)
		# il regarde le visiteur ; il respire ; il cligne des yeux (il les ferme pour dormir, et de joie)
		var pp: Vector3 = M.main._player_pos_v27()
		nuage.rotation.y = lerp_angle(nuage.rotation.y, atan2(pp.x - p.x, pp.z - p.z), clampf(dt * 2.0, 0.0, 1.0))
		var resp: float = sin(t * (0.8 if mode == "dodo" or mode == "veille" else 1.5))
		corps.scale = Vector3(1.0 + 0.04 * resp, 1.0 + 0.06 * resp, 1.0 + 0.04 * resp)
		st["cligne"] = float(st["cligne"]) - dt
		if float(st["cligne"]) <= 0.0:
			st["cligne"] = 2.5 + randf() * 3.0
		var ferme: bool = mode == "dodo" or mode == "veille" or float(st["cligne"]) < 0.12 or str(st["phase"]) == "arc"
		for e2 in yeux:
			(e2 as Node3D).scale.y = 0.2 if ferme else 1.35
		var g: float = float(st["gris"])
		if str(st["phase"]) != "averse":
			g = maxf(0.0, g - dt * 1.2)
			st["gris"] = g
		blanc.albedo_color = Color(1, 1, 1, 0.93).lerp(Color(0.78, 0.82, 0.88, 0.93), g)
		# la baie reste ouverte : de temps en temps, il retourne jeter un œil
		if mode == "balade" and bool(v["ouvert"]):
			st["coucou"] = float(st["coucou"]) - dt
			if float(st["coucou"]) <= 0.0:
				st["mode"] = "dehors"
				st["phase"] = "va"
	# ouvrir et refermer la baie, parler aux gens
	var a_ouvrir: Vector3 = _dans_baie(v, Vector3(0.44, -1.22, 0.8))
	M.act(a_ouvrir, "E : ouvrir la baie vitrée", func() -> void:
		_coulisser(M, v, true)
		if str(st["mode"]) == "balade":
			st["mode"] = "dehors"
			st["phase"] = "va"
			if not nuit:
				kid.say(str(_pick(M, ["Il va voir dehors !", "Oh non, il va regarder les grands nuages…", "Pas trop loin, hein !"])), 2.5)
		elif nuit:
			parent.say("Juste un peu d'air frais, alors. Tout doucement.", 3.5)
	, 1.2, func(): return not bool(v["ouvert"]))
	M.act(a_ouvrir, "E : refermer la baie vitrée", func() -> void:
		_coulisser(M, v, false)
		if str(st["mode"]) == "dehors":
			st["phase"] = "revient"
	, 1.2, func(): return bool(v["ouvert"]))
	var parent_cb := func() -> void:
		if nuit:
			M.talk(parent, "Chut… Le petit dort. Le nuage veille sur lui : il fait veilleuse, il brille un peu quand l'enfant rêve.",
				[{"id": "brille", "label": "Il brille vraiment ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if id == "brille":
					M.talk(parent, "Regardez bien : plus le rêve est beau, plus il brille. Ce soir, ça doit être un rêve de chouquettes.", I._bye("Chut… Bonne nuit !"), I._close(M), "à voix basse")
				else:
					M.close_talk()
			, "à voix basse")
			return
		var accueil: String = str(_pick(M, ["Bonjour ! Attention où vous marchez : quand il a bu, il goutte un peu. C'est le nuage de mon fils." if boy else "Bonjour ! Attention où vous marchez : quand il a bu, il goutte un peu. C'est le nuage de ma fille.",
			"Bon vent ! Vous avez vu notre locataire ? Il ne paie pas de loyer, mais il arrose les plantes."]))
		M.talk(parent, accueil, [{"id": "ou", "label": "D'où vient ce petit nuage ?"}, {"id": "mange", "label": "Qu'est-ce qu'il mange ?"}, {"id": "fermer", "label": "Bon vent !"}], func(id):
			match id:
				"ou":
					M.talk(parent, "Un nuage orphelin ! Le Docteur Aurèle l'a trouvé tout seul sous la Gare, trop petit pour suivre les autres. Il nous l'a confié en disant : « Il lui faut une famille et une plante verte. »", I._bye("Il a bien trouvé !"), I._close(M), "sur un petit nuage")
				"mange":
					M.talk(parent, "La vapeur de la bouilloire, le matin. La rosée des plantes. Et les bulles de savon : il en raffole, mais il les rate toutes.", I._bye("Ha ha !"), I._close(M), "sur un petit nuage")
				_:
					M.close_talk()
		, "sur un petit nuage")
	M.talk_spot(parent, parent_cb)
	var kid_cb := func() -> void:
		if nuit:
			M.talk(kid, ["Zzz… Pompon… tu gouttes sur mon nez… zzz…", "Zzz… Guimauve… tu gouttes sur mon nez… zzz…", "Zzz… Flocon… tu gouttes sur mon nez… zzz…"][ni], I._bye("(Le laisser dormir)") if boy else I._bye("(La laisser dormir)"), I._close(M), "endormi" if boy else "endormie")
			return
		M.talk(kid, ["C'est mon nuage ! Il s'appelle Pompon. Le Docteur Aurèle dit que c'est un cumulus. Moi, je dis que c'est un Pompon.", "C'est mon nuage ! Il s'appelle Guimauve. Le Docteur Aurèle dit que c'est un cumulus. Moi, je dis que c'est une Guimauve.", "C'est mon nuage ! Il s'appelle Flocon. Le Docteur Aurèle dit que c'est un cumulus. Moi, je dis que c'est un Flocon."][ni],
			[{"id": "tour", "label": "Il sait faire des tours ?"}, {"id": "part", "label": "Il ne s'envole jamais ?"}, {"id": "fermer", "label": "Salut !"}], func(id):
			match id:
				"tour":
					M.talk(kid, "Caresse-le ! Il fait la pluie sur les plantes, et après, il fait un arc-en-ciel. Il est très fier de son arc-en-ciel.", I._bye("Je vais essayer !"), I._close(M), "aux anges")
				"part":
					M.talk(kid, "Des fois, il va regarder dehors, par la baie. Mais il revient toujours. Dehors, les autres nuages sont trop grands. Ici, il a moi.", I._bye("Il a de la chance."), I._close(M), "aux anges")
				_:
					M.close_talk()
		, "aux anges")
	M.talk_spot(kid, kid_cb)
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Un enfant dort sur le canapé. Au-dessus de lui, un petit nuage brille tout doucement, comme une veilleuse.",
			"Tout est calme. Un petit nuage flotte au-dessus du canapé, où dort un enfant. Il respire en même temps que lui.",
			"Il fait nuit dans le salon. Seul un petit nuage blanc luit au-dessus d'un enfant endormi. Quelqu'un te fait « chut » du doigt."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Un petit nuage tout blanc flotte au milieu du salon, comme un ballon qui aurait appris à rêver. Un enfant le suit des yeux, ravi.",
			"Tiens, il pleut ? Non : c'est le petit nuage de la maison qui passe au-dessus de toi. Il a l'air très content de te voir.",
			"Un canapé, des plantes… et un nuage. Un vrai, tout petit, qui se promène à hauteur de lampe en clignant des yeux."]))


# =================================================================== le grand cerf-volant

## Les couleurs du cerf-volant (une palette par maison) : les quatre triangles du losange.
const PALETTES_CV := [
	[Color(0.9, 0.2, 0.18), Color(1.0, 0.82, 0.25), Color(0.2, 0.45, 0.85), Color(0.25, 0.68, 0.35)],
	[Color(0.55, 0.78, 0.98), Color(0.98, 0.98, 0.96), Color(0.55, 0.78, 0.98), Color(0.98, 0.98, 0.96)],
	[Color(1.0, 0.55, 0.15), Color(0.6, 0.35, 0.85), Color(1.0, 0.85, 0.3), Color(0.2, 0.7, 0.72)],
]


## Le losange de toile d'un cerf-volant (quatre triangles de couleur, visibles des deux côtés) : le haut
## en +Y, la face en +Z ; w : la demi-largeur, h : la demi-hauteur, y0 : la hauteur de la baguette en travers.
static func _losange(cols: Array, w: float, h: float, y0: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var haut := Vector3(0, h, 0)
	var bas := Vector3(0, -h, 0)
	var g := Vector3(-w, y0, 0)
	var d := Vector3(w, y0, 0)
	var c := Vector3(0, y0, 0)
	var tris: Array = [[haut, g, c], [haut, c, d], [g, bas, c], [c, bas, d]]
	for i in range(4):
		for q in tris[i]:
			st.set_color(cols[i % cols.size()])
			st.set_normal(Vector3(0, 0, 1))
			st.add_vertex(q)
	return st.commit()


## Une famille fabrique un immense cerf-volant pour la Fête des Vents : il est couché sur le tapis, sa
## queue de rubans traverse la pièce ; dans un coin, un gros ventilateur sur pied. On allume : le
## cerf-volant se soulève et danse sous le plafond (il frôle le plafonnier), les rubans ondulent, les
## plans s'envolent, tout le monde crie et rit ; on éteint : il se repose, on ramasse les papiers. On
## peut tenir la ficelle (la première fois : le petit cerf-volant de l'entraînement). La nuit, l'enfant
## dort sur le tapis à côté du Géant, et l'on coud les derniers rubans en chuchotant.
static func _cerf_volant(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var room0: Node = M.room
	var nuit: bool = _nuit(M)
	var s: float = 1.0 if r.randf() < 0.5 else -1.0
	var cols: Array = PALETTES_CV[r.randi() % PALETTES_CV.size()]
	var boy: bool = r.randf() < 0.5
	var sol: float = R.P(0, 0, 0).y
	# la table de travail au fond (les plans, les bobines de ruban, les ciseaux), le grand tapis
	var tx: float = -s * R.W * 0.15
	var tz: float = -hd + 0.6
	R.table(tx, tz, 0, 1.4, 0.7, 0.76)
	R.chaise(tx - s * 1.1, tz + 0.05, 90.0 * s)
	for k in range(4):
		R.kit.cyl(R.L(tx + s * (0.15 + k * 0.12), 0.76, tz - 0.2), 0.045, 0.045, 0.05, ["tissu_rouge", "tissu_jaune", "tissu_bleu", "tissu_vert"][k], 10)
	R.kit.box(R.L(tx + s * 0.5, 0.765, tz + 0.12, 25), Vector3(0.16, 0.01, 0.05), "argent", 1.0)
	var kz: float = clampf(-0.2, -hd + 1.4, hd - 2.4)
	R.tapis(s * 0.1, kz, 0, minf(3.0, R.W - 2.0), minf(2.2, R.D - 2.6))
	_cadres(M, 2)
	# le tabouret de la bobine (la ficelle part de là), près de l'enfant
	var bx: float = -s * 0.95
	var bz: float = clampf(kz + 0.8, -hd + 0.5, hd - 1.6)
	R.tabouret(bx, bz)
	R.reserve(bx, bz, 0.45, 0.45)
	R.kit.cyl(R.L(bx, 0.44, bz), 0.07, 0.07, 0.015, "bois_clair", 14)
	R.kit.cyl(R.L(bx, 0.455, bz), 0.035, 0.035, 0.09, "tissu_blanc", 12)
	R.kit.cyl(R.L(bx, 0.545, bz), 0.07, 0.07, 0.015, "bois_clair", 14)
	var bobine_at: Vector3 = R.P(bx, 0.5, bz)
	# le gros ventilateur, dans le coin du fond, tourné vers le cerf-volant
	var fx: float = s * (hw - 0.6)
	var fz: float = -hd + 0.65
	R.reserve(fx, fz, 0.7, 0.7)
	var vol_c: Vector3 = R.P(s * 0.15, 2.0, kz)
	var vent: Node3D = I._node(M, R.P(fx, 0, fz), _vers(fx, fz, s * 0.15, kz))
	var blanc := _mat(Color(0.96, 0.96, 0.95), 0.0, 0.35)
	var alu := _mat(Color(0.85, 0.86, 0.88), 0.9, 0.3)
	_p(vent, I._cyl(0.22, 0.24, 0.04, 24), blanc, Vector3(0, 0.02, 0))
	_p(vent, I._cyl(0.025, 0.025, 1.2, 10), alu, Vector3(0, 0.62, 0))
	var tete := Node3D.new()
	vent.add_child(tete)
	tete.position = Vector3(0, 1.25, 0)
	var dist_f: float = Vector2(s * 0.15 - fx, kz - fz).length()
	tete.rotation.x = -atan2(0.7, maxf(1.0, dist_f))
	_p(tete, I._cyl(0.1, 0.1, 0.2, 16), blanc, Vector3(0, 0, -0.14), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_p(tete, I._cyl(0.38, 0.38, 0.16, 28), _verre(Color(0.86, 0.88, 0.92), 0.2), Vector3(0, 0, 0.04), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	var tor := TorusMesh.new()
	tor.inner_radius = 0.36
	tor.outer_radius = 0.39
	tor.rings = 28
	tor.ring_segments = 6
	for rz in [-0.04, 0.12]:
		_p(tete, tor, alu, Vector3(0, 0, rz), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_p(tete, I._cyl(0.06, 0.06, 0.02, 16), blanc, Vector3(0, 0, 0.13), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	var helice := Node3D.new()
	tete.add_child(helice)
	helice.position = Vector3(0, 0, 0.04)
	var pale_m := _mat(Color(0.62, 0.8, 0.96), 0.0, 0.4)
	for k2 in range(3):
		var pale := Node3D.new()
		helice.add_child(pale)
		pale.rotation.z = TAU * k2 / 3.0
		_p(pale, I._boxm(Vector3(0.13, 0.28, 0.01)), pale_m, Vector3(0, 0.17, 0), Vector3.ONE, Vector3(0, 0.35, 0))
	_sans_ombre(vent)
	var fan_w: Vector3 = vent.global_position
	var souffle: CPUParticles3D = _souffle(M, tete.global_position, (vol_c - tete.global_position).normalized())
	souffle.emission_box_extents = Vector3(0.22, 0.22, 0.22)
	souffle.lifetime = 1.1
	# le cerf-volant : le losange de toile et ses deux baguettes ; couché sur le tapis, le haut vers le ventilateur
	var cv := Node3D.new()
	M.room.add_child(cv)
	var toile := StandardMaterial3D.new()
	toile.vertex_color_use_as_albedo = true
	toile.cull_mode = BaseMaterial3D.CULL_DISABLED
	toile.roughness = 0.8
	var lmi := MeshInstance3D.new()
	lmi.mesh = _losange(cols, 0.55, 0.8, 0.22)
	lmi.material_override = toile
	cv.add_child(lmi)
	var baguette := _mat(Color(0.86, 0.74, 0.55), 0.0, 0.7)
	_p(cv, I._cyl(0.008, 0.008, 1.6, 6), baguette, Vector3(0, 0, 0.012))
	_p(cv, I._cyl(0.008, 0.008, 1.1, 6), baguette, Vector3(0, 0.22, 0.014), Vector3.ONE, Vector3(0, 0, PI * 0.5))
	_sans_ombre(cv)
	var repos: Vector3 = R.P(s * 0.15, 0.03, kz)
	var q_repos: Quaternion = Basis(Vector3(0, 0, s), Vector3(s, 0, 0), Vector3(0, 1, 0)).get_rotation_quaternion()
	cv.global_transform = Transform3D(Basis(q_repos), repos)
	# la queue : quatorze nœuds de rubans, posés à travers la pièce (une ligne brisée sur le sol)
	var o: Vector3 = R.P(0, 0, 0)
	var ligne: Array = [cv.global_transform * Vector3(0, -0.8, 0), R.P(-s * (hw - 1.0), 0.02, clampf(kz + 0.3, -hd + 0.6, hd - 1.6)),
		R.P(-s * (hw - 1.0), 0.02, -hd + 1.0), R.P(-s * 0.1, 0.02, -hd + 1.05)]
	var nq: int = 14
	var repos_q: Array = []
	for i in range(nq):
		var d0: float = 0.28 * (i + 1)
		var pt: Vector3 = ligne[ligne.size() - 1]
		for j in range(ligne.size() - 1):
			var a: Vector3 = ligne[j]
			var bb: Vector3 = ligne[j + 1]
			var l: float = a.distance_to(bb)
			if d0 <= l:
				pt = a.lerp(bb, d0 / maxf(l, 0.001))
				break
			d0 -= l
		var nrm: Vector3 = Vector3(sin(i * 1.7), 0, cos(i * 1.3)) * 0.06
		repos_q.append(Vector3(pt.x, o.y + 0.02, pt.z) + nrm)
	var noeuds: Array = []
	var segs: Array = []
	var ficelle_m := _mat(Color(0.92, 0.9, 0.84), 0.0, 0.9)
	var fil_mesh: CylinderMesh = I._cyl(0.004, 0.004, 1.0, 4)
	for i2 in range(nq):
		var nb := Node3D.new()
		M.room.add_child(nb)
		var rub := _mat(cols[i2 % cols.size()], 0.0, 0.7)
		for sx in [-1.0, 1.0]:
			_p(nb, I._boxm(Vector3(0.1, 0.006, 0.05)), rub, Vector3(sx * 0.05, 0, 0), Vector3.ONE, Vector3(0, sx * 0.5, 0))
		nb.global_position = repos_q[i2]
		noeuds.append(nb)
		segs.append(_p(M.room, fil_mesh, ficelle_m, Vector3.ZERO))
	var fil: MeshInstance3D = _p(M.room, fil_mesh, ficelle_m, Vector3.ZERO)
	# les plans du cerf-volant, sur la table (ils s'envolent quand le ventilateur souffle)
	var papiers: Array = []
	var pap_m := _mat(Color(0.97, 0.96, 0.92), 0.0, 0.9)
	var pmesh: BoxMesh = I._boxm(Vector3(0.21, 0.003, 0.29))
	for k3 in range(6):
		var pm: MeshInstance3D = _p(M.room, pmesh, pap_m, Vector3.ZERO)
		var pp0: Vector3 = R.P(tx + r.randf_range(-0.55, 0.55), 0.763 + k3 * 0.002, tz + r.randf_range(-0.16, 0.16))
		pm.global_position = pp0
		pm.rotation.y = r.randf() * TAU
		pm.set_meta("base", pp0)
		pm.set_meta("rot", pm.rotation)
		papiers.append(pm)
	# les gens : le parent noue les rubans, l'enfant attend près de la bobine, l'ancien coud à la table
	var px: float = s * 0.62
	var pz: float = clampf(kz + 0.85, -hd + 0.5, hd - 1.6)
	var parent: Node = M.person(str(_pick(M, ["homme", "femme"])), px, pz, _vers(px, pz, s * 0.15, kz), "bricoler")
	var ancien: Node = M.person(str(_pick(M, ["vieux", "vieille"])), tx - s * 1.1, tz + 0.05, 90.0 * s, "dormir_assis" if nuit else "tricot")
	var kid: Node
	if nuit:
		kid = M.person("garcon" if boy else "fille", bx - s * 0.2, bz + 0.1, -90.0 * s, "dormir")
		kid.lie(R.P(bx - s * 0.2, 0.04, bz + 0.1), Vector3(-s, 0, 0))
		R.kit.box(R.L(bx - s * 1.3, 0.05, bz + 0.1), Vector3(0.3, 0.1, 0.22), "tissu_bleu", 1.0)
		kid.lines = ["Zzz…", "Zzz… plus haut… plus haut… zzz…", "Mmh… le Géant… zzz…"]
		kid.line_every = Vector2(9.0, 14.0)
		parent.lines = ["Chut… le petit dort.", "Plus que trois nœuds…", "Tout doux, tout doux…"]
		parent.line_every = Vector2(10.0, 15.0)
		ancien.lines = ["Zzz…", "Zzz… quarante-huit nœuds… zzz…"]
	else:
		var kx: float = bx - s * 0.45
		kid = M.person("garcon" if boy else "fille", kx, bz, _vers(kx, bz, s * 0.15, kz), "debout")
		kid.lines = ["Le plus grand de toute la Fête des Vents !", "On l'appelle le Géant !", "Allume le ventilateur ! Allume !", "Lili va être jalouse !"]
		kid.line_every = Vector2(6.0, 10.0)
		parent.lines = ["Encore un nœud…", "Qui a marché sur la queue ?", "Il faudra le plier en quatre pour le sortir.", "Attention à la lampe, surtout."]
		ancien.lines = ["Un nœud, deux nœuds… quarante-sept nœuds.", "De mon temps, la queue faisait trois mètres. Et on trouvait ça long.", "Qui a pris mes ciseaux ?"]
	ancien.line_every = Vector2(9.0, 14.0)
	var st := {"t": r.randf() * 10.0, "on": false, "vit": 0.0, "k": 0.0, "tient": 0.0, "lampe": 0.0}
	# les papiers s'envolent (et retombent n'importe où), puis on les range sur la table
	var envoler := func() -> void:
		for pm2 in papiers:
			var n2: Node3D = pm2
			var old: Variant = n2.get_meta("tw", null)
			if old is Tween and (old as Tween).is_valid():
				(old as Tween).kill()
			var from: Vector3 = n2.global_position
			var away: Vector3 = Vector3(from.x - fan_w.x, 0, from.z - fan_w.z).normalized()
			var apex: Vector3 = from + away * randf_range(0.4, 1.0) + Vector3(randf_range(-0.4, 0.4), randf_range(1.0, 1.6), randf_range(-0.4, 0.4))
			var land: Vector3 = Vector3(clampf(apex.x - o.x + randf_range(-0.6, 0.6), -hw + 0.4, hw - 0.4) + o.x, o.y + 0.012, clampf(apex.z - o.z + randf_range(-0.6, 0.6), -hd + 0.4, hd - 0.4) + o.z)
			var tw: Tween = M.room.create_tween()
			tw.tween_interval(randf() * 0.3)
			tw.tween_property(n2, "global_position", apex, randf_range(0.6, 0.9)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(n2, "rotation", Vector3(randf_range(-1.2, 1.2), randf() * TAU, randf_range(-1.2, 1.2)), 0.8)
			tw.tween_property(n2, "global_position", land, randf_range(1.6, 2.4)).set_trans(Tween.TRANS_SINE)
			tw.parallel().tween_property(n2, "rotation", Vector3(0, randf() * TAU, 0), 2.0)
			n2.set_meta("tw", tw)
	var ranger := func() -> void:
		for pm3 in papiers:
			var n3: Node3D = pm3
			var old2: Variant = n3.get_meta("tw", null)
			if old2 is Tween and (old2 as Tween).is_valid():
				(old2 as Tween).kill()
			var tw2: Tween = M.room.create_tween()
			tw2.tween_property(n3, "global_position", n3.get_meta("base"), 0.8).set_trans(Tween.TRANS_SINE)
			tw2.parallel().tween_property(n3, "rotation", n3.get_meta("rot"), 0.8)
			n3.set_meta("tw", tw2)
	var allumer := func() -> void:
		st["on"] = true
		M.main.sfx("mecanisme", vent.global_position)
		M.main.sfx("bourrasque", vol_c)
		souffle.emitting = true
		envoler.call()
		_bulle(M, vol_c + Vector3(0, 0.6, 0), "Fwoooosh !", Color(0.85, 0.95, 1.0), 44, 0.5, 1.8)
		if nuit:
			parent.say("Chut ! … Bon, juste un petit tour.", 3.0)
			S._say_late(M, kid, "Zzz… il vole… zzz…", 2.0)
			return
		kid.gesture("joie", 2.5)
		parent.gesture("rire", 2.5)
		kid.say(str(_pick(M, ["Il vole ! IL VOLE !", "Ouaaaais ! Le Géant décolle !", "Plus haut ! Plus haut !"])), 3.0)
		S._say_late(M, parent, str(_pick(M, ["La lampe ! Attention à la lampe !", "Ha ha ! Il danse !", "Mes plans ! Ils s'envolent !"])), 1.2)
		S._say_late(M, ancien, str(_pick(M, ["Mes rubans ! Mes rubans !", "Ho ho ! Comme au Parc des Brumes !", "Tenez-le, il va partir au Plancher !"])), 2.2)
	var eteindre := func() -> void:
		st["on"] = false
		st["tient"] = 0.0
		souffle.emitting = false
		M.main.sfx("mecanisme", vent.global_position)
		if not nuit:
			kid.say(str(_pick(M, ["Ohhh… Encore !", "Il s'est posé comme une plume !", "Encore une fois ! Juste une !"])), 3.0)
		await M.get_tree().create_timer(3.5).timeout
		if not _la(M, room0) or bool(st["on"]):
			return
		ranger.call()
		if not nuit:
			ancien.say(str(_pick(M, ["Je ramasse les papiers. Comme d'habitude.", "Et hop, les plans sur la table.", "Ce ventilateur, c'est une tornade en pyjama."])), 3.0)
	# tenir la ficelle (la première fois : le petit cerf-volant de l'entraînement)
	var fin_tenir := func() -> void:
		if bool(M.state().get("nu_cerfvolant", false)):
			M.say(str(_pick(M, ["Tu reposes doucement la bobine sur le tabouret. Le Géant continue de danser tout seul.", "La ficelle retourne sur sa bobine. Tes bras se souviennent encore du vent."])), 4.0)
			return
		M.state()["nu_cerfvolant"] = true
		var cad: String = _neuf(M, "cerf_volant", "chouquettes")
		var txt: String
		if nuit:
			txt = "Tu l'as tenu comme un vrai pilote… Chut. Tiens : notre petit cerf-volant, celui de l'entraînement. Demain, à la Fête des Vents, tu voleras avec nous." if cad == "cerf_volant" else "Tu l'as tenu comme un vrai pilote… Chut. Tu as déjà un cerf-volant ? Alors des chouquettes : à la Fête des Vents, on vole mieux le ventre plein."
		else:
			txt = "Tu l'as tenu comme un vrai pilote ! Tiens : notre petit cerf-volant, celui de l'entraînement. À la Fête des Vents, tu voleras avec nous !" if cad == "cerf_volant" else "Tu l'as tenu comme un vrai pilote ! Tu as déjà un cerf-volant ? Alors des chouquettes : à la Fête des Vents, on vole mieux le ventre plein."
		M.talk(parent, txt, I._bye("Merci ! Bon vent !"), func(_i):
			M.give([[cad, 1]], "")
			M.close_talk(), "à voix basse" if nuit else "enthousiaste")
	var tenir := func() -> void:
		if float(st["tient"]) > 0.0:
			return
		if not bool(st["on"]) or float(st["k"]) < 0.6:
			M.say(str(_pick(M, ["La ficelle pend, toute molle. Sans vent, même le plus grand cerf-volant de la Fête reste couché. Et si on allumait le ventilateur ?",
				"Tu tires un peu sur la ficelle. Le cerf-volant glisse de deux centimètres sur le tapis. C'est un début."])), 4.5)
			return
		st["tient"] = 8.0
		M.main.sfx("bourrasque", cv.global_position)
		_bulle(M, M.main._player_pos_v27() + Vector3(0, 2.0, 0), "Ça tire !", Color(1.0, 0.92, 0.6), 44, 0.4, 1.6)
		if nuit:
			parent.say("Tiens-le bien… tout doucement.", 3.0)
		else:
			kid.gesture("joie", 2.0)
			kid.say(str(_pick(M, ["C'est toi le pilote ! Tiens bon !", "Il tire ! Il veut partir à Hautefond !", "Pas trop fort, il va emporter la lampe !"])), 3.0)
	# ce qui bouge : l'hélice, le cerf-volant (du tapis jusque sous le plafond), la queue, la ficelle
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(cv):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var on: bool = bool(st["on"])
		var vit: float = move_toward(float(st["vit"]), 1.0 if on else 0.0, dt * (0.8 if on else 0.35))
		st["vit"] = vit
		helice.rotation.z += dt * vit * 28.0
		var k: float = move_toward(float(st["k"]), 1.0 if on else 0.0, dt * (0.45 if on else 0.35))
		st["k"] = k
		var ke: float = smoothstep(0.0, 1.0, k)
		var tient: float = float(st["tient"])
		var fort: float = 1.6 if tient > 0.0 else 1.0
		var pv: Vector3 = vol_c + Vector3(0.28 * sin(t * 1.3), 0.12 * sin(t * 2.2 + 1.0), 0.22 * sin(t * 0.9 + 2.0)) * fort
		pv.y = minf(pv.y, vol_c.y + 0.12)
		var to_f: Vector3 = Vector3(fan_w.x - pv.x, 0, fan_w.z - pv.z).normalized()
		var tilt: float = 0.45 + 0.08 * sin(t * 1.9)
		var yv: Vector3 = (Vector3.UP * cos(tilt) - to_f * sin(tilt)).normalized()
		var zv: Vector3 = (to_f * cos(tilt) + Vector3.UP * sin(tilt)).normalized()
		var bf := Basis(yv.cross(zv), yv, zv)
		bf = Basis(zv, (0.35 * sin(t * 1.7) + 0.1 * sin(t * 4.3)) * fort) * bf
		var q: Quaternion = q_repos.slerp(bf.get_rotation_quaternion(), ke)
		cv.global_transform = Transform3D(Basis(q), repos.lerp(pv, ke))
		# il frôle le plafonnier : « Tink ! »
		st["lampe"] = maxf(0.0, float(st["lampe"]) - dt)
		var haut: Vector3 = cv.global_transform * Vector3(0, 0.8, 0)
		if ke > 0.9 and float(st["lampe"]) <= 0.0 and haut.distance_to(R.P(0, R.H - 0.06, 0)) < 0.6:
			st["lampe"] = 7.0
			M.main.sfx("clochette", haut)
			_bulle(M, haut + Vector3(0, 0.05, 0), "Tink !", Color(1.0, 0.95, 0.7), 36, 0.3, 1.2)
			if not nuit:
				parent.say(str(_pick(M, ["La lampe ! Il a touché la lampe !", "Ouh là, le plafonnier !", "Il fait la bise à la lampe !"])), 2.5)
		# la queue : posée à travers la pièce, ou qui ondule sous le cerf-volant
		var tip: Vector3 = cv.global_transform * Vector3(0, -0.8, 0)
		var cote: Vector3 = to_f.cross(Vector3.UP).normalized()
		var prev: Vector3 = tip
		for i3 in range(nq):
			var dd: float = 0.28 * (i3 + 1)
			var fly: Vector3 = tip - to_f * (dd * 0.55) + Vector3(0, -dd * 0.62 + 0.07 * sin(dd * 3.1 - t * 7.0), 0) + cote * (0.2 * sin(dd * 2.4 - t * 6.0) * minf(1.0, dd / 1.5))
			fly.y = maxf(fly.y, sol + 0.03)
			var q2: Vector3 = (repos_q[i3] as Vector3).lerp(fly, ke)
			var nb2: Node3D = noeuds[i3]
			nb2.global_position = q2
			var dir2: Vector3 = q2 - prev
			nb2.rotation = Vector3(0, atan2(dir2.x, dir2.z), 0.6 * sin(t * 9.0 + i3) * ke)
			_tendre(segs[i3], prev, q2)
			prev = q2
		# la ficelle : de la bride jusqu'à la bobine… ou jusqu'à ta main
		var bride: Vector3 = cv.global_transform * Vector3(0, 0.1, 0.2)
		var bout: Vector3 = bobine_at
		if tient > 0.0:
			var pp: Vector3 = M.main._player_pos_v27()
			bout = pp + Vector3(0, 1.15, 0) + Vector3(pv.x - pp.x, 0, pv.z - pp.z).normalized() * 0.35
			tient -= dt
			st["tient"] = maxf(0.0, tient)
			if tient <= 0.0:
				fin_tenir.call()
		_tendre(fil, bride, bout)
	# ce qu'on fait : allumer, éteindre, tenir la ficelle, parler au parent
	var a_vent: Vector3 = R.P(fx - s * 0.75, 0, fz + 0.55)
	M.act(a_vent, "E : allumer le gros ventilateur", func(): allumer.call(), 1.2, func(): return not bool(st["on"]))
	M.act(a_vent, "E : éteindre le gros ventilateur", func(): eteindre.call(), 1.2, func(): return bool(st["on"]))
	M.act(R.P(bx, 0, bz), "E : tenir la ficelle du cerf-volant", tenir, 1.1)
	var parent_cb := func() -> void:
		if nuit:
			M.talk(parent, "Chut… Le petit s'est endormi à côté de son cerf-volant. On finit les derniers nœuds tout doucement : la Fête des Vents, c'est demain.",
				[{"id": "aider", "label": "Je peux aider ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if id == "aider":
					M.talk(parent, "Tiens la ficelle, si tu veux… Et le ventilateur, juste un petit tour. Il adore danser la nuit, comme nous.", I._bye("Promis, tout doux."), I._close(M), "à voix basse")
				else:
					M.close_talk()
			, "à voix basse")
			return
		M.talk(parent, str(_pick(M, ["Bonjour ! Attention à la queue : on l'a posée à travers tout le salon. Onze mètres de rubans, cousus main.",
			"Bon vent ! Tu tombes bien : il nous faut un témoin. Ce cerf-volant sera le plus grand de la Fête des Vents."])),
			[{"id": "fete", "label": "C'est quoi, la Fête des Vents ?"}, {"id": "sortir", "label": "Comment va-t-il sortir ?"}, {"id": "fermer", "label": "Bon vent !"}], func(id):
			match id:
				"fete":
					M.talk(parent, "Une fois par an, toute la Cité monte au Parc des Brumes avec un cerf-volant. Le plus grand gagne une médaille, le plus beau aussi, le plus drôle aussi. Lili Altaïr les gagne presque toutes.", I._bye("Pas cette année !"), I._close(M), "enthousiaste")
				"sortir":
					M.talk(parent, "Par la baie ! On a mesuré : il passe. En biais. En retenant notre souffle. Et sans la queue, qu'on remettra dehors.", I._bye("Ha ha ! Bonne chance !"), I._close(M), "enthousiaste")
				_:
					M.close_talk()
		, "enthousiaste")
	M.talk_spot(parent, parent_cb)
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Un enfant dort sur le tapis, à côté d'un cerf-volant géant. Quelqu'un noue les derniers rubans à la lueur d'une lampe.",
			"La maison dort à moitié. Un cerf-volant immense attend sur le tapis, sa queue de rubans en travers du salon. Un enfant ronfle tout près.",
			"Il est tard. Des rubans partout, un ventilateur endormi dans son coin, et un cerf-volant géant qui attend la Fête des Vents."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Un immense cerf-volant est couché au milieu du salon, et sa queue de rubans traverse toute la pièce. Dans un coin, un gros ventilateur attend son heure.",
			"Des rubans partout, des ciseaux, des plans… Une famille fabrique un cerf-volant géant pour la Fête des Vents.",
			"« Ne marche pas sur la queue ! » Trop tard. Un cerf-volant géant dort sur le tapis, prêt pour la Fête des Vents."]))


# =================================================================== l'appartement-jardin

## L'appartement d'un(e) botaniste, ami(e) de Flora Verdine : un mur végétal, des pots suspendus, des
## fraisiers géants en bacs ; Plic, un petit drone d'arrosage (un disque blanc et ses quatre hélices),
## fait sa tournée en boucle et arrose tout… y compris le visiteur (« Pschhh ! ») et l'enfant qui lit
## dans son fauteuil. On peut cueillir une fraise géante (la première fois : deux fraises), arrêter
## le drone (il se pose sur son socle… puis repart), toucher le mur végétal. La nuit, l'enfant dort
## dans le fauteuil et Plic fait sa tournée de nuit, sa lumière bleue sous le ventre.
static func _jardin(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var nuit: bool = _nuit(M)
	var s: float = 1.0 if r.randf() < 0.5 else -1.0
	var boy: bool = r.randf() < 0.5
	var sol: float = R.P(0, 0, 0).y
	var o: Vector3 = R.P(0, 0, 0)
	# le mur végétal, contre le mur du fond (pas devant la baie du fond)
	var pw: float = minf(2.4, R.W * 0.4)
	var ph: float = 1.9
	var mx: float = R.W * 0.18 if R.W > 7.5 else (1.0 if r.randf() < 0.5 else -1.0) * R.W * 0.15
	var mzw: float = -hd + 0.02
	R.mark_wall(mx, 1.5, mzw, pw * 0.5 + 0.1)
	R.reserve(mx, -hd + 0.3, pw, 0.5)
	R.kit.box(R.L(mx, 0.55 + ph * 0.5, -hd + 0.035), Vector3(pw, ph, 0.03), "nu_vert_sombre", 1.0)
	for sx in [-1.0, 1.0]:
		R.kit.box(R.L(mx + sx * (pw * 0.5 + 0.025), 0.55 + ph * 0.5, -hd + 0.045), Vector3(0.05, ph + 0.1, 0.05), "bois_clair", 1.0)
		R.kit.box(R.L(mx, 0.55 + ph * 0.5 + sx * (ph * 0.5 + 0.025), -hd + 0.045), Vector3(pw + 0.1, 0.05, 0.05), "bois_clair", 1.0)
	var nc: int = int(pw / 0.16)
	var nr: int = int(ph / 0.16)
	for i in range(nc):
		for j in range(nr):
			var lx: float = mx - pw * 0.5 + (i + 0.5) * pw / nc + r.randf_range(-0.03, 0.03)
			var ly: float = 0.55 + (j + 0.5) * ph / nr + r.randf_range(-0.03, 0.03)
			for k in range(2):
				var tf: Transform3D = R.L(lx, ly, -hd + 0.08) * Transform3D(Basis(Vector3.BACK, r.randf() * TAU) * Basis(Vector3.RIGHT, r.randf_range(-0.5, 0.5)), Vector3.ZERO)
				R.kit.box(tf, Vector3(r.randf_range(0.1, 0.16), 0.08, 0.06), ["nu_vert", "nu_vert_clair", "feuillage"][(i + j + k) % 3], 1.0)
			if r.randf() < 0.12:
				R.kit.box(R.L(lx, ly + 0.04, -hd + 0.13, r.randf() * 90.0), Vector3(0.05, 0.05, 0.05), str(_pick(M, ["nu_rose", "nu_jaune", "nu_lavande", "nu_blanc"])), 1.0)
	# la cheminée à l'éthanol, de l'autre côté du mur du fond, s'il y a la place
	var fxx: float = mx - signf(mx) * (pw * 0.5 + 1.15)
	if R.W <= 7.5 and absf(fxx) < hw - 0.95:
		_foyer(M, fxx)
	# les fraisiers géants : deux ou trois bacs de bois blond contre le mur d'un côté
	var nb: int = clampi(int((R.D - 2.3) / 1.15), 2, 3)
	var bx: float = -s * (hw - 0.55)
	var bacs: Array = []
	var fraises: Array = []
	var rouge := _mat(Color(0.88, 0.12, 0.15), 0.0, 0.3)
	var vert_m := _mat(Color(0.25, 0.55, 0.22), 0.0, 0.7)
	for b2 in range(nb):
		var bz: float = -hd + 1.1 + b2 * 1.15
		bacs.append(bz)
		R.kit.box(R.L(bx, 0.27, bz), Vector3(0.45, 0.54, 1.0), "bois_clair", 1.0)
		R.kit.box(R.L(bx, 0.545, bz), Vector3(0.41, 0.01, 0.96), "terreau", 1.0)
		for k2 in range(7):
			var fz: float = bz - 0.4 + k2 * 0.13
			var lf: Transform3D = R.L(bx + r.randf_range(-0.1, 0.1), 0.55, fz) * Transform3D(Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, r.randf_range(-0.7, 0.7)), Vector3.ZERO)
			R.kit.box(lf * Transform3D(Basis(), Vector3(0, 0.12, 0)), Vector3(0.22, 0.2, 0.02), "nu_vert" if k2 % 2 == 0 else "nu_vert_clair", 1.0)
			if k2 % 3 == 0:
				R.kit.box(R.L(bx + r.randf_range(-0.08, 0.08), 0.78, fz, r.randf() * 90.0), Vector3(0.05, 0.03, 0.05), "nu_blanc", 1.0)
		R.kit.col_box(R.L(bx, 0.27, bz), Vector3(0.45, 0.54, 1.0))
		R.reserve(bx, bz, 0.65, 1.1)
		var lot: Array = []
		for k3 in range(3):
			var fr: Node3D = I._node(M, R.P(bx + s * 0.2, 0.5 + r.randf_range(-0.04, 0.06), bz - 0.3 + k3 * 0.3), r.randf() * 360.0)
			_p(fr, I._sph(0.065), rouge, Vector3.ZERO, Vector3(1.0, 1.25, 1.0))
			_p(fr, I._cyl(0.05, 0.015, 0.02, 8), vert_m, Vector3(0, 0.08, 0))
			lot.append(fr)
		fraises.append(lot)
	# le buffet blanc et le socle du drone, contre le mur d'en face
	var dz: float = clampf(hd - 2.1, -hd + 0.8, hd - 1.7)
	var dxb: float = s * (hw - 0.23)
	R.kit.box(R.L(dxb, 0.34, dz), Vector3(0.42, 0.68, 1.0), "ceramique", 1.0)
	R.kit.box(R.L(dxb, 0.695, dz), Vector3(0.44, 0.03, 1.02), "bois_clair", 1.0)
	R.kit.col_box(R.L(dxb, 0.35, dz), Vector3(0.42, 0.7, 1.0))
	R.reserve(dxb, dz, 0.6, 1.2)
	R.kit.cyl(R.L(dxb, 0.71, dz), 0.19, 0.2, 0.03, "ceramique", 20)
	R.kit.ring(R.L(dxb, 0.71, dz), 0.15, 0.17, 0.035, "nu_bleu", 20)
	var socle: Vector3 = R.P(dxb, 0.86, dz)
	# le fauteuil de l'enfant, face au mur végétal ; une plante à côté
	var kx: float = s * 0.45
	var kz: float = clampf(hd - 2.4, -hd + 1.5, hd - 1.8)
	R.fauteuil(kx, kz, 180, str(_pick(M, ["blanc", "creme", "vert"])))
	if R.is_free(kx + s * 0.75, kz - 0.2, 0.45, 0.45):
		_pot(M, kx + s * 0.75, kz - 0.2, 0.0, 1.0, "nu_rose")
	# les pots suspendus (des coins vers le milieu, loin du plafonnier)
	var pots: Array = []
	for c in [[-hw + 0.9, -hd + 1.4], [hw - 0.9, -hd + 1.4], [-hw + 1.0, hd - 2.2], [hw - 1.0, hd - 2.2]]:
		var hx: float = float(c[0])
		var hz: float = float(c[1])
		if Vector2(hx, hz).length() < 1.0:
			continue
		pots.append(R.P(hx, 2.45, hz))
		R.kit.cyl(R.L(hx, 2.3, hz), 0.006, 0.006, R.H - 2.3, "argent", 4, false)
		R.kit.cyl(R.L(hx, 2.1, hz), 0.1, 0.16, 0.2, "ceramique", 14)
		R.kit.cyl(R.L(hx, 2.29, hz), 0.15, 0.15, 0.01, "terreau", 14)
		for k4 in range(6):
			var a4: float = TAU * k4 / 6.0 + r.randf()
			var ll: float = r.randf_range(0.2, 0.4)
			R.kit.box(R.L(hx + cos(a4) * 0.15, 2.3 - ll * 0.5, hz + sin(a4) * 0.15, rad_to_deg(-a4)), Vector3(0.03, ll, 0.06), "nu_vert" if k4 % 2 == 0 else "nu_vert_clair", 1.0)
	_cadres(M, 1, 1)
	# les gens : le (la) botaniste près des fraisiers, l'enfant qui lit dans le fauteuil
	var mid: float = float(bacs[int(bacs.size() * 0.5)])
	var gx: float = -s * (hw - 1.45)
	var gz: float = clampf(mid + 0.55, -hd + 0.5, hd - 1.6)
	var role_b: String = str(_pick(M, ["homme", "femme", "vieux", "vieille"]))
	var fem: bool = role_b == "femme" or role_b == "vieille"
	var bot: Node = M.person(role_b, gx, gz, _vers(gx, gz, bx, mid), "jardiner")
	var kid: Node = M.person("garcon" if boy else "fille", kx, kz, 180, "dormir_assis" if nuit else "lire")
	if nuit:
		bot.lines = ["Chut… les fraises poussent.", "Tout doux, Plic. Mode nuit.", "Elles boivent mieux la nuit."]
		bot.line_every = Vector2(10.0, 15.0)
		kid.lines = ["Zzz…", "Zzz… Plic… pas sur ma tête… zzz…"]
		kid.line_every = Vector2(10.0, 15.0)
	else:
		bot.lines = ["Bonjour, les fraisiers ! Bien dormi ?", "Plic, n'oublie pas la fougère du coin !", "Celle-là pèse un demi-kilo !", "Il faudra leur parler de la Fête des Vents."]
		kid.lines = ["Plic ! Je LIS !", "Il m'a encore arrosé le livre…", "Les fraises, c'est pour le goûter ?", "Je crois que la fougère m'a regardé." if boy else "Je crois que la fougère m'a regardée."]
		kid.line_every = Vector2(7.0, 11.0)
	# Plic, le drone : son disque blanc, son réservoir bleu, sa lumière, ses quatre hélices
	var blanc := _mat(Color(0.97, 0.97, 0.96), 0.0, 0.3)
	var alu := _mat(Color(0.85, 0.86, 0.88), 0.9, 0.3)
	var led_m := _mat(Color(0.35, 0.7, 1.0), 0.0, 0.3, 2.5)
	var helice_m := _verre(Color(0.9, 0.92, 0.95), 0.55)
	var dr: Node3D = I._node(M, socle, 0)
	var caisse := Node3D.new()
	dr.add_child(caisse)
	_p(caisse, I._cyl(0.15, 0.15, 0.05, 24), blanc, Vector3.ZERO)
	_p(caisse, I._sph(0.1), blanc, Vector3(0, 0.03, 0), Vector3(1.0, 0.45, 1.0))
	_p(caisse, I._cyl(0.06, 0.05, 0.08, 14), _verre(Color(0.4, 0.65, 1.0), 0.6), Vector3(0, -0.06, 0))
	_p(caisse, I._cyl(0.008, 0.004, 0.06, 6), alu, Vector3(0, -0.12, 0))
	_p(caisse, I._sph(0.018), led_m, Vector3(0, -0.02, 0.15))
	var rotors: Array = []
	for k5 in range(4):
		var a5: float = PI * 0.25 + k5 * PI * 0.5
		var bras: Vector3 = Vector3(cos(a5), 0, sin(a5)) * 0.2
		_p(caisse, I._boxm(Vector3(0.2, 0.015, 0.02)), blanc, bras * 0.5, Vector3.ONE, Vector3(0, -a5, 0))
		_p(caisse, I._cyl(0.025, 0.025, 0.03, 10), alu, bras + Vector3(0, 0.005, 0))
		var rot := Node3D.new()
		caisse.add_child(rot)
		rot.position = bras + Vector3(0, 0.03, 0)
		_p(rot, I._boxm(Vector3(0.16, 0.004, 0.02)), helice_m, Vector3.ZERO)
		_p(rot, I._boxm(Vector3(0.02, 0.004, 0.16)), helice_m, Vector3.ZERO)
		rotors.append(rot)
	_sans_ombre(dr)
	var jet: CPUParticles3D = _gouttes(M, 30)
	jet.emission_box_extents = Vector3(0.02, 0.01, 0.02)
	jet.spread = 16.0
	# sa tournée : au-dessus des bacs, devant le mur végétal, au-dessus des pots, du fauteuil
	var wps: Array = []
	for bz2 in bacs:
		wps.append([R.P(bx + s * 0.05, 1.3, float(bz2)), "bac"])
	wps.append([R.P(mx - pw * 0.25, 1.75, -hd + 0.7), "mur"])
	wps.append([R.P(mx + pw * 0.25, 1.5, -hd + 0.7), "mur"])
	for pt in pots:
		wps.append([pt, "pot"])
	wps.append([R.P(kx, 1.75, kz), "enfant"])
	wps.sort_custom(func(a, b): return atan2((a[0] as Vector3).z - o.z, (a[0] as Vector3).x - o.x) < atan2((b[0] as Vector3).z - o.z, (b[0] as Vector3).x - o.x))
	var st := {"t": 0.0, "mode": "pose" if nuit else "route", "i": 0, "d": 3.0, "pos": socle, "prev": socle, "toi": 12.0, "phase": "", "cueilli": 0}
	var vitesse: float = 0.45 if nuit else 0.7
	var arroser := func(at: Vector3, d: float) -> void:
		jet.global_position = at + Vector3(0, -0.13, 0)
		jet.emitting = true
		st["d"] = d
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(dr):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var mode: String = str(st["mode"])
		var p: Vector3 = st["pos"]
		var pp: Vector3 = M.main._player_pos_v27()
		st["toi"] = maxf(0.0, float(st["toi"]) - dt)
		match mode:
			"route":
				var w: Array = wps[int(st["i"]) % wps.size()]
				var cible: Vector3 = w[0]
				p = p.move_toward(cible, dt * vitesse)
				if p.distance_to(cible) < 0.02:
					st["mode"] = "pause"
					arroser.call(p, 2.4 if nuit else 1.6)
					if str(w[1]) == "enfant" and not nuit:
						kid.say(str(_pick(M, ["Plic ! Je LIS !", "Pas sur le livre, Plic !", "Pschhh… merci, Plic. J'avais justement soif."])), 3.0)
					elif str(w[1]) == "bac":
						M.main.sfx("verser", p, -4.0)
				elif float(st["toi"]) <= 0.0 and Vector2(pp.x - p.x, pp.z - p.z).length() < 1.6:
					st["mode"] = "toi"
					st["phase"] = "va"
					st["d"] = 3.0
			"pause":
				st["d"] = float(st["d"]) - dt
				if float(st["d"]) <= 0.0:
					jet.emitting = false
					st["i"] = (int(st["i"]) + 1) % wps.size()
					st["mode"] = "route"
			"toi":
				var lp: Vector3 = pp - o
				var au_dessus: Vector3 = o + Vector3(clampf(lp.x, -hw + 0.4, hw - 0.4), 2.15, clampf(lp.z, -hd + 0.4, hd - 0.4))
				if str(st["phase"]) == "va":
					p = p.move_toward(au_dessus, dt * 1.2)
					st["d"] = float(st["d"]) - dt
					if p.distance_to(au_dessus) < 0.05 or float(st["d"]) <= 0.0:
						st["phase"] = "arrose"
						arroser.call(p, 1.3)
						M.main.sfx("verser", pp + Vector3(0, 1.7, 0))
						_bulle(M, pp + Vector3(0, 1.95, 0), "Pschhh… !" if nuit else "Pschhh !", Color(0.75, 0.9, 1.0), 48, 0.4, 1.5)
						M.say(str(_pick(M, ["Pschhh ! Le drone t'arrose consciencieusement, de la tête aux épaules. Tu pousses mieux, maintenant ?",
							"Pschhh ! Une petite pluie fraîche sur ta tête. Plic fait un bip satisfait : encore une plante d'arrosée.",
							"Pschhh ! Plic t'a pris pour un ficus. Un ficus très surpris."])), 4.0)
						bot.gesture("rire", 2.0)
						S._say_late(M, bot, "Chut… Il te prend pour une plante. C'est un compliment." if nuit else str(_pick(M, ["Ha ha ! Il te prend pour une plante ! C'est un compliment.", "Plic ! On n'arrose pas les invités ! … Enfin, pas tous les jours.", "Ne bouge pas, il a presque fini."])), 1.2)
				else:
					p = p.move_toward(au_dessus, dt * 0.6)
					st["d"] = float(st["d"]) - dt
					if float(st["d"]) <= 0.0:
						jet.emitting = false
						st["toi"] = 25.0
						st["mode"] = "route"
			"retour":
				var dock: Vector3 = socle + Vector3(0, 0.12, 0)
				p = p.move_toward(dock, dt * 0.9)
				if p.distance_to(dock) < 0.02:
					st["mode"] = "pose"
					st["d"] = 12.0 if nuit else 9.0
					led_m.albedo_color = Color(1.0, 0.6, 0.2)
					led_m.emission = Color(1.0, 0.6, 0.2)
					M.main.sfx("ui_clic", dock)
			"pose":
				p = p.move_toward(socle, dt * 0.3)
				st["d"] = float(st["d"]) - dt
				if float(st["d"]) <= 0.0:
					st["mode"] = "route"
					led_m.albedo_color = Color(0.35, 0.7, 1.0)
					led_m.emission = Color(0.35, 0.7, 1.0)
					_bulle(M, p + Vector3(0, 0.3, 0), "Bip-bip !", Color(0.7, 0.9, 1.0), 38, 0.4, 1.4)
					M.main.sfx("robot_bip", p)
		var vole: bool = str(st["mode"]) != "pose"
		var bob: float = 0.02 * sin(t * 3.0) if vole else 0.0
		dr.global_position = p + Vector3(0, bob, 0)
		jet.global_position = p + Vector3(0, -0.13, 0)
		var prev: Vector3 = st["prev"]
		var vel: Vector3 = (p - prev) / maxf(dt, 0.001)
		st["prev"] = p
		st["pos"] = p
		caisse.rotation.x = lerpf(caisse.rotation.x, clampf(vel.z * 0.35, -0.3, 0.3), clampf(dt * 4.0, 0.0, 1.0))
		caisse.rotation.z = lerpf(caisse.rotation.z, clampf(-vel.x * 0.35, -0.3, 0.3), clampf(dt * 4.0, 0.0, 1.0))
		var spin: float = (30.0 if nuit else 42.0) if vole else 3.0
		for ro in rotors:
			(ro as Node3D).rotation.y += dt * spin
	# ce qu'on fait : cueillir une fraise (un endroit par bac), arrêter le drone, toucher le mur végétal
	for b3 in range(bacs.size()):
		var lot2: Array = fraises[b3]
		M.act(R.P(-s * (hw - 1.25), 0, float(bacs[b3])), "E : cueillir une fraise géante", func() -> void:
			var fr2: Node3D = null
			for f in lot2:
				if (f as Node3D).scale.x > 0.9:
					fr2 = f
					break
			if fr2 == null:
				M.say("Plus une fraise mûre dans ce bac. Elles repoussent : il faut juste un peu de patience, et beaucoup de soleil.", 4.0)
				return
			var tw: Tween = M.room.create_tween()
			tw.tween_property(fr2, "scale", Vector3.ONE * 1.25, 0.12)
			tw.tween_property(fr2, "scale", Vector3.ONE * 0.01, 0.2)
			tw.tween_interval(14.0)
			tw.tween_property(fr2, "scale", Vector3.ONE, 3.0).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			_bulle(M, fr2.global_position + Vector3(0, 0.25, 0), "Pop !", Color(1.0, 0.75, 0.75), 40, 0.4, 1.2)
			if not bool(M.state().get("nu_jardin", false)):
				M.state()["nu_jardin"] = true
				var txt: String = "Chut… Oui, prends-en deux. Les fraises cueillies la nuit sont les plus sucrées : elles ont rêvé de soleil." if nuit else "Une fraise de Flora ! Prends-en deux, va : elles sont grosses comme le poing, et sucrées comme… comme des fraises géantes. Je n'ai pas mieux."
				M.talk(bot, txt, I._bye("Merci !"), func(_i):
					M.give([["fraise_geante", 2]], "")
					M.close_talk(), "à voix basse" if nuit else "aux anges")
				return
			st["cueilli"] = int(st["cueilli"]) + 1
			M.say(str(_pick(M, ["Tu la soupèses : lourde comme un melon. Tu la reposes délicatement au bord du bac. Elle repoussera sur sa tige, paraît-il.",
				"Elle sent si bon que tu fermes les yeux. Quand tu les rouvres, la botaniste te regarde. Tu reposes la fraise." if fem else "Elle sent si bon que tu fermes les yeux. Quand tu les rouvres, le botaniste te regarde. Tu reposes la fraise."])), 4.0)
			S._say_late(M, bot, str(_pick(M, ["Doucement ! Celles-là sont promises à la Fête des Vents.", "Elle repousse déjà, regarde ! C'est le soleil d'ici.", "Une par visite, petit gourmand !"])), 1.0)
		, 1.1)
	M.act(R.P(s * (hw - 0.95), 0, dz), "E : arrêter le drone d'arrosage", func() -> void:
		M.main.sfx("ui_clic", socle)
		jet.emitting = false
		st["mode"] = "retour"
		bot.say("Il va bouder, mais il repartira tout seul. Il a le sens du devoir." if not nuit else "Chut… Il repartira tout seul, tout doucement.", 3.5)
	, 1.2, func(): return str(st["mode"]) != "retour" and str(st["mode"]) != "pose")
	M.act(R.P(mx, 0, -hd + 0.9), "E : toucher le mur végétal", func() -> void:
		M.main.sfx("pas_herbe", R.P(mx, 1.2, -hd + 0.2))
		M.say(str(_pick(M, ["C'est doux et frais. Ça sent la menthe, le basilic et… la fraise ? Une tige de fraisier s'est glissée dans le mur. Personne ne sait comment.",
			"Des centaines de petites plantes, serrées comme dans un nid. Une coccinelle te regarde, puis retourne à ses affaires.",
			"Le mur est humide : Plic est passé par là. Une fougère frémit sous ta main, comme un chat qu'on caresse."])), 5.0)
	, 1.2)
	var bot_cb := func() -> void:
		if nuit:
			M.talk(bot, "Chut… La nuit, les fraises poussent. Si on tend l'oreille, on les entend presque. Plic fait sa tournée de nuit, sans un bruit. Enfin, presque.",
				[{"id": "entendre", "label": "On les entend vraiment ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if id == "entendre":
					M.talk(bot, "Écoute… Ce petit « plop », là ? Non ? Moi non plus. Mais j'y crois très fort, et elles le savent.", I._bye("Bonne nuit, les fraises."), I._close(M), "à voix basse")
				else:
					M.close_talk()
			, "à voix basse")
			return
		M.talk(bot, str(_pick(M, ["Bonjour ! Attention au drone : il arrose tout ce qui ne bouge pas assez vite. Il s'appelle Plic.",
			"Bon vent ! Entre, entre, mais ne reste pas immobile trop longtemps : Plic pourrait te prendre pour une plante."])),
			[{"id": "fraise", "label": "Je peux cueillir une fraise ?"}, {"id": "flora", "label": "Vous connaissez Flora Verdine ?"}, {"id": "fermer", "label": "Bon vent !"}], func(id):
			match id:
				"fraise":
					M.talk(bot, "Cueille donc ! Les bacs sont là, contre le mur. Choisis une bien rouge : les blanches boudent encore.", I._bye("Merci !"), I._close(M), "aux anges")
				"flora":
					M.talk(bot, "Flora ? C'est elle qui m'a donné mes premiers fraisiers ! Et Plic est le petit frère de Ploc, le drone des Serres d'Altitude. Ils s'écrivent. Enfin, ils se bipent.", I._bye("Ha ha ! Bip !"), I._close(M), "aux anges")
				_:
					M.close_talk()
		, "aux anges")
	M.talk_spot(bot, bot_cb)
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Les plantes dorment, le mur végétal respire. Seul un petit drone veille sur son socle, une lumière au ventre.",
			"Il fait nuit dans la jungle de l'appartement. Un enfant dort dans un fauteuil, entre les fraisiers géants.",
			"Tout est calme. On entend juste l'eau qui goutte des pots suspendus, et un petit bip, de temps en temps."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Un appartement-jungle ! Un mur entier de plantes, des pots qui pendent du plafond, des fraisiers géants… et un petit drone blanc qui arrose tout.",
			"Ça sent la terre mouillée et la fraise. Un petit drone passe en bourdonnant : « Pschhh ! » Une fougère le remercie.",
			"Ici, les plantes ont plus de place que les meubles. Entre elles, un drone d'arrosage fait sa tournée, très sérieux."]))


# =================================================================== le planeur dans le salon

## Le manuel de montage, posé sur le tabouret (une page par maison).
const MANUEL := [
	"MANUEL DE MONTAGE. Étape douze : fixer l'aile gauche. Étape treize : fixer l'aile droite. Étape quatorze : sortir le planeur de la maison. À côté, au crayon : « Étape quatorze : à revoir. »",
	"MANUEL DE MONTAGE, page une : « Choisissez un lieu de montage spacieux, de préférence en plein air. » Quelqu'un a entouré « de préférence » trois fois.",
	"MANUEL DE MONTAGE. Au dos, un conseil d'Icare Plané : « Parlez gentiment à votre planeur. Et ne le montez jamais dans un salon. » La deuxième phrase est soulignée en rouge.",
]


## Une famille de vol à voile (des amis d'Icare Plané) assemble un planeur blanc dans le salon : le nez
## vers la porte, le cockpit et son siège, de longues ailes qui traversent la pièce d'un mur à l'autre,
## posées sur des tréteaux. Le père (ou la mère) mesure la porte : « il ne passera jamais… on démontera
## les ailes. Ou le mur. » ; l'enfant est dans le cockpit et fait « vrrrr » (les ailes tremblent). On
## peut s'asseoir dans le cockpit (un petit vol en bulles : la verrière se ferme, « On décolle ! », les
## ailes vibrent ; la première fois, une plume du vent), mesurer la porte, lire le manuel de montage.
## La nuit, l'enfant s'est endormi dans le cockpit, les mains sur le manche.
static func _planeur(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var room0: Node = M.room
	var nuit: bool = _nuit(M)
	var boy: bool = r.randf() < 0.5
	var dside: float = -1.0 if R.door_x > 0.0 else 1.0
	# les mesures du planeur (le nez vers la porte, la queue vers le mur du fond)
	var yc: float = 0.62
	var zn: float = hd - 2.2
	var zt: float = maxf(-hd + 0.4, zn - 5.5)
	var lf: float = zn - zt
	var zc: float = zn - 0.2 * lf - 0.1
	var zw: float = zn - 0.4 * lf - 0.35
	var demi: float = hw - 0.15
	var envergure: int = roundi(demi * 2.0)
	var pl: Node3D = I._node(M, R.P(0, yc, zw), 0)
	var base_w: Vector3 = pl.global_position
	var blanc := _mat(Color(0.97, 0.97, 0.96), 0.0, 0.25)
	var bleu := _mat(Color(0.45, 0.68, 0.92), 0.0, 0.4)
	var noir := _mat(Color(0.08, 0.08, 0.09), 0.0, 0.6)
	var gris := _mat(Color(0.3, 0.32, 0.35), 0.0, 0.7)
	var vitre := _verre(Color(0.7, 0.85, 1.0), 0.3)
	# le fuselage : le nez (un long œuf blanc), la poutre de queue, la dérive, le stabilisateur, la roue
	_p(pl, I._sph(1.0), blanc, Vector3(0, 0, zn - 0.33 * lf - zw), Vector3(0.33, 0.36, 0.33 * lf))
	var b0: float = zn - 0.6 * lf
	var b1: float = zt + 0.1
	_p(pl, I._cyl(0.07, 0.22, b0 - b1, 16), blanc, Vector3(0, 0.04, (b0 + b1) * 0.5 - zw), Vector3.ONE, Vector3(-PI * 0.5, 0, 0))
	_p(pl, I._boxm(Vector3(0.04, 0.75, 0.45)), blanc, Vector3(0, 0.45, zt + 0.3 - zw), Vector3.ONE, Vector3(-0.25, 0, 0))
	_p(pl, I._boxm(Vector3(0.045, 0.2, 0.3)), bleu, Vector3(0, 0.62, zt + 0.25 - zw), Vector3.ONE, Vector3(-0.25, 0, 0))
	_p(pl, I._boxm(Vector3(1.6, 0.03, 0.32)), blanc, Vector3(0, 0.8, zt + 0.2 - zw))
	_p(pl, I._cyl(0.12, 0.12, 0.08, 16), noir, Vector3(0, 0.12 - yc, zc - 0.25 - zw), Vector3.ONE, Vector3(0, 0, PI * 0.5))
	_p(pl, I._boxm(Vector3(0.3, 0.06, 0.3)), gris, Vector3(0, -0.15, zc - 0.1 - zw))
	_p(pl, I._boxm(Vector3(0.32, 0.4, 0.06)), gris, Vector3(0, 0.05, zc - 0.32 - zw), Vector3.ONE, Vector3(-0.2, 0, 0))
	_p(pl, I._cyl(0.012, 0.012, 0.3, 6), noir, Vector3(0, -0.05, zc + 0.15 - zw), Vector3.ONE, Vector3(0.4, 0, 0))
	# la verrière (ouverte : relevée vers l'arrière)
	var verriere := Node3D.new()
	pl.add_child(verriere)
	verriere.position = Vector3(0, 0.3, zc - 0.35 - zw)
	_p(verriere, I._sph(1.0), vitre, Vector3(0, 0.02, 0.32), Vector3(0.25, 0.2, 0.42))
	verriere.rotation.x = -0.95
	# les ailes (deux moitiés, qui peuvent trembler), une bande bleue et un petit saumon au bout
	var ailes: Array = []
	for sx in [-1.0, 1.0]:
		var piv := Node3D.new()
		pl.add_child(piv)
		piv.position = Vector3(0, 0.26, 0)
		var x0: float = 0.12
		var x1: float = 0.58 * demi
		_p(piv, I._boxm(Vector3(x1 - x0, 0.05, 0.56)), blanc, Vector3(sx * (x0 + x1) * 0.5, 0, 0))
		_p(piv, I._boxm(Vector3(demi - x1, 0.04, 0.4)), blanc, Vector3(sx * (x1 + demi) * 0.5, 0, 0.08))
		_p(piv, I._boxm(Vector3(0.3, 0.045, 0.41)), bleu, Vector3(sx * (demi - 0.45), 0, 0.08))
		_p(piv, I._boxm(Vector3(0.02, 0.14, 0.26)), blanc, Vector3(sx * demi, 0.06, 0.12))
		piv.rotation.z = sx * 0.04
		ailes.append([piv, sx])
	# les tréteaux sous les ailes, le berceau sous la queue
	for sx2 in [-1.0, 1.0]:
		var tx: float = sx2 * (hw - 0.75)
		for sz in [-1.0, 1.0]:
			R.kit.box(R.L(tx, 0.4, zw + sz * 0.22) * Transform3D(Basis(Vector3.RIGHT, sz * 0.25), Vector3.ZERO), Vector3(0.05, 0.84, 0.05), "bois_clair", 1.0)
		R.kit.box(R.L(tx, 0.82, zw), Vector3(0.3, 0.04, 0.12), "bois_clair", 1.0)
		R.reserve(tx, zw, 0.5, 0.7)
	R.kit.box(R.L(0, (yc - 0.12) * 0.5, zt + 0.9), Vector3(0.3, yc - 0.12, 0.25), "bois_clair", 1.0)
	R.kit.col_box(R.L(0, yc, zn - 0.33 * lf), Vector3(0.62, 0.72, 0.62 * lf))
	R.kit.col_box(R.L(0, yc, (b0 + zt) * 0.5), Vector3(0.3, 0.4, maxf(0.2, b0 - zt)))
	R.reserve(0, (zn + zt) * 0.5, 0.8, lf + 0.2)
	R.tapis(0, zc + 0.2, 0, minf(2.4, R.W - 2.4), 1.4, 1)
	_cadres(M, 2, 2)
	# le tabouret du manuel de montage, près du bout d'une aile
	var mx: float = -dside * (hw - 0.65)
	var mz: float = clampf(zw + 1.25, -hd + 0.5, hd - 1.6)
	R.tabouret(mx, mz)
	R.reserve(mx, mz, 0.45, 0.45)
	S._mot(M, mx, mz, 0.44, str(MANUEL[r.randi() % MANUEL.size()]), "E : lire le manuel de montage")
	# le mètre ruban (il se déroule le long de la porte quand on mesure)
	var ruban: Node3D = I._node(M, R.P(R.door_x - 0.55, 1.0, hd - 0.12), 0)
	_p(ruban, I._boxm(Vector3(1.0, 0.025, 0.004)), _mat(Color(1.0, 0.85, 0.2), 0.0, 0.5), Vector3(0.5, 0, 0))
	ruban.scale.x = 0.01
	ruban.visible = false
	# les gens : l'enfant dans le cockpit, le père (ou la mère) qui mesure la porte, l'aide au bout de l'aile
	var kid: Node = M.person("garcon" if boy else "fille", 0.0, zc, 0, "dormir_assis" if nuit else "assis")
	kid.npc.global_position += Vector3.UP * 0.3          # assis dans le cockpit (les jambes dans le fuselage)
	var fp: Vector2 = _dedans(M, R.door_x + dside * 1.0, hd - 1.6)
	var porte: Vector3 = R.P(R.door_x, 1.0, hd - 0.1)
	var pere: Node = M.person(str(_pick(M, ["homme", "femme"])), fp.x, fp.y, _vers(fp.x, fp.y, R.door_x, hd), "mains_dos" if nuit else "bras_croises")
	var ap: Vector2 = _dedans(M, -dside * (hw - 1.0), zw + 0.6)
	var aide: Node = M.person(str(_pick(M, ["homme", "femme", "vieux", "vieille"])), ap.x, ap.y, 180, "bricoler")
	if nuit:
		kid.lines = ["Zzz… vrrr… zzz…", "Zzz… on décolle… zzz…", "Mmh… virage à gauche… zzz…"]
		kid.line_every = Vector2(9.0, 14.0)
		pere.lines = ["Chut… le petit pilote dort.", "Demain, on mesure encore. Tout doux.", "Il ne passera jamais… mais chut."]
		pere.line_every = Vector2(10.0, 15.0)
		aide.lines = ["Chut…", "Je serre le dernier boulon. Sans bruit."]
	else:
		pere.lines = ["Un mètre dix… Un mètre DIX.", "Il ne passera jamais…", "On démontera les ailes. Ou le mur.", "Qui a eu l'idée de le monter ici ?"]
		aide.lines = ["Encore un boulon…", "Aile gauche fixée ! Aile droite… presque.", "Icare dit qu'il faut lui parler gentiment.", "C'est moi qui ai eu l'idée. Ne le répète pas."]
	aide.line_every = Vector2(8.0, 13.0)
	var cockpit_w: Vector3 = R.P(0, 0.95, zc)
	var tour: Vector3 = R.P(dside * 0.95, 0, clampf(zc + 0.6, -hd + 0.5, hd - 1.6))
	var siege: Vector3 = kid.npc.global_position
	var st := {"t": 0.0, "vol": false, "envol": 0.0, "lev": 0.0, "secoue": 0.0, "vrr": 4.0, "mesure": false}
	# ce qui bouge : les ailes qui tremblent (quand l'enfant fait « vrrrr », et pendant le vol), le planeur qui se soulève
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(pl):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var lev: float = move_toward(float(st["lev"]), float(st["envol"]), dt * 0.8)
		st["lev"] = lev
		var sh: float = maxf(0.0, float(st["secoue"]) - dt * 0.35)
		sh = maxf(sh, 0.6 * lev)
		st["secoue"] = sh
		var flex: float = 0.05 * sh * sin(t * 11.0) + 0.07 * lev * sin(t * 2.2)
		for e in ailes:
			(e[0] as Node3D).rotation.z = float(e[1]) * (0.04 + flex)
		pl.global_position = base_w + Vector3(0, 0.07 * lev + 0.006 * sh * sin(t * 17.0), 0)
		pl.rotation.z = 0.05 * lev * sin(t * 1.3) + 0.012 * sh * sin(t * 13.0)
		pl.rotation.x = -0.03 * lev
		if not bool(st["vol"]) and not nuit:
			st["vrr"] = float(st["vrr"]) - dt
			if float(st["vrr"]) <= 0.0:
				st["vrr"] = 7.0 + randf() * 5.0
				st["secoue"] = 0.4
				kid.say(str(_pick(M, ["Vrrrrrr !", "Vrrrr… virage à gauche !", "Attention, je décolle ! Vrrrr !", "Tour de contrôle, ici le pilote ! Vrrr !" if boy else "Tour de contrôle, ici la pilote ! Vrrr !"])), 2.5)
	# s'asseoir dans le cockpit : un petit vol en bulles
	var bulle_vol := func(txt: String, big: bool) -> void:
		_bulle(M, cockpit_w + Vector3(0, 0.75, 0), txt, Color(0.85, 0.95, 1.0) if not big else Color(1.0, 0.92, 0.55), 48 if big else 38, 0.5, 2.2)
	var voler := func() -> void:
		if bool(st["vol"]):
			return
		if nuit:
			M.say(str(_pick(M, ["Le cockpit est occupé : un petit pilote y dort, la tête sur le côté, les mains sur le manche. Il fait « vrrr » en dormant.",
				"Chut… L'enfant s'est endormi aux commandes. Le planeur veille sur lui, ses grandes ailes ouvertes d'un mur à l'autre."])), 5.0)
			return
		st["vol"] = true
		kid.say(str(_pick(M, ["À toi ! Moi, je fais la tour de contrôle !", "Je te prête ma place ! Attache ta ceinture !", "Pilote, à ton poste !"])), 3.0)
		kid.set_pose("marcher", tour - siege)
		var tw: Tween = M.room.create_tween()
		tw.tween_property(kid.npc, "global_position", tour, 1.0)
		tw.tween_callback(func() -> void:
			kid.set_pose("pointer", R.P(0, 0, zc) - tour))
		M.say(str(_pick(M, ["Tu te glisses dans le cockpit. Le siège est un peu petit, mais le manche tombe pile sous ta main.",
			"Tu enjambes le bord du cockpit et tu t'assois. Ça sent le cuir neuf et la colle à bois."])), 4.0)
		await M.get_tree().create_timer(1.8).timeout
		if not _la(M, room0):
			return
		var tw2: Tween = M.room.create_tween()
		tw2.tween_property(verriere, "rotation:x", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
		M.main.sfx("ui_clic", cockpit_w)
		bulle_vol.call("Verrière fermée !", false)
		await M.get_tree().create_timer(1.6).timeout
		if not _la(M, room0):
			return
		bulle_vol.call("Manche… palonnier… sourire !", false)
		await M.get_tree().create_timer(1.8).timeout
		if not _la(M, room0):
			return
		kid.say("Tour de contrôle à pilote : vent de face, force deux ! Décollage autorisé !", 3.0)
		await M.get_tree().create_timer(1.8).timeout
		if not _la(M, room0):
			return
		st["envol"] = 1.0
		st["secoue"] = 1.0
		M.main.sfx("deltaplane_vent", cockpit_w)
		M.main.sfx("bourrasque", cockpit_w)
		bulle_vol.call("On décolle !", true)
		kid.gesture("joie", 2.5)
		pere.gesture("joie", 2.5)
		aide.gesture("applaudir", 2.5)
		await M.get_tree().create_timer(2.0).timeout
		if not _la(M, room0):
			return
		bulle_vol.call(str(_pick(M, ["Ouaaah ! On survole le Parc des Brumes !", "Virage à gauche… au-dessus de la Cascade !", "On frôle un cumulus ! Il est tout doux !"])), false)
		S._say_late(M, pere, str(_pick(M, ["Attention au plafonnier !", "Tu vois la boulangerie d'Icare ?", "Pas trop haut, il y a l'étage du dessus !"])), 1.0)
		await M.get_tree().create_timer(2.2).timeout
		if not _la(M, room0):
			return
		bulle_vol.call("Atterrissage… en douceur !", false)
		st["envol"] = 0.0
		await M.get_tree().create_timer(1.5).timeout
		if not _la(M, room0):
			return
		M.main.sfx("touche_bois", cockpit_w)
		st["secoue"] = 0.5
		var tw3: Tween = M.room.create_tween()
		tw3.tween_property(verriere, "rotation:x", -0.95, 0.8).set_trans(Tween.TRANS_SINE)
		kid.gesture("applaudir", 2.0)
		await M.get_tree().create_timer(1.0).timeout
		if not _la(M, room0):
			return
		if not bool(M.state().get("nu_planeur", false)):
			M.state()["nu_planeur"] = true
			M.talk(pere, "Bienvenue au club de vol à voile ! Chez nous, après le premier vol, on offre une plume du vent. C'est Icare Plané qui nous a appris la coutume : lui, il en a toute une collection.",
				I._bye("Merci ! Quel vol !"), func(_i):
				M.give([["plume_vent", 1]], "")
				M.close_talk(), "enthousiaste")
		else:
			pere.say(str(_pick(M, ["Joli vol ! Toujours pas sorti du salon, mais joli vol.", "Atterrissage parfait. Le tapis n'a rien senti.", "Bravo, pilote ! Prochaine étape : la porte."])), 3.5)
		# l'enfant reprend sa place
		kid.set_pose("marcher", siege - tour)
		var tw4: Tween = M.room.create_tween()
		tw4.tween_property(kid.npc, "global_position", siege, 1.0)
		tw4.tween_callback(func() -> void:
			kid.set_pose("assis", Vector3(0, 0, 1))
			st["vol"] = false)
	# mesurer la porte : le mètre ruban se déroule… le verdict tombe
	var mesurer := func() -> void:
		if bool(st["mesure"]):
			return
		st["mesure"] = true
		ruban.visible = true
		ruban.scale.x = 0.01
		M.main.sfx("ui_clic", porte)
		var tw5: Tween = M.room.create_tween()
		tw5.tween_property(ruban, "scale:x", 1.1, 1.0).set_trans(Tween.TRANS_SINE)
		pere.set_pose("pointer", porte - pere.npc.global_position)
		_bulle(M, porte + Vector3(0, 0.6, 0), "Un mètre dix…", Color(1.0, 0.9, 0.5), 38, 0.4, 1.8)
		await M.get_tree().create_timer(1.6).timeout
		if not _la(M, room0):
			return
		if nuit:
			pere.say("Chut… %d centimètres de porte. Toujours %d mètres d'ailes. Toujours pas." % [110, envergure], 5.0)
		else:
			pere.say(str(_pick(M, ["La porte : %d centimètres. Les ailes : %d mètres. Il ne passera jamais… On démontera les ailes. Ou le mur.",
				"%d centimètres de porte, %d mètres d'ailes. Bon. Quelqu'un a un tournevis ? Ou une très grande scie ?",
				"La porte fait %d centimètres, les ailes %d mètres. J'ai refait le calcul trois fois. Le calcul est têtu."])) % [110, envergure], 5.0)
			S._say_late(M, aide, str(_pick(M, ["Ou on attend que l'île descende.", "On pourrait le sortir par la baie. En biais.", "Je propose de vivre dans le planeur."])), 2.5)
		await M.get_tree().create_timer(2.5).timeout
		if not _la(M, room0):
			return
		var tw6: Tween = M.room.create_tween()
		tw6.tween_property(ruban, "scale:x", 0.01, 0.4)
		tw6.tween_callback(func() -> void:
			ruban.visible = false
			st["mesure"] = false)
		pere.set_pose("mains_dos" if nuit else "bras_croises", porte - pere.npc.global_position)
	M.act(R.P(-dside * 0.8, 0, zc + 0.1), "E : s'asseoir dans le cockpit", func(): voler.call(), 1.1, func(): return not bool(st["vol"]))
	M.act(R.P(R.door_x + dside * 0.6, 0, hd - 1.75), "E : mesurer la porte", func(): mesurer.call(), 1.0, func(): return not bool(st["mesure"]))
	var pere_cb := func() -> void:
		if nuit:
			M.talk(pere, "Chut… Le petit s'est endormi dans le cockpit. Il pilote en rêve : écoute, il fait « vrrr » tout bas.",
				[{"id": "reve", "label": "Il rêve de quoi ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if id == "reve":
					M.talk(pere, "De nuages, de virages, et de la boulangerie d'Icare. Demain matin, il voudra décoller avant le petit-déjeuner." if boy else "De nuages, de virages, et de la boulangerie d'Icare. Demain matin, elle voudra décoller avant le petit-déjeuner.", I._bye("Bonne nuit, pilote."), I._close(M), "à voix basse")
				else:
					M.close_talk()
			, "à voix basse")
			return
		M.talk(pere, str(_pick(M, ["Bonjour ! Attention aux ailes : on vient de les fixer. Un planeur dans le salon, c'est pratique pour le bricoler. Pour le sortir, beaucoup moins.",
			"Bon vent ! Tu tombes bien : on cherche quelqu'un de mince pour pousser. Non, je plaisante. Quoique."])),
			[{"id": "sortir", "label": "Comment allez-vous le sortir ?"}, {"id": "icare", "label": "Vous connaissez Icare Plané ?"}, {"id": "fermer", "label": "Bon vent !"}], func(id):
			match id:
				"sortir":
					M.talk(pere, "On a trois idées : démonter les ailes, démonter le mur, ou attendre que l'île descende. La troisième est la plus reposante.", I._bye("Ha ha ! Bon courage !"), I._close(M), "enthousiaste")
				"icare":
					M.talk(pere, "Icare ? C'est lui qui nous a tout appris ! Il plane jusqu'à la boulangerie tous les matins. Nous, on vise d'abord la porte du salon.", I._bye("Un jour, la boulangerie !"), I._close(M), "enthousiaste")
				_:
					M.close_talk()
		, "enthousiaste")
	M.talk_spot(pere, pere_cb)
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Un planeur blanc dort dans le salon, ses ailes d'un mur à l'autre. Dans le cockpit, un enfant s'est endormi, les mains sur le manche.",
			"La nuit, le planeur du salon a l'air encore plus grand. Un petit pilote ronfle dans le cockpit. Quelqu'un mesure la porte, à la lampe, en soupirant.",
			"Tout est calme. Seules les ailes blanches luisent un peu dans le noir, et un enfant fait « vrrr » en dormant."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Un planeur blanc dans le salon ! Ses longues ailes traversent la pièce d'un mur à l'autre. Dans le cockpit, un enfant fait « Vrrrrr ! ».",
			"Attention à la tête : une aile de planeur passe à hauteur de poitrine, d'un mur à l'autre. Près de la porte, quelqu'un la mesure en soupirant.",
			"Une famille de vol à voile a monté son planeur… dans le salon. Le nez pointe vers la porte. La porte a l'air inquiète."]))


## La petite météorologue : une fillette tient une station météo dans le salon. Près de la baie, le
## mât de mesure (l'anémomètre à coupelles et la girouette : ils tournent tout seuls, il y a toujours
## un peu de vent sur une île volante) et le pluviomètre ; au mur du fond, le grand tableau noir de ses
## prévisions (des soleils, des nuages, des flèches de vent à la craie, sans un mot écrit), son bureau
## (le cahier des bulletins, un ballon-sonde attaché) et le baromètre. Son grand-père est son assistant :
## il note, il porte le parapluie à hélice au garde-à-vous, il obéit très sérieusement. Elle veut
## travailler à l'Institut des Vents avec le Docteur Aurèle. On peut souffler sur l'anémomètre (il
## s'emballe puis ralentit, la girouette se tourne vers toi ; le premier record de la station vaut un
## parapluie à hélice, ou une plume du vent si l'on en a déjà un), lire le bulletin du jour (six
## bulletins ; relu, il est « mis à jour » et redessiné au tableau), tapoter le baromètre (l'aiguille
## hésite, puis annonce ; s'il doit pleuvoir, le grand-père ouvre le parapluie). La nuit, la fillette
## dort sur un matelas devant la baie (ou fait semblant : elle surveille la Lune) et le grand-père chuchote.
static func _meteo(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var room0 = M.room
	var nuit: bool = _nuit(M)
	var semblant: bool = r.randf() < 0.5
	var s: float = 1.0 if r.randf() < 0.5 else -1.0
	var nz: int = 1 if R.D < 7.0 else 2
	var bz: float = float(_baie(M, s)[1])
	# le mur du fond (sans la baie du fond des grandes pièces) : le bureau, le tableau noir, le
	# baromètre (du côté de la station)
	var l0: float = -hw + 0.35 if R.W <= 7.5 else -R.W * 0.25 + 1.15
	var l1: float = hw - 0.35
	var wb: float = 1.8 if R.W >= 6.6 else 1.55
	var hb: float = 1.0
	var tot: float = wb + 1.85
	var gcx: float = (l0 + l1) * 0.5
	var xd: float = gcx + s * (0.475 - tot * 0.5)
	var xt: float = gcx + s * (1.15 + wb * 0.5 - tot * 0.5)
	var xb: float = gcx + s * (wb + 1.65 - tot * 0.5)
	var yt: float = 1.45
	var yb: float = 1.5
	var zd: float = -hd + 0.42
	# les six bulletins de la station (celui de la maison, puis les « mises à jour ») et leurs dessins
	# (le matin, l'après-midi, le soir)
	var bulletins: Array = [
		"BULLETIN DU JOUR. Ce matin : soleil. Cet après-midi : soleil. Ce soir : la Lune, si elle est d'accord. Vent d'ouest : assez pour faire tourner l'anémomètre, pas assez pour décoiffer Papi.",
		"BULLETIN DU JOUR. Ce matin, un nuage en forme de chouquette passera au-dessus de la maison. Risque de faim : élevé. Cet après-midi, grand soleil. La station conseille un goûter.",
		"BULLETIN DU JOUR. Grand vent au Parc des Brumes : tenez bien vos chapeaux, vos cerfs-volants et vos grands-pères. Retour au calme pour le goûter. Ce soir, la Lune.",
		"BULLETIN DU JOUR. Averse prévue à quinze heures douze, à la minute près. Elle tombera sur Hautefond, deux cents mètres plus bas. Pour nous : un arc-en-ciel. C'est la meilleure part.",
		"BULLETIN DU JOUR. Avis de tempête… dans la cuisine : Papi fait des crêpes. Risque de farine : très élevé. Retour au beau temps après la vaisselle.",
		"BULLETIN DU JOUR. Brume douce sous l'île : les nuages font la sieste en dessous de nous. Merci de ne pas sauter dessus. Le Docteur Aurèle en baptisera trois. La station propose : Gaspard, Mirabelle et Chaussette."]
	var dessins: Array = [["soleil", "soleil", "lune"], ["chouquette", "soleil", "soleil"], ["vent", "vent", "lune"], ["soleil", "pluie", "arc"], ["soleil", "orage", "soleil"], ["nuage", "soleil", "nuage"]]
	var st := {"t": r.randf() * 10.0, "vit": 1.4, "souffle": 0.0, "vent_t": 0.0, "src": Vector3.ZERO, "gir": 0.0, "gir_v": 0.0,
		"baro": false, "bul": r.randi() % bulletins.size(), "lu": false, "dessin": false, "para": false, "para_n": 0, "idle": 12.0 + r.randf() * 8.0, "idle_p": ""}
	# --- le grand tableau noir : l'ardoise, le cadre de bois blond, l'auget, les craies, la brosse
	var zt: float = -hd + 0.035
	R.kit.box(R.L(xt, yt, zt), Vector3(wb, hb, 0.025), "nu_ardoise", 1.0)
	for sx in [-1.0, 1.0]:
		R.kit.box(R.L(xt + sx * (wb * 0.5 + 0.02), yt, zt + 0.006), Vector3(0.04, hb + 0.08, 0.04), "bois_clair", 1.0)
		R.kit.box(R.L(xt, yt + sx * (hb * 0.5 + 0.02), zt + 0.006), Vector3(wb + 0.08, 0.04, 0.04), "bois_clair", 1.0)
	R.kit.box(R.L(xt, yt - hb * 0.5 - 0.055, -hd + 0.075), Vector3(wb * 0.9, 0.022, 0.09), "bois_clair", 1.0)
	var craies: Array = ["nu_craie", "nu_jaune", "nu_bleu", "nu_rose"]
	for k in range(4):
		R.kit.cyl(R.L(xt - wb * 0.3 + k * 0.1, yt - hb * 0.5 - 0.036, -hd + 0.08) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.008, 0.008, 0.075, str(craies[k]), 6)
	R.kit.box(R.L(xt + wb * 0.28, yt - hb * 0.5 - 0.026, -hd + 0.08, 8.0), Vector3(0.13, 0.03, 0.05), "bois_clair", 1.0)
	R.kit.box(R.L(xt + wb * 0.28, yt - hb * 0.5 - 0.043, -hd + 0.08, 8.0), Vector3(0.13, 0.01, 0.05), "tissu_gris", 1.0)
	R.mark_wall(xt, yt, -hd, wb * 0.5 + 0.12)
	R.reserve(xt, -hd + 0.5, wb, 0.8)
	# ce qui reste au tableau : les trois colonnes, et en tête le matin (un soleil qui se lève), midi
	# (un petit soleil), le soir (un croissant de lune) ; en bas, le grand-père et son parapluie, la
	# fillette qui montre le ciel, des flèches de vent, une rose des vents
	var xft: Transform3D = R.L(xt, yt, -hd + 0.049)
	for sx2 in [-1.0, 1.0]:
		_meteo_craie(M, xft, Vector2(sx2 * wb / 6.0, -hb * 0.5 + 0.07), Vector2(sx2 * wb / 6.0, hb * 0.5 - 0.06), 0.008)
	_meteo_craie(M, xft, Vector2(-wb * 0.5 + 0.06, hb * 0.5 - 0.19), Vector2(wb * 0.5 - 0.06, hb * 0.5 - 0.19), 0.008)
	var yh: float = hb * 0.5 - 0.1
	var c0: float = -wb / 3.0
	var c2: float = wb / 3.0
	_meteo_rond_k(M, xft, Vector2(c0, yh - 0.02), 0.032, "nu_jaune")
	_meteo_craie(M, xft, Vector2(c0 - 0.045, yh - 0.037), Vector2(c0 + 0.045, yh - 0.037), 0.034, "nu_ardoise", 0.002)
	_meteo_craie(M, xft, Vector2(c0 - 0.075, yh - 0.02), Vector2(c0 + 0.075, yh - 0.02), 0.008, "nu_craie", 0.004)
	for k2 in range(3):
		var d2: Vector2 = Vector2.from_angle(PI * (0.25 + 0.25 * k2))
		_meteo_craie(M, xft, Vector2(c0, yh - 0.02) + d2 * 0.045, Vector2(c0, yh - 0.02) + d2 * 0.066, 0.007, "nu_jaune")
	_meteo_rond_k(M, xft, Vector2(0.0, yh), 0.026, "nu_jaune")
	for k3 in range(6):
		var d3: Vector2 = Vector2.from_angle(TAU * k3 / 6.0)
		_meteo_craie(M, xft, Vector2(0.0, yh) + d3 * 0.036, Vector2(0.0, yh) + d3 * 0.054, 0.007, "nu_jaune")
	_meteo_rond_k(M, xft, Vector2(c2, yh), 0.03, "nu_jaune")
	_meteo_rond_k(M, xft, Vector2(c2 + 0.014, yh + 0.009), 0.027, "nu_ardoise", 0.002)
	_meteo_rond_k(M, xft, Vector2(c2 + 0.058, yh + 0.03), 0.006, "nu_craie")
	var bp: Vector2 = Vector2(c0 - 0.05, -hb * 0.5 + 0.05)
	for e in [[Vector2(-0.02, 0.0), Vector2(0.0, 0.06)], [Vector2(0.02, 0.0), Vector2(0.0, 0.06)], [Vector2(0.0, 0.06), Vector2(0.0, 0.14)],
			[Vector2(-0.03, 0.1), Vector2(0.03, 0.12)], [Vector2(0.03, 0.12), Vector2(0.03, 0.2)]]:
		_meteo_craie(M, xft, bp + (e[0] as Vector2), bp + (e[1] as Vector2), 0.007)
	_meteo_rond_k(M, xft, bp + Vector2(0.0, 0.165), 0.017, "nu_craie")
	var dome: Array = [Vector2(-0.025, 0.2), Vector2(-0.005, 0.226), Vector2(0.03, 0.238), Vector2(0.065, 0.226), Vector2(0.085, 0.2)]
	for i in range(dome.size() - 1):
		_meteo_craie(M, xft, bp + (dome[i] as Vector2), bp + (dome[i + 1] as Vector2), 0.009, "nu_rouge")
	_meteo_craie(M, xft, bp + Vector2(-0.025, 0.2), bp + Vector2(0.085, 0.2), 0.006, "nu_rouge")
	var gp2: Vector2 = bp + Vector2(0.14, 0.0)
	for e2 in [[Vector2(-0.015, 0.0), Vector2(0.0, 0.04)], [Vector2(0.015, 0.0), Vector2(0.0, 0.04)], [Vector2(0.0, 0.04), Vector2(0.0, 0.095)],
			[Vector2(0.0, 0.08), Vector2(0.045, 0.115)], [Vector2(0.0, 0.08), Vector2(-0.03, 0.06)]]:
		_meteo_craie(M, xft, gp2 + (e2[0] as Vector2), gp2 + (e2[1] as Vector2), 0.007)
	_meteo_rond_k(M, xft, gp2 + Vector2(0.0, 0.112), 0.014, "nu_craie")
	var wp: Vector2 = Vector2(0.0, -hb * 0.5 + 0.12)
	for e3 in [[Vector2(-0.09, 0.0), Vector2(0.08, 0.0)], [Vector2(0.08, 0.0), Vector2(0.05, 0.022)], [Vector2(0.08, 0.0), Vector2(0.05, -0.022)],
			[Vector2(-0.07, -0.045), Vector2(0.05, -0.045)], [Vector2(0.05, -0.045), Vector2(0.025, -0.027)], [Vector2(0.05, -0.045), Vector2(0.025, -0.063)]]:
		_meteo_craie(M, xft, wp + (e3[0] as Vector2), wp + (e3[1] as Vector2), 0.008)
	var cp: Vector2 = Vector2(c2, -hb * 0.5 + 0.15)
	for k4 in range(8):
		var d4: Vector2 = Vector2.from_angle(TAU * k4 / 8.0 + PI * 0.5)
		_meteo_craie(M, xft, cp, cp + d4 * (0.075 if k4 % 2 == 0 else 0.04), 0.007)
	_meteo_craie(M, xft, cp + Vector2(0.0, 0.075), cp + Vector2(-0.014, 0.05), 0.008, "nu_rouge", 0.002)
	_meteo_craie(M, xft, cp + Vector2(0.0, 0.075), cp + Vector2(0.014, 0.05), 0.008, "nu_rouge", 0.002)
	_meteo_rond_k(M, xft, cp, 0.011, "nu_craie", 0.002)
	# les prévisions du bulletin de la maison, à la craie (on les efface et on les redessine)
	var tab: Node3D = I._node(M, R.P(xt, yt, -hd + 0.058), 0)
	var cr := {"trait": I._boxm(Vector3.ONE), "rond": I._cyl(0.5, 0.5, 1.0, 20),
		"blanc": _mat(Color(0.94, 0.94, 0.91), 0.0, 1.0, 0.12), "jaune": _mat(Color(1.0, 0.86, 0.36), 0.0, 1.0, 0.12),
		"bleu": _mat(Color(0.56, 0.78, 1.0), 0.0, 1.0, 0.12), "rose": _mat(Color(1.0, 0.62, 0.74), 0.0, 1.0, 0.12),
		"orange": _mat(Color(0.98, 0.72, 0.42), 0.0, 1.0, 0.12), "ardoise": _mat(Color(0.11, 0.16, 0.14), 0.0, 0.92)}
	var slots: Array = [Vector2(-wb / 3.0, -0.03), Vector2(0.0, -0.03), Vector2(wb / 3.0, -0.03)]
	var cases: Array = []
	for k5 in range(3):
		cases.append(_meteo_dessin(tab, str(dessins[int(st["bul"])][k5]), cr, slots[k5]))
	# --- le bureau de la station : le cahier des bulletins, les crayons, les jumelles ; le ballon-sonde
	R.table(xd, zd, 0, 0.95, 0.55, 0.76)
	var cy: float = r.randf_range(-12.0, 12.0)
	R.kit.box(R.L(xd - s * 0.1, 0.764, zd + 0.04, cy), Vector3(0.34, 0.008, 0.24), "nu_bleu", 1.0)
	R.kit.box(R.L(xd - s * 0.1, 0.772, zd + 0.04, cy), Vector3(0.32, 0.008, 0.22), "papier", 1.0)
	R.kit.box(R.L(xd - s * 0.1, 0.777, zd + 0.04, cy), Vector3(0.005, 0.002, 0.22), "nu_bleu", 1.0)
	R.kit.cyl(R.L(xd + s * 0.27, 0.76, zd - 0.12), 0.04, 0.04, 0.1, "ceramique", 12)
	var crayons: Array = ["nu_rouge", "nu_jaune", "nu_bleu", "nu_vert"]
	for k6 in range(4):
		R.kit.box(R.L(xd + s * 0.27 + (k6 - 1.5) * 0.014, 0.86, zd - 0.12 + (0.008 if k6 % 2 == 0 else -0.008)) * Transform3D(Basis(Vector3.BACK, (k6 - 1.5) * 0.14), Vector3.ZERO),
			Vector3(0.009, 0.13, 0.009), str(crayons[k6]), 1.0)
	if not nuit:
		for sx3 in [-1.0, 1.0]:
			R.kit.cyl(R.L(xd + s * 0.06 + sx3 * 0.036, 0.782, zd - 0.2) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.022, 0.022, 0.1, "noir", 10)
		R.kit.box(R.L(xd + s * 0.06, 0.782, zd - 0.15), Vector3(0.05, 0.015, 0.02), "argent", 1.0)
	R.kit.box(R.L(xd + s * 0.38, 0.775, zd + 0.17), Vector3(0.05, 0.03, 0.05), "argent", 1.0)
	var ancre: Vector3 = R.P(xd + s * 0.38, 0.79, zd + 0.17)
	var fil_m := _mat(Color(0.92, 0.9, 0.84), 0.0, 0.9)
	var ballon: Node3D = I._node(M, ancre + Vector3(s * 0.12, 1.75, 0.18), 0)
	_p(ballon, I._sph(0.16), _mat(Color(0.97, 0.97, 0.95), 0.0, 0.35), Vector3.ZERO, Vector3(1.0, 1.12, 1.0))
	_p(ballon, I._cyl(0.003, 0.003, 0.12, 4), fil_m, Vector3(0, -0.24, 0))
	_p(ballon, I._boxm(Vector3(0.06, 0.06, 0.06)), _mat(Color(1.0, 0.58, 0.2), 0.0, 0.6), Vector3(0, -0.33, 0))
	_sans_ombre(ballon)
	var ballon_base: Vector3 = ballon.global_position
	var fil: MeshInstance3D = _p(M.room, I._cyl(0.003, 0.003, 1.0, 4), fil_m, Vector3.ZERO)
	fil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_tendre(fil, ancre, ballon_base + Vector3(0, -0.36, 0))
	# --- le baromètre (un boîtier de bois blond, le cadran : la tempête et la pluie à gauche, le
	# variable, le beau temps et le beau fixe à droite ; l'aiguille dorée du matin, l'aiguille noire)
	var xfb: Transform3D = R.L(xb, yb, -hd)
	var face := Basis(Vector3.RIGHT, PI * 0.5)
	R.kit.cyl(xfb * Transform3D(face, Vector3.ZERO), 0.19, 0.19, 0.035, "bois_clair", 28)
	R.kit.ring(xfb * Transform3D(face, Vector3(0, 0, 0.035)), 0.155, 0.19, 0.022, "argent", 28)
	R.kit.cyl(xfb * Transform3D(face, Vector3(0, 0, 0.035)), 0.155, 0.155, 0.004, "ceramique", 28)
	var ph: float = -2.1
	while ph <= 2.11:
		var zone: String = "nu_lavande" if ph > 1.25 else ("nu_bleu" if ph > 0.45 else ("tissu_gris" if ph > -0.45 else ("nu_jaune" if ph > -1.25 else "tissu_orange")))
		R.kit.box(xfb * Transform3D(Basis(Vector3.BACK, ph), Vector3(-sin(ph) * 0.122, cos(ph) * 0.122, 0.041)), Vector3(0.026, 0.018, 0.003), zone, 1.0)
		ph += 0.12
	for k7 in range(13):
		var pt: float = -2.1 + k7 * 0.35
		R.kit.box(xfb * Transform3D(Basis(Vector3.BACK, pt), Vector3(-sin(pt) * 0.143, cos(pt) * 0.143, 0.041)), Vector3(0.003, 0.016, 0.002), "noir", 1.0)
	for sx4 in [-1.0, 1.0]:
		R.kit.box(xfb * Transform3D(Basis(Vector3.BACK, 0.35), Vector3(-sin(1.0) * 0.07 + sx4 * 0.011, cos(1.0) * 0.07 - sx4 * 0.004, 0.041)), Vector3(0.006, 0.022, 0.003), "nu_bleu", 1.0)
	_meteo_rond_k(M, xfb, Vector2(-0.01, 0.07), 0.012, "tissu_gris", 0.042)
	_meteo_rond_k(M, xfb, Vector2(0.008, 0.075), 0.015, "tissu_gris", 0.042)
	var soleil_b: Vector2 = Vector2(sin(1.0) * 0.07, cos(1.0) * 0.07)
	_meteo_rond_k(M, xfb, soleil_b, 0.012, "nu_jaune", 0.042)
	for k8 in range(4):
		var d8: Vector2 = Vector2.from_angle(TAU * k8 / 4.0 + 0.4)
		R.kit.box(xfb * Transform3D(Basis(Vector3.BACK, d8.angle()), Vector3(soleil_b.x + d8.x * 0.022, soleil_b.y + d8.y * 0.022, 0.042)), Vector3(0.012, 0.004, 0.003), "nu_jaune", 1.0)
	var pref: float = r.randf_range(-1.0, 0.4)
	R.kit.box(xfb * Transform3D(Basis(Vector3.BACK, pref), Vector3(-sin(pref) * 0.05, cos(pref) * 0.05, 0.046)), Vector3(0.005, 0.1, 0.002), "or", 1.0)
	R.kit.cyl(xfb * Transform3D(face, Vector3(0, 0, 0.055)), 0.155, 0.155, 0.002, "verre", 28)
	var aig: Node3D = I._node(M, R.P(xb, yb, -hd + 0.05), 0)
	var noir := _mat(Color(0.08, 0.08, 0.1), 0.3, 0.4)
	_p(aig, I._boxm(Vector3(0.007, 0.125, 0.003)), noir, Vector3(0, 0.05, 0))
	_p(aig, I._boxm(Vector3(0.014, 0.035, 0.003)), noir, Vector3(0, -0.022, 0))
	_p(aig, I._cyl(0.012, 0.012, 0.008, 12), _mat(Color(0.85, 0.86, 0.88), 0.9, 0.3), Vector3(0, 0, 0.002), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	aig.rotation.z = r.randf_range(-1.0, 0.25)
	_sans_ombre(aig)
	var baro_c: Vector3 = R.P(xb, yb, -hd + 0.06)
	R.mark_wall(xb, yb, -hd, 0.3)
	R.reserve(xb, -hd + 0.5, 0.6, 0.7)
	# --- le mât de mesure, devant la baie : l'anémomètre à coupelles, la girouette et sa croix (une
	# boule rouge pour le nord), le petit enregistreur et sa lumière verte
	var mx: float = s * (hw - 0.75)
	var mz: float = bz + 0.5
	var blanc := _mat(Color(0.96, 0.96, 0.95), 0.0, 0.35)
	var alu := _mat(Color(0.85, 0.86, 0.88), 0.9, 0.3)
	var rouge := _mat(Color(0.86, 0.16, 0.14), 0.0, 0.45)
	var mat_: Node3D = I._node(M, R.P(mx, 0, mz), 0)
	_p(mat_, I._cyl(0.2, 0.22, 0.05, 24), blanc, Vector3(0, 0.025, 0))
	_p(mat_, I._cyl(0.02, 0.02, 1.5, 10), alu, Vector3(0, 0.78, 0))
	_p(mat_, I._cyl(0.012, 0.012, 0.62, 8), alu, Vector3(0, 1.5, 0), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_p(mat_, I._boxm(Vector3(0.12, 0.16, 0.07)), blanc, Vector3(-s * 0.06, 1.05, 0))
	var led: MeshInstance3D = _p(mat_, I._sph(0.012), _mat(Color(0.3, 1.0, 0.45), 0.0, 0.3, 3.0), Vector3(-s * 0.122, 1.1, 0))
	_p(mat_, I._cyl(0.008, 0.008, 0.14, 8), alu, Vector3(0, 1.57, 0.3))
	var rotor := Node3D.new()
	mat_.add_child(rotor)
	rotor.position = Vector3(0, 1.64, 0.3)
	_p(rotor, I._cyl(0.02, 0.025, 0.04, 12), blanc, Vector3.ZERO)
	var coupe := SphereMesh.new()
	coupe.radius = 0.042
	coupe.height = 0.042
	coupe.is_hemisphere = true
	coupe.radial_segments = 14
	coupe.rings = 6
	var coupe_m := _mat(Color(0.95, 0.95, 0.94), 0.0, 0.4)
	coupe_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	for k9 in range(3):
		var bras := Node3D.new()
		rotor.add_child(bras)
		bras.rotation.y = TAU * k9 / 3.0
		_p(bras, I._boxm(Vector3(0.17, 0.008, 0.008)), alu, Vector3(0.085, 0, 0))
		_p(bras, coupe, coupe_m, Vector3(0.17, 0, 0), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_p(mat_, I._cyl(0.008, 0.008, 0.16, 8), alu, Vector3(0, 1.58, -0.3))
	for k10 in range(4):
		var a10: float = TAU * k10 / 4.0
		var dv: Vector3 = Vector3(sin(a10), 0, cos(a10))
		_p(mat_, I._boxm(Vector3(0.006, 0.006, 0.12)), alu, Vector3(0, 1.6, -0.3) + dv * 0.06, Vector3.ONE, Vector3(0, a10, 0))
		_p(mat_, I._sph(0.014), rouge if k10 == 0 else alu, Vector3(0, 1.6, -0.3) + dv * 0.125)
	var vane := Node3D.new()
	mat_.add_child(vane)
	vane.position = Vector3(0, 1.68, -0.3)
	_p(vane, I._boxm(Vector3(0.012, 0.012, 0.36)), alu, Vector3.ZERO)
	_p(vane, I._cyl(0.0, 0.03, 0.07, 10), rouge, Vector3(0, 0, 0.2), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_p(vane, I._boxm(Vector3(0.006, 0.1, 0.12)), rouge, Vector3(0, 0.02, -0.17))
	_p(vane, I._sph(0.014), alu, Vector3.ZERO)
	_sans_ombre(mat_)
	R.kit.col_box(R.L(mx, 0.8, mz), Vector3(0.25, 1.6, 0.25))
	R.reserve(mx, mz, 0.8, 0.9)
	var dehors: Vector3 = R.P(s * (hw + 3.0), 1.68, bz)
	var gpos: Vector3 = vane.global_position
	st["gir"] = atan2(dehors.x - gpos.x, dehors.z - gpos.z)
	vane.rotation.y = float(st["gir"])
	var souffle: CPUParticles3D = _souffle(M, R.P(mx, 1.5, mz), Vector3(s, 0, 0))
	souffle.emission_box_extents = Vector3(0.06, 0.06, 0.06)
	souffle.lifetime = 0.9
	souffle.amount = 24
	# --- le pluviomètre, sur sa sellette, devant l'autre moitié de la baie (un peu d'eau dedans)
	var xp: float = s * (hw - 0.42)
	var zp: float = bz - 0.45
	var niveau: float = r.randf_range(0.03, 0.14)
	R.kit.cyl(R.L(xp, 0, zp), 0.16, 0.18, 0.04, "ceramique", 16)
	R.kit.cyl(R.L(xp, 0.04, zp), 0.035, 0.035, 0.66, "ceramique", 10, false)
	R.kit.cyl(R.L(xp, 0.7, zp), 0.12, 0.1, 0.04, "ceramique", 16)
	R.kit.cyl(R.L(xp, 0.74, zp), 0.045, 0.045, 0.28, "verre", 16, false)
	R.kit.cyl(R.L(xp, 0.74, zp), 0.041, 0.041, niveau, "nu_bleu", 14)
	R.kit.cyl(R.L(xp, 1.02, zp), 0.045, 0.085, 0.07, "argent", 16, false)
	for k11 in range(6):
		R.kit.box(R.L(xp - s * 0.047, 0.77 + k11 * 0.04, zp), Vector3(0.002, 0.003, 0.02), "noir", 1.0)
	R.kit.col_box(R.L(xp, 0.55, zp), Vector3(0.3, 1.1, 0.3))
	R.reserve(xp, zp, 0.45, 0.45)
	R.tapis(xt, -hd + 1.55, 0, minf(wb + 0.9, 2.8), 1.5)
	# --- les gens : le jour, la fillette présente au tableau, le grand-père au garde-à-vous avec son
	# parapluie ; la nuit, elle dort sur un matelas devant la baie (des jumelles près de l'oreiller),
	# il veille debout à côté
	var fille: Node
	var papi: Node
	var face_f: Vector3 = Vector3(0, 0, 1)
	var gens_xz: Array = []
	if nuit:
		var xm: float = s * (hw - 1.65)
		R.kit.box(R.L(xm, 0.06, bz + 0.05), Vector3(0.75, 0.12, 1.5), "drap", 1.0)
		R.kit.box(R.L(xm, 0.125, bz + 0.3), Vector3(0.78, 0.03, 0.95), "tissu_bleu", 1.0)
		R.kit.box(R.L(xm, 0.15, bz - 0.52), Vector3(0.45, 0.08, 0.26), "tissu_blanc", 1.0)
		for sx5 in [-1.0, 1.0]:
			R.kit.cyl(R.L(xm + s * 0.3 + sx5 * 0.036, 0.142, bz - 0.36) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.022, 0.022, 0.1, "noir", 10)
		R.reserve(xm, bz + 0.05, 0.95, 1.7)
		fille = M.person("fille", xm, bz, 0, "dormir")
		fille.lie(R.P(xm, 0.12, bz + 0.6), Vector3(0, 0, -1))
		if semblant:
			fille.lines = ["Je ne dors pas. Je surveille la Lune.", "(Elle ouvre un œil.) Elle est toujours là.", "Zzz… Non ! Je ne dors pas !"]
		else:
			fille.lines = ["Zzz…", "Zzz… vent d'ouest… force trois… zzz…", "Mmh… Gaspard… reviens… zzz…"]
		fille.line_every = Vector2(9.0, 14.0)
		var pxn: float = xm - s * 0.85
		var pzn: float = bz + 0.35
		papi = M.person("vieux", pxn, pzn, _vers(pxn, pzn, xm, bz), "debout")
		papi.lines = ["Chut…", "Ciel dégagé, petite. Dors.", "Je note : la Lune est toujours là.", "Bonne nuit, chef…"]
		papi.line_every = Vector2(10.0, 15.0)
		R.reserve(pxn, pzn, 0.6, 0.6)
		gens_xz = [Vector2(xm, bz), Vector2(pxn, pzn)]
	else:
		var gx: float = xt - s * wb * 0.28
		var gz: float = -hd + 0.85
		face_f = Vector3(-gx * 0.25, 0, 1.0).normalized()
		fille = M.person("fille", gx, gz, rad_to_deg(atan2(face_f.x, face_f.z)), "enseigner")
		fille.lines = ["Assistant, notez : vent d'ouest, force deux.", "Humeur du ciel : excellente.", "Ce nuage-là, je l'appelle Gaspard.", "Plus tard, je travaillerai à l'Institut des Vents !", "Papi, le parapluie ! … Non, fausse alerte."]
		fille.line_every = Vector2(7.0, 11.0)
		var px: float = xb - s * 0.5
		var pz: float = -hd + 1.5
		papi = M.person("vieux", px, pz, _vers(px, pz, px - s * 0.4, hd), "debout")
		papi.lines = ["Noté, chef.", "Bien, chef.", "Parapluie prêt, chef.", "Je note : il fait beau. Encore.", "Elle a toujours la tête dans les nuages. C'est un compliment, chez nous."]
		papi.line_every = Vector2(9.0, 14.0)
		R.reserve(px, pz, 0.6, 0.6)
		gens_xz = [Vector2(gx, gz), Vector2(px, pz)]
	var para: Dictionary = _meteo_parapluie(papi)
	var hel: Node3D = para["hel"]
	# --- le reste du salon : la cheminée à l'éthanol (sur le mur d'en face, si elle y tient), un
	# lampadaire, des plantes, le public du bulletin (deux peluches sur un pouf), des tableaux
	var zfs: Array = [-hd + 0.95] if nz == 1 else [0.0]
	for zf in zfs:
		var fx: float = -s * (hw - 0.22)
		if R.wall_free(-s * (hw - 0.02), 1.22, float(zf), 0.8) and R.is_free(fx, float(zf), 0.8, 1.8):
			R.foyer(fx, float(zf), 90.0 * s, true)
			R.reserve(fx, float(zf), 0.8, 1.8)
			break
	for lc in [[-s * (hw - 0.45), -hd + 0.45], [-s * (hw - 0.45), hd - 1.9], [s * (hw - 0.45), hd - 1.9]]:
		if R.is_free(float(lc[0]), float(lc[1]), 0.5, 0.5):
			_lampadaire(M, float(lc[0]), float(lc[1]))
			break
	var npot: int = 0
	for pc in [[s * (hw - 0.45), hd - 1.85], [-s * (hw - 0.45), hd - 1.85], [s * (hw - 0.4), -hd + 0.45]]:
		if npot >= 2:
			break
		if R.is_free(float(pc[0]), float(pc[1]), 0.5, 0.5):
			_pot(M, float(pc[0]), float(pc[1]), 0.0, r.randf_range(0.9, 1.25), str(_pick(M, ["", "nu_rose", "nu_jaune", "nu_lavande"])))
			npot += 1
	for pc2 in [[xt - s * 0.2, -hd + 2.45], [xd + s * 0.1, -hd + 2.05], [xt + s * 0.55, -hd + 2.45]]:
		var ox: float = float(pc2[0])
		var oz: float = minf(float(pc2[1]), hd - 1.95)
		var loin: bool = true
		for g in gens_xz:
			if (g as Vector2).distance_to(Vector2(ox, oz)) < 0.95:
				loin = false
		if loin and R.is_free(ox, oz, 0.65, 0.65):
			_meteo_peluches(M, ox, oz)
			break
	_cadres(M, 2)
	# --- le parapluie : on l'ouvre (la toile s'arrondit au-dessus de sa tête, l'hélice tourne), on le
	# referme ; une alerte : ouvert quelques secondes, puis refermé (sauf si une autre alerte a suivi)
	var ouvrir_para := func(ouvert: bool) -> void:
		if bool(st["para"]) == ouvert:
			return
		st["para"] = ouvert
		var pn: Node3D = para["n"]
		var toile: Node3D = para["toile"]
		var tw: Tween = M.room.create_tween()
		tw.set_parallel(true)
		tw.tween_property(pn, "position", Vector3(-0.14, 1.15, 0.12) if ouvert else Vector3(-0.24, 0.85, 0.15), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(toile, "scale", Vector3.ONE if ouvert else Vector3(0.1, 2.2, 0.1), 0.45).set_trans(Tween.TRANS_BACK if ouvert else Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(toile, "position:y", 0.78 if ouvert else 0.6, 0.45)
		M.main.sfx("fendre_air", pn.global_position)
	var alerte := func(dit: bool) -> void:
		st["para_n"] = int(st["para_n"]) + 1
		var jeton: int = int(st["para_n"])
		ouvrir_para.call(true)
		if dit:
			papi.say("Parapluie ouvert, chef !", 3.0)
		await M.get_tree().create_timer(4.5).timeout
		if not _la(M, room0) or int(st["para_n"]) != jeton:
			return
		ouvrir_para.call(false)
		if dit:
			papi.say(str(_pick(M, ["Parapluie refermé, chef. Fausse alerte.", "Refermé, chef. Il ne pleut toujours pas."])), 3.0)
	# --- le baromètre : on le tapote, l'aiguille hésite (de moins en moins), s'arrête… et la fillette
	# annonce (zones : 0 tempête, 1 pluie, 2 variable, 3 beau temps, 4 beau fixe)
	var baro_fille: Array = [
		["TEMPÊTE ! Assistant, le parapluie !", "Tempête ! … Dans un verre d'eau. Assistant, le parapluie quand même !"],
		["Pluie ! Assistant, le parapluie !", "Il va pleuvoir ! Enfin, en bas, sur le Plancher. Assistant, le parapluie, par principe !"],
		["Variable. Le baromètre ne sait pas. Moi non plus. C'est ça, la science.", "Variable ! Il fera un temps. Je ne sais pas encore lequel."],
		["Beau temps ! Comme hier. Comme d'habitude. Assistant, notez : « encore beau ».", "Beau temps ! Ciel bleu, vent doux, et une forte probabilité de goûter."],
		["Beau fixe ! L'aiguille est tellement contente qu'elle est allée jusqu'au bout.", "Très sec ! Papi, tu as encore oublié d'arroser les plantes ?"]]
	var baro_papi: Array = ["", "", "Noté, chef : « variable ».", "Noté, chef : « beau ». Encore.", "Noté, chef. Et j'arrose les plantes."]
	var baro_nuit: Array = ["Chut… Tempête. Dans un verre d'eau, sûrement. J'ouvre le parapluie quand même.", "Pluie… sur le Plancher, sans doute. J'ouvre le parapluie. Tout doucement.",
		"Variable… comme ses rêves.", "Beau temps pour demain. Elle va être contente.", "Beau fixe. Je le lui dirai au réveil."]
	var annoncer := func(zi: int) -> void:
		st["baro"] = false
		M.main.sfx("clochette", baro_c)
		_bulle(M, baro_c + Vector3(0, 0.3, 0.08), "Ding !", Color(1.0, 0.92, 0.6), 38, 0.35, 1.3)
		if nuit:
			papi.say(str(baro_nuit[zi]), 4.5)
			if semblant:
				S._say_late(M, fille, str(_pick(M, ["(Sans ouvrir les yeux.) Noté.", "Je ne dors pas. J'ai tout entendu.", "(Elle ouvre un œil.) … Bon. (Elle le referme.)"])), 2.5)
			if zi <= 1:
				alerte.call(false)
			return
		if zi >= 3:
			fille.gesture("joie", 1.8)
		fille.say(str(_pick(M, baro_fille[zi])), 4.0)
		if zi > 1:
			S._say_late(M, papi, str(baro_papi[zi]), 1.8)
			return
		await M.get_tree().create_timer(1.1).timeout
		if not _la(M, room0):
			return
		alerte.call(true)
	var tapoter := func() -> void:
		if bool(st["baro"]):
			return
		st["baro"] = true
		M.main.sfx("touche_bois", baro_c)
		_bulle(M, baro_c + Vector3(0, 0.28, 0.08), "Toc, toc !", Color(1.0, 0.95, 0.8), 34, 0.3, 1.2)
		var zr: float = r.randf()
		var zi: int = 3 if zr < 0.32 else (4 if zr < 0.5 else (2 if zr < 0.7 else (1 if zr < 0.88 else 0)))
		var bornes: Array = [[1.35, 2.0], [0.55, 1.15], [-0.32, 0.32], [-1.15, -0.55], [-2.0, -1.35]]
		var cible: float = r.randf_range(float(bornes[zi][0]), float(bornes[zi][1]))
		var a0: float = aig.rotation.z
		var tw: Tween = M.room.create_tween()
		for e4 in [[a0 + 0.5, 0.22], [a0 - 0.4, 0.38], [lerpf(a0, cible, 0.5) + 0.3, 0.42], [cible - 0.24, 0.42], [cible + 0.1, 0.3]]:
			tw.tween_property(aig, "rotation:z", clampf(float(e4[0]), -2.15, 2.15), float(e4[1])).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(aig, "rotation:z", cible, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tw.tween_callback(annoncer.bind(zi))
		if not nuit:
			S._say_late(M, fille, str(_pick(M, ["Il réfléchit…", "Chut ! Il hésite.", "Allez, décide-toi…"])), 0.5, 2.0)
	# --- le bulletin du jour (relu : une mise à jour, et le tableau est redessiné, case par case)
	var redessiner := func(bi: int) -> void:
		var sy: Array = dessins[bi]
		for k12 in range(3):
			var old: Node3D = cases[k12]
			var nv: Node3D = _meteo_dessin(tab, str(sy[k12]), cr, slots[k12])
			nv.scale = Vector3(0.01, 0.01, 1.0)
			cases[k12] = nv
			var tw: Tween = M.room.create_tween()
			tw.tween_interval(0.15 + k12 * 0.42)
			tw.tween_property(old, "scale", Vector3(0.01, 0.01, 1.0), 0.18)
			tw.tween_callback(old.queue_free)
			tw.tween_property(nv, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var lire := func() -> void:
		if bool(st["dessin"]):
			return
		var bi: int = int(st["bul"])
		var maj: bool = bool(st["lu"]) and not nuit
		if maj:
			bi = (bi + 1) % bulletins.size()
			st["bul"] = bi
		st["lu"] = true
		M.main.sfx("carillon", tab.global_position)
		M.say(str(bulletins[bi]), 9.0)
		if nuit:
			S._say_late(M, papi, "Chut… Elle l'a écrit avant de dormir. Elle prépare toujours celui du lendemain.", 1.0)
			if semblant:
				S._say_late(M, fille, "(Sans ouvrir les yeux.) Il est très bien, ce bulletin.", 3.5)
			return
		if not maj:
			fille.gesture("salut", 1.6)
			fille.say(str(_pick(M, ["Mesdames et messieurs, le bulletin !", "Voici le temps qu'il fera. Normalement.", "Le bulletin du jour, en exclusivité !"])), 3.0)
			S._say_late(M, papi, str(_pick(M, ["Bulletin noté, chef.", "Noté, chef. Très beau bulletin."])), 2.2)
			return
		st["dessin"] = true
		fille.set_pose("peindre", Vector3(0, 0, -1))
		fille.say(str(_pick(M, ["Mise à jour ! Le ciel a changé d'avis.", "Attendez, je corrige ! Nouveau bulletin !", "Flash spécial ! Je redessine !"])), 3.0)
		redessiner.call(bi)
		await M.get_tree().create_timer(1.7).timeout
		if not _la(M, room0):
			return
		fille.set_pose("enseigner", face_f)
		st["dessin"] = false
		S._say_late(M, papi, "Mise à jour notée, chef.", 0.6)
	# --- souffler sur l'anémomètre : il s'emballe, la girouette se tourne vers toi, on mesure ; le
	# premier record de la station vaut le parapluie d'honneur (une fois)
	var recompense := func(record: bool) -> void:
		if bool(M.state().get("nu_meteo", false)):
			return
		var cad: String = _neuf(M, "parapluie_helice", "plume_vent")
		var pc3: bool = cad == "parapluie_helice"
		var txt: String
		if nuit:
			txt = "Chut… Quel souffle, en pleine nuit ! Elle aurait voulu vous le remettre elle-même. Tenez, tout bas : le parapluie d'honneur de la station. Quand on l'ouvre, l'hélice tourne. Pas ici : on la réveillerait." if pc3 else "Chut… Quel souffle, en pleine nuit ! Vous avez déjà un parapluie à hélice ? Alors, tout bas : la plume d'honneur de la station, une plume du vent. Le Docteur Aurèle adore ces plumes."
		else:
			if record:
				fille.say("Record ! Assistant, le parapluie d'honneur !" if pc3 else "Record ! Assistant, la plume d'honneur !", 3.0)
			else:
				fille.say("Quel souffle ! Assistant, le parapluie d'honneur !" if pc3 else "Quel souffle ! Assistant, la plume d'honneur !", 3.0)
			papi.gesture("salut", 1.5)
			await M.get_tree().create_timer(1.4).timeout
			if not _la(M, room0) or bool(M.state().get("nu_meteo", false)):
				return
			txt = "Bien, chef. (Il te tend un parapluie rouge, très solennellement.) Le parapluie d'honneur de la station. Quand on l'ouvre, l'hélice mesure le vent. Enfin… elle tourne. Ne le montrez pas au Docteur Aurèle : il dit que ça fausse ses mesures." if pc3 else "Bien, chef. (Il te tend une longue plume blanche, très solennellement.) Vous avez déjà un parapluie à hélice ? Alors voici la plume d'honneur de la station : une plume du vent, tombée sur l'anémomètre un jour de grand vent. Le Docteur Aurèle adore ces plumes."
		M.state()["nu_meteo"] = true
		M.talk(papi, txt, I._bye("Merci… Bonne nuit !") if nuit else I._bye("Merci, assistant !"), func(_i):
			M.give([[cad, 1]], "")
			M.close_talk(), "à voix basse" if nuit else "très sérieux")
	var souffler := func() -> void:
		if float(st["vit"]) > 12.0:
			if nuit:
				papi.say("Chut… Il tourne encore. Laissez-le souffler un peu.", 3.0)
			else:
				fille.say(str(_pick(M, ["Attendez qu'il ralentisse ! On ne mesure pas deux souffles à la fois.", "Il tourne encore ! Patience : c'est de la science."])), 3.0)
			return
		var tete: Vector3 = M.main._player_pos_v27() + Vector3(0, 1.5, 0)
		var vers: Vector3 = (rotor.global_position - tete).normalized()
		st["vit"] = 30.0 + r.randf() * 8.0
		st["vent_t"] = 3.5
		st["src"] = tete
		st["souffle"] = 0.6
		souffle.global_position = tete + vers * 0.25
		souffle.direction = vers
		souffle.emitting = true
		M.main.sfx("bourrasque", rotor.global_position)
		_bulle(M, tete.lerp(rotor.global_position, 0.5) + Vector3(0, 0.25, 0), "Fffffouuuh !", Color(0.85, 0.95, 1.0), 40, 0.4, 1.4)
		var n: int = r.randi_range(48, 131)
		var record: bool = n > int(M.state().get("nu_meteo_record", 0))
		if record:
			M.state()["nu_meteo_record"] = n
		await M.get_tree().create_timer(1.3).timeout
		if not _la(M, room0):
			return
		if nuit:
			papi.say("%d kilomètres-heure… Je le note pour demain matin." % n, 4.0)
			S._say_late(M, fille, "(Sans ouvrir les yeux.) Joli souffle. Je dors." if semblant else "Zzz… grand vent… zzz…", 2.2)
		else:
			fille.gesture("joie", 2.0)
			if record:
				fille.say("%d kilomètres-heure ! Nouveau record de la station !" % n, 3.5)
			else:
				fille.say(str(_pick(M, ["%d kilomètres-heure ! Assistant, notez !", "%d kilomètres-heure ! Vous soufflez comme une tempête de poche !", "%d kilomètres-heure ! Le Docteur Aurèle serait impressionné !"])) % n, 3.5)
			S._say_late(M, papi, "Record noté, chef." if record else "Noté, chef.", 1.6)
		if bool(M.state().get("nu_meteo", false)):
			return
		await M.get_tree().create_timer(2.4).timeout
		if not _la(M, room0):
			return
		recompense.call(record)
	# --- ce qui bouge : l'anémomètre, la girouette, la lumière de l'enregistreur, le ballon-sonde,
	# l'hélice du parapluie ; et de temps en temps, la fillette ajoute un détail au tableau
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(rotor):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var v0: float = 0.9 if nuit else 1.4
		var vit: float = v0 + (float(st["vit"]) - v0) * exp(-dt * 0.38)
		st["vit"] = vit
		rotor.rotation.y -= vit * dt
		if float(st["souffle"]) > 0.0:
			st["souffle"] = float(st["souffle"]) - dt
			if float(st["souffle"]) <= 0.0:
				souffle.emitting = false
		# la girouette (un ressort amorti) montre d'où vient le vent : la baie… ou toi
		var vt: float = float(st["vent_t"])
		var src: Vector3 = dehors
		if vt > 0.0:
			src = st["src"]
		st["vent_t"] = maxf(0.0, vt - dt)
		var gp: Vector3 = vane.global_position
		var cible: float = atan2(src.x - gp.x, src.z - gp.z) + 0.2 * sin(t * 0.55) + 0.07 * sin(t * 2.1)
		var gv: float = float(st["gir_v"]) + (wrapf(cible - float(st["gir"]), -PI, PI) * 7.0 - float(st["gir_v"]) * 2.4) * dt
		st["gir_v"] = gv
		st["gir"] = float(st["gir"]) + gv * dt
		vane.rotation.y = float(st["gir"])
		led.visible = fmod(t, 2.4) < 0.18
		var bpos: Vector3 = ballon_base + Vector3(0.05 * sin(t * 0.7), 0.035 * sin(t * 1.1), 0.05 * sin(t * 0.53 + 1.0))
		ballon.global_position = bpos
		_tendre(fil, ancre, bpos + Vector3(0, -0.36, 0))
		if bool(st["para"]):
			hel.rotation.y += dt * 15.0
		if nuit or bool(st["dessin"]) or bool(fille.talking):
			return
		st["idle"] = float(st["idle"]) - dt
		if float(st["idle"]) > 0.0:
			return
		if str(st["idle_p"]) == "":
			st["idle_p"] = "craie"
			st["idle"] = 2.8
			fille.set_pose("peindre", Vector3(0, 0, -1))
			fille.say(str(_pick(M, ["Je rajoute un petit nuage. Pour faire joli.", "Une flèche de vent, ici… Voilà.", "Un peu plus de soleil. Là."])), 2.6)
		else:
			st["idle_p"] = ""
			st["idle"] = 18.0 + randf() * 10.0
			fille.set_pose("enseigner", face_f)
	M.act(R.P(mx - s * 0.55, 0, mz + 0.4), "E : souffler sur l'anémomètre", souffler, 1.2)
	M.act(R.P(xb, 0, -hd + 0.8), "E : tapoter le baromètre", tapoter, 1.1, func(): return not bool(st["baro"]))
	M.act(R.P(xd, 0, zd + 0.85), "E : lire le bulletin du jour", lire, 1.2, func(): return not bool(st["dessin"]))
	# --- les conversations
	var fille_cb := func() -> void:
		if nuit:
			if semblant:
				M.talk(fille, "Chut ! Je ne dors pas : je surveille la Lune. Elle bouge quand personne ne la regarde.",
					[{"id": "bouge", "label": "Elle bouge vraiment ?"}, {"id": "fermer", "label": "(La laisser surveiller)"}], func(id):
					if id == "bouge":
						M.talk(fille, "Un tout petit peu, vers la gauche. Le Docteur Aurèle dit que c'est normal : c'est nous qui tournons. Moi, je préfère vérifier. … Je ne dors pas !", I._bye("Bonne surveillance…"), I._close(M), "à voix basse")
					else:
						M.close_talk()
				, "à voix basse")
			else:
				M.talk(fille, "Zzz… cumulus… stratus… chouquettus… zzz…", I._bye("(La laisser dormir)"), I._close(M), "endormie")
			return
		M.talk(fille, str(_pick(M, ["Bonjour ! Bienvenue à la station météo de la maison. Ici, on prévoit le temps. Aujourd'hui, il fait beau. Je l'avais prévu.",
			"Bon vent ! Vous tombez bien : c'est l'heure du bulletin. Assistant, à vos notes !", "Chut… je mesure le vent. … Voilà : il y en a. Bonjour !"])),
			[{"id": "plus_tard", "label": "Que veux-tu faire plus tard ?"}, {"id": "instruments", "label": "À quoi servent tes instruments ?"}, {"id": "fermer", "label": "Bon vent, chef !"}], func(id):
			match id:
				"plus_tard":
					M.talk(fille, "Météorologue à l'Institut des Vents, avec le Docteur Aurèle ! Il baptise les nuages. Moi aussi, je veux baptiser des nuages. J'ai déjà une liste : Gaspard, Mirabelle, Chaussette…",
						[{"id": "lettre", "label": "Tu lui as déjà écrit ?"}, {"id": "fermer", "label": "Tu y arriveras !"}], func(id2):
						if id2 == "lettre":
							M.talk(fille, "Quarante-deux lettres ! Il m'a répondu une fois : « Chère collègue, votre prévision de mardi était juste. » Papi l'a encadrée. Elle est au-dessus de mon lit.", I._bye("Chère collègue !"), I._close(M), "fière")
						else:
							M.close_talk()
					, "rêveuse")
				"instruments":
					M.talk(fille, "L'anémomètre mesure le vent. Il tourne tout seul : ici, il y a toujours un peu de vent, on habite sur une île volante. Soufflez dessus, vous verrez ! Et le baromètre, tapotez-le : il hésite toujours un peu avant de répondre.", I._bye("Je vais essayer !"), I._close(M), "passionnée")
				_:
					M.close_talk()
		, "passionnée")
	M.talk_spot(fille, fille_cb)
	var papi_cb := func() -> void:
		if nuit:
			M.talk(papi, "Chut… Elle dit qu'elle ne dort pas : elle surveille la Lune, au cas où elle partirait." if semblant else "Chut… Elle s'est endormie en comptant les nuages. Elle en était à quarante-trois.",
				[{"id": "lune", "label": "Elle surveille la Lune ?" if semblant else "Pourquoi devant la baie ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if id == "lune":
					M.talk(papi, "Elle a peur qu'on la perde, cette Lune. Alors elle la regarde jusqu'à ce que ses yeux se ferment. Ensuite, c'est moi qui prends le relais. C'est mon travail d'assistant." if semblant else "Pour surveiller la Lune, au cas où elle partirait. Elle la regarde jusqu'à ce que ses yeux se ferment. Ensuite, c'est moi qui prends le relais. C'est mon travail d'assistant.",
						I._bye("Bonne veille…"), I._close(M), "à voix basse")
				else:
					M.close_talk()
			, "à voix basse")
			return
		M.talk(papi, str(_pick(M, ["Bonjour. Je suis l'assistant. Assistant météorologue de troisième classe : c'est elle qui m'a nommé. J'attends toujours mon augmentation.",
			"Chut, elle va présenter le bulletin. Moi, je note. Et je porte le parapluie. C'est un poste à responsabilités.",
			"Bon vent ! Pardon, je reste au garde-à-vous : c'est le règlement de la station. Article un."])),
			[{"id": "parapluie", "label": "Pourquoi un parapluie, à l'intérieur ?"}, {"id": "pluvio", "label": "Il pleut souvent, ici ?"}, {"id": "fermer", "label": "Bon courage, assistant !"}], func(id):
			match id:
				"parapluie":
					M.talk(papi, "Règlement de la station, article un : l'assistant porte le parapluie. Article deux : l'assistant ne discute pas l'article un. C'est elle qui a écrit le règlement. Je l'ai fait encadrer.",
						[{"id": "fier", "label": "Vous êtes fier d'elle ?"}, {"id": "fermer", "label": "Ha ha !"}], func(id2):
						if id2 == "fier":
							M.talk(papi, "Fier ? … (Il essuie ses lunettes.) Elle connaît le nom de chaque nuage, la vitesse du vent et l'heure exacte du goûter. Un jour, elle travaillera à l'Institut des Vents. Et moi, je porterai encore le parapluie. Si elle veut bien de moi.", I._bye("Elle voudra."), I._close(M), "ému")
						else:
							M.close_talk()
					, "très sérieux")
				"pluvio":
					M.talk(papi, "Jamais : les nuages sont en dessous de nous. Alors chaque matin, je verse un dé à coudre d'eau dans le pluviomètre, en cachette. Elle note « petite averse ». Elle est si contente. Ne lui dites rien.", I._bye("Promis, motus."), I._close(M), "à voix basse")
				_:
					M.close_talk()
		, "très sérieux")
	M.talk_spot(papi, papi_cb)
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Devant la baie, une fillette dort sur un matelas, des jumelles près de l'oreiller. Son grand-père veille, son parapluie à la main.",
			"La station météo dort. Enfin, presque : l'anémomètre tourne tout doucement, et la petite météorologue surveille la Lune les yeux fermés.",
			"Il fait nuit. Au tableau noir, les prévisions de demain sont déjà dessinées. Un grand-père te fait « chut » : la petite dort devant la baie."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Une station météo dans le salon ! Un anémomètre tourne près de la baie, un baromètre brille au mur, et une fillette présente le bulletin devant un grand tableau noir.",
			"« Bulletin du jour ! » annonce une petite voix. Une fillette, une craie à la main ; un grand-père au garde-à-vous, un parapluie rouge à l'épaule. Bienvenue à la station météo de la maison.",
			"Des soleils et des nuages à la craie, un anémomètre qui tourne tout seul, un parapluie au garde-à-vous… Ici, on prévoit le temps. Il fait beau. C'était prévu."]))


## Un trait de craie qui reste (R.kit) sur le tableau noir : xf est le repère du tableau (x vers la
## droite, y vers le haut, z vers la pièce) ; a et b dans son plan, ep : l'épaisseur ; dz : un peu en
## avant (pour passer par-dessus un autre trait).
static func _meteo_craie(M, xf: Transform3D, a: Vector2, b: Vector2, ep: float, key: String = "nu_craie", dz: float = 0.0) -> void:
	var d: Vector2 = b - a
	var c: Vector2 = (a + b) * 0.5
	M.R.kit.box(xf * Transform3D(Basis(Vector3.BACK, d.angle()), Vector3(c.x, c.y, dz)), Vector3(d.length() + ep * 0.5, ep, 0.003), key, 1.0)


## Un rond qui reste (R.kit) dans le plan du repère xf (craie, cache couleur d'ardoise, cadran…).
static func _meteo_rond_k(M, xf: Transform3D, c: Vector2, rr: float, key: String, dz: float = 0.0) -> void:
	M.R.kit.cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(c.x, c.y, dz - 0.0015)), rr, rr, 0.003, key, 16)


## Un trait de craie qu'on peut effacer (un morceau d'une prévision) ; cr : les craies et les formes.
static func _meteo_trait(n: Node3D, cr: Dictionary, col: String, a: Vector2, b: Vector2, ep: float, z: float = 0.0) -> void:
	var d: Vector2 = b - a
	_p(n, cr["trait"], cr[col], Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, z), Vector3(d.length() + ep * 0.5, ep, 0.004), Vector3(0, 0, d.angle()))


## Un rond de craie qu'on peut effacer.
static func _meteo_rond(n: Node3D, cr: Dictionary, col: String, c: Vector2, rr: float, z: float = 0.0) -> void:
	_p(n, cr["rond"], cr[col], Vector3(c.x, c.y, z), Vector3(rr * 2.0, 0.004, rr * 2.0), Vector3(PI * 0.5, 0, 0))


## Un nuage à la craie (trois ronds, un fond plat), centré en o.
static func _meteo_nuage(n: Node3D, cr: Dictionary, col: String, o: Vector2) -> void:
	_meteo_rond(n, cr, col, o + Vector2(-0.065, -0.005), 0.05)
	_meteo_rond(n, cr, col, o + Vector2(0.0, 0.028), 0.066)
	_meteo_rond(n, cr, col, o + Vector2(0.066, -0.002), 0.05)
	_meteo_trait(n, cr, col, o + Vector2(-0.09, -0.032), o + Vector2(0.095, -0.032), 0.045)


## Une prévision dessinée à la craie sur le tableau (soleil, nuage, pluie, orage, vent, lune,
## arc-en-ciel, nuage en forme de chouquette) : un nœud posé sur `tab` (le repère du tableau), en `at`.
static func _meteo_dessin(tab: Node3D, kind: String, cr: Dictionary, at: Vector2) -> Node3D:
	var n := Node3D.new()
	tab.add_child(n)
	n.position = Vector3(at.x, at.y, 0.0)
	match kind:
		"soleil":
			_meteo_rond(n, cr, "jaune", Vector2.ZERO, 0.07)
			for k in range(8):
				var d: Vector2 = Vector2.from_angle(TAU * k / 8.0)
				_meteo_trait(n, cr, "jaune", d * 0.095, d * 0.145, 0.016)
		"nuage":
			_meteo_nuage(n, cr, "blanc", Vector2.ZERO)
		"pluie":
			_meteo_nuage(n, cr, "blanc", Vector2(0.0, 0.045))
			for x in [-0.07, -0.025, 0.02, 0.065]:
				_meteo_trait(n, cr, "bleu", Vector2(float(x), -0.03), Vector2(float(x) - 0.02, -0.085), 0.014)
				_meteo_trait(n, cr, "bleu", Vector2(float(x) - 0.03, -0.105), Vector2(float(x) - 0.045, -0.145), 0.014)
		"orage":
			_meteo_nuage(n, cr, "blanc", Vector2(0.0, 0.05))
			_meteo_trait(n, cr, "jaune", Vector2(0.015, -0.005), Vector2(-0.03, -0.065), 0.02)
			_meteo_trait(n, cr, "jaune", Vector2(-0.03, -0.065), Vector2(0.02, -0.065), 0.02)
			_meteo_trait(n, cr, "jaune", Vector2(0.02, -0.065), Vector2(-0.025, -0.14), 0.02)
		"vent":
			for e in [[0.065, -0.12, 0.07], [0.0, -0.1, 0.12], [-0.065, -0.13, 0.05]]:
				var y: float = float(e[0])
				var x1: float = float(e[2])
				_meteo_trait(n, cr, "blanc", Vector2(float(e[1]), y), Vector2(x1, y), 0.014)
				_meteo_trait(n, cr, "blanc", Vector2(x1, y), Vector2(x1 - 0.038, y + 0.028), 0.014)
				_meteo_trait(n, cr, "blanc", Vector2(x1, y), Vector2(x1 - 0.038, y - 0.028), 0.014)
		"lune":
			_meteo_rond(n, cr, "jaune", Vector2.ZERO, 0.08)
			_meteo_rond(n, cr, "ardoise", Vector2(0.04, 0.026), 0.074, 0.003)
			for e2 in [[Vector2(0.1, 0.085), 0.012], [Vector2(-0.085, 0.1), 0.009], [Vector2(0.075, -0.09), 0.008]]:
				_meteo_rond(n, cr, "blanc", e2[0] as Vector2, float(e2[1]))
		"arc":
			for bd in [[0.12, "rose"], [0.098, "jaune"], [0.076, "bleu"]]:
				var rr: float = float(bd[0])
				for i in range(9):
					var a0: float = PI * i / 9.0
					var a1: float = PI * (i + 1) / 9.0
					_meteo_trait(n, cr, str(bd[1]), Vector2(cos(a0), sin(a0)) * rr + Vector2(0.0, -0.05), Vector2(cos(a1), sin(a1)) * rr + Vector2(0.0, -0.05), 0.02)
			for sx in [-1.0, 1.0]:
				_meteo_rond(n, cr, "blanc", Vector2(sx * 0.098, -0.06), 0.026, 0.003)
				_meteo_rond(n, cr, "blanc", Vector2(sx * 0.125, -0.07), 0.02, 0.003)
		"chouquette":
			_meteo_rond(n, cr, "orange", Vector2.ZERO, 0.07)
			for e3 in [[Vector2(-0.055, 0.04), 0.035], [Vector2(0.0, 0.066), 0.04], [Vector2(0.055, 0.04), 0.035]]:
				_meteo_rond(n, cr, "orange", e3[0] as Vector2, float(e3[1]))
			for p in [Vector2(-0.04, 0.03), Vector2(0.0, 0.055), Vector2(0.035, 0.02), Vector2(-0.015, -0.01), Vector2(0.05, -0.02), Vector2(-0.05, -0.03), Vector2(0.02, 0.08)]:
				_meteo_rond(n, cr, "blanc", p as Vector2, 0.009, 0.003)
	_sans_ombre(n)
	return n


## Le parapluie à hélice du grand-père, accroché à son corps (f.npc) : il le porte au garde-à-vous,
## fermé ; ouvert, la toile rouge s'arrondit au-dessus de sa tête et l'hélice du sommet tourne.
static func _meteo_parapluie(f: Node) -> Dictionary:
	var corps: Node3D = f.npc
	var pn := Node3D.new()
	corps.add_child(pn)
	pn.position = Vector3(-0.24, 0.85, 0.15)
	var rouge := _mat(Color(0.86, 0.14, 0.13), 0.0, 0.5)
	rouge.cull_mode = BaseMaterial3D.CULL_DISABLED
	var alu := _mat(Color(0.85, 0.86, 0.88), 0.9, 0.3)
	_p(pn, I._cyl(0.007, 0.007, 0.92, 6), alu, Vector3(0, 0.46, 0))
	_p(pn, I._cyl(0.016, 0.014, 0.13, 8), _mat(Color(0.32, 0.2, 0.12), 0.0, 0.6), Vector3(0, 0.03, 0))
	var toile: MeshInstance3D = _p(pn, I._cyl(0.02, 0.55, 0.24, 18), rouge, Vector3(0, 0.6, 0), Vector3(0.1, 2.2, 0.1))
	var hel := Node3D.new()
	pn.add_child(hel)
	hel.position = Vector3(0, 0.95, 0)
	var jaune := _mat(Color(1.0, 0.84, 0.3), 0.0, 0.4)
	_p(hel, I._sph(0.016), alu, Vector3.ZERO)
	for sx in [-1.0, 1.0]:
		_p(hel, I._boxm(Vector3(0.11, 0.004, 0.03)), jaune, Vector3(sx * 0.06, 0, 0), Vector3.ONE, Vector3(sx * 0.35, 0, 0))
	_sans_ombre(pn)
	return {"n": pn, "toile": toile, "hel": hel}


## Le public du bulletin : un ours et un lapin en peluche sur un pouf, tournés vers le tableau noir.
static func _meteo_peluches(M, x: float, z: float) -> void:
	var R = M.R
	R.kit.cyl(R.L(x, 0, z), 0.27, 0.25, 0.36, "tissu_jaune", 20)
	R.kit.cyl(R.L(x, 0.36, z), 0.25, 0.25, 0.04, "tissu_creme", 20)
	R.kit.col_box(R.L(x, 0.2, z), Vector3(0.5, 0.4, 0.5))
	R.reserve(x, z, 0.65, 0.65)
	var n: Node3D = I._node(M, R.P(x, 0.4, z), 180.0)
	var brun := _mat(Color(0.55, 0.36, 0.2), 0.0, 0.95)
	var beige := _mat(Color(0.86, 0.72, 0.52), 0.0, 0.95)
	var blanc := _mat(Color(0.96, 0.95, 0.93), 0.0, 0.95)
	var rose := _mat(Color(0.96, 0.66, 0.74), 0.0, 0.9)
	var noir := _mat(Color(0.06, 0.06, 0.07), 0.0, 0.3)
	var o := Vector3(-0.1, 0, 0)
	_p(n, I._sph(0.085), brun, o + Vector3(0, 0.085, 0), Vector3(1.0, 1.1, 0.9))
	_p(n, I._sph(0.065), brun, o + Vector3(0, 0.22, 0))
	_p(n, I._sph(0.028), beige, o + Vector3(0, 0.205, 0.055))
	for sx in [-1.0, 1.0]:
		_p(n, I._sph(0.024), brun, o + Vector3(sx * 0.05, 0.275, 0))
		_p(n, I._sph(0.03), brun, o + Vector3(sx * 0.07, 0.03, 0.05))
		_p(n, I._sph(0.008), noir, o + Vector3(sx * 0.025, 0.235, 0.058))
	var l := Vector3(0.11, 0, 0)
	_p(n, I._sph(0.075), blanc, l + Vector3(0, 0.075, 0), Vector3(1.0, 1.1, 0.9))
	_p(n, I._sph(0.055), blanc, l + Vector3(0, 0.195, 0))
	_p(n, I._sph(0.012), rose, l + Vector3(0, 0.19, 0.054))
	for sx2 in [-1.0, 1.0]:
		_p(n, I._boxm(Vector3(0.028, 0.13, 0.014)), blanc, l + Vector3(sx2 * 0.022, 0.3, 0), Vector3.ONE, Vector3(0, 0, -sx2 * 0.15))
		_p(n, I._boxm(Vector3(0.014, 0.1, 0.004)), rose, l + Vector3(sx2 * 0.022, 0.3, 0.009), Vector3.ONE, Vector3(0, 0, -sx2 * 0.15))
		_p(n, I._sph(0.007), noir, l + Vector3(sx2 * 0.02, 0.21, 0.048))


## Les airs du vent, le jour (chaque maison en a trois à son programme) : [titre (pour choisir), annonce
## du chef, bulle au-dessus de la harpe, couleur des notes, mélodie (des degrés de 0, le plus grave, à 4,
## le plus aigu), temps entre deux notes (s), petites phrases du chef, question (pour la dame), pourquoi
## ce titre, accent (« bourrasque » : un coup de vent au début de chaque tour ; « eternuement » : le vent
## éternue à la fin), nuances (la force du vent, note après note)].
static func _harpe_airs() -> Array:
	return [
		["« La Valse des Courants d'Air »", "Mesdames et messieurs : « La Valse des Courants d'Air » ! Un, deux, trois… un, deux, trois…",
			"♪ La Valse des Courants d'Air ♪", Color(1.0, 0.86, 0.55), [0, 2, 4, 2, 3, 1], 0.95,
			["Un, deux, trois ! Un, deux, trois !", "Et on tourne, les carillons !", "Plus léger, le courant d'air ! Plus léger !"],
			"Pourquoi « La Valse des Courants d'Air » ?",
			"Trois courants d'air qui dansent : un par la baie, un par la porte, un par la cheminée. Le jour où on l'a composée, on a perdu deux chapeaux et une partition.",
			"", [1.0, 0.7, 0.7]],
		["« Le Boléro du Cumulus »", "Silence… « Le Boléro du Cumulus ». Ça commence tout doucement… et ça finit tout gonflé.",
			"♪ Le Boléro du Cumulus ♪", Color(0.82, 0.9, 1.0), [0, 0, 1, 0, 2, 1, 3, 4], 1.1,
			["Piano… piano… on ne réveille pas le cumulus.", "Crescendo ! Gonflez, gonflez !", "Plus de nuage ! Encore plus de nuage !"],
			"Pourquoi « Le Boléro du Cumulus » ?",
			"Un cumulus, ça commence par un petit flocon de vapeur et ça finit gros comme la Tour du Zénith. Le boléro aussi. Mon mari aussi, après le goûter.",
			"", [0.45, 0.55, 0.65, 0.75, 0.85, 0.95, 1.05, 1.2]],
		["« La Sonate pour Chaussettes qui Sèchent »", "Une œuvre de jeunesse : « La Sonate pour Chaussettes qui Sèchent » ! Allegro !",
			"♪ La Sonate pour Chaussettes qui Sèchent ♪", Color(1.0, 0.72, 0.8), [2, 3, 2, 1, 2, 0, 1, 2], 0.7,
			["Allegro, les chaussettes ! Allegro !", "Plus de vent dans les talons !", "La chaussette gauche est en retard. Comme toujours."],
			"Pourquoi « La Sonate pour Chaussettes qui Sèchent » ?",
			"On l'a composée un jour de lessive : les chaussettes battaient la mesure sur le fil du balcon. Il en manque une depuis. Elle est partie en tournée au Plancher.",
			"", [0.9, 0.7]],
		["« Le Concerto pour Parapluie Retourné »", "Tenez vos chapeaux : « Le Concerto pour Parapluie Retourné » ! C'est fougueux !",
			"♪ Le Concerto pour Parapluie Retourné ♪", Color(0.6, 0.88, 0.76), [4, 2, 0, 4, 3, 1], 0.62,
			["Fortissimo ! Comme un parapluie qui se retourne !", "Tenez bon, les coupelles !", "Flap ! Flap ! Et… re-flap !"],
			"Pourquoi « Le Concerto pour Parapluie Retourné » ?",
			"Monsieur Pression, notre voisin, l'a inspiré sans le vouloir : un coup de vent sur la Promenade du bord, son parapluie s'est retourné, et il a crié en si bémol. Un si bémol parfait.",
			"bourrasque", [1.3, 0.8, 0.9, 1.2, 0.8, 1.0]],
		["« La Marche des Moutons du Ciel »", "En rangs, les nuages ! « La Marche des Moutons du Ciel » ! Une, deux ! Une, deux !",
			"♪ La Marche des Moutons du Ciel ♪", Color(0.96, 0.95, 0.84), [0, 2, 0, 2, 4, 2, 3, 0], 0.75,
			["Une, deux ! Une, deux !", "Les moutons du fond, suivez !", "Pas de mouton égaré, s'il vous plaît !"],
			"Pourquoi « La Marche des Moutons du Ciel » ?",
			"Ce sont les petits nuages qui passent en troupeau au-dessus de l'Esplanade. Le Docteur Aurèle les compte et leur donne des noms. Nous, on leur a donné une marche.",
			"", [1.0, 0.75]],
		["« La Rhapsodie pour Girouette Indécise »", "« La Rhapsodie pour Girouette Indécise » ! Par ici… non, par là… non, par ici !",
			"♪ La Rhapsodie pour Girouette Indécise ♪", Color(0.8, 0.76, 1.0), [1, 3, 1, 4, 0, 3, 2], 1.0,
			["Par ici, le vent ! … Non, par là !", "Changez de direction ! … Non, revenez !", "Tournez, tournez… et hésitez !"],
			"Pourquoi « La Rhapsodie pour Girouette Indécise » ?",
			"Celle de l'Institut des Vents ne sait jamais où aller. Le Docteur Aurèle dit qu'elle réfléchit. Mon mari dit qu'elle lui ressemble. Moi, je ne dis rien.",
			"", [0.6, 1.1, 0.5, 1.2, 0.7, 1.0, 0.8]],
		["« La Petite Brise en Si Bémol pour Éternuement »", "Une pièce délicate : « La Petite Brise en Si Bémol pour Éternuement ». Le final est… surprenant.",
			"♪ La Petite Brise en Si Bémol pour Éternuement ♪", Color(1.0, 0.95, 0.62), [3, 2, 1, 0, 1, 2, 3], 1.0,
			["Doucement… tout doucement…", "Ah… ah… attendez le final…", "Ah… ah… AH…"],
			"Pourquoi « La Petite Brise en Si Bémol pour Éternuement » ?",
			"C'est la seule pièce au monde qui se termine par un éternuement. Celui du vent, d'habitude. Une fois, c'était celui du public : on a gardé cette version.",
			"eternuement", [0.6, 0.6, 0.7, 0.7, 0.8, 0.9, 1.3]],
	]


## Les airs du vent de nuit (plus doux, plus lents ; une maison n'en joue qu'un) : même forme.
static func _harpe_airs_nuit() -> Array:
	return [
		["« Le Nocturne pour Courant d'Air Timide »", "Chut… « Le Nocturne pour Courant d'Air Timide ». La nuit, le vent joue plus doucement.",
			"♪ Le Nocturne pour Courant d'Air Timide ♪", Color(0.72, 0.78, 1.0), [4, 2, 3, 1, 2, 0], 1.9,
			["Pianissimo… pianississimo…", "Il chuchote. Écoutez.", "Tout doux, mon vieux vent."],
			"Pourquoi « Le Nocturne pour Courant d'Air Timide » ?",
			"La nuit, le vent a sommeil, lui aussi. Il joue du bout des doigts, pour ne pas réveiller les nuages.",
			"", [0.8, 0.7, 0.9]],
		["« La Berceuse du Sustentateur »", "Chut… « La Berceuse du Sustentateur ». Pour les quatre gros moteurs qui nous tiennent en l'air.",
			"♪ La Berceuse du Sustentateur ♪", Color(0.78, 0.86, 1.0), [0, 1, 0, 2, 0, 1], 1.7,
			["Tout doux… tout doux…", "Ronronnez, mes gros, ronronnez…", "Pianissimo. Il ne faudrait pas qu'ils s'endorment."],
			"Pourquoi « La Berceuse du Sustentateur » ?",
			"Les quatre Sustentateurs ronronnent sous nos pieds depuis cent vingt ans. On leur a écrit une berceuse. L'Ingénieure Nova dit qu'ils ronronnent en mesure, maintenant.",
			"", [0.8, 0.7]],
	]


## Un maillage fait de primitives regroupées : un groupe par surface ([[maillage, Transform3D], …]), et
## chaque surface aura sa matière (surface_set_material, ou celle du nœud).
static func _harpe_fondre(groupes: Array) -> ArrayMesh:
	var am := ArrayMesh.new()
	for g in groupes:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for e in g:
			st.append_from(e[0], 0, e[1])
		st.commit(am)
	return am


## Un carillon à vent, en un seul maillage de deux surfaces (0 : le métal ; 1 : le bois et les
## cordelettes), qui pend sous son point d'accroche (y = 0) au bout d'une cordelette de longueur `corde`.
## Sortes 0 et 1 : des tubes d'argent en couronne autour d'un battant (cinq longs, ou quatre courts), une
## petite voile de bois en dessous ; sortes 2 et 3 : de petites coupelles enfilées sur la cordelette, une
## perle sous chacune, une plume au bout. Renvoie [maillage, profondeur sous l'accroche].
static func _harpe_carillon(sorte: int, corde: float) -> Array:
	var metal: Array = []
	var bois: Array = []
	var fil: CylinderMesh = I._cyl(0.0016, 0.0016, 1.0, 4)
	var bas: float = 0.0
	if sorte < 2:
		var n: int = 5 if sorte == 0 else 4
		var rr: float = 0.05 if sorte == 0 else 0.04
		var rt: float = 0.0085 if sorte == 0 else 0.007
		var l0: float = 0.34 if sorte == 0 else 0.26
		var dl: float = 0.04 if sorte == 0 else 0.03
		var tube: CylinderMesh = I._cyl(rt, rt, 1.0, 10)
		bois.append([fil, Transform3D(Basis.from_scale(Vector3(1.0, corde, 1.0)), Vector3(0, -corde * 0.5, 0))])
		bois.append([I._cyl(rr + 0.02, rr + 0.02, 0.012, 16), Transform3D(Basis(), Vector3(0, -corde - 0.006, 0))])
		var yt: float = -corde - 0.042
		for k in range(n):
			var a: float = TAU * k / n
			var l: float = l0 - dl * k
			var p := Vector3(cos(a) * rr, 0, sin(a) * rr)
			metal.append([tube, Transform3D(Basis.from_scale(Vector3(1.0, l, 1.0)), p + Vector3(0, yt - l * 0.5, 0))])
			bois.append([fil, Transform3D(Basis.from_scale(Vector3(0.8, 0.03, 0.8)), p + Vector3(0, yt + 0.015, 0))])
		bois.append([I._cyl(rr - rt - 0.005, rr - rt - 0.005, 0.008, 14), Transform3D(Basis(), Vector3(0, yt - 0.11, 0))])
		var ys: float = yt - l0 - 0.04
		var lc: float = (-corde - 0.012) - ys
		bois.append([fil, Transform3D(Basis.from_scale(Vector3(1.0, lc, 1.0)), Vector3(0, ys + lc * 0.5, 0))])
		bois.append([I._boxm(Vector3(0.07, 0.11, 0.005)), Transform3D(Basis(), Vector3(0, ys - 0.055, 0))])
		bas = -(ys - 0.11)
	else:
		var nc: int = 4 if sorte == 2 else 3
		var rc: float = 0.032 if sorte == 2 else 0.042
		var coupe: CylinderMesh = I._cyl(rc * 0.32, rc, rc * 0.85, 14)
		var perle: SphereMesh = I._sph(0.0075)
		var y: float = -corde
		for _k2 in range(nc):
			metal.append([coupe, Transform3D(Basis(), Vector3(0, y - rc * 0.425, 0))])
			bois.append([perle, Transform3D(Basis(), Vector3(0, y - rc * 0.85 - 0.006, 0))])
			y -= rc * 0.85 + 0.045
		bois.append([fil, Transform3D(Basis.from_scale(Vector3(1.0, -y, 1.0)), Vector3(0, y * 0.5, 0))])
		bois.append([I._sph(0.03), Transform3D(Basis.from_scale(Vector3(0.9, 2.0, 0.25)), Vector3(0, y - 0.06, 0))])
		bas = -(y - 0.12)
	return [_harpe_fondre([metal, bois]), bas]


## Un violoncelle (deux surfaces : le bois verni, puis l'ébène), debout sur sa pique (y = 0), la table
## tournée vers +Z.
static func _harpe_violoncelle() -> ArrayMesh:
	var sph: SphereMesh = I._sph(0.5)
	var bois: Array = [
		[sph, Transform3D(Basis.from_scale(Vector3(0.44, 0.42, 0.2)), Vector3(0, 0.4, 0))],
		[sph, Transform3D(Basis.from_scale(Vector3(0.36, 0.33, 0.19)), Vector3(0, 0.71, 0))],
		[I._boxm(Vector3(0.04, 0.3, 0.05)), Transform3D(Basis(), Vector3(0, 0.98, 0.06))],
		[I._boxm(Vector3(0.035, 0.13, 0.045)), Transform3D(Basis(), Vector3(0, 1.19, 0.05))],
		[I._sph(0.03), Transform3D(Basis.from_scale(Vector3(0.9, 1.1, 1.2)), Vector3(0, 1.27, 0.055))],
		[I._boxm(Vector3(0.08, 0.045, 0.008)), Transform3D(Basis(), Vector3(0, 0.47, 0.1))],
	]
	var ebene: Array = [
		[I._boxm(Vector3(0.05, 0.6, 0.012)), Transform3D(Basis(), Vector3(0, 0.9, 0.092))],
		[I._boxm(Vector3(0.055, 0.17, 0.012)), Transform3D(Basis(), Vector3(0, 0.3, 0.098))],
		[I._cyl(0.006, 0.004, 0.2, 6), Transform3D(Basis(), Vector3(0, 0.1, 0))],
	]
	for sx in [-1.0, 1.0]:
		ebene.append([I._boxm(Vector3(0.008, 0.085, 0.004)), Transform3D(Basis(Vector3.BACK, sx * 0.12), Vector3(sx * 0.075, 0.52, 0.077))])
	for k in range(4):
		bois.append([I._cyl(0.006, 0.006, 0.1, 6), Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, 1.14 + k * 0.028, 0.05))])
		ebene.append([I._boxm(Vector3(0.0025, 0.84, 0.0025)), Transform3D(Basis(), Vector3(-0.015 + k * 0.01, 0.8, 0.104))])
	return _harpe_fondre([bois, ebene])


## La harpe éolienne. Un couple de vieux musiciens : devant la baie, une harpe éolienne (un cadre de bois
## clair et ses onze cordes fines) ; sous le plafond, des dizaines de carillons à vent (des tubes d'argent,
## de petites coupelles). On ouvre la baie : le vent entre, la harpe chante (les notes montent en bulles, sur
## les cinq notes des pierres qui chantent), les carillons se balancent et tintent, et le vieux musicien
## dirige le vent comme un orchestre (trois « airs du vent » au programme de la maison, aux titres drôles,
## l'un après l'autre ; la maison se souvient du prochain) ; on referme : silence. On peut aussi effleurer
## les cordes, lire le cahier des airs du vent, et diriger soi-même le vent avec la baguette de rechange
## (la première fois : une plume du vent, restée prise dans les cordes). Une conversation avec chacun des
## deux. La nuit, ils dorment dans leurs fauteuils, ou chuchotent que le vent de nuit joue plus doucement.
static func _harpe(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var nuit: bool = _nuit(M)
	var dodo: bool = nuit and r.randf() < 0.5
	var s: float = 1.0 if r.randf() < 0.5 else -1.0
	var b: Array = _baie(M, s)
	var bz: float = float(b[1])
	var v: Dictionary = _vantail(M, b)
	var db: float = -7.0 if nuit else 0.0
	# le programme de la maison : trois airs du vent (la nuit, un seul, plus doux)
	var rep: Array = []
	if nuit:
		var an: Array = _harpe_airs_nuit()
		rep.append(an[r.randi() % an.size()])
	else:
		var tous: Array = _harpe_airs()
		for _k in range(3):
			rep.append(tous.pop_at(r.randi() % tous.size()))
	# les places (repère de la pièce) : la harpe devant la baie, le chef sur le côté (il regarde la
	# harpe… et la porte), les deux fauteuils face à la baie, le guéridon entre eux, le pupitre du chef
	var hx: float = s * (hw - 0.45)
	var hz: float = bz
	var yaw_h: float = -90.0 * s
	var cx: float = s * (hw - 1.3)
	var cz: float = bz - 1.0
	var f1x: float = s * (hw - 2.25)
	var f1z: float = bz - 0.9
	var f2x: float = s * (hw - 2.35)
	var f2z: float = bz + 0.75
	var tx: float = s * (hw - 2.6)
	var tz: float = bz - 0.08
	var px: float = s * (hw - 1.0)
	var pz: float = bz - 0.62
	var dir_h := Vector3(hx - cx, 0, hz - cz)
	var harp_top: Vector3 = R.P(hx, 1.72, hz)
	var harp_mid: Vector3 = R.P(hx, 1.0, hz)
	# la cheminée au fond, loin de la baie ; le grand tapis ; les deux fauteuils tournés vers la harpe
	_foyer(M, -s * R.W * 0.2)
	R.tapis(s * (hw - 1.85), bz - 0.05, 90, minf(2.9, R.D - 2.2), 2.3)
	var f1yaw: float = _vers(f1x, f1z, hx, hz)
	var f2yaw: float = _vers(f2x, f2z, hx, hz)
	R.fauteuil(f1x, f1z, f1yaw, str(_pick(M, ["creme", "blanc", "gris"])))
	R.fauteuil(f2x, f2z, f2yaw, str(_pick(M, ["creme", "blanc", "gris"])))
	if not nuit:
		R.kit.box(R.L(f1x, 0.51, f1z, f1yaw + 12.0), Vector3(0.24, 0.02, 0.31), "papier", 1.0)
	# le guéridon de céramique : le cahier des airs du vent (ouvert), la théière, une tasse
	R.kit.cyl(R.L(tx, 0, tz), 0.17, 0.17, 0.02, "argent", 16)
	R.kit.cyl(R.L(tx, 0.02, tz), 0.02, 0.02, 0.56, "argent", 8, false)
	R.kit.cyl(R.L(tx, 0.58, tz), 0.28, 0.28, 0.03, "ceramique", 24)
	R.kit.col_box(R.L(tx, 0.3, tz), Vector3(0.45, 0.6, 0.45))
	R.reserve(tx, tz, 0.6, 0.6)
	var nxf: Transform3D = R.L(tx, 0.61, tz, -90.0 * s) * Transform3D(Basis(), Vector3(0, 0, 0.05))
	R.kit.box(nxf * Transform3D(Basis(), Vector3(0, 0.004, 0)), Vector3(0.31, 0.008, 0.21), "nu_bleu", 1.0)
	for sx in [-1.0, 1.0]:
		var pxf: Transform3D = nxf * Transform3D(Basis(Vector3.BACK, sx * 0.07), Vector3(sx * 0.075, 0.012, 0))
		R.kit.box(pxf, Vector3(0.145, 0.006, 0.195), "papier", 1.0)
		for k4 in range(3):
			R.kit.box(pxf * Transform3D(Basis(), Vector3(0, 0.0035, -0.05 + k4 * 0.05)), Vector3(0.11, 0.001, 0.012), "nu_ardoise", 1.0, 4)
	var tpx: float = tx + 0.16 * s
	var tpz: float = tz + 0.08
	R.kit.cyl(R.L(tpx, 0.61, tpz), 0.06, 0.05, 0.1, "ceramique", 14)
	R.kit.cyl(R.L(tpx, 0.71, tpz), 0.03, 0.006, 0.025, "ceramique", 10)
	R.kit.cyl(Transform3D(Basis(Vector3.RIGHT, 0.9), R.P(tpx, 0.65, tpz + 0.045)), 0.014, 0.008, 0.09, "ceramique", 8)
	R.kit.cyl(R.L(tx + 0.15 * s, 0.61, tz - 0.13), 0.055, 0.055, 0.006, "ceramique", 14)
	R.kit.cyl(R.L(tx + 0.15 * s, 0.616, tz - 0.13), 0.03, 0.036, 0.045, "nu_bleu", 12)
	# le lampadaire, derrière le guéridon
	var lx: float = s * (hw - 3.15)
	var lz: float = bz - 0.1
	if absf(lx) <= hw - 0.5 and R.is_free(lx, lz, 0.45, 0.45):
		_lampadaire(M, lx, lz)
	# la harpe éolienne : deux pieds, deux montants, la caisse et sa rose, le sommier et ses chevilles,
	# le fronton en arc et sa rose des vents d'argent (tournée vers la pièce, la baie dans le dos)
	var hxf: Transform3D = R.L(hx, 0, hz, yaw_h)
	for sx2 in [-1.0, 1.0]:
		R.kit.box(hxf * Transform3D(Basis(), Vector3(sx2 * 0.37, 0.025, 0)), Vector3(0.07, 0.05, 0.38), "bois_clair", 1.0)
		R.kit.box(hxf * Transform3D(Basis(), Vector3(sx2 * 0.37, 0.76, 0)), Vector3(0.05, 1.42, 0.05), "bois_clair", 1.0)
		R.kit.cyl(hxf * Transform3D(Basis(), Vector3(sx2 * 0.37, 1.53, 0)), 0.03, 0.0, 0.07, "bois_clair", 10)
	R.kit.box(hxf * Transform3D(Basis(), Vector3(0, 0.36, 0)), Vector3(0.8, 0.17, 0.13), "bois_clair", 1.0)
	R.kit.cyl(hxf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.36, 0.064)), 0.046, 0.046, 0.003, "argent", 16)
	R.kit.cyl(hxf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.36, 0.066)), 0.034, 0.034, 0.003, "noir", 16)
	R.kit.box(hxf * Transform3D(Basis(), Vector3(0, 0.452, 0)), Vector3(0.66, 0.012, 0.022), "argent", 1.0)
	R.kit.box(hxf * Transform3D(Basis(), Vector3(0, 1.5, 0)), Vector3(0.82, 0.06, 0.07), "bois_clair", 1.0)
	R.kit.box(hxf * Transform3D(Basis(), Vector3(0, 1.462, 0)), Vector3(0.66, 0.012, 0.022), "argent", 1.0)
	for k5 in range(8):
		var a0: float = PI * float(k5) / 8.0
		var a1: float = PI * float(k5 + 1) / 8.0
		var p0 := Vector3(-0.37 * cos(a0), 1.53 + 0.15 * sin(a0), 0)
		var p1 := Vector3(-0.37 * cos(a1), 1.53 + 0.15 * sin(a1), 0)
		var dd: Vector3 = p1 - p0
		R.kit.box(hxf * Transform3D(Basis(Vector3.BACK, atan2(dd.y, dd.x)), (p0 + p1) * 0.5), Vector3(dd.length() + 0.012, 0.03, 0.045), "bois_clair", 1.0)
	R.kit.cyl(hxf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 1.6, 0.0)), 0.055, 0.055, 0.03, "argent", 16)
	for k6 in range(11):
		R.kit.cyl(hxf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.3 + k6 * 0.06, 1.5, 0.035)), 0.008, 0.008, 0.025, "argent", 6)
	R.kit.col_box(hxf * Transform3D(Basis(), Vector3(0, 0.8, 0)), Vector3(0.84, 1.6, 0.38))
	R.reserve(hx, hz, 0.55, 1.0)
	# ses onze cordes (elles vibrent, et luisent quand elles chantent ; la nuit, un peu, toujours)
	var cordes_n: Node3D = I._node(M, R.P(hx, 0, hz), yaw_h)
	var corde_m := _mat(Color(0.93, 0.95, 1.0), 0.8, 0.25, 0.05)
	corde_m.emission = Color(0.72, 0.86, 1.0)
	var cmesh: CylinderMesh = I._cyl(0.0024, 0.0024, 1.0, 6)
	var cordes: Array = []
	for k7 in range(11):
		var cm: MeshInstance3D = _p(cordes_n, cmesh, corde_m, Vector3(-0.3 + k7 * 0.06, 0.957, 0))
		cordes.append([cm, 34.0 + k7 * 4.0 + r.randf() * 3.0, r.randf() * TAU])
	_sans_ombre(cordes_n)
	# le pupitre du chef (tourné vers lui) : la partition du vent, la baguette de rechange sur le rebord,
	# et une page qui s'envole à moitié quand le vent souffle
	var pyaw: float = _vers(px, pz, cx, cz)
	for k8 in range(3):
		R.kit.box(R.L(px, 0.012, pz, pyaw + 120.0 * k8) * Transform3D(Basis(), Vector3(0, 0, 0.11)), Vector3(0.02, 0.02, 0.22), "argent", 1.0)
	R.kit.cyl(R.L(px, 0.0, pz), 0.012, 0.012, 1.02, "argent", 8, false)
	var dxf: Transform3D = R.L(px, 1.1, pz, pyaw) * Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-25.0)), Vector3.ZERO)
	R.kit.box(dxf, Vector3(0.48, 0.32, 0.012), "argent", 1.0)
	R.kit.box(dxf * Transform3D(Basis(), Vector3(0, -0.16, 0.022)), Vector3(0.48, 0.012, 0.04), "argent", 1.0)
	R.kit.box(dxf * Transform3D(Basis(), Vector3(0.11, 0.0, 0.009)), Vector3(0.21, 0.29, 0.003), "papier", 1.0)
	for k9 in range(4):
		R.kit.box(dxf * Transform3D(Basis(), Vector3(0.11, 0.09 - k9 * 0.06, 0.0112)), Vector3(0.17, 0.012, 0.001), "nu_ardoise", 1.0, 16)
	R.kit.cyl(dxf * Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3(-0.2, -0.15, 0.03)), 0.0045, 0.003, 0.36, "ceramique", 6)
	var desk_n := Node3D.new()
	M.room.add_child(desk_n)
	desk_n.global_transform = dxf * Transform3D(Basis(), Vector3(0, 0, 0.009))
	var feuille := Node3D.new()
	desk_n.add_child(feuille)
	_p(feuille, I._boxm(Vector3(0.21, 0.29, 0.003)), _mat(Color(0.97, 0.96, 0.92), 0.0, 0.9), Vector3(-0.105, 0, 0))
	_sans_ombre(desk_n)
	# le violoncelle de la dame, appuyé contre un mur libre (s'il y en a un)
	for c in [[-s * (hw - 0.55), -hd + 0.32, 0.0, -s * (hw - 0.55), -hd], [-s * (hw - 0.32), -hd + 0.85, 90.0 * s, -s * hw, -hd + 0.85],
			[s * (hw - 0.55), -hd + 0.32, 0.0, s * (hw - 0.55), -hd]]:
		if not R.is_free(float(c[0]), float(c[1]), 0.6, 0.55) or not R.wall_free(float(c[3]), 1.1, float(c[4]), 0.3):
			continue
		var cel := MeshInstance3D.new()
		var cel_m: ArrayMesh = _harpe_violoncelle()
		cel_m.surface_set_material(0, _mat(Color(0.66, 0.34, 0.14), 0.0, 0.32))
		cel_m.surface_set_material(1, _mat(Color(0.07, 0.06, 0.06), 0.0, 0.45))
		cel.mesh = cel_m
		M.room.add_child(cel)
		cel.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(float(c[2]))) * Basis(Vector3.RIGHT, deg_to_rad(-11.0)), R.P(float(c[0]), 0.0, float(c[1])))
		R.kit.col_box(R.L(float(c[0]), 0.6, float(c[1]), float(c[2])), Vector3(0.45, 1.2, 0.3))
		R.reserve(float(c[0]), float(c[1]), 0.6, 0.55)
		R.mark_wall(float(c[3]), 1.1, float(c[4]), 0.35)
		break
	# des plantes de part et d'autre de la baie, et une près de la porte
	for e in [[s * (hw - 0.38), bz - 1.32], [s * (hw - 0.38), bz + 1.32], [-s * (hw - 0.45), hd - 1.75]]:
		var ex: float = float(e[0])
		var ez: float = float(e[1])
		if ez < -hd + 0.4 or ez > hd - 1.6 or not R.is_free(ex, ez, 0.45, 0.45):
			continue
		_pot(M, ex, ez, 0.0, 1.0, str(_pick(M, ["", "nu_rose", "nu_lavande", "nu_jaune"])))
	_cadres(M, 2)
	# les carillons à vent : douze modèles (quatre sortes, trois longueurs de cordelette), accrochés en
	# quinconce sous tout le plafond, sauf autour du plafonnier ; le plus bas reste au-dessus de 2 m
	var argent_m := _mat(Color(0.88, 0.9, 0.94), 0.95, 0.2)
	var laiton_m := _mat(Color(0.94, 0.84, 0.58), 0.9, 0.3)
	var bois_m := _mat(Color(0.9, 0.83, 0.7), 0.0, 0.75)
	var variantes: Array = []
	for sorte in range(4):
		for cl in [0.2, 0.32, 0.44]:
			var cr: Array = _harpe_carillon(sorte, float(cl))
			var am: ArrayMesh = cr[0]
			am.surface_set_material(0, argent_m if sorte < 2 else laiton_m)
			am.surface_set_material(1, bois_m)
			variantes.append([am, float(cr[1]), float(cl)])
	var carillons: Array = []
	var gx: int = maxi(2, int((R.W - 1.0) / 0.8) + 1)
	var gz: int = maxi(2, int((R.D - 1.0) / 0.8) + 1)
	var garder: float = minf(0.85, 38.0 / float(gx * gz))
	for i in range(gx):
		for j in range(gz):
			if r.randf() > garder:
				continue
			var x: float = -hw + 0.5 + (R.W - 1.0) * float(i) / float(gx - 1) + r.randf_range(-0.12, 0.12)
			var z: float = -hd + 0.5 + (R.D - 1.0) * float(j) / float(gz - 1) + r.randf_range(-0.12, 0.12)
			if Vector2(x, z).length() < 0.8:
				continue
			var va: Array = variantes[r.randi() % variantes.size()]
			R.kit.cyl(R.L(x, R.H - 0.014, z), 0.022, 0.022, 0.014, "argent", 8)
			var piv: Node3D = I._node(M, R.P(x, R.H, z), r.randf() * 360.0)
			var mi := MeshInstance3D.new()
			mi.mesh = va[0]
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			piv.add_child(mi)
			var dist: float = Vector2(x - s * hw, z - bz).length()
			carillons.append([piv, sqrt(9.8 / (float(va[2]) + 0.3)) * r.randf_range(0.88, 1.12), r.randf() * TAU, r.randf() * TAU,
				piv.rotation.y, clampf(1.25 - dist / 5.5, 0.3, 1.0), dist / 2.4, float(va[1])])
	# l'air du dehors qui entre par la baie ouverte
	var bay_mid: Vector3 = _dans_baie(v, Vector3(0.44, 0.0, 0.25))
	var souffle: CPUParticles3D = _souffle(M, _dans_baie(v, Vector3(0.44, 0.0, 0.12)), Vector3(-s, 0.05, 0).normalized())
	if nuit:
		souffle.amount = 18
		souffle.initial_velocity_min = 0.6
		souffle.initial_velocity_max = 1.2
	# les gens : le jour, le vieux chef debout près de la harpe (sa baguette à la main), la dame tricote
	# dans son fauteuil ; la nuit, tous deux dans leurs fauteuils (endormis, ou qui chuchotent)
	var lv_attente: Array = ["Le soliste est en retard. Comme toujours.", "Quelqu'un ouvre la baie ? Le vent attend son entrée.",
		"Un peu de silence avant la musique… Voilà. C'est fait.", "J'ai dirigé la tempête de l'an quarante. Elle m'a obéi. Presque."]
	var lv_tricot: Array = ["Une maille à l'endroit, une maille pour le vent…", "Je tricote une chaussette à air. Pour que le vent n'ait pas froid aux pieds.",
		"Quarante-trois carillons, et pas deux qui chantent pareil.", "Ferme ta veste, mon chéri. Il va y avoir du courant d'air."]
	var lv_concert: Array = ["Bravo, le vent !", "Tu entends, mon chéri ? Il a changé une note.", "Il joue mieux que toi, ce vent. Mais tu diriges mieux que lui."]
	var lv_nuit: Array = ["Chut… le vent de nuit joue plus doucement.", "Écoute : il chuchote.", "La nuit, même le vent a sommeil."]
	var vieux: Node
	var vieille: Node
	if nuit:
		vieux = M.person("vieux", f1x, f1z, f1yaw, "dormir_assis" if dodo else "assis")
		vieille = M.person("vieille", f2x, f2z, f2yaw, "dormir_assis" if dodo else "assis")
		if dodo:
			vieux.lines = ["Zzz…", "Zzz… pianissimo… zzz…", "Zzz… plus doux, les carillons… zzz…"]
			vieille.lines = ["Zzz…", "Zzz… une maille pour le vent… zzz…"]
		else:
			vieux.lines = lv_nuit
			vieille.lines = ["Il ne faut pas réveiller les nuages.", "La nuit, même les carillons parlent tout bas.", "Tu entends, mon chéri ? Le vent rêve."]
		vieux.line_every = Vector2(10.0, 15.0)
		vieille.line_every = Vector2(10.0, 15.0)
	else:
		vieux = M.person("vieux", cx, cz, _vers(cx, cz, hx, hz), "mains_dos")
		vieux.lines = lv_attente
		vieux.line_every = Vector2(7.0, 12.0)
		vieille = M.person("vieille", f2x, f2z, f2yaw, "tricot")
		vieille.lines = lv_tricot
		vieille.line_every = Vector2(8.0, 13.0)
		# sa baguette de chef, dans la main droite
		var bag := Node3D.new()
		_p(bag, I._cyl(0.0025, 0.0045, 0.36, 6), _mat(Color(0.97, 0.97, 0.95), 0.0, 0.4), Vector3(0, 0.17, 0))
		_p(bag, I._cyl(0.011, 0.011, 0.07, 8), _mat(Color(0.72, 0.58, 0.4), 0.0, 0.7), Vector3.ZERO)
		var corps: Node = vieux.npc
		if corps.has_method("_attach"):
			corps.call("_attach", "RightHand", Vector3(0, -8, 3), bag, Vector3(90, 0, 0))
		if bag.get_parent() == null:
			bag.free()
	var st := {"t": r.randf() * 10.0, "vent": 0.0, "cible": 0.0, "force": 1.0, "air": int(M.state().get("nu_harpe_air", 0)) % rep.size(),
		"beat": 0, "next": 1.0, "tinte": 0.4, "carillon": 2.0, "souffle": 0.0, "gliss": -1.0, "dirige": 0.0, "phase": "", "page": r.randi() % 5}
	# un nouvel air : le chef l'annonce, son titre monte au-dessus de la harpe (la maison retient le suivant)
	var annoncer := func() -> void:
		var a: Array = rep[int(st["air"]) % rep.size()]
		st["beat"] = 0
		st["next"] = 1.3
		if not nuit:
			M.state()["nu_harpe_air"] = (int(st["air"]) + 1) % rep.size()
		_bulle(M, harp_top + Vector3(0, 0.4, 0), str(a[2]), a[3], 34 if nuit else 40, 0.5, 2.6)
		if dodo:
			return
		vieux.say(str(a[1]), 4.5)
		vieux.lines = a[6]
		vieux.line_every = Vector2(5.0, 8.0) if nuit else Vector2(4.5, 7.5)
	# ouvrir la baie : le vent entre (moins fort la nuit), la harpe s'éveille, le chef lève sa baguette
	var ouvrir := func() -> void:
		if bool(v["ouvert"]):
			return
		_coulisser(M, v, true)
		st["cible"] = 0.45 if nuit else 1.0
		st["souffle"] = 0.5
		souffle.emitting = true
		M.main.sfx("bourrasque", bay_mid, db - 2.0)
		M.main.sfx("cristal_chante", harp_top, db)
		annoncer.call()
		if nuit:
			M.say("Un petit vent de nuit se glisse par la baie. La harpe chante tout bas, et les carillons tintent à peine, pour ne réveiller personne.", 5.0)
			if dodo:
				vieux.say("Zzz… pianissimo… zzz…", 3.5)
			else:
				S._say_late(M, vieille, str(_pick(M, ["Écoute… il chuchote.", "Tout doucement, le vent…", "Le vent de nuit joue du bout des doigts."])), 2.6)
			return
		M.say(str(_pick(M, ["Le vent entre dans le salon. Les cordes de la harpe se mettent à chanter toutes seules, et des dizaines de carillons tintent au-dessus de ta tête.",
			"Fwooosh ! Le vent s'engouffre par la baie : la harpe chante, les carillons se balancent et tintent, et le vieux musicien lève sa baguette."])), 5.0)
		vieux.set_pose("enseigner", dir_h)
		vieille.lines = lv_concert
		S._say_late(M, vieille, str(_pick(M, ["Ferme ta veste, mon chéri !", "Ah ! Le voilà, notre soliste !", "Écoutez… elle se réveille."])), 2.2)
	# refermer : silence ; le chef salue, la dame est ravie ; la prochaine fois, l'air suivant
	var fermer := func() -> void:
		if not bool(v["ouvert"]):
			return
		_coulisser(M, v, false)
		st["cible"] = 0.0
		st["dirige"] = 0.0
		st["phase"] = ""
		souffle.emitting = false
		if not nuit:
			st["air"] = (int(st["air"]) + 1) % rep.size()
		M.say("Tu refermes tout doucement. Les carillons frémissent encore un peu… puis plus rien. Silence." if nuit else str(_pick(M, ["Tu refermes la baie. Les carillons se balancent encore un peu… puis plus rien. Silence.",
			"La baie se referme. La harpe se tait, les carillons s'immobilisent un à un. Silence."])), 4.0)
		if nuit:
			if not dodo:
				vieux.lines = lv_nuit
				vieux.say(str(_pick(M, ["Chut… le vent s'est endormi.", "Merci, vieux vent. Bonne nuit."])), 3.0)
			return
		vieux.set_pose("mains_dos", dir_h)
		vieux.gesture("salut", 2.0)
		vieux.lines = lv_attente
		vieux.line_every = Vector2(7.0, 12.0)
		vieux.say(str(_pick(M, ["Et… silence.", "Le vent salue. Merci, merci !", "Fin du concert. Le vent remballe ses notes."])), 3.0)
		vieille.lines = lv_tricot
		vieille.gesture("rire", 1.6)
		S._say_late(M, vieille, str(_pick(M, ["Bravo, le vent ! Bravo, mon chéri !", "Magnifique. Il a encore changé une note.", "Bravo ! Et maintenant, un thé : j'ai froid aux oreilles."])), 1.2)
	# effleurer les cordes (baie fermée) : elles frémissent l'une après l'autre
	var effleurer := func() -> void:
		st["gliss"] = 0.0
		M.main.sfx("luth", harp_mid, db)
		var a: Array = rep[int(st["air"]) % rep.size()]
		for k in range(3):
			_bulle(M, harp_top + Vector3(0, 0.08 * k, (float(k) - 1.0) * 0.22), "♪", a[3], 34, 0.45 + 0.15 * k, 1.5 + 0.2 * k)
		M.say(str(_pick(M, ["Tu effleures les cordes du bout des doigts. Elles frémissent l'une après l'autre : plinnng…",
			"Tes doigts glissent sur les cordes fines. La harpe répond, tout bas, comme si elle se réveillait."])), 4.0)
		if nuit:
			if dodo:
				S._say_late(M, vieille, "Zzz… qui joue ?… zzz…", 1.2)
			else:
				S._say_late(M, vieux, "Chut… même la harpe dort.", 1.0)
			return
		match randi() % 3:
			0:
				S._say_late(M, vieille, "Doucement… elle préfère le vent. Mais elle vous a répondu, on dirait !", 1.0)
			1:
				S._say_late(M, vieux, "Pas mal ! Mais elle ne chante vraiment qu'avec le vent. Ouvrez donc la baie !", 1.0)
			_:
				S._say_late(M, vieille, "Pling ! Elle est chatouilleuse.", 1.0)
	# diriger soi-même (baie ouverte) : pianissimo, crescendo, fortissimo… et stop (la nuit, sans forcer)
	var diriger := func() -> void:
		if float(st["dirige"]) > 0.0 or not bool(v["ouvert"]):
			return
		st["dirige"] = 7.0
		st["phase"] = ""
		M.say("Tu lèves la baguette, tout doucement. Le vent de nuit retient son souffle…" if nuit else "Tu prends la baguette de rechange sur le pupitre et tu la lèves bien haut. Le vent retient son souffle…", 4.0)
		if not nuit:
			vieux.say(str(_pick(M, ["À vous, maestro !", "Le pupitre est à vous ! Levez bien le coude !", "Chut, tout le monde : nouveau chef !"])), 3.0)
	# la plume du vent quitte les cordes et vient se poser dans ta main
	var plume_vole := func() -> void:
		var pl: Node3D = I._node(M, harp_top, 0.0)
		_p(pl, I._sph(0.06), _mat(Color(0.95, 0.97, 1.0), 0.0, 0.6, 0.3), Vector3.ZERO, Vector3(0.22, 0.05, 1.0))
		_sans_ombre(pl)
		var to: Vector3 = M.main._player_pos_v27() + Vector3(0, 1.25, 0)
		var tw: Tween = M.room.create_tween()
		tw.set_parallel(true)
		tw.tween_property(pl, "global_position", to, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(pl, "rotation", Vector3(0.6, 4.0, 0.4), 1.8)
		tw.chain().tween_callback(pl.queue_free)
	# la fin du tour de chef : bravo ; la première fois, la plume du vent (une seule fois par maison)
	var fin_diriger := func() -> void:
		if not bool(v["ouvert"]):
			return
		if bool(M.state().get("nu_harpe", false)):
			if nuit:
				if dodo:
					vieux.say("Zzz… bravo… zzz…", 3.0)
				else:
					vieille.say("Bravo… tout bas, tout bas.", 3.0)
				return
			vieux.gesture("applaudir", 2.0)
			vieux.say(str(_pick(M, ["Bravo ! Le vent vous connaît, maintenant.", "Encore un triomphe ! Le vent en redemande.", "Pas mal du tout ! Un peu trop de fortissimo, mais c'est de votre âge."])), 3.5)
			return
		M.state()["nu_harpe"] = true
		plume_vole.call()
		if nuit and dodo:
			M.talk(vieux, "Zzz… bravo… maestro… zzz… La plume… dans les cordes… elle est pour vous… zzz…", I._bye("(La prendre tout doucement)"), func(_i):
				M.give([["plume_vent", 1]], "")
				M.close_talk(), "endormi")
			return
		if nuit:
			M.talk(vieille, "Bravo… tout bas. Le vent de nuit vous a écouté, et il n'écoute presque personne. Tenez : une plume du vent, restée dans les cordes. Elle porte bonheur aux chefs d'orchestre.", I._bye("Merci… bonne nuit."), func(_i):
				M.give([["plume_vent", 1]], "")
				M.close_talk(), "à voix basse")
			return
		vieux.gesture("applaudir", 2.0)
		M.talk(vieux, "Bravo ! Bravo ! Le vent vous a obéi, et il n'obéit à personne. Même pas à moi, le mardi. Tenez : une plume du vent, elle s'était prise dans les cordes. Les chefs d'orchestre de la Cité en portent une à la boutonnière.", I._bye("Merci, maestro !"), func(_i):
			M.give([["plume_vent", 1]], "")
			M.close_talk(), "ému")
	# ce qui bouge : le vent (qui obéit au chef… ou à toi), les cordes, les carillons, la page du pupitre,
	# les notes de la harpe (les cinq notes des pierres qui chantent), les tintements, le souffle du dehors
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(cordes_n):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var chef: float = 1.0
		var dg: float = float(st["dirige"])
		if dg > 0.0:
			dg = maxf(0.0, dg - dt)
			st["dirige"] = dg
			var el: float = 7.0 - dg
			var ph: String = "piano"
			if el >= 6.0:
				ph = "fin"
			elif el >= 4.4:
				ph = "forte"
			elif el >= 1.8:
				ph = "crescendo"
			match ph:
				"piano":
					chef = 0.3
				"crescendo":
					chef = lerpf(0.3, 1.25 if nuit else 1.8, (el - 1.8) / 2.6)
				"forte":
					chef = 1.3 if nuit else 1.9
			if ph != str(st["phase"]):
				st["phase"] = ph
				var tete: Vector3 = M.main._player_pos_v27() + Vector3(0, 2.05, 0)
				match ph:
					"piano":
						_bulle(M, tete, "Pianissimo…", Color(0.8, 0.88, 1.0), 40, 0.4, 1.8)
					"crescendo":
						_bulle(M, tete, "Un tout petit peu plus…" if nuit else "Crescendo…", Color(0.9, 0.92, 1.0), 42, 0.45, 2.0)
					"forte":
						_bulle(M, tete, "Mezzo forte… pas plus !" if nuit else "FORTISSIMO !", Color(1.0, 0.86, 0.5), 42 if nuit else 50, 0.55, 2.0)
						M.main.sfx("bourrasque", bay_mid, db)
						M.main.sfx("carillon", R.P(s * hw * 0.4, R.H - 0.6, bz), db)
						if not nuit:
							M.main.sfx("carillon", R.P(-s * hw * 0.4, R.H - 0.6, 0.0), db)
							vieux.say(str(_pick(M, ["Oh là là ! Tout l'orchestre !", "Ça, c'est du vent !", "Bravo ! Euh… doucement !"])), 2.5)
							S._say_late(M, vieille, "Mes coupelles ! Doucement !", 0.8)
					"fin":
						_bulle(M, tete, "Et… chut." if nuit else "Et… stop !", Color(1.0, 0.95, 0.85), 42, 0.4, 1.8)
			if dg <= 0.0:
				st["phase"] = ""
				fin_diriger.call()
		# le vent monte, retombe ; l'air du moment lui donne ses nuances
		var cible: float = float(st["cible"]) * chef
		var vent: float = float(st["vent"])
		vent = move_toward(vent, cible, dt * (0.6 if cible > vent else 0.45))
		st["vent"] = vent
		var a: Array = rep[int(st["air"]) % rep.size()]
		var notes: Array = a[4]
		var nuances: Array = a[10]
		var b0: int = int(st["beat"])
		var force: float = lerpf(float(st["force"]), float(nuances[b0 % nuances.size()]), clampf(dt * 2.5, 0.0, 1.0))
		st["force"] = force
		var sv: float = clampf(vent * force, 0.0, 1.8)
		# les cordes : elles vibrent (et se brouillent) avec le vent, ou d'une corde à l'autre sous tes doigts
		var gl_t: float = float(st["gliss"])
		if gl_t >= 0.0:
			gl_t += dt
			st["gliss"] = gl_t if gl_t < 3.0 else -1.0
		var gl_max: float = 0.0
		for i in range(cordes.size()):
			var e: Array = cordes[i]
			var gi: float = 0.0
			if gl_t >= 0.0 and gl_t - 0.045 * i >= 0.0:
				gi = exp(-(gl_t - 0.045 * i) * 2.4)
			gl_max = maxf(gl_max, gi)
			var cn: Node3D = e[0]
			cn.position.z = (0.0005 + 0.003 * sv + 0.004 * gi) * sin(t * float(e[1]) + float(e[2]))
			var bl: float = 1.0 + 1.4 * sv + 1.4 * gi
			cn.scale = Vector3(bl, 1.0, bl)
		corde_m.emission_energy_multiplier = (0.25 if nuit else 0.05) + 1.5 * maxf(sv, gl_max) * (0.8 + 0.2 * sin(t * 5.0))
		# les carillons : penchés par le vent, ils se balancent ; la rafale arrive d'abord près de la baie
		for e2 in carillons:
			var n: Node3D = e2[0]
			var tau: float = t - float(e2[6])
			var wl: float = minf(1.4, vent * force * float(e2[5]) * (0.78 + 0.22 * sin(tau * 1.9) * sin(tau * 0.61 + 0.7)))
			var w: float = float(e2[1])
			var osc: float = (0.006 + 0.2 * wl) * sin(t * w + float(e2[2]))
			var osc2: float = (0.004 + 0.11 * wl) * sin(t * w * 1.23 + float(e2[3]))
			n.rotation = Vector3(osc2, float(e2[4]) + 0.35 * wl * sin(t * 0.8 + float(e2[2])), -s * 0.16 * wl + osc)
		feuille.rotation.y = minf(1.3, 0.03 + 0.9 * sv * (0.55 + 0.45 * sin(t * 6.3)))
		# baie fermée : plus une note, plus un tintement (les carillons finissent de se balancer en silence)
		if vent < 0.15 or not bool(v["ouvert"]):
			return
		# la harpe chante : une note par temps, sa bulle monte (et les accents de l'air)
		st["next"] = float(st["next"]) - dt * clampf(chef, 0.6, 2.2)
		if float(st["next"]) <= 0.0:
			var ci: int = [0, 1, 3, 4, 2][clampi(int(notes[b0 % notes.size()]), 0, 4)]
			M.main.sfx("chant_%d" % ci, harp_top, db - 3.0)
			var sym: String = str(["♪", "♫"][randi() % 2]) if nuit else str(["♪", "♫", "♪ ♫", "♬"][randi() % 4])
			_bulle(M, harp_top + Vector3(randf_range(-0.05, 0.05), 0, randf_range(-0.3, 0.3)), sym, a[3], 32 if nuit else 40, 0.6, 1.9)
			var pos_c: int = b0 % notes.size()
			if str(a[9]) == "bourrasque" and pos_c == 0:
				M.main.sfx("bourrasque", bay_mid, db - 2.0)
				_bulle(M, bay_mid + Vector3(0, 0.6, 0), "Flap !", Color(0.85, 0.95, 1.0), 38, 0.4, 1.4)
			elif str(a[9]) == "eternuement" and pos_c == notes.size() - 1:
				M.main.sfx("eternuement", harp_top, db)
				_bulle(M, harp_top + Vector3(0, 0.35, 0), "Atchoum !", Color(1.0, 0.95, 0.7), 46, 0.5, 1.8)
				if not nuit and dg <= 0.0:
					S._say_late(M, vieille, "À vos souhaits, le vent !", 0.7)
			st["beat"] = b0 + 1
			st["next"] = float(a[5]) * randf_range(0.92, 1.08)
			# deux tours de l'air, et le chef passe au suivant du programme
			if not nuit and dg <= 0.0 and rep.size() > 1 and b0 + 1 >= notes.size() * 2:
				st["air"] = (int(st["air"]) + 1) % rep.size()
				annoncer.call()
		# les carillons tintent (plus souvent quand ça souffle fort), et de temps en temps tous ensemble
		if not carillons.is_empty():
			st["tinte"] = float(st["tinte"]) - dt * clampf(vent * force * 1.4, 0.0, 2.5)
			if float(st["tinte"]) <= 0.0:
				st["tinte"] = randf_range(0.5, 1.1)
				var ch: Array = carillons[randi() % carillons.size()]
				var cp: Vector3 = (ch[0] as Node3D).global_position + Vector3(0, -float(ch[7]) * 0.7, 0)
				M.main.sfx("clochette", cp, db - 2.0)
				if randf() < 0.35:
					_bulle(M, cp, str(["Ting !", "Tiling…", "Ding !", "Gling !"][randi() % 4]), Color(0.92, 0.95, 1.0), 30, 0.35, 1.3)
		st["carillon"] = float(st["carillon"]) - dt * clampf(vent * force, 0.0, 2.0)
		if float(st["carillon"]) <= 0.0:
			st["carillon"] = randf_range(5.5, 8.0)
			M.main.sfx("carillon", R.P(-s * hw * 0.3, R.H - 0.5, bz), db)
		# le souffle du dehors, tant que la baie est ouverte
		st["souffle"] = float(st["souffle"]) - dt
		if bool(v["ouvert"]) and float(st["souffle"]) <= 0.0:
			st["souffle"] = 5.6
			M.main.sfx("deltaplane_vent", bay_mid, db - 6.0)
	# ce qu'on fait : ouvrir et refermer la baie, effleurer les cordes ou diriger le vent, lire le cahier
	var a_baie: Vector3 = R.P(s * (hw - 1.0), 0, bz + 0.62)
	M.act(a_baie, "E : ouvrir la baie vitrée", ouvrir, 1.0, func(): return not bool(v["ouvert"]))
	M.act(a_baie, "E : refermer la baie vitrée", fermer, 1.0, func(): return bool(v["ouvert"]))
	var a_harpe: Vector3 = R.P(s * (hw - 1.05), 0, bz - 0.05)
	M.act(a_harpe, "E : effleurer les cordes de la harpe", effleurer, 0.8, func(): return not bool(v["ouvert"]))
	M.act(a_harpe, "E : diriger le vent avec la baguette", diriger, 0.8, func(): return bool(v["ouvert"]) and float(st["dirige"]) <= 0.0)
	var pages: Array = [
		"Le cahier des airs du vent, d'une écriture fine et penchée : « Lundi, vent d'ouest : la Valse. Mardi, vent du nord : la Valse, mais en grelottant. Mercredi, pas de vent : on a joué nous-mêmes. C'était moins bien. »",
		"« Note pour plus tard : ne jamais ouvrir la baie quand passe la Libellule. La Capitaine Zéphyrine a cru que le concert était pour elle. Elle a fait trois tours d'honneur. »",
		"« Aujourd'hui, le vent a improvisé un solo de vingt minutes. Mon mari l'a dirigé jusqu'au bout. Le vent s'est arrêté avant lui. »",
		"« Carillons accordés : quarante-trois. Carillons désaccordés : quarante-trois. Le vent les désaccorde exprès. C'est son humour. »",
		"« Applaudissements de l'année : deux cent douze. Dont deux cent onze de ma femme, et un de Monsieur Pression, par erreur : il chassait une mouche. »",
	]
	var lire := func() -> void:
		var k: int = int(st["page"])
		st["page"] = k + 1
		M.say(str(pages[k % pages.size()]), 9.0)
	M.act(R.P(tx, 0, tz), "E : lire le cahier des airs du vent", lire, 0.9)
	# parler au vieux chef : la harpe, le programme (on choisit l'air), diriger soi-même
	var programme := func() -> void:
		var ch2: Array = []
		for k in range(rep.size()):
			ch2.append({"id": "air_%d" % k, "label": str(rep[k][0])})
		ch2.append({"id": "hasard", "label": "Laisser le vent choisir"})
		M.talk(vieux, "Au programme aujourd'hui, trois airs du vent. Choisissez, je dirige !", ch2, func(id):
			var sid: String = str(id)
			st["air"] = int(sid.substr(4)) if sid.begins_with("air_") else randi() % rep.size()
			if bool(v["ouvert"]):
				M.close_talk()
				annoncer.call()
				return
			M.talk(vieux, "Excellent choix ! Ouvrez la baie, et je lève la baguette.", I._bye("C'est parti !"), I._close(M), "enthousiaste")
		, "enthousiaste")
	var vieux_cb := func() -> void:
		if dodo:
			M.talk(vieux, "Zzz… pianissimo… les carillons… plus doux… zzz…", I._bye("(Le laisser dormir)"), I._close(M), "endormi")
			return
		if nuit:
			M.talk(vieux, "Chut… La nuit, le vent joue plus doucement. Il ne veut pas réveiller les nuages. Si vous ouvrez la baie, ce sera… pianissimo.",
				[{"id": "pourquoi", "label": "Pourquoi plus doucement ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if id == "pourquoi":
					M.talk(vieux, "Le vent de nuit a sommeil, lui aussi : il joue du bout des doigts. Et s'il joue trop fort, les Sustentateurs se réveillent et ronronnent faux.", I._bye("Chut… bonne nuit."), I._close(M), "à voix basse")
				else:
					M.close_talk()
			, "à voix basse")
			return
		M.talk(vieux, str(_pick(M, ["Ah ! Un public ! Entrez, entrez : le vent est d'humeur musicale aujourd'hui. Il n'attend que son chef. C'est moi.",
			"Bon vent ! Et je dis ça au sens propre : ici, c'est le vent qui joue. Moi, je dirige.",
			"Chut… Vous entendez ? Rien. Normal : la baie est fermée, et le soliste attend dehors."])),
			[{"id": "harpe", "label": "Le vent joue de la musique ?"}, {"id": "air", "label": "Qu'est-ce qu'on joue ?"},
			{"id": "diriger", "label": "Je peux diriger, moi aussi ?"}, {"id": "fermer", "label": "Bon vent !"}], func(id):
			match id:
				"harpe":
					M.talk(vieux, "Une harpe éolienne ! Des cordes tendues sur un cadre de bois : on ne les pince pas, on ouvre la baie, et le vent joue dedans. Il lui faut juste un chef, sinon il fait n'importe quoi. Comme un ténor.", I._bye("Ha ha !"), I._close(M), "enthousiaste")
				"air":
					programme.call()
				"diriger":
					if bool(M.state().get("nu_harpe", false)):
						M.talk(vieux, "Encore ? Le vent commence à vous connaître. Quand vous entrez, il fait « hou-hou » sous la porte.", I._bye("Hou-hou !"), I._close(M), "enthousiaste")
					else:
						M.talk(vieux, "Bien sûr ! Ouvrez la baie, mettez-vous devant la harpe, et prenez la baguette de rechange sur le pupitre. Le vent vous écoutera… peut-être.", I._bye("J'y vais !"), I._close(M), "enthousiaste")
				_:
					M.close_talk()
		, "enthousiaste")
	M.talk_spot(vieux, vieux_cb)
	# parler à la dame : la harpe, les carillons, le titre de l'air du moment
	var vieille_cb := func() -> void:
		if dodo:
			M.talk(vieille, "Zzz… une maille à l'endroit… une maille pour le vent… zzz…", I._bye("(La laisser dormir)"), I._close(M), "endormie")
			return
		if nuit:
			M.talk(vieille, "Chut… Vous entendez ? La nuit, le vent joue plus doucement. Même les carillons parlent tout bas.",
				[{"id": "compose", "label": "Et que fait le vent, la nuit ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if id == "compose":
					M.talk(vieille, "Il compose. Le jour, il joue nos airs ; la nuit, il invente les siens. Je les note au réveil… quand je m'en souviens.", I._bye("Bonne nuit…"), I._close(M), "à voix basse")
				else:
					M.close_talk()
			, "à voix basse")
			return
		var a3: Array = rep[int(st["air"]) % rep.size()]
		M.talk(vieille, str(_pick(M, ["Bonjour ! Ne faites pas attention à mon mari, il se prend pour un chef d'orchestre. Remarquez, c'est le meilleur chef de vent de toute la Cité.",
			"Bon vent ! Vous venez écouter la harpe ? Elle ne joue que si on lui ouvre la baie. Comme un chat qui veut sortir."])),
			[{"id": "harpe", "label": "Qui a fabriqué la harpe ?"}, {"id": "carillons", "label": "Et tous ces carillons ?"},
			{"id": "titre", "label": str(a3[7])}, {"id": "fermer", "label": "Au revoir !"}], func(id):
			match id:
				"harpe":
					M.talk(vieille, "Nous deux, pour notre mariage, il y a quarante-trois ans ! Le cadre vient d'une vieille aile de planeur, tombée un jour sur notre balcon. Les cordes, ce sont des ficelles de cerfs-volants de la Fête des Vents : elles ont gardé le goût du ciel.", I._bye("C'est magnifique."), I._close(M), "malicieuse")
				"carillons":
					M.talk(vieille, "Un par anniversaire de mariage : quarante-trois ! Les tubes d'argent, c'est lui ; les petites coupelles, c'est moi. Lui dit que c'est un orchestre, moi, que c'est beaucoup de poussière.", I._bye("Ha ha !"), I._close(M), "malicieuse")
				"titre":
					M.talk(vieille, str(a3[8]), I._bye("Ha ha !"), I._close(M), "malicieuse")
				_:
					M.close_talk()
		, "malicieuse")
	M.talk_spot(vieille, vieille_cb)
	if dodo:
		M.ctx["entree"] = str(_pick(M, ["Il fait nuit. Deux vieux musiciens dorment dans leurs fauteuils, face à la baie. Au-dessus d'eux, des dizaines de carillons attendent le vent, sans un bruit.",
			"Chut… Le salon dort. Devant la baie, les cordes d'une harpe luisent doucement, et deux vieux musiciens ronflent en mesure.",
			"Tout est calme. Pas un tintement : les carillons dorment, la harpe aussi. Dans leurs fauteuils, un vieux couple rêve de musique."]))
	elif nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Deux vieux musiciens veillent dans leurs fauteuils, face à la baie. « La nuit, chuchote la dame, le vent joue plus doucement. »",
			"Il fait nuit, mais on ne dort pas encore. Sous des dizaines de carillons immobiles, un vieux couple écoute le silence. « Ouvrez tout doucement… »",
			"Une harpe devant la baie, des carillons au plafond, et deux vieux musiciens qui chuchotent dans la pénombre : « Le vent de nuit joue du bout des doigts. »"]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Des dizaines de carillons pendent du plafond, immobiles : des tubes d'argent, de petites coupelles. Devant la baie, une harpe de bois clair attend le vent. Un vieux monsieur aussi, sa baguette à la main.",
			"Chut… Rien ne bouge : ni les carillons d'argent sous le plafond, ni les cordes fines de la harpe, devant la baie. « Ouvrez donc, sourit une vieille dame. Notre musicien attend dehors. »",
			"Un salon de musiciens : un pupitre, deux fauteuils tournés vers la baie… et des carillons à vent par dizaines, suspendus au plafond. Devant la baie, une harpe éolienne attend son soliste : le vent."]))


# =================================================================== la chambre aux papillons

## Les couleurs des papillons : [la couleur des ailes, celle du bout des ailes de devant] (le bleu,
## l'orange, le citron, le rose, le blanc, le vert, le violet, le rouge).
static func _papillons_couleurs() -> Array:
	return [
		[Color(0.25, 0.55, 1.0), Color(0.04, 0.08, 0.24)],
		[Color(1.0, 0.56, 0.12), Color(0.08, 0.06, 0.05)],
		[Color(1.0, 0.9, 0.28), Color(0.95, 0.58, 0.12)],
		[Color(0.98, 0.58, 0.78), Color(0.6, 0.2, 0.48)],
		[Color(0.97, 0.97, 0.94), Color(0.32, 0.32, 0.34)],
		[Color(0.5, 0.88, 0.55), Color(0.08, 0.35, 0.18)],
		[Color(0.7, 0.52, 0.98), Color(0.28, 0.12, 0.5)],
		[Color(0.92, 0.2, 0.16), Color(0.1, 0.07, 0.07)],
	]


## Un triangle à plat (sa normale calculée), pour les petits maillages des papillons.
static func _papillons_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	n = n.normalized() if n.length() > 0.0000001 else Vector3.UP
	for v in [a, b, c]:
		st.set_normal(n)
		st.add_vertex(v)


## Une aile de papillon (cote : 1 l'aile droite, vers +X ; -1 la gauche) : la charnière le long de Z
## (la tête en +Z), à plat ; l'aile de devant, plus grande, et celle de derrière, d'un seul morceau ; la
## couleur en dégradé (plus sombre près du corps), le bout de l'aile de devant d'une autre couleur.
static func _papillons_aile(c: Color, bout: Color, cote: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dedans: Color = c.darkened(0.3)
	var lobes: Array = [
		[Vector3(0.012, 0.0, 0.012), [Vector3(0.0, 0.0, 0.016), Vector3(0.022, 0.0, 0.046), Vector3(0.056, 0.0, 0.054), Vector3(0.072, 0.0, 0.03), Vector3(0.052, 0.0, 0.006), Vector3(0.0, 0.0, -0.002)],
			[dedans, c, bout, bout, c, dedans]],
		[Vector3(0.012, 0.0, -0.014), [Vector3(0.0, 0.0, -0.002), Vector3(0.046, 0.0, -0.004), Vector3(0.052, 0.0, -0.03), Vector3(0.034, 0.0, -0.052), Vector3(0.01, 0.0, -0.044), Vector3(0.0, 0.0, -0.02)],
			[dedans, c, c.lightened(0.15), bout.lerp(c, 0.4), c, dedans]],
	]
	var m := Vector3(cote, 1.0, 1.0)
	for lb in lobes:
		var o: Vector3 = (lb[0] as Vector3) * m
		var pts: Array = lb[1]
		var cs: Array = lb[2]
		var nb: int = pts.size()
		for i in range(nb):
			var j: int = (i + 1) % nb
			for e in [[o, dedans], [(pts[i] as Vector3) * m, cs[i]], [(pts[j] as Vector3) * m, cs[j]]]:
				st.set_color(e[1])
				st.set_normal(Vector3.UP)
				st.add_vertex(e[0])
	return st.commit()


## Le corps d'un papillon (la tête en +Z) et ses deux antennes, d'un seul morceau.
static func _papillons_corps() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tete := Vector3(0.0, 0.003, 0.03)
	var queue := Vector3(0.0, 0.0, -0.036)
	var tour: Array = [Vector3(0.0055, 0.002, 0.008), Vector3(0.0, 0.008, 0.008), Vector3(-0.0055, 0.002, 0.008), Vector3(0.0, -0.004, 0.008)]
	for i in range(4):
		var a: Vector3 = tour[i]
		var b: Vector3 = tour[(i + 1) % 4]
		_papillons_tri(st, tete, b, a)
		_papillons_tri(st, queue, a, b)
	for sx in [-1.0, 1.0]:
		var p0 := Vector3(sx * 0.002, 0.005, 0.028)
		var p1 := Vector3(sx * 0.016, 0.02, 0.058)
		var e := Vector3(0.001, 0.001, 0.0)
		_papillons_tri(st, p0, p1, p1 + e)
		_papillons_tri(st, p0, p1 + e, p0 + e)
	return st.commit()


## Le petit jet de la fontaine : des gouttes qui montent un peu et retombent dans la vasque.
static func _papillons_jet(M, at: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 26
	p.lifetime = 0.62
	p.direction = Vector3.UP
	p.spread = 9.0
	p.initial_velocity_min = 1.4
	p.initial_velocity_max = 1.7
	p.gravity = Vector3(0, -6.0, 0)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.008, 0.02, 0.008)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.75, 0.88, 1.0, 0.8)
	bm.material = m
	p.mesh = bm
	M.room.add_child(p)
	p.global_position = at
	return p


## Un trait de craie sur le mur du fond (repère de la pièce : de (x0, y0) à (x1, y1), en z).
static func _papillons_trait(M, x0: float, y0: float, x1: float, y1: float, z: float) -> void:
	var R = M.R
	var l: float = Vector2(x1 - x0, y1 - y0).length()
	var a: float = atan2(y1 - y0, x1 - x0)
	R.kit.box(R.L((x0 + x1) * 0.5, (y0 + y1) * 0.5, z) * Transform3D(Basis(Vector3.BACK, a), Vector3.ZERO), Vector3(l + 0.005, 0.006, 0.004), "nu_craie", 1.0)


## Un nombre (ou un « ? ») écrit à la craie, sur le mur du fond (at : monde).
static func _papillons_craie(M, txt: String, at: Vector3, taille: int = 56) -> void:
	var lab := Label3D.new()
	lab.text = txt
	lab.font_size = taille
	lab.pixel_size = 0.0022
	lab.outline_size = 0
	lab.modulate = Color(0.93, 0.93, 0.88)
	lab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	M.room.add_child(lab)
	lab.global_position = at


## La chambre aux papillons : dans un coin de l'appartement, une petite serre (des parois de verre dans
## un cadre d'argent, un gradin de fleurs en pots, une petite fontaine et sa rampe d'arrosage) ; partout,
## des dizaines de papillons de toutes les couleurs (deux ailes qui battent) volent en boucles douces, se
## posent sur les fleurs, repartent. Un enfant essaie de les compter (des chiffres en bulles au-dessus des
## papillons… et il se trompe toujours), son père ou sa mère soigne les fleurs. On peut tendre la main (un
## papillon vient s'y poser ; la première fois, un sachet de graines ou du miel), compter les papillons
## (le compte change à chaque fois), arroser les fleurs (les papillons viennent boire). La nuit, ils dorment
## sur les fleurs, les ailes fermées, et ne bougent plus ; l'enfant s'est endormi sur le canapé en
## comptant ; seul le petit blanc, « Monsieur Pascal », ne dort jamais (il vient sur ta main), et le
## compte, pour une fois, tombe juste.
static func _papillons(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var room0: Node = M.room
	var nuit: bool = _nuit(M)
	var boy: bool = r.randf() < 0.5
	var pere: bool = r.randf() < 0.5
	var o: Vector3 = R.P(0, 0, 0)
	var nb: int = 30 + r.randi() % 13
	var fleurs: Array = ["nu_rose", "nu_jaune", "nu_lavande", "nu_rouge", "nu_blanc", "tissu_orange", "tissu_violet"]
	var argent := _mat(Color(0.86, 0.87, 0.9), 0.9, 0.3)
	# la serre, dans un coin du fond (à droite quand le mur du fond a sa baie, qui est à gauche) ; dans
	# une pièce profonde, elle englobe la première baie du mur de côté (les fleurs aiment la lumière)
	var s: float = 1.0 if R.W > 7.5 or r.randf() < 0.5 else -1.0
	var sw: float = clampf(R.W * 0.3, 1.9, 2.5)
	var sd: float = clampf(hd - 1.05, 1.45, 2.3) if R.D < 7.0 else R.D * 0.25 + 1.0
	var xi: float = s * (hw - sw)
	var zi: float = -hd + sd
	var scx: float = s * (hw - sw * 0.5)
	var scz: float = -hd + sd * 0.5
	var hg: float = 2.4
	R.reserve(scx, scz, sw + 0.1, sd + 0.1)
	R.mark_wall(scx, 1.5, -hd + 0.02, sw * 0.5 + 0.1)
	R.mark_wall(s * (hw - 0.02), 1.5, scz, sd * 0.5 + 0.1)
	R.kit.box(R.L(scx, 0.008, scz), Vector3(sw - 0.04, 0.016, sd - 0.04), "terre_cuite", 1.0, 4)
	# ses parois de verre dans leur cadre d'argent (l'entrée, sans porte, près du coin intérieur)
	var dx0: float = xi + s * 0.25
	var dx1: float = xi + s * 1.05
	var xd: float = (dx0 + dx1) * 0.5
	var pans: Array = [[Vector2(xi, zi), Vector2(dx0, zi)], [Vector2(dx1, zi), Vector2(s * hw, zi)], [Vector2(xi, -hd), Vector2(xi, zi)]]
	for pn in pans:
		var a: Vector2 = pn[0]
		var b: Vector2 = pn[1]
		var l: float = a.distance_to(b)
		var c: Vector2 = (a + b) * 0.5
		var yaw: float = 0.0 if absf(b.y - a.y) < 0.01 else 90.0
		R.kit.box(R.L(c.x, hg * 0.5, c.y, yaw), Vector3(l, hg - 0.04, 0.012), "verre", 1.0)
		R.kit.col_box(R.L(c.x, hg * 0.5, c.y, yaw), Vector3(l, hg, 0.06))
		for yy in [0.02, 0.9, hg]:
			R.kit.box(R.L(c.x, yy, c.y, yaw), Vector3(l + 0.03, 0.035, 0.035), "argent", 1.0)
		var nm: int = maxi(1, roundi(l / 0.62))
		for k in range(nm + 1):
			var q: Vector2 = a.lerp(b, float(k) / nm)
			R.kit.box(R.L(q.x, hg * 0.5, q.y), Vector3(0.035, hg, 0.035), "argent", 1.0)
	R.kit.box(R.L(xd, hg, zi), Vector3(0.83, 0.035, 0.035), "argent", 1.0)
	# le gradin de fleurs contre le mur du fond (trois marches, des pots de toutes les couleurs) ; chaque
	# bouquet est une place où se poser : {p : le dessus des fleurs (monde), serre, n : qui s'y est posé}
	var spots: Array = []
	var gw: float = sw - 0.3
	for k2 in range(3):
		var hk: float = 0.3 + k2 * 0.3
		var zk: float = -hd + 0.12 + (2 - k2) * 0.22
		R.kit.box(R.L(scx, hk * 0.5, zk), Vector3(gw, hk, 0.22), "ceramique", 1.0)
		R.kit.box(R.L(scx, hk + 0.012, zk), Vector3(gw + 0.02, 0.024, 0.24), "bois_clair", 1.0)
		var np: int = clampi(int(gw / 0.4), 2, 6)
		for j in range(np):
			var px: float = scx - gw * 0.5 + gw * (j + 0.5) / np
			_pot(M, px, zk, hk + 0.024, 0.66, str(fleurs[(j * 3 + k2 * 2 + r.randi() % 2) % fleurs.size()]))
			spots.append({"p": R.P(px, hk + 0.024 + 0.66 * 0.53, zk), "serre": true, "n": 0})
	R.kit.col_box(R.L(scx, 0.45, -hd + 0.34), Vector3(gw, 0.9, 0.66))
	# la rampe d'arrosage au-dessus du gradin (l'eau des nuages arrive par le tuyau du coin)
	var ry: float = 2.32
	var rz: float = -hd + 0.34
	var xa: float = xi + s * 0.15
	var xb: float = s * (hw - 0.06)
	R.kit.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5), R.P(maxf(xa, xb), ry, rz)), 0.014, 0.014, absf(xb - xa), "argent", 8)
	R.kit.cyl(R.L(xb, 0.0, rz), 0.016, 0.016, ry, "argent", 8, false)
	for k3 in range(3):
		var rx: float = scx - gw * 0.5 + gw * (k3 + 0.5) / 3.0
		R.kit.cyl(R.L(rx, ry - 0.07, rz), 0.045, 0.012, 0.06, "argent", 12)
		if k3 != 1:
			R.kit.cyl(R.L(rx, ry, rz), 0.005, 0.005, R.H - ry, "argent", 4, false)
	var pluie: CPUParticles3D = _gouttes(M, 70)
	pluie.emission_box_extents = Vector3(gw * 0.45, 0.02, 0.24)
	pluie.lifetime = 0.62
	pluie.global_position = R.P(scx, ry - 0.1, rz)
	# la petite fontaine, dans le coin de devant, et son robinet (c'est lui qui ouvre la rampe)
	var fx: float = s * (hw - 0.5)
	var fz: float = zi - 0.42
	R.kit.ring(R.L(fx, 0.0, fz), 0.25, 0.3, 0.34, "ceramique", 24)
	R.kit.disc(R.L(fx, 0.29, fz), 0.25, "nu_bleu", 24)
	R.kit.cyl(R.L(fx, 0.29, fz), 0.05, 0.03, 0.26, "argent", 10)
	R.kit.cyl(R.L(fx, 0.55, fz), 0.03, 0.1, 0.05, "argent", 14)
	R.kit.disc(R.L(fx, 0.596, fz), 0.09, "nu_bleu", 14)
	R.kit.col_box(R.L(fx, 0.17, fz), Vector3(0.6, 0.34, 0.6))
	R.reserve(fx, fz, 0.7, 0.7)
	var jet: CPUParticles3D = _papillons_jet(M, R.P(fx, 0.61, fz))
	var fontaine_at: Vector3 = R.P(fx, 0.5, fz)
	var robinet: Node3D = I._node(M, R.P(fx, 0.42, fz + 0.05), 0)
	_p(robinet, I._boxm(Vector3(0.012, 0.012, 0.03)), argent, Vector3.ZERO)
	_p(robinet, I._boxm(Vector3(0.075, 0.016, 0.016)), argent, Vector3(0, 0, 0.018))
	_sans_ombre(robinet)
	# dans une serre profonde, deux grands pots au milieu : c'est là que le parent travaille
	var profonde: bool = sd >= 2.2
	if profonde:
		for e in [[-0.42, -1.15], [0.36, -1.28]]:
			var mx: float = scx - s * 0.2 + float(e[0])
			var mz: float = zi + float(e[1])
			_pot(M, mx, mz, 0.0, 1.25, str(fleurs[r.randi() % fleurs.size()]))
			spots.append({"p": R.P(mx, 1.25 * 0.53, mz), "serre": true, "n": 0})
	# le canapé contre le mur d'en face (il regarde la serre), la table basse et ses deux pots, le lampadaire
	var cx: float = -s * (hw - 0.55)
	var cz: float = clampf(-0.2, -hd + 1.2, hd - 2.0)
	R.canape(cx, cz, 90.0 * s, str(_pick(M, ["blanc", "creme", "gris", "bleu"])))
	R.reserve(cx, cz, 1.1, 2.1)
	var tbx: float = cx + s * 1.05
	R.tapis(tbx, cz, 90, minf(2.2, R.D - 2.4), 1.5)
	_table_basse(M, tbx, cz, 0.5, 0.9)
	for tz2 in [-0.22, 0.24]:
		_pot(M, tbx, cz + float(tz2), 0.38, 0.6, str(fleurs[r.randi() % fleurs.size()]))
		spots.append({"p": R.P(tbx, 0.38 + 0.6 * 0.53, cz + float(tz2)), "serre": false, "n": 0})
	if R.is_free(cx, cz - 1.3, 0.45, 0.45):
		_lampadaire(M, cx, cz - 1.3)
	# le tableau des comptes de l'enfant, au mur du fond, à côté de la serre : des bâtons par cinq, un
	# papillon dessiné, des nombres barrés… et un grand « ? »
	var xs: float = s * (hw - sw - 0.62)
	var ys: float = 1.42
	var zc: float = -hd + 0.03
	R.mark_wall(xs, ys, -hd + 0.02, 0.55)
	R.kit.box(R.L(xs, ys, -hd + 0.015), Vector3(0.86, 0.6, 0.02), "nu_ardoise", 1.0)
	for sy in [-1.0, 1.0]:
		R.kit.box(R.L(xs, ys + float(sy) * 0.315, -hd + 0.02), Vector3(0.9, 0.03, 0.03), "bois_clair", 1.0)
		R.kit.box(R.L(xs + float(sy) * 0.445, ys, -hd + 0.02), Vector3(0.03, 0.63, 0.03), "bois_clair", 1.0)
	R.kit.box(R.L(xs, ys - 0.34, -hd + 0.045), Vector3(0.86, 0.02, 0.06), "bois_clair", 1.0)
	R.kit.box(R.L(xs + 0.22, ys - 0.322, -hd + 0.05, 12), Vector3(0.07, 0.014, 0.014), "nu_craie", 1.0)
	for row in range(3):
		var yr: float = ys + 0.17 - row * 0.12
		for g in range(3 if row < 2 else 2):
			var gx0: float = xs - 0.37 + g * 0.12
			for k4 in range(4):
				_papillons_trait(M, gx0 + k4 * 0.02, yr - 0.035, gx0 + k4 * 0.02, yr + 0.035, zc)
			_papillons_trait(M, gx0 - 0.012, yr - 0.03, gx0 + 0.072, yr + 0.03, zc + 0.001)
	var bx0: float = xs - 0.3
	var by0: float = ys - 0.19
	_papillons_trait(M, bx0, by0 - 0.03, bx0, by0 + 0.03, zc)
	for sx2 in [-1.0, 1.0]:
		var ex0: float = bx0 + float(sx2) * 0.05
		_papillons_trait(M, bx0, by0, ex0, by0 + 0.04, zc)
		_papillons_trait(M, ex0, by0 + 0.04, ex0, by0 - 0.035, zc)
		_papillons_trait(M, ex0, by0 - 0.035, bx0, by0, zc)
	var vieux: Array = [nb - 3 - r.randi() % 6, nb + 2 + r.randi() % 7, nb - 1 - r.randi() % 3]
	for k5 in range(3):
		var yk: float = ys + 0.17 - k5 * 0.12
		_papillons_craie(M, str(vieux[k5]), R.P(xs + 0.24, yk, zc + 0.002))
		_papillons_trait(M, xs + 0.18, yk - 0.008, xs + 0.3, yk + 0.012, zc + 0.006)
	_papillons_craie(M, "?", R.P(xs + 0.24, ys - 0.2, zc + 0.002), 84)
	# la cheminée à l'éthanol, au mur du fond, entre le coin du canapé et le tableau (s'il y a la place)
	var fxp: float = -s * (hw - 1.0)
	for _k6 in range(16):
		if s * ((xs - s * 0.46) - fxp) < 0.9:
			break
		if R.wall_free(fxp, 0.9, -hd + 0.02, 0.8) and R.is_free(fxp, -hd + 0.22, 1.8, 0.8):
			_foyer(M, fxp)
			R.mark_wall(fxp, 1.0, -hd + 0.02, 0.85)
			break
		fxp += s * 0.45
	# l'échelle à fleurs, dans le coin de devant loin de la porte ; de grands pots dans d'autres coins
	var es: float = -signf(R.door_x) if absf(R.door_x) > 0.05 else -s
	var ex: float = es * (hw - 0.5)
	var ez: float = hd - 0.24
	if R.is_free(ex, ez, 0.8, 0.45):
		for sx3 in [-1.0, 1.0]:
			R.kit.box(R.L(ex + float(sx3) * 0.35, 0.7, ez), Vector3(0.035, 1.4, 0.035), "bois_clair", 1.0)
		for k7 in range(3):
			var ey: float = 0.32 + k7 * 0.4
			R.kit.box(R.L(ex, ey, ez), Vector3(0.74, 0.025, 0.26), "bois_clair", 1.0)
			for sx4 in [-0.17, 0.17]:
				_pot(M, ex + float(sx4), ez, ey + 0.012, 0.55, str(fleurs[r.randi() % fleurs.size()]))
				spots.append({"p": R.P(ex + float(sx4), ey + 0.012 + 0.55 * 0.53, ez), "serre": false, "n": 0})
		R.kit.col_box(R.L(ex, 0.7, ez), Vector3(0.76, 1.4, 0.3))
		R.reserve(ex, ez, 0.8, 0.45)
	for e2 in [[-es * (hw - 0.45), hd - 0.45], [-s * (hw - 0.45), -hd + 0.45]]:
		var gx2: float = float(e2[0])
		var gz2: float = float(e2[1])
		if absf(gx2 - R.door_x) > 1.05 and R.is_free(gx2, gz2, 0.5, 0.5):
			_pot(M, gx2, gz2, 0.0, 1.2, str(fleurs[r.randi() % fleurs.size()]))
			spots.append({"p": R.P(gx2, 1.2 * 0.53, gz2), "serre": false, "n": 0})
	_cadres(M, 2)
	# les gens : le parent soigne les fleurs dans la serre, l'enfant compte au milieu de la pièce ; la
	# nuit, l'enfant s'est endormi sur le canapé en comptant, et le parent veille à l'entrée de la serre
	var parent: Node
	var kid: Node
	var kx: float = xi - s * 1.25
	var kz: float = clampf(zi + 0.95, -hd + 1.4, hd - 1.7)
	if nuit:
		parent = M.person("homme" if pere else "femme", xd, zi + 0.55, 180.0, "mains_dos")
		parent.lines = ["Chut… tout le monde dort.", "Ils dorment les ailes fermées, comme de petits livres.", "Pas un bruit… même la fontaine chuchote.",
			"Le petit s'est endormi en comptant." if boy else "La petite s'est endormie en comptant."]
		parent.line_every = Vector2(10.0, 15.0)
		kid = M.person("garcon" if boy else "fille", cx, cz, 90.0 * s, "dormir")
		kid.lie(R.P(cx + s * 0.06, 0.47, cz + 0.75), Vector3(0, 0, -1))
		kid.lines = ["Zzz…", "Zzz… quarante et un… quarante-deux… zzz…", "Mmh… pas sur mon nez, Capitaine… zzz…"]
		kid.line_every = Vector2(9.0, 14.0)
		var vl := OmniLight3D.new()
		vl.light_color = Color(1.0, 0.86, 0.62)
		vl.light_energy = 0.55
		vl.omni_range = 3.2
		vl.shadow_enabled = false
		M.room.add_child(vl)
		vl.global_position = R.P(scx, 1.6, scz)
	else:
		var ppx: float = scx - s * 0.2 if profonde else scx - s * 0.25
		var ppz: float = zi - 0.6 if profonde else -hd + 1.09
		parent = M.person("homme" if pere else "femme", ppx, ppz, 180.0, "jardiner")
		parent.lines = ["Doucement, les capucines…", "Qui a encore bu tout le nectar des pétunias ?", "Ici, ils ne font pas grève. Ils sont en vacances.",
			"Tu en es à combien, mon cœur ?", "Attention, ne marche pas sur Confiture ! … Ah non, c'est un pétale."]
		parent.line_every = Vector2(8.0, 13.0)
		kid = M.person("garcon" if boy else "fille", kx, kz, _vers(kx, kz, scx, scz), "debout")
		kid.lines = ["Trente-deux, trente-trois… Hé ! Reste là, toi !", "Un, deux, trois… Bon. Je recommence.", "Celui-là, je l'ai déjà compté ! … Ou c'est son frère ?",
			"Quarante ! Non, trente-neuf : celui-là, c'est une feuille.", "Papa, ils bougent tout le temps !" if pere else "Maman, ils bougent tout le temps !"]
		kid.line_every = Vector2(7.0, 11.0)
	# les papillons : un corps, deux ailes qui battent ; chacun sa boucle (les uns dans la serre, sous les
	# vitres ; les autres dans la pièce, et ceux dont la boucle passe au-dessus de la serre volent plus haut
	# que ses vitres). Le premier est le petit blanc, celui qui ne dort jamais.
	var cols: Array = _papillons_couleurs()
	var ailes: Array = []
	for cp in cols:
		ailes.append([_papillons_aile(cp[0], cp[1], -1.0), _papillons_aile(cp[0], cp[1], 1.0)])
	var aile_m := StandardMaterial3D.new()
	aile_m.vertex_color_use_as_albedo = true
	aile_m.vertex_color_is_srgb = true
	aile_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	aile_m.roughness = 0.55
	var corps_m := _mat(Color(0.13, 0.1, 0.08), 0.0, 0.7)
	corps_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var corps_mesh: ArrayMesh = _papillons_corps()
	var n_piece: int = int(nb * 0.42)
	var x_lo: float = minf(xi, s * hw)
	var x_hi: float = maxf(xi, s * hw)
	var bs: Array = []
	for i in range(nb):
		var en_serre: bool = i >= n_piece
		var bn := Node3D.new()
		M.room.add_child(bn)
		bn.scale = Vector3.ONE * r.randf_range(0.85, 1.2)
		_p(bn, corps_mesh, corps_m, Vector3.ZERO)
		var ci: int = 4 if i == 0 else r.randi() % cols.size()
		var ag := Node3D.new()
		bn.add_child(ag)
		ag.position = Vector3(-0.004, 0.003, 0.0)
		_p(ag, ailes[ci][0], aile_m, Vector3.ZERO)
		var ad := Node3D.new()
		bn.add_child(ad)
		ad.position = Vector3(0.004, 0.003, 0.0)
		_p(ad, ailes[ci][1], aile_m, Vector3.ZERO)
		_sans_ombre(bn)
		var ax: float
		var az: float
		var lx: float
		var lz: float
		var y0: float
		var ay: float
		var ymin: float = 0.0
		if en_serre:
			ax = r.randf_range(0.2, maxf(0.22, sw * 0.5 - 0.45))
			az = r.randf_range(0.2, maxf(0.22, sd * 0.5 - 0.45))
			lx = scx + r.randf_range(-1.0, 1.0) * maxf(0.0, sw * 0.5 - 0.3 - ax)
			lz = scz + r.randf_range(-1.0, 1.0) * maxf(0.0, sd * 0.5 - 0.3 - az)
			y0 = r.randf_range(1.92, 2.06)
			ay = r.randf_range(0.03, 0.07)
		else:
			ax = r.randf_range(0.45, minf(1.4, hw - 1.0))
			az = r.randf_range(0.45, minf(1.3, hd - 1.2))
			lx = r.randf_range(-hw + 0.7 + ax, hw - 0.7 - ax)
			lz = r.randf_range(-hd + 0.7 + az, hd - 1.2 - az)
			if lx + ax > x_lo - 0.2 and lx - ax < x_hi + 0.2 and lz - az < zi + 0.2:
				y0 = r.randf_range(2.56, 2.7)
				ay = 0.04
				ymin = 2.5
			else:
				y0 = r.randf_range(1.6, 2.35)
				ay = r.randf_range(0.06, 0.2)
		var b := {"n": bn, "ag": ag, "ad": ad, "serre": en_serre, "c": R.P(lx, y0, lz), "ax": ax, "ay": ay, "az": az,
			"w1": r.randf_range(0.22, 0.4) / ax * (1.0 if r.randf() < 0.5 else -1.0), "w2": r.randf_range(0.22, 0.4) / az * (1.0 if r.randf() < 0.5 else -1.0),
			"w3": r.randf_range(0.5, 1.1), "p1": r.randf() * TAU, "p2": r.randf() * TAU, "p3": r.randf() * TAU, "tb": r.randf() * 60.0,
			"f": TAU * r.randf_range(5.5, 8.5), "ph": r.randf() * TAU, "pos": Vector3.ZERO, "yaw": r.randf() * TAU, "mode": "vol",
			"spot": -1, "cible": Vector3.ZERO, "wp": 0, "d": 0.0, "ymin": ymin, "yr": 0.0, "nuit_p": Vector3.ZERO}
		bs.append(b)
	# ce qu'ils savent faire : suivre leur boucle, choisir une fleur, y aller, repartir
	var st := {"t": 0.0, "pluie": 0.0, "glou": 3.0, "kc": r.randf_range(5.0, 9.0), "pose_t": 1.0, "main": -1, "mb": 0, "compte": false, "dernier": 0}
	var dans_serre := func(p: Vector3) -> bool:
		var q: Vector3 = p - o
		return q.x > x_lo and q.x < x_hi and q.z < zi
	var boucle := func(pb: Dictionary, tb: float) -> Vector3:
		var c: Vector3 = pb["c"]
		return c + Vector3(float(pb["ax"]) * sin(float(pb["w1"]) * tb + float(pb["p1"])), float(pb["ay"]) * sin(float(pb["w3"]) * tb + float(pb["p3"])),
			float(pb["az"]) * sin(float(pb["w2"]) * tb + float(pb["p2"])))
	var prendre := func(serre: bool, maxn: int) -> int:
		var cands: Array = []
		for j in range(spots.size()):
			var sp: Dictionary = spots[j]
			if bool(sp["serre"]) == serre and int(sp["n"]) < maxn:
				cands.append(j)
		if cands.is_empty():
			return -1
		return int(cands[randi() % cands.size()])
	var aller := func(pb: Dictionary, j: int, duree: float) -> void:
		var sp: Dictionary = spots[j]
		var k: int = int(sp["n"])
		sp["n"] = k + 1
		pb["spot"] = j
		var off: Vector3 = Vector3.ZERO
		if k > 0:
			off = Vector3(cos(k * 2.4 + j) * 0.055, 0.006 * k, sin(k * 2.4 + j) * 0.055)
		pb["cible"] = (sp["p"] as Vector3) + off
		pb["wp"] = 0
		pb["d"] = duree
		pb["mode"] = "va"
	var lacher := func(pb: Dictionary) -> void:
		var j: int = int(pb["spot"])
		if j >= 0:
			var sp2: Dictionary = spots[j]
			sp2["n"] = maxi(0, int(sp2["n"]) - 1)
		pb["spot"] = -1
		pb["mode"] = "decolle"
		var c: Vector3 = pb["c"]
		var p0: Vector3 = pb["pos"]
		pb["yr"] = maxf(maxf(c.y - float(pb["ay"]), float(pb["ymin"])), p0.y + 0.25)
	var volants := func() -> Array:
		var l2: Array = []
		for i2 in range(bs.size()):
			if str(bs[i2]["mode"]) == "vol":
				l2.append(i2)
		l2.shuffle()
		return l2
	# où ils sont au départ : le jour, sur leur boucle (quelques-uns posés) ; la nuit, sur les fleurs,
	# deux ou trois par bouquet (ceux de la pièce sur les fleurs de la pièce, les autres dans la serre)
	if nuit:
		var lieux: Array = [[], []]
		for j2 in range(spots.size()):
			(lieux[1 if bool(spots[j2]["serre"]) else 0] as Array).append(j2)
		var kk: Array = [0, 0]
		for pb in bs:
			var zone: int = 1 if bool(pb["serre"]) else 0
			var lst: Array = lieux[zone]
			var j3: int = int(lst[int(kk[zone]) % lst.size()])
			kk[zone] = int(kk[zone]) + 1
			aller.call(pb, j3, 0.0)
			pb["mode"] = "dort"
			pb["pos"] = pb["cible"]
			pb["nuit_p"] = pb["cible"]
	else:
		for pb2 in bs:
			pb2["pos"] = boucle.call(pb2, float(pb2["tb"]))
			if r.randf() < 0.15:
				var j4: int = prendre.call(bool(pb2["serre"]), 2)
				if j4 >= 0:
					aller.call(pb2, j4, r.randf_range(2.0, 9.0))
					pb2["mode"] = "pose"
					pb2["pos"] = pb2["cible"]
	for pb3 in bs:
		var bn2: Node3D = pb3["n"]
		bn2.global_position = pb3["pos"]
		bn2.rotation.y = float(pb3["yaw"])
		var a0: float = 1.48 if str(pb3["mode"]) == "dort" else 0.9
		(pb3["ag"] as Node3D).rotation.z = -a0
		(pb3["ad"] as Node3D).rotation.z = a0
	# la main tendue : devant toi, un peu sur le côté (en VR, sous les yeux)
	var main_at := func() -> Vector3:
		var pp: Vector3 = M.main._player_pos_v27()
		var cam: Camera3D = M.main.get_viewport().get_camera_3d()
		var fwd: Vector3 = Vector3(0, 0, -1)
		if cam != null:
			fwd = -cam.global_basis.z
		fwd.y = 0.0
		if fwd.length() < 0.05:
			fwd = Vector3(0, 0, -1)
		fwd = fwd.normalized()
		var droite: Vector3 = fwd.cross(Vector3.UP)
		if bool(M.main.get("xr_active")):
			return pp + fwd * 0.34 + droite * 0.1 + Vector3(0, -0.42, 0)
		return pp + fwd * 0.28 + droite * 0.3 + Vector3(0, 1.2, 0)
	# la récompense, une seule fois : un sachet de graines (ou du miel, si on a déjà des graines)
	var recompense := func() -> void:
		if bool(M.state().get("nu_papillons", false)):
			return
		M.state()["nu_papillons"] = true
		var cad: String = _neuf(M, "graines", "miel")
		if nuit:
			var txt_n: String
			if cad == "graines":
				txt_n = "Monsieur Pascal s'est posé sur toi… D'habitude, il ne se pose sur personne. Tiens, tout bas : un sachet de graines de tournesol, le goûter du petit. Il sera d'accord." if boy else "Monsieur Pascal s'est posé sur toi… D'habitude, il ne se pose sur personne. Tiens, tout bas : un sachet de graines de tournesol, le goûter de la petite. Elle sera d'accord."
			else:
				txt_n = "Monsieur Pascal s'est posé sur toi… D'habitude, il ne se pose sur personne. Tiens, tout bas : du miel des Serres d'Altitude. Flora Verdine nous en apporte quand elle vient voir ses anciens pensionnaires."
			M.talk(parent, txt_n, I._bye("Merci… Bonne nuit !"), func(_i):
				M.give([[cad, 1]], "")
				M.close_talk(), "à voix basse")
			return
		var txt: String = "Il s'est posé sur toi ! Ça veut dire qu'il t'a choisi. Tiens, c'est mon goûter : un sachet de graines de tournesol. Les papillons n'en veulent pas, ils préfèrent les fleurs." if cad == "graines" else "Il s'est posé sur toi ! Ça veut dire qu'il t'a choisi. Tiens, c'est mon goûter : du miel des Serres d'Altitude. Flora dit que les papillons y sont pour quelque chose : ils aident les fleurs."
		kid.gesture("joie", 2.0)
		M.talk(kid, txt, I._bye("Merci ! Bon vent !"), func(_i):
			M.give([[cad, 1]], "")
			M.close_talk(), "aux anges")
	# un papillon se pose sur la main… puis repart (en bulles)
	var arrivee_main := func(at: Vector3) -> void:
		M.main.sfx("ailes", at, -12.0)
		if not bool(M.state().get("nu_papillons", false)):
			M.main.sfx("carillon", at)
		_bulle(M, at + Vector3(0, 0.22, 0), str(_pick(M, ["Chut…", "Il est tout léger…"] if nuit else ["Il se pose…", "Chut… ne bouge plus.", "Il est là, sur ta main !"])), Color(1.0, 0.97, 0.88), 36, 0.45, 1.8)
		if not nuit:
			kid.gesture("joie", 2.0)
			S._say_late(M, kid, str(_pick(M, ["Il t'a choisi ! Il t'a choisi !", "Tu as vu ? Il n'a même pas peur !", "Ne bouge plus, il est bien, là !"])), 0.6)
	var depart_main := func(pb: Dictionary, at: Vector3) -> void:
		st["main"] = -1
		st["mb"] = 0
		M.main.sfx("ailes", at, -12.0)
		_bulle(M, at + Vector3(0, 0.22, 0), str(_pick(M, ["Bonne nuit, petit papillon…", "Il retourne sur sa fleur…"] if nuit else ["Bon vent, petit papillon !", "Et hop, il repart !", "Flap, flap… au revoir !"])), Color(1.0, 0.97, 0.88), 36, 0.45, 1.8)
		if nuit:
			pb["cible"] = pb["nuit_p"]
			pb["wp"] = 0
			pb["mode"] = "va"
		else:
			pb["spot"] = -1
			lacher.call(pb)
		recompense.call()
	# l'enfant compte : des chiffres en bulles au-dessus des papillons… et il se trompe toujours
	var compte_enfant := func() -> void:
		if bool(st["compte"]) or bool(kid.talking):
			return
		var vus: Array = volants.call()
		if vus.size() < 3:
			return
		st["compte"] = true
		kid.set_pose("pointer")
		kid.follow = false
		var k: int = 5 + randi() % 5
		for c2 in range(mini(k, vus.size())):
			var bp: Vector3 = (bs[int(vus[c2])]["n"] as Node3D).global_position
			var kp: Vector3 = kid.npc.global_position
			kid.face_dir = Vector3(bp.x - kp.x, 0, bp.z - kp.z)
			_bulle(M, bp + Vector3(0, 0.14, 0), str(c2 + 1), Color(1.0, 0.96, 0.75), 30, 0.25, 1.0)
			await M.get_tree().create_timer(0.55).timeout
			if not _la(M, room0):
				return
		if randf() < 0.18:
			M.main.sfx("eternuement", kid.npc.global_position + Vector3(0, 1.0, 0))
			kid.say("Atchoum ! … Du pollen. Bon, je recommence.", 3.0)
		else:
			kid.say(str(_pick(M, ["Euh… je ne sais plus où j'en suis.", "Hé ! Toi, je t'ai déjà compté !", "Arrêtez de bouger, s'il vous plaît !",
				"Bon. Je recommence. Un…", "Celui-là compte double : il est très grand."])), 3.0)
		kid.set_pose("debout")
		st["compte"] = false
	# compter soi-même : le jour, le compte change à chaque fois ; la nuit, personne ne bouge
	var compter := func() -> void:
		if nuit:
			M.say(str(_pick(M, ["Tu comptes les papillons endormis, fleur après fleur, tout bas : %d. Pour une fois, personne ne bouge. C'est le bon compte !",
				"Sur chaque fleur, des papillons dorment, les ailes fermées. Tu les comptes sans un bruit : %d. Exactement."])) % nb, 6.0)
			S._say_late(M, parent, "Chut… Ne le dis pas au petit. Demain, il voudra recompter." if boy else "Chut… Ne le dis pas à la petite. Demain, elle voudra recompter.", 1.6)
			return
		if bool(st["compte"]):
			return
		var vus2: Array = volants.call()
		st["compte"] = true
		for c3 in range(mini(8, vus2.size())):
			var bp2: Vector3 = (bs[int(vus2[c3])]["n"] as Node3D).global_position
			_bulle(M, bp2 + Vector3(0, 0.14, 0), str(c3 + 1), Color(0.85, 0.95, 1.0), 32, 0.25, 1.0)
			await M.get_tree().create_timer(0.38).timeout
			if not _la(M, room0):
				return
		var a1: int = nb + randi_range(-9, 9)
		if a1 == int(st["dernier"]):
			a1 += 2
		st["dernier"] = a1
		var b1: int = nb + randi_range(-12, 12)
		if b1 == a1:
			b1 -= 3
		M.main.sfx("clochette", R.P(xs, 1.4, -hd + 0.3))
		M.say(str(_pick(M, ["Un, deux, trois… %d ! Non, attends : le jaune, tu l'as compté deux fois.", "Tu arrives à %d. Puis un papillon se pose sur ton nez, et tu perds le fil.",
			"%d papillons ! Enfin, à peu près : les bleus ne restent jamais assez longtemps pour être comptés.",
			"Tu en comptes %d. Pendant ce temps, trois autres sont passés derrière la lampe. Ou les mêmes. Difficile à dire."])) % a1, 5.5)
		kid.gesture("rire", 2.0)
		S._say_late(M, kid, str(_pick(M, ["Moi, j'en ai compté %d !", "Presque ! Moi, j'en ai trouvé %d. Je crois.", "Pas du tout ! Il y en a au moins %d !",
			"Moi, j'ai dit %d. On n'a qu'à faire la moyenne !"])) % b1, 1.8, 3.5)
		st["compte"] = false
	# arroser : le robinet de la fontaine ouvre la rampe ; une pluie fine sur le gradin, et ceux de la
	# serre viennent boire sur les pétales mouillés
	var arroser := func() -> void:
		if float(st["pluie"]) > 0.0:
			return
		st["pluie"] = 2.8
		pluie.emitting = true
		var tw: Tween = M.room.create_tween()
		tw.tween_property(robinet, "rotation:z", 1.3, 0.25)
		tw.tween_interval(2.3)
		tw.tween_property(robinet, "rotation:z", 0.0, 0.3)
		M.main.sfx("verser", R.P(scx, ry, rz))
		M.main.sfx("bulles", fontaine_at, -4.0)
		_bulle(M, R.P(scx, ry + 0.2, rz), "Plic… ploc… plic…", Color(0.75, 0.88, 1.0), 34, 0.4, 1.8)
		if nuit:
			M.say(str(_pick(M, ["Une pluie toute fine tombe sur les fleurs. Une goutte roule sur une aile fermée : le papillon ne se réveille même pas.",
				"Tu arroses tout doucement. Les papillons endormis ne bougent pas d'une antenne."])), 4.5)
			parent.say("Tout doux… ils dorment juste dessous.", 3.0)
			return
		var n2: int = 0
		for i3 in volants.call():
			var pb4: Dictionary = bs[int(i3)]
			if not bool(pb4["serre"]):
				continue
			var j5: int = prendre.call(true, 3)
			if j5 < 0:
				break
			aller.call(pb4, j5, randf_range(5.0, 9.0))
			n2 += 1
			if n2 >= 6:
				break
		parent.say(str(_pick(M, ["Merci ! Pas trop, hein : ils n'aiment pas se mouiller les pieds.", "Parfait ! Tu as la main verte.", "Ah, la pluie de serre ! Ils adorent ça."])), 3.5)
		S._say_late(M, kid, str(_pick(M, ["Ils vont boire ! Regarde !", "Ils arrivent tous !", "Capitaine a soif !"])), 1.2)
	# tendre la main : le jour, le papillon le plus proche (du même côté des vitres) ; la nuit, le petit blanc
	var tendre := func() -> void:
		if int(st["main"]) >= 0:
			return
		var i0: int = -1
		if nuit:
			i0 = 0
			M.say("Tous les papillons dorment sur les fleurs… sauf un. Le petit blanc ouvre les ailes, s'envole sans un bruit et vient vers ta main.", 5.0)
		else:
			var hand0: Vector3 = main_at.call()
			var zone0: bool = dans_serre.call(hand0)
			var best: float = INF
			for i5 in range(bs.size()):
				var pb5: Dictionary = bs[i5]
				if str(pb5["mode"]) != "vol" or bool(pb5["serre"]) != zone0:
					continue
				var d5: float = (pb5["pos"] as Vector3).distance_to(hand0)
				if d5 < best:
					best = d5
					i0 = i5
			if i0 < 0:
				M.say("Tous les papillons se reposent sur les fleurs. Attends un peu : ils vont bientôt repartir.", 3.5)
				return
			kid.say(str(_pick(M, ["Ne bouge plus ! Ne respire plus !", "La main bien à plat ! Comme ça !", "Il arrive ! Il arrive !"])), 3.0)
		var pb6: Dictionary = bs[i0]
		pb6["mode"] = "main"
		st["main"] = i0
		st["mb"] = 0
	# ce qui bouge (un seul tick pour tous) : les papillons (leur vol, leurs ailes), la pluie de serre,
	# la fontaine qui glougloute, l'enfant qui recompte, les papillons qui se posent et repartent
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(jet):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		if float(st["pluie"]) > 0.0:
			st["pluie"] = float(st["pluie"]) - dt
			if float(st["pluie"]) <= 0.0:
				pluie.emitting = false
		st["glou"] = float(st["glou"]) - dt
		if float(st["glou"]) <= 0.0:
			st["glou"] = randf_range(9.0, 14.0)
			M.main.sfx("bulles", fontaine_at, -8.0)
		if not nuit:
			st["kc"] = float(st["kc"]) - dt
			if float(st["kc"]) <= 0.0:
				st["kc"] = randf_range(16.0, 24.0)
				compte_enfant.call()
			st["pose_t"] = float(st["pose_t"]) - dt
			if float(st["pose_t"]) <= 0.0:
				st["pose_t"] = randf_range(1.0, 2.2)
				var pq: Dictionary = bs[randi() % bs.size()]
				if str(pq["mode"]) == "vol":
					var jq: int = prendre.call(bool(pq["serre"]), 2)
					if jq >= 0:
						aller.call(pq, jq, randf_range(4.0, 11.0))
		var im: int = int(st["main"])
		var hand: Vector3 = main_at.call() if im >= 0 else Vector3.ZERO
		var hand_serre: bool = bool(dans_serre.call(hand)) if im >= 0 else false
		for i4 in range(bs.size()):
			var pb: Dictionary = bs[i4]
			var mode: String = pb["mode"]
			if mode == "dort":
				continue
			var p: Vector3 = pb["pos"]
			var tgt: Vector3 = p
			var vit: float = 0.9
			var vole: bool = true
			match mode:
				"vol":
					var tb: float = float(pb["tb"]) + dt
					pb["tb"] = tb
					tgt = boucle.call(pb, tb)
				"va":
					# au-dessus de la fleur d'abord, puis on descend tout droit
					var sp: Vector3 = pb["cible"]
					if int(pb["wp"]) == 0:
						tgt = Vector3(sp.x, maxf(p.y, sp.y + 0.25), sp.z)
						if Vector2(sp.x - p.x, sp.z - p.z).length() < 0.05:
							pb["wp"] = 1
					else:
						tgt = sp
						vit = 0.4
						if p.distance_to(sp) < 0.004:
							pb["mode"] = "dort" if nuit else "pose"
							vole = false
				"pose":
					vole = false
					pb["d"] = float(pb["d"]) - dt
					if float(pb["d"]) <= 0.0:
						lacher.call(pb)
				"decolle":
					tgt = Vector3(p.x, float(pb["yr"]), p.z)
					vit = 0.6
					if p.y >= float(pb["yr"]) - 0.02:
						pb["mode"] = "vol"
				"main":
					# vers la main (par-dessus les vitres de la serre s'il faut les passer)
					tgt = hand
					vit = 0.75
					if bool(dans_serre.call(p)) != hand_serre:
						tgt = Vector3(hand.x, maxf(p.y, 2.5), hand.z)
					elif p.distance_to(hand) < 0.03:
						pb["mode"] = "sur_main"
						pb["d"] = 6.5
						st["mb"] = 1
						arrivee_main.call(hand)
				"sur_main":
					vole = false
					p = hand
					tgt = hand
					pb["d"] = float(pb["d"]) - dt
					var dm: float = float(pb["d"])
					if int(st["mb"]) == 1 and dm < 4.6:
						st["mb"] = 2
						_bulle(M, hand + Vector3(0, 0.22, 0), str(_pick(M, ["Il ne dort jamais, celui-là.", "Ses ailes battent tout doucement…"] if nuit else ["Ça chatouille !", "Ses ailes s'ouvrent… se ferment…", "Il goûte ta main. Elle est sucrée ?"])), Color(1.0, 0.97, 0.88), 34, 0.45, 1.8)
					elif int(st["mb"]) == 2 and dm < 2.6:
						st["mb"] = 3
						_bulle(M, hand + Vector3(0, 0.22, 0), "♥", Color(1.0, 0.7, 0.82), 46, 0.45, 1.4)
					elif dm <= 0.0:
						depart_main.call(pb, hand)
			var dv: Vector3 = tgt - p
			p = p.move_toward(tgt, dt * vit)
			pb["pos"] = p
			# les ailes : elles battent en vol ; posé, il les ouvre et les ferme lentement ; endormi, fermées
			var bn3: Node3D = pb["n"]
			var f: float = float(pb["f"])
			var ph: float = float(pb["ph"])
			var ang: float = 1.48
			if str(pb["mode"]) == "dort":
				bn3.global_position = p
			elif vole:
				ang = 0.55 + 0.8 * sin(t * f + ph)
				bn3.global_position = p + Vector3(0.012 * sin(t * 2.3 + ph), 0.02 * sin(t * f + ph + 1.6), 0.012 * cos(t * 1.9 + ph))
				if dv.x * dv.x + dv.z * dv.z > 0.0000001:
					pb["yaw"] = lerp_angle(float(pb["yaw"]), atan2(dv.x, dv.z), clampf(dt * 6.0, 0.0, 1.0))
			else:
				ang = 0.95 + 0.45 * sin(t * 1.3 + ph)
				bn3.global_position = p
			bn3.rotation.y = float(pb["yaw"])
			(pb["ag"] as Node3D).rotation.z = -ang
			(pb["ad"] as Node3D).rotation.z = ang
	# ce qu'on fait : tendre la main (devant la serre), compter (au tableau), arroser (à la fontaine)
	var zm: float = clampf(zi + 1.25, -hd + 0.5, hd - 1.6)
	M.act(R.P(scx, 0, zm), "E : tendre la main", func(): tendre.call(), 1.3, func(): return int(st["main"]) < 0)
	M.act(R.P(xs, 0, -hd + 0.9), "E : compter les papillons", func(): compter.call(), 1.2, func(): return not bool(st["compte"]))
	M.act(R.P(fx, 0, fz), "E : arroser les fleurs", func(): arroser.call(), 1.3, func(): return float(st["pluie"]) <= 0.0)
	# parler à l'enfant
	var kid_cb := func() -> void:
		if nuit:
			M.talk(kid, "Zzz… quarante-deux… quarante-trois… Gérard, reste tranquille… zzz…", I._bye("(Le laisser dormir)") if boy else I._bye("(La laisser dormir)"), I._close(M), "endormi" if boy else "endormie")
			return
		var a2: int = nb + randi_range(-11, -3)
		var b2: int = nb + randi_range(3, 12)
		M.talk(kid, str(_pick(M, ["Chut ! Je compte. Trente-huit, trente-neuf… Oh non ! Tu m'as fait perdre le compte !",
			"Bonjour ! Tu veux m'aider ? Je compte les papillons. Ça fait trois semaines que je n'y arrive pas."])),
			[{"id": "combien", "label": "Combien il y en a ?"}, {"id": "noms", "label": "Ils ont des noms ?"}, {"id": "aider", "label": "Je t'aide à compter !"}, {"id": "fermer", "label": "Bon courage !"}], func(id):
			match id:
				"combien":
					M.talk(kid, ("Hier, j'en ai compté %d. Ce matin, %d. Papa dit que c'est parce qu'ils bougent. Moi, je crois qu'il y en a qui trichent." if pere else "Hier, j'en ai compté %d. Ce matin, %d. Maman dit que c'est parce qu'ils bougent. Moi, je crois qu'il y en a qui trichent.") % [a2, b2],
						I._bye("Ils trichent, c'est sûr !"), I._close(M), "très concentré" if boy else "très concentrée")
				"noms":
					M.talk(kid, "Oui ! Le grand bleu, c'est Capitaine. Le jaune, c'est Confiture. Le petit blanc, c'est Monsieur Pascal : il râle quand on ouvre la fenêtre. Les autres, je les appelle tous Gérard. Ça va plus vite.",
						I._bye("Bonjour, Gérard !"), I._close(M), "très concentré" if boy else "très concentrée")
				"aider":
					M.close_talk()
					compter.call()
				_:
					M.close_talk()
		, "très concentré" if boy else "très concentrée")
	M.talk_spot(kid, kid_cb)
	# parler au parent
	var parent_cb := func() -> void:
		if nuit:
			M.talk(parent, "Chut… Ils dorment tous sur les fleurs, les ailes fermées. Le petit aussi : il s'est endormi en comptant." if boy else "Chut… Ils dorment tous sur les fleurs, les ailes fermées. La petite aussi : elle s'est endormie en comptant.",
				[{"id": "fleurs", "label": "Pourquoi sur les fleurs ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if id == "fleurs":
					M.talk(parent, "Les fleurs gardent un peu de la chaleur du jour. Et au réveil, le petit-déjeuner est déjà servi. Malins, non ?", I._bye("Très malins. Bonne nuit…"), I._close(M), "à voix basse")
				else:
					M.close_talk()
			, "à voix basse")
			return
		var accueil: String = ("Bon vent ! Entre doucement : ici, on partage l'appartement avec %d colocataires. Aucun ne fait la vaisselle, mais ils sont très décoratifs." % nb) if _r(M).randf() < 0.5 else "Bonjour ! Attention à la tête… enfin, aux ailes. Bienvenue dans la chambre aux papillons !"
		M.talk(parent, accueil, [{"id": "ou", "label": "D'où viennent-ils ?"}, {"id": "approcher", "label": "Comment les approcher ?"}, {"id": "combien", "label": "Combien sont-ils, vraiment ?"}, {"id": "fermer", "label": "Bon vent !"}], func(id):
			match id:
				"ou":
					M.talk(parent, "Des Serres d'Altitude ! Flora Verdine nous a confié une boîte de chrysalides du troisième dôme. Là-bas, ils faisaient grève. Ici, ils sont en vacances. Pour toujours, je crois.",
						I._bye("Bonnes vacances, les papillons !"), I._close(M), "les mains dans la terre")
				"approcher":
					M.talk(parent, "Tends la main, bien à plat, et ne bouge plus. Ils viennent toujours voir les gens calmes. Et un peu ceux qui ont mangé de la confiture.",
						I._bye("Je vais essayer !"), I._close(M), "les mains dans la terre")
				"combien":
					M.talk(parent, ("Exactement %d. Mais chut ! Ne le dis pas au petit : il compte depuis trois semaines, c'est son jeu préféré." if boy else "Exactement %d. Mais chut ! Ne le dis pas à la petite : elle compte depuis trois semaines, c'est son jeu préféré.") % nb,
						I._bye("Promis, motus !"), I._close(M), "les mains dans la terre")
				_:
					M.close_talk()
		, "les mains dans la terre")
	M.talk_spot(parent, parent_cb)
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Sur les fleurs de la serre, des dizaines de papillons dorment, les ailes fermées. Sur le canapé, un enfant dort aussi.",
			"Tout est immobile. Les papillons se sont posés sur les fleurs pour la nuit, comme des pétales en plus. Seule la fontaine murmure.",
			"Il fait nuit dans la chambre aux papillons. Ils dorment tous sur les fleurs… et l'enfant, sur le canapé, compte encore en rêvant."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Des papillons ! Des dizaines, de toutes les couleurs, qui volent en rond sous le plafond. Au fond, une petite serre de verre déborde de fleurs.",
			"Un papillon bleu passe devant ton nez, puis un jaune, puis vingt autres. Au milieu de la pièce, un enfant compte à voix haute… et recommence.",
			"Ça sent les fleurs et la terre mouillée. Dans un coin, une serre de verre et sa petite fontaine ; partout ailleurs, des papillons."]))
