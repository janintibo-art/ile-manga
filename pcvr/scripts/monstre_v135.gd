extends "res://scripts/monstre_v133.gd"
## V135 : la faune sauvage de l'île de la jungle et de l'Île des Trois Soleils (région par région).
## (Les bêtes des V132 et V133 passent toujours par leurs fichiers : on ne fait ici que les nouvelles.)
## Trois caractères nouveaux :
##  - rôdeur (jaguar, la nuit) : il tourne autour du héros dans l'ombre, à bonne distance, puis
##    se ramasse… et bondit. On le garde en vue, on s'écarte quand il se tasse ;
##  - amphibie (crocodile du fleuve) : caché sous l'eau, on ne voit que ses yeux ; il jaillit
##    quand on longe la rive, ouvre la gueule et mord, puis retourne se cacher. Il ne s'éloigne
##    pas de l'eau ;
##  - chapardeur (coati) : il trottine vers le héros, lui chipe à manger et file, la queue en
##    l'air. Un coup : il lâche ce qu'il a pris (on ne peut pas lui faire de mal).
## Et des cousins des caractères d'avant : le singe hurleur (tireur : il lance des fruits), le
## mille-pattes géant (il fonce et pince), l'araignée géante (sauteur), le scarabée géant qui
## pousse sa boule (rouleur), le chacal et le coyote (meute), l'aigle royal (il tourne haut,
## puis pique serres en avant) ; et deux bêtes paisibles : les lucioles (de petites nuées qui
## clignotent la nuit) et l'axolotl géant des jardins flottants.

const SPECS135 := {
	"singe_hurleur": {"pv": 8, "vitesse": 3.6, "degats": 1, "portee": 9.0, "armer": 0.8, "repos": 2.2, "vue": 16.0, "laisse": 34.0,
		"rayon": 0.45, "haut": 0.55, "nom": "Singe hurleur", "genre": "tireur", "col": ["boite", Vector3(0.5, 0.75, 0.7)]},
	"mille_pattes": {"pv": 14, "vitesse": 4.0, "degats": 1, "portee": 1.5, "armer": 0.35, "repos": 1.0, "vue": 12.0, "laisse": 30.0,
		"rayon": 0.5, "haut": 0.2, "nom": "Mille-pattes géant", "genre": "pinceur", "col": ["boite", Vector3(0.45, 0.25, 1.6)]},
	"araignee_geante": {"pv": 16, "vitesse": 2.4, "degats": 2, "portee": 1.4, "armer": 0.6, "repos": 1.4, "vue": 11.0, "laisse": 26.0,
		"rayon": 0.6, "haut": 0.4, "nom": "Araignée géante", "genre": "sauteur", "saut": 6.5, "col": ["boite", Vector3(0.9, 0.5, 0.9)]},
	"luciole": {"pv": 1, "vitesse": 1.2, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 3.0, "laisse": 20.0,
		"rayon": 0.6, "haut": 0.0, "nom": "Lucioles", "genre": "essaim", "vol": true, "col": ["boule", 0.5, 0.0]},
	"crocodile": {"pv": 30, "vitesse": 2.6, "degats": 2, "portee": 2.0, "armer": 0.55, "repos": 1.6, "vue": 5.5, "laisse": 11.0,
		"rayon": 0.8, "haut": 0.35, "nom": "Crocodile du fleuve", "genre": "amphibie", "col": ["boite", Vector3(0.9, 0.45, 2.4)]},
	"scarabee_geant": {"pv": 18, "vitesse": 3.0, "degats": 1, "portee": 1.0, "armer": 0.5, "repos": 1.0, "vue": 13.0, "laisse": 30.0,
		"rayon": 0.55, "haut": 0.45, "nom": "Scarabée géant", "genre": "rouleur", "col": ["boule", 0.4, 0.4]},
	"chacal": {"pv": 9, "vitesse": 4.8, "degats": 1, "portee": 1.7, "armer": 0.42, "repos": 1.2, "vue": 20.0, "laisse": 50.0,
		"rayon": 0.5, "haut": 0.6, "nom": "Chacal", "genre": "meute", "col": ["boite", Vector3(0.6, 0.8, 1.3)]},
	"coati": {"pv": 99, "vitesse": 3.8, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 13.0, "laisse": 40.0,
		"rayon": 0.4, "haut": 0.3, "nom": "Coati chapardeur", "genre": "chapardeur", "col": ["boite", Vector3(0.4, 0.45, 0.9)]},
	"jaguar_sauvage": {"pv": 30, "vitesse": 4.4, "degats": 2, "portee": 1.6, "armer": 0.75, "repos": 1.6, "vue": 18.0, "laisse": 45.0,
		"rayon": 0.65, "haut": 0.6, "nom": "Jaguar", "genre": "rodeur", "saut": 8.5, "col": ["boite", Vector3(0.6, 0.85, 1.6)]},
	"aigle_royal": {"pv": 10, "vitesse": 7.0, "degats": 2, "portee": 1.0, "armer": 0.5, "repos": 1.5, "vue": 24.0, "laisse": 70.0,
		"rayon": 0.7, "haut": 0.0, "nom": "Aigle royal", "genre": "rapace", "vol": true, "col": ["boule", 0.45, 0.0]},
	"axolotl": {"pv": 4, "vitesse": 1.1, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 4.0, "laisse": 20.0,
		"rayon": 0.4, "haut": 0.2, "nom": "Axolotl géant", "genre": "fuyard", "col": ["boite", Vector3(0.35, 0.25, 0.8)]},
	"coyote": {"pv": 11, "vitesse": 4.6, "degats": 1, "portee": 1.7, "armer": 0.45, "repos": 1.2, "vue": 20.0, "laisse": 50.0,
		"rayon": 0.55, "haut": 0.65, "nom": "Coyote", "genre": "meute", "col": ["boite", Vector3(0.6, 0.85, 1.4)]},
}
const SOUNDS135 := {
	"singe_hurleur": ["singe_hurle", "singe_hurle"], "mille_pattes": ["mille_pattes_cliquette", "monstre_mort"],
	"araignee_geante": ["araignee_siffle", "araignee_siffle"], "luciole": ["", ""],
	"crocodile": ["crocodile_grogne", "crocodile_grogne"], "scarabee_geant": ["scarabee_crisse", "scarabee_crisse"],
	"chacal": ["chacal_glapit", "chacal_glapit"], "coati": ["coati_couine", "coati_couine"],
	"jaguar_sauvage": ["jaguar_feule", "jaguar_feule"], "aigle_royal": ["aigle_cri", "aigle_cri"],
	"axolotl": ["axolotl_bulle", "axolotl_bulle"], "coyote": ["coyote_hurle", "coyote_hurle"],
}
const ALERTES135 := {
	"singe_hurleur": "Des singes hurleurs ! Ils te bombardent de fruits de loin et filent quand tu approches : esquive les fruits, puis cours-leur après.",
	"mille_pattes": "Un mille-pattes géant ! Il fonce sur toi et pince : garde-le devant toi, et frappe-le quand il redresse la tête pour mordre.",
	"araignee_geante": "Une araignée géante ! Quand elle se tasse sur ses pattes, elle va bondir sur toi : écarte-toi, puis frappe-la quand elle retombe.",
	"crocodile": "Un crocodile ! Il guette sous l'eau, on ne voit que ses yeux : quand tu longes le fleuve, regarde l'eau. S'il ouvre la gueule, recule vite, puis frappe-le. Il ne s'éloigne pas de l'eau.",
	"scarabee_geant": "Un scarabée géant ! Il pousse sa boule droit sur toi : fais un pas de côté au dernier moment, puis frappe-le pendant qu'il la reprend.",
	"chacal": "Des chacals ! Ils chassent en meute, la nuit : garde-les devant toi, et pare quand l'un d'eux bondit.",
	"coati": "Un coati ! Ce petit chapardeur va te chiper à manger : s'il file avec, frappe-le pour qu'il le lâche.",
	"jaguar_sauvage": "Un jaguar ! Il tourne autour de toi dans l'ombre avant de bondir : garde-le en vue, et quand il se tasse, écarte-toi d'un coup. Puis frappe-le.",
	"aigle_royal": "Un aigle royal ! Il tourne haut dans le ciel, puis pique sur toi serres en avant : frappe-le au moment où il arrive.",
	"coyote": "Des coyotes ! Ils chassent en meute, la nuit : garde-les devant toi, et pare quand l'un d'eux bondit.",
}
const GENRES135 := ["rodeur", "amphibie", "chapardeur"]
const EAU: float = -0.42                 # le niveau de la mer et du fleuve

var _lucs: Array = []                    # lucioles : [nœud, matière, phase, rayon, hauteur, vitesse]
var _luc_light: OmniLight3D
var _fruit: MeshInstance3D               # singe : le fruit dans la main
var _throw_t: float = 0.0
var _arm_x: float = 0.0
var _sink: float = 0.0                   # crocodile : 1 = tapi sous l'eau
var _segs135: Array = []                 # mille-pattes : [anneau, pattes, position au repos]
var _legs135: Array = []                 # araignée, scarabée : [pivot, côté, rang, angle au repos]
var _wings: Array = []                   # aigle : [aile, main, côté]
var _gills: Array = []                   # axolotl : [branchie, côté, rang]
var _circle_a: float = 0.0               # jaguar : son angle autour du héros
var _stalk_t: float = 0.0
var _eye_glow: Array = []                # yeux qui brillent dans le noir (jaguar, chacal, coyote)
var throws: int = 0                      # tests : fruits lancés
var steals: int = 0                      # tests : vols du coati
var pounces: int = 0                     # tests : bonds du jaguar


static func spec_of(k: String) -> Dictionary:
	if SPECS135.has(k):
		return SPECS135[k]
	if SPECS133.has(k):
		return SPECS133[k]
	return SPECS132.get(k, {})


static func has_kind(k: String) -> bool:
	return SPECS135.has(k) or SPECS133.has(k) or SPECS132.has(k)


func setup(m: Node, k: String, at: Vector3) -> void:
	if not SPECS135.has(k):
		super.setup(m, k, at)
		return
	manager = m
	kind = k
	spec = SPECS135[k]
	genre = str(spec["genre"])
	vol = bool(spec.get("vol", false))
	peaceful = int(spec["degats"]) == 0
	home = at
	hp = int(spec["pv"])
	hit_radius = float(spec["rayon"])
	hit_height = float(spec["haut"])
	name = "Bete_%s_%d" % [k, get_instance_id()]
	collision_layer = 0 if vol else 1
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var col: Array = spec["col"]
	if str(col[0]) == "boule":
		var s := SphereShape3D.new()
		s.radius = float(col[1])
		cs.shape = s
		cs.position.y = float(col[2])
	else:
		var b := BoxShape3D.new()
		b.size = col[1]
		cs.shape = b
		cs.position.y = (col[1] as Vector3).y * 0.5 + 0.02
	add_child(cs)
	_visual = Node3D.new()
	add_child(_visual)
	match k:
		"singe_hurleur":
			_build_singe()
		"mille_pattes":
			_build_mille_pattes()
		"araignee_geante":
			_build_araignee()
		"luciole":
			_build_lucioles()
		"crocodile":
			_build_crocodile()
		"scarabee_geant":
			_build_scarabee()
		"chacal":
			# chacal doré, la selle noire et argent sur le dos, les grandes oreilles
			_build_canide({"long": 0.58, "haut": 0.5, "rayon": 0.155, "dos": Color(0.62, 0.43, 0.22), "museau": 0.17, "bout": 0.2,
				"crane": 0.62, "oreille": 0.78, "queue": 0.36, "touffe": 0.4, "patte": 0.17, "pied": 0.9, "cou": 0.8, "port": 0.8,
				"taille": 0.66, "yeux": Color(1.0, 0.72, 0.28), "oeil": 0.13, "dedans": Color(0.9, 0.85, 0.75)}, 0.62)
		"coyote":
			# coyote gris fauve, plus grand, les pattes et les oreilles rousses
			_build_canide({"long": 0.68, "haut": 0.6, "rayon": 0.185, "dos": Color(0.5, 0.44, 0.36), "museau": 0.2, "bout": 0.2,
				"crane": 0.6, "oreille": 0.64, "queue": 0.42, "touffe": 0.45, "patte": 0.16, "pied": 0.9, "cou": 0.8, "port": 0.75,
				"taille": 0.68, "yeux": Color(1.0, 0.78, 0.35), "oeil": 0.12, "dedans": Color(0.78, 0.6, 0.45)}, 0.38)
		"coati":
			_build_coati()
		"jaguar_sauvage":
			_build_jaguar()
		"aigle_royal":
			_build_aigle()
		"axolotl":
			_build_axolotl()
	add_to_group("cibles_v28")
	add_to_group("faune_v132")
	global_position = at
	facing = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	if facing.length() < 0.5:
		facing = Vector3.FORWARD
	_flank = randf_range(-1.0, 1.0)
	_wander_t = randf_range(0.5, 3.0)
	if genre == "amphibie":
		_hidden = true
		_sink = 1.0
		state = "cache"
	elif vol:
		_alt = randf_range(11.0, 15.0) if k == "aigle_royal" else randf_range(0.8, 1.8)
		_orbit_c = Vector3(at.x, 0.0, at.z)
		_orbit_a = randf() * TAU
		state = "vol"
	else:
		state = "erre"
	_base_scale = _visual.scale


# =================================================================== modèles : l'île de la jungle

## Le singe hurleur : pelage noir, le manteau doré sur les flancs, la face nue et noire, la grosse
## gorge (c'est elle qui résonne), de longs bras, et la queue préhensile enroulée au bout.
func _build_singe() -> void:
	var fur := _vmat(Color(0.17, 0.1, 0.05), 0.95)
	var face := _mat(Color(0.05, 0.04, 0.035), 0.55)
	var flanc := func(s: float, ang: float) -> float:
		return 0.8 + 1.5 * pow(absf(cos(ang)), 3.0) * smoothstep(0.05, 0.5, s) + 0.06 * sin(s * 40.0 + ang * 7.0)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	var sp: Array = []
	var rr: Array = []
	for i in range(8):
		var u: float = float(i) / 7.0
		sp.append(Vector3(0, lerpf(0.5, 0.66, u) + 0.03 * sin(u * PI), lerpf(-0.2, 0.16, u)))
		rr.append(lerpf(0.12, 0.15, sin(u * PI)) * (1.0 - 0.25 * smoothstep(0.85, 1.0, u)))
	_put(body, _tube_fn("singe:corps", sp, rr, 12, 1.1, flanc), fur)
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.74, 0.22)
	body.add_child(head)
	_pivots["tete"] = head
	_mesh(head, _unit_sphere(), fur, Vector3(0, 0.02, -0.02), Vector3(0.11, 0.1, 0.11))
	_mesh(head, _unit_sphere(), face, Vector3(0, -0.005, 0.06), Vector3(0.075, 0.075, 0.06))
	_mesh(head, _unit_sphere(), face, Vector3(0, -0.05, 0.095), Vector3(0.05, 0.035, 0.045))
	var brow := BoxMesh.new()
	brow.size = Vector3(0.1, 0.018, 0.03)
	_mesh(head, brow, face, Vector3(0, 0.035, 0.1))
	var eye := _mat(Color(0.12, 0.06, 0.02), 0.1)
	var glint := _mat(Color(1, 1, 1), 0.1, 1.5)
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), eye, Vector3(sx * 0.03, 0.02, 0.112), Vector3.ONE * 0.013)
		_mesh(head, _unit_sphere(), glint, Vector3(sx * 0.03 - 0.003, 0.025, 0.124), Vector3.ONE * 0.003)
		_mesh(head, _unit_sphere(), fur, Vector3(sx * 0.1, 0.02, -0.01), Vector3(0.025, 0.03, 0.02))
	# la gorge et la barbe (la mâchoire s'ouvre quand il hurle)
	var jaw := Node3D.new()
	jaw.position = Vector3(0, -0.05, 0.04)
	head.add_child(jaw)
	_pivots["machoire"] = jaw
	_mesh(jaw, _unit_sphere(), fur, Vector3(0, -0.05, 0.0), Vector3(0.085, 0.08, 0.075))
	_mesh(jaw, _unit_sphere(), face, Vector3(0, -0.01, 0.05), Vector3(0.045, 0.02, 0.035))
	# bras (longs) et jambes
	var mango := _mat(Color(0.95, 0.62, 0.12), 0.45)
	for i in range(4):
		var sx2: float = -1.0 if i % 2 == 0 else 1.0
		var front: bool = i < 2
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * 0.12, 0.62 if front else 0.5, 0.12 if front else -0.18)
		body.add_child(leg)
		var hgt: float = leg.position.y
		var path: Array
		if front:
			path = [Vector3.ZERO, Vector3(sx2 * 0.02, -hgt * 0.5, 0.05), Vector3(0, -hgt + 0.03, 0.08)]
		else:
			path = [Vector3.ZERO, Vector3(sx2 * 0.03, -hgt * 0.45, 0.12), Vector3(0, -hgt + 0.03, 0.02)]
		_put(leg, _tube_fn("singe:membre%d" % (0 if front else 1), path, [0.05, 0.035, 0.03], 8, 1.0, Callable()), fur)
		_mesh(leg, _unit_sphere(), face, (path[2] as Vector3) + Vector3(0, 0.0, 0.03), Vector3(0.035, 0.02, 0.05))
		_legs.append([leg, sx2, i])
		if front and sx2 > 0.0:
			_pivots["bras"] = leg
			_fruit = _mesh(leg, _unit_sphere(), mango, (path[2] as Vector3) + Vector3(0, 0.06, 0.07), Vector3(0.05, 0.065, 0.05))
			_fruit.visible = false
	# la queue : vers l'arrière, elle monte, et s'enroule au bout
	var tail := Node3D.new()
	tail.name = "Queue"
	tail.position = Vector3(0, 0.5, -0.22)
	body.add_child(tail)
	_pivots["queue"] = tail
	var tp: Array = []
	for i in range(10):
		var u: float = float(i) / 9.0
		tp.append(Vector3(0, sin(u * PI * 0.55) * 0.42, -u * 0.5))
	var cc: Vector3 = (tp[9] as Vector3) + Vector3(0, -0.09, 0.0)
	for k2 in range(1, 9):
		var th: float = float(k2) / 8.0 * PI * 1.6
		tp.append(cc + Vector3(0, cos(th) * 0.09, -sin(th) * 0.09))
	var tr: Array = []
	for i in range(tp.size()):
		tr.append(lerpf(0.035, 0.012, float(i) / float(tp.size() - 1)))
	_put(tail, _tube_fn("singe:queue", tp, tr, 8, 1.0, Callable()), fur)


## Le mille-pattes géant (une scolopendre) : seize anneaux de chitine brun-rouge luisant, une
## paire de pattes orangées par anneau, de longues antennes, les crochets venimeux devant.
func _build_mille_pattes() -> void:
	var chit := _mat(Color(0.3, 0.075, 0.035), 0.26)
	chit.metallic_specular = 0.75
	var chit_dark := _mat(Color(0.1, 0.035, 0.025), 0.3)
	var patte := _mat(Color(0.9, 0.56, 0.15), 0.42)
	var n: int = 16
	for i in range(n):
		var u: float = float(i) / float(n - 1)
		var seg := Node3D.new()
		seg.position = Vector3(0, 0.12, 0.72 - u * 1.5)
		_visual.add_child(seg)
		var w: float = 0.1 * (1.0 - 0.35 * smoothstep(0.7, 1.0, u)) * (0.88 if i == 0 else 1.0)
		_mesh(seg, _unit_sphere(), chit, Vector3.ZERO, Vector3(w, w * 0.42, 0.062))
		_mesh(seg, _unit_sphere(), chit_dark, Vector3(0, -0.014, -0.03), Vector3(w * 0.97, w * 0.34, 0.045))
		var legs: Array = []
		if i > 0:
			for sx in [-1.0, 1.0]:
				var lp := Node3D.new()
				lp.position = Vector3(sx * w * 0.85, -0.01, 0)
				seg.add_child(lp)
				var path: Array = [Vector3.ZERO, Vector3(sx * 0.09, 0.03, 0.01), Vector3(sx * 0.15, -0.11, 0.02)]
				var key: String = "mp:patte"
				if i == n - 1:
					path = [Vector3.ZERO, Vector3(sx * 0.05, 0.02, -0.12), Vector3(sx * 0.09, -0.03, -0.3)]
					key = "mp:queue"
				_put(lp, _tube_fn(key + ("g" if sx < 0.0 else "d"), path, [0.013, 0.01, 0.004], 5, 1.0, Callable()), patte)
				legs.append([lp, sx])
		_segs135.append([seg, legs, seg.position])
	var head: Node3D = _segs135[0][0]
	_pivots["tete"] = head
	var noir := _mat(Color(0.02, 0.02, 0.02), 0.1)
	for sx in [-1.0, 1.0]:
		var ap: Array = [Vector3(sx * 0.03, 0.01, 0.05), Vector3(sx * 0.08, 0.06, 0.18), Vector3(sx * 0.16, 0.05, 0.33)]
		_put(head, _tube_fn("mp:antenne%d" % int(sx), ap, [0.008, 0.006, 0.002], 5, 1.0, Callable()), patte)
		var fp: Array = [Vector3(sx * 0.05, -0.02, 0.03), Vector3(sx * 0.06, -0.025, 0.09), Vector3(sx * 0.015, -0.03, 0.13)]
		_put(head, _tube_fn("mp:croc%d" % int(sx), fp, [0.016, 0.012, 0.003], 6, 1.0, Callable()), chit_dark)
		_mesh(head, _unit_sphere(), noir, Vector3(sx * 0.045, 0.022, 0.04), Vector3.ONE * 0.012)


## L'araignée géante (une mygale) : poilue, noire et brune, les genoux orangés, huit yeux, deux
## gros crochets ; huit pattes articulées, larges comme les bras d'un homme.
func _build_araignee() -> void:
	var poil := _vmat(Color(0.075, 0.058, 0.046), 0.97)
	var genou := _mat(Color(0.8, 0.34, 0.1), 0.9)
	var noir := _mat(Color(0.02, 0.02, 0.02), 0.15)
	var body := Node3D.new()
	body.name = "Corps"
	body.position = Vector3(0, 0.34, 0)
	_visual.add_child(body)
	_pivots["corps"] = body
	var fourrure := func(s: float, ang: float) -> float:
		return 0.85 + 0.25 * sin(s * 37.0 + ang * 11.0) * sin(ang * 5.0 + s * 9.0)
	var ab: Array = []
	var abr: Array = []
	for i in range(9):
		var u: float = float(i) / 8.0
		ab.append(Vector3(0, 0.04 + sin(u * PI) * 0.03, lerpf(-0.04, -0.54, u)))
		abr.append(sin(lerpf(0.15, 0.97, u) * PI) * 0.22)
	_put(body, _tube_fn("araignee:abdomen", ab, abr, 16, 0.85, fourrure), poil)
	_mesh(body, _unit_sphere(), poil, Vector3(0, 0.0, 0.1), Vector3(0.17, 0.09, 0.2))
	# les huit yeux, serrés sur le dessus
	for k in range(8):
		var a: float = TAU * float(k) / 8.0
		_mesh(body, _unit_sphere(), noir, Vector3(cos(a) * 0.03, 0.085, 0.2 + sin(a) * 0.02), Vector3.ONE * (0.014 if k % 4 == 1 else 0.009))
	# chélicères et crocs
	for sx in [-1.0, 1.0]:
		_mesh(body, _unit_sphere(), poil, Vector3(sx * 0.04, -0.02, 0.29), Vector3(0.04, 0.05, 0.05))
		var fp: Array = [Vector3(sx * 0.04, -0.06, 0.32), Vector3(sx * 0.035, -0.1, 0.33), Vector3(sx * 0.02, -0.12, 0.31)]
		_put(body, _tube_fn("araignee:croc%d" % int(sx), fp, [0.013, 0.009, 0.002], 6, 1.0, Callable()), noir)
		# pédipalpes
		var pp: Array = [Vector3(sx * 0.07, -0.02, 0.27), Vector3(sx * 0.11, 0.02, 0.36), Vector3(sx * 0.12, -0.12, 0.42)]
		_put(body, _tube_fn("araignee:palpe%d" % int(sx), pp, [0.022, 0.018, 0.012], 7, 1.0, fourrure), poil)
	# les huit pattes
	var spread: Array = [deg_to_rad(42.0), deg_to_rad(14.0), deg_to_rad(-16.0), deg_to_rad(-46.0)]
	for i in range(8):
		var sx2: float = -1.0 if i < 4 else 1.0
		var j: int = i % 4
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * 0.12, 0.0, 0.14 - float(j) * 0.055)
		var th0: float = -sx2 * float(spread[j])
		leg.rotation.y = th0
		body.add_child(leg)
		var reach: float = 0.9 + (0.1 if j == 0 or j == 3 else 0.0)
		var path: Array = [Vector3.ZERO, Vector3(sx2 * 0.18 * reach, 0.15, 0), Vector3(sx2 * 0.32 * reach, 0.17, 0),
			Vector3(sx2 * 0.46 * reach, 0.0, 0), Vector3(sx2 * 0.54 * reach, -0.33, 0)]
		_put(leg, _tube_fn("araignee:patte%d%s" % [j, "g" if sx2 < 0.0 else "d"], path, [0.058, 0.052, 0.046, 0.038, 0.022], 9, 1.0, fourrure), poil)
		_mesh(leg, _unit_sphere(), genou, path[2], Vector3(0.05, 0.05, 0.05))
		_mesh(leg, _unit_sphere(), genou, (path[3] as Vector3).lerp(path[4], 0.35), Vector3(0.04, 0.03, 0.04))
		_legs135.append([leg, sx2, j, th0])


## Les lucioles : une petite nuée de sept bestioles, le ventre qui s'allume et s'éteint.
func _build_lucioles() -> void:
	var corps := _mat(Color(0.08, 0.07, 0.05), 0.6)
	for i in range(7):
		var nd := Node3D.new()
		_visual.add_child(nd)
		var g := StandardMaterial3D.new()
		g.albedo_color = Color(0.85, 1.0, 0.35)
		g.emission_enabled = true
		g.emission = Color(0.75, 1.0, 0.3)
		g.emission_energy_multiplier = 5.0
		g.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mesh(nd, _unit_sphere(), corps, Vector3(0, 0, 0.012), Vector3(0.008, 0.008, 0.014))
		_mesh(nd, _unit_sphere(), g, Vector3(0, 0, -0.008), Vector3.ONE * 0.016)
		_lucs.append([nd, g, randf() * TAU, randf_range(0.2, 0.75), randf_range(-0.3, 0.35), randf_range(0.6, 1.4)])
	_luc_light = OmniLight3D.new()
	_luc_light.light_color = Color(0.75, 1.0, 0.35)
	_luc_light.light_energy = 0.4
	_luc_light.omni_range = 2.4
	_luc_light.shadow_enabled = false
	_visual.add_child(_luc_light)


# =================================================================== modèles : l'Île des Trois Soleils

## Le crocodile du Nil (de l'Iterou) : long, plat, la peau en écailles olive, le ventre jaune pâle,
## des rangées d'écussons sur le dos et une crête dentelée sur la queue ; la gueule pleine de dents.
func _build_crocodile() -> void:
	var peau := _vmat(Color(0.2, 0.22, 0.13), 0.78)
	var ecaille := _mat(Color(0.13, 0.14, 0.085), 0.82)
	var dent := _mat(Color(0.9, 0.86, 0.72), 0.4)
	var oeil := _mat(Color(0.78, 0.7, 0.22), 0.15, 0.5)
	var noir := _mat(Color(0.02, 0.02, 0.02), 0.1)
	var ventre := func(s: float, ang: float) -> float:
		var b: float = 1.0 + 2.1 * smoothstep(-0.25, -0.85, sin(ang))
		var band: float = 0.78 if (sin(ang) > 0.25 and fmod(s * 11.0, 1.0) < 0.3) else 1.0
		return b * band * (0.9 + 0.1 * sin(s * 60.0 + ang * 9.0))
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	var sp: Array = []
	var rr: Array = []
	for i in range(14):
		var u: float = float(i) / 13.0
		sp.append(Vector3(0, 0.24, lerpf(-0.62, 0.52, u)))
		rr.append(lerpf(0.2, 0.28, sin(u * PI)) * (1.0 - 0.3 * smoothstep(0.75, 1.0, u)))
	_put(body, _tube_fn("croco:corps", sp, rr, 16, 0.55, ventre), peau)
	for k in range(9):
		var z: float = -0.52 + float(k) * 0.125
		for sx in [-1.0, 1.0]:
			_mesh(body, _cyl(0.0, 0.03, 0.05), ecaille, Vector3(sx * 0.075, 0.385, z), Vector3(1.0, 1.0, 1.5))
	# la tête : le crâne et la mâchoire du haut ; la mâchoire du bas s'ouvre
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.25, 0.5)
	body.add_child(head)
	_pivots["tete"] = head
	var hp: Array = [Vector3(0, 0.02, -0.02), Vector3(0, 0.045, 0.16), Vector3(0, 0.025, 0.36), Vector3(0, 0.005, 0.56), Vector3(0, -0.005, 0.66)]
	_put(head, _tube_fn("croco:tete", hp, [0.17, 0.13, 0.085, 0.07, 0.035], 14, 0.5, ventre), peau)
	var jaw := Node3D.new()
	jaw.position = Vector3(0, -0.035, 0.06)
	head.add_child(jaw)
	_pivots["machoire"] = jaw
	var jp: Array = [Vector3(0, -0.02, 0.0), Vector3(0, -0.04, 0.24), Vector3(0, -0.035, 0.48), Vector3(0, -0.03, 0.57)]
	_put(jaw, _tube_fn("croco:machoire", jp, [0.13, 0.085, 0.06, 0.03], 12, 0.4, ventre), peau)
	for k2 in range(9):
		var z2: float = 0.15 + float(k2) * 0.052
		var wv: float = lerpf(0.11, 0.06, float(k2) / 8.0)
		for sx in [-1.0, 1.0]:
			_mesh(head, _cyl(0.009, 0.0, 0.04), dent, Vector3(sx * wv * 0.92, -0.035, z2))
			_mesh(jaw, _cyl(0.0, 0.008, 0.032), dent, Vector3(sx * wv * 0.88, -0.012, z2 - 0.05))
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), peau, Vector3(sx * 0.06, 0.1, 0.12), Vector3(0.036, 0.032, 0.042))
		_mesh(head, _unit_sphere(), oeil, Vector3(sx * 0.065, 0.118, 0.138), Vector3(0.022, 0.02, 0.02))
		_mesh(head, _unit_sphere(), noir, Vector3(sx * 0.066, 0.12, 0.155), Vector3(0.004, 0.017, 0.006))
		_mesh(head, _unit_sphere(), ecaille, Vector3(sx * 0.018, 0.04, 0.62), Vector3(0.016, 0.012, 0.016))
	# la queue, plus haute que large, avec sa crête
	var tail := Node3D.new()
	tail.name = "Queue"
	tail.position = Vector3(0, 0.22, -0.6)
	body.add_child(tail)
	_pivots["queue"] = tail
	var tp: Array = []
	var tr: Array = []
	for i in range(12):
		var u: float = float(i) / 11.0
		tp.append(Vector3(0, -0.04 * u, -u * 1.3))
		tr.append(lerpf(0.19, 0.02, pow(u, 0.8)))
	_put(tail, _tube_fn("croco:queue", tp, tr, 12, 1.25, ventre), peau)
	for k3 in range(11):
		var u: float = float(k3) / 10.0
		var z3: float = -0.06 - u * 1.18
		var top: float = -0.04 * u + lerpf(0.19, 0.03, pow(u, 0.8)) * 1.2
		var sz: float = 1.0 - u * 0.5
		if u < 0.45:
			for sx in [-1.0, 1.0]:
				_mesh(tail, _cyl(0.0, 0.026 * sz, 0.075 * sz), ecaille, Vector3(sx * 0.05, top, z3), Vector3(0.5, 1.0, 1.4))
		else:
			_mesh(tail, _cyl(0.0, 0.026 * sz, 0.075 * sz), ecaille, Vector3(0, top, z3), Vector3(0.5, 1.0, 1.4))
	# quatre pattes courtes, écartées
	for i in range(4):
		var sx2: float = -1.0 if i % 2 == 0 else 1.0
		var front: bool = i < 2
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * 0.2, 0.22, 0.33 if front else -0.45)
		body.add_child(leg)
		var path: Array = [Vector3.ZERO, Vector3(sx2 * 0.2, -0.04, 0.02), Vector3(sx2 * 0.27, -0.2, 0.06 if front else -0.02)]
		_put(leg, _tube_fn("croco:patte%d%s" % [0 if front else 1, "g" if sx2 < 0.0 else "d"], path, [0.07, 0.05, 0.035], 8, 1.0, ventre), peau)
		_mesh(leg, _unit_sphere(), peau, (path[2] as Vector3) + Vector3(sx2 * 0.02, -0.015, 0.05), Vector3(0.06, 0.02, 0.08))
		_legs.append([leg, sx2, i])


## Le scarabée géant (un bousier sacré) : noir à reflets verts et dorés, la tête en râteau ; il
## pousse à reculons, pattes arrière posées sur sa grosse boule de terre (c'est elle qui roule).
func _build_scarabee() -> void:
	var r: float = 0.4
	var boule := Node3D.new()
	boule.name = "Boule"
	boule.position = Vector3(0, r, 0)
	_visual.add_child(boule)
	_pivots["boule"] = boule
	var pos_fn := func(d: Vector3) -> Vector3:
		var nz: float = sin(d.x * 9.0 + d.y * 4.0) * 0.5 + sin(d.z * 11.0 - d.x * 3.0) * 0.5 + sin(d.y * 13.0 + d.z * 5.0) * 0.3
		return d * r * (1.0 + 0.045 * nz)
	var col_fn := func(d: Vector3, _p: Vector3) -> Color:
		var nz: float = 0.5 + 0.5 * sin(d.x * 23.0 + d.z * 17.0) * sin(d.y * 19.0)
		return Color(0.52, 0.42, 0.28).lerp(Color(0.34, 0.27, 0.17), nz * 0.75)
	_put(boule, _blob_mesh("scarabee:boule", pos_fn, col_fn, 18, 26), _vmat(Color(1, 1, 1), 0.97))
	var paille := _mat(Color(0.72, 0.62, 0.36), 0.9)
	for k in range(7):
		var d: Vector3 = Vector3(sin(k * 2.3), cos(k * 1.7), sin(k * 3.1 + 1.0)).normalized()
		_mesh(boule, _cyl(0.006, 0.006, 0.16), paille, d * r * 1.02, Vector3.ONE, Vector3(k * 0.9, k * 1.3, 0))
	# le scarabée : tête vers -z (il recule), l'arrière relevé contre la boule
	var carap := _mat(Color(0.035, 0.05, 0.035), 0.22)
	carap.metallic = 0.6
	var dark := _mat(Color(0.02, 0.02, 0.02), 0.4)
	var bug := Node3D.new()
	bug.name = "Corps"
	bug.position = Vector3(0, 0.34, -r - 0.36)
	bug.rotation.x = -0.45
	bug.scale = Vector3.ONE * 1.45
	_visual.add_child(bug)
	_pivots["corps"] = bug
	_mesh(bug, _unit_sphere(), carap, Vector3(0, 0.0, 0.06), Vector3(0.2, 0.13, 0.24))
	var seam := BoxMesh.new()
	seam.size = Vector3(0.006, 0.01, 0.42)
	_mesh(bug, seam, dark, Vector3(0, 0.128, 0.06))
	_mesh(bug, _unit_sphere(), carap, Vector3(0, 0.0, -0.16), Vector3(0.17, 0.1, 0.1))
	_mesh(bug, _unit_sphere(), carap, Vector3(0, -0.02, -0.28), Vector3(0.13, 0.04, 0.08))
	for k2 in range(6):
		var x: float = (float(k2) - 2.5) * 0.04
		_mesh(bug, _cyl(0.0, 0.012, 0.04), carap, Vector3(x, -0.02, -0.36), Vector3.ONE, Vector3(-PI * 0.5, 0, 0))
	for sx in [-1.0, 1.0]:
		_mesh(bug, _unit_sphere(), dark, Vector3(sx * 0.09, 0.0, -0.24), Vector3.ONE * 0.018)
	# six pattes : devant, pour gratter ; au milieu ; derrière, longues, posées sur la boule
	for i in range(6):
		var sx2: float = -1.0 if i % 2 == 0 else 1.0
		var pair: int = int(i / 2)
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * 0.12, -0.06, [-0.17, -0.02, 0.12][pair])
		bug.add_child(leg)
		var path: Array
		match pair:
			0:
				path = [Vector3.ZERO, Vector3(sx2 * 0.12, -0.02, -0.08), Vector3(sx2 * 0.18, -0.16, -0.16)]
			1:
				path = [Vector3.ZERO, Vector3(sx2 * 0.16, 0.0, 0.0), Vector3(sx2 * 0.26, -0.2, 0.04)]
			_:
				path = [Vector3.ZERO, Vector3(sx2 * 0.15, 0.04, 0.12), Vector3(sx2 * 0.14, 0.12, 0.3)]
		_put(leg, _tube_fn("scarabee:patte%d%s" % [pair, "g" if sx2 < 0.0 else "d"], path, [0.022, 0.016, 0.008], 6, 1.0, Callable()), carap)
		_legs135.append([leg, sx2, pair, 0.0])


## Un mammifère à quatre pattes, plus fin que le gabarit V132 : croupe ronde, taille fine,
## poitrine profonde ; un cou, un crâne et un museau distincts ; des pattes à trois segments (le
## jarret en arrière derrière) ; la queue pendante, dressée ou en crosse. Sert au chacal, au
## coyote, au coati et au jaguar.
func _profil(u: float, pts: Array) -> float:
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		if u <= b.x:
			return lerpf(a.y, b.y, smoothstep(a.x, b.x, u))
	return (pts[pts.size() - 1] as Vector2).y


func _build_mammal(c: Dictionary) -> void:
	var k: String = kind
	var L: float = c["long"]
	var H: float = c["haut"]
	var R: float = c["rayon"]
	var fur: Material = c["mat"]
	var shade: Callable = c.get("shade", Callable(self, "_shade_dos"))
	var dark := _mat(c.get("sombre", Color(0.05, 0.04, 0.035)), 0.55)
	# les sphères (crâne, oreilles, pattes) n'ont pas de couleurs de sommet : leur matière prend la
	# teinte moyenne du pelage
	var flat: StandardMaterial3D = (fur as StandardMaterial3D).duplicate()
	flat.vertex_color_use_as_albedo = false
	flat.albedo_color = (fur as StandardMaterial3D).albedo_color * float(c.get("teinte", 0.82))
	flat.albedo_color.a = 1.0
	_flash_mats.append(flat)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	# le tronc : de la croupe (u = 0) au garrot (u = 1) ; la poitrine descend plus bas que le ventre
	var prof: Array = [Vector2(0.0, 0.62), Vector2(0.12, 0.84), Vector2(0.42, float(c.get("taille", 0.7))), Vector2(0.72, 1.0), Vector2(0.92, 0.95), Vector2(1.0, 0.62)]
	var spine: Array = []
	var radii: Array = []
	var top: float = H - R * 0.55
	for i in range(18):
		var u: float = float(i) / 17.0
		var y: float = top + 0.025 * sin(u * PI) - R * 0.22 * smoothstep(0.45, 0.8, u) * (1.0 - smoothstep(0.85, 1.0, u)) + float(c.get("garrot", 0.0)) * smoothstep(0.7, 1.0, u)
		spine.append(Vector3(0, y, lerpf(-L * 0.5, L * 0.5, u)))
		radii.append(R * _profil(u, prof))
	_put(body, _tube_fn(k + ":tronc", spine, radii, int(c.get("segs", 16)), float(c.get("aplat", 1.2)), shade), fur)
	# le cou et la tête
	var neck0: Vector3 = (spine[15] as Vector3) + Vector3(0, R * 0.2, 0)
	var nl: float = float(c.get("cou", 0.6)) * R
	var nang: float = float(c.get("port", 0.75))
	var neck1: Vector3 = neck0 + Vector3(0, sin(nang), cos(nang)) * nl
	_put(body, _tube_fn(k + ":cou", [neck0, (neck0 + neck1) * 0.5, neck1], [R * 0.62, R * 0.5, R * 0.42], 12, 1.1, shade), fur)
	var head := Node3D.new()
	head.name = "Tete"
	head.position = neck1
	body.add_child(head)
	_pivots["tete"] = head
	var sk: float = float(c.get("crane", 0.5)) * R
	_mesh(head, _unit_sphere(), flat, Vector3(0, sk * 0.1, sk * 0.25), Vector3(sk, sk * 0.9, sk * 1.05))
	var ml: float = float(c["museau"])
	var mt: float = float(c.get("bout", 0.22)) * R
	var mp: Array = [Vector3(0, -sk * 0.05, sk * 0.6), Vector3(0, -sk * 0.18, sk * 0.6 + ml * 0.55), Vector3(0, -sk * 0.25, sk * 0.6 + ml)]
	_put(head, _tube_fn(k + ":museau", mp, [sk * 0.62, mt * 1.25, mt], 12, 0.85, shade), fur)
	var nez: Vector3 = mp[2]
	var tr2: float = float(c.get("truffe", 0.85))
	_mesh(head, _unit_sphere(), dark, nez + Vector3(0, 0.005 + mt * (0.85 - tr2) * 0.6, 0.0), Vector3(mt * tr2, mt * tr2 * 0.75, mt * 0.6))
	# la mâchoire du bas, sous le museau
	_put(head, _tube_fn(k + ":machoire", [Vector3(0, -sk * 0.45, sk * 0.45), Vector3(0, -sk * 0.42, sk * 0.6 + ml * 0.85)], [sk * 0.35, mt * 0.7], 8, 0.7, shade), fur)
	var ycol: Color = c.get("yeux", Color(0.3, 0.2, 0.08))
	var oeil := _mat(ycol, 0.12, 0.6 if c.has("yeux") else 0.0)
	if c.has("yeux"):
		_eye_glow.append(oeil)
	var pupille := _mat(Color(0.01, 0.01, 0.01), 0.1)
	var eh: float = float(c.get("oeil", 0.12)) * R
	for sx in [-1.0, 1.0]:
		var ep := Vector3(sx * sk * 0.52, sk * 0.28, sk * 0.78)
		_mesh(head, _unit_sphere(), oeil, ep, Vector3(eh, eh * 0.85, eh * 0.6))
		_mesh(head, _unit_sphere(), pupille, ep + Vector3(0, 0, eh * 0.5), Vector3(eh * (0.35 if c.get("pupille", "ronde") == "ronde" else 0.2), eh * 0.75, eh * 0.2))
		# les oreilles
		var oh: float = float(c["oreille"]) * R
		var ear := Node3D.new()
		ear.position = Vector3(sx * sk * 0.55, sk * 0.75, -sk * 0.05)
		ear.rotation = Vector3(-0.15, 0, sx * -float(c.get("ecart", 0.35)))
		head.add_child(ear)
		ear.name = "Oreille"
		if c.get("forme_oreille", "pointe") == "pointe":
			_mesh(ear, _cyl(0.0, oh * 0.45, oh), flat, Vector3(0, oh * 0.5, 0), Vector3(1.0, 1.0, 0.35))
			_mesh(ear, _cyl(0.0, oh * 0.32, oh * 0.8), _mat(c.get("dedans", Color(0.82, 0.74, 0.62)), 0.9), Vector3(0, oh * 0.45, oh * 0.06), Vector3(1.0, 1.0, 0.2))
		else:
			_mesh(ear, _unit_sphere(), flat, Vector3(0, oh * 0.5, 0), Vector3(oh * 0.55, oh * 0.55, oh * 0.2))
			_mesh(ear, _unit_sphere(), dark, Vector3(0, oh * 0.5, -oh * 0.08), Vector3(oh * 0.45, oh * 0.45, oh * 0.08))
	# les pattes : épaule (ou hanche), coude (ou grasset), poignet (ou jarret), patte
	var lw: float = float(c.get("patte", 0.16)) * R
	var paw: float = float(c.get("pied", 1.0))
	for i in range(4):
		var sx2: float = -1.0 if i % 2 == 0 else 1.0
		var front: bool = i < 2
		var su: float = 0.86 if front else 0.12
		var sp_y: float = (spine[int(su * 17.0)] as Vector3).y - R * 0.25
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * R * 0.58, sp_y, lerpf(-L * 0.5, L * 0.5, su))
		body.add_child(leg)
		var lh: float = sp_y
		var path: Array
		if front:
			path = [Vector3.ZERO, Vector3(0, -lh * 0.42, -lh * 0.06), Vector3(0, -lh * 0.86, -lh * 0.02), Vector3(0, -lh + 0.03, lh * 0.03)]
		else:
			path = [Vector3.ZERO, Vector3(0, -lh * 0.38, lh * 0.14), Vector3(0, -lh * 0.72, -lh * 0.1), Vector3(0, -lh + 0.03, -lh * 0.04)]
		_put(leg, _tube_fn(k + (":avant" if front else ":arriere"), path, [lw * (2.4 if front else 2.8), lw * 1.3, lw * 0.95, lw * 0.85], 10, 1.0, shade), fur)
		_mesh(leg, _unit_sphere(), flat, (path[3] as Vector3) + Vector3(0, 0.0, lw * 0.6), Vector3(lw * 1.25 * paw, lw * 0.8, lw * 1.7 * paw))
		_legs.append([leg, sx2, i])
	# la queue
	var tail := Node3D.new()
	tail.name = "Queue"
	tail.position = (spine[0] as Vector3) + Vector3(0, R * 0.15, -R * 0.05)
	body.add_child(tail)
	_pivots["queue"] = tail
	var ql: float = float(c["queue"])
	var tp: Array = []
	var tr: Array = []
	var style: String = str(c.get("style", "pend"))
	var touffe: float = float(c.get("touffe", 0.3))
	for i in range(16):
		var u: float = float(i) / 15.0
		var q: Vector3
		match style:
			"dressee":
				q = Vector3(0, sin(u * PI * 0.5) * ql * 0.92, -sin(u * PI) * ql * 0.22 - u * ql * 0.08)
			"crosse":
				q = Vector3(0, -sin(u * PI * 0.62) * ql * 0.62 + smoothstep(0.75, 1.0, u) * ql * 0.16, -u * ql * 0.85)
			_:
				q = Vector3(0, -sin(u * PI * 0.5) * ql * 0.55 - u * ql * 0.1, -sin(u * PI * 0.5) * ql * 0.7)
		tp.append(q)
		tr.append(R * lerpf(0.26, touffe, sin(u * PI * 0.85)) * (1.0 - 0.75 * smoothstep(0.85, 1.0, u)))
	_put(tail, _tube_fn(k + ":queue", tp, tr, 10, 1.0, c.get("shade_queue", shade)), fur)


## Le pelage des canidés : plus sombre sur le dos (la selle), plus clair sous le ventre.
func _selle(force: float) -> Callable:
	return func(s: float, ang: float) -> float:
		var base: float = 0.72 + 0.28 * (0.5 - 0.5 * sin(ang)) + 0.05 * sin(s * 37.0 + ang * 5.0)
		var sad: float = smoothstep(0.25, 0.8, sin(ang)) * smoothstep(0.1, 0.3, s) * (1.0 - smoothstep(0.8, 0.97, s))
		return base * (1.0 - force * sad) + 0.5 * smoothstep(-0.3, -0.9, sin(ang))


## Chacal et coyote : longues pattes fines, museau pointu, grandes oreilles, queue touffue pendante
## au bout noir ; la selle sombre sur le dos.
func _build_canide(c: Dictionary, selle: float) -> void:
	var sh: Callable = _selle(selle)
	var queue := func(s: float, ang: float) -> float:
		return 0.18 if s > 0.86 else float(sh.call(0.5, ang))
	var d: Dictionary = c.duplicate()
	d["mat"] = _vmat(c["dos"], 0.93)
	d["shade"] = sh
	d["shade_queue"] = queue
	d["style"] = "pend"
	d["forme_oreille"] = "pointe"
	_build_mammal(d)


## Le coati : petit, bas sur pattes, un museau long et fin au bout noir, des taches blanches sur la
## face, et la queue annelée qu'il tient droite comme un mât.
func _build_coati() -> void:
	var sh: Callable = _selle(0.15)
	var anneaux := func(s: float, _ang: float) -> float:
		return 0.3 if fmod(s * 8.0 + 0.2, 1.0) < 0.42 else 1.1
	_build_mammal({"long": 0.46, "haut": 0.32, "rayon": 0.115, "mat": _vmat(Color(0.52, 0.34, 0.19), 0.95), "shade": sh,
		"shade_queue": anneaux, "museau": 0.16, "bout": 0.16, "crane": 0.55, "oreille": 0.38, "forme_oreille": "rond",
		"queue": 0.62, "style": "dressee", "touffe": 0.3, "patte": 0.2, "pied": 1.1, "cou": 0.5, "port": 0.35, "taille": 0.85, "oeil": 0.14})
	var head: Node3D = _pivots["tete"]
	var blanc := _mat(Color(0.92, 0.9, 0.84), 0.9)
	var sk: float = 0.55 * 0.115
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), blanc, Vector3(sx * sk * 0.5, sk * 0.6, sk * 0.85), Vector3(0.016, 0.009, 0.014))
		_mesh(head, _unit_sphere(), blanc, Vector3(sx * sk * 0.55, -sk * 0.1, sk * 0.95), Vector3(0.012, 0.012, 0.022))
	_mesh(head, _unit_sphere(), blanc, Vector3(0, -sk * 0.2, sk * 0.6 + 0.1), Vector3(0.022, 0.018, 0.03))


## Le jaguar : trapu et puissant, la robe dorée semée de rosettes noires (une vraie texture,
## posée « en triplan » sur le corps), le ventre crème, la tête large ; ses yeux brillent la nuit.
static var _tex135: Dictionary = {}


func _disque(img: Image, cx: float, cy: float, r: float, col: Color) -> void:
	var n: int = img.get_width()
	for dy in range(int(-r) - 1, int(r) + 2):
		for dx in range(int(-r) - 1, int(r) + 2):
			if dx * dx + dy * dy <= r * r:
				img.set_pixel(posmod(int(cx) + dx, n), posmod(int(cy) + dy, n), col)


func _rosette_tex() -> Texture2D:
	if _tex135.has("rosettes"):
		return _tex135["rosettes"]
	var n: int = 256
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 135
	var base := Color(0.72, 0.46, 0.18)
	for y in range(n):
		for x in range(n):
			var v: float = 1.0 + 0.07 * sin(float(x) * 0.9 + float(y) * 0.13) * sin(float(y) * 0.71) + rng.randf_range(-0.05, 0.05)
			img.set_pixel(x, y, Color(base.r * v, base.g * v, base.b * v))
	var noir := Color(0.07, 0.05, 0.035)
	# des rosettes : un anneau sombre brisé (deux ou trois trouées), le centre plus foncé, parfois
	# une tache au milieu
	for i in range(22):
		var cx: float = rng.randf() * n
		var cy: float = rng.randf() * n
		var rr: float = rng.randf_range(9.0, 14.0)
		_disque(img, cx, cy, rr * 0.8, Color(0.6, 0.38, 0.14))
		var gaps: Array = []
		for g in range(rng.randi_range(2, 3)):
			gaps.append(rng.randf() * TAU)
		var steps: int = 26
		for st in range(steps):
			var a: float = TAU * float(st) / float(steps)
			var hole: bool = false
			for g2 in gaps:
				if absf(wrapf(a - float(g2), -PI, PI)) < 0.32:
					hole = true
			if not hole:
				var w: float = rr * rng.randf_range(0.85, 1.15)
				_disque(img, cx + cos(a) * w, cy + sin(a) * w * 0.85, rng.randf_range(2.2, 3.4), noir)
		if rng.randf() < 0.5:
			_disque(img, cx + rng.randf_range(-3, 3), cy + rng.randf_range(-3, 3), rng.randf_range(1.6, 2.6), noir)
	for i in range(30):
		_disque(img, rng.randf() * n, rng.randf() * n, rng.randf_range(2.0, 3.6), noir)
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex135["rosettes"] = t
	return t


func _build_jaguar() -> void:
	var fur := _mat(Color(1, 1, 1), 0.86)
	fur.vertex_color_use_as_albedo = true
	fur.albedo_texture = _rosette_tex()
	fur.uv1_triplanar = true
	fur.uv1_scale = Vector3(1.4, 1.4, 1.4)
	var ventre := func(s: float, ang: float) -> float:
		return 0.88 + 0.5 * smoothstep(0.0, -0.8, sin(ang)) + 0.04 * sin(s * 29.0 + ang * 3.0)
	var queue := func(s: float, ang: float) -> float:
		if s > 0.9:
			return 0.1
		if s > 0.6:
			return 0.15 if fmod(s * 11.0, 1.0) < 0.3 else float(ventre.call(s, ang))
		return float(ventre.call(s, ang))
	_build_mammal({"long": 1.04, "haut": 0.72, "rayon": 0.24, "mat": fur, "truffe": 0.38, "shade": ventre, "shade_queue": queue,
		"museau": 0.13, "bout": 0.42, "crane": 0.6, "oreille": 0.32, "forme_oreille": "rond", "ecart": 0.5,
		"queue": 0.72, "style": "crosse", "touffe": 0.24, "patte": 0.25, "pied": 1.0, "teinte": 0.9, "cou": 0.55, "port": 0.4,
		"taille": 0.82, "segs": 22, "aplat": 1.18, "yeux": Color(0.88, 0.7, 0.22), "oeil": 0.13, "garrot": 0.02, "sombre": Color(0.25, 0.14, 0.12)})
	var head: Node3D = _pivots["tete"]
	var creme := _mat(Color(0.88, 0.8, 0.64), 0.9)
	var sk: float = 0.6 * 0.24
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), creme, Vector3(sx * sk * 0.26, -sk * 0.3, sk * 0.6 + 0.1), Vector3(0.045, 0.035, 0.04))
	_mesh(head, _unit_sphere(), creme, Vector3(0, -sk * 0.5, sk * 0.75), Vector3(0.055, 0.028, 0.05))


## L'aigle royal : brun sombre, la nuque dorée, le bec crochu, les grandes ailes aux rémiges
## écartées comme des doigts, la queue en éventail ; les serres jaunes aux griffes noires.
func _build_aigle() -> void:
	var plume := _vmat(Color(0.21, 0.135, 0.075), 0.9)
	var nuque := _vmat(Color(0.62, 0.43, 0.18), 0.9)
	var bec := _mat(Color(0.14, 0.12, 0.1), 0.35)
	var cire := _mat(Color(0.95, 0.78, 0.25), 0.5)
	var jaune := _mat(Color(0.92, 0.76, 0.25), 0.6)
	var noir := _mat(Color(0.03, 0.03, 0.03), 0.3)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	var sp: Array = []
	var rr: Array = []
	for i in range(9):
		var u: float = float(i) / 8.0
		sp.append(Vector3(0, -0.02 * sin(u * PI), lerpf(-0.38, 0.28, u)))
		rr.append(lerpf(0.05, 0.14, smoothstep(0.0, 0.6, u)) * (1.0 - 0.2 * smoothstep(0.85, 1.0, u)))
	_put(body, _tube_fn("aigle:corps", sp, rr, 14, 1.0, Callable(self, "_shade_dos")), plume)
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.05, 0.31)
	body.add_child(head)
	_pivots["tete"] = head
	_mesh(head, _unit_sphere(), nuque, Vector3(0, 0.02, 0.0), Vector3(0.075, 0.072, 0.09))
	_mesh(head, _unit_sphere(), cire, Vector3(0, 0.015, 0.08), Vector3(0.03, 0.025, 0.02))
	var bp: Array = [Vector3(0, 0.015, 0.085), Vector3(0, 0.008, 0.13), Vector3(0, -0.03, 0.15)]
	_put(head, _tube_fn("aigle:bec", bp, [0.025, 0.017, 0.003], 8, 1.0, Callable()), bec)
	var oeil := _mat(Color(0.75, 0.5, 0.12), 0.15, 0.3)
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), oeil, Vector3(sx * 0.047, 0.03, 0.05), Vector3.ONE * 0.014)
		_mesh(head, _unit_sphere(), noir, Vector3(sx * 0.05, 0.03, 0.056), Vector3.ONE * 0.007)
		var brow := BoxMesh.new()
		brow.size = Vector3(0.03, 0.012, 0.04)
		_mesh(head, brow, plume, Vector3(sx * 0.045, 0.048, 0.05), Vector3.ONE, Vector3(0, 0, sx * 0.25))
	# les ailes : le bras, la main (qui se plie), et les six rémiges écartées
	for sx in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.position = Vector3(sx * 0.09, 0.05, 0.1)
		body.add_child(wing)
		_mesh(wing, _unit_sphere(), plume, Vector3(sx * 0.28, 0.0, -0.03), Vector3(0.3, 0.025, 0.17))
		_mesh(wing, _unit_sphere(), nuque, Vector3(sx * 0.22, 0.012, 0.03), Vector3(0.2, 0.012, 0.07))
		var hand := Node3D.new()
		hand.position = Vector3(sx * 0.55, 0.0, 0.0)
		wing.add_child(hand)
		_mesh(hand, _unit_sphere(), plume, Vector3(sx * 0.16, 0.0, -0.05), Vector3(0.2, 0.02, 0.15))
		for k in range(6):
			var b0 := Vector3(sx * 0.28, 0.0, -0.0 - float(k) * 0.035)
			var b1 := Vector3(sx * (0.5 - float(k) * 0.02), 0.0, -0.05 - float(k) * 0.06)
			_put(hand, _tube_fn("aigle:remige%d%s" % [k, "g" if sx < 0.0 else "d"], [b0, (b0 + b1) * 0.5, b1], [0.03, 0.025, 0.008], 6, 0.22, Callable()), plume)
		_wings.append([wing, hand, sx])
		_pivots["aile%d" % int(sx)] = wing
	# la queue en éventail
	var tail := Node3D.new()
	tail.name = "Queue"
	tail.position = Vector3(0, 0.0, -0.36)
	body.add_child(tail)
	_pivots["queue"] = tail
	for k in range(9):
		var a: float = (float(k) - 4.0) * 0.11
		_mesh(tail, _unit_sphere(), plume, Vector3(sin(a) * 0.12, 0.0, -cos(a) * 0.12), Vector3(0.035, 0.008, 0.15), Vector3(0, a, 0))
	# les serres : rentrées en vol, en avant quand il pique
	var talons := Node3D.new()
	talons.position = Vector3(0, -0.09, 0.02)
	body.add_child(talons)
	_pivots["serres"] = talons
	for sx in [-1.0, 1.0]:
		_mesh(talons, _unit_sphere(), plume, Vector3(sx * 0.05, 0.0, 0.0), Vector3(0.045, 0.06, 0.05))
		_mesh(talons, _cyl(0.014, 0.014, 0.1), jaune, Vector3(sx * 0.05, -0.08, 0.0))
		for k in range(3):
			var a2: float = (float(k) - 1.0) * 0.45
			_mesh(talons, _cyl(0.008, 0.002, 0.06), noir, Vector3(sx * 0.05 + sin(a2) * 0.03, -0.13, 0.03 * cos(a2)), Vector3.ONE, Vector3(PI * 0.6, a2, 0))


## L'axolotl géant : rose pâle et un peu luisant, une tête large au sourire tranquille, trois
## branchies plumeuses de chaque côté, une longue nageoire sur la queue.
func _build_axolotl() -> void:
	var rose := _vmat(Color(0.96, 0.68, 0.7), 0.36)
	var branchie := _mat(Color(0.88, 0.3, 0.42), 0.5)
	var noir := _mat(Color(0.03, 0.02, 0.03), 0.1)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	var sp: Array = []
	var rr: Array = []
	for i in range(10):
		var u: float = float(i) / 9.0
		sp.append(Vector3(0, 0.1, lerpf(-0.2, 0.22, u)))
		rr.append(lerpf(0.065, 0.085, sin(u * PI)))
	var lisse := func(s: float, ang: float) -> float: return 0.9 + 0.12 * (0.5 - 0.5 * sin(ang)) + 0.03 * sin(s * 30.0 + ang * 4.0)
	_put(body, _tube_fn("axolotl:corps", sp, rr, 14, 0.78, lisse), rose)
	_mesh(body, _unit_sphere(), rose, Vector3(0, 0.15, 0.0), Vector3(0.006, 0.03, 0.17))
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.11, 0.27)
	body.add_child(head)
	_pivots["tete"] = head
	_mesh(head, _unit_sphere(), rose, Vector3(0, 0.0, 0.03), Vector3(0.11, 0.065, 0.1))
	var smile: Array = [Vector3(-0.075, -0.022, 0.06), Vector3(0, -0.03, 0.125), Vector3(0.075, -0.022, 0.06)]
	_put(head, _tube_fn("axolotl:sourire", smile, [0.004, 0.004, 0.004], 5, 1.0, Callable()), noir)
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), noir, Vector3(sx * 0.07, 0.03, 0.08), Vector3.ONE * 0.012)
		for g in range(3):
			var gill := Node3D.new()
			gill.position = Vector3(sx * 0.09, 0.0 + float(g) * 0.028, -0.01)
			head.add_child(gill)
			var gp: Array = [Vector3.ZERO, Vector3(sx * 0.05, 0.03 + float(g) * 0.012, -0.03), Vector3(sx * 0.08, 0.05 + float(g) * 0.02, -0.08)]
			_put(gill, _tube_fn("axolotl:branchie%d%s" % [g, "g" if sx < 0.0 else "d"], gp, [0.01, 0.008, 0.004], 5, 1.0, Callable()), branchie)
			for f in range(5):
				var u2: float = 0.25 + float(f) * 0.16
				var q: Vector3 = (gp[1] as Vector3).lerp(gp[2], u2) if u2 > 0.5 else (gp[0] as Vector3).lerp(gp[1], u2 * 2.0)
				_mesh(gill, _unit_sphere(), branchie, q + Vector3(0, 0.012, 0), Vector3(0.004, 0.014, 0.005))
				_mesh(gill, _unit_sphere(), branchie, q - Vector3(0, 0.012, 0), Vector3(0.004, 0.014, 0.005))
			_gills.append([gill, sx, g])
	var tail := Node3D.new()
	tail.name = "Queue"
	tail.position = Vector3(0, 0.1, -0.2)
	body.add_child(tail)
	_pivots["queue"] = tail
	var tp: Array = []
	var tr: Array = []
	for i in range(8):
		var u: float = float(i) / 7.0
		tp.append(Vector3(0, 0.0, -u * 0.36))
		tr.append(lerpf(0.06, 0.008, u))
	_put(tail, _tube_fn("axolotl:queue", tp, tr, 10, 1.15, lisse), rose)
	_mesh(tail, _unit_sphere(), rose, Vector3(0, 0.005, -0.2), Vector3(0.006, 0.065, 0.2))
	for i in range(4):
		var sx2: float = -1.0 if i % 2 == 0 else 1.0
		var front: bool = i < 2
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * 0.07, 0.08, 0.14 if front else -0.12)
		body.add_child(leg)
		var lp: Array = [Vector3.ZERO, Vector3(sx2 * 0.06, -0.03, 0.02), Vector3(sx2 * 0.08, -0.075, 0.04)]
		_put(leg, _tube_fn("axolotl:patte%s" % ("g" if sx2 < 0.0 else "d"), lp, [0.02, 0.014, 0.01], 6, 1.0, Callable()), rose)
		for f in range(4):
			var a: float = (float(f) - 1.5) * 0.4
			_mesh(leg, _unit_sphere(), rose, (lp[2] as Vector3) + Vector3(sin(a) * 0.02, -0.004, cos(a) * 0.02), Vector3(0.005, 0.004, 0.012), Vector3(0, a, 0))
		_legs.append([leg, sx2, i])


# =================================================================== sons, alertes, butin

func _sound(what: String) -> void:
	if not SPECS135.has(kind):
		super._sound(what)
		return
	if manager == null or manager.main == null or not manager.main.has_method("sfx"):
		return
	var pair: Array = SOUNDS135.get(kind, ["monstre_menace", "monstre_mort"])
	var s: String = str(pair[0] if what == "menace" else pair[1])
	if s != "":
		manager.main.sfx(s, global_position + Vector3.UP * maxf(hit_height, 0.3))


func alert_text() -> String:
	if SPECS135.has(kind):
		return str(ALERTES135.get(kind, ""))
	return super.alert_text()


func loot(rng: RandomNumberGenerator) -> Array:
	if not SPECS135.has(kind):
		return super.loot(rng)
	var g: Array = []
	match kind:
		"singe_hurleur":
			g.append(["piece", rng.randi_range(1, 3)])
			if rng.randf() < 0.35:
				g.append(["noix_coco", 1])
		"mille_pattes":
			g.append(["piece", rng.randi_range(1, 3)])
			if rng.randf() < 0.08:
				g.append(["rubis", 1])
		"araignee_geante":
			g.append(["piece", rng.randi_range(2, 4)])
			if rng.randf() < 0.12:
				g.append(["eclat_cristal", 1])
		"crocodile":
			g.append(["piece", rng.randi_range(3, 6)])
			if rng.randf() < 0.3:
				g.append(["dent_croco", 1])
			if rng.randf() < 0.08:
				g.append(["piece_or", 1])
		"scarabee_geant":
			g.append(["piece", rng.randi_range(2, 4)])
			if rng.randf() < 0.15:
				g.append(["scarabee", 1])
		"chacal", "coyote":
			g.append(["piece", rng.randi_range(1, 3)])
		"jaguar_sauvage":
			g.append(["piece", rng.randi_range(4, 8)])
			if rng.randf() < 0.12:
				g.append(["piece_or", 1])
		"aigle_royal":
			g.append(["piece", rng.randi_range(2, 4)])
			if rng.randf() < 0.25:
				g.append(["plume_vent", 1])
	return g


# =================================================================== coups reçus, mort

func take_hit(damage: int, from_pos: Vector3) -> void:
	if not SPECS135.has(kind):
		super.take_hit(damage, from_pos)
		return
	if state == "mort":
		return
	if kind == "coati":
		# on ne lui fait pas de mal : il couine, lâche ce qu'il tient, et file
		_flash = 0.15
		_sound("menace")
		if butin != "" and manager.has_method("chapardeur_lache"):
			manager.chapardeur_lache(self)
		var away: Vector3 = global_position - from_pos
		away.y = 0.0
		_knock = (away.normalized() if away.length() > 0.01 else -facing) * 4.0
		state = "fuite"
		timer = 3.0
		return
	var st0: String = str(state)
	var t0: float = timer
	super.take_hit(damage, from_pos)
	if state == "mort":
		return
	match genre:
		"sauteur":
			if st0 == "saut":
				state = st0
				timer = t0
		"rouleur":
			_roll_v = 0.0
			_knock *= 2.2
		"rodeur":
			if st0 == "saut":
				state = st0
				timer = t0
			elif st0 == "armer":
				manager.release_token(self)
		"rapace":
			if st0 == "pique":
				manager.release_token(self)
		"amphibie":
			_sink = 0.0


func _reveal() -> void:
	var was: bool = _hidden
	super._reveal()
	if was and kind == "crocodile":
		_puff(global_position + Vector3(0, maxf(EAU - global_position.y, 0.0) + 0.1, 0) + facing * 0.6, 12, Color(0.75, 0.82, 0.8, 0.8), 0.15, 0.6, 0.8, 1.5, 4.0)


func _die() -> void:
	if not SPECS135.has(kind):
		super._die()
		return
	if genre in ["rodeur", "rapace", "meute"] and manager != null:
		manager.release_token(self)
	if kind == "scarabee_geant":
		var b: Node3D = _pivots.get("boule")
		if b != null:
			_puff(b.global_position, 14, Color(0.55, 0.45, 0.3, 0.9), 0.15, 0.6, 0.9, 0.8, 2.5)
			b.visible = false
	super._die()


func _death_tick(delta: float) -> void:
	if kind != "luciole":
		super._death_tick(delta)
		return
	# les lucioles s'éparpillent et s'éteignent
	timer += delta
	for e in _lucs:
		var nd: Node3D = e[0]
		nd.position += nd.position.normalized() * delta * 1.5
		(e[1] as StandardMaterial3D).emission_energy_multiplier = maxf(0.0, 4.0 * (1.0 - timer / 0.8))
	if _luc_light != null:
		_luc_light.light_energy = maxf(0.0, 0.4 * (1.0 - timer / 0.8))
	if timer > 0.9:
		set_physics_process(false)
		queue_free()


## Le singe lance un fruit (en cloche : on peut l'esquiver).
func _spit(target: Vector3) -> void:
	if kind != "singe_hurleur":
		super._spit(target)
		return
	throws += 1
	_throw_t = 0.35
	if manager != null and manager.has_method("spit"):
		manager.spit(global_position + facing * 0.3 + Vector3.UP * 0.95, target + Vector3.UP * 1.0, int(spec["degats"]), "fruit")
	_sound("menace")


# =================================================================== comportement

func _physics_process(delta: float) -> void:
	if not (genre in GENRES135):
		super._physics_process(delta)
		return
	if manager == null:
		return
	_clock += delta
	if _flash > 0.0:
		_flash -= delta
	_apply_flash()
	if state == "mort":
		_death_tick(delta)
		return
	if not bool(manager.active):
		_animate132(delta, 0.0)
		return
	_hit_cd -= delta
	var p: Vector3 = _player()
	var to_p: Vector3 = p - global_position
	var dy: float = absf(to_p.y)
	to_p.y = 0.0
	var dist: float = to_p.length()
	var dir_p: Vector3 = to_p / dist if dist > 0.01 else facing
	if state == "saut":
		_jump_tick(delta, p)
		_animate132(delta, 0.0)
		return
	timer -= delta
	var sp: float = float(spec["vitesse"])
	var vue: float = float(spec["vue"])
	var from_home: float = Vector2(global_position.x - home.x, global_position.z - home.z).length()
	var move := Vector3.ZERO
	match genre:
		"rodeur":
			move = _rodeur(delta, dist, dir_p, dy, p, sp, vue, from_home)
		"amphibie":
			move = _amphibie(delta, dist, dir_p, dy, sp, vue, from_home)
		"chapardeur":
			move = _chapardeur(delta, dist, dir_p, sp, vue)
	# on ne s'avance pas dans la mer (sauf le crocodile, qui y vit)
	if move.length() > 0.01 and genre != "amphibie":
		var ahead: Vector3 = global_position + move.normalized() * 1.2
		if _ground_at(ahead) < 0.15 and _ground_at(global_position) > _ground_at(ahead):
			move = -move * 0.3
			_wander_to = Vector3.INF
	if _knock.length() > 0.05:
		move += _knock
		_knock = _knock.move_toward(Vector3.ZERO, delta * 14.0)
	velocity.x = move.x
	velocity.z = move.z
	velocity.y = 0.0 if is_on_floor() else maxf(velocity.y - 18.0 * delta, -20.0)
	move_and_slide()
	rotation.y = atan2(facing.x, facing.z)
	_animate132(delta, Vector2(move.x, move.z).length())


## Le jaguar : il rôde en cercle autour du héros, se tasse… et bondit.
func _rodeur(delta: float, dist: float, dir_p: Vector3, dy: float, p: Vector3, sp: float, vue: float, from_home: float) -> Vector3:
	var move := Vector3.ZERO
	match state:
		"erre":
			move = _wander(delta, sp)
			if dist < vue and dy < 3.0:
				state = "rode"
				_stalk_t = randf_range(2.5, 4.5)
				var off: Vector3 = global_position - p
				_circle_a = atan2(off.z, off.x)
				manager.alert(self)
				_sound("menace")
		"rode":
			if dist > vue * 1.8 or from_home > float(spec["laisse"]):
				state = "retour"
			else:
				var ring: float = 7.0 + _flank * 0.8
				_circle_a += delta * sp * 0.45 / ring * (1.0 if _flank >= 0.0 else -1.0)
				var tgt: Vector3 = p + Vector3(cos(_circle_a), 0, sin(_circle_a)) * ring
				var to: Vector3 = tgt - global_position
				to.y = 0.0
				if to.length() > 0.3:
					move = to.normalized() * sp * (0.7 if to.length() > 1.5 else 0.35)
					var look: Vector3 = (to.normalized() * 0.65 + dir_p * 0.35).normalized()
					facing = facing.lerp(look, clampf(delta * 5.0, 0.0, 1.0)).normalized()
				_stalk_t -= delta
				if _stalk_t <= 0.0 and dist < 10.0 and manager.take_token(self):
					state = "armer"
					timer = float(spec["armer"])
					_sound("menace")
		"armer":
			facing = facing.lerp(dir_p, clampf(delta * 8.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				pounces += 1
				_start_jump(p, dist, dir_p)
		"souffle":
			if timer <= 0.0:
				manager.release_token(self)
				state = "rode"
				_stalk_t = randf_range(3.0, 5.0)
				var off2: Vector3 = global_position - p
				_circle_a = atan2(off2.z, off2.x)
		"recul":
			if timer <= 0.0:
				state = "rode"
				_stalk_t = randf_range(2.0, 3.5)
		"retour":
			var back: Vector3 = home - global_position
			back.y = 0.0
			if back.length() < 2.0:
				state = "erre"
			else:
				move = back.normalized() * sp * 0.7
				facing = facing.lerp(back.normalized(), clampf(delta * 5.0, 0.0, 1.0)).normalized()
			if dist < vue * 0.6:
				state = "rode"
				_stalk_t = randf_range(2.0, 4.0)
		_:
			state = "rode"
	return move


## Le crocodile : tapi sous l'eau, il jaillit, mord, puis retourne se cacher.
func _amphibie(delta: float, dist: float, dir_p: Vector3, dy: float, sp: float, vue: float, from_home: float) -> Vector3:
	var move := Vector3.ZERO
	match state:
		"cache":
			_sink = minf(_sink + delta * 0.8, 1.0)
			if dist < vue and dy < 2.5:
				facing = dir_p
				_reveal()
		"surgit":
			_sink = maxf(_sink - delta * 3.0, 0.0)
			move = dir_p * sp * 2.2
			facing = facing.lerp(dir_p, clampf(delta * 8.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "chasse"
		"chasse":
			_sink = maxf(_sink - delta * 3.0, 0.0)
			if from_home > float(spec["laisse"]) or dist > vue * 3.0:
				state = "retour"
			elif dist <= float(spec["portee"]):
				state = "armer"
				timer = float(spec["armer"])
				_sound("menace")
			else:
				move = dir_p * sp
				facing = facing.lerp(dir_p, clampf(delta * 5.0, 0.0, 1.0)).normalized()
		"armer":
			facing = facing.lerp(dir_p, clampf(delta * 6.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "frappe"
				timer = 0.25
				if dist <= float(spec["portee"]) + 0.4 and facing.dot(dir_p) > 0.4 and dy < 1.8:
					manager.hurt_player(int(spec["degats"]), global_position)
					landed_hits += 1
				if manager.main.has_method("sfx"):
					manager.main.sfx("touche_lourd", global_position + facing * 1.2)
		"frappe":
			if timer <= 0.0:
				state = "souffle"
				timer = float(spec["repos"])
		"souffle", "recul":
			if timer <= 0.0:
				state = "chasse"
		"retour":
			var back: Vector3 = home - global_position
			back.y = 0.0
			if back.length() < 1.5:
				state = "cache"
				_hidden = true
			else:
				move = back.normalized() * sp * 0.8
				facing = facing.lerp(back.normalized(), clampf(delta * 5.0, 0.0, 1.0)).normalized()
			if dist < vue * 0.7 and from_home < float(spec["laisse"]) * 0.8:
				state = "chasse"
		_:
			state = "chasse"
	return move


## Le coati : il vient chiper à manger, file avec ; frappé, il lâche tout.
func _chapardeur(delta: float, dist: float, dir_p: Vector3, sp: float, vue: float) -> Vector3:
	var move := Vector3.ZERO
	match state:
		"erre":
			move = _wander(delta, sp)
			if dist < vue and manager.has_method("peut_chaparder") and manager.peut_chaparder():
				state = "approche"
				timer = 9.0
				_sound("menace")
				manager.alert(self)
		"approche":
			move = dir_p * sp * 1.25
			facing = facing.lerp(dir_p, clampf(delta * 8.0, 0.0, 1.0)).normalized()
			if dist < 1.2:
				if manager.chapardeur_vole(self):
					steals += 1
					state = "emporte"
					timer = 7.0
				else:
					state = "fuite"
					timer = 2.5
			elif dist > vue * 1.6 or timer <= 0.0:
				state = "erre"
		"emporte":
			move = -dir_p * sp * 1.5
			facing = facing.lerp(-dir_p, clampf(delta * 8.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				manager.chapardeur_garde(self)
				home = global_position
				state = "erre"
		"fuite":
			move = -dir_p * sp * 1.4
			facing = facing.lerp(-dir_p, clampf(delta * 8.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "erre"
				home = global_position
		_:
			state = "erre"
	return move


# =================================================================== en vol : l'aigle, les lucioles

func _fly_tick(delta: float, p: Vector3, dist: float, dir_p: Vector3) -> void:
	match kind:
		"aigle_royal":
			_fly_aigle(delta, p, dist)
		"luciole":
			_fly_luciole(delta, p, dist)
		_:
			super._fly_tick(delta, p, dist, dir_p)


func _fly_aigle(delta: float, p: Vector3, dist: float) -> void:
	timer -= delta
	var target: Vector3
	var speed: float = float(spec["vitesse"])
	var rate: float = 1.6
	match state:
		"vol":
			_orbit_a += delta * 0.3
			var rr: float = 14.0 + _flank * 3.0
			target = _orbit_c + Vector3(cos(_orbit_a) * rr, 0, sin(_orbit_a) * rr)
			target.y = _ground_at(target) + _alt
			if dist < float(spec["vue"]):
				state = "chasse"
				timer = randf_range(2.5, 4.5)
				manager.alert(self)
				_sound("menace")
		"chasse":
			_orbit_a += delta * 0.7
			target = p + Vector3(cos(_orbit_a) * 9.0, 7.5 + sin(_clock * 0.8), sin(_orbit_a) * 9.0)
			if timer <= 0.0 and manager.take_token(self):
				state = "pique"
				timer = 2.4
				_sound("menace")
			if dist > float(spec["vue"]) * 1.8:
				state = "vol"
				_orbit_c = Vector3(global_position.x, 0.0, global_position.z)
		"pique":
			target = p + Vector3.UP * 1.1
			speed *= 2.3
			rate = 4.0
			if global_position.distance_to(target) < 1.1 and not has_meta("mordu"):
				set_meta("mordu", true)
				manager.hurt_player(int(spec["degats"]), global_position)
				landed_hits += 1
			if has_meta("mordu") or timer <= 0.0:
				if has_meta("mordu"):
					remove_meta("mordu")
				manager.release_token(self)
				state = "remonte"
				timer = 2.0
		_:
			var out: Vector3 = global_position - p
			out.y = 0.0
			out = out.normalized() if out.length() > 0.1 else Vector3.FORWARD
			target = global_position + out * 6.0 + Vector3.UP * 4.0
			if timer <= 0.0:
				state = "chasse"
				timer = randf_range(3.0, 5.0)
	var v: Vector3 = (target - global_position).limit_length(speed)
	velocity = velocity.lerp(v, clampf(delta * rate, 0.0, 1.0))
	global_position += velocity * delta
	var g: float = _ground_at(global_position)
	if global_position.y < g + 0.6:
		global_position.y = g + 0.6
	var hv := Vector3(velocity.x, 0, velocity.z)
	if hv.length() > 0.3:
		var nf: Vector3 = facing.lerp(hv.normalized(), clampf(delta * 3.0, 0.0, 1.0)).normalized()
		_visual.rotation.z = lerpf(_visual.rotation.z, clampf(facing.cross(nf).y * 25.0, -0.6, 0.6), clampf(delta * 3.0, 0.0, 1.0))
		facing = nf
	rotation.y = atan2(facing.x, facing.z)
	_visual.rotation.x = lerpf(_visual.rotation.x, clampf(velocity.y * 0.07, -0.9, 0.5), clampf(delta * 3.0, 0.0, 1.0))


func _fly_luciole(delta: float, p: Vector3, dist: float) -> void:
	_orbit_a += delta * 0.25
	var target: Vector3 = _orbit_c + Vector3(cos(_orbit_a) * 1.6, 0, sin(_orbit_a * 1.3) * 1.6)
	target.y = _ground_at(target) + _alt + sin(_clock * 0.7) * 0.25
	if dist < 2.6:
		# elles s'écartent doucement du héros
		var away: Vector3 = global_position - p
		away.y = 0.0
		away = away.normalized() if away.length() > 0.05 else Vector3.FORWARD
		target = global_position + away * 2.0
		target.y = _ground_at(target) + _alt
	var v: Vector3 = (target - global_position).limit_length(float(spec["vitesse"]))
	velocity = velocity.lerp(v, clampf(delta * 1.5, 0.0, 1.0))
	global_position += velocity * delta


# =================================================================== animation

func _animate132(delta: float, speed: float) -> void:
	if not SPECS135.has(kind):
		super._animate132(delta, speed)
		return
	var walk: float = clampf(speed / maxf(float(spec["vitesse"]), 0.1), 0.0, 2.2)
	var night: bool = manager != null and manager.has_method("night") and bool(manager.night())
	for m in _eye_glow:
		(m as StandardMaterial3D).emission_energy_multiplier = 3.0 if night else 0.4
	match kind:
		"chacal", "coyote", "coati":
			super._animate132(delta, speed)
			if kind == "coati":
				var tail: Node3D = _pivots.get("queue")
				if tail != null:
					tail.rotation.x = sin(_clock * 2.0) * 0.08
					tail.rotation.z = sin(_clock * 3.1) * 0.12
		"jaguar_sauvage":
			super._animate132(delta, speed)
			_anim_jaguar(delta)
		"singe_hurleur":
			super._animate132(delta, speed)
			_anim_singe(delta)
		"mille_pattes":
			_anim_mille_pattes(delta, walk)
		"araignee_geante":
			_anim_araignee(delta, walk)
		"luciole":
			_anim_lucioles()
		"crocodile":
			super._animate132(delta, speed)
			_anim_crocodile(delta, walk)
		"scarabee_geant":
			_anim_scarabee(delta, speed, walk)
		"aigle_royal":
			_anim_aigle()
		"axolotl":
			super._animate132(delta, speed)
			for e in _gills:
				var gl: Node3D = e[0]
				gl.rotation.y = sin(_clock * 2.2 + float(e[2]) * 0.8) * 0.18 * float(e[1])
				gl.rotation.z = sin(_clock * 1.7 + float(e[2])) * 0.12
			var tl: Node3D = _pivots.get("queue")
			if tl != null:
				tl.rotation.y = sin(_clock * (3.0 + walk * 4.0)) * (0.25 + walk * 0.2)


func _anim_jaguar(delta: float) -> void:
	# rôder : le corps bas, la tête basse ; se tasser avant le bond ; la queue qui fouette
	var low: float = 0.0
	if state == "rode":
		low = 0.35
	elif state == "armer":
		low = 0.7 + sin(_clock * 18.0) * 0.05
	var body: Node3D = _pivots.get("corps")
	if body != null:
		body.position.y = lerpf(body.position.y, -low * 0.16, clampf(delta * 6.0, 0.0, 1.0))
	var head: Node3D = _pivots.get("tete")
	if head != null:
		head.rotation.x = lerpf(head.rotation.x, low * 0.35, clampf(delta * 6.0, 0.0, 1.0))
	var tail: Node3D = _pivots.get("queue")
	if tail != null:
		tail.rotation.y = sin(_clock * (9.0 if state == "armer" else 2.2)) * (0.45 if state == "armer" else 0.25)


func _anim_singe(delta: float) -> void:
	_throw_t = maxf(_throw_t - delta, 0.0)
	var arm: Node3D = _pivots.get("bras")
	if arm != null:
		if state == "armer":
			_arm_x = lerpf(_arm_x, -2.4, clampf(delta * 10.0, 0.0, 1.0))
		elif _throw_t > 0.0:
			_arm_x = lerpf(-2.4, 0.6, 1.0 - _throw_t / 0.35)
		else:
			_arm_x = lerpf(_arm_x, arm.rotation.x, clampf(delta * 8.0, 0.0, 1.0))
		arm.rotation.x = _arm_x
	if _fruit != null:
		_fruit.visible = state == "armer"
	var jaw: Node3D = _pivots.get("machoire")
	if jaw != null:
		var howl: float = 0.5 if state in ["armer", "fuite"] else 0.0
		jaw.rotation.x = lerpf(jaw.rotation.x, howl, clampf(delta * 8.0, 0.0, 1.0))
	var tail: Node3D = _pivots.get("queue")
	if tail != null:
		tail.rotation.y = sin(_clock * 1.6) * 0.2


func _anim_mille_pattes(_delta: float, walk: float) -> void:
	var t: float = _clock
	var k: float = minf(walk, 1.5)
	for i in range(_segs135.size()):
		var e: Array = _segs135[i]
		var seg: Node3D = e[0]
		var ph: float = t * 9.0 - float(i) * 0.55
		seg.position.x = sin(ph) * 0.06 * k
		seg.rotation.y = cos(ph) * 0.35 * k
		for l in e[1]:
			var lp: Node3D = l[0]
			var sx: float = l[1]
			lp.rotation.y = sin(t * 18.0 * (0.4 + k) - float(i) * 0.9 + (PI if sx > 0.0 else 0.0)) * 0.5 * (0.25 + k)
	var head: Node3D = _pivots.get("tete")
	if head != null:
		var up: float = -0.45 if state == "armer" else (0.2 if state == "frappe" else 0.0)
		head.rotation.x = up


func _anim_araignee(delta: float, walk: float) -> void:
	var t: float = _clock
	var crouch: float = 0.0
	if state == "armer":
		crouch = smoothstep(0.0, 1.0, 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0))
	var body: Node3D = _pivots.get("corps")
	if body != null:
		body.position.y = lerpf(body.position.y, 0.34 - crouch * 0.12 + sin(t * 14.0) * 0.008 * minf(walk, 1.0), clampf(delta * 10.0, 0.0, 1.0))
	for e in _legs135:
		var leg: Node3D = e[0]
		var sx: float = e[1]
		var j: int = e[2]
		var group: float = 0.0 if ((j % 2 == 0) == (sx > 0.0)) else PI
		var ph: float = t * 11.0 * (0.4 + minf(walk, 1.4)) + group
		var w: float = minf(walk, 1.3)
		leg.rotation.y = float(e[3]) + sin(ph) * 0.28 * w
		leg.rotation.z = sx * (maxf(0.0, cos(ph)) * 0.22 * w + crouch * 0.25)
		if state == "saut":
			leg.rotation.z = sx * -0.25


func _anim_lucioles() -> void:
	var t: float = _clock
	var sum: float = 0.0
	for e in _lucs:
		var nd: Node3D = e[0]
		var ph: float = e[2]
		var r: float = e[3]
		var h: float = e[4]
		var sp: float = e[5]
		nd.position = Vector3(cos(t * sp * 0.7 + ph) * r, h + sin(t * sp * 1.3 + ph * 2.0) * 0.15, sin(t * sp * 0.9 + ph) * r * 0.8)
		var c: float = fmod(t * 0.55 * sp + ph, 1.0)
		var on: float = smoothstep(0.0, 0.08, c) * (1.0 - smoothstep(0.25, 0.4, c))
		var m: StandardMaterial3D = e[1]
		m.emission_energy_multiplier = 0.15 + 6.0 * on
		m.albedo_color = Color(0.85, 1.0, 0.35).darkened(0.75 * (1.0 - on))
		sum += on
	if _luc_light != null:
		_luc_light.light_energy = 0.12 + 0.4 * sum / maxf(float(_lucs.size()), 1.0)


func _anim_crocodile(delta: float, walk: float) -> void:
	var body: Node3D = _pivots.get("corps")
	if body != null:
		body.rotation.y = sin(_clock * 6.0) * 0.08 * minf(walk, 1.0)
	var tail: Node3D = _pivots.get("queue")
	if tail != null:
		tail.rotation.y = sin(_clock * (6.0 if walk > 0.1 else 1.2) + 0.8) * (0.3 * minf(walk, 1.0) + 0.06)
	var jaw: Node3D = _pivots.get("machoire")
	if jaw != null:
		var open: float = 0.0
		if state == "armer":
			open = 0.62
		elif state == "surgit":
			open = 0.4
		jaw.rotation.x = lerpf(jaw.rotation.x, open, clampf(delta * (30.0 if state == "frappe" else 8.0), 0.0, 1.0))
	# tapi : seuls les yeux et les narines dépassent de l'eau
	var lift: float = clampf((EAU + 0.02) - (global_position.y + 0.37), -0.6, 1.5)
	_visual.position.y = lift * _sink


func _anim_scarabee(delta: float, speed: float, walk: float) -> void:
	var b: Node3D = _pivots.get("boule")
	if b != null:
		b.rotation.x += speed * delta / 0.4
	var bug: Node3D = _pivots.get("corps")
	if bug != null:
		bug.position.y = 0.34 + absf(sin(_clock * 12.0)) * 0.012 * minf(walk, 1.0)
	for e in _legs135:
		var leg: Node3D = e[0]
		var sx: float = e[1]
		var pair: int = e[2]
		var ph: float = _clock * 13.0 + (0.0 if ((pair % 2 == 0) == (sx > 0.0)) else PI)
		leg.rotation.x = sin(ph) * 0.35 * minf(walk + 0.05, 1.0)
		leg.rotation.z = sx * maxf(0.0, cos(ph)) * 0.15 * minf(walk, 1.0)


func _anim_aigle() -> void:
	var t: float = _clock
	var flap: float = 0.0
	var fold: float = 0.0
	match state:
		"vol":
			flap = sin(t * 3.0) * 0.12 * (1.0 if fmod(t, 6.0) < 1.5 else 0.15)
		"chasse", "remonte", "recul":
			flap = sin(t * 4.2) * 0.5
		"pique":
			fold = 1.0
	for e in _wings:
		var wing: Node3D = e[0]
		var hand: Node3D = e[1]
		var sx: float = e[2]
		wing.rotation.z = sx * (flap + 0.12 * (1.0 - fold)) + sx * fold * 0.25
		wing.rotation.y = -sx * fold * 0.95
		hand.rotation.z = sx * (flap * 0.6 - fold * 0.3)
		hand.rotation.y = -sx * fold * 0.7
	var talons: Node3D = _pivots.get("serres")
	if talons != null:
		talons.rotation.x = -1.0 if state == "pique" else 0.9
	var tail: Node3D = _pivots.get("queue")
	if tail != null:
		tail.rotation.x = sin(t * 1.3) * 0.06
