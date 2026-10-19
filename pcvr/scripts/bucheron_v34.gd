extends Node3D
## V34 : abattre des arbres à la hache.
## Seuls certains arbres s'abattent : de jeunes arbres et des cocotiers, reconnaissables à
## l'entaille claire taillée dans leur tronc, à hauteur de main. Hache en main, chaque coup
## les entaille (copeaux, l'arbre tremble) ; au dernier, l'arbre bascule à l'opposé du
## bûcheron, tombe, puis il ne reste qu'une souche. Butin : bûches, noix de coco, miel,
## parfois un nid de pie plein de pièces. Les arbres repoussent au bout de 8 minutes de jeu.

const REGROW: float = 480.0
const HP := {"arbre": 4, "palmier": 3}
const NOTCH_COLOR := Color(0.86, 0.7, 0.48)

var main: Node
var trees: Array = []                 # {kind, pos, yaw, scale, island, node, body, stump, hp, state, regrow, ...}
var _rng := RandomNumberGenerator.new()
var _msg_clock: float = 0.0
var _mats: Dictionary = {}
var _pending: Dictionary = {}         # sauvegarde lue avant la plantation
var total_cut: int = 0                # arbres abattus depuis le début de la partie


func setup(main_node: Node) -> void:
	main = main_node


## Plantation (déterministe) : à appeler une fois la physique prête.
func plant() -> void:
	_rng.seed = 3434
	var spots: Array = []
	var flora: Node = main.flora_v30
	var j: Node = main.jungle_v29
	# Jungle : trois jeunes arbres autour du fromager d'Octave (hors du côté de l'échelle),
	# des cocotiers sur la plage de la baie, et d'autres arbres dans les sous-bois.
	if not main.tree_spot_v33.is_empty():
		var c: Vector3 = main.tree_spot_v33["pos"]
		var f: Vector3 = main.tree_spot_v33["facing"]
		var base_a: float = atan2(f.z, f.x)
		for k in range(3):
			var a: float = base_a + PI * (0.55 + 0.45 * k)
			_try(spots, "arbre", c + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(10.0, 12.0), "jungle")
	if j != null:
		var dock: Vector3 = j.dock_start
		var tries: int = 0
		var made: int = 0
		while made < 8 and tries < 400:
			tries += 1
			var a2: float = PI * 0.5 + _rng.randf_range(-0.6, 0.6)
			var r2: float = _rng.randf_range(60.0, 92.0)
			var p2: Vector3 = j.CENTER + Vector3(cos(a2) * r2, 0, sin(a2) * r2)
			var h2: float = main._height_at(p2.x, p2.z)
			if h2 < 0.35 or h2 > 2.6 or Vector2(p2.x - dock.x, p2.z - dock.z).length() < 10.0:
				continue
			if _try(spots, "palmier", p2, "jungle"):
				made += 1
		tries = 0
		made = 0
		while made < 14 and tries < 1500:
			tries += 1
			var a3: float = _rng.randf() * TAU
			var r3: float = sqrt(_rng.randf_range(25.0 * 25.0, 95.0 * 95.0))
			var l := Vector2(cos(a3) * r3, sin(a3) * r3)
			if j.coast_ratio(l.x, l.y) > 0.85 or j.gorge_distance(l.x, l.y) < 8.0:
				continue
			var p3: Vector3 = j.CENTER + Vector3(l.x, 0, l.y)
			var h3: float = main._height_at(p3.x, p3.z)
			if h3 < 1.5 or h3 > 22.0 or _slope(p3) > 0.45:
				continue
			if _try(spots, "arbre", p3, "jungle"):
				made += 1
	# Île du village : quelques jeunes arbres dans les prés et des cocotiers sur la plage.
	var tries2: int = 0
	var made2: int = 0
	while made2 < 6 and tries2 < 800:
		tries2 += 1
		var a4: float = _rng.randf() * TAU
		var r4: float = _rng.randf_range(20.0, 46.0)
		var p4 := Vector3(cos(a4) * r4, 0, 4.0 + sin(a4) * r4)
		var h4: float = main._height_at(p4.x, p4.z)
		if h4 < 0.9 or h4 > 9.0 or _slope(p4) > 0.4:
			continue
		if _try(spots, "arbre", p4, "village"):
			made2 += 1
	tries2 = 0
	made2 = 0
	while made2 < 6 and tries2 < 800:
		tries2 += 1
		var a5: float = _rng.randf() * TAU
		var r5: float = _rng.randf_range(38.0, 60.0)
		var p5 := Vector3(cos(a5) * r5, 0, 4.0 + sin(a5) * r5)
		var h5: float = main._height_at(p5.x, p5.z)
		if h5 < 0.25 or h5 > 1.6:
			continue
		if _try(spots, "palmier", p5, "village"):
			made2 += 1
	for i in range(spots.size()):
		_build(i, spots[i])
	_apply_pending()
	print("ILE_MANGA_V34: ", trees.size(), " arbres à abattre")


func _slope(p: Vector3) -> float:
	var e: float = 0.8
	var gx: float = main._height_at(p.x + e, p.z) - main._height_at(p.x - e, p.z)
	var gz: float = main._height_at(p.x, p.z + e) - main._height_at(p.x, p.z - e)
	return sqrt(gx * gx + gz * gz) / (2.0 * e)


## Un emplacement est bon si l'on tombe sur le sol nu (pas de rocher, de maison, de tronc)
## et qu'il y a de la place autour.
func _try(spots: Array, kind: String, p: Vector3, island: String) -> bool:
	var space: PhysicsDirectSpaceState3D = (main as Node3D).get_world_3d().direct_space_state
	var h: float = main._height_at(p.x, p.z)
	var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, h + 12.0, p.z), Vector3(p.x, h - 2.0, p.z), 1))
	if hit.is_empty():
		return false
	var n: String = str(hit.collider.name)
	if n != "Sol_collision_v11" and n != "Sol_jungle_v29":
		return false
	if absf(hit.position.y - h) > 0.4:
		return false
	var q := PhysicsShapeQueryParameters3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 1.3
	q.shape = sph
	q.collision_mask = 1
	q.transform = Transform3D(Basis.IDENTITY, hit.position + Vector3.UP * 1.6)
	if not space.intersect_shape(q, 1).is_empty():
		return false
	for s in spots:
		if Vector2(s["pos"].x - p.x, s["pos"].z - p.z).length() < 6.0:
			return false
	# Pas sur les chemins des habitants ni au bout des pontons.
	for npc in main.npcs_v31:
		for k in npc.points:
			var q2: Vector3 = npc.points[k]
			if Vector2(q2.x - p.x, q2.z - p.z).length() < 3.0:
				return false
	spots.append({"kind": kind, "pos": hit.position, "yaw": _rng.randf() * TAU, "scale": _rng.randf_range(0.9, 1.1), "island": island, "variant": _rng.randi() % 3})
	return true


# =================================================================== construction

func _mat(key: String, c: Color, rough: float = 0.85) -> StandardMaterial3D:
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = rough
		_mats[key] = m
	return _mats[key]


func _build(i: int, s: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "Arbre_a_bois_v34_%d" % i
	root.set_script(preload("res://scripts/arbre_v34.gd"))
	add_child(root)
	root.global_position = s["pos"] - Vector3.UP * 0.08
	var detailed: bool = OS.has_feature("ile_manga_pc") or not main.xr_active
	var kind: String = s["kind"]
	var sc: float = float(s["scale"])
	var mesh: Mesh = null
	if main.flora_v30 != null:
		mesh = main.flora_v30.palm_mesh(int(s["variant"]), detailed) if kind == "palmier" else main.flora_v30.canopy_tree_mesh(int(s["variant"]), detailed)
	var mi := MeshInstance3D.new()
	mi.name = "Arbre"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var tree_scale: float = sc * (0.85 if kind == "palmier" else 0.42)
	mi.scale = Vector3.ONE * tree_scale
	root.add_child(mi)
	# L'entaille claire : le signe des arbres qu'on peut abattre.
	var trunk_r: float = 0.27 if kind == "palmier" else 0.42 * 0.42 * sc * 1.15
	var bark_r: float = 0.2 * sc if kind == "palmier" else 0.155 * sc      # rayon réel du tronc à 1 m
	var notch := Node3D.new()
	notch.name = "Entaille"
	notch.position = Vector3(0, 1.0, 0)
	mi.add_child(notch)
	notch.scale = Vector3.ONE / tree_scale
	# Entaille en V taillée dans l'écorce : deux faces de bois clair, un fond sombre.
	for sgn in [-1.0, 1.0]:
		var face := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(bark_r * 1.25, 0.1, 0.02)
		face.mesh = b
		face.material_override = _mat("entaille", NOTCH_COLOR, 0.9)
		face.position = Vector3(0, sgn * 0.035, bark_r - 0.025)
		face.rotation = Vector3(sgn * 0.55, 0, 0)
		notch.add_child(face)
	var dark := MeshInstance3D.new()
	var b2 := BoxMesh.new()
	b2.size = Vector3(bark_r * 1.1, 0.025, 0.02)
	dark.mesh = b2
	dark.material_override = _mat("entaille_creux", Color(0.36, 0.25, 0.15), 0.9)
	dark.position = Vector3(0, 0.0, bark_r - 0.05)
	notch.add_child(dark)
	notch.rotation.y = float(s["yaw"])
	notch.position = Vector3(0, 1.0 / tree_scale, 0)
	# Souche (cachée tant que l'arbre est debout)
	var stump := Node3D.new()
	stump.name = "Souche"
	stump.visible = false
	root.add_child(stump)
	var sm := MeshInstance3D.new()
	var sc_mesh := CylinderMesh.new()
	sc_mesh.top_radius = trunk_r * 0.95
	sc_mesh.bottom_radius = trunk_r * 1.2
	sc_mesh.height = 0.4
	sc_mesh.radial_segments = 10
	sm.mesh = sc_mesh
	sm.material_override = main.flora_v30.bark_mat() if main.flora_v30 != null else _mat("ecorce", Color(0.4, 0.3, 0.2))
	sm.position.y = 0.2
	stump.add_child(sm)
	var top := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = trunk_r * 0.9
	tm.bottom_radius = trunk_r * 0.9
	tm.height = 0.02
	tm.radial_segments = 10
	top.mesh = tm
	top.material_override = _mat("tranche", Color(0.85, 0.7, 0.48), 0.8)
	top.position.y = 0.4
	stump.add_child(top)
	# Collision du tronc
	var body := StaticBody3D.new()
	body.name = "Tronc_collision"
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = maxf(trunk_r, 0.22)
	cyl.height = 4.0
	cs.shape = cyl
	cs.position.y = 2.0
	body.add_child(cs)
	root.add_child(body)
	root.manager = self
	root.index = i
	root.hit_radius = maxf(trunk_r, 0.22) + 0.05
	root.hit_height = 1.0
	root.add_to_group("cibles_v28")
	trees.append({"kind": kind, "island": s["island"], "node": root, "mesh": mi, "body": body, "stump": stump, "notch": notch,
		"hp": int(HP[kind]), "state": "debout", "regrow": 0.0, "shake": 0.0, "shake_axis": Vector3.RIGHT, "fall": 0.0, "fall_axis": Vector3.RIGHT})


# =================================================================== coups de hache

func standing(i: int) -> bool:
	return i >= 0 and i < trees.size() and str(trees[i]["state"]) == "debout"


func _say(text: String, at: Vector3 = Vector3.INF) -> void:
	if _msg_clock > 0.0:
		return
	_msg_clock = 1.6
	main._show_message_v28(text)
	if main.xr_active and at != Vector3.INF and main.combat_v28 != null:
		main.combat_v28.float_text(at, text, Color(1, 0.95, 0.8))


func hit(i: int, damage: int, from_pos: Vector3) -> void:
	if not standing(i):
		return
	var t: Dictionary = trees[i]
	var node: Node3D = t["node"]
	var at: Vector3 = node.global_position + Vector3.UP * 1.0
	var axe: bool = main.inventory_v28.equipped == "hache" and damage >= 3
	var away: Vector3 = node.global_position - from_pos
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3.FORWARD
	t["shake"] = 0.05 if not axe else 0.12
	t["shake_axis"] = Vector3.UP.cross(away).normalized()
	if not axe:
		if main.inventory_v28.equipped in ["epee", "epee_bois", "epee_naine", "epee_nuees", "trident_marees"]:
			_say("Une épée ne coupe pas un arbre : elle s'émousserait. Prends une hache.", at)
		elif main.inventory_v28.equipped == "hache":
			_say("Frappe le tronc avec le fer de la hache !", at)
		elif main.inventory_v28.equipped == "pelle":
			_say("Avec une pelle ? Il faut une hache pour abattre cet arbre.", at)
		else:
			_say("Cet arbre porte une entaille : il s'abat… avec une hache.", at)
		return
	t["hp"] = int(t["hp"]) - 1
	if main.has_method("sfx"):
		main.sfx("hache", at)
	if main.combat_v28 != null:
		main.combat_v28.puff(at - away * 0.25, Color(0.86, 0.72, 0.5))
		main.combat_v28.float_text(at + Vector3.UP * 0.9, "Toc !" if int(t["hp"]) > 0 else "Craaac !", Color(1.0, 0.85, 0.55))
	if int(t["hp"]) > 0:
		return
	# Il tombe à l'opposé du bûcheron.
	t["state"] = "chute"
	t["fall"] = 0.0
	t["fall_axis"] = Vector3.UP.cross(away).normalized()
	t["fall_dir"] = away
	(t["body"] as StaticBody3D).collision_layer = 0
	main._show_message_v28("Attention, ça tombe !")
	if main.has_method("sfx"):
		main.sfx("arbre_tombe", at + Vector3.UP * 2.0)


func _loot(t: Dictionary) -> void:
	total_cut += 1
	var gains: Array = []
	if str(t["kind"]) == "palmier":
		gains.append(["noix_coco", _rng.randi_range(2, 3)])
		gains.append(["buche", 1])
		if _rng.randf() < 0.1:
			gains.append(["piece", _rng.randi_range(1, 2)])
	else:
		gains.append(["buche", _rng.randi_range(2, 3)])
		if str(t["island"]) == "jungle":
			if _rng.randf() < 0.3:
				gains.append(["miel", 1])
		elif _rng.randf() < 0.4:
			gains.append(["pomme", 2])
		var nest: float = _rng.randf()
		if nest < 0.12:
			gains.append(["piece", _rng.randi_range(3, 6)])
		if nest < 0.04:
			gains.append(["bague", 1])
	var parts: Array = []
	for g in gains:
		var got: int = main.inventory_v28.add(str(g[0]), int(g[1]))
		if got > 0:
			parts.append(str(main.inventory_v28.ITEMS[str(g[0])]["name"]) + ("" if got == 1 else " ×%d" % got))
	var text: String = "Arbre abattu ! " + (", ".join(parts) if not parts.is_empty() else "(ton sac est plein)")
	for g in gains:
		if str(g[0]) == "bague" or (str(g[0]) == "piece" and int(g[1]) >= 3 and str(t["kind"]) == "arbre"):
			text += "\nUn nid de pie était caché dans les branches !"
			break
	main._show_message_v28(text)
	if main.xr_active and main.combat_v28 != null:
		main.combat_v28.float_text((t["node"] as Node3D).global_position + Vector3.UP * 2.0, text, Color(0.8, 1.0, 0.7))


# =================================================================== chute et repousse

func _process(delta: float) -> void:
	_msg_clock = maxf(_msg_clock - delta, 0.0)
	var playing: bool = main != null and main.game_started and (main.game_menu == null or not main.game_menu.opened)
	for i in range(trees.size()):
		var t: Dictionary = trees[i]
		var node: Node3D = t["node"]
		var mi: MeshInstance3D = t["mesh"]
		match str(t["state"]):
			"debout":
				if float(t["shake"]) > 0.001:
					t["shake"] = float(t["shake"]) * pow(0.02, delta)
					var wob: float = sin(Time.get_ticks_msec() * 0.03) * float(t["shake"])
					mi.basis = Basis(t["shake_axis"], wob).scaled(mi.scale)
				elif float(t["shake"]) > 0.0:
					t["shake"] = 0.0
					mi.basis = Basis.IDENTITY.scaled(mi.scale)
			"chute":
				t["fall"] = float(t["fall"]) + delta
				var u: float = float(t["fall"])
				# Lente au départ, puis de plus en plus vite ; petit rebond au sol.
				var ang: float = minf(pow(u / 1.5, 2.2), 1.0) * deg_to_rad(86.0)
				if u > 1.5:
					ang = deg_to_rad(86.0) - sin(clampf((u - 1.5) / 0.35, 0.0, 1.0) * PI) * deg_to_rad(5.0)
				mi.basis = Basis(t["fall_axis"], ang).scaled(mi.scale)
				if u >= 1.5 and not t.get("landed", false):
					t["landed"] = true
					(t["stump"] as Node3D).visible = true
					if main.combat_v28 != null:
						var land: Vector3 = node.global_position + (t["fall_dir"] as Vector3) * 3.0
						land.y = main._height_at(land.x, land.z) + 0.2
						main.combat_v28.puff(land, Color(0.5, 0.42, 0.3))
					_loot(t)
				if u > 7.0:
					# Le tronc s'enfonce et disparaît ; la souche reste.
					var k: float = clampf((u - 7.0) / 1.5, 0.0, 1.0)
					mi.position.y = -k * 1.2
					if k >= 1.0:
						mi.visible = false
						(t["notch"] as Node3D).visible = false
						t["state"] = "souche"
						t["regrow"] = REGROW
			"souche":
				if playing:
					t["regrow"] = float(t["regrow"]) - delta
				if float(t["regrow"]) <= 0.0 and _player_far(node.global_position):
					_restore(t)


func _player_far(p: Vector3) -> bool:
	var me: Vector3 = main._player_pos_v27()
	return Vector2(me.x - p.x, me.z - p.z).length() > 18.0


func _restore(t: Dictionary) -> void:
	var mi: MeshInstance3D = t["mesh"]
	mi.visible = true
	mi.position = Vector3.ZERO
	mi.basis = Basis.IDENTITY.scaled(mi.scale)
	(t["notch"] as Node3D).visible = true
	(t["stump"] as Node3D).visible = false
	(t["body"] as StaticBody3D).collision_layer = 1
	t["hp"] = int(HP[str(t["kind"])])
	t["state"] = "debout"
	t["shake"] = 0.0
	t["landed"] = false
	t["regrow"] = 0.0


func _cut_instantly(t: Dictionary, regrow: float) -> void:
	var mi: MeshInstance3D = t["mesh"]
	mi.visible = false
	(t["notch"] as Node3D).visible = false
	(t["stump"] as Node3D).visible = true
	(t["body"] as StaticBody3D).collision_layer = 0
	t["state"] = "souche"
	t["regrow"] = regrow


## PC : texte d'invite près d'un arbre à abattre.
func prompt(p: Vector3) -> String:
	for t in trees:
		if str(t["state"]) != "debout":
			continue
		var q: Vector3 = (t["node"] as Node3D).global_position
		if Vector2(q.x - p.x, q.z - p.z).length() < 2.0 and absf(q.y - p.y) < 2.0:
			if main.inventory_v28.equipped == "hache":
				return "Clic : abattre l'arbre (%s)" % ("encore %d coups" % int(t["hp"]) if int(t["hp"]) > 1 else "dernier coup !")
			return "Arbre marqué d'une entaille : il s'abat à la hache"
	return ""


# =================================================================== sauvegarde

func serialize() -> Dictionary:
	var cut := {}
	for i in range(trees.size()):
		var t: Dictionary = trees[i]
		if str(t["state"]) != "debout":
			cut[str(i)] = maxf(float(t["regrow"]), 0.0) if str(t["state"]) == "souche" else REGROW
	return {"coupes": cut, "total": total_cut}


func load_data(d: Dictionary) -> void:
	var c: Variant = d.get("coupes", {})
	_pending = c if c is Dictionary else {}
	total_cut = int(d.get("total", 0))
	_apply_pending()


func _apply_pending() -> void:
	if trees.is_empty():
		return
	for t in trees:
		_restore(t)
	for k in _pending:
		var i: int = int(k)
		if i >= 0 and i < trees.size():
			_cut_instantly(trees[i], float(_pending[k]))
