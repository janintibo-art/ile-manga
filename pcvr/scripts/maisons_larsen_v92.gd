extends RefCounted
## V92 : l'intérieur des yourtes de l'Île de Larsen (maisons_v81 construit la pièce, ici ronde : le
## plancher, le treillis de bois croisé contre le feutre, les perches du toit qui montent vers la
## couronne, la lumière du jour qui tombe par la couronne, la porte peinte), et ce qui s'y passe.
## Au Camp des Fleurs (style « yourte_fleurs ») :
##  - tisanes : une famille autour de la table basse, la théière qui fume (on repart avec une tisane) ;
##  - guitare : un musicien sur un pouf, qui chante (on chante avec lui) ;
##  - sieste_enfants : des enfants qui dorment sur des futons (chut ! on les borde) ;
##  - yoga : trois personnes qui respirent sur des tapis (on s'assoit avec elles) ;
##  - attrape_reves : l'atelier des attrape-rêves (on en reçoit un).
## À Rainville (style « yourte_rainville ») :
##  - fuites : le toit fuit, il faut placer les seaux sous les gouttes ;
##  - repete : deux jeunes qui répètent dans le salon (on monte le volume… larsen !) ;
##  - vinyles : une collection de disques et un tourne-disque (on choisit un disque) ;
##  - sieste_flanelle : quelqu'un dort sous trois couvertures à carreaux, avec son chat ;
##  - tricot : une grand-mère qui tricote des pulls à carreaux pour toute la rue.
## Et deux yourtes à part (leur porte donne l'histoire) : le Café Feedback (le comptoir, le juke-box,
## la fuite au-dessus de la table trois, le chat sur l'ampli, le chocolat chaud) et le Disquaire (les
## bacs à disques ; le disque rare, une fois la réconciliation faite).
## M : maisons_v81 ; M.R : la pièce (maisons_pieces_v81) ; S : maisons_scenes_v81 ; I : maisons_iles_v82.

const S = preload("res://scripts/maisons_scenes_v81.gd")
const I = preload("res://scripts/maisons_iles_v82.gd")
const Figurant = preload("res://scripts/pnj/figurant_v81.gd")
const Gens = preload("res://scripts/pnj/maisons_habitants_v81.gd")

const FLEURS := ["tisanes", "guitare", "sieste_enfants", "yoga", "attrape_reves"]
const RAIN := ["fuites", "repete", "vinyles", "sieste_flanelle", "tricot"]
const SPECIALES := ["cafe", "disquaire", "chez_larsen"]
const RI: float = 3.3                     # le rayon de la yourte, dedans
const HW: float = 1.8
const HC: float = 3.45

const CHANSONS := [
	"♪ Le soleil se lève sur les tournesols… et les tournesols se lèvent avec lui… ♪",
	"♪ Viens danser sous l'arbre à rubans, viens danser, il est encore temps… ♪",
	"♪ Paix sur la mer, paix sur la terre, et un peu de miel pour le dessert… ♪",
	"♪ Tous les chemins mènent au feu, et le feu mène aux étoiles… ♪",
]
const DISQUES := [
	["« Flaques en mineur », des Gouttières", "Une guitare qui grince, une voix qui murmure, et la pluie enregistrée dans le garage. Tout le monde dans la yourte ferme les yeux."],
	["« Tournesols, volume 2 », du Camp des Fleurs", "Des djembés, une flûte, des voix qui chantent en chœur. On a envie de se lever pour danser autour d'un feu."],
	["« Larsen ! », la compilation du festival d'il y a vingt ans", "Les deux villages ensemble, en direct de la Grande Scène. La foule chante. Ça siffle, ça crépite, c'est magnifique."],
	["« Bruits de pluie, face A et face B »", "Quarante minutes de pluie sur une tente. Rien d'autre. « C'est mon disque préféré pour m'endormir », dit le propriétaire."],
]


static func has(sc: String) -> bool:
	return sc in FLEURS or sc in RAIN or sc in SPECIALES


static func is_yourte(style: String) -> bool:
	return style.begins_with("yourte_")


static func pick(M) -> String:
	var ctx: Dictionary = M.ctx
	if str(ctx.get("owner", "")) != "" and ctx.get("owner_node", null) != null:
		return "chez_larsen"
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(ctx["id"]) + "yourte")
	var lst: Array = FLEURS if str(ctx["style"]) == "yourte_fleurs" else RAIN
	return str(lst[rng.randi() % lst.size()])


static func build(M, sc: String) -> void:
	match sc:
		"tisanes":
			_tisanes(M)
		"guitare":
			_guitare(M)
		"sieste_enfants":
			_sieste(M)
		"yoga":
			_yoga(M)
		"attrape_reves":
			_attrape_reves(M)
		"fuites":
			_fuites(M)
		"repete":
			_repete(M)
		"vinyles":
			_vinyles(M)
		"sieste_flanelle":
			_sieste_flanelle(M)
		"tricot":
			_tricot(M)
		"cafe":
			_cafe(M)
		"disquaire":
			_disquaire(M)
		"chez_larsen":
			_chez(M)


static func _r(M) -> RandomNumberGenerator:
	return M.ctx["rng"]


static func _pick(M, a: Array) -> Variant:
	return a[_r(M).randi() % a.size()]


static func _fleurs(M) -> bool:
	return str(M.ctx["style"]) == "yourte_fleurs"


# =================================================================== la yourte, dedans

## Les matériaux de la yourte (le feutre, la toile du toit, les perches peintes ou brutes).
static func _mats(M) -> void:
	var R = M.R
	var fl: bool = _fleurs(M)
	var noise := FastNoiseLite.new()
	noise.seed = 9201
	noise.frequency = 0.08
	noise.fractal_octaves = 4
	var nt := NoiseTexture2D.new()
	nt.width = 256
	nt.height = 256
	nt.seamless = true
	nt.noise = noise
	var felt := StandardMaterial3D.new()
	felt.albedo_texture = nt
	felt.albedo_color = Color(0.98, 0.92, 0.8) if fl else Color(0.5, 0.46, 0.42)
	felt.roughness = 1.0
	felt.uv1_triplanar = true
	felt.uv1_scale = Vector3.ONE * 1.6
	R._put("y_feutre", felt)
	var toile := StandardMaterial3D.new()
	toile.albedo_texture = nt
	toile.albedo_color = Color(0.96, 0.93, 0.86) if fl else Color(0.36, 0.34, 0.32)
	toile.roughness = 0.95
	toile.uv1_triplanar = true
	toile.uv1_scale = Vector3.ONE * 0.8
	R._put("y_toile", toile)
	var wt: Texture2D = load("res://assets/textures/doors/wood_plain.png")
	var perche := StandardMaterial3D.new()
	perche.albedo_texture = wt
	perche.albedo_color = Color(0.95, 0.45, 0.14) if fl else Color(0.55, 0.47, 0.38)
	perche.roughness = 0.6
	R._put("y_perche", perche)
	var treillis := StandardMaterial3D.new()
	treillis.albedo_texture = wt
	treillis.albedo_color = Color(0.92, 0.5, 0.2) if fl else Color(0.5, 0.42, 0.34)
	treillis.roughness = 0.65
	R._put("y_treillis", treillis)
	var ciel := StandardMaterial3D.new()
	var jour: bool = bool(R.day)
	ciel.albedo_color = Color(0.75, 0.88, 1.0) if jour else Color(0.06, 0.08, 0.16)
	ciel.emission_enabled = true
	ciel.emission = Color(0.75, 0.88, 1.0) if jour else Color(0.08, 0.1, 0.22)
	ciel.emission_energy_multiplier = 1.6 if jour else 0.4
	ciel.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	R._put("y_ciel", ciel)
	var porte := StandardMaterial3D.new()
	porte.albedo_texture = wt
	porte.albedo_color = Color(0.95, 0.5, 0.12) if fl else Color(0.12, 0.13, 0.12)
	porte.roughness = 0.55
	R._put("y_porte", porte)
	var plaid := StandardMaterial3D.new()
	plaid.albedo_texture = _plaid_tex(Color(0.55, 0.08, 0.07) if not fl else Color(0.85, 0.45, 0.15), Color(0.06, 0.06, 0.07) if not fl else Color(0.95, 0.85, 0.3))
	plaid.roughness = 0.95
	plaid.uv1_triplanar = true
	plaid.uv1_scale = Vector3.ONE * 1.5
	R._put("y_plaid", plaid)


## Une petite texture à carreaux (les couvertures, les coussins de Rainville ; les tissus du camp).
static func _plaid_tex(a: Color, b: Color) -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y in range(64):
		for x in range(64):
			var c: Color = a
			var bx: bool = (x % 32) >= 20 and (x % 32) < 28
			var by: bool = (y % 32) >= 20 and (y % 32) < 28
			if bx and by:
				c = b
			elif bx or by:
				c = a.lerp(b, 0.55)
			if (x % 32) == 10 or (y % 32) == 10:
				c = c.lerp(Color(0.95, 0.9, 0.75), 0.4)
			c = c.darkened(0.06 * float((x + y) % 2))
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## La pièce ronde (repère de la pièce : la porte en +z, au milieu).
static func shell(M) -> void:
	var R = M.R
	var k = R.kit
	_mats(M)
	var fl: bool = _fleurs(M)
	# le plancher (et sa collision), le grand tapis rond
	k.cyl(R.L(0, -0.2, 0), RI + 0.15, RI + 0.15, 0.2, "sol", 40, true, 1.2)
	k.col_box(R.L(0, -0.25, 0), Vector3(RI * 2.0 + 1.0, 0.5, RI * 2.0 + 1.0))
	k.cyl(R.L(0, 0.005, 0), 2.1, 2.1, 0.012, "tapis_0", 36, true, 4.2)
	# le mur de feutre (des panneaux), et le treillis de bois croisé devant
	var n: int = 40
	var door_a: float = PI * 0.5
	for i in range(n):
		var a: float = TAU * (i + 0.5) / n
		if absf(wrapf(a - door_a, -PI, PI)) < 0.17:
			continue
		var d := Vector3(cos(a), 0, sin(a))
		var w: float = TAU * (RI + 0.06) / n * 1.04
		k.box(Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), R.P(d.x * (RI + 0.06), HW * 0.5, d.z * (RI + 0.06))), Vector3(w, HW + 0.05, 0.05), "y_feutre", 1.0)
	for j in range(56):
		var a2: float = TAU * (j + 0.5) / 56
		if absf(wrapf(a2 - door_a, -PI, PI)) < 0.24:
			continue
		var d2 := Vector3(cos(a2), 0, sin(a2))
		var up := Vector3.UP
		var tang: Vector3 = d2.cross(up)
		for sgn in [-1.0, 1.0]:
			var axis: Vector3 = (up + tang * sgn * 0.9).normalized()
			var x_ax: Vector3 = axis.cross(d2).normalized()
			var bs := Basis(x_ax, axis, d2)
			k.box(Transform3D(bs, R.P(d2.x * (RI - 0.02), HW * 0.5, d2.z * (RI - 0.02))), Vector3(0.028, HW * 1.32, 0.018), "y_treillis", 1.0)
	# le haut du mur : une bande de bois, et une corde
	k.ring(R.L(0, HW - 0.04, 0), RI - 0.06, RI + 0.02, 0.08, "y_treillis", 40)
	# le toit : la toile vue d'en dessous (des pans), les perches peintes, la couronne et le ciel
	var m: int = 36
	for i2 in range(m):
		var a0: float = TAU * i2 / m
		var a1: float = TAU * (i2 + 1) / m
		var p0 := Vector3(cos(a0) * RI, HW, sin(a0) * RI)
		var p1 := Vector3(cos(a1) * RI, HW, sin(a1) * RI)
		var q0 := Vector3(cos(a0) * 0.66, HC, sin(a0) * 0.66)
		var q1 := Vector3(cos(a1) * 0.66, HC, sin(a1) * 0.66)
		var mid: Vector3 = (p0 + p1 + q0 + q1) * 0.25
		var down: Vector3 = ((p0 + p1) * 0.5 - (q0 + q1) * 0.5)
		var len: float = down.length()
		var yax: Vector3 = down.normalized()
		var xax: Vector3 = (p1 - p0).normalized()
		var zax: Vector3 = xax.cross(yax).normalized()
		if zax.y > 0.0:
			zax = -zax
		var wid: float = p0.distance_to(p1) * 1.06
		k.box(Transform3D(Basis(xax, yax, zax), R.P(mid.x, mid.y + 0.03, mid.z)), Vector3(wid, len, 0.03), "y_toile", 1.0)
	for i3 in range(48):
		var a3: float = TAU * (i3 + 0.5) / 48
		var lo := Vector3(cos(a3) * (RI - 0.04), HW - 0.02, sin(a3) * (RI - 0.04))
		var hi := Vector3(cos(a3) * 0.64, HC - 0.04, sin(a3) * 0.64)
		var dir: Vector3 = hi - lo
		var yax2: Vector3 = dir.normalized()
		var xax2: Vector3 = yax2.cross(Vector3(cos(a3), 0, sin(a3))).normalized()
		var zax2: Vector3 = xax2.cross(yax2)
		k.box(Transform3D(Basis(xax2, yax2, zax2), R.P((lo.x + hi.x) * 0.5, (lo.y + hi.y) * 0.5, (lo.z + hi.z) * 0.5)), Vector3(0.045, dir.length(), 0.045), "y_perche", 1.0)
	k.ring(R.L(0, HC - 0.08, 0), 0.55, 0.7, 0.16, "y_perche", 28)
	k.cyl(R.L(0, HC + 0.12, 0), 0.56, 0.56, 0.01, "y_ciel", 24, true)
	for c in range(4):
		k.box(R.L(0, HC + 0.02, 0, c * 45.0), Vector3(1.1, 0.04, 0.05), "y_perche", 1.0)
	k.col_box(R.L(0, HC + 0.4, 0), Vector3(RI * 2.0 + 1.0, 0.4, RI * 2.0 + 1.0))
	# les murs (collision) : un anneau de boîtes
	for i4 in range(20):
		var a4: float = TAU * (i4 + 0.5) / 20
		var d4 := Vector3(cos(a4), 0, sin(a4))
		k.col_box(Transform3D(Basis(Vector3.UP, atan2(d4.x, d4.z)), R.P(d4.x * (RI + 0.25), 1.2, d4.z * (RI + 0.25))), Vector3(RI * TAU / 20.0 * 1.15, 2.6, 0.4))
	# la porte, de l'intérieur (fermée), son cadre
	k.box(R.L(0, 0.8, RI - 0.02), Vector3(0.95, 1.6, 0.06), "y_porte", 1.0)
	for sx in [-0.55, 0.55]:
		k.box(R.L(sx, 0.85, RI - 0.04), Vector3(0.1, 1.75, 0.1), "y_perche", 1.0)
	k.box(R.L(0, 1.72, RI - 0.04), Vector3(1.2, 0.12, 0.1), "y_perche", 1.0)
	k.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), R.P(0.3, 0.85, RI - 0.1)), 0.03, 0.03, 0.06, "fer", 8)
	# au milieu : les deux colonnes peintes (au Camp des Fleurs) ou le poêle et son tuyau (à Rainville)
	if fl:
		for sx2 in [-0.42, 0.42]:
			k.cyl(R.L(sx2, 0, -0.1), 0.06, 0.055, HC - 0.06, "y_perche", 10, false)
			for b in range(4):
				k.ring(R.L(sx2, 0.5 + b * 0.75, -0.1), 0.055, 0.075, 0.05, "or", 10)
		R.reserve(0, -0.1, 1.2, 0.4)
	else:
		k.box(R.L(0, 0.35, -0.6), Vector3(0.55, 0.7, 0.5), "fer", 1.0)
		k.box(R.L(0, 0.72, -0.6), Vector3(0.6, 0.04, 0.56), "fer", 1.0)
		k.cyl(R.L(0.0, 0.74, -0.6), 0.075, 0.075, HC - 0.74, "fer", 10, false)
		R.fire(R.P(0, 0.25, -0.33), 0.35)
		R.reserve(0, -0.6, 0.9, 0.8)
	# la lumière : une lampe (une ampoule nue à Rainville, une lanterne de papier au camp), et le jour par la couronne
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.82, 0.6)
	lamp.light_energy = 1.3 if not R.day else 0.8
	lamp.omni_range = 7.0
	lamp.omni_attenuation = 0.9
	lamp.shadow_enabled = R.pc and not M.main.xr_active
	R.root.add_child(lamp)
	lamp.global_position = R.P(0.8, 2.2, 0.6)
	R.lights.append(lamp)
	if fl:
		k.cyl(R.L(0.8, 2.15, 0.6), 0.16, 0.22, 0.2, "papier", 12)
		k.cyl(R.L(0.8, 2.35, 0.6), 0.22, 0.12, 0.18, "papier", 12)
	else:
		k.cyl(R.L(0.8, 2.25, 0.6), 0.05, 0.05, 0.09, "lumiere", 8)
	k.cyl(R.L(0.8, 2.34, 0.6), 0.006, 0.006, HC - 2.34, "fer", 4, false)
	if R.day:
		var sun := SpotLight3D.new()
		sun.light_color = Color(0.9, 0.95, 1.0)
		sun.light_energy = 2.2
		sun.spot_range = 5.0
		sun.spot_angle = 32.0
		sun.shadow_enabled = false
		R.root.add_child(sun)
		sun.global_transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), R.P(0, HC + 0.05, 0))
		R.lights.append(sun)
	# le long du mur : un coffre peint, une étagère basse, des coussins (selon la maison)
	var r := _r(M)
	var bois: String = "bois" if not fl else "bois_clair"
	var ec: float = deg_to_rad(200.0 + r.randf_range(-20, 20))
	_mur_objet(M, ec, func(x, z, yaw): R.coffre_deco(x, z, yaw))
	var ea: float = deg_to_rad(330.0 + r.randf_range(-15, 15))
	_mur_objet(M, ea, func(x, z, yaw): R.etagere(x, z, yaw, 1.0, 1.4, true, 3))
	if not fl:
		# des guitares accrochées, une affiche de concert
		for g in range(2):
			var ag: float = deg_to_rad(25.0 + g * 14.0)
			var gp: Vector3 = R.P(cos(ag) * (RI - 0.2), 1.0, sin(ag) * (RI - 0.2))
			var gn: Node3D = I._node(M, gp, rad_to_deg(atan2(-cos(ag), -sin(ag))))
			I._part(gn, I._sph(0.17), Color(0.55, 0.12, 0.08) if g == 0 else Color(0.1, 0.1, 0.12), Vector3(0, -0.15, 0), Vector3(1.0, 1.2, 0.3))
			I._part(gn, BoxMesh.new(), Color(0.2, 0.14, 0.1), Vector3(0, 0.22, 0), Vector3(0.05, 0.6, 0.03))
	_bric_a_brac(M)


## Un meuble contre le mur, à l'angle a (radians ; la porte est à 90°).
static func _mur_objet(M, a: float, fn: Callable) -> void:
	var R = M.R
	var x: float = cos(a) * (RI - 0.55)
	var z: float = sin(a) * (RI - 0.55)
	var yaw: float = rad_to_deg(atan2(-cos(a), -sin(a)))
	fn.call(x, z, yaw)
	R.reserve(x, z, 1.1, 1.1)


## De petites choses de la vie : des plantes, des bougies, des coussins, des disques, des parapluies.
static func _bric_a_brac(M) -> void:
	var R = M.R
	var r := _r(M)
	var fl: bool = _fleurs(M)
	for k in range(3):
		var a: float = deg_to_rad(r.randf_range(120.0, 170.0) if k == 0 else r.randf_range(10.0, 60.0) + (0.0 if k == 1 else 250.0))
		var x: float = cos(a) * (RI - 0.45)
		var z: float = sin(a) * (RI - 0.45)
		if not R.is_free(x, z, 0.5, 0.5):
			continue
		if fl:
			R.plante(x, z, 0.0, r.randf_range(0.8, 1.2))
		else:
			# un parapluie ouvert qui sèche
			var n: Node3D = I._node(M, R.P(x, 0.0, z), r.randf_range(0, 360))
			var col: Color = [Color(0.12, 0.12, 0.13), Color(0.55, 0.1, 0.1), Color(0.95, 0.8, 0.12)][k % 3]
			I._part(n, I._cyl(0.02, 0.55, 0.3, 10), col, Vector3(0, 0.35, 0), Vector3.ONE, Vector3(25, 0, 0))
			I._part(n, I._cyl(0.01, 0.01, 0.8, 6), Color(0.1, 0.1, 0.1), Vector3(0, 0.3, 0.05), Vector3.ONE, Vector3(25, 0, 0))
		R.reserve(x, z, 0.6, 0.6)


# =================================================================== les gens

## Un habitant (le corps des gens des yourtes) ; extra : ce qu'on ajoute à sa fiche (un objet tenu,
## une couronne…). x, z, yaw (degrés) en repère de la pièce.
static func _gens(M, role: String, x: float, z: float, yaw: float, pose: String, extra: Dictionary = {}, nom: String = "") -> Node:
	var prof: Dictionary = Gens.pick(str(M.ctx["style"]), role, M.ctx["rng"])
	if nom == "":
		# (deux habitants d'une même yourte ne portent pas le même prénom)
		var pris: Array = []
		for p in M.people:
			if is_instance_valid(p) and p.get("npc") != null:
				pris.append(str(p.npc.display_name))
		for _essai in range(8):
			nom = Gens.prenom(str(M.ctx["style"]), role, M.ctx["rng"])
			if not (nom in pris):
				break
	prof["nom"] = nom
	for k in extra:
		prof[k] = extra[k]
	var face: Vector3 = Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0, 0, 1)
	var f: Node = Figurant.spawn(M.room, M.main, prof, M.R.P(x, 0.0, z), face, pose)
	M.people.append(f)
	return f


## Un pouf rond (on s'assoit dessus : 0,42 m).
static func _pouf(M, x: float, z: float, key: String = "tissu_orange") -> void:
	M.R.kit.cyl(M.R.L(x, 0, z), 0.26, 0.28, 0.4, key, 14, true)
	M.R.kit.cyl(M.R.L(x, 0.4, z), 0.24, 0.26, 0.03, key, 14, true)
	M.R.reserve(x, z, 0.6, 0.6)


## Une table basse ronde.
static func _table_basse(M, x: float, z: float, r: float = 0.55) -> void:
	M.R.kit.cyl(M.R.L(x, 0, z), 0.08, 0.1, 0.32, "bois", 8, true)
	M.R.kit.cyl(M.R.L(x, 0.32, z), r, r, 0.04, "bois_clair", 20, true)
	M.R.reserve(x, z, r * 2.0 + 0.2, r * 2.0 + 0.2)


static func _theiere(M, x: float, y: float, z: float) -> void:
	var R = M.R
	R.kit.cyl(R.L(x, y, z), 0.09, 0.11, 0.13, "terre_cuite", 12, true)
	R.kit.cyl(R.L(x, y + 0.13, z), 0.05, 0.09, 0.04, "terre_cuite", 12, true)
	R.kit.cyl(Transform3D(Basis(Vector3.BACK, -0.9), R.P(x + 0.1, y + 0.06, z)), 0.012, 0.018, 0.12, "terre_cuite", 6, true)
	for k in range(4):
		var a: float = TAU * k / 4.0 + 0.4
		R.kit.cyl(R.L(x + cos(a) * 0.3, y, z + sin(a) * 0.3), 0.035, 0.03, 0.07, "ceramique", 8, true)
	Decor_steam(M, R.P(x, y + 0.2, z))


static func Decor_steam(M, at: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.amount = 8
	p.lifetime = 2.2
	p.direction = Vector3.UP
	p.spread = 8.0
	p.initial_velocity_min = 0.08
	p.initial_velocity_max = 0.15
	p.gravity = Vector3.ZERO
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1, 1, 1, 0.18)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_texture = M.R.dot_texture()
	q.material = m
	p.mesh = q
	M.room.add_child(p)
	p.global_position = at


# =================================================================== le Camp des Fleurs

static func _tisanes(M) -> void:
	var R = M.R
	_table_basse(M, 0.6, -1.3)
	_theiere(M, 0.6, 0.36, -1.3)
	_pouf(M, -0.35, -1.6, "tissu_jaune")
	_pouf(M, 1.55, -1.6, "tissu_rose")
	_pouf(M, 0.6, -2.35, "tissu_turquoise")
	var mere: Node = _gens(M, "femme", -0.35, -1.6, 70, "assis", {"larsen": {"style": "hippie", "tenue": "robe_fleurs", "couronne": "marguerites"}})
	var enfant: Node = _gens(M, "enfant", 1.55, -1.6, -70, "assis", {"larsen": {"style": "hippie", "tenue": "enfant", "couronne": "coquelicots"}})
	_gens(M, "ancien", 0.6, -2.35, 0, "assis")
	mere.lines = ["Encore un peu de tisane ?", "Elle est à la camomille et au coquelicot.", "Doucement, c'est chaud."]
	enfant.lines = ["J'ai mis trois sucres !", "Hihi !", "C'est moi qui ai cueilli la menthe !"]
	var cb := func() -> void:
		M.talk(mere, "Entre, entre ! Ici, la porte est toujours ouverte et la théière toujours chaude. Tu veux une tisane ? Menthe du jardin de Lavande, camomille, et un pétale de coquelicot pour la couleur.",
			[{"id": "oui", "label": "Avec plaisir !"}, {"id": "camp", "label": "C'est comment, la vie au camp ?"}, {"id": "fermer", "label": "Merci, une autre fois."}], func(id):
			match id:
				"oui":
					if bool(M.state().get("tisane", false)):
						M.talk(mere, "Tu as déjà ta thermos, petit gourmand ! Reviens demain, j'en referai.", I._bye("D'accord !"), I._close(M))
						return
					M.state()["tisane"] = true
					mere.gesture("joie", 1.5)
					M.talk(mere, "Tiens : une pour maintenant, une pour la route. Et souviens-toi : une tisane, ça se boit lentement, en regardant quelque chose de beau.", I._bye("Merci !"), func(_i):
						M.give([["tisane_lune", 2]], "")
						M.close_talk())
				"camp":
					M.talk(mere, "La vie au camp ? On se lève avec le soleil, on jardine, on tisse, on joue de la musique, et le soir on se retrouve autour du feu. Le seul problème, c'est que Rainville nous manque un peu. Avant, on faisait la fête ensemble.", I._bye("Je comprends."), I._close(M))
				_:
					M.close_talk()
		, "de bonne humeur")
	M.talk_spot(mere, cb)
	M.ctx["entree"] = str(_pick(M, ["Ça sent la menthe et le miel. Autour d'une table basse, une famille boit des tisanes dans des tasses dépareillées.", "Une théière fume sur une petite table ronde. « Entre ! Il en reste ! »", "La lumière tombe de la couronne, toute ronde, sur des poufs de toutes les couleurs."]))


static func _guitare(M) -> void:
	var R = M.R
	_pouf(M, -0.9, -1.5, "tissu_violet")
	var musicien: Node = _gens(M, "homme", -0.9, -1.5, 35, "guitare", {"larsen": {"style": "hippie", "tenue": "tie_dye", "chapeau": "bandeau"}, "punk": {"objet": "guitare"}})
	_pouf(M, 0.9, -1.2, "tissu_orange")
	var amie: Node = _gens(M, "femme", 0.9, -1.2, -40, "assis", {"larsen": {"style": "hippie", "tenue": "robe_longue", "couronne": "tournesol"}})
	musicien.lines = CHANSONS
	musicien.line_every = Vector2(6.0, 10.0)
	amie.lines = ["Joli !", "Encore une !", "♪ La la la… ♪"]
	R.kit.cyl(R.L(0, 0.005, -0.5), 1.0, 1.0, 0.012, "tapis_1", 24, true, 2.0)
	var cb := func() -> void:
		M.talk(musicien, "Salut, l'ami ! Assieds-toi. Je cherche la suite de ma chanson. Ça parle d'un tournesol qui tombe amoureux de la lune… mais il ne la voit jamais, parce qu'il dort la nuit. Tu veux chanter le refrain avec moi ?",
			[{"id": "chanter", "label": "On chante !"}, {"id": "fermer", "label": "Je t'écoute seulement."}], func(id):
			if id == "chanter":
				musicien.gesture("joie", 2.0)
				amie.gesture("applaudir", 2.5)
				M.close_talk()
				M.say("Vous chantez tous les trois : « ♪ Tournesol, tournesol, la lune te regarde dormir… ♪ ». C'est un peu faux, mais c'est très joli.", 6.0)
				M.state()["chante"] = true
			else:
				M.close_talk()
				M.say("♪ … et le tournesol rêve d'elle, la tête penchée vers le ciel… ♪", 5.0)
		, "de bonne humeur")
	M.talk_spot(musicien, cb)
	M.ctx["entree"] = str(_pick(M, ["Quelqu'un gratte une guitare, assis sur un pouf violet. Une jeune femme fredonne avec lui.", "♪ La la la… ♪ Un musicien lève la tête et sourit : « Entre, il y a de la place pour une voix de plus ! »"]))


static func _sieste(M) -> void:
	var R = M.R
	for k in range(3):
		var a: float = deg_to_rad(200.0 + k * 50.0)
		var x: float = cos(a) * 2.0
		var z: float = sin(a) * 2.0
		var yaw: float = rad_to_deg(atan2(-cos(a), -sin(a)))
		R.kit.box(R.L(x, 0.08, z, yaw), Vector3(0.8, 0.16, 1.7), ["tissu_jaune", "tissu_rose", "tissu_turquoise"][k], 1.0)
		R.kit.box(R.L(x, 0.18, z, yaw) * Transform3D(Basis(), Vector3(0, 0, -0.65)), Vector3(0.5, 0.1, 0.3), "drap", 1.0)
		R.reserve(x, z, 1.3, 1.3)
		var kid: Node = _gens(M, "enfant", x, z, yaw, "dormir")
		var dir: Vector3 = (R.P(x, 0, z) - R.P(cos(a) * 2.9, 0, sin(a) * 2.9)).normalized()
		kid.lie(R.P(x, 0.1, z) + dir * 0.75, -dir)
	var garde: Node = _gens(M, "femme", 1.2, 0.8, -30, "tricot", {"larsen": {"style": "hippie", "tenue": "robe_longue"}})
	_pouf(M, 1.2, 0.8)
	garde.lines = ["Chuuut…", "Ils dorment enfin.", "Pas de bruit, s'il te plaît."]
	var cb := func() -> void:
		M.talk(garde, "(Elle chuchote.) Chut… Les petits font la sieste. Ils ont dansé autour de l'arbre à rubans toute la matinée. Tu veux bien m'aider à les border ? Doucement…",
			[{"id": "border", "label": "(Border les enfants, tout doucement)"}, {"id": "fermer", "label": "(Repartir sur la pointe des pieds)"}], func(id):
			if id == "border":
				M.close_talk()
				if bool(M.state().get("borde", false)):
					M.say("Ils sont déjà bien bordés. L'un d'eux sourit en dormant.", 4.0)
					return
				M.state()["borde"] = true
				M.say("Tu remontes les couvertures jusqu'aux mentons. Un des enfants murmure « Merci, Mamie Tournesol… » sans se réveiller. La maman te glisse quelques pièces : « Pour ta douceur. »", 6.0)
				M.give([["piece", 8]], "")
			else:
				M.close_talk()
		, "de bonne humeur")
	M.talk_spot(garde, cb)
	M.ctx["entree"] = "Chut… Trois enfants dorment sur des futons de toutes les couleurs. On n'entend que le vent sur la toile, et une maman qui tricote."


static func _yoga(M) -> void:
	var R = M.R
	var tapis: Array = [[-1.1, -1.2, 30.0], [1.1, -1.2, -30.0], [0.0, -2.0, 0.0]]
	var gens: Array = []
	for i in range(tapis.size()):
		var t: Array = tapis[i]
		R.kit.box(R.L(float(t[0]), 0.008, float(t[1]), float(t[2])), Vector3(0.65, 0.012, 1.8), ["tissu_violet", "tissu_vert", "tissu_turquoise"][i], 1.0)
		R.reserve(float(t[0]), float(t[1]), 0.9, 1.9)
		gens.append(_gens(M, ["femme", "homme", "ancien"][i], float(t[0]), float(t[1]) + 0.4, float(t[2]) + 180.0, "mediter" if i != 2 else "assis"))
	var maitre: Node = gens[2]
	(gens[0] as Node).lines = ["Ommm…", "Inspire…", "Expire…"]
	(gens[1] as Node).lines = ["Ommm…", "(Il éternue.) Pardon.", "Ommm…"]
	maitre.lines = ["Respirez…", "Sentez le soleil…", "Doucement…"]
	R.kit.box(R.L(0.0, 0.008, 1.2), Vector3(0.65, 0.012, 1.8), "tissu_jaune", 1.0)
	var cb := func() -> void:
		M.talk(maitre, "Bienvenue… Respire. Il reste un tapis, le jaune, près de la porte. Assieds-toi, ferme les yeux, et écoute le vent sur la toile. Tu veux essayer ?",
			[{"id": "oui", "label": "(S'asseoir et respirer)"}, {"id": "fermer", "label": "Une autre fois."}], func(id):
			M.close_talk()
			if id == "oui":
				M.say("Tu t'assois sur le tapis jaune. Inspire… expire… Le vent fait chanter la toile, quelqu'un rit tout bas, une mouche passe. Au bout d'un moment, tu te sens léger comme une plume.", 7.0)
				var hero: Node = M.main.get("hero_v28")
				if hero != null and hero.get("hp") != null and hero.get("HP_MAX") != null:
					hero.hp = int(hero.HP_MAX)
				M.state()["yoga"] = true
		, "de bonne humeur")
	M.talk_spot(maitre, cb)
	M.ctx["entree"] = "Trois personnes sont assises en silence sur des tapis de couleur. Une voix douce murmure : « Respirez… »"


static func _attrape_reves(M) -> void:
	var R = M.R
	R.table(0.4, -1.7, 0.0, 1.5, 0.75, 0.76, "")
	R.chaise(0.4, -1.0, 180.0)
	var artisan: Node = _gens(M, "femme", 0.4, -1.0, 180, "bricoler", {"larsen": {"style": "hippie", "tenue": "poncho", "couronne": "marguerites"}})
	# des attrape-rêves accrochés aux perches, qui tournent doucement
	for k in range(7):
		var a: float = TAU * k / 7.0 + 0.3
		var at: Vector3 = R.P(cos(a) * 1.8, 2.3 + 0.2 * sin(k), sin(a) * 1.8)
		var n: Node3D = I._node(M, at, rad_to_deg(a))
		var tm := TorusMesh.new()
		tm.inner_radius = 0.13
		tm.outer_radius = 0.15
		I._part(n, tm, Color(0.6, 0.4, 0.22), Vector3.ZERO, Vector3.ONE, Vector3(90, 0, 0))
		I._part(n, QuadMesh.new(), Color(0.95, 0.92, 0.85, 0.6), Vector3.ZERO, Vector3(0.24, 0.24, 1))
		for p in range(3):
			I._part(n, I._sph(0.02), [Color(0.9, 0.3, 0.4), Color(0.3, 0.6, 0.9), Color(0.95, 0.8, 0.2)][p], Vector3(-0.08 + p * 0.08, -0.22 - 0.05 * p, 0))
			I._part(n, BoxMesh.new(), Color(0.95, 0.95, 0.92), Vector3(-0.08 + p * 0.08, -0.3 - 0.05 * p, 0), Vector3(0.02, 0.1, 0.005))
		I._part(n, I._cyl(0.003, 0.003, HC - 2.3, 4), Color(0.4, 0.3, 0.2), Vector3(0, (HC - at.y + R.origin.y) * 0.5 + 0.15, 0))
	artisan.lines = ["Un fil, une perle, une plume…", "Celui-là attrape les cauchemars.", "Les beaux rêves passent par le trou du milieu."]
	var cb := func() -> void:
		M.talk(artisan, "Ce sont des attrape-rêves. Le filet attrape les mauvais rêves, et les beaux rêves glissent par le petit trou du milieu, le long des plumes, jusqu'à la personne qui dort. Tu en veux un ? Il est fait avec une corde de chanvre de Galet.",
			[{"id": "oui", "label": "Oh oui, merci !"}, {"id": "fermer", "label": "Ils sont très beaux."}], func(id):
			if id == "oui" and not bool(M.state().get("reves", false)):
				M.state()["reves"] = true
				artisan.gesture("joie", 1.5)
				M.talk(artisan, "Tiens. Accroche-le au-dessus de ton lit. Et si un jour tu fais un cauchemar, viens me le dire : je renforcerai le filet.", I._bye("Merci !"), func(_i):
					M.give([["attrape_reves", 1]], "")
					M.close_talk())
			elif id == "oui":
				M.talk(artisan, "Tu en as déjà un ! Un seul suffit : les mauvais rêves ont peur des attrape-rêves.", I._bye("D'accord."), I._close(M))
			else:
				M.close_talk()
		, "de bonne humeur")
	M.talk_spot(artisan, cb)
	M.ctx["entree"] = "Des cercles de bois tressés de fil tournent doucement au bout de leurs ficelles, avec des perles et des plumes. Une artisane noue un filet à la lumière de la couronne."


# =================================================================== Rainville

static func _fuites(M) -> void:
	var R = M.R
	var r := _r(M)
	var habitant: Node = _gens(M, "homme", -0.2, 1.4, 180, "bras_croises", {"larsen": {"style": "grunge", "tenue": "flanelle", "chapeau": "bonnet"}})
	habitant.lines = ["Ça goutte…", "Encore une fuite…", "Plic. Ploc. Plic."]
	R.canape(-1.6, -1.6, 50.0, "gris", 1.7)
	var gouttes: Array = [[1.2, -1.4], [-0.6, 0.2], [0.9, 0.6]]
	var faits: Array = [0]
	var seaux: Array = []
	for i in range(gouttes.size()):
		var g: Array = gouttes[i]
		var gp: Vector3 = R.P(float(g[0]), 0, float(g[1]))
		# la goutte qui tombe du toit, la flaque par terre
		var p := CPUParticles3D.new()
		p.amount = 3
		p.lifetime = 0.9
		p.direction = Vector3.DOWN
		p.spread = 0.0
		p.initial_velocity_min = 0.5
		p.initial_velocity_max = 0.6
		p.gravity = Vector3(0, -9.8, 0)
		var q := SphereMesh.new()
		q.radius = 0.018
		q.height = 0.05
		var mm := StandardMaterial3D.new()
		mm.albedo_color = Color(0.6, 0.75, 0.9, 0.7)
		mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mm.roughness = 0.05
		q.material = mm
		p.mesh = q
		M.room.add_child(p)
		p.global_position = gp + Vector3.UP * (HC - 0.6 - 0.3 * i)
		R.kit.cyl(R.L(float(g[0]), 0.004, float(g[1])), 0.32, 0.32, 0.004, "verre", 14, true)
		var seau: Node3D = I._node(M, R.P(-2.2 + i * 0.4, 0, 2.2), 0)
		I._part(seau, I._cyl(0.15, 0.12, 0.28, 12), [Color(0.6, 0.62, 0.65), Color(0.2, 0.35, 0.6), Color(0.65, 0.12, 0.1)][i], Vector3(0, 0.14, 0), Vector3.ONE, Vector3.ZERO, 0.0, 0.6)
		seaux.append(seau)
		var idx: int = i
		M.act(gp + Vector3.UP * 0.3, "E : placer un seau sous la goutte", func():
			var s: Node3D = seaux[idx]
			s.global_position = R.P(float(gouttes[idx][0]), 0, float(gouttes[idx][1]))
			M.main.sfx("plouf", s.global_position)
			faits[0] = int(faits[0]) + 1
			if int(faits[0]) >= 3 and not bool(M.state().get("seaux", false)):
				M.state()["seaux"] = true
				habitant.gesture("joie", 2.0)
				M.say("Plic… plic… plonc ! Les trois gouttes tombent dans les trois seaux, et ça fait presque une mélodie. « Génial ! Merci ! J'appellerai ça : Concerto pour toit qui fuit. » Il te donne quelques pièces.", 7.0)
				M.give([["piece", 10]], "")
			elif int(faits[0]) < 3:
				M.say("Plonc ! Un seau de placé. Encore %d." % (3 - int(faits[0])), 3.0)
			, 1.0, func(): return seaux[idx].global_position.distance_to(R.P(float(gouttes[idx][0]), 0, float(gouttes[idx][1]))) > 0.3)
	var cb := func() -> void:
		M.talk(habitant, "Salut. Fais attention où tu marches : le toit fuit. À trois endroits. J'ai trois seaux, là, près de la porte, mais j'ai la flemme de me lever… Tu veux bien les mettre sous les gouttes ?",
			[{"id": "oui", "label": "D'accord !"}, {"id": "fermer", "label": "Bon courage…"}], func(id):
			M.close_talk()
			if id == "oui":
				M.say("Les seaux sont près de la porte. Place-les sous les trois gouttes.", 4.0)
		, "un peu nuageux")
	M.talk_spot(habitant, cb)
	M.ctx["entree"] = "Plic… ploc… Il pleut dans la yourte. Trois gouttes tombent du toit sur le tapis, et quelqu'un les regarde d'un air résigné."


static func _repete(M) -> void:
	var R = M.R
	var gui: Node = _gens(M, "homme", -0.8, -1.3, 20, "guitare_bo", {"larsen": {"style": "grunge", "tenue": "cardigan"}, "punk": {"objet": "guitare"}})
	var bas: Node = _gens(M, "femme", 0.9, -1.4, -20, "basse_bo", {"larsen": {"style": "grunge", "tenue": "robe_grunge"}, "punk": {"objet": "basse"}})
	# un petit ampli et des câbles
	var amp: Node3D = I._node(M, R.P(0.0, 0, -2.4), 0)
	I._part(amp, BoxMesh.new(), Color(0.05, 0.05, 0.05), Vector3(0, 0.3, 0), Vector3(0.6, 0.6, 0.32))
	I._part(amp, BoxMesh.new(), Color(0.62, 0.55, 0.42), Vector3(0, 0.3, 0.165), Vector3(0.52, 0.5, 0.01))
	gui.lines = ["Plus fort !", "Un, deux, trois, quatre !", "Ça grince bien, là."]
	bas.lines = ["Boum… boum…", "(Elle hoche la tête en rythme.)", "On reprend ?"]
	var cb := func() -> void:
		M.talk(gui, "Hé ! Tu tombes bien. On répète pour… pour rien, en fait. Il n'y a plus de festival. Mais on répète quand même. Tu veux monter le volume de l'ampli ? Le bouton va jusqu'à onze.",
			[{"id": "onze", "label": "(Tourner le bouton jusqu'à onze)"}, {"id": "fermer", "label": "Continuez, c'est super !"}], func(id):
			M.close_talk()
			if id == "onze":
				M.main.sfx("larsen", amp.global_position)
				gui.gesture("joie", 2.0)
				bas.gesture("rire", 2.0)
				M.say("RRRIIIIIII ! Le larsen siffle dans toute la yourte ! Les deux musiciens éclatent de rire : « Ça, c'est le son de Rainville ! »", 6.0)
				M.state()["onze"] = true
		, "de bonne humeur")
	M.talk_spot(gui, cb)
	M.ctx["entree"] = "BRRRANG ! Une guitare saturée, une basse qui gronde : deux musiciens répètent au milieu de la yourte, entre le poêle et un vieil ampli."


static func _vinyles(M) -> void:
	var R = M.R
	var r := _r(M)
	# des bacs à disques tout le long du mur, un tourne-disque sur un meuble
	for k in range(5):
		var a: float = deg_to_rad(205.0 + k * 22.0)
		var x: float = cos(a) * (RI - 0.5)
		var z: float = sin(a) * (RI - 0.5)
		var yaw: float = rad_to_deg(atan2(-cos(a), -sin(a)))
		R.kit.box(R.L(x, 0.3, z, yaw), Vector3(0.7, 0.6, 0.4), "bois_sombre", 1.0)
		for d in range(9):
			var col: String = ["tissu_rouge", "tissu_noir", "tissu_jaune", "tissu_bleu", "tissu_blanc", "tissu_vert"][(d + k) % 6]
			R.kit.box(R.L(x, 0.6 + 0.1, z, yaw) * Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(-0.3 + d * 0.075, 0, 0)), Vector3(0.012, 0.31, 0.31), col, 1.0)
		R.reserve(x, z, 0.8, 0.8)
	R.table(1.2, -1.2, -40.0, 0.9, 0.5, 0.7, "")
	var pl: Node3D = I._node(M, R.P(1.2, 0.72, -1.2), -40)
	I._part(pl, BoxMesh.new(), Color(0.3, 0.2, 0.12), Vector3(0, 0.05, 0), Vector3(0.45, 0.1, 0.35))
	var disc: MeshInstance3D = I._part(pl, I._cyl(0.15, 0.15, 0.01, 24), Color(0.05, 0.05, 0.05), Vector3(-0.05, 0.11, 0))
	var fan: Node = _gens(M, "homme", 0.2, -0.3, 120, "debout", {"larsen": {"style": "grunge", "tenue": "cardigan"}})
	fan.lines = ["Écoute ce craquement…", "Face B, la meilleure.", "Édition originale !"]
	var cb := func() -> void:
		M.talk(fan, "Bienvenue dans ma collection ! Deux mille disques. Choisis-en un, je le mets sur la platine.",
			[{"id": "0", "label": str(DISQUES[0][0])}, {"id": "1", "label": str(DISQUES[1][0])}, {"id": "2", "label": str(DISQUES[2][0])}, {"id": "3", "label": str(DISQUES[3][0])}], func(id):
			M.close_talk()
			var i: int = int(id)
			fan.gesture("joie", 2.0)
			M.say("Le disque tourne, le diamant crépite… " + str(DISQUES[i][1]), 7.0)
			M.state()["disque"] = i
		, "de bonne humeur")
	M.talk_spot(fan, cb)
	M.ctx["entree"] = "Des disques partout, dans des bacs le long du mur. Sur un petit meuble, une platine attend qu'on choisisse."
	M.ctx["tick"] = func(dt: float) -> void:
		if is_instance_valid(disc):
			disc.rotate_y(dt * 3.5)


static func _sieste_flanelle(M) -> void:
	var R = M.R
	R.canape(0.0, -1.9, 0.0, "brun", 2.0)
	var dormeur: Node = _gens(M, "homme", 0.0, -1.9, 0, "dormir", {"larsen": {"style": "grunge", "tenue": "flanelle"}})
	dormeur.lie(R.P(-0.85, 0.45, -1.95), Vector3(1, 0, 0))
	for k in range(3):
		R.kit.box(R.L(0.1 - k * 0.05, 0.62 + k * 0.05, -1.9, 4.0 * k), Vector3(1.5, 0.04, 0.85), "y_plaid", 1.0)
	R.chat(0.4, -1.85, 30.0, Color(0.15, 0.13, 0.12), true, 0.78)
	dormeur.lines = ["Zzz…", "Mmh… cinq minutes…", "Zzz… la pluie… zzz…"]
	dormeur.follow = false
	var cache: Vector3 = R.P(0.9, 0.5, -1.6)
	M.act(cache, "E : regarder sous le coussin", func():
		if bool(M.state().get("coussin", false)):
			M.say("Il n'y a plus rien sous le coussin. Juste un peu de poil de chat.", 3.0)
			return
		M.state()["coussin"] = true
		M.say("Sous le coussin, tu trouves quelques pièces, une baguette de batterie cassée et un mot : « Si tu lis ceci, ne me réveille pas. » Tu laisses la baguette et le mot, mais il ne dira rien pour les pièces.", 6.0)
		M.give([["piece", 6]], "")
		, 1.2)
	M.ctx["entree"] = "Ronflements. Sur le canapé, quelqu'un dort sous trois couvertures à carreaux. Un chat noir dort sur lui. Personne ne bouge."


static func _tricot(M) -> void:
	var R = M.R
	R.fauteuil(-0.6, -1.5, 30.0, "rouge")
	var mamie: Node = _gens(M, "vieille", -0.6, -1.5, 30, "tricot", {"larsen": {"style": "grunge", "tenue": "impermeable"}, "punk": {"objet": "aiguilles"}})
	# des pelotes, des pulls finis sur un fil
	for k in range(5):
		R.kit.cyl(R.L(0.3 + k * 0.18, 0.06, -1.9 + (k % 2) * 0.15), 0.07, 0.07, 0.12, ["tissu_rouge", "tissu_noir", "tissu_vert", "tissu_brun", "tissu_jaune"][k], 10, true)
	for k2 in range(4):
		var a: float = deg_to_rad(20.0 + k2 * 30.0)
		R.kit.box(R.L(cos(a) * 2.2, 1.6, sin(a) * 2.2 - 0.4, rad_to_deg(a)), Vector3(0.6, 0.65, 0.04), "y_plaid", 1.0)
	R.guirlande(R.P(2.6, 1.95, -1.6), R.P(0.6, 1.95, 1.8), 6)
	mamie.lines = ["Une maille à l'endroit, une maille à l'envers…", "Il faut bien couvrir tout le monde.", "Ce rouge-là, c'est pour Flanelle."]
	var cb := func() -> void:
		M.talk(mamie, "Bonjour, mon petit. Je tricote des pulls à carreaux pour toute la rue. Quand il pleut, il faut avoir chaud. Et quand il ne pleut pas… il pleut quand même, ici. Tu veux une paire de chaussettes ? J'en ai trop.",
			[{"id": "oui", "label": "Volontiers !"}, {"id": "fermer", "label": "C'est gentil, non merci."}], func(id):
			M.close_talk()
			if id == "oui" and not bool(M.state().get("chaussettes", false)):
				M.state()["chaussettes"] = true
				M.say("Elle te tend une paire de chaussettes à carreaux, toutes chaudes… et quelques pièces cachées dedans. « Pour le café. »", 5.0)
				M.give([["piece", 7]], "")
			elif id == "oui":
				M.say("« Tu les as déjà ! Les chaussettes, ça ne s'use pas si on ne marche pas dans les flaques. Tu marches dans les flaques ? »", 5.0)
		, "de bonne humeur")
	M.talk_spot(mamie, cb)
	M.ctx["entree"] = "Clic, clic, clic… Une grand-mère tricote dans un fauteuil rouge, entourée de pelotes. Des pulls à carreaux sèchent sur un fil."


# =================================================================== le Café Feedback et le Disquaire

static func _cafe(M) -> void:
	var R = M.R
	# le comptoir, en arc de cercle au fond
	for k in range(5):
		var a: float = deg_to_rad(235.0 + k * 17.0)
		var x: float = cos(a) * 2.2
		var z: float = sin(a) * 2.2
		var yaw: float = rad_to_deg(atan2(-cos(a), -sin(a)))
		R.kit.box(R.L(x, 0.52, z, yaw), Vector3(0.7, 1.04, 0.5), "bois_sombre", 1.0)
		R.kit.box(R.L(x, 1.07, z, yaw), Vector3(0.75, 0.05, 0.62), "bois", 1.0)
		R.reserve(x, z, 0.8, 0.8)
	for k2 in range(4):
		R.kit.cyl(R.L(-0.7 + k2 * 0.4, 1.1, -2.05), 0.04, 0.035, 0.1, "ceramique", 8, true)
	var barista: Node = _gens(M, "femme", 0.0, -2.75, 0, "comptoir", {"larsen": {"style": "grunge", "tenue": "tablier_cafe", "chapeau": "bonnet"}})
	# le juke-box (une boîte aux néons), les tables, la fuite au-dessus de la table trois
	var jb: Node3D = I._node(M, R.P(-2.5, 0, 0.8), 70)
	I._part(jb, BoxMesh.new(), Color(0.35, 0.12, 0.08), Vector3(0, 0.75, 0), Vector3(0.75, 1.5, 0.5))
	I._part(jb, I._cyl(0.36, 0.36, 0.5, 18), Color(0.35, 0.12, 0.08), Vector3(0, 1.5, 0), Vector3.ONE, Vector3(90, 0, 0))
	I._part(jb, BoxMesh.new(), Color(1.0, 0.45, 0.7), Vector3(0, 1.0, 0.26), Vector3(0.6, 0.5, 0.01), Vector3.ZERO, 2.5)
	R.reserve(-2.5, 0.8, 0.9, 0.9)
	var tables: Array = [[1.3, 0.4], [-0.8, 0.9], [1.0, 1.9]]
	for i in range(tables.size()):
		var t: Array = tables[i]
		R.table_ronde(float(t[0]), float(t[1]), 0.42, 0.75)
		R.tabouret(float(t[0]) + 0.6, float(t[1]))
		R.tabouret(float(t[0]) - 0.6, float(t[1]))
	var client: Node = _gens(M, "homme", 1.9, 0.4, -90, "assis", {"larsen": {"style": "grunge", "tenue": "flanelle"}})
	client.lines = ["La table trois, c'est la meilleure.", "J'adore le bruit de la fuite.", "Encore un chocolat…"]
	# la fuite au-dessus de la table trois, la tasse qui la recueille
	var p := CPUParticles3D.new()
	p.amount = 2
	p.lifetime = 0.8
	p.direction = Vector3.DOWN
	p.initial_velocity_min = 0.5
	p.gravity = Vector3(0, -9.8, 0)
	var q := SphereMesh.new()
	q.radius = 0.016
	q.height = 0.045
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(0.6, 0.75, 0.9, 0.7)
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = mm
	p.mesh = q
	M.room.add_child(p)
	p.global_position = R.P(1.0, HC - 0.7, 1.9)
	# le chat qui dort sur l'ampli
	var amp: Node3D = I._node(M, R.P(2.4, 0, -0.9), -110)
	I._part(amp, BoxMesh.new(), Color(0.05, 0.05, 0.05), Vector3(0, 0.35, 0), Vector3(0.7, 0.7, 0.35))
	I._part(amp, BoxMesh.new(), Color(0.62, 0.55, 0.42), Vector3(0, 0.35, 0.18), Vector3(0.6, 0.6, 0.01))
	R.chat(2.4, -0.9, 20.0, Color(0.85, 0.5, 0.2), true, 0.71)
	R.reserve(2.4, -0.9, 0.9, 0.9)
	barista.lines = ["Un chocolat chaud ?", "La table trois est libre… enfin, presque.", "Il pleut dedans, c'est l'ambiance."]
	var cb := func() -> void:
		M.talk(barista, "Bienvenue au Café Feedback. Chocolat chaud, trois pièces. Tisane, deux pièces. La mélancolie, c'est gratuit. Le juke-box ne joue qu'une seule chanson, mais c'est la bonne.",
			[{"id": "choco", "label": "Un chocolat chaud (3 pièces)"}, {"id": "tisane", "label": "Une tisane (2 pièces)"}, {"id": "juke", "label": "Quelle chanson joue le juke-box ?"}, {"id": "fermer", "label": "Au revoir !"}], func(id):
			var inv: Node = M.main.get("inventory_v28")
			match id:
				"choco", "tisane":
					var prix: int = 3 if id == "choco" else 2
					if inv == null or int(inv.count("piece")) < prix:
						M.talk(barista, "Il te manque des pièces… Bon. Je te l'offre. Mais ne le dis pas à Spleen, il dirait que je suis trop gentille. Il aurait raison.", I._bye("Merci !"), func(_i):
							M.give([["chocolat_chaud" if id == "choco" else "tisane_lune", 1]], "")
							M.close_talk())
						return
					inv.remove("piece", prix)
					M.main.sfx("ramasse_pieces")
					M.talk(barista, "Et voilà. Attention, c'est chaud. Avec un nuage de crème. Un vrai nuage, de Rainville.", I._bye("Merci !"), func(_i):
						M.give([["chocolat_chaud" if id == "choco" else "tisane_lune", 1]], "")
						M.close_talk())
				"juke":
					M.talk(barista, "« Pluie d'été », des Gouttières et du Camp des Fleurs, enregistrée au dernier Festival du Larsen. Spleen la passe quand il pense que personne ne le voit. Il pleure un peu, à chaque fois.", I._bye("Oh…"), I._close(M))
				_:
					M.close_talk()
		, "de bonne humeur")
	M.talk_spot(barista, cb)
	M.ctx["entree"] = "Le Café Feedback : une odeur de chocolat chaud et de laine mouillée, un juke-box qui brille en rose, un chat qui dort sur un ampli… et une goutte qui tombe, plic, ploc, dans une tasse posée sur la table trois."


static func _disquaire(M) -> void:
	var R = M.R
	for k in range(7):
		var a: float = deg_to_rad(160.0 + k * 31.0)
		var x: float = cos(a) * (RI - 0.5)
		var z: float = sin(a) * (RI - 0.5)
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.6:
			continue
		var yaw: float = rad_to_deg(atan2(-cos(a), -sin(a)))
		R.kit.box(R.L(x, 0.4, z, yaw), Vector3(0.8, 0.8, 0.45), "bois_sombre", 1.0)
		for d in range(10):
			R.kit.box(R.L(x, 0.9, z, yaw) * Transform3D(Basis(Vector3.RIGHT, 0.25), Vector3(-0.34 + d * 0.075, 0, 0)), Vector3(0.012, 0.31, 0.31), ["tissu_rouge", "tissu_noir", "tissu_jaune", "tissu_bleu", "tissu_blanc"][(d + k) % 5], 1.0)
		R.reserve(x, z, 0.9, 0.9)
	R.table(0.0, -1.0, 0.0, 1.4, 0.7, 0.9, "")
	var pl: Node3D = I._node(M, R.P(0.3, 0.92, -1.0), 0)
	I._part(pl, BoxMesh.new(), Color(0.3, 0.2, 0.12), Vector3(0, 0.05, 0), Vector3(0.45, 0.1, 0.35))
	var disc: MeshInstance3D = I._part(pl, I._cyl(0.15, 0.15, 0.01, 24), Color(0.05, 0.05, 0.05), Vector3(-0.05, 0.11, 0))
	var vendeur: Node = _gens(M, "homme", 0.0, -1.8, 0, "comptoir", {"larsen": {"style": "grunge", "tenue": "cardigan"}})
	vendeur.lines = ["Ça craque, c'est vivant.", "Face A, face B…", "Prends ton temps."]
	var la: Node = M.main.get("larsen_v91")
	var jr: Node = M.main.get("journal_v56")
	var fini: bool = jr != null and str(jr.state("la_soleil_pluie")) == "finie"
	var cb := func() -> void:
		var choix: Array = [{"id": "ecouter", "label": "Je peux écouter un disque ?"}]
		if fini:
			choix.append({"id": "rare", "label": "Et le disque rare, celui des deux villages ?"})
		choix.append({"id": "fermer", "label": "Au revoir !"})
		M.talk(vendeur, "Bienvenue chez le Disquaire ! Ici, il y a tous les disques de l'île. Vinyle me laisse garder la boutique quand il prend l'air. Prends ton temps.",
			choix, func(id):
			M.close_talk()
			match id:
				"ecouter":
					M.say("Le diamant se pose, ça crépite… « Flaques en mineur », des Gouttières. Une guitare qui grince doucement, une voix qui chuchote. Dehors, la pluie bat la mesure.", 6.0)
				"rare":
					M.say("Il sort, tout au fond, un disque dans une pochette faite main : un soleil et un nuage qui se tiennent la main. « Ça, Vinyle l'a gardé pour le jour où les deux villages se réconcilieraient. Ce jour est arrivé. » La musique commence : des djembés, une guitare saturée, et deux voix de jeunes filles… celles de Mamie Tournesol et de Mère Averse, il y a cinquante ans.", 10.0)
					if la != null:
						la.state["disque_rare"] = true
		, "de bonne humeur")
	M.talk_spot(vendeur, cb)
	M.ctx["entree"] = "Le Disquaire : des milliers de pochettes, une odeur de carton et de vieux papier, et une platine qui tourne doucement."
	M.ctx["tick"] = func(dt: float) -> void:
		if is_instance_valid(disc):
			disc.rotate_y(dt * 3.5)


# =================================================================== chez un habitant qu'on connaît

## La yourte d'un habitant de l'île (Mamie Tournesol, Grésil, Mère Averse…) : son lit, sa table
## basse, ses poufs ; s'il est rentré, il est là (et il parle) ; sinon, un petit mot.
static func _chez(M) -> void:
	var R = M.R
	var r := _r(M)
	var owner: Node = M.ctx["owner_node"]
	var prof: Dictionary = owner.get("profile")
	var nom: String = str(owner.get("display_name"))
	var titre: String = str(prof.get("titre", ""))
	var fl: bool = _fleurs(M)
	# le lit contre le mur (au fond à gauche), la table basse, deux poufs
	var a: float = deg_to_rad(215.0)
	R.lit(cos(a) * 2.1, sin(a) * 2.1, rad_to_deg(atan2(-cos(a), -sin(a))) + 90.0, 1.0, "jaune" if fl else "gris")
	R.reserve(cos(a) * 2.1, sin(a) * 2.1, 2.2, 2.2)
	if not fl:
		R.kit.box(R.L(cos(a) * 2.1, 0.58, sin(a) * 2.1, rad_to_deg(atan2(-cos(a), -sin(a))) + 90.0), Vector3(1.0, 0.04, 1.4), "y_plaid", 1.0)
	_table_basse(M, 0.9, -0.9, 0.45)
	_pouf(M, 1.7, -0.5, "tissu_orange" if fl else "tissu_noir")
	_pouf(M, 0.2, -1.6, "tissu_jaune" if fl else "tissu_rouge")
	_theiere(M, 0.9, 0.36, -0.9)
	if bool(owner.get("hidden_home")):
		var p: Dictionary = prof.duplicate(true)
		p["classe"] = "lumen"
		var f: Node = Figurant.spawn(M.room, M.main, p, R.P(1.7, 0, -0.5), Vector3(-0.85, 0, -0.5).normalized(), "assis")
		M.people.append(f)
		var acc: Array = (prof.get("repliques", {}) as Dictionary).get("lui", [])
		M.talk_spot(f, func() -> void:
			var t: String = str(_pick(M, ["Oh ! Tu es venu me voir dans ma yourte ? Assieds-toi sur un pouf, je fais chauffer de l'eau.", "Ah, c'est toi ! Entre, entre. Mets-toi à l'aise, ici on est entre amis.", "Bienvenue chez moi ! C'est tout rond, c'est tout chaud, et ça sent bon."]))
			var choices: Array = [{"id": "maison", "label": "Elle est belle, ta yourte !"}]
			if not acc.is_empty():
				choices.append({"id": "lui", "label": "Parle-moi un peu de toi."})
			choices.append({"id": "fermer", "label": "Je ne fais que passer. À bientôt !"})
			M.talk(f, t, choices, func(id):
				match id:
					"maison":
						if not bool(M.state().get("cadeau_chez", false)):
							M.state()["cadeau_chez"] = true
							var it: Array = S.food(str(M.ctx["style"]))
							M.talk(f, "Merci ! Lune a tissé la toile, Galet a fait les cordes, et moi j'ai peint la porte. Tiens, prends ça pour la route.", [{"id": "fermer", "label": "Merci beaucoup !"}], func(_i):
								M.give([[str(it[r.randi() % it.size()]), 1]], "")
								M.close_talk())
						else:
							M.talk(f, "Merci ! Reviens quand tu veux, la porte est toujours ouverte.", [{"id": "fermer", "label": "À bientôt !"}], func(_i): M.close_talk())
					"lui":
						var l: Variant = acc[r.randi() % acc.size()]
						M.talk(f, str((l as Dictionary).get("t", "")) if l is Dictionary else str(l), [{"id": "fermer", "label": "Merci de m'avoir raconté."}], func(_i): M.close_talk())
					_:
						M.close_talk()
			))
		M.ctx["entree"] = "Tu es chez %s%s." % [nom, (", " + titre) if titre != "" else ""]
	else:
		S._mot(M, 0.9, -0.9, 0.38, str(_pick(M, ["Un mot de %s : « Partie dehors, au soleil (ou sous la pluie). Fais comme chez toi, mais ne mange pas tous les biscuits. »" % nom, "Un mot sur la table basse : « Je reviens ce soir. — %s »" % nom])), "E : lire le petit mot")
		M.ctx["entree"] = "C'est la yourte de %s%s. Il n'y a personne : on doit être dehors." % [nom, (", " + titre) if titre != "" else ""]
