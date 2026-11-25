extends Node3D
## V201 : le parachute. On le trouve au « Saut des Nuées », un petit kiosque au bord de chaque île
## flottante (Astralys, la Cité des Nuées, l'Île Perchée, l'île de la Citadelle). Avec un parachute dans
## le sac, on saute du bord : la chute libre (on accélère jusqu'à 55 m/s, le vent siffle de plus en plus
## fort, les manettes vibrent, les nuages et les traînées d'air filent vers le haut), puis, à 60 m de la
## terre ou de la mer, la voile s'ouvre toute seule (une secousse, le claquement de la toile, le calme) ;
## on la dirige jusqu'au sol. Le parachute se replie tout seul : on le garde pour le saut suivant.
##
## Au PC, c'est un état du héros (hero_v28.state = "parachute") ; en VR, la chute remplace la marche
## (main._physics_process). Dans les deux cas : le corps physique du joueur, ses collisions, rien d'autre.

const ITEM := "parachute"
const H_MIN_SAUT := 80.0          # on ne saute en chute libre qu'avec au moins 80 m de vide dessous
const H_OUVERTURE := 60.0         # la voile s'ouvre à 60 m du sol ou de la mer
const V_MAX := 55.0               # la vitesse de chute libre (m/s, environ 200 km/h)
const ACCEL := 13.0               # l'accélération de la chute (la pesanteur moins l'air)
const V_HORIZ := 11.0             # en chute libre, on glisse de côté jusqu'à 11 m/s
const V_VOILE := 4.5              # sous la voile, on descend à 4,5 m/s…
const GLISSE := 7.5               # … et on avance de 7,5 m/s (3 en freinant, 11 en accélérant)
const VIRAGE := 0.9               # rad/s
const REGLAGES := "user://reglages_son.cfg"

# les îles flottantes : [nom, centre (x, z), altitude basse et haute du sol]
const ILES := [
	["astralys", Vector2(-820.0, -760.0), 300.0, 470.0],
	["nuees", Vector2(-1030.0, 1370.0), 180.0, 330.0],
	["perchee", Vector2(-820.0, 2140.0), 220.0, 360.0],
	["citadelle", Vector2(40.0, 400.0), 100.0, 260.0],
]

var main: Node
var etat: String = "sol"          # sol, chute, voile
var vitesse: Vector3 = Vector3.ZERO
var cap: float = 0.0              # le cap de la voile (radians autour de Y)
var hauteur: float = 0.0          # hauteur au-dessus du sol ou de la mer
var _t_voile: float = 0.0
var voile: Node3D
var _trainees: GPUParticles3D
var _nuages: GPUParticles3D
var _vent: AudioStreamPlayer
var kiosques: Array = []          # [nom de l'île, position]
var arrivees: Array = []          # V206 : [nom de l'île, où se tenir devant le kiosque] (mode testeur)
var nb_sauts: int = 0
var confort: bool = false         # VR : un voile sombre sur les bords pendant la chute (Paramètres)
var _vignette: MeshInstance3D
var _corps: CharacterBody3D       # qui saute (le héros au PC, le corps VR)


func setup(main_node: Node) -> void:
	main = main_node
	name = "Parachute_v201"
	main.add_child(self)
	_faire_voile()
	_faire_trainees()
	_vent = AudioStreamPlayer.new()
	var s: AudioStream = load("res://assets/sons/ambiance/vent_altitude.ogg") if ResourceLoader.exists("res://assets/sons/ambiance/vent_altitude.ogg") else null
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	_vent.stream = s
	_vent.volume_db = -60.0
	_vent.bus = "Master"
	add_child(_vent)
	var cfg := ConfigFile.new()
	if cfg.load(REGLAGES) == OK:
		confort = bool(cfg.get_value("vr", "confort_chute", false))


## Paramètres > Confort de chute (VR) : gardé avec les autres réglages.
func libelle_confort() -> String:
	return "Confort de chute : " + ("bords voilés" if confort else "vue entière")


func basculer_confort() -> void:
	confort = not confort
	var cfg := ConfigFile.new()
	cfg.load(REGLAGES)
	cfg.set_value("vr", "confort_chute", confort)
	cfg.save(REGLAGES)


# =================================================================== les kiosques du Saut des Nuées

## Sur chaque île flottante : on cherche, par des rayons tombés du ciel, le bord de l'île (le dernier
## point de sol avant le vide) dans plusieurs directions ; on garde un endroit plat et dégagé, à 6 m du
## bord ; on y pose le kiosque, tourné vers le vide, et le parachute à prendre.
func poser_kiosques() -> void:
	var space: PhysicsDirectSpaceState3D = main.get_world_3d().direct_space_state
	for ile in ILES:
		var c: Vector2 = ile[1]
		var bas: float = float(ile[2])
		var haut: float = float(ile[3])
		var meilleur: Dictionary = {}
		for k in range(24):
			var a: float = TAU * k / 24.0
			var d := Vector2(cos(a), sin(a))
			var dernier: Variant = null
			var r: float = 16.0
			while r < 420.0:
				var p: Vector2 = c + d * r
				var hit: Dictionary = _sol(space, p, bas, haut)
				if hit.is_empty():
					if dernier != null:
						break
				else:
					dernier = [r, hit]
				r += 4.0
			if dernier == null:
				continue
			# au-delà du bord, un vrai vide : de quoi ouvrir la voile (pas un quai, pas une plate-forme)
			var y_bord: float = float(((dernier[1] as Dictionary)["position"] as Vector3).y)
			var vide: bool = true
			for e2 in [3.0, 6.0, 10.0]:
				var pv: Vector2 = c + d * (float(dernier[0]) + e2)
				if _hauteur(Vector3(pv.x, y_bord + 1.0, pv.y)) < H_MIN_SAUT + 20.0:
					vide = false
			if not vide:
				continue
			# à 6 m du bord, vers l'intérieur : plat, dégagé, du sol tout autour
			var rk: float = float(dernier[0]) - 6.0
			if rk < 12.0:
				continue
			var pk: Vector2 = c + d * rk
			var hk: Dictionary = _sol(space, pk, bas, haut)
			if hk.is_empty() or (hk["normal"] as Vector3).y < 0.9:
				continue
			var y0: float = float((hk["position"] as Vector3).y)
			var plat: bool = true
			for e in [Vector2(1.5, 0), Vector2(-1.5, 0), Vector2(0, 1.5), Vector2(0, -1.5)]:
				var he: Dictionary = _sol(space, pk + e, bas, haut)
				if he.is_empty() or absf(float((he["position"] as Vector3).y) - y0) > 0.6:
					plat = false
			if not plat:
				continue
			# rien au-dessus (un toit, un arbre) jusqu'à 4 m
			var q := PhysicsRayQueryParameters3D.create(Vector3(pk.x, y0 + 0.3, pk.y), Vector3(pk.x, y0 + 4.0, pk.y))
			q.collision_mask = 1
			if not space.intersect_ray(q).is_empty():
				continue
			# le plus près du bord le plus net : on préfère un grand vide dessous
			var note: float = float(dernier[0])
			if meilleur.is_empty() or note > float(meilleur["note"]):
				meilleur = {"note": note, "pos": Vector3(pk.x, y0, pk.y), "vers": Vector3(d.x, 0, d.y)}
		if meilleur.is_empty():
			print("ILE_MANGA_V201: pas de place pour le Saut des Nuées sur ", ile[0])
			continue
		_kiosque(str(ile[0]), meilleur["pos"], meilleur["vers"])
	print("ILE_MANGA_V201: le Saut des Nuées, %d kiosques à parachutes" % kiosques.size())


func _sol(space: PhysicsDirectSpaceState3D, p: Vector2, bas: float, haut: float) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, haut + 120.0, p.y), Vector3(p.x, bas - 40.0, p.y))
	q.collision_mask = 1
	var hit: Dictionary = space.intersect_ray(q)
	if hit.is_empty():
		return {}
	var y: float = float((hit["position"] as Vector3).y)
	if y < bas - 30.0 or y > haut + 60.0:
		return {}
	return hit


func _kiosque(nom: String, at: Vector3, vers: Vector3) -> void:
	var k := Node3D.new()
	k.name = "Saut_des_Nuees_" + nom
	add_child(k)
	k.global_position = at
	k.look_at(at + vers, Vector3.UP)
	arrivees.append([nom, at - vers.normalized() * 2.6 + Vector3.UP * 0.3])
	var bois := StandardMaterial3D.new()
	bois.albedo_color = Color(0.48, 0.33, 0.2)
	bois.roughness = 0.8
	var toile := StandardMaterial3D.new()
	toile.albedo_color = Color(0.92, 0.42, 0.18)
	toile.roughness = 0.75
	toile.cull_mode = BaseMaterial3D.CULL_DISABLED
	var toile2 := StandardMaterial3D.new()
	toile2.albedo_color = Color(0.95, 0.9, 0.78)
	toile2.roughness = 0.75
	toile2.cull_mode = BaseMaterial3D.CULL_DISABLED
	# (le kiosque tourne le dos au vide, -Z : on arrive de l'île, côté +Z, devant le comptoir)
	# quatre poteaux, un comptoir, un auvent rayé
	for x in [-1.1, 1.1]:
		for z in [-0.6, 0.6]:
			_boite(k, bois, Vector3(x, 1.2, z), Vector3(0.1, 2.4, 0.1))
	_boite(k, bois, Vector3(0, 0.55, 0.6), Vector3(2.3, 1.1, 0.12))
	_boite(k, bois, Vector3(0, 1.12, 0.6), Vector3(2.4, 0.06, 0.4))
	# le comptoir arrête le joueur (on fait le tour pour sauter)
	var corps := StaticBody3D.new()
	corps.collision_layer = 1
	var forme := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(2.4, 1.15, 0.4)
	forme.shape = bx
	forme.position = Vector3(0, 0.575, 0.6)
	corps.add_child(forme)
	k.add_child(corps)
	for i in range(6):
		_boite(k, toile if i % 2 == 0 else toile2, Vector3(-1.0 + i * 0.4, 2.48, 0.0), Vector3(0.4, 0.05, 1.5), Vector3(8, 0, 0))
	# trois sacs de parachute pendus derrière le comptoir
	for i in range(3):
		var sac := _sac()
		sac.position = Vector3(-0.6 + i * 0.6, 1.55, -0.4)
		k.add_child(sac)
	# l'enseigne, au-dessus de l'auvent, tournée vers l'île
	var l := Label3D.new()
	l.text = "LE SAUT DES NUÉES\nParachutes"
	l.font_size = 64
	l.pixel_size = 0.004
	l.outline_size = 10
	l.position = Vector3(0, 2.95, 0.62)
	k.add_child(l)
	# le parachute à prendre, posé sur le comptoir
	var p_pos: Vector3 = k.to_global(Vector3(0, 1.17, 0.6))
	if main.inventory_v28 != null:
		main.inventory_v28.spawn_pickup("parachute_" + nom, ITEM, 1, p_pos, k.global_rotation.y)
	kiosques.append([nom, at])


func _boite(parent: Node3D, mat: Material, pos: Vector3, taille: Vector3, rot: Vector3 = Vector3.ZERO) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = taille
	m.mesh = b
	m.material_override = mat
	m.position = pos
	m.rotation_degrees = rot
	parent.add_child(m)


## Le sac du parachute (aussi le modèle de l'objet dans le sac à dos).
static func _sac() -> Node3D:
	var n := Node3D.new()
	var toile := StandardMaterial3D.new()
	toile.albedo_color = Color(0.86, 0.38, 0.16)
	toile.roughness = 0.85
	var sangle := StandardMaterial3D.new()
	sangle.albedo_color = Color(0.12, 0.12, 0.14)
	sangle.roughness = 0.6
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.34, 0.42, 0.16)
	m.mesh = b
	m.material_override = toile
	n.add_child(m)
	for y in [-0.12, 0.12]:
		var s := MeshInstance3D.new()
		var bs := BoxMesh.new()
		bs.size = Vector3(0.36, 0.04, 0.17)
		s.mesh = bs
		s.material_override = sangle
		s.position.y = y
		n.add_child(s)
	var poignee := MeshInstance3D.new()
	var tp := TorusMesh.new()
	tp.inner_radius = 0.02
	tp.outer_radius = 0.035
	poignee.mesh = tp
	poignee.material_override = sangle
	poignee.position = Vector3(0.12, -0.05, 0.09)
	poignee.rotation_degrees = Vector3(90, 0, 0)
	n.add_child(poignee)
	return n


# =================================================================== la voile et les traînées d'air

func _faire_voile() -> void:
	voile = Node3D.new()
	voile.name = "Voile_v201"
	voile.top_level = true
	voile.visible = false
	add_child(voile)
	# un caisson en arc : 9 cellules, rayées orange et crème, vues de dessous et de dessus
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n_cell: int = 9
	var envergure: float = 8.4
	var corde: float = 3.0
	var fleche: float = 1.6
	for i in range(n_cell):
		var c: Color = Color(0.92, 0.42, 0.18) if i % 2 == 0 else Color(0.96, 0.92, 0.82)
		if i == 4:
			c = Color(0.16, 0.36, 0.62)
		for side in [0, 1]:
			var t0: float = float(i) / n_cell
			var t1: float = float(i + 1) / n_cell
			var x0: float = (t0 - 0.5) * envergure
			var x1: float = (t1 - 0.5) * envergure
			var y0: float = -fleche * pow(2.0 * t0 - 1.0, 2.0) + (0.25 if side == 0 else 0.0)
			var y1: float = -fleche * pow(2.0 * t1 - 1.0, 2.0) + (0.25 if side == 0 else 0.0)
			var a := Vector3(x0, y0, -corde * 0.5)
			var b := Vector3(x1, y1, -corde * 0.5)
			var cc := Vector3(x1, y1 - 0.05, corde * 0.5)
			var d := Vector3(x0, y0 - 0.05, corde * 0.5)
			st.set_color(c)
			var nrm := Vector3.UP if side == 0 else Vector3.DOWN
			st.set_normal(nrm)
			if side == 0:
				for v in [a, b, cc, a, cc, d]:
					st.add_vertex(v)
			else:
				for v in [a, cc, b, a, d, cc]:
					st.add_vertex(v)
	var mesh: ArrayMesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.8
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.backlight_enabled = true
	mat.backlight = Color(0.5, 0.4, 0.3)
	mi.material_override = mat
	mi.position.y = 4.6
	voile.add_child(mi)
	# les suspentes : du bord de la voile aux épaules
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color(0.85, 0.85, 0.82)
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(n_cell + 1):
		var t: float = float(i) / n_cell
		var x: float = (t - 0.5) * envergure
		var y: float = 4.6 - fleche * pow(2.0 * t - 1.0, 2.0)
		for z in [-1.0, 0.8]:
			var top := Vector3(x, y, z)
			var bas := Vector3(0.22 * signf(x) if absf(x) > 0.1 else 0.0, 1.35, 0.0)
			var l := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.006
			cyl.bottom_radius = 0.006
			cyl.height = top.distance_to(bas)
			cyl.radial_segments = 4
			cyl.rings = 1
			l.mesh = cyl
			l.material_override = lm
			l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var dir: Vector3 = (top - bas).normalized()
			l.transform = Transform3D(Basis(Quaternion(Vector3.UP, dir)), (top + bas) * 0.5)
			voile.add_child(l)


## Des traînées d'air et des lambeaux de nuage, immobiles dans le monde : en tombant, on passe au
## travers, et ils filent vers le haut (c'est ce qui donne la vitesse, en VR comme au PC).
func _faire_trainees() -> void:
	_trainees = _particules(220, 1.4, Vector2(0.025, 1.6), Color(0.95, 0.97, 1.0, 0.35), Vector3(14, 30, 14))
	_trainees.name = "Trainees_v201"
	_nuages = _particules(40, 2.4, Vector2(4.5, 3.0), Color(1, 1, 1, 0.18), Vector3(40, 60, 40))
	_nuages.name = "Nuages_v201"


func _particules(n: int, vie: float, taille: Vector2, couleur: Color, boite: Vector3) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = n
	p.lifetime = vie
	p.local_coords = false
	p.emitting = false
	p.top_level = true
	p.visibility_aabb = AABB(-boite * 2.0, boite * 4.0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = boite
	pm.gravity = Vector3.ZERO
	pm.initial_velocity_min = 0.0
	pm.initial_velocity_max = 0.0
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.add_point(0.2, Color(1, 1, 1, 1))
	fade.add_point(0.75, Color(1, 1, 1, 1))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	var ft := GradientTexture1D.new()
	ft.gradient = fade
	pm.color_ramp = ft
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = taille
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.vertex_color_use_as_albedo = true
	m.albedo_color = couleur
	var g := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 1))
	gr.set_color(1, Color(1, 1, 1, 0))
	g.gradient = gr
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(0.5, 0.0)
	g.width = 32
	g.height = 64
	m.albedo_texture = g
	m.disable_receive_shadows = true
	q.material = m
	p.draw_pass_1 = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	return p


# =================================================================== la chute

## Pour main.pied_ok_v176 : avec un parachute, au-dessus d'une île flottante (ou juste à côté), on a le
## droit de s'avancer au-delà du bord.
func laisse_sauter(p: Vector3) -> bool:
	if not a_un_parachute():
		return false
	for ile in ILES:
		var c: Vector2 = ile[1]
		if Vector2(p.x, p.z).distance_to(c) < 480.0 and p.y > float(ile[2]) - 60.0:
			# seulement là où il y a assez de vide dessous pour que la voile s'ouvre
			return _hauteur(p + Vector3.UP * 0.3) > H_MIN_SAUT
	return false


## Le héros (PC) a quitté la chute autrement qu'en se posant (repêché, téléporté, évanoui) : on
## replie tout, sinon le bord des îles resterait ouvert.
func _physics_process(_delta: float) -> void:
	if etat == "sol" or main == null or main.xr_active:
		return
	var h: Variant = main.get("hero_v28")
	if h != null and _corps == h.body and str(h.state) != "parachute":
		_finir()


func a_un_parachute() -> bool:
	return main.inventory_v28 != null and int(main.inventory_v28.count(ITEM)) > 0


func actif() -> bool:
	return etat != "sol"


## La hauteur au-dessus du sol (ou de la mer) sous un point.
func _hauteur(p: Vector3) -> float:
	var space: PhysicsDirectSpaceState3D = main.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(p, p + Vector3.DOWN * 2500.0)
	q.collision_mask = 1
	var hit: Dictionary = space.intersect_ray(q)
	var sol: float = 0.0
	if not hit.is_empty():
		sol = maxf(float((hit["position"] as Vector3).y), 0.0)
	return p.y - sol


## Saute-t-on ? (en l'air, déjà en train de tomber, avec beaucoup de vide dessous et un parachute)
func peut_sauter(corps: CharacterBody3D) -> bool:
	if corps == null or corps.is_on_floor() or corps.velocity.y > -4.0 or not a_un_parachute():
		return false
	return _hauteur(corps.global_position) > H_MIN_SAUT


func commencer(corps: CharacterBody3D) -> void:
	_corps = corps
	etat = "chute"
	vitesse = corps.velocity
	nb_sauts += 1
	_t_voile = 0.0
	var f: Vector3 = Vector3(vitesse.x, 0, vitesse.z)
	cap = atan2(-f.x, -f.z) if f.length() > 0.5 else cap
	_trainees.emitting = true
	_nuages.emitting = true
	if _vent.stream != null:
		_vent.play()
	if main.has_method("_show_message_v28"):
		main._show_message_v28("Chute libre ! La voile s'ouvrira toute seule près du sol.")


func _ouvrir() -> void:
	etat = "voile"
	_t_voile = 0.0
	voile.visible = true
	voile.scale = Vector3(0.15, 0.15, 0.15)
	if main.has_method("sfx"):
		main.sfx("fregate_claque", null, -2.0)
	_vibrer(0.9, 0.35)


func _finir() -> void:
	etat = "sol"
	voile.visible = false
	_trainees.emitting = false
	_nuages.emitting = false
	if _vent.playing:
		_vent.stop()
	if _vignette != null:
		_vignette.visible = false


## Un pas de chute (PC ou VR) : dir = la direction voulue à plat (déjà dans le monde, longueur 0..1),
## frein = -1..1 (en arrière : on freine la voile ; en avant : on accélère).
func pas(corps: CharacterBody3D, delta: float, dir: Vector3, tourne: float, frein: float) -> void:
	hauteur = _hauteur(corps.global_position)
	if etat == "chute":
		vitesse.y = maxf(vitesse.y - ACCEL * delta, -V_MAX)
		var vh := Vector3(vitesse.x, 0, vitesse.z)
		vh = vh.lerp(dir * V_HORIZ, clampf(delta * 1.2, 0.0, 1.0))
		vitesse.x = vh.x
		vitesse.z = vh.z
		if dir.length() > 0.2:
			cap = lerp_angle(cap, atan2(-dir.x, -dir.z), clampf(delta * 2.0, 0.0, 1.0))
		if hauteur < H_OUVERTURE:
			_ouvrir()
	elif etat == "voile":
		_t_voile += delta
		cap -= tourne * VIRAGE * delta
		var avance: float = GLISSE + (3.5 if frein > 0.3 else 0.0) - (4.5 if frein < -0.3 else 0.0)
		var cible := Vector3(-sin(cap), 0, -cos(cap)) * avance
		# la secousse : la voile freine net la chute en une seconde
		var k: float = clampf(delta * (2.6 if _t_voile < 1.2 else 1.5), 0.0, 1.0)
		vitesse.y = lerpf(vitesse.y, -V_VOILE, k)
		vitesse.x = lerpf(vitesse.x, cible.x, k)
		vitesse.z = lerpf(vitesse.z, cible.z, k)
		voile.scale = Vector3.ONE * minf(1.0, 0.15 + _t_voile * 1.3)
	corps.velocity = vitesse
	corps.move_and_slide()
	vitesse = corps.velocity
	if etat == "voile" and corps.global_position.y < 0.6:
		# dans la mer : on lâche la voile, on nage
		_finir()
	elif corps.is_on_floor() and (etat == "voile" or vitesse.y > -1.0):
		_finir()
		if main.has_method("sfx"):
			main.sfx("atterrissage", corps.global_position, -4.0)
	_visuels(corps, delta)


func _visuels(corps: CharacterBody3D, _delta: float) -> void:
	var p: Vector3 = corps.global_position
	if voile.visible:
		voile.global_transform = Transform3D(Basis(Vector3.UP, cap), p)
	# les traînées : un peu sous le joueur (on tombe dedans)
	_trainees.global_position = p + Vector3.DOWN * 24.0
	_nuages.global_position = p + Vector3.DOWN * 50.0
	var v: float = vitesse.length()
	_trainees.amount_ratio = clampf(v / V_MAX, 0.05, 1.0) if etat == "chute" else 0.05
	if _vent.playing:
		var k: float = clampf(v / V_MAX, 0.0, 1.0) if etat == "chute" else 0.15
		_vent.volume_db = lerpf(-30.0, 2.0, k)
		_vent.pitch_scale = lerpf(0.8, 1.35, k)
	if etat == "chute":
		_vibrer(clampf(v / V_MAX, 0.0, 1.0) * 0.35, 0.05)
	if _vignette != null:
		_vignette.visible = confort and etat == "chute"


func _vibrer(force: float, duree: float) -> void:
	if main == null or not main.xr_active:
		return
	for h in [main.left_hand, main.right_hand]:
		if h != null and h.has_method("trigger_haptic_pulse"):
			h.trigger_haptic_pulse("haptic", 0.0, force, duree, 0.0)


# =================================================================== VR

## En VR, chaque pas de physique : on saute (si l'on tombe dans le vide avec un parachute), on tombe,
## on vole. Renvoie vrai si la chute a pris la main (la marche ne joue pas).
func vr_tick(delta: float) -> bool:
	var corps: CharacterBody3D = main.vr_body
	if corps == null:
		return false
	if etat == "sol":
		if not peut_sauter(corps):
			return false
		commencer(corps)
		_faire_vignette()
	var stick: Vector2 = main.left_hand.get_vector2("primary")
	var f: Vector3 = -main.xr_camera.global_transform.basis.z
	f.y = 0.0
	f = f.normalized() if f.length() > 0.01 else Vector3.FORWARD
	var r: Vector3 = main.xr_camera.global_transform.basis.x
	r.y = 0.0
	r = r.normalized() if r.length() > 0.01 else Vector3.RIGHT
	var dir: Vector3 = (r * stick.x + f * stick.y).limit_length(1.0)
	var head: Vector3 = main.xr_camera.global_position
	var head_offset := Vector3(head.x - main.xr_origin.global_position.x, 0.0, head.z - main.xr_origin.global_position.z)
	pas(corps, delta, dir, stick.x, stick.y)
	# l'origine suit le corps (la tête au-dessus), comme en marchant
	main.xr_origin.position = Vector3(corps.position.x - head_offset.x, corps.position.y, corps.position.z - head_offset.z)
	return true


## VR : un voile sombre sur les bords de la vue pendant la chute libre, pour ceux que la vitesse gêne
## (Paramètres > Confort de chute). Une sphère autour de la tête, transparente au centre.
func _faire_vignette() -> void:
	if _vignette != null or main.xr_camera == null:
		return
	_vignette = MeshInstance3D.new()
	_vignette.name = "Confort_chute_v201"
	var s := SphereMesh.new()
	s.radius = 0.3
	s.height = 0.6
	s.radial_segments = 24
	s.rings = 12
	_vignette.mesh = s
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, depth_test_disabled, blend_mix;
void fragment() {
	// VIEW : la direction du regard vers ce point ; au centre de la vue, transparent
	float c = clamp(dot(normalize(-VERTEX), vec3(0.0, 0.0, 1.0)), 0.0, 1.0);
	float a = smoothstep(0.86, 0.6, c);
	ALBEDO = vec3(0.0);
	ALPHA = a * 0.85;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	_vignette.material_override = m
	_vignette.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_vignette.visible = false
	main.xr_camera.add_child(_vignette)


# =================================================================== PC

## Au PC, appelé par le héros (hero_v28, état « parachute ») : dir = la direction voulue (caméra).
func pc_tick(heros: Node, delta: float, dir: Vector3, axe: Vector2) -> void:
	var corps: CharacterBody3D = heros.body
	pas(corps, delta, dir, axe.x, -axe.y)
	heros.root.position = corps.position
	heros.fall_top = corps.position.y
	if etat == "sol":
		heros.state = "sol"
