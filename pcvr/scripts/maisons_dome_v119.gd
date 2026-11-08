extends RefCounted
## V119 : les histoires des maisons du Dôme d'Azur, la ville au fond de la mer (maisons_v81 ; style « dome » :
## les maisons-bulles et les tours-coquillages : murs de nacre, terrazzo, titane, diodes aigue-marine, des
## hublots qui donnent sur la mer profonde, une porte de verre).
## En plus des histoires communes (maisons_scenes_v81), six histoires à elles : le poisson-lanterne du soir,
## la boîte à ciel, le poulpe évadé, la grand-mère qui chante avec la baleine, le bathyscaphe de la
## baignoire, le potager sous les lampes roses.
## Chaque histoire : ses meubles, ses gens (et leur nuit : on dort, on chuchote), ce qui bouge (un seul
## M.ctx["tick"] par maison), ce qu'on y fait, et ce dont la maison se souvient (M.state() : une
## récompense une seule fois).
## M : maisons_v81 ; S : maisons_scenes_v81 (les aides communes) ; I : maisons_iles_v82 (_part, _node…).

const S = preload("res://scripts/maisons_scenes_v81.gd")
const I = preload("res://scripts/maisons_iles_v82.gd")

## [id, poids, {style: [styles où elle peut arriver]}]
const SCENARIOS := [
	["da_lanterne", 11, {"style": ["dome"]}], ["da_boite", 12, {"style": ["dome"]}], ["da_poulpe", 11, {"style": ["dome"]}],
	["da_chanteuse", 11, {"style": ["dome"]}], ["da_baignoire", 10, {"style": ["dome"]}], ["da_potager", 10, {"style": ["dome"]}],
]

static var _rond: Texture2D


static func has(sc: String) -> bool:
	for e in SCENARIOS:
		if str(e[0]) == sc:
			return true
	return false


static func build(M, sc: String) -> void:
	_matieres(M)
	match sc:
		"da_lanterne":
			_lanterne(M)
		"da_boite":
			_boite(M)
		"da_poulpe":
			_poulpe(M)
		"da_chanteuse":
			_chanteuse(M)
		"da_baignoire":
			_baignoire(M)
		"da_potager":
			_potager(M)


# =================================================================== aides

static func _r(M) -> RandomNumberGenerator:
	return M.ctx["rng"]


static func _pick(M, a: Array) -> Variant:
	return a[_r(M).randi() % a.size()]


## Toujours dans la même pièce ? (après un délai, on a pu sortir… ou entrer dans une autre maison)
static func _la(M, room0) -> bool:
	return is_instance_valid(room0) and M.inside and M.room == room0


## La nuit des Strates (le Soleil de Laiton baisse sa lampe : avant 7 h, après 21 h) : on dort, on chuchote.
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


## Pas d'ombre (ce qui bouge près de la lampe ferait des ombres géantes sur les murs).
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

## Un tableau de la maison (R.pal["tableaux"] : ceux du style « strates »), cadre fin.
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


## Les matières en plus des Strates (les verts des plantes, pour _pot ; le feutre et la route des
## maquettes ; le charbon). Une seule fois par pièce.
static func _matieres(M) -> void:
	var R = M.R
	if R.kit.mats.has("nu_vert"):
		return
	R._put("nu_vert", R._col(Color(0.3, 0.52, 0.27), 0.8))
	R._put("nu_vert_clair", R._col(Color(0.48, 0.66, 0.32), 0.8))
	R._put("st_feutre", R._col(Color(0.24, 0.42, 0.22), 1.0))
	R._put("st_route", R._col(Color(0.42, 0.4, 0.38), 0.95))
	R._put("st_charbon", R._col(Color(0.07, 0.07, 0.08), 0.6))


## Le poisson-lanterne du soir (V119) : une famille du Dôme a un grand hublot rond dans son salon, une
## banquette dessous. Chaque soir, le même petit poisson-lanterne (gros yeux, dents pointues mais gentilles,
## une lumière vert d'eau au bout de son antenne) vient se coller au verre. La famille lui a donné un nom ;
## l'enfant lui fait des signes avec une lampe de poche posée sur un trépied (il répond en clignotant, le
## même nombre de fois… ou une de plus, pour avoir le dernier mot) ; un carnet compte ses visites, et le mur
## est couvert de ses portraits.
## Le jour, il n'est pas là : on attend, on prépare (on astique le hublot, l'enfant dessine ; parfois un
## poisson-hachette passe, « ce n'est pas lui ») ; le soir, il arrive du fond (une petite lumière qui
## grandit), fait parfois un tour et revient ; la nuit, l'enfant dort dans son fauteuil face au hublot, et
## le poisson veille, comme une veilleuse. Ce dont la maison se souvient : « la_vitre » (le hublot astiqué :
## une limonade bleue), « la_lanterne » (il vous a répondu : un dessin en carte postale et un chocolat des
## abysses), « la_note » (on a écrit sa visite dans le carnet).
static func _lanterne(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var nuit: bool = _nuit(M)
	var soir: bool = nuit or float(M.ctx["hour"]) >= 18.0
	var ni: int = r.randi() % 3
	var boy: bool = r.randf() < 0.5
	var pere: bool = r.randf() < 0.5
	var nv: int = 1000 + r.randi() % 95
	var nd: int = 40 + r.randi() % 60
	_lanterne_mats(M)
	# le grand hublot au milieu du mur du fond (dans une grande pièce, le petit hublot du fond est à
	# gauche : le grand se met à droite du milieu)
	var s: float = 1.0 if (R.W > 7.5 or r.randf() < 0.5) else -1.0
	var hx: float = s * 0.25
	var hy: float = 1.45
	var rr: float = 0.78
	var fond: float = -hd + 0.02
	R.mark_wall(hx, hy, fond, 1.0)
	# la banquette du guet, sous le hublot : nacre, coussins aigue-marine, une diode au pied
	var bz: float = -hd + 0.25
	R.kit.box(R.L(hx, 0.2, bz), Vector3(1.6, 0.4, 0.46), "ceramique", 1.0)
	R.kit.box(R.L(hx, 0.44, bz + 0.01), Vector3(1.5, 0.08, 0.4), "tissu_turquoise", 1.0)
	R.kit.box(Transform3D(Basis(Vector3.RIGHT, -0.25), R.P(hx - 0.5, 0.6, bz - 0.12)), Vector3(0.36, 0.26, 0.1), "tissu_blanc", 1.0)
	R.kit.box(Transform3D(Basis(Vector3.RIGHT, -0.25), R.P(hx + 0.5, 0.6, bz - 0.12)), Vector3(0.36, 0.26, 0.1), "tissu_bleu", 1.0)
	R.kit.box(R.L(hx, 0.05, bz + 0.235), Vector3(1.56, 0.015, 0.01), "la_diode", 1.0)
	R.kit.col_box(R.L(hx, 0.2, bz), Vector3(1.6, 0.4, 0.46))
	R.reserve(hx, bz, 1.8, 0.7)
	# le hublot : la mer derrière, un tunnel de titane, un gros cadre boulonné, un anneau de diodes, le verre
	var hub: Node3D = I._node(M, R.P(hx, hy, -hd), 0.0)
	var mer_m := StandardMaterial3D.new()
	mer_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mer_m.albedo_color = Color(0.01, 0.04, 0.1) if nuit else (Color(0.02, 0.07, 0.16) if soir else Color(0.05, 0.22, 0.34))
	var rot_z := Vector3(PI * 0.5, 0, 0)
	_p(hub, I._cyl(rr, rr, 0.01, 40), mer_m, Vector3(0, 0, 0.03), Vector3.ONE, rot_z)
	if not soir:
		# un peu de la Grande Perle, tout là-haut, qui éclaire l'eau
		var lueur_m := StandardMaterial3D.new()
		lueur_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		lueur_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lueur_m.albedo_texture = _tache()
		lueur_m.albedo_color = Color(0.5, 0.8, 0.95, 0.35)
		var lq := QuadMesh.new()
		lq.size = Vector2(1.1, 0.8)
		_p(hub, lq, lueur_m, Vector3(0.1, 0.45, 0.036))
	var tunnel := CylinderMesh.new()
	tunnel.top_radius = rr + 0.01
	tunnel.bottom_radius = rr + 0.01
	tunnel.height = 0.32
	tunnel.radial_segments = 40
	tunnel.cap_top = false
	tunnel.cap_bottom = false
	var titane := _mat(Color(0.8, 0.83, 0.87), 0.85, 0.3)
	titane.cull_mode = BaseMaterial3D.CULL_DISABLED
	_p(hub, tunnel, titane, Vector3(0, 0, 0.17), Vector3.ONE, rot_z)
	var cadre := TorusMesh.new()
	cadre.inner_radius = rr - 0.01
	cadre.outer_radius = rr + 0.13
	cadre.rings = 40
	_p(hub, cadre, R.kit.mats["argent"], Vector3(0, 0, 0.33), Vector3(1, 0.6, 1), rot_z)
	var diode_t := TorusMesh.new()
	diode_t.inner_radius = rr + 0.13
	diode_t.outer_radius = rr + 0.155
	diode_t.rings = 40
	_p(hub, diode_t, _mat(Color(0.35, 0.95, 0.88), 0.0, 0.4, 2.2 if soir else 1.2), Vector3(0, 0, 0.31), Vector3.ONE, rot_z)
	var boulon: SphereMesh = I._sph(0.022)
	for k in range(12):
		var a: float = TAU * k / 12.0
		_p(hub, boulon, R.kit.mats["argent"], Vector3(cos(a) * (rr + 0.06), sin(a) * (rr + 0.06), 0.37))
	_p(hub, I._cyl(rr, rr, 0.006, 40), _verre(Color(0.75, 0.9, 1.0), 0.1), Vector3(0, 0, 0.3), Vector3.ONE, rot_z)
	# la neige marine qui tombe doucement derrière le verre
	var neige := CPUParticles3D.new()
	neige.amount = 36
	neige.lifetime = 9.0
	neige.preprocess = 9.0
	neige.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	neige.emission_box_extents = Vector3(0.45, 0.02, 0.09)
	neige.direction = Vector3.DOWN
	neige.spread = 20.0
	neige.initial_velocity_min = 0.06
	neige.initial_velocity_max = 0.11
	neige.gravity = Vector3(0, -0.004, 0)
	var nq := QuadMesh.new()
	nq.size = Vector2(0.012, 0.012)
	var nm := StandardMaterial3D.new()
	nm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	nm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	nm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	nm.albedo_texture = _tache()
	nm.albedo_color = Color(0.85, 0.95, 1.0, 0.7)
	nq.material = nm
	neige.mesh = nq
	hub.add_child(neige)
	neige.position = Vector3(0, 0.6, 0.14)
	# le jour, des traces de doigts sur le verre (il faut astiquer avant ce soir) ; un reflet pour le coup de chiffon
	var traces: Array = []
	if not soir:
		for k2 in range(5):
			var tm := _verre(Color(1, 1, 1), 0.32)
			tm.albedo_texture = _tache()
			var tq := QuadMesh.new()
			tq.size = Vector2(0.16, 0.16) * r.randf_range(0.8, 1.3)
			var a2: float = r.randf() * TAU
			var d2: float = r.randf_range(0.0, 0.5)
			_p(hub, tq, tm, Vector3(cos(a2) * d2, sin(a2) * d2 - 0.15, 0.306))
			traces.append(tm)
	var reflet_m := _verre(Color(1, 1, 1), 0.0, 1.2)
	var rq := QuadMesh.new()
	rq.size = Vector2(0.08, 0.9)
	var reflet: MeshInstance3D = _p(hub, rq, reflet_m, Vector3(-0.42, 0, 0.308), Vector3.ONE, Vector3(0, 0, 0.5))
	_sans_ombre(hub)
	# le poisson-lanterne, et le poisson-hachette qui passe parfois le jour (« ce n'est pas lui »)
	var pz: Dictionary = _lanterne_poisson(M, hub)
	var fish: Node3D = pz["n"]
	var leurre_m: StandardMaterial3D = pz["leurre_m"]
	var lum: OmniLight3D = pz["lum"]
	var halo: Node3D = pz["halo"]
	var hache: Node3D = _lanterne_hachette(hub)
	hache.visible = false
	# la lampe de poche sur son trépied (« sinon, ça tremble, et il ne comprend rien »), tournée vers le verre
	var tx: float = hx + s * 0.5
	var tz: float = -hd + 1.0
	for k3 in range(3):
		var a3: float = TAU * k3 / 3.0 + 0.3
		var pied: Vector3 = R.P(tx + cos(a3) * 0.2, 0.0, tz + sin(a3) * 0.2)
		var haut: Vector3 = R.P(tx, 0.88, tz)
		var jambe := MeshInstance3D.new()
		jambe.mesh = I._cyl(0.008, 0.008, 1.0, 6)
		jambe.material_override = R.kit.mats["argent"]
		M.room.add_child(jambe)
		_tendre(jambe, pied, haut)
	var torche: Node3D = I._node(M, R.P(tx, 0.95, tz), 0.0)
	var cible_verre: Vector3 = R.P(hx, hy - 0.05, -hd + 0.3)
	torche.look_at(cible_verre, Vector3.UP)
	_p(torche, I._cyl(0.028, 0.028, 0.16, 12), _mat(Color(0.2, 0.55, 0.62), 0.3, 0.4), Vector3(0, 0, 0.08), Vector3.ONE, rot_z)
	_p(torche, I._cyl(0.044, 0.03, 0.05, 14), R.kit.mats["argent"], Vector3(0, 0, -0.01), Vector3.ONE, rot_z)
	var lentille_m := _mat(Color(0.95, 0.97, 1.0), 0.0, 0.2, 0.3)
	_p(torche, I._cyl(0.038, 0.038, 0.006, 14), lentille_m, Vector3(0, 0, -0.036), Vector3.ONE, rot_z)
	_p(torche, I._cyl(0.012, 0.012, 0.05, 6), R.kit.mats["argent"], Vector3(0, -0.04, 0.05))
	var bm := CylinderMesh.new()
	bm.bottom_radius = 0.035
	bm.top_radius = 0.2
	bm.height = 1.0
	bm.radial_segments = 16
	bm.cap_top = false
	bm.cap_bottom = false
	var faisceau := MeshInstance3D.new()
	faisceau.mesh = bm
	var fm := _verre(Color(0.92, 0.97, 1.0), 0.16, 1.5)
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	faisceau.material_override = fm
	faisceau.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	M.room.add_child(faisceau)
	_tendre(faisceau, torche.global_position + (cible_verre - torche.global_position).normalized() * 0.04, cible_verre)
	faisceau.visible = false
	var eclair := OmniLight3D.new()
	eclair.light_color = Color(0.92, 0.96, 1.0)
	eclair.light_energy = 0.0
	eclair.omni_range = 1.4
	eclair.shadow_enabled = false
	M.room.add_child(eclair)
	eclair.global_position = cible_verre + Vector3(0, 0, 0.25)
	R.reserve(tx, tz, 0.55, 0.55)
	# le fauteuil du guet, face au hublot
	var fx: float = hx - s * 0.35
	var fz: float = -hd + 1.9
	R.fauteuil(fx, fz, 180, str(_pick(M, ["blanc", "creme", "turquoise"])))
	if nuit:
		R.kit.box(R.L(fx + 0.36, 0.68, fz + 0.05, 8), Vector3(0.16, 0.05, 0.6), "tissu_bleu", 1.0)
	# les portraits du poisson sur le mur (deux rangées de dessins d'enfant : un rond sombre, une lumière verte)
	var dx: float = hx + s * 1.5
	R.mark_wall(dx, 1.5, fond, 0.5)
	for row in range(2):
		for i in range(3):
			var ax: float = dx + (i - 1) * 0.28 + r.randf_range(-0.03, 0.03)
			var ay: float = 1.36 + row * 0.24 + r.randf_range(-0.02, 0.02)
			var tilt: float = r.randf_range(-8.0, 8.0)
			var dxf: Transform3D = R.L(ax, ay, fond + 0.004) * Transform3D(Basis(Vector3.BACK, deg_to_rad(tilt)), Vector3.ZERO)
			R.kit.box(dxf, Vector3(0.22, 0.16, 0.006), "papier", 1.0)
			R.kit.box(dxf * Transform3D(Basis(), Vector3(0.01, -0.015, 0.005)), Vector3(0.08, 0.055, 0.004), "la_encre", 1.0)
			R.kit.box(dxf * Transform3D(Basis(), Vector3(-0.045, 0.045, 0.005)), Vector3(0.018, 0.018, 0.004), "la_lueur", 1.0)
	# le guéridon de nacre, de l'autre côté : le carnet des visites, son crayon, un petit corail
	var gx: float = hx - s * 1.45
	var gz: float = -hd + 0.55
	R.kit.cyl(R.L(gx, 0.66, gz), 0.3, 0.3, 0.04, "ceramique", 24)
	R.kit.cyl(R.L(gx, 0.0, gz), 0.03, 0.03, 0.66, "argent", 8, false)
	R.kit.cyl(R.L(gx, 0.0, gz), 0.2, 0.22, 0.03, "argent", 16)
	R.kit.col_box(R.L(gx, 0.35, gz), Vector3(0.45, 0.7, 0.45))
	R.reserve(gx, gz, 0.65, 0.65)
	R.kit.box(R.L(gx - 0.04, 0.712, gz + 0.04, 12), Vector3(0.22, 0.025, 0.16), "tissu_turquoise", 1.0)
	R.kit.box(R.L(gx - 0.04, 0.726, gz + 0.04, 12), Vector3(0.2, 0.006, 0.145), "papier", 1.0)
	R.kit.box(R.L(gx + 0.06, 0.733, gz + 0.06, -30), Vector3(0.012, 0.012, 0.14), "argent", 1.0)
	R.kit.cyl(R.L(gx + 0.15, 0.7, gz - 0.1), 0.04, 0.035, 0.07, "ceramique", 10)
	for k4 in range(5):
		var a4: float = TAU * k4 / 5.0 + r.randf()
		var cxf: Transform3D = R.L(gx + 0.15, 0.76, gz - 0.1) * Transform3D(Basis(Vector3.UP, a4) * Basis(Vector3.RIGHT, r.randf_range(0.2, 0.6)), Vector3.ZERO)
		R.kit.cyl(cxf, 0.008, 0.004, 0.13, "la_corail", 5, false)
	# le canapé, de biais, tourné vers le hublot ; la table basse et ses tasses ; le lampadaire
	var cx: float = -s * (hw - 1.0)
	var cz: float = clampf(-hd + 2.5, -hd + 1.4, hd - 2.2)
	var cyaw: float = _vers(cx, cz, hx, -hd + 0.5)
	R.canape(cx, cz, cyaw, str(_pick(M, ["blanc", "creme", "gris", "bleu"])))
	R.reserve(cx, cz, 1.8, 1.8)
	var cb: Basis = Basis(Vector3.UP, deg_to_rad(cyaw))
	var fwd: Vector3 = cb * Vector3(0, 0, 1)
	var tbx: float = cx + fwd.x * 1.05
	var tbz: float = cz + fwd.z * 1.05
	if R.is_free(tbx, tbz, 0.6, 0.6):
		_table_basse(M, tbx, tbz, 0.6, 0.6)
		for k5 in range(2):
			var mx: float = tbx - 0.12 + k5 * 0.22
			var mz: float = tbz + (0.08 if k5 == 0 else -0.1)
			R.kit.cyl(R.L(mx, 0.38, mz), 0.04, 0.035, 0.08, "ceramique", 10)
			R.kit.cyl(R.L(mx, 0.455, mz), 0.034, 0.034, 0.005, "chocolat", 10)
	var lpx: float = -s * (hw - 0.45)
	var lpz: float = clampf(cz + 1.35, -hd + 0.5, hd - 1.7)
	if not R.is_free(lpx, lpz, 0.45, 0.45):
		lpz = clampf(cz - 1.35, -hd + 0.5, hd - 1.7)
	var lampadaire: bool = R.is_free(lpx, lpz, 0.45, 0.45)
	if lampadaire:
		_lampadaire(M, lpx, lpz)
	for c in [[s * (hw - 0.5), -hd + 0.5], [s * (hw - 0.5), hd - 2.0], [-s * (hw - 0.5), -hd + 0.5]]:
		if R.is_free(float(c[0]), float(c[1]), 0.45, 0.45):
			_pot(M, float(c[0]), float(c[1]), 0.0, 1.0, "la_corail" if r.randf() < 0.5 else "")
	_cadres(M, 1)
	# les lumières du salon (on les tamise le soir, pour mieux se voir ; la nuit, elles sont déjà basses)
	var lums: Array = []
	for l in R.lights:
		if l is Light3D:
			lums.append([l, (l as Light3D).light_energy])
	if nuit:
		for e in lums:
			(e[0] as Light3D).light_energy = float(e[1]) * 0.35
	# les gens : le parent sur le canapé (le jour il tricote, le soir il regarde) ; l'enfant au mur de
	# dessins le jour, au hublot le soir ; la nuit, l'enfant dort dans le fauteuil du guet, le parent veille
	var seat: Vector3 = Vector3(cx, 0, cz) + cb * Vector3(0.45, 0, 0.05)
	var parent: Node
	var kid: Node
	if nuit:
		var npx: Vector2 = _dedans(M, fx - s * 0.85, fz + 0.3)
		parent = M.person("homme" if pere else "femme", npx.x, npx.y, _vers(npx.x, npx.y, fx, fz), "mains_dos")
		parent.lines = ["Chut… ils veillent tous les deux. Enfin, lui, il veille.", "Il reste jusqu'à ce que la Perle redevienne dorée.", "Tout doux. Sa petite lumière, c'est notre veilleuse.",
			"Il s'est endormi en comptant les clignotements." if boy else "Elle s'est endormie en comptant les clignotements."]
		parent.line_every = Vector2(10.0, 15.0)
		kid = M.person("garcon" if boy else "fille", fx, fz - 0.05, 180, "dormir_assis")
		kid.lines = ["Zzz… encore un… clignotement… zzz…", ["Mmh… Lumignon… bonne nuit… zzz…", "Mmh… Falot… bonne nuit… zzz…", "Mmh… Pistache… bonne nuit… zzz…"][ni], "Zzz… trois longs… un court… zzz…"]
		kid.line_every = Vector2(9.0, 14.0)
	elif soir:
		parent = M.person("homme" if pere else "femme", seat.x, seat.z, cyaw, "assis")
		parent.lines = ["Il est pile à l'heure. Plus ponctuel que la Ligne !", "Chut, laissons-les se parler.", "Trois ans qu'il vient. On ne sait pas où il passe ses journées.", "Qui veut encore du chocolat ?"]
		parent.line_every = Vector2(9.0, 14.0)
		var kx: float = hx - s * 0.6
		var kz: float = -hd + 0.85
		kid = M.person("garcon" if boy else "fille", kx, kz, _vers(kx, kz, hx, -hd), "debout")
		kid.lines = ["Bonsoir ! Bonnes bulles !", "Regarde, il cligne ! Ça veut dire bonjour.", "Tu as vu ses dents ? Il sourit.",
			"Il a grossi, non ? Papa dit que c'est le verre." if pere else "Il a grossi, non ? Maman dit que c'est le verre."]
		kid.line_every = Vector2(7.0, 11.0)
	else:
		parent = M.person("homme" if pere else "femme", seat.x, seat.z, cyaw, "tricot")
		parent.lines = ["Je tricote une couverture pour les soirs de veille. Près du hublot, ça rafraîchit.", "Tous les soirs depuis trois ans. Même les jours de grande marée.",
			"Pas de doigts pleins de confiture sur le verre, s'il te plaît !", "Il faudra racheter des piles pour la lampe."]
		parent.line_every = Vector2(10.0, 15.0)
		kid = M.person("garcon" if boy else "fille", dx, -hd + 0.75, 180, "peindre")
		kid.lines = ["Ce soir, je lui montre mon nouveau signal : trois longs, un court.", "Il vient quand la Perle devient violette. C'est encore loin, ce soir ?",
			"J'ai dessiné ses dents. Il en a beaucoup, mais elles sont gentilles.", ["Lumignon, c'est moi qui ai choisi son nom. À cause de sa lumière.", "Falot, c'est moi qui ai choisi son nom. À cause de sa lumière.", "Pistache, c'est moi qui ai choisi son nom. À cause de sa lumière."][ni]]
		kid.line_every = Vector2(7.0, 11.0)
	# l'état : ce que fait le poisson ; le dialogue de lumière (la lampe, puis lui)
	var arrive: bool = soir and not nuit and r.randf() < 0.5
	var st := {"t": r.randf() * 20.0, "mode": "absent", "d": 0.0, "x": 0.15, "y": 0.2, "tour": r.randf_range(50.0, 80.0), "attente": 0.0,
		"colle": 0.0, "yaw": 0.0, "hache": r.randf_range(8.0, 16.0), "hp": -1.0, "hdir": 1.0, "hy": 0.0, "auto": r.randf_range(25.0, 40.0),
		"sombre": nuit, "propre": false}
	if soir:
		st["mode"] = "arrive" if arrive else "la"
		st["d"] = 0.0 if arrive else 0.8
		st["x"] = 0.15 if arrive else 0.0
		st["y"] = 0.2 if arrive else 0.0
	var sig := {"etat": "", "n": 0, "m": 0, "k": 0, "t": 0.0, "on": false, "par": ""}
	fish.visible = soir
	var lampe := func(on: bool) -> void:
		lentille_m.emission_energy_multiplier = 6.0 if on else 0.3
		faisceau.visible = on
		eclair.light_energy = 1.6 if on else 0.0
	# la récompense : il vous a répondu (le soir : l'enfant ; la nuit : le parent, tout bas)
	var recompense := func() -> void:
		if bool(M.state().get("la_lanterne", false)):
			return
		M.state()["la_lanterne"] = true
		if nuit:
			var tn: String = "Il vous a répondu… Il ne répond pas à n'importe qui. Tenez, tout bas : un dessin de mon fils, en carte postale. Et un chocolat des abysses, pour la veille." if boy else "Il vous a répondu… Il ne répond pas à n'importe qui. Tenez, tout bas : un dessin de ma fille, en carte postale. Et un chocolat des abysses, pour la veille."
			M.talk(parent, tn, I._bye("Merci… Bonne nuit."), func(_i):
				M.give([["carte_postale", 1], ["chocolat_abysses", 1]], "")
				M.close_talk(), "à voix basse")
			return
		var tk: String = ["Il t'a répondu ! Il ne répond pas à tout le monde, tu sais. Tiens : mon dessin de Lumignon, en carte postale. Et un chocolat des abysses : c'est ce qu'on boit pendant la veille.",
			"Il t'a répondu ! Il ne répond pas à tout le monde, tu sais. Tiens : mon dessin de Falot, en carte postale. Et un chocolat des abysses : c'est ce qu'on boit pendant la veille.",
			"Il t'a répondu ! Il ne répond pas à tout le monde, tu sais. Tiens : mon dessin de Pistache, en carte postale. Et un chocolat des abysses : c'est ce qu'on boit pendant la veille."][ni]
		M.talk(kid, tk, I._bye("Merci ! Bonnes bulles !"), func(_i):
			M.give([["carte_postale", 1], ["chocolat_abysses", 1]], "")
			M.close_talk(), "aux anges")
	# la fin d'une réponse : on compte les clignotements
	var reagir := func() -> void:
		var n: int = int(sig["n"])
		var m: int = int(sig["m"])
		st["colle"] = 6.0
		if nuit:
			parent.say("Il a répondu… Tout doucement, pour ne pas réveiller le petit." if boy else "Il a répondu… Tout doucement, pour ne pas réveiller la petite.", 4.0)
		else:
			kid.gesture("joie", 1.8)
			if m > n:
				kid.say("Il en a fait un de plus ! Il veut toujours avoir le dernier mot.", 3.5)
			else:
				kid.say(str(LANTERNE_COMPTE[clampi(m - 1, 0, LANTERNE_COMPTE.size() - 1)]), 3.0)
		if str(sig["par"]) == "joueur":
			recompense.call()
	var signaler := func(par: String) -> void:
		if str(sig["etat"]) != "":
			return
		sig["etat"] = "torche"
		sig["n"] = 2 + randi() % 3
		sig["k"] = 0
		sig["t"] = 0.15
		sig["on"] = false
		sig["par"] = par
	# ce qui bouge : le poisson (il arrive du fond, nage devant le verre, s'y colle, fait un tour), sa
	# lumière qui palpite et répond, la lampe de poche ; le jour, le poisson-hachette qui passe
	var corps: Node3D = pz["corps"]
	var queue: Node3D = pz["queue"]
	var tige: Node3D = pz["tige"]
	var bouche: Node3D = pz["bouche"]
	var nageoires: Array = pz["nageoires"]
	var hub_c: Vector3 = hub.global_position
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(fish) or not is_instance_valid(hub):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var pp: Vector3 = M.main._player_pos_v27()
		var mode: String = str(st["mode"])
		# --- le dialogue de lumière
		var etat: String = str(sig["etat"])
		var flash: float = -1.0
		if etat != "":
			sig["t"] = float(sig["t"]) - dt
			if float(sig["t"]) <= 0.0:
				match etat:
					"torche":
						if bool(sig["on"]):
							lampe.call(false)
							sig["on"] = false
							sig["k"] = int(sig["k"]) + 1
							sig["t"] = 0.28
							if int(sig["k"]) >= int(sig["n"]):
								sig["etat"] = "attente"
								sig["t"] = 1.0
						else:
							lampe.call(true)
							sig["on"] = true
							sig["t"] = 0.3
							M.main.sfx("ui_clic", torche.global_position)
					"attente":
						if mode == "la" and float(st["d"]) > 0.5:
							sig["etat"] = "reponse"
							sig["m"] = int(sig["n"]) + (1 if randf() < 0.3 else 0)
							sig["k"] = 0
							sig["on"] = false
							sig["t"] = 0.2
							M.main.sfx("bulles", hub_c)
						else:
							sig["etat"] = ""
							if not soir:
								kid.gesture("rire", 1.5)
								kid.say(str(_pick(M, ["Pas maintenant ! Il ne vient que le soir, quand la Perle devient violette.", "Personne… Normal : il dort encore, quelque part au fond.", "Garde des piles pour ce soir !"])), 3.5)
							elif mode == "tour":
								st["mode"] = "arrive"
								if not nuit:
									kid.say(str(_pick(M, ["Il t'a vu ! Il revient !", "Regarde, la petite lumière au fond ! Il fait demi-tour !"])), 3.0)
					"reponse":
						if bool(sig["on"]):
							sig["on"] = false
							sig["k"] = int(sig["k"]) + 1
							sig["t"] = 0.3
							if int(sig["k"]) >= int(sig["m"]):
								sig["etat"] = ""
								M.main.sfx("cristal_chante", hub_c)
								reagir.call()
						else:
							sig["on"] = true
							sig["t"] = 0.32
							M.main.sfx("clochette", hub_c)
			if str(sig["etat"]) == "reponse":
				flash = 1.0 if bool(sig["on"]) else 0.0
		# --- le poisson
		if mode == "absent":
			fish.visible = false
			lum.light_energy = 0.0
		else:
			fish.visible = true
			var d: float = float(st["d"])
			var colle: bool = float(st["colle"]) > 0.0 or bool(st["sombre"]) or Vector2(pp.x - hub_c.x, pp.z - hub_c.z).length() < 1.7
			st["colle"] = maxf(0.0, float(st["colle"]) - dt)
			var hx2: float = (0.08 if colle else 0.16) * sin(t * 0.37)
			var hy2: float = (0.04 if colle else 0.08) * sin(t * 0.53)
			var cx2: float = hx2
			var cy2: float = hy2
			match mode:
				"arrive":
					d = minf(0.8, d + dt * 0.12)
					cx2 = lerpf(0.15, hx2, d / 0.8)
					cy2 = lerpf(0.2, hy2, d / 0.8)
					if d >= 0.8:
						st["mode"] = "la"
						st["tour"] = randf_range(50.0, 80.0)
						M.main.sfx("bulles", hub_c)
						if not nuit:
							kid.gesture("joie", 1.8)
							kid.say(str(_pick(M, [["Le voilà ! Bonsoir, Lumignon !", "Le voilà ! Bonsoir, Falot !", "Le voilà ! Bonsoir, Pistache !"][ni], "Il est là ! Il revient toujours !", "Coucou ! Tu as vu, on a tout astiqué !"])), 3.0)
				"la":
					d = lerpf(d, 1.0 if colle else 0.8, 1.0 - exp(-dt * 1.2))
					if not nuit and str(sig["etat"]) == "":
						st["tour"] = float(st["tour"]) - dt
						if float(st["tour"]) <= 0.0:
							st["mode"] = "tour"
							st["attente"] = randf_range(5.0, 8.0)
							kid.say(str(_pick(M, ["Il va faire un tour. Il revient toujours.", "Oh… il part ? Non, il fait juste le tour du Dôme.", "À tout de suite !"])), 3.0)
				"tour":
					d = maxf(0.0, d - dt * 0.16)
					cx2 = lerpf(-0.25, hx2, d)
					cy2 = lerpf(0.15, hy2, d)
					if d <= 0.02:
						st["attente"] = float(st["attente"]) - dt
						if float(st["attente"]) <= 0.0:
							st["mode"] = "arrive"
			st["d"] = d
			var px: float = lerpf(float(st["x"]), cx2, 1.0 - exp(-dt * 1.5))
			var py: float = lerpf(float(st["y"]), cy2, 1.0 - exp(-dt * 1.5))
			st["x"] = px
			st["y"] = py
			var sc: float = lerpf(0.05, 1.0, pow(d, 1.4))
			fish.position = Vector3(px, py, lerpf(0.05, 0.15, d))
			fish.scale = Vector3.ONE * sc
			# il regarde le visiteur (ou s'en va de profil)
			var wp: Vector3 = fish.global_position
			var vise: float = clampf(atan2(pp.x - wp.x, pp.z - wp.z), -0.45, 0.45)
			if str(st["mode"]) == "tour":
				vise = -1.3
			elif str(st["mode"]) == "arrive" and d < 0.5:
				vise = 0.9
			st["yaw"] = lerp_angle(float(st["yaw"]), vise, clampf(dt * 2.0, 0.0, 1.0))
			fish.rotation = Vector3(0.06 * sin(t * 0.9), float(st["yaw"]), 0.05 * sin(t * 0.7))
			corps.position.y = 0.006 * sin(t * 2.0)
			queue.rotation.y = 0.45 * sin(t * (6.0 if str(st["mode"]) != "la" else 3.5))
			tige.rotation.x = -0.4 + 0.12 * sin(t * 1.3)
			bouche.scale = Vector3(1.0, 0.6 + 0.5 * (0.5 + 0.5 * sin(t * 1.1)), 1.0)
			for k6 in range(nageoires.size()):
				(nageoires[k6] as Node3D).rotation.z = (1.0 if k6 == 0 else -1.0) * (0.3 + 0.35 * sin(t * 7.0))
			# sa lumière : elle palpite (la nuit : lente, comme une veilleuse) ; quand il répond, elle clignote fort
			var b: float = 0.5 + 0.4 * sin(t * 0.8) if nuit else 0.75 + 0.25 * sin(t * 2.2)
			if bool(st["sombre"]):
				b *= 1.25
			if flash >= 0.0:
				b = 3.2 if flash > 0.5 else 0.08
			leurre_m.emission_energy_multiplier = 1.0 + 2.5 * b
			lum.light_energy = 0.9 * b * d
			halo.scale = Vector3.ONE * (0.6 + 0.5 * minf(b, 2.0))
		# --- le jour : parfois, un poisson-hachette passe (ce n'est pas lui)
		if not soir:
			if float(st["hp"]) < 0.0:
				st["hache"] = float(st["hache"]) - dt
				if float(st["hache"]) <= 0.0:
					st["hp"] = 0.0
					st["hdir"] = 1.0 if randf() < 0.5 else -1.0
					st["hy"] = randf_range(-0.3, 0.3)
					hache.visible = true
			else:
				var p0: float = float(st["hp"])
				var p1: float = p0 + dt / 7.0
				st["hp"] = p1
				var hd2: float = float(st["hdir"])
				hache.position = Vector3(hd2 * lerpf(-0.5, 0.5, p1), float(st["hy"]) + 0.03 * sin(t * 3.0), 0.12)
				hache.rotation.y = 0.0 if hd2 > 0.0 else PI
				hache.scale = Vector3.ONE * maxf(0.01, 0.75 * sin(PI * clampf(p1, 0.0, 1.0)))
				if p0 < 0.4 and p1 >= 0.4 and randf() < 0.6:
					kid.gesture("sursaut", 1.2)
					kid.say(str(_pick(M, [["Lumignon ?! … Ah non. C'est un poisson-hachette. Bonjour quand même.", "Falot ?! … Ah non. C'est un poisson-hachette. Bonjour quand même.", "Pistache ?! … Ah non. C'est un poisson-hachette. Bonjour quand même."][ni],
						"Fausse alerte : celui-là n'a pas de lumière.", "Pas lui. Lui, il a une lumière, et des dents."])), 3.5)
				if p1 >= 1.0:
					st["hp"] = -1.0
					st["hache"] = randf_range(15.0, 28.0)
					hache.visible = false
		# --- le soir : de temps en temps, l'enfant lui dit bonsoir avec la lampe
		elif not nuit:
			if str(sig["etat"]) == "" and str(kid.pose) == "pointer":
				kid.set_pose("debout", Vector3.ZERO)
			if str(st["mode"]) == "la" and str(sig["etat"]) == "":
				st["auto"] = float(st["auto"]) - dt
				if float(st["auto"]) <= 0.0:
					st["auto"] = randf_range(35.0, 55.0)
					kid.set_pose("pointer", Vector3.ZERO)
					kid.say(str(_pick(M, ["Je lui dis bonsoir. Regarde bien.", "Trois longs, un court. Ça veut dire : « Ça va ? »", "Attention… je clignote !"])), 3.0)
					signaler.call("enfant")
	# --- ce qu'on fait : la lampe de poche, le hublot à astiquer, le carnet, les lumières
	M.act(R.P(tx, 0, tz), "E : faire des signes avec la lampe de poche" if soir else "E : essayer la lampe de poche", func() -> void:
		if nuit:
			parent.say("Tout doucement, alors. Il ne faut pas réveiller le petit." if boy else "Tout doucement, alors. Il ne faut pas réveiller la petite.", 3.0)
		elif soir and str(st["mode"]) == "la":
			kid.say(str(_pick(M, ["Vas-y ! Il répond toujours. Compte bien !", "Pas trop vite, sinon il s'embrouille.", "Chut… regarde sa lumière."])), 2.5)
		signaler.call("joueur")
	, 1.1, func(): return str(sig["etat"]) == "")
	if not soir:
		var room0 = M.room
		M.act(R.P(hx - s * 0.4, 0, -hd + 0.9), "E : astiquer le hublot", func() -> void:
			st["propre"] = true
			M.main.sfx("verser", hub_c + Vector3(0, 0, 0.35))
			var tw: Tween = M.room.create_tween()
			tw.set_parallel(true)
			for tm2 in traces:
				tw.tween_property(tm2, "albedo_color:a", 0.0, 1.4)
			reflet.position.x = -0.42
			tw.tween_property(reflet_m, "albedo_color:a", 0.55, 0.3)
			tw.tween_property(reflet, "position:x", 0.42, 1.2).set_trans(Tween.TRANS_SINE)
			tw.tween_property(reflet_m, "albedo_color:a", 0.0, 0.4).set_delay(0.9)
			tw.chain().tween_callback(func() -> void:
				if not _la(M, room0):
					return
				M.main.sfx("carillon", hub_c + Vector3(0, 0, 0.35))
				_bulle(M, hub_c + Vector3(0.3, 0.5, 0.35), "✦", Color(0.85, 1.0, 1.0), 46, 0.4, 1.4)
				kid.say(str(_pick(M, ["Ce soir, il nous verra comme en plein jour !", "Les traces de doigts ? C'est les siennes ! … Bon, c'est les miennes.", "Il brille ! Le hublot, je veux dire."])), 3.5)
				if not bool(M.state().get("la_vitre", false)):
					M.state()["la_vitre"] = true
					M.talk(parent, "Merci ! Ce soir, il nous verra parfaitement. Tenez : une limonade bleue, pour la peine. On en garde toujours pour les soirs de visite.", I._bye("Merci !"), func(_i):
						M.give([["limonade_bleue", 1]], "")
						M.close_talk())
			)
		, 1.1, func(): return not bool(st["propre"]))
	M.act(R.P(gx, 0, gz), "E : écrire la visite de ce soir dans le carnet", func() -> void:
		M.state()["la_note"] = true
		M.main.sfx("ui_ouvrir", R.P(gx, 0.75, gz))
		M.say("Tu écris dans le carnet : « Visite n° %d. Il est venu, pile à l'heure. Il a cligné. Il avait l'air content. »" % nv, 7.0)
		if nuit:
			parent.say("Merci. On le lui montrera demain matin.", 3.0)
		else:
			kid.say(str(_pick(M, ["Tu as une belle écriture ! Enfin… on arrive à lire.", "Merci ! Moi, je fais les dessins.", "N'oublie pas l'heure ! Bon, tant pis."])), 3.0)
	, 1.2, func(): return soir and not bool(M.state().get("la_note", false)))
	M.act(R.P(gx, 0, gz), "E : lire le carnet des visites", func() -> void:
		M.main.sfx("ui_ouvrir", R.P(gx, 0.75, gz))
		if not soir:
			M.say(str(_pick(M, ["Le carnet des visites, plein de dessins et de petites croix. La dernière page dit : « Ce soir : visite n° %d. Penser aux piles. »" % nv,
				"Le carnet des visites. Visite n° %d : il est venu avec deux copains. Ils ont tous clignoté en même temps. On a applaudi. Eux aussi, je crois." % (nv - 12)])), 8.0)
			return
		M.say(str(_pick(M, ["Le carnet des visites. Visite n° %d : arrivé à 19 h 04. A répondu trois fois à la lampe. A fait une drôle de tête devant le chocolat." % (nv - 1),
			"Le carnet des visites. Visite n° %d : la Grande Chanteuse est passée au loin. Il s'est caché tout contre notre hublot. On lui a laissé la lumière." % (nv - 40),
			"Le carnet des visites. Visite n° 1 : un petit poisson avec une lampe sur la tête. Il nous regarde. On le regarde. Personne ne bouge. Il revient demain ?"])), 8.0)
	, 1.2, func(): return not soir or bool(M.state().get("la_note", false)))
	if soir:
		var tamiser := func(on: bool) -> void:
			st["sombre"] = on
			M.main.sfx("ui_clic", R.P(lpx, 1.2, lpz))
			var vives: Array = []
			for e2 in lums:
				if is_instance_valid(e2[0]):
					vives.append(e2)
			if vives.is_empty():
				return
			var tw2: Tween = M.room.create_tween()
			tw2.set_parallel(true)
			for e3 in vives:
				tw2.tween_property(e3[0], "light_energy", float(e3[1]) * (0.35 if on else 1.0), 1.2)
			if on and not nuit:
				kid.say(str(_pick(M, ["Oh oui ! Dans le noir, il nous voit mieux.", "Regarde comme il brille, maintenant !", "Il s'approche ! Il aime bien quand c'est tout doux."])), 3.0)
		var lp_at: Vector3 = R.P(lpx, 0, lpz) if lampadaire else R.P(cx, 0, cz)
		M.act(lp_at, "E : tamiser les lumières", func(): tamiser.call(true), 1.2, func(): return not bool(st["sombre"]))
		M.act(lp_at, "E : rallumer les lumières", func(): tamiser.call(false), 1.2, func(): return bool(st["sombre"]))
	# --- parler aux gens
	var parent_cb := func() -> void:
		if nuit:
			M.talk(parent, "Chut… Le petit dort devant le hublot. Il voulait attendre que notre poisson s'en aille. Mais le poisson attend toujours qu'il s'endorme." if boy else "Chut… La petite dort devant le hublot. Elle voulait attendre que notre poisson s'en aille. Mais le poisson attend toujours qu'elle s'endorme.",
				[{"id": "nuit", "label": "Il reste toute la nuit ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if id == "nuit":
					M.talk(parent, "Jusqu'à ce que la Perle redevienne dorée. Puis il redescend, tout doucement. Le matin, il ne reste qu'une petite trace de buée sur le verre.", I._bye("Chut… Bonne nuit !"), I._close(M), "à voix basse")
				else:
					M.close_talk()
			, "à voix basse")
			return
		if soir:
			M.talk(parent, "Bonsoir ! Il est là, vous avez vu ? Asseyez-vous, ou restez debout, mais pas devant la lumière : il est un peu timide.",
				[{"id": "pourquoi", "label": "Pourquoi vient-il chez vous ?"}, {"id": "tous", "label": "Il vient vraiment tous les soirs ?"}, {"id": "fermer", "label": "Bonne soirée !"}], func(id):
				match id:
					"pourquoi":
						M.talk(parent, "Le Professeur Benthos dit que c'est notre lampe qui l'attire. Mon fils dit que c'est parce qu'on est gentils. Moi, je crois qu'il aime regarder la télévision : la télévision, c'est nous." if boy else "Le Professeur Benthos dit que c'est notre lampe qui l'attire. Ma fille dit que c'est parce qu'on est gentils. Moi, je crois qu'il aime regarder la télévision : la télévision, c'est nous.",
							I._bye("Ha ha !"), I._close(M), "attendri")
					"tous":
						M.talk(parent, "Tous les soirs depuis trois ans. Sauf une fois, le soir où la Grande Chanteuse est passée. Le lendemain, il est revenu avec deux copains. C'est dans le carnet.", I._bye("Quelle fidélité !"), I._close(M), "attendri")
					_:
						M.close_talk()
			, "attendri")
			return
		M.talk(parent, "Bonnes bulles ! Vous tombez un peu tôt : notre invité ne vient que le soir. Mais vous pouvez nous aider à préparer.",
			[{"id": "qui", "label": "Quel invité ?"}, {"id": "preparer", "label": "Préparer quoi ?"}, {"id": "fermer", "label": "Bonnes bulles !"}], func(id):
			match id:
				"qui":
					M.talk(parent, ["Un poisson-lanterne. Il s'appelle Lumignon. Tous les soirs, depuis trois ans, il vient se coller à notre hublot. On ne sait pas pourquoi. On ne demande pas : c'est poli.",
						"Un poisson-lanterne. Il s'appelle Falot. Tous les soirs, depuis trois ans, il vient se coller à notre hublot. On ne sait pas pourquoi. On ne demande pas : c'est poli.",
						"Un poisson-lanterne. Il s'appelle Pistache. Tous les soirs, depuis trois ans, il vient se coller à notre hublot. On ne sait pas pourquoi. On ne demande pas : c'est poli."][ni], I._bye("C'est un bel invité."), I._close(M))
				"preparer":
					M.talk(parent, "Astiquer le hublot, pour qu'il nous voie bien. Vérifier les piles de la lampe. Et préparer le chocolat : lui, il n'en boit pas, mais nous, si.", I._bye("Je m'y mets !"), I._close(M))
				_:
					M.close_talk()
		)
	M.talk_spot(parent, parent_cb)
	var kid_cb := func() -> void:
		if nuit:
			M.talk(kid, "Zzz… trois clignotements… ça veut dire… je t'aime bien… zzz…", I._bye("(Le laisser dormir)") if boy else I._bye("(La laisser dormir)"), I._close(M), "endormi" if boy else "endormie")
			return
		if soir:
			M.talk(kid, ["C'est Lumignon ! On se parle avec la lampe : je clignote, il clignote. Je fais trois, il fait trois. Des fois, il fait quatre, pour avoir le dernier mot.",
				"C'est Falot ! On se parle avec la lampe : je clignote, il clignote. Je fais trois, il fait trois. Des fois, il fait quatre, pour avoir le dernier mot.",
				"C'est Pistache ! On se parle avec la lampe : je clignote, il clignote. Je fais trois, il fait trois. Des fois, il fait quatre, pour avoir le dernier mot."][ni],
				[{"id": "essayer", "label": "Je peux essayer ?"}, {"id": "ciel", "label": "Tu as déjà vu le ciel ?"}, {"id": "fermer", "label": "Bonne veille !"}], func(id):
				match id:
					"essayer":
						M.talk(kid, "Bien sûr ! La lampe est sur le trépied. Sinon, ça tremble, et il ne comprend rien. Et éteins les lumières du salon, il voit mieux.", I._bye("D'accord !"), I._close(M), "aux anges")
					"ciel":
						M.talk(kid, "Non, jamais. Mais lui non plus, il n'a jamais vu de canapé. Alors on est quittes. Un jour, je prendrai la Ligne, et je lui raconterai le ciel avec la lampe.", I._bye("Il aura hâte."), I._close(M), "rêveur" if boy else "rêveuse")
					_:
						M.close_talk()
			, "aux anges")
			return
		M.talk(kid, ["Ce soir, Lumignon vient ! Je lui fais un nouveau dessin pour le mur. Ça fera %d dessins." % nd, "Ce soir, Falot vient ! Je lui fais un nouveau dessin pour le mur. Ça fera %d dessins." % nd,
			"Ce soir, Pistache vient ! Je lui fais un nouveau dessin pour le mur. Ça fera %d dessins." % nd][ni],
			[{"id": "sur", "label": "Comment tu sais qu'il viendra ?"}, {"id": "fermer", "label": "Salut !"}], func(id):
			if id == "sur":
				M.talk(kid, "Il vient toujours. Quand la Grande Perle devient violette, je compte jusqu'à cent, et pouf : une petite lumière, tout au fond. Elle grandit, elle grandit… et c'est lui.", I._bye("J'aimerais voir ça."), I._close(M), "aux anges")
			else:
				M.close_talk()
		, "impatient" if boy else "impatiente")
	M.talk_spot(kid, kid_cb)
	# --- le texte d'entrée
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Un enfant dort dans un fauteuil, face au grand hublot. Derrière le verre, un petit poisson-lanterne veille ; sa lumière clignote tout doucement. Une veilleuse qui nage.",
			"Le salon est dans la pénombre, sauf une petite lueur verte contre le hublot : le poisson-lanterne est encore là. Quelqu'un te fait « chut » du doigt.",
			"Tout dort. Enfin, presque : derrière le grand hublot, une petite lumière se balance, patiente, au-dessus d'un enfant endormi."]))
	elif soir and arrive:
		M.ctx["entree"] = str(_pick(M, ["La Grande Perle vient de virer au violet. Derrière le grand hublot, tout au fond, une petite lumière s'allume… et grandit. Un enfant retient son souffle.",
			"Chut ! Toute la famille regarde le grand hublot. Là-bas, dans le noir, un point vert s'approche en dansant. Il arrive !"]))
	elif soir:
		M.ctx["entree"] = str(_pick(M, ["Collé au grand hublot, un petit poisson aux gros yeux et aux dents pointues balance sa lumière au bout d'une antenne. Un enfant lui fait des signes avec une lampe de poche. Il répond.",
			"Le salon baigne dans une lueur vert d'eau. Elle vient d'un tout petit poisson-lanterne, le nez contre le verre du hublot, qui regarde la famille comme on regarde la télévision."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Un grand hublot rond occupe le mur du salon. Derrière, la mer bleue, vide. Une lampe de poche attend sur son trépied. Ici, on attend quelqu'un.",
			"Le salon sent le chocolat chaud et le produit à vitres. Tout est tourné vers le grand hublot, comme une salle avant le spectacle. Le spectacle, c'est ce soir.",
			"À côté du grand hublot, des dizaines de dessins du même petit poisson, avec la même petite lumière au bout du nez. Il n'est pas là. Pas encore."]))


## Les noms que la famille a donnés à son poisson-lanterne (un par maison ; les phrases qui le nomment
## sont écrites en entier pour chacun).
const LANTERNE_NOMS := ["Lumignon", "Falot", "Pistache"]

## Ce que l'enfant compte quand le poisson répond.
const LANTERNE_COMPTE := ["Un ! Il a répondu un !", "Deux ! Il a répondu deux !", "Trois ! Il a répondu trois !", "Quatre ! Il a répondu quatre !", "Cinq ! Il a répondu cinq !"]


## Les matières du poisson-lanterne : la diode aigue-marine, l'encre et la lueur des dessins, le corail.
static func _lanterne_mats(M) -> void:
	var R = M.R
	if R.kit.mats.has("la_diode"):
		return
	R._put("la_diode", _mat(Color(0.35, 0.95, 0.88), 0.0, 0.4, 1.8))
	R._put("la_encre", R._col(Color(0.2, 0.16, 0.3), 0.9))
	R._put("la_lueur", _mat(Color(0.5, 1.0, 0.8), 0.0, 0.6, 1.2))
	R._put("la_corail", R._col(Color(0.98, 0.5, 0.45), 0.7))


## Le petit poisson-lanterne (face en +Z, vers la pièce) : un corps rond violet sombre, de gros yeux, une
## bouche pleine de petites dents, des nageoires, une queue, et son antenne avec la lumière au bout.
static func _lanterne_poisson(M, hub: Node3D) -> Dictionary:
	var n := Node3D.new()
	hub.add_child(n)
	var corps := Node3D.new()
	n.add_child(corps)
	var peau := _mat(Color(0.26, 0.18, 0.32), 0.1, 0.45, 0.12)
	var ventre := _mat(Color(0.42, 0.32, 0.45), 0.0, 0.5, 0.1)
	var boule: SphereMesh = I._sph(1.0)
	_p(corps, boule, peau, Vector3.ZERO, Vector3(0.12, 0.105, 0.1))
	_p(corps, boule, ventre, Vector3(0, -0.035, 0.02), Vector3(0.095, 0.07, 0.08))
	# les yeux
	var blanc := _mat(Color(0.95, 0.96, 0.92), 0.0, 0.2, 0.25)
	var noir := _mat(Color(0.02, 0.02, 0.04), 0.0, 0.1)
	for sx in [-1.0, 1.0]:
		_p(corps, I._sph(0.032), blanc, Vector3(sx * 0.052, 0.035, 0.07))
		_p(corps, I._sph(0.019), noir, Vector3(sx * 0.054, 0.037, 0.096))
		_p(corps, I._sph(0.006), blanc, Vector3(sx * 0.048, 0.045, 0.112))
	# la bouche, et ses petites dents pointues (mais gentilles)
	var bouche := Node3D.new()
	corps.add_child(bouche)
	bouche.position = Vector3(0, -0.035, 0.088)
	_p(bouche, boule, noir, Vector3.ZERO, Vector3(0.065, 0.022, 0.02))
	var dent: CylinderMesh = I._cyl(0.0, 0.006, 0.018, 4)
	for k in range(6):
		var dxk: float = -0.045 + k * 0.018
		_p(bouche, dent, blanc, Vector3(dxk, 0.012, 0.012), Vector3.ONE, Vector3(PI, 0, 0))
	# les nageoires et la queue
	var nageoires: Array = []
	var fin_m := _verre(Color(0.55, 0.4, 0.62), 0.75)
	for sx2 in [-1.0, 1.0]:
		var nag := Node3D.new()
		corps.add_child(nag)
		nag.position = Vector3(sx2 * 0.11, -0.01, 0.0)
		_p(nag, boule, fin_m, Vector3(sx2 * 0.03, 0, 0), Vector3(0.035, 0.008, 0.04))
		nageoires.append(nag)
	var queue := Node3D.new()
	corps.add_child(queue)
	queue.position = Vector3(0, 0, -0.09)
	_p(queue, boule, fin_m, Vector3(0, 0, -0.05), Vector3(0.008, 0.06, 0.055))
	# l'antenne (deux morceaux) et la lumière au bout
	var tige := Node3D.new()
	corps.add_child(tige)
	tige.position = Vector3(0, 0.09, 0.02)
	var tige_m := _mat(Color(0.3, 0.22, 0.36), 0.0, 0.5, 0.1)
	_p(tige, I._cyl(0.005, 0.007, 0.12, 6), tige_m, Vector3(0, 0.06, 0))
	var bout := Node3D.new()
	tige.add_child(bout)
	bout.position = Vector3(0, 0.12, 0)
	bout.rotation.x = 1.3
	_p(bout, I._cyl(0.004, 0.005, 0.07, 6), tige_m, Vector3(0, 0.035, 0))
	var leurre := Node3D.new()
	bout.add_child(leurre)
	leurre.position = Vector3(0, 0.075, 0)
	var leurre_m := _mat(Color(0.5, 1.0, 0.82), 0.0, 0.3, 2.5)
	_p(leurre, I._sph(0.022), leurre_m, Vector3.ZERO)
	var halo_m := StandardMaterial3D.new()
	halo_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	halo_m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	halo_m.albedo_texture = _tache()
	halo_m.albedo_color = Color(0.45, 1.0, 0.82, 0.7)
	var hq := QuadMesh.new()
	hq.size = Vector2(0.3, 0.3)
	var halo: MeshInstance3D = _p(leurre, hq, halo_m, Vector3.ZERO)
	var lum := OmniLight3D.new()
	lum.light_color = Color(0.45, 1.0, 0.82)
	lum.light_energy = 0.0
	lum.omni_range = 1.8
	lum.shadow_enabled = false
	leurre.add_child(lum)
	lum.position = Vector3(0, 0, 0.05)
	_sans_ombre(n)
	return {"n": n, "corps": corps, "queue": queue, "tige": tige, "bouche": bouche, "nageoires": nageoires, "leurre_m": leurre_m, "lum": lum, "halo": halo}


## Le poisson-hachette (face en +X) : tout plat, argenté, de gros yeux, pas de lumière. Ce n'est pas lui.
static func _lanterne_hachette(hub: Node3D) -> Node3D:
	var n := Node3D.new()
	hub.add_child(n)
	var argent := _mat(Color(0.8, 0.84, 0.9), 0.9, 0.25, 0.3)
	var boule: SphereMesh = I._sph(1.0)
	_p(n, boule, argent, Vector3.ZERO, Vector3(0.07, 0.055, 0.018))
	_p(n, boule, argent, Vector3(0.0, -0.035, 0.0), Vector3(0.05, 0.03, 0.014))
	var noir := _mat(Color(0.02, 0.02, 0.04), 0.0, 0.1)
	for sz in [-1.0, 1.0]:
		_p(n, I._sph(0.012), noir, Vector3(0.045, 0.012, sz * 0.014))
	_p(n, boule, _verre(Color(0.75, 0.82, 0.9), 0.6), Vector3(-0.08, 0, 0), Vector3(0.025, 0.03, 0.005))
	_sans_ombre(n)
	return n


# =================================================================== la boîte à ciel

## Le règlement de la boîte à ciel, sur le guéridon (chez Papi ; chez Mamie).
const BOITE_REGLEMENT := [
	"LE RÈGLEMENT DE LA BOÎTE À CIEL, en lettres bleues, au feutre : « Un : on ne met dedans que des morceaux de ciel. Deux : ils doivent être vrais, ou dessinés par quelqu'un qui l'a vu. Trois : on ne secoue pas la boîte (à cause du grêlon). Quatre : Papi a le droit de regarder quand il veut, même sans demander. »",
	"LE RÈGLEMENT DE LA BOÎTE À CIEL, en lettres bleues, au feutre : « Un : on ne met dedans que des morceaux de ciel. Deux : ils doivent être vrais, ou dessinés par quelqu'un qui l'a vu. Trois : on ne secoue pas la boîte (à cause du grêlon). Quatre : Mamie a le droit de regarder quand elle veut, même sans demander. »",
]

## La lumière du ciel en boîte (le bleu du couvercle peint).
const BOITE_BLEU := Color(0.55, 0.78, 1.0)


## La boîte à ciel. Un enfant du Dôme qui n'a jamais vu le ciel collectionne des « morceaux de ciel »
## dans une grande boîte de nacre (le dedans peint en bleu, un ciel peint sous le couvercle) : trois
## cartes postales d'en haut, une plume de mouette tombée par la Cheminée d'Air, un flacon d'« air de la
## surface », un bout de nuage dessiné (avec du vrai coton), un grêlon fondu dans un bocal (« il était
## froid »), une photo d'arc-en-ciel. Depuis que la Ligne a rouvert, il espère un nouveau morceau.
## On ouvre la boîte, on sort les morceaux un par un (chacun flotte au-dessus de la boîte, à sa façon :
## la plume se balance, le flacon luit, l'eau du bocal clapote, l'arc-en-ciel colore la lumière), on lui
## raconte le ciel (le bleu, le vent, la pluie, le soleil, les étoiles), et on lui donne une carte
## postale si on en a une (sinon, on en dessine une avec lui, sur son petit bureau) : le grand-parent,
## qui a grandi à Port-Azur et n'est jamais remonté depuis cinquante ans, donne alors un morceau de mer
## en échange (une seule fois). Au-dessus de la boîte tourne un mobile de ciel en papier. La nuit,
## l'enfant dort, la boîte entrouverte fait veilleuse, et le grand-parent veille en chuchotant.
static func _boite(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var room0: Node = M.room
	var nuit: bool = _nuit(M)
	var s: float = 1.0 if r.randf() < 0.5 else -1.0
	var boy: bool = r.randf() < 0.5
	var papi: bool = r.randf() < 0.5
	var kb: int = 0 if boy else 1
	var gp: int = 0 if papi else 1
	_boite_mats(M)
	# le foyer à l'éthanol au fond, du côté du grand-parent
	var fox: float = -s * R.W * 0.22
	_foyer(M, fox)
	R.mark_wall(fox, 1.6, -hd + 0.02, 0.6)
	# le lit de l'enfant, la tête contre le mur du fond, dans son coin ; au-dessus, des bocaux vides
	# (« en attente de ciel »)
	var bx: float = s * (hw - 0.65)
	var bz: float = -hd + 1.05
	R.lit(bx, bz, 0.0, 0.95, "turquoise" if boy else "bleu")
	if R.wall_free(bx, 1.75, -hd + 0.02, 0.55):
		R.etagere_murale(bx, 1.75, -hd + 0.13, 0.0, 0.9, "verre", 4)
	# la boîte, sur un tapis, devant le lit ; l'enfant à côté ; son petit bureau (les crayons, le papier)
	var kx: float = s * (hw - 1.75)
	var kz: float = clampf(-hd + 2.7, -hd + 1.6, hd - 2.3)
	R.tapis(kx - s * 0.35, kz + 0.25, 0, 2.0, 1.5)
	var kp: Vector2 = _dedans(M, kx - s * 0.85, kz + 0.1)
	var dp: Vector2 = _dedans(M, kp.x, kp.y + 0.8)
	var dx: float = dp.x
	var dz: float = dp.y
	R.table(dx, dz, 0.0, 0.75, 0.45, 0.55)
	R.kit.box(R.L(dx - 0.12, 0.552, dz + 0.02, 8.0), Vector3(0.21, 0.004, 0.15), "papier", 1.0)
	for k in range(3):
		R.kit.cyl(Transform3D(Basis(Vector3.UP, 0.2 * k) * Basis(Vector3.BACK, PI * 0.5), R.P(dx + 0.2, 0.556, dz - 0.08 + k * 0.05)), 0.006, 0.006, 0.12,
			["tissu_bleu", "tissu_jaune", "tissu_turquoise"][k], 6)
	# le fauteuil du grand-parent, tourné vers la boîte ; le guéridon (sa tasse, le règlement), le lampadaire
	var gx: float = -s * (hw - 1.0)
	var gz: float = clampf(kz + 0.2, -hd + 1.0, hd - 1.8)
	var gyaw: float = _vers(gx, gz, kx, kz)
	R.fauteuil(gx, gz, gyaw, str(_pick(M, ["blanc", "creme", "bleu", "turquoise"])))
	var tx: float = gx
	var tz: float = gz - 0.9
	R.table_ronde(tx, tz, 0.3, 0.6)
	R.kit.cyl(R.L(tx + 0.1, 0.6, tz + 0.04), 0.035, 0.03, 0.06, "ceramique", 10)
	R.kit.cyl(R.L(tx + 0.1, 0.6, tz + 0.04), 0.06, 0.06, 0.006, "ceramique", 12)
	S._mot(M, tx - 0.08, tz - 0.02, 0.6, BOITE_REGLEMENT[gp], "E : lire le règlement de la boîte à ciel")
	if R.is_free(-s * (hw - 0.45), gz + 0.75, 0.45, 0.45):
		_lampadaire(M, -s * (hw - 0.45), gz + 0.75)
	if R.is_free(-s * (hw - 0.5), -hd + 0.5, 0.45, 0.45):
		_pot(M, -s * (hw - 0.5), -hd + 0.5, 0.0, 1.1, "")
	_cadres(M, 2)
	# --- la boîte à ciel : un grand coffre de nacre aux arêtes de titane, une ligne de diodes aigue-marine,
	# le dedans peint en bleu ciel
	R.kit.box(R.L(kx, 0.03, kz), Vector3(0.94, 0.04, 0.62), "da_nacre", 1.0)
	for sz in [-1.0, 1.0]:
		R.kit.box(R.L(kx, 0.25, kz + sz * 0.295), Vector3(0.94, 0.4, 0.03), "da_nacre", 1.0)
		R.kit.box(R.L(kx, 0.25, kz + sz * 0.276), Vector3(0.86, 0.38, 0.008), "da_ciel", 1.0)
	for sx in [-1.0, 1.0]:
		R.kit.box(R.L(kx + sx * 0.455, 0.25, kz), Vector3(0.03, 0.4, 0.56), "da_nacre", 1.0)
		R.kit.box(R.L(kx + sx * 0.436, 0.25, kz), Vector3(0.008, 0.38, 0.54), "da_ciel", 1.0)
		for sz2 in [-1.0, 1.0]:
			R.kit.cyl(R.L(kx + sx * 0.47, 0.0, kz + sz2 * 0.31), 0.022, 0.022, 0.46, "argent", 8)
	R.kit.box(R.L(kx, 0.052, kz), Vector3(0.88, 0.005, 0.56), "da_ciel", 1.0)
	R.kit.box(R.L(kx, 0.4, kz + 0.313), Vector3(0.8, 0.014, 0.006), "da_diode", 1.0)
	R.kit.col_box(R.L(kx, 0.23, kz), Vector3(0.96, 0.46, 0.64))
	R.reserve(kx, kz, 1.2, 0.9)
	for e in [["LA BOÎTE À CIEL", 0.29, 44], ["Fragile : contient du ciel.", 0.17, 26]]:
		var lab := Label3D.new()
		lab.text = str(e[0])
		lab.font_size = int(e[2])
		lab.pixel_size = 0.0016
		lab.outline_size = 0
		lab.modulate = Color(0.16, 0.34, 0.62)
		M.room.add_child(lab)
		lab.global_position = R.P(kx, float(e[1]), kz + 0.313)
	# le couvercle (il pivote sur sa charnière, au dos) : de la nacre dessus, un ciel peint dessous
	# (le bleu, trois nuages, un soleil) ; la nuit, il reste entrouvert : la boîte fait veilleuse
	var lid: Node3D = I._node(M, R.P(kx, 0.45, kz - 0.31), 0.0)
	var nacre_m := _mat(Color(0.97, 0.96, 0.98), 0.15, 0.25)
	var titane_m := _mat(Color(0.82, 0.84, 0.87), 0.85, 0.3)
	var ciel_m := _mat(Color(0.5, 0.74, 0.96), 0.0, 0.7, 0.15)
	var blanc_m := _mat(Color(1, 1, 1), 0.0, 0.9, 0.1)
	_p(lid, I._boxm(Vector3(0.96, 0.035, 0.64)), nacre_m, Vector3(0, 0.0175, 0.31))
	for sx3 in [-1.0, 1.0]:
		_p(lid, I._boxm(Vector3(0.012, 0.04, 0.64)), titane_m, Vector3(sx3 * 0.48, 0.02, 0.31))
	_p(lid, I._boxm(Vector3(0.96, 0.04, 0.012)), titane_m, Vector3(0, 0.02, 0.63))
	_p(lid, I._boxm(Vector3(0.16, 0.02, 0.03)), titane_m, Vector3(0, 0.03, 0.645))
	_p(lid, I._boxm(Vector3(0.88, 0.004, 0.58)), ciel_m, Vector3(0, -0.003, 0.31))
	for c in [[Vector3(-0.25, -0.006, 0.34), 0.08], [Vector3(-0.17, -0.007, 0.36), 0.06], [Vector3(0.05, -0.006, 0.22), 0.07], [Vector3(0.12, -0.007, 0.24), 0.05], [Vector3(-0.05, -0.006, 0.47), 0.06]]:
		_p(lid, I._sph(1.0), blanc_m, c[0], Vector3(float(c[1]), 0.003, float(c[1]) * 0.55))
	_p(lid, I._sph(1.0), _mat(Color(1.0, 0.85, 0.3), 0.0, 0.5, 0.8), Vector3(0.3, -0.006, 0.48), Vector3(0.05, 0.003, 0.05))
	_sans_ombre(lid)
	lid.rotation.x = -0.42 if nuit else 0.0
	var lum := OmniLight3D.new()
	lum.light_color = BOITE_BLEU
	lum.light_energy = 0.0
	lum.omni_range = 2.2
	lum.shadow_enabled = false
	M.room.add_child(lum)
	lum.global_position = R.P(kx, 0.7, kz)
	# --- les morceaux de ciel, rangés dans la boîte (chacun à sa place)
	var objs: Array = []
	var places: Array = [
		["cartes", Vector3(-0.27, 0.07, -0.12), Vector3(-PI * 0.5, 0.2, 0)], ["plume", Vector3(0.0, 0.06, -0.13), Vector3(-PI * 0.5, 0.9, 0)],
		["flacon", Vector3(0.27, 0.125, -0.13), Vector3(0, 0.3, 0)], ["nuage", Vector3(-0.27, 0.07, 0.12), Vector3(-PI * 0.5, -0.15, 0)],
		["bocal", Vector3(0.0, 0.12, 0.12), Vector3(0, 2.2, 0)], ["arc", Vector3(0.27, 0.07, 0.12), Vector3(-PI * 0.5, 0.25, 0)]]
	if bool(M.state().get("da_boite_carte", false)):
		places.append(["vraie", Vector3(-0.14, 0.09, 0.02), Vector3(-PI * 0.5, 0.3, 0)])
	if bool(M.state().get("da_boite_dessin", false)):
		places.append(["dessin", Vector3(0.14, 0.095, 0.0), Vector3(-PI * 0.5, -0.25, 0)])
	for pl in places:
		objs.append(_boite_morceau(M, str(pl[0]), R.P(kx, 0, kz) + (pl[1] as Vector3), pl[2]))
	var show: Vector3 = R.P(kx, 1.2, kz + 0.1)
	# ce qu'on lit et ce qu'on entend pour chaque morceau : [le récit, l'enfant (le jour), le grand-parent
	# (la nuit, tout bas)]
	var T: Dictionary = {
		"cartes": ["Trois cartes postales cornées à force d'être regardées : un ciel bleu au-dessus d'un champ, un coucher de soleil tout orange, des nuages au-dessus d'un phare. Au dos, des écritures qui ne sont pas d'ici.",
			["Les cartes de Papi, de quand il habitait en haut. Regarde le orange, là ! Le ciel peut devenir ORANGE. Je l'ai appris à six ans. Ça m'a fait un choc.", "Les cartes de Mamie, de quand elle habitait en haut. Regarde le orange, là ! Le ciel peut devenir ORANGE. Je l'ai appris à six ans. Ça m'a fait un choc."][gp],
			["Mes cartes… Je les ai descendues dans ma valise, il y a cinquante ans. Maintenant, elles sont à lui. Elles ont plus voyagé dans ses mains que dans les miennes.", "Mes cartes… Je les ai descendues dans ma valise, il y a cinquante ans. Maintenant, elles sont à elle. Elles ont plus voyagé dans ses mains que dans les miennes."][kb]],
		"plume": ["Une plume grise et blanche, longue comme une main. Une étiquette, d'une écriture d'enfant : « Tombée par la Cheminée d'Air. Attrapée sur la grille. Un mardi. »",
			"Une plume de mouette ! Elle est tombée par la Cheminée d'Air, cent quarante mètres, toute seule, et je l'ai attrapée sur la grille. Le gardien dit que la mouette me l'a envoyée. Exprès.",
			"Les mouettes… Là-haut, je les entendais tous les matins. Ça criait, ça se disputait les frites. Je ne pensais pas qu'un jour, ça me manquerait."],
		"flacon": ["Un petit flacon bouché à la cire bleue. L'étiquette dit : « AIR DE LA SURFACE. Ne pas ouvrir. Sauf urgence de ciel. »",
			"De l'air de la surface ! Du vrai ! Je l'ai rempli au pied de la Cheminée, là où il descend tout frais. Je ne l'ouvre jamais : sinon, il se mélange avec le nôtre, et je ne saurai plus lequel c'est.",
			"Son flacon d'air… Un soir, j'ai failli l'ouvrir, pour sentir. Je ne l'ai pas fait. C'est son ciel. On ne respire pas le ciel des autres."],
		"nuage": ["Un nuage dessiné au crayon blanc sur un carton bleu, découpé, avec du vrai coton collé dessus. En dessous : « Nuage. Taille réelle : inconnue. »",
			"Ça, c'est un nuage. Enfin, presque. Personne n'a pu m'en descendre un vrai : ils sont trop gros pour le Funiculaire. Alors je l'ai fait d'après ce qu'on m'a dit. Il est bien ?",
			["Son nuage en coton… Il est plus joli que les vrais. Ne le lui dites pas : il voudrait comparer.", "Son nuage en coton… Il est plus joli que les vrais. Ne le lui dites pas : elle voudrait comparer."][kb]],
		"bocal": ["Un bocal de confiture, bien fermé. Au fond, une cuillère d'eau. Sur l'étiquette, une seule phrase : « Grêlon. Il était froid. »",
			"C'était un grêlon : un morceau de glace qui tombe du ciel, tout seul ! Un voyageur me l'a apporté dans sa poche. Le temps d'arriver, il avait fondu. Mais il était froid. Je l'ai touché. Il était froid.",
			["Le grêlon… Le monsieur a couru depuis la Gare, la poche qui gouttait. Le petit a pleuré en voyant l'eau. Puis il a dit : « Ce n'est pas grave. Il était froid. » Et il a gardé l'eau.",
				"Le grêlon… Le monsieur a couru depuis la Gare, la poche qui gouttait. La petite a pleuré en voyant l'eau. Puis elle a dit : « Ce n'est pas grave. Il était froid. » Et elle a gardé l'eau."][kb]],
		"arc": ["Une photo un peu passée : un arc-en-ciel au-dessus d'une prairie mouillée. Quelqu'un a repassé chaque couleur au crayon, pour être sûr qu'elle ne s'efface pas.",
			"Un arc-en-ciel ! Il arrive quand il pleut ET qu'il fait soleil, en même temps. Les deux ! Ici, on ne peut pas. J'ai essayé avec la Fontaine des Bulles et une lampe de poche. Ça a fait un petit bout. Tout petit.",
			"Cette photo, c'est la dernière que j'ai prise là-haut, avant de descendre. Je ne savais pas que c'était la dernière. On ne le sait jamais."],
		"vraie": ["Ta carte postale, rangée bien à plat : le phare de Port-Azur, la baie, un ciel immense. Une étiquette neuve dit : « Apportée par quelqu'un d'en haut. En vrai. »",
			"Ta carte ! C'est mon morceau le plus neuf. Je la regarde tous les soirs. Le ciel, dessus, il est encore plus grand que sur les autres.",
			["Votre carte… Il s'endort en la regardant. Hier, il m'a demandé si le phare était allumé, là-haut, en ce moment.", "Votre carte… Elle s'endort en la regardant. Hier, elle m'a demandé si le phare était allumé, là-haut, en ce moment."][kb]],
		"dessin": ["La carte postale que vous avez dessinée ensemble : un grand ciel bleu, un soleil qui dépasse un peu, et un oiseau en forme de V. Au dos : « Dessinée d'après quelqu'un qui l'a vu. »",
			"Notre carte ! Celle qu'on a dessinée ensemble. Elle compte, hein ? Elle compte, parce que c'est toi qui m'as dit les couleurs.",
			["Votre dessin… Il l'a montré à toute l'école. Il dit que c'est « d'après nature ». D'après vous, plutôt.", "Votre dessin… Elle l'a montré à toute l'école. Elle dit que c'est « d'après nature ». D'après vous, plutôt."][kb]],
	}
	var SON: Dictionary = {"cartes": "ui_ouvrir", "plume": "bourrasque", "flacon": "cristal_chante", "nuage": "ui_clic", "bocal": "verser", "arc": "carillon", "vraie": "ui_ouvrir", "dessin": "ui_clic"}
	# --- le mobile de ciel en papier, au-dessus de la boîte : deux nuages, un soleil, un oiseau, des gouttes
	var mobile: Node3D = I._node(M, R.P(kx, R.H - 0.02, kz), 0.0)
	var fil_m := _mat(Color(0.85, 0.87, 0.9), 0.6, 0.4)
	var anneau := TorusMesh.new()
	anneau.inner_radius = 0.3
	anneau.outer_radius = 0.315
	anneau.rings = 24
	anneau.ring_segments = 6
	_p(mobile, I._cyl(0.003, 0.003, 0.3, 4), fil_m, Vector3(0, -0.15, 0))
	_p(mobile, anneau, fil_m, Vector3(0, -0.3, 0))
	var pendus: Array = []
	var papier_bleu := _mat(Color(0.45, 0.7, 0.98), 0.0, 0.9)
	var gris_m := _mat(Color(0.35, 0.38, 0.45), 0.0, 0.8)
	for k2 in range(6):
		var a: float = TAU * k2 / 6.0
		var pd := Node3D.new()
		mobile.add_child(pd)
		pd.position = Vector3(cos(a) * 0.307, -0.3, sin(a) * 0.307)
		var lg: float = 0.18 + 0.12 * float(k2 % 3)
		_p(pd, I._cyl(0.002, 0.002, lg, 4), fil_m, Vector3(0, -lg * 0.5, 0))
		var it := Node3D.new()
		pd.add_child(it)
		it.position = Vector3(0, -lg - 0.05, 0)
		it.rotation.y = -a
		match k2 % 6:
			0, 3:
				for c2 in [[Vector3(0, 0, 0), 0.07], [Vector3(0.06, -0.01, 0), 0.05], [Vector3(-0.06, -0.012, 0), 0.05]]:
					_p(it, I._sph(1.0), blanc_m, c2[0], Vector3(float(c2[1]), float(c2[1]) * 0.7, 0.012))
			1:
				_p(it, I._cyl(0.06, 0.06, 0.006, 20), _mat(Color(1.0, 0.82, 0.25), 0.0, 0.6, 0.6), Vector3.ZERO, Vector3.ONE, Vector3(PI * 0.5, 0, 0))
				for k3 in range(8):
					var b: float = TAU * k3 / 8.0
					_p(it, I._boxm(Vector3(0.008, 0.035, 0.004)), _mat(Color(1.0, 0.82, 0.25), 0.0, 0.6, 0.6), Vector3(cos(b) * 0.08, sin(b) * 0.08, 0), Vector3.ONE, Vector3(0, 0, b - PI * 0.5))
			2:
				for sb in [-1.0, 1.0]:
					_p(it, I._boxm(Vector3(0.07, 0.008, 0.012)), gris_m, Vector3(sb * 0.03, 0.012, 0), Vector3.ONE, Vector3(0, 0, sb * 0.45))
			_:
				for k4 in range(3):
					_p(it, I._sph(1.0), papier_bleu, Vector3(0.0, -k4 * 0.07, 0), Vector3(0.016, 0.026, 0.006))
		pendus.append(pd)
	_sans_ombre(mobile)
	# --- les gens : l'enfant, debout devant sa boîte (la nuit, il dort) ; le grand-parent dans son fauteuil
	var kid: Node
	if nuit:
		kid = M.person("garcon" if boy else "fille", bx, bz, 0.0, "dormir")
		kid.lie(R.P(bx, 0.5, bz + 0.72), Vector3(0, 0, -1))
		kid.lines = ["Zzz…", "Zzz… il était froid… zzz…", "Mmh… encore un morceau… zzz…", "Zzz… le vent… il court… zzz…"]
		kid.line_every = Vector2(10.0, 15.0)
	else:
		kid = M.person("garcon" if boy else "fille", kp.x, kp.y, _vers(kp.x, kp.y, kx, kz), "debout")
		kid.lines = ["Tu as quelque chose d'en haut ? N'importe quoi ! Même un tout petit caillou de ciel !",
			"Depuis que la Ligne a rouvert, je laisse toujours de la place dans ma boîte.",
			"Mila a un cahier du ciel. Moi, j'ai une boîte. Une boîte, c'est mieux : on peut mettre des choses en vrai dedans.",
			["Papi dit que le ciel n'a pas de plafond. Je ne le crois pas tout à fait.", "Mamie dit que le ciel n'a pas de plafond. Je ne la crois pas tout à fait."][gp]]
		kid.line_every = Vector2(7.0, 11.0)
	var gpf: Node = M.person("vieux" if papi else "vieille", gx, gz, gyaw, "assis")
	if nuit:
		gpf.lines = [["Chut… il rêve du ciel.", "Chut… elle rêve du ciel."][kb], "Regardez : la boîte fait veilleuse. Un petit bout de ciel bleu dans le noir.",
			"Zzz… Oh ! Non, je ne dormais pas. Je veillais. Les yeux fermés."]
		gpf.line_every = Vector2(11.0, 16.0)
	else:
		gpf.lines = [["Il me fait le musée tous les soirs. Je connais les morceaux par cœur. Je fais semblant que non.", "Elle me fait le musée tous les soirs. Je connais les morceaux par cœur. Je fais semblant que non."][kb],
			"Bonnes bulles ! Attention à la boîte : elle contient du ciel.", "Cinquante ans que je n'ai pas vu le ciel. Mais je vois sa boîte tous les jours.",
			"La Grande Perle est belle, aujourd'hui. Presque autant qu'un vrai matin."]
		gpf.line_every = Vector2(9.0, 14.0)
	var st := {"t": r.randf() * 10.0, "open": false, "busy": false, "cur": -1, "idx": 0, "flotte": false, "vus": {}, "tout": false,
		"lum": 0.4 if nuit else 0.0, "lum_e": 0.4 if nuit else 0.0, "dit": {}}
	# --- sortir un morceau (il monte au-dessus de la boîte) ; le ranger (il redescend à sa place)
	var lever := func(i: int) -> void:
		var o: Node3D = objs[i]["n"]
		st["cur"] = i
		st["flotte"] = false
		o.rotation.y = wrapf(o.rotation.y, -PI, PI)
		var tw: Tween = M.room.create_tween()
		tw.set_parallel(true)
		tw.tween_property(o, "global_position", show, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(o, "rotation", Vector3(0.0, o.rotation.y, 0.0), 0.6).set_trans(Tween.TRANS_SINE)
		tw.chain().tween_callback(func(): st["flotte"] = true)
	var ranger := func(i: int) -> void:
		var o: Node3D = objs[i]["n"]
		if int(st["cur"]) == i:
			st["cur"] = -1
		st["flotte"] = false
		o.scale = Vector3.ONE
		o.rotation = Vector3(o.rotation.x, wrapf(o.rotation.y, -PI, PI), wrapf(o.rotation.z, -PI, PI))
		var tw: Tween = M.room.create_tween()
		tw.set_parallel(true)
		tw.tween_property(o, "global_position", objs[i]["rest"], 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(o, "rotation", objs[i]["rot"], 0.6).set_trans(Tween.TRANS_SINE)
	# ouvrir, refermer le couvercle (la nuit, il reste entrouvert : la veilleuse)
	var couvrir := func(ouvre: bool) -> void:
		st["open"] = ouvre
		var tw: Tween = M.room.create_tween()
		tw.tween_property(lid, "rotation:x", -1.9 if ouvre else (-0.42 if nuit else 0.0), 0.7).set_trans(Tween.TRANS_SINE)
		st["lum"] = 0.9 if ouvre else (0.4 if nuit else 0.0)
		M.main.sfx("coffre", R.P(kx, 0.4, kz), -12.0 if nuit else -4.0)
	# le grand-parent donne un morceau de mer en échange (une seule fois)
	var recompense := func() -> void:
		if bool(M.state().get("da_boite", false)):
			gpf.say(str(_pick(M, ["Encore un morceau… Cette boîte sera bientôt plus grande que le ciel.", "Merci. Vraiment. Pour lui, et un peu pour moi.", "Bonnes bulles, et revenez avec du ciel !"])), 4.0)
			return
		M.state()["da_boite"] = true
		var txt: String = ["Un nouveau morceau de ciel… Vous savez, je le regarde autant que lui. Tenez, tout bas : un morceau de mer, en échange. Là-haut, il vous fera penser à nous.",
			"Un nouveau morceau de ciel… Vous savez, je le regarde autant qu'elle. Tenez, tout bas : un morceau de mer, en échange. Là-haut, il vous fera penser à nous."][kb] if nuit else \
			["Un nouveau morceau de ciel ! Vous savez, je le regarde autant que lui. Un morceau de ciel contre un morceau de mer : c'est un échange honnête. Tenez. Là-haut, il vous fera penser à nous.",
			"Un nouveau morceau de ciel ! Vous savez, je le regarde autant qu'elle. Un morceau de ciel contre un morceau de mer : c'est un échange honnête. Tenez. Là-haut, il vous fera penser à nous."][kb]
		M.talk(gpf, txt, I._bye("Merci… Bonne nuit !" if nuit else "Merci ! Bonnes bulles !"), func(_i):
			M.give([[_neuf(M, "coquillage_chanteur", "perle_azur"), 1]], "")
			M.close_talk(), "à voix basse" if nuit else "ému")
	var sortir := func() -> void:
		if bool(st["busy"]) or not bool(st["open"]):
			return
		st["busy"] = true
		var c0: int = int(st["cur"])
		if c0 >= 0:
			ranger.call(c0)
			await M.get_tree().create_timer(0.6).timeout
			if not _la(M, room0):
				return
		var i: int = int(st["idx"]) % objs.size()
		st["idx"] = i + 1
		lever.call(i)
		var kind: String = str(objs[i]["kind"])
		M.main.sfx(str(SON[kind]), show, -16.0 if (nuit or kind == "plume") else -6.0)
		var tx3: Array = T[kind]
		M.say(str(tx3[0]), 7.0)
		if nuit:
			S._say_late(M, gpf, str(tx3[2]), 1.6, 6.0)
		else:
			S._say_late(M, kid, str(tx3[1]), 1.2, 6.0)
			if kind == "arc" or kind == "vraie" or kind == "dessin":
				kid.gesture("joie", 1.6)
		(st["vus"] as Dictionary)[i] = true
		if not nuit and not bool(st["tout"]) and (st["vus"] as Dictionary).size() >= objs.size():
			st["tout"] = true
			S._say_late(M, kid, "Et voilà toute ma boîte. Il reste de la place, tu as vu ? C'est pour les prochains morceaux. Je laisse toujours de la place.", 8.0, 5.0)
		await M.get_tree().create_timer(1.0).timeout
		st["busy"] = false
	var ouvrir := func() -> void:
		if bool(st["busy"]):
			return
		couvrir.call(true)
		if nuit:
			M.say("Tu soulèves le couvercle, tout doucement. Le ciel peint dessous s'allume en bleu. Dans son lit, l'enfant ne se réveille pas.", 5.0)
			S._say_late(M, gpf, "Doucement… Vous pouvez regarder. Il ne faut juste pas le réveiller.", 1.2)
		else:
			kid.gesture("joie", 1.5)
			kid.say(str(_pick(M, ["Attention, c'est fragile ! C'est du ciel !", "Tu veux voir ? Sors-les un par un, c'est mieux. C'est un musée.", "Ta-daaa ! Le ciel !"])), 3.5)
	var refermer := func() -> void:
		if bool(st["busy"]):
			return
		st["busy"] = true
		var c0: int = int(st["cur"])
		if c0 >= 0:
			ranger.call(c0)
			await M.get_tree().create_timer(0.55).timeout
			if not _la(M, room0):
				return
		couvrir.call(false)
		if not nuit:
			kid.say(str(_pick(M, ["On referme bien, sinon le ciel s'échappe.", "Merci d'avoir regardé !", "Clac ! Le ciel est à l'abri."])), 3.0)
		await M.get_tree().create_timer(0.7).timeout
		st["busy"] = false
	# --- donner une carte postale (si on en a une) : elle vole du sac jusqu'au-dessus de la boîte
	var cartes_sac := func() -> int:
		var inv: Node = M.main.get("inventory_v28")
		if inv == null or not inv.has_method("count"):
			return 0
		return int(inv.count("carte_postale"))
	var donner := func() -> void:
		var inv: Node = M.main.get("inventory_v28")
		if inv == null or int(inv.count("carte_postale")) <= 0 or bool(st["busy"]) or bool(M.state().get("da_boite_carte", false)):
			return
		st["busy"] = true
		inv.remove("carte_postale", 1)
		M.state()["da_boite_carte"] = true
		var c0: int = int(st["cur"])
		if c0 >= 0:
			ranger.call(c0)
		if not bool(st["open"]):
			couvrir.call(true)
		var o: Dictionary = _boite_morceau(M, "vraie", R.P(kx - 0.14, 0.09, kz + 0.02), Vector3(-PI * 0.5, 0.3, 0))
		(o["n"] as Node3D).global_position = M.main._player_pos_v27() + Vector3(0, 1.3, 0)
		(o["n"] as Node3D).rotation = Vector3.ZERO
		objs.append(o)
		lever.call(objs.size() - 1)
		M.main.sfx("ui_ouvrir", show, -12.0 if nuit else -6.0)
		if nuit:
			M.say("Tu glisses ta carte postale au-dessus de la boîte entrouverte : le phare de Port-Azur, la baie, un grand ciel. Dans son lit, l'enfant sourit sans se réveiller.", 6.0)
			S._say_late(M, kid, "Zzz… un phare… zzz…", 2.0)
		else:
			M.say("Tu sors une carte postale de ton sac : le phare de Port-Azur, la baie, un grand ciel. L'enfant la regarde monter au-dessus de la boîte sans respirer, comme si elle allait fondre.", 6.0)
			kid.gesture("joie", 2.5)
			S._say_late(M, kid, ["Un nouveau morceau ! Tout neuf, avec un phare ! Papi ! Viens voir ! C'est Port-Azur !", "Un nouveau morceau ! Tout neuf, avec un phare ! Mamie ! Viens voir ! C'est Port-Azur !"][gp], 1.0, 4.0)
			S._say_late(M, gpf, "Port-Azur… C'est là que j'ai grandi. Le phare n'a pas changé. Moi, si.", 4.2, 4.0)
		await M.get_tree().create_timer(7.5).timeout
		if not _la(M, room0):
			return
		recompense.call()
		st["busy"] = false
	# --- sinon, la dessiner ensemble : on raconte, l'enfant dessine sur son bureau (le ciel, le soleil,
	# l'oiseau, un trait à la fois), puis le dessin rejoint la boîte
	var dessiner := func() -> void:
		if bool(st["busy"]) or nuit or bool(M.state().get("da_boite_dessin", false)):
			return
		st["busy"] = true
		M.state()["da_boite_dessin"] = true
		var c0: int = int(st["cur"])
		if c0 >= 0:
			ranger.call(c0)
		var o: Dictionary = _boite_morceau(M, "dessin", R.P(kx + 0.14, 0.095, kz), Vector3(-PI * 0.5, -0.25, 0))
		var fn: Node3D = o["n"]
		fn.global_position = R.P(dx - 0.12, 0.565, dz + 0.02)
		fn.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
		var etapes: Array = o["etapes"]
		for e2 in etapes:
			(e2 as Node3D).visible = false
		kid.set_pose("peindre", Vector3(0, 0, 1))
		M.say("Pas de carte postale dans ton sac ? « Alors raconte, je dessine ! » Tu racontes, l'enfant dessine, la langue entre les dents.", 5.0)
		var paroles: Array = ["Le bleu d'abord. Beaucoup de bleu. Encore plus ? D'accord…", "Le soleil, je le fais rond, comme la Perle. Il dépasse un peu. Ce n'est pas grave ?",
			"Et un oiseau ! En forme de V ? Ils sont tous en forme de V ? C'est pratique."]
		for k5 in range(etapes.size()):
			await M.get_tree().create_timer(2.6).timeout
			if not _la(M, room0):
				return
			(etapes[k5] as Node3D).visible = true
			M.main.sfx("ui_clic", fn.global_position, -10.0)
			_bulle(M, fn.global_position + Vector3(0, 0.2, 0), "✎", Color(0.55, 0.75, 1.0), 40, 0.4, 1.4)
			if k5 < paroles.size():
				kid.say(str(paroles[k5]), 3.0)
		await M.get_tree().create_timer(2.4).timeout
		if not _la(M, room0):
			return
		kid.set_pose("debout", Vector3(kx - kp.x, 0, kz - kp.y))
		if not bool(st["open"]):
			couvrir.call(true)
		objs.append(o)
		lever.call(objs.size() - 1)
		kid.gesture("joie", 2.5)
		kid.say("Voilà ! Une carte postale du ciel, dessinée d'après quelqu'un qui l'a vu. Ça compte, hein ? Dis que ça compte !", 4.5)
		await M.get_tree().create_timer(5.0).timeout
		if not _la(M, room0):
			return
		recompense.call()
		st["busy"] = false
	var a_boite: Vector3 = R.P(kx - s * 0.3, 0, kz + 0.62)
	M.act(a_boite, "E : ouvrir la boîte à ciel, tout doucement" if nuit else "E : ouvrir la boîte à ciel", ouvrir, 0.9, func(): return not bool(st["open"]) and not bool(st["busy"]))
	M.act(a_boite, "E : refermer la boîte à ciel", refermer, 0.9, func(): return bool(st["open"]) and not bool(st["busy"]))
	M.act(R.P(kx + s * 0.3, 0, kz + 0.62), "E : sortir un morceau de ciel", sortir, 0.9, func(): return bool(st["open"]) and not bool(st["busy"]))
	M.act(R.P(kx, 0, kz + 0.95), "E : glisser une carte postale dans la boîte", donner, 0.9,
		func(): return int(cartes_sac.call()) > 0 and not bool(M.state().get("da_boite_carte", false)) and not bool(st["busy"]))
	if not nuit:
		M.act(R.P(dx, 0, dz + 0.55), "E : dessiner une carte postale avec l'enfant", dessiner, 0.9,
			func(): return int(cartes_sac.call()) <= 0 and not bool(M.state().get("da_boite_dessin", false)) and not bool(st["busy"]))
	# --- ce qui bouge : le mobile qui tourne, ses pendeloques qui se balancent, la lumière de la boîte qui
	# respire (en couleurs pour l'arc-en-ciel), le morceau sorti qui flotte et tourne, chacun à sa façon
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(mobile):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		mobile.rotation.y += dt * (0.07 if nuit else 0.2)
		for k6 in range(pendus.size()):
			(pendus[k6] as Node3D).rotation.z = 0.07 * sin(t * 0.9 + k6 * 1.3)
		var cur: int = int(st["cur"])
		var kind: String = str(objs[cur]["kind"]) if cur >= 0 and cur < objs.size() else ""
		var fl: bool = bool(st["flotte"])
		st["lum_e"] = lerpf(float(st["lum_e"]), float(st["lum"]), clampf(dt * 2.0, 0.0, 1.0))
		lum.light_energy = float(st["lum_e"]) * (1.0 + 0.12 * sin(t * 1.3))
		if kind == "arc" and fl:
			lum.light_color = Color.from_hsv(fposmod(t * 0.12, 1.0), 0.55, 1.0)
		else:
			lum.light_color = lum.light_color.lerp(BOITE_BLEU, clampf(dt * 2.0, 0.0, 1.0))
		if cur < 0 or not fl:
			return
		var o: Node3D = objs[cur]["n"]
		if not is_instance_valid(o):
			return
		var p: Vector3 = show + Vector3(0, 0.03 * sin(t * 1.6), 0)
		o.rotation.y += dt * 0.7
		match kind:
			"plume":
				p += Vector3(0.07 * sin(t * 0.9), 0.0, 0.0)
				o.rotation.z = 0.45 * sin(t * 1.8)
			"flacon":
				(objs[cur]["glow"] as StandardMaterial3D).emission_energy_multiplier = 1.0 + 0.9 * sin(t * 3.0)
			"bocal":
				o.rotation.z = 0.18 * sin(t * 2.4)
			"nuage":
				o.scale = Vector3.ONE * (1.0 + 0.05 * sin(t * 1.5))
		o.global_position = p
	# --- les conversations : l'enfant (lui raconter le ciel) ; le grand-parent (le ciel d'avant)
	var sujets: Array = [{"id": "bleu", "label": "Le ciel est bleu. Tout en haut, et partout."}, {"id": "vent", "label": "Il y a le vent : de l'air qui court partout."},
		{"id": "pluie", "label": "Parfois, il pleut : de l'eau qui tombe du ciel."}, {"id": "soleil", "label": "Et le soleil : comme la Grande Perle, mais en feu, très loin."},
		{"id": "etoiles", "label": "La nuit, il y a des étoiles : des milliers de petites lumières."}]
	var reponses: Dictionary = {
		"bleu": "Bleu comme le Bassin ? … Plus clair ? Plus clair que le Bassin, et il ne s'arrête pas ? Il n'y a pas de vitre au bout ? Pas du tout ? … J'ai besoin de m'asseoir. Raconte encore !",
		"vent": "De l'air qui court ! Tout seul, sans tuyau ? Et il pousse les gens ? Et les chapeaux ? … Le jour où je le rencontre, je le tiens par la main. Ou par le chapeau.",
		"pluie": "De l'eau qui tombe ? Mais d'où ? Il y a une fuite, là-haut ? … Les nuages ? Des nuages qui fuient ? Il faudrait que quelqu'un les répare. Yolande pourrait.",
		"soleil": "Comme la Grande Perle, mais en vrai feu ? Et personne ne l'a enfilé sur une cheminée ? Il tient tout seul ? … Le ciel est un endroit très bizarre. J'ai encore plus envie d'y aller.",
		"etoiles": "Des milliers ? Comme les poissons-lanternes, mais qui ne bougent pas ? Et qui les allume, le soir ? … Personne ? Elles s'allument toutes seules ? Je vais le noter. En très grand.",
	}
	var cb: Dictionary = {}
	cb["ciel"] = func(texte: String) -> void:
		var ch: Array = sujets.duplicate()
		ch.append({"id": "fermer", "label": "C'est tout pour aujourd'hui !"})
		M.talk(kid, texte, ch, func(id):
			if str(id) == "fermer":
				M.close_talk()
				if (st["dit"] as Dictionary).size() >= sujets.size():
					kid.gesture("joie", 2.0)
					kid.say("Le bleu, le vent, la pluie, le soleil, les étoiles… Je vais tout ranger dans ma boîte. Enfin, dans ma tête. Ma tête, c'est ma deuxième boîte.", 5.5)
				else:
					kid.say(str(_pick(M, ["Merci ! Reviens me raconter la suite !", "Je vais rêver de tout ça cette nuit.", "Tu racontes bien. Mieux que les cartes postales."])), 3.5)
				return
			(st["dit"] as Dictionary)[str(id)] = true
			_bulle(M, kid.npc.global_position + Vector3(0, 1.75, 0), "✎", Color(0.55, 0.75, 1.0), 40, 0.4, 1.4)
			cb["ciel"].call(str(reponses[str(id)]))
		, "aux anges")
	var kid_cb := func() -> void:
		if nuit:
			M.talk(kid, "Zzz… c'est comment… le ciel… zzz…", [{"id": "chut", "label": "(Lui chuchoter : « Bleu. Grand. Et tout doux. »)"}, {"id": "fermer", "label": "(Le laisser dormir)" if boy else "(La laisser dormir)"}], func(id):
				if str(id) == "chut":
					M.talk(kid, ["Zzz… bleu… grand… tout doux… zzz… comme Papi… zzz…", "Zzz… bleu… grand… tout doux… zzz… comme Mamie… zzz…"][gp], I._bye("(Le laisser dormir)" if boy else "(La laisser dormir)"), I._close(M), "endormi" if boy else "endormie")
				else:
					M.close_talk()
			, "endormi" if boy else "endormie")
			return
		cb["ciel"].call(str(_pick(M, ["Bonnes bulles ! Tu viens d'en haut ? Du vrai en haut ? Alors tu l'as vu ! Raconte-moi le ciel. S'il te plaît. Tout.",
			"Tu as vu le ciel, toi ? Avec tes yeux ? Raconte ! Moi, je ne l'ai jamais vu. Ni le soleil. Ni la pluie. Seulement dans ma boîte."])))
	M.talk_spot(kid, kid_cb)
	var gp_cb := func() -> void:
		if nuit:
			M.talk(gpf, ["Chut… Il dort. Il s'endort toujours la boîte entrouverte, pour que le ciel lui tienne compagnie. Moi, je veille. J'aime bien cette lumière bleue.",
				"Chut… Elle dort. Elle s'endort toujours la boîte entrouverte, pour que le ciel lui tienne compagnie. Moi, je veille. J'aime bien cette lumière bleue."][kb],
				[{"id": "vous", "label": "Vous ne dormez pas ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if str(id) == "vous":
					M.talk(gpf, "On dort peu, à mon âge. Et puis, la nuit, la Grande Perle devient violette. Ça me rappelle les soirs d'en haut. Un peu. Si je plisse les yeux.", I._bye("Bonne nuit…"), I._close(M), "à voix basse")
				else:
					M.close_talk()
			, "à voix basse")
			return
		M.talk(gpf, str(_pick(M, ["Bonnes bulles ! Vous venez voir sa boîte ? Tout le monde y a droit. C'est un musée, ici : le seul musée du ciel au fond de la mer.",
			"Ah, quelqu'un d'en haut ! Ça se voit tout de suite : vous regardez le plafond comme s'il allait partir."])),
			[{"id": "vu", "label": "Vous l'avez vu, vous, le ciel ?"}, {"id": "remonter", "label": "Vous remonterez, un jour ?"}, {"id": "fermer", "label": "Bonnes bulles !"}], func(id):
			match str(id):
				"vu":
					M.talk(gpf, ["Oh oui. J'ai grandi là-haut, à Port-Azur, au bord de la mer, mais dessus. À vingt ans, je suis descendu poser les vitres du Dôme. Je ne suis jamais remonté. Le travail, puis la famille, puis la Ligne fermée pendant douze ans… Le temps passe, en bas comme en haut.",
						"Oh oui. J'ai grandi là-haut, à Port-Azur, au bord de la mer, mais dessus. À vingt ans, je suis descendue poser les vitres du Dôme. Je ne suis jamais remontée. Le travail, puis la famille, puis la Ligne fermée pendant douze ans… Le temps passe, en bas comme en haut."][gp],
						[{"id": "manque", "label": "Il vous manque ?"}, {"id": "fermer", "label": "Merci de m'avoir raconté."}], func(id2):
						if str(id2) == "manque":
							M.talk(gpf, ["Le ciel ? Je ne m'en souviens plus très bien. C'est ça, le plus triste. Le bleu, oui. Mais le vent sur la figure, je l'ai oublié. Alors le petit me le rapporte, morceau par morceau. Sa boîte, c'est un peu pour moi.",
								"Le ciel ? Je ne m'en souviens plus très bien. C'est ça, le plus triste. Le bleu, oui. Mais le vent sur la figure, je l'ai oublié. Alors la petite me le rapporte, morceau par morceau. Sa boîte, c'est un peu pour moi."][kb], I._bye("…"), I._close(M), "ému")
						else:
							M.close_talk()
					, "ému")
				"remonter":
					M.talk(gpf, ["Il veut m'emmener. Il m'a déjà fait deux billets pour le Funiculaire. Dessinés. Marius a dit qu'il les accepterait. … Peut-être. Quand j'aurai fini d'avoir peur que le ciel ne me reconnaisse pas.",
						"Elle veut m'emmener. Elle m'a déjà fait deux billets pour le Funiculaire. Dessinés. Marius a dit qu'il les accepterait. … Peut-être. Quand j'aurai fini d'avoir peur que le ciel ne me reconnaisse pas."][kb],
						I._bye("Il vous reconnaîtra."), I._close(M), "ému")
				_:
					M.close_talk()
		, "de bonne humeur")
	M.talk_spot(gpf, gp_cb)
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Un enfant dort dans son lit. À côté, une grande boîte entrouverte luit en bleu, comme un petit bout de ciel posé par terre.",
			"Tout est calme. Un mobile de nuages en papier tourne lentement au-dessus d'une boîte qui brille. Dans le fauteuil, quelqu'un veille et te fait « chut ».",
			"Il fait nuit dans la maison-bulle. Seule une boîte entrouverte éclaire la pièce, d'une lumière bleu ciel. Un ciel qu'on n'a jamais vu, ici."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Une grande boîte de nacre trône sur le tapis. Dessus, en lettres bleues : « LA BOÎTE À CIEL ». Un enfant, à côté, te regarde comme si tu tombais du ciel. Un peu, oui.",
			"Des nuages en papier tournent au plafond, au-dessus d'une grande boîte. Un enfant se précipite : « Tu viens d'en haut ? Tu as apporté quelque chose ? »",
			"Ici, au fond de la mer, quelqu'un collectionne le ciel. Une boîte de nacre, un mobile de papier, et dans un fauteuil, un grand-parent qui sourit."]))


## Les matières de la boîte à ciel (la nacre, le bleu peint, les diodes aigue-marine).
static func _boite_mats(M) -> void:
	var R = M.R
	if R.kit.mats.has("da_nacre"):
		return
	R._put("da_nacre", R._col(Color(0.97, 0.96, 0.98), 0.25, 0.1))
	R._put("da_ciel", R._col(Color(0.5, 0.74, 0.96), 0.7))
	R._put("da_diode", _mat(Color(0.35, 0.95, 0.88), 0.0, 0.3, 2.2))


## Une bande de couleur (de y0 à y1) sur une carte de largeur w, à la profondeur z.
static func _boite_bande(n: Node3D, w: float, y0: float, y1: float, c: Color, z: float) -> MeshInstance3D:
	return _p(n, I._boxm(Vector3(w, absf(y1 - y0), 0.002)), _mat(c, 0.0, 0.8), Vector3(0, (y0 + y1) * 0.5, z))


## Une carte debout (une photo, un dessin), l'image vers +Z, le centre à l'origine : « champ »,
## « couchant », « phare », « vraie », « dessin », « nuage », « arc ». Rend les étapes du dessin.
static func _boite_carte(n: Node3D, kind: String, w: float, h: float) -> Array:
	var etapes: Array = []
	var fond: Color = Color(0.45, 0.68, 0.95) if kind == "nuage" else Color(0.97, 0.95, 0.9)
	_p(n, I._boxm(Vector3(w, h, 0.003)), _mat(fond, 0.0, 0.9), Vector3.ZERO)
	var z: float = 0.0025
	var iw: float = w - 0.012
	var top: float = h * 0.5 - 0.006
	var bot: float = -h * 0.5 + 0.006
	var blanc := _mat(Color(1, 1, 1), 0.0, 0.9)
	match kind:
		"champ":
			_boite_bande(n, iw, top, -h * 0.1, Color(0.45, 0.72, 0.98), z)
			_boite_bande(n, iw, -h * 0.1, bot, Color(0.42, 0.68, 0.3), z)
			_p(n, I._sph(1.0), blanc, Vector3(-0.025, h * 0.25, z + 0.001), Vector3(0.022, 0.008, 0.001))
			_p(n, I._sph(1.0), blanc, Vector3(-0.01, h * 0.27, z + 0.001), Vector3(0.016, 0.009, 0.001))
		"couchant":
			_boite_bande(n, iw, top, h * 0.15, Color(1.0, 0.62, 0.25), z)
			_boite_bande(n, iw, h * 0.15, -h * 0.12, Color(0.98, 0.45, 0.42), z)
			_boite_bande(n, iw, -h * 0.12, bot, Color(0.15, 0.22, 0.45), z)
			_p(n, I._sph(1.0), _mat(Color(1.0, 0.85, 0.35), 0.0, 0.6, 0.4), Vector3(0.02, -h * 0.12, z + 0.001), Vector3(0.018, 0.018, 0.001))
		"phare", "vraie":
			_boite_bande(n, iw, top, -h * 0.15, Color(0.55, 0.78, 0.98) if kind == "vraie" else Color(0.62, 0.7, 0.8), z)
			_boite_bande(n, iw, -h * 0.15, bot, Color(0.16, 0.4, 0.7), z)
			var px: float = w * 0.25
			_p(n, I._cyl(0.006, 0.009, h * 0.42, 8), blanc, Vector3(px, -h * 0.05, z + 0.003))
			_p(n, I._cyl(0.0085, 0.0085, h * 0.08, 8), _mat(Color(0.85, 0.15, 0.12), 0.0, 0.7), Vector3(px, -h * 0.02, z + 0.003))
			_p(n, I._sph(0.008), _mat(Color(1.0, 0.9, 0.4), 0.0, 0.5, 1.0), Vector3(px, h * 0.18, z + 0.003))
			for c in [[Vector3(-0.03, h * 0.28, z + 0.001), 0.022], [Vector3(-0.012, h * 0.3, z + 0.001), 0.016]]:
				_p(n, I._sph(1.0), blanc, c[0], Vector3(float(c[1]), float(c[1]) * 0.4, 0.001))
			if kind == "vraie":
				_p(n, I._sph(1.0), _mat(Color(1.0, 0.85, 0.3), 0.0, 0.6, 0.5), Vector3(-w * 0.3, h * 0.05, z + 0.001), Vector3(0.012, 0.012, 0.001))
		"nuage":
			for c2 in [[Vector3(0, 0.005, 0.004), 0.045], [Vector3(0.042, -0.008, 0.004), 0.032], [Vector3(-0.042, -0.01, 0.004), 0.03], [Vector3(0.015, 0.025, 0.004), 0.03]]:
				_p(n, I._sph(1.0), blanc, c2[0], Vector3(float(c2[1]), float(c2[1]) * 0.75, 0.012))
		"arc":
			_boite_bande(n, iw, top, -h * 0.28, Color(0.6, 0.8, 0.95), z)
			_boite_bande(n, iw, -h * 0.28, bot, Color(0.4, 0.62, 0.32), z)
			var cols: Array = [Color(0.95, 0.2, 0.2), Color(1.0, 0.55, 0.15), Color(1.0, 0.88, 0.2), Color(0.3, 0.75, 0.3), Color(0.25, 0.45, 0.95), Color(0.55, 0.3, 0.8)]
			for kc in range(cols.size()):
				var rr: float = h * 0.55 - kc * 0.0055
				var m := _mat(cols[kc], 0.0, 0.7)
				var seg: BoxMesh = I._boxm(Vector3(rr * PI / 9.0 * 1.15, 0.0055, 0.002))
				for ks in range(9):
					var a: float = PI * (ks + 0.5) / 9.0
					_p(n, seg, m, Vector3(cos(a) * rr, -h * 0.28 + sin(a) * rr, z + 0.001), Vector3.ONE, Vector3(0, 0, a + PI * 0.5))
		"dessin":
			# au crayon : le ciel (un peu de travers) et l'herbe, puis le soleil, puis l'oiseau
			var e1 := Node3D.new()
			n.add_child(e1)
			_boite_bande(e1, iw, top, -h * 0.25, Color(0.35, 0.6, 0.95), z)
			_p(e1, I._boxm(Vector3(iw * 0.8, 0.008, 0.002)), _mat(Color(0.3, 0.52, 0.9), 0.0, 0.9), Vector3(-0.01, h * 0.1, z + 0.001), Vector3.ONE, Vector3(0, 0, 0.06))
			_boite_bande(e1, iw, -h * 0.25, bot, Color(0.4, 0.75, 0.3), z)
			var e2 := Node3D.new()
			n.add_child(e2)
			_p(e2, I._sph(1.0), _mat(Color(1.0, 0.82, 0.2), 0.0, 0.6, 0.4), Vector3(w * 0.42, h * 0.38, z + 0.002), Vector3(0.028, 0.028, 0.001))
			for k in range(6):
				var b: float = PI * 0.6 + PI * 0.9 * k / 5.0
				_p(e2, I._boxm(Vector3(0.003, 0.016, 0.001)), _mat(Color(1.0, 0.82, 0.2), 0.0, 0.6, 0.4), Vector3(w * 0.42 + cos(b) * 0.04, h * 0.38 + sin(b) * 0.04, z + 0.002), Vector3.ONE, Vector3(0, 0, b - PI * 0.5))
			var e3 := Node3D.new()
			n.add_child(e3)
			for sb in [-1.0, 1.0]:
				_p(e3, I._boxm(Vector3(0.026, 0.004, 0.001)), _mat(Color(0.15, 0.15, 0.2), 0.0, 0.8), Vector3(-0.02 + sb * 0.011, h * 0.12, z + 0.002), Vector3.ONE, Vector3(0, 0, -sb * 0.5))
			etapes = [e1, e2, e3]
	return etapes


## Un morceau de ciel (un nœud qui bouge), posé à `rest` (monde) avec la rotation `rot` ; le centre du
## morceau à l'origine. Rend {n, kind, rest, rot, glow (le flacon), etapes (le dessin)}.
static func _boite_morceau(M, kind: String, rest: Vector3, rot: Vector3) -> Dictionary:
	var n: Node3D = I._node(M, rest, 0.0)
	n.rotation = rot
	var d: Dictionary = {"n": n, "kind": kind, "rest": rest, "rot": rot, "glow": null, "etapes": []}
	match kind:
		"cartes":
			var noms: Array = ["champ", "couchant", "phare"]
			for k in range(3):
				var c := Node3D.new()
				n.add_child(c)
				c.position = Vector3((k - 1) * 0.035, 0.0, k * 0.004)
				c.rotation.z = (1 - k) * 0.28
				_boite_carte(c, str(noms[k]), 0.15, 0.1)
		"plume":
			_p(n, I._cyl(0.0015, 0.0025, 0.2, 5), _mat(Color(0.9, 0.9, 0.88), 0.0, 0.6), Vector3(0, 0, 0))
			_p(n, I._sph(1.0), _mat(Color(0.97, 0.97, 0.96), 0.0, 0.9), Vector3(0, 0.015, 0), Vector3(0.028, 0.085, 0.004))
			_p(n, I._sph(1.0), _mat(Color(0.55, 0.57, 0.62), 0.0, 0.9), Vector3(0, 0.075, 0.0005), Vector3(0.02, 0.03, 0.0042))
		"flacon":
			_p(n, I._cyl(0.032, 0.032, 0.12, 14), _verre(Color(0.8, 0.92, 1.0), 0.3), Vector3.ZERO)
			var glow := _verre(Color(0.7, 0.9, 1.0), 0.35, 1.0)
			_p(n, I._sph(1.0), glow, Vector3.ZERO, Vector3(0.025, 0.045, 0.025))
			_p(n, I._cyl(0.018, 0.02, 0.025, 10), _mat(Color(0.82, 0.7, 0.5), 0.0, 0.8), Vector3(0, 0.07, 0))
			_p(n, I._cyl(0.022, 0.022, 0.012, 10), _mat(Color(0.25, 0.45, 0.85), 0.0, 0.4), Vector3(0, 0.086, 0))
			_p(n, I._boxm(Vector3(0.045, 0.03, 0.002)), _mat(Color(0.97, 0.95, 0.88), 0.0, 0.9), Vector3(0, -0.01, 0.033))
			d["glow"] = glow
		"bocal":
			_p(n, I._cyl(0.055, 0.055, 0.11, 18), _verre(Color(0.85, 0.93, 1.0), 0.28), Vector3.ZERO)
			_p(n, I._cyl(0.05, 0.05, 0.016, 18), _verre(Color(0.5, 0.75, 1.0), 0.6, 0.2), Vector3(0, -0.045, 0))
			_p(n, I._cyl(0.058, 0.058, 0.02, 18), _mat(Color(0.82, 0.84, 0.87), 0.85, 0.3), Vector3(0, 0.065, 0))
			_p(n, I._boxm(Vector3(0.085, 0.04, 0.002)), _mat(Color(0.97, 0.95, 0.88), 0.0, 0.9), Vector3(0, 0.01, 0.056))
			var lab := Label3D.new()
			lab.text = "Il était froid."
			lab.font_size = 32
			lab.pixel_size = 0.00035
			lab.outline_size = 0
			lab.modulate = Color(0.15, 0.25, 0.5)
			n.add_child(lab)
			lab.position = Vector3(0, 0.01, 0.058)
		"nuage":
			_boite_carte(n, "nuage", 0.18, 0.13)
		"arc":
			_boite_carte(n, "arc", 0.15, 0.11)
		"vraie":
			_boite_carte(n, "vraie", 0.16, 0.11)
		"dessin":
			d["etapes"] = _boite_carte(n, "dessin", 0.2, 0.14)
	_sans_ombre(n)
	return d


# =================================================================== le poulpe évadé

## Ses couleurs quand on l'admire (un arc-en-ciel, et blanc nacré pour finir, comme les murs).
const POULPE_ARC := [Color(0.95, 0.25, 0.22), Color(1.0, 0.55, 0.15), Color(1.0, 0.85, 0.25), Color(0.35, 0.85, 0.45),
	Color(0.25, 0.6, 1.0), Color(0.6, 0.35, 0.9), Color(0.96, 0.94, 1.0)]

## Ses couleurs de rêve, la nuit, dans le bocal.
const POULPE_REVE := [Color(0.66, 0.52, 0.86), Color(0.95, 0.6, 0.72), Color(0.4, 0.62, 0.95), Color(0.95, 0.82, 0.45)]

## Ce qu'on dit quand on cherche : le libellé de chaque cachette.
const POULPE_CHERCHER := {"theiere": "E : soulever le couvercle de la théière", "coussin": "E : soulever le coussin du canapé",
	"tiroir": "E : ouvrir le tiroir de la commode", "hublot": "E : regarder le hublot de près", "cuilleres": "E : regarder dans le pot à cuillères"}

## Les indices de l'enfant complice (selon la cachette).
const POULPE_INDICES := {
	"theiere": ["Ça sent le thé froid… et il y a de petites bulles qui sortent du bec de quelque chose.", "Maman cherche la théière pour son thé. Elle est sur la table basse. Elle est juste… un peu lourde, aujourd'hui.",
		"Quelqu'un a fait « bloup » dans la porcelaine."],
	"coussin": ["Le canapé a une bosse. Les canapés n'ont pas de bosse, d'habitude.", "Papa s'est assis tout à l'heure et il a fait « Hiii ! ». Ça veut peut-être dire quelque chose.",
		"Un coussin qui respire, ce n'est pas normal."],
	"tiroir": ["Les chaussettes de Papa sont rangées par couleur. Personne ne range les chaussettes par couleur. Sauf quelqu'un.", "Tout à l'heure, un bout de tentacule dépassait de la commode.",
		"On entend quelqu'un ranger des chaussettes. Du côté de la commode."],
	"hublot": ["Il aime bien regarder dehors. Il dit bonjour aux poissons-lanternes.", "Un des hublots a deux yeux, aujourd'hui. Les hublots n'ont pas d'yeux.",
		"La mer est plus sombre que d'habitude derrière un hublot. Comme s'il y avait un bout de nuit collé dessus."],
	"cuilleres": ["Tchling, tchling… On entend des cuillères qu'on range, du côté du buffet.", "Toutes les cuillères du buffet sont rangées en étoile. Un rangeur est passé par là.",
		"Maman a demandé : « Qui a pris mes cuillères ? » Ce n'est pas moi."],
}

## Quand on cherche au mauvais endroit.
const POULPE_VIDE := {
	"theiere": "Dans la théière : du thé froid, et les clés de Papa. Mais pas de poulpe.",
	"coussin": "Sous le coussin : trois miettes de galette et une chaussette. Pas de poulpe.",
	"tiroir": "Dans le tiroir : des chaussettes rangées par couleur. Très bien rangées. Trop bien rangées… mais pas de poulpe.",
	"hublot": "Derrière le hublot, un poisson-lanterne te regarde. Ce n'est pas un poulpe.",
	"cuilleres": "Dans le pot : des cuillères, et c'est tout. Pas de poulpe. Pas encore.",
}

## Quand on le trouve (selon la cachette).
const POULPE_TROUVE := {
	"theiere": ["Tu soulèves le couvercle de la théière… Deux yeux te regardent, tout blancs à fleurs bleues, comme la porcelaine. « Bloup. » Trouvé !",
		"Dans la théière, roulé en boule, un petit poulpe couleur de porcelaine. Il te fait coucou avec un tentacule. Trouvé !"],
	"coussin": ["Tu soulèves le coussin… Un petit poulpe tout plat, exactement de la couleur du canapé, prend une grande inspiration. Trouvé !",
		"Sous le coussin, il y a une crêpe. Une crêpe qui a deux yeux. Et huit bras. Trouvé !"],
	"tiroir": ["Tu ouvres le tiroir… Les chaussettes sont rangées par couleur, et au milieu, un petit poulpe mauve fait semblant d'être une chaussette. Trouvé !",
		"Dans le tiroir, une chaussette te regarde. Puis elle agite un tentacule. Trouvé !"],
	"hublot": ["Ce n'est pas la mer qui est si sombre : c'est un petit poulpe bleu nuit, collé au verre, qui regarde les poissons-lanternes. Trouvé !",
		"Sur le hublot, une tache bleu nuit… avec deux yeux. Il disait bonjour aux poissons du dehors. Trouvé !"],
	"cuilleres": ["Dans le pot à cuillères, une cuillère te regarde. Puis huit bras couleur d'argent se lèvent : il range les cuillères, très sérieusement. Trouvé !",
		"Le pot à cuillères fait « tchling ». Dedans, un petit poulpe argenté tient une cuillère dans chaque tentacule. Trouvé !"],
}


## Le petit poulpe : un manteau rond (la tête), deux gros yeux, huit bras de trois morceaux qui ondulent ;
## les pieds (la base des bras) à l'origine, les yeux vers +Z. `peau` : le matériau qui change de couleur.
static func _poulpe_corps(M, peau: StandardMaterial3D) -> Dictionary:
	var n := Node3D.new()
	M.room.add_child(n)
	var corps := Node3D.new()
	n.add_child(corps)
	_p(corps, I._sph(0.05), peau, Vector3(0, 0.09, -0.02), Vector3(1.0, 1.35, 1.15), Vector3(-0.4, 0, 0))
	_p(corps, I._sph(0.034), peau, Vector3(0, 0.045, 0.01), Vector3(1.15, 0.8, 1.0))
	var blanc := _mat(Color(0.97, 0.97, 0.95), 0.0, 0.2)
	var noir := _mat(Color(0.03, 0.03, 0.04), 0.0, 0.1)
	var yeux: Array = []
	for sx in [-1.0, 1.0]:
		var oe := Node3D.new()
		corps.add_child(oe)
		oe.position = Vector3(sx * 0.024, 0.062, 0.03)
		_p(oe, I._sph(0.014), blanc, Vector3.ZERO)
		_p(oe, I._sph(0.0075), noir, Vector3(0, 0, 0.01))
		yeux.append(oe)
	var tent: Array = []
	var rr: Array = [0.011, 0.008, 0.0055, 0.003]
	for k in range(8):
		var a: float = TAU * k / 8.0 + PI / 8.0
		var piv := Node3D.new()
		n.add_child(piv)
		piv.position = Vector3(sin(a) * 0.022, 0.03, cos(a) * 0.022)
		piv.rotation = Vector3(0, a, 0)
		var segs: Array = []
		var par: Node3D = piv
		for j in range(3):
			var sg := Node3D.new()
			par.add_child(sg)
			sg.position = Vector3(0, 0, 0.0 if j == 0 else 0.048)
			_p(sg, I._cyl(float(rr[j + 1]), float(rr[j]), 0.05, 6), peau, Vector3(0, 0, 0.024), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
			segs.append(sg)
			par = sg
		tent.append(segs)
	_sans_ombre(n)
	return {"n": n, "corps": corps, "yeux": yeux, "tent": tent}


## Le poulpe évadé. Dans le salon, un aquarium de verre et de titane (sable blanc, coraux, son petit pot
## de terre couché) ; et son petit poulpe (Gribouille, Chaussette ou Bigoudi, selon la maison) qui s'en
## évade tout le temps : par le couvercle entrouvert, il file se cacher à un endroit tiré au sort (dans la
## théière, sous un coussin du canapé, dans le tiroir aux chaussettes, collé au hublot, dans le pot à
## cuillères du buffet) et il prend la couleur de l'endroit. Pour le chercher : des traces mouillées sur le
## terrazzo, des « bloup » qui sortent de sa cachette, et les indices de l'enfant complice. On le remet
## dans l'aquarium (la première fois, il fouille dans son pot et donne son trésor), on lui donne une
## crevette, on admire ses couleurs… et un peu plus tard, il ressort. Les parents sont débordés. La nuit :
## soit il dort en boule dans le bocal à biscuits (il rêve en couleurs), soit il fait des bêtises en douce
## pendant que Papa ronfle, et l'enfant en pyjama chuchote.
static func _poulpe(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var room0: Node = M.room
	var nuit: bool = _nuit(M)
	var s: float = 1.0 if r.randf() < 0.5 else -1.0
	var ni: int = r.randi() % 3
	var boy: bool = r.randf() < 0.5
	var dodo: bool = nuit and r.randf() < 0.6
	var ami: bool = bool(M.state().get("da_poulpe_ami", false))
	# --- les repères : l'aquarium contre le mur du fond (côté s), la commode au fond (côté -s), le canapé
	# contre le mur -s (sous le hublot), le buffet contre le mur s (à côté du hublot)
	var zh: float = 0.0 if R.D < 7.0 else -hd + R.D * 0.25
	var xa: float = s * 1.05
	var za: float = -hd + 0.3
	var txa: float = xa - s * 0.17
	var zc: float = clampf(-hd * 0.15, -hd + 1.5, hd - 2.6)
	var cax: float = -s * (hw - 0.55)
	var tbx: float = -s * (hw - 1.6)
	var cmx: float = -s * (hw - 0.9)
	var cmz: float = -hd + 0.25
	var bx: float = s * (hw - 0.3)
	var zb: float = clampf(zh + 1.25, -hd + 1.4, hd - 2.0)
	var col_can: String = str(_pick(M, ["turquoise", "rose", "jaune"]))
	var camo_can: Color = {"turquoise": Color(0.2, 0.62, 0.62), "rose": Color(0.92, 0.6, 0.66), "jaune": Color(0.92, 0.75, 0.25)}[col_can]
	var nacre := _mat(Color(0.95, 0.95, 0.97), 0.15, 0.25)
	var titane := _mat(Color(0.8, 0.82, 0.86), 0.9, 0.3)
	var aigue := _mat(Color(0.3, 0.95, 0.85), 0.0, 0.4, 2.2)
	# --- le salon : le canapé, la table basse sur le tapis, le fauteuil de Papa, le lampadaire
	R.canape(cax, zc, 90.0 * s, col_can, 1.9)
	R.tapis(tbx + s * 0.2, zc, 90, minf(2.4, R.D - 3.0), 1.7)
	_table_basse(M, tbx, zc, 0.6, 1.0)
	var fx: float = -s * (hw - 1.75)
	var fz: float = clampf(zc + 1.55, -hd + 0.8, hd - 1.7)
	var fyaw: float = _vers(fx, fz, xa, za)
	R.fauteuil(fx, fz, fyaw, "blanc")
	if R.is_free(-s * (hw - 0.45), clampf(zc + 1.3, -hd + 1.0, hd - 1.2), 0.45, 0.45):
		_lampadaire(M, -s * (hw - 0.45), clampf(zc + 1.3, -hd + 1.0, hd - 1.2))
	_cadres(M, 2)
	if R.is_free(s * (hw - 0.5), -hd + 0.5, 0.45, 0.45):
		_pot(M, s * (hw - 0.5), -hd + 0.5, 0.0, 1.1, "")
	# une tasse sur la table basse (la théière est à part : elle s'ouvre)
	R.kit.cyl(R.L(tbx + 0.12 * s, 0.38, zc + 0.25), 0.035, 0.03, 0.06, "ceramique", 10)
	# --- l'aquarium : le meuble de nacre, le plateau de titane, la boîte de crevettes
	R.kit.box(R.L(xa, 0.36, za), Vector3(1.6, 0.72, 0.5), "ceramique", 1.0)
	R.kit.box(R.L(xa, 0.73, za), Vector3(1.64, 0.025, 0.54), "argent", 1.0)
	R.kit.col_box(R.L(xa, 0.7, za), Vector3(1.6, 1.4, 0.5))
	R.reserve(xa, za, 1.8, 0.8)
	R.mark_wall(xa, 1.2, -hd + 0.02, 0.95)
	R.kit.cyl(R.L(xa + s * 0.62, 0.742, za + 0.05), 0.05, 0.05, 0.065, "argent", 12)
	R.kit.cyl(R.L(xa + s * 0.62, 0.762, za + 0.05), 0.051, 0.051, 0.025, "tissu_rose", 12, false)
	var aq: Node3D = I._node(M, R.P(txa, 0.745, za), 0)
	_p(aq, I._boxm(Vector3(1.16, 0.44, 0.42)), _verre(Color(0.25, 0.7, 0.85), 0.22, 0.15), Vector3(0, 0.22, 0))
	_p(aq, I._boxm(Vector3(1.2, 0.48, 0.46)), _verre(Color(0.8, 0.95, 1.0), 0.08), Vector3(0, 0.24, 0))
	for cx2 in [-0.6, 0.6]:
		for cz2 in [-0.23, 0.23]:
			_p(aq, I._boxm(Vector3(0.022, 0.48, 0.022)), titane, Vector3(float(cx2), 0.24, float(cz2)))
	for cz3 in [-0.23, 0.23]:
		_p(aq, I._boxm(Vector3(1.22, 0.022, 0.022)), titane, Vector3(0, 0.011, float(cz3)))
	_p(aq, I._boxm(Vector3(1.2, 0.012, 0.012)), aigue, Vector3(0, 0.03, 0.236))
	_p(aq, I._boxm(Vector3(1.16, 0.04, 0.42)), _mat(Color(0.93, 0.9, 0.82), 0.0, 1.0), Vector3(0, 0.02, 0))
	var cor: Array = [Color(1.0, 0.45, 0.55), Color(1.0, 0.6, 0.25), Color(0.65, 0.4, 0.95), Color(0.95, 0.85, 0.4)]
	for k in range(7):
		var ccx: float = -0.5 + k * 0.16 + r.randf_range(-0.03, 0.03)
		var ccz: float = r.randf_range(-0.15, 0.0)
		var cm := _mat(cor[k % cor.size()], 0.0, 0.7, 0.25)
		if k % 3 == 0:
			_p(aq, I._sph(0.045), cm, Vector3(ccx, 0.06, ccz), Vector3(1.0, 0.7, 1.0))
		else:
			for b2 in range(3):
				_p(aq, I._cyl(0.006, 0.012, 0.12 + 0.05 * b2, 5), cm, Vector3(ccx + (b2 - 1) * 0.02, 0.09 + 0.02 * b2, ccz), Vector3.ONE, Vector3(0, 0, (b2 - 1) * 0.35))
	# son pot de terre, couché dans le sable (sa maison : son trésor est dedans)
	_p(aq, I._cyl(0.06, 0.075, 0.15, 12), _mat(Color(0.72, 0.4, 0.26), 0.0, 0.85), Vector3(s * 0.38, 0.1, 0.06), Vector3.ONE, Vector3(0, 0, PI * 0.5))
	_p(aq, I._cyl(0.05, 0.05, 0.005, 12), _mat(Color(0.12, 0.06, 0.04), 0.0, 1.0), Vector3(s * 0.3, 0.1, 0.06), Vector3.ONE, Vector3(0, 0, PI * 0.5))
	# le couvercle de titane (il s'ouvre par devant : une charnière au fond)
	var couv := Node3D.new()
	aq.add_child(couv)
	couv.position = Vector3(0, 0.49, -0.23)
	_p(couv, I._boxm(Vector3(1.22, 0.02, 0.47)), titane, Vector3(0, 0, 0.235))
	_p(couv, I._boxm(Vector3(1.0, 0.01, 0.01)), aigue, Vector3(0, -0.005, 0.46))
	for vx in [-0.35, 0.0, 0.35]:
		_p(couv, I._boxm(Vector3(0.04, 0.03, 0.02)), titane, Vector3(float(vx), -0.01, 0.47))
	var lum := OmniLight3D.new()
	lum.light_color = Color(0.4, 0.9, 0.95)
	lum.light_energy = 0.9 if nuit else 0.5
	lum.omni_range = 2.4
	lum.shadow_enabled = false
	aq.add_child(lum)
	lum.position = Vector3(0, 0.35, 0.1)
	var bub := CPUParticles3D.new()
	bub.amount = 14
	bub.lifetime = 1.6
	bub.preprocess = 1.6
	bub.direction = Vector3.UP
	bub.spread = 8.0
	bub.initial_velocity_min = 0.22
	bub.initial_velocity_max = 0.3
	bub.gravity = Vector3.ZERO
	bub.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	bub.emission_box_extents = Vector3(0.015, 0.01, 0.015)
	var bm := SphereMesh.new()
	bm.radius = 0.008
	bm.height = 0.016
	bm.material = _verre(Color(0.85, 0.97, 1.0), 0.55)
	bub.mesh = bm
	aq.add_child(bub)
	bub.position = Vector3(-s * 0.45, 0.05, -0.1)
	_sans_ombre(aq)
	var AQC: Vector3 = R.P(txa, 0.79, za)
	var AQH: Vector3 = R.P(txa, 1.32, za + 0.05)
	var SORTIE: Vector3 = R.P(txa + s * 0.42, 1.25, za + 0.22)
	# --- la commode de nacre (le tiroir du haut s'ouvre : les chaussettes rangées par couleur) et, dessus,
	# le bocal à biscuits (son lit, la nuit)
	R.kit.box(R.L(cmx, 0.4, cmz), Vector3(1.0, 0.8, 0.45), "ceramique", 1.0)
	R.kit.box(R.L(cmx, 0.805, cmz), Vector3(1.04, 0.02, 0.48), "argent", 1.0)
	for yy in [0.16, 0.4]:
		R.kit.box(R.L(cmx, float(yy), cmz + 0.226), Vector3(0.92, 0.2, 0.01), "argent", 1.0, 16)
		R.kit.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), R.P(cmx, float(yy), cmz + 0.235)), 0.016, 0.016, 0.02, "argent", 8)
	R.kit.col_box(R.L(cmx, 0.4, cmz), Vector3(1.0, 0.8, 0.45))
	R.reserve(cmx, cmz, 1.2, 0.75)
	var dr: Node3D = I._node(M, R.P(cmx, 0.66, cmz), 0)
	_p(dr, I._boxm(Vector3(0.92, 0.2, 0.02)), nacre, Vector3(0, 0, 0.235))
	_p(dr, I._sph(0.018), titane, Vector3(0, 0, 0.255))
	_p(dr, I._boxm(Vector3(0.86, 0.01, 0.42)), nacre, Vector3(0, -0.085, 0.02))
	for sx3 in [-1.0, 1.0]:
		_p(dr, I._boxm(Vector3(0.01, 0.14, 0.42)), nacre, Vector3(sx3 * 0.43, -0.02, 0.02))
	var chau: Array = [Color(0.85, 0.2, 0.2), Color(1.0, 0.6, 0.2), Color(0.95, 0.85, 0.3), Color(0.3, 0.7, 0.4), Color(0.3, 0.5, 0.9), Color(0.6, 0.4, 0.85)]
	for k2 in range(6):
		_p(dr, I._boxm(Vector3(0.1, 0.05, 0.3)), _mat(chau[k2], 0.0, 1.0), Vector3(-0.35 + k2 * 0.14, -0.055, 0.03))
	var BOCAL: Vector3 = R.P(cmx + 0.28, 0.815, cmz)
	var boc: Node3D = I._node(M, BOCAL, 0)
	_p(boc, I._cyl(0.1, 0.1, 0.22, 18), _verre(Color(0.85, 0.95, 1.0), 0.18), Vector3(0, 0.11, 0))
	_p(boc, I._cyl(0.085, 0.085, 0.03, 18), titane, Vector3(0, 0.235, 0))
	# --- la théière de porcelaine (le couvercle s'ouvre), sur la table basse
	var TP: Vector3 = R.P(tbx, 0.38, zc - 0.2)
	var th: Node3D = I._node(M, TP, 90.0 * s)
	var porc := _mat(Color(0.96, 0.97, 1.0), 0.0, 0.15)
	var bleu := _mat(Color(0.25, 0.4, 0.85), 0.0, 0.3)
	_p(th, I._sph(0.09), porc, Vector3(0, 0.075, 0), Vector3(1.0, 0.85, 1.0))
	_p(th, I._cyl(0.012, 0.02, 0.12, 8), porc, Vector3(0, 0.1, 0.1), Vector3.ONE, Vector3(0.9, 0, 0))
	var anse := TorusMesh.new()
	anse.inner_radius = 0.035
	anse.outer_radius = 0.048
	_p(th, anse, porc, Vector3(0, 0.085, -0.09), Vector3.ONE, Vector3(0, 0, PI * 0.5))
	for k3 in range(6):
		var a3: float = TAU * k3 / 6.0
		_p(th, I._sph(0.012), bleu, Vector3(sin(a3) * 0.088, 0.08, cos(a3) * 0.088), Vector3(1.0, 1.0, 0.4), Vector3(0, a3, 0))
	var lid: Node3D = I._node(M, TP + Vector3(0, 0.145, 0), 0)
	_p(lid, I._cyl(0.045, 0.055, 0.02, 14), porc, Vector3(0, 0.01, 0))
	_p(lid, I._sph(0.014), bleu, Vector3(0, 0.03, 0))
	# --- le coussin du canapé (il se soulève)
	var CU: Vector3 = R.P(-s * (hw - 0.6), 0.555, zc + 0.45)
	var cus: Node3D = I._node(M, CU, 90.0 * s)
	_p(cus, I._boxm(Vector3(0.42, 0.13, 0.4)), R.kit.mats["tissu_" + col_can], Vector3.ZERO)
	# --- le buffet de nacre contre le mur s : le pot à cuillères, et les cuillères rangées en étoile
	R.kit.box(R.L(bx, 0.45, zb), Vector3(0.5, 0.9, 1.4), "ceramique", 1.0)
	R.kit.box(R.L(bx, 0.915, zb), Vector3(0.54, 0.03, 1.44), "argent", 1.0)
	R.kit.box(R.L(bx - s * 0.255, 0.45, zb), Vector3(0.01, 0.06, 1.3), "argent", 1.0, 16)
	R.kit.col_box(R.L(bx, 0.45, zb), Vector3(0.5, 0.9, 1.4))
	R.reserve(bx, zb, 0.8, 1.6)
	for k4 in range(8):
		var a4: float = TAU * k4 / 8.0
		var yw: float = 90.0 - rad_to_deg(a4)
		R.kit.box(R.L(bx + cos(a4) * 0.1, 0.934, zb + 0.25 + sin(a4) * 0.1, yw), Vector3(0.014, 0.006, 0.12), "argent", 1.0)
		R.kit.box(R.L(bx + cos(a4) * 0.18, 0.936, zb + 0.25 + sin(a4) * 0.18, yw), Vector3(0.035, 0.01, 0.045), "argent", 1.0)
	_pot(M, bx, zb + 0.55, 0.93, 0.6, "")
	var SP: Vector3 = R.P(bx, 0.93, zb - 0.4)
	var sp: Node3D = I._node(M, SP, 0)
	_p(sp, I._cyl(0.07, 0.06, 0.14, 14), nacre, Vector3(0, 0.07, 0))
	for k5 in range(5):
		var a5: float = TAU * k5 / 5.0
		_p(sp, I._boxm(Vector3(0.012, 0.2, 0.004)), titane, Vector3(sin(a5) * 0.03, 0.17, cos(a5) * 0.03), Vector3.ONE, Vector3(cos(a5) * 0.25, 0, -sin(a5) * 0.25))
	# --- le hublot (sur le mur s) : on peut s'y coller
	var HB: Vector3 = R.P(s * (hw - 0.07), 1.47, zh)
	# --- les cachettes : où il se cache, où il se montre, sa couleur là, sa taille, si on le voit
	var spots := {
		"theiere": {"cache": TP + Vector3(0, 0.04, 0), "peek": TP + Vector3(0, 0.16, 0), "camo": Color(0.9, 0.93, 1.0), "hs": 0.5, "vis": false, "sol": R.P(tbx + s * 0.65, 0, zc - 0.2)},
		"coussin": {"cache": R.P(-s * (hw - 0.6), 0.49, zc + 0.45), "peek": R.P(-s * (hw - 0.88), 0.49, zc + 0.45), "camo": camo_can, "hs": 0.8, "vis": true, "sol": R.P(-s * (hw - 1.2), 0, zc + 0.85)},
		"tiroir": {"cache": R.P(cmx, 0.6, cmz + 0.1), "peek": R.P(cmx, 0.6, cmz + 0.32), "camo": Color(0.72, 0.6, 0.85), "hs": 0.6, "vis": false, "sol": R.P(cmx + s * 0.1, 0, cmz + 0.9)},
		"hublot": {"cache": HB, "peek": HB, "camo": Color(0.05, 0.2, 0.33), "hs": 1.0, "vis": true, "sol": R.P(s * (hw - 0.95), 0, zh - 0.35)},
		"cuilleres": {"cache": SP + Vector3(0, 0.03, 0), "peek": SP + Vector3(0, 0.15, 0), "camo": Color(0.82, 0.85, 0.9), "hs": 0.45, "vis": false, "sol": R.P(s * (hw - 1.0), 0, zb - 0.45)},
	}
	var objs := {"theiere": lid, "coussin": cus, "tiroir": dr, "cuilleres": sp}
	var base := {}
	for kk in objs:
		base[kk] = (objs[kk] as Node3D).global_transform
	# --- les traces mouillées (de l'aquarium vers sa cachette)
	var mouille := _verre(Color(0.12, 0.22, 0.32), 0.35)
	var goutte: CylinderMesh = I._cyl(0.035, 0.035, 0.003, 10)
	var traces: Array = []
	for k6 in range(5):
		var tr := MeshInstance3D.new()
		tr.mesh = goutte
		tr.material_override = mouille
		tr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tr.visible = false
		M.room.add_child(tr)
		traces.append(tr)
	# --- le poulpe
	var BASE: Color = Color(0.95, 0.45, 0.3)
	var peau := _mat(BASE, 0.0, 0.45, 0.15)
	var pc: Dictionary = _poulpe_corps(M, peau)
	var pn: Node3D = pc["n"]
	var corps: Node3D = pc["corps"]
	var yeux: Array = pc["yeux"]
	var tent: Array = pc["tent"]
	var ids: Array = spots.keys()
	var st := {"t": r.randf() * 10.0, "mode": "dodo" if dodo else "cache", "spot": str(ids[r.randi() % ids.size()]), "pos": BOCAL, "from": Vector3.ZERO, "to": Vector3.ZERO,
		"k": 0.0, "dur": 1.0, "arc": 0.0, "ensuite": "", "sc": 0.55, "sc_to": 0.55, "vis": true, "flash": 0.0, "show": 0.0, "faim": 0.0, "reve": 0.0,
		"evasion": 45.0, "bloup": 3.0, "sec": 0.0, "crevettes": 0, "evasions": 0, "rot": 0.0}
	# --- les gens : la maman débordée au buffet, le papa qui lit dans son fauteuil, l'enfant complice devant
	# l'aquarium ; la nuit, Papa dort dans le fauteuil (et l'enfant, en pyjama, chuchote… si le poulpe est sorti)
	var maman: Node = null
	var kid: Node = null
	var papa: Node = M.person("homme", fx, fz, fyaw, "dormir_assis" if nuit else "lire")
	var kp: Vector2 = _dedans(M, xa - s * 1.05, za + 0.95)
	if nuit:
		papa.lines = ["Zzz…", "Zzz… pas dans la théière… zzz…", "Zzz… trois verrous… il les ouvre dans l'ordre… zzz…",
			["Mmh… Gribouille… au lit… zzz…", "Mmh… Chaussette… au lit… zzz…", "Mmh… Bigoudi… au lit… zzz…"][ni]]
		papa.line_every = Vector2(10.0, 15.0)
		if not dodo:
			kid = M.person("garcon" if boy else "fille", kp.x, kp.y, _vers(kp.x, kp.y, xa, za), "debout")
			kid.lines = ["Chut… il est sorti. Papa dort.", "Je suis son complice. C'est un travail de nuit.", "Tu l'entends ? Bloup… Il est par là.",
				"Si Papa se réveille, on dit que c'est le chat. … On n'a pas de chat."]
			kid.line_every = Vector2(9.0, 14.0)
	else:
		papa.lines = ["Quelqu'un a lu mon journal avant moi. Il y a des traces de ventouses.", "Il m'a rangé mes chaussettes par couleur. Je n'avais rien demandé.",
			["Gribouille, si tu m'entends : rends-moi ma cuillère à thé.", "Chaussette, si tu m'entends : rends-moi ma cuillère à thé.", "Bigoudi, si tu m'entends : rends-moi ma cuillère à thé."][ni],
			"Je cherche un article qui explique comment garder un poulpe dans un aquarium. Il n'y en a pas."]
		papa.line_every = Vector2(9.0, 14.0)
		var mx: float = s * (hw - 1.0)
		var mz: float = clampf(zb + 0.3, -hd + 0.6, hd - 1.6)
		maman = M.person("femme", mx, mz, 90.0 * s, "cuisiner")
		maman.lines = ["Qui a rangé les cuillères en étoile ? … Je sais qui.", "J'avais demandé un poisson rouge. Un POISSON ROUGE.", "Si vous trouvez mes clés, elles sont sûrement dans la théière.",
			"Trois verrous sur le couvercle. Il les ouvre tous les trois. Dans l'ordre !", "Bonnes bulles ! Attention où vous vous asseyez."]
		maman.line_every = Vector2(8.0, 13.0)
		kid = M.person("garcon" if boy else "fille", kp.x, kp.y, _vers(kp.x, kp.y, xa, za), "observer")
		kid.lines = ["Moi, je sais où il est. Mais je ne dis rien.", "Il m'a fait un clin d'œil avec un tentacule !",
			"Quand je serai grand, je serai poulpe." if boy else "Quand je serai grande, je serai poulpe.", "Maman dit qu'il est infernal. Moi, je dis qu'il est malin.",
			["Gribouille ! Gribouille ! … Il ne vient jamais quand on l'appelle.", "Chaussette ! Chaussette ! … Elle ne vient jamais quand on l'appelle.", "Bigoudi ! Bigoudi ! … Il ne vient jamais quand on l'appelle."][ni]]
		kid.line_every = Vector2(6.0, 10.0)
		if ami:
			S._say_late(M, kid, "Il te reconnaît ! Il a fait le tentacule qui dit bonjour !", 2.5)
	# --- ouvrir / refermer une cachette (le couvercle de la théière, le coussin, le tiroir, le pot)
	var ouvrir := func(id: String, ouvert: bool) -> void:
		if not objs.has(id):
			return
		var n: Node3D = objs[id]
		if not is_instance_valid(n):
			return
		var b: Transform3D = base[id]
		var to: Transform3D = b
		if ouvert:
			match id:
				"theiere":
					to = Transform3D(Basis(Vector3.BACK, 0.7) * b.basis, b.origin + Vector3(0.04, 0.07, 0))
				"coussin":
					to = Transform3D(Basis(Vector3.BACK, s * 0.9) * b.basis, b.origin + Vector3(-s * 0.06, 0.14, 0))
				"tiroir":
					to = Transform3D(b.basis, b.origin + Vector3(0, 0, 0.3))
				"cuilleres":
					to = Transform3D(Basis(Vector3.BACK, 0.3 * s) * b.basis, b.origin)
		elif id == "coussin" and str(st["spot"]) == "coussin" and str(st["mode"]) == "cache":
			to = Transform3D(b.basis, b.origin + Vector3(0, 0.05, 0))
		var tw: Tween = M.room.create_tween()
		tw.tween_property(n, "global_transform", to, 0.35).set_trans(Tween.TRANS_SINE)
	# --- les traces mouillées, de l'aquarium jusqu'à (presque) la cachette
	var poser_traces := func(montrer: bool) -> void:
		var sd: Dictionary = spots[str(st["spot"])]
		var c: Vector3 = sd["cache"]
		var a: Vector3 = R.P(txa, 0.006, za + 0.4)
		var b: Vector3 = Vector3(c.x, a.y, c.z)
		var side: Vector3 = (b - a).cross(Vector3.UP).normalized() * 0.06
		for i in range(traces.size()):
			var tr: MeshInstance3D = traces[i]
			if not is_instance_valid(tr):
				continue
			tr.visible = montrer
			tr.global_position = a.lerp(b, 0.12 + 0.15 * i) + side * (1.0 if i % 2 == 0 else -1.0)
	# --- l'indice de l'enfant (selon où il est)
	var indice := func() -> String:
		match str(st["mode"]):
			"cache":
				return str(_pick(M, POULPE_INDICES[str(st["spot"])]))
			"trouve":
				return "Mais tu l'as trouvé ! Il est là, il te regarde. Remets-le dans l'aquarium, sinon il repart."
			"aquarium":
				return "Il est dans l'aquarium, là. Pour l'instant. Compte jusqu'à cinquante et regarde encore."
			"dodo":
				return "Il dort dans le bocal à biscuits, sur la commode. Chut."
		return "Trop tard, il file ! Regarde bien où il va !"
	# --- la récompense (une seule fois) : il fouille dans son pot et donne son trésor
	var recompense := func() -> void:
		if bool(M.state().get("da_poulpe", false)):
			return
		await M.get_tree().create_timer(1.6).timeout
		if not _la(M, room0):
			return
		M.state()["da_poulpe"] = true
		var it: String = _neuf(M, "perle_azur", "coquillage_chanteur")
		var f: Node = maman if maman != null else kid if kid != null else papa
		var txt: String
		if f == maman:
			txt = "Regardez : il fouille dans son petit pot… et il vous tend quelque chose du bout d'un tentacule. Une perle d'Azur ! C'est la mienne : il me l'avait « rangée » il y a un mois. Chez les poulpes, ça veut dire merci. Gardez-la." if it == "perle_azur" else \
				"Regardez : il fouille dans son petit pot… et il vous tend quelque chose du bout d'un tentacule. Un coquillage qui chante ! C'est celui de la salle de bain : il l'avait « rangé ». Chez les poulpes, ça veut dire merci. Gardez-le."
		elif f == kid:
			txt = "Regarde, il te donne un truc de son trésor ! Une perle d'Azur… c'est celle de Maman. Chut, garde-la : chez les poulpes, ça veut dire merci." if it == "perle_azur" else \
				"Regarde, il te donne un truc de son trésor ! Un coquillage qui chante… c'est celui de la salle de bain. Chut, garde-le : chez les poulpes, ça veut dire merci."
		else:
			txt = "Mmh ? … Il vous donne quelque chose de son trésor ? Alors gardez-le. Chez les poulpes, ça veut dire merci. … Zzz…"
		M.talk(f, txt, I._bye("Merci, petit poulpe !"), func(_i):
			M.give([[it, 1]], "")
			M.close_talk(), "à voix basse" if nuit else "ému")
	# --- quand un trajet est fini : la suite (filer vers la cachette, s'y cacher, plonger dans l'aquarium)
	var arrive := func() -> void:
		match str(st["ensuite"]):
			"file":
				var sd: Dictionary = spots[str(st["spot"])]
				st["from"] = SORTIE
				st["to"] = sd["cache"]
				st["k"] = 0.0
				st["dur"] = 2.6
				st["arc"] = 0.4
				st["ensuite"] = "cache"
				st["sc_to"] = float(sd["hs"])
				ouvrir.call(str(st["spot"]), true)
				_bulle(M, SORTIE + Vector3(0, 0.15, 0), "Flop !", Color(1.0, 0.75, 0.6), 30, 0.35, 1.3)
				var tw0: Tween = M.room.create_tween()
				tw0.tween_property(couv, "rotation:x", -0.18, 0.4)
			"cache":
				var sd2: Dictionary = spots[str(st["spot"])]
				st["mode"] = "cache"
				st["vis"] = bool(sd2["vis"])
				st["bloup"] = 4.0
				st["evasions"] = int(st["evasions"]) + 1
				ouvrir.call(str(st["spot"]), false)
				poser_traces.call(true)
			"plouf":
				st["mode"] = "aquarium"
				st["sc_to"] = 0.9
				st["evasion"] = r.randf_range(40.0, 65.0) if not nuit else r.randf_range(55.0, 80.0)
				M.main.sfx("plouf", AQH, -14.0 if nuit else -6.0)
				M.main.sfx("bulles", AQC, -12.0)
				_bulle(M, AQH + Vector3(0, 0.1, 0), "Plouf !", Color(0.7, 0.92, 1.0), 40, 0.45, 1.4)
				var tw1: Tween = M.room.create_tween()
				tw1.tween_property(couv, "rotation:x", 0.0, 0.4).set_delay(0.6)
				M.main.sfx("serrure", AQH, -14.0)
				poser_traces.call(false)
				if bool(M.state().get("da_poulpe", false)):
					if maman != null:
						S._say_late(M, maman, str(_pick(M, ["Merci ! Je referme les trois verrous. Dans l'ordre.", "Et une de plus ! On tient le compte sur le frigo : quarante-deux évasions cette semaine.",
							"Merci. Il va ressortir, hein. Mais merci."])), 1.2)
					elif kid != null:
						S._say_late(M, kid, "Chut… bravo. Il est rentré. Pour l'instant.", 1.2)
				else:
					recompense.call()
	# --- l'évasion : il soulève le couvercle, file à une cachette tirée au sort
	var evader := func() -> void:
		var choix: Array = spots.keys()
		choix.erase(str(st["spot"]))
		st["spot"] = str(choix[randi() % choix.size()])
		st["mode"] = "trajet"
		st["from"] = st["pos"]
		st["to"] = SORTIE
		st["k"] = 0.0
		st["dur"] = 1.5
		st["arc"] = 0.05
		st["ensuite"] = "file"
		st["sc_to"] = 0.8
		var tw: Tween = M.room.create_tween()
		tw.tween_property(couv, "rotation:x", -0.32, 0.5).set_trans(Tween.TRANS_SINE)
		M.main.sfx("serrure", SORTIE, -12.0 if nuit else -6.0)
		if maman != null:
			maman.gesture("sursaut", 1.5)
			maman.say(str(_pick(M, ["Il est ENCORE sorti !", "Le couvercle ! Qui a ouvert le couv… Ah. Lui.", "Non, non, non ! Reviens ici, toi !",
				"Trois verrous ! TROIS ! Et il les ouvre comme des boîtes de biscuits !"])), 3.0)
		if kid != null:
			if nuit:
				S._say_late(M, kid, "Il ressort… Chut ! Regarde où il va !", 0.6)
			else:
				kid.gesture("rire", 2.0)
				S._say_late(M, kid, str(_pick(M, ["Il s'évade ! Il s'évade !", "Regarde bien où il va… moi, je ne dis rien !", "Ha ha ! Il est trop fort !"])), 0.8)
	# --- ce qui bouge : le poulpe (où il est, sa taille, sa couleur, ses bras, ses yeux), ses « bloup »
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(pn):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var mode: String = str(st["mode"])
		var p: Vector3 = st["pos"]
		var pose: String = "marche"
		var face: Vector3 = Vector3.ZERO
		var sid: String = str(st["spot"])
		var sd: Dictionary = spots[sid]
		var coul: Color = BASE
		var plat: bool = false
		var sc_to: float = float(st["sc_to"])
		match mode:
			"aquarium":
				pose = "nage"
				var ph: float = t * 0.35
				var tg: Vector3 = AQC + Vector3(0.34 * sin(ph), 0.06 + 0.05 * sin(t * 0.9), 0.08 * cos(ph * 1.3))
				p = p.move_toward(tg, dt * 0.4)
				face = Vector3(cos(ph), 0, -0.3 * sin(ph * 1.3))
				st["evasion"] = float(st["evasion"]) - dt
				if float(st["evasion"]) <= 0.0 and float(st["show"]) <= 0.0 and float(st["faim"]) <= 0.0:
					evader.call()
			"trajet":
				pose = "nage"
				var k: float = minf(1.0, float(st["k"]) + dt / float(st["dur"]))
				st["k"] = k
				var fr: Vector3 = st["from"]
				var to: Vector3 = st["to"]
				p = fr.lerp(to, k) + Vector3(0, float(st["arc"]) * sin(PI * k), 0)
				face = to - fr
				if str(st["ensuite"]) == "cache":
					coul = BASE.lerp(sd["camo"], k)
				if k >= 1.0:
					arrive.call()
			"cache":
				pose = "plat" if sid == "hublot" else "boule"
				plat = sid == "hublot" or sid == "coussin"
				p = sd["cache"]
				coul = sd["camo"]
				sc_to = float(sd["hs"])
				st["bloup"] = float(st["bloup"]) - dt
				if float(st["bloup"]) <= 0.0:
					st["bloup"] = randf_range(8.0, 13.0)
					st["sec"] = 0.6
					_bulle(M, p + Vector3(0, 0.2, 0), "bloup", Color(0.75, 0.9, 1.0, 0.85), 22 if nuit else 26, 0.3, 1.4)
					M.main.sfx("bulles", p, -22.0 if nuit else -16.0)
				# la cachette qui bouge un peu (le couvercle tressaute, le coussin frémit)
				if float(st["sec"]) > 0.0 and objs.has(sid):
					st["sec"] = float(st["sec"]) - dt
					var on: Node3D = objs[sid]
					var b: Transform3D = base[sid]
					if sid == "coussin":
						b.origin += Vector3(0, 0.05, 0)
					on.global_transform = b * Transform3D(Basis(Vector3.BACK, 0.07 * sin(t * 40.0) * maxf(0.0, float(st["sec"]))), Vector3.ZERO)
			"trouve":
				pose = "plat" if sid == "hublot" else "marche"
				plat = sid == "hublot"
				p = sd["peek"]
				coul = sd["camo"]
				sc_to = 1.0 if sid == "hublot" else 0.85
				face = M.main._player_pos_v27() - p
			"dodo":
				pose = "boule"
				p = BOCAL + Vector3(0, 0.02, 0)
				sc_to = 0.55
				coul = POULPE_REVE[0]
				if float(st["reve"]) > 0.0:
					st["reve"] = float(st["reve"]) - dt
					var u: float = t * 0.5
					coul = (POULPE_REVE[int(u) % 4] as Color).lerp(POULPE_REVE[(int(u) + 1) % 4], u - floorf(u))
		# les couleurs : l'arc-en-ciel, le rouge de la crevette, le blanc de la surprise
		if float(st["show"]) > 0.0:
			st["show"] = float(st["show"]) - dt
			var u2: float = t * 1.4
			coul = (POULPE_ARC[int(u2) % 7] as Color).lerp(POULPE_ARC[(int(u2) + 1) % 7], u2 - floorf(u2))
		if float(st["faim"]) > 0.0:
			st["faim"] = float(st["faim"]) - dt
			coul = Color(0.85, 0.12, 0.1)
		if float(st["flash"]) > 0.0:
			st["flash"] = float(st["flash"]) - dt
			coul = Color(1.0, 1.0, 1.0)
		var lc: float = clampf(dt * 3.5, 0.0, 1.0)
		peau.albedo_color = peau.albedo_color.lerp(coul, lc)
		peau.emission = peau.albedo_color
		peau.metallic = lerpf(peau.metallic, 0.75 if (sid == "cuilleres" and mode in ["cache", "trouve"]) else 0.0, lc)
		# où il est, sa taille, s'il se voit
		st["pos"] = p
		pn.global_position = p
		var sc: float = lerpf(float(st["sc"]), sc_to, clampf(dt * 3.0, 0.0, 1.0))
		st["sc"] = sc
		pn.scale = Vector3(sc, sc * (0.5 if (plat and sid == "coussin") else 1.0), sc)
		pn.visible = mode != "cache" or bool(st["vis"])
		# où il regarde (collé au hublot : couché sur le verre, les yeux vers la pièce)
		if plat and sid == "hublot":
			pn.rotation = Vector3(0, 0, s * PI * 0.5)
		else:
			pn.rotation.x = 0.0
			pn.rotation.z = 0.0
			face.y = 0.0
			if face.length() > 0.001:
				pn.rotation.y = lerp_angle(pn.rotation.y, atan2(face.x, face.z), clampf(dt * 5.0, 0.0, 1.0))
		# les bras : ils marchent, nagent, se roulent en boule, s'étalent ; un bras qui fait coucou
		var a0: float = 1.0
		var a1: float = -0.55
		var a2: float = -0.35
		var wav: float = 0.18
		var vit: float = 3.0
		match pose:
			"nage":
				a0 = 1.3
				a1 = 0.15
				a2 = 0.2
				wav = 0.25 + 0.15 * sin(t * 2.0)
				vit = 4.0
			"boule":
				a0 = 1.5
				a1 = 1.1
				a2 = 1.0
				wav = 0.05
				vit = 1.2
			"plat":
				a0 = 0.25
				a1 = 0.05
				a2 = -0.05
				wav = 0.12
				vit = 2.0
		for k2 in range(8):
			var segs: Array = tent[k2]
			for j in range(3):
				var ang: float = [a0, a1, a2][j]
				(segs[j] as Node3D).rotation.x = ang + wav * sin(t * vit + k2 * 0.8 + j * 1.1)
		if mode == "trouve":
			(tent[0][0] as Node3D).rotation.x = -0.9 + 0.35 * sin(t * 6.0)
		# il respire ; il cligne des yeux (la nuit dans le bocal, il les ferme)
		corps.scale = Vector3.ONE * (1.0 + (0.03 * sin(t * 1.1) if mode == "dodo" else 0.04 * sin(t * 2.2)))
		var ferme: bool = mode == "dodo" or fmod(t, 4.3) < 0.12
		for oe in yeux:
			(oe as Node3D).scale = Vector3(1.0, 0.12 if ferme else 1.0, 1.0)
	# --- chercher : soulever, ouvrir, regarder de près
	var chercher := func(id: String) -> void:
		var mode: String = str(st["mode"])
		if mode == "trajet":
			M.say("Trop tard : il file sous ton nez ! Regarde bien où il va.", 3.0)
			return
		if mode == "cache" and str(st["spot"]) == id:
			st["mode"] = "trouve"
			st["flash"] = 0.45
			st["vis"] = true
			ouvrir.call(id, true)
			M.main.sfx("ramasse" if id != "cuilleres" else "clochette", (spots[id] as Dictionary)["peek"], -12.0 if nuit else -6.0)
			M.main.sfx("bulles", (spots[id] as Dictionary)["peek"], -14.0)
			_bulle(M, ((spots[id] as Dictionary)["peek"] as Vector3) + Vector3(0, 0.3, 0), "Bloup !", Color(1.0, 0.85, 0.6), 38, 0.4, 1.4)
			M.say(str(_pick(M, POULPE_TROUVE[id])), 5.0)
			if kid != null:
				kid.gesture("joie", 2.0)
				if nuit:
					S._say_late(M, kid, "Chut… bravo ! Remets-le tout doucement dans l'aquarium.", 1.5)
				else:
					S._say_late(M, kid, str(_pick(M, ["Bravo ! Tu l'as trouvé plus vite que Papa !", "Ohh… Je n'avais rien dit, hein !", "Il te fait coucou ! Il t'aime bien."])), 1.5)
			if maman != null:
				S._say_late(M, maman, str(_pick(M, ["Merci ! Vous ne voudriez pas habiter ici ?", "Ah, enfin ! Vite, dans l'aquarium, avant qu'il change d'avis !"])), 3.5)
			elif nuit:
				S._say_late(M, papa, "Zzz… pas dans la théière… zzz…", 2.5)
			return
		# pas là : on referme, et l'enfant souffle un indice
		ouvrir.call(id, true)
		M.main.sfx("ui_ouvrir" if id != "cuilleres" else "clochette", (spots[id] as Dictionary)["sol"], -14.0 if nuit else -8.0)
		M.say(str(POULPE_VIDE[id]), 4.0)
		await M.get_tree().create_timer(1.5).timeout
		if not _la(M, room0):
			return
		ouvrir.call(id, false)
		if kid != null:
			S._say_late(M, kid, str(indice.call()), 0.3, 4.5)
		elif str(st["mode"]) == "dodo":
			await M.get_tree().create_timer(2.6).timeout
			if _la(M, room0):
				M.say("Sur la commode, dans le bocal à biscuits, quelque chose respire tout doucement…", 4.0)
	# --- le remettre dans l'aquarium
	var remettre := func() -> void:
		if str(st["mode"]) != "trouve":
			return
		var id: String = str(st["spot"])
		st["mode"] = "trajet"
		st["from"] = st["pos"]
		st["to"] = AQH
		st["k"] = 0.0
		st["dur"] = 1.4
		st["arc"] = 0.35
		st["ensuite"] = "plouf"
		st["sc_to"] = 0.85
		ouvrir.call(id, false)
		var tw: Tween = M.room.create_tween()
		tw.tween_property(couv, "rotation:x", -0.6, 0.4).set_trans(Tween.TRANS_SINE)
		M.say(str(_pick(M, ["Tu le prends tout doucement : il s'enroule autour de ton poignet comme un bracelet tiède… et hop, direction l'aquarium.",
			"Il se laisse porter en faisant la planche, très digne. Direction l'aquarium… pour l'instant."])), 4.0)
	for id0 in spots:
		var idc: String = str(id0)
		var sol: Vector3 = (spots[idc] as Dictionary)["sol"]
		M.act(sol, str(POULPE_CHERCHER[idc]), func(): chercher.call(idc), 0.75,
			func(): return str(st["mode"]) != "dodo" and not (str(st["mode"]) == "trouve" and str(st["spot"]) == idc))
		M.act(sol, "E : remettre le poulpe dans l'aquarium", remettre, 0.75, func(): return str(st["mode"]) == "trouve" and str(st["spot"]) == idc)
	# --- lui donner une crevette (trois au plus : après, il a le hoquet)
	var crevette := func() -> void:
		if float(st["faim"]) > 0.0:
			return
		if int(st["crevettes"]) >= 3:
			M.main.sfx("hoquet", st["pos"], -10.0)
			_bulle(M, (st["pos"] as Vector3) + Vector3(0, 0.25, 0), "Hic !", Color(1.0, 0.8, 0.7), 34, 0.35, 1.3)
			M.say("Il a le ventre tout rond. Il fait « non » avec trois tentacules, poliment. Et il a le hoquet.", 4.0)
			if maman != null:
				S._say_late(M, maman, "Stop ! Trois crevettes, c'est la ration. Sinon il ne passe plus par le trou du couvercle… Ah. Tiens. C'est une idée, ça.", 1.4, 5.0)
			return
		st["crevettes"] = int(st["crevettes"]) + 1
		var cr: Node3D = I._node(M, AQH, 0)
		var rose := _mat(Color(1.0, 0.55, 0.5), 0.0, 0.5)
		_p(cr, I._cyl(0.004, 0.012, 0.05, 6), rose, Vector3.ZERO, Vector3.ONE, Vector3(PI * 0.5, 0, 0.6))
		_p(cr, I._sph(0.01), rose, Vector3(0, 0.005, 0.025))
		var tw: Tween = M.room.create_tween()
		tw.tween_property(cr, "global_position", (st["pos"] as Vector3) + Vector3(0, 0.12, 0), 1.0).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(cr, "rotation:y", TAU * 2.0, 1.0)
		tw.tween_callback(cr.queue_free)
		M.main.sfx("plouf", AQH, -16.0)
		M.say(str(_pick(M, ["Tu laisses tomber une crevette dans l'eau. Huit bras se tendent en même temps : hop, attrapée ! Il devient tout rouge de plaisir.",
			"Une crevette descend en tournant. Le poulpe la cueille du bout d'un tentacule, comme une fleur, et vire au rouge."])), 4.5)
		await M.get_tree().create_timer(1.0).timeout
		if not _la(M, room0):
			return
		st["faim"] = 3.0
		M.main.sfx("manger", st["pos"], -10.0)
		_bulle(M, (st["pos"] as Vector3) + Vector3(0, 0.25, 0), "♥", Color(1.0, 0.45, 0.5), 40, 0.4, 1.6)
		M.state()["da_poulpe_ami"] = true
		if kid != null:
			S._say_late(M, kid, str(_pick(M, ["Il devient rouge quand il est content ! Moi, je deviens rouge quand je cours.", "Maintenant, il est ton ami. C'est la règle de la crevette.",
				"Chut… quand il mange, il ne s'évade pas. C'est le seul moment."])), 1.2)
	# --- admirer ses couleurs (dans l'aquarium)
	var admirer := func() -> void:
		if float(st["show"]) > 0.0:
			return
		st["show"] = 7.0
		M.main.sfx("cristal_chante", AQC, -14.0 if nuit else -8.0)
		if nuit:
			M.say("Dans la lumière bleue des diodes, il change de couleur tout doucement, rouge, jaune, vert, violet… comme une veilleuse qui ne sait pas choisir.", 5.0)
		else:
			M.say(str(_pick(M, ["Tu t'approches du verre. Le poulpe devient rouge, puis orange, puis jaune, puis vert… Il fait tout l'arc-en-ciel, rien que pour toi.",
				"Il colle ses ventouses au verre et change de couleur comme une petite enseigne : rouge, jaune, bleu, violet… et blanc nacré pour finir, comme les murs."])), 5.0)
		if kid != null:
			kid.gesture("applaudir", 2.5)
			if not nuit:
				S._say_late(M, kid, "Le Professeur Benthos dit qu'il parle avec ses couleurs. Là, il dit : « Regarde-moi ! »", 2.0)
	# --- regarder dans l'aquarium (quand il n'y est pas)
	var regarder := func() -> void:
		match str(st["mode"]):
			"dodo":
				M.say("L'aquarium est vide, le couvercle bien fermé. Sur la commode, peut-être ? Quelque chose y respire tout doucement.", 4.5)
			"trajet":
				M.say("Trop tard : il est déjà dehors !", 2.5)
			_:
				M.say(str(_pick(M, ["L'aquarium est vide. Le couvercle est entrouvert, et de petites traces mouillées partent sur le terrazzo…",
					"Du sable blanc, des coraux roses, un petit pot couché… et personne. Le poulpe a encore fait le mur."])), 4.5)
				if kid != null and str(st["mode"]) == "cache":
					S._say_late(M, kid, str(indice.call()), 2.0, 4.5)
	# --- la nuit : le regarder dormir dans son bocal (il rêve en couleurs)
	var bocal_voir := func() -> void:
		st["reve"] = 9.0
		M.main.sfx("lit_dodo", BOCAL, -18.0)
		M.say(str(_pick(M, ["Dans le bocal à biscuits, un petit poulpe dort roulé en boule, les bras repliés sous lui. Il rêve : il passe doucement du mauve au rose, puis au bleu…",
			"Il dort dans le bocal, serré comme un petit poing. De temps en temps, une couleur passe sur lui, comme un rêve qui le traverse."])), 5.0)
		S._say_late(M, papa, "Zzz… il rêve en couleurs… zzz…", 2.5)
	var avant: Vector3 = R.P(txa, 0, za + 0.95)
	M.act(avant + Vector3(-s * 0.35, 0, 0), "E : donner une crevette au poulpe", crevette, 0.55, func(): return str(st["mode"]) == "aquarium")
	M.act(avant + Vector3(s * 0.35, 0, 0), "E : admirer ses couleurs", admirer, 0.55, func(): return str(st["mode"]) == "aquarium")
	M.act(avant, "E : regarder dans l'aquarium", regarder, 0.6, func(): return str(st["mode"]) != "aquarium")
	M.act(R.P(cmx + 0.28, 0, cmz + 0.85), "E : regarder le poulpe dormir", bocal_voir, 0.75, func(): return str(st["mode"]) == "dodo")
	# --- au départ : caché (tiré au sort), ou dans son bocal ; les traces mouillées
	if dodo:
		st["pos"] = BOCAL
	else:
		var sd0: Dictionary = spots[str(st["spot"])]
		st["pos"] = sd0["cache"]
		st["sc"] = float(sd0["hs"])
		st["sc_to"] = float(sd0["hs"])
		st["vis"] = bool(sd0["vis"])
		couv.rotation.x = -0.18
		poser_traces.call(true)
		ouvrir.call(str(st["spot"]), false)
	pn.global_position = st["pos"]
	peau.albedo_color = POULPE_REVE[0] if dodo else (spots[str(st["spot"])] as Dictionary)["camo"]
	# --- les conversations
	if maman != null:
		var maman_cb := func() -> void:
			M.talk(maman, str(_pick(M, ["Bonnes bulles ! Entrez, entrez… mais regardez où vous mettez les pieds. Et les mains. Et le reste.",
				"Ah, de la visite ! Vous n'auriez pas vu passer un petit poulpe ? Orange. Ou blanc. Ou bleu. Ça dépend.",
				"Bonnes bulles ! Excusez le désordre : tout est très bien rangé, mais ce n'est pas nous qui avons rangé."])),
				[{"id": "souvent", "label": "Il s'échappe souvent ?"}, {"id": "comment", "label": "Mais comment il fait ?"}, {"id": "couleur", "label": "Et ses couleurs ?"}, {"id": "fermer", "label": "Bon courage !"}], func(id):
				match id:
					"souvent":
						M.talk(maman, "Souvent ? Tout le temps ! Lundi, dans la théière. Mardi, dans mon sac. Mercredi, il a pris la Ligne… enfin, presque : Marius Trident nous l'a ramené de la gare, dans sa casquette.",
							I._bye("Ha ha !"), I._close(M), "dépassée")
					"comment":
						M.talk(maman, "Un poulpe n'a pas d'os : seulement un petit bec. Il passe partout où passe son bec, un trou grand comme une bille. Le couvercle a trois verrous. Il les ouvre tous les trois. Dans l'ordre.",
							I._bye("Il est malin !"), I._close(M), "dépassée")
					"couleur":
						M.talk(maman, "Il prend la couleur de l'endroit : blanc dans la théière, bleu nuit sur le hublot, argent dans les cuillères. Le Professeur Benthos dit que c'est sa peau qui réfléchit. Moi, je dis que c'est un comédien.",
							I._bye("Un vrai comédien !"), I._close(M), "amusée")
					_:
						M.close_talk()
			, "dépassée")
		M.talk_spot(maman, maman_cb)
	var papa_cb := func() -> void:
		if nuit:
			M.talk(papa, "Mmh ? … Chut. La nuit, ici, tout le monde dort. Même le poulpe. Surtout le poulpe. … Enfin, j'espère.",
				[{"id": "sinon", "label": "Et s'il ne dort pas ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if id == "sinon":
					M.talk(papa, "Alors demain matin, on retrouvera mes chaussettes rangées par couleur, et les cuillères en étoile. … Zzz…", I._bye("(Le laisser dormir)"), I._close(M), "à voix basse")
				else:
					M.close_talk()
			, "à voix basse")
			return
		M.talk(papa, str(_pick(M, ["Bonnes bulles ! Asseyez-vous… mais vérifiez le coussin d'abord. On ne sait jamais.",
			"Ah, bonjour ! Vous venez pour le poulpe ? Tout le monde vient pour le poulpe. Personne ne vient pour moi."])),
			[{"id": "origine", "label": "D'où vient-il ?"}, {"id": "gentil", "label": "Il est gentil ?"}, {"id": "fermer", "label": "Bonne lecture !"}], func(id):
			match id:
				"origine":
					M.talk(papa, ["Du Grand Aquarium de l'Institut. Gribouille s'en évadait tous les soirs pour aller voir les crevettes des voisins. Le Professeur Benthos nous l'a confié : « Une famille, ça l'occupera. » Ça nous occupe, surtout.",
						"Du Grand Aquarium de l'Institut. Chaussette s'en évadait tous les soirs pour aller voir les crevettes des voisins. Le Professeur Benthos nous l'a confiée : « Une famille, ça l'occupera. » Ça nous occupe, surtout.",
						"Du Grand Aquarium de l'Institut. Bigoudi s'en évadait tous les soirs pour aller voir les crevettes des voisins. Le Professeur Benthos nous l'a confié : « Une famille, ça l'occupera. » Ça nous occupe, surtout."][ni],
						I._bye("Ha ha !"), I._close(M), "philosophe")
				"gentil":
					M.talk(papa, "Très gentil. Il range. Il range TOUT. Mes chaussettes par couleur, les cuillères en étoile, mes clés dans la théière. On ne retrouve plus rien, mais tout est très bien rangé.",
						I._bye("C'est déjà ça !"), I._close(M), "philosophe")
				_:
					M.close_talk()
		, "de bonne humeur")
	M.talk_spot(papa, papa_cb)
	if kid != null:
		var kid_cb := func() -> void:
			if nuit:
				M.talk(kid, "Chut ! Il est sorti faire ses bêtises. Si tu le trouves, remets-le tout doucement dans l'aquarium… sinon Papa va se réveiller et dire « Encore ! »",
					[{"id": "indice", "label": "Un indice ?"}, {"id": "fermer", "label": "Chut…"}], func(id):
					if id == "indice":
						M.talk(kid, str(indice.call()), I._bye("Merci, complice !"), I._close(M), "à voix basse")
					else:
						M.close_talk()
				, "à voix basse")
				return
			M.talk(kid, "Tu veux savoir où il est ? Je suis son complice : je ne dis rien. … Bon. Juste un indice ?",
				[{"id": "indice", "label": "Un indice !"}, {"id": "pourquoi", "label": "Pourquoi il s'échappe ?"}, {"id": "fermer", "label": "Salut !"}], func(id):
				match id:
					"indice":
						M.talk(kid, str(indice.call()), I._bye("Merci, complice !"), I._close(M), "malicieux" if boy else "malicieuse")
					"pourquoi":
						M.talk(kid, "Il s'ennuie, dans l'aquarium. Dehors, il y a des tiroirs, des théières, des cuillères… Moi aussi, j'aime bien les tiroirs. Mais je n'ai pas le droit de dormir dedans.",
							I._bye("Ha ha !"), I._close(M), "malicieux" if boy else "malicieuse")
					_:
						M.close_talk()
			, "aux anges")
		M.talk_spot(kid, kid_cb)
	# --- l'entrée
	if nuit and dodo:
		M.ctx["entree"] = str(_pick(M, ["Chut… Le salon dort. Sur la commode, dans un bocal à biscuits, un petit poulpe s'est roulé en boule. Il a pris la couleur d'un rêve.",
			"Il fait nuit dans le Dôme. Un papa ronfle dans son fauteuil, l'aquarium est vide… et le poulpe dort dans le bocal à biscuits, évidemment.",
			"Tout est calme. Les diodes de l'aquarium luisent en bleu, et dans un bocal, sur la commode, une petite boule mauve respire tout doucement."]))
	elif nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Un papa dort dans son fauteuil. L'aquarium est vide, le couvercle entrouvert : quelqu'un fait des bêtises en douce.",
			"Il fait nuit. Un enfant en pyjama te fait « chut ! » : le poulpe est sorti, et Papa ne doit surtout pas se réveiller.",
			"Dans la lumière bleue de l'aquarium vide, de petites traces mouillées filent sur le terrazzo. Quelque part, quelqu'un fait « bloup »."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Un salon de nacre, un aquarium qui fait des bulles… et personne dedans. Le couvercle est entrouvert. Quelque part dans la pièce, un petit poulpe se cache.",
			"« Il est ENCORE sorti ! » Une maman cherche du côté du buffet, un papa soulève son journal, un enfant fait semblant de ne rien savoir. L'aquarium, lui, est vide.",
			"De petites traces mouillées partent de l'aquarium vide, sur le terrazzo. Ici vit un poulpe qui ne tient pas en place."]))


# =================================================================== la grand-mère qui chante avec la baleine

## Les cinq notes de baleine (des plus graves aux plus aiguës) : le libellé de la coquille, ce qu'on
## chante (en bulle), la couleur de la coquille.
const CHANTEUSE_NOTES := [
	["E : chanter le Grondement", "Hoummm…", Color(0.25, 0.4, 1.0)],
	["E : chanter la Houle", "Ouhooo…", Color(0.2, 0.75, 0.95)],
	["E : chanter l'Écho", "Ohé-oh…", Color(0.35, 0.95, 0.8)],
	["E : chanter la Bulle", "Bloui ?", Color(0.78, 0.6, 1.0)],
	["E : chanter le Sifflet", "Piii-ou !", Color(1.0, 0.85, 0.45)],
]

## Le carnet des passages (soixante ans de Grande Chanteuse) : une page à chaque lecture.
const CHANTEUSE_CARNET := [
	"Le carnet, première page, d'une écriture d'enfant : « Premier passage. J'ai huit ans. Elle est passée très haut. J'ai chanté hou. Elle a chanté houuu. Maman dit que c'est un hasard. Moi, je dis que c'est une amie. »",
	"« Trois chants ce matin : deux graves, un aigu. Le jeune Hippolyte Benthos dit que ça veut dire : bonjour, le Dôme. Je lui ai répondu : bonjour, ma grande. Il a noté ma réponse aussi. »",
	"« Pas de passage depuis neuf jours. J'ai passé le disque numéro trois, pour qu'elle ne nous oublie pas. Le dixième jour, elle est revenue. Je ne dis pas que c'est grâce au disque. Je ne dis pas le contraire non plus. »",
	"« Nuit sans sommeil. Elle est passée à trois heures, toute seule, très lentement, en chantant tout bas. Je crois qu'elle berçait quelqu'un. »",
	"« Le Professeur m'a apporté son nouveau disque. Il l'a écouté sept fois, moi une seule. Il a pleuré à la troisième, moi à la première. Nous sommes quittes. »",
	"« Le jour où la Ligne a rouvert, elle est passée trois fois. Elle voulait voir les gens d'en haut, c'est sûr. Elle est curieuse, comme moi. »",
]


## Une coquille de nacre posée au sol (le chemin des notes) : sa forme, ses côtes, le disque qui luit
## dessous quand on la chante. Rend [le nœud, le matériau qui luit].
static func _chanteuse_coquille(M, at: Vector3, yaw: float, c: Color, nacre: Material) -> Array:
	var n: Node3D = I._node(M, at, yaw)
	var lueur := _mat(c, 0.0, 0.3, 0.25)
	_p(n, I._cyl(0.2, 0.2, 0.004, 24), lueur, Vector3(0, 0.003, 0))
	_p(n, I._sph(1.0), nacre, Vector3(0, 0.012, 0), Vector3(0.17, 0.035, 0.15))
	var cote := _mat(c.lerp(Color(1, 1, 1), 0.45), 0.3, 0.3)
	for k in range(7):
		var a: float = -1.2 + 2.4 * k / 6.0
		_p(n, I._boxm(Vector3(0.012, 0.012, 0.15)), cote, Vector3(sin(a) * 0.07, 0.04, cos(a) * 0.07 - 0.04), Vector3.ONE, Vector3(-0.18, a, 0))
	_p(n, I._boxm(Vector3(0.06, 0.03, 0.035)), nacre, Vector3(0, 0.02, -0.14))
	_sans_ombre(n)
	return [n, lueur]


## La grand-mère qui chante avec la baleine. Toute sa vie, une vieille dame du Dôme a répondu au chant
## de la Grande Chanteuse, la baleine qui passe très haut au-dessus des dômes. Son fauteuil est tourné
## vers le hublot ; à côté, un vieux phonographe de nacre et les disques de chants de baleine enregistrés
## par le Professeur Benthos (le plateau tourne, le pavillon chante, des « ♪ » bleus s'en échappent) ; sur
## le guéridon, le carnet où elle note chaque passage depuis soixante ans. Au milieu du salon, le chemin
## des notes : cinq coquilles de nacre (le Grondement, la Houle, l'Écho, la Bulle, le Sifflet ; chant_0..4)
## sur lesquelles son petit-fils (ou sa petite-fille) apprend les « notes de baleine » : elles chantent une
## petite phrase, on la répète en marchant sur les coquilles (trois, puis quatre, puis cinq notes). Au bout
## de la grande phrase, la baleine répond (un chant lointain, une ombre qui passe derrière le hublot) : la
## première fois, la grand-mère donne un coquillage qui chante. Parfois, la baleine passe toute seule.
## La nuit, l'enfant dort sur le canapé et la grand-mère veille dans son fauteuil, en chuchotant.
static func _chanteuse(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var room0: Node = M.room
	var nuit: bool = _nuit(M)
	var s: float = 1.0 if r.randf() < 0.5 else -1.0
	var boy: bool = r.randf() < 0.5
	# les matières : la nacre, les disques, les diodes aigue-marine
	if not R.kit.mats.has("ch_nacre"):
		R._put("ch_nacre", R._col(Color(0.96, 0.95, 0.98), 0.25, 0.3))
		R._put("ch_disque", R._col(Color(0.05, 0.06, 0.1), 0.2, 0.3))
		R._put("ch_diode", _mat(Color(0.35, 0.95, 0.9), 0.0, 0.4, 2.2))
	var nacre := _mat(Color(0.97, 0.95, 0.98), 0.35, 0.22)
	var nacre_rose := _mat(Color(0.98, 0.85, 0.88), 0.25, 0.3)
	nacre_rose.cull_mode = BaseMaterial3D.CULL_DISABLED
	var titane := _mat(Color(0.8, 0.82, 0.86), 0.9, 0.3)
	var disque_m := _mat(Color(0.06, 0.07, 0.12), 0.3, 0.15)
	# le hublot du côté s (là où le moteur des pièces l'a posé) : sa hauteur, sa place
	var wy: float = 1.55 if R.H > 2.7 else 1.4
	var zh: float = (-hd + R.D * 0.25) if R.D >= 7.0 else 0.0
	var hx: float = s * (hw - 0.02)
	var hub_xf: Transform3D = R.L(hx, wy, zh, -90.0 * s)
	R.kit.ring(hub_xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.012)), 0.51, 0.54, 0.025, "ch_diode", 24)
	# la cheminée à l'éthanol au fond, une affiche de la Chanteuse, un autre cadre
	_foyer(M, R.W * 0.22)
	R.mark_wall(R.W * 0.22, 1.6, -hd + 0.02, 0.6)
	_cadres(M, 1, 0)
	_cadres(M, 1)
	# le fauteuil de la grand-mère, tourné vers le hublot (un peu vers la pièce)
	var fx: float = s * (hw - 1.05)
	var fz: float = zh
	var fyaw: float = _vers(fx, fz, hx, zh + 0.9)
	R.fauteuil(fx, fz, fyaw, str(_pick(M, ["blanc", "creme", "turquoise", "bleu"])))
	# le guéridon de nacre, à portée de main : le carnet ouvert, un bol de chocolat des abysses
	var gx: float = s * (hw - 0.45)
	var gz: float = minf(zh + 0.85, hd - 1.7)
	R.kit.cyl(R.L(gx, 0, gz), 0.14, 0.14, 0.02, "argent", 14)
	R.kit.cyl(R.L(gx, 0.02, gz), 0.02, 0.02, 0.55, "argent", 8, false)
	R.kit.cyl(R.L(gx, 0.57, gz), 0.26, 0.26, 0.03, "ch_nacre", 20)
	R.kit.col_box(R.L(gx, 0.3, gz), Vector3(0.5, 0.6, 0.5))
	R.reserve(gx, gz, 0.6, 0.6)
	R.kit.box(R.L(gx - s * 0.04, 0.605, gz - 0.02, 12.0), Vector3(0.3, 0.012, 0.21), "cuir", 1.0)
	for sp in [-1.0, 1.0]:
		R.kit.box(R.L(gx - s * 0.04 + sp * 0.07 * cos(deg_to_rad(12.0)), 0.616, gz - 0.02 - sp * 0.07 * sin(deg_to_rad(12.0)), 12.0), Vector3(0.135, 0.01, 0.19), "papier", 1.0)
	R.kit.cyl(R.L(gx + s * 0.1, 0.6, gz + 0.13), 0.045, 0.04, 0.08, "ceramique", 12)
	R.kit.cyl(R.L(gx + s * 0.1, 0.672, gz + 0.13), 0.038, 0.038, 0.005, "st_charbon", 12)
	# le meuble aux disques et le phonographe de nacre, contre le mur, de l'autre côté du fauteuil
	var pxc: float = s * (hw - 0.3)
	var pzc: float = maxf(zh - 1.0, -hd + 0.6)
	R.kit.box(R.L(pxc, 0.37, pzc), Vector3(0.5, 0.74, 0.8), "ch_nacre", 1.0)
	R.kit.box(R.L(pxc, 0.755, pzc), Vector3(0.54, 0.03, 0.84), "argent", 1.0)
	R.kit.box(R.L(pxc - s * 0.252, 0.1, pzc), Vector3(0.01, 0.02, 0.76), "ch_diode", 1.0)
	R.kit.col_box(R.L(pxc, 0.37, pzc), Vector3(0.5, 0.74, 0.8))
	R.reserve(pxc, pzc, 0.7, 1.0)
	# dans le casier ouvert du meuble : les disques du Professeur, debout, et leurs pochettes
	R.kit.box(R.L(pxc - s * 0.2, 0.42, pzc), Vector3(0.12, 0.5, 0.7), "ch_disque", 1.0)
	for k in range(9):
		var dz: float = pzc - 0.3 + k * 0.075
		R.kit.box(R.L(pxc - s * 0.12, 0.33, dz), Vector3(0.28, 0.3, 0.012), str(["ch_disque", "ch_nacre", "tissu_turquoise"][k % 3]), 1.0)
	# le phonographe (un nœud tourné vers la pièce : son +Z regarde la pièce)
	var phon: Node3D = I._node(M, R.P(pxc, 0.77, pzc - 0.12))
	phon.global_transform = R.L(pxc, 0.77, pzc - 0.12, -90.0 * s)
	_p(phon, I._boxm(Vector3(0.34, 0.1, 0.32)), nacre, Vector3(0, 0.05, 0))
	_p(phon, I._boxm(Vector3(0.35, 0.012, 0.33)), titane, Vector3(0, 0.1, 0))
	_p(phon, I._boxm(Vector3(0.35, 0.012, 0.33)), titane, Vector3(0, 0.005, 0))
	var plat := Node3D.new()
	phon.add_child(plat)
	plat.position = Vector3(-0.02, 0.112, 0.03)
	_p(plat, I._cyl(0.13, 0.13, 0.008, 28), disque_m, Vector3.ZERO)
	var etiquette := _mat(Color(0.98, 0.9, 0.95), 0.2, 0.3, 0.3)
	_p(plat, I._cyl(0.04, 0.04, 0.01, 18), etiquette, Vector3(0, 0.001, 0))
	_p(plat, I._boxm(Vector3(0.06, 0.004, 0.012)), nacre, Vector3(0.08, 0.006, 0))
	# le bras de lecture, la manivelle, le pavillon (un grand cornet de nacre rose, ouvert vers la pièce)
	_p(phon, I._cyl(0.012, 0.012, 0.03, 8), titane, Vector3(0.13, 0.12, -0.11))
	_p(phon, I._boxm(Vector3(0.012, 0.01, 0.17)), titane, Vector3(0.09, 0.14, -0.04), Vector3.ONE, Vector3(0, 0.45, 0))
	_p(phon, I._cyl(0.006, 0.006, 0.1, 6), titane, Vector3(0.2, 0.06, 0.05), Vector3.ONE, Vector3(0, 0, PI * 0.5))
	_p(phon, I._boxm(Vector3(0.012, 0.06, 0.012)), titane, Vector3(0.25, 0.04, 0.05))
	_p(phon, I._sph(0.016), nacre, Vector3(0.25, 0.01, 0.05))
	_p(phon, I._cyl(0.012, 0.016, 0.26, 8), titane, Vector3(-0.12, 0.23, -0.12))
	var ang: float = 0.95
	var hdir := Vector3(0, cos(ang), sin(ang))
	var col_bas := Vector3(-0.12, 0.36, -0.12)
	var cornet: CylinderMesh = I._cyl(0.2, 0.022, 0.36, 22)
	cornet.cap_top = false
	cornet.cap_bottom = false
	_p(phon, cornet, nacre_rose, col_bas + hdir * 0.18, Vector3.ONE, Vector3(ang, 0, 0))
	var bord := TorusMesh.new()
	bord.inner_radius = 0.19
	bord.outer_radius = 0.21
	bord.rings = 28
	bord.ring_segments = 6
	_p(phon, bord, nacre, col_bas + hdir * 0.36, Vector3.ONE, Vector3(ang, 0, 0))
	_p(phon, I._sph(0.03), titane, col_bas)
	_sans_ombre(phon)
	var bouche: Vector3 = phon.to_global(col_bas + hdir * 0.4)
	# le canapé de l'autre côté (l'enfant y dort la nuit), le lampadaire, une plante
	var cx: float = -s * (hw - 0.55)
	var cz: float = clampf(zh, -hd + 1.2, hd - 2.0)
	R.canape(cx, cz, 90.0 * s, str(_pick(M, ["blanc", "creme", "turquoise", "gris"])))
	if R.is_free(cx, cz - 1.35, 0.45, 0.45):
		_lampadaire(M, cx, cz - 1.35)
	if R.is_free(-s * (hw - 0.5), hd - 1.8, 0.5, 0.5):
		_pot(M, -s * (hw - 0.5), hd - 1.8, 0.0, 1.1, "")
	# le chemin des notes : cinq coquilles de nacre sur un tapis, la plus grave loin du hublot
	var xr: float = -s * 0.15
	var zr: float = clampf(zh + 1.0, -hd + 0.8, hd - 1.8)
	R.tapis(xr, zr, 0, minf(3.2, R.W - 3.0), 1.2)
	R.reserve(xr, zr, 3.0, 0.8)
	var coquilles: Array = []
	var lueurs: Array = []
	var cpos: Array = []
	for k2 in range(5):
		var ckx: float = xr + s * (k2 - 2) * 0.55
		var ck: Array = _chanteuse_coquille(M, R.P(ckx, 0.0, zr), 90.0 * s + r.randf_range(-12.0, 12.0), CHANTEUSE_NOTES[k2][2], nacre)
		coquilles.append(ck[0])
		lueurs.append(ck[1])
		cpos.append(R.P(ckx, 0.0, zr))
	# derrière le hublot : la lueur de la mer qui s'éclaire, l'ombre de la baleine qui passe, très loin
	var hub: Node3D = I._node(M, R.P(hx, wy, zh))
	hub.global_transform = hub_xf
	var halo_m := _verre(Color(0.45, 0.78, 1.0), 0.0, 1.4)
	_p(hub, I._cyl(0.41, 0.41, 0.002, 28), halo_m, Vector3(0, 0, 0.016), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	var bal_m := _verre(Color(0.02, 0.05, 0.1), 0.0)
	var bal := Node3D.new()
	hub.add_child(bal)
	bal.position = Vector3(-0.3, 0.1, 0.02)
	_p(bal, I._sph(1.0), bal_m, Vector3.ZERO, Vector3(0.11, 0.028, 0.004))
	_p(bal, I._sph(1.0), bal_m, Vector3(0.07, 0.004, 0), Vector3(0.05, 0.026, 0.004))
	_p(bal, I._boxm(Vector3(0.05, 0.008, 0.004)), bal_m, Vector3(0.0, -0.03, 0), Vector3.ONE, Vector3(0, 0, -0.6))
	for sq in [-1.0, 1.0]:
		_p(bal, I._boxm(Vector3(0.045, 0.012, 0.004)), bal_m, Vector3(-0.12, sq * 0.014, 0), Vector3.ONE, Vector3(0, 0, sq * 0.7))
	_sans_ombre(hub)
	var lueur_mer := OmniLight3D.new()
	lueur_mer.light_color = Color(0.4, 0.7, 1.0)
	lueur_mer.light_energy = 0.0
	lueur_mer.omni_range = 3.2
	lueur_mer.shadow_enabled = false
	M.room.add_child(lueur_mer)
	lueur_mer.global_position = R.P(s * (hw - 0.7), wy, zh)
	var a_hublot: Vector3 = R.P(s * (hw - 0.15), wy, zh)
	# --- les gens : la grand-mère dans son fauteuil (elle veille, la nuit aussi) ; l'enfant près des
	# coquilles le jour, endormi sur le canapé la nuit
	var mamie: Node = M.person("vieille", fx, fz, fyaw, "assis")
	var kid: Node
	if nuit:
		mamie.lines = ["Chut… le petit dort." if boy else "Chut… la petite dort.", "La nuit, elle passe plus bas. Je l'attends.", "Bonnes bulles… tout bas, hein.",
			"Je ne dors plus beaucoup. Elle non plus, je crois.", "Hmmm… hmmm… (Elle fredonne le Grondement, très doucement.)"]
		mamie.line_every = Vector2(10.0, 15.0)
		kid = M.person("garcon" if boy else "fille", cx, cz, 90.0 * s, "dormir")
		kid.lie(R.P(cx + s * 0.06, 0.47, cz + 0.75), Vector3(0, 0, -1))
		kid.lines = ["Zzz…", "Zzz… hoummm… zzz…", "Mmh… Mamie… elle a répondu ?… zzz…", "Zzz… piii-ou… zzz…"]
		kid.line_every = Vector2(9.0, 14.0)
	else:
		mamie.lines = ["Chut… Vous entendez ? … Non. Pas encore.", "Soixante ans que je lui réponds. Elle ne s'est jamais plainte de ma voix.",
			"La Houle, mon trésor, la Houle ! Plus lentement : c'est une baleine, pas un poisson-chat.",
			"Le Professeur Benthos dit que c'est de la science. Moi, je dis que c'est de la politesse.", "Bonnes bulles ! Entrez, entrez. Mais pas trop fort."]
		mamie.line_every = Vector2(8.0, 13.0)
		var kp: Vector2 = _dedans(M, xr - s * 0.5, zr - 0.8)
		kid = M.person("garcon" if boy else "fille", kp.x, kp.y, _vers(kp.x, kp.y, hx, zh), "debout")
		kid.lines = ["Hoummm… Mamie, c'était un bon Grondement ?", "Plus tard, je chanterai assez fort pour qu'elle m'entende de la surface.",
			"Mamie a un carnet avec tous les passages. Même ceux de quand elle était petite !", "Le Sifflet, c'est le plus dur. Il faut sourire en même temps.",
			"Quand je serai grand, j'enregistrerai des disques, comme le Professeur." if boy else "Quand je serai grande, j'enregistrerai des disques, comme le Professeur."]
		kid.line_every = Vector2(6.0, 10.0)
	var tete: Vector3 = R.P(fx, 1.25, fz)
	var st := {"t": 0.0, "jeu": "", "seq": [], "k": 0, "i": 0, "d": 0.0, "niveau": 3, "att": 0.0, "lum": [0.0, 0.0, 0.0, 0.0, 0.0],
		"disque": r.randi() % 3, "disque_t": 0.0, "note_t": 0.0, "bal": -1.0, "prochain": r.randf_range(45.0, 90.0), "page": 0, "ecoute": 0}
	# une note : le son, la coquille qui s'allume, la bulle (qui : "mamie", "toi")
	var sonner := func(n: int, qui: String) -> void:
		(st["lum"] as Array)[n] = 1.0
		var at: Vector3 = tete if qui == "mamie" else M.main._player_pos_v27() + Vector3(0, 1.6, 0)
		M.main.sfx("chant_%d" % n, at, -12.0 if nuit else -5.0)
		var c: Color = CHANTEUSE_NOTES[n][2]
		_bulle(M, (cpos[n] as Vector3) + Vector3(0, 0.35, 0), str(CHANTEUSE_NOTES[n][1]), c, 30 if nuit else 38, 0.45, 1.5)
		if qui == "mamie":
			_bulle(M, tete + Vector3(0, 0.45, 0), "♪", c, 34, 0.35, 1.2)
	# la baleine passe (fort : elle répond ; sinon, elle passe toute seule, très loin)
	var passer := func(fort: bool) -> void:
		if float(st["bal"]) >= 0.0:
			return
		st["bal"] = 0.0
		M.state()["da_chanteuse_passages"] = int(M.state().get("da_chanteuse_passages", 0)) + 1
		M.main.sfx("baleine", a_hublot, (-8.0 if fort else -16.0) - (4.0 if nuit else 0.0))
		M.main.sfx("bulles", a_hublot, -18.0)
		_bulle(M, a_hublot + Vector3(-s * 0.3, 0.3, 0), "♪ … ♪", Color(0.6, 0.85, 1.0), 40, 0.6, 2.4)
		if fort:
			M.say(str(_pick(M, ["Très loin, très haut, au-dessus des dômes, un chant immense répond. Le verre du hublot frémit. La vieille dame ferme les yeux et sourit.",
				"Derrière le hublot, la mer s'éclaire un peu. Une ombre immense glisse, très haut, et chante trois notes longues. Les mêmes que les vôtres. Enfin, presque."])), 5.5)
		else:
			M.say(str(_pick(M, ["Tout se tait. Très loin, au-dessus des dômes, la Grande Chanteuse passe. Son chant traverse l'eau, le verre, les murs… et toi.",
				"Un chant grave arrive de partout à la fois. Dans son fauteuil, la vieille dame se redresse, tournée vers le hublot."])), 5.0)
		if nuit:
			S._say_late(M, mamie, str(_pick(M, ["La voilà… tout bas, ma grande, tout bas. Il y a un enfant qui dort.", "Bonsoir, ma vieille amie… Je note, je note."])), 1.5)
			S._say_late(M, kid, "Zzz… elle chante… zzz…", 4.0)
		else:
			mamie.gesture("joie", 2.0)
			S._say_late(M, mamie, str(_pick(M, ["Bonjour, ma grande ! … Vite, mon carnet.", "La voilà ! Vous l'entendez ? Elle ne passe jamais pour rien.",
				"C'est elle. Soixante ans, et j'ai toujours le cœur qui fait des bulles."])), 1.4)
			kid.gesture("sursaut", 1.0)
			S._say_late(M, kid, str(_pick(M, ["Chut ! Chut ! Elle est là !", "Mamie ! Mamie, elle chante !", "J'ai des frissons jusque dans les chaussettes !"])), 2.6)
		await M.get_tree().create_timer(3.2).timeout
		if not _la(M, room0):
			return
		M.main.sfx("baleine", a_hublot, (-11.0 if fort else -19.0) - (4.0 if nuit else 0.0))
	# la récompense (une seule fois) : un coquillage qui chante (ou une perle d'Azur, si on en a déjà un)
	var recompense := func() -> void:
		if bool(M.state().get("da_chanteuse", false)):
			mamie.say(str(_pick(M, ["Elle t'a encore répondu. Je l'écris dans le carnet, avec ton nom à côté.", "Bravo ! On fera un trio, la prochaine fois.",
				"Tu vois ? Elle reconnaît les voix. La tienne, maintenant, elle la connaît."])), 3.5)
			return
		M.state()["da_chanteuse"] = true
		var id: String = _neuf(M, "coquillage_chanteur", "perle_azur")
		var txt: String = ""
		if id == "coquillage_chanteur":
			txt = "Tout bas, alors : elle t'a répondu. En soixante ans, je ne l'ai vue répondre qu'à trois personnes : ma mère, le Professeur, et moi. Tiens, un coquillage qui chante. Les soirs où elle ne passe pas, colle-le à ton oreille." if nuit else "Elle t'a répondu ! En soixante ans, je ne l'ai vue répondre qu'à trois personnes : ma mère, le Professeur, et moi. Te voilà la quatrième. Tiens, un coquillage qui chante. Les soirs où elle ne passe pas, colle-le à ton oreille."
		else:
			txt = "Tout bas, alors : elle t'a répondu. Tu as déjà un coquillage qui chante, je le vois dépasser de ton sac. Alors tiens : une perle d'Azur de mon collier de jeune fille. Elle a entendu tous les chants depuis soixante ans." if nuit else "Elle t'a répondu ! Tu as déjà un coquillage qui chante, je le vois dépasser de ton sac. Alors tiens : une perle d'Azur de mon collier de jeune fille. Elle a entendu tous les chants depuis soixante ans."
		M.talk(mamie, txt, I._bye("Merci ! Bonnes bulles !"), func(_i):
			M.give([[id, 1]], "")
			M.close_talk(), "à voix basse" if nuit else "émue")
	# la phrase réussie : on passe à la phrase plus longue ; au bout de la grande, la baleine répond
	var reussi := func() -> void:
		var n0: int = int(st["niveau"])
		st["jeu"] = ""
		M.main.sfx("carillon", tete, -14.0 if nuit else -8.0)
		if n0 < 5:
			st["niveau"] = n0 + 1
			if nuit:
				mamie.say(str(_pick(M, ["Joli… tout bas, c'est encore plus joli. Une de plus ?", "Parfait. Elle aime qu'on chante doucement, la nuit."])), 3.5)
			else:
				kid.gesture("joie", 1.6)
				kid.say(str(_pick(M, ["Bravo ! Maintenant, une plus longue !", "Tu chantes mieux que moi ! … Presque.", "Oui ! Mamie, encore !"])), 3.0)
				S._say_late(M, mamie, str(_pick(M, ["Très bien. Une note de plus, maintenant.", "Voilà une voix qui sait écouter. On allonge la phrase ?"])), 1.6)
			return
		st["niveau"] = 3
		mamie.say("Chut… Écoutez…" if not nuit else "Chut… tout bas… écoute…", 2.5)
		if not nuit:
			kid.set_pose("debout")
		await M.get_tree().create_timer(1.8).timeout
		if not _la(M, room0):
			return
		passer.call(true)
		await M.get_tree().create_timer(5.0).timeout
		if not _la(M, room0):
			return
		recompense.call()
	# une coquille : on chante sa note (pendant le jeu, il faut la bonne)
	var appuyer := func(n: int) -> void:
		var jeu: String = str(st["jeu"])
		if jeu == "ecoute":
			return
		sonner.call(n, "toi")
		if jeu != "toi":
			if r.randf() < 0.3:
				if nuit:
					mamie.say("Tout bas, tout bas…", 2.0)
				else:
					kid.say(str(_pick(M, ["Joli ! Mais il faut attendre que Mamie chante d'abord.", "C'est la bonne note ! Enfin, c'est une note.", "Encore !"])), 2.5)
			return
		var seq: Array = st["seq"]
		var i: int = int(st["i"])
		if n == int(seq[i]):
			st["i"] = i + 1
			st["att"] = 20.0
			if i + 1 >= seq.size():
				reussi.call()
			return
		st["jeu"] = ""
		M.main.sfx("ui_erreur", tete, -14.0)
		if nuit:
			mamie.say(str(_pick(M, ["Pas tout à fait… On recommence demain, ou maintenant, tout bas ?", "Presque. Elle aussi se trompe, parfois. Elle reprend, c'est tout."])), 3.5)
		else:
			kid.gesture("rire", 1.5)
			kid.say(str(_pick(M, ["Ha ha ! Ça, c'est une note de poisson-chat !", "Raté ! Mais c'était joli quand même.", "Non, pas celle-là ! On recommence ?"])), 3.0)
			S._say_late(M, mamie, str(_pick(M, ["Ce n'est rien. La Chanteuse met trois minutes à chanter une note. Prends ton temps.", "On recommence. Écoute bien d'abord : chanter, c'est surtout écouter."])), 1.6)
	for k3 in range(5):
		var kk: int = k3
		M.act(cpos[kk], str(CHANTEUSE_NOTES[kk][0]), func(): appuyer.call(kk), 0.32, func(): return str(st["jeu"]) != "ecoute")
	# commencer une phrase : la grand-mère (et l'enfant) chantent, on écoute
	var commencer := func() -> void:
		var seq2: Array = []
		var prev: int = -1
		for _j in range(int(st["niveau"])):
			var n2: int = r.randi() % 5
			if n2 == prev:
				n2 = (n2 + 1 + r.randi() % 4) % 5
			seq2.append(n2)
			prev = n2
		st["seq"] = seq2
		st["k"] = 0
		st["i"] = 0
		st["d"] = 1.2
		st["jeu"] = "ecoute"
		if nuit:
			M.say("La vieille dame chante une petite phrase, très doucement, pour ne pas réveiller l'enfant. Écoute bien, puis répète-la sur les coquilles.", 4.5)
		else:
			kid.set_pose("chanter")
			mamie.say(str(_pick(M, ["Écoute d'abord. Puis tu la chantes sur les coquilles, dans le même ordre.", "Une petite phrase de baleine. Ouvre grand les oreilles.",
				"Attention, je chante… et toi, tu répètes."])), 3.5)
	var lab_jeu: String = "E : chanter tout bas avec elle" if nuit else ("E : chanter avec eux" if boy else "E : chanter avec elles")
	M.act(R.P(xr, 0, zr - 0.75), lab_jeu, commencer, 0.55, func(): return str(st["jeu"]) != "ecoute" and float(st["bal"]) < 0.0 and float(st["disque_t"]) <= 0.0)
	# le phonographe : on tourne la manivelle, le disque tourne, le pavillon chante
	var fin_disque := func() -> void:
		if nuit:
			mamie.say("Voilà… Il dort encore mieux, tu vois." if boy else "Voilà… Elle dort encore mieux, tu vois.", 3.0)
		else:
			mamie.say(str(_pick(M, ["Ce crachotement, à la fin… c'est Hippolyte qui éternue. Il n'a jamais voulu le couper.", "Merci, Professeur. Toujours aussi beau.",
				"On l'écoute une fois par jour. Ça entretient l'oreille."])), 3.5)
		st["ecoute"] = int(st["ecoute"]) + 1
		if int(st["ecoute"]) == 1 or r.randf() < 0.4:
			await M.get_tree().create_timer(2.2).timeout
			if not _la(M, room0):
				return
			passer.call(true)
	var tourner := func() -> void:
		var d: int = int(st["disque"])
		st["disque"] = (d + 1) % 3
		st["disque_t"] = 9.0
		st["note_t"] = 1.0
		etiquette.albedo_color = [Color(0.98, 0.9, 0.95), Color(0.8, 0.95, 1.0), Color(1.0, 0.92, 0.7)][d]
		etiquette.emission = etiquette.albedo_color
		M.main.sfx("mecanisme", bouche, -10.0)
		M.say(str(_pick(M, ["Tu poses le disque sur le plateau et tu tournes la manivelle. Le pavillon tousse, crachote… puis la mer entière se met à chanter dans le salon.",
			"Le plateau tourne. Une aiguille de titane se pose sur le disque, et un chant de baleine sort du grand cornet de nacre, enregistré il y a quarante ans."])), 4.5)
		if nuit:
			S._say_late(M, mamie, "Tout bas, alors… Le disque de la berceuse. Le petit dort mieux quand il l'entend." if boy else "Tout bas, alors… Le disque de la berceuse. La petite dort mieux quand elle l'entend.", 1.0)
		else:
			S._say_late(M, mamie, ["Le disque numéro un : « Bonjour, le Dôme ». Hippolyte l'a enregistré quand il avait encore des cheveux.",
				"Le numéro deux : « Il fait bon, là-haut ». Celui-là, je le passe quand quelqu'un a le cafard.",
				"Le numéro trois : la grande berceuse. Elle ne la chante qu'une fois par an. Hippolyte a attendu onze mois avec son micro."][d], 1.0, 5.0)
		await M.get_tree().create_timer(0.8).timeout
		if not _la(M, room0):
			return
		M.main.sfx("baleine", bouche, -16.0 if nuit else -9.0)
	M.act(R.P(pxc - s * 0.75, 0, pzc), "E : faire tourner un disque", tourner, 0.8, func(): return float(st["disque_t"]) <= 0.0 and str(st["jeu"]) == "")
	# le carnet des passages : une page à chaque fois ; à la fin, le compte des passages
	var lire := func() -> void:
		var pg: int = int(st["page"])
		st["page"] = pg + 1
		M.main.sfx("ui_ouvrir", R.P(gx, 0.62, gz), -12.0)
		var pages: Array = CHANTEUSE_CARNET.duplicate()
		pages.append("« Appris la Houle au petit. Il la chante trop vite. Elle, elle met trois minutes. On a le temps. »" if boy else "« Appris la Houle à la petite. Elle la chante trop vite. La Chanteuse, elle, met trois minutes. On a le temps. »")
		if bool(M.state().get("da_chanteuse", false)):
			pages.append("La dernière page, l'encre encore fraîche : « Aujourd'hui, un visiteur a chanté avec nous, et elle a répondu. Je l'écris deux fois, pour être sûre. Elle a répondu. »")
		if pg % (pages.size() + 1) == pages.size():
			M.say("Au dos du carnet, des milliers de petites étoiles, une par passage. En bas, au crayon : « Passages notés depuis soixante ans : %d. Et ce n'est pas fini. »" % (5831 + int(M.state().get("da_chanteuse_passages", 0))), 7.0)
		else:
			M.say(str(pages[pg % (pages.size() + 1)]), 9.0)
		if nuit and pg == 0:
			S._say_late(M, mamie, "Lis, lis… mais tourne les pages tout doucement.", 1.5)
		elif not nuit and r.randf() < 0.4:
			S._say_late(M, mamie, str(_pick(M, ["Ne regarde pas les fautes d'orthographe de mes huit ans.", "Il y a tout, là-dedans. Même les jours où elle n'est pas venue."])), 2.0)
	M.act(R.P(gx - s * 0.45, 0, gz + 0.1), "E : lire le carnet des passages", lire, 0.7)
	# --- ce qui bouge : les coquilles qui s'allument, la phrase de la grand-mère, le plateau qui tourne,
	# les notes du pavillon, l'ombre de la baleine derrière le hublot, la mer qui s'éclaire
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(plat):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var lum: Array = st["lum"]
		for q in range(5):
			var l: float = maxf(0.0, float(lum[q]) - dt * 1.5)
			lum[q] = l
			(lueurs[q] as StandardMaterial3D).emission_energy_multiplier = 0.25 + 0.15 * sin(t * 1.3 + q) + 3.2 * l
			(coquilles[q] as Node3D).scale = Vector3.ONE * (1.0 + 0.14 * l)
		var jeu: String = str(st["jeu"])
		if jeu == "ecoute":
			st["d"] = float(st["d"]) - dt
			if float(st["d"]) <= 0.0:
				var seq: Array = st["seq"]
				var k: int = int(st["k"])
				if k < seq.size():
					sonner.call(int(seq[k]), "mamie")
					st["k"] = k + 1
					st["d"] = 0.9
				else:
					st["jeu"] = "toi"
					st["att"] = 25.0
					if nuit:
						mamie.say("À toi… tout doucement.", 2.5)
					else:
						kid.set_pose("debout")
						kid.say(str(_pick(M, ["À toi ! Marche sur les coquilles !", "À ton tour ! Dans le même ordre !", "Vas-y, je ne regarde pas. Enfin, si."])), 2.5)
		elif jeu == "toi":
			st["att"] = float(st["att"]) - dt
			if float(st["att"]) <= 0.0:
				st["jeu"] = ""
				mamie.say(str(_pick(M, ["On reprendra. Une baleine, ça sait attendre.", "Tu réfléchis ? C'est bien. On recommencera quand tu veux."])), 3.0)
		# le phonographe
		var dt_d: float = float(st["disque_t"])
		if dt_d > 0.0:
			dt_d -= dt
			st["disque_t"] = dt_d
			plat.rotation.y -= dt * 3.6
			st["note_t"] = float(st["note_t"]) - dt
			if float(st["note_t"]) <= 0.0:
				st["note_t"] = randf_range(0.6, 1.0)
				_bulle(M, bouche + Vector3(randf_range(-0.08, 0.08), 0.05, randf_range(-0.08, 0.08)), str(["♪", "♫", "♬"][randi() % 3]), Color(0.55, 0.85, 1.0), 26 if nuit else 34, 0.5, 1.8)
			if dt_d <= 0.0:
				fin_disque.call()
		# la baleine : une ombre qui glisse derrière le hublot (10 s), la mer qui s'éclaire
		var b: float = float(st["bal"])
		if b >= 0.0:
			b += dt / 10.0
			var a: float = pow(maxf(0.0, sin(PI * minf(b, 1.0))), 0.6)
			bal.position = Vector3(lerpf(-0.3, 0.3, minf(b, 1.0)), 0.1 + 0.035 * sin(b * TAU), 0.02)
			bal.rotation.z = 0.12 * cos(b * TAU)
			bal_m.albedo_color.a = 0.85 * a
			halo_m.albedo_color.a = 0.22 * a
			lueur_mer.light_energy = 1.4 * a
			if b >= 1.0:
				b = -1.0
				bal_m.albedo_color.a = 0.0
				halo_m.albedo_color.a = 0.0
				lueur_mer.light_energy = 0.0
			st["bal"] = b
		elif jeu == "" and dt_d <= 0.0:
			# parfois, elle passe toute seule
			st["prochain"] = float(st["prochain"]) - dt
			if float(st["prochain"]) <= 0.0:
				st["prochain"] = randf_range(80.0, 150.0)
				passer.call(false)
	# --- les conversations
	var mamie_cb := func() -> void:
		if nuit:
			M.talk(mamie, "Chut… Le petit dort. Moi, je veille. La nuit, elle passe plus bas, et plus lentement. Il ne faut pas la manquer." if boy else "Chut… La petite dort. Moi, je veille. La nuit, elle passe plus bas, et plus lentement. Il ne faut pas la manquer.",
				[{"id": "dormir", "label": "Vous ne dormez pas ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if id == "dormir":
					M.talk(mamie, "À mon âge, on dort par petits morceaux, comme le pain qu'on donne aux poissons. Et entre deux morceaux, je l'écoute. C'est elle, ma berceuse.", I._bye("Bonnes bulles…"), I._close(M), "à voix basse")
				else:
					M.close_talk()
			, "à voix basse")
			return
		M.talk(mamie, str(_pick(M, ["Bonnes bulles ! Entrez. Vous tombez bien : elle passe souvent à cette heure-ci. Enfin, souvent… quand elle veut.",
			"Ah, de la visite ! Asseyez-vous. Non, pas dans mon fauteuil : il est tourné vers le hublot depuis soixante ans, il ne saurait plus regarder ailleurs.",
			"Bonjour ! Vous venez pour la baleine ? Tout le monde vient pour la baleine. Moi aussi, remarquez : je suis venue pour elle, et je suis restée."])),
			[{"id": "depuis", "label": "Vous chantez avec la baleine ?"}, {"id": "disques", "label": "Et ces disques ?"}, {"id": "repond", "label": "Elle vous répond vraiment ?"}, {"id": "fermer", "label": "Bonnes bulles !"}], func(id):
			match id:
				"depuis":
					M.talk(mamie, "Depuis mes huit ans. Elle est passée au-dessus de l'école, j'ai chanté « hou » par la fenêtre, et elle a chanté « houuu ». Madame la maîtresse m'a punie. Ça valait le coup. Depuis, je lui réponds à chaque passage. Tout est dans le carnet.", I._bye("Quelle histoire !"), I._close(M), "émue")
				"disques":
					M.talk(mamie, "Le Professeur Benthos les a enregistrés, contre la vitre de l'Institut. Quand il était jeune, il venait me les faire écouter avant même de les écouter lui-même. Il disait : « Vous, vous savez ce qu'elle dit. » Je ne sais pas. Mais je sais ce que je lui réponds.", I._bye("C'est beau."), I._close(M), "émue")
				"repond":
					M.talk(mamie, "Le Professeur dit que c'est un hasard. Puis il le note dans son Dictionnaire. Essayez donc : apprenez les cinq notes avec mon petit-fils, chantez la grande phrase… et écoutez bien le hublot." if boy else "Le Professeur dit que c'est un hasard. Puis il le note dans son Dictionnaire. Essayez donc : apprenez les cinq notes avec ma petite-fille, chantez la grande phrase… et écoutez bien le hublot.", I._bye("Je vais essayer !"), I._close(M), "malicieuse")
				_:
					M.close_talk()
		, "de bonne humeur")
	M.talk_spot(mamie, mamie_cb)
	var kid_cb := func() -> void:
		if nuit:
			M.talk(kid, "Zzz… le Grondement… la Houle… l'Écho… zzz… la Bulle… zzz…", I._bye("(Le laisser dormir)") if boy else I._bye("(La laisser dormir)"), I._close(M), "endormi" if boy else "endormie")
			return
		M.talk(kid, "Mamie m'apprend les notes de baleine ! Il y en a cinq : le Grondement, la Houle, l'Écho, la Bulle et le Sifflet. Chacune a sa coquille, par terre.",
			[{"id": "jeu", "label": "Comment on joue ?"}, {"id": "ciel", "label": "Tu as déjà vu la baleine ?"}, {"id": "fermer", "label": "Salut !"}], func(id):
			match id:
				"jeu":
					M.talk(kid, "Mamie chante une petite phrase. Toi, tu marches sur les coquilles et tu la rechantes, pareil. Trois notes, puis quatre, puis cinq. Si tu réussis la grande, des fois… elle répond !", I._bye("J'essaie !"), I._close(M), "malicieux" if boy else "malicieuse")
				"ciel":
					M.talk(kid, "Juste son ombre, tout en haut, par le hublot. Le Professeur dit qu'elle remonte respirer à la surface. Elle voit le ciel tous les jours ! Moi, jamais. Alors je lui chante des questions.", I._bye("Elle doit adorer ça."), I._close(M), "rêveur" if boy else "rêveuse")
				_:
					M.close_talk()
		, "aux anges")
	M.talk_spot(kid, kid_cb)
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Un enfant dort sur le canapé. Dans un fauteuil tourné vers le hublot, une vieille dame veille, les yeux sur la mer noire.",
			"Tout est calme. Les diodes du hublot luisent en aigue-marine. Une vieille dame fredonne, très bas, une note si grave qu'on la sent dans le sol.",
			"Il fait nuit sous la mer. Ici, quelqu'un ne dort pas : une grand-mère, son carnet sur les genoux, qui attend une baleine."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Un fauteuil tourné vers le hublot, un phonographe de nacre au grand cornet rose, et cinq coquilles posées par terre. Une vieille dame lève un doigt : « Chut… Pas encore. »",
			"« Hoummm… » Un enfant chante, accroupi sur une coquille de nacre. Dans son fauteuil, sa grand-mère corrige : « Plus grave. Plus lent. Tu es une baleine, pas un poisson-chat. »",
			"Ça sent le chocolat chaud et la nacre. Ici, on écoute la mer : une vieille dame répond au chant de la Grande Chanteuse depuis soixante ans."]))


## Le bathyscaphe de la baignoire : un enfant qui rêve d'être pilote comme Lou Grenadier a construit un
## mini-bathyscaphe (une boule jaune de récupération, un hublot de bocal, un petit phare, dix rivets qui
## sont des boutons) et le fait plonger dans une grande bassine de titane, au milieu de la pièce : des
## bulles, des poissons de bain qui tournent en rond, et tout au fond, une casserole : « LA FAILLE ». Le
## parent, ingénieur à l'Atelier des Scaphandres (chez Yolande), vérifie l'étanchéité très sérieusement,
## manomètre à l'appui (gravé : « 40 cm », comme le « 200 » de Lou). On peut faire plonger le
## mini-bathyscaphe (il descend, fait des bulles, éclaire la Faille si son phare est allumé, remonte ;
## la première fois, « étanche ! » et le goûter du pilote), allumer son phare, vérifier ses rivets, faire
## le compte à rebours. La nuit, il dort sur une serviette au bord de la bassine, son phare en veilleuse,
## et l'enfant rêve tout haut de la Faille.
static func _baignoire(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var nuit: bool = _nuit(M)
	var s: float = 1.0 if r.randf() < 0.5 else -1.0
	var boy: bool = r.randf() < 0.5
	var pere: bool = r.randf() < 0.5
	var ni: int = r.randi() % 3
	_baignoire_mats(M)
	var face := Basis(Vector3.RIGHT, PI * 0.5)
	# --- la grande bassine de titane, au milieu de la pièce (l'eau à wy), sa bande de diodes, le fond bleu
	var bx: float = s * 0.35
	var bz: float = clampf(-0.35, -hd + 1.4, hd - 2.4)
	var rb: float = 0.64
	var wy: float = 0.5
	R.kit.ring(R.L(bx, 0, bz), rb - 0.04, rb, 0.56, "argent", 40)
	R.kit.ring(R.L(bx, 0.56, bz), rb - 0.05, rb + 0.02, 0.025, "ceramique", 40)
	R.kit.ring(R.L(bx, 0.03, bz), rb, rb + 0.012, 0.02, "bai_diode", 40)
	R.kit.disc(R.L(bx, 0.03, bz), rb - 0.04, "bai_bleu", 32)
	R.kit.col_cyl(R.P(bx, 0, bz), rb, 0.58)
	R.reserve(bx, bz, rb * 2.0 + 0.2, rb * 2.0 + 0.2)
	# --- la Faille : une casserole posée au fond (le fond tout noir, une cuillère-trésor), son drapeau sur le bord
	var fxa: float = bx + s * 0.18
	var fza: float = bz - 0.15
	R.kit.ring(R.L(fxa, 0.035, fza), 0.14, 0.152, 0.1, "argent", 24)
	R.kit.disc(R.L(fxa, 0.04, fza), 0.142, "st_charbon", 20)
	R.kit.box(R.L(fxa - s * 0.22, 0.12, fza, 0.0) * Transform3D(Basis(Vector3.BACK, s * 0.12), Vector3.ZERO), Vector3(0.15, 0.018, 0.03), "fer", 1.0)
	R.kit.box(R.L(fxa + 0.03, 0.046, fza + 0.02, 35.0), Vector3(0.09, 0.006, 0.018), "argent", 1.0)
	var fdir := Vector2(fxa - bx, fza - bz).normalized()
	var drx: float = bx + fdir.x * (rb - 0.02)
	var drz: float = bz + fdir.y * (rb - 0.02)
	R.kit.cyl(R.L(drx, 0.5, drz), 0.006, 0.006, 0.36, "bois_clair", 6)
	R.kit.box(R.L(drx, 0.8, drz + 0.003), Vector3(0.24, 0.1, 0.006), "papier", 1.0)
	var drapeau := Label3D.new()
	drapeau.text = "LA FAILLE"
	drapeau.font_size = 34
	drapeau.pixel_size = 0.002
	drapeau.outline_size = 0
	drapeau.modulate = Color(0.12, 0.2, 0.5)
	M.room.add_child(drapeau)
	drapeau.global_transform = R.L(drx, 0.8, drz + 0.01)
	# l'eau : une surface bleue, un peu transparente (on voit la Faille au fond)
	var eau_m := _verre(Color(0.3, 0.72, 0.86), 0.4, 0.12)
	var eau_n: Node3D = I._node(M, R.P(bx, wy, bz), 0)
	_p(eau_n, I._cyl(rb - 0.042, rb - 0.042, 0.004, 40), eau_m, Vector3.ZERO)
	_sans_ombre(eau_n)
	# des flaques autour (on a déjà plongé, aujourd'hui), le tapis de bain
	if not nuit:
		for k in range(3):
			var a0: float = r.randf() * TAU
			R.kit.disc(R.L(bx + cos(a0) * (rb + 0.25), 0.004, bz + sin(a0) * (rb + 0.25)), r.randf_range(0.06, 0.13), "verre", 12)
	R.kit.box(R.L(bx - s * 0.95, 0.008, bz + 0.3, 15.0 * s), Vector3(0.55, 0.016, 0.38), "tissu_turquoise", 1.0)
	# --- le manomètre, sur son pied de titane au bord de la bassine (gravé « 40 cm », comme chez Lou)
	var gx: float = bx + s * 0.52
	var gz: float = bz + 0.5
	var gy: float = 0.8
	R.kit.cyl(R.L(gx, 0, gz), 0.07, 0.07, 0.02, "argent", 14)
	R.kit.cyl(R.L(gx, 0.02, gz), 0.012, 0.012, gy - 0.07, "argent", 8)
	R.kit.cyl(R.L(gx, gy, gz - 0.015) * Transform3D(face, Vector3.ZERO), 0.075, 0.075, 0.03, "argent", 24)
	R.kit.cyl(R.L(gx, gy, gz + 0.015) * Transform3D(face, Vector3.ZERO), 0.064, 0.064, 0.004, "ceramique", 24)
	R.kit.box(R.L(gx + 0.045, gy + 0.03, gz + 0.021, 0.0) * Transform3D(Basis(Vector3.BACK, -0.6), Vector3.ZERO), Vector3(0.022, 0.006, 0.002), "bai_rouge", 1.0)
	R.reserve(gx, gz, 0.3, 0.3)
	var grav := Label3D.new()
	grav.text = "40 cm"
	grav.font_size = 26
	grav.pixel_size = 0.0012
	grav.outline_size = 0
	grav.modulate = Color(0.75, 0.1, 0.1)
	M.room.add_child(grav)
	grav.global_transform = R.L(gx, gy - 0.032, gz + 0.021)
	var grav2 := Label3D.new()
	grav2.text = "Je te vois."
	grav2.font_size = 18
	grav2.pixel_size = 0.0009
	grav2.outline_size = 0
	grav2.modulate = Color(0.3, 0.32, 0.36)
	M.room.add_child(grav2)
	grav2.global_transform = R.L(gx, gy - 0.05, gz + 0.021)
	var aig: Node3D = I._node(M, R.P(gx, gy, gz + 0.026), 0)
	_p(aig, I._boxm(Vector3(0.006, 0.055, 0.003)), _mat(Color(0.12, 0.12, 0.14)), Vector3(0, 0.024, 0))
	_p(aig, I._cyl(0.008, 0.008, 0.006, 10), _mat(Color(0.12, 0.12, 0.14)), Vector3.ZERO, Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	aig.rotation.z = 1.2
	_sans_ombre(aig)
	# --- le lit de l'enfant (une coque de nacre, ses diodes) contre le mur, l'affiche du Petit Plongeon
	var lx: float = -s * (hw - 0.55)
	var lz: float = -hd + 1.1
	var lxf: Transform3D = R.L(lx, 0, lz, 0)
	var couv: String = str(_pick(M, ["jaune", "bleu", "turquoise", "orange"]))
	R.kit.box(lxf * Transform3D(Basis(), Vector3(0, 0.16, 0)), Vector3(0.98, 0.3, 2.0), "ceramique", 1.0)
	R.kit.box(lxf * Transform3D(Basis(), Vector3(0, 0.025, 0)), Vector3(1.0, 0.02, 2.02), "bai_diode", 1.0)
	R.kit.box(lxf * Transform3D(Basis(), Vector3(0, 0.38, 0)), Vector3(0.9, 0.14, 1.94), "drap", 1.0)
	R.kit.box(lxf * Transform3D(Basis(), Vector3(0, 0.47, 0.22)), Vector3(0.94, 0.05, 1.45), "tissu_" + couv, 1.0)
	R.kit.box(lxf * Transform3D(Basis(), Vector3(0, 0.5, -0.75)), Vector3(0.6, 0.1, 0.32), "drap", 1.0)
	R.kit.box(lxf * Transform3D(Basis(), Vector3(0, 0.5, -1.02)), Vector3(1.0, 0.7, 0.08), "ceramique", 1.0)
	R.kit.cyl(lxf * Transform3D(face, Vector3(0, 0.85, -1.06)), 0.5, 0.5, 0.08, "ceramique", 24)
	R.kit.col_box(lxf * Transform3D(Basis(), Vector3(0, 0.3, 0)), Vector3(1.0, 0.6, 2.0))
	R.reserve(lx, lz, 1.2, 2.3)
	R.mark_wall(lx, 1.0, -hd, 0.55)
	# un poisson en peluche sur le lit
	R.kit.box(lxf * Transform3D(Basis(Vector3.UP, 0.4), Vector3(0.18, 0.52, 0.6)), Vector3(0.12, 0.08, 0.22), "tissu_orange", 1.0)
	R.kit.box(lxf * Transform3D(Basis(Vector3.UP, 0.4), Vector3(0.22, 0.52, 0.73)), Vector3(0.1, 0.06, 0.06), "tissu_orange", 1.0)
	if R.wall_free(lx, 1.95, -hd + 0.02, 0.4):
		_tableau(M, lx, 1.95, -hd + 0.02, 0.0, 0.56, 0.78, 1)
	# --- l'établi de titane du parent (contre le mur du fond) : le plan, le bocal, la peinture jaune
	var ebx: float = s * minf(hw - 0.95, 1.75)
	var ebz: float = -hd + 0.38
	if R.is_free(ebx, ebz, 1.35, 0.65):
		R.kit.box(R.L(ebx, 0.8, ebz), Vector3(1.25, 0.04, 0.55), "argent", 1.0)
		for sx2 in [-1.0, 1.0]:
			for sz2 in [-1.0, 1.0]:
				R.kit.cyl(R.L(ebx + sx2 * 0.56, 0, ebz + sz2 * 0.22), 0.018, 0.018, 0.78, "argent", 8, false)
		R.kit.box(R.L(ebx - 0.25, 0.823, ebz + 0.02, 8.0), Vector3(0.42, 0.004, 0.3), "bai_plan", 1.0)
		var plan := Label3D.new()
		plan.text = "PLAN : MINI-BATHYSCAPHE"
		plan.font_size = 22
		plan.pixel_size = 0.0011
		plan.outline_size = 0
		plan.modulate = Color(0.92, 0.96, 1.0)
		M.room.add_child(plan)
		plan.global_transform = R.L(ebx - 0.25, 0.827, ebz + 0.02, 8.0) * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO)
		R.kit.cyl(R.L(ebx + 0.2, 0.82, ebz - 0.08), 0.06, 0.06, 0.14, "verre", 14)
		R.kit.cyl(R.L(ebx + 0.2, 0.96, ebz - 0.08), 0.062, 0.062, 0.02, "bai_rouge", 14)
		R.kit.cyl(R.L(ebx + 0.4, 0.82, ebz + 0.1), 0.05, 0.05, 0.08, "bai_jaune", 12)
		R.kit.box(R.L(ebx + 0.4, 0.905, ebz + 0.1, 30.0), Vector3(0.012, 0.012, 0.16), "bois_clair", 1.0)
		R.kit.box(R.L(ebx + 0.5, 0.825, ebz - 0.15, -20.0), Vector3(0.16, 0.012, 0.03), "fer", 1.0)
		for k2 in range(5):
			R.kit.cyl(R.L(ebx - 0.5 + k2 * 0.04, 0.82, ebz + 0.2), 0.012, 0.012, 0.006, "bai_jaune", 8)
		R.kit.col_box(R.L(ebx, 0.41, ebz), Vector3(1.25, 0.82, 0.55))
		R.reserve(ebx, ebz, 1.35, 0.65)
		R.mark_wall(ebx, 1.0, -hd, 0.7)
	# --- le fauteuil du parent (la nuit, il veille près du lit), le lampadaire, des plantes, un cadre
	var fx: float = lx + s * 1.3
	var fz: float = -hd + 0.8
	var fyaw: float = _vers(fx, fz, lx, lz + 0.3)
	var fauteuil: bool = R.is_free(fx, fz, 1.0, 1.0)
	if fauteuil:
		R.fauteuil(fx, fz, fyaw, str(_pick(M, ["blanc", "creme", "turquoise"])))
	if R.is_free(fx + s * 0.75, -hd + 0.4, 0.45, 0.45):
		_lampadaire(M, fx + s * 0.75, -hd + 0.4)
	if R.is_free(s * (hw - 0.5), hd - 1.9, 0.45, 0.45):
		_pot(M, s * (hw - 0.5), hd - 1.9, 0.0, 1.1)
	if R.is_free(-s * (hw - 0.5), hd - 1.9, 0.45, 0.45):
		_pot(M, -s * (hw - 0.5), hd - 1.9, 0.0, 0.9, "bai_jaune")
	_cadres(M, 1)
	# --- le mini-bathyscaphe : à la surface (le jour) ou sur sa serviette, au bord de la bassine (la nuit)
	var bt: Dictionary = _baignoire_bathy(M)
	var bathy: Node3D = bt["n"]
	var rivets: Array = bt["rivets"]
	var ampoule: StandardMaterial3D = bt["ampoule"]
	var lum: OmniLight3D = bt["lum"]
	var faisceau: MeshInstance3D = bt["faisceau"]
	var faisceau_m: StandardMaterial3D = bt["faisceau_m"]
	var helice: Node3D = bt["helice"]
	var surf: Vector3 = R.P(bx - s * 0.2, wy + 0.025, bz + 0.18)
	var fond: Vector3 = R.P(fxa, 0.255, fza)
	var dodo: Vector3 = R.P(bx - s * (rb - 0.02), 0.585 + 0.09, bz)
	if nuit:
		R.kit.box(R.L(bx - s * (rb - 0.02), 0.582, bz), Vector3(0.24, 0.022, 0.2), "tissu_" + couv, 1.0)
		for sx3 in [-1.0, 1.0]:
			R.kit.box(R.L(bx - s * (rb - 0.02) + sx3 * 0.12, 0.52, bz), Vector3(0.018, 0.13, 0.2), "tissu_" + couv, 1.0)
	var fond_yaw: float = atan2(fond.x - surf.x, fond.z - surf.z)
	var dodo_yaw: float = deg_to_rad(_vers(bx - s * (rb - 0.02), bz, lx, lz + 0.4))
	bathy.global_position = dodo if nuit else surf
	bathy.rotation.y = dodo_yaw if nuit else r.randf() * TAU
	var bulles: CPUParticles3D = _baignoire_bulles(M)
	# --- les poissons de bain, qui tournent en rond à la surface
	var poissons: Array = []
	var pcols: Array = [Color(1.0, 0.55, 0.15), Color(0.95, 0.45, 0.65), Color(0.35, 0.8, 0.45), Color(0.35, 0.6, 0.95)]
	for k3 in range(4):
		var pd: Dictionary = _baignoire_poisson(M, pcols[k3])
		pd["a"] = r.randf() * TAU
		pd["rr"] = r.randf_range(0.36, 0.5)
		pd["w"] = r.randf_range(0.25, 0.45) * (1.0 if k3 % 2 == 0 else -1.0)
		pd["ph"] = r.randf() * TAU
		poissons.append(pd)
	# --- les gens : le jour, le parent observe la bassine (très sérieusement), l'enfant pilote ; la nuit,
	# l'enfant dort et rêve tout haut, le parent veille dans le fauteuil
	var parent: Node
	var kid: Node
	if nuit:
		if fauteuil:
			parent = M.person("homme" if pere else "femme", fx, fz, fyaw, "lire")
		else:
			parent = M.person("homme" if pere else "femme", lx + s * 1.2, lz + 0.4, _vers(lx + s * 1.2, lz + 0.4, lx, lz), "mains_dos")
		parent.lines = ["Chut… le pilote dort.", "Écoutez… le pilote rêve de la Faille.", "Le phare fait une bonne veilleuse. Yolande serait d'accord.", "Les rivets sont vérifiés. On peut dormir."]
		parent.line_every = Vector2(10.0, 15.0)
		kid = M.person("garcon" if boy else "fille", lx, lz, 0.0, "dormir")
		kid.lie(R.P(lx, 0.5, lz + 0.78), Vector3(0, 0, -1))
		kid.lines = ["Zzz…", "Zzz… Ballasts pleins… on descend… zzz…", "Zzz… la Faille… elle est toute bleue… zzz…", "Mmh… trente-neuf centimètres… je remonte, je remonte… zzz…", "Zzz… bonjour, les poissons-lanternes… zzz…"]
		kid.line_every = Vector2(8.0, 13.0)
	else:
		var px: float = bx + s * 0.95
		var pz: float = bz - 0.35
		parent = M.person("homme" if pere else "femme", px, pz, _vers(px, pz, bx, bz), "observer")
		parent.lines = ["Étanchéité : vérifiée. Deux fois. Bon, trois.", "Pas plus de quarante centimètres, d'accord ?", "Ce bocal à cornichons tient la pression comme un vrai hublot.", "Yolande serait fière. Enfin, elle dirait « hm ».", "Joints : pâte à modeler. Tenue : excellente."]
		parent.line_every = Vector2(9.0, 14.0)
		var kx: float = bx - s * 0.95
		var kz: float = bz + 0.3
		kid = M.person("garcon" if boy else "fille", kx, kz, _vers(kx, kz, bx, bz), "debout")
		kid.lines = ["Ballasts pleins !", "Encore dix centimètres…", "Bloup ! Ça veut dire « d'accord », en bathyscaphe.", "Les poissons de bain ont peur de la Faille.", "Un jour, je descendrai dans la vraie Faille. Avec Lou.", "Plus tard, je serai pilote. Comme Lou Grenadier !"]
		kid.line_every = Vector2(6.0, 10.0)
	# --- l'état : la plongée (surface, descend, fond, remonte, nuit), le phare, les événements à venir
	var st := {"t": 0.0, "mode": "nuit" if nuit else "surface", "d": 0.0, "pos": bathy.global_position, "yaw": bathy.rotation.y,
		"phare": nuit, "occupe": false, "ev": [], "vu": false, "rond": 0.0}
	var trier := func(a, b) -> bool:
		return float(a[0]) < float(b[0])
	var plus_tard := func(dt0: float, cb: Callable) -> void:
		var ev: Array = st["ev"]
		ev.append([float(st["t"]) + dt0, cb])
		ev.sort_custom(trier)
	# le phare : l'ampoule, la lumière, le faisceau (la nuit : une veilleuse, tout doux)
	var regler_phare := func() -> void:
		var on: bool = bool(st["phare"])
		ampoule.emission_energy_multiplier = (1.4 if nuit else 3.0) if on else 0.0
		lum.light_energy = (0.45 if nuit else 1.1) if on else 0.0
		faisceau.visible = on
		faisceau_m.albedo_color.a = 0.07 if nuit else 0.16
	regler_phare.call()
	# la récompense (une fois) : le goûter du pilote
	var recompense := func() -> void:
		if bool(M.state().get("da_baignoire", false)):
			return
		M.state()["da_baignoire"] = true
		var txt: String = "Chut… Dix rivets sur dix : il est étanche, même en dormant. Tenez, tout bas : le goûter du pilote, pour demain. Règle numéro un de Lou : une plongée sans goûter, c'est une plongée ratée." if nuit else "Remontée parfaite ! Pas une goutte dans le hublot : étanche ! Tenez : le goûter du pilote. Règle numéro un de Lou Grenadier : une plongée sans goûter, c'est une plongée ratée."
		M.talk(parent, txt, I._bye("Merci… Bonne nuit !") if nuit else I._bye("Merci, et bonnes bulles !"), func(_i):
			M.give([["chocolat_abysses", 1]], "")
			M.close_talk(), "à voix basse" if nuit else "très sérieux" if pere else "très sérieuse")
	# --- faire plonger (avec ou sans compte à rebours)
	var plonger := func(compte: bool) -> void:
		if str(st["mode"]) != "surface":
			return
		st["mode"] = "descend"
		st["vu"] = false
		M.main.sfx("bulles", surf)
		_baignoire_rond(M, Vector3(surf.x, R.P(0, wy + 0.004, 0).y, surf.z))
		_bulle(M, surf + Vector3(0, 0.25, 0), "Bloup !", Color(0.8, 0.95, 1.0), 40, 0.45, 1.5)
		kid.gesture("joie", 1.6)
		if not compte:
			kid.say(str(_pick(M, ["Hé ! Sans compte à rebours ?! … Bon. Plongée !", "Plongée ! Ballasts pleins !", "On plonge ! Tenez-vous bien, les poissons !"])), 2.8)
	# --- le compte à rebours : l'enfant compte, le parent vérifie tout (très sérieusement)
	var compter := func() -> void:
		if bool(st["occupe"]) or str(st["mode"]) != "surface":
			return
		st["occupe"] = true
		var mots: Array = ["Cinq !", "Quatre !", "Trois !", "Deux !", "Un !"]
		for k4 in range(5):
			var n: int = 5 - k4
			var mot: String = str(mots[k4])
			plus_tard.call(k4 * 1.0, func() -> void:
				kid.say(mot, 1.0)
				M.main.sfx("bip", surf, -8.0)
				_bulle(M, surf + Vector3(0, 0.45, 0), "%d" % n, Color(1.0, 0.9, 0.35), 52, 0.35, 0.9))
		plus_tard.call(1.5, func() -> void:
			parent.say("Hublot : fermé.", 1.0))
		plus_tard.call(2.5, func() -> void:
			parent.say("Rivets : vérifiés.", 1.0))
		plus_tard.call(3.5, func() -> void:
			parent.say("Phare : allumé." if bool(st["phare"]) else "Phare : éteint. Hm.", 1.0))
		plus_tard.call(5.0, func() -> void:
			kid.say(str(_pick(M, ["Plongée !", "Zéro ! Plongée !", "Ballasts pleins ! Plongée !"])), 2.0)
			st["occupe"] = false
			plonger.call(true))
	# --- allumer / éteindre le phare
	var phare := func(on: bool) -> void:
		st["phare"] = on
		regler_phare.call()
		M.main.sfx("ui_clic", bathy.global_position, -10.0 if nuit else 0.0)
		if nuit:
			if on:
				parent.say("Chut… voilà. Une veilleuse de pilote.", 3.0)
				S._say_late(M, kid, "Zzz… phare allumé… zzz…", 2.5, 3.0)
			else:
				parent.say("Chut… Il dort mieux dans le noir ? Bon. Comme les poissons-lanternes éteints.", 3.5)
			return
		if on:
			_bulle(M, bathy.global_position + Vector3(0, 0.25, 0), "Clic !", Color(1.0, 0.95, 0.6), 34, 0.4, 1.2)
			if str(st["mode"]) == "fond":
				st["vu"] = true
				st["d"] = maxf(float(st["d"]), 2.5)
				kid.gesture("joie", 1.6)
				kid.say(str(_pick(M, ["Je vois le fond de la Faille ! Il y a un trésor ! … C'est une cuillère.", "La Faille ! Elle est toute noire au fond ! Et il y a… une cuillère !"])), 3.5)
			else:
				kid.say(str(_pick(M, ["Phare allumé !", "Lumière ! Les poissons de bain vont être éblouis.", "Comme le vrai ! Lou allume toujours ses phares avant la Faille."])), 2.5)
		else:
			kid.say(str(_pick(M, ["Phare éteint. Économie d'énergie !", "Hé ! Il fait tout noir, maintenant."])), 2.2)
	# --- vérifier les rivets : on tapote les dix, un par un ; le verdict (la nuit : la récompense)
	var verifier := func() -> void:
		if bool(st["occupe"]):
			return
		st["occupe"] = true
		var n2: int = rivets.size()
		for k5 in range(n2):
			var rv: Node3D = rivets[k5]
			plus_tard.call(0.3 + k5 * 0.28, func() -> void:
				if not is_instance_valid(rv):
					return
				var tw: Tween = M.room.create_tween()
				tw.tween_property(rv, "scale", Vector3.ONE * 2.2, 0.08)
				tw.tween_property(rv, "scale", Vector3.ONE, 0.14)
				M.main.sfx("ui_clic", rv.global_position, -16.0 if nuit else -4.0)
				_bulle(M, rv.global_position + Vector3(0, 0.1, 0), "tic", Color(0.85, 0.9, 0.95), 22 if nuit else 28, 0.2, 0.8))
		plus_tard.call(0.6 + n2 * 0.28, func() -> void:
			st["occupe"] = false
			if nuit:
				parent.say(str(_pick(M, ["Chut… Dix rivets sur dix. Il peut dormir tranquille.", "Tous les rivets dorment bien serrés. Bonne nuit, petit bathyscaphe."])), 4.0)
				plus_tard.call(4.2, recompense)
				return
			parent.say(str(_pick(M, ["Rivets : tous là. Étanchéité : parfaite. Pilote : impatient.", "Dix rivets sur dix. Bon, ce sont des boutons de culotte. Mais ils tiennent.", "Rivet numéro sept : un peu lâche… Non, c'est bon. C'était mon doigt."])), 4.0)
			S._say_late(M, kid, str(_pick(M, ["Alors ? On peut plonger ?", "Je le savais ! C'est moi qui les ai collés.", "Yolande dirait « hm » ?"])), 2.0, 3.0))
	# --- ce qui bouge : la plongée (descendre, s'arrêter au-dessus de la Faille, remonter), les bulles, la
	# petite hélice, le manomètre, les poissons de bain, le roulis à la surface ; et les événements
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(bathy):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var ev: Array = st["ev"]
		while not ev.is_empty() and float(ev[0][0]) <= t:
			var e: Array = ev.pop_front()
			(e[1] as Callable).call()
		var mode: String = str(st["mode"])
		var p0: Vector3 = st["pos"]
		var cible: Vector3 = p0
		var yaw: float = float(st["yaw"])
		var pitch: float = 0.0
		var roll: float = 0.0
		var vite: float = 1.6
		match mode:
			"surface":
				cible = surf + Vector3(0, 0.008 * sin(t * 1.7), 0)
				yaw += dt * 0.18
				roll = 0.07 * sin(t * 1.3)
				pitch = 0.04 * sin(t * 1.1 + 0.7)
				vite = 2.5
			"descend":
				cible = fond
				yaw = lerp_angle(yaw, fond_yaw, clampf(dt * 2.0, 0.0, 1.0))
				pitch = 0.3
				vite = 1.4
				if p0.distance_to(fond) < 0.02:
					st["mode"] = "fond"
					st["d"] = 2.8
					M.main.sfx("bulles", fond, -6.0)
					_bulle(M, R.P(fxa, wy + 0.2, fza), "Bloup… bloup…", Color(0.8, 0.95, 1.0), 32, 0.35, 1.6)
					if bool(st["phare"]):
						st["vu"] = true
						kid.gesture("joie", 1.6)
						kid.say(str(_pick(M, ["Je vois le fond de la Faille ! Il y a un trésor ! … C'est une cuillère.", "Profondeur maximale ! Trente-neuf centimètres ! … Je remonte, je remonte.", "Le phare éclaire la Faille ! Elle est profonde comme… une casserole."])), 3.5)
					else:
						kid.say(str(_pick(M, ["Il fait tout noir dans la Faille ! Allume le phare !", "On ne voit rien, au fond… Il faut le phare !"])), 3.0)
			"fond":
				cible = fond + Vector3(0, 0.006 * sin(t * 2.3), 0)
				yaw = lerp_angle(yaw, fond_yaw, clampf(dt * 2.0, 0.0, 1.0))
				pitch = 0.5
				st["d"] = float(st["d"]) - dt
				if float(st["d"]) <= 0.0:
					st["mode"] = "remonte"
					parent.say(str(_pick(M, ["Remontée ! Doucement… pas de palier à oublier.", "On remonte. Et on regarde le hublot : pas une goutte ?"])), 2.8)
			"remonte":
				cible = surf
				pitch = -0.35
				vite = 1.8
				if p0.distance_to(surf) < 0.02:
					st["mode"] = "surface"
					M.main.sfx("verser", surf, -8.0)
					_baignoire_rond(M, Vector3(surf.x, R.P(0, wy + 0.004, 0).y, surf.z))
					_bulle(M, surf + Vector3(0, 0.3, 0), "Plouf !", Color(0.8, 0.95, 1.0), 40, 0.45, 1.4)
					parent.gesture("applaudir", 1.6)
					parent.say(str(_pick(M, ["Hublot : sec. Étanchéité : parfaite. Bravo, pilote !", "Pas une goutte dedans. Je vérifie quand même… Étanche !", "Belle plongée. Yolande dirait « hm ». C'est un compliment."])), 3.5)
					plus_tard.call(3.8, recompense)
			"nuit":
				cible = dodo
				yaw = dodo_yaw
		var p: Vector3 = p0.lerp(cible, 1.0 - exp(-dt * vite))
		st["pos"] = p
		st["yaw"] = yaw
		bathy.global_position = p
		bathy.rotation = Vector3(pitch, yaw, roll)
		var sous: bool = mode == "descend" or mode == "fond" or mode == "remonte"
		bulles.emitting = sous
		bulles.global_position = p + Vector3(0, 0.07, 0)
		helice.rotation.z += dt * (16.0 if sous else (1.5 if mode == "surface" else 0.0))
		# le manomètre : l'aiguille suit la profondeur (et tremble un peu, comme un vrai)
		var prof: float = clampf((surf.y - p.y) / maxf(0.01, surf.y - fond.y), 0.0, 1.0)
		aig.rotation.z = lerpf(1.2, -1.2, prof) + 0.03 * prof * sin(t * 13.0)
		# les poissons de bain : ils tournent à la surface (plus vite quand le bathyscaphe plonge)
		var cx0: Vector3 = R.P(bx, wy + 0.006, bz)
		var acc: float = 0.15 if mode == "nuit" else (2.4 if sous else 1.0)
		for pd2 in poissons:
			var a: float = float(pd2["a"]) + float(pd2["w"]) * dt * acc
			pd2["a"] = a
			var rr: float = float(pd2["rr"])
			var pn: Node3D = pd2["n"]
			pn.global_position = cx0 + Vector3(cos(a) * rr, 0.006 * sin(t * 1.4 + float(pd2["ph"])), sin(a) * rr)
			pn.rotation.y = -a + (0.0 if float(pd2["w"]) > 0.0 else PI)
			pn.rotation.z = 0.12 * sin(t * 1.2 + float(pd2["ph"]))
			(pd2["queue"] as Node3D).rotation.y = (0.15 if mode == "nuit" else 0.45) * sin(t * (2.0 if mode == "nuit" else 8.0) + float(pd2["ph"]))
	# --- les actions (le jour : plonger, compte à rebours, phare, rivets ; la nuit : la veilleuse, les rivets)
	M.act(R.P(bx + s * 0.15, 0, bz + 0.95), "E : faire plonger le mini-bathyscaphe", func() -> void:
		plonger.call(false)
	, 0.8, func(): return not nuit and str(st["mode"]) == "surface" and not bool(st["occupe"]))
	M.act(R.P(bx - s * 0.6, 0, bz + 0.85), "E : faire le compte à rebours", compter, 0.8,
		func(): return not nuit and str(st["mode"]) == "surface" and not bool(st["occupe"]))
	var a_phare: Vector3 = R.P(bx - s * 0.85, 0, bz - 0.55)
	M.act(a_phare, "E : rallumer la veilleuse du phare" if nuit else "E : allumer le phare du bathyscaphe", func() -> void:
		phare.call(true)
	, 0.9, func(): return not bool(st["phare"]))
	M.act(a_phare, "E : éteindre la veilleuse du phare" if nuit else "E : éteindre le phare du bathyscaphe", func() -> void:
		phare.call(false)
	, 0.9, func(): return bool(st["phare"]))
	M.act(R.P(bx + s * 0.9, 0, bz + 0.45), "E : vérifier les rivets (tout doucement)" if nuit else "E : vérifier les rivets", verifier, 0.85,
		func(): return not bool(st["occupe"]) and (str(st["mode"]) == "surface" or str(st["mode"]) == "nuit"))
	# --- les conversations
	var parent_cb := func() -> void:
		if nuit:
			M.talk(parent, "Chut… Le pilote dort. Le mini-bathyscaphe aussi, sur sa serviette, au bord de la bassine. Écoutez : on rêve de la Faille. Tout haut.",
				[{"id": "reve", "label": "Ça arrive souvent ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if id == "reve":
					M.talk(parent, "Toutes les nuits. On donne la profondeur, on vide les ballasts, on dit bonjour aux poissons-lanternes. Une nuit, j'ai entendu : « Yolande, je remonte ! » Je l'ai noté. Pour Yolande.",
						I._bye("Chut… Bonne nuit !"), I._close(M), "à voix basse")
				else:
					M.close_talk()
			, "à voix basse")
			return
		var accueil: String = str(_pick(M, ["Bonnes bulles ! Entrez, mais pas trop près de la bassine : nous sommes en essai de plongée. Je vérifie l'étanchéité. Très sérieusement.",
			"Bonnes bulles ! Attention où vous marchez : la Faille est juste là. C'est une casserole. Mais aujourd'hui, c'est la Faille.",
			"Chut… Essai d'étanchéité en cours. Ah, bonnes bulles ! Vous tombez bien : il nous faut un témoin officiel."]))
		M.talk(parent, accueil, [{"id": "etanche", "label": "C'est vraiment étanche ?"}, {"id": "yolande", "label": "Vous travaillez chez Yolande ?"},
			{"id": "fosse", "label": "Il ira un jour dans la vraie Fosse ?"}, {"id": "fermer", "label": "Bonnes bulles !"}], func(id):
			match id:
				"etanche":
					M.talk(parent, "La coque, c'est une vieille bouée jaune. Le hublot, un bocal à cornichons. Les joints, de la pâte à modeler. J'ai tout vérifié trois fois. Verdict : étanche. Enfin, étanche pour une bassine.",
						I._bye("C'est déjà beaucoup !"), I._close(M), "très sérieux" if pere else "très sérieuse")
				"yolande":
					M.talk(parent, "Je suis ingénieur à l'Atelier des Scaphandres. Yolande m'a appris une chose : tout vérifier trois fois. Alors, ici aussi, je vérifie tout trois fois. Même les rivets. Ce sont des boutons collés. Ils tiennent très bien." if pere else "Je suis ingénieure à l'Atelier des Scaphandres. Yolande m'a appris une chose : tout vérifier trois fois. Alors, ici aussi, je vérifie tout trois fois. Même les rivets. Ce sont des boutons collés. Ils tiennent très bien.",
						[{"id": "vu", "label": "Et Yolande, elle l'a vu ?"}, {"id": "fermer", "label": "Bon travail !"}], func(id2):
						if id2 == "vu":
							M.talk(parent, "Elle est passée dimanche. Elle a fait trois fois le tour de la bassine, elle a tapoté le hublot, et elle a gravé « 40 cm » sur le manomètre. Puis elle a dit : « Hm. » Chez Yolande, « hm », c'est une médaille.",
								I._bye("Une médaille !"), I._close(M), "fier" if pere else "fière")
						else:
							M.close_talk()
					, "très sérieux" if pere else "très sérieuse")
				"fosse":
					M.talk(parent, "Pour l'instant, la Faille est une casserole, et c'est très bien. Lou dit que tous les pilotes ont commencé dans une baignoire. Elle, c'était dans un évier. Elle avait quatre ans. L'évier a beaucoup souffert.",
						I._bye("Ha ha !"), I._close(M), "amusé" if pere else "amusée")
				_:
					M.close_talk()
		, "très sérieux" if pere else "très sérieuse")
	M.talk_spot(parent, parent_cb)
	var kid_cb := func() -> void:
		if nuit:
			M.talk(kid, str(_pick(M, ["Zzz… Ballasts pleins… on descend… La Faille… elle est toute bleue… zzz…", "Zzz… Trente-neuf centimètres… Lou… je vois une petite lumière… zzz…", "Mmh… Phare allumé… bonjour, la cuillère… zzz…"])),
				I._bye("(Le laisser dormir)") if boy else I._bye("(La laisser dormir)"), I._close(M), "endormi" if boy else "endormie")
			return
		var nom: String = ["C'est mon bathyscaphe ! Il s'appelle le Petit Bouchon. Comme le Petit Plongeon de Lou, mais en plus petit. Et en plus bouchon.",
			"C'est mon bathyscaphe ! Il s'appelle la Bulle Jaune. Il est jaune comme le Petit Plongeon de Lou, et rond comme une bulle. Le nom était facile.",
			"C'est mon bathyscaphe ! Il s'appelle le Tout Petit Plongeon. J'ai demandé la permission à Lou. Elle a ri. Ça veut dire oui."][ni]
		M.talk(kid, nom, [{"id": "pilote", "label": "Tu veux être pilote ?"}, {"id": "casserole", "label": "Pourquoi une casserole ?"},
			{"id": "plonger", "label": "Je peux le faire plonger ?"}, {"id": "fermer", "label": "Salut, pilote !"}], func(id):
			match id:
				"pilote":
					M.talk(kid, "Comme Lou Grenadier ! Je descendrai jusqu'à deux cents mètres. Puis deux cent un. Mais chut : il ne faut pas le dire à Yolande. Ni à Papa : ils travaillent ensemble." if pere else "Comme Lou Grenadier ! Je descendrai jusqu'à deux cents mètres. Puis deux cent un. Mais chut : il ne faut pas le dire à Yolande. Ni à Maman : elles travaillent ensemble.",
						I._bye("Motus !"), I._close(M), "rêveur" if boy else "rêveuse")
				"casserole":
					M.talk(kid, "C'est la Faille ! La vraie est trop loin, alors j'en ai fait une. Tout au fond, il y a un trésor. Ou un monstre. Allume le phare quand il est en bas, tu verras.",
						I._bye("J'y vais !"), I._close(M), "mystérieux" if boy else "mystérieuse")
				"plonger":
					M.talk(kid, "Oui ! Mais un vrai pilote fait toujours le compte à rebours. Et après, il allume son phare : au fond de la Faille, il fait tout noir.",
						I._bye("Compris, pilote !"), I._close(M), "fier" if boy else "fière")
				_:
					M.close_talk()
		, "aux anges")
	M.talk_spot(kid, kid_cb)
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Au bord d'une grande bassine, un petit bathyscaphe jaune dort sur une serviette, son phare allumé comme une veilleuse. Dans son lit, un enfant rêve tout haut de la Faille.",
			"Il fait nuit. L'eau de la bassine ne bouge plus ; les poissons de bain dorment. Un enfant marmonne dans son sommeil : « Ballasts pleins… on descend… »",
			"La pièce dort. Seul brille un tout petit phare, sur le bord d'une bassine. Dans le fauteuil, quelqu'un veille et te fait « chut » du doigt."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Au milieu de la pièce, une grande bassine. Dedans flotte une boule jaune avec un hublot : un bathyscaphe ! À côté, on vérifie l'étanchéité avec un sérieux d'amiral.",
			"Bloup ! Une petite boule jaune plonge dans une bassine, au milieu de la pièce, et remonte dans une gerbe de bulles. « Record ! » crie un enfant.",
			"Une bassine pleine d'eau, des poissons de bain, et tout au fond, une casserole avec un drapeau : « LA FAILLE ». Ici, on s'entraîne à devenir pilote."]))


## Les matières du bathyscaphe de la baignoire (le fond bleu de la bassine, les diodes aigue-marine, la
## peinture jaune, le plan bleu, le rouge du bocal). Une seule fois par pièce.
static func _baignoire_mats(M) -> void:
	var R = M.R
	if R.kit.mats.has("bai_bleu"):
		return
	R._put("bai_bleu", R._col(Color(0.55, 0.82, 0.9), 0.3))
	R._put("bai_jaune", R._col(Color(1.0, 0.8, 0.12), 0.45))
	R._put("bai_plan", R._col(Color(0.12, 0.28, 0.62), 0.9))
	R._put("bai_rouge", R._col(Color(0.8, 0.14, 0.12), 0.5))
	R._put("bai_diode", _mat(Color(0.3, 0.95, 0.88), 0.0, 0.4, 1.6))


## Le mini-bathyscaphe (repère local : le nez et son hublot en +Z) : la boule jaune, le hublot de bocal,
## le petit phare (l'ampoule, sa lumière, son faisceau), les dix rivets, l'aileron et la petite hélice.
## Renvoie {n, rivets, ampoule, lum, faisceau, faisceau_m, helice}.
static func _baignoire_bathy(M) -> Dictionary:
	var n: Node3D = I._node(M, Vector3.ZERO, 0)
	var jaune := _mat(Color(1.0, 0.8, 0.12), 0.1, 0.45)
	var titane := _mat(Color(0.82, 0.84, 0.88), 0.9, 0.3)
	var axe := Vector3(PI * 0.5, 0, 0)
	_p(n, I._sph(0.09), jaune, Vector3.ZERO)
	# le hublot : le couvercle d'argent d'un bocal, le verre bombé
	_p(n, I._cyl(0.05, 0.05, 0.014, 20), titane, Vector3(0, 0.005, 0.08), Vector3.ONE, axe)
	_p(n, I._sph(0.042), _verre(Color(0.7, 0.9, 1.0), 0.55, 0.15), Vector3(0, 0.005, 0.087), Vector3(1.0, 1.0, 0.5))
	# le petit phare, sur le dessus, tourné vers l'avant
	_p(n, I._cyl(0.018, 0.022, 0.04, 12), titane, Vector3(0, 0.085, 0.03), Vector3.ONE, axe)
	var ampoule := _mat(Color(1.0, 0.92, 0.6), 0.0, 0.3, 3.0)
	_p(n, I._sph(0.014), ampoule, Vector3(0, 0.085, 0.052))
	var lum := OmniLight3D.new()
	lum.light_color = Color(1.0, 0.9, 0.65)
	lum.omni_range = 1.0
	lum.light_energy = 0.0
	lum.shadow_enabled = false
	n.add_child(lum)
	lum.position = Vector3(0, 0.085, 0.09)
	var faisceau_m := _verre(Color(1.0, 0.95, 0.7), 0.16, 0.6)
	faisceau_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var faisceau: MeshInstance3D = _p(n, I._cyl(0.075, 0.008, 0.34, 16), faisceau_m, Vector3(0, 0.07, 0.23), Vector3.ONE, Vector3(PI * 0.5 + 0.12, 0, 0))
	# les dix rivets (des boutons collés), autour de la coque
	var rivets: Array = []
	var bouton := _mat(Color(0.86, 0.87, 0.9), 0.8, 0.35)
	for k in range(10):
		var a: float = deg_to_rad(40.0 + k * 31.0)
		rivets.append(_p(n, I._sph(0.008), bouton, Vector3(sin(a) * 0.09, 0.0, cos(a) * 0.09)))
	# l'aileron sur le dos, la petite hélice derrière
	_p(n, I._boxm(Vector3(0.008, 0.045, 0.06)), jaune, Vector3(0, 0.09, -0.05))
	_p(n, I._cyl(0.012, 0.016, 0.03, 10), titane, Vector3(0, 0, -0.098), Vector3.ONE, axe)
	var helice := Node3D.new()
	n.add_child(helice)
	helice.position = Vector3(0, 0, -0.117)
	_p(helice, I._boxm(Vector3(0.075, 0.016, 0.004)), titane, Vector3.ZERO)
	_p(helice, I._boxm(Vector3(0.016, 0.075, 0.004)), titane, Vector3.ZERO)
	_sans_ombre(n)
	return {"n": n, "rivets": rivets, "ampoule": ampoule, "lum": lum, "faisceau": faisceau, "faisceau_m": faisceau_m, "helice": helice}


## Un poisson de bain (le corps, la queue qui frétille, deux yeux), posé sur l'eau. Renvoie {n, queue}.
static func _baignoire_poisson(M, c: Color) -> Dictionary:
	var n: Node3D = I._node(M, Vector3.ZERO, 0)
	var m := _mat(c, 0.0, 0.35)
	_p(n, I._sph(0.03), m, Vector3.ZERO, Vector3(0.75, 0.8, 1.3))
	var queue := Node3D.new()
	n.add_child(queue)
	queue.position = Vector3(0, 0, -0.036)
	_p(queue, I._boxm(Vector3(0.004, 0.035, 0.03)), m, Vector3(0, 0, -0.014))
	var oeil := _mat(Color(0.08, 0.08, 0.1), 0.0, 0.3)
	for sx in [-1.0, 1.0]:
		_p(n, I._sph(0.005), oeil, Vector3(sx * 0.02, 0.008, 0.022))
	_sans_ombre(n)
	return {"n": n, "queue": queue}


## Des bulles qui montent du mini-bathyscaphe quand il est sous l'eau (emitting).
static func _baignoire_bulles(M) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 14
	p.lifetime = 0.6
	p.emitting = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.03
	p.direction = Vector3.UP
	p.spread = 25.0
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.35
	p.gravity = Vector3(0, 0.6, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.3
	var sm := SphereMesh.new()
	sm.radius = 0.008
	sm.height = 0.016
	sm.radial_segments = 8
	sm.rings = 4
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.9, 0.97, 1.0, 0.6)
	sm.material = m
	p.mesh = sm
	M.room.add_child(p)
	return p


## Un rond dans l'eau qui s'élargit et s'efface (quand le bathyscaphe plonge ou refait surface), à `at` (monde).
static func _baignoire_rond(M, at: Vector3) -> void:
	var tm := TorusMesh.new()
	tm.inner_radius = 0.06
	tm.outer_radius = 0.072
	tm.rings = 24
	tm.ring_segments = 6
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	var m := _verre(Color(0.9, 0.97, 1.0), 0.6)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	M.room.add_child(mi)
	mi.global_position = at
	mi.scale = Vector3(1.0, 0.3, 1.0)
	var tw: Tween = M.room.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3(4.2, 0.3, 4.2), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "albedo_color:a", 0.0, 1.2)
	tw.chain().tween_callback(mi.queue_free)


# =================================================================== le potager sous les lampes roses

## Les couleurs des lampes du potager, selon le réglage (et la veilleuse violette de la nuit).
const POTAGER_TEINTES := {"rose": Color(1.0, 0.42, 0.78), "blanc": Color(0.96, 0.98, 1.0), "soleil": Color(1.0, 0.84, 0.52), "veille": Color(0.56, 0.3, 1.0)}
## La force des lampes (OmniLight3D) et de leur anneau qui luit, selon le réglage.
const POTAGER_FORCE := {"rose": 1.3, "blanc": 1.15, "soleil": 1.9, "veille": 0.4}
const POTAGER_LUEUR := {"rose": 3.0, "blanc": 2.4, "soleil": 4.0, "veille": 1.4}


## Une colonne de culture hydroponique (au sol, en `at`, monde) : le socle de titane, la cuve de
## nacre, le fût et ses godets sur quatre étages ; dedans, selon `sorte` : 0 des fraises des Lampes
## (mûres ou encore pâles), 1 des salades, 2 des herbes (basilic, et un peu de basilic pourpre) ; en
## haut, l'anneau de la lampe. Le nœud tourne (tick). Rend {"n": le nœud, "grosse": la plus belle fraise}.
static func _potager_tour(M, at: Vector3, sorte: int, m: Dictionary) -> Dictionary:
	var n: Node3D = I._node(M, at, _r(M).randf() * 360.0)
	var nacre: Material = m["nacre"]
	var titane: Material = m["titane"]
	_p(n, I._cyl(0.27, 0.3, 0.1, 20), titane, Vector3(0, 0.05, 0))
	_p(n, I._cyl(0.22, 0.26, 0.26, 20), nacre, Vector3(0, 0.23, 0))
	_p(n, I._cyl(0.085, 0.085, 1.76, 14), nacre, Vector3(0, 0.36 + 0.88, 0))
	_p(n, I._cyl(0.1, 0.11, 0.06, 14), titane, Vector3(0, 2.15, 0))
	var godet: CylinderMesh = I._cyl(0.055, 0.035, 0.08, 10)
	var boule: SphereMesh = I._sph(1.0)
	var fruit: SphereMesh = I._sph(0.024)
	var tige: BoxMesh = I._boxm(Vector3(0.026, 0.12, 0.006))
	var grosse: MeshInstance3D = null
	for lv in range(4):
		var y: float = 0.62 + lv * 0.42
		for k in range(3):
			var a: float = TAU * k / 3.0 + (PI / 3.0 if lv % 2 == 1 else 0.0)
			var dir := Vector3(cos(a), 0, sin(a))
			_p(n, godet, nacre, dir * 0.12 + Vector3(0, y, 0))
			var c: Vector3 = dir * 0.15 + Vector3(0, y + 0.05, 0)
			match sorte:
				0:
					for j in range(2):
						var aj: float = a + (float(j) - 0.5) * 1.1
						_p(n, boule, m["vert"], c + Vector3(cos(aj), 0, sin(aj)) * 0.045 + Vector3(0, 0.02, 0), Vector3(0.05, 0.012, 0.04), Vector3(0, -aj, 0.3))
					var mure: bool = (lv + k) % 3 != 1
					var fr: MeshInstance3D = _p(n, fruit, m["fraise"] if mure else m["fraise_pale"], dir * 0.21 + Vector3(0, y - 0.03, 0), Vector3(1.0, 1.25, 1.0))
					_p(n, fruit, m["fraise_pale"] if mure else m["fraise"], dir * 0.19 + Vector3(sin(a) * 0.04, y - 0.07, -cos(a) * 0.04), Vector3(0.8, 1.0, 0.8))
					if lv == 1 and k == 0:
						fr.scale = Vector3(1.45, 1.8, 1.45)
						fr.material_override = m["fraise"]
						grosse = fr
				1:
					for j2 in range(3):
						var aj2: float = a + (float(j2) - 1.0) * 0.8
						_p(n, boule, m["vert_clair"] if j2 != 1 else m["vert"], c + Vector3(cos(aj2), 0, sin(aj2)) * 0.04 + Vector3(0, 0.03, 0), Vector3(0.075, 0.03, 0.06), Vector3(0, -aj2, 0.45))
				_:
					for j3 in range(4):
						var aj3: float = a + (float(j3) - 1.5) * 0.5
						_p(n, tige, m["pourpre"] if (lv + j3) % 5 == 0 else m["herbe"], c + Vector3(cos(aj3), 0, sin(aj3)) * 0.03 + Vector3(0, 0.06, 0), Vector3.ONE, Vector3(0, -aj3, 0.25 * (float(j3) - 1.5)))
	_p(n, m["anneau"], m["lampe"], Vector3(0, 2.34, 0))
	_sans_ombre(n)
	return {"n": n, "grosse": grosse}


## Une bulle d'eau qui court dans les tuyaux de verre (de point en point, monde), après `delai` ; au
## bout, en haut de la colonne : « Gloup ! ».
static func _potager_glou(M, pts: Array, m: Material, delai: float, doux: bool) -> void:
	var b := MeshInstance3D.new()
	b.mesh = I._sph(0.022)
	b.material_override = m
	b.visible = false
	b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	M.room.add_child(b)
	b.global_position = pts[0]
	var fin: Vector3 = pts[pts.size() - 1]
	var tw: Tween = M.room.create_tween()
	tw.tween_interval(delai)
	tw.tween_callback(b.show)
	for k in range(1, pts.size()):
		var d: float = (pts[k] as Vector3).distance_to(pts[k - 1])
		tw.tween_property(b, "global_position", pts[k], maxf(0.05, d / 1.3))
	tw.tween_callback(func() -> void:
		_bulle(M, fin + Vector3(0, 0.15, 0), "Gloup !", Color(0.6, 1.0, 0.92), 26 if doux else 34, 0.35, 1.3)
		M.main.sfx("bulles", fin, -18.0 if doux else -10.0))
	tw.tween_callback(b.queue_free)


## Le potager sous les lampes roses. Une famille cultive tout un potager dans son salon, comme aux
## Serres : des colonnes de culture hydroponiques qui tournent doucement (des fraises des Lampes, des
## salades, des herbes), sous des anneaux de lampes roses ; une mandarine en pot qui rougit d'une joue ;
## au fond, un mur de tubes de spiruline verte qui fait des bulles ; au plafond, des tuyaux de verre qui
## gargouillent. Tout baigne dans le rose (et en sortant, on voit tout en vert : ça fait rire). Le parent
## est cultivateur (ou cultivatrice) aux Serres, il connaît bien Mélisande. On peut récolter (la plus
## belle fraise, une seule fois : une barquette de fraises des Lampes), arroser (la vanne : les bulles
## courent dans les tuyaux), régler les lampes (rose, blanc, « soleil d'en haut »), goûter une feuille,
## et embêter la minuscule plante carnivore (« Clac ! »). La nuit, les lampes passent en veilleuse
## violette, l'enfant dort sur le canapé et la plante carnivore ronfle.
static func _potager(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var room0: Node = M.room
	var nuit: bool = _nuit(M)
	var s: float = 1.0 if r.randf() < 0.5 else -1.0
	var ni: int = r.randi() % 3
	var fem: bool = r.randf() < 0.5
	var boy: bool = r.randf() < 0.5
	var mats := {
		"nacre": _mat(Color(0.95, 0.95, 0.97), 0.25, 0.22),
		"titane": _mat(Color(0.74, 0.76, 0.8), 0.85, 0.3),
		"vert": R.kit.mats["nu_vert"], "vert_clair": R.kit.mats["nu_vert_clair"],
		"fraise": _mat(Color(0.9, 0.08, 0.16), 0.0, 0.3),
		"fraise_pale": _mat(Color(0.98, 0.78, 0.74), 0.0, 0.45),
		"herbe": _mat(Color(0.16, 0.38, 0.16), 0.0, 0.7),
		"pourpre": _mat(Color(0.42, 0.14, 0.36), 0.0, 0.6),
		"lampe": _mat(POTAGER_TEINTES["veille" if nuit else "rose"], 0.0, 0.3, float(POTAGER_LUEUR["veille" if nuit else "rose"])),
	}
	var tor := TorusMesh.new()
	tor.inner_radius = 0.24
	tor.outer_radius = 0.29
	tor.rings = 24
	tor.ring_segments = 8
	mats["anneau"] = tor
	var lampe_m: StandardMaterial3D = mats["lampe"]
	# --- les places : le mur de spiruline au fond (au milieu, loin du hublot du fond), la cuve d'eau à
	# côté (vers les colonnes), le régleur des lampes de l'autre côté ; les colonnes le long du mur s ;
	# la mandarine dans le coin du fond, côté -s ; le canapé et la table basse le long du mur -s
	var xs: float = R.W * 0.08
	var zw: float = -hd + 0.2
	var nb: int = 6
	var xt: float = s * (hw - 0.85)
	var nt: int = 3 if R.D >= 6.8 else 2
	var za: float = -hd + 1.9
	var zb: float = hd - 2.3
	var zt: Array = []
	for i in range(nt):
		zt.append(za + (zb - za) * float(i) / float(nt - 1))
	var tx: float = xs + s * 1.4
	var tz: float = -hd + 0.5
	var px: float = xs - s * 1.3
	var mx: float = -s * (hw - 0.75)
	var mz: float = -hd + 0.95
	var cx: float = -s * (hw - 0.55)
	var cz: float = clampf(0.35, -hd + 2.3, hd - 2.0)
	var tbx: float = cx + s * 1.05
	# --- le mur de spiruline : six tubes de verre pleins d'eau verte qui luit, entre deux rails de titane
	var hy: float = R.H - 0.5
	R._put("da_spiruline", _verre(Color(0.22, 0.85, 0.5), 0.6, 1.6 if nuit else 0.9))
	R.kit.box(R.L(xs, 0.08, zw), Vector3(nb * 0.3 + 0.2, 0.16, 0.3), "argent", 1.0)
	R.kit.box(R.L(xs, 0.16 + hy + 0.05, zw), Vector3(nb * 0.3 + 0.2, 0.1, 0.3), "argent", 1.0)
	for k in range(nb):
		R.kit.cyl(R.L(xs + (float(k) - (nb - 1) * 0.5) * 0.3, 0.16, zw), 0.11, 0.11, hy, "da_spiruline", 16, true)
	R.kit.col_box(R.L(xs, hy * 0.5, zw), Vector3(nb * 0.3 + 0.2, hy + 0.3, 0.32))
	R.reserve(xs, zw + 0.1, nb * 0.3 + 0.4, 0.6)
	R.mark_wall(xs, 1.5, -hd + 0.02, nb * 0.15 + 0.2)
	var vl := OmniLight3D.new()
	vl.light_color = Color(0.35, 1.0, 0.6)
	vl.light_energy = 0.8 if nuit else 0.45
	vl.omni_range = 2.6
	vl.shadow_enabled = false
	M.room.add_child(vl)
	vl.global_position = R.P(xs, 1.3, zw + 0.5)
	# les bulles qui montent dans les tubes (toujours : les algues font l'air, même la nuit)
	var bu := CPUParticles3D.new()
	bu.amount = 60
	bu.lifetime = (hy - 0.1) / 0.5
	bu.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINTS
	var pts := PackedVector3Array()
	for k2 in range(nb):
		var bx: float = (float(k2) - (nb - 1) * 0.5) * 0.3
		for e in [-0.05, 0.0, 0.05]:
			pts.append(Vector3(bx + float(e), 0, float(e) * 0.6))
	bu.emission_points = pts
	bu.direction = Vector3.UP
	bu.spread = 1.5
	bu.initial_velocity_min = 0.34
	bu.initial_velocity_max = 0.5
	bu.gravity = Vector3.ZERO
	bu.scale_amount_min = 0.5
	bu.scale_amount_max = 1.4
	var bsm := SphereMesh.new()
	bsm.radius = 0.012
	bsm.height = 0.024
	bsm.radial_segments = 6
	bsm.rings = 3
	var bmat := StandardMaterial3D.new()
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.albedo_color = Color(0.88, 1.0, 0.94, 0.7)
	bsm.material = bmat
	bu.mesh = bsm
	M.room.add_child(bu)
	bu.global_position = R.P(xs, 0.2, zw)
	# --- la cuve d'eau (verre et titane) et sa vanne, tournée vers le mur de spiruline
	R.kit.cyl(R.L(tx, 0, tz), 0.3, 0.3, 0.06, "argent", 18)
	R.kit.cyl(R.L(tx, 0.06, tz), 0.27, 0.27, 0.9, "verre", 18, false)
	R._put("da_eau", _verre(Color(0.3, 0.75, 0.7), 0.55, 0.3))
	R.kit.cyl(R.L(tx, 0.07, tz), 0.25, 0.25, 0.7, "da_eau", 18)
	R.kit.cyl(R.L(tx, 0.96, tz), 0.29, 0.25, 0.08, "argent", 18)
	R.kit.col_box(R.L(tx, 0.5, tz), Vector3(0.6, 1.0, 0.6))
	R.reserve(tx, tz, 0.8, 0.8)
	var vanne: Node3D = I._node(M, R.P(tx - s * 0.33, 0.55, tz), -90.0 * s)
	_p(vanne, I._cyl(0.02, 0.02, 0.08, 8), mats["titane"], Vector3(0, 0, -0.03), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	var roue := Node3D.new()
	vanne.add_child(roue)
	roue.position = Vector3(0, 0, 0.02)
	var vtor := TorusMesh.new()
	vtor.inner_radius = 0.05
	vtor.outer_radius = 0.065
	_p(roue, vtor, mats["titane"], Vector3.ZERO, Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	for k3 in range(3):
		_p(roue, I._boxm(Vector3(0.11, 0.01, 0.01)), mats["titane"], Vector3.ZERO, Vector3.ONE, Vector3(0, 0, PI * float(k3) / 3.0))
	_p(roue, I._sph(0.018), _mat(Color(0.3, 0.95, 0.85), 0.0, 0.3, 1.5), Vector3(0, 0, 0.01))
	# --- les colonnes de culture : 0 les fraises (au fond), 1 les salades, 2 les herbes ; le mur derrière
	# elles reste libre
	var tours: Array = []
	var grosse: MeshInstance3D = null
	var lampes: Array = []
	for i2 in range(nt):
		var zi: float = float(zt[i2])
		var d: Dictionary = _potager_tour(M, R.P(xt, 0, zi), i2, mats)
		tours.append(d["n"])
		if i2 == 0:
			grosse = d["grosse"]
		R.kit.col_box(R.L(xt, 1.0, zi), Vector3(0.5, 2.0, 0.5))
		R.reserve(xt, zi, 0.8, 0.8)
		R.mark_wall(s * (hw - 0.02), 1.6, zi, 0.5)
		for sx in [-1.0, 1.0]:
			R.kit.cyl(R.L(xt + float(sx) * 0.265, 2.34, zi), 0.006, 0.006, R.H - 2.34, "argent", 4, false)
		var tl := OmniLight3D.new()
		tl.omni_range = 2.4
		tl.shadow_enabled = false
		M.room.add_child(tl)
		tl.global_position = R.P(xt - s * 0.4, 1.5, zi)
		lampes.append(tl)
	if grosse != null:
		grosse.visible = not bool(M.state().get("da_potager_fraise", false))
	# --- les tuyaux de verre : de la cuve au plafond, puis au-dessus des colonnes, et une descente
	# jusqu'en haut de chacune
	var hc: float = R.H - 0.2
	var tuyau_m := _verre(Color(0.75, 0.95, 0.95), 0.35)
	var tuyaux: Node3D = I._node(M, R.P(0, 0, 0))
	var tcyl: CylinderMesh = I._cyl(0.025, 0.025, 1.0, 8)
	var p_a: Vector3 = R.P(tx, 1.0, tz)
	var p_b: Vector3 = R.P(tx, hc, tz)
	var p_c: Vector3 = R.P(xt, hc, tz)
	var p_d: Vector3 = R.P(xt, hc, float(zt[nt - 1]))
	for seg in [[p_a, p_b], [p_b, p_c], [p_c, p_d]]:
		_tendre(_p(tuyaux, tcyl, tuyau_m, Vector3.ZERO), seg[0], seg[1])
	for q in [p_b, p_c]:
		_p(tuyaux, I._sph(0.04), mats["titane"], tuyaux.to_local(q))
	var chemins: Array = []
	for i3 in range(nt):
		var z3: float = float(zt[i3])
		var h0: Vector3 = R.P(xt, hc, z3)
		var h1: Vector3 = R.P(xt, 2.18, z3)
		_tendre(_p(tuyaux, tcyl, tuyau_m, Vector3.ZERO), h0, h1)
		_p(tuyaux, I._sph(0.035), mats["titane"], tuyaux.to_local(h0))
		chemins.append([p_a, p_b, p_c, h0, h1])
	_sans_ombre(tuyaux)
	var glou_m := _mat(Color(0.55, 1.0, 0.9), 0.0, 0.2, 2.0)
	# --- la mandarine en pot, dans le coin : un pot de nacre, un petit tronc, un feuillage rond et ses
	# mandarines (une joue plus rose : celle qui regarde la lampe) ; son anneau de lampe au-dessus
	R.kit.cyl(R.L(mx, 0, mz), 0.3, 0.24, 0.5, "ceramique", 18)
	R.kit.cyl(R.L(mx, 0.49, mz), 0.28, 0.28, 0.01, "terreau", 18)
	R.kit.cyl(R.L(mx, 0.5, mz), 0.035, 0.045, 0.75, "bois_clair", 8)
	R.kit.col_box(R.L(mx, 0.6, mz), Vector3(0.6, 1.2, 0.6))
	R.reserve(mx, mz, 0.8, 0.8)
	R.mark_wall(mx, 1.6, -hd + 0.02, 0.5)
	var arbre: Node3D = I._node(M, R.P(mx, 0, mz), r.randf() * 360.0)
	var feuillage := _mat(Color(0.2, 0.46, 0.2), 0.0, 0.7)
	for e2 in [[Vector3(0, 1.42, 0), 0.36], [Vector3(0.2, 1.3, 0.1), 0.26], [Vector3(-0.18, 1.32, -0.08), 0.27], [Vector3(0.02, 1.62, -0.05), 0.24]]:
		_p(arbre, I._sph(1.0), feuillage, e2[0], Vector3.ONE * float(e2[1]))
	var orange := _mat(Color(1.0, 0.55, 0.1), 0.0, 0.4)
	var joue := _mat(Color(1.0, 0.36, 0.42), 0.0, 0.4)
	for k4 in range(7):
		var a4: float = TAU * k4 / 7.0 + r.randf() * 0.4
		var fy: float = 1.22 + r.randf() * 0.36
		var fp := Vector3(cos(a4) * 0.33, fy, sin(a4) * 0.33)
		_p(arbre, I._sph(0.045), orange, fp)
		_p(arbre, I._sph(0.03), joue, fp + Vector3(cos(a4) * 0.02, 0.025, sin(a4) * 0.02))
	_p(arbre, tor, lampe_m, Vector3(0, 2.3, 0), Vector3.ONE * 1.4)
	for sx2 in [-1.0, 1.0]:
		R.kit.cyl(R.L(mx + float(sx2) * 0.37, 2.3, mz), 0.006, 0.006, R.H - 2.3, "argent", 4, false)
	_sans_ombre(arbre)
	var ml := OmniLight3D.new()
	ml.omni_range = 2.2
	ml.shadow_enabled = false
	M.room.add_child(ml)
	ml.global_position = R.P(mx, 1.9, mz + 0.4)
	lampes.append(ml)
	# le « soleil d'en haut » : une grande lumière dorée au plafond (éteinte sauf dans ce réglage)
	var soleil := OmniLight3D.new()
	soleil.light_color = POTAGER_TEINTES["soleil"]
	soleil.light_energy = 0.0
	soleil.omni_range = maxf(R.W, R.D) * 1.1
	soleil.shadow_enabled = false
	M.room.add_child(soleil)
	soleil.global_position = R.P(0, R.H - 0.3, -0.3)
	var base: Array = []
	for l in R.lights:
		if is_instance_valid(l):
			base.append([l, (l as OmniLight3D).light_color, (l as OmniLight3D).light_energy])
	# --- le régleur des lampes, au mur du fond : une plaque de titane et trois diodes (rose, blanc, soleil)
	R.mark_wall(px, 1.3, -hd + 0.02, 0.3)
	R.kit.box(R.L(px, 1.3, -hd + 0.03), Vector3(0.36, 0.22, 0.03), "argent", 1.0)
	var diodes := {}
	var dn: Node3D = I._node(M, R.P(px, 1.3, -hd + 0.05))
	var di: int = 0
	for dm in ["rose", "blanc", "soleil"]:
		var dmat := _mat(POTAGER_TEINTES[dm], 0.0, 0.3, 0.3)
		_p(dn, I._sph(0.028), dmat, Vector3(-0.1 + di * 0.1, 0, 0.012), Vector3(1.0, 1.0, 0.5))
		diodes[dm] = dmat
		di += 1
	_sans_ombre(dn)
	# --- le coin du salon : le canapé, le tapis, la table basse (et la plante carnivore dessus)
	R.canape(cx, cz, 90.0 * s, str(_pick(M, ["blanc", "creme", "rose"])))
	R.tapis(tbx, cz, 90, minf(2.2, R.D - 2.4), 1.5)
	_table_basse(M, tbx, cz, 0.5, 0.9)
	R.kit.cyl(R.L(tbx, 0.38, cz + 0.25), 0.07, 0.06, 0.06, "ceramique", 12)
	_cadres(M, 1)
	# la minuscule plante carnivore : un pot de nacre, une tige, et deux pièges (deux lobes à dents qui
	# s'ouvrent et se ferment)
	var dio: Node3D = I._node(M, R.P(tbx, 0.38, cz - 0.25), r.randf() * 360.0)
	dio.scale = Vector3.ONE * 1.4
	var vert_dio := _mat(Color(0.42, 0.7, 0.25), 0.0, 0.5)
	var rouge_dio := _mat(Color(0.85, 0.15, 0.2), 0.0, 0.45)
	_p(dio, I._cyl(0.04, 0.032, 0.055, 12), mats["nacre"], Vector3(0, 0.0275, 0))
	_p(dio, I._cyl(0.036, 0.036, 0.004, 12), R.kit.mats["terreau"], Vector3(0, 0.055, 0))
	var lobes: Array = []
	for pg in [[Vector3(0, 0.1, 0), 0.0], [Vector3(0.025, 0.08, 0.02), 1.9]]:
		var pv: Vector3 = pg[0]
		_p(dio, I._cyl(0.003, 0.004, pv.y - 0.055, 5), vert_dio, Vector3(pv.x * 0.5, 0.055 + (pv.y - 0.055) * 0.5, pv.z * 0.5))
		var piege := Node3D.new()
		dio.add_child(piege)
		piege.position = pv
		piege.rotation.y = float(pg[1])
		for sd in [-1.0, 1.0]:
			var lobe := Node3D.new()
			piege.add_child(lobe)
			_p(lobe, I._sph(1.0), vert_dio, Vector3(float(sd) * 0.026, 0, 0), Vector3(0.028, 0.007, 0.024))
			_p(lobe, I._sph(1.0), rouge_dio, Vector3(float(sd) * 0.025, 0.004, 0), Vector3(0.022, 0.004, 0.019))
			for t3 in range(5):
				_p(lobe, I._boxm(Vector3(0.016, 0.002, 0.002)), vert_dio, Vector3(float(sd) * 0.058, 0, -0.018 + t3 * 0.009))
			lobes.append([lobe, float(sd)])
	_sans_ombre(dio)
	# --- les gens : le jour, le parent (cultivateur ou cultivatrice aux Serres) jardine près des
	# colonnes et l'enfant est sur le canapé ; la nuit, l'enfant dort sur le canapé et le parent veille,
	# debout, en chuchotant près de la plante qui ronfle
	var parent: Node
	var kid: Node
	if nuit:
		var npp: Vector2 = _dedans(M, tbx + s * 0.75, cz + 0.5)
		parent = M.person("femme" if fem else "homme", npp.x, npp.y, _vers(npp.x, npp.y, tbx, cz - 0.25), "mains_dos")
		parent.lines = ["Chut… elles dorment.", "La veilleuse violette, c'est pour qu'elles n'aient pas peur du noir.",
			["Tu l'entends ? Mordicus ronfle encore.", "Tu l'entends ? Gédéon ronfle encore.", "Tu l'entends ? Grignotin ronfle encore."][ni], "Demain, on récolte. Ce soir, on chuchote."]
		parent.line_every = Vector2(10.0, 15.0)
		kid = M.person("garcon" if boy else "fille", cx + s * 0.05, cz - 0.45, 90.0 * s, "dormir_assis")
		kid.lines = ["Zzz…", "Zzz… une fraise… juste une… zzz…", "Mmh… tout est vert… zzz…"]
		kid.line_every = Vector2(9.0, 14.0)
	else:
		var zl: float = float(zt[nt - 1])
		var pp: Vector2 = _dedans(M, xt - s * 0.85, zl + 0.65)
		parent = M.person("femme" if fem else "homme", pp.x, pp.y, _vers(pp.x, pp.y, xt, zl), "jardiner")
		parent.lines = ["Bonjour, mes salades. … Oh, pardon : bonjour, toi aussi.", "Rouge et bleu, ça fait rose. Et rose, ça fait des fraises.",
			"Mélisande leur parle. Moi, je leur chante. Faux, mais avec cœur.", "Tu verras, en sortant : tout sera vert. C'est normal. Ça passe.", "Allez, on tourne, on tourne… chacune son tour sous la lampe."]
		parent.line_every = Vector2(8.0, 13.0)
		kid = M.person("garcon" if boy else "fille", cx + s * 0.05, cz - 0.45, 90.0 * s, "assis")
		kid.lines = ["Maman, je peux manger une fraise ? … Juste une ?" if fem else "Papa, je peux manger une fraise ? … Juste une ?",
			"Quand je sors, je vois tout en vert ! Même Madame Odile !", "Regarde les bulles du mur : elles font la course !",
			"Le mur fait des bulles, et nous, on respire. C'est un échange.", "Un jour, je verrai le vrai soleil d'en haut. Par la Ligne."]
		kid.line_every = Vector2(6.0, 10.0)
	var st := {"t": r.randf() * 10.0, "lampe": "veille" if nuit else "rose", "arrose": false, "gouts": 0, "clac": 6.0, "clac_d": 0.0,
		"ang": 1.1 if nuit else 0.55, "ronfle": 3.0, "hic": 0}
	# --- les lampes : leur couleur, leur force, l'anneau qui luit, la pièce qui baigne dans la teinte
	var allumer := func(mode: String, dur: float) -> void:
		st["lampe"] = mode
		var c: Color = POTAGER_TEINTES[mode]
		var e: float = float(POTAGER_FORCE[mode])
		var dd: float = maxf(dur, 0.01)
		var tw: Tween = M.room.create_tween()
		tw.set_parallel(true)
		for l2 in lampes:
			if is_instance_valid(l2):
				tw.tween_property(l2, "light_color", c, dd)
				tw.tween_property(l2, "light_energy", e, dd)
		tw.tween_property(lampe_m, "emission", c, dd)
		tw.tween_property(lampe_m, "albedo_color", c, dd)
		tw.tween_property(lampe_m, "emission_energy_multiplier", float(POTAGER_LUEUR[mode]), dd)
		for b in base:
			if not is_instance_valid(b[0]):
				continue
			var bc: Color = b[1]
			var be: float = float(b[2])
			match mode:
				"rose":
					bc = bc.lerp(c, 0.55)
				"soleil":
					bc = bc.lerp(c, 0.35)
					be *= 1.25
				"veille":
					bc = bc.lerp(c, 0.65)
					be *= 0.45
			tw.tween_property(b[0], "light_color", bc, dd)
			tw.tween_property(b[0], "light_energy", be, dd)
		tw.tween_property(soleil, "light_energy", 1.4 if mode == "soleil" else 0.0, dd)
		for k5 in diodes:
			(diodes[k5] as StandardMaterial3D).emission_energy_multiplier = 3.0 if str(k5) == mode else 0.3
	allumer.call("veille" if nuit else "rose", 0.0)
	# la récompense (une seule fois) : la plus belle fraise de la colonne, et une barquette avec
	var recolter := func() -> void:
		var fp2: Vector3 = R.P(xt - s * 0.3, 1.0, float(zt[0]))
		if bool(M.state().get("da_potager_fraise", false)):
			if nuit:
				M.say("Les fraises dorment sous la veilleuse violette. On ne cueille pas une fraise qui dort : elle serait de mauvaise humeur toute la journée.", 5.0)
			else:
				M.say(str(_pick(M, ["Les autres fraises ne sont pas encore mûres : elles n'ont qu'une joue rouge, celle qui regarde la lampe. Elles attendent d'avoir les deux.",
					"Tu cherches une autre fraise bien rouge… Elles sont toutes encore un peu pâles. Demain, peut-être."])), 5.0)
				S._say_late(M, parent, "Patience : une fraise des Lampes, ça ne se presse pas. Ça rougit.", 1.2)
			return
		M.state()["da_potager_fraise"] = true
		M.main.sfx("ramasse", fp2, -12.0 if nuit else -6.0)
		if is_instance_valid(grosse):
			grosse.visible = false
		var txt: String = "Chut… Bon, d'accord. La plus rouge, celle qui dormait le plus près de la veilleuse. Une fraise des Lampes, et une petite barquette de ses sœurs. Tout bas, hein." if nuit \
			else str(_pick(M, ["Celle-là ? Tu as l'œil : c'est la plus rouge de la colonne. Mélisande dit toujours qu'on offre la première fraise au visiteur. Tiens, avec une petite barquette de ses sœurs. Chut : sinon, tout le monde en voudra.",
			"Oh, la grosse ! Elle t'attendait, je crois : elle a tourné sous la lampe toute la semaine. Une fraise des Lampes, mûrie au fond de la mer. Prends aussi la barquette, va."]))
		M.talk(parent, txt, I._bye("Merci ! Bonnes bulles !"), func(_i):
			M.give([["fraises_lampes", 1]], "")
			M.close_talk(), "à voix basse" if nuit else "aux anges")
	# --- arroser : la vanne tourne, les bulles courent dans les tuyaux, tout gargouille jusqu'en haut
	var arroser := func() -> void:
		if bool(st["arrose"]):
			return
		st["arrose"] = true
		M.main.sfx("vanne", vanne.global_position, -14.0 if nuit else -6.0)
		var tw2: Tween = M.room.create_tween()
		tw2.tween_property(roue, "rotation:z", roue.rotation.z + TAU, 1.2).set_trans(Tween.TRANS_SINE)
		for i4 in range(chemins.size()):
			_potager_glou(M, chemins[i4], glou_m, 0.4 + i4 * 0.3, nuit)
			_potager_glou(M, chemins[i4], glou_m, 0.9 + i4 * 0.3, nuit)
		if nuit:
			M.say("Tu tournes la vanne tout doucement. Les tuyaux gargouillent quand même, un peu gênés : glou… glou… dans le noir violet.", 5.0)
		else:
			M.say(str(_pick(M, ["Tu tournes la petite vanne. Dans les tuyaux de verre, l'eau se met en route : glou… glou… gloup ! Ça gargouille jusqu'en haut de chaque colonne.",
				"Un quart de tour de vanne, et tout le plafond se met à gargouiller, comme un ventre qui a faim. L'eau court dans les tuyaux jusqu'aux colonnes."])), 5.0)
		await M.get_tree().create_timer(1.4).timeout
		if not _la(M, room0):
			return
		M.main.sfx("bulles", p_c, -16.0 if nuit else -8.0)
		_bulle(M, p_c + Vector3(0, -0.2, 0), "Glou… glou…", Color(0.6, 1.0, 0.92), 28 if nuit else 38, 0.3, 1.8)
		await M.get_tree().create_timer(2.4).timeout
		if not _la(M, room0):
			return
		if nuit:
			st["hic"] = 3
			S._say_late(M, parent, ["Chut… Tu as réveillé Mordicus. Il a le hoquet, maintenant.", "Chut… Tu as réveillé Gédéon. Il a le hoquet, maintenant.", "Chut… Tu as réveillé Grignotin. Il a le hoquet, maintenant."][ni], 0.8)
		else:
			parent.say(str(_pick(M, ["Ils gargouillent, mais ils ne fuient jamais. C'est Yolande, de l'Atelier des Scaphandres, qui les a soudés.",
				"Tu entends ? C'est le bruit du dîner. Le leur, pas le nôtre.", "Pas trop, hein : une salade, ça se noie dans un verre d'eau."])), 4.0)
			S._say_late(M, kid, str(_pick(M, ["Ça fait glouglou ! Comme mon ventre !", "Les tuyaux ont le hoquet !", "Encore ! Encore une fois !"])), 2.0)
		await M.get_tree().create_timer(2.0).timeout
		st["arrose"] = false
	# --- régler les lampes : rose, puis blanc, puis « soleil d'en haut » (la nuit : la veilleuse)
	var regler := func() -> void:
		var at_p: Vector3 = R.P(px, 1.3, -hd + 0.1)
		M.main.sfx("ui_clic", at_p, -12.0 if nuit else -4.0)
		if nuit:
			var tw3: Tween = M.room.create_tween()
			tw3.tween_property(lampe_m, "emission_energy_multiplier", 3.0, 0.5)
			tw3.tween_property(lampe_m, "emission_energy_multiplier", float(POTAGER_LUEUR["veille"]), 0.8)
			M.say("Tu touches le régleur : la veilleuse violette clignote une fois, tout doucement… et reste violette. Le régleur, lui aussi, sait qu'il fait nuit.", 5.0)
			S._say_late(M, parent, "Pas la nuit… Si on allume le soleil, les fraises vont croire que c'est le matin et se réveiller toutes en même temps.", 1.0)
			return
		var suite := {"rose": "blanc", "blanc": "soleil", "soleil": "rose"}
		var mode: String = str(suite.get(str(st["lampe"]), "rose"))
		allumer.call(mode, 1.2)
		M.main.sfx("lanterne_allume", R.P(xt, 2.3, float(zt[0])), -10.0)
		match mode:
			"blanc":
				M.say("Clic. Les lampes passent au blanc. D'un coup, la salade est verte, les fraises sont rouges, et le salon a l'air tout étonné d'avoir ses vraies couleurs.", 5.5)
				S._say_late(M, parent, "Le blanc, c'est pour nous. Le rose, c'est pour elles : elles n'aiment que le rouge et le bleu.", 1.4)
				S._say_late(M, kid, "Oh ! Le canapé n'est pas rose ! Je ne savais pas !", 3.0)
			"soleil":
				_bulle(M, R.P(0, R.H - 0.6, -0.3), "☀", Color(1.0, 0.9, 0.5), 60, 0.3, 2.0)
				M.say("Clic. Mode « soleil d'en haut » : une grande lumière dorée tombe du plafond, chaude comme… comme quoi, au juste ? Personne ici n'en est très sûr.", 5.5)
				kid.gesture("joie", 2.0)
				S._say_late(M, kid, "C'est comme ça, le ciel ? Dis, c'est comme ça ?", 1.2)
				S._say_late(M, parent, "Presque. Le vrai, il paraît qu'il bouge. Et qu'il n'a pas de bouton.", 3.4)
			_:
				M.say("Clic. Tout redevient rose. Les fraises ont l'air soulagées, et la mandarine rougit de la joue qui regarde la lampe.", 5.0)
				S._say_late(M, parent, "Voilà. Elles préfèrent ça. Et moi aussi, je crois.", 1.4)
	# --- goûter une feuille de salade (ou de roquette, ou de basilic…)
	var gouter := func() -> void:
		var z1: float = float(zt[1])
		M.main.sfx("manger", R.P(xt - s * 0.4, 1.2, z1), -14.0 if nuit else -6.0)
		st["gouts"] = int(st["gouts"]) + 1
		var g: int = int(st["gouts"])
		if nuit:
			M.say("Tu goûtes une feuille, sans bruit. Elle est fraîche et croquante. Crounch. Le crounch le plus fort de toute la nuit. Sur le canapé, quelqu'un se retourne.", 5.0)
			S._say_late(M, kid, "Mmh… c'est mon goûter… zzz…", 1.6)
			return
		if g == 1:
			M.say(str(_pick(M, ["Tu croques une feuille de salade, tout juste cueillie sur la colonne. Elle est fraîche, croquante, et elle a un petit goût de… rose ? Non. De salade. Mais une très bonne salade.",
				"Une feuille de laitue, croquante comme un biscuit. Elle a poussé sans terre et sans soleil, au fond de la mer, et elle a quand même meilleur goût que bien des salades d'en haut. Elle le sait."])), 5.5)
			S._say_late(M, parent, "Alors ? Elle a entendu ma chanson ce matin. Ça se sent, non ?", 1.5)
		elif g == 2:
			M.say("Une autre feuille. Celle-là pique un peu : c'est de la roquette. Elle a du caractère, la roquette du Dôme.", 4.5)
			S._say_late(M, kid, "Bleuh ! La roquette, ça pique la langue !", 1.2)
		else:
			M.say("Encore une feuille. Croc. Tu commences à comprendre pourquoi les escargots ont l'air si heureux.", 4.5)
			parent.gesture("rire", 1.6)
			S._say_late(M, parent, str(_pick(M, ["Hé ! Tu vas finir toute la colonne ! … Bon, une dernière. Pour la route.", "Doucement : celle-là, c'était le dîner de ce soir !"])), 0.8)
	# --- la plante carnivore : elle claque (le jour), elle ronfle (la nuit)
	var plante := func() -> void:
		if nuit:
			M.say("Tu te penches vers la toute petite plante carnivore. Elle ronfle. Si, vraiment : un minuscule « rrr… pfiou… », la bouche à moitié fermée.", 5.0)
			S._say_late(M, parent, ["Chut… Mordicus rêve de moucherons. Il ronfle comme un dragon, mais un dragon de la taille d'un ongle.",
				"Chut… Gédéon rêve de moucherons. Il ronfle comme un dragon, mais un dragon de la taille d'un ongle.",
				"Chut… Grignotin rêve de moucherons. Il ronfle comme un dragon, mais un dragon de la taille d'un ongle."][ni], 1.5)
			st["ronfle"] = 0.4
			return
		st["clac_d"] = 0.8
		M.main.sfx("ui_clic", dio.global_position, -6.0)
		_bulle(M, dio.global_position + Vector3(0, 0.2, 0), "Clac !", Color(0.75, 1.0, 0.5), 34, 0.35, 1.2)
		M.say(str(_pick(M, ["Tu approches un doigt. CLAC ! La minuscule plante carnivore se referme… sur rien du tout. Elle t'a pris pour un moucheron. Un très grand moucheron.",
			"Tu chatouilles un des petits pièges. Il claque, tout fier, puis se rouvre lentement, l'air de dire : « Je t'ai eu. » Il ne t'a pas eu."])), 5.0)
		S._say_late(M, kid, ["Il fait ça à tout le monde ! Mordicus, gentil !", "Il fait ça à tout le monde ! Gédéon, gentil !", "Il fait ça à tout le monde ! Grignotin, gentil !"][ni], 1.6)
	var front: float = -s
	M.act(R.P(xt + front * 0.7, 0, float(zt[0]) + 0.25), "E : récolter une fraise des Lampes", recolter, 0.8)
	M.act(R.P(xt + front * 0.7, 0, float(zt[1]) + 0.25), "E : goûter une feuille", gouter, 0.8)
	M.act(R.P(tx - s * 0.8, 0, tz + 0.15), "E : arroser (tourner la vanne)", arroser, 0.8, func(): return not bool(st["arrose"]))
	M.act(R.P(px, 0, -hd + 0.75), "E : régler les lampes", regler, 0.8)
	M.act(R.P(tbx + s * 0.5, 0, cz - 0.3), "E : regarder la plante carnivore", plante, 0.7)
	# --- ce qui bouge : les colonnes tournent (chaque plante a sa part de lampe), la plante carnivore
	# s'ouvre, claque, respire et ronfle (et a le hoquet si on arrose la nuit)
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(dio):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		for n in tours:
			if is_instance_valid(n):
				(n as Node3D).rotation.y += dt * (0.04 if nuit else 0.1)
		var cible: float = 0.55 + 0.04 * sin(t * 2.0)
		if nuit:
			cible = 1.1 + 0.08 * sin(t * 1.4)
			dio.scale = Vector3.ONE * (1.4 + 0.05 * sin(t * 1.4))
			st["ronfle"] = float(st["ronfle"]) - dt
			if float(st["ronfle"]) <= 0.0:
				if int(st["hic"]) > 0:
					st["hic"] = int(st["hic"]) - 1
					st["ronfle"] = 1.4 if int(st["hic"]) > 0 else 5.0
					_bulle(M, dio.global_position + Vector3(0, 0.15, 0), "Hic !", Color(0.85, 0.75, 1.0), 26, 0.3, 1.2)
					M.main.sfx("hoquet", dio.global_position, -20.0)
				else:
					st["ronfle"] = randf_range(4.5, 7.0)
					_bulle(M, dio.global_position + Vector3(0, 0.15, 0), str(["Rrrr… pfiou…", "Rrr… rrr…", "Zzz…"][randi() % 3]), Color(0.82, 0.7, 1.0), 24, 0.3, 2.0)
					M.main.sfx("ronron", dio.global_position, -20.0)
		else:
			st["clac"] = float(st["clac"]) - dt
			if float(st["clac"]) <= 0.0:
				st["clac"] = randf_range(9.0, 15.0)
				st["clac_d"] = 0.5
				_bulle(M, dio.global_position + Vector3(0, 0.15, 0), "Clac !", Color(0.75, 1.0, 0.5), 22, 0.25, 1.0)
				M.main.sfx("ui_clic", dio.global_position, -18.0)
			if float(st["clac_d"]) > 0.0:
				st["clac_d"] = float(st["clac_d"]) - dt
				cible = 1.45
		var a0: float = float(st["ang"])
		var a1: float = lerpf(a0, cible, clampf(dt * (20.0 if cible > a0 + 0.3 else 3.0), 0.0, 1.0))
		st["ang"] = a1
		for e3 in lobes:
			(e3[0] as Node3D).rotation.z = float(e3[1]) * a1
	# --- les conversations
	var parent_cb := func() -> void:
		if nuit:
			M.talk(parent, "Chut… Les lampes sont en veilleuse : les plantes dorment, le petit aussi. Et sur la table, il y a quelqu'un qui ronfle. Non, pas moi.",
				[{"id": "qui", "label": "Qui ronfle ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if id == "qui":
					M.talk(parent, ["La plante carnivore. Mordicus. Gros comme un ongle, et il ronfle comme une baleine. Mélisande dit que c'est impossible. Elle n'est jamais venue la nuit.",
						"La plante carnivore. Gédéon. Gros comme un ongle, et il ronfle comme une baleine. Mélisande dit que c'est impossible. Elle n'est jamais venue la nuit.",
						"La plante carnivore. Grignotin. Gros comme un ongle, et il ronfle comme une baleine. Mélisande dit que c'est impossible. Elle n'est jamais venue la nuit."][ni],
						I._bye("Chut… Bonne nuit !"), I._close(M), "à voix basse")
				else:
					M.close_talk()
			, "à voix basse")
			return
		M.talk(parent, str(_pick(M, ["Bonnes bulles ! Entre, entre, mais attention aux tuyaux : ils gargouillent, ils ne mordent pas. Bienvenue dans notre potager. Enfin, notre salon. Enfin, les deux.",
			"Ah, de la visite ! Excuse la lumière : ici, tout est rose. Les plantes adorent. Les invités, un peu moins, au début.",
			"Bonjour ! Tu tombes bien : c'est l'heure du tour de colonnes. Regarde-les tourner : chacune son tour sous la lampe, comme au manège."])),
			[{"id": "rose", "label": "Pourquoi tout est rose ?"}, {"id": "serres", "label": "Vous travaillez aux Serres ?"}, {"id": "fermer", "label": "Bonnes bulles !"}], func(id):
			match id:
				"rose":
					M.talk(parent, "Les plantes ne mangent que le rouge et le bleu de la lumière. Le vert, elles le renvoient : c'est pour ça qu'elles sont vertes ! Alors on ne leur donne que du rouge et du bleu. Rouge et bleu, ça fait rose.",
						[{"id": "vert", "label": "Et pourquoi on voit vert en sortant ?"}, {"id": "fermer", "label": "Je comprends mieux !"}], func(id2):
						if id2 == "vert":
							M.talk(parent, "Tes yeux s'habituent au rose. Quand tu sors, ils le cherchent partout, et ils voient tout en vert pendant une minute. Mes voisins disent qu'on reconnaît ma famille de loin : on est les seuls à rire devant la Grande Perle.", I._bye("Ha ha !"), I._close(M), "aux anges")
						else:
							M.close_talk()
					, "de bonne humeur")
				"serres":
					M.talk(parent, "Je suis cultivatrice aux Serres, aux colonnes des salades. Mélisande, c'est un peu ma cheffe. Enfin, elle dit qu'elle n'est la cheffe de personne, seulement l'amie des laitues. Le soir, je rentre… et je continue à la maison. On ne se refait pas." if fem \
						else "Je suis cultivateur aux Serres, aux colonnes des salades. Mélisande, c'est un peu ma cheffe. Enfin, elle dit qu'elle n'est la cheffe de personne, seulement l'amie des laitues. Le soir, je rentre… et je continue à la maison. On ne se refait pas.",
						[{"id": "meli", "label": "Et Mélisande, elle est comment ?"}, {"id": "fermer", "label": "Bonnes bulles !"}], func(id3):
						if id3 == "meli":
							M.talk(parent, "Douce comme une feuille de laitue. Elle parle à ses salades, tout bas. Moi, je leur chante des chansons. Les miennes poussent plus vite, les siennes sont plus calmes. On en discute depuis dix ans. Et c'est elle qui m'a donné ma première fraise des Lampes.", I._bye("Ha ha ! Bonnes bulles !"), I._close(M), "ému")
						else:
							M.close_talk()
					, "de bonne humeur")
				_:
					M.close_talk()
		, "de bonne humeur")
	M.talk_spot(parent, parent_cb)
	var kid_cb := func() -> void:
		if nuit:
			M.talk(kid, "Zzz… encore une fraise… juste une… zzz…", I._bye("(Le laisser dormir)") if boy else I._bye("(La laisser dormir)"), I._close(M), "endormi" if boy else "endormie")
			return
		M.talk(kid, "Tu as vu ? Ici, tout est rose ! Mais quand je sors, je vois tout en vert. Mila dit que je suis un extraterrestre. Moi, je dis que c'est elle qui est verte.",
			[{"id": "soleil", "label": "Tu as déjà vu le vrai soleil ?"}, {"id": "plante", "label": "La plante carnivore, elle mord ?"}, {"id": "fermer", "label": "Salut !"}], func(id):
			match id:
				"soleil":
					M.talk(kid, "Jamais. Mais Maman a un réglage « soleil d'en haut » sur le mur. Il paraît que le vrai est beaucoup plus grand, et qu'il s'éteint tout seul le soir. Sans bouton ! C'est bizarre, là-haut." if fem \
						else "Jamais. Mais Papa a un réglage « soleil d'en haut » sur le mur. Il paraît que le vrai est beaucoup plus grand, et qu'il s'éteint tout seul le soir. Sans bouton ! C'est bizarre, là-haut.",
						I._bye("Un peu, oui !"), I._close(M), "aux anges")
				"plante":
					M.talk(kid, ["Mordicus ? Il est gros comme un ongle ! Il mord les moucherons. Et les doigts, mais pour rire. Et la nuit, il ronfle. Si, je te jure.",
						"Gédéon ? Il est gros comme un ongle ! Il mord les moucherons. Et les doigts, mais pour rire. Et la nuit, il ronfle. Si, je te jure.",
						"Grignotin ? Il est gros comme un ongle ! Il mord les moucherons. Et les doigts, mais pour rire. Et la nuit, il ronfle. Si, je te jure."][ni],
						I._bye("Je vais voir ça !"), I._close(M), "malicieux" if boy else "malicieuse")
				_:
					M.close_talk()
		, "aux anges")
	M.talk_spot(kid, kid_cb)
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Les lampes sont passées en veilleuse violette. Les salades dorment, le mur d'algues fait des bulles tout bas… et quelque part, sur la table basse, quelque chose ronfle.",
			"Tout baigne dans une lumière violette. Les colonnes de culture tournent au ralenti, un enfant dort sur le canapé, et une plante carnivore minuscule ronfle comme un très petit dragon.",
			"Il fait nuit au potager. Les tuyaux du plafond se taisent, les fraises dorment sous leur veilleuse, et quelqu'un te fait « chut » du doigt."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Tout est rose ! Des colonnes de salades et de fraises tournent doucement sous des lampes roses, un mur de tubes verts fait des bulles, et une mandarine rougit dans son pot. Bienvenue au salon. Enfin, au potager.",
			"Ça sent la terre mouillée… sans terre. Ici, une famille fait pousser tout un potager dans son salon, comme aux Serres : sous des lampes roses, au fond de la mer.",
			"Glou, glou… Les tuyaux du plafond gargouillent, les colonnes de culture tournent, les lampes roses ronronnent. Quelqu'un chante faux pour les salades."]))
