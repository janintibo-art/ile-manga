extends "res://scripts/arcane_kit_v67.gd"
## V68 : les pièces de Port-Coutelas et de l'Île de la Balafre. Même principe que les autres kits
## (azur_kit_v56.gd, arcane_kit_v67.gd) : la géométrie est regroupée par matériau ; les
## collisions vont dans un seul corps statique. En plus :
##  - shack : une cabane de planches délavées (pilotis, véranda, volets, toit de palmes) ;
##  - wood_hall : une grande salle de bois où l'on entre (tripots) ;
##  - quay_wall, pier68, gangplank : le quai de pierre, les pontons, les passerelles ;
##  - crane, gallows, cannon, lantern, dice_table, bar_counter, palisade, tent, flag_pole,
##    tombstone, grave_cross, hammock, cage, anvil, coins, bottle_row, rib_arc.

const PI68 := "res://assets/textures/pirates/"
const PLANCHES := {"": Color(1, 1, 1), "sombre": Color(0.6, 0.56, 0.52), "clair": Color(1.15, 1.1, 1.02), "rouge": Color(1.25, 0.62, 0.52),
	"vert": Color(0.72, 1.0, 0.78), "bleu": Color(0.7, 0.88, 1.15), "jaune": Color(1.2, 1.05, 0.62), "noir": Color(0.36, 0.34, 0.34)}

var flags: Array = []                    # MeshInstance3D des pavillons (ils flottent au vent)
var walk_boxes: Array = []               # [Transform3D inverse, demi-taille] : passerelles, pontons
var lights68: Array = []                 # OmniLight3D des lanternes (la nuit)
var foot: Array = []                     # Rect2 (x, z monde) de tout ce qui est solide : le bric-à-brac ne s'y pose pas


func mat(key: String) -> Material:
	if mats.has(key):
		return mats[key]
	var m: StandardMaterial3D = null
	var parts: PackedStringArray = key.split("_", true, 1)
	var kind: String = parts[0]
	var variant: String = parts[1] if parts.size() > 1 else ""
	match kind:
		"planchesp":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(PI68 + "planchesp.png")
			m.normal_enabled = true
			m.normal_texture = load(PI68 + "planchesp_n.png")
			m.normal_scale = 1.1
			m.roughness = 0.92
			m.albedo_color = PLANCHES.get(variant, Color(1, 1, 1))
		"palmes":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(PI68 + "palmes.png")
			m.normal_enabled = true
			m.normal_texture = load(PI68 + "palmes_n.png")
			m.roughness = 0.96
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.albedo_color = Color(1, 1, 1) if variant == "" else Color(0.75, 0.7, 0.62)
		"toile":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(PI68 + "toile.png")
			m.normal_enabled = true
			m.normal_texture = load(PI68 + "toile_n.png")
			m.roughness = 0.95
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.albedo_color = {"": Color(1, 1, 1), "rouge": Color(0.95, 0.42, 0.36), "bleu": Color(0.55, 0.68, 0.9), "sale": Color(0.72, 0.66, 0.56)}.get(variant, Color(1, 1, 1))
		"pierrefort":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(PI68 + "pierrefort.png")
			m.normal_enabled = true
			m.normal_texture = load(PI68 + "pierrefort_n.png")
			m.normal_scale = 1.2
			m.roughness = 0.9
			m.albedo_color = Color(1, 1, 1) if variant == "" else Color(0.66, 0.64, 0.6)
		"rondins":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(PI68 + "rondins.png")
			m.normal_enabled = true
			m.normal_texture = load(PI68 + "rondins_n.png")
			m.roughness = 0.93
		"osp":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(PI68 + "os.png")
			m.normal_enabled = true
			m.normal_texture = load(PI68 + "os_n.png")
			m.roughness = 0.75
		"cordage":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.42, 0.34, 0.22)
			m.roughness = 0.95
		"orp":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.92, 0.7, 0.26)
			m.metallic = 0.9
			m.roughness = 0.3
		"bouteille":
			m = StandardMaterial3D.new()
			m.albedo_color = {"": Color(0.16, 0.36, 0.18, 0.85), "brune": Color(0.36, 0.2, 0.08, 0.85), "claire": Color(0.7, 0.8, 0.75, 0.6)}.get(variant, Color(0.16, 0.36, 0.18, 0.85))
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.roughness = 0.1
			m.metallic_specular = 0.9
		"pavillon", "voilep", "affiche":
			m = StandardMaterial3D.new()
			var file: String = {"pavillon": "pavillon_", "voilep": "voile_", "affiche": ""}[kind] + variant + ".png"
			m.albedo_texture = load(PI68 + file)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.5
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.roughness = 0.9
		"enseignep":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(PI68 + "enseigne_%s.png" % variant)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.3
			m.roughness = 0.7
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission = Color(1, 1, 1)
			m.emission_energy_multiplier = 0.0
			if temps != null:
				temps.register_glow(m, 0.3, 0.0)
		"de":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(PI68 + "de.png")
			m.roughness = 0.5
		"lanterne":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(1.0, 0.8, 0.45, 0.9)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.emission_enabled = true
			m.emission = Color(1.0, 0.66, 0.3)
			m.emission_energy_multiplier = 0.2
			if temps != null:
				temps.register_glow(m, 3.2, 0.2)
		"goudron":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.06, 0.05, 0.045)
			m.roughness = 0.35
		"braise":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.9, 0.3, 0.06)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.36, 0.08)
			m.emission_energy_multiplier = 2.2
		"tapis":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.1, 0.32, 0.18)
			m.roughness = 1.0
		"dalles":
			# le dallage du quai de Port-Coutelas : les dalles de Port-Azur, noircies de goudron,
			# de sel et de rhum renversé
			var base: StandardMaterial3D = (super.mat("dalles") as StandardMaterial3D).duplicate()
			base.albedo_color = Color(0.56, 0.52, 0.47)
			base.roughness = 0.88
			m = base
		_:
			return super.mat(key)
	mats[key] = m
	return m


# =================================================================== l'emprise au sol (pour le bric-à-brac)

func col_box(xf: Transform3D, size: Vector3) -> void:
	super.col_box(xf, size)
	var r := Rect2()
	var first: bool = true
	for sx in [-0.5, 0.5]:
		for sz in [-0.5, 0.5]:
			var p: Vector3 = xf * Vector3(size.x * sx, 0.0, size.z * sz)
			if first:
				r = Rect2(p.x, p.z, 0.0, 0.0)
				first = false
			else:
				r = r.expand(Vector2(p.x, p.z))
	foot.append(r)


func col_cyl(pos: Vector3, r: float, h: float) -> void:
	super.col_cyl(pos, r, h)
	foot.append(Rect2(pos.x - r, pos.z - r, r * 2.0, r * 2.0))


func crate(pos: Vector3, yaw: float, s: float = 0.7, fixe: bool = false) -> void:
	super.crate(pos, yaw, s, fixe)
	foot.append(Rect2(pos.x - s * 0.75, pos.z - s * 0.75, s * 1.5, s * 1.5))


func barrel(pos: Vector3, fixe: bool = false) -> void:
	super.barrel(pos, fixe)
	foot.append(Rect2(pos.x - 0.38, pos.z - 0.38, 0.76, 0.76))


## Une charrette à bras (deux roues, le plateau, les brancards posés au sol). xf : le milieu,
## au sol ; les brancards vers -Z.
func cart(xf: Transform3D, load_kind: String = "") -> void:
	box(xf * Transform3D(Basis(Vector3.RIGHT, 0.08), Vector3(0, 0.62, 0.1)), Vector3(1.3, 0.08, 1.9), "planchesp", 1.0)
	for sx in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(Vector3.RIGHT, 0.08), Vector3(sx * 0.62, 0.78, 0.1)), Vector3(0.05, 0.28, 1.9), "planchesp_sombre", 1.0)
		cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(sx * 0.75, 0.48, 0.35)), 0.48, 0.48, 0.07, "bois_sombre", 14)
		cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(sx * 0.78, 0.48, 0.35)), 0.08, 0.08, 0.1, "fer", 8)
		box(xf * Transform3D(Basis(Vector3.RIGHT, -0.26), Vector3(sx * 0.42, 0.42, -1.45)), Vector3(0.07, 0.07, 1.6), "poutre", 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, 0.48, 0.35)), Vector3(1.5, 0.07, 0.07), "fer", 1.0)
	match load_kind:
		"tonneaux":
			for k in range(2):
				cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.28 + k * 0.56, 0.95, 0.75)), 0.27, 0.27, 0.8, "bois", 10)
		"sacs":
			for k2 in range(3):
				cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5) * Basis(Vector3.UP, k2 * 0.4), Vector3(-0.3 + k2 * 0.3, 0.86, -0.2 + k2 * 0.35)), 0.2, 0.22, 0.6, "toile_sale", 8)
		"caisses":
			box(xf * Transform3D(Basis(Vector3.UP, 0.1), Vector3(-0.2, 0.95, 0.3)), Vector3(0.6, 0.6, 0.6), "bois", 0.7)
			box(xf * Transform3D(Basis(Vector3.UP, -0.2), Vector3(0.25, 0.85, -0.4)), Vector3(0.5, 0.4, 0.5), "bois", 0.7)
	col_box(xf * Transform3D(Basis(), Vector3(0, 0.6, 0.1)), Vector3(1.5, 1.2, 2.0))


## Un étal de marché : quatre poteaux, la table, un auvent de toile, des marchandises.
func stall(xf: Transform3D, cloth: String, goods: String) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			box(xf * Transform3D(Basis(), Vector3(sx * 1.1, 1.15 + (0.15 if sz < 0 else 0.0), sz * 0.6)), Vector3(0.09, 2.3 + (0.3 if sz < 0 else 0.0), 0.09), "poutre", 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, 0.82, 0)), Vector3(2.4, 0.08, 1.2), "planchesp", 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, 0.42, 0.55)), Vector3(2.3, 0.8, 0.04), "planchesp_sombre", 1.0)
	box(xf * Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(0, 2.42, 0.0)), Vector3(2.7, 0.04, 1.8), cloth, 1.0)
	col_box(xf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(2.4, 0.9, 1.2))
	match goods:
		"poisson":
			for k in range(7):
				cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5) * Basis(Vector3.RIGHT, rng.randf_range(-0.3, 0.3)), Vector3(-0.9 + k * 0.3, 0.9, rng.randf_range(-0.3, 0.3))), 0.05, 0.015, 0.36, "osp" if k % 3 == 0 else "fer", 6)
		"fruits":
			for k2 in range(10):
				cyl(xf * Transform3D(Basis(), Vector3(-1.0 + (k2 % 5) * 0.5, 0.86, -0.25 + (k2 / 5) * 0.4)), 0.11, 0.09, 0.12, ["braise", "toile_rouge", "palmes"][k2 % 3], 8)
		"bouteilles":
			for k3 in range(9):
				cyl(xf * Transform3D(Basis(), Vector3(-0.9 + k3 * 0.22, 0.86, rng.randf_range(-0.2, 0.2))), 0.05, 0.035, 0.3, ["bouteille", "bouteille_brune", "bouteille_claire"][k3 % 3], 8)
		_:
			for k4 in range(4):
				box(xf * Transform3D(Basis(Vector3.UP, rng.randf_range(-0.4, 0.4)), Vector3(-0.8 + k4 * 0.55, 1.0, rng.randf_range(-0.2, 0.2))), Vector3(0.35, 0.3, 0.3), "bois", 0.6)


## Une corde à linge entre deux poteaux, des chemises et des voiles qui sèchent.
func laundry(a: Vector3, b: Vector3) -> void:
	for p in [a, b]:
		cyl(Transform3D(Basis(), p), 0.06, 0.05, 2.3, "poutre", 6)
		col_cyl(p, 0.08, 2.3)
	var top_a: Vector3 = a + Vector3.UP * 2.2
	var top_b: Vector3 = b + Vector3.UP * 2.2
	var d: Vector3 = top_b - top_a
	var mid: Vector3 = (top_a + top_b) * 0.5 + Vector3.DOWN * 0.12
	var yaw: float = atan2(d.x, d.z)
	cyl(Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, PI * 0.5), top_a), 0.012, 0.012, d.length(), "cordage", 4, false)
	var keys: Array = ["toile", "toile_rouge", "toile_bleu", "toile_sale", "toile"]
	var n: int = int(d.length() / 0.9)
	for k in range(n):
		var t: float = (k + 0.5) / float(n)
		var p2: Vector3 = top_a.lerp(top_b, t) + Vector3.DOWN * (0.12 * sin(t * PI) + 0.35)
		var xf := Transform3D(Basis(Vector3.UP, yaw + PI * 0.5) * Basis(Vector3.RIGHT, rng.randf_range(-0.08, 0.08)), p2)
		quad(xf, rng.randf_range(0.45, 0.7), rng.randf_range(0.5, 0.75), str(keys[rng.randi() % keys.size()]), Vector2(0, 0), Vector2(1, 1), true)


# =================================================================== cabanes et salles

## Une cabane de planches délavées. xf : milieu de la façade au niveau du plancher (la façade
## regarde -Z). opts : pilotis (hauteur sous le plancher ; les pieux descendent jusqu'au sol
## « ground »), toit ("palmes", "planches"), couleur (planchesp_…), door_x, porch (profondeur
## de la véranda devant), h (hauteur des murs), windows (bool), collide.
## Renvoie le point devant la porte (au sol de la véranda).
func shack(xf: Transform3D, w: float, d: float, opts: Dictionary = {}) -> Vector3:
	var h: float = float(opts.get("h", 2.7))
	var col: String = "planchesp" + ("_" + str(opts["couleur"]) if opts.has("couleur") and str(opts["couleur"]) != "" else "")
	var roof: String = str(opts.get("toit", "palmes"))
	var dx: float = float(opts.get("door_x", 0.0))
	var dw: float = 1.0
	var dh: float = 2.05
	var porch: float = float(opts.get("porch", 0.0))
	var stilts: float = float(opts.get("pilotis", 0.0))
	var t: float = 0.12
	# le plancher (et les pilotis)
	box(xf * Transform3D(Basis(), Vector3(0, -0.08, d * 0.5 - porch * 0.5)), Vector3(w + 0.2, 0.16, d + porch), "planchesp_sombre", 1.6)
	col_box(xf * Transform3D(Basis(), Vector3(0, -0.15, d * 0.5 - porch * 0.5)), Vector3(w + 0.2, 0.3, d + porch))
	if stilts > 0.05:
		for sx in [-1.0, 0.0, 1.0]:
			for sz in [-porch, d * 0.5, d]:
				var pp: Vector3 = xf * Vector3(sx * (w * 0.5 - 0.1), 0, sz - (0.1 if sz >= d else -0.1 if sz <= -porch else 0.0))
				cyl(Transform3D(Basis(), pp + Vector3.DOWN * (stilts + 1.2)), 0.11, 0.1, stilts + 1.1, "rondins", 7, false)
		# les marches de la véranda (ou de la porte)
		var steps: int = int(ceil(stilts / 0.22))
		for k in range(steps):
			var sy: float = -stilts + (k + 0.5) * stilts / steps
			var sz2: float = -porch - 0.35 - (steps - k - 1) * 0.3
			box(xf * Transform3D(Basis(), Vector3(dx, sy, sz2)), Vector3(1.2, 0.08, 0.32), "planchesp_sombre", 1.0)
			col_box(xf * Transform3D(Basis(), Vector3(dx, sy - 0.1, sz2)), Vector3(1.2, 0.24, 0.32))
	# les murs (façade avec une porte, côtés, fond) : planches dehors, planches sombres dedans
	var left_w: float = (dx - dw * 0.5) + w * 0.5
	var right_w: float = w * 0.5 - (dx + dw * 0.5)
	for seg in [[-w * 0.5 + left_w * 0.5, left_w], [w * 0.5 - right_w * 0.5, right_w]]:
		if float(seg[1]) > 0.01:
			box(xf * Transform3D(Basis(), Vector3(float(seg[0]), h * 0.5, t * 0.5)), Vector3(float(seg[1]), h, t), col, 2.4, 63 - 4 - 8 - 16)
			box(xf * Transform3D(Basis(), Vector3(float(seg[0]), h * 0.5, t + 0.003)), Vector3(float(seg[1]), h, 0.0), "planchesp_sombre", 2.4, 16)
			col_box(xf * Transform3D(Basis(), Vector3(float(seg[0]), h * 0.5, t * 0.5)), Vector3(float(seg[1]), h, t))
	box(xf * Transform3D(Basis(), Vector3(dx, (h + dh) * 0.5, t * 0.5)), Vector3(dw, h - dh, t), col, 2.4, 63 - 4)
	col_box(xf * Transform3D(Basis(), Vector3(dx, (h + dh) * 0.5, t * 0.5)), Vector3(dw, h - dh, t))
	# l'encadrement et la porte entrouverte (un vantail de planches)
	for s in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(dx + s * (dw * 0.5 + 0.05), dh * 0.5, -0.03)), Vector3(0.1, dh, 0.08), "poutre", 1.0)
	box(xf * Transform3D(Basis(), Vector3(dx, dh + 0.05, -0.03)), Vector3(dw + 0.3, 0.1, 0.08), "poutre", 1.0)
	box(xf * Transform3D(Basis(Vector3.UP, 1.25), Vector3(dx - dw * 0.5 + 0.1, dh * 0.5, t + 0.35)), Vector3(dw * 0.9, dh * 0.97, 0.05), "planchesp_sombre", 1.2)
	for s2 in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(s2 * (w * 0.5 - t * 0.5), h * 0.5, d * 0.5)), Vector3(t, h, d), col, 2.4, (1 if s2 > 0 else 2))
		box(xf * Transform3D(Basis(), Vector3(s2 * (w * 0.5 - t - 0.003), h * 0.5, d * 0.5)), Vector3(0.0, h, d - 2.0 * t), "planchesp_sombre", 2.4, (2 if s2 > 0 else 1))
		col_box(xf * Transform3D(Basis(), Vector3(s2 * (w * 0.5 - t * 0.5), h * 0.5, d * 0.5)), Vector3(t, h, d))
	box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, d - t * 0.5)), Vector3(w, h, t), col, 2.4, 16)
	box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, d - t - 0.003)), Vector3(w - 2.0 * t, h, 0.0), "planchesp_sombre", 2.4, 32)
	col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, d - t * 0.5)), Vector3(w, h, t))
	# poteaux d'angle
	for cx in [-1.0, 1.0]:
		for cz in [0.0, d]:
			box(xf * Transform3D(Basis(), Vector3(cx * (w * 0.5 - 0.02), h * 0.5, cz + (0.02 if cz < 0.1 else -0.02))), Vector3(0.16, h + 0.05, 0.16), "poutre", 1.0)
	# fenêtres (volets ouverts)
	if bool(opts.get("windows", true)):
		for s3 in [-1.0, 1.0]:
			if w > 3.2:
				var wx: float = s3 * w * 0.3
				if absf(wx - dx) > 1.1:
					_shutter_window(xf * Transform3D(Basis(), Vector3(wx, 1.55, -0.01)), 0.7, 0.8)
			_shutter_window(xf * Transform3D(Basis(Vector3.UP, -s3 * PI * 0.5), Vector3(s3 * w * 0.5, 1.55, d * 0.5)), 0.65, 0.75)
	# le toit
	var top := xf * Transform3D(Basis(), Vector3(0, h, d * 0.5))
	if roof == "palmes":
		roof_gable(top, w, d, 38.0, 0.6, "palmes", col)
	else:
		roof_gable(top, w, d, 26.0, 0.45, "planchesp_noir", col)
	# la véranda : poteaux, rambarde, auvent
	if porch > 0.3:
		for s4 in [-1.0, 1.0]:
			box(xf * Transform3D(Basis(), Vector3(s4 * (w * 0.5 - 0.08), h * 0.42, -porch + 0.08)), Vector3(0.12, h * 0.84, 0.12), "poutre", 1.0)
			box(xf * Transform3D(Basis(), Vector3(s4 * (w * 0.5 - 0.08), 0.85, -porch * 0.5)), Vector3(0.07, 0.07, porch), "poutre", 1.0)
		var awn_l: float = Vector2(porch + 0.3, 0.45).length()
		box(xf * Transform3D(Basis(Vector3.RIGHT, -atan2(0.45, porch + 0.3)), Vector3(0, h * 0.84 + 0.25, -porch * 0.5 - 0.1)), Vector3(w + 0.3, 0.06, awn_l), "palmes" if roof == "palmes" else "planchesp_noir", 1.6)
	return xf * Vector3(dx, 0, -porch - 0.8 - (stilts / 0.22) * 0.3)


## Une fenêtre sans vitre : un cadre, l'ouverture sombre (la vitre « fenetrearc » s'allume la
## nuit), deux volets de planches ouverts. xf : centre, sur le mur (qui regarde -Z).
func _shutter_window(xf: Transform3D, w: float, h: float) -> void:
	quad(xf * Transform3D(Basis(), Vector3(0, 0, -0.015)), w, h, "fenetrearc")
	box(xf * Transform3D(Basis(), Vector3(0, h * 0.5 + 0.05, -0.04)), Vector3(w + 0.16, 0.08, 0.08), "poutre", 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, -h * 0.5 - 0.05, -0.06)), Vector3(w + 0.2, 0.07, 0.14), "poutre", 1.0)
	for s in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(s * (w * 0.5 + 0.04), 0, -0.04)), Vector3(0.07, h, 0.08), "poutre", 1.0)
		box(xf * Transform3D(Basis(Vector3.UP, s * 0.35), Vector3(s * (w * 0.75 + 0.06), 0, -0.12)), Vector3(w * 0.5, h, 0.04), "planchesp_sombre", 1.0)


## Une grande salle de bois où l'on entre (tripots). xf : milieu de la façade au plancher.
## opts : h, door_x, door_w, roof ("palmes" | "planches"), couleur, lights, energy,
## light_color, floor_key. Renvoie {door, inside}.
func wood_hall(xf: Transform3D, w: float, d: float, opts: Dictionary = {}) -> Dictionary:
	var h: float = float(opts.get("h", 4.0))
	var t: float = 0.3
	var dx: float = float(opts.get("door_x", 0.0))
	var dw: float = float(opts.get("door_w", 2.0))
	var dh: float = 2.6
	var col: String = "planchesp" + ("_" + str(opts["couleur"]) if opts.has("couleur") and str(opts["couleur"]) != "" else "")
	var inner: String = str(opts.get("inner", "planchesp_sombre"))
	var left_w: float = (dx - dw * 0.5) + w * 0.5
	var right_w: float = w * 0.5 - (dx + dw * 0.5)
	for seg in [[-w * 0.5 + left_w * 0.5, left_w], [w * 0.5 - right_w * 0.5, right_w]]:
		if float(seg[1]) > 0.01:
			box(xf * Transform3D(Basis(), Vector3(float(seg[0]), h * 0.5 - 0.3, t * 0.5)), Vector3(float(seg[1]), h + 0.6, t), col, 2.4, 63 - 8 - 16)
			box(xf * Transform3D(Basis(), Vector3(float(seg[0]), h * 0.5, t + 0.003)), Vector3(float(seg[1]), h, 0.0), inner, 2.4, 16)
			col_box(xf * Transform3D(Basis(), Vector3(float(seg[0]), h * 0.5, t * 0.5)), Vector3(float(seg[1]), h, t))
	box(xf * Transform3D(Basis(), Vector3(dx, (h + dh) * 0.5, t * 0.5)), Vector3(dw, h - dh, t), col, 2.4, 63 - 8)
	col_box(xf * Transform3D(Basis(), Vector3(dx, (h + dh) * 0.5, t * 0.5)), Vector3(dw, h - dh, t))
	# l'encadrement de la porte (et une porte battante de saloon, ouverte)
	for s in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(dx + s * (dw * 0.5 + 0.08), dh * 0.5, -0.05)), Vector3(0.16, dh, 0.14), "poutre", 1.0)
		box(xf * Transform3D(Basis(Vector3.UP, s * 1.2), Vector3(dx + s * (dw * 0.5 - 0.25), 1.35, t + 0.4)), Vector3(dw * 0.45, 1.1, 0.04), "planchesp_sombre", 1.0)
	box(xf * Transform3D(Basis(), Vector3(dx, dh + 0.08, -0.05)), Vector3(dw + 0.5, 0.16, 0.14), "poutre", 1.0)
	# côtés et fond
	for s2 in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(s2 * (w * 0.5 - t * 0.5), h * 0.5 - 0.3, d * 0.5)), Vector3(t, h + 0.6, d), col, 2.4, 1 if s2 > 0 else 2)
		box(xf * Transform3D(Basis(), Vector3(s2 * (w * 0.5 - t - 0.003), h * 0.5, d * 0.5)), Vector3(0.0, h, d - 2.0 * t), inner, 2.4, 2 if s2 > 0 else 1)
		col_box(xf * Transform3D(Basis(), Vector3(s2 * (w * 0.5 - t * 0.5), h * 0.5, d * 0.5)), Vector3(t, h, d))
	box(xf * Transform3D(Basis(), Vector3(0, h * 0.5 - 0.3, d - t * 0.5)), Vector3(w, h + 0.6, t), col, 2.4, 16)
	box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, d - t - 0.003)), Vector3(w - 2.0 * t, h, 0.0), inner, 2.4, 32)
	col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, d - t * 0.5)), Vector3(w, h, t))
	# poteaux d'angle, gros et sombres
	for cx in [-1.0, 1.0]:
		for cz in [0.0, d]:
			box(xf * Transform3D(Basis(), Vector3(cx * (w * 0.5 - 0.05), h * 0.5 - 0.3, cz + (-0.02 if cz < 0.1 else 0.02))), Vector3(0.3, h + 0.6, 0.3), "poutre", 1.0)
	# plancher, plafond, poutres
	box(xf * Transform3D(Basis(), Vector3(0, 0.04, d * 0.5)), Vector3(w - 2.0 * t, 0.08, d - 2.0 * t), str(opts.get("floor_key", "planchesp_sombre")), 2.0, 4)
	col_box(xf * Transform3D(Basis(), Vector3(0, -0.15, d * 0.5)), Vector3(w, 0.4, d))
	box(xf * Transform3D(Basis(), Vector3(0, h - 0.05, d * 0.5)), Vector3(w - 2.0 * t, 0.1, d - 2.0 * t), "planchesp_sombre", 2.0, 8)
	for k in range(int((d - 1.0) / 1.8)):
		box(xf * Transform3D(Basis(), Vector3(0, h - 0.22, 1.0 + k * 1.8)), Vector3(w - 2.0 * t, 0.26, 0.24), "poutre", 1.5, 63 - 4)
	# fenêtres à volets sur les côtés et en façade
	var nwin: int = maxi(1, int((d - 2.0) / 3.2))
	for s3 in [-1.0, 1.0]:
		for k2 in range(nwin):
			var wz: float = 1.6 + (k2 + 0.5) * (d - 3.2) / nwin
			_shutter_window(xf * Transform3D(Basis(Vector3.UP, -s3 * PI * 0.5), Vector3(s3 * w * 0.5, 1.7, wz)), 0.8, 0.9)
		var fx: float = s3 * w * 0.32
		if absf(fx - dx) > dw * 0.5 + 0.9:
			_shutter_window(xf * Transform3D(Basis(), Vector3(fx, 1.7, -0.01)), 0.9, 0.9)
	# le toit
	var top := xf * Transform3D(Basis(), Vector3(0, h, d * 0.5))
	if str(opts.get("roof", "planches")) == "palmes":
		roof_gable(top, w, d, 36.0, 0.7, "palmes", col)
	else:
		roof_gable(top, w, d, 28.0, 0.55, "planchesp_noir", col)
	# des lanternes suspendues, une lumière chaude (et vacillante, voir le port)
	var nl: int = int(opts.get("lights", 2))
	for k3 in range(nl):
		var lp: Vector3 = (xf * Transform3D(Basis(), Vector3(0, h - 0.9, d * (0.3 + 0.4 * float(k3) / maxf(nl - 1, 1)) if nl > 1 else d * 0.5))).origin
		cyl(Transform3D(Basis(), lp + Vector3.UP * 0.32), 0.008, 0.008, h - 1.2 - (lp.y - (xf.origin.y + 0.0)) + 0.6, "cordage", 4, false)
		cyl(Transform3D(Basis(), lp - Vector3.UP * 0.18), 0.13, 0.11, 0.36, "lanterne", 8)
		cyl(Transform3D(Basis(), lp + Vector3.UP * 0.18), 0.14, 0.05, 0.14, "fer", 8)
		var l := OmniLight3D.new()
		l.light_color = opts.get("light_color", Color(1.0, 0.7, 0.42))
		l.light_energy = float(opts.get("energy", 1.4))
		l.omni_range = maxf(w, d) * 0.65
		l.shadow_enabled = false
		l.position = lp
		root.add_child(l)
		lights68.append(l)
		lamp_count += 1
	return {"door": xf * Vector3(dx, 0, -1.2), "inside": xf * Vector3(dx, 0, d * 0.5)}


# =================================================================== le port

## Le mur du quai : des blocs de pierre, d'un point à l'autre, du fond jusqu'au niveau top.
func quay_wall(a: Vector3, b: Vector3, top: float, bottom: float, w: float = 1.4) -> void:
	var d: Vector3 = Vector3(b.x - a.x, 0, b.z - a.z)
	var len: float = d.length()
	var yaw: float = atan2(d.x, d.z)
	var bas := Basis(Vector3.UP, yaw)
	var n: int = maxi(1, int(len / 6.0))
	for k in range(n):
		var p0: Vector3 = a.lerp(b, (k + 0.5) / n)
		var c := Vector3(p0.x, (top + bottom) * 0.5, p0.z)
		box(Transform3D(bas, c), Vector3(w, top - bottom, len / n + 0.02), "pierrefort", 2.2)
		col_box(Transform3D(bas, c), Vector3(w, top - bottom, len / n))
		# la margelle : de grosses pierres plates
		box(Transform3D(bas, Vector3(p0.x, top + 0.06, p0.z)), Vector3(w + 0.25, 0.14, len / n - 0.05), "pierrefort_sombre", 1.4)


## Un ponton de planches goudronnées sur pieux, de a à b (plancher à la hauteur y) ; des bittes
## d'amarrage, des cordages.
func pier68(a: Vector3, b: Vector3, w: float, y: float) -> void:
	var d: Vector3 = Vector3(b.x - a.x, 0, b.z - a.z)
	var len: float = d.length()
	var yaw: float = atan2(d.x, d.z)
	var bas := Basis(Vector3.UP, yaw)
	var mid: Vector3 = (a + b) * 0.5
	mid.y = y
	box(Transform3D(bas, mid), Vector3(w, 0.14, len), "planchesp_sombre", 1.8)
	col_box(Transform3D(bas, mid + Vector3.DOWN * 0.1), Vector3(w, 0.34, len))
	walk_boxes.append([Transform3D(bas, mid).affine_inverse(), Vector3(w * 0.5 + 0.3, 3.0, len * 0.5 + 0.4)])
	var n: int = int(len / 3.0) + 1
	for k in range(n):
		var t: float = float(k) / maxf(n - 1, 1)
		var p: Vector3 = a.lerp(b, t)
		for s in [-1.0, 1.0]:
			var q: Vector3 = p + bas.x * s * (w * 0.5 + 0.05)
			cyl(Transform3D(Basis(), Vector3(q.x, -9.0, q.z)), 0.17, 0.15, y + 9.6, "rondins", 8, true)
			if k % 2 == 1:
				cyl(Transform3D(Basis(), Vector3(q.x, y + 0.6, q.z)), 0.15, 0.17, 0.05, "cordage", 8, true)
		box(Transform3D(bas, Vector3(p.x, y - 0.35, p.z)), Vector3(w + 0.4, 0.18, 0.2), "poutre", 1.0)


## Une passerelle du ponton (ou du quai) au pont d'un navire, avec ses mains courantes.
func gangplank(low: Vector3, top: Vector3, w: float = 1.3) -> void:
	var dir: Vector3 = top - low
	var f: Vector3 = dir.normalized()
	var side: Vector3 = f.cross(Vector3.UP).normalized()
	var up: Vector3 = side.cross(f).normalized()
	var gx := Transform3D(Basis(side, up, -f), (top + low) * 0.5)
	box(gx * Transform3D(Basis(), Vector3(0, -0.06, 0)), Vector3(w, 0.1, dir.length() + 0.4), "planchesp_sombre", 1.0)
	col_box(gx * Transform3D(Basis(), Vector3(0, -0.06, 0)), Vector3(w, 0.12, dir.length() + 0.4))
	for k in range(int(dir.length() / 0.45)):
		box(gx * Transform3D(Basis(), Vector3(0, 0.0, -dir.length() * 0.5 + 0.3 + k * 0.45)), Vector3(w, 0.04, 0.05), "poutre", 1.0)
	for s in [-1.0, 1.0]:
		box(gx * Transform3D(Basis(), Vector3(s * w * 0.5, 0.9, 0)), Vector3(0.04, 0.04, dir.length()), "cordage", 1.0)
		col_box(gx * Transform3D(Basis(), Vector3(s * (w * 0.5 + 0.05), 0.5, 0)), Vector3(0.1, 1.0, dir.length()))
	walk_boxes.append([gx.affine_inverse(), Vector3(w * 0.5 + 0.2, 3.0, dir.length() * 0.5 + 0.6)])


## Une grue de quai : un mât, une flèche, une poulie, un filet de marchandises qui pend.
func crane(xf: Transform3D, h: float = 6.5) -> void:
	cyl(xf, 0.3, 0.24, h, "rondins", 10)
	col_cyl(xf.origin, 0.32, h)
	for k in range(4):
		var a: float = TAU * k / 4.0 + 0.4
		beam(xf * Vector3(cos(a) * 1.4, 0, sin(a) * 1.4), xf * Vector3(0, 1.8, 0), 0.14, "poutre")
	var tip: Vector3 = xf * Vector3(0, h - 0.4, -4.5)
	beam(xf * Vector3(0, h * 0.55, 0), tip, 0.2, "poutre")
	beam(xf * Vector3(0, h, 0), tip, 0.05, "cordage")
	cyl(Transform3D(Basis(), tip + Vector3.DOWN * 2.4), 0.02, 0.02, 2.4, "cordage", 4, false)
	var net := tip + Vector3.DOWN * 3.4
	box(Transform3D(Basis(Vector3.UP, 0.4), net), Vector3(1.0, 0.9, 1.0), "toile_sale", 1.0)
	box(Transform3D(Basis(Vector3.UP, 0.4), net + Vector3(0, 0.1, 0)), Vector3(1.06, 0.06, 1.06), "cordage", 1.0)


## La potence de la place (vide, la corde se balance au vent).
func gallows(xf: Transform3D) -> Vector3:
	box(xf * Transform3D(Basis(), Vector3(0, 0.6, 0)), Vector3(3.4, 1.2, 2.6), "planchesp_sombre", 1.5)
	col_box(xf * Transform3D(Basis(), Vector3(0, 0.6, 0)), Vector3(3.4, 1.2, 2.6))
	for k2 in range(4):
		var sz: float = 1.3 + 0.3 * (4 - k2)
		box(xf * Transform3D(Basis(), Vector3(0, 0.15 + k2 * 0.3, sz)), Vector3(1.2, 0.08, 0.3), "planchesp_sombre", 1.0)
		col_box(xf * Transform3D(Basis(), Vector3(0, 0.15 + k2 * 0.3 - 0.1, sz)), Vector3(1.2, 0.26, 0.3))
	box(xf * Transform3D(Basis(), Vector3(-1.2, 1.2 + 1.8, 0)), Vector3(0.24, 3.6, 0.24), "poutre", 1.0)
	col_box(xf * Transform3D(Basis(), Vector3(-1.2, 1.2 + 1.8, 0)), Vector3(0.24, 3.6, 0.24))
	box(xf * Transform3D(Basis(), Vector3(-0.2, 4.7, 0)), Vector3(2.4, 0.22, 0.22), "poutre", 1.0)
	beam(xf * Vector3(-1.2, 3.9, 0), xf * Vector3(-0.4, 4.6, 0), 0.14, "poutre")
	return xf * Vector3(0.6, 4.6, 0)


## Un canon sur son affût (tourné vers -Z) ; quelques boulets empilés à côté.
func cannon(xf: Transform3D, balls: bool = true) -> void:
	box(xf * Transform3D(Basis(), Vector3(0, 0.32, 0.2)), Vector3(0.9, 0.36, 1.5), "poutre", 1.0)
	for s in [-1.0, 1.0]:
		for z in [-0.4, 0.75]:
			cyl(Transform3D(xf.basis * Basis(Vector3.BACK, PI * 0.5), xf * Vector3(s * 0.5, 0.22, z)), 0.22, 0.22, 0.1, "poutre", 10)
	cyl(Transform3D(xf.basis * Basis(Vector3.RIGHT, -PI * 0.5 + 0.08), xf * Vector3(0, 0.62, 0.9)), 0.2, 0.13, 2.1, "fer", 12)
	cyl(Transform3D(xf.basis * Basis(Vector3.RIGHT, -PI * 0.5 + 0.08), xf * Vector3(0, 0.62, 0.9)), 0.24, 0.24, 0.12, "fer", 12)
	cyl(Transform3D(xf.basis * Basis(Vector3.RIGHT, -PI * 0.5 + 0.08), xf * Vector3(0, 0.71, -1.08)), 0.17, 0.17, 0.12, "fer", 12)
	col_box(xf * Transform3D(Basis(), Vector3(0, 0.45, 0.1)), Vector3(0.9, 0.9, 2.0))
	if balls:
		var bp: Vector3 = xf * Vector3(1.1, 0.0, 0.6)
		for k in range(3):
			for j in range(3 - k):
				for i in range(3 - k - (0 if k == 0 else 0)):
					if k > 0 and (i >= 2 or j >= 2):
						continue
					var sph := Transform3D(Basis(), bp + xf.basis * Vector3(i * 0.24 + k * 0.12, 0.12 + k * 0.2, j * 0.24 + k * 0.12))
					cyl(sph * Transform3D(Basis(), Vector3(0, -0.11, 0)), 0.06, 0.06, 0.22, "fer", 6)
					cyl(sph * Transform3D(Basis(), Vector3(0, -0.06, 0)), 0.11, 0.11, 0.12, "fer", 8)


## Une lanterne de fer sur une potence de bois (ou accrochée à un mur si wall = true) ; une
## vraie lumière la nuit si with_light.
func lantern(pos: Vector3, yaw: float, with_light: bool = true, wall: bool = false) -> Vector3:
	var xf := Transform3D(Basis(Vector3.UP, yaw), pos)
	var lp: Vector3
	if wall:
		box(xf * Transform3D(Basis(), Vector3(0, 0, -0.25)), Vector3(0.05, 0.05, 0.5), "fer", 1.0)
		lp = xf * Vector3(0, -0.3, -0.48)
	else:
		cyl(xf, 0.09, 0.07, 3.0, "poutre", 6)
		col_cyl(pos, 0.1, 3.0)
		box(xf * Transform3D(Basis(), Vector3(0, 2.9, -0.35)), Vector3(0.06, 0.06, 0.8), "poutre", 1.0)
		lp = xf * Vector3(0, 2.5, -0.7)
	cyl(Transform3D(Basis(), lp + Vector3.UP * 0.2), 0.008, 0.008, 0.22, "fer", 4, false)
	cyl(Transform3D(Basis(), lp - Vector3.UP * 0.16), 0.11, 0.1, 0.32, "lanterne", 8)
	cyl(Transform3D(Basis(), lp + Vector3.UP * 0.16), 0.13, 0.04, 0.12, "fer", 8)
	cyl(Transform3D(Basis(), lp - Vector3.UP * 0.2), 0.12, 0.12, 0.04, "fer", 8)
	if with_light:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.66, 0.34)
		l.light_energy = 0.0
		l.omni_range = 7.5
		l.shadow_enabled = false
		l.position = lp
		root.add_child(l)
		lights68.append(l)
		lamp_count += 1
	return lp


## Une table de jeu (un tonneau coupé, un tapis vert), des dés, des gobelets, des pièces.
## Renvoie le centre du plateau.
func dice_table(pos: Vector3, yaw: float, r: float = 0.55) -> Vector3:
	var xf := Transform3D(Basis(Vector3.UP, yaw), pos)
	cyl(xf, r * 0.75, r * 0.82, 0.78, "bois", 12)
	for y in [0.15, 0.6]:
		cyl(xf * Transform3D(Basis(), Vector3(0, y, 0)), r * 0.8, r * 0.8, 0.05, "fer", 12, false)
	cyl(xf * Transform3D(Basis(), Vector3(0, 0.78, 0)), r, r, 0.06, "poutre", 16)
	disc(xf * Transform3D(Basis(), Vector3(0, 0.845, 0)), r * 0.85, "tapis", 16)
	col_cyl(pos, r, 0.85)
	for k in range(3):
		var a: float = 0.7 + k * 0.9
		var dp: Vector3 = xf * Vector3(cos(a) * 0.15, 0.885, sin(a) * 0.15)
		box(Transform3D(Basis(Vector3.UP, a * 2.3), dp), Vector3(0.07, 0.07, 0.07), "de", 0.07)
	cyl(xf * Transform3D(Basis(), Vector3(-0.28, 0.85, 0.18)), 0.07, 0.09, 0.16, "planchesp_sombre", 10)
	for c in range(4):
		var cp: Vector3 = xf * Vector3(0.25 - c * 0.04, 0.85, -0.22 + c * 0.02)
		for k2 in range(2 + c):
			cyl(Transform3D(Basis(), cp + Vector3.UP * k2 * 0.012), 0.03, 0.03, 0.01, "orp", 8)
	return xf * Vector3(0, 0.85, 0)


## Un comptoir de bar (le long de X local), des bouteilles sur le dessus et des étagères derrière
## (vers +Z). Renvoie le repère du comptoir.
func bar_counter(xf: Transform3D, len: float) -> void:
	box(xf * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(len, 1.1, 0.6), "planchesp_sombre", 1.2)
	box(xf * Transform3D(Basis(), Vector3(0, 1.13, 0)), Vector3(len + 0.2, 0.07, 0.8), "poutre", 1.0)
	col_box(xf * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(len, 1.1, 0.6))
	for k in range(int(len / 0.5)):
		if k % 3 == 1:
			cyl(xf * Transform3D(Basis(), Vector3(-len * 0.5 + 0.3 + k * 0.5, 1.17, 0.1)), 0.05, 0.035, 0.3, ["bouteille", "bouteille_brune", "bouteille_claire"][k % 3], 8)
	# étagères au mur
	for row in range(3):
		var sh: Transform3D = xf * Transform3D(Basis(), Vector3(0, 1.5 + row * 0.5, 1.4))
		box(sh, Vector3(len * 0.8, 0.05, 0.28), "poutre", 1.0)
		for b in range(int(len * 0.8 / 0.22)):
			var key: String = ["bouteille", "bouteille_brune", "bouteille_claire", "bouteille_brune"][(b + row) % 4]
			cyl(sh * Transform3D(Basis(), Vector3(-len * 0.4 + 0.12 + b * 0.22, 0.02, 0)), 0.045 + (b % 2) * 0.01, 0.03, 0.26 + (b % 3) * 0.05, key, 8)


## Une palissade de rondins pointus, de a à b.
func palisade(a: Vector3, b: Vector3, h: float = 2.6) -> void:
	var d: Vector3 = b - a
	var flat := Vector3(d.x, 0, d.z)
	var len: float = flat.length()
	var n: int = maxi(1, int(len / 0.32))
	for k in range(n):
		var p: Vector3 = a.lerp(b, (k + 0.5) / n)
		var hh: float = h * (0.9 + 0.2 * fposmod(sin(k * 12.9898) * 43758.5, 1.0))
		cyl(Transform3D(Basis(), p + Vector3.DOWN * 0.4), 0.15, 0.15, hh, "rondins", 6, false)
		cyl(Transform3D(Basis(), p + Vector3.UP * (hh - 0.4)), 0.15, 0.0, 0.35, "rondins", 6, false)
	var yaw: float = atan2(flat.x, flat.z)
	col_box(Transform3D(Basis(Vector3.UP, yaw), (a + b) * 0.5 + Vector3.UP * h * 0.4), Vector3(0.3, h, len))
	box(Transform3D(Basis(Vector3.UP, yaw), (a + b) * 0.5 + Vector3.UP * h * 0.55), Vector3(0.34, 0.12, len), "poutre", 1.0)


## Une tente de toile (deux pans), la toile tendue sur une perche.
func tent(xf: Transform3D, w: float, d: float, h: float, key: String = "toile") -> void:
	for s in [-1.0, 1.0]:
		var p0: Vector3 = xf * Vector3(s * w * 0.5, 0.0, -d * 0.5)
		var p1: Vector3 = xf * Vector3(s * w * 0.5, 0.0, d * 0.5)
		var p2: Vector3 = xf * Vector3(0, h, d * 0.5)
		var p3: Vector3 = xf * Vector3(0, h, -d * 0.5)
		var n: Vector3 = (xf.basis * Vector3(s * h, w * 0.5, 0)).normalized()
		quad4(key, p0, p1, p2, p3, n, Vector2(0, 1), Vector2(d / 2.0, 1), Vector2(d / 2.0, 0), Vector2(0, 0))
	tri(key, xf * Vector3(-w * 0.5, 0, d * 0.5), xf * Vector3(w * 0.5, 0, d * 0.5), xf * Vector3(0, h, d * 0.5), xf.basis * Vector3.BACK, Vector2(0, 1), Vector2(1, 1), Vector2(0.5, 0))
	cyl(Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), xf * Vector3(0, h, -d * 0.5 - 0.1)), 0.04, 0.04, d + 0.2, "poutre", 6, false)
	for z in [-d * 0.5 - 0.05, d * 0.5 + 0.05]:
		cyl(xf * Transform3D(Basis(), Vector3(0, 0, z)), 0.04, 0.04, h, "poutre", 6, false)
	col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.4, 0)), Vector3(w * 0.7, h * 0.8, d))


## Un mât de pavillon ; le pavillon (un MeshInstance à part, qui flotte) est rendu.
func flag_pole(pos: Vector3, h: float, flag_key: String, size := Vector2(1.6, 1.0)) -> MeshInstance3D:
	cyl(Transform3D(Basis(), pos), 0.08, 0.05, h, "poutre", 8)
	col_cyl(pos, 0.1, h)
	return flag_on(Transform3D(Basis(), pos + Vector3.UP * (h - size.y * 0.5 - 0.1)), flag_key, size)


## Un pavillon accroché à x (le bord gauche du drapeau est sur x.origin, il flotte vers +X).
func flag_on(x: Transform3D, flag_key: String, size := Vector2(1.6, 1.0)) -> MeshInstance3D:
	var pm := PlaneMesh.new()
	pm.size = size
	pm.subdivide_width = 8
	pm.orientation = PlaneMesh.FACE_Z
	var mi := MeshInstance3D.new()
	mi.name = "Pavillon_" + flag_key
	mi.mesh = pm
	mi.material_override = mat("pavillon_" + flag_key)
	mi.transform = x * Transform3D(Basis(), Vector3(size.x * 0.5 + 0.06, 0, 0))
	mi.set_meta("base", mi.transform)
	root.add_child(mi)
	flags.append(mi)
	return mi


## Une pierre tombale (un peu penchée), ou une croix de bois.
func tombstone(xf: Transform3D, h: float = 0.9) -> void:
	box(xf * Transform3D(Basis(), Vector3(0, h * 0.5 - 0.15, 0)), Vector3(0.55, h, 0.14), "pierrefort_sombre", 0.8)
	cyl(Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), xf * Vector3(0, h - 0.15, -0.07)), 0.275, 0.275, 0.14, "pierrefort_sombre", 10)
	col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.4, 0)), Vector3(0.55, h, 0.16))


func grave_cross(xf: Transform3D) -> void:
	box(xf * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(0.1, 1.3, 0.08), "poutre", 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, 0.85, 0)), Vector3(0.6, 0.1, 0.08), "poutre", 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, 0.06, -0.9)), Vector3(0.9, 0.12, 1.8), "terrearc", 1.0)


## Un hamac entre deux points (la toile pend au milieu).
func hammock(a: Vector3, b: Vector3, sag: float = 0.45) -> void:
	var n: int = 8
	var prev: Vector3 = a
	var side: Vector3 = (b - a).cross(Vector3.UP).normalized() * 0.45
	for k in range(1, n + 1):
		var t: float = float(k) / n
		var p: Vector3 = a.lerp(b, t) + Vector3.DOWN * sag * sin(PI * t)
		quad4("toile_rouge", prev - side, prev + side, p + side, p - side, Vector3.UP, Vector2(0, (k - 1) / float(n)), Vector2(1, (k - 1) / float(n)), Vector2(1, t), Vector2(0, t))
		quad4("toile_rouge", prev - side, prev + side, p + side, p - side, Vector3.DOWN, Vector2(0, (k - 1) / float(n)), Vector2(1, (k - 1) / float(n)), Vector2(1, t), Vector2(0, t))
		prev = p


## Une cage à oiseau (barreaux de fer, un anneau en haut).
func cage(pos: Vector3, r: float = 0.3, h: float = 0.6) -> void:
	for k in range(10):
		var a: float = TAU * k / 10.0
		cyl(Transform3D(Basis(), pos + Vector3(cos(a) * r, 0, sin(a) * r)), 0.01, 0.01, h, "fer", 4, false)
	cyl(Transform3D(Basis(), pos), r + 0.02, r + 0.02, 0.04, "fer", 12)
	cyl(Transform3D(Basis(), pos + Vector3.UP * h), r + 0.02, 0.04, 0.18, "fer", 12)


## Une enclume sur son billot.
func anvil(pos: Vector3, yaw: float) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw), pos)
	cyl(xf, 0.32, 0.3, 0.55, "rondins", 10)
	box(xf * Transform3D(Basis(), Vector3(0, 0.66, 0)), Vector3(0.3, 0.22, 0.22), "fer", 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, 0.82, 0)), Vector3(0.62, 0.1, 0.26), "fer", 1.0)
	cyl(Transform3D(xf.basis * Basis(Vector3.BACK, PI * 0.5), xf * Vector3(0.31, 0.82, 0)), 0.1, 0.0, 0.3, "fer", 8)
	col_cyl(pos, 0.34, 0.9)


## Un tas de pièces d'or (des piles et des pièces éparses).
func coins(pos: Vector3, n: int = 8, spread: float = 0.5) -> void:
	for k in range(n):
		var a: float = k * 2.39996
		var r: float = spread * sqrt(float(k) / maxf(n, 1))
		var p: Vector3 = pos + Vector3(cos(a) * r, 0, sin(a) * r)
		var hgt: int = 1 + (k * 7) % 6
		cyl(Transform3D(Basis(), p), 0.035, 0.035, 0.012 * hgt, "orp", 10)


## Une côte de baleine (un arc d'os) de a à b, bombée vers le haut.
func rib_arc(a: Vector3, b: Vector3, rise: float, r: float = 0.18) -> void:
	var n: int = 10
	var prev: Vector3 = a
	for k in range(1, n + 1):
		var t: float = float(k) / n
		var p: Vector3 = a.lerp(b, t) + Vector3.UP * rise * sin(PI * t)
		var rr: float = r * (1.0 - 0.4 * absf(t - 0.5))
		cyl(axis_xf(prev, p), rr, rr * 0.92, prev.distance_to(p) + 0.04, "osp", 7, false)
		prev = p
