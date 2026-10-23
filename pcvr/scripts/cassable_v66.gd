extends Node3D
## V66 : un objet qu'on peut casser — caisse, tonneau, jarre, pot ou panier.
## Il suit la règle des cibles (groupe « cibles_v28 », hit_radius, hit_height, is_hittable,
## take_hit) : l'épée, les poings en VR et les pouvoirs le frappent. Il vacille à chaque coup,
## puis se brise : planches, douelles et cercles de fer, tessons, brins d'osier et fruits qui
## roulent ; parfois un petit butin (pièces, de quoi manger ou boire, rarement une petite clé).
## Ce qui était posé dessus tombe. Si quelqu'un habite à côté, il le fait savoir.
## Il se reforme quelques minutes plus tard, quand le joueur est loin.
## Création : spawn(parent, sorte, position locale, angle, échelle) — utilisé par la boîte à
## outils des villes (caisses et tonneaux), le décor des nains et du château, et objets_v66.

const TEX := "res://assets/textures/objets/"
const _Pnj = preload("res://scripts/pnj/pnj_v31.gd")
## sorte -> points de solidité, rayon et demi-hauteur (à l'échelle 1), bruits, couleur de poussière
const KINDS := {
	"caisse": {"pv": 4, "r": 0.55, "h": 0.5, "coup": "touche_bois", "casse": "caisse_casse", "poussiere": Color(0.72, 0.6, 0.45)},
	"tonneau": {"pv": 6, "r": 0.34, "h": 0.45, "coup": "touche_bois", "casse": "tonneau_casse", "poussiere": Color(0.55, 0.42, 0.3)},
	"jarre": {"pv": 1, "r": 0.27, "h": 0.33, "coup": "jarre_casse", "casse": "jarre_casse", "poussiere": Color(0.7, 0.42, 0.28)},
	"pot": {"pv": 1, "r": 0.2, "h": 0.17, "coup": "jarre_casse", "casse": "jarre_casse", "poussiere": Color(0.7, 0.42, 0.28)},
	"panier": {"pv": 2, "r": 0.27, "h": 0.17, "coup": "panier_casse", "casse": "panier_casse", "poussiere": Color(0.78, 0.66, 0.44)},
}
const RESPAWN := Vector2(300.0, 480.0)

static var main: Node                    # posé par objets_v66
static var manager: Node                 # objets_v66 (butin, éclats, ce qui tombe, plaintes)
static var _meshes: Dictionary = {}
static var _mats: Dictionary = {}

var kind: String = "caisse"
var region: String = ""                  # "" : d'après la position, au moment de casser
var style: String = ""                   # jarres : la couleur de la frise
var hit_radius: float = 0.3
var hit_height: float = 0.3
var height: float = 0.6
var pv: int = 1
var broken: bool = false
var respawn_in: float = 0.0
var displaced: bool = false              # tombé parce que ce qui le portait s'est brisé
var home: Transform3D
var tilt: Vector3 = Vector3.ZERO
var tilt_vel: Vector3 = Vector3.ZERO
var _pivot: Node3D
var _body: StaticBody3D
var _scale := Vector3.ONE


## Crée un objet à casser sous parent (position et angle dans le repère de parent).
## s : échelle (un nombre, ou Vector3 pour un tonneau plus large que haut).
static func spawn(parent: Node, k: String, pos: Vector3, yaw: float = 0.0, s: Variant = 1.0, reg: String = "", sty: String = "") -> Node3D:
	var c: Node3D = load("res://scripts/cassable_v66.gd").new()
	c.name = "Cassable_%s_%d" % [k, parent.get_child_count()]
	c.kind = k if KINDS.has(k) else "caisse"
	c.region = reg
	c.style = sty
	c._scale = (s as Vector3) if s is Vector3 else Vector3.ONE * float(s)
	c.position = pos
	c.rotation.y = yaw
	parent.add_child(c)
	return c


func _ready() -> void:
	home = transform
	var d: Dictionary = KINDS[kind]
	hit_radius = float(d["r"]) * maxf(_scale.x, _scale.z)
	hit_height = float(d["h"]) * _scale.y
	height = hit_height * 2.0
	pv = int(d["pv"])
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)
	var mi := MeshInstance3D.new()
	mi.name = "Forme"
	mi.mesh = mesh_for(kind, style)
	mi.scale = _scale
	mi.visibility_range_end = 90.0
	mi.visibility_range_end_margin = 6.0
	mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	_pivot.add_child(mi)
	_body = StaticBody3D.new()
	_body.name = "Collision"
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)
	var cs := CollisionShape3D.new()
	if kind == "caisse":
		var b := BoxShape3D.new()
		b.size = _scale
		cs.shape = b
	else:
		var cy := CylinderShape3D.new()
		cy.radius = hit_radius * 0.92
		cy.height = height
		cs.shape = cy
	cs.position = Vector3.UP * height * 0.5
	_body.add_child(cs)
	# les habitants passent au travers (leur rayon de sol l'ignore : ils ne grimpent pas dessus)
	_Pnj._npc_bodies.append(_body.get_rid())
	add_to_group("cibles_v28")
	add_to_group("cassables_v66")
	set_process(false)


func is_hittable() -> bool:
	return not broken


func center() -> Vector3:
	return global_position + Vector3.UP * hit_height


func take_hit(damage: int, from_pos: Vector3) -> void:
	if broken:
		return
	pv -= maxi(damage, 1)
	var d: Vector3 = global_position - from_pos
	d.y = 0.0
	d = d.normalized() if d.length() > 0.01 else -global_basis.z
	if pv > 0:
		var local_d: Vector3 = global_basis.inverse() * d
		tilt_vel += Vector3.UP.cross(local_d) * (1.6 + 0.4 * damage) / maxf(_scale.y, 0.6)
		set_process(true)
		_sfx(str(KINDS[kind]["coup"]))
		if main != null and main.get("combat_v28") != null and main.combat_v28 != null:
			main.combat_v28.puff(center() - d * hit_radius, KINDS[kind]["poussiere"])
		return
	shatter(d)


## Se brise : éclats, poussière, bruit, butin ; ce qui était posé dessus tombe.
func shatter(dir: Vector3 = Vector3.ZERO) -> void:
	if broken:
		return
	broken = true
	pv = 0
	_pivot.visible = false
	_body.collision_layer = 0
	remove_from_group("cibles_v28")
	tilt = Vector3.ZERO
	tilt_vel = Vector3.ZERO
	respawn_in = randf_range(RESPAWN.x, RESPAWN.y)
	set_process(true)
	_sfx(str(KINDS[kind]["casse"]))
	if manager != null:
		manager.on_shatter(self, dir)


func _sfx(nm: String) -> void:
	if main != null and main.has_method("sfx"):
		main.sfx(nm, center())


func _process(delta: float) -> void:
	if broken:
		respawn_in -= delta
		if respawn_in <= 0.0 and _player_far(25.0):
			# ce qui le portait doit être là avant lui (sinon il flotterait)
			if manager != null and manager.support_broken(self):
				respawn_in = 20.0
			else:
				restore()
		return
	tilt_vel += (-tilt * 70.0 - tilt_vel * 7.0) * delta
	tilt += tilt_vel * delta
	var a: float = tilt.length()
	_pivot.basis = Basis(tilt / a, minf(a, 0.35)) if a > 0.0001 else Basis.IDENTITY
	if a < 0.002 and tilt_vel.length() < 0.01:
		_pivot.basis = Basis.IDENTITY
		set_process(false)


## Se reforme (le joueur est loin) ; ce qui était tombé de dessus retrouve sa place.
func restore() -> void:
	broken = false
	displaced = false
	transform = home
	pv = int(KINDS[kind]["pv"])
	_pivot.visible = true
	_pivot.basis = Basis.IDENTITY
	_body.collision_layer = 1
	if not is_in_group("cibles_v28"):
		add_to_group("cibles_v28")
	set_process(false)
	if manager != null:
		manager.on_restore(self)


## Tombe (ce qui le portait s'est brisé) jusqu'au sol, en vacillant à l'arrivée.
func fall_to(y: float) -> void:
	displaced = true
	var drop: float = global_position.y - y
	if drop <= 0.02:
		return
	var tw := create_tween()
	tw.tween_property(self, "global_position:y", y, sqrt(2.0 * drop / 9.8)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		tilt_vel += Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * 2.5
		set_process(true)
		_sfx("touche_bois"))


func _player_far(d: float) -> bool:
	if main == null:
		return true
	var p: Vector3 = main._player_pos_v27()
	return Vector2(p.x - global_position.x, p.z - global_position.z).length() > d or absf(p.y - global_position.y) > 12.0


# =================================================================== matériaux

static func mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.roughness = 0.85
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	match key:
		"caisse", "cadre":
			_tex(m, "caisse")
			m.albedo_color = Color(1, 1, 1) if key == "caisse" else Color(0.66, 0.58, 0.5)
		"douelles":
			_tex(m, "douelles")
			m.roughness = 0.78
		"fer":
			_tex(m, "fer")
			m.metallic = 0.55
			m.roughness = 0.55
		"terre":
			_tex(m, "terre_cuite")
			m.roughness = 0.92
		"osier":
			_tex(m, "osier")
			m.roughness = 0.9
		"interieur":
			m.albedo_color = Color(0.07, 0.045, 0.03)
			m.roughness = 1.0
		"fruit":
			m.vertex_color_use_as_albedo = true
			m.roughness = 0.38
		_:
			# frises des jarres : frise_<couleur html>
			m.albedo_color = Color.html(key.trim_prefix("frise_"))
			m.roughness = 0.6
	_mats[key] = m
	return m


static func _tex(m: StandardMaterial3D, name: String) -> void:
	if ResourceLoader.exists(TEX + name + ".png"):
		m.albedo_texture = load(TEX + name + ".png")
	if ResourceLoader.exists(TEX + name + "_n.png"):
		m.normal_enabled = true
		m.normal_texture = load(TEX + name + "_n.png")
		m.normal_scale = 0.9


## Couleur de la frise d'une jarre selon le pays.
static func frise(sty: String) -> String:
	match sty:
		"tazira":
			return "frise_1f4f8f"
		"elfes":
			return "frise_5d7a3a"
		"donjon":
			return "frise_2a1d16"
	return "frise_5a3320"


# =================================================================== formes

static func mesh_for(k: String, sty: String = "") -> ArrayMesh:
	var key: String = k + ":" + sty
	if _meshes.has(key):
		return _meshes[key]
	var am := ArrayMesh.new()
	match k:
		"caisse":
			_add(am, _crate_panels(), mat("caisse"))
			_add(am, _crate_frame(), mat("cadre"))
		"tonneau":
			_add(am, _barrel_body(), mat("douelles"))
			_add(am, _barrel_hoops(), mat("fer"))
		"jarre":
			var prof := [[0.0, 0.0], [0.11, 0.0], [0.15, 0.04], [0.23, 0.16], [0.27, 0.32], [0.25, 0.44], [0.18, 0.54], [0.105, 0.6], [0.1, 0.63], [0.13, 0.65], [0.13, 0.67], [0.095, 0.67]]
			_add(am, _lathe(prof, 22, 2.0, true), mat("terre"))
			_add(am, _lathe([[0.27, 0.3], [0.272, 0.34]], 22, 2.0, false, 0.004), mat(frise(sty)))
			_add(am, _disc(0.095, 0.62, 16), mat("interieur"))
		"pot":
			var prof2 := [[0.0, 0.0], [0.1, 0.0], [0.15, 0.04], [0.2, 0.15], [0.19, 0.26], [0.14, 0.32], [0.155, 0.34], [0.155, 0.355], [0.13, 0.355]]
			_add(am, _lathe(prof2, 20, 1.5, true), mat("terre"))
			_add(am, _disc(0.13, 0.33, 14), mat("interieur"))
		"panier":
			_add(am, _basket(), mat("osier"))
			_add(am, _fruits(), mat("fruit"))
	_meshes[key] = am
	return am


static func _add(am: ArrayMesh, st: SurfaceTool, m: Material) -> void:
	st.generate_tangents()
	var arr: Array = st.commit_to_arrays()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	am.surface_set_material(am.get_surface_count() - 1, m)


static func _new_st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


static func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, n: Vector3, u0: Vector2, u1: Vector2, u2: Vector2, u3: Vector2) -> void:
	# p0 p1 p2 p3 dans le sens du tour ; la face avant regarde vers n
	var flip: bool = (p1 - p0).cross(p2 - p0).dot(n) > 0.0
	var tris := [[p0, u0], [p1, u1], [p2, u2], [p0, u0], [p2, u2], [p3, u3]]
	if flip:
		tris = [[p0, u0], [p2, u2], [p1, u1], [p0, u0], [p3, u3], [p2, u2]]
	for v in tris:
		st.set_normal(n)
		st.set_uv(v[1])
		st.add_vertex(v[0])


## Boîte posée sur y0, UV de 0 à 1 sur chaque face (ou proportionnels à la taille si tile > 0).
static func _box(st: SurfaceTool, c: Vector3, size: Vector3, tile: float = 0.0) -> void:
	var h: Vector3 = size * 0.5
	var defs := [
		[Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0), size.z, size.y],
		[Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0), size.z, size.y],
		[Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1), size.x, size.z],
		[Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, -1), size.x, size.z],
		[Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0), size.x, size.y],
		[Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0), size.x, size.y],
	]
	for d in defs:
		var n: Vector3 = d[0]
		var u: Vector3 = d[1]
		var v: Vector3 = d[2]
		var cc: Vector3 = c + Vector3(n.x * h.x, n.y * h.y, n.z * h.z)
		var hu := Vector3(u.x * h.x, u.y * h.y, u.z * h.z)
		var hv := Vector3(v.x * h.x, v.y * h.y, v.z * h.z)
		var uw: float = float(d[3]) / tile if tile > 0.0 else 1.0
		var vh: float = float(d[4]) / tile if tile > 0.0 else 1.0
		_quad(st, cc - hu - hv, cc + hu - hv, cc + hu + hv, cc - hu + hv, n, Vector2(0, vh), Vector2(uw, vh), Vector2(uw, 0), Vector2(0, 0))


## Les six panneaux de planches d'une caisse de 1 m (posée sur y = 0), un peu en retrait du cadre.
static func _crate_panels() -> SurfaceTool:
	var st := _new_st()
	_box(st, Vector3(0, 0.5, 0), Vector3(0.96, 0.96, 0.96))
	return st


## Le cadre : douze tasseaux sur les arêtes, et une écharpe en travers de deux faces.
static func _crate_frame() -> SurfaceTool:
	var st := _new_st()
	var e: float = 0.085
	var o: float = 0.5 - e * 0.5 + 0.012
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_box(st, Vector3(sx * o, 0.5, sz * o), Vector3(e, 1.02, e), 0.5)
	for sy: float in [-1.0, 1.0]:
		for sz2: float in [-1.0, 1.0]:
			_box(st, Vector3(0, 0.5 + sy * o, sz2 * o), Vector3(1.02, e, e), 0.5)
		for sx2: float in [-1.0, 1.0]:
			_box(st, Vector3(sx2 * o, 0.5 + sy * o, 0), Vector3(e, e, 1.02), 0.5)
	# écharpes (diagonales) sur deux faces opposées
	for sz3: float in [-1.0, 1.0]:
		var b := Basis(Vector3(0, 0, 1), PI / 4.0)
		var xf := Transform3D(b, Vector3(0, 0.5, sz3 * o))
		var tmp := _new_st()
		_box(tmp, Vector3.ZERO, Vector3(1.22, e * 0.9, e * 0.6), 0.5)
		var arr: Array = tmp.commit_to_arrays()
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		for i in vs.size():
			st.set_normal((b * ns[i]).normalized())
			st.set_uv(uvs[i])
			st.add_vertex(xf * vs[i])
	return st


## Le corps d'un tonneau de 0,9 m (rayon 0,34 au bouge, 0,29 aux bouts) et ses deux fonds.
static func _barrel_body() -> SurfaceTool:
	var st := _new_st()
	var seg: int = 24
	var rows: int = 10
	var hh: float = 0.9
	var prof: Array = []
	for j in rows + 1:
		var t: float = float(j) / rows
		prof.append([0.29 + 0.05 * sin(PI * t), hh * t])
	for j in rows:
		for i in seg:
			var a0: float = TAU * i / seg
			var a1: float = TAU * (i + 1) / seg
			var r0: float = prof[j][0]
			var r1: float = prof[j + 1][0]
			var y0: float = prof[j][1]
			var y1: float = prof[j + 1][1]
			var slope: float = (r1 - r0) / (y1 - y0)
			var n0 := Vector3(cos(a0), -slope, sin(a0)).normalized()
			var n1 := Vector3(cos(a1), -slope, sin(a1)).normalized()
			var u0: float = float(i) / seg * 1.5
			var u1: float = float(i + 1) / seg * 1.5
			var v0: float = 1.0 - y0 / hh
			var v1: float = 1.0 - y1 / hh
			var q := [[Vector3(cos(a0) * r0, y0, sin(a0) * r0), n0, Vector2(u0, v0)], [Vector3(cos(a0) * r1, y1, sin(a0) * r1), n0, Vector2(u0, v1)],
				[Vector3(cos(a1) * r1, y1, sin(a1) * r1), n1, Vector2(u1, v1)], [Vector3(cos(a1) * r0, y0, sin(a1) * r0), n1, Vector2(u1, v0)]]
			for idx: float in [0, 2, 1, 0, 3, 2]:
				st.set_normal(q[idx][1])
				st.set_uv(q[idx][2])
				st.add_vertex(q[idx][0])
	# fonds en retrait (le jable dépasse de 3 cm), et l'épaisseur du jable
	for top: bool in [true, false]:
		var y: float = hh - 0.03 if top else 0.03
		var yr: float = hh if top else 0.0
		var r: float = 0.275
		var nn: Vector3 = Vector3.UP if top else Vector3.DOWN
		for i in seg:
			var a0b: float = TAU * i / seg
			var a1b: float = TAU * (i + 1) / seg
			var p0 := Vector3(cos(a0b) * r, y, sin(a0b) * r)
			var p1 := Vector3(cos(a1b) * r, y, sin(a1b) * r)
			var tri := [[Vector3(0, y, 0), Vector2(0.5, 0.5)], [p0, Vector2(0.5 + cos(a0b) * 0.45, 0.5 + sin(a0b) * 0.45)], [p1, Vector2(0.5 + cos(a1b) * 0.45, 0.5 + sin(a1b) * 0.45)]]
			var order: Array = [0, 1, 2] if top else [0, 2, 1]
			for k in order:
				st.set_normal(nn)
				st.set_uv(tri[k][1])
				st.add_vertex(tri[k][0])
			# paroi intérieure du jable
			var q0 := Vector3(cos(a0b) * r, yr, sin(a0b) * r)
			var q1 := Vector3(cos(a1b) * r, yr, sin(a1b) * r)
			var nin0 := Vector3(-cos(a0b), 0, -sin(a0b))
			var nin1 := Vector3(-cos(a1b), 0, -sin(a1b))
			var w := [[p0, nin0, Vector2(0, 0)], [q0, nin0, Vector2(0, 0.05)], [q1, nin1, Vector2(0.06, 0.05)], [p1, nin1, Vector2(0.06, 0)]]
			var ord2: Array = [0, 1, 2, 0, 2, 3] if top else [0, 2, 1, 0, 3, 2]
			for k2 in ord2:
				st.set_normal(w[k2][1])
				st.set_uv(w[k2][2])
				st.add_vertex(w[k2][0])
			# dessus du jable (anneau entre le fond et le bord)
			var ro: float = 0.292
			var s0 := Vector3(cos(a0b) * ro, yr, sin(a0b) * ro)
			var s1 := Vector3(cos(a1b) * ro, yr, sin(a1b) * ro)
			var rim := [[q0, Vector2(0, 0)], [s0, Vector2(0, 0.03)], [s1, Vector2(0.06, 0.03)], [q1, Vector2(0.06, 0)]]
			var ord3: Array = [0, 1, 2, 0, 2, 3] if top else [0, 2, 1, 0, 3, 2]
			for k3 in ord3:
				st.set_normal(nn)
				st.set_uv(rim[k3][1])
				st.add_vertex(rim[k3][0])
	return st


## Quatre cercles de fer qui épousent le galbe du tonneau.
static func _barrel_hoops() -> SurfaceTool:
	var st := _new_st()
	var seg: int = 24
	for t: float in [0.07, 0.27, 0.73, 0.93]:
		var y: float = 0.9 * t
		var r: float = 0.29 + 0.05 * sin(PI * t) + 0.008
		var h: float = 0.045
		for i in seg:
			var a0: float = TAU * i / seg
			var a1: float = TAU * (i + 1) / seg
			var n0 := Vector3(cos(a0), 0, sin(a0))
			var n1 := Vector3(cos(a1), 0, sin(a1))
			var u0: float = float(i) / seg * 3.0
			var u1: float = float(i + 1) / seg * 3.0
			var q := [[n0 * r + Vector3.UP * (y - h * 0.5), n0, Vector2(u0, 0.1)], [n0 * r + Vector3.UP * (y + h * 0.5), n0, Vector2(u0, 0.0)],
				[n1 * r + Vector3.UP * (y + h * 0.5), n1, Vector2(u1, 0.0)], [n1 * r + Vector3.UP * (y - h * 0.5), n1, Vector2(u1, 0.1)]]
			for idx: float in [0, 2, 1, 0, 3, 2]:
				st.set_normal(q[idx][1])
				st.set_uv(q[idx][2])
				st.add_vertex(q[idx][0])
			# chants haut et bas du cercle
			for sgn: float in [1.0, -1.0]:
				var yy: float = y + sgn * h * 0.5
				var a := n0 * (r - 0.012) + Vector3.UP * yy
				var b := n0 * r + Vector3.UP * yy
				var c := n1 * r + Vector3.UP * yy
				var d := n1 * (r - 0.012) + Vector3.UP * yy
				var nn := Vector3.UP * sgn
				var ord: Array = [0, 1, 2, 0, 2, 3] if sgn > 0.0 else [0, 2, 1, 0, 3, 2]
				var pts := [a, b, c, d]
				for k in ord:
					st.set_normal(nn)
					st.set_uv(Vector2(0, 0))
					st.add_vertex(pts[k])
	return st


## Un corps de révolution (profil [[rayon, hauteur]…] de bas en haut), UV u = angle, v = longueur.
## La normale vient du profil (à droite de la montée) ; push : décalage vers l'extérieur (frises).
static func _lathe(prof: Array, seg: int, u_rep: float, _closed_bottom: bool, push: float = 0.0) -> SurfaceTool:
	var st := _new_st()
	var acc: Array = [0.0]
	for j in range(1, prof.size()):
		acc.append(float(acc[j - 1]) + Vector2(float(prof[j][0]) - float(prof[j - 1][0]), float(prof[j][1]) - float(prof[j - 1][1])).length())
	var total: float = maxf(float(acc[acc.size() - 1]), 0.001)
	for j in prof.size() - 1:
		var r0: float = float(prof[j][0]) + push
		var r1: float = float(prof[j + 1][0]) + push
		var y0: float = float(prof[j][1])
		var y1: float = float(prof[j + 1][1])
		var tang := Vector2(r1 - r0, y1 - y0).normalized()
		var nr: float = tang.y
		var ny: float = -tang.x
		for i in seg:
			var a0: float = TAU * i / seg
			var a1: float = TAU * (i + 1) / seg
			var n0 := Vector3(cos(a0) * nr, ny, sin(a0) * nr).normalized()
			var n1 := Vector3(cos(a1) * nr, ny, sin(a1) * nr).normalized()
			var u0: float = float(i) / seg * u_rep
			var u1: float = float(i + 1) / seg * u_rep
			var v0: float = 1.0 - float(acc[j]) / total
			var v1: float = 1.0 - float(acc[j + 1]) / total
			var q := [[Vector3(cos(a0) * r0, y0, sin(a0) * r0), n0, Vector2(u0, v0)], [Vector3(cos(a0) * r1, y1, sin(a0) * r1), n0, Vector2(u0, v1)],
				[Vector3(cos(a1) * r1, y1, sin(a1) * r1), n1, Vector2(u1, v1)], [Vector3(cos(a1) * r0, y0, sin(a1) * r0), n1, Vector2(u1, v0)]]
			# face avant vers l'extérieur (n) : ordre adapté au repère de Godot (sens horaire vu de face)
			for idx: float in [0, 2, 1, 0, 3, 2]:
				st.set_normal(q[idx][1])
				st.set_uv(q[idx][2])
				st.add_vertex(q[idx][0])
	return st


static func _disc(r: float, y: float, seg: int) -> SurfaceTool:
	var st := _new_st()
	for i in seg:
		var a0: float = TAU * i / seg
		var a1: float = TAU * (i + 1) / seg
		for v in [Vector3(0, y, 0), Vector3(cos(a0) * r, y, sin(a0) * r), Vector3(cos(a1) * r, y, sin(a1) * r)]:
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(v.x, v.z))
			st.add_vertex(v)
	return st


## Panier d'osier évasé (fond, paroi dedans et dehors, bord roulé, deux anses).
static func _basket() -> SurfaceTool:
	var st := _new_st()
	var outer := _lathe([[0.0, 0.0], [0.19, 0.0], [0.21, 0.03], [0.26, 0.3], [0.27, 0.32]], 20, 3.0, true)
	var inner := _lathe([[0.25, 0.31], [0.2, 0.05], [0.0, 0.05]], 20, 3.0, false)
	for part in [outer, inner]:
		var arr: Array = part.commit_to_arrays()
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		for i in vs.size():
			st.set_normal(ns[i])
			st.set_uv(uvs[i])
			st.add_vertex(vs[i])
	# anses : deux arceaux faits de petits segments
	for side: float in [-1.0, 1.0]:
		var prev := Vector3.ZERO
		for k in 9:
			var t: float = float(k) / 8.0
			var ang: float = PI * t
			var p := Vector3(side * 0.26, 0.31 + sin(ang) * 0.09, -0.07 + 0.14 * t)
			if k > 0:
				var mid: Vector3 = (prev + p) * 0.5
				var dir: Vector3 = (p - prev)
				var b := Basis.looking_at(dir.normalized(), Vector3(side, 0, 0))
				var tmp := _new_st()
				_box(tmp, Vector3.ZERO, Vector3(0.02, 0.02, dir.length() + 0.01), 0.3)
				var arr2: Array = tmp.commit_to_arrays()
				var vs2: PackedVector3Array = arr2[Mesh.ARRAY_VERTEX]
				var ns2: PackedVector3Array = arr2[Mesh.ARRAY_NORMAL]
				var uv2: PackedVector2Array = arr2[Mesh.ARRAY_TEX_UV]
				for i2 in vs2.size():
					st.set_normal((b * ns2[i2]).normalized())
					st.set_uv(uv2[i2])
					st.add_vertex(mid + b * vs2[i2])
			prev = p
	return st


## Des fruits dans le panier (pommes, oranges, poires), en couleurs de sommets.
static func _fruits() -> SurfaceTool:
	var st := _new_st()
	var cols := [Color(0.72, 0.1, 0.08), Color(0.95, 0.55, 0.1), Color(0.62, 0.72, 0.2), Color(0.8, 0.16, 0.1), Color(0.93, 0.6, 0.12)]
	var spots := [Vector3(-0.08, 0.28, -0.05), Vector3(0.07, 0.28, -0.06), Vector3(0.0, 0.28, 0.08), Vector3(-0.1, 0.26, 0.08), Vector3(0.11, 0.26, 0.06), Vector3(0.0, 0.34, 0.0)]
	for k in spots.size():
		var c: Color = cols[k % cols.size()]
		var r: float = 0.06 if k != 5 else 0.055
		var o: Vector3 = spots[k]
		var rings: int = 6
		var seg: int = 10
		for j in rings:
			for i in seg:
				var t0: float = PI * j / rings
				var t1: float = PI * (j + 1) / rings
				var a0: float = TAU * i / seg
				var a1: float = TAU * (i + 1) / seg
				var pts := [Vector3(sin(t0) * cos(a0), cos(t0), sin(t0) * sin(a0)), Vector3(sin(t1) * cos(a0), cos(t1), sin(t1) * sin(a0)),
					Vector3(sin(t1) * cos(a1), cos(t1), sin(t1) * sin(a1)), Vector3(sin(t0) * cos(a1), cos(t0), sin(t0) * sin(a1))]
				for idx: float in [0, 1, 2, 0, 2, 3]:
					var n: Vector3 = pts[idx]
					st.set_color(c * (0.9 + 0.1 * n.y))
					st.set_normal(n)
					st.set_uv(Vector2(0, 0))
					st.add_vertex(o + Vector3(n.x * r, n.y * r * 0.92, n.z * r))
	return st
