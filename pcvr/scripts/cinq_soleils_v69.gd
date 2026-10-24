extends "res://scripts/enigmes_v69.gd"
## V69 : les Cinq Soleils, sous le Grand Temple d'Aztlán (les Aztèques) — la légende des soleils :
## quatre mondes ont été détruits avant le nôtre (par les jaguars, par le vent, par une pluie de
## feu, par l'eau) ; le cinquième soleil est né quand l'humble Nanahuatzin s'est jeté dans le
## grand feu de Teotihuacan, et il ne s'est mis en mouvement qu'au souffle d'Ehécatl, le vent.
## Dehors, au sommet du temple : une jarre de pluie pour Tlaloc, du copal pour Huitzilopochtli ;
## la dalle ronde entre les deux sanctuaires s'ouvre. Dedans :
##  1. la descente (Tlaloc et Huitzilopochtli peints aux murs) ;
##  2. la salle de la Pierre du Soleil : quatre niches ; y poser les quatre glyphes dans l'ordre
##     des soleils (le codex de l'entrée le montre) ;
##  3. les quatre salles des soleils, dans l'ordre qu'on veut : le Soleil des Jaguars (un combat) ;
##     le Soleil du Vent (des passerelles sur le vide, des rafales — et la conque d'Ehécatl) ; le
##     Soleil de Pluie de feu (traverser sous les pierres de feu) ; le Soleil de l'Eau (ouvrir les
##     vannes : l'eau monte, les chinampas aussi) ;
##  4. le Cinquième Soleil : l'offrande humble de Nanahuatzin, puis le souffle de la conque ;
##  5. Cipactli, le monstre de la Terre. Récompense : la Plume de Quetzalcóatl.

const T := 1.0
const GLYPHS := ["glyphe_jaguar", "glyphe_vent", "glyphe_feu", "glyphe_eau"]
const GLYPH_SYM := {"glyphe_jaguar": "sym69_soleil_jaguar", "glyphe_vent": "sym69_soleil_vent", "glyphe_feu": "sym69_soleil_feu", "glyphe_eau": "sym69_soleil_eau"}
const GLYPH_NAME := {"glyphe_jaguar": "le Jaguar", "glyphe_vent": "le Vent", "glyphe_feu": "la Pluie de feu", "glyphe_eau": "l'Eau"}
const NICHE_X := [-7.5, -4.5, 4.5, 7.5]
## le Vent : les passerelles [x0, z0, x1, z1] (les tronçons « z » sont à l'abri des rafales)
const WALKS := [[-18.0, 40.0, -28.0, 40.0], [-28.0, 40.0, -28.0, 36.0], [-28.0, 36.0, -40.0, 36.0], [-40.0, 36.0, -40.0, 44.0],
	[-40.0, 44.0, -50.0, 44.0], [-50.0, 44.0, -50.0, 40.0], [-50.0, 40.0, -55.1, 40.0]]
const FIRE_SAFE := [[4, 2], [4, 3], [8, 5], [8, 6]]
const RAFT_X := [22.5, 26.0, 29.5, 33.0, 36.5]
const WATER_Y := [-3.0, -2.0, -1.0, 0.0]

var _niche_quads: Array = []
var _stone_light: OmniLight3D
var _gust_t: float = 0.0
var _gust_dir: float = 1.0
var _dust: CPUParticles3D
var _fire_marks: Dictionary = {}               # "c,r" -> MeshInstance3D
var _fire_t: float = 0.0
var _fire_on: Array = []
var _fire_hit_cd: float = 0.0
var _rafts: Array = []
var _water: MeshInstance3D
var _wheels: Array = []
var _sun: Node3D
var _sun_mat: StandardMaterial3D
var _feather: Node3D
var _big_fire: CPUParticles3D
var _slab: MeshInstance3D
var _hole: MeshInstance3D
var _pending_niche: int = -1


func _init() -> void:
	key = "azteque"
	titre = "les Cinq Soleils"
	O = Vector3(-1070.0, -130.0, -40.0)
	bbox = AABB(Vector3(-70.0, -12.0, -4.0), Vector3(130.0, 40.0, 130.0))
	room_spawns = {
		"pierre": [["jaguar_pierre", -9.0, 0.0, 31.0], ["jaguar_pierre", 9.0, 0.0, 31.0]],
		"jaguars": [["jaguar", -30.0, 0.0, 20.0], ["jaguar", -32.0, 0.0, 28.0], ["jaguar", -26.0, 0.0, 24.0], ["jaguar_pierre", -34.0, 0.0, 24.0]],
	}


func _defaults() -> Dictionary:
	return {"tlaloc": false, "huitzi": false, "ouvert": false, "niches": ["", "", "", ""], "pierre": false, "jaguars": false,
		"vannes": [false, false, false], "offrande": false, "soleil": false}


func entry() -> Array:
	return [W(Vector3(0, 0, 3.5)), Vector3(0, 0, 1)]


func exit_point() -> Array:
	return [sol.azteque.temple_gate + Vector3(-1.8, 0.1, 0), Vector3(-1, 0, 0)]


# =================================================================== construction

func _build() -> void:
	add_room("descente", Vector3(-6, 0, 0), Vector3(6, 8, 14), Vector3(0, 0, 3.5), Vector3(0, 0, 1), ["pierre"])
	add_room("pierre", Vector3(-16, 0, 16), Vector3(16, 12, 48), Vector3(0, 0, 17.8), Vector3(0, 0, 1), ["descente", "jaguars", "vent", "feu", "eau", "cinquieme"])
	add_room("jaguars", Vector3(-38, 0, 16), Vector3(-18, 8, 32), Vector3(-19.8, 0, 24.0), Vector3(-1, 0, 0), ["pierre"])
	add_room("vent", Vector3(-62, -6, 34), Vector3(-18, 9, 46), Vector3(-19.0, 0, 40.0), Vector3(-1, 0, 0), ["pierre"])
	add_room("feu", Vector3(18, 0, 16), Vector3(44, 8, 32), Vector3(18.8, 0, 24.0), Vector3(1, 0, 0), ["pierre"])
	add_room("eau", Vector3(18, -4, 34), Vector3(46, 9, 46), Vector3(19.4, 0, 40.0), Vector3(1, 0, 0), ["pierre"])
	add_room("cinquieme", Vector3(-14, 0, 50), Vector3(14, 12, 78), Vector3(0, 0, 51.8), Vector3(0, 0, 1), ["pierre", "cipactli"])
	add_room("cipactli", Vector3(-20, 0, 80), Vector3(20, 14, 120), Vector3(0, 0, 81.8), Vector3(0, 0, 1), ["cinquieme"])
	_build_descente()
	_build_pierre()
	_build_jaguars()
	_build_vent()
	_build_feu()
	_build_eau()
	_build_cinquieme()
	_build_cipactli()
	kit.commit()


func _xf() -> Transform3D:
	return Transform3D(Basis(), O)


func _torch(n: String, l: Vector3, facing: Vector3, energy: float = 1.5) -> void:
	kit.torch(rooms[n]["root"], W(l), facing, energy)


func _build_descente() -> void:
	_in_room("descente")
	kit.room(_xf(), -6, 6, 0, 14, 0, 8, "tezo69", "dalles69", [["s", 0, 3.2, 4.2]], "tezo69", T)
	kit.ramp(_xf(), Vector3(0, 0, 2.6), Vector3(0, 3.0, -0.2), 3.0, "tezo69", "enduit69_rouge")
	kit.solid(X(Vector3(0, 1.5, -0.6)), Vector3(3.6, 3.0, 0.8), "tezo69")
	kit.quadz(X(Vector3(0, 4.2, 0.02)), 3.0, 2.2, "noir69")
	kit.panel(X(Vector3(-5.95, 3.6, 7.0), PI * 0.5), 6.0, 3.0, "fresque69_tlaloc", "enduit69_bleu")
	kit.panel(X(Vector3(5.95, 3.6, 7.0), -PI * 0.5), 6.0, 3.0, "fresque69_huitzilopochtli", "enduit69_rouge")
	_torch("descente", Vector3(-5.85, 2.4, 3.0), Vector3(1, 0, 0))
	_torch("descente", Vector3(5.85, 2.4, 3.0), Vector3(-1, 0, 0))
	_torch("descente", Vector3(-5.85, 2.4, 11.0), Vector3(1, 0, 0))
	_torch("descente", Vector3(5.85, 2.4, 11.0), Vector3(-1, 0, 0))


func _build_pierre() -> void:
	_in_room("pierre")
	kit.room(_xf(), -16, 16, 16, 48, 0, 12, "frise69", "dalles69",
		[["n", 0, 3.2, 4.2], ["w", 24, 3.0, 4.0], ["w", 40, 3.0, 4.0], ["e", 24, 3.0, 4.0], ["e", 40, 3.0, 4.0], ["s", 0, 3.2, 4.2]], "tezo69", T)
	gate("cinquieme", "pierre", Vector3(0, 0, 49.0), 3.4, 4.3, 0.6, 0.0, "tezo69", "sym69_ollin")
	# la Pierre du Soleil, immense, au-dessus de la porte du sud ; ses quatre niches dessous
	kit.cyl(X(Vector3(0, 8.0, 47.7), 0.0) * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO), 4.0, 4.0, 0.6, "tezo69", 40)
	kit.quad(X(Vector3(0, 8.0, 47.05), 0.0), 7.8, 7.8, "psoleil69")
	_stone_light = kit.glow_light(rooms["pierre"]["root"], W(Vector3(0, 8.0, 44.0)), Color(1.0, 0.75, 0.35), 0.0, 14.0)
	_niche_quads.clear()
	for i in range(4):
		var x: float = NICHE_X[i]
		kit.box(X(Vector3(x, 1.6, 47.55)), Vector3(1.6, 1.6, 0.9), "tezo69", 1.0)
		kit.quad(X(Vector3(x, 1.6, 47.08)), 1.0, 1.0, "noir69")
		# le nombre (des points) au-dessus de chaque niche
		kit.quad(X(Vector3(x, 2.75, 47.06)), 0.6, 0.6, "sym69_num_%d" % (i + 1))
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.95, 0.95)
		q.mesh = qm
		q.rotation.y = PI
		(rooms["pierre"]["root"] as Node3D).add_child(q)
		q.global_position = W(Vector3(x, 1.6, 47.05))
		q.visible = false
		_niche_quads.append(q)
		kit.col_box(X(Vector3(x, 1.6, 47.55)), Vector3(1.6, 1.6, 0.9))
	# le codex des soleils, à l'entrée
	kit.panel(X(Vector3(-7.0, 3.4, 16.05), 0.0), 4.4, 4.4, "codex69_soleils", "enduit69_blanc")
	kit.panel(X(Vector3(7.0, 3.4, 16.05), 0.0), 6.0, 3.0, "fresque69_nanahuatzin", "enduit69_rouge")
	# les quatre portes des soleils : leur signe au-dessus
	for d in [[-15.9, 24.0, PI * 0.5, "sym69_soleil_jaguar"], [-15.9, 40.0, PI * 0.5, "sym69_soleil_vent"], [15.9, 24.0, -PI * 0.5, "sym69_soleil_feu"], [15.9, 40.0, -PI * 0.5, "sym69_soleil_eau"]]:
		kit.quadz(X(Vector3(float(d[0]), 5.0, float(d[1])), float(d[2])), 1.6, 1.6, str(d[3]))
	for p in [Vector3(-9.0, 0, 22.0), Vector3(9.0, 0, 22.0), Vector3(-9.0, 0, 42.0), Vector3(9.0, 0, 42.0)]:
		kit.column(X(p), 0.8, 12.0, "frise69", "tezo69")
	for z in [20.0, 32.0, 44.0]:
		_torch("pierre", Vector3(-15.85, 3.0, z), Vector3(1, 0, 0))
		_torch("pierre", Vector3(15.85, 3.0, z), Vector3(-1, 0, 0))
	kit.brazier63(rooms["pierre"]["root"], W(Vector3(-4.0, 0, 38.0)), true, "bronze69", 2.2, "tezo69")
	kit.brazier63(rooms["pierre"]["root"], W(Vector3(4.0, 0, 38.0)), true, "bronze69", 2.2, "tezo69")
	# deux torches hautes de part et d'autre de la Pierre : on la lit même éteinte
	_torch("pierre", Vector3(-6.0, 9.5, 46.8), Vector3(0, 0, -1), 1.8)
	_torch("pierre", Vector3(6.0, 9.5, 46.8), Vector3(0, 0, -1), 1.8)


func _build_jaguars() -> void:
	_in_room("jaguars")
	kit.room(_xf(), -38, -18, 16, 32, 0, 8, "tezo69", "dalles69", [["e", 24, 3.0, 4.0]], "tezo69", T)
	kit.panel(X(Vector3(-37.95, 4.0, 24.0), PI * 0.5), 3.0, 3.0, "sym69_soleil_jaguar", "tezo69")
	kit.solid(X(Vector3(-35.6, 0.5, 24.0)), Vector3(1.6, 1.0, 2.6), "tezo69")
	for p in [Vector3(-24.0, 0, 19.0), Vector3(-24.0, 0, 29.0), Vector3(-32.0, 0, 19.0), Vector3(-32.0, 0, 29.0)]:
		kit.column(X(p), 0.6, 8.0, "frise69", "tezo69")
	_torch("jaguars", Vector3(-28.0, 2.8, 16.15), Vector3(0, 0, 1))
	_torch("jaguars", Vector3(-28.0, 2.8, 31.85), Vector3(0, 0, -1))
	_torch("jaguars", Vector3(-37.85, 2.8, 19.0), Vector3(1, 0, 0))
	_torch("jaguars", Vector3(-37.85, 2.8, 29.0), Vector3(1, 0, 0))
	var me = self
	chest("jaguar", "jaguars", Vector3(-35.6, 1.0, 24.0), PI * 0.5, [["glyphe_jaguar", 1]],
		"Sur l'autel du Soleil des Jaguars : une tablette gravée d'une tête de jaguar et de quatre points. Le premier soleil, celui que les jaguars dévorèrent.",
		func(): return me.room_spawned("jaguars") and me.room_alive("jaguars") == 0)


func _build_vent() -> void:
	_in_room("vent")
	kit.room(_xf(), -62, -18, 34, 46, -6, 15, "tezo69", "roche69", [["e", 40, 3.0, 10.0]], "tezo69", T)
	# le seuil (l'épaisseur du mur, sous la porte)
	kit.solid(X(Vector3(-17.5, -0.25, 40.0)), Vector3(1.0, 0.5, 3.0), "tezo69", 1.5)
	for wi in range(WALKS.size()):
		var w: Array = WALKS[wi]
		var a := Vector3(float(w[0]), 0, float(w[1]))
		var b := Vector3(float(w[2]), 0, float(w[3]))
		var dir: Vector3 = (b - a).normalized()
		# chaque tronçon porte le coude où il arrive ; le coude d'où il part est à son voisin
		var s0: Vector3 = a if wi == 0 else a + dir * 0.9
		var s1: Vector3 = b + dir * 0.9
		var c: Vector3 = (s0 + s1) * 0.5
		var along_x: bool = absf(dir.x) > 0.5
		var ln: float = s0.distance_to(s1)
		var size := Vector3(ln if along_x else 1.8, 0.5, 1.8 if along_x else ln)
		kit.solid(X(c + Vector3(0, -0.25, 0)), size, "tezo69", 1.5)
		# une piles de pierre sous chaque coude
		kit.box(X(b + Vector3(0, -3.25, 0)), Vector3(1.4, 5.5, 1.4), "tezo69", 1.5)
	# la plate-forme d'Ehécatl, au bout
	kit.solid(X(Vector3(-59.0, -3.0, 40.0)), Vector3(6.0, 6.0, 12.0), "tezo69", 2.0)
	kit.solid(X(Vector3(-60.4, 0.5, 40.0)), Vector3(1.6, 1.0, 2.6), "tezo69")
	# Ehécatl, le dieu du vent : une statue au masque à bec, contre le mur
	kit.box(X(Vector3(-61.4, 1.6, 40.0)), Vector3(0.8, 3.2, 1.2), "tezo69", 1.0)
	kit.box(X(Vector3(-61.0, 3.5, 40.0)), Vector3(0.7, 0.7, 0.7), "enduit69_rouge", 1.0)
	kit.box(X(Vector3(-60.5, 3.4, 40.0)), Vector3(0.5, 0.25, 0.3), "enduit69_noir", 1.0)
	kit.panel(X(Vector3(-61.95, 6.0, 40.0), PI * 0.5), 3.0, 3.0, "sym69_soleil_vent", "tezo69")
	# la poussière que soulève le vent
	_dust = CPUParticles3D.new()
	_dust.amount = 120
	_dust.lifetime = 1.6
	_dust.emitting = false
	_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_dust.emission_box_extents = Vector3(22.0, 3.0, 1.0)
	_dust.direction = Vector3(0, 0, 1)
	_dust.spread = 8.0
	_dust.initial_velocity_min = 7.0
	_dust.initial_velocity_max = 11.0
	_dust.gravity = Vector3.ZERO
	_dust.scale_amount_min = 0.3
	_dust.scale_amount_max = 0.9
	var qm := QuadMesh.new()
	qm.size = Vector2(0.3, 0.3)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.75, 0.68, 0.58, 0.35)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	if main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	qm.material = m
	_dust.mesh = qm
	(rooms["vent"]["root"] as Node3D).add_child(_dust)
	_dust.global_position = W(Vector3(-40.0, 1.5, 40.0))
	for x in [-24.0, -36.0, -48.0]:
		_torch("vent", Vector3(x, 3.4, 34.15), Vector3(0, 0, 1), 2.0)
		_torch("vent", Vector3(x, 3.4, 45.85), Vector3(0, 0, -1), 2.0)
	_torch("vent", Vector3(-61.85, 2.8, 36.0), Vector3(1, 0, 0), 1.3)
	_torch("vent", Vector3(-61.85, 2.8, 44.0), Vector3(1, 0, 0), 1.3)
	chest("vent", "vent", Vector3(-60.4, 1.0, 40.0), PI * 0.5, [["glyphe_vent", 1], ["conque", 1]],
		"Aux pieds d'Ehécatl : la tablette du Soleil du Vent… et une grande conque rose, la conque du dieu. Quand on souffle dedans, le vent se lève.")


func _build_feu() -> void:
	_in_room("feu")
	kit.room(_xf(), 18, 44, 16, 32, 0, 8, "tezo69", "dalles69_sombre", [["w", 24, 3.0, 4.0]], "tezo69", T)
	# les abris de pierre (des dalles sur deux piliers), la sortie, l'autel du glyphe
	for s in [[4, 2.5], [8, 5.5]]:
		var c := Vector3(19.0 + 2.0 * float(s[0]), 0, 17.0 + 2.0 * float(s[1]))
		for dx in [-1.6, 1.6]:
			kit.solid(X(c + Vector3(dx, 1.25, 0)), Vector3(0.5, 2.5, 0.5), "tezo69", 1.0)
		kit.solid(X(c + Vector3(0, 2.65, 0)), Vector3(4.0, 0.3, 4.4), "tezo69", 1.0)
	kit.solid(X(Vector3(42.6, 0.5, 24.0)), Vector3(1.6, 1.0, 2.6), "tezo69")
	kit.panel(X(Vector3(43.95, 4.0, 24.0), -PI * 0.5), 3.0, 3.0, "sym69_soleil_feu", "tezo69")
	# la braise rouge des fissures du plafond
	for k in range(3):
		kit.glow_light(rooms["feu"]["root"], W(Vector3(23.0 + k * 8.0, 7.2, 24.0)), Color(1.0, 0.4, 0.15), 1.6, 14.0)
	# les marques au sol (là où le feu va tomber)
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(1.0, 0.45, 0.15, 0.85)
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if main.has_method("_soft_dot_v24"):
		mm.albedo_texture = main._soft_dot_v24()
	_fire_marks.clear()
	for c2 in range(13):
		for r in range(8):
			var q := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(2.2, 2.2)
			q.mesh = qm
			q.material_override = mm
			q.rotation.x = -PI * 0.5
			q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			(rooms["feu"]["root"] as Node3D).add_child(q)
			q.global_position = W(Vector3(19.0 + 2.0 * c2, 0.04, 17.0 + 2.0 * r))
			q.visible = false
			_fire_marks["%d,%d" % [c2, r]] = q
	for z in [18.0, 30.0]:
		_torch("feu", Vector3(18.15, 2.6, z), Vector3(1, 0, 0), 2.0)
		_torch("feu", Vector3(43.85, 2.6, z), Vector3(-1, 0, 0), 2.0)
	for x3 in [26.0, 36.0]:
		_torch("feu", Vector3(x3, 3.0, 16.15), Vector3(0, 0, 1), 1.6)
		_torch("feu", Vector3(x3, 3.0, 31.85), Vector3(0, 0, -1), 1.6)
	chest("feu", "feu", Vector3(42.6, 1.0, 24.0), -PI * 0.5, [["glyphe_feu", 1]],
		"Sur l'autel, sous la pluie de feu : la tablette du Soleil de Pluie de feu, encore chaude.")


func _build_eau() -> void:
	_in_room("eau")
	kit.room(_xf(), 18, 46, 34, 46, -4, 13, "tezo69", "tezo69_sombre", [["w", 40, 3.0, 8.0]], "tezo69", T)
	# le rebord d'entrée, la rive du fond (et sa rampe vers la corniche haute)
	kit.solid(X(Vector3(19.0, -2.0, 40.0)), Vector3(4.0, 4.0, 12.0 + 2.0 * T), "tezo69", 2.0)
	kit.solid(X(Vector3(42.5, -2.0, 40.0)), Vector3(7.0, 4.0, 12.0 + 2.0 * T), "tezo69", 2.0)
	kit.solid(X(Vector3(43.0, 1.25, 42.0)), Vector3(6.0, 2.5, 8.0), "tezo69", 2.0)
	kit.ramp(_xf(), Vector3(39.4, 0.0, 36.0), Vector3(43.8, 2.5, 36.0), 2.4, "tezo69", "enduit69_bleu")
	kit.solid(X(Vector3(45.0, 1.25, 36.4)), Vector3(2.0, 2.5, 3.2), "tezo69")
	kit.panel(X(Vector3(45.95, 5.5, 42.0), -PI * 0.5), 3.0, 3.0, "sym69_soleil_eau", "tezo69")
	# l'eau
	_water = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(18.0, 12.0)
	_water.mesh = pm
	_water.material_override = kit.mat("eau69")
	(rooms["eau"]["root"] as Node3D).add_child(_water)
	_water.global_position = W(Vector3(30.0, WATER_Y[0], 40.0))
	# les chinampas flottantes (des radeaux de roseaux et de terre, couverts de fleurs)
	_rafts.clear()
	for x in RAFT_X:
		var r := AnimatableBody3D.new()
		r.sync_to_physics = true
		(rooms["eau"]["root"] as Node3D).add_child(r)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(2.6, 0.5, 2.6)
		mi.mesh = bm
		mi.material_override = kit.mat("palme69")
		mi.position = Vector3(0, -0.25, 0)
		r.add_child(mi)
		var top := MeshInstance3D.new()
		var tb := BoxMesh.new()
		tb.size = Vector3(2.3, 0.08, 2.3)
		top.mesh = tb
		top.material_override = kit.mat("herbe69")
		top.position = Vector3(0, 0.02, 0)
		r.add_child(top)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(2.6, 0.5, 2.6)
		cs.shape = sh
		cs.position = Vector3(0, -0.25, 0)
		r.add_child(cs)
		r.global_position = W(Vector3(x, WATER_Y[0] + 0.1, 40.0))
		_rafts.append(r)
	# les trois vannes (des roues de bronze aux murs)
	_wheels.clear()
	for p in [[Vector3(20.4, 1.4, 34.15), 0.0], [Vector3(20.4, 1.4, 45.85), PI], [Vector3(17.15, 1.4, 36.4), PI * 0.5]]:
		var w := Node3D.new()
		(rooms["eau"]["root"] as Node3D).add_child(w)
		w.global_transform = X(p[0], float(p[1]))
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.45
		tm.outer_radius = 0.55
		ring.mesh = tm
		ring.material_override = kit.mat("bronze69")
		ring.rotation.x = PI * 0.5
		ring.position = Vector3(0, 0, 0.3)
		w.add_child(ring)
		for k in range(3):
			var sp := MeshInstance3D.new()
			var sb := BoxMesh.new()
			sb.size = Vector3(1.0, 0.06, 0.06)
			sp.mesh = sb
			sp.material_override = kit.mat("bronze69")
			sp.rotation.z = PI * k / 3.0
			sp.position = Vector3(0, 0, 0.3)
			w.add_child(sp)
		_wheels.append(w)
	_torch("eau", Vector3(18.15, 2.6, 36.0), Vector3(1, 0, 0), 2.0)
	for x2 in [22.0, 30.0, 38.0]:
		_torch("eau", Vector3(x2, 3.4, 34.15), Vector3(0, 0, 1), 2.0)
		_torch("eau", Vector3(x2, 3.4, 45.85), Vector3(0, 0, -1), 2.0)
	kit.glow_light(rooms["eau"]["root"], W(Vector3(43.0, 4.0, 42.0)), Color(0.4, 0.7, 1.0), 1.4, 10.0)
	kit.glow_light(rooms["eau"]["root"], W(Vector3(30.0, 5.0, 40.0)), Color(0.5, 0.75, 1.0), 0.7, 18.0)
	chest("eau", "eau", Vector3(44.0, 2.5, 43.0), -PI * 0.5, [["glyphe_eau", 1]],
		"Sur la corniche, au sec : la tablette du Soleil de l'Eau, gravée de vagues. Le soleil du grand déluge.")


func _build_cinquieme() -> void:
	_in_room("cinquieme")
	kit.room(_xf(), -14, 14, 50, 78, 0, 12, "frise69", "dalles69", [["n", 0, 3.2, 4.2], ["s", 0, 3.2, 4.2]], "tezo69", T)
	gate("cipactli", "cinquieme", Vector3(0, 0, 79.0), 3.4, 4.3, 0.6, 0.0, "tezo69", "sym69_ollin")
	# le grand feu de Teotihuacan, dans sa margelle
	kit.ring(X(Vector3(0, 0, 64.0)), 2.6, 3.3, 0.8, "tezo69", 36)
	kit.col_cyl(W(Vector3(0, 0, 64.0)), 3.3, 0.8)
	kit.disc(X(Vector3(0, 0.3, 64.0)), 2.6, "noir69", 24)
	_big_fire = kit.fire(rooms["cinquieme"]["root"], W(Vector3(0, 0.6, 64.0)), 1.2, 90)
	_big_fire.global_position = W(Vector3(0, 0.6, 64.0))
	kit.glow_light(rooms["cinquieme"]["root"], W(Vector3(0, 2.5, 64.0)), Color(1.0, 0.55, 0.2), 2.6, 16.0)
	# l'autel de Tecciztécatl (l'or, le jade, les plumes) et celui de Nanahuatzin (des roseaux, des épines)
	kit.solid(X(Vector3(-8.5, 0.5, 64.0)), Vector3(2.0, 1.0, 3.0), "tezo69")
	kit.box(X(Vector3(-8.5, 1.2, 63.4)), Vector3(0.6, 0.4, 0.6), "or69", 1.0)
	kit.box(X(Vector3(-8.5, 1.15, 64.4)), Vector3(0.5, 0.3, 0.5), "jade69", 1.0)
	for k in range(4):
		kit.box(X(Vector3(-8.9 + k * 0.25, 1.4, 64.9), 0.2 * k), Vector3(0.06, 0.8, 0.03), "plume69", 1.0)
	kit.solid(X(Vector3(8.5, 0.5, 64.0)), Vector3(2.0, 1.0, 3.0), "tezo69")
	for k2 in range(5):
		kit.cyl(X(Vector3(9.1, 1.04, 63.2 + k2 * 0.12)) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.04, 0.04, 1.2, "palme69", 6)
	kit.box(X(Vector3(8.5, 1.08, 64.6)), Vector3(0.5, 0.16, 0.4), "lin69", 1.0)
	# le soleil (caché dans le feu) qui se lèvera
	_sun = Node3D.new()
	_sun.name = "Cinquieme_Soleil"
	(rooms["cinquieme"]["root"] as Node3D).add_child(_sun)
	_sun_mat = StandardMaterial3D.new()
	_sun_mat.albedo_color = Color(1.0, 0.7, 0.25)
	_sun_mat.emission_enabled = true
	_sun_mat.emission = Color(1.0, 0.65, 0.2)
	_sun_mat.emission_energy_multiplier = 3.5
	var sm := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 1.3
	sp.height = 2.6
	sm.mesh = sp
	sm.material_override = _sun_mat
	_sun.add_child(sm)
	var face := MeshInstance3D.new()
	var fq := QuadMesh.new()
	fq.size = Vector2(2.2, 2.2)
	face.mesh = fq
	var fm := StandardMaterial3D.new()
	fm.albedo_texture = load("res://assets/textures/soleils/sym_ollin.png")
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	face.material_override = fm
	face.position = Vector3(0, 0, 0)
	_sun.add_child(face)
	var sl := OmniLight3D.new()
	sl.light_color = Color(1.0, 0.8, 0.45)
	sl.light_energy = 3.0
	sl.omni_range = 26.0
	sl.shadow_enabled = pc
	_sun.add_child(sl)
	_sun.global_position = W(Vector3(0, 9.0, 64.0))
	_sun.visible = false
	for z in [54.0, 74.0]:
		_torch("cinquieme", Vector3(-13.85, 3.0, z), Vector3(1, 0, 0), 1.2)
		_torch("cinquieme", Vector3(13.85, 3.0, z), Vector3(-1, 0, 0), 1.2)
	kit.panel(X(Vector3(-13.95, 5.0, 64.0), PI * 0.5), 8.0, 4.0, "fresque69_nanahuatzin", "tezo69")


func _build_cipactli() -> void:
	_in_room("cipactli")
	kit.room(_xf(), -20, 20, 80, 120, 0, 14, "tezo69", "", [["n", 0, 3.2, 4.2]], "tezo69", T)
	kit.solid(X(Vector3(0, -0.3, 100.0)), Vector3(31.0, 0.6, 40.0 + 2.0 * T), "dalles69_sombre", 3.0)
	for s in [-1.0, 1.0]:
		kit.solid(X(Vector3(s * 18.25, -1.5, 100.0)), Vector3(5.5, 0.6, 40.0 + 2.0 * T), "tezo69", 3.0)
		kit.solid(X(Vector3(s * 20.5, -0.6, 100.0)), Vector3(1.0, 1.2, 40.0 + 2.0 * T), "tezo69", 3.0)
		for zz in [79.5, 120.5]:
			kit.solid(X(Vector3(s * 18.0, -0.6, zz)), Vector3(5.0, 1.2, 1.0), "tezo69", 3.0)
		kit.solid(X(Vector3(s * 15.2, 0.3, 100.0)), Vector3(0.6, 0.6, 40.0), "tezo69")
		var w := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(4.6, 40.0)
		w.mesh = pm
		w.material_override = kit.mat("eau69_sombre")
		(rooms["cipactli"]["root"] as Node3D).add_child(w)
		w.global_position = W(Vector3(s * 17.8, -0.6, 100.0))
	for p in [Vector3(-10.0, 0, 88.0), Vector3(10.0, 0, 88.0), Vector3(-10.0, 0, 112.0), Vector3(10.0, 0, 112.0)]:
		kit.column(X(p), 0.9, 14.0, "frise69", "tezo69")
	kit.solid(X(Vector3(0, 0.5, 116.5)), Vector3(4.0, 1.0, 3.0), "tezo69")
	kit.panel(X(Vector3(0, 6.0, 119.95), PI), 6.0, 6.0, "psoleil69", "tezo69")
	for z2 in [86.0, 100.0, 114.0]:
		kit.brazier63(rooms["cipactli"]["root"], W(Vector3(-13.0, 0, z2)), true, "bronze69", 1.8, "tezo69")
		kit.brazier63(rooms["cipactli"]["root"], W(Vector3(13.0, 0, z2)), true, "bronze69", 1.8, "tezo69")
	_feather = Node3D.new()
	_feather.name = "Plume_Quetzalcoatl"
	(rooms["cipactli"]["root"] as Node3D).add_child(_feather)
	var fm := MeshInstance3D.new()
	var fs := SphereMesh.new()
	fs.radius = 0.12
	fs.height = 0.24
	fm.mesh = fs
	fm.scale = Vector3(1.0, 0.3, 8.0)
	fm.rotation.x = -0.6
	fm.material_override = kit.mat("plume69")
	_feather.add_child(fm)
	var fl := OmniLight3D.new()
	fl.light_color = Color(0.4, 1.0, 0.7)
	fl.light_energy = 1.6
	fl.omni_range = 6.0
	_feather.add_child(fl)
	_feather.global_position = W(Vector3(0, 2.2, 116.0))
	_feather.visible = false


# =================================================================== dehors : les offrandes

func register(journal: Node) -> void:
	journal.lieux["cinq_soleils"] = W(Vector3(0, 0, 3.5))
	var d: Node = main.get("donjon_v35")
	if d == null or sol.azteque == null:
		return
	var A: Node = sol.azteque
	var me = self
	# la dalle ronde (elle glisse quand les deux dieux ont reçu leur offrande) et le trou noir dessous
	var Mats = preload("res://scripts/soleils_mats_v69.gd")
	_hole = MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 1.25
	hm.bottom_radius = 1.25
	hm.height = 0.02
	_hole.mesh = hm
	_hole.material_override = Mats.make("noir69")
	add_child(_hole)
	_hole.global_position = A.temple_gate + Vector3(0, 0.045, 0)
	_slab = MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 1.45
	sm.bottom_radius = 1.45
	sm.height = 0.14
	sm.radial_segments = 28
	_slab.mesh = sm
	_slab.material_override = Mats.make("frise69")
	add_child(_slab)
	_slab.global_position = A.temple_gate + Vector3(0, 0.1, 0)
	d._interactions.append({"id": "az_tlaloc", "pos": A.shrine_tlaloc, "radius": 1.8, "text": "E : verser l'eau de la jarre devant Tlaloc", "vr": "Gâchette : l'offrande",
		"call": func(): me._offer("tlaloc"), "when": func(): return not bool(me.state["tlaloc"]) and me._inv().count("jarre_pluie") > 0})
	d._interactions.append({"id": "az_tlaloc_vu", "pos": A.shrine_tlaloc, "radius": 1.8, "text": "E : examiner le sanctuaire de Tlaloc", "vr": "Gâchette : le sanctuaire",
		"call": func(): me._say("Le sanctuaire bleu de Tlaloc, le dieu de la pluie, aux yeux ronds et aux crocs. Devant, un chacmool tient une coupe vide sur son ventre. Tlaloc a soif… d'une jarre d'eau de pluie, sans doute. Coyotl, le potier, fait de belles jarres bleues.", 8.0),
		"when": func(): return not bool(me.state["tlaloc"]) and me._inv().count("jarre_pluie") <= 0})
	d._interactions.append({"id": "az_huitzi", "pos": A.shrine_huitzi, "radius": 1.8, "text": "E : brûler du copal pour Huitzilopochtli", "vr": "Gâchette : l'offrande",
		"call": func(): me._offer("huitzi"), "when": func(): return not bool(me.state["huitzi"]) and me._inv().count("copal") > 0})
	d._interactions.append({"id": "az_huitzi_vu", "pos": A.shrine_huitzi, "radius": 1.8, "text": "E : examiner le sanctuaire de Huitzilopochtli", "vr": "Gâchette : le sanctuaire",
		"call": func(): me._say("Le sanctuaire rouge de Huitzilopochtli, le colibri guerrier, le soleil qui se bat chaque nuit pour revenir. Devant, un brasero éteint. On y brûle du copal, l'encens blanc ; Tochtli en vend au marché.", 8.0),
		"when": func(): return not bool(me.state["huitzi"]) and me._inv().count("copal") <= 0})
	d._interactions.append({"id": "az_dalle", "pos": A.temple_gate, "radius": 1.8, "text": "E : examiner la dalle ronde", "vr": "Gâchette : la dalle",
		"call": func(): me._say("Une grande dalle ronde gravée, entre les deux sanctuaires. « Quand la pluie et le soleil auront reçu leur offrande, le chemin des Cinq Soleils s'ouvrira. »", 7.0),
		"when": func(): return not bool(me.state["ouvert"])})
	d._interactions.append({"id": "az_descendre", "pos": A.temple_gate, "radius": 1.8, "text": "E : descendre sous le Grand Temple", "vr": "Gâchette : descendre",
		"call": func(): me.enter(), "when": func(): return bool(me.state["ouvert"])})
	_apply_outdoor()


func _apply_outdoor() -> void:
	if _slab == null or sol.azteque == null:
		return
	var open: bool = bool(state["ouvert"])
	_slab.global_position = sol.azteque.temple_gate + (Vector3(-2.4, 0.1, 0) if open else Vector3(0, 0.1, 0))
	_hole.visible = open


func _offer(god: String) -> void:
	if god == "tlaloc":
		_inv().remove("jarre_pluie", 1)
		state["tlaloc"] = true
		_sfx("verser", sol.azteque.shrine_tlaloc + Vector3.UP)
		_say("Tu verses l'eau de la jarre dans la coupe du chacmool. Un grondement de tonnerre roule au loin, sur le lac… Tlaloc est content.", 6.0)
	else:
		_inv().remove("copal", 1)
		state["huitzi"] = true
		_sfx("flamme_impact", sol.azteque.shrine_huitzi + Vector3.UP)
		_say("Le copal crépite sur les braises, et une fumée blanche, parfumée, monte vers le soleil. Huitzilopochtli est content.", 6.0)
	if bool(state["tlaloc"]) and bool(state["huitzi"]) and not bool(state["ouvert"]):
		state["ouvert"] = true
		await get_tree().create_timer(2.0).timeout
		_sfx("tambour_azteque", sol.azteque.temple_gate + Vector3.UP)
		_sfx("pierre_glisse", sol.azteque.temple_gate + Vector3.UP)
		var tw := create_tween()
		tw.tween_property(_slab, "global_position", sol.azteque.temple_gate + Vector3(-2.4, 0.1, 0), 2.5).set_trans(Tween.TRANS_SINE)
		_hole.visible = true
		if main.has_method("jingle"):
			main.jingle("decouverte")
		_say("La pluie et le soleil ont reçu leur offrande ! Les tambours du temple se mettent à battre tout seuls, et la grande dalle ronde glisse de côté : un escalier descend sous le Grand Temple.", 8.0)


# =================================================================== invites du donjon

func _register() -> void:
	var me = self
	ia("sortir", Vector3(0, 0, 2.0), 1.6, "E : remonter au sommet du Grand Temple", "Gâchette : remonter", func(): me.leave("De retour au sommet du Grand Temple, entre Tlaloc et Huitzilopochtli."))
	ia("codex", Vector3(-7.0, 0, 17.8), 1.8, "E : lire le codex des soleils", "Gâchette : le codex",
		func(): me._say("Le codex des soleils, sur une peau de cerf peinte : au milieu, notre soleil, le cinquième. Autour, les quatre soleils d'avant, chacun avec son numéro en points rouges, et des flèches qui tournent : 1, 2, 3, 4… puis 5, au centre.", 8.0))
	for i in range(4):
		var ii: int = i
		ia("niche_%d" % i, Vector3(NICHE_X[i], 0, 45.8), 1.1, "E : poser un glyphe dans la niche", "Gâchette : la niche",
			func(): me._niche(ii), func(): return not bool(me.state["pierre"]) and str((me.state["niches"] as Array)[ii]) == "")
	for i2 in range(3):
		var jj: int = i2
		var p: Vector3 = [Vector3(20.4, 0, 35.3), Vector3(20.4, 0, 44.7), Vector3(18.3, 0, 36.8)][i2]
		ia("vanne_%d" % i2, p, 1.2, "E : ouvrir la vanne", "Gâchette : la vanne", func(): me._open_sluice(jj),
			func(): return not bool((me.state["vannes"] as Array)[jj]))
	ia("feu_offrande", Vector3(0, 0, 59.6), 2.4, "E : jeter une offrande dans le grand feu", "Gâchette : l'offrande",
		func(): me._fire_offering(), func(): return not bool(me.state["offrande"]))
	ia("conque", Vector3(0, 0, 59.6), 2.4, "E : souffler dans la conque d'Ehécatl", "Gâchette : la conque",
		func(): me._blow_conch(), func(): return bool(me.state["offrande"]) and not bool(me.state["soleil"]) and me._inv().count("conque") > 0)
	ia("soleil_immobile", Vector3(0, 0, 59.6), 2.4, "E : regarder le soleil immobile", "Gâchette : le soleil",
		func(): me._say("Le cinquième soleil brille au-dessus du feu… mais il ne bouge pas. Les dieux avaient le même souci : un soleil immobile brûle tout. Il lui faudrait un grand souffle — celui d'Ehécatl, le vent.", 7.0),
		func(): return bool(me.state["offrande"]) and not bool(me.state["soleil"]) and me._inv().count("conque") <= 0)
	ia("plume", Vector3(0, 1.0, 114.6), 2.2, "E : prendre la Plume de Quetzalcóatl", "Gâchette : la plume", func(): me._take_feather(),
		func(): return bool(me.state["boss"]) and not bool(me.state["fini"]))
	ia("sortie_fin", Vector3(0, 1.0, 114.6), 2.2, "E : monter vers la lumière (au sommet du Grand Temple)", "Gâchette : remonter",
		func(): me.leave("Un escalier de lumière… et te voilà au sommet du Grand Temple, au-dessus du lac d'Aztlán."), func(): return bool(me.state["fini"]))


func _apply_state() -> void:
	super._apply_state()
	_apply_outdoor()
	if _niche_quads.is_empty():
		return
	_show_niches()
	_stone_light.light_energy = 2.5 if bool(state["pierre"]) else 0.0
	var lvl: int = _water_level()
	_water.global_position = W(Vector3(30.0, WATER_Y[lvl], 40.0))
	for i in range(_rafts.size()):
		(_rafts[i] as Node3D).global_position = W(Vector3(RAFT_X[i], WATER_Y[lvl] + 0.1, 40.0))
	for i2 in range(3):
		(_wheels[i2] as Node3D).rotation.z = PI * 0.5 if bool(state["vannes"][i2]) else 0.0
	_sun.visible = bool(state["offrande"])
	_feather.visible = bool(state["boss"]) and not bool(state["fini"])


func _show_niches() -> void:
	var nn: Array = state["niches"]
	for i in range(4):
		var g: String = str(nn[i])
		var q: MeshInstance3D = _niche_quads[i]
		q.visible = g != ""
		if g != "":
			q.material_override = kit.mat(str(GLYPH_SYM[g]))


# =================================================================== la Pierre du Soleil

func _niche(i: int) -> void:
	var have: Array = []
	for g in GLYPHS:
		if _inv().count(g) > 0:
			have.append(g)
	if have.is_empty():
		_say("Une niche vide sous la Pierre du Soleil, marquée de %d point%s. Il y manque une tablette gravée. Les quatre salles des soleils en gardent chacune une." % [i + 1, "" if i == 0 else "s"], 6.0)
		return
	_pending_niche = i
	var choices: Array = []
	for g2 in have:
		choices.append({"id": str(g2), "label": "Poser le glyphe : %s" % str(GLYPH_NAME[g2])})
	choices.append({"id": "fermer", "label": "Ne rien poser."})
	_ask(W(Vector3(NICHE_X[i], 2.6, 46.6)), "La Pierre du Soleil", "immobile", "La niche marquée de %d point%s. Quel glyphe y poses-tu ?" % [i + 1, "" if i == 0 else "s"], choices, Callable(self, "_niche_answer"))


func _niche_answer(id: String) -> void:
	_close_dialog()
	if _pending_niche < 0 or not GLYPHS.has(id) or _inv().count(id) <= 0:
		return
	var i: int = _pending_niche
	_pending_niche = -1
	_inv().remove(id, 1)
	state["niches"][i] = id
	_show_niches()
	_sfx("mecanisme", W(Vector3(NICHE_X[i], 1.6, 46.8)))
	var nn: Array = state["niches"]
	for g in nn:
		if str(g) == "":
			_say("Tu poses %s dans la niche. Le glyphe s'enfonce avec un déclic." % str(GLYPH_NAME[id]), 4.0)
			return
	# les quatre niches sont pleines : l'ordre est-il celui des soleils ?
	var ok: bool = true
	for k in range(4):
		ok = ok and str(nn[k]) == GLYPHS[k]
	if ok:
		state["pierre"] = true
		_sfx("tambour_azteque", W(Vector3(0, 6, 46)))
		var tw := create_tween()
		tw.tween_property(_stone_light, "light_energy", 2.5, 2.5)
		_say("Jaguar, Vent, Pluie de feu, Eau : les quatre soleils, dans l'ordre ! La Pierre du Soleil s'allume d'or, et sous elle, la porte du Cinquième Soleil s'enfonce dans le sol.", 8.0)
		await get_tree().create_timer(2.5).timeout
		open_gate("cinquieme")
	else:
		await get_tree().create_timer(1.0).timeout
		_sfx("onde_choc", W(Vector3(0, 2, 46)))
		for g2 in nn:
			_inv().add(str(g2), 1)
		state["niches"] = ["", "", "", ""]
		_show_niches()
		_say("La Pierre du Soleil gronde… et rejette les quatre glyphes, qui retombent dans tes mains. Ce n'est pas l'ordre des soleils. (Le codex, à l'entrée, montre cet ordre.)", 7.0)


# =================================================================== l'eau

func _water_level() -> int:
	var n: int = 0
	for v in state["vannes"]:
		if bool(v):
			n += 1
	return n


func _open_sluice(i: int) -> void:
	state["vannes"][i] = true
	var lvl: int = _water_level()
	create_tween().tween_property(_wheels[i], "rotation:z", PI * 0.5, 1.2)
	_sfx("eau_vanne", (_wheels[i] as Node3D).global_position)
	var y: float = WATER_Y[lvl]
	var tw := create_tween()
	tw.tween_property(_water, "global_position:y", O.y + y, 3.0).set_trans(Tween.TRANS_SINE)
	for r in _rafts:
		create_tween().tween_property(r, "global_position:y", O.y + y + 0.1, 3.0).set_trans(Tween.TRANS_SINE)
	if lvl < 3:
		_say("Tu tournes la roue de bronze : un grondement d'eau dans les murs… le bassin monte, et les chinampas avec lui. (%d vanne%s sur 3)" % [lvl, "" if lvl == 1 else "s"], 5.0)
	else:
		_say("La dernière vanne ! L'eau monte jusqu'au bord, et les chinampas forment un chemin flottant jusqu'à la rive d'en face. Comme au temps du Soleil de l'Eau, quand les hommes devinrent des poissons…", 8.0)


# =================================================================== le Cinquième Soleil

func _fire_offering() -> void:
	_ask(W(Vector3(0, 3.0, 64.0)), "Le grand feu", "brûlant", "Le feu de Teotihuacan, où les dieux attendaient qu'un des leurs se jette pour devenir le soleil. Sur un autel, les riches offrandes de Tecciztécatl ; sur l'autre, les humbles offrandes de Nanahuatzin. Que jettes-tu dans le feu ?",
		[{"id": "riche", "label": "L'or, le jade et les plumes de Tecciztécatl"}, {"id": "humble", "label": "Les roseaux, les épines et le baume de Nanahuatzin"}, {"id": "fermer", "label": "Rien, pour l'instant."}],
		Callable(self, "_fire_answer"))


func _fire_answer(id: String) -> void:
	_close_dialog()
	if id == "riche":
		_sfx("flamme_impact", W(Vector3(0, 1, 64)))
		_say("Tu jettes l'or et le jade dans le feu… Les flammes sifflent et se recroquevillent, comme Tecciztécatl, le riche, qui recula quatre fois devant le brasier. Rien ne se passe. (Sur la fresque, c'est l'autre dieu qui saute.)", 8.0)
		return
	if id != "humble":
		return
	state["offrande"] = true
	_sfx("flamme_impact", W(Vector3(0, 1, 64)))
	_say("Tu jettes les roseaux et les épines de Nanahuatzin, le pauvre, le courageux, qui sauta sans hésiter… Le feu rugit, monte jusqu'à la voûte ! Et du brasier, lentement, un soleil se lève.", 8.0)
	_sun.visible = true
	_sun.global_position = W(Vector3(0, 1.0, 64.0))
	_sun.scale = Vector3.ONE * 0.2
	var tw := create_tween()
	tw.tween_property(_sun, "global_position", W(Vector3(0, 9.0, 64.0)), 5.0).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(_sun, "scale", Vector3.ONE, 5.0)
	await get_tree().create_timer(6.0).timeout
	if room == "cinquieme" and not bool(state["soleil"]):
		_say("Le soleil s'est levé… mais il ne bouge pas. Il brûle, immobile, au-dessus du feu. Les dieux, autrefois, ont eu le même souci.", 6.0)


func _blow_conch() -> void:
	state["soleil"] = true
	_sfx("conque", _feet() + Vector3.UP * 1.5)
	_say("Tu souffles dans la conque d'Ehécatl, de toutes tes forces. Un vent immense se lève dans la salle, fait plier les flammes… et le cinquième soleil se met en mouvement ! Il tourne, il traverse le ciel de pierre. Au sud, la dernière porte s'ouvre.", 9.0)
	await get_tree().create_timer(2.5).timeout
	open_gate("cipactli")


# =================================================================== chaque image

func _tick(delta: float, p: Vector3, r: String) -> void:
	var l: Vector3 = L(p)
	match r:
		"vent":
			_tick_wind(delta, l)
		"feu":
			_tick_fire(delta, l)
		"eau":
			if l.y < -2.2 and _fall_cd <= 0.0:
				_fall_cd = 1.5
				_fall_back("Plouf ! Tu remontes, trempé, sur le rebord de l'entrée. Le bassin est trop profond pour y nager.", 1 if _water_level() >= 3 else 2)
		"jaguars":
			if not bool(state["jaguars"]) and room_spawned("jaguars") and room_alive("jaguars") == 0:
				state["jaguars"] = true
				_say("Le dernier jaguar tombe. Dans le silence, la tête de jaguar de l'autel ouvre la gueule : un coffret y est apparu.", 6.0)
		"cipactli":
			if not bool(state["boss"]) and not fight and l.z > 90.0:
				_say("Le sol tremble. L'eau noire des douves bouillonne, et un crocodile gigantesque en sort, couvert d'épines, des gueules à chaque articulation : CIPACTLI, le monstre de la Terre, dont les dieux firent le monde !", 8.0)
				_start_boss("cipactli", Vector3(0, 0, 104.0), "Cipactli, le monstre de la Terre", Callable(self, "_cipactli_dead"))
	if _sun != null and _sun.visible and bool(state["soleil"]):
		var a: float = _clock * 0.35
		_sun.global_position = W(Vector3(cos(a) * 8.0, 9.0, 64.0 + sin(a) * 8.0))
	if _feather != null and _feather.visible:
		_feather.rotate_y(delta * 0.8)


func _on_walk_z(l: Vector3) -> bool:
	# à l'abri : sur un tronçon orienté nord-sud, sur la plate-forme, à l'entrée
	if l.x > -18.5 or l.x < -55.5:
		return true
	for w in WALKS:
		if absf(float(w[0]) - float(w[2])) < 0.1:
			var z0: float = minf(float(w[1]), float(w[3]))
			var z1: float = maxf(float(w[1]), float(w[3]))
			if absf(l.x - float(w[0])) < 1.0 and l.z > z0 - 1.0 and l.z < z1 + 1.0:
				return true
	return false


func _tick_wind(delta: float, l: Vector3) -> void:
	_gust_t += delta
	if _gust_t > 5.0:
		_gust_t = 0.0
		_gust_dir = -_gust_dir
	if _gust_t < delta * 1.5:
		_sfx("bourrasque", W(Vector3(-40.0, 2.0, 40.0 - _gust_dir * 5.0)))
	var gusting: bool = _gust_t > 1.2 and _gust_t < 2.6
	_dust.emitting = _gust_t > 1.0 and _gust_t < 2.6
	_dust.direction = Vector3(0, 0, _gust_dir)
	_dust.global_position = W(Vector3(-40.0, 1.5, 40.0 - _gust_dir * 5.5))
	if gusting and l.y > -1.0 and not _on_walk_z(l):
		push_player(Vector3(0, 0, _gust_dir * 2.4 * delta))
	if l.y < -2.0 and _fall_cd <= 0.0:
		_fall_cd = 1.5
		_fall_back("La rafale t'a emporté dans le vide… tu te réveilles à l'entrée de la salle, tout endolori. Attends à l'abri, dans les coudes des passerelles, que le vent tombe.", 2)


func _tick_fire(delta: float, l: Vector3) -> void:
	_fire_hit_cd = maxf(_fire_hit_cd - delta, 0.0)
	_fire_t += delta
	if _fire_t > 3.0:
		_fire_t = 0.0
		_fire_on.clear()
		for k in _fire_marks:
			(_fire_marks[k] as Node3D).visible = false
		for c in range(1, 12):
			for r in range(8):
				var safe: bool = false
				for s in FIRE_SAFE:
					if int(s[0]) == c and int(s[1]) == r:
						safe = true
				if not safe and randf() < 0.38:
					_fire_on.append([c, r])
					(_fire_marks["%d,%d" % [c, r]] as Node3D).visible = true
	# les pierres de feu tombent au bout d'une seconde et demie
	if _fire_t > 1.5 and _fire_t - delta <= 1.5:
		_sfx("pluie_feu", W(Vector3(31.0, 3.0, 24.0)))
		var shown: int = 0
		for cr in _fire_on:
			var at: Vector3 = W(Vector3(19.0 + 2.0 * float(cr[0]), 0.3, 17.0 + 2.0 * float(cr[1])))
			if shown < 8 and main.combat_v28 != null:
				shown += 1
				main.combat_v28.puff(at, Color(1.0, 0.5, 0.15))
			var c2: int = int(cr[0])
			var r2: int = int(cr[1])
			var pc_: int = int(round((l.x - 19.0) / 2.0))
			var pr: int = int(round((l.z - 17.0) / 2.0))
			if pc_ == c2 and pr == r2 and l.y < 2.0 and _fire_hit_cd <= 0.0:
				_fire_hit_cd = 1.0
				_hurt(2, at + Vector3.UP * 3.0)
				_say("Une pierre de feu s'écrase sur toi ! Regarde le sol : là où il rougeoie, le feu va tomber.", 4.0)
		for k2 in _fire_marks:
			(_fire_marks[k2] as Node3D).visible = false


func _cipactli_dead() -> void:
	state["boss"] = true
	_say("Cipactli s'effondre dans un grondement de montagne. Son corps se fait pierre, terre, racines… comme au premier jour, quand les dieux firent le monde de son corps. Sur l'autel du fond, une plume verte se met à briller.", 9.0)
	await get_tree().create_timer(2.0).timeout
	_feather.visible = true
	_feather.scale = Vector3.ONE * 0.1
	create_tween().tween_property(_feather, "scale", Vector3.ONE, 1.5)


func _take_feather() -> void:
	state["fini"] = true
	_feather.visible = false
	_reward("plume_quetzal", "Porteur du Cinquième Soleil", 150, W(Vector3(0, 1.2, 114.0)))
	main._show_message_v28("La Plume de Quetzalcóatl ! Le Serpent à plumes, le dieu du vent et du savoir. 150 pièces, un cœur de plus, et un titre : « Porteur du Cinquième Soleil ». Un escalier de lumière remonte au sommet du Grand Temple.")


func _on_enter(first: bool) -> void:
	if first:
		_say("Tu descends sous le Grand Temple. Sur les murs, Tlaloc et Huitzilopochtli te regardent passer ; quelque part, plus bas, un tambour bat comme un cœur.", 8.0)
	else:
		_say("Sous le Grand Temple d'Aztlán.", 3.0)


func _enter_room(_old: String, r: String) -> void:
	match r:
		"pierre":
			_once("pierre", "La salle de la Pierre du Soleil. Un disque de pierre immense, au-dessus de la porte du sud, et quatre niches vides dessous. Quatre portes, chacune marquée d'un soleil. Près de l'entrée, un codex peint.", 8.0)
		"jaguars":
			if not bool(state["jaguars"]):
				_once("jaguars", "Le Soleil des Jaguars : le premier monde, que les jaguars dévorèrent. Des grondements entre les piliers…", 5.0)
		"vent":
			_once("vent", "Le Soleil du Vent : des passerelles étroites au-dessus du vide, et un vent qui se lève par rafales. Dans les coudes des passerelles, le vent souffle dans le bon sens… À l'abri, attends ; puis cours.", 8.0)
		"feu":
			_once("feu", "Le Soleil de Pluie de feu. Le plafond est fendu de braises. Par moments, le sol rougeoie… puis des pierres de feu tombent. Deux abris de pierre, au milieu.", 7.0)
		"eau":
			_once("eau", "Le Soleil de l'Eau. Un grand bassin presque vide, des chinampas échouées tout au fond, et trois roues de bronze aux murs.", 6.0)
		"cinquieme":
			if not bool(state["soleil"]):
				_once("cinquieme", "Le Cinquième Soleil. Un grand feu, deux autels : l'or et le jade d'un côté, des roseaux et des épines de l'autre. Au mur, une fresque : des dieux autour du feu, et l'un d'eux qui saute.", 8.0)
		"cipactli":
			if not bool(state["boss"]):
				_once("cipactli", "Une salle immense, des douves d'eau noire tout autour. Au fond, la Pierre du Soleil… Le sol vibre, très légèrement.", 6.0)


func _faint_text() -> String:
	return "Le tambour bat toujours, quelque part…"


func _on_reset() -> void:
	_pending_niche = -1
	for k in _fire_marks:
		(_fire_marks[k] as Node3D).visible = false
	_fire_on.clear()
