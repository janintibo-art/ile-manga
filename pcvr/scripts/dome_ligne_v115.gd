extends Node3D
## V115 : la Ligne du Dôme d'Azur (le Funiculaire d'Azur). De la Gare des Strates jusqu'au Grand Dôme,
## au fond de la Fosse d'Azur :
##  - aux Strates, la CAGE DE LAITON (à côté de la Colonne Renversée) : on y entre, on tire le levier
##    (E / gâchette), les grilles se ferment, la cage s'enfonce dans le sol… (un fondu au noir) ;
##  - au fond du tunnel du canyon, la BULLE (une cabine de verre et de nacre, suspendue à son rail par
##    un bras, qui reste toujours de niveau) sort de la falaise et descend dans son long tube de verre,
##    sur ses pylônes, jusqu'à la GARE D'AZUR (le joueur est porté par la bulle, au PC et en VR) ;
##  - pour remonter : on appuie sur le bouton de la bulle, à quai ; elle remonte jusqu'au tunnel, et
##    l'on reparaît dans la cage, aux Strates. La bulle redescend seule à la Gare.
## Les portes palières de la Gare (du verre le long du quai) s'ouvrent quand la bulle est à quai.

const F = preload("res://scripts/fosse_azur_v115.gd")
const D = preload("res://scripts/dome_azur_v115.gd")
const SR = preload("res://scripts/strates_roche_v114.gd")
const CAB_L: float = 6.0
const CAB_W: float = 3.0
const CAB_H: float = 2.6
const STOP_R: float = 63.5
const DUREE: float = 32.0
const CAGE_R: float = 1.6
const CAGE_H: float = 3.3

var main: Node
var dome: Node3D
var pc: bool = true
var path: Array = []                     # Vector3 : le plancher de la bulle (la Gare, … , le fond du tunnel)
var path_len: float = 0.0
var t: float = 0.0                       # 0 : à la Gare ; 1 : au fond du tunnel
var target: float = 0.0
var moving: bool = false
var busy: bool = false
var carrying: bool = false
var rides: int = 0
var doors_open: float = 1.0
var cabin: Node3D
var cab_body: StaticBody3D
var cab_doors: Array = []                # [Node3D, côté]
var cab_door_col: CollisionShape3D
var psd: Array = []                      # [Node3D, position fermée, direction d'ouverture, collision]
var cage: Node3D
var cage_pos := Vector3.ZERO             # le plancher de la cage (en haut)
var cage_gates: Array = []               # [Node3D, collision, position locale fermée, côté]
var cage_open: float = 1.0
var cage_sink: float = 0.0
var _dl := Vector3.ZERO
var _sd := Vector3.ZERO


func T(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


func build(main_node: Node, dome_node: Node3D, strates_node: Node3D, high_quality: bool) -> void:
	main = main_node
	dome = dome_node
	pc = high_quality
	_dl = D.dirv(D.A_GARE)
	_sd = _dl.cross(Vector3.UP).normalized()
	var o: Vector3 = D.P(0, 0)
	path = [D.LR(STOP_R, 0.0, F.AXE_BAS - 1.5), o + _dl * F.L_FLAT + Vector3.UP * (F.AXE_BAS - 1.5),
		o + _dl * F.L_PORTAL + Vector3.UP * (F.AXE_HAUT - 1.5), o + _dl * 214.0 + Vector3.UP * (F.AXE_HAUT - 1.5)]
	path_len = 0.0
	for k in range(path.size() - 1):
		path_len += (path[k] as Vector3).distance_to(path[k + 1])
	_cabine()
	_portes_palieres()
	cage_pos = strates_node.objets.get("ligne_dome", SR.W(0.0, -5.2, SR.F0)) - Vector3(0, 0, 2.4) if strates_node != null else SR.W(0.0, -7.6, SR.F0)
	_cage()
	_apply()


# =================================================================== la bulle

func _cabine() -> void:
	cabin = Node3D.new()
	cabin.name = "Bulle_du_funiculaire"
	add_child(cabin)
	var ck = load("res://scripts/dome_kit_v115.gd").new()
	ck.setup(cabin, main.get("temps_v56") if main != null else null)
	ck.main = main
	ck.pc = pc
	cab_body = ck.body
	var hw: float = CAB_W * 0.5
	var hl: float = CAB_L * 0.5
	# le plancher, le toit (de nacre), les coins arrondis (des montants de titane)
	ck.box(T(0, -0.15, 0), Vector3(CAB_W, 0.3, CAB_L), "nacre115_gris", 1.0)
	ck.box(T(0, 0.01, 0), Vector3(CAB_W - 0.1, 0.02, CAB_L - 0.1), "terrazzo115_bleu", 2.0, 4)
	ck.box(T(0, CAB_H + 0.15, 0), Vector3(CAB_W + 0.1, 0.3, CAB_L + 0.1), "nacre115", 1.0)
	ck.box(T(0, CAB_H - 0.02, 0), Vector3(CAB_W - 0.3, 0.04, CAB_L - 0.4), "led115_blanc", 1.0, 8)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			ck.cyl(T(sx * (hw - 0.1), 0, sz * (hl - 0.1)), 0.12, 0.12, CAB_H, "titane115_clair", 8, false)
	# les vitres : le côté ouest (-X), les deux bouts ; à l'est (+X), deux vitres et la porte au milieu
	ck.quad(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-hw, CAB_H * 0.5 + 0.1, 0)), CAB_L - 0.2, CAB_H - 0.2, "vitre115", Vector2(0, 0), Vector2(1, 1), true)
	for sz2 in [-1.0, 1.0]:
		ck.quad(Transform3D(Basis(), Vector3(0, CAB_H * 0.5 + 0.1, sz2 * hl)), CAB_W - 0.2, CAB_H - 0.2, "vitre115", Vector2(0, 0), Vector2(1, 1), true)
		ck.quad(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(hw, CAB_H * 0.5 + 0.1, sz2 * (hl * 0.5 + 0.45))), hl - 0.9, CAB_H - 0.2, "vitre115", Vector2(0, 0), Vector2(1, 1), true)
	# les collisions des parois
	var cols: Array = [[T(0, -0.15, 0), Vector3(CAB_W, 0.3, CAB_L)], [T(0, CAB_H + 0.15, 0), Vector3(CAB_W, 0.3, CAB_L)],
		[T(-hw, CAB_H * 0.5, 0), Vector3(0.12, CAB_H, CAB_L)], [T(0, CAB_H * 0.5, -hl), Vector3(CAB_W, CAB_H, 0.12)],
		[T(0, CAB_H * 0.5, hl), Vector3(CAB_W, CAB_H, 0.12)], [T(hw, CAB_H * 0.5, -(hl * 0.5 + 0.45)), Vector3(0.12, CAB_H, hl - 0.9)],
		[T(hw, CAB_H * 0.5, hl * 0.5 + 0.45), Vector3(0.12, CAB_H, hl - 0.9)]]
	for c in cols:
		ck.col_box(c[0], c[1])
	# les banquettes (contre la vitre ouest), la barre, le pupitre et son bouton (près de la porte)
	for sz3 in [-1.0, 1.0]:
		ck.box(T(-hw + 0.35, 0.22, sz3 * 1.3), Vector3(0.6, 0.44, 1.8), "nacre115", 1.0)
		ck.box(T(-hw + 0.38, 0.47, sz3 * 1.3), Vector3(0.56, 0.08, 1.7), "tissu115", 1.0)
		ck.col_box(T(-hw + 0.35, 0.25, sz3 * 1.3), Vector3(0.6, 0.5, 1.8))
	ck.cyl(T(0, 0, 0), 0.04, 0.04, CAB_H, "titane115_clair", 6, false)
	ck.box(T(hw - 0.3, 0.6, -1.2), Vector3(0.4, 1.2, 0.3), "nacre115", 1.0)
	ck.ball(T(hw - 0.3, 1.25, -1.2), 0.08, "led115_cyan", 8, 4)
	# le bras et le chariot (en haut, sur le rail)
	var rail_y: float = 1.5 + D.R_FUNI - 0.45
	ck.box(T(0, (CAB_H + rail_y) * 0.5, 0), Vector3(0.22, rail_y - CAB_H, 0.5), "titane115_clair", 1.0)
	ck.box(T(0, rail_y - 0.32, 0), Vector3(0.6, 0.22, 1.6), "titane115", 1.0)
	ck.cyl(Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(0.0, rail_y + 0.05, -0.55)), 0.16, 0.16, 0.5, "titane115_sombre", 10, true)
	ck.cyl(Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(0.0, rail_y + 0.05, 0.55)), 0.16, 0.16, 0.5, "titane115_sombre", 10, true)
	ck.commit()
	# la porte (deux vantaux de verre qui coulissent le long de la bulle)
	for s in [-1.0, 1.0]:
		var dk = load("res://scripts/dome_kit_v115.gd").new()
		var leaf := Node3D.new()
		leaf.name = "Porte_bulle"
		cabin.add_child(leaf)
		dk.setup(leaf, null)
		dk.quad(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, CAB_H * 0.5 + 0.05, 0)), 0.9, CAB_H - 0.15, "vitre115_fume", Vector2(0, 0), Vector2(1, 1), true)
		dk.box(T(0, CAB_H - 0.05, 0), Vector3(0.06, 0.08, 0.92), "titane115_clair", 1.0)
		dk.box(T(0, 0.04, 0), Vector3(0.06, 0.08, 0.92), "titane115_clair", 1.0)
		dk.box(T(0, CAB_H * 0.5, -s * 0.44), Vector3(0.06, CAB_H - 0.1, 0.05), "titane115_clair", 1.0)
		dk.commit()
		leaf.position = Vector3(hw + 0.02, 0, s * 0.45)
		cab_doors.append([leaf, s])
	cab_door_col = CollisionShape3D.new()
	var ds := BoxShape3D.new()
	ds.size = Vector3(0.12, CAB_H, 1.8)
	cab_door_col.shape = ds
	cab_door_col.position = Vector3(hw, CAB_H * 0.5, 0)
	cab_door_col.disabled = true
	cab_body.add_child(cab_door_col)
	var l := OmniLight3D.new()
	l.light_color = Color(0.9, 0.97, 1.0)
	l.light_energy = 0.9
	l.omni_range = 6.0
	l.position = Vector3(0, CAB_H - 0.3, 0)
	cabin.add_child(l)


## Les portes palières de la Gare : deux vantaux de verre, sur le bord du quai, en face de la porte de
## la bulle (ils glissent le long du quai quand la bulle est là).
func _portes_palieres() -> void:
	var bd := Basis.looking_at(_dl, Vector3.UP)
	for s in [-1.0, 1.0]:
		var n := Node3D.new()
		n.name = "Porte_paliere"
		add_child(n)
		var pk = load("res://scripts/dome_kit_v115.gd").new()
		pk.setup(n, null)
		pk.box(T(0, 1.1, 0), Vector3(0.05, 2.2, 0.98), "vitre115", 1.0)
		pk.box(T(0, 2.22, 0), Vector3(0.1, 0.06, 1.0), "titane115_clair", 1.0)
		pk.box(T(0, 1.1, s * 0.48), Vector3(0.08, 2.2, 0.04), "led115_ambre", 1.0)
		pk.commit()
		var closed: Vector3 = D.LR(STOP_R - s * 0.5, 1.65, 1.0)
		n.global_transform = Transform3D(bd, closed)
		var b := StaticBody3D.new()
		add_child(b)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(0.12, 2.2, 1.0)
		cs.shape = sh
		b.add_child(cs)
		b.global_transform = Transform3D(bd, closed + Vector3.UP * 1.1)
		psd.append([n, closed, -_dl * s, cs, b])


# =================================================================== la cage de laiton (aux Strates)

func _cage() -> void:
	cage = Node3D.new()
	cage.name = "Cage_du_Dome"
	add_child(cage)
	cage.global_position = cage_pos
	var ck = load("res://scripts/strates_kit_v114.gd").new()
	ck.setup(cage, main.get("temps_v56") if main != null else null)
	ck.main = main
	ck.pc = pc
	var r: float = CAGE_R
	ck.cyl(T(0, -0.2, 0), r + 0.15, r + 0.15, 0.2, "laiton112_vieux", 24)
	ck.disc(T(0, 0.01, 0), r, "bois112", 24, 1.5)
	ck.ring(T(0, 0.0, 0), r - 0.05, r + 0.15, 0.25, "laiton112", 24)
	ck.ring(T(0, CAGE_H - 0.2, 0), r - 0.05, r + 0.15, 0.25, "laiton112", 24)
	ck.dome76(T(0, CAGE_H + 0.05, 0), r + 0.15, 0.9, "verdigris112", 16, 5)
	ck.ball(T(0, CAGE_H + 1.0, 0), 0.14, "or112", 8, 4)
	ck.cyl(T(0, CAGE_H, 0), r + 0.15, r + 0.15, 0.06, "laiton112_vieux", 24, true)
	ck.ball(T(0, CAGE_H - 0.4, 0), 0.22, "lampe114", 10, 6)
	var seg: int = 14
	for k in range(seg):
		var a0: float = TAU * k / seg + PI * 0.5 - PI / seg
		var a1: float = a0 + TAU / seg
		var am: float = (a0 + a1) * 0.5
		var p0 := Vector3(cos(a0), 0, sin(a0)) * r
		var p1 := Vector3(cos(a1), 0, sin(a1)) * r
		ck.cyl(Transform3D(Basis(), p0), 0.04, 0.04, CAGE_H, "laiton112", 6, false)
		if absf(wrapf(am - PI * 0.5, -PI, PI)) < 0.55:
			continue
		var mid: Vector3 = (p0 + p1) * 0.5
		var w: float = p0.distance_to(p1)
		var bs := Basis.looking_at(-mid.normalized(), Vector3.UP)
		for k2 in range(3):
			ck.box(Transform3D(bs, mid + Vector3.UP * (0.4 + k2 * 1.1)), Vector3(w, 0.04, 0.04), "laiton112", 1.0)
		ck.quad(Transform3D(bs, mid + Vector3.UP * (CAGE_H * 0.5)), w, CAGE_H - 0.3, "vitre114", Vector2(0, 0), Vector2(1, 1), true)
		ck.col_box(Transform3D(bs, mid + Vector3.UP * (CAGE_H * 0.5)), Vector3(w, CAGE_H, 0.1))
	# le plancher, le toit ; le levier (au fond), l'enseigne au-dessus de la porte
	ck.col_box(T(0, -0.1, 0), Vector3(r * 2.0, 0.2, r * 2.0))
	ck.col_box(T(0, CAGE_H + 0.1, 0), Vector3(r * 2.0, 0.2, r * 2.0))
	var lv := Vector3(0, 0, -r + 0.45)
	ck.box(T(lv.x, 0.55, lv.z), Vector3(0.36, 1.1, 0.25), "laiton112_vieux", 1.0)
	ck.cyl(Transform3D(Basis(Vector3.RIGHT, -0.5), lv + Vector3(0, 1.05, 0)), 0.03, 0.03, 0.55, "fer114", 6)
	ck.ball(T(lv.x, 1.52, lv.z + 0.24), 0.07, "lampe114", 6, 4)
	ck.sign114(T(0, CAGE_H + 0.45, r + 0.2), "dome", 1.6, 0.8)
	ck.commit()
	# les deux grilles de la porte (elles coulissent)
	for s in [-1.0, 1.0]:
		var g := Node3D.new()
		g.name = "Grille_cage"
		cage.add_child(g)
		var gk = load("res://scripts/strates_kit_v114.gd").new()
		gk.setup(g, null)
		for k3 in range(4):
			gk.box(T(-0.33 + k3 * 0.22, CAGE_H * 0.5, 0), Vector3(0.035, CAGE_H - 0.2, 0.035), "laiton112", 1.0)
		gk.box(T(0, CAGE_H - 0.12, 0), Vector3(0.9, 0.07, 0.05), "laiton112", 1.0)
		gk.box(T(0, 0.08, 0), Vector3(0.9, 0.07, 0.05), "laiton112", 1.0)
		gk.commit()
		var closed := Vector3(s * 0.46, 0, r * cos(0.5))
		g.position = closed
		var b := StaticBody3D.new()
		g.add_child(b)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(0.92, CAGE_H, 0.1)
		cs.shape = sh
		cs.position = Vector3(0, CAGE_H * 0.5, 0)
		cs.disabled = true
		b.add_child(cs)
		cage_gates.append([g, cs, closed, s])
	var cl := OmniLight3D.new()
	cl.light_color = Color(1.0, 0.8, 0.55)
	cl.light_energy = 0.8
	cl.omni_range = 4.0
	cl.position = Vector3(0, CAGE_H - 0.5, 0)
	cage.add_child(cl)


# =================================================================== la conduite

static func _ease(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)


## Le plancher de la bulle (son centre) au paramètre u (0 : la Gare ; 1 : le fond du tunnel).
func point_at(u: float) -> Vector3:
	var s: float = clampf(u, 0.0, 1.0) * path_len
	for k in range(path.size() - 1):
		var a: Vector3 = path[k]
		var b: Vector3 = path[k + 1]
		var l: float = a.distance_to(b)
		if s <= l or k == path.size() - 2:
			return a.lerp(b, clampf(s / maxf(l, 0.001), 0.0, 1.0))
		s -= l
	return path[path.size() - 1]


func cabin_floor() -> Vector3:
	return point_at(_ease(t))


func at_station() -> bool:
	return not moving and t < 0.001


func in_cabin(p: Vector3) -> bool:
	if cabin == null:
		return false
	var l: Vector3 = cabin.global_transform.affine_inverse() * p
	return absf(l.x) < CAB_W * 0.5 - 0.05 and absf(l.z) < CAB_L * 0.5 - 0.05 and l.y > -0.6 and l.y < CAB_H + 0.2


func in_cage(p: Vector3) -> bool:
	var y0: float = cage.global_position.y if cage != null else cage_pos.y
	return Vector2(p.x - cage_pos.x, p.z - cage_pos.z).length() < CAGE_R - 0.15 and p.y > y0 - 0.6 and p.y < y0 + CAGE_H


## Descendre : depuis la cage, aux Strates.
func descend() -> void:
	if busy:
		return
	busy = true
	moving = false
	rides += 1
	var dj: Node = main.get("donjon_v35") if main != null else null
	var p: Vector3 = main._player_pos_v27()
	var off := Vector3(p.x - cage_pos.x, 0, p.z - cage_pos.z).limit_length(0.8)
	if main.has_method("sfx"):
		main.sfx("porte", cage_pos + Vector3.UP * 1.5)
	main._show_message_v28("Les grilles se ferment… La cage s'enfonce dans la roche. Prochain arrêt : le Dôme d'Azur, au fond de la mer !")
	await _cage_doors(false)
	# la cage s'enfonce un peu (on la sent descendre), puis le noir
	var sunk: float = 0.0
	while sunk < 0.7:
		var dy: float = minf(get_physics_process_delta_time() * 0.5, 0.7 - sunk)
		sunk += dy
		cage.global_position = cage_pos + Vector3.DOWN * sunk
		if in_cage(main._player_pos_v27() + Vector3.UP * dy):
			_carry(Vector3.DOWN * dy)
		await get_tree().physics_frame
	if dj != null:
		dj._busy = true
		await dj._fade_to(1.0, 0.6)
	# la bulle attend au fond du tunnel, porte fermée
	t = 1.0
	target = 1.0
	doors_open = 0.0
	_apply()
	var fl: Vector3 = cabin_floor()
	var side: Vector3 = _sd * clampf(off.x * _sd.x + off.z * _sd.z, -0.6, 0.6)
	main.place_player_v35(fl + side + _dl * 0.6 + Vector3.UP * 0.05, -_dl)
	carrying = true
	if dj != null:
		dj.update_inside(true)
	cage.global_position = cage_pos
	_cage_doors_now(true)
	await get_tree().create_timer(0.5).timeout
	if dj != null:
		await dj._fade_to(0.0, 1.0)
		dj._busy = false
	main._show_message_v28("La bulle sort de la falaise… En bas, au fond du bleu, les trois dômes du Dôme d'Azur s'allument.")
	target = 0.0
	moving = true
	busy = false


## Remonter : depuis la bulle, à la Gare d'Azur.
func ascend() -> void:
	if busy or moving or not at_station():
		return
	busy = true
	rides += 1
	if main.has_method("sfx"):
		main.sfx("porte", cabin_floor() + Vector3.UP * 1.5)
	main._show_message_v28("On remonte ! Prochain arrêt : les Strates, la Gare.")
	target = 1.0
	moving = true
	carrying = true
	busy = false


func _arrive_strates() -> void:
	busy = true
	var dj: Node = main.get("donjon_v35") if main != null else null
	if dj != null:
		dj._busy = true
		await dj._fade_to(1.0, 0.7)
	_cage_doors_now(false)
	cage.global_position = cage_pos + Vector3.DOWN * 0.7
	main.place_player_v35(cage_pos + Vector3.DOWN * 0.65 + Vector3(0, 0, -0.2), Vector3(0, 0, 1))
	carrying = false
	if dj != null:
		dj.update_inside(true)
	await get_tree().create_timer(0.4).timeout
	if dj != null:
		await dj._fade_to(0.0, 0.8)
		dj._busy = false
	# la cage remonte au niveau de la Gare des Strates, les grilles s'ouvrent
	var risen: float = 0.0
	while risen < 0.7:
		var dy: float = minf(get_physics_process_delta_time() * 0.5, 0.7 - risen)
		risen += dy
		cage.global_position = cage_pos + Vector3.DOWN * (0.7 - risen)
		if in_cage(main._player_pos_v27()):
			_carry(Vector3.UP * dy)
		await get_tree().physics_frame
	cage.global_position = cage_pos
	main._show_message_v28("Les Strates, la Gare. Ça sent la vapeur et le chocolat : on est bien remonté.")
	await _cage_doors(true)
	# la bulle redescend seule à la Gare d'Azur
	target = 0.0
	moving = true
	busy = false


func _cage_doors(open: bool) -> void:
	var want: float = 1.0 if open else 0.0
	while absf(cage_open - want) > 0.01:
		cage_open = move_toward(cage_open, want, get_physics_process_delta_time() * 1.6)
		_apply_cage()
		await get_tree().physics_frame


func _cage_doors_now(open: bool) -> void:
	cage_open = 1.0 if open else 0.0
	_apply_cage()


func _apply_cage() -> void:
	for g in cage_gates:
		(g[0] as Node3D).position = (g[2] as Vector3) + Vector3(float(g[3]) * 0.82 * cage_open, 0, 0)
		(g[1] as CollisionShape3D).disabled = cage_open > 0.5


func _apply() -> void:
	if cabin == null:
		return
	cabin.global_transform = Transform3D(Basis.looking_at(_dl, Vector3.UP), cabin_floor())
	for dl in cab_doors:
		var s: float = dl[1]
		(dl[0] as Node3D).position.z = s * (0.45 + 0.85 * doors_open)
	if cab_door_col != null:
		cab_door_col.disabled = doors_open > 0.6
	var bd := Basis.looking_at(_dl, Vector3.UP)
	var psd_open: float = doors_open if t < 0.001 else 0.0
	for pd in psd:
		(pd[0] as Node3D).global_transform = Transform3D(bd, (pd[1] as Vector3) + (pd[2] as Vector3) * 0.95 * psd_open)
		(pd[3] as CollisionShape3D).disabled = psd_open > 0.6


func _physics_process(delta: float) -> void:
	if cabin == null or main == null:
		return
	var p: Vector3 = main._player_pos_v27()
	var before: Vector3 = cabin_floor()
	var want_open: float = 0.0 if (moving or t > 0.001) else 1.0
	doors_open = move_toward(doors_open, want_open, delta * 1.4)
	if moving and doors_open <= 0.0:
		var dir: float = signf(target - t)
		t = clampf(t + dir * delta / DUREE, 0.0, 1.0)
		if (dir > 0.0 and t >= target) or (dir < 0.0 and t <= target):
			t = target
			moving = false
			if t < 0.5:
				if carrying and in_cabin(p):
					main._show_message_v28("La Gare d'Azur ! Bienvenue au Dôme d'Azur, à cent quarante mètres sous la mer. Respirez : l'air vient de la surface, par la Cheminée.")
				carrying = false
			elif carrying:
				_arrive_strates()
	_apply()
	var dv: Vector3 = cabin_floor() - before
	if dv.length() > 0.00001 and carrying and in_cabin(p + dv):
		_carry(dv)


func _carry(dv: Vector3) -> void:
	if main.get("xr_active") and main.xr_active:
		main.xr_origin.global_position += dv
		main.vr_body.global_position += dv
		if dv.y > 0.0:
			main.vr_body.velocity.y = maxf(main.vr_body.velocity.y, 0.0)
	else:
		main.pc_body.global_position += dv
		main.pc_root.position += dv
		if dv.y > 0.0:
			main.pc_body.velocity.y = maxf(main.pc_body.velocity.y, 0.0)
		if main.get("hero_v28") != null:
			main.hero_v28.fall_top = main.pc_body.global_position.y
	main.last_ok_v29.clear()


# =================================================================== les interactions

func register(d: Node, owner_node: Node) -> void:
	var me = self
	var ia := func(it: Dictionary) -> void:
		d._interactions.append(it)
		if owner_node != null and owner_node.get("_interactions") != null:
			owner_node._interactions.append(it)
	ia.call({"id": "da_descendre", "pos": cage_pos + Vector3.UP * 1.0, "radius": 2.0, "text": "E : tirer le levier (descendre au Dôme d'Azur)",
		"vr": "Gâchette : tirer le levier (descendre au Dôme d'Azur)", "call": func(): me.descend(), "when": func(): return not me.busy and me.in_cage(me.main._player_pos_v27())})
	ia.call({"id": "da_remonter", "pos": D.LR(STOP_R, 0.0, 2.0), "radius": 2.6, "text": "E : appuyer sur le bouton (remonter aux Strates)",
		"vr": "Gâchette : appuyer sur le bouton (remonter aux Strates)", "call": func(): me.ascend(), "when": func(): return me.at_station() and not me.busy and me.in_cabin(me.main._player_pos_v27())})
