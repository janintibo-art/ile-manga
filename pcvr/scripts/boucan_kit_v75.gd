extends "res://scripts/montjoie_kit_v71.gd"
## V75 : la boîte à outils de Port-Boucan, la ville-friche des punks (et de son dehors). Même principe
## que les autres kits : la géométrie regroupée par matière (commit()), les pièces répétées en
## MultiMesh (place()), les collisions dans un seul corps statique. Les matières « …75 » viennent de
## boucan_mats_v75.gd ; les autres, des kits précédents.
##  - usine75() : un bâtiment industriel de briques (pilastres, grandes fenêtres à petits carreaux
##    d'acier, corniche ; toit en sheds vitrés, en voûte, à deux pans ou plat ; creux ou plein) ;
##  - maison75() : une maison ouvrière de briques ; conteneur75() : un conteneur maritime (une
##    maison, s'il le faut) ; algeco75() : le bungalow de chantier ;
##  - grue75(), cheminee75(), chateau_eau75(), gazometre75(), cargo75(), phare75() ;
##  - rails75(), wagon75(), voiture75() (une épave), grillage75(), guirlande75() ;
##  - le mobilier de récup : palettes, canapé, tables, baignoire-fontaine, barils, pneus ;
##  - le skatepark : quarter75(), funbox75() ; les jardins : bac75(), serre75(), ruche75() ;
##  - la musique : scene75(), ampli75(), batterie75(), projecteur75() ;
##  - champi75() : un champignon géant lumineux.
## Repères : une façade « xf » regarde +Z local (comme les autres kits).

const Mats75 = preload("res://scripts/boucan_mats_v75.gd")
const CONT_V := ["rouge", "bleu", "vert", "orange", "jaune", "blanc", "gris", "turquoise", "rouge", "bleu"]

var spot_lights: Array = []              # les projecteurs de la scène (OmniLight3D / SpotLight3D)
var neon_mats: Array = []                # (pour la nuit)


func mat(key: String) -> Material:
	if mats.has(key):
		return mats[key]
	var m: Material = Mats75.make(key)
	if m != null:
		mats[key] = m
		return m
	if key == "grillage75":
		m = _grillage_mat()
		mats[key] = m
		return m
	return super.mat(key)


## Le grillage : un losange de fil de fer, transparent (une texture faite ici).
func _grillage_mat() -> StandardMaterial3D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in range(64):
		for t in range(-1, 2):
			for p in [[i, (i + t) % 64], [i, (64 - i + t) % 64]]:
				img.set_pixel(int(p[0]), posmod(int(p[1]), 64), Color(0.62, 0.64, 0.66, 1.0))
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.metallic = 0.7
	m.roughness = 0.5
	return m


## Les prototypes de Port-Boucan ; les autres : ceux de Montjoie et de V70.
func proto(key: String) -> ArrayMesh:
	if protos.has(key):
		return protos[key]
	var parts: PackedStringArray = key.split("|")
	var kind: String = parts[0]
	if not kind.ends_with("75"):
		return super.proto(key)
	var saved: Dictionary = batch
	batch = {}
	var I := Transform3D.IDENTITY
	var p1: String = parts[1] if parts.size() > 1 else ""
	match kind:
		"fenu75":
			# une grande fenêtre d'usine (1,8 × 3,0) : un quadrillage d'acier, des vitres
			_fenu_geo(1.8, 3.0, p1 == "1")
		"fenm75":
			# une fenêtre de maison (1,0 × 1,5) : un cadre blanc, deux vantaux, un appui de pierre
			_fenm_geo(p1 == "1", parts[2] if parts.size() > 2 else "")
		"porte75":
			_porte_geo(p1)
		"rideau75":
			# un rideau métallique de garage (3,6 × 3,4), tagué
			box(T(0, 1.7, 0.03), Vector3(3.6, 3.4, 0.06), "tolep75_" + (p1 if p1 != "" else "gris"), 1.2)
			box(T(0, 3.5, 0.12), Vector3(3.8, 0.3, 0.3), "rivete75_gris", 1.0)
		"palette75":
			for k in range(3):
				box(T(0, 0.13, -0.33 + k * 0.33), Vector3(1.2, 0.022, 0.1), "palette75", 1.0)
			for k2 in range(3):
				box(T(-0.55 + k2 * 0.55, 0.07, 0), Vector3(0.1, 0.1, 0.8), "palette75", 1.0)
			for k3 in range(5):
				box(T(0, 0.01, -0.36 + k3 * 0.18), Vector3(1.2, 0.02, 0.09), "palette75", 1.0)
		"pneu75":
			ring(I, 0.22, 0.36, 0.22, "caoutchouc75", 14)
		"bitte75":
			cyl(I, 0.22, 0.2, 0.55, "acier75", 10)
			cyl(T(0, 0.55, 0), 0.3, 0.3, 0.1, "acier75", 10)
		"baril75":
			cyl(I, 0.29, 0.29, 0.88, "tolep75_" + (p1 if p1 != "" else "bleu"), 12, true, 1.0)
			for y in [0.25, 0.62]:
				ring(T(0, y, 0), 0.285, 0.305, 0.03, "acier75", 12)
		"ampoule75":
			ball(I, 0.05, "lampe75", 6, 3)
		"traverse75":
			box(T(0, 0.07, 0), Vector3(2.4, 0.14, 0.24), "bardage75_sombre", 1.0)
		"lampadaire75":
			# un lampadaire de quai : un mât d'acier, une tête plate
			cyl(I, 0.12, 0.08, 7.0, "metal75_gris", 8, false)
			box(T(0.6, 7.0, 0), Vector3(1.4, 0.08, 0.12), "metal75_gris", 1.0)
			box(T(1.2, 6.92, 0), Vector3(0.6, 0.14, 0.34), "metal75_gris", 1.0)
			box(T(1.2, 6.84, 0), Vector3(0.5, 0.02, 0.26), "lampe75", 1.0)
		"chaise75":
			for s in [[-0.2, -0.2], [0.2, -0.2], [-0.2, 0.2], [0.2, 0.2]]:
				box(T(float(s[0]), 0.22, float(s[1])), Vector3(0.04, 0.44, 0.04), "metal75_" + (p1 if p1 != "" else "rouge"), 1.0)
			box(T(0, 0.46, 0), Vector3(0.46, 0.04, 0.46), "palette75", 1.0)
			box(T(0, 0.72, -0.21), Vector3(0.46, 0.44, 0.04), "palette75", 1.0)
		"plante75":
			cyl(I, 0.18, 0.22, 0.34, "tolep75_" + (p1 if p1 != "" else "rouge"), 8)
			for k4 in range(5):
				var a: float = TAU * k4 / 5.0
				ball(T(cos(a) * 0.12, 0.5 + (k4 % 2) * 0.12, sin(a) * 0.12), 0.16, "feuille75", 6, 3)
	var mesh := ArrayMesh.new()
	for k in batch:
		var st: SurfaceTool = batch[k]
		var m: Material = mat(str(k))
		if m is StandardMaterial3D and (m as StandardMaterial3D).normal_enabled:
			st.generate_tangents()
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, m)
	batch = saved
	protos[key] = mesh
	return mesh


# =================================================================== fenêtres, portes

## La fenêtre d'usine (le prototype : w × h, le bas au sol de la baie, sur le nu du mur qui regarde +Z).
func _fenu_geo(w: float, h: float, lit: bool) -> void:
	quadz(T(0, h * 0.5, -0.06), w, h, "vitre75_on" if lit else "vitre75_off")
	var nx: int = 3
	var ny: int = 5
	for i in range(nx + 1):
		box(T(-w * 0.5 + w * i / nx, h * 0.5, -0.03), Vector3(0.05, h, 0.06), "metal75_noir", 1.0)
	for j in range(ny + 1):
		box(T(0, h * j / ny, -0.03), Vector3(w, 0.05, 0.06), "metal75_noir", 1.0)
	# l'appui de béton, le linteau de briques en arc surbaissé (simplifié : un bandeau)
	box(T(0, -0.06, 0.05), Vector3(w + 0.3, 0.12, 0.24), "beton75_clair", 1.0)
	box(T(0, h + 0.12, 0.02), Vector3(w + 0.4, 0.24, 0.1), "brique75_sombre", 0.8)
	# un carreau cassé de temps en temps (dans la variante éteinte)
	if not lit:
		box(T(w * 0.17, h * 0.7, -0.07), Vector3(w / nx - 0.06, h / ny - 0.06, 0.005), "metal75_noir", 1.0)


func _fenm_geo(lit: bool, volet: String) -> void:
	var w: float = 1.0
	var h: float = 1.5
	quadz(T(0, h * 0.5, -0.05), w, h, "vitre75_on" if lit else "vitre75_off")
	for s in [-1.0, 1.0]:
		box(T(s * w * 0.5, h * 0.5, -0.02), Vector3(0.08, h, 0.08), "peint75_blanc", 1.0)
	box(T(0, h * 0.5, -0.02), Vector3(0.05, h, 0.06), "peint75_blanc", 1.0)
	box(T(0, h, -0.02), Vector3(w + 0.08, 0.08, 0.08), "peint75_blanc", 1.0)
	box(T(0, h * 0.55, -0.02), Vector3(w, 0.04, 0.05), "peint75_blanc", 1.0)
	box(T(0, -0.05, 0.06), Vector3(w + 0.24, 0.1, 0.2), "beton75_clair", 1.0)
	if volet != "":
		for s2 in [-1.0, 1.0]:
			box(T(s2 * (w * 0.5 + 0.3), h * 0.5, 0.04), Vector3(0.52, h, 0.04), "peint75_" + volet, 1.0)


func _porte_geo(color: String) -> void:
	var c: String = color if color != "" else "rouge"
	box(T(0, 1.1, -0.02), Vector3(1.1, 2.2, 0.06), "peint75_" + c, 1.0)
	box(T(0.38, 1.05, 0.03), Vector3(0.1, 0.05, 0.06), "chrome75", 1.0)
	for s in [-1.0, 1.0]:
		box(T(s * 0.62, 1.15, 0.0), Vector3(0.14, 2.3, 0.1), "beton75_clair", 1.0)
	box(T(0, 2.34, 0.0), Vector3(1.4, 0.16, 0.12), "beton75_clair", 1.0)
	box(T(0, 0.04, 0.3), Vector3(1.4, 0.08, 0.6), "beton75", 1.0)


func fenu75(xf: Transform3D, lit: bool) -> void:
	place("fenu75|" + ("1" if lit else "0"), xf)


func fenm75(xf: Transform3D, lit: bool, volet: String = "") -> void:
	place("fenm75|" + ("1" if lit else "0") + "|" + volet, xf)


func porte75(xf: Transform3D, color: String = "rouge") -> void:
	place("porte75|" + color, xf)


# =================================================================== le bâtiment industriel

## xf : le milieu de la façade au sol, la façade regarde +Z, le bâtiment s'étend vers -Z sur d.
## opts : h (hauteur des murs), wall (brique75…, briquep75_…, beton75…), inner, rows (rangées de
## fenêtres), bay (pas des travées), win (bool), lit (part allumée), roof (shed, arc, gable, plat,
## ""), roof_key, hollow (un intérieur : on entre), floor_key, door_x, door_w, door_h, back_door,
## side_doors [z gauche ou null, z droite ou null], lights (lustres), light_color, energy,
## pilasters, cornice, sign (id d'enseigne), sign_w, sign_h, fresque {"side": "l"/"r"/"f"/"b", "id":
## n, "w", "h", "x", "y"}, chimney (hauteur). Renvoie {door, inside, top}.
func usine75(xf: Transform3D, w: float, d: float, opts: Dictionary = {}) -> Dictionary:
	var h: float = float(opts.get("h", 8.0))
	var t: float = 0.5
	var wall: String = str(opts.get("wall", "brique75"))
	var inner: String = str(opts.get("inner", "briquep75_blanc"))
	var hollow: bool = bool(opts.get("hollow", false))
	var dw: float = float(opts.get("door_w", 3.2))
	var dh: float = float(opts.get("door_h", 3.6))
	var dx: float = float(opts.get("door_x", 0.0))
	var bay: float = float(opts.get("bay", 4.2))
	var rows: int = int(opts.get("rows", 1))
	var lit_k: float = float(opts.get("lit", 0.3))
	var win: bool = bool(opts.get("win", true))
	# le soubassement (une marche de béton) et, dedans, le sol
	box(xf * T(0, -0.3, -d * 0.5), Vector3(w + 0.3, 0.8, d + 0.3), "beton75_sombre", 2.0, 63 - 4)
	if hollow:
		box(xf * T(0, 0.08, -d * 0.5), Vector3(w - t, 0.06, d - t), str(opts.get("floor_key", "betonsol75")), 3.0, 4)
		col_box(xf * T(0, -0.15, -d * 0.5), Vector3(w, 0.5, d))
	else:
		box(xf * T(0, h * 0.5, -d * 0.5), Vector3(w - 0.02, h, d - 0.02), wall, 2.6, 63 - 8)
		col_box(xf * T(0, h * 0.5, -d * 0.5), Vector3(w, h, d))
	# les murs (creux : percés de leurs portes)
	if hollow:
		var walls := [
			[Transform3D(Basis(), Vector3(0, 0, -t * 0.5)), w, [[dx, dw, dh]]],
			[Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -d + t * 0.5)), w, [[0.0, dw, dh]] if bool(opts.get("back_door", false)) else []],
		]
		var sd: Array = opts.get("side_doors", [null, null])
		for s in [-1.0, 1.0]:
			var zpos: Variant = sd[0] if s < 0 else sd[1]
			var gaps: Array = []
			if zpos != null:
				gaps.append([(float(zpos) + d * 0.5) * (-s), 2.0, 2.8])
			walls.append([Transform3D(Basis(Vector3.UP, s * PI * 0.5), Vector3(s * (w * 0.5 - t * 0.5), 0, -d * 0.5)), d - t * 2.0, gaps])
		for wd in walls:
			var wx: Transform3D = xf * (wd[0] as Transform3D)
			var len: float = float(wd[1])
			var cur: float = -len * 0.5
			var gaps2: Array = (wd[2] as Array).duplicate()
			gaps2.sort_custom(func(p, q): return float(p[0]) < float(q[0]))
			for g in gaps2:
				var g0: float = float(g[0]) - float(g[1]) * 0.5
				var g1: float = float(g[0]) + float(g[1]) * 0.5
				_wall_piece(wx, cur, g0, 0.0, h, t, wall, inner)
				_wall_piece(wx, g0, g1, float(g[2]), h, t, wall, inner)
				box(wx * T(float(g[0]), float(g[2]) + 0.15, t * 0.5 + 0.04), Vector3(float(g[1]) + 0.5, 0.3, 0.12), "beton75_clair", 1.0)
				cur = g1
			_wall_piece(wx, cur, len * 0.5, 0.0, h, t, wall, inner)
	# les pilastres (une travée sur deux), la corniche
	if bool(opts.get("pilasters", true)):
		var nb: int = maxi(int(w / bay), 1)
		for i in range(nb + 1):
			var px: float = -w * 0.5 + w * i / nb
			box(xf * T(px, h * 0.5, 0.12), Vector3(0.6, h, 0.24), wall, 2.0, 63 - 32)
			box(xf * T(px, h * 0.5, -d - 0.12), Vector3(0.6, h, 0.24), wall, 2.0, 63 - 16)
		var nd: int = maxi(int(d / bay), 1)
		for s3 in [-1.0, 1.0]:
			for j in range(nd + 1):
				var pz: float = -d * j / nd
				box(xf * T(s3 * (w * 0.5 + 0.12), h * 0.5, pz), Vector3(0.24, h, 0.6), wall, 2.0, 63 - (2 if s3 > 0 else 1))
	if bool(opts.get("cornice", true)):
		box(xf * T(0, h + 0.15, -d * 0.5), Vector3(w + 0.7, 0.3, d + 0.7), str(opts.get("cornice_key", "brique75_sombre")), 2.0)
	# les fenêtres (sur les quatre faces, en rangées)
	if win:
		var wh: float = minf(3.0, (h - 1.6) / rows - 0.6)
		var ws: float = wh / 3.0
		var faces := [[Transform3D(Basis(), Vector3(0, 0, 0)), w, 0], [Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -d)), w, 1]]
		for s4 in [-1.0, 1.0]:
			faces.append([Transform3D(Basis(Vector3.UP, s4 * PI * 0.5), Vector3(s4 * w * 0.5, 0, -d * 0.5)), d, 2 if s4 < 0 else 3])
		for f in faces:
			var fx: Transform3D = xf * (f[0] as Transform3D)
			var flen: float = float(f[1])
			var nb2: int = maxi(int(flen / bay), 1)
			for r in range(rows):
				var y0: float = 1.0 + r * (h - 1.6) / rows
				for i2 in range(nb2):
					var cx: float = -flen * 0.5 + flen * (i2 + 0.5) / nb2
					if int(f[2]) == 0 and r == 0 and absf(cx - dx) < dw * 0.5 + 1.0:
						continue
					if hollow and r == 0 and int(f[2]) >= 2:
						var sdz: Array = opts.get("side_doors", [null, null])
						var zz: Variant = sdz[0] if int(f[2]) == 2 else sdz[1]
						if zz != null and absf(cx - (float(zz) + d * 0.5) * (1.0 if int(f[2]) == 3 else -1.0)) < 2.2:
							continue
					var lit: bool = rng.randf() < lit_k
					place("fenu75|" + ("1" if lit else "0"), fx * Transform3D(Basis.from_scale(Vector3(ws, ws, 1.0)), Vector3(cx, y0, 0.0)))
					if hollow:
						quadz(fx * Transform3D(Basis(Vector3.UP, PI), Vector3(cx, y0 + wh * 0.5, -t - 0.02)), 1.8 * ws, wh, "vitre75_usine")
	# le toit
	var roof: String = str(opts.get("roof", "gable"))
	var rk: String = str(opts.get("roof_key", "tole75"))
	var top: float = h + 0.3
	match roof:
		"shed":
			top = _sheds(xf * T(0, h + 0.3, 0), w, d, rk)
		"arc":
			top = _vault(xf * T(0, h + 0.3, 0), w, d, rk, bool(opts.get("glass_strip", true)))
		"gable":
			top = h + 0.3 + roof_gable(xf * T(0, h + 0.3, -d * 0.5), w, d, float(opts.get("pitch", 22.0)), 0.5, rk, wall)
		"plat":
			box(xf * T(0, h + 0.36, -d * 0.5), Vector3(w + 0.1, 0.12, d + 0.1), "beton75_sombre", 3.0)
			if bool(opts.get("roof_walk", false)):
				col_box(xf * T(0, h + 0.3, -d * 0.5), Vector3(w, 0.2, d))
	if hollow and bool(opts.get("ceiling", true)) and roof != "arc" and roof != "shed":
		box(xf * T(0, h - 0.05, -d * 0.5), Vector3(w - t, 0.1, d - t), inner, 3.0, 8)
	# l'enseigne, la fresque
	if opts.has("sign"):
		quadz(xf * T(float(opts.get("sign_x", 0.0)), float(opts.get("sign_y", h - 1.2)), 0.32), float(opts.get("sign_w", 6.0)), float(opts.get("sign_h", 1.4)), "enseigne75_" + str(opts["sign"]))
	for fr in opts.get("fresques", []):
		fresque75(xf, w, d, fr)
	# l'intérieur : des lampes d'atelier
	var nl: int = int(opts.get("lights", 2 if hollow else 0))
	for k in range(nl):
		var lz: float = -d * (0.5 if nl == 1 else (0.2 + 0.6 * float(k) / float(nl - 1)))
		var lp: Vector3 = xf * Vector3(0, h - 1.0, lz)
		cyl(Transform3D(Basis(), lp + Vector3.UP * 0.1), 0.012, 0.012, 0.9, "metal75_noir", 4, false)
		cyl(Transform3D(Basis(), lp), 0.45, 0.08, 0.3, "tolep75_vert", 10, false)
		_hall_light(lp + Vector3.DOWN * 0.3, opts.get("light_color", Color(1.0, 0.86, 0.66)), float(opts.get("energy", 1.6)), maxf(w, d) * 0.7)
	if opts.has("chimney"):
		var cp: Vector3 = xf * Vector3(w * 0.3, 0, -d * 0.7)
		cheminee75(cp, float(opts["chimney"]), 1.1, 0.8)
	if not hollow and bool(opts.get("v81", false)):
		porte_v81(xf, Vector3(dx, 0, 1.6), w, d, "boucan_entrepot", 1)
	return {"door": xf * Vector3(dx, 0, 1.6), "inside": xf * Vector3(0, 0, -d * 0.5), "top": top}


## Une lampe d'atelier ou de halle (une vraie lumière, pas d'ombre en VR).
func _hall_light(p: Vector3, c: Color, energy: float, rng_m: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = energy
	l.omni_range = rng_m
	l.omni_attenuation = 1.2
	l.shadow_enabled = pc
	l.distance_fade_enabled = true
	l.distance_fade_begin = 50.0
	l.distance_fade_length = 14.0
	l.distance_fade_shadow = 25.0
	root.add_child(l)
	l.position = p
	return l


## Les toits en sheds (en dents de scie : le pan vitré regarde le nord, +Z local du bâtiment ;
## xf : le milieu du bord avant, au haut des murs). Renvoie le faîte.
func _sheds(xf: Transform3D, w: float, d: float, key: String) -> float:
	var n: int = maxi(int(d / 7.0), 1)
	var step: float = d / n
	var rise: float = 2.6
	for i in range(n):
		var z0: float = -i * step
		var z1: float = z0 - step
		# le pan vitré (presque vertical) côté avant, le pan de tôle vers l'arrière
		var a0 := Vector3(-w * 0.5, 0, z0)
		var a1 := Vector3(w * 0.5, 0, z0)
		var b0 := Vector3(-w * 0.5, rise, z0 - 0.6)
		var b1 := Vector3(w * 0.5, rise, z0 - 0.6)
		var c0 := Vector3(-w * 0.5, 0, z1)
		var c1 := Vector3(w * 0.5, 0, z1)
		var ng: Vector3 = (xf.basis * (b0 - a0).cross(a1 - a0)).normalized()
		quad4("vitre75_usine", xf * a0, xf * a1, xf * b1, xf * b0, -ng, Vector2(0, 1), Vector2(w / 3.0, 1), Vector2(w / 3.0, 0), Vector2(0, 0))
		var nt: Vector3 = (xf.basis * (c1 - b1).cross(b0 - b1)).normalized()
		quad4(key, xf * b0, xf * b1, xf * c1, xf * c0, -nt, Vector2(0, 0), Vector2(w / 2.0, 0), Vector2(w / 2.0, step / 2.0), Vector2(0, step / 2.0))
		quad4(key, xf * b0, xf * b1, xf * c1, xf * c0, nt, Vector2(0, 0), Vector2(w / 2.0, 0), Vector2(w / 2.0, step / 2.0), Vector2(0, step / 2.0))
		# les pignons triangulaires (briques) aux deux bouts
		for s in [-1.0, 1.0]:
			var e := Vector3(s * w * 0.5, 0, 0)
			tri("brique75", xf * (a0 * Vector3(0, 1, 1) + e), xf * (b0 * Vector3(0, 1, 1) + e), xf * (c0 * Vector3(0, 1, 1) + e), (xf.basis * Vector3(s, 0, 0)).normalized(), Vector2(0, 1), Vector2(0.3, 0), Vector2(1, 1))
		# les fermes d'acier, dessous
		box(xf * T(0, rise * 0.5, z0 - 0.3), Vector3(w, 0.12, 0.12), "metal75_noir", 1.0)
	return rise


## Une voûte en berceau (la Halle), un bandeau de verre au faîte. Renvoie la hauteur de la voûte.
func _vault(xf: Transform3D, w: float, d: float, key: String, glass: bool) -> float:
	var segs: int = 12
	var r: float = w * 0.5
	var rise: float = r * 0.55
	for i in range(segs):
		var a0: float = PI * i / segs
		var a1: float = PI * (i + 1) / segs
		var p0 := Vector3(-cos(a0) * r, sin(a0) * rise, 0)
		var p1 := Vector3(-cos(a1) * r, sin(a1) * rise, 0)
		var k: String = "vitre75_usine" if glass and i >= segs / 2 - 1 and i <= segs / 2 else key
		var n: Vector3 = (xf.basis * Vector3(-(p1.y - p0.y), p1.x - p0.x, 0).normalized() * -1.0).normalized()
		quad4(k, xf * p0, xf * p1, xf * (p1 + Vector3(0, 0, -d)), xf * (p0 + Vector3(0, 0, -d)), n, Vector2(0, 0), Vector2(p0.distance_to(p1) / 2.0, 0), Vector2(p0.distance_to(p1) / 2.0, d / 2.0), Vector2(0, d / 2.0))
		quad4(k, xf * p0, xf * p1, xf * (p1 + Vector3(0, 0, -d)), xf * (p0 + Vector3(0, 0, -d)), -n, Vector2(0, 0), Vector2(p0.distance_to(p1) / 2.0, 0), Vector2(p0.distance_to(p1) / 2.0, d / 2.0), Vector2(0, d / 2.0))
		# les pignons en demi-lune (briques)
		for z in [0.0, -d]:
			var nn: Vector3 = (xf.basis * Vector3(0, 0, 1.0 if z == 0.0 else -1.0)).normalized()
			tri("brique75", xf * Vector3(0, 0, z), xf * (p0 + Vector3(0, 0, z)), xf * (p1 + Vector3(0, 0, z)), nn, Vector2(0.5, 1), Vector2(0.5 - p0.x / w, 1 - p0.y / w), Vector2(0.5 - p1.x / w, 1 - p1.y / w))
	# les arcs de fer, dessous
	var na: int = maxi(int(d / 4.0), 2)
	for j in range(na + 1):
		var z2: float = -d * j / na
		for i2 in range(segs):
			var a2: float = PI * i2 / segs
			var a3: float = PI * (i2 + 1) / segs
			beam(xf * Vector3(-cos(a2) * (r - 0.3), sin(a2) * (rise - 0.3), z2), xf * Vector3(-cos(a3) * (r - 0.3), sin(a3) * (rise - 0.3), z2), 0.14, "metal75_noir")
	return rise


## Une fresque peinte sur une façade (fr : side l/r/f/b, id, w, h, x (le long du mur), y (le bas)).
func fresque75(xf: Transform3D, w: float, d: float, fr: Dictionary) -> void:
	var side: String = str(fr.get("side", "f"))
	var fw: float = float(fr.get("w", 10.0))
	var fh: float = float(fr.get("h", 5.0))
	var x: float = float(fr.get("x", 0.0))
	var y: float = float(fr.get("y", 1.0)) + fh * 0.5
	var key: String = ("fresque75_" if not fr.has("graffiti") else "graffiti75_") + str(fr.get("id", 1))
	var fx: Transform3D
	match side:
		"f":
			fx = xf * T(x, y, 0.3)
		"b":
			fx = xf * Transform3D(Basis(Vector3.UP, PI), Vector3(-x, y, -d - 0.3))
		"l":
			fx = xf * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-w * 0.5 - 0.3, y, -d * 0.5 + x))
		_:
			fx = xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(w * 0.5 + 0.3, y, -d * 0.5 - x))
	quadz(fx, fw, fh, key)


# =================================================================== maisons ouvrières, conteneurs

## Une maison ouvrière de briques (xf : le milieu de la façade au sol, la façade regarde +Z).
## opts : floors, wall, roof (tole75, tuiles71_rouge…), volet, door (couleur), lit, graffiti (id),
## chimney (bool). Renvoie le point devant la porte.
func maison75(xf: Transform3D, w: float, d: float, opts: Dictionary = {}) -> Vector3:
	var floors: int = int(opts.get("floors", 2))
	var fh: float = 3.0
	var h: float = floors * fh + 0.4
	var wall: String = str(opts.get("wall", "brique75"))
	box(xf * T(0, h * 0.5, -d * 0.5), Vector3(w, h, d), wall, 2.4, 63 - 8)
	col_box(xf * T(0, h * 0.5, -d * 0.5), Vector3(w, h, d))
	box(xf * T(0, 0.25, 0.04), Vector3(w + 0.06, 0.5, 0.1), "beton75_sombre", 1.0)
	var dx: float = float(opts.get("door_x", -w * 0.25 if w > 5.0 else 0.0))
	porte75(xf * T(dx, 0.05, 0.0), str(opts.get("door", "rouge")))
	var nwin: int = maxi(int((w - 1.0) / 2.4), 1)
	var vol: String = str(opts.get("volet", ""))
	var lit_k: float = float(opts.get("lit", 0.35))
	for f in range(floors):
		for i in range(nwin):
			var wx: float = -w * 0.5 + w * (i + 0.5) / nwin
			if f == 0 and absf(wx - dx) < 1.3:
				continue
			fenm75(xf * T(wx, 0.9 + f * fh, 0.0), rng.randf() < lit_k, vol)
			fenm75(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(-wx, 0.9 + f * fh, -d)), rng.randf() < lit_k * 0.6, "")
	# une corniche de briques, le toit
	box(xf * T(0, h + 0.1, -d * 0.5), Vector3(w + 0.3, 0.2, d + 0.3), "brique75_sombre", 1.6)
	var roof: String = str(opts.get("roof", "tole75"))
	var rise: float = 0.0
	if roof != "":
		rise = roof_gable(xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, h + 0.2, -d * 0.5)), d, w, float(opts.get("pitch", 30.0)), 0.35, roof, wall)
	if bool(opts.get("chimney", true)):
		var cx: Vector3 = xf * Vector3(w * 0.3, h + rise * 0.6, -d * 0.5)
		box(Transform3D(xf.basis, cx + Vector3.UP * 0.8), Vector3(0.6, 1.8, 0.6), "brique75_suie", 1.0)
		chimneys70.append(cx + Vector3.UP * 1.8)
	if opts.has("graffiti"):
		quadz(xf * T(w * 0.15, 1.6, 0.04), minf(w * 0.7, 4.0), minf(w * 0.35, 2.0), "graffiti75_" + str(opts["graffiti"]))
	if bool(opts.get("v81", false)):
		porte_v81(xf, Vector3(dx, 0, 1.2), w, d, "boucan", floors)
	return xf * Vector3(dx, 0, 1.2)


## Un conteneur maritime (xf : le centre du sol, la longueur le long de X local). opts : len (6 ou
## 12), home (des fenêtres, une porte côté +Z), door_color, lit, solid (collision).
func conteneur75(xf: Transform3D, color: String, opts: Dictionary = {}) -> Vector3:
	var len: float = float(opts.get("len", 12.0))
	var cw: float = 2.44
	var ch: float = 2.6
	var key: String = "tolep75_" + color
	box(xf * T(0, ch * 0.5, 0), Vector3(len, ch, cw), key, 1.3)
	# les longerons, les pièces de coin
	for y in [0.08, ch - 0.08]:
		for s in [-1.0, 1.0]:
			box(xf * T(0, y, s * (cw * 0.5 + 0.02)), Vector3(len, 0.16, 0.06), "rivete75_" + color, 1.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			for y2 in [0.09, ch - 0.09]:
				box(xf * T(sx * (len * 0.5 - 0.1), y2, sz * (cw * 0.5 - 0.1)), Vector3(0.24, 0.2, 0.24), "acier75", 1.0)
	# les portes du bout (+X) : les barres de fermeture
	for k in range(4):
		box(xf * T(len * 0.5 + 0.04, ch * 0.5, -0.9 + k * 0.6), Vector3(0.04, ch - 0.3, 0.05), "rivete75_gris", 1.0)
	if bool(opts.get("home", false)):
		var fz: float = cw * 0.5 + 0.02
		var lit: bool = bool(opts.get("lit", true))
		for wx in [-len * 0.3, len * 0.15]:
			box(xf * T(wx, 1.4, fz - 0.01), Vector3(1.4, 1.1, 0.02), "vitre75_on" if lit else "vitre75_off", 1.0)
			box(xf * T(wx, 1.4, fz), Vector3(1.6, 1.3, 0.03), "peint75_blanc", 1.0, 16)
		box(xf * T(len * 0.38, 1.05, fz), Vector3(0.9, 2.05, 0.04), "peint75_" + str(opts.get("door_color", "jaune")), 1.0)
	if bool(opts.get("solid", true)):
		col_box(xf * T(0, ch * 0.5, 0), Vector3(len, ch, cw))
	if bool(opts.get("home", false)) and bool(opts.get("v81", false)):
		porte_v81(xf, Vector3(len * 0.38, 0, cw * 0.5 + 1.0), len, cw, "boucan_conteneur", 1)
	return xf * Vector3(len * 0.38, 0, cw * 0.5 + 1.0)


## Le bungalow de chantier de Lisse & Fils (xf : le milieu de la façade, qui regarde +Z).
func algeco75(xf: Transform3D, w: float, d: float) -> Vector3:
	box(xf * T(0, 1.55, -d * 0.5), Vector3(w, 2.6, d), "tolep75_blanc", 1.2)
	box(xf * T(0, 2.9, -d * 0.5), Vector3(w + 0.2, 0.12, d + 0.2), "tolep75_gris", 1.2)
	for sx in [-1.0, 1.0]:
		for sz in [0.0, -d]:
			box(xf * T(sx * (w * 0.5 - 0.2), 0.12, sz + (-0.2 if sz == 0.0 else 0.2)), Vector3(0.3, 0.24, 0.3), "beton75", 1.0)
	col_box(xf * T(0, 1.55, -d * 0.5), Vector3(w, 2.6, d))
	for wx in [-w * 0.32, w * 0.05, w * 0.32]:
		box(xf * T(wx, 1.7, 0.01), Vector3(1.3, 0.9, 0.02), "vitre75_on", 1.0)
	box(xf * T(-w * 0.15, 1.3, 0.02), Vector3(0.9, 2.0, 0.03), "tolep75_gris", 1.0)
	stair(xf * Vector3(-w * 0.15, 0.0, 1.4), xf * Vector3(-w * 0.15, 0.3, 0.3), 1.1, "acier75")
	return xf * Vector3(-w * 0.15, 0, 1.8)


# =================================================================== les grandes machines du port

## Une grue de quai à portique (xf : au sol, entre les quatre pieds ; la flèche s'avance vers -Z,
## au-dessus de l'eau). Renvoie le bout de la flèche.
func grue75(xf: Transform3D, h: float = 18.0, color: String = "jaune") -> Vector3:
	var key: String = "tolep75_" + color
	var span := Vector2(9.0, 7.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var a: Vector3 = xf * Vector3(sx * span.x * 0.5, 0, sz * span.y * 0.5)
			box(Transform3D(xf.basis, a + Vector3.UP * h * 0.5), Vector3(0.7, h, 0.7), key, 1.4)
			col_box(Transform3D(xf.basis, a + Vector3.UP * h * 0.5), Vector3(0.7, h, 0.7))
			box(Transform3D(xf.basis, a + Vector3.UP * 0.4), Vector3(1.2, 0.8, 1.6), "acier75", 1.0)
		# les croix de saint André entre les pieds
		beam(xf * Vector3(sx * span.x * 0.5, 1.0, -span.y * 0.5), xf * Vector3(sx * span.x * 0.5, h * 0.6, span.y * 0.5), 0.22, key)
		beam(xf * Vector3(sx * span.x * 0.5, 1.0, span.y * 0.5), xf * Vector3(sx * span.x * 0.5, h * 0.6, -span.y * 0.5), 0.22, key)
	for sz2 in [-1.0, 1.0]:
		box(xf * T(0, h * 0.62, sz2 * span.y * 0.5), Vector3(span.x + 0.7, 0.6, 0.6), key, 1.4)
	# le plateau, la machinerie, la cabine
	box(xf * T(0, h + 0.4, 0), Vector3(span.x + 1.2, 0.8, span.y + 1.2), key, 1.6)
	box(xf * T(0, h + 2.2, 1.0), Vector3(5.0, 2.8, 4.0), key, 1.4)
	box(xf * T(0, h + 2.4, 3.02), Vector3(3.6, 1.2, 0.04), "vitre75_off", 1.0)
	# la flèche : deux poutres en treillis
	var reach: float = 26.0
	for s in [-0.9, 0.9]:
		box(xf * T(s, h + 1.2, -reach * 0.5 + 2.0), Vector3(0.5, 0.9, reach + 6.0), key, 1.4)
	for k in range(int(reach / 2.5)):
		var z: float = 4.0 - k * 2.5
		beam(xf * Vector3(-0.9, h + 0.8, z), xf * Vector3(0.9, h + 1.6, z - 2.5), 0.1, key)
	# le câble, le crochet
	var tip: Vector3 = xf * Vector3(0, h + 0.8, -reach + 2.0)
	cyl(Transform3D(Basis(), tip + Vector3.DOWN * 9.0), 0.03, 0.03, 9.0, "metal75_noir", 4, false)
	box(Transform3D(xf.basis, tip + Vector3.DOWN * 9.3), Vector3(0.6, 0.5, 0.4), "tolep75_rouge", 1.0)
	return tip


## Une cheminée d'usine en briques (pos : le pied), haute de h, effilée de r0 à r1.
func cheminee75(pos: Vector3, h: float, r0: float, r1: float) -> void:
	box(Transform3D(Basis(), pos + Vector3.UP * 1.5), Vector3(r0 * 2.6, 3.0, r0 * 2.6), "brique75_sombre", 2.0)
	cyl(Transform3D(Basis(), pos + Vector3.UP * 3.0), r0, r1, h - 3.0, "brique75", 16, false, 2.4)
	for y in [h * 0.45, h * 0.75]:
		ring(Transform3D(Basis(), pos + Vector3.UP * y), lerpf(r0, r1, (y - 3.0) / (h - 3.0)) - 0.02, lerpf(r0, r1, (y - 3.0) / (h - 3.0)) + 0.12, 0.25, "acier75", 16)
	ring(Transform3D(Basis(), pos + Vector3.UP * (h - 0.6)), r1 - 0.3, r1 + 0.25, 0.6, "brique75_suie", 16)
	col_cyl(pos, r0 * 1.3, h)
	chimneys70.append(pos + Vector3.UP * h)


## Un château d'eau (pos : le pied, au centre) : une cuve ronde peinte d'une fresque, sur huit
## pieds ; une échelle. Renvoie le haut de la cuve (là où l'antenne de la radio est tombée).
func chateau_eau75(pos: Vector3, fresque_id: int = 7) -> Vector3:
	var hl: float = 18.0
	var r: float = 5.0
	for k in range(8):
		var a: float = TAU * k / 8.0
		var foot: Vector3 = pos + Vector3(cos(a) * (r - 0.6), 0, sin(a) * (r - 0.6))
		box(Transform3D(Basis(), foot + Vector3.UP * hl * 0.5), Vector3(0.5, hl, 0.5), "beton75", 2.0)
		col_box(Transform3D(Basis(), foot + Vector3.UP * hl * 0.5), Vector3(0.5, hl, 0.5))
		var a2: float = TAU * (k + 1) / 8.0
		var foot2: Vector3 = pos + Vector3(cos(a2) * (r - 0.6), 0, sin(a2) * (r - 0.6))
		for y in [6.0, 12.0]:
			beam(foot + Vector3.UP * y, foot2 + Vector3.UP * y, 0.3, "beton75")
	# la cuve : la fresque fait le tour
	cyl_uv(Transform3D(Basis(), pos + Vector3.UP * hl), r, r, 7.0, "fresque75_" + str(fresque_id), 32)
	disc(Transform3D(Basis(Vector3.RIGHT, PI), pos + Vector3.UP * hl), r, "beton75", 24)
	cyl(Transform3D(Basis(), pos + Vector3.UP * (hl + 7.0)), r + 0.2, 0.6, 2.2, "tolep75_gris", 24, true, 2.0)
	ring(Transform3D(Basis(), pos + Vector3.UP * (hl + 7.0)), r + 0.05, r + 0.9, 0.1, "acier75", 24)
	col_cyl(pos + Vector3.UP * hl, r, 9.2)
	# la passerelle autour du haut de la cuve (on y monte par l'échelle) : on peut y marcher
	var walk_y: float = hl + 7.0
	ring(Transform3D(Basis(), pos + Vector3.UP * (walk_y - 0.12)), r, r + 1.0, 0.12, "acier75", 24)
	for k2 in range(12):
		var a3: float = TAU * k2 / 12.0
		var c3: Vector3 = pos + Vector3(cos(a3) * (r + 0.5), walk_y - 0.06, sin(a3) * (r + 0.5))
		col_box(Transform3D(Basis(Vector3.UP, -a3), c3), Vector3(1.0, 0.12, TAU * (r + 0.5) / 12.0 + 0.2))
		box(Transform3D(Basis(), pos + Vector3(cos(a3) * (r + 0.96), walk_y + 0.5, sin(a3) * (r + 0.96))), Vector3(0.05, 1.0, 0.05), "acier75", 1.0)
	ring(Transform3D(Basis(), pos + Vector3.UP * (walk_y + 1.0)), r + 0.94, r + 1.0, 0.05, "acier75", 24)
	# l'échelle (une rampe raide qu'on gravit : des barreaux ; la collision : une pente)
	var l0: Vector3 = pos + Vector3(r + 1.4, 0, 0)
	var l1: Vector3 = pos + Vector3(r + 0.6, walk_y, 0)
	for s in [-0.3, 0.3]:
		beam(l0 + Vector3(0, 0, s), l1 + Vector3(0, 0, s), 0.05, "acier75")
	for k3 in range(int(walk_y / 0.35)):
		var q: Vector3 = l0.lerp(l1, float(k3) / int(walk_y / 0.35))
		box(Transform3D(Basis(), q), Vector3(0.05, 0.05, 0.6), "acier75", 1.0)
	return pos + Vector3.UP * walk_y


## Un cylindre dont la texture fait le tour une seule fois (u de 0 à 1) et toute la hauteur (v).
func cyl_uv(xf: Transform3D, r0: float, r1: float, h: float, key: String, seg: int = 24) -> void:
	for i in range(seg):
		var a0: float = TAU * i / seg
		var a1: float = TAU * (i + 1) / seg
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var nm: Vector3 = (xf.basis * (d0 + d1)).normalized()
		quad4(key, xf * (d0 * r0), xf * (d1 * r0), xf * (d1 * r1 + Vector3.UP * h), xf * (d0 * r1 + Vector3.UP * h), nm,
			Vector2(1.0 - float(i) / seg, 1), Vector2(1.0 - float(i + 1) / seg, 1), Vector2(1.0 - float(i + 1) / seg, 0), Vector2(1.0 - float(i) / seg, 0))


## La carcasse d'un gazomètre : un anneau de piliers en treillis d'acier, des ceintures, la poutre du
## haut ; plus de toit (c : le centre au sol, r : le rayon, h : la hauteur, n : les piliers).
func gazometre75(c: Vector3, r: float, h: float, n: int = 18) -> void:
	var tops: Array = []
	for k in range(n):
		var a: float = TAU * k / n
		var out := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-out.z, 0, out.x)
		var p: Vector3 = c + out * r
		# le pilier : deux montants et des croisillons
		for s in [-0.45, 0.45]:
			box(Transform3D(Basis.looking_at(out, Vector3.UP), p + side * s + Vector3.UP * h * 0.5), Vector3(0.28, h, 0.28), "acier75", 2.0)
		var nz: int = int(h / 2.4)
		for j in range(nz):
			var y0: float = j * h / nz
			var y1: float = (j + 1) * h / nz
			beam(p - side * 0.45 + Vector3.UP * y0, p + side * 0.45 + Vector3.UP * y1, 0.07, "acier75")
		box(Transform3D(Basis.looking_at(out, Vector3.UP), p + Vector3.UP * 1.0), Vector3(1.6, 2.0, 1.2), "beton75_sombre", 1.6)
		col_box(Transform3D(Basis.looking_at(out, Vector3.UP), p + Vector3.UP * h * 0.5), Vector3(1.3, h, 0.5))
		tops.append(p)
	# les ceintures (trois) et la couronne du haut
	for y in [h * 0.36, h * 0.7, h - 0.4]:
		for k2 in range(n):
			var a0: Vector3 = (tops[k2] as Vector3) + Vector3.UP * y
			var a1: Vector3 = (tops[(k2 + 1) % n] as Vector3) + Vector3.UP * y
			box(Transform3D(Basis.looking_at(a1 - a0, Vector3.UP), (a0 + a1) * 0.5), Vector3(0.35 if y < h - 1.0 else 0.7, 0.5 if y < h - 1.0 else 1.1, a0.distance_to(a1)), "acier75", 2.0)
			# des croix entre les piliers, en bas
			if y < h * 0.4:
				beam(a0 - Vector3.UP * y, a1, 0.08, "acier75")


# =================================================================== le cargo échoué

## La Baleine Rouillée : un vieux cargo échoué (xf : le milieu de la quille au sol ; la proue vers
## +X local, le pont à deck_y). Renvoie {"deck": hauteur du pont (monde), "gang": [bas, haut] de la
## passerelle (côté +Z), "studio": l'intérieur de la timonerie, "studio_door", "bridge"}.
func cargo75(xf: Transform3D, length: float = 62.0, beam_w: float = 11.0, deck_y: float = 6.0) -> Dictionary:
	var hw: float = beam_w * 0.5
	# le profil : [x, demi-largeur, bas de la coque]
	var prof: Array = []
	var n: int = 16
	for i in range(n + 1):
		var t: float = float(i) / n
		var x: float = -length * 0.5 + t * length
		var half: float = hw
		if t > 0.72:
			half = hw * sqrt(maxf(1.0 - pow((t - 0.72) / 0.28, 2.0), 0.0)) + 0.15
		elif t < 0.06:
			half = hw * (0.85 + 0.15 * t / 0.06)
		var bot: float = -0.8 + (1.6 if t > 0.85 else 0.0) * (t - 0.85) / 0.15 if t > 0.85 else -0.8
		prof.append([x, half, bot])
	for i in range(n):
		var a: Array = prof[i]
		var b: Array = prof[i + 1]
		for s in [-1.0, 1.0]:
			var p0 := Vector3(float(a[0]), float(a[2]), s * float(a[1]) * 0.9)
			var p1 := Vector3(float(b[0]), float(b[2]), s * float(b[1]) * 0.9)
			var p2 := Vector3(float(b[0]), deck_y + 1.0, s * float(b[1]))
			var p3 := Vector3(float(a[0]), deck_y + 1.0, s * float(a[1]))
			var nrm: Vector3 = (xf.basis * Vector3(0, 0, s)).normalized()
			var u0: float = float(a[0]) / 3.0
			var u1: float = float(b[0]) / 3.0
			if s > 0:
				quad4("coque75", xf * p0, xf * p1, xf * p2, xf * p3, nrm, Vector2(u0, (deck_y + 1.8) / 3.0), Vector2(u1, (deck_y + 1.8) / 3.0), Vector2(u1, 0), Vector2(u0, 0))
			else:
				quad4("coque75", xf * p1, xf * p0, xf * p3, xf * p2, nrm, Vector2(u1, (deck_y + 1.8) / 3.0), Vector2(u0, (deck_y + 1.8) / 3.0), Vector2(u0, 0), Vector2(u1, 0))
			# le dedans du bastingage (la tôle, vue du pont)
			var q0 := Vector3(float(a[0]), deck_y, s * (float(a[1]) - 0.12))
			var q1 := Vector3(float(b[0]), deck_y, s * (float(b[1]) - 0.12))
			if s > 0:
				quad4("tolep75_rouge", xf * q1, xf * q0, xf * p3, xf * p2, -nrm, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
			else:
				quad4("tolep75_rouge", xf * q0, xf * q1, xf * p2, xf * p3, -nrm, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
			col_box(Transform3D(Basis.looking_at(xf.basis * (p3 - p2).normalized() if (p3 - p2).length() > 0.01 else xf.basis * Vector3.RIGHT, xf.basis * Vector3.UP), xf * ((p2 + p3) * 0.5 - Vector3(0, 0.6, 0))), Vector3(0.3, 1.4, (p2 - p3).length()))
		# le pont (un plancher par tranche) ; dessous, la coque est pleine (collision)
		var cx: float = (float(a[0]) + float(b[0])) * 0.5
		var half_min: float = minf(float(a[1]), float(b[1]))
		box(xf * T(cx, deck_y - 0.1, 0), Vector3(float(b[0]) - float(a[0]), 0.2, half_min * 2.0 - 0.2), "rivete75_gris", 2.0, 4)
		col_box(xf * T(cx, deck_y * 0.5 - 0.1, 0), Vector3(float(b[0]) - float(a[0]), deck_y, half_min * 2.0 - 0.3))
		walk_boxes.append([(xf * T(cx, deck_y, 0)).affine_inverse(), Vector3((float(b[0]) - float(a[0])) * 0.5, 4.0, half_min - 0.1)])
	# la poupe (un mur plat), le pont de la proue
	var sx0: float = -length * 0.5
	box(xf * T(sx0 - 0.05, (deck_y + 0.2) * 0.5, 0), Vector3(0.12, deck_y + 2.0, hw * 1.8), "coque75", 2.5)
	# les panneaux de cale (trois), un conteneur-cabine, des bittes
	for k in range(3):
		var hx: float = -2.0 + k * 9.0
		box(xf * T(hx, deck_y + 0.6, 0), Vector3(7.0, 1.2, hw * 1.2), "tolep75_vert", 1.6)
		col_box(xf * T(hx, deck_y + 0.6, 0), Vector3(7.0, 1.2, hw * 1.2))
	conteneur75(xf * Transform3D(Basis(), Vector3(4.0, deck_y + 1.2, 0)), "bleu", {"len": 6.0, "home": true})
	for k2 in range(4):
		place("bitte75", xf * T(-20.0 + k2 * 12.0, deck_y, hw - 0.9))
	# le château arrière : trois niveaux, la timonerie au sommet (le studio de la radio)
	var sx: float = -length * 0.5 + 6.0
	var levels: int = 3
	for lv in range(levels):
		var y0: float = deck_y + lv * 2.8
		var ww: float = 9.0 - lv * 1.2
		box(xf * T(sx, y0 + 1.4, 0), Vector3(8.0 - lv * 0.8, 2.8, ww), "tolep75_blanc", 1.6, 63 - 8 - (4 if lv < levels - 1 else 0))
		col_box(xf * T(sx, y0 + 1.4, 0), Vector3(8.0 - lv * 0.8, 2.8, ww))
		for k3 in range(4):
			var zz: float = -ww * 0.5 + ww * (k3 + 0.5) / 4.0
			box(xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(sx + (8.0 - lv * 0.8) * 0.5 + 0.01, y0 + 1.6, zz)), Vector3(0.6, 0.6, 0.02), "vitre75_on" if (k3 + lv) % 2 == 0 else "vitre75_off", 1.0)
	# la timonerie : une pièce creuse (on y entre par une porte à l'arrière, depuis une passerelle)
	var ty: float = deck_y + levels * 2.8
	var tx: Transform3D = xf * T(sx, ty, 0)
	box(tx * T(0, -0.05, 0), Vector3(6.2, 0.1, 6.0), "bardage75", 2.0, 4)
	col_box(tx * T(0, -0.1, 0), Vector3(6.4, 0.2, 6.2))
	for s2 in [-1.0, 1.0]:
		box(tx * T(0, 1.3, s2 * 3.0), Vector3(6.2, 2.6, 0.12), "tolep75_blanc", 1.6)
		col_box(tx * T(0, 1.3, s2 * 3.0), Vector3(6.2, 2.6, 0.12))
		box(tx * T(0.5, 1.6, s2 * 3.07), Vector3(4.0, 0.9, 0.02), "vitre75_on", 1.0)
	box(tx * T(3.1, 1.3, 0), Vector3(0.12, 2.6, 6.0), "tolep75_blanc", 1.6)
	col_box(tx * T(3.1, 1.3, 0), Vector3(0.12, 2.6, 6.0))
	box(tx * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(3.17, 1.7, 0)), Vector3(5.0, 1.1, 0.02), "vitre75_on", 1.0)
	_wall_piece(tx * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-3.1, 0, 0)), -3.0, -0.6, 0.0, 2.6, 0.12, "tolep75_blanc", "tolep75_blanc")
	_wall_piece(tx * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-3.1, 0, 0)), -0.6, 0.6, 2.1, 2.6, 0.12, "tolep75_blanc", "tolep75_blanc")
	_wall_piece(tx * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-3.1, 0, 0)), 0.6, 3.0, 0.0, 2.6, 0.12, "tolep75_blanc", "tolep75_blanc")
	box(tx * T(0, 2.66, 0), Vector3(6.6, 0.14, 6.4), "tolep75_gris", 2.0)
	walk_boxes.append([(tx).affine_inverse(), Vector3(3.0, 3.0, 2.9)])
	# la passerelle de l'arrière (on y monte du pont par un escalier extérieur, le long du château)
	var st_bot: Vector3 = xf * Vector3(sx - 1.0, deck_y, hw - 1.6)
	var st_top: Vector3 = xf * Vector3(sx - 6.0, ty, hw - 1.6)
	stair(st_bot, st_top, 1.0, "acier75", "acier75", 0.9, 0.06)
	var land: Vector3 = xf * Vector3(sx - 4.4, ty - 0.1, 0.4)
	box(Transform3D(xf.basis, land), Vector3(2.6, 0.2, hw * 2.0 - 2.4), "acier75", 1.0)
	col_box(Transform3D(xf.basis, land), Vector3(2.6, 0.2, hw * 2.0 - 2.4))
	walk_boxes.append([(Transform3D(xf.basis, land + Vector3.UP * 0.1)).affine_inverse(), Vector3(1.3, 3.0, hw - 1.2)])
	# le mât et l'antenne de Radio Boucan, la cheminée du navire
	var mast: Vector3 = xf * Vector3(sx + 6.0, deck_y, 0)
	cyl(Transform3D(Basis(), mast), 0.25, 0.15, 16.0, "tolep75_blanc", 10, false)
	box(Transform3D(xf.basis, mast + Vector3.UP * 12.0), Vector3(0.12, 0.12, 6.0), "tolep75_blanc", 1.0)
	cyl(Transform3D(Basis(), xf * Vector3(sx - 2.0, ty + 2.7, 0)), 1.1, 1.0, 4.0, "tolep75_noir", 14, true, 2.0)
	ring(Transform3D(Basis(), xf * Vector3(sx - 2.0, ty + 5.0, 0)), 1.0, 1.06, 0.8, "tolep75_rouge", 14)
	# la grande passerelle d'embarquement : de la plage (+Z) au pont
	var g_bot: Vector3 = xf * Vector3(10.0, 0.0, hw + 9.0)
	var g_top: Vector3 = xf * Vector3(10.0, deck_y, hw - 0.2)
	g_bot.y = 0.0
	return {"deck": (xf * Vector3(0, deck_y, 0)).y, "gang": [g_bot, g_top], "studio": tx * Vector3(0.6, 0.05, 0.0), "studio_door": tx * Vector3(-4.2, 0.05, 0.0),
		"bridge_top": st_top, "bridge_bot": st_bot, "mast": mast + Vector3.UP * 16.0, "pont": xf * Vector3(8.0, deck_y, 0)}


# =================================================================== rails, épaves, clôtures, lumières

## Une voie ferrée de a à b (au sol) : deux rails, des traverses.
func rails75(a: Vector3, b: Vector3) -> void:
	var d: Vector3 = b - a
	var len: float = Vector2(d.x, d.z).length()
	var bs := Basis(Vector3.UP, atan2(d.x, d.z))
	for s in [-0.72, 0.72]:
		var off: Vector3 = bs * Vector3(s, 0, 0)
		box(Transform3D(bs, (a + b) * 0.5 + off + Vector3.UP * 0.2), Vector3(0.08, 0.14, len), "acier75", 1.0)
	var n: int = int(len / 0.75)
	for i in range(n):
		place("traverse75", Transform3D(bs * Basis(Vector3.UP, PI * 0.5), a.lerp(b, (i + 0.5) / n)))


## Un wagon couvert rouillé (xf : le milieu, la longueur le long de Z).
func wagon75(xf: Transform3D, color: String = "rouge") -> void:
	box(xf * T(0, 2.4, 0), Vector3(2.8, 2.8, 12.0), "tolep75_" + color, 1.2)
	box(xf * T(0, 3.85, 0), Vector3(3.0, 0.1, 12.2), "tole75", 1.6)
	box(xf * T(1.42, 2.3, 0), Vector3(0.04, 2.4, 3.0), "acier75", 1.0)
	box(xf * T(0, 0.85, 0), Vector3(2.0, 0.3, 12.0), "acier75", 1.0)
	for z in [-4.5, -3.0, 3.0, 4.5]:
		for s in [-0.72, 0.72]:
			cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(s, 0.48, z)), 0.45, 0.45, 0.12, "acier75", 12)
	col_box(xf * T(0, 2.0, 0), Vector3(3.0, 4.0, 12.2))


## Une épave de voiture (xf : au sol, le capot vers +Z).
func voiture75(xf: Transform3D, color: String = "rouge", rusty: bool = true) -> void:
	var key: String = "tolep75_" + color if not rusty else "acier75"
	box(xf * T(0, 0.65, 0), Vector3(1.75, 0.6, 4.2), key, 1.2)
	frustum(xf * T(0, 0.95, -0.35), 1.6, 2.1, 1.3, 1.6, 0.6, key if not rusty else "tolep75_" + color, 1.2)
	box(xf * T(0, 1.25, 0.66), Vector3(1.3, 0.45, 0.04), "vitre75_off", 1.0)
	for s in [-0.82, 0.82]:
		for z in [-1.3, 1.3]:
			if rng.randf() < 0.75:
				place("pneu75", xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(s, 0.34, z)))
	col_box(xf * T(0, 0.8, 0), Vector3(1.8, 1.6, 4.2))


## Un grillage (de a à b, au sol) : des poteaux, le treillis.
func grillage75(a: Vector3, b: Vector3, h: float = 2.2) -> void:
	var d: Vector3 = b - a
	var len: float = Vector2(d.x, d.z).length()
	if len < 0.1:
		return
	var bs := Basis(Vector3.UP, atan2(d.x, d.z))
	var n: int = maxi(int(len / 2.6), 1)
	for i in range(n + 1):
		var p: Vector3 = a.lerp(b, float(i) / n)
		cyl(Transform3D(Basis(), p), 0.04, 0.04, h + 0.1, "metal75_gris", 6, false)
	var mid: Vector3 = (a + b) * 0.5
	quad(Transform3D(bs * Basis(Vector3.UP, PI * 0.5), mid + Vector3.UP * h * 0.5), len, h, "grillage75", Vector2(0, 0), Vector2(len / 0.5, h / 0.5), true)
	col_box(Transform3D(bs, mid + Vector3.UP * h * 0.5), Vector3(0.08, h, len))


## Une guirlande d'ampoules de a à b (une chaînette qui pend de « sag » mètres).
func guirlande75(a: Vector3, b: Vector3, sag: float = 0.8, step: float = 0.7) -> void:
	var len: float = a.distance_to(b)
	var n: int = maxi(int(len / step), 2)
	var prev: Vector3 = a
	for i in range(1, n + 1):
		var t: float = float(i) / n
		var p: Vector3 = a.lerp(b, t) + Vector3.DOWN * sag * 4.0 * t * (1.0 - t)
		beam(prev, p, 0.012, "metal75_noir")
		if i < n:
			place("ampoule75", Transform3D(Basis(), p + Vector3.DOWN * 0.08))
		prev = p


## Un lampadaire de quai (une vraie lumière une fois sur light_every).
func lampadaire75(pos: Vector3, yaw: float) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw), pos)
	place("lampadaire75", xf)
	col_cyl(pos, 0.15, 7.0)
	var light_here: bool = lamps70.size() % maxi(light_every, 1) == 0
	_lamp_light(xf * Vector3(1.2, 6.6, 0), 2.2, 16.0, light_here)


# =================================================================== mobilier de récup

func palette75(xf: Transform3D) -> void:
	place("palette75", xf)


## Une pile de palettes (n), un peu de travers.
func pile_palettes75(pos: Vector3, n: int, yaw: float = 0.0) -> void:
	for i in range(n):
		place("palette75", Transform3D(Basis(Vector3.UP, yaw + (rng.randf() - 0.5) * 0.12), pos + Vector3.UP * i * 0.145))
	col_box(Transform3D(Basis(Vector3.UP, yaw), pos + Vector3.UP * n * 0.07), Vector3(1.2, n * 0.145, 0.8))


## Un canapé en palettes et coussins (xf : le milieu, le dossier vers -Z). Renvoie la place assise.
func canape75(xf: Transform3D, color: String = "rouge") -> Vector3:
	for k in range(2):
		place("palette75", xf * Transform3D(Basis(), Vector3(-0.62 + k * 1.24, 0.0, 0)))
		place("palette75", xf * Transform3D(Basis(), Vector3(-0.62 + k * 1.24, 0.145, 0)))
		place("palette75", xf * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5 + 0.18), Vector3(-0.62 + k * 1.24, 0.3, -0.42)))
	box(xf * T(0, 0.38, 0.02), Vector3(2.3, 0.16, 0.72), "tissu75_" + color, 1.0)
	box(xf * T(0, 0.7, -0.3), Vector3(2.3, 0.5, 0.18), "tissu75_" + color, 1.0)
	col_box(xf * T(0, 0.3, -0.1), Vector3(2.5, 0.6, 1.0))
	return xf * Vector3(0, 0.45, 0.1)


## Une table en bobine de câble (une grosse bobine de bois couchée) ; renvoie le centre.
func table_bobine75(pos: Vector3) -> Vector3:
	cyl(Transform3D(Basis(), pos), 0.7, 0.7, 0.06, "palette75", 16)
	cyl(Transform3D(Basis(), pos + Vector3.UP * 0.06), 0.28, 0.28, 0.62, "palette75", 10, false)
	cyl(Transform3D(Basis(), pos + Vector3.UP * 0.68), 0.75, 0.75, 0.07, "palette75", 16)
	col_cyl(pos, 0.75, 0.75)
	return pos + Vector3.UP * 0.75


## La fontaine-baignoire de la Place des Palettes (une baignoire sur pieds, un robinet qui coule).
func baignoire75(xf: Transform3D) -> Vector3:
	box(xf * T(0, 0.75, 0), Vector3(1.7, 0.6, 0.8), "peint75_blanc", 1.0)
	box(xf * T(0, 0.66, 0), Vector3(1.5, 0.4, 0.62), "eau71", 1.0, 4)
	for sx in [-0.7, 0.7]:
		for sz in [-0.3, 0.3]:
			cyl(xf * T(sx, 0.0, sz), 0.05, 0.08, 0.45, "chrome75", 6)
	cyl(xf * T(-0.85, 1.05, 0), 0.04, 0.04, 0.6, "chrome75", 6, false)
	col_box(xf * T(0, 0.6, 0), Vector3(1.8, 1.2, 0.9))
	return xf * Vector3(-0.85, 1.5, 0)


func baril75(pos: Vector3, color: String = "") -> void:
	place("baril75|" + (color if color != "" else ["bleu", "rouge", "vert", "jaune", "noir"][rng.randi() % 5]), Transform3D(Basis(Vector3.UP, rng.randf() * TAU), pos))
	col_cyl(pos, 0.3, 0.9)


func pneus75(pos: Vector3, n: int = 3) -> void:
	for i in range(n):
		place("pneu75", Transform3D(Basis(Vector3.UP, rng.randf() * TAU), pos + Vector3.UP * (0.11 + i * 0.22)))
	col_cyl(pos, 0.38, n * 0.22)


# =================================================================== le skatepark, les jardins

## Un quart de lune (xf : le bas de la courbe, le skateur arrive par +Z ; la courbe monte vers -Z).
func quarter75(xf: Transform3D, w: float, r: float) -> void:
	var segs: int = 8
	for i in range(segs):
		var a0: float = PI * 0.5 * i / segs
		var a1: float = PI * 0.5 * (i + 1) / segs
		var p0 := Vector3(0, r - cos(a0) * r, -sin(a0) * r)
		var p1 := Vector3(0, r - cos(a1) * r, -sin(a1) * r)
		var mid: Vector3 = (p0 + p1) * 0.5
		var bs := Basis(Vector3.RIGHT, -(a0 + a1) * 0.5)
		box(xf * Transform3D(bs, mid), Vector3(w, 0.08, p0.distance_to(p1) + 0.02), "betonsol75", 2.0)
		col_box(xf * Transform3D(bs, mid + bs * Vector3(0, -0.06, 0)), Vector3(w, 0.12, p0.distance_to(p1) + 0.02))
	box(xf * T(0, r * 0.5, -r - 0.4), Vector3(w, r, 0.8), "beton75", 2.0)
	box(xf * T(0, r + 0.02, -r - 0.4), Vector3(w, 0.06, 0.8), "betonsol75", 2.0)
	box(xf * T(0, r + 0.04, -r + 0.02), Vector3(w, 0.06, 0.06), "acier75", 1.0)
	col_box(xf * T(0, r * 0.5, -r - 0.4), Vector3(w, r, 0.8))


func funbox75(xf: Transform3D, w: float = 4.0, d: float = 3.0, h: float = 0.7) -> void:
	box(xf * T(0, h * 0.5, 0), Vector3(w, h, d), "beton75", 2.0)
	col_box(xf * T(0, h * 0.5, 0), Vector3(w, h, d))
	for s in [-1.0, 1.0]:
		var a := xf * Vector3(s * w * 0.5, h, 0)
		var b := xf * Vector3(s * (w * 0.5 + 2.2), 0.0, 0)
		var bs: Basis = xf.basis * Basis(Vector3.UP, PI * 0.5)
		var dd: Vector3 = b - a
		var ang: float = atan2(h, 2.2)
		box(Transform3D(bs * Basis(Vector3.RIGHT, -ang * s * -1.0), (a + b) * 0.5), Vector3(d, 0.08, dd.length()), "betonsol75", 2.0)
		col_box(Transform3D(bs * Basis(Vector3.RIGHT, ang * s), (a + b) * 0.5), Vector3(d, 0.1, dd.length()))
	box(xf * T(0, h + 0.03, 0), Vector3(0.08, 0.06, d), "acier75", 1.0)


## Un bac de potager (xf : le centre) : des planches, de la terre, des légumes en rangs.
func bac75(xf: Transform3D, w: float = 3.0, d: float = 1.2) -> void:
	box(xf * T(0, 0.25, 0), Vector3(w, 0.5, d), "palette75", 1.0, 63 - 4)
	box(xf * T(0, 0.48, 0), Vector3(w - 0.1, 0.04, d - 0.1), "terre75", 1.0, 4)
	var n: int = int(w / 0.4)
	for i in range(n):
		for j in range(2):
			var p: Vector3 = xf * Vector3(-w * 0.5 + 0.25 + i * 0.4, 0.55, -d * 0.25 + j * d * 0.5)
			ball(Transform3D(Basis(), p), 0.13 + rng.randf() * 0.06, "feuille75", 6, 3)
			if rng.randf() < 0.3:
				ball(Transform3D(Basis(), p + Vector3(0.05, 0.12, 0)), 0.06, "tissu75_rouge", 6, 3)
	col_box(xf * T(0, 0.25, 0), Vector3(w, 0.5, d))


## Une serre en fenêtres de récup (xf : le milieu de l'entrée, la serre s'étend vers -Z).
func serre75(xf: Transform3D, w: float = 5.0, d: float = 7.0) -> Vector3:
	var h: float = 2.6
	for s in [-1.0, 1.0]:
		quad(xf * Transform3D(Basis(Vector3.UP, s * PI * 0.5), Vector3(s * w * 0.5, h * 0.5, -d * 0.5)), d, h, "vitre75_usine", Vector2(0, 0), Vector2(1, 1), true)
		col_box(xf * T(s * w * 0.5, h * 0.5, -d * 0.5), Vector3(0.1, h, d))
	quad(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, h * 0.5, -d)), w, h, "vitre75_usine", Vector2(0, 0), Vector2(1, 1), true)
	col_box(xf * T(0, h * 0.5, -d), Vector3(w, h, 0.1))
	for s2 in [-1.0, 1.0]:
		quad(xf * Transform3D(Basis(Vector3.UP, s2 * PI * 0.5) * Basis(Vector3.RIGHT, 0.0) * Basis(Vector3.FORWARD, s2 * 0.5), Vector3(s2 * w * 0.25, h + 0.6, -d * 0.5)), d, w * 0.56, "vitre75_usine", Vector2(0, 0), Vector2(1, 1), true)
	for k in range(int(d / 1.2) + 1):
		var z: float = -k * 1.2
		for s3 in [-1.0, 1.0]:
			box(xf * T(s3 * w * 0.5, h * 0.5, z), Vector3(0.08, h, 0.08), "peint75_blanc", 1.0)
		beam(xf * Vector3(-w * 0.5, h, z), xf * Vector3(0, h + 1.2, z), 0.06, "peint75_blanc")
		beam(xf * Vector3(w * 0.5, h, z), xf * Vector3(0, h + 1.2, z), 0.06, "peint75_blanc")
	for k2 in range(2):
		bac75(xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-w * 0.25 + k2 * w * 0.5, 0, -d * 0.5)), d - 1.6, 1.0)
	return xf * Vector3(0, 0, -1.0)


func ruche75(pos: Vector3, yaw: float = 0.0) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw), pos)
	for k in range(3):
		box(xf * T(0, 0.45 + k * 0.26, 0), Vector3(0.5, 0.24, 0.44), "peint75_" + ["jaune", "bleu", "blanc"][k], 1.0)
	box(xf * T(0, 1.24, 0), Vector3(0.58, 0.06, 0.52), "tolep75_gris", 1.0)
	for s in [-0.2, 0.2]:
		box(xf * T(s, 0.17, 0), Vector3(0.06, 0.34, 0.4), "palette75", 1.0)
	col_box(xf * T(0, 0.6, 0), Vector3(0.6, 1.2, 0.5))


# =================================================================== la musique

## Une scène (xf : le bord avant au milieu, la scène s'étend vers -Z), haute de h. Renvoie les
## places des musiciens {chant, guitare, basse, batterie}.
func scene75(xf: Transform3D, w: float, d: float, h: float = 1.1) -> Dictionary:
	box(xf * T(0, h * 0.5, -d * 0.5), Vector3(w, h, d), "palette75", 1.4, 63 - 8)
	box(xf * T(0, h + 0.01, -d * 0.5), Vector3(w, 0.02, d), "caoutchouc75", 2.0, 4)
	col_box(xf * T(0, h * 0.5, -d * 0.5), Vector3(w, h, d))
	walk_boxes.append([(xf * T(0, h, -d * 0.5)).affine_inverse(), Vector3(w * 0.5, 3.0, d * 0.5)])
	# un petit escalier sur le côté
	stair(xf * Vector3(w * 0.5 + 1.6, 0.0, -d * 0.7), xf * Vector3(w * 0.5 - 0.2, h, -d * 0.7), 1.0, "palette75")
	# les retours de scène, les amplis, la batterie (sur un praticable)
	for s in [-1.0, 1.0]:
		var wedge: Transform3D = xf * Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3(s * w * 0.18, h + 0.18, -0.4))
		box(wedge, Vector3(0.7, 0.35, 0.45), "caoutchouc75", 1.0)
		ampli75(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(s * w * 0.38, h, -d + 1.2)))
	var riser: Transform3D = xf * T(0, h, -d + 2.0)
	box(riser * T(0, 0.25, 0), Vector3(3.2, 0.5, 2.4), "palette75", 1.0)
	col_box(riser * T(0, 0.25, 0), Vector3(3.2, 0.5, 2.4))
	batterie75(riser * T(0, 0.5, 0.2))
	# le pied de micro
	var mic: Vector3 = xf * Vector3(0, h, -1.2)
	cyl(Transform3D(Basis(), mic), 0.18, 0.18, 0.03, "metal75_noir", 10)
	cyl(Transform3D(Basis(), mic), 0.012, 0.012, 1.55, "metal75_noir", 4, false)
	ball(Transform3D(Basis(), mic + Vector3.UP * 1.6), 0.05, "metal75_noir", 6, 3)
	# le portique d'éclairage (une poutre en treillis) et ses projecteurs
	for s2 in [-1.0, 1.0]:
		box(xf * T(s2 * (w * 0.5 - 0.3), h + 2.6, -0.5), Vector3(0.3, 5.2, 0.3), "metal75_noir", 1.0)
	box(xf * T(0, h + 5.2, -0.5), Vector3(w, 0.3, 0.3), "metal75_noir", 1.0)
	return {"chant": xf * Vector3(0, h, -1.6), "guitare": xf * Vector3(-w * 0.28, h, -2.4), "basse": xf * Vector3(w * 0.28, h, -2.4),
		"batterie": riser * Vector3(0, 0.5, -0.7), "portique": xf * Vector3(0, h + 5.0, -0.5)}


## Un ampli (une tête sur deux baffles ; xf : le devant au sol, il regarde +Z).
func ampli75(xf: Transform3D) -> void:
	for k in range(2):
		box(xf * T(0, 0.38 + k * 0.76, -0.2), Vector3(0.76, 0.74, 0.4), "caoutchouc75", 1.0)
		box(xf * T(0, 0.38 + k * 0.76, 0.005), Vector3(0.66, 0.64, 0.01), "tissu75_noir", 1.0)
	box(xf * T(0, 1.68, -0.2), Vector3(0.76, 0.3, 0.38), "caoutchouc75", 1.0)
	box(xf * T(0, 1.68, 0.0), Vector3(0.6, 0.06, 0.01), "chrome75", 1.0)
	col_box(xf * T(0, 0.9, -0.2), Vector3(0.8, 1.8, 0.42))


## Une batterie (grosse caisse, caisse claire, toms, cymbales) ; xf : le centre au sol, le
## batteur derrière (-Z).
func batterie75(xf: Transform3D) -> void:
	cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.3, 0.2)), 0.3, 0.3, 0.42, "tolep75_rouge", 16, true, 1.0)
	disc(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.3, 0.2)), 0.29, "peint75_blanc", 16)
	cyl(xf * T(-0.45, 0.55, -0.15), 0.18, 0.18, 0.14, "chrome75", 12)
	for s in [-0.2, 0.2]:
		cyl(xf * Transform3D(Basis(Vector3.RIGHT, 0.3), Vector3(s, 0.72, 0.15)), 0.13, 0.13, 0.16, "tolep75_rouge", 12)
	cyl(xf * T(0.5, 0.35, -0.1), 0.22, 0.22, 0.4, "tolep75_rouge", 12)
	for c in [[-0.65, 1.15, 0.0], [0.6, 1.25, 0.15], [-0.4, 1.0, -0.3]]:
		var p: Vector3 = xf * Vector3(float(c[0]), float(c[1]), float(c[2]))
		cyl(Transform3D(Basis(), xf * Vector3(float(c[0]), 0.0, float(c[2]))), 0.012, 0.012, float(c[1]), "chrome75", 4, false)
		cyl(Transform3D(Basis(Vector3.RIGHT, 0.1), p), 0.32, 0.02, 0.03, "laiton71", 16)
	col_box(xf * T(0, 0.5, 0), Vector3(1.6, 1.0, 1.0))


## Un projecteur de scène (une boîte noire, une lentille qui luit) et sa lumière colorée.
func projecteur75(at: Vector3, aim: Vector3, c: Color, energy: float = 4.0, with_light: bool = true) -> Light3D:
	var xf := Transform3D(Basis.looking_at(aim - at, Vector3.UP), at)
	box(xf * T(0, 0, 0), Vector3(0.3, 0.3, 0.42), "caoutchouc75", 1.0)
	disc(xf * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, 0, -0.22)), 0.12, "lampe75", 10)
	if not with_light:
		return null
	var l := SpotLight3D.new()
	l.light_color = c
	l.light_energy = energy
	l.spot_range = at.distance_to(aim) * 1.6
	l.spot_angle = 24.0
	l.spot_attenuation = 0.8
	l.shadow_enabled = false
	l.light_volumetric_fog_energy = 2.0
	l.distance_fade_enabled = true
	l.distance_fade_begin = 60.0
	l.distance_fade_length = 15.0
	root.add_child(l)
	l.global_transform = xf
	spot_lights.append(l)
	return l


# =================================================================== le phare, les champignons géants

## Le Phare Tagué (pos : le pied) : une tour ronde couverte de graffitis, la lanterne, le balcon.
func phare75(pos: Vector3) -> Vector3:
	var h: float = 18.0
	cyl(Transform3D(Basis(), pos), 3.2, 2.4, h, "briquep75_blanc", 20, false, 2.0)
	for k in range(4):
		var a: float = TAU * k / 4.0 + 0.3
		var out := Vector3(cos(a), 0, sin(a))
		var fx := Transform3D(Basis.looking_at(-out, Vector3.UP), pos + out * (3.25 - k * 0.1) + Vector3.UP * (2.4 + k * 3.6))
		quadz(fx, 3.0, 1.6, "graffiti75_" + str([1, 4, 7, 10][k]))
	ring(Transform3D(Basis(), pos + Vector3.UP * h), 2.0, 3.2, 0.25, "metal75_noir", 20)
	cyl(Transform3D(Basis(), pos + Vector3.UP * (h + 0.25)), 1.7, 1.7, 2.2, "vitre75_on", 12, false)
	cyl(Transform3D(Basis(), pos + Vector3.UP * (h + 2.45)), 1.9, 0.2, 1.4, "tolep75_rouge", 12)
	col_cyl(pos, 3.2, h + 3.5)
	return pos + Vector3.UP * (h + 1.4)


## Un champignon géant lumineux (pos : le pied ; h : la hauteur ; r : le rayon du chapeau ;
## couleur : bleu, violet, orange ; lean : penché de quelques degrés). Renvoie le dessous du chapeau.
func champi75(pos: Vector3, h: float, r: float, couleur: String, lean: float = 0.0, yaw: float = 0.0) -> Vector3:
	var bs := Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, deg_to_rad(lean))
	var sr: float = maxf(r * 0.16, 0.12)
	# le pied : un peu renflé à la base, une collerette
	cyl(Transform3D(bs, pos + Vector3.DOWN * 0.3), sr * 1.6, sr * 1.1, h * 0.25 + 0.3, "pied75", 14, false, 1.2)
	cyl(Transform3D(bs, pos + bs * Vector3(0, h * 0.25, 0)), sr * 1.1, sr * 0.9, h * 0.75, "pied75", 14, false, 1.2)
	var top: Vector3 = pos + bs * Vector3(0, h, 0)
	ring(Transform3D(bs, pos + bs * Vector3(0, h * 0.7, 0)), sr * 0.9, sr * 1.8, 0.12, "lamelles75_" + couleur, 14)
	# le chapeau : un dôme aplati ; dessous, les lamelles
	var cap := Transform3D(bs * Basis.from_scale(Vector3(1.0, 0.42, 1.0)), top)
	_dome(cap, r, "chapeau75_" + couleur, 18, 6)
	disc(Transform3D(bs * Basis(Vector3.RIGHT, PI), top + bs * Vector3(0, 0.02, 0)), r * 0.98, "lamelles75_" + couleur, 18, r)
	col_cyl(pos, sr * 1.3, h)
	if r > 2.2:
		col_box(Transform3D(bs, top + bs * Vector3(0, r * 0.2, 0)), Vector3(r * 1.3, r * 0.36, r * 1.3))
	return top


## Une demi-sphère (le haut) : un dôme posé sur xf.
func _dome(xf: Transform3D, r: float, key: String, seg: int, rings: int) -> void:
	for j in range(rings):
		var b0: float = PI * 0.5 * j / rings
		var b1: float = PI * 0.5 * (j + 1) / rings
		for i in range(seg):
			var a0: float = TAU * i / seg
			var a1: float = TAU * (i + 1) / seg
			var p00 := Vector3(cos(a0) * cos(b0), sin(b0), sin(a0) * cos(b0)) * r
			var p10 := Vector3(cos(a1) * cos(b0), sin(b0), sin(a1) * cos(b0)) * r
			var p11 := Vector3(cos(a1) * cos(b1), sin(b1), sin(a1) * cos(b1)) * r
			var p01 := Vector3(cos(a0) * cos(b1), sin(b1), sin(a0) * cos(b1)) * r
			var nm: Vector3 = (xf.basis.inverse().transposed() * (p00 + p11).normalized()).normalized()
			var u0: float = float(i) / seg * 3.0
			var u1: float = float(i + 1) / seg * 3.0
			quad4(key, xf * p00, xf * p10, xf * p11, xf * p01, nm, Vector2(u0, 1.0 - float(j) / rings), Vector2(u1, 1.0 - float(j) / rings), Vector2(u1, 1.0 - float(j + 1) / rings), Vector2(u0, 1.0 - float(j + 1) / rings))
