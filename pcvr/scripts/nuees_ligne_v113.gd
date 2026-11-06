extends Node3D
## V113 : la Ligne des Nuées. Du Belvédère de la Grande Colonne (70 m au-dessus de la Place) à la Gare
## des Nuées (sur l'île flottante, 130 m plus haut) :
##  - le quai du Belvédère : une plate-forme ronde qui prolonge le Belvédère (la balustrade s'ouvre),
##    une passerelle, des garde-corps de verre, la porte palière (une grille de verre qui coulisse) ;
##  - la cage : un tube de verre cerclé d'acier blanc, tenu à la couronne de la Colonne par des
##    haubans ; dans la roche de l'île, un puits clair éclairé d'anneaux de lumière ;
##  - la CAPSULE : une cabine ronde de verre et de composite blanc, qu'on peut parcourir à pied ; on y
##    entre, on appuie sur le bouton (E / gâchette), les portes se ferment, ça plane ! Le joueur est
##    porté par la capsule (sa hauteur suit celle du plancher, au PC comme en VR), comme dans la
##    cabine de la Colonne.
## Les points (repère monde) : foot (le centre, au plancher du quai du Belvédère), top (le centre, au
## plancher de la Gare des Nuées).

const Ile = preload("res://scripts/ile_nuees_v113.gd")
const R_TUBE: float = 2.3                # la cage de verre
const R_CAP: float = 1.9                 # la capsule
const H_CAP: float = 2.8
const R_QUAI: float = 4.8                # le quai rond du Belvédère
const DUREE: float = 22.0                # la montée (s)

var main: Node
var kit
var foot := Vector3.ZERO
var top := Vector3.ZERO
var to_col := Vector3.ZERO               # la direction de la capsule vers la Colonne (la porte)
var capsule: Node3D
var cap_body: StaticBody3D
var door_l: Node3D
var door_r: Node3D
var door_col: CollisionShape3D
var gates: Array = []                    # [grille, collision, position fermée, en haut ?, côté]
var cap_light: OmniLight3D
var cap_ring: StandardMaterial3D
var ylow: float = 0.0
var yhigh: float = 0.0
var t: float = 0.0
var target: float = 0.0
var moving: bool = false
var doors_open: float = 1.0
var rides: int = 0
var quai_bas := Vector3.ZERO             # devant la porte, en bas (sur le quai du Belvédère)
var quai_haut := Vector3.ZERO            # devant la porte, en haut (sur le quai de la Gare)
var _clock: float = 0.0
var _pc: bool = true


func T(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


## Bâtit la ligne. nkit : la boîte à outils des Nuées ; belv : le plancher du Belvédère (centre).
func build(main_node: Node, nkit, belv: Vector3, ile: Node3D, pc: bool) -> void:
	main = main_node
	kit = nkit
	_pc = pc
	var tl: Vector2 = Ile.tube_l()
	foot = Vector3(Ile.CENTER.x + tl.x, belv.y, Ile.CENTER.z + tl.y)
	var gy: float = Ile.Y0 + ile.top_local(tl.x, tl.y)
	top = Vector3(foot.x, gy, foot.z)
	to_col = Ile.tube_dir_to_column()
	ylow = foot.y + 0.02
	yhigh = top.y + 0.02
	quai_bas = foot + to_col * (R_TUBE + 1.4)
	quai_haut = top + to_col * (R_TUBE + 1.6)
	_quai(belv)
	_cage(ile, nkit)
	_capsule()
	_gates()


# =================================================================== le quai du Belvédère

func _quai(belv: Vector3) -> void:
	var c: Vector3 = foot
	# le plancher : un disque de dalles claires sur une sous-face de béton blanc, une passerelle
	kit.cyl(Transform3D(Basis(), c + Vector3.DOWN * 0.5), R_QUAI, R_QUAI, 0.5, "dalle113", 40, true, 3.0)
	kit.cyl(Transform3D(Basis(), c + Vector3.DOWN * 1.3), R_QUAI - 0.6, R_QUAI, 0.8, "beton113", 40, false, 2.4)
	kit.disc(Transform3D(Basis(Vector3.RIGHT, PI), c + Vector3.DOWN * 1.3), R_QUAI - 0.6, "beton113", 40)
	var col := StaticBody3D.new()
	col.name = "Quai_nuees_col"
	add_child(col)
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = R_QUAI
	sh.height = 0.5
	cs.shape = sh
	col.add_child(cs)
	col.global_position = c + Vector3.DOWN * 0.25
	var bs := Basis.looking_at(to_col, Vector3.UP)
	var mid: Vector3 = c + to_col * (R_QUAI + 0.2)
	kit.box(Transform3D(bs, mid + Vector3.DOWN * 0.25), Vector3(5.6, 0.5, 3.4), "dalle113", 3.0)
	kit.box(Transform3D(bs, mid + Vector3.DOWN * 0.9), Vector3(5.2, 0.8, 3.0), "beton113", 2.4, 63 - 4)
	kit.col_box(Transform3D(bs, mid + Vector3.DOWN * 0.25), Vector3(5.6, 0.5, 3.4))
	# les garde-corps de verre tout autour du quai (sauf du côté de la passerelle) et le long d'elle
	var a_col: float = atan2(to_col.z, to_col.x)
	var n: int = 20
	for k in range(n):
		var a0: float = a_col + TAU * k / n
		var a1: float = a_col + TAU * (k + 1) / n
		var am: float = (a0 + a1) * 0.5
		if absf(wrapf(am - a_col, -PI, PI)) < 0.62:
			continue
		var p0: Vector3 = c + Vector3(cos(a0), 0, sin(a0)) * (R_QUAI - 0.15)
		var p1: Vector3 = c + Vector3(cos(a1), 0, sin(a1)) * (R_QUAI - 0.15)
		kit.glass_rail113(p0, p1, 1.15)
	var side: Vector3 = to_col.cross(Vector3.UP).normalized()
	for s in [-1.0, 1.0]:
		var a: Vector3 = c + to_col * (R_QUAI * cos(0.62)) + side * s * (R_QUAI * sin(0.62) - 0.15)
		var b: Vector3 = mid + to_col * 1.6 + side * s * 2.7
		kit.glass_rail113(a, b, 1.15)
	# l'enseigne de la ligne, sur un totem blanc, à l'entrée de la passerelle
	kit.totem113(mid + to_col * 1.2 + side * 3.6, atan2(to_col.x, to_col.z), "ligne")
	# deux bancs, des lampes
	for s2 in [-1.0, 1.0]:
		var bp: Vector3 = c + Vector3(cos(a_col + PI + s2 * 1.2), 0, sin(a_col + PI + s2 * 1.2)) * (R_QUAI - 1.1)
		kit.bench113(Transform3D(Basis.looking_at(c - bp, Vector3.UP).rotated(Vector3.UP, PI), bp), 1.8)


# =================================================================== la cage

func _cage(ile: Node3D, nkit) -> void:
	var c: Vector3 = foot
	var tl: Vector2 = Ile.tube_l()
	var rr: float = float(ile.coast_radius(atan2(tl.y, tl.x)))
	var rock: float = float(ile.under_y(tl.length(), rr)) + 4.0
	var y0: float = foot.y + H_CAP + 0.3
	# le tube de verre (de la capsule au repos jusqu'à la roche), ses cerclages, ses quatre rails
	nkit.cyl(Transform3D(Basis(), Vector3(c.x, y0, c.z)), R_TUBE, R_TUBE, rock - y0, "verre113", 24, false, 3.0)
	var y: float = y0
	while y < rock:
		nkit.ring(Transform3D(Basis(), Vector3(c.x, y, c.z)), R_TUBE - 0.02, R_TUBE + 0.16, 0.22, "composite113", 24)
		y += 4.0
	for k in range(4):
		var a: float = TAU * k / 4.0 + PI * 0.25
		var q: Vector3 = Vector3(c.x, 0, c.z) + Vector3(cos(a), 0, sin(a)) * (R_TUBE + 0.12)
		nkit.cyl(Transform3D(Basis(), Vector3(q.x, foot.y - 0.5, q.z)), 0.1, 0.1, top.y + 5.0 - foot.y, "acier113", 6, false)
	# le pied de la cage sur le quai (un anneau d'acier, la porte palière)
	nkit.ring(Transform3D(Basis(), foot), R_TUBE - 0.05, R_TUBE + 0.35, 0.12, "acier113", 24)
	nkit.ring(Transform3D(Basis(), foot + Vector3.UP * (H_CAP + 0.3)), R_TUBE - 0.05, R_TUBE + 0.3, 0.3, "composite113", 24)
	# les haubans : trois câbles qui tiennent la cage à la couronne de la Colonne
	var colc: Vector3 = foot + to_col * Ile.TUBE_OFF
	for e in [[20.0, -0.5], [34.0, 0.0], [20.0, 0.5]]:
		var at: Vector3 = Vector3(c.x, foot.y + float(e[0]) + 14.0, c.z)
		var side: Vector3 = to_col.cross(Vector3.UP).normalized()
		var to: Vector3 = Vector3(colc.x, foot.y + float(e[0]), colc.z) - to_col * 7.0 + side * float(e[1]) * 4.0
		nkit.beam(at, to, 0.07, "acier113")
	# dans la roche : un puits clair, des anneaux de lumière (on les voit de la capsule)
	var lin_y0: float = rock - 6.0
	nkit.cyl(Transform3D(Basis(Vector3.RIGHT, PI), Vector3(c.x, top.y - 0.3, c.z)), R_TUBE + 0.5, R_TUBE + 0.5, top.y - 0.3 - lin_y0, "beton113_gris", 24, false, 3.0)
	var y2: float = lin_y0 + 2.0
	while y2 < top.y - 1.0:
		nkit.ring(Transform3D(Basis(), Vector3(c.x, y2, c.z)), R_TUBE + 0.3, R_TUBE + 0.48, 0.18, "led113", 24)
		y2 += 6.0
	# en haut, la cage dépasse le plancher de la Gare (le verre, le toit de la cage)
	nkit.cyl(Transform3D(Basis(), top + Vector3.UP * (H_CAP + 0.3)), R_TUBE, R_TUBE, 2.4, "verre113", 24, false, 3.0)
	nkit.cyl(Transform3D(Basis(), top + Vector3.UP * (H_CAP + 2.7)), R_TUBE + 0.4, R_TUBE + 0.4, 0.4, "composite113", 24, true)
	nkit.ring(Transform3D(Basis(), top), R_TUBE - 0.05, R_TUBE + 0.35, 0.12, "acier113", 24)


# =================================================================== la capsule

func _capsule() -> void:
	capsule = Node3D.new()
	capsule.name = "Capsule_nuees"
	add_child(capsule)
	capsule.global_position = Vector3(foot.x, ylow, foot.z)
	capsule.global_basis = Basis.looking_at(-to_col, Vector3.UP)
	var ck = load("res://scripts/nuees_kit_v113.gd").new()
	ck.setup(capsule, main.get("temps_v56") if main != null else null)
	ck.main = main
	ck.pc = _pc
	cap_body = ck.body
	var r: float = R_CAP
	# repère de la capsule : la porte regarde +Z (vers la Colonne)
	ck.cyl(T(0, -0.3, 0), r + 0.1, r + 0.1, 0.3, "composite113", 24)
	ck.disc(T(0, 0.02, 0), r, "bois113", 24, 1.5)
	ck.ring(T(0, 0.0, 0), r - 0.08, r + 0.1, 0.05, "acier113", 24)
	ck.cyl(T(0, H_CAP, 0), r + 0.1, r + 0.1, 0.22, "composite113", 24)
	ck.dome76(T(0, H_CAP + 0.22, 0), r + 0.1, 0.45, "composite113", 24, 4)
	ck.ring(T(0, H_CAP - 0.06, 0), r - 0.5, r - 0.35, 0.03, "led113", 24)
	ck.cyl(T(0, H_CAP - 0.04, 0), 0.6, 0.6, 0.04, "led113", 16)
	var body_col := CollisionShape3D.new()
	var floor_shape := CylinderShape3D.new()
	floor_shape.radius = r
	floor_shape.height = 0.3
	body_col.shape = floor_shape
	body_col.position = Vector3(0, -0.15, 0)
	cap_body.add_child(body_col)
	var roof_col := CollisionShape3D.new()
	var roof_shape := CylinderShape3D.new()
	roof_shape.radius = r
	roof_shape.height = 0.2
	roof_col.shape = roof_shape
	roof_col.position = Vector3(0, H_CAP + 0.1, 0)
	cap_body.add_child(roof_col)
	# les vitres courbes (la porte : devant, +Z), les montants blancs, la main courante
	var seg: int = 12
	for k in range(seg):
		var a0: float = TAU * k / seg + PI * 0.5 - PI / seg
		var a1: float = a0 + TAU / seg
		var am: float = (a0 + a1) * 0.5
		var p0 := Vector3(cos(a0), 0, sin(a0)) * r
		var p1 := Vector3(cos(a1), 0, sin(a1)) * r
		ck.cyl(Transform3D(Basis(), p0), 0.045, 0.045, H_CAP, "composite113", 6, false)
		if absf(wrapf(am - PI * 0.5, -PI, PI)) < 0.6:
			continue
		var mid: Vector3 = (p0 + p1) * 0.5
		var w: float = p0.distance_to(p1)
		var bs := Basis.looking_at(-mid.normalized(), Vector3.UP)
		ck.quad(Transform3D(bs, mid + Vector3.UP * (H_CAP * 0.5)), w, H_CAP - 0.1, "verre113", Vector2(0, 0), Vector2(1, 1), true)
		ck.box(Transform3D(bs, mid * 0.94 + Vector3.UP * 1.0), Vector3(w, 0.05, 0.05), "acier113", 1.0)
		ck.col_box(Transform3D(bs, mid + Vector3.UP * (H_CAP * 0.5)), Vector3(w, H_CAP, 0.1))
	# la banquette (au fond) et la colonne de commande (à droite de la porte)
	ck.box(T(0, 0.24, -r + 0.45), Vector3(1.8, 0.48, 0.5), "composite113", 1.0)
	ck.box(T(0, 0.5, -r + 0.45), Vector3(1.7, 0.06, 0.46), "bois113", 1.0)
	ck.col_box(T(0, 0.25, -r + 0.45), Vector3(1.8, 0.5, 0.5))
	var px: Transform3D = Transform3D(Basis(Vector3.UP, -PI * 0.35), Vector3(r - 0.55, 0, 0.75))
	ck.box(px * T(0, 0.6, 0), Vector3(0.36, 1.2, 0.2), "composite113", 1.0)
	ck.box(px * T(0, 1.22, 0.04), Vector3(0.4, 0.05, 0.3), "acier113", 1.0)
	ck.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), px * Vector3(0, 1.0, 0.11)), 0.06, 0.06, 0.03, "anneau113", 12)
	ck.commit()
	door_l = _door_leaf(ck, -1.0)
	door_r = _door_leaf(ck, 1.0)
	door_col = CollisionShape3D.new()
	var dshape := BoxShape3D.new()
	dshape.size = Vector3(1.8, H_CAP, 0.12)
	door_col.shape = dshape
	door_col.position = Vector3(0, H_CAP * 0.5, r * cos(0.55))
	door_col.disabled = true
	cap_body.add_child(door_col)
	cap_light = OmniLight3D.new()
	cap_light.light_color = Color(0.92, 0.96, 1.0)
	cap_light.light_energy = 1.0
	cap_light.omni_range = 4.5
	cap_light.shadow_enabled = false
	cap_light.distance_fade_enabled = true
	cap_light.distance_fade_begin = 60.0
	cap_light.distance_fade_length = 10.0
	cap_light.position = Vector3(0, H_CAP - 0.4, 0)
	capsule.add_child(cap_light)
	for ch in capsule.get_children():
		if ch is GeometryInstance3D:
			(ch as GeometryInstance3D).visibility_range_end = 1200.0


func _door_leaf(ck, s: float) -> Node3D:
	var n := MeshInstance3D.new()
	n.name = "Porte_capsule"
	var saved: Dictionary = ck.batch
	ck.batch = {}
	ck.quad(T(0, H_CAP * 0.5, 0), 0.9, H_CAP - 0.08, "verre113", Vector2(0, 0), Vector2(1, 1), true)
	ck.box(T(0, H_CAP - 0.03, 0), Vector3(0.9, 0.06, 0.05), "composite113", 1.0)
	ck.box(T(0, 0.04, 0), Vector3(0.9, 0.08, 0.05), "composite113", 1.0)
	for x in [-0.43, 0.43]:
		ck.box(T(x, H_CAP * 0.5, 0), Vector3(0.05, H_CAP, 0.05), "acier113", 1.0)
	var mesh := ArrayMesh.new()
	for k in ck.batch:
		var st: SurfaceTool = ck.batch[k]
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, ck.mat(str(k)))
	ck.batch = saved
	n.mesh = mesh
	capsule.add_child(n)
	n.set_meta("s", s)
	n.position = Vector3(s * 0.45, 0, R_CAP * cos(0.55))
	return n


## Les deux portes palières (une grille de verre qui coulisse) : fermées quand la capsule n'est pas
## là (on ne tombe pas dans la cage).
func _gates() -> void:
	var side: Vector3 = to_col.cross(Vector3.UP).normalized()
	for lv in [[foot, false], [top, true]]:
		var g := MeshInstance3D.new()
		g.name = "Porte_palier_nuees"
		var nk = load("res://scripts/nuees_kit_v113.gd").new()
		nk.setup(g, null)
		var saved: Dictionary = nk.batch
		nk.quad(T(0, 1.45, 0), 2.2, 2.8, "verre113", Vector2(0, 0), Vector2(1, 1), true)
		for x in [-1.1, 1.1]:
			nk.box(T(x, 1.45, 0), Vector3(0.06, 2.9, 0.06), "acier113", 1.0)
		nk.box(T(0, 2.88, 0), Vector3(2.3, 0.06, 0.06), "acier113", 1.0)
		nk.box(T(0, 1.0, 0.03), Vector3(2.2, 0.05, 0.03), "acier113", 1.0)
		var mesh := ArrayMesh.new()
		for k2 in nk.batch:
			var st: SurfaceTool = nk.batch[k2]
			st.commit(mesh)
			mesh.surface_set_material(mesh.get_surface_count() - 1, nk.mat(str(k2)))
		nk.batch = saved
		g.mesh = mesh
		add_child(g)
		var at: Vector3 = (lv[0] as Vector3) + to_col * (R_TUBE + 0.15)
		g.global_transform = Transform3D(Basis.looking_at(-to_col, Vector3.UP), at)
		var b := StaticBody3D.new()
		b.name = "Porte_palier_col"
		add_child(b)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(2.4, 3.0, 0.15)
		cs.shape = sh
		b.add_child(cs)
		b.global_transform = Transform3D(Basis.looking_at(-to_col, Vector3.UP), at + Vector3.UP * 1.5)
		gates.append([g, cs, at, bool(lv[1]), side])


# =================================================================== la conduite

func cabin_y() -> float:
	return lerpf(ylow, yhigh, _ease(t))


static func _ease(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)


func at_top() -> bool:
	return not moving and t > 0.99


func at_bottom() -> bool:
	return not moving and t < 0.01


func inside(p: Vector3) -> bool:
	var cy: float = cabin_y()
	return Vector2(p.x - foot.x, p.z - foot.z).length() < R_CAP - 0.1 and p.y > cy - 0.6 and p.y < cy + H_CAP


## Sur le quai du Belvédère, sa passerelle, ou dans la capsule : on peut marcher ici.
func walkable(p: Vector3) -> bool:
	if inside(p):
		return true
	var l := Vector2(p.x - foot.x, p.z - foot.z)
	if absf(p.y - foot.y) < 3.5 and (l.length() < R_QUAI + 0.5 or (l.dot(Vector2(to_col.x, to_col.z)) > 0.0 and l.dot(Vector2(to_col.x, to_col.z)) < R_QUAI + 3.0 and absf(l.cross(Vector2(to_col.x, to_col.z))) < 3.0)):
		return true
	return false


func go(to_top: bool) -> void:
	if moving:
		return
	target = 1.0 if to_top else 0.0
	if absf(target - t) < 0.01:
		return
	moving = true
	rides += 1
	if main != null and main.has_method("sfx"):
		main.sfx("porte", capsule.global_position + Vector3.UP * 1.5)
	var p: Vector3 = main._player_pos_v27() if main != null else Vector3.ZERO
	if main != null and inside(p):
		main._show_message_v28("Ça plane ! Prochain arrêt : la Gare des Nuées, cent trente mètres plus haut." if to_top else "On redescend ! Prochain arrêt : le Belvédère de la Grande Colonne.")


func _physics_process(delta: float) -> void:
	if capsule == null:
		return
	_clock += delta
	var want_open: float = 0.0 if moving else 1.0
	doors_open = move_toward(doors_open, want_open, delta * 1.5)
	var p_player: Vector3 = main._player_pos_v27() if main != null else Vector3.ZERO
	var y_before: float = cabin_y()
	if moving and doors_open <= 0.0:
		var dir: float = signf(target - t)
		t = clampf(t + dir * delta / DUREE, 0.0, 1.0)
		if (dir > 0.0 and t >= target) or (dir < 0.0 and t <= target):
			t = target
			moving = false
			if main != null and inside(p_player):
				main._show_message_v28("La Gare des Nuées : bienvenue au-dessus des nuages. Bon vent !" if t > 0.5 else "Le Belvédère de la Grande Colonne. Bon vent, et à bientôt là-haut !")
	var y_now: float = cabin_y()
	capsule.global_position = Vector3(foot.x, y_now, foot.z)
	var dy: float = y_now - y_before
	if absf(dy) > 0.00001 and main != null and inside(Vector3(p_player.x, p_player.y - dy, p_player.z)):
		_carry(dy)
	for dl in [door_l, door_r]:
		if dl != null:
			var s: float = float(dl.get_meta("s"))
			dl.position.x = s * (0.45 + 0.8 * doors_open)
	if door_col != null:
		door_col.disabled = doors_open > 0.6
	for gt in gates:
		var opened: bool = at_top() if bool(gt[3]) else at_bottom()
		(gt[1] as CollisionShape3D).disabled = opened
		var gnode: Node3D = gt[0]
		var want: Vector3 = (gt[2] as Vector3) + (gt[4] as Vector3) * (2.2 if opened else 0.0)
		gnode.global_position = gnode.global_position.move_toward(want, delta * 1.8)


func _carry(dy: float) -> void:
	if main.get("xr_active") and main.xr_active:
		main.xr_origin.position.y += dy
		main.vr_body.global_position.y += dy
		if dy > 0.0:
			main.vr_body.velocity.y = maxf(main.vr_body.velocity.y, 0.0)
	else:
		main.pc_body.global_position.y += dy
		main.pc_root.position.y += dy
		if dy > 0.0:
			main.pc_body.velocity.y = maxf(main.pc_body.velocity.y, 0.0)
		if main.get("hero_v28") != null:
			main.hero_v28.fall_top = main.pc_body.global_position.y
	main.last_ok_v29.clear()


func set_night(k: float) -> void:
	if cap_light != null:
		cap_light.light_energy = lerpf(0.8, 1.6, k)


# =================================================================== les interactions

func register(d: Node, owner_node: Node) -> void:
	var me = self
	var ia := func(it: Dictionary) -> void:
		d._interactions.append(it)
		if owner_node != null and owner_node.get("_interactions") != null:
			owner_node._interactions.append(it)
	ia.call({"id": "nu_capsule_monter", "pos": Vector3(foot.x, ylow + 1.0, foot.z), "radius": 1.9, "text": "E : appuyer sur le bouton (monter à la Cité des Nuées)",
		"vr": "Gâchette : appuyer sur le bouton (monter à la Cité des Nuées)", "call": func(): me.go(true), "when": func(): return me.at_bottom() and me.inside(me.main._player_pos_v27())})
	ia.call({"id": "nu_capsule_descendre", "pos": Vector3(foot.x, yhigh + 1.0, foot.z), "radius": 1.9, "text": "E : appuyer sur le bouton (redescendre au Belvédère)",
		"vr": "Gâchette : appuyer sur le bouton (redescendre au Belvédère)", "call": func(): me.go(false), "when": func(): return me.at_top() and me.inside(me.main._player_pos_v27())})
	ia.call({"id": "nu_appel_bas", "pos": quai_bas + Vector3.UP * 1.0, "radius": 1.8, "text": "E : appeler la capsule",
		"vr": "Gâchette : appeler la capsule", "call": func(): me.go(false), "when": func(): return not me.at_bottom() and not me.moving})
	ia.call({"id": "nu_appel_haut", "pos": quai_haut + Vector3.UP * 1.0, "radius": 1.8, "text": "E : appeler la capsule",
		"vr": "Gâchette : appeler la capsule", "call": func(): me.go(true), "when": func(): return not me.at_top() and not me.moving})
