extends Node3D
## V29 : barque à voile pour aller d'une île à l'autre, et un ponton sur chaque île.
## PC : E près du bateau pour monter, Z/S avancer/reculer, Q/D barrer, E pour débarquer
## (près d'un ponton ou d'une plage). VR : gâchette droite pour monter/descendre,
## stick gauche pour avancer et barrer.
##
## V76 : le bateau évolue au chantier naval de Port-Azur (chantier_v76.gd appelle
## set_evolution()) : trois coques (1 la Barque d'origine, 2 le Sloop, 3 la Goélette), trois
## propulsions (1 la voile, 2 la voile + le moteur à vapeur, 3 le moteur à cristal) et six
## accessoires (lanterne de proue, longue-vue, couchette, canon à confettis, peinture de la
## coque, pavillon). Le modèle se reconstruit sur place ; conduite, pontons, VR, mer navigable
## et accostage valent pour toutes les tailles. Sans évolution : la barque de V29, inchangée.
## À bord : PC  L = longue-vue (zoom), K = canon à confettis, E à l'arrêt loin du rivage =
##              dormir dans la couchette (la nuit) ;
##          manette  LB = longue-vue, B = confettis, Y = E ;
##          VR  A (main droite) = confettis, gâchette à l'arrêt au large = dormir.

const LENGTH: float = 4.6
const BEAM: float = 1.6
const DEPTH: float = 0.72
const DRAFT: float = 0.28              # partie de la coque sous l'eau
const MAX_SPEED: float = 8.0
const MAX_REVERSE: float = 2.2
const ACCEL: float = 2.4
const WATER: float = -0.42
const DECK_Y: float = 1.0              # hauteur du plancher des pontons
const BOARD_REACH: float = 3.4
const WORLD_RADIUS: float = 560.0      # la mer navigable, autour du milieu des deux îles
const WORLD_MID := Vector3(0.0, 0.0, -165.0)
const GrandeIle = preload("res://scripts/grande_ile_v59.gd")

# =================================================================== V76 : les évolutions

## Coques : nom, longueur, largeur, creux, vitesse en voile (m/s), vitesse de giration.
const HULLS := {
	1: {"nom": "la Barque", "titre": "Barque", "L": 4.6, "B": 1.6, "D": 0.72, "v": 8.0, "turn": 0.85},
	2: {"nom": "le Sloop", "titre": "Sloop", "L": 6.5, "B": 2.2, "D": 0.95, "v": 10.0, "turn": 0.78},
	3: {"nom": "la Goélette", "titre": "Goélette", "L": 8.5, "B": 2.6, "D": 1.1, "v": 12.0, "turn": 0.72},
}
const PROPULSIONS := {
	1: {"nom": "à voile", "titre": "la voile", "k": 1.0},
	2: {"nom": "à vapeur", "titre": "le moteur à vapeur", "k": 1.3},
	3: {"nom": "à cristal", "titre": "le moteur à cristal", "k": 1.7},
}
const ACCESSOIRES := ["lanterne", "longue_vue", "couchette", "canon", "peinture", "pavillon"]
## Peintures de coque : id -> [couleur, nom]
const COULEURS := {
	"bleu": [Color(0.1, 0.19, 0.4), "Bleu marine"],
	"rouge": [Color(0.6, 0.09, 0.07), "Rouge corsaire"],
	"vert": [Color(0.1, 0.32, 0.21), "Vert sapin"],
	"jaune": [Color(0.92, 0.68, 0.15), "Jaune soleil"],
	"blanc": [Color(0.92, 0.92, 0.88), "Blanc écume"],
	"noir": [Color(0.055, 0.055, 0.065), "Noir goudron"],
	"turquoise": [Color(0.07, 0.5, 0.53), "Turquoise lagon"],
	"rose": [Color(0.92, 0.46, 0.6), "Rose bonbon"],
}
## Pavillons (0 : aucun)
const PAVILLONS := ["", "La Mouette rieuse", "L'Étoile du marin", "Le Crâne qui rigole", "Le Cœur vaillant", "L'Ancre d'or", "Le Poisson-lune"]
const KEY_LONGUE_VUE := KEY_L
const KEY_CONFETTIS := KEY_K
const SPY_FOV: float = 13.0

var main: Node
var driving: bool = false
var speed: float = 0.0
var yaw: float = PI                    # cap (rotation Y) ; la proue regarde vers -Z local
var bob_clock: float = 0.0
var docks: Array = []                  # {start, end, axis, name}
var hull: Node3D
var seat_local := Vector3(0.0, 0.0, 0.0)
var _wood: StandardMaterial3D
var _paint: StandardMaterial3D
var _sail_mat: StandardMaterial3D
var _rope: StandardMaterial3D
var _vr_yaw_offset: float = 0.0
var _vr_trigger_ready: bool = true
var _blocked_clock: float = 0.0
var vr_label: Label3D

# V76
var coque: int = 1
var propulsion: int = 1
var accessoires: Dictionary = {}       # id -> true
var couleur: String = ""               # "" : bois d'origine
var pavillon: int = 0
var length: float = LENGTH
var beam: float = BEAM
var depth: float = DEPTH
var draft: float = DRAFT
var max_speed: float = MAX_SPEED
var max_reverse: float = MAX_REVERSE
var accel: float = ACCEL
var turn_rate: float = 0.85
var passenger_seats: Array = []        # places des passagers (repère du bateau, regard vers l'avant)
var stats: Dictionary = {"confettis": 0, "nuits": 0, "reconstructions": 0}
var _lay: Dictionary = {}              # points d'accroche du modèle courant
var _batch: Dictionary = {}            # clé matériau -> SurfaceTool (pièces regroupées)
var _mats: Dictionary = {}
var _meshes: Dictionary = {}           # primitives partagées
var _glow: Array = []                  # [matériau, énergie] des cristaux qui palpitent
var _smoke: GPUParticles3D
var _foam: GPUParticles3D
var _wake: GPUParticles3D
var _confetti: GPUParticles3D
var _muzzle: Node3D
var _engine: AudioStreamPlayer3D
var _engine_puff: float = 0.0
var _spy: bool = false
var _spy_fov0: float = -1.0
var _spy_layer: CanvasLayer
var _spy_rect: ColorRect
var _pad_prev: Dictionary = {}
var _vr_a_ready: bool = true
var _confetti_cd: float = 0.0
var _sleep_busy: bool = false
var _clock: float = 0.0
static var _flag_cache: Dictionary = {}
static var _sail_tex: ImageTexture


func build(main_node: Node, island_dock: Array, jungle_dock: Array) -> void:
	main = main_node
	process_priority = 50                # après le héros : la longue-vue a le dernier mot sur la caméra
	_wood = StandardMaterial3D.new()
	_wood.albedo_texture = load("res://assets/textures/doors/wood_plain.png")
	_wood.uv1_triplanar = true
	_wood.uv1_scale = Vector3(1.6, 1.6, 1.6)
	_wood.roughness = 0.75
	_wood.cull_mode = BaseMaterial3D.CULL_DISABLED
	_paint = StandardMaterial3D.new()
	_paint.albedo_color = Color(0.13, 0.32, 0.38)
	_paint.roughness = 0.55
	_sail_mat = StandardMaterial3D.new()
	_sail_mat.albedo_color = Color(0.92, 0.88, 0.78)
	_sail_mat.roughness = 0.95
	_sail_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_sail_mat.backlight_enabled = true
	_sail_mat.backlight = Color(0.35, 0.32, 0.25)
	_rope = StandardMaterial3D.new()
	_rope.albedo_color = Color(0.55, 0.45, 0.3)
	_make_dock("Ponton_village", island_dock[0], island_dock[1])
	_make_dock("Ponton_jungle", jungle_dock[0], jungle_dock[1])
	_make_boat()
	moor(0)
	print("ILE_MANGA_V29: bateau et ", docks.size(), " pontons")


# =================================================================== pontons

func _make_dock(label: String, start: Vector3, end: Vector3) -> void:
	start.y = DECK_Y
	end.y = DECK_Y
	var axis: Vector3 = (end - start)
	axis.y = 0.0
	var length_d: float = axis.length()
	axis = axis.normalized()
	var side: Vector3 = axis.cross(Vector3.UP).normalized()
	var root := Node3D.new()
	root.name = label
	add_child(root)
	var basis := Basis(side, Vector3.UP, -axis)        # Z local = vers la plage
	var center: Vector3 = (start + end) * 0.5
	# Planches transversales avec de petits jours entre elles.
	var plank := BoxMesh.new()
	plank.size = Vector3(2.4, 0.07, 0.42)
	var k: int = 0
	var s: float = 0.25
	while s < length_d:
		var p: Vector3 = start + axis * s
		var mi := MeshInstance3D.new()
		mi.mesh = plank
		mi.material_override = _wood
		root.add_child(mi)
		mi.global_transform = Transform3D(basis.rotated(Vector3.UP, (float(k % 3) - 1.0) * 0.012), p + Vector3.DOWN * 0.035)
		s += 0.46
		k += 1
	# Longerons et pieux.
	var beam_m := BoxMesh.new()
	beam_m.size = Vector3(0.14, 0.18, length_d)
	for sd in [-1.0, 1.0]:
		var mb := MeshInstance3D.new()
		mb.mesh = beam_m
		mb.material_override = _wood
		root.add_child(mb)
		mb.global_transform = Transform3D(basis, center + side * sd * 1.05 + Vector3.DOWN * 0.16)
	var post := CylinderMesh.new()
	post.top_radius = 0.11
	post.bottom_radius = 0.13
	post.height = 8.0
	var t: float = 0.6
	while t <= length_d + 0.01:
		for sd in [-1.0, 1.0]:
			var mp := MeshInstance3D.new()
			mp.mesh = post
			mp.material_override = _wood
			root.add_child(mp)
			mp.global_position = start + axis * t + side * sd * 1.15 + Vector3.DOWN * 3.7
		t += 2.6
	# Bollard d'amarrage au bout.
	var bollard := CylinderMesh.new()
	bollard.top_radius = 0.12
	bollard.bottom_radius = 0.14
	bollard.height = 0.6
	var mbo := MeshInstance3D.new()
	mbo.mesh = bollard
	mbo.material_override = _wood
	root.add_child(mbo)
	mbo.global_position = end - axis * 0.4 + side * 0.85 + Vector3.UP * 0.3
	# Plancher solide pour marcher.
	var body := StaticBody3D.new()
	body.name = label + "_collision"
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 0.3, length_d + 0.4)
	cs.shape = box
	body.add_child(cs)
	root.add_child(body)
	body.global_transform = Transform3D(basis, center + Vector3.DOWN * 0.15)
	docks.append({"name": label, "start": start, "end": end, "axis": axis, "side": side, "length": length_d})


## Le joueur à pied est-il sur un ponton ? (la limite de l'île ne s'y applique pas)
func on_dock(p: Vector3) -> bool:
	for d in docks:
		var rel: Vector3 = p - d["start"]
		var along: float = rel.dot(d["axis"])
		var across: float = absf(rel.dot(d["side"]))
		if along > -1.0 and along < float(d["length"]) + 0.3 and across < 1.35 and p.y > DECK_Y - 1.5:
			return true
	return false


## V76 : l'indice d'un ponton d'après son nom (-1 s'il n'existe pas).
func dock_index(label: String) -> int:
	for i in range(docks.size()):
		if str(docks[i]["name"]) == label:
			return i
	return -1


# =================================================================== le modèle

func _make_boat() -> void:
	hull = Node3D.new()
	hull.name = "Barque_v29"
	add_child(hull)
	_build_model()


## V76 : (re)construit le modèle selon la coque, la propulsion et les accessoires.
func _build_model() -> void:
	_spy_off_now()
	for c in hull.get_children():
		hull.remove_child(c)
		c.queue_free()
	_batch.clear()
	_glow.clear()
	_lay.clear()
	for k in ["coque", "lisere", "voile_peinte"]:
		_mats.erase(k)
	_smoke = null
	_foam = null
	_wake = null
	_confetti = null
	_muzzle = null
	_engine = null
	if coque <= 1:
		_model_barque()
	else:
		_model_ponte()
	_model_propulsion()
	_model_accessoires()
	_commit_batch()
	for c in hull.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for c2 in hull.find_children("NoShadow_*", "MeshInstance3D", true, false):
		(c2 as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	vr_label = Label3D.new()
	vr_label.text = "Gâchette droite : monter à bord"
	vr_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	vr_label.font_size = 44
	vr_label.pixel_size = 0.003
	vr_label.outline_size = 12
	vr_label.no_depth_test = true
	vr_label.position = Vector3(0, 2.2 + (depth - DEPTH) * 1.5, 0)
	vr_label.visible = false
	hull.add_child(vr_label)


## La barque de V29 (inchangée ; seule la peinture, si on l'a achetée, change la coque).
func _model_barque() -> void:
	var shell := MeshInstance3D.new()
	shell.name = "Coque"
	shell.mesh = _hull_mesh()
	shell.material_override = _wood if couleur == "" else _mat("coque")
	hull.add_child(shell)
	if couleur != "":
		var inner := MeshInstance3D.new()
		inner.name = "Coque_interieur"
		inner.mesh = _hull_mesh(0.0, 1.0, 0.985)
		inner.material_override = _wood
		hull.add_child(inner)
	var stripe := MeshInstance3D.new()
	stripe.name = "Liseré"
	stripe.mesh = _hull_mesh(0.82, 0.96, 1.012)
	stripe.material_override = _paint if couleur == "" else _mat("lisere")
	hull.add_child(stripe)
	# Bancs, plancher.
	for b in [[0.95, 0.38, 1.25], [-0.55, 0.4, 1.38]]:
		var bench := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(float(b[2]), 0.05, 0.32)
		bench.mesh = bm
		bench.material_override = _wood
		bench.position = Vector3(0, float(b[1]), float(b[0]))
		hull.add_child(bench)
	var floor_m := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(0.7, 0.03, 3.0)
	floor_m.mesh = fm
	floor_m.material_override = _wood
	floor_m.position = Vector3(0, 0.1, 0.1)
	hull.add_child(floor_m)
	# Mât, bôme, voile, gouvernail.
	var mast_z: float = -0.9
	var mast := MeshInstance3D.new()
	var mm := CylinderMesh.new()
	mm.top_radius = 0.035
	mm.bottom_radius = 0.055
	mm.height = 3.7
	mast.mesh = mm
	mast.material_override = _wood
	mast.position = Vector3(0, 0.1 + 1.85, mast_z)
	hull.add_child(mast)
	var boom := MeshInstance3D.new()
	var bm2 := CylinderMesh.new()
	bm2.top_radius = 0.03
	bm2.bottom_radius = 0.03
	bm2.height = 2.3
	boom.mesh = bm2
	boom.material_override = _wood
	boom.rotation_degrees = Vector3(90, 0, 0)
	boom.position = Vector3(0, 1.05, mast_z + 1.15)
	hull.add_child(boom)
	var sail := MeshInstance3D.new()
	sail.name = "Voile"
	sail.mesh = _sail_mesh(Vector3(0, 3.65, mast_z), Vector3(0, 1.1, mast_z), Vector3(0, 1.1, mast_z + 2.25))
	sail.material_override = _sail_mat
	hull.add_child(sail)
	var stay := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.008
	sm.bottom_radius = 0.008
	var a := Vector3(0, 3.7, mast_z)
	var bow := Vector3(0, DEPTH + 0.15, -LENGTH * 0.5 + 0.1)
	sm.height = a.distance_to(bow)
	stay.mesh = sm
	stay.material_override = _rope
	hull.add_child(stay)
	stay.position = (a + bow) * 0.5
	stay.basis = Basis(Quaternion(Vector3.UP, (a - bow).normalized()))
	var rudder := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(0.05, 0.75, 0.32)
	rudder.mesh = rm
	rudder.material_override = _paint
	rudder.position = Vector3(0, 0.15, LENGTH * 0.5 + 0.12)
	hull.add_child(rudder)
	var tiller := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(0.04, 0.04, 0.8)
	tiller.mesh = tm
	tiller.material_override = _wood
	tiller.position = Vector3(0, 0.62, LENGTH * 0.5 - 0.3)
	hull.add_child(tiller)
	seat_local = Vector3(0, 0.405, 0.95)
	passenger_seats = [Vector3(0, 0.425, -0.55), Vector3(-0.42, 0.405, 0.95), Vector3(0.42, 0.405, 0.95), Vector3(0, 0.13, -0.12)]
	_lay = {
		"lantern": Vector3(0.1, 0.88, -2.0), "lantern_h": 0.5,
		"spy": Vector3(0.62, 0.745, 1.32),
		"cannon": Vector3(0.36, 0.425, -0.55),
		"bed": Vector3(0, 0.2, -1.5), "bed_w": 0.7,
		"flag": Vector3(0.32, 0.62, 2.33), "flag_h": 1.25, "flag_w": 0.48,
		"chimney": Vector3(0, 0.115, 0.25), "boiler": true, "chimney_h": 1.25, "chimney_r": 0.065,
		"stern": Vector3(0, 0.72, LENGTH * 0.5), "transom_w": 0.5,
		"side_z": 0.35,
	}


## Le Sloop et la Goélette : coque pontée, cockpit, rouf, mâture.
func _model_ponte() -> void:
	var goe: bool = coque >= 3
	var drop: float = 0.14 if goe else 0.1
	var c0: float = 0.04
	var c1: float = 0.21 if goe else 0.27
	var r1: float = 0.43 if goe else 0.52
	var floor_y: float = draft + 0.05
	# --- coque, carène, liseré, plat-bord, pont
	_inst(_hull_mesh(), "coque" if couleur != "" else "bordage", "Coque")
	if couleur != "":
		_inst(_hull_mesh(0.0, 1.0, 0.985), "verni", "Coque_interieur")
	_inst(_hull_mesh(0.0, 1.0, 1.006, draft + 0.07), "antifouling", "Carene")
	_inst(_hull_mesh(0.8, 0.92, 1.012), "lisere", "Lisere")
	_inst(_rail_mesh(), "verni", "Plat_bord")
	var cw: float = minf(_deck_lat(c0 + 0.02, drop), _deck_lat(c1, drop)) - (0.3 if goe else 0.27)
	_inst(_deck_mesh(c0, c1, cw, drop), "pont", "Pont")
	# --- le cockpit
	var zc0: float = _z(c0)
	var zc1: float = _z(c1)
	var dy0: float = _deck_y(c0, drop)
	var dy1: float = _deck_y(c1, drop)
	var cl: float = zc0 - zc1
	var zm: float = (zc0 + zc1) * 0.5
	_box(Vector3(0, floor_y - 0.02, zm), Vector3(cw * 2.0, 0.04, cl), "bois_clair")
	for sd in [-1.0, 1.0]:
		_box(Vector3(sd * (cw + 0.015), (floor_y + (dy0 + dy1) * 0.5) * 0.5, zm), Vector3(0.03, (dy0 + dy1) * 0.5 - floor_y + 0.02, cl), "verni")
		# hiloires (rebords autour du cockpit)
		_box(Vector3(sd * (cw + 0.03), (dy0 + dy1) * 0.5 + 0.05, zm), Vector3(0.04, 0.14, cl + 0.06), "verni")
	_box(Vector3(0, (floor_y + dy0) * 0.5, zc0 + 0.015), Vector3(cw * 2.0, dy0 - floor_y, 0.03), "verni")
	_box(Vector3(0, dy0 + 0.05, zc0 + 0.03), Vector3(cw * 2.0 + 0.1, 0.14, 0.04), "verni")
	_box(Vector3(0, (floor_y + dy1) * 0.5, zc1 - 0.015), Vector3(cw * 2.0, dy1 - floor_y, 0.03), "verni")
	# banc du barreur (en travers, à l'arrière) et bancs latéraux
	var bench_top: float = floor_y + 0.4
	var zb: float = zc0 - 0.22
	_box(Vector3(0, bench_top - 0.025, zb), Vector3(cw * 2.0 - 0.02, 0.05, 0.42), "verni")
	_box(Vector3(0, (floor_y + bench_top) * 0.5 - 0.02, zb - 0.2), Vector3(cw * 2.0 - 0.02, bench_top - floor_y - 0.04, 0.03), "bois_clair")
	var side_len: float = (zb - 0.21) - (zc1 + 0.03)
	for sd2 in [-1.0, 1.0]:
		_box(Vector3(sd2 * (cw - 0.17), bench_top - 0.025, zc1 + 0.03 + side_len * 0.5), Vector3(0.34, 0.05, side_len), "verni")
		_box(Vector3(sd2 * (cw - 0.34), (floor_y + bench_top) * 0.5 - 0.02, zc1 + 0.03 + side_len * 0.5), Vector3(0.03, bench_top - floor_y - 0.04, side_len), "bois_clair")
	seat_local = Vector3(0, bench_top, zb)
	# --- le rouf (la cabine)
	var cab_h: float = 0.72 if goe else 0.62
	var roof_y: float = _cabin(c1, r1, cab_h, drop)
	var zr1: float = _z(r1)
	# --- mâture, voiles, gréement, gouvernail
	if goe:
		_rig_goelette(drop, roof_y)
	else:
		_rig_sloop(drop, roof_y)
	# défenses (pare-battages) le long de la coque
	for sd3 in [-1.0, 1.0]:
		for fz in [0.32, 0.62]:
			var fp: Vector3 = hull_point(fz, 0.86, length, beam, depth, 1.04)
			_rod(Vector3(sd3 * fp.x, _top(fz) + 0.02, fp.z), Vector3(sd3 * (fp.x + 0.02), fp.y - 0.05, fp.z), 0.006, "corde")
			_add(_cyl(0.075, 0.075, 0.34, 10), "pare_battage", Transform3D(Basis(), Vector3(sd3 * (fp.x + 0.07), fp.y - 0.25, fp.z)))
	# une bouée couronne sur le rouf
	var tb := TorusMesh.new()
	tb.inner_radius = 0.17
	tb.outer_radius = 0.24
	tb.rings = 16
	tb.ring_segments = 8
	_add(tb, "bouee", Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(_deck_lat(c1, drop) - 0.62, roof_y - 0.34, _z(c1) + 0.035)))
	# une ancre sur le pont avant
	var za: float = _z(0.88)
	var ya: float = _deck_y(0.88, drop) + 0.03
	_rod(Vector3(0.28, ya, za + 0.32), Vector3(0.28, ya, za - 0.28), 0.025, "fer")
	_rod(Vector3(0.28, ya, za + 0.3), Vector3(0.08, ya, za + 0.18), 0.02, "fer")
	_rod(Vector3(0.28, ya, za + 0.3), Vector3(0.48, ya, za + 0.18), 0.02, "fer")
	_rod(Vector3(0.12, ya, za - 0.22), Vector3(0.44, ya, za - 0.22), 0.015, "fer")
	var floor_mid: float = floor_y + 0.02
	passenger_seats = [Vector3(0.45, bench_top, zc1 + 0.4), Vector3(-0.45, bench_top, zc1 + 0.4), Vector3(0, _deck_y(0.78, drop), _z(0.78)), Vector3(0.0, floor_mid, zm - 0.1), Vector3(0.3, roof_y, (zc1 + zr1) * 0.5)]
	var s_b: float = 0.955
	var lantern_base := Vector3(0.24, _deck_y(s_b, drop), _z(s_b))
	_lay = {
		"lantern": lantern_base, "lantern_h": 0.62,
		"spy": Vector3(0.36, roof_y + 0.06, zc1 - 0.18),
		"cannon": Vector3(-0.32, _deck_y(0.8, drop), _z(0.8)),
		"bed": Vector3(0, _deck_y(c1, drop) - 0.25, (zc1 + zr1) * 0.5), "bed_w": 0.75 if not goe else 0.85,
		"flag": Vector3(beam * 0.22, _top(0.0) - 0.15, length * 0.5 + 0.03), "flag_h": 1.55 if goe else 1.4, "flag_w": 0.78 if goe else 0.62,
		"chimney": Vector3(-0.42 if not goe else -0.5, roof_y - 0.03, zr1 + (0.45 if not goe else 0.9)), "boiler": false,
		"chimney_h": 1.25 if not goe else 1.4, "chimney_r": 0.085 if not goe else 0.1,
		"stern": Vector3(0, _top(0.0), length * 0.5), "transom_w": beam * 0.32,
		"side_z": _z(0.45),
		"roof_y": roof_y,
	}


## Le rouf : un caisson aux flancs un peu rentrés, toit bombé, hublots, porte vers le cockpit.
## Renvoie la hauteur du toit (au milieu).
func _cabin(s0: float, s1: float, h: float, drop: float) -> float:
	var za: float = _z(s0)
	var zf: float = _z(s1)
	var yb: float = minf(_deck_y(s0, drop), _deck_y(s1, drop)) - 0.06
	var yt: float = maxf(_deck_y(s0, drop), _deck_y(s1, drop)) + h
	var wa: float = _deck_lat(s0, drop) - 0.24
	var wf: float = _deck_lat(s1, drop) - 0.3
	var inset: float = 0.07
	var camber: float = 0.07
	var walls := SurfaceTool.new()
	walls.begin(Mesh.PRIMITIVE_TRIANGLES)
	var roof := SurfaceTool.new()
	roof.begin(Mesh.PRIMITIVE_TRIANGLES)
	# coins : bas arrière/avant, haut arrière/avant (côté +x)
	var n: int = 8
	for sd in [-1.0, 1.0]:
		var b0 := Vector3(sd * wa, yb, za)
		var b1 := Vector3(sd * wf, yb, zf)
		var t0 := Vector3(sd * (wa - inset), yt, za)
		var t1 := Vector3(sd * (wf - inset), yt, zf)
		_quad(walls, b0, b1, t1, t0, Vector3(sd, 0.12, 0), Vector2(za, yb), Vector2(zf, yb), Vector2(zf, yt), Vector2(za, yt))
	# faces avant et arrière (avec le bombé du toit)
	for e in [[za, wa, 1.0], [zf, wf, -1.0]]:
		var z: float = e[0]
		var w: float = e[1]
		var nz := Vector3(0, 0, float(e[2]))
		for i in range(n):
			var u0: float = -1.0 + 2.0 * i / n
			var u1: float = -1.0 + 2.0 * (i + 1) / n
			var p0 := Vector3(u0 * w, yb, z)
			var p1 := Vector3(u1 * w, yb, z)
			var q1 := Vector3(u1 * (w - inset), yt + camber * (1.0 - u1 * u1), z)
			var q0 := Vector3(u0 * (w - inset), yt + camber * (1.0 - u0 * u0), z)
			_quad(walls, p0, p1, q1, q0, nz, Vector2(p0.x, p0.y), Vector2(p1.x, p1.y), Vector2(q1.x, q1.y), Vector2(q0.x, q0.y))
	# le toit bombé (débordant un peu)
	for i in range(n):
		var u0: float = -1.0 + 2.0 * i / n
		var u1: float = -1.0 + 2.0 * (i + 1) / n
		var ov: float = 1.03
		var a0 := Vector3(u0 * (wa - inset) * ov, yt + camber * (1.0 - u0 * u0) + 0.02, za + 0.04)
		var a1 := Vector3(u1 * (wa - inset) * ov, yt + camber * (1.0 - u1 * u1) + 0.02, za + 0.04)
		var f1 := Vector3(u1 * (wf - inset) * ov, yt + camber * (1.0 - u1 * u1) + 0.02, zf - 0.04)
		var f0 := Vector3(u0 * (wf - inset) * ov, yt + camber * (1.0 - u0 * u0) + 0.02, zf - 0.04)
		_quad(roof, a0, a1, f1, f0, Vector3.UP, Vector2(a0.x, a0.z), Vector2(a1.x, a1.z), Vector2(f1.x, f1.z), Vector2(f0.x, f0.z))
	walls.generate_normals()
	roof.generate_normals()
	_inst(walls.commit(), "verni", "Rouf")
	_inst(roof.commit(), "creme", "Toit_rouf")
	# hublots (cercle de laiton et verre sombre)
	var nh: int = 3 if (za - zf) > 2.0 else 2
	var tor := TorusMesh.new()
	tor.inner_radius = 0.065
	tor.outer_radius = 0.09
	tor.rings = 14
	tor.ring_segments = 6
	for sd2 in [-1.0, 1.0]:
		for k in range(nh):
			var t: float = (k + 0.5) / nh
			var z2: float = lerpf(za - 0.25, zf + 0.25, t)
			var w2: float = lerpf(wa, wf, (za - z2) / maxf(za - zf, 0.01))
			var y2: float = yb + (yt - yb) * 0.58
			var x2: float = sd2 * (w2 - inset * 0.58 + 0.012)
			var bz := Basis(Vector3.FORWARD, sd2 * PI * 0.5) * Basis(Vector3.FORWARD, 0.0)
			_add(tor, "laiton", Transform3D(bz, Vector3(x2, y2, z2)))
			_add(_cyl(0.068, 0.068, 0.012, 14), "vitre", Transform3D(bz, Vector3(x2 - sd2 * 0.004, y2, z2)))
	# la porte de descente, côté cockpit, et son capot coulissant
	var door_h: float = (yt - yb) - 0.16
	_box(Vector3(0, yb + 0.08 + door_h * 0.5, za + 0.012), Vector3(0.5, door_h, 0.025), "bois_sombre")
	_box(Vector3(0.18, yb + 0.08 + door_h * 0.55, za + 0.03), Vector3(0.04, 0.04, 0.03), "laiton")
	_box(Vector3(0, yt + camber + 0.07, za - 0.32), Vector3(0.66, 0.07, 0.62), "verni")
	# mains courantes sur le toit
	for sd3 in [-1.0, 1.0]:
		var hx: float = sd3 * ((wa + wf) * 0.5 - inset - 0.14)
		_rod(Vector3(hx, yt + camber * 0.6 + 0.09, za - 0.15), Vector3(hx, yt + camber * 0.6 + 0.09, zf + 0.15), 0.016, "verni")
		for zz in [za - 0.15, zf + 0.15]:
			_rod(Vector3(hx, yt + camber * 0.6, zz), Vector3(hx, yt + camber * 0.6 + 0.09, zz), 0.014, "verni")
	return yt + camber


## Gréement du sloop : un mât, une grand-voile bermudienne et un foc sur bout-dehors.
func _rig_sloop(drop: float, roof_y: float) -> void:
	var sm: float = 0.6
	var zm: float = _z(sm)
	var dy: float = _deck_y(sm, drop)
	var top_y: float = dy + 6.6
	_rod(Vector3(0, dy - 0.3, zm), Vector3(0, top_y, zm), 0.085, "verni", 0.05)
	_add(_cyl(0.06, 0.06, 0.08, 10), "laiton", Transform3D(Basis(), Vector3(0, top_y, zm)))
	# barres de flèche
	var spr_y: float = dy + 4.2
	_rod(Vector3(-0.5, spr_y, zm), Vector3(0.5, spr_y, zm), 0.022, "verni")
	# bôme (un peu ouverte sur tribord)
	var by: float = roof_y + 0.55
	var bl: float = 3.0
	var ba: float = deg_to_rad(9.0)
	var clew := Vector3(sin(ba) * bl, by, zm + cos(ba) * bl)
	_rod(Vector3(0, by, zm), clew, 0.05, "verni")
	_sail_inst(_sail_tri(Vector3(0, top_y - 0.25, zm + 0.07), Vector3(0, by + 0.07, zm + 0.08), clew + Vector3(0, 0.07, -0.05), 0.32), "Grand_voile")
	# bout-dehors, étai, foc
	var sb: float = 0.97
	var bow := Vector3(0, _deck_y(sb, drop) + 0.04, _z(sb))
	var tip := Vector3(0, bow.y + 0.12, -length * 0.5 - 1.0)
	_rod(Vector3(0, bow.y, _z(0.86)), tip, 0.045, "verni", 0.035)
	_rod(tip, Vector3(0, draft + 0.15, -length * 0.5 + 0.03), 0.01, "fer")
	var stay_top := Vector3(0, dy + 5.4, zm - 0.04)
	_rod(stay_top, tip, 0.009, "corde")
	_sail_inst(_sail_tri(Vector3(0, dy + 5.2, zm - 0.13), tip + Vector3(0, 0.05, 0.1), Vector3(0.55, dy + 0.85, zm + 0.15), 0.26), "Foc")
	# pataras et haubans
	_rod(Vector3(0, top_y - 0.05, zm), Vector3(0, _top(0.0) + 0.05, length * 0.5 - 0.06), 0.008, "corde")
	var lat: float = _deck_lat(sm, drop) + 0.02
	for sd in [-1.0, 1.0]:
		_rod(Vector3(0, top_y - 0.4, zm), Vector3(sd * 0.5, spr_y, zm), 0.008, "corde")
		_rod(Vector3(sd * 0.5, spr_y, zm), Vector3(sd * lat, dy + 0.05, zm + 0.22), 0.008, "corde")
		_rod(Vector3(0, spr_y, zm), Vector3(sd * lat, dy + 0.05, zm - 0.3), 0.008, "corde")
	# gouvernail et barre franche
	_box(Vector3(0, draft * 0.7, length * 0.5 + 0.16), Vector3(0.06, 1.0, 0.46), "antifouling")
	_box(Vector3(0, _top(0.0) - 0.05, length * 0.5 + 0.06), Vector3(0.07, 0.2, 0.12), "verni")
	_rod(Vector3(0, _top(0.0) + 0.02, length * 0.5 + 0.02), Vector3(-0.42, _top(0.0) + 0.14, length * 0.5 - 0.8), 0.03, "verni", 0.022)


## Gréement de la goélette : deux mâts à voiles auriques, foc, roue de barre.
func _rig_goelette(drop: float, roof_y: float) -> void:
	var masts := [[0.47, 7.6, 3.3, 2.8], [0.72, 6.5, 1.72, 1.7]]
	var tops: Array = []
	for m in masts:
		var sm: float = m[0]
		var zm: float = _z(sm)
		var dy: float = _deck_y(sm, drop)
		var h: float = m[1]
		var top_y: float = dy + h
		tops.append(Vector3(0, top_y - 0.1, zm))
		_rod(Vector3(0, dy - 0.3, zm), Vector3(0, top_y, zm), 0.11, "verni", 0.06)
		_add(_cyl(0.075, 0.075, 0.09, 10), "laiton", Transform3D(Basis(), Vector3(0, top_y, zm)))
		var is_main: bool = sm < 0.5
		var by: float = (roof_y + 0.52) if is_main else (dy + 1.15)
		var bl: float = m[2]
		var ba: float = deg_to_rad(8.0 if is_main else 6.0)
		var clew := Vector3(sin(ba) * bl, by, zm + cos(ba) * bl)
		_rod(Vector3(0, by, zm), clew, 0.055 if is_main else 0.045, "verni")
		var throat := Vector3(0, top_y - h * 0.24, zm + 0.08)
		var gl: float = m[3]
		var peak := Vector3(sin(ba) * gl * 0.8, throat.y + gl * 0.7, zm + 0.08 + gl * 0.75)
		_rod(throat + Vector3(0, -0.02, -0.06), peak, 0.04, "verni")
		_sail_inst(_sail_quad(Vector3(0, by + 0.07, zm + 0.1), throat, peak + Vector3(0, -0.05, 0), clew + Vector3(0, 0.07, -0.06), 0.3), "Voile_aurique")
		# barres de flèche, haubans
		var spr_y: float = top_y - h * 0.3
		_rod(Vector3(-0.55, spr_y, zm), Vector3(0.55, spr_y, zm), 0.025, "verni")
		var lat: float = _deck_lat(sm, drop) + 0.02
		for sd in [-1.0, 1.0]:
			_rod(Vector3(0, top_y - 0.3, zm), Vector3(sd * 0.55, spr_y, zm), 0.009, "corde")
			_rod(Vector3(sd * 0.55, spr_y, zm), Vector3(sd * lat, dy + 0.05, zm + 0.25), 0.009, "corde")
			_rod(Vector3(0, spr_y, zm), Vector3(sd * lat, dy + 0.05, zm - 0.3), 0.009, "corde")
			# enfléchures (quelques échelons)
			for k in range(5):
				var t: float = 0.12 + k * 0.15
				var p0: Vector3 = Vector3(sd * lat, dy + 0.05, zm + 0.25).lerp(Vector3(sd * 0.55, spr_y, zm), t)
				var p1: Vector3 = Vector3(sd * lat, dy + 0.05, zm - 0.3).lerp(Vector3(0, spr_y, zm), t)
				_rod(p0, p1, 0.006, "corde")
	# bout-dehors, foc, étais
	var sb: float = 0.97
	var bow := Vector3(0, _deck_y(sb, drop) + 0.05, _z(sb))
	var tip := Vector3(0, bow.y + 0.18, -length * 0.5 - 1.6)
	_rod(Vector3(0, bow.y, _z(0.85)), tip, 0.06, "verni", 0.04)
	_rod(tip, Vector3(0, draft + 0.18, -length * 0.5 + 0.03), 0.012, "fer")
	var zf: float = _z(0.72)
	var dyf: float = _deck_y(0.72, drop)
	_rod(Vector3(0, dyf + 5.5, zf - 0.05), tip, 0.01, "corde")
	_sail_inst(_sail_tri(Vector3(0, dyf + 5.3, zf - 0.16), tip + Vector3(0, 0.06, 0.14), Vector3(0.6, dyf + 0.9, zf - 0.3), 0.28), "Foc")
	_rod(tops[0], tops[1], 0.009, "corde")
	_rod(tops[0], Vector3(0, _top(0.0) + 0.05, length * 0.5 - 0.06), 0.009, "corde")
	# gouvernail, roue de barre sur sa colonne
	_box(Vector3(0, draft * 0.7, length * 0.5 + 0.17), Vector3(0.07, 1.15, 0.52), "antifouling")
	var zw: float = seat_local.z - 0.74
	var fy: float = seat_local.y - 0.4
	_box(Vector3(0, fy + 0.4, zw), Vector3(0.16, 0.8, 0.16), "verni")
	var wc := Vector3(0, fy + 0.98, zw + 0.06)
	var rim := TorusMesh.new()
	rim.inner_radius = 0.3
	rim.outer_radius = 0.345
	rim.rings = 24
	rim.ring_segments = 6
	_add(rim, "verni", Transform3D(Basis(Vector3.RIGHT, PI * 0.5), wc))
	_add(_cyl(0.06, 0.06, 0.12, 10), "laiton", Transform3D(Basis(Vector3.RIGHT, PI * 0.5), wc))
	for k2 in range(8):
		var a: float = TAU * k2 / 8.0
		var d := Vector3(cos(a), sin(a), 0)
		_rod(wc + d * 0.05, wc + d * 0.44, 0.017, "verni", 0.012)


func update_vr_label(head: Vector3) -> void:
	if vr_label != null:
		vr_label.visible = not driving and can_board(head)


# =================================================================== la forme de la coque

## V76 : un point de la coque (la barque de V29, mise à l'échelle de L x B x D) ; s : 0 = poupe,
## 1 = proue ; a : 0 = quille, 1 = plat-bord. Les shaders de l'eau connaissent cette forme
## (voir _process : on leur passe la coque ramenée aux mesures de la barque).
static func hull_point(s: float, a: float, L: float, B: float, D: float, grow: float = 1.0) -> Vector3:
	var ky: float = D / DEPTH
	var z: float = L * 0.5 - s * L
	var w: float
	if s < 0.42:
		w = B * 0.5 * (0.64 + 0.36 * sin(PI * 0.5 * s / 0.42))
	else:
		w = B * 0.5 * pow(cos(PI * 0.5 * (s - 0.42) / 0.58), 0.75)
	w = maxf(w, 0.015) * grow
	var keel: float = (0.28 * pow(maxf(s - 0.72, 0.0) / 0.28, 2.0) + 0.05 * pow(maxf(0.15 - s, 0.0) / 0.15, 2.0)) * ky
	var top: float = D + 0.2 * ky * pow(s, 3.0)
	var lat: float = w * pow(sin(a * PI * 0.5), 0.7)
	var y: float = keel + (top - keel) * (1.0 - cos(a * PI * 0.5))
	return Vector3(lat, y, z)


func _z(s: float) -> float:
	return length * 0.5 - s * length


func _keel(s: float) -> float:
	return (0.28 * pow(maxf(s - 0.72, 0.0) / 0.28, 2.0) + 0.05 * pow(maxf(0.15 - s, 0.0) / 0.15, 2.0)) * depth / DEPTH


func _top(s: float) -> float:
	return depth + 0.2 * depth / DEPTH * pow(s, 3.0)


## Le paramètre a (0 quille … 1 plat-bord) où la coque atteint la hauteur y à la section s.
func _a_at(s: float, y: float) -> float:
	var k: float = _keel(s)
	var t: float = clampf((y - k) / maxf(_top(s) - k, 0.001), 0.0, 1.0)
	return acos(1.0 - t) / (PI * 0.5)


func _deck_y(s: float, drop: float) -> float:
	return _top(s) - drop


func _deck_lat(s: float, drop: float) -> float:
	return hull_point(s, _a_at(s, _deck_y(s, drop)), length, beam, depth).x * 0.995


## Coque : sections le long de Z (poupe en +Z, proue en -Z), bordé qui remonte vers l'avant.
## a0..a1 : portion de la section (0 = quille, 1 = plat-bord) ; grow : léger gonflement (liseré) ;
## ytop (V76) : on s'arrête à cette hauteur (la carène peinte sous la flottaison).
func _hull_mesh(a0: float = 0.0, a1: float = 1.0, grow: float = 1.0, ytop: float = INF) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ns: int = 28
	var na: int = 10
	var rows: Array = []
	for i in range(ns + 1):
		var s: float = float(i) / ns                     # 0 = poupe, 1 = proue
		var a1r: float = a1 if ytop == INF else minf(a1, _a_at(s, ytop))
		var row: Array = []
		for j in range(na + 1):
			var a: float = lerpf(a0, a1r, float(j) / na)
			row.append(hull_point(s, a, length, beam, depth, grow))
		rows.append(row)
	for side in [1.0, -1.0]:
		for i in range(ns):
			for j in range(na):
				var p00: Vector3 = rows[i][j] * Vector3(side, 1, 1)
				var p01: Vector3 = rows[i][j + 1] * Vector3(side, 1, 1)
				var p10: Vector3 = rows[i + 1][j] * Vector3(side, 1, 1)
				var p11: Vector3 = rows[i + 1][j + 1] * Vector3(side, 1, 1)
				if side > 0.0:
					st.add_vertex(p00); st.add_vertex(p11); st.add_vertex(p10)
					st.add_vertex(p00); st.add_vertex(p01); st.add_vertex(p11)
				else:
					st.add_vertex(p00); st.add_vertex(p10); st.add_vertex(p11)
					st.add_vertex(p00); st.add_vertex(p11); st.add_vertex(p01)
	# Tableau arrière (poupe plate).
	if a0 == 0.0:
		var back: Array = rows[0]
		for j in range(na):
			for side2 in [1.0, -1.0]:
				var q0: Vector3 = Vector3(0, back[j].y, back[j].z)
				var q1: Vector3 = back[j] * Vector3(side2, 1, 1)
				var q2: Vector3 = back[j + 1] * Vector3(side2, 1, 1)
				var q3: Vector3 = Vector3(0, back[j + 1].y, back[j + 1].z)
				st.add_vertex(q0); st.add_vertex(q1); st.add_vertex(q2)
				st.add_vertex(q0); st.add_vertex(q2); st.add_vertex(q3)
	st.generate_normals()
	return st.commit()


## V76 : le pont (planches dans le sens de la longueur), percé du cockpit (s0..s1, demi-largeur cw).
func _deck_mesh(s0: float, s1: float, cw: float, drop: float) -> ArrayMesh:
	var ss: Array = []
	for i in range(41):
		ss.append(minf(float(i) / 40.0, 0.988))
	ss.append(s0)
	ss.append(s1)
	ss.sort()
	var rows: Array = []
	var last: float = -1.0
	for s in ss:
		if float(s) - last < 0.0005:
			continue
		last = float(s)
		rows.append([float(s), _deck_y(float(s), drop), _deck_lat(float(s), drop), _z(float(s))])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(rows.size() - 1):
		var r0: Array = rows[i]
		var r1: Array = rows[i + 1]
		var mid: float = (float(r0[0]) + float(r1[0])) * 0.5
		var spans: Array = [[-1.0, 1.0]]
		if mid > s0 and mid < s1:
			spans = [[-1.0, -cw], [cw, 1.0]]
		for sp in spans:
			var xa0: float = float(r0[2]) * float(sp[0]) if absf(float(sp[0])) == 1.0 else float(sp[0])
			var xb0: float = float(r0[2]) * float(sp[1]) if absf(float(sp[1])) == 1.0 else float(sp[1])
			var xa1: float = float(r1[2]) * float(sp[0]) if absf(float(sp[0])) == 1.0 else float(sp[0])
			var xb1: float = float(r1[2]) * float(sp[1]) if absf(float(sp[1])) == 1.0 else float(sp[1])
			var a := Vector3(xa0, r0[1], r0[3])
			var b := Vector3(xb0, r0[1], r0[3])
			var c := Vector3(xb1, r1[1], r1[3])
			var d := Vector3(xa1, r1[1], r1[3])
			var k: float = 1.3
			_quad(st, a, b, c, d, Vector3.UP, Vector2(a.z / k, a.x / k), Vector2(b.z / k, b.x / k), Vector2(c.z / k, c.x / k), Vector2(d.z / k, d.x / k))
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


## V76 : le plat-bord (une lisse de bois verni sur le haut de la coque, des deux bords).
func _rail_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 30
	for side in [1.0, -1.0]:
		for i in range(n):
			var sa: float = float(i) / n * 0.99
			var sb: float = float(i + 1) / n * 0.99
			var pa: Vector3 = hull_point(sa, 1.0, length, beam, depth) * Vector3(side, 1, 1)
			var pb: Vector3 = hull_point(sb, 1.0, length, beam, depth) * Vector3(side, 1, 1)
			var oa := Vector3(side * 0.025, 0, 0)
			var ia := Vector3(-side * 0.055, 0, 0)
			var up := Vector3(0, 0.045, 0)
			# dessus, flanc extérieur, flanc intérieur
			_quad(st, pa + oa + up, pb + oa + up, pb + ia + up, pa + ia + up, Vector3.UP, Vector2(pa.z, 0), Vector2(pb.z, 0), Vector2(pb.z, 0.1), Vector2(pa.z, 0.1))
			_quad(st, pa + oa, pb + oa, pb + oa + up, pa + oa + up, Vector3(side, 0, 0), Vector2(pa.z, 0), Vector2(pb.z, 0), Vector2(pb.z, 0.1), Vector2(pa.z, 0.1))
			_quad(st, pa + ia, pb + ia, pb + ia + up, pa + ia + up, Vector3(-side, 0, 0), Vector2(pa.z, 0), Vector2(pb.z, 0), Vector2(pb.z, 0.1), Vector2(pa.z, 0.1))
	st.generate_normals()
	return st.commit()


func _sail_mesh(head: Vector3, tack: Vector3, clew: Vector3) -> ArrayMesh:
	# Voile légèrement creusée par le vent (bombée vers +X).
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 8
	var grid: Array = []
	for i in range(n + 1):
		var u: float = float(i) / n
		var row: Array = []
		for j in range(n + 1 - i):
			var v: float = float(j) / n
			var p: Vector3 = tack + (head - tack) * u + (clew - tack) * v
			p.x += sin(PI * u) * sin(PI * minf(v / maxf(1.0 - u, 0.001), 1.0)) * 0.22
			row.append(p)
		grid.append(row)
	for i in range(n):
		for j in range(n - i):
			st.add_vertex(grid[i][j]); st.add_vertex(grid[i + 1][j]); st.add_vertex(grid[i][j + 1])
			if j + 1 < grid[i + 1].size():
				st.add_vertex(grid[i + 1][j]); st.add_vertex(grid[i + 1][j + 1]); st.add_vertex(grid[i][j + 1])
	st.generate_normals()
	return st.commit()


## V76 : voile triangulaire texturée (laizes), creusée vers +X.
func _sail_tri(head: Vector3, tack: Vector3, clew: Vector3, belly: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 10
	var grid: Array = []
	var foot: float = tack.distance_to(clew)
	var luff: float = tack.distance_to(head)
	for i in range(n + 1):
		var u: float = float(i) / n
		var row: Array = []
		for j in range(n + 1 - i):
			var v: float = float(j) / n
			var p: Vector3 = tack + (head - tack) * u + (clew - tack) * v
			p.x += sin(PI * u) * sin(PI * minf(v / maxf(1.0 - u, 0.001), 1.0)) * belly * (1.0 - 0.4 * u)
			row.append([p, Vector2(v * foot / 2.0, (1.0 - u) * luff / 2.0)])
		grid.append(row)
	for i in range(n):
		for j in range(n - i):
			_vtx(st, grid[i][j]); _vtx(st, grid[i + 1][j]); _vtx(st, grid[i][j + 1])
			if j + 1 < grid[i + 1].size():
				_vtx(st, grid[i + 1][j]); _vtx(st, grid[i + 1][j + 1]); _vtx(st, grid[i][j + 1])
	st.generate_normals()
	return st.commit()


## V76 : voile aurique (quadrilatère : point d'amure, gorge, pic, point d'écoute).
func _sail_quad(tack: Vector3, throat: Vector3, peak: Vector3, clew: Vector3, belly: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 10
	var grid: Array = []
	var foot: float = tack.distance_to(clew)
	var luff: float = maxf(tack.distance_to(throat), clew.distance_to(peak))
	for i in range(n + 1):
		var u: float = float(i) / n
		var row: Array = []
		for j in range(n + 1):
			var v: float = float(j) / n
			var p: Vector3 = tack.lerp(throat, u).lerp(clew.lerp(peak, u), v)
			p.x += sin(PI * u) * sin(PI * v) * belly
			row.append([p, Vector2(v * foot / 2.0, (1.0 - u) * luff / 2.0)])
		grid.append(row)
	for i in range(n):
		for j in range(n):
			_vtx(st, grid[i][j]); _vtx(st, grid[i + 1][j]); _vtx(st, grid[i][j + 1])
			_vtx(st, grid[i + 1][j]); _vtx(st, grid[i + 1][j + 1]); _vtx(st, grid[i][j + 1])
	st.generate_normals()
	return st.commit()


func _vtx(st: SurfaceTool, e: Array) -> void:
	st.set_uv(e[1])
	st.add_vertex(e[0])


## Un quadrilatère a-b-c-d vu depuis n (l'ordre des sommets est corrigé au besoin).
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2) -> void:
	_tri(st, [a, ua], [b, ub], [c, uc], n)
	_tri(st, [a, ua], [c, uc], [d, ud], n)


func _tri(st: SurfaceTool, a: Array, b: Array, c: Array, n: Vector3) -> void:
	var pa: Vector3 = a[0]
	var pb: Vector3 = b[0]
	var pc: Vector3 = c[0]
	if (pb - pa).cross(pc - pa).dot(n) > 0.0:
		var t: Array = b
		b = c
		c = t
	for e in [a, b, c]:
		st.set_uv(e[1])
		st.add_vertex(e[0])


# =================================================================== V76 : pièces regroupées

func _cyl(top: float, bottom: float, h: float, seg: int = 8) -> CylinderMesh:
	var key: String = "c%.3f_%.3f_%.3f_%d" % [top, bottom, h, seg]
	if _meshes.has(key):
		return _meshes[key]
	var cm := CylinderMesh.new()
	cm.top_radius = top
	cm.bottom_radius = bottom
	cm.height = h
	cm.radial_segments = seg
	cm.rings = 1
	_meshes[key] = cm
	return cm


func _box(center: Vector3, size: Vector3, key: String, basis: Basis = Basis()) -> void:
	var k: String = "b%.3f_%.3f_%.3f" % [size.x, size.y, size.z]
	if not _meshes.has(k):
		var bm := BoxMesh.new()
		bm.size = size
		_meshes[k] = bm
	_add(_meshes[k], key, Transform3D(basis, center))


## Un cylindre de a à b (rayon r en a, r_top en b si donné).
func _rod(a: Vector3, b: Vector3, r: float, key: String, r_top: float = -1.0) -> void:
	var d: Vector3 = b - a
	var l: float = d.length()
	if l < 0.001:
		return
	var seg: int = 6 if r < 0.015 else (8 if r < 0.05 else 12)
	_add(_cyl(r_top if r_top >= 0.0 else r, r, l, seg), key, Transform3D(_basis_y(d / l), (a + b) * 0.5))


static func _basis_y(y: Vector3) -> Basis:
	var ref: Vector3 = Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x: Vector3 = y.cross(ref).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


func _add(mesh: Mesh, key: String, xf: Transform3D) -> void:
	if not _batch.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_batch[key] = st
	(_batch[key] as SurfaceTool).append_from(mesh, 0, xf)


func _commit_batch() -> void:
	for key in _batch:
		var mi := MeshInstance3D.new()
		mi.name = ("NoShadow_" if str(key) in ["lanterne", "cristal", "cristal_violet", "vitre"] else "Pieces_") + str(key)
		mi.mesh = (_batch[key] as SurfaceTool).commit()
		mi.material_override = _mat(str(key))
		hull.add_child(mi)
	_batch.clear()


func _inst(mesh: Mesh, key: String, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	mi.mesh = mesh
	mi.material_override = _mat(key)
	hull.add_child(mi)
	return mi


func _sail_inst(mesh: Mesh, label: String) -> void:
	# les voiles sur le calque 2 : le projecteur de la lanterne (calque 1) ne les éblouit pas
	_inst(mesh, "voile", label).layers = 2


func _tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


func _mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.roughness = 0.8
	match key:
		"bois":
			return _wood
		"verni", "bois_sombre", "bois_clair":
			m.albedo_texture = _tex("res://assets/textures/doors/wood_plain.png")
			m.uv1_triplanar = true
			m.uv1_scale = Vector3(2.2, 2.2, 2.2)
			m.albedo_color = {"verni": Color(0.78, 0.5, 0.3), "bois_sombre": Color(0.42, 0.28, 0.18), "bois_clair": Color(1.0, 0.86, 0.66)}[key]
			m.roughness = 0.32 if key == "verni" else 0.7
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"bordage", "coque":
			m.normal_enabled = true
			m.normal_texture = _tex("res://assets/textures/carene/bordage_n.png")
			m.normal_scale = 0.8
			m.uv1_triplanar = true
			m.uv1_scale = Vector3(0.6, 0.6, 0.6)
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			if key == "coque":
				# la peinture : coque vue de l'extérieur seulement (l'intérieur reste en bois)
				m.cull_mode = BaseMaterial3D.CULL_BACK
				m.normal_scale = 0.3
				m.uv1_scale = Vector3(0.4, 0.4, 0.4)
			if key == "bordage":
				m.albedo_texture = _tex("res://assets/textures/carene/bordage.png")
				m.albedo_color = Color(1.1, 0.98, 0.86)
				m.roughness = 0.5
			else:
				m.albedo_color = (COULEURS.get(couleur, COULEURS["bleu"]) as Array)[0]
				m.roughness = 0.36
		"lisere":
			if couleur == "":
				m.albedo_color = Color(0.13, 0.32, 0.38)
			elif couleur in ["blanc", "jaune", "rose"]:
				m.albedo_color = Color(0.1, 0.19, 0.4)
			else:
				m.albedo_color = Color(0.94, 0.9, 0.78)
			m.roughness = 0.45
		"antifouling":
			m.albedo_color = Color(0.4, 0.1, 0.07)
			m.roughness = 0.75
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"pont":
			m.albedo_texture = _tex("res://assets/textures/carene/pont.png")
			m.normal_enabled = true
			m.normal_texture = _tex("res://assets/textures/carene/pont_n.png")
			m.albedo_color = Color(1.12, 1.02, 0.9)
			m.roughness = 0.72
		"voile":
			m.albedo_texture = sail_texture()
			m.albedo_color = Color(0.93, 0.9, 0.82)
			m.roughness = 0.95
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.backlight_enabled = true
			m.backlight = Color(0.42, 0.4, 0.33)
		"corde":
			m.albedo_color = Color(0.62, 0.52, 0.36)
			m.roughness = 0.95
		"laiton":
			m.albedo_color = Color(0.8, 0.6, 0.27)
			m.metallic = 0.85
			m.roughness = 0.3
		"fer":
			m.albedo_color = Color(0.1, 0.1, 0.11)
			m.metallic = 0.6
			m.roughness = 0.45
		"noir":
			m.albedo_color = Color(0.05, 0.05, 0.055)
			m.metallic = 0.35
			m.roughness = 0.5
		"rouge":
			m.albedo_color = Color(0.66, 0.09, 0.06)
			m.roughness = 0.45
		"creme":
			m.albedo_color = Color(0.93, 0.89, 0.8)
			m.roughness = 0.6
		"blanc", "pare_battage":
			m.albedo_color = Color(0.94, 0.94, 0.92)
			m.roughness = 0.4
		"bouee":
			m.albedo_color = Color(0.9, 0.22, 0.12)
			m.roughness = 0.5
		"vitre":
			m.albedo_color = Color(0.05, 0.08, 0.09)
			m.metallic = 0.4
			m.roughness = 0.05
		"lanterne":
			m.albedo_color = Color(1.0, 0.9, 0.7)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.72, 0.38)
			m.emission_energy_multiplier = 0.0
			var t: Node = main.get("temps_v56") if main != null else null
			if t != null:
				t.register_glow(m, 4.0, 0.0)
		"cristal", "cristal_violet":
			m.albedo_color = Color(0.55, 0.92, 1.0) if key == "cristal" else Color(0.82, 0.6, 1.0)
			m.emission_enabled = true
			m.emission = Color(0.35, 0.85, 1.0) if key == "cristal" else Color(0.72, 0.42, 1.0)
			m.emission_energy_multiplier = 2.2
			m.roughness = 0.08
			m.metallic_specular = 0.9
			m.rim_enabled = true
			m.rim = 0.6
			_glow.append([m, 2.2])
		"matelas":
			m.albedo_color = Color(0.9, 0.87, 0.8)
			m.roughness = 0.95
		"couverture":
			m.albedo_color = Color(0.6, 0.16, 0.15)
			m.roughness = 0.95
		"canon":
			m.albedo_color = Color(0.95, 0.4, 0.66)
			m.roughness = 0.35
			m.metallic = 0.2
		"or":
			m.albedo_color = Color(0.98, 0.78, 0.25)
			m.metallic = 0.75
			m.roughness = 0.28
		"bleu_ciel":
			m.albedo_color = Color(0.3, 0.7, 0.95)
			m.roughness = 0.4
		"cuir":
			m.albedo_color = Color(0.32, 0.19, 0.1)
			m.roughness = 0.6
		_:
			m.albedo_color = Color(1, 0, 1)
	_mats[key] = m
	return m


## La toile des voiles neuves (laizes cousues), dessinée une fois pour toutes.
static func sail_texture() -> ImageTexture:
	if _sail_tex != null:
		return _sail_tex
	var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
	img.fill(Color(0.94, 0.91, 0.83))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7601
	for k in range(900):
		var x: int = rng.randi_range(0, 250)
		var y: int = rng.randi_range(0, 254)
		var g: float = rng.randf_range(-0.035, 0.02)
		img.fill_rect(Rect2i(x, y, rng.randi_range(2, 6), 1), Color(0.94 + g, 0.91 + g, 0.83 + g))
	for y2 in range(0, 256, 32):
		img.fill_rect(Rect2i(0, y2, 256, 2), Color(0.8, 0.77, 0.69))
		img.fill_rect(Rect2i(0, y2 + 2, 256, 1), Color(0.97, 0.95, 0.89))
		img.fill_rect(Rect2i(0, y2 + 6, 256, 1), Color(0.86, 0.83, 0.75))
	img.generate_mipmaps()
	_sail_tex = ImageTexture.create_from_image(img)
	return _sail_tex


# =================================================================== V76 : propulsion

func _model_propulsion() -> void:
	match propulsion:
		2:
			_model_vapeur()
		3:
			_model_cristal()


## La vapeur : chaudière (barque) ou cheminée qui sort du rouf, fumée, hélice, bouillons.
func _model_vapeur() -> void:
	var base: Vector3 = _lay["chimney"]
	var r: float = _lay["chimney_r"]
	var h: float = _lay["chimney_h"]
	var y0: float = base.y
	if bool(_lay.get("boiler", false)):
		_add(_cyl(0.2, 0.22, 0.42, 14), "fer", Transform3D(Basis(), base + Vector3(0, 0.21, 0)))
		_add(_cyl(0.205, 0.205, 0.035, 14), "laiton", Transform3D(Basis(), base + Vector3(0, 0.1, 0)))
		_add(_cyl(0.205, 0.205, 0.035, 14), "laiton", Transform3D(Basis(), base + Vector3(0, 0.33, 0)))
		_add(_cyl(0.06, 0.06, 0.08, 8), "laiton", Transform3D(Basis(Vector3.FORWARD, PI * 0.5), base + Vector3(0.21, 0.26, 0)))
		y0 = base.y + 0.42
	else:
		_add(_cyl(r * 1.9, r * 2.1, 0.06, 12), "laiton", Transform3D(Basis(), base + Vector3(0, 0.03, 0)))
	var top := Vector3(base.x, y0 + h, base.z)
	_rod(Vector3(base.x, y0, base.z), top, r, "noir", r * 0.92)
	_add(_cyl(r * 1.02, r * 1.02, h * 0.12, 12), "rouge", Transform3D(Basis(), top + Vector3(0, -h * 0.14, 0)))
	_add(_cyl(r * 1.25, r * 1.08, 0.05, 12), "laiton", Transform3D(Basis(), top))
	# sifflet
	_rod(top + Vector3(r * 1.1, -h * 0.35, 0), top + Vector3(r * 1.1, -h * 0.2, 0), r * 0.25, "laiton")
	# l'hélice sous la poupe (on la devine sous l'eau)
	var st: Vector3 = Vector3(0, draft * 0.45, length * 0.5 - 0.05)
	_add(_cyl(0.05, 0.05, 0.12, 8), "laiton", Transform3D(Basis(Vector3.RIGHT, PI * 0.5), st))
	for k in range(3):
		var a: float = TAU * k / 3.0
		_box(st + Vector3(cos(a), sin(a), 0) * 0.13, Vector3(0.16, 0.05, 0.015), "laiton", Basis(Vector3.BACK, a) * Basis(Vector3.RIGHT, 0.5))
	# la fumée
	_smoke = _particles("Fumee", 46, 3.6, top + Vector3(0, 0.08, 0), _soft_mat(Color(0.55, 0.55, 0.56, 0.5), false), 0.55)
	var pm: ParticleProcessMaterial = _smoke.process_material
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 12.0
	pm.initial_velocity_min = 1.2
	pm.initial_velocity_max = 1.9
	pm.gravity = Vector3(0, 0.35, 0)
	pm.damping_min = 0.4
	pm.damping_max = 0.8
	pm.scale_min = 0.6
	pm.scale_max = 1.0
	pm.scale_curve = _curve_tex([Vector2(0, 0.35), Vector2(1, 2.6)])
	pm.color_ramp = _ramp([Color(0.2, 0.2, 0.21, 0.8), Color(0.36, 0.36, 0.38, 0.5), Color(0.55, 0.55, 0.58, 0.0)])
	# les bouillons à l'arrière
	_foam = _particles("Bouillons", 40, 1.4, Vector3(0, draft + 0.06, length * 0.5 + 0.25), _soft_mat(Color(1, 1, 1, 0.75), false), 0.42)
	var pf: ParticleProcessMaterial = _foam.process_material
	pf.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pf.emission_box_extents = Vector3(0.25, 0.02, 0.15)
	pf.direction = Vector3(0, 1, 0.3)
	pf.spread = 40.0
	pf.initial_velocity_min = 0.6
	pf.initial_velocity_max = 1.4
	pf.gravity = Vector3(0, -2.5, 0)
	pf.scale_curve = _curve_tex([Vector2(0, 0.6), Vector2(1, 1.8)])
	pf.color_ramp = _ramp([Color(1, 1, 1, 0.85), Color(0.92, 0.96, 1.0, 0.0)])
	_engine_sound("bateau_vapeur")


## Le cristal des Lumens : une gerbe de cristaux à la poupe, des éclats sur les flancs,
## un sillage de lumière.
func _model_cristal() -> void:
	var s: Vector3 = _lay["stern"]
	var holder := s + Vector3(-float(_lay["transom_w"]) * 0.55, -0.16, 0.1)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.16
	ring.outer_radius = 0.2
	ring.rings = 16
	ring.ring_segments = 6
	_add(ring, "laiton", Transform3D(Basis(), holder + Vector3(0, 0.05, 0.05)))
	for k in range(3):
		var a: float = -0.5 + k * 0.5
		var col: String = "cristal" if k != 1 else "cristal_violet"
		var dir := Vector3(sin(a) * 0.55, 1.0, 0.45).normalized()
		var hgt: float = 0.42 if k == 1 else 0.3
		var b: Vector3 = holder + Vector3(sin(a) * 0.08, 0.04, 0.05)
		_rod(b, b + dir * hgt, 0.065 if k == 1 else 0.05, col)
		_rod(b + dir * hgt, b + dir * (hgt + 0.16), 0.065 if k == 1 else 0.05, col, 0.0)
		_rod(b - dir * 0.04, b + dir * 0.06, (0.075 if k == 1 else 0.06), "laiton")
	# éclats sur les flancs, près de la flottaison
	for sd in [-1.0, 1.0]:
		for dz in [-0.35, 0.35]:
			var p: Vector3 = hull_point(clampf((length * 0.5 - float(_lay["side_z"]) - dz) / length, 0.0, 1.0), 0.6, length, beam, depth, 1.02)
			var at := Vector3(sd * p.x, p.y, p.z)
			_rod(at, at + Vector3(sd * 0.06, 0.02, 0.18), 0.03, "cristal", 0.0)
	var light := OmniLight3D.new()
	light.name = "Lueur_cristal"
	light.light_color = Color(0.45, 0.85, 1.0)
	light.light_energy = 1.0
	light.omni_range = 5.0
	light.shadow_enabled = false
	light.position = holder + Vector3(0, 0.35, 0.1)
	hull.add_child(light)
	# le sillage lumineux (les éclats restent sur l'eau, derrière le bateau)
	var wm := _soft_mat(Color(0.5, 0.9, 1.0, 0.9), true)
	_wake = _particles("Sillage", 150, 4.5, Vector3(0, draft + 0.03, length * 0.5 + 0.15), wm, 0.38)
	var pw: ParticleProcessMaterial = _wake.process_material
	pw.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pw.emission_box_extents = Vector3(beam * 0.28, 0.01, 0.2)
	pw.direction = Vector3(0, 1, 0)
	pw.spread = 60.0
	pw.initial_velocity_min = 0.05
	pw.initial_velocity_max = 0.25
	pw.gravity = Vector3(0, 0.02, 0)
	pw.scale_min = 0.5
	pw.scale_max = 1.2
	pw.scale_curve = _curve_tex([Vector2(0, 1.0), Vector2(0.3, 1.25), Vector2(1, 0.0)])
	pw.color_ramp = _ramp([Color(0.6, 0.95, 1.0, 1.0), Color(0.75, 0.55, 1.0, 0.7), Color(0.4, 0.6, 1.0, 0.0)])
	_engine_sound("bateau_cristal")


func _soft_mat(col: Color, additive: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_color = col
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	m.disable_receive_shadows = true
	return m


func _particles(label: String, amount: int, life: float, at: Vector3, mat: Material, size: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = label
	p.amount = amount
	p.lifetime = life
	p.local_coords = false
	p.emitting = false
	p.position = at
	p.visibility_aabb = AABB(Vector3(-40, -10, -40), Vector3(80, 30, 80))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	p.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(size, size)
	qm.material = mat
	p.draw_pass_1 = qm
	hull.add_child(p)
	return p


func _ramp(cols: Array) -> GradientTexture1D:
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	var cs := PackedColorArray()
	for i in range(cols.size()):
		offs.append(float(i) / maxf(cols.size() - 1, 1))
		cs.append(cols[i])
	g.offsets = offs
	g.colors = cs
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


func _curve_tex(pts: Array) -> CurveTexture:
	var c := Curve.new()
	var mx: float = 1.0
	for p in pts:
		mx = maxf(mx, (p as Vector2).y)
	c.max_value = mx
	for p2 in pts:
		c.add_point(p2)
	var t := CurveTexture.new()
	t.curve = c
	return t


## Le bruit du moteur : une boucle (sons/sfx/<nom>_1.ogg) si elle existe.
func _engine_sound(name: String) -> void:
	var s: AudioStream = _sfx_stream(name)
	if s == null:
		return
	_engine = AudioStreamPlayer3D.new()
	_engine.name = "Moteur"
	var dup: AudioStream = s.duplicate()
	if dup is AudioStreamOggVorbis:
		(dup as AudioStreamOggVorbis).loop = true
	elif dup is AudioStreamWAV:
		(dup as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_engine.stream = dup
	_engine.bus = "Bruitages" if AudioServer.get_bus_index("Bruitages") >= 0 else "Master"
	_engine.unit_size = 5.0
	_engine.volume_db = -60.0
	_engine.position = Vector3(0, 0.6, length * 0.25)
	hull.add_child(_engine)


func _sfx_stream(name: String) -> AudioStream:
	var fx: Node = main.get("sfx_v50") if main != null else null
	if fx != null and fx.has_method("_variants"):
		var list: Array = fx._variants(name)
		if not list.is_empty():
			return list[0]
	var p: String = "res://assets/sons/sfx/%s_1.ogg" % name
	return load(p) if ResourceLoader.exists(p) else null


func _has_sfx(name: String) -> bool:
	return _sfx_stream(name) != null


# =================================================================== V76 : accessoires

func _model_accessoires() -> void:
	if accessoires.has("lanterne"):
		_model_lanterne()
	if accessoires.has("longue_vue"):
		_model_longue_vue()
	if accessoires.has("couchette"):
		_model_couchette()
	if accessoires.has("canon"):
		_model_canon()
	if accessoires.has("pavillon") and pavillon > 0:
		_model_pavillon()


## La lanterne de proue : une vraie lumière la nuit (projecteur vers l'avant + halo).
func _model_lanterne() -> void:
	var b: Vector3 = _lay["lantern"]
	var h: float = _lay["lantern_h"]
	var top := b + Vector3(0, h, 0)
	_rod(b, top, 0.025, "verni")
	_rod(top, top + Vector3(0, 0, -0.2), 0.015, "fer")
	var lp := top + Vector3(0, -0.15, -0.2)
	_add(_cyl(0.005, 0.07, 0.07, 8), "fer", Transform3D(Basis(), lp + Vector3(0, 0.12, 0)))
	_add(_cyl(0.06, 0.06, 0.16, 8), "lanterne", Transform3D(Basis(), lp))
	for k in range(4):
		var a: float = TAU * k / 4.0 + PI * 0.25
		_rod(lp + Vector3(cos(a) * 0.062, -0.08, sin(a) * 0.062), lp + Vector3(cos(a) * 0.062, 0.08, sin(a) * 0.062), 0.007, "laiton")
	_add(_cyl(0.07, 0.07, 0.02, 8), "laiton", Transform3D(Basis(), lp + Vector3(0, -0.09, 0)))
	var spot := SpotLight3D.new()
	spot.name = "Lanterne_projecteur"
	spot.light_color = Color(1.0, 0.86, 0.62)
	spot.spot_range = 40.0
	spot.spot_angle = 34.0
	spot.spot_attenuation = 0.9
	spot.shadow_enabled = false
	spot.light_cull_mask = 1
	spot.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-7.0)), lp + Vector3(0, 0, -0.08))
	hull.add_child(spot)
	var halo := OmniLight3D.new()
	halo.name = "Lanterne_halo"
	halo.light_color = Color(1.0, 0.8, 0.52)
	halo.omni_range = 7.0
	halo.shadow_enabled = false
	halo.light_cull_mask = 1
	halo.position = lp
	hull.add_child(halo)
	var t: Node = main.get("temps_v56") if main != null else null
	if t != null:
		t.register_lamp(spot, 5.0)
		t.register_lamp(halo, 1.6)
	else:
		spot.light_energy = 5.0
		halo.light_energy = 1.6


## La longue-vue de laiton, dans son support près du barreur.
func _model_longue_vue() -> void:
	var p: Vector3 = _lay["spy"]
	_box(p + Vector3(0, 0.02, 0), Vector3(0.1, 0.04, 0.34), "verni")
	var a := p + Vector3(0, 0.08, 0.2)
	var b := p + Vector3(0, 0.08, -0.22)
	_rod(a, a.lerp(b, 0.45), 0.032, "laiton", 0.032)
	_rod(a.lerp(b, 0.45), b, 0.026, "laiton", 0.024)
	_rod(a.lerp(b, 0.2), a.lerp(b, 0.36), 0.035, "cuir")
	_rod(b, b + Vector3(0, 0, -0.03), 0.03, "laiton")


## La couchette : un matelas, un oreiller, une couverture rouge.
func _model_couchette() -> void:
	var p: Vector3 = _lay["bed"]
	var w: float = _lay["bed_w"]
	if coque <= 1:
		# barque : un couchage roulé et sanglé, à l'avant
		_add(_cyl(0.13, 0.13, w, 12), "matelas", Transform3D(Basis(Vector3.BACK, PI * 0.5), p))
		_add(_cyl(0.135, 0.135, w * 0.55, 12), "couverture", Transform3D(Basis(Vector3.BACK, PI * 0.5), p))
		for sx in [-0.22, 0.22]:
			_add(_cyl(0.14, 0.14, 0.03, 12), "cuir", Transform3D(Basis(Vector3.BACK, PI * 0.5), p + Vector3(sx, 0, 0)))
		_box(p + Vector3(0, 0.02, 0.3), Vector3(0.34, 0.1, 0.22), "blanc")
	else:
		# dans le rouf : une couchette en bois
		_box(p, Vector3(w, 0.12, 1.5), "verni")
		_box(p + Vector3(0, 0.1, 0), Vector3(w - 0.06, 0.1, 1.44), "matelas")
		_box(p + Vector3(0, 0.17, 0.2), Vector3(w - 0.04, 0.05, 0.9), "couverture")
		_box(p + Vector3(0, 0.19, -0.55), Vector3(w * 0.6, 0.09, 0.28), "blanc")


## Le canon à confettis : un petit fût rose cerclé d'or sur son affût.
func _model_canon() -> void:
	var p: Vector3 = _lay["cannon"]
	var up: float = deg_to_rad(24.0)
	_box(p + Vector3(0, 0.07, 0.02), Vector3(0.2, 0.08, 0.34), "verni")
	for sx in [-0.12, 0.12]:
		for sz in [-0.1, 0.12]:
			_add(_cyl(0.055, 0.055, 0.03, 10), "rouge", Transform3D(Basis(Vector3.BACK, PI * 0.5), p + Vector3(sx, 0.055, sz)))
	var pivot := p + Vector3(0, 0.15, 0.05)
	var dir := Vector3(0, sin(up), -cos(up))
	var tip: Vector3 = pivot + dir * 0.42
	_rod(pivot - dir * 0.1, tip, 0.065, "canon", 0.05)
	for t in [0.0, 0.45, 0.95]:
		var c: Vector3 = (pivot - dir * 0.1).lerp(tip, t)
		_add(_cyl(0.068 - t * 0.014, 0.068 - t * 0.014, 0.025, 12), "or", Transform3D(_basis_y(dir), c))
	_add(_cyl(0.06, 0.06, 0.03, 10), "or", Transform3D(Basis(), pivot - dir * 0.13))
	_muzzle = Node3D.new()
	_muzzle.name = "Bouche_canon"
	_muzzle.position = tip
	_muzzle.basis = _basis_y(dir)
	hull.add_child(_muzzle)
	var cm := StandardMaterial3D.new()
	cm.vertex_color_use_as_albedo = true
	cm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	cm.cull_mode = BaseMaterial3D.CULL_DISABLED
	cm.roughness = 0.6
	cm.emission_enabled = true
	cm.emission = Color(0.25, 0.25, 0.25)
	_confetti = GPUParticles3D.new()
	_confetti.name = "Confettis"
	_confetti.amount = 180
	_confetti.lifetime = 3.2
	_confetti.one_shot = true
	_confetti.explosiveness = 0.92
	_confetti.local_coords = false
	_confetti.emitting = false
	_confetti.visibility_aabb = AABB(Vector3(-30, -20, -30), Vector3(60, 40, 60))
	_confetti.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 22.0
	pm.initial_velocity_min = 6.0
	pm.initial_velocity_max = 10.0
	pm.gravity = Vector3(0, -3.2, 0)
	pm.damping_min = 1.2
	pm.damping_max = 2.2
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	pm.angular_velocity_min = -400.0
	pm.angular_velocity_max = 400.0
	pm.scale_min = 0.7
	pm.scale_max = 1.3
	pm.color_initial_ramp = _ramp([Color(1.0, 0.25, 0.35), Color(1.0, 0.8, 0.15), Color(0.3, 0.85, 0.4), Color(0.25, 0.6, 1.0), Color(0.8, 0.35, 1.0), Color(1.0, 0.5, 0.8)])
	_confetti.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(0.075, 0.05)
	qm.material = cm
	_confetti.draw_pass_1 = qm
	_muzzle.add_child(_confetti)


## Le pavillon : une hampe à la poupe, le drapeau choisi qui flotte au vent.
func _model_pavillon() -> void:
	var b: Vector3 = _lay["flag"]
	var h: float = _lay["flag_h"]
	var w: float = _lay["flag_w"]
	var top := b + Vector3(0, h, 0)
	_rod(b, top, 0.022, "verni", 0.016)
	_add(_cyl(0.03, 0.03, 0.04, 8), "or", Transform3D(Basis(), top + Vector3(0, 0.02, 0)))
	var qm := QuadMesh.new()
	qm.size = Vector2(w, w * 0.66)
	qm.subdivide_width = 10
	qm.subdivide_depth = 3
	var mi := MeshInstance3D.new()
	mi.name = "Pavillon"
	mi.mesh = qm
	var sm := ShaderMaterial.new()
	sm.shader = _flag_shader()
	sm.set_shader_parameter("tex", flag_texture(pavillon))
	sm.set_shader_parameter("w", w)
	mi.material_override = sm
	# le drapeau flotte vers l'arrière (+Z local), le guindant contre la hampe
	mi.transform = Transform3D(Basis(Vector3.UP, -PI * 0.5), top + Vector3(0, -w * 0.33 - 0.03, w * 0.5 + 0.02))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hull.add_child(mi)


static var _flag_sh: Shader

static func _flag_shader() -> Shader:
	if _flag_sh != null:
		return _flag_sh
	_flag_sh = Shader.new()
	_flag_sh.code = """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform float w = 0.5;
void vertex() {
	float k = UV.x;
	float t = TIME * 5.5;
	VERTEX.z += (sin(UV.x * 7.0 - t) * 0.07 + sin(UV.x * 13.0 - t * 1.7 + UV.y * 2.0) * 0.025) * k * w;
	VERTEX.y -= k * k * 0.05 * w;
	NORMAL = normalize(NORMAL + vec3(-cos(UV.x * 7.0 - t) * 0.5 * k, 0.0, 0.0));
}
void fragment() {
	vec4 c = texture(tex, UV);
	float shade = 0.85 + 0.15 * sin(UV.x * 7.0 - TIME * 5.5);
	ALBEDO = c.rgb * shade;
	ROUGHNESS = 0.9;
	BACKLIGHT = c.rgb * 0.35;
}
"""
	return _flag_sh


## Les six pavillons, dessinés une fois (formes lissées, sans fichier).
static func flag_texture(n: int) -> ImageTexture:
	if _flag_cache.has(n):
		return _flag_cache[n]
	var W: int = 192
	var H: int = 128
	var img := Image.create(W, H, false, Image.FORMAT_RGB8)
	var px: float = 1.0 / H
	for y in range(H):
		for x in range(W):
			img.set_pixel(x, y, _flag_px(n, Vector2((x + 0.5) / H, (y + 0.5) / H), px))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_flag_cache[n] = t
	return t


static func _lay_col(c: Color, top: Color, d: float, px: float) -> Color:
	return c.lerp(top, clampf(0.5 - d / px, 0.0, 1.0))


static func _sd_circle(p: Vector2, c: Vector2, r: float) -> float:
	return p.distance_to(c) - r


static func _sd_seg(p: Vector2, a: Vector2, b: Vector2, r: float) -> float:
	var pa: Vector2 = p - a
	var ba: Vector2 = b - a
	var h: float = clampf(pa.dot(ba) / ba.dot(ba), 0.0, 1.0)
	return (pa - ba * h).length() - r


static func _sd_poly(p: Vector2, pts: Array) -> float:
	var d: float = INF
	var inside: bool = false
	var n: int = pts.size()
	for i in range(n):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		d = minf(d, _sd_seg(p, a, b, 0.0))
		if ((a.y > p.y) != (b.y > p.y)) and (p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x):
			inside = not inside
	return -d if inside else d


static func _star(c: Vector2, r0: float, r1: float, rot: float = 0.0) -> Array:
	var pts: Array = []
	for k in range(10):
		var a: float = rot - PI * 0.5 + PI * k / 5.0
		var r: float = r0 if k % 2 == 0 else r1
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


static func _flag_px(n: int, p: Vector2, px: float) -> Color:
	var col := Color(1, 1, 1)
	match n:
		1:
			# La Mouette rieuse : un ciel, un soleil, une mouette qui plane
			col = Color(0.36, 0.64, 0.9).lerp(Color(0.6, 0.82, 0.98), p.y)
			col = _lay_col(col, Color(1.0, 0.86, 0.3), _sd_circle(p, Vector2(1.2, 0.28), 0.15), px)
			var wing := minf(minf(_sd_seg(p, Vector2(0.36, 0.5), Vector2(0.55, 0.38), 0.035), _sd_seg(p, Vector2(0.55, 0.38), Vector2(0.75, 0.55), 0.035)),
				minf(_sd_seg(p, Vector2(0.75, 0.55), Vector2(0.95, 0.38), 0.035), _sd_seg(p, Vector2(0.95, 0.38), Vector2(1.14, 0.5), 0.035)))
			col = _lay_col(col, Color(1, 1, 1), wing, px)
			col = _lay_col(col, Color(0.98, 0.98, 0.98), _sd_circle(p, Vector2(0.75, 0.57), 0.06), px)
			col = _lay_col(col, Color(1.0, 0.65, 0.15), _sd_poly(p, [Vector2(0.72, 0.6), Vector2(0.78, 0.6), Vector2(0.75, 0.68)]), px)
			col = _lay_col(col, Color(0.95, 0.95, 0.95), absf(p.y - 0.88) - 0.03 + (0.0 if fmod(p.x, 0.3) < 0.15 else 1.0), px)
		2:
			# L'Étoile du marin : bleu nuit, grande étoile d'or, quatre petites étoiles
			col = Color(0.07, 0.11, 0.3)
			col = _lay_col(col, Color(1.0, 0.82, 0.25), _sd_poly(p, _star(Vector2(0.75, 0.52), 0.36, 0.15)), px)
			for c in [Vector2(0.18, 0.18), Vector2(1.32, 0.2), Vector2(0.2, 0.84), Vector2(1.3, 0.82)]:
				col = _lay_col(col, Color(0.95, 0.95, 1.0), _sd_poly(p, _star(c, 0.07, 0.03)), px)
		3:
			# Le Crâne qui rigole : os croisés, crâne souriant, un nœud rose
			col = Color(0.06, 0.06, 0.07)
			var bone := minf(_sd_seg(p, Vector2(0.48, 0.62), Vector2(1.02, 0.92), 0.03), _sd_seg(p, Vector2(1.02, 0.62), Vector2(0.48, 0.92), 0.03))
			for e in [Vector2(0.48, 0.62), Vector2(1.02, 0.92), Vector2(1.02, 0.62), Vector2(0.48, 0.92)]:
				bone = minf(bone, minf(_sd_circle(p, e + Vector2(0, -0.03), 0.035), _sd_circle(p, e + Vector2(0, 0.03), 0.035)))
			col = _lay_col(col, Color(0.95, 0.94, 0.88), bone, px)
			var skull := minf(_sd_circle(p, Vector2(0.75, 0.4), 0.2), _sd_seg(p, Vector2(0.68, 0.58), Vector2(0.82, 0.58), 0.07))
			col = _lay_col(col, Color(0.97, 0.96, 0.9), skull, px)
			for ex in [0.67, 0.83]:
				col = _lay_col(col, Color(0.06, 0.06, 0.07), _sd_circle(p, Vector2(ex, 0.4), 0.05), px)
			col = _lay_col(col, Color(0.06, 0.06, 0.07), _sd_poly(p, [Vector2(0.75, 0.47), Vector2(0.72, 0.52), Vector2(0.78, 0.52)]), px)
			var smile: float = absf(p.distance_to(Vector2(0.75, 0.5)) - 0.1) - 0.014
			smile = maxf(smile, 0.56 - p.y)
			col = _lay_col(col, Color(0.06, 0.06, 0.07), smile, px)
			col = _lay_col(col, Color(1.0, 0.45, 0.7), minf(_sd_poly(p, [Vector2(0.86, 0.22), Vector2(0.78, 0.15), Vector2(0.78, 0.29)]), _sd_poly(p, [Vector2(0.86, 0.22), Vector2(0.94, 0.15), Vector2(0.94, 0.29)])), px)
			col = _lay_col(col, Color(1.0, 0.6, 0.8), _sd_circle(p, Vector2(0.86, 0.22), 0.025), px)
		4:
			# Le Cœur vaillant : un grand cœur rouge sur fond blanc, bordé de rouge
			col = Color(0.97, 0.96, 0.93)
			col = _lay_col(col, Color(0.78, 0.1, 0.12), minf(absf(p.y - 0.05) - 0.05, absf(p.y - 0.95) - 0.05), px)
			var heart := minf(minf(_sd_circle(p, Vector2(0.65, 0.42), 0.15), _sd_circle(p, Vector2(0.85, 0.42), 0.15)),
				_sd_poly(p, [Vector2(0.515, 0.47), Vector2(0.985, 0.47), Vector2(0.75, 0.8)]))
			col = _lay_col(col, Color(0.86, 0.1, 0.16), heart, px)
			col = _lay_col(col, Color(1.0, 0.6, 0.62), _sd_circle(p, Vector2(0.62, 0.38), 0.035), px)
		5:
			# L'Ancre d'or : fond rouge, ancre dorée
			col = Color(0.66, 0.09, 0.09)
			var g := Color(1.0, 0.8, 0.28)
			var anc: float = absf(p.distance_to(Vector2(0.75, 0.2)) - 0.055) - 0.018
			anc = minf(anc, _sd_seg(p, Vector2(0.75, 0.26), Vector2(0.75, 0.8), 0.028))
			anc = minf(anc, _sd_seg(p, Vector2(0.6, 0.33), Vector2(0.9, 0.33), 0.022))
			anc = minf(anc, maxf(absf(p.distance_to(Vector2(0.75, 0.56)) - 0.24) - 0.025, 0.58 - p.y))
			anc = minf(anc, _sd_poly(p, [Vector2(0.47, 0.5), Vector2(0.56, 0.6), Vector2(0.48, 0.63)]))
			anc = minf(anc, _sd_poly(p, [Vector2(1.03, 0.5), Vector2(0.94, 0.6), Vector2(1.02, 0.63)]))
			col = _lay_col(col, g, anc, px)
		6:
			# Le Poisson-lune : rayures turquoise et blanches, un poisson orange qui sourit
			col = Color(0.1, 0.6, 0.62) if int(p.y * 5.0) % 2 == 0 else Color(0.95, 0.96, 0.94)
			var q: Vector2 = (p - Vector2(0.68, 0.5)) / Vector2(0.3, 0.2)
			var body: float = (q.length() - 1.0) * 0.2
			var tail: float = _sd_poly(p, [Vector2(0.93, 0.5), Vector2(1.2, 0.3), Vector2(1.2, 0.7)])
			col = _lay_col(col, Color(0.98, 0.5, 0.12), minf(body, tail), px)
			col = _lay_col(col, Color(1.0, 0.72, 0.3), _sd_poly(p, [Vector2(0.62, 0.32), Vector2(0.78, 0.18), Vector2(0.82, 0.34)]), px)
			col = _lay_col(col, Color(1, 1, 1), _sd_circle(p, Vector2(0.53, 0.45), 0.05), px)
			col = _lay_col(col, Color(0.05, 0.05, 0.08), _sd_circle(p, Vector2(0.52, 0.45), 0.025), px)
			var sm2: float = maxf(absf(p.distance_to(Vector2(0.48, 0.5)) - 0.06) - 0.01, 0.52 - p.y)
			col = _lay_col(col, Color(0.4, 0.1, 0.05), sm2, px)
	return col


# =================================================================== V76 : évoluer

## L'état d'évolution reçu du chantier (chantier_v76.gd) : {coque, propulsion, accessoires,
## couleur, pavillon}. Le bateau reste où il est (et se ré-amarre si on change sa taille).
func set_evolution(d: Dictionary) -> void:
	var c: int = clampi(int(d.get("coque", 1)), 1, 3)
	var p: int = clampi(int(d.get("propulsion", 1)), 1, 3)
	var acc: Dictionary = {}
	var src: Variant = d.get("accessoires", {})
	if src is Dictionary:
		for k in src:
			if ACCESSOIRES.has(str(k)) and bool(src[k]):
				acc[str(k)] = true
	elif src is Array:
		for k2 in src:
			if ACCESSOIRES.has(str(k2)):
				acc[str(k2)] = true
	var col: String = str(d.get("couleur", ""))
	if not COULEURS.has(col) or not acc.has("peinture"):
		col = ""
	var fl: int = clampi(int(d.get("pavillon", 0)), 0, PAVILLONS.size() - 1)
	if not acc.has("pavillon"):
		fl = 0
	var before: String = _signature()
	var docked: int = _docked_at()
	var old_len: float = length
	var old_beam: float = beam
	coque = c
	propulsion = p
	accessoires = acc
	couleur = col
	pavillon = fl
	_apply_dims()
	if hull == null or _signature() == before:
		return
	_build_model()
	stats["reconstructions"] = int(stats["reconstructions"]) + 1
	if not driving:
		if docked >= 0 and (old_len != length or old_beam != beam):
			moor(docked)
		else:
			hull.global_position.y = WATER - draft
	print("ILE_MANGA_V76: bateau = ", boat_name(), " ", accessoires.keys())


func evolution() -> Dictionary:
	return {"coque": coque, "propulsion": propulsion, "accessoires": accessoires.keys(), "couleur": couleur, "pavillon": pavillon}


func _signature() -> String:
	var k: Array = accessoires.keys()
	k.sort()
	return "%d/%d/%s/%s/%d" % [coque, propulsion, ",".join(k), couleur, pavillon]


func _apply_dims() -> void:
	var h: Dictionary = HULLS[coque]
	length = float(h["L"])
	beam = float(h["B"])
	depth = float(h["D"])
	draft = DRAFT * depth / DEPTH
	max_speed = float(h["v"]) * float(PROPULSIONS[propulsion]["k"])
	accel = ACCEL * max_speed / MAX_SPEED
	max_reverse = MAX_REVERSE * sqrt(max_speed / MAX_SPEED)
	turn_rate = float(h["turn"])


## « la Goélette à cristal »
func boat_name() -> String:
	return "%s %s" % [str(HULLS[coque]["nom"]), str(PROPULSIONS[propulsion]["nom"])]


## L'indice du ponton où le bateau est amarré (-1 s'il n'est près d'aucun).
func _docked_at() -> int:
	if hull == null:
		return -1
	var c: Vector3 = hull.global_position
	for i in range(docks.size()):
		if Vector2(c.x - docks[i]["end"].x, c.z - docks[i]["end"].z).length() < _dock_reach():
			return i
	return -1


func _dock_reach() -> float:
	return 6.5 + (length - LENGTH) * 0.5


## Amarre la barque le long du ponton n (0 = village, 1 = jungle), proue vers le large.
func moor(n: int) -> void:
	if n < 0 or n >= docks.size():
		return
	var d: Dictionary = docks[n]
	var pos: Vector3 = d["end"] - d["axis"] * (2.6 + (length - LENGTH) * 0.5) + d["side"] * (2.15 + (beam - BEAM) * 0.5)
	hull.global_position = Vector3(pos.x, WATER - draft, pos.z)
	var fwd: Vector3 = d["axis"]
	yaw = atan2(-fwd.x, -fwd.z)
	speed = 0.0
	hull.rotation = Vector3(0, yaw, 0)


func forward() -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


func seat_transform() -> Transform3D:
	return hull.global_transform * Transform3D(Basis.IDENTITY, seat_local)


## V76 : les places des passagers (compagnons) : nombre et repère monde (regard vers l'avant).
func passenger_count() -> int:
	return passenger_seats.size()


func passenger_transform(i: int) -> Transform3D:
	if passenger_seats.is_empty():
		return seat_transform()
	return hull.global_transform * Transform3D(Basis.IDENTITY, passenger_seats[clampi(i, 0, passenger_seats.size() - 1)])


# =================================================================== monter / descendre

func can_board(p: Vector3) -> bool:
	if driving or hull == null:
		return false
	var c: Vector3 = hull.global_position
	var rel := Vector2(p.x - c.x, p.z - c.z)
	var f: Vector3 = forward()
	var ax := Vector2(f.x, f.z)
	var half: float = maxf(length * 0.5 - 2.3, 0.0)
	var t: float = clampf(rel.dot(ax), -half, half)
	return (rel - ax * t).length() < BOARD_REACH + (beam - BEAM) * 0.5 and absf(p.y - c.y) < 3.5


func board() -> void:
	if main.has_method("sfx"):
		main.sfx("gros_plouf", hull.global_position, -6.0)
	driving = true
	speed = 0.0
	if main.xr_active:
		_vr_yaw_offset = main.xr_origin.rotation.y - yaw
		_vr_trigger_ready = false


## Où débarquer : au bout d'un ponton proche, sinon sur une plage à quelques mètres.
func landing_spot() -> Variant:
	var c: Vector3 = hull.global_position
	for d in docks:
		if Vector2(c.x - d["end"].x, c.z - d["end"].z).length() < _dock_reach():
			return d["end"] - d["axis"] * 1.6 + Vector3.UP * 0.05
	var r0: float = 2.5 + (beam - BEAM) * 0.5
	for r in [r0, r0 + 1.0, r0 + 2.0, r0 + 3.0, r0 + 4.0]:
		for k in range(16):
			var a: float = TAU * k / 16.0
			var x: float = c.x + cos(a) * r
			var z: float = c.z + sin(a) * r
			var h: float = main._height_at(x, z)
			if h > WATER + 0.15 and h < WATER + 4.0:
				var slope: float = absf(main._height_at(x + 0.6, z) - h) + absf(main._height_at(x, z + 0.6) - h)
				if slope < 0.5:
					return Vector3(x, h + 0.05, z)
	return null


func leave() -> bool:
	var spot: Variant = landing_spot()
	if spot == null:
		return false
	if main.has_method("sfx"):
		main.sfx("pas_bois", hull.global_position + Vector3.UP * 0.5)
	driving = false
	speed = 0.0
	_spy_off_now()
	# Arrivé au bout d'un ponton : la barque s'y amarre proprement.
	for i in range(docks.size()):
		if Vector2(hull.global_position.x - docks[i]["end"].x, hull.global_position.z - docks[i]["end"].z).length() < _dock_reach():
			moor(i)
	return true


func prompt(p: Vector3) -> String:
	if driving:
		var extra: String = _extra_prompt()
		if landing_spot() != null:
			return "E : débarquer" + extra
		if can_sleep_here():
			return "E : dormir dans la couchette" + extra
		return "Z / S : avancer, reculer  •  Q / D : barrer  •  approchez un ponton ou une plage pour débarquer" + extra
	if can_board(p):
		return "E : monter dans le bateau"
	return ""


func _extra_prompt() -> String:
	var pad: bool = _pad_active()
	var out: String = ""
	if accessoires.has("longue_vue"):
		out += ("  •  LB : longue-vue" if pad else "  •  L : longue-vue")
	if accessoires.has("canon"):
		out += ("  •  B : confettis" if pad else "  •  K : confettis")
	return out


func _pad_active() -> bool:
	var mn: Node = main.get("manette_v74") if main != null else null
	return mn != null and bool(mn.get("active")) and int(mn.get("device")) >= 0


# =================================================================== navigation

## throttle : -1..1 (avant > 0) ; steer : -1..1 (droite > 0).
func drive(delta: float, throttle: float, steer: float) -> void:
	if throttle > 0.05:
		speed = minf(speed + accel * throttle * delta, max_speed)
	elif throttle < -0.05:
		speed = maxf(speed + accel * 1.2 * throttle * delta, -max_reverse)
	else:
		speed = move_toward(speed, 0.0, 0.9 * sqrt(accel / ACCEL) * delta)
	var grip: float = clampf(absf(speed) / 3.0, 0.25, 1.0)
	var turn: float = -steer * turn_rate * grip * (1.0 if speed >= -0.05 else -1.0)
	yaw += turn * delta
	var step: Vector3 = forward() * speed * delta
	var next: Vector3 = hull.global_position + step
	_blocked_clock = maxf(_blocked_clock - delta, 0.0)
	if _blocked(next):
		speed = -speed * 0.25
		_blocked_clock = 0.4
	else:
		hull.global_position = next
	_float_motion(delta, turn)


func _blocked(next: Vector3) -> bool:
	var fwd: Vector3 = forward() * signf(speed if absf(speed) > 0.01 else 1.0)
	var right: Vector3 = Vector3(-fwd.z, 0, fwd.x)
	var bow: float = length * 0.5
	var sh: float = length * 0.3043
	var half: float = beam * 0.4375
	for probe in [next + fwd * bow, next + fwd * sh + right * half, next + fwd * sh - right * half, next]:
		if main._height_at(probe.x, probe.z) > WATER - DRAFT - 0.25:
			return true
		for d in docks:
			var rel: Vector3 = (probe as Vector3) - d["start"]
			var along: float = rel.dot(d["axis"])
			if along > -0.5 and along < float(d["length"]) + 0.5 and absf(rel.dot(d["side"])) < 1.45:
				return true
	# V59 : la mer de l'est (la grande île) ; la barque ne passe pas à travers le Léviathan
	if not GrandeIle.sea_contains(next.x, next.z, Vector2(WORLD_MID.x, WORLD_MID.z), WORLD_RADIUS):
		return true
	var tip: Vector3 = next + fwd * bow
	var g59: Node = main.get("grande_v59")
	if g59 != null and g59.blocks_boat(tip):
		return true
	# V68 : les navires et les pontons de Port-Coutelas
	var p68: Node = main.get("pirates_v68")
	if p68 != null and p68.blocks_boat(tip):
		return true
	# V69 : le pont de l'Iterou et le débarcadère de Per-Hâpy
	var s69: Node = main.get("soleils_v69")
	if s69 != null and s69.egypte != null and s69.blocks_boat(tip):
		return true
	# V70 : les navires du Port de Cendre
	var b70: Node = main.get("braise_v70")
	if b70 != null and b70.city != null and b70.blocks_boat(tip):
		return true
	return false


## Tangage, roulis et gîte dans les virages (V76 : les grands bateaux bougent moins).
func _float_motion(delta: float, turn: float) -> void:
	bob_clock += delta
	var k: float = LENGTH / length
	var heave: float = (sin(bob_clock * 1.3) * 0.05 + sin(bob_clock * 2.1 + 1.0) * 0.025) * k
	var pitch: float = (sin(bob_clock * 1.1 + 0.4) * 0.025 + speed * 0.004 * MAX_SPEED / max_speed) * k
	var roll: float = sin(bob_clock * 0.9) * 0.035 * k + turn * clampf(absf(speed) / max_speed, 0.0, 1.0) * 0.12
	hull.global_position.y = WATER - draft + heave
	hull.rotation = Vector3(pitch, yaw, roll)


## V52 : la mer ne se dessine pas à l'intérieur de la coque (shaders water*.gdshader).
## V76 : les shaders connaissent la forme de la barque ; on leur passe la coque ramenée à ces
## mesures (la forme des grandes coques est la même, mise à l'échelle).
func _process(delta: float) -> void:
	if hull == null or main == null:
		return
	var m: ShaderMaterial = main.get("ocean_material")
	if m != null:
		var inv: Transform3D = hull.global_transform.affine_inverse()
		if coque > 1:
			inv = Transform3D(Basis.from_scale(Vector3(BEAM / beam, DEPTH / depth, LENGTH / length)), Vector3.ZERO) * inv
		m.set_shader_parameter("boat_inv", Projection(inv))
		m.set_shader_parameter("boat_on", true)
	_clock += delta
	_fx_tick(delta)
	_spy_tick(delta)
	_pad_tick()


## V52 : la barque revient s'amarrer au ponton du village (après un évanouissement loin
## d'elle). Vrai si elle a été déplacée.
func return_home() -> bool:
	if hull == null or docks.is_empty():
		return false
	driving = false
	_spy_off_now()
	var d: Dictionary = docks[0]
	if Vector2(hull.global_position.x - d["end"].x, hull.global_position.z - d["end"].z).length() < 12.0:
		return false
	moor(0)
	return true


func _physics_process(delta: float) -> void:
	# À l'amarre : la barque continue de bouger doucement sur l'eau.
	if not driving and hull != null:
		_float_motion(delta, 0.0)


# =================================================================== V76 : effets à bord

func _fx_tick(delta: float) -> void:
	var f: float = clampf(absf(speed) / maxf(max_speed, 0.1), 0.0, 1.0)
	var running: bool = driving and propulsion >= 2
	if _smoke != null:
		_smoke.emitting = running
		_smoke.amount_ratio = 0.3 + 0.7 * f
	if _foam != null:
		_foam.emitting = running and absf(speed) > 0.6
		_foam.amount_ratio = clampf(f * 1.4, 0.2, 1.0)
	if _wake != null:
		_wake.emitting = driving and absf(speed) > 0.8
		_wake.amount_ratio = clampf(f * 1.3, 0.25, 1.0)
	for g in _glow:
		(g[0] as StandardMaterial3D).emission_energy_multiplier = float(g[1]) * (0.8 + 0.22 * sin(_clock * 2.3)) + (1.6 * f if driving else 0.0)
	if _engine != null:
		if running:
			if not _engine.playing:
				_engine.play()
			_engine.volume_db = lerpf(-16.0, -4.0, f)
			_engine.pitch_scale = lerpf(0.85, 1.25, f)
		elif _engine.playing:
			_engine.stop()
	elif running and propulsion == 2:
		# pas de boucle « bateau_vapeur » : quelques bouffées de vapeur
		_engine_puff -= delta
		if _engine_puff <= 0.0:
			_engine_puff = lerpf(1.6, 0.6, f)
			if main.has_method("sfx") and _has_sfx("vapeur"):
				main.sfx("vapeur", hull.global_position + Vector3.UP, -12.0 + 6.0 * f)
	_confetti_cd = maxf(_confetti_cd - delta, 0.0)


## Le canon à confettis : pan ! (une fois toutes les 1,2 s).
func fire_confetti() -> bool:
	if not accessoires.has("canon") or _confetti == null:
		if main != null:
			main._show_message_v28("Pas de canon à confettis à bord… Le chantier naval de Port-Azur en installe un très joli.")
		return false
	if _confetti_cd > 0.0:
		return false
	_confetti_cd = 1.2
	_confetti.restart()
	_confetti.emitting = true
	stats["confettis"] = int(stats["confettis"]) + 1
	if main.has_method("sfx"):
		main.sfx("confettis_canon" if _has_sfx("confettis_canon") else "confettis", _muzzle.global_position)
	return true


## La couchette : à l'arrêt, loin du rivage, avec une couchette : dormir jusqu'au matin.
func can_sleep_here() -> bool:
	return driving and accessoires.has("couchette") and absf(speed) < 0.8 and landing_spot() == null


## Vrai si l'appui a été pris par la couchette (on dort, ou il fait encore jour).
func try_sleep() -> bool:
	if not can_sleep_here():
		return false
	var t: Node = main.get("temps_v56")
	if t == null:
		return false
	if _sleep_busy or bool(t.get("_sleeping")):
		return true
	var h: float = float(t.hour)
	if h >= 6.0 and h < 19.0:
		main._show_message_v28("La couchette, c'est pour la nuit (à partir de 19 h)… Pour l'instant, le soleil te fait de l'œil !")
		return true
	speed = 0.0
	stats["nuits"] = int(stats["nuits"]) + 1
	main._show_message_v28("Tu te glisses dans la couchette. Les vagues te bercent… Bonne nuit, matelot.")
	_sleep_night(t)
	return true


func _sleep_night(t: Node) -> void:
	_sleep_busy = true
	await t.sleep_until(7.0)
	_sleep_busy = false
	if driving and main != null:
		main._show_message_v28("Debout, matelot ! Le soleil se lève sur la mer.")


# =================================================================== V76 : la longue-vue

func toggle_spyglass() -> void:
	if not accessoires.has("longue_vue"):
		main._show_message_v28("Pas de longue-vue à bord… Le chantier naval de Port-Azur en installe une.")
		return
	if main.xr_active:
		main._show_message_v28("La longue-vue ne se tient pas avec un casque… Rapproche-toi, tout simplement !")
		return
	_spy = not _spy
	if _spy:
		main._show_message_v28("Longue-vue : clic droit (ou stick droit) pour regarder autour ; L pour la replier.")
		if main.has_method("sfx"):
			main.sfx("ui_ouvrir")


func spyglass_on() -> bool:
	return _spy


func _spy_off_now() -> void:
	_spy = false
	if _spy_fov0 > 0.0 and main != null and main.get("pc_camera") != null:
		main.pc_camera.fov = _spy_fov0
	_spy_fov0 = -1.0
	if _spy_rect != null:
		_spy_rect.visible = false


func _spy_tick(delta: float) -> void:
	if _spy and (not driving or main.xr_active):
		_spy_off_now()
	var cam: Camera3D = main.get("pc_camera")
	if cam == null:
		return
	if _spy:
		if _spy_fov0 < 0.0:
			_spy_fov0 = cam.fov
		cam.fov = lerpf(cam.fov, SPY_FOV, 1.0 - exp(-7.0 * delta))
		var eye: Vector3 = seat_transform().origin + Vector3.UP * 0.92
		var fwd: Vector3 = -main.pc_root.global_basis.z
		fwd.y = 0.0
		fwd = fwd.normalized() if fwd.length() > 0.01 else forward()
		cam.global_position = eye + fwd * 0.4
		cam.look_at(eye + fwd * 30.0 + Vector3.UP * 0.4, Vector3.UP)
		_spy_overlay(true)
	elif _spy_fov0 > 0.0:
		cam.fov = lerpf(cam.fov, _spy_fov0, 1.0 - exp(-9.0 * delta))
		_spy_overlay(false)
		if absf(cam.fov - _spy_fov0) < 0.3:
			cam.fov = _spy_fov0
			_spy_fov0 = -1.0


func _spy_overlay(on: bool) -> void:
	if not on:
		if _spy_rect != null:
			_spy_rect.visible = false
		return
	if _spy_rect == null:
		_spy_layer = CanvasLayer.new()
		_spy_layer.layer = 5
		add_child(_spy_layer)
		_spy_rect = ColorRect.new()
		_spy_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_spy_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sh := Shader.new()
		sh.code = """
shader_type canvas_item;
uniform float aspect = 1.7778;
void fragment() {
	vec2 p = (UV - 0.5) * vec2(aspect, 1.0);
	float r = length(p);
	float R = 0.47;
	float outside = smoothstep(R, R + 0.006, r);
	float ring = smoothstep(R - 0.03, R - 0.004, r) * (1.0 - outside);
	float glint = 0.5 + 0.5 * sin(atan(p.y, p.x) * 2.0 + 0.8);
	vec3 brass = mix(vec3(0.32, 0.22, 0.08), vec3(0.85, 0.66, 0.3), glint);
	float vign = smoothstep(R * 0.6, R, r) * 0.45;
	vec3 col = mix(vec3(0.0), brass, ring);
	COLOR = vec4(col, max(outside, max(ring, vign)));
}
"""
		var sm := ShaderMaterial.new()
		sm.shader = sh
		_spy_rect.material = sm
		_spy_layer.add_child(_spy_rect)
	var vp: Vector2 = get_viewport().get_visible_rect().size
	(_spy_rect.material as ShaderMaterial).set_shader_parameter("aspect", vp.x / maxf(vp.y, 1.0))
	_spy_rect.visible = true


# =================================================================== V76 : touches, manette

func _ui_busy() -> bool:
	if main.get("game_menu") != null and main.game_menu != null and bool(main.game_menu.opened):
		return true
	if main.get("inventory_v28") != null and main.inventory_v28 != null and bool(main.inventory_v28.opened):
		return true
	if main.get("dialogue_v31") != null and main.dialogue_v31 != null and bool(main.dialogue_v31.opened):
		return true
	return false


## Les enfants passent avant leur parent : on voit E, L, K avant main.gd (E n'est gardé que
## quand la couchette s'en sert).
func _unhandled_input(event: InputEvent) -> void:
	if main == null or not driving or bool(main.xr_active) or not bool(main.game_started):
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if _ui_busy():
		return
	match (event as InputEventKey).keycode:
		KEY_E:
			if try_sleep():
				get_viewport().set_input_as_handled()
		KEY_LONGUE_VUE:
			toggle_spyglass()
			get_viewport().set_input_as_handled()
		KEY_CONFETTIS:
			fire_confetti()
			get_viewport().set_input_as_handled()


## La manette (à bord) : LB la longue-vue, B les confettis (Y fait E, voir manette_v74.gd).
func _pad_tick() -> void:
	if main == null or not driving or bool(main.xr_active):
		_pad_prev.clear()
		return
	var mn: Node = main.get("manette_v74")
	if mn == null or int(mn.get("device")) < 0 or _ui_busy():
		_pad_prev.clear()
		return
	var dev: int = int(mn.get("device"))
	for b in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_B]:
		var now: bool = Input.is_joy_button_pressed(dev, b)
		if now and not bool(_pad_prev.get(b, false)):
			if b == JOY_BUTTON_LEFT_SHOULDER:
				if accessoires.has("longue_vue"):
					toggle_spyglass()
			elif accessoires.has("canon"):
				fire_confetti()
		_pad_prev[b] = now


# =================================================================== VR

## Stick gauche : avant/arrière et barre. Gâchette droite : débarquer (V76 : à l'arrêt au
## large, avec une couchette : dormir). A (main droite) : canon à confettis.
func vr_tick(delta: float, stick: Vector2, trigger: float) -> void:
	drive(delta, stick.y if absf(stick.y) > 0.2 else 0.0, stick.x if absf(stick.x) > 0.2 else 0.0)
	var pressed: bool = trigger > 0.7
	if pressed and _vr_trigger_ready:
		if not try_sleep():
			main._leave_boat_v29()
	_vr_trigger_ready = not pressed
	var rh: Node = main.get("right_hand")
	var a_now: bool = rh != null and rh.is_button_pressed("ax_button")
	if a_now and _vr_a_ready and accessoires.has("canon"):
		fire_confetti()
	_vr_a_ready = not a_now


func serialize() -> Dictionary:
	return {"x": hull.global_position.x, "z": hull.global_position.z, "cap": yaw, "a_bord": driving}


func load_data(d: Dictionary) -> void:
	if d.is_empty():
		moor(0)
		return
	hull.global_position = Vector3(float(d.get("x", 0.0)), WATER - draft, float(d.get("z", 0.0)))
	yaw = float(d.get("cap", PI))
	speed = 0.0
	hull.rotation = Vector3(0, yaw, 0)
