extends RefCounted
## V118 : les histoires des maisons des Strates, la ville de mineurs et d'artisans creusée dans le grès,
## une centaine de mètres sous Hautefond (maisons_v81 ; style « strates » : murs de grès en couches,
## dalles de grès, poutres de bois sombre, un poêle, des fenêtres à plomb qui donnent sur la caverne et
## sur le Soleil de Laiton, une porte d'acier).
## En plus des histoires communes (maisons_scenes_v81), cinq histoires à elles : le canari de la mine,
## le petit train miniature, la collection de cristaux, la maison sous la fuite d'eau, le téléphone de
## roche.
## Chaque histoire : ses meubles (bois sombre, fer, cuivre, laiton, cristal), ses gens (et leur nuit : on
## dort, on chuchote), ce qui bouge (un seul M.ctx["tick"] par maison), ce qu'on y fait, et ce dont la
## maison se souvient (M.state() : une récompense une seule fois).
## M : maisons_v81 ; S : maisons_scenes_v81 (les aides communes) ; I : maisons_iles_v82 (_part, _node…).

const S = preload("res://scripts/maisons_scenes_v81.gd")
const I = preload("res://scripts/maisons_iles_v82.gd")

## [id, poids, {style: [styles où elle peut arriver]}]
const SCENARIOS := [
	["st_canari", 11, {"style": ["strates"]}], ["st_train", 12, {"style": ["strates"]}],
	["st_cristaux", 11, {"style": ["strates"]}], ["st_fuite", 10, {"style": ["strates"]}],
	["st_roche", 11, {"style": ["strates"]}],
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
		"st_canari":
			_canari(M)
		"st_train":
			_train(M)
		"st_cristaux":
			_cristaux(M)
		"st_fuite":
			_fuite(M)
		"st_roche":
			_roche(M)


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


# =================================================================== le canari de la mine

## Le carnet de la galerie trois, posé sur le guéridon du vieux mineur.
const CANARI_CARNET := "LE CARNET DE LA GALERIE TROIS, d'une écriture appliquée : « Mardi : Mistigri chante depuis ce matin. Mercredi : il chante encore, le bavard. Jeudi, onze heures : il s'est tu. On est tous remontés. Onze heures cinq : le plafond de la galerie est tombé. Personne dessous. Merci, Mistigri. » En dessous, plus tard, au crayon : « Ses petits-enfants chantent aussi bien que lui. »"


## Le canari de la mine. Un vieux mineur à la retraite et son canari, dans une cage de laiton sur son
## pied, près de la fenêtre : un petit oiseau jaune (un corps et une tête ronds, une queue, deux ailes)
## qui saute d'un perchoir à l'autre et lance ses trilles (« ♪ » en bulles). Autrefois, au fond de la
## galerie trois, son arrière-grand-père Mistigri a sauvé toute l'équipe : il chantait quand l'air était
## bon, et il s'est tu quand l'air a tourné. On peut lui donner une graine (il mange, puis il chante une
## chanson entière ; la première fois, le vieux donne le cristal de la galerie trois, qu'il gardait pour
## « celui qui fait chanter le canari »), siffler avec lui (il répond), ouvrir la cage (il fait le tour de
## la pièce et revient). Le petit-fils (ou la petite-fille) écoute les histoires. La nuit, le mineur dort
## dans son fauteuil et le canari a la tête sous l'aile.
static func _canari(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var room0: Node = M.room
	var nuit: bool = _nuit(M)
	var s: float = 1.0 if r.randf() < 0.5 else -1.0
	var ni: int = r.randi() % 3
	var boy: bool = r.randf() < 0.5
	# le poêle au fond, de l'autre côté ; le grand tapis devant la cage
	_foyer(M, -s * R.W * 0.22)
	R.mark_wall(-s * R.W * 0.22, 1.6, -hd + 0.02, 0.6)
	var cx: float = s * (hw - 0.55)
	var cz: float = clampf(-hd * 0.3, -hd + 0.8, hd - 2.4)
	R.tapis(s * (hw - 1.7), cz + 0.5, 90, minf(2.4, R.D - 2.6), 1.6)
	# le fauteuil du vieux mineur, à côté de la cage, tourné vers la pièce ; le guéridon
	var fx: float = s * (hw - 1.05)
	var fz: float = clampf(cz + 1.2, -hd + 0.6, hd - 1.7)
	var fyaw: float = _vers(fx, fz, 0.0, cz)
	R.fauteuil(fx, fz, fyaw, str(_pick(M, ["vert", "brun", "rouge"])))
	var tx: float = fx - s * 0.9
	var tz: float = clampf(fz + 0.3, -hd + 0.6, hd - 1.7)
	R.table_ronde(tx, tz, 0.32, 0.62)
	# sur le guéridon : le casque de mineur (sa lampe), la lanterne à cristal, le carnet
	R.kit.cyl(R.L(tx + 0.1, 0.62, tz - 0.08), 0.15, 0.15, 0.012, "cuivre", 16)
	R.kit.cyl(R.L(tx + 0.1, 0.632, tz - 0.08), 0.11, 0.08, 0.1, "cuivre", 16)
	R.kit.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), R.P(tx + 0.1, 0.68, tz + 0.02)), 0.025, 0.025, 0.03, "lumiere", 10)
	var lx: float = tx - 0.12
	var lz: float = tz + 0.1
	R.kit.cyl(R.L(lx, 0.62, lz), 0.06, 0.06, 0.02, "or", 12)
	for k in range(4):
		var a: float = TAU * k / 4.0 + 0.4
		R.kit.cyl(R.L(lx + cos(a) * 0.05, 0.64, lz + sin(a) * 0.05), 0.005, 0.005, 0.14, "or", 4, false)
	R.kit.cyl(R.L(lx, 0.78, lz), 0.065, 0.02, 0.04, "or", 12)
	R.kit.cyl(R.L(lx, 0.645, lz), 0.03, 0.0, 0.11, "cristal", 6)
	var lan := OmniLight3D.new()
	lan.light_color = Color(0.5, 0.75, 1.0)
	lan.light_energy = 0.9 if nuit else 0.45
	lan.omni_range = 2.6
	lan.shadow_enabled = false
	M.room.add_child(lan)
	lan.global_position = R.P(lx, 0.85, lz)
	S._mot(M, tx, tz - 0.05, 0.62, CANARI_CARNET, "E : lire le carnet de la galerie trois")
	# la boîte du premier cristal de la galerie trois, sur le rebord de la fenêtre… ou sur un petit
	# bahut contre le mur ; le cristal brille tant que personne ne l'a mérité
	var bx: float = s * (hw - 0.3)
	var bz: float = clampf(cz - 1.0, -hd + 0.45, hd - 1.7)
	R.kit.box(R.L(bx, 0.4, bz), Vector3(0.4, 0.8, 0.6), "bois_sombre", 1.0)
	R.kit.box(R.L(bx, 0.81, bz), Vector3(0.44, 0.03, 0.64), "bois", 1.0)
	R.kit.col_box(R.L(bx, 0.4, bz), Vector3(0.4, 0.8, 0.6))
	R.reserve(bx, bz, 0.6, 0.8)
	R.kit.box(R.L(bx - s * 0.02, 0.86, bz), Vector3(0.16, 0.07, 0.12), "bois", 1.0)
	R.kit.box(R.L(bx - s * 0.02, 0.9, bz), Vector3(0.14, 0.01, 0.1), "tissu_rouge", 1.0)
	R.kit.box(Transform3D(Basis(Vector3.UP, -PI * 0.5 * s) * Basis(Vector3.RIGHT, -1.1), R.P(bx + s * 0.04, 0.93, bz)), Vector3(0.16, 0.012, 0.12), "bois", 1.0)
	var eclat: Node3D = I._node(M, R.P(bx - s * 0.02, 0.905, bz), r.randf() * 360.0)
	_p(eclat, I._cyl(0.0, 0.016, 0.07, 6), R.kit.mats["cristal"], Vector3(0, 0.035, 0), Vector3.ONE, Vector3(0.3, 0, 0.15))
	_p(eclat, I._cyl(0.0, 0.011, 0.045, 6), R.kit.mats["cristal"], Vector3(0.02, 0.02, 0.0), Vector3.ONE, Vector3(-0.2, 0, -0.5))
	eclat.visible = not bool(M.state().get("st_canari", false))
	# la pioche du vieux, accrochée au mur du fond (si le mur est libre)
	var px: float = s * (hw - 1.6)
	if R.wall_free(px, 1.6, -hd + 0.02, 0.5):
		R.mark_wall(px, 1.6, -hd + 0.02, 0.5)
		R.kit.box(Transform3D(Basis(Vector3.BACK, 0.5 * s), R.P(px, 1.55, -hd + 0.05)), Vector3(0.04, 0.85, 0.04), "bois", 1.0)
		R.kit.box(Transform3D(Basis(Vector3.BACK, 0.5 * s), R.P(px, 1.55, -hd + 0.05)) * Transform3D(Basis(), Vector3(0, 0.42, 0)), Vector3(0.5, 0.05, 0.05), "fer", 1.0)
		R.kit.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), R.P(px, 1.55, -hd + 0.03)), 0.015, 0.015, 0.04, "fer", 6)
	_cadres(M, 2)
	if R.is_free(-s * (hw - 0.5), hd - 1.8, 0.5, 0.5):
		_pot(M, -s * (hw - 0.5), hd - 1.8, 0.0, 1.1, "")
	# --- la cage de laiton, sur son pied (tournée vers la pièce) : le pied, le plateau, les barreaux,
	# le dôme, l'anneau, les deux perchoirs, la mangeoire ; la petite porte (elle s'ouvre)
	R.reserve(cx, cz, 0.8, 0.8)
	R.kit.col_box(R.L(cx, 0.8, cz), Vector3(0.5, 1.6, 0.5))
	var cage: Node3D = I._node(M, R.P(cx, 0, cz), -90.0 * s)
	var laiton := _mat(Color(0.88, 0.68, 0.3), 0.9, 0.32)
	var laiton_s := _mat(Color(0.55, 0.4, 0.2), 0.8, 0.45)
	var bois_m := _mat(Color(0.5, 0.34, 0.2), 0.0, 0.7)
	var y0: float = 1.06
	_p(cage, I._cyl(0.2, 0.24, 0.04, 20), laiton_s, Vector3(0, 0.02, 0))
	_p(cage, I._cyl(0.018, 0.018, y0, 10), laiton, Vector3(0, y0 * 0.5, 0))
	_p(cage, I._cyl(0.25, 0.24, 0.035, 24), bois_m, Vector3(0, y0, 0))
	var tor := TorusMesh.new()
	tor.inner_radius = 0.218
	tor.outer_radius = 0.232
	tor.rings = 24
	tor.ring_segments = 6
	for yy in [y0 + 0.03, y0 + 0.25, y0 + 0.44]:
		_p(cage, tor, laiton, Vector3(0, float(yy), 0))
	var barre: CylinderMesh = I._cyl(0.004, 0.004, 1.0, 5)
	for k2 in range(18):
		var a2: float = TAU * k2 / 18.0
		var bp := Vector3(sin(a2) * 0.225, 0, cos(a2) * 0.225)
		if absf(wrapf(a2, -PI, PI)) < 0.42:
			_p(cage, barre, laiton, bp + Vector3(0, y0 + 0.345, 0), Vector3(1.0, 0.19, 1.0))
		else:
			_p(cage, barre, laiton, bp + Vector3(0, y0 + 0.23, 0), Vector3(1.0, 0.42, 1.0))
	for k3 in range(6):
		var a3: float = TAU * k3 / 6.0
		var q0 := Vector3(sin(a3) * 0.225, y0 + 0.44, cos(a3) * 0.225)
		var q1 := Vector3(sin(a3) * 0.15, y0 + 0.56, cos(a3) * 0.15)
		var q2 := Vector3(0, y0 + 0.6, 0)
		_tendre(_p(cage, barre, laiton, Vector3.ZERO), cage.to_global(q0), cage.to_global(q1))
		_tendre(_p(cage, barre, laiton, Vector3.ZERO), cage.to_global(q1), cage.to_global(q2))
	var anneau := TorusMesh.new()
	anneau.inner_radius = 0.025
	anneau.outer_radius = 0.035
	_p(cage, anneau, laiton, Vector3(0, y0 + 0.63, 0), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	var perches: Array = [Vector3(-0.09, y0 + 0.148, -0.05), Vector3(0.09, y0 + 0.278, 0.05)]
	for pc in perches:
		_p(cage, I._cyl(0.008, 0.008, 0.42, 8), bois_m, Vector3(0, (pc as Vector3).y - 0.008, (pc as Vector3).z), Vector3.ONE, Vector3(0, 0, PI * 0.5))
	_p(cage, I._cyl(0.04, 0.03, 0.035, 14), _mat(Color(0.95, 0.94, 0.9), 0.0, 0.2), Vector3(0.1, y0 + 0.035, 0.15))
	_p(cage, I._cyl(0.034, 0.034, 0.004, 14), _mat(Color(0.82, 0.68, 0.38), 0.0, 0.9), Vector3(0.1, y0 + 0.05, 0.15))
	var mangeoire := Vector3(0.07, y0 + 0.054, 0.13)
	var dedans := Vector3(0.0, y0 + 0.12, 0.1)
	var dehors := Vector3(0.0, y0 + 0.13, 0.36)
	_p(cage, I._boxm(Vector3(0.19, 0.008, 0.008)), laiton, Vector3(0, y0 + 0.25, 0.212))
	var porte := Node3D.new()
	cage.add_child(porte)
	porte.position = Vector3(-0.088, y0 + 0.03, 0.205)
	for k4 in range(5):
		_p(porte, barre, laiton, Vector3(k4 * 0.044, 0.11, 0), Vector3(1.0, 0.22, 1.0))
	for yb in [0.0, 0.22]:
		_p(porte, I._boxm(Vector3(0.185, 0.008, 0.008)), laiton, Vector3(0.088, float(yb), 0))
	_p(porte, I._sph(0.008), laiton, Vector3(0.18, 0.11, 0.008))
	# la nuit, une housse de tissu sur le dôme (à moitié : on voit encore le canari)
	if nuit:
		_p(cage, I._cyl(0.06, 0.26, 0.2, 20), _mat(Color(0.25, 0.42, 0.3), 0.0, 1.0), Vector3(0, y0 + 0.52, -0.02), Vector3(1.0, 1.0, 1.0))
		_p(cage, I._boxm(Vector3(0.5, 0.36, 0.015)), _mat(Color(0.25, 0.42, 0.3), 0.0, 1.0), Vector3(0, y0 + 0.28, -0.24))
	# --- le canari : un corps rond, une tête ronde (le bec orange, deux yeux noirs), une queue, deux
	# ailes qui battent, deux petites pattes ; les pieds à l'origine, le bec vers +Z
	var jaune := _mat(Color(1.0, 0.85, 0.16), 0.0, 0.55)
	var jaune2 := _mat(Color(0.92, 0.72, 0.1), 0.0, 0.6)
	var orange := _mat(Color(1.0, 0.55, 0.15), 0.0, 0.45)
	var noir := _mat(Color(0.04, 0.04, 0.05), 0.0, 0.25)
	var ois := Node3D.new()
	M.room.add_child(ois)
	ois.scale = Vector3.ONE * 1.25
	var corps := Node3D.new()
	ois.add_child(corps)
	_p(corps, I._sph(0.038), jaune, Vector3(0, 0.045, 0), Vector3(1.0, 1.0, 1.35), Vector3(-0.35, 0, 0))
	var tete := Node3D.new()
	ois.add_child(tete)
	tete.position = Vector3(0, 0.09, 0.035)
	_p(tete, I._sph(0.027), jaune, Vector3.ZERO)
	_p(tete, I._cyl(0.0, 0.009, 0.022, 8), orange, Vector3(0, -0.004, 0.032), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	for sx in [-1.0, 1.0]:
		_p(tete, I._sph(0.006), noir, Vector3(sx * 0.019, 0.007, 0.017))
		_p(ois, I._cyl(0.003, 0.003, 0.024, 4), orange, Vector3(sx * 0.012, 0.012, 0.005))
	_p(ois, I._boxm(Vector3(0.03, 0.006, 0.065)), jaune2, Vector3(0, 0.035, -0.07), Vector3.ONE, Vector3(0.35, 0, 0))
	var ailes: Array = []
	for sx2 in [-1.0, 1.0]:
		var ai := Node3D.new()
		ois.add_child(ai)
		ai.position = Vector3(sx2 * 0.03, 0.062, 0.0)
		_p(ai, I._sph(0.03), jaune2, Vector3(sx2 * 0.006, -0.006, -0.012), Vector3(0.35, 0.7, 1.45))
		ailes.append([ai, sx2])
	_sans_ombre(ois)
	var loc := func(v: Vector3) -> Vector3:
		return cage.to_global(v)
	var vol_c: Vector3 = R.P(0, 1.95, -0.2)
	var ax: float = maxf(0.8, hw - 1.0)
	var az: float = maxf(0.7, hd - 1.15)
	# --- les gens : le vieux mineur dans son fauteuil (la nuit, il dort) ; le jour, le petit-fils ou la
	# petite-fille, debout devant la cage
	var papi: Node = M.person("vieux", fx, fz, fyaw, "dormir_assis" if nuit else "assis")
	var kid: Node = null
	if nuit:
		papi.lines = ["Zzz…", "Zzz… l'air est bon… zzz…", "Zzz… tout le monde est remonté… zzz…", ["Mmh… chante, Pépite… zzz…", "Mmh… chante, Citron… zzz…", "Mmh… chante, Paillette… zzz…"][ni]]
		papi.line_every = Vector2(10.0, 15.0)
	else:
		papi.lines = [["Chante, Pépite ! … Il chante quand il veut. Comme moi.", "Chante, Citron ! … Il chante quand il veut. Comme moi.", "Chante, Paillette ! … Il chante quand il veut. Comme moi."][ni],
			"Quarante ans de mine, et jamais entendu une plus jolie voix.", "Il chante : l'air est bon. Tout va bien.", "Bonne descente ! … Ah, non, on est déjà en bas.",
			"De mon temps, on descendait avec un canari et une gamelle. Le canari chantait, la gamelle refroidissait."]
		papi.line_every = Vector2(8.0, 13.0)
		var kp: Vector2 = _dedans(M, cx - s * 1.15, cz - 0.7)
		kid = M.person("garcon" if boy else "fille", kp.x, kp.y, _vers(kp.x, kp.y, cx, cz), "debout")
		kid.lines = ["Papi, raconte encore la galerie trois !", "Il m'a regardé ! Il m'a regardé !" if boy else "Il m'a regardée ! Il m'a regardée !",
			"Quand je serai grand, j'aurai un canari. Et un casque." if boy else "Quand je serai grande, j'aurai un canari. Et un casque.",
			"Il fait « tuit » ! Papi, il a fait « tuit » !", "Moi aussi, je sais siffler. Enfin, presque."]
		kid.line_every = Vector2(6.0, 10.0)
	var st := {"t": r.randf() * 10.0, "mode": "dodo" if nuit else "perche", "perche": 0, "pos": loc.call(perches[0]), "prev": loc.call(perches[0]),
		"hop": 2.5, "trille": 5.0, "chant": 0, "note": 0.0, "bec": 0.0, "fin": false, "from": Vector3.ZERO, "to": Vector3.ZERO, "k": 0.0,
		"ensuite": "perche", "d": 0.0, "phase": "", "phi": 0.0, "tour": 0.0, "siffle": false}
	ois.global_position = st["pos"]
	ois.rotation.y = cage.rotation.y
	# la récompense (une seule fois) : le premier cristal de la galerie trois
	var recompense := func() -> void:
		M.bonne_action_v120()  ## V120 : une bonne action, l'île s'en souvient
		papi.gesture("joie", 2.0)
		if bool(M.state().get("st_canari", false)):
			papi.say(str(_pick(M, ["Quelle voix ! Il chante mieux pour toi que pour moi.", "Bravo, l'oiseau ! Bravo, le visiteur !", "Ça, c'est une chanson de mineur. Ça résonne jusqu'au fond des galeries."])), 3.5)
			return
		M.state()["st_canari"] = true
		var txt: String = ["Il a chanté toute sa chanson, rien que pour toi ! Ce cristal, je le garde depuis quarante ans pour celui qui ferait chanter Pépite comme ça. C'est le premier cristal de la galerie trois. Tiens, il est à toi.",
			"Il a chanté toute sa chanson, rien que pour toi ! Ce cristal, je le garde depuis quarante ans pour celui qui ferait chanter Citron comme ça. C'est le premier cristal de la galerie trois. Tiens, il est à toi.",
			"Il a chanté toute sa chanson, rien que pour toi ! Ce cristal, je le garde depuis quarante ans pour celui qui ferait chanter Paillette comme ça. C'est le premier cristal de la galerie trois. Tiens, il est à toi."][ni]
		M.talk(papi, txt, I._bye("Merci ! Bonne descente !"), func(_i):
			if is_instance_valid(eclat):
				eclat.visible = false
			M.give([["eclat_cristal", 1]], "")
			M.close_talk(), "ému")
	# un saut d'un point à un autre (perchoir, mangeoire, porte)
	var sauter := func(to: Vector3, ensuite: String) -> void:
		st["from"] = st["pos"]
		st["to"] = to
		st["k"] = 0.0
		st["ensuite"] = ensuite
		st["mode"] = "saut"
	var fermer := func() -> void:
		var tw: Tween = M.room.create_tween()
		tw.tween_property(porte, "rotation:y", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		M.main.sfx("grille", cage.global_position + Vector3(0, y0, 0), -8.0)
		papi.say(str(_pick(M, ["Il revient toujours. Comme nous, à la fin de la journée.", "Et voilà : tout le monde est remonté. Je peux compter.", "Il a fait sa ronde. Un vrai contremaître."])), 3.5)
	# --- ce qui bouge : le canari (ses sauts, ses trilles, sa chanson, son vol), ses ailes, sa tête
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(ois):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var mode: String = str(st["mode"])
		var p: Vector3 = st["pos"]
		var vole: bool = false
		match mode:
			"perche":
				p = loc.call(perches[int(st["perche"])])
				st["hop"] = float(st["hop"]) - dt
				if float(st["hop"]) <= 0.0 and int(st["chant"]) <= 0:
					st["hop"] = randf_range(2.5, 5.5)
					st["perche"] = 1 - int(st["perche"])
					sauter.call(loc.call(perches[int(st["perche"])]), "perche")
				st["trille"] = float(st["trille"]) - dt
				if float(st["trille"]) <= 0.0:
					st["trille"] = randf_range(9.0, 16.0)
					if int(st["chant"]) <= 0:
						st["chant"] = randi_range(2, 4)
			"saut":
				vole = true
				var k: float = minf(1.0, float(st["k"]) + dt / 0.32)
				st["k"] = k
				p = (st["from"] as Vector3).lerp(st["to"], k) + Vector3(0, 0.07 * sin(PI * k), 0)
				if k >= 1.0:
					st["mode"] = str(st["ensuite"])
			"mange":
				p = loc.call(mangeoire)
				st["d"] = float(st["d"]) - dt
				if float(st["d"]) <= 0.0:
					st["perche"] = 1
					sauter.call(loc.call(perches[1]), "perche")
					st["hop"] = 6.0
					st["chant"] = 10
					st["fin"] = true
			"vol":
				vole = true
				var ph: String = str(st["phase"])
				if ph == "sort":
					var tg: Vector3 = loc.call(dehors)
					p = p.move_toward(tg, dt * 0.7)
					if p.distance_to(tg) < 0.02:
						st["phase"] = "tour"
						st["phi"] = atan2(p.z - vol_c.z, p.x - vol_c.x)
						st["tour"] = 0.0
						M.main.sfx("ailes", p, -10.0)
				elif ph == "tour":
					st["phi"] = float(st["phi"]) + dt * 0.62
					st["tour"] = float(st["tour"]) + dt * 0.62
					var phi: float = float(st["phi"])
					var tg2: Vector3 = vol_c + Vector3(ax * cos(phi), 0.15 * sin(t * 1.7), az * sin(phi))
					p = p.move_toward(tg2, dt * 2.4)
					if float(st["tour"]) >= TAU * 1.3:
						st["phase"] = "retour"
				elif ph == "retour":
					var tg3: Vector3 = loc.call(dehors)
					p = p.move_toward(tg3, dt * 1.4)
					if p.distance_to(tg3) < 0.03:
						st["phase"] = "entre"
				else:
					var tg4: Vector3 = loc.call(dedans)
					p = p.move_toward(tg4, dt * 0.5)
					if p.distance_to(tg4) < 0.02:
						st["perche"] = 0
						st["pos"] = p
						sauter.call(loc.call(perches[0]), "perche")
						st["hop"] = 4.0
						st["chant"] = 3
						fermer.call()
			"reveil":
				p = loc.call(perches[0])
				st["d"] = float(st["d"]) - dt
				if float(st["d"]) <= 0.0:
					st["mode"] = "dodo"
			_:
				p = loc.call(perches[0])
		# la chanson : une note à la fois (une bulle, un son, la tête qui se lève)
		if int(st["chant"]) > 0 and mode != "dodo":
			st["note"] = float(st["note"]) - dt
			if float(st["note"]) <= 0.0:
				st["note"] = randf_range(0.26, 0.4)
				st["chant"] = int(st["chant"]) - 1
				st["bec"] = 0.18
				M.main.sfx("chant_%d" % (randi() % 5), p, -12.0 if mode == "reveil" else -6.0)
				_bulle(M, p + Vector3(randf_range(-0.05, 0.05), 0.16, randf_range(-0.05, 0.05)), str(["♪", "♫", "♪", "♬"][randi() % 4]), Color(1.0, 0.9, 0.35), 26 if mode == "reveil" else 34, 0.4, 1.4)
				if int(st["chant"]) <= 0 and bool(st["fin"]):
					st["fin"] = false
					recompense.call()
		st["bec"] = maxf(0.0, float(st["bec"]) - dt)
		# où il est, où il regarde (en vol : devant lui ; posé : vers le visiteur)
		var prev: Vector3 = st["prev"]
		st["prev"] = p
		st["pos"] = p
		ois.global_position = p
		var dir: Vector3 = p - prev
		if not vole:
			dir = M.main._player_pos_v27() - p
		dir.y = 0.0
		if mode != "dodo" and mode != "reveil" and dir.length() > 0.0005:
			ois.rotation.y = lerp_angle(ois.rotation.y, atan2(dir.x, dir.z), clampf(dt * 7.0, 0.0, 1.0))
		# les ailes battent en vol ; la tête : sous l'aile la nuit, qui picore, qui chante, qui regarde
		var fl: float = (0.3 + 0.9 * absf(sin(t * 28.0))) if vole else 0.0
		for e in ailes:
			(e[0] as Node3D).rotation.z = float(e[1]) * fl
		if mode == "dodo":
			tete.position = Vector3(0.022, 0.07, -0.004)
			tete.rotation = Vector3(0.5, 2.2, 0.3)
			corps.scale = Vector3.ONE * (1.15 + 0.02 * sin(t * 1.2))
		else:
			tete.position = Vector3(0, 0.09, 0.035)
			corps.scale = Vector3.ONE
			var hx: float = 0.0
			if mode == "mange":
				hx = 0.85 * maxf(0.0, sin(t * 13.0))
			elif float(st["bec"]) > 0.0:
				hx = -0.5
			tete.rotation = Vector3(lerpf(tete.rotation.x, hx, clampf(dt * 14.0, 0.0, 1.0)), 0.0 if vole else 0.4 * sin(t * 0.9) * sin(t * 2.3), 0.0)
	# --- donner une graine : il saute à la mangeoire, picore, puis chante une chanson entière
	var graine := func() -> void:
		if nuit:
			M.say(str(_pick(M, ["Tu poses une graine au bord de la mangeoire. Le canari ne bouge pas : il dort, la tête sous l'aile, tout ébouriffé. Il la mangera demain matin.",
				"Une graine pour demain matin. Dans la cage, une petite boule jaune respire tout doucement, la tête sous l'aile."])), 5.0)
			S._say_late(M, papi, ["Zzz… pas maintenant, Pépite… zzz…", "Zzz… pas maintenant, Citron… zzz…", "Zzz… pas maintenant, Paillette… zzz…"][ni], 1.2)
			return
		if str(st["mode"]) != "perche" or int(st["chant"]) > 0:
			if kid != null:
				kid.say(str(_pick(M, ["Attends, il est occupé !", "Chut, il chante !", "Pas pendant qu'il vole !"])), 2.5)
			return
		M.main.sfx("manger", loc.call(mangeoire), -10.0)
		_bulle(M, loc.call(mangeoire) + Vector3(0, 0.15, 0), "Tic, tic, tic…", Color(1.0, 0.92, 0.7), 30, 0.35, 1.6)
		st["d"] = 1.9
		sauter.call(loc.call(mangeoire), "mange")
		M.say(str(_pick(M, ["Tu poses une graine au bord de la mangeoire. Le canari saute dessus : tic, tic, tic… puis il lève la tête et gonfle sa petite gorge jaune.",
			"Une graine de chènevis, sa préférée. Il la picore en trois coups de bec, très sérieux, puis il se redresse sur son perchoir."])), 4.5)
		if kid != null:
			S._say_late(M, kid, str(_pick(M, ["Il va chanter ! Il chante toujours après la graine !", "Chut ! Écoute bien !", "Papi, il va faire sa grande chanson !"])), 1.4)
	# --- siffler avec lui : tu siffles, il répond (deux fois) ; la nuit, il sort la tête… et se rendort
	var siffler := func() -> void:
		if bool(st["siffle"]):
			return
		st["siffle"] = true
		var tj: Vector3 = M.main._player_pos_v27() + Vector3(0, 1.75, 0)
		M.main.sfx("sifflet_compagnons", tj, -16.0 if nuit else -10.0)
		_bulle(M, tj + Vector3(0, 0.2, 0), "Fuit-fuiii… ♪" if nuit else "Fuit-fuiii ♪", Color(0.85, 0.95, 1.0), 34 if nuit else 40, 0.4, 1.6)
		await M.get_tree().create_timer(1.1).timeout
		if not _la(M, room0):
			return
		if nuit:
			st["mode"] = "reveil"
			st["d"] = 2.6
			st["chant"] = 1
			M.say("Une petite tête jaune sort de sous l'aile, cligne des yeux… et répond tout bas : une seule note. Puis elle retourne se cacher sous la plume.", 5.0)
			S._say_late(M, papi, "Zzz… il t'a répondu… c'est bon signe… zzz…", 2.0)
			await M.get_tree().create_timer(3.0).timeout
			st["siffle"] = false
			return
		st["chant"] = int(st["chant"]) + 3
		await M.get_tree().create_timer(2.2).timeout
		if not _la(M, room0):
			return
		tj = M.main._player_pos_v27() + Vector3(0, 1.75, 0)
		M.main.sfx("sifflet_compagnons", tj, -10.0)
		_bulle(M, tj + Vector3(0, 0.2, 0), "Tuii-tuii-tuiiit ♪", Color(0.85, 0.95, 1.0), 40, 0.4, 1.6)
		await M.get_tree().create_timer(1.0).timeout
		if not _la(M, room0):
			return
		st["chant"] = int(st["chant"]) + 5
		if kid != null:
			kid.gesture("joie", 2.0)
			S._say_late(M, kid, str(_pick(M, ["Il te répond ! Il te répond !", "Il a fait la même chose que toi, en mieux !", "Il t'aime bien ! Moi, il me répond une fois sur deux."])), 1.5)
		S._say_late(M, papi, str(_pick(M, ["Il siffle juste, ce visiteur. Le canari ne répond qu'aux gens qui sifflent juste.", "Ha ! Vous faites un duo. À la mine, on appelait ça « l'air est bon ».",
			"C'est comme ça qu'on se parlait, au fond. Un sifflet, une réponse : tout le monde va bien."])), 3.0)
		await M.get_tree().create_timer(3.5).timeout
		st["siffle"] = false
	# --- ouvrir la cage : il sort, fait le tour de la pièce sous le plafond… et revient tout seul
	var ouvrir := func() -> void:
		if nuit:
			M.say("La cage reste fermée : la nuit, un canari dort. Même un canari de mineur à la retraite. Surtout lui.", 4.5)
			return
		if str(st["mode"]) != "perche":
			if kid != null:
				kid.say("Attends qu'il se pose !", 2.5)
			return
		var tw: Tween = M.room.create_tween()
		tw.tween_property(porte, "rotation:y", -1.8, 0.5).set_trans(Tween.TRANS_SINE)
		M.main.sfx("grille", cage.global_position + Vector3(0, y0, 0), -8.0)
		st["pos"] = loc.call(dedans)
		sauter.call(loc.call(dedans), "vol")
		st["phase"] = "sort"
		st["chant"] = 0
		if kid != null:
			kid.gesture("joie", 2.0)
			kid.say(str(_pick(M, ["Il sort ! Il fait sa ronde !", "Baisse la tête, il arrive !", "Il vole ! Regarde, il vole !"])), 3.0)
		S._say_late(M, papi, str(_pick(M, ["N'aie pas peur : il fait le tour et il rentre. Il a toujours fait comme ça.", "Il inspecte. Un vrai canari de mine : il vérifie l'air partout.",
			"Laisse-le faire. Il connaît le chemin du retour mieux que moi."])), 1.6)
	var front: Vector3 = Vector3(-s, 0, 0)
	M.act(R.P(cx, 0, cz) + front * 0.85 + Vector3(0, 0, -0.45), "E : donner une graine au canari", graine, 0.8)
	M.act(R.P(cx, 0, cz) + front * 0.85 + Vector3(0, 0, 0.45), "E : siffler avec le canari", siffler, 0.8, func(): return not bool(st["siffle"]))
	M.act(R.P(cx, 0, cz) + front * 1.35, "E : ouvrir la cage", ouvrir, 0.8, func(): return str(st["mode"]) != "vol")
	# --- les conversations
	var papi_cb := func() -> void:
		if nuit:
			M.talk(papi, ["Mmh ? … Chut. Pépite dort, la tête sous l'aile. Ça veut dire que l'air est bon et que tout le monde est rentré. Bonne descente…",
				"Mmh ? … Chut. Citron dort, la tête sous l'aile. Ça veut dire que l'air est bon et que tout le monde est rentré. Bonne descente…",
				"Mmh ? … Chut. Paillette dort, la tête sous l'aile. Ça veut dire que l'air est bon et que tout le monde est rentré. Bonne descente…"][ni],
				[{"id": "vous", "label": "Et vous, vous dormez ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if id == "vous":
					M.talk(papi, "Moi ? Un mineur ne dort que d'un œil. L'autre surveille le canari. … Zzz…", I._bye("(Le laisser dormir)"), I._close(M), "à voix basse")
				else:
					M.close_talk()
			, "à voix basse")
			return
		M.talk(papi, str(_pick(M, ["Bonne descente ! Entre, entre. Tu viens voir mon canari ? Tout le monde vient voir mon canari. Moi, on ne me regarde plus depuis longtemps.",
			"Ah, de la visite ! Attention à la cage : il n'aime pas qu'on lui cache le Soleil de Laiton.",
			"Bonjour ! Assieds-toi… Ah, il n'y a qu'un fauteuil, et c'est le mien. Reste debout, alors : c'est bon pour les jambes."])),
			[{"id": "histoire", "label": "Il paraît qu'il a sauvé une équipe ?"}, {"id": "cristal", "label": "Et ce cristal, dans la boîte ?"}, {"id": "fermer", "label": "Bonne descente !"}], func(id):
			match id:
				"histoire":
					M.talk(papi, ["Pas lui : son arrière-grand-père, Mistigri. Dans le temps, chaque équipe descendait avec un canari. Quand l'air était bon, il chantait. Quand l'air tournait, il se taisait. Un jeudi, galerie trois, Mistigri s'est tu. On est tous remontés. Cinq minutes après, le plafond est tombé. Personne dessous.",
						"Pas lui : son arrière-grand-père, Mistigri. Dans le temps, chaque équipe descendait avec un canari. Quand l'air était bon, il chantait. Quand l'air tournait, il se taisait. Un jeudi, galerie trois, Mistigri s'est tu. On est tous remontés. Cinq minutes après, le plafond est tombé. Personne dessous.",
						"Pas elle : son arrière-grand-père, Mistigri. Dans le temps, chaque équipe descendait avec un canari. Quand l'air était bon, il chantait. Quand l'air tournait, il se taisait. Un jeudi, galerie trois, Mistigri s'est tu. On est tous remontés. Cinq minutes après, le plafond est tombé. Personne dessous."][ni],
						[{"id": "aujourdhui", "label": "Et aujourd'hui ?"}, {"id": "fermer", "label": "Merci, Mistigri…"}], func(id2):
						if id2 == "aujourdhui":
							M.talk(papi, "Aujourd'hui, Ludovic Grisou a des lampes, des étais partout, et il parle à la roche. Plus besoin de canari au fond. Alors celui-ci est à la retraite, comme moi. On chante tous les deux, le matin. Lui, mieux.", I._bye("Ha ha !"), I._close(M), "ému")
						else:
							M.close_talk()
					, "ému")
				"cristal":
					if bool(M.state().get("st_canari", false)):
						M.talk(papi, "Il est à toi, maintenant. La boîte est vide, mais elle sent encore la mine. Et le canari chante toujours un peu plus fort quand tu passes.", I._bye("Merci encore !"), I._close(M), "ému")
					else:
						M.talk(papi, "Le premier cristal de la galerie trois, celui qu'on a remonté le jour de Mistigri. Je le garde pour celui qui fera chanter le canari. Pas trois notes : sa chanson entière. Donne-lui une graine, on verra bien.", I._bye("J'essaie !"), I._close(M), "malicieux")
				_:
					M.close_talk()
		, "de bonne humeur")
	M.talk_spot(papi, papi_cb)
	if kid != null:
		var kid_cb := func() -> void:
			M.talk(kid, str(_pick(M, ["Tu sais siffler ? Papi dit que si on siffle juste, il répond. Moi, il me répond une fois sur deux. L'autre fois, il rit.",
				"Bonne descente ! Tu as vu le canari de Papi ? C'est le plus célèbre des Strates. Enfin, c'est son arrière-grand-père, le plus célèbre."])),
				[{"id": "rire", "label": "Un canari, ça rit ?"}, {"id": "fermer", "label": "Salut !"}], func(id):
				if id == "rire":
					M.talk(kid, "Ça fait « tirlititi ». Papi dit que c'est un trille. Moi, je dis que c'est un rire. Il rit quand je siffle faux. Donc il rit beaucoup.", I._bye("Ha ha !"), I._close(M), "malicieux" if boy else "malicieuse")
				else:
					M.close_talk()
			, "aux anges")
		M.talk_spot(kid, kid_cb)
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Un vieux mineur dort dans son fauteuil, près d'une cage de laiton à moitié couverte. Dedans, une petite boule jaune a la tête sous l'aile.",
			"Tout est calme. Le poêle ronronne, une lanterne à cristal luit en bleu sur le guéridon, et un canari dort, ébouriffé, sur son perchoir.",
			"Il fait nuit dans les Strates. Ici, deux retraités dorment : un vieux mineur qui ronfle, et un canari qui ne ronfle pas."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["« Tirlititi ! » Près de la fenêtre, dans une cage de laiton, un petit canari jaune saute d'un perchoir à l'autre. Un vieux mineur l'écoute, les yeux mi-clos.",
			"Ça sent le poêle et le café. Un vieux mineur dans son fauteuil, un enfant devant une cage… et dans la cage, un canari qui chante comme si l'air était le meilleur du monde.",
			"Un casque de mineur sur le guéridon, une pioche au mur, et un canari qui trille. Ici, quand l'oiseau chante, c'est que tout va bien."]))


# =================================================================== le petit train miniature

## Le règlement du Petit Train de la maison, sur le tabouret près du fauteuil.
const TRAIN_REGLEMENT := "LE RÈGLEMENT DU PETIT TRAIN DE LA MAISON, recopié de celui de Papy Ferdinand. Article un : on ne marche pas sur la voie. Article deux : on ne marche VRAIMENT pas sur la voie. Article trois : quand le train boude dans le tunnel, on va le chercher gentiment. Article quatre : on dit « Tchou-tchou », c'est obligatoire. Signé : Papy Ferdinand, et en dessous, un petit dessin de Bernadette."


## Une bouffée de fumée qui suit la cheminée de la locomotive (des particules grises, dans le monde).
static func _train_fumee(M) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 28
	p.lifetime = 1.7
	p.emitting = false
	p.local_coords = false
	p.direction = Vector3.UP
	p.spread = 14.0
	p.initial_velocity_min = 0.18
	p.initial_velocity_max = 0.32
	p.gravity = Vector3(0, 0.12, 0)
	p.damping_min = 0.2
	p.damping_max = 0.4
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.3
	var cv := Curve.new()
	cv.add_point(Vector2(0, 0.4))
	cv.add_point(Vector2(1, 1.0))
	p.scale_amount_curve = cv
	var gr := Gradient.new()
	gr.set_color(0, Color(0.82, 0.82, 0.84, 0.75))
	gr.set_color(1, Color(0.6, 0.6, 0.62, 0.0))
	p.color_ramp = gr
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _tache()
	q.material = m
	p.mesh = q
	M.room.add_child(p)
	return p


## Une petite maison de la maquette (repère de la pièce), son toit en pointe.
static func _train_maison(M, x: float, z: float, yaw: float, mur: String, toit: String) -> void:
	var R = M.R
	R.kit.box(R.L(x, 0.075, z, yaw), Vector3(0.2, 0.15, 0.17), mur, 1.0)
	R.kit.cyl(Transform3D(Basis(Vector3.UP, deg_to_rad(yaw) + PI * 0.25), R.P(x, 0.15, z)), 0.16, 0.0, 0.11, toit, 4)
	R.kit.box(R.L(x, 0.04, z, yaw) * Transform3D(Basis(), Vector3(0, 0, 0.086)), Vector3(0.04, 0.07, 0.004), "bois_sombre", 1.0)
	R.kit.box(R.L(x, 0.1, z, yaw) * Transform3D(Basis(), Vector3(0.06, 0, 0.086)), Vector3(0.035, 0.035, 0.004), "lumiere", 1.0)


## Le petit train miniature. Une famille d'amis de Papy Ferdinand a monté un circuit qui fait le tour du
## salon : une voie ovale au sol (traverses et rails d'argent sur un grand feutre vert), une petite
## locomotive verte et laiton (« Petite Bernadette ») et deux voitures qui roulent en boucle ; au milieu,
## un village de carton et sa petite Colonne au Soleil de Laiton ; un tunnel de carton au fond, un passage
## à niveau devant (les barrières se baissent, le feu clignote), une gare à charbon et sa trémie, un quai
## et un Papy Ferdinand en pâte à modeler. L'enfant fait « tchou-tchou ». On peut pousser le levier (le
## train accélère et siffle), remplir le tender (on verse le seau dans la trémie : au passage suivant, le
## train fait le plein et fume), soulever le tunnel (le train s'y cache et boude ; on voit dépasser le
## dernier wagon). La première fois qu'il file à toute vapeur, en fumant : une galette des Rouages. La
## nuit, l'enfant dort sur un matelas près de la voie, les wagons éclairés font un tour au ralenti.
static func _train(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var room0: Node = M.room
	var nuit: bool = _nuit(M)
	var s: float = 1.0 if r.randf() < 0.5 else -1.0
	var boy: bool = r.randf() < 0.5
	# l'ovale de la voie (repère de la pièce) : loin du poêle, la porte libre
	var zmin: float = -hd + 1.05
	var zmax: float = hd - 1.8
	var tcz: float = (zmin + zmax) * 0.5
	var b: float = maxf(0.8, (zmax - zmin) * 0.5)
	var a: float = maxf(1.3, hw - 1.25)
	R.reserve(0.0, tcz, 2.0 * a + 0.3, 2.0 * b + 0.3)
	var pt := func(th: float) -> Vector2:
		return Vector2(a * cos(th), tcz + b * sin(th))
	var sp := func(th: float) -> float:
		return maxf(0.05, sqrt(a * a * sin(th) * sin(th) + b * b * cos(th) * cos(th)))
	var th_t: float = -PI * 0.5                       # le tunnel, au fond
	var th_p: float = PI * 0.5                        # le passage à niveau, devant
	var th_c: float = 0.0 if s > 0.0 else PI          # la gare à charbon, du côté s
	var th_g: float = PI if s > 0.0 else 0.0          # le quai, de l'autre côté
	# le poêle au fond (du côté s), le fauteuil de l'ancien dans l'autre coin, le tabouret du règlement
	_foyer(M, s * R.W * 0.22)
	R.mark_wall(s * R.W * 0.22, 1.6, -hd + 0.02, 0.6)
	var gx: float = -s * (hw - 0.65)
	var gz: float = -hd + 0.65
	var gyaw: float = _vers(gx, gz, 0.0, tcz)
	R.fauteuil(gx, gz, gyaw, str(_pick(M, ["brun", "vert", "rouge"])))
	R.tabouret(gx + s * 0.7, gz - 0.1)
	S._mot(M, gx + s * 0.7, gz - 0.1, 0.44, TRAIN_REGLEMENT, "E : lire le règlement du Petit Train")
	_cadres(M, 2)
	# le feutre vert sous la voie, la voie (traverses de bois, deux rails d'argent)
	R.kit.disc(Transform3D(Basis.from_scale(Vector3(a + 0.16, 1.0, b + 0.16)), R.P(0, 0.003, tcz)), 1.0, "st_feutre", 40)
	var nseg: int = 96
	for i in range(nseg):
		var t0: float = TAU * i / nseg
		var t1: float = TAU * (i + 1) / nseg
		var p0: Vector2 = pt.call(t0)
		var p1: Vector2 = pt.call(t1)
		var tm: float = (t0 + t1) * 0.5
		var nrm: Vector2 = Vector2(b * cos(tm), a * sin(tm)).normalized()
		var d: Vector2 = p1 - p0
		var yaw: float = atan2(d.x, d.y)
		var mid: Vector2 = (p0 + p1) * 0.5
		for sd in [-1.0, 1.0]:
			var mr: Vector2 = mid + nrm * 0.045 * float(sd)
			R.kit.box(Transform3D(Basis(Vector3.UP, yaw), R.P(mr.x, 0.022, mr.y)), Vector3(0.01, 0.012, d.length() + 0.004), "argent", 1.0)
		if i % 2 == 0:
			R.kit.box(Transform3D(Basis(Vector3.UP, yaw), R.P(mid.x, 0.01, mid.y)), Vector3(0.14, 0.014, 0.03), "bois_sombre", 1.0)
	# le village de carton, au milieu ; sa petite Colonne et son Soleil de Laiton (un bouchon doré)
	var murs: Array = ["tissu_creme", "tissu_jaune", "carton", "tissu_rouge"]
	for k in range(4):
		var ph: float = 0.6 + TAU * k / 4.0 + r.randf_range(-0.3, 0.3)
		var hx: float = a * 0.5 * cos(ph)
		var hz: float = tcz + b * 0.45 * sin(ph)
		_train_maison(M, hx, hz, r.randf() * 360.0, str(murs[k]), str(_pick(M, ["brique", "tissu_rouge", "tissu_brun"])))
		R.kit.cyl(R.L(hx + 0.2, 0.0, hz + 0.05), 0.05, 0.0, 0.16, "nu_vert", 6)
	R.kit.cyl(R.L(0, 0.0, tcz), 0.06, 0.06, 0.02, "fer", 12)
	R.kit.cyl(R.L(0, 0.0, tcz), 0.012, 0.012, 0.55, "or", 8, false)
	R.kit.ring(R.L(0, 0.38, tcz), 0.08, 0.095, 0.012, "or", 18)
	R.kit.ring(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), R.P(0, 0.385, tcz)), 0.08, 0.095, 0.012, "or", 18)
	R.kit.cyl(R.L(0, 0.36, tcz), 0.035, 0.035, 0.05, "lumiere", 10)
	# le quai, son auvent, et un Papy Ferdinand en pâte à modeler (bleu de chauffe, casquette)
	var qg: Vector2 = pt.call(th_g)
	var qn: Vector2 = Vector2(-s, 0.0)
	var qp: Vector2 = qg + qn * 0.15
	R.kit.box(R.L(qp.x, 0.025, qp.y), Vector3(0.14, 0.05, 0.55), "pierre_lisse", 1.0)
	for sz in [-0.22, 0.22]:
		R.kit.box(R.L(qp.x + qn.x * 0.04, 0.12, qp.y + float(sz)), Vector3(0.015, 0.19, 0.015), "fer", 1.0)
	R.kit.box(R.L(qp.x, 0.22, qp.y), Vector3(0.2, 0.012, 0.6), "tissu_rouge", 1.0)
	R.kit.cyl(R.L(qp.x, 0.05, qp.y + 0.1), 0.017, 0.015, 0.045, "tissu_bleu", 8)
	R.kit.cyl(R.L(qp.x, 0.095, qp.y + 0.1), 0.014, 0.014, 0.025, "tissu_rose", 8)
	R.kit.cyl(R.L(qp.x, 0.118, qp.y + 0.1), 0.016, 0.016, 0.008, "noir", 8)
	R.kit.cyl(R.L(qp.x, 0.096, qp.y + 0.115), 0.01, 0.006, 0.015, "tissu_blanc", 6)
	# la gare à charbon : la trémie sur ses quatre pieds, la goulotte vers la voie, le seau à côté
	var qc: Vector2 = pt.call(th_c)
	var cn: Vector2 = Vector2(s, 0.0)
	var hp: Vector2 = qc + cn * 0.2
	for lx in [-0.05, 0.05]:
		for lz in [-0.05, 0.05]:
			R.kit.box(R.L(hp.x + float(lx), 0.1, hp.y + float(lz)), Vector3(0.012, 0.2, 0.012), "fer", 1.0)
	R.kit.cyl(Transform3D(Basis(Vector3.BACK, PI), R.P(hp.x, 0.3, hp.y)), 0.08, 0.03, 0.1, "fer", 10)
	R.kit.box(Transform3D(Basis(Vector3.BACK, 0.6 * s), R.P(hp.x - cn.x * 0.1, 0.19, hp.y)), Vector3(0.1, 0.012, 0.04), "fer", 1.0)
	var seau: Vector2 = qc + cn * 0.55
	R.kit.cyl(R.L(seau.x, 0.0, seau.y), 0.09, 0.11, 0.2, "fer", 14)
	R.kit.cyl(R.L(seau.x, 0.17, seau.y), 0.1, 0.1, 0.02, "st_charbon", 14)
	R.kit.ring(Transform3D(Basis(Vector3.BACK, PI * 0.5), R.P(seau.x, 0.2, seau.y)), 0.09, 0.1, 0.008, "fer", 14)
	R.reserve(seau.x, seau.y, 0.35, 0.35)
	# le pupitre du levier (contre le côté s) : la caisse de bois, la plaque de laiton, le levier
	var lvx: float = s * (hw - 0.6)
	var lvz: float = tcz - b * 0.55
	R.kit.box(R.L(lvx, 0.35, lvz), Vector3(0.3, 0.7, 0.3), "bois", 1.0)
	R.kit.box(R.L(lvx, 0.705, lvz), Vector3(0.32, 0.012, 0.32), "or", 1.0)
	R.kit.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5 * s), R.P(lvx - s * 0.152, 0.5, lvz)), 0.04, 0.04, 0.01, "ceramique", 14)
	R.kit.col_box(R.L(lvx, 0.35, lvz), Vector3(0.3, 0.7, 0.3))
	R.reserve(lvx, lvz, 0.5, 0.5)
	var levier: Node3D = I._node(M, R.P(lvx, 0.72, lvz), -90.0 * s)
	var laiton := _mat(Color(0.88, 0.68, 0.3), 0.9, 0.3)
	var rouge := _mat(Color(0.78, 0.12, 0.1), 0.2, 0.45)
	_p(levier, I._cyl(0.01, 0.01, 0.28, 8), laiton, Vector3(0, 0.14, 0))
	_p(levier, I._sph(0.03), rouge, Vector3(0, 0.29, 0))
	levier.rotation.x = -0.4
	_sans_ombre(levier)
	# le tunnel de carton (une voûte de sept plaques), au fond ; il se soulève
	var qt: Vector2 = pt.call(th_t)
	var tg_t: Vector2 = Vector2(-a * sin(th_t), b * cos(th_t))
	var tunnel: Node3D = I._node(M, R.P(qt.x, 0.0, qt.y), rad_to_deg(atan2(tg_t.x, tg_t.y)))
	var carton := _mat(Color(0.66, 0.5, 0.32), 0.0, 0.95)
	var carton2 := _mat(Color(0.45, 0.55, 0.3), 0.0, 0.95)
	for k2 in range(7):
		var ang: float = PI * k2 / 6.0
		_p(tunnel, I._boxm(Vector3(0.085, 0.012, 0.7)), carton if k2 % 2 == 0 else carton2, Vector3(cos(ang) * 0.15, sin(ang) * 0.15, 0), Vector3.ONE, Vector3(0, 0, ang - PI * 0.5))
	for sz2 in [-0.35, 0.35]:
		_p(tunnel, I._boxm(Vector3(0.06, 0.2, 0.02)), carton, Vector3(-0.19, 0.1, float(sz2)))
		_p(tunnel, I._boxm(Vector3(0.06, 0.2, 0.02)), carton, Vector3(0.19, 0.1, float(sz2)))
	var tunnel_y: float = tunnel.position.y
	# le passage à niveau : la route grise, deux poteaux, deux barrières rayées, deux feux rouges
	var qpn: Vector2 = pt.call(th_p)
	var tg_p: Vector2 = Vector2(-a * sin(th_p), b * cos(th_p)).normalized()
	var np: Vector2 = Vector2(0.0, 1.0)
	R.kit.box(R.L(qpn.x, 0.005, qpn.y), Vector3(0.18, 0.006, 0.62), "st_route", 1.0)
	var feu_m := _mat(Color(1.0, 0.15, 0.1), 0.0, 0.4, 0.3)
	var bras: Array = []
	var blanc := _mat(Color(0.95, 0.95, 0.92), 0.0, 0.5)
	for sd2 in [-1.0, 1.0]:
		var bp: Vector2 = qpn + np * 0.2 * float(sd2) + tg_p * 0.11 * float(sd2)
		R.kit.cyl(R.L(bp.x, 0.0, bp.y), 0.008, 0.008, 0.12, "fer", 6, false)
		R.kit.box(R.L(bp.x, 0.115, bp.y), Vector3(0.02, 0.02, 0.02), "noir", 1.0)
		var feu: MeshInstance3D = _p(M.room, I._sph(0.009), feu_m, Vector3.ZERO)
		feu.global_position = R.P(bp.x, 0.135, bp.y)
		var dirb: Vector2 = -tg_p * float(sd2)
		var bn: Node3D = I._node(M, R.P(bp.x, 0.1, bp.y), rad_to_deg(atan2(-dirb.y, dirb.x)))
		var arm := Node3D.new()
		bn.add_child(arm)
		for k3 in range(4):
			_p(arm, I._boxm(Vector3(0.045, 0.01, 0.01)), rouge if k3 % 2 == 0 else blanc, Vector3(0.025 + k3 * 0.045, 0, 0))
		arm.rotation.z = 1.35
		bras.append(arm)
	# --- le train : la locomotive verte et laiton (son tender, son charbon), deux voitures
	var vert := _mat(Color(0.12, 0.38, 0.24), 0.3, 0.45)
	var noir := _mat(Color(0.06, 0.06, 0.07), 0.4, 0.5)
	var vitre_m := _mat(Color(1.0, 0.85, 0.5), 0.0, 0.4, 2.2 if nuit else 0.4)
	var loco := Node3D.new()
	M.room.add_child(loco)
	_p(loco, I._boxm(Vector3(0.1, 0.02, 0.3)), noir, Vector3(0, 0.04, 0.0))
	_p(loco, I._cyl(0.042, 0.042, 0.17, 14), vert, Vector3(0, 0.085, 0.055), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_p(loco, I._cyl(0.044, 0.044, 0.03, 14), noir, Vector3(0, 0.085, 0.15), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	for zb in [0.0, 0.1]:
		_p(loco, I._cyl(0.045, 0.045, 0.008, 14), laiton, Vector3(0, 0.085, float(zb)), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_p(loco, I._cyl(0.022, 0.014, 0.06, 10), noir, Vector3(0, 0.15, 0.13))
	_p(loco, I._sph(0.022), laiton, Vector3(0, 0.128, 0.05))
	_p(loco, I._boxm(Vector3(0.11, 0.1, 0.08)), vert, Vector3(0, 0.1, -0.07))
	_p(loco, I._boxm(Vector3(0.13, 0.012, 0.1)), noir, Vector3(0, 0.155, -0.07))
	for sx in [-1.0, 1.0]:
		_p(loco, I._boxm(Vector3(0.004, 0.03, 0.04)), vitre_m, Vector3(sx * 0.056, 0.115, -0.07))
	_p(loco, I._boxm(Vector3(0.1, 0.06, 0.09)), vert, Vector3(0, 0.07, -0.17))
	var charbon: MeshInstance3D = _p(loco, I._boxm(Vector3(0.085, 0.02, 0.075)), noir, Vector3(0, 0.105, -0.17))
	charbon.visible = false
	_p(loco, I._sph(0.01), _mat(Color(1.0, 0.9, 0.6), 0.0, 0.3, 2.0), Vector3(0, 0.06, 0.17))
	_p(loco, I._boxm(Vector3(0.1, 0.015, 0.01)), rouge, Vector3(0, 0.045, 0.155))
	var roues: Array = []
	for zr in [-0.17, -0.07, 0.03, 0.11]:
		for sx2 in [-1.0, 1.0]:
			roues.append(_p(loco, I._cyl(0.024, 0.024, 0.012, 12), rouge, Vector3(float(sx2) * 0.056, 0.025, float(zr)), Vector3.ONE, Vector3(0, 0, PI * 0.5)))
	_sans_ombre(loco)
	var wagons: Array = []
	var wcols: Array = [Color(0.66, 0.14, 0.12), Color(0.16, 0.28, 0.58)]
	for w in range(2):
		var wn := Node3D.new()
		M.room.add_child(wn)
		var cm := _mat(wcols[w], 0.2, 0.5)
		_p(wn, I._boxm(Vector3(0.1, 0.02, 0.2)), noir, Vector3(0, 0.04, 0))
		_p(wn, I._boxm(Vector3(0.1, 0.075, 0.19)), cm, Vector3(0, 0.085, 0))
		_p(wn, I._boxm(Vector3(0.115, 0.012, 0.205)), noir, Vector3(0, 0.128, 0))
		for sx3 in [-1.0, 1.0]:
			for zf in [-0.055, 0.0, 0.055]:
				_p(wn, I._boxm(Vector3(0.004, 0.03, 0.035)), vitre_m, Vector3(float(sx3) * 0.051, 0.095, float(zf)))
			for zr2 in [-0.06, 0.06]:
				roues.append(_p(wn, I._cyl(0.022, 0.022, 0.012, 12), noir, Vector3(float(sx3) * 0.056, 0.024, float(zr2)), Vector3.ONE, Vector3(0, 0, PI * 0.5)))
		_sans_ombre(wn)
		wagons.append([wn, 0.37 + 0.24 * w])
	var fumee: CPUParticles3D = _train_fumee(M)
	var th_cache: float = th_t + 0.12 / float(sp.call(th_t))
	# --- les gens : le parent ajuste un rail, l'enfant fait « tchou-tchou » devant, l'ancien lit le
	# journal du Petit Train ; la nuit, l'enfant dort sur un matelas près de la voie
	var parent: Node
	var kid: Node
	var role_a: String = str(_pick(M, ["vieux", "vieille"]))
	var ancien: Node = M.person(role_a, gx, gz, gyaw, "dormir_assis" if nuit else "lire")
	var cote_porte: float = -1.0 if R.door_x > 0.0 else 1.0
	if nuit:
		var mx: float = -s * (hw - 0.5)
		R.kit.box(R.L(mx, 0.05, tcz), Vector3(0.6, 0.1, 1.45), "drap", 1.0)
		R.kit.box(R.L(mx, 0.11, tcz + 0.2), Vector3(0.62, 0.03, 0.95), "tissu_bleu", 1.0)
		R.kit.box(R.L(mx, 0.13, tcz - 0.55), Vector3(0.4, 0.07, 0.22), "tissu_blanc", 1.0)
		R.reserve(mx, tcz, 0.8, 1.6)
		kid = M.person("garcon" if boy else "fille", mx, tcz, 0.0, "dormir")
		kid.lie(R.P(mx, 0.1, tcz + 0.6), Vector3(0, 0, -1))
		kid.lines = ["Zzz…", "Zzz… tchou… tchou… zzz…", "Mmh… Petite Bernadette… attends-moi… zzz…"]
		kid.line_every = Vector2(9.0, 14.0)
		var pp: Vector2 = _dedans(M, cote_porte * minf(a * 0.7, hw - 0.7), hd - 1.6)
		parent = M.person(str(_pick(M, ["homme", "femme"])), pp.x, pp.y, _vers(pp.x, pp.y, mx, tcz), "mains_dos")
		parent.lines = ["Chut… le petit chef de gare dort." if boy else "Chut… la petite cheffe de gare dort.", "Dernier tour, tout doucement.", "Les wagons éclairés, la nuit… comme la vraie Bernadette."]
		parent.line_every = Vector2(10.0, 15.0)
		ancien.lines = ["Zzz…", "Zzz… en voiture… zzz…"]
	else:
		var px: float = -s * (hw - 0.6)
		var pz: float = tcz - 0.25
		parent = M.person(str(_pick(M, ["homme", "femme"])), px, pz, _vers(px, pz, 0.0, tcz), "bricoler")
		parent.lines = ["Encore un rail qui se décolle…", "Qui a mis une chaussette dans le tunnel ?", "Papy Ferdinand vient l'inspecter dimanche. Il faut que tout brille.", "Attention au passage à niveau !"]
		parent.line_every = Vector2(8.0, 13.0)
		var kp: Vector2 = _dedans(M, cote_porte * minf(a * 0.75, hw - 0.6), hd - 1.6)
		kid = M.person("garcon" if boy else "fille", kp.x, kp.y, _vers(kp.x, kp.y, 0.0, tcz), "debout")
		kid.lines = ["Tchou-tchou !", "Attention, le train arrive ! Ding-ding-ding !", "En voiture ! C'est Papy Ferdinand qui dit ça.", "Plus vite, Petite Bernadette !", "Le terminus, c'est le tapis !"]
		kid.line_every = Vector2(5.0, 9.0)
		ancien.lines = ["Vingt minutes le tour, comme la vraie… Non : quarante secondes.", "De mon temps, les trains étaient en bois. Et nous aussi, presque.", "Le journal dit que Bernadette a cent ans. Moi aussi, demain."]
	ancien.line_every = Vector2(9.0, 14.0)
	var st := {"t": 0.0, "th": th_g if nuit else th_cache, "v": 0.0, "vite": 0.0, "cache": not nuit, "fume": 0.0, "charger": false, "arret": 0.0,
		"tours": 0, "bar": 1.35, "ferme": false, "lev": false, "tunnel": false, "roue": 0.0}
	var poser := func(n: Node3D, th: float) -> void:
		var q: Vector2 = pt.call(th)
		var tg: Vector2 = Vector2(-a * sin(th), b * cos(th))
		n.global_transform = Transform3D(Basis(Vector3.UP, atan2(tg.x, tg.y)), R.P(q.x, 0.028, q.y))
	var passe := func(prev: float, nouv: float, x: float) -> bool:
		var dn: float = fposmod(nouv - prev, TAU)
		var dx: float = fposmod(x - prev, TAU)
		return dx > 0.0 and dx <= dn and dn < PI
	# la récompense (une seule fois) : le train file à toute vapeur, en fumant
	var recompense := func() -> void:
		M.bonne_action_v120()  ## V120 : une bonne action, l'île s'en souvient
		if bool(M.state().get("st_train", false)):
			return
		M.state()["st_train"] = true
		var txt: String = "Chut… À toute vapeur, et en pleine nuit ! Papy Ferdinand dit que celui qui fait rouler Bernadette à toute vapeur a droit à une galette des Rouages. Ici, c'est pareil. Tiens, tout bas." if nuit else "À toute vapeur, avec la fumée et tout ! Papy Ferdinand dit que celui qui fait rouler Bernadette à toute vapeur a droit à une galette des Rouages. Ici, c'est pareil. Tiens !"
		M.talk(parent, txt, I._bye("Merci ! Tchou-tchou !"), func(_i):
			M.give([["galette_rouages", 1]], "")
			M.close_talk(), "à voix basse" if nuit else "enthousiaste")
	# --- ce qui bouge : le train (sa vitesse, ses arrêts, sa cachette, la trémie), ses roues, sa fumée,
	# les barrières et les feux du passage à niveau
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(loco):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		st["vite"] = maxf(0.0, float(st["vite"]) - dt)
		st["arret"] = maxf(0.0, float(st["arret"]) - dt)
		st["fume"] = maxf(0.0, float(st["fume"]) - dt)
		var cible: float = 0.1 if nuit else 0.26
		if float(st["vite"]) > 0.0:
			cible = 0.3 if nuit else 0.72
		if bool(st["cache"]) or float(st["arret"]) > 0.0:
			cible = 0.0
		var v: float = move_toward(float(st["v"]), cible, dt * 0.6)
		st["v"] = v
		var th0: float = float(st["th"])
		var th: float = fposmod(th0 + v * dt / float(sp.call(th0)), TAU)
		# il passe le tunnel : de temps en temps, il s'y cache et boude
		if bool(passe.call(th0, th, th_cache)):
			st["tours"] = int(st["tours"]) + 1
			if not nuit and float(st["vite"]) <= 0.0 and int(st["tours"]) % 3 == 0:
				st["cache"] = true
				th = th_cache
				st["v"] = 0.0
				kid.say(str(_pick(M, ["Oh non, il boude encore dans le tunnel !", "Il se cache ! Mais on voit son wagon qui dépasse !", "Petite Bernadette, sors de là !"])), 3.0)
		# la trémie : s'il y a du charbon, il s'arrête dessous et fait le plein
		if bool(st["charger"]) and bool(passe.call(th0, th, th_c)):
			st["charger"] = false
			st["arret"] = 1.6
			th = th_c
			st["v"] = 0.0
			charbon.visible = true
			st["fume"] = 24.0
			var hp3: Vector3 = R.P(hp.x, 0.25, hp.y)
			M.main.sfx("ramasse_pierre", hp3, -10.0)
			_bulle(M, hp3 + Vector3(0, 0.15, 0), "Gling, gling, gling !", Color(1.0, 0.92, 0.7), 32, 0.35, 1.5)
			S._say_late(M, kid if not nuit else parent, "Il fait le plein ! Regarde, il fume !" if not nuit else "Chut… le plein, tout doucement.", 1.0)
			M.main.sfx("vapeur", hp3, -10.0 if not nuit else -18.0)
		st["th"] = th
		poser.call(loco, th)
		for e in wagons:
			var lag: float = float(e[1])
			poser.call(e[0], fposmod(th - lag / float(sp.call(th)), TAU))
		st["roue"] = float(st["roue"]) + v * dt / 0.024
		for rw in roues:
			(rw as Node3D).rotation = Vector3(float(st["roue"]), 0, PI * 0.5)
		# la fumée sort de la cheminée tant qu'il reste du charbon
		fumee.global_position = loco.global_transform * Vector3(0, 0.19, 0.13)
		fumee.emitting = float(st["fume"]) > 0.0
		if float(st["fume"]) <= 0.0:
			charbon.visible = false
		# le passage à niveau : les barrières se baissent quand le train approche, les feux clignotent
		var avant: float = wrapf(th_p - th, -PI, PI) * float(sp.call(th_p))
		var ferme: bool = avant < 0.6 and avant > -0.8 and v > 0.01
		if ferme and not bool(st["ferme"]):
			M.main.sfx("clochette", R.P(qpn.x, 0.1, qpn.y), -18.0 if nuit else -12.0)
		st["ferme"] = ferme
		st["bar"] = move_toward(float(st["bar"]), 0.0 if ferme else 1.35, dt * 2.5)
		for arm2 in bras:
			(arm2 as Node3D).rotation.z = float(st["bar"])
		feu_m.emission_energy_multiplier = 3.0 if ferme and fmod(t, 0.8) < 0.4 else 0.3
	poser.call(loco, float(st["th"]))
	# --- pousser le levier : le train accélère et siffle (avec du charbon : à toute vapeur)
	var pousser := func() -> void:
		if bool(st["lev"]):
			return
		st["lev"] = true
		var tw: Tween = M.room.create_tween()
		tw.tween_property(levier, "rotation:x", 0.45, 0.2)
		tw.tween_interval(1.2)
		tw.tween_property(levier, "rotation:x", -0.4, 0.4)
		tw.tween_callback(func() -> void:
			st["lev"] = false)
		M.main.sfx("levier", levier.global_position)
		if bool(st["cache"]):
			if nuit:
				parent.say("Chut… il dort dans son tunnel, lui aussi.", 3.0)
			else:
				kid.say(str(_pick(M, ["Il boude dans le tunnel ! Il faut aller le chercher !", "Ça ne marche pas : il est caché ! Soulève le tunnel !"])), 3.0)
			return
		st["vite"] = 4.0 if nuit else 6.0
		var lp: Vector3 = loco.global_position + Vector3(0, 0.3, 0)
		M.main.sfx("sifflet_compagnons", lp, -18.0 if nuit else -4.0)
		_bulle(M, lp, "Tchou… (tout bas)" if nuit else "Tchouuuuu !", Color(1.0, 0.95, 0.8), 34 if nuit else 46, 0.5, 1.8)
		if nuit:
			parent.say("Chut… Un petit tour, alors. Tout doucement.", 3.0)
			S._say_late(M, kid, "Zzz… tchou-tchou… zzz…", 2.0)
		else:
			kid.gesture("joie", 2.0)
			kid.say(str(_pick(M, ["Plus vite ! Plus viiite !", "Tchou-tchou ! Attention au virage !", "Elle siffle comme la vraie !"])), 3.0)
		if float(st["fume"]) > 0.0:
			if bool(M.state().get("st_train", false)):
				if not nuit:
					S._say_late(M, parent, str(_pick(M, ["À toute vapeur ! Papy Ferdinand serait fier.", "Regarde-la filer ! On dirait Bernadette un jour de fête.", "Doucement dans les virages !"])), 1.5)
				return
			await M.get_tree().create_timer(3.0).timeout
			if not _la(M, room0):
				return
			recompense.call()
		elif not nuit:
			S._say_late(M, parent, str(_pick(M, ["Sans charbon, elle ne fait que siffler ! Verse le seau dans la trémie, là-bas.", "Pour la grande vitesse, il lui faut du charbon. Le seau est près de la petite gare."])), 1.6)
	# --- remplir le tender : on verse le seau dans la trémie ; au passage suivant, il fait le plein
	var remplir := func() -> void:
		if bool(st["charger"]) or float(st["fume"]) > 3.0:
			M.say("La trémie est pleine, et le tender aussi. Même une petite locomotive ne mange pas deux fois de suite.", 4.0)
			return
		st["charger"] = true
		var sp3: Vector3 = R.P(hp.x, 0.3, hp.y)
		M.main.sfx("ramasse_pierre", sp3, -6.0)
		_bulle(M, sp3 + Vector3(0, 0.2, 0), "Une pelletée !", Color(1.0, 0.92, 0.7), 36, 0.4, 1.5)
		if bool(st["cache"]):
			M.say("Tu verses des grains de charbon, gros comme des grains de café, dans la trémie de la petite gare. Le train fera le plein en passant… quand il sortira de son tunnel.", 5.0)
		else:
			M.say(str(_pick(M, ["Tu verses des grains de charbon, gros comme des grains de café, dans la trémie de la petite gare. Au prochain passage, le train fera le plein.",
				"Le seau se vide dans la trémie avec un joli bruit de grêle. Le charbon vient de la Grande Forge, en tout petits morceaux."])), 4.5)
		if nuit:
			parent.say("Juste une pelletée… et pas de bruit.", 3.0)
		else:
			kid.say(str(_pick(M, ["Il va fumer ! Il va fumer comme la vraie !", "Du charbon ! Elle va pouvoir aller à toute vapeur !"])), 3.0)
	# --- soulever le tunnel de carton : s'il s'y cachait, il ressort (« Coucou ! »)
	var soulever := func() -> void:
		if bool(st["tunnel"]):
			return
		st["tunnel"] = true
		M.main.sfx("touche_bois", tunnel.global_position, -6.0)
		var tw: Tween = M.room.create_tween()
		tw.tween_property(tunnel, "position:y", tunnel_y + 0.55, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if bool(st["cache"]):
			await M.get_tree().create_timer(0.6).timeout
			if not _la(M, room0):
				return
			_bulle(M, loco.global_position + Vector3(0, 0.3, 0), "Coucou !", Color(1.0, 0.95, 0.7), 42, 0.45, 1.6)
			M.main.sfx("sifflet_compagnons", loco.global_position, -18.0 if nuit else -10.0)
			st["cache"] = false
			st["vite"] = 1.5
			if nuit:
				parent.say("Chut… Il s'était caché pour dormir. Allez, un dernier tour.", 3.5)
			else:
				kid.gesture("joie", 2.0)
				kid.say(str(_pick(M, ["Trouvé ! Il était là !", "Coucou, Petite Bernadette ! Tu ne boudes plus ?", "Il repart ! Tchou-tchou !"])), 3.0)
		else:
			M.say(str(_pick(M, ["Personne dans le tunnel. Juste une araignée en papier, collée là pour faire peur au train. Elle n'a jamais fait peur à personne.",
				"Le tunnel est vide. Dessous, quelqu'un a écrit au crayon : « Ici, Petite Bernadette fait la sieste. »"])), 4.5)
		await M.get_tree().create_timer(2.0).timeout
		if not _la(M, room0):
			return
		var tw2: Tween = M.room.create_tween()
		tw2.tween_property(tunnel, "position:y", tunnel_y, 0.5).set_trans(Tween.TRANS_SINE)
		tw2.tween_callback(func() -> void:
			st["tunnel"] = false)
	M.act(R.P(lvx - s * 0.5, 0, lvz), "E : pousser le levier du petit train", pousser, 0.9, func(): return not bool(st["lev"]))
	M.act(R.P(seau.x, 0, seau.y), "E : remplir le tender (le seau de charbon)", remplir, 0.8)
	var nt: Vector2 = Vector2(0.0, -1.0)
	M.act(R.P(qt.x + nt.x * 0.5, 0, maxf(qt.y + nt.y * 0.5, -hd + 0.5)), "E : soulever le tunnel de carton", soulever, 0.9, func(): return not bool(st["tunnel"]))
	# --- les conversations
	var parent_cb := func() -> void:
		if nuit:
			M.talk(parent, "Chut… Le petit s'est endormi au bord de la voie, comme un vrai cheminot. Je fais faire un dernier tour au train de nuit : les wagons éclairés, c'est son moment préféré." if boy else "Chut… La petite s'est endormie au bord de la voie, comme une vraie cheminote. Je fais faire un dernier tour au train de nuit : les wagons éclairés, c'est son moment préféré.",
				[{"id": "pourquoi", "label": "Pourquoi un tour la nuit ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if id == "pourquoi":
					M.talk(parent, "Papy Ferdinand ramène toujours Bernadette au dépôt en lui racontant sa journée. Alors on fait pareil. Le train fait « pfff », et tout le monde s'endort.", I._bye("Pfff… Bonne nuit."), I._close(M), "à voix basse")
				else:
					M.close_talk()
			, "à voix basse")
			return
		M.talk(parent, str(_pick(M, ["Bonne descente ! Attention où vous mettez les pieds : la voie fait tout le tour du salon. Papy Ferdinand nous a aidés à la poser.",
			"Bonjour ! Vous tombez bien : on cherche un chef de gare. Le nôtre fait « tchou-tchou » toute la journée, mais il oublie de siffler les départs." if boy else "Bonjour ! Vous tombez bien : on cherche un chef de gare. La nôtre fait « tchou-tchou » toute la journée, mais elle oublie de siffler les départs."])),
			[{"id": "ferdinand", "label": "Vous connaissez Papy Ferdinand ?"}, {"id": "tunnel", "label": "Pourquoi le train se cache ?"}, {"id": "fermer", "label": "Bonne descente !"}], func(id):
			match id:
				"ferdinand":
					M.talk(parent, "Depuis toujours ! Il nous a donné les plans de Bernadette, en tout petit. La locomotive, c'est Brunehaut qui l'a forgée, à la Grande Forge, avec les chutes de laiton. Il vient l'inspecter tous les dimanches. Il dit qu'elle tient la route. Enfin, les rails.", I._bye("Ha ha !"), I._close(M), "enthousiaste")
				"tunnel":
					M.talk(parent, "Personne ne sait ! Elle s'arrête dans le tunnel, de temps en temps, et elle ne veut plus sortir. Papy Ferdinand dit que la vraie Bernadette faisait pareil, jeune. On soulève le tunnel, on lui dit coucou, et elle repart.", I._bye("Coucou, Bernadette !"), I._close(M), "enthousiaste")
				_:
					M.close_talk()
		, "enthousiaste")
	M.talk_spot(parent, parent_cb)
	var kid_cb := func() -> void:
		if nuit:
			M.talk(kid, "Zzz… prochain arrêt… le tapis… tout le monde descend… zzz…", I._bye("(Le laisser dormir)") if boy else I._bye("(La laisser dormir)"), I._close(M), "endormi" if boy else "endormie")
			return
		M.talk(kid, str(_pick(M, ["Tchou-tchou ! Tu as vu mon train ? Elle s'appelle Petite Bernadette. Comme la vraie, mais en petit.",
			"En voiture ! … Ah, tu es trop grand pour monter. Tant pis, tu peux regarder."])),
			[{"id": "plus_tard", "label": "Que veux-tu faire plus tard ?"}, {"id": "papy", "label": "Papy Ferdinand vient souvent ?"}, {"id": "fermer", "label": "Tchou-tchou !"}], func(id):
			match id:
				"plus_tard":
					M.talk(kid, "Conducteur du Petit Train, comme Papy Ferdinand ! Il dit que je dois d'abord apprendre à siffler, à huiler les roues et à arriver à l'heure. Moi, je sais déjà dire « En voiture ! »." if boy else "Conductrice du Petit Train, comme Papy Ferdinand ! Il dit que je dois d'abord apprendre à siffler, à huiler les roues et à arriver à l'heure. Moi, je sais déjà dire « En voiture ! ».", I._bye("C'est un bon début !"), I._close(M), "aux anges")
				"papy":
					M.talk(kid, "Tous les dimanches ! Il se met à quatre pattes, il regarde le train passer, et il dit « Elle siffle un peu ». Après, il mange trois galettes. Maman dit que c'est pour ça qu'il vient." if r.randf() < 0.5 else "Tous les dimanches ! Il se met à quatre pattes, il regarde le train passer, et il dit « Elle siffle un peu ». Après, il mange trois galettes. Papa dit que c'est pour ça qu'il vient.", I._bye("Ha ha !"), I._close(M), "aux anges")
				_:
					M.close_talk()
		, "aux anges")
	M.talk_spot(kid, kid_cb)
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Un petit train aux fenêtres éclairées fait le tour du salon, tout doucement. Au bord de la voie, un enfant dort sur un matelas.",
			"Il fait nuit. Sur le feutre vert, les petites maisons de carton dorment, et un train de nuit passe sans un bruit, ses wagons allumés comme des lanternes.",
			"Tout est calme. Seul un minuscule passage à niveau clignote dans le noir : « ding… ding… ». Un enfant ronfle à côté des rails."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["« Tchou-tchou ! » Une voie de train miniature fait le tour du salon… mais où est le train ? On voit dépasser un wagon d'un tunnel de carton.",
			"Un village de carton, une petite gare, un passage à niveau, et des rails tout autour de la pièce. Le train ? Il boude dans son tunnel, paraît-il.",
			"Ici, on ne marche pas n'importe où : une voie de train fait tout le tour du salon. Un enfant crie « Tchou-tchou ! », mais le train se cache."]))


# =================================================================== la collection de cristaux

## (écrite à part)
# =================================================================== la collection de cristaux

## Les cinq cristaux chanteurs du présentoir, du plus grave (chant_0) au plus aigu (chant_4) : Bleuet,
## Grenadine, Mirabelle, Menthe et Pipelette (le violet, le bavard : celui qui se perd).
const CRISTAUX_CHANTEURS := [Color(0.35, 0.62, 1.0), Color(1.0, 0.36, 0.48), Color(1.0, 0.84, 0.3), Color(0.38, 1.0, 0.58), Color(0.74, 0.46, 1.0)]

## Les couleurs de la collection (vitrine, étagère, caisse) : une matière partagée par couleur
## ("stc_0"…), qui pulse doucement pour tous les cristaux de cette couleur à la fois.
const CRISTAUX_COULEURS := [Color(0.35, 0.62, 1.0), Color(1.0, 0.36, 0.48), Color(1.0, 0.84, 0.3), Color(0.38, 1.0, 0.58),
	Color(0.74, 0.46, 1.0), Color(1.0, 0.6, 0.25), Color(0.82, 0.94, 1.0)]

## Les petites mélodies (des chanteurs, de 0 à 4) : la dernière note est toujours celle de Pipelette
## (tant qu'il est perdu, la chanson tombe dans un trou).
const CRISTAUX_AIRS := [[0, 2, 1, 4], [2, 0, 3, 4], [1, 3, 2, 4], [3, 1, 0, 4], [0, 1, 3, 4]]


## Un petit groupe de cristaux qui reste (R.kit : trois à cinq prismes à six pans et leurs pointes,
## sur un caillou) et son étiquette de papier ; xf : le pied du groupe (y vers le haut, +z vers nous) ;
## key : la matière ("stc_0"…).
static func _cristaux_groupe(M, xf: Transform3D, key: String, s: float = 1.0, etiquette: bool = true) -> void:
	var R = M.R
	var r := _r(M)
	R.kit.box(xf * Transform3D(Basis(), Vector3(0, 0.012 * s, 0)), Vector3(0.09, 0.025, 0.07) * s, "pierre", 1.0)
	var n: int = r.randi_range(3, 5)
	for k in range(n):
		var a: float = TAU * k / n + r.randf()
		var tilt: float = 0.0 if k == 0 else r.randf_range(0.2, 0.55)
		var rr: float = r.randf_range(0.009, 0.015) * s * (1.4 if k == 0 else 1.0)
		var h: float = r.randf_range(0.05, 0.085) * s * (1.5 if k == 0 else 1.0)
		var off: Vector3 = Vector3(cos(a), 0, sin(a)) * (0.0 if k == 0 else 0.016 * s)
		var px: Transform3D = xf * Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, tilt), off + Vector3(0, 0.018 * s, 0))
		R.kit.cyl(px, rr, rr, h, key, 6, false)
		R.kit.cyl(px * Transform3D(Basis(), Vector3(0, h, 0)), rr, 0.0, rr * 2.2, key, 6, false)
	if etiquette:
		var et: Transform3D = xf * Transform3D(Basis(Vector3.RIGHT, -0.6), Vector3(0, 0.014, 0.05 * s + 0.025))
		R.kit.box(et, Vector3(0.05, 0.002, 0.026), "papier", 1.0)
		R.kit.box(et * Transform3D(Basis(), Vector3(0, 0.0015, 0)), Vector3(0.032, 0.001, 0.003), "noir", 1.0)


## Un cristal chanteur qui bouge (quatre prismes à six pans et leurs pointes, d'une matière à lui :
## il s'allume quand il chante) ; at : son pied (monde).
static func _cristaux_chanteur(M, at: Vector3, m: Material) -> Node3D:
	var n: Node3D = I._node(M, at, 0)
	for e in [[Vector3.ZERO, 0.032, 0.22, 0.0, 0.0], [Vector3(0.035, 0, 0.01), 0.022, 0.15, 0.0, -0.35],
			[Vector3(-0.032, 0, 0.012), 0.02, 0.13, 0.0, 0.4], [Vector3(0.0, 0, -0.03), 0.018, 0.11, -0.38, 0.0]]:
		var piv := Node3D.new()
		n.add_child(piv)
		piv.position = e[0]
		piv.rotation = Vector3(float(e[3]), 0, float(e[4]))
		var rr: float = float(e[1])
		var h: float = float(e[2])
		_p(piv, I._cyl(rr, rr, h, 6), m, Vector3(0, h * 0.5, 0))
		_p(piv, I._cyl(0.0, rr, rr * 2.4, 6), m, Vector3(0, h + rr * 1.2, 0))
	_sans_ombre(n)
	return n


## La collection de cristaux (une maison des Strates) : un enfant collectionne les cristaux de la
## mine. Au fond, une grande vitrine pleine de petits groupes de cristaux de toutes les couleurs, une
## étagère et une caisse de « pas-encore-classés », chacun son étiquette ; devant la vitrine, le
## présentoir des cinq chanteurs (chacun sa note et sa couleur) ; le parent, mineur ou mineuse, les
## classe à sa table (la loupe, les plateaux, le carnet). Tout pulse doucement. On fait chanter les
## cristaux (une petite mélodie, ils s'allument l'un après l'autre… et il manque la dernière note) ;
## on lit le carnet de la collection ; on cherche le cristal perdu, Pipelette, qui fredonne quelque
## part (sous le lit, dans la poche du manteau du parent ou dans la soupe : selon la maison) ; retrouvé,
## il revole à sa place, l'enfant est fou de joie et donne un de ses deux éclats jumeaux (une fois).
## La nuit, l'enfant dort, les cristaux veillent tout bas, la veilleuse luit, le parent chuchote.
static func _cristaux(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var room0 = M.room
	var nuit: bool = _nuit(M)
	# le mur du fond n'a une fenêtre (en x = -W/4) que dans les grandes pièces : on ne retourne la
	# pièce (s = -1) que dans les petites
	var s: float = 1.0 if (R.W > 7.5 or r.randf() < 0.5) else -1.0
	var boy: bool = r.randf() < 0.5
	var pere: bool = r.randf() < 0.5
	var cache: int = r.randi() % 3
	var deja: bool = bool(M.state().get("st_cristaux", false))
	var n_total: int = r.randi_range(140, 320)
	var n_faux: int = r.randi_range(3, 17)
	# les matières de la collection (une par couleur), partagées : le tick les fait pulser
	var mats: Array = []
	for i in range(CRISTAUX_COULEURS.size()):
		var mc: StandardMaterial3D = _verre(CRISTAUX_COULEURS[i], 0.82, 1.0)
		mc.roughness = 0.08
		R._put("stc_%d" % i, mc)
		mats.append(mc)
	# --- la grande vitrine, contre le mur du fond : le meuble bas, les montants de bois sombre, les
	# tablettes et la façade de verre, un liseré de laiton ; trois rangées de groupes de cristaux
	var vx: float = s * R.W * 0.1
	var vw: float = 2.2
	var vh: float = 1.85
	var vd: float = 0.42
	var vz: float = -hd + vd * 0.5 + 0.02
	R.kit.box(R.L(vx, 0.3, vz), Vector3(vw, 0.6, vd), "bois_sombre", 1.0)
	R.kit.box(R.L(vx, 0.61, vz), Vector3(vw + 0.04, 0.03, vd + 0.04), "bois", 1.0)
	for sx in [-1.0, 1.0]:
		R.kit.box(R.L(vx + sx * vw * 0.25, 0.3, vz + vd * 0.5 + 0.006), Vector3(vw * 0.46, 0.48, 0.012), "bois", 1.0)
		R.kit.cyl(R.L(vx + sx * 0.08, 0.32, vz + vd * 0.5 + 0.012) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.018, 0.018, 0.03, "or", 8)
		for sz in [-1.0, 1.0]:
			R.kit.box(R.L(vx + sx * (vw * 0.5 - 0.025), 1.235, vz + sz * (vd * 0.5 - 0.025)), Vector3(0.05, 1.23, 0.05), "bois_sombre", 1.0)
		R.kit.box(R.L(vx + sx * (vw * 0.5 - 0.02), 1.235, vz), Vector3(0.006, 1.2, vd - 0.06), "verre", 1.0)
	R.kit.box(R.L(vx, 1.235, -hd + 0.03), Vector3(vw, 1.23, 0.02), "bois_sombre", 1.0)
	R.kit.box(R.L(vx, vh + 0.025, vz), Vector3(vw + 0.06, 0.05, vd + 0.06), "bois_sombre", 1.0)
	R.kit.box(R.L(vx, vh - 0.01, vz + vd * 0.5 + 0.02), Vector3(vw + 0.02, 0.025, 0.012), "or", 1.0)
	for ty in [1.02, 1.42]:
		R.kit.box(R.L(vx, ty, vz), Vector3(vw - 0.08, 0.012, vd - 0.06), "verre", 1.0)
	R.kit.box(R.L(vx, 1.235, vz + vd * 0.5 - 0.01), Vector3(vw - 0.08, 1.2, 0.006), "verre", 1.0)
	R.kit.box(R.L(vx, 1.235, vz + vd * 0.5), Vector3(0.02, 1.2, 0.015), "or", 1.0)
	for ly in [0.625, 1.026, 1.426]:
		for k in range(5):
			var gx: float = vx - vw * 0.4 + k * vw * 0.2 + r.randf_range(-0.04, 0.04)
			_cristaux_groupe(M, R.L(gx, ly, vz + 0.01, r.randf_range(-20.0, 20.0)), "stc_%d" % (r.randi() % CRISTAUX_COULEURS.size()), r.randf_range(0.85, 1.25))
	R.kit.col_box(R.L(vx, vh * 0.5, vz), Vector3(vw, vh, vd))
	R.reserve(vx, vz, vw + 0.2, vd + 0.3)
	R.mark_wall(vx, 1.2, -hd, vw * 0.5 + 0.1)
	var lum_v := OmniLight3D.new()
	lum_v.light_color = Color(0.72, 0.8, 1.0)
	lum_v.omni_range = 2.4
	lum_v.light_energy = 0.4
	lum_v.shadow_enabled = false
	M.room.add_child(lum_v)
	lum_v.global_position = R.P(vx, 1.3, vz + 0.5)
	# --- le poêle, dans le coin du fond ; sur le poêle, la marmite de soupe et sa louche
	var px: float = s * (hw - 0.8)
	var pz: float = -hd + 0.6
	R.foyer(px, pz, 0, true)
	R.mark_wall(px, 1.5, -hd, 0.5)
	var mx: float = px - 0.13
	var mz: float = pz + 0.02
	R.kit.cyl(R.L(mx, 0.91, mz), 0.13, 0.14, 0.17, "fer", 14, false)
	R.kit.cyl(R.L(mx, 0.912, mz), 0.13, 0.13, 0.01, "fer", 14)
	R.kit.cyl(R.L(mx, 1.04, mz), 0.13, 0.13, 0.01, "soupe", 14)
	R.kit.ring(R.L(mx, 1.07, mz), 0.13, 0.15, 0.02, "fer", 14)
	for sx2 in [-1.0, 1.0]:
		R.kit.box(R.L(mx + sx2 * 0.16, 1.03, mz), Vector3(0.04, 0.02, 0.05), "fer", 1.0)
	R.kit.cyl(R.L(mx + 0.05, 1.04, mz - 0.04) * Transform3D(Basis(Vector3.BACK, -0.45), Vector3.ZERO), 0.008, 0.008, 0.26, "argent", 6)
	# --- le présentoir des chanteurs, devant la vitrine : cinq socles de laiton, cinq étiquettes
	var bw: float = 1.9
	var prz: float = -hd + 1.3
	R.kit.box(R.L(vx, 0.35, prz), Vector3(bw, 0.7, 0.42), "bois", 1.0)
	R.kit.box(R.L(vx, 0.715, prz), Vector3(bw + 0.06, 0.03, 0.48), "bois_sombre", 1.0)
	R.kit.box(R.L(vx, 0.69, prz + 0.216), Vector3(bw, 0.025, 0.012), "or", 1.0)
	R.kit.col_box(R.L(vx, 0.36, prz), Vector3(bw, 0.72, 0.42))
	R.reserve(vx, prz, bw + 0.2, 0.7)
	var slots: Array = []
	for i2 in range(5):
		var sxp: float = vx + (i2 - 2) * 0.36
		R.kit.cyl(R.L(sxp, 0.73, prz), 0.07, 0.06, 0.03, "or", 12)
		var et: Transform3D = R.L(sxp, 0.735, prz + 0.15) * Transform3D(Basis(Vector3.RIGHT, -0.6), Vector3.ZERO)
		R.kit.box(et, Vector3(0.08, 0.002, 0.04), "papier", 1.0)
		R.kit.box(et * Transform3D(Basis(), Vector3(0, 0.0015, 0)), Vector3(0.05, 0.001, 0.004), "noir", 1.0)
		slots.append(R.P(sxp, 0.76, prz))
	# --- le lit de l'enfant contre le mur d'en face, la table de nuit et sa veilleuse (une lanterne à
	# cristal de laiton et de verre, un cristal blanc-bleu dedans)
	var lx: float = -s * (hw - 1.06)
	var lz: float = 0.0
	R.lit(lx, lz, 90.0 * s, 1.0, str(_pick(M, ["bleu", "violet", "vert", "jaune"])))
	R.mark_wall(-s * hw, 1.0, lz, 0.6)
	var tnx: float = -s * (hw - 0.3)
	var tnz: float = lz - 0.85
	R.kit.box(R.L(tnx, 0.25, tnz), Vector3(0.4, 0.5, 0.38), "bois_sombre", 1.0)
	R.kit.box(R.L(tnx, 0.515, tnz), Vector3(0.44, 0.03, 0.42), "bois", 1.0)
	R.kit.col_box(R.L(tnx, 0.26, tnz), Vector3(0.4, 0.52, 0.38))
	R.reserve(tnx, tnz, 0.5, 0.5)
	R.kit.cyl(R.L(tnx, 0.53, tnz), 0.075, 0.075, 0.02, "or", 12)
	R.kit.cyl(R.L(tnx, 0.55, tnz), 0.06, 0.06, 0.17, "verre", 12, false)
	for k2 in range(4):
		var a2: float = TAU * k2 / 4.0 + 0.4
		R.kit.box(R.L(tnx + cos(a2) * 0.062, 0.635, tnz + sin(a2) * 0.062), Vector3(0.01, 0.17, 0.01), "or", 1.0)
	R.kit.cyl(R.L(tnx, 0.72, tnz), 0.075, 0.02, 0.05, "or", 12)
	R.kit.ring(R.L(tnx, 0.77, tnz) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.025, 0.035, 0.006, "or", 12)
	var vmat: StandardMaterial3D = _verre(Color(0.78, 0.9, 1.0), 0.85, 2.0)
	var veilleuse: Node3D = _cristaux_chanteur(M, R.P(tnx, 0.56, tnz), vmat)
	veilleuse.scale = Vector3.ONE * 0.6
	var lum_n := OmniLight3D.new()
	lum_n.light_color = Color(0.62, 0.78, 1.0)
	lum_n.omni_range = 2.6
	lum_n.light_energy = 0.7 if nuit else 0.15
	lum_n.shadow_enabled = false
	M.room.add_child(lum_n)
	lum_n.global_position = R.P(tnx + s * 0.15, 0.85, tnz)
	# --- le portemanteau, dans le coin du fond : le gros manteau de mineur (une poche bien large)
	# et le casque à lampe
	var cx: float = -s * (hw - 0.45)
	var cz: float = -hd + 0.55
	R.kit.cyl(R.L(cx, 0, cz), 0.025, 0.02, 1.85, "bois_sombre", 8)
	for k3 in range(3):
		var a3: float = TAU * k3 / 3.0 + 0.3
		R.kit.box(R.L(cx + cos(a3) * 0.13, 0.03, cz + sin(a3) * 0.13, -rad_to_deg(a3)), Vector3(0.28, 0.05, 0.04), "bois_sombre", 1.0)
	R.kit.box(R.L(cx + s * 0.06, 1.2, cz), Vector3(0.16, 0.82, 0.48), "tissu_brun", 1.0)
	R.kit.box(R.L(cx + s * 0.05, 1.64, cz), Vector3(0.12, 0.1, 0.22), "tissu_brun", 1.0)
	R.kit.box(R.L(cx + s * 0.145, 0.92, cz + 0.09), Vector3(0.03, 0.15, 0.16), "cuir", 1.0)
	R.kit.box(R.L(cx + s * 0.145, 1.2, cz), Vector3(0.012, 0.75, 0.02), "cuir", 1.0)
	R.kit.cyl(R.L(cx, 1.84, cz), 0.13, 0.1, 0.1, "cuivre", 14)
	R.kit.ring(R.L(cx, 1.84, cz), 0.12, 0.16, 0.012, "cuivre", 14)
	R.kit.cyl(R.L(cx + s * 0.12, 1.885, cz) * Transform3D(Basis(Vector3.BACK, -PI * 0.5 * s), Vector3.ZERO), 0.03, 0.03, 0.03, "lumiere", 10)
	R.kit.col_box(R.L(cx, 0.9, cz), Vector3(0.3, 1.8, 0.5))
	R.reserve(cx, cz, 0.6, 0.65)
	R.mark_wall(cx, 1.3, -hd, 0.45)
	R.mark_wall(-s * hw, 1.3, cz, 0.45)
	# --- l'étagère de la collection (contre le mur d'à côté) et la caisse des « pas-encore-classés »
	var ex: float = s * (hw - 0.2)
	var ez: float = 0.0
	var ew: float = 1.6
	R.etagere(ex, ez, -90.0 * s, ew, 1.9, false, 4)
	R.reserve(ex, ez, 0.6, ew + 0.1)
	R.mark_wall(s * hw, 1.0, ez, ew * 0.5 + 0.1)
	for row in range(5):
		var ry: float = 0.08 + 1.78 * float(row) / 4.0 + 0.016
		for k4 in range(4):
			if row == 4 and k4 % 2 == 1:
				continue
			var gl: float = -ew * 0.5 + 0.22 + k4 * (ew - 0.44) / 3.0 + r.randf_range(-0.04, 0.04)
			_cristaux_groupe(M, R.L(ex, ry, ez, -90.0 * s) * Transform3D(Basis(Vector3.UP, r.randf_range(-0.3, 0.3)), Vector3(gl, 0, 0.02)),
				"stc_%d" % (r.randi() % CRISTAUX_COULEURS.size()), r.randf_range(0.8, 1.2))
	var kxc: float = s * (hw - 0.45)
	var kzc: float = ez + ew * 0.5 + 0.45
	R.caisse(kxc, kzc, 0.45)
	for k5 in range(5):
		_cristaux_groupe(M, R.L(kxc + r.randf_range(-0.13, 0.13), 0.44, kzc + r.randf_range(-0.13, 0.13), r.randf() * 360.0), "stc_%d" % (r.randi() % CRISTAUX_COULEURS.size()), r.randf_range(0.9, 1.3), false)
	# --- la table de classement : les plateaux de petits cristaux, les étiquettes, la loupe, la
	# lanterne de mineur et le carnet de la collection ; la chaise du côté du fond
	var tx: float = s * clampf(hw * 0.38, 1.3, 2.0)
	var tz: float = 0.35
	R.table(tx, tz, 0, 1.3, 0.75, 0.76)
	R.chaise(tx, tz - 0.62, 0)
	for k6 in range(2):
		var plx: float = tx + s * (0.3 - k6 * 0.62)
		var plz: float = tz - 0.12
		R.kit.box(R.L(plx, 0.765, plz), Vector3(0.36, 0.012, 0.26), "bois_clair", 1.0)
		for sx3 in [-1.0, 1.0]:
			R.kit.box(R.L(plx + sx3 * 0.175, 0.785, plz), Vector3(0.012, 0.03, 0.26), "bois_sombre", 1.0)
			R.kit.box(R.L(plx, 0.785, plz + sx3 * 0.125), Vector3(0.36, 0.03, 0.012), "bois_sombre", 1.0)
		for k7 in range(4):
			_cristaux_groupe(M, R.L(plx - 0.11 + (k7 % 2) * 0.22, 0.77, plz - 0.06 + (0.0 if k7 < 2 else 0.12), r.randf() * 360.0), "stc_%d" % (r.randi() % CRISTAUX_COULEURS.size()), 0.6, false)
	for k8 in range(5):
		R.kit.box(R.L(tx - s * 0.3 + r.randf_range(-0.04, 0.04), 0.762 + k8 * 0.002, tz + 0.27 + r.randf_range(-0.03, 0.03), r.randf_range(-25.0, 25.0)), Vector3(0.05, 0.002, 0.026), "papier", 1.0)
	R.kit.ring(R.L(tx + s * 0.32, 0.77, tz + 0.2), 0.04, 0.05, 0.012, "or", 16)
	R.kit.cyl(R.L(tx + s * 0.32, 0.77, tz + 0.2), 0.04, 0.04, 0.006, "verre", 16)
	R.kit.box(R.L(tx + s * 0.42, 0.772, tz + 0.27, 40.0 * s), Vector3(0.1, 0.015, 0.02), "bois_sombre", 1.0)
	var lnx: float = tx - s * 0.52
	R.kit.cyl(R.L(lnx, 0.76, tz + 0.22), 0.06, 0.06, 0.03, "fer", 10)
	R.kit.cyl(R.L(lnx, 0.79, tz + 0.22), 0.045, 0.045, 0.12, "verre", 10, false)
	R.kit.cyl(R.L(lnx, 0.8, tz + 0.22), 0.012, 0.0, 0.08, "cristal", 6)
	R.kit.cyl(R.L(lnx, 0.91, tz + 0.22), 0.055, 0.015, 0.04, "fer", 10)
	var cnx: float = tx + s * 0.08
	var cnz: float = tz + 0.18
	R.kit.box(R.L(cnx, 0.765, cnz, 6.0), Vector3(0.36, 0.01, 0.24), "cuir", 1.0)
	for sx4 in [-1.0, 1.0]:
		R.kit.box(R.L(cnx + sx4 * 0.085, 0.773, cnz, 6.0), Vector3(0.16, 0.008, 0.22), "papier", 1.0)
	R.kit.box(R.L(cnx + 0.1, 0.779, cnz + 0.02, 6.0), Vector3(0.1, 0.001, 0.004), "noir", 1.0)
	R.kit.box(R.L(cnx - 0.08, 0.779, cnz - 0.03, 6.0), Vector3(0.11, 0.001, 0.004), "noir", 1.0)
	var carnet_at: Vector3 = R.P(cnx, 0.85, cnz)
	R.tapis(-s * 0.3, 1.1, 0, 2.0, 1.3)
	_cadres(M, 2)
	# --- les cinq chanteurs (Pipelette, le cinquième, est caché : sous le lit, dans la poche du
	# manteau ou dans la soupe… sauf si on l'a déjà retrouvé)
	var mats_ch: Array = []
	var chanteurs: Array = []
	for i3 in range(5):
		var mch: StandardMaterial3D = _verre(CRISTAUX_CHANTEURS[i3], 0.86, 1.0)
		mch.roughness = 0.08
		mats_ch.append(mch)
		chanteurs.append(_cristaux_chanteur(M, slots[i3], mch))
	var perdu: Node3D = chanteurs[4]
	var cache_at: Vector3
	var cache_act: Vector3
	var cache_rot: Vector3 = Vector3.ZERO
	match cache:
		0:
			cache_at = R.P(lx + s * 0.2, 0.05, lz + 0.1)
			cache_rot = Vector3(0, 0, PI * 0.5 * s)
			cache_act = R.P(lx + s * 0.3, 0, lz + 0.95)
		1:
			cache_at = R.P(cx + s * 0.16, 0.9, cz + 0.09)
			cache_act = R.P(cx + s * 0.85, 0, cz + 0.35)
		_:
			cache_at = R.P(mx, 0.98, mz)
			cache_rot = Vector3(0.25, 0, 0.2)
			cache_act = R.P(px - s * 0.6, 0, pz + 0.85)
	if not deja:
		perdu.global_position = cache_at
		perdu.rotation = cache_rot
	var st := {"t": r.randf() * 10.0, "lit": [0.0, 0.0, 0.0, 0.0, 0.0], "chante": false, "trouve": deja, "cherche": false,
		"page": 0, "hum": 5.0 + r.randf() * 4.0, "hum_n": 0, "sc4": 1.0 if deja else 0.65}
	# --- les gens : le jour, l'enfant près du présentoir, le parent classe à sa table ; la nuit,
	# l'enfant dort, le parent lit le carnet à la lueur de la lanterne
	var parent: Node
	var kid: Node
	var role_kid: String = "garcon" if boy else "fille"
	var lignes_trouve: Array = ["Touche-les : ils chantent !", "Chut, Bleuet fait la sieste.", "Celui-là, je l'ai trouvé tout seul ! Enfin, presque.", "Pipelette, arrête de bavarder !"]
	if nuit:
		kid = M.person(role_kid, lx, lz, -90.0 * s, "dormir")
		kid.lie(R.P(lx + s * 0.72, 0.5, lz), Vector3(-s, 0, 0))
		kid.lines = ["Zzz…", "Zzz… do… mi… sol… zzz…", "Mmh… Pipelette… chante moins fort… zzz…", "Zzz… trois cent douze… trois cent treize… zzz…"]
		kid.line_every = Vector2(9.0, 14.0)
		parent = M.person("homme" if pere else "femme", tx, tz - 0.62, 0.0, "lire")
		parent.lines = ["Chut… il dort." if boy else "Chut… elle dort.", "Tout doux, les cristaux…", "Encore une étiquette, et au lit.", "Bonne nuit, la collection."]
		parent.line_every = Vector2(10.0, 15.0)
	else:
		var kx: float = vx + s * 1.5
		var kz: float = prz + 0.25
		kid = M.person(role_kid, kx, kz, _vers(kx, kz, vx, prz + 0.8), "debout")
		kid.lines = lignes_trouve if deja else ["Pipelette ! Pipelette, où es-tu ?", "Touche-les : ils chantent !", "Il manque un chanteur… Il chantait encore ce matin !", "Chut ! Tu entends ? Il fredonne quelque part…"]
		kid.line_every = Vector2(6.0, 10.0)
		var pxp: float = tx - s * 0.95
		parent = M.person("homme" if pere else "femme", pxp, tz, 90.0 * s, "bricoler")
		parent.lines = ["Celui-là, avec les bleus… ou les verts ? Bleu-vert. Nouvelle étagère.", "Cent quatre-vingts… cent quatre-vingt-un…",
			"À la mine, je creuse. À la maison, j'étiquette.", "Attention à la vitrine : elle chante quand on la frôle."]
		parent.line_every = Vector2(9.0, 14.0)
	# --- faire chanter les cristaux : une petite mélodie, ils s'allument l'un après l'autre
	var chanter := func() -> void:
		if bool(st["chante"]):
			return
		st["chante"] = true
		var air: Array = CRISTAUX_AIRS[randi() % CRISTAUX_AIRS.size()]
		var db: float = -9.0 if nuit else 0.0
		if nuit:
			parent.say(str(_pick(M, ["Chut… tout doux, alors.", "Tout bas, d'accord ? Ils bercent la maison."])), 3.0)
		var complet: bool = true
		for k9 in range(air.size()):
			var ci: int = int(air[k9])
			if ci == 4 and not bool(st["trouve"]):
				complet = false
				_bulle(M, (slots[4] as Vector3) + Vector3(0, 0.3, 0), "… ?", Color(0.85, 0.8, 1.0), 40, 0.4, 1.6)
				break
			var cr: Node3D = chanteurs[ci]
			(st["lit"] as Array)[ci] = 1.0
			M.main.sfx("chant_%d" % ci, cr.global_position, db)
			_bulle(M, cr.global_position + Vector3(0, 0.38, 0), "♪", CRISTAUX_CHANTEURS[ci], 46, 0.5, 1.5)
			await M.get_tree().create_timer(0.6).timeout
			if not _la(M, room0):
				return
		st["chante"] = false
		if nuit:
			if complet:
				S._say_late(M, kid, "Zzz… do… mi… sol… zzz…", 0.6)
				S._say_late(M, parent, "Il a souri en dormant. Il entend ses cristaux même en rêve." if boy else "Elle a souri en dormant. Elle entend ses cristaux même en rêve.", 2.0)
			else:
				parent.say("Il manque la dernière note… Pipelette a encore disparu, je parie.", 3.5)
			return
		if complet:
			kid.gesture("joie", 2.0)
			kid.say(str(_pick(M, ["Tu as entendu ? C'est la chanson de la mine !", "Encore ! Encore !", "Ils t'aiment bien : ils ont chanté juste !"])), 3.0)
			S._say_late(M, parent, str(_pick(M, ["Ça, c'est un « la ». Ou un « si ». Enfin, c'est joli.", "Bravo ! Même les faux ont chanté juste."])), 1.8)
		else:
			kid.say(str(_pick(M, ["Il manque la note de Pipelette ! La plus aiguë…", "Tu entends le trou, à la fin ? C'est Pipelette qui chante là. Il a disparu !",
				"Sans Pipelette, la chanson tombe dans un trou."])), 3.5)
	M.act(R.P(vx, 0, prz + 0.65), "E : faire chanter les cristaux", chanter, 1.3, func(): return not bool(st["chante"]))
	# --- lire le carnet de la collection (une page à la fois, des nombres dedans)
	var pg: int = r.randi_range(3, 9)
	var pages: Array = [
		"CARNET DE LA COLLECTION. %d cristaux, dont %d qui chantent faux. Et un qui ne chante que le dimanche, mais alors très bien." % [n_total, n_faux],
		"Page %d. Trouvés dans la gamelle du contremaître Grisou : %d cristaux. Trouvés dans sa soupe : un. Il ne l'a jamais su." % [pg, r.randi_range(12, 48)],
		"Page %d. Règle numéro un de la collection : on ne lèche pas les cristaux. Même le jaune. Surtout le jaune." % (pg + r.randi_range(2, 6)),
		"Page %d. Échangés à l'école : %d cristaux. Contre des billes, une galette aux rouages et un dessin de Bernadette, la locomotive. Très bonnes affaires." % [pg + 9, r.randi_range(4, 19)],
		"Page %d. La Docteure Opaline Quartz voulait mettre Bleuet dans une lanterne. J'ai dit non. Il chante trop bien pour éclairer un couloir." % (pg + 14),
		"Page %d. Cristaux qui ont le droit de dormir dans mon lit : un seul. Pipelette, parce qu'il a peur du noir. Un cristal qui brille et qui a peur du noir : c'est très rare." % (pg + 21)]
	var lire := func() -> void:
		var p: int = int(st["page"])
		st["page"] = (p + 1) % pages.size()
		M.main.sfx("ui_ouvrir", carnet_at)
		M.say(str(pages[p]), 8.0)
		if nuit:
			if p == 0:
				S._say_late(M, parent, "Chut… Il l'écrit tous les soirs, sous la couverture, avec sa lampe de mineur. Il croit que je ne le sais pas." if boy else "Chut… Elle l'écrit tous les soirs, sous la couverture, avec sa lampe de mineur. Elle croit que je ne le sais pas.", 1.2, 5.0)
			return
		if p % 2 == 0:
			kid.say(str(_pick(M, ["C'est mon carnet ! Ne lis pas la page des secrets !", "Tout est vrai ! Même la page de la soupe.", "J'ai fait des dessins, aussi. Pas à cette page-là."])), 3.0)
		else:
			parent.gesture("rire", 2.0)
			parent.say(str(_pick(M, ["Ha ha ! Je découvre des choses, moi.", "Tout est vrai. Surtout la règle sur le jaune.", "Je n'étais pas au courant pour la gamelle de Grisou."])), 3.0)
	M.act(R.P(tx + s * 0.15, 0, tz + 0.85), "E : lire le carnet", lire, 1.2)
	# --- chercher le cristal perdu : il revole à sa place ; l'enfant est fou de joie (une récompense, une fois)
	var recompense := func() -> void:
		M.bonne_action_v120()  ## V120 : une bonne action, l'île s'en souvient
		if bool(M.state().get("st_cristaux", false)):
			return
		M.state()["st_cristaux"] = true
		await M.get_tree().create_timer(2.4).timeout
		if not _la(M, room0):
			return
		if nuit:
			M.talk(parent, "Chut… Pipelette ! Il le cherchait partout depuis ce matin. Il a deux éclats de cristal pareils, deux jumeaux : il t'en aurait donné un, c'est sûr. Tiens, de sa part." if boy else "Chut… Pipelette ! Elle le cherchait partout depuis ce matin. Elle a deux éclats de cristal pareils, deux jumeaux : elle t'en aurait donné un, c'est sûr. Tiens, de sa part.",
				I._bye("Merci… Bonne nuit !"), func(_i):
				M.give([["eclat_cristal", 1]], "")
				M.close_talk(), "à voix basse")
			return
		M.talk(kid, "Tu as retrouvé Pipelette ! Tiens : j'ai deux éclats de cristal pareils, des jumeaux. Un pour toi, un pour moi. Comme ça, on a le même. Écoute : il chante pareil !",
			I._bye("Merci ! Bonne descente !"), func(_i):
			M.give([["eclat_cristal", 1]], "")
			M.close_talk(), "fou de joie" if boy else "folle de joie")
	var chercher := func() -> void:
		if bool(st["trouve"]) or bool(st["cherche"]):
			return
		st["cherche"] = true
		var recit: Array
		if nuit:
			recit = ["Tout doucement, tu te glisses sous le lit de l'enfant endormi. Au fond, entre deux chaussettes, une petite lueur violette fredonne.",
				"Sans un bruit, tu fouilles la poche du gros manteau de mineur. Un mouchoir, un bout de crayon… et un cristal violet, bien au chaud, qui fredonne.",
				"La marmite tiédit sur le poêle. Dans la soupe, une petite lueur violette chantonne : « Bloup ♪ »."]
		else:
			recit = ["Tu te penches sous le lit. Une chaussette, trois billes, un trognon de galette… et, tout au fond, une petite lueur violette qui fredonne.",
				"Tu fouilles la poche du gros manteau de mineur : un mouchoir, un bout de crayon, un ticket du Petit Train… et un cristal violet, bien au chaud, qui fredonne.",
				"Tu te penches sur la marmite. Dans la soupe, quelque chose de violet fait des bulles en chantonnant : « Bloup ♪ »."]
		M.main.sfx(["touche_bois", "ramasse", "bulles"][cache], cache_at)
		M.say(str(recit[cache]), 6.0)
		await M.get_tree().create_timer(1.2).timeout
		if not _la(M, room0):
			return
		# il s'envole jusqu'à sa place, sur le présentoir
		var sortie: Vector3 = cache_act + Vector3(0, 1.3, 0)
		var dest: Vector3 = slots[4]
		M.main.sfx("cristal_eveil", perdu.global_position)
		st["sc4"] = 1.0
		var tw: Tween = M.room.create_tween()
		tw.tween_property(perdu, "global_position", sortie, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(perdu, "rotation", Vector3(0, TAU, 0), 1.6)
		tw.tween_property(perdu, "global_position", dest + Vector3(0, 0.35, 0), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(perdu, "global_position", dest, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		await M.get_tree().create_timer(2.35).timeout
		if not _la(M, room0):
			return
		perdu.rotation = Vector3.ZERO
		st["trouve"] = true
		(st["lit"] as Array)[4] = 1.0
		M.main.sfx("chant_4", dest, -9.0 if nuit else 0.0)
		_bulle(M, dest + Vector3(0, 0.4, 0), "♪", CRISTAUX_CHANTEURS[4], 50, 0.6, 1.8)
		var ou: Array = ["Sous le lit ! Je l'avais dit, qu'il fallait ranger sous ce lit.", "Dans MA poche ? Il est donc allé à la mine avec moi toute la journée. Il a dû adorer.",
			"Dans la soupe ! Je me disais aussi : elle était bleue, et elle chantait."]
		if nuit:
			S._say_late(M, kid, "Mmh… Pipelette… zzz…", 0.6)
			S._say_late(M, parent, str(ou[cache]), 1.6)
		else:
			kid.lines = lignes_trouve
			kid.gesture("joie", 3.0)
			kid.say(str(_pick(M, ["PIPELETTE ! Tu es revenu !", "Il était là ! Je savais qu'il chantait quelque part !", "Mon Pipelette ! Merci, merci, merci !"])), 3.0)
			S._say_late(M, parent, str(ou[cache]), 1.8)
		recompense.call()
	if not deja:
		M.act(cache_act, "E : chercher le cristal manquant", chercher, 1.3, func(): return not bool(st["trouve"]) and not bool(st["cherche"]))
	# --- ce qui bouge : tout pulse doucement (la nuit, tout bas), les chanteurs s'allument et
	# grandissent quand ils chantent, la veilleuse respire ; Pipelette, caché, fredonne de temps en temps
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(perdu):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var base: float = 0.45 if nuit else 1.1
		for i4 in range(mats.size()):
			(mats[i4] as StandardMaterial3D).emission_energy_multiplier = base * (0.7 + 0.3 * sin(t * 0.8 + i4 * 1.7))
		var lit: Array = st["lit"]
		var sc4: float = move_toward(float(st["sc4"]), 1.0 if bool(st["trouve"]) or bool(st["cherche"]) else 0.65, dt * 0.6)
		st["sc4"] = sc4
		for i5 in range(5):
			var l: float = maxf(0.0, float(lit[i5]) - dt * 1.3)
			lit[i5] = l
			(mats_ch[i5] as StandardMaterial3D).emission_energy_multiplier = base * (0.8 + 0.25 * sin(t * 1.1 + i5)) + 5.0 * l
			var sc: float = sc4 if i5 == 4 else 1.0
			(chanteurs[i5] as Node3D).scale = Vector3.ONE * sc * (1.0 + 0.03 * sin(t * 1.6 + i5 * 0.9) + 0.18 * l)
		lum_v.light_energy = (0.22 if nuit else 0.45) * (0.85 + 0.15 * sin(t * 0.8)) + 0.4 * (float(lit[0]) + float(lit[1]) + float(lit[2]) + float(lit[3]) + float(lit[4])) * 0.2
		var resp: float = 0.85 + 0.15 * sin(t * 0.6)
		vmat.emission_energy_multiplier = (2.2 if nuit else 0.8) * resp
		lum_n.light_energy = (0.7 if nuit else 0.15) * resp
		if bool(st["trouve"]) or bool(st["cherche"]):
			return
		st["hum"] = float(st["hum"]) - dt
		if float(st["hum"]) > 0.0:
			return
		st["hum"] = 9.0 + randf() * 5.0
		st["hum_n"] = int(st["hum_n"]) + 1
		lit[4] = 0.6
		M.main.sfx("chant_4", perdu.global_position, -16.0 if nuit else -11.0)
		_bulle(M, perdu.global_position + Vector3(0, 0.3, 0), "♪", CRISTAUX_CHANTEURS[4], 30, 0.35, 1.4)
		if not nuit and int(st["hum_n"]) % 2 == 1 and not bool(kid.talking):
			kid.say(str(_pick(M, ["Tu entends ? C'est Pipelette ! Il chante quelque part…", "Chut ! Il fredonne… Mais où ?", "Pipelette ! Je t'entends, tu sais !"])), 3.0)
	# --- les conversations
	var kid_cb := func() -> void:
		if nuit:
			M.talk(kid, str(_pick(M, ["Zzz… Bleuet… Grenadine… Mirabelle… zzz…", "Zzz… pas dans la soupe… zzz…", "Zzz… trois cent treize… trois cent quatorze… zzz…"])),
				I._bye("(Le laisser dormir)") if boy else I._bye("(La laisser dormir)"), I._close(M), "endormi" if boy else "endormie")
			return
		var accueil: String = str(_pick(M, ["Bienvenue dans ma collection ! Ne touche à rien… Enfin, si : touche les chanteurs, ils adorent ça.",
			"Chut ! J'écoute s'ils chantent juste. … Voilà. Bonne descente !",
			"Tu viens voir mes cristaux ? Ils ont tous une étiquette. Moi aussi, j'en ai une : « Chef de la collection »." if deja else "Tu viens voir mes cristaux ? Ils sont tous rangés. Sauf un. Il s'appelle Pipelette, et il a disparu."]))
		var humeur: String = "passionné" if boy else "passionnée"
		M.talk(kid, accueil, [{"id": "prefere", "label": "Lequel est ton préféré ?"}, {"id": "ou", "label": "Où les trouves-tu ?"},
			{"id": "chante", "label": "Ils chantent vraiment ?"}, {"id": "fermer", "label": "Bonne descente !"}], func(id):
			match id:
				"prefere":
					if bool(st["trouve"]):
						M.talk(kid, "Pipelette, le violet ! Il est bavard comme une pie. Depuis que tu l'as retrouvé, il ne quitte plus sa place. Enfin… je crois.", I._bye("Surveille-le bien !"), I._close(M), humeur)
					else:
						M.talk(kid, "Pipelette, le violet ! Il chante tout le temps, même quand on ne le touche pas : c'est pour ça qu'il s'appelle Pipelette. Mais ce matin, il a disparu… Écoute bien : des fois, on l'entend fredonner.", I._bye("Je vais le chercher !"), I._close(M), humeur)
				"ou":
					M.talk(kid, "Dans les déblais, à la sortie de la mine ! Les mineurs me gardent les tout petits, trop petits pour les lanternes. Le contremaître Grisou m'en cache dans sa gamelle. Mais d'abord, il faut dire bonjour à la Vieille : c'est la roche.",
						[{"id": "vieille", "label": "Dire bonjour à la roche ?"}, {"id": "fermer", "label": "Quelle chance !"}], func(id2):
						if id2 == "vieille":
							M.talk(kid, "Ben oui. Si tu lui dis bonjour, elle te donne des cristaux. Si tu oublies, elle te donne des cailloux. Moi, je lui dis bonjour, au revoir, et bon appétit.", I._bye("Bonne idée !"), I._close(M), humeur)
						else:
							M.close_talk()
					, humeur)
				"chante":
					M.talk(kid, "Bien sûr ! Chacun a sa note : Bleuet la plus grave, Pipelette la plus aiguë. La Docteure Opaline Quartz dit que c'est la roche qui se souvient de l'eau qui coulait dedans. Moi, je crois qu'ils s'ennuient.",
						[{"id": "ennui", "label": "Ils s'ennuient ?"}, {"id": "fermer", "label": "Je vais les écouter !"}], func(id3):
						if id3 == "ennui":
							M.talk(kid, "Ça fait des millions d'années qu'ils sont dans le noir, sans personne. Alors quand on les touche, ils sont contents : ils chantent. Comme moi quand on vient me voir.", I._bye("Alors je les touche !"), I._close(M), humeur)
						else:
							M.close_talk()
					, humeur)
				_:
					M.close_talk()
		, humeur)
	M.talk_spot(kid, kid_cb)
	var parent_cb := func() -> void:
		if nuit:
			var choix: Array = [{"id": "chantent", "label": "Ils chantent, la nuit ?"}]
			if not bool(st["trouve"]):
				choix.append({"id": "perdu", "label": "Il en manque un ?"})
			choix.append({"id": "fermer", "label": "Bonne nuit…"})
			M.talk(parent, "Chut… Il dort. Les cristaux veillent sur lui : la nuit, ils baissent leur lumière et chantent tout bas." if boy else "Chut… Elle dort. Les cristaux veillent sur elle : la nuit, ils baissent leur lumière et chantent tout bas.", choix, func(id):
				match id:
					"chantent":
						M.talk(parent, "Tout bas. Juste assez pour qu'on les entende en rêve. Le matin, il me les fredonne au petit déjeuner. Faux, mais avec cœur." if boy else "Tout bas. Juste assez pour qu'on les entende en rêve. Le matin, elle me les fredonne au petit déjeuner. Faux, mais avec cœur.", I._bye("Bonne nuit…"), I._close(M), "à voix basse")
					"perdu":
						M.talk(parent, "Pipelette, le violet. Il a disparu ce matin. Le petit s'est endormi en le cherchant… Si vous l'entendez fredonner, chut : remettez-le à sa place." if boy else "Pipelette, le violet. Il a disparu ce matin. La petite s'est endormie en le cherchant… Si vous l'entendez fredonner, chut : remettez-le à sa place.", I._bye("Promis, tout doux."), I._close(M), "à voix basse")
					_:
						M.close_talk()
			, "à voix basse")
			return
		var accueils: Array = [
			[["Bonne descente ! Je suis mineur aux Mines de Cristaux. Le jour, je les creuse ; le soir, mon fils me les fait étiqueter.", "Bonne descente ! Je suis mineur aux Mines de Cristaux. Le jour, je les creuse ; le soir, ma fille me les fait étiqueter."],
				["Bonne descente ! Je suis mineuse aux Mines de Cristaux. Le jour, je les creuse ; le soir, mon fils me les fait étiqueter.", "Bonne descente ! Je suis mineuse aux Mines de Cristaux. Le jour, je les creuse ; le soir, ma fille me les fait étiqueter."]],
			[["Bonne descente ! Attention, ici, tout ce qui brille chante. Et tout ce qui chante a une étiquette. C'est le règlement de la maison.", "Bonne descente ! Attention, ici, tout ce qui brille chante. Et tout ce qui chante a une étiquette. C'est le règlement de la maison."],
				["Bonne descente ! Attention, ici, tout ce qui brille chante. Et tout ce qui chante a une étiquette. C'est le règlement de la maison.", "Bonne descente ! Attention, ici, tout ce qui brille chante. Et tout ce qui chante a une étiquette. C'est le règlement de la maison."]]]
		var accueil: String = str(accueils[r.randi() % 2][0 if pere else 1][0 if boy else 1])
		M.talk(parent, accueil, [{"id": "combien", "label": "Il y en a combien ?"}, {"id": "classer", "label": "Comment les classez-vous ?"},
			{"id": "mine", "label": "C'est dur, la mine ?"}, {"id": "fermer", "label": "Bonne descente !"}], func(id):
			match id:
				"combien":
					M.talk(parent, "%d, officiellement. Plus ceux qui dorment dans ses poches, sous son oreiller et, une fois, dans mon casque." % n_total, I._bye("Par les Strates !"), I._close(M), "amusé" if pere else "amusée")
				"classer":
					M.talk(parent, "Par couleur, puis par note, puis par humeur. Les bleus sont calmes, les rouges bavards, les jaunes chatouilleux. Moi, je fais les étiquettes ; le chef de la collection, c'est mon fils." if boy else "Par couleur, puis par note, puis par humeur. Les bleus sont calmes, les rouges bavards, les jaunes chatouilleux. Moi, je fais les étiquettes ; la cheffe de la collection, c'est ma fille.",
						I._bye("Une vraie collection !"), I._close(M), "amusé" if pere else "amusée")
				"mine":
					M.talk(parent, "Ça creuse ! Mais il y a les cristaux qui luisent au fond des galeries, le Soleil de Laiton en sortant, et le chocolat du mineur de La Marmite, qui répare tout. Les tout petits éclats, trop petits pour les lanternes, je les rapporte ici.",
						I._bye("Bonne descente !"), I._close(M), "fier" if pere else "fière")
				_:
					M.close_talk()
		, "de bonne humeur")
	M.talk_spot(parent, parent_cb)
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Un enfant dort dans un petit lit. Tout autour, des centaines de cristaux luisent doucement, comme des veilleuses de toutes les couleurs.",
			"Il fait nuit. Dans la vitrine, les cristaux respirent tout bas, bleus, roses, verts. À la table, quelqu'un lit un carnet à la lueur d'une lanterne et te fait « chut ».",
			"La maison dort, mais la collection veille : des cristaux qui brillent à peine, une veilleuse bleue près du lit, et un tout petit fredonnement, quelque part."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Une vitrine pleine de cristaux, une étagère pleine de cristaux, une caisse pleine de cristaux… Bienvenue dans la plus grande collection des Strates. Enfin, de la maison.",
			"Ça brille partout ! Bleu, rose, vert, violet : des centaines de petits cristaux, chacun avec son étiquette. Un enfant te regarde comme un gardien de musée.",
			"Des cristaux de toutes les couleurs luisent doucement dans une grande vitrine. À une table, quelqu'un les classe à la loupe ; près d'un présentoir, un enfant cherche quelque chose."]))


# =================================================================== la maison sous la fuite d'eau

## (écrite à part)
# =================================================================== la maison sous la fuite

## La maison sous la fuite (une maison des Strates) : l'eau de pluie de la surface, celle de la
## Cascade des Jardins, traverse cent mètres de grès et goutte du plafond à trois ou quatre endroits :
## dans un seau de fer, dans le bassin de cuivre où tourne la petite roue à aubes de l'enfant (sous la
## plus grosse goutte, un filet continu), dans la jardinière de la mère (des plantes et des champignons
## lumineux qui ne boivent que l'eau d'en haut) et, une maison sur deux, dans une casserole de cuivre
## posée au milieu de la table. Le seau et la casserole se remplissent ; quand l'un est plein, le père
## (ou la mère, s'il n'y a pas de père) le porte jusqu'à la grande citerne, le vide avec un soupir… et
## ça recommence. Le grand-père, dans son fauteuil, dit que c'est bon pour les articulations. On peut
## vider un seau (la mère remercie ; la première fois, un sirop de la Cascade), mettre la main sous la
## goutte (« Plic ! »), goûter l'eau de la surface (elle a le goût du ciel). La nuit, tout le monde dort,
## les gouttes tombent plus lentement (« plic… ploc… ») et le grand-père dort dans son fauteuil sous un
## parapluie ouvert.
static func _fuite(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var room0 = M.room
	var nuit: bool = _nuit(M)
	var s: float = 1.0 if r.randf() < 0.5 else -1.0
	var boy: bool = r.randf() < 0.5
	var avec_pere: bool = r.randf() < 0.65
	var quatre: bool = r.randf() < 0.5
	var sol: float = R.P(0, 0, 0).y
	_fuite_mats(M)
	var eau_m := _verre(Color(0.32, 0.5, 0.62), 0.82, 0.12)
	eau_m.roughness = 0.04
	# --- la grande citerne de cuivre cerclée de fer, dans le coin du fond (son robinet, sa jauge de
	# verre, la bouche où l'on verse) ; à côté, les seaux de rechange et la serpillière
	var cx: float = s * (hw - 0.62)
	var cz: float = -hd + 0.62
	var cpx: float = s * (hw - 1.55)
	var cpz: float = -hd + 1.0
	var cdir := Vector2(cpx - cx, cpz - cz).normalized()
	var cyaw: float = _vers(cx, cz, cpx, cpz)
	R.kit.cyl(R.L(cx, 0, cz), 0.5, 0.5, 1.3, "cuivre", 24)
	for yy in [0.1, 0.62, 1.14]:
		R.kit.ring(R.L(cx, float(yy), cz), 0.5, 0.53, 0.06, "fer", 24)
	R.kit.cyl(R.L(cx, 1.3, cz), 0.53, 0.53, 0.04, "fer", 24)
	var bx0: float = cx + cdir.x * 0.3
	var bz0: float = cz + cdir.y * 0.3
	R.kit.ring(R.L(bx0, 1.34, bz0), 0.15, 0.18, 0.03, "cuivre", 16)
	R.kit.cyl(R.L(bx0, 1.341, bz0), 0.15, 0.15, 0.004, "fu_eau", 16)
	R.kit.cyl(R.L(cx + cdir.x * 0.48, 0.3, cz + cdir.y * 0.48, cyaw) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.025, 0.025, 0.14, "or", 8)
	R.kit.box(R.L(cx + cdir.x * 0.58, 0.36, cz + cdir.y * 0.58, cyaw), Vector3(0.08, 0.02, 0.02), "or", 1.0)
	var jx0: float = cx + cdir.x * 0.53
	var jz0: float = cz + cdir.y * 0.53
	R.kit.cyl(R.L(jx0, 0.2, jz0), 0.024, 0.024, 0.96, "verre", 10)
	for yy2 in [0.18, 1.16]:
		R.kit.cyl(R.L(jx0, float(yy2), jz0), 0.03, 0.03, 0.03, "or", 10)
	R.kit.col_box(R.L(cx, 0.65, cz), Vector3(1.06, 1.3, 1.06))
	R.reserve(cx, cz, 1.2, 1.2)
	var cit_c: Vector3 = R.P(cx, 0, cz)
	var cit_top: Vector3 = R.P(bx0, 1.38, bz0)
	var cit_pres: Vector3 = R.P(cpx, 0, cpz)
	var rim: Vector3 = R.P(cx + cdir.x * 0.36, 1.48, cz + cdir.y * 0.36)
	var jauge: MeshInstance3D = _p(M.room, I._cyl(0.017, 0.017, 1.0, 8), eau_m, Vector3.ZERO)
	var jauge_bas: Vector3 = R.P(jx0, 0.2, jz0)
	jauge.global_position = jauge_bas
	jauge.scale = Vector3(1.0, 0.01, 1.0)
	var sx1: float = s * (hw - 1.4)
	var sz1: float = -hd + 0.3
	R.kit.cyl(R.L(sx1, 0, sz1), 0.13, 0.16, 0.3, "fer", 14, false)
	R.kit.ring(R.L(sx1, 0.3, sz1), 0.15, 0.17, 0.02, "fer", 14)
	R.kit.cyl(R.L(sx1 + s * 0.05, 0.3, sz1 + 0.02, 15.0), 0.12, 0.15, 0.06, "fer", 14)
	R.kit.cyl(R.L(sx1, 0.003, sz1), 0.13, 0.13, 0.004, "noir", 14)
	R.reserve(sx1, sz1, 0.4, 0.4)
	var mpx: float = s * (hw - 0.22)
	var mpz: float = -hd + 1.28
	R.kit.box(R.L(mpx, 0.7, mpz) * Transform3D(Basis(Vector3.BACK, 0.16 * s), Vector3.ZERO), Vector3(0.03, 1.4, 0.03), "bois_clair", 1.0)
	R.kit.box(R.L(mpx + s * 0.11, 0.05, mpz) * Transform3D(Basis(Vector3.BACK, 0.16 * s), Vector3.ZERO), Vector3(0.24, 0.1, 0.12), "tissu_gris", 1.0)
	# --- le poêle, au milieu du mur du fond ; l'étagère des bouteilles de sirop (s'il y a la place)
	R.foyer(0.0, -hd + 0.45, 0, true)
	R.mark_wall(0.0, 1.6, -hd, 0.35)
	var ex: float = s * (0.6 + hw - 1.15) * 0.5
	var ew: float = minf(0.9, hw - 1.95)
	if ew > 0.5 and R.wall_free(ex, 1.55, -hd, ew * 0.5 + 0.1):
		R.etagere_murale(ex, 1.55, -hd + 0.14, 0, ew, "fu_sirop", 5)
	# --- le lit des parents, la tête contre le mur du fond, le long de l'autre côté
	var lx: float = -s * (hw - 0.8)
	var lz: float = -hd + 1.08
	R.lit(lx, lz, 0, 1.3, str(_pick(M, ["bleu", "rouge", "vert", "brun"])))
	# --- la jardinière de la mère, le long du même mur : des plantes, de la mousse, des champignons
	var jx: float = -s * (hw - 0.38)
	var jz: float = maxf(0.3, -hd + 3.05)
	R.kit.box(R.L(jx, 0.21, jz), Vector3(0.5, 0.42, 1.4), "bois_sombre", 1.0)
	R.kit.box(R.L(jx, 0.425, jz), Vector3(0.44, 0.012, 1.34), "terreau", 1.0)
	for k in range(10):
		var pz: float = jz - 0.6 + k * 0.13
		if absf(pz - (jz + 0.15)) < 0.12:
			continue
		var pxf: Transform3D = R.L(jx + r.randf_range(-0.12, 0.12), 0.43, pz) * Transform3D(Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, r.randf_range(-0.6, 0.6)), Vector3.ZERO)
		R.kit.box(pxf * Transform3D(Basis(), Vector3(0, 0.15, 0)), Vector3(0.11, 0.3, 0.015), "fu_vert" if k % 2 == 0 else "fu_vert_clair", 1.0)
	R.kit.cyl(R.L(jx, 0.432, jz + 0.15), 0.16, 0.16, 0.006, "fu_mousse", 14)
	R.kit.col_box(R.L(jx, 0.21, jz), Vector3(0.5, 0.42, 1.4))
	R.reserve(jx, jz, 0.7, 1.6)
	# --- le bassin de cuivre de la roue à aubes, au milieu de la pièce (de l'eau jusqu'au bord)
	var bsx: float = -s * 0.75
	var bsz: float = -hd + 2.45
	R.kit.ring(R.L(bsx, 0, bsz), 0.39, 0.42, 0.22, "cuivre", 28)
	R.kit.ring(R.L(bsx, 0.22, bsz), 0.38, 0.44, 0.02, "cuivre", 28)
	R.kit.cyl(R.L(bsx, 0.0, bsz), 0.39, 0.39, 0.02, "cuivre", 28)
	R.kit.cyl(R.L(bsx, 0.185, bsz), 0.39, 0.39, 0.004, "fu_eau", 28)
	R.kit.col_box(R.L(bsx, 0.12, bsz), Vector3(0.84, 0.24, 0.84))
	R.reserve(bsx, bsz, 1.0, 1.0)
	for k2 in range(4):
		var am: float = TAU * k2 / 4.0 + r.randf()
		R.kit.cyl(R.L(bsx + cos(am) * 0.62, 0.0, bsz + sin(am) * 0.62), r.randf_range(0.1, 0.18), r.randf_range(0.1, 0.18), 0.008, "fu_mousse", 10)
	var hub: Vector3 = R.P(bsx, 0.44, bsz)
	var roue: Dictionary = _fuite_roue(M, hub)
	var rotor: Node3D = roue["rotor"]
	# --- la table (une casserole au milieu, une maison sur deux) et ses chaises, de l'autre côté
	var tx: float = s * (hw - 1.4)
	var tz: float = clampf(hd - 2.6, -hd + 3.2, hd - 2.2)
	R.table(tx, tz, 0, 1.2, 0.8)
	R.chaise(tx, tz - 0.62, 0)
	R.chaise(tx, tz + 0.62, 180)
	R.kit.cyl(R.L(tx - s * 0.4, 0.76, tz + 0.22), 0.04, 0.032, 0.2, "fu_sirop", 10)
	R.kit.cyl(R.L(tx - s * 0.4, 0.96, tz + 0.22), 0.012, 0.012, 0.05, "bois_clair", 6)
	R.kit.cyl(R.L(tx + s * 0.38, 0.76, tz - 0.2), 0.05, 0.04, 0.09, "ceramique", 10)
	# --- le fauteuil du grand-père, tourné vers la roue ; une plante à côté
	var fx: float = -s * (hw - 1.35)
	var fz: float = hd - 2.15
	var fyaw: float = _vers(fx, fz, bsx, bsz)
	R.fauteuil(fx, fz, fyaw, str(_pick(M, ["brun", "vert", "rouge"])))
	if R.is_free(-s * (hw - 0.45), hd - 1.8, 0.5, 0.5):
		R.plante(-s * (hw - 0.45), hd - 1.8)
	_cadres(M, 2)
	# --- les champignons lumineux (dans la jardinière et autour du bassin) et leur lumière
	var champ_m: Array = [_mat(Color(0.45, 0.95, 0.85), 0.0, 0.5, 1.4), _mat(Color(0.6, 0.75, 1.0), 0.0, 0.5, 1.4), _mat(Color(0.85, 0.95, 0.5), 0.0, 0.5, 1.2)]
	var pied_m := _mat(Color(0.92, 0.9, 0.82), 0.0, 0.8, 0.25)
	for k3 in range(6):
		var cz3: float = jz - 0.55 + k3 * 0.21 + r.randf_range(-0.04, 0.04)
		_fuite_champi(M, R.P(jx + r.randf_range(-0.14, 0.14), 0.43, cz3), r.randf_range(0.8, 1.5), pied_m, champ_m[k3 % champ_m.size()])
	for k4 in range(3):
		var a4: float = PI * 0.3 + k4 * 0.7 + (PI if s > 0.0 else 0.0)
		_fuite_champi(M, R.P(bsx + cos(a4) * 0.6, 0.0, bsz + sin(a4) * 0.6), r.randf_range(0.9, 1.3), pied_m, champ_m[(k4 + 1) % champ_m.size()])
	var lum := OmniLight3D.new()
	lum.light_color = Color(0.5, 0.95, 0.85)
	lum.omni_range = 2.6
	lum.shadow_enabled = false
	M.room.add_child(lum)
	lum.global_position = R.P(jx - s * 0.3, 0.8, jz)
	# --- les gouttes : le seau, le bassin de la roue, la jardinière (et la casserole) ; une tache
	# d'humidité au plafond au-dessus de chacune, une petite pointe de grès d'où la goutte se détache
	var goutte_mesh: SphereMesh = I._sph(0.017)
	var goutte_m := _verre(Color(0.78, 0.9, 1.0), 0.85, 0.6)
	var sx0: float = s * 0.85
	var sz0: float = -0.35
	var drips: Array = []
	var d_seau: Dictionary = _fuite_goutte(M, sx0, sz0, "seau", 1.5, goutte_mesh, goutte_m)
	var rs: Dictionary = _fuite_recipient(M, R.P(sx0, 0, sz0), "seau", eau_m)
	d_seau.merge(rs)
	d_seau["home"] = R.P(sx0, 0, sz0)
	d_seau["lvl"] = r.randf_range(0.45, 0.9)
	d_seau["dl"] = 1.0 / 55.0
	drips.append(d_seau)
	var d_roue: Dictionary = _fuite_goutte(M, bsx, bsz + 0.13, "bassin", 1.0, goutte_mesh, goutte_m)
	d_roue["hy"] = hub.y + 0.18
	d_roue["ry"] = sol + 0.19
	drips.append(d_roue)
	var d_terre: Dictionary = _fuite_goutte(M, jx, jz + 0.15, "terre", 2.4, goutte_mesh, goutte_m)
	d_terre["hy"] = sol + 0.44
	d_terre["ring_ok"] = false
	drips.append(d_terre)
	if quatre:
		var d_cas: Dictionary = _fuite_goutte(M, tx, tz, "casserole", 2.1, goutte_mesh, goutte_m)
		d_cas.merge(_fuite_recipient(M, R.P(tx, 0.76, tz), "casserole", eau_m))
		d_cas["home"] = R.P(tx, 0.76, tz)
		d_cas["lvl"] = r.randf_range(0.3, 0.8)
		d_cas["dl"] = 1.0 / 26.0
		d_cas["pres"] = R.P(tx - s * 0.9, 0, tz)
		drips.append(d_cas)
	var porte_ids: Array = []
	for i0 in range(drips.size()):
		if (drips[i0] as Dictionary).has("cont"):
			porte_ids.append(i0)
	# le filet continu de la plus grosse goutte, qui tombe sur les aubes de la roue
	var filet: CPUParticles3D = _gouttes(M, 10)
	filet.emission_box_extents = Vector3(0.01, 0.005, 0.01)
	var big_src: Vector3 = d_roue["src"]
	var dy: float = maxf(0.5, big_src.y - (hub.y + 0.2))
	filet.lifetime = (-0.8 + sqrt(0.64 + 10.0 * dy)) / 5.0
	filet.global_position = big_src
	filet.emitting = true
	# --- les gens : le jour, la mère jardine sous la goutte, le père surveille le seau, l'enfant regarde
	# sa roue, le grand-père est dans son fauteuil ; la nuit, tout le monde dort
	var col_para: Color = [Color(0.2, 0.3, 0.62), Color(0.72, 0.18, 0.15), Color(0.2, 0.46, 0.3)][r.randi() % 3]
	var mx: float = jx + s * 0.75
	var mz: float = jz
	var phx: float = sx0 + s * 0.65
	var phz: float = sz0 + 0.55
	var mere: Node
	var pere: Node = null
	var papi: Node
	var kid: Node
	var fxf: Vector3 = Basis(Vector3.UP, deg_to_rad(fyaw)) * Vector3(0, 0, 1)
	if nuit:
		mere = M.person("femme", lx, lz, 0, "dormir")
		mere.lie(R.P(lx - (0.3 if avec_pere else 0.0), 0.5, lz + 0.88), Vector3(0, 0, -1))
		mere.lines = ["Zzz…", "Zzz… le seau… quelqu'un… zzz…", "Mmh… plic… ploc… zzz…"]
		mere.line_every = Vector2(10.0, 15.0)
		if avec_pere:
			pere = M.person("homme", lx, lz, 0, "dormir")
			pere.lie(R.P(lx + 0.3, 0.5, lz + 0.88), Vector3(0, 0, -1))
			pere.lines = ["Rrron… pschhh…", "Zzz… encore un seau… zzz…", "Zzz… je la boucherai… demain… zzz…"]
			pere.line_every = Vector2(11.0, 16.0)
		# le petit matelas de l'enfant, contre le mur, entre la citerne et la table
		var kmx: float = s * (hw - 0.5)
		var kz0: float = -hd + 1.45
		var kz1: float = tz - 0.9
		var kmz: float = (kz0 + kz1) * 0.5
		R.kit.box(R.L(kmx, 0.06, kmz), Vector3(0.72, 0.12, 1.5), "drap", 1.0)
		R.kit.box(R.L(kmx, 0.125, kmz + 0.2), Vector3(0.75, 0.03, 1.0), "tissu_" + str(_pick(M, ["jaune", "turquoise", "orange"])), 1.0)
		R.kit.box(R.L(kmx, 0.15, kmz - 0.55), Vector3(0.42, 0.08, 0.26), "tissu_blanc", 1.0)
		R.reserve(kmx, kmz, 0.9, 1.7)
		kid = M.person("garcon" if boy else "fille", kmx, kmz, 0, "dormir")
		kid.lie(R.P(kmx, 0.12, kmz + 0.62), Vector3(0, 0, -1))
		kid.lines = ["Zzz…", "Zzz… plus vite, la roue… zzz…", "Mmh… il pleut… zzz…"]
		kid.line_every = Vector2(9.0, 14.0)
		papi = M.person("vieux", fx + fxf.x * 0.05, fz + fxf.z * 0.05, fyaw, "dormir_assis")
		papi.lines = ["Zzz…", "Zzz… plic… ploc… zzz…", "Rrrr… bon pour les articulations… zzz…"]
		papi.line_every = Vector2(9.0, 14.0)
		var para: Node3D = _fuite_parapluie(M, R.P(fx + fxf.x * 0.1, 0.95, fz + fxf.z * 0.1), true, col_para)
		para.rotation = Vector3(-0.12, deg_to_rad(fyaw), 0.1)
	else:
		mere = M.person("femme", mx, mz, _vers(mx, mz, jx, jz), "jardiner")
		mere.lines = ["Doucement, mes champignons : voilà votre pluie.", "Plic, ploc… On ne l'entend même plus. Enfin, presque.", "Ces champignons-là ne boivent que l'eau de la surface. Des gourmets.", "Attention où vous marchez, ça goutte !"]
		if avec_pere:
			pere = M.person("homme", phx, phz, _vers(phx, phz, sx0, sz0), "bras_croises")
			pere.lines = ["Il est bientôt plein, celui-là.", "Plic… ploc… plic… Je compte. Je ne devrais pas compter.", "Un jour, je boucherai cette fuite. Un jour.", "Quelqu'un a vu ma serpillière ?"]
			pere.line_every = Vector2(8.0, 13.0)
		var kx: float = bsx + s * 0.6
		var kz: float = bsz + 0.35
		kid = M.person("garcon" if boy else "fille", kx, kz, _vers(kx, kz, bsx, bsz), "jardiner")
		kid.lines = ["Plus vite, la roue ! Plus vite !", "Elle a fait quatre-vingt-douze tours ! Non, quatre-vingt-treize !",
			"Quand je serai grand, je construirai un moulin." if boy else "Quand je serai grande, je construirai un moulin.", "C'est de la pluie de la surface. Moi, je n'ai jamais vu la pluie."]
		kid.line_every = Vector2(6.0, 10.0)
		papi = M.person("vieux", fx + fxf.x * 0.05, fz + fxf.z * 0.05, fyaw, "assis")
		papi.lines = ["Une goutte sur le genou chaque matin : c'est bon pour les articulations.", "Plic, ploc. Plus régulier qu'une horloge, et ça ne se remonte jamais.",
			"De mon temps, on n'avait pas de fuite. On avait une cascade. Dans la cuisine.", "Elle accélère, la goutte. Il doit pleuvoir fort, là-haut."]
		papi.line_every = Vector2(9.0, 14.0)
		var fr: Vector3 = Basis(Vector3.UP, deg_to_rad(fyaw)) * Vector3(1, 0, 0)
		var para2: Node3D = _fuite_parapluie(M, R.P(fx + fr.x * 0.55, 0.0, fz + fr.z * 0.55), false, col_para)
		para2.rotation = Vector3(0, deg_to_rad(fyaw), 0.18)
	mere.line_every = Vector2(9.0, 14.0)
	# qui vide les seaux : le père (sinon, la mère), d'où il part et comment il attend
	var porteur: Node = pere if pere != null else mere
	var porteur_home: Vector3 = R.P(phx, 0, phz) if pere != null else R.P(mx, 0, mz)
	var porteur_pose: String = "bras_croises" if pere != null else "jardiner"
	var porteur_face: Vector3 = Vector3(sx0 - phx, 0, sz0 - phz) if pere != null else Vector3(-s, 0, 0)
	var ph: Vector3 = porteur_home
	var hs: Vector3 = d_seau["home"]
	d_seau["pres"] = hs + Vector3(ph.x - hs.x, 0, ph.z - hs.z).normalized() * 0.5
	var soupirs: Array = ["Pfff… Et de quarante-trois.", "(Il soupire.) Vivement qu'il arrête de pleuvoir, à la surface.", "Pfff… Bon. Ça, c'est fait. Jusqu'au prochain.", "(Un long soupir.) Elle est bonne, cette eau. C'est déjà ça."]
	if pere == null:
		soupirs = ["Pfff… Et de quarante-trois.", "(Elle soupire.) Vivement qu'il arrête de pleuvoir, à la surface.", "Pfff… Bon. Ça, c'est fait. Jusqu'au prochain.", "(Un long soupir.) Elle est bonne, cette eau. C'est déjà ça."]
	var st := {"t": r.randf() * 10.0, "w": 2.0, "porteur": -1, "cd": 3.0, "verse": 0.0, "verse_i": -1, "plic": 2.0, "pp": true, "deb": 0.0,
		"cit": r.randf_range(0.45, 0.75)}
	# --- marcher jusqu'à un point (le corps glisse, la pose « marcher ») : la durée du trajet
	var marcher := func(f: Node, to: Vector3) -> float:
		var from: Vector3 = f.npc.global_position
		var to2 := Vector3(to.x, from.y, to.z)
		var dist: float = from.distance_to(to2)
		if dist < 0.05:
			return 0.0
		f.set_pose("marcher", to2 - from)
		var dur: float = clampf(dist / 0.75, 0.3, 5.0)
		var tw: Tween = M.room.create_tween()
		tw.tween_property(f.npc, "global_position", to2, dur)
		return dur
	# --- un récipient est plein : on va le chercher, on le porte à la citerne, on le vide (glouglou),
	# un soupir, on le remet à sa place… et ça recommence
	var vider_parent := func(i: int) -> void:
		var dd: Dictionary = drips[i]
		st["porteur"] = i
		var pres: Vector3 = dd["pres"]
		var home: Vector3 = dd["home"]
		var d1: float = marcher.call(porteur, pres)
		await M.get_tree().create_timer(d1 + 0.1).timeout
		if not _la(M, room0):
			return
		porteur.set_pose("bricoler", Vector3(home.x - pres.x, 0, home.z - pres.z))
		await M.get_tree().create_timer(0.7).timeout
		if not _la(M, room0):
			return
		dd["porte"] = true
		if str(dd["kind"]) == "seau":
			porteur.say(str(_pick(M, ["Allez, hop.", "Et un seau de plus…", "Encore lui ?"])), 2.5)
		else:
			porteur.say(str(_pick(M, ["La casserole, maintenant. Allez.", "Pas de soupe ce soir : la casserole est prise."])), 2.5)
		var d2: float = marcher.call(porteur, cit_pres)
		await M.get_tree().create_timer(d2 + 0.1).timeout
		if not _la(M, room0):
			return
		porteur.set_pose("bricoler", Vector3(cit_c.x - cit_pres.x, 0, cit_c.z - cit_pres.z))
		st["verse_i"] = i
		st["verse"] = 1.4
		M.main.sfx("verser", cit_top)
		_bulle(M, cit_top + Vector3(0, 0.35, 0), "Glouglouglou…", Color(0.75, 0.88, 1.0), 38, 0.45, 1.8)
		await M.get_tree().create_timer(1.5).timeout
		if not _la(M, room0):
			return
		st["verse"] = 0.0
		st["verse_i"] = -1
		dd["lvl"] = 0.0
		st["cit"] = minf(0.96, float(st["cit"]) + 0.04)
		porteur.say(str(_pick(M, soupirs)), 3.5)
		await M.get_tree().create_timer(0.9).timeout
		if not _la(M, room0):
			return
		var d3: float = marcher.call(porteur, pres)
		await M.get_tree().create_timer(d3 + 0.1).timeout
		if not _la(M, room0):
			return
		porteur.set_pose("bricoler", Vector3(home.x - pres.x, 0, home.z - pres.z))
		await M.get_tree().create_timer(0.5).timeout
		if not _la(M, room0):
			return
		dd["porte"] = false
		var c: Node3D = dd["cont"]
		c.global_position = home
		c.rotation = Vector3.ZERO
		var d4: float = marcher.call(porteur, porteur_home)
		await M.get_tree().create_timer(d4 + 0.1).timeout
		if not _la(M, room0):
			return
		porteur.set_pose(porteur_pose, porteur_face)
		st["porteur"] = -1
		st["cd"] = 5.0
		if randf() < 0.5:
			S._say_late(M, porteur, str(_pick(M, ["Et ça recommence…", "Plic. Bon. Ça recommence.", "Et voilà la suivante. Bonjour, la suivante."])), 2.5, 3.0)
	# --- la récompense (une seule fois) : le sirop de la Cascade, fait avec l'eau de la surface
	var recompense := func(parole: bool) -> void:
		M.bonne_action_v120()  ## V120 : une bonne action, l'île s'en souvient
		if bool(M.state().get("st_fuite", false)):
			return
		M.state()["st_fuite"] = true
		if nuit:
			M.say("Sur le couvercle de la citerne, une étiquette à la craie : « À qui videra un seau cette nuit : merci ! Servez-vous en sirop de la Cascade. » Une petite bouteille t'attend juste à côté.", 7.0)
			M.give([["sirop_cascade", 1]], "")
			return
		var txt: String = "Le sirop de la Cascade ! On fait bouillir l'eau de la surface sur le poêle, avec du sucre et des fleurs des Jardins. Tenez, goûtez : il a le goût de la pluie d'en haut." if parole else "Merci pour le seau ! Tenez, pour la peine : notre sirop de la Cascade. On fait bouillir l'eau de la surface sur le poêle, avec du sucre et des fleurs des Jardins. Il a le goût de la pluie d'en haut."
		M.talk(mere, txt, I._bye("Merci beaucoup !"), func(_i):
			M.give([["sirop_cascade", 1]], "")
			M.close_talk(), "reconnaissante")
	# --- vider soi-même un seau (ou la casserole) dans la citerne : la mère remercie
	var vider_joueur := func(i: int) -> void:
		var dd: Dictionary = drips[i]
		if float(dd["lvl"]) <= 0.15 or bool(dd["porte"]) or int(st["porteur"]) == i or float(dd["vide"]) > 0.0:
			return
		var seau: bool = str(dd["kind"]) == "seau"
		dd["vide"] = 0.9
		var c: Node3D = dd["cont"]
		var home: Vector3 = dd["home"]
		var tw: Tween = M.room.create_tween()
		tw.tween_property(c, "global_position", home + Vector3(0, 0.18, 0), 0.25).set_trans(Tween.TRANS_SINE)
		tw.tween_property(c, "global_position", home, 0.35).set_delay(0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		M.main.sfx("verser", cit_top)
		_bulle(M, cit_top + Vector3(0, 0.35, 0), "Glouglou !", Color(0.75, 0.88, 1.0), 40, 0.45, 1.6)
		st["cit"] = minf(0.96, float(st["cit"]) + 0.03)
		var premier: bool = not bool(M.state().get("st_fuite", false))
		if nuit:
			if seau:
				M.say("Sur la pointe des pieds, tu portes le seau jusqu'à la citerne. Glouglou… Personne ne se réveille. Enfin, presque : quelqu'un sourit en dormant.", 5.5)
			else:
				M.say("Sur la pointe des pieds, tu vides la casserole dans la citerne. Glouglou… Personne ne se réveille. Enfin, presque : quelqu'un sourit en dormant.", 5.5)
			S._say_late(M, mere, "Zzz… merci… zzz…", 1.6, 3.0)
			if premier:
				await M.get_tree().create_timer(6.0).timeout
				if not _la(M, room0):
					return
				recompense.call(false)
			return
		if seau:
			M.say(str(_pick(M, ["Tu soulèves le seau (il pèse son poids de ciel) et tu le vides dans la grande citerne. Glouglou !",
				"Hop ! Le seau dans la citerne. Glouglou. Au-dessus de toi, la goutte suivante se prépare déjà."])), 4.5)
		else:
			M.say(str(_pick(M, ["Tu vides la casserole dans la grande citerne. Glouglou ! La goutte suivante tombe aussitôt dedans : plic.",
				"Hop ! La casserole dans la citerne. Glouglou. Il y a de la soupe dans l'air… non, juste de la pluie."])), 4.5)
		var merci: Array = ["Oh, merci ! Un seau de moins avant le suivant.", "Merci ! Vous avez le coup de main, dites donc.", "Merci, c'est gentil ! La citerne vous dit merci aussi : glouglou."]
		if pere != null:
			merci.append("Merci ! Mon mari va être jaloux : d'habitude, c'est son seau.")
		S._say_late(M, mere, str(_pick(M, merci)), 1.0, 3.5)
		if premier:
			await M.get_tree().create_timer(2.8).timeout
			if not _la(M, room0):
				return
			recompense.call(false)
	# --- la main sous la goutte (la goutte suivante tombe dans ta paume) ; goûter l'eau de la surface
	var main_dit := func() -> void:
		if nuit:
			M.say(str(_pick(M, ["Plic ! Une goutte glacée te tombe dans la paume. Tu retiens un petit cri : tout le monde dort.",
				"Plic ! … Tu attends la suivante, la main tendue, dans le noir. Ploc. Elle a pris son temps."])), 5.0)
			S._say_late(M, papi, "Zzz… bon pour les articulations… zzz…", 1.4, 3.0)
			return
		M.say(str(_pick(M, ["Plic ! Une goutte froide te tombe pile dans la paume. Elle vient de traverser cent mètres de grès rien que pour te dire bonjour.",
			"Plic ! … Plic ! … Tu attends la troisième. Elle prend son temps. Les gouttes des Strates ne sont jamais pressées.",
			"Plic ! Elle est glacée ! Tu secoues ta main. Toute la famille te regarde en souriant : eux aussi, ils sont passés par là."])), 5.0)
		kid.gesture("rire", 2.0)
		S._say_late(M, kid, str(_pick(M, ["Ha ha ! Elle t'a eu !", "La prochaine fois, essaie avec le nez !", "Tu as de la chance : c'est de la vraie pluie de la surface !"])), 0.6, 3.0)
		S._say_late(M, papi, "Sur le genou, c'est encore meilleur.", 2.6, 3.0)
	var gouter := func() -> void:
		M.main.sfx("boire", R.P(bsx, 1.3, bsz))
		if nuit:
			M.say("Tout doucement, tu tends la langue sous la grosse goutte. Plic ! Elle a le goût du ciel… un ciel de nuit, tout frais, avec un fond d'étoiles.", 6.0)
			return
		M.say(str(_pick(M, ["Tu tends la langue sous la grosse goutte… Plic ! Elle a le goût du ciel : frais, léger, avec un petit fond de nuage.",
			"Une goutte sur la langue. Elle a le goût du ciel. Un ciel de pluie, qui a pris tout son temps pour descendre jusqu'ici.",
			"Plic ! Elle a le goût du ciel… et d'un tout petit peu de grès. Comme un ciel qui serait passé par la cave."])), 5.5)
		S._say_late(M, papi, str(_pick(M, ["Alors ? Le goût du ciel, hein ? Moi, je ne l'ai jamais vu, le ciel. Mais je connais son goût.", "Le goût du ciel ! On en fait du sirop, vous savez."])), 1.8, 4.5)
		S._say_late(M, kid, "Hé ! C'est la goutte de ma roue !", 0.8, 2.5)
	# --- ce qui bouge : les gouttes qui se forment et tombent, les ronds dans l'eau, les niveaux qui
	# montent, le seau qu'on porte et qu'on vide, la roue à aubes, les champignons qui respirent, la jauge
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(rotor):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		st["plic"] = float(st["plic"]) - dt
		st["deb"] = float(st["deb"]) - dt
		for i in range(drips.size()):
			var dd: Dictionary = drips[i]
			var kind: String = str(dd["kind"])
			var drop: MeshInstance3D = dd["drop"]
			var src: Vector3 = dd["src"]
			var a_contenant: bool = dd.has("cont")
			if str(dd["ph"]) == "forme":
				dd["t"] = float(dd["t"]) - dt
				var kf: float = clampf(1.0 - float(dd["t"]) / float(dd["per"]), 0.0, 1.0)
				drop.global_position = src + Vector3(0, -0.012 * kf, 0)
				drop.scale = Vector3.ONE * (0.35 + 0.65 * kf)
				if float(dd["t"]) <= 0.0:
					dd["ph"] = "tombe"
					dd["v"] = 0.0
			else:
				var v: float = float(dd["v"]) + 9.8 * dt
				dd["v"] = v
				var p: Vector3 = drop.global_position - Vector3(0, v * dt, 0)
				var hy: float = float(dd.get("hy", sol))
				if a_contenant:
					if bool(dd["porte"]):
						hy = sol + 0.004
					else:
						hy = (dd["home"] as Vector3).y + 0.012 + float(dd["lvl"]) * (float(dd["h"]) - 0.035)
				var main_la: bool = float(dd["main"]) > 0.0
				if main_la:
					hy = sol + 1.05
				if p.y > hy:
					drop.global_position = p
					drop.scale = Vector3(0.8, 1.6, 0.8)
				else:
					# plic ! la goutte arrive
					var hp := Vector3(src.x, hy, src.z)
					dd["ph"] = "forme"
					dd["t"] = float(dd["per"]) * randf_range(0.8, 1.25) * (1.8 if nuit else 1.0)
					drop.global_position = src
					drop.scale = Vector3.ONE * 0.35
					if main_la:
						dd["main"] = 0.0
						_bulle(M, hp + Vector3(0, 0.25, 0), "Plic !", Color(0.8, 0.92, 1.0), 52, 0.5, 1.6)
						M.main.sfx("bulles", hp)
						main_dit.call()
						continue
					if bool(dd.get("ring_ok", true)):
						var ring: MeshInstance3D = dd["ring"]
						ring.global_position = Vector3(src.x, float(dd.get("ry", hy)) + 0.003, src.z)
						dd["rt"] = 0.0
					if kind == "bassin":
						st["w"] = minf(6.0, float(st["w"]) + 0.9)
					if a_contenant and not bool(dd["porte"]):
						if float(dd["lvl"]) >= 1.0:
							if float(st["deb"]) <= 0.0:
								st["deb"] = 9.0
								_bulle(M, hp + Vector3(0, 0.3, 0), "Ça déborde !" if not nuit else "Flac…", Color(0.75, 0.88, 1.0), 34, 0.4, 1.8)
								if nuit:
									S._say_late(M, mere, "Zzz… le seau… déborde… zzz…", 1.0, 3.0)
								elif int(st["porteur"]) >= 0:
									porteur.say("J'arrive, j'arrive !", 2.5)
						else:
							dd["lvl"] = minf(1.0, float(dd["lvl"]) + float(dd["dl"]))
					if float(st["plic"]) <= 0.0:
						st["plic"] = randf_range(4.5, 7.0) if nuit else randf_range(2.6, 4.5)
						var txt: String
						if nuit:
							txt = "plic…" if bool(st["pp"]) else "ploc…"
						else:
							txt = str(["Plic !", "Ploc !", "Plic."][randi() % 3])
						st["pp"] = not bool(st["pp"])
						_bulle(M, hp + Vector3(0, 0.3, 0), txt, Color(0.75, 0.88, 1.0), 30 if nuit else 34, 0.35, 2.4 if nuit else 1.5)
						if randf() < 0.4:
							M.main.sfx("bulles", hp)
			# les ronds dans l'eau
			var rt: float = float(dd["rt"])
			var rg: MeshInstance3D = dd["ring"]
			if rt < 1.0:
				rt = minf(1.0, rt + dt * 1.5)
				dd["rt"] = rt
				rg.visible = true
				var sc: float = 0.6 + 2.2 * rt
				rg.scale = Vector3(sc, 1.0, sc)
				var rmat: StandardMaterial3D = dd["rm"]
				rmat.albedo_color.a = 0.75 * (1.0 - rt)
			else:
				rg.visible = false
			if not a_contenant:
				continue
			# le niveau d'eau du seau (ou de la casserole) ; porté, versé, vidé
			var lv: float = float(dd["lvl"])
			var c: Node3D = dd["cont"]
			if float(dd["vide"]) > 0.0:
				dd["vide"] = float(dd["vide"]) - dt
				lv = maxf(0.0, lv - dt * 1.4)
			if bool(dd["porte"]) and is_instance_valid(porteur):
				var b: Node3D = porteur.npc
				var fw: Vector3 = b.global_transform.basis.z
				fw = Vector3(fw.x, 0, fw.z).normalized()
				var mains: Vector3 = b.global_position + fw * 0.34 + Vector3(0, 0.5 if kind == "seau" else 0.85, 0)
				var vv: float = float(st["verse"])
				if int(st["verse_i"]) == i and vv > 0.0:
					st["verse"] = maxf(0.0, vv - dt)
					var k: float = clampf(1.0 - vv / 1.4, 0.0, 1.0)
					c.global_position = mains.lerp(rim, minf(1.0, k * 3.0))
					c.rotation = Vector3(1.9 * sin(PI * minf(1.0, k * 1.6)), b.rotation.y, 0)
					if k > 0.25:
						lv = maxf(0.0, lv - dt * 1.2)
				else:
					c.global_position = mains
					c.rotation = Vector3(0, b.rotation.y, 0)
			dd["lvl"] = lv
			var e: MeshInstance3D = dd["eau"]
			var hh: float = float(dd["h"])
			var ye: float = 0.012 + lv * (hh - 0.035)
			e.position.y = ye
			var re: float = lerpf(float(dd["rb"]), float(dd["rt_r"]), ye / hh) - 0.006
			e.scale = Vector3(re, 1.0, re)
			e.visible = lv > 0.01
		# la roue à aubes : un coup de pouce à chaque grosse goutte
		var w: float = move_toward(float(st["w"]), 1.4 if nuit else 2.0, dt * 0.6)
		st["w"] = w
		rotor.rotation.x -= w * dt
		# les champignons respirent (plus fort la nuit)
		for k2 in range(champ_m.size()):
			var cm: StandardMaterial3D = champ_m[k2]
			cm.emission_energy_multiplier = (2.2 if nuit else 1.2) * (1.0 + 0.25 * sin(t * 1.1 + k2 * 2.0))
		lum.light_energy = (0.75 if nuit else 0.35) * (1.0 + 0.15 * sin(t * 1.1))
		# la jauge de la citerne
		var lc: float = float(st["cit"])
		jauge.scale = Vector3(1.0, maxf(0.01, lc * 0.92), 1.0)
		jauge.global_position = jauge_bas + Vector3(0, lc * 0.46, 0)
		# un récipient plein : le père (ou la mère) va le vider
		st["cd"] = maxf(0.0, float(st["cd"]) - dt)
		if not nuit and int(st["porteur"]) < 0 and float(st["cd"]) <= 0.0 and is_instance_valid(porteur) and not bool(porteur.talking):
			for i2 in porte_ids:
				var d2: Dictionary = drips[int(i2)]
				if float(d2["lvl"]) >= 1.0 and float(d2["vide"]) <= 0.0:
					vider_parent.call(int(i2))
					break
	# --- ce qu'on fait : vider un seau, mettre la main sous la goutte, goûter l'eau de la surface
	for i3 in porte_ids:
		var dd3: Dictionary = drips[int(i3)]
		var lab: String = "E : vider le seau" if str(dd3["kind"]) == "seau" else "E : vider la casserole"
		var h3: Vector3 = dd3["home"]
		M.act(Vector3(h3.x, sol, h3.z), lab, vider_joueur.bind(int(i3)), 1.25, func(): return float(dd3["lvl"]) > 0.15 and not bool(dd3["porte"]) and int(st["porteur"]) != int(i3) and float(dd3["vide"]) <= 0.0)
	M.act(R.P(jx + s * 0.7, 0, jz + 0.15), "E : mettre la main sous la goutte", func() -> void:
		d_terre["main"] = 1.0
		if str(d_terre["ph"]) == "forme":
			d_terre["t"] = minf(float(d_terre["t"]), 0.3)
	, 1.2, func(): return float(d_terre["main"]) <= 0.0)
	M.act(R.P(bsx, 0, bsz), "E : goûter l'eau de la surface", gouter, 1.25)
	# --- les conversations : la mère, le grand-père, l'enfant, le père
	var mere_cb := func() -> void:
		if nuit:
			M.talk(mere, "Zzz… le seau… c'est ton tour… zzz…", I._bye("(La laisser dormir)"), I._close(M), "endormie")
			return
		M.talk(mere, str(_pick(M, ["Bonne descente ! Excusez le désordre : il pleut chez nous. Pas beaucoup. Juste assez pour mes champignons.",
			"Bonjour ! Mettez-vous où vous voulez, sauf sous les gouttes. Enfin, sauf si vous aimez ça.",
			"Bonne descente ! Ne faites pas attention aux seaux : ils font partie de la famille."])),
			[{"id": "ou", "label": "D'où vient l'eau ?"}, {"id": "boucher", "label": "Pourquoi ne pas boucher ?"}, {"id": "fermer", "label": "Bonne descente !"}], func(id):
			match id:
				"ou":
					M.talk(mere, "De la surface ! Quand il pleut sur Hautefond, l'eau descend tout doucement à travers le grès. Elle met des semaines à arriver. C'est la même eau que la Cascade des Jardins : notre plafond est juste sur son chemin.",
						[{"id": "sirop", "label": "Et qu'est-ce que vous en faites ?"}, {"id": "fermer", "label": "Quel voyage !"}], func(id2):
						if id2 == "sirop":
							if bool(M.state().get("st_fuite", false)):
								M.talk(mere, "On la boit, on arrose, et surtout, on en fait du sirop : le sirop de la Cascade. Vous y avez déjà goûté, je crois. Il est bon, hein ?", I._bye("Délicieux !"), I._close(M), "fière")
							else:
								recompense.call(true)
						else:
							M.close_talk()
					, "rêveuse")
				"boucher":
					M.talk(mere, "On a essayé ! Du mastic, de la cire, un bouchon de liège, et même le chewing-gum du petit. La goutte trouve toujours un autre chemin. Alors on a fait la paix : elle arrose mes champignons, et nous, on boit de l'eau du ciel." if boy else "On a essayé ! Du mastic, de la cire, un bouchon de liège, et même le chewing-gum de la petite. La goutte trouve toujours un autre chemin. Alors on a fait la paix : elle arrose mes champignons, et nous, on boit de l'eau du ciel.",
						[{"id": "guilde", "label": "La Guilde ne pourrait pas réparer ?"}, {"id": "fermer", "label": "Belle philosophie !"}], func(id3):
						if id3 == "guilde":
							M.talk(mere, "La Guilde est venue. Ils ont regardé le plafond, ils ont dit « Par les Strates ! », et ils nous ont offert un seau de plus. Un très beau seau, d'ailleurs.", I._bye("Ha ha !"), I._close(M), "amusée")
						else:
							M.close_talk()
					, "philosophe")
				_:
					M.close_talk()
		, "de bonne humeur")
	M.talk_spot(mere, mere_cb)
	var papi_cb := func() -> void:
		if nuit:
			M.talk(papi, "Zzz… plic… ploc… zzz… (Sous son parapluie, il sourit en dormant.)", I._bye("(Le laisser dormir)"), I._close(M), "endormi")
			return
		M.talk(papi, str(_pick(M, ["Bonne descente ! Asseyez-vous, écoutez : plic… ploc… C'est plus reposant que n'importe quelle berceuse.",
			"Ah, de la visite ! Attention à la goutte du milieu : c'est la mienne. Enfin, c'est celle de la roue du petit. Mais je l'ai vue le premier." if boy else "Ah, de la visite ! Attention à la goutte du milieu : c'est la mienne. Enfin, c'est celle de la roue de la petite. Mais je l'ai vue le premier."])),
			[{"id": "genou", "label": "C'est vraiment bon pour les articulations ?"}, {"id": "parapluie", "label": "Pourquoi ce parapluie ?"}, {"id": "fermer", "label": "À plus tard !"}], func(id):
			match id:
				"genou":
					M.talk(papi, "Absolument ! Une goutte de la surface sur le genou chaque matin, et je descends à la mine comme un jeune homme. Enfin, je n'y descends plus. Mais je pourrais.",
						[{"id": "preuve", "label": "Qui vous a dit ça ?"}, {"id": "fermer", "label": "Je vous crois !"}], func(id2):
						if id2 == "preuve":
							M.talk(papi, "Moi ! Quarante ans d'expérience : le genou gauche sous la goutte, le genou droit au sec. Résultat : le gauche va très bien. Le droit aussi, remarquez. L'expérience continue.", I._bye("Ha ha ! Bonne expérience !"), I._close(M), "malicieux")
						else:
							M.close_talk()
					, "très sérieux")
				"parapluie":
					M.talk(papi, "Pour la nuit ! Je dors ici, dans mon fauteuil. Et la nuit, les gouttes aiment changer de place, pour me faire une surprise. Alors j'ouvre mon parapluie. C'est le seul parapluie de toutes les Strates : j'en suis très fier.", I._bye("Il est très beau."), I._close(M), "fier")
				_:
					M.close_talk()
		, "de bonne humeur")
	M.talk_spot(papi, papi_cb)
	var kid_cb := func() -> void:
		if nuit:
			M.talk(kid, "Zzz… elle tourne… elle tourne… zzz…", I._bye("(Le laisser dormir)") if boy else I._bye("(La laisser dormir)"), I._close(M), "endormi" if boy else "endormie")
			return
		M.talk(kid, "C'est ma roue à aubes ! Je l'ai fabriquée tout seul, avec des cuillères en bois et un bouchon de citerne. Elle tourne toute seule, grâce à la pluie d'en haut." if boy else "C'est ma roue à aubes ! Je l'ai fabriquée toute seule, avec des cuillères en bois et un bouchon de citerne. Elle tourne toute seule, grâce à la pluie d'en haut.",
			[{"id": "sert", "label": "Elle sert à quoi ?"}, {"id": "fermer", "label": "Elle est super !"}], func(id):
			if id == "sert":
				M.talk(kid, "À rien ! Enfin si : quand elle tourne vite, c'est qu'il pleut fort à la surface. C'est mon pluviomètre. Tom Taraud dit que c'est le seul pluviomètre de la ville qui fait des bulles.", I._bye("C'est génial !"), I._close(M), "fier" if boy else "fière")
			else:
				M.close_talk()
		, "fier" if boy else "fière")
	M.talk_spot(kid, kid_cb)
	if pere != null:
		var pere_n: Node = pere
		var pere_cb := func() -> void:
			if nuit:
				M.talk(pere_n, "Rrron… pschhh… (Il dort à poings fermés.)", I._bye("(Le laisser dormir)"), I._close(M), "endormi")
				return
			M.talk(pere_n, str(_pick(M, ["Bonne descente ! Pardon, je ne vous regarde pas : je surveille le seau. Dès que je tourne la tête, il déborde.",
				"Bonjour ! Vous venez de la surface ? Alors c'est un peu votre pluie, tout ça. Vous ne pourriez pas lui dire de pleuvoir ailleurs ?"])),
				I._bye("Bon courage !"), I._close(M), "un peu las")
		M.talk_spot(pere_n, pere_cb)
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Tout le monde dort. Dans le noir, on n'entend plus que les gouttes : plic… dans le seau… ploc… dans le bassin.",
			"La maison dort. Les champignons lumineux veillent sous les gouttes, et dans son fauteuil, un grand-père ronfle sous un parapluie ouvert.",
			"Il fait nuit. Plic… ploc… Le seau se remplit tout doucement, la petite roue tourne toute seule, et personne ne se lève pour vider quoi que ce soit."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Plic… ploc… Dans cette maison, il pleut. Du plafond de grès, des gouttes tombent une à une dans des seaux et dans un bassin de cuivre. La famille a l'air de trouver ça parfaitement normal.",
			"« Attention où vous marchez, ça goutte ! » L'eau de pluie de la surface a traversé cent mètres de grès pour arriver ici. Des seaux, des champignons lumineux et une petite roue à aubes l'attendent.",
			"Une maison sous la fuite : des taches sombres au plafond, des gouttes qui tombent en mesure, une petite roue à aubes qui tourne sous la plus grosse. Plic, ploc. On s'y fait, paraît-il."]))


## Les matières de la maison sous la fuite (taches d'humidité, mousse, feuillages, sirop, eau).
static func _fuite_mats(M) -> void:
	var R = M.R
	if R.kit.mats.has("fu_tache"):
		return
	R._put("fu_tache", R._col(Color(0.2, 0.16, 0.13), 0.3))
	R._put("fu_mousse", R._col(Color(0.22, 0.4, 0.19), 0.95))
	R._put("fu_vert", R._col(Color(0.3, 0.56, 0.27), 0.8))
	R._put("fu_vert_clair", R._col(Color(0.48, 0.7, 0.33), 0.8))
	R._put("fu_sirop", R._col(Color(0.5, 0.76, 0.9), 0.15))
	R._put("fu_eau", R._col(Color(0.2, 0.34, 0.42), 0.05))
	R._put("fu_rouge", R._col(Color(0.82, 0.2, 0.16), 0.5))
	R._put("fu_jaune", R._col(Color(0.98, 0.78, 0.25), 0.5))


## La hauteur (repère de la pièce) d'où tombe une goutte en x : sous le plafond, ou sous une poutre
## (les poutres de maisons_pieces_v81._after_door).
static func _fuite_y0(M, x: float) -> float:
	var R = M.R
	var nb: int = maxi(2, int(R.W / 1.6))
	for i in range(nb):
		var bx: float = -R.W * 0.5 + R.W * (i + 0.5) / nb
		if absf(x - bx) < 0.16:
			return R.H - 0.252
	return R.H - 0.012


## Un endroit où ça goutte (repère de la pièce) : la tache d'humidité au plafond, la petite pointe de
## grès, la goutte qui s'y forme et qui tombe (per : le temps entre deux gouttes), le rond dans l'eau.
static func _fuite_goutte(M, x: float, z: float, kind: String, per: float, mesh: Mesh, m: Material) -> Dictionary:
	var R = M.R
	var ys: float = _fuite_y0(M, x)
	var poutre: bool = ys < R.H - 0.1
	R.kit.cyl(R.L(x, ys, z), 0.09 if poutre else 0.26, 0.09 if poutre else 0.26, 0.008, "fu_tache", 18)
	if not poutre:
		R.kit.cyl(R.L(x + 0.05, ys - 0.001, z - 0.03), 0.14, 0.14, 0.008, "fu_tache", 14)
	R.kit.cyl(R.L(x, ys - 0.05, z), 0.004, 0.028, 0.05, "mur", 8)
	var src: Vector3 = R.P(x, ys - 0.06, z)
	var drop: MeshInstance3D = _p(M.room, mesh, m, Vector3.ZERO)
	drop.global_position = src
	drop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tor := TorusMesh.new()
	tor.inner_radius = 0.034
	tor.outer_radius = 0.042
	tor.rings = 20
	tor.ring_segments = 4
	var rm := _verre(Color(0.85, 0.94, 1.0), 0.0, 0.3)
	var ring: MeshInstance3D = _p(M.room, tor, rm, Vector3.ZERO)
	ring.visible = false
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return {"kind": kind, "src": src, "per": per, "t": randf() * per, "ph": "forme", "v": 0.0, "drop": drop, "ring": ring, "rm": rm, "rt": 1.0,
		"main": 0.0}


## Un seau de fer (son anse) ou une casserole de cuivre (son manche), ouverts en haut, posés en `at`
## (monde) ; l'eau dedans est un disque qui monte. Rend {cont, eau, rb, rt_r, h, porte, vide, lvl}.
static func _fuite_recipient(M, at: Vector3, kind: String, eau_m: Material) -> Dictionary:
	var seau: bool = kind == "seau"
	var rb: float = 0.13 if seau else 0.12
	var rt: float = 0.16 if seau else 0.125
	var h: float = 0.3 if seau else 0.13
	var m: StandardMaterial3D = _mat(Color(0.3, 0.31, 0.33), 0.7, 0.45) if seau else _mat(Color(0.78, 0.45, 0.25), 0.9, 0.35)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var n: Node3D = I._node(M, at, 0.0)
	var corps: CylinderMesh = I._cyl(rt, rb, h, 20)
	corps.cap_top = false
	_p(n, corps, m, Vector3(0, h * 0.5, 0))
	var tor := TorusMesh.new()
	tor.inner_radius = rt - 0.007
	tor.outer_radius = rt + 0.007
	tor.rings = 20
	tor.ring_segments = 6
	_p(n, tor, m, Vector3(0, h, 0))
	if seau:
		# l'anse : un demi-cercle de fil de fer
		var fil := _mat(Color(0.25, 0.25, 0.27), 0.7, 0.4)
		var ra: float = rt + 0.004
		var nseg: int = 9
		for k in range(nseg):
			var a0: float = PI * k / nseg
			var a1: float = PI * (k + 1) / nseg
			var p0 := Vector2(cos(a0) * ra, sin(a0) * ra * 0.9)
			var p1 := Vector2(cos(a1) * ra, sin(a1) * ra * 0.9)
			var dv: Vector2 = p1 - p0
			_p(n, I._boxm(Vector3(dv.length() + 0.004, 0.007, 0.007)), fil, Vector3((p0.x + p1.x) * 0.5, h + (p0.y + p1.y) * 0.5, 0), Vector3.ONE, Vector3(0, 0, dv.angle()))
	else:
		_p(n, I._boxm(Vector3(0.22, 0.018, 0.035)), m, Vector3(rt + 0.11, h - 0.02, 0))
	var eau: MeshInstance3D = _p(n, I._cyl(1.0, 1.0, 0.008, 20), eau_m, Vector3(0, 0.02, 0), Vector3(rb, 1.0, rb))
	return {"cont": n, "eau": eau, "rb": rb, "rt_r": rt, "h": h, "porte": false, "vide": 0.0, "lvl": 0.0}


## La petite roue à aubes de l'enfant, au-dessus du bassin (hub : son moyeu, monde) : deux montants de
## bois plantés dans le bassin, un axe, huit aubes peintes (des cuillères en bois) qui tournent autour
## de l'axe (x). Rend {n, rotor}.
static func _fuite_roue(M, hub: Vector3) -> Dictionary:
	var n: Node3D = I._node(M, hub, 0.0)
	var bois := _mat(Color(0.36, 0.25, 0.17), 0.0, 0.75)
	var clair := _mat(Color(0.82, 0.68, 0.5), 0.0, 0.7)
	var fer := _mat(Color(0.25, 0.25, 0.27), 0.7, 0.4)
	for sx in [-1.0, 1.0]:
		_p(n, I._boxm(Vector3(0.025, 0.44, 0.03)), bois, Vector3(sx * 0.13, -0.2, 0))
	_p(n, I._cyl(0.01, 0.01, 0.32, 8), fer, Vector3.ZERO, Vector3.ONE, Vector3(0, 0, PI * 0.5))
	var rotor := Node3D.new()
	n.add_child(rotor)
	_p(rotor, I._cyl(0.04, 0.04, 0.1, 14), clair, Vector3.ZERO, Vector3.ONE, Vector3(0, 0, PI * 0.5))
	var cols: Array = [_mat(Color(0.86, 0.22, 0.17), 0.0, 0.5), _mat(Color(0.98, 0.8, 0.28), 0.0, 0.5)]
	for k in range(8):
		var bras := Node3D.new()
		rotor.add_child(bras)
		bras.rotation.x = TAU * k / 8.0
		_p(bras, I._boxm(Vector3(0.014, 0.18, 0.012)), clair, Vector3(0, 0.12, 0))
		_p(bras, I._boxm(Vector3(0.11, 0.075, 0.01)), cols[k % 2], Vector3(0, 0.2, 0))
	return {"n": n, "rotor": rotor}


## Un champignon lumineux (un pied clair, un chapeau qui brille) posé en `at` (monde), à l'échelle sc.
static func _fuite_champi(M, at: Vector3, sc: float, pied_m: Material, chap_m: Material) -> void:
	var n: Node3D = I._node(M, at, randf() * 360.0)
	n.scale = Vector3.ONE * sc
	_p(n, I._cyl(0.011, 0.016, 0.08, 8), pied_m, Vector3(0, 0.04, 0), Vector3.ONE, Vector3(randf_range(-0.15, 0.15), 0, randf_range(-0.15, 0.15)))
	_p(n, I._sph(0.042), chap_m, Vector3(0, 0.083, 0), Vector3(1.0, 0.45, 1.0))
	_sans_ombre(n)


## Le parapluie du grand-père (le seul parapluie de toutes les Strates), posé en `at` (monde) : ouvert
## (la nuit, au-dessus de sa tête) ou fermé (le jour, appuyé contre le fauteuil).
static func _fuite_parapluie(M, at: Vector3, ouvert: bool, col: Color) -> Node3D:
	var n: Node3D = I._node(M, at, 0.0)
	var toile := _mat(col, 0.0, 0.6)
	toile.cull_mode = BaseMaterial3D.CULL_DISABLED
	var fer := _mat(Color(0.2, 0.2, 0.22), 0.7, 0.4)
	var bois := _mat(Color(0.4, 0.26, 0.15), 0.0, 0.6)
	_p(n, I._cyl(0.007, 0.007, 0.95, 6), fer, Vector3(0, 0.475, 0))
	_p(n, I._cyl(0.016, 0.014, 0.12, 8), bois, Vector3(0, 0.05, 0))
	_p(n, I._boxm(Vector3(0.07, 0.025, 0.025)), bois, Vector3(0.03, -0.005, 0))
	if ouvert:
		_p(n, I._cyl(0.02, 0.62, 0.22, 20), toile, Vector3(0, 0.84, 0))
		_p(n, I._sph(0.014), fer, Vector3(0, 0.97, 0))
	else:
		_p(n, I._cyl(0.02, 0.07, 0.62, 12), toile, Vector3(0, 0.6, 0))
		_p(n, I._sph(0.012), fer, Vector3(0, 0.96, 0))
	_sans_ombre(n)
	return n


# =================================================================== le téléphone de roche

## (écrite à part)
# =================================================================== le téléphone de roche

## Les bulles des coups (un groupe de un à quatre coups) : ceux qui arrivent d'en haut (« tac »),
## ceux qu'on tape soi-même sur la pierre (« toc »).
const ROCHE_TAC := ["Tac !", "Tac-tac !", "Tac-tac-tac !", "Tac-tac-tac-tac !"]
const ROCHE_TOC := ["Toc !", "Toc-toc !", "Toc-toc-toc !", "Toc-toc-toc-toc !"]

## Les nouvelles de la surface (des coups d'en haut, de temps en temps, le jour) : [les groupes de
## coups, ce que la grand-mère traduit tout haut, ce que l'enfant dit en le notant].
const ROCHE_NOUVELLES := [
	[[2, 1, 3], "Ça dit : « Il pleut. Encore. » Trois jours de suite ! Là-haut, même les pigeons ont des bottes.", "Je note : pluie. Encore. J'ai écrit « encore » quarante fois."],
	[[1, 3, 1, 2], "Ça dit : « Le Bourgmestre a perdu son chapeau. » Le vent l'a posé sur une cheminée. Toute la ville est sortie le regarder.", "Le chapeau… du Bourgmestre… sur une cheminée. Noté !"],
	[[2, 2, 1], "Ça dit : « Un pigeon a volé un croissant au marché. » C'est Monsieur Plume, sûrement. Il a ses habitudes.", "Je le dessine, Monsieur Plume. Avec son croissant."],
	[[3, 1, 1, 2], "Ça dit : « Mathilde a forgé une casserole si grande qu'on peut s'asseoir dedans. » Je voudrais bien voir ça.", "Une casserole-fauteuil ! Noté !"],
	[[1, 1, 2], "Ça dit : « Pimprenelle a vérifié ce matin : le ciel est toujours là. » Elle vérifie tous les jours. Nous voilà rassurés.", "Ouf. Je note : ciel, toujours là."],
	[[3], "Trois coups : « Quelle heure est-il en bas ? » La même qu'en haut, voyons ! Ils posent la question tous les jours. Ils trouvent ça très drôle.", "Trois coups ! C'est la page un du carnet !"],
	[[2, 3, 2], "Ça dit : « Il fait beau. Un nuage ressemble à une chaussette. » Une chaussette ! Ils ont de la chance, là-haut.", "Je dessine la chaussette. Enfin, le nuage."],
]

## Les pages du carnet du code (pendu à un clou, à côté du cornet), dans l'ordre.
const ROCHE_CARNET := [
	"LE CODE DE LA ROCHE. Un coup : « oui ». Deux coups : « non ». Trois coups : « Quelle heure est-il en haut ? » (Ils répondent toujours : « La même qu'en bas. »)",
	"Trois coups VITE : « Boulon trouvé ! » C'est le code de Tom Taraud. Ne pas confondre avec l'heure. Mamie a confondu une fois : Pimprenelle a cherché l'heure partout. Elle a trouvé un boulon.",
	"Quatre coups : « On mange ! » Cinq coups : « On mange quoi ? » Six coups : « Encore de la soupe ? » (Cette ligne-là, Mamie l'a rayée. Trois fois.)",
	"Un long frottement : « Bonne nuit. » Deux longs frottements : « Bonne nuit, et ne tapez pas avant sept heures. » (Écrit en gros, et souligné.)",
	"LES NOUVELLES DE LA SURFACE. Lundi : il pleut. Mardi : il pleut. Mercredi : il pleut encore. Jeudi : le Bourgmestre a perdu son chapeau. Enfin du nouveau !",
	"Un dessin de pigeon, très appliqué. En dessous : « Monsieur Plume, le pigeon du Grand Marché, d'après les coups. Je ne l'ai jamais vu. Il est sûrement plus gros. »",
]


## Le grand cornet de laiton (un I._cyl évasé, matière « or ») qui sort du mur du fond, sa membrane
## tendue sur la bouche (elle vibre quand ça tape) ; la nuit, un chiffon dessus. Repère local : z sort
## du mur, vers la pièce. Renvoie {n, memb, bouche (monde)}.
static func _roche_cornet(M, at: Vector3, nuit: bool) -> Dictionary:
	var R = M.R
	var n: Node3D = I._node(M, at, 0)
	var laiton: Material = R.mat("or")
	var axe := Vector3(PI * 0.5, 0, 0)
	_p(n, I._cyl(0.055, 0.055, 0.24, 14), laiton, Vector3(0, 0, 0.12), Vector3.ONE, axe)
	_p(n, I._cyl(0.075, 0.075, 0.04, 14), laiton, Vector3(0, 0, 0.21), Vector3.ONE, axe)
	_p(n, I._cyl(0.27, 0.055, 0.5, 28), laiton, Vector3(0, 0, 0.47), Vector3.ONE, axe)
	_p(n, I._cyl(0.29, 0.29, 0.03, 28), laiton, Vector3(0, 0, 0.72), Vector3.ONE, axe)
	var memb := Node3D.new()
	n.add_child(memb)
	memb.position = Vector3(0, 0, 0.738)
	_p(memb, I._cyl(0.262, 0.262, 0.006, 28), _mat(Color(0.93, 0.84, 0.66), 0.0, 0.85), Vector3.ZERO, Vector3.ONE, axe)
	_p(memb, I._cyl(0.035, 0.035, 0.012, 12), laiton, Vector3(0, 0, 0.004), Vector3.ONE, axe)
	if nuit:
		# le chiffon à carreaux : un bonnet de nuit sur la bouche, un pan qui pend, un nœud
		var tissu: Material = R.mat("tissu_rouge")
		_p(n, I._cyl(0.31, 0.31, 0.05, 28), tissu, Vector3(0, 0, 0.752), Vector3.ONE, axe)
		_p(n, I._boxm(Vector3(0.6, 0.34, 0.012)), tissu, Vector3(0, -0.46, 0.77), Vector3.ONE, Vector3(0.12, 0, 0))
		_p(n, I._sph(0.06), tissu, Vector3(0, 0.3, 0.75), Vector3(1.4, 0.8, 0.8))
	n.rotation.x = 0.12
	return {"n": n, "memb": memb, "bouche": n.to_global(Vector3(0, 0, 0.8))}


## Le marteau de bois pendu à son crochet (le pivot), la tête posée contre la pierre de frappe.
static func _roche_marteau(M, at: Vector3) -> Node3D:
	var n: Node3D = I._node(M, at, 0)
	var bois := _mat(Color(0.55, 0.38, 0.22), 0.0, 0.7)
	var sombre := _mat(Color(0.32, 0.21, 0.13), 0.0, 0.75)
	_p(n, I._cyl(0.016, 0.018, 0.4, 8), bois, Vector3(0, -0.22, 0))
	_p(n, I._cyl(0.06, 0.06, 0.19, 14), sombre, Vector3(0, -0.46, 0), Vector3.ONE, Vector3(0, 0, PI * 0.5))
	_p(n, I._cyl(0.064, 0.064, 0.02, 14), _mat(Color(0.95, 0.75, 0.3), 1.0, 0.3), Vector3(0.07, -0.46, 0), Vector3.ONE, Vector3(0, 0, PI * 0.5))
	_p(n, I._cyl(0.064, 0.064, 0.02, 14), _mat(Color(0.95, 0.75, 0.3), 1.0, 0.3), Vector3(-0.07, -0.46, 0), Vector3.ONE, Vector3(0, 0, PI * 0.5))
	return n


## Un coup de marteau sur la pierre : il s'écarte, frappe (le son et la bulle « toc » au moment du choc).
static func _roche_frapper(M, m: Node3D, at: Vector3, txt: String) -> void:
	var tw: Tween = M.room.create_tween()
	tw.tween_property(m, "rotation:x", -0.55, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "rotation:x", 0.02, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		M.main.sfx("touche_bois", at)
		if txt != "":
			_bulle(M, at + Vector3(0, 0.35, 0.15), txt, Color(1.0, 0.9, 0.65), 40, 0.45, 1.5))
	tw.tween_property(m, "rotation:x", 0.0, 0.06)


## Un long frottement du marteau sur la pierre (« bonne nuit », dans le code).
static func _roche_frotter(M, m: Node3D, at: Vector3) -> void:
	var tw: Tween = M.room.create_tween()
	for a in [0.1, -0.1, 0.1, -0.1, 0.0]:
		tw.tween_property(m, "rotation:z", a, 0.26).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	M.main.sfx("touche_bois", at, -14.0)
	_bulle(M, at + Vector3(0, 0.35, 0.15), "Frrrrrt…", Color(0.9, 0.85, 0.75), 30, 0.4, 1.8)


## Une famille a installé dans le mur du fond un « téléphone de roche », comme celui de Tom Taraud :
## un grand cornet de laiton, sa membrane, la pierre de frappe et son marteau de bois, le carnet du
## code pendu à un clou ; une tige de laiton monte à travers la roche jusqu'à une cave de Hautefond,
## cent mètres plus haut. De temps en temps, des coups arrivent d'en haut (tac, tac-tac) : la
## grand-mère traduit tout haut les nouvelles de la surface, l'enfant les note dans son carnet. On peut
## taper un message (la réponse arrive deux secondes plus tard, en coups, puis traduite ; la première
## fois, un chocolat du mineur « pour la route jusqu'en haut »), coller l'oreille au cornet (le marché,
## la pluie, un pigeon, le vent), lire le carnet du code. La nuit, le cornet dort sous un chiffon,
## l'enfant dort, et la grand-mère chuchote que la surface dort aussi… sauf le phare.
static func _roche(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var nuit: bool = _nuit(M)
	var boy: bool = r.randf() < 0.5
	var zw: float = -hd
	var px: float = R.W * 0.06
	var yc: float = 1.45
	var face := Basis(Vector3.RIGHT, PI * 0.5)
	# --- le poêle dans le coin du fond, le lit de l'enfant contre le mur de gauche, l'étagère des
	# vieux carnets (cinquante ans de nouvelles) contre le mur de droite
	_foyer(M, maxf(-R.W * 0.4, -hw + 0.6))
	var lx: float = -hw + 1.06
	var lz: float = clampf(0.3, -hd + 1.6, hd - 2.4)
	R.lit(lx, lz, 90, 0.9, str(_pick(M, ["rouge", "bleu", "vert", "jaune"])))
	R.etagere(hw - 0.2, 0.2, -90, 1.2, 1.9, true)
	R.mark_wall(hw, 1.2, 0.2, 0.7)
	# --- le téléphone de roche : la rosace de laiton et ses rivets, la tige qui monte dans la roche
	# (vers Hautefond), la plaque gravée
	R.kit.cyl(R.L(px, yc, zw) * Transform3D(face, Vector3.ZERO), 0.34, 0.34, 0.03, "or", 28)
	R.kit.ring(R.L(px, yc, zw) * Transform3D(face, Vector3(0, 0, 0.03)), 0.2, 0.24, 0.012, "cuivre", 24)
	for k in range(12):
		var a: float = TAU * k / 12.0
		R.kit.cyl(R.L(px + cos(a) * 0.3, yc + sin(a) * 0.3, zw) * Transform3D(face, Vector3.ZERO), 0.014, 0.014, 0.045, "cuivre", 6)
	R.kit.cyl(R.L(px, yc + 0.3, zw + 0.06), 0.05, 0.05, 0.08, "or", 10)
	R.kit.cyl(R.L(px, yc + 0.36, zw + 0.06), 0.035, 0.035, R.H - yc - 0.36, "cuivre", 10, false)
	for yb in [yc + 0.75, R.H - 0.35]:
		R.kit.box(R.L(px, float(yb), zw + 0.035), Vector3(0.11, 0.03, 0.07), "fer", 1.0)
	R.kit.box(R.L(px, 2.1, zw + 0.1), Vector3(0.82, 0.13, 0.012), "or", 1.0)
	var plaque := Label3D.new()
	plaque.text = "HAUTEFOND : 100 m plus haut"
	plaque.font_size = 28
	plaque.pixel_size = 0.0017
	plaque.outline_size = 0
	plaque.modulate = Color(0.24, 0.15, 0.06)
	M.room.add_child(plaque)
	plaque.global_transform = R.L(px, 2.1, zw + 0.108)
	R.mark_wall(px, yc, zw, 0.45)
	R.mark_wall(px, 2.1, zw, 0.45)
	var corn_d: Dictionary = _roche_cornet(M, R.P(px, yc, zw + 0.03), nuit)
	var corn: Node3D = corn_d["n"]
	var memb: Node3D = corn_d["memb"]
	var memb_z0: float = memb.position.z
	var bouche: Vector3 = corn_d["bouche"]
	# --- la pierre de frappe (polie par cinquante ans de coups), le crochet et le marteau de bois
	var sx: float = px + 0.9
	R.kit.cyl(R.L(sx, 1.15, zw) * Transform3D(face, Vector3.ZERO), 0.17, 0.19, 0.022, "pierre_lisse", 18)
	R.kit.cyl(R.L(sx, 1.15, zw) * Transform3D(face, Vector3.ZERO), 0.08, 0.08, 0.026, "pierre", 14)
	R.kit.cyl(R.L(sx, 1.62, zw) * Transform3D(face, Vector3.ZERO), 0.012, 0.012, 0.12, "or", 6)
	R.mark_wall(sx, 1.3, zw, 0.3)
	var marteau: Node3D = _roche_marteau(M, R.P(sx, 1.62, zw + 0.1))
	var frappe_at: Vector3 = R.P(sx, 1.15, zw + 0.05)
	# --- le carnet du code, pendu à un clou par une ficelle
	var cx: float = px - 0.9
	R.kit.cyl(R.L(cx, 1.6, zw) * Transform3D(face, Vector3.ZERO), 0.008, 0.008, 0.06, "fer", 6)
	R.kit.box(R.L(cx, 1.49, zw + 0.035), Vector3(0.006, 0.2, 0.006), "papier", 1.0)
	var cxf: Transform3D = R.L(cx, 1.26, zw + 0.03) * Transform3D(Basis(Vector3.BACK, 0.07), Vector3.ZERO)
	R.kit.box(cxf, Vector3(0.18, 0.24, 0.03), "cuir", 1.0)
	R.kit.box(cxf * Transform3D(Basis(), Vector3(0, 0.03, 0.016)), Vector3(0.11, 0.05, 0.004), "papier", 1.0)
	R.mark_wall(cx, 1.3, zw, 0.25)
	var carnet_at: Vector3 = R.P(cx, 1.26, zw + 0.06)
	# --- le coin de la grand-mère (son fauteuil tourné vers le cornet, le guéridon, la lampe à
	# cristal, la théière), le tabouret de l'enfant, le tapis, des cadres
	R.tapis(px, -hd + 1.95, 0, minf(2.8, R.W - 3.0), 1.4)
	var ax: float = px - 1.55
	var az: float = -hd + 1.6
	var ayaw: float = _vers(ax, az, px, zw + 0.6)
	R.fauteuil(ax, az, ayaw, str(_pick(M, ["rouge", "vert", "brun", "bleu"])))
	R.kit.cyl(R.L(ax + 0.5, 0, az + 0.35), 0.13, 0.11, 0.18, "bois_clair", 12)
	R.kit.cyl(R.L(ax + 0.5, 0.17, az + 0.35), 0.07, 0.07, 0.08, "tissu_jaune", 10)
	var gx: float = px - 2.35
	var gz: float = -hd + 1.15
	if R.is_free(gx, gz, 0.55, 0.55):
		R.table_ronde(gx, gz, 0.26, 0.62)
		R.kit.cyl(R.L(gx - 0.08, 0.62, gz), 0.05, 0.06, 0.04, "fer", 10)
		R.kit.cyl(R.L(gx - 0.08, 0.66, gz), 0.035, 0.0, 0.16, "cristal", 6)
		R.kit.cyl(R.L(gx + 0.1, 0.62, gz + 0.04), 0.055, 0.045, 0.09, "ceramique", 12)
		R.kit.cyl(R.L(gx + 0.1, 0.71, gz + 0.04), 0.025, 0.005, 0.02, "ceramique", 8)
	var kx: float = px + 1.25
	var kz: float = -hd + 1.65
	R.tabouret(kx, kz)
	R.reserve(kx, kz, 0.5, 0.5)
	if R.is_free(hw - 0.5, hd - 1.9, 0.5, 0.5):
		R.plante(hw - 0.5, hd - 1.9)
	_cadres(M, 2)
	# --- les gens : le jour, la grand-mère tricote l'oreille tendue, l'enfant attend, son carnet sur
	# les genoux ; la nuit, l'enfant dort dans son lit et la grand-mère tricote encore, en chuchotant
	var gm: Node = M.person("vieille", ax, az, ayaw, "tricot")
	var kid: Node
	if nuit:
		gm.lines = ["Chut… tout dort. Même la surface.", "Là-haut aussi, on dort. Sauf le phare.", "Je tricote une chaussette pour le cornet. Il a froid, la nuit.", "Bonne nuit, la roche."]
		gm.line_every = Vector2(10.0, 15.0)
		kid = M.person("garcon" if boy else "fille", lx, lz, 90, "dormir")
		kid.lie(R.P(lx + 0.78, 0.5, lz), Vector3(-1, 0, 0))
		kid.lines = ["Zzz…", "Zzz… tac… tac-tac… zzz…", "Mmh… boulon trouvé… zzz…"]
		kid.line_every = Vector2(9.0, 14.0)
		R.kit.box(R.L(kx, 0.465, kz, 20.0), Vector3(0.16, 0.02, 0.22), "cuir", 1.0)
		R.kit.box(R.L(kx + 0.03, 0.48, kz + 0.02, 70.0), Vector3(0.12, 0.008, 0.008), "bois_clair", 1.0)
	else:
		gm.lines = ["Chut… j'écoute la roche.", "Encore la pluie, je parie.", "Cinquante ans que je tape. J'ai le poignet en grès.", "Tapez doucement, la roche n'est pas sourde.", "Là-haut, ils ont un ciel. Nous, on a un plafond qui ne fuit jamais."]
		gm.line_every = Vector2(9.0, 14.0)
		kid = M.person("garcon" if boy else "fille", kx, kz, _vers(kx, kz, px, zw + 0.6), "lire")
		kid.lines = ["Tac… tac-tac… Je note !", "Mamie, ça a tapé ? Non ? Bon.", "J'ai fini mon carnet numéro trois !", "Tom Taraud tape plus vite que moi. Pour l'instant.", "En haut, il pleut tout le temps. C'est dans le carnet."]
		kid.line_every = Vector2(7.0, 12.0)
	# --- la cadence des coups : une seule liste d'événements [quand, quoi, donnée], lue par le tick
	# (« in » : un coup qui arrive d'en haut, « out » : un coup qu'on tape, « son » : un bruit de la
	# surface dans le cornet, « call » : la suite de l'histoire)
	var st := {"t": 0.0, "ev": [], "occupe": false, "vib": 0.0, "ecoute": 0.0, "ni": r.randi() % ROCHE_NOUVELLES.size(), "page": 0, "eco": r.randi() % 4,
		"prochain": r.randf_range(32.0, 48.0) if nuit else r.randf_range(7.0, 11.0)}
	var trier := func(a, b) -> bool:
		return float(a[0]) < float(b[0])
	var planifier := func(code: Array, kind: String, t0: float, ecart: float) -> float:
		var ev: Array = st["ev"]
		var t: float = t0
		for g in code:
			for k2 in range(int(g)):
				ev.append([t, kind, int(g) if k2 == 0 else 0])
				t += ecart
			t += 0.7
		ev.sort_custom(trier)
		return t - 0.7
	var plus_tard := func(at: float, cb: Callable) -> void:
		var ev: Array = st["ev"]
		ev.append([at, "call", cb])
		ev.sort_custom(trier)
	var son := func(at: float, nom: String, db: float) -> void:
		var ev: Array = st["ev"]
		ev.append([at, "son", [nom, db]])
		ev.sort_custom(trier)
	var coup_in := func(g: int) -> void:
		st["vib"] = 1.0
		M.main.sfx("touche_bois", bouche, -9.0 if nuit else -2.0)
		if g <= 0:
			return
		var txt: String = "tac…" if nuit else str(ROCHE_TAC[mini(g, 4) - 1])
		_bulle(M, bouche + Vector3(r.randf_range(-0.25, 0.25), 0.3, 0.1), txt, Color(1.0, 0.86, 0.5), 28 if nuit else 40, 0.45, 1.5)
	var liberer := func() -> void:
		st["occupe"] = false
		st["prochain"] = r.randf_range(40.0, 60.0) if nuit else r.randf_range(24.0, 38.0)
	# l'enfant note (le crayon gratte)
	var noter := func() -> void:
		if is_instance_valid(kid) and not nuit:
			_bulle(M, kid.npc.global_position + Vector3(0, 1.35, 0), "Scritch, scritch…", Color(0.92, 0.92, 0.85), 30, 0.35, 1.6)
	# la grand-mère traduit tout haut ; l'enfant le note
	var traduire := func(dit: String, note: String) -> void:
		gm.say(dit, 6.5)
		if r.randf() < 0.5:
			gm.gesture("rire", 1.8)
		S._say_late(M, kid, note, 3.4, 3.5)
		plus_tard.call(float(st["t"]) + 3.0, noter)
	# la récompense (une fois) : un chocolat du mineur, pour la route jusqu'en haut
	var recompense := func() -> void:
		M.bonne_action_v120()  ## V120 : une bonne action, l'île s'en souvient
		if bool(M.state().get("st_roche", false)):
			return
		M.state()["st_roche"] = true
		var txt: String = "Chut… Vous avez dit bonne nuit à toute la surface, et le phare vous a répondu. Tenez, tout bas : un chocolat du mineur. Pour la route jusqu'en haut, demain." if nuit else "Votre premier message à travers cent mètres de roche ! Ça se fête. Tenez : un chocolat du mineur. Pour la route jusqu'en haut : c'est long, cent mètres, quand on monte."
		M.talk(gm, txt, I._bye("Merci… Bonne nuit !") if nuit else I._bye("Merci beaucoup !"), func(_i):
			M.give([["chocolat_mineur", 1]], "")
			M.close_talk(), "à voix basse" if nuit else "fière")
	# --- une nouvelle d'en haut (le jour) : les coups, l'enfant qui s'agite, la traduction
	var nouvelle := func() -> void:
		var i: int = int(st["ni"]) % ROCHE_NOUVELLES.size()
		st["ni"] = i + 1
		var nv: Array = ROCHE_NOUVELLES[i]
		st["occupe"] = true
		var t0: float = float(st["t"]) + 0.2
		var t1: float = planifier.call(nv[0], "in", t0, 0.24)
		plus_tard.call(t0 + 0.4, func() -> void:
			kid.say(str(_pick(M, ["Ça tape ! Mamie, ça tape !", "Chut ! Un message d'en haut !", "Tac… tac-tac… Ça vient de la surface !"])), 2.5))
		plus_tard.call(t1 + 0.7, traduire.bind(str(nv[1]), str(nv[2])))
		plus_tard.call(t1 + 4.5, liberer)
	# --- la nuit, de temps en temps : un seul petit coup, celui du phare
	var phare := func() -> void:
		st["occupe"] = true
		var t0: float = float(st["t"]) + 0.1
		(st["ev"] as Array).append([t0, "in", 1])
		plus_tard.call(t0 + 1.2, func() -> void:
			gm.say(str(_pick(M, ["Un coup… C'est le phare. Margot dit qu'elle est là.", "Vous avez entendu ? Un seul petit coup. La gardienne du phare ne dort jamais."])), 4.5))
		plus_tard.call(t0 + 2.6, func() -> void:
			kid.say("Zzz… tac… zzz…", 3.0))
		plus_tard.call(t0 + 3.5, liberer)
	# --- taper un message (le jour) : les coups qu'on tape, deux secondes, la réponse, la traduction
	var envoyer := func(id: String) -> void:
		var out: Array = [1, 3, 2]
		var rep: Array = [3]
		var ecart: float = 0.12
		var dit: String = "Trois petits coups très vite : c'est Pimprenelle elle-même ! Dans le code de Tom, ça veut dire « Boulon trouvé ! ». Elle en trouve un par jour."
		var note: String = "Je note : boulon trouvé. Tom va être jaloux. Ou content. Les deux."
		if id == "bonjour":
			out = [2, 2, 1]
			rep = [1, 1, 2]
			ecart = 0.24
			dit = str(_pick(M, ["Ils répondent : « Bonjour d'en haut ! Bonne descente ! » Ils ont appris notre politesse. C'est mignon.",
				"Ils répondent : « Bonjour à vous ! Il pleut. » Ils donnent toujours la météo. Même quand on ne demande rien."]))
			note = "Je note : « Bonjour ! » Avec un point d'exclamation."
		elif id == "temps":
			out = [3, 1, 2]
			rep = [2, 1, 3]
			ecart = 0.24
			dit = str(_pick(M, ["Ils répondent : « Il pleut. Encore. » Comme hier. Et avant-hier. Et le jour d'avant.",
				"Ils répondent : « Grand soleil, et un arc-en-ciel au-dessus du Port des Cordages. » Un arc-en-ciel ! Il faudra qu'on monte voir ça.",
				"Ils répondent : « Du vent. Le Bourgmestre court après son chapeau. » Encore ! Il devrait l'attacher avec une ficelle."]))
			note = "Je note la météo d'en haut. C'est mon travail."
		st["occupe"] = true
		kid.say(str(_pick(M, ["Je note ce qu'on envoie !", "Tapez fort, la roche est épaisse !", "Doucement… ils ont des oreilles, là-haut."])), 2.5)
		var t0: float = float(st["t"]) + 0.5
		var t1: float = planifier.call(out, "out", t0, 0.3)
		var t2: float = planifier.call(rep, "in", t1 + 2.0, ecart)
		plus_tard.call(t1 + 2.3, func() -> void:
			kid.say(str(_pick(M, ["Ça répond ! Ça répond !", "Chut ! La réponse !", "Ils ont entendu !"])), 2.2))
		plus_tard.call(t2 + 0.7, traduire.bind(dit, note))
		plus_tard.call(t2 + 4.4, recompense)
		plus_tard.call(t2 + 4.6, liberer)
	# --- la nuit, on ne tape qu'un long frottement : « bonne nuit » (le phare répond)
	var frotter := func() -> void:
		st["occupe"] = true
		var t0: float = float(st["t"]) + 0.4
		plus_tard.call(t0, func() -> void:
			_roche_frotter(M, marteau, frappe_at))
		var t1: float = t0 + 1.4 + 2.0
		(st["ev"] as Array).append([t1, "in", 1])
		(st["ev"] as Array).sort_custom(trier)
		plus_tard.call(t1 + 1.0, func() -> void:
			gm.say("Un seul petit coup… C'est Margot, la gardienne du phare. Un coup, ça veut dire « oui ». Oui, bonne nuit.", 5.0))
		plus_tard.call(t1 + 4.6, recompense)
		plus_tard.call(t1 + 4.8, liberer)
	var taper := func() -> void:
		if bool(st["occupe"]):
			return
		if nuit:
			M.talk(gm, "Chut… La nuit, on ne tape qu'une chose : un long frottement, tout doux. Ça veut dire « bonne nuit ».",
				[{"id": "frotter", "label": "Frotter « bonne nuit »"}, {"id": "fermer", "label": "(Ne réveiller personne)"}], func(id):
				M.close_talk()
				if id == "frotter":
					frotter.call()
			, "à voix basse")
			return
		M.talk(gm, str(_pick(M, ["Vous voulez taper un message ? Prenez le marteau. Qu'est-ce qu'on leur dit ?", "À vous ! Tapez sur la pierre, pas sur le cornet. Qu'est-ce qu'on envoie ?"])),
			[{"id": "bonjour", "label": "« Bonjour ! »"}, {"id": "temps", "label": "« Quel temps fait-il en haut ? »"}, {"id": "pimprenelle", "label": "« Dites bonjour à Pimprenelle ! »"}, {"id": "fermer", "label": "Rien, finalement."}], func(id):
			M.close_talk()
			if str(id) != "fermer":
				envoyer.call(str(id))
		, "ravie")
	# --- coller l'oreille au cornet : on entend la surface (le marché, la pluie, un pigeon, le vent)
	var ecouter := func() -> void:
		if bool(st["occupe"]):
			return
		st["ecoute"] = 3.5
		if nuit:
			M.main.sfx("bourrasque", bouche, -14.0)
			M.say(str(_pick(M, ["Tu soulèves un coin du chiffon et tu colles l'oreille au cornet. Rien… puis, très loin, un souffle : le vent de la nuit sur les toits de Hautefond. Tout dort, là-haut.",
				"Tu soulèves un coin du chiffon. Tout au fond du cornet, le silence. Un silence de cent mètres d'épaisseur. Hautefond dort."])), 6.0)
			S._say_late(M, gm, str(_pick(M, ["Chut… La surface dort aussi. Toute la ville. Sauf le phare.", "Vous entendez ? Rien. Là-haut, tout le monde dort. Sauf la gardienne du phare."])), 2.5, 4.5)
			return
		var k: int = int(st["eco"]) % 4
		st["eco"] = k + 1
		var t0: float = float(st["t"])
		var haut: Vector3 = bouche + Vector3(0, 0.35, 0.1)
		match k:
			0:
				M.main.sfx("clochette", bouche, -6.0)
				son.call(t0 + 1.3, "clochette", -8.0)
				_bulle(M, haut, "Des choux ! Des beaux choux !", Color(0.95, 0.92, 0.8), 30, 0.4, 2.2)
				M.say("Tu colles l'oreille au cornet. Tout au fond, très loin : une clochette, des cris de marchands, quelqu'un qui marchande un chou. C'est le Grand Marché de Hautefond, cent mètres plus haut.", 6.5)
				S._say_late(M, kid, "C'est le marché ! Des fois, on entend les choux rouler.", 3.0, 3.5)
			1:
				M.main.sfx("verser", bouche, -10.0)
				son.call(t0 + 1.6, "verser", -12.0)
				_bulle(M, haut, "Plic… ploc…", Color(0.75, 0.88, 1.0), 32, 0.4, 2.0)
				M.say("Tu colles l'oreille au cornet. Plic, ploc, plic… Il pleut sur Hautefond : sur les toits, sur les pavés, sur les parapluies. Ici, au sec, ça fait un bruit de bouilloire.", 6.5)
				S._say_late(M, kid, "Il pleut ! Je le savais. Je note : pluie. Encore.", 3.0, 3.5)
			2:
				M.main.sfx("pigeon", bouche, -4.0)
				son.call(t0 + 1.5, "pigeon", -6.0)
				_bulle(M, haut, "Rrrou ! Rrrou !", Color(0.85, 0.85, 0.95), 34, 0.4, 2.0)
				M.say("Tu colles l'oreille au cornet. Rrrou, rrrou… Un pigeon ! Il doit se promener juste au-dessus de la tige, quelque part sur une place de Hautefond.", 6.5)
				S._say_late(M, gm, "C'est Monsieur Plume. Il roucoule tous les jours à la même heure. Il a ses habitudes.", 3.0, 4.0)
			_:
				M.main.sfx("bourrasque", bouche, -6.0)
				_bulle(M, haut, "Fffouuuh…", Color(0.85, 0.95, 1.0), 34, 0.4, 2.0)
				M.say("Tu colles l'oreille au cornet. Fffouuuh… Le vent souffle là-haut, dans les rues de Hautefond. Il fait chanter la tige de laiton comme une flûte.", 6.5)
				S._say_late(M, kid, "Le vent ! Pourvu que le Bourgmestre tienne son chapeau !", 3.0, 3.5)
	# --- lire le carnet du code (page après page)
	var lire := func() -> void:
		var i: int = int(st["page"]) % ROCHE_CARNET.size()
		st["page"] = i + 1
		M.main.sfx("ui_ouvrir", carnet_at)
		M.say(str(ROCHE_CARNET[i]), 9.0)
		if nuit:
			if i == 0:
				S._say_late(M, gm, "Chut… Tournez les pages tout doucement. Elles froissent.", 1.5, 3.5)
		elif r.randf() < 0.6:
			S._say_late(M, kid, str(_pick(M, ["C'est moi qui ai dessiné le pigeon !", "Le code, c'est Mamie et Tom qui l'ont inventé. Surtout Tom.", "La page des six coups, Mamie l'a rayée. Moi, je la connais par cœur."])), 2.5, 3.5)
	# --- ce qui bouge : les coups (la cadence), la membrane qui vibre, le cornet qui frémit ; et de
	# temps en temps, une nouvelle d'en haut (le jour) ou le petit coup du phare (la nuit)
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(corn):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var ev: Array = st["ev"]
		while not ev.is_empty() and float(ev[0][0]) <= t:
			var e: Array = ev.pop_front()
			match str(e[1]):
				"in":
					coup_in.call(int(e[2]))
				"out":
					var g: int = int(e[2])
					_roche_frapper(M, marteau, frappe_at, str(ROCHE_TOC[mini(g, 4) - 1]) if g > 0 else "")
				"son":
					M.main.sfx(str(e[2][0]), bouche, float(e[2][1]))
				"call":
					(e[2] as Callable).call()
		var v: float = float(st["vib"]) * exp(-dt * 5.0)
		if float(st["ecoute"]) > 0.0:
			st["ecoute"] = float(st["ecoute"]) - dt
			v = maxf(v, 0.25)
		st["vib"] = v
		memb.position.z = memb_z0 + 0.008 * v * sin(t * 63.0)
		memb.scale = Vector3(1.0 + 0.03 * v * sin(t * 51.0), 1.0 + 0.03 * v * sin(t * 51.0 + 1.3), 1.0)
		corn.rotation.z = 0.012 * v * sin(t * 47.0)
		if bool(st["occupe"]) or bool(gm.talking):
			return
		st["prochain"] = float(st["prochain"]) - dt
		if float(st["prochain"]) > 0.0:
			return
		if nuit:
			phare.call()
		else:
			nouvelle.call()
	M.act(R.P(sx, 0, zw + 0.95), "E : taper un message", taper, 0.95, func(): return not bool(st["occupe"]))
	M.act(R.P(px, 0, zw + 1.0), "E : coller l'oreille au cornet", ecouter, 0.95, func(): return not bool(st["occupe"]))
	M.act(R.P(cx, 0, zw + 0.95), "E : lire le carnet du code", lire, 0.95)
	# --- les conversations
	var gm_cb := func() -> void:
		if nuit:
			M.talk(gm, "Chut… Le cornet dort, sous son chiffon. Le petit aussi. Et là-haut, la surface dort aussi. Toute la ville. Sauf le phare." if boy else "Chut… Le cornet dort, sous son chiffon. La petite aussi. Et là-haut, la surface dort aussi. Toute la ville. Sauf le phare.",
				[{"id": "phare", "label": "Sauf le phare ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if id == "phare":
					M.talk(gm, "Margot, la gardienne du phare, ne dort jamais. Des fois, la nuit, elle tape un seul petit coup. Un coup : « oui ». Je crois qu'elle veut juste dire qu'elle est là.", I._bye("Bonne nuit, Margot…"), I._close(M), "à voix basse")
				else:
					M.close_talk()
			, "à voix basse")
			return
		M.talk(gm, str(_pick(M, ["Bonne descente ! Entrez, entrez. Vous tombez bien : la surface est bavarde, aujourd'hui.",
			"Chut… Ah, ce n'est que vous. Bonjour ! J'ai cru que c'était un message.",
			"Par les Strates, de la visite ! Asseyez-vous… Enfin, pas sur le cornet."])),
			[{"id": "comment", "label": "Comment ça marche ?"}, {"id": "qui", "label": "Qui tape, là-haut ?"}, {"id": "fermer", "label": "Bonne descente !"}], func(id):
			match id:
				"comment":
					M.talk(gm, "Une tige de laiton traverse la roche jusqu'à une cave de Hautefond. On tape sur la pierre, ça monte ; ils tapent en haut, ça descend, et le cornet nous le chante. Comme Tom Taraud, sauf que lui colle l'oreille directement sur la roche.",
						[{"id": "vrai", "label": "Et ça marche vraiment ?"}, {"id": "fermer", "label": "Incroyable !"}], func(id2):
						if id2 == "vrai":
							M.talk(gm, "Depuis cinquante ans ! Bon, une fois, on a cru recevoir « Au secours ! ». C'était Berthe qui cassait des noix. On a ri pendant une semaine.", I._bye("Ha ha !"), I._close(M), "malicieuse")
						else:
							M.close_talk()
					, "fière")
				"qui":
					M.talk(gm, "Mon amie Berthe. On était à l'école ensemble, ici, en bas. Puis elle est montée vivre à Hautefond. Depuis, on se raconte tout. À coups de marteau.",
						[{"id": "revue", "label": "Vous ne vous êtes jamais revues ?"}, {"id": "fermer", "label": "Quelle belle amitié."}], func(id2):
						if id2 == "revue":
							M.talk(gm, "Si ! Depuis que la Ligne a rouvert, elle descend le dimanche. On s'assoit côte à côte… et on se tape des messages sur la table. Par habitude. Les gens nous trouvent bizarres.", I._bye("C'est très joli."), I._close(M), "émue")
						else:
							M.close_talk()
					, "émue")
				_:
					M.close_talk()
		, "ravie")
	M.talk_spot(gm, gm_cb)
	var kid_cb := func() -> void:
		if nuit:
			M.talk(kid, "Zzz… tac… tac-tac… Mamie… ils ont dit… boulon trouvé… zzz…", I._bye("(Le laisser dormir)") if boy else I._bye("(La laisser dormir)"), I._close(M), "endormi" if boy else "endormie")
			return
		M.talk(kid, "C'est moi qui note tout ! J'en suis à mon troisième carnet. Mamie dit que je suis la mémoire de la famille.",
			[{"id": "tom", "label": "Tu connais Tom Taraud ?"}, {"id": "haut", "label": "Tu es déjà monté en haut ?" if boy else "Tu es déjà montée en haut ?"}, {"id": "fermer", "label": "Je te laisse noter !"}], func(id):
			match id:
				"tom":
					M.talk(kid, "Tom ? C'est lui qui tape le mieux de toutes les Strates ! Il parle avec Pimprenelle, en haut. Il dit que ce n'est pas son amoureuse. Il devient tout rouge quand il le dit.", I._bye("Ha ha ! Je vois."), I._close(M), "malicieux" if boy else "malicieuse")
				"haut":
					M.talk(kid, "Pas encore. Mamie dit que le ciel, c'est comme un plafond, mais très haut et tout bleu. Moi, je crois qu'il est en couches, comme la roche : bleu clair, bleu moyen, bleu foncé.", I._bye("Tu verras bientôt !"), I._close(M), "rêveur" if boy else "rêveuse")
				_:
					M.close_talk()
		, "fier" if boy else "fière")
	M.talk_spot(kid, kid_cb)
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Un chiffon couvre le grand cornet de laiton : le téléphone de roche dort. L'enfant aussi, dans son lit. La grand-mère tricote encore, tout bas, près du poêle.",
			"Il fait nuit. Le cornet dort sous son chiffon, l'enfant dort sous sa couverture. Une grand-mère te fait « chut » sans lâcher son tricot.",
			"La maison dort. Seul le poêle ronronne. Sur le mur du fond, le grand cornet de laiton porte un chiffon, comme un bonnet de nuit."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Dans le mur du fond, un grand cornet de laiton sort de la roche comme une fleur de cuivre. Dessous, une grand-mère tricote, l'oreille tendue ; un enfant attend, un carnet sur les genoux.",
			"Tac… tac-tac… Le bruit vient d'un grand cornet de laiton planté dans la roche. « Chut ! » fait une grand-mère. « C'est la surface qui parle. »",
			"Un poêle qui ronfle… et, dans le mur, un téléphone de roche : un cornet de laiton, un marteau de bois, un carnet du code pendu à un clou. Ici, on parle avec Hautefond, cent mètres plus haut."]))
