extends "res://scripts/carene_kit_v59.gd"
## V61 : la boîte à outils de Cliquetis, la cité des ingénieurs fous — celle de Carène et de
## Port-Azur, plus les matériaux de la cité (cuivre riveté et patiné, laiton martelé, fonte
## striée, brique d'usine, ardoise, verrières) et ses formes : engrenages, tuyaux, dômes,
## cheminées d'usine, fenêtres à petits carreaux en arc, ateliers à verrière, tours rondes,
## bobines de Tesla, réverbères à globe.

const CQ := "res://assets/textures/cliquetis/"


func mat(key: String) -> Material:
	if mats.has(key):
		return mats[key]
	var m: StandardMaterial3D = null
	match key:
		"cuivre", "cuivre_sombre":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(CQ + "cuivre.png")
			m.normal_enabled = true
			m.normal_texture = load(CQ + "cuivre_n.png")
			m.metallic = 0.55
			m.roughness = 0.45
			m.albedo_color = Color(1, 1, 1) if key == "cuivre" else Color(0.7, 0.62, 0.58)
		"cuivre_poli":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.86, 0.5, 0.32)
			m.metallic = 0.9
			m.roughness = 0.25
		"laiton":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(CQ + "laiton.png")
			m.normal_enabled = true
			m.normal_texture = load(CQ + "laiton_n.png")
			m.metallic = 0.8
			m.roughness = 0.3
		"fonte":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(CQ + "fonte.png")
			m.normal_enabled = true
			m.normal_texture = load(CQ + "fonte_n.png")
			m.metallic = 0.5
			m.roughness = 0.6
		"brique", "brique_sombre":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(CQ + "brique.png")
			m.normal_enabled = true
			m.normal_texture = load(CQ + "brique_n.png")
			m.roughness = 0.92
			m.albedo_color = Color(1, 1, 1) if key == "brique" else Color(0.66, 0.6, 0.58)
		"ardoise":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(CQ + "ardoise.png")
			m.normal_enabled = true
			m.normal_texture = load(CQ + "ardoise_n.png")
			m.roughness = 0.88
			m.metallic_specular = 0.25
		"verriere":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(CQ + "verriere.png")
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.roughness = 0.08
			m.metallic_specular = 0.9
		"vitre_lumiere":
			# les fenêtres des ateliers : on y travaille tard, elles s'allument le soir
			m = StandardMaterial3D.new()
			m.albedo_texture = load(CQ + "verriere.png")
			m.albedo_color = Color(0.5, 0.5, 0.45)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.76, 0.42)
			m.emission_energy_multiplier = 0.0
			if temps != null:
				temps.register_glow(m, 1.6, 0.0)
		"acier":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.56, 0.58, 0.6)
			m.metallic = 0.85
			m.roughness = 0.35
		"fer_noir":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.09, 0.09, 0.1)
			m.metallic = 0.6
			m.roughness = 0.5
		"cadran":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(CQ + "cadran.png")
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.5
			m.roughness = 0.6
			m.emission_enabled = true
			m.emission = Color(1.0, 0.85, 0.6)
			m.emission_energy_multiplier = 0.0
			m.emission_texture = load(CQ + "cadran.png")
			if temps != null:
				temps.register_glow(m, 0.6, 0.0)
		"tesla":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.6, 0.85, 1.0)
			m.emission_enabled = true
			m.emission = Color(0.45, 0.75, 1.0)
			m.emission_energy_multiplier = 1.2
			m.metallic = 0.7
			m.roughness = 0.2
		"globe":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(1.0, 0.96, 0.86, 0.8)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.emission_enabled = true
			m.emission = Color(1.0, 0.86, 0.6)
			m.emission_energy_multiplier = 0.3
			if temps != null:
				temps.register_glow(m, 5.0, 0.3)
		"caoutchouc":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.06, 0.06, 0.06)
			m.roughness = 0.9
	if m == null and key == "talus_cq":
		m = (super.mat("moellons") as StandardMaterial3D).duplicate()
		m.albedo_color = Color(0.62, 0.56, 0.5)
	if m == null and (key == "dalles_cq" or key == "paves_cq"):
		# le pavage de la cité : basalte sombre et pavés roussis par la suie
		m = (super.mat(key.trim_suffix("_cq")) as StandardMaterial3D).duplicate()
		m.albedo_color = Color(0.5, 0.48, 0.46) if key == "dalles_cq" else Color(0.62, 0.52, 0.44)
		m.roughness = 0.78
	if m == null and key.begins_with("affiche_"):
		m = StandardMaterial3D.new()
		m.albedo_texture = load(CQ + key + ".png")
		m.roughness = 0.85
	if m == null:
		return super.mat(key)
	mats[key] = m
	return m


# =================================================================== formes

## Un repère dont l'axe Y local suit a -> b (pour poser un cylindre entre deux points).
func axis_xf(a: Vector3, b: Vector3) -> Transform3D:
	var y: Vector3 = (b - a).normalized()
	var ref: Vector3 = Vector3.RIGHT if absf(y.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Transform3D(Basis(x, y, z), a)


## Un tuyau entre deux points, avec ses brides aux deux bouts.
func pipe(a: Vector3, b: Vector3, r: float, key: String = "cuivre_poli", flanges: bool = true) -> void:
	var xf: Transform3D = axis_xf(a, b)
	var L: float = a.distance_to(b)
	cyl(xf, r, r, L, key, 10, false, 1.0)
	if flanges:
		for t in [0.0, L - 0.08]:
			cyl(xf * Transform3D(Basis(), Vector3(0, t, 0)), r * 1.45, r * 1.45, 0.08, "laiton", 10)


## Engrenage plat (dans le plan XZ local), à plat ou dressé selon xf, ajouré de rayons.
func gear(xf: Transform3D, r: float, thick: float, teeth: int, key: String) -> void:
	var n: int = teeth * 2
	var r_in: float = r * 0.84
	var up: Vector3 = (xf.basis * Vector3.UP).normalized()
	for i in range(n):
		var a0: float = TAU * i / n
		var a1: float = TAU * (i + 1) / n
		var rr: float = r if i % 2 == 0 else r_in
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		# couronne : du rayon intérieur de la jante (0.62 r) au bord (dent ou creux)
		for s in [0.0, thick]:
			var nn: Vector3 = up if s > 0.0 else -up
			quad4(key, xf * (d0 * r * 0.62 + Vector3.UP * s), xf * (d1 * r * 0.62 + Vector3.UP * s), xf * (d1 * rr + Vector3.UP * s), xf * (d0 * rr + Vector3.UP * s), nn,
				Vector2(d0.x, d0.z) * r, Vector2(d1.x, d1.z) * r, Vector2(d1.x, d1.z) * r * 1.2, Vector2(d0.x, d0.z) * r * 1.2)
		var no: Vector3 = (xf.basis * ((d0 + d1) * 0.5)).normalized()
		quad4(key, xf * (d0 * rr), xf * (d1 * rr), xf * (d1 * rr + Vector3.UP * thick), xf * (d0 * rr + Vector3.UP * thick), no, Vector2(0, 0), Vector2(0.2, 0), Vector2(0.2, 0.1), Vector2(0, 0.1))
		# flancs des dents
		if i % 2 == 0:
			for dd in [d0, d1]:
				var side: Vector3 = (xf.basis * dd.cross(Vector3.UP)).normalized() * (1.0 if dd == d0 else -1.0)
				quad4(key, xf * (dd * r_in), xf * (dd * r), xf * (dd * r + Vector3.UP * thick), xf * (dd * r_in + Vector3.UP * thick), -side, Vector2(0, 0), Vector2(0.1, 0), Vector2(0.1, 0.1), Vector2(0, 0.1))
	ring(xf, r * 0.56, r * 0.64, thick, key, maxi(12, teeth))
	ring(xf, r * 0.1, r * 0.2, thick * 1.4, key, 10)
	for k in range(5):
		var a: float = TAU * k / 5.0
		var c: Vector3 = Vector3(cos(a), 0, sin(a)) * r * 0.38
		box(xf * Transform3D(Basis(Vector3.UP, -a), c + Vector3.UP * thick * 0.5), Vector3(r * 0.4, thick * 0.9, r * 0.09), key, 1.0)


## Un engrenage en maillage à part (pour qu'il tourne).
func gear_mesh(r: float, thick: float, teeth: int, key: String) -> ArrayMesh:
	var keep: Dictionary = batch
	batch = {}
	gear(Transform3D(Basis(), Vector3(0, -thick * 0.5, 0)), r, thick, teeth, key)
	var st: SurfaceTool = batch[key]
	batch = keep
	var mesh: ArrayMesh = st.commit()
	mesh.surface_set_material(0, mat(key))
	return mesh


## Dôme (demi-sphère, ou bulbe un peu étiré) posé sur xf.origin ; un épi au sommet.
func dome(xf: Transform3D, r: float, key: String, stretch: float = 1.0, seg: int = 16, spire: bool = true) -> void:
	var rings: int = 7
	for j in range(rings):
		var b0: float = PI * 0.5 * j / rings
		var b1: float = PI * 0.5 * (j + 1) / rings
		for i in range(seg):
			var a0: float = TAU * i / seg
			var a1: float = TAU * (i + 1) / seg
			var p := func(a: float, b: float) -> Vector3:
				return Vector3(cos(a) * cos(b) * r, sin(b) * r * stretch, sin(a) * cos(b) * r)
			var n: Vector3 = (xf.basis * Vector3(cos((a0 + a1) * 0.5) * cos((b0 + b1) * 0.5), sin((b0 + b1) * 0.5) / stretch, sin((a0 + a1) * 0.5) * cos((b0 + b1) * 0.5))).normalized()
			quad4(key, xf * p.call(a0, b0), xf * p.call(a1, b0), xf * p.call(a1, b1), xf * p.call(a0, b1), n,
				Vector2(float(i) / seg * 4.0, 1.0 - float(j) / rings), Vector2(float(i + 1) / seg * 4.0, 1.0 - float(j) / rings),
				Vector2(float(i + 1) / seg * 4.0, 1.0 - float(j + 1) / rings), Vector2(float(i) / seg * 4.0, 1.0 - float(j + 1) / rings))
	# côtes de laiton
	for k in range(8):
		var a2: float = TAU * k / 8.0
		for j2 in range(rings):
			var b2: float = PI * 0.5 * (j2 + 0.5) / rings
			var c: Vector3 = Vector3(cos(a2) * cos(b2) * r * 1.01, sin(b2) * r * stretch * 1.01, sin(a2) * cos(b2) * r * 1.01)
			box(Transform3D(Basis.looking_at(Vector3(cos(a2), 0, sin(a2)), Vector3.UP).rotated(Vector3(-sin(a2), 0, cos(a2)), -b2), xf * c), Vector3(0.08, r * PI * 0.5 / rings, 0.06), "laiton", 1.0)
	if spire:
		var top: Vector3 = xf * Vector3(0, r * stretch, 0)
		cyl(Transform3D(xf.basis, top), r * 0.12, 0.02, r * 0.9, "laiton", 8)
		cyl(Transform3D(xf.basis, top + xf.basis * Vector3(0, r * 0.3, 0)), r * 0.08, r * 0.08, 0.1, "laiton", 8)


## Fenêtre d'atelier : grande baie en arc à petits carreaux, cadre de fer, arc de briques.
## xf : milieu du bas de la baie, sur le nu du mur (qui regarde -Z).
func shop_window(xf: Transform3D, w: float, h: float, lit: bool = true) -> void:
	quad(xf * Transform3D(Basis(), Vector3(0, h * 0.5, -0.03)), w, h, "vitre_lumiere" if lit else "verriere", Vector2(0, 0), Vector2(w / 1.6, h / 1.6))
	for s in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(s * (w * 0.5 + 0.05), h * 0.5, -0.06)), Vector3(0.1, h, 0.1), "fer_noir", 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, -0.06, -0.12)), Vector3(w + 0.3, 0.12, 0.3), "pierre", 1.0)
	for k in range(9):
		var a: float = PI * (k + 0.5) / 9.0
		var c := Vector3(cos(a) * (w * 0.5 + 0.12), h + sin(a) * (w * 0.25 + 0.12), -0.08)
		box(xf * Transform3D(Basis(Vector3(0, 0, 1), a), c), Vector3(0.22, w * PI * 0.5 / 9.0 * 1.15, 0.16), "brique_sombre", 0.6)
	# l'imposte en demi-ellipse
	for k2 in range(8):
		var a0: float = PI * k2 / 8.0
		var a1: float = PI * (k2 + 1) / 8.0
		tri("vitre_lumiere" if lit else "verriere", xf * Vector3(0, h, -0.03), xf * Vector3(cos(a0) * w * 0.5, h + sin(a0) * w * 0.25, -0.03), xf * Vector3(cos(a1) * w * 0.5, h + sin(a1) * w * 0.25, -0.03),
			(xf.basis * Vector3(0, 0, -1)).normalized(), Vector2(0.5, 0), Vector2(0.5 + cos(a0) * 0.5, 0), Vector2(0.5 + cos(a1) * 0.5, 0.1))


## Une maison-atelier : murs de brique, grandes baies, toit d'ardoise (ou verrière), une
## cheminée qui fume, parfois un petit dôme de cuivre, une citerne, des tuyaux.
## xf : milieu du bas de la façade (qui regarde -Z). Renvoie le point devant la porte.
func workshop(xf: Transform3D, w: float, d: float, h: float, opts: Dictionary = {}) -> Vector3:
	var wall: String = str(opts.get("mur", "brique"))
	box(xf * Transform3D(Basis(), Vector3(0, h / 2, d / 2)), Vector3(w, h, d), wall, 3.0, 63 - 8)
	col_box(xf * Transform3D(Basis(), Vector3(0, h / 2, d / 2)), Vector3(w, h, d))
	# soubassement et corniche de pierre
	box(xf * Transform3D(Basis(), Vector3(0, 0.35, d / 2)), Vector3(w + 0.12, 0.7, d + 0.12), "pierre", 1.5, 63 - 12)
	box(xf * Transform3D(Basis(), Vector3(0, h, d / 2)), Vector3(w + 0.3, 0.3, d + 0.3), "pierre", 1.5)
	# la porte (double, en bois sombre, ferrures)
	var door_x: float = float(opts.get("porte_x", 0.0))
	var dxf: Transform3D = xf * Transform3D(Basis(), Vector3(door_x, 0, 0))
	quad(dxf * Transform3D(Basis(), Vector3(0, 1.3, -0.03)), 1.8, 2.6, "porte_brun")
	for s in [-1.0, 1.0]:
		box(dxf * Transform3D(Basis(), Vector3(s * 0.98, 1.4, -0.08)), Vector3(0.16, 2.8, 0.16), "fer_noir", 1.0)
	box(dxf * Transform3D(Basis(), Vector3(0, 2.86, -0.08)), Vector3(2.12, 0.18, 0.16), "fer_noir", 1.0)
	# les baies
	var nwin: int = int((w - 2.4) / 3.2)
	for k in range(nwin):
		var wx: float = -w / 2 + 1.2 + (k + 0.5) * (w - 2.4) / nwin
		if absf(wx - door_x) < 1.9:
			continue
		shop_window(xf * Transform3D(Basis(), Vector3(wx, 0.9, 0)), 1.9, 2.0, true)
	if h > 6.5:
		for k2 in range(nwin + 1):
			var wx2: float = -w / 2 + 1.2 + (k2 + 0.5) * (w - 2.4) / (nwin + 1)
			shop_window(xf * Transform3D(Basis(), Vector3(wx2, h - 2.6, 0)), 1.4, 1.5, true)
	# le toit
	var roof: String = str(opts.get("toit", "ardoise"))
	var top_xf: Transform3D = xf * Transform3D(Basis(), Vector3(0, h + 0.15, d / 2))
	if roof == "verriere":
		var rise: float = d * 0.3
		for s2 in [-1.0, 1.0]:
			var e0 := Vector3(-w / 2, 0, s2 * d / 2)
			var e1 := Vector3(w / 2, 0, s2 * d / 2)
			var r0 := Vector3(-w / 2, rise, 0)
			var r1 := Vector3(w / 2, rise, 0)
			quad4("verriere", top_xf * e0, top_xf * e1, top_xf * r1, top_xf * r0, (top_xf.basis * Vector3(0, d / 2, s2 * rise)).normalized(), Vector2(0, 2), Vector2(w / 1.5, 2), Vector2(w / 1.5, 0), Vector2(0, 0))
			for k3 in range(int(w / 2.0) + 1):
				var x3: float = -w / 2 + k3 * w / int(w / 2.0)
				box(Transform3D(top_xf.basis, top_xf * Vector3(x3, rise * 0.5, s2 * d * 0.25)).rotated_local(Vector3.RIGHT, -s2 * atan2(rise, d / 2)), Vector3(0.08, 0.08, Vector2(d / 2, rise).length()), "fer_noir", 1.0)
		for sx in [-1.0, 1.0]:
			tri(wall, top_xf * Vector3(sx * w / 2, 0, -d / 2), top_xf * Vector3(sx * w / 2, 0, d / 2), top_xf * Vector3(sx * w / 2, rise, 0), (top_xf.basis * Vector3(sx, 0, 0)).normalized(), Vector2(0, 1), Vector2(d / 3, 1), Vector2(d / 6, 1 - rise / 3))
	elif roof == "plat":
		box(top_xf * Transform3D(Basis(), Vector3(0, 0.3, 0)), Vector3(w, 0.6, d), wall, 2.0, 63 - 8)
	else:
		roof_gable(top_xf, w, d, 32.0, 0.35, "ardoise", wall)
	# cheminée d'usine, dôme, citerne
	var tops: Array = []
	if bool(opts.get("cheminee", true)):
		var cx: float = w / 2 - 1.2 if door_x < 0.0 else -w / 2 + 1.2
		var cxf: Transform3D = xf * Transform3D(Basis(), Vector3(cx, h, d * 0.7))
		var ch: float = float(opts.get("cheminee_h", 6.0))
		cyl(cxf, 0.75, 0.55, ch, "brique_sombre", 12, false, 2.0)
		cyl(cxf * Transform3D(Basis(), Vector3(0, ch, 0)), 0.72, 0.72, 0.35, "fer_noir", 12)
		tops.append(cxf * Vector3(0, ch + 0.4, 0))
	if bool(opts.get("dome", false)):
		var dxf2: Transform3D = xf * Transform3D(Basis(), Vector3(-door_x * 0.3, h + 0.15, d * 0.35))
		cyl(dxf2, 1.9, 1.9, 1.2, wall, 16, false, 2.0)
		dome(dxf2 * Transform3D(Basis(), Vector3(0, 1.2, 0)), 2.0, "cuivre", 1.1)
	if bool(opts.get("citerne", false)):
		var txf: Transform3D = xf * Transform3D(Basis(), Vector3(w * 0.25, h + 0.15, d * 0.75))
		for s3 in [Vector3(-0.8, 0, -0.8), Vector3(0.8, 0, -0.8), Vector3(-0.8, 0, 0.8), Vector3(0.8, 0, 0.8)]:
			box(txf * Transform3D(Basis(), s3 + Vector3(0, 1.0, 0)), Vector3(0.14, 2.0, 0.14), "fer_noir", 1.0)
		cyl(txf * Transform3D(Basis(), Vector3(0, 2.0, 0)), 1.25, 1.25, 1.8, "cuivre", 14)
		dome(txf * Transform3D(Basis(), Vector3(0, 3.8, 0)), 1.25, "cuivre", 0.5, 14, false)
	opts["_fumees"] = tops
	return xf * Vector3(door_x, 0, -1.2)


## Tour ronde de brique, coiffée d'un dôme de cuivre (ou d'un toit conique d'ardoise).
func round_tower(xf: Transform3D, r: float, h: float, cap: String = "dome") -> void:
	cyl(xf, r, r * 0.94, h, "brique", 20, false, 3.0)
	col_cyl(xf.origin, r, h)
	cyl(xf * Transform3D(Basis(), Vector3(0, h, 0)), r * 1.06, r * 1.06, 0.4, "pierre", 20)
	for k in range(3):
		var y: float = h * (0.35 + 0.25 * k)
		for i in range(4):
			var a: float = TAU * (i + 0.5 * (k % 2)) / 4.0
			var p := Vector3(cos(a) * r * 0.97, y, sin(a) * r * 0.97)
			var bas := Basis.looking_at(-Vector3(cos(a), 0, sin(a)), Vector3.UP)
			shop_window(Transform3D(xf.basis * bas, xf * p), 0.9, 1.4, true)
	if cap == "dome":
		dome(xf * Transform3D(Basis(), Vector3(0, h + 0.4, 0)), r * 1.02, "cuivre", 1.25, 20)
	else:
		cyl(xf * Transform3D(Basis(), Vector3(0, h + 0.4, 0)), r * 1.15, 0.05, r * 1.8, "ardoise", 20)


## Bobine de Tesla : socle, colonne de spires de cuivre, tore au sommet. Renvoie le sommet.
func tesla_coil(xf: Transform3D, h: float) -> Vector3:
	box(xf * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(3.0, 1.0, 3.0), "fonte", 1.5)
	col_box(xf * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(3.0, 1.0, 3.0))
	cyl(xf * Transform3D(Basis(), Vector3(0, 1.0, 0)), 0.9, 0.6, 1.2, "fer_noir", 14)
	var y: float = 2.2
	while y < h - 1.6:
		cyl(xf * Transform3D(Basis(), Vector3(0, y, 0)), 0.48, 0.48, 0.16, "cuivre_poli", 14)
		cyl(xf * Transform3D(Basis(), Vector3(0, y + 0.16, 0)), 0.42, 0.42, 0.08, "fer_noir", 14, false)
		y += 0.24
	col_cyl(xf * Vector3(0, 2.2, 0), 0.5, h - 3.8)
	ring(xf * Transform3D(Basis(), Vector3(0, h - 1.4, 0)), 0.5, 1.7, 0.7, "acier", 24)
	cyl(xf * Transform3D(Basis(), Vector3(0, h - 1.4, 0)), 0.5, 0.5, 0.7, "acier", 16)
	cyl(xf * Transform3D(Basis(), Vector3(0, h - 0.7, 0)), 0.3, 0.05, 1.0, "tesla", 10)
	return xf * Vector3(0, h, 0)


## Réverbère de fonte à globe (s'allume le soir).
func globe_lamp(pos: Vector3, h: float = 4.2, light: bool = true) -> void:
	var xf := Transform3D(Basis(), pos)
	cyl(xf, 0.22, 0.16, 0.6, "fer_noir", 10)
	cyl(xf * Transform3D(Basis(), Vector3(0, 0.6, 0)), 0.08, 0.06, h - 0.9, "fer_noir", 8)
	for k in range(4):
		var a: float = TAU * k / 4.0
		box(xf * Transform3D(Basis(Vector3.UP, a), Vector3(0, h - 0.5, 0) + Vector3(cos(a), 0, sin(a)) * 0.0), Vector3(0.5, 0.04, 0.04), "laiton", 0.5)
	cyl(xf * Transform3D(Basis(), Vector3(0, h - 0.35, 0)), 0.32, 0.3, 0.55, "globe", 12)
	cyl(xf * Transform3D(Basis(), Vector3(0, h + 0.2, 0)), 0.34, 0.05, 0.3, "cuivre_poli", 12)
	col_cyl(pos, 0.2, h)
	if light and temps != null:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.86, 0.62)
		l.omni_range = 11.0
		l.position = pos + Vector3.UP * (h - 0.1)
		l.distance_fade_enabled = true
		l.distance_fade_begin = 60.0
		l.distance_fade_length = 15.0
		root.add_child(l)
		temps.register_lamp(l, 1.6)
		lamp_count += 1


## Balustrade de fer forgé entre deux points (au sol).
func iron_rail(a: Vector3, b: Vector3, h: float = 1.05) -> void:
	var L: float = a.distance_to(b)
	var dir: Vector3 = (b - a).normalized()
	var bas := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	box(Transform3D(bas, (a + b) * 0.5 + Vector3.UP * h), Vector3(L, 0.07, 0.09), "fer_noir", 1.0)
	box(Transform3D(bas, (a + b) * 0.5 + Vector3.UP * 0.12), Vector3(L, 0.05, 0.05), "fer_noir", 1.0)
	var n: int = int(L / 0.16)
	for i in range(n + 1):
		var p: Vector3 = a.lerp(b, float(i) / n)
		box(Transform3D(bas, p + Vector3.UP * h * 0.5), Vector3(0.025, h, 0.025), "fer_noir", 1.0)
	var m: int = int(L / 2.5)
	for j in range(m + 1):
		var q: Vector3 = a.lerp(b, float(j) / maxi(m, 1))
		box(Transform3D(bas, q + Vector3.UP * (h * 0.5 + 0.05)), Vector3(0.09, h + 0.1, 0.09), "fer_noir", 1.0)
		cyl(Transform3D(Basis(), q + Vector3.UP * (h + 0.1)), 0.07, 0.03, 0.14, "laiton", 6)
	col_box(Transform3D(bas, (a + b) * 0.5 + Vector3.UP * h * 0.5), Vector3(L, h, 0.12))
