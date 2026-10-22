extends Node3D
## V63 : la grande enquête des Quatre Sceaux (la quête « quatre_sceaux » du carnet) et ce qu'il
## faut construire dans le monde pour la mener :
##  - Tazira : trois bornes de caravane qui « marchent » vers le nord-est (elles s'allument la
##    nuit), la Dune qui Marche, et sous elle le tombeau du désert : une porte à trois anneaux
##    (l'étoile, la dune, le soleil), une salle à colonnes, le Sceau des Sables, des scorpions,
##    et la fresque de la bergerie ;
##  - au pied du Cœur-de-Pierre, au sud-est de Cliquetis : la Bergerie du Vent, fermée par des
##    ronces noires (la Flamme les brûle) ; dedans, la bergerie des anciens bergers, une porte de
##    bronze à trois roues (le chant du berger donne les nombres de moutons), le Sceau d'Airain,
##    deux automates gardiens, et la fresque de la mare ;
##  - Ramure : la vieille vanne de bronze de la grande mare (le Rouage la fait tourner : l'eau
##    baisse), la pierre ronde au fond ; la nuit, le Sceau des Brumes, et les spectres ;
##  - le journal de bord du Léviathan, dont l'encre de lune apparaît à la Lueur de lune ;
##  - Carène : la Dame de Proue, la figure de proue du Léviathan, qui garde le Sceau des Embruns ;
##  - la Porte aux Quatre Sceaux : on y pose les sceaux, elle s'enfonce dans le sol ; on descend
##    alors sous le Cœur-de-Pierre (coeur_v63.gd).
## Les invites « E » (et gâchette en VR) passent par donjon_v35._interactions.

const Kit = preload("res://scripts/coeur_kit_v63.gd")
const BORNES := [Vector2(968.0, -3.0), Vector2(988.0, -24.0), Vector2(1008.0, -45.0)]
const DUNE_C := Vector2(1032.0, -70.0)
const TOMB_IN := Vector3(1032.0, -80.0, -70.0)
const BERG := Vector2(1021.0, -242.0)
const BERG_IN := Vector3(1000.0, -80.0, -262.0)
const POND_GUESS := Vector2(1087.0, -120.2)
const SYMBOLS := ["l'étoile", "la dune", "le soleil", "la lune", "le palmier", "le scarabée"]
const RING_GOAL := [0, 1, 2]
const RING_START := [3, 5, 4]
const WHEEL_GOAL := [3, 1, 2]
const WHEEL_START := [1, 4, 4]
const SOCKET_OF := {"airain": 0, "embruns": 1, "sables": 2, "brumes": 3}
const SEAL_COL := {"embruns": Color(0.35, 0.95, 0.9), "sables": Color(1.0, 0.6, 0.2), "airain": Color(1.0, 0.8, 0.35), "brumes": Color(0.72, 0.82, 1.0)}

var main: Node
var ile: Node3D
var kit
var pc: bool = true
var state: Dictionary = {}
var dune_xf: Transform3D
var tomb_door_xf: Transform3D
var berg_xf: Transform3D
var pond_c: Vector3 = Vector3.INF
var pond_r: float = 15.0
var vanne_xf: Transform3D
var proue_at: Vector3 = Vector3.INF
# noeuds
var _tomb_root: Node3D
var _berg_root: Node3D
var _beacon_lights: Array = []          # [OmniLight3D, StandardMaterial3D, étoile]
var _rings: Array = []                  # Node3D des trois anneaux
var _tomb_slab: Node3D
var _tomb_slab_y: float = 0.0
var _tomb_seal: Node3D
var _brambles: Node3D
var _bramble_body: CollisionShape3D
var _wheels: Array = []
var _berg_door: Node3D
var _berg_seal: Node3D
var _statues: Array = []
var _vanne_gears: Array = []
var _vanne_gate: Node3D
var _vanne_gate_y: float = 0.0
var _pond_disc: MeshInstance3D
var _pond_y0: float = 0.0
var _moon_stone_glow: StandardMaterial3D
var _pond_seal: Node3D
var _figure: Node3D
var _figure_arms: Array = []
var _figure_glow: OmniLight3D
var _shell_lid: Node3D
var _door_void: Node3D
var _door_seals: Array = []
var _fight: Dictionary = {}
var _busy: bool = false
var _clock: float = 0.0
var _night_was: int = -1


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	ile = main.grande_v59.ile
	state = _defaults()


func _defaults() -> Dictionary:
	return {"anneaux": RING_START.duplicate(), "tombeau": false, "coffre_tombeau": false, "sceau_sables": false, "visite_tombeau": false,
		"ronces": false, "visite_bergerie": false, "roues": WHEEL_START.duplicate(), "porte_bergerie": false, "sceau_airain": false,
		"vanne": false, "sceau_brumes": false, "journal_lu": false, "sceau_embruns": false, "porte_ouverte": false}


func _say(text: String, seconds: float = 5.0) -> void:
	main.donjon_v35._say(text, seconds)


func _h(x: float, z: float) -> float:
	return ile.height(x, z)


## La lune est levée (la nuit, de 20 h à 6 h).
func moon() -> bool:
	var t: Node = main.get("temps_v56")
	if t == null:
		return true
	var h: float = float(t.hour)
	return h >= 20.0 or h < 6.0


func _inv() -> Node:
	return main.inventory_v28


# =================================================================== construction

func build() -> void:
	kit = Kit.new()
	kit.setup63(self, main, pc)
	_build_tazira()
	_build_tomb_inside()
	_build_bergerie()
	_build_bergerie_inside()
	_build_vanne()
	_build_figure()
	_register()
	apply_state()
	print("ILE_MANGA_V63: les sites des quatre sceaux (dune %s, bergerie %s, mare %s)" % [str(DUNE_C), str(BERG), str(pond_c)])


func _node(label: String) -> Node3D:
	var n := Node3D.new()
	n.name = label
	add_child(n)
	kit.root = n
	return n


# ------------------------------------------------------------------- Tazira : bornes et dune

func _build_tazira() -> void:
	var root: Node3D = _node("Tazira_dune_v63")
	# les trois bornes des caravanes : obélisque de grès, étoile de bronze ajourée
	for i in range(BORNES.size()):
		var b: Vector2 = BORNES[i]
		var y: float = _h(b.x, b.y)
		var nxt: Vector2 = BORNES[i + 1] if i + 1 < BORNES.size() else DUNE_C
		var d: Vector2 = (nxt - b).normalized()
		var xf := Transform3D(Basis(Vector3.UP, atan2(d.x, d.y)), Vector3(b.x, y, b.y))
		kit.solid(xf * Transform3D(Basis(), Vector3(0, 0.25, 0)), Vector3(1.3, 0.5, 1.3), "gres_sombre", 1.0)
		kit.box(xf * Transform3D(Basis(), Vector3(0, -0.4, 0)), Vector3(1.5, 0.8, 1.5), "gres_sombre", 1.0)
		kit.cyl(xf * Transform3D(Basis(), Vector3(0, 0.5, 0)), 0.42, 0.26, 3.0, "gres", 4, true, 1.2)
		kit.col_box(xf * Transform3D(Basis(), Vector3(0, 2.0, 0)), Vector3(0.7, 3.0, 0.7))
		kit.box(xf * Transform3D(Basis(), Vector3(0, 3.55, 0)), Vector3(0.5, 0.12, 0.5), "bronze", 0.5)
		# la flèche gravée (une arête de bronze vers la borne suivante)
		kit.box(xf * Transform3D(Basis(), Vector3(0, 1.4, 0.34)), Vector3(0.08, 0.6, 0.04), "bronze", 0.5)
		kit.box(xf * Transform3D(Basis(Vector3.BACK, 0.7), Vector3(-0.08, 1.62, 0.34)), Vector3(0.06, 0.25, 0.04), "bronze", 0.5)
		kit.box(xf * Transform3D(Basis(Vector3.BACK, -0.7), Vector3(0.08, 1.62, 0.34)), Vector3(0.06, 0.25, 0.04), "bronze", 0.5)
		# l'étoile : deux prismes de verre croisés, dans une cage de bronze
		var star := Node3D.new()
		star.name = "Etoile_%d" % i
		root.add_child(star)
		star.global_position = xf * Vector3(0, 4.05, 0)
		var glass := StandardMaterial3D.new()
		glass.albedo_color = Color(1.0, 0.85, 0.55, 0.85)
		glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glass.roughness = 0.15
		glass.emission_enabled = true
		glass.emission = Color(1.0, 0.75, 0.4)
		glass.emission_energy_multiplier = 0.0
		for k in range(2):
			var pm := MeshInstance3D.new()
			var pr := PrismMesh.new()
			pr.size = Vector3(0.62, 0.62, 0.62)
			pm.mesh = pr
			pm.material_override = glass
			pm.rotation = Vector3(0, k * PI * 0.25, k * PI)
			pm.position.y = -0.1 + k * 0.1
			star.add_child(pm)
		for k2 in range(4):
			var cage := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.015
			cm.bottom_radius = 0.015
			cm.height = 0.8
			cage.mesh = cm
			cage.material_override = kit.mat("bronze")
			cage.position = Vector3(cos(k2 * PI * 0.5) * 0.32, 0, sin(k2 * PI * 0.5) * 0.32)
			star.add_child(cage)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.78, 0.45)
		l.light_energy = 0.0
		l.omni_range = 14.0
		star.add_child(l)
		_beacon_lights.append([l, glass, star])
	# la Dune qui Marche : un grand croissant de sable, la face raide (et la porte) vers les bornes
	var to_b: Vector2 = (BORNES[2] - DUNE_C).normalized()
	var yaw: float = atan2(to_b.x, to_b.y)
	var g: float = _h(DUNE_C.x, DUNE_C.y)
	dune_xf = Transform3D(Basis(Vector3.UP, yaw), Vector3(DUNE_C.x, g, DUNE_C.y))
	_dune_mesh(root)
	# le portail du tombeau, au creux du croissant
	var dw: Vector3 = dune_xf * Vector3(0, 0, -7.6)
	var dy: float = _h(dw.x, dw.z)
	tomb_door_xf = Transform3D(dune_xf.basis, Vector3(dw.x, dy - 0.1, dw.z))
	var t: Transform3D = tomb_door_xf
	for s in [-1.0, 1.0]:
		kit.solid(t * Transform3D(Basis(), Vector3(s * 2.45, 2.4, 0)), Vector3(1.1, 5.2, 1.4), "gres", 1.5)
		kit.box(t * Transform3D(Basis(), Vector3(s * 2.45, 5.2, 0)), Vector3(1.3, 0.4, 1.6), "gres_sombre", 1.0)
		# un disque de soleil sur chaque pilier
		kit.cyl(t * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(s * 2.45, 3.6, 0.71)), 0.32, 0.32, 0.05, "or_c", 16)
	kit.solid(t * Transform3D(Basis(), Vector3(0, 5.6, 0)), Vector3(6.4, 1.0, 1.6), "gres", 1.5)
	kit.box(t * Transform3D(Basis(), Vector3(0, 6.2, 0)), Vector3(7.0, 0.3, 1.9), "gres_sombre", 1.0)
	kit.cyl(t * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 5.6, 0.81)), 0.45, 0.45, 0.06, "or_c", 20)
	# l'escalier qui s'enfonce dans le noir, derrière la porte
	for k3 in range(5):
		kit.box(t * Transform3D(Basis(), Vector3(0, -0.15 - k3 * 0.3, -0.6 - k3 * 0.45)), Vector3(3.8, 0.3, 0.45), "gres_sombre", 1.0)
	kit.box(t * Transform3D(Basis(), Vector3(0, 2.0, -2.8)), Vector3(3.8, 6.0, 0.2), "noir", 1.0)
	kit.col_box(t * Transform3D(Basis(), Vector3(0, 2.0, -1.4)), Vector3(3.8, 5.0, 0.4))
	# le seuil de grès, devant
	kit.solid(t * Transform3D(Basis(), Vector3(0, -0.65, 1.6)), Vector3(6.0, 1.5, 2.4), "dalles_c", 1.5)
	kit.commit()
	# la dalle de la porte et ses trois anneaux (à part : elle s'enfonce)
	_tomb_slab = Node3D.new()
	_tomb_slab.name = "Dalle_tombeau"
	root.add_child(_tomb_slab)
	_tomb_slab.global_transform = t * Transform3D(Basis(), Vector3(0, 2.3, 0.1))
	_tomb_slab_y = _tomb_slab.position.y
	var slab := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(3.9, 4.6, 0.5)
	slab.mesh = sb
	slab.material_override = kit.mat("gres")
	_tomb_slab.add_child(slab)
	var slab_body := StaticBody3D.new()
	slab_body.name = "Collision"
	var scs := CollisionShape3D.new()
	var sbs := BoxShape3D.new()
	sbs.size = Vector3(3.9, 4.6, 0.5)
	scs.shape = sbs
	slab_body.add_child(scs)
	_tomb_slab.add_child(slab_body)
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_texture = load("res://assets/textures/coeur/anneau_tombeau.png") if ResourceLoader.exists("res://assets/textures/coeur/anneau_tombeau.png") else null
	ring_mat.albedo_color = Color(1.0, 0.95, 0.88) if ring_mat.albedo_texture != null else Color(0.85, 0.7, 0.45)
	ring_mat.roughness = 0.8
	for i2 in range(3):
		var r := Node3D.new()
		r.name = "Anneau_%d" % i2
		r.position = Vector3(-1.15 + i2 * 1.15, -0.6, 0.27)
		_tomb_slab.add_child(r)
		var disc := MeshInstance3D.new()
		var dm := CylinderMesh.new()
		dm.top_radius = 0.48
		dm.bottom_radius = 0.48
		dm.height = 0.07
		dm.radial_segments = 32
		disc.mesh = dm
		disc.material_override = ring_mat
		disc.rotation.x = PI * 0.5
		r.add_child(disc)
		var notch := MeshInstance3D.new()
		var nm := PrismMesh.new()
		nm.size = Vector3(0.14, 0.12, 0.05)
		notch.mesh = nm
		notch.material_override = kit.mat("or_c")
		notch.rotation.z = PI
		notch.position = Vector3(-1.15 + i2 * 1.15, -0.6 + 0.58, 0.29)
		_tomb_slab.add_child(notch)
		_rings.append(r)


## Le relief de la dune (repère de la dune : +Z vers les bornes).
func _dune_h(x: float, z: float) -> float:
	var dome: float = 9.0 * (1.0 - (x * x) / (24.0 * 24.0) - pow(z + 9.0, 2.0) / (19.0 * 19.0))
	var dc: float = Vector2(x, z - 5.0).length()
	var bowl: float = maxf(0.0, (13.5 - dc)) * 1.25
	var h: float = dome - bowl
	h += sin(x * 0.9 + z * 0.35) * 0.12 + sin(x * 0.37 - z * 0.8) * 0.18
	# le couloir de sable dégagé devant la porte du tombeau (la porte reste prise dans la dune)
	var side: float = smoothstep(3.6, 6.2, absf(x))
	var behind: float = smoothstep(-7.7, -8.7, z)
	h *= clampf(maxf(side, behind), 0.0, 1.0)
	return maxf(h, 0.0)


## Le maillage de la dune (posé sur le relief de l'île) et sa collision.
func _dune_mesh(root: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0: int = -26
	var x1: int = 26
	var z0: int = -30
	var z1: int = 14
	var nx: int = x1 - x0 + 1
	var nz: int = z1 - z0 + 1
	var pts := PackedVector3Array()
	pts.resize(nx * nz)
	for j in range(nz):
		for i in range(nx):
			var lx: float = float(x0 + i)
			var lz: float = float(z0 + j)
			var w: Vector3 = dune_xf * Vector3(lx, 0, lz)
			var h: float = _dune_h(lx, lz)
			var gy: float = _h(w.x, w.z)
			pts[j * nx + i] = Vector3(w.x, gy + h - (0.25 if h <= 0.01 else 0.0), w.z)
	var faces := PackedVector3Array()
	for j2 in range(nz - 1):
		for i2 in range(nx - 1):
			var a: Vector3 = pts[j2 * nx + i2]
			var b: Vector3 = pts[j2 * nx + i2 + 1]
			var c: Vector3 = pts[(j2 + 1) * nx + i2 + 1]
			var d: Vector3 = pts[(j2 + 1) * nx + i2]
			for tri in [[a, b, c], [a, c, d]]:
				var n: Vector3 = ((tri[1] as Vector3) - (tri[0] as Vector3)).cross((tri[2] as Vector3) - (tri[0] as Vector3))
				var order: Array = tri if n.y < 0.0 else [tri[0], tri[2], tri[1]]
				for v in order:
					st.set_uv(Vector2((v as Vector3).x, (v as Vector3).z) * 0.25)
					st.add_vertex(v)
					faces.append(v)
	st.generate_normals()
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.name = "Dune_qui_marche"
	mi.mesh = st.commit()
	mi.material_override = kit.mat("sable_c")
	root.add_child(mi)
	var sb := StaticBody3D.new()
	sb.name = "Dune_collision"
	var cs := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	cs.shape = shape
	sb.add_child(cs)
	root.add_child(sb)


# ------------------------------------------------------------------- le tombeau, dedans

func _build_tomb_inside() -> void:
	_tomb_root = _node("Tombeau_dune_v63")
	var xf := Transform3D(Basis(), TOMB_IN)
	kit.room(xf, -7.0, 7.0, -13.0, 2.0, 0.0, 6.0, "gres", "dalles_c", [["s", 0.0, 3.2, 3.6]], "gres_sombre", 0.8, 3.0)
	kit.room(xf, -1.6, 1.6, 2.0, 9.6, 0.0, 3.6, "gres", "dalles_c", [["n", 0.0, 3.2, 3.6], ["s", 0.0, 3.2, 3.6]], "gres_sombre", 0.6, 2.0)
	kit.ramp(xf, Vector3(0, 0, 9.6), Vector3(0, 3.0, 14.2), 3.2, "gres_sombre")
	kit.solid(xf * Transform3D(Basis(), Vector3(0, 3.0, 15.0)), Vector3(3.6, 6.0, 0.6), "noir", 1.0)
	kit.solid(xf * Transform3D(Basis(), Vector3(0, 5.4, 12.0)), Vector3(3.6, 0.6, 5.0), "gres_sombre", 2.0)
	for s in [-1.0, 1.0]:
		kit.solid(xf * Transform3D(Basis(), Vector3(s * 1.9, 2.8, 12.0)), Vector3(0.6, 5.6, 5.0), "gres", 2.0)
	# les colonnes, les sarcophages, l'estrade
	for p in [Vector3(-4.5, 0, -1.5), Vector3(4.5, 0, -1.5), Vector3(-4.5, 0, -9.5), Vector3(4.5, 0, -9.5)]:
		kit.column(xf * Transform3D(Basis(), p), 0.45, 6.0, "gres", "gres_sombre")
	for s2 in [-1.0, 1.0]:
		kit.solid(xf * Transform3D(Basis(), Vector3(s2 * 6.0, 0.45, -5.5)), Vector3(1.2, 0.9, 2.4), "gres_sombre", 1.0)
		kit.box(xf * Transform3D(Basis(), Vector3(s2 * 6.0, 0.98, -5.5)), Vector3(1.35, 0.16, 2.55), "gres", 1.0)
	kit.solid(xf * Transform3D(Basis(), Vector3(0, 0.15, -6.0)), Vector3(4.6, 0.3, 4.6), "gres_sombre", 1.5)
	kit.solid(xf * Transform3D(Basis(), Vector3(0, 0.45, -6.0)), Vector3(3.2, 0.3, 3.2), "gres_sombre", 1.5)
	kit.solid(xf * Transform3D(Basis(), Vector3(0, 1.15, -6.0)), Vector3(0.9, 1.1, 0.9), "gres", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 1.75, -6.0)), Vector3(1.1, 0.1, 1.1), "or_c", 0.5)
	# la fresque de la bergerie, au fond
	kit.quad(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 3.1, -12.58)), 6.4, 3.2, "img_fresque_bergerie")
	# un coffre de grès (le trésor du tombeau)
	kit.solid(xf * Transform3D(Basis(), Vector3(4.0, 0.4, -12.0)), Vector3(1.4, 0.8, 0.8), "gres_sombre", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(4.0, 0.86, -12.0)), Vector3(1.5, 0.12, 0.9), "or_c", 0.5)
	kit.commit()
	# des tas de sable dans les coins
	for c in [Vector3(-5.6, 0, -11.6), Vector3(5.6, 0, -0.4), Vector3(-5.8, 0, 0.4)]:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 1.2
		sm.height = 1.0
		sm.is_hemisphere = true
		mi.mesh = sm
		mi.material_override = kit.mat("sable_c")
		mi.scale = Vector3(1.0, 0.6, 1.2)
		_tomb_root.add_child(mi)
		mi.global_position = TOMB_IN + c
	# les torches et la lumière du puits au-dessus du sceau
	for z in [-3.5, -10.5]:
		for s3 in [-1.0, 1.0]:
			kit.torch(_tomb_root, TOMB_IN + Vector3(s3 * 6.55, 2.6, z), Vector3(-s3, 0, 0), 1.4)
	kit.torch(_tomb_root, TOMB_IN + Vector3(1.15, 2.2, 5.5), Vector3(-1, 0, 0), 1.0)
	var spot := SpotLight3D.new()
	spot.light_color = Color(1.0, 0.88, 0.62)
	spot.light_energy = 6.0
	spot.spot_range = 9.0
	spot.spot_angle = 18.0
	spot.shadow_enabled = pc
	_tomb_root.add_child(spot)
	spot.global_position = TOMB_IN + Vector3(0, 5.9, -6.0)
	spot.rotation.x = -PI * 0.5
	var shaft := MeshInstance3D.new()
	var cm2 := CylinderMesh.new()
	cm2.top_radius = 0.7
	cm2.bottom_radius = 1.1
	cm2.height = 4.6
	shaft.mesh = cm2
	var sh := StandardMaterial3D.new()
	sh.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sh.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sh.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sh.albedo_color = Color(1.0, 0.85, 0.55, 0.07)
	sh.cull_mode = BaseMaterial3D.CULL_DISABLED
	shaft.material_override = sh
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_tomb_root.add_child(shaft)
	shaft.global_position = TOMB_IN + Vector3(0, 3.9, -6.0)
	_tomb_seal = _seal_model("sceau_sables")
	_tomb_root.add_child(_tomb_seal)
	_tomb_seal.global_position = TOMB_IN + Vector3(0, 2.25, -6.0)


## Un sceau posé debout, qui tourne doucement sur lui-même, avec sa lumière.
func _seal_model(item: String) -> Node3D:
	var n := Node3D.new()
	n.name = "Sceau_" + item
	var m: Node3D = _inv().make_model(item)
	m.rotation.x = PI * 0.5
	m.scale = Vector3.ONE * 2.2
	n.add_child(m)
	var l := OmniLight3D.new()
	l.light_color = SEAL_COL.get(item.trim_prefix("sceau_"), Color(1, 1, 1))
	l.light_energy = 1.2
	l.omni_range = 4.0
	n.add_child(l)
	return n


# ------------------------------------------------------------------- la Bergerie du Vent

func _build_bergerie() -> void:
	var root: Node3D = _node("Bergerie_du_vent_v63")
	var g: float = _h(BERG.x, BERG.y)
	# l'entrée regarde vers le bas de la pente (le sud-est) : la grotte s'enfonce sous la colline
	var d: Vector2 = (BERG - Vector2(960.0, -315.0)).normalized()
	berg_xf = Transform3D(Basis(Vector3.UP, atan2(d.x, d.y)), Vector3(BERG.x, g, BERG.y))
	var t: Transform3D = berg_xf
	# l'arche de rochers autour de l'ouverture (l'ouverture regarde +Z)
	var pts: Array = []
	for k in range(9):
		var a: float = PI * k / 8.0
		pts.append(t * Vector3(cos(a) * 2.7, sin(a) * 3.3 - 0.4, -0.3))
	kit.rocks(root, pts, 6311, "roche_c", 1.0, 1.8)
	var back: Array = []
	for k2 in range(10):
		var a2: float = PI * (k2 / 9.0)
		back.append(t * Vector3(cos(a2) * 5.2, sin(a2) * 4.0 - 0.5, -2.8))
	for k3 in range(6):
		back.append(t * Vector3(-6.0 + k3 * 2.4, 4.6, -4.8))
	kit.rocks(root, back, 6312, "roche_c", 2.0, 3.2)
	# le noir de la grotte, le sol de l'entrée
	kit.box(t * Transform3D(Basis(), Vector3(0, 1.6, -2.4)), Vector3(4.2, 3.6, 0.3), "noir", 1.0)
	kit.col_box(t * Transform3D(Basis(), Vector3(0, 1.6, -1.8)), Vector3(4.0, 3.4, 0.6))
	kit.solid(t * Transform3D(Basis(), Vector3(0, -0.1, -0.6)), Vector3(4.4, 0.4, 3.2), "roche_c", 1.5)
	# un vieil enclos de bois et une auge de pierre devant
	# (chaque traverse va d'un piquet à l'autre : la clôture suit la pente)
	var posts: Array = []
	for k4 in range(6):
		var px: float = -5.5 + k4 * 1.6
		var fp: Vector3 = t * Vector3(px, 0, 4.4)
		var fy: float = _h(fp.x, fp.z)
		kit.cyl(Transform3D(t.basis, Vector3(fp.x, fy - 0.3, fp.z)), 0.08, 0.08, 1.4, "poutre_c", 6)
		posts.append(Vector3(fp.x, fy, fp.z))
	for k5 in range(posts.size() - 1):
		var pa: Vector3 = posts[k5]
		var pb: Vector3 = posts[k5 + 1]
		for ry in [0.35, 0.75]:
			var mid2: Vector3 = (pa + pb) * 0.5 + Vector3.UP * ry
			var dir: Vector3 = pb - pa
			kit.box(Transform3D(Basis.looking_at(dir.normalized(), Vector3.UP), mid2), Vector3(0.1, 0.12, dir.length() + 0.1), "poutre_c", 1.0)
	var tp: Vector3 = t * Vector3(3.8, 0, 2.4)
	kit.solid(Transform3D(t.basis, Vector3(tp.x, _h(tp.x, tp.z) - 0.1, tp.z)), Vector3(1.8, 1.2, 0.6), "granit_sombre", 1.0)
	kit.commit()
	# les ronces noires qui ferment l'entrée
	_brambles = Node3D.new()
	_brambles.name = "Ronces_noires"
	root.add_child(_brambles)
	_brambles.global_transform = t * Transform3D(Basis(), Vector3(0, 0, -0.6))
	var thorn := StandardMaterial3D.new()
	thorn.albedo_color = Color(0.12, 0.07, 0.1)
	thorn.roughness = 0.6
	thorn.metallic_specular = 0.7
	var rng := RandomNumberGenerator.new()
	rng.seed = 6314
	for k5 in range(28):
		var vine: ArrayMesh = _vine(rng, Vector3(rng.randf_range(-1.8, 1.8), rng.randf_range(-0.1, 0.4), rng.randf_range(-0.4, 0.3)), rng.randf_range(1.6, 3.4))
		var mi := MeshInstance3D.new()
		mi.mesh = vine
		mi.material_override = thorn
		_brambles.add_child(mi)
	var rb := StaticBody3D.new()
	_bramble_body = CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(4.0, 3.4, 1.0)
	_bramble_body.shape = bs
	_bramble_body.position = Vector3(0, 1.6, 0)
	rb.add_child(_bramble_body)
	_brambles.add_child(rb)


## Une tige de ronce : un tube qui serpente vers le haut, hérissé d'épines.
func _vine(rng: RandomNumberGenerator, base: Vector3, length: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = []
	var p: Vector3 = base
	var dir := Vector3(rng.randf_range(-0.6, 0.6), 1.0, rng.randf_range(-0.3, 0.3)).normalized()
	var n: int = 10
	for i in range(n + 1):
		pts.append(p)
		dir = (dir + Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.2, 0.3), rng.randf_range(-0.3, 0.3))).normalized()
		p += dir * length / n
	for i2 in range(n):
		var a: Vector3 = pts[i2]
		var b: Vector3 = pts[i2 + 1]
		var r0: float = lerpf(0.06, 0.015, float(i2) / n)
		var r1: float = lerpf(0.06, 0.015, float(i2 + 1) / n)
		var ax: Vector3 = (b - a).normalized()
		var u: Vector3 = ax.cross(Vector3.FORWARD if absf(ax.z) < 0.9 else Vector3.RIGHT).normalized()
		var v: Vector3 = ax.cross(u)
		for k in range(5):
			var t0: float = TAU * k / 5.0
			var t1: float = TAU * (k + 1) / 5.0
			var d0: Vector3 = u * cos(t0) + v * sin(t0)
			var d1: Vector3 = u * cos(t1) + v * sin(t1)
			for vv in [[a + d0 * r0, d0], [b + d1 * r1, d1], [b + d0 * r1, d0], [a + d0 * r0, d0], [a + d1 * r0, d1], [b + d1 * r1, d1]]:
				st.set_normal(vv[1])
				st.add_vertex(vv[0])
		# une épine
		var side: Vector3 = (u * cos(i2 * 2.1) + v * sin(i2 * 2.1)).normalized()
		var tip: Vector3 = a + side * (r0 + 0.11) + ax * 0.04
		var b0: Vector3 = a + side * r0 + u * 0.02
		var b1: Vector3 = a + side * r0 - u * 0.02 + ax * 0.03
		for vv2 in [b0, b1, tip]:
			st.set_normal(side)
			st.add_vertex(vv2)
	return st.commit()


func _build_bergerie_inside() -> void:
	_berg_root = _node("Bergerie_dedans_v63")
	var xf := Transform3D(Basis(), BERG_IN)
	kit.room(xf, -8.0, 8.0, -16.0, 6.0, 0.0, 7.0, "roche_c", "roche_c", [["s", 0.0, 3.6, 3.6], ["n", 0.0, 4.6, 3.8]], "roche_c", 1.0, 3.0)
	kit.room(xf, -1.8, 1.8, 6.0, 12.0, 0.0, 3.6, "roche_c", "roche_c", [["n", 0.0, 3.6, 3.6]], "roche_c", 0.8, 2.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 1.8, 12.3)), Vector3(3.6, 3.6, 0.2), "glow_argent", 1.0)
	# des rochers le long des murs, sous la voûte
	var along: Array = []
	for k in range(9):
		along.append(BERG_IN + Vector3(-7.6, 0.0, 5.0 - k * 2.4))
		along.append(BERG_IN + Vector3(7.6, 0.0, 5.0 - k * 2.4))
	kit.rocks(_berg_root, along, 6321, "roche_c", 1.4, 2.4)
	var ceil: Array = []
	for k2 in range(10):
		ceil.append(BERG_IN + Vector3(-6.0 + (k2 % 5) * 3.0, 6.6, 3.0 - (k2 / 5) * 8.0))
	kit.rocks(_berg_root, ceil, 6322, "roche_c", 1.0, 2.0)
	# l'enclos des moutons, la paille, la mangeoire
	for k3 in range(5):
		kit.cyl(xf * Transform3D(Basis(), Vector3(-2.8, 0, 3.0 - k3 * 1.6)), 0.08, 0.08, 1.2, "poutre_c", 6)
	for y in [0.45, 0.9]:
		kit.box(xf * Transform3D(Basis(), Vector3(-2.8, y, -0.2)), Vector3(0.1, 0.12, 6.6), "poutre_c", 1.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(-2.8, 0.6, -0.2)), Vector3(0.2, 1.2, 6.6))
	kit.solid(xf * Transform3D(Basis(), Vector3(-5.0, 0.4, -5.0)), Vector3(2.4, 0.8, 0.7), "bois_c", 1.0)
	# le coin du berger : banc, foyer éteint, la planche du chant
	kit.solid(xf * Transform3D(Basis(), Vector3(5.6, 0.25, 2.0)), Vector3(0.5, 0.5, 2.2), "bois_c", 1.0)
	for k4 in range(7):
		var a: float = TAU * k4 / 7.0
		kit.box(xf * Transform3D(Basis(Vector3.UP, a), Vector3(4.0 + cos(a) * 0.7, 0.15, -2.0 + sin(a) * 0.7)), Vector3(0.35, 0.3, 0.3), "granit_sombre", 0.5)
	kit.box(xf * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(6.95, 2.1, -6.0)), Vector3(2.4, 1.2, 0.08), "bois_c", 1.0)
	kit.quad(xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(6.9, 2.1, -6.0)), 2.2, 1.0, "img_chant_berger")
	# le mur de bronze du fond (l'ouverture de la porte au milieu), la console aux trois roues
	for s in [-1.0, 1.0]:
		kit.solid(xf * Transform3D(Basis(), Vector3(s * 5.15, 3.5, -15.7)), Vector3(5.7, 7.0, 0.6), "laiton_c", 2.0)
	kit.solid(xf * Transform3D(Basis(), Vector3(0, 5.35, -15.7)), Vector3(4.6, 3.3, 0.6), "laiton_c", 2.0)
	for s2 in [-1.0, 1.0]:
		kit.box(xf * Transform3D(Basis(), Vector3(s2 * 2.35, 1.85, -15.35)), Vector3(0.25, 3.7, 0.2), "fonte_c", 1.0)
	# la niche derrière la porte
	kit.room(xf, -2.3, 2.3, -21.0, -16.0, 0.0, 4.0, "roche_c", "dalles_c", [["s", 0.0, 6.4, 4.0]], "roche_c", 0.8, 2.0)
	kit.solid(xf * Transform3D(Basis(), Vector3(0, 0.55, -19.6)), Vector3(1.0, 1.1, 1.0), "granit", 1.0)
	kit.quad(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 2.4, -20.58)), 3.6, 2.2, "img_fresque_mare")
	kit.commit()
	# la paille de l'enclos
	for c in [Vector3(-5.5, 0, 1.5), Vector3(-6.0, 0, -2.5)]:
		var hay := MeshInstance3D.new()
		var hm := SphereMesh.new()
		hm.radius = 1.1
		hm.height = 1.0
		hm.is_hemisphere = true
		hay.mesh = hm
		hay.material_override = kit.mat("paille_c")
		hay.scale = Vector3(1.2, 0.8, 1.0)
		_berg_root.add_child(hay)
		hay.global_position = BERG_IN + c
	# la porte ronde (un grand engrenage de bronze), les roues
	_berg_door = Node3D.new()
	_berg_door.name = "Porte_ronde"
	_berg_root.add_child(_berg_door)
	_berg_door.global_position = BERG_IN + Vector3(0, 1.85, -15.55)
	var gear := MeshInstance3D.new()
	gear.mesh = load("res://scripts/pouvoirs_v63.gd").gear_mesh()
	gear.material_override = kit.mat("laiton_c")
	gear.scale = Vector3(6.6, 6.0, 6.6)
	gear.rotation.x = PI * 0.5
	_berg_door.add_child(gear)
	var hub := MeshInstance3D.new()
	var hcm := CylinderMesh.new()
	hcm.top_radius = 0.5
	hcm.bottom_radius = 0.5
	hcm.height = 0.5
	hub.mesh = hcm
	hub.material_override = kit.mat("cuivre_c")
	hub.rotation.x = PI * 0.5
	_berg_door.add_child(hub)
	var dbody := StaticBody3D.new()
	var dcs := CollisionShape3D.new()
	var dbs := BoxShape3D.new()
	dbs.size = Vector3(3.6, 3.6, 0.4)
	dcs.shape = dbs
	dbody.add_child(dcs)
	_berg_door.add_child(dbody)
	var wm := StandardMaterial3D.new()
	wm.albedo_texture = load("res://assets/textures/coeur/roue_moutons.png") if ResourceLoader.exists("res://assets/textures/coeur/roue_moutons.png") else null
	wm.albedo_color = Color(1, 1, 1) if wm.albedo_texture != null else Color(0.8, 0.65, 0.35)
	wm.metallic = 0.5
	wm.roughness = 0.45
	for i in range(3):
		var w := Node3D.new()
		w.name = "Roue_%d" % i
		_berg_root.add_child(w)
		w.global_position = BERG_IN + Vector3(-4.0 - i * 1.3, 1.4, -15.33)
		var disc := MeshInstance3D.new()
		var dm := CylinderMesh.new()
		dm.top_radius = 0.48
		dm.bottom_radius = 0.48
		dm.height = 0.08
		dm.radial_segments = 32
		disc.mesh = dm
		disc.material_override = wm
		disc.rotation.x = PI * 0.5
		w.add_child(disc)
		var notch := MeshInstance3D.new()
		var nm := PrismMesh.new()
		nm.size = Vector3(0.14, 0.12, 0.06)
		notch.mesh = nm
		notch.material_override = kit.mat("or_c")
		notch.rotation.z = PI
		_berg_root.add_child(notch)
		notch.global_position = BERG_IN + Vector3(-4.0 - i * 1.3, 1.4 + 0.58, -15.3)
		_wheels.append(w)
	# deux gardiens de bronze (des statues… pour l'instant)
	for s3 in [-1.0, 1.0]:
		var stat := Node3D.new()
		stat.name = "Statue_automate"
		_berg_root.add_child(stat)
		stat.global_position = BERG_IN + Vector3(s3 * 2.95, 0.0, -14.5)
		_statue(stat)
		_statues.append(stat)
	# la lumière : un puits de jour dans la voûte, des torches
	kit.glow_light(_berg_root, BERG_IN + Vector3(0, 6.0, -4.0), Color(0.75, 0.82, 1.0), 2.2, 16.0, true)
	kit.torch(_berg_root, BERG_IN + Vector3(6.95, 2.6, 1.0), Vector3(-1, 0, 0), 1.3)
	kit.torch(_berg_root, BERG_IN + Vector3(-2.0, 2.5, -15.3), Vector3(0, 0, 1), 1.4)
	kit.torch(_berg_root, BERG_IN + Vector3(2.0, 2.5, -15.3), Vector3(0, 0, 1), 1.4)
	kit.glow_light(_berg_root, BERG_IN + Vector3(0, 3.0, -18.5), Color(1.0, 0.82, 0.45), 1.4, 7.0)
	_berg_seal = _seal_model("sceau_airain")
	_berg_root.add_child(_berg_seal)
	_berg_seal.global_position = BERG_IN + Vector3(0, 1.6, -19.6)


## Une statue d'automate (le même modèle que le monstre, figé).
func _statue(parent: Node3D) -> void:
	var packed: PackedScene = load("res://assets/models/characters/hero.glb")
	var model: Node3D = packed.instantiate()
	model.scale = Vector3.ONE * 1.05
	parent.add_child(model)
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.7, 0.52, 0.28)
	brass.metallic = 0.55
	brass.roughness = 0.45
	brass.albedo_texture = load("res://assets/textures/cliquetis/laiton.png") if ResourceLoader.exists("res://assets/textures/cliquetis/laiton.png") else null
	brass.uv1_scale = Vector3(3, 3, 3)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		for k in range(m.mesh.get_surface_count()):
			m.set_surface_override_material(k, brass)
	var anim: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	var found := model.find_children("*", "Skeleton3D", true, false)
	if anim != null and found.size() > 0:
		var lib = load("res://scripts/hero_v28.gd").new()
		lib.hero = model
		lib.anim = anim
		lib.skel = found[0]
		lib._build_animations()
		lib.free()
		anim.play("v28/block")
		anim.seek(0.3, true)
		anim.pause()


# ------------------------------------------------------------------- Ramure : la vanne

func _build_vanne() -> void:
	var root: Node3D = _node("Vanne_grande_mare_v63")
	# la grande mare (la plus proche du point attendu)
	var best: float = INF
	for p in ile.ponds_world:
		var c: Vector3 = p[0]
		var d: float = Vector2(c.x - POND_GUESS.x, c.z - POND_GUESS.y).length()
		if d < best:
			best = d
			pond_c = c
			pond_r = float(p[1])
	if pond_c == Vector3.INF:
		return
	for ch in ile.get_children():
		if ch is MeshInstance3D and str(ch.name).begins_with("Mare_v59") and (ch as Node3D).position.distance_to(pond_c) < 1.0:
			_pond_disc = ch
	_pond_y0 = pond_c.y
	# la vanne, au bord ouest : un canal de pierre, une porte de bronze, une grande roue dentée
	var at := Vector3(pond_c.x - pond_r - 1.4, 0, pond_c.z - 1.0)
	at.y = minf(_h(at.x, at.z), pond_c.y + 0.4)
	vanne_xf = Transform3D(Basis(Vector3.UP, -PI * 0.5), at)
	var t: Transform3D = vanne_xf
	for s in [-1.0, 1.0]:
		kit.solid(t * Transform3D(Basis(), Vector3(s * 1.15, 0.2, -1.6)), Vector3(0.6, 1.8, 5.0), "granit_sombre", 1.5)
	kit.box(t * Transform3D(Basis(), Vector3(0, -0.65, -1.6)), Vector3(1.8, 0.2, 5.0), "granit_sombre", 1.5)
	kit.solid(t * Transform3D(Basis(), Vector3(0, 1.85, 0.0)), Vector3(3.0, 0.5, 0.7), "granit_sombre", 1.5)
	for s2 in [-1.0, 1.0]:
		kit.solid(t * Transform3D(Basis(), Vector3(s2 * 1.4, 0.75, 0.0)), Vector3(0.5, 2.7, 0.7), "granit_sombre", 1.5)
	kit.box(t * Transform3D(Basis(), Vector3(0, 2.15, 0.0)), Vector3(3.2, 0.12, 0.8), "mousse_c", 1.0)
	kit.commit()
	_vanne_gate = Node3D.new()
	_vanne_gate.name = "Porte_de_vanne"
	root.add_child(_vanne_gate)
	_vanne_gate.global_transform = t * Transform3D(Basis(), Vector3(0, 0.45, 0.0))
	_vanne_gate_y = _vanne_gate.position.y
	var gm := MeshInstance3D.new()
	var gb := BoxMesh.new()
	gb.size = Vector3(2.3, 1.7, 0.14)
	gm.mesh = gb
	var bronze_vert := StandardMaterial3D.new()
	bronze_vert.albedo_texture = load("res://assets/textures/cliquetis/cuivre.png") if ResourceLoader.exists("res://assets/textures/cliquetis/cuivre.png") else null
	bronze_vert.albedo_color = Color(0.42, 0.62, 0.5)
	bronze_vert.metallic = 0.6
	bronze_vert.roughness = 0.7
	gm.material_override = bronze_vert
	_vanne_gate.add_child(gm)
	# la grande roue dentée et deux pignons, sur le côté
	var gear_mesh: ArrayMesh = load("res://scripts/pouvoirs_v63.gd").gear_mesh()
	var specs := [[Vector3(2.0, 1.3, 0.2), 4.2], [Vector3(2.0, 2.55, 0.25), 2.0], [Vector3(2.0, 0.25, 0.25), 1.6]]
	for sp in specs:
		var g := MeshInstance3D.new()
		g.mesh = gear_mesh
		g.material_override = bronze_vert
		g.scale = Vector3.ONE * float(sp[1])
		var holder := Node3D.new()
		root.add_child(holder)
		holder.global_transform = t * Transform3D(Basis(Vector3.BACK, PI * 0.5), sp[0])
		holder.add_child(g)
		_vanne_gears.append(holder)
	# la pierre ronde au fond de la mare, son croissant d'argent
	var stone := MeshInstance3D.new()
	var scm := CylinderMesh.new()
	scm.top_radius = 1.3
	scm.bottom_radius = 1.45
	scm.height = 0.7
	scm.radial_segments = 28
	stone.mesh = scm
	stone.material_override = kit.mat("granit")
	root.add_child(stone)
	stone.global_position = Vector3(pond_c.x, pond_c.y - 1.55, pond_c.z)
	var sbody := StaticBody3D.new()
	var scs := CollisionShape3D.new()
	var cyl_s := CylinderShape3D.new()
	cyl_s.radius = 1.3
	cyl_s.height = 0.7
	scs.shape = cyl_s
	sbody.add_child(scs)
	stone.add_child(sbody)
	_moon_stone_glow = StandardMaterial3D.new()
	_moon_stone_glow.albedo_color = Color(0.8, 0.85, 0.95)
	_moon_stone_glow.metallic = 1.0
	_moon_stone_glow.roughness = 0.2
	_moon_stone_glow.emission_enabled = true
	_moon_stone_glow.emission = Color(0.6, 0.75, 1.0)
	_moon_stone_glow.emission_energy_multiplier = 0.0
	var crescent := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.5
	tm.outer_radius = 0.62
	crescent.mesh = tm
	crescent.material_override = _moon_stone_glow
	crescent.scale = Vector3(1.0, 0.3, 1.0)
	stone.add_child(crescent)
	crescent.position = Vector3(0.12, 0.35, 0)
	_pond_seal = _seal_model("sceau_brumes")
	root.add_child(_pond_seal)
	_pond_seal.global_position = Vector3(pond_c.x, pond_c.y - 0.6, pond_c.z)
	_pond_seal.visible = false


# ------------------------------------------------------------------- Carène : la Dame de Proue

func _build_figure() -> void:
	var ep: Node3D = main.grande_v59.epave
	if ep == null:
		return
	var HL: float = float(ep.HL)
	var dy: float = float(ep.deck_y(HL))
	_figure = Node3D.new()
	_figure.name = "Dame_de_proue_v63"
	add_child(_figure)
	# repère du navire : +X vers l'avant. La Dame est sculptée dans l'étrave : le dos contre la
	# coque, penchée en avant au-dessus des vagues, le regard vers le large.
	_figure.global_transform = ep.xf * Transform3D(Basis(Vector3.BACK, -0.62) * Basis(Vector3.UP, PI * 0.5), Vector3(HL - 0.75, dy - 2.9, 0))
	var packed: PackedScene = load("res://assets/models/characters/hero.glb")
	var model: Node3D = packed.instantiate()
	model.scale = Vector3.ONE * 1.7
	_figure.add_child(model)
	# du bois sculpté, peint en bleu de mer délavé (la peinture s'écaille : on voit le bois)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.6, 0.74, 0.86)
	paint.roughness = 0.72
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		for k in range(m.mesh.get_surface_count()):
			m.set_surface_override_material(k, paint)
	var anim: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	var found := model.find_children("*", "Skeleton3D", true, false)
	if anim != null and found.size() > 0:
		var lib = load("res://scripts/hero_v28.gd").new()
		lib.hero = model
		lib.anim = anim
		lib.skel = found[0]
		lib._build_animations()
		lib.free()
		# les mains jointes devant la poitrine (la garde du héros, figée)
		anim.play("v28/block")
		anim.seek(0.35, true)
		anim.pause()
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.85, 0.66, 0.3)
	gold.metallic = 0.6
	gold.roughness = 0.4
	# le coquillage fermé qu'elle tient (deux valves : la valve du dessus s'ouvrira)
	var shell := Node3D.new()
	shell.name = "Coquillage"
	model.add_child(shell)
	shell.position = Vector3(0, 1.22, 0.36)
	var low := MeshInstance3D.new()
	var lm := SphereMesh.new()
	lm.radius = 0.14
	lm.height = 0.14
	lm.is_hemisphere = true
	low.mesh = lm
	low.material_override = gold
	low.rotation.x = PI
	low.scale = Vector3(1.25, 0.6, 1.0)
	shell.add_child(low)
	_shell_lid = Node3D.new()
	_shell_lid.position = Vector3(0, 0, -0.12)
	shell.add_child(_shell_lid)
	var top := MeshInstance3D.new()
	top.mesh = lm
	top.material_override = gold
	top.position = Vector3(0, 0, 0.12)
	top.scale = Vector3(1.25, 0.6, 1.0)
	_shell_lid.add_child(top)
	_figure_glow = OmniLight3D.new()
	_figure_glow.light_color = Color(0.35, 0.95, 0.9)
	_figure_glow.light_energy = 0.0
	_figure_glow.omni_range = 7.0
	model.add_child(_figure_glow)
	_figure_glow.position = Vector3(0, 1.3, 0.7)
	proue_at = ep.W(Vector3(HL - 6.5, ep.deck_y(HL - 6.5) + 0.1, 0))


func _fig_mesh(parent: Node3D, mesh: Mesh, m: Material, pos: Vector3, scl: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.scale = scl
	mi.rotation = rot
	parent.add_child(mi)
	return mi


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s


func _cyl(a: float, b: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = a
	c.bottom_radius = b
	c.height = h
	c.radial_segments = 14
	return c


# =================================================================== invites et pouvoirs

func _register() -> void:
	var I: Array = main.donjon_v35._interactions
	# Tazira : les bornes, les anneaux, la porte
	for i in range(BORNES.size()):
		var ii: int = i
		var b: Vector2 = BORNES[i]
		I.append({"id": "tz63_borne_%d" % i, "pos": Vector3(b.x, _h(b.x, b.y), b.y), "radius": 2.6, "text": "E : examiner la borne", "vr": "Gâchette : la borne",
			"call": func(): _borne(ii)})
	for i2 in range(3):
		var r: int = i2
		var rp: Vector3 = tomb_door_xf * Vector3(-1.15 + i2 * 1.15, 0.0, 1.2)
		I.append({"id": "tz63_anneau_%d" % i2, "pos": rp, "radius": 0.62, "text": "E : tourner l'anneau %s" % ["de gauche", "du milieu", "de droite"][i2],
			"vr": "Gâchette : tourner l'anneau", "call": func(): _turn_ring(r), "when": func(): return not bool(state["tombeau"])})
	I.append({"id": "tz63_porte", "pos": tomb_door_xf * Vector3(0, 0, 2.6), "radius": 2.4, "text": "E : examiner la porte du tombeau", "vr": "Gâchette : la porte",
		"call": _tomb_door_text, "when": func(): return not bool(state["tombeau"])})
	I.append({"id": "tz63_descendre", "pos": tomb_door_xf * Vector3(0, 0, 1.4), "radius": 2.6, "text": "E : descendre dans le tombeau", "vr": "Gâchette : descendre",
		"call": _enter_tomb, "when": func(): return bool(state["tombeau"])})
	I.append({"id": "tz63_remonter", "pos": TOMB_IN + Vector3(0, 0, 8.6), "radius": 1.8, "text": "E : remonter à la surface", "vr": "Gâchette : remonter",
		"call": _leave_tomb})
	I.append({"id": "tz63_sceau", "pos": TOMB_IN + Vector3(0, 0.3, -4.4), "radius": 1.7, "text": "E : prendre le Sceau des Sables", "vr": "Gâchette : prendre le sceau",
		"call": _take_sables, "when": func(): return not bool(state["sceau_sables"])})
	I.append({"id": "tz63_fresque", "pos": TOMB_IN + Vector3(0, 0, -11.3), "radius": 2.6, "text": "E : regarder la fresque", "vr": "Gâchette : la fresque",
		"call": func(): _say("Une grande fresque, peinte il y a très longtemps : un berger et ses moutons au pied d'une montagne grise, une grotte, et dans la grotte une roue dentée de bronze. Au-dessus, la crête du Cœur-de-Pierre, vue du nord. Une astronome, avec une grande lunette, saurait sûrement où c'est…", 9.0)})
	I.append({"id": "tz63_coffre", "pos": TOMB_IN + Vector3(4.0, 0, -11.0), "radius": 1.6, "text": "E : ouvrir le coffre de grès", "vr": "Gâchette : le coffre",
		"call": _tomb_chest, "when": func(): return not bool(state["coffre_tombeau"])})
	# la Bergerie du Vent
	I.append({"id": "br63_ronces", "pos": berg_xf * Vector3(0, 0, 2.2), "radius": 3.2, "text": "E : examiner les ronces noires", "vr": "Gâchette : les ronces",
		"call": _bramble_text, "when": func(): return not bool(state["ronces"])})
	I.append({"id": "br63_entrer", "pos": berg_xf * Vector3(0, 0, 1.4), "radius": 3.0, "text": "E : entrer dans la Bergerie du Vent", "vr": "Gâchette : entrer",
		"call": _enter_berg, "when": func(): return bool(state["ronces"])})
	I.append({"id": "br63_sortir", "pos": BERG_IN + Vector3(0, 0, 10.0), "radius": 2.0, "text": "E : ressortir", "vr": "Gâchette : ressortir", "call": _leave_berg})
	for i3 in range(3):
		var w: int = i3
		I.append({"id": "br63_roue_%d" % i3, "pos": BERG_IN + Vector3(-4.0 - i3 * 1.3, 0, -14.5), "radius": 0.62, "text": "E : tourner la %s roue" % ["première", "deuxième", "troisième"][i3],
			"vr": "Gâchette : tourner la roue", "call": func(): _turn_wheel(w), "when": func(): return not bool(state["porte_bergerie"])})
	I.append({"id": "br63_chant", "pos": BERG_IN + Vector3(6.2, 0, -6.0), "radius": 1.8, "text": "E : lire la planche peinte", "vr": "Gâchette : lire",
		"call": func(): _say("Le chant du berger, peint à la chaux sur une planche : « Trois moutons sur la crête, au soleil du matin ; un seul dans la vallée, qui boude dans le thym ; deux à la bergerie, qui dorment près du feu. Compte-les dans l'ordre, et le vent t'ouvrira. »", 11.0)})
	I.append({"id": "br63_porte", "pos": BERG_IN + Vector3(0, 0, -12.6), "radius": 2.2, "text": "E : examiner la porte ronde", "vr": "Gâchette : la porte",
		"call": func(): _say("Une porte ronde comme un engrenage, en bronze, gardée par deux statues de métal. À gauche, sur le mur, trois roues gravées de moutons : un, deux, trois ou quatre. Dans le coin du berger, contre la paroi, une planche peinte…", 6.0),
		"when": func(): return not bool(state["porte_bergerie"])})
	I.append({"id": "br63_sceau", "pos": BERG_IN + Vector3(0, 0, -18.4), "radius": 1.8, "text": "E : prendre le Sceau d'Airain", "vr": "Gâchette : prendre le sceau",
		"call": _take_airain, "when": func(): return bool(state["porte_bergerie"]) and not bool(state["sceau_airain"])})
	I.append({"id": "br63_fresque", "pos": BERG_IN + Vector3(0, 0, -19.8), "radius": 1.4, "text": "E : regarder la fresque", "vr": "Gâchette : la fresque",
		"call": func(): _say("Une petite fresque au fond de la niche : une mare entourée de grands arbres, une vanne de bronze sur son bord, et au-dessus, une pleine lune qui verse sa lumière jusqu'au fond de l'eau. Les gens des brumes, à Ramure… Mère-Lune saura.", 9.0),
		"when": func(): return bool(state["porte_bergerie"])})
	# Ramure : la vanne et la pierre ronde
	if pond_c != Vector3.INF:
		I.append({"id": "rm63_vanne", "pos": vanne_xf * Vector3(0, 0, -2.4), "radius": 3.0, "text": "E : examiner la vieille vanne", "vr": "Gâchette : la vanne",
			"call": _vanne_text, "when": func(): return not bool(state["vanne"])})
		I.append({"id": "rm63_pierre", "pos": Vector3(pond_c.x, pond_c.y - 1.2, pond_c.z), "radius": 2.6, "text": "E : examiner la pierre ronde", "vr": "Gâchette : la pierre",
			"call": _stone, "when": func(): return bool(state["vanne"]) and not bool(state["sceau_brumes"])})
	# Carène : la Dame de Proue
	if proue_at != Vector3.INF:
		I.append({"id": "cr63_proue", "pos": proue_at, "radius": 3.2, "text": "E : se pencher vers la Dame de Proue", "vr": "Gâchette : la Dame de Proue",
			"call": _figurehead, "when": func(): return not bool(state["sceau_embruns"])})
	# la porte ouverte : descendre
	I.append({"id": "porte63_descendre", "pos": ile.door_front(), "radius": 6.0, "text": "E : descendre sous le Cœur-de-Pierre", "vr": "Gâchette : descendre",
		"call": _go_down, "when": func(): return bool(state["porte_ouverte"])})
	# les pouvoirs
	var pw: Node = main.get("pouvoirs_v63")
	if pw != null:
		pw.register({"id": "br63_ronces", "power": "flamme", "pos": berg_xf * Vector3(0, 1.4, -0.4), "radius": 2.2, "call": _burn_brambles,
			"when": func(): return not bool(state["ronces"])})
		if pond_c != Vector3.INF:
			pw.register({"id": "rm63_vanne", "power": "rouage", "pos": vanne_xf * Vector3(0, 1.0, 0), "radius": 2.5, "call": _open_vanne,
				"when": func(): return not bool(state["vanne"])})
		pw.register({"id": "journal63", "power": "lune", "call": _read_journal,
			"when": func(): return not bool(state["journal_lu"]) and _inv().count("journal_bord") > 0})


# ------------------------------------------------------------------- Tazira

func _borne(i: int) -> void:
	var t: String = ["Une vieille borne de grès, rongée par le vent de sable. Au sommet, une étoile de bronze ajourée. Une flèche gravée montre le nord-est, vers les dunes.",
		"La deuxième borne. Des chameaux sont gravés sur ses flancs, en file. La flèche montre toujours le nord-est.",
		"La troisième borne. Sa flèche montre une grande dune en croissant, tout près… On dirait que la dune a bougé depuis qu'on a gravé la flèche : elle a avancé d'au moins dix pas."][i]
	if moon():
		t += " L'étoile, au sommet, brille d'une lumière douce, comme si quelqu'un l'avait allumée."
	_say(t, 7.0)


func _tomb_door_text() -> void:
	_say("Une porte de grès, à demi enfouie dans la dune. Au-dessus, un soleil d'or. Sur la dalle, trois anneaux de pierre gravés de signes : l'étoile, la dune, le soleil, la lune, le palmier, le scarabée. Une encoche d'or au-dessus de chacun.", 8.0)


func _turn_ring(i: int) -> void:
	if bool(state["tombeau"]) or _busy:
		return
	var a: Array = state["anneaux"]
	a[i] = (int(a[i]) + 1) % SYMBOLS.size()
	main.sfx("pierre_glisse", (_rings[i] as Node3D).global_position, -6.0)
	_place_rings(true)
	main._show_message_v28("L'anneau %s montre %s." % [["de gauche", "du milieu", "de droite"][i], SYMBOLS[int(a[i])]])
	for k in range(3):
		if int(a[k]) != RING_GOAL[k]:
			return
	_open_tomb()


func _place_rings(animate: bool) -> void:
	var a: Array = state["anneaux"]
	for i in range(_rings.size()):
		var target: float = -float(int(a[i])) * TAU / SYMBOLS.size()
		var r: Node3D = _rings[i]
		if animate:
			var cur: float = r.rotation.z
			while target > cur + 0.01:
				target -= TAU
			create_tween().tween_property(r, "rotation:z", target, 0.35).set_trans(Tween.TRANS_BACK)
		else:
			r.rotation.z = target


func _open_tomb() -> void:
	state["tombeau"] = true
	_busy = true
	await get_tree().create_timer(0.5).timeout
	main.sfx("porte_coeur", tomb_door_xf.origin + Vector3.UP * 2.0)
	main.jingle("decouverte")
	_say("L'étoile, la dune, le soleil… Les trois anneaux s'alignent ! Un grondement sourd monte de la dune, le sable se met à couler… et la dalle s'enfonce lentement dans le sol.", 7.0)
	var tw := create_tween()
	tw.tween_property(_tomb_slab, "position:y", _tomb_slab_y - 4.8, 3.5).set_trans(Tween.TRANS_SINE)
	if main.combat_v28 != null:
		for k in range(5):
			main.combat_v28.puff(tomb_door_xf * Vector3(-1.6 + k * 0.8, 0.4, 0.6), Color(0.9, 0.78, 0.55))
	await tw.finished
	var cb: Node = _tomb_slab.get_node_or_null("Collision")
	if cb != null:
		(cb as StaticBody3D).collision_layer = 0
	_busy = false


func _enter_tomb() -> void:
	var first: bool = not bool(state["visite_tombeau"])
	state["visite_tombeau"] = true
	await main.donjon_v35._travel(TOMB_IN + Vector3(0, 0.1, 7.0), Vector3(0, 0, -1))
	if first:
		_say("Le tombeau de la Dune qui Marche. L'air est sec, immobile. Des colonnes de grès, des sarcophages, et tout au fond, sur une estrade, dans un rayon de lumière tombé d'on ne sait où… un disque d'or.", 9.0)


func _leave_tomb() -> void:
	_end_fight()
	await main.donjon_v35._travel(tomb_door_xf * Vector3(0, 0.15, 3.2), tomb_door_xf.basis * Vector3(0, 0, 1))


func _tomb_chest() -> void:
	if not _inv().can_accept([["piece", 40], ["rubis", 1]]):
		_say("Ton sac est plein ! Fais de la place avant d'ouvrir le coffre.", 4.0)
		return
	state["coffre_tombeau"] = true
	main.sfx("coffre", TOMB_IN + Vector3(4.0, 1.0, -12.0))
	var a: int = _inv().add("piece", 40)
	_inv().add("rubis", 1)
	_say("Le couvercle de grès glisse : %d pièces des caravanes, et un rubis gros comme une datte." % a, 6.0)


func _take_sables() -> void:
	if not _give_seal("sables"):
		return
	_tomb_seal.visible = false
	_say("Tu prends le Sceau des Sables. Il est chaud comme une pierre au soleil… et soudain, il brûle sans faire mal : une flamme s'éveille au creux de ta main ! (Touche 2 pour choisir la Flamme, X pour la lancer ; en VR : B.) Le sable des coins se met à bouger…", 10.0)
	await get_tree().create_timer(2.5).timeout
	_start_fight("tombeau", [["scorpion", TOMB_IN + Vector3(-5.6, 0.1, -11.6)], ["scorpion", TOMB_IN + Vector3(5.6, 0.1, -0.4)], ["scorpion", TOMB_IN + Vector3(-5.8, 0.1, 0.4)]],
		"Les scorpions ne bougent plus. Le tombeau retrouve son silence… Sur le mur du fond, une grande fresque.")


# ------------------------------------------------------------------- la Bergerie

func _bramble_text() -> void:
	var t: String = "Des ronces noires, épaisses comme le poignet, couvertes d'épines luisantes. Elles ferment toute l'entrée de la grotte. Le couteau glisse dessus comme sur du verre."
	var pr: Node = main.get("progression_v63")
	if pr != null and pr.power_owned("flamme"):
		t += " Le Sceau des Sables est chaud dans ta poche… La Flamme (touche 2, puis X) ?"
	_say(t, 7.0)


func _burn_brambles() -> void:
	if bool(state["ronces"]):
		return
	state["ronces"] = true
	main.sfx("feu_ronces", berg_xf * Vector3(0, 1.5, 0))
	var fire: CPUParticles3D = kit.fire(_brambles, Vector3(0, 1.4, 0), 0.5, 90)
	fire.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	fire.emission_box_extents = Vector3(1.8, 1.5, 0.4)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.55, 0.2)
	l.light_energy = 3.0
	l.omni_range = 12.0
	_brambles.add_child(l)
	l.position = Vector3(0, 1.6, 1.0)
	_say("La Flamme prend dans les ronces noires ! Elles se tordent, crépitent, sifflent… et tombent en cendres.", 6.0)
	var tw := create_tween()
	tw.tween_interval(1.0)
	var vines: Array = []
	for c in _brambles.get_children():
		if c is MeshInstance3D:
			vines.append(c)
	for v in vines:
		tw.parallel().tween_property(v, "scale", Vector3(1.0, 0.05, 1.0), 2.6).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): fire.emitting = false)
	tw.tween_property(l, "light_energy", 0.0, 1.0)
	tw.tween_callback(_brambles_gone)


func _brambles_gone() -> void:
	if _bramble_body != null:
		_bramble_body.disabled = true
	for c in _brambles.get_children():
		if c is MeshInstance3D:
			(c as Node3D).visible = false


func _enter_berg() -> void:
	var first: bool = not bool(state["visite_bergerie"])
	state["visite_bergerie"] = true
	await main.donjon_v35._travel(BERG_IN + Vector3(0, 0.1, 9.0), Vector3(0, 0, -1))
	if first:
		_say("La Bergerie du Vent. Une grande grotte, un enclos de bois, de la paille sèche, un foyer froid. Tout au fond, un mur de bronze et une porte ronde comme un engrenage, gardée par deux statues de métal.", 9.0)


func _leave_berg() -> void:
	_end_fight()
	await main.donjon_v35._travel(berg_xf * Vector3(0, 0.2, 3.0), berg_xf.basis * Vector3(0, 0, 1))


func _turn_wheel(i: int) -> void:
	if bool(state["porte_bergerie"]) or _busy:
		return
	var a: Array = state["roues"]
	a[i] = int(a[i]) % 4 + 1
	main.sfx("mecanisme", (_wheels[i] as Node3D).global_position, -6.0)
	_place_wheels(true)
	main._show_message_v28("La %s roue montre %d mouton%s." % [["première", "deuxième", "troisième"][i], int(a[i]), "s" if int(a[i]) > 1 else ""])
	for k in range(3):
		if int(a[k]) != WHEEL_GOAL[k]:
			return
	_open_berg_door()


func _place_wheels(animate: bool) -> void:
	var a: Array = state["roues"]
	for i in range(_wheels.size()):
		var target: float = -float(int(a[i]) - 1) * TAU / 4.0
		var w: Node3D = _wheels[i]
		if animate:
			var cur: float = w.rotation.z
			while target > cur + 0.01:
				target -= TAU
			create_tween().tween_property(w, "rotation:z", target, 0.35).set_trans(Tween.TRANS_BACK)
		else:
			w.rotation.z = target


func _open_berg_door() -> void:
	state["porte_bergerie"] = true
	_busy = true
	await get_tree().create_timer(0.5).timeout
	main.sfx("mecanisme", _berg_door.global_position)
	main.jingle("decouverte")
	_say("Trois, un, deux… Un déclic, puis un long cliquetis : la porte ronde se met à tourner sur elle-même, comme un engrenage… et roule de côté !", 6.0)
	var tw := create_tween()
	tw.tween_property(_berg_door, "position:x", _berg_door.position.x + 3.9, 3.0).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(_berg_door, "rotation:z", -TAU * 0.6, 3.0).set_trans(Tween.TRANS_SINE)
	await tw.finished
	_busy = false


func _take_airain() -> void:
	if not _give_seal("airain"):
		return
	_berg_seal.visible = false
	_say("Le Sceau d'Airain ! Il se met à tourner tout seul dans ta main, ses dents cliquettent… Une mécanique s'éveille en toi : le Rouage (touche 3, puis X ; en VR : B). Derrière toi, un bruit de métal : les deux statues bougent !", 10.0)
	await get_tree().create_timer(2.0).timeout
	var list: Array = []
	for s in _statues:
		(s as Node3D).visible = false
		list.append(["automate", (s as Node3D).global_position + Vector3.UP * 0.05])
	_start_fight("bergerie", list, "Les deux gardiens de bronze s'effondrent dans un dernier cliquetis. La bergerie redevient silencieuse… Au fond de la niche, une petite fresque.")


# ------------------------------------------------------------------- Ramure

func _vanne_text() -> void:
	var t: String = "Une vieille vanne de bronze, toute verte, à moitié prise dans la vase. Une grande roue dentée, deux pignons soudés par le temps… Aucune main ne la fera tourner."
	var pr: Node = main.get("progression_v63")
	if pr != null and pr.power_owned("rouage"):
		t += " Mais le Sceau d'Airain cliquette dans ta poche… Le Rouage (touche 3, puis X) ?"
	_say(t, 7.0)


func _open_vanne() -> void:
	if bool(state["vanne"]):
		return
	state["vanne"] = true
	main.sfx("mecanisme", vanne_xf.origin + Vector3.UP)
	main.sfx("eau_vanne", vanne_xf.origin)
	_say("Les engrenages grincent… et se mettent à tourner ! La porte de bronze se lève, l'eau de la grande mare s'engouffre dans le vieux canal en grondant. Le niveau baisse, baisse… Au milieu de la mare apparaît une grande pierre ronde.", 9.0)
	for i in range(_vanne_gears.size()):
		var g: Node3D = _vanne_gears[i]
		create_tween().tween_property(g, "rotation:y", g.rotation.y + (TAU * 1.5 if i % 2 == 0 else -TAU * 2.5), 6.0).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(_vanne_gate, "position:y", _vanne_gate_y + 1.5, 4.0).set_trans(Tween.TRANS_SINE)
	if _pond_disc != null:
		create_tween().tween_property(_pond_disc, "position:y", _pond_y0 - 1.45, 8.0).set_trans(Tween.TRANS_SINE)


func _stone() -> void:
	if not moon():
		_say("Une grande pierre ronde, gravée d'un croissant d'argent. Rien dessus… « Seule la lune sait où il dort », disait Mère-Lune. Il faudra revenir quand la lune se lèvera (la nuit tombe vers 20 h ; on peut dormir à l'auberge pour l'attendre).", 9.0)
		return
	if not _give_seal("brumes"):
		return
	_pond_seal.visible = false
	_say("La lune touche la pierre… le croissant d'argent s'allume, et un disque pâle monte lentement de la pierre, dans la brume : le Sceau des Brumes ! Une lumière de lune s'éveille en toi (touche 4, puis X ; en VR : B). Et la brume, autour de la mare, prend des formes…", 10.0)
	await get_tree().create_timer(2.5).timeout
	var list: Array = []
	for k in range(3):
		var a: float = TAU * k / 3.0 + 0.6
		var p := Vector3(pond_c.x + cos(a) * (pond_r + 3.0), 0, pond_c.z + sin(a) * (pond_r + 3.0))
		p.y = _h(p.x, p.z) + 0.1
		list.append(["spectre", p])
	_start_fight("mare", list, "Les spectres se défont en lambeaux de brume. La grande mare redevient calme… La vieille vanne se referme doucement : l'eau remonte.")


# ------------------------------------------------------------------- le journal, la Dame de Proue

func _read_journal(_on: bool = true) -> void:
	if bool(state["journal_lu"]):
		return
	state["journal_lu"] = true
	main.jingle("decouverte")
	_say("Dans ton sac, le journal de bord se met à luire ! À la Lueur de lune, des lignes d'argent apparaissent sur les pages blanches : « Le Sceau des Embruns, je l'ai confié à notre Dame de Proue. Elle ne le rendra qu'à qui lui montrera ses trois sœurs : les sables, l'airain et les brumes. — Yves Kerhervé, dernier capitaine du Léviathan. »", 14.0)


func _figurehead() -> void:
	var have: int = 0
	for s in ["sceau_sables", "sceau_airain", "sceau_brumes"]:
		if _inv().count(s) > 0:
			have += 1
	if have < 3 or not bool(state["journal_lu"]):
		var t: String = "Sous le beaupré, la Dame de Proue : une femme de bois sculpté, penchée au-dessus des vagues, les mains jointes sur un coquillage fermé. La peinture bleue de sa robe s'écaille. Elle regarde la mer depuis deux cents ans."
		if bool(state["journal_lu"]):
			t += " Le journal le disait : elle attend ses trois sœurs. Il t'en manque %d." % (3 - have)
		_say(t, 8.0)
		return
	if not _inv().can_accept([["sceau_embruns", 1]]):
		_say("Ton sac est plein ! Fais un peu de place.", 4.0)
		return
	_busy = true
	main.sfx("esprit", _figure.global_position)
	_say("Tu lèves les trois sceaux vers la Dame de Proue. Ils s'allument : or, bronze, argent… Le bois craque. Lentement, entre ses mains, le coquillage s'ouvre.", 7.0)
	var tw := create_tween()
	for a in _figure_arms:
		tw.parallel().tween_property(a[0], "rotation:z", float(a[1]) * 0.9, 3.0).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(_figure_glow, "light_energy", 4.0, 3.0)
	if _shell_lid != null:
		tw.parallel().tween_property(_shell_lid, "rotation:x", -1.3, 3.0).set_trans(Tween.TRANS_SINE)
	await tw.finished
	_busy = false
	if _give_seal("embruns"):
		_say("Une lumière d'écume monte du coquillage : le Sceau des Embruns, frais comme une vague ! Le vent du large se lève autour de toi et fait claquer les vieilles voiles : la Bourrasque (touche 1, puis X ; en VR : B). Il ne reste plus qu'à porter les quatre sceaux à la grande porte.", 11.0)
	create_tween().tween_property(_figure_glow, "light_energy", 0.6, 4.0)


# ------------------------------------------------------------------- la Porte aux Quatre Sceaux

func door_open() -> bool:
	return bool(state["porte_ouverte"])


## Appelé par grande_v59._examine_door : renvoie true si la grande enquête a pris la main.
func door_interact(_first: bool) -> bool:
	if bool(state["porte_ouverte"]) or _busy:
		return true
	var have: Array = []
	for s in ["sables", "airain", "brumes", "embruns"]:
		if _inv().count("sceau_" + s) > 0:
			have.append(s)
	var j: Node = main.get("journal_v56")
	var started: bool = j != null and str(j.state("quatre_sceaux")) in ["en_cours", "finie"]
	if have.size() < 4:
		if not started and have.is_empty():
			return false
		_say("La Porte aux Quatre Sceaux. Les quatre creux attendent leurs sceaux : tu en as %d sur quatre. Les autres peuples de l'île gardent les leurs…" % have.size(), 6.0)
		return true
	_place_seals()
	return true


func _place_seals() -> void:
	_busy = true
	var gate: Node3D = ile.door_gate
	_say("Tu lèves les quatre sceaux vers la grande porte…", 4.0)
	for s in ["airain", "embruns", "sables", "brumes"]:
		await get_tree().create_timer(1.1).timeout
		_inv().remove("sceau_" + s, 1)
		var disc: Node3D = _door_seal(s)
		disc.scale = Vector3.ONE * 0.1
		create_tween().tween_property(disc, "scale", Vector3.ONE * 5.2, 0.8).set_trans(Tween.TRANS_BACK)
		main.sfx("sceau_pose", gate.global_position + Vector3.UP * 9.0)
	await get_tree().create_timer(1.2).timeout
	main.sfx("porte_coeur", gate.global_position + Vector3.UP * 6.0)
	_say("Les quatre sceaux s'allument ensemble. Le grand cercle flamboie… La montagne gronde, très loin, très profond, comme un cœur qui se réveille. Puis, dans un fracas de pierre, la Porte aux Quatre Sceaux s'enfonce dans le sol.", 10.0)
	var glow: StandardMaterial3D = ile.door_glow
	create_tween().tween_property(glow, "emission_energy_multiplier", 4.0, 2.0)
	await get_tree().create_timer(2.0).timeout
	var tw := create_tween()
	tw.tween_property(ile.door_mobile, "position:y", -19.0, 6.0).set_trans(Tween.TRANS_SINE)
	if main.combat_v28 != null:
		for k in range(9):
			main.combat_v28.puff(gate.global_transform * Vector3(-6.0 + k * 1.5, 0.6, 1.0), Color(0.75, 0.72, 0.66))
	await tw.finished
	state["porte_ouverte"] = true
	_disable_leaves()
	_show_door_void(true)
	main.jingle("decouverte")
	_say("La porte est ouverte ! Derrière, un escalier immense plonge dans le noir, sous le Cœur-de-Pierre. Un souffle tiède en monte. (E : descendre)", 8.0)
	_busy = false


## Derrière la porte ouverte : le noir de l'escalier qui plonge sous la montagne, et une
## lueur rouge tout au fond (le Cœur qui bat).
func _show_door_void(on: bool) -> void:
	if ile.door_gate == null:
		return
	if _door_void == null:
		_door_void = Node3D.new()
		_door_void.name = "Noir_de_la_porte_v63"
		ile.door_gate.add_child(_door_void)
		var black := StandardMaterial3D.new()
		black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		black.albedo_color = Color(0.0, 0.0, 0.0)
		var q := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(14.8, 19.0, 0.1)
		q.mesh = bm
		q.material_override = black
		q.position = Vector3(0, 9.2, -1.6)
		_door_void.add_child(q)
		var glow := OmniLight3D.new()
		glow.light_color = Color(1.0, 0.32, 0.15)
		glow.light_energy = 0.8
		glow.omni_range = 9.0
		glow.position = Vector3(0, 1.5, -1.2)
		_door_void.add_child(glow)
	_door_void.visible = on


func _door_seal(s: String) -> Node3D:
	var k: int = int(SOCKET_OF[s])
	var p: Vector3 = ile.door_sockets[k] if k < ile.door_sockets.size() else Vector3(0, 9.2, 0)
	var n: Node3D = _inv().make_model("sceau_" + s)
	n.name = "Sceau_pose_" + s
	ile.door_mobile.add_child(n)
	n.position = p + Vector3(0, 0, 0.32)
	n.rotation.x = PI * 0.5
	n.scale = Vector3.ONE * 5.2
	_door_seals.append(n)
	return n


func _disable_leaves() -> void:
	for leaf in ile.door_leaves:
		for c in (leaf as Node).get_children():
			if c is StaticBody3D:
				(c as StaticBody3D).collision_layer = 0


func _go_down() -> void:
	var co: Node = main.get("coeur_v63")
	if co != null:
		co.enter()


# =================================================================== sceaux donnés, combats

## Le sceau va dans le sac, son pouvoir s'éveille (progression_v63.give_seal).
func _give_seal(id: String) -> bool:
	if not _inv().can_accept([["sceau_" + id, 1]]):
		_say("Ton sac est plein ! Fais un peu de place pour le sceau.", 4.0)
		return false
	_inv().add("sceau_" + id, 1)
	state["sceau_" + id] = true
	main.sfx("sceau_eveil", main._player_pos_v27())
	main.jingle("decouverte")
	var pr: Node = main.get("progression_v63")
	if pr != null:
		pr.give_seal(id)
	return true


func _start_fight(where: String, list: Array, done_text: String) -> void:
	_end_fight()
	var mo: Node = main.get("monstres_v36")
	if mo == null:
		return
	var monsters: Array = []
	var center := Vector3.ZERO
	for e in list:
		var at: Vector3 = e[1]
		var m: Node3D = mo.spawn_extra(str(e[0]), at)
		m.home = at
		m.state = "chasse"
		monsters.append(m)
		center += at
		if main.combat_v28 != null:
			main.combat_v28.puff(at + Vector3.UP * 0.5, Color(0.85, 0.8, 0.7))
	center /= maxf(1.0, float(list.size()))
	_fight = {"where": where, "monsters": monsters, "center": center, "done": done_text}


func _end_fight() -> void:
	if _fight.is_empty():
		return
	var mo: Node = main.get("monstres_v36")
	for m in _fight["monsters"]:
		if is_instance_valid(m):
			if mo != null:
				mo.monsters.erase(m)
			(m as Node).queue_free()
	_fight = {}


func fight_active() -> bool:
	return not _fight.is_empty()


func _tick_fight() -> void:
	if _fight.is_empty():
		return
	var alive: int = 0
	for m in _fight["monsters"]:
		if is_instance_valid(m) and str(m.get("state")) != "mort":
			alive += 1
	var p: Vector3 = main._player_pos_v27()
	if alive == 0:
		var where: String = str(_fight["where"])
		var t: String = str(_fight["done"])
		_fight = {}
		main.jingle("victoire")
		_say(t, 7.0)
		if where == "mare":
			_close_vanne()
		return
	if p.distance_to(_fight["center"]) > 70.0:
		_end_fight()


func _close_vanne() -> void:
	for i in range(_vanne_gears.size()):
		var g: Node3D = _vanne_gears[i]
		create_tween().tween_property(g, "rotation:y", g.rotation.y - (TAU * 1.5 if i % 2 == 0 else -TAU * 2.5), 8.0).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(_vanne_gate, "position:y", _vanne_gate_y, 6.0).set_trans(Tween.TRANS_SINE)
	if _pond_disc != null:
		create_tween().tween_property(_pond_disc, "position:y", _pond_y0, 20.0).set_trans(Tween.TRANS_SINE)


## Les combats de la grande enquête au grand air (les spectres de la mare).
func hostile_zone(p: Vector3) -> bool:
	return not _fight.is_empty() and str(_fight["where"]) == "mare" and p.distance_to(_fight["center"]) < 60.0


## Évanoui dans un sanctuaire : on se réveille à son entrée (dehors).
func respawn_here(p: Vector3) -> bool:
	if p.y > -40.0:
		return false
	var inside_tomb: bool = Vector2(p.x - TOMB_IN.x, p.z - TOMB_IN.z).length() < 40.0 and absf(p.y - TOMB_IN.y) < 15.0
	var inside_berg: bool = Vector2(p.x - BERG_IN.x, p.z - BERG_IN.z).length() < 40.0 and absf(p.y - BERG_IN.y) < 15.0
	if not inside_tomb and not inside_berg:
		return false
	_end_fight()
	if inside_tomb:
		main.place_player_v35(tomb_door_xf * Vector3(0, 0.15, 3.5), tomb_door_xf.basis * Vector3(0, 0, 1))
		main._show_message_v28("Vous vous êtes évanoui… Un caravanier de passage vous a tiré hors du tombeau et vous a donné à boire.")
	else:
		main.place_player_v35(berg_xf * Vector3(0, 0.2, 3.5), berg_xf.basis * Vector3(0, 0, 1))
		main._show_message_v28("Vous vous êtes évanoui… Un berger vous a ramené à l'air libre, devant la Bergerie du Vent.")
	var hero: Node = main.get("hero_v28")
	if hero != null:
		hero.hp = hero.HP_MAX
		hero.stamina = hero.STAMINA_MAX
		hero.state = "sol"
		hero.health_changed.emit(hero.hp, hero.HP_MAX)
	main.donjon_v35.update_inside(true)
	return true


# =================================================================== vie

func _process(delta: float) -> void:
	if main == null or not bool(main.game_started):
		return
	_clock += delta
	var p: Vector3 = main._player_pos_v27()
	# les sanctuaires ne se dessinent que quand on y est
	var under: bool = p.y < -40.0
	if _tomb_root != null:
		_tomb_root.visible = under and Vector2(p.x - TOMB_IN.x, p.z - TOMB_IN.z).length() < 60.0
	if _berg_root != null:
		_berg_root.visible = under and Vector2(p.x - BERG_IN.x, p.z - BERG_IN.z).length() < 60.0
	# les sceaux posés tournent doucement
	for n in [_tomb_seal, _berg_seal, _pond_seal]:
		if n != null and (n as Node3D).visible:
			(n as Node3D).rotate_y(delta * 0.8)
	# les étoiles des bornes s'allument la nuit
	var night: bool = moon()
	if int(night) != _night_was:
		_night_was = int(night)
		for b in _beacon_lights:
			(b[1] as StandardMaterial3D).emission_energy_multiplier = 3.0 if night else 0.0
			if not night:
				(b[0] as OmniLight3D).light_energy = 0.0
	if night:
		for i in range(_beacon_lights.size()):
			var l: OmniLight3D = _beacon_lights[i][0]
			l.light_energy = 1.4 + sin(_clock * 2.0 + i * 1.3) * 0.25
	# la pierre de la mare : son croissant luit à la lune quand l'eau est basse
	if _moon_stone_glow != null:
		var want: float = 3.0 if night and bool(state["vanne"]) and not bool(state["sceau_brumes"]) else (0.6 if night else 0.0)
		_moon_stone_glow.emission_energy_multiplier = lerpf(_moon_stone_glow.emission_energy_multiplier, want, clampf(delta * 1.5, 0.0, 1.0))
		_pond_seal.visible = night and bool(state["vanne"]) and not bool(state["sceau_brumes"])
	_tick_fight()


# =================================================================== état

func apply_state() -> void:
	_place_rings(false)
	_place_wheels(false)
	if _tomb_slab != null:
		_tomb_slab.position.y = _tomb_slab_y - (4.8 if bool(state["tombeau"]) else 0.0)
		var cb: Node = _tomb_slab.get_node_or_null("Collision")
		if cb != null:
			(cb as StaticBody3D).collision_layer = 0 if bool(state["tombeau"]) else 1
	if _tomb_seal != null:
		_tomb_seal.visible = not bool(state["sceau_sables"])
	if _brambles != null:
		for c2 in _brambles.get_children():
			if c2 is MeshInstance3D:
				(c2 as Node3D).visible = not bool(state["ronces"])
				(c2 as Node3D).scale = Vector3.ONE
		if _bramble_body != null:
			_bramble_body.disabled = bool(state["ronces"])
	if _berg_door != null:
		_berg_door.global_position = BERG_IN + Vector3(3.9 if bool(state["porte_bergerie"]) else 0.0, 1.85, -15.55)
		_berg_door.rotation.z = -TAU * 0.6 if bool(state["porte_bergerie"]) else 0.0
	if _berg_seal != null:
		_berg_seal.visible = not bool(state["sceau_airain"])
	for s in _statues:
		(s as Node3D).visible = not bool(state["sceau_airain"])
	if _vanne_gate != null:
		_vanne_gate.position.y = _vanne_gate_y + (1.5 if bool(state["vanne"]) and not bool(state["sceau_brumes"]) else 0.0)
	if _pond_disc != null:
		_pond_disc.position.y = _pond_y0 - (1.45 if bool(state["vanne"]) and not bool(state["sceau_brumes"]) else 0.0)
	for a in _figure_arms:
		(a[0] as Node3D).rotation.z = float(a[1]) * (0.9 if bool(state["sceau_embruns"]) else -0.2)
	if _figure_glow != null:
		_figure_glow.light_energy = 0.6 if bool(state["sceau_embruns"]) else 0.0
	if _shell_lid != null:
		_shell_lid.rotation.x = -1.3 if bool(state["sceau_embruns"]) else 0.0
	# la porte
	for n in _door_seals:
		if is_instance_valid(n):
			(n as Node).queue_free()
	_door_seals.clear()
	_show_door_void(bool(state["porte_ouverte"]))
	if ile.door_mobile != null:
		ile.door_mobile.position.y = -19.0 if bool(state["porte_ouverte"]) else 0.0
		if bool(state["porte_ouverte"]):
			for s2 in ["airain", "embruns", "sables", "brumes"]:
				_door_seal(s2)
			_disable_leaves()
			ile.door_glow.emission_energy_multiplier = 4.0
		else:
			ile.door_glow.emission_energy_multiplier = 0.9
			for leaf in ile.door_leaves:
				for c3 in (leaf as Node).get_children():
					if c3 is StaticBody3D:
						(c3 as StaticBody3D).collision_layer = 1


func trouvailles() -> Dictionary:
	var t := {}
	for k in ["sceau_sables", "sceau_airain", "sceau_brumes", "sceau_embruns", "journal_lu", "porte_ouverte"]:
		t[k] = 1 if bool(state[k]) else 0
	t["tombeau_dune"] = 1 if bool(state["visite_tombeau"]) else 0
	t["bergerie_vent"] = 1 if bool(state["visite_bergerie"]) else 0
	return t


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	_end_fight()
	_busy = false
	state = _defaults()
	for k in state:
		if not d.has(k):
			continue
		if state[k] is Array:
			var a: Variant = d[k]
			if a is Array and (a as Array).size() == (state[k] as Array).size():
				var out: Array = []
				for v in a:
					out.append(int(v))
				state[k] = out
		else:
			state[k] = bool(d[k])
	apply_state()
