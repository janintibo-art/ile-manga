extends "res://scripts/astrale_kit_v76.gd"
## V112 : la boîte à outils de Hautefond, la cité-colonne (fantastique-vapeur). Tout ce que savent
## faire les kits d'avant (Montjoie, Pandémonia, le Boucan, Astralys…), et ce qui fait Hautefond :
##  - house112() : la maison de pierre blonde (trois à cinq niveaux, bandeaux et pilastres clairs,
##    hautes fenêtres à encadrement de pierre, balconnets de fer, toit d'ardoise bleue en mansarde
##    ou à pignon, lucarnes, cheminées à chapeau de cuivre, descente d'eau de cuivre, tuyaux de
##    vapeur de laiton) ; boutique : une vitrine, une enseigne pendue, un store ;
##  - sign112() : une enseigne de Hautefond (« enseigne112_<id> ») pendue à sa potence ;
##  - steam_pipe112(), gear112() (un engrenage de laiton), globe_lamp112() (un réverbère à globe),
##    clock112() (une grande horloge à cadran), airship112() (un dirigeable), bench112() ;
##  - les prototypes : fen112 (fenêtre), fenp112 (petite fenêtre), balcon112, globe112.
## Repères : comme les autres kits, une façade « xf » regarde +Z local.

const Mats112 = preload("res://scripts/hautefond_mats_v112.gd")
const MURS := ["pierre112", "pierre112", "pierre112_clair", "pierre112_chaud", "pierre112_rose", "pierre112_clair"]
const STORES := ["bleu", "rouge", "vert", "or", "creme"]

var steam_spots: Array = []              # Vector3 : les évents de vapeur (les panaches)
var gears: Array = []                    # MeshInstance3D : les engrenages qui tournent (on les fait tourner)


func mat(key: String) -> Material:
	if mats.has(key):
		return mats[key]
	var m: Material = Mats112.make(key)
	if m != null:
		mats[key] = m
		return m
	return super.mat(key)


func proto(key: String) -> ArrayMesh:
	if protos.has(key):
		return protos[key]
	var parts: PackedStringArray = key.split("|")
	var kind: String = parts[0]
	if not kind.ends_with("112"):
		return super.proto(key)
	var saved: Dictionary = batch
	batch = {}
	var I := Transform3D.IDENTITY
	match kind:
		"fen112":
			_win112_geo(I, 1.0, 2.0, parts.size() > 1 and parts[1] == "1")
		"fenp112":
			_win112_geo(I, 0.8, 1.2, parts.size() > 1 and parts[1] == "1")
		"balcon112":
			_balconet112_geo(I, 1.4)
		"globe112":
			_globe_geo()
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


# =================================================================== fenêtres, balcons

## Une haute fenêtre (le centre à l'origine, sur le nu du mur qui regarde +Z) : la vitre (allumée ou
## non), les petits bois peints, l'encadrement de pierre claire en saillie, l'appui, la clé.
func _win112_geo(xf: Transform3D, w: float, h: float, lit: bool) -> void:
	quadz(xf * T(0, 0, 0.012), w, h, "vitre71_on" if lit else "vitre71_off")
	for s in [-1.0, 1.0]:
		box(xf * T(s * (w * 0.5 + 0.11), 0, 0.05), Vector3(0.22, h + 0.1, 0.1), "pierre112_clair", 1.0, 63 - 8 - 4)
	box(xf * T(0, h * 0.5 + 0.13, 0.06), Vector3(w + 0.5, 0.26, 0.12), "pierre112_clair", 1.0)
	box(xf * T(0, h * 0.5 + 0.16, 0.12), Vector3(0.24, 0.3, 0.08), "pierre112_clair", 1.0)
	box(xf * T(0, -h * 0.5 - 0.07, 0.1), Vector3(w + 0.44, 0.14, 0.24), "pierre112_clair", 1.0)
	box(xf * T(0, 0, 0.025), Vector3(0.05, h, 0.03), "acier112", 1.0, 16 | 4 | 8)
	for k in range(1, 3):
		box(xf * T(0, -h * 0.5 + h * k / 3.0, 0.025), Vector3(w, 0.04, 0.03), "acier112", 1.0, 16 | 4 | 8)


## Un balconnet de fer forgé (devant une fenêtre, le bas au sol de l'étage).
func _balconet112_geo(xf: Transform3D, w: float) -> void:
	box(xf * T(0, 0.04, 0.22), Vector3(w, 0.08, 0.44), "pierre112_clair", 1.0)
	box(xf * T(0, 0.95, 0.42), Vector3(w, 0.05, 0.05), "acier112", 1.0)
	for s in [-1.0, 1.0]:
		box(xf * T(s * (w * 0.5 - 0.02), 0.95, 0.22), Vector3(0.05, 0.05, 0.44), "acier112", 1.0)
	var n: int = int(w / 0.12)
	for i in range(n + 1):
		box(xf * T(-w * 0.5 + w * i / n, 0.5, 0.42), Vector3(0.022, 0.9, 0.022), "acier112", 1.0, 1 | 2 | 16 | 32)
	for i2 in range(3):
		cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), xf * Vector3(-w * 0.33 + i2 * w * 0.33, 0.55, 0.42)), 0.18, 0.18, 0.02, "laiton112_vieux", 10, false)


## Le globe d'un réverbère (le prototype : un globe lumineux et son chapeau de laiton).
func _globe_geo() -> void:
	ball(T(0, 0.0, 0), 0.24, "lampe112", 10, 6)
	cyl(T(0, 0.18, 0), 0.2, 0.06, 0.16, "laiton112", 10)
	cyl(T(0, -0.26, 0), 0.08, 0.14, 0.08, "laiton112", 10)


func window112(xf: Transform3D, lit: bool, small: bool = false) -> void:
	place(("fenp112|" if small else "fen112|") + ("1" if lit else "0"), xf)


# =================================================================== la maison de Hautefond

## xf : le milieu de la façade au sol, la façade regarde +Z, la maison s'étend vers -Z sur d.
## opts : floors (2-5), gf, uf, wall, roof ("mansarde" | "pignon"), lit, door_x, shop (enseigne :
## horloger…), awning (couleur du store), balcons, chimney, sides, v81 (une porte qu'on ouvre).
## Renvoie le point devant la porte.
func house112(xf: Transform3D, w: float, d: float, opts: Dictionary = {}) -> Vector3:
	var floors: int = clampi(int(opts.get("floors", 3)), 1, 6)
	var gf: float = float(opts.get("gf", 3.6))
	var uf: float = float(opts.get("uf", 3.1))
	var H: float = gf + uf * (floors - 1)
	var wall: String = str(opts.get("wall", MURS[rng.randi() % MURS.size()]))
	var lit_k: float = float(opts.get("lit", 0.5))
	var dx: float = float(opts.get("door_x", 0.0))
	var shop: String = str(opts.get("shop", ""))
	var sides: int = int(opts.get("sides", 0))
	# le soubassement, le corps de la maison
	box(xf * T(0, -0.3, -d * 0.5), Vector3(w + 0.16, 1.0, d + 0.16), "pierre112_sombre", 1.6, 63 - 8)
	box(xf * T(0, H * 0.5, -d * 0.5), Vector3(w, H, d), wall, 3.0, 63 - 8 - 4)
	col_box(xf * T(0, H * 0.5, -d * 0.5), Vector3(w, H, d))
	# les bandeaux (un par plancher), la corniche, les pilastres d'angle de la façade
	for k in range(1, floors):
		var fy: float = gf + (k - 1) * uf
		box(xf * T(0, fy, -d * 0.5), Vector3(w + 0.12, 0.2, d + 0.12), "pierre112_clair", 1.2, 63 - 8)
	box(xf * T(0, H + 0.12, -d * 0.5), Vector3(w + 0.46, 0.3, d + 0.46), "pierre112_clair", 1.2)
	box(xf * T(0, H - 0.12, -d * 0.5), Vector3(w + 0.26, 0.2, d + 0.26), "pierre112_clair", 1.2, 63 - 4)
	for s in [-1.0, 1.0]:
		box(xf * T(s * (w * 0.5 - 0.16), H * 0.5, 0.04), Vector3(0.34, H, 0.1), "pierre112_clair", 1.4, 63 - 32 - 8)
	# les fenêtres des étages (balconnets au premier), derrière aussi
	var n: int = clampi(int((w - 0.6) / 1.8), 1, 5)
	var balcons: bool = bool(opts.get("balcons", rng.randf() < 0.6))
	for f in range(1, floors):
		var y: float = gf + (f - 1) * uf + uf * 0.5
		for i in range(n):
			var x: float = -w * 0.5 + (i + 0.5) * w / n
			window112(xf * T(x, y, 0.0), rng.randf() < lit_k, f == floors - 1 and floors >= 4)
			if f == 1 and balcons:
				place("balcon112", xf * T(x, y - uf * 0.5 + 0.06, 0.0))
			if bool(opts.get("back", true)):
				window112(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(-x, y, -d)), rng.randf() < lit_k * 0.8)
		for sd in [1, 2]:
			if (sides & sd) == 0:
				continue
			var sg: float = -1.0 if sd == 1 else 1.0
			var ns: int = clampi(int((d - 0.6) / 1.9), 1, 5)
			var face: Transform3D = xf * Transform3D(Basis(Vector3.UP, sg * PI * 0.5), Vector3(sg * w * 0.5, y, -d * 0.5))
			for i2 in range(ns):
				window112(face * T(-d * 0.5 + (i2 + 0.5) * d / ns, 0, 0), rng.randf() < lit_k * 0.8)
	# le rez-de-chaussée : la porte, la vitrine (boutique) ou de petites fenêtres
	if bool(opts.get("door", true)):
		door71(xf * T(dx, 0.0, 0.0), "planches71_sombre" if rng.randf() < 0.5 else "bois112")
		box(xf * T(dx, 2.75, 0.06), Vector3(1.9, 0.3, 0.14), "pierre112_clair", 1.0)
	for i3 in range(n):
		var x3: float = -w * 0.5 + (i3 + 0.5) * w / n
		if absf(x3 - dx) < 1.3:
			continue
		if shop != "":
			_shop_window71(xf * T(x3, 1.45, 0.0), minf(1.7, w / n * 0.82), 2.1)
		else:
			window112(xf * T(x3, 1.7, 0.0), rng.randf() < lit_k * 0.7, true)
	if shop != "":
		sign112(xf * T(w * 0.5 - 0.4, gf - 0.6, 0.0), shop)
		if str(opts.get("awning", "")) != "":
			awning71(xf * T(0, gf - 0.3, 0.0), w - 0.6, 1.4, 0.7, str(opts["awning"]))
	# le toit : une mansarde (le brisis raide, des lucarnes) ou un pignon pointu
	var roof_kind: String = str(opts.get("roof", "mansarde" if rng.randf() < 0.6 else "pignon"))
	var rise: float = 0.0
	if roof_kind == "mansarde":
		rise = roof_hip(xf * T(0, H + 0.26, -d * 0.5), w + 0.1, d + 0.1, 66.0, 0.1, "ardoise112")
		box(xf * T(0, H + 0.26 + rise + 0.05, -d * 0.5), Vector3(maxf(w - d, 0.4) + 0.3, 0.12, 0.3), "acier112", 1.0)
		var nd: int = clampi(int(w / 2.6), 1, 4)
		for i5 in range(nd):
			var x5: float = -w * 0.5 + (i5 + 0.5) * w / nd
			_dormer112(xf * T(x5, H + 0.3, -0.55), rng.randf() < lit_k)
	else:
		rise = roof_gable(xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, H + 0.26, -d * 0.5)), d + 0.1, w + 0.1, rng.randf_range(54.0, 60.0), 0.35, "ardoise112", wall)
		if rise > 2.2:
			window112(xf * T(0, H + rise * 0.3 + 0.4, 0.03), rng.randf() < lit_k, true)
		# l'épi de faîtage en laiton
		cyl(xf * T(0, H + 0.26 + rise, 0.1), 0.05, 0.02, 0.9, "laiton112", 6)
		ball(xf * T(0, H + 0.26 + rise + 0.5, 0.1), 0.08, "laiton112", 6, 3)
	# les cheminées, coiffées de cuivre ; un tuyau de vapeur, parfois
	if bool(opts.get("chimney", rng.randf() < 0.8)):
		var cxs: float = (w * 0.3) * (1.0 if rng.randf() < 0.5 else -1.0)
		var ch_h: float = rise + 1.3
		var cz: float = -d * 0.62
		box(xf * T(cxs, H + ch_h * 0.5, cz), Vector3(0.7, ch_h, 0.7), "pierre112_sombre", 1.2, 63 - 8)
		box(xf * T(cxs, H + ch_h + 0.06, cz), Vector3(0.88, 0.12, 0.88), "pierre112_clair", 1.0)
		for k6 in range(2):
			cyl(xf * T(cxs + (k6 - 0.5) * 0.3, H + ch_h + 0.12, cz), 0.1, 0.1, 0.4, "terre71", 8)
		chimneys70.append(xf * Vector3(cxs, H + ch_h + 0.6, cz))
	if rng.randf() < 0.35:
		steam_pipe112(xf * T(-w * 0.5 + 0.35, 0.0, 0.18), H + rise * 0.5 + 1.2)
	# la descente d'eau de cuivre, à l'angle
	cyl(xf * T(w * 0.5 - 0.08, 0.0, 0.16), 0.06, 0.06, H, "cuivre112", 6, false)
	box(xf * T(0, H - 0.02, 0.16), Vector3(w, 0.1, 0.14), "cuivre112", 1.0)
	if not opts.has("shop") and bool(opts.get("v81", false)):
		porte_v81(xf, Vector3(dx, 0.0, 1.2), w, d, str(opts.get("style81", "hautefond")), floors)
	return xf * Vector3(dx, 0.0, 1.2)


## Une lucarne d'ardoise (xf : le pied, sur la corniche, qui regarde +Z).
func _dormer112(xf: Transform3D, lit: bool) -> void:
	box(xf * T(0, 0.75, -0.5), Vector3(1.2, 1.5, 1.0), "pierre112_clair", 1.4, 63 - 8)
	window112(xf * T(0, 0.8, 0.0), lit, true)
	cyl(Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), xf * Vector3(0, 1.5, 0.02)), 0.62, 0.62, 1.05, "ardoise112", 10, true, 1.0)


## Un tuyau de vapeur de laiton qui monte le long d'un mur (xf : le pied, le mur derrière), ses
## colliers, son coude, son évent au sommet (un panache).
func steam_pipe112(xf: Transform3D, h: float) -> void:
	cyl(xf, 0.09, 0.09, h, "laiton112_vieux", 8, false)
	var k: int = int(h / 1.6)
	for i in range(1, k):
		cyl(xf * T(0, i * 1.6, 0), 0.12, 0.12, 0.08, "laiton112", 8)
	cyl(xf * T(0, h, 0), 0.14, 0.18, 0.4, "cuivre112", 8)
	steam_spots.append(xf * Vector3(0, h + 0.45, 0))


## Un engrenage de laiton (dans le plan XY local de xf), qu'on fera tourner s'il est « libre ».
func gear112(xf: Transform3D, r: float, teeth: int = 12, thick: float = 0.12, key: String = "laiton112", free: bool = false) -> void:
	var target_root: Node3D = root
	var g_batch: Dictionary = batch
	if free:
		batch = {}
	var I: Transform3D = Transform3D.IDENTITY if free else xf
	var bx: Basis = Basis(Vector3.RIGHT, PI * 0.5)
	cyl(I * Transform3D(bx, Vector3(0, 0, -thick * 0.5)), r * 0.82, r * 0.82, thick, key, maxi(teeth * 2, 12))
	for t in range(teeth):
		var a: float = TAU * t / teeth
		box(I * Transform3D(Basis(Vector3.BACK, a), Vector3(cos(a), sin(a), 0) * r * 0.9), Vector3(r * 0.28, r * 0.24, thick), key, 1.0)
	cyl(I * Transform3D(bx, Vector3(0, 0, -thick * 0.8)), r * 0.18, r * 0.18, thick * 1.6, "acier112", 10)
	for sp in range(4):
		var a2: float = TAU * sp / 4.0 + 0.4
		box(I * Transform3D(Basis(Vector3.BACK, a2), Vector3(cos(a2), sin(a2), 0) * r * 0.45), Vector3(r * 0.7, r * 0.12, thick * 1.1), key, 1.0)
	if free:
		var mesh := ArrayMesh.new()
		for k in batch:
			var st: SurfaceTool = batch[k]
			st.commit(mesh)
			mesh.surface_set_material(mesh.get_surface_count() - 1, mat(str(k)))
		batch = g_batch
		var mi := MeshInstance3D.new()
		mi.name = "Engrenage"
		mi.mesh = mesh
		mi.visibility_range_end = 260.0
		target_root.add_child(mi)
		mi.transform = xf
		mi.set_meta("vitesse", (1.0 if gears.size() % 2 == 0 else -1.0) * 0.6 / maxf(r, 0.3))
		gears.append(mi)


## Une enseigne de Hautefond pendue à sa potence (xf : le point d'accroche sur le mur, +Z : la rue).
func sign112(xf: Transform3D, sign_id: String, w: float = 1.3, h: float = 0.65) -> void:
	box(xf * T(0, 0.2, 0.02), Vector3(0.12, 0.3, 0.04), "acier112", 1.0)
	box(xf * T(0, 0.3, 0.6), Vector3(0.04, 0.04, 1.2), "acier112", 1.0)
	beam(xf * Vector3(0, -0.1, 0.03), xf * Vector3(0, 0.28, 0.66), 0.03, "acier112")
	var bx: Transform3D = xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, 0.3 - h * 0.5 - 0.12, 0.62))
	box(bx, Vector3(w + 0.08, h + 0.08, 0.05), "laiton112_vieux", 1.0)
	quad(bx * T(0, 0, 0.03), w, h, "enseigne112_" + sign_id)
	quad(bx * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -0.03)), w, h, "enseigne112_" + sign_id)


## Une grande enseigne posée à plat sur une façade (xf : le milieu, +Z : la rue).
func plaque112(xf: Transform3D, sign_id: String, w: float = 3.2) -> void:
	box(xf * T(0, 0, 0.03), Vector3(w + 0.16, w * 0.5 + 0.16, 0.06), "laiton112_vieux", 1.0)
	quadz(xf * T(0, 0, 0.065), w, w * 0.5, "enseigne112_" + sign_id)


## Un réverbère de Hautefond : fût de fonte, crosse, deux globes (pos : le pied).
func globe_lamp112(pos: Vector3, yaw: float = 0.0, h: float = 4.2, with_light: bool = true) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw), pos)
	cyl(xf, 0.24, 0.17, 0.5, "acier112", 8)
	cyl(xf * T(0, 0.5, 0), 0.08, 0.06, h - 0.5, "acier112", 8, false)
	cyl(xf * T(0, 1.4, 0), 0.11, 0.11, 0.1, "laiton112", 8)
	for s in [-1.0, 1.0]:
		beam(xf * Vector3(0, h - 0.4, 0), xf * Vector3(s * 0.55, h - 0.1, 0), 0.05, "acier112")
		place("globe112", xf * T(s * 0.55, h - 0.38, 0))
	ball(xf * T(0, h + 0.05, 0), 0.1, "laiton112", 8, 4)
	col_cyl(pos, 0.2, h)
	if with_light:
		var real: bool = lamps70.size() % maxi(light_every, 1) == 0
		_lamp_light(xf * Vector3(0, h - 0.3, 0), 1.3, 10.0, real)


## Un banc de Hautefond : lattes de bois, pieds de fonte (xf : le milieu, assis face à +Z).
func bench112(xf: Transform3D) -> void:
	for s in [-1.0, 1.0]:
		box(xf * T(s * 0.75, 0.22, 0.0), Vector3(0.08, 0.44, 0.5), "acier112", 1.0)
		box(xf * T(s * 0.75, 0.62, -0.24), Vector3(0.08, 0.5, 0.06), "acier112", 1.0)
	for k in range(4):
		box(xf * T(0, 0.46, -0.18 + k * 0.12), Vector3(1.7, 0.04, 0.09), "bois112", 1.0)
	for k2 in range(2):
		box(xf * T(0, 0.66 + k2 * 0.16, -0.26), Vector3(1.7, 0.1, 0.03), "bois112", 1.0)
	col_box(xf * T(0, 0.3, 0.0), Vector3(1.7, 0.6, 0.55))


## Une grande horloge à cadran (xf : le centre du cadran, +Z : devant) : cadran, chiffres, aiguilles.
func clock112(xf: Transform3D, r: float) -> void:
	cyl(Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), xf * Vector3(0, 0, -0.12)), r + 0.18, r + 0.18, 0.16, "laiton112", 32)
	cyl(Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), xf * Vector3(0, 0, 0.0)), r, r, 0.06, "cadran112", 32)
	for k in range(12):
		var a: float = TAU * k / 12.0
		var L: float = r * (0.2 if k % 3 == 0 else 0.12)
		box(xf * Transform3D(Basis(Vector3.BACK, a), Vector3(sin(a), cos(a), 0) * (r * 0.84) + Vector3(0, 0, 0.07)), Vector3(r * 0.05, L, 0.02), "acier112", 1.0)
	box(xf * Transform3D(Basis(Vector3.BACK, -0.6), Vector3(sin(0.6), cos(0.6), 0) * r * 0.25 + Vector3(0, 0, 0.09)), Vector3(r * 0.06, r * 0.5, 0.02), "acier112", 1.0)
	box(xf * Transform3D(Basis(Vector3.BACK, 2.1), Vector3(-sin(2.1), cos(2.1), 0) * -r * 0.36 + Vector3(0, 0, 0.1)), Vector3(r * 0.045, r * 0.72, 0.02), "acier112", 1.0)
	ball(xf * T(0, 0, 0.1), r * 0.06, "laiton112", 8, 4)


## Un dirigeable (xf : le centre de l'enveloppe, le nez vers +X) : l'enveloppe de toile, ses bandes,
## les ailerons, la nacelle de bois et de laiton suspendue, les hélices. Longueur L.
func airship112(xf: Transform3D, L: float, cloth: String = "tissu112_creme") -> void:
	var R0: float = L * 0.18
	var n: int = 14
	for i in range(n):
		var t0: float = float(i) / n
		var t1: float = float(i + 1) / n
		var r0: float = R0 * sqrt(maxf(1.0 - pow(t0 * 2.0 - 1.0, 2.0), 0.0)) + 0.02
		var r1: float = R0 * sqrt(maxf(1.0 - pow(t1 * 2.0 - 1.0, 2.0), 0.0)) + 0.02
		cyl(xf * Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3(-L * 0.5 + t0 * L, 0, 0)), r0, r1, L / n, cloth, 16, false, 2.0)
	for k in range(3):
		var x: float = -L * 0.3 + k * L * 0.3
		var rr: float = R0 * sqrt(maxf(1.0 - pow((x / L + 0.5) * 2.0 - 1.0, 2.0), 0.0))
		cyl(xf * Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3(x - 0.15, 0, 0)), rr + 0.04, rr + 0.04, 0.3, "tissu112_bleu", 16, false)
	for a in [0.0, PI * 0.5, PI, PI * 1.5]:
		box(xf * Transform3D(Basis(Vector3.RIGHT, a), Vector3(-L * 0.42, R0 * 0.55, 0)), Vector3(L * 0.14, R0 * 0.8, 0.08), "tissu112_bleu", 1.0)
	var g: Transform3D = xf * T(0, -R0 - 1.4, 0)
	box(g, Vector3(L * 0.3, 1.0, 1.6), "bois112", 1.0)
	box(g * T(0, 0.55, 0), Vector3(L * 0.3 + 0.2, 0.1, 1.8), "laiton112", 1.0)
	for s in [-1.0, 1.0]:
		for k2 in range(3):
			beam(g * Vector3(-L * 0.12 + k2 * L * 0.12, 0.5, s * 0.8), xf * Vector3(-L * 0.12 + k2 * L * 0.12, -R0 * 0.8, s * R0 * 0.5), 0.03, "acier112")
		cyl(Transform3D(xf.basis * Basis(Vector3.BACK, -PI * 0.5), g * Vector3(-L * 0.18, 0, s * 1.4)), 0.25, 0.18, 0.8, "laiton112", 8)
	for k3 in range(4):
		box(g * T(-L * 0.1 + k3 * L * 0.07, 0.05, 0.81), Vector3(0.5, 0.4, 0.02), "vitre71_on", 1.0)
