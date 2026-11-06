extends Node3D
## V114 : LES STRATES, la ville sous la ville, une centaine de mètres sous la Place de la Colonne de
## Hautefond, dans les cavernes de grès en couches (strates_roche_v114). Fantastique-vapeur, sous terre :
##  - la COLONNE RENVERSÉE : la Grande Colonne continue sous terre ; un tube de verre cerclé de laiton
##    pend du sommet de la voûte jusqu'à la GARE DES STRATES (la cabine de la Ligne des Strates y
##    descend : strates_ligne_v114) ; à côté, la grille fermée de la LIGNE DU DÔME D'AZUR ;
##  - le SOLEIL DE LAITON : une grande sphère armillaire de laiton, à mi-hauteur de la Colonne, dont le
##    cœur (des lampes à arc) éclaire toute la caverne : fort le jour, ambré et doux la nuit ;
##  - la PLACE DES ROUAGES (autour de la Gare) : la Grande Horloge des Strates, la Fontaine aux
##    Rouages, les bancs, les évents de vapeur ;
##  - la GRANDE FORGE DES STRATES (au nord-est) : la halle, les fours, le marteau-pilon, la cheminée qui
##    monte jusqu'à la voûte ; LA MARMITE (au sud-est), la cantine (sans une goutte d'alcool) ;
##    l'ATELIER DES LUMIÈRES (au sud-ouest), les lanternes à cristal ;
##  - les maisons de pierre blonde, en deux couronnes ; le PETIT TRAIN DES STRATES (une petite
##    locomotive à vapeur et ses deux voitures) fait le tour de la caverne, sa gare au sud-ouest, son
##    dépôt au nord-ouest ;
##  - les GALERIES (taillées dans la paroi nord) : deux grands escaliers montent à la première, où
##    s'alignent les maisons creusées dans la roche et la MAISON DE LA GUILDE ; la seconde, plus haut ;
##  - les MINES DE CRISTAUX (à l'ouest) : le portail de bois, le bureau du contremaître, la voie et ses
##    wagonnets, la GROTTE AUX CRISTAUX ;
##  - les JARDINS DES CHAMPIGNONS (au sud, sous la grande arche) : les champignons lumineux, les
##    planches de culture, l'étang noir et sa CASCADE (l'eau de pluie de la surface qui tombe d'une
##    fissure de la voûte) ;
##  - à l'est, le tunnel de la Fronde, le PONT DES FRONDEURS au-dessus du GOUFFRE (fronde_v114).
## Les points, le réseau et les lieux des habitants vont dans ceux de Hautefond (comme ceux des Nuées).

const R = preload("res://scripts/strates_roche_v114.gd")
const Kit = preload("res://scripts/strates_kit_v114.gd")
const F0: float = -96.0
const TRAIN_E: float = 0.82              # la voie du Petit Train (sur l'ovale de la caverne)
const SOLEIL_Y: float = -66.0

var main: Node
var roche: Node3D
var hf: Node3D                           # la ville de Hautefond (ses points, son réseau, ses lieux)
var kit
var pc: bool = true
var ligne: Node3D                        # strates_ligne_v114 (bâtie par hautefond_v112, à côté)
var fronde: Node3D                       # fronde_v114
var objets: Dictionary = {}
var crowd_spots: Array = []
var doors: Dictionary = {}
var lights: Array = []                   # [OmniLight3D, énergie de jour, énergie de nuit]
var soleil_light: OmniLight3D
var soleil_rings: Array = []             # Node3D : les anneaux de la sphère armillaire (ils tournent)
var train: Node3D
var train_cars: Array = []               # [Node3D, retard en mètres]
var train_path: Array = []               # Vector3 : la voie (fermée)
var train_len: float = 0.0
var train_s: float = 0.0
var train_stop: float = 0.0
var hammer: Node3D
var gears: Array = []                    # [Node3D, vitesse]
var steam: Array = []
var _clock: float = 0.0
var _rng := RandomNumberGenerator.new()


# =================================================================== repères

func P(lx: float, lz: float, y: float = F0) -> Vector3:
	return R.W(lx, lz, y)


## Un point de la Grande Strate sur l'ovale (e : 1 au pied de la paroi ; deg : l'angle, 0 = est, 90 = sud).
func E(e: float, deg: float, y: float = F0) -> Vector3:
	var a: float = deg_to_rad(deg)
	return P(R.GS_A * e * cos(a), R.GS_B * e * sin(a), y)


## Un repère au sol, sur l'ovale, dont la façade (+Z) regarde le centre de la caverne.
func XE(e: float, deg: float, y: float = F0) -> Transform3D:
	var p: Vector3 = E(e, deg, y)
	var c: Vector3 = P(0, 0, y)
	return Transform3D(Basis.looking_at(-(c - p).normalized(), Vector3.UP), p)


## Un repère au sol en p, dont la façade (+Z) regarde vers q.
func XL(p: Vector3, q: Vector3) -> Transform3D:
	var d := Vector3(q.x - p.x, 0, q.z - p.z)
	return Transform3D(Basis.looking_at(-d.normalized(), Vector3.UP), p)


func _pt(name: String, p: Vector3) -> String:
	return hf._pt(name, p)


func _link(a: String, b: String) -> void:
	hf._link(a, b)


func _chain(names: Array) -> void:
	hf._chain(names)


func _spot(name: String, pos: Vector3, face: Vector3, pose: String, node: String) -> void:
	hf._spot(name, pos, face, pose, node)


func _near_pt(p: Vector3, prefix: String = "st_p_") -> String:
	var best: String = ""
	var bd: float = INF
	for k in hf.points:
		if not str(k).begins_with(prefix):
			continue
		var d: float = (hf.points[k] as Vector3).distance_to(p)
		if d < bd:
			bd = d
			best = str(k)
	return best


## Un lieu de rendez-vous (un « spot »), relié au point du réseau le plus proche.
func _sp(name: String, pos: Vector3, face_to: Vector3, pose: String) -> void:
	var f := Vector3(face_to.x - pos.x, 0, face_to.z - pos.z)
	_spot(name, pos + Vector3.UP * 0.05, f.normalized() if f.length() > 0.01 else Vector3.FORWARD, pose, _near_pt(pos))


## Un lieu pour un passant.
func _crowd(name: String, pos: Vector3, face_to: Vector3, pose: String) -> void:
	_sp(name, pos, face_to, pose)
	crowd_spots.append(name)


## Une porte d'habitant (« porte_<prénom> ») : un point du réseau, relié au plus proche.
func _door(name: String, p: Vector3) -> void:
	var near: String = _near_pt(p)
	_pt(name, p + Vector3.UP * 0.05)
	if near != "":
		_link(name, near)
	doors[name] = p


func _light(p: Vector3, c: Color, e_day: float, e_night: float, rng_m: float, shadow: bool = false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = e_day
	l.omni_range = rng_m
	l.omni_attenuation = 1.2
	l.shadow_enabled = shadow
	l.distance_fade_enabled = true
	l.distance_fade_begin = 120.0
	l.distance_fade_length = 30.0
	add_child(l)
	l.global_position = p
	lights.append([l, e_day, e_night])
	return l


# =================================================================== construction

func build(main_node: Node, rock: Node3D, hf_city: Node3D, high_quality: bool) -> void:
	main = main_node
	roche = rock
	hf = hf_city
	pc = high_quality
	_rng.seed = 11400
	var t0: int = Time.get_ticks_msec()
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.main = main
	kit.pc = pc
	kit.rng.seed = 11401
	_network()
	_colonne_renversee()
	_soleil()
	_gare()
	_place()
	_forge()
	_marmite()
	_lumieres()
	_maisons()
	_galeries()
	_mines()
	_jardins()
	_petit_train()
	_vers_la_fronde()
	fronde = load("res://scripts/fronde_v114.gd").new()
	fronde.name = "Fronde_v114"
	add_child(fronde)
	fronde.build(main, self, hf, pc)
	kit.commit()
	for ch in get_children():
		if ch is GeometryInstance3D and str(ch.name).contains("verre"):
			(ch as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lumieres_reelles()
	print("ILE_MANGA_V114: les Strates sont bâties (%d ms, %d points)" % [Time.get_ticks_msec() - t0, hf.points.size()])


# =================================================================== le réseau des rues

const PL_R: float = 21.0


func _network() -> void:
	# l'anneau de la Place des Rouages (autour de la Gare)
	for k in range(12):
		var a: float = TAU * k / 12.0
		_pt("st_p_pl_%d" % k, P(cos(a) * PL_R, sin(a) * PL_R))
	for k in range(12):
		_link("st_p_pl_%d" % k, "st_p_pl_%d" % ((k + 1) % 12))
	# la Gare (au centre) : le quai, relié à la Place
	_pt("st_p_gare", P(0, 6.5))
	_link("st_p_gare", "st_p_pl_3")
	_link("st_p_gare", "st_p_pl_9")
	_link("st_p_gare", "st_p_pl_0")
	_link("st_p_gare", "st_p_pl_6")
	# la couronne (e = 0.64) : seize points
	for k2 in range(16):
		_pt("st_p_co_%d" % k2, E(0.64, 22.5 * k2))
	for k2 in range(16):
		_link("st_p_co_%d" % k2, "st_p_co_%d" % ((k2 + 1) % 16))
	# les quatre avenues (est, sud, ouest, nord) de la Place à la couronne
	_pt("st_p_av_e", E(0.42, 0.0))
	_chain(["st_p_pl_0", "st_p_av_e", "st_p_co_0"])
	_pt("st_p_av_s", E(0.42, 90.0))
	_chain(["st_p_pl_3", "st_p_av_s", "st_p_co_4"])
	_pt("st_p_av_o", E(0.42, 180.0))
	_chain(["st_p_pl_6", "st_p_av_o", "st_p_co_8"])
	_pt("st_p_av_n", E(0.42, 270.0))
	_chain(["st_p_pl_9", "st_p_av_n", "st_p_co_12"])
	# les diagonales (la Forge, la Marmite, les Lumières, le dépôt)
	_link("st_p_pl_10", "st_p_co_14")
	_link("st_p_pl_1", "st_p_co_2")
	_link("st_p_pl_4", "st_p_co_6")
	_link("st_p_pl_7", "st_p_co_10")
	# le tour extérieur (le long de la voie du train, côté intérieur)
	for k3 in range(16):
		_pt("st_p_ex_%d" % k3, E(0.76, 22.5 * k3))
	for k3 in range(16):
		_link("st_p_ex_%d" % k3, "st_p_ex_%d" % ((k3 + 1) % 16))
		_link("st_p_ex_%d" % k3, "st_p_co_%d" % k3)


# =================================================================== la Colonne Renversée

func _colonne_renversee() -> void:
	var c: Vector3 = P(0, 0)
	var top_y: float = -47.0
	var h: float = top_y - F0
	# le tube de verre, ses bagues de laiton, ses quatre rails
	kit.cyl(Transform3D(Basis(), c), 2.75, 2.75, h, "verre112", 20, false, 3.0)
	var y: float = 3.6
	while y < h - 1.0:
		kit.ring(Transform3D(Basis(), c + Vector3.UP * y), 2.72, 3.02, 0.28, "laiton112", 28)
		y += 4.5
	for k in range(4):
		var a: float = TAU * k / 4.0 + PI * 0.25
		kit.cyl(Transform3D(Basis(), c + Vector3(cos(a), 0, sin(a)) * 2.95), 0.09, 0.09, h, "laiton112", 6, false)
	# en haut : la grande rosace de laiton où la Colonne entre dans la roche ; les haubans
	var ry: float = top_y - 2.0
	kit.cyl(Transform3D(Basis(), P(0, 0, ry)), 7.5, 4.0, 2.4, "laiton112_vieux", 28, true, 2.0)
	kit.ring(Transform3D(Basis(), P(0, 0, ry - 0.2)), 6.8, 8.2, 0.5, "or112", 32)
	for k2 in range(8):
		var a2: float = TAU * k2 / 8.0
		var d := Vector3(cos(a2), 0, sin(a2))
		kit.gear112(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), P(0, 0, ry - 0.5) + d * 7.5), 0.9, 10, 0.18, "laiton112")
	# en bas : le socle de la Colonne (un anneau de pierre et de laiton autour de la cage)
	kit.cyl(Transform3D(Basis(), c), 3.6, 3.4, 0.4, "pierre112_clair", 24, true, 2.0)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * 0.4), 3.0, 3.5, 0.12, "laiton112", 24)


# =================================================================== le Soleil de Laiton

func _soleil() -> void:
	var c: Vector3 = P(0, 0, SOLEIL_Y)
	# le moyeu, sur la Colonne : une bague épaisse, ses rayons
	kit.cyl(Transform3D(Basis(), c + Vector3.DOWN * 1.4), 3.6, 3.6, 2.8, "laiton112_vieux", 24, true, 1.5)
	for k in range(8):
		var a: float = TAU * k / 8.0 + PI / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		kit.beam(c + d * 3.5, c + d * 8.6, 0.16, "laiton112")
		# les lampes à arc : huit globes autour du moyeu
		kit.ball(Transform3D(Basis(), c + d * 5.8 + Vector3.DOWN * 0.4), 1.5, "soleil114", 16, 10)
		kit.cyl(Transform3D(Basis(), c + d * 5.6 + Vector3.UP * 0.6), 0.5, 0.3, 0.4, "laiton112", 10)
	kit.ring(Transform3D(Basis(), c + Vector3.DOWN * 0.4), 4.4, 7.2, 0.3, "soleil114", 48)
	kit.ball(Transform3D(Basis(), c + Vector3.DOWN * 2.6), 3.1, "soleil114", 20, 10)
	# la sphère armillaire : des anneaux qui tournent lentement (des maillages à part)
	var specs := [[9.0, 0.0, 0.0, 0.05], [8.2, 1.15, 0.0, -0.07], [7.4, 0.0, 1.15, 0.09]]
	for sp in specs:
		var n := Node3D.new()
		n.name = "Anneau_soleil"
		add_child(n)
		n.global_position = c
		var mi := MeshInstance3D.new()
		var tk = Kit.new()
		tk.setup(mi, null)
		tk.ring(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), float(sp[0]) - 0.3, float(sp[0]), 0.4, "laiton112", 48)
		for k2 in range(12):
			var a2: float = TAU * k2 / 12.0
			tk.ball(Transform3D(Basis(), Vector3(cos(a2), sin(a2), 0) * (float(sp[0]) - 0.15)), 0.22, "or112", 6, 3)
		var mesh := ArrayMesh.new()
		for k3 in tk.batch:
			var st: SurfaceTool = tk.batch[k3]
			st.commit(mesh)
			mesh.surface_set_material(mesh.get_surface_count() - 1, tk.mat(str(k3)))
		mi.mesh = mesh
		mi.rotation = Vector3(float(sp[1]), 0, float(sp[2]))
		n.add_child(mi)
		soleil_rings.append([n, float(sp[3])])
	# l'équateur fixe : un anneau à créneaux, gravé des heures
	kit.ring(Transform3D(Basis(), c + Vector3.DOWN * 0.2), 9.6, 10.4, 0.5, "laiton112_vieux", 64)
	for k4 in range(24):
		var a4: float = TAU * k4 / 24.0
		kit.box(Transform3D(Basis(Vector3.UP, -a4), c + Vector3(cos(a4), 0, sin(a4)) * 10.0 + Vector3.UP * 0.3), Vector3(0.5, 0.5, 0.7), "or112", 1.0)
	for k5 in range(4):
		var a5: float = TAU * k5 / 4.0
		kit.beam(c + Vector3(cos(a5), 0, sin(a5)) * 3.4 + Vector3.DOWN * 1.2, c + Vector3(cos(a5), 0, sin(a5)) * 9.8 + Vector3.DOWN * 0.2, 0.12, "laiton112_vieux")
	soleil_light = OmniLight3D.new()
	soleil_light.name = "Soleil_de_laiton"
	soleil_light.light_color = Color(1.0, 0.9, 0.74)
	soleil_light.light_energy = 8.0
	soleil_light.omni_range = 175.0
	soleil_light.omni_attenuation = 0.55
	soleil_light.shadow_enabled = pc
	soleil_light.shadow_bias = 0.06
	add_child(soleil_light)
	soleil_light.global_position = c + Vector3.DOWN * 3.2
	objets["soleil"] = c


# =================================================================== la Gare des Strates

func _gare() -> void:
	var c: Vector3 = P(0, 0)
	# le sol de la gare : des dalles blondes, un liseré de laiton
	kit.cyl(Transform3D(Basis(), c + Vector3.UP * 0.01), 11.5, 11.5, 0.03, "pave112", 40, true, 3.0)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * 0.02), 11.4, 11.8, 0.04, "laiton112", 40)
	# la marquise : douze colonnes de fonte, un anneau de verre et de fer
	var hh: float = 6.2
	for k in range(12):
		var a: float = TAU * k / 12.0 + PI / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		var p: Vector3 = c + d * 9.6
		kit.cyl(Transform3D(Basis(), p), 0.32, 0.26, 0.5, "pierre112_clair", 10)
		kit.cyl(Transform3D(Basis(), p + Vector3.UP * 0.5), 0.14, 0.12, hh - 0.5, "fer114", 10, false)
		kit.cyl(Transform3D(Basis(), p + Vector3.UP * (hh - 0.4)), 0.12, 0.3, 0.4, "fer114", 10)
		kit.col_cyl(p, 0.3, hh)
		# les consoles en volute (deux barres courbes vers le dedans)
		kit.beam(p + Vector3.UP * (hh - 1.4), p - d * 1.6 + Vector3.UP * hh, 0.05, "fer114")
		kit.beam(p + Vector3.UP * (hh - 1.4), p + d * 1.0 + Vector3.UP * hh, 0.05, "fer114")
	kit.ring(Transform3D(Basis(), c + Vector3.UP * hh), 8.0, 10.8, 0.22, "fer114", 48)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * (hh + 0.2)), 8.2, 10.6, 0.04, "verre112", 48)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * (hh + 0.25)), 10.6, 11.0, 0.5, "laiton112_vieux", 48)
	# les quatre enseignes « Gare des Strates », au bord de la marquise
	for k2 in range(4):
		var a2: float = TAU * k2 / 4.0 + PI * 0.5
		var d2 := Vector3(cos(a2), 0, sin(a2))
		kit.sign114(Transform3D(Basis.looking_at(-d2, Vector3.UP), c + d2 * 11.05 + Vector3.UP * (hh + 1.15)), "gare", 3.4, 1.0)
	# le guichet (une cabine de bois et de verre, une horloge dessus)
	var gx: Transform3D = XL(P(5.5, -4.5), c)
	kit.box(gx * kit.T(0, 1.3, -0.9), Vector3(2.6, 2.6, 1.8), "bois112", 1.0)
	kit.box(gx * kit.T(0, 1.6, 0.0), Vector3(2.2, 1.2, 0.04), "vitre114", 1.0)
	kit.box(gx * kit.T(0, 0.95, 0.12), Vector3(2.4, 0.08, 0.3), "laiton112", 1.0)
	kit.box(gx * kit.T(0, 2.75, -0.9), Vector3(2.9, 0.3, 2.1), "laiton112_vieux", 1.0)
	kit.clock112(gx * kit.T(0, 3.4, -0.2), 0.42)
	kit.col_box(gx * kit.T(0, 1.3, -0.9), Vector3(2.6, 2.6, 1.8))
	_sp("st_gare_guichet", gx * Vector3(0, 0, -0.4), gx * Vector3(0, 0, 3.0), "comptoir")
	# les bancs du quai
	for b in [[-6.5, 2.5], [6.5, 2.5], [-6.0, -5.0]]:
		var bp: Vector3 = P(float(b[0]), float(b[1]))
		kit.bench112(XL(bp, c))
	_sp("st_gare_banc_1", P(-6.5, 2.5) + (c - P(-6.5, 2.5)).normalized() * 0.3, c, "assis")
	_sp("st_gare_banc_2", P(6.5, 2.5) + (c - P(6.5, 2.5)).normalized() * 0.3, c, "assis")
	_sp("st_gare_quai", P(0.8, 5.0), P(0, 0), "debout")
	# la grille de la Ligne du Dôme d'Azur : une petite cage de laiton qui descend dans le sol, fermée
	var dz: Vector3 = P(0, -7.6)
	kit.cyl(Transform3D(Basis(), dz), 1.7, 1.7, 3.2, "verre112", 16, false, 2.0)
	kit.ring(Transform3D(Basis(), dz), 1.6, 1.9, 0.25, "laiton112", 20)
	kit.ring(Transform3D(Basis(), dz + Vector3.UP * 3.1), 1.6, 1.9, 0.25, "laiton112", 20)
	kit.dome76(Transform3D(Basis(), dz + Vector3.UP * 3.25), 1.9, 0.9, "verdigris112", 16, 5)
	var gb := Basis.looking_at(Vector3(0, 0, 1), Vector3.UP)
	for k3 in range(9):
		var x: float = -0.8 + k3 * 0.2
		kit.box(Transform3D(gb, dz + Vector3(x, 1.3, 1.75)), Vector3(0.04, 2.6, 0.04), "laiton112_vieux", 1.0)
	kit.box(Transform3D(gb, dz + Vector3(0, 0.9, 1.78)), Vector3(1.9, 0.08, 0.06), "laiton112_vieux", 1.0)
	kit.box(Transform3D(gb, dz + Vector3(0, 1.4, 1.82)), Vector3(1.9, 0.12, 0.04), "fer114", 1.0)
	kit.sign114(Transform3D(gb, dz + Vector3(0, 2.3, 1.85)), "dome", 1.6, 0.8)
	kit.col_cyl(dz, 1.9, 3.4)
	objets["ligne_dome"] = dz + Vector3(0, 0, 2.4)
	objets["gare"] = c + Vector3(0, 0, 6.0)


# =================================================================== la Place des Rouages

func _place() -> void:
	var c: Vector3 = P(0, 0)
	# le pavé : un grand disque de dalles, un cercle de laiton gravé
	kit.cyl(Transform3D(Basis(), c + Vector3.UP * 0.005), 30.0, 30.0, 0.02, "pave112_gris", 64, true, 3.0)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * 0.02), 29.6, 30.2, 0.03, "laiton112_vieux", 64)
	# les avenues (des bandes de dalles, de la Place à la couronne)
	for a_deg in [0.0, 90.0, 180.0, 270.0]:
		var a: Vector3 = E(0.0, a_deg) + (E(1.0, a_deg) - E(0.0, a_deg)).normalized() * 29.0
		var b: Vector3 = E(0.95 if a_deg != 270.0 else 0.9, a_deg)
		var d: Vector3 = b - a
		kit.box(Transform3D(Basis.looking_at(d.normalized(), Vector3.UP), (a + b) * 0.5 + Vector3.UP * 0.01), Vector3(8.0, 0.02, d.length()), "pave112_gris", 3.0, 4)
	# la couronne : un anneau de dalles (e = 0.64) qui fait le tour
	var n: int = 64
	for k in range(n):
		var a0: Vector3 = E(0.64, 360.0 * k / n)
		var a1: Vector3 = E(0.64, 360.0 * (k + 1) / n)
		var dd: Vector3 = a1 - a0
		kit.box(Transform3D(Basis.looking_at(dd.normalized(), Vector3.UP), (a0 + a1) * 0.5 + Vector3.UP * 0.012), Vector3(6.0, 0.02, dd.length() + 0.3), "pave112_gris", 3.0, 4)
	# les réverbères (huit autour de la Place), les bancs
	for k2 in range(8):
		var a2: float = TAU * k2 / 8.0 + PI / 8.0
		kit.lamp114(c + Vector3(cos(a2), 0, sin(a2)) * 26.0, 4.4, false, k2 % 2 == 0)
	for k3 in range(4):
		var a3: float = TAU * k3 / 4.0 + PI / 4.0
		var bp: Vector3 = c + Vector3(cos(a3), 0, sin(a3)) * 15.5
		kit.bench112(XL(bp, c))
		_sp("st_place_banc_%d" % (k3 + 1), bp + (c - bp).normalized() * 0.3, c, "assis")
	var standing := [[30.0, "debout"], [75.0, "observer"], [150.0, "bras_croises"], [210.0, "debout"], [250.0, "observer"], [320.0, "bras_croises"]]
	for i in range(standing.size()):
		var a4: float = deg_to_rad(float(standing[i][0]))
		var sp: Vector3 = c + Vector3(cos(a4), 0, sin(a4)) * 19.0
		_sp("st_place_%d" % (i + 1), sp, c + Vector3(cos(a4 + 0.9), 0, sin(a4 + 0.9)) * 30.0, str(standing[i][1]))
		crowd_spots.append("st_place_%d" % (i + 1))
	# la Grande Horloge des Strates (au sud-est) : une tour de pierre et de laiton, deux cadrans, des
	# engrenages à l'air qui tournent
	var hx: Transform3D = XL(P(15.5, 17.0), c)
	kit.box(hx * kit.T(0, 0.6, 0), Vector3(3.6, 1.2, 3.6), "pierre112_sombre", 1.6)
	kit.box(hx * kit.T(0, 5.2, 0), Vector3(2.8, 8.4, 2.8), "pierre112_clair", 2.0)
	kit.box(hx * kit.T(0, 9.6, 0), Vector3(3.3, 0.5, 3.3), "laiton112_vieux", 1.0)
	kit.col_box(hx * kit.T(0, 5.0, 0), Vector3(3.6, 10.0, 3.6))
	for s in [1.0, -1.0]:
		var face: Transform3D = hx * Transform3D(Basis(Vector3.UP, 0.0 if s > 0 else PI), Vector3(0, 7.6, s * 1.42))
		kit.clock112(face, 1.15)
	kit.dome76(hx * kit.T(0, 9.85, 0), 1.9, 1.6, "verdigris112", 16, 5)
	kit.cyl(hx * kit.T(0, 11.4, 0), 0.08, 0.02, 1.4, "or112", 6)
	for k4 in range(3):
		var g := Node3D.new()
		g.name = "Engrenage_horloge"
		add_child(g)
		var gp: Vector3 = hx * Vector3(1.55, 3.2 + k4 * 1.5, -0.4 + k4 * 0.4)
		g.global_transform = Transform3D(hx.basis * Basis(Vector3.UP, PI * 0.5), gp)
		var gm := MeshInstance3D.new()
		var tk = Kit.new()
		tk.setup(gm, null)
		tk.gear112(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.75 - k4 * 0.15, 12 - k4 * 2, 0.14, "laiton112")
		var mesh := ArrayMesh.new()
		for k5 in tk.batch:
			var st: SurfaceTool = tk.batch[k5]
			st.commit(mesh)
			mesh.surface_set_material(mesh.get_surface_count() - 1, tk.mat(str(k5)))
		gm.mesh = mesh
		g.add_child(gm)
		gears.append([g, (0.4 + k4 * 0.2) * (1.0 if k4 % 2 == 0 else -1.0)])
	_sp("st_horloge", hx * Vector3(0, 0, 2.4), hx * Vector3(0, 3, 0), "bricoler")
	objets["horloge"] = hx * Vector3(0, 0, 2.6)
	# la Fontaine aux Rouages (au sud-ouest) : un bassin, une roue à aubes de laiton qui tourne
	var fp: Vector3 = P(-15.5, 17.0)
	kit.cyl(Transform3D(Basis(), fp), 4.2, 4.2, 0.6, "pierre112_clair", 32, false, 2.0)
	kit.ring(Transform3D(Basis(), fp + Vector3.UP * 0.6), 3.9, 4.4, 0.12, "pierre112_clair", 32)
	kit.disc(Transform3D(Basis(), fp + Vector3.UP * 0.45), 3.95, "eau112", 32)
	kit.col_cyl(fp, 4.3, 0.75)
	kit.box(Transform3D(Basis(), fp + Vector3.UP * 1.6), Vector3(0.5, 3.2, 0.5), "pierre112_sombre", 1.0)
	var wheel := Node3D.new()
	wheel.name = "Roue_fontaine"
	add_child(wheel)
	wheel.global_position = fp + Vector3.UP * 2.6
	var wm := MeshInstance3D.new()
	var wk = Kit.new()
	wk.setup(wm, null)
	wk.ring(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 1.7, 1.9, 0.3, "laiton112", 28)
	for k6 in range(10):
		var a6: float = TAU * k6 / 10.0
		wk.box(Transform3D(Basis(Vector3.BACK, a6), Vector3(cos(a6), sin(a6), 0) * 1.2), Vector3(1.2, 0.06, 0.5), "laiton112_vieux", 1.0)
	var wmesh := ArrayMesh.new()
	for k7 in wk.batch:
		var st2: SurfaceTool = wk.batch[k7]
		st2.commit(wmesh)
		wmesh.surface_set_material(wmesh.get_surface_count() - 1, wk.mat(str(k7)))
	wm.mesh = wmesh
	wheel.add_child(wm)
	gears.append([wheel, 0.5])
	objets["fontaine"] = fp + Vector3(0, 0, 5.0)
	# les évents de vapeur (quatre bouches de laiton dans le pavé)
	for k8 in range(4):
		var a8: float = TAU * k8 / 4.0
		var vp: Vector3 = c + Vector3(cos(a8), 0, sin(a8)) * 12.5
		kit.cyl(Transform3D(Basis(), vp), 0.45, 0.35, 0.3, "laiton112_vieux", 12)
		kit.disc(Transform3D(Basis(), vp + Vector3.UP * 0.31), 0.33, "fer114", 12)
		steam.append(vp + Vector3.UP * 0.35)


# =================================================================== la Grande Forge des Strates

func _forge() -> void:
	var xf: Transform3D = XE(0.6, -42.0)
	var w: float = 24.0
	var d: float = 15.0
	var hh: float = 9.0
	var c: Transform3D = xf * kit.T(0, 0, -d * 0.5)
	# les murs de pierre sombre (la façade ouverte par trois grandes arches)
	kit.box(c * kit.T(0, hh * 0.5, -d * 0.5), Vector3(w, hh, 0.8), "pierre112_sombre", 2.5)
	kit.col_box(c * kit.T(0, hh * 0.5, -d * 0.5), Vector3(w, hh, 0.8))
	for s in [-1.0, 1.0]:
		kit.box(c * kit.T(s * w * 0.5, hh * 0.5, 0), Vector3(0.8, hh, d), "pierre112_sombre", 2.5)
		kit.col_box(c * kit.T(s * w * 0.5, hh * 0.5, 0), Vector3(0.8, hh, d))
	# la façade : quatre piles, trois arches (on voit dedans)
	for k in range(4):
		var x: float = -w * 0.5 + 0.6 + k * (w - 1.2) / 3.0
		kit.box(c * kit.T(x, hh * 0.5, d * 0.5), Vector3(1.4, hh, 1.0), "pierre112", 2.0)
		kit.col_box(c * kit.T(x, hh * 0.5, d * 0.5), Vector3(1.4, hh, 1.0))
	kit.box(c * kit.T(0, hh - 1.0, d * 0.5), Vector3(w, 2.0, 1.0), "pierre112", 2.0)
	kit.box(c * kit.T(0, hh + 0.2, 0), Vector3(w + 1.0, 0.4, d + 1.0), "ardoise112", 2.0)
	kit.roof_gable(c * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, hh + 0.4, 0)), d + 0.6, w + 0.6, 34.0, 0.3, "ardoise112", "pierre112_sombre")
	kit.sign114(c * kit.T(0, hh - 1.0, d * 0.5 + 0.55), "forge", 5.2, 1.3)
	# le sol de la forge : des dalles noircies
	kit.box(c * kit.T(0, 0.02, 0), Vector3(w - 0.8, 0.04, d - 0.6), "pierre112_sombre", 2.0, 4)
	# les deux fours (des voûtes de brique, une gueule rougeoyante) contre le mur du fond
	for s2 in [-1.0, 1.0]:
		var fx: Transform3D = c * kit.T(s2 * 6.5, 0, -d * 0.5 + 2.2)
		kit.box(fx * kit.T(0, 1.6, 0), Vector3(4.2, 3.2, 3.2), "pierre112_sombre", 1.5)
		kit.box(fx * kit.T(0, 1.2, 1.62), Vector3(1.5, 1.2, 0.04), "braise114", 1.0)
		kit.box(fx * kit.T(0, 3.6, 0), Vector3(2.4, 0.8, 2.0), "fer114", 1.0)
		kit.col_box(fx * kit.T(0, 1.6, 0), Vector3(4.2, 3.2, 3.2))
		_light(fx * Vector3(0, 1.4, 2.6), Color(1.0, 0.5, 0.2), 2.2, 2.6, 12.0)
	# la grande cheminée de brique : elle monte jusqu'à la voûte
	var chp: Vector3 = c * Vector3(0, hh, -d * 0.5 + 2.0)
	var top_y: float = -54.0
	kit.cyl(Transform3D(Basis(), chp), 1.6, 1.2, top_y - chp.y, "pierre112_sombre", 16, false, 2.0)
	var yy: float = chp.y + 3.0
	while yy < top_y - 1.0:
		kit.ring(Transform3D(Basis(), Vector3(chp.x, yy, chp.z)), 1.25, 1.65, 0.3, "fer114", 16)
		yy += 5.0
	# les enclumes, le marteau-pilon (il frappe), les établis
	var an: Transform3D = c * kit.T(-3.0, 0, 1.0)
	kit.box(an * kit.T(0, 0.35, 0), Vector3(0.6, 0.7, 0.6), "fer114", 1.0)
	kit.box(an * kit.T(0, 0.82, 0), Vector3(1.2, 0.24, 0.42), "fer114", 1.0)
	kit.col_box(an * kit.T(0, 0.5, 0), Vector3(1.2, 1.0, 0.7))
	_sp("st_forge_enclume", an * Vector3(0, 0, 1.0), an * Vector3(0, 0, 0), "forger")
	var an2: Transform3D = c * kit.T(1.5, 0, 2.0)
	kit.box(an2 * kit.T(0, 0.3, 0), Vector3(0.5, 0.6, 0.5), "fer114", 1.0)
	kit.box(an2 * kit.T(0, 0.7, 0), Vector3(0.9, 0.2, 0.34), "fer114", 1.0)
	kit.col_box(an2 * kit.T(0, 0.45, 0), Vector3(0.9, 0.9, 0.5))
	_sp("st_forge_apprenti", an2 * Vector3(0, 0, 0.9), an2 * Vector3(0, 0, 0), "forger")
	_sp("st_forge_four", c * Vector3(-6.5, 0, -d * 0.5 + 5.0), c * Vector3(-6.5, 1, -d * 0.5 + 2.0), "observer")
	var mh: Transform3D = c * kit.T(7.5, 0, 2.5)
	kit.box(mh * kit.T(0, 0.4, 0), Vector3(2.4, 0.8, 2.0), "fer114", 1.0)
	for s3 in [-1.0, 1.0]:
		kit.box(mh * kit.T(s3 * 0.95, 3.0, 0), Vector3(0.4, 5.2, 0.6), "fer114", 1.0)
	kit.box(mh * kit.T(0, 5.4, 0), Vector3(2.6, 0.6, 0.8), "fer114", 1.0)
	kit.cyl(mh * kit.T(0, 5.7, 0), 0.5, 0.5, 1.2, "laiton112_vieux", 12)
	kit.col_box(mh * kit.T(0, 2.8, 0), Vector3(2.6, 5.6, 2.0))
	hammer = Node3D.new()
	hammer.name = "Marteau_pilon"
	add_child(hammer)
	hammer.global_transform = mh * kit.T(0, 3.4, 0)
	hammer.set_meta("y0", hammer.position.y)
	var hm := MeshInstance3D.new()
	var hk = Kit.new()
	hk.setup(hm, null)
	hk.box(Transform3D(Basis(), Vector3(0, 0, 0)), Vector3(1.2, 1.3, 0.9), "fer114", 1.0)
	hk.cyl(Transform3D(Basis(), Vector3(0, 0.6, 0)), 0.18, 0.18, 2.2, "acier112_clair", 8)
	var hmesh := ArrayMesh.new()
	for k4 in hk.batch:
		var st: SurfaceTool = hk.batch[k4]
		st.commit(hmesh)
		hmesh.surface_set_material(hmesh.get_surface_count() - 1, hk.mat(str(k4)))
	hm.mesh = hmesh
	hammer.add_child(hm)
	# le comptoir (devant, sous l'arche du milieu) : Brunehaut y vend outils et armes
	var cx: Transform3D = c * kit.T(0, 0, d * 0.5 + 2.4)
	kit.counter71(cx, 3.2, "planches71")
	_sp("st_forge_comptoir", cx * Vector3(0, 0, -0.9), cx * Vector3(0, 0, 3.0), "comptoir")
	objets["forge"] = cx * Vector3(0, 0, 1.6)
	steam.append(c * Vector3(7.5, 1.0, 3.8))


# =================================================================== La Marmite (la cantine)

func _marmite() -> void:
	var xf: Transform3D = XE(0.5, 42.0)
	var door: Vector3 = kit.house112(xf, 13.0, 9.0, {"floors": 2, "shop": "", "lit": 0.95, "door_x": 3.5, "roof": "pignon", "balcons": true, "chimney": true})
	kit.sign114(xf * kit.T(-2.0, 4.0, 0.12), "marmite", 4.0, 1.1)
	kit.awning71(xf * kit.T(0, 3.3, 0.0), 12.4, 3.4, 0.9, "rouge")
	# la terrasse : quatre tables, des lampions
	for i in range(4):
		var tx: Transform3D = xf * kit.T(-4.5 + i * 3.0, 0, 5.0 + (i % 2) * 1.4)
		var seats: Array = kit.tavern_table71(tx, 1.8)
		var sp: Vector3 = (seats[0] as Vector3) if seats.size() > 0 else tx * Vector3(0, 0, 0.8)
		_sp("st_marmite_table_%d" % (i + 1), sp, tx.origin, "assis")
	var cx: Transform3D = xf * kit.T(3.6, 0, 1.6)
	kit.counter71(cx, 3.0, "planches71")
	_sp("st_marmite_comptoir", cx * Vector3(0, 0, -0.9), cx * Vector3(0, 0, 3.0), "comptoir")
	# la grande marmite fumante, sur son trépied, au coin
	var mp: Vector3 = xf * Vector3(-5.6, 0, 2.2)
	kit.cyl(Transform3D(Basis(), mp + Vector3.UP * 0.5), 0.75, 0.62, 0.9, "fer114", 16)
	kit.ring(Transform3D(Basis(), mp + Vector3.UP * 1.35), 0.7, 0.8, 0.08, "laiton112", 16)
	for k in range(3):
		var a: float = TAU * k / 3.0
		kit.beam(mp + Vector3(cos(a), 0, sin(a)) * 0.9, mp + Vector3.UP * 0.6 + Vector3(cos(a), 0, sin(a)) * 0.55, 0.04, "fer114")
	kit.disc(Transform3D(Basis(), mp + Vector3.UP * 0.12), 0.45, "braise114", 10)
	kit.col_cyl(mp, 0.8, 1.4)
	steam.append(mp + Vector3.UP * 1.5)
	_sp("st_marmite_cuisine", mp + (xf.basis * Vector3(1.0, 0, 0.6)), mp, "cuisiner")
	for k2 in range(5):
		var la: Vector3 = xf * Vector3(-5.8 + k2 * 2.9, 3.0, 3.3)
		kit.ball(Transform3D(Basis(), la), 0.2, "lampe114", 8, 5)
	_light(xf * Vector3(0, 3.0, 5.0), Color(1.0, 0.72, 0.42), 1.4, 2.2, 13.0)
	objets["marmite"] = cx * Vector3(0, 0, 1.8)
	_door("porte_marmite_cuisine", door)


# =================================================================== l'Atelier des Lumières

func _lumieres() -> void:
	var xf: Transform3D = XE(0.5, 138.0)
	kit.house112(xf, 11.0, 9.0, {"floors": 2, "lit": 1.0, "door_x": -3.0, "roof": "mansarde", "balcons": false})
	kit.sign114(xf * kit.T(1.5, 4.1, 0.12), "lumieres", 4.0, 1.1)
	kit.awning71(xf * kit.T(0, 3.2, 0.0), 10.4, 2.6, 0.8, "bleu")
	# l'étal : des lanternes à cristal pendues à une barre
	var cx: Transform3D = xf * kit.T(1.6, 0, 1.6)
	kit.counter71(cx, 3.2, "planches71")
	_sp("st_lumieres_comptoir", cx * Vector3(0, 0, -0.9), cx * Vector3(0, 0, 3.0), "comptoir")
	kit.box(xf * kit.T(1.6, 2.9, 2.6), Vector3(4.0, 0.06, 0.06), "fer114", 1.0)
	for k in range(6):
		var lp: Vector3 = xf * Vector3(-0.2 + k * 0.72, 2.45, 2.6)
		kit.beam(lp + Vector3.UP * 0.45, lp + Vector3.UP * 0.2, 0.01, "fer114")
		kit.cyl(Transform3D(Basis(), lp - Vector3.UP * 0.18), 0.13, 0.13, 0.36, "vitre114", 6)
		kit.ball(Transform3D(Basis(), lp), 0.09, "cristal114" if k % 3 != 2 else "cristal114_violet", 6, 4)
	# l'établi de la Docteure (dehors, sous la marquise) : loupes, cristaux, un bec de gaz
	var ex: Transform3D = xf * kit.T(-3.4, 0, 2.6)
	kit.box(ex * kit.T(0, 0.9, 0), Vector3(2.2, 0.08, 0.9), "bois112", 1.0)
	for sx in [-1.0, 1.0]:
		kit.box(ex * kit.T(sx * 0.95, 0.45, 0), Vector3(0.08, 0.9, 0.8), "fer114", 1.0)
	for k2 in range(4):
		var cp: Vector3 = ex * Vector3(-0.7 + k2 * 0.45, 1.0, 0.1)
		kit.ball(Transform3D(Basis(), cp), 0.07, "cristal114", 6, 4)
	kit.col_box(ex * kit.T(0, 0.5, 0), Vector3(2.2, 1.0, 0.9))
	_sp("st_lumieres_etabli", ex * Vector3(0, 0, -0.7), ex * Vector3(0, 0.9, 0), "bricoler")
	_light(xf * Vector3(1.6, 2.4, 3.2), Color(0.6, 0.8, 1.0), 1.0, 1.6, 10.0)
	objets["lumieres"] = cx * Vector3(0, 0, 1.8)


# =================================================================== les maisons

## Les maisons de pierre blonde, en deux couronnes (e = 0.52 et 0.71) ; les avenues, les grands lieux et
## le chemin des escaliers restent libres. Les portes des habitants : les premières qu'on bâtit.
const HOUSE_DOORS := ["porte_honorine", "porte_ferdinand", "porte_opaline", "porte_ludovic", "porte_anatole", "porte_brunehaut", "porte_tom"]


func _maisons() -> void:
	var free := [[0.0, 13.0], [90.0, 13.0], [180.0, 13.0], [270.0, 16.0], [-42.0, 26.0], [42.0, 18.0], [138.0, 16.0]]
	var rows := [[0.52, 0.0, 15.0], [0.71, 7.5, 15.0]]
	var doors_left: Array = HOUSE_DOORS.duplicate()
	var dorder := {"porte_honorine": 52.0, "porte_opaline": 125.0, "porte_brunehaut": -60.0, "porte_tom": -60.0}
	for row in rows:
		var e: float = row[0]
		var deg: float = row[1]
		while deg < 360.0 - 1.0:
			var skip: bool = false
			for f in free:
				if absf(wrapf(deg - float(f[0]), -180.0, 180.0)) < float(f[1]) * (0.75 if e > 0.6 else 1.0):
					skip = true
			if not skip:
				var w: float = _rng.randf_range(8.0, 10.5)
				var dd: float = _rng.randf_range(7.0, 8.5)
				var fl: int = 3 if (e > 0.6 and _rng.randf() < 0.5) else 2
				var dx: float = _rng.randf_range(-w * 0.25, w * 0.25)
				var xf: Transform3D = XE(e, deg)
				var door: Vector3 = kit.house112(xf, w, dd, {"floors": fl, "lit": 0.7, "door_x": dx, "v81": true, "gf": 3.5, "uf": 3.0})
				_place_door(door, deg, doors_left)
				if _rng.randf() < 0.4:
					kit.flower_box71(xf * kit.T(-w * 0.3, 1.0, 0.1))
			deg += row[2]
	# les portes qui restent (si une couronne en a manqué) : près de la Place
	for nm in doors_left:
		_door(str(nm), E(0.36, _rng.randf_range(0.0, 360.0)))


func _place_door(door: Vector3, deg: float, left: Array) -> void:
	if left.is_empty():
		return
	# une porte d'habitant sur trois maisons
	if _rng.randf() < 0.45:
		_door(str(left.pop_front()), door)


# =================================================================== les Galeries

const G1_E0: float = 0.975              # le bord de la Galerie 1 (au-dessus du vide)
const G1_EH: float = 1.075              # la façade des maisons de la Galerie 1
const G1_A0: float = -152.0
const G1_A1: float = -28.0


func _galeries() -> void:
	var y1: float = R.G1_Y
	# le réseau de la Galerie 1 : des points le long de l'arc
	var names: Array = []
	var a: float = G1_A0 + 4.0
	var k: int = 0
	while a <= G1_A1 - 4.0 + 0.1:
		names.append(_pt("st_p_g1_%d" % k, E(1.025, a, y1)))
		a += 8.0
		k += 1
	_chain(names)
	# les deux grands escaliers : du sol de la caverne au palier de la Guilde (au milieu de l'arc)
	var land: Vector3 = E(1.0, -90.0, y1)
	for s in [-1.0, 1.0]:
		var foot: Vector3 = P(s * 30.0, -51.0)
		var top: Vector3 = P(s * 6.0, -66.2, y1)
		kit.flight114(foot, top, 3.2, 0.0)
		# le palier haut (un plateau de pierre jusqu'au bord de la galerie)
		var pal: Vector3 = (top + E(0.99, -90.0 + s * 6.0, y1)) * 0.5
		kit.box(Transform3D(Basis(), Vector3(pal.x, y1 - 0.25, pal.z)), Vector3(8.0, 0.5, 4.6), "pierre112_clair", 2.0)
		kit.box(Transform3D(Basis(), Vector3(pal.x, (y1 + F0) * 0.5 - 0.3, pal.z)), Vector3(7.6, y1 - F0 - 0.6, 4.2), "pierre112_sombre", 3.0, 63 - 4)
		kit.col_box(Transform3D(Basis(), Vector3(pal.x, y1 - 0.25, pal.z)), Vector3(8.0, 0.5, 4.6))
		var bn: String = _pt("st_p_esc_%s0" % ("e" if s > 0 else "o"), foot)
		var tn: String = _pt("st_p_esc_%s1" % ("e" if s > 0 else "o"), top)
		_link(bn, tn)
		_link(bn, "st_p_co_12" if absf(s) > 0 else "")
		_link(bn, _near_pt_named(foot, "st_p_ex_"))
		_link(tn, _near_pt_named(E(1.025, -90.0 + s * 8.0, y1), "st_p_g1_"))
		kit.lamp114(foot + (P(0, 0) - foot).normalized() * 2.5, 4.0, false, false)
	kit.box(Transform3D(Basis(), Vector3(land.x, y1 - 0.25, land.z + 2.0)), Vector3(12.0, 0.5, 5.0), "pierre112_clair", 2.0)
	kit.col_box(Transform3D(Basis(), Vector3(land.x, y1 - 0.25, land.z + 2.0)), Vector3(12.0, 0.5, 5.0))
	# le garde-corps au bord de la galerie (sauf au palier des escaliers)
	var n: int = 40
	for i in range(n):
		var a0: float = lerpf(G1_A0, G1_A1, float(i) / n)
		var a1: float = lerpf(G1_A0, G1_A1, float(i + 1) / n)
		if absf((a0 + a1) * 0.5 + 90.0) < 9.0:
			continue
		kit.rail114(E(G1_E0, a0, y1), E(G1_E0, a1, y1), 1.1)
	# les maisons creusées dans la paroi : des façades (le reste de la maison est dans la roche)
	var aa: float = G1_A0 + 6.0
	var gdoors := ["porte_agathe"]
	while aa < G1_A1 - 5.0:
		if absf(aa + 90.0) < 9.0:
			aa = -90.0 + 9.0
			continue
		var w: float = _rng.randf_range(7.5, 9.5)
		var xf: Transform3D = XE(G1_EH, aa, y1)
		var door: Vector3 = kit.house112(xf, w, 7.0, {"floors": 2, "lit": 0.8, "door_x": _rng.randf_range(-1.5, 1.5), "gf": 3.4, "uf": 2.9, "roof": "pignon", "chimney": false, "back": false, "v81": true, "balcons": true})
		if not gdoors.is_empty() and absf(aa + 90.0) < 30.0:
			_door(str(gdoors.pop_front()), door)
		aa += w / (R.GS_A * G1_EH) * 57.3 + 1.5
	# la Maison de la Guilde (au milieu, face aux escaliers) : une grande façade à colonnes, un balcon
	var gx: Transform3D = XE(G1_EH + 0.01, -90.0, y1)
	kit.house112(gx, 15.0, 8.0, {"floors": 2, "lit": 0.95, "door_x": 0.0, "gf": 3.8, "uf": 3.0, "roof": "mansarde", "chimney": false, "back": false, "balcons": true, "wall": "pierre112_clair"})
	for x in [-5.5, -2.0, 2.0, 5.5]:
		kit.cyl(gx * kit.T(x, 0, 0.6), 0.32, 0.28, 6.6, "pierre112_clair", 12)
	kit.box(gx * kit.T(0, 6.75, 0.6), Vector3(14.4, 0.4, 1.6), "pierre112_clair", 1.5)
	kit.sign114(gx * kit.T(0, 4.2, 0.15), "guilde", 4.6, 1.2)
	for s4 in [-1.0, 1.0]:
		kit.banner70(gx * kit.T(s4 * 3.8, 3.4, 0.2), 0.9, 2.4, "banniere112")
	_sp("st_guilde_balcon", gx * Vector3(0, 0, 2.6), P(0, 0, SOLEIL_Y), "observer")
	_sp("st_guilde_bureau", gx * Vector3(2.5, 0, 1.6), gx * Vector3(2.5, 0, 6), "lire")
	objets["guilde"] = gx * Vector3(0, 0, 2.4)
	# les points de vue de la galerie (on y regarde la caverne)
	var views := [-140.0, -115.0, -65.0, -40.0]
	for i2 in range(views.size()):
		var vp: Vector3 = E(0.99, float(views[i2]), y1)
		_sp("st_galerie_%d" % (i2 + 1), vp, P(0, 0, SOLEIL_Y), "observer")
	_crowd("st_crowd_galerie_1", E(1.0, -128.0, y1), P(0, 0, SOLEIL_Y), "observer")
	_crowd("st_crowd_galerie_2", E(1.0, -52.0, y1), P(0, 0, SOLEIL_Y), "observer")
	for k3 in range(5):
		var ap: float = lerpf(G1_A0 + 10.0, G1_A1 - 10.0, k3 / 4.0)
		kit.lamp114(E(1.0, ap, y1), 3.6, false, k3 % 2 == 0)
	# la Galerie 2 (plus haut) : des façades seules, leurs fenêtres allumées, des balcons
	var y2: float = R.G2_Y
	var ab: float = -145.0
	while ab < -35.0:
		var w2: float = _rng.randf_range(7.0, 9.0)
		var xf2: Transform3D = XE(0.985, ab, y2)
		kit.house112(xf2, w2, 6.0, {"floors": 2, "lit": 0.75, "door_x": 0.0, "gf": 3.2, "uf": 2.8, "roof": "pignon", "chimney": false, "back": false, "balcons": true})
		ab += w2 / (R.GS_A * 0.985) * 57.3 + 2.0
	for i3 in range(24):
		var b0: float = lerpf(-145.0, -35.0, float(i3) / 24.0)
		var b1: float = lerpf(-145.0, -35.0, float(i3 + 1) / 24.0)
		kit.rail114(E(0.9, b0, y2), E(0.9, b1, y2), 1.1)


func _near_pt_named(p: Vector3, prefix: String) -> String:
	return _near_pt(p, prefix)


# =================================================================== les Mines de Cristaux

func _mines() -> void:
	var mouth: Vector3 = P(-80.5, -8.0)
	var inward := Vector3(1, 0, 0.1).normalized()
	# le portail de bois (deux poteaux, un linteau, des étais), la lanterne
	var bs := Basis.looking_at(-inward, Vector3.UP)
	for s in [-1.0, 1.0]:
		kit.box(Transform3D(bs, mouth + bs.x * s * 3.2 + Vector3.UP * 2.8), Vector3(0.45, 5.6, 0.45), "bois112", 1.0)
		kit.col_box(Transform3D(bs, mouth + bs.x * s * 3.2 + Vector3.UP * 2.8), Vector3(0.45, 5.6, 0.45))
	kit.box(Transform3D(bs, mouth + Vector3.UP * 5.5), Vector3(7.4, 0.5, 0.5), "bois112", 1.0)
	kit.sign114(Transform3D(bs, mouth + Vector3.UP * 6.2 + inward * 0.3), "mines", 3.6, 0.9)
	# la voie : du milieu de la caverne (le quai des wagonnets) jusqu'au fond de la Grotte
	var pts := [E(0.62, 178.0), P(-70.0, -7.0), P(-80.0, -8.0), P(-104.0, -11.0, -98.0), P(-128.0, -14.0, -100.0), P(-146.0, -16.0, -100.0), P(-158.0, -22.0, -100.0)]
	var tp: Array = []
	for i in range(pts.size()):
		var q: Vector3 = pts[i]
		q.y = roche.floor_at(q.x - R.O.x, q.z - R.O.z, R.floor_y(q.x - R.O.x, q.z - R.O.z))
		tp.append(q)
	kit.track114(tp, false)
	# les wagonnets : trois au quai, deux dans la Grotte
	for k in range(3):
		var wp: Vector3 = (tp[1] as Vector3).lerp(tp[2], 0.15 + k * 0.28)
		kit.wagonnet114(XL(wp, tp[2]), k != 1)
	for k2 in range(2):
		var wp2: Vector3 = (tp[4] as Vector3).lerp(tp[5], 0.4 + k2 * 0.35)
		kit.wagonnet114(XL(wp2, tp[5]), true)
	# les étais du tunnel (des cadres de bois), des lampes de mine
	for k3 in range(6):
		var t: float = (k3 + 0.5) / 6.0
		var q2: Vector3 = (tp[2] as Vector3).lerp(tp[4], t)
		var dirq: Vector3 = ((tp[4] as Vector3) - (tp[2] as Vector3)).normalized()
		var b2 := Basis.looking_at(dirq, Vector3.UP)
		for s2 in [-1.0, 1.0]:
			kit.box(Transform3D(b2, q2 + b2.x * s2 * 2.7 + Vector3.UP * 2.2), Vector3(0.3, 4.4, 0.3), "bois112", 1.0)
		kit.box(Transform3D(b2, q2 + Vector3.UP * 4.45), Vector3(5.8, 0.3, 0.3), "bois112", 1.0)
		if k3 % 2 == 0:
			kit.ball(Transform3D(Basis(), q2 + Vector3.UP * 4.0 + b2.x * 2.4), 0.16, "lampe114", 8, 5)
	# le bureau du contremaître (une cabane de planches, contre la paroi, à gauche du portail)
	var ox: Transform3D = XL(P(-72.0, 6.0), P(-60.0, -2.0))
	kit.box(ox * kit.T(0, 1.4, -1.6), Vector3(4.2, 2.8, 3.2), "planches71_sombre", 1.2)
	kit.box(ox * kit.T(0, 2.95, -1.6), Vector3(4.6, 0.2, 3.6), "fer114_rouille", 1.0)
	kit.window112(ox * kit.T(-1.0, 1.6, 0.0), true, true)
	kit.door71(ox * kit.T(1.0, 0.0, 0.0), "planches71_sombre")
	kit.col_box(ox * kit.T(0, 1.4, -1.6), Vector3(4.2, 2.8, 3.2))
	kit.box(ox * kit.T(-1.6, 0.8, 0.5), Vector3(1.0, 0.06, 0.6), "bois112", 1.0)
	_sp("st_mine_bureau", ox * Vector3(-1.6, 0, 1.2), ox * Vector3(-1.6, 0.8, 0.5), "lire")
	_sp("st_mine_entree", mouth + inward * 4.0 + bs.x * 2.0, mouth, "bras_croises")
	_sp("st_mine_wagon", (tp[1] as Vector3).lerp(tp[2], 0.43) + XL(tp[1], tp[2]).basis.x * 1.2, (tp[1] as Vector3).lerp(tp[2], 0.43), "bricoler")
	# dans la Grotte : le front de taille (une échelle, des outils), le treuil
	var front: Vector3 = R.W(-162.0, -8.0, -100.0)
	_sp("st_mine_front", front, R.W(-168.0, -6.0, -98.0), "bricoler")
	kit.box(XL(front + Vector3(1.5, 0, 1.0), front + Vector3(-5, 0, 0)) * kit.T(0, 0.5, 0), Vector3(1.6, 1.0, 0.8), "bois112", 1.0)
	for k4 in range(3):
		_light(R.W(-150.0 + k4 * 7.0, -18.0 + k4 * 4.0, -92.0), Color(0.45, 0.7, 1.0), 2.4, 2.4, 26.0)
	_light(mouth + inward * -6.0 + Vector3.UP * 4.0, Color(1.0, 0.72, 0.42), 0.9, 1.2, 12.0)
	objets["mines"] = mouth - inward * 3.5
	objets["grotte"] = R.W(-146.0, -16.0, -100.0)
	# le réseau : de la couronne au portail, au fond de la Grotte
	var m0: String = _pt("st_p_mi_0", E(0.86, 182.0))
	var m1: String = _pt("st_p_mi_1", mouth + inward * 2.0)
	var m2: String = _pt("st_p_mi_2", R.W(-104.0, -9.5, roche.floor_at(-104.0, -9.5, R.floor_y(-104.0, -9.5))))
	var m3: String = _pt("st_p_mi_3", R.W(-128.0, -12.5, -100.0))
	var m4: String = _pt("st_p_mi_4", R.W(-148.0, -12.0, -100.0))
	var m5: String = _pt("st_p_mi_5", R.W(-160.0, -10.0, -100.0))
	_chain(["st_p_ex_8", m0, m1, m2, m3, m4, m5])
	_link(m0, "st_p_co_8")


# =================================================================== les Jardins des Champignons

func _jardins() -> void:
	var y0: float = R.JA_C.y
	# l'arche : deux piles de pierre, une enseigne
	var arch: Vector3 = P(2.0, 60.0)
	var ab := Basis.looking_at(Vector3(0, 0, -1), Vector3.UP)
	kit.sign114(Transform3D(ab, arch + Vector3.UP * 7.8 + Vector3(0, 0, -0.5)), "jardins", 4.4, 1.1)
	kit.box(Transform3D(ab, arch + Vector3.UP * 8.6), Vector3(7.0, 0.2, 0.2), "fer114", 1.0)
	# l'allée (des planches posées sur la poussière)
	var path_pts := [P(2.0, 56.0), P(4.0, 70.0, -97.5), P(6.0, 80.0, y0), P(4.0, 92.0, y0), P(-2.0, 104.0, y0), P(8.0, 116.0, y0)]
	for i0 in range(path_pts.size()):
		var q0: Vector3 = path_pts[i0]
		path_pts[i0] = Vector3(q0.x, roche.floor_at(q0.x - R.O.x, q0.z - R.O.z, q0.y), q0.z)
	for i in range(path_pts.size() - 1):
		var a: Vector3 = path_pts[i]
		var b: Vector3 = path_pts[i + 1]
		var d: Vector3 = b - a
		kit.box(Transform3D(Basis.looking_at(d.normalized(), Vector3.UP), (a + b) * 0.5 + Vector3.UP * 0.05), Vector3(2.4, 0.06, d.length()), "planches71", 1.0, 4)
	# l'étang noir, sa margelle de pierres
	var ep: Vector3 = P(R.ETANG.x, R.ETANG.y, y0 - 0.55)
	kit.disc(Transform3D(Basis(), ep), R.ETANG_R + 0.6, "eau114", 40)
	for k in range(26):
		var a2: float = TAU * k / 26.0
		var sp: Vector3 = P(R.ETANG.x + cos(a2) * (R.ETANG_R + 1.3), R.ETANG.y + sin(a2) * (R.ETANG_R + 1.3), y0)
		kit.ball(Transform3D(Basis(Vector3.UP, a2), sp), _rng.randf_range(0.35, 0.6), "pierre112_sombre", 7, 4)
	# la cascade : un ruban d'eau qui tombe d'une fissure de la voûte dans l'étang
	var top: Vector3 = P(R.ETANG.x + 4.0, R.ETANG.y + 3.0, y0 + 19.0)
	_cascade(top, P(R.ETANG.x + 4.0, R.ETANG.y + 3.0, y0 - 0.4))
	objets["cascade"] = top
	# les champignons géants (bleus, verts, roses, ambre), et les petits par grappes
	var colors := ["bleu", "vert", "rose", "ambre"]
	var giants := [[-14.0, 88.0, 5.5, 2.8], [-20.0, 100.0, 7.0, 3.6], [24.0, 88.0, 4.2, 2.2], [30.0, 98.0, 6.2, 3.2], [-8.0, 116.0, 4.8, 2.6],
		[22.0, 116.0, 5.0, 2.4], [-26.0, 92.0, 3.4, 1.8], [12.0, 84.0, 2.6, 1.5], [-12.0, 108.0, 3.0, 1.6], [34.0, 108.0, 3.6, 1.9],
		[-24.0, 112.0, 8.0, 4.2], [36.0, 90.0, 6.8, 3.4], [-2.0, 120.0, 6.0, 3.0], [-30.0, 100.0, 4.4, 2.2], [26.0, 104.0, 2.8, 1.4], [-18.0, 84.0, 3.8, 2.0]]
	for i2 in range(giants.size()):
		var g: Array = giants[i2]
		kit.champi114(P(float(g[0]), float(g[1]), y0), float(g[2]), float(g[3]), colors[i2 % 4], _rng.randf_range(-8.0, 8.0), _rng.randf() * TAU)
		if i2 < 8:
			_light(P(float(g[0]), float(g[1]), y0 + float(g[2]) - 0.6), [Color(0.4, 0.7, 1.0), Color(0.45, 1.0, 0.6), Color(1.0, 0.5, 0.8), Color(1.0, 0.7, 0.35)][i2 % 4], 0.9, 1.2, 12.0)
	for k2 in range(110):
		var a3: float = _rng.randf() * TAU
		var r: float = _rng.randf_range(10.0, 28.0)
		var q := Vector2(R.JA_C.x + cos(a3) * r, R.JA_C.z + sin(a3) * r * 0.75)
		if Vector2(q.x - R.ETANG.x, q.y - R.ETANG.y).length() < R.ETANG_R + 2.0:
			continue
		var h: float = _rng.randf_range(0.25, 0.9)
		kit.champi114(P(q.x, q.y, y0), h, h * _rng.randf_range(0.5, 0.8), colors[k2 % 4], _rng.randf_range(-12, 12), _rng.randf() * TAU, false)
	# les planches de culture de Bertille (des bacs de bois pleins de terre noire, de petits champignons)
	for k3 in range(3):
		var bx: Transform3D = XL(P(-6.0 + k3 * 6.0, 94.0, y0), P(-6.0 + k3 * 6.0, 104.0, y0))
		kit.box(bx * kit.T(0, 0.3, 0), Vector3(4.0, 0.6, 1.4), "bois112", 1.0)
		kit.box(bx * kit.T(0, 0.58, 0), Vector3(3.8, 0.06, 1.2), "terre71", 1.0)
		for k4 in range(6):
			kit.champi114(bx * Vector3(-1.5 + k4 * 0.6, 0.6, _rng.randf_range(-0.3, 0.3)), 0.22, 0.14, colors[(k3 + k4) % 4], 0.0, 0.0, false)
		kit.col_box(bx * kit.T(0, 0.3, 0), Vector3(4.0, 0.6, 1.4))
		_sp("st_jardin_%d" % (k3 + 1), bx * Vector3(0, 0, -1.2), bx * Vector3(0, 0.5, 0), "jardiner")
	# la cabane de Bertille (une petite maison ronde de pierre, un toit de bardeaux)
	var hx: Transform3D = XL(P(-24.0, 108.0, y0), P(-6.0, 100.0, y0))
	kit.cyl(Transform3D(Basis(), hx * Vector3(0, 0, -2.6)), 2.8, 2.8, 3.0, "pierre112_rose", 16, false, 2.0)
	kit.cyl(Transform3D(Basis(), hx * Vector3(0, 3.0, -2.6)), 3.3, 0.2, 2.4, "ardoise112", 16, true, 2.0)
	kit.door71(hx * kit.T(0, 0, 0.18), "planches71_sombre")
	kit.window112(hx * Transform3D(Basis(Vector3.UP, 0.7), Vector3(-1.6, 1.6, -0.7)), true, true)
	kit.col_cyl(hx * Vector3(0, 0, -2.6), 2.8, 3.2)
	_door("porte_bertille", hx * Vector3(0, 0, 1.2))
	# le banc au bord de l'étang
	var bp: Vector3 = P(R.ETANG.x - 11.5, R.ETANG.y + 2.0, y0)
	kit.bench112(XL(bp, ep))
	_sp("st_jardin_banc", bp + (ep - bp).normalized() * 0.3, ep, "assis")
	_sp("st_jardin_bassin", P(R.ETANG.x - 3.0, R.ETANG.y - 11.0, y0), ep, "observer")
	_crowd("st_crowd_jardin_1", P(0.0, 96.0, y0), ep, "observer")
	_crowd("st_crowd_jardin_2", P(10.0, 90.0, y0), P(30.0, 98.0, y0), "observer")
	objets["jardins"] = P(4.0, 86.0, y0)
	objets["etang"] = ep
	# le réseau : de l'avenue sud, sous l'arche, le long de l'allée
	var jn: Array = []
	for i3 in range(path_pts.size()):
		var q2: Vector3 = path_pts[i3]
		jn.append(_pt("st_p_ja_%d" % i3, q2))
	_chain(jn)
	_link("st_p_co_4", jn[0])
	_link(jn[3], _pt("st_p_ja_b", P(-6.0, 100.0, y0)))
	_link("st_p_ja_b", "porte_bertille")


## Une cascade : un ruban d'eau qui tombe (le shader de la Cascade des Nuées), sa brume au pied.
func _cascade(top: Vector3, bottom: Vector3) -> void:
	var sh: Shader = load("res://shaders/chute_ciel_v54.gdshader") if ResourceLoader.exists("res://shaders/chute_ciel_v54.gdshader") else null
	var mi := MeshInstance3D.new()
	mi.name = "Cascade_jardins"
	var qm := QuadMesh.new()
	qm.size = Vector2(1.6, top.y - bottom.y)
	mi.mesh = qm
	if sh != null:
		var m := ShaderMaterial.new()
		m.shader = sh
		mi.material_override = m
	else:
		var m2 := StandardMaterial3D.new()
		m2.albedo_color = Color(0.7, 0.85, 0.95, 0.5)
		m2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mi.material_override = m2
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = (top + bottom) * 0.5
	mi.rotation.y = 0.6
	var mi2: MeshInstance3D = mi.duplicate()
	add_child(mi2)
	mi2.global_position = (top + bottom) * 0.5
	mi2.rotation.y = 0.6 + PI * 0.5
	var mist := CPUParticles3D.new()
	mist.name = "Brume_cascade"
	mist.amount = 40 if pc else 16
	mist.lifetime = 3.0
	mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mist.emission_sphere_radius = 1.2
	mist.direction = Vector3.UP
	mist.spread = 60.0
	mist.initial_velocity_min = 0.3
	mist.initial_velocity_max = 0.9
	mist.gravity = Vector3(0, 0.05, 0)
	mist.scale_amount_min = 1.2
	mist.scale_amount_max = 2.6
	var qm2 := QuadMesh.new()
	qm2.size = Vector2(1, 1)
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.85, 0.92, 0.95, 0.12)
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm2.material = pm
	mist.mesh = qm2
	add_child(mist)
	mist.global_position = bottom + Vector3.UP * 0.6


# =================================================================== le Petit Train des Strates

func _petit_train() -> void:
	# la voie : l'ovale e = TRAIN_E (fermé)
	var n: int = 96
	for k in range(n):
		train_path.append(E(TRAIN_E, 360.0 * k / n) + Vector3.UP * 0.02)
	for k in range(n):
		train_len += (train_path[k] as Vector3).distance_to(train_path[(k + 1) % n])
	kit.track114(train_path, true)
	# la gare du Petit Train (au sud-ouest) : un quai de pierre, un abri à marquise
	var st_deg: float = 122.0
	var qx: Transform3D = XE(TRAIN_E - 0.045, st_deg)
	kit.box(qx * kit.T(0, 0.2, 0), Vector3(14.0, 0.4, 3.0), "pierre112_clair", 2.0)
	kit.col_box(qx * kit.T(0, 0.2, 0), Vector3(14.0, 0.4, 3.0))
	for x in [-5.0, 0.0, 5.0]:
		kit.cyl(qx * kit.T(x, 0.4, -0.8), 0.1, 0.1, 3.2, "fer114", 8, false)
	kit.box(qx * kit.T(0, 3.65, -0.4), Vector3(13.0, 0.12, 2.8), "fer114", 1.0)
	kit.box(qx * kit.T(0, 3.75, -0.4), Vector3(12.6, 0.04, 2.4), "verre112", 1.0)
	kit.sign114(qx * kit.T(0, 2.9, -0.7), "train", 3.0, 0.75)
	kit.bench112(qx * kit.T(-3.0, 0.4, -0.9))
	_sp("st_train_quai", qx * Vector3(2.0, 0.4, 0.3), qx * Vector3(2.0, 0.4, 3.0), "debout")
	objets["train"] = qx * Vector3(0, 0.4, 0.6)
	_link(_pt("st_p_train", qx * Vector3(0, 0.4, -0.2)), _near_pt_named(qx.origin, "st_p_ex_"))
	# le dépôt (au nord-ouest) : une halle de briques sur la voie
	var dx: Transform3D = XE(TRAIN_E + 0.07, -158.0)
	kit.box(dx * kit.T(0, 3.2, -4.0), Vector3(12.0, 6.4, 0.5), "pierre112_sombre", 2.0)
	for s in [-1.0, 1.0]:
		kit.box(dx * kit.T(s * 6.0, 3.2, 0.5), Vector3(0.5, 6.4, 9.5), "pierre112_sombre", 2.0)
		kit.col_box(dx * kit.T(s * 6.0, 3.2, 0.5), Vector3(0.5, 6.4, 9.5))
	kit.roof_gable(dx * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, 6.4, 0.5)), 10.0, 12.6, 30.0, 0.3, "ardoise112", "pierre112_sombre")
	var tb: Transform3D = dx * kit.T(-3.5, 0, 2.0)
	kit.box(tb * kit.T(0, 0.9, 0), Vector3(2.4, 0.08, 1.0), "bois112", 1.0)
	kit.col_box(tb * kit.T(0, 0.5, 0), Vector3(2.4, 1.0, 1.0))
	_sp("st_train_depot", tb * Vector3(0, 0, 0.9), tb * Vector3(0, 0.9, 0), "bricoler")
	objets["depot"] = dx * Vector3(0, 0, 3.0)
	_crowd("st_crowd_train", qx * Vector3(-4.5, 0.4, 0.4), qx * Vector3(-4.5, 0.4, 3.0), "debout")
	# des passants le long de la couronne
	for k5 in range(6):
		var a5: float = 30.0 + k5 * 60.0
		_crowd("st_crowd_co_%d" % k5, E(0.6, a5), E(0.6, a5 + 20.0), ["debout", "bras_croises", "observer"][k5 % 3])
	# le train : une locomotive verte et laiton, deux voitures à bancs, sous un toit
	train = Node3D.new()
	train.name = "Petit_train"
	add_child(train)
	train.add_child(_loco_mesh())
	for i in range(2):
		var car := Node3D.new()
		car.name = "Voiture_%d" % i
		add_child(car)
		car.add_child(_voiture_mesh(i))
		train_cars.append([car, 6.4 + i * 5.6])
	train_s = 0.0


func _sub_mesh(build: Callable) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var tk = Kit.new()
	tk.setup(mi, null)
	build.call(tk)
	var mesh := ArrayMesh.new()
	for k in tk.batch:
		var st: SurfaceTool = tk.batch[k]
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, tk.mat(str(k)))
	mi.mesh = mesh
	return mi


func _loco_mesh() -> MeshInstance3D:
	return _sub_mesh(func(tk):
		var T := func(x, y, z): return Transform3D(Basis(), Vector3(x, y, z))
		# le châssis, les roues rouges, la chaudière verte cerclée de laiton, la cabine, la cheminée
		tk.box(T.call(0, 0.55, 0), Vector3(1.3, 0.3, 4.4), "fer114", 1.0)
		for z in [-1.4, -0.3, 0.8]:
			for s in [-1.0, 1.0]:
				tk.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(s * 0.66, 0.42, z)), 0.38, 0.38, 0.1, "tole114_rouge", 14)
		tk.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 1.3, 0.25)), 0.62, 0.62, 2.6, "tole114_vert", 18, true, 1.0)
		for z2 in [-0.9, 0.0, 0.9]:
			tk.ring(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 1.3, z2)), 0.61, 0.66, 0.08, "laiton112", 18)
		tk.cyl(T.call(0, 1.85, 1.1), 0.18, 0.28, 1.0, "fer114", 10)
		tk.cyl(T.call(0, 2.85, 1.1), 0.3, 0.3, 0.12, "laiton112", 10)
		tk.ball(T.call(0, 1.95, 0.0), 0.28, "laiton112", 10, 5)
		tk.ball(T.call(0, 1.3, 1.56), 0.2, "lampe114", 10, 6)
		tk.box(T.call(0, 1.6, -1.55), Vector3(1.4, 1.8, 1.2), "tole114_vert", 1.0)
		tk.box(T.call(0, 2.58, -1.55), Vector3(1.6, 0.12, 1.5), "fer114", 1.0)
		tk.box(T.call(0, 1.9, -0.94), Vector3(1.0, 0.6, 0.04), "vitre114", 1.0)
		tk.box(T.call(0, 0.42, 2.25), Vector3(1.2, 0.3, 0.2), "tole114_rouge", 1.0))


func _voiture_mesh(i: int) -> MeshInstance3D:
	return _sub_mesh(func(tk):
		var T := func(x, y, z): return Transform3D(Basis(), Vector3(x, y, z))
		tk.box(T.call(0, 0.6, 0), Vector3(1.4, 0.2, 4.4), "tole114_creme" if i == 0 else "tole114_bleu", 1.0)
		for z in [-1.5, 1.5]:
			for s in [-1.0, 1.0]:
				tk.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(s * 0.66, 0.34, z)), 0.3, 0.3, 0.1, "tole114_rouge", 12)
		for z2 in [-1.4, -0.45, 0.5, 1.45]:
			tk.box(T.call(0, 0.95, z2), Vector3(1.2, 0.08, 0.5), "bois112", 1.0)
			tk.box(T.call(0, 1.25, z2 - 0.24), Vector3(1.2, 0.5, 0.06), "bois112", 1.0)
		for s2 in [-1.0, 1.0]:
			for z3 in [-2.1, 2.1]:
				tk.cyl(T.call(s2 * 0.62, 0.7, z3), 0.04, 0.04, 1.6, "laiton112", 6)
		tk.box(T.call(0, 2.35, 0), Vector3(1.6, 0.1, 4.6), "tole114_creme" if i == 0 else "tole114_bleu", 1.0)
		for s3 in [-1.0, 1.0]:
			tk.box(T.call(s3 * 0.7, 0.85, 0), Vector3(0.05, 0.3, 4.3), "laiton112", 1.0))


# =================================================================== vers la Fronde

func _vers_la_fronde() -> void:
	# le portail du tunnel (des piles de pierre, une bannière de la Fronde, une enseigne fleurie de
	# graffitis) ; l'enseigne « La Fronde » est de l'autre côté du Pont (fronde_v114)
	var mouth: Vector3 = P(80.5, 10.0)
	var out := Vector3(-1, 0, -0.45).normalized()
	var bs := Basis.looking_at(-out, Vector3.UP)
	for s in [-1.0, 1.0]:
		kit.box(Transform3D(bs, mouth + bs.x * s * 4.2 + Vector3.UP * 3.0), Vector3(1.0, 6.0, 1.0), "pierre112_clair", 1.5)
		kit.col_box(Transform3D(bs, mouth + bs.x * s * 4.2 + Vector3.UP * 3.0), Vector3(1.0, 6.0, 1.0))
		kit.lamp114(mouth + bs.x * s * 4.2 + out * 1.2, 4.0, false, false)
	kit.box(Transform3D(bs, mouth + Vector3.UP * 6.3), Vector3(9.6, 0.6, 1.0), "pierre112_clair", 1.5)
	kit.sign114(Transform3D(bs, mouth + Vector3.UP * 6.3 + out * 0.55), "pont", 4.0, 0.8)
	var e0: String = _pt("st_p_fr_0", E(0.9, 4.0))
	var e1: String = _pt("st_p_fr_1", mouth + out * 1.0)
	_chain(["st_p_ex_0", e0, e1])
	_link(e0, "st_p_co_0")
	objets["tunnel_fronde"] = mouth


# =================================================================== les lumières

func _lumieres_reelles() -> void:
	for ls in kit.light_spots:
		_light(ls[0], ls[1], float(ls[2]) * 0.7, float(ls[2]), float(ls[3]))


# =================================================================== les zones

## Où est-on, dans les Strates ? (pour la musique, les ambiances, le nom du lieu)
func zone_at(p: Vector3) -> String:
	if fronde != null:
		var fz: String = fronde.zone_at(p)
		if fz != "":
			return fz
	var l: Vector3 = R.L(p)
	if ligne != null and ligne.in_deep_cabin(p):
		return "st_ligne"
	if l.x < -82.0:
		return "st_grotte" if l.x < -124.0 else "st_mines"
	if l.z > 62.0:
		return "st_jardins"
	if l.x > 80.0:
		return "st_pont"
	if l.y > R.G1_Y - 1.5 and l.z < 0.0:
		var g: Vector3 = objets.get("guilde", Vector3.ZERO)
		if Vector2(p.x - g.x, p.z - g.z).length() < 12.0:
			return "st_guilde"
		return "st_galeries"
	var r: float = Vector2(l.x, l.z).length()
	if r < 12.0:
		return "st_gare"
	var e: float = R.e_gs(l.x, l.z)
	for k in [["forge", "st_forge", 15.0], ["marmite", "st_marmite", 11.0], ["lumieres", "st_lumieres", 9.0], ["train", "st_train", 9.0], ["depot", "st_train", 10.0]]:
		var o: Vector3 = objets.get(str(k[0]), Vector3.INF)
		if o != Vector3.INF and Vector2(p.x - o.x, p.z - o.z).length() < float(k[2]):
			return str(k[1])
	if r < 31.0:
		return "st_place"
	if e > 0.9:
		return "st_bord"
	return "st_ville"


# =================================================================== la vie

func tick(delta: float, night: float, near: bool) -> void:
	_clock += delta
	if soleil_light != null:
		soleil_light.light_energy = lerpf(8.0, 2.2, night)
		soleil_light.light_color = Color(1.0, 0.9, 0.74).lerp(Color(1.0, 0.66, 0.38), night)
	for l in lights:
		(l[0] as OmniLight3D).light_energy = lerpf(float(l[1]), float(l[2]), night)
	if not near:
		return
	for r in soleil_rings:
		(r[0] as Node3D).rotate_y(float(r[1]) * delta)
	for g in gears:
		(g[0] as Node3D).rotate_object_local(Vector3.FORWARD, float(g[1]) * delta)
	# le marteau-pilon : il monte lentement, retombe d'un coup
	if hammer != null:
		var ph: float = fmod(_clock, 3.2) / 3.2
		var up: float = ph / 0.8 if ph < 0.8 else 1.0 - (ph - 0.8) / 0.2
		hammer.position.y = float(hammer.get_meta("y0")) + up * 1.6
	_train_tick(delta)


func _train_tick(delta: float) -> void:
	if train == null or train_path.is_empty():
		return
	# il roule (5 m/s), s'arrête vingt secondes à sa gare
	if train_stop > 0.0:
		train_stop -= delta
	else:
		var prev: float = train_s
		train_s = fmod(train_s + delta * 5.0, train_len)
		var st_s: float = _path_s_of(objets.get("train", Vector3.ZERO))
		if prev < st_s and train_s >= st_s:
			train_stop = 20.0
	_place_on_path(train, train_s)
	for c in train_cars:
		_place_on_path(c[0], fmod(train_s - float(c[1]) + train_len, train_len))


var _st_s_cache: float = -1.0


func _path_s_of(p: Vector3) -> float:
	if _st_s_cache >= 0.0:
		return _st_s_cache
	var best: float = INF
	var acc: float = 0.0
	var s_best: float = 0.0
	for k in range(train_path.size()):
		var a: Vector3 = train_path[k]
		var d: float = Vector2(a.x - p.x, a.z - p.z).length()
		if d < best:
			best = d
			s_best = acc
		acc += a.distance_to(train_path[(k + 1) % train_path.size()])
	_st_s_cache = s_best
	return s_best


func _place_on_path(n: Node3D, s: float) -> void:
	var acc: float = 0.0
	var cnt: int = train_path.size()
	for k in range(cnt):
		var a: Vector3 = train_path[k]
		var b: Vector3 = train_path[(k + 1) % cnt]
		var l: float = a.distance_to(b)
		if acc + l >= s:
			var t: float = (s - acc) / l
			var p: Vector3 = a.lerp(b, t)
			n.global_transform = Transform3D(Basis.looking_at(-(b - a).normalized(), Vector3.UP), p)
			return
		acc += l
