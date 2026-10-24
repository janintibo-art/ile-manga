extends "res://scripts/enigmes_v69.gd"
## V69 : la Pyramide de Rê (les Égyptiens de Per-Hâpy) — le voyage de Rê à travers la nuit.
## Dehors : le Sphinx pose trois devinettes ; quand on a tout trouvé, la porte de la pyramide
## s'ouvre. Dedans (loin sous le plateau) :
##  1. le vestibule (la barque de Rê peinte au mur, l'escalier qui remonte) ;
##  2. la salle de Thot : trois tambours de pierre à six signes ; écrire le nom du roi comme Thot
##     l'a écrit sur le papyrus (l'ibis, l'œil d'Horus, le soleil) ;
##  3. la Grande Galerie : la lumière de Rê entre par un conduit ; tourner les miroirs de bronze
##     pour la mener jusqu'au disque solaire de la porte ;
##  4. la salle d'Osiris et les quatre chapelles d'Isis : Seth a dispersé le corps d'Osiris ;
##     retrouver les quatre morceaux (la chapelle de Serket et ses scorpions ; le sol de sable
##     qui s'effondre — suivre les scarabées ; deux blocs à pousser sur les dalles d'Isis ; la
##     chapelle obscure et ses momies) et les rendre au sarcophage ;
##  5. la Salle des Deux Vérités : la pesée du cœur devant Anubis (un mensonge, et Ammit la
##     Dévoreuse surgit) ;
##  6. la Douat : Apophis, le serpent du chaos, attend la barque de Rê. Récompense : l'Œil d'Horus.

const T := 1.0                                  # épaisseur des murs
const MIRRORS := [[0, 2], [2, 2], [2, 4], [4, 4], [4, 2], [0, 4]]   # [colonne, rangée] des miroirs
const MIRROR_START := [1, 1, 1, 1, 0, 1]        # 0 : « / » (+z <-> +x) ; 1 : « \ » (+z <-> -x)
const PILLARS := [[1, 1], [3, 2], [1, 5], [3, 5]]
const DRUM_FACES := ["sym69_ibis", "sym69_oeil", "sym69_soleil", "sym69_ankh", "sym69_scarabee", "sym69_plume"]
const DRUM_NAMES := ["l'ibis", "l'œil d'Horus", "le soleil", "la croix ankh", "le scarabée", "la plume"]
const DRUM_GOAL := [0, 1, 2]
const SAFE_TILES := [[0, 2], [1, 2], [2, 2], [2, 3], [2, 4], [3, 4], [4, 4], [4, 3], [4, 2], [4, 1], [5, 1], [6, 1]]
const BLOCK_START := [[2, 1], [5, 3]]
const PLATES := [[2, 4], [6, 1]]

var drums: Array = []                           # Node3D des trois tambours
var mirrors: Array = []                         # Node3D des miroirs
var _beam_root: Node3D
var _beam_mats: Array = []
var _sun_door_mat: StandardMaterial3D
var _sun_door_light: OmniLight3D
var blocks: Array = []                          # Node3D des deux blocs
var _block_cells: Array = []
var _plate_mats: Array = []
var _tiles: Dictionary = {}                     # "i,j" -> Node3D (les dalles qui s'effondrent)
var _osiris: Node3D
var _scale_beam: Node3D
var _feather_mat: StandardMaterial3D
var _sun_disc_mat: StandardMaterial3D
var _sun_disc_light: OmniLight3D
var _eye: Node3D
var _sand_fx_t: float = 0.0
var _ammit: Node3D
var _pesee_step: int = 0
var _sphinx_step: int = 0
var _chest_blocs: Node3D


func _init() -> void:
	key = "egypte"
	titre = "la Pyramide de Rê"
	O = Vector3(-760.0, -130.0, -20.0)
	bbox = AABB(Vector3(-40.0, -12.0, -4.0), Vector3(80.0, 30.0, 188.0))
	room_spawns = {
		"thot": [["momie", -5.0, 0.0, 26.0], ["momie", 5.0, 0.0, 30.0]],
		"galerie": [["momie", -6.0, 0.0, 55.0], ["momie", 6.0, 0.0, 47.0], ["scorpion", 2.0, 0.0, 63.0]],
		"serket": [["scorpion", -26.0, 0.0, 74.0], ["scorpion", -28.0, 0.0, 80.0], ["scorpion", -22.0, 0.0, 77.0]],
		"obscure": [["momie", 22.0, 0.0, 90.0], ["momie", 27.0, 0.0, 96.0], ["momie", 29.0, 0.0, 89.0]],
	}


func _defaults() -> Dictionary:
	return {"tambours": [3, 4, 5], "thot": false, "miroirs": MIRROR_START.duplicate(), "galerie": false,
		"blocs_pos": [BLOCK_START[0].duplicate(), BLOCK_START[1].duplicate()], "blocs": false, "osiris": false, "pesee": false}


func entry() -> Array:
	return [W(Vector3(0, 0, 3.5)), Vector3(0, 0, 1)]


func exit_point() -> Array:
	var d: Vector3 = sol.egypte.pyramid_door
	return [d + Vector3(0, 0.1, -0.6), Vector3(0, 0, -1)]


# =================================================================== construction

func _build() -> void:
	add_room("vestibule", Vector3(-7, 0, 0), Vector3(7, 8, 16), Vector3(0, 0, 3.5), Vector3(0, 0, 1), ["thot"])
	add_room("thot", Vector3(-9, 0, 18), Vector3(9, 8, 37), Vector3(0, 0, 19.5), Vector3(0, 0, 1), ["vestibule", "galerie"])
	add_room("galerie", Vector3(-10, 0, 39), Vector3(10, 10, 67), Vector3(0, 0, 40.5), Vector3(0, 0, 1), ["thot", "chapelles"])
	add_room("chapelles", Vector3(-14, 0, 69), Vector3(14, 9, 101), Vector3(8, 0, 70.8), Vector3(0, 0, 1), ["galerie", "serket", "scarabees", "blocs", "obscure", "verites"])
	add_room("serket", Vector3(-32, 0, 71), Vector3(-16, 7, 83), Vector3(-17.2, 0, 77), Vector3(-1, 0, 0), ["chapelles"])
	add_room("scarabees", Vector3(-36, -5, 87), Vector3(-16, 7, 99), Vector3(-17.0, 0, 93), Vector3(-1, 0, 0), ["chapelles"])
	add_room("blocs", Vector3(16, 0, 71), Vector3(32, 7, 83), Vector3(17.2, 0, 77), Vector3(1, 0, 0), ["chapelles"])
	add_room("obscure", Vector3(16, 0, 87), Vector3(32, 7, 99), Vector3(17.2, 0, 93), Vector3(1, 0, 0), ["chapelles"])
	add_room("verites", Vector3(-12, 0, 103), Vector3(12, 10, 131), Vector3(0, 0, 104.8), Vector3(0, 0, 1), ["chapelles", "douat"])
	add_room("douat", Vector3(-20, 0, 133), Vector3(20, 14, 179), Vector3(0, 0, 134.8), Vector3(0, 0, 1), ["verites"])
	_build_vestibule()
	_build_thot()
	_build_galerie()
	_build_hall()
	_build_serket()
	_build_scarabees()
	_build_blocs()
	_build_obscure()
	_build_verites()
	_build_douat()
	kit.commit()


func _xf() -> Transform3D:
	return Transform3D(Basis(), O)


func _torch(n: String, l: Vector3, facing: Vector3, energy: float = 1.6) -> void:
	kit.torch(rooms[n]["root"], W(l), facing, energy)


## Une statue de dieu debout (corps d'homme, pagne, collier d'or ; tête de chacal, d'ibis ou de
## faucon). xf : au sol, le dieu regarde +Z.
func _god(xf: Transform3D, s: float, head: String, body_key: String = "statue69_ocre") -> void:
	var skin: String = "obsid69" if head == "chacal" else body_key
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.15 * s, 0)), Vector3(0.9, 0.3, 0.9) * s, "calc69", 1.0)
	for sx in [-0.12, 0.12]:
		kit.box(xf * Transform3D(Basis(), Vector3(sx * s, 0.75 * s, 0.05 * s)), Vector3(0.16, 0.9, 0.18) * s, skin, 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 1.25 * s, 0)), Vector3(0.46, 0.34, 0.26) * s, "lin69", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 1.62 * s, 0)), Vector3(0.44, 0.42, 0.24) * s, skin, 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 1.84 * s, 0.01 * s)), Vector3(0.5, 0.1, 0.27) * s, "or69", 1.0)
	for sx2 in [-0.3, 0.3]:
		kit.box(xf * Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3(sx2 * s, 1.55 * s, 0.12 * s)), Vector3(0.12, 0.5, 0.12) * s, skin, 1.0)
	# la tête
	match head:
		"chacal":
			kit.box(xf * Transform3D(Basis(), Vector3(0, 2.05 * s, 0)), Vector3(0.24, 0.26, 0.26) * s, skin, 1.0)
			kit.box(xf * Transform3D(Basis(), Vector3(0, 2.0 * s, 0.22 * s)), Vector3(0.12, 0.12, 0.26) * s, skin, 1.0)
			for sx3 in [-0.07, 0.07]:
				kit.frustum(xf * Transform3D(Basis(), Vector3(sx3 * s, 2.16 * s, -0.02 * s)), 0.1 * s, 0.06 * s, 0.01 * s, 0.01 * s, 0.26 * s, skin, 1.0, false)
				kit.box(xf * Transform3D(Basis(), Vector3(sx3 * 0.8 * s, 2.09 * s, 0.13 * s)), Vector3(0.04, 0.02, 0.02) * s, "or69", 1.0)
		"ibis":
			kit.box(xf * Transform3D(Basis(), Vector3(0, 2.05 * s, 0)), Vector3(0.22, 0.24, 0.24) * s, "obsid69", 1.0)
			for k in range(4):
				kit.box(xf * Transform3D(Basis(Vector3.RIGHT, 0.25 + k * 0.18), Vector3(0, (2.0 - k * 0.06) * s, (0.2 + k * 0.1) * s)), Vector3(0.05, 0.05, 0.14) * s, "obsid69", 1.0)
		"faucon":
			kit.box(xf * Transform3D(Basis(), Vector3(0, 2.05 * s, 0)), Vector3(0.24, 0.26, 0.26) * s, "statue69_bleu", 1.0)
			kit.box(xf * Transform3D(Basis(Vector3.RIGHT, 0.6), Vector3(0, 2.0 * s, 0.15 * s)), Vector3(0.06, 0.08, 0.1) * s, "or69", 1.0)
			kit.cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 2.38 * s, -0.04 * s)), 0.2 * s, 0.2 * s, 0.05 * s, "lueur69_rouge", 16)
	# le némès (une coiffe rayée qui tombe sur les épaules)
	kit.frustum(xf * Transform3D(Basis(), Vector3(0, 1.82 * s, -0.04 * s)), 0.46 * s, 0.24 * s, 0.26 * s, 0.26 * s, 0.24 * s, "lapis69", 0.6, false)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 1.1 * s, 0)), Vector3(0.6, 2.2, 0.5) * s)


func _build_vestibule() -> void:
	_in_room("vestibule")
	var xf := _xf()
	kit.room(xf, -7, 7, 0, 16, 0, 8, "hiero69", "calc69", [["s", 0, 3.2, 4.2]], "psombre69", T)
	# l'escalier qui remonte (des marches jusqu'au plafond, contre le mur nord)
	kit.ramp(xf, Vector3(0, 0, 2.6), Vector3(0, 3.0, -0.2), 3.0, "calc69", "gres69")
	kit.solid(X(Vector3(0, 1.5, -0.6)), Vector3(3.6, 3.0, 0.8), "calc69")
	kit.quadz(X(Vector3(0, 4.2, 0.02)), 3.0, 2.2, "noir69")
	# deux statues assises de part et d'autre, deux colonnes papyriformes
	kit.seated_statue(X(Vector3(-5.2, 0, 8.0), PI * 0.5), 1.6, "statue69_granit")
	kit.seated_statue(X(Vector3(5.2, 0, 8.0), -PI * 0.5), 1.6, "statue69_granit")
	for z in [5.0, 12.0]:
		for x in [-3.2, 3.2]:
			kit.papyrus_column(X(Vector3(x, 0, z)), 0.42, 7.4, "gres69")
	kit.panel(X(Vector3(-6.95, 3.8, 8.0), PI * 0.5), 6.0, 3.0, "fresque69_barque")
	kit.panel(X(Vector3(6.95, 3.8, 8.0), -PI * 0.5), 6.0, 3.0, "fresque69_nil")
	for z2 in [3.0, 13.0]:
		_torch("vestibule", Vector3(-6.85, 2.4, z2), Vector3(1, 0, 0))
		_torch("vestibule", Vector3(6.85, 2.4, z2), Vector3(-1, 0, 0))


func _build_thot() -> void:
	_in_room("thot")
	var xf := _xf()
	kit.room(xf, -9, 9, 18, 37, 0, 8, "hiero69", "calc69", [["n", 0, 3.2, 4.2], ["s", 0, 3.2, 4.2]], "psombre69", T)
	gate("thot", "thot", Vector3(0, 0, 38.0), 3.4, 4.3, 0.6, 0.0, "gres69", "sym69_ibis")
	# Thot (tête d'ibis) devant son papyrus, contre le mur ouest ; le pupitre
	_god(X(Vector3(-7.4, 0, 27.5), PI * 0.5), 1.9, "ibis")
	kit.panel(X(Vector3(-8.95, 3.6, 24.0), PI * 0.5), 5.2, 2.6, "papyrus69_thot", "gres69")
	kit.box(X(Vector3(-7.4, 0.55, 24.0)), Vector3(0.6, 1.1, 0.9), "bois69", 1.0)
	kit.col_box(X(Vector3(-7.4, 0.55, 24.0)), Vector3(0.6, 1.1, 0.9))
	# l'inscription au-dessus de la porte
	kit.panel(X(Vector3(0, 5.6, 36.95), PI), 6.0, 1.2, "hiero69")
	# les trois tambours devant la porte, sur un socle
	kit.solid(X(Vector3(0, 0.45, 34.2)), Vector3(9.0, 0.9, 1.6), "gres69")
	drums.clear()
	var st: Array = state["tambours"]
	for i in range(3):
		var dn: Node3D = kit.drum(rooms["thot"]["root"], W(Vector3(-3.0 + i * 3.0, 1.75, 34.2)), 0.72, 2.2, DRUM_FACES, "gres69")
		dn.rotation.y = PI
		dn.rotation.x = 0.0
		drums.append(dn)
		_show_drum(i, int(st[i]), false)
		kit.box(X(Vector3(-3.0 + i * 3.0, 1.1, 34.2)), Vector3(0.3, 0.4, 0.3), "bronze69", 1.0)
	for z in [21.0, 30.0]:
		_torch("thot", Vector3(-8.85, 2.4, z), Vector3(1, 0, 0))
		_torch("thot", Vector3(8.85, 2.4, z), Vector3(-1, 0, 0))
	kit.brazier63(rooms["thot"]["root"], W(Vector3(-5.0, 0, 32.5)), true)
	kit.brazier63(rooms["thot"]["root"], W(Vector3(5.0, 0, 32.5)), true)
	kit.seated_statue(X(Vector3(7.4, 0, 27.5), -PI * 0.5), 1.4, "statue69_blanc")


func _show_drum(i: int, face: int, animate: bool) -> void:
	var dn: Node3D = drums[i]
	# le tambour est tourné vers -Z (vers le joueur qui arrive du nord) : rotation.x amène la face
	var target: float = TAU * face / 6.0
	if animate:
		var cur: float = dn.rotation.x
		while target < cur - 0.01:
			target += TAU
		create_tween().tween_property(dn, "rotation:x", target, 0.5).set_trans(Tween.TRANS_BACK)
	else:
		dn.rotation.x = target


# --------------------------------------------------------------- la Grande Galerie

func _cell_pos(c: int, r: int) -> Vector3:
	return Vector3(-8.0 + 4.0 * c, 0.0, 43.0 + 4.0 * r)


func _build_galerie() -> void:
	_in_room("galerie")
	var xf := _xf()
	kit.room(xf, -10, 10, 39, 67, 0, 10, "hiero69", "calc69", [["n", 0, 3.2, 4.2], ["s", 8.0, 3.2, 4.2]], "psombre69", T)
	gate("galerie", "galerie", Vector3(8.0, 0, 68.0), 3.4, 4.3, 0.6, 0.0, "gres69")
	# le disque solaire sur la porte (il s'allume quand la lumière l'atteint)
	_sun_door_mat = StandardMaterial3D.new()
	_sun_door_mat.albedo_color = Color(0.55, 0.42, 0.2)
	_sun_door_mat.metallic = 0.8
	_sun_door_mat.roughness = 0.3
	_sun_door_mat.emission_enabled = true
	_sun_door_mat.emission = Color(1.0, 0.75, 0.3)
	_sun_door_mat.emission_energy_multiplier = 0.0
	var disc := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 0.75
	dm.bottom_radius = 0.75
	dm.height = 0.1
	disc.mesh = dm
	disc.material_override = _sun_door_mat
	disc.rotation.x = PI * 0.5
	disc.position = Vector3(0, 2.4, -0.36)
	(gates["galerie"] as Node3D).add_child(disc)
	_sun_door_light = OmniLight3D.new()
	_sun_door_light.light_color = Color(1.0, 0.8, 0.4)
	_sun_door_light.light_energy = 0.0
	_sun_door_light.omni_range = 9.0
	_sun_door_light.position = Vector3(0, 2.4, -1.2)
	(gates["galerie"] as Node3D).add_child(_sun_door_light)
	# le conduit d'où vient la lumière (au nord-ouest), une lueur
	kit.box(X(Vector3(-8.0, 1.6, 39.2)), Vector3(1.0, 1.0, 0.4), "noir69", 1.0)
	kit.glow_light(rooms["galerie"]["root"], W(Vector3(-8.0, 1.8, 40.0)), Color(1.0, 0.85, 0.5), 1.6, 6.0)
	# les piliers
	for pc_ in PILLARS:
		kit.column(X(_cell_pos(int(pc_[0]), int(pc_[1]))), 0.6, 10.0, "hiero69", "gres69")
	# les miroirs de bronze sur leurs pieds
	mirrors.clear()
	for i in range(MIRRORS.size()):
		var m: Array = MIRRORS[i]
		var p: Vector3 = _cell_pos(int(m[0]), int(m[1]))
		kit.cyl(X(p), 0.35, 0.3, 0.3, "gres69", 12)
		kit.col_cyl(W(p), 0.35, 1.0)
		var holder := Node3D.new()
		holder.name = "Miroir_%d" % i
		(rooms["galerie"]["root"] as Node3D).add_child(holder)
		holder.global_position = W(p + Vector3(0, 0.3, 0))
		var post := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.05
		pm.bottom_radius = 0.06
		pm.height = 1.0
		post.mesh = pm
		post.material_override = kit.mat("bronze69")
		post.position = Vector3(0, 0.5, 0)
		holder.add_child(post)
		var face := MeshInstance3D.new()
		var fm := CylinderMesh.new()
		fm.top_radius = 0.62
		fm.bottom_radius = 0.62
		fm.height = 0.06
		fm.radial_segments = 24
		face.mesh = fm
		face.material_override = kit.mat("miroir69")
		face.rotation.x = PI * 0.5
		face.position = Vector3(0, 1.3, 0)
		holder.add_child(face)
		var rim := MeshInstance3D.new()
		var rm := TorusMesh.new()
		rm.inner_radius = 0.6
		rm.outer_radius = 0.68
		rim.mesh = rm
		rim.material_override = kit.mat("bronze69")
		rim.rotation.x = PI * 0.5
		rim.position = Vector3(0, 1.3, 0)
		holder.add_child(rim)
		mirrors.append(holder)
	_beam_root = Node3D.new()
	_beam_root.name = "Rayon"
	(rooms["galerie"]["root"] as Node3D).add_child(_beam_root)
	for z in [45.0, 57.0]:
		_torch("galerie", Vector3(-9.85, 2.6, z), Vector3(1, 0, 0), 1.2)
		_torch("galerie", Vector3(9.85, 2.6, z), Vector3(-1, 0, 0), 1.2)
	kit.panel(X(Vector3(9.95, 5.0, 51.0), -PI * 0.5), 8.0, 4.0, "fresque69_barque")


## Le miroir : « / » (0) renvoie +z vers +x ; « \ » (1) renvoie +z vers -x.
func _mirror_yaw(o: int) -> float:
	return -PI * 0.25 if o == 0 else PI * 0.25


func _show_mirrors(animate: bool) -> void:
	var o: Array = state["miroirs"]
	for i in range(mirrors.size()):
		var y: float = _mirror_yaw(int(o[i]))
		if animate:
			create_tween().tween_property(mirrors[i], "rotation:y", y, 0.4)
		else:
			(mirrors[i] as Node3D).rotation.y = y


## Suit la lumière de case en case ; renvoie [chemin (positions locales), arrive au disque ?].
func _trace_beam() -> Array:
	var o: Array = state["miroirs"]
	var mm: Dictionary = {}
	for i in range(MIRRORS.size()):
		mm["%d,%d" % [MIRRORS[i][0], MIRRORS[i][1]]] = int(o[i])
	var pil: Dictionary = {}
	for pc_ in PILLARS:
		pil["%d,%d" % [pc_[0], pc_[1]]] = true
	var c: int = 0
	var r: int = 0
	var dc: int = 0
	var dr: int = 1
	var pts: Array = [Vector3(-8.0, 1.6, 39.4)]
	for step in range(40):
		var k: String = "%d,%d" % [c, r]
		if pil.has(k):
			pts.append(_cell_pos(c, r) + Vector3(0, 1.6, 0) - Vector3(dc, 0, dr) * 0.7)
			return [pts, false]
		if mm.has(k):
			pts.append(_cell_pos(c, r) + Vector3(0, 1.6, 0))
			var om: int = mm[k]
			# « / » : (dc, dr) -> (dr, dc) ; « \ » : (dc, dr) -> (-dr, -dc)
			var ndc: int = dr if om == 0 else -dr
			var ndr: int = dc if om == 0 else -dc
			dc = ndc
			dr = ndr
		var nc: int = c + dc
		var nr: int = r + dr
		if nc < 0 or nc > 4 or nr < 0 or nr > 5:
			# le mur : au sud, la porte du disque solaire se trouve en colonne 4
			var end: Vector3 = _cell_pos(c, r) + Vector3(0, 1.6, 0) + Vector3(dc, 0, dr) * 2.0
			if nr > 5 and c == 4:
				end = Vector3(8.0, 2.4, 67.6)
				pts.append(end)
				return [pts, true]
			pts.append(end)
			return [pts, false]
		c = nc
		r = nr
	return [pts, false]


func _draw_beam() -> void:
	for ch in _beam_root.get_children():
		ch.queue_free()
	var res: Array = _trace_beam()
	var pts: Array = res[0]
	for i in range(pts.size() - 1):
		var a: Vector3 = W(pts[i])
		var b: Vector3 = W(pts[i + 1])
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.07
		cm.bottom_radius = 0.07
		cm.height = a.distance_to(b)
		cm.radial_segments = 8
		mi.mesh = cm
		mi.material_override = kit.mat("rayon69")
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_beam_root.add_child(mi)
		mi.global_transform = kit.axis_xf(a, b) * Transform3D(Basis(), Vector3(0, a.distance_to(b) * 0.5, 0))
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.85, 0.5)
		l.light_energy = 0.7
		l.omni_range = 3.5
		l.shadow_enabled = false
		_beam_root.add_child(l)
		l.global_position = b
	var hit: bool = res[1]
	_sun_door_mat.emission_energy_multiplier = 3.0 if hit or bool(state["galerie"]) else 0.0
	_sun_door_light.light_energy = 2.0 if hit or bool(state["galerie"]) else 0.0
	if hit and not bool(state["galerie"]):
		state["galerie"] = true
		_sfx("sistre", W(Vector3(8, 2, 66)))
		open_gate("galerie", "La lumière de Rê frappe le disque d'or de la porte ! Il s'embrase… et la dalle s'enfonce lentement dans le sol.")


func _turn_mirror(i: int) -> void:
	var o: Array = state["miroirs"]
	o[i] = 1 - int(o[i])
	_show_mirrors(true)
	_sfx("mecanisme", (mirrors[i] as Node3D).global_position + Vector3.UP)
	get_tree().create_timer(0.45).timeout.connect(_draw_beam)


# --------------------------------------------------------------- la salle d'Osiris

func _build_hall() -> void:
	_in_room("chapelles")
	var xf := _xf()
	kit.room(xf, -14, 14, 69, 101, 0, 9, "hiero69", "calc69",
		[["n", 8.0, 3.2, 4.2], ["s", 0, 3.2, 4.2], ["w", 77, 3.0, 4.0], ["w", 93, 3.0, 4.0], ["e", 77, 3.0, 4.0], ["e", 93, 3.0, 4.0]], "psombre69", T)
	gate("verites", "chapelles", Vector3(0, 0, 102.0), 3.4, 4.3, 0.6, 0.0, "gres69", "sym69_plume")
	# le sarcophage d'Osiris au centre, sur une estrade
	kit.solid(X(Vector3(0, 0.25, 85.0)), Vector3(5.0, 0.5, 6.0), "gres69_rose")
	kit.sarcophagus(X(Vector3(0, 0.5, 85.0)), true, "gres69", "or69")
	# Osiris : une silhouette verte emmaillotée, qui apparaît quand les quatre morceaux y sont
	_osiris = Node3D.new()
	_osiris.name = "Osiris"
	(rooms["chapelles"]["root"] as Node3D).add_child(_osiris)
	_osiris.global_position = W(Vector3(0, 1.45, 85.0))
	var om := StandardMaterial3D.new()
	om.albedo_color = Color(0.25, 0.6, 0.35)
	om.emission_enabled = true
	om.emission = Color(0.3, 0.9, 0.5)
	om.emission_energy_multiplier = 0.8
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.28
	cap.height = 1.9
	body.mesh = cap
	body.material_override = om
	body.rotation.x = PI * 0.5
	_osiris.add_child(body)
	var crown := MeshInstance3D.new()
	var cr := CylinderMesh.new()
	cr.top_radius = 0.05
	cr.bottom_radius = 0.16
	cr.height = 0.5
	crown.mesh = cr
	crown.material_override = kit.mat("calc69_blanc")
	crown.rotation.x = -PI * 0.5
	crown.position = Vector3(0, 0.12, -1.15)
	_osiris.add_child(crown)
	var gl := OmniLight3D.new()
	gl.light_color = Color(0.4, 1.0, 0.6)
	gl.light_energy = 1.6
	gl.omni_range = 7.0
	gl.position = Vector3(0, 1.2, 0)
	_osiris.add_child(gl)
	_osiris.visible = bool(state["osiris"])
	# Isis et Nephthys (statues ailées : des dieux debout) aux quatre coins, les fresques
	for p in [Vector3(-11.5, 0, 72.0), Vector3(11.5, 0, 72.0), Vector3(-11.5, 0, 98.0), Vector3(11.5, 0, 98.0)]:
		_god(X(p, atan2(-p.x, 85.0 - p.z)), 1.6, "faucon", "statue69_ocre")
	kit.panel(X(Vector3(-4.0, 4.4, 69.05), 0.0), 7.0, 3.5, "fresque69_osiris")
	kit.panel(X(Vector3(0, 6.0, 100.95), PI), 6.0, 3.0, "fresque69_pesee")
	for p2 in [Vector3(-8.0, 0, 79.0), Vector3(8.0, 0, 79.0), Vector3(-8.0, 0, 91.0), Vector3(8.0, 0, 91.0)]:
		kit.papyrus_column(X(p2), 0.5, 8.4, "gres69")
	for z in [73.0, 85.0, 97.0]:
		_torch("chapelles", Vector3(-13.85, 2.5, z + (4.0 if z == 85.0 else 0.0)), Vector3(1, 0, 0))
		_torch("chapelles", Vector3(13.85, 2.5, z + (4.0 if z == 85.0 else 0.0)), Vector3(-1, 0, 0))
	kit.brazier63(rooms["chapelles"]["root"], W(Vector3(-4.0, 0, 82.0)), true)
	kit.brazier63(rooms["chapelles"]["root"], W(Vector3(4.0, 0, 88.0)), true)


func _build_serket() -> void:
	_in_room("serket")
	var xf := _xf()
	kit.room(xf, -32, -16, 71, 83, 0, 7, "hiero69", "calc69", [["e", 77, 3.0, 4.0]], "psombre69", T)
	# Serket, la déesse au scorpion : une statue assise, un scorpion d'or sur la tête
	kit.seated_statue(X(Vector3(-30.2, 0, 77.0), PI * 0.5), 1.8, "statue69_granit")
	kit.box(X(Vector3(-30.4, 4.5, 77.0)), Vector3(0.7, 0.18, 0.4), "or69", 1.0)
	kit.solid(X(Vector3(-27.6, 0.5, 77.0)), Vector3(1.6, 1.0, 2.6), "gres69")
	for z in [73.0, 81.0]:
		_torch("serket", Vector3(-31.85, 2.4, z), Vector3(1, 0, 0), 1.3)
	_torch("serket", Vector3(-24.0, 2.4, 71.15), Vector3(0, 0, 1), 1.3)
	_torch("serket", Vector3(-24.0, 2.4, 82.85), Vector3(0, 0, -1), 1.3)
	var me = self
	chest("serket", "serket", Vector3(-27.6, 1.0, 77.0), PI * 0.5, [["fragment_osiris", 1]],
		"Sur l'autel de Serket, dans un coffret : un morceau d'Osiris, vert comme le blé qui repousse.",
		func(): return me.room_spawned("serket") and me.room_alive("serket") == 0)


func _build_scarabees() -> void:
	_in_room("scarabees")
	var xf := _xf()
	# la salle descend jusqu'au fond de la fosse (y = -5) ; les rebords et les dalles sont posés dessus
	kit.room(xf, -36, -16, 87, 99, -5, 12, "hiero69", "sable69", [["e", 93, 3.0, 9.0]], "psombre69", T)
	kit.solid(X(Vector3(-16.5, -2.5, 93.0)), Vector3(3.0, 5.0, 12.0 + 2.0 * T), "calc69")
	kit.solid(X(Vector3(-34.5, -2.5, 93.0)), Vector3(5.0, 5.0, 12.0 + 2.0 * T), "calc69")
	_tiles.clear()
	var safe: Dictionary = {}
	for t in SAFE_TILES:
		safe["%d,%d" % [t[0], t[1]]] = true
	for i in range(7):
		for j in range(6):
			var p := Vector3(-19.0 - 2.0 * i, -0.2, 88.0 + 2.0 * j)
			var k: String = "%d,%d" % [i, j]
			if safe.has(k):
				kit.box(X(p), Vector3(1.94, 0.4, 1.94), "calc69_ocre", 1.0)
				kit.col_box(X(p), Vector3(1.94, 0.4, 1.94))
				# un petit scarabée gravé, à peine visible
				var q := MeshInstance3D.new()
				var qm := QuadMesh.new()
				qm.size = Vector2(0.55, 0.55)
				q.mesh = qm
				q.material_override = kit.mat("sym69_scarabee")
				q.rotation.x = -PI * 0.5
				q.rotation.y = PI * 0.5
				(rooms["scarabees"]["root"] as Node3D).add_child(q)
				q.global_position = W(p + Vector3(0, 0.205, 0))
			else:
				var mi := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(1.94, 0.4, 1.94)
				mi.mesh = bm
				mi.material_override = kit.mat("calc69_ocre")
				(rooms["scarabees"]["root"] as Node3D).add_child(mi)
				mi.global_position = W(p)
				mi.set_meta("y0", mi.position.y)
				_tiles[k] = mi
	# Khépri, le scarabée qui pousse le soleil, sculpté au-dessus de l'autel
	kit.panel(X(Vector3(-35.95, 3.0, 93.0), PI * 0.5), 2.4, 2.4, "sym69_scarabee", "gres69")
	kit.solid(X(Vector3(-34.0, 0.5, 93.0)), Vector3(1.4, 1.0, 2.4), "gres69")
	_torch("scarabees", Vector3(-35.85, 2.4, 89.0), Vector3(1, 0, 0), 1.4)
	_torch("scarabees", Vector3(-35.85, 2.4, 97.0), Vector3(1, 0, 0), 1.4)
	_torch("scarabees", Vector3(-16.85 + 0.0, 2.4, 89.0), Vector3(-1, 0, 0), 1.2)
	_torch("scarabees", Vector3(-26.0, 2.4, 87.15), Vector3(0, 0, 1), 1.2)
	_torch("scarabees", Vector3(-26.0, 2.4, 98.85), Vector3(0, 0, -1), 1.2)
	chest("scarabees", "scarabees", Vector3(-34.0, 1.0, 93.0), PI * 0.5, [["fragment_osiris", 1]],
		"Sous l'œil de Khépri, dans un coffret : un morceau d'Osiris !")


func _build_blocs() -> void:
	_in_room("blocs")
	var xf := _xf()
	kit.room(xf, 16, 32, 71, 83, 0, 7, "hiero69", "calc69", [["w", 77, 3.0, 4.0]], "psombre69", T)
	# les deux dalles d'Isis (le nœud d'Isis, la croix ankh)
	_plate_mats.clear()
	for pl in PLATES:
		var p: Vector3 = _bcell(int(pl[0]), int(pl[1]))
		kit.box(X(p + Vector3(0, 0.02, 0)), Vector3(1.9, 0.04, 1.9), "bronze69", 1.0)
		var pm := StandardMaterial3D.new()
		pm.albedo_texture = load("res://assets/textures/soleils/sym_ankh.png")
		pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		pm.emission_enabled = true
		pm.emission = Color(0.4, 0.9, 1.0)
		pm.emission_energy_multiplier = 0.0
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(1.5, 1.5)
		q.mesh = qm
		q.material_override = pm
		q.rotation.x = -PI * 0.5
		(rooms["blocs"]["root"] as Node3D).add_child(q)
		q.global_position = W(p + Vector3(0, 0.05, 0))
		_plate_mats.append(pm)
	# les deux blocs de granit
	blocks.clear()
	for i in range(2):
		var b := Node3D.new()
		b.name = "Bloc_%d" % i
		(rooms["blocs"]["root"] as Node3D).add_child(b)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.8, 1.8, 1.8)
		mi.mesh = bm
		mi.material_override = kit.mat("gres69_rose")
		mi.position = Vector3(0, 0.9, 0)
		b.add_child(mi)
		var q2 := MeshInstance3D.new()
		var qm2 := QuadMesh.new()
		qm2.size = Vector2(1.1, 1.1)
		q2.mesh = qm2
		q2.material_override = kit.mat("sym69_oeil")
		q2.position = Vector3(0, 1.81, 0)
		q2.rotation.x = -PI * 0.5
		b.add_child(q2)
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(1.8, 1.8, 1.8)
		cs.shape = sh
		cs.position = Vector3(0, 0.9, 0)
		sb.add_child(cs)
		b.add_child(sb)
		blocks.append(b)
	_place_blocks(false)
	kit.panel(X(Vector3(31.95, 3.4, 77.0), -PI * 0.5), 5.0, 2.5, "fresque69_osiris")
	for z in [73.0, 81.0]:
		_torch("blocs", Vector3(31.85, 2.4, z), Vector3(-1, 0, 0), 1.3)
		_torch("blocs", Vector3(16.15, 2.4, z), Vector3(1, 0, 0), 1.0)
	var me = self
	chest("blocs", "blocs", Vector3(30.6, 0, 77.0), -PI * 0.5, [["fragment_osiris", 1]],
		"Le coffret qui est monté du sol contient un morceau d'Osiris !",
		func(): return bool(me.state["blocs"]))
	_chest_blocs = (rooms["blocs"]["root"] as Node3D).get_node_or_null("Coffre_blocs")
	if _chest_blocs != null and not bool(state["blocs"]):
		_chest_blocs.position.y -= 1.0


func _bcell(c: int, r: int) -> Vector3:
	return Vector3(17.0 + 2.0 * c, 0.0, 72.0 + 2.0 * r)


func _place_blocks(animate: bool) -> void:
	var bp: Array = state["blocs_pos"]
	for i in range(2):
		var p: Vector3 = W(_bcell(int(bp[i][0]), int(bp[i][1])))
		if animate:
			create_tween().tween_property(blocks[i], "global_position", p, 0.7).set_trans(Tween.TRANS_QUAD)
		else:
			(blocks[i] as Node3D).global_position = p
	for k in range(2):
		var on: bool = false
		for i2 in range(2):
			if int(bp[i2][0]) == int(PLATES[k][0]) and int(bp[i2][1]) == int(PLATES[k][1]):
				on = true
		(_plate_mats[k] as StandardMaterial3D).emission_energy_multiplier = 2.5 if on else 0.0


func _push_block(i: int) -> void:
	if bool(state["blocs"]):
		return
	var bp: Array = state["blocs_pos"]
	var b: Vector3 = _bcell(int(bp[i][0]), int(bp[i][1]))
	var p: Vector3 = L(_feet())
	var d := Vector2(b.x - p.x, b.z - p.z)
	var dc: int = 0
	var dr: int = 0
	if absf(d.x) > absf(d.y):
		if absf(d.y) > 0.9:
			_say("Mets-toi bien en face du bloc pour le pousser.", 3.0)
			return
		dc = 1 if d.x > 0.0 else -1
	else:
		if absf(d.x) > 0.9:
			_say("Mets-toi bien en face du bloc pour le pousser.", 3.0)
			return
		dr = 1 if d.y > 0.0 else -1
	var nc: int = int(bp[i][0]) + dc
	var nr: int = int(bp[i][1]) + dr
	var other: Array = bp[1 - i]
	var forbidden: bool = (nc == 7 and (nr == 2 or nr == 3)) or (nc == 0 and (nr == 2 or nr == 3))
	if nc < 0 or nc > 7 or nr < 0 or nr > 5 or forbidden or (nc == int(other[0]) and nr == int(other[1])):
		_say("Le bloc ne bouge plus : le mur, ou l'autre bloc, le retient.", 3.0)
		_sfx("touche_pierre", W(b) + Vector3.UP)
		return
	bp[i] = [nc, nr]
	_place_blocks(true)
	_sfx("pierre_glisse", W(b) + Vector3.UP)
	var done: bool = true
	for k in range(2):
		var on: bool = false
		for i2 in range(2):
			if int(bp[i2][0]) == int(PLATES[k][0]) and int(bp[i2][1]) == int(PLATES[k][1]):
				on = true
		done = done and on
	if done:
		state["blocs"] = true
		_sfx("sistre", W(Vector3(30, 1, 77)))
		if _chest_blocs != null:
			create_tween().tween_property(_chest_blocs, "position:y", _chest_blocs.position.y + 1.0, 2.0).set_trans(Tween.TRANS_SINE)
		_say("Les deux dalles d'Isis s'illuminent ! Contre le mur du fond, un coffret monte lentement du sol.", 6.0)


func _reset_blocks() -> void:
	if bool(state["blocs"]):
		return
	state["blocs_pos"] = [BLOCK_START[0].duplicate(), BLOCK_START[1].duplicate()]
	_place_blocks(true)
	_sfx("mecanisme", W(Vector3(18, 1, 75)))
	_say("Un grondement : les deux blocs glissent d'eux-mêmes jusqu'à leur place de départ.", 4.0)


func _build_obscure() -> void:
	_in_room("obscure")
	var xf := _xf()
	kit.room(xf, 16, 32, 87, 99, 0, 7, "psombre69", "calc69_sombre", [["w", 93, 3.0, 4.0]], "psombre69", T)
	# aucune torche : la chapelle obscure. Juste une lueur verte, au fond, sur le sarcophage
	kit.sarcophagus(X(Vector3(29.6, 0, 93.0), PI * 0.5), false, "psombre69", "or69")
	for z in [89.0, 97.0]:
		kit.sarcophagus(X(Vector3(24.0, 0, z), 0.0), true, "psombre69", "gres69")
	kit.glow_light(rooms["obscure"]["root"], W(Vector3(28.0, 2.0, 93.0)), Color(0.4, 1.0, 0.55), 0.9, 7.0)
	var me = self
	chest("obscure", "obscure", Vector3(27.0, 0, 93.0), -PI * 0.5, [["fragment_osiris", 1]],
		"Dans le coffret, au pied du sarcophage : le dernier morceau d'Osiris.",
		func(): return me.room_spawned("obscure") and me.room_alive("obscure") == 0)


# --------------------------------------------------------------- la Salle des Deux Vérités

func _build_verites() -> void:
	_in_room("verites")
	var xf := _xf()
	kit.room(xf, -12, 12, 103, 131, 0, 10, "hiero69", "calc69", [["n", 0, 3.2, 4.2], ["s", 0, 3.2, 4.2]], "psombre69", T)
	gate("douat", "verites", Vector3(0, 0, 132.0), 3.4, 4.3, 0.6, 0.0, "psombre69", "sym69_soleil")
	# Anubis, grand, à côté de la balance ; Thot de l'autre côté ; les juges le long des murs
	kit.solid(X(Vector3(0, 0.3, 119.0)), Vector3(10.0, 0.6, 5.0), "gres69")
	_god(X(Vector3(-3.4, 0.6, 119.0), PI), 2.4, "chacal")
	_god(X(Vector3(3.4, 0.6, 119.0), PI), 2.2, "ibis")
	for k in range(6):
		var z: float = 106.0 + k * 4.2
		kit.seated_statue(X(Vector3(-10.6, 0, z), PI * 0.5), 1.0, "statue69_ocre")
		kit.seated_statue(X(Vector3(10.6, 0, z), -PI * 0.5), 1.0, "statue69_ocre")
	# la balance : un pied, un fléau (qui bascule), deux plateaux ; un cœur rouge, la plume de Maât
	kit.cyl(X(Vector3(0, 0.6, 119.0)), 0.18, 0.14, 3.0, "or69", 12)
	kit.col_cyl(W(Vector3(0, 0.6, 119.0)), 0.3, 3.0)
	_scale_beam = Node3D.new()
	_scale_beam.name = "Fleau"
	(rooms["verites"]["root"] as Node3D).add_child(_scale_beam)
	_scale_beam.global_position = W(Vector3(0, 3.65, 119.0))
	var bar := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(3.0, 0.1, 0.1)
	bar.mesh = bb
	bar.material_override = kit.mat("or69")
	_scale_beam.add_child(bar)
	for s in [-1.0, 1.0]:
		var pan := Node3D.new()
		pan.name = "Plateau_%s" % ("g" if s < 0 else "d")
		pan.position = Vector3(s * 1.4, 0, 0)
		_scale_beam.add_child(pan)
		for k2 in range(3):
			var a: float = TAU * k2 / 3.0
			var cord := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.012
			cm.bottom_radius = 0.012
			cm.height = 1.2
			cord.mesh = cm
			cord.material_override = kit.mat("or69")
			cord.position = Vector3(cos(a) * 0.2, -0.6, sin(a) * 0.2)
			pan.add_child(cord)
		var dish := MeshInstance3D.new()
		var dm := CylinderMesh.new()
		dm.top_radius = 0.42
		dm.bottom_radius = 0.3
		dm.height = 0.08
		dish.mesh = dm
		dish.material_override = kit.mat("or69")
		dish.position = Vector3(0, -1.2, 0)
		pan.add_child(dish)
		if s < 0:
			var heart := MeshInstance3D.new()
			var hm := SphereMesh.new()
			hm.radius = 0.16
			hm.height = 0.3
			heart.mesh = hm
			heart.material_override = kit.mat("argile69_rouge")
			heart.position = Vector3(0, -1.05, 0)
			pan.add_child(heart)
		else:
			_feather_mat = StandardMaterial3D.new()
			_feather_mat.albedo_texture = load("res://assets/textures/soleils/sym_plume.png")
			_feather_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			_feather_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			_feather_mat.emission_enabled = true
			_feather_mat.emission = Color(1.0, 0.95, 0.8)
			_feather_mat.emission_energy_multiplier = 0.3
			var fq := MeshInstance3D.new()
			var fqm := QuadMesh.new()
			fqm.size = Vector2(0.5, 0.5)
			fq.mesh = fqm
			fq.material_override = _feather_mat
			fq.position = Vector3(0, -0.92, 0)
			pan.add_child(fq)
	_scale_beam.rotation.z = 0.0 if bool(state["pesee"]) else 0.22
	kit.panel(X(Vector3(0, 6.6, 103.05), 0.0), 8.0, 4.0, "fresque69_pesee")
	for z2 in [107.0, 125.0]:
		_torch("verites", Vector3(-11.85, 2.8, z2), Vector3(1, 0, 0))
		_torch("verites", Vector3(11.85, 2.8, z2), Vector3(-1, 0, 0))
	kit.brazier63(rooms["verites"]["root"], W(Vector3(-5.5, 0, 114.0)), true)
	kit.brazier63(rooms["verites"]["root"], W(Vector3(5.5, 0, 114.0)), true)


# --------------------------------------------------------------- la Douat

func _build_douat() -> void:
	_in_room("douat")
	var xf := _xf()
	kit.room(xf, -20, 20, 133, 179, 0, 14, "psombre69", "", [["n", 0, 3.2, 4.2]], "lapis69", T)
	kit.solid(X(Vector3(0, -0.3, 156.0)), Vector3(31.0, 0.6, 46.0 + 2.0 * T), "psombre69", 3.0)
	# le fleuve de la nuit, de part et d'autre (un parapet bas le borde)
	for s in [-1.0, 1.0]:
		kit.solid(X(Vector3(s * 18.25, -1.5, 156.0)), Vector3(5.5, 0.6, 46.0 + 2.0 * T), "psombre69", 3.0)
		kit.solid(X(Vector3(s * 20.5, -0.6, 156.0)), Vector3(1.0, 1.2, 46.0 + 2.0 * T), "psombre69", 3.0)
		for zz in [132.5, 179.5]:
			kit.solid(X(Vector3(s * 18.0, -0.6, zz)), Vector3(5.0, 1.2, 1.0), "psombre69", 3.0)
		kit.solid(X(Vector3(s * 15.2, 0.4, 156.0)), Vector3(0.6, 0.8, 46.0), "gres69")
		var w := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(4.6, 46.0)
		w.mesh = pm
		w.material_override = kit.mat("eau69_sombre")
		(rooms["douat"]["root"] as Node3D).add_child(w)
		w.global_position = W(Vector3(s * 17.8, -0.6, 156.0))
	# les colonnes papyriformes, les étoiles du plafond (des petites lueurs)
	for z in [140.0, 150.0, 160.0, 170.0]:
		for x in [-11.0, 11.0]:
			kit.papyrus_column(X(Vector3(x, 0, z)), 0.6, 13.0, "psombre69", false)
	for k in range(30):
		var sp := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.08
		sm.height = 0.16
		sp.mesh = sm
		sp.material_override = kit.mat("lueur69_or")
		(rooms["douat"]["root"] as Node3D).add_child(sp)
		sp.global_position = W(Vector3(-18.0 + fmod(k * 7.3, 36.0), 13.9, 135.0 + fmod(k * 11.7, 42.0)))
	# la barque de Rê, au sud, et le disque solaire éteint au-dessus
	kit.solid(X(Vector3(0, 0.3, 172.0)), Vector3(9.0, 0.6, 8.0), "gres69")
	kit.papyrus_boat(X(Vector3(0, 0.6, 172.0), PI * 0.5), 8.0)
	kit.box(X(Vector3(0, 1.5, 172.0)), Vector3(1.6, 1.4, 1.6), "or69", 1.0)
	_sun_disc_mat = StandardMaterial3D.new()
	_sun_disc_mat.albedo_color = Color(0.35, 0.18, 0.08)
	_sun_disc_mat.emission_enabled = true
	_sun_disc_mat.emission = Color(1.0, 0.7, 0.25)
	_sun_disc_mat.emission_energy_multiplier = 0.0
	var disc := MeshInstance3D.new()
	var dm := SphereMesh.new()
	dm.radius = 1.2
	dm.height = 2.4
	disc.mesh = dm
	disc.material_override = _sun_disc_mat
	(rooms["douat"]["root"] as Node3D).add_child(disc)
	disc.global_position = W(Vector3(0, 5.2, 172.0))
	_sun_disc_light = OmniLight3D.new()
	_sun_disc_light.light_color = Color(1.0, 0.8, 0.45)
	_sun_disc_light.light_energy = 0.0
	_sun_disc_light.omni_range = 50.0
	_sun_disc_light.omni_attenuation = 0.7
	_sun_disc_light.shadow_enabled = pc
	disc.add_child(_sun_disc_light)
	# l'Œil d'Horus, qui flottera au-dessus de la barque
	_eye = Node3D.new()
	_eye.name = "Oeil_Horus"
	(rooms["douat"]["root"] as Node3D).add_child(_eye)
	_eye.global_position = W(Vector3(0, 2.6, 169.0))
	var eq := MeshInstance3D.new()
	var eqm := QuadMesh.new()
	eqm.size = Vector2(0.9, 0.9)
	eq.mesh = eqm
	var em := StandardMaterial3D.new()
	em.albedo_texture = load("res://assets/textures/soleils/sym_oeil.png")
	em.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	em.cull_mode = BaseMaterial3D.CULL_DISABLED
	em.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	em.emission_enabled = true
	em.emission = Color(0.5, 0.7, 1.0)
	em.emission_energy_multiplier = 1.4
	eq.material_override = em
	_eye.add_child(eq)
	var el := OmniLight3D.new()
	el.light_color = Color(0.5, 0.7, 1.0)
	el.light_energy = 1.4
	el.omni_range = 5.0
	_eye.add_child(el)
	_eye.visible = false
	kit.panel(X(Vector3(-19.95, 6.0, 156.0), PI * 0.5), 10.0, 5.0, "fresque69_barque", "psombre69")
	for z2 in [138.0, 152.0, 166.0]:
		kit.brazier63(rooms["douat"]["root"], W(Vector3(-13.0, 0, z2)), true, "bronze69", 1.8, "psombre69")
		kit.brazier63(rooms["douat"]["root"], W(Vector3(13.0, 0, z2)), true, "bronze69", 1.8, "psombre69")


# =================================================================== invites

func register(journal: Node) -> void:
	journal.lieux["pyramide_interieur"] = W(Vector3(0, 0, 3.5))
	var d: Node = main.get("donjon_v35")
	if d == null or sol.egypte == null:
		return
	var me = self
	# dehors : le Sphinx et la porte de la pyramide
	var s1 := {"id": "eg_sphinx", "pos": sol.egypte.sphinx_talk, "radius": 3.2, "text": "E : parler au Sphinx", "vr": "Gâchette : le Sphinx",
		"call": func(): me._sphinx(), "when": func(): return int(me.sol.state["sphinx"]) < 3}
	d._interactions.append(s1)
	var s2 := {"id": "eg_sphinx_fini", "pos": sol.egypte.sphinx_talk, "radius": 3.2, "text": "E : saluer le Sphinx", "vr": "Gâchette : le Sphinx",
		"call": func(): me._say("Le Sphinx ne bouge pas. Mais tu jurerais que, l'espace d'un instant, ses lèvres de pierre ont souri.", 4.0),
		"when": func(): return int(me.sol.state["sphinx"]) >= 3}
	d._interactions.append(s2)
	var p1 := {"id": "eg_pyramide_porte", "pos": sol.egypte.pyramid_door, "radius": 2.0, "text": "E : examiner la porte de la pyramide", "vr": "Gâchette : la porte",
		"call": func(): me._say("Une porte de pierre, scellée, sous un linteau couvert de hiéroglyphes. Au-dessus, un soleil entre deux cobras. On dirait que quelque chose, sur ce plateau, garde la clé… Le Sphinx, peut-être ?", 6.0),
		"when": func(): return int(me.sol.state["sphinx"]) < 3}
	d._interactions.append(p1)
	var p2 := {"id": "eg_pyramide_entrer", "pos": sol.egypte.pyramid_door, "radius": 2.0, "text": "E : entrer dans la Pyramide de Rê", "vr": "Gâchette : entrer",
		"call": func(): me.enter(), "when": func(): return int(me.sol.state["sphinx"]) >= 3}
	d._interactions.append(p2)


func _register() -> void:
	var me = self
	ia("sortir", Vector3(0, 0, 2.0), 1.6, "E : remonter vers la lumière", "Gâchette : remonter", func(): me.leave("De retour sur le plateau de Rê, devant la porte de la pyramide."))
	ia("papyrus", Vector3(-7.4, 0, 24.0), 1.8, "E : lire le papyrus de Thot", "Gâchette : le papyrus",
		func(): me._say("Le papyrus de Thot, le dieu à tête d'ibis, le scribe des dieux. Thot montre du doigt un cartouche — le nom du roi, écrit de haut en bas : trois signes, l'un sous l'autre. Regarde-les bien.", 8.0))
	ia("inscription_thot", Vector3(0, 0, 29.4), 1.6, "E : lire l'inscription au-dessus de la porte", "Gâchette : l'inscription",
		func(): me._say("« Seul passera celui qui écrit le nom du roi comme Thot l'a écrit. Le premier signe à gauche, le dernier à droite. »", 6.0),
		func(): return not bool(me.state["thot"]))
	for i in range(3):
		var ii: int = i
		ia("tambour_%d" % i, Vector3(-3.0 + i * 3.0, 0, 32.7), 1.1, "E : tourner le tambour", "Gâchette : le tambour",
			func(): me._turn_drum(ii), func(): return not bool(me.state["thot"]))
	for i2 in range(MIRRORS.size()):
		var jj: int = i2
		var p: Vector3 = _cell_pos(int(MIRRORS[i2][0]), int(MIRRORS[i2][1]))
		ia("miroir_%d" % i2, p, 1.6, "E : tourner le miroir de bronze", "Gâchette : le miroir", func(): me._turn_mirror(jj), func(): return not bool(me.state["galerie"]))
	ia("sarcophage", Vector3(0, 0.5, 81.6), 2.6, "E : examiner le sarcophage d'Osiris", "Gâchette : le sarcophage", func(): me._sarcophagus(), func(): return not bool(me.state["osiris"]))
	for i3 in range(2):
		var kk: int = i3
		var me2 = self
		var it: Dictionary = ia("bloc_%d" % i3, Vector3.ZERO, 2.1, "E : pousser le bloc", "Gâchette : pousser", func(): me2._push_block(kk), func(): return not bool(me2.state["blocs"]))
		it["bloc"] = i3
	ia("blocs_remise", Vector3(17.4, 0, 72.0), 1.2, "E : tirer l'anneau de bronze (remettre les blocs en place)", "Gâchette : l'anneau", func(): me._reset_blocks(), func(): return not bool(me.state["blocs"]))
	ia("anubis", Vector3(0, 0, 114.6), 2.6, "E : te présenter devant Anubis", "Gâchette : Anubis", func(): me._pesee_start(), func(): return not bool(me.state["pesee"]) and not me.fight)
	ia("oeil", Vector3(0, 0.6, 166.6), 2.6, "E : prendre l'Œil d'Horus", "Gâchette : l'Œil d'Horus", func(): me._take_eye(), func(): return bool(me.state["boss"]) and not bool(me.state["fini"]))
	ia("barque", Vector3(0, 0.6, 166.6), 2.6, "E : monter dans la barque de Rê (vers la lumière)", "Gâchette : la barque",
		func(): me.leave("La barque de Rê glisse sur le fleuve de la nuit… et te dépose au soleil, devant la porte de la pyramide."), func(): return bool(me.state["fini"]))
	# le Sphinx et la porte sont enregistrés par register(), au démarrage


func _apply_state() -> void:
	super._apply_state()
	if drums.is_empty():
		return
	var st: Array = state["tambours"]
	for i in range(3):
		_show_drum(i, int(st[i]), false)
	_show_mirrors(false)
	_draw_beam()
	_place_blocks(false)
	if _chest_blocs != null:
		var base_y: float = float(_chest_blocs.get_meta("y_base", _chest_blocs.position.y + (1.0 if not bool(state["blocs"]) else 0.0)))
		_chest_blocs.set_meta("y_base", base_y)
		_chest_blocs.position.y = base_y if bool(state["blocs"]) else base_y - 1.0
	for n in ["serket", "scarabees", "blocs", "obscure"]:
		var c: Node3D = (rooms[n]["root"] as Node3D).get_node_or_null("Coffre_" + n)
		if c != null:
			(c.get_meta("lid") as Node3D).rotation.x = -1.6 if bool((state["coffres"] as Dictionary).get(n, false)) else 0.0
	_osiris.visible = bool(state["osiris"])
	_scale_beam.rotation.z = 0.0 if bool(state["pesee"]) else 0.22
	_feather_mat.emission_energy_multiplier = 2.0 if bool(state["pesee"]) else 0.3
	_sun_disc_mat.emission_energy_multiplier = 4.0 if bool(state["boss"]) else 0.0
	_sun_disc_light.light_energy = 4.5 if bool(state["boss"]) else 0.0
	_eye.visible = bool(state["boss"]) and not bool(state["fini"])


# =================================================================== le Sphinx

const SPHINX := [
	["Écoute, voyageur. Quel est l'être qui marche à quatre pattes le matin, sur deux pattes à midi, et sur trois pattes le soir ?",
		[["lion", "Le lion du désert"], ["homme", "L'homme"], ["scarabee", "Le scarabée"]], "homme",
		"« L'homme. » Bébé, il marche à quatre pattes ; grand, sur ses deux jambes ; vieux, avec un bâton. Bien."],
	["Le matin, je suis un scarabée qui pousse une boule de feu. À midi, un faucon qui brille au-dessus du monde. Le soir, un vieillard à tête de bélier qui descend dans la nuit. Qui suis-je ?",
		[["osiris", "Osiris"], ["re", "Rê, le soleil"], ["nil", "Le Nil, le grand fleuve"]], "re",
		"« Rê, le soleil. » Khépri le matin, Rê à midi, Atoum le soir. Chaque nuit, je voyage dans sa barque jusqu'à l'aube."],
	["Dernière question. Mon frère jaloux m'a enfermé dans un coffre et jeté dans le fleuve ; puis il a coupé mon corps en morceaux. Mon épouse a cherché chaque morceau et m'a rendu la vie. Depuis, je règne sur le royaume des morts. Qui suis-je ?",
		[["horus", "Horus, le faucon"], ["anubis", "Anubis, le chacal"], ["osiris", "Osiris, le roi des morts"]], "osiris",
		"« Osiris. » Seth l'a trahi, Isis l'a rassemblé. Souviens-t'en, là-dessous : son corps est encore dispersé."],
]


func _sphinx() -> void:
	_sphinx_step = int(sol.state["sphinx"])
	if _sphinx_step == 0:
		_sfx("statue_parle", sol.egypte.sphinx_face)
	_sphinx_ask()


func _sphinx_ask() -> void:
	var q: Array = SPHINX[_sphinx_step]
	var choices: Array = []
	for c in q[1]:
		choices.append({"id": str(c[0]), "label": str(c[1])})
	choices.append({"id": "fermer", "label": "Je reviendrai plus tard."})
	var intro: String = ""
	if _sphinx_step == 0:
		intro = "Une voix de pierre, grave comme le désert : « Je garde la porte de Rê. Réponds à mes trois questions, et elle s'ouvrira. Trompe-toi, et reviens quand tu sauras. » "
	_ask(sol.egypte.sphinx_face, "Le Sphinx", "de pierre", intro + "« " + str(q[0]) + " »", choices, Callable(self, "_sphinx_answer"))


func _sphinx_answer(id: String) -> void:
	var q: Array = SPHINX[_sphinx_step]
	if id != str(q[2]):
		_close_dialog()
		_say("Le Sphinx gronde, et le sable tremble : « Non. Va, réfléchis, et reviens quand tu sauras. »", 5.0)
		_sfx("statue_parle", sol.egypte.sphinx_face)
		return
	_sphinx_step += 1
	sol.state["sphinx"] = _sphinx_step
	_sfx("sistre", sol.egypte.sphinx_face)
	if _sphinx_step < 3:
		var nxt: Array = SPHINX[_sphinx_step]
		var choices: Array = []
		for c in nxt[1]:
			choices.append({"id": str(c[0]), "label": str(c[1])})
		choices.append({"id": "fermer", "label": "Je reviendrai plus tard."})
		_ask(sol.egypte.sphinx_face, "Le Sphinx", "de pierre", str(q[3]) + "\n\n« " + str(nxt[0]) + " »", choices, Callable(self, "_sphinx_answer"))
		return
	_ask(sol.egypte.sphinx_face, "Le Sphinx", "de pierre", str(q[3]) + "\n\n« Tu as l'esprit clair, voyageur. Va : la porte de Rê est ouverte. Mais prends garde à Apophis, qui attend la barque du soleil au fond de la nuit. »",
		[{"id": "fermer", "label": "Merci, Sphinx."}], Callable(self, "_sphinx_answer"))
	_sfx("pierre_glisse", sol.egypte.pyramid_door + Vector3.UP)
	if main.has_method("jingle"):
		main.jingle("decouverte")
	var j: Node = main.get("journal_v56")
	if j != null and j.has_method("refresh"):
		j.refresh()


# =================================================================== Thot

func _turn_drum(i: int) -> void:
	var st: Array = state["tambours"]
	st[i] = (int(st[i]) + 1) % 6
	_show_drum(i, int(st[i]), true)
	_sfx("mecanisme", (drums[i] as Node3D).global_position)
	if int(st[0]) == DRUM_GOAL[0] and int(st[1]) == DRUM_GOAL[1] and int(st[2]) == DRUM_GOAL[2]:
		state["thot"] = true
		_sfx("sistre", (drums[1] as Node3D).global_position)
		await get_tree().create_timer(0.7).timeout
		open_gate("thot", "L'ibis, l'œil d'Horus, le soleil : le nom du roi est écrit ! Un déclic profond… la porte de pierre s'enfonce dans le sol.")


# =================================================================== Osiris

func _sarcophagus() -> void:
	var n: int = _inv().count("fragment_osiris")
	if n < 4:
		_say("Le sarcophage d'Osiris est vide. Sur son couvercle, ces mots : « Seth a dispersé mon corps aux quatre chapelles d'Isis. Rassemble-moi, et je te laisserai passer. » (Morceaux d'Osiris : %d sur 4)" % n, 8.0)
		return
	_inv().remove("fragment_osiris", 4)
	state["osiris"] = true
	_osiris.visible = true
	_osiris.scale = Vector3.ONE * 0.05
	create_tween().tween_property(_osiris, "scale", Vector3.ONE, 2.5).set_trans(Tween.TRANS_SINE)
	_sfx("esprit", _osiris.global_position)
	_say("Tu poses les quatre morceaux dans le sarcophage… Une lumière verte, comme le blé qui pousse, monte de la cuve : Osiris est rassemblé ! Une voix très douce : « Merci. Va maintenant devant Anubis : ton cœur sera pesé. »", 9.0)
	await get_tree().create_timer(3.0).timeout
	open_gate("verites")


# =================================================================== la pesée du cœur

const PESEE := [
	["Anubis", "Je suis Anubis, le gardien de la balance. Ton cœur va être pesé. Sur l'autre plateau, que pose-t-on ?",
		[["or", "Un lingot d'or, pour payer les dieux"], ["plume", "La plume de Maât, la Vérité"], ["lion", "Le cœur d'un lion"]], "plume"],
	["Thot", "Je suis Thot, qui écrit le jugement. Si un cœur est plus lourd que la plume, alourdi de mensonges… qui le dévore ?",
		[["apophis", "Apophis, le serpent"], ["ammit", "Ammit, la Dévoreuse"], ["sobek", "Sobek, le dieu crocodile"]], "ammit"],
	["Anubis", "Dis maintenant ta confession devant les quarante-deux juges.",
		[["fort", "« Je suis le plus fort : j'ai vaincu tous mes ennemis. »"], ["vrai", "« Je n'ai pas menti, je n'ai pas volé, je n'ai fait pleurer personne. »"], ["riche", "« J'ai beaucoup d'or, et de beaux habits. »"]], "vrai"],
]


func _pesee_start() -> void:
	_pesee_step = 0
	_sfx("battement", W(Vector3(0, 2, 119)))
	_pesee_ask("Tu montes sur l'estrade. Ton cœur s'envole de ta poitrine — tu le vois ! — et se pose sur le plateau de gauche. Le chacal se penche vers toi.\n\n")


func _pesee_ask(prefix: String) -> void:
	var q: Array = PESEE[_pesee_step]
	var choices: Array = []
	for c in q[2]:
		choices.append({"id": str(c[0]), "label": str(c[1])})
	var at: Vector3 = W(Vector3(-3.4 if str(q[0]) == "Anubis" else 3.4, 0.6 + 2.4 * 2.05, 119.0 - 0.6))
	_ask(at, str(q[0]), "solennel", prefix + "« " + str(q[1]) + " »", choices, Callable(self, "_pesee_answer"))


func _pesee_answer(id: String) -> void:
	var q: Array = PESEE[_pesee_step]
	if id != str(q[3]):
		_close_dialog()
		_lie()
		return
	_pesee_step += 1
	_sfx("battement", W(Vector3(0, 2, 119)))
	if _pesee_step < PESEE.size():
		create_tween().tween_property(_scale_beam, "rotation:z", 0.22 * (1.0 - float(_pesee_step) / 3.0), 0.8)
		_pesee_ask("")
		return
	_close_dialog()
	state["pesee"] = true
	create_tween().tween_property(_scale_beam, "rotation:z", 0.0, 1.5).set_trans(Tween.TRANS_SINE)
	_feather_mat.emission_energy_multiplier = 2.0
	_sfx("sistre", W(Vector3(0, 2, 119)))
	_say("La balance s'équilibre : ton cœur est aussi léger que la plume de Maât ! Thot écrit sur sa tablette : « Juste de voix. » Ton cœur revient dans ta poitrine… et au fond de la salle, la porte de la Douat s'ouvre.", 9.0)
	await get_tree().create_timer(3.0).timeout
	open_gate("douat")


func _lie() -> void:
	create_tween().tween_property(_scale_beam, "rotation:z", 0.45, 0.6).set_trans(Tween.TRANS_BACK)
	_say("La balance penche lourdement : ton cœur pèse plus que la plume ! Dans l'ombre, derrière les juges, quelque chose gronde… AMMIT LA DÉVOREUSE surgit !", 6.0)
	_sfx("ammit_cri", W(Vector3(0, 2, 126)))
	await get_tree().create_timer(1.2).timeout
	if room != "verites":
		return
	_ammit = _start_boss("ammit", Vector3(0, 0, 126.0), "Ammit la Dévoreuse", Callable(self, "_ammit_dead"))


func _ammit_dead() -> void:
	create_tween().tween_property(_scale_beam, "rotation:z", 0.22, 1.0)
	_say("Ammit s'effondre et se dissout dans l'ombre. Anubis n'a pas bougé. Tu peux te présenter de nouveau devant la balance… et dire la vérité, cette fois.", 7.0)


# =================================================================== la Douat, Apophis

func _tick(delta: float, p: Vector3, r: String) -> void:
	var l: Vector3 = L(p)
	match r:
		"scarabees":
			_sand_fx_t = maxf(_sand_fx_t - delta, 0.0)
			if l.y < -0.6 and l.x < -17.9 and l.x > -32.1 and _sand_fx_t <= 0.0:
				_sand_fx_t = 3.0
				_collapse_under(l)
			if l.y < -3.0 and _fall_cd <= 0.0:
				_fall_cd = 1.5
				_fall_back("Tu remontes de la fosse, couvert de sable, à l'entrée de la chapelle. Ces dalles-là ne portaient rien… Les scarabées, eux, savent où marcher.", 2)
		"douat":
			if not bool(state["boss"]) and not fight and l.z > 146.0:
				_say("Le fleuve de la nuit se met à bouillonner. Une tête énorme sort de l'eau noire, des yeux rouges comme des braises : APOPHIS, le serpent du chaos, qui veut avaler le soleil !", 7.0)
				_start_boss("apophis", Vector3(0, 0, 160.0), "Apophis, le serpent du chaos", Callable(self, "_apophis_dead"))
	if _eye != null and _eye.visible:
		_eye.position.y += sin(_clock * 2.0) * delta * 0.15
		_eye.rotate_y(delta * 0.8)
	# les dalles des scarabées qui retombent à leur place
	for k in _tiles:
		var t: MeshInstance3D = _tiles[k]
		if t.has_meta("drop_t"):
			var dt: float = float(t.get_meta("drop_t")) - delta
			t.set_meta("drop_t", dt)
			if dt <= 0.0:
				t.remove_meta("drop_t")
				t.position.y = float(t.get_meta("y0"))


func _collapse_under(l: Vector3) -> void:
	var i: int = clampi(int(round((-19.0 - l.x) / 2.0)), 0, 6)
	var j: int = clampi(int(round((l.z - 88.0) / 2.0)), 0, 5)
	var k: String = "%d,%d" % [i, j]
	_sfx("sable_effondre", W(l) + Vector3.UP)
	if _tiles.has(k):
		var t: MeshInstance3D = _tiles[k]
		t.set_meta("drop_t", 4.0)
		create_tween().tween_property(t, "position:y", float(t.get_meta("y0")) - 4.6, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if main.combat_v28 != null:
		for n in range(5):
			main.combat_v28.puff(W(l) + Vector3(randf_range(-0.8, 0.8), 0.2, randf_range(-0.8, 0.8)), Color(0.85, 0.72, 0.5))


func _apophis_dead() -> void:
	state["boss"] = true
	_sfx("sistre", W(Vector3(0, 4, 172)))
	var tw := create_tween()
	tw.tween_property(_sun_disc_mat, "emission_energy_multiplier", 4.0, 3.0)
	tw.parallel().tween_property(_sun_disc_light, "light_energy", 4.5, 3.0)
	_say("Apophis s'enfonce dans l'eau noire en sifflant… vaincu ! Au-dessus de la barque, le disque du soleil se rallume, d'abord rouge comme l'aube, puis d'or. Rê est sauvé : demain, le soleil se lèvera. Et devant la barque, quelque chose brille…", 9.0)
	await get_tree().create_timer(3.0).timeout
	_eye.visible = true
	_eye.scale = Vector3.ONE * 0.1
	create_tween().tween_property(_eye, "scale", Vector3.ONE, 1.5)


func _take_eye() -> void:
	state["fini"] = true
	_eye.visible = false
	_reward("oeil_horus", "Œil de Rê", 150, W(Vector3(0, 0.8, 166.0)))
	main._show_message_v28("L'Œil d'Horus ! L'œil que Thot a guéri, le signe de la lumière qui revient. 150 pièces, un cœur de plus, et un titre : « Œil de Rê ». La barque de Rê te ramènera à la lumière. Sur les hautes terres, une niche de l'Autel des Trois Soleils attend cet œil.")


func _on_enter(first: bool) -> void:
	if first:
		_say("Le vestibule de la Pyramide de Rê. L'air est frais, immobile, et sent la pierre et l'encens. Sur les murs, des milliers de signes peints ; à gauche, la barque du soleil qui navigue dans la nuit.", 9.0)
	else:
		_say("La Pyramide de Rê.", 3.0)


func _enter_room(_old: String, r: String) -> void:
	match r:
		"thot":
			_once("thot", "La salle de Thot. Un dieu à tête d'ibis devant un grand papyrus ; devant la porte, trois tambours de pierre couverts de signes. Et dans l'ombre, des bandelettes qui bougent…", 7.0)
		"galerie":
			_once("galerie", "La Grande Galerie. Un rayon de soleil — ici, si profond ! — entre par un conduit étroit et frappe un miroir de bronze. Il y en a d'autres, sur des pieds. Au fond, sur la porte, un disque d'or éteint.", 8.0)
		"chapelles":
			_once("chapelles", "La salle d'Osiris. Au milieu, un sarcophage ouvert… vide. Quatre portes mènent aux chapelles d'Isis.", 6.0)
		"serket":
			_once("serket", "La chapelle de Serket, la déesse au scorpion. Ça gratte, dans les coins…", 4.0)
		"scarabees":
			_once("scarabees", "La chapelle de Khépri, le scarabée. Un sol de dalles au-dessus d'une fosse de sable. Certaines sont gravées d'un tout petit scarabée.", 6.0)
		"blocs":
			_once("blocs", "La chapelle d'Isis. Deux gros blocs de granit, et deux dalles de bronze gravées d'une croix ankh. Près de l'entrée, un anneau de bronze au mur.", 6.0)
		"obscure":
			_once("obscure", "La chapelle obscure. Pas une torche. Juste une lueur verte, tout au fond… et des pas qui traînent.", 5.0)
		"verites":
			_once("verites", "La Salle des Deux Vérités. Anubis, le dieu chacal, et Thot, le dieu ibis, devant une grande balance d'or. Le long des murs, les quarante-deux juges.", 7.0)
		"douat":
			if not bool(state["boss"]):
				_once("douat", "La Douat, le monde de la nuit. Un ciel d'étoiles sous la pierre, un fleuve noir de chaque côté, et au fond la barque de Rê, éteinte. Le silence… trop de silence.", 8.0)


func _fall_text(r: String) -> String:
	if r == "scarabees":
		return "Tu remontes de la fosse, couvert de sable."
	return super._fall_text(r)


func _faint_text() -> String:
	return "L'encens et la pierre fraîche…"


func _on_reset() -> void:
	_ammit = null


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# les invites des blocs suivent les blocs
	if not built or blocks.is_empty():
		return
	for it in _ia:
		if it.has("bloc"):
			it["pos"] = (blocks[int(it["bloc"])] as Node3D).global_position
