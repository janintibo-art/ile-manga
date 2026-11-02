extends Node3D
## V97 : l'Île Al Dente — le chef d'orchestre. L'île de la secte du Spaghetti Volant :
##  - le Temple-Passoire : une passoire géante retournée sur un socle de pierre, percée de centaines de
##    trous (le soleil dessine des taches de lumière à l'intérieur) ; dedans, des bancs en arc de cercle
##    et l'autel, la Fourchette Sacrée, l'assiette éternelle ; au-dessus, le Grand Spaghetti Volant,
##    une grande pelote de spaghettis qui flotte dans le ciel, avec deux boulettes et deux yeux au bout
##    de leurs tiges (ils te suivent du regard) ;
##  - le parvis : la fourchette et la cuillère géantes en bronze, la fontaine de sauce, les boulettes de
##    pierre, les bannières vert-blanc-rouge, le Couvercle Sacré (on le frappe comme un gong) ;
##  - le Mont Bolognaise : un chemin qui monte en spirale jusqu'à la Marmite, le cratère plein de sauce
##    tomate qui bouillonne ; la louche géante ; de temps en temps (ou si on insiste sur le Couvercle),
##    une éruption : le volcan crache de grosses gouttes de sauce qui s'écrasent sur ses pentes ;
##  - deux rivières de sauce : l'une jusqu'au Lac Napolitain, l'autre jusqu'à la falaise du nord (la
##    Cascade Arrabbiata, qui tombe dans la mer et la teinte de rouge) ;
##  - la Plage du Parmesan (le ponton), les Champs de Blé Dur, le Séchoir à pâtes, la Tomateraie,
##    l'Oliveraie, le Jardin du Basilic.
## (V98 : les adeptes du Spaghetti Volant et leur quête.)

const IleScript = preload("res://scripts/ile_pasta_v97.gd")
const Kit = preload("res://scripts/pasta_kit_v97.gd")
const Decor = preload("res://scripts/decor_v53.gd")
const FLORE := "res://scripts/pasta_flore_v97.gd"
const SAUCE := "res://shaders/sauce_v97.gdshader"
const SAUCE_FLOT := "res://shaders/sauce_flot_v97.gdshader"
const PASSOIRE := "res://shaders/passoire_v97.gdshader"

const PLACES := {"plage": "la Plage du Parmesan", "temple": "le parvis du Temple-Passoire", "temple_dedans": "le Temple-Passoire",
	"volcan": "le Mont Bolognaise", "cratere": "la Marmite (le cratère)", "lac": "le Lac Napolitain", "cascade": "la Cascade Arrabbiata",
	"champs": "les Champs de Blé Dur", "sechoir": "le Séchoir à pâtes", "tomateraie": "la Tomateraie", "oliveraie": "l'Oliveraie",
	"prairie": "la prairie", "borgo": "le Borgo des Coquillettes", "barque": "la Barque-Maison du Capitaine"}

## Ce que disent les panneaux : [id, x, z, vers où il regarde, texte]
const PANNEAUX := [
	["accueil", 30.0, 146.0, Vector2(0, 1), "Bienvenue sur l'Île Al Dente !\nAu nord : le Mont Bolognaise (il crache de la sauce).\nÀ l'ouest : le Temple-Passoire.\nMerci de ne pas manger les panneaux."],
	["temple", -32.0, 61.0, Vector2(0.81, 0.586), "Temple-Passoire\nEntrez, la porte est ouverte (tout est ouvert : c'est une passoire).\nSilence, on égoutte."],
	["volcan", 74.0, 24.0, Vector2(-0.4, 0.9), "Mont Bolognaise — chemin de la Marmite\nAttention : éruptions de sauce imprévisibles.\nPortez un bavoir."],
	["lac", 84.0, 30.0, Vector2(-0.7, 0.7), "Lac Napolitain\nBaignade interdite : la sauce est chaude,\net il paraît qu'on en ressort tout rouge."],
	["champs", -46.0, 96.0, Vector2(0.6, 0.8), "Champs de Blé Dur\nIci pousse le blé des pâtes.\nPas de pâtes sans blé, pas de blé sans soleil."],
	["cratere", 0.0, 0.0, Vector2(0, 1), "La Marmite\nNe pas se pencher. Ne pas tremper les doigts.\nLa louche est là pour ça."],
]

## Les Huit Recommandations des Pâtes (sur le pupitre de l'autel)
const RECOMMANDATIONS := "Les Huit Recommandations des Pâtes\n1. Tu ne trop cuiras point les pâtes.\n2. Tu partageras ta sauce avec ton voisin.\n3. Tu ne casseras point les spaghettis en deux.\n4. Tu goûteras avant de saler.\n5. Tu ne jetteras point les pâtes au mur pour voir si elles collent.\n6. Tu laisseras une place à table pour l'inconnu.\n7. Tu feras la vaisselle (même la marmite).\n8. Tu souriras : c'est meilleur avec le sourire."

var main: Node
var ile: Node3D
var flore: Node3D
var pc: bool = true
var state: Dictionary = {}
var objets: Dictionary = {}               # lieux pour le carnet (nom -> Vector3 monde)
var panneaux: Array = []
var _avoid: Array = []
var _cols: StaticBody3D
var _registered: bool = false
var _rng := RandomNumberGenerator.new()
var _clock: float = 0.0
var _zone_t: float = 0.0
var _night_lights: Array = []

# le temple
var temple_c := Vector3.ZERO              # le centre de la passoire (au sol)
var temple_floor: float = 0.0
var _autel_at := Vector3.ZERO
var _gong_at := Vector3.ZERO
var _fontaine_at := Vector3.ZERO
var _sechoir_at := Vector3.ZERO
var _tomates_at := Vector3.ZERO
var _gong_hits: Array = []                # les derniers coups (secondes)
# le Grand Spaghetti Volant
var effigie: Node3D
var _eyes: Array = []                     # [Node3D (le globe), Vector3 (sa place dans l'effigie)]
var _effigie_y: float = 0.0
var _wiggle: float = 0.0
var _blink: float = 0.0
var _nouille_mat: ShaderMaterial
# le volcan
var cratere_c := Vector3.ZERO             # le centre de la Marmite, au niveau de la sauce
var _marmite_mat: ShaderMaterial
var _flot_mats: Array = []
var _louche_at := Vector3.ZERO
var _vapeur: GPUParticles3D
var _gerbe: GPUParticles3D
var _gouttes: Array = []                  # {"node", "a", "b", "t", "dur", "h"}
var _taches: Array = []                   # {"decal", "age"}
var _splat_tex: Texture2D
var _goutte_mesh: Mesh
var _goutte_mat: ShaderMaterial
var erupt_phase: String = ""              # "" / "gronde" / "jaillit"
var _erupt_t: float = 0.0
var _next_erupt: float = 150.0
var _boil: float = 0.0
var _hot_t: float = 0.0
var _hot_msg_t: float = 0.0
var cascade_at := Vector3.ZERO
var _sauce_t: float = 0.0                 # le dernier coup de louche (secondes)
# V98 : la vie de l'île (le Borgo, les adeptes, la Barque-Maison) et l'humeur du Grand Spaghetti
const Ville = preload("res://scripts/pasta_ville_v98.gd")
var ville: Node3D
var humeur_effigie: float = 1.0           # 0 : il boude (nouilles pendantes, yeux mi-clos) ; 1 : il va bien
var fete_k: float = 0.0                   # la Grande Réconciliation : il danse
var _humeur_lisse: float = 1.0


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_rng.seed = 9790
	state = _fresh_state()


func _fresh_state() -> Dictionary:
	return {"visite": false, "visites": {}, "panneaux": {}, "temple": false, "effigie": false, "couvercle": 0, "cratere": false,
		"sauce": 0, "eruptions": 0, "eclabousse": false, "cascade": false, "lac": false, "spaghettis": false, "tomates": 0,
		"recommandations": false, "offrande": false}


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_al_dente_v97"
	add_child(ile)
	ile.build(pc)


func dock() -> Array:
	return [IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y), IleScript.W(IleScript.DOCK_B.x, IleScript.DOCK_B.y)]


## Après le relief et l'heure du jour : le temple et son parvis, le Spaghetti Volant, le volcan et sa
## sauce, les champs, le séchoir, la plage, les panneaux, la végétation.
func build_town() -> void:
	var t0: int = Time.get_ticks_msec()
	_temple()
	_parvis()
	_effigie()
	_volcan()
	_rivieres()
	_champs()
	_plage()
	_panneaux()
	# V98 : le Borgo des Coquillettes, la Barque-Maison, les rues et les lieux des adeptes (avant la
	# végétation : les maisons écartent les arbres ; les adeptes arrivent avec les autres habitants)
	ville = Ville.new()
	add_child(ville)
	ville.setup(main, self)
	ville.build()
	if ResourceLoader.exists(FLORE):
		flore = load(FLORE).new()
		flore.name = "Flore_al_dente_v97"
		add_child(flore)
		for a in _avoid:
			flore.avoid.append(a)
		flore.build_pasta(ile, pc)
	objets["plage"] = _ground(18.0, 140.0)
	objets["temple"] = temple_c
	objets["parvis"] = _fontaine_at
	objets["cratere"] = ile.spiral_end
	objets["lac"] = _ground(86.0, 25.0)
	objets["cascade"] = cascade_at
	objets["champs"] = _ground(-74.0, 102.0)
	objets["sechoir"] = _sechoir_at
	objets["tomateraie"] = _tomates_at
	print("ILE_MANGA_V97: l'Île Al Dente est prête (%d ms)" % (Time.get_ticks_msec() - t0))


func _ground(x: float, z: float) -> Vector3:
	var w: Vector3 = IleScript.W(x, z)
	w.y = ile.height(w.x, w.z)
	return w


func _col(xf: Transform3D, size: Vector3) -> void:
	if _cols == null:
		_cols = StaticBody3D.new()
		_cols.name = "Al_dente_collisions_v97"
		_cols.collision_layer = 1
		_cols.collision_mask = 0
		add_child(_cols)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	_cols.add_child(cs)
	cs.global_transform = xf


func _col_cyl(at: Vector3, r: float, h: float) -> void:
	if _cols == null:
		_col(Transform3D(Basis(), Vector3(0, -500, 0)), Vector3.ONE * 0.1)
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = h
	cs.shape = sh
	_cols.add_child(cs)
	cs.global_position = at + Vector3.UP * h * 0.5


func _light(at: Vector3, col: Color, energy: float, rng: float, night_only: bool, shadows: bool = false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.3
	l.shadow_enabled = shadows
	add_child(l)
	l.global_position = at
	if night_only:
		_night_lights.append([l, energy])
	return l


# ------------------------------------------------------------------- le Temple-Passoire

func _temple() -> void:
	var pc2: Vector2 = IleScript.PASSOIRE
	temple_floor = float(IleScript.PADS["temple"][3]) + 0.45
	temple_c = IleScript.W(pc2.x, pc2.y, temple_floor)
	var R: float = IleScript.PASSOIRE_R
	var H: float = 13.0
	var door := Vector3(IleScript.PORTE_DIR.x, 0, IleScript.PORTE_DIR.y).normalized()
	var b := Kit.Batch.new()
	# le socle : deux marches de calcaire, le sol de dalles
	b.cyl("calcaire", Transform3D(Basis(), temple_c - Vector3.UP * 0.9), R + 2.6, R + 2.6, 0.5, 64, true)
	b.cyl("calcaire", Transform3D(Basis(), temple_c - Vector3.UP * 0.45), R + 1.4, R + 1.4, 0.45, 64, true)
	b.cyl("dalles", Transform3D(Basis(), temple_c - Vector3.UP * 0.02), R + 0.3, R + 0.3, 0.02, 64, true)
	# l'escalier devant la porte
	var side: Vector3 = door.cross(Vector3.UP)
	var yaw: float = atan2(door.x, door.z)
	for k in range(3):
		var sp: Vector3 = temple_c + door * (R + 1.9 + k * 0.7) - Vector3.UP * (0.25 + k * 0.3)
		b.box("calcaire", Transform3D(Basis(Vector3.UP, yaw), sp), Vector3(6.4, 0.3, 0.7))
	# la passoire : la coque percée, puis le rebord, le pied et les anses
	var shell := MeshInstance3D.new()
	shell.name = "Temple_passoire_coque"
	shell.mesh = Kit.colander_shell(R, H)
	var pm := ShaderMaterial.new()
	pm.shader = load(PASSOIRE)
	pm.set_shader_parameter("holes", true)
	pm.set_shader_parameter("radius", Kit.colander_profile(R, H)["rs"])
	pm.set_shader_parameter("sphere_y", Kit.colander_profile(R, H)["sphere_y"])
	pm.set_shader_parameter("door_dir", IleScript.PORTE_DIR)
	shell.material_override = pm
	add_child(shell)
	shell.global_position = temple_c
	Kit.colander_trim(b, Transform3D(Basis(), temple_c), R, H)
	# --- dedans : l'autel (au fond, face à la porte), la Fourchette Sacrée, l'assiette éternelle
	_autel_at = temple_c - door * 8.6
	var ab := Basis(Vector3.UP, yaw)
	b.box("calcaire", Transform3D(ab, _autel_at + Vector3.UP * 0.55), Vector3(3.6, 1.1, 1.5))
	b.box("calcaire", Transform3D(ab, _autel_at + Vector3.UP * 1.13), Vector3(3.9, 0.08, 1.75))
	b.box("nappe", Transform3D(ab, _autel_at + Vector3.UP * 1.18), Vector3(3.95, 0.02, 1.8))
	for sx in [-1.0, 1.0]:
		b.box("nappe", Transform3D(ab, _autel_at + Vector3.UP * 0.86 + ab * Vector3(sx * 1.97, 0, 0)), Vector3(0.02, 0.6, 1.8))
	# l'assiette éternelle : une montagne de spaghettis, une boulette au sommet
	var plate: Vector3 = _autel_at + Vector3.UP * 1.2
	b.cyl("calcaire", Transform3D(Basis(), plate), 0.62, 0.7, 0.05, 28, true)
	var prng := RandomNumberGenerator.new()
	prng.seed = 9733
	for k2 in range(46):
		var pts: Array = []
		var a0: float = prng.randf() * TAU
		var r0: float = prng.randf_range(0.05, 0.5)
		var turns: float = prng.randf_range(0.8, 1.6)
		for s in range(10):
			var t: float = float(s) / 9.0
			var aa: float = a0 + t * TAU * turns
			var rr: float = r0 * (1.0 - t * 0.6) + 0.05
			pts.append(plate + Vector3(cos(aa) * rr, 0.06 + t * 0.38 * (1.0 - rr), sin(aa) * rr))
		b.noodle("pates", pts, 0.012, [], 4)
	b.sphere("boulette", plate + Vector3.UP * 0.55, 0.17, 0.92, 7, 12)
	b.sphere("boulette", plate + Vector3(0.22, 0.4, 0.12), 0.13, 0.9, 6, 10)
	# la Fourchette Sacrée (dorée), dressée derrière l'autel
	Kit.fork(b, Transform3D(ab, _autel_at - door * 1.6), 4.2, "or")
	# deux grands chandeliers
	for sx2 in [-1.0, 1.0]:
		var cp: Vector3 = _autel_at + ab * Vector3(sx2 * 2.8, 0, 0.3)
		b.cyl("cuivre", Transform3D(Basis(), cp), 0.28, 0.05, 1.7, 10, true)
		b.cyl("cuivre", Transform3D(Basis(), cp + Vector3.UP * 1.7), 0.2, 0.22, 0.08, 10, true)
		b.cyl("toile_creme", Transform3D(Basis(), cp + Vector3.UP * 1.78), 0.07, 0.07, 0.45, 8, true)
		var fl: CPUParticles3D = _fire(cp + Vector3.UP * 2.28, 0.04, 14)
		fl.name = "Chandelle_%d" % int(sx2 + 1)
		_light(cp + Vector3.UP * 2.4, Color(1.0, 0.7, 0.4), 0.9, 7.0, false)
	# le pupitre des Huit Recommandations
	var pup: Vector3 = _autel_at + ab * Vector3(-2.9, 0, 2.2)
	b.box("bois", Transform3D(ab, pup + Vector3.UP * 0.55), Vector3(0.14, 1.1, 0.14))
	b.box("bois", Transform3D(ab * Basis(Vector3.RIGHT, -0.5), pup + Vector3.UP * 1.12), Vector3(0.75, 0.04, 0.55))
	var lb: Label3D = Kit.label(self, RECOMMANDATIONS, pup + Vector3.UP * 1.62 + door * 0.0, door, 0.0016, Color(0.2, 0.12, 0.05))
	lb.font_size = 48
	lb.width = 900.0
	lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lb.position = pup + Vector3.UP * 1.9 + door * 0.35
	objets["autel"] = _autel_at
	# les bancs, en trois arcs face à l'autel
	for row in range(3):
		var rr2: float = 4.2 + row * 1.9
		for k3 in range(-2, 3):
			if k3 == 0:
				continue       # l'allée du milieu
			var aa2: float = k3 * 0.36
			var dirb: Vector3 = (door.rotated(Vector3.UP, aa2)).normalized()
			var bp: Vector3 = _autel_at + dirb * rr2
			# V98 : les bancs regardent l'autel (le dossier côté porte)
			Kit.pew(b, Transform3D(Basis(Vector3.UP, atan2(-dirb.x, -dirb.z)), bp), 2.0)
	b.commit(self, "Temple_passoire")
	# la collision de la paroi : des boîtes tout autour (sauf la porte), le socle
	var n: int = 44
	for i in range(n):
		var a: float = TAU * (i + 0.5) / n
		var dir := Vector3(cos(a), 0, sin(a))
		if dir.dot(door) > cos(0.2):
			continue
		var wp: Vector3 = temple_c + dir * (R - 0.15)
		_col(Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.z)), wp + Vector3.UP * 4.0), Vector3(TAU * R / n + 0.4, 8.0, 0.5))
	_col(Transform3D(Basis(Vector3.UP, atan2(_autel_at.x - temple_c.x, _autel_at.z - temple_c.z)), _autel_at + Vector3.UP * 0.6), Vector3(3.8, 1.2, 1.6))
	_col_cyl(temple_c - Vector3.UP * 0.95, R + 1.4, 0.95)
	_avoid.append([Vector2(temple_c.x, temple_c.z), R + 4.0])
	# une lumière douce dedans (le soleil passe par les trous : c'est lui qui fait l'essentiel)
	_light(temple_c + Vector3.UP * 6.0, Color(1.0, 0.86, 0.66), 0.5, 18.0, false)
	_light(temple_c + Vector3.UP * 4.0, Color(1.0, 0.75, 0.45), 1.6, 20.0, true)


# ------------------------------------------------------------------- le parvis

func _parvis() -> void:
	var door := Vector3(IleScript.PORTE_DIR.x, 0, IleScript.PORTE_DIR.y).normalized()
	var side: Vector3 = door.cross(Vector3.UP)
	var yaw: float = atan2(door.x, door.z)
	var R: float = IleScript.PASSOIRE_R
	var y: float = float(IleScript.PADS["temple"][3])
	var b := Kit.Batch.new()
	# le dallage : de la porte jusqu'au bord du terre-plein
	var p0: Vector3 = temple_c + door * (R + 3.8)
	p0.y = y
	var plen: float = 24.0
	b.box("dalles", Transform3D(Basis(Vector3.UP, yaw), p0 + door * plen * 0.5 + Vector3.UP * 0.02), Vector3(9.0, 0.06, plen))
	# la fontaine de sauce, au milieu
	_fontaine_at = p0 + door * 10.0
	b.cyl("calcaire", Transform3D(Basis(), _fontaine_at), 2.6, 2.6, 0.62, 40, true)
	b.cyl("calcaire", Transform3D(Basis(), _fontaine_at + Vector3.UP * 0.62), 2.75, 2.75, 0.1, 40, true)
	b.cyl("calcaire", Transform3D(Basis(), _fontaine_at + Vector3.UP * 0.6), 0.45, 0.32, 1.5, 16, true)
	b.cyl("calcaire", Transform3D(Basis(), _fontaine_at + Vector3.UP * 2.1), 0.3, 1.1, 0.35, 24, true)
	# une boulette de pierre au sommet, d'où la sauce déborde
	b.sphere("boulette", _fontaine_at + Vector3.UP * 2.75, 0.42, 0.95, 8, 14)
	var pool := MeshInstance3D.new()
	var pmh := PlaneMesh.new()
	pmh.size = Vector2(5.0, 5.0)
	pmh.subdivide_width = 24
	pmh.subdivide_depth = 24
	pool.mesh = pmh
	var sm := ShaderMaterial.new()
	sm.shader = load(SAUCE)
	sm.set_shader_parameter("mode", 2)
	sm.set_shader_parameter("bubble_scale", 0.35)
	pool.material_override = sm
	add_child(pool)
	pool.global_position = _fontaine_at + Vector3.UP * 0.5
	# le filet de sauce qui coule de la coupe (un petit ruban circulaire, en cascade)
	var drip := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.05
	cm.bottom_radius = 1.25
	cm.height = 1.55
	cm.cap_top = false
	cm.cap_bottom = false
	cm.radial_segments = 32
	drip.mesh = cm
	var dm := ShaderMaterial.new()
	dm.shader = load(SAUCE_FLOT)
	dm.set_shader_parameter("mode", 1)
	dm.set_shader_parameter("speed", 0.25)
	drip.material_override = dm
	add_child(drip)
	drip.global_position = _fontaine_at + Vector3.UP * 1.33
	_col_cyl(_fontaine_at, 2.7, 0.75)
	_avoid.append([Vector2(_fontaine_at.x, _fontaine_at.z), 4.0])
	# la fourchette et la cuillère géantes, à l'entrée du parvis
	var gate: Vector3 = p0 + door * (plen - 1.5)
	for sx in [-1.0, 1.0]:
		var sp: Vector3 = gate + side * sx * 6.2
		sp.y = ile.height(sp.x, sp.z)
		b.cyl("calcaire", Transform3D(Basis(), sp), 1.3, 1.2, 1.0, 16, true)
		var xf := Transform3D(Basis(Vector3.UP, yaw), sp + Vector3.UP * 1.0)
		if sx < 0.0:
			Kit.fork(b, xf, 12.0, "bronze")
		else:
			Kit.spoon(b, xf, 12.0, "bronze")
		_col_cyl(sp, 1.3, 4.0)
		_avoid.append([Vector2(sp.x, sp.z), 2.5])
	# les boulettes de pierre, de chaque côté
	for k in range(5):
		for sx2 in [-1.0, 1.0]:
			var bp: Vector3 = p0 + door * (3.0 + k * 4.4) + side * sx2 * 5.4
			if k == 2:
				continue
			bp.y = y
			var rb: float = 0.75 + 0.15 * float((k + int(sx2 + 1.0)) % 3)
			b.sphere("boulette", bp + Vector3.UP * rb * 0.85, rb, 0.9, 8, 14)
			_col_cyl(bp, rb * 0.9, rb * 1.6)
	# les bannières vert-blanc-rouge
	for k2 in range(4):
		var sx3: float = -1.0 if k2 % 2 == 0 else 1.0
		var bn: Vector3 = p0 + door * (5.0 + (k2 / 2) * 11.0) + side * sx3 * 7.2
		bn.y = ile.height(bn.x, bn.z)
		Kit.banner(b, bn, -side * sx3)
	# le Couvercle Sacré, à droite de la porte
	_gong_at = temple_c + door * (R + 5.0) + side * 6.5
	_gong_at.y = y
	Kit.lid_gong(b, Transform3D(Basis(Vector3.UP, yaw), _gong_at))
	_col(Transform3D(Basis(Vector3.UP, yaw), _gong_at + Vector3.UP * 1.9), Vector3(4.2, 3.8, 0.3))
	_avoid.append([Vector2(_gong_at.x, _gong_at.z), 3.0])
	# des lanternes le soir, le long du dallage
	for k3 in range(3):
		for sx4 in [-1.0, 1.0]:
			var lp: Vector3 = p0 + door * (1.5 + k3 * 9.0) + side * sx4 * 4.0
			lp.y = y
			b.cyl("fer", Transform3D(Basis(), lp), 0.06, 0.05, 2.4, 6, true)
			b.box("lampe", Transform3D(Basis(), lp + Vector3.UP * 2.55), Vector3(0.24, 0.32, 0.24))
			_light(lp + Vector3.UP * 2.6, Color(1.0, 0.72, 0.42), 1.4, 9.0, true)
	b.commit(self, "Parvis_du_temple")


func _fire(at: Vector3, radius: float, amount: int) -> CPUParticles3D:
	var d: Node = main.get("donjon_v35") if main != null else null
	if d != null and d.has_method("_fire"):
		return d._fire(self, at - global_position, radius, amount)
	var p := CPUParticles3D.new()
	add_child(p)
	p.global_position = at
	return p


# ------------------------------------------------------------------- le Grand Spaghetti Volant

func _effigie() -> void:
	effigie = Node3D.new()
	effigie.name = "Grand_Spaghetti_Volant"
	add_child(effigie)
	_effigie_y = temple_floor + 13.0 + 22.0
	effigie.global_position = Vector3(temple_c.x, _effigie_y, temple_c.z)
	var b := Kit.Batch.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 9777
	# la pelote : des nouilles qui font des boucles autour du centre (un ellipsoïde)
	for i in range(34):
		var axis := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		var u: Vector3 = axis.cross(Vector3.UP if absf(axis.y) < 0.9 else Vector3.RIGHT).normalized()
		var v: Vector3 = axis.cross(u)
		var r: float = rng.randf_range(2.6, 4.6)
		var ph: float = rng.randf() * TAU
		var len: float = rng.randf_range(1.2, 1.9) * PI
		var pts: Array = []
		var fl: Array = []
		var n: int = 26
		for k in range(n):
			var t: float = ph + len * k / (n - 1)
			var wob: float = 1.0 + 0.12 * sin(t * 3.0 + i)
			var p: Vector3 = (u * cos(t) + v * sin(t)) * r * wob + axis * sin(t * 2.0 + i) * 0.5
			pts.append(Vector3(p.x * 1.35, p.y * 0.62, p.z * 1.35))
			fl.append(0.12)
		b.noodle("nouille", pts, 0.11, fl, 6)
	# les tentacules qui pendent (ils se balancent)
	for j in range(14):
		var a: float = TAU * j / 14.0 + rng.randf_range(-0.2, 0.2)
		var start := Vector3(cos(a) * rng.randf_range(1.5, 4.0), -1.2, sin(a) * rng.randf_range(1.5, 4.0))
		var lng: float = rng.randf_range(8.0, 15.0)
		var pts2: Array = []
		var fl2: Array = []
		var m: int = 18
		for k2 in range(m):
			var t2: float = float(k2) / (m - 1)
			var curl := Vector3(sin(t2 * 7.0 + j) * 0.6 * t2, 0.0, cos(t2 * 5.0 + j * 2.0) * 0.6 * t2)
			pts2.append(start + Vector3(cos(a), 0, sin(a)) * t2 * 2.5 + curl - Vector3.UP * t2 * lng)
			fl2.append(0.15 + t2 * 0.85)
		b.noodle("nouille", pts2, 0.11 - 0.03 * 0.5, fl2, 6)
	# les deux boulettes, sur le dessus
	for sx in [-1.0, 1.0]:
		b.sphere("boulette", Vector3(sx * 2.5, 2.2, -0.4), 2.0, 0.92, 12, 20)
	# les tiges des yeux : deux nouilles qui montent en se courbant vers l'avant
	for sx2 in [-1.0, 1.0]:
		var pts3: Array = []
		var fl3: Array = []
		for k3 in range(12):
			var t3: float = float(k3) / 11.0
			pts3.append(Vector3(sx2 * (0.8 + t3 * 1.6), 2.0 + t3 * 5.2 - t3 * t3 * 1.2, 0.4 + t3 * t3 * 2.4))
			fl3.append(0.1 + t3 * 0.3)
		b.noodle("nouille", pts3, 0.2, fl3, 8)
		var eye_at: Vector3 = pts3[-1] + Vector3(0, 0.9, 0.3)
		var eye := MeshInstance3D.new()
		eye.name = "Oeil_%s" % ("gauche" if sx2 < 0 else "droit")
		var sm := SphereMesh.new()
		sm.radius = 1.1
		sm.height = 2.2
		sm.radial_segments = 32
		sm.rings = 16
		eye.mesh = sm
		eye.material_override = Kit.mat("oeil")
		effigie.add_child(eye)
		eye.position = eye_at
		_eyes.append([eye, eye_at])
	var mi: MeshInstance3D = b.commit(effigie, "Spaghetti_corps")
	mi.position = Vector3.ZERO
	# les nouilles du corps se balancent davantage : leur matière est la sienne
	_nouille_mat = Kit.mat("nouille")
	effigie.global_position = Vector3(temple_c.x, _effigie_y, temple_c.z)


# ------------------------------------------------------------------- le Mont Bolognaise

func _volcan() -> void:
	var v: Array = IleScript.VOLCAN
	cratere_c = IleScript.W(float(v[0]), float(v[1]), float(v[6]))
	# la Marmite : une grande nappe de sauce qui bouillonne
	var pool := MeshInstance3D.new()
	pool.name = "Marmite_sauce"
	var pm := PlaneMesh.new()
	pm.size = Vector2(float(v[2]) * 1.9, float(v[2]) * 1.9)
	pm.subdivide_width = 96
	pm.subdivide_depth = 96
	pool.mesh = pm
	_marmite_mat = ShaderMaterial.new()
	_marmite_mat.shader = load(SAUCE)
	_marmite_mat.set_shader_parameter("mode", 0)
	_marmite_mat.set_shader_parameter("bubble_scale", 1.6)
	pool.material_override = _marmite_mat
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pool)
	pool.global_position = cratere_c
	# la vapeur qui monte de la Marmite
	_vapeur = Decor.smoke(self, cratere_c - global_position + Vector3.UP * 0.5, 40, 2.4, 6.0)
	_vapeur.visibility_aabb = AABB(Vector3(-20, -2, -20), Vector3(40, 60, 40))
	# la gerbe des éruptions (des gouttes de sauce qui jaillissent)
	_gerbe = _make_gerbe()
	_gerbe.global_position = cratere_c
	# le belvédère : une rambarde, la louche géante
	var b := Kit.Batch.new()
	var be: Vector3 = ile.spiral_end
	var to_c: Vector3 = Vector3(cratere_c.x - be.x, 0, cratere_c.z - be.z).normalized()
	var side: Vector3 = to_c.cross(Vector3.UP)
	var posts: Array = []
	for k in range(7):
		var pp: Vector3 = be + to_c * 2.6 + side * (k - 3) * 1.4
		pp.y = ile.height(pp.x, pp.z)
		b.cyl("bois", Transform3D(Basis(), pp), 0.07, 0.06, 1.1, 6, true)
		posts.append(pp + Vector3.UP * 1.0)
	for k2 in range(posts.size() - 1):
		b.tube("bois", posts[k2], posts[k2 + 1], 0.04, 5)
		b.tube("bois", (posts[k2] as Vector3) - Vector3.UP * 0.5, (posts[k2 + 1] as Vector3) - Vector3.UP * 0.5, 0.03, 5)
	_louche_at = be + side * 3.4 + to_c * 1.2
	_louche_at.y = ile.height(_louche_at.x, _louche_at.z)
	Kit.ladle(b, _louche_at, to_c, 5.0)
	b.commit(self, "Belvedere_de_la_Marmite")
	_avoid.append([Vector2(be.x, be.z), 6.0])
	# le panneau du cratère se pose au belvédère (voir _panneaux)
	# la goutte (pour les éruptions) et la tache qu'elle laisse
	var gm := SphereMesh.new()
	gm.radius = 0.5
	gm.height = 1.0
	gm.radial_segments = 16
	gm.rings = 8
	_goutte_mesh = gm
	_goutte_mat = ShaderMaterial.new()
	_goutte_mat.shader = load(SAUCE)
	_goutte_mat.set_shader_parameter("mode", 2)
	_goutte_mat.set_shader_parameter("bubble_scale", 0.2)
	_splat_tex = _make_splat()


func _make_gerbe() -> GPUParticles3D:
	var g := GPUParticles3D.new()
	g.name = "Gerbe_de_sauce"
	g.amount = 220
	g.lifetime = 3.4
	g.one_shot = false
	g.emitting = false
	g.explosiveness = 0.0
	g.visibility_aabb = AABB(Vector3(-60, -60, -60), Vector3(120, 120, 120))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 3.0
	pm.direction = Vector3.UP
	pm.spread = 16.0
	pm.initial_velocity_min = 14.0
	pm.initial_velocity_max = 26.0
	pm.gravity = Vector3(0, -9.8, 0)
	pm.scale_min = 0.4
	pm.scale_max = 1.1
	pm.angular_velocity_min = -90.0
	pm.angular_velocity_max = 90.0
	g.process_material = pm
	var sm := SphereMesh.new()
	sm.radius = 0.32
	sm.height = 0.55
	sm.radial_segments = 10
	sm.rings = 5
	var mat := ShaderMaterial.new()
	mat.shader = load(SAUCE)
	mat.set_shader_parameter("mode", 2)
	mat.set_shader_parameter("bubble_scale", 0.1)
	sm.material = mat
	g.draw_pass_1 = sm
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(g)
	return g


## La tache de sauce (une image : un pâté rouge aux bords irréguliers, des gouttelettes autour).
func _make_splat() -> Texture2D:
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 9711
	noise.frequency = 0.08
	var drops: Array = []
	for k in range(14):
		var a: float = _rng.randf() * TAU
		var r: float = _rng.randf_range(0.42, 0.8)
		drops.append([Vector2(0.5 + cos(a) * r * 0.5, 0.5 + sin(a) * r * 0.5), _rng.randf_range(0.015, 0.045)])
	for y in range(n):
		for x in range(n):
			var p := Vector2((x + 0.5) / n, (y + 0.5) / n)
			var d: float = p.distance_to(Vector2(0.5, 0.5))
			var ang: float = atan2(p.y - 0.5, p.x - 0.5)
			var edge: float = 0.3 + 0.07 * noise.get_noise_2d(cos(ang) * 20.0, sin(ang) * 20.0) + 0.04 * sin(ang * 7.0)
			var a2: float = 1.0 - smoothstep(edge - 0.03, edge, d)
			for dr in drops:
				a2 = maxf(a2, 1.0 - smoothstep(float(dr[1]) * 0.7, float(dr[1]), p.distance_to(dr[0])))
			var shade: float = 0.75 + 0.25 * noise.get_noise_2d(x * 2.0, y * 2.0)
			img.set_pixel(x, y, Color(0.5 * shade, 0.05 * shade, 0.025, a2))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------------- les rivières de sauce

func _rivieres() -> void:
	for f in ile.flows_world:
		var pts: Array = ile.flows_world[f]
		var wid: float = 4.2 if str(f) != "deversoir" else 2.8
		var raised: Array = []
		for p in pts:
			raised.append((p as Vector3) + Vector3.UP * 0.42)
		var mi: MeshInstance3D = _ribbon("Riviere_%s" % f, raised, wid, 0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# la Cascade Arrabbiata : au bout de la rivière du nord, la sauce tombe de la falaise dans la mer
	var nord: Array = ile.flows_world["nord"]
	var top: Vector3 = (nord[-1] as Vector3) + Vector3.UP * 0.42
	var prev: Vector3 = nord[-4]
	var out: Vector3 = Vector3(top.x - prev.x, 0, top.z - prev.z).normalized()
	var fall: Array = []
	var depth: float = top.y - IleScript.WATER
	for k in range(14):
		var t: float = float(k) / 13.0
		fall.append(top + out * (0.4 + 2.2 * sqrt(t)) - Vector3.UP * (depth + 0.3) * t)
	var cas: MeshInstance3D = _ribbon("Cascade_Arrabbiata", fall, 3.6, 1)
	cas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cascade_at = top + out * 2.6
	cascade_at.y = IleScript.WATER
	# le panache rouge dans la mer, au pied de la cascade, et au bout du déversoir
	_panache(cascade_at + out * 9.0, 30.0)
	var dv: Array = ile.flows_world["deversoir"]
	var dend: Vector3 = dv[-1]
	_panache(Vector3(dend.x + 6.0, IleScript.WATER, dend.z + 2.0), 18.0)
	# l'écume au pied de la cascade
	var sp := CPUParticles3D.new()
	sp.name = "Ecume_de_la_cascade"
	sp.amount = 60
	sp.lifetime = 1.4
	sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	sp.emission_box_extents = Vector3(1.8, 0.2, 1.2)
	sp.direction = Vector3.UP
	sp.spread = 40.0
	sp.initial_velocity_min = 2.0
	sp.initial_velocity_max = 4.5
	sp.gravity = Vector3(0, -9.8, 0)
	sp.scale_amount_min = 0.5
	sp.scale_amount_max = 1.2
	var dm := SphereMesh.new()
	dm.radius = 0.12
	dm.height = 0.24
	dm.radial_segments = 6
	dm.rings = 3
	dm.material = _goutte_mat
	sp.mesh = dm
	add_child(sp)
	sp.global_position = cascade_at + out * 1.0
	var vap: GPUParticles3D = Decor.smoke(self, cascade_at + out * 1.0 - global_position + Vector3.UP * 0.4, 18, 1.0, 3.0)
	vap.name = "Brume_de_la_cascade"
	# le Lac Napolitain : une grande nappe de sauce, calme
	var lac := MeshInstance3D.new()
	lac.name = "Lac_Napolitain"
	var pm := PlaneMesh.new()
	var lr: float = float(IleScript.LAC[2]) + 1.6
	pm.size = Vector2(lr * 2.0, lr * 2.0)
	pm.subdivide_width = 64
	pm.subdivide_depth = 64
	lac.mesh = pm
	var lm := ShaderMaterial.new()
	lm.shader = load(SAUCE)
	lm.set_shader_parameter("mode", 1)
	lm.set_shader_parameter("bubble_scale", 1.2)
	lac.material_override = lm
	lac.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lac)
	lac.global_position = IleScript.W(float(IleScript.LAC[0]), float(IleScript.LAC[1]), ile.lac_level)


## Un ruban le long d'une suite de points (UV.x : en travers, de 0 à 1 ; UV.y : le long, en mètres).
func _ribbon(label: String, pts: Array, wid: float, mode: int) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var acc: float = 0.0
	var rows: Array = []
	for i in range(pts.size()):
		var a: Vector3 = pts[maxi(i - 1, 0)]
		var c: Vector3 = pts[mini(i + 1, pts.size() - 1)]
		var t: Vector3 = (c - a).normalized()
		var side: Vector3 = Vector3(t.x, 0, t.z).cross(Vector3.UP).normalized() if mode == 0 else Vector3(t.x, 0, t.z).normalized().cross(Vector3.UP).normalized()
		if side.length() < 0.5:
			side = Vector3.RIGHT
		var n: Vector3 = side.cross(t).normalized() if mode == 1 else Vector3.UP
		if n.y < 0.0 and mode == 0:
			n = -n
		if i > 0:
			acc += (pts[i] as Vector3).distance_to(pts[i - 1])
		var p: Vector3 = pts[i]
		var w: float = wid * (1.0 if mode == 0 else lerpf(0.75, 1.25, float(i) / (pts.size() - 1)))
		rows.append([p - side * w * 0.5, p + side * w * 0.5, n, acc])
	for i in range(rows.size() - 1):
		var r0: Array = rows[i]
		var r1: Array = rows[i + 1]
		var quad: Array = [[r0[0], Vector2(0, r0[3]), r0[2]], [r0[1], Vector2(1, r0[3]), r0[2]], [r1[1], Vector2(1, r1[3]), r1[2]], [r1[0], Vector2(0, r1[3]), r1[2]]]
		var face: Vector3 = ((quad[1][0] as Vector3) - (quad[0][0] as Vector3)).cross((quad[2][0] as Vector3) - (quad[0][0] as Vector3))
		var order: Array = [0, 2, 1, 0, 3, 2] if face.dot(r0[2]) > 0.0 else [0, 1, 2, 0, 2, 3]
		for k in order:
			st.set_uv(quad[k][1])
			st.set_normal(quad[k][2])
			st.add_vertex(quad[k][0])
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.name = label
	mi.mesh = st.commit()
	var m := ShaderMaterial.new()
	m.shader = load(SAUCE_FLOT)
	m.set_shader_parameter("mode", mode)
	m.set_shader_parameter("speed", 0.55 if mode == 0 else 0.5)
	mi.material_override = m
	_flot_mats.append(m)
	add_child(mi)
	return mi


func _panache(at: Vector3, size: float) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Panache_de_sauce"
	var pm := PlaneMesh.new()
	pm.size = Vector2(size, size)
	mi.mesh = pm
	var m := ShaderMaterial.new()
	m.shader = load(SAUCE_FLOT)
	m.set_shader_parameter("mode", 2)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = at + Vector3.UP * 0.04


# ------------------------------------------------------------------- les champs, le séchoir, la tomateraie

func _champs() -> void:
	var b := Kit.Batch.new()
	# le Séchoir à pâtes : quatre séchoirs, une table à nappe, des sacs de farine, une meule
	var sc: Array = IleScript.PADS["sechoir"]
	var c := Vector2(float(sc[0]), float(sc[1]))
	_sechoir_at = _ground(c.x, c.y)
	var rr := RandomNumberGenerator.new()
	rr.seed = 9741
	for k in range(4):
		var off := Vector2(-4.5 + (k % 2) * 9.0, -2.6 + (k / 2) * 5.2)
		var at: Vector3 = _ground(c.x + off.x, c.y + off.y)
		var yaw: float = 0.25 + rr.randf_range(-0.05, 0.05)
		Kit.drying_rack(b, Transform3D(Basis(Vector3.UP, yaw), at), 3.0, rr)
		_col(Transform3D(Basis(Vector3.UP, yaw), at + Vector3.UP * 1.1), Vector3(3.2, 2.2, 1.4))
	var tb: Vector3 = _ground(c.x + 0.5, c.y + 6.5)
	b.box("bois", Transform3D(Basis(Vector3.UP, 0.25), tb + Vector3.UP * 0.75), Vector3(2.6, 0.08, 1.2))
	b.box("nappe", Transform3D(Basis(Vector3.UP, 0.25), tb + Vector3.UP * 0.8), Vector3(2.7, 0.02, 1.3))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			b.box("bois", Transform3D(Basis(Vector3.UP, 0.25), tb + Basis(Vector3.UP, 0.25) * Vector3(sx * 1.15, 0.37, sz * 0.5)), Vector3(0.08, 0.74, 0.08))
	# des nids de tagliatelles sur la table
	for k2 in range(5):
		var np: Vector3 = tb + Basis(Vector3.UP, 0.25) * Vector3(-0.9 + k2 * 0.45, 0.84, 0.15)
		for ring in range(3):
			var pts: Array = []
			for s in range(9):
				var a: float = TAU * s / 8.0 + ring
				pts.append(np + Vector3(cos(a) * (0.1 - ring * 0.02), 0.02 + ring * 0.025, sin(a) * (0.1 - ring * 0.02)))
			b.noodle("pates_seches", pts, 0.012, [], 4)
	_col(Transform3D(Basis(Vector3.UP, 0.25), tb + Vector3.UP * 0.4), Vector3(2.7, 0.8, 1.3))
	for k3 in range(4):
		var sp: Vector3 = _ground(c.x - 5.5 + k3 * 0.75, c.y + 6.8 + (k3 % 2) * 0.5)
		b.cyl("toile_creme", Transform3D(Basis(Vector3.UP, k3), sp), 0.3, 0.26, 0.75, 10, true)
		b.sphere("toile_creme", sp + Vector3.UP * 0.75, 0.24, 0.45, 5, 10)
	# la meule de pierre (pour moudre le blé)
	var mp: Vector3 = _ground(c.x + 6.5, c.y + 5.0)
	b.cyl("pierre", Transform3D(Basis(), mp), 1.2, 1.2, 0.45, 24, true)
	b.cyl("pierre", Transform3D(Basis(Vector3.FORWARD, PI * 0.5), mp + Vector3(0.25, 1.2, 0)), 0.75, 0.75, 0.5, 24, true)
	b.tube("bois", mp + Vector3.UP * 0.45, mp + Vector3.UP * 1.7, 0.06, 6)
	_col_cyl(mp, 1.2, 1.9)
	_avoid.append([Vector2(_sechoir_at.x, _sechoir_at.z), 11.0])
	# la Tomateraie : une petite clôture de piquets (les plants sont posés par la végétation)
	var tp: Array = IleScript.PADS["tomateraie"]
	_tomates_at = _ground(float(tp[0]), float(tp[1]))
	var r: float = float(tp[2]) - 0.5
	for k4 in range(28):
		var a2: float = TAU * k4 / 28.0
		if absf(wrapf(a2 - atan2(-0.3, -1.0), -PI, PI)) < 0.2:
			continue    # la porte, côté chemin
		var fp: Vector3 = _tomates_at + Vector3(cos(a2) * r, 0, sin(a2) * r)
		fp.y = ile.height(fp.x, fp.z)
		b.box("bois_clair", Transform3D(Basis(), fp + Vector3.UP * 0.45), Vector3(0.07, 0.9, 0.07))
		var a3: float = TAU * (k4 + 1) / 28.0
		var fq: Vector3 = _tomates_at + Vector3(cos(a3) * r, 0, sin(a3) * r)
		fq.y = ile.height(fq.x, fq.z)
		b.tube("bois_clair", fp + Vector3.UP * 0.7, fq + Vector3.UP * 0.7, 0.025, 4)
		b.tube("bois_clair", fp + Vector3.UP * 0.3, fq + Vector3.UP * 0.3, 0.025, 4)
	b.commit(self, "Sechoir_et_tomateraie")


# ------------------------------------------------------------------- la Plage du Parmesan

func _plage() -> void:
	var b := Kit.Batch.new()
	# un parasol vert-blanc-rouge, deux transats, une barque retournée
	var pa: Vector3 = _ground(-6.0, 140.0)
	b.tube("bois", pa, pa + Vector3.UP * 2.4, 0.035, 6)
	var keys: Array = ["toile_verte", "toile_blanche", "toile_rouge"]
	for k in range(12):
		var a0: float = TAU * k / 12.0
		var a1: float = TAU * (k + 1) / 12.0
		var tip: Vector3 = pa + Vector3.UP * 2.55
		var e0: Vector3 = pa + Vector3(cos(a0) * 1.5, 2.05, sin(a0) * 1.5)
		var e1: Vector3 = pa + Vector3(cos(a1) * 1.5, 2.05, sin(a1) * 1.5)
		b.tri(keys[k % 3], [tip, e0, e1], [Vector3.UP, Vector3.UP, Vector3.UP], [Vector2(0.5, 0), Vector2(0, 1), Vector2(1, 1)])
	for sx in [-1.0, 1.0]:
		var tp: Vector3 = _ground(-6.0 + sx * 1.4, 142.5)
		var bs := Basis(Vector3.UP, 0.1 * sx)
		b.box("bois_clair", Transform3D(bs, tp + Vector3.UP * 0.3), Vector3(0.65, 0.05, 1.3))
		b.box("toile_rouge" if sx < 0 else "toile_verte", Transform3D(bs * Basis(Vector3.RIGHT, -0.9), tp + bs * Vector3(0, 0.6, -0.75)), Vector3(0.62, 0.03, 0.8))
		for sz in [-0.55, 0.55]:
			b.box("bois_clair", Transform3D(bs, tp + bs * Vector3(0, 0.15, sz)), Vector3(0.65, 0.3, 0.05))
	var bt: Vector3 = _ground(44.0, 138.0)
	b.sphere("bois", bt + Vector3.UP * 0.35, 1.0, 0.45, 6, 16, Basis(Vector3.UP, 0.8) * Basis.from_scale(Vector3(2.4, 1.0, 1.0)) * Basis(Vector3.FORWARD, PI))
	_col(Transform3D(Basis(Vector3.UP, 0.8), bt + Vector3.UP * 0.4), Vector3(4.6, 0.8, 1.9))
	_avoid.append([Vector2(bt.x, bt.z), 3.5])
	b.commit(self, "Plage_du_Parmesan")


# ------------------------------------------------------------------- les panneaux

func _panneaux() -> void:
	var b := Kit.Batch.new()
	for e in PANNEAUX:
		var at: Vector3
		var face: Vector3
		if str(e[0]) == "cratere":
			var be: Vector3 = ile.spiral_end
			var away: Vector3 = Vector3(be.x - cratere_c.x, 0, be.z - cratere_c.z).normalized()
			at = be + away * 2.5 + away.cross(Vector3.UP) * 2.0
			at.y = ile.height(at.x, at.z)
			face = away
		else:
			at = _ground(float(e[1]), float(e[2]))
			var f2: Vector2 = (e[3] as Vector2).normalized()
			face = Vector3(f2.x, 0, f2.y)
		var xf := Transform3D(Basis(Vector3.UP, atan2(face.x, face.z)), at)
		Kit.sign_board(b, xf, 2.4, 1.35)
		var lb: Label3D = Kit.label(self, str(e[4]), at + Vector3.UP * 2.08 + face * 0.1, face, 0.003)
		lb.font_size = 40
		lb.width = 640.0
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panneaux.append({"id": str(e[0]), "at": at + face * 1.0, "texte": str(e[4]).replace("\n", " ")})
		_avoid.append([Vector2(at.x, at.z), 1.8])
	b.commit(self, "Panneaux_al_dente")


# =================================================================== les interactions

func _register_interactions() -> void:
	if _registered:
		return
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	_registered = true
	for j in range(panneaux.size()):
		var pn: Dictionary = panneaux[j]
		d._interactions.append({"id": "pasta_panneau_%s" % str(pn["id"]), "pos": pn["at"], "radius": 2.2,
			"text": "E : lire le panneau", "vr": "Gâchette : lire le panneau", "call": _lire.bind(j)})
	d._interactions.append({"id": "pasta_couvercle", "pos": _gong_at, "radius": 2.6,
		"text": "E : frapper le Couvercle Sacré", "vr": "Gâchette : frapper le Couvercle Sacré", "call": _couvercle})
	d._interactions.append({"id": "pasta_recommandations", "pos": _autel_at + (temple_c - _autel_at).normalized() * 2.2, "radius": 2.6,
		"text": "E : lire les Huit Recommandations", "vr": "Gâchette : lire les Huit Recommandations", "call": _recommandations})
	d._interactions.append({"id": "pasta_effigie", "pos": _fontaine_at, "radius": 6.0,
		"text": "E : lever les yeux vers le Grand Spaghetti Volant", "vr": "Gâchette : lever les yeux", "call": _lever_les_yeux})
	d._interactions.append({"id": "pasta_louche", "pos": _louche_at, "radius": 2.6,
		"text": "E : goûter la sauce avec la louche géante", "vr": "Gâchette : goûter la sauce", "call": _louche})
	d._interactions.append({"id": "pasta_spaghettis", "pos": _sechoir_at, "radius": 5.0,
		"text": "E : décrocher une botte de spaghettis", "vr": "Gâchette : décrocher des spaghettis", "call": _spaghettis})
	d._interactions.append({"id": "pasta_tomate", "pos": _tomates_at, "radius": 6.0,
		"text": "E : cueillir une tomate", "vr": "Gâchette : cueillir une tomate", "call": _tomate})
	# V98 : le Plat de la Grande Réconciliation, sur l'autel
	if ville != null:
		ville.register_interactions(d)


func _lire(j: int) -> void:
	var pn: Dictionary = panneaux[j]
	(state["panneaux"] as Dictionary)[str(pn["id"])] = true
	say("« " + str(pn["texte"]) + " »", 7.0)


func _couvercle() -> void:
	sfx("couvercle", _gong_at)
	state["couvercle"] = int(state.get("couvercle", 0)) + 1
	var n: int = int(state["couvercle"])
	_gong_hits.append(_clock)
	while not _gong_hits.is_empty() and _clock - float(_gong_hits[0]) > 12.0:
		_gong_hits.pop_front()
	_wiggle = maxf(_wiggle, 1.0)
	if _gong_hits.size() >= 3 and erupt_phase == "" and _next_erupt > 8.0:
		_gong_hits.clear()
		_next_erupt = 6.0
		say("BOOONG… BOOONG… BOOONG ! Le sol tremble un peu. Là-haut, le Mont Bolognaise se met à gronder… On dirait qu'il t'a entendu.", 7.0)
		return
	if n == 1:
		say("BOOONG ! Le grand couvercle de cuivre résonne dans tout le parvis. Au-dessus du temple, le Grand Spaghetti Volant frétille de toutes ses nouilles.", 7.0)
	else:
		say("BOOONG ! (Les adeptes disent qu'il ne faut pas le frapper trois fois de suite. Personne ne se souvient pourquoi.)", 6.0)


func _recommandations() -> void:
	state["recommandations"] = true
	say(RECOMMANDATIONS.replace("\n", " "), 12.0)


func _lever_les_yeux() -> void:
	var first: bool = not bool(state.get("effigie", false))
	state["effigie"] = true
	_wiggle = maxf(_wiggle, 1.2)
	_blink = 0.35
	if humeur_effigie < 0.5:
		# V98 : il boude (la quête « Le Grand Spaghetti boude »)
		say("Là-haut, au-dessus de la passoire, flotte le Grand Spaghetti Volant : une énorme pelote de spaghettis, deux boulettes, et deux yeux au bout de leurs tiges… à moitié fermés. Ses nouilles pendent. On dirait qu'il boude." if first
			else "Le Grand Spaghetti Volant entrouvre un œil, te regarde, et le referme. Il boude toujours. (Le Révérend Père Farfalle, au temple, saurait peut-être pourquoi.)", 8.0)
	else:
		say("Là-haut, au-dessus de la passoire, flotte le Grand Spaghetti Volant : une énorme pelote de spaghettis, deux boulettes, et deux yeux au bout de leurs tiges… qui te regardent. Il vient de cligner des yeux. Si, si." if first
			else "Le Grand Spaghetti Volant te fait un petit signe de nouille. (Personne ne sait comment il tient en l'air. Les adeptes disent : « par la sauce ! »)", 8.0)
	if first and main.has_method("jingle"):
		main.jingle("decouverte")


func _louche() -> void:
	if erupt_phase != "":
		say("Pas pendant une éruption ! La Marmite crache, recule un peu…", 5.0)
		return
	sfx("louche", _louche_at)
	var n: int = int(state.get("sauce", 0))
	state["sauce"] = n + 1
	if _clock - _sauce_t < 60.0 and n > 0:
		say("Encore ? Tu as déjà la bouche toute rouge. Attends un peu que la louche refroidisse.", 5.0)
		return
	_sauce_t = _clock
	var inv: Node = main.get("inventory_v28")
	if inv != null:
		inv.add("sauce_volcan", 1)
	say("Tu bascules la louche géante dans la Marmite, tu souffles longtemps, et tu goûtes… Mmmh ! Une sauce tomate parfaite : de l'ail, du basilic, une pointe de sucre. Tu en remplis un petit pot." if n == 0
		else "Tu remplis un petit pot de sauce du volcan. Elle est toujours aussi bonne.", 7.0)


func _spaghettis() -> void:
	if bool(state.get("spaghettis", false)):
		say("Les spaghettis qui restent ne sont pas encore secs. Il faut de la patience (et du soleil).", 5.0)
		return
	state["spaghettis"] = true
	sfx("ramasse_bois", _sechoir_at)
	var inv: Node = main.get("inventory_v28")
	if inv != null:
		inv.add("spaghettis_secs", 1)
	say("Tu décroches une botte de spaghettis bien secs : ils sont durs comme des baguettes et ils sentent bon le blé. (Recommandation n° 3 : ne pas les casser en deux.)", 7.0)


func _tomate() -> void:
	var n: int = int(state.get("tomates", 0))
	if n >= 3:
		say("Tu as déjà pris trois tomates. Il faut en laisser pour la sauce (et pour les autres).", 5.0)
		return
	state["tomates"] = n + 1
	sfx("ramasse_bois", _tomates_at)
	var inv: Node = main.get("inventory_v28")
	if inv != null:
		inv.add("tomate_coeur", 1)
	say("Tu cueilles une tomate cœur-de-bœuf, lourde et chaude de soleil. Elle sent le vert et l'été." if n == 0 else "Encore une belle tomate !", 6.0)


func say(text: String, seconds: float = 6.0) -> void:
	var d: Node = main.get("donjon_v35")
	if d != null and d.has_method("_say"):
		d._say(text, seconds)
	else:
		main._show_message_v28(text)


func sfx(name: String, at: Vector3) -> void:
	if main.has_method("sfx"):
		main.sfx(name, at)


# =================================================================== les éruptions

func is_erupting() -> bool:
	return erupt_phase != ""


func _update_eruption(delta: float, p: Vector3, near: bool) -> void:
	_next_erupt -= delta
	if erupt_phase == "" and _next_erupt <= 0.0:
		if not near:
			_next_erupt = 30.0
			return
		erupt_phase = "gronde"
		_erupt_t = 0.0
		sfx("eruption", cratere_c)
		var dc: float = Vector2(p.x - cratere_c.x, p.z - cratere_c.z).length()
		if dc < 40.0:
			say("Le sol tremble ! La Marmite bouillonne de plus en plus fort… Une éruption se prépare !", 5.0)
	if erupt_phase == "gronde":
		_erupt_t += delta
		_boil = minf(_boil + delta * 0.3, 1.0)
		if _erupt_t > 4.5:
			erupt_phase = "jaillit"
			_erupt_t = 0.0
			_gerbe.emitting = true
			for k in range(16):
				_launch_goutte(p)
			var dc2: float = Vector2(p.x - cratere_c.x, p.z - cratere_c.z).length()
			if dc2 < 260.0:
				state["eruptions"] = int(state.get("eruptions", 0)) + 1
				if int(state["eruptions"]) == 1:
					say("SPLOOOSH ! Le Mont Bolognaise crache sa sauce ! De grosses gouttes rouges montent très haut… et retombent partout sur ses pentes.", 7.0)
					if main.has_method("jingle"):
						main.jingle("decouverte")
	elif erupt_phase == "jaillit":
		_erupt_t += delta
		if _erupt_t > 1.2 and _erupt_t - delta <= 1.2:
			for k2 in range(10):
				_launch_goutte(p)
		if _erupt_t > 5.0:
			_gerbe.emitting = false
			erupt_phase = ""
			_next_erupt = _rng.randf_range(170.0, 280.0)
	else:
		_boil = maxf(_boil - delta * 0.08, 0.0)
	if _marmite_mat != null:
		_marmite_mat.set_shader_parameter("boil", _boil)
	var spd: float = 0.55 + 0.9 * _boil
	for m in _flot_mats:
		if int((m as ShaderMaterial).get_shader_parameter("mode")) == 0:
			(m as ShaderMaterial).set_shader_parameter("speed", spd)
	# les gouttes en vol
	var i: int = 0
	while i < _gouttes.size():
		var g: Dictionary = _gouttes[i]
		g["t"] = float(g["t"]) + delta
		var u: float = float(g["t"]) / float(g["dur"])
		var a: Vector3 = g["a"]
		var bq: Vector3 = g["b"]
		var pos: Vector3 = a.lerp(bq, u) + Vector3.UP * float(g["h"]) * 4.0 * u * (1.0 - u)
		var node: MeshInstance3D = g["node"]
		node.global_position = pos
		var vel: Vector3 = (bq - a) / float(g["dur"]) + Vector3.UP * float(g["h"]) * 4.0 * (1.0 - 2.0 * u) / float(g["dur"])
		if vel.length() > 0.1:
			var dirv: Vector3 = vel.normalized()
			var x: Vector3 = dirv.cross(Vector3.UP if absf(dirv.y) < 0.95 else Vector3.RIGHT).normalized()
			node.global_basis = Basis(x, dirv, x.cross(dirv)).scaled(Vector3(float(g["s"]), float(g["s"]) * 1.6, float(g["s"])))
		if u >= 1.0:
			_splat(bq, float(g["s"]), p)
			node.queue_free()
			_gouttes.remove_at(i)
			continue
		i += 1
	# les taches sèchent et s'effacent
	var j: int = 0
	while j < _taches.size():
		var tc: Dictionary = _taches[j]
		tc["age"] = float(tc["age"]) + delta
		var dcl: Decal = tc["decal"]
		var age: float = float(tc["age"])
		dcl.modulate = Color(1, 1, 1, 1.0 - smoothstep(90.0, 140.0, age))
		if age > 140.0:
			dcl.queue_free()
			_taches.remove_at(j)
			continue
		j += 1


func _launch_goutte(p: Vector3) -> void:
	var a: float = _rng.randf() * TAU
	var r: float = _rng.randf_range(14.0, 62.0)
	# un peu plus souvent vers le promeneur s'il est sur le volcan (c'est plus drôle)
	var dp: Vector2 = Vector2(p.x - cratere_c.x, p.z - cratere_c.z)
	if dp.length() < 70.0 and _rng.randf() < 0.25:
		a = atan2(dp.y, dp.x) + _rng.randf_range(-0.35, 0.35)
		r = clampf(dp.length() + _rng.randf_range(-8.0, 8.0), 14.0, 66.0)
	var land: Vector3 = Vector3(cratere_c.x + cos(a) * r, 0, cratere_c.z + sin(a) * r)
	land.y = ile.height(land.x, land.z)
	var node := MeshInstance3D.new()
	node.mesh = _goutte_mesh
	node.material_override = _goutte_mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	var start: Vector3 = cratere_c + Vector3(_rng.randf_range(-3, 3), 0.5, _rng.randf_range(-3, 3))
	node.global_position = start
	_gouttes.append({"node": node, "a": start, "b": land, "t": -_rng.randf_range(0.0, 0.8), "dur": _rng.randf_range(2.4, 3.6),
		"h": _rng.randf_range(16.0, 30.0) + maxf(start.y - land.y, 0.0) * 0.3, "s": _rng.randf_range(0.7, 1.5)})


func _splat(at: Vector3, s: float, p: Vector3) -> void:
	var dcl := Decal.new()
	dcl.texture_albedo = _splat_tex
	dcl.size = Vector3(3.2 * s, 3.0, 3.2 * s)
	dcl.upper_fade = 0.3
	dcl.lower_fade = 0.3
	dcl.cull_mask = 1
	add_child(dcl)
	dcl.global_position = at + Vector3.UP * 0.4
	dcl.rotation.y = _rng.randf() * TAU
	_taches.append({"decal": dcl, "age": 0.0})
	while _taches.size() > 40:
		var old: Dictionary = _taches.pop_front()
		(old["decal"] as Decal).queue_free()
	if Vector2(p.x - at.x, p.z - at.z).length() < 12.0:
		sfx("splotch", at)
	if Vector2(p.x - at.x, p.z - at.z).length() < 3.5 and absf(p.y - at.y) < 3.0:
		state["eclabousse"] = true
		say("SPLOTCH ! Une grosse goutte de sauce t'est tombée juste à côté… Tu es éclaboussé de la tête aux pieds. (Ça sent très bon.)", 6.0)


# =================================================================== services du jeu

func register_services(journal: Node) -> void:
	for k in objets:
		journal.lieux["pasta_" + str(k)] = objets[k]
	journal.lieux["pasta"] = respawn_point()[0]
	_register_interactions()


func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z) and p.y > -45.0


## Dans la sauce (le lac, la Marmite, les rivières) ?
func in_sauce(p: Vector3) -> bool:
	if ile == null:
		return false
	var lvl: float = ile.sauce_level(p.x, p.z)
	return lvl > -INF and p.y < lvl + 0.7


## À pied : sur la terre ferme, et pas dans la sauce (elle est brûlante).
func walkable(p: Vector3) -> bool:
	if not contains(p):
		return false
	if in_sauce(p):
		_hot_t = _clock
		return false
	return ile.height(p.x, p.z) > -0.3 or p.y > 1.0


func owns_point(p: Vector3) -> bool:
	return contains(p)


func zone_at(p: Vector3) -> String:
	if not contains(p):
		return ""
	var l: Vector2 = IleScript.L(p.x, p.z)
	var v: Array = IleScript.VOLCAN
	var vd: float = IleScript.volcan_d(l.x, l.y)
	if Vector2(p.x - temple_c.x, p.z - temple_c.z).length() < IleScript.PASSOIRE_R - 0.4 and p.y < temple_floor + 10.0:
		return "temple_dedans"
	if vd < float(v[2]) + 7.0 and p.y > float(v[6]) - 4.0:
		return "cratere"
	var tp: Array = IleScript.PADS["temple"]
	if l.distance_to(Vector2(float(tp[0]), float(tp[1]))) < float(tp[2]) + 2.0:
		return "temple"
	if l.distance_to(Vector2(float(IleScript.LAC[0]), float(IleScript.LAC[1]))) < float(IleScript.LAC[2]) + 9.0:
		return "lac"
	if cascade_at != Vector3.ZERO and Vector2(p.x - cascade_at.x, p.z - cascade_at.z).length() < 26.0:
		return "cascade"
	if vd < float(v[3]) - 6.0:
		return "volcan"
	# V98 : le Borgo des Coquillettes (les maisons, la piazzetta) et la Barque-Maison
	if l.distance_to(Vector2(-18.0, 72.0)) < 25.0:
		return "borgo"
	if l.distance_to(Ville.BARQUE) < 11.0:
		return "barque"
	if IleScript.champ_at(l.x, l.y) != "":
		return "champs"
	var sc: Array = IleScript.PADS["sechoir"]
	if l.distance_to(Vector2(float(sc[0]), float(sc[1]))) < 13.0:
		return "sechoir"
	var tm: Array = IleScript.PADS["tomateraie"]
	if l.distance_to(Vector2(float(tm[0]), float(tm[1]))) < float(tm[2]) + 2.0:
		return "tomateraie"
	if IleScript.beach_k(l.x, l.y) > 0.4 and IleScript.coast_q(l.x, l.y) > 0.82:
		return "plage"
	if l.x > 40.0 and l.y > 30.0:
		return "oliveraie"
	return "prairie"


func place_name(p: Vector3) -> String:
	return "L'Île Al Dente, " + str(PLACES.get(zone_at(p), "l'île"))


## Pour la téléportation : on arrive sur la Plage du Parmesan, au bout du ponton, face à l'île.
func village_point(_id: String) -> Array:
	return respawn_point()


func respawn_point() -> Array:
	var p: Vector3 = _ground(18.0, 142.0) + Vector3.UP * 0.3
	return [p, Vector3(0, 0, -1)]


func on_faint(_p: Vector3) -> void:
	var at: Array = respawn_point()
	main.place_player_v35(at[0], at[1])


func hour() -> float:
	var t: Node = main.get("temps_v56")
	return float(t.hour) if t != null else 12.0


func _process(delta: float) -> void:
	if main == null or ile == null:
		return
	_clock += delta
	var p: Vector3 = main._player_pos_v27()
	var dist: float = Vector2(p.x - IleScript.CENTER.x, p.z - IleScript.CENTER.z).length()
	var near: bool = dist < 700.0
	# le Grand Spaghetti Volant : il flotte, il tourne doucement, ses yeux suivent le promeneur
	if effigie != null and (near or dist < 1500.0):
		_wiggle = maxf(_wiggle - delta * 0.35, 0.0)
		# V98 : quand il boude, il pend un peu plus bas, il tourne à peine ; quand il fête, il danse
		_humeur_lisse = move_toward(_humeur_lisse, humeur_effigie, delta * 0.25)
		var hm: float = _humeur_lisse
		var bob: float = 0.9 + 1.6 * fete_k
		effigie.global_position = Vector3(temple_c.x + sin(_clock * 0.11) * 1.5, _effigie_y - (1.0 - hm) * 1.5 + sin(_clock * (0.45 + fete_k * 1.2)) * bob, temple_c.z + cos(_clock * 0.09) * 1.5)
		effigie.rotation = Vector3(sin(_clock * 0.3) * (0.04 + fete_k * 0.12), effigie.rotation.y + delta * (0.01 + 0.02 * hm + 0.9 * fete_k), cos(_clock * 0.27) * (0.04 + fete_k * 0.12))
		if _nouille_mat != null:
			_nouille_mat.set_shader_parameter("sway", 0.3 + 0.6 * hm + 1.6 * _wiggle)
		_blink -= delta
		if _blink < -_rng.randf_range(3.0, 7.0):
			_blink = 0.18
		for e in _eyes:
			var eye: Node3D = e[0]
			var to: Vector3 = p + Vector3.UP * 1.6
			if eye.global_position.distance_to(to) > 1.0:
				eye.look_at(to, Vector3.UP)
				eye.rotate_object_local(Vector3.UP, PI)
			eye.scale = Vector3(1.0, 0.12 if _blink > 0.0 else lerpf(0.42, 1.0, _humeur_lisse), 1.0)
	if near:
		_update_eruption(delta, p, dist < 450.0)
	if not ile.contains(p.x, p.z):
		return
	if _clock - _hot_t < 0.2 and _clock - _hot_msg_t > 9.0:
		_hot_msg_t = _clock
		say("Aïe ! Pas dans la sauce : elle est brûlante ! (Et en plus, ça tache.)", 4.0)
	if not bool(state["visite"]) and ile.height(p.x, p.z) > -0.2 and bool(main.get("game_started")):
		state["visite"] = true
		main._show_message_v28("L'Île Al Dente — l'île de la secte du Spaghetti Volant : un volcan qui crache de la sauce tomate, un temple en forme de passoire… et quelque chose qui flotte au-dessus")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	_zone_t -= delta
	if _zone_t > 0.0:
		return
	_zone_t = 1.0
	var h: float = hour()
	var night: bool = h < 6.5 or h > 19.5
	for e2 in _night_lights:
		(e2[0] as OmniLight3D).visible = night
	var lampe: StandardMaterial3D = Kit.mat("lampe")
	lampe.emission_energy_multiplier = 2.4 if night else 0.35
	var z: String = zone_at(p)
	var vis: Dictionary = state["visites"]
	if z == "temple_dedans":
		state["temple"] = true
	if z == "cratere":
		state["cratere"] = true
	if z == "lac":
		state["lac"] = true
	if z == "cascade":
		state["cascade"] = true
	if z in ["temple", "temple_dedans", "volcan", "cratere", "lac", "cascade", "champs", "sechoir", "tomateraie", "oliveraie", "borgo", "barque"] and not bool(vis.get(z, false)):
		vis[z] = true
		match z:
			"temple":
				main._show_message_v28("Le parvis du Temple-Passoire — une fourchette et une cuillère géantes, une fontaine de sauce… et, là-haut, le Grand Spaghetti Volant")
			"temple_dedans":
				main._show_message_v28("Le Temple-Passoire — le soleil passe par tous les trous de la passoire et fait pleuvoir de petites taches de lumière")
			"volcan":
				main._show_message_v28("Le Mont Bolognaise — un volcan de sauce tomate ; le chemin monte en tournant jusqu'à la Marmite")
			"cratere":
				main._show_message_v28("La Marmite — le cratère est plein de sauce tomate qui mijote : ça sent l'ail, le basilic et la tomate chaude")
			"lac":
				main._show_message_v28("Le Lac Napolitain — un lac de sauce tomate, calme et fumant (baignade interdite)")
			"cascade":
				main._show_message_v28("La Cascade Arrabbiata — la sauce tombe de la falaise dans la mer, qui devient toute rouge")
			"champs":
				main._show_message_v28("Les Champs de Blé Dur — le blé des pâtes ondule au vent")
			"sechoir":
				main._show_message_v28("Le Séchoir à pâtes — des rideaux de spaghettis sèchent au soleil")
			"tomateraie":
				main._show_message_v28("La Tomateraie — des tomates grosses comme le poing, rouges, chaudes de soleil")
			"oliveraie":
				main._show_message_v28("L'Oliveraie — de vieux oliviers tordus, et des cigales qui chantent")
			"borgo":
				main._show_message_v28("Le Borgo des Coquillettes — le hameau des adeptes : des maisons de toutes les couleurs, une treille, une grande table, et une odeur de pain chaud")
			"barque":
				main._show_message_v28("La Barque-Maison — une vieille barque retournée sur le sable, un mât, un drapeau… c'est la maison du Capitaine Rigatoni")
	# la surface vue d'en dessous suit le plongeur (la mer de l'île est loin du centre du monde)
	var mer: Node = main.get("mer_v55")
	if mer != null and mer.get("_underside") != null:
		(mer._underside as Node3D).global_position = Vector3(snappedf(p.x, 40.0), (mer._underside as Node3D).global_position.y, snappedf(p.z, 40.0))


func trouvailles() -> Dictionary:
	return {"pasta": 1 if bool(state.get("visite", false)) else 0,
		"pasta_temple": 1 if bool(state.get("temple", false)) else 0,
		"pasta_effigie": 1 if bool(state.get("effigie", false)) else 0,
		"pasta_couvercle": 1 if int(state.get("couvercle", 0)) > 0 else 0,
		"pasta_cratere": 1 if bool(state.get("cratere", false)) else 0,
		"pasta_sauce": 1 if int(state.get("sauce", 0)) > 0 else 0,
		"pasta_eruption": 1 if int(state.get("eruptions", 0)) > 0 else 0,
		"pasta_eclabousse": 1 if bool(state.get("eclabousse", false)) else 0,
		"pasta_cascade": 1 if bool(state.get("cascade", false)) else 0,
		"pasta_lac": 1 if bool(state.get("lac", false)) else 0,
		"pasta_recommandations": 1 if bool(state.get("recommandations", false)) else 0,
		"pasta_tomates": 1 if int(state.get("tomates", 0)) > 0 else 0,
		"pasta_offrande": 1 if bool(state.get("offrande", false)) else 0,
		"pasta_borgo": 1 if bool((state.get("visites", {}) as Dictionary).get("borgo", false)) else 0,
		"pasta_barque": 1 if bool((state.get("visites", {}) as Dictionary).get("barque", false)) else 0}


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	state = _fresh_state()
	for k in state:
		if d.has(k):
			state[k] = d[k] if not (d[k] is Dictionary) else (d[k] as Dictionary).duplicate(true)
