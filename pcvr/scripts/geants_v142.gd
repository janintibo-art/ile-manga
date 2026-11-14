extends Node3D
## V142 : l'Île des Géants — le chef d'orchestre. Il construit le relief (ile_geants_v142), puis, après
## l'heure du jour, la ferme des Grandpré (geants_kit_v142 : la maison, la grange, le moulin, le puits,
## la clôture du potager, la corde à linge, les objets oubliés dehors), la végétation à l'échelle des
## géants (geants_flore_v142), l'eau de la mare, et la famille Grandpré elle-même (cinq géants :
## pnj/geants_habitants_v142, pnj/pnj_geant_v142). Il fait tourner les ailes du moulin, fumer la
## cheminée, onduler le linge, briller les fenêtres la nuit (et l'on entend ronfler la maison) ; à
## chaque pas d'un géant, le sol tremble près de lui. Il tient les trois petites quêtes de l'île :
## la bague de Mère Mathurine (cachée dans le potager), les limaces du potager (oncle Théophile) et
## le cache-cache avec Pâquerette.

const IleScript = preload("res://scripts/ile_geants_v142.gd")
const Kit = preload("res://scripts/geants_kit_v142.gd")
const Limace = preload("res://scripts/limace_v142.gd")
const FLORE := "res://scripts/geants_flore_v142.gd"
const HABITANTS := "res://scripts/pnj/geants_habitants_v142.gd"
const PNJ := "res://scripts/pnj/pnj_geant_v142.gd"

const PLACES := {"gt_ponton": "le Ponton des Petits", "gt_greve": "la grève", "gt_rivage": "le rivage", "gt_maison": "la maison des Grandpré",
	"gt_cour": "la cour de la ferme", "gt_grange": "la grange", "gt_potager": "le potager", "gt_verger": "le verger",
	"gt_ble": "le champ de blé", "gt_moulin": "le Moulin de la Butte", "gt_mare": "la mare aux nénuphars", "gt_pres": "les prés"}
## Les cachettes de Pâquerette (repère île) et ce qu'on entend
const CACHETTES := [
	[Vector2(-62.0, 34.0), "Hi hi hi… (on entend pouffer du côté des balles de foin, derrière la grange)"],
	[Vector2(16.0, 101.0), "Hi hi… (ça glousse au milieu du champ de blé, et les épis bougent tout seuls)"],
	[Vector2(-168.0, -116.0), "Hi hi hi ! (un rire étouffé, derrière le moulin)"],
	[Vector2(126.0, 142.0), "Hi hi… (quelque chose de très grand se cache derrière un pommier… et ce n'est pas très réussi)"],
	[Vector2(-142.0, 140.0), "Hi hi hi… (les massettes de la mare tremblent, et on voit dépasser une tresse blonde)"],
]
## Le fauteuil à bascule de Grand-mère : le dossier contre la maison, elle regarde la cour (au nord)
const FAUTEUIL_YAW: float = 0.35
const LIMACES_N: int = 6
const LIMACES_BUT: int = 6

var main: Node
var ile: Node3D
var flore: Node3D
var pc: bool = true
var state: Dictionary = {}
var habitants: Array = []
var by_id: Dictionary = {}
var stations: Dictionary = {}             # lieu -> {"pos", "face", "pose"}
var graph: Dictionary = {}
var lieux: Dictionary = {}                # pour le carnet (journal_v56.lieux)
var ailes: Node3D
var reperes: Dictionary = {}              # la maison (seuil, fumée…), la grange, le moulin
var limaces: Array = []
var pas_total: int = 0
var cache_rond: int = -1                  # la cachette du tour en cours (-1 : pas de partie)
var _cache_phase: String = ""             # compte, cachee, trouvee
var _cache_t: float = 0.0
var _rire_t: float = 0.0
var _fumee: CPUParticles3D
var _clock: float = 0.0
var _rng := RandomNumberGenerator.new()
var _lim_t: float = 0.0
var _ronfle_t: float = 4.0
var _built: bool = false
var _interactions: Array = []
var _pommes_ok: bool = false


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_rng.seed = 14250
	state = _fresh_state()


func _fresh_state() -> Dictionary:
	return {"visite": false, "visites": {}, "limaces": 0, "cache": 0, "moulin": false}


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_geants_v142"
	add_child(ile)
	ile.build(pc)


func dock() -> Array:
	return [IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y), IleScript.W(IleScript.DOCK_B.x, IleScript.DOCK_B.y)]


## Après le relief et l'heure du jour : la ferme, la végétation, l'eau, les géants.
func build_town() -> void:
	if _built:
		return
	_built = true
	var t0: int = Time.get_ticks_msec()
	var y0: float = IleScript.PLATEAU_Y
	var b := Kit.Batch.new()
	var cols := Kit.Cols.new(self, "Geants_collisions")
	reperes["maison"] = Kit.maison(b, cols, y0)
	b.commit(self, "Maison_geants", true)
	reperes["grange"] = Kit.grange(b, cols, y0)
	b.commit(self, "Grange_geants", true)
	reperes["moulin"] = Kit.moulin(b, cols, self)
	ailes = reperes["moulin"]["ailes"]
	b.commit(self, "Moulin_geants", true)
	reperes["puits"] = Kit.puits(b, cols, _w(IleScript.PUITS.x, IleScript.PUITS.y))
	Kit.cloture(b, cols, ile)
	Kit.brouette(b, cols, _w(48.0, -30.0), 0.5)
	Kit.arrosoir(b, cols, _w(107.0, -2.0), 1.2)
	Kit.seau(b, _w(-26.0, -48.0), 0.3)
	Kit.bottes(b, cols, _w(9.0, -33.0), PI + 0.2)
	Kit.rateau(b, _w(63.5, -24.0), _w(64.5, -24.0) + Vector3(0.0, 11.5, 2.6))
	Kit.fauteuil(b, cols, _w(26.0, -40.0), FAUTEUIL_YAW)
	Kit.pelote(b, _w(31.0, -44.0), "rouge")
	Kit.pelote(b, _w(33.0, -41.0), "geranium_rose")
	Kit.epouvantail(b, cols, _w(107.0, 38.0), 0.4)
	for bl in [[Vector2(-58.0, 26.0), 0.3], [Vector2(-52.0, 38.0), 1.2], [Vector2(-66.0, 44.0), 0.2]]:
		Kit.balle_foin(b, cols, _w((bl[0] as Vector2).x, (bl[0] as Vector2).y), float(bl[1]))
	Kit.chateau_sable(b, cols, ile, IleScript.CHATEAU_SABLE)
	var mr := RandomNumberGenerator.new()
	mr.seed = 1427
	for mu in IleScript.MURETS:
		Kit.muret(b, cols, ile, mu, mr)
	b.commit(self, "Ferme_geants", true)
	var pts: Array = Kit.corde_linge(b, cols, _w(IleScript.LINGE_A.x, IleScript.LINGE_A.y), _w(IleScript.LINGE_B.x, IleScript.LINGE_B.y))
	b.commit(self, "Corde_linge", true)
	_linge(pts)
	_mare()
	if ResourceLoader.exists(FLORE):
		flore = load(FLORE).new()
		flore.name = "Flore_geants_v142"
		add_child(flore)
		flore.avoid.append([Vector2(26.0, -40.0), 8.0])
		flore.avoid.append([IleScript.LINGE_A.lerp(IleScript.LINGE_B, 0.5), 22.0])
		flore.avoid.append([Vector2(-60.0, 34.0), 14.0])
		flore.avoid.append([IleScript.CHATEAU_SABLE, 26.0])
		flore.build(ile, pc)
	_fumee = _make_smoke(reperes["maison"]["fumee"])
	_glows()
	_stations()
	_spawn_geants()
	print("ILE_MANGA_V142: l'Île des Géants est prête (%d ms)" % (Time.get_ticks_msec() - t0))


func _w(x: float, z: float, dy: float = 0.0) -> Vector3:
	return IleScript.W(x, z, ile.height_l(x, z) + dy)


## Le linge sur la corde : deux draps, une chemise, la robe jaune de Pâquerette, des chaussettes
func _linge(pts: Array) -> void:
	var along: Vector3 = (pts[pts.size() - 1] as Vector3) - (pts[0] as Vector3)
	var items := [[2, 5.6, 7.2, "linge_blanc", "drap"], [5, 3.4, 4.6, "linge_bleu", "chemise"], [8, 5.6, 7.0, "linge_raye", "drap"],
		[11, 3.0, 4.4, "linge_jaune", "robe"], [13, 0.9, 2.6, "linge_rouge", "chaussette"], [14, 0.9, 2.6, "linge_vert", "chaussette"]]
	for it in items:
		var top: Vector3 = pts[int(it[0])]
		Kit.linge(self, top - Vector3.UP * 0.15, along, float(it[1]), float(it[2]), str(it[3]), str(it[4]))


## L'eau de la mare : une ellipse, un peu plus grande que la cuvette
func _mare() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c: Vector3 = IleScript.W(IleScript.MARE.x, IleScript.MARE.y, IleScript.MARE_Y)
	var n: int = 48
	for i in range(n):
		var a0: float = TAU * i / n
		var a1: float = TAU * (i + 1) / n
		var p0: Vector3 = c
		var p1: Vector3 = c + Vector3(cos(a0) * IleScript.MARE_AX.x, 0, sin(a0) * IleScript.MARE_AX.y) * 1.06
		var p2: Vector3 = c + Vector3(cos(a1) * IleScript.MARE_AX.x, 0, sin(a1) * IleScript.MARE_AX.y) * 1.06
		for p in [p0, p2, p1]:
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(p.x, p.z) * 0.1)
			st.add_vertex(p)
	var mi := MeshInstance3D.new()
	mi.name = "Mare_geants"
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.13, 0.2, 0.15, 0.9)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.05
	m.metallic_specular = 0.9
	if ResourceLoader.exists("res://assets/textures/water/water_n.png"):
		m.normal_enabled = true
		m.normal_texture = load("res://assets/textures/water/water_n.png")
		m.normal_scale = 0.3
		m.uv1_scale = Vector3(0.5, 0.5, 0.5)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Les nénuphars portent le tout petit visiteur (on saute de feuille en feuille)
func _nenuphars_cols() -> void:
	if flore == null:
		return
	var body := StaticBody3D.new()
	body.name = "Nenuphars_collisions"
	add_child(body)
	for p in flore.nenuphars:
		var cs := CollisionShape3D.new()
		var cy := CylinderShape3D.new()
		cy.radius = 1.25
		cy.height = 0.2
		cs.shape = cy
		cs.position = (p as Vector3) + Vector3.DOWN * 0.08
		body.add_child(cs)


func _make_smoke(at: Vector3) -> CPUParticles3D:
	var s := CPUParticles3D.new()
	s.name = "Fumee_cheminee"
	s.amount = 14
	s.lifetime = 9.0
	s.direction = Vector3(0.25, 1, 0.1)
	s.spread = 10.0
	s.initial_velocity_min = 2.0
	s.initial_velocity_max = 3.2
	s.gravity = Vector3(0.8, 0.2, 0.2)
	s.scale_amount_min = 4.0
	s.scale_amount_max = 7.0
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.35))
	curve.add_point(Vector2(1.0, 1.8))
	s.scale_amount_curve = curve
	var qm := QuadMesh.new()
	qm.size = Vector2(1.6, 1.6)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.72, 0.72, 0.72, 0.28)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	qm.material = m
	s.mesh = qm
	s.visibility_aabb = AABB(Vector3(-30, -5, -30), Vector3(60, 90, 60))
	add_child(s)
	s.global_position = at
	s.emitting = true
	return s


## La nuit, les fenêtres éclairées s'allument
func _glows() -> void:
	var t: Node = main.get("temps_v56") if main != null else null
	if t != null and t.has_method("register_glow"):
		t.register_glow(Kit.mat("vitre_on"), 2.4, 0.05)


# =================================================================== les lieux des géants

func _st(nom: String, x: float, z: float, face: Vector3, pose: String) -> void:
	stations[nom] = {"pos": _w(x, z), "face": face.normalized(), "pose": pose}


func _stations() -> void:
	var mo: Dictionary = reperes["moulin"]
	var md: Vector3 = mo["porte"]
	var ml: Vector2 = IleScript.L(md.x, md.z)
	_st("cour", 0.0, -56.0, Vector3(0, 0, -1), "debout")
	_st("porte", 0.0, -38.0, Vector3(0, 0, -1), "debout")
	_st("puits", -27.0, -63.0, Vector3(-1, 0, 0.4), "cueillir")
	_st("fauteuil", 26.0, -40.0, Vector3(-sin(FAUTEUIL_YAW), 0, -cos(FAUTEUIL_YAW)), "tricoter")
	_st("linge", -50.0, 34.0, Vector3(0.3, 0, 1), "etendre")
	_st("potager_porte", 54.0, -40.0, Vector3(1, 0, 0), "debout")
	_st("potager_entree", 64.5, -40.0, Vector3(1, 0, 0), "debout")
	_st("potager_ouest", 64.5, 0.0, Vector3(1, 0, 0), "debout")
	_st("potager_centre", 107.0, 0.0, Vector3(0, 0, 1), "debout")
	_st("potager_choux", 107.0, -26.0, Vector3(-1, 0, 0), "biner")
	_st("potager_tomates", 107.0, 26.0, Vector3(1, 0, 0), "cueillir")
	_st("potager_citrouilles", 85.0, 0.0, Vector3(0, 0, 1), "arroser")
	_st("grange", -98.0, -28.0, Vector3(0, 0, -1), "porter")
	_st("moulin_pied", -110.0, -95.0, Vector3(1, 0, 0), "debout")
	_st("moulin", ml.x + 2.0, ml.y + 3.0, Vector3(0.62, 0, 0.78), "regarder")
	_st("ouest", -56.0, -20.0, Vector3(0, 0, 1), "debout")
	_st("ouest_sud", -56.0, 40.0, Vector3(0, 0, 1), "debout")
	_st("derriere", 10.0, 45.0, Vector3(0, 0, 1), "debout")
	_st("verger_chemin", 48.0, 62.0, Vector3(1, 0, 1), "debout")
	_st("verger", 96.0, 106.0, Vector3(0.3, 0, 1), "cueillir")
	_st("ble", 4.0, 58.0, Vector3(0, 0, 1), "regarder")
	_st("mare", -84.0, 110.0, Vector3(-0.6, 0, 0.6), "accroupi")
	_st("pres", -40.0, 152.0, Vector3(0, 0, 1), "jouer")
	for i in range(CACHETTES.size()):
		var q: Vector2 = CACHETTES[i][0]
		_st("cache_%d" % i, q.x, q.y, Vector3(0, 0, 1), "cache")
	var e := [["cour", "porte"], ["cour", "puits"], ["cour", "fauteuil"], ["cour", "potager_porte"], ["cour", "grange"], ["cour", "moulin_pied"],
		["cour", "ouest"], ["potager_porte", "potager_entree"], ["potager_entree", "potager_ouest"], ["potager_ouest", "potager_citrouilles"],
		["potager_citrouilles", "potager_centre"], ["potager_centre", "potager_choux"], ["potager_centre", "potager_tomates"],
		["moulin_pied", "moulin"], ["ouest", "ouest_sud"], ["ouest_sud", "linge"], ["ouest_sud", "derriere"], ["derriere", "verger_chemin"],
		["verger_chemin", "verger"], ["derriere", "ble"], ["ouest_sud", "mare"], ["mare", "pres"],
		["ouest_sud", "cache_0"], ["ble", "cache_1"], ["moulin", "cache_2"], ["verger", "cache_3"], ["mare", "cache_4"]]
	graph.clear()
	for pair in e:
		for k in range(2):
			var a: String = pair[k]
			var c: String = pair[1 - k]
			if not graph.has(a):
				graph[a] = []
			(graph[a] as Array).append(c)


func spawn_geants() -> void:
	_spawn_geants()


func _spawn_geants() -> void:
	if not habitants.is_empty() or not ResourceLoader.exists(HABITANTS) or not ResourceLoader.exists(PNJ) or main == null:
		return
	var H = load(HABITANTS)
	var P = load(PNJ)
	for data in H.all_profiles():
		var npc: Node3D = P.new()
		main.add_child(npc)
		var start: String = str(data.get("maison", "cour"))
		npc.setup(main, data, {"ici": stations.get(start, stations["cour"])["pos"]}, {"ici": []}, "ici")
		npc.setup_geant(self, data, stations, graph)
		var saved: Variant = main.get("pending_pnj_v31").get(str(data["id"]), {}) if main.get("pending_pnj_v31") != null else {}
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			npc.load_data(saved)
		npc.place_now()
		if main.get("npcs_v31") != null:
			main.npcs_v31.append(npc)
		habitants.append(npc)
		by_id[str(data["id"])] = npc
	_nenuphars_cols()
	print("ILE_MANGA_V142: %d géants à la ferme des Grandpré" % habitants.size())


# =================================================================== les pas des géants

## Un pied de géant qui se pose : le son sourd, la poussière, le sol qui tremble près de lui
func pas_geant(at: Vector3, who: Node3D) -> void:
	pas_total += 1
	if main == null:
		return
	var p: Vector3 = main._player_pos_v27()
	var d: float = p.distance_to(at)
	if d > 140.0:
		return
	if main.has_method("sfx"):
		var petite: float = -6.0 if str(who.get("display_name")) == "Pâquerette" else 0.0
		if d < 40.0:
			main.sfx("pas_geant", at, petite)
		else:
			# de loin, un grondement sourd (on l'entend de partout)
			main.sfx("pas_geant", null, petite - 10.0 - (d - 40.0) * 0.14)
	var fx: Node = main.get("combat_fx_v129")
	if fx != null:
		if d < 70.0 and fx.has_method("_puffs"):
			fx._puffs(at + Vector3.UP * 0.4, 7, Color(0.62, 0.56, 0.44, 0.45), 1.2, 3.4, 1.4, 1.0, 2.6, 0.15, 1.2)
		var k: float = 1.0 - d / 32.0
		if k > 0.0:
			if fx.has_method("shake"):
				fx.shake(0.22 * k)
			if fx.has_method("haptic"):
				fx.haptic(0.2 * k, 0.07)


# =================================================================== les repères des autres

func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z) and p.y > -45.0


## À pied : la terre ferme ; sur l'eau de la mare, seulement sur un nénuphar (ou en l'air, d'un saut)
func walkable(p: Vector3) -> bool:
	if not contains(p):
		return false
	if IleScript.in_mare_water(p.x, p.z):
		if p.y > IleScript.MARE_Y + 0.35:
			return true
		if flore != null:
			for q in flore.nenuphars:
				if Vector2(p.x - (q as Vector3).x, p.z - (q as Vector3).z).length() < 1.4:
					return true
		return false
	return ile.height(p.x, p.z) > -1.3 or p.y > 1.0


func owns_point(p: Vector3) -> bool:
	return contains(p)


func hostile_zone(_p: Vector3) -> bool:
	return false


func zone_at(p: Vector3) -> String:
	if ile == null or not ile.contains(p.x, p.z) or p.y < -20.0:
		return ""
	var l: Vector2 = IleScript.L(p.x, p.z)
	var h: float = ile.height(p.x, p.z)
	if l.distance_to(IleScript.DOCK_A.lerp(IleScript.DOCK_B, 0.5)) < 26.0:
		return "gt_ponton"
	if h < -0.42 and p.y < 2.0:
		return "" if ile.coast_q(l.x, l.y) > 1.12 else "gt_rivage"
	if IleScript.in_maison(l.x, l.y, 3.0):
		return "gt_maison"
	if IleScript.in_grange(l.x, l.y, 3.0):
		return "gt_grange"
	if IleScript.in_rect(IleScript.POTAGER, l.x, l.y, 2.0):
		return "gt_potager"
	if IleScript.in_rect(IleScript.COUR, l.x, l.y, 4.0) or l.distance_to(IleScript.PUITS) < 12.0:
		return "gt_cour"
	if l.distance_to(IleScript.MOULIN) < IleScript.MOULIN_R1 * 0.55:
		return "gt_moulin"
	if IleScript.mare_q(l.x, l.y) < 1.6:
		return "gt_mare"
	if IleScript.in_rect(IleScript.BLE, l.x, l.y, 3.0):
		return "gt_ble"
	if l.distance_to(IleScript.VERGER) < IleScript.VERGER_R + 6.0:
		return "gt_verger"
	if ile.coast_q(l.x, l.y) > 0.9:
		return "gt_greve" if l.y < -150.0 else "gt_rivage"
	return "gt_pres"


func place_name(p: Vector3) -> String:
	return "Île des Géants, " + str(PLACES.get(zone_at(p), "l'île"))


func village_point(id: String) -> Array:
	if id == "geants":
		var a: Vector3 = dock()[0]
		var q: Vector3 = IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y + 10.0, 0.0)
		q.y = ile.height(q.x, q.z) + 0.3 if ile != null else a.y
		return [q, Vector3(0, 0, 1)]
	return []


func respawn_point() -> Array:
	var q: Vector3 = _w(-6.0, -46.0, 0.3)
	return [q, Vector3(0, 0, -1)]


func on_faint(_p: Vector3) -> void:
	var at: Array = respawn_point()
	main.place_player_v35(at[0], at[1])
	main._show_message_v28("Vous vous êtes évanoui… Mère Mathurine vous a ramassé au creux de sa main et vous a posé sur le seuil de la porte, avec un dé à coudre rempli de soupe chaude. On se sent tout de suite mieux.")


func hour() -> float:
	return float(main.temps_v56.hour) if main != null and main.get("temps_v56") != null and main.temps_v56 != null else 12.0


func _now() -> float:
	return float(main.game_menu.seconds) if main != null and main.get("game_menu") != null and main.game_menu != null else 0.0


# =================================================================== services (le carnet)

func register_services(journal: Node) -> void:
	journal.lieux["geants"] = respawn_point()[0]
	journal.lieux["gt_bague"] = _w(86.0, -22.0, 0.25)
	journal.lieux["gt_potager"] = _w(107.0, -30.0)
	journal.lieux["gt_ferme"] = _w(0.0, -56.0)
	journal.lieux["gt_ble"] = _w(8.0, 90.0)
	lieux = {"gt_bague": journal.lieux["gt_bague"]}


func _journal() -> Node:
	return main.get("journal_v56") if main != null else null


func _quete(qid: String) -> String:
	var j: Node = _journal()
	return str(j.state(qid)) if j != null else ""


func _etape(qid: String) -> int:
	var j: Node = _journal()
	return int(j.step_of(qid)) if j != null else -1


# =================================================================== la vie de l'île

func _process(delta: float) -> void:
	if main == null or ile == null:
		return
	_clock += delta
	if ailes != null and is_instance_valid(ailes):
		ailes.rotate_object_local(Vector3.BACK, delta * 0.22)
	var p: Vector3 = main._player_pos_v27()
	if not ile.contains(p.x, p.z):
		return
	if not bool(state["visite"]) and ile.height(p.x, p.z) > -0.3 and bool(main.get("game_started")):
		state["visite"] = true
		main._show_message_v28("L'Île des Géants — ici, tout est sept fois plus grand que toi. Regarde bien où tu marches… et surtout où ils marchent !")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	var z: String = zone_at(p)
	if z != "" and not bool((state["visites"] as Dictionary).get(z, false)):
		state["visites"][z] = true
		if z == "gt_cour":
			main._show_message_v28("La ferme des Grandpré : une porte haute comme un phare, des bottes grandes comme des barques")
		elif z == "gt_moulin":
			state["moulin"] = true
			main._show_message_v28("Le Moulin de la Butte : ses ailes balaient le ciel")
	if not _built:
		return
	# la surface vue d'en dessous suit le plongeur
	var mer: Node = main.get("mer_v55")
	if mer != null and mer.get("_underside") != null:
		(mer._underside as Node3D).global_position = Vector3(snappedf(p.x, 40.0), (mer._underside as Node3D).global_position.y, snappedf(p.z, 40.0))
	if not _pommes_ok:
		_pommes_ok = true
		_pommes()
	_lim_t -= delta
	if _lim_t <= 0.0:
		_lim_t = 1.0
		_limaces_tick(p)
	_cache_tick(delta, p)
	# la nuit, la maison ronfle
	_ronfle_t -= delta
	if _ronfle_t <= 0.0:
		_ronfle_t = 5.5
		var h: float = hour()
		var mh: Vector3 = reperes["maison"]["porte"]
		if (h >= 21.5 or h < 5.5) and p.distance_to(mh) < 90.0 and main.has_method("sfx"):
			main.sfx("ronflement_geant", mh + Vector3.UP * 12.0, -4.0)


## Les pommes tombées du verger : on peut les ramasser (une fois)
func _pommes() -> void:
	var inv: Node = main.get("inventory_v28")
	if inv == null or flore == null or not inv.ITEMS.has("pomme_geante"):
		return
	var i: int = 0
	for gp in flore.pommes_sol:
		var uid: String = "gt_pomme_%d" % i
		i += 1
		if inv.taken.has(uid):
			continue
		inv.spawn_pickup(uid, "pomme_geante", 1, gp)


# =================================================================== les limaces du potager

func _limaces_tick(p: Vector3) -> void:
	limaces = limaces.filter(func(l): return is_instance_valid(l))
	var actif: bool = _quete("gt_limaces") == "en_cours" and _etape("gt_limaces") == 0 and int(state["limaces"]) < LIMACES_BUT
	var near: bool = p.distance_to(_w(107.0, 0.0)) < 160.0
	if not actif or not near:
		if not actif:
			for l in limaces:
				l.queue_free()
			limaces.clear()
		return
	var want: int = mini(LIMACES_N, LIMACES_BUT - int(state["limaces"]))
	var alive: int = limaces.filter(func(l): return str(l.etat) in ["rampe", "mange"]).size()
	if alive < want:
		_spawn_limace()


func _spawn_limace() -> void:
	var r: Array = IleScript.PLANCHES["choux"] if _rng.randf() < 0.6 else IleScript.PLANCHES["poireaux"]
	var x: float = float(r[0]) + IleScript.SILLON * (0.5 + float(_rng.randi_range(0, 8)))
	var z: float = _rng.randf_range(float(r[1]) + 3.0, float(r[3]) - 3.0)
	var start: Vector3 = _w(x + _rng.randf_range(-1.5, 1.5), z + _rng.randf_range(-6.0, 6.0))
	var chou: Vector3 = _w(x, z)
	var exit: Vector3 = _w(IleScript.POTAGER[2] + 4.0, z) if x > 107.0 else _w(IleScript.POTAGER[0] - 4.0, z)
	var l: Node3D = Limace.new()
	add_child(l)
	l.setup(main, ile, start, chou, exit, _rng.randi())
	l.chassee.connect(_on_limace)
	limaces.append(l)


func _on_limace(_l: Node3D) -> void:
	if _quete("gt_limaces") == "en_cours" and _etape("gt_limaces") == 0:
		state["limaces"] = int(state["limaces"]) + 1
		var n: int = int(state["limaces"])
		if n >= LIMACES_BUT:
			main._show_message_v28("Plus une seule limace dans le potager ! Oncle Théophile va être content.")
		else:
			main._show_message_v28("Splotch ! La limace file se cacher sous la clôture (%d / %d)" % [n, LIMACES_BUT])


# =================================================================== le cache-cache avec Pâquerette

func _paquerette() -> Node3D:
	return by_id.get("paquerette_gt")


func cache_actif() -> bool:
	return _quete("gt_cache") == "en_cours" and _etape("gt_cache") == 0 and int(state["cache"]) < 3


func _cache_tick(delta: float, p: Vector3) -> void:
	var pq: Node3D = _paquerette()
	if pq == null:
		return
	if not cache_actif():
		if cache_rond >= 0:
			cache_rond = -1
			_cache_phase = ""
			pq.impose = ""
			pq.impose_pose = ""
		return
	if bool(pq.hidden_home):
		return
	_cache_t -= delta
	match _cache_phase:
		"":
			# une nouvelle partie : elle compte (c'est elle qui se cache), puis court se cacher
			cache_rond = (int(state["cache"]) * 2 + 1) % CACHETTES.size()
			_cache_phase = "court"
			pq.impose = "cache_%d" % cache_rond
			pq.impose_pose = "cache"
			pq.say_bubble(Brain_t("Ferme les yeux et compte jusqu'à dix ! Un… deux… Je me cache !"), 5.0)
			main._show_message_v28("Pâquerette court se cacher ! Compte jusqu'à dix… puis cherche-la.")
			_cache_t = 12.0
			pq._go(pq.impose)
		"court":
			if str(pq.etat) == "repos" and str(pq.lieu) == pq.impose:
				_cache_phase = "cachee"
				_rire_t = 3.0
			elif _cache_t < -40.0:
				pq._jump(pq.impose)
		"cachee":
			_rire_t -= delta
			if _rire_t <= 0.0:
				_rire_t = 9.0
				if p.distance_to(pq.global_position) < 70.0:
					pq.say_bubble(Brain_t(str(CACHETTES[cache_rond][1])), 4.0)
					if main.has_method("sfx"):
						main.sfx("gloussement", pq.global_position + Vector3.UP * 5.0, -3.0)
			if Vector2(p.x - pq.global_position.x, p.z - pq.global_position.z).length() < 11.0:
				state["cache"] = int(state["cache"]) + 1
				var n: int = int(state["cache"])
				_cache_phase = "trouvee"
				_cache_t = 7.0
				pq.impose_pose = "jouer"
				if main.has_method("sfx"):
					main.sfx("gloussement", pq.global_position + Vector3.UP * 5.0, 0.0)
				if n >= 3:
					pq.say_bubble(Brain_t("Trouvée ! Encore ! Tu es le plus fort des tout-petits du monde ! Viens, j'ai un cadeau pour toi !"), 6.0)
					main._show_message_v28("Trouvée trois fois ! Va voir Pâquerette : elle a quelque chose pour toi.")
				else:
					pq.say_bubble(Brain_t("Trouvée ! Hi hi hi ! Encore une fois ! Je me cache mieux, cette fois !"), 5.0)
					main._show_message_v28("Trouvée ! (%d / 3)" % n)
		"trouvee":
			if _cache_t <= 0.0:
				_cache_phase = ""
				if int(state["cache"]) >= 3:
					pq.impose = ""
					pq.impose_pose = ""
					cache_rond = -1


static func Brain_t(s: String) -> String:
	return load("res://scripts/langue_v104.gd").t(s)


# =================================================================== carnet, sauvegarde

func trouvailles() -> Dictionary:
	return {"geants": 1 if bool(state["visite"]) else 0,
		"gt_ferme": 1 if bool((state["visites"] as Dictionary).get("gt_cour", false)) else 0,
		"gt_moulin": 1 if bool(state.get("moulin", false)) else 0,
		"gt_limaces": 1 if int(state["limaces"]) >= LIMACES_BUT else 0,
		"gt_cache": 1 if int(state["cache"]) >= 3 else 0}


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	state = _fresh_state()
	for k in state:
		if d.has(k):
			state[k] = d[k] if not (d[k] is Dictionary) else (d[k] as Dictionary).duplicate(true)
	cache_rond = -1
	_cache_phase = ""
	_pommes_ok = false
	for l in limaces:
		if is_instance_valid(l):
			l.queue_free()
	limaces.clear()
	for g in habitants:
		if is_instance_valid(g):
			g.impose = ""
			g.impose_pose = ""
			g.place_now()
