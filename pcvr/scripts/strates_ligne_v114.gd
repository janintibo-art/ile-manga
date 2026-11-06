extends Node3D
## V114 : la Ligne des Strates. De la Place de la Colonne de Hautefond à la Gare des Strates, une
## centaine de mètres plus bas :
##  - en haut, le PAVILLON de la Ligne (sur la Place, à l'ouest de la Grande Colonne) : un kiosque
##    octogonal de fonte et de verre, coiffé d'un dôme vert-de-gris ; dedans, la cabine dorée. On y entre,
##    on tire le levier (E / gâchette), les grilles se ferment… et l'on descend dans le noir de la roche
##    (un fondu au noir) ;
##  - en bas, la même cabine reparaît en haut de la COLONNE RENVERSÉE, sous la voûte des Strates, et
##    descend lentement, en plein ciel de la caverne, jusqu'à la Gare des Strates (le joueur est porté
##    par la cabine : sa hauteur suit celle du plancher, au PC comme en VR) ;
##  - pour remonter : on tire le levier de la cabine, à la Gare ; elle monte jusqu'à la voûte, et l'on
##    reparaît dans le pavillon, en haut. La cabine redescend seule à la Gare.
## Les points (repère monde) : kiosk (le centre du pavillon, au sol), bottom (le centre de la cabine, au
## sol de la Gare), top_y (le plancher de la cabine, en haut de la Colonne Renversée).

const R = preload("res://scripts/strates_roche_v114.gd")
const R_CAB: float = 2.3
const H_CAB: float = 3.0
const R_KIOSK: float = 3.4
const DUREE: float = 20.0                # la descente (s)
const TOP_Y: float = -56.0

var main: Node
var kit                                  # le kit des Strates (la caverne)
var kiosk := Vector3.ZERO
var kiosk_door := Vector3.ZERO           # la direction de la porte du pavillon (vers la Colonne)
var bottom := Vector3.ZERO
var cabin: Node3D
var door_l: Node3D
var door_r: Node3D
var door_col: CollisionShape3D
var k_gates: Array = []                  # [grille, collision, position fermée, côté]
var k_open: float = 1.0
var t: float = 0.0                       # 0 : à la Gare ; 1 : en haut de la Colonne Renversée
var target: float = 0.0
var moving: bool = false
var doors_open: float = 1.0
var busy: bool = false
var rides: int = 0
var carrying: bool = false               # la cabine porte le joueur (pendant la conduite)
var _pc: bool = true


func T(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


func build(main_node: Node, strates_kit, colonne: Node3D, _ville: Node3D, pc: bool) -> void:
	main = main_node
	kit = strates_kit
	_pc = pc
	kiosk = colonne.foot + Vector3(-30.8, 0.0, 0.0)
	kiosk_door = Vector3(1, 0, 0)
	bottom = R.W(0.0, 0.0, R.F0)
	_pavillon()
	_cabine()
	_cage_bas()


# =================================================================== le pavillon (sur la Place)

func _pavillon() -> void:
	var pk = load("res://scripts/strates_kit_v114.gd").new()
	pk.setup(self, main.get("temps_v56") if main != null else null)
	pk.main = main
	pk.pc = _pc
	var c: Vector3 = kiosk
	var r: float = R_KIOSK
	var hh: float = 3.6
	var door_a: float = atan2(kiosk_door.z, kiosk_door.x)
	# le socle (trois marches basses), le plancher de laiton et de bois
	pk.cyl(Transform3D(Basis(), c + Vector3.DOWN * 0.6), r + 0.9, r + 0.9, 0.62, "pierre112_clair", 8, true, 2.0)
	pk.disc(Transform3D(Basis(), c + Vector3.UP * 0.03), r - 0.1, "bois112", 24, 1.5)
	pk.ring(Transform3D(Basis(), c + Vector3.UP * 0.02), r - 0.3, r + 0.05, 0.04, "laiton112", 24)
	# les huit colonnes de fonte, les vitres (sauf la porte), la frise
	for k in range(8):
		var a: float = door_a + TAU * k / 8.0 + PI / 8.0
		var p: Vector3 = c + Vector3(cos(a), 0, sin(a)) * r
		pk.cyl(Transform3D(Basis(), p), 0.12, 0.1, hh, "fer114", 8, false)
		pk.col_cyl(p, 0.14, hh)
		var a2: float = a + TAU / 8.0
		var p2: Vector3 = c + Vector3(cos(a2), 0, sin(a2)) * r
		var mid: Vector3 = (p + p2) * 0.5
		var am: float = a + PI / 8.0
		var bs := Basis.looking_at(-(mid - c).normalized(), Vector3.UP)
		if absf(wrapf(am - door_a, -PI, PI)) < 0.2:
			continue
		pk.box(Transform3D(bs, mid + Vector3.UP * 0.5), Vector3(p.distance_to(p2), 1.0, 0.08), "fer114", 1.0)
		pk.quad(Transform3D(bs, mid + Vector3.UP * 2.1), p.distance_to(p2) - 0.1, 2.2, "verre112", Vector2(0, 0), Vector2(1, 1), true)
		pk.col_box(Transform3D(bs, mid + Vector3.UP * (hh * 0.5)), Vector3(p.distance_to(p2), hh, 0.12))
	pk.cyl(Transform3D(Basis(), c + Vector3.UP * hh), r + 0.35, r + 0.35, 0.5, "fer114", 8, true)
	pk.ring(Transform3D(Basis(), c + Vector3.UP * (hh + 0.1)), r + 0.3, r + 0.45, 0.3, "laiton112", 8)
	pk.dome76(Transform3D(Basis(), c + Vector3.UP * (hh + 0.5)), r + 0.35, 2.0, "verdigris112", 16, 6)
	pk.cyl(Transform3D(Basis(), c + Vector3.UP * (hh + 2.5)), 0.12, 0.03, 1.6, "or112", 6)
	pk.ball(Transform3D(Basis(), c + Vector3.UP * (hh + 2.6)), 0.22, "or112", 8, 4)
	# l'enseigne (au-dessus de la porte, vers la Colonne) et le levier, dedans
	var db := Basis.looking_at(-kiosk_door, Vector3.UP)
	pk.sign114(Transform3D(db, c + kiosk_door * (r + 0.42) + Vector3.UP * (hh + 0.25)), "ligne", 2.8, 0.7)
	var lv: Vector3 = c - kiosk_door * (r - 0.6)
	pk.box(Transform3D(db, lv + Vector3.UP * 0.55), Vector3(0.4, 1.1, 0.3), "laiton112_vieux", 1.0)
	pk.cyl(Transform3D(db * Basis(Vector3.RIGHT, -0.5), lv + Vector3.UP * 1.05), 0.03, 0.03, 0.6, "fer114", 6)
	pk.ball(Transform3D(Basis(), lv + Vector3.UP * 1.05 + db * Vector3(0, 0.52, 0.27)), 0.07, "lampe114", 6, 4)
	# la lanterne au plafond
	pk.ball(Transform3D(Basis(), c + Vector3.UP * (hh - 0.4)), 0.3, "lampe112", 10, 6)
	# la banquette circulaire (au fond)
	pk.commit()
	# les deux grilles de la porte (elles coulissent)
	var side: Vector3 = kiosk_door.cross(Vector3.UP).normalized()
	for s in [-1.0, 1.0]:
		var g := MeshInstance3D.new()
		g.name = "Grille_pavillon"
		var gk = load("res://scripts/strates_kit_v114.gd").new()
		gk.setup(g, null)
		for k2 in range(6):
			gk.box(T(-0.55 + k2 * 0.22, 1.5, 0), Vector3(0.035, 3.0, 0.035), "laiton112", 1.0)
		gk.box(T(0, 2.95, 0), Vector3(1.35, 0.08, 0.06), "laiton112", 1.0)
		gk.box(T(0, 0.05, 0), Vector3(1.35, 0.08, 0.06), "laiton112", 1.0)
		var mesh := ArrayMesh.new()
		for k3 in gk.batch:
			var st: SurfaceTool = gk.batch[k3]
			st.commit(mesh)
			mesh.surface_set_material(mesh.get_surface_count() - 1, gk.mat(str(k3)))
		g.mesh = mesh
		add_child(g)
		var closed: Vector3 = c + kiosk_door * (r * cos(PI / 8.0) + 0.02) + side * s * 0.68
		g.global_transform = Transform3D(db, closed)
		var b := StaticBody3D.new()
		add_child(b)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(1.36, 3.0, 0.12)
		cs.shape = sh
		b.add_child(cs)
		b.global_transform = Transform3D(db, closed + Vector3.UP * 1.5)
		cs.disabled = true
		k_gates.append([g, cs, closed, side * s])


# =================================================================== la cabine (en bas)

func _cabine() -> void:
	cabin = Node3D.new()
	cabin.name = "Cabine_strates"
	add_child(cabin)
	cabin.global_position = bottom
	cabin.global_basis = Basis.looking_at(Vector3(0, 0, -1), Vector3.UP)   # la porte regarde +Z (le sud)
	var ck = load("res://scripts/strates_kit_v114.gd").new()
	ck.setup(cabin, main.get("temps_v56") if main != null else null)
	ck.main = main
	ck.pc = _pc
	var r: float = R_CAB
	ck.cyl(T(0, -0.25, 0), r + 0.1, r + 0.1, 0.25, "laiton112_vieux", 24)
	ck.disc(T(0, 0.02, 0), r, "bois112", 24, 1.5)
	ck.cyl(T(0, H_CAB, 0), r + 0.1, r + 0.1, 0.2, "laiton112_vieux", 24)
	ck.dome76(T(0, H_CAB + 0.2, 0), r + 0.1, 0.6, "or112", 24, 4)
	ck.cyl(T(0, H_CAB + 0.7, 0), 0.25, 0.25, 0.5, "laiton112", 10)
	var body: StaticBody3D = ck.body
	var floor_col := CollisionShape3D.new()
	var fs := CylinderShape3D.new()
	fs.radius = r
	fs.height = 0.3
	floor_col.shape = fs
	floor_col.position = Vector3(0, -0.15, 0)
	body.add_child(floor_col)
	var roof_col := CollisionShape3D.new()
	var rs := CylinderShape3D.new()
	rs.radius = r
	rs.height = 0.2
	roof_col.shape = rs
	roof_col.position = Vector3(0, H_CAB + 0.1, 0)
	body.add_child(roof_col)
	# la cage dorée : des barreaux, une main courante (la porte : devant, +Z)
	var seg: int = 14
	for k in range(seg):
		var a0: float = TAU * k / seg + PI * 0.5 - PI / seg
		var a1: float = a0 + TAU / seg
		var am: float = (a0 + a1) * 0.5
		var p0 := Vector3(cos(a0), 0, sin(a0)) * r
		var p1 := Vector3(cos(a1), 0, sin(a1)) * r
		ck.cyl(Transform3D(Basis(), p0), 0.05, 0.05, H_CAB, "laiton112", 6, false)
		if absf(wrapf(am - PI * 0.5, -PI, PI)) < 0.55:
			continue
		var mid: Vector3 = (p0 + p1) * 0.5
		var w: float = p0.distance_to(p1)
		var bs := Basis.looking_at(-mid.normalized(), Vector3.UP)
		for k2 in range(4):
			ck.box(Transform3D(bs, mid + Vector3.UP * (0.35 + k2 * 0.75)), Vector3(w, 0.04, 0.04), "laiton112", 1.0)
		ck.quad(Transform3D(bs, mid + Vector3.UP * (H_CAB * 0.5)), w, H_CAB - 0.1, "vitre114", Vector2(0, 0), Vector2(1, 1), true)
		ck.col_box(Transform3D(bs, mid + Vector3.UP * (H_CAB * 0.5)), Vector3(w, H_CAB, 0.1))
	# la banquette de velours (au fond), le levier (à droite de la porte), la lanterne
	ck.box(T(0, 0.25, -r + 0.45), Vector3(1.8, 0.5, 0.5), "bois112", 1.0)
	ck.box(T(0, 0.52, -r + 0.45), Vector3(1.7, 0.08, 0.46), "tissu112_rouge", 1.0)
	ck.col_box(T(0, 0.25, -r + 0.45), Vector3(1.8, 0.5, 0.5))
	var px := Transform3D(Basis(Vector3.UP, -PI * 0.35), Vector3(r - 0.55, 0, 0.75))
	ck.box(px * T(0, 0.55, 0), Vector3(0.36, 1.1, 0.22), "laiton112_vieux", 1.0)
	ck.cyl(Transform3D(px.basis * Basis(Vector3.RIGHT, -0.5), px * Vector3(0, 1.05, 0)), 0.03, 0.03, 0.6, "fer114", 6)
	ck.ball(T(0, H_CAB - 0.35, 0), 0.25, "lampe114", 10, 6)
	ck.commit()
	door_l = _door_leaf(-1.0)
	door_r = _door_leaf(1.0)
	door_col = CollisionShape3D.new()
	var ds := BoxShape3D.new()
	ds.size = Vector3(1.9, H_CAB, 0.12)
	door_col.shape = ds
	door_col.position = Vector3(0, H_CAB * 0.5, r * cos(0.55))
	door_col.disabled = true
	body.add_child(door_col)
	var cl := OmniLight3D.new()
	cl.light_color = Color(1.0, 0.8, 0.55)
	cl.light_energy = 1.0
	cl.omni_range = 5.0
	cl.position = Vector3(0, H_CAB - 0.5, 0)
	cabin.add_child(cl)


func _door_leaf(s: float) -> Node3D:
	var n := MeshInstance3D.new()
	n.name = "Grille_cabine"
	var gk = load("res://scripts/strates_kit_v114.gd").new()
	gk.setup(n, null)
	for k in range(5):
		gk.box(T(-0.4 + k * 0.2, H_CAB * 0.5, 0), Vector3(0.035, H_CAB - 0.1, 0.035), "laiton112", 1.0)
	gk.box(T(0, H_CAB - 0.05, 0), Vector3(0.95, 0.07, 0.05), "laiton112", 1.0)
	gk.box(T(0, 0.05, 0), Vector3(0.95, 0.07, 0.05), "laiton112", 1.0)
	var mesh := ArrayMesh.new()
	for k2 in gk.batch:
		var st: SurfaceTool = gk.batch[k2]
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, gk.mat(str(k2)))
	n.mesh = mesh
	cabin.add_child(n)
	n.set_meta("s", s)
	n.position = Vector3(s * 0.47, 0, R_CAB * cos(0.55))
	return n


## La cage du bas : quatre montants, des panneaux de verre (la porte au sud reste ouverte).
func _cage_bas() -> void:
	var ck = load("res://scripts/strates_kit_v114.gd").new()
	ck.setup(self, null)
	var c: Vector3 = bottom
	for k in range(8):
		var a: float = TAU * k / 8.0
		var p: Vector3 = c + Vector3(cos(a), 0, sin(a)) * 2.75
		ck.cyl(Transform3D(Basis(), p), 0.08, 0.08, 3.6, "laiton112", 6, false)
		var a2: float = a + TAU / 8.0
		var am: float = a + PI / 8.0
		if absf(wrapf(am - PI * 0.5, -PI, PI)) < 0.5:
			continue
		var p2: Vector3 = c + Vector3(cos(a2), 0, sin(a2)) * 2.75
		var mid: Vector3 = (p + p2) * 0.5
		var bs := Basis.looking_at(-(mid - c).normalized(), Vector3.UP)
		ck.quad(Transform3D(bs, mid + Vector3.UP * 1.8), p.distance_to(p2), 3.5, "verre112", Vector2(0, 0), Vector2(1, 1), true)
		ck.col_box(Transform3D(bs, mid + Vector3.UP * 1.8), Vector3(p.distance_to(p2), 3.6, 0.1))
	ck.ring(Transform3D(Basis(), c + Vector3.UP * 3.6), 2.6, 3.05, 0.3, "laiton112", 24)
	ck.commit()


# =================================================================== la conduite

func cabin_y() -> float:
	return lerpf(bottom.y + 0.02, TOP_Y, _ease(t))


static func _ease(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)


func at_bottom() -> bool:
	return not moving and t < 0.01


func in_deep_cabin(p: Vector3) -> bool:
	var cy: float = cabin_y()
	return Vector2(p.x - bottom.x, p.z - bottom.z).length() < R_CAB - 0.1 and p.y > cy - 0.6 and p.y < cy + H_CAB


func in_kiosk(p: Vector3) -> bool:
	return Vector2(p.x - kiosk.x, p.z - kiosk.z).length() < R_KIOSK - 0.2 and absf(p.y - kiosk.y) < 2.5


## Dans le tube de la Colonne Renversée, au-dessus de la Gare (on ne devrait pas y être, sauf dans la cabine).
func in_shaft(p: Vector3) -> bool:
	return Vector2(p.x - bottom.x, p.z - bottom.z).length() < 2.7 and p.y > bottom.y + 4.0 and p.y < TOP_Y + 6.0


## Descendre : depuis le pavillon, en haut.
func descend() -> void:
	if busy or moving:
		return
	busy = true
	rides += 1
	var dj: Node = main.get("donjon_v35") if main != null else null
	var p: Vector3 = main._player_pos_v27()
	var off := Vector3(p.x - kiosk.x, 0, p.z - kiosk.z)
	if off.length() > 1.3:
		off = off.normalized() * 1.3
	if main.has_method("sfx"):
		main.sfx("porte", kiosk + Vector3.UP * 1.5)
	main._show_message_v28("Les grilles se ferment… La cabine s'enfonce dans la roche. Prochain arrêt : la Gare des Strates !")
	await _kiosk_doors(false)
	if dj != null:
		dj._busy = true
		await dj._fade_to(1.0, 0.6)
	# la cabine attend tout en haut de la Colonne Renversée, portes fermées
	t = 1.0
	target = 1.0
	doors_open = 0.0
	_apply_cabin()
	main.place_player_v35(Vector3(bottom.x + off.x, TOP_Y + 0.05, bottom.z + off.z), Vector3(0, 0, 1))
	carrying = true
	if dj != null:
		dj.update_inside(true)
	await get_tree().create_timer(0.4).timeout
	if dj != null:
		await dj._fade_to(0.0, 0.9)
		dj._busy = false
	_kiosk_doors_now(true)
	target = 0.0
	moving = true
	busy = false


## Remonter : depuis la cabine, à la Gare.
func ascend() -> void:
	if busy or moving or not at_bottom():
		return
	busy = true
	rides += 1
	if main.has_method("sfx"):
		main.sfx("porte", bottom + Vector3.UP * 1.5)
	main._show_message_v28("On remonte ! Prochain arrêt : Hautefond, la Place de la Colonne.")
	target = 1.0
	moving = true
	carrying = true
	busy = false


func _arrive_top() -> void:
	busy = true
	var dj: Node = main.get("donjon_v35") if main != null else null
	var p: Vector3 = main._player_pos_v27()
	var off := Vector3(p.x - bottom.x, 0, p.z - bottom.z)
	if dj != null:
		dj._busy = true
		await dj._fade_to(1.0, 0.7)
	_kiosk_doors_now(false)
	main.place_player_v35(Vector3(kiosk.x + off.x * 0.6, kiosk.y + 0.08, kiosk.z + off.z * 0.6), kiosk_door)
	carrying = false
	if dj != null:
		dj.update_inside(true)
	await get_tree().create_timer(0.4).timeout
	if dj != null:
		await dj._fade_to(0.0, 0.8)
		dj._busy = false
	main._show_message_v28("Hautefond, la Place de la Colonne. Le ciel ! Il fait drôlement clair, en haut.")
	await _kiosk_doors(true)
	# la cabine redescend seule à la Gare
	target = 0.0
	moving = true
	busy = false


func _kiosk_doors(open: bool) -> void:
	var want: float = 1.0 if open else 0.0
	while absf(k_open - want) > 0.01:
		k_open = move_toward(k_open, want, get_physics_process_delta_time() * 1.6)
		_apply_kiosk()
		await get_tree().physics_frame


func _kiosk_doors_now(open: bool) -> void:
	k_open = 1.0 if open else 0.0
	_apply_kiosk()


func _apply_kiosk() -> void:
	for g in k_gates:
		(g[0] as Node3D).global_position = (g[2] as Vector3) + (g[3] as Vector3) * 0.95 * k_open
		(g[1] as CollisionShape3D).disabled = k_open > 0.5


func _apply_cabin() -> void:
	if cabin == null:
		return
	cabin.global_position = Vector3(bottom.x, cabin_y(), bottom.z)
	for dl in [door_l, door_r]:
		if dl != null:
			var s: float = float(dl.get_meta("s"))
			dl.position.x = s * (0.47 + 0.85 * doors_open)
	if door_col != null:
		door_col.disabled = doors_open > 0.6


func _physics_process(delta: float) -> void:
	if cabin == null or main == null:
		return
	var p: Vector3 = main._player_pos_v27()
	var y_before: float = cabin_y()
	var want_open: float = 0.0 if (moving or t > 0.5) else 1.0
	doors_open = move_toward(doors_open, want_open, delta * 1.5)
	if moving and doors_open <= 0.0:
		var dir: float = signf(target - t)
		t = clampf(t + dir * delta / DUREE, 0.0, 1.0)
		if (dir > 0.0 and t >= target) or (dir < 0.0 and t <= target):
			t = target
			moving = false
			if t < 0.5:
				if carrying and in_deep_cabin(p):
					main._show_message_v28("La Gare des Strates ! Bienvenue sous la ville. Attention à la marche, et au Soleil : il ne se couche jamais vraiment.")
				carrying = false
			elif carrying:
				_arrive_top()
	_apply_cabin()
	var dy: float = cabin_y() - y_before
	if absf(dy) > 0.00001 and carrying and in_deep_cabin(Vector3(p.x, p.y - dy, p.z)):
		_carry(dy)


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


# =================================================================== les interactions

func register(d: Node, owner_node: Node) -> void:
	var me = self
	var ia := func(it: Dictionary) -> void:
		d._interactions.append(it)
		if owner_node != null and owner_node.get("_interactions") != null:
			owner_node._interactions.append(it)
	ia.call({"id": "st_descendre", "pos": kiosk + Vector3.UP * 1.0, "radius": 2.6, "text": "E : tirer le levier (descendre aux Strates)",
		"vr": "Gâchette : tirer le levier (descendre aux Strates)", "call": func(): me.descend(), "when": func(): return not me.busy and not me.moving and me.in_kiosk(me.main._player_pos_v27())})
	ia.call({"id": "st_remonter", "pos": bottom + Vector3.UP * 1.0, "radius": 2.1, "text": "E : tirer le levier (remonter à Hautefond)",
		"vr": "Gâchette : tirer le levier (remonter à Hautefond)", "call": func(): me.ascend(), "when": func(): return me.at_bottom() and not me.busy and me.in_deep_cabin(me.main._player_pos_v27())})
