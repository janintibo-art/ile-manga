extends Node3D
## V47 : Forgefer, la cité des nains, sous la Montagne de Feu (70 m sous la mer, comme les
## autres souterrains : l'ambiance « sous terre » s'y applique toute seule).
## La Grande Halle : une nef de piliers gravés de runes, deux rigoles de lave qui éclairent
## tout d'orange, des bannières rouge et or. Au fond, sur une estrade, le trône du roi Thorgal.
## À l'est, la Forge Royale (foyer de lave, enclume géante, chaînes) et l'échoppe d'Orsik le
## joaillier ; à l'ouest, la taverne de la Chope Ardente et le coin des runes de Nori.
## On y entre par la Grande Porte de la terrasse (quand Bramm l'a ouverte), on en sort par
## le couloir d'entrée.

const Habitants = preload("res://scripts/pnj/nains_habitants_v47.gd")
const Rocks = preload("res://scripts/rocks_v26.gd")
const Y: float = -70.0
const X0: float = -26.0
const X1: float = 26.0
const Z0: float = -24.0
const Z1: float = 26.0
const H: float = 14.0
const PILLAR_X := [-9.0, 9.0]
const PILLAR_Z := [-16.0, -7.0, 2.0, 11.0, 20.0]

var n: Node3D                  # nains_v46.gd (matériaux, formes, collisions)
var main: Node
var d: Node
var s: Node3D
var habitants: Array = []
var by_id: Dictionary = {}
var _banner_mat: StandardMaterial3D
var _gem_mats: Array = []
var _clock: float = 0.0


func setup(nains: Node3D) -> void:
	n = nains
	main = n.main
	d = main.donjon_v35


func entry_point() -> Vector3:
	return s.to_global(Vector3(0, 0.1, 29.5))


func entry_facing() -> Vector3:
	return (s.to_global(Vector3(0, 0, -1)) - s.to_global(Vector3.ZERO)).normalized()


func build() -> void:
	s = Node3D.new()
	s.name = "Grande_Halle"
	add_child(s)
	var pk: Vector3 = n.ile.peak_world()
	s.global_position = Vector3(pk.x, Y, pk.z)
	s.rotation.y = n.forge_root.rotation.y
	var stone: Material = n._mat("pierre")
	var floor_m: Material = n._mat("dalle")
	# Sol, plafond, murs
	n._solid(s, Vector3(X1 - X0, 1.0, Z1 - Z0 + 10.0), Vector3(0, -0.5, (Z0 + Z1 + 10.0) * 0.5), floor_m)
	n._solid(s, Vector3(X1 - X0 + 2.0, 1.0, Z1 - Z0 + 2.0), Vector3(0, H + 0.5, (Z0 + Z1) * 0.5), stone)
	n._solid(s, Vector3(X1 - X0 + 2.0, H, 1.0), Vector3(0, H * 0.5, Z0 - 0.5), stone)
	n._solid(s, Vector3(1.0, H, Z1 - Z0), Vector3(X0 - 0.5, H * 0.5, (Z0 + Z1) * 0.5), stone)
	n._solid(s, Vector3(1.0, H, Z1 - Z0), Vector3(X1 + 0.5, H * 0.5, (Z0 + Z1) * 0.5), stone)
	# Mur sud, percé du couloir d'entrée (x de -3 à 3)
	n._solid(s, Vector3(23.0, H, 1.0), Vector3(-14.5, H * 0.5, Z1 + 0.5), stone)
	n._solid(s, Vector3(23.0, H, 1.0), Vector3(14.5, H * 0.5, Z1 + 0.5), stone)
	n._solid(s, Vector3(6.0, H - 6.0, 1.0), Vector3(0, 6.0 + (H - 6.0) * 0.5, Z1 + 0.5), stone)
	# Le couloir d'entrée : voûte basse, porte de fer au fond (la sortie)
	n._solid(s, Vector3(1.0, 6.0, 9.0), Vector3(-3.5, 3.0, Z1 + 4.5), stone)
	n._solid(s, Vector3(1.0, 6.0, 9.0), Vector3(3.5, 3.0, Z1 + 4.5), stone)
	n._solid(s, Vector3(8.0, 1.0, 9.0), Vector3(0, 6.5, Z1 + 4.5), stone)
	n._solid(s, Vector3(8.0, 6.0, 1.0), Vector3(0, 3.0, Z1 + 9.5), stone)
	for sx in [-1.0, 1.0]:
		n._mesh(s, n._box_mesh(Vector3(2.9, 5.2, 0.2)), n._mat("fer"), Vector3(sx * 1.48, 2.6, Z1 + 8.9))
		n._mesh(s, n._cyl(0.18, 0.18, 0.06, 12), n._mat("or"), Vector3(sx * 0.35, 2.6, Z1 + 8.78), Vector3(PI * 0.5, 0, 0))
	for k in range(5):
		n._mesh(s, n._box_mesh(Vector3(5.8, 0.12, 0.12)), n._mat("bronze"), Vector3(0, 0.6 + k * 1.1, Z1 + 8.75))
	_torch(Vector3(-3.0, 3.2, Z1 + 3.0))
	_torch(Vector3(3.0, 3.2, Z1 + 3.0))
	# Plinthes et frise dorée le long des murs
	for zz in [Z0 + 0.15, Z1 - 0.15]:
		n._mesh(s, n._box_mesh(Vector3(X1 - X0, 0.5, 0.3)), stone, Vector3(0, 0.25, zz))
		n._mesh(s, n._box_mesh(Vector3(X1 - X0, 0.15, 0.1)), n._mat("or"), Vector3(0, H - 2.0, zz))
	for xx in [X0 + 0.15, X1 - 0.15]:
		n._mesh(s, n._box_mesh(Vector3(0.3, 0.5, Z1 - Z0)), stone, Vector3(xx, 0.25, (Z0 + Z1) * 0.5))
		n._mesh(s, n._box_mesh(Vector3(0.1, 0.15, Z1 - Z0)), n._mat("or"), Vector3(xx, H - 2.0, (Z0 + Z1) * 0.5))
	# Poutres de pierre au plafond
	for zb in range(int(Z0) + 4, int(Z1), 9):
		n._mesh(s, n._box_mesh(Vector3(X1 - X0, 0.9, 1.0)), stone, Vector3(0, H - 0.45, float(zb)))
	_pillars()
	_chandeliers()
	_lava_channels()
	_throne()
	_forge_royale()
	_tavern()
	_runes()
	_jeweler()
	_maisons_v85()
	# Grand tapis rouge dans l'allée centrale
	var rug := StandardMaterial3D.new()
	rug.albedo_color = Color(0.45, 0.08, 0.08)
	rug.roughness = 0.95
	n._mesh(s, n._box_mesh(Vector3(3.6, 0.03, Z1 - Z0 - 9.0)), rug, Vector3(0, 0.02, (Z0 + 7.0 + Z1) * 0.5))
	n._mesh(s, n._box_mesh(Vector3(3.9, 0.025, Z1 - Z0 - 9.0)), n._mat("or"), Vector3(0, 0.01, (Z0 + 7.0 + Z1) * 0.5))
	# Sortie
	d._interactions.append({"id": "sortir_forgefer", "pos": s.to_global(Vector3(0, 0, Z1 + 7.0)), "radius": 2.4,
		"text": "E : sortir de Forgefer", "vr": "Gâchette : sortir de Forgefer", "call": _leave})
	d.spawn["forgefer"] = [entry_point(), entry_facing()]
	_spawn_dwarves()


func _leave() -> void:
	var to_sea: Vector3 = (n.forge_root.to_global(Vector3(0, 0, 1)) - n.forge_root.global_position).normalized()
	var out: Vector3 = n.gate_front + to_sea * 1.5
	out.y = n._ground(out.x, out.z) + 0.1
	await d._travel(out, to_sea)
	d._say("Le grand air, enfin… s'il sentait autre chose que le soufre.", 3.0)


# =================================================================== architecture

## V85 : les maisons des nains, creusées dans les murs de la halle (trois de chaque côté) : une
## porte de bois cerclée de fer dans un cadre de pierre, une rune qui luit au-dessus. On y entre
## comme dans toutes les maisons (maisons_v81.gd).
const MAISONS_V85 := [[-1.0, -19.5, 6.6, 5.8], [-1.0, 2.0, 6.0, 5.0], [-1.0, 21.0, 7.2, 6.0],
	[1.0, -19.5, 6.4, 5.4], [1.0, 4.5, 7.0, 5.6], [1.0, 21.0, 6.0, 5.4]]


func _maisons_v85() -> void:
	var stone: Material = n._mat("pierre")
	var wood: Material = n._mat("bois")
	var iron: Material = n._mat("fer")
	for e in MAISONS_V85:
		var sx: float = float(e[0])
		var z: float = float(e[1])
		var inner: float = X0 if sx < 0.0 else X1
		var di: float = -sx
		var x := func(off: float) -> float:
			return inner + di * off
		n._mesh(s, n._box_mesh(Vector3(0.5, 0.08, 1.7)), stone, Vector3(x.call(0.62), 0.04, z))
		for sz in [-1.0, 1.0]:
			n._mesh(s, n._box_mesh(Vector3(0.44, 2.75, 0.32)), stone, Vector3(x.call(0.22), 1.375, z + sz * 0.8))
		n._mesh(s, n._box_mesh(Vector3(0.46, 0.45, 1.95)), stone, Vector3(x.call(0.23), 2.95, z))
		n._mesh(s, n._box_mesh(Vector3(0.08, 2.5, 1.28)), wood, Vector3(x.call(0.36), 1.25, z))
		for k in range(3):
			n._mesh(s, n._box_mesh(Vector3(0.1, 0.08, 1.3)), iron, Vector3(x.call(0.41), 0.45 + k * 0.8, z))
		n._mesh(s, n._cyl(0.07, 0.07, 0.03, 12), n._mat("bronze"), Vector3(x.call(0.42), 1.15, z + 0.38), Vector3(0, 0, PI * 0.5))
		n._mesh(s, n._cyl(0.17, 0.17, 0.04, 6), n._mat("rune"), Vector3(x.call(0.3), 3.45, z), Vector3(0, 0, PI * 0.5))
		var door: Vector3 = s.to_global(Vector3(x.call(0.45), 0.05, z))
		var out: Vector3 = s.global_basis * Vector3(di, 0, 0)
		preload("res://scripts/azur_kit_v56.gd").note_v81(door, out, float(e[2]), float(e[3]), "nain", 1)


func _torch(at: Vector3) -> void:
	n._mesh(s, n._cyl(0.06, 0.04, 0.6, 8), n._mat("fer"), at)
	n._mesh(s, n._sphere(0.12, 8), n._mat("braise"), at + Vector3.UP * 0.35)
	n._pending_fires.append([s, at + Vector3.UP * 0.42, 0.12, 14])
	n._light(s, at + Vector3(0, 0.6, 0), Color(1.0, 0.6, 0.3), 1.4, 9.0)


func _pillars() -> void:
	var stone: Material = n._mat("pierre")
	var rune: Material = n._mat("rune")
	var gold: Material = n._mat("or")
	for px in PILLAR_X:
		for pz in PILLAR_Z:
			var at := Vector3(px, 0, pz)
			n._solid(s, Vector3(2.2, H, 2.2), at + Vector3.UP * H * 0.5, stone)
			n._mesh(s, n._box_mesh(Vector3(2.9, 0.8, 2.9)), stone, at + Vector3.UP * 0.4)
			n._mesh(s, n._box_mesh(Vector3(2.9, 0.8, 2.9)), stone, at + Vector3.UP * (H - 1.4))
			n._mesh(s, n._box_mesh(Vector3(2.35, 0.25, 2.35)), gold, at + Vector3.UP * 3.0)
			n._mesh(s, n._box_mesh(Vector3(2.35, 0.25, 2.35)), gold, at + Vector3.UP * 7.5)
			# Runes gravées qui rougeoient, sur les deux faces de la nef
			# Rune naine (ᛉ) : un trait vertical, deux branches en V vers le haut
			for fz in [-1.0, 1.0]:
				n._mesh(s, n._box_mesh(Vector3(0.12, 2.4, 0.04)), rune, at + Vector3(0, 5.2, fz * 1.12))
				for sx in [-1.0, 1.0]:
					n._mesh(s, n._box_mesh(Vector3(0.1, 1.0, 0.04)), rune, at + Vector3(sx * 0.3, 6.15, fz * 1.12), Vector3(0, 0, -sx * 0.6))
	# Bannières rouge et or entre les piliers
	_banner_mat = StandardMaterial3D.new()
	_banner_mat.albedo_color = Color(0.55, 0.06, 0.08)
	_banner_mat.roughness = 0.9
	_banner_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for px2 in PILLAR_X:
		for k in range(PILLAR_Z.size() - 1):
			var z: float = (float(PILLAR_Z[k]) + float(PILLAR_Z[k + 1])) * 0.5
			var bx: float = float(px2) * 1.1
			n._mesh(s, n._box_mesh(Vector3(0.05, 4.2, 2.2)), _banner_mat, Vector3(bx, H - 4.2, z))
			n._mesh(s, n._box_mesh(Vector3(0.07, 0.6, 0.6)), gold, Vector3(bx, H - 3.8, z), Vector3(PI * 0.25, 0, 0))
			n._mesh(s, n._cyl(0.05, 0.05, 2.5, 6), n._mat("bois"), Vector3(bx, H - 2.05, z), Vector3(PI * 0.5, 0, 0))


## Lustres de fer au-dessus de la nef, appliques le long des murs.
func _chandeliers() -> void:
	var iron: Material = n._mat("fer")
	var flame: Material = n._mat("braise")
	for cz in [-12.0, -2.5, 6.5, 15.5]:
		var c := Vector3(0, H - 4.0, cz)
		for k in range(6):
			n._mesh(s, n._box_mesh(Vector3(0.06, 0.25, 0.12)), iron, Vector3(0, H - 0.3 - k * 0.3, cz), Vector3(0, (k % 2) * PI * 0.5, 0))
		var ring := TorusMesh.new()
		ring.inner_radius = 1.5
		ring.outer_radius = 1.65
		n._mesh(s, ring, iron, c)
		for k2 in range(8):
			var a: float = TAU * k2 / 8.0
			var q := c + Vector3(cos(a) * 1.57, 0.12, sin(a) * 1.57)
			n._mesh(s, n._cyl(0.05, 0.05, 0.22, 6), n._cloth_mat(Color(0.95, 0.9, 0.8)), q + Vector3.UP * 0.05)
			n._mesh(s, n._sphere(0.06, 6), flame, q + Vector3.UP * 0.22)
		n._light(s, c + Vector3(0, -0.6, 0), Color(1.0, 0.72, 0.45), 3.2, 22.0)
	for sx in [-1.0, 1.0]:
		for k3 in range(PILLAR_Z.size()):
			var wz: float = float(PILLAR_Z[k3]) + 4.5
			if wz > Z1 - 2.0:
				continue
			var wp := Vector3(sx * (X1 - 0.5), 3.4, wz)
			n._mesh(s, n._box_mesh(Vector3(0.4, 0.15, 0.4)), iron, wp)
			n._mesh(s, n._cyl(0.18, 0.1, 0.3, 8), iron, wp + Vector3(-sx * 0.15, 0.2, 0))
			n._mesh(s, n._sphere(0.14, 8), flame, wp + Vector3(-sx * 0.15, 0.38, 0), Vector3.ZERO, Vector3(1, 0.6, 1))
			n._pending_fires.append([s, wp + Vector3(-sx * 0.15, 0.45, 0), 0.14, 12])
			n._light(s, wp + Vector3(-sx * 0.8, 0.6, 0), Color(1.0, 0.6, 0.3), 1.8, 11.0)


## Deux rigoles de lave le long de la nef, entre des murets de pierre.
func _lava_channels() -> void:
	var stone: Material = n._mat("pierre")
	for cx in [-15.0, 15.0]:
		var length: float = Z1 - Z0 - 6.0
		var cz: float = (Z0 + 2.0 + Z1 - 4.0) * 0.5
		var lava := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(1.6, length)
		pm.subdivide_depth = 8
		lava.mesh = pm
		lava.material_override = n._lava_mat
		s.add_child(lava)
		lava.position = Vector3(cx, 0.08, cz)
		for sx in [-1.0, 1.0]:
			n._solid(s, Vector3(0.4, 0.7, length), Vector3(cx + sx * 1.0, 0.35, cz), stone)
		n._solid(s, Vector3(2.4, 0.7, 0.4), Vector3(cx, 0.35, cz - length * 0.5), stone)
		n._solid(s, Vector3(2.4, 0.7, 0.4), Vector3(cx, 0.35, cz + length * 0.5), stone)
		for k in range(4):
			var lz: float = cz - length * 0.5 + (k + 0.5) * length / 4.0
			n._light(s, Vector3(cx, 1.6, lz), Color(1.0, 0.45, 0.15), 2.2, 13.0)
		n._embers(s, Vector3(cx, 0.3, cz), Vector3(0.6, 0.1, length * 0.5), 30)


## L'estrade et le trône du roi Thorgal, au fond de la halle.
func _throne() -> void:
	var stone: Material = n._mat("pierre")
	var gold: Material = n._mat("or")
	n._solid(s, Vector3(14.0, 1.2, 7.0), Vector3(0, 0.6, Z0 + 3.5), stone)
	for k in range(3):
		n._solid(s, Vector3(8.0, 0.4 * (k + 1), 0.7), Vector3(0, 0.2 * (k + 1), Z0 + 7.0 + (2 - k) * 0.7 + 0.35), stone)
	var th := Node3D.new()
	th.name = "Trone"
	s.add_child(th)
	th.position = Vector3(0, 1.2, Z0 + 2.2)
	n._solid(th, Vector3(2.6, 1.0, 1.8), Vector3(0, 0.5, 0), stone)
	n._mesh(th, n._box_mesh(Vector3(2.6, 3.6, 0.5)), stone, Vector3(0, 2.3, -0.65))
	n._mesh(th, n._box_mesh(Vector3(2.2, 0.15, 1.5)), _banner_mat, Vector3(0, 1.05, 0.05))
	for sx in [-1.0, 1.0]:
		n._mesh(th, n._box_mesh(Vector3(0.4, 0.8, 1.6)), stone, Vector3(sx * 1.2, 1.3, 0))
		n._mesh(th, n._sphere(0.28, 10), gold, Vector3(sx * 1.2, 1.85, 0.6))
	n._mesh(th, n._cyl(0.0, 1.0, 1.3, 4), gold, Vector3(0, 4.7, -0.65), Vector3(0, PI * 0.25, 0))
	n._mesh(th, n._sphere(0.22, 10), n._mat("rune"), Vector3(0, 3.6, -0.38))
	# Grand marteau d'or sculpté au mur, braseros, bannières royales
	n._mesh(s, n._box_mesh(Vector3(0.5, 7.0, 0.4)), n._mat("bois"), Vector3(0, 8.0, Z0 + 0.3))
	n._mesh(s, n._box_mesh(Vector3(3.6, 1.8, 0.6)), gold, Vector3(0, 11.0, Z0 + 0.35))
	for sx2 in [-1.0, 1.0]:
		var bz := Vector3(sx2 * 4.5, 1.2, Z0 + 5.5)
		n._brazier(s, bz)
		for k2 in range(2):
			var bxx: float = sx2 * (8.0 + k2 * 6.0)
			n._mesh(s, n._box_mesh(Vector3(2.4, 6.0, 0.06)), _banner_mat, Vector3(bxx, 8.0, Z0 + 0.1))
			n._mesh(s, n._cyl(0.4, 0.4, 0.07, 6), gold, Vector3(bxx, 8.8, Z0 + 0.16), Vector3(PI * 0.5, 0, 0))
	n._light(s, Vector3(0, 6.0, Z0 + 6.0), Color(1.0, 0.75, 0.45), 2.0, 16.0)


## La Forge Royale, à l'est : foyer nourri par la lave, enclume géante, chaînes.
func _forge_royale() -> void:
	var stone: Material = n._mat("pierre")
	var fr := Node3D.new()
	fr.name = "Forge_Royale"
	s.add_child(fr)
	fr.position = Vector3(X1 - 3.0, 0, -6.0)
	n._solid(fr, Vector3(3.0, 3.0, 7.0), Vector3(1.0, 1.5, 0), stone)
	var hearth := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1.8, 5.6)
	hearth.mesh = pm
	hearth.material_override = n._lava_mat
	fr.add_child(hearth)
	hearth.position = Vector3(1.0, 3.02, 0)
	n._mesh(fr, n._cyl(1.2, 2.2, 8.0, 8), stone, Vector3(1.3, 7.0, 0))
	n._embers(fr, Vector3(1.0, 3.2, 0), Vector3(0.8, 0.2, 2.6), 24)
	n._light(fr, Vector3(-1.5, 4.0, 0), Color(1.0, 0.45, 0.15), 3.0, 14.0)
	# L'enclume géante
	n._solid(fr, Vector3(1.4, 1.0, 1.0), Vector3(-4.0, 0.5, 0), n._mat("fer"))
	n._mesh(fr, n._box_mesh(Vector3(2.6, 0.5, 1.0)), n._mat("fer"), Vector3(-4.0, 1.25, 0))
	n._mesh(fr, n._cyl(0.0, 0.32, 0.9, 8), n._mat("fer"), Vector3(-2.3, 1.25, 0), Vector3(0, 0, -PI * 0.5))
	# Chaînes et crochet qui pendent du plafond
	for k in range(14):
		n._mesh(fr, n._box_mesh(Vector3(0.08, 0.35, 0.18)), n._mat("fer"), Vector3(-1.0, H - 0.4 - k * 0.42, 1.8), Vector3(0, (k % 2) * PI * 0.5, 0))
	n._mesh(fr, n._cyl(0.02, 0.1, 0.5, 6), n._mat("fer"), Vector3(-1.0, H - 6.4, 1.8))
	# Râtelier d'outils et lingots
	n._mesh(fr, n._box_mesh(Vector3(0.3, 2.4, 3.0)), n._mat("bois"), Vector3(2.4, 1.2, 5.5))
	for k2 in range(5):
		n._mesh(fr, n._cyl(0.025, 0.025, 1.3, 6), n._mat("bois"), Vector3(2.0, 1.4, 4.4 + k2 * 0.55))
		n._mesh(fr, n._box_mesh(Vector3(0.2, 0.2, 0.25)), n._mat("fer"), Vector3(2.0, 2.05, 4.4 + k2 * 0.55))
	for k3 in range(6):
		n._mesh(fr, n._box_mesh(Vector3(0.6, 0.18, 0.25)), n._mat("or") if k3 % 3 == 0 else n._mat("fer"), Vector3(-4.0 + (k3 % 3) * 0.65, 0.09 + (k3 / 3) * 0.18, 3.0))


## La Chope Ardente, à l'ouest : comptoir, tonneaux, tables et chopes.
func _tavern() -> void:
	var wood: Material = n._mat("bois")
	var t := Node3D.new()
	t.name = "Chope_Ardente"
	s.add_child(t)
	t.position = Vector3(X0 + 3.0, 0, 13.0)
	n._solid(t, Vector3(1.0, 1.1, 8.0), Vector3(1.6, 0.55, 0), wood)
	n._mesh(t, n._box_mesh(Vector3(1.3, 0.1, 8.2)), wood, Vector3(1.6, 1.15, 0))
	for k in range(6):
		var bz: float = -3.5 + k * 1.4
		n._mesh(t, n._cyl(0.55, 0.55, 1.2, 14), wood, Vector3(-1.9, 0.9, bz), Vector3(0, 0, PI * 0.5))
		n._mesh(t, n._cyl(0.57, 0.57, 0.07, 14), n._mat("fer"), Vector3(-1.5, 0.9, bz), Vector3(0, 0, PI * 0.5))
		n._mesh(t, n._cyl(0.06, 0.06, 0.2, 6), n._mat("bronze"), Vector3(-1.2, 0.7, bz), Vector3(0, 0, PI * 0.5))
	for k2 in range(5):
		n._mesh(t, n._cyl(0.06, 0.06, 0.18, 8), n._mat("bois"), Vector3(1.5 + (k2 % 2) * 0.2, 1.29, -2.5 + k2 * 1.2))
	# Tables et bancs
	for k3 in range(3):
		var tp := Vector3(6.5, 0, -3.0 + k3 * 4.0)
		n._solid(t, Vector3(1.4, 0.85, 2.6), tp + Vector3.UP * 0.425, wood)
		for sx in [-1.0, 1.0]:
			n._mesh(t, n._box_mesh(Vector3(0.4, 0.45, 2.4)), wood, tp + Vector3(sx * 1.2, 0.22, 0))
		for k4 in range(3):
			n._mesh(t, n._cyl(0.06, 0.06, 0.16, 8), wood, tp + Vector3(0.3 - (k4 % 2) * 0.6, 0.93, -0.8 + k4 * 0.8))
			n._mesh(t, n._cyl(0.062, 0.062, 0.03, 8), n._cloth_mat(Color(0.98, 0.96, 0.9)), tp + Vector3(0.3 - (k4 % 2) * 0.6, 1.02, -0.8 + k4 * 0.8))
	# Enseigne et lustre de fer
	n._mesh(t, n._box_mesh(Vector3(0.1, 1.0, 2.4)), wood, Vector3(2.4, 4.2, 0))
	n._mesh(t, n._cyl(0.25, 0.22, 0.4, 10), n._mat("or"), Vector3(2.45, 4.2, 0), Vector3(0, 0, PI * 0.5))
	var ring := TorusMesh.new()
	ring.inner_radius = 1.0
	ring.outer_radius = 1.1
	n._mesh(t, ring, n._mat("fer"), Vector3(5.5, 6.5, 1.0))
	for k5 in range(6):
		var a: float = TAU * k5 / 6.0
		n._mesh(t, n._sphere(0.09, 8), n._mat("braise"), Vector3(5.5 + cos(a) * 1.05, 6.65, 1.0 + sin(a) * 1.05))
	n._light(t, Vector3(5.5, 5.8, 1.0), Color(1.0, 0.65, 0.35), 2.2, 13.0)


## Le coin des runes de Nori : trois menhirs gravés de runes bleues, un lutrin.
func _runes() -> void:
	var stone: Material = n._mat("pierre")
	var blue := StandardMaterial3D.new()
	blue.albedo_color = Color(0.35, 0.8, 1.0)
	blue.emission_enabled = true
	blue.emission = Color(0.3, 0.75, 1.0)
	blue.emission_energy_multiplier = 2.5
	var r := Node3D.new()
	r.name = "Coin_des_runes"
	s.add_child(r)
	r.position = Vector3(X0 + 5.0, 0, -11.0)
	for k in range(3):
		var mp := Vector3(-2.0, 0, -4.0 + k * 4.0)
		n._solid(r, Vector3(0.9, 3.4, 1.6), mp + Vector3.UP * 1.7, stone, Vector3(0, 0.1 * (k - 1), 0))
		for j in range(4):
			n._mesh(r, n._box_mesh(Vector3(0.04, 0.35, 0.08 + 0.08 * (j % 2))), blue, mp + Vector3(0.47, 0.8 + j * 0.6, -0.3 + (j % 3) * 0.3))
	n._mesh(r, n._cyl(0.15, 0.25, 1.1, 8), stone, Vector3(2.0, 0.55, 0))
	n._mesh(r, n._box_mesh(Vector3(0.9, 0.08, 0.7)), n._mat("bois"), Vector3(2.0, 1.15, 0), Vector3(0, 0, 0.35))
	n._mesh(r, n._box_mesh(Vector3(0.6, 0.04, 0.45)), n._cloth_mat(Color(0.85, 0.78, 0.6)), Vector3(2.0, 1.21, 0), Vector3(0, 0, 0.35))
	var l: OmniLight3D = n._light(r, Vector3(0.0, 2.6, 0), Color(0.45, 0.75, 1.0), 1.6, 10.0)
	l.name = "Lueur_runes"


## L'échoppe d'Orsik : un comptoir vitré, des gemmes qui brillent.
func _jeweler() -> void:
	var wood: Material = n._mat("bois")
	var j := Node3D.new()
	j.name = "Joaillier"
	s.add_child(j)
	j.position = Vector3(X1 - 4.0, 0, 13.0)
	n._solid(j, Vector3(1.0, 1.1, 5.0), Vector3(-1.2, 0.55, 0), wood)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.8, 0.9, 1.0, 0.25)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	n._mesh(j, n._box_mesh(Vector3(0.9, 0.35, 4.8)), glass, Vector3(-1.2, 1.28, 0))
	var cols := [Color(0.9, 0.1, 0.15), Color(0.2, 0.5, 1.0), Color(0.2, 0.9, 0.4), Color(1.0, 0.85, 0.3), Color(0.8, 0.4, 1.0)]
	for k in range(10):
		var gm := StandardMaterial3D.new()
		var c: Color = cols[k % cols.size()]
		gm.albedo_color = c
		gm.roughness = 0.05
		gm.metallic = 0.2
		gm.emission_enabled = true
		gm.emission = c
		gm.emission_energy_multiplier = 1.2
		_gem_mats.append(gm)
		n._mesh(j, n._sphere(0.07, 8), gm, Vector3(-1.2 + (k % 2) * 0.25 - 0.12, 1.18, -2.0 + k * 0.42), Vector3.ZERO, Vector3(1, 0.7, 1))
	# Coffre-fort et balance
	n._mesh(j, n._box_mesh(Vector3(1.2, 1.0, 1.0)), n._mat("fer"), Vector3(1.4, 0.5, -1.5))
	n._mesh(j, n._cyl(0.15, 0.15, 0.06, 12), n._mat("or"), Vector3(1.4, 0.7, -0.98), Vector3(PI * 0.5, 0, 0))
	n._mesh(j, n._cyl(0.02, 0.02, 0.6, 6), n._mat("or"), Vector3(-1.2, 1.75, 1.8))
	n._mesh(j, n._box_mesh(Vector3(0.04, 0.04, 0.7)), n._mat("or"), Vector3(-1.2, 2.05, 1.8))
	n._light(j, Vector3(-1.0, 3.0, 0), Color(1.0, 0.85, 0.6), 1.6, 9.0)


# =================================================================== habitants

func _spawn_dwarves() -> void:
	var L := {
		"trone": Vector3(0, 1.2, Z0 + 5.6), "trone2": Vector3(-2.5, 1.2, Z0 + 5.0),
		"taverne": Vector3(X0 + 6.2, 0, 11.0), "taverne2": Vector3(X0 + 6.2, 0, 15.5), "taverne3": Vector3(X0 + 9.0, 0, 13.0),
		"runes": Vector3(X0 + 6.5, 0, -11.0), "runes2": Vector3(X0 + 6.0, 0, -14.5),
		"joaillier": Vector3(X1 - 6.8, 0, 13.0), "joaillier2": Vector3(X1 - 6.8, 0, 10.0),
		"forge": Vector3(X1 - 8.3, 0, -6.0), "forge2": Vector3(X1 - 8.0, 0, -3.0),
		"nef1": Vector3(0, 0, 18.0), "nef2": Vector3(0, 0, 6.0), "nef3": Vector3(0, 0, -6.0), "nef4": Vector3(2.0, 0, -12.0),
	}
	var pts := {}
	for k in L:
		pts[k] = s.to_global(L[k])
	var homes := {
		"trone": [["trone", "trone2"], "trone"],
		"taverne": [["taverne", "taverne2", "taverne3"], "taverne"],
		"runes": [["runes", "runes2"], "runes"],
		"joaillier": [["joaillier", "joaillier2"], "joaillier"],
	}
	for entry in Habitants.DEDANS:
		var h: Array = homes[str(entry["coin"])]
		var sub: Dictionary = {}
		for k2 in h[0]:
			sub[k2] = pts[k2]
		_spawn_one(Habitants.complete(entry["data"]), sub, str(h[1]))
	var walk_sets := [["forge", "forge2", "nef3"], ["nef1", "nef2", "nef3", "nef4"], ["taverne3", "nef2", "nef1"]]
	for i in range(3):
		var sub2: Dictionary = {}
		for k3 in walk_sets[i]:
			sub2[k3] = pts[k3]
		_spawn_one(Habitants.passant(4 + i), sub2, str(walk_sets[i][0]))
	# Le roi regarde sa halle ; Ulfa son comptoir ; Nori ses menhirs ; Orsik son échoppe
	_face("thorgal", "trone", s.to_global(Vector3(0, 1.2, 10.0)))
	_face("ulfa", "taverne", s.to_global(Vector3(X0 + 9.5, 0, 11.0)))
	_face("nori", "runes", s.to_global(Vector3(X0 + 3.0, 0, -11.0)))
	_face("orsik", "joaillier", s.to_global(Vector3(0, 0, 13.0)))


func _spawn_one(data: Dictionary, pts: Dictionary, start: String) -> void:
	var graph := {}
	for k in pts:
		graph[k] = pts.keys().filter(func(x): return x != k)
	var npc: Node3D = n.PnjScript.new()
	main.add_child(npc)
	npc.setup(main, data, pts, graph, start)
	npc.sleep_far = 60.0
	npc.idle_clock = randf_range(2.0, 12.0)
	var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
	if saved is Dictionary and not (saved as Dictionary).is_empty():
		npc.load_data(saved)
	main.npcs_v31.append(npc)
	habitants.append(npc)
	by_id[str(data["id"])] = npc


func _face(id: String, point: String, target: Vector3) -> void:
	if by_id.has(id):
		by_id[id].face_at[point] = target


func _process(delta: float) -> void:
	_clock += delta
	if _gem_mats.is_empty() or main == null or not main.game_started:
		return
	for i in range(_gem_mats.size()):
		(_gem_mats[i] as StandardMaterial3D).emission_energy_multiplier = 1.0 + 0.5 * sin(_clock * 2.0 + i)
