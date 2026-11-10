extends Node3D
## V127 : on marche jusque dans l'eau peu profonde (le rivage n'est plus un mur : on y entre et on en sort à la nage).
const RIVE_V127: float = -1.3
## V94 : Néopolis, la ville cyberpunk, au sud de l'archipel. Une grande dalle de béton sur la mer,
## quadrillée de rues, et des tours : jusqu'à 265 m pour la Tour Axiome, au centre. Les quartiers :
##   le Quai des Drones (au nord, où l'on accoste), le Boulevard des Néons (du quai au sud de la ville),
##   la Place des Hologrammes (trois carpes de lumière nagent dans le ciel), la Tour Axiome (son
##   ascenseur monte à la Terrasse du Ciel), le Marché de Nuit (les étals, les lanternes, le robot
##   des nouilles), le Quartier des Arcades (l'Arcade du Dragon-Pixel), les Ruelles (de vieux
##   immeubles serrés, des enseignes partout, de la vapeur), les Hauts (les tours de bureaux), les
##   Résidences, le Jardin Zen (des cerisiers, une fontaine de bambou).
## Au-dessus des rues, des voitures volantes filent sur leurs couloirs ; un monorail fait le tour de
## la ville sur son viaduc et s'arrête à quatre stations. Le soir, les fenêtres s'allument, les
## néons et les écrans brillent, et une petite pluie fait briller l'asphalte.
## (Les habitants et les androïdes arrivent avec la V95.)

const IleScript = preload("res://scripts/ile_neo_v94.gd")
const Kit = preload("res://scripts/neo_kit_v94.gd")

const Y0: float = IleScript.Y0
const PLACES := {"port": "le Quai des Drones", "front_de_mer": "le front de mer", "place": "la Place des Hologrammes",
	"axiome": "la Tour Axiome", "terrasse": "la Terrasse du Ciel", "marche": "le Marché de Nuit", "arcades": "le Quartier des Arcades",
	"ruelles": "les Ruelles", "hauts": "les Hauts", "residences": "les Résidences", "quai": "le Quartier du Quai",
	"jardin": "le Jardin Zen", "centre": "le centre-ville", "boulevard": "le Boulevard des Néons", "monorail": "le monorail"}
const MESSAGES := {
	"place": "La Place des Hologrammes — trois carpes de lumière nagent au-dessus des passants",
	"axiome": "La Tour Axiome — 265 mètres de verre ; son ascenseur monte à la Terrasse du Ciel",
	"terrasse": "La Terrasse du Ciel — à 150 mètres au-dessus des rues : toute la ville, la mer, et l'archipel au loin",
	"marche": "Le Marché de Nuit — des lanternes, des marmites qui fument, et un robot qui fait des nouilles",
	"arcades": "Le Quartier des Arcades — des écrans, des jeux, et des musiques en petits bips",
	"ruelles": "Les Ruelles — de vieux immeubles serrés, des enseignes partout, de la vapeur qui sort du sol",
	"hauts": "Les Hauts — les grandes tours de bureaux, leurs liserés de lumière, et les voitures qui filent entre elles",
	"residences": "Les Résidences — des immeubles d'habitation, des balcons, des citernes sur les toits",
	"jardin": "Le Jardin Zen — des cerisiers en fleurs, du gravier ratissé… et le silence, enfin",
	"boulevard": "Le Boulevard des Néons — la grande avenue de Néopolis, du quai jusqu'au sud de la ville",
}
## Les quartiers des îlots (i, j de -3 à 2) ; les autres îlots : voir _district()
const ILOTS := {"-1,-1": "place", "0,-1": "axiome", "-1,0": "marche", "0,0": "centre", "-1,1": "arcades", "0,1": "arcades",
	"-1,2": "arcades", "0,2": "arcades", "-1,-2": "quai", "0,-2": "quai", "-1,-3": "quai", "0,-3": "quai", "2,2": "jardin"}
## Les stations du monorail (une sur chaque côté de la boucle, 30 m après le milieu)
const STATIONS := ["la Station du Quai", "la Station des Hauts", "la Station des Arcades", "la Station des Ruelles"]
const RAIL_R: float = 180.0
const RAIL_RC: float = 10.0          # les coins de la boucle (assez serrés pour ne pas frôler les tours des coins)
const RAIL_Y: float = 10.0
const TOUR := Vector2(31.25, -30.0)
const Ville = preload("res://scripts/neo_ville_v95.gd")
const Virus = preload("res://scripts/virus_v96.gd")
const PRIX_VIRUS: int = 3

var main: Node
var ile: Node3D
var pc: bool = true
var state: Dictionary = {}
var objets: Dictionary = {}
var batiments: Array = []                 # {"rect": [x0, z0, x1, z1] (île), "h", "quartier", "style"}
var nb_boites: int = 0
var tours_mat: ShaderMaterial
var ecran_mats: Array = []
var holo_mats: Array = []
var _neon_mats: Dictionary = {}
var _cols: StaticBody3D
var _rng := RandomNumberGenerator.new()
var _lights: Array = []                   # [OmniLight3D, énergie]
var _koi: Array = []                      # [MeshInstance3D, rayon, vitesse, phase, hauteur]
var _holo_ring: MeshInstance3D
var _cars: Array = []                     # {"lane", "t", "speed"}
var _lanes: Array = []                    # {"o": Vector3 (monde), "d": Vector3, "y": float}
var _car_mm: Dictionary = {}
var _train: Array = []
var _train_s: float = 0.0
var _train_wait: float = 0.0
var _train_next: int = 0
var _rain: CPUParticles3D
var _kiosques: Array = []                 # les pieds des stations (monde) et leur face
var _distributeurs: Array = []
var _interactions: Array = []             # {"id", "pos", "radius", "text", "vr", "call"}
var _registered: bool = false
var _clock: float = 0.0
var _zone_t: float = 0.0
var _light_t: float = 0.0
var _car_sfx_t: float = 0.0
var night: float = 0.0
var lobby := Vector3.ZERO
var ville: Node3D                         # V95 : les rues, les lieux, les habitants, les passants
var virus: Node                           # V96 : le faux virus du « programme pas cher » de Monsieur Fil
var terrasse := Vector3.ZERO


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_rng.seed = 9494
	state = _fresh_state()


func _fresh_state() -> Dictionary:
	return {"visite": false, "visites": {}, "terrasse": false, "monorail": 0, "stations": {}, "sodas": 0, "nouilles": 0,
		"arcade": 0, "record": 0, "hologramme": 0, "zen": 0, "virus": 0, "virus_pas": 0}


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_neo_v94"
	add_child(ile)
	ile.build(pc)


func dock() -> Array:
	return [IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y), IleScript.W(IleScript.DOCK_B.x, IleScript.DOCK_B.y)]


func build_town() -> void:
	var t0: int = Time.get_ticks_msec()
	_layout()
	_towers()
	_axiome()
	_place()
	_marche()
	_arcade()
	_jardin()
	_port()
	_rues()
	_enseignes()
	_monorail()
	_voitures()
	_pluie()
	_accueil()
	objets["quai"] = _ground(0.0, -226.0)
	objets["place"] = _ground(-30.0, -14.0)
	objets["axiome"] = lobby
	objets["marche"] = _ground(-31.0, 30.0)
	objets["arcade"] = _ground(-8.0, 90.0)
	objets["ruelles"] = _ground(-120.0, 90.0)
	objets["jardin"] = _ground(150.0, 150.0)
	# V95 : la vie de la ville (les habitants arrivent avec les autres, voir main._spawn_azur_v56)
	ville = Ville.new()
	add_child(ville)
	ville.setup(main, self)
	ville.build()
	print("ILE_MANGA_V94: Néopolis est prête (%d tours, %d boîtes, %d ms)" % [batiments.size(), nb_boites, Time.get_ticks_msec() - t0])


func _ground(x: float, z: float) -> Vector3:
	var w: Vector3 = IleScript.W(x, z)
	w.y = ile.height(w.x, w.z)
	return w


func _col(xf: Transform3D, size: Vector3) -> void:
	if _cols == null:
		_cols = StaticBody3D.new()
		_cols.name = "Neo_collisions_v94"
		_cols.collision_layer = 1
		_cols.collision_mask = 0
		add_child(_cols)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	_cols.add_child(cs)
	cs.global_transform = xf


func _light(at: Vector3, col: Color, energy: float, rng: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.4
	l.shadow_enabled = false
	l.visible = false
	add_child(l)
	l.global_position = at
	_lights.append([l, energy])
	return l


## Le quartier d'un îlot
func _district(i: int, j: int) -> String:
	var k: String = "%d,%d" % [i, j]
	if ILOTS.has(k):
		return str(ILOTS[k])
	if i >= 1:
		return "hauts"
	return "residences" if j <= -1 else "ruelles"


# =================================================================== les tours

var _xfs: Array = []
var _customs: Array = []
var _roof_b: Kit.Batch


## Une boîte de façade (repère île ; du bas y0 au haut y1, au-dessus de la mer)
func _boite(x0: float, z0: float, x1: float, z1: float, y0: float, y1: float, style: int, hue: float, lit: float) -> void:
	var c: Vector3 = IleScript.W((x0 + x1) * 0.5, (z0 + z1) * 0.5, (y0 + y1) * 0.5)
	var s := Vector3(x1 - x0, y1 - y0, z1 - z0)
	var xf := Transform3D(Basis().scaled(s), c)
	_xfs.append(xf)
	_customs.append(Color(_rng.randf(), style / 4.0, hue, lit))
	_col(Transform3D(Basis(), c), s)
	nb_boites += 1


## Une tour : un socle (au besoin), un fût, des retraits, et ce qu'il y a sur le toit.
func _tour(r: Array, h: float, style: int, quartier: String, socle: bool) -> void:
	h = minf(h, 198.0)                    # la Tour Axiome reste la plus haute
	var x0: float = r[0]
	var z0: float = r[1]
	var x1: float = r[2]
	var z1: float = r[3]
	var hue: float = _rng.randf()
	var lit: float = _rng.randf_range(0.35, 0.75)
	var y: float = Y0
	if socle and h > 50.0:
		var hs: float = _rng.randf_range(7.0, 10.5)
		_boite(x0, z0, x1, z1, y, y + hs, 0 if style == 0 else 2, hue, lit)
		y += hs
		var ins: float = _rng.randf_range(3.0, 6.0)
		x0 += ins
		z0 += ins
		x1 -= ins
		z1 -= ins
	var top: float = Y0 + h
	var nseg: int = 1 if h < 45.0 else (2 if h < 110.0 else 3)
	for k in range(nseg):
		var yk: float = top if k == nseg - 1 else lerpf(y, top, _rng.randf_range(0.55, 0.75))
		_boite(x0, z0, x1, z1, y, yk, style, hue, lit)
		y = yk
		if k < nseg - 1:
			var sb: float = _rng.randf_range(2.0, 4.5)
			if x1 - x0 - 2.0 * sb > 8.0 and z1 - z0 - 2.0 * sb > 8.0:
				x0 += sb
				z0 += sb
				x1 -= sb
				z1 -= sb
	batiments.append({"rect": [float(r[0]), float(r[1]), float(r[2]), float(r[3])], "h": h, "quartier": quartier, "style": style, "hue": hue,
		"top": [x0, z0, x1, z1]})
	# le toit
	var cx: float = (x0 + x1) * 0.5
	var cz: float = (z0 + z1) * 0.5
	var roof: Vector3 = IleScript.W(cx, cz, top)
	if style == 1 or style == 3:
		if _rng.randf() < 0.6 and x1 - x0 > 7.0:
			Kit.water_tank(_roof_b, roof + Vector3((x1 - x0) * 0.22, 0, (z1 - z0) * 0.18))
		for k2 in range(_rng.randi_range(1, 3)):
			Kit.ac_unit(_roof_b, roof + Vector3(_rng.randf_range(-0.3, 0.3) * (x1 - x0), 0, _rng.randf_range(-0.3, 0.3) * (z1 - z0)), _rng.randf() * PI)
	elif h > 70.0:
		# une antenne, son feu rouge clignotant pour les voitures volantes
		var mh: float = _rng.randf_range(8.0, 22.0)
		_roof_b.cyl_at("metal", roof, 0.35, 0.12, mh, 8)
		_roof_b.blob("neon_rouge", roof + Vector3.UP * mh, Vector3(0.35, 0.35, 0.35), 8)
		Kit.ac_unit(_roof_b, roof + Vector3((x1 - x0) * 0.25, 0, 0), 0.0)


func _layout() -> void:
	_roof_b = Kit.Batch.new()
	for i in range(-3, 3):
		for j in range(-3, 3):
			var q: String = _district(i, j)
			if q in ["place", "axiome", "marche", "jardin"]:
				continue
			var r: Array = IleScript.block_rect(i, j)
			var c: Vector2 = IleScript.block_center(i, j)
			var dc: float = c.length()
			match q:
				"centre", "hauts":
					var hb: float = lerpf(215.0, 85.0, clampf((dc - 40.0) / 200.0, 0.0, 1.0))
					if _rng.randf() < 0.55:
						_tour(r, hb * _rng.randf_range(0.8, 1.15), 0 if _rng.randf() < 0.6 else 2, q, true)
					else:
						for part in _split2(r, 6.0):
							_tour(part, hb * _rng.randf_range(0.55, 1.0), 0 if _rng.randf() < 0.5 else 2, q, true)
				"residences", "quai":
					for part in (_split4(r, 6.0) if _rng.randf() < 0.5 else _split2(r, 6.0)):
						_tour(part, _rng.randf_range(32.0, 82.0) if q == "residences" else _rng.randf_range(24.0, 58.0), 1 if _rng.randf() < 0.75 else 3, q, false)
				"arcades":
					if i == -1 and j == 1:
						# l'Arcade du Dragon-Pixel tient le côté du boulevard (voir _arcade) ; derrière, deux immeubles
						_tour([r[0], r[1], r[0] + 14.0, r[3]], _rng.randf_range(26.0, 40.0), 1, q, false)
						continue
					for part in _split4(r, 5.0):
						_tour(part, _rng.randf_range(18.0, 46.0), 1 if _rng.randf() < 0.5 else 3, q, false)
				"ruelles":
					for part in _split3x3(r, 3.5):
						_tour(part, _rng.randf_range(10.0, 32.0), 3 if _rng.randf() < 0.75 else 1, q, false)


func _split2(r: Array, gap: float) -> Array:
	var x0: float = r[0]
	var z0: float = r[1]
	var x1: float = r[2]
	var z1: float = r[3]
	if _rng.randf() < 0.5:
		var xm: float = lerpf(x0, x1, _rng.randf_range(0.4, 0.6))
		return [[x0, z0, xm - gap * 0.5, z1], [xm + gap * 0.5, z0, x1, z1]]
	var zm: float = lerpf(z0, z1, _rng.randf_range(0.4, 0.6))
	return [[x0, z0, x1, zm - gap * 0.5], [x0, zm + gap * 0.5, x1, z1]]


func _split4(r: Array, gap: float) -> Array:
	var out: Array = []
	for a in _split2_axis(r, gap, true):
		for b in _split2_axis(a, gap, false):
			out.append(b)
	return out


func _split2_axis(r: Array, gap: float, on_x: bool) -> Array:
	var x0: float = r[0]
	var z0: float = r[1]
	var x1: float = r[2]
	var z1: float = r[3]
	if on_x:
		var xm: float = lerpf(x0, x1, _rng.randf_range(0.42, 0.58))
		return [[x0, z0, xm - gap * 0.5, z1], [xm + gap * 0.5, z0, x1, z1]]
	var zm: float = lerpf(z0, z1, _rng.randf_range(0.42, 0.58))
	return [[x0, z0, x1, zm - gap * 0.5], [x0, zm + gap * 0.5, x1, z1]]


func _split3x3(r: Array, gap: float) -> Array:
	var out: Array = []
	var w: float = (float(r[2]) - float(r[0]) - 2.0 * gap) / 3.0
	var d: float = (float(r[3]) - float(r[1]) - 2.0 * gap) / 3.0
	for a in range(3):
		for b in range(3):
			var x0: float = float(r[0]) + a * (w + gap)
			var z0: float = float(r[1]) + b * (d + gap)
			out.append([x0, z0, x0 + w, z0 + d])
	return out


## Toutes les boîtes en un seul MultiMesh, peint par gratte_ciel_v94
func _towers() -> void:
	tours_mat = ShaderMaterial.new()
	tours_mat.shader = load("res://shaders/gratte_ciel_v94.gdshader")
	tours_mat.set_shader_parameter("sol_y", Y0)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	mm.mesh = bm
	mm.instance_count = _xfs.size()
	for k in range(_xfs.size()):
		mm.set_instance_transform(k, _xfs[k])
		mm.set_instance_custom_data(k, _customs[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Neo_tours"
	mmi.multimesh = mm
	mmi.material_override = tours_mat
	add_child(mmi)
	_roof_b.commit(self, "Neo_toits")
	_xfs.clear()
	_customs.clear()


# =================================================================== la Tour Axiome

func _axiome() -> void:
	var r: Array = IleScript.block_rect(0, -1)
	var cx: float = (float(r[0]) + float(r[2])) * 0.5
	var cz: float = (float(r[1]) + float(r[3])) * 0.5
	_rng.seed = 9495
	# le socle (l'atrium), le fût, la terrasse, la couronne
	_boite(r[0], r[1], r[2], r[3], Y0, Y0 + 12.0, 0, 0.05, 0.7)
	_boite(cx - 14.0, cz - 14.0, cx + 14.0, cz + 14.0, Y0 + 12.0, Y0 + 150.0, 0, 0.05, 0.6)
	_boite(cx - 10.0, cz - 10.0, cx + 10.0, cz + 10.0, Y0 + 150.0, Y0 + 205.0, 0, 0.05, 0.55)
	_boite(cx - 6.0, cz - 6.0, cx + 6.0, cz + 6.0, Y0 + 205.0, Y0 + 225.0, 2, 0.05, 0.8)
	batiments.append({"rect": r, "h": 225.0, "quartier": "axiome", "style": 0, "hue": 0.05, "top": [cx - 6.0, cz - 6.0, cx + 6.0, cz + 6.0]})
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	mm.mesh = bm
	mm.instance_count = _xfs.size()
	for k in range(_xfs.size()):
		mm.set_instance_transform(k, _xfs[k])
		mm.set_instance_custom_data(k, _customs[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Tour_Axiome"
	mmi.multimesh = mm
	mmi.material_override = tours_mat
	add_child(mmi)
	_xfs.clear()
	_customs.clear()
	var b := Kit.Batch.new()
	# l'aiguille, et son feu
	var spire: Vector3 = IleScript.W(cx, cz, Y0 + 225.0)
	b.cyl_at("chrome", spire, 1.2, 0.15, 40.0, 10)
	b.blob("neon_rouge", spire + Vector3.UP * 40.0, Vector3(0.6, 0.6, 0.6), 8)
	# la terrasse : un garde-corps de verre (et ses montants), des bancs, une longue-vue
	var ty: float = Y0 + 150.0
	for e in [[Vector3(0, 0, -13.95), Vector3(28.0, 1.3, 0.1)], [Vector3(0, 0, 13.95), Vector3(28.0, 1.3, 0.1)],
			[Vector3(-13.95, 0, 0), Vector3(0.1, 1.3, 28.0)], [Vector3(13.95, 0, 0), Vector3(0.1, 1.3, 28.0)]]:
		var c: Vector3 = IleScript.W(cx, cz, ty + 0.65) + (e[0] as Vector3)
		b.box("verre", Transform3D(Basis(), c), e[1])
		b.box("chrome", Transform3D(Basis(), c + Vector3.UP * 0.68), (e[1] as Vector3) + Vector3(0.02, -1.22, 0.02))
		_col(Transform3D(Basis(), c + Vector3.UP * 0.3), (e[1] as Vector3) + Vector3(0.1, 0.6, 0.1))
	# le plancher de bois de la terrasse (un anneau autour du fût)
	for e2 in [[Vector3(0, 0, -12.0), Vector3(28.0, 0.06, 4.0)], [Vector3(0, 0, 12.0), Vector3(28.0, 0.06, 4.0)],
			[Vector3(-12.0, 0, 0), Vector3(4.0, 0.06, 20.0)], [Vector3(12.0, 0, 0), Vector3(4.0, 0.06, 20.0)]]:
		b.box("bois_clair", Transform3D(Basis(), IleScript.W(cx, cz, ty + 0.03) + (e2[0] as Vector3)), e2[1])
	for k in range(4):
		var a: float = TAU * k / 4.0
		var dir := Vector3(cos(a), 0, sin(a))
		Kit.bench(b, IleScript.W(cx, cz, ty) + dir * 12.0 + dir.cross(Vector3.UP) * 5.0, atan2(-dir.x, -dir.z) + PI)
	var lv: Vector3 = IleScript.W(cx, cz - 12.6, ty)
	b.cyl_at("metal_noir", lv, 0.08, 0.08, 1.2, 8)
	b.tube("metal", lv + Vector3(0, 1.25, 0.3), lv + Vector3(0, 1.4, -0.5), 0.09, 10)
	# l'entrée : une porte de lumière, côté boulevard
	lobby = _ground(float(r[0]) - 1.6, cz)
	var porte: Vector3 = IleScript.W(float(r[0]), cz, Y0)
	b.box("neon_cyan", Transform3D(Basis(), porte + Vector3(-0.05, 3.0, 0)), Vector3(0.1, 0.12, 5.2))
	b.box("verre_fume", Transform3D(Basis(), porte + Vector3(-0.03, 1.5, 0)), Vector3(0.06, 2.9, 5.0))
	b.commit(self, "Tour_Axiome_details")
	var lb := Label3D.new()
	lb.text = "TOUR AXIOME\nAscenseur — Terrasse du Ciel"
	lb.font_size = 64
	lb.pixel_size = 0.012
	lb.modulate = Color(0.7, 0.95, 1.0)
	lb.outline_size = 8
	lb.outline_modulate = Color(0.0, 0.1, 0.2)
	add_child(lb)
	lb.global_position = porte + Vector3(-0.2, 4.4, 0)
	lb.global_rotation = Vector3(0, -PI * 0.5, 0)
	terrasse = IleScript.W(cx, cz - 12.0, ty + 0.05)
	_interactions.append({"id": "neo_ascenseur_bas", "pos": lobby, "radius": 2.6, "text": "E : prendre l'ascenseur (Terrasse du Ciel)",
		"vr": "Gâchette : prendre l'ascenseur", "call": _ascenseur.bind(true)})
	_interactions.append({"id": "neo_ascenseur_haut", "pos": terrasse, "radius": 2.4, "text": "E : redescendre dans la rue",
		"vr": "Gâchette : redescendre", "call": _ascenseur.bind(false)})
	_light(lobby + Vector3.UP * 3.0, Color(0.5, 0.9, 1.0), 2.0, 12.0)
	# l'anneau holographique autour de la couronne
	var tor := TorusMesh.new()
	tor.inner_radius = 12.6
	tor.outer_radius = 13.4
	tor.rings = 48
	tor.ring_segments = 8
	_holo_ring = MeshInstance3D.new()
	_holo_ring.name = "Anneau_Axiome"
	_holo_ring.mesh = tor
	_holo_ring.material_override = _holo_mat(Color(0.2, 0.85, 1.0), Color(1.0, 0.3, 0.85), 2.0)
	_holo_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_holo_ring)
	_holo_ring.global_position = IleScript.W(cx, cz, Y0 + 214.0)
	_rng.seed = 9496


func _holo_mat(c1: Color, c2: Color, force: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/hologramme_v94.gdshader")
	m.set_shader_parameter("couleur", c1)
	m.set_shader_parameter("couleur_bord", c2)
	m.set_shader_parameter("force", force)
	holo_mats.append(m)
	return m


# =================================================================== la Place des Hologrammes

const KOI_COULEURS := [[Color(1.0, 0.45, 0.15), Color(1.0, 0.9, 0.6)], [Color(0.2, 0.85, 1.0), Color(1.0, 0.35, 0.9)], [Color(1.0, 0.25, 0.6), Color(0.9, 0.9, 1.0)]]


func _place() -> void:
	var c: Vector3 = _ground(IleScript.PLACE.x, IleScript.PLACE.y)
	var b := Kit.Batch.new()
	# l'émetteur : un socle, un anneau de lumière, une lentille
	b.cyl_at("metal_noir", c, 2.6, 2.2, 0.6, 24)
	b.cyl_at("neon_cyan", c + Vector3.UP * 0.6, 2.25, 2.25, 0.08, 24)
	b.blob("verre_fume", c + Vector3.UP * 0.8, Vector3(1.2, 0.5, 1.2), 12)
	_col(Transform3D(Basis(), c + Vector3.UP * 0.3), Vector3(5.0, 0.6, 5.0))
	# des bancs en cercle, des cerisiers dans leurs bacs
	for k in range(8):
		var a: float = TAU * (k + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		Kit.bench(b, c + d * 12.0, atan2(d.x, d.z))
	for k in range(4):
		var a2: float = TAU * k / 4.0 + PI * 0.25
		var p: Vector3 = c + Vector3(cos(a2), 0, sin(a2)) * 19.0
		b.box_at("beton_clair", p, Vector3(3.2, 0.6, 3.2))
		b.box_at("herbe", p + Vector3.UP * 0.6, Vector3(2.9, 0.02, 2.9))
		Kit.cherry(b, p + Vector3.UP * 0.6, _rng, 0.9)
		_col(Transform3D(Basis(), p + Vector3.UP * 0.3), Vector3(3.2, 0.6, 3.2))
	b.commit(self, "Place_des_Hologrammes")
	_light(c + Vector3.UP * 1.5, Color(0.3, 0.85, 1.0), 2.5, 16.0)
	var mesh: ArrayMesh = Kit.koi_mesh(9.0)
	for k in range(3):
		var mi := MeshInstance3D.new()
		mi.name = "Carpe_hologramme_%d" % k
		mi.mesh = mesh
		mi.material_override = _holo_mat(KOI_COULEURS[k][0], KOI_COULEURS[k][1], 1.5)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_koi.append([mi, 8.0 + k * 3.5, 0.22 - k * 0.04, TAU * k / 3.0, 9.0 + k * 4.0])
	_interactions.append({"id": "neo_hologramme", "pos": c + Vector3(0, 0, 3.2), "radius": 2.6, "text": "E : toucher la lentille de l'émetteur",
		"vr": "Gâchette : toucher l'émetteur", "call": _hologramme})


# =================================================================== le Marché de Nuit

func _marche() -> void:
	var r: Array = IleScript.block_rect(-1, 0)
	var b := Kit.Batch.new()
	var ax: float = (float(r[0]) + float(r[2])) * 0.5
	var toiles: Array = ["tissu_rouge", "tissu_bleu", "tissu_vert", "tissu_jaune"]
	var robot := Vector3.ZERO
	for side in [-1.0, 1.0]:
		var k: int = 0
		var z: float = float(r[1]) + 4.0
		while z < float(r[3]) - 3.0:
			var at: Vector3 = _ground(ax + side * 6.2, z)
			var face := Vector3(-side, 0, 0)
			var lamps: Array = Kit.stall(b, at, face, toiles[(k + (1 if side > 0 else 0)) % 4], 3.6)
			_col(Transform3D(Basis(), at + Vector3(0, 0.9, 0) - face * 0.15), Vector3(1.6, 1.8, 3.6))
			if k % 2 == 0:
				_light(lamps[1] + face * 0.6, Color(1.0, 0.65, 0.35), 4.5, 11.0)
			if side < 0.0 and k == 3:
				robot = at
			z += 4.4
			k += 1
	# les guirlandes de lanternes au-dessus de l'allée
	for k2 in range(6):
		var z2: float = float(r[1]) + 6.0 + k2 * 7.0
		var a: Vector3 = _ground(ax - 4.6, z2) + Vector3.UP * 3.4
		var c: Vector3 = _ground(ax + 4.6, z2) + Vector3.UP * 3.4
		b.tube("metal_noir", a, c, 0.012, 4)
		for q in range(6):
			var t: float = (q + 0.5) / 6.0
			var p: Vector3 = a.lerp(c, t) + Vector3.DOWN * sin(PI * t) * 0.5
			b.blob("lampe_chaude" if q % 2 == 0 else "neon_rose", p, Vector3(0.18, 0.22, 0.18), 8)
	# les tables, de chaque côté
	for side2 in [-1.0, 1.0]:
		for k3 in range(5):
			var tz: float = float(r[1]) + 6.0 + k3 * 8.5
			var tx: float = ax + side2 * 16.0
			Kit.table(b, _ground(tx, tz))
	# le robot des nouilles : un bras articulé au-dessus de sa marmite
	if robot != Vector3.ZERO:
		var base: Vector3 = robot + Vector3(0, 1.0, 0.0)
		b.cyl_at("peinture_jaune", base, 0.25, 0.22, 0.3, 12)
		var j1: Vector3 = base + Vector3(0.0, 0.9, 0.0)
		var j2: Vector3 = j1 + Vector3(0.7, 0.3, 0.0)
		b.tube("peinture_jaune", base, j1, 0.1, 8)
		b.tube("peinture_jaune", j1, j2, 0.08, 8)
		b.blob("metal_noir", j1, Vector3(0.14, 0.14, 0.14), 8)
		b.blob("ecran_bleu", j2 + Vector3(0.05, -0.1, 0), Vector3(0.12, 0.08, 0.12), 8)
		b.tube("chrome", j2, j2 + Vector3(0.2, -0.45, 0.0), 0.02, 4)
		_interactions.append({"id": "neo_nouilles", "pos": robot + Vector3(1.3, 0, 0), "radius": 2.2, "text": "E : demander un bol au robot des nouilles",
			"vr": "Gâchette : demander un bol", "call": _nouilles})
	b.commit(self, "Marche_de_Nuit")
	var lb := Label3D.new()
	lb.text = "MARCHÉ DE NUIT"
	lb.font_size = 96
	lb.pixel_size = 0.014
	lb.modulate = Color(1.0, 0.7, 0.35)
	lb.outline_size = 10
	lb.outline_modulate = Color(0.3, 0.05, 0.0)
	add_child(lb)
	lb.global_position = _ground(ax, float(r[1]) - 0.5) + Vector3.UP * 4.0
	lb.global_rotation = Vector3(0, PI, 0)
	var b2 := Kit.Batch.new()
	var g0: Vector3 = _ground(ax - 4.8, float(r[1]) - 0.3)
	var g1: Vector3 = _ground(ax + 4.8, float(r[1]) - 0.3)
	b2.box_at("rouge_laque", g0, Vector3(0.4, 4.6, 0.4))
	b2.box_at("rouge_laque", g1, Vector3(0.4, 4.6, 0.4))
	b2.box("rouge_laque", Transform3D(Basis(), (g0 + g1) * 0.5 + Vector3.UP * 4.7), Vector3(11.0, 0.35, 0.5))
	b2.commit(self, "Marche_portique")


# =================================================================== l'Arcade du Dragon-Pixel

var arcade_at := Vector3.ZERO


func _arcade() -> void:
	var r: Array = IleScript.block_rect(-1, 1)
	var x0: float = float(r[0]) + 17.0
	var x1: float = float(r[2])
	var z0: float = float(r[1]) + 6.0
	var z1: float = float(r[3]) - 6.0
	_boite(x0, z0, x1, z1, Y0, Y0 + 9.0, 1, 0.3, 0.9)
	batiments.append({"rect": [x0, z0, x1, z1], "h": 9.0, "quartier": "arcade", "style": 1, "hue": 0.3, "top": [x0, z0, x1, z1]})
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	mm.mesh = bm
	mm.instance_count = _xfs.size()
	for k in range(_xfs.size()):
		mm.set_instance_transform(k, _xfs[k])
		mm.set_instance_custom_data(k, _customs[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Arcade_batiment"
	mmi.multimesh = mm
	mmi.material_override = tours_mat
	add_child(mmi)
	_xfs.clear()
	_customs.clear()
	# la grande enseigne, côté boulevard, et deux bornes de jeu devant la porte
	var zm: float = (z0 + z1) * 0.5
	var face := Vector3(1, 0, 0)
	_sign_plat("arcade", IleScript.W(x1 + 0.12, zm, Y0 + 6.6), face, 9.0)
	var b := Kit.Batch.new()
	for k2 in [-1.0, 1.0]:
		var bp: Vector3 = _ground(x1 + 1.2, zm + k2 * 3.6)
		b.box("plastique_noir", Transform3D(Basis(Vector3.UP, PI * 0.5), bp + Vector3.UP * 0.9), Vector3(0.8, 1.8, 0.7))
		b.box("ecran_bleu", Transform3D(Basis(Vector3.UP, PI * 0.5).rotated(Vector3(0, 0, 1), -0.25), bp + Vector3(0.36, 1.35, 0)), Vector3(0.6, 0.45, 0.02))
		b.box("neon_rose", Transform3D(Basis(), bp + Vector3(0, 1.84, 0)), Vector3(0.8, 0.1, 0.72))
		_col(Transform3D(Basis(), bp + Vector3.UP * 0.9), Vector3(0.8, 1.8, 0.7))
	b.commit(self, "Arcade_bornes")
	arcade_at = _ground(x1 + 2.4, zm)
	_light(arcade_at + Vector3.UP * 2.5, Color(1.0, 0.3, 0.8), 2.2, 12.0)
	_interactions.append({"id": "neo_arcade", "pos": arcade_at, "radius": 2.4, "text": "E : jouer à Dragon-Pixel",
		"vr": "Gâchette : jouer à Dragon-Pixel", "call": _arcade_jeu})


# =================================================================== le Jardin Zen

var zen_at := Vector3.ZERO


func _jardin() -> void:
	var r: Array = IleScript.block_rect(2, 2)
	var b := Kit.Batch.new()
	var c: Vector3 = _ground((float(r[0]) + float(r[2])) * 0.5, (float(r[1]) + float(r[3])) * 0.5)
	var w: float = float(r[2]) - float(r[0])
	var d: float = float(r[3]) - float(r[1])
	b.box_at("gravier_zen", c + Vector3.DOWN * 0.02, Vector3(w - 1.0, 0.06, d - 1.0))
	# un muret tout autour, avec quatre entrées
	for e in [[Vector3(0, 0, -d * 0.5), Vector3(w, 0.9, 0.5)], [Vector3(0, 0, d * 0.5), Vector3(w, 0.9, 0.5)],
			[Vector3(-w * 0.5, 0, 0), Vector3(0.5, 0.9, d)], [Vector3(w * 0.5, 0, 0), Vector3(0.5, 0.9, d)]]:
		var s: Vector3 = e[1]
		var o: Vector3 = e[0]
		var along_x: bool = s.x > s.z
		var l: float = s.x if along_x else s.z
		for half in [-1.0, 1.0]:
			var seg: float = l * 0.5 - 2.0
			var off: float = half * (2.0 + seg * 0.5)
			var cc: Vector3 = c + o + (Vector3(off, 0, 0) if along_x else Vector3(0, 0, off))
			var sz: Vector3 = Vector3(seg, 0.9, 0.5) if along_x else Vector3(0.5, 0.9, seg)
			b.box_at("pierre", cc, sz)
			_col(Transform3D(Basis(), cc + Vector3.UP * 0.45), sz)
	# l'étang, le petit pont rouge, la fontaine de bambou
	var etang: Vector3 = c + Vector3(-6.0, 0, 5.0)
	b.cyl_at("pierre", etang + Vector3.DOWN * 0.1, 7.2, 7.2, 0.18, 28)
	b.cyl_at("eau", etang + Vector3.UP * 0.06, 6.8, 6.8, 0.04, 28)
	for k in range(9):
		var t: float = k / 8.0
		var p: Vector3 = etang + Vector3(lerpf(-1.5, 1.5, 0.5), 0.1 + sin(PI * t) * 0.9, lerpf(-7.5, 7.5, t))
		b.box("rouge_laque", Transform3D(Basis(), p + Vector3.UP * 0.05), Vector3(2.0, 0.12, 1.9))
	b.cyl_at("ecorce", c + Vector3(9.0, 0, -8.0), 0.1, 0.1, 1.2, 8)
	b.tube("bois_clair", c + Vector3(8.5, 1.0, -8.0), c + Vector3(9.8, 0.6, -8.0), 0.08, 8)
	b.cyl_at("pierre", c + Vector3(10.0, 0, -8.0), 0.6, 0.5, 0.35, 12)
	zen_at = c + Vector3(9.0, 0, -6.6)
	# des cerisiers, des lanternes de pierre, des pierres levées
	for k2 in range(11):
		var a: float = TAU * k2 / 11.0 + 0.3
		var rr: float = _rng.randf_range(12.0, 18.0)
		var tp: Vector3 = c + Vector3(cos(a) * rr, 0, sin(a) * rr)
		if tp.distance_to(etang) < 8.5:
			continue
		Kit.cherry(b, tp, _rng, _rng.randf_range(0.9, 1.3))
	for k3 in range(4):
		var lp: Vector3 = c + Vector3([-10.0, 10.0, -14.0, 3.0][k3], 0, [-12.0, 12.0, -2.0, 14.0][k3])
		b.box_at("pierre", lp, Vector3(0.6, 0.9, 0.6))
		b.box_at("lampe_chaude", lp + Vector3.UP * 0.9, Vector3(0.5, 0.4, 0.5))
		b.box_at("pierre", lp + Vector3.UP * 1.3, Vector3(0.9, 0.18, 0.9))
		_light(lp + Vector3.UP * 1.1, Color(1.0, 0.7, 0.45), 1.2, 7.0)
	for k4 in range(3):
		var sp: Vector3 = c + Vector3(4.0 + k4 * 2.2, 0, -14.0 + k4 * 1.5)
		b.blob("pierre", sp + Vector3.UP * 0.5, Vector3(0.9, 0.7 + k4 * 0.3, 0.7), 8)
	b.commit(self, "Jardin_Zen")
	_interactions.append({"id": "neo_zen", "pos": zen_at, "radius": 2.0, "text": "E : écouter la fontaine de bambou",
		"vr": "Gâchette : écouter la fontaine", "call": _zen})


# =================================================================== le Quai des Drones

func _port() -> void:
	var b := Kit.Batch.new()
	var couleurs: Array = ["conteneur_orange", "conteneur_bleu", "conteneur_vert", "conteneur_rouge"]
	for side in [-1.0, 1.0]:
		for k in range(4):
			var x: float = side * (48.0 + k * 16.0)
			for lvl in range(1 + (k % 3)):
				var at: Vector3 = _ground(x, -206.0) + Vector3.UP * lvl * 2.62
				Kit.container(b, at, PI * 0.5 + (0.02 if lvl % 2 else -0.01), couleurs[(k + lvl + (2 if side > 0 else 0)) % 4])
			_col(Transform3D(Basis(), _ground(x, -206.0) + Vector3.UP * (1.31 * (1 + (k % 3)))), Vector3(2.45, 2.62 * (1 + (k % 3)), 12.0))
	# des bittes d'amarrage le long du quai, des bancs face à la mer
	for k2 in range(-6, 7):
		var bx: float = k2 * 26.0
		if absf(bx) < 12.0:
			continue
		var q: Vector3 = _ground(bx, -232.0)
		b.cyl_at("metal_noir", q, 0.3, 0.3, 0.5, 10)
		b.cyl_at("metal_noir", q + Vector3.UP * 0.5, 0.42, 0.42, 0.12, 10)
	for k3 in range(-3, 4):
		if k3 == 0:
			continue
		Kit.bench(b, _ground(k3 * 22.0 + 11.0, -222.0), PI)
	b.commit(self, "Quai_des_Drones")


# =================================================================== les rues

func _rues() -> void:
	var b := Kit.Batch.new()
	var n_light: int = 0
	var lamp_pts: Array = []
	for k in range(-3, 4):
		var w: Vector2 = IleScript.largeur(k)
		var s: float = -IleScript.ANNEAU + 16.0
		var side: float = 1.0
		while s < IleScript.ANNEAU - 4.0:
			var near: float = absf(s - round(s / IleScript.PAS) * IleScript.PAS)
			if near > 12.0:
				# une rue nord-sud (x = k * PAS) puis une rue est-ouest (z = k * PAS)
				lamp_pts.append([Vector2(k * IleScript.PAS + side * (w.x + 1.3), s), Vector3(-side, 0, 0)])
				lamp_pts.append([Vector2(s, k * IleScript.PAS + side * (w.x + 1.3)), Vector3(0, 0, -side)])
			s += 30.0
			side = -side
	for e in lamp_pts:
		var p: Vector2 = e[0]
		if maxf(absf(p.x), absf(p.y)) > IleScript.ANNEAU + 6.0:
			continue
		var at: Vector3 = _ground(p.x, p.y)
		var head: Vector3 = Kit.lamp_post(b, at, e[1])
		_col(Transform3D(Basis(), at + Vector3.UP * 1.5), Vector3(0.3, 3.0, 0.3))
		if n_light % 2 == 0:
			_light(head, Color(0.8, 0.9, 1.0), 11.0, 24.0)
		n_light += 1
	# la promenade : des réverbères tout autour, côté mer
	for k2 in range(48):
		var a: float = TAU * k2 / 48.0
		var dir := Vector2(cos(a), sin(a))
		var rr: float = 214.0 / pow(pow(absf(dir.x), 4.0) + pow(absf(dir.y), 4.0), 0.25)
		var p2: Vector2 = dir * rr
		if absf(p2.x) < 14.0 and p2.y < 0.0:
			continue
		var at2: Vector3 = _ground(p2.x, p2.y)
		var head2: Vector3 = Kit.lamp_post(b, at2, Vector3(-dir.x, 0, -dir.y))
		_col(Transform3D(Basis(), at2 + Vector3.UP * 1.5), Vector3(0.3, 3.0, 0.3))
		if k2 % 3 == 0:
			_light(head2, Color(0.8, 0.9, 1.0), 9.0, 22.0)
	# les distributeurs : au coin des rues, côté immeubles
	var coins: Array = [[-1, -2], [1, -2], [-2, -1], [1, -1], [-2, 1], [1, 1], [-1, 2], [2, 0], [-3, 0], [0, -3], [2, -2], [-2, 2], [0, 1], [-1, -3]]
	var couleurs: Array = ["plastique_rouge", "plastique_bleu", "peinture_blanche"]
	for q in range(coins.size()):
		var kx: int = coins[q][0]
		var kz: int = coins[q][1]
		var wx: Vector2 = IleScript.largeur(kx)
		var x: float = kx * IleScript.PAS + wx.y - 0.7
		var z: float = kz * IleScript.PAS + 12.0 + (q % 3) * 5.0
		var at3: Vector3 = _ground(x, z)
		var face := Vector3(-1, 0, 0)
		Kit.vending(b, at3, face, couleurs[q % 3])
		_col(Transform3D(Basis(), at3 + Vector3.UP * 0.95), Vector3(0.8, 1.9, 1.05))
		var ip: Vector3 = at3 + face * 1.2
		_distributeurs.append(ip)
		_interactions.append({"id": "neo_distributeur_%d" % q, "pos": ip, "radius": 1.6, "text": "E : prendre un Synthé-Soda",
			"vr": "Gâchette : prendre un Synthé-Soda", "call": _distributeur.bind(q)})
	# les Ruelles : des guirlandes d'ampoules et des lanternes au-dessus des passages entre les immeubles
	for i in [-3, -2]:
		for j in [0, 1, 2]:
			var r: Array = IleScript.block_rect(i, j)
			var gap: float = 3.5
			var w3: float = (float(r[2]) - float(r[0]) - 2.0 * gap) / 3.0
			var d3: float = (float(r[3]) - float(r[1]) - 2.0 * gap) / 3.0
			for a2 in range(2):
				var ax: float = float(r[0]) + (a2 + 1) * w3 + (a2 + 0.5) * gap
				var az: float = float(r[1]) + (a2 + 1) * d3 + (a2 + 0.5) * gap
				for t in range(4):
					var zz: float = lerpf(float(r[1]) + 3.0, float(r[3]) - 3.0, (t + 0.5) / 4.0)
					var xx: float = lerpf(float(r[0]) + 3.0, float(r[2]) - 3.0, (t + 0.5) / 4.0)
					_guirlande(b, _ground(ax - gap * 0.5, zz) + Vector3.UP * 4.2, _ground(ax + gap * 0.5, zz) + Vector3.UP * 4.4)
					_guirlande(b, _ground(xx, az - gap * 0.5) + Vector3.UP * 4.3, _ground(xx, az + gap * 0.5) + Vector3.UP * 4.1)
				for t2 in [0.2, 0.5, 0.8]:
					_light(_ground(ax, lerpf(float(r[1]), float(r[3]), t2)) + Vector3.UP * 3.6, Color(1.0, 0.62, 0.35) if t2 != 0.5 else Color(1.0, 0.4, 0.7), 2.4, 12.0)
				_light(_ground((float(r[0]) + float(r[2])) * 0.5, az) + Vector3.UP * 3.6, Color(1.0, 0.4, 0.7), 2.0, 12.0)
	b.commit(self, "Neo_rues")
	# de la vapeur qui sort des plaques d'égout (surtout dans les Ruelles)
	var Decor = load("res://scripts/decor_v53.gd")
	var vents: Array = [Vector2(-120, 30), Vector2(-150, 64), Vector2(-92, 120), Vector2(-130, 150), Vector2(-60, 92), Vector2(60, -60), Vector2(0, 30), Vector2(120, 90)]
	for k3 in range(vents.size() if pc else 4):
		var vp: Vector3 = _ground(vents[k3].x, vents[k3].y)
		Decor.smoke(self, vp - global_position, 18 if pc else 10, 2.4, 1.4)


## Une guirlande d'ampoules tendue entre deux murs
func _guirlande(b: Kit.Batch, a: Vector3, c: Vector3) -> void:
	b.tube("metal_noir", a, c, 0.01, 4)
	for q in range(5):
		var t: float = (q + 0.5) / 5.0
		var p: Vector3 = a.lerp(c, t) + Vector3.DOWN * sin(PI * t) * 0.35
		b.blob("lampe_chaude" if q % 2 == 0 else "neon_rose", p, Vector3(0.09, 0.12, 0.09), 6)


# =================================================================== les enseignes et les écrans

func _neon_mat(nom: String) -> ShaderMaterial:
	if _neon_mats.has(nom):
		return _neon_mats[nom]
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/ecran_v94.gdshader")
	var path: String = "res://assets/textures/neo/neon_%s.png" % nom
	if ResourceLoader.exists(path):
		m.set_shader_parameter("image", load(path))
	m.set_shader_parameter("ecran", false)
	m.set_shader_parameter("force", 2.8)
	m.set_shader_parameter("graine", float(_neon_mats.size()) * 0.37)
	_neon_mats[nom] = m
	ecran_mats.append(m)
	return m


func _ecran_mat(large: bool, graine: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/ecran_v94.gdshader")
	var path: String = "res://assets/textures/neo/%s.png" % ("ecrans_larges" if large else "ecrans_hauts")
	if ResourceLoader.exists(path):
		m.set_shader_parameter("image", load(path))
	m.set_shader_parameter("pages", 4.0)
	m.set_shader_parameter("duree_page", 8.0 + graine)
	m.set_shader_parameter("graine", float(graine) * 2.3)
	m.set_shader_parameter("force", 1.9)
	ecran_mats.append(m)
	return m


const PLATS := ["ramen", "hotel", "arcade", "ouvert", "karaoke", "nouilles", "cybercafe", "reparations", "the", "data", "jus", "pharmacie", "robots", "dumplings", "bijoux"]
const COLONNES := ["c_ramen", "c_neo", "c_game", "c_hotel", "c_cafe", "c_open"]


## Une enseigne à plat sur un mur (at : son centre ; face : vers la rue ; w : sa largeur)
func _sign_plat(nom: String, at: Vector3, face: Vector3, w: float = 4.2) -> void:
	var q := QuadMesh.new()
	q.size = Vector2(w, w * 0.25)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = _neon_mat(nom)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_transform = Transform3D(Basis(Vector3.UP, atan2(face.x, face.z)), at)


## Une enseigne en drapeau (perpendiculaire au mur : on la lit des deux côtés de la rue)
func _sign_drapeau(b: Kit.Batch, nom: String, at: Vector3, along: Vector3) -> void:
	var yaw: float = atan2(along.x, along.z)
	b.box("metal_noir", Transform3D(Basis(Vector3.UP, yaw), at), Vector3(1.08, 4.1, 0.1))
	for sg in [1.0, -1.0]:
		var q := QuadMesh.new()
		q.size = Vector2(1.0, 4.0)
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.material_override = _neon_mat(nom)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		mi.global_transform = Transform3D(Basis(Vector3.UP, yaw + (0.0 if sg > 0.0 else PI)), at + along * 0.06 * sg)


func _enseignes() -> void:
	var b := Kit.Batch.new()
	var n_plat: int = 0
	var n_ecr: int = 0
	var mats_l: Array = [_ecran_mat(true, 0), _ecran_mat(true, 1), _ecran_mat(true, 2)]
	var mats_h: Array = [_ecran_mat(false, 0), _ecran_mat(false, 1), _ecran_mat(false, 2)]
	for bt in batiments:
		var r: Array = bt["rect"]
		var q: String = str(bt["quartier"])
		if q in ["axiome", "arcade"]:
			continue
		var x0: float = r[0]
		var z0: float = r[1]
		var x1: float = r[2]
		var z1: float = r[3]
		# les quatre côtés : [milieu, normale, longueur, direction le long du mur]
		var sides: Array = [[Vector2((x0 + x1) * 0.5, z0), Vector3(0, 0, -1), x1 - x0, Vector3(1, 0, 0)],
			[Vector2((x0 + x1) * 0.5, z1), Vector3(0, 0, 1), x1 - x0, Vector3(1, 0, 0)],
			[Vector2(x0, (z0 + z1) * 0.5), Vector3(-1, 0, 0), z1 - z0, Vector3(0, 0, 1)],
			[Vector2(x1, (z0 + z1) * 0.5), Vector3(1, 0, 0), z1 - z0, Vector3(0, 0, 1)]]
		for sd in sides:
			var mid: Vector2 = sd[0]
			var n: Vector3 = sd[1]
			var l: float = sd[2]
			var along: Vector3 = sd[3]
			# ce côté donne-t-il sur une rue (ou une ruelle, dans les Ruelles) ?
			var probe: Vector2 = mid + Vector2(n.x, n.z) * 2.4
			var rue: bool = IleScript.on_road(probe.x + n.x * 3.0, probe.y + n.z * 3.0)
			if not rue and q != "ruelles":
				continue
			var base: Vector3 = IleScript.W(mid.x, mid.y, Y0)
			var p_plat: float = 0.55 if q in ["ruelles", "arcades", "quai"] else 0.3
			if l > 6.0 and _rng.randf() < p_plat:
				var off: float = _rng.randf_range(-0.25, 0.25) * (l - 5.0)
				_sign_plat(PLATS[_rng.randi() % PLATS.size()], base + along * off + n * 0.1 + Vector3.UP * 5.2, n, minf(4.6, l - 1.0))
				n_plat += 1
			var p_drap: float = 0.6 if q == "ruelles" else (0.4 if q in ["arcades", "quai", "residences"] else 0.15)
			if l > 5.0 and _rng.randf() < p_drap:
				var off2: float = _rng.randf_range(-0.4, 0.4) * l
				var hy: float = _rng.randf_range(7.5, minf(14.0, float(bt["h"]) - 3.0))
				if hy > 7.0:
					_sign_drapeau(b, COLONNES[_rng.randi() % COLONNES.size()], base + along * off2 + n * 0.75 + Vector3.UP * hy, along)
					if _rng.randf() < 0.4:
						_light(base + along * off2 + n * 2.0 + Vector3.UP * (hy - 2.0), Kit.NEONS.values()[_rng.randi() % 6], 1.4, 9.0)
			# les grands écrans, sur les tours
			if rue and float(bt["h"]) > 55.0 and l > 16.0 and _rng.randf() < 0.32:
				var large: bool = _rng.randf() < 0.55
				var sz := Vector2(16.0, 8.0) if large else Vector2(7.0, 14.0)
				var ey: float = _rng.randf_range(18.0, minf(48.0, float(bt["h"]) - sz.y))
				if ey < 16.0:
					continue
				var ep: Vector3 = base + n * 0.35 + Vector3.UP * ey
				var qm := QuadMesh.new()
				qm.size = sz
				var mi := MeshInstance3D.new()
				mi.mesh = qm
				mi.material_override = (mats_l if large else mats_h)[n_ecr % 3]
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				add_child(mi)
				mi.global_transform = Transform3D(Basis(Vector3.UP, atan2(n.x, n.z)), ep)
				b.box("metal_noir", Transform3D(Basis(Vector3.UP, atan2(n.x, n.z)), ep - n * 0.2), Vector3(sz.x + 0.5, sz.y + 0.5, 0.3))
				n_ecr += 1
	b.commit(self, "Neo_enseignes", false)
	print("ILE_MANGA_V94: %d enseignes à plat, %d écrans" % [n_plat, n_ecr])


# =================================================================== le monorail

## Un point de la boucle du monorail (repère île) : [position (x, z), direction]
func rail(s: float) -> Array:
	var st: float = (RAIL_R - RAIL_RC) * 2.0
	var arc: float = PI * 0.5 * RAIL_RC
	var seg: float = st + arc
	s = fposmod(s, seg * 4.0)
	var k: int = int(s / seg)
	var u: float = s - k * seg
	var a := Vector2.ZERO
	var d := Vector2.ZERO
	# chaque côté : le départ et la direction ; le coin : son centre
	var starts: Array = [Vector2(-RAIL_R + RAIL_RC, -RAIL_R), Vector2(RAIL_R, -RAIL_R + RAIL_RC), Vector2(RAIL_R - RAIL_RC, RAIL_R), Vector2(-RAIL_R, RAIL_R - RAIL_RC)]
	var dirs: Array = [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]
	if u < st:
		a = (starts[k] as Vector2) + (dirs[k] as Vector2) * u
		d = dirs[k]
	else:
		var t: float = (u - st) / RAIL_RC
		var c: Vector2 = (starts[k] as Vector2) + (dirs[k] as Vector2) * st + (dirs[(k + 1) % 4] as Vector2) * RAIL_RC
		var r0: Vector2 = -(dirs[(k + 1) % 4] as Vector2)
		a = c + r0.rotated(t) * RAIL_RC
		d = (dirs[k] as Vector2).rotated(t)
	return [a, d]


## L'abscisse curviligne de la station k sur la boucle
func station_s(k: int) -> float:
	return k * ((RAIL_R - RAIL_RC) * 2.0 + PI * 0.5 * RAIL_RC) + (RAIL_R - RAIL_RC) + 30.0


func rail_length() -> float:
	return ((RAIL_R - RAIL_RC) * 2.0 + PI * 0.5 * RAIL_RC) * 4.0


func _monorail() -> void:
	var b := Kit.Batch.new()
	var L: float = rail_length()
	var y: float = Y0 + RAIL_Y
	var s: float = 0.0
	while s < L:
		var e0: Array = rail(s)
		var e1: Array = rail(minf(s + 6.0, L))
		var p0: Vector2 = e0[0]
		var p1: Vector2 = e1[0]
		var mid: Vector2 = (p0 + p1) * 0.5
		var dd: Vector2 = p1 - p0
		b.box("beton_clair", Transform3D(Basis(Vector3.UP, atan2(dd.x, dd.y)), IleScript.W(mid.x, mid.y, y - 0.55)), Vector3(1.3, 1.1, dd.length() + 0.12))
		s += 6.0
	var sp: float = 0.0
	while sp < L:
		var e: Array = rail(sp)
		var pp: Vector2 = e[0]
		var near_st: bool = false
		for k0 in range(STATIONS.size()):
			if absf(sp - station_s(k0)) < 8.0:
				near_st = true
		if not near_st:
			var g: Vector3 = _ground(pp.x, pp.y)
			b.cyl_at("beton_clair", g, 0.75, 0.6, y - 1.0 - g.y, 14)
			b.box("beton_clair", Transform3D(Basis(Vector3.UP, atan2((e[1] as Vector2).x, (e[1] as Vector2).y)), IleScript.W(pp.x, pp.y, y - 1.3)), Vector3(2.4, 0.7, 1.6))
			_col(Transform3D(Basis(), g + Vector3.UP * (y - g.y) * 0.5), Vector3(1.3, y - g.y, 1.3))
		sp += 36.0
	# les quatre stations : un quai en hauteur (côté mer), un toit, un escalier-tour, une borne
	for k in range(STATIONS.size()):
		var e2: Array = rail(station_s(k))
		var p2: Vector2 = e2[0]
		var d2: Vector2 = e2[1]
		var out := Vector2(-d2.y, d2.x)        # vers l'extérieur de la boucle (sens horaire)
		var yaw: float = atan2(d2.x, d2.y)
		var bs := Basis(Vector3.UP, yaw)
		var q0: Vector2 = p2 + out * 4.0
		b.box("beton_clair", Transform3D(bs, IleScript.W(q0.x, q0.y, y - 0.3)), Vector3(3.6, 0.5, 28.0))
		b.box("neon_cyan", Transform3D(bs, IleScript.W(q0.x, q0.y, y - 0.04) - Vector3(out.x, 0, out.y) * 1.72), Vector3(0.12, 0.04, 28.0))
		b.box("verre", Transform3D(bs, IleScript.W(q0.x, q0.y, y + 0.6) + Vector3(out.x, 0, out.y) * 1.75), Vector3(0.06, 1.2, 28.0))
		for z in [-12.0, 0.0, 12.0]:
			var pq: Vector3 = IleScript.W(q0.x, q0.y, y) + bs * Vector3(0, 0, z) + Vector3(out.x, 0, out.y) * 1.5
			b.box("metal_noir", Transform3D(bs, pq + Vector3.UP * 1.7), Vector3(0.15, 3.4, 0.15))
		b.box("metal_noir", Transform3D(bs.rotated(Vector3(d2.x, 0, d2.y), 0.0), IleScript.W(q0.x, q0.y, y + 3.5) - Vector3(out.x, 0, out.y) * 0.6), Vector3(5.5, 0.18, 30.0))
		for zz in [-14.5, 14.5]:
			var pg: Vector3 = IleScript.W(q0.x, q0.y, y - 0.3) + bs * Vector3(0, 0, zz)
			var gg: Vector3 = _ground(pg.x - IleScript.CENTER.x, pg.z - IleScript.CENTER.z)
			b.cyl_at("beton_clair", gg, 0.5, 0.5, pg.y - gg.y, 10)
			_col(Transform3D(Basis(), gg + Vector3.UP * (pg.y - gg.y) * 0.5), Vector3(1.0, pg.y - gg.y, 1.0))
		# l'escalier-tour (une cage de verre) et sa borne, au pied du quai
		var tq: Vector2 = p2 + out * 10.0 + d2 * 16.0
		var tg: Vector3 = _ground(tq.x, tq.y)
		b.box("verre_fume", Transform3D(bs, tg + Vector3.UP * (y - tg.y + 1.0) * 0.5), Vector3(3.2, y - tg.y + 1.0, 3.2))
		b.box("neon_cyan", Transform3D(bs, tg + Vector3.UP * (y - tg.y + 1.05)), Vector3(3.3, 0.1, 3.3))
		_col(Transform3D(bs, tg + Vector3.UP * (y - tg.y + 1.0) * 0.5), Vector3(3.2, y - tg.y + 1.0, 3.2))
		var kio: Vector3 = tg - Vector3(out.x, 0, out.y) * 2.6
		_kiosques.append([kio, -Vector3(out.x, 0, out.y)])
		_sign_plat("monorail", tg + Vector3.UP * 3.4 - Vector3(out.x, 0, out.y) * 1.64, -Vector3(out.x, 0, out.y), 3.0)
		_light(kio + Vector3.UP * 2.6, Color(0.7, 0.9, 1.0), 1.6, 9.0)
		_interactions.append({"id": "neo_monorail_%d" % k, "pos": kio, "radius": 2.4,
			"text": "E : prendre le monorail (vers %s)" % str(STATIONS[(k + 1) % 4]), "vr": "Gâchette : prendre le monorail",
			"call": _monorail_trajet.bind(k)})
	b.commit(self, "Monorail_viaduc")
	# le train : trois voitures
	var tb := Kit.Batch.new()
	Kit.monorail_car(tb)
	var mi0: MeshInstance3D = tb.commit(self, "Monorail_voiture_0")
	_train.append(mi0)
	for k3 in range(2):
		var mi := MeshInstance3D.new()
		mi.name = "Monorail_voiture_%d" % (k3 + 1)
		mi.mesh = mi0.mesh
		add_child(mi)
		_train.append(mi)
	_train_s = 40.0
	_place_train()


func _place_train() -> void:
	for k in range(_train.size()):
		var e: Array = rail(_train_s - (k - 1) * 12.6)
		var p: Vector2 = e[0]
		var d: Vector2 = e[1]
		(_train[k] as Node3D).global_transform = Transform3D(Basis(Vector3.UP, atan2(d.x, d.y)), IleScript.W(p.x, p.y, Y0 + RAIL_Y))


func _train_tick(delta: float) -> void:
	if _train.is_empty():
		return
	if _train_wait > 0.0:
		_train_wait -= delta
		return
	var target: float = station_s(_train_next)
	var gap: float = fposmod(target - _train_s, rail_length())
	var v: float = 15.0 * clampf(gap / 30.0, 0.18, 1.0)
	var step: float = v * delta
	if gap <= step:
		_train_s = target
		_train_wait = 8.0
		_train_next = (_train_next + 1) % STATIONS.size()
	else:
		_train_s = fposmod(_train_s + step, rail_length())
	_place_train()


# =================================================================== les voitures volantes

const CAR_COULEURS := [Color(0.92, 0.93, 0.95), Color(0.06, 0.06, 0.07), Color(0.75, 0.08, 0.1), Color(0.95, 0.75, 0.1), Color(0.1, 0.45, 0.7), Color(0.55, 0.2, 0.7)]


func _voitures() -> void:
	var alt_x: Array = [26.0, 40.0, 54.0, 30.0, 46.0, 60.0, 34.0]
	var alt_z: Array = [22.0, 36.0, 50.0, 28.0, 44.0, 58.0, 32.0]
	for k in range(-3, 4):
		var sgn: float = 1.0 if k % 2 == 0 else -1.0
		_lanes.append({"o": IleScript.W(k * IleScript.PAS + 1.8 * sgn, 0.0, Y0 + float(alt_x[k + 3])), "d": Vector3(0, 0, sgn)})
		_lanes.append({"o": IleScript.W(0.0, k * IleScript.PAS - 1.8 * sgn, Y0 + float(alt_z[k + 3])), "d": Vector3(-sgn, 0, 0)})
	var per_lane: int = 2 if pc else 1
	for li in range(_lanes.size()):
		for c in range(per_lane):
			_cars.append({"lane": li, "t": -280.0 + (c * 280.0) + _rng.randf_range(0.0, 140.0), "speed": _rng.randf_range(18.0, 30.0)})
	var meshes: Dictionary = Kit.car_meshes()
	var coque := StandardMaterial3D.new()
	coque.vertex_color_use_as_albedo = true
	coque.roughness = 0.18
	coque.metallic = 0.6
	var lueur := StandardMaterial3D.new()
	lueur.vertex_color_use_as_albedo = true
	lueur.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lueur.albedo_color = Color(2.5, 2.5, 2.5)
	var mats := {"coque": coque, "bulle": Kit.mat("verre_fume"), "phares": Kit.mat("phare"), "feux": Kit.mat("feu_arriere"), "lueur": lueur}
	for part in meshes:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = part in ["coque", "lueur"]
		mm.mesh = meshes[part]
		mm.instance_count = _cars.size()
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Voitures_" + str(part)
		mmi.multimesh = mm
		mmi.material_override = mats[part]
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if part == "coque" else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		mmi.global_position = Vector3.ZERO
		if mm.use_colors:
			for i in range(_cars.size()):
				mm.set_instance_color(i, CAR_COULEURS[i % CAR_COULEURS.size()] if part == "coque" else (Color(0.2, 0.9, 1.0) if i % 2 == 0 else Color(1.0, 0.3, 0.85)))
		_car_mm[part] = mm
	_cars_tick(0.0)


func car_pos(i: int) -> Vector3:
	var c: Dictionary = _cars[i]
	var ln: Dictionary = _lanes[int(c["lane"])]
	return (ln["o"] as Vector3) + (ln["d"] as Vector3) * float(c["t"])


func _cars_tick(delta: float) -> void:
	for i in range(_cars.size()):
		var c: Dictionary = _cars[i]
		c["t"] = float(c["t"]) + float(c["speed"]) * delta
		if float(c["t"]) > 300.0:
			c["t"] = -300.0
		var ln: Dictionary = _lanes[int(c["lane"])]
		var d: Vector3 = ln["d"]
		var t: float = float(c["t"])
		var p: Vector3 = (ln["o"] as Vector3) + d * t + Vector3.UP * sin(_clock * 0.7 + i) * 0.4
		var s: float = clampf((290.0 - absf(t)) / 30.0, 0.001, 1.0)
		var bs := Basis(Vector3.UP, atan2(d.x, d.z)).rotated(d, sin(_clock * 0.5 + i * 1.7) * 0.05).scaled(Vector3.ONE * s)
		var xf := Transform3D(bs, p)
		for part in _car_mm:
			(_car_mm[part] as MultiMesh).set_instance_transform(i, xf)


# =================================================================== la pluie, l'accueil

func _pluie() -> void:
	_rain = CPUParticles3D.new()
	_rain.name = "Pluie_de_Neopolis"
	_rain.amount = 900 if pc else 380
	_rain.lifetime = 1.2
	_rain.preprocess = 1.0
	_rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rain.emission_box_extents = Vector3(26.0, 0.5, 26.0)
	_rain.direction = Vector3(0.1, -1, 0.05)
	_rain.spread = 2.0
	_rain.initial_velocity_min = 13.0
	_rain.initial_velocity_max = 15.0
	_rain.gravity = Vector3(0, -2.0, 0)
	_rain.local_coords = false
	var rq := QuadMesh.new()
	rq.size = Vector2(0.016, 0.5)
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.75, 0.85, 1.0, 0.35)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	rm.disable_receive_shadows = true
	rq.material = rm
	_rain.mesh = rq
	_rain.emitting = false
	add_child(_rain)


## Au bout de la jetée, un grand panneau lumineux : le plan de la ville
func _accueil() -> void:
	var at: Vector3 = _ground(10.0, -224.0)
	var b := Kit.Batch.new()
	b.box_at("metal_noir", at, Vector3(0.3, 2.0, 0.3))
	b.box("metal_noir", Transform3D(Basis(), at + Vector3.UP * 3.4), Vector3(4.4, 2.8, 0.2))
	b.box("ecran_bleu", Transform3D(Basis(), at + Vector3(0, 3.4, -0.11)), Vector3(4.2, 2.6, 0.02))
	b.commit(self, "Neo_accueil")
	_col(Transform3D(Basis(), at + Vector3.UP * 2.4), Vector3(4.4, 4.8, 0.3))
	var lb := Label3D.new()
	lb.text = "NÉOPOLIS\n\nTout droit : le Boulevard des Néons, la Place des Hologrammes,\nla Tour Axiome (Terrasse du Ciel), le Marché de Nuit, les Arcades\nÀ l'ouest : les Ruelles   ·   À l'est : les Hauts, le Jardin Zen\nMonorail : 4 stations autour de la ville"
	lb.font_size = 40
	lb.pixel_size = 0.0055
	lb.modulate = Color(0.85, 0.97, 1.0)
	lb.outline_size = 0
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(lb)
	lb.global_position = at + Vector3(0, 3.4, -0.14)
	lb.global_rotation = Vector3(0, PI, 0)


# =================================================================== les interactions

func _register_interactions() -> void:
	if _registered:
		return
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	_registered = true
	for e in _interactions:
		d._interactions.append(e)


func _ascenseur(monter: bool) -> void:
	sfx("ascenseur_tour", lobby if monter else terrasse)
	if monter:
		say("Les portes de verre se ferment. L'ascenseur file vers le ciel : 50 étages, 100, 150… on sent ses oreilles se boucher. Ding !", 5.0)
	await get_tree().create_timer(0.9).timeout
	if monter:
		main.place_player_v35(terrasse + Vector3.UP * 0.3, Vector3(0, 0, -1))
		if not bool(state.get("terrasse", false)):
			state["terrasse"] = true
			main._show_message_v28(str(MESSAGES["terrasse"]))
			if main.has_method("jingle"):
				main.jingle("decouverte")
	else:
		main.place_player_v35(lobby + Vector3.UP * 0.3, Vector3(-1, 0, 0))
		say("Ding ! Rez-de-chaussée. Les néons du boulevard, le bruit des voitures… retour dans la rue.", 4.0)


func _monorail_trajet(k: int) -> void:
	var n: int = (k + 1) % _kiosques.size()
	sfx("monorail", _kiosques[k][0])
	say("Tu montes dans le monorail. Il glisse sans bruit au-dessus des rues, entre les tours… « Prochain arrêt : %s. »" % str(STATIONS[n]), 5.0)
	state["monorail"] = int(state.get("monorail", 0)) + 1
	(state["stations"] as Dictionary)[str(n)] = true
	await get_tree().create_timer(1.2).timeout
	var kp: Vector3 = _kiosques[n][0]
	main.place_player_v35(kp + Vector3.UP * 0.3 + (_kiosques[n][1] as Vector3) * 1.2, _kiosques[n][1])


const SODA_LIGNES := ["Clonk ! Une canette de Synthé-Soda tombe dans le bac. Elle est glacée, et elle brille un peu dans le noir.",
	"Le distributeur affiche : « Merci ! Bonne soirée, humain ! » Clonk ! Un Synthé-Soda.",
	"Bip, bip… clonk ! Synthé-Soda goût fruits de la Lune. Personne ne sait quel goût ont les fruits de la Lune.",
	"Le distributeur hésite, réfléchit, puis : clonk ! « Offert par la maison. » Il est sympa, ce distributeur."]


func _distributeur(q: int) -> void:
	var n: int = int(state.get("sodas", 0))
	state["sodas"] = n + 1
	sfx("distributeur", _distributeurs[q])
	var inv: Node = main.get("inventory_v28")
	if inv != null:
		inv.add("soda_neon", 1)
	say(str(SODA_LIGNES[(n + q) % SODA_LIGNES.size()]), 5.5)


func _nouilles() -> void:
	var n: int = int(state.get("nouilles", 0))
	state["nouilles"] = n + 1
	sfx("robot_nouilles", null)
	var inv: Node = main.get("inventory_v28")
	if inv != null:
		inv.add("nouilles_neo", 1)
	say("Le bras du robot plonge dans la marmite, tourne, égoutte, verse… « UN NÉO-RAMEN ! ATTENTION, C'EST CHAUD ! » Il fait même une petite révérence." if n == 0
		else "« ENCORE UN ? EXCELLENT CHOIX ! » Le robot te tend un bol fumant. Il a dessiné un smiley avec la sauce.", 6.0)


func _arcade_jeu() -> void:
	var n: int = int(state.get("arcade", 0)) + 1
	state["arcade"] = n
	sfx("arcade", arcade_at)
	var score: int = int(_rng.randi_range(12, 98)) * 100 + (3000 if n >= 3 else 0)
	var rec: int = int(state.get("record", 0))
	if score > rec:
		state["record"] = score
	if n == 1:
		say("Tu glisses une pièce. Le petit dragon de pixels saute, crache du feu… et tombe dans un trou. Score : %d. Pas mal, pour une première partie !" % score, 6.0)
	elif score > rec and n >= 3:
		say("Bip-bip-bip ! NOUVEAU RECORD : %d ! Le dragon fait une danse de la victoire. L'écran clignote en arc-en-ciel." % score, 6.0)
		if main.has_method("jingle"):
			main.jingle("decouverte")
	else:
		say("Le dragon saute, plane, crache du feu… Score : %d. Record : %d." % [score, maxi(rec, score)], 5.0)


const HOLO_PALETTES := [[[Color(1.0, 0.45, 0.15), Color(1.0, 0.9, 0.6)], [Color(0.2, 0.85, 1.0), Color(1.0, 0.35, 0.9)], [Color(1.0, 0.25, 0.6), Color(0.9, 0.9, 1.0)]],
	[[Color(0.3, 1.0, 0.5), Color(0.9, 1.0, 0.4)], [Color(0.3, 1.0, 0.5), Color(0.2, 0.7, 1.0)], [Color(0.9, 1.0, 0.4), Color(0.3, 1.0, 0.5)]],
	[[Color(0.7, 0.4, 1.0), Color(1.0, 0.6, 1.0)], [Color(1.0, 0.7, 0.2), Color(1.0, 0.3, 0.3)], [Color(0.3, 0.8, 1.0), Color(1.0, 1.0, 1.0)]]]


func _hologramme() -> void:
	var n: int = int(state.get("hologramme", 0)) + 1
	state["hologramme"] = n
	sfx("hologramme", null)
	var pal: Array = HOLO_PALETTES[n % HOLO_PALETTES.size()]
	for k in range(_koi.size()):
		var m: ShaderMaterial = (_koi[k][0] as MeshInstance3D).material_override
		m.set_shader_parameter("couleur", pal[k][0])
		m.set_shader_parameter("couleur_bord", pal[k][1])
	say("Tu poses la main sur la lentille. Bzzzt ! Les carpes changent de couleur et font un grand tour au-dessus de la place. Quelqu'un, quelque part, applaudit." if n == 1
		else "Bzzzt ! Nouvelles couleurs pour les carpes.", 5.0)


func _zen() -> void:
	var n: int = int(state.get("zen", 0)) + 1
	state["zen"] = n
	sfx("touche_bois", zen_at)
	say("Le bambou se remplit d'eau goutte à goutte, bascule… TOC ! Puis tout redevient calme. Au-dessus des cerisiers, les tours brillent, mais ici on n'entend presque plus la ville." if n == 1
		else "Goutte… goutte… TOC !", 6.0)


func say(text: String, seconds: float = 6.0) -> void:
	var d: Node = main.get("donjon_v35")
	if d != null and d.has_method("_say"):
		d._say(text, seconds)
	else:
		main._show_message_v28(text)


func sfx(name: String, at: Variant) -> void:
	if main.has_method("sfx"):
		main.sfx(name, at)


# =================================================================== services du jeu

func register_services(journal: Node) -> void:
	for k in objets:
		journal.lieux["neo_" + str(k)] = objets[k]
	journal.lieux["neo"] = respawn_point()[0]
	_register_interactions()
	# V96 : le programme pas cher de Monsieur Fil, et Glitch qui chasse le virus
	if virus == null:
		virus = Virus.new()
		virus.name = "Virus_v96"
		add_child(virus)
		virus.setup(main, self)
	journal.add_service("fil", Callable(self, "_fil_topics"), Callable(self, "_fil_choose"))
	journal.add_service("glitch", Callable(self, "_glitch_topics"), Callable(self, "_glitch_choose"))


# =================================================================== V96 : le « Turbo-Aventure 3000 »

func _virus_q() -> String:
	var j: Node = main.get("journal_v56")
	return str(j.state("ne_virus_fil")) if j != null else ""


func _fil_topics(_npc: Node) -> Array:
	var v: int = int(state.get("virus", 0))
	if v == 0:
		return [{"id": "q56:service:fil", "label": "✦ C'est quoi, votre programme exceptionnel ?"}]
	if _virus_q() == "finie":
		return [{"id": "q56:service:fil:encore", "label": "✦ Un nouveau programme, Monsieur Fil ?"}]
	if v == 1:
		return [{"id": "q56:service:fil:virus", "label": "✦ Monsieur Fil, mon carnet a attrapé un virus !"}]
	return []


func _fil_choose(_npc: Node, choice: String) -> Dictionary:
	match choice:
		"q56:service:fil":
			if int(state.get("virus", 0)) != 0:
				return {}
			return {"texte": "Ah ! Mon chef-d'œuvre ! Le Turbo-Aventure 3000 ! (Il fait briller sa tablette sous ton nez.) Il range ton sac tout seul, il trouve les trésors avant toi, il fait même tes devoirs. Enfin… presque. Je le copie directement dans ton carnet de voyage : ton carnet est magique, non ? Alors il est sûrement compatible. Et pour toi, seulement %d pièces ! Garanti sans virus. Enfin… garanti." % PRIX_VIRUS,
				"geste": "rire", "choix": [{"id": "q56:service:fil:acheter", "label": "D'accord, je le prends ! (%d pièces)" % PRIX_VIRUS}, {"id": "q56:service:fil:non", "label": "Hmm… non merci."}]}
		"q56:service:fil:acheter":
			if int(state.get("virus", 0)) != 0:
				return {}
			var n: int = mini(PRIX_VIRUS, int(main.inventory_v28.count("piece")))
			var t: String = "(Il branche un petit câble violet sur ton carnet de voyage.) Et… voilà ! Installation en cours. Ne t'inquiète pas si ça clignote un peu. C'est normal. C'est… prévu."
			if n == 0:
				t = "Pas une seule pièce ? Bon… pour toi, c'est offert ! Un cadeau de bienvenue. " + t
			elif n < PRIX_VIRUS:
				t = "Tu n'as que %d pièce%s ? Allez, ce sera le prix ! " % [n, "s" if n > 1 else ""] + t
			var r: Dictionary = {"texte": t, "geste": "rire", "_virus96": "start", "fin": true}
			if n > 0:
				r["prendre"] = [["piece", n]]
			return r
		"q56:service:fil:non":
			return {"texte": "Tant pis pour toi ! Enfin… tant mieux pour toi, peut-être. Hé hé. L'offre tient toujours !", "geste": "parle"}
		"q56:service:fil:virus":
			return {"texte": "Un virus ? Dans MES programmes ? Impossible ! Ils sont garantis. Garantis… quelque chose. (Il regarde ailleurs.) Va voir la petite Glitch : elle s'y connaît, en… en choses. Le matin et le soir, elle traîne près de la Station des Arcades ; l'après-midi, dans la salle d'arcade. Moi, j'ai un rendez-vous. Très loin. Tout de suite.", "geste": "parle"}
		"q56:service:fil:encore":
			return {"texte": "Ah non ! Fini, les programmes pas chers. Maintenant, Monsieur Fil vend des programmes vérifiés par Glitch. Elle n'en a encore vérifié aucun… alors je n'en vends aucun. Le commerce honnête, c'est très reposant.", "geste": "rire"}
	return {}


func _glitch_topics(_npc: Node) -> Array:
	if int(state.get("virus", 0)) == 1 and virus != null and not virus.opened:
		return [{"id": "q56:service:glitch:virus", "label": "✦ Glitch, aide-moi à chasser le virus de mon carnet !"}]
	return []


func _glitch_choose(_npc: Node, choice: String) -> Dictionary:
	if choice == "q56:service:glitch:virus" and int(state.get("virus", 0)) == 1:
		return {"texte": "Encore le virus de Fil ? Donne-moi ton carnet. (Elle branche un câble rose sur ton carnet et tape à toute vitesse.) Voilà : je t'ouvre le système. On reprend là où tu t'étais arrêté.", "geste": "parle", "_virus96": "resume", "fin": true}
	return {}


## Appelé par main après un échange réussi : l'achat du programme (le virus arrive), ou Glitch qui
## rouvre le système.
func after_reply(r: Dictionary, _npc: Node) -> void:
	if not r.has("_virus96") or virus == null:
		return
	var mode: String = str(r["_virus96"])
	main._close_dialogue_v31()
	if mode == "start":
		state["virus"] = 1
		state["virus_pas"] = 0
		var j: Node = main.get("journal_v56")
		if j != null:
			j.start_quest("ne_virus_fil")
	get_tree().create_timer(1.2 if mode == "start" else 0.6).timeout.connect(func():
		if virus != null and not virus.opened and int(state.get("virus", 0)) == 1:
			virus.begin(mode))


func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z) and p.y > -45.0


func walkable(p: Vector3) -> bool:
	if not contains(p):
		return false
	return ile.height(p.x, p.z) > RIVE_V127 or p.y > 1.0


func owns_point(p: Vector3) -> bool:
	return contains(p)


func zone_at(p: Vector3) -> String:
	if not contains(p):
		return ""
	var l: Vector2 = IleScript.L(p.x, p.z)
	if p.y > Y0 + 100.0 and l.distance_to(TOUR) < 22.0:
		return "terrasse"
	var m: float = maxf(absf(l.x), absf(l.y))
	if IleScript.coast_q(l.x, l.y) > 1.02 and not IleScript.in_jetee(l.x, l.y):
		return ""
	if m > IleScript.ANNEAU + 8.0:
		return "port" if l.y < -150.0 and absf(l.x) < 130.0 else "front_de_mer"
	if absf(l.x) < 9.5:
		return "boulevard"
	var i: int = clampi(int(floor(l.x / IleScript.PAS)), -3, 2)
	var j: int = clampi(int(floor(l.y / IleScript.PAS)), -3, 2)
	return _district(i, j)


func place_name(p: Vector3) -> String:
	return "Néopolis, " + str(PLACES.get(zone_at(p), "la ville"))


func village_point(_id: String) -> Array:
	return respawn_point()


func respawn_point() -> Array:
	var p: Vector3 = _ground(0.0, -228.0) + Vector3.UP * 0.3
	return [p, Vector3(0, 0, 1)]


func on_faint(_p: Vector3) -> void:
	var at: Array = respawn_point()
	main.place_player_v35(at[0], at[1])


func hour() -> float:
	var t: Node = main.get("temps_v56")
	return float(t.hour) if t != null else 12.0


## 0 le jour, 1 la nuit (le soir monte de 18 h à 20 h ; le matin, de 5 h à 7 h)
func night_k(h: float) -> float:
	if h >= 12.0:
		return clampf((h - 18.0) / 2.0, 0.0, 1.0)
	return clampf((7.0 - h) / 2.0, 0.0, 1.0)


func is_raining() -> bool:
	var h: float = hour()
	return h >= 21.0 or h < 4.5


func _process(delta: float) -> void:
	if main == null or ile == null:
		return
	_clock += delta
	var p: Vector3 = main._player_pos_v27()
	var near_city: bool = Vector2(p.x - IleScript.CENTER.x, p.z - IleScript.CENTER.z).length() < 900.0
	if not near_city:
		return
	_cars_tick(delta)
	_train_tick(delta)
	for k in _koi:
		var mi: MeshInstance3D = k[0]
		var a: float = float(k[3]) + _clock * float(k[2])
		var c: Vector3 = IleScript.W(IleScript.PLACE.x, IleScript.PLACE.y, Y0 + float(k[4]) + sin(_clock * 0.6 + float(k[3])) * 2.0)
		var rr: float = k[1]
		var pos: Vector3 = c + Vector3(cos(a), 0, sin(a)) * rr
		var tang := Vector3(-sin(a), 0, cos(a))
		mi.global_transform = Transform3D(Basis(Vector3.UP, atan2(-tang.z, tang.x)).rotated(Vector3.UP, sin(_clock * 3.0 + float(k[3])) * 0.12), pos)
	if _holo_ring != null:
		_holo_ring.rotation.y = _clock * 0.25
		_holo_ring.rotation.x = sin(_clock * 0.3) * 0.08
	var inside: bool = ile.contains(p.x, p.z)
	if _rain != null:
		var wet: bool = inside and is_raining() and p.y < Y0 + 60.0
		if wet != _rain.emitting:
			_rain.emitting = wet
		if wet:
			_rain.global_position = Vector3(p.x, p.y + 15.0, p.z)
	# une voiture volante passe tout près : vrrroumm
	_car_sfx_t -= delta
	if inside and _car_sfx_t <= 0.0:
		for i in range(_cars.size()):
			var cp: Vector3 = car_pos(i)
			if cp.distance_to(p) < 22.0:
				sfx("voiture_volante", cp)
				_car_sfx_t = 4.0
				break
	_light_t -= delta
	if _light_t <= 0.0:
		_light_t = 0.5
		_lights_tick(p)
	if not inside:
		return
	if not bool(state["visite"]) and ile.height(p.x, p.z) > 0.5 and bool(main.get("game_started")):
		state["visite"] = true
		main._show_message_v28("Néopolis — la ville qui ne dort jamais : des tours de verre, des néons, des voitures qui volent…")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	_zone_t -= delta
	if _zone_t > 0.0:
		return
	_zone_t = 1.0
	var z: String = zone_at(p)
	var vis: Dictionary = state["visites"]
	if z == "centre":
		z = "axiome" if IleScript.L(p.x, p.z).distance_to(TOUR) < 40.0 else z
	if MESSAGES.has(z) and z != "terrasse" and not bool(vis.get(z, false)):
		vis[z] = true
		main._show_message_v28(str(MESSAGES[z]))
	elif z == "terrasse":
		vis["terrasse"] = true
	# la surface vue d'en dessous suit le plongeur (la mer de l'île est loin du centre du monde)
	var mer: Node = main.get("mer_v55")
	if mer != null and mer.get("_underside") != null:
		(mer._underside as Node3D).global_position = Vector3(snappedf(p.x, 40.0), (mer._underside as Node3D).global_position.y, snappedf(p.z, 40.0))


## Le soir : les fenêtres, les néons, la pluie sur l'asphalte ; et seulement les lumières proches
func _lights_tick(p: Vector3) -> void:
	night = night_k(hour())
	var raining: bool = is_raining()
	if tours_mat != null:
		tours_mat.set_shader_parameter("nuit", night)
	if ile.ground_mat != null:
		ile.ground_mat.set_shader_parameter("nuit", night)
		ile.ground_mat.set_shader_parameter("mouille", 0.95 if raining else lerpf(0.3, 0.7, night))
	for m in ecran_mats:
		(m as ShaderMaterial).set_shader_parameter("nuit", night)
	Kit.set_night(night)
	var maxl: int = 48 if pc else 20
	var reach: float = 110.0 if pc else 70.0
	var cand: Array = []
	if night > 0.3:
		for i in range(_lights.size()):
			var d: float = ((_lights[i][0] as Node3D).global_position).distance_squared_to(p)
			if d < reach * reach:
				cand.append([d, i])
		cand.sort_custom(func(a, b): return a[0] < b[0])
	var on: Dictionary = {}
	for k in range(mini(maxl, cand.size())):
		on[int(cand[k][1])] = true
	for i in range(_lights.size()):
		var l: OmniLight3D = _lights[i][0]
		var v: bool = on.has(i)
		if l.visible != v:
			l.visible = v
		if v:
			l.light_energy = float(_lights[i][1]) * night


func trouvailles() -> Dictionary:
	var vis: Dictionary = state.get("visites", {})
	return {"neo": 1 if bool(state.get("visite", false)) else 0,
		"neo_place": 1 if bool(vis.get("place", false)) else 0, "neo_terrasse": 1 if bool(state.get("terrasse", false)) else 0,
		"neo_marche": 1 if bool(vis.get("marche", false)) else 0, "neo_ruelles": 1 if bool(vis.get("ruelles", false)) else 0,
		"neo_hauts": 1 if bool(vis.get("hauts", false)) else 0, "neo_jardin": 1 if bool(vis.get("jardin", false)) else 0,
		"neo_monorail": 1 if (state.get("stations", {}) as Dictionary).size() >= 4 else 0,
		"neo_arcade": 1 if int(state.get("arcade", 0)) >= 3 else 0, "neo_soda": 1 if int(state.get("sodas", 0)) >= 1 else 0,
		"neo_nouilles": 1 if int(state.get("nouilles", 0)) >= 1 else 0,
		"virus_neo": 1 if int(state.get("virus", 0)) >= 2 else 0}


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	state = _fresh_state()
	for k in state:
		if d.has(k):
			state[k] = d[k] if not (d[k] is Dictionary) else (d[k] as Dictionary).duplicate(true)
	# V96 : une partie chargée referme le faux virus (il reprendra avec Glitch, là où on en était)
	if virus != null:
		virus.reset()
