extends "res://scripts/pnj/pnj_v31.gd"
## V142 : un géant de l'Île des Géants (la famille Grandpré). Un vrai corps d'habitant (V64, voir
## tools/generate_geants_v142.gd), agrandi : 12 à 14 m (Pâquerette, sept ans : 9 m). Il vit selon
## l'heure entre les lieux de la ferme (le potager, la cour, le moulin, le verger, le fauteuil de
## Grand-mère…) et y travaille (biner, arroser, cueillir, tricoter, étendre le linge, porter les sacs,
## jouer) ; il marche à grandes enjambées (à chaque pas, le sol tremble près de lui, la poussière vole) ;
## il fait attention où il met les pieds (il s'arrête si le tout petit visiteur est devant lui). Quand
## on s'approche, il le remarque, se tourne, et s'agenouille pour parler (on parle de plus loin qu'aux
## gens de notre taille). La nuit, il rentre à la maison (on l'entend ronfler).

const G_ANIM: float = 0.5                 # ses gestes : deux fois plus lents que les nôtres
const POSES_TRAVAIL := ["biner", "arroser", "cueillir", "tricoter", "etendre", "porter", "jouer", "regarder"]

var geants: Node                          # l'île (geants_v142)
var taille: float = 13.0                  # sa taille (m)
var k: float = 7.5                        # l'agrandissement de son corps
var stations: Dictionary = {}             # lieu -> {"pos": Vector3, "face": Vector3, "pose": String}
var graph: Dictionary = {}                # lieu -> [lieux voisins] (les chemins de la ferme)
var agenda: Array = []                    # [[h0, h1, lieu], …]
var lieu: String = ""                     # le lieu où il est (ou vers lequel il va)
var pose: String = "debout"
var talk_reach: float = 11.0
var hidden_home: bool = false
var etat: String = "repos"                # repos, marche, parle, attend
var impose: String = ""                   # un lieu imposé (le cache-cache, les tests) ; « » : l'agenda
var impose_pose: String = ""
var pas_count: int = 0                    # les pas faits (les tests)
var vitesse: float = 3.6                  # m/s en marchant
var _route: Array = []                    # les lieux à suivre
var _bend: float = 0.0                    # agenouillé (0 debout, 1 à genoux)
var _bend_goal: float = 0.0
var _feet: Array = []                     # [[os, levé ?]]
var _check_t: float = 0.0
var _gest_t: float = 4.0
var _wait_t: float = 0.0
var _said_wait: float = 0.0
var _anim_now: String = ""


## Les réglages du géant (après setup) : sa taille, ses lieux, son agenda ; son corps agrandi.
func setup_geant(island: Node, data: Dictionary, lieux: Dictionary, chemins: Dictionary) -> void:
	geants = island
	var g: Dictionary = data.get("geant", {})
	taille = float(g.get("taille", 13.0))
	agenda = g.get("agenda", [])
	vitesse = float(g.get("vitesse", 3.6))
	stations = lieux
	graph = chemins
	var h0: float = super.body_height()
	k = taille / maxf(h0, 0.5)
	model.scale *= k
	sleep_far = 520.0
	talk_reach = clampf(taille * 0.85, 7.0, 12.0)
	hit_height = 1.2
	hit_radius = taille * 0.09
	# le corps de collision : les jambes (on se cogne aux mollets d'un géant)
	var cs: CollisionShape3D = _body.get_child(0) as CollisionShape3D
	if cs != null:
		var cap := CapsuleShape3D.new()
		cap.radius = taille * 0.085
		cap.height = taille * 0.5
		cs.shape = cap
		cs.position.y = taille * 0.25
	bubble.position = Vector3(0, taille + 1.2, 0)
	bubble.pixel_size = 0.0028 * 2.6
	bubble.width = 560
	vr_label.position = Vector3(0, taille * 0.55, 0)
	vr_label.pixel_size = 0.0024 * 2.2
	_build_geant_poses()
	if skel != null:
		for nm in ["LeftFoot", "RightFoot"]:
			var bi: int = skel.find_bone(nm)
			if bi >= 0:
				_feet.append([bi, false])
	lieu = str(data.get("maison", "cour"))


## Pas de perroquet (ni d'autre accessoire) : la tenue vient du corps.
func _accessories() -> void:
	pass


func body_height() -> float:
	return super.body_height() * (model.scale.y / maxf(float(v64.get("scale", 1.0)), 0.01) if not v64.is_empty() else model.scale.y)


## La hauteur des yeux : plus bas quand il est agenouillé, assis ou accroupi.
func face_height() -> float:
	var h: float = super.face_height()
	if not v64.is_empty():
		h *= model.scale.y / maxf(float(v64.get("scale", 1.0)), 0.01)
	var f: float = 1.0
	match _anim_now:
		"g142/genou", "g142/genou_parle":
			f = 0.66
		"g142/accroupi", "g142/cache":
			f = 0.52
		"g142/tricoter", "g142/assise_parle":
			f = 0.7
		"g142/cueillir":
			f = 0.62
	return h * f


## De près, les petites pièces du visage restent dessinées plus loin (un géant a de grands yeux).
func body64_build() -> void:
	super.body64_build()
	for key in ["cils", "dents", "langue", "yeux"]:
		var mi: MeshInstance3D = v64.get(key)
		if mi != null:
			mi.visibility_range_end = (14.0 if key != "yeux" else 45.0) * k


# =================================================================== les gestes des géants

func _build_geant_poses() -> void:
	if anim == null or skel == null or anim.has_animation_library("g142"):
		return
	var lib = HeroLib.new()
	lib.hero = model
	lib.anim = anim
	lib.skel = skel
	var poses := AnimationLibrary.new()
	var o := Vector3.ZERO
	var base := {"LeftArm": Vector3(0, 0, -12), "RightArm": Vector3(0, 0, 12), "LeftForeArm": Vector3(-12, 0, 0), "RightForeArm": Vector3(-12, 0, 0)}
	# à genoux (genou droit à terre), penché vers le petit visiteur, la main gauche sur le genou
	var genou := {"LeftUpLeg": Vector3(-88, 0, 10), "LeftLeg": Vector3(92, 0, 0), "LeftFoot": Vector3(-6, 0, 0),
		"RightUpLeg": Vector3(-8, 0, -8), "RightLeg": Vector3(98, 0, 0), "RightFoot": Vector3(40, 0, 0),
		"Spine": Vector3(8, 0, 0), "Spine01": Vector3(10, 0, 0), "Spine02": Vector3(10, 0, 0), "Neck": Vector3(8, 0, 0), "Head": Vector3(18, 0, 0),
		"LeftArm": Vector3(-38, 0, -20), "LeftForeArm": Vector3(-62, 0, 0), "RightArm": Vector3(-14, 0, 16), "RightForeArm": Vector3(-30, 0, 0)}
	var genou_b := lib._merge(genou, {"Spine02": Vector3(12, 0, 0), "Head": Vector3(22, 6, 0)})
	var down := Vector3(0, -44, 6)
	poses.add_animation("genou", lib._clip(5.0, true, [[0.0, genou, down], [2.5, genou_b, down + Vector3(0, -0.6, 0)], [5.0, genou, down]]))
	var parle_a := lib._merge(genou, {"RightArm": Vector3(-52, 20, 30), "RightForeArm": Vector3(-58, 0, 0), "Head": Vector3(16, -6, 0)})
	var parle_b := lib._merge(genou, {"RightArm": Vector3(-60, 10, 24), "RightForeArm": Vector3(-82, 0, 0), "Head": Vector3(20, 6, 0)})
	poses.add_animation("genou_parle", lib._clip(2.4, true, [[0.0, parle_a, down], [1.2, parle_b, down + Vector3(0, -0.4, 0)], [2.4, parle_a, down]]))
	# accroupi (regarder le sol de près, se cacher)
	var accroupi := {"LeftUpLeg": Vector3(-112, 0, 14), "RightUpLeg": Vector3(-112, 0, -14), "LeftLeg": Vector3(136, 0, 0), "RightLeg": Vector3(136, 0, 0),
		"LeftFoot": Vector3(-26, 0, 0), "RightFoot": Vector3(-26, 0, 0), "Spine01": Vector3(16, 0, 0), "Spine02": Vector3(18, 0, 0), "Head": Vector3(12, 0, 0),
		"LeftArm": Vector3(-48, 0, -16), "RightArm": Vector3(-48, 0, 16), "LeftForeArm": Vector3(-70, 0, 0), "RightForeArm": Vector3(-70, 0, 0)}
	var acc_b := lib._merge(accroupi, {"Head": Vector3(14, 14, 0)})
	poses.add_animation("accroupi", lib._clip(4.0, true, [[0.0, accroupi, Vector3(0, -62, 10)], [2.0, acc_b, Vector3(0, -62.5, 10)], [4.0, accroupi, Vector3(0, -62, 10)]]))
	# se cacher : accroupi, les mains sur la bouche (elle pouffe de rire)
	var cache := lib._merge(accroupi, {"LeftArm": Vector3(-70, 0, -40), "RightArm": Vector3(-70, 0, 40), "LeftForeArm": Vector3(-130, 0, 0), "RightForeArm": Vector3(-130, 0, 0), "Head": Vector3(6, 0, 0)})
	var cache_b := lib._merge(cache, {"Head": Vector3(2, 10, 0), "Spine02": Vector3(14, 4, 0)})
	poses.add_animation("cache", lib._clip(1.2, true, [[0.0, cache, Vector3(0, -62, 10)], [0.6, cache_b, Vector3(0, -60.5, 10)], [1.2, cache, Vector3(0, -62, 10)]]))
	# biner : les bras tendus, la binette monte et redescend, le dos courbé
	var bi_a := {"Spine02": Vector3(24, 0, 0), "Spine01": Vector3(8, 0, 0), "Head": Vector3(10, 0, 0), "LeftArm": Vector3(-78, 0, -12), "RightArm": Vector3(-70, 0, 14),
		"LeftForeArm": Vector3(-22, 0, 0), "RightForeArm": Vector3(-40, 0, 0), "LeftUpLeg": Vector3(-14, 0, 4), "LeftLeg": Vector3(20, 0, 0), "RightUpLeg": Vector3(10, 0, -4)}
	var bi_b := lib._merge(bi_a, {"Spine02": Vector3(34, 0, 0), "LeftArm": Vector3(-38, 0, -10), "RightArm": Vector3(-32, 0, 12), "LeftForeArm": Vector3(-10, 0, 0), "RightForeArm": Vector3(-18, 0, 0)})
	poses.add_animation("biner", lib._clip(2.2, true, [[0.0, bi_a, Vector3(0, -3, 0)], [0.9, bi_b, Vector3(0, -5, 2)], [1.3, bi_b, Vector3(0, -5, 2)], [2.2, bi_a, Vector3(0, -3, 0)]]))
	# arroser : le bras droit tendu (l'arrosoir), qui penche doucement
	var ar_a := lib._merge(base, {"RightArm": Vector3(-46, 0, 24), "RightForeArm": Vector3(-34, 0, 0), "Spine02": Vector3(10, 0, 0), "Head": Vector3(14, 0, 0), "LeftArm": Vector3(-10, 0, -20)})
	var ar_b := lib._merge(ar_a, {"RightArm": Vector3(-36, 8, 30), "Spine02": Vector3(14, 6, 0), "Head": Vector3(18, 8, 0)})
	poses.add_animation("arroser", lib._clip(4.0, true, [[0.0, ar_a, o], [2.0, ar_b, Vector3(0, -1, 0)], [4.0, ar_a, o]]))
	# cueillir : penché en avant, les mains vers le bas, qui ramassent
	var cu_a := {"Spine": Vector3(14, 0, 0), "Spine01": Vector3(20, 0, 0), "Spine02": Vector3(22, 0, 0), "Head": Vector3(-4, 0, 0),
		"LeftUpLeg": Vector3(-30, 0, 6), "RightUpLeg": Vector3(-30, 0, -6), "LeftLeg": Vector3(36, 0, 0), "RightLeg": Vector3(36, 0, 0),
		"LeftArm": Vector3(-62, 0, -6), "RightArm": Vector3(-70, 0, 6), "LeftForeArm": Vector3(-14, 0, 0), "RightForeArm": Vector3(-18, 0, 0)}
	var cu_b := lib._merge(cu_a, {"RightArm": Vector3(-48, 10, 14), "RightForeArm": Vector3(-70, 0, 0), "Head": Vector3(-8, 10, 0)})
	poses.add_animation("cueillir", lib._clip(3.0, true, [[0.0, cu_a, Vector3(0, -14, 4)], [1.2, cu_b, Vector3(0, -15, 4)], [1.8, cu_b, Vector3(0, -15, 4)], [3.0, cu_a, Vector3(0, -14, 4)]]))
	# tricoter (assise dans son fauteuil) : les avant-bras devant, les aiguilles qui vont et viennent
	var assise := {"LeftUpLeg": Vector3(-88, 0, 6), "RightUpLeg": Vector3(-88, 0, -6), "LeftLeg": Vector3(85, 0, 0), "RightLeg": Vector3(85, 0, 0),
		"LeftFoot": Vector3(-5, 0, 0), "RightFoot": Vector3(-5, 0, 0), "Spine02": Vector3(-4, 0, 0)}
	var tr_a := lib._merge(assise, {"LeftArm": Vector3(-34, 0, -26), "RightArm": Vector3(-34, 0, 26), "LeftForeArm": Vector3(-96, 0, 0), "RightForeArm": Vector3(-88, 0, 0), "Head": Vector3(18, 0, 0)})
	var tr_b := lib._merge(tr_a, {"LeftForeArm": Vector3(-88, 0, 0), "RightForeArm": Vector3(-98, 0, 0)})
	poses.add_animation("tricoter", lib._clip(1.0, true, [[0.0, tr_a, Vector3(0, -38, 0)], [0.5, tr_b, Vector3(0, -38, 0)], [1.0, tr_a, Vector3(0, -38, 0)]]))
	var ap_a := lib._merge(assise, {"LeftArm": Vector3(-30, 0, -24), "LeftForeArm": Vector3(-90, 0, 0), "RightArm": Vector3(-44, 20, 26), "RightForeArm": Vector3(-60, 0, 0), "Head": Vector3(14, -6, 0)})
	var ap_b := lib._merge(ap_a, {"RightArm": Vector3(-52, 8, 20), "RightForeArm": Vector3(-84, 0, 0), "Head": Vector3(18, 6, 0)})
	poses.add_animation("assise_parle", lib._clip(2.4, true, [[0.0, ap_a, Vector3(0, -38, 0)], [1.2, ap_b, Vector3(0, -38, 0)], [2.4, ap_a, Vector3(0, -38, 0)]]))
	# étendre le linge : les bras en l'air, qui épinglent
	var et_a := lib._merge(base, {"LeftArm": Vector3(-150, 0, 14), "RightArm": Vector3(-140, 0, -18), "LeftForeArm": Vector3(-20, 0, 0), "RightForeArm": Vector3(-34, 0, 0), "Head": Vector3(-16, 0, 0), "Spine02": Vector3(-6, 0, 0)})
	var et_b := lib._merge(et_a, {"LeftArm": Vector3(-136, 0, 22), "RightArm": Vector3(-152, 0, -10), "Head": Vector3(-14, 8, 0)})
	poses.add_animation("etendre", lib._clip(3.0, true, [[0.0, et_a, Vector3(0, 1, 0)], [1.5, et_b, Vector3(0, 1.5, 0)], [3.0, et_a, Vector3(0, 1, 0)]]))
	# porter un sac sur l'épaule
	var po_a := lib._merge(base, {"RightArm": Vector3(-150, 0, -30), "RightForeArm": Vector3(-120, 0, 0), "Head": Vector3(4, -14, 0), "Spine02": Vector3(4, 0, 8)})
	poses.add_animation("porter", lib._clip(4.0, true, [[0.0, po_a, o], [2.0, lib._merge(po_a, {"Spine02": Vector3(6, 0, 10)}), Vector3(0, -0.8, 0)], [4.0, po_a, o]]))
	# jouer (Pâquerette) : sauter à cloche-pied, les bras qui battent
	var ju_a := lib._merge(base, {"LeftUpLeg": Vector3(-40, 0, 0), "LeftLeg": Vector3(70, 0, 0), "LeftArm": Vector3(-30, 0, -50), "RightArm": Vector3(-30, 0, 50)})
	var ju_b := lib._merge(ju_a, {"RightUpLeg": Vector3(-12, 0, 0), "RightLeg": Vector3(22, 0, 0), "LeftArm": Vector3(-60, 0, -70), "RightArm": Vector3(-60, 0, 70)})
	poses.add_animation("jouer", lib._clip(0.9, true, [[0.0, ju_a, Vector3(0, 0, 0)], [0.3, ju_b, Vector3(0, 12, 0)], [0.6, ju_a, Vector3(0, 2, 0)], [0.9, ju_a, Vector3(0, 0, 0)]]))
	# regarder au loin, la main en visière
	var vi := lib._merge(base, {"RightArm": Vector3(-130, 0, -20), "RightForeArm": Vector3(-115, 0, 0), "Head": Vector3(-8, 0, 0)})
	var vi_b := lib._merge(vi, {"Head": Vector3(-8, 28, 0), "Spine02": Vector3(-4, 8, 0)})
	var vi_c := lib._merge(vi, {"Head": Vector3(-8, -26, 0), "Spine02": Vector3(-4, -8, 0)})
	poses.add_animation("regarder", lib._clip(7.0, true, [[0.0, vi, o], [2.0, vi_b, o], [4.5, vi_c, o], [7.0, vi, o]]))
	# les mains sur les hanches (quand il attend que le petit s'écarte)
	var hanches := lib._merge(base, {"LeftArm": Vector3(-10, 0, -40), "RightArm": Vector3(-10, 0, 40), "LeftForeArm": Vector3(-100, 30, 0), "RightForeArm": Vector3(-100, -30, 0), "Head": Vector3(16, 0, 0)})
	poses.add_animation("hanches", lib._clip(3.0, true, [[0.0, hanches, o], [1.5, lib._merge(hanches, {"Head": Vector3(18, 10, 0)}), o], [3.0, hanches, o]]))
	anim.add_animation_library("g142", poses)
	lib.free()


func _anim(name_anim: String, blend: float = 0.6, speed: float = 1.0) -> void:
	_anim_now = name_anim
	_play(name_anim, blend, speed * G_ANIM)


# =================================================================== la vie

func _process(delta: float) -> void:
	if main == null or geants == null:
		return
	var p: Vector3 = main._player_pos_v27()
	var to_p: Vector3 = p - global_position
	var dist: float = Vector2(to_p.x, to_p.z).length()
	brain.tick(delta)
	if bubble_clock > 0.0:
		bubble_clock -= delta
		bubble.modulate.a = clampf(bubble_clock, 0.0, 1.0)
		if bubble_clock <= 0.0:
			bubble.visible = false
	called_clock = maxf(called_clock - delta, 0.0)
	gesture_clock = maxf(gesture_clock - delta, 0.0)
	if vr_label != null:
		vr_label.visible = main.xr_active and etat != "parle" and dist < talk_reach and not hidden_home
	_check_t -= delta
	if _check_t <= 0.0:
		_check_t = 1.0
		_agenda_tick()
	if hidden_home:
		return
	# il remarque le tout petit visiteur
	var near: bool = dist < 22.0 and absf(to_p.y) < 12.0
	if near and not player_was_near and called_clock <= 0.0 and etat != "parle":
		var line: String = brain.call_out(main._npc_ctx_v31())
		if line != "":
			say_bubble(line, 5.0)
		called_clock = 90.0
	player_was_near = near
	match etat:
		"parle":
			_face(to_p, delta, 1.6)
			var assise: bool = pose == "tricoter"
			_anim("g142/assise_parle" if assise else "g142/genou_parle", 0.8)
		"marche":
			_walk_geant(delta, p, dist)
		"attend":
			_wait_t -= delta
			_face(to_p, delta, 1.2)
			if _anim_now != "g142/hanches":
				_anim("g142/hanches", 0.6)
			var ahead: bool = _petit_devant(p)
			if not ahead or _wait_t <= 0.0:
				etat = "marche"
		_:
			_repos(delta, to_p, dist)
	_feet_tick()


## À son lieu : il travaille ; si le petit visiteur s'approche, il se tourne et s'agenouille.
func _repos(delta: float, to_p: Vector3, dist: float) -> void:
	var sp: Dictionary = stations.get(lieu, {})
	var travail: String = impose_pose if impose_pose != "" else str(sp.get("pose", "debout"))
	pose = travail
	var assise: bool = travail == "tricoter"
	if dist < talk_reach + 2.0 and not assise and travail != "cache":
		_face(to_p, delta, 1.2)
		if _anim_now != "g142/genou":
			_anim("g142/genou", 1.0)
		return
	if assise and dist < talk_reach + 4.0:
		_face(to_p, delta, 0.8)
	elif sp.has("face"):
		_face(sp["face"], delta, 1.0)
	if travail in ["biner", "arroser", "cueillir", "tricoter", "etendre", "porter", "jouer", "regarder", "accroupi", "cache"]:
		if _anim_now != "g142/" + travail:
			_anim("g142/" + travail, 0.9)
		return
	# debout : il respire, de temps en temps il regarde au loin
	_gest_t -= delta
	if _gest_t <= 0.0:
		_gest_t = randf_range(12.0, 22.0)
		_anim("g142/regarder", 0.8)
	elif _anim_now != "v28/idle" and _anim_now != "g142/regarder":
		_anim("v28/idle", 0.8)
	elif _anim_now == "g142/regarder" and _gest_t < 6.0:
		_anim("v28/idle", 0.8)


## Le lieu voulu (l'agenda, ou le lieu imposé) ; la nuit, à la maison.
func lieu_voulu() -> String:
	if impose != "":
		return impose
	var h: float = geants.hour() if geants != null and geants.has_method("hour") else 12.0
	for e in agenda:
		var h0: float = float(e[0])
		var h1: float = float(e[1])
		var inside: bool = (h >= h0 and h < h1) if h0 < h1 else (h >= h0 or h < h1)
		if inside:
			return str(e[2])
	return "cour"


func _agenda_tick() -> void:
	if etat == "parle":
		return
	var want: String = lieu_voulu()
	if want == "maison":
		if hidden_home:
			return
		if lieu == "porte" and etat == "repos":
			_set_hidden(true)
			return
		if lieu != "porte" or etat != "marche":
			if lieu != "porte":
				_go("porte")
		return
	if hidden_home:
		# le matin : il sort par la porte
		_set_hidden(false)
		_jump("porte")
	if want != lieu or (etat == "repos" and _route.is_empty() and global_position.distance_to(_station_pos(lieu)) > 4.0):
		_go(want)


func _set_hidden(h: bool) -> void:
	hidden_home = h
	model.visible = not h
	visible = true
	_body.collision_layer = 0 if h else 1
	if h:
		etat = "repos"
		_route.clear()


## Tout de suite à un lieu (au début d'une partie, au réveil)
func _jump(where: String) -> void:
	lieu = where
	_route.clear()
	etat = "repos"
	global_position = _station_pos(where)
	_ground()
	var sp: Dictionary = stations.get(where, {})
	if sp.has("face"):
		var f: Vector3 = sp["face"]
		rotation.y = atan2(f.x, f.z)


func place_now() -> void:
	var want: String = lieu_voulu()
	if want == "maison":
		_jump("porte")
		_set_hidden(true)
	else:
		_set_hidden(false)
		_jump(want)


func _station_pos(where: String) -> Vector3:
	var sp: Dictionary = stations.get(where, {})
	return sp.get("pos", global_position)


## Le chemin d'un lieu à l'autre (dans le graphe des chemins de la ferme)
func _go(where: String) -> void:
	if not stations.has(where):
		return
	var from: String = lieu if graph.has(lieu) else _nearest_node()
	var prev := {from: ""}
	var queue: Array = [from]
	while not queue.is_empty():
		var cur: String = queue.pop_front()
		if cur == where:
			break
		for nb in graph.get(cur, []):
			if not prev.has(nb):
				prev[nb] = cur
				queue.append(nb)
	var path: Array = []
	if prev.has(where):
		var c: String = where
		while c != from and c != "":
			path.push_front(c)
			c = prev[c]
	else:
		path = [where]
	_route = path
	lieu = where
	etat = "marche" if not _route.is_empty() else "repos"


func _nearest_node() -> String:
	var best: String = "cour"
	var bd: float = 1e9
	for n in stations:
		if not graph.has(n):
			continue
		var d: float = global_position.distance_to(stations[n]["pos"])
		if d < bd:
			bd = d
			best = str(n)
	return best


## Le tout petit visiteur est-il juste devant (sur le chemin des pieds) ?
func _petit_devant(p: Vector3) -> bool:
	var fwd: Vector3 = Vector3(sin(rotation.y), 0, cos(rotation.y))
	var off: Vector3 = p - global_position
	off.y = 0.0
	var along: float = off.dot(fwd)
	var lat: float = absf(off.dot(fwd.cross(Vector3.UP)))
	return along > -1.0 and along < taille * 0.55 and lat < taille * 0.16


func _walk_geant(delta: float, p: Vector3, dist: float) -> void:
	if _route.is_empty():
		etat = "repos"
		return
	if _petit_devant(p) and absf(p.y - global_position.y) < 6.0:
		etat = "attend"
		_wait_t = 6.0
		if _said_wait <= 0.0:
			_said_wait = 40.0
			var lines: Array = ["Oh là ! Pardon, petit ! J'ai failli te marcher dessus.", "Attention, je passe ! Pousse-toi un peu, tout petit.",
				"Ne bouge pas… je t'enjambe. Voilà !", "Houlà ! On ne se met pas devant les pieds d'un géant !"]
			say_bubble(Brain._t(lines[randi() % lines.size()]), 4.0)
		return
	_said_wait = maxf(_said_wait - delta, 0.0)
	var goal: Vector3 = _station_pos(str(_route[0]))
	var to_goal: Vector3 = goal - global_position
	to_goal.y = 0.0
	if to_goal.length() < 1.2:
		_route.pop_front()
		if _route.is_empty():
			etat = "repos"
			global_position = Vector3(goal.x, global_position.y, goal.z)
			_ground()
		return
	_face(to_goal, delta, 2.0)
	var fwd := Vector3(sin(rotation.y), 0, cos(rotation.y))
	var step: float = minf(vitesse * delta, to_goal.length())
	global_position += fwd * step * clampf(fwd.dot(to_goal.normalized()) * 1.4, 0.2, 1.0)
	_ground()
	if _anim_now != "Walking":
		_anim_now = "Walking"
		_play("Walking", 0.6, vitesse / k)


func _ground() -> void:
	var y: float = main._height_at(global_position.x, global_position.z) if main != null else global_position.y
	global_position.y = y
	_body.global_transform = Transform3D(Basis(Vector3.UP, rotation.y), global_position)


## Les pas : un pied qui se pose (après s'être levé), le sol tremble
func _feet_tick() -> void:
	if skel == null or _feet.is_empty() or not model.visible:
		return
	var walking: bool = etat == "marche"
	for f in _feet:
		var gp: Vector3 = (skel.global_transform * skel.get_bone_global_pose(int(f[0]))).origin
		var rel: float = gp.y - global_position.y
		if not bool(f[1]) and rel > taille * 0.07:
			f[1] = true
		elif bool(f[1]) and rel < taille * 0.052:
			f[1] = false
			if walking:
				pas_count += 1
				if geants != null and geants.has_method("pas_geant"):
					geants.pas_geant(Vector3(gp.x, global_position.y, gp.z), self)


func begin_talk() -> void:
	etat = "parle"
	state = "parle"
	bubble.visible = false
	bubble_clock = 0.0


func end_talk() -> void:
	etat = "repos" if _route.is_empty() else "marche"
	state = "repos"
	gesture_clock = 0.0


func can_talk() -> bool:
	return not hidden_home


## On ne fait pas mal à un géant : ça le chatouille (sa réplique « frappe »)
func take_hit(_damage: int, from_pos: Vector3) -> void:
	var line: String = brain.hit(main._npc_ctx_v31())
	say_bubble(line, 4.0)
	if state == "parle":
		main._close_dialogue_v31()


func is_hittable() -> bool:
	return not hidden_home and model.visible
