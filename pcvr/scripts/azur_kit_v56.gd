extends RefCounted
## V56 : la boîte à outils de Port-Azur — matériaux partagés, géométrie regroupée par
## matériau (une poignée d'appels de dessin pour toute la ville), formes simples (boîtes,
## cylindres, toits, anneaux) et le générateur de façades méditerranéennes (enduit coloré,
## volets persiennes, encadrements de pierre, balcons de fer forgé, génoise, tuiles canal,
## boutiques avec vitrine, store rayé et enseigne peinte).
## Convention : chaque objet reçoit un Transform3D (son repère local) ; les façades
## regardent -Z dans le repère du bâtiment.

const A := "res://assets/textures/azur/"
const Cassable = preload("res://scripts/cassable_v66.gd")

const ENDUITS := {
	"ocre": Color(0.94, 0.76, 0.52), "rose": Color(0.93, 0.68, 0.62), "jaune": Color(0.97, 0.86, 0.58),
	"blanc": Color(0.96, 0.94, 0.9), "saumon": Color(0.94, 0.64, 0.5), "terre": Color(0.84, 0.6, 0.44),
	"bleu": Color(0.74, 0.82, 0.88), "vert": Color(0.78, 0.86, 0.78), "creme": Color(0.97, 0.9, 0.76),
	"corail": Color(0.95, 0.58, 0.5),
}
const VOLETS := {
	"vert": Color(0.34, 0.5, 0.4), "bleu": Color(0.36, 0.54, 0.7), "gris": Color(0.64, 0.66, 0.64),
	"lavande": Color(0.6, 0.58, 0.74), "bordeaux": Color(0.56, 0.24, 0.24), "turquoise": Color(0.28, 0.6, 0.62),
	"brun": Color(0.46, 0.34, 0.24), "blanc": Color(0.92, 0.92, 0.9),
}

var mats: Dictionary = {}
var batch: Dictionary = {}               # clé matériau -> SurfaceTool
var body: StaticBody3D                   # collisions de la ville
var root: Node3D                         # où l'on accroche les maillages
var temps: Node                          # temps_v56 (lampes et fenêtres de nuit)
var rng := RandomNumberGenerator.new()
var lamp_count: int = 0
var signs: Array = []                    # MeshInstance3D des enseignes
## V81 : les portes des maisons décoratives (on y entre par un fondu : maisons_v81.gd).
## {door, out, w, d, style, floors} ; remis à zéro par main avant la construction du monde.
static var PORTES_V81: Array = []


func setup(parent: Node3D, time_node: Node) -> void:
	root = parent
	temps = time_node
	rng.seed = 5656
	body = StaticBody3D.new()
	body.name = "Collisions_ville_v56"
	body.collision_layer = 1
	body.collision_mask = 0
	root.add_child(body)


## V81 : note la porte d'une maison décorative. xf : le repère de la maison ; door_local : la porte
## dans ce repère (juste devant, dehors) ; la sortie regarde du côté de la porte.
func porte_v81(xf: Transform3D, door_local: Vector3, w: float, d: float, style: String, floors: int = 1, owner: String = "") -> void:
	var out: Vector3 = xf.basis * Vector3(0, 0, signf(door_local.z) if absf(door_local.z) > 0.01 else 1.0)
	porte_v81_dir(xf * door_local, out, w, d, style, floors, owner)


func porte_v81_dir(door: Vector3, out: Vector3, w: float, d: float, style: String, floors: int = 1, owner: String = "") -> void:
	note_v81(door, out, w, d, style, floors, owner)


## V82 : la même chose, pour les villages qui n'ont pas de boîte à outils (elfes, fées, Atlantide).
static func note_v81(door: Vector3, out: Vector3, w: float, d: float, style: String, floors: int = 1, owner: String = "") -> void:
	out.y = 0.0
	if out.length() < 0.01:
		return
	PORTES_V81.append({"door": door, "out": out.normalized(), "w": w, "d": d, "style": style, "floors": floors, "owner": owner})


# =================================================================== matériaux

func _tex(name: String) -> Texture2D:
	var p: String = A + name
	return load(p) if ResourceLoader.exists(p) else null


func mat(key: String) -> Material:
	if mats.has(key):
		return mats[key]
	var m := StandardMaterial3D.new()
	m.roughness = 0.9
	var parts: PackedStringArray = key.split("_", true, 1)
	var kind: String = parts[0]
	var variant: String = parts[1] if parts.size() > 1 else ""
	match kind:
		"enduit":
			m.albedo_texture = _tex("enduit.png")
			m.normal_enabled = true
			m.normal_texture = _tex("enduit_n.png")
			m.normal_scale = 0.7
			m.albedo_color = ENDUITS.get(variant, Color(0.95, 0.92, 0.86))
			m.roughness = 0.93
		"interieur":
			m.albedo_texture = _tex("enduit.png")
			m.albedo_color = Color(0.96, 0.92, 0.84) if variant == "" else ENDUITS.get(variant, Color(0.96, 0.92, 0.84))
			m.roughness = 0.95
		"pierre":
			m.albedo_texture = _tex("dalles.png")
			m.normal_enabled = true
			m.normal_texture = _tex("dalles_n.png")
			m.albedo_color = Color(1.02, 0.98, 0.9) if variant == "" else Color(0.8, 0.78, 0.72)
			m.roughness = 0.88
		"dalles":
			m.albedo_texture = _tex("dalles.png")
			m.normal_enabled = true
			m.normal_texture = _tex("dalles_n.png")
			m.roughness = 0.85
		"paves":
			m.albedo_texture = _tex("paves.png")
			m.normal_enabled = true
			m.normal_texture = _tex("paves_n.png")
			m.normal_scale = 1.2
			m.roughness = 0.82
		"moellons":
			m.albedo_texture = _tex("moellons.png")
			m.normal_enabled = true
			m.normal_texture = _tex("moellons_n.png")
			m.normal_scale = 1.3
			m.albedo_color = Color(0.95, 0.93, 0.88) if variant == "" else Color(0.7, 0.7, 0.68)
		"calcaire":
			m.albedo_texture = _tex("calcaire.png")
			m.normal_enabled = true
			m.normal_texture = _tex("calcaire_n.png")
			m.uv1_triplanar = true
			m.uv1_scale = Vector3.ONE * 0.25
		"tuiles":
			m.albedo_texture = _tex("tuiles.png")
			m.normal_enabled = true
			m.normal_texture = _tex("tuiles_n.png")
			m.normal_scale = 1.4
			m.roughness = 0.86
		"planches":
			m.albedo_texture = _tex("planches.png")
			m.normal_enabled = true
			m.normal_texture = _tex("planches_n.png")
			m.roughness = 0.9
		"bois":
			m.albedo_texture = load("res://assets/textures/doors/wood_plain.png")
			m.albedo_color = Color(0.82, 0.66, 0.5) if variant == "" else (Color(0.45, 0.32, 0.22) if variant == "sombre" else Color(0.95, 0.85, 0.7))
			m.roughness = 0.75
		"fer":
			m.albedo_color = Color(0.08, 0.085, 0.09)
			m.metallic = 0.6
			m.roughness = 0.5
		"laiton":
			m.albedo_color = Color(0.72, 0.56, 0.26)
			m.metallic = 0.85
			m.roughness = 0.35
		"chrome":
			m.albedo_color = Color(0.8, 0.82, 0.85)
			m.metallic = 0.9
			m.roughness = 0.25
		"fenetre", "vitrine":
			m.albedo_texture = _tex(kind + ".png")
			m.roughness = 0.12
			m.metallic_specular = 0.75
			if variant == "nuit":
				m.emission_enabled = true
				m.emission_texture = _tex("fenetre_lum.png") if kind == "fenetre" else _tex("vitrine.png")
				m.emission = Color(1.0, 0.78, 0.48)
				m.emission_energy_multiplier = 0.0
				if temps != null:
					temps.register_glow(m, 1.6 if kind == "fenetre" else 0.9, 0.0)
		"volet":
			m.albedo_texture = _tex("volet.png")
			m.normal_enabled = true
			m.normal_texture = _tex("volet_n.png")
			m.albedo_color = VOLETS.get(variant, VOLETS["vert"])
			m.roughness = 0.7
		"porte":
			m.albedo_texture = _tex("porte.png")
			m.normal_enabled = true
			m.normal_texture = _tex("porte_n.png")
			m.albedo_color = VOLETS.get(variant, VOLETS["vert"])
			m.roughness = 0.6
		"auvent":
			m.albedo_texture = _tex("auvent_" + variant + ".png")
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.5
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.roughness = 0.95
		"balcon", "filet":
			m.albedo_texture = _tex(kind + ".png")
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.4
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.metallic = 0.5 if kind == "balcon" else 0.0
			m.roughness = 0.55 if kind == "balcon" else 0.95
		"tissu":
			var cols := {"rouge": Color(0.75, 0.16, 0.14), "bleu": Color(0.16, 0.32, 0.6), "jaune": Color(0.95, 0.75, 0.2),
				"vert": Color(0.2, 0.5, 0.3), "blanc": Color(0.94, 0.93, 0.9), "rose": Color(0.92, 0.5, 0.6), "turquoise": Color(0.1, 0.6, 0.62),
				"orange": Color(0.92, 0.48, 0.16), "creme": Color(0.92, 0.86, 0.72), "noir": Color(0.1, 0.1, 0.11),
				"bordeaux": Color(0.45, 0.08, 0.12), "or": Color(0.85, 0.66, 0.3)}
			m.albedo_color = cols.get(variant, Color(0.8, 0.8, 0.8))
			m.roughness = 0.95
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"image":
			# une image de la ville (tableau, affiche) : variant = nom du fichier sans .png
			m.albedo_texture = _tex(variant + ".png")
			m.roughness = 0.7
		"chaume":
			m.albedo_texture = load("res://assets/textures/jungle/thatch.png")
			m.roughness = 0.95
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"peinture":
			var pc := {"blanc": Color(0.95, 0.95, 0.93), "rouge": Color(0.72, 0.12, 0.1), "bleu": Color(0.12, 0.28, 0.55),
				"vert": Color(0.15, 0.42, 0.28), "jaune": Color(0.95, 0.72, 0.15), "noir": Color(0.07, 0.07, 0.08), "bois": Color(0.6, 0.45, 0.3),
				"turquoise": Color(0.1, 0.55, 0.58), "gris": Color(0.5, 0.52, 0.54), "creme": Color(0.94, 0.9, 0.8), "orange": Color(0.9, 0.42, 0.12)}
			m.albedo_color = pc.get(variant, Color(0.9, 0.9, 0.9))
			m.roughness = 0.45
		"verre":
			m.albedo_color = Color(0.85, 0.92, 0.95, 0.25)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.roughness = 0.05
			m.metallic_specular = 0.9
		"lampe":
			m.albedo_color = Color(1.0, 0.92, 0.75, 0.85)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.emission_enabled = true
			m.emission = Color(1.0, 0.8, 0.5)
			m.emission_energy_multiplier = 0.0
			if temps != null:
				temps.register_glow(m, 4.0, 0.15)
		"eau":
			m.albedo_color = Color(0.3, 0.55, 0.6, 0.6)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.normal_enabled = true
			m.normal_texture = load("res://assets/textures/water/water_n.png")
			m.normal_scale = 0.5
			m.roughness = 0.05
			m.metallic_specular = 0.8
		"feuillage":
			m.albedo_color = Color(0.28, 0.42, 0.2)
			m.roughness = 0.9
		"terre":
			m.albedo_texture = _tex("terre_garrigue.png")
			m.roughness = 0.95
		"sable":
			m.albedo_texture = _tex("sable_azur.png")
			m.roughness = 0.95
		_:
			m.albedo_color = Color(1, 0, 1)
	mats[key] = m
	return m


# =================================================================== géométrie regroupée

func _st(key: String) -> SurfaceTool:
	if not batch.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		batch[key] = st
	return batch[key]


## Un triangle, retourné au besoin pour que sa face avant regarde du côté de n.
func tri(key: String, a: Vector3, b: Vector3, c: Vector3, n: Vector3, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	var st: SurfaceTool = _st(key)
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t: Vector3 = b
		b = c
		c = t
		var tu: Vector2 = ub
		ub = uc
		uc = tu
	for v in [[a, ua], [b, ub], [c, uc]]:
		st.set_normal(n)
		st.set_uv(v[1])
		st.add_vertex(v[0])


## Un quadrilatère (p0 p1 p2 p3 dans l'ordre du tour), normale n.
func quad4(key: String, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, n: Vector3, u0: Vector2, u1: Vector2, u2: Vector2, u3: Vector2) -> void:
	tri(key, p0, p1, p2, n, u0, u1, u2)
	tri(key, p0, p2, p3, n, u0, u2, u3)


## Rectangle vertical dans le plan XY local, centré, qui regarde -Z (ou les deux côtés).
func quad(xf: Transform3D, w: float, h: float, key: String, uv0: Vector2 = Vector2(0, 0), uv1: Vector2 = Vector2(1, 1), both: bool = false) -> void:
	var n: Vector3 = (xf.basis * Vector3(0, 0, -1)).normalized()
	var p0: Vector3 = xf * Vector3(-w / 2, -h / 2, 0)
	var p1: Vector3 = xf * Vector3(w / 2, -h / 2, 0)
	var p2: Vector3 = xf * Vector3(w / 2, h / 2, 0)
	var p3: Vector3 = xf * Vector3(-w / 2, h / 2, 0)
	# vu de face (depuis -Z), x local va vers la gauche de l'observateur : on inverse u
	quad4(key, p0, p1, p2, p3, n, Vector2(uv1.x, uv1.y), Vector2(uv0.x, uv1.y), Vector2(uv0.x, uv0.y), Vector2(uv1.x, uv0.y))
	if both:
		quad4(key, p0, p1, p2, p3, -n, Vector2(uv0.x, uv1.y), Vector2(uv1.x, uv1.y), Vector2(uv1.x, uv0.y), Vector2(uv0.x, uv0.y))


## Boîte centrée sur xf.origin. tile : taille (m) d'une répétition de texture.
## faces : 1 +X, 2 -X, 4 +Y, 8 -Y, 16 +Z, 32 -Z.
func box(xf: Transform3D, size: Vector3, key: String, tile: float = 2.0, faces: int = 63) -> void:
	var h: Vector3 = size * 0.5
	var b: Basis = xf.basis
	var defs := [
		[1, Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0), size.z, size.y],
		[2, Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0), size.z, size.y],
		[4, Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1), size.x, size.z],
		[8, Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, -1), size.x, size.z],
		[16, Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0), size.x, size.y],
		[32, Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0), size.x, size.y],
	]
	for d in defs:
		if (faces & int(d[0])) == 0:
			continue
		var n: Vector3 = d[1]
		var u: Vector3 = d[2]
		var v: Vector3 = d[3]
		var c: Vector3 = Vector3(n.x * h.x, n.y * h.y, n.z * h.z)
		var hu: Vector3 = Vector3(u.x * h.x, u.y * h.y, u.z * h.z)
		var hv: Vector3 = Vector3(v.x * h.x, v.y * h.y, v.z * h.z)
		var uw: float = float(d[4]) / tile
		var vh: float = float(d[5]) / tile
		var p0: Vector3 = xf * (c - hu - hv)
		var p1: Vector3 = xf * (c + hu - hv)
		var p2: Vector3 = xf * (c + hu + hv)
		var p3: Vector3 = xf * (c - hu + hv)
		var nw: Vector3 = (b * n).normalized()
		quad4(key, p0, p1, p2, p3, nw, Vector2(0, vh), Vector2(uw, vh), Vector2(uw, 0), Vector2(0, 0))


## Cylindre (ou cône tronqué) posé sur xf.origin, vers +Y local.
func cyl(xf: Transform3D, r0: float, r1: float, h: float, key: String, seg: int = 12, caps: bool = true, tile: float = 1.5) -> void:
	var circ: float = TAU * maxf(r0, r1)
	for i in range(seg):
		var a0: float = TAU * i / seg
		var a1: float = TAU * (i + 1) / seg
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var slope: float = (r0 - r1) / maxf(h, 0.001)
		var n0: Vector3 = (xf.basis * (d0 + Vector3.UP * slope)).normalized()
		var n1: Vector3 = (xf.basis * (d1 + Vector3.UP * slope)).normalized()
		var nm: Vector3 = (n0 + n1).normalized()
		var p0: Vector3 = xf * (d0 * r0)
		var p1: Vector3 = xf * (d1 * r0)
		var p2: Vector3 = xf * (d1 * r1 + Vector3.UP * h)
		var p3: Vector3 = xf * (d0 * r1 + Vector3.UP * h)
		var u0: float = float(i) / seg * circ / tile
		var u1: float = float(i + 1) / seg * circ / tile
		quad4(key, p0, p1, p2, p3, nm, Vector2(u0, h / tile), Vector2(u1, h / tile), Vector2(u1, 0), Vector2(u0, 0))
		if caps:
			var up: Vector3 = (xf.basis * Vector3.UP).normalized()
			if r1 > 0.001:
				tri(key, xf * (Vector3.UP * h), p3, p2, up, Vector2(0.5, 0.5), Vector2(0.5 + d0.x * 0.5, 0.5 + d0.z * 0.5), Vector2(0.5 + d1.x * 0.5, 0.5 + d1.z * 0.5))
			if r0 > 0.001:
				tri(key, xf * Vector3.ZERO, p0, p1, -up, Vector2(0.5, 0.5), Vector2(0.5 + d0.x * 0.5, 0.5 + d0.z * 0.5), Vector2(0.5 + d1.x * 0.5, 0.5 + d1.z * 0.5))


## Anneau épais (margelle de fontaine, bordure ronde).
func ring(xf: Transform3D, r_in: float, r_out: float, h: float, key: String, seg: int = 32) -> void:
	for i in range(seg):
		var a0: float = TAU * i / seg
		var a1: float = TAU * (i + 1) / seg
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var up: Vector3 = (xf.basis * Vector3.UP).normalized()
		var u0: float = float(i) / seg * 6.0
		var u1: float = float(i + 1) / seg * 6.0
		# dessus
		quad4(key, xf * (d0 * r_in + Vector3.UP * h), xf * (d1 * r_in + Vector3.UP * h), xf * (d1 * r_out + Vector3.UP * h), xf * (d0 * r_out + Vector3.UP * h), up, Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, 0.3), Vector2(u0, 0.3))
		# extérieur
		var no: Vector3 = (xf.basis * ((d0 + d1) * 0.5)).normalized()
		quad4(key, xf * (d0 * r_out), xf * (d1 * r_out), xf * (d1 * r_out + Vector3.UP * h), xf * (d0 * r_out + Vector3.UP * h), no, Vector2(u0, h), Vector2(u1, h), Vector2(u1, 0), Vector2(u0, 0))
		# intérieur
		quad4(key, xf * (d0 * r_in), xf * (d1 * r_in), xf * (d1 * r_in + Vector3.UP * h), xf * (d0 * r_in + Vector3.UP * h), -no, Vector2(u0, h), Vector2(u1, h), Vector2(u1, 0), Vector2(u0, 0))


## Disque horizontal (plan d'eau, plateau de table).
func disc(xf: Transform3D, r: float, key: String, seg: int = 24, tile: float = 2.0) -> void:
	var up: Vector3 = (xf.basis * Vector3.UP).normalized()
	for i in range(seg):
		var a0: float = TAU * i / seg
		var a1: float = TAU * (i + 1) / seg
		var p0 := Vector3(cos(a0) * r, 0, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, 0, sin(a1) * r)
		tri(key, xf * Vector3.ZERO, xf * p0, xf * p1, up, Vector2(0, 0), Vector2(p0.x, p0.z) / tile, Vector2(p1.x, p1.z) / tile)


## Toit à deux pans (faîtage parallèle à X), posé sur xf.origin = milieu du haut des murs.
func roof_gable(xf: Transform3D, w: float, d: float, pitch_deg: float, over: float, key: String, gable_key: String) -> float:
	var rise: float = (d * 0.5 + over) * tan(deg_to_rad(pitch_deg))
	var hw: float = w * 0.5 + over * 0.6
	var hd: float = d * 0.5 + over
	var ridge := Vector3(0, rise, 0)
	var tile: float = 2.4
	for s in [-1.0, 1.0]:
		var e0 := Vector3(-hw, 0, s * hd)
		var e1 := Vector3(hw, 0, s * hd)
		var r0 := Vector3(-hw, rise, 0)
		var r1 := Vector3(hw, rise, 0)
		var n: Vector3 = (xf.basis * Vector3(0, hd, s * rise).normalized()).normalized()
		var slope_len: float = Vector2(hd, rise).length()
		quad4(key, xf * e0, xf * e1, xf * r1, xf * r0, n, Vector2(0, slope_len / tile), Vector2(w / tile, slope_len / tile), Vector2(w / tile, 0), Vector2(0, 0))
		# dessous de la saillie (planches sombres)
		quad4("bois_sombre", xf * (e0 + Vector3(0, -0.02, 0)), xf * (e1 + Vector3(0, -0.02, 0)), xf * Vector3(hw, -0.02, s * d * 0.5), xf * Vector3(-hw, -0.02, s * d * 0.5), xf.basis * Vector3.DOWN, Vector2(0, 0), Vector2(w / 2, 0), Vector2(w / 2, 0.3), Vector2(0, 0.3))
	# pignons
	for sx in [-1.0, 1.0]:
		var gx: float = sx * w * 0.5
		var n2: Vector3 = (xf.basis * Vector3(sx, 0, 0)).normalized()
		tri(gable_key, xf * Vector3(gx, 0, -d * 0.5), xf * Vector3(gx, 0, d * 0.5), xf * Vector3(gx, rise - 0.05, 0), n2, Vector2(0, 1), Vector2(d / 3.0, 1), Vector2(d / 6.0, 1.0 - rise / 3.0))
		# rive de toit (bout des tuiles)
		quad4(key, xf * Vector3(sx * hw, 0, -hd), xf * Vector3(sx * hw, 0, hd), xf * Vector3(sx * hw, rise, 0), xf * Vector3(sx * hw, rise, 0), n2, Vector2(0, 0.2), Vector2(1, 0.2), Vector2(0.5, 0), Vector2(0.5, 0))
	# faîtage : une rangée de tuiles rondes, d'une rive à l'autre (V67 : elle partait vers
	# l'extérieur du pignon et dépassait du toit de toute sa longueur)
	cyl(Transform3D(xf.basis * Basis(Vector3.BACK, -PI / 2.0), xf * Vector3(-hw, rise - 0.02, 0)), 0.11, 0.11, w + over * 1.2, key, 8, false, 0.6)
	return rise


## Toit à quatre pans (croupe), faîtage parallèle à X.
func roof_hip(xf: Transform3D, w: float, d: float, pitch_deg: float, over: float, key: String) -> float:
	var hw: float = w * 0.5 + over
	var hd: float = d * 0.5 + over
	var rise: float = hd * tan(deg_to_rad(pitch_deg))
	var ridge_half: float = maxf(hw - hd, 0.0)
	var tile: float = 2.4
	var r0 := Vector3(-ridge_half, rise, 0)
	var r1 := Vector3(ridge_half, rise, 0)
	var c00 := Vector3(-hw, 0, -hd)
	var c10 := Vector3(hw, 0, -hd)
	var c11 := Vector3(hw, 0, hd)
	var c01 := Vector3(-hw, 0, hd)
	var nf: Vector3 = (xf.basis * Vector3(0, hd, -rise).normalized()).normalized()
	var nb: Vector3 = (xf.basis * Vector3(0, hd, rise).normalized()).normalized()
	var nl: Vector3 = (xf.basis * Vector3(-rise, hd, 0).normalized()).normalized()
	var nr: Vector3 = (xf.basis * Vector3(rise, hd, 0).normalized()).normalized()
	var sl: float = Vector2(hd, rise).length() / tile
	quad4(key, xf * c00, xf * c10, xf * r1, xf * r0, nf, Vector2(0, sl), Vector2(w / tile, sl), Vector2((hw + ridge_half) / tile, 0), Vector2((hw - ridge_half) / tile, 0))
	quad4(key, xf * c11, xf * c01, xf * r0, xf * r1, nb, Vector2(0, sl), Vector2(w / tile, sl), Vector2((hw + ridge_half) / tile, 0), Vector2((hw - ridge_half) / tile, 0))
	tri(key, xf * c01, xf * c00, xf * r0, nl, Vector2(0, sl), Vector2(d / tile, sl), Vector2(d * 0.5 / tile, 0))
	tri(key, xf * c10, xf * c11, xf * r1, nr, Vector2(0, sl), Vector2(d / tile, sl), Vector2(d * 0.5 / tile, 0))
	for e in [[c00, c10], [c10, c11], [c11, c01], [c01, c00]]:
		pass
	quad4("bois_sombre", xf * (c00 + Vector3.DOWN * 0.02), xf * (c10 + Vector3.DOWN * 0.02), xf * (c11 + Vector3.DOWN * 0.02), xf * (c01 + Vector3.DOWN * 0.02), xf.basis * Vector3.DOWN, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
	if ridge_half > 0.01:
		cyl(Transform3D(xf.basis * Basis(Vector3.BACK, PI / 2.0), xf * Vector3(-ridge_half - 0.1, rise - 0.02, 0)), 0.11, 0.11, ridge_half * 2.0 + 0.2, key, 8, false, 0.6)
	return rise


# =================================================================== collisions

func col_box(xf: Transform3D, size: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	cs.shape = s
	cs.transform = xf
	body.add_child(cs)


func col_cyl(pos: Vector3, r: float, h: float) -> void:
	var cs := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = r
	s.height = h
	cs.shape = s
	cs.position = pos + Vector3.UP * h * 0.5
	body.add_child(cs)


# =================================================================== fin : les maillages

func commit() -> void:
	for key in batch:
		var st: SurfaceTool = batch[key]
		var m: Material = mat(key)
		if m is StandardMaterial3D and (m as StandardMaterial3D).normal_enabled:
			st.generate_tangents()
		var mesh: ArrayMesh = st.commit()
		var mi := MeshInstance3D.new()
		mi.name = "Ville_" + str(key)
		mi.mesh = mesh
		mi.material_override = m
		var transparent: bool = m is StandardMaterial3D and (m as StandardMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_ALPHA
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if transparent or str(key).begins_with("lampe") else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mi.visibility_range_end = 900.0
		root.add_child(mi)
	batch.clear()


# =================================================================== éléments de façade

## Fenêtre avec encadrement de pierre, appui, volets (ouverts ou clos). xf : centre de la
## fenêtre, posé sur le nu du mur (qui regarde -Z).
func window(xf: Transform3D, w: float, h: float, volets: String, lit: bool, closed: bool = false, french: bool = false) -> void:
	var glass_key: String = "fenetre_nuit" if lit else "fenetre"
	if closed:
		quad(xf * Transform3D(Basis(), Vector3(-w / 4, 0, -0.03)), w / 2, h, "volet_" + volets)
		quad(xf * Transform3D(Basis(), Vector3(w / 4, 0, -0.03)), w / 2, h, "volet_" + volets)
	else:
		quad(xf * Transform3D(Basis(), Vector3(0, 0, -0.012)), w, h, glass_key)
		if volets != "":
			for s in [-1.0, 1.0]:
				var ang: float = deg_to_rad(rng.randf_range(150.0, 178.0)) * s
				var hinge := Vector3(s * (w / 2 + 0.07), 0, -0.02)
				var b := Basis(Vector3.UP, -ang)
				quad(xf * Transform3D(b, hinge + b * Vector3(-s * w / 4, 0, 0)), w / 2, h, "volet_" + volets, Vector2(0, 0), Vector2(1, 1), true)
	# encadrement et appui
	box(xf * Transform3D(Basis(), Vector3(0, h / 2 + 0.08, -0.04)), Vector3(w + 0.3, 0.16, 0.1), "pierre", 1.5)
	box(xf * Transform3D(Basis(), Vector3(-w / 2 - 0.06, 0, -0.03)), Vector3(0.12, h, 0.08), "pierre", 1.5)
	box(xf * Transform3D(Basis(), Vector3(w / 2 + 0.06, 0, -0.03)), Vector3(0.12, h, 0.08), "pierre", 1.5)
	if not french:
		box(xf * Transform3D(Basis(), Vector3(0, -h / 2 - 0.05, -0.08)), Vector3(w + 0.34, 0.08, 0.2), "pierre", 1.5)


## Balcon de fer forgé : dalle de pierre, garde-corps sur trois côtés.
func balcony(xf: Transform3D, w: float, depth: float = 0.75) -> void:
	box(xf * Transform3D(Basis(), Vector3(0, -0.06, -depth / 2)), Vector3(w, 0.12, depth), "pierre", 1.5)
	var rail_h: float = 0.95
	quad(xf * Transform3D(Basis(), Vector3(0, rail_h / 2, -depth + 0.02)), w, rail_h, "balcon", Vector2(0, 0), Vector2(w / 1.6, 1.0), true)
	for s in [-1.0, 1.0]:
		quad(xf * Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(s * (w / 2 - 0.02), rail_h / 2, -depth / 2)), depth, rail_h, "balcon", Vector2(0, 0), Vector2(depth / 1.6, 1.0), true)
	# consoles
	for s in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(s * (w / 2 - 0.2), -0.25, -0.2)), Vector3(0.12, 0.3, 0.35), "pierre", 1.5)


## Store banne rayé, de travers au-dessus d'une devanture (xf : milieu du haut, sur le mur).
func awning(xf: Transform3D, w: float, out: float, drop: float, color: String) -> void:
	var key: String = "auvent_" + color
	var n: Vector3 = (xf.basis * Vector3(0, out, -drop).cross(Vector3.RIGHT)).normalized()
	var p0: Vector3 = xf * Vector3(-w / 2, 0, -0.05)
	var p1: Vector3 = xf * Vector3(w / 2, 0, -0.05)
	var p2: Vector3 = xf * Vector3(w / 2, -drop, -out)
	var p3: Vector3 = xf * Vector3(-w / 2, -drop, -out)
	var nn: Vector3 = (xf.basis * Vector3(0, out, drop).normalized()).normalized()
	nn = (xf.basis * Vector3(0, 1, 0)).normalized() if nn.y < 0 else nn
	quad4(key, p0, p1, p2, p3, nn, Vector2(0, 0.0), Vector2(w / 1.0, 0.0), Vector2(w / 1.0, 0.85), Vector2(0, 0.85))
	# lambrequin festonné
	quad(xf * Transform3D(Basis(), Vector3(0, -drop - 0.16, -out)), w, 0.32, key, Vector2(0, 0.82), Vector2(w / 1.0, 1.0), true)
	# bras
	for s in [-1.0, 1.0]:
		var a: Vector3 = xf * Vector3(s * (w / 2 - 0.1), -0.9, -0.05)
		var b2: Vector3 = xf * Vector3(s * (w / 2 - 0.1), -drop, -out)
		var mid: Vector3 = (a + b2) * 0.5
		var dir: Vector3 = (b2 - a)
		var bas := Basis.looking_at(dir.normalized(), Vector3.UP)
		box(Transform3D(bas, mid), Vector3(0.03, 0.03, dir.length()), "fer", 1.0)


## Enseigne peinte : un panneau avec sa propre texture (un MeshInstance par enseigne).
func sign_board(xf: Transform3D, w: float, h: float, sign_id: String, hanging: bool = false) -> void:
	box(xf, Vector3(w + 0.08, h + 0.08, 0.06), "bois_sombre", 1.0)
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex("enseigne_%s.png" % sign_id)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.3
	m.roughness = 0.6
	m.emission_enabled = true
	m.emission_texture = m.albedo_texture
	m.emission = Color(1, 1, 1)
	m.emission_energy_multiplier = 0.0
	if temps != null:
		temps.register_glow(m, 0.35, 0.0)
	var qm := QuadMesh.new()
	qm.size = Vector2(w, h)
	var mi := MeshInstance3D.new()
	mi.name = "Enseigne_" + sign_id
	mi.mesh = qm
	mi.material_override = m
	mi.transform = xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -0.035))
	root.add_child(mi)
	signs.append(mi)
	if hanging:
		var mi2 := mi.duplicate() as MeshInstance3D
		mi2.transform = xf * Transform3D(Basis(), Vector3(0, 0, 0.035))
		root.add_child(mi2)


## Lampadaire de fonte (lanterne en haut d'un fût) ; une vraie lumière la nuit.
func lamppost(pos: Vector3, yaw: float, with_light: bool = true, h: float = 3.6) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw), pos)
	cyl(xf, 0.16, 0.12, 0.45, "fer", 10)
	cyl(xf * Transform3D(Basis(), Vector3(0, 0.45, 0)), 0.07, 0.05, h - 0.9, "fer", 8)
	cyl(xf * Transform3D(Basis(), Vector3(0, h - 0.45, 0)), 0.09, 0.06, 0.1, "fer", 8)
	# lanterne : chapeau, verre, socle
	var top: Vector3 = Vector3(0, h - 0.35, 0)
	cyl(xf * Transform3D(Basis(), top), 0.13, 0.17, 0.08, "fer", 6)
	cyl(xf * Transform3D(Basis(), top + Vector3(0, 0.08, 0)), 0.17, 0.2, 0.38, "lampe", 6, false)
	cyl(xf * Transform3D(Basis(), top + Vector3(0, 0.46, 0)), 0.24, 0.02, 0.2, "fer", 6)
	col_cyl(pos, 0.15, h)
	if with_light and temps != null:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.78, 0.5)
		l.omni_range = 10.0
		l.omni_attenuation = 1.3
		l.shadow_enabled = false
		l.light_volumetric_fog_energy = 0.6
		l.position = pos + Vector3(0, h - 0.1, 0)
		root.add_child(l)
		temps.register_lamp(l, 1.8)
		lamp_count += 1


func bench(xf: Transform3D) -> void:
	for s in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(s * 0.75, 0.22, 0)), Vector3(0.06, 0.44, 0.5), "fer", 1.0)
		box(xf * Transform3D(Basis(Vector3.RIGHT, -0.25), Vector3(s * 0.75, 0.62, 0.22)), Vector3(0.06, 0.45, 0.06), "fer", 1.0)
	for k in range(3):
		box(xf * Transform3D(Basis(), Vector3(0, 0.45, -0.18 + k * 0.15)), Vector3(1.7, 0.04, 0.12), "bois", 1.2)
	for k in range(2):
		box(xf * Transform3D(Basis(Vector3.RIGHT, -0.25), Vector3(0, 0.62 + k * 0.16, 0.24 + k * 0.04)), Vector3(1.7, 0.1, 0.03), "bois", 1.2)
	col_box(xf * Transform3D(Basis(), Vector3(0, 0.3, 0)), Vector3(1.7, 0.6, 0.55))


## Table de bistrot ronde et ses chaises (n chaises autour).
func cafe_table(pos: Vector3, yaw: float, chairs: int = 2, parasol: String = "") -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw), pos)
	cyl(xf, 0.22, 0.2, 0.03, "fer", 10)
	cyl(xf, 0.03, 0.03, 0.72, "fer", 6, false)
	cyl(xf * Transform3D(Basis(), Vector3(0, 0.72, 0)), 0.36, 0.36, 0.03, "pierre", 18)
	for i in range(chairs):
		var a: float = TAU * i / chairs + 0.3
		var cp := Vector3(cos(a) * 0.62, 0, sin(a) * 0.62)
		var cb := Basis(Vector3.UP, -a - PI / 2.0)
		var cx := xf * Transform3D(cb, cp)
		for lx in [-0.18, 0.18]:
			for lz in [-0.18, 0.18]:
				box(cx * Transform3D(Basis(), Vector3(lx, 0.22, lz)), Vector3(0.03, 0.44, 0.03), "fer", 1.0)
		box(cx * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(0.42, 0.04, 0.42), "bois", 1.0)
		box(cx * Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3(0, 0.72, 0.2)), Vector3(0.42, 0.4, 0.03), "bois", 1.0)
	col_cyl(pos, 0.38, 0.75)
	if parasol != "":
		cyl(xf * Transform3D(Basis(), Vector3(0, 0.72, 0)), 0.025, 0.025, 1.6, "bois_clair", 6, false)
		umbrella(xf * Transform3D(Basis(), Vector3(0, 2.3, 0)), 1.35, 0.45, parasol)


## Toile de parasol octogonale (xf : sommet).
func umbrella(xf: Transform3D, r: float, drop: float, color: String) -> void:
	var key: String = "auvent_" + color
	for i in range(8):
		var a0: float = TAU * i / 8.0
		var a1: float = TAU * (i + 1) / 8.0
		var p0 := Vector3(cos(a0) * r, -drop, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, -drop, sin(a1) * r)
		var n: Vector3 = (xf.basis * (p1 - Vector3.ZERO).cross(p0 - Vector3.ZERO)).normalized()
		if n.y < 0.0:
			n = -n
		tri(key, xf * Vector3(0, 0.02, 0), xf * p0, xf * p1, n, Vector2(i % 2 * 0.5, 0.0), Vector2(0.0, 0.8), Vector2(0.5, 0.8))


## Bitte d'amarrage en fonte.
func bollard(pos: Vector3) -> void:
	var xf := Transform3D(Basis(), pos)
	cyl(xf, 0.17, 0.15, 0.4, "fer", 10)
	cyl(xf * Transform3D(Basis(), Vector3(0, 0.4, 0)), 0.22, 0.22, 0.08, "fer", 10)
	col_cyl(pos, 0.2, 0.5)


## V66 : caisses et tonneaux se cassent (cassable_v66.gd) ; fixe = true pour ceux qui servent
## de table, de siège ou d'appui (ils restent dans la géométrie regroupée de la ville).
func crate(pos: Vector3, yaw: float, s: float = 0.7, fixe: bool = false) -> void:
	if not fixe and root != null:
		Cassable.spawn(root, "caisse", pos, yaw, s)
		return
	var xf := Transform3D(Basis(Vector3.UP, yaw), pos + Vector3.UP * s * 0.5)
	box(xf, Vector3(s, s, s), "bois", 0.7)
	for k in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(0, k * s * 0.42, -s * 0.51)), Vector3(s * 1.02, 0.07, 0.02), "bois_sombre", 0.7)
	col_box(xf, Vector3(s, s, s))


func barrel(pos: Vector3, fixe: bool = false) -> void:
	if not fixe and root != null:
		# (angle tiré de la position : le hasard de la ville reste le même qu'avant)
		Cassable.spawn(root, "tonneau", pos, fposmod(pos.x * 12.9898 + pos.z * 78.233, TAU), 1.0)
		return
	var xf := Transform3D(Basis(), pos)
	cyl(xf, 0.3, 0.34, 0.45, "bois", 12)
	cyl(xf * Transform3D(Basis(), Vector3(0, 0.45, 0)), 0.34, 0.3, 0.45, "bois", 12)
	for y in [0.12, 0.45, 0.78]:
		cyl(xf * Transform3D(Basis(), Vector3(0, y, 0)), 0.33 + 0.02, 0.33 + 0.02, 0.04, "fer", 12, false)
	col_cyl(pos, 0.34, 0.9)


## Pot de fleurs en terre cuite (la plante est ajoutée par la végétation).
func planter(pos: Vector3, r: float = 0.4) -> void:
	var xf := Transform3D(Basis(), pos)
	cyl(xf, r * 0.75, r, r * 1.3, "peinture_orange", 12)
	disc(xf * Transform3D(Basis(), Vector3(0, r * 1.2, 0)), r * 0.95, "terre", 12)
	col_cyl(pos, r, r * 1.3)


# =================================================================== bâtiments

## Une maison ou une boutique. spec :
##  w, d, floors (hauteurs), color, volets, roof ("gable", "hip", "flat"), rdc ("porte",
##  "boutique", "bar", "aveugle", "hall"), enseigne, auvent, balcons (étages), lit (0..1),
##  door_x (position de la porte, sinon au milieu), shutters_closed (0..1)
## Renvoie {door: Vector3 monde devant la porte, top: hauteur des murs}.
func building(xf: Transform3D, spec: Dictionary) -> Dictionary:
	var w: float = float(spec.get("w", 8.0))
	var d: float = float(spec.get("d", 10.0))
	var floors: Array = spec.get("floors", [3.6, 3.0])
	var color: String = str(spec.get("color", "ocre"))
	var volets: String = str(spec.get("volets", "vert"))
	var wall_key: String = "enduit_" + color
	var hsum: float = 0.0
	for f in floors:
		hsum += float(f)
	var walkin: Dictionary = spec.get("interieur", {})
	var gf: float = float(floors[0])
	# murs
	if walkin.is_empty():
		box(xf * Transform3D(Basis(), Vector3(0, hsum / 2, d / 2)), Vector3(w, hsum, d), wall_key, 3.0, 63 - 8)
		col_box(xf * Transform3D(Basis(), Vector3(0, hsum / 2, d / 2)), Vector3(w, hsum, d))
	else:
		_hollow_ground_floor(xf, w, d, gf, wall_key, walkin)
		box(xf * Transform3D(Basis(), Vector3(0, gf + (hsum - gf) / 2, d / 2)), Vector3(w, hsum - gf, d), wall_key, 3.0, 63 - 8)
		col_box(xf * Transform3D(Basis(), Vector3(0, gf + (hsum - gf) / 2, d / 2)), Vector3(w, hsum - gf, d))
	# soubassement et bandeaux
	box(xf * Transform3D(Basis(), Vector3(0, 0.3, -0.03)), Vector3(w + 0.04, 0.6, 0.08), "pierre_sombre", 1.5, 63 - 8 - 16)
	var y: float = 0.0
	for i in range(floors.size()):
		y += float(floors[i])
		if i < floors.size() - 1:
			box(xf * Transform3D(Basis(), Vector3(0, y, -0.05)), Vector3(w + 0.12, 0.16, 0.12), "pierre", 1.5)
	# génoise sous le toit, devant et derrière
	box(xf * Transform3D(Basis(), Vector3(0, hsum - 0.12, -0.12)), Vector3(w + 0.3, 0.26, 0.26), "pierre", 1.2)
	box(xf * Transform3D(Basis(), Vector3(0, hsum - 0.12, d + 0.12)), Vector3(w + 0.3, 0.26, 0.26), "pierre", 1.2)
	# toit
	var roof: String = str(spec.get("roof", "gable"))
	var top_xf: Transform3D = xf * Transform3D(Basis(), Vector3(0, hsum, d / 2))
	match roof:
		"hip":
			roof_hip(top_xf, w, d, 20.0, 0.45, "tuiles")
		"flat":
			box(xf * Transform3D(Basis(), Vector3(0, hsum + 0.45, -0.1 + 0.2)), Vector3(w + 0.1, 0.9, 0.4), wall_key, 3.0)
			box(xf * Transform3D(Basis(), Vector3(0, hsum + 0.45, d - 0.1)), Vector3(w + 0.1, 0.9, 0.4), wall_key, 3.0)
			box(xf * Transform3D(Basis(), Vector3(0, hsum + 0.04, d / 2)), Vector3(w, 0.08, d), "dalles", 3.0, 4)
		_:
			roof_gable(top_xf, w, d, 19.0, 0.45, "tuiles", wall_key)
	# cheminée
	if rng.randf() < 0.7 and roof != "flat":
		var cx: float = rng.randf_range(-w * 0.3, w * 0.3)
		var cz: float = d * rng.randf_range(0.55, 0.8)
		var ch_h: float = hsum + (d * 0.5) * tan(deg_to_rad(19.0)) * 0.6 + 1.1
		box(xf * Transform3D(Basis(), Vector3(cx, ch_h - 1.2, cz)), Vector3(0.6, 2.4, 0.6), wall_key, 2.0)
		box(xf * Transform3D(Basis(), Vector3(cx, ch_h + 0.05, cz)), Vector3(0.75, 0.1, 0.75), "tuiles", 1.0)
	# rez-de-chaussée
	var rdc: String = str(spec.get("rdc", "porte"))
	var door_x: float = float(spec.get("door_x", 0.0))
	var lit_p: float = float(spec.get("lit", 0.45))
	var out := {"top": hsum}
	var porte_col: String = str(spec.get("porte", volets))
	match rdc:
		"boutique":
			var vw: float = minf(w - 2.6, 4.2)
			var vx: float = -0.7 if door_x >= 0.0 else 0.7
			quad(xf * Transform3D(Basis(), Vector3(vx - (0.0 if door_x >= 0.0 else 0.0), 1.55, -0.02)), vw, 2.2, "vitrine_nuit" if rng.randf() < 0.7 else "vitrine")
			box(xf * Transform3D(Basis(), Vector3(vx, 1.55, -0.05)), Vector3(vw + 0.24, 2.44, 0.06), "bois_sombre", 1.0, 32)
			var dx2: float = vx + (vw / 2 + 0.9) * (1.0 if door_x >= 0.0 else -1.0)
			quad(xf * Transform3D(Basis(), Vector3(dx2, 1.2, -0.02)), 1.1, 2.4, "porte_" + porte_col)
			box(xf * Transform3D(Basis(), Vector3(dx2, 2.46, -0.05)), Vector3(1.3, 0.12, 0.1), "pierre", 1.0)
			if spec.has("auvent"):
				awning(xf * Transform3D(Basis(), Vector3(vx * 0.5 + dx2 * 0.5, 3.05, 0)), vw + 1.8, 1.7, 0.75, str(spec["auvent"]))
			if spec.has("enseigne"):
				sign_board(xf * Transform3D(Basis(), Vector3(0, gf - 0.3, -0.06)), minf(w - 0.6, 4.6), minf(w - 0.6, 4.6) / 4.0, str(spec["enseigne"]))
			out["door"] = xf * Vector3(dx2, 0, -1.1)
		"bar":
			for k in range(3):
				var ax: float = (k - 1) * (w / 3.2)
				quad(xf * Transform3D(Basis(), Vector3(ax, 1.4, -0.02)), w / 4.2, 2.6, "vitrine_nuit")
				box(xf * Transform3D(Basis(), Vector3(ax, 2.78, -0.05)), Vector3(w / 4.2 + 0.25, 0.16, 0.1), "pierre", 1.0)
			if spec.has("auvent"):
				awning(xf * Transform3D(Basis(), Vector3(0, 3.1, 0)), w - 0.6, 2.4, 0.8, str(spec["auvent"]))
			if spec.has("enseigne"):
				sign_board(xf * Transform3D(Basis(), Vector3(0, gf - 0.25, -0.06)), minf(w - 0.8, 5.2), minf(w - 0.8, 5.2) / 4.0, str(spec["enseigne"]))
			out["door"] = xf * Vector3(0, 0, -1.1)
		"hall":
			pass
		"aveugle":
			out["door"] = xf * Vector3(0, 0, -1.0)
			var ddx: float = float(walkin.get("door_x", 0.0))
			if spec.has("auvent"):
				awning(xf * Transform3D(Basis(), Vector3(0, 3.1, 0)), w - 0.8, 2.2, 0.8, str(spec["auvent"]))
			if spec.has("enseigne"):
				sign_board(xf * Transform3D(Basis(), Vector3(ddx, gf - 0.3, -0.06)), minf(w - 0.8, 5.0), minf(w - 0.8, 5.0) / 4.0, str(spec["enseigne"]))
		_:
			# porte de maison et une ou deux fenêtres
			quad(xf * Transform3D(Basis(), Vector3(door_x, 1.2, -0.02)), 1.1, 2.4, "porte_" + porte_col)
			box(xf * Transform3D(Basis(), Vector3(door_x, 2.5, -0.05)), Vector3(1.4, 0.16, 0.1), "pierre", 1.0)
			box(xf * Transform3D(Basis(), Vector3(door_x - 0.62, 1.25, -0.04)), Vector3(0.14, 2.5, 0.08), "pierre", 1.0)
			box(xf * Transform3D(Basis(), Vector3(door_x + 0.62, 1.25, -0.04)), Vector3(0.14, 2.5, 0.08), "pierre", 1.0)
			var nwin: int = int((w - 1.6) / 2.4)
			for k in range(nwin):
				var wx: float = -w / 2 + (k + 0.5) * w / nwin
				if absf(wx - door_x) < 1.6:
					continue
				window(xf * Transform3D(Basis(), Vector3(wx, 1.8, 0)), 0.9, 1.3, volets, rng.randf() < lit_p, rng.randf() < 0.25)
			out["door"] = xf * Vector3(door_x, 0, -1.0)
			if walkin.is_empty() and not bool(spec.get("pas_v81", false)):
				porte_v81(xf, Vector3(door_x, 0, -1.0), w, d, "azur", floors.size())
	if not walkin.is_empty():
		out["door"] = xf * Vector3(float(walkin.get("door_x", 0.0)), 0, -1.0)
	# étages
	var balconies: Array = spec.get("balcons", [])
	var fy: float = gf
	var nwin2: int = maxi(1, int((w - 0.8) / 2.5))
	for fi in range(1, floors.size()):
		var fh: float = float(floors[fi])
		for k in range(nwin2):
			var wx2: float = -w / 2 + (k + 0.5) * w / nwin2
			var has_bal: bool = balconies.has(fi) and (nwin2 <= 2 or k == nwin2 / 2 or spec.get("balcon_long", false))
			if has_bal:
				window(xf * Transform3D(Basis(), Vector3(wx2, fy + 1.15, 0)), 1.0, 2.1, volets, rng.randf() < lit_p, false, true)
				if not spec.get("balcon_long", false):
					balcony(xf * Transform3D(Basis(), Vector3(wx2, fy + 0.1, 0)), 1.7)
			else:
				window(xf * Transform3D(Basis(), Vector3(wx2, fy + fh * 0.5 + 0.05, 0)), 0.95, 1.45, volets, rng.randf() < lit_p, rng.randf() < float(spec.get("shutters_closed", 0.2)))
		if spec.get("balcon_long", false) and balconies.has(fi):
			balcony(xf * Transform3D(Basis(), Vector3(0, fy + 0.1, 0)), w - 0.6, 1.0)
		fy += fh
	# façade arrière : quelques fenêtres
	for fi2 in range(1, floors.size()):
		var by: float = gf
		for j in range(1, fi2):
			by += float(floors[j])
		for k2 in range(maxi(1, nwin2 - 1)):
			var bx: float = -w / 2 + (k2 + 0.5) * w / maxi(1, nwin2 - 1)
			window(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(bx, by + float(floors[fi2]) * 0.5, d)), 0.85, 1.3, volets, rng.randf() < lit_p * 0.6, rng.randf() < 0.4)
	return out


## Rez-de-chaussée creux (on entre) : murs de 0,3 m, porte, plancher, plafond, éclairage.
func _hollow_ground_floor(xf: Transform3D, w: float, d: float, gf: float, wall_key: String, walkin: Dictionary) -> void:
	var t: float = 0.3
	var dx: float = float(walkin.get("door_x", 0.0))
	var dw: float = float(walkin.get("door_w", 1.6))
	var dh: float = 2.6
	var inner: String = "interieur_" + str(walkin.get("couleur", ""))
	# façade : à gauche et à droite de la porte, linteau au-dessus
	var left_w: float = (dx - dw / 2) + w / 2
	var right_w: float = w / 2 - (dx + dw / 2)
	if left_w > 0.01:
		box(xf * Transform3D(Basis(), Vector3(-w / 2 + left_w / 2, gf / 2, t / 2)), Vector3(left_w, gf, t), wall_key, 3.0, 63 - 8 - 16)
		box(xf * Transform3D(Basis(), Vector3(-w / 2 + left_w / 2, gf / 2, t + 0.001)), Vector3(left_w, gf, 0.0), inner, 3.0, 16)
		col_box(xf * Transform3D(Basis(), Vector3(-w / 2 + left_w / 2, gf / 2, t / 2)), Vector3(left_w, gf, t))
	if right_w > 0.01:
		box(xf * Transform3D(Basis(), Vector3(w / 2 - right_w / 2, gf / 2, t / 2)), Vector3(right_w, gf, t), wall_key, 3.0, 63 - 8 - 16)
		box(xf * Transform3D(Basis(), Vector3(w / 2 - right_w / 2, gf / 2, t + 0.001)), Vector3(right_w, gf, 0.0), inner, 3.0, 16)
		col_box(xf * Transform3D(Basis(), Vector3(w / 2 - right_w / 2, gf / 2, t / 2)), Vector3(right_w, gf, t))
	box(xf * Transform3D(Basis(), Vector3(dx, (gf + dh) / 2, t / 2)), Vector3(dw, gf - dh, t), wall_key, 3.0, 63 - 8)
	box(xf * Transform3D(Basis(), Vector3(dx, dh + 0.06, -0.04)), Vector3(dw + 0.3, 0.14, 0.1), "pierre", 1.0)
	# fenêtres de part et d'autre de la porte (verre seul, on voit l'intérieur éclairé)
	for s in [-1.0, 1.0]:
		var wx: float = dx + s * (dw / 2 + 1.4)
		if absf(wx) < w / 2 - 0.9:
			quad(xf * Transform3D(Basis(), Vector3(wx, 1.6, -0.01)), 1.3, 1.6, "fenetre_nuit")
	# murs latéraux et arrière
	for s2 in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(s2 * (w / 2 - t / 2), gf / 2, d / 2)), Vector3(t, gf, d), wall_key, 3.0, 1 if s2 > 0 else 2)
		box(xf * Transform3D(Basis(), Vector3(s2 * (w / 2 - t / 2), gf / 2, d / 2)), Vector3(t, gf, d - 2.0 * t), inner, 3.0, 2 if s2 > 0 else 1)
		col_box(xf * Transform3D(Basis(), Vector3(s2 * (w / 2 - t / 2), gf / 2, d / 2)), Vector3(t, gf, d))
	box(xf * Transform3D(Basis(), Vector3(0, gf / 2, d - t / 2)), Vector3(w, gf, t), wall_key, 3.0, 16)
	box(xf * Transform3D(Basis(), Vector3(0, gf / 2, d - t / 2)), Vector3(w - 2.0 * t, gf, t), inner, 3.0, 32)
	col_box(xf * Transform3D(Basis(), Vector3(0, gf / 2, d - t / 2)), Vector3(w, gf, t))
	# plancher et plafond
	box(xf * Transform3D(Basis(), Vector3(0, 0.03, d / 2)), Vector3(w - 2.0 * t, 0.06, d - 2.0 * t), str(walkin.get("sol", "planches")), 2.0, 4)
	box(xf * Transform3D(Basis(), Vector3(0, gf - 0.04, d / 2)), Vector3(w - 2.0 * t, 0.08, d - 2.0 * t), inner, 3.0, 8)
	# poutres
	for k in range(int(w / 2.0)):
		box(xf * Transform3D(Basis(), Vector3(-w / 2 + 1.0 + k * 2.0, gf - 0.18, d / 2)), Vector3(0.16, 0.2, d - 2.0 * t), "bois_sombre", 1.5, 63 - 4)
	# lumière chaude à l'intérieur
	for k2 in range(int(walkin.get("lumieres", 2))):
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.8, 0.55)
		l.light_energy = float(walkin.get("energie", 1.2))
		l.omni_range = maxf(w, d) * float(walkin.get("portee", 0.7))
		l.shadow_enabled = false
		var nl: int = int(walkin.get("lumieres", 2))
		var lz: float = d / 2 if nl <= 2 else d * (0.2 + 0.6 * float(k2) / float(nl - 1))
		var lx: float = (-w / 4 + k2 * w / 2) if nl <= 2 else 0.0
		l.position = (xf * Transform3D(Basis(), Vector3(lx, gf - 0.6, lz))).origin
		root.add_child(l)
		lamp_count += 1
		# suspension : globe lumineux
		sphere_lamp(xf * Transform3D(Basis(), Vector3(lx, gf - 0.55, lz)))


func sphere_lamp(xf: Transform3D) -> void:
	cyl(xf * Transform3D(Basis(), Vector3(0, 0.12, 0)), 0.01, 0.01, 0.4, "fer", 4, false)
	cyl(xf * Transform3D(Basis(), Vector3(0, -0.12, 0)), 0.08, 0.18, 0.24, "laiton", 10)
	var m: Variant = mats.get("globe")
	if m == null:
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(1.0, 0.92, 0.75)
		sm.emission_enabled = true
		sm.emission = Color(1.0, 0.8, 0.5)
		sm.emission_energy_multiplier = 2.0
		mats["globe"] = sm
	cyl(xf * Transform3D(Basis(), Vector3(0, -0.2, 0)), 0.1, 0.1, 0.08, "globe", 8)
