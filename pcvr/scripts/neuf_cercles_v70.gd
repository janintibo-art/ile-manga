extends "res://scripts/enigmes_v69.gd"
## V70 : les Neuf Cercles, sous la Cathédrale-Forge de Pandémonia. Le voyage de Dante, en plus
## gentil (et plus drôle) : au fond, le Titan de Givre a volé la Flamme Éternelle, et le
## Cœur-Brasier de la cité s'éteint. On descend, cercle après cercle :
##  0. le Vestibule : la porte et son inscription (« Vous qui entrez ici, gardez l'espoir (et
##     prenez un manteau) ») ; une coupe d'oboles, une patère et ses manteaux ;
##  1. l'Achéron : Charon, le passeur, demande une obole pour traverser ;
##  2. les Limbes : des ombres ; la lumière des sages à conduire, de miroir en miroir, jusqu'au
##     cristal qui ouvre la porte ;
##  3. Minos, le juge : trois questions sur le voyage (la réponse fausse : on recommence) ;
##     la Tourmente : un couloir au bord du vide, des rafales ; on s'abrite derrière les piliers ;
##  4. Cerbère : trois gâteaux de miel (un par tête)… ou le combat ;
##  5. les Avares : pousser les deux grands poids sur les deux dalles ;
##  6. le Styx : un marais de boue ; seules tiennent les dalles qui ne bouillonnent pas ; la porte
##     de Dité, et les trois Furies ;
##  7. les Tombeaux de feu : des rangées de tombeaux qui crachent des flammes, chacune à son tour ;
##  8. le Phlégéthon : une rivière de lave, des radeaux de basalte ; Géryon vous porte, en volant,
##     jusqu'à Malebolge ;
##  9. Malebolge : trois fossés, trois ponts qui tournent, des diablotins ; le Puits des Géants :
##     Antée, un géant très doux, vous descend au fond ; le Cocyte, le lac gelé : le Titan de
##     Givre. La Flamme Éternelle, puis l'escalier de lumière.

const PBv = preload("res://scripts/pnj/pnj_braise_v70.gd")
const T := 0.8
## Les Limbes : la source de la lumière des sages, les trois miroirs (x, z), le cristal
const SRC := Vector2(-15.2, 56.0)
const MIRRORS := [Vector2(-4.0, 56.0), Vector2(-4.0, 68.0), Vector2(8.0, 68.0)]
const MIRROR_OK := [1, 3, 2]
const CRYSTAL := Vector2(8.0, 50.6)
## Minos : les questions (texte, réponses, bonne réponse)
const QUESTIONS := [
	["Qu'est-il écrit au-dessus de la porte des Neuf Cercles ?", ["« Vous qui entrez ici, laissez toute espérance. »", "« Vous qui entrez ici, gardez l'espoir (et prenez un manteau). »", "« Défense d'entrer : chien méchant (trois fois). »"], 1],
	["Que demande Charon pour passer l'Achéron ?", ["Une chanson à boire.", "Une obole.", "Un gâteau de miel."], 1],
	["Qu'est-ce qui éclaire les Limbes ?", ["La lumière des sages, de miroir en miroir.", "Les yeux des ombres.", "Une lanterne de Lumina, oubliée là."], 0],
	["Combien de cercles compte ce royaume ?", ["Sept, comme les jours.", "Douze, comme les mois.", "Neuf."], 2],
]
## Les Avares : la grille (cases de 2,5 m), les deux poids, les deux dalles, les tas d'or
const GRID0 := Vector2(63.75, 108.75)
const GRID_N := Vector2i(9, 6)
const WEIGHTS0 := [Vector2i(3, 1), Vector2i(5, 2)]
const PLATES := [Vector2i(2, 4), Vector2i(6, 4)]
const PILES := [Vector2i(1, 2), Vector2i(7, 1), Vector2i(4, 3)]
## Le Styx : les dalles (colonne 0..2 en x 68, 74, 80 ; rangée 0..5) ; celles qui tiennent
const SLAB_X := [68.0, 74.0, 80.0]
const SLAB_Z := [134.5, 138.5, 142.5, 146.5, 150.5, 154.5]
const SLAB_OK := [1, 0, 0, 1, 2, 2]
## Les Tombeaux de feu : les rangées (z)
const TOMB_ROWS := [171.0, 176.5, 182.0]
## Le Phlégéthon : les radeaux (z), les rives (x)
const RAFT_Z := [174.0, 184.0]
## Malebolge : les fossés (z du milieu)
const DITCH_Z := [160.0, 170.0, 180.0]

var _beam_root: Node3D
var _mirror_nodes: Array = []
var _crystal_mat: StandardMaterial3D
var _crystal_light: OmniLight3D
var _charon: Node3D
var _boat: Node3D
var _q: Array = []                       # les questions tirées pour ce passage devant Minos
var _qi: int = 0
var _weights: Array = []                 # Node3D
var _weight_ia: Array = []
var _plates_mats: Array = []
var _slabs: Array = []                   # [AnimatableBody3D, col, row, sinking]
var _slab_t: Dictionary = {}
var _tomb_fires: Array = []              # par rangée : [CPUParticles3D…]
var _tomb_lights: Array = []
var _tomb_t: float = 0.0
var _tomb_cd: float = 0.0
var _rafts: Array = []
var _bridges: Array = []
var _gust_t: float = 0.0
var _gust: CPUParticles3D
var _cold_t: float = 0.0
var _snow: CPUParticles3D
var _flame: Node3D
var _furies: bool = false


func _init() -> void:
	key = "braise"
	titre = "les Neuf Cercles"
	O = Vector3(-900.0, -150.0, 560.0)
	bbox = AABB(Vector3(-58.0, -40.0, -6.0), Vector3(156.0, 62.0, 290.0))
	room_spawns = {
		"limbes": [["ombre", -10.0, 0.0, 62.0], ["ombre", 10.0, 0.0, 60.0], ["ombre", 0.0, 0.0, 70.0]],
		"tombeaux": [["diablotin", 66.0, 0.0, 179.0], ["diablotin", 82.0, 0.0, 173.0]],
		"malebolge": [["diablotin", -30.0, -12.0, 165.0], ["diablotin", -10.0, -12.0, 175.0], ["diablotin", -26.0, -12.0, 186.0]],
		"cocyte": [["spectre_givre", -34.0, -24.0, 232.0], ["spectre_givre", -6.0, -24.0, 236.0]],
	}


func _defaults() -> Dictionary:
	return {"obole": false, "manteau": false, "miroirs": [0, 0, 0], "limbes": false, "minos": false, "cerbere": false, "gateaux": false,
		"poids": [[3, 1], [5, 2]], "avares": false, "dite": false, "geryon": false}


## Le donjon se dessine avec le kit de Pandémonia (ses matières « …70 », et celles des donjons).
func ensure_built() -> void:
	if built:
		return
	built = true
	var t0: int = Time.get_ticks_msec()
	kit = load("res://scripts/braise_kit_v70.gd").new()
	kit.setup69(self, main, pc)
	kit.body.name = "Collisions_donjon_" + key
	_build()
	_register()
	_apply_state()
	_hide_all(false)
	print("ILE_MANGA_V70: %s construits en %d ms" % [titre, Time.get_ticks_msec() - t0])


func entry() -> Array:
	return [W(Vector3(0, 0, 4.0)), Vector3(0, 0, 1)]


func exit_point() -> Array:
	var city: Node = sol.get("city") if sol != null else null
	if city == null or city.get("lieux") == null:
		return [Vector3.ZERO, Vector3(0, 0, 1)]
	var door: Vector3 = city.lieux.porte_cercles
	var c: Vector3 = (city.lieux.coeur as Dictionary)["base"]
	var d: Vector3 = c - door
	d.y = 0.0
	d = d.normalized() if d.length() > 0.1 else Vector3(0, 0, 1)
	return [door + d * 1.0 + Vector3.UP * 0.1, d]


func _xf() -> Transform3D:
	return Transform3D(Basis(), O)


func _torch(n: String, l: Vector3, facing: Vector3, energy: float = 1.5) -> void:
	kit.torch(rooms[n]["root"], W(l), facing, energy)


func _root(n: String) -> Node3D:
	return rooms[n]["root"]


## Une nappe de lave (UV en mètres, le courant le long de x ou de z).
func _lava(n: String, x0: float, x1: float, z0: float, z1: float, y: float, along_z: bool = false) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := [Vector3(x0, y, z0), Vector3(x1, y, z0), Vector3(x1, y, z1), Vector3(x0, y, z1)]
	for i in [0, 2, 1, 0, 3, 2]:
		var v: Vector3 = c[i]
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(v.z - z0, v.x - x0) if along_z else Vector2(v.x - x0, v.z - z0))
		st.add_vertex(W(v))
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = kit.mat("lave70")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_root(n).add_child(mi)
	return mi


## Une nappe d'eau (ou de boue) sombre.
func _water(n: String, x0: float, x1: float, z0: float, z1: float, y: float, k: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(x1 - x0, z1 - z0)
	mi.mesh = pm
	mi.material_override = kit.mat(k)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_root(n).add_child(mi)
	mi.global_position = W(Vector3((x0 + x1) * 0.5, y, (z0 + z1) * 0.5))
	return mi


## Un mur plein (boîte locale de a à b).
func _block(a: Vector3, b: Vector3, k: String, tile: float = 3.0) -> void:
	kit.solid(X((a + b) * 0.5), (b - a).abs(), k, tile)


# =================================================================== construction

func _build() -> void:
	add_room("vestibule", Vector3(-7, 0, 0), Vector3(7, 10, 18), Vector3(0, 0, 4.0), Vector3(0, 0, 1), ["acheron"])
	add_room("acheron", Vector3(-15, 0, 18), Vector3(15, 12, 36), Vector3(0, 0, 21.0), Vector3(0, 0, 1), ["vestibule", "rive"])
	add_room("rive", Vector3(-15, 0, 36), Vector3(15, 12, 48), Vector3(0, 0, 38.5), Vector3(0, 0, 1), ["acheron", "limbes"])
	add_room("limbes", Vector3(-16, 0, 48), Vector3(16, 10, 76), Vector3(0, 0, 50.5), Vector3(0, 0, 1), ["rive", "minos"])
	add_room("minos", Vector3(-12, 0, 76), Vector3(12, 14, 96), Vector3(0, 0, 78.5), Vector3(0, 0, 1), ["limbes", "tourmente"])
	add_room("tourmente", Vector3(12, 0, 78), Vector3(60, 10, 94), Vector3(14.0, 0, 90.0), Vector3(1, 0, 0), ["minos", "cerbere"])
	add_room("cerbere", Vector3(60, 0, 76), Vector3(88, 12, 104), Vector3(62.0, 0, 90.0), Vector3(1, 0, 0), ["tourmente", "avares"])
	add_room("avares", Vector3(60, 0, 104), Vector3(88, 10, 128), Vector3(74.0, 0, 106.0), Vector3(0, 0, 1), ["cerbere", "styx"])
	add_room("styx", Vector3(54, 0, 128), Vector3(94, 14, 166), Vector3(74.0, 0, 130.0), Vector3(0, 0, 1), ["avares", "tombeaux"])
	add_room("tombeaux", Vector3(60, 0, 166), Vector3(88, 10, 192), Vector3(74.0, 0, 168.0), Vector3(0, 0, 1), ["styx", "phlegethon"])
	add_room("phlegethon", Vector3(18, 0, 166), Vector3(60, 12, 194), Vector3(57.0, 0, 186.0), Vector3(-1, 0, 0), ["tombeaux"])
	add_room("malebolge", Vector3(-40, -12, 150), Vector3(0, 2, 192), Vector3(-20.0, -12, 153.0), Vector3(0, 0, 1), ["puits"])
	add_room("puits", Vector3(-40, -24, 192), Vector3(0, 4, 216), Vector3(-20.0, -12, 194.5), Vector3(0, 0, 1), ["malebolge", "cocyte"])
	add_room("cocyte", Vector3(-50, -24, 216), Vector3(10, 0, 276), Vector3(-20.0, -24, 219.0), Vector3(0, 0, 1), ["puits"])
	_build_vestibule()
	_build_acheron()
	_build_limbes()
	_build_minos()
	_build_tourmente()
	_build_cerbere()
	_build_avares()
	_build_styx()
	_build_tombeaux()
	_build_phlegethon()
	_build_malebolge()
	_build_puits()
	_build_cocyte()
	_fill_lights()
	kit.commit()


## Une lumière douce par salle (sans ombre), à la couleur du cercle : les pierres sont sombres,
## les torches seules ne suffisent pas à voir le chemin.
const FILL := {"vestibule": Color(1.0, 0.75, 0.5), "acheron": Color(0.55, 0.65, 0.9), "rive": Color(0.55, 0.65, 0.9),
	"limbes": Color(1.0, 0.85, 0.6), "minos": Color(1.0, 0.7, 0.45), "tourmente": Color(1.0, 0.55, 0.35), "cerbere": Color(1.0, 0.55, 0.3),
	"avares": Color(1.0, 0.82, 0.45), "styx": Color(0.8, 0.6, 0.45), "tombeaux": Color(1.0, 0.5, 0.3), "phlegethon": Color(1.0, 0.5, 0.25),
	"malebolge": Color(1.0, 0.5, 0.3), "puits": Color(0.6, 0.75, 1.0), "cocyte": Color(0.6, 0.8, 1.0)}

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
		for c in cells:
			var l := OmniLight3D.new()
			l.name = "Ambiance"
			l.light_color = FILL.get(n, Color(1.0, 0.8, 0.6))
			l.light_energy = 0.9
			l.light_specular = 0.1
			l.shadow_enabled = false
			l.omni_range = clampf(maxf(size.x, size.z) * (0.42 if cells.size() > 1 else 0.75), 12.0, 30.0)
			l.omni_attenuation = 0.6
			(rooms[n]["root"] as Node3D).add_child(l)
			l.global_position = W(Vector3(c.x, minf(b.y - 1.5, a.y + 8.0), c.z))


func _build_vestibule() -> void:
	_in_room("vestibule")
	kit.room(_xf(), -7, 7, 0, 18, 0, 10, "abysse70", "paves70_sombre", [["s", 0, 3.4, 4.4]], "abysse70", T)
	# l'escalier qui descend de la Cathédrale-Forge (il remonte dans le mur)
	kit.ramp(_xf(), Vector3(0, 0, 2.6), Vector3(0, 3.2, -0.2), 3.0, "pgoth70_sombre", "fer70")
	kit.solid(X(Vector3(0, 1.6, -0.6)), Vector3(3.6, 3.2, 0.8), "pgoth70_sombre")
	kit.quadz(X(Vector3(0, 4.4, 0.02)), 3.0, 2.2, "noir69")
	# l'inscription, au-dessus de la porte du sud
	kit.door_frame(X(Vector3(0, 0, 17.6), 0.0), 3.4, 4.4, 1.0, "pgoth70_sombre", "fer70")
	kit.panel(X(Vector3(0, 6.9, 17.15), PI), 5.2, 2.6, "fresque70_porte", "pgoth70_sombre")
	# la coupe d'oboles (pour Charon) et la patère aux manteaux
	kit.solid(X(Vector3(4.8, 0.5, 9.0)), Vector3(0.9, 1.0, 0.9), "pgoth70_sombre", 1.0)
	kit.cyl(X(Vector3(4.8, 1.0, 9.0)), 0.3, 0.5, 0.22, "bronze70", 20)
	kit.coins(W(Vector3(4.8, 1.22, 9.0)), 10, 0.3)
	kit.box(X(Vector3(-6.55, 2.2, 9.0), 0.0), Vector3(0.1, 0.12, 4.0), "boisb70", 1.0)
	for k in range(4):
		var z: float = 7.6 + k * 0.95
		kit.box(X(Vector3(-6.35, 2.2, z)), Vector3(0.3, 0.05, 0.05), "fer70", 1.0)
		kit.box(X(Vector3(-6.3, 1.45, z)), Vector3(0.18, 1.5, 0.7), ["tissu70_rouge", "tissu70_noir", "tissu70_pourpre", "tissu70_vert"][k], 1.0)
	kit.panel(X(Vector3(-6.9, 3.4, 4.0), PI * 0.5), 2.6, 1.6, "affiche70_fete", "pgoth70_sombre")
	for z2 in [3.0, 14.0]:
		_torch("vestibule", Vector3(-6.85, 2.6, z2), Vector3(1, 0, 0))
		_torch("vestibule", Vector3(6.85, 2.6, z2), Vector3(-1, 0, 0))


func _build_acheron() -> void:
	_in_room("acheron")
	kit.room(_xf(), -15, 15, 18, 48, 0, 12, "abysse70", "", [["n", 0, 3.4, 4.4], ["s", 0, 3.4, 4.4]], "abysse70", T)
	# les deux rives, et le lit de la rivière
	kit.solid(X(Vector3(0, -0.3, 23.0 - T * 0.5)), Vector3(30.0 + 2 * T, 0.6, 10.0 + T), "basalte70", 3.0)
	kit.solid(X(Vector3(0, -0.3, 42.0 + T * 0.5)), Vector3(30.0 + 2 * T, 0.6, 12.0 + T), "basalte70", 3.0)
	kit.solid(X(Vector3(0, -3.3, 32.0)), Vector3(30.0 + 2 * T, 0.6, 8.0), "abysse70", 3.0)
	for s in [-1.0, 1.0]:
		kit.box(X(Vector3(0, -1.6, 32.0 + s * 4.0)), Vector3(30.0, 3.2, 0.3), "abysse70_noir", 2.0)
	_water("acheron", -15, 15, 28, 36, -1.0, "eau69_sombre")
	kit.glow_light(_root("acheron"), W(Vector3(0, -0.4, 32.0)), Color(0.35, 0.5, 0.8), 0.8, 18.0)
	# la barque de Charon et Charon lui-même (une grande robe noire, deux yeux d'or, la rame)
	_boat = Node3D.new()
	_boat.name = "Barque_de_Charon"
	_root("acheron").add_child(_boat)
	var hull := StandardMaterial3D.new()
	hull.albedo_color = Color(0.16, 0.12, 0.1)
	hull.roughness = 0.8
	var robe := StandardMaterial3D.new()
	robe.albedo_color = Color(0.06, 0.05, 0.06)
	robe.roughness = 0.95
	var eye := StandardMaterial3D.new()
	eye.albedo_color = Color(1.0, 0.8, 0.3)
	eye.emission_enabled = true
	eye.emission = Color(1.0, 0.75, 0.25)
	eye.emission_energy_multiplier = 4.0
	_mesh_box(_boat, Vector3(1.6, 0.5, 5.0), hull, Vector3(0, 0.0, 0))
	_mesh_box(_boat, Vector3(1.2, 0.2, 4.4), robe, Vector3(0, 0.18, 0))
	for e in [-1.0, 1.0]:
		var prow := MeshInstance3D.new()
		var pc := CylinderMesh.new()
		pc.top_radius = 0.05
		pc.bottom_radius = 0.18
		pc.height = 1.2
		prow.mesh = pc
		prow.material_override = hull
		prow.position = Vector3(0, 0.5, e * 2.6)
		prow.rotation.x = -e * 0.6
		_boat.add_child(prow)
	_charon = Node3D.new()
	_boat.add_child(_charon)
	_charon.position = Vector3(0, 0.25, -1.4)
	var body := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 0.22
	bc.bottom_radius = 0.5
	bc.height = 1.9
	body.mesh = bc
	body.material_override = robe
	body.position = Vector3(0, 0.95, 0)
	_charon.add_child(body)
	var hood := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.25
	hs.height = 0.55
	hood.mesh = hs
	hood.material_override = robe
	hood.position = Vector3(0, 2.05, 0)
	_charon.add_child(hood)
	for sx in [-0.07, 0.07]:
		var ey := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.03
		es.height = 0.05
		ey.mesh = es
		ey.material_override = eye
		ey.position = Vector3(sx, 2.05, 0.2)
		_charon.add_child(ey)
	var oar := MeshInstance3D.new()
	var oc := CylinderMesh.new()
	oc.top_radius = 0.03
	oc.bottom_radius = 0.03
	oc.height = 3.2
	oar.mesh = oc
	oar.material_override = hull
	oar.position = Vector3(0.35, 1.3, 0.3)
	oar.rotation.x = 0.35
	_charon.add_child(oar)
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.7, 0.35)
	lamp.light_energy = 1.4
	lamp.omni_range = 7.0
	lamp.position = Vector3(0, 2.6, 1.2)
	_charon.add_child(lamp)
	kit.panel(X(Vector3(-14.85, 4.5, 26.0), PI * 0.5), 5.0, 3.0, "fresque70_charon", "abysse70_noir")
	for z in [22.0, 44.0]:
		_torch("acheron", Vector3(-14.85, 2.6, z), Vector3(1, 0, 0))
		_torch("acheron", Vector3(14.85, 2.6, z), Vector3(-1, 0, 0))
	_torch("acheron", Vector3(-5.0, 2.6, 18.15), Vector3(0, 0, 1))
	_torch("acheron", Vector3(5.0, 2.6, 47.85), Vector3(0, 0, -1))
	_place_boat(false)


func _mesh_box(parent: Node3D, size: Vector3, m: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	return mi


## La barque, au bord de la rive nord (avant de passer) ou de la rive sud.
func _place_boat(south: bool) -> void:
	if _boat == null:
		return
	_boat.global_transform = Transform3D(Basis(Vector3.UP, PI * 0.5), W(Vector3(6.0, -0.75, 34.4 if south else 29.6)))


func _build_limbes() -> void:
	_in_room("limbes")
	kit.room(_xf(), -16, 16, 48, 76, 0, 10, "abysse70", "paves70_sombre", [["n", 0, 3.4, 4.4], ["s", 0, 3.4, 4.4]], "abysse70", T)
	gate("limbes", "limbes", Vector3(0, 0, 76.6), 3.4, 4.4, 0.6, 0.0, "fer70", "sym70_cercle_1")
	# la source : le sage assis, qui tient la lumière (un orbe d'or)
	_seated(X(Vector3(-14.4, 0, 56.0), PI * 0.5), 0.8, "pgoth70_sombre", "")
	var orb := MeshInstance3D.new()
	var os := SphereMesh.new()
	os.radius = 0.22
	os.height = 0.44
	orb.mesh = os
	orb.material_override = kit.mat("lueur70_or")
	_root("limbes").add_child(orb)
	orb.global_position = W(Vector3(SRC.x + 2.0, 1.3, SRC.y))
	kit.glow_light(_root("limbes"), W(Vector3(SRC.x + 2.6, 1.8, SRC.y)), Color(1.0, 0.8, 0.4), 1.2, 6.0)
	# les trois miroirs (un cadre de bronze sur un socle tournant) : orientés à la main
	_mirror_nodes.clear()
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.85, 0.88, 0.92)
	glass.metallic = 1.0
	glass.roughness = 0.04
	for i in range(MIRRORS.size()):
		var m := Node3D.new()
		m.name = "Miroir_%d" % i
		_root("limbes").add_child(m)
		m.global_position = W(Vector3(MIRRORS[i].x, 0, MIRRORS[i].y))
		_mesh_box(m, Vector3(0.9, 0.3, 0.9), kit.mat("pgoth70_sombre"), Vector3(0, 0.15, 0))
		var face := Node3D.new()
		face.name = "Face"
		m.add_child(face)
		_mesh_box(face, Vector3(1.5, 2.0, 0.08), glass, Vector3(0, 1.4, 0.05))
		_mesh_box(face, Vector3(1.7, 2.2, 0.1), kit.mat("bronze70"), Vector3(0, 1.4, -0.04))
		kit.col_box(X(Vector3(MIRRORS[i].x, 1.0, MIRRORS[i].y)), Vector3(1.0, 2.0, 1.0))
		_mirror_nodes.append(m)
	# le cristal (il s'allume quand la lumière l'atteint)
	_crystal_mat = StandardMaterial3D.new()
	_crystal_mat.albedo_color = Color(0.7, 0.85, 1.0)
	_crystal_mat.roughness = 0.1
	_crystal_mat.emission_enabled = true
	_crystal_mat.emission = Color(1.0, 0.85, 0.45)
	_crystal_mat.emission_energy_multiplier = 0.1
	kit.solid(X(Vector3(CRYSTAL.x, 0.5, CRYSTAL.y)), Vector3(1.2, 1.0, 1.2), "pgoth70_sombre", 1.0)
	var cr := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = 0.35
	cm.height = 1.4
	cm.radial_segments = 6
	cr.mesh = cm
	cr.material_override = _crystal_mat
	_root("limbes").add_child(cr)
	cr.global_position = W(Vector3(CRYSTAL.x, 1.7, CRYSTAL.y))
	_crystal_light = kit.glow_light(_root("limbes"), W(Vector3(CRYSTAL.x, 2.4, CRYSTAL.y + 1.0)), Color(1.0, 0.85, 0.45), 0.0, 12.0)
	_beam_root = Node3D.new()
	_beam_root.name = "Lumiere_des_sages"
	_root("limbes").add_child(_beam_root)
	# des colonnes, des sages de pierre le long des murs
	for p in [Vector3(-10, 0, 52), Vector3(10, 0, 52), Vector3(-10, 0, 72), Vector3(10, 0, 72)]:
		kit.column(X(p), 0.6, 10.0, "pgoth70_sombre", "abysse70")
	for z in [60.0, 66.0]:
		_seated(X(Vector3(15.0, 0, z), -PI * 0.5), 0.8, "pgoth70_noir", "")
	for z2 in [52.0, 64.0, 74.0]:
		_torch("limbes", Vector3(-15.85, 2.6, z2), Vector3(1, 0, 0), 1.1)
		_torch("limbes", Vector3(15.85, 2.6, z2), Vector3(-1, 0, 0), 1.1)


func _build_minos() -> void:
	_in_room("minos")
	kit.room(_xf(), -12, 12, 76, 96, 0, 14, "abysse70", "palais70_sombre", [["n", 0, 3.4, 4.4], ["e", 90, 3.4, 4.4]], "abysse70", T)
	gate("minos", "minos", Vector3(12.4, 0, 90.0), 3.4, 4.4, 0.6, PI * 0.5, "fer70", "sym70_cercle_2")
	# Minos, le juge : un roi assis, immense, la couronne, et sa longue queue de serpent enroulée
	kit.solid(X(Vector3(0, 0.6, 92.5)), Vector3(8.0, 1.2, 5.0), "mnoir70", 2.0)
	_seated(X(Vector3(0, 1.2, 93.0), PI), 2.6, "bronze70", "or70")
	var tail_path: Array = []
	for k2 in range(12):
		var t: float = float(k2) / 11.0
		var a2: float = t * TAU * 1.6
		tail_path.append(W(Vector3(cos(a2) * (4.0 - t * 1.6), 1.4 + t * 2.2, 91.0 + sin(a2) * (2.6 - t * 0.8))))
	var tp: PackedVector3Array = PBv.smooth_path(tail_path, 60)
	var tr := PackedFloat32Array()
	for i in range(tp.size()):
		tr.append(lerpf(0.42, 0.06, float(i) / float(tp.size() - 1)))
	var tail := MeshInstance3D.new()
	tail.mesh = PBv.tube_mesh(tp, tr, 14, 0.0, 0.0, Color(0.32, 0.24, 0.16), Color(0.5, 0.36, 0.2))
	var tm := StandardMaterial3D.new()
	tm.vertex_color_use_as_albedo = true
	tm.roughness = 0.4
	tm.metallic = 0.6
	tail.material_override = tm
	_root("minos").add_child(tail)
	kit.glow_light(_root("minos"), W(Vector3(0, 9.0, 88.0)), Color(1.0, 0.65, 0.3), 1.6, 16.0)
	kit.panel(X(Vector3(-11.85, 5.0, 86.0), PI * 0.5), 5.0, 3.0, "fresque70_minos", "abysse70_noir")
	for z in [80.0, 92.0]:
		_torch("minos", Vector3(-11.85, 2.8, z), Vector3(1, 0, 0))
		_torch("minos", Vector3(11.85, 2.8, z), Vector3(-1, 0, 0))
	for x in [-6.0, 6.0]:
		kit.brazier63(_root("minos"), W(Vector3(x, 0, 85.0)), true, "bronze70", 2.0, "pgoth70_sombre")


## Une grande figure assise sur son trône (un sage, un juge), le dos au mur : xf au sol, la
## figure regarde vers +Z ; s = 1 : 2,5 m. Une couronne de pointes si crown_key.
func _seated(xf: Transform3D, s: float, key: String, crown_key: String) -> void:
	var B := func(p: Vector3, sz: Vector3, k: String) -> void:
		kit.box(xf * Transform3D(Basis(), p * s), sz * s, k, 1.0)
	B.call(Vector3(0, 0.45, -0.1), Vector3(1.5, 0.9, 1.3), key)
	B.call(Vector3(0, 1.6, -0.62), Vector3(1.6, 2.4, 0.25), key)
	for sx in [-1.0, 1.0]:
		B.call(Vector3(sx * 0.2, 1.05, 0.25), Vector3(0.34, 0.3, 0.9), key)
		B.call(Vector3(sx * 0.2, 0.5, 0.68), Vector3(0.3, 1.0, 0.32), key)
		B.call(Vector3(sx * 0.2, 0.06, 0.78), Vector3(0.32, 0.12, 0.5), key)
		B.call(Vector3(sx * 0.62, 1.15, 0.05), Vector3(0.26, 0.26, 0.9), key)
		B.call(Vector3(sx * 0.62, 1.2, 0.5), Vector3(0.2, 0.2, 0.2), key)
	B.call(Vector3(0, 1.7, -0.2), Vector3(0.95, 1.1, 0.55), key)
	B.call(Vector3(0, 2.2, -0.2), Vector3(1.3, 0.32, 0.62), key)
	B.call(Vector3(0, 2.62, -0.15), Vector3(0.44, 0.52, 0.48), key)
	B.call(Vector3(0, 2.36, 0.08), Vector3(0.38, 0.4, 0.22), key)
	if crown_key != "":
		B.call(Vector3(0, 2.92, -0.15), Vector3(0.52, 0.1, 0.56), crown_key)
		for k in range(5):
			var a: float = deg_to_rad(-60.0 + k * 30.0)
			kit.cyl(xf * Transform3D(Basis(), Vector3(sin(a) * 0.2, 2.96, -0.15 + cos(a) * 0.2) * s), 0.06 * s, 0.0, 0.3 * s, crown_key, 6)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 1.3, -0.1) * s), Vector3(1.6, 2.6, 1.4) * s)


func _build_tourmente() -> void:
	_in_room("tourmente")
	kit.room(_xf(), 12, 60, 78, 94, 0, 10, "abysse70", "", [["w", 90, 3.4, 4.4], ["e", 90, 3.4, 4.4]], "abysse70", T)
	# le chemin, au bord du vide (au nord, le gouffre)
	kit.solid(X(Vector3(36.0, -0.3, 91.0 + T * 0.25)), Vector3(48.0 + 2 * T, 0.6, 6.0 + T * 0.5), "basalte70", 3.0)
	kit.solid(X(Vector3(36.0, -10.3, 83.0)), Vector3(48.0 + 2 * T, 0.6, 10.0 + T), "abysse70_noir", 3.0)
	_lava("tourmente", 12.0, 60.0, 78.0, 88.0, -9.8)
	kit.glow_light(_root("tourmente"), W(Vector3(36.0, -6.0, 83.0)), Color(1.0, 0.4, 0.15), 2.0, 20.0)
	# les abris : de gros piliers contre le mur du sud (le vent ne passe pas derrière)
	for x in [21.0, 31.0, 41.0, 51.0]:
		kit.solid(X(Vector3(x, 3.0, 89.2)), Vector3(1.4, 6.0, 1.4), "pgoth70_sombre", 1.5)
	for x2 in [16.0, 26.0, 36.0, 46.0, 56.0]:
		_torch("tourmente", Vector3(x2, 2.6, 93.85), Vector3(0, 0, -1), 1.3)
	# les rafales : des feuilles mortes et des cendres
	_gust = CPUParticles3D.new()
	_gust.amount = 160
	_gust.lifetime = 1.4
	_gust.emitting = false
	_gust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_gust.emission_box_extents = Vector3(24.0, 3.0, 1.0)
	_gust.direction = Vector3(0, 0, -1)
	_gust.spread = 10.0
	_gust.initial_velocity_min = 8.0
	_gust.initial_velocity_max = 12.0
	_gust.gravity = Vector3.ZERO
	_gust.scale_amount_min = 0.4
	_gust.scale_amount_max = 1.0
	var qm := QuadMesh.new()
	qm.size = Vector2(0.18, 0.12)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.32, 0.18)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.material = m
	_gust.mesh = qm
	_root("tourmente").add_child(_gust)
	_gust.global_position = W(Vector3(36.0, 1.5, 93.0))


func _build_cerbere() -> void:
	_in_room("cerbere")
	kit.room(_xf(), 60, 88, 76, 104, 0, 12, "abysse70", "basalte70", [["w", 90, 3.4, 4.4], ["s", 74, 3.4, 4.4]], "abysse70", T)
	gate("cerbere", "cerbere", Vector3(74.0, 0, 104.6), 3.4, 4.4, 0.6, 0.0, "fer70", "sym70_cercle_3")
	# la gamelle de Cerbère (son nom gravé dessus), des os, de la paille
	kit.cyl(X(Vector3(82.0, 0, 82.0)), 1.6, 1.4, 0.6, "bronze70", 24)
	kit.disc(X(Vector3(82.0, 0.55, 82.0)), 1.3, "noir69", 20)
	kit.panel(X(Vector3(74.0, 5.0, 76.15), 0.0), 5.0, 3.0, "fresque70_cerbere", "abysse70_noir")
	kit.rocks(_root("cerbere"), [W(Vector3(64.0, 0, 80.0)), W(Vector3(84.0, 0, 98.0)), W(Vector3(65.0, 0, 99.0))], 7031, "basalte70", 0.6, 1.4)
	for x in [66.0, 82.0]:
		kit.brazier63(_root("cerbere"), W(Vector3(x, 0, 90.0)), true, "fer70", 2.4, "pgoth70_sombre")
	for z in [80.0, 100.0]:
		_torch("cerbere", Vector3(60.15, 2.8, z), Vector3(1, 0, 0), 1.4)
		_torch("cerbere", Vector3(87.85, 2.8, z), Vector3(-1, 0, 0), 1.4)


func _cell_pos(c: Vector2i) -> Vector3:
	return Vector3(GRID0.x + 2.5 * c.x, 0, GRID0.y + 2.5 * c.y)


func _build_avares() -> void:
	_in_room("avares")
	kit.room(_xf(), 60, 88, 104, 128, 0, 10, "abysse70", "mosaique70_sombre", [["n", 74, 3.4, 4.4], ["s", 74, 3.4, 4.4]], "abysse70", T)
	gate("avares", "avares", Vector3(74.0, 0, 128.6), 3.4, 4.4, 0.6, 0.0, "fer70", "sym70_cercle_4")
	# les dalles (où poser les poids), les tas d'or (on ne passe pas)
	_plates_mats.clear()
	for p in PLATES:
		var pm := StandardMaterial3D.new()
		pm.albedo_color = Color(0.85, 0.65, 0.25)
		pm.metallic = 0.8
		pm.roughness = 0.3
		pm.emission_enabled = true
		pm.emission = Color(1.0, 0.7, 0.25)
		pm.emission_energy_multiplier = 0.2
		var plate := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = Vector3(2.2, 0.08, 2.2)
		plate.mesh = pb
		plate.material_override = pm
		_root("avares").add_child(plate)
		plate.global_position = W(_cell_pos(p) + Vector3(0, 0.04, 0))
		_plates_mats.append(pm)
	for pile in PILES:
		var c: Vector3 = _cell_pos(pile)
		kit.solid(X(c + Vector3(0, 0.5, 0)), Vector3(2.0, 1.0, 2.0), "or70", 1.0)
		kit.coins(W(c + Vector3(0, 1.02, 0)), 12, 0.7)
	# le bord de la grille (des murets) : les poids ne sortent pas
	var gx0: float = GRID0.x - 1.25
	var gz0: float = GRID0.y - 1.25
	var gx1: float = GRID0.x + 2.5 * GRID_N.x - 1.25
	var gz1: float = GRID0.y + 2.5 * GRID_N.y - 1.25
	for s in [[Vector3(gx0, 0, gz0), Vector3(gx1, 0.4, gz0 + 0.3)], [Vector3(gx0, 0, gz1 - 0.3), Vector3(gx1, 0.4, gz1)], [Vector3(gx0, 0, gz0), Vector3(gx0 + 0.3, 0.4, gz1)], [Vector3(gx1 - 0.3, 0, gz0), Vector3(gx1, 0.4, gz1)]]:
		var a: Vector3 = s[0]
		var b: Vector3 = s[1]
		kit.box(X((a + b) * 0.5), (b - a).abs(), "or70", 1.0)
	# les deux grands poids (des sacs d'or de pierre, marqués « 1000 »)
	_weights.clear()
	for i in range(2):
		var w := AnimatableBody3D.new()
		w.name = "Poids_%d" % i
		w.sync_to_physics = false
		_root("avares").add_child(w)
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 1.0
		sm.height = 1.9
		mi.mesh = sm
		mi.material_override = kit.mat("pgoth70_or")
		mi.position = Vector3(0, 0.95, 0)
		w.add_child(mi)
		var knot := MeshInstance3D.new()
		var kc := CylinderMesh.new()
		kc.top_radius = 0.35
		kc.bottom_radius = 0.18
		kc.height = 0.5
		knot.mesh = kc
		knot.material_override = kit.mat("pgoth70_or")
		knot.position = Vector3(0, 2.0, 0)
		w.add_child(knot)
		var cs := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 1.0
		cyl.height = 2.2
		cs.shape = cyl
		cs.position = Vector3(0, 1.1, 0)
		w.add_child(cs)
		_weights.append(w)
	kit.panel(X(Vector3(60.15, 4.5, 116.0), PI * 0.5), 4.0, 2.4, "plan70", "abysse70_noir")
	for z in [108.0, 124.0]:
		_torch("avares", Vector3(60.15, 2.6, z), Vector3(1, 0, 0), 1.4)
		_torch("avares", Vector3(87.85, 2.6, z), Vector3(-1, 0, 0), 1.4)
	kit.glow_light(_root("avares"), W(Vector3(74.0, 6.0, 116.0)), Color(1.0, 0.75, 0.35), 1.2, 16.0)


func _build_styx() -> void:
	_in_room("styx")
	kit.room(_xf(), 54, 94, 128, 166, 0, 14, "abysse70", "", [["n", 74, 3.4, 4.4], ["s", 74, 4.0, 6.0]], "abysse70", T)
	gate("dite", "styx", Vector3(74.0, 0, 166.6), 4.0, 6.0, 0.7, 0.0, "fer70_rouge", "sym70_flamme_sym")
	kit.solid(X(Vector3(74.0, -0.3, 130.0 - T * 0.25)), Vector3(40.0 + 2 * T, 0.6, 4.0 + T * 0.5), "basalte70", 3.0)
	kit.solid(X(Vector3(74.0, -0.3, 161.0 + T * 0.25)), Vector3(40.0 + 2 * T, 0.6, 10.0 + T * 0.5), "basalte70", 3.0)
	kit.solid(X(Vector3(74.0, -3.3, 144.0)), Vector3(40.0 + 2 * T, 0.6, 24.0), "abysse70", 3.0)
	_water("styx", 54, 94, 132, 156, -0.7, "boue70_sombre")
	# les murailles de Dité, rouges de feu, au sud
	for x in [62.0, 86.0]:
		kit.solid(X(Vector3(x, 6.0, 164.8)), Vector3(4.0, 12.0, 2.4), "fer70_rouge", 2.0)
		kit.glow_light(_root("styx"), W(Vector3(x, 9.0, 162.0)), Color(1.0, 0.35, 0.12), 1.6, 12.0)
	kit.panel(X(Vector3(74.0, 9.0, 165.1), PI), 6.0, 3.6, "fresque70_dite", "fer70")
	# les dalles du Styx
	_slabs.clear()
	for r in range(SLAB_Z.size()):
		for c in range(SLAB_X.size()):
			var sb := AnimatableBody3D.new()
			sb.name = "Dalle_%d_%d" % [c, r]
			sb.sync_to_physics = false
			_root("styx").add_child(sb)
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(2.6, 0.5, 2.6)
			mi.mesh = bm
			mi.material_override = kit.mat("basalte70_sombre")
			mi.position = Vector3(0, -0.25, 0)
			sb.add_child(mi)
			var cs := CollisionShape3D.new()
			var sh := BoxShape3D.new()
			sh.size = Vector3(2.6, 0.5, 2.6)
			cs.shape = sh
			cs.position = Vector3(0, -0.25, 0)
			sb.add_child(cs)
			sb.global_position = W(Vector3(SLAB_X[c], 0.0, SLAB_Z[r]))
			if int(SLAB_OK[r]) != c:
				# celle-ci bouillonne : des bulles de boue tout autour
				var bub := CPUParticles3D.new()
				bub.amount = 10
				bub.lifetime = 1.2
				bub.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
				bub.emission_box_extents = Vector3(1.5, 0.05, 1.5)
				bub.direction = Vector3.UP
				bub.spread = 10.0
				bub.initial_velocity_min = 0.2
				bub.initial_velocity_max = 0.5
				bub.gravity = Vector3.ZERO
				bub.scale_amount_min = 0.5
				bub.scale_amount_max = 1.2
				var bmesh := SphereMesh.new()
				bmesh.radius = 0.08
				bmesh.height = 0.12
				var bmat := StandardMaterial3D.new()
				bmat.albedo_color = Color(0.25, 0.2, 0.14)
				bmat.roughness = 0.2
				bmesh.material = bmat
				bub.mesh = bmesh
				bub.position = Vector3(0, -0.55, 0)
				sb.add_child(bub)
			_slabs.append([sb, c, r, false])
	for z in [131.0, 160.0]:
		_torch("styx", Vector3(54.15, 2.8, z), Vector3(1, 0, 0), 1.4)
		_torch("styx", Vector3(93.85, 2.8, z), Vector3(-1, 0, 0), 1.4)
	kit.glow_light(_root("styx"), W(Vector3(74.0, 4.0, 144.0)), Color(0.55, 0.45, 0.3), 0.8, 24.0)


func _build_tombeaux() -> void:
	_in_room("tombeaux")
	kit.room(_xf(), 60, 88, 166, 192, 0, 10, "abysse70", "paves70_sombre", [["n", 74, 4.0, 6.0], ["w", 186, 3.4, 4.4]], "abysse70", T)
	_tomb_fires.clear()
	_tomb_lights.clear()
	for r in range(TOMB_ROWS.size()):
		var z: float = TOMB_ROWS[r]
		var fires: Array = []
		var x: float = 62.4
		while x < 86.0:
			kit.sarcophagus(X(Vector3(x, 0, z), PI * 0.5), true, "obsid70", "pgoth70_sombre")
			var f: CPUParticles3D = kit.fire(_root("tombeaux"), W(Vector3(x, 1.0, z)), 0.45, 26)
			f.emitting = false
			fires.append(f)
			x += 3.4
		_tomb_fires.append(fires)
		_tomb_lights.append(kit.glow_light(_root("tombeaux"), W(Vector3(74.0, 2.5, z)), Color(1.0, 0.45, 0.15), 0.0, 16.0))
	var me = self
	chest("tombeaux", "tombeaux", Vector3(85.5, 0, 189.5), PI, [["potion_seve", 1], ["piece", 30]],
		"Dans un tombeau qui ne crache plus de flammes : une fiole de sève et une poignée de pièces. (Le propriétaire est parti en vacances.)")
	for z2 in [168.0, 190.0]:
		_torch("tombeaux", Vector3(60.15, 2.6, z2), Vector3(1, 0, 0), 1.2)
		_torch("tombeaux", Vector3(87.85, 2.6, z2), Vector3(-1, 0, 0), 1.2)


func _build_phlegethon() -> void:
	_in_room("phlegethon")
	kit.room(_xf(), 18, 60, 166, 194, 0, 12, "abysse70", "", [["e", 186, 3.4, 4.4]], "abysse70", T)
	kit.solid(X(Vector3(55.5 + T * 0.25, -0.3, 180.0)), Vector3(9.0 + T * 0.5, 0.6, 28.0 + 2 * T), "basalte70", 3.0)
	kit.solid(X(Vector3(22.5 - T * 0.25, -0.3, 180.0)), Vector3(9.0 + T * 0.5, 0.6, 28.0 + 2 * T), "basalte70", 3.0)
	kit.solid(X(Vector3(39.0, -2.3, 180.0)), Vector3(24.0, 0.6, 28.0 + 2 * T), "roche70", 3.0)
	_lava("phlegethon", 27.0, 51.0, 166.0, 194.0, -1.2, true)
	for z in [170.0, 180.0, 190.0]:
		kit.glow_light(_root("phlegethon"), W(Vector3(39.0, 1.0, z)), Color(1.0, 0.42, 0.12), 2.4, 14.0)
	# les radeaux de basalte (ils traversent tout seuls)
	_rafts.clear()
	for rz in RAFT_Z:
		var r := AnimatableBody3D.new()
		r.sync_to_physics = true
		_root("phlegethon").add_child(r)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(3.2, 0.6, 3.2)
		mi.mesh = bm
		mi.material_override = kit.mat("basalte70_sombre")
		mi.position = Vector3(0, -0.3, 0)
		r.add_child(mi)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(3.2, 0.6, 3.2)
		cs.shape = sh
		cs.position = Vector3(0, -0.3, 0)
		r.add_child(cs)
		r.global_position = W(Vector3(49.4, 0.0, rz))
		_rafts.append(r)
	# Géryon, sur la rive ouest : un corps de serpent, des pattes de lion, de grandes ailes, et le
	# visage d'un brave homme (qui s'ennuie un peu)
	var g := Node3D.new()
	g.name = "Geryon"
	_root("phlegethon").add_child(g)
	g.global_transform = Transform3D(Basis(Vector3.UP, PI * 0.5), W(Vector3(22.0, 0, 180.0)))
	var gskin := StandardMaterial3D.new()
	gskin.albedo_color = Color(0.35, 0.3, 0.2)
	gskin.roughness = 0.5
	var gscale := StandardMaterial3D.new()
	gscale.albedo_color = Color(0.55, 0.25, 0.12)
	gscale.roughness = 0.4
	var path: Array = [Vector3(0, 1.6, 1.0), Vector3(0, 1.4, -1.0), Vector3(0.6, 0.8, -3.0), Vector3(1.6, 0.6, -4.6), Vector3(2.6, 1.2, -5.6), Vector3(2.8, 2.4, -6.0)]
	var gp: PackedVector3Array = PBv.smooth_path(path, 30)
	var gr := PackedFloat32Array()
	for i in range(gp.size()):
		gr.append(lerpf(0.85, 0.12, pow(float(i) / float(gp.size() - 1), 0.8)))
	var gb := MeshInstance3D.new()
	gb.mesh = PBv.tube_mesh(gp, gr, 14, 0.06, 0.25, Color(0.5, 0.3, 0.16), Color(0.62, 0.22, 0.1))
	var gm := StandardMaterial3D.new()
	gm.vertex_color_use_as_albedo = true
	gm.roughness = 0.45
	gb.material_override = gm
	g.add_child(gb)
	var head := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.55
	hs.height = 1.2
	head.mesh = hs
	head.material_override = gskin
	head.position = Vector3(0, 2.6, 1.6)
	g.add_child(head)
	var eye := StandardMaterial3D.new()
	eye.albedo_color = Color(0.95, 0.9, 0.7)
	eye.emission_enabled = true
	eye.emission = Color(1.0, 0.85, 0.5)
	eye.emission_energy_multiplier = 1.5
	for sx in [-0.2, 0.2]:
		var e := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.08
		es.height = 0.12
		e.mesh = es
		e.material_override = eye
		e.position = Vector3(sx, 2.75, 2.1)
		g.add_child(e)
	for sx2 in [-1.0, 1.0]:
		for fz in [0.8, -1.6]:
			var leg := MeshInstance3D.new()
			var lc := CylinderMesh.new()
			lc.top_radius = 0.22
			lc.bottom_radius = 0.16
			lc.height = 1.4
			leg.mesh = lc
			leg.material_override = gskin
			leg.position = Vector3(sx2 * 0.7, 0.7, fz)
			g.add_child(leg)
		var w := Node3D.new()
		w.position = Vector3(sx2 * 0.6, 2.2, -0.4)
		w.rotation.z = sx2 * 0.5
		g.add_child(w)
		var wm := StandardMaterial3D.new()
		wm.albedo_color = Color(0.4, 0.16, 0.1)
		wm.cull_mode = BaseMaterial3D.CULL_DISABLED
		wm.roughness = 0.7
		var wing := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(4.2, 2.6, 0.05)
		wing.mesh = pm
		wing.material_override = wm
		wing.position = Vector3(sx2 * 2.0, 0.6, 0)
		wing.rotation = Vector3(0, 0, sx2 * -1.1)
		w.add_child(wing)
	kit.col_box(X(Vector3(22.0, 1.4, 180.0)), Vector3(2.2, 2.8, 4.0))
	kit.panel(X(Vector3(18.15, 5.5, 172.0), PI * 0.5), 5.0, 3.0, "fresque70_geryon", "abysse70_noir")
	for z2 in [170.0, 190.0]:
		_torch("phlegethon", Vector3(59.85, 2.6, z2), Vector3(-1, 0, 0), 1.2)
		_torch("phlegethon", Vector3(18.15, 2.6, z2), Vector3(1, 0, 0), 1.2)


func _build_malebolge() -> void:
	_in_room("malebolge")
	kit.room(_xf(), -40, 0, 150, 192, -12, 14, "abysse70", "", [["s", -20, 3.4, 4.4]], "abysse70", T)
	# le sol entre les fossés, et le fond des fossés (la lave, très bas)
	var edges: Array = [150.0 - T]
	for dz in DITCH_Z:
		edges.append(float(dz) - 2.0)
		edges.append(float(dz) + 2.0)
	edges.append(192.0 + T)
	for i in range(0, edges.size(), 2):
		var z0: float = edges[i]
		var z1: float = edges[i + 1]
		kit.solid(X(Vector3(-20.0, -12.3, (z0 + z1) * 0.5)), Vector3(40.0 + 2 * T, 0.6, z1 - z0), "basalte70_sombre", 3.0)
	for dz2 in DITCH_Z:
		kit.solid(X(Vector3(-20.0, -22.3, float(dz2))), Vector3(40.0, 0.6, 4.0), "abysse70", 3.0)
		for s in [-1.0, 1.0]:
			kit.box(X(Vector3(-20.0, -17.0, float(dz2) + s * 1.95)), Vector3(40.0, 10.0, 0.1), "abysse70_noir", 3.0)
		_lava("malebolge", -40.0, 0.0, float(dz2) - 2.0, float(dz2) + 2.0, -21.6)
		kit.glow_light(_root("malebolge"), W(Vector3(-20.0, -16.0, float(dz2))), Color(1.0, 0.42, 0.12), 2.0, 14.0)
	# les ponts qui tournent
	_bridges.clear()
	for dz3 in DITCH_Z:
		var b := AnimatableBody3D.new()
		b.sync_to_physics = true
		_root("malebolge").add_child(b)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(2.4, 0.4, 7.6)
		mi.mesh = bm
		mi.material_override = kit.mat("fer70")
		mi.position = Vector3(0, -0.2, 0)
		b.add_child(mi)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(2.4, 0.4, 7.6)
		cs.shape = sh
		cs.position = Vector3(0, -0.2, 0)
		b.add_child(cs)
		b.global_position = W(Vector3(-20.0, -12.0, float(dz3)))
		_bridges.append(b)
		kit.cyl(X(Vector3(-20.0, -12.6, float(dz3))), 0.6, 0.6, 0.4, "fer70", 12)
	for z in [154.0, 165.0, 175.0, 186.0]:
		_torch("malebolge", Vector3(-39.85, -9.4, z), Vector3(1, 0, 0), 1.3)
		_torch("malebolge", Vector3(-0.15, -9.4, z), Vector3(-1, 0, 0), 1.3)


func _build_puits() -> void:
	_in_room("puits")
	# le palier du haut (au niveau de Malebolge), le puits, le fond (au niveau du Cocyte)
	kit.solid(X(Vector3(-20.0, -12.3, 195.0)), Vector3(40.0, 0.6, 6.0), "basalte70_sombre", 3.0)
	kit.box(X(Vector3(-20.0, -11.55, 197.95)), Vector3(40.0, 0.9, 0.1), "fer70", 2.0)
	kit.solid(X(Vector3(-20.0, -24.3, 204.0)), Vector3(40.0 + 2 * T, 0.6, 24.0 + 2 * T), "glace70", 3.0)
	_block(Vector3(-40.0 - T, -24.0, 192.0 - T), Vector3(-40.0, 4.0, 216.0 + T), "abysse70")
	_block(Vector3(0.0, -24.0, 192.0 - T), Vector3(T, 4.0, 216.0 + T), "abysse70")
	_block(Vector3(-40.0, -24.0, 192.0 - T), Vector3(0.0, -12.6, 192.0), "abysse70")
	# le mur du sud (une porte en bas, vers le Cocyte)
	_block(Vector3(-40.0, -24.0, 216.0), Vector3(-21.7, 4.0, 216.0 + T), "abysse70")
	_block(Vector3(-18.3, -24.0, 216.0), Vector3(0.0, 4.0, 216.0 + T), "abysse70")
	_block(Vector3(-21.7, -19.6, 216.0), Vector3(-18.3, 4.0, 216.0 + T), "abysse70")
	_block(Vector3(-40.0, 4.0, 192.0 - T), Vector3(0.0, 4.8, 216.0 + T), "abysse70")
	# les Géants, enchaînés dans la pierre jusqu'à la taille
	for g in [[-34.0, 206.0, 0.6], [-6.0, 206.0, -0.6], [-30.0, 213.0, 0.2], [-10.0, 213.0, -0.2]]:
		_giant(Vector3(float(g[0]), -24.0, float(g[1])), float(g[2]))
	# Antée, le plus doux des géants, au bord du palier : il tend la main
	_giant(Vector3(-20.0, -24.0, 203.0), PI, true)
	for x in [-36.0, -4.0]:
		_torch("puits", Vector3(x, -9.4, 192.15), Vector3(0, 0, 1), 1.4)
		_torch("puits", Vector3(x, -21.4, 215.85), Vector3(0, 0, -1), 1.4)
	kit.glow_light(_root("puits"), W(Vector3(-20.0, -16.0, 206.0)), Color(0.55, 0.75, 1.0), 1.4, 24.0)


## Un géant de pierre (bras croisés, chaînes de fer), 11 m de haut.
func _giant(at: Vector3, yaw: float, antee: bool = false) -> void:
	var xf: Transform3D = Transform3D(Basis(Vector3.UP, yaw), W(at))
	var k: String = "basalte70" if not antee else "pgoth70"
	kit.box(xf * Transform3D(Basis(), Vector3(0, 3.0, 0)), Vector3(3.4, 6.0, 2.2), k, 2.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 7.2, 0)), Vector3(4.4, 3.6, 2.4), k, 2.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 9.9, 0.1)), Vector3(1.8, 1.9, 1.8), k, 1.5)
	for s in [-1.0, 1.0]:
		kit.box(xf * Transform3D(Basis(), Vector3(s * 0.6, 9.6, 0.92)), Vector3(0.3, 0.2, 0.1), "lueur70_bleu" if not antee else "lueur70_or", 1.0)
		if antee:
			# le bras tendu vers le palier
			kit.box(xf * Transform3D(Basis(Vector3.RIGHT, -0.9), Vector3(s * 2.6, 8.4, 0.8)), Vector3(1.0, 3.6, 1.0), k, 1.5)
		else:
			kit.box(xf * Transform3D(Basis(), Vector3(s * 0.8, 7.0, 1.3)), Vector3(3.0, 0.9, 0.9), k, 1.5)
	if not antee:
		for c in range(6):
			kit.cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(-2.4 + c * 0.95, 5.4, 1.2)), 0.14, 0.14, 0.7, "fer70", 8)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 5.0, 0)), Vector3(4.4, 10.0, 2.4))


func _build_cocyte() -> void:
	_in_room("cocyte")
	kit.room(_xf(), -50, 10, 216, 276, -24, 24, "givre70", "glace70", [["n", -20, 3.4, 4.4]], "abysse70", T, 4.0)
	# des piliers de glace, des stalactites, des silhouettes prises dans la glace (des statues)
	for p in [Vector3(-40, -24, 228), Vector3(0, -24, 228), Vector3(-44, -24, 252), Vector3(4, -24, 252), Vector3(-36, -24, 270), Vector3(-4, -24, 270)]:
		kit.cyl(X(p), 1.4, 2.0, 24.0, "glace70", 10)
		kit.col_cyl(W(p), 1.8, 24.0)
	for k in range(26):
		var a: float = float(k) * 2.39996
		var r: float = 6.0 + float(k % 7) * 3.3
		var px: float = -20.0 + cos(a) * r * 1.15
		var pz: float = 246.0 + sin(a) * r
		var ln: float = 3.0 + float(k % 5)
		kit.cyl(X(Vector3(px, -ln, pz)), 0.0, 0.5 + float(k % 3) * 0.2, ln, "glace70", 6)
	# le trône du Titan (au fond), l'autel de la Flamme Éternelle
	kit.solid(X(Vector3(-20.0, -23.0, 271.0)), Vector3(12.0, 2.0, 8.0), "glace70", 2.0)
	kit.ramp(_xf(), Vector3(-20.0, -24.0, 264.6), Vector3(-20.0, -22.0, 267.2), 4.0, "glace70")
	kit.solid(X(Vector3(-20.0, -21.5, 271.0)), Vector3(1.6, 1.0, 1.6), "obsid70", 1.0)
	kit.panel(X(Vector3(-20.0, -14.0, 275.15), PI), 8.0, 5.0, "fresque70_cocyte", "givre70")
	_flame = Node3D.new()
	_flame.name = "Flamme_Eternelle"
	_root("cocyte").add_child(_flame)
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(1.0, 0.8, 0.3)
	fm.emission_enabled = true
	fm.emission = Color(1.0, 0.7, 0.25)
	fm.emission_energy_multiplier = 5.0
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var fl := MeshInstance3D.new()
	var fc := CylinderMesh.new()
	fc.top_radius = 0.0
	fc.bottom_radius = 0.25
	fc.height = 0.8
	fl.mesh = fc
	fl.material_override = fm
	_flame.add_child(fl)
	var ff: CPUParticles3D = kit.fire(_flame, Vector3(0, -0.2, 0), 0.25, 40)
	ff.position = Vector3(0, -0.2, 0)
	var flight := OmniLight3D.new()
	flight.light_color = Color(1.0, 0.7, 0.3)
	flight.light_energy = 3.0
	flight.omni_range = 14.0
	_flame.add_child(flight)
	_flame.global_position = W(Vector3(-20.0, -20.4, 271.0))
	_flame.visible = false
	# le froid : de la neige qui tombe ; des lumières bleues
	_snow = CPUParticles3D.new()
	_snow.amount = 300 if pc else 140
	_snow.lifetime = 6.0
	_snow.preprocess = 6.0
	_snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_snow.emission_box_extents = Vector3(30.0, 0.5, 30.0)
	_snow.direction = Vector3(0.3, -1, 0.1)
	_snow.spread = 20.0
	_snow.initial_velocity_min = 1.0
	_snow.initial_velocity_max = 2.0
	_snow.gravity = Vector3(0.4, -0.6, 0)
	_snow.scale_amount_min = 0.5
	_snow.scale_amount_max = 1.2
	var sq := QuadMesh.new()
	sq.size = Vector2(0.08, 0.08)
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.95, 0.97, 1.0)
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	if main.has_method("_soft_dot_v24"):
		sm.albedo_texture = main._soft_dot_v24()
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sq.material = sm
	_snow.mesh = sq
	_snow.visibility_aabb = AABB(Vector3(-32, -26, -32), Vector3(64, 30, 64))
	_root("cocyte").add_child(_snow)
	_snow.global_position = W(Vector3(-20.0, -1.0, 246.0))
	for p2 in [Vector3(-20, -18, 230), Vector3(-36, -18, 246), Vector3(-4, -18, 246), Vector3(-20, -16, 262)]:
		kit.glow_light(_root("cocyte"), W(p2), Color(0.55, 0.78, 1.0), 2.0, 26.0)
	for x in [-30.0, -10.0]:
		_torch("cocyte", Vector3(x, -21.4, 216.15), Vector3(0, 0, 1), 1.4)


# =================================================================== dehors, le carnet

func register(journal: Node) -> void:
	journal.lieux["neuf_cercles"] = W(Vector3(0, 0, 4.0))


# =================================================================== invites du donjon

func _register() -> void:
	var me = self
	ia("sortir", Vector3(0, 0, 2.2), 1.6, "E : remonter dans la Cathédrale-Forge", "Gâchette : remonter",
		func(): me.leave("De retour dans la nef de la Cathédrale-Forge. Il fait bon, ici."))
	ia("obole", Vector3(4.8, 0, 8.0), 1.6, "E : prendre une obole dans la coupe", "Gâchette : prendre une obole", func(): me._take_obole(),
		func(): return me._inv().count("obole") <= 0 and not bool(me.state["obole"]))
	ia("manteau", Vector3(-5.6, 0, 9.0), 1.8, "E : prendre un manteau", "Gâchette : prendre un manteau", func(): me._take_coat(),
		func(): return not bool(me.state["manteau"]))
	ia("inscription", Vector3(0, 0, 15.6), 2.0, "E : lire l'inscription", "Gâchette : l'inscription",
		func(): me._say("Au-dessus de la porte, en lettres de feu : « VOUS QUI ENTREZ ICI, GARDEZ L'ESPOIR (ET PRENEZ UN MANTEAU). » Plus bas, plus petit : « Le passeur n'accepte que les oboles. Pas de pièces trouées. »", 9.0))
	ia("charon", Vector3(6.0, 0, 26.6), 2.4, "E : parler à Charon, le passeur", "Gâchette : parler à Charon", func(): me._charon_talk(false),
		func(): return me.room == "acheron")
	ia("charon_sud", Vector3(6.0, 0, 37.4), 2.4, "E : repasser l'Achéron avec Charon", "Gâchette : repasser l'Achéron", func(): me._charon_talk(true),
		func(): return bool(me.state["obole"]) and me.room == "rive")
	for i in range(MIRRORS.size()):
		var ii: int = i
		var p: Vector2 = MIRRORS[i]
		ia("miroir_%d" % i, Vector3(p.x, 0, p.y - 1.4), 1.7, "E : tourner le miroir", "Gâchette : tourner le miroir", func(): me._turn_mirror(ii),
			func(): return not bool(me.state["limbes"]))
	ia("minos", Vector3(0, 0, 88.0), 3.0, "E : se présenter devant Minos, le juge", "Gâchette : se présenter devant Minos", func(): me._minos(),
		func(): return not bool(me.state["minos"]))
	ia("gateaux", Vector3(74.0, 0, 90.0), 9.0, "E : lancer les trois gâteaux de miel à Cerbère", "Gâchette : lancer les gâteaux de miel", func(): me._cakes(),
		func(): return not bool(me.state["cerbere"]) and me.room == "cerbere" and me._inv().count("gateau_miel") >= 3)
	_weight_ia.clear()
	for i2 in range(2):
		var jj: int = i2
		var it: Dictionary = ia("poids_%d" % i2, Vector3.ZERO, 2.1, "E : pousser le poids", "Gâchette : pousser le poids", func(): me._push_weight(jj),
			func(): return not bool(me.state["avares"]))
		_weight_ia.append(it)
	ia("poids_remettre", Vector3(70.0, 0, 106.0), 1.6, "E : tirer le levier (les poids reviennent à leur place)", "Gâchette : le levier", func(): me._reset_weights(),
		func(): return not bool(me.state["avares"]))
	ia("geryon", Vector3(24.6, 0, 180.0), 2.6, "E : monter sur le dos de Géryon", "Gâchette : monter sur Géryon", func(): me._ride_geryon())
	ia("antee", Vector3(-20.0, -12.0, 196.6), 2.4, "E : demander à Antée de te descendre au fond du puits", "Gâchette : demander à Antée", func(): me._antee())
	ia("flamme", Vector3(-20.0, -22.0, 268.6), 2.6, "E : prendre la Flamme Éternelle", "Gâchette : prendre la Flamme", func(): me._take_flame(),
		func(): return bool(me.state["boss"]) and not bool(me.state["fini"]))
	ia("sortie_fin", Vector3(-20.0, -22.0, 268.6), 2.6, "E : monter l'escalier de lumière (vers la Cathédrale-Forge)", "Gâchette : remonter",
		func(): me.leave("Un escalier de lumière, des marches qui se réchauffent une à une… et te voilà dans la nef de la Cathédrale-Forge, la Flamme Éternelle dans les mains."),
		func(): return bool(me.state["fini"]))


func _apply_state() -> void:
	super._apply_state()
	if _mirror_nodes.is_empty():
		return
	for i in range(_mirror_nodes.size()):
		(_mirror_nodes[i] as Node3D).rotation.y = _mirror_yaw(int((state["miroirs"] as Array)[i]))
	_trace_beam()
	_place_weights()
	_place_boat(false)
	if _flame != null:
		_flame.visible = bool(state["boss"]) and not bool(state["fini"])


# =================================================================== le Vestibule, l'Achéron

func _take_obole() -> void:
	_inv().add("obole", 1)
	_sfx("obole", W(Vector3(4.8, 1.2, 9.0)))
	_say("Tu prends une obole dans la coupe de bronze. Une petite étiquette : « Pour Charon. Une par voyageur. Il compte. »", 6.0)


func _take_coat() -> void:
	state["manteau"] = true
	_sfx("equiper", _feet() + Vector3.UP)
	_say("Tu enfiles un grand manteau de laine rouge, bien chaud. Il sent un peu le soufre. (On ne sait jamais : l'inscription de la porte insiste.)", 6.0)


func _charon_talk(back: bool) -> void:
	if back:
		_travel_across(false)
		return
	if bool(state["obole"]):
		_say("Charon grogne : « Déjà payé. Monte. » Et la barque glisse sur l'eau noire.", 4.0)
		_travel_across(true)
		return
	if _inv().count("obole") <= 0:
		_say("Charon, le passeur, te regarde de ses yeux d'or : « Une obole pour traverser. Pas d'obole, pas de barque. Et ne me dis pas que tu l'as oubliée, ils disent tous ça. » (Il y avait une coupe d'oboles au Vestibule…)", 9.0)
		return
	_inv().remove("obole", 1)
	state["obole"] = true
	_sfx("obole", W(Vector3(6.0, 1.0, 28.0)))
	_say("Tu poses l'obole dans la main osseuse de Charon. Il la mord, la regarde, la range. « Monte. Et ne te penche pas : l'Achéron est froid, et il ne rend pas les chapeaux. »", 8.0)
	_travel_across(true)


func _travel_across(to_south: bool) -> void:
	_sfx("charon_rame", W(Vector3(6.0, 0, 32.0)))
	if to_south:
		await main.donjon_v35._travel(W(Vector3(3.0, 0, 38.5)), Vector3(0, 0, 1))
	else:
		await main.donjon_v35._travel(W(Vector3(3.0, 0, 24.0)), Vector3(0, 0, -1))
	_place_boat(to_south)


# =================================================================== les Limbes : la lumière des sages

func _mirror_yaw(k: int) -> float:
	# la normale du miroir (sa face) : 45° + 90° × k, dans le plan (x, z)
	var th: float = deg_to_rad(45.0 + 90.0 * float(k))
	var n := Vector3(cos(th), 0, sin(th))
	return atan2(n.x, n.z)


func _turn_mirror(i: int) -> void:
	var mm: Array = state["miroirs"]
	mm[i] = (int(mm[i]) + 1) % 4
	var m: Node3D = _mirror_nodes[i]
	var tw := create_tween()
	tw.tween_property(m, "rotation:y", _mirror_yaw(int(mm[i])), 0.5).set_trans(Tween.TRANS_SINE)
	_sfx("pierre_glisse", m.global_position + Vector3.UP)
	await tw.finished
	_trace_beam()


## Le trajet de la lumière : de la source, de miroir en miroir ; jusqu'au cristal, ou au mur.
func _trace_beam() -> void:
	if _beam_root == null:
		return
	for c in _beam_root.get_children():
		c.queue_free()
	var p: Vector2 = Vector2(SRC.x + 2.2, SRC.y)
	var d := Vector2(1, 0)
	var hit_crystal: bool = false
	for step in range(6):
		var best_t: float = INF
		var best: int = -1
		for i in range(MIRRORS.size()):
			var q: Vector2 = MIRRORS[i] - p
			var t: float = q.dot(d)
			if t > 0.3 and absf(q.cross(d)) < 0.2 and t < best_t:
				best_t = t
				best = i
		var qc: Vector2 = CRYSTAL - p
		var tc: float = qc.dot(d)
		var crystal_ahead: bool = tc > 0.3 and absf(qc.cross(d)) < 0.2 and tc < best_t
		if crystal_ahead:
			_beam_seg(p, CRYSTAL)
			hit_crystal = true
			break
		if best < 0:
			# jusqu'au mur
			var end: Vector2 = p + d * _to_wall(p, d)
			_beam_seg(p, end)
			break
		var mp: Vector2 = MIRRORS[best]
		_beam_seg(p, mp)
		var th: float = deg_to_rad(45.0 + 90.0 * float((state["miroirs"] as Array)[best]))
		var n := Vector2(cos(th), sin(th))
		if d.dot(n) >= 0.0:
			break                                     # le dos du miroir : la lumière s'arrête
		d = (d - 2.0 * d.dot(n) * n).normalized()
		d = Vector2(round(d.x), round(d.y))
		p = mp
	_crystal_mat.emission_energy_multiplier = 4.0 if hit_crystal else 0.1
	_crystal_light.light_energy = 2.4 if hit_crystal else 0.0
	if hit_crystal and not bool(state["limbes"]):
		state["limbes"] = true
		_sfx("cristal_eveil", W(Vector3(CRYSTAL.x, 1.5, CRYSTAL.y)))
		_say("La lumière des sages court de miroir en miroir… et frappe le cristal, qui s'embrase d'or ! Au sud, la porte des Limbes s'enfonce dans le sol.", 7.0)
		await get_tree().create_timer(2.0).timeout
		open_gate("limbes")


func _to_wall(p: Vector2, d: Vector2) -> float:
	var t: float = 40.0
	if d.x > 0.5:
		t = 15.8 - p.x
	elif d.x < -0.5:
		t = p.x + 15.8
	elif d.y > 0.5:
		t = 75.8 - p.y
	elif d.y < -0.5:
		t = p.y - 48.2
	return maxf(t, 0.1)


func _beam_seg(a: Vector2, b: Vector2) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var len_m: float = a.distance_to(b)
	bm.size = Vector3(0.08, 0.08, len_m)
	mi.mesh = bm
	mi.material_override = kit.mat("lueur70_or")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beam_root.add_child(mi)
	var mid: Vector2 = (a + b) * 0.5
	var dir: Vector2 = (b - a).normalized()
	mi.global_transform = Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.y)), W(Vector3(mid.x, 1.5, mid.y)))


# =================================================================== Minos

func _minos() -> void:
	if _q.is_empty() or _qi >= 3:
		var order: Array = [0, 1, 2, 3]
		order.shuffle()
		_q = order.slice(0, 3)
		_qi = 0
	_ask_minos()


func _ask_minos() -> void:
	var q: Array = QUESTIONS[int(_q[_qi])]
	var choices: Array = []
	var answers: Array = q[1]
	for i in range(answers.size()):
		choices.append({"id": "r%d" % i, "label": str(answers[i])})
	var intro: String = "« Qui vient là ? Un vivant ! » Minos, le juge, se penche, et sa queue de serpent s'enroule. « Réponds à trois questions sur ton voyage. " if _qi == 0 else "« Bien. Ensuite : "
	_ask(W(Vector3(0, 8.0, 92.0)), "Minos, le juge", "sévère", intro + str(q[0]) + " »", choices, Callable(self, "_minos_answer"))


func _minos_answer(id: String) -> void:
	_close_dialog()
	if not id.begins_with("r"):
		return
	var q: Array = QUESTIONS[int(_q[_qi])]
	if int(id.substr(1)) != int(q[2]):
		_q.clear()
		_qi = 0
		_sfx("onde_choc", W(Vector3(0, 2, 90)))
		_fall_back("Minos enroule sa queue autour de lui, une fois, deux fois, trois fois… « FAUX ! Retourne au début de la salle, et réfléchis. » (Ombreline, la bibliothécaire, connaît toutes les réponses.)", 0)
		return
	_qi += 1
	if _qi < 3:
		_sfx("clochette", W(Vector3(0, 6, 90)))
		_ask_minos()
		return
	state["minos"] = true
	_say("« Trois bonnes réponses. Tu as bien regardé ton chemin. » Minos se rassoit et déroule sa queue. « Passe. Le vent souffle fort, de l'autre côté : abrite-toi derrière les piliers. »", 9.0)
	await get_tree().create_timer(2.0).timeout
	open_gate("minos")


# =================================================================== Cerbère

func _cakes() -> void:
	_inv().remove("gateau_miel", 3)
	state["gateaux"] = true
	state["cerbere"] = true
	var b: Node3D = _boss
	if b != null and is_instance_valid(b) and b.has_method("endormir"):
		b.endormir()
	fight = false
	_boss = null
	_hide_bar()
	_sfx("cerbere_ronfle", W(Vector3(74, 2, 92)))
	_say("Tu lances les trois gâteaux de miel. Trois têtes, trois « gloups ». Cerbère se lèche les babines… bâille de ses trois gueules… et s'écroule en ronflant. Un ronflement à trois voix. La porte du sud s'ouvre.", 9.0)
	await get_tree().create_timer(1.5).timeout
	open_gate("cerbere")


func _cerbere_dead() -> void:
	state["cerbere"] = true
	_say("Cerbère s'effondre, ses trois têtes ensemble. (« Il aurait préféré des gâteaux », souffle une petite voix dans ta tête.) La porte du sud s'ouvre.", 7.0)
	await get_tree().create_timer(1.5).timeout
	open_gate("cerbere")


# =================================================================== les Avares : les poids

func _cell_of(w: Array) -> Vector2i:
	return Vector2i(int(w[0]), int(w[1]))


func _place_weights() -> void:
	var pw: Array = state["poids"]
	for i in range(_weights.size()):
		var c: Vector2i = _cell_of(pw[i])
		(_weights[i] as Node3D).global_position = W(_cell_pos(c))
		if i < _weight_ia.size():
			(_weight_ia[i] as Dictionary)["pos"] = W(_cell_pos(c))
	_check_plates(false)


func _push_weight(i: int) -> void:
	var pw: Array = state["poids"]
	var c: Vector2i = _cell_of(pw[i])
	var wpos: Vector3 = W(_cell_pos(c))
	var from: Vector3 = wpos - _feet()
	var d := Vector2i(0, 0)
	if absf(from.x) > absf(from.z):
		d.x = 1 if from.x > 0.0 else -1
	else:
		d.y = 1 if from.z > 0.0 else -1
	var to: Vector2i = c + d
	var blocked: bool = to.x < 0 or to.y < 0 or to.x >= GRID_N.x or to.y >= GRID_N.y
	for pile in PILES:
		if pile == to:
			blocked = true
	for j in range(pw.size()):
		if j != i and _cell_of(pw[j]) == to:
			blocked = true
	if blocked:
		_say("Tu pousses de toutes tes forces… Le poids ne bouge pas : quelque chose le bloque de l'autre côté.", 3.5)
		return
	pw[i] = [to.x, to.y]
	var tw := create_tween()
	tw.tween_property(_weights[i], "global_position", W(_cell_pos(to)), 0.7).set_trans(Tween.TRANS_SINE)
	(_weight_ia[i] as Dictionary)["pos"] = W(_cell_pos(to))
	_sfx("pierre_glisse", W(_cell_pos(to)) + Vector3.UP)
	if randf() < 0.35:
		_say(["Une voix d'avare, dans le mur : « Pourquoi gardes-tu ? » Une autre lui répond : « Pourquoi dépenses-tu ? »", "« Mille talents ! » grince le poids. (C'est écrit dessus.)", "Les avares, dit-on, poussent ces poids depuis toujours. Toi, tu as un but : les dalles d'or."][randi() % 3], 4.0)
	await tw.finished
	_check_plates(true)


func _check_plates(announce: bool) -> void:
	var pw: Array = state["poids"]
	var n: int = 0
	for k in range(PLATES.size()):
		var on: bool = false
		for w in pw:
			if _cell_of(w) == PLATES[k]:
				on = true
		(_plates_mats[k] as StandardMaterial3D).emission_energy_multiplier = 2.2 if on else 0.2
		if on:
			n += 1
	if n == PLATES.size() and not bool(state["avares"]):
		state["avares"] = true
		if announce:
			_sfx("mecanisme", W(Vector3(74, 2, 120)))
			_say("Les deux poids sont sur les dalles d'or ! Un « clac » profond, quelque part dans les murs : la porte du sud s'enfonce dans le sol.", 7.0)
			await get_tree().create_timer(1.5).timeout
		open_gate("avares")


func _reset_weights() -> void:
	state["poids"] = [[WEIGHTS0[0].x, WEIGHTS0[0].y], [WEIGHTS0[1].x, WEIGHTS0[1].y]]
	_place_weights()
	_sfx("mecanisme", W(Vector3(70, 1.5, 106)))
	_say("Clac ! Un grondement, et les deux poids glissent jusqu'à leur place de départ.", 4.0)


# =================================================================== Géryon, Antée

func _ride_geryon() -> void:
	state["geryon"] = true
	_sfx("geryon_ailes", W(Vector3(22, 3, 180)))
	_say("Tu grimpes sur le dos de Géryon. « Accroche-toi bien », dit-il de sa voix de brave homme. Il déploie ses ailes, plonge dans le gouffre en larges cercles… et te dépose, tout en bas, au bord de Malebolge.", 8.0)
	await main.donjon_v35._travel(W(Vector3(-20.0, -12.0, 153.0)), Vector3(0, 0, 1))


func _antee() -> void:
	_sfx("titan_pas", W(Vector3(-20, -18, 203)))
	_say("Antée, le géant, te prend dans sa grande main de pierre, très doucement, comme un oiseau. « Le Cocyte est en bas. Il fait froid. Tu as pris un manteau, j'espère ? » Il te pose au fond du puits.", 8.0)
	await main.donjon_v35._travel(W(Vector3(-20.0, -24.0, 212.0)), Vector3(0, 0, 1))


# =================================================================== la Flamme Éternelle

func _titan_dead() -> void:
	state["boss"] = true
	_say("Le Titan de Givre vacille… se fige… et vole en mille éclats de glace ! Sur l'autel, au fond, une flamme d'or s'allume dans un pilier de cristal : la Flamme Éternelle.", 9.0)
	await get_tree().create_timer(2.0).timeout
	_flame.visible = true
	_flame.scale = Vector3.ONE * 0.1
	create_tween().tween_property(_flame, "scale", Vector3.ONE, 1.5)


func _take_flame() -> void:
	state["fini"] = true
	_flame.visible = false
	_reward("flamme_eternelle", "Vainqueur du Titan de Givre", 150, W(Vector3(-20.0, -21.0, 270.0)))
	main._show_message_v28("La Flamme Éternelle ! Elle ne brûle pas les doigts : elle réchauffe. 150 pièces, un cœur de plus, et un titre : « Vainqueur du Titan de Givre ». Rapporte-la au Cœur-Brasier, dans la Cathédrale-Forge !")


# =================================================================== chaque image

func _tick(delta: float, p: Vector3, r: String) -> void:
	var l: Vector3 = L(p)
	match r:
		"acheron", "rive":
			if l.y < -0.7 and l.z > 27.6 and l.z < 36.4 and _fall_cd <= 0.0:
				_fall_cd = 1.5
				_fall_back("Plouf ! L'Achéron est glacé… Charon te repêche avec sa rame, en soupirant : « Une obole, j'ai dit. Pas un plongeon. »", 1)
		"tourmente":
			_tick_wind(delta, l)
		"cerbere":
			if not bool(state["cerbere"]) and not fight and l.x > 63.0:
				_say("Trois grognements, trois paires d'yeux de braise… CERBÈRE, le chien à trois têtes, se lève de sa paille ! (On dit qu'il adore les gâteaux de miel. Un par tête.)", 8.0)
				_start_boss("cerbere", Vector3(76.0, 0, 92.0), "Cerbère", Callable(self, "_cerbere_dead"))
		"styx":
			_tick_slabs(delta, l)
			if not bool(state["dite"]) and not _furies and l.z > 156.5:
				_furies = true
				_say("Au sommet des murailles de Dité, trois silhouettes déploient leurs ailes : les FURIES ! « Personne n'entre à Dité ! » crient-elles en plongeant sur toi.", 7.0)
				for k in range(3):
					spawn_in("styx", "furie", Vector3(66.0 + k * 8.0, 0, 161.0))
			if _furies and not bool(state["dite"]) and room_spawned("styx") and room_alive("styx") == 0:
				state["dite"] = true
				_say("La dernière Furie s'enfuit en hurlant (« On reviendra ! On ne revient jamais. »). La grande porte de fer de Dité grince, rougeoie… et s'ouvre.", 7.0)
				open_gate("dite")
		"tombeaux":
			_tick_tombs(delta, l)
		"phlegethon":
			if l.y < -0.6 and l.x > 26.6 and l.x < 51.4 and _fall_cd <= 0.0:
				_fall_cd = 1.5
				_fall_back("Aïe aïe aïe ! La lave du Phlégéthon ! Tu remontes d'un bond sur la rive, les semelles fumantes. Prends un radeau, la prochaine fois.", 2)
		"cocyte":
			if not bool(state["boss"]) and not fight and l.z > 232.0:
				_say("La glace craque. Au fond du lac, quelque chose de très grand se lève : LE TITAN DE GIVRE, la couronne de cristaux, une massue d'eau gelée. Il serre la Flamme Éternelle dans sa cage de glace.", 8.0)
				_start_boss("titan_givre", Vector3(-20.0, -24.0, 256.0), "le Titan de Givre", Callable(self, "_titan_dead"))
			_tick_cold(delta)
	_tick_rafts()
	_tick_bridges()
	if _flame != null and _flame.visible:
		_flame.rotate_y(delta * 0.8)


func _tick_wind(delta: float, l: Vector3) -> void:
	_gust_t += delta
	if _gust_t > 5.0:
		_gust_t = 0.0
		_sfx("bourrasque", W(Vector3(36.0, 2.0, 92.0)))
	var gusting: bool = _gust_t > 1.6 and _gust_t < 3.2
	_gust.emitting = _gust_t > 1.4 and _gust_t < 3.2
	if gusting and l.y > -1.0:
		var sheltered: bool = false
		for x in [21.0, 31.0, 41.0, 51.0]:
			if absf(l.x - x) < 1.3 and l.z > 88.6:
				sheltered = true
		if l.x < 13.5 or l.x > 58.5:
			sheltered = true
		if not sheltered:
			push_player(Vector3(0, 0, -2.6 * delta))
	if l.y < -3.0 and _fall_cd <= 0.0:
		_fall_cd = 1.5
		_fall_back("La rafale t'a emporté dans le gouffre ! Tu te réveilles au début du couloir, un peu roussi. Attends derrière un pilier que le vent tombe, puis cours.", 1)


func _tick_slabs(delta: float, l: Vector3) -> void:
	for s in _slabs:
		var sb: Node3D = s[0]
		var c: int = s[1]
		var r: int = s[2]
		var k: String = "%d,%d" % [c, r]
		var on: bool = absf(l.x - SLAB_X[c]) < 1.45 and absf(l.z - SLAB_Z[r]) < 1.45 and l.y > -0.5 and l.y < 1.0
		if int(SLAB_OK[r]) == c:
			continue
		if on and not _slab_t.has(k):
			_slab_t[k] = 0.0
			_sfx("lave_bulles", sb.global_position)
		if _slab_t.has(k):
			_slab_t[k] = float(_slab_t[k]) + delta
			var t: float = float(_slab_t[k])
			if t > 0.5 and t < 1.5:
				sb.global_position = W(Vector3(SLAB_X[c], -1.8 * (t - 0.5), SLAB_Z[r]))
			elif t >= 4.0:
				sb.global_position = W(Vector3(SLAB_X[c], 0.0, SLAB_Z[r]))
				_slab_t.erase(k)
	if l.y < -0.9 and l.z > 132.0 and l.z < 156.0 and _fall_cd <= 0.0:
		_fall_cd = 1.5
		_fall_back("Splotch ! Tu t'enfonces dans la boue du Styx… et tu en ressors, gluant, sur la rive. Les dalles qui bouillonnent ne tiennent pas !", 1)


func _tick_tombs(delta: float, l: Vector3) -> void:
	_tomb_t += delta
	_tomb_cd = maxf(_tomb_cd - delta, 0.0)
	for r in range(TOMB_ROWS.size()):
		var ph: float = fmod(_tomb_t + float(r) * 1.3, 4.0)
		var flare: bool = ph < 1.6
		for f in _tomb_fires[r]:
			(f as CPUParticles3D).emitting = flare
		(_tomb_lights[r] as OmniLight3D).light_energy = 2.2 if flare else 0.3
		if flare and absf(l.z - TOMB_ROWS[r]) < 1.3 and l.x > 61.0 and l.x < 87.0 and l.y < 2.0 and _tomb_cd <= 0.0:
			_tomb_cd = 1.2
			_hurt(1, W(Vector3(l.x, 1.0, TOMB_ROWS[r])))
			push_player(Vector3(0, 0, -1.6 if l.z < TOMB_ROWS[r] else 1.6))
			_once("tombeaux_aie", "Ouille ! Les tombeaux crachent leurs flammes, une rangée après l'autre. Regarde-les faire, et passe quand ta rangée s'éteint.", 5.0)


func _tick_rafts() -> void:
	if _rafts.is_empty():
		return
	for i in range(_rafts.size()):
		var t: float = fmod(_clock + float(i) * 5.5, 22.0)
		var x: float
		if t < 3.0:
			x = 49.4
		elif t < 11.0:
			x = lerpf(49.4, 28.6, smoothstep(0.0, 1.0, (t - 3.0) / 8.0))
		elif t < 14.0:
			x = 28.6
		else:
			x = lerpf(28.6, 49.4, smoothstep(0.0, 1.0, (t - 14.0) / 8.0))
		(_rafts[i] as Node3D).global_position = W(Vector3(x, 0.0, RAFT_Z[i]))


func _tick_bridges() -> void:
	if _bridges.is_empty():
		return
	for i in range(_bridges.size()):
		var t: float = fmod(_clock + float(i) * 2.3, 9.0)
		var a: float
		if t < 4.0:
			a = 0.0
		elif t < 5.0:
			a = smoothstep(0.0, 1.0, t - 4.0) * PI * 0.5
		elif t < 8.0:
			a = PI * 0.5
		else:
			a = (1.0 - smoothstep(0.0, 1.0, t - 8.0)) * PI * 0.5
		(_bridges[i] as Node3D).global_transform = Transform3D(Basis(Vector3.UP, a), W(Vector3(-20.0, -12.0, DITCH_Z[i])))


func _tick_cold(delta: float) -> void:
	if bool(state["manteau"]) or bool(state["fini"]):
		return
	_cold_t += delta
	if _cold_t > 14.0:
		_cold_t = 0.0
		_hurt(1, _feet() + Vector3(0, 1.0, 0.5))
		_say("Brrr ! Le froid du Cocyte te mord les doigts. Un manteau, au Vestibule… l'inscription l'avait bien dit.", 4.0)


## La lueur de chaque cercle (donjon_v35 pose celle des braises en entrant) : le froid bleu en bas.
func _mood(r: String) -> void:
	if not bool(main.donjon_v35.get("inside")):
		return
	for c in main.get_children():
		if c is WorldEnvironment:
			var env: Environment = (c as WorldEnvironment).environment
			if r in ["puits", "cocyte"]:
				env.ambient_light_color = Color(0.4, 0.5, 0.66)
				env.ambient_light_energy = 0.9
				env.fog_light_color = Color(0.03, 0.04, 0.06)
				env.tonemap_exposure = 1.25
			else:
				env.ambient_light_color = Color(0.62, 0.46, 0.38)
				env.ambient_light_energy = 1.5
				env.fog_light_color = Color(0.06, 0.035, 0.03)
				env.tonemap_exposure = 1.45
			return


func _enter_room(_old: String, r: String) -> void:
	_mood(r)
	match r:
		"acheron":
			_once("acheron", "L'Achéron, une rivière d'eau noire et froide. Sur la rive, une barque, et dedans, une grande silhouette encapuchonnée aux yeux d'or : Charon, le passeur.", 7.0)
		"limbes":
			if not bool(state["limbes"]):
				_once("limbes", "Les Limbes, le Premier Cercle. Des ombres glissent entre les colonnes. Un sage de pierre tient une lumière d'or ; trois miroirs de bronze, un cristal éteint, et une porte fermée.", 8.0)
		"minos":
			if not bool(state["minos"]):
				_once("minos", "Le Deuxième Cercle. Sur un trône de bronze, MINOS, le juge des enfers, couronné, sa longue queue enroulée autour de lui. Il attend que tu te présentes.", 7.0)
		"tourmente":
			_once("tourmente", "La Tourmente : un couloir au bord d'un gouffre de feu, et un vent qui ne s'arrête jamais de souffler, par rafales. Les piliers, contre le mur, font de bons abris.", 7.0)
		"avares":
			if not bool(state["avares"]):
				_once("avares", "Le Quatrième Cercle, celui des Avares. Deux poids énormes, des tas d'or, deux dalles dorées dans le sol. Pousse les poids (en te plaçant derrière) jusqu'aux dalles. Le levier, près de l'entrée, remet tout en place.", 9.0)
		"styx":
			if not bool(state["dite"]):
				_once("styx", "Le Styx, un marais de boue tiède. Des dalles de basalte forment un chemin… mais certaines bouillonnent. Au fond, les murailles rouges de Dité.", 7.0)
		"tombeaux":
			_once("tombeaux", "Le Sixième Cercle : des rangées de tombeaux ouverts, d'où jaillissent des flammes, chacune à son tour.", 6.0)
		"phlegethon":
			_once("phlegethon", "Le Phlégéthon, une rivière de lave bouillante. Des radeaux de basalte la traversent tout seuls, sans se presser. Sur l'autre rive, une bête énorme à visage d'homme attend : Géryon.", 8.0)
		"malebolge":
			_once("malebolge", "Malebolge, le Huitième Cercle : trois fossés de feu, trois ponts de fer qui tournent. Et des diablotins, les Malebranches, qui ricanent en t'attendant.", 7.0)
		"puits":
			_once("puits", "Le Puits des Géants. Tout en bas, la glace. Autour, des géants de pierre, enchaînés. L'un d'eux, Antée, n'a pas de chaînes : il tend la main vers le palier.", 7.0)
		"cocyte":
			_once("cocyte", "Le Cocyte, le lac gelé, le Neuvième et dernier Cercle. Il neige, sous la terre. Tout au fond, un trône de glace.", 6.0)


func _on_enter(first: bool) -> void:
	if first:
		_say("Tu descends l'escalier de la Cathédrale-Forge. L'air fraîchit à chaque marche… En bas, une porte, et une inscription en lettres de feu.", 7.0)
	else:
		_say("Les Neuf Cercles.", 3.0)


func _fall_text(_r: String) -> String:
	return "Tu tombes… et tu te retrouves, étourdi, à l'entrée de la salle."


func _faint_text() -> String:
	return "Un petit diablotin te tapote la joue : « Debout ! Les cercles ne vont pas se descendre tout seuls. »"


func _on_reset() -> void:
	_furies = false
	_slab_t.clear()
	for s in _slabs:
		(s[0] as Node3D).global_position = W(Vector3(SLAB_X[int(s[1])], 0.0, SLAB_Z[int(s[2])]))
	_q.clear()
	_qi = 0
