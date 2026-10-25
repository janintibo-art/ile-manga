extends "res://scripts/enigmes_v69.gd"
## V71 : le Donjon des Mille Marches, sous les Crocs de l'Île de Montjoie (la vieille tour en
## ruine ; Odon, le gardien, tient le registre à l'entrée). Cinq étages, de plus en plus bas :
##  1. les Caves Gluantes : un petit labyrinthe moussu, des slimes, un coffre au fond d'un cul-de-sac ;
##  2. la Salle des Pièges : des dalles fêlées (des fléchettes jaillissent du mur), le Couloir du
##     Rocher (un rocher qui roule : cours, ou cache-toi dans une niche), trois leviers qui ouvrent
##     la porte, des gobelins ;
##  3. le Lac Souterrain : des pierres plates pour passer l'eau, des grenouilles géantes ; la clé
##     de cuivre est dans le ventre de l'une d'elles (celle qui brille) ; la porte de cuivre ;
##  4. la Bibliothèque des Mimiques : six coffres sur six estrades, trois ont des dents ; le Grand
##     Livre des Coffres dit lequel est le bon (la clé d'argent, pour la porte d'argent) ; des
##     squelettes ;
##  5. la Salle du Trône Gélatineux : le Roi Gélatineux (il se divise aux deux tiers et au tiers :
##     monstre_v71) ; le Cœur de gelée royale, un titre, l'escalier de lumière.
## À chaque étage, un cristal de retour (E : remonter à l'entrée). Odon note l'étage le plus
## profond atteint (state["profond"]) ; dans le hall, le cristal de descente y mène directement.
## Repère : O, loin sous l'île (y < -40 : « sous terre » pour donjon_v35) ; l'étage k est à
## y = -12 × (k - 1) (local). Les escaliers sont tous en x = 12, de 4 m de large.
## Le gestionnaire de l'île (montjoie_v71) : setup(main, mj), enter(), contains(p), near(p),
## ensure_built(), respawn(), register(journal), serialize(), load_data(d), state, room, fight ;
## et, pour lui : trouvailles(), music(), ambience(), deepest().

const IleR = preload("res://scripts/ile_montjoie_v71.gd")
const T := 0.8
## l'étage de chaque salle (les escaliers comptent pour l'étage du haut)
const FLOOR := {"hall": 1, "caves": 1, "esc1": 1, "pieges": 2, "couloir": 2, "esc2": 2, "lac": 3, "esc3": 3,
	"biblio": 4, "esc4": 4, "trone": 5}
const FLOOR_NAMES := ["", "les Caves Gluantes", "la Salle des Pièges", "le Lac Souterrain", "la Bibliothèque des Mimiques", "la Salle du Trône Gélatineux"]
## l'arrivée de chaque étage (au pied de l'escalier) et son cristal de retour
const ARRIVE := [Vector3(0, 0, 4.0), Vector3(0, 0, 4.0), Vector3(12, -12, 76.5), Vector3(12, -24, 134.5), Vector3(12, -36, 208.5), Vector3(12, -48, 268.5)]
const CRYSTALS := [Vector3.ZERO, Vector3(4.2, 0, 9.0), Vector3(7.5, -12, 77.5), Vector3(6.5, -24, 135.5), Vector3(6.5, -36, 209.5), Vector3(6.5, -48, 269.5)]
## le labyrinthe des Caves : 6 × 6 cases de 6 m
const MZ_X0 := -21.0
const MZ_Z0 := 12.0
const MZ_C := 6.0
const MZ_N := 6
## la Salle des Pièges : le champ de dalles (10 × 13 dalles de 2 m), le chemin sûr
const TR_X0 := 16.0
const TR_Z0 := 80.0
const TR_NX := 10
const TR_NZ := 13
const SAFE := [[0, 0], [1, 0], [2, 0], [3, 0], [3, 1], [3, 2], [3, 3], [3, 4], [4, 4], [5, 4], [6, 4], [7, 4], [7, 5], [7, 6], [7, 7], [7, 8],
	[6, 8], [5, 8], [5, 9], [5, 10], [5, 11], [5, 12], [6, 12], [7, 12], [8, 12], [9, 12]]
## les trois leviers : position (locale, au mur), direction vers la salle
const LEVERS := [[Vector3(-36.0, -12, 86.08), Vector3(0, 0, 1)], [Vector3(35.92, -12, 105.0), Vector3(-1, 0, 0)], [Vector3(-9.0, -12, 105.92), Vector3(0, 0, -1)]]
## le Couloir du Rocher : les niches (x), le rocher (rayon), d'où il part, où il se brise
const NICHES := [-34.0, -26.0, -18.0]
const BALL_R := 2.6
const BALL_X0 := -39.6
const BALL_X1 := -14.2
const BALL_Z := 89.0
## le Lac : les pierres plates [x, z, rayon], les îlots [x, z, rayon]
const STONES := [[12.0, 144.4, 1.1], [10.0, 147.4, 1.0], [12.6, 150.4, 1.05], [10.2, 153.4, 1.0], [12.0, 156.6, 1.1], [14.0, 159.6, 1.0],
	[12.2, 162.6, 1.05], [10.6, 165.6, 1.0], [12.0, 168.6, 1.1],
	[7.2, 155.4, 0.95], [4.0, 156.6, 0.95], [1.0, 155.8, 0.9],
	[16.6, 151.4, 0.95], [20.0, 150.8, 0.95], [23.4, 152.2, 0.9]]
const ISLES := [[-4.0, 156.0, 4.0], [30.0, 152.0, 3.5]]
const FROG_KEY := Vector3(-4.0, -24, 156.0)
## la Bibliothèque : les six estrades [x, z, statuette, rôle] (rôle : vrai, leurre, mimique)
const DAIS := [[-8.0, 216.0, "crane", "mimique"], [-8.0, 230.0, "couronne", "mimique"], [32.0, 216.0, "chandelle", "leurre"],
	[32.0, 230.0, "sablier", "mimique"], [2.0, 223.0, "livres", "leurre"], [22.0, 223.0, "hibou", "vrai"]]
const FILL := {"hall": Color(1.0, 0.8, 0.6), "caves": Color(0.7, 0.95, 0.6), "esc1": Color(1.0, 0.78, 0.55), "pieges": Color(1.0, 0.75, 0.5),
	"couloir": Color(1.0, 0.7, 0.45), "esc2": Color(1.0, 0.78, 0.55), "lac": Color(0.55, 0.75, 1.0), "esc3": Color(0.75, 0.82, 1.0),
	"biblio": Color(1.0, 0.82, 0.55), "esc4": Color(1.0, 0.78, 0.55), "trone": Color(0.75, 1.0, 0.6)}

var mj: Node                              # montjoie_v71 (le gestionnaire de l'île)
var _own_mats: Dictionary = {}
var _maze_e: Array = []                   # [c][r] : passage vers l'est
var _maze_s: Array = []                   # [c][r] : passage vers le sud
var _trap_tiles: Dictionary = {}          # "c,r" -> MeshInstance3D (les dalles piégées)
var _trap_cd: Dictionary = {}
var _levers: Array = []                   # Node3D (la poignée)
var _lamps: Array = []                    # [StandardMaterial3D, OmniLight3D]
var _ball: Node3D
var _ball_on: bool = false
var _ball_x: float = 0.0
var _ball_v: float = 0.0
var _ball_t: float = 0.0
var _ball_hit: bool = false
var _ball_snd: float = 0.0
var _carrier: Node3D                      # la grenouille qui a avalé la clé
var _mimics_set: bool = false
var _mimics: Dictionary = {}              # indice de l'estrade -> la mimique
var _light_stairs: Node3D
var _shortcut_ia: Dictionary = {}
var _crystal_nodes: Array = []
var _strays_t: float = 0.0


func _init() -> void:
	key = "mille_marches"
	titre = "le Donjon des Mille Marches"
	O = Vector3(640.0, -80.0, 540.0)
	bbox = AABB(Vector3(-46.0, -54.0, -4.0), Vector3(90.0, 64.0, 318.0))
	room_spawns = {
		"caves": [["slime", -18.0, 0.0, 21.0], ["slime", 6.0, 0.0, 27.0], ["slime_bleu", -12.0, 0.0, 33.0], ["slime", -6.0, 0.0, 39.0],
			["slime_bleu", 12.0, 0.0, 33.0], ["slime", 0.0, 0.0, 45.0]],
		"pieges": [["gobelin", -6.0, -12.0, 80.0], ["gobelin", 2.0, -12.0, 84.0], ["gobelin", -4.0, -12.0, 99.0], ["gobelin", 4.0, -12.0, 95.0]],
		"lac": [["grenouille_geante", FROG_KEY.x, -24.0, FROG_KEY.z, func(): return not bool(state["cle"])], ["grenouille_geante", 28.0, -24.0, 137.0],
			["grenouille_geante", 30.0, -24.0, 152.0], ["grenouille_geante", 20.0, -24.0, 174.0]],
		"biblio": [["squelette", 12.0, -36.0, 215.0], ["squelette", 2.0, -36.0, 233.0], ["squelette", 24.0, -36.0, 233.0],
			["mimique", -8.0, -35.7, 216.0], ["mimique", -8.0, -35.7, 230.0], ["mimique", 32.0, -35.7, 230.0]],
	}


func setup(main_node: Node, manager: Node) -> void:
	super.setup(main_node, manager)
	mj = manager


func _defaults() -> Dictionary:
	return {"profond": 0, "leviers": [false, false, false], "rocher": false, "cle": false, "vrai_coffre": false, "mimiques": 0}


## Le donjon se dessine avec le kit de Montjoie (ses matières « …71 », et celles des donjons).
func ensure_built() -> void:
	if built:
		return
	built = true
	var t0: int = Time.get_ticks_msec()
	kit = load("res://scripts/montjoie_kit_v71.gd").new()
	kit.setup69(self, main, pc)
	kit.body.name = "Collisions_donjon_" + key
	_own_materials()
	_build()
	_register()
	_apply_state()
	_hide_all(false)
	print("ILE_MANGA_V71: %s construit en %d ms" % [titre, Time.get_ticks_msec() - t0])


func entry() -> Array:
	return [W(ARRIVE[1]), Vector3(0, 0, 1)]


## On ressort devant l'escalier de la tour en ruine, dos aux marches (vers la ville).
func exit_point() -> Array:
	var dh: Node = mj.get("dehors") if mj != null else null
	var dd: Variant = dh.get("dungeon_door") if dh != null else null
	if not (dd is Vector3) or dd == Vector3.ZERO:
		return [IleR.W(IleR.DUNGEON.x, IleR.DUNGEON.y, 1.0), Vector3(0, 0, 1)]
	var door: Vector3 = dd
	var town: Vector3 = IleR.W(IleR.TOWN.x, IleR.TOWN.y)
	var d := Vector3(town.x - door.x, 0, town.z - door.z)
	d = d.normalized() if d.length() > 0.1 else Vector3(0, 0, 1)
	return [door + d * 1.0 + Vector3.UP * 0.1, d]


## L'étage le plus profond atteint (Odon le note dans son registre).
func deepest() -> int:
	return int(state.get("profond", 0))


## Pour la musique : le donjon, ou le combat contre le Roi Gélatineux.
func music() -> String:
	return "roi_gelatineux" if fight else "donjon_mille_marches"


## Pour les ambiances : l'eau qui goutte au lac, les caves ailleurs.
func ambience() -> String:
	return "donjon_lac" if room in ["lac", "esc3"] else "donjon_caves"


## Ce que le carnet (journal_v56, quêtes « etat ») et la carte doivent savoir.
func trouvailles() -> Dictionary:
	return {"mille_marches_visite": 1 if bool(state["visite"]) else 0, "mille_marches": 1 if bool(state["fini"]) else 0,
		"roi_gelatineux": 1 if bool(state["boss"]) else 0, "mm_etage_2": 1 if deepest() >= 2 else 0, "mm_etage_3": 1 if deepest() >= 3 else 0,
		"mm_etage_4": 1 if deepest() >= 4 else 0, "mm_etage_5": 1 if deepest() >= 5 else 0,
		"mm_leviers": 1 if gate_open("pieges") else 0, "cle_cuivre_lac": 1 if bool(state["cle"]) else 0,
		"vrai_coffre": 1 if bool(state["vrai_coffre"]) else 0}


# =================================================================== outils

func _xf() -> Transform3D:
	return Transform3D(Basis(), O)


func _root(n: String) -> Node3D:
	return rooms[n]["root"]


func _torch(n: String, l: Vector3, facing: Vector3, energy: float = 1.5) -> void:
	kit.torch(rooms[n]["root"], W(l), facing, energy)


func _block(a: Vector3, b: Vector3, k: String, tile: float = 3.0) -> void:
	kit.solid(X((a + b) * 0.5), (b - a).abs(), k, tile)


## Les matières de ce donjon qui ne sont pas dans montjoie_mats_v71 (posées dans kit.mats).
func _own_materials() -> void:
	var ar := StandardMaterial3D.new()
	ar.albedo_color = Color(0.78, 0.8, 0.84)
	ar.metallic = 0.9
	ar.roughness = 0.28
	kit.mats["argent71m"] = ar
	var cu := StandardMaterial3D.new()
	cu.albedo_color = Color(0.72, 0.42, 0.24)
	cu.metallic = 0.85
	cu.roughness = 0.36
	kit.mats["cuivre71m"] = cu
	var li := StandardMaterial3D.new()
	li.albedo_color = Color(1.0, 0.92, 0.6, 0.7)
	li.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	li.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	li.emission_enabled = true
	li.emission = Color(1.0, 0.85, 0.45)
	li.emission_energy_multiplier = 2.5
	kit.mats["lumiere71m"] = li
	var ch := StandardMaterial3D.new()
	ch.albedo_color = Color(0.35, 0.8, 1.0)
	ch.emission_enabled = true
	ch.emission = Color(0.3, 0.75, 1.0)
	ch.emission_energy_multiplier = 2.2
	ch.roughness = 0.5
	kit.mats["champi71m"] = ch
	var cv := StandardMaterial3D.new()
	cv.albedo_color = Color(0.86, 0.8, 0.66)
	cv.roughness = 0.85
	kit.mats["pied71m"] = cv
	var pa := StandardMaterial3D.new()
	pa.albedo_color = Color(0.93, 0.87, 0.72)
	pa.roughness = 0.9
	kit.mats["parchemin71m"] = pa
	var cd := StandardMaterial3D.new()
	cd.albedo_color = Color(0.96, 0.93, 0.85)
	cd.roughness = 0.6
	kit.mats["cire71m"] = cd
	var os := StandardMaterial3D.new()
	os.albedo_color = Color(0.88, 0.85, 0.76)
	os.roughness = 0.7
	kit.mats["os71m"] = os
	var plume := StandardMaterial3D.new()
	plume.albedo_color = Color(0.45, 0.32, 0.2)
	plume.roughness = 0.9
	kit.mats["plume71m"] = plume
	var oeil := StandardMaterial3D.new()
	oeil.albedo_color = Color(1.0, 0.8, 0.25)
	oeil.emission_enabled = true
	oeil.emission = Color(1.0, 0.7, 0.2)
	oeil.emission_energy_multiplier = 1.2
	kit.mats["oeil71m"] = oeil


func _m(k: String) -> Material:
	return kit.mat(k)


func _mesh(parent: Node3D, mesh: Mesh, k: String, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _m(k)
	parent.add_child(mi)
	mi.position = pos
	mi.rotation = rot
	return mi


func _sphere(r: float, h: float = -1.0) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = h if h > 0.0 else r * 2.0
	s.radial_segments = 20
	s.rings = 10
	return s


func _cylm(r0: float, r1: float, h: float, seg: int = 14) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r1
	c.bottom_radius = r0
	c.height = h
	c.radial_segments = seg
	return c


func _boxm(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b


## Une plaque de bois au mur, avec son texte (Label3D) : l = le centre, yaw : elle regarde +Z tourné.
func _plaque(n: String, l: Vector3, yaw: float, w: float, h: float, text: String, font: int = 40) -> void:
	var bs := Basis(Vector3.UP, yaw)
	kit.box(Transform3D(bs, W(l + bs * Vector3(0, 0, -0.05))), Vector3(w, h, 0.08), "planches71_sombre", 1.0)
	for s in [-1.0, 1.0]:
		kit.box(Transform3D(bs, W(l + bs * Vector3(s * (w * 0.5 - 0.06), 0, 0.0))), Vector3(0.1, h + 0.06, 0.06), "fer71", 1.0)
	var lb := Label3D.new()
	lb.text = text
	lb.font_size = font
	lb.pixel_size = 0.0042
	lb.outline_size = 6
	lb.outline_modulate = Color(0.08, 0.05, 0.03)
	lb.modulate = Color(0.95, 0.86, 0.66)
	lb.width = w / 0.0042 * 0.92
	lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root(n).add_child(lb)
	lb.global_transform = Transform3D(bs, W(l + bs * Vector3(0, 0, 0.012)))


## La lumière d'ambiance de chaque salle (sans ombre) : les pierres sont sombres.
func _fill_lights() -> void:
	for n in rooms:
		var a: Vector3 = rooms[n]["a"]
		var b: Vector3 = rooms[n]["b"]
		var size: Vector3 = b - a
		var cells: Array = [Vector3((a.x + b.x) * 0.5, 0, (a.z + b.z) * 0.5)]
		if maxf(size.x, size.z) > 30.0:
			cells.clear()
			var along_x: bool = size.x > size.z
			for k in range(2):
				var t: float = 0.27 + 0.46 * k
				cells.append(Vector3(lerpf(a.x, b.x, t) if along_x else (a.x + b.x) * 0.5, 0, (a.z + b.z) * 0.5 if along_x else lerpf(a.z, b.z, t)))
		var stairs: bool = str(n).begins_with("esc")
		for c in cells:
			var l := OmniLight3D.new()
			l.name = "Ambiance"
			l.light_color = FILL.get(n, Color(1.0, 0.8, 0.6))
			l.light_energy = 0.85
			l.light_specular = 0.1
			l.shadow_enabled = false
			l.omni_range = clampf(maxf(size.x, size.z) * (0.42 if cells.size() > 1 else 0.75), 12.0, 30.0)
			l.omni_attenuation = 0.6
			_root(n).add_child(l)
			var y: float = (a.y + b.y) * 0.5 if stairs else minf(b.y - 1.5, a.y + 6.0)
			l.global_position = W(Vector3(c.x, y, c.z))


## Un cristal de retour (bleu, il flotte et tourne sur son socle) ; aussi le cristal de descente.
func _crystal(n: String, l: Vector3, col: Color) -> Node3D:
	kit.cyl(X(l), 0.45, 0.35, 0.8, "donjon71_clair", 10, true, 1.0)
	kit.cyl(X(l + Vector3(0, 0.8, 0)), 0.42, 0.42, 0.08, "laiton71", 12)
	kit.col_cyl(W(l), 0.45, 0.9)
	var node := Node3D.new()
	node.name = "Cristal"
	_root(n).add_child(node)
	node.global_position = W(l + Vector3(0, 1.55, 0))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(col.r, col.g, col.b, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.08
	mat.metallic_specular = 0.9
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.8
	var top := MeshInstance3D.new()
	top.mesh = _cylm(0.26, 0.0, 0.5, 6)
	top.material_override = mat
	top.position = Vector3(0, 0.25, 0)
	node.add_child(top)
	var bot := MeshInstance3D.new()
	bot.mesh = _cylm(0.0, 0.26, 0.4, 6)
	bot.material_override = mat
	bot.position = Vector3(0, -0.2, 0)
	node.add_child(bot)
	var gl := OmniLight3D.new()
	gl.light_color = col
	gl.light_energy = 1.2
	gl.omni_range = 6.0
	node.add_child(gl)
	_crystal_nodes.append(node)
	return node


## Une touffe de champignons qui luisent (bleus), avec une petite lumière si light.
func _mushrooms(n: String, l: Vector3, count: int, seed_i: int, light: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_i
	for k in range(count):
		var a: float = rng.randf() * TAU
		var r: float = rng.randf_range(0.0, 0.6)
		var p: Vector3 = l + Vector3(cos(a) * r, 0, sin(a) * r)
		var h: float = rng.randf_range(0.12, 0.38)
		kit.cyl(X(p), 0.03, 0.025, h, "pied71m", 6, false, 1.0)
		kit.cyl(X(p + Vector3(0, h, 0)), rng.randf_range(0.07, 0.16), 0.02, rng.randf_range(0.05, 0.09), "champi71m", 10, true, 1.0)
	if light:
		kit.glow_light(_root(n), W(l + Vector3(0, 0.6, 0)), Color(0.35, 0.75, 1.0), 0.9, 6.0)


## Un escalier de l'étage du haut (yu) vers celui du bas (yu - 12), de z0 à z0 + 26, en x = 12.
func _build_stairs(n: String, z0: float, yu: float, floor_k: int) -> void:
	_in_room(n)
	var yl: float = yu - 12.0
	kit.solid(X(Vector3(12, yu - 0.3, z0 + 1.0)), Vector3(4.0 + 2 * T, 0.6, 2.0), "dallesd71", 3.0)
	kit.ramp(_xf(), Vector3(12, yl, z0 + 23.0), Vector3(12, yu, z0 + 2.0), 4.0, "dallesd71_vieux")
	kit.solid(X(Vector3(12, yl - 0.3, z0 + 24.5)), Vector3(4.0 + 2 * T, 0.6, 3.0), "dallesd71", 3.0)
	for x in [10.0 - T * 0.5, 14.0 + T * 0.5]:
		_block(Vector3(x - T * 0.5, yl - 0.6, z0 + T * 0.5), Vector3(x + T * 0.5, yu + 5.0, z0 + 26.0 - T * 0.5), "donjon71_vieux")
	# le plafond en gradins (il suit la pente)
	for i in range(13):
		var zs: float = z0 + 2.0 * i
		var f: float = yu if zs <= z0 + 2.0 else maxf(yu - (zs - z0 - 2.0) / 21.0 * 12.0, yl)
		kit.solid(X(Vector3(12, f + 4.6 + 1.25, zs + 1.0)), Vector3(4.0 + 2 * T, 2.5, 2.0), "donjon71_sombre", 3.0)
	for k in range(3):
		var z: float = z0 + 6.0 + k * 7.0
		var fy: float = maxf(yu - (z - z0 - 2.0) / 21.0 * 12.0, yl)
		_torch(n, Vector3(10.15 if k % 2 == 0 else 13.85, fy + 2.4, z), Vector3(1, 0, 0) if k % 2 == 0 else Vector3(-1, 0, 0), 1.3)
	# le compte des marches, gravé à mi-hauteur (Odon en a compté 999 en tout)
	var zm: float = z0 + 12.5
	var ym: float = yu - (zm - z0 - 2.0) / 21.0 * 12.0
	var counts := ["Marche 55. (Plus que 944.)", "Marche 300. Courage !", "Marche 610. Quelqu'un a écrit : « J'ai faim. »", "Marche 905. Presque !"]
	_plaque(n, Vector3(13.91, ym + 1.6, zm), -PI * 0.5, 1.4, 0.5, counts[clampi(floor_k - 1, 0, 3)], 30)


# =================================================================== construction

func _build() -> void:
	add_room("hall", Vector3(-6, 0, 0), Vector3(6, 6, 12), Vector3(0, 0, 4.0), Vector3(0, 0, 1), ["caves"])
	add_room("caves", Vector3(-21, 0, 12), Vector3(15, 5, 48), Vector3(0, 0, 13.5), Vector3(0, 0, 1), ["hall", "esc1"])
	add_room("esc1", Vector3(10, -12, 48), Vector3(14, 5, 74), Vector3(12, 0, 49.2), Vector3(0, 0, 1), ["caves", "pieges"])
	add_room("pieges", Vector3(-12, -12, 74), Vector3(36, -5, 106), ARRIVE[2], Vector3(0, 0, 1), ["esc1", "couloir", "esc2"])
	add_room("couloir", Vector3(-42, -12, 86), Vector3(-12, -6.5, 95), Vector3(-9.0, -12, 90.0), Vector3(-1, 0, 0), ["pieges"])
	add_room("esc2", Vector3(10, -24, 106), Vector3(14, -7, 132), Vector3(12, -12, 107.2), Vector3(0, 0, 1), ["pieges", "lac"])
	add_room("lac", Vector3(-20, -24, 132), Vector3(44, -12, 180), ARRIVE[3], Vector3(0, 0, 1), ["esc2", "esc3"])
	add_room("esc3", Vector3(10, -36, 180), Vector3(14, -19, 206), Vector3(12, -24, 181.2), Vector3(0, 0, 1), ["lac", "biblio"])
	add_room("biblio", Vector3(-16, -36, 206), Vector3(40, -27, 240), ARRIVE[4], Vector3(0, 0, 1), ["esc3", "esc4"])
	add_room("esc4", Vector3(10, -48, 240), Vector3(14, -31, 266), Vector3(12, -36, 241.2), Vector3(0, 0, 1), ["biblio", "trone"])
	add_room("trone", Vector3(-12, -48, 266), Vector3(36, -34, 310), ARRIVE[5], Vector3(0, 0, 1), ["esc4"])
	_build_hall()
	_build_caves()
	_build_stairs("esc1", 48.0, 0.0, 1)
	_build_pieges()
	_build_couloir()
	_build_stairs("esc2", 106.0, -12.0, 2)
	_build_lac()
	_build_stairs("esc3", 180.0, -24.0, 3)
	_build_biblio()
	_build_stairs("esc4", 240.0, -36.0, 4)
	_build_trone()
	_fill_lights()
	kit.commit()


func _build_hall() -> void:
	_in_room("hall")
	kit.room(_xf(), -6, 6, 0, 12, 0, 6, "donjon71", "dallesd71", [["s", 0, 3.4, 4.4]], "donjon71_sombre", T)
	# l'escalier qui descend de la tour en ruine (il remonte dans le mur du nord)
	kit.ramp(_xf(), Vector3(0, 0, 2.6), Vector3(0, 3.2, -0.2), 3.0, "dallesd71_vieux", "fer71")
	kit.solid(X(Vector3(0, 1.6, -0.6)), Vector3(3.6, 3.2, 0.8), "donjon71_sombre")
	kit.quadz(X(Vector3(0, 4.4, 0.02)), 3.0, 2.2, "noir69")
	# le règlement d'Odon, le cristal de retour, le cristal de descente (violet)
	_plaque("hall", Vector3(-5.93, 2.4, 6.0), PI * 0.5, 3.0, 2.0, "RÈGLEMENT DU DONJON\nDES MILLE MARCHES\n\n1. Ne pas nourrir les slimes (ils grossissent).\n2. Ne pas caresser les grenouilles (elles avalent).\n3. Un coffre qui sourit n'est pas un coffre.\n4. Les cristaux bleus remontent ici. Les chutes, non.\n\n— Odon, gardien et compteur de marches", 26)
	_plaque("hall", Vector3(0, 4.9, 11.91), PI, 4.2, 0.7, "ÉTAGE 1 — LES CAVES GLUANTES", 44)
	_crystal("hall", CRYSTALS[1], Color(0.4, 0.75, 1.0))
	_crystal("hall", Vector3(-4.2, 0, 9.0), Color(0.75, 0.45, 1.0))
	for z in [3.0, 10.0]:
		_torch("hall", Vector3(-5.85, 2.6, z), Vector3(1, 0, 0))
		_torch("hall", Vector3(5.85, 2.6, z), Vector3(-1, 0, 0))
	# des cordes, des sacs, une pelle oubliée (les aventuriers redescendent toujours chargés)
	kit.crate(W(Vector3(4.6, 0, 2.2)), 0.3, 0.7, true)
	kit.barrel(W(Vector3(4.9, 0, 3.4)), true)
	kit.cyl(Transform3D(Basis(Vector3.BACK, 0.1), W(Vector3(-4.8, 0, 2.0))), 0.35, 0.3, 0.3, "cuir71", 12)


func _gen_maze() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7101
	_maze_e.clear()
	_maze_s.clear()
	var seen: Array = []
	for c in range(MZ_N):
		_maze_e.append([false, false, false, false, false, false])
		_maze_s.append([false, false, false, false, false, false])
		seen.append([false, false, false, false, false, false])
	var stack: Array = [Vector2i(3, 0)]
	seen[3][0] = true
	while not stack.is_empty():
		var cur: Vector2i = stack.back()
		var nb: Array = []
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = cur + d
			if q.x >= 0 and q.y >= 0 and q.x < MZ_N and q.y < MZ_N and not bool(seen[q.x][q.y]):
				nb.append(q)
		if nb.is_empty():
			stack.pop_back()
			continue
		var nx: Vector2i = nb[rng.randi() % nb.size()]
		if nx.x > cur.x:
			_maze_e[cur.x][cur.y] = true
		elif nx.x < cur.x:
			_maze_e[nx.x][nx.y] = true
		elif nx.y > cur.y:
			_maze_s[cur.x][cur.y] = true
		else:
			_maze_s[nx.x][nx.y] = true
		seen[nx.x][nx.y] = true
		stack.append(nx)


func _maze_links(c: int, r: int) -> Array:
	var out: Array = []
	if c < MZ_N - 1 and bool(_maze_e[c][r]):
		out.append(Vector2i(c + 1, r))
	if c > 0 and bool(_maze_e[c - 1][r]):
		out.append(Vector2i(c - 1, r))
	if r < MZ_N - 1 and bool(_maze_s[c][r]):
		out.append(Vector2i(c, r + 1))
	if r > 0 and bool(_maze_s[c][r - 1]):
		out.append(Vector2i(c, r - 1))
	return out


func _cell(c: int, r: int, y: float = 0.0) -> Vector3:
	return Vector3(MZ_X0 + MZ_C * (c + 0.5), y, MZ_Z0 + MZ_C * (r + 0.5))


func _build_caves() -> void:
	_in_room("caves")
	kit.room(_xf(), -21, 15, 12, 48, 0, 5, "donjon71_mousse", "dallesd71_mousse", [["n", 0, 3.4, 4.4], ["s", 12, 3.4, 4.4]], "donjon71_sombre", T)
	_gen_maze()
	var hw: float = 0.3
	# les murs nord-sud (lignes x), regroupés en longueurs continues
	for i in range(1, MZ_N):
		var x: float = MZ_X0 + MZ_C * i
		var r: int = 0
		while r < MZ_N:
			if bool(_maze_e[i - 1][r]):
				r += 1
				continue
			var r0: int = r
			while r < MZ_N and not bool(_maze_e[i - 1][r]):
				r += 1
			_block(Vector3(x - hw, 0, MZ_Z0 + MZ_C * r0 - 0.29), Vector3(x + hw, 5.0, MZ_Z0 + MZ_C * r + 0.29), "donjon71_mousse")
	# les murs est-ouest (lignes z)
	for j in range(1, MZ_N):
		var z: float = MZ_Z0 + MZ_C * j
		var c: int = 0
		while c < MZ_N:
			if bool(_maze_s[c][j - 1]):
				c += 1
				continue
			var c0: int = c
			while c < MZ_N and not bool(_maze_s[c][j - 1]):
				c += 1
			_block(Vector3(MZ_X0 + MZ_C * c0, 0, z - hw), Vector3(MZ_X0 + MZ_C * c, 5.0, z + hw), "donjon71_mousse")
	# le coffre : au bout du cul-de-sac le plus loin de l'entrée
	var dist: Dictionary = {Vector2i(3, 0): 0}
	var q: Array = [Vector2i(3, 0)]
	while not q.is_empty():
		var cur: Vector2i = q.pop_front()
		for nb in _maze_links(cur.x, cur.y):
			if not dist.has(nb):
				dist[nb] = int(dist[cur]) + 1
				q.append(nb)
	var best := Vector2i(0, 5)
	var best_d: int = -1
	for cell in dist:
		var cc: Vector2i = cell
		if cc == Vector2i(5, 5) or cc == Vector2i(3, 0):
			continue
		if _maze_links(cc.x, cc.y).size() == 1 and int(dist[cc]) > best_d:
			best_d = int(dist[cc])
			best = cc
	var open_to: Vector2i = _maze_links(best.x, best.y)[0]
	var dir := Vector3(open_to.x - best.x, 0, open_to.y - best.y)
	var cpos: Vector3 = _cell(best.x, best.y) - dir * 1.6
	chest("caves", "caves", cpos, atan2(dir.x, dir.z), [["potion_seve", 1], ["piece", 25]],
		"Au fond du cul-de-sac, un coffre tout collant. Dedans : une fiole de sève, des pièces… et une étiquette : « Propriété des slimes. Ne pas toucher. » Trop tard.")
	# des champignons qui luisent, des flaques de gelée, des torches sur les murs du tour
	var spots := [[0, 1], [2, 2], [4, 1], [1, 4], [3, 3], [5, 2], [2, 5], [4, 4]]
	for k in range(spots.size()):
		var sp: Array = spots[k]
		var p: Vector3 = _cell(int(sp[0]), int(sp[1])) + Vector3(1.8 * (1 if k % 2 == 0 else -1), 0, 1.8 * (1 if k % 3 == 0 else -1))
		_mushrooms("caves", p, 7, 7110 + k, k % 2 == 0)
		kit.disc(X(_cell(int(sp[1]), int(sp[0])) + Vector3(0.8, 0.015, -0.6)), 0.6 + 0.15 * (k % 3), "gelee71", 16, 1.0)
	for x in [-18.0, -6.0, 6.0]:
		_torch("caves", Vector3(x, 2.4, 12.15), Vector3(0, 0, 1), 1.2)
		_torch("caves", Vector3(x, 2.4, 47.85), Vector3(0, 0, -1), 1.2)
	for z in [21.0, 39.0]:
		_torch("caves", Vector3(-20.85, 2.4, z), Vector3(1, 0, 0), 1.2)
		_torch("caves", Vector3(14.85, 2.4, z), Vector3(-1, 0, 0), 1.2)
	# des gouttes de gelée qui pendent du plafond
	for k2 in range(14):
		var a: float = float(k2) * 2.39996
		var px: float = -3.0 + cos(a) * (4.0 + k2 * 1.1)
		var pz: float = 30.0 + sin(a) * (3.0 + k2 * 0.9)
		var ln: float = 0.3 + float(k2 % 4) * 0.15
		kit.cyl(X(Vector3(clampf(px, -20.0, 14.0), 5.0 - ln, clampf(pz, 13.0, 47.0))), 0.0, 0.07, ln, "gelee71", 8, false, 1.0)


func _build_pieges() -> void:
	_in_room("pieges")
	kit.room(_xf(), -12, 36, 74, 106, -12, 7, "donjon71", "dallesd71", [["n", 12, 3.4, 4.4], ["s", 12, 3.4, 4.4], ["w", 90, 3.4, 4.4]], "donjon71_sombre", T)
	gate("pieges", "pieges", Vector3(12, -12, 106.6), 3.4, 4.4, 0.6, 0.0, "donjon71_sombre", "fer71")
	_plaque("pieges", Vector3(12, -6.4, 74.09), 0.0, 4.6, 0.7, "ÉTAGE 2 — LA SALLE DES PIÈGES", 44)
	_crystal("pieges", CRYSTALS[2], Color(0.4, 0.75, 1.0))
	# le champ de dalles : les dalles sûres (dessinées en lot), les piégées (une par une : elles s'enfoncent)
	var safe: Dictionary = {}
	for s in SAFE:
		safe["%d,%d" % [int(s[0]), int(s[1])]] = true
	var hole_z: Array = []
	_trap_tiles.clear()
	for c in range(TR_NX):
		for r in range(TR_NZ):
			var k: String = "%d,%d" % [c, r]
			var p := Vector3(TR_X0 + 2.0 * c + 1.0, -12.0 + 0.02, TR_Z0 + 2.0 * r + 1.0)
			var trapped: bool = not safe.has(k) and ((c * 7 + r * 13 + c * r) % 9) < 5
			if trapped:
				var mi := MeshInstance3D.new()
				mi.mesh = _boxm(Vector3(1.9, 0.04, 1.9))
				mi.material_override = _m("dallesd71_sombre")
				_root("pieges").add_child(mi)
				mi.global_position = W(p)
				_trap_tiles[k] = mi
				if not hole_z.has(r):
					hole_z.append(r)
			else:
				kit.box(X(p), Vector3(1.9, 0.04, 1.9), "dallesd71_clair", 3.0)
	# les trous des fléchettes, dans le mur de l'est
	for r2 in hole_z:
		for hy in [0.6, 1.2]:
			kit.box(X(Vector3(35.98, -12.0 + hy, TR_Z0 + 2.0 * int(r2) + 1.0)), Vector3(0.04, 0.07, 0.07), "noir69", 1.0)
	_plaque("pieges", Vector3(16.4, -10.4, 74.09), 0.0, 2.2, 1.1, "ATTENTION :\nles dalles fêlées ne sont pas fêlées.\nCe sont des pièges.\n— un aventurier qui a appris", 24)
	# le camp des gobelins (à l'ouest) : un feu, des peaux, un tas d'os de poulet
	kit.brazier63(_root("pieges"), W(Vector3(-2.0, -12, 90.0)), true, "fer71", 2.0, "donjon71_vieux")
	for k3 in range(4):
		var a: float = TAU * k3 / 4.0 + 0.4
		kit.box(Transform3D(Basis(Vector3.UP, a), W(Vector3(-2.0 + cos(a) * 2.6, -11.97, 90.0 + sin(a) * 2.6))), Vector3(1.4, 0.06, 1.0), "cuir71", 1.0)
	for bz in [Vector3(14.0, -12, 77.0), Vector3(34.0, -12, 77.0), Vector3(-10.0, -12, 77.5)]:
		kit.brazier63(_root("pieges"), W(bz), true, "fer71", 2.4, "donjon71_vieux")
	for gz in [86.0, 98.0]:
		kit.glow_light(_root("pieges"), W(Vector3(26.0, -12 + 5.5, gz)), Color(1.0, 0.75, 0.5), 1.1, 16.0)
	kit.rocks(_root("pieges"), [W(Vector3(2.0, -12, 75.4)), W(Vector3(-11.0, -12, 82.0)), W(Vector3(6.0, -12, 104.4))], 7121, "roche71", 0.5, 1.1)
	# les trois lampes au-dessus de la porte (une par levier)
	_lamps.clear()
	for i in range(3):
		var lm := StandardMaterial3D.new()
		lm.albedo_color = Color(0.25, 0.2, 0.16)
		lm.emission_enabled = true
		lm.emission = Color(1.0, 0.6, 0.25)
		lm.emission_energy_multiplier = 0.0
		lm.roughness = 0.3
		var bulb := MeshInstance3D.new()
		bulb.mesh = _sphere(0.18)
		bulb.material_override = lm
		_root("pieges").add_child(bulb)
		bulb.global_position = W(Vector3(10.6 + 1.4 * i, -12 + 5.3, 105.7))
		kit.box(X(Vector3(10.6 + 1.4 * i, -12 + 5.0, 105.85)), Vector3(0.3, 0.12, 0.3), "fer71", 1.0)
		var ll := OmniLight3D.new()
		ll.light_color = Color(1.0, 0.6, 0.25)
		ll.light_energy = 0.0
		ll.omni_range = 5.0
		_root("pieges").add_child(ll)
		ll.global_position = W(Vector3(10.6 + 1.4 * i, -12 + 5.3, 105.2))
		_lamps.append([lm, ll])
	_levers.clear()
	for i2 in range(3):
		_lever(i2, "pieges" if i2 > 0 else "couloir")
	for z in [80.0, 100.0]:
		_torch("pieges", Vector3(-11.85, -12 + 2.6, z), Vector3(1, 0, 0), 1.3)
		_torch("pieges", Vector3(35.85, -12 + 2.6, z - 4.0), Vector3(-1, 0, 0), 1.3)
	for x in [0.0, 24.0]:
		_torch("pieges", Vector3(x, -12 + 2.6, 74.15), Vector3(0, 0, 1), 1.3)
		_torch("pieges", Vector3(x, -12 + 2.6, 105.85), Vector3(0, 0, -1), 1.3)


## Un levier : une plaque au mur, une poignée qui pivote (relevée : -0.7 ; tirée : +0.7).
func _lever(i: int, n: String) -> void:
	_in_room(n)
	var l: Vector3 = LEVERS[i][0]
	var d: Vector3 = LEVERS[i][1]
	var yaw: float = atan2(d.x, d.z)
	var bs := Basis(Vector3.UP, yaw)
	kit.box(Transform3D(bs, W(l + Vector3(0, 1.2, 0))), Vector3(0.6, 0.9, 0.12), "fer71", 1.0)
	kit.box(Transform3D(bs, W(l + Vector3(0, 1.2, 0) + bs * Vector3(0, 0, 0.08))), Vector3(0.3, 0.3, 0.1), "laiton71", 1.0)
	var piv := Node3D.new()
	piv.name = "Levier_%d" % i
	_root(n).add_child(piv)
	piv.global_transform = Transform3D(bs, W(l + Vector3(0, 1.2, 0) + bs * Vector3(0, 0, 0.15)))
	var arm := Node3D.new()
	piv.add_child(arm)
	_mesh(arm, _cylm(0.035, 0.035, 0.7, 8), "fer71", Vector3(0, 0.35, 0))
	_mesh(arm, _sphere(0.08), "cuivre71m", Vector3(0, 0.72, 0))
	arm.rotation.x = -0.7
	_levers.append(arm)
	_in_room("pieges")


func _build_couloir() -> void:
	_in_room("couloir")
	kit.room(_xf(), -42, -12, 86, 95, -12, 5.5, "donjon71_vieux", "dallesd71_sombre", [["e", 90, 3.4, 4.4]], "donjon71_sombre", T)
	# les niches (au sud) : on remplit le mur entre elles
	var xs: Array = [-42.0]
	for nx in NICHES:
		xs.append(float(nx) - 1.2)
		xs.append(float(nx) + 1.2)
	xs.append(-12.0 - T)
	for k in range(0, xs.size(), 2):
		_block(Vector3(float(xs[k]), -12, 92.0), Vector3(float(xs[k + 1]), -6.5, 95.0), "donjon71_vieux")
	for nx2 in NICHES:
		_torch("couloir", Vector3(float(nx2), -12 + 2.0, 94.85), Vector3(0, 0, -1), 0.9)
	# l'ornière du rocher, le trou du plafond d'où il tombe
	kit.box(X(Vector3(-27.0, -11.99, BALL_Z)), Vector3(30.0, 0.02, 1.4), "dallesd71_sombre", 2.0)
	kit.disc(Transform3D(Basis(Vector3.RIGHT, PI), W(Vector3(BALL_X0, -6.49, BALL_Z))), 2.8, "noir69", 20)
	_plaque("couloir", Vector3(-14.8, -12 + 3.2, 91.91), PI, 2.0, 0.9, "LE COULOIR DU ROCHER\nPrière de courir.\n(Les niches sont gratuites.)", 26)
	for x in [-38.0, -30.0, -22.0, -15.0]:
		_torch("couloir", Vector3(x, -12 + 2.6, 86.15), Vector3(0, 0, 1), 1.2)
	_ball = Node3D.new()
	_ball.name = "Rocher"
	_root("couloir").add_child(_ball)
	var Rk = preload("res://scripts/rocks_v26.gd")
	var bm := MeshInstance3D.new()
	bm.mesh = Rk.shape(7130, Vector3(BALL_R * 2.0, BALL_R * 2.0, BALL_R * 2.0), 0.9, 0.08)
	bm.material_override = _m("roche71")
	_ball.add_child(bm)
	_ball.visible = false
	_ball.global_position = W(Vector3(BALL_X0, -6.0 + BALL_R, BALL_Z))


func _build_lac() -> void:
	_in_room("lac")
	kit.room(_xf(), -20, 44, 132, 180, -24, 12, "donjon71_mousse", "", [["n", 12, 3.4, 4.4], ["s", 12, 3.4, 4.4]], "donjon71_sombre", T)
	gate("lac", "lac", Vector3(12, -24, 180.6), 3.4, 4.4, 0.6, 0.0, "cuivre71m", "laiton71")
	# les rives, le fond, l'eau
	kit.solid(X(Vector3(12, -25.65, 137.0 - T * 0.25)), Vector3(64.0 + 2 * T, 3.3, 10.0 + T * 0.5), "dallesd71_mousse", 3.0)
	kit.solid(X(Vector3(12, -25.65, 175.0 + T * 0.25)), Vector3(64.0 + 2 * T, 3.3, 10.0 + T * 0.5), "dallesd71_mousse", 3.0)
	kit.solid(X(Vector3(12, -27.3, 156.0)), Vector3(64.0 + 2 * T, 0.6, 28.0), "roche71", 3.0)
	_block(Vector3(-20.0 - T, -27.3, 142.0), Vector3(-20.0, -24.0, 170.0), "roche71")
	_block(Vector3(44.0, -27.3, 142.0), Vector3(44.0 + T, -24.0, 170.0), "roche71")
	var w := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(64.0, 28.0)
	w.mesh = pm
	w.material_override = _m("eau71")
	w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_root("lac").add_child(w)
	w.global_position = W(Vector3(12, -24.45, 156.0))
	for x in [-8.0, 12.0, 32.0]:
		kit.glow_light(_root("lac"), W(Vector3(x, -25.0, 156.0)), Color(0.3, 0.55, 0.8), 0.7, 14.0)
	# les pierres plates, les deux îlots
	for s in STONES:
		var p := Vector3(float(s[0]), -27.0, float(s[1]))
		var r: float = float(s[2])
		kit.cyl(X(p), r * 1.12, r, 3.06, "roche71_sombre", 12, true, 1.5)
		kit.disc(X(p + Vector3(0, 3.07, 0)), r * 0.8, "moussed71", 12, 1.0)
		kit.col_cyl(W(p), r, 3.06)
	for isl in ISLES:
		var p2 := Vector3(float(isl[0]), -27.0, float(isl[1]))
		var r2: float = float(isl[2])
		kit.cyl(X(p2), r2 * 1.15, r2, 3.1, "roche71_sombre", 20, true, 2.0)
		kit.disc(X(p2 + Vector3(0, 3.11, 0)), r2 * 0.88, "moussed71", 20, 2.0)
		kit.col_cyl(W(p2), r2, 3.1)
		_mushrooms("lac", p2 + Vector3(r2 * 0.5, 3.1, -r2 * 0.4), 9, 7140 + int(r2 * 10), true)
	# des stalactites, des champignons qui luisent sur les rives, des rochers
	for k in range(30):
		var a: float = float(k) * 2.39996
		var rr: float = 4.0 + float(k % 9) * 3.2
		var px: float = clampf(12.0 + cos(a) * rr * 1.6, -18.0, 42.0)
		var pz: float = clampf(156.0 + sin(a) * rr, 134.0, 178.0)
		var ln: float = 1.0 + float(k % 5) * 0.7
		kit.cyl(X(Vector3(px, -12.0 - ln, pz)), 0.0, 0.25 + float(k % 3) * 0.12, ln, "donjon71_sombre", 7, false, 1.5)
	for mp in [Vector3(-16, -24, 135), Vector3(36, -24, 134), Vector3(41, -24, 140), Vector3(-17, -24, 176), Vector3(28, -24, 178), Vector3(2, -24, 172)]:
		_mushrooms("lac", mp, 10, int(mp.x * 3 + mp.z), true)
	kit.rocks(_root("lac"), [W(Vector3(-14, -24, 139)), W(Vector3(40, -24, 175)), W(Vector3(-6, -24, 177)), W(Vector3(24, -24, 133.5))], 7150, "roche71", 0.6, 1.5)
	_plaque("lac", Vector3(12, -24 + 5.0, 132.09), 0.0, 4.2, 0.7, "ÉTAGE 3 — LE LAC SOUTERRAIN", 44)
	_plaque("lac", Vector3(15.6, -24 + 1.5, 179.91), PI, 1.6, 0.8, "Porte de cuivre.\nLa clé ? Demandez\naux grenouilles.", 24)
	_crystal("lac", CRYSTALS[3], Color(0.4, 0.75, 1.0))
	for x2 in [-12.0, 36.0]:
		_torch("lac", Vector3(x2, -24 + 2.6, 132.15), Vector3(0, 0, 1), 1.2)
		_torch("lac", Vector3(x2, -24 + 2.6, 179.85), Vector3(0, 0, -1), 1.2)


## Une étagère de livres contre un mur (front : le bas-milieu de sa face, inward : vers la salle).
func _shelf(front: Vector3, inward: Vector3, w: float = 3.6, h: float = 4.0) -> void:
	var yaw: float = atan2(-inward.x, -inward.z)
	kit.bookshelf(Transform3D(Basis(Vector3.UP, yaw), W(front + inward * 0.45)), w, h, 0.45)


## Une statuette (le repère des estrades de la Bibliothèque), au-dessus du sol en l.
func _statuette(n: String, kind: String, l: Vector3) -> void:
	var node := Node3D.new()
	node.name = "Statuette_" + kind
	_root(n).add_child(node)
	node.global_position = W(l)
	match kind:
		"hibou":
			_mesh(node, _sphere(0.2, 0.46), "plume71m", Vector3(0, 0.23, 0))
			_mesh(node, _sphere(0.15, 0.28), "plume71m", Vector3(0, 0.52, 0))
			for s in [-1.0, 1.0]:
				_mesh(node, _sphere(0.055), "oeil71m", Vector3(s * 0.065, 0.55, 0.12))
				_mesh(node, _cylm(0.03, 0.0, 0.12, 6), "plume71m", Vector3(s * 0.09, 0.68, 0), Vector3(0, 0, -s * 0.3))
			_mesh(node, _cylm(0.025, 0.0, 0.07, 6), "or71", Vector3(0, 0.5, 0.15), Vector3(PI * 0.5, 0, 0))
		"crane":
			_mesh(node, _sphere(0.22, 0.4), "os71m", Vector3(0, 0.26, 0))
			_mesh(node, _boxm(Vector3(0.22, 0.12, 0.2)), "os71m", Vector3(0, 0.08, 0.06))
			for s in [-1.0, 1.0]:
				_mesh(node, _sphere(0.055), "noir69", Vector3(s * 0.08, 0.28, 0.17))
		"chandelle":
			_mesh(node, _cylm(0.16, 0.16, 0.05, 12), "laiton71", Vector3(0, 0.025, 0))
			_mesh(node, _cylm(0.06, 0.055, 0.5, 10), "cire71m", Vector3(0, 0.3, 0))
			var f: CPUParticles3D = kit.fire(node, Vector3(0, 0.6, 0), 0.03, 10)
			f.position = Vector3(0, 0.6, 0)
			var cl := OmniLight3D.new()
			cl.light_color = Color(1.0, 0.7, 0.35)
			cl.light_energy = 0.8
			cl.omni_range = 3.5
			cl.position = Vector3(0, 0.75, 0)
			node.add_child(cl)
		"sablier":
			for y in [0.02, 0.62]:
				_mesh(node, _boxm(Vector3(0.34, 0.04, 0.34)), "planches71_sombre", Vector3(0, y, 0))
			_mesh(node, _cylm(0.14, 0.02, 0.3, 12), "cristal71", Vector3(0, 0.18, 0))
			_mesh(node, _cylm(0.02, 0.14, 0.3, 12), "cristal71", Vector3(0, 0.46, 0))
			for s2 in [Vector2(-0.14, -0.14), Vector2(0.14, -0.14), Vector2(-0.14, 0.14), Vector2(0.14, 0.14)]:
				_mesh(node, _cylm(0.015, 0.015, 0.6, 6), "planches71_sombre", Vector3(s2.x, 0.32, s2.y))
		"couronne":
			_mesh(node, _cylm(0.17, 0.17, 0.12, 16), "or71", Vector3(0, 0.08, 0))
			for k in range(6):
				var a: float = TAU * k / 6.0
				_mesh(node, _cylm(0.035, 0.0, 0.14, 6), "or71", Vector3(cos(a) * 0.15, 0.2, sin(a) * 0.15))
		"livres":
			var cols := ["tissu71_rouge", "tissu71_bleu", "tissu71_vert", "tissu71_brun"]
			for k2 in range(4):
				_mesh(node, _boxm(Vector3(0.4 - k2 * 0.04, 0.08, 0.28)), str(cols[k2]), Vector3(0, 0.04 + k2 * 0.085, 0), Vector3(0, k2 * 0.3, 0))


func _build_biblio() -> void:
	_in_room("biblio")
	kit.room(_xf(), -16, 40, 206, 240, -36, 9, "donjon71_chaud", "dallesd71_chaud", [["n", 12, 3.4, 4.4], ["s", 12, 3.4, 4.4]], "donjon71_sombre", T)
	gate("biblio", "biblio", Vector3(12, -36, 240.6), 3.4, 4.4, 0.6, 0.0, "argent71m", "or71")
	_plaque("biblio", Vector3(12, -36 + 5.4, 206.09), 0.0, 5.6, 0.7, "ÉTAGE 4 — LA BIBLIOTHÈQUE DES MIMIQUES", 44)
	_crystal("biblio", CRYSTALS[4], Color(0.4, 0.75, 1.0))
	# les étagères contre les murs (sauf devant les portes)
	for x in [-13.5, -9.5, -5.5, -1.5, 25.5, 29.5, 33.5, 37.5]:
		_shelf(Vector3(x, -36, 206.0), Vector3(0, 0, 1))
		_shelf(Vector3(x, -36, 240.0), Vector3(0, 0, -1))
	for z in [210.5, 214.5, 219.0, 227.0, 231.5, 235.5]:
		_shelf(Vector3(-16.0, -36, z), Vector3(1, 0, 0))
		_shelf(Vector3(40.0, -36, z), Vector3(-1, 0, 0))
	# les six estrades, leurs statuettes ; les vrais coffres (le bon et les deux leurres)
	for i in range(DAIS.size()):
		var dd: Array = DAIS[i]
		var p := Vector3(float(dd[0]), -36, float(dd[1]))
		var inward := Vector3(signf(12.0 - p.x), 0, 0)
		kit.solid(X(p + Vector3(0, 0.15, 0)), Vector3(2.4, 0.3, 2.4), "donjon71_clair", 1.0)
		kit.solid(X(p - inward * 0.8 + Vector3(0, 0.6, 0)), Vector3(0.5, 0.6, 0.5), "donjon71_vieux", 1.0)
		_statuette("biblio", str(dd[2]), p - inward * 0.8 + Vector3(0, 0.9, 0))
		var yaw: float = atan2(inward.x, inward.z)
		var cpos: Vector3 = p + inward * 0.2 + Vector3(0, 0.3, 0)
		match str(dd[3]):
			"vrai":
				chest("vrai", "biblio", cpos, yaw, [["cle_argent", 1], ["piece", 40]],
					"Le coffre du hibou ne mord pas : il grince, c'est tout. Dedans, sur un coussin de velours, une clé d'argent ciselée de petits hiboux.")
			"leurre":
				if str(dd[2]) == "chandelle":
					chest("chandelle", "biblio", cpos, yaw, [["vieille_botte", 1]],
						"Le coffre de la chandelle s'ouvre… sur une vieille botte, et un mot : « Raté ! Mais au moins, celui-ci ne mord pas. »")
				else:
					chest("livres", "biblio", cpos, yaw, [["piece", 15], ["potion_seve", 1]],
						"Le coffre des livres est honnête, et pauvre : quelques pièces, une fiole de sève, et un marque-page.")
	# le lutrin et le Grand Livre des Coffres
	kit.solid(X(Vector3(12, -36 + 0.55, 211.0)), Vector3(0.7, 1.1, 0.5), "planches71_sombre", 1.0)
	kit.box(Transform3D(Basis(Vector3.RIGHT, 0.35), W(Vector3(12, -36 + 1.2, 211.0))), Vector3(0.9, 0.05, 0.62), "planches71_sombre", 1.0)
	for s in [-1.0, 1.0]:
		kit.box(Transform3D(Basis(Vector3.RIGHT, 0.35) * Basis(Vector3.BACK, s * 0.08), W(Vector3(12 + s * 0.2, -36 + 1.25, 211.0))), Vector3(0.38, 0.03, 0.52), "parchemin71m", 1.0)
	var lb := Label3D.new()
	lb.text = "LE GRAND LIVRE\nDES COFFRES"
	lb.font_size = 40
	lb.pixel_size = 0.004
	lb.outline_size = 8
	lb.modulate = Color(1.0, 0.85, 0.5)
	lb.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_root("biblio").add_child(lb)
	lb.global_position = W(Vector3(12, -36 + 2.0, 211.0))
	# des lustres (des cercles de chandelles), des piles de livres par terre
	for c in [Vector3(2, -36, 216), Vector3(22, -36, 216), Vector3(2, -36, 231), Vector3(22, -36, 231)]:
		kit.cyl(X(c + Vector3(0, 6.6, 0)), 0.02, 0.02, 2.4, "fer71", 6, false)
		kit.ring(X(c + Vector3(0, 6.5, 0)), 0.9, 1.0, 0.08, "fer71", 20)
		for k in range(6):
			var a: float = TAU * k / 6.0
			kit.cyl(X(c + Vector3(cos(a) * 0.95, 6.58, sin(a) * 0.95)), 0.03, 0.03, 0.18, "cire71m", 6)
		var cl := OmniLight3D.new()
		cl.light_color = Color(1.0, 0.72, 0.4)
		cl.light_energy = 1.6
		cl.omni_range = 11.0
		cl.shadow_enabled = pc
		_root("biblio").add_child(cl)
		cl.global_position = W(c + Vector3(0, 6.2, 0))
	for bp in [Vector3(-12, -36, 223), Vector3(36, -36, 222), Vector3(16, -36, 236), Vector3(6, -36, 236.5)]:
		_statuette("biblio", "livres", bp)
	for z2 in [223.0]:
		_torch("biblio", Vector3(-15.85, -36 + 2.8, z2), Vector3(1, 0, 0), 1.2)
		_torch("biblio", Vector3(39.85, -36 + 2.8, z2), Vector3(-1, 0, 0), 1.2)


func _build_trone() -> void:
	_in_room("trone")
	kit.room(_xf(), -12, 36, 266, 310, -48, 14, "donjon71_mousse", "dallesd71", [["n", 12, 3.4, 4.4]], "donjon71_sombre", T)
	_plaque("trone", Vector3(12, -48 + 5.2, 266.09), 0.0, 5.6, 0.7, "ÉTAGE 5 — LA SALLE DU TRÔNE GÉLATINEUX", 44)
	_crystal("trone", CRYSTALS[5], Color(0.4, 0.75, 1.0))
	# l'estrade et le trône de gelée (dorures, une cuillère royale géante appuyée contre)
	kit.solid(X(Vector3(12, -48 + 0.6, 305.0)), Vector3(14.0, 1.2, 8.0), "donjon71", 2.0)
	kit.ramp(_xf(), Vector3(12, -48, 299.6), Vector3(12, -46.8, 301.0), 6.0, "dallesd71")
	kit.solid(X(Vector3(12, -46.8 + 1.0, 306.5)), Vector3(5.0, 2.0, 3.0), "gelee71", 2.5)
	kit.solid(X(Vector3(12, -46.8 + 4.0, 308.4)), Vector3(5.6, 8.0, 1.2), "gelee71", 2.5)
	kit.box(X(Vector3(12, -46.8 + 8.1, 308.4)), Vector3(5.9, 0.3, 1.4), "or71", 1.0)
	for s in [-1.0, 1.0]:
		kit.box(X(Vector3(12 + s * 2.75, -46.8 + 4.0, 308.4)), Vector3(0.3, 8.2, 1.4), "or71", 1.0)
		kit.solid(X(Vector3(12 + s * 2.9, -46.8 + 1.6, 306.2)), Vector3(0.8, 1.2, 2.6), "gelee71", 2.5)
	kit.cyl(Transform3D(Basis(Vector3.BACK, 0.35), W(Vector3(17.6, -46.8, 304.6))), 0.12, 0.1, 6.0, "or71", 10)
	kit.cyl(Transform3D(Basis(Vector3.BACK, 0.35) * Basis(Vector3.RIGHT, PI * 0.5), W(Vector3(15.5, -46.8 + 5.8, 304.6))), 0.9, 0.9, 0.25, "or71", 18)
	# des piliers enrobés de gelée, des flaques, des gouttes au plafond
	for p in [Vector3(-4, -48, 276), Vector3(28, -48, 276), Vector3(-4, -48, 296), Vector3(28, -48, 296)]:
		kit.column(X(p), 0.8, 14.0, "donjon71_mousse", "donjon71")
		kit.cyl(X(p + Vector3(0, 0.3, 0)), 1.2, 0.95, 3.4, "gelee71", 16, false, 2.5)
	for k in range(12):
		var a: float = float(k) * 2.39996
		var rr: float = 4.0 + float(k % 6) * 3.0
		kit.disc(X(Vector3(12.0 + cos(a) * rr * 1.3, -47.985, 288.0 + sin(a) * rr)), 0.5 + float(k % 4) * 0.35, "gelee71", 16, 1.0)
	for k2 in range(24):
		var a2: float = float(k2) * 2.39996
		var r2: float = 3.0 + float(k2 % 8) * 2.6
		var ln: float = 0.5 + float(k2 % 4) * 0.4
		kit.cyl(X(Vector3(clampf(12.0 + cos(a2) * r2 * 1.4, -11.0, 35.0), -34.0 - ln, clampf(288.0 + sin(a2) * r2, 267.0, 309.0))), 0.0, 0.12, ln, "gelee71", 8, false, 1.0)
	for b in [Vector3(4, -48, 302), Vector3(20, -48, 302), Vector3(-6, -48, 286), Vector3(30, -48, 286)]:
		kit.brazier63(_root("trone"), W(b), true, "laiton71", 2.2, "donjon71_vieux")
	for z in [272.0, 288.0, 304.0]:
		_torch("trone", Vector3(-11.85, -48 + 3.0, z), Vector3(1, 0, 0), 1.4)
		_torch("trone", Vector3(35.85, -48 + 3.0, z), Vector3(-1, 0, 0), 1.4)
	kit.glow_light(_root("trone"), W(Vector3(12, -46.8 + 3.0, 304.0)), Color(0.5, 1.0, 0.4), 1.6, 10.0)
	# l'escalier de lumière (il apparaît quand le Roi est vaincu)
	_light_stairs = Node3D.new()
	_light_stairs.name = "Escalier_de_lumiere"
	_root("trone").add_child(_light_stairs)
	_light_stairs.global_position = W(Vector3(12, -48, 291.0))
	for k3 in range(16):
		var a3: float = k3 * 0.42
		var st := MeshInstance3D.new()
		st.mesh = _boxm(Vector3(1.8, 0.12, 0.8))
		st.material_override = _m("lumiere71m")
		st.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_light_stairs.add_child(st)
		st.position = Vector3(cos(a3) * 2.2, 0.3 + k3 * 0.78, sin(a3) * 2.2)
		st.rotation.y = -a3
	var beam := MeshInstance3D.new()
	beam.mesh = _cylm(0.9, 0.9, 14.0, 20)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(1.0, 0.85, 0.45, 0.06)
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam.material_override = bmat
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_light_stairs.add_child(beam)
	beam.position = Vector3(0, 7.0, 0)
	var sl := OmniLight3D.new()
	sl.light_color = Color(1.0, 0.88, 0.55)
	sl.light_energy = 2.4
	sl.omni_range = 16.0
	_light_stairs.add_child(sl)
	sl.position = Vector3(0, 4.0, 0)
	_light_stairs.visible = false


# =================================================================== dehors, le carnet

func register(journal: Node) -> void:
	journal.lieux["mille_marches"] = W(ARRIVE[1])


# =================================================================== invites du donjon

func _register() -> void:
	var me = self
	ia("sortir", Vector3(0, 0, 2.4), 1.6, "E : remonter l'escalier (vers la tour en ruine)", "Gâchette : remonter",
		func(): me.leave("Tu remontes les marches… L'air sent l'herbe et le vent. Odon lève le nez de son registre : « Déjà ? »"))
	_shortcut_ia = ia("raccourci", Vector3(-4.2, 0, 8.0), 1.6, "E : descendre directement (Odon l'a noté)", "Gâchette : descendre directement",
		func(): me._shortcut(), func(): return me.deepest() >= 2)
	ia("reglement", Vector3(-5.0, 0, 6.0), 1.4, "E : lire le règlement", "Gâchette : lire le règlement",
		func(): me._say("« Règlement du Donjon des Mille Marches. 1. Ne pas nourrir les slimes (ils grossissent). 2. Ne pas caresser les grenouilles (elles avalent). 3. Un coffre qui sourit n'est pas un coffre. 4. Les cristaux bleus remontent ici. Les chutes, non. » Signé : Odon, gardien et compteur de marches.", 10.0))
	for k in range(1, 6):
		var kk: int = k
		var c: Vector3 = CRYSTALS[k]
		ia("cristal_%d" % k, c + Vector3(0, 0, 1.0), 1.7, "E : toucher le cristal de retour (remonter à l'entrée)", "Gâchette : cristal de retour",
			func(): me._crystal_return(kk))
	for i in range(3):
		var ii: int = i
		var l: Vector3 = LEVERS[i][0]
		var d: Vector3 = LEVERS[i][1]
		ia("levier_%d" % i, l + d * 0.9, 1.5, "E : tirer le levier", "Gâchette : tirer le levier", func(): me._pull(ii),
			func(): return not bool((me.state["leviers"] as Array)[ii]))
	ia("porte_cuivre", Vector3(12, -24, 178.6), 2.0, "E : ouvrir la porte de cuivre", "Gâchette : la porte de cuivre", func(): me._copper_door(),
		func(): return not me.gate_open("lac"))
	ia("grand_livre", Vector3(12, -36, 212.0), 1.6, "E : lire le Grand Livre des Coffres", "Gâchette : lire le Grand Livre", func(): me._read_book())
	for i2 in range(DAIS.size()):
		if str(DAIS[i2][3]) != "mimique":
			continue
		var jj: int = i2
		var p := Vector3(float(DAIS[i2][0]), -36, float(DAIS[i2][1]))
		var inward := Vector3(signf(12.0 - p.x), 0, 0)
		ia("mimique_%d" % i2, p + inward * 1.6, 1.5, "E : ouvrir le coffre", "Gâchette : ouvrir le coffre", func(): me._open_mimic(jj),
			func(): return me._mimic_sleeping(jj))
	ia("porte_argent", Vector3(12, -36, 238.6), 2.0, "E : ouvrir la porte d'argent", "Gâchette : la porte d'argent", func(): me._silver_door(),
		func(): return not me.gate_open("biblio"))
	ia("escalier_lumiere", Vector3(12, -48, 293.6), 2.4, "E : monter l'escalier de lumière (vers la surface)", "Gâchette : l'escalier de lumière",
		func(): me.leave("Les marches de lumière tintent sous tes pieds, une à une… Mille marches, mais elles montent toutes seules. Et te voilà dans la tour en ruine, au grand jour, le Cœur de gelée royale dans ton sac."),
		func(): return bool(me.state["fini"]))


func _apply_state() -> void:
	super._apply_state()
	var lv: Array = state["leviers"]
	for i in range(_levers.size()):
		(_levers[i] as Node3D).rotation.x = 0.7 if bool(lv[i]) else -0.7
		_lamp(i, bool(lv[i]))
	if _light_stairs != null:
		_light_stairs.visible = bool(state["fini"])
	if _ball != null:
		_ball.visible = false
	_ball_on = false


## Un objet est-il connu du sac (les objets V71 sont ajoutés par inventory_v28) ?
func _known(id: String) -> bool:
	return (_inv().ITEMS as Dictionary).has(id)


## Le coffre ouvert : seulement les objets que le sac connaît ; le bon coffre de la Bibliothèque
## ouvre le chemin, même si la clé d'argent n'existe pas (encore) dans le sac.
func _open_chest(n: String, c: Node3D, contents: Array, text: String) -> void:
	var ok: Array = []
	for g in contents:
		if _known(str(g[0])):
			ok.append(g)
	if n == "vrai":
		state["vrai_coffre"] = true
	_sfx("coffre_pieces", c.global_position + Vector3.UP * 0.5)
	super._open_chest(n, c, ok, text)


# =================================================================== le hall, les cristaux

func _crystal_return(k: int) -> void:
	_sfx("cristal_retour", W(CRYSTALS[k] + Vector3(0, 1.5, 0)))
	if k == 1:
		leave("Le cristal bleu s'illumine, et le hall se dissout dans un tintement… Te revoilà au soleil, devant la tour en ruine. (Odon, sans lever les yeux : « Étage 1. C'est noté. »)")
		return
	leave("Le cristal bleu s'illumine : tout tourne, ça sent la menthe… et te revoilà au soleil, devant la tour en ruine. Odon trempe sa plume : « Étage %d. C'est noté. »" % deepest())


func _shortcut() -> void:
	var k: int = clampi(deepest(), 2, 5)
	_sfx("cristal_retour", W(Vector3(-4.2, 1.5, 9.0)))
	_say("Le cristal violet bourdonne. « Étage %d, %s », murmure la voix d'Odon, comme s'il était là. Ça descend vite… très vite…" % [k, FLOOR_NAMES[k]], 5.0)
	await main.donjon_v35._travel(W(ARRIVE[k]), Vector3(0, 0, 1))
	checkpoint = [W(ARRIVE[k]), Vector3(0, 0, 1)]


# =================================================================== la Salle des Pièges

func _lamp(i: int, on: bool) -> void:
	if i >= _lamps.size():
		return
	(_lamps[i][0] as StandardMaterial3D).emission_energy_multiplier = 3.0 if on else 0.0
	(_lamps[i][1] as OmniLight3D).light_energy = 1.2 if on else 0.0


func _pull(i: int) -> void:
	var lv: Array = state["leviers"]
	if bool(lv[i]):
		return
	lv[i] = true
	if i < _levers.size():
		create_tween().tween_property(_levers[i], "rotation:x", 0.7, 0.35).set_trans(Tween.TRANS_BACK)
	var l: Vector3 = LEVERS[i][0]
	_sfx("levier", W(l + Vector3(0, 1.2, 0)))
	_lamp(i, true)
	var n: int = 0
	for v in lv:
		if bool(v):
			n += 1
	if i == 0 and not bool(state["rocher"]):
		state["rocher"] = true
		_say("Clac ! Une lampe s'allume au-dessus de la porte… et, au-dessus de ta tête, quelque chose de très lourd fait « crrrr ». COURS ! (Les niches sont gratuites.)", 5.0)
		await get_tree().create_timer(1.0).timeout
		_start_ball()
	elif n < 3:
		_say(["Clac ! Une lampe s'allume au-dessus de la porte du sud. Encore %d levier(s)." % (3 - n), "Clonk ! Une deuxième lampe brille. Plus que %d levier." % (3 - n)][clampi(n - 1, 0, 1)], 5.0)
	if n == 3 and not gate_open("pieges"):
		await get_tree().create_timer(1.2).timeout
		open_gate("pieges", "Trois lampes, trois « clac » : la porte du sud s'enfonce dans le sol en grondant. L'escalier descend vers le Lac Souterrain.")


func _start_ball() -> void:
	if _ball == null:
		return
	_ball_on = true
	_ball_hit = false
	_ball_x = BALL_X0
	_ball_v = 0.0
	_ball_t = 0.0
	_ball_snd = 0.0
	_ball.visible = true
	_ball.global_position = W(Vector3(BALL_X0, -6.5 + BALL_R, BALL_Z))
	_sfx("rocher_roule", _ball.global_position)


func _tick_ball(delta: float, l: Vector3, r: String) -> void:
	if not _ball_on:
		return
	_ball_t += delta
	var y: float = -12.0 + BALL_R
	if _ball_t < 0.5:
		# il tombe du trou du plafond
		y = lerpf(-6.5 + BALL_R, -12.0 + BALL_R, smoothstep(0.0, 1.0, _ball_t / 0.5))
	else:
		_ball_v = minf(_ball_v + 3.2 * delta, 7.5)
		_ball_x += _ball_v * delta
		_ball.rotate_z(-_ball_v * delta / BALL_R)
		_ball_snd -= delta
		if _ball_snd <= 0.0:
			_ball_snd = 1.4
			_sfx("rocher_roule", _ball.global_position)
	_ball.global_position = W(Vector3(_ball_x, y, BALL_Z))
	if not _ball_hit and r == "couloir" and l.z < 92.2 and absf(l.x - _ball_x) < BALL_R + 0.35 and l.y < -9.0:
		_ball_hit = true
		_fall_back("BOUM ! Le rocher t'aplatit comme une crêpe (une crêpe très vexée). Tu te décolles du sol à l'entrée du couloir. La prochaine fois : une niche !", 1)
	if _ball_x >= BALL_X1:
		_ball_on = false
		_ball.visible = false
		var at: Vector3 = W(Vector3(BALL_X1, -12.0 + 1.0, BALL_Z))
		_sfx("onde_choc", at)
		if main.combat_v28 != null:
			for k in range(6):
				main.combat_v28.puff(at + Vector3(randf_range(-1.5, 1.5), randf_range(0.0, 2.0), randf_range(-1.5, 1.5)), Color(0.55, 0.5, 0.44))
		if r in ["couloir", "pieges"]:
			_say("CRAAAC ! Le rocher se fracasse contre le seuil de pierre, en mille cailloux. (Mille marches, mille cailloux : c'est la maison.)", 5.0)


func _tick_traps(delta: float, l: Vector3) -> void:
	for k in _trap_cd.keys():
		_trap_cd[k] = float(_trap_cd[k]) - delta
		if float(_trap_cd[k]) <= -2.0:
			_trap_cd.erase(k)
	if l.y > -11.0 or l.x < TR_X0 or l.z < TR_Z0:
		return
	var c: int = int((l.x - TR_X0) / 2.0)
	var r: int = int((l.z - TR_Z0) / 2.0)
	if c < 0 or r < 0 or c >= TR_NX or r >= TR_NZ:
		return
	var k2: String = "%d,%d" % [c, r]
	if not _trap_tiles.has(k2) or _trap_cd.has(k2):
		return
	_trap_cd[k2] = 1.6
	var tile: MeshInstance3D = _trap_tiles[k2]
	var y0: Vector3 = W(Vector3(TR_X0 + 2.0 * c + 1.0, -12.0 + 0.02, TR_Z0 + 2.0 * r + 1.0))
	var tw := create_tween()
	tw.tween_property(tile, "global_position", y0 + Vector3.DOWN * 0.035, 0.08)
	tw.tween_interval(1.0)
	tw.tween_property(tile, "global_position", y0, 0.3)
	_sfx("piege_dalle", y0)
	await get_tree().create_timer(0.25).timeout
	var from: Vector3 = W(Vector3(35.9, -12.0 + 1.2, l.z))
	_sfx("fleche_piege", from)
	_dart(from, _feet() + Vector3(0, 1.1, 0))
	await get_tree().create_timer(0.18).timeout
	if room == "pieges":
		_hurt(1, from)
		_once("fleches", "Clic… FIOU ! Une fléchette jaillit du mur de l'est ! Les dalles sombres et fêlées sont piégées : marche sur les claires.", 6.0)


func _dart(from: Vector3, to: Vector3) -> void:
	var d := MeshInstance3D.new()
	d.mesh = _cylm(0.012, 0.012, 0.45, 6)
	d.material_override = _m("fer71")
	_root("pieges").add_child(d)
	var dir: Vector3 = (to - from).normalized()
	d.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5), from)
	var tw := create_tween()
	tw.tween_property(d, "global_position", to, 0.18)
	tw.tween_interval(0.05)
	tw.tween_callback(d.queue_free)


# =================================================================== le Lac Souterrain

func _tick_lake() -> void:
	if _carrier == null and not bool(state["cle"]) and room_spawned("lac"):
		var best: Node3D = null
		var bd: float = 1e9
		for m in _room_monsters.get("lac", []):
			if is_instance_valid(m) and str(m.get("kind")) == "grenouille_geante":
				var dd: float = (m as Node3D).global_position.distance_to(W(FROG_KEY))
				if dd < bd:
					bd = dd
					best = m
		if best != null:
			_carrier = best
			if _known("cle_cuivre"):
				best.set_meta("butin_extra", [["cle_cuivre", 1]])
			# un reflet de cuivre, dans le ventre
			var gl := OmniLight3D.new()
			gl.name = "Reflet_cuivre"
			gl.light_color = Color(1.0, 0.55, 0.25)
			gl.light_energy = 1.4
			gl.omni_range = 2.6
			best.add_child(gl)
			gl.position = Vector3(0, 0.55, 0.3)
	if _carrier != null and (not is_instance_valid(_carrier) or str(_carrier.get("state")) == "mort"):
		var at: Vector3 = _carrier.global_position if is_instance_valid(_carrier) else W(FROG_KEY)
		_carrier = null
		if not bool(state["cle"]):
			state["cle"] = true
			if _known("cle_cuivre") and _inv().count("cle_cuivre") <= 0:
				_inv().spawn_pickup(key + "_cle_cuivre", "cle_cuivre", 1, at + Vector3(0, 0.3, 0))
			_say("La grenouille fait « blurp »… et recrache une clé de cuivre, toute gluante ! (Elle l'avait prise pour une mouche. Une mouche très dure.)", 6.0)


func _swallowed() -> bool:
	for m in _room_monsters.get("lac", []):
		if is_instance_valid(m) and m.has_method("is_swallowing") and bool(m.is_swallowing()):
			return true
	return false


func _copper_door() -> void:
	if not bool(state["cle"]) and _inv().count("cle_cuivre") <= 0:
		_say("Une porte de cuivre, et une grosse serrure en forme de grenouille, bouche ouverte. (Tiens donc.) Il faut une clé de cuivre… et une des grenouilles a le ventre qui brille.", 7.0)
		return
	if _inv().count("cle_cuivre") > 0:
		_inv().remove("cle_cuivre", 1)
	state["cle"] = true
	_sfx("porte_donjon", W(Vector3(12, -22, 180.6)))
	open_gate("lac", "La clé de cuivre entre dans la bouche de la serrure-grenouille, qui fait « croâ » (si, si). La porte de cuivre s'enfonce dans le sol.")


# =================================================================== la Bibliothèque des Mimiques

func _read_book() -> void:
	_sfx("page", W(Vector3(12, -34.8, 211.0)))
	_say("LE GRAND LIVRE DES COFFRES (tome 7 : « Ceux qui mordent »). « Six coffres dorment ici, et trois ont des dents. Le crâne sourit trop : méfie-toi des sourires. La couronne se prend pour un roi : elle mord comme un roi. Le sablier compte les secondes avant son dîner (toi). La chandelle et les livres sont honnêtes, mais pauvres. Le vrai trésor dort près de celui qui veille la nuit et ne répond que « hou ». » Dans la marge, au crayon : « J'ai essayé le crâne. Je déconseille. »", 16.0)


func _mimic_sleeping(i: int) -> bool:
	var m: Node3D = _mimics.get(i, null)
	return m != null and is_instance_valid(m) and m.has_method("is_sleeping") and bool(m.is_sleeping())


func _open_mimic(i: int) -> void:
	var m: Node3D = _mimics.get(i, null)
	if m == null or not is_instance_valid(m):
		return
	if m.has_method("wake"):
		m.wake()
	_say(["Tu soulèves le couvercle… Le coffre ouvre un œil. Puis une bouche. Pleine de dents. Oups.", "Le coffre bâille. Très grand. Avec une langue. Ce n'était pas un coffre !", "« Crr… » fait le coffre en se léchant les babines. Le Grand Livre avait prévenu."][i % 3], 5.0)


func _tick_library() -> void:
	if _mimics_set or not room_spawned("biblio"):
		return
	_mimics_set = true
	_mimics.clear()
	for m in _room_monsters.get("biblio", []):
		if not is_instance_valid(m) or str(m.get("kind")) != "mimique":
			continue
		var mm: Node3D = m
		var best: int = -1
		var bd: float = 1e9
		for i in range(DAIS.size()):
			if str(DAIS[i][3]) != "mimique":
				continue
			var d: float = Vector2(L(mm.global_position).x - float(DAIS[i][0]), L(mm.global_position).z - float(DAIS[i][1])).length()
			if d < bd:
				bd = d
				best = i
		if best >= 0:
			_mimics[best] = mm
			var inward := Vector3(signf(12.0 - float(DAIS[best][0])), 0, 0)
			mm.set("facing", inward)
			mm.rotation.y = atan2(inward.x, inward.z)


func _silver_door() -> void:
	if not bool(state["vrai_coffre"]) and _inv().count("cle_argent") <= 0:
		_say("Une porte d'argent, ciselée de hiboux qui dorment. La serrure attend une clé d'argent. (Le Grand Livre, sur le lutrin, saurait peut-être où elle est.)", 7.0)
		return
	if _inv().count("cle_argent") > 0:
		_inv().remove("cle_argent", 1)
	_sfx("porte_donjon", W(Vector3(12, -34, 240.6)))
	open_gate("biblio", "La clé d'argent tourne. Les hiboux ciselés ouvrent tous un œil (« hou ») et la porte d'argent s'enfonce dans le sol. Plus bas, ça sent la pomme verte… et la gelée.")


# =================================================================== le Roi Gélatineux

func _roi_dead() -> void:
	_kill_strays()
	state["boss"] = true
	_say("Le Roi Gélatineux tremble, gargouille une dernière fois (« Ma couronne… elle était trop petite, de toute façon… ») et s'étale en une grande flaque qui sent la pomme verte. Au milieu brille un cœur de gelée, comme un bonbon géant.", 9.0)
	await get_tree().create_timer(2.5).timeout
	state["fini"] = true
	_royal_reward()
	if _light_stairs != null:
		_light_stairs.visible = true
		_light_stairs.scale = Vector3(1, 0.05, 1)
		create_tween().tween_property(_light_stairs, "scale", Vector3.ONE, 2.0).set_trans(Tween.TRANS_SINE)
	_sfx("cristal_retour", W(Vector3(12, -44, 291.0)))


## La récompense du Roi : le Cœur de gelée royale (s'il n'est pas déjà tombé dans le sac avec le
## butin du Roi), 200 pièces, un titre, un cœur de plus.
func _royal_reward() -> void:
	var inv: Node = _inv()
	if _known("coeur_gelee") and inv.count("coeur_gelee") <= 0:
		if inv.add("coeur_gelee", 1) <= 0:
			inv.spawn_pickup(key + "_relique", "coeur_gelee", 1, W(Vector3(12, -47.5, 290.0)))
	inv.add("piece", 200)
	var title: String = "Vainqueur du Roi Gélatineux"
	var j: Node = main.get("journal_v56")
	if j != null:
		if not (j.titres as Array).has(title):
			j.titres.append(title)
		j.bonus["coeur"] = int(j.bonus.get("coeur", 0)) + 1
		j.apply_bonuses()
	var hero: Node = main.get("hero_v28")
	if hero != null:
		hero.set_health(int(hero.HP_MAX))
	if main.has_method("jingle"):
		main.jingle("decouverte")
	main._show_message_v28("Le Cœur de gelée royale ! 200 pièces, un cœur de plus, et un titre : « %s ». Un escalier de lumière descend du plafond : il remonte jusqu'à la surface. Odon va devoir agrandir son registre !" % title)


## Les petits slimes nés du Roi (monstre_v71 les appelle lui-même) : on les compte dans la salle.
func _strays() -> Array:
	var out: Array = []
	var mo: Node = main.get("monstres_v36")
	if mo == null or not rooms.has("trone"):
		return out
	var a: Vector3 = rooms["trone"]["a"]
	var b: Vector3 = rooms["trone"]["b"]
	for m in mo.monsters:
		if not is_instance_valid(m) or str(m.get("state")) == "mort" or not (str(m.get("kind")) in ["slime", "slime_bleu", "slime_rose"]):
			continue
		var l: Vector3 = L((m as Node3D).global_position)
		if l.x > a.x - 2.0 and l.x < b.x + 2.0 and l.z > a.z - 2.0 and l.z < b.z + 2.0 and l.y > a.y - 6.0 and l.y < b.y:
			out.append(m)
	return out


func _kill_strays() -> void:
	for m in _strays():
		m.take_hit(99, (m as Node3D).global_position + Vector3.UP)


func _free_strays() -> void:
	var mo: Node = main.get("monstres_v36") if main != null else null
	for m in _strays():
		if mo != null:
			mo.monsters.erase(m)
		(m as Node).queue_free()


# =================================================================== les portes

func open_gate(n: String, text: String = "") -> void:
	if gate_open(n):
		return
	state["portes"][n] = true
	_set_gate(n, true, true)
	var g: Node3D = gates.get(n, null)
	if g != null:
		_sfx("porte_donjon", g.global_position + Vector3.UP)
		_sfx("pierre_glisse", g.global_position + Vector3.UP)
		var hide_later := get_tree().create_timer(2.4)
		hide_later.timeout.connect(func(): if is_instance_valid(g) and gate_open(n): g.visible = false)
	if text != "":
		_say(text, 6.0)


# =================================================================== chaque image

func _tick(delta: float, p: Vector3, r: String) -> void:
	var l: Vector3 = L(p)
	match r:
		"pieges":
			_tick_traps(delta, l)
		"lac":
			_tick_lake()
			if l.y < -24.8 and l.z > 142.0 and l.z < 170.0 and _fall_cd <= 0.0 and not _swallowed():
				_fall_cd = 1.5
				_fall_back("Plouf ! L'eau du lac est froide comme un matin d'hiver. Tu remontes sur la rive en grelottant ; les grenouilles rigolent (enfin, elles coassent). Saute de pierre en pierre !", 0)
		"biblio":
			_tick_library()
		"trone":
			if not bool(state["boss"]) and not fight and l.z > 274.0:
				_say("Le sol fait « blop ». Une gelée verte grande comme une maison se dresse devant le trône, une couronne minuscule posée de travers : LE ROI GÉLATINEUX ! « Qui ose marcher sur mes dalles propres ? » gargouille-t-il.", 8.0)
				_start_boss("slime_roi", Vector3(12, -48, 292.0), "le Roi Gélatineux", Callable(self, "_roi_dead"))
			if fight:
				_strays_t -= delta
				if _strays_t <= 0.0:
					_strays_t = 1.0
					for m in _strays():
						var mm: Node3D = m
						if L(mm.global_position).y < -52.0:
							mm.global_position = W(Vector3(12, -47.6, 288.0))
	_tick_ball(delta, l, r)
	if not _shortcut_ia.is_empty():
		_shortcut_ia["text"] = "E : descendre directement à l'étage %d (Odon l'a noté)" % clampi(deepest(), 2, 5)
	for c in _crystal_nodes:
		if (c as Node3D).is_visible_in_tree():
			(c as Node3D).rotate_y(delta * 0.7)


## La lueur de chaque étage (donjon_v35 pose la pénombre en entrant).
func _mood(r: String) -> void:
	if main == null or main.get("donjon_v35") == null or not bool(main.donjon_v35.get("inside")):
		return
	for c in main.get_children():
		if c is WorldEnvironment:
			var env: Environment = (c as WorldEnvironment).environment
			var f: int = int(FLOOR.get(r, 1))
			env.fog_density = 0.014
			match f:
				1:
					env.ambient_light_color = Color(0.5, 0.6, 0.44)
					env.ambient_light_energy = 1.3
					env.fog_light_color = Color(0.03, 0.05, 0.03)
					env.tonemap_exposure = 1.4
				3:
					env.ambient_light_color = Color(0.42, 0.52, 0.64)
					env.ambient_light_energy = 1.2
					env.fog_light_color = Color(0.02, 0.04, 0.06)
					env.tonemap_exposure = 1.35
				5:
					env.ambient_light_color = Color(0.5, 0.62, 0.42)
					env.ambient_light_energy = 1.4
					env.fog_light_color = Color(0.03, 0.05, 0.02)
					env.tonemap_exposure = 1.4
				_:
					env.ambient_light_color = Color(0.64, 0.52, 0.4)
					env.ambient_light_energy = 1.4
					env.fog_light_color = Color(0.05, 0.035, 0.025)
					env.tonemap_exposure = 1.4
			return


func _enter_room(_old: String, r: String) -> void:
	_mood(r)
	var f: int = int(FLOOR.get(r, 0))
	if not r.begins_with("esc") and f > deepest():
		state["profond"] = f
		if f >= 2:
			_say("Étage %d : %s ! (Odon le notera dans son registre : le cristal du hall pourra t'y redescendre directement.)" % [f, FLOOR_NAMES[f]], 5.0)
			return
	match r:
		"caves":
			_once("caves", "Les Caves Gluantes. Des couloirs de pierre moussue qui tournent dans tous les sens, et partout, des petites flaques qui font « blop ». Des slimes ! L'escalier qui descend est quelque part au sud-est.", 8.0)
		"esc1", "esc2", "esc3", "esc4":
			_once(r, ["Des marches, des marches, encore des marches… On les appelle les Mille Marches. Odon en a compté 999 : il cherche encore la dernière.", "Encore des marches. Tes mollets protestent poliment.", "Des marches mouillées : on entend l'eau, en bas.", "Les marches sentent la pomme verte. Ce n'est pas bon signe."][int(r.substr(3)) - 1], 6.0)
		"pieges":
			_once("pieges", "La Salle des Pièges. À l'est, un champ de dalles (certaines sont sombres et fêlées…) ; à l'ouest, un feu de camp et des gobelins ; au sud, une porte fermée, et trois lampes éteintes au-dessus. Trois leviers à trouver !", 9.0)
		"couloir":
			if not bool(state["rocher"]):
				_once("couloir", "Un long couloir, une ornière bien droite au milieu… et, au fond, un levier. Au plafond, un grand trou rond. Hmm.", 6.0)
		"lac":
			_once("lac", "Le Lac Souterrain. Des pierres plates forment un gué… et des grenouilles géantes, grosses comme des tonneaux, te regardent. L'une d'elles, sur l'îlot de l'ouest, a le ventre qui brille d'un éclat de cuivre. Elle a avalé quelque chose.", 9.0)
		"biblio":
			_once("biblio", "La Bibliothèque des Mimiques. Des livres jusqu'au plafond, six coffres sur six estrades, chacun gardé par une statuette… et, au milieu, un grand livre ouvert sur un lutrin.", 8.0)
		"trone":
			if not bool(state["boss"]):
				_once("trone", "La Salle du Trône Gélatineux. Le sol colle aux semelles, un trône de gelée tremblote au fond… et une odeur de pomme verte flotte partout.", 7.0)


func _on_enter(first: bool) -> void:
	if first:
		_say("Tu descends l'escalier de la vieille tour. Les marches s'enfoncent dans le noir, l'air sent la mousse et… la gelée ? En bas, un hall, un règlement, et un cristal bleu.", 8.0)
	elif deepest() >= 2:
		_say("Le Donjon des Mille Marches. Odon a noté l'étage %d dans son registre : le cristal violet du hall t'y descend directement." % deepest(), 6.0)
	else:
		_say("Le Donjon des Mille Marches.", 3.0)


## La visite en images (tour71) : place la caméra pour un plan du donjon. Renvoie false si le
## plan n'est pas d'ici. Plans : d_hall, d_caves, d_pieges, d_couloir, d_lac, d_mimiques, d_trone.
const SHOTS := {
	"d_hall": ["hall", Vector3(1.5, 1.7, 10.8), Vector3(-0.5, 1.6, 1.0), "Le hall du Donjon des Mille Marches"],
	"d_caves": ["caves", Vector3(0, 1.7, 13.2), Vector3(0, 0.8, 24.0), "Étage 1 : les Caves Gluantes"],
	"d_pieges": ["pieges", Vector3(12, -10.2, 76.0), Vector3(24, -11.5, 94.0), "Étage 2 : la Salle des Pièges"],
	"d_couloir": ["couloir", Vector3(-13.5, -10.3, 90.0), Vector3(-36, -10.0, 89.0), "Le Couloir du Rocher"],
	"d_lac": ["lac", Vector3(12, -22.2, 134.0), Vector3(10, -24.5, 158.0), "Étage 3 : le Lac Souterrain"],
	"d_mimiques": ["biblio", Vector3(12, -34.0, 219.0), Vector3(-8, -35.0, 222.0), "Étage 4 : la Bibliothèque des Mimiques"],
	"d_trone": ["trone", Vector3(12, -46.0, 268.5), Vector3(12, -44.0, 300.0), "Étage 5 : la Salle du Trône Gélatineux"],
}


func tour_shot(m: Node, shot: String) -> bool:
	if not SHOTS.has(shot):
		return false
	ensure_built()
	var s: Array = SHOTS[shot]
	var r: String = s[0]
	if m.has_method("_in71"):
		await m._in71(self, s[1])
	room = r
	_visibility(r)
	_mood(r)
	if m.has_method("_cam56"):
		await m._cam56(W(s[1]), W(s[2]), str(s[3]), 70.0, 10)
	return true


func _fall_text(_r: String) -> String:
	return "Tu tombes… et tu te retrouves, étourdi, au début de la salle. (Une marche de plus pour le compte d'Odon.)"


func _faint_text() -> String:
	return "Un petit slime te tapote la joue d'une gelée bien fraîche : « Blop ? » (Ça veut dire « debout ».)"


func _on_reset() -> void:
	_ball_on = false
	if _ball != null:
		_ball.visible = false
	_trap_cd.clear()
	_carrier = null
	_mimics.clear()
	_mimics_set = false
	if built:
		_free_strays()
