extends RefCounted
## V118 : les histoires des maisons de la Fronde, le quartier libre des Strates, au-delà du Pont des
## Frondeurs (maisons_v81 ; style « fronde » : un conteneur ou une chaudière, de la tôle peinte
## écaillée, des planches de palette, des poutrelles, un poêle, des affiches de concert partout).
## Les pièces sont PETITES : 6,1 × 2,44 m pour un conteneur (un couloir !), 4,6 × 6 m pour une
## chaudière ; chaque histoire lit R.W et R.D et tient dans les deux.
## En plus des histoires communes (maisons_scenes_v81), cinq histoires à elles : le groupe des
## casseroles (Les Petites Soupapes), le robot de ferraille, l'atelier de skates, la maison peinte,
## la chaudière qui respire.
## Chaque histoire : ses meubles, ses gens (et leur nuit : on dort, on chuchote), ce qui bouge (un seul
## M.ctx["tick"] par maison), ce qu'on y fait, et ce dont la maison se souvient (M.state() : une
## récompense une seule fois). Jamais d'alcool, jamais de violence : de l'entraide, du bricolage, de
## la musique, des couleurs.
## M : maisons_v81 ; S : maisons_scenes_v81 (les aides communes) ; I : maisons_iles_v82 (_part, _node…).

const S = preload("res://scripts/maisons_scenes_v81.gd")
const I = preload("res://scripts/maisons_iles_v82.gd")

## [id, poids, {style: [styles où elle peut arriver]}]
const SCENARIOS := [
	["fr_casseroles", 12, {"style": ["fronde"]}], ["fr_robot", 11, {"style": ["fronde"]}],
	["fr_planche", 11, {"style": ["fronde"]}], ["fr_murs", 10, {"style": ["fronde"]}],
	["fr_vapeur", 11, {"style": ["fronde"]}],
]

static var _rond: Texture2D


static func has(sc: String) -> bool:
	for e in SCENARIOS:
		if str(e[0]) == sc:
			return true
	return false


static func build(M, sc: String) -> void:
	_fronde_mats(M)
	match sc:
		"fr_casseroles":
			_casseroles(M)
		"fr_robot":
			_robot(M)
		"fr_planche":
			_planche(M)
		"fr_murs":
			_murs(M)
		"fr_vapeur":
			_vapeur(M)


## Les couleurs de la Fronde (la peinture vive sur la tôle), et les verts des plantes (pour _pot).
static func _fronde_mats(M) -> void:
	var R = M.R
	if R.kit.mats.has("fr_rouge"):
		return
	R._put("fr_rouge", R._col(Color(0.86, 0.2, 0.16), 0.5, 0.3))
	R._put("fr_jaune", R._col(Color(0.98, 0.78, 0.2), 0.5, 0.3))
	R._put("fr_bleu", R._col(Color(0.2, 0.5, 0.86), 0.5, 0.3))
	R._put("fr_vert", R._col(Color(0.3, 0.7, 0.36), 0.5, 0.3))
	R._put("fr_rose", R._col(Color(0.95, 0.45, 0.65), 0.5, 0.3))
	R._put("fr_rouille", R._col(Color(0.55, 0.3, 0.18), 0.85, 0.4))
	if not R.kit.mats.has("nu_vert"):
		R._put("nu_vert", R._col(Color(0.3, 0.56, 0.27), 0.8))
		R._put("nu_vert_clair", R._col(Color(0.5, 0.72, 0.34), 0.8))


# =================================================================== aides

static func _r(M) -> RandomNumberGenerator:
	return M.ctx["rng"]


static func _pick(M, a: Array) -> Variant:
	return a[_r(M).randi() % a.size()]


## Toujours dans la même pièce ? (après un délai, on a pu sortir… ou entrer dans une autre maison)
static func _la(M, room0) -> bool:
	return is_instance_valid(room0) and M.inside and M.room == room0


## La nuit de la Fronde (avant 7 h, après 21 h) : on dort, on chuchote.
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



## Une affiche de la Fronde (les Soupapes, les concerts, le fanzine : R.pal["tableaux"]), cadre fin.
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


## Des affiches là où le mur est libre (fenêtres, poêle, établi…) ; idx : l'image (-1 : au hasard).
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


## Le foyer de la pièce (dans la Fronde : le poêle), contre le mur du fond, en x.
static func _foyer(M, x: float) -> void:
	M.R.foyer(x, -M.R.D * 0.5 + 0.22, 0, true)


## Une table basse (plateau de céramique, pieds d'argent).
static func _table_basse(M, x: float, z: float, w: float = 1.0, d: float = 0.55) -> void:
	var R = M.R
	R.kit.box(R.L(x, 0.36, z), Vector3(w, 0.04, d), "ceramique", 1.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			R.kit.cyl(R.L(x + sx * (w * 0.5 - 0.06), 0.0, z + sz * (d * 0.5 - 0.06)), 0.015, 0.015, 0.34, "argent", 8, false)
	R.kit.col_box(R.L(x, 0.19, z), Vector3(w, 0.38, d))
	R.reserve(x, z, w + 0.2, d + 0.2)


## Un lampadaire à l'abat-jour blanc.
static func _lampadaire(M, x: float, z: float) -> void:
	var R = M.R
	R.kit.cyl(R.L(x, 0, z), 0.16, 0.16, 0.025, "argent", 16)
	R.kit.cyl(R.L(x, 0.02, z), 0.012, 0.012, 1.42, "argent", 8, false)
	R.kit.cyl(R.L(x, 1.36, z), 0.04, 0.04, 0.08, "lumiere", 8)
	R.kit.cyl(R.L(x, 1.3, z), 0.21, 0.14, 0.26, "tissu_blanc", 16, false)
	R.reserve(x, z, 0.45, 0.45)


## Un pot et sa plante (fleur : la matière des fleurs, "" : pas de fleurs ; les verts : _fronde_mats).
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



# =================================================================== le groupe des casseroles

## Les chansons des Petites Soupapes (une par maison), et la berceuse de la nuit.
const CHANSONS_CS := [
	["♪ Pas de batterie ? On tape sur des casseroles ! ♪", "♪ Pas de guitare ? La nôtre est en carton ! ♪", "♪ Pas de grande scène, mais toute la Fronde rigole ! ♪", "♪ Les Petites Soupapes… BONG ! C'est nous ! ♪"],
	["♪ Mémé Gamelle, rends-nous la louche ! ♪", "♪ Elle sonne comme une cloche quand on la touche ! ♪", "♪ La Fronde chante, la Fronde danse ! ♪", "♪ Et toute la tôle tremble en cadence ! ♪"],
]
const BERCEUSE_CS := ["♪ Dodo, les Soupapes… ♪", "♪ Les casseroles dorment au clou… ♪", "♪ Demain, on tapera fort… ♪", "♪ Mais cette nuit, tout doux… ♪"]


## Deux enfants ont monté leur groupe, « Les Petites Soupapes » (comme les grandes, Rivet, Bielle et
## Écho) : une batterie de casseroles pendues à un portique, un bidon pour grosse caisse, un ampli et
## une guitare de carton, un micro fait d'un entonnoir au bout d'un manche à balai. L'un tape,
## l'autre chante ; des « ♪ » montent ; les parents se bouchent les oreilles… en souriant. On peut
## taper sur une casserole, chanter avec eux (la première fois : le premier fanzine du groupe,
## dessiné à la main), régler le micro (larsen : tout le monde sursaute). La nuit, les deux musiciens
## dorment dans des hamacs l'un au-dessus de l'autre, la guitare de carton sur la poitrine.
static func _casseroles(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var room0: Node = M.room
	var nuit: bool = _nuit(M)
	var big: bool = R.D >= 4.0
	var dside: float = -1.0 if R.door_x > 0.0 else 1.0          # le bout de la pièce loin de la porte : la « scène »
	var zl: float = _dedans(M, 0.0, -hd + 0.75).y               # la ligne où l'on se tient (devant le mur du fond)
	var chanson: Array = CHANSONS_CS[r.randi() % CHANSONS_CS.size()]
	# --- la batterie : le bidon (grosse caisse), le portique et ses casseroles pendues
	var xbd: float = dside * (hw - 0.28)
	var xr: float = dside * (hw - 0.62)
	R.kit.cyl(R.L(xbd, 0, zl), 0.2, 0.2, 0.56, "fr_rouge", 16)
	for yb in [0.1, 0.42]:
		R.kit.ring(R.L(xbd, yb, zl), 0.196, 0.212, 0.035, "fr_jaune", 16)
	R.kit.cyl(R.L(xbd, 0.56, zl), 0.18, 0.18, 0.008, "fer", 14)
	var lab := Label3D.new()
	lab.text = "LES PETITES\nSOUPAPES"
	lab.font_size = 18
	lab.pixel_size = 0.002
	lab.outline_size = 4
	lab.modulate = Color(1.0, 0.95, 0.85)
	lab.outline_modulate = Color(0.25, 0.05, 0.03)
	M.room.add_child(lab)
	lab.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(-90.0 * dside)), R.P(xbd - dside * 0.215, 0.28, zl))
	for sz in [-1.0, 1.0]:
		R.kit.cyl(R.L(xr, 0, zl + sz * 0.4), 0.022, 0.022, 1.16, "poutre", 6)
		R.kit.box(R.L(xr, 0.012, zl + sz * 0.4), Vector3(0.22, 0.024, 0.22), "fer", 1.0)
	R.kit.cyl(R.L(xr, 1.13, zl - 0.42) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.016, 0.016, 0.84, "fer", 6)
	R.kit.col_box(R.L(dside * (hw - 0.45), 0.6, zl), Vector3(0.75, 1.2, 0.85))
	R.reserve(dside * (hw - 0.45), zl, 0.9, 1.0)
	R.mark_wall(dside * (hw - 0.6), 1.3, -hd, 0.7)
	var inox := _mat(Color(0.78, 0.79, 0.81), 0.85, 0.3)
	var cuivre := _mat(Color(0.82, 0.5, 0.3), 0.9, 0.35)
	var email := _mat(Color(0.2, 0.48, 0.8), 0.25, 0.4)
	var noir := _mat(Color(0.08, 0.08, 0.09), 0.3, 0.5)
	var fil := _mat(Color(0.9, 0.88, 0.8), 0.0, 0.9)
	var pots: Array = []
	var tailles: Array = [[0.075, inox], [0.1, cuivre], [0.085, email], [0.0, inox]]
	for k in range(4):
		var pv: Node3D = I._node(M, R.P(xr, 1.12, zl - 0.3 + k * 0.2), 0)
		_p(pv, I._cyl(0.004, 0.004, 0.1, 4), fil, Vector3(0, -0.05, 0))
		var rr: float = float(tailles[k][0])
		if rr > 0.0:
			# la casserole, le fond tourné vers le batteur, le manche en l'air
			_p(pv, I._boxm(Vector3(0.022, 0.1, 0.026)), noir, Vector3(0, -0.15, 0))
			_p(pv, I._cyl(rr, rr * 0.9, 0.11, 16), tailles[k][1], Vector3(0, -0.2 - rr, 0), Vector3.ONE, Vector3(0, 0, PI * 0.5))
		else:
			# le couvercle : la cymbale
			_p(pv, I._cyl(0.12, 0.12, 0.012, 20), inox, Vector3(0, -0.22, 0), Vector3.ONE, Vector3(0, 0, PI * 0.5))
			_p(pv, I._sph(0.018), noir, Vector3(-dside * 0.012, -0.22, 0))
		pots.append(pv)
	var kit_c: Vector3 = R.P(xr, 0.9, zl)
	# --- l'ampli de carton contre le mur du fond (son haut-parleur dessiné au feutre), la guitare de carton
	var xa: float = dside * (hw - 0.95)
	R.kit.box(R.L(xa, 0.25, -hd + 0.24), Vector3(0.42, 0.5, 0.36), "carton", 1.0)
	R.kit.cyl(R.L(xa, 0.28, -hd + 0.42) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.13, 0.13, 0.006, "noir", 16)
	R.kit.cyl(R.L(xa, 0.28, -hd + 0.425) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.04, 0.04, 0.006, "fr_jaune", 12)
	R.kit.box(R.L(xa - 0.13, 0.46, -hd + 0.425), Vector3(0.05, 0.03, 0.006), "fr_rouge", 1.0)
	R.kit.col_box(R.L(xa, 0.25, -hd + 0.24), Vector3(0.42, 0.5, 0.36))
	R.reserve(xa, -hd + 0.3, 0.55, 0.55)
	# --- les hamacs (roulés le jour, tendus la nuit), entre deux poutrelles
	var hc: float = dside * (hw - 2.3)
	var hz: float = -hd + 0.38
	_casseroles_hamac(M, hc, hz, [0.85, 1.75], nuit)
	if nuit:
		# la guitare de carton, sur la poitrine de la chanteuse
		_casseroles_guitare(M, R.L(0, 0, 0) * Transform3D(Basis(Vector3(0, 0, -dside), Vector3(-dside, 0, 0), Vector3(0, 1, 0)), Vector3(hc + dside * 0.42, 0.95, hz)))
	else:
		# appuyée contre l'ampli
		_casseroles_guitare(M, R.L(xa, 0.0, -hd + 0.52) * Transform3D(Basis(Vector3.RIGHT, -0.32), Vector3.ZERO))
	# --- le micro : un entonnoir au bout d'un manche à balai, sur un vieux pied de lampe
	var xs: float = dside * (hw - 2.1)
	var xm: float = xs - dside * 0.5
	R.kit.cyl(R.L(xm, 0, zl), 0.13, 0.15, 0.03, "fer", 14)
	R.kit.cyl(R.L(xm, 0.03, zl), 0.014, 0.014, 1.2, "bois_clair", 8, false)
	R.kit.col_box(R.L(xm, 0.6, zl), Vector3(0.12, 1.2, 0.12))
	R.reserve(xm, zl, 0.35, 0.35)
	var mic: Node3D = I._node(M, R.P(xm, 1.24, zl), 0)
	var mic_t := Node3D.new()
	mic.add_child(mic_t)
	_p(mic_t, I._cyl(0.085, 0.014, 0.14, 16), cuivre, Vector3(dside * 0.07, 0, 0), Vector3.ONE, Vector3(0, 0, -PI * 0.5 * dside))
	_p(mic_t, I._sph(0.024), noir, Vector3.ZERO)
	_p(mic_t, I._boxm(Vector3(0.05, 0.02, 0.03)), _mat(Color(0.98, 0.78, 0.2), 0.2, 0.5), Vector3(0, -0.03, 0))
	var mic_c: Vector3 = mic.global_position
	# --- le reste : les affiches, une guirlande de fanions, la caisse du parent, les dessins du fanzine
	_cadres(M, 2)
	R.guirlande(R.P(-hw + 0.35, R.H - 0.22, -hd + 0.3), R.P(hw - 0.35, R.H - 0.22, -hd + 0.3), 14)
	var xpa: float = -dside * (hw - 0.55)
	R.kit.box(R.L(xpa - dside * 0.12, 0.2, zl), Vector3(0.42, 0.4, 0.42), "bois_clair", 0.6)
	R.kit.box(R.L(xpa - dside * 0.12, 0.39, zl), Vector3(0.44, 0.04, 0.44), "bois_sombre", 1.0)
	R.kit.col_box(R.L(xpa - dside * 0.12, 0.2, zl), Vector3(0.42, 0.4, 0.42))
	R.reserve(xpa, zl, 0.6, 0.6)
	for k2 in range(3):
		R.kit.box(R.L(xpa + dside * (0.42 + k2 * 0.1), 0.003 + k2 * 0.002, zl - 0.12 + r.randf_range(-0.06, 0.06), r.randf_range(-30.0, 30.0)), Vector3(0.21, 0.004, 0.29), "papier", 1.0)
	R.kit.box(R.L(xpa + dside * 0.5, 0.012, zl + 0.05, 40.0), Vector3(0.012, 0.012, 0.15), "fr_rouge", 1.0)
	if big:
		# la chaudière a de la place : le poêle, un tapis devant la « scène », le touret du fanzine
		var fx: float = -dside * (hw - 0.4)
		var fz: float = hd - 2.1
		if R.is_free(fx, fz, 1.1, 1.1):
			R.foyer(fx, fz, 90.0 * dside, true)
		R.tapis(dside * 0.4, zl + 1.0, 0, minf(2.6, R.W - 1.6), 1.3)
		var tx: float = dside * 0.8
		var tz: float = zl + 1.7
		if R.is_free(tx, tz, 0.9, 0.9):
			R.kit.cyl(R.L(tx, 0, tz), 0.38, 0.38, 0.05, "bois", 18)
			R.kit.cyl(R.L(tx, 0.05, tz), 0.12, 0.12, 0.38, "bois_sombre", 10)
			R.kit.cyl(R.L(tx, 0.43, tz), 0.38, 0.38, 0.05, "bois", 18)
			for k3 in range(2):
				R.kit.box(R.L(tx + r.randf_range(-0.15, 0.15), 0.483 + k3 * 0.003, tz + r.randf_range(-0.12, 0.12), r.randf_range(-40.0, 40.0)), Vector3(0.21, 0.004, 0.29), "papier", 1.0)
			R.kit.col_box(R.L(tx, 0.24, tz), Vector3(0.6, 0.48, 0.6))
			R.reserve(tx, tz, 0.9, 0.9)
	# --- les gens : le batteur et la chanteuse ; un parent assis sur la caisse, l'autre debout
	var xd: float = dside * (hw - 1.1)
	var batteur: Node
	var chanteuse: Node
	if nuit:
		chanteuse = M.person("fille", hc, zl, 0, "dormir")
		chanteuse.lie(R.P(hc - dside * 0.6, 0.85 - 0.17, hz), Vector3(dside, 0, 0))
		chanteuse.lines = ["Zzz…", "Zzz… un, deux, trois, quatre… zzz…", "Mmh… plus fort, la batterie… zzz…"]
		chanteuse.line_every = Vector2(9.0, 14.0)
		batteur = M.person("garcon", hc, zl, 0, "dormir")
		batteur.lie(R.P(hc + dside * 0.6, 1.75 - 0.17, hz), Vector3(-dside, 0, 0))
		batteur.lines = ["Zzz… bong… zzz…", "Zzz… solo de louche… zzz…", "Mmh… encore un rappel… zzz…"]
		batteur.line_every = Vector2(10.0, 15.0)
	else:
		batteur = M.person("garcon", xd, zl, 90.0 * dside, "bricoler")
		batteur.lines = ["BONG ! … Pardon. BONG !", "J'ai cassé une louche. C'était un solo.", "Ma batterie, c'est toute la cuisine. Ce soir, on mange dans les couvercles.", "Rivet dit que le rock, c'est d'abord taper fort."]
		batteur.line_every = Vector2(6.0, 10.0)
		chanteuse = M.person("fille", xs, zl, -90.0 * dside, "chanter")
		chanteuse.lines = ["Un, deux, trois, quatre !", "Plus fort, la batterie !", "Ce soir, on joue pour toute la Fronde ! Enfin, pour Papa et Maman.", "Merci, la Fronde ! … Merci, les parents !"]
		chanteuse.line_every = Vector2(6.0, 10.0)
	var role_a: String = str(_pick(M, ["homme", "femme"]))
	var pa: Node = M.person(role_a, xpa, zl, 90.0 * dside, "dormir_assis" if nuit else "rire_assis")
	# le parent debout : pas devant la porte, pas sur le micro
	var cands: Array = [Vector2(-dside * (hw - 1.3), zl), Vector2((R.door_x + xm) * 0.5, zl), Vector2(-dside * (hw - 1.0), zl)]
	if big:
		cands.insert(1, Vector2(-dside * (hw - 0.6), zl + 1.1))
	var pbp: Vector2 = cands[cands.size() - 1]
	for c in cands:
		var cv: Vector2 = c
		var loin_porte: bool = absf(cv.x - R.door_x) >= 0.7 or cv.y < hd - 2.0
		if loin_porte and absf(cv.x - xm) >= 0.55 and absf(cv.x - xpa) >= 0.6:
			pbp = cv
			break
	pbp = _dedans(M, pbp.x, pbp.y)
	var pb: Node = M.person("femme" if role_a == "homme" else "homme", pbp.x, pbp.y, _vers(pbp.x, pbp.y, xs, zl), "mains_dos" if nuit else "bras_croises")
	R.reserve(pbp.x, pbp.y, 0.6, 0.6)
	if nuit:
		pa.lines = ["Zzz…", "Zzz… encore une chanson… zzz…"]
		pa.line_every = Vector2(11.0, 16.0)
		pb.lines = ["Chut… les artistes dorment.", "Ils se sont endormis en plein refrain.", "Ne touche pas aux casseroles, d'accord ? Tout doux.", "Regarde : la guitare monte et descend."]
		pb.line_every = Vector2(10.0, 15.0)
	else:
		pa.lines = ["Mes oreilles ! … Encore, encore !", "Bravo ! (Les mains sur les oreilles.)", "C'est fort. C'est très fort. C'est très bien.", "Qui a pris la passoire ? … Ah. La cymbale."]
		pa.line_every = Vector2(8.0, 13.0)
		pb.lines = ["Plus tard, ils joueront avec les Soupapes.", "J'ai mis du coton dans mes oreilles. Je n'entends plus que la batterie.", "C'est ma louche, ça ? … C'était ma louche.", "Ils répètent tous les jours. Les voisins connaissent les paroles."]
		pb.line_every = Vector2(8.0, 13.0)
	# --- ce qui bouge : les casseroles qui se balancent (et sonnent quand on tape), les « ♪ », le micro
	var st := {"t": r.randf() * 10.0, "coup": [0.0, 0.0, 0.0, 0.0], "beat": 0.6, "note": 1.5, "son": 6.0 + r.randf() * 4.0, "zzz": 4.0,
		"chante": false, "larsen": 0.0, "regle": false}
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(mic):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var coup: Array = st["coup"]
		if nuit:
			st["zzz"] = float(st["zzz"]) - dt
			if float(st["zzz"]) <= 0.0:
				st["zzz"] = 6.0 + randf() * 4.0
				_bulle(M, R.P(hc + randf_range(-0.4, 0.4), 2.05, hz + 0.2), "Zzz…", Color(0.8, 0.85, 1.0), 34, 0.35, 2.2)
		else:
			# le batteur tape (plus vite quand on chante avec eux)
			st["beat"] = float(st["beat"]) - dt
			if float(st["beat"]) <= 0.0:
				st["beat"] = (0.26 if bool(st["chante"]) else 0.5) * (1.0 if randf() < 0.75 else 2.0)
				var k: int = randi() % coup.size()
				coup[k] = minf(1.4, float(coup[k]) + 0.7)
			st["note"] = float(st["note"]) - dt
			if float(st["note"]) <= 0.0:
				st["note"] = randf_range(0.7, 1.2) if bool(st["chante"]) else randf_range(1.4, 2.6)
				var src: Node = chanteuse if randf() < 0.6 else batteur
				if is_instance_valid(src):
					var col: Color = [Color(1.0, 0.85, 0.3), Color(0.5, 0.85, 1.0), Color(1.0, 0.55, 0.75), Color(0.6, 1.0, 0.6)][randi() % 4]
					_bulle(M, (src.npc as Node3D).global_position + Vector3(randf_range(-0.2, 0.2), 1.7, randf_range(-0.1, 0.1)), ["♪", "♫", "♪ ♪", "♫ ♪"][randi() % 4], col, 46, 0.6, 1.8)
			st["son"] = float(st["son"]) - dt
			if float(st["son"]) <= 0.0:
				st["son"] = 9.0 + randf() * 6.0
				M.main.sfx(["tambour", "batterie_roulement", "guitare_riff"][randi() % 3], kit_c, -12.0)
		for k2 in range(pots.size()):
			var e: float = maxf(0.0, float(coup[k2]) - dt * 1.5)
			coup[k2] = e
			(pots[k2] as Node3D).rotation.z = dside * 0.35 * e * sin(t * 13.0 + k2) + 0.04 * sin(t * 0.9 + k2 * 1.7)
		# le micro tremble quand il siffle
		var lz: float = maxf(0.0, float(st["larsen"]) - dt)
		st["larsen"] = lz
		mic.rotation = Vector3(0.1 * lz * sin(t * 47.0), 0.0, 0.1 * lz * sin(t * 39.0))
	# --- taper sur une casserole
	var taper := func() -> void:
		var coup: Array = st["coup"]
		var k: int = r.randi() % coup.size()
		coup[k] = 1.6
		var pk: Node3D = pots[k]
		M.main.sfx(str(_pick(M, ["tambour", "batterie_roulement"])), pk.global_position, -8.0 if nuit else 0.0)
		_bulle(M, pk.global_position + Vector3(0, 0.15, 0), str(_pick(M, ["BONG !", "DONG !", "TCHING !", "BLONG !"])), Color(1.0, 0.9, 0.5), 44 if not nuit else 32, 0.45, 1.3)
		if nuit:
			pb.say(str(_pick(M, ["Chut ! … Doucement, ils dorment.", "Pas la nuit, les casseroles… Tout doux.", "Shhh… La batterie dort aussi."])), 3.0)
			S._say_late(M, batteur, "Zzz… bong… zzz…", 1.4, 3.0)
			return
		batteur.gesture("rire", 1.5)
		batteur.say(str(_pick(M, ["Hé ! C'est ma batterie ! … Bon, d'accord, joli coup.", "Pas mal ! Tu veux faire le solo ?", "Pas la casserole bleue, c'est celle du chocolat !", "Ouais ! Encore ! Plus fort !"])), 3.0)
		S._say_late(M, pa, str(_pick(M, ["Mes oreilles !", "Ha ha ! Un troisième musicien !", "Ma casserole à soupe…"])), 1.2, 3.0)
	M.act(R.P(dside * (hw - 1.05), 0, zl + 0.3), "E : taper sur une casserole", taper, 1.0)
	# --- chanter avec eux (la nuit : une berceuse, tout bas) ; la première fois, le fanzine
	var recompense := func() -> void:
		M.bonne_action_v120()  ## V120 : une bonne action, l'île s'en souvient
		if bool(M.state().get("fr_casseroles", false)):
			if nuit:
				pb.say("Merci… Ils ont souri en dormant, je l'ai vu.", 3.5)
			else:
				chanteuse.say(str(_pick(M, ["Encore un rappel ? Les rappels, c'est notre spécialité !", "Tu chantes presque aussi fort que les casseroles !", "Bienvenue dans le groupe, camarade !"])), 3.5)
			return
		M.state()["fr_casseroles"] = true
		var txt: String = "Chut… Une berceuse avec Les Petites Soupapes, ça compte. Tiens, tout bas : leur premier fanzine, dessiné à la main. Ils seront si fiers que tu l'aies." if nuit else "Bravo, camarade ! Tu as chanté avec Les Petites Soupapes : tu fais partie du groupe. Tiens : leur premier fanzine, dessiné à la main. Il y a ta tête en page trois. Enfin, elle y sera."
		M.talk(pb, txt, I._bye("Merci ! Bonne nuit, les artistes…") if nuit else I._bye("Merci ! Vive les Soupapes !"), func(_i):
			M.give([["fanzine", 1]], "")
			M.close_talk(), "à voix basse" if nuit else "aux anges")
	var chanter := func() -> void:
		if bool(st["chante"]):
			return
		st["chante"] = true
		var paroles: Array = BERCEUSE_CS if nuit else chanson
		if nuit:
			M.say("Tu fredonnes tout bas, près des hamacs. Le parent te rejoint, à mi-voix.", 4.0)
		else:
			chanteuse.gesture("joie", 1.6)
			chanteuse.say(str(_pick(M, ["Un, deux, trois, quatre !", "Avec nous ! Un, deux, trois, quatre !", "Plus fort que les casseroles ! Un, deux, trois, quatre !"])), 2.5)
			M.main.sfx("batterie_roulement", kit_c)
		for i in range(paroles.size()):
			await M.get_tree().create_timer(2.0 if i == 0 else 2.3).timeout
			if not _la(M, room0):
				return
			var qui: Node = pb if nuit else chanteuse
			_bulle(M, (qui.npc as Node3D).global_position + Vector3(0, 1.95, 0), str(paroles[i]), Color(0.75, 0.85, 1.0) if nuit else Color(1.0, 0.9, 0.55), 30 if nuit else 36, 0.5, 2.6)
			if not nuit:
				M.main.sfx("chant_%d" % (r.randi() % 5), mic_c, -4.0)
				var coup: Array = st["coup"]
				coup[i % coup.size()] = 1.4
		await M.get_tree().create_timer(2.2).timeout
		if not _la(M, room0):
			return
		st["chante"] = false
		if nuit:
			S._say_late(M, chanteuse, "Zzz… encore… zzz…", 0.5, 3.0)
		else:
			M.main.sfx("confettis", kit_c, -6.0)
			pa.gesture("applaudir", 2.5)
			pb.gesture("applaudir", 2.5)
			batteur.gesture("joie", 2.0)
			_bulle(M, (pa.npc as Node3D).global_position + Vector3(0, 1.5, 0), "Clap clap clap !", Color(1.0, 0.95, 0.8), 38, 0.5, 1.8)
			_bulle(M, (pb.npc as Node3D).global_position + Vector3(0, 2.0, 0), "Bravo !", Color(1.0, 0.95, 0.8), 40, 0.5, 1.8)
			chanteuse.say(str(_pick(M, ["Merci, la Fronde !", "On est Les Petites Soupapes ! Merci !", "Ouais ! Le public est en délire ! Enfin, les parents."])), 3.0)
		await M.get_tree().create_timer(2.0).timeout
		if not _la(M, room0):
			return
		recompense.call()
	M.act(R.P(xm - dside * 0.1, 0, zl + 0.45), "E : chanter avec eux" if not nuit else "E : fredonner une berceuse", chanter, 1.0, func(): return not bool(st["chante"]))
	# --- régler le micro : un quart de tour… larsen !
	var regler := func() -> void:
		if bool(st["regle"]):
			return
		st["regle"] = true
		var tw: Tween = M.room.create_tween()
		tw.tween_property(mic_t, "rotation:y", mic_t.rotation.y + r.randf_range(-0.5, 0.5), 0.4).set_trans(Tween.TRANS_SINE)
		M.main.sfx("larsen", mic_c)
		st["larsen"] = 1.4
		_bulle(M, mic_c + Vector3(0, 0.3, 0), "IIIIIIIIIIIII !", Color(1.0, 0.6, 0.5), 46, 0.5, 1.5)
		M.say(str(_pick(M, ["Tu tournes l'entonnoir d'un quart de tour… IIIIIIIIII ! Le micro hurle, tout le monde sursaute. Puis tout le monde rit.",
			"Tu rapproches l'entonnoir de l'ampli. Mauvaise idée : un sifflement à décoller la peinture de la tôle !"])), 4.5)
		for f in [batteur, chanteuse, pa, pb]:
			f.gesture("sursaut", 1.0)
		await M.get_tree().create_timer(1.4).timeout
		if not _la(M, room0):
			return
		chanteuse.gesture("rire", 1.8)
		chanteuse.say(str(_pick(M, ["Aïe ! Pas trop près de l'ampli, l'entonnoir siffle !", "Réglé ! … Enfin, il siffle moins.", "C'est le son Soupapes, ça ! Rivet adore."])), 3.0)
		S._say_late(M, pa, str(_pick(M, ["Mes oreilles ! … Ha ha !", "Ça, c'était le meilleur morceau.", "Je n'entends plus rien. Mais j'ai adoré."])), 1.5, 3.0)
		st["regle"] = false
	if not nuit:
		M.act(R.P(xm - dside * 0.35, 0, zl + 0.2), "E : régler le micro", regler, 0.9, func(): return not bool(st["regle"]) and not bool(st["chante"]))
	# --- les conversations
	var chanteuse_cb := func() -> void:
		if nuit:
			M.talk(chanteuse, "Zzz… et maintenant… le rappel… zzz…", I._bye("(La laisser dormir)"), I._close(M), "endormie")
			return
		M.talk(chanteuse, str(_pick(M, ["Salut, camarade ! On est Les Petites Soupapes ! Moi, je chante. Lui, il tape sur tout ce qui sonne. Et la guitare est en carton, mais elle a beaucoup de caractère.",
			"Bon bricolage ! Tu tombes bien : on répète pour notre premier concert. Le public, pour l'instant, c'est Papa et Maman. Ils adorent. Enfin, je crois."])),
			[{"id": "nom", "label": "Pourquoi « Les Petites Soupapes » ?"}, {"id": "chanter", "label": "Je peux chanter avec vous ?"}, {"id": "fermer", "label": "Salut, camarade !"}], func(id):
			match id:
				"nom":
					M.talk(chanteuse, "À cause des grandes : les Soupapes, Rivet, Bielle et Écho ! Elles jouent tous les soirs dans la Fronde. Rivet nous a dit : « Commencez par les casseroles, c'est comme ça qu'on a fait. » Alors on a commencé.", I._bye("Bonne idée !"), I._close(M), "fière")
				"chanter":
					M.talk(chanteuse, "Bien sûr ! Viens près du micro et chante fort. Plus fort que les casseroles, si tu peux. Personne n'y arrive.", I._bye("Je vais essayer !"), I._close(M), "aux anges")
				_:
					M.close_talk()
		, "aux anges")
	M.talk_spot(chanteuse, chanteuse_cb)
	var pb_cb := func() -> void:
		if nuit:
			M.talk(pb, "Chut… Ils se sont endormis en plein refrain, la guitare sur le ventre. Demain matin, ça recommence. Dès huit heures.",
				[{"id": "jours", "label": "Ils jouent tous les jours ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if id == "jours":
					M.talk(pb, "Tous les jours. Les voisins ont fini par apprendre les paroles. Le vieux d'à côté tape même la mesure contre la tôle.", I._bye("Bonne nuit, les artistes…"), I._close(M), "à voix basse")
				else:
					M.close_talk()
			, "à voix basse")
			return
		M.talk(pb, str(_pick(M, ["Salut, camarade ! Entre, entre. Ne cherche pas les casseroles : elles sont toutes sur la batterie.",
			"Bon bricolage ! Attention où tu mets les pieds : par terre, ce sont les dessins de leur fanzine. Et la louche, c'est un instrument."])),
			[{"id": "bruit", "label": "Ça ne vous dérange pas, le bruit ?"}, {"id": "concert", "label": "Ils vont faire un concert ?"}, {"id": "fermer", "label": "Bonne répétition !"}], func(id):
			match id:
				"bruit":
					M.talk(pb, "Un peu. Beaucoup. Mais tu as vu leurs têtes quand ils jouent ? À la Fronde, on dit : la musique, ça se partage. Même avec les oreilles des parents.", I._bye("C'est beau."), I._close(M), "attendri")
				"concert":
					M.talk(pb, "Ils en rêvent ! Brasero leur a promis cinq minutes avant les Soupapes, à la prochaine fête. Cinq minutes. Ils répètent déjà le salut final.", I._bye("J'y serai !"), I._close(M), "attendri")
				_:
					M.close_talk()
		, "attendri")
	M.talk_spot(pb, pb_cb)
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Les Petites Soupapes dorment dans leurs hamacs, l'un au-dessus de l'autre. Une guitare de carton monte et descend sur une petite poitrine.",
			"Tout est silencieux, pour une fois. Les casseroles se balancent doucement au-dessus du bidon, et deux musiciens ronflent en mesure.",
			"Il fait nuit. Un parent veille en chuchotant à côté de deux hamacs. Le micro en entonnoir attend demain, la tête basse."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["BONG ! DING ! TCHAK ! Deux enfants répètent avec des casseroles, un bidon et une guitare de carton. Leurs parents se bouchent les oreilles… en souriant.",
			"Bienvenue à la répétition des Petites Soupapes ! Une batterie de casseroles, un micro en entonnoir, et un public de deux parents très fiers.",
			"Ça résonne fort dans la tôle : deux enfants répètent leur premier concert à grands coups de louche. Une chanteuse te fait signe : « Un, deux, trois, quatre ! »"]))


## Deux hamacs (ou plus) l'un au-dessus de l'autre, entre deux poutrelles, le long du mur du fond
## (hc, hz : le milieu, repère de la pièce ; ys : les hauteurs d'accroche) ; roulés contre une
## poutrelle le jour, tendus la nuit (le creux : 25 cm sous l'accroche).
static func _casseroles_hamac(M, hc: float, hz: float, ys: Array, tendu: bool) -> void:
	var R = M.R
	var cols: Array = ["tissu_orange", "tissu_turquoise", "tissu_rose", "tissu_jaune"]
	var c0: int = _r(M).randi() % cols.size()
	for sx in [-1.0, 1.0]:
		R.kit.cyl(R.L(hc + sx * 1.1, 0.0, hz), 0.045, 0.045, R.H, "poutre", 8, false)
	for i in range(ys.size()):
		var y: float = float(ys[i])
		var col: String = cols[(c0 + i) % cols.size()]
		for sx2 in [-1.0, 1.0]:
			R.kit.ring(R.L(hc + sx2 * 1.06, y + 0.2, hz), 0.035, 0.05, 0.03, "fer", 8)
		if not tendu:
			R.kit.cyl(R.L(hc - 0.98, y - 0.5, hz), 0.07, 0.07, 0.62, col, 10)
			_casseroles_corde(M, Vector3(hc - 1.06, y + 0.2, hz), Vector3(hc - 0.98, y + 0.12, hz))
			continue
		var n: int = 8
		var prev := Vector2(-0.95, 0.0)
		for k in range(1, n + 1):
			var u: float = -0.95 + 1.9 * float(k) / n
			var cur := Vector2(u, -0.25 * (1.0 - (u / 0.95) * (u / 0.95)))
			var mid: Vector2 = (prev + cur) * 0.5
			var d: Vector2 = cur - prev
			R.kit.box(R.L(hc + mid.x, y + mid.y, hz) * Transform3D(Basis(Vector3.BACK, d.angle()), Vector3.ZERO), Vector3(d.length() + 0.012, 0.025, 0.62), col, 1.0)
			prev = cur
		for sx3 in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_casseroles_corde(M, Vector3(hc + sx3 * 1.06, y + 0.2, hz), Vector3(hc + sx3 * 0.95, y, hz + sz * 0.29))
	R.kit.col_box(R.L(hc, 0.6, hz), Vector3(2.2, 1.2, 0.5))
	R.reserve(hc, hz, 2.4, 0.8)
	R.mark_wall(hc, 1.3, -R.D * 0.5, 1.25)


## Une corde (un cylindre fin de la géométrie de la pièce) de a à b, repère de la pièce.
static func _casseroles_corde(M, a: Vector3, b: Vector3, r: float = 0.008, key: String = "tissu_creme") -> void:
	var d: Vector3 = b - a
	var l: float = d.length()
	if l < 0.001:
		return
	var y: Vector3 = d / l
	var ref: Vector3 = Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x: Vector3 = y.cross(ref).normalized()
	var z: Vector3 = x.cross(y).normalized()
	M.R.kit.cyl(M.R.L(0, 0, 0) * Transform3D(Basis(x, y, z), a), r, r, l, key, 5, false)


## La guitare de carton (xf : le bas de la caisse ; +Y vers la tête du manche, +Z la face) : une
## caisse de carton, une rosace au feutre, un manche de règle, trois élastiques.
static func _casseroles_guitare(M, xf: Transform3D) -> void:
	var K = M.R.kit
	K.box(xf * Transform3D(Basis(), Vector3(0, 0.21, 0)), Vector3(0.34, 0.42, 0.07), "carton", 1.0)
	K.cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.26, 0.036)), 0.065, 0.065, 0.004, "noir", 14)
	K.box(xf * Transform3D(Basis(), Vector3(0, 0.12, 0.037)), Vector3(0.12, 0.025, 0.006), "fr_rouge", 1.0)
	K.box(xf * Transform3D(Basis(), Vector3(0, 0.66, 0.0)), Vector3(0.06, 0.48, 0.03), "bois_clair", 1.0)
	K.box(xf * Transform3D(Basis(), Vector3(0, 0.94, 0.0)), Vector3(0.1, 0.1, 0.035), "fr_jaune", 1.0)
	for k in range(3):
		K.box(xf * Transform3D(Basis(), Vector3(-0.02 + k * 0.02, 0.55, 0.042)), Vector3(0.004, 0.82, 0.004), "tissu_blanc", 1.0)


# =================================================================== le robot de ferraille

## Un enfant inventeur (un ami de Bricole, l'inventrice de l'Atelier Libre) a construit son robot,
## Boulon : des boîtes de conserve, un entonnoir sur la tête, des ressorts pour les bras et les
## jambes, deux ampoules pour les yeux, une clé dans le dos. Boulon fait des tours de piste le long
## de la pièce en cliquetant, ses yeux clignotent, il bipe. On peut le remonter (la clé tourne, il
## accélère), lui serrer la main (il lève un bras de ressort), lui donner un boulon (il vient le
## manger à l'établi : « Miam, bip ! » ; la première fois, il recrache… une bague de boulon). La
## nuit, Boulon est « éteint » dans un coin, les yeux qui clignotent faiblement ; l'enfant dort dans
## son hamac.
static func _robot(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var room0: Node = M.room
	var nuit: bool = _nuit(M)
	var big: bool = R.D >= 4.0
	var boy: bool = r.randf() < 0.5
	var dside: float = -1.0 if R.door_x > 0.0 else 1.0
	var zl: float = _dedans(M, 0.0, -hd + 0.75).y
	var sol: float = R.P(0, 0, 0).y
	# --- l'établi, au bout de la pièce (loin de la porte) : des conserves en réserve, des outils, le
	# bocal des boulons, la lampe d'atelier ; au mur, les plans de Boulon
	var xb: float = dside * (hw - 0.85)
	var zb: float = -hd + 0.3
	R.kit.box(R.L(xb, 0.84, zb), Vector3(1.25, 0.05, 0.5), "bois", 1.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			R.kit.box(R.L(xb + sx * 0.56, 0.41, zb + sz * 0.19), Vector3(0.06, 0.82, 0.06), "poutre", 1.0)
	R.kit.box(R.L(xb, 0.2, zb), Vector3(1.15, 0.03, 0.42), "bois_sombre", 1.0)
	for k in range(4):
		R.kit.cyl(R.L(xb - 0.4 + k * 0.17, 0.215, zb + r.randf_range(-0.1, 0.1)), 0.05, 0.05, 0.11, "argent", 10)
	R.kit.box(R.L(xb + 0.15, 0.875, zb + 0.06, 30.0), Vector3(0.2, 0.02, 0.05), "fer", 1.0)
	R.kit.box(R.L(xb + 0.3, 0.875, zb - 0.06, -20.0), Vector3(0.03, 0.02, 0.18), "fr_rouge", 1.0)
	R.kit.ring(R.L(xb - 0.05, 0.865, zb - 0.1), 0.03, 0.042, 0.12, "argent", 10)
	var xj: float = xb - dside * 0.42
	R.kit.cyl(R.L(xj, 0.865, zb + 0.08), 0.07, 0.07, 0.16, "verre", 14, false)
	for k2 in range(6):
		R.kit.cyl(R.L(xj + r.randf_range(-0.035, 0.035), 0.868 + k2 * 0.018, zb + 0.08 + r.randf_range(-0.035, 0.035)), 0.018, 0.018, 0.016, "fer", 6)
	var xl: float = xb + dside * 0.45
	R.kit.cyl(R.L(xl, 0.865, zb - 0.12), 0.06, 0.06, 0.02, "fer", 10)
	R.kit.cyl(R.L(xl, 0.885, zb - 0.12), 0.01, 0.01, 0.32, "fer", 6, false)
	R.kit.cyl(R.L(xl, 1.15, zb - 0.06), 0.07, 0.03, 0.1, "fr_jaune", 10)
	R.kit.cyl(R.L(xl, 1.14, zb - 0.06), 0.03, 0.03, 0.02, "lumiere", 8)
	R.kit.col_box(R.L(xb, 0.43, zb), Vector3(1.25, 0.86, 0.5))
	R.reserve(xb, zb + 0.1, 1.45, 0.7)
	for k3 in range(3):
		R.kit.box(R.L(xb - 0.35 + k3 * 0.33, 1.45 + r.randf_range(-0.08, 0.08), -hd + 0.03) * Transform3D(Basis(Vector3.BACK, deg_to_rad(r.randf_range(-8.0, 8.0))), Vector3.ZERO), Vector3(0.24, 0.32, 0.005), "papier", 1.0)
		R.kit.cyl(R.L(xb - 0.35 + k3 * 0.33, 1.58, -hd + 0.035) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.01, 0.01, 0.01, "fr_rouge", 6)
	R.mark_wall(xb, 1.45, -hd, 0.75)
	var jar_c: Vector3 = R.P(xj, 1.0, zb + 0.08)
	# --- le hamac de l'enfant (roulé le jour), à l'autre bout ; le coin de Boulon pour la nuit
	var hc: float = -dside * (hw - 1.75)
	var hz: float = -hd + 0.38
	_casseroles_hamac(M, hc, hz, [0.85], nuit)
	var coin: Vector2 = _dedans(M, -dside * (hw - 0.5), hd)
	R.kit.box(R.L(coin.x, 0.03, coin.y), Vector3(0.5, 0.06, 0.42), "bois_clair", 1.0)
	R.kit.box(R.L(coin.x - dside * 0.02, 0.07, coin.y), Vector3(0.38, 0.02, 0.3), "tissu_rouge", 1.0)
	R.reserve(coin.x, coin.y, 0.55, 0.5)
	_cadres(M, 2)
	if big:
		var fx: float = -dside * (hw - 0.4)
		var fz: float = hd - 2.1
		if R.is_free(fx, fz, 1.1, 1.1):
			R.foyer(fx, fz, 90.0 * dside, true)
		var ez: float = -hd + 1.25
		if R.wall_free(dside * hw, 1.5, ez, 0.6):
			R.etagere_murale(dside * (hw - 0.14), 1.5, ez, -90.0 * dside, 1.0, "argent", 6)
	# --- la boucle de Boulon : un ovale le long de la pièce, entre l'établi et le bout du hamac
	var xa: float = -dside * (hw - 0.95)
	var xe: float = xb - dside * 0.85
	var cx: float = (xa + xe) * 0.5
	var ax: float = absf(xe - xa) * 0.5
	var z0: float = -hd + 0.7
	var z1: float = (hd - 2.0) if big else (hd - 1.6)
	var cz: float = (z0 + z1) * 0.5
	var az: float = maxf(0.04, (z1 - z0) * 0.5)
	var boucle := func(s: float) -> Vector3:
		return R.P(cx + ax * cos(s), 0.0, cz + az * sin(s))
	var s0: float = r.randf() * TAU
	var depart: Vector3 = R.P(coin.x, 0.0, coin.y) if nuit else boucle.call(s0)
	var rb: Dictionary = _robot_boulon(M, depart)
	var bot: Node3D = rb["n"]
	var oeil: StandardMaterial3D = rb["oeil"]
	var jambes: Array = rb["jambes"]
	var bras: Array = rb["bras"]
	var cle: Node3D = rb["cle"]
	var tete: Node3D = rb["tete"]
	var cap0: float = atan2(dside, 0.0) if nuit else atan2(-ax * sin(s0), az * cos(s0))
	bot.rotation.y = cap0
	# --- l'enfant : à l'établi le jour, dans le hamac la nuit
	var role: String = "garcon" if boy else "fille"
	var kid: Node
	if nuit:
		kid = M.person(role, hc, zl, 0, "dormir")
		kid.lie(R.P(hc - dside * 0.6, 0.85 - 0.17, hz), Vector3(dside, 0, 0))
		kid.lines = ["Zzz…", "Zzz… Boulon… va recharger… zzz…", "Mmh… encore un ressort… zzz…"]
		kid.line_every = Vector2(9.0, 14.0)
	else:
		kid = M.person(role, xb, zl, 180, "bricoler")
		kid.lines = ["Boulon, à gauche ! … Ton autre gauche !", "Il fait trois kilomètres par jour. En rond. Dans ma chambre.",
			"Bricole dit que c'est le plus beau robot de la Fronde. C'est aussi le seul.", "Je lui ai appris à dire bonjour. Il dit « bip ». C'est pareil."]
		kid.line_every = Vector2(7.0, 11.0)
	# --- ce qui bouge : Boulon marche (ou va manger, serre la main, dort), ses jambes de ressort, ses
	# bras, sa clé qui se déroule, ses yeux qui clignotent, ses « bip »
	var st := {"t": r.randf() * 10.0, "mode": "eteint" if nuit else "marche", "s": s0, "pos": depart, "cap": cap0, "boost": 0.0,
		"remonte": 0.0, "pas": 0.0, "cligne": 2.0, "flash": 0.0, "bip": 4.0 + r.randf() * 4.0, "d": 0.0, "cible": depart, "ensuite": "", "occupe": false}
	var its := {}                                                # "main", "cle" : les interactions qui suivent Boulon
	var croquer := func(src: Vector3) -> void:
		# le boulon vole (du bocal, ou de ta main) jusque dans l'entonnoir
		var bn: Node3D = I._node(M, src, 0)
		_p(bn, I._cyl(0.026, 0.026, 0.02, 6), _mat(Color(0.45, 0.45, 0.48), 0.9, 0.35), Vector3.ZERO)
		_p(bn, I._cyl(0.011, 0.011, 0.06, 8), _mat(Color(0.6, 0.6, 0.63), 0.9, 0.35), Vector3(0, -0.04, 0))
		var bouche: Vector3 = tete.global_position + Vector3(0, 0.3, 0)
		var haut: Vector3 = src.lerp(bouche, 0.5) + Vector3(0, 0.45, 0)
		var tw: Tween = M.room.create_tween()
		tw.tween_property(bn, "global_position", haut, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(bn, "rotation", Vector3(3.0, 1.0, 2.0), 0.7)
		tw.tween_property(bn, "global_position", bouche, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(bn.queue_free)
		await M.get_tree().create_timer(0.75).timeout
		if not _la(M, room0):
			return
		M.main.sfx("manger", bouche)
		st["flash"] = 1.0
		_bulle(M, bouche + Vector3(0, 0.25, 0), "Miam, bip !", Color(0.7, 0.95, 1.0), 42, 0.45, 1.8)
		if not nuit:
			kid.gesture("rire", 1.5)
			kid.say(str(_pick(M, ["Il adore ça ! Les boulons de douze, surtout.", "Pas trop, Boulon, tu vas rouiller de l'intérieur !", "Mâche bien, Boulon !"])), 3.0)
		await M.get_tree().create_timer(1.5).timeout
		if not _la(M, room0):
			return
		if bool(M.state().get("fr_robot", false)):
			M.main.sfx("robot_bip", bouche, -4.0)
			return
		M.state()["fr_robot"] = true
		M.main.sfx("rot", bouche, -6.0)
		_bulle(M, bouche + Vector3(0, 0.25, 0), "Ptoui !", Color(1.0, 0.9, 0.5), 42, 0.45, 1.6)
		var txt: String
		if nuit:
			txt = "(L'enfant ouvre un œil, tout bas.) Il t'a donné une bague… Il fait ça avec les gens qu'il aime bien : il garde le boulon et il recrache l'écrou, tout rond, tout poli. Garde-la. Bonne nuit…"
		else:
			txt = "Oh ! Il t'a recraché une bague ! Il ne fait ça qu'avec les gens qu'il aime bien : il garde le boulon et il polit l'écrou dans son ventre. Garde-la : une vraie bague de boulon, comme celles de Lumi au Troc !"
		M.talk(kid, txt, I._bye("Merci, Boulon ! Bip !") if not nuit else I._bye("Merci… Bonne nuit, Boulon."), func(_i):
			M.give([["bague_boulon", 1]], "")
			M.close_talk(), "à voix basse" if nuit else "aux anges")
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(bot):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var mode: String = str(st["mode"])
		var p: Vector3 = st["pos"]
		var vit: float = 0.0
		var pp: Vector3 = M.main._player_pos_v27()
		match mode:
			"marche":
				st["boost"] = maxf(0.0, float(st["boost"]) - dt * 0.12)
				vit = 0.3 + 0.65 * float(st["boost"])
				var sa: float = float(st["s"])
				var dv := Vector2(-ax * sin(sa), az * cos(sa))
				sa += vit * dt / maxf(dv.length(), 0.05)
				st["s"] = sa
				p = boucle.call(sa)
				st["cap"] = atan2(-ax * sin(sa), az * cos(sa))
			"va":
				vit = 0.45
				var cible: Vector3 = st["cible"]
				var dd := Vector3(cible.x - p.x, 0.0, cible.z - p.z)
				if dd.length() < 0.03:
					p = cible
					var ens: String = str(st["ensuite"])
					if ens == "mange":
						st["mode"] = "mange"
						st["d"] = 3.2
						st["cap"] = atan2(jar_c.x - p.x, jar_c.z - p.z)
						croquer.call(jar_c)
					else:
						st["mode"] = "marche"
				else:
					p = p.move_toward(Vector3(cible.x, p.y, cible.z), dt * vit)
					st["cap"] = atan2(dd.x, dd.z)
			"main", "mange":
				st["d"] = float(st["d"]) - dt
				if mode == "main":
					st["cap"] = atan2(pp.x - p.x, pp.z - p.z)
				if float(st["d"]) <= 0.0:
					if mode == "main":
						var tw: Tween = M.room.create_tween()
						tw.tween_property(bras[1], "rotation:x", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
						st["mode"] = "marche"
					else:
						st["mode"] = "va"
						st["cible"] = boucle.call(float(st["s"]))
						st["ensuite"] = "marche"
					st["occupe"] = false
		st["pos"] = p
		# les pas : un petit rebond, les jambes de ressort, les bras qui balancent
		var ph: float = float(st["pas"]) + dt * vit * 16.0
		st["pas"] = ph
		var marche: float = 1.0 if vit > 0.0 else 0.0
		bot.global_position = p + Vector3(0, 0.012 * absf(sin(ph)) * marche, 0)
		bot.rotation.y = lerp_angle(bot.rotation.y, float(st["cap"]), clampf(dt * 6.0, 0.0, 1.0))
		(jambes[0] as Node3D).rotation.x = 0.45 * sin(ph) * marche
		(jambes[1] as Node3D).rotation.x = -0.45 * sin(ph) * marche
		if marche > 0.0:
			(bras[0] as Node3D).rotation.x = -0.35 * sin(ph) * marche
		if str(st["mode"]) != "main" and marche > 0.0:
			(bras[1] as Node3D).rotation.x = 0.35 * sin(ph) * marche
		var nod: float = 0.0
		if str(st["mode"]) == "mange":
			nod = 0.12 * sin(t * 18.0)
		tete.rotation.x = nod
		tete.rotation.z = 0.05 * sin(ph * 0.5) * marche
		# la clé se déroule (vite quand on vient de la remonter)
		var rem: float = maxf(0.0, float(st["remonte"]) - dt)
		st["remonte"] = rem
		cle.rotation.z += dt * (14.0 if rem > 0.0 else (0.8 + 2.5 * float(st["boost"])) * marche)
		# les yeux : ils clignent ; ils s'allument fort quand il est content ; la nuit, ils veillent tout bas
		st["cligne"] = float(st["cligne"]) - dt
		if float(st["cligne"]) <= 0.0:
			st["cligne"] = 2.0 + randf() * 3.5
		var fl: float = maxf(0.0, float(st["flash"]) - dt * 0.8)
		st["flash"] = fl
		var e: float = 2.5
		if nuit:
			e = 0.25 + 0.2 * sin(t * 1.3)
			if float(st["cligne"]) < 0.25:
				e = 0.05
		elif float(st["cligne"]) < 0.12:
			e = 0.0
		oeil.emission_energy_multiplier = e + 5.0 * fl
		# ses « bip » (la nuit, très bas)
		st["bip"] = float(st["bip"]) - dt
		if float(st["bip"]) <= 0.0:
			st["bip"] = (14.0 + randf() * 10.0) if nuit else (6.0 + randf() * 7.0)
			var tp: Vector3 = tete.global_position + Vector3(0, 0.4, 0)
			M.main.sfx("robot_bip", tp, -14.0 if nuit else -4.0)
			_bulle(M, tp, "bip…" if nuit else str(["Bip !", "Bip-bip !", "Biiip ?", "Bip ! Bip !"][randi() % 4]), Color(0.7, 0.95, 1.0), 30 if nuit else 38, 0.35, 1.3)
		# où l'on peut le toucher : sa main devant, sa clé derrière (elles le suivent)
		var fwd := Vector3(sin(bot.rotation.y), 0.0, cos(bot.rotation.y))
		if its.has("main"):
			(its["main"] as Dictionary)["pos"] = Vector3(p.x, sol, p.z) + fwd * 0.5
		if its.has("cle"):
			var cote := Vector3(fwd.z, 0.0, -fwd.x)
			(its["cle"] as Dictionary)["pos"] = Vector3(p.x, sol, p.z) + (cote * 0.5 if nuit else -fwd * 0.5)
	# --- le remonter
	var remonter := func() -> void:
		st["remonte"] = 1.3
		st["flash"] = 1.0
		M.main.sfx("robot_servo", bot.global_position, -10.0 if nuit else 0.0)
		_bulle(M, bot.global_position + Vector3(0, 1.1, 0), "Crric, crric, crric !", Color(1.0, 0.9, 0.6), 34 if nuit else 40, 0.4, 1.4)
		if nuit:
			S._say_late(M, kid, "Zzz… pas maintenant, Boulon… zzz…", 1.2, 3.0)
			await M.get_tree().create_timer(1.4).timeout
			if not _la(M, room0):
				return
			_bulle(M, tete.global_position + Vector3(0, 0.4, 0), "Bip ? … zzz.", Color(0.7, 0.95, 1.0), 32, 0.35, 1.6)
			M.say(str(_pick(M, ["Les yeux de Boulon s'allument un instant, il tourne la tête… puis se rendort, avec un tout petit « bip ».",
				"Boulon fait un quart de pas, réfléchit, et décide que la nuit, c'est pour recharger."])), 4.0)
			return
		st["boost"] = 1.0
		kid.gesture("joie", 1.6)
		kid.say(str(_pick(M, ["Remonté à bloc ! Attention, il va foncer !", "Pas trop fort, il va faire des tonneaux !", "Vas-y, Boulon ! Tour de piste !"])), 3.0)
	its["cle"] = M.act(depart, "E : remonter la clé de Boulon", remonter, 0.8, func(): return str(st["mode"]) == "marche" or str(st["mode"]) == "eteint")
	# --- lui serrer la main
	var serrer := func() -> void:
		if bool(st["occupe"]):
			return
		var tw: Tween = M.room.create_tween()
		M.main.sfx("robot_servo", bot.global_position, -10.0 if nuit else -2.0)
		if nuit:
			tw.tween_property(bras[1], "rotation:x", -0.7, 1.2).set_trans(Tween.TRANS_SINE)
			tw.tween_interval(0.8)
			tw.tween_property(bras[1], "rotation:x", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
			_bulle(M, tete.global_position + Vector3(0, 0.4, 0), "Bip… (bâillement)", Color(0.7, 0.95, 1.0), 30, 0.35, 2.0)
			M.say("Boulon lève à moitié son bras de ressort, sans ouvrir les yeux. Une poignée de main somnambule.", 4.0)
			return
		st["occupe"] = true
		st["mode"] = "main"
		st["d"] = 2.6
		st["flash"] = 0.8
		tw.tween_property(bras[1], "rotation:x", -1.35, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(bras[1], "rotation:x", -1.15, 0.15)
		tw.tween_property(bras[1], "rotation:x", -1.35, 0.15)
		tw.tween_property(bras[1], "rotation:x", -1.15, 0.15)
		_bulle(M, tete.global_position + Vector3(0, 0.4, 0), str(_pick(M, ["Bip ! Enchanté !", "Bip-bip ! Bonjour !", "Bip ! Main serrée !"])), Color(0.7, 0.95, 1.0), 40, 0.45, 1.8)
		S._say_late(M, kid, str(_pick(M, ["Il dit bonjour ! Enfin, « bip ». C'est pareil.", "Il serre doucement, hein ? Je lui ai appris la politesse.", "Bravo, Boulon ! Une vraie poignée de ressort !"])), 0.8, 3.0)
	its["main"] = M.act(depart, "E : serrer la main de Boulon", serrer, 0.8, func(): return (str(st["mode"]) == "marche" or str(st["mode"]) == "eteint") and not bool(st["occupe"]))
	# --- lui donner un boulon : il vient le manger à l'établi (la nuit : on le pose près de lui)
	var donner := func() -> void:
		if bool(st["occupe"]):
			return
		M.main.sfx("ramasse", jar_c, -4.0)
		if nuit:
			st["occupe"] = true
			M.say("Tu prends un boulon dans le bocal, sur la pointe des pieds, et tu le tends à Boulon.", 3.5)
			await M.get_tree().create_timer(0.8).timeout
			if not _la(M, room0):
				return
			croquer.call(bot.global_position + Vector3(0.0, 0.3, 0.0) + Vector3(sin(bot.rotation.y), 0.0, cos(bot.rotation.y)) * 0.45)
			await M.get_tree().create_timer(3.0).timeout
			if _la(M, room0):
				st["occupe"] = false
			return
		st["occupe"] = true
		st["mode"] = "va"
		st["cible"] = R.P(xj - dside * 0.25, 0.0, zl + 0.05)
		st["ensuite"] = "mange"
		M.say(str(_pick(M, ["Tu prends un boulon dans le bocal. Aussitôt, Boulon quitte sa piste et vient vers toi en cliquetant, les yeux qui brillent.",
			"Tu fais tinter un boulon contre le bocal. « Bip ! » Boulon fait demi-tour et accourt, ressorts au vent."])), 4.0)
		kid.say(str(_pick(M, ["Oh, il a faim ! Il entend un boulon à dix mètres.", "Un seul, hein ! Sinon il fait des bruits de casserole toute la nuit."])), 3.0)
	if nuit:
		M.act(R.P(coin.x + dside * 0.55, 0.0, coin.y), "E : donner un boulon à Boulon", donner, 0.9, func(): return not bool(st["occupe"]))
	else:
		M.act(R.P(xj - dside * 0.15, 0.0, zl + 0.3), "E : donner un boulon à Boulon", donner, 0.9, func(): return str(st["mode"]) == "marche" and not bool(st["occupe"]))
	# --- parler à l'enfant
	var kid_cb := func() -> void:
		if nuit:
			M.talk(kid, "Zzz… Boulon… pas les chaussettes… elles ne sont pas en fer… zzz…", I._bye("(Le laisser dormir)") if boy else I._bye("(La laisser dormir)"), I._close(M), "endormi" if boy else "endormie")
			return
		M.talk(kid, str(_pick(M, ["Salut, camarade ! Je te présente Boulon : trois boîtes de conserve, un entonnoir, onze ressorts et beaucoup d'amour. C'est moi qui l'ai fabriqué !",
			"Bon bricolage ! Attention aux pieds : Boulon ne freine pas très bien. Il dit « bip », et puis il te rentre dedans. Gentiment."])),
			[{"id": "marche", "label": "Comment il marche ?"}, {"id": "bricole", "label": "Tu connais Bricole ?"}, {"id": "fermer", "label": "Bon bricolage !"}], func(id):
			match id:
				"marche":
					M.talk(kid, "Avec une clé dans le dos, comme un jouet ! Tu la remontes, il fonce. Bricole voulait le brancher sur une chaudière. J'ai dit non : il est déjà assez énervé comme ça.", I._bye("Ha ha !"), I._close(M), "fier" if boy else "fière")
				"bricole":
					M.talk(kid, "C'est mon amie ! Elle m'a prêté un coin de l'Atelier Libre tout un hiver. Elle m'a appris à souder… enfin, à regarder souder, avec des grosses lunettes. Quand je serai grand, je serai inventeur, comme elle." if boy else "C'est mon amie ! Elle m'a prêté un coin de l'Atelier Libre tout un hiver. Elle m'a appris à souder… enfin, à regarder souder, avec des grosses lunettes. Quand je serai grande, je serai inventrice, comme elle.",
						I._bye("Tu y arriveras !"), I._close(M), "fier" if boy else "fière")
				_:
					M.close_talk()
		, "fier" if boy else "fière")
	M.talk_spot(kid, kid_cb)
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… Dans un coin, un petit robot de ferraille s'est éteint. Ses yeux d'ampoule clignotent tout doucement, comme une veilleuse.",
			"Il fait nuit. Un enfant dort dans un hamac ; dans le coin, son robot de boîtes de conserve veille, éteint, un œil qui clignote encore un peu.",
			"Tout est calme. On entend juste un « bip » très, très faible, de temps en temps : le robot rêve."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Un petit robot de boîtes de conserve fait le tour de la pièce en cliquetant, un entonnoir sur la tête. Ses yeux d'ampoule clignotent : « Bip ! »",
			"« Bip ! » Un robot haut comme une chaise te croise, te salue d'un ressort et continue sa ronde. Au fond, un enfant penché sur un établi lève le nez, très fier.",
			"Ça sent l'huile de vélo et la soudure. Un enfant règle un ressort à l'établi ; son robot, Boulon, fait des tours de piste au milieu de la pièce."]))


## Boulon, le robot de ferraille (at : ses pieds, monde ; il regarde +Z local) : le corps d'une grosse
## boîte de conserve et son étiquette rouge, la tête d'une petite, deux ampoules pour les yeux,
## l'entonnoir pour chapeau, des ressorts pour le cou, les bras et les jambes, une clé dans le dos.
static func _robot_boulon(M, at: Vector3) -> Dictionary:
	var n: Node3D = I._node(M, at, 0)
	var corps := Node3D.new()
	n.add_child(corps)
	var tole := _mat(Color(0.78, 0.8, 0.83), 0.85, 0.32)
	var rouge := _mat(Color(0.86, 0.22, 0.16), 0.2, 0.5)
	var jaune := _mat(Color(0.98, 0.78, 0.22), 0.2, 0.5)
	var ressort := _mat(Color(0.5, 0.5, 0.54), 0.9, 0.3)
	var cuivre := _mat(Color(0.82, 0.52, 0.3), 0.9, 0.35)
	var noir := _mat(Color(0.06, 0.06, 0.07), 0.3, 0.5)
	var oeil := _mat(Color(1.0, 0.86, 0.45), 0.0, 0.2, 2.5)
	var spire := TorusMesh.new()
	spire.inner_radius = 0.022
	spire.outer_radius = 0.034
	spire.rings = 10
	spire.ring_segments = 6
	# les jambes : des ressorts, et des pieds en boîte de sardines
	var jambes: Array = []
	for sx in [-1.0, 1.0]:
		var hanche := Node3D.new()
		corps.add_child(hanche)
		hanche.position = Vector3(sx * 0.065, 0.3, 0)
		for k in range(6):
			_p(hanche, spire, ressort, Vector3(0, -0.02 - k * 0.04, 0))
		_p(hanche, I._boxm(Vector3(0.08, 0.035, 0.14)), rouge, Vector3(0, -0.27, 0.02))
		jambes.append(hanche)
	# le corps : la grosse boîte, son étiquette, ses bords, un rivet doré
	_p(corps, I._cyl(0.14, 0.14, 0.3, 20), tole, Vector3(0, 0.46, 0))
	_p(corps, I._cyl(0.143, 0.143, 0.12, 20), rouge, Vector3(0, 0.46, 0))
	var bord := TorusMesh.new()
	bord.inner_radius = 0.135
	bord.outer_radius = 0.15
	bord.rings = 20
	bord.ring_segments = 6
	for yb in [0.315, 0.605]:
		_p(corps, bord, tole, Vector3(0, yb, 0))
	_p(corps, I._sph(0.025), jaune, Vector3(0, 0.48, 0.14), Vector3(1.0, 1.0, 0.4))
	# le cou, la tête, les yeux (deux ampoules dans leurs douilles), la bouche (une grille)
	_p(corps, spire, ressort, Vector3(0, 0.625, 0), Vector3(0.6, 1.0, 0.6))
	var tete := Node3D.new()
	corps.add_child(tete)
	tete.position = Vector3(0, 0.64, 0)
	_p(tete, I._cyl(0.1, 0.1, 0.15, 18), tole, Vector3(0, 0.075, 0))
	for sx2 in [-1.0, 1.0]:
		_p(tete, I._cyl(0.02, 0.02, 0.02, 10), cuivre, Vector3(sx2 * 0.045, 0.08, 0.1), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		_p(tete, I._sph(0.03), oeil, Vector3(sx2 * 0.045, 0.08, 0.125))
	_p(tete, I._boxm(Vector3(0.07, 0.012, 0.01)), noir, Vector3(0, 0.035, 0.1))
	# le chapeau : l'entonnoir, le bec en l'air (c'est par là qu'il mange)
	_p(tete, I._cyl(0.022, 0.11, 0.1, 18), cuivre, Vector3(0, 0.2, 0))
	_p(tete, I._cyl(0.012, 0.012, 0.08, 8), cuivre, Vector3(0, 0.29, 0))
	# les bras de ressort et leurs pinces
	var bras: Array = []
	for sx3 in [-1.0, 1.0]:
		var ep := Node3D.new()
		corps.add_child(ep)
		ep.position = Vector3(sx3 * 0.17, 0.56, 0)
		_p(ep, I._sph(0.03), tole, Vector3.ZERO)
		for k2 in range(5):
			_p(ep, spire, ressort, Vector3(0, -0.035 - k2 * 0.036, 0), Vector3(0.7, 1.0, 0.7))
		for sz in [-1.0, 1.0]:
			_p(ep, I._boxm(Vector3(0.015, 0.06, 0.015)), rouge, Vector3(0, -0.24, sz * 0.015), Vector3.ONE, Vector3(sz * 0.3, 0, 0))
		bras.append(ep)
	# la clé dans le dos
	var cle := Node3D.new()
	corps.add_child(cle)
	cle.position = Vector3(0, 0.47, -0.15)
	_p(cle, I._cyl(0.01, 0.01, 0.07, 8), cuivre, Vector3(0, 0, -0.03), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	for sx4 in [-1.0, 1.0]:
		_p(cle, I._sph(0.04), cuivre, Vector3(sx4 * 0.04, 0, -0.07), Vector3(1.0, 0.6, 0.25))
	return {"n": n, "corps": corps, "tete": tete, "jambes": jambes, "bras": bras, "cle": cle, "oeil": oeil}


# =================================================================== l'atelier de skates (en cours d'écriture, à part)

# =================================================================== l'atelier de skates

## Les couleurs vives de l'atelier de skates (peintures, autocollants, bandes des planches).
const PLANCHE_COULEURS := {
	"rouge": Color(0.9, 0.16, 0.14), "orange": Color(1.0, 0.52, 0.12), "jaune": Color(1.0, 0.84, 0.18),
	"vert": Color(0.25, 0.75, 0.3), "bleu": Color(0.18, 0.42, 0.92), "violet": Color(0.6, 0.3, 0.85),
	"rose": Color(1.0, 0.45, 0.7), "turquoise": Color(0.15, 0.78, 0.78), "noir": Color(0.06, 0.06, 0.07),
	"blanc": Color(0.96, 0.95, 0.92),
}
## Les trois peintures qu'on peut choisir : les six bandes de la planche de l'établi.
const PLANCHE_CHOIX := {
	"rouge_noir": ["rouge", "noir", "rouge", "noir", "rouge", "noir"],
	"jaune_bleu": ["jaune", "bleu", "jaune", "bleu", "jaune", "bleu"],
	"toutes": ["rouge", "orange", "jaune", "vert", "bleu", "violet"],
}
## La planche : le plateau du milieu, les deux bouts relevés (longueur, angle), l'épaisseur, la largeur ;
## la hauteur du plateau quand elle est posée sur ses roues.
const PLANCHE_L0: float = 0.5
const PLANCHE_LE: float = 0.15
const PLANCHE_A: float = 0.38
const PLANCHE_T: float = 0.018
const PLANCHE_W: float = 0.2
const PLANCHE_HAUT: float = 0.077


## Les peintures de l'atelier (« pl_rouge », « pl_jaune »…), pour la géométrie fixe de la pièce.
static func _planche_mats(M) -> void:
	var R = M.R
	if R.kit.mats.has("pl_rouge"):
		return
	for k in PLANCHE_COULEURS:
		R._put("pl_" + str(k), R._col(PLANCHE_COULEURS[k], 0.45))


## Une planche finie, en géométrie fixe (R.kit), au repère xf : x le long de la planche, y vers le
## dessus, z en travers. Dessous : les bandes de couleur (c'est là qu'on peint), deux essieux, quatre roues.
static func _planche_kit(M, xf: Transform3D, base: String, bandes: Array) -> void:
	var R = M.R
	var t: float = PLANCHE_T
	R.kit.box(xf, Vector3(PLANCHE_L0, t, PLANCHE_W), base, 1.0)
	for s in [-1.0, 1.0]:
		var bout := Transform3D(Basis(Vector3.BACK, s * PLANCHE_A), Vector3(s * (PLANCHE_L0 * 0.5 + PLANCHE_LE * 0.5 * cos(PLANCHE_A)), PLANCHE_LE * 0.5 * sin(PLANCHE_A), 0))
		R.kit.box(xf * bout, Vector3(PLANCHE_LE, t, PLANCHE_W), base, 1.0)
	var nb: int = bandes.size()
	for k in range(nb):
		var bx: float = -PLANCHE_L0 * 0.5 + PLANCHE_L0 * (k + 0.5) / nb
		R.kit.box(xf * Transform3D(Basis(), Vector3(bx, -t * 0.5 - 0.002, 0)), Vector3(PLANCHE_L0 / nb * 0.7, 0.004, PLANCHE_W * 0.96), str(bandes[k]), 1.0)
	for sx in [-1.0, 1.0]:
		R.kit.box(xf * Transform3D(Basis(), Vector3(sx * 0.17, -t * 0.5 - 0.018, 0)), Vector3(0.04, 0.03, 0.15), "argent", 1.0)
		for sz in [-1.0, 1.0]:
			R.kit.cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(sx * 0.17, -t * 0.5 - 0.04, sz * 0.085 - 0.015)), 0.028, 0.028, 0.03, "noir", 10)


## Une planche qui bouge (même repère que _planche_kit, le nœud n posé PLANCHE_HAUT au-dessus du sol) :
## les bandes de couleur sur le dessus (cols : leurs couleurs), les roues dessous (nr : combien sont
## vissées ; les autres attendent, invisibles). Renvoie {"bandes": [...], "roues": [...]}.
static func _planche_mobile(n: Node3D, bois: Material, cols: Array, nr: int = 4) -> Dictionary:
	var t: float = PLANCHE_T
	_p(n, I._boxm(Vector3(PLANCHE_L0, t, PLANCHE_W)), bois, Vector3.ZERO)
	for s in [-1.0, 1.0]:
		_p(n, I._boxm(Vector3(PLANCHE_LE, t, PLANCHE_W)), bois, Vector3(s * (PLANCHE_L0 * 0.5 + PLANCHE_LE * 0.5 * cos(PLANCHE_A)), PLANCHE_LE * 0.5 * sin(PLANCHE_A), 0), Vector3.ONE, Vector3(0, 0, s * PLANCHE_A))
	var bandes: Array = []
	var nb: int = cols.size()
	for k in range(nb):
		var bx: float = -PLANCHE_L0 * 0.5 + PLANCHE_L0 * (k + 0.5) / nb
		bandes.append(_p(n, I._boxm(Vector3(PLANCHE_L0 / nb * 0.7, 0.004, PLANCHE_W * 0.96)), _mat(cols[k], 0.0, 0.4), Vector3(bx, t * 0.5 + 0.002, 0)))
	var fer := _mat(Color(0.75, 0.76, 0.8), 0.8, 0.35)
	var noir := _mat(Color(0.07, 0.07, 0.08), 0.0, 0.9)
	var roues: Array = []
	for sx in [-1.0, 1.0]:
		_p(n, I._boxm(Vector3(0.04, 0.03, 0.15)), fer, Vector3(sx * 0.17, -t * 0.5 - 0.018, 0))
		for sz in [-1.0, 1.0]:
			var ro: MeshInstance3D = _p(n, I._cyl(0.028, 0.028, 0.03, 12), noir, Vector3(sx * 0.17, -t * 0.5 - 0.04, sz * 0.085), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
			if roues.size() >= nr:
				ro.visible = false
				ro.scale = Vector3(0.01, 0.01, 0.01)
			roues.append(ro)
	return {"bandes": bandes, "roues": roues}


## Un pot de peinture en fer-blanc (couvercle ouvert ou fermé, une étiquette et une coulure de couleur).
static func _planche_pot(M, x: float, y: float, z: float, col: String, ouvert: bool) -> void:
	var R = M.R
	R.kit.cyl(R.L(x, y, z), 0.055, 0.055, 0.11, "argent", 12)
	R.kit.cyl(R.L(x, y + 0.03, z), 0.057, 0.057, 0.04, col, 12, false)
	R.kit.cyl(R.L(x, y + 0.11, z), 0.05 if ouvert else 0.058, 0.05 if ouvert else 0.058, 0.006, col, 12)
	R.kit.box(R.L(x + 0.056, y + 0.085, z), Vector3(0.006, 0.05, 0.018), col, 1.0)
	if not ouvert:
		R.kit.cyl(R.L(x, y + 0.116, z), 0.02, 0.02, 0.01, "argent", 8)


## L'atelier de skates (la Fronde) : un parent et son enfant fabriquent des planches avec de la récup'.
## Contre un mur, l'établi (une planche en cours, des roues en couvercles de bocaux et en roulements,
## des pots de peinture, des autocollants) et son axe d'essai, où une roue tourne ; au fond, le mur des
## planches finies, chacune peinte autrement ; au sol, un tapis à graffitis où l'enfant fait rouler une
## planche d'un bout à l'autre de la pièce (elle rebondit sur un vieux pneu et revient). On peut faire
## siffler la roue, visser la dernière roue (« Et de une ! » : une bague de boulon, une seule fois),
## choisir les couleurs de la planche de l'établi. La nuit, l'enfant dort, sa planche sous l'oreiller ;
## le parent ponce à la bougie… ou s'est endormi sur son tabouret.
## Tout suit R.W et R.D : un conteneur (6,1 × 2,44 m, un couloir) ou une chaudière (4,6 × 6 m).
static func _planche(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var nuit: bool = _nuit(M)
	var dodo: bool = nuit and r.randf() < 0.35
	var long: bool = R.W >= R.D
	var boy: bool = r.randf() < 0.5
	var papa: bool = r.randf() < 0.5
	_planche_mats(M)
	var noms: Array = PLANCHE_COULEURS.keys()
	# l'établi, contre le mur de gauche, vers le fond (son devant regarde la pièce, vers +x)
	var ex: float = -hw + 0.42
	var ez: float = -hd + 0.85
	var top: float = 0.92
	R.etabli(ex, ez, 90.0, 1.5)
	R.reserve(ex + 0.1, ez, 1.1, 1.7)
	# dessus : des pots de peinture, un bocal de roues en couvercles, une pile de roues, des autocollants
	_planche_pot(M, ex - 0.25, top, ez - 0.55, "pl_" + str(_pick(M, ["rouge", "jaune", "bleu"])), true)
	_planche_pot(M, ex - 0.12, top, ez - 0.7, "pl_" + str(_pick(M, ["vert", "rose", "turquoise"])), false)
	_planche_pot(M, ex - 0.3, top, ez - 0.74, "pl_" + str(_pick(M, ["noir", "orange", "violet"])), true)
	R.kit.cyl(R.L(ex - 0.3, top, ez + 0.3), 0.05, 0.05, 0.15, "verre", 12)
	for k in range(5):
		R.kit.cyl(R.L(ex - 0.3, top + 0.01 + k * 0.025, ez + 0.3), 0.04, 0.04, 0.012, "argent" if k % 2 == 0 else "pl_rouge", 10)
	for k2 in range(4):
		R.kit.cyl(R.L(ex - 0.3 + r.randf_range(-0.01, 0.01), top + k2 * 0.03, ez + 0.62), 0.035, 0.035, 0.028, "noir" if k2 % 2 == 0 else "fer", 10)
	for k3 in range(5):
		R.kit.box(R.L(ex + 0.22 + r.randf_range(0.0, 0.12), top + 0.002, ez - 0.22 - r.randf_range(0.0, 0.28), r.randf() * 90.0), Vector3(0.05, 0.003, 0.05), "pl_" + str(noms[r.randi() % noms.size()]), 1.0)
	# dessous, sur la tablette : trois planches brutes et deux pots
	for k4 in range(3):
		R.kit.box(R.L(ex + 0.05, 0.28 + k4 * 0.02, ez - 0.2, 90.0 + r.randf_range(-4, 4)), Vector3(0.78, 0.018, 0.2), "bois_clair", 1.0)
	_planche_pot(M, ex - 0.05, 0.27, ez + 0.42, "pl_" + str(_pick(M, ["bleu", "jaune"])), false)
	_planche_pot(M, ex + 0.12, 0.27, ez + 0.56, "pl_" + str(_pick(M, ["rouge", "vert"])), false)
	# l'axe d'essai, au bout de l'établi : deux montants, un axe, et la roue (elle tourne)
	var axe := Vector3(ex - 0.1, top + 0.13, ez + 0.55)
	R.kit.box(R.L(axe.x, top + 0.008, axe.z), Vector3(0.16, 0.016, 0.12), "bois_sombre", 1.0)
	for sx in [-1.0, 1.0]:
		R.kit.box(R.L(axe.x + sx * 0.045, top + 0.075, axe.z), Vector3(0.016, 0.13, 0.04), "fer", 1.0)
	R.kit.cyl(R.L(axe.x - 0.06, axe.y, axe.z) * Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3.ZERO), 0.008, 0.008, 0.12, "argent", 8)
	var piv: Node3D = I._node(M, R.P(axe.x, axe.y, axe.z), 0.0)
	var roue := Node3D.new()
	piv.add_child(roue)
	var rz := Vector3(0, 0, PI * 0.5)
	_p(roue, I._cyl(0.09, 0.09, 0.035, 20), _mat(Color(0.07, 0.07, 0.08), 0.0, 0.9), Vector3.ZERO, Vector3.ONE, rz)
	_p(roue, I._cyl(0.05, 0.05, 0.04, 16), _mat(Color(0.65, 0.66, 0.7), 0.8, 0.35), Vector3.ZERO, Vector3.ONE, rz)
	_p(roue, I._boxm(Vector3(0.006, 0.03, 0.03)), _mat(PLANCHE_COULEURS["jaune"]), Vector3(0.02, 0.066, 0))
	_p(roue, I._boxm(Vector3(0.006, 0.03, 0.03)), _mat(PLANCHE_COULEURS["rouge"]), Vector3(0.02, -0.066, 0))
	_sans_ombre(piv)
	# la planche en cours, sur l'établi : du bois brut, trois roues sur quatre, pas encore peinte
	var bp: Vector3 = R.P(ex - 0.12, top + PLANCHE_HAUT, ez - 0.05)
	var nb: Node3D = I._node(M, bp, 90.0)
	var blanc: Color = PLANCHE_COULEURS["blanc"]
	var pb: Dictionary = _planche_mobile(nb, _mat(Color(0.84, 0.68, 0.48), 0.0, 0.75), [blanc, blanc, blanc, blanc, blanc, blanc], 3)
	for b0 in pb["bandes"]:
		(b0 as Node3D).visible = false
	# le mur des planches finies, au fond : chacune peinte autrement, sur son crochet
	var x0: float = -hw + 1.0
	var x1: float = hw - 1.0
	var nbp: int = clampi(int((x1 - x0) / 0.32) + 1, 3, 10)
	var pas: float = (x1 - x0) / float(nbp - 1)
	R.mark_wall((x0 + x1) * 0.5, 1.45, -hd + 0.02, (x1 - x0) * 0.5 + 0.2)
	var au_mur := Basis(Vector3.UP, Vector3(0, 0, -1), Vector3(-1, 0, 0))
	for k5 in range(nbp):
		var bx: float = x0 + pas * k5
		var by: float = 1.45 + r.randf_range(-0.05, 0.05)
		var bandes: Array = []
		for j in range(r.randi_range(2, 5)):
			bandes.append("pl_" + str(noms[r.randi() % noms.size()]))
		_planche_kit(M, R.L(bx, by, -hd + 0.1) * Transform3D(au_mur, Vector3.ZERO), "pl_" + str(noms[r.randi() % noms.size()]) if r.randf() < 0.6 else "bois_clair", bandes)
		R.kit.box(R.L(bx, by + 0.42, -hd + 0.05), Vector3(0.03, 0.03, 0.08), "fer", 1.0)
	# des autocollants plein le bas du mur
	for k6 in range(16):
		var sx2: float = r.randf_range(x0 - 0.3, x1 + 0.3)
		R.kit.box(R.L(sx2, r.randf_range(0.3, 0.85), -hd + 0.012) * Transform3D(Basis(Vector3.BACK, r.randf_range(-0.6, 0.6)), Vector3.ZERO), Vector3(0.06, 0.06, 0.004), "pl_" + str(noms[r.randi() % noms.size()]), 1.0)
	# le matelas de l'enfant, sur une palette, contre le mur de droite
	var mx: float = hw - 0.5
	var mz: float = -hd + 1.07
	R.kit.box(R.L(mx, 0.06, mz), Vector3(0.86, 0.12, 1.96), "bois_clair", 1.0)
	for k7 in range(3):
		R.kit.box(R.L(mx, 0.06, mz - 0.9 + k7 * 0.9), Vector3(0.88, 0.1, 0.1), "bois_sombre", 1.0)
	R.kit.box(R.L(mx, 0.2, mz), Vector3(0.8, 0.16, 1.9), "drap", 1.0)
	R.kit.box(R.L(mx, 0.29, mz + 0.25), Vector3(0.82, 0.04, 1.3), "tissu_" + str(_pick(M, ["rouge", "orange", "turquoise", "violet", "jaune"])), 1.0)
	R.kit.box(R.L(mx, 0.33, mz - 0.72), Vector3(0.55, 0.1, 0.32), "drap", 1.0)
	R.kit.col_box(R.L(mx, 0.14, mz), Vector3(0.86, 0.28, 1.96))
	R.reserve(mx, mz, 1.0, 2.1)
	# la piste : d'un bout à l'autre de la pièce (le long du couloir, ou de la porte vers le fond)
	var la: Vector2
	var lb: Vector2
	if long:
		var lz: float = -hd + 0.45
		la = Vector2(hw - 1.55, lz)
		lb = Vector2(-hw + 1.42, lz)
	else:
		var lx: float = 0.15
		la = Vector2(lx, hd - 2.1)
		lb = Vector2(lx, -hd + 0.92)
	var dir: Vector2 = (lb - la).normalized()
	var d3 := Vector3(dir.x, 0, dir.y)
	# le tapis à graffitis, sous la piste
	var rw: float = absf(lb.x - la.x) + 1.1 if long else 1.3
	var rd: float = 1.2 if long else absf(lb.y - la.y) + 1.1
	var rc: Vector2 = (la + lb) * 0.5
	rc = Vector2(clampf(rc.x, -hw + rw * 0.5 + 0.05, hw - rw * 0.5 - 0.05), clampf(rc.y, -hd + rd * 0.5 + 0.05, hd - rd * 0.5 - 0.05))
	R.tapis(rc.x, rc.y, 0.0, rw, rd)
	R.reserve(rc.x, rc.y, rw, rd)
	# le vieux pneu, au bout de la piste : la planche rebondit dessus
	var tp: Vector2 = lb + dir * 0.42
	var pneu := Transform3D(Basis(d3.cross(Vector3.UP), d3, Vector3.UP), R.P(tp.x, 0.22, tp.y))
	var pneu2 := Transform3D(Basis((-d3).cross(Vector3.UP), -d3, Vector3.UP), R.P(tp.x, 0.22, tp.y) + d3 * 0.11)
	R.kit.ring(pneu, 0.12, 0.22, 0.11, "noir", 20)
	R.kit.ring(pneu2, 0.12, 0.22, 0.11, "noir", 20)
	R.kit.cyl(pneu * Transform3D(Basis(), Vector3(0, 0.035, 0)), 0.12, 0.12, 0.04, "fer", 14)
	# une affiche de concert sur le mur de la porte, loin de la porte
	for cx in [-hw + 0.6, hw - 0.6]:
		if absf(float(cx) - R.door_x) > 1.2 and R.wall_free(float(cx), 1.5, hd - 0.02, 0.4):
			R.tableau(float(cx), 1.5, hd - 0.02, 180.0, 0.45, 0.62)
			break
	# la planche qui roule (la nuit : sous l'oreiller)
	var cols_r: Array = []
	for k8 in range(4):
		cols_r.append(PLANCHE_COULEURS[noms[r.randi() % noms.size()]])
	var pa: Vector3 = R.P(la.x, PLANCHE_HAUT, la.y)
	var pbt: Vector3 = R.P(lb.x, PLANCHE_HAUT, lb.y)
	var yaw_l: float = rad_to_deg(atan2(-dir.y, dir.x))
	var nr: Node3D
	if nuit:
		nr = I._node(M, R.P(mx, 0.35, mz - 0.72), 0.0)
	else:
		nr = I._node(M, pa, yaw_l)
	_planche_mobile(nr, _mat(Color(0.86, 0.7, 0.5), 0.0, 0.75), cols_r)
	# les gens : le parent à l'établi, l'enfant au bout de la piste ; la nuit, l'enfant dort
	var pp: Vector2 = _dedans(M, ex + 0.85, ez + 0.05)
	var parent: Node
	var kid: Node
	var role_p: String = "homme" if papa else "femme"
	if dodo:
		R.tabouret(pp.x, pp.y)
		parent = M.person(role_p, pp.x, pp.y, -90.0, "dormir_assis")
		parent.lines = ["Zzz…", "Zzz… et de deux… et de trois… zzz…", "Zzz… pas sur la tôle… zzz…", "Mmh… le papier de verre… zzz…"]
		parent.line_every = Vector2(10.0, 15.0)
	else:
		parent = M.person(role_p, pp.x, pp.y, -90.0, "bricoler")
		if nuit:
			R.bougie(ex - 0.3, top, ez - 0.22)
			parent.lines = ["Chut… Il dort avec sa planche." if boy else "Chut… Elle dort avec sa planche.", "Frrt… frrt… Tout doux, le papier de verre.", "Encore une, et je vais me coucher. Promis.", "Demain matin, surprise…"]
			parent.line_every = Vector2(10.0, 15.0)
		else:
			parent.lines = ["Et un tour de vis…", "Qui a pris mon tournevis ? … Ah. Il est dans ma main.", "Doucement sur les murs, c'est de la tôle !", "Une planche, c'est trois bouts de rien et beaucoup de patience.", "Bon bricolage !"]
	R.reserve(pp.x, pp.y, 0.6, 0.6)
	if nuit:
		kid = M.person("garcon" if boy else "fille", mx, mz, 180.0, "dormir")
		kid.lie(R.P(mx, 0.26, mz + 0.8), Vector3(0, 0, -1))
		kid.lines = ["Zzz…", "Zzz… un ollie… deux ollies… zzz…", "Zzz… plus vite… zzz…", "Mmh… ma planche… zzz…"]
		kid.line_every = Vector2(9.0, 14.0)
	else:
		var kp: Vector2 = _dedans(M, la.x - dir.x * 0.5, la.y - dir.y * 0.5)
		kid = M.person("garcon" if boy else "fille", kp.x, kp.y, _vers(kp.x, kp.y, kp.x + dir.x, kp.y + dir.y), "debout")
		kid.lines = ["Attention, ça roule !", "Elle va jusqu'au bout ! Presque !", "Plus tard, je ferai le tour du Gouffre en skate.", "Ressort va être vert de jalousie !", "Boing ! Et elle revient !"]
		kid.line_every = Vector2(6.0, 10.0)
		R.reserve(kp.x, kp.y, 0.6, 0.6)
	var humeur: String = "endormi" if papa else "endormie"
	if not dodo:
		humeur = "à voix basse" if nuit else "les mains pleines de peinture"
	# ce dont la maison se souvient : une bague de boulon, la première planche finie
	var recompense := func() -> void:
		M.bonne_action_v120()  ## V120 : une bonne action, l'île s'en souvient
		if bool(M.state().get("fr_planche", false)):
			return
		M.state()["fr_planche"] = true
		if dodo:
			M.give([["bague_boulon", 1]], "Sur l'établi, à côté de la planche finie, il reste un boulon tout rond, poli comme un bijou : une bague de boulon, comme celles de Lumi. Tu la gardes en souvenir.")
			return
		var txt: String = "(Tout bas.) Merci du coup de main. Tenez : il me restait un boulon, j'en ai fait une bague. Une bague de boulon, comme celles de Lumi. Chut, c'est pour vous." if nuit else "Merci du coup de main, camarade ! Tenez : il me restait un boulon, j'en ai fait une bague. Une bague de boulon, comme celles de Lumi. Elle vous va bien !"
		M.talk(parent, txt, I._bye("Merci, camarade !"), func(_i):
			M.give([["bague_boulon", 1]], "")
			M.close_talk(), humeur)
	# ce qui bouge : la roue d'essai, la planche qui va et vient (la nuit : le papier de verre)
	var idle: float = 0.25 if nuit else 0.8
	var dur: float = maxf(1.6, la.distance_to(lb) / 1.25)
	var etabli_at: Vector3 = R.P(ex - 0.1, top + 0.35, ez)
	var st := {"t": 0.0, "w": idle, "ph": "attend", "u": 0.0, "d": 1.0 + r.randf() * 2.0, "frrt": 3.0, "vis": false}
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(roue):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var w: float = lerpf(float(st["w"]), idle, clampf(dt * 0.35, 0.0, 1.0))
		st["w"] = w
		roue.rotation.x = wrapf(roue.rotation.x + w * dt, -PI, PI)
		if nuit:
			if not dodo:
				st["frrt"] = float(st["frrt"]) - dt
				if float(st["frrt"]) <= 0.0:
					st["frrt"] = 5.0 + randf() * 4.0
					_bulle(M, etabli_at, "frrt… frrt…", Color(0.95, 0.85, 0.65), 28, 0.3, 1.8)
			return
		if not is_instance_valid(nr):
			return
		var ph: String = str(st["ph"])
		if ph == "attend":
			st["d"] = float(st["d"]) - dt
			if float(st["d"]) <= 0.0:
				st["ph"] = "aller"
				st["u"] = 0.0
				M.main.sfx("skate", nr.global_position)
			return
		var u: float = minf(1.0, float(st["u"]) + dt / dur)
		st["u"] = u
		var s: float = u * (1.5 - 0.5 * u)
		if ph == "retour":
			s = 1.0 - s
		nr.global_position = pa.lerp(pbt, s)
		nr.rotation.x = 0.03 * sin(t * 11.0)
		if u >= 1.0:
			nr.rotation.x = 0.0
			if ph == "aller":
				st["ph"] = "retour"
				st["u"] = 0.0
				M.main.sfx("touche_bois", pbt)
				if randf() < 0.4:
					_bulle(M, pbt + Vector3(0, 0.35, 0), "Boing !", Color(1.0, 0.85, 0.3), 36, 0.4, 1.2)
			else:
				st["ph"] = "attend"
				st["d"] = 1.5 + randf() * 2.5
				if randf() < 0.35 and is_instance_valid(kid):
					kid.gesture("joie", 1.2)
	# faire tourner la roue : elle siffle
	M.act(R.P(ex + 0.85, 0, ez + 0.55), "E : faire tourner la roue", func() -> void:
		st["w"] = 30.0
		M.main.sfx("rouage", piv.global_position)
		_bulle(M, piv.global_position + Vector3(0, 0.2, 0), "Fiiiiiouuu !", Color(0.85, 0.95, 1.0), 36, 0.45, 1.6)
		if dodo:
			M.say("La roue siffle tout bas dans le noir. Personne ne se réveille. Enfin, presque : quelqu'un marmonne « et de deux… ».", 4.5)
		elif nuit:
			parent.say("Chut… Elle siffle fort, celle-là. Elle va réveiller tout le monde.", 3.5)
		else:
			M.say(str(_pick(M, ["La roue file sur son axe d'essai et se met à siffler, de plus en plus aigu. Un bon roulement, ça chante.",
				"Fiiiiiou ! La roue tourne si vite que ses deux autocollants, le jaune et le rouge, n'en font plus qu'un, tout orange."])), 4.5)
			kid.say(str(_pick(M, ["Elle siffle ! Ça veut dire qu'elle est contente !", "Plus vite ! Encore !", "Celle-là, c'est pour ma prochaine planche !"])), 2.8)
	, 0.9)
	# visser la dernière roue : la planche est finie
	M.act(R.P(ex + 0.85, 0, ez - 0.05), "E : visser une roue", func() -> void:
		if bool(st["vis"]):
			return
		st["vis"] = true
		var r4: Node3D = (pb["roues"] as Array)[3]
		r4.visible = true
		M.main.sfx("mecanisme", bp)
		_bulle(M, bp + Vector3(0, 0.25, 0), "Crrr… crrr… clac !", Color(0.9, 0.9, 0.95), 32, 0.4, 1.6)
		var tw: Tween = M.room.create_tween()
		tw.tween_property(r4, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.4)
		tw.tween_callback(func() -> void:
			M.main.sfx("touche_bois", bp)
			if not is_instance_valid(parent):
				return
			if dodo:
				parent.say("Zzz… et de une… zzz…", 3.0)
			elif nuit:
				parent.say("(Tout bas.) Et de une !", 2.5)
			else:
				parent.gesture("joie", 1.5)
				parent.say("Et de une !", 2.5)
				if is_instance_valid(kid):
					kid.say("Elle est finie ? Je peux l'essayer ? Dis oui !", 3.0))
		tw.tween_interval(1.6)
		tw.tween_callback(recompense)
	, 0.9, func(): return not bool(st["vis"]))
	# choisir les couleurs de la planche de l'établi (une petite conversation à choix)
	var peindre := func(id: String) -> void:
		var cols: Array = PLANCHE_CHOIX[id]
		var bandes: Array = pb["bandes"]
		var tw: Tween = M.room.create_tween()
		for k in range(bandes.size()):
			var mi: MeshInstance3D = bandes[k]
			mi.material_override = _mat(PLANCHE_COULEURS[cols[k % cols.size()]], 0.0, 0.4)
			mi.scale = Vector3(1.0, 1.0, 0.02)
			mi.visible = true
			tw.tween_property(mi, "scale", Vector3.ONE, 0.18)
		M.main.sfx("verser", bp)
		_bulle(M, bp + Vector3(0, 0.25, 0), "Splotch !", PLANCHE_COULEURS[cols[0]].lightened(0.3), 38, 0.45, 1.5)
		if not nuit and is_instance_valid(kid):
			kid.say(str(_pick(M, ["Ouaaah ! Elle est trop belle !", "Je la veux ! Je la veux !", "C'est la plus belle du mur !"])), 2.5)
	var choix: Array = [{"id": "rouge_noir", "label": "Rouge et noir"}, {"id": "jaune_bleu", "label": "Jaune et bleu"},
		{"id": "toutes", "label": "Toutes à la fois !"}, {"id": "fermer", "label": "Je réfléchis encore…"}]
	M.act(R.P(ex + 0.85, 0, ez - 0.6), "E : choisir les couleurs", func() -> void:
		var q: String = "Zzz… les couleurs… rouge et noir ? Jaune et bleu ? … zzz…"
		if not dodo:
			q = "(Tout bas.) Vous voulez choisir ? D'accord, mais en silence. Rouge et noir, jaune et bleu… ou toutes à la fois ?" if nuit else str(_pick(M, ["Elle attend sa peinture, celle-là. Vous choisissez ? Rouge et noir, jaune et bleu… ou toutes les couleurs à la fois ?",
				"À vous l'honneur, camarade : de quelles couleurs on la peint ?"]))
		M.talk(parent, q, choix, func(id):
			var k: String = str(id)
			if not PLANCHE_CHOIX.has(k):
				M.close_talk()
				return
			peindre.call(k)
			var rep: String
			match k:
				"rouge_noir":
					rep = "Rouge et noir ! La planche des pirates du Gouffre. Elle ira deux fois plus vite. C'est scientifique."
					if dodo:
						rep = "Zzz… rouge et noir… très joli… zzz…"
					elif nuit:
						rep = "(Tout bas.) Rouge et noir… Superbe. Elle ira deux fois plus vite. C'est scientifique."
				"jaune_bleu":
					rep = "Jaune et bleu ! Comme le Soleil de Laiton sur les cristaux de la mine. Fusain va être jaloux."
					if dodo:
						rep = "Zzz… jaune et bleu… comme le soleil… zzz…"
					elif nuit:
						rep = "(Tout bas.) Jaune et bleu… Comme le Soleil de Laiton sur les cristaux. Joli."
				_:
					rep = "Toutes à la fois ! Ça, c'est une planche de la Fronde. On la verra arriver de l'autre côté du Pont !"
					if dodo:
						rep = "Zzz… toutes… les couleurs… zzz…"
					elif nuit:
						rep = "(Tout bas.) Toutes à la fois… Elle va briller dans le noir, celle-là."
			M.talk(parent, rep, I._bye("Bonne nuit…" if nuit else "Bon bricolage !"), I._close(M), humeur)
		, humeur)
	, 0.9)
	# parler au parent
	var parent_cb := func() -> void:
		if dodo:
			M.talk(parent, "Zzz… Ressort… pas sur la rampe… zzz… et de deux…", I._bye("(Le laisser dormir)" if papa else "(La laisser dormir)"), I._close(M), humeur)
			return
		if nuit:
			M.talk(parent, "(Tout bas.) Chut… Il dort avec sa planche sous l'oreiller. Moi, je ponce la prochaine : demain matin, surprise." if boy else "(Tout bas.) Chut… Elle dort avec sa planche sous l'oreiller. Moi, je ponce la prochaine : demain matin, surprise.",
				[{"id": "surprise", "label": "Une surprise ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if str(id) == "surprise":
					M.talk(parent, "Sa première planche toute neuve. Pas de la récup' : du beau bois, et des roues qui sifflent. Ne lui dites rien, hein.", I._bye("Promis. Bonne nuit !"), I._close(M), humeur)
				else:
					M.close_talk()
			, humeur)
			return
		var accueil: String = str(_pick(M, ["Salut, camarade ! Attention à vos pieds : ici, les planches roulent toutes seules. Enfin, presque.",
			"Bon bricolage ! Bienvenue à l'atelier. Enfin, chez nous. Ici, c'est pareil."]))
		M.talk(parent, accueil, [{"id": "roues", "label": "Où trouvez-vous les roues ?"}, {"id": "ressort", "label": "Ressort est votre client ?"}, {"id": "fermer", "label": "Bon bricolage !"}], func(id):
			match str(id):
				"roues":
					M.talk(parent, "Les roues ? Des couvercles de bocaux de la Cantine Libre, avec un rond de caoutchouc autour. Et les roulements, c'est Lumi, au Troc : elle nous garde ceux qui sont trop moches pour faire des bijoux.", I._bye("Malin !"), I._close(M), humeur)
				"ressort":
					M.talk(parent, "Notre meilleur client ! Et notre pire : il en use une par semaine. Il dit que nos roues sifflent mieux que celles de son père. Ne le répétez pas à Bricole.", I._bye("Ha ha ! Promis."), I._close(M), humeur)
				_:
					M.close_talk()
		, humeur)
	M.talk_spot(parent, parent_cb)
	# parler à l'enfant
	var kid_cb := func() -> void:
		if nuit:
			M.talk(kid, str(_pick(M, ["Zzz… un ollie… deux ollies… zzz…", "Zzz… plus vite… le Pont… zzz…"])), I._bye("(Le laisser dormir)" if boy else "(La laisser dormir)"), I._close(M), "endormi" if boy else "endormie")
			return
		M.talk(kid, str(_pick(M, ["Salut, camarade ! Tu as vu ma planche ? Elle roule d'un bout à l'autre ! Enfin, si je la pousse.",
			"Chut, je m'entraîne. Le jour où je bats Ressort, tu pourras dire que tu étais là."])),
			[{"id": "peint", "label": "C'est toi qui l'as peinte ?"}, {"id": "figure", "label": "Tu sais faire des figures ?"}, {"id": "fermer", "label": "Salut, camarade !"}], func(id):
			match str(id):
				"peint":
					M.talk(kid, "Oui ! Avec mes doigts, et un peu avec mon nez. Les autocollants, ce sont les étiquettes des pots de confiture de Mémé Gamelle.", I._bye("Elle est superbe !"), I._close(M), "aux anges")
				"figure":
					M.talk(kid, "Je sais faire le « pneu » : je la pousse, elle rebondit sur le pneu, elle revient. Ressort dit que ce n'est pas une figure. Moi, je dis que si.", I._bye("C'est une figure !"), I._close(M), "aux anges")
				_:
					M.close_talk()
		, "aux anges")
	M.talk_spot(kid, kid_cb)
	# le texte d'entrée
	if dodo:
		M.ctx["entree"] = str(_pick(M, ["Tout dort. Près de l'établi, quelqu'un s'est endormi sur son tabouret, le papier de verre à la main. Dans un coin, un enfant dort, sa planche de skate sous l'oreiller.",
			"Chut… Tout le monde dort, même les roues. Enfin, presque : sur son axe d'essai, une roue tourne encore, tout doucement."]))
	elif nuit:
		M.ctx["entree"] = str(_pick(M, ["Il fait nuit. À la lueur d'une bougie, quelqu'un ponce une planche, tout doucement. Dans un coin, un enfant dort, une planche de skate sous l'oreiller.",
			"Frrt… frrt… Le bruit doux du papier de verre. Un enfant dort sur son matelas, la main posée sur la planche glissée sous son oreiller."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Ça sent la peinture fraîche et le bois scié. Un établi, des roues partout, et un enfant qui fait rouler une planche d'un bout à l'autre en riant.",
			"Attention aux pieds ! Une planche de skate file sur le tapis, rebondit contre un vieux pneu et revient. Ici, on fabrique des skates avec ce qu'on trouve.",
			"Au mur, une rangée de planches peintes de toutes les couleurs. À l'établi, quelqu'un visse une roue en sifflotant. Bienvenue à l'atelier de skates."]))


# =================================================================== la maison peinte (en cours d'écriture, à part)

# =================================================================== la maison peinte

## Les fresques de la maison peinte (des textures sous assets/textures/), mélangées une fois par maison.
const MURS_FRESQUES := [
	"boucan/graffiti_1.png", "boucan/graffiti_2.png", "boucan/graffiti_3.png", "boucan/graffiti_4.png",
	"boucan/graffiti_5.png", "boucan/graffiti_6.png", "boucan/graffiti_7.png", "boucan/graffiti_8.png",
	"boucan/graffiti_9.png", "boucan/graffiti_10.png", "boucan/graffiti_11.png", "boucan/graffiti_12.png",
	"strates/fresque_1.png", "strates/fresque_2.png", "strates/fresque_3.png",
]

## Les couleurs du coin blanc : une autre à chaque coup de pinceau (quand on n'en a pas choisi).
const MURS_COULEURS := [
	["rouge", Color(0.9, 0.18, 0.2)], ["bleu", Color(0.2, 0.45, 0.9)], ["jaune", Color(1.0, 0.82, 0.2)],
	["vert", Color(0.25, 0.7, 0.35)], ["violet", Color(0.6, 0.35, 0.85)], ["orange", Color(1.0, 0.55, 0.15)],
	["rose", Color(0.96, 0.5, 0.7)],
]

## Ce que dit l'enfant quand on trempe le pinceau dans une couleur.
const MURS_TREMPE := {
	"rouge": "Du rouge ! Comme la rouille des rails de Rivet !",
	"bleu": "Du bleu ! Le bleu des cristaux de la mine. Celui-là, il brille la nuit.",
	"jaune": "Du jaune ! Ça va faire du soleil dans mon coin.",
	"toutes": "Toutes ! Trempe dans tous les pots en même temps ! … Oui, après, ça fait du marron. Mais d'abord, c'est joli.",
}

## Ce que représentent les fresques (trois par maison, tirées au sort).
const MURS_HISTOIRES := [
	"Celle-ci, c'est toute la famille, le jour où Bricole a repeint le conteneur. Le chat est violet : il était dessous.",
	"Un concert des Soupapes. Rivet a six bras : c'est pour montrer qu'il joue vite. Écho chante un nuage de notes en forme de chaussettes.",
	"Mémé Gamelle et sa grande marmite. Dans la soupe, on reconnaît un boulon, deux étoiles et un poisson qui a l'air très content d'être là.",
	"Le Pont des Frondeurs, peint par l'enfant. Il est tout tordu. « C'est le vent du Gouffre », dit l'enfant. Le pont, lui, n'a rien dit.",
	"Un portrait de Fusain, peint par Fusain, pendant que la famille peignait Fusain en train de se peindre. On s'y perd un peu. C'est voulu.",
	"Un ciel. Personne ici ne l'a jamais vu, alors il est vert à pois roses. « Pourquoi pas ? », dit toute la famille.",
	"Ressort sur son skate, en plein saut. Ressort a posé pour de vrai : on voit encore, sur le mur, la trace de ses roues.",
	"Le Soleil de Laiton qui fait la sieste… avec une moustache. La moustache n'était pas prévue : une goutte a coulé. On l'a gardée.",
	"Le chat de la maison, en très grand, en roi de la Fronde. Il a posé trois secondes, puis il est allé marcher dans le jaune.",
]


## Les matières de la maison peinte (les couleurs des pots, la bâche, l'eau du bocal, le mur blanc).
static func _murs_mats(M) -> void:
	var R = M.R
	if R.kit.mats.has("mu_rouge"):
		return
	R._put("mu_rouge", R._col(Color(0.9, 0.18, 0.2), 0.3))
	R._put("mu_bleu", R._col(Color(0.2, 0.45, 0.9), 0.3))
	R._put("mu_jaune", R._col(Color(1.0, 0.82, 0.2), 0.3))
	R._put("mu_vert", R._col(Color(0.25, 0.7, 0.35), 0.3))
	R._put("mu_violet", R._col(Color(0.6, 0.35, 0.85), 0.3))
	R._put("mu_orange", R._col(Color(1.0, 0.55, 0.15), 0.3))
	R._put("mu_blanc", R._col(Color(0.97, 0.96, 0.93), 0.6))
	R._put("mu_bache", R._col(Color(0.62, 0.7, 0.76), 0.75))
	R._put("mu_eau", R._col(Color(0.45, 0.42, 0.55), 0.1))


## La couleur d'un nom de MURS_COULEURS (rouge si on ne la trouve pas).
static func _murs_couleur(nom: String) -> Color:
	for e in MURS_COULEURS:
		if str(e[0]) == nom:
			return e[1]
	return MURS_COULEURS[0][1]


## Une fresque plate contre un mur (repère de la pièce ; yaw : 0 au fond, 90 à gauche, -90 à droite,
## 180 devant) : un panneau peint (tex : un chemin sous assets/textures/) qui luit un peu la nuit.
static func _murs_fresque(M, x: float, y: float, z: float, yaw: float, w: float, h: float, tex: String) -> MeshInstance3D:
	var R = M.R
	R.mark_wall(x, y, z, w * 0.5 + 0.05)
	var q := QuadMesh.new()
	q.size = Vector2(w, h)
	var m := StandardMaterial3D.new()
	var t: Texture2D = R._tex(tex)
	if t != null:
		m.albedo_texture = t
	else:
		m.albedo_color = Color(0.85, 0.5, 0.35)
	m.roughness = 0.75
	if _nuit(M):
		m.emission_enabled = true
		m.emission = Color(1, 1, 1)
		if t != null:
			m.emission_texture = t
		m.emission_energy_multiplier = 0.35
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	M.room.add_child(mi)
	mi.global_transform = R.L(x, y, z, yaw) * Transform3D(Basis(), Vector3(0, 0, 0.012))
	return mi


## Une caisse de palette (le dessous en (x, y, z), repère de la pièce), avec ses lattes.
static func _murs_caisse(M, x: float, y: float, z: float, yaw: float, sx: float, sy: float, sz: float) -> void:
	var R = M.R
	var xf: Transform3D = R.L(x, y + sy * 0.5, z, yaw)
	R.kit.box(xf, Vector3(sx, sy, sz), "bois", 1.0)
	for k in [-1.0, 1.0]:
		for f in [-1.0, 1.0]:
			R.kit.box(xf * Transform3D(Basis(), Vector3(0, k * sy * 0.3, f * (sz * 0.5 + 0.006))), Vector3(sx * 0.96, 0.05, 0.012), "bois_sombre", 1.0)
	R.kit.col_box(xf, Vector3(sx, sy, sz))


## Un pot de peinture ouvert : du fer, un disque de couleur dessus, une coulure sur le côté.
static func _murs_pot(M, x: float, z: float, coul: String) -> void:
	var R = M.R
	R.kit.cyl(R.L(x, 0.0, z), 0.085, 0.08, 0.15, "fer", 12)
	R.kit.cyl(R.L(x, 0.15, z), 0.079, 0.079, 0.006, coul, 12)
	R.kit.box(R.L(x + 0.084, 0.11, z), Vector3(0.006, 0.08, 0.03), coul, 1.0)


## Un pinceau posé à plat (manche de bois clair, virole de fer, poils de couleur).
static func _murs_pinceau(M, x: float, y: float, z: float, yaw: float, coul: String) -> void:
	var R = M.R
	var xf: Transform3D = R.L(x, y + 0.012, z, yaw) * Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3.ZERO)
	R.kit.cyl(xf, 0.01, 0.008, 0.22, "bois_clair", 6)
	R.kit.cyl(xf * Transform3D(Basis(), Vector3(0, -0.05, 0)), 0.013, 0.013, 0.05, "fer", 6)
	R.kit.box(xf * Transform3D(Basis(), Vector3(0, -0.07, 0)), Vector3(0.03, 0.04, 0.012), coul, 1.0)


## Une forme de peinture fraîche sur le coin blanc (repère du panneau : x le long du mur, y vers le
## haut, z vers la pièce) : une tache et ses éclaboussures, des bandes, une étoile ou un zigzag.
static func _murs_forme(pan: Node3D, cols: Array, k: int, r: RandomNumberGenerator) -> Node3D:
	var fo := Node3D.new()
	pan.add_child(fo)
	fo.position = Vector3(r.randf_range(-0.3, 0.3), r.randf_range(-0.36, 0.36), 0.014 + 0.0005 * k)
	fo.rotation.z = r.randf() * TAU
	var nc: int = cols.size()
	var ms: Array = []
	for c in cols:
		ms.append(_mat(c, 0.0, 0.25))
	var disque: CylinderMesh = I._cyl(1.0, 1.0, 0.003, 18)
	var face := Vector3(PI * 0.5, 0, 0)
	match k % 4:
		0:
			var rr: float = r.randf_range(0.06, 0.1)
			_p(fo, disque, ms[0], Vector3.ZERO, Vector3(rr, 1.0, rr), face)
			for e in range(4):
				var a: float = r.randf() * TAU
				var d: float = rr + r.randf_range(0.02, 0.06)
				var pr: float = r.randf_range(0.01, 0.02)
				_p(fo, disque, ms[e % nc], Vector3(cos(a) * d, sin(a) * d, 0.0005), Vector3(pr, 1.0, pr), face)
		1:
			for i in range(maxi(nc, 2)):
				_p(fo, I._boxm(Vector3(0.3, 0.035, 0.003)), ms[i % nc], Vector3(0, (i - (maxi(nc, 2) - 1) * 0.5) * 0.04, 0.0003 * i))
		2:
			var lb: float = r.randf_range(0.14, 0.22)
			for i in range(3):
				_p(fo, I._boxm(Vector3(lb, 0.03, 0.003)), ms[i % nc], Vector3(0, 0, 0.0003 * i), Vector3.ONE, Vector3(0, 0, PI * i / 3.0))
		_:
			for i in range(4):
				_p(fo, I._boxm(Vector3(0.11, 0.028, 0.003)), ms[i % nc], Vector3(-0.12 + i * 0.08, 0.0, 0.0003 * i), Vector3.ONE, Vector3(0, 0, 0.7 if i % 2 == 0 else -0.7))
	return fo


## La maison peinte (la Fronde, style « fronde » : un conteneur-couloir ou une chaudière). Une famille
## d'amis de Fusain : tous les murs sont couverts de fresques, une bâche au sol, des pots ouverts, des
## pinceaux, un échafaudage de caisses. L'enfant peint le dernier coin encore blanc ; le parent, debout
## sur les caisses, peint le plafond ; le chat a les pattes de toutes les couleurs (ses traces au sol).
## Ce qui bouge : le pinceau de l'enfant va et vient, une coulure de peinture fraîche descend le long
## d'une fresque. On donne des coups de pinceau (une forme de couleur à chaque fois ; au troisième,
## l'enfant déclare l'œuvre finie : le fanzine des fresques, une seule fois), on choisit sa couleur,
## on regarde les fresques (trois histoires par maison), on caresse le chat. La nuit : les pinceaux
## trempent dans un bocal, tout le monde dort là où il peignait, les fresques luisent un peu.
static func _murs(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var nuit: bool = _nuit(M)
	_murs_mats(M)
	var s: float = 1.0 if r.randf() < 0.5 else -1.0
	var boy: bool = r.randf() < 0.5
	var ci: int = r.randi() % 3
	# le coin blanc : au fond si la pièce est large (un conteneur en long, une chaudière), sinon sur le
	# mur de côté ; o : le pied du coin blanc, tg : le long du mur (vers le milieu), nm : vers la pièce
	var dos: bool = R.W >= 3.5
	var o: Vector2
	var tg: Vector2
	var nm: Vector2
	var wyaw: float
	if dos:
		o = Vector2(s * (hw - 0.8), -hd + 0.015)
		tg = Vector2(-s, 0)
		nm = Vector2(0, 1)
		wyaw = 0.0
	else:
		o = Vector2(s * (hw - 0.015), minf(-hd + 1.0, hd - 1.8))
		tg = Vector2(0, 1)
		nm = Vector2(-s, 0)
		wyaw = -90.0 * s
	R.mark_wall(o.x, 1.05, o.y, 0.6)
	var k: Vector2 = _dedans(M, o.x + nm.x * 0.55, o.y + nm.y * 0.55)
	R.reserve(k.x, k.y, 0.6, 0.6)
	# l'échafaudage de caisses, dans le coin du fond de l'autre côté
	var sc: Vector2 = Vector2(-s * (hw - 0.6), -hd + 0.5)
	for lx in [-0.225, 0.225]:
		_murs_caisse(M, sc.x + lx, 0.0, sc.y, 0.0, 0.44, 0.31, 0.55)
		_murs_caisse(M, sc.x + lx, 0.31, sc.y, 0.0, 0.44, 0.31, 0.55)
	R.kit.box(R.L(sc.x, 0.635, sc.y), Vector3(0.94, 0.03, 0.6), "bois_clair", 1.0)
	R.kit.col_box(R.L(sc.x, 0.635, sc.y), Vector3(0.94, 0.03, 0.6))
	R.kit.box(R.L(sc.x + s * 0.3, 0.652, sc.y + 0.12), Vector3(0.12, 0.004, 0.18), "mu_jaune", 1.0)
	R.reserve(sc.x, sc.y, 1.0, 0.7)
	# la bâche au sol, tachée de partout
	var bz: float = -hd + (R.D - 1.0) * 0.5 + 0.05
	R.kit.box(R.L(0, 0.004, bz), Vector3(R.W - 0.7, 0.006, R.D - 1.0), "mu_bache", 2.0)
	var pots: Array = ["mu_rouge", "mu_bleu", "mu_jaune", "mu_vert", "mu_violet", "mu_orange"]
	for e in range(16):
		var tx: float = r.randf_range(-hw + 0.5, hw - 0.5)
		var tz: float = r.randf_range(-hd + 0.6, hd - 0.6)
		var tr: float = r.randf_range(0.02, 0.09)
		R.kit.cyl(R.L(tx, 0.008, tz), tr, tr, 0.002, str(pots[e % pots.size()]), 12)
	# les pots ouverts, le long du mur à côté de l'enfant
	for i in range(4):
		var pp: Vector2 = o + nm * 0.28 + tg * (0.62 + 0.21 * i)
		_murs_pot(M, pp.x, pp.y, str(pots[i]))
	var pc: Vector2 = o + nm * 0.28 + tg * 0.94
	R.reserve(pc.x, pc.y, 1.0 if dos else 0.4, 0.4 if dos else 1.0)
	var pots_at: Vector3 = R.P(pc.x, 0.0, pc.y)
	# les pinceaux : par terre le jour ; la nuit, ils trempent dans un bocal
	var bc: Vector2 = o + nm * 0.32 + tg * 1.45
	if nuit:
		R.kit.cyl(R.L(bc.x, 0.0, bc.y), 0.075, 0.07, 0.2, "verre", 14, false)
		R.kit.cyl(R.L(bc.x, 0.0, bc.y), 0.068, 0.068, 0.13, "mu_eau", 14)
		for i in range(4):
			var a: float = TAU * i / 4.0 + r.randf()
			var xf: Transform3D = R.L(bc.x + cos(a) * 0.03, 0.02, bc.y + sin(a) * 0.03, rad_to_deg(a)) * Transform3D(Basis(Vector3.RIGHT, 0.18), Vector3.ZERO)
			R.kit.cyl(xf, 0.01, 0.008, 0.3, "bois_clair", 6)
			R.kit.box(xf * Transform3D(Basis(), Vector3(0, 0.03, 0)), Vector3(0.03, 0.05, 0.012), str(pots[i]), 1.0)
	else:
		for i in range(3):
			var bp: Vector2 = o + nm * (0.55 + 0.08 * i) + tg * (0.9 + 0.25 * i)
			_murs_pinceau(M, bp.x, 0.004, bp.y, r.randf() * 360.0, str(pots[(i + 2) % pots.size()]))
		_murs_pinceau(M, sc.x - s * 0.25, 0.65, sc.y + 0.1, r.randf() * 360.0, "mu_bleu")
	# les fresques, sur tous les murs (pas sur les fenêtres, ni sur le coin blanc, ni sur la porte)
	var ordre: Array = range(MURS_FRESQUES.size())
	for i in range(ordre.size() - 1, 0, -1):
		var j: int = r.randi() % (i + 1)
		var tmp = ordre[i]
		ordre[i] = ordre[j]
		ordre[j] = tmp
	var fh: float = minf(1.5, R.H - 0.9)
	var fy: float = 0.45 + fh * 0.5
	var spots: Array = []
	var nx: int = maxi(1, int((R.W - 0.3) / 1.12))
	var nz: int = maxi(1, int((R.D - 0.3) / 1.12))
	var wx: float = minf(0.98, R.W / nx - 0.14)
	var wz: float = minf(0.98, R.D / nz - 0.14)
	for i in range(nx):
		spots.append([-hw + R.W * (i + 0.5) / nx, -hd + 0.02, 0.0, wx])
	for i in range(nz):
		var zz: float = -hd + R.D * (i + 0.5) / nz
		spots.append([-hw + 0.02, zz, 90.0, wz])
		spots.append([hw - 0.02, zz, -90.0, wz])
	for i in range(nx):
		var xx: float = -hw + R.W * (i + 0.5) / nx
		if absf(xx - float(R.door_x)) > wx * 0.5 + 0.75:
			spots.append([xx, hd - 0.02, 180.0, wx])
	var poses: Array = []
	var nf: int = 0
	for sp in spots:
		var w: float = float(sp[3])
		if not R.wall_free(float(sp[0]), fy, float(sp[1]), w * 0.5):
			continue
		_murs_fresque(M, float(sp[0]), fy, float(sp[1]), float(sp[2]), w, fh, str(MURS_FRESQUES[int(ordre[nf % ordre.size()])]))
		poses.append(sp)
		nf += 1
	# la fresque du plafond, au-dessus de l'échafaudage : à moitié peinte
	var pl: MeshInstance3D = _murs_fresque(M, -s * (hw - 0.8), R.H - 0.015, sc.y + 0.2, 0.0, minf(1.2, R.W * 0.4), minf(0.9, R.D - 0.9), str(MURS_FRESQUES[int(ordre[nf % ordre.size()])]))
	pl.global_transform = R.L(-s * (hw - 0.8), R.H - 0.015, sc.y + 0.2, 0.0) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO)
	# le coin blanc, ses formes, le pinceau de l'enfant
	var pan: Node3D = Node3D.new()
	M.room.add_child(pan)
	pan.global_transform = R.L(o.x, 1.05, o.y, wyaw)
	_p(pan, I._boxm(Vector3(0.9, 1.1, 0.01)), _mat(Color(0.97, 0.96, 0.93), 0.0, 0.7), Vector3(0, 0, 0.006))
	var pin := Node3D.new()
	pan.add_child(pin)
	var tip_m := _mat(Color(0.2, 0.45, 0.9), 0.0, 0.25)
	_p(pin, I._boxm(Vector3(0.035, 0.03, 0.04)), tip_m, Vector3(0, 0, 0.02))
	_p(pin, I._cyl(0.013, 0.013, 0.04, 8), _mat(Color(0.5, 0.5, 0.52), 0.8, 0.35), Vector3(0, 0, 0.06), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_p(pin, I._cyl(0.01, 0.008, 0.24, 8), _mat(Color(0.82, 0.68, 0.48), 0.0, 0.6), Vector3(0, 0, 0.2), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	pin.position = Vector3(0.12, -0.08, 0.02)
	pin.visible = not nuit
	_sans_ombre(pan)
	# la coulure de peinture fraîche, sur une fresque du fond (ou la première)
	var dsp: Array = poses[0] if poses.size() > 0 else [0.0, -hd + 0.02, 0.0, 0.9]
	for sp2 in poses:
		if float(sp2[2]) == 0.0:
			dsp = sp2
			break
	var dr := Node3D.new()
	M.room.add_child(dr)
	dr.global_transform = R.L(float(dsp[0]), fy + fh * 0.5 - 0.08, float(dsp[1]), float(dsp[2]))
	var cou := Node3D.new()
	dr.add_child(cou)
	cou.position = Vector3(r.randf_range(-0.3, 0.3) * float(dsp[3]), 0, 0.02)
	var cou_m := _mat(Color(0.9, 0.18, 0.2), 0.0, 0.1)
	var filet: MeshInstance3D = _p(cou, I._boxm(Vector3(0.022, 1.0, 0.006)), cou_m, Vector3.ZERO, Vector3(1, 0.001, 1))
	var perle: MeshInstance3D = _p(cou, I._sph(0.016), cou_m, Vector3.ZERO, Vector3(1.0, 1.3, 0.6))
	_sans_ombre(dr)
	# le chat de la maison, ses pattes de toutes les couleurs, ses traces sur la bâche
	var cyaw: float = 90.0 * s if R.W >= R.D else 180.0
	var cp: Vector2 = _dedans(M, s * 0.1 * hw, -hd + R.D * 0.35)
	var chat: Node3D = R.chat(cp.x, cp.y, cyaw, Color(0.95, 0.94, 0.9), nuit)
	var pattes: Array = [Color(0.9, 0.18, 0.2), Color(0.2, 0.45, 0.9), Color(1.0, 0.82, 0.2), Color(0.25, 0.7, 0.35)]
	if not nuit:
		var ip: int = 0
		for px in [-0.06, 0.06]:
			for pz in [-0.1, 0.1]:
				I._part(chat, I._sph(0.03), pattes[ip], Vector3(px, 0.02, pz), Vector3(1.0, 0.6, 1.2))
				ip += 1
	var fw := Vector2(sin(deg_to_rad(cyaw)), cos(deg_to_rad(cyaw)))
	var lat := Vector2(fw.y, -fw.x)
	for i in range(10):
		var tp: Vector2 = cp - fw * (0.3 + 0.14 * i) + lat * (0.045 if i % 2 == 0 else -0.045)
		if absf(tp.x) > hw - 0.2 or absf(tp.y) > hd - 0.2:
			break
		R.kit.cyl(R.L(tp.x, 0.009, tp.y), 0.024, 0.024, 0.003, str(pots[i % 4]), 8)
	var chat_at: Vector3 = R.P(cp.x, 0.0, cp.y)
	# les gens : le jour, l'enfant peint son coin blanc et le parent, debout sur les caisses, le
	# plafond ; la nuit, chacun s'est endormi là où il peignait
	var parent: Node
	var kid: Node
	var prole: String = str(_pick(M, ["homme", "femme"]))
	if nuit:
		parent = M.person(prole, sc.x, sc.y + 0.2, _vers(sc.x, sc.y, 0.0, 0.0), "dormir_assis")
		parent.npc.global_position.y += 0.19
		parent.lines = ["Zzz… un peu plus à gauche… zzz…", "Mmh… le plafond… demain… zzz…", "Zzz… pas sur les canapés… zzz…"]
		parent.line_every = Vector2(10.0, 15.0)
		var st0: Vector2 = Vector2(k.x, k.y) - nm * 0.12
		_murs_caisse(M, st0.x, 0.0, st0.y, wyaw, 0.4, 0.4, 0.36)
		kid = M.person("garcon" if boy else "fille", k.x + nm.x * 0.1, k.y + nm.y * 0.1, _vers(k.x, k.y, k.x + nm.x, k.y + nm.y), "dormir_assis")
		kid.lines = ["Zzz… encore un petit coup de bleu… zzz…", ["Zzz… Gribouille… pas dans le jaune… zzz…", "Zzz… Pastel… pas dans le jaune… zzz…", "Zzz… Barbouille… pas dans le jaune… zzz…"][ci], "Mmh… c'est fini… zzz…"]
		kid.line_every = Vector2(9.0, 14.0)
	else:
		parent = M.person(prole, sc.x, sc.y, _vers(sc.x, sc.y, sc.x - s * 1.0, sc.y - 1.0), "peindre")
		parent.npc.global_position.y += 0.65
		parent.lines = ["Un peu plus à gauche… voilà.", "J'ai de la peinture dans les cheveux. Encore.", "Le plafond, c'est le plus dur : la peinture veut toujours redescendre.", "Salut, camarade ! Attention, ça coule."]
		parent.line_every = Vector2(8.0, 13.0)
		kid = M.person("garcon" if boy else "fille", k.x, k.y, _vers(k.x, k.y, o.x, o.y), "peindre")
		kid.lines = ["Ne marche pas dans le bleu !", "Le mur blanc, c'est le mien. Enfin, il était blanc.", "Encore un petit coup, et c'est fini.",
			["Gribouille a encore marché dans le jaune !", "Pastel a encore marché dans le jaune !", "Barbouille a encore marché dans le jaune !"][ci]]
		kid.line_every = Vector2(6.0, 10.0)
	var histoires: Array = []
	var hs: Array = range(MURS_HISTOIRES.size())
	for i in range(3):
		var j: int = r.randi() % hs.size()
		histoires.append(MURS_HISTOIRES[int(hs[j])])
		hs.remove_at(j)
	var st := {"t": r.randf() * 10.0, "coups": 0, "couleur": "", "vu": 0, "coule": 0.0, "coule_max": r.randf_range(0.25, 0.55), "pause": 3.0}
	# la récompense : le fanzine des fresques, une seule fois
	var recompense := func() -> void:
		M.bonne_action_v120()  ## V120 : une bonne action, l'île s'en souvient
		if bool(M.state().get("fr_murs", false)):
			return
		M.state()["fr_murs"] = true
		var txt: String = "(tout bas) Vous aimez les fresques, hein ? Tenez, prenez ça sans réveiller personne : notre fanzine. Toutes les fresques de la Fronde, dessinées par la famille. Fusain a fait la couverture." if nuit else "Une œuvre finie ! Ça se fête. Tenez, camarade : notre fanzine. Toutes les fresques de la Fronde, dessinées par la famille, agrafées à la main. Fusain a fait la couverture."
		M.talk(parent, txt, I._bye("Merci, camarades !"), func(_i):
			M.give([["fanzine", 1]], "")
			M.close_talk(), "à voix basse" if nuit else "en pleine peinture")
	# donner un coup de pinceau sur le coin blanc
	var coup := func() -> void:
		var n: int = int(st["coups"])
		if n >= 24:
			M.say("Le coin blanc ne l'est plus du tout : il n'y a plus la place pour un seul coup de pinceau.", 4.0)
			return
		var choix: String = str(st["couleur"])
		var cols: Array = []
		if choix == "toutes":
			cols = [MURS_COULEURS[0][1], MURS_COULEURS[1][1], MURS_COULEURS[2][1]]
		elif choix != "":
			cols = [_murs_couleur(choix)]
		else:
			cols = [MURS_COULEURS[n % MURS_COULEURS.size()][1]]
		st["couleur"] = ""
		var fo: Node3D = _murs_forme(pan, cols, n, r)
		fo.scale = Vector3(0.05, 0.05, 1.0)
		var tw: Tween = M.room.create_tween()
		tw.tween_property(fo, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tip_m.albedo_color = cols[cols.size() - 1]
		n += 1
		st["coups"] = n
		M.main.sfx("touche_bois", fo.global_position)
		_bulle(M, fo.global_position + Vector3(0, 0.2, 0), str(_pick(M, ["Splotch !", "Flap !", "Pchhh !"])), cols[0], 40, 0.4, 1.3)
		M.say(str(_pick(M, ["Splotch ! Une forme toute neuve apparaît sur le mur blanc.", "Tu donnes un coup de pinceau. Le mur blanc l'est un peu moins.",
			"Flap ! Un coup de pinceau, et une forme de plus dans le coin."])), 3.5)
		if n == 1:
			kid.say(str(_pick(M, ["Oh ! Ça commence bien !", "Pas mal ! Le mur a l'air d'accord.", "Encore ! Il en veut encore !"])), 3.0)
		elif n == 2:
			kid.say(str(_pick(M, ["Encore un, et c'est fini !", "On y est presque !", "Un dernier, le plus beau !"])), 3.0)
		else:
			kid.gesture("joie", 2.0)
			if n == 3:
				M.main.sfx("confettis", fo.global_position)
				kid.say(str(_pick(M, ["Fini ! C'est un chef-d'œuvre !", "Terminé ! On l'appellera « Le coin qui n'est plus blanc » !"])), 3.5)
				recompense.call()
			else:
				kid.say(str(_pick(M, ["Bon, cette fois, c'est vraiment fini.", "Encore fini ! C'est un chef-d'œuvre de plus.", "Fini ! … Enfin, presque. Enfin, fini !"])), 3.0)
	var coup_at: Vector2 = o + nm * 0.95
	M.act(R.P(coup_at.x, 0.0, coup_at.y), "E : donner un coup de pinceau", coup, 1.2, func(): return not nuit)
	# tremper le pinceau : choisir la couleur de la prochaine forme
	var tremper := func() -> void:
		M.main.sfx("verser", pots_at)
		M.talk(kid, "Tu veux quelle couleur ? Trempe bien, mais pas jusqu'au manche !", [{"id": "rouge", "label": "Rouge"}, {"id": "bleu", "label": "Bleu"}, {"id": "jaune", "label": "Jaune"}, {"id": "toutes", "label": "Toutes !"}], func(id):
			M.close_talk()
			if MURS_TREMPE.has(str(id)):
				st["couleur"] = str(id)
				kid.say(str(MURS_TREMPE[str(id)]), 4.0)
				var cc: Color = _murs_couleur("rouge" if str(id) == "toutes" else str(id))
				tip_m.albedo_color = cc
		, "barbouillé" if boy else "barbouillée")
	M.act(pots_at, "E : tremper le pinceau", tremper, 1.0, func(): return not nuit)
	# regarder les fresques
	var regarder := func() -> void:
		var v: int = int(st["vu"])
		st["vu"] = v + 1
		if nuit and v == 0:
			M.say("Dans le noir, les fresques luisent tout doucement : un peu de poudre de cristal dans la peinture, et les murs veillent toute la nuit.", 6.0)
			return
		M.say(str(histoires[v % histoires.size()]), 8.0)
		if nuit:
			if v >= 3:
				recompense.call()
		elif v % 3 == 1:
			parent.say(str(_pick(M, ["Celle-là, c'est ma préférée.", "On l'a peinte en une nuit. Ça se voit ?", "Fusain a ajouté un petit truc dedans. Cherchez bien."])), 3.5)
	var vue: Vector2 = _dedans(M, -s * 0.3, -hd * 0.2)
	M.act(R.P(vue.x, 0.0, vue.y), "E : regarder les fresques", regarder, 1.5)
	# caresser le chat
	var caresser := func() -> void:
		M.main.sfx("ronron" if nuit else str(_pick(M, ["chat_miaou", "ronron"])), chat_at)
		_bulle(M, chat_at + Vector3(0, 0.55, 0), "♥", Color(1.0, 0.72, 0.82), 44, 0.4, 1.4)
		if nuit:
			M.say(["Gribouille ronronne en dormant, roulé en boule sur la bâche. Même dans le noir, on voit qu'il a des chaussettes de quatre couleurs.", "Pastel ronronne en dormant, roulé en boule sur la bâche. Même dans le noir, on voit qu'il a des chaussettes de quatre couleurs.", "Barbouille ronronne en dormant, roulé en boule sur la bâche. Même dans le noir, on voit qu'il a des chaussettes de quatre couleurs."][ci], 5.0)
		else:
			M.say(["Gribouille se laisse caresser. Une patte rouge, une bleue, une jaune, une verte : il a marché dans tous les pots. Ses traces font le tour de la bâche.", "Pastel se laisse caresser. Une patte rouge, une bleue, une jaune, une verte : il a marché dans tous les pots. Ses traces font le tour de la bâche.", "Barbouille se laisse caresser. Une patte rouge, une bleue, une jaune, une verte : il a marché dans tous les pots. Ses traces font le tour de la bâche."][ci], 5.0)
			kid.say(str(_pick(M, ["Lui, il signe toutes nos fresques.", "Fusain dit que c'est le meilleur peintre de la maison.", "Il ne faut pas le laver : c'est de l'art."])), 3.0)
	M.act(chat_at, "E : caresser le chat", caresser, 1.0)
	# ce qui bouge : le pinceau de l'enfant va et vient, la coulure descend lentement
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(pan) or not is_instance_valid(dr):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		if not nuit:
			pin.position = Vector3(0.12 + 0.14 * sin(t * 2.4), -0.08 + 0.07 * sin(t * 1.2), 0.02)
			pin.rotation.z = 0.35 * sin(t * 2.4)
		var lg: float = float(st["coule"])
		if lg < float(st["coule_max"]):
			lg = minf(float(st["coule_max"]), lg + dt * (0.004 if nuit else 0.012))
			st["coule"] = lg
		else:
			st["pause"] = float(st["pause"]) - dt
			if float(st["pause"]) <= 0.0:
				lg = 0.0
				st["coule"] = 0.0
				st["pause"] = 4.0
				st["coule_max"] = randf_range(0.25, 0.55)
				cou_m.albedo_color = MURS_COULEURS[randi() % MURS_COULEURS.size()][1]
				cou.position.x = randf_range(-0.3, 0.3) * float(dsp[3])
		filet.scale.y = maxf(lg, 0.001)
		filet.position.y = -lg * 0.5
		perle.position.y = -lg
		perle.visible = lg > 0.01
	# les conversations
	var parent_cb := func() -> void:
		if nuit:
			M.talk(parent, "Mmh ? … Oh, bonsoir, camarade. (tout bas) Chut, tout le monde dort. Je me suis endormi sur l'échafaudage, avec le pinceau à la main. Ça arrive souvent." if prole == "homme" else "Mmh ? … Oh, bonsoir, camarade. (tout bas) Chut, tout le monde dort. Je me suis endormie sur l'échafaudage, avec le pinceau à la main. Ça arrive souvent.",
				[{"id": "luire", "label": "Les fresques brillent ?"}, {"id": "fermer", "label": "Bonne nuit…"}], func(id):
				if id == "luire":
					M.talk(parent, "Jusqu'au matin. C'est la poudre de cristal que Fusain met dans le bleu. L'enfant dit que ce sont des veilleuses qui racontent des histoires.", I._bye("Chut… Bonne nuit !"), I._close(M), "à voix basse")
				else:
					M.close_talk()
			, "à voix basse")
			return
		var accueil: String = str(_pick(M, ["Salut, camarade ! Attention à la bâche, ça glisse. Ici, on ne repeint pas les murs : on les raconte.",
			"Bon bricolage ! Excusez-moi, je ne descends pas : si je lâche le plafond, il va couler sur ma tête."]))
		M.talk(parent, accueil, [{"id": "fusain", "label": "Fusain vient ici ?"}, {"id": "souvent", "label": "Vous repeignez souvent ?"}, {"id": "fermer", "label": "Bon bricolage !"}], func(id):
			match id:
				"fusain":
					M.talk(parent, "Tous les dimanches ! Il entre, il ne dit presque rien, il prend un pinceau, et il ajoute un petit truc quelque part. On met parfois une semaine à le trouver. La dernière fois, c'était une coccinelle sur la poignée de la porte.", I._bye("Je vais la chercher !"), I._close(M), "en pleine peinture")
				"souvent":
					M.talk(parent, "Repeindre ? On ne repeint jamais : on peint par-dessus ! Sous cette fresque, il y en a sept autres. Le mur fait déjà deux doigts d'épaisseur. La maison rétrécit, mais elle est de plus en plus belle.", I._bye("Ha ha !"), I._close(M), "en pleine peinture")
				_:
					M.close_talk()
		, "en pleine peinture")
	M.talk_spot(parent, parent_cb)
	var kid_cb := func() -> void:
		if nuit:
			M.talk(kid, "Zzz… encore un petit coup de bleu… et c'est fini… zzz…", I._bye("(Le laisser dormir)") if boy else I._bye("(La laisser dormir)"), I._close(M), "endormi" if boy else "endormie")
			return
		M.talk(kid, "C'est mon coin à moi ! Le dernier bout de mur encore blanc de toute la maison. Je dois le remplir avant le dîner.",
			[{"id": "quoi", "label": "Qu'est-ce que tu peins ?"}, {"id": "chat", "label": "Et le chat, il peint aussi ?"}, {"id": "fermer", "label": "Salut, camarade !"}], func(id):
			match id:
				"quoi":
					M.talk(kid, "Je ne sais pas encore. Fusain dit qu'il ne faut jamais savoir avant : c'est le mur qui décide. Donne un coup de pinceau, pour voir ce qu'il veut !", I._bye("D'accord !"), I._close(M), "barbouillé" if boy else "barbouillée")
				"chat":
					M.talk(kid, ["Gribouille ? Il peint avec les pattes ! Il marche dans les pots, et après, il signe partout. Fusain dit que c'est de l'art moderne.", "Pastel ? Il peint avec les pattes ! Il marche dans les pots, et après, il signe partout. Fusain dit que c'est de l'art moderne.", "Barbouille ? Il peint avec les pattes ! Il marche dans les pots, et après, il signe partout. Fusain dit que c'est de l'art moderne."][ci], I._bye("Ha ha !"), I._close(M), "barbouillé" if boy else "barbouillée")
				_:
					M.close_talk()
		, "barbouillé" if boy else "barbouillée")
	M.talk_spot(kid, kid_cb)
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Chut… La maison dort. Dans le noir, les fresques luisent tout doucement, comme si elles rêvaient elles aussi.",
			"Il fait nuit. Les pinceaux trempent dans leur bocal. Sur les murs, les couleurs brillent à peine : on dirait des veilleuses.",
			"Tout le monde s'est endormi là où il peignait : un enfant au pied de son coin de mur, quelqu'un tout en haut des caisses. Le chat ronronne sur la bâche."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Partout, des couleurs : les murs, le plafond, même la poignée de la porte. Ça sent la peinture fraîche. Attention où tu marches : le chat a des pattes de toutes les couleurs.",
			"Tu entres dans une fresque. Enfin, dans une maison couverte de fresques du sol au plafond. Là-haut, sur des caisses, quelqu'un peint le plafond, le nez en l'air.",
			"Une bâche au sol, des pots ouverts, des pinceaux partout. Dans un coin, un enfant attaque le dernier bout de mur encore blanc."]))


# =================================================================== la chaudière qui respire (en cours d'écriture, à part)

# =================================================================== la chaudière qui respire

## Les anecdotes de la fondation de la Fronde (le vieux les raconte en servant le thé, une par tasse).
const ANECDOTES_VAPEUR := [
	"Le premier soir de la Fronde, on était sept, avec une brouette de braises et cette chaudière. Brasero a levé le poing et il a dit : « Ici, on sera libres ! » Puis il s'est assis sur une braise. C'était moins solennel.",
	"Le Pont des Frondeurs, on l'a soudé en une seule nuit, avec des rails de rebut. Brasero tenait la lampe. Il a éclairé ses pieds toute la nuit : c'est pour ça que le pont est un peu tordu.",
	"À la première Assemblée, on a voté le nom du quartier : « La Bricole », « Le Bazar », « Chez Nous » ou « La Fronde ». La Fronde a gagné de deux voix. L'une des deux, c'était elle : elle a sifflé au bon moment.",
	"Au début, on n'avait qu'une marmite pour tout le monde : la soupe à midi, la lessive l'après-midi, le bain des petits le soir. La soupe avait un goût de savon. Personne ne s'est plaint. Enfin, pas fort.",
	"Brasero et moi, on a tiré cette chaudière depuis la décharge jusqu'ici, avec des cordes et des rondins. Trois jours ! Le troisième, elle a dévalé la pente toute seule et on a couru derrière. Ce jour-là, elle a roulé plus vite que nous.",
]


## Un tuyau (un cylindre de R.kit) de a à b (repère de la pièce), de rayon r. Appelée dans un _bloc,
## elle bâtit dans la boîte à outils du bloc (R.kit est relu à chaque appel).
static func _vapeur_tube(R, a: Vector3, b: Vector3, r: float, key: String = "cuivre", seg: int = 10) -> void:
	var d: Vector3 = b - a
	var l: float = d.length()
	if l < 0.001:
		return
	var y: Vector3 = d / l
	var ref: Vector3 = Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x: Vector3 = y.cross(ref).normalized()
	var z: Vector3 = x.cross(y).normalized()
	R.kit.cyl(Transform3D(Basis(x, y, z), R.P(a.x, a.y, a.z)), r, r, l, key, seg, false)


## Un coude (un manchon un peu plus gros) là où deux tuyaux se rejoignent (repère de la pièce).
static func _vapeur_coude(R, p: Vector3, r: float) -> void:
	R.kit.cyl(R.L(p.x, p.y - 0.06, p.z), r * 1.45, r * 1.45, 0.12, "cuivre", 10)


## La hauteur de la toile d'un hamac en u (0 : un bout, 1 : l'autre) : elle pend de `creux` au milieu.
static func _vapeur_creux(ytop: float, creux: float, u: float) -> float:
	return ytop - creux * 4.0 * u * (1.0 - u)


## Un hamac de toile rayée tendu le long de z, en x, entre deux tuyaux (za, zb), accroché à ytop :
## la toile en segments, ses bords relevés, deux barres d'écartement en bois, les cordes.
static func _vapeur_hamac(M, x: float, za: float, zb: float, ytop: float, creux: float, cols: Array, larg: float = 0.72) -> void:
	var R = M.R
	var n: int = 12
	var u0: float = 0.12
	var u1: float = 0.88
	for k in range(n):
		var ua: float = lerpf(u0, u1, float(k) / n)
		var ub: float = lerpf(u0, u1, float(k + 1) / n)
		var ya: float = _vapeur_creux(ytop, creux, ua)
		var yb: float = _vapeur_creux(ytop, creux, ub)
		var zza: float = lerpf(za, zb, ua)
		var zzb: float = lerpf(za, zb, ub)
		var dz: float = zzb - zza
		var dy: float = yb - ya
		var l: float = sqrt(dz * dz + dy * dy) + 0.012
		var xf: Transform3D = R.L(x, (ya + yb) * 0.5, (zza + zzb) * 0.5) * Transform3D(Basis(Vector3.RIGHT, -atan2(dy, dz)), Vector3.ZERO)
		var key: String = str(cols[k % cols.size()])
		R.kit.box(xf, Vector3(larg, 0.02, l), key, 1.0)
		for sx in [-1.0, 1.0]:
			R.kit.box(xf * Transform3D(Basis(Vector3.BACK, sx * 0.5), Vector3(sx * (larg * 0.5 + 0.015), 0.035, 0)), Vector3(0.025, 0.08, l), key, 1.0)
	for u in [u0, u1]:
		var yu: float = _vapeur_creux(ytop, creux, u) + 0.03
		var zu: float = lerpf(za, zb, u)
		R.kit.box(R.L(x, yu, zu), Vector3(larg + 0.08, 0.035, 0.035), "bois", 1.0)
		var zt: float = za if u < 0.5 else zb
		for sx2 in [-1.0, 0.0, 1.0]:
			_vapeur_tube(R, Vector3(x + sx2 * (larg * 0.5 + 0.02), yu, zu), Vector3(x, ytop, zt), 0.007, "tissu_creme", 4)


## Un manomètre (un disque de faïence cerclé de laiton, ses graduations, la zone rouge, sous un verre),
## tourné vers +Z (la pièce), centré sur `at` (monde) ; renvoie le pivot de l'aiguille (rotation.z).
static func _vapeur_mano(M, at: Vector3, rad: float, mats: Dictionary) -> Node3D:
	var g: Node3D = I._node(M, at, 0.0)
	var face := Vector3(PI * 0.5, 0, 0)
	_p(g, I._cyl(rad, rad, 0.05, 28), mats["laiton"], Vector3(0, 0, 0), Vector3.ONE, face)
	_p(g, I._cyl(rad * 0.88, rad * 0.88, 0.012, 28), mats["faience"], Vector3(0, 0, 0.026), Vector3.ONE, face)
	for k in range(9):
		var a: float = deg_to_rad(120.0 - 240.0 * k / 8.0)
		var rr: float = rad * 0.72
		_p(g, I._boxm(Vector3(0.006, rad * 0.16, 0.004)), mats["rouge"] if k >= 7 else mats["noir"],
			Vector3(-sin(a) * rr, cos(a) * rr, 0.034), Vector3.ONE, Vector3(0, 0, a))
	var piv := Node3D.new()
	g.add_child(piv)
	piv.position = Vector3(0, 0, 0.038)
	_p(piv, I._boxm(Vector3(rad * 0.08, rad * 0.75, 0.004)), mats["noir"], Vector3(0, rad * 0.3, 0))
	_p(g, I._sph(rad * 0.09), mats["laiton"], Vector3(0, 0, 0.04))
	_p(g, I._cyl(rad * 0.9, rad * 0.9, 0.004, 28), mats["vitre"], Vector3(0, 0, 0.05), Vector3.ONE, face)
	_sans_ombre(g)
	return piv


## Un jet de vapeur (de petites taches blanches qui s'élargissent et montent en s'effaçant), à `at`
## (monde), soufflé vers `dir` ; emitting = true : ça souffle.
static func _vapeur_jet(M, at: Vector3, dir: Vector3, s: float = 1.0) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 30
	p.lifetime = 1.5
	p.emitting = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.02 * s
	p.direction = dir.normalized()
	p.spread = 10.0
	p.initial_velocity_min = 0.6 * s
	p.initial_velocity_max = 1.0 * s
	p.gravity = Vector3(0, 0.4, 0)
	p.damping_min = 0.8
	p.damping_max = 1.4
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var cv := Curve.new()
	cv.add_point(Vector2(0, 0.3))
	cv.add_point(Vector2(1, 1.0))
	p.scale_amount_curve = cv
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	gr.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.0)])
	p.color_ramp = gr
	var q := QuadMesh.new()
	q.size = Vector2(0.16, 0.16) * s
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


## La maison est une vieille chaudière de locomotive (Hortense, qui tirait les wagons de la mine), et
## elle respire encore : les tuyaux de cuivre qui courent le long des murs frémissent, les aiguilles
## des manomètres montent et descendent, la bouche de vapeur souffle par moments. Le poêle, c'est la
## gueule de l'ancien foyer ; la théière siffle dessus. Un vieux Frondeur (un ami de Brasero) y vit
## depuis la fondation de la Fronde, avec son petit-enfant qui apprend à « parler chaudière » (il lit
## les manomètres). On tourne la vanne (les aiguilles montent, elle souffle, elle siffle), on tapote
## un manomètre, on sert le thé (une anecdote de la fondation ; la première fois, un pain cuit dans la
## chaudière). La nuit, elle respire plus lentement, le vieux ronfle avec elle, l'enfant dort dans
## son hamac. Tout tient le long des murs : un conteneur (6,1 × 2,44 m) comme une chaudière (4,6 × 6 m).
static func _vapeur(M) -> void:
	var R = M.R
	var r := _r(M)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var room0: Node = M.room
	var nuit: bool = _nuit(M)
	var s: float = 1.0 if r.randf() < 0.5 else -1.0
	var boy: bool = r.randf() < 0.5
	var zb0: float = -hd + 0.1
	# où tout se range, le long du mur du fond (de -s à +s) : le poêle, le fauteuil du vieux (sous le
	# hamac du haut), les manomètres, la vanne (et la bouche de vapeur au-dessus), le hamac de l'enfant
	var x_f: float = -s * (hw - 0.6)
	var x_v: float = -s * (hw - 1.6)
	var x_m: float = s * 0.5
	var x_w: float = s * (hw - 1.3)
	var x_h: float = s * (hw - 0.5)
	var mats := {"laiton": _mat(Color(0.88, 0.68, 0.3), 0.9, 0.3), "faience": _mat(Color(0.96, 0.94, 0.88), 0.0, 0.25),
		"noir": _mat(Color(0.04, 0.04, 0.05), 0.2, 0.5), "rouge": _mat(Color(0.85, 0.12, 0.1), 0.0, 0.5),
		"vitre": _verre(Color(0.85, 0.92, 1.0), 0.12)}
	var gy: Array = [1.45, 1.6, 1.45]
	var gr: Array = [0.1, 0.14, 0.1]
	var gx: Array = [x_m - s * 0.3, x_m, x_m + s * 0.3]
	# les hamacs : celui de l'enfant (le long de z, contre le mur +s), celui du vieux, tout en haut,
	# au-dessus de son fauteuil (il n'y dort jamais : c'est le hamac des chaussettes)
	var za1: float = -hd + 0.12
	var zb1: float = minf(za1 + 2.2, hd - 0.12)
	var zb2: float = minf(za1 + 2.0, hd - 0.12)
	# les tuyaux de cuivre : un bloc qui frémit (ils courent le long des murs, avec leurs coudes)
	var piv: Node3D = _bloc(M, R.P(0, 1.2, -hd + 0.3), func() -> void:
		for yy in [[2.15, 0.05], [1.95, 0.035]]:
			_vapeur_tube(R, Vector3(-hw + 0.1, float(yy[0]), zb0), Vector3(hw - 0.1, float(yy[0]), zb0), float(yy[1]))
		for sx in [-1.0, 1.0]:
			var cx: float = sx * (hw - 0.1)
			_vapeur_tube(R, Vector3(cx, 0, zb0), Vector3(cx, 2.15, zb0), 0.05)
			_vapeur_coude(R, Vector3(cx, 2.15, zb0), 0.05)
			_vapeur_coude(R, Vector3(cx, 1.95, zb0), 0.04)
			R.kit.cyl(R.L(cx, 0, zb0), 0.09, 0.09, 0.03, "cuivre", 12)
			var zf: float = hd - 0.35
			_vapeur_tube(R, Vector3(cx, 2.15, zb0), Vector3(cx, 2.15, zf), 0.05)
			_vapeur_tube(R, Vector3(cx, 0, zf), Vector3(cx, 2.15, zf), 0.05)
			_vapeur_coude(R, Vector3(cx, 2.15, zf), 0.05)
			R.kit.cyl(R.L(cx, 0, zf), 0.09, 0.09, 0.03, "cuivre", 12)
		# les tuyaux où pendent les hamacs (du sol au plafond)
		for e in [[x_h, za1], [x_h, zb1], [x_v, za1], [x_v, zb2]]:
			_vapeur_tube(R, Vector3(float(e[0]), 0, float(e[1])), Vector3(float(e[0]), R.H, float(e[1])), 0.04)
			R.kit.cyl(R.L(float(e[0]), 0, float(e[1])), 0.08, 0.08, 0.03, "cuivre", 12)
			for yc in [1.45, 2.2]:
				_vapeur_coude(R, Vector3(float(e[0]), yc, float(e[1])), 0.04)
		# la conduite de la vanne, et la bouche de vapeur au-dessus (un coude, un pavillon)
		_vapeur_tube(R, Vector3(x_w, 0, zb0 + 0.02), Vector3(x_w, 1.95, zb0 + 0.02), 0.035)
		R.kit.cyl(R.L(x_w, 0.98, zb0 + 0.02), 0.08, 0.08, 0.22, "or", 14)
		_vapeur_tube(R, Vector3(x_w, 1.12, zb0 + 0.02), Vector3(x_w, 1.12, -hd + 0.3), 0.018, "or", 8)
		_vapeur_tube(R, Vector3(x_w, 2.15, zb0), Vector3(x_w, 2.15, -hd + 0.34), 0.04)
		_vapeur_tube(R, Vector3(x_w, 2.03, -hd + 0.34), Vector3(x_w, 2.15, -hd + 0.34), 0.04)
		_vapeur_coude(R, Vector3(x_w, 2.15, -hd + 0.34), 0.04)
		R.kit.cyl(R.L(x_w, 1.95, -hd + 0.34), 0.075, 0.04, 0.08, "cuivre", 14)
		# les petits tuyaux des manomètres
		for i in range(3):
			_vapeur_tube(R, Vector3(float(gx[i]), float(gy[i]) + float(gr[i]), zb0 + 0.01), Vector3(float(gx[i]), 1.95, zb0 + 0.01), 0.014))
	_sans_ombre(piv)
	var piv0: Vector3 = piv.global_position
	R.mark_wall(x_m, 1.5, -hd, 0.65)
	R.mark_wall(x_w, 1.3, -hd, 0.35)
	R.mark_wall(s * hw, 1.2, (za1 + zb1) * 0.5, (zb1 - za1) * 0.5 + 0.2)
	# le poêle : la gueule de l'ancien foyer de la locomotive, sa porte ouverte, ses braises
	var zf0: float = -hd + 0.32
	R.kit.box(R.L(x_f, 0.4, zf0), Vector3(0.9, 0.8, 0.6), "fer", 1.0)
	R.kit.box(R.L(x_f, 0.815, zf0), Vector3(0.96, 0.03, 0.66), "metal", 1.0)
	R.kit.ring(R.L(x_f, 0.36, zf0 + 0.3) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.17, 0.22, 0.03, "or", 24)
	R.kit.box(R.L(x_f, 0.66, zf0 + 0.305), Vector3(0.3, 0.07, 0.01), "or", 1.0)
	for k in range(5):
		for sy in [0.08, 0.74]:
			R.kit.cyl(R.L(x_f - 0.36 + k * 0.18, sy, zf0 + 0.3) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.015, 0.015, 0.015, "or", 6)
	R.kit.box(R.L(x_f - s * 0.33, 0.36, zf0 + 0.48, 70.0 * s), Vector3(0.4, 0.42, 0.03), "fer", 1.0)
	R.kit.cyl(R.L(x_f + s * 0.28, 0.83, -hd + 0.14), 0.07, 0.07, R.H - 0.83, "fer", 10, false)
	R.kit.col_box(R.L(x_f, 0.4, zf0), Vector3(0.9, 0.8, 0.6))
	R.reserve(x_f, zf0, 1.05, 0.85)
	R.mark_wall(x_f, 1.0, -hd, 0.6)
	R.mark_wall(-s * hw, 1.0, zf0, 0.5)
	var feu: Node3D = I._node(M, R.P(x_f, 0.36, zf0 + 0.3), 0.0)
	var braise_m := _mat(Color(1.0, 0.42, 0.1), 0.0, 0.8, 1.6)
	_p(feu, I._cyl(0.17, 0.17, 0.01, 24), braise_m, Vector3(0, 0, 0.002), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	for k2 in range(5):
		_p(feu, I._boxm(Vector3(0.07, 0.04, 0.02)), braise_m, Vector3(r.randf_range(-0.1, 0.1), r.randf_range(-0.12, -0.04), 0.012), Vector3.ONE, Vector3(0, 0, r.randf() * 3.0))
	var lueur := OmniLight3D.new()
	lueur.light_color = Color(1.0, 0.5, 0.2)
	lueur.light_energy = 0.8
	lueur.omni_range = 2.8
	lueur.shadow_enabled = false
	M.room.add_child(lueur)
	lueur.global_position = R.P(x_f, 0.45, zf0 + 0.6)
	# le seau à charbon, devant le poêle, côté mur
	var bx: float = x_f - s * 0.25
	var bz: float = zf0 + 0.55
	R.kit.cyl(R.L(bx, 0, bz), 0.12, 0.14, 0.28, "fer", 12)
	R.kit.cyl(R.L(bx, 0.27, bz), 0.11, 0.11, 0.015, "noir", 12)
	# la théière sur le poêle (émaillée bleue, un peu écaillée) et une tasse
	var tp: Node3D = I._node(M, R.P(x_f - s * 0.18, 0.83, zf0 - 0.02), 0.0 if s > 0.0 else 180.0)
	var email := _mat(Color(0.2, 0.42, 0.72), 0.1, 0.35)
	_p(tp, I._sph(0.1), email, Vector3(0, 0.09, 0), Vector3(1.0, 0.85, 1.0))
	_p(tp, I._cyl(0.012, 0.022, 0.12, 8), email, Vector3(0.12, 0.12, 0), Vector3.ONE, Vector3(0, 0, -0.7))
	_p(tp, I._cyl(0.045, 0.05, 0.02, 14), email, Vector3(0, 0.175, 0))
	_p(tp, I._sph(0.018), mats["noir"], Vector3(0, 0.2, 0))
	var anse := TorusMesh.new()
	anse.inner_radius = 0.045
	anse.outer_radius = 0.06
	_p(tp, anse, mats["noir"], Vector3(-0.1, 0.11, 0), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_sans_ombre(tp)
	R.kit.cyl(R.L(x_f + s * 0.14, 0.83, zf0 - 0.02), 0.04, 0.035, 0.08, "ceramique", 12)
	R.kit.cyl(R.L(x_f + s * 0.14, 0.9, zf0 - 0.02), 0.033, 0.033, 0.005, "chocolat", 10)
	var bec: Vector3 = tp.to_global(Vector3(0.16, 0.17, 0))
	var the_jet: CPUParticles3D = _vapeur_jet(M, bec, Vector3(s * 0.4, 1.0, 0), 0.4)
	# la vanne à volant (rouge vif, trois rayons) et la bouche de vapeur au-dessus
	var vanne: Node3D = I._node(M, R.P(x_w, 1.12, -hd + 0.3), 0.0)
	var volant := Node3D.new()
	vanne.add_child(volant)
	var rouge_v := _mat(Color(0.82, 0.16, 0.1), 0.4, 0.45)
	var jante := TorusMesh.new()
	jante.inner_radius = 0.17
	jante.outer_radius = 0.205
	jante.rings = 24
	_p(volant, jante, rouge_v, Vector3.ZERO, Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	for k3 in range(3):
		_p(volant, I._boxm(Vector3(0.025, 0.36, 0.02)), rouge_v, Vector3.ZERO, Vector3.ONE, Vector3(0, 0, PI * k3 / 3.0))
	_p(volant, I._cyl(0.035, 0.035, 0.05, 12), mats["laiton"], Vector3(0, 0, 0.01), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_p(volant, I._sph(0.022), mats["laiton"], Vector3(0.188, 0, 0.03))
	_sans_ombre(vanne)
	var bouche: Vector3 = R.P(x_w, 1.94, -hd + 0.34)
	var jet: CPUParticles3D = _vapeur_jet(M, bouche, Vector3(0, -0.5, 1.0), 1.0)
	# les manomètres
	var aig: Array = []
	for i in range(3):
		aig.append(_vapeur_mano(M, R.P(float(gx[i]), float(gy[i]), -hd + 0.13), float(gr[i]), mats))
	# les hamacs (rayés) ; une couverture pliée et des chaussettes dans celui du haut
	_vapeur_hamac(M, x_h, za1, zb1, 1.45, 0.55, _pick(M, [["tissu_rouge", "tissu_jaune"], ["tissu_turquoise", "tissu_orange"], ["tissu_vert", "tissu_creme"]]))
	_vapeur_hamac(M, x_v, za1, zb2, 2.2, 0.25, ["tissu_violet", "tissu_jaune"], 0.6)
	var z2m: float = (za1 + zb2) * 0.5
	R.kit.box(R.L(x_v, 1.99, z2m - 0.2, 8.0), Vector3(0.4, 0.06, 0.3), "tissu_brun", 1.0)
	R.kit.box(R.L(x_v + 0.06, 1.99, z2m + 0.2, -20.0), Vector3(0.09, 0.03, 0.22), "tissu_rouge", 1.0)
	R.kit.box(R.L(x_v - 0.08, 1.99, z2m + 0.26, 15.0), Vector3(0.09, 0.03, 0.22), "tissu_turquoise", 1.0)
	R.reserve(x_h, (za1 + zb1) * 0.5, 0.9, zb1 - za1)
	# le fauteuil du vieux, à côté du poêle (un siège de wagon rembourré)
	var z_v: float = -hd + 0.55
	var yaw_v: float = _vers(x_v, z_v, x_v * 0.3, hd)
	R.fauteuil(x_v, z_v, yaw_v, str(_pick(M, ["rouge", "vert", "orange"])))
	# dans la chaudière (plus profonde que le conteneur) : un tapis, une caisse en guise de table
	if R.D >= 4.0:
		var tz: float = clampf(-hd + 2.0, -hd + 1.5, hd - 2.0)
		R.tapis(x_m * 0.4, tz, 0, minf(2.2, R.W - 2.0), 1.3)
		if R.is_free(x_m * 0.4, tz, 0.6, 0.6):
			R.caisse(x_m * 0.4, tz, 0.5)
			R.reserve(x_m * 0.4, tz, 0.6, 0.6)
			R.kit.cyl(R.L(x_m * 0.4 + 0.1, 0.5, tz), 0.04, 0.035, 0.08, "ceramique", 10)
	_cadres(M, 2)
	# les gens : le vieux Frondeur dans son fauteuil, l'enfant devant les manomètres ; la nuit, le vieux
	# ronfle dans son fauteuil et l'enfant dort dans son hamac
	var fwd: Vector3 = Basis(Vector3.UP, deg_to_rad(yaw_v)) * Vector3(0, 0, 0.05)
	var vieux: Node = M.person("vieux", x_v + fwd.x, z_v + fwd.z, yaw_v, "dormir_assis" if nuit else "assis")
	var kid: Node
	var kx: float = x_m - s * 0.35
	var kz: float = -hd + (0.62 if R.D < 4.0 else 0.95)
	if nuit:
		vieux.lines = []
		kid = M.person("garcon" if boy else "fille", x_h, (za1 + zb1) * 0.5, 0.0, "dormir")
		var uk: float = 0.68
		kid.lie(R.P(x_h, _vapeur_creux(1.45, 0.55, uk) - 0.05, lerpf(za1, zb1, uk)), Vector3(0, 0, -1))
		kid.lines = ["Zzz…", "Mmh… quarante-deux… elle dit quarante-deux… zzz…", "Zzz… tchou… tchou… zzz…"]
		kid.line_every = Vector2(12.0, 18.0)
	else:
		vieux.lines = ["Écoute-la respirer. Inspire… expire…", "Soixante ans de vapeur dans ces tuyaux. Et pas une fuite. Enfin, presque.",
			"Salut, camarade ! Ne touche pas au sifflet. Enfin… si, un peu.", "Brasero vient prendre le thé le jeudi. Il triche aux dominos."]
		vieux.line_every = Vector2(9.0, 14.0)
		kid = M.person("garcon" if boy else "fille", kx, kz, _vers(kx, kz, x_m, -hd), "observer")
		kid.lines = ["Trois bars et demi ! … Je crois.", "Papy, la petite aiguille fait des bêtises !", "Quand elle siffle deux fois, c'est l'heure du goûter.",
			"Chut ! Elle dit quelque chose."]
		kid.line_every = Vector2(7.0, 11.0)
	var tete_v: Vector3 = vieux.npc.global_position + Vector3(0, 1.4, 0)
	# l'état de la chaudière : sa respiration (phase), la pression en plus (la vanne), les jets
	var st := {"t": 0.0, "ph": r.randf() * TAU, "prev": 0.0, "boost": 0.0, "souffle": r.randf_range(3.0, 6.0), "jet": 0.0, "fort": false,
		"hes": 0.0, "occ_v": 0.0, "occ_t": 0.0, "the_jet": 0.0, "ane": r.randi() % ANECDOTES_VAPEUR.size()}
	var base: Array = [0.36, 0.5, 0.6]
	M.ctx["tick"] = func(dt: float) -> void:
		if not is_instance_valid(piv):
			return
		var t: float = float(st["t"]) + dt
		st["t"] = t
		var boost: float = float(st["boost"])
		var w: float = 0.5 if nuit else 1.1
		var ph: float = float(st["ph"]) + dt * w * (1.0 + boost * 0.8)
		st["ph"] = ph
		var b: float = sin(ph)
		var prev: float = float(st["prev"])
		st["prev"] = b
		# la nuit, le vieux ronfle avec elle : « Zzz… » quand elle inspire, « Pfff… » quand elle expire
		if nuit:
			if prev < 0.0 and b >= 0.0:
				_bulle(M, tete_v, "Zzz…", Color(0.85, 0.9, 1.0), 36, 0.45, 2.4)
			elif prev > 0.0 and b <= 0.0:
				_bulle(M, tete_v + Vector3(0.1, 0, 0), "Pfff…", Color(1.0, 0.95, 0.85), 34, 0.4, 2.2)
		st["boost"] = maxf(0.0, boost - dt * 0.16)
		for key in ["occ_v", "occ_t", "hes"]:
			st[key] = maxf(0.0, float(st[key]) - dt)
		# les tuyaux frémissent (plus fort quand elle inspire, beaucoup plus avec la vanne ouverte)
		var amp: float = 0.0012 + 0.0012 * maxf(b, 0.0) + 0.006 * boost
		piv.global_position = piv0 + Vector3(sin(t * 53.0) * amp, sin(t * 61.0 + 1.0) * amp * 0.6, sin(t * 47.0 + 2.0) * amp * 0.4)
		# les aiguilles (celle du milieu hésite quand on la tapote)
		var h: float = float(st["hes"]) / 2.0
		for i in range(3):
			var v: float = float(base[i]) + (0.06 + 0.02 * i) * b * (0.6 if nuit else 1.0) + boost * (0.35 + 0.05 * i)
			if i == 1 and h > 0.0:
				v += (0.15 * sin(t * 23.0) + 0.1 * sin(t * 9.0)) * h
			var target: float = deg_to_rad(120.0 - 240.0 * clampf(v, 0.0, 1.05))
			var n: Node3D = aig[i]
			n.rotation.z = lerpf(n.rotation.z, target, 1.0 - exp(-dt * 6.0))
		# le foyer respire aussi
		var resp: float = b * 0.5 + 0.5
		braise_m.emission_energy_multiplier = 1.1 + 0.9 * resp + boost
		lueur.light_energy = 0.5 + 0.4 * resp + 0.4 * boost
		# la bouche de vapeur souffle par moments
		st["souffle"] = float(st["souffle"]) - dt
		if float(st["souffle"]) <= 0.0:
			st["souffle"] = r.randf_range(15.0, 22.0) if nuit else r.randf_range(8.0, 13.0)
			if float(st["jet"]) <= 0.0:
				st["jet"] = 0.9 if nuit else 1.3
				st["fort"] = false
				M.main.sfx("vapeur", bouche, -22.0 if nuit else -12.0)
				if not nuit and r.randf() < 0.35:
					kid.say(str(_pick(M, ["Pfff ! Elle a expiré. Ça veut dire « bonjour ».", "Elle souffle ! Elle est de bonne humeur.", "Pschhh… Papy, elle a dit ton prénom !"])), 3.0)
		var fort: bool = bool(st["fort"])
		jet.initial_velocity_min = 1.6 if fort else 0.5
		jet.initial_velocity_max = 2.4 if fort else 0.9
		jet.scale_amount_max = 2.0 if fort else 1.2
		st["jet"] = float(st["jet"]) - dt
		jet.emitting = float(st["jet"]) > 0.0
		st["the_jet"] = float(st["the_jet"]) - dt
		the_jet.emitting = float(st["the_jet"]) > 0.0
	# tourner la vanne : les aiguilles montent, elle souffle fort, elle siffle (la nuit : tout doucement)
	var tourner := func() -> void:
		st["occ_v"] = 4.5
		var tw: Tween = M.room.create_tween()
		tw.tween_property(volant, "rotation:z", volant.rotation.z - TAU * 1.25, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		M.main.sfx("levier", vanne.global_position)
		if nuit:
			st["boost"] = 0.3
			st["jet"] = 1.2
			st["fort"] = false
			M.main.sfx("vapeur", bouche, -18.0)
			M.say(str(_pick(M, ["Tu tournes la vanne tout doucement… La chaudière soupire, sans siffler. Personne ne se réveille. Presque.",
				"Un quart de tour, pas plus. Les aiguilles s'étirent comme des chats, la vapeur fait « pfff ». Le vieux grogne dans son sommeil."])), 5.0)
			S._say_late(M, vieux, str(_pick(M, ["Mmh… doucement… elle dort… zzz…", "Zzz… pas la nuit, ma vieille… zzz…"])), 1.5, 3.0)
			return
		st["boost"] = 1.0
		st["jet"] = 3.0
		st["fort"] = true
		M.main.sfx("vapeur", bouche)
		kid.gesture("joie", 2.0)
		kid.say(str(_pick(M, ["Douze ! Treize ! Elle monte, elle monte !", "Toutes les aiguilles dans le rouge ! Enfin, presque.", "Ouaaah ! Elle respire à fond !"])), 3.0)
		await M.get_tree().create_timer(0.9).timeout
		if not _la(M, room0):
			return
		M.main.sfx("sifflet_compagnons", bouche)
		_bulle(M, bouche + Vector3(0, 0.2, 0.2), "Tuuuuuut !", Color(1.0, 0.95, 0.8), 44, 0.6, 1.8)
		vieux.gesture("sursaut", 1.2)
		vieux.say(str(_pick(M, ["Doucement ! Elle est vieille, comme moi.", "Doucement ! Elle est vieille, comme moi. Et moi, j'ai les oreilles fragiles !",
			"Doucement ! Elle est vieille, comme moi. On ne réveille pas une dame comme ça."])), 3.5)
	M.act(R.P(x_w, 0, -hd + 0.65), "E : tourner la vanne", tourner, 0.95, func(): return float(st["occ_v"]) <= 0.0)
	# tapoter le manomètre (celui du milieu) : l'aiguille hésite
	var tapoter := func() -> void:
		st["hes"] = 2.0
		var at: Vector3 = (aig[1] as Node3D).global_position
		M.main.sfx("touche_bois", at, -6.0 if nuit else 0.0)
		_bulle(M, at + Vector3(0, 0.2, 0.1), "Toc, toc.", Color(1, 1, 1), 32, 0.3, 1.2)
		if nuit:
			M.say(str(_pick(M, ["Toc. L'aiguille sursaute, réfléchit… puis se rendort, comme tout le monde ici.",
				"Tu tapotes le verre. L'aiguille bâille, s'étire, et revient se coucher sur son chiffre."])), 4.5)
			return
		M.say(str(_pick(M, ["Tu tapotes le verre. L'aiguille hésite, fait un petit tour d'honneur… et revient pile où elle était. Elle voulait juste qu'on la regarde.",
			"Toc, toc. L'aiguille sursaute, recule d'un cran, avance de deux. Elle n'a pas l'air sûre d'elle.",
			"Tu tapotes le manomètre. L'aiguille tremble comme quelqu'un qu'on réveille un dimanche."])), 5.0)
		S._say_late(M, kid, str(_pick(M, ["Elle dit « bof ». Quand elle hésite, ça veut dire « bof ».", "Hé ! Ça la chatouille !",
			"Papy dit qu'il faut lui dire bonjour avant de taper. Elle est susceptible."])), 1.4, 3.5)
	M.act(R.P(x_m + s * 0.15, 0, -hd + 0.6), "E : tapoter le manomètre", tapoter, 0.85, func(): return float(st["hes"]) <= 0.0)
	# servir le thé : la théière siffle, on verse, le vieux raconte (la première fois : le pain de chaudière)
	var fx := {}
	var recompense := func() -> void:
		M.bonne_action_v120()  ## V120 : une bonne action, l'île s'en souvient
		if bool(M.state().get("fr_vapeur", false)):
			M.close_talk()
			return
		M.state()["fr_vapeur"] = true
		M.talk(vieux, "Attends ! Tu ne pars pas le ventre vide. Du pain de chaudière, cuit dans son ventre, comme au premier soir de la Fronde. Ne le dis pas à Gamelle : elle croit que le meilleur, c'est le sien.",
			I._bye("Merci, camarade !"), func(_i):
			M.give([["pain_chaudiere", 1]], "")
			M.close_talk(), "en pleine vapeur")
	fx["raconter"] = func() -> void:
		var i: int = int(st["ane"]) % ANECDOTES_VAPEUR.size()
		st["ane"] = i + 1
		M.talk(vieux, str(ANECDOTES_VAPEUR[i]), [{"id": "encore", "label": "Encore une histoire !"}, {"id": "fermer", "label": "Merci pour le thé !"}], func(id):
			if id == "encore":
				vieux.gesture("rire", 1.5)
				(fx["raconter"] as Callable).call()
			else:
				recompense.call()
		, "en pleine vapeur")
	var servir := func() -> void:
		st["occ_t"] = 6.0
		if nuit:
			M.main.sfx("verser", bec, -8.0)
			M.say(str(_pick(M, ["Tu te sers une tasse, tout doucement. La théière, encore tiède, ne siffle pas : elle aussi fait attention.",
				"Tu verses un fond de thé tiède. Dans son fauteuil, le vieux sourit en dormant, comme s'il sentait l'odeur."])), 5.0)
			S._say_late(M, vieux, str(_pick(M, ["Zzz… Brasero… pas la brouette… zzz…", "Mmh… on était sept… zzz…", "Zzz… pousse… elle roule… zzz…"])), 2.0, 3.5)
			if not bool(M.state().get("fr_vapeur", false)):
				M.state()["fr_vapeur"] = true
				await M.get_tree().create_timer(5.5).timeout
				if not _la(M, room0):
					return
				M.give([["pain_chaudiere", 1]], "Sur le poêle, sous un torchon, un pain encore tiède et un mot : « Pour qui passe. » ")
			return
		st["the_jet"] = 1.6
		M.main.sfx("vapeur", bec, -10.0)
		_bulle(M, bec + Vector3(0, 0.15, 0), "Fuiiiii !", Color(0.85, 0.92, 1.0), 34, 0.4, 1.4)
		kid.say(str(_pick(M, ["La théière siffle ! Elle parle chaudière, elle aussi.", "Thé ! Thé ! Avec beaucoup de sucre, Papy !"])), 2.5)
		await M.get_tree().create_timer(1.5).timeout
		if not _la(M, room0):
			return
		var tw: Tween = M.room.create_tween()
		tw.tween_property(tp, "rotation:z", -0.55, 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_interval(0.9)
		tw.tween_property(tp, "rotation:z", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		M.main.sfx("verser", bec)
		await M.get_tree().create_timer(2.0).timeout
		if not _la(M, room0):
			return
		M.main.sfx("boire", vieux.npc.global_position, -4.0)
		(fx["raconter"] as Callable).call()
	M.act(R.P(x_f + s * 0.1, 0, minf(-hd + 0.95, hd - 1.6)), "E : servir le thé", servir, 0.9, func(): return float(st["occ_t"]) <= 0.0)
	# parler au vieux Frondeur
	var vieux_cb := func() -> void:
		if nuit:
			M.talk(vieux, "Zzz… Pfff… Zzz… (Il ronfle exactement en même temps que la chaudière. Ils ont l'air d'accord sur tout.)", I._bye("(Le laisser dormir)"), I._close(M), "endormi")
			return
		var accueil: String = str(_pick(M, ["Salut, camarade ! Entre, entre. Attention aux tuyaux : ils sont chauds, et ils sont susceptibles.",
			"Bon bricolage ! Tu entends ? Elle respire. Soixante ans qu'elle respire, ma vieille chaudière."]))
		M.talk(vieux, accueil, [{"id": "roule", "label": "Elle a roulé, cette chaudière ?"}, {"id": "debut", "label": "C'était comment, le début de la Fronde ?"},
			{"id": "boum", "label": "Elle va exploser ?"}, {"id": "fermer", "label": "Bonne vapeur !"}], func(id):
			match id:
				"roule":
					M.talk(vieux, "Si elle a roulé ! Quarante ans derrière Hortense, la locomotive de la mine. Quand Hortense a pris sa retraite, on a gardé son cœur. C'est ici : tu es dedans.",
						[{"id": "hortense", "label": "Qui était Hortense ?"}, {"id": "fermer", "label": "Quelle histoire !"}], func(id2):
						if id2 == "hortense":
							M.talk(vieux, "La plus vieille locomotive des Strates. Elle tirait les wagons de minerai et elle chantait dans les tunnels. Bernadette, la locomotive de Papy Ferdinand, c'est un peu sa petite-nièce.", I._bye("Bonne descente, Hortense !"), I._close(M), "ému")
						else:
							M.close_talk()
					, "tout fier")
				"debut":
					M.talk(vieux, "Au début, il n'y avait rien : la décharge des Strates, le Gouffre, et Brasero avec une brouette pleine de braises. Moi, j'avais une chaudière ; lui, il avait du feu. On s'est dit : « Ça tombe bien. »",
						[{"id": "brasero", "label": "Et Brasero, il était comment ?"}, {"id": "fermer", "label": "Merci !"}], func(id2):
						if id2 == "brasero":
							M.talk(vieux, "Pareil qu'aujourd'hui ! La même crête, le même feu, les mêmes discours trop longs. Il vient boire le thé ici le jeudi : il dit que c'est la seule maison où il n'a jamais froid.", I._bye("Ha ha !"), I._close(M), "en pleine vapeur")
						else:
							M.close_talk()
					, "en pleine vapeur")
				"boum":
					vieux.gesture("rire", 2.0)
					M.talk(vieux, "Jamais ! Elle est en pierre de patience. Elle souffle, elle siffle, elle ronchonne, comme moi, mais elle n'a jamais perdu son calme.", I._bye("Ouf !"), I._close(M), "en pleine vapeur")
				_:
					M.close_talk()
		, "en pleine vapeur")
	M.talk_spot(vieux, vieux_cb)
	# parler à l'enfant (il apprend à « parler chaudière »)
	var kid_cb := func() -> void:
		if nuit:
			M.talk(kid, "Zzz… elle inspire… elle expire… quarante-deux… zzz…", I._bye("(Le laisser dormir)") if boy else I._bye("(La laisser dormir)"), I._close(M), "endormi" if boy else "endormie")
			return
		M.talk(kid, "Chut, j'écoute la chaudière… Bonjour ! J'apprends à parler chaudière. Papy dit que je suis doué." if boy else "Chut, j'écoute la chaudière… Bonjour ! J'apprends à parler chaudière. Papy dit que je suis douée.",
			[{"id": "lire", "label": "Qu'est-ce qu'elle dit, là ?"}, {"id": "apprendre", "label": "Comment on apprend à parler chaudière ?"},
			{"id": "tard", "label": "Tu veux faire quoi, plus tard ?"}, {"id": "fermer", "label": "Bon bricolage !"}], func(id):
			match id:
				"lire":
					var txt: String
					if float(st["boost"]) > 0.3:
						txt = "Elle est TOUT en haut ! Elle dit : « Je suis réveillée, je suis réveillée ! » Papy dit qu'il ne faut pas l'énerver."
					elif sin(float(st["ph"])) >= 0.0:
						txt = "Là, elle inspire. La grosse aiguille dit « tranquille », la petite dit « goûter ». La petite dit toujours « goûter »."
					else:
						txt = "Là, elle expire. Ça veut dire qu'elle est d'accord avec nous. Elle est souvent d'accord : c'est une gentille chaudière."
					M.talk(kid, txt, I._bye("Bravo, l'interprète !"), I._close(M), "concentré" if boy else "concentrée")
				"apprendre":
					M.talk(kid, "Il faut écouter avec le ventre, pas avec les oreilles. Et regarder les aiguilles. Et ne jamais, jamais lui dire qu'elle est vieille. Ça, c'est Papy qui a le droit.", I._bye("C'est noté !"), I._close(M), "très sérieux" if boy else "très sérieuse")
				"tard":
					M.talk(kid, "Chauffeur de chaudière ! Ou batteur chez les Soupapes. Ou les deux : Rivet dit que c'est pareil, il faut taper au bon moment.", I._bye("Bonne idée !"), I._close(M), "aux anges")
				_:
					M.close_talk()
		, "aux anges")
	M.talk_spot(kid, kid_cb)
	if nuit:
		M.ctx["entree"] = str(_pick(M, ["Dans la pénombre orange du foyer, la chaudière respire lentement. Un vieux monsieur ronfle dans son fauteuil, exactement au même rythme qu'elle.",
			"Chut… Inspire, expire. La chaudière dort, le vieux dort, l'enfant dort dans son hamac. Seules les aiguilles des cadrans veillent.",
			"Il fait chaud et sombre. Les tuyaux soupirent tout bas, un hamac se balance à peine, et quelque part, quelqu'un ronfle en mesure."]))
	else:
		M.ctx["entree"] = str(_pick(M, ["Tu entres dans le ventre d'une vieille chaudière de locomotive. Les tuyaux de cuivre frémissent, les aiguilles des cadrans battent la mesure… La maison respire.",
			"Pschhh… Une bouffée de vapeur t'accueille. Des tuyaux de cuivre partout, des cadrans, une grosse vanne rouge, et un vieux Frondeur qui te fait signe d'entrer.",
			"Il fait bon, ici, et ça sent le thé et le métal chaud. Les aiguilles montent, descendent, remontent : la vieille chaudière respire encore."]))
