extends "res://scripts/monstre_v36.gd"
## V132 : les bêtes sauvages des îles (faune_v132.gd les fait vivre loin des villages).
## Chaque espèce a son caractère :
##  - fuyard (crabe des sables) : il trottine de travers sur la plage et file quand on approche ;
##  - voleuse (mouette chapardeuse) : elle tourne au-dessus de la plage… et pique sur le héros
##    pour lui chiper à manger. Un coup pendant qu'elle s'enfuit : elle lâche son butin.
##    (sans danger : on ne peut pas lui faire de mal, elle s'envole en criant) ;
##  - chargeur (sanglier, bouc des roches) : il gratte le sol, baisse la tête… et fonce tout
##    droit. On l'esquive au dernier moment, on le frappe pendant qu'il reprend son souffle.
##    Le bouc ne défend que son coin de montagne ;
##  - embuscade (ronceux des fourrés) : un buisson épineux de plus… qui se lève quand on passe ;
##  - meute (loups, la nuit) : ils tournent autour du héros et bondissent chacun à leur tour ;
##  - tireur (salamandre de braise) : elle crache des boules de feu de loin et file si on
##    l'approche ;
##  - volant (chauves-souris des cendres, la nuit) : elles voltigent et plongent pour mordre.
## Les corps sont des volumes lissés (tubes le long de la colonne, pattes articulées), ombrés
## plus sombre sur le dos, plus clair sous le ventre.

const Armes132 := preload("res://scripts/armes_v129.gd")

const SPECS132 := {
	"crabe_plage": {"pv": 3, "vitesse": 2.8, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 5.5, "laisse": 40.0,
		"rayon": 0.35, "haut": 0.25, "nom": "Crabe des sables", "genre": "fuyard"},
	"mouette": {"pv": 99, "vitesse": 7.0, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 40.0, "laisse": 80.0,
		"rayon": 0.45, "haut": 0.2, "nom": "Mouette chapardeuse", "genre": "voleuse", "vol": true},
	"sanglier": {"pv": 22, "vitesse": 2.4, "degats": 2, "portee": 1.7, "armer": 0.9, "repos": 1.8, "vue": 10.0, "laisse": 28.0,
		"rayon": 0.65, "haut": 0.75, "nom": "Sanglier des bois", "genre": "chargeur", "charge": 8.5},
	"ronceux_sauvage": {"pv": 16, "vitesse": 1.9, "degats": 1, "portee": 1.6, "armer": 0.55, "repos": 1.3, "vue": 3.6, "laisse": 11.0,
		"rayon": 0.55, "haut": 1.0, "nom": "Ronceux des fourrés", "genre": "embuscade"},
	"loup_bois": {"pv": 12, "vitesse": 4.6, "degats": 1, "portee": 1.8, "armer": 0.45, "repos": 1.2, "vue": 20.0, "laisse": 50.0,
		"rayon": 0.55, "haut": 0.8, "nom": "Loup du Bois-Doré", "genre": "meute"},
	"salamandre": {"pv": 10, "vitesse": 3.8, "degats": 1, "portee": 9.5, "armer": 0.75, "repos": 2.3, "vue": 15.0, "laisse": 32.0,
		"rayon": 0.5, "haut": 0.35, "nom": "Salamandre de braise", "genre": "tireur"},
	"bouc": {"pv": 26, "vitesse": 2.2, "degats": 2, "portee": 1.7, "armer": 1.0, "repos": 1.8, "vue": 7.5, "laisse": 18.0,
		"rayon": 0.65, "haut": 0.95, "nom": "Bouc des roches", "genre": "chargeur", "charge": 9.0, "territoire": true},
	"chauve_souris_mont": {"pv": 4, "vitesse": 5.0, "degats": 1, "portee": 1.3, "armer": 0.4, "repos": 1.5, "vue": 16.0, "laisse": 45.0,
		"rayon": 0.4, "haut": 0.2, "nom": "Chauve-souris des cendres", "genre": "volant", "vol": true},
}
const SOUNDS132 := {
	"crabe_plage": ["crabe_menace", "crabe_mort"], "mouette": ["mouette_cri", "mouette_cri"],
	"sanglier": ["sanglier_grogne", "sanglier_grogne"], "ronceux_sauvage": ["ronce_menace", "plante_mort"],
	"loup_bois": ["loup_menace", "loup_hurle"], "salamandre": ["serpent_menace", "salamandre_crache"],
	"bouc": ["bouc_belement", "bouc_belement"], "chauve_souris_mont": ["chauve_souris_cri", "chauve_souris_cri"],
}
const ALERTES := {
	"sanglier": "Un sanglier ! Quand il gratte le sol, il va charger tout droit : écarte-toi au dernier moment (roulade), puis frappe-le pendant qu'il reprend son souffle.",
	"ronceux_sauvage": "Un buisson qui se lève… un ronceux ! Ils dorment dans les fourrés : méfie-toi des buissons trop épineux.",
	"loup_bois": "Des loups ! Ils chassent en meute et tournent autour de toi : garde-les devant toi, et pare quand l'un d'eux bondit.",
	"salamandre": "Une salamandre de braise ! Elle crache du feu de loin et file quand on l'approche : esquive ses tirs, puis cours-lui après.",
	"bouc": "Un bouc des roches ! Il défend son coin de montagne : s'il baisse la tête, il va foncer. Laisse-le tranquille… ou esquive, puis frappe.",
	"chauve_souris_mont": "Des chauves-souris des cendres ! Elles plongent pour mordre : frappe-les quand elles descendent.",
}

static var _meshes132: Dictionary = {}

var genre: String = ""
var vol: bool = false
var peaceful: bool = false
var _pivots: Dictionary = {}          # "tete", "queue", "aileG", "aileD"…
var _wander_to: Vector3 = Vector3.INF
var _wander_t: float = 0.0
var _graze: float = 0.0
var _charge_t: float = 0.0
var _charge_hit: bool = false
var _flank: float = 0.0
var _alt: float = 12.0
var _orbit_a: float = 0.0
var _orbit_c: Vector3 = Vector3.ZERO
var butin: String = ""               # mouette : l'objet chipé
var _steal_t: float = 0.0
var _hidden: bool = false
var _rise: float = 0.0
var _embers: Array = []
var _eye_mats: Array = []
var _base_scale: Vector3 = Vector3.ONE


func is_hittable() -> bool:
	return state != "mort"


func setup(m: Node, k: String, at: Vector3) -> void:
	manager = m
	kind = k
	spec = SPECS132[k]
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
	match k:
		"crabe_plage":
			var b := BoxShape3D.new()
			b.size = Vector3(0.5, 0.3, 0.4)
			cs.shape = b
			cs.position.y = 0.16
		"mouette", "chauve_souris_mont":
			var s := SphereShape3D.new()
			s.radius = 0.3
			cs.shape = s
		"salamandre":
			var b2 := BoxShape3D.new()
			b2.size = Vector3(0.5, 0.35, 1.3)
			cs.shape = b2
			cs.position.y = 0.2
		"ronceux_sauvage":
			var c := CapsuleShape3D.new()
			c.radius = 0.45
			c.height = 1.4
			cs.shape = c
			cs.position.y = 0.7
		_:
			var b3 := BoxShape3D.new()
			b3.size = Vector3(0.7, 0.9, 1.5)
			cs.shape = b3
			cs.position.y = 0.55
	add_child(cs)
	_visual = Node3D.new()
	add_child(_visual)
	match k:
		"crabe_plage":
			_build_crab()
			_visual.scale = Vector3.ONE * 0.5
		"ronceux_sauvage":
			_build_bramble()
			_hidden = true
			state = "cache"
		"sanglier":
			_build_quadrupede({"long": 1.1, "haut": 0.62, "rayon": 0.33, "dos": Color(0.25, 0.18, 0.13), "tete": 0.5, "museau": 0.32,
				"defenses": true, "queue": 0.25, "patte": 0.07, "poil": 0.95, "oreilles": 0.12, "bosse": 0.18})
		"bouc":
			_build_quadrupede({"long": 1.0, "haut": 0.78, "rayon": 0.27, "dos": Color(0.82, 0.78, 0.7), "tete": 0.42, "museau": 0.24,
				"cornes": true, "barbe": true, "queue": 0.14, "patte": 0.055, "poil": 0.9, "oreilles": 0.13, "bosse": 0.05})
		"loup_bois":
			_build_quadrupede({"long": 1.15, "haut": 0.72, "rayon": 0.24, "dos": Color(0.42, 0.4, 0.38), "tete": 0.5, "museau": 0.3,
				"queue": 0.6, "patte": 0.05, "poil": 0.92, "oreilles": 0.16, "bosse": 0.04, "yeux": Color(1.0, 0.8, 0.3)})
		"salamandre":
			_build_salamandre()
		"mouette":
			_build_oiseau(false)
		"chauve_souris_mont":
			_build_oiseau(true)
	add_to_group("cibles_v28")
	add_to_group("faune_v132")
	global_position = at
	facing = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	_flank = randf_range(-1.0, 1.0)
	_wander_t = randf_range(0.5, 3.0)
	if vol:
		_alt = randf_range(10.0, 16.0) if kind == "mouette" else randf_range(2.2, 3.5)
		_orbit_c = at
		_orbit_a = randf() * TAU
		state = "vol"
	elif state != "cache":
		state = "erre"
	_base_scale = _visual.scale
	if _hidden:
		_visual.scale = Vector3(1.0, 0.35, 1.0)
		_visual.position.y = -0.3


# =================================================================== modèles

func _shade_dos(s: float, ang: float) -> float:
	# plus sombre sur le dos (sin > 0), plus clair sous le ventre
	return 0.62 + 0.38 * (0.5 - 0.5 * sin(ang)) + 0.04 * sin(s * 31.0 + ang * 5.0)


func _tube_mesh(key: String, path: Array, radii: Array, segs: int, aplat: float, shade: bool) -> ArrayMesh:
	if _meshes132.has(key):
		return _meshes132[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	Armes132._add_tube(st, path, radii, segs, aplat, Transform3D.IDENTITY, Callable(self, "_shade_dos") if shade else Callable())
	var m: ArrayMesh = st.commit()
	_meshes132[key] = m
	return m


func _vmat(c: Color, rough: float) -> StandardMaterial3D:
	var m := _mat(c, rough)
	m.vertex_color_use_as_albedo = true
	return m


func _put(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


## Un quadrupède : corps lissé le long de la colonne, tête allongée, quatre pattes articulées
## (cuisse, jarret, sabot), queue ; défenses (sanglier), cornes et barbiche (bouc).
func _build_quadrupede(c: Dictionary) -> void:
	var L: float = c["long"]
	var H: float = c["haut"]
	var R: float = c["rayon"]
	var k: String = kind
	var fur := _vmat(c["dos"], float(c["poil"]))
	var dark := _mat((c["dos"] as Color).darkened(0.55), 0.6)
	var corne := _mat(Color(0.86, 0.82, 0.7), 0.35)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	# colonne : de la croupe au garrot, un peu cambrée ; le ventre plus épais
	var bosse: float = float(c.get("bosse", 0.1))
	var spine: Array = []
	var radii: Array = []
	for i in range(9):
		var u: float = float(i) / 8.0
		spine.append(Vector3(0, H + 0.06 * sin(u * PI) + bosse * smoothstep(0.55, 0.85, u), lerpf(-L * 0.5, L * 0.5, u)))
		radii.append(R * (0.78 + 0.32 * sin(u * PI * 0.95 + 0.1)) * (1.0 + bosse * 0.8 * smoothstep(0.6, 0.9, u)))
	_put(body, _tube_mesh(k + ":corps", spine, radii, 14, 1.18, true), fur)
	# cou et tête
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, H + 0.08 + bosse * 0.6, L * 0.5)
	body.add_child(head)
	_pivots["tete"] = head
	var hl: float = c["tete"]
	var mz: float = c["museau"]
	var hp_path: Array = [Vector3(0, 0.0, -0.1), Vector3(0, 0.04, hl * 0.35), Vector3(0, -0.04, hl * 0.7), Vector3(0, -0.1, hl * 0.7 + mz)]
	var hr: Array = [R * 0.85, R * 0.75, R * 0.55, R * (0.42 if k != "loup_bois" else 0.22)]
	if k == "bouc":
		hr = [R * 0.72, R * 0.6, R * 0.42, R * 0.3]
	_put(head, _tube_mesh(k + ":tete", hp_path, hr, 12, 1.05, true), fur)
	# groin / truffe
	_mesh(head, _sphere(R * (0.38 if k == "sanglier" else 0.18)), dark, Vector3(0, -0.1, hl * 0.7 + mz + 0.01), Vector3(1.0, 0.85, 0.4))
	var eye := _mat(c.get("yeux", Color(0.05, 0.04, 0.03)), 0.15, 2.5 if c.has("yeux") else 0.0)
	_eye_mats.append(eye)
	for sx in [-1.0, 1.0]:
		_mesh(head, _sphere(0.035), eye, Vector3(sx * R * 0.6, 0.08, hl * 0.45))
		# oreilles
		var oh: float = float(c["oreilles"])
		var ear := _mesh(head, _cyl(0.0, oh * 0.45, oh), fur, Vector3(sx * R * 0.55, R * 0.75, hl * 0.12), Vector3(1.0, 1.0, 0.45), Vector3(-0.35, 0, sx * -0.45))
		ear.name = "Oreille"
		if bool(c.get("defenses", false)):
			var tp: Array = [Vector3(sx * R * 0.35, -0.12, hl * 0.62), Vector3(sx * R * 0.6, -0.08, hl * 0.72), Vector3(sx * R * 0.62, 0.06, hl * 0.78)]
			_put(head, _tube_mesh(k + ":defense%d" % int(sx), tp, [0.028, 0.02, 0.004], 6, 1.0, false), corne)
		if bool(c.get("cornes", false)):
			# de grandes cornes annelées qui montent et se recourbent vers l'arrière
			var cp: Array = []
			var cr: Array = []
			for i in range(14):
				var u: float = float(i) / 13.0
				var a: float = u * 2.3
				cp.append(Vector3(sx * (R * 0.3 + 0.03 + u * 0.08), R * 0.6 + sin(a) * 0.3, hl * 0.12 - (1.0 - cos(a)) * 0.3))
				cr.append(lerpf(0.05, 0.008, u) * (1.0 + 0.12 * sin(u * 60.0)))
			_put(head, _tube_mesh(k + ":corne%d" % int(sx), cp, cr, 8, 1.0, false), corne)
	if bool(c.get("barbe", false)):
		_mesh(head, _cyl(0.05, 0.0, 0.18), _mat((c["dos"] as Color).lightened(0.1), 0.95), Vector3(0, -0.24, hl * 0.62), Vector3.ONE, Vector3(0.2, 0, 0))
	# queue
	var tail := Node3D.new()
	tail.name = "Queue"
	tail.position = Vector3(0, H + 0.04, -L * 0.5)
	body.add_child(tail)
	_pivots["queue"] = tail
	var ql: float = c["queue"]
	_put(tail, _tube_mesh(k + ":queue", [Vector3(0, 0, 0), Vector3(0, -ql * 0.35, -ql * 0.45), Vector3(0, -ql * 0.9, -ql * 0.65)], [R * 0.25, R * (0.32 if k == "loup_bois" else 0.12), 0.01], 8, 1.0, true), fur)
	# pattes : cuisse, jarret, sabot (pivot à l'épaule / la hanche)
	var pw: float = c["patte"]
	for i in range(4):
		var sx2: float = -1.0 if i % 2 == 0 else 1.0
		var front: bool = i < 2
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * R * 0.55, H - R * 0.1, (L * 0.36 if front else -L * 0.36))
		body.add_child(leg)
		var lp: Array = [Vector3(0, 0, 0), Vector3(0, -(H - R * 0.1) * 0.5, (0.02 if front else -0.06)), Vector3(0, -(H - R * 0.1) + 0.04, 0.0)]
		_put(leg, _tube_mesh(k + ":patte%d" % (0 if front else 1), lp, [pw * 1.8, pw * 1.05, pw * 0.9], 8, 1.0, true), fur)
		_mesh(leg, _sphere(pw * 1.05), dark, Vector3(0, -(H - R * 0.1) + 0.03, 0.02), Vector3(1.0, 0.6, 1.3))
		_legs.append([leg, sx2, i])


## Salamandre de braise : un lézard noir et trapu, aux taches de braise qui rougeoient, la gorge
## qui s'allume avant de cracher.
func _build_salamandre() -> void:
	var skin := _vmat(Color(0.13, 0.11, 0.1), 0.45)
	var braise := _mat(Color(1.0, 0.42, 0.08), 0.4, 2.6)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	var spine: Array = []
	var radii: Array = []
	for i in range(13):
		var u: float = float(i) / 12.0
		spine.append(Vector3(0, 0.22 + 0.04 * sin(u * PI), lerpf(-0.95, 0.55, u)))
		radii.append(lerpf(0.02, 0.17, smoothstep(0.0, 0.55, u)) * (1.0 - 0.45 * smoothstep(0.82, 1.0, u)))
	_put(body, _tube_mesh("salamandre:corps", spine, radii, 12, 0.75, true), skin)
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.25, 0.55)
	body.add_child(head)
	_pivots["tete"] = head
	_put(head, _tube_mesh("salamandre:tete", [Vector3(0, 0, -0.05), Vector3(0, 0.01, 0.12), Vector3(0, -0.01, 0.26)], [0.1, 0.11, 0.04], 10, 0.7, true), skin)
	var gorge := _mat(Color(1.0, 0.55, 0.1), 0.4, 0.6)
	_mesh(head, _sphere(0.07), gorge, Vector3(0, -0.06, 0.1), Vector3(1.0, 0.6, 1.4))
	_pivots["gorge"] = gorge
	for sx in [-1.0, 1.0]:
		var eye := _mat(Color(1.0, 0.85, 0.2), 0.1, 4.0)
		_eye_mats.append(eye)
		_mesh(head, _sphere(0.028), eye, Vector3(sx * 0.07, 0.05, 0.12))
	var rng := RandomNumberGenerator.new()
	rng.seed = 132
	for i in range(14):
		var u2: float = rng.randf_range(0.15, 0.9)
		var z: float = lerpf(-0.95, 0.55, u2)
		var r2: float = lerpf(0.02, 0.17, smoothstep(0.0, 0.55, u2))
		var sp := _mesh(body, _sphere(rng.randf_range(0.022, 0.045)), braise, Vector3(rng.randf_range(-0.6, 0.6) * r2, 0.22 + r2 * 0.62, z), Vector3(1.0, 0.45, 1.0))
		_embers.append(sp)
	for i in range(4):
		var sx2: float = -1.0 if i % 2 == 0 else 1.0
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * 0.12, 0.22, (0.32 if i < 2 else -0.22))
		body.add_child(leg)
		_put(leg, _tube_mesh("salamandre:patte", [Vector3(0, 0, 0), Vector3(0.12, 0.0, 0.0), Vector3(0.16, -0.18, 0.04)], [0.055, 0.045, 0.035], 7, 1.0, true), skin)
		_mesh(leg, _sphere(0.045), skin, Vector3(0.17, -0.19, 0.07), Vector3(1.2, 0.5, 1.4))
		leg.scale.x = sx2
		_legs.append([leg, sx2, i])
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.5, 0.15)
	l.light_energy = 0.5
	l.omni_range = 2.5
	l.position = Vector3(0, 0.5, 0)
	body.add_child(l)
	_pivots["lueur"] = l


## Mouette (ailes grises, bout des ailes noir, bec jaune) ou chauve-souris (ailes de peau).
func _build_oiseau(bat: bool) -> void:
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	var plume := _vmat(Color(0.95, 0.95, 0.94) if not bat else Color(0.18, 0.15, 0.14), 0.7)
	var aile_m := _mat(Color(0.62, 0.66, 0.7) if not bat else Color(0.24, 0.18, 0.17), 0.75)
	aile_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var noir := _mat(Color(0.08, 0.08, 0.09), 0.6)
	var key: String = "chauve" if bat else "mouette"
	var sc: float = 0.55 if bat else 1.0
	_put(body, _tube_mesh(key + ":corps", [Vector3(0, 0, -0.3 * sc), Vector3(0, 0.02, -0.05 * sc), Vector3(0, 0.03, 0.15 * sc), Vector3(0, 0.08, 0.27 * sc)],
		[0.02, 0.09 * sc, 0.085 * sc, 0.065 * sc], 10, 1.0, true), plume)
	if not bat:
		var bec := _mat(Color(1.0, 0.8, 0.15), 0.4)
		_mesh(body, _cyl(0.0, 0.022, 0.12), bec, Vector3(0, 0.08, 0.38), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		_mesh(body, _sphere(0.012), _mat(Color(0.85, 0.1, 0.05), 0.4), Vector3(0, 0.065, 0.37))
		var tail_st := _mesh(body, _cyl(0.0, 0.06, 0.16), aile_m, Vector3(0, 0.01, -0.36), Vector3(1.0, 1.0, 0.25), Vector3(-PI * 0.5, 0, 0))
		tail_st.name = "Queue"
	else:
		for sx in [-1.0, 1.0]:
			_mesh(body, _cyl(0.0, 0.025, 0.07), plume, Vector3(sx * 0.03, 0.12, 0.13), Vector3.ONE, Vector3(-0.3, 0, sx * -0.3))
	for sx in [-1.0, 1.0]:
		var eye := _mat(Color(0.05, 0.04, 0.03) if not bat else Color(1.0, 0.3, 0.2), 0.15, 0.0 if not bat else 3.0)
		_eye_mats.append(eye)
		_mesh(body, _sphere(0.014 if not bat else 0.012), eye, Vector3(sx * 0.04, 0.1 * (1.0 if not bat else 0.9), 0.27 * sc))
		var wing := Node3D.new()
		wing.position = Vector3(sx * 0.06 * sc, 0.04, 0.02)
		body.add_child(wing)
		_pivots["aile%d" % int(sx)] = wing
		var span: float = 0.62 if not bat else 0.38
		var fn := func(s: float, d: float) -> Vector3:
			var w: float = lerpf(0.22, 0.08, s) * (1.0 if not bat else 1.3)
			var back: float = (0.05 + 0.1 * s * s)
			var scal: float = 1.0 if not bat else (1.0 - 0.35 * sin(d * PI * 3.0) * s)
			return Vector3(s * span, 0.0, -back - d * w * scal + 0.06)
		var ep := func(_s: float, _d: float) -> float:
			return 0.012
		var te := func(s: float, _d: float) -> float:
			return 1.0 if bat or s < 0.78 else 0.25
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		Armes132._add_nappe(st, fn, ep, Vector3.UP, 8, 4, te)
		var wm: ArrayMesh = st.commit()
		var wmat: StandardMaterial3D = aile_m
		if not bat:
			wmat = _vmat(Color(0.62, 0.66, 0.7), 0.75)
			wmat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var wmi := _put(wing, wm, wmat)
		wmi.scale.x = sx
	if bat:
		_visual.scale = Vector3.ONE * 1.1


# =================================================================== sons, alertes, butin

func _sound(what: String) -> void:
	if manager == null or manager.main == null or not manager.main.has_method("sfx"):
		return
	var pair: Array = SOUNDS132.get(kind, ["monstre_menace", "monstre_mort"])
	manager.main.sfx(str(pair[0] if what == "menace" else pair[1]), global_position + Vector3.UP * hit_height)


func alert_text() -> String:
	return str(ALERTES.get(kind, ""))


func loot(rng: RandomNumberGenerator) -> Array:
	var g: Array = []
	match kind:
		"crabe_plage":
			if rng.randf() < 0.4:
				g.append(["piece", 1])
			if rng.randf() < 0.05:
				g.append(["perle", 1])
		"sanglier":
			g.append(["piece", rng.randi_range(2, 5)])
			if rng.randf() < 0.3:
				g.append(["champignon", 1])
			if rng.randf() < 0.08:
				g.append(["gland_dore", 1])
		"ronceux_sauvage":
			g.append(["piece", rng.randi_range(1, 4)])
			if rng.randf() < 0.35:
				g.append(["baies", rng.randi_range(1, 2)])
		"loup_bois":
			g.append(["piece", rng.randi_range(1, 3)])
		"salamandre":
			g.append(["piece", rng.randi_range(2, 4)])
			if rng.randf() < 0.35:
				g.append(["champignon_braise", 1])
			elif rng.randf() < 0.25:
				g.append(["obsidienne", 1])
			if rng.randf() < 0.06:
				g.append(["coeur_magma", 1])
		"bouc":
			g.append(["piece", rng.randi_range(3, 6)])
			if rng.randf() < 0.25:
				g.append(["minerai_fer", 1])
		"chauve_souris_mont":
			if rng.randf() < 0.6:
				g.append(["piece", rng.randi_range(1, 2)])
	return g


# =================================================================== coups reçus

func take_hit(damage: int, from_pos: Vector3) -> void:
	if state == "mort":
		return
	if kind == "mouette":
		# on ne lui fait pas de mal : elle crie, lâche ce qu'elle tient, et file
		_flash = 0.15
		_sound("menace")
		if butin != "":
			manager.mouette_lache(self)
		state = "fuite_air"
		timer = 3.0
		return
	if _hidden:
		_reveal()
	super.take_hit(damage, from_pos)
	if state == "mort":
		return
	# un chargeur touché pendant sa charge ne s'arrête pas ; ailleurs il recule un peu
	if genre == "chargeur" and _charge_t > 0.0:
		state = "charge"
	elif genre == "fuyard":
		state = "fuite"
		timer = 2.5
	elif genre == "tireur":
		state = "fuite"
		timer = 1.6


func _reveal() -> void:
	if not _hidden:
		return
	_hidden = false
	state = "surgit"
	timer = 0.55
	_sound("menace")
	manager.alert(self)


func _die() -> void:
	_sound("mort")
	state = "mort"
	timer = 0.0
	collision_layer = 0
	collision_mask = 0
	died.emit(self)


# =================================================================== comportement

func _ground_at(p: Vector3) -> float:
	var m: Node = manager.main
	return float(m._height_at(p.x, p.z)) if m != null and m.has_method("_height_at") else p.y


func _physics_process(delta: float) -> void:
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
		return
	var p: Vector3 = _player()
	var to_p: Vector3 = p - global_position
	var dy: float = absf(to_p.y)
	to_p.y = 0.0
	var dist: float = to_p.length()
	var dir_p: Vector3 = to_p / dist if dist > 0.01 else facing
	if vol:
		_fly_tick(delta, p, dist, dir_p)
		_animate132(delta, 1.0)
		return
	var move := Vector3.ZERO
	timer -= delta
	var sp: float = float(spec["vitesse"])
	var from_home: float = Vector2(global_position.x - home.x, global_position.z - home.z).length()
	match state:
		"cache":
			if dist < float(spec["vue"]) and dy < 2.5:
				_reveal()
		"surgit":
			_rise = 1.0 - clampf(timer / 0.55, 0.0, 1.0)
			_visual.scale = Vector3(1.0, lerpf(0.35, 1.0, _rise), 1.0)
			_visual.position.y = lerpf(-0.3, 0.0, _rise)
			if timer <= 0.0:
				state = "chasse"
		"erre":
			move = _wander(delta, sp)
			if not peaceful and dist < float(spec["vue"]) and dy < 3.0:
				state = "chasse" if genre != "chargeur" else "armer"
				timer = float(spec["armer"])
				_sound("menace")
				manager.alert(self)
			elif peaceful and dist < float(spec["vue"]):
				state = "fuite"
				timer = 2.0
		"fuite":
			var away: Vector3 = -dir_p
			move = away * sp * 1.4
			facing = facing.lerp(away, clampf(delta * 8.0, 0.0, 1.0)).normalized()
			if timer <= 0.0 and dist > float(spec["vue"]) * 1.2:
				state = "erre" if peaceful or genre != "tireur" else "chasse"
			elif timer <= 0.0 and genre == "tireur" and dist > 6.0:
				state = "chasse"
		"chasse":
			if dist > float(spec["vue"]) * 1.8 or from_home > float(spec["laisse"]) or dy > 4.0:
				state = "retour"
			else:
				match genre:
					"meute":
						move = _pack_move(dist, dir_p, p, sp)
					"tireur":
						move = _shooter_move(dist, dir_p, sp)
					"chargeur":
						state = "armer"
						timer = float(spec["armer"])
					_:
						if dist <= float(spec["portee"]):
							state = "armer"
							timer = float(spec["armer"])
							_sound("menace")
						else:
							move = dir_p * sp
				facing = facing.lerp(dir_p, clampf(delta * 8.0, 0.0, 1.0)).normalized()
		"armer":
			facing = facing.lerp(dir_p, clampf(delta * 6.0, 0.0, 1.0)).normalized()
			if bool(spec.get("territoire", false)) and dist > float(spec["vue"]) * 1.3:
				state = "erre"
			elif timer <= 0.0:
				match genre:
					"chargeur":
						state = "charge"
						_charge_t = 1.25
						_charge_hit = false
						_sound("menace")
					"tireur":
						_spit(p)
						state = "souffle"
						timer = float(spec["repos"])
					"meute":
						state = "frappe"
						timer = 0.28
						_knock = facing * 7.5
					_:
						state = "frappe"
						timer = 0.18
						_strike(dist, dir_p)
		"charge":
			_charge_t -= delta
			move = facing * float(spec.get("charge", 8.0))
			if not _charge_hit and dist < 1.5 and dy < 1.8:
				_charge_hit = true
				manager.hurt_player(int(spec["degats"]), global_position - facing * 2.0)
				_shove_player(facing * 7.0)
			# la charge s'arrête : passée, épuisée, ou contre un obstacle
			if _charge_t <= 0.0 or (get_slide_collision_count() > 0 and _charge_t < 1.05):
				_charge_t = 0.0
				state = "souffle"
				timer = float(spec["repos"])
				if manager.main.combat_v28 != null:
					manager.main.combat_v28.puff(global_position + facing * 0.8 + Vector3.UP * 0.3, Color(0.6, 0.55, 0.45))
		"frappe":
			if genre == "meute" and timer > 0.08 and dist < 1.6 and not has_meta("mordu"):
				set_meta("mordu", true)
				manager.hurt_player(int(spec["degats"]), global_position)
			if timer <= 0.0:
				if has_meta("mordu"):
					remove_meta("mordu")
				state = "souffle"
				timer = float(spec["repos"])
				if genre == "meute":
					manager.release_token(self)
		"souffle":
			if genre == "meute":
				move = -dir_p * sp * 0.45
			if timer <= 0.0:
				if bool(spec.get("territoire", false)) and dist > float(spec["vue"]):
					state = "erre"
				else:
					state = "chasse"
		"recul":
			if timer <= 0.0:
				state = "chasse"
		"retour":
			var back: Vector3 = home - global_position
			back.y = 0.0
			if back.length() < 2.0:
				state = "erre"
			else:
				move = back.normalized() * sp * 0.7
				facing = facing.lerp(back.normalized(), clampf(delta * 5.0, 0.0, 1.0)).normalized()
			if not peaceful and dist < float(spec["vue"]) * 0.6:
				state = "chasse"
	# on ne s'avance pas dans la mer
	if move.length() > 0.01:
		var ahead: Vector3 = global_position + move.normalized() * 1.2
		if _ground_at(ahead) < 0.15 and _ground_at(global_position) > _ground_at(ahead):
			move = -move * 0.3
			_wander_to = Vector3.INF
			if state == "charge":
				_charge_t = 0.0
	if _knock.length() > 0.05:
		move += _knock
		_knock = _knock.move_toward(Vector3.ZERO, delta * 14.0)
	velocity.x = move.x
	velocity.z = move.z
	velocity.y = 0.0 if is_on_floor() else maxf(velocity.y - 18.0 * delta, -20.0)
	move_and_slide()
	rotation.y = atan2(facing.x, facing.z)
	_animate132(delta, Vector2(move.x, move.z).length())


## Errer : un point au hasard près de chez soi, on y va au pas, on broute un peu.
func _wander(delta: float, sp: float) -> Vector3:
	_wander_t -= delta
	if _graze > 0.0:
		_graze -= delta
		return Vector3.ZERO
	if _wander_to == Vector3.INF or _wander_t <= 0.0:
		var a: float = randf() * TAU
		var r: float = randf_range(2.0, 9.0)
		_wander_to = home + Vector3(cos(a) * r, 0, sin(a) * r)
		_wander_t = randf_range(4.0, 9.0)
	var to: Vector3 = _wander_to - global_position
	to.y = 0.0
	if to.length() < 0.6:
		_wander_to = Vector3.INF
		_graze = randf_range(1.5, 4.0)
		return Vector3.ZERO
	var d: Vector3 = to.normalized()
	facing = facing.lerp(d, clampf(delta * 3.0, 0.0, 1.0)).normalized()
	return facing * sp * (0.35 if kind != "crabe_plage" else 0.6)


## Meute : chacun tourne autour du héros à sa place ; un seul bondit à la fois.
func _pack_move(dist: float, dir_p: Vector3, p: Vector3, sp: float) -> Vector3:
	if dist < 4.2 and manager.take_token(self):
		state = "armer"
		timer = float(spec["armer"])
		_sound("menace")
		return Vector3.ZERO
	var side: Vector3 = Vector3(-dir_p.z, 0, dir_p.x)
	var ring: float = 3.4 + _flank * 0.6
	var target: Vector3 = p - dir_p * ring + side * _flank * 2.6
	var to: Vector3 = target - global_position
	to.y = 0.0
	if dist < 3.0:
		return (-dir_p + side * signf(_flank + 0.01)).normalized() * sp * 0.6
	return to.normalized() * sp * (1.0 if to.length() > 1.5 else 0.4)


## Tireuse : à bonne distance on s'arrête et on crache ; trop près, on file.
func _shooter_move(dist: float, dir_p: Vector3, sp: float) -> Vector3:
	if dist < 4.5:
		state = "fuite"
		timer = 1.4
		return Vector3.ZERO
	if dist > float(spec["portee"]):
		return dir_p * sp * 0.8
	state = "armer"
	timer = float(spec["armer"])
	_sound("menace")
	return Vector3.ZERO


func _shove_player(v: Vector3) -> void:
	manager.shove(v)


## Une boule de braise qui vole en cloche vers le héros (on peut l'esquiver).
func _spit(target: Vector3) -> void:
	manager.spit(global_position + facing * 0.7 + Vector3.UP * 0.35, target + Vector3.UP * 1.0, int(spec["degats"]))
	_sound("mort")


# =================================================================== en vol

func _fly_tick(delta: float, p: Vector3, dist: float, dir_p: Vector3) -> void:
	timer -= delta
	var target: Vector3
	var speed: float = float(spec["vitesse"])
	match state:
		"vol":
			# des cercles au-dessus de chez soi
			_orbit_a += delta * speed / maxf(6.0 + _flank * 3.0, 3.0) * (0.6 if kind == "mouette" else 1.2)
			var rr: float = (11.0 + _flank * 4.0) if kind == "mouette" else (3.0 + _flank)
			target = _orbit_c + Vector3(cos(_orbit_a) * rr, 0, sin(_orbit_a) * rr)
			target.y = _ground_at(target) + _alt + (sin(_clock * 1.3) * 0.8 if kind == "mouette" else sin(_clock * 6.0) * 0.4)
			if kind == "chauve_souris_mont" and dist < float(spec["vue"]):
				state = "chasse"
				manager.alert(self)
		"chasse":
			# la chauve-souris voltige autour de la tête du héros, puis plonge
			_orbit_a += delta * 3.2
			target = p + Vector3(cos(_orbit_a) * 2.6, 2.2 + sin(_clock * 7.0) * 0.4, sin(_orbit_a) * 2.6)
			if timer <= 0.0 and manager.take_token(self):
				state = "pique"
				timer = 0.7
				_sound("menace")
			if dist > float(spec["vue"]) * 1.8:
				state = "vol"
		"pique":
			target = p + Vector3.UP * (1.2 if kind == "chauve_souris_mont" else 1.7)
			speed *= 1.9
			var d3: float = global_position.distance_to(target)
			if kind == "chauve_souris_mont":
				if d3 < 0.9 and not has_meta("mordu"):
					set_meta("mordu", true)
					manager.hurt_player(int(spec["degats"]), global_position)
				if timer <= 0.0 or has_meta("mordu"):
					remove_meta("mordu")
					manager.release_token(self)
					state = "chasse"
					timer = randf_range(1.8, 3.5)
			else:
				if d3 < 1.3:
					manager.mouette_vole(self)
					state = "emporte"
					timer = 7.0
				elif timer <= 0.0:
					state = "vol"
		"emporte", "fuite_air":
			var out: Vector3 = (global_position - p)
			out.y = 0.0
			out = out.normalized() if out.length() > 0.1 else Vector3.FORWARD
			target = global_position + out * 6.0 + Vector3.UP * 2.5
			speed *= 0.85
			if timer <= 0.0:
				if state == "emporte" and butin != "":
					manager.mouette_garde(self)
				state = "vol"
				_orbit_c = global_position
				_orbit_c.y = 0.0
		_:
			# touchée (« recul ») : elle s'écarte un instant, puis reprend
			target = global_position + Vector3.UP * 0.5
			if timer <= 0.0:
				state = "chasse" if kind == "chauve_souris_mont" else "vol"
				timer = 1.5
	var to: Vector3 = target - global_position
	var v: Vector3 = to.limit_length(speed)
	velocity = velocity.lerp(v, clampf(delta * 3.0, 0.0, 1.0))
	global_position += velocity * delta
	var hv := Vector3(velocity.x, 0, velocity.z)
	if hv.length() > 0.3:
		facing = facing.lerp(hv.normalized(), clampf(delta * 5.0, 0.0, 1.0)).normalized()
	rotation.y = atan2(facing.x, facing.z)
	# on penche dans les virages, on pique du nez en descente
	_visual.rotation.z = lerpf(_visual.rotation.z, -clampf(facing.cross(hv.normalized() if hv.length() > 0.3 else facing).y * 2.0, -0.7, 0.7), delta * 3.0)
	_visual.rotation.x = lerpf(_visual.rotation.x, clampf(-velocity.y * 0.08, -0.6, 0.6), delta * 3.0)


# =================================================================== animation

func _animate132(delta: float, speed: float) -> void:
	var t: float = _clock
	if vol:
		var flap: float = 9.0 if kind == "mouette" else 16.0
		var amp: float = 0.75 if kind == "mouette" else 0.9
		var glide: float = 0.25 if (kind == "mouette" and state == "vol" and fmod(t, 4.0) > 2.2) else 1.0
		for sx in [-1, 1]:
			var w: Node3D = _pivots.get("aile%d" % sx)
			if w != null:
				w.rotation.z = sx * (sin(t * flap) * amp * glide + 0.15)
		return
	var walk: float = clampf(speed / maxf(float(spec["vitesse"]), 0.1), 0.0, 2.2)
	var freq: float = 7.0 + walk * 3.0
	for l in _legs:
		var leg: Node3D = l[0]
		var i: int = int(l[2])
		var phase: float = 0.0 if i in [0, 3] else PI
		if kind == "salamandre":
			leg.rotation.y = sin(t * freq * 1.3 + phase) * 0.6 * minf(walk, 1.0)
		elif kind == "crabe_plage":
			leg.rotation.z = sin(t * 18.0 + i) * 0.35 * minf(walk + 0.1, 1.0)
		else:
			leg.rotation.x = sin(t * freq + phase) * 0.55 * minf(walk, 1.2)
	var head: Node3D = _pivots.get("tete")
	if head != null:
		var low: float = 0.55 if (_graze > 0.0 and state == "erre") else 0.0
		if state == "armer" and genre == "chargeur":
			low = 0.35
			# il gratte le sol de la patte avant
			if not _legs.is_empty():
				(_legs[0][0] as Node3D).rotation.x = sin(t * 14.0) * 0.6
		head.rotation.x = lerpf(head.rotation.x, low + sin(t * 2.0) * 0.04, clampf(delta * 5.0, 0.0, 1.0))
	var tail: Node3D = _pivots.get("queue")
	if tail != null:
		tail.rotation.y = sin(t * (6.0 if state in ["chasse", "armer"] else 2.5)) * 0.35
	if kind == "salamandre":
		var body: Node3D = _pivots.get("corps")
		body.rotation.y = sin(t * freq * 0.65) * 0.12 * minf(walk, 1.0)
		var g: StandardMaterial3D = _pivots.get("gorge")
		if g != null:
			g.emission_energy_multiplier = 4.5 if state == "armer" else 0.6 + 0.3 * sin(t * 3.0)
		var lum: OmniLight3D = _pivots.get("lueur")
		if lum != null:
			lum.light_energy = 0.4 + 0.15 * sin(t * 5.0) + (0.8 if state == "armer" else 0.0)
	if genre == "chargeur" and state == "charge":
		var b2: Node3D = _pivots.get("corps")
		if b2 != null:
			b2.position.y = absf(sin(t * 16.0)) * 0.06


func _death_tick(delta: float) -> void:
	timer += delta
	if vol:
		global_position.y = maxf(global_position.y - delta * (2.0 + timer * 8.0), _ground_at(global_position) + 0.1)
	else:
		_visual.rotation.z = minf(timer * 3.5, PI * 0.5)
	if timer > 1.4:
		_visual.scale = _base_scale * clampf(1.0 - (timer - 1.4) / 0.8, 0.01, 1.0)
	if timer > 2.2:
		visible = false
		set_physics_process(false)
		queue_free()
