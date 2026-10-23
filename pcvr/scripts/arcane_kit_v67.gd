extends "res://scripts/azur_kit_v56.gd"
## V67 : les pièces d'Arcanelle, l'île des sorciers. Même principe que les autres kits
## (azur_kit_v56.gd) : la géométrie est regroupée par matériau ; les collisions vont dans un
## seul corps statique. En plus :
##  - tower : une tour ronde de moellons bleus, ses bandeaux, ses fenêtres en ogive (vitraux qui
##    s'allument le soir), son toit en cône d'ardoises en écailles et son épi de faîtage ;
##  - lancet : une fenêtre en ogive (vitrail) ; arch_door : une porte en ogive ;
##  - timber_house : une maison à pans de bois (rez-de-chaussée de pierre, étage en
##    encorbellement, toit pentu, lucarne, cheminée) ;
##  - hall : un bâtiment où l'on entre (murs, porte, plancher, plafond, toit, lumières) ;
##  - orb_lamp : un réverbère de fer tordu qui porte une boule de lumière bleutée ;
##  - brazier, menhir, crystal, bookshelf, cauldron, low_wall, pier, bell_frame, telescope.

const AR := "res://assets/textures/arcanelle/"
const TOITS := {"": Color(1, 1, 1), "rouge": Color(1.25, 0.62, 0.55), "vert": Color(0.8, 1.05, 0.82), "bleu": Color(0.85, 1.0, 1.25), "violet": Color(1.1, 0.88, 1.15)}

var orbs: Array = []                     # [OmniLight3D] des réverbères (pour les tests)


func mat(key: String) -> Material:
	if mats.has(key):
		return mats[key]
	var m: StandardMaterial3D = null
	var parts: PackedStringArray = key.split("_", true, 1)
	var kind: String = parts[0]
	var variant: String = parts[1] if parts.size() > 1 else ""
	match kind:
		"pierrearc":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(AR + "pierre_arc.png")
			m.normal_enabled = true
			m.normal_texture = load(AR + "pierre_arc_n.png")
			m.normal_scale = 1.2
			m.roughness = 0.92
			m.albedo_color = {"": Color(1, 1, 1), "sombre": Color(0.66, 0.68, 0.72), "clair": Color(1.12, 1.1, 1.06), "mousse": Color(0.82, 0.92, 0.78)}.get(variant, Color(1, 1, 1))
		"ecailles":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(AR + "ecailles.png")
			m.normal_enabled = true
			m.normal_texture = load(AR + "ecailles_n.png")
			m.normal_scale = 1.3
			m.roughness = 0.62
			m.albedo_color = TOITS.get(variant, Color(1, 1, 1))
		"colombage":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(AR + "colombage.png")
			m.normal_enabled = true
			m.normal_texture = load(AR + "colombage_n.png")
			m.roughness = 0.95
			m.albedo_color = {"": Color(1, 1, 1), "ocre": Color(1.0, 0.86, 0.66), "rose": Color(1.0, 0.84, 0.82), "bleu": Color(0.84, 0.9, 1.0)}.get(variant, Color(1, 1, 1))
		"poutre":
			m = StandardMaterial3D.new()
			m.albedo_texture = load("res://assets/textures/doors/wood_plain.png")
			m.albedo_color = Color(0.36, 0.25, 0.18) if variant == "" else Color(0.52, 0.38, 0.26)
			m.roughness = 0.85
		"dallesarc":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(AR + "dalles_arc.png")
			m.normal_enabled = true
			m.normal_texture = load(AR + "dalles_arc_n.png")
			m.roughness = 0.86
		"vitrail":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(AR + "vitrail.png")
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission = Color(1, 1, 1)
			m.roughness = 0.15
			m.metallic_specular = 0.8
			m.emission_energy_multiplier = 0.35
			if temps != null:
				temps.register_glow(m, 1.6, 0.35)
		"rosace":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(AR + "rosace.png")
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.4
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission = Color(1, 1, 1)
			m.emission_energy_multiplier = 0.4
			m.roughness = 0.2
			if temps != null:
				temps.register_glow(m, 1.8, 0.4)
		"runes":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(AR + "runes.png")
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_color = {"": Color(0.55, 0.7, 1.0, 0.85), "or": Color(1.0, 0.82, 0.42, 0.85), "violet": Color(0.8, 0.55, 1.0, 0.85), "pale": Color(0.6, 0.66, 0.78, 0.35)}.get(variant, Color(0.55, 0.7, 1.0, 0.85))
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.render_priority = 1
		"livres":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(AR + "livres.png")
			m.roughness = 0.85
		"carteciel":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(AR + "carte_ciel.png")
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission = Color(1, 1, 1)
			m.emission_energy_multiplier = 0.3
			m.roughness = 0.8
		"banniere":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(AR + "banniere.png")
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.4
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.roughness = 0.9
		"cristal":
			m = StandardMaterial3D.new()
			var cc: Color = {"": Color(0.62, 0.45, 1.0), "bleu": Color(0.4, 0.66, 1.0), "givre": Color(0.75, 0.92, 1.0), "rose": Color(1.0, 0.55, 0.85), "vert": Color(0.45, 1.0, 0.7)}.get(variant, Color(0.62, 0.45, 1.0))
			m.albedo_color = Color(cc.r * 0.6, cc.g * 0.6, cc.b * 0.6, 0.82)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.emission_enabled = true
			m.emission = cc
			m.emission_energy_multiplier = 0.9
			m.roughness = 0.08
			m.metallic_specular = 1.0
			if temps != null:
				temps.register_glow(m, 2.6, 0.9)
		"orbe":
			m = StandardMaterial3D.new()
			var oc: Color = {"": Color(0.55, 0.75, 1.0), "or": Color(1.0, 0.8, 0.45), "violet": Color(0.78, 0.55, 1.0), "vert": Color(0.5, 1.0, 0.7)}.get(variant, Color(0.55, 0.75, 1.0))
			m.albedo_color = oc
			m.emission_enabled = true
			m.emission = oc
			m.emission_energy_multiplier = 0.6
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			if temps != null:
				temps.register_glow(m, 3.2, 0.6)
		"cuivrevert":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.33, 0.58, 0.5)
			m.metallic = 0.55
			m.roughness = 0.5
		"or":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.86, 0.68, 0.3)
			m.metallic = 0.9
			m.roughness = 0.3
		"paille":
			m = StandardMaterial3D.new()
			m.albedo_texture = load("res://assets/textures/jungle/thatch.png")
			m.albedo_color = Color(1.05, 0.95, 0.72)
			m.roughness = 0.95
		"terrearc":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(AR + "tourbe.png")
			m.normal_enabled = true
			m.normal_texture = load(AR + "tourbe_n.png")
			m.roughness = 0.98
		"galets":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(AR + "galets.png")
			m.roughness = 0.9
		"schiste":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(AR + "schiste.png")
			m.normal_enabled = true
			m.normal_texture = load(AR + "schiste_n.png")
			m.normal_scale = 1.4
			m.roughness = 0.9
			m.albedo_color = Color(1, 1, 1) if variant == "" else Color(0.86, 0.9, 1.05)
		"pierrelune":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(AR + "schiste.png")
			m.normal_enabled = true
			m.normal_texture = load(AR + "schiste_n.png")
			m.normal_scale = 1.6
			m.albedo_color = Color(0.82, 0.86, 0.98)
			m.roughness = 0.7
			m.metallic_specular = 0.7
		"liquide":
			m = StandardMaterial3D.new()
			var lc: Color = {"": Color(0.4, 0.95, 0.5), "violet": Color(0.7, 0.4, 1.0), "bleu": Color(0.3, 0.6, 1.0), "rouge": Color(1.0, 0.35, 0.3), "or": Color(1.0, 0.8, 0.3)}.get(variant, Color(0.4, 0.95, 0.5))
			m.albedo_color = lc
			m.emission_enabled = true
			m.emission = lc
			m.emission_energy_multiplier = 1.2
			m.roughness = 0.1
		"flacon":
			m = StandardMaterial3D.new()
			var fc: Color = {"": Color(0.4, 0.6, 1.0), "rouge": Color(1.0, 0.3, 0.3), "vert": Color(0.3, 0.9, 0.45), "or": Color(1.0, 0.78, 0.3), "violet": Color(0.7, 0.4, 1.0), "rose": Color(1.0, 0.5, 0.8)}.get(variant, Color(0.4, 0.6, 1.0))
			m.albedo_color = Color(fc.r, fc.g, fc.b, 0.72)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.emission_enabled = true
			m.emission = fc
			m.emission_energy_multiplier = 0.25
			m.roughness = 0.05
			m.metallic_specular = 1.0
			if temps != null:
				temps.register_glow(m, 0.9, 0.25)
		"eaulac":
			m = StandardMaterial3D.new()
			# le Lac Miroir : une eau sombre et lisse qui renvoie le ciel
			m.albedo_color = Color(0.09, 0.16, 0.22, 0.9)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.normal_enabled = true
			m.normal_texture = load("res://assets/textures/water/water_n.png")
			m.normal_scale = 0.12
			m.uv1_scale = Vector3(0.05, 0.05, 0.05)
			m.roughness = 0.0
			m.metallic = 0.35
			m.metallic_specular = 1.0
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"glace":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.78, 0.9, 1.0, 0.82)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.roughness = 0.12
			m.metallic_specular = 1.0
			m.emission_enabled = true
			m.emission = Color(0.4, 0.6, 0.9)
			m.emission_energy_multiplier = 0.25
		"fenetrearc":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.18, 0.16, 0.14)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.72, 0.4)
			m.emission_energy_multiplier = 0.0
			m.roughness = 0.2
			if temps != null:
				temps.register_glow(m, 1.7, 0.0)
		"feu":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(1.0, 0.55, 0.15)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.45, 0.1)
			m.emission_energy_multiplier = 3.0
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		"enseignearc":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(AR + "enseigne_%s.png" % variant)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.3
			m.roughness = 0.6
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission = Color(1, 1, 1)
			m.emission_energy_multiplier = 0.0
			if temps != null:
				temps.register_glow(m, 0.35, 0.0)
		_:
			return super.mat(key)
	mats[key] = m
	return m


# =================================================================== outils

## Repère qui va de a vers b (axe +Y), pour une poutre ou un fût.
func axis_xf(a: Vector3, b: Vector3) -> Transform3D:
	var d: Vector3 = b - a
	var y: Vector3 = d.normalized()
	var x: Vector3 = y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Transform3D(Basis(x, y, z), a)


func beam(a: Vector3, b: Vector3, w: float, key: String, tile: float = 1.0) -> void:
	var xf: Transform3D = axis_xf(a, b)
	box(xf * Transform3D(Basis(), Vector3(0, a.distance_to(b) * 0.5, 0)), Vector3(w, a.distance_to(b), w), key, tile)


## Un repère posé sur la face d'un mur rond (rayon r, angle a autour de c), qui regarde dehors.
func round_face(c: Vector3, r: float, a: float, y: float) -> Transform3D:
	var out := Vector3(cos(a), 0, sin(a))
	return Transform3D(Basis.looking_at(out, Vector3.UP), c + out * r + Vector3.UP * y)


# =================================================================== fenêtres, portes

## Fenêtre en ogive (vitrail). xf : bas-milieu de la fenêtre, sur le nu du mur (qui regarde -Z).
## Note : Basis.looking_at(d) fait regarder -Z vers d ; la vitre est posée juste devant.
func lancet(xf: Transform3D, w: float, h: float, frame: String = "pierrearc_clair") -> void:
	var glass_h: float = h - w * 0.5
	quad(xf * Transform3D(Basis(), Vector3(0, glass_h * 0.5, -0.03)), w, glass_h, "vitrail", Vector2(0, 0.32), Vector2(1, 1))
	# l'ogive : deux triangles du même vitrail
	var top: Vector3 = Vector3(0, h, -0.03)
	var l: Vector3 = Vector3(-w * 0.5, glass_h, -0.03)
	var r: Vector3 = Vector3(w * 0.5, glass_h, -0.03)
	var n: Vector3 = (xf.basis * Vector3(0, 0, -1)).normalized()
	tri("vitrail", xf * l, xf * r, xf * top, n, Vector2(0.0, 0.32), Vector2(1.0, 0.32), Vector2(0.5, 0.0))
	# l'encadrement
	box(xf * Transform3D(Basis(), Vector3(-w * 0.5 - 0.07, glass_h * 0.5, -0.04)), Vector3(0.14, glass_h, 0.12), frame, 1.0)
	box(xf * Transform3D(Basis(), Vector3(w * 0.5 + 0.07, glass_h * 0.5, -0.04)), Vector3(0.14, glass_h, 0.12), frame, 1.0)
	var arc_len: float = Vector2(w * 0.5, h - glass_h).length() + 0.08
	for s in [-1.0, 1.0]:
		var mid := Vector3(s * w * 0.25, (glass_h + h) * 0.5, -0.04)
		var ang: float = atan2(h - glass_h, w * 0.5) * -s
		box(xf * Transform3D(Basis(Vector3.BACK, ang), mid + Vector3(s * 0.05, 0.04, 0)), Vector3(arc_len, 0.14, 0.12), frame, 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, -0.06, -0.08)), Vector3(w + 0.34, 0.12, 0.2), frame, 1.0)


## Porte en ogive : vantaux de bois clouté, encadrement de pierre. xf : bas-milieu, sur le mur.
func arch_door(xf: Transform3D, w: float, h: float, wood: String = "poutre") -> void:
	var rect_h: float = h - w * 0.5
	box(xf * Transform3D(Basis(), Vector3(0, rect_h * 0.5, -0.03)), Vector3(w, rect_h, 0.08), wood, 0.8)
	var n: Vector3 = (xf.basis * Vector3(0, 0, -1)).normalized()
	tri(wood, xf * Vector3(-w * 0.5, rect_h, -0.071), xf * Vector3(w * 0.5, rect_h, -0.071), xf * Vector3(0, h, -0.071), n, Vector2(0, 0.5), Vector2(1, 0.5), Vector2(0.5, 0))
	for k in range(3):
		box(xf * Transform3D(Basis(), Vector3(0, 0.4 + k * (rect_h - 0.6) * 0.5, -0.08)), Vector3(w * 0.96, 0.07, 0.03), "fer", 1.0)
	box(xf * Transform3D(Basis(), Vector3(0.0, rect_h * 0.5, -0.081)), Vector3(0.025, rect_h, 0.02), "fer", 1.0)
	box(xf * Transform3D(Basis(), Vector3(-w * 0.5 - 0.12, rect_h * 0.5, -0.06)), Vector3(0.24, rect_h, 0.18), "pierrearc_clair", 1.0)
	box(xf * Transform3D(Basis(), Vector3(w * 0.5 + 0.12, rect_h * 0.5, -0.06)), Vector3(0.24, rect_h, 0.18), "pierrearc_clair", 1.0)
	var arc_len: float = Vector2(w * 0.5 + 0.2, h - rect_h + 0.1).length()
	for s in [-1.0, 1.0]:
		var ang: float = atan2(h - rect_h, w * 0.5) * -s
		box(xf * Transform3D(Basis(Vector3.BACK, ang), Vector3(s * (w * 0.25 + 0.06), (rect_h + h) * 0.5 + 0.05, -0.06)), Vector3(arc_len, 0.22, 0.18), "pierrearc_clair", 1.0)


## Petite fenêtre à carreaux (maisons) : verre qui s'allume la nuit, croisée de bois.
func small_window(xf: Transform3D, w: float, h: float) -> void:
	quad(xf * Transform3D(Basis(), Vector3(0, 0, -0.02)), w, h, "fenetrearc")
	box(xf * Transform3D(Basis(), Vector3(0, 0, -0.04)), Vector3(0.05, h, 0.04), "poutre", 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, 0, -0.04)), Vector3(w, 0.05, 0.04), "poutre", 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, h * 0.5 + 0.05, -0.05)), Vector3(w + 0.18, 0.1, 0.1), "poutre", 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, -h * 0.5 - 0.05, -0.07)), Vector3(w + 0.22, 0.08, 0.16), "poutre", 1.0)
	for s in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(s * (w * 0.5 + 0.05), 0, -0.05)), Vector3(0.1, h, 0.1), "poutre", 1.0)


# =================================================================== toits

## Toit en cône (tour ronde) : xf au niveau du bas du toit ; un épi de faîtage doré.
func cone_roof(xf: Transform3D, r: float, h: float, key: String = "ecailles", seg: int = 20, finial: bool = true) -> void:
	cyl(xf, r, 0.0, h, key, seg, false, 2.0)
	cyl(xf, r, r, 0.12, "poutre", seg, false)
	cyl(xf * Transform3D(Basis(), Vector3(0, -0.02, 0)), r * 0.92, r * 0.92, 0.02, "poutre", seg, true)
	if finial:
		cyl(xf * Transform3D(Basis(), Vector3(0, h - 0.1, 0)), 0.05, 0.03, 1.4, "or", 6)
		cyl(xf * Transform3D(Basis(), Vector3(0, h + 0.6, 0)), 0.12, 0.0, 0.3, "or", 6)
		cyl(xf * Transform3D(Basis(), Vector3(0, h + 0.45, 0)), 0.0, 0.12, 0.15, "or", 6)


## Toit à deux pans très pentu (ardoises) ; xf au milieu du haut des murs, faîtage selon X.
func steep_roof(xf: Transform3D, w: float, d: float, key: String = "ecailles", pitch: float = 52.0, over: float = 0.45, gable: String = "pierrearc") -> float:
	return roof_gable(xf, w, d, pitch, over, key, gable)


# =================================================================== bâtiments

## Une tour ronde. opts : roof_h, roof ("cone", "flat", "none"), roof_key, windows (niveaux),
## door_dir (Vector3, vers où regarde la porte ; ZERO = pas de porte), band (bandeaux),
## crenel (créneaux), wall (matériau), collide.
func tower(c: Vector3, r: float, h: float, opts: Dictionary = {}) -> void:
	var wall: String = str(opts.get("wall", "pierrearc"))
	var seg: int = int(opts.get("seg", 20))
	cyl(Transform3D(Basis(), c + Vector3.DOWN * 0.6), r + 0.25, r + 0.15, 1.2, wall + "_sombre" if not wall.ends_with("_sombre") else wall, seg, false, 3.0)
	cyl(Transform3D(Basis(), c), r, r, h, wall, seg, false, 3.0)
	if bool(opts.get("band", true)):
		var y: float = 4.0
		while y < h - 1.5:
			cyl(Transform3D(Basis(), c + Vector3.UP * y), r + 0.08, r + 0.08, 0.2, "pierrearc_clair", seg, false, 2.0)
			y += 4.5
	var dd: Vector3 = opts.get("door_dir", Vector3.ZERO)
	var door_a: float = atan2(dd.z, dd.x) if dd.length() > 0.01 else 99.0
	if dd.length() > 0.01:
		arch_door(round_face(c, r, door_a, 0.0), minf(1.4, r * 0.6), 2.7)
	var levels: Array = opts.get("windows", [])
	var nwin: int = int(opts.get("nwin", 4))
	for lv in levels:
		for k in range(nwin):
			var a: float = door_a + TAU * (k + 0.5) / nwin + float(lv) * 0.37
			lancet(round_face(c, r, a, float(lv)), 0.62, 1.6)
	var top_y: float = h
	if bool(opts.get("crenel", false)):
		cyl(Transform3D(Basis(), c + Vector3.UP * (h - 0.05)), r + 0.35, r + 0.35, 0.3, wall, seg, true, 2.0)
		for k in range(seg):
			if k % 2 == 0:
				var a2: float = TAU * k / seg
				box(Transform3D(Basis(Vector3.UP, -a2), c + Vector3(cos(a2), 0, sin(a2)) * (r + 0.15) + Vector3.UP * (h + 0.55)), Vector3(0.4, 0.9, r * TAU / seg * 0.9), wall, 1.5)
		top_y = h + 0.25
	match str(opts.get("roof", "cone")):
		"cone":
			cone_roof(Transform3D(Basis(), c + Vector3.UP * top_y), r + float(opts.get("over", 0.5)), float(opts.get("roof_h", r * 1.9)), str(opts.get("roof_key", "ecailles")), seg)
		"flat":
			disc(Transform3D(Basis(), c + Vector3.UP * (top_y + 0.02)), r, "dallesarc", seg, 3.0)
	if bool(opts.get("collide", true)):
		col_cyl(c + Vector3.DOWN * 0.5, r + 0.1, h + 0.5)


## Maison à pans de bois : rez-de-chaussée de pierre, étage blanchi à la chaux en léger
## encorbellement, poutres sombres, toit pentu d'ardoises. xf : milieu de la façade au sol
## (la façade regarde -Z). Renvoie le point devant la porte.
func timber_house(xf: Transform3D, w: float, d: float, opts: Dictionary = {}) -> Vector3:
	var gf: float = float(opts.get("gf", 3.0))
	var uf: float = float(opts.get("uf", 2.8))
	var jet: float = 0.35
	var plaster: String = "colombage" + ("_" + str(opts["enduit"]) if opts.has("enduit") else "")
	var roof_key: String = "ecailles" + ("_" + str(opts["toit"]) if opts.has("toit") else "")
	# rez-de-chaussée
	box(xf * Transform3D(Basis(), Vector3(0, gf * 0.5 - 0.3, d * 0.5)), Vector3(w, gf + 0.6, d), "pierrearc", 3.0, 63 - 8)
	col_box(xf * Transform3D(Basis(), Vector3(0, gf * 0.5, d * 0.5)), Vector3(w, gf, d))
	# étage en encorbellement
	var u0: float = gf
	box(xf * Transform3D(Basis(), Vector3(0, u0 + uf * 0.5, d * 0.5)), Vector3(w + jet * 2.0, uf, d + jet * 2.0), plaster, 3.0, 63 - 8)
	box(xf * Transform3D(Basis(), Vector3(0, u0 - 0.1, d * 0.5)), Vector3(w + jet * 2.0 + 0.1, 0.22, d + jet * 2.0 + 0.1), "poutre", 1.0)
	col_box(xf * Transform3D(Basis(), Vector3(0, u0 + uf * 0.5, d * 0.5)), Vector3(w + jet * 2.0, uf, d + jet * 2.0))
	# colombages : poteaux et écharpes sur les quatre faces
	var faces := [[Vector3(0, 0, -jet), w + jet * 2.0, 0.0], [Vector3(0, 0, d + jet), w + jet * 2.0, PI], [Vector3(-w * 0.5 - jet, 0, d * 0.5), d + jet * 2.0, PI * 0.5], [Vector3(w * 0.5 + jet, 0, d * 0.5), d + jet * 2.0, -PI * 0.5]]
	for f in faces:
		var fxf: Transform3D = xf * Transform3D(Basis(Vector3.UP, float(f[2])), f[0])
		var fw: float = float(f[1])
		var nposts: int = maxi(2, int(fw / 1.3))
		for k in range(nposts + 1):
			var px: float = -fw * 0.5 + fw * k / nposts
			box(fxf * Transform3D(Basis(), Vector3(px, u0 + uf * 0.5, -0.03)), Vector3(0.16, uf, 0.06), "poutre", 1.0)
			if k < nposts and k % 2 == 0:
				var a := Vector3(px, u0 + 0.1, -0.03)
				var b := Vector3(px + fw / nposts, u0 + uf - 0.1, -0.03)
				var mid: Vector3 = (a + b) * 0.5
				var ang: float = atan2(b.y - a.y, b.x - a.x)
				box(fxf * Transform3D(Basis(Vector3.BACK, ang), mid), Vector3(a.distance_to(b), 0.13, 0.05), "poutre", 1.0)
		box(fxf * Transform3D(Basis(), Vector3(0, u0 + uf - 0.08, -0.03)), Vector3(fw, 0.16, 0.06), "poutre", 1.0)
		box(fxf * Transform3D(Basis(), Vector3(0, u0 + 0.9, -0.03)), Vector3(fw, 0.1, 0.05), "poutre", 1.0)
	# toit
	var rise: float = steep_roof(xf * Transform3D(Basis(), Vector3(0, u0 + uf, d * 0.5)), w + jet * 2.0, d + jet * 2.0, roof_key, float(opts.get("pitch", 50.0)), 0.5, plaster)
	# lucarne
	if bool(opts.get("lucarne", w > 5.5)):
		var lx: float = float(opts.get("lucarne_x", 0.0))
		var ly: float = u0 + uf + rise * 0.28
		var lz: float = -jet + (rise * 0.28) / tan(deg_to_rad(float(opts.get("pitch", 50.0)))) - 0.2
		box(xf * Transform3D(Basis(), Vector3(lx, ly + 0.6, lz + 0.6)), Vector3(1.3, 1.2, 1.2), plaster, 2.0)
		small_window(xf * Transform3D(Basis(), Vector3(lx, ly + 0.6, lz - 0.01)), 0.6, 0.7)
		roof_gable(xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(lx, ly + 1.2, lz + 0.6)), 1.3, 1.4, 45.0, 0.15, roof_key, plaster)
	# cheminée
	var cx: float = float(opts.get("chem_x", w * 0.3))
	box(xf * Transform3D(Basis(), Vector3(cx, u0 + uf + rise * 0.5 + 0.6, d * 0.68)), Vector3(0.7, rise + 1.6, 0.7), "pierrearc_sombre", 2.0)
	box(xf * Transform3D(Basis(), Vector3(cx, u0 + uf + rise + 1.45, d * 0.68)), Vector3(0.86, 0.12, 0.86), "pierrearc_clair", 1.0)
	# porte, fenêtres
	var door_x: float = float(opts.get("door_x", 0.0))
	arch_door(xf * Transform3D(Basis(), Vector3(door_x, 0, 0)), 1.1, 2.5)
	var nwin: int = maxi(1, int((w - 1.0) / 2.2))
	for k in range(nwin):
		var wx: float = -w * 0.5 + (k + 0.5) * w / nwin
		if absf(wx - door_x) > 1.3:
			small_window(xf * Transform3D(Basis(), Vector3(wx, 1.7, 0.0)), 0.75, 1.0)
		small_window(xf * Transform3D(Basis(), Vector3(wx, u0 + 1.45, -jet)), 0.75, 1.0)
	for s in [-1.0, 1.0]:
		small_window(xf * Transform3D(Basis(Vector3.UP, -s * PI * 0.5), Vector3(s * (w * 0.5 + jet), u0 + 1.45, d * 0.5)), 0.7, 0.95)
	return xf * Vector3(door_x, 0, -1.0)


## Un bâtiment où l'on entre (une salle) : murs de pierre (épaisseur t), une porte en ogive
## dans la façade (-Z), plancher, plafond, toit pentu, lumières. xf : milieu de la façade au
## sol. opts : h, door_x, door_w, roof_key, pitch, floor_key, inner (matériau des murs
## intérieurs), lights (nombre), energy, windows (bool). Renvoie {door, inside}.
func hall(xf: Transform3D, w: float, d: float, opts: Dictionary = {}) -> Dictionary:
	var h: float = float(opts.get("h", 4.2))
	var t: float = 0.45
	var dx: float = float(opts.get("door_x", 0.0))
	var dw: float = float(opts.get("door_w", 1.8))
	var dh: float = 2.9
	var wall: String = str(opts.get("wall", "pierrearc"))
	var inner: String = str(opts.get("inner", "colombage"))
	var left_w: float = (dx - dw * 0.5) + w * 0.5
	var right_w: float = w * 0.5 - (dx + dw * 0.5)
	for seg in [[-w * 0.5 + left_w * 0.5, left_w], [w * 0.5 - right_w * 0.5, right_w]]:
		if float(seg[1]) > 0.01:
			box(xf * Transform3D(Basis(), Vector3(float(seg[0]), h * 0.5 - 0.3, t * 0.5)), Vector3(float(seg[1]), h + 0.6, t), wall, 3.0, 63 - 8 - 16)
			box(xf * Transform3D(Basis(), Vector3(float(seg[0]), h * 0.5, t + 0.002)), Vector3(float(seg[1]), h, 0.0), inner, 3.0, 16)
			col_box(xf * Transform3D(Basis(), Vector3(float(seg[0]), h * 0.5, t * 0.5)), Vector3(float(seg[1]), h, t))
	box(xf * Transform3D(Basis(), Vector3(dx, (h + dh) * 0.5, t * 0.5)), Vector3(dw, h - dh, t), wall, 3.0, 63 - 8)
	col_box(xf * Transform3D(Basis(), Vector3(dx, (h + dh) * 0.5, t * 0.5)), Vector3(dw, h - dh, t))
	# l'encadrement en ogive (la porte reste ouverte : un vantail plaqué contre le mur dedans)
	var arc_len: float = Vector2(dw * 0.5 + 0.25, 0.7).length()
	for s in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(dx + s * (dw * 0.5 + 0.12), dh * 0.5 - 0.15, -0.06)), Vector3(0.26, dh - 0.3, 0.2), "pierrearc_clair", 1.0)
		box(xf * Transform3D(Basis(Vector3.BACK, -s * 0.5), Vector3(dx + s * (dw * 0.25 + 0.08), dh - 0.05, -0.06)), Vector3(arc_len, 0.24, 0.2), "pierrearc_clair", 1.0)
	box(xf * Transform3D(Basis(Vector3.UP, 1.4), Vector3(dx - dw * 0.5 + 0.08, dh * 0.45, t + 0.45)), Vector3(dw * 0.5, dh * 0.85, 0.07), "poutre", 0.8)
	# côtés et fond
	for s2 in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(s2 * (w * 0.5 - t * 0.5), h * 0.5 - 0.3, d * 0.5)), Vector3(t, h + 0.6, d), wall, 3.0, 1 if s2 > 0 else 2)
		box(xf * Transform3D(Basis(), Vector3(s2 * (w * 0.5 - t - 0.002), h * 0.5, d * 0.5)), Vector3(0.0, h, d - 2.0 * t), inner, 3.0, 2 if s2 > 0 else 1)
		col_box(xf * Transform3D(Basis(), Vector3(s2 * (w * 0.5 - t * 0.5), h * 0.5, d * 0.5)), Vector3(t, h, d))
	box(xf * Transform3D(Basis(), Vector3(0, h * 0.5 - 0.3, d - t * 0.5)), Vector3(w, h + 0.6, t), wall, 3.0, 16)
	box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, d - t - 0.002)), Vector3(w - 2.0 * t, h, 0.0), inner, 3.0, 32)
	col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, d - t * 0.5)), Vector3(w, h, t))
	# plancher, plafond, poutres
	box(xf * Transform3D(Basis(), Vector3(0, 0.04, d * 0.5)), Vector3(w - 2.0 * t, 0.08, d - 2.0 * t), str(opts.get("floor_key", "planches")), 2.0, 4)
	col_box(xf * Transform3D(Basis(), Vector3(0, -0.15, d * 0.5)), Vector3(w, 0.4, d))
	box(xf * Transform3D(Basis(), Vector3(0, h - 0.05, d * 0.5)), Vector3(w - 2.0 * t, 0.1, d - 2.0 * t), "poutre_clair", 2.0, 8)
	for k in range(int((d - 1.0) / 1.8)):
		box(xf * Transform3D(Basis(), Vector3(0, h - 0.2, 1.0 + k * 1.8)), Vector3(w - 2.0 * t, 0.22, 0.2), "poutre", 1.5, 63 - 4)
	# fenêtres en ogive sur les côtés
	if bool(opts.get("windows", true)):
		var nwin: int = maxi(1, int((d - 2.0) / 3.0))
		for s3 in [-1.0, 1.0]:
			for k2 in range(nwin):
				var wz: float = 1.5 + (k2 + 0.5) * (d - 3.0) / nwin
				lancet(xf * Transform3D(Basis(Vector3.UP, -s3 * PI * 0.5), Vector3(s3 * w * 0.5, 1.3, wz)), 0.7, minf(2.2, h - 1.8))
	# toit
	steep_roof(xf * Transform3D(Basis(), Vector3(0, h, d * 0.5)), w, d, str(opts.get("roof_key", "ecailles")), float(opts.get("pitch", 48.0)), 0.5, wall)
	# lumières chaudes
	var nl: int = int(opts.get("lights", 2))
	for k3 in range(nl):
		var l := OmniLight3D.new()
		l.light_color = opts.get("light_color", Color(1.0, 0.76, 0.5))
		l.light_energy = float(opts.get("energy", 1.3))
		l.omni_range = maxf(w, d) * 0.7
		l.shadow_enabled = false
		l.position = (xf * Transform3D(Basis(), Vector3(0, h - 0.8, d * (0.3 + 0.4 * float(k3) / maxf(nl - 1, 1)) if nl > 1 else d * 0.5))).origin
		root.add_child(l)
		lamp_count += 1
	return {"door": xf * Vector3(dx, 0, -1.2), "inside": xf * Vector3(dx, 0, d * 0.5)}


# =================================================================== mobilier, objets

## Réverbère de fer tordu : une boule de lumière bleutée flotte dans une couronne de fer.
func orb_lamp(pos: Vector3, h: float = 3.4, color: String = "", with_light: bool = true) -> void:
	var xf := Transform3D(Basis(), pos)
	cyl(xf, 0.18, 0.13, 0.35, "fer", 8)
	for k in range(3):
		var a: float = TAU * k / 3.0
		var p0 := Vector3(cos(a) * 0.06, 0.3, sin(a) * 0.06)
		var p1 := Vector3(cos(a + 1.2) * 0.06, h * 0.5, sin(a + 1.2) * 0.06)
		var p2 := Vector3(cos(a + 2.4) * 0.05, h - 0.35, sin(a + 2.4) * 0.05)
		beam(pos + p0, pos + p1, 0.05, "fer")
		beam(pos + p1, pos + p2, 0.045, "fer")
	ring(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), pos + Vector3(0, h, 0)), 0.2, 0.24, 0.03, "fer", 16)
	ring(Transform3D(Basis(Vector3.FORWARD, PI * 0.5), pos + Vector3(0, h, 0)), 0.2, 0.24, 0.03, "fer", 16)
	var orb := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.32
	orb.mesh = sm
	orb.material_override = mat("orbe" + ("_" + color if color != "" else ""))
	orb.position = pos + Vector3(0, h, 0)
	orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(orb)
	col_cyl(pos, 0.15, h)
	if with_light and temps != null:
		var l := OmniLight3D.new()
		l.light_color = {"": Color(0.6, 0.75, 1.0), "or": Color(1.0, 0.78, 0.5), "violet": Color(0.78, 0.6, 1.0), "vert": Color(0.55, 1.0, 0.75)}.get(color, Color(0.6, 0.75, 1.0))
		l.omni_range = 9.0
		l.omni_attenuation = 1.3
		l.shadow_enabled = false
		l.light_volumetric_fog_energy = 0.8
		l.position = pos + Vector3(0, h, 0)
		root.add_child(l)
		temps.register_lamp(l, 1.6)
		lamp_count += 1
		orbs.append(l)


## Brasero de fer sur trois pieds ; renvoie le point du feu (le feu est ajouté par l'île).
func brazier(pos: Vector3, h: float = 1.0) -> Vector3:
	var xf := Transform3D(Basis(), pos)
	for k in range(3):
		var a: float = TAU * k / 3.0
		beam(pos + Vector3(cos(a) * 0.45, 0, sin(a) * 0.45), pos + Vector3(cos(a) * 0.22, h - 0.1, sin(a) * 0.22), 0.06, "fer")
	cyl(xf * Transform3D(Basis(), Vector3(0, h - 0.15, 0)), 0.18, 0.42, 0.3, "fer", 12)
	ring(xf * Transform3D(Basis(), Vector3(0, h + 0.13, 0)), 0.38, 0.44, 0.05, "fer", 16)
	disc(xf * Transform3D(Basis(), Vector3(0, h + 0.05, 0)), 0.36, "cendre" if mats.has("cendre") else "fer", 12)
	col_cyl(pos, 0.42, h + 0.15)
	return pos + Vector3(0, h + 0.1, 0)


## Une pierre levée (menhir) : un bloc effilé, penché, des runes qui luisent sur une face.
func menhir(xf: Transform3D, h: float, w: float, d: float, glow: bool = true) -> void:
	var lean := Basis(Vector3.RIGHT, rng.randf_range(-0.05, 0.05)) * Basis(Vector3.BACK, rng.randf_range(-0.05, 0.05))
	var b: Transform3D = xf * Transform3D(lean, Vector3.ZERO)
	cyl(b * Transform3D(Basis(), Vector3(0, -0.5, 0)), w * 0.55, w * 0.42, h * 0.75, "pierrelune", 7, false, 1.5)
	cyl(b * Transform3D(Basis(), Vector3(0, h * 0.75 - 0.5, 0)), w * 0.42, w * 0.12, h * 0.25 + 0.5, "pierrelune", 7, true, 1.5)
	if glow:
		quad(b * Transform3D(Basis(), Vector3(0, h * 0.45, -w * 0.56)), w * 0.6, w * 0.6, "runes_pale", Vector2(0.3, 0.3), Vector2(0.7, 0.7))
	col_cyl(xf.origin, w * 0.45, h)


## Un amas de cristaux (des prismes hexagonaux pointus, inclinés).
func crystal(xf: Transform3D, s: float = 1.0, key: String = "cristal") -> void:
	var n: int = 5
	for k in range(n):
		var a: float = TAU * k / n + rng.randf_range(-0.3, 0.3)
		var tilt: float = 0.0 if k == 0 else rng.randf_range(0.25, 0.6)
		var hh: float = s * (1.6 if k == 0 else rng.randf_range(0.6, 1.1))
		var r: float = s * (0.22 if k == 0 else rng.randf_range(0.1, 0.16))
		var b := Basis(Vector3.UP, a) * Basis(Vector3.BACK, tilt)
		var off := Vector3(cos(a), 0, sin(a)) * (0.0 if k == 0 else s * 0.15)
		var cxf: Transform3D = xf * Transform3D(b, off)
		cyl(cxf, r, r, hh * 0.8, key, 6, false, 1.0)
		cyl(cxf * Transform3D(Basis(), Vector3(0, hh * 0.8, 0)), r, 0.0, hh * 0.25, key, 6, false, 1.0)


## Une étagère de livres (la face des livres regarde -Z). xf : bas-milieu, contre le mur.
func bookshelf(xf: Transform3D, w: float, h: float, d: float = 0.4) -> void:
	box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, d * 0.5)), Vector3(w, h, d), "poutre", 1.0, 63 - 32)
	quad(xf * Transform3D(Basis(), Vector3(0, h * 0.5, -0.02)), w - 0.1, h - 0.1, "livres", Vector2(0, 0), Vector2(w / 2.0, h / 2.4))
	for s in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(s * (w * 0.5 - 0.04), h * 0.5, d * 0.5 - 0.02)), Vector3(0.08, h, d + 0.04), "poutre", 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, h + 0.04, d * 0.5)), Vector3(w + 0.1, 0.08, d + 0.06), "poutre", 1.0)
	col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, d * 0.5)), Vector3(w, h, d))


## Un chaudron de fonte sur trois pieds, une potion qui bouillonne dedans.
func cauldron(xf: Transform3D, r: float = 0.6, liquid: String = "liquide") -> Vector3:
	for k in range(3):
		var a: float = TAU * k / 3.0
		beam(xf * Vector3(cos(a) * r * 0.7, 0, sin(a) * r * 0.7), xf * Vector3(cos(a) * r * 0.6, r * 0.5, sin(a) * r * 0.6), 0.06, "fer")
	cyl(xf * Transform3D(Basis(), Vector3(0, r * 0.3, 0)), r * 0.55, r, r * 0.6, "fer", 14)
	cyl(xf * Transform3D(Basis(), Vector3(0, r * 0.9, 0)), r, r * 0.85, r * 0.35, "fer", 14, false)
	ring(xf * Transform3D(Basis(), Vector3(0, r * 1.25, 0)), r * 0.82, r * 0.92, 0.05, "fer", 18)
	disc(xf * Transform3D(Basis(), Vector3(0, r * 1.1, 0)), r * 0.84, liquid, 16)
	col_cyl(xf.origin, r, r * 1.3)
	return xf * Vector3(0, r * 1.15, 0)


## Muret de pierres sèches de a à b (hauteur h), suivant le sol (y donnés).
func low_wall(a: Vector3, b: Vector3, h: float = 0.8, w: float = 0.55, key: String = "pierrearc_mousse") -> void:
	var d: Vector3 = b - a
	var flat := Vector3(d.x, 0, d.z)
	var len: float = flat.length()
	if len < 0.05:
		return
	var yaw: float = atan2(flat.x, flat.z)
	var n: int = maxi(1, int(len / 2.0))
	for k in range(n):
		var p0: Vector3 = a.lerp(b, float(k) / n)
		var p1: Vector3 = a.lerp(b, float(k + 1) / n)
		var mid: Vector3 = (p0 + p1) * 0.5
		var xf := Transform3D(Basis(Vector3.UP, yaw), mid + Vector3.UP * (h * 0.5 - 0.15))
		box(xf, Vector3(w, h + 0.3, len / n + 0.04), key, 1.2)
		box(xf * Transform3D(Basis(), Vector3(0, h * 0.5 + 0.12, 0)), Vector3(w + 0.1, 0.12, len / n + 0.04), "pierrearc_clair", 1.0)
		col_box(xf, Vector3(w, h + 0.3, len / n))


## Un ponton de planches sur pilotis, de a à b (hauteur y du plancher).
func pier(a: Vector3, b: Vector3, w: float, y: float) -> void:
	var d: Vector3 = Vector3(b.x - a.x, 0, b.z - a.z)
	var len: float = d.length()
	var yaw: float = atan2(d.x, d.z)
	var bas := Basis(Vector3.UP, yaw)
	var mid: Vector3 = (a + b) * 0.5
	mid.y = y
	box(Transform3D(bas, mid), Vector3(w, 0.12, len), "planches", 2.0)
	col_box(Transform3D(bas, mid + Vector3.DOWN * 0.1), Vector3(w, 0.32, len))
	var n: int = int(len / 2.5) + 1
	for k in range(n):
		var t: float = float(k) / maxf(n - 1, 1)
		var p: Vector3 = a.lerp(b, t)
		for s in [-1.0, 1.0]:
			var q: Vector3 = p + bas.x * s * (w * 0.5 - 0.1)
			cyl(Transform3D(Basis(), Vector3(q.x, -3.5, q.z)), 0.12, 0.12, y + 4.3, "poutre", 8)
	for s2 in [-1.0, 1.0]:
		box(Transform3D(bas, mid + bas.x * s2 * (w * 0.5 - 0.05) + Vector3.UP * 0.75), Vector3(0.08, 0.08, len), "poutre", 1.0)


## Le cadre d'une cloche (sur une tour) : deux montants, une traverse, la cloche (MeshInstance
## à part : elle se balance quand on la fait sonner). Renvoie la cloche.
func bell_frame(xf: Transform3D, r: float = 0.45) -> Node3D:
	for s in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(s * (r + 0.3), 0.9, 0)), Vector3(0.16, 1.8, 0.16), "poutre", 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, 1.85, 0)), Vector3(2.0 * r + 0.9, 0.2, 0.2), "poutre", 1.0)
	var pivot := Node3D.new()
	pivot.name = "Cloche"
	pivot.transform = xf * Transform3D(Basis(), Vector3(0, 1.75, 0))
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.7, 0.52, 0.26)
	m.metallic = 0.85
	m.roughness = 0.3
	var bell := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r * 0.45
	cm.bottom_radius = r
	cm.height = r * 1.4
	cm.radial_segments = 16
	bell.mesh = cm
	bell.material_override = m
	bell.position = Vector3(0, -r * 0.75, 0)
	pivot.add_child(bell)
	var lip := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = r * 0.92
	tm.outer_radius = r * 1.06
	lip.mesh = tm
	lip.material_override = m
	lip.position = Vector3(0, -r * 1.45, 0)
	pivot.add_child(lip)
	root.add_child(pivot)
	return pivot


## Une lunette astronomique de laiton sur un trépied.
func telescope(xf: Transform3D, aim_up: float = 0.6) -> void:
	for k in range(3):
		var a: float = TAU * k / 3.0
		beam(xf * Vector3(cos(a) * 0.5, 0, sin(a) * 0.5), xf * Vector3(0, 1.3, 0), 0.05, "poutre")
	var tb: Transform3D = xf * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5 + aim_up), Vector3(0, 1.35, 0))
	cyl(tb * Transform3D(Basis(), Vector3(0, -0.6, 0)), 0.1, 0.14, 1.9, "laiton", 12)
	cyl(tb * Transform3D(Basis(), Vector3(0, 1.3, 0)), 0.16, 0.16, 0.12, "laiton", 12)
	cyl(tb * Transform3D(Basis(), Vector3(0, -0.7, 0)), 0.05, 0.05, 0.14, "laiton", 8)
