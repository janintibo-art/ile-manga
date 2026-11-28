extends Node3D
## V219 : la magie spectaculaire. Les sorts d'attaque avaient les bonnes règles (le feu brûle, la glace fige,
## la foudre saute d'un ennemi à l'autre) mais une image pauvre : quelques dizaines de points lumineux. Ici,
## de vraies matières, calculées par la carte graphique (le processeur, lui, ne fait que les lancer) :
##
##  - la Boule de feu : un cœur en fusion, une chevelure de flammes, des braises, une traînée de fumée ;
##    à l'impact, un éclat, une boule de flammes qui roule et monte, des braises qui tourbillonnent, une
##    colonne de fumée, une vague de feu au sol, et le sol noirci où des braises rougeoient encore ;
##  - le Gel : un cône de brume glacée, des bouquets de cristaux qui poussent en éventail puis volent en
##    poussière, une poussière de givre qui flotte et scintille, le givre qui prend sur le sol ;
##  - la Foudre : un éclair brisé à toutes les échelles, qui ondule sans cesse, ramifié, avec des filaments
##    qui s'enroulent autour de lui ; un éclat qui éclaire tout le décor, une poussière électrique, des arcs
##    qui rampent encore au sol en se tordant.
##
## Rien de droit, rien de régulier : pas de trait, pas d'anneau parfait, pas d'alignement. Les flammes, la
## fumée, la brume sont des bouffées rongées par un bruit qui défile ; les braises et les paillettes, des
## points doux qui scintillent et tourbillonnent (shaders/magie_v219/). Rien n'est animé image par image par
## le processeur, sauf quelques réglages de lumière.

const SH := "res://shaders/magie_v219/"
const MATIERES := ["feu_bouffee", "fumee_bouffee", "poussiere", "boule_feu", "eclat", "onde", "brulure", "givre_sol", "eclair", "glace"]
const BOUQUETS := 4                     # formes différentes de bouquets de cristaux (faites une fois)
const MARQUES_MAX := 10                 # brûlures au sol gardées en même temps (les plus vieilles s'effacent)
const GIVRES_MAX := 24                  # plaques de givre gardées en même temps (un souffle en pose dix)

var main: Node
var bruit: NoiseTexture2D
var cristaux: NoiseTexture2D
var lances: Dictionary = {}             # sorte d'effet -> combien de fois (pour les essais)
var marques: Array = []                 # les brûlures au sol encore là
var givres: Array = []                  # les plaques de givre encore là
var dernier: Dictionary = {}            # le dernier effet de chaque sorte : ses objets (pour les essais)

var _shaders: Dictionary = {}
var _mats: Dictionary = {}
var _procs: Dictionary = {}
var _quad: QuadMesh
var _plan: PlaneMesh
var _eclat_glace: ArrayMesh
var _bouquets: Array = []               # les bouquets de cristaux (ArrayMesh)
# les tableaux d'un maillage de rubans en cours (les éclairs)
var _tv := PackedVector3Array()
var _tn := PackedVector3Array()
var _tuv := PackedVector2Array()
var _tuv2 := PackedVector2Array()
var _tc := PackedColorArray()
var _ti := PackedInt32Array()
var _sphere: SphereMesh
var _rng := RandomNumberGenerator.new()


func setup(main_node: Node) -> void:
	main = main_node
	name = "Magie_v219"
	# (les objets créés ici ont des noms sans chiffre final : le moteur numérote des frères de même nom en
	# faisant monter ce chiffre, et « Brulure_v219 » deviendrait « Brulure_v220 »)
	_rng.randomize()
	# le bruit qui ronge les flammes et la fumée : un nuage qui se répète sans couture
	var fn := FastNoiseLite.new()
	fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fn.frequency = 0.014
	fn.fractal_type = FastNoiseLite.FRACTAL_FBM
	fn.fractal_octaves = 4
	bruit = NoiseTexture2D.new()
	bruit.width = 256
	bruit.height = 256
	bruit.seamless = true
	bruit.generate_mipmaps = true
	bruit.noise = fn
	# les cristaux du givre : les arêtes d'un pavage
	var fc := FastNoiseLite.new()
	fc.noise_type = FastNoiseLite.TYPE_CELLULAR
	fc.frequency = 0.035
	fc.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	fc.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	fc.fractal_type = FastNoiseLite.FRACTAL_NONE
	cristaux = NoiseTexture2D.new()
	cristaux.width = 256
	cristaux.height = 256
	cristaux.seamless = true
	cristaux.generate_mipmaps = true
	cristaux.noise = fc
	_quad = QuadMesh.new()
	_quad.size = Vector2(1, 1)
	_plan = PlaneMesh.new()
	_plan.size = Vector2(1, 1)
	_sphere = SphereMesh.new()
	_sphere.radius = 0.5
	_sphere.height = 1.0
	_sphere.radial_segments = 24
	_sphere.rings = 12
	_eclat_glace = _mesh_eclat(0.03, 0.26)
	for i in BOUQUETS:
		_bouquets.append(_mesh_bouquet(5 + i % 3))
	# les matières sont chargées tout de suite (pas au premier sort), puis montrées une fois loin sous le
	# monde : la carte graphique prépare ses programmes pendant le chargement
	for nom in MATIERES:
		_shader(nom)
	if is_inside_tree():
		get_tree().create_timer(2.0).timeout.connect(prechauffer)


func _compte(sorte: String) -> void:
	lances[sorte] = int(lances.get(sorte, 0)) + 1


# =================================================================== les matières, les maillages

func _shader(nom: String) -> Shader:
	if not _shaders.has(nom):
		_shaders[nom] = load(SH + nom + ".gdshader")
	return _shaders[nom]


## Une matière nommée, faite une fois (cle), sur le shader « nom », avec ces réglages.
func _mat(cle: String, nom: String, reglages: Dictionary = {}) -> ShaderMaterial:
	if _mats.has(cle):
		return _mats[cle]
	var m := ShaderMaterial.new()
	m.shader = _shader(nom)
	for k in reglages:
		m.set_shader_parameter(str(k), reglages[k])
	_mats[cle] = m
	return m


## Un éclat de glace : deux pointes opposées, à quatre pans, le long de Y.
func _mesh_eclat(rayon: float, long: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var haut: Vector3 = Vector3.UP * long * 0.5
	var bas: Vector3 = Vector3.DOWN * long * 0.5
	var ceinture: Array = []
	for i in 4:
		var a: float = TAU * float(i) / 4.0 + 0.4
		ceinture.append(Vector3(cos(a) * rayon, long * 0.12, sin(a) * rayon))
	for i in 4:
		var p0: Vector3 = ceinture[i]
		var p1: Vector3 = ceinture[(i + 1) % 4]
		for v in [haut, p1, p0, bas, p0, p1]:
			st.set_uv(Vector2(0.5, 0.75))
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()


## Un cristal de glace : un prisme à « pans » côtés, renflé au tiers, effilé en pointe, posé par « xf ».
## UV.y : la hauteur le long du cristal (0 au pied, 1 à la pointe).
func _ajoute_cristal(st: SurfaceTool, xf: Transform3D, r: float, h: float, pans: int) -> void:
	var niveaux: Array = [[0.0, 0.72], [0.3, 1.0], [0.8, 0.62]]      # [hauteur, rayon] en parts de h et de r
	var tour: float = _rng.randf() * TAU
	for k in range(niveaux.size()):
		var y0: float = float(niveaux[k][0]) * h
		var r0: float = float(niveaux[k][1]) * r
		var dernier_niveau: bool = k == niveaux.size() - 1
		var y1: float = h if dernier_niveau else float(niveaux[k + 1][0]) * h
		var r1: float = 0.0 if dernier_niveau else float(niveaux[k + 1][1]) * r
		for i in pans:
			var a0: float = tour + TAU * float(i) / pans
			var a1: float = tour + TAU * float(i + 1) / pans
			var b0 := Vector3(cos(a0) * r0, y0, sin(a0) * r0)
			var b1 := Vector3(cos(a1) * r0, y0, sin(a1) * r0)
			var t0 := Vector3(cos(a0) * r1, y1, sin(a0) * r1)
			var t1 := Vector3(cos(a1) * r1, y1, sin(a1) * r1)
			var faces: Array = [[b0, y0], [t0, y1], [b1, y0]] if dernier_niveau else [[b0, y0], [t0, y1], [b1, y0], [b1, y0], [t0, y1], [t1, y1]]
			for f in faces:
				st.set_uv(Vector2(float(i) / pans, float(f[1]) / h))
				st.add_vertex(xf * (f[0] as Vector3))


## Un bouquet de cristaux : un grand au milieu, les autres en éventail autour, penchés, inégaux. Haut d'un
## mètre environ (on le grandit en le posant). Les faces ne partagent pas leurs sommets : chaque pan a son
## reflet.
func _mesh_bouquet(n: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		var milieu: bool = i == 0
		var penche: float = _rng.randf_range(0.0, 0.12) if milieu else _rng.randf_range(0.3, 0.9)
		var azimut: float = TAU * float(i) / maxf(n - 1, 1) + _rng.randf_range(-0.5, 0.5)
		var haut: float = 1.0 if milieu else _rng.randf_range(0.32, 0.78)
		var large: float = haut * _rng.randf_range(0.085, 0.14)
		var b: Basis = Basis(Vector3.UP, azimut) * Basis(Vector3.RIGHT, penche)
		var pied: Vector3 = Vector3(sin(azimut), 0.0, cos(azimut)) * (0.0 if milieu else _rng.randf_range(0.02, 0.09)) + Vector3.DOWN * 0.04
		_ajoute_cristal(st, Transform3D(b, pied), large, haut, 6)
	st.generate_normals()
	return st.commit()


## Un des bouquets de cristaux (au hasard), et la matière de la glace : pour ceux qui posent de la glace
## ailleurs (la gangue d'un ennemi gelé).
func bouquet() -> ArrayMesh:
	return _bouquets[_rng.randi() % _bouquets.size()]


func matiere_glace() -> ShaderMaterial:
	return _mat("glace", "glace", {"bruit": bruit})


func _courbe(points: Array) -> CurveTexture:
	var c := Curve.new()
	var maxi: float = 1.0
	for p in points:
		maxi = maxf(maxi, float(p[1]))
	c.max_value = maxi
	for p in points:
		c.add_point(Vector2(float(p[0]), float(p[1])))
	var t := CurveTexture.new()
	t.curve = c
	return t


func _degrade(couleurs: Array) -> GradientTexture1D:
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for i in couleurs.size():
		offs.append(float(i) / maxf(couleurs.size() - 1, 1.0))
		cols.append(couleurs[i])
	g.offsets = offs
	g.colors = cols
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


## Les règles d'un jet de particules (faites une fois par « cle », sauf si « dir » change : alors une copie).
## dir, ouverture, v0-v1 (vitesse), poids, frein, s0-s1 (taille), courbe (taille selon l'âge), couleurs,
## rayon ou boite (d'où elles partent), hasard (durée de vie inégale), tourbillon/grain/emprise, aligne.
func _proc(cle: String, p: Dictionary) -> ParticleProcessMaterial:
	if _procs.has(cle):
		return _procs[cle]
	var m := ParticleProcessMaterial.new()
	m.direction = p.get("dir", Vector3.UP)
	m.spread = float(p.get("ouverture", 180.0))
	m.initial_velocity_min = float(p.get("v0", 1.0))
	m.initial_velocity_max = float(p.get("v1", 2.0))
	m.gravity = p.get("poids", Vector3.ZERO)
	m.damping_min = float(p.get("frein", 0.0))
	m.damping_max = float(p.get("frein", 0.0)) * 1.3
	m.scale_min = float(p.get("s0", 1.0))
	m.scale_max = float(p.get("s1", 1.0))
	if p.has("courbe"):
		m.scale_curve = _courbe(p["courbe"])
	if p.has("couleurs"):
		m.color_ramp = _degrade(p["couleurs"])
	if p.has("boite"):
		m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		m.emission_box_extents = p["boite"]
	else:
		m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		m.emission_sphere_radius = float(p.get("rayon", 0.1))
	m.lifetime_randomness = float(p.get("hasard", 0.3))
	if p.has("tourbillon"):
		# l'air les emporte : leur course se tord, aucune ne va droit (tourbillon : la force ; grain : la
		# taille des remous, en mètres à peu près)
		m.turbulence_enabled = true
		m.turbulence_noise_strength = float(p["tourbillon"])
		m.turbulence_noise_scale = float(p.get("grain", 2.2))
		m.turbulence_noise_speed = Vector3(0.0, 0.6, 0.0)
		m.turbulence_noise_speed_random = 0.4
		m.turbulence_influence_min = float(p.get("emprise", 0.25)) * 0.5
		m.turbulence_influence_max = float(p.get("emprise", 0.25))
	if bool(p.get("aligne", false)):
		m.particle_flag_align_y = true
	else:
		# l'angle de chaque bouffée sert de graine à son dessin
		m.angle_min = 0.0
		m.angle_max = 360.0
	_procs[cle] = m
	return m


## Un jet de particules de la carte graphique. p : n, vie, continu, explo, portee, vers (son axe) ; proc
## (ses règles), mesh, mat. Il se détruit seul, sauf « continu » : celui-là suit « cible » (à « decal »
## d'elle) tant qu'elle existe (p["suivi"] : l'attache posée sur elle ; la détruire éteint le jet).
func _gerbe(at: Vector3, p: Dictionary, cible: Node3D = null) -> GPUParticles3D:
	var g := GPUParticles3D.new()
	g.amount = int(p.get("n", 16))
	g.lifetime = float(p.get("vie", 1.0))
	var continu: bool = bool(p.get("continu", false))
	g.one_shot = not continu
	g.explosiveness = float(p.get("explo", 0.0 if continu else 1.0))
	g.local_coords = false
	g.process_material = p["proc"]
	g.draw_pass_1 = p.get("mesh", _quad)
	g.material_override = p["mat"]
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var r: float = float(p.get("portee", 12.0))
	g.visibility_aabb = AABB(Vector3(-r, -r, -r), Vector3(r, r, r) * 2.0)
	add_child(g)
	if cible != null:
		g.global_position = cible.global_position + (p.get("decal", Vector3.ZERO) as Vector3)
		p["suivi"] = _suivre(g, cible, p.get("decal", Vector3.ZERO))
	else:
		g.global_position = at
	var vers: Vector3 = p.get("vers", Vector3.ZERO)
	if vers.length() > 0.01:
		# (l'axe Z du jet le long de « vers » : sa boîte d'émission s'étire dans ce sens)
		g.global_transform = Transform3D(Basis.looking_at(vers.normalized(), Vector3.UP if absf(vers.normalized().y) < 0.95 else Vector3.RIGHT), g.global_position)
	g.emitting = true
	if not continu:
		get_tree().create_timer(g.lifetime * 1.4 + 0.8).timeout.connect(g.queue_free)
	return g


## Le jet « g » suit « cible » sans en être l'enfant : une attache posée sur la cible lui donne sa place à
## chaque déplacement (le moteur s'en charge, aucun calcul par image ici). Quand l'attache disparaît (la
## cible est détruite, ou on détruit l'attache), le jet cesse d'émettre et ses dernières particules
## finissent leur vie : les flammes ne s'éteignent pas d'un coup.
func _suivre(g: GPUParticles3D, cible: Node3D, decal: Vector3) -> RemoteTransform3D:
	var attache := RemoteTransform3D.new()
	attache.name = "Attache_magie"
	attache.update_rotation = false
	attache.update_scale = false
	cible.add_child(attache)
	attache.position = decal
	attache.remote_path = attache.get_path_to(g)
	attache.tree_exiting.connect(_eteindre.bind(g), CONNECT_ONE_SHOT)
	return attache


func _eteindre(g: Variant) -> void:
	if g == null or not is_instance_valid(g):
		return
	var jet: GPUParticles3D = g
	jet.emitting = false
	if is_inside_tree():
		get_tree().create_timer(jet.lifetime + 0.3).timeout.connect(jet.queue_free)
	else:
		jet.queue_free()


## Les matières qui servent à plusieurs effets (toujours les mêmes réglages, quel que soit le premier servi).
func _mat_brume() -> ShaderMaterial:
	return _mat("brume_givre", "fumee_bouffee", {"bruit": bruit, "opacite": 0.62, "vitesse": 0.25,
		"teinte": Vector3(0.62, 0.76, 0.9), "teinte_claire": Vector3(0.93, 0.97, 1.0), "lueur": Vector3(0.55, 0.8, 1.0), "lueur_force": 0.9})


## La braise : un point doux, un peu étiré dans le sens de sa course (les particules alignées), qui palpite.
func _mat_braise() -> ShaderMaterial:
	return _mat("braise", "poussiere", {"intensite": 4.2, "etire": 2.2, "scintille": 0.45})


## La poussière électrique : des points bleu-blanc qui clignotent vite.
func _mat_etincelle_foudre() -> ShaderMaterial:
	return _mat("poussiere_foudre", "poussiere", {"intensite": 4.2, "etire": 1.0, "scintille": 0.85})


## La paillette de givre : un point pâle, quatre rayons très fins, qui scintille.
func _mat_paillette() -> ShaderMaterial:
	return _mat("paillette", "poussiere", {"intensite": 2.6, "etire": 1.0, "scintille": 0.8, "etoile": 0.7})


# =================================================================== les briques

## Le sol sous ce point : {ok, pos, n}. D'abord par un rayon (les décors, les planchers), sinon le relief.
## Ce qui bouge (une bête, un habitant, un objet qui roule, un bateau) n'est pas le sol : le rayon passe au travers,
## sinon la marque d'une explosion se poserait sur le dos de l'ennemi touché.
func _sol(p: Vector3, bas: float = 4.0) -> Dictionary:
	if is_inside_tree():
		var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 1.2, p + Vector3.DOWN * bas, 1)
		var sauf: Array[RID] = []
		for b in [main.get("pc_body") if main != null else null, main.get("vr_body") if main != null else null]:
			if b != null and is_instance_valid(b) and b.has_method("get_rid"):
				sauf.append(b.get_rid())
		var espace: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
		for essai in 4:
			q.exclude = sauf
			var hit: Dictionary = espace.intersect_ray(q)
			if hit.is_empty():
				break
			if hit.collider is CharacterBody3D or hit.collider is RigidBody3D or hit.collider is AnimatableBody3D:
				sauf.append(hit.rid)
				continue
			return {"ok": true, "pos": hit.position, "n": (hit.normal as Vector3).normalized()}
	if main != null and main.has_method("_height_at"):
		var y: float = float(main._height_at(p.x, p.z))
		if p.y - y < bas and p.y - y > -1.5:
			return {"ok": true, "pos": Vector3(p.x, y, p.z), "n": Vector3.UP}
	return {"ok": false, "pos": p, "n": Vector3.UP}


## Une lumière qui s'éteint.
func _lumiere(at: Vector3, col: Color, force: float, portee: float, vie: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = force
	l.omni_range = portee
	l.omni_attenuation = 1.4
	l.shadow_enabled = false
	add_child(l)
	l.global_position = at
	var tw := l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, vie).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(l.queue_free)
	return l


## L'éclat : un disque de lumière face au regard, qui grandit de d0 à d1 mètres et s'éteint.
func _eclat(at: Vector3, col: Color, d0: float, d1: float, vie: float, intensite: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _quad
	var m := ShaderMaterial.new()
	m.shader = _shader("eclat")
	# de tout près, l'éclat remplirait la vue de blanc : on le modère (encore plus dans le casque)
	var force: float = 1.0
	var cam: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam != null:
		force = clampf(cam.global_position.distance_to(at) / 6.0, 0.3, 1.0)
	if main != null and bool(main.get("xr_active")):
		force *= 0.7
	m.set_shader_parameter("couleur", Vector3(col.r, col.g, col.b))
	m.set_shader_parameter("intensite", intensite)
	m.set_shader_parameter("force", force)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = at
	mi.scale = Vector3.ONE * d0
	var tw := mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * d1, vie).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "shader_parameter/force", 0.0, vie).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(mi.queue_free)
	return mi


## Un carré posé à plat sur le sol (de normale n), large de « taille » mètres.
func _a_plat(pos: Vector3, n: Vector3, taille: float, m: ShaderMaterial) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _plan
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var y: Vector3 = n.normalized()
	var x: Vector3 = y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var z: Vector3 = x.cross(y).normalized()
	var b := Basis(x, y, z).rotated(y, _rng.randf() * TAU)
	mi.global_transform = Transform3D(Basis(b.x * taille, b.y, b.z * taille), pos + y * 0.045)
	return mi


## La vague au sol : un front irrégulier, ourlé de mèches, qui s'élargit jusqu'à « taille » mètres.
func _onde(pos: Vector3, n: Vector3, taille: float, vie: float, col: Color, intensite: float = 5.0) -> void:
	var m := ShaderMaterial.new()
	m.shader = _shader("onde")
	m.set_shader_parameter("bruit", bruit)
	m.set_shader_parameter("couleur", Vector3(col.r, col.g, col.b))
	m.set_shader_parameter("intensite", intensite)
	m.set_shader_parameter("t", 0.0)
	m.set_shader_parameter("graine", _rng.randf() * 7.0)
	var mi := _a_plat(pos, n, taille, m)
	var tw := mi.create_tween()
	tw.tween_property(m, "shader_parameter/t", 1.0, vie)
	tw.tween_callback(mi.queue_free)


## Une marque de plus dans sa liste ; au-delà de « maxi », les plus vieilles s'effacent (en une demi-seconde,
## par leur réglage « efface » ou « fonte » : pas d'un coup).
func _marque(liste: Array, maxi: int, mi: MeshInstance3D, reglage: String) -> void:
	liste.append(mi)
	while liste.size() > maxi:
		var vieux: Variant = liste.pop_front()
		if vieux == null or not is_instance_valid(vieux):
			continue
		var vieille: MeshInstance3D = vieux
		var avant: Variant = vieille.get_meta("vie_v219", null)
		if avant is Tween and (avant as Tween).is_valid():
			(avant as Tween).kill()
		var tw := vieille.create_tween()
		tw.tween_property(vieille.material_override, "shader_parameter/" + reglage, 1.0, 0.5)
		tw.tween_callback(vieille.queue_free)


## Le sol noirci, avec ses braises (lueur : leur couleur ; rouge : combien de temps elles rougeoient).
func _brulure(pos: Vector3, n: Vector3, taille: float, lueur: Color, rouge: float, reste: float) -> MeshInstance3D:
	var m := ShaderMaterial.new()
	m.shader = _shader("brulure")
	m.set_shader_parameter("bruit", bruit)
	m.set_shader_parameter("lueur", Vector3(lueur.r, lueur.g, lueur.b))
	m.set_shader_parameter("braise", 1.0)
	m.set_shader_parameter("efface", 0.0)
	m.set_shader_parameter("graine", _rng.randf() * 10.0)
	var mi := _a_plat(pos, n, taille, m)
	mi.name = "Brulure_magie"
	_marque(marques, MARQUES_MAX, mi, "efface")
	var tw := mi.create_tween()
	mi.set_meta("vie_v219", tw)
	tw.tween_property(m, "shader_parameter/braise", 0.0, rouge).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(maxf(reste - rouge, 0.1))
	tw.tween_property(m, "shader_parameter/efface", 1.0, 4.0)
	tw.tween_callback(mi.queue_free)
	return mi


# =================================================================== la Boule de feu

## La lumière d'un feu palpite (entre deux forces, sans fin : elle s'arrête avec la lampe).
func palpiter(lampe: OmniLight3D, bas: float, haut: float) -> void:
	if lampe == null or not is_instance_valid(lampe) or not lampe.is_inside_tree():
		return
	lampe.light_energy = (bas + haut) * 0.5
	var tw := lampe.create_tween().set_loops()
	tw.tween_property(lampe, "light_energy", haut, 0.06)
	tw.tween_property(lampe, "light_energy", bas, 0.09)
	tw.tween_property(lampe, "light_energy", (bas + haut) * 0.55, 0.05)
	tw.tween_property(lampe, "light_energy", bas * 1.1, 0.08)


## La boule de feu en vol : on remplace sa petite bille et ses points par un cœur en fusion, une chevelure de
## flammes, des braises et une traînée de fumée. (ball : l'objet qui vole ; sa lumière est gardée, renforcée.)
## Si la boule dit où elle va (sa note « dir_v219 »), ses flammes naissent tout le long du chemin parcouru
## entre deux images : la traînée reste continue même quand le jeu tourne lentement.
func habiller_boule(ball: Node3D, k: float = 1.0) -> void:
	if ball == null or not is_instance_valid(ball) or not ball.is_inside_tree():
		return
	_compte("boule")
	var lampe: OmniLight3D = null
	for c in ball.get_children():
		if c is MeshInstance3D or c is CPUParticles3D:
			c.queue_free()
		elif c is OmniLight3D:
			lampe = c
	if lampe == null:
		lampe = OmniLight3D.new()
		lampe.light_color = Color(1.0, 0.55, 0.2)
		lampe.shadow_enabled = false
		ball.add_child(lampe)
	lampe.omni_range = 9.0 * k
	palpiter(lampe, 3.8, 5.6)
	var coeur := MeshInstance3D.new()
	coeur.name = "Coeur_en_fusion"
	coeur.mesh = _sphere
	coeur.scale = Vector3.ONE * 0.4 * k
	coeur.material_override = _mat("boule", "boule_feu", {"bruit": bruit, "intensite": 7.0})
	coeur.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ball.add_child(coeur)
	var objets: Array = [coeur]
	var course: Vector3 = ball.get_meta("dir_v219", Vector3.ZERO)
	var regles_flammes: Dictionary = {"v0": 0.2, "v1": 1.0, "poids": Vector3(0, 1.6, 0), "s0": 0.6 * k, "s1": 0.95 * k,
		"courbe": [[0.0, 1.0], [0.5, 0.8], [1.0, 0.3]], "rayon": 0.1 * k, "hasard": 0.4,
		"couleurs": [Color(1, 1, 1, 1), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0)]}
	if course.length() > 0.01:
		regles_flammes["boite"] = Vector3(0.09 * k, 0.09 * k, 0.3)
	objets.append(_gerbe(Vector3.ZERO, {"n": 40, "vie": 0.4, "continu": true, "portee": 30.0, "vers": course, "decal": -course.normalized() * 0.22 if course.length() > 0.01 else Vector3.ZERO,
		"proc": _proc("boule_flammes:%.2f:%s" % [k, str(course.length() > 0.01)], regles_flammes),
		"mat": _mat("feu_boule", "feu_bouffee", {"bruit": bruit, "intensite": 1.3, "vitesse": 0.9, "duree_chaude": 0.42})}, ball))
	objets.append(_gerbe(Vector3.ZERO, {"n": 22, "vie": 0.9, "continu": true, "portee": 30.0,
		"proc": _proc("boule_braises:%.2f" % k, {"v0": 0.6, "v1": 2.6, "poids": Vector3(0, -2.2, 0), "s0": 0.07, "s1": 0.16, "rayon": 0.12 * k, "aligne": true,
			"tourbillon": 3.0, "grain": 1.6, "emprise": 0.4,
			"couleurs": [Color(1.0, 0.92, 0.6, 1), Color(1.0, 0.5, 0.12, 1), Color(0.9, 0.2, 0.03, 0)]}),
		"mat": _mat_braise()}, ball))
	objets.append(_gerbe(Vector3.ZERO, {"n": 16, "vie": 1.3, "continu": true, "portee": 30.0,
		"proc": _proc("boule_fumee:%.2f" % k, {"v0": 0.1, "v1": 0.5, "poids": Vector3(0, 0.7, 0), "s0": 0.5 * k, "s1": 0.85 * k,
			"courbe": [[0.0, 0.5], [0.4, 1.0], [1.0, 1.7]], "rayon": 0.08 * k,
			"couleurs": [Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.4), Color(1, 1, 1, 0)]}),
		"mat": _mat("fumee_trainee", "fumee_bouffee", {"bruit": bruit, "opacite": 0.45, "lueur_force": 1.0})}, ball))
	dernier["boule"] = objets


## L'explosion de la boule de feu (k : son ampleur ; 1 pour le sort).
func explosion(at: Vector3, k: float = 1.0) -> void:
	_compte("explosion")
	var objets: Array = []
	var sol: Dictionary = _sol(at, 3.0)
	var haut: Vector3 = at + Vector3.UP * 0.25
	# l'éclat et la lumière
	objets.append(_eclat(haut, Color(1.0, 0.72, 0.36), 0.7 * k, 5.0 * k, 0.16, 5.0))
	objets.append(_lumiere(haut + Vector3.UP * 0.4, Color(1.0, 0.6, 0.26), 15.0 * k, 14.0 * k, 0.75))
	# la boule de flammes : elle gonfle, roule, monte
	objets.append(_gerbe(haut, {"n": 14, "vie": 0.95,
		"proc": _proc("explosion_feu:%.2f" % k, {"v0": 2.6 * k, "v1": 7.0 * k, "frein": 6.0, "poids": Vector3(0, 2.6, 0), "s0": 1.7 * k, "s1": 2.7 * k,
			"courbe": [[0.0, 0.4], [0.22, 1.0], [1.0, 1.3]], "rayon": 0.3 * k, "hasard": 0.35,
			"couleurs": [Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0.85), Color(1, 1, 1, 0)]}),
		"mat": _mat("feu_explosion", "feu_bouffee", {"bruit": bruit, "intensite": 1.8, "vitesse": 0.45, "duree_chaude": 0.55})}))
	# les braises : elles jaillissent, l'air chaud les emporte en tourbillons
	objets.append(_gerbe(haut, {"n": 58, "vie": 2.3,
		"proc": _proc("explosion_braises:%.2f" % k, {"ouverture": 85.0, "v0": 4.0 * k, "v1": 13.0 * k, "frein": 1.7, "poids": Vector3(0, -4.2, 0),
			"s0": 0.1, "s1": 0.26, "rayon": 0.3 * k, "aligne": true, "hasard": 0.55,
			"tourbillon": 4.5, "grain": 2.4, "emprise": 0.4,
			"couleurs": [Color(1.0, 0.95, 0.7, 1), Color(1.0, 0.62, 0.18, 1), Color(1.0, 0.35, 0.06, 1), Color(0.8, 0.15, 0.02, 0)]}),
		"mat": _mat_braise()}))
	# la fumée : elle sort du feu et monte en colonne
	objets.append(_gerbe(haut + Vector3.UP * 0.2, {"n": 11, "vie": 3.0, "explo": 0.75,
		"proc": _proc("explosion_fumee:%.2f" % k, {"ouverture": 50.0, "v0": 1.3 * k, "v1": 3.4 * k, "frein": 1.3, "poids": Vector3(0, 0.9, 0),
			"s0": 1.7 * k, "s1": 2.8 * k, "courbe": [[0.0, 0.4], [0.3, 0.95], [1.0, 1.7]], "rayon": 0.45 * k, "hasard": 0.3,
			"tourbillon": 1.2, "grain": 3.5, "emprise": 0.2,
			"couleurs": [Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.75), Color(1, 1, 1, 0)]}),
		"mat": _mat("fumee_explosion", "fumee_bouffee", {"bruit": bruit, "opacite": 0.72, "lueur_force": 2.2})}))
	# au sol : la vague de feu, et la terre noircie où les braises rougeoient
	if bool(sol["ok"]) and at.y - (sol["pos"] as Vector3).y < 2.6:
		_onde(sol["pos"], sol["n"], 10.0 * k, 0.6, Color(1.0, 0.5, 0.16), 3.2)
		objets.append(_brulure(sol["pos"], sol["n"], 3.6 * k, Color(1.0, 0.36, 0.05), 7.0, 24.0))
	dernier["explosion"] = objets


# =================================================================== le Gel

## Le souffle de givre : de « o », vers « dir ».
func givre(o: Vector3, dir: Vector3) -> void:
	_compte("givre")
	var objets: Array = []
	var d: Vector3 = Vector3(dir.x, clampf(dir.y, -0.25, 0.25), dir.z)
	d = d.normalized() if d.length() > 0.01 else Vector3.FORWARD
	var plat: Vector3 = Vector3(d.x, 0.0, d.z).normalized() if Vector2(d.x, d.z).length() > 0.01 else Vector3.FORWARD
	var cote: Vector3 = plat.cross(Vector3.UP).normalized()
	var bouche: Vector3 = o + d * 0.5
	objets.append(_lumiere(o + d * 2.5 + Vector3.UP * 0.4, Color(0.62, 0.84, 1.0), 7.0, 12.0, 0.9))
	objets.append(_eclat(bouche, Color(0.7, 0.88, 1.0), 0.4, 2.4, 0.2, 5.0))
	# la brume glacée : un cône qui file, s'étale et s'enroule (les règles dépendent de la direction : une
	# copie par souffle)
	var regles_brume: ParticleProcessMaterial = _proc("givre_brume", {"ouverture": 19.0, "v0": 9.0, "v1": 17.5, "frein": 7.5, "poids": Vector3(0, -0.5, 0),
		"s0": 0.9, "s1": 1.6, "courbe": [[0.0, 0.3], [0.35, 1.0], [1.0, 2.0]], "rayon": 0.15, "hasard": 0.3,
		"tourbillon": 1.6, "grain": 3.0, "emprise": 0.22,
		"couleurs": [Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)]}).duplicate()
	regles_brume.direction = d
	objets.append(_gerbe(bouche, {"n": 34, "vie": 1.3, "explo": 0.9, "proc": regles_brume, "mat": _mat_brume()}))
	# quelques éclats de glace filent, pointe en avant
	var regles_eclats: ParticleProcessMaterial = _proc("givre_eclats", {"ouverture": 17.0, "v0": 10.0, "v1": 19.0, "frein": 1.6, "poids": Vector3(0, -5.0, 0),
		"s0": 0.6, "s1": 1.3, "rayon": 0.12, "aligne": true, "hasard": 0.4, "tourbillon": 1.5, "grain": 2.5, "emprise": 0.15}).duplicate()
	regles_eclats.direction = d
	objets.append(_gerbe(bouche, {"n": 18, "vie": 0.9, "explo": 0.85, "mesh": _eclat_glace, "proc": regles_eclats, "mat": matiere_glace()}))
	# la poussière de givre : des paillettes qui restent en l'air, tournoient, scintillent, retombent
	var regles_paillettes: ParticleProcessMaterial = _proc("givre_paillettes", {"ouverture": 24.0, "v0": 4.0, "v1": 13.0, "frein": 6.0, "poids": Vector3(0, -0.7, 0),
		"s0": 0.06, "s1": 0.15, "rayon": 0.2, "hasard": 0.5, "tourbillon": 3.5, "grain": 2.0, "emprise": 0.5,
		"couleurs": [Color(0.92, 0.98, 1.0, 1), Color(0.72, 0.9, 1.0, 1), Color(0.6, 0.8, 1.0, 0)]}).duplicate()
	regles_paillettes.direction = d
	objets.append(_gerbe(bouche, {"n": 48, "vie": 2.6, "explo": 0.8, "proc": regles_paillettes, "mat": _mat_paillette()}))
	# les bouquets de cristaux : ils jaillissent en éventail, de proche en proche, jamais alignés
	var bouquets: Array = []
	for i in 8:
		var loin_b: float = 1.5 + float(i) * 0.82 + _rng.randf_range(-0.3, 0.3)
		var pb: Vector3 = o + plat * loin_b + cote * _rng.randf_range(-1.0, 1.0) * (0.35 + loin_b * 0.3)
		var sol_b: Dictionary = _sol(pb + Vector3.UP * 0.5, 4.5)
		if not bool(sol_b["ok"]):
			continue
		bouquets.append(_cristaux(sol_b["pos"], sol_b["n"], _rng.randf_range(0.75, 1.3) * (0.85 + loin_b * 0.05), loin_b / 15.0, _rng.randf_range(1.0, 1.5), plat))
	objets.append_array(bouquets)
	# le givre prend sur le sol, de proche en proche
	var plaques: Array = []
	for i in 10:
		var loin: float = 1.5 + float(i) * 0.78
		var p: Vector3 = o + plat * loin + cote * _rng.randf_range(-1.0, 1.0) * loin * 0.3
		var sol: Dictionary = _sol(p + Vector3.UP * 0.5, 4.5)
		if not bool(sol["ok"]):
			continue
		plaques.append(_plaque_givre(sol["pos"], sol["n"], _rng.randf_range(2.0, 3.2), loin / 15.0))
	objets.append_array(plaques)
	dernier["givre"] = objets
	dernier["givre_plaques"] = plaques
	dernier["givre_bouquets"] = bouquets


## Un bouquet de cristaux qui jaillit du sol (après « retard »), tient « tient » secondes, puis vole en
## poussière. « fuit » : il penche un peu dans ce sens (le souffle l'a couché).
func _cristaux(pos: Vector3, n: Vector3, taille: float, retard: float, tient: float, fuit: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Cristaux_magie"
	mi.mesh = bouquet()
	mi.material_override = matiere_glace()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var y: Vector3 = n.normalized()
	if fuit.length() > 0.01:
		y = (y + fuit.normalized() * 0.22).normalized()
	var x: Vector3 = y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var z: Vector3 = x.cross(y).normalized()
	mi.global_transform = Transform3D(Basis(x, y, z).rotated(y, _rng.randf() * TAU), pos)
	mi.scale = Vector3(taille * 0.5, 0.01, taille * 0.5)
	var tw := mi.create_tween()
	tw.tween_interval(maxf(retard, 0.01))
	tw.tween_property(mi, "scale", Vector3.ONE * taille, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(tient)
	tw.tween_callback(_briser.bind(mi, taille))
	tw.tween_property(mi, "scale", Vector3(taille * 1.08, taille * 0.02, taille * 1.08), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(mi.queue_free)
	return mi


## Le bouquet vole en poussière : des paillettes qui tournoient, quelques éclats.
func _briser(mi: Variant, taille: float) -> void:
	if mi == null or not is_instance_valid(mi) or not is_inside_tree():
		return
	var at: Vector3 = (mi as Node3D).global_position + Vector3.UP * taille * 0.4
	_gerbe(at, {"n": 16, "vie": 1.7,
		"proc": _proc("brise_paillettes", {"v0": 0.6, "v1": 2.6, "frein": 1.5, "poids": Vector3(0, -1.2, 0), "s0": 0.05, "s1": 0.13, "rayon": 0.3, "hasard": 0.5,
			"tourbillon": 2.5, "grain": 1.6, "emprise": 0.45,
			"couleurs": [Color(0.92, 0.98, 1.0, 1), Color(0.72, 0.9, 1.0, 1), Color(0.6, 0.8, 1.0, 0)]}),
		"mat": _mat_paillette()})
	_gerbe(at, {"n": 7, "vie": 0.8, "mesh": _eclat_glace,
		"proc": _proc("brise_eclats", {"dir": Vector3.UP, "ouverture": 80.0, "v0": 1.5, "v1": 4.0, "poids": Vector3(0, -9.0, 0), "s0": 0.5, "s1": 1.0, "rayon": 0.2, "aligne": true}),
		"mat": matiere_glace()})


## Une plaque de givre : elle pousse (après « retard »), scintille une dizaine de secondes, fond.
func _plaque_givre(pos: Vector3, n: Vector3, taille: float, retard: float) -> MeshInstance3D:
	var m := ShaderMaterial.new()
	m.shader = _shader("givre_sol")
	m.set_shader_parameter("cristaux", cristaux)
	m.set_shader_parameter("bruit", bruit)
	m.set_shader_parameter("pousse", 0.0)
	m.set_shader_parameter("fonte", 0.0)
	m.set_shader_parameter("graine", _rng.randf() * 10.0)
	var mi := _a_plat(pos, n, taille, m)
	mi.name = "Givre_magie"
	_marque(givres, GIVRES_MAX, mi, "fonte")
	var tw := mi.create_tween()
	mi.set_meta("vie_v219", tw)
	tw.tween_interval(maxf(retard, 0.01))
	tw.tween_property(m, "shader_parameter/pousse", 1.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(9.0)
	tw.tween_property(m, "shader_parameter/fonte", 1.0, 3.5)
	tw.tween_callback(mi.queue_free)
	return mi


# =================================================================== la Foudre

## Un tracé d'éclair de a à b : on coupe chaque tronçon en deux en poussant son milieu de côté, encore et
## encore (l'écart diminue de moitié à chaque fois). Il est brisé à toutes les échelles, comme un vrai, et
## jamais deux fois le même. rugosite : l'écart du premier pli, par rapport à la longueur.
func _trace(a: Vector3, b: Vector3, rugosite: float, niveaux: int) -> PackedVector3Array:
	var pts := PackedVector3Array([a, b])
	var ecart: float = a.distance_to(b) * rugosite
	for niveau in niveaux:
		var suite := PackedVector3Array()
		for i in range(pts.size() - 1):
			var p0: Vector3 = pts[i]
			var p1: Vector3 = pts[i + 1]
			var axe: Vector3 = p1 - p0
			var lg: float = axe.length()
			axe = axe / lg if lg > 1e-5 else Vector3.FORWARD
			var s1: Vector3 = axe.cross(Vector3.UP if absf(axe.y) < 0.9 else Vector3.RIGHT).normalized()
			var s2: Vector3 = axe.cross(s1)
			var ang: float = _rng.randf() * TAU
			suite.append(p0)
			suite.append((p0 + p1) * 0.5 + (s1 * cos(ang) + s2 * sin(ang)) * ecart * _rng.randf_range(0.25, 1.0))
		suite.append(pts[pts.size() - 1])
		pts = suite
		ecart *= 0.5
	return pts


## Combien de fois couper un tracé de cette longueur (pour des tronçons d'une dizaine de centimètres).
func _niveaux(lg: float) -> int:
	return clampi(int(log(maxf(lg, 0.1) / 0.1) / log(2.0)), 3, 6)


## D'où l'on regarde (les rubans font face au regard).
func _oeil(a: Vector3, b: Vector3) -> Vector3:
	var cam: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	return cam.global_position if cam != null else (a + b) * 0.5 + Vector3(0, 3, 8)


func _rubans_debut() -> void:
	_tv.clear()
	_tn.clear()
	_tuv.clear()
	_tuv2.clear()
	_tc.clear()
	_ti.clear()


## Ajoute un ruban le long de ces points au maillage en cours. large : sa largeur au départ ; il s'effile
## jusqu'à « bout » fois cette largeur. tremble : de combien ses points glissent de côté en ondulant (m) ;
## « tenu » : il est tenu aux deux bouts (un éclair), sinon seulement à son départ (une branche).
func _ruban(pts: PackedVector3Array, large: float, bout: float, oeil: Vector3, col: Color, tremble: float, tenu: bool) -> void:
	var n: int = pts.size()
	if n < 2:
		return
	var base: int = _tv.size()
	var phase: float = _rng.randf()
	for i in n:
		var k: float = float(i) / (n - 1)
		var tangente: Vector3 = pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]
		var cote: Vector3 = tangente.cross(oeil - pts[i])
		var lc: float = cote.length()
		cote = cote / lc if lc > 1e-6 else Vector3.UP
		var w: float = large * 0.5 * lerpf(1.0, bout, k)
		var amp: float = tremble * (sin(k * PI) if tenu else minf(k * 3.0, 1.0))
		_tv.append(pts[i] - cote * w)
		_tv.append(pts[i] + cote * w)
		_tn.append(cote)
		_tn.append(cote)
		_tuv.append(Vector2(0.0, k))
		_tuv.append(Vector2(1.0, k))
		_tuv2.append(Vector2(amp, phase))
		_tuv2.append(Vector2(amp, phase))
		_tc.append(col)
		_tc.append(col)
	for i in range(n - 1):
		var q: int = base + i * 2
		_ti.append(q)
		_ti.append(q + 1)
		_ti.append(q + 3)
		_ti.append(q)
		_ti.append(q + 3)
		_ti.append(q + 2)


func _rubans_fin() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if _tv.size() < 3:
		return mesh
	var tableaux: Array = []
	tableaux.resize(Mesh.ARRAY_MAX)
	tableaux[Mesh.ARRAY_VERTEX] = _tv
	tableaux[Mesh.ARRAY_NORMAL] = _tn
	tableaux[Mesh.ARRAY_TEX_UV] = _tuv
	tableaux[Mesh.ARRAY_TEX_UV2] = _tuv2
	tableaux[Mesh.ARRAY_COLOR] = _tc
	tableaux[Mesh.ARRAY_INDEX] = _ti
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, tableaux)
	return mesh


## Une hélice autour d'un tracé : le filament qui s'enroule autour de l'éclair (tours : combien de tours,
## le signe donne le sens). Elle suit le tracé lissé : une courbe souple.
func _helice(tronc: PackedVector3Array, rayon: float, tours: float, phase: float) -> PackedVector3Array:
	var n: int = tronc.size()
	var pts := PackedVector3Array()
	var axe: Vector3 = (tronc[n - 1] - tronc[0]).normalized()
	var s1: Vector3 = axe.cross(Vector3.UP if absf(axe.y) < 0.9 else Vector3.RIGHT).normalized()
	var s2: Vector3 = axe.cross(s1)
	for i in n:
		var k: float = float(i) / (n - 1)
		var centre := Vector3.ZERO
		var combien: int = 0
		for j in range(maxi(i - 3, 0), mini(i + 4, n)):
			centre += tronc[j]
			combien += 1
		centre /= float(combien)
		var ang: float = phase + k * tours * TAU
		pts.append(centre + (s1 * cos(ang) + s2 * sin(ang)) * rayon * (0.2 + 0.8 * sin(k * PI)))
	return pts


## Le maillage d'un éclair de a à b : le tronc, brisé à toutes les échelles ; ses branches, qui s'en écartent
## et se ramifient ; et (filaments) deux filaments violets qui s'enroulent autour de lui.
func _mesh_eclair(a: Vector3, b: Vector3, gros: float, branches: int, filaments: bool) -> ArrayMesh:
	var oeil: Vector3 = _oeil(a, b)
	var lg: float = a.distance_to(b)
	_rubans_debut()
	var tronc: PackedVector3Array = _trace(a, b, 0.13, _niveaux(lg))
	_ruban(tronc, 0.46 * gros, 0.8, oeil, Color(1, 1, 1, 1), 0.14 * gros, true)
	var n: int = tronc.size()
	for br in branches:
		var i0: int = _rng.randi_range(maxi(n / 8, 1), maxi(n * 7 / 8, 1))
		var depart: Vector3 = tronc[i0]
		var tangente: Vector3 = (tronc[mini(i0 + 2, n - 1)] - tronc[maxi(i0 - 2, 0)]).normalized()
		var vers: Vector3 = (tangente + Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-0.7, 0.9), _rng.randf_range(-1.0, 1.0)) * 0.85).normalized()
		var long: float = clampf(lg * _rng.randf_range(0.14, 0.34), 0.5, 3.6) * (0.5 + 0.5 * gros)
		var branche: PackedVector3Array = _trace(depart, depart + vers * long, 0.2, _niveaux(long))
		_ruban(branche, 0.24 * gros, 0.08, oeil, Color(0.9, 0.94, 1.0, 0.85), 0.1 * gros, false)
		if _rng.randf() < 0.65 and branche.size() > 4:
			var d2: Vector3 = branche[_rng.randi_range(branche.size() / 3, branche.size() * 2 / 3)]
			var v2: Vector3 = (vers + Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * 0.9).normalized()
			_ruban(_trace(d2, d2 + v2 * long * 0.5, 0.22, _niveaux(long * 0.5)), 0.14 * gros, 0.05, oeil, Color(0.82, 0.88, 1.0, 0.7), 0.07 * gros, false)
	if filaments and lg > 1.5:
		for f in 2:
			var sens: float = 1.0 if f == 0 else -1.0
			_ruban(_helice(tronc, _rng.randf_range(0.16, 0.26) * gros, sens * _rng.randf_range(1.5, 3.0) * clampf(lg / 8.0, 0.5, 1.6), _rng.randf() * TAU),
				0.09 * gros, 0.5, oeil, Color(0.8, 0.6, 1.0, 0.7), 0.05 * gros, true)
	return _rubans_fin()


## Pose un maillage d'éclair dans le monde, avec sa matière vivante.
func _poser_eclair(mesh: ArrayMesh, force: float, intensite: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Eclair_magie"
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := ShaderMaterial.new()
	m.shader = _shader("eclair")
	m.set_shader_parameter("bruit", bruit)
	m.set_shader_parameter("force", force)
	m.set_shader_parameter("intensite", intensite)
	mi.material_override = m
	# (ses points glissent de côté en ondulant : sa boîte doit être un peu plus large que son maillage)
	mi.extra_cull_margin = 1.5
	mi.mesh = mesh
	add_child(mi)
	mi.global_position = Vector3.ZERO
	return mi


func _eteindre_eclair(mi: MeshInstance3D, duree: float) -> void:
	var tw := mi.create_tween()
	tw.tween_property(mi.material_override, "shader_parameter/force", 0.0, duree)
	tw.tween_callback(mi.queue_free)


## Un éclair de a à b : il ondule sans cesse, change une fois de tracé, laisse une poussière électrique sur
## son passage, puis s'éteint (un tiers de seconde en tout).
func eclair(a: Vector3, b: Vector3, gros: float = 1.0) -> void:
	_compte("eclair")
	var lg: float = a.distance_to(b)
	var branches: int = 3 + int(lg / 4.0)
	var mi: MeshInstance3D = _poser_eclair(_mesh_eclair(a, b, gros, branches, true), 1.0, 5.0)
	dernier["eclair"] = [mi]
	_lumiere(a.lerp(b, 0.5), Color(0.68, 0.76, 1.0), 6.0 * gros, maxf(lg * 0.9, 6.0), 0.32)
	if lg > 1.2:
		_gerbe(a.lerp(b, 0.5), {"n": clampi(int(lg * 3.0), 8, 30), "vie": 1.0, "vers": b - a,
			"proc": _proc("eclair_poussiere:%d" % int(lg), {"boite": Vector3(0.22, 0.22, lg * 0.5), "v0": 0.2, "v1": 1.5, "poids": Vector3(0, 0.5, 0), "s0": 0.05, "s1": 0.14, "hasard": 0.5,
				"tourbillon": 3.0, "grain": 1.5, "emprise": 0.5,
				"couleurs": [Color(1, 1, 1, 1), Color(0.7, 0.8, 1.0, 1), Color(0.6, 0.45, 1.0, 0)]}),
			"mat": _mat_etincelle_foudre()})
	_vivre(mi, a, b, gros, branches)


func _vivre(mi: MeshInstance3D, a: Vector3, b: Vector3, gros: float, branches: int) -> void:
	await get_tree().create_timer(0.07).timeout
	if not is_instance_valid(mi):
		return
	mi.mesh = _mesh_eclair(a, b, gros * 0.9, maxi(branches - 1, 1), true)
	(mi.material_override as ShaderMaterial).set_shader_parameter("force", 0.8)
	await get_tree().create_timer(0.06).timeout
	if not is_instance_valid(mi):
		return
	_eteindre_eclair(mi, 0.16)


## La foudre frappe ici : l'éclat qui éclaire tout le décor, la poussière électrique qui tournoie, la vague
## au sol, les arcs qui rampent encore, la marque.
func frappe_foudre(at: Vector3) -> void:
	_compte("frappe")
	var objets: Array = []
	objets.append(_eclat(at, Color(0.78, 0.87, 1.0), 0.9, 6.0, 0.16, 6.0))
	objets.append(_lumiere(at + Vector3.UP * 0.5, Color(0.75, 0.84, 1.0), 16.0, 16.0, 0.4))
	# (le décor entier s'éclaire un instant, comme sous un vrai éclair)
	objets.append(_lumiere(at + Vector3.UP * 7.0, Color(0.8, 0.87, 1.0), 5.0, 46.0, 0.14))
	objets.append(_gerbe(at + Vector3.UP * 0.2, {"n": 48, "vie": 1.1,
		"proc": _proc("foudre_poussiere", {"ouverture": 90.0, "v0": 2.5, "v1": 9.0, "frein": 4.5, "poids": Vector3(0, -1.5, 0), "s0": 0.06, "s1": 0.17, "rayon": 0.2, "hasard": 0.5,
			"tourbillon": 5.0, "grain": 1.8, "emprise": 0.55,
			"couleurs": [Color(1, 1, 1, 1), Color(0.75, 0.85, 1.0, 1), Color(0.6, 0.45, 1.0, 0)]}),
		"mat": _mat_etincelle_foudre()}))
	var sol: Dictionary = _sol(at, 3.0)
	if bool(sol["ok"]) and at.y - (sol["pos"] as Vector3).y < 2.6:
		_onde(sol["pos"], sol["n"], 7.0, 0.45, Color(0.55, 0.7, 1.0), 4.0)
		objets.append(_brulure(sol["pos"], sol["n"], 1.9, Color(0.6, 0.78, 1.0), 2.5, 16.0))
	dernier["frappe"] = objets
	arcs(at, 8, 1.8)


## Un arc court de a à b, qui ondule et s'éteint aussitôt.
func _arc(a: Vector3, b: Vector3, gros: float, force: float = 0.8) -> MeshInstance3D:
	var mi: MeshInstance3D = _poser_eclair(_mesh_eclair(a, b, gros, 1, false), force, 4.5)
	mi.name = "Arc_magie"
	_eteindre_eclair(mi, 0.12)
	return mi


## Un arc qui rampe sur le sol en se tordant, depuis « centre » (normale : celle du sol).
func _rampant(centre: Vector3, normale: Vector3, long: float) -> MeshInstance3D:
	var y: Vector3 = normale.normalized()
	var x: Vector3 = y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var z: Vector3 = x.cross(y).normalized()
	var ang: float = _rng.randf() * TAU
	var courbe: float = _rng.randf_range(-1.8, 1.8)
	var p: Vector3 = centre + y * 0.08 + (x * cos(ang) + z * sin(ang)) * 0.12
	var pts := PackedVector3Array()
	var pas: float = long / 14.0
	for i in 15:
		pts.append(p + y * _rng.randf_range(0.0, 0.07))
		ang += courbe / 14.0 + _rng.randf_range(-0.4, 0.4)
		p += (x * cos(ang) + z * sin(ang)) * pas
	var oeil: Vector3 = _oeil(centre, p)
	_rubans_debut()
	_ruban(pts, 0.2, 0.06, oeil, Color(0.88, 0.92, 1.0, 0.9), 0.06, false)
	# une brindille qui part de son milieu
	var depart: Vector3 = pts[_rng.randi_range(4, 9)]
	var a2: float = ang + _rng.randf_range(0.6, 1.4) * (1.0 if _rng.randf() < 0.5 else -1.0)
	_ruban(_trace(depart, depart + (x * cos(a2) + z * sin(a2)) * long * 0.4, 0.2, 3), 0.11, 0.05, oeil, Color(0.8, 0.86, 1.0, 0.75), 0.04, false)
	var mi: MeshInstance3D = _poser_eclair(_rubans_fin(), 0.85, 4.5)
	mi.name = "Arc_magie"
	_eteindre_eclair(mi, 0.16)
	return mi


## Des arcs qui courent encore autour d'un point (n arcs, un toutes les 6 centièmes de seconde) : sur le sol
## quand il est là (ils rampent en se tordant), dans l'air sinon.
func arcs(at: Vector3, n: int = 6, rayon: float = 1.6) -> void:
	_compte("arcs")
	var sol: Dictionary = _sol(at, 3.0)
	var au_sol: bool = bool(sol["ok"]) and at.y - (sol["pos"] as Vector3).y < 1.6
	for i in n:
		await get_tree().create_timer(0.06).timeout
		if not is_inside_tree():
			return
		if au_sol and i % 3 != 2:
			_rampant(sol["pos"], sol["n"], rayon * _rng.randf_range(0.8, 1.7))
		else:
			var a: Vector3 = at + Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(0.0, 0.4), _rng.randf_range(-0.3, 0.3)) * rayon
			var b: Vector3 = at + Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(0.0, 0.8), _rng.randf_range(-1.0, 1.0)) * rayon
			_arc(a, b, 0.4)


# =================================================================== sur l'ennemi

## L'ennemi prend feu : de vraies flammes l'enveloppent, des braises s'en échappent en tournoyant, une fumée
## monte. Renvoie les attaches posées sur lui (les détruire éteint le feu, en douceur). r, h : sa largeur,
## sa hauteur.
func embraser(m: Node3D, r: float, h: float) -> Array:
	if m == null or not is_instance_valid(m) or not m.is_inside_tree():
		return []
	_compte("embrase")
	var gros: float = clampf(r * 1.6, 0.7, 2.4)
	var cle: String = "%.1f:%.1f" % [r, h]
	var boite := Vector3(r, h * 0.45, r)
	var jets: Array = []
	var attaches: Array = []
	for p in [
		# les flammes
		{"n": clampi(int(20.0 + r * h * 12.0), 22, 48), "vie": 0.8, "continu": true, "portee": 40.0, "decal": Vector3.UP * h * 0.45,
			"proc": _proc("embrase_feu:" + cle, {"dir": Vector3.UP, "ouverture": 24.0, "v0": 0.3, "v1": 1.2, "poids": Vector3(0, 2.4, 0), "s0": 0.55 * gros, "s1": 0.95 * gros,
				"courbe": [[0.0, 0.55], [0.3, 1.0], [1.0, 0.45]], "boite": boite,
				"couleurs": [Color(1, 1, 1, 1), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0)]}),
			"mat": _mat("feu_ennemi", "feu_bouffee", {"bruit": bruit, "intensite": 1.4, "vitesse": 0.85, "duree_chaude": 0.6})},
		# les braises
		{"n": 18, "vie": 1.5, "continu": true, "portee": 40.0, "decal": Vector3.UP * h * 0.8,
			"proc": _proc("embrase_braises:" + cle, {"dir": Vector3.UP, "ouverture": 50.0, "v0": 0.6, "v1": 2.2, "poids": Vector3(0, 0.9, 0), "s0": 0.06, "s1": 0.14, "rayon": r * 0.7, "aligne": true,
				"tourbillon": 3.0, "grain": 1.5, "emprise": 0.45,
				"couleurs": [Color(1.0, 0.92, 0.6, 1), Color(1.0, 0.5, 0.12, 1), Color(0.9, 0.2, 0.03, 0)]}),
			"mat": _mat_braise()},
		# la fumée
		{"n": 9, "vie": 2.0, "continu": true, "portee": 40.0, "decal": Vector3.UP * (h + 0.3),
			"proc": _proc("embrase_fumee:" + cle, {"dir": Vector3.UP, "ouverture": 18.0, "v0": 0.6, "v1": 1.4, "poids": Vector3(0, 0.8, 0), "s0": 0.8 * gros, "s1": 1.3 * gros,
				"courbe": [[0.0, 0.4], [0.4, 1.0], [1.0, 1.8]], "rayon": r * 0.5, "tourbillon": 1.0, "grain": 3.0, "emprise": 0.2,
				"couleurs": [Color(1, 1, 1, 0.6), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)]}),
			"mat": _mat("fumee_ennemi", "fumee_bouffee", {"bruit": bruit, "opacite": 0.45, "lueur_force": 1.0})}]:
		jets.append(_gerbe(Vector3.ZERO, p, m))
		attaches.append(p["suivi"])
	dernier["embrase"] = jets
	return attaches


## L'ennemi est pris par la glace : un souffle de brume blanche, des éclats, une poussière de givre qui
## tournoie, le givre à ses pieds.
func saisir_glace(at: Vector3, r: float, h: float) -> void:
	_compte("saisi")
	var gros: float = clampf(r * 1.4 + h * 0.3, 0.7, 2.6)
	var objets: Array = []
	objets.append(_eclat(at, Color(0.75, 0.9, 1.0), 0.5 * gros, 3.4 * gros, 0.22, 5.0))
	objets.append(_lumiere(at, Color(0.6, 0.82, 1.0), 5.0, 8.0, 0.5))
	objets.append(_gerbe(at, {"n": 14, "vie": 1.1,
		"proc": _proc("saisi_brume:%.1f" % gros, {"v0": 1.4, "v1": 3.6, "frein": 3.0, "poids": Vector3(0, 0.3, 0), "s0": 0.9 * gros, "s1": 1.5 * gros,
			"courbe": [[0.0, 0.4], [0.35, 1.0], [1.0, 1.8]], "rayon": r * 0.8, "tourbillon": 1.4, "grain": 3.0, "emprise": 0.2,
			"couleurs": [Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0)]}),
		"mat": _mat_brume()}))
	objets.append(_gerbe(at, {"n": 12, "vie": 0.8, "mesh": _eclat_glace,
		"proc": _proc("saisi_eclats:%.1f" % gros, {"v0": 2.5, "v1": 6.5, "frein": 1.0, "poids": Vector3(0, -8.0, 0), "s0": 0.5, "s1": 1.2, "rayon": r * 0.8, "aligne": true, "hasard": 0.4}),
		"mat": matiere_glace()}))
	objets.append(_gerbe(at, {"n": 26, "vie": 2.2,
		"proc": _proc("saisi_paillettes:%.1f" % gros, {"v0": 0.8, "v1": 3.4, "frein": 2.0, "poids": Vector3(0, -0.6, 0), "s0": 0.05, "s1": 0.14, "rayon": r, "hasard": 0.5,
			"tourbillon": 3.0, "grain": 1.8, "emprise": 0.5,
			"couleurs": [Color(0.92, 0.98, 1.0, 1), Color(0.72, 0.9, 1.0, 1), Color(0.6, 0.8, 1.0, 0)]}),
		"mat": _mat_paillette()}))
	var sol: Dictionary = _sol(at, 4.0)
	if bool(sol["ok"]):
		objets.append(_plaque_givre(sol["pos"], sol["n"], r * 2.6 + 1.8, 0.0))
	dernier["saisi"] = objets


## Un arc qui s'enroule autour d'un corps (au pied « base », de rayon r, haut de h) : une courbe, pas une
## corde tendue.
func _arc_sur_corps(base: Vector3, r: float, h: float) -> void:
	var a1: float = _rng.randf() * TAU
	var tour: float = _rng.randf_range(0.9, 2.6) * (1.0 if _rng.randf() < 0.5 else -1.0)
	var y1: float = _rng.randf_range(0.1, 1.05) * h
	var y2: float = _rng.randf_range(0.1, 1.05) * h
	var pts := PackedVector3Array()
	for j in 11:
		var k: float = float(j) / 10.0
		var ang: float = a1 + tour * k
		var rr: float = r * _rng.randf_range(0.95, 1.12)
		pts.append(base + Vector3(cos(ang) * rr, lerpf(y1, y2, k) + _rng.randf_range(-0.04, 0.04) * h, sin(ang) * rr))
	_rubans_debut()
	_ruban(pts, 0.17, 0.1, _oeil(base, base + Vector3.UP * h), Color(0.88, 0.92, 1.0, 0.9), 0.05, true)
	var mi: MeshInstance3D = _poser_eclair(_rubans_fin(), 0.85, 4.5)
	mi.name = "Arc_magie"
	_eteindre_eclair(mi, 0.13)


## L'ennemi électrisé : des arcs s'enroulent autour de son corps tant que dure sa secousse.
func electriser(m: Node3D, r: float, h: float, duree: float = 0.7) -> void:
	if m == null or not is_instance_valid(m):
		return
	_compte("electrise")
	var l := OmniLight3D.new()
	l.name = "Lueur_electrise"
	l.light_color = Color(0.7, 0.82, 1.0)
	l.light_energy = 3.0
	l.omni_range = 3.0 + r * 2.0
	l.shadow_enabled = false
	m.add_child(l)
	l.position = Vector3.UP * h * 0.6
	var tw := l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, duree + 0.15)
	tw.tween_callback(l.queue_free)
	var n: int = clampi(int(duree / 0.06), 3, 16)
	for i in n:
		if not is_instance_valid(m) or not m.is_inside_tree() or not is_inside_tree():
			return
		for deux in 2:
			_arc_sur_corps(m.global_position, r * 1.1, h)
		await get_tree().create_timer(0.06).timeout


## Le feu rencontre la glace : un nuage de vapeur qui monte d'un coup en s'enroulant, une vague blanche au sol.
func vapeur(at: Vector3) -> void:
	_compte("vapeur")
	var objets: Array = []
	objets.append(_gerbe(at, {"n": 18, "vie": 1.7, "explo": 0.8,
		"proc": _proc("vapeur", {"dir": Vector3.UP, "ouverture": 65.0, "v0": 1.5, "v1": 4.2, "frein": 1.6, "poids": Vector3(0, 1.7, 0), "s0": 1.2, "s1": 2.3,
			"courbe": [[0.0, 0.4], [0.3, 1.0], [1.0, 1.9]], "rayon": 0.4, "tourbillon": 1.8, "grain": 3.0, "emprise": 0.25,
			"couleurs": [Color(1, 1, 1, 0.85), Color(1, 1, 1, 0.65), Color(1, 1, 1, 0)]}),
		"mat": _mat("vapeur", "fumee_bouffee", {"bruit": bruit, "opacite": 0.58, "vitesse": 0.3,
			"teinte": Vector3(0.74, 0.77, 0.8), "teinte_claire": Vector3(0.97, 0.98, 1.0), "lueur_force": 0.0})}))
	var sol: Dictionary = _sol(at, 3.0)
	if bool(sol["ok"]):
		_onde(sol["pos"], sol["n"], 7.0, 0.5, Color(0.9, 0.95, 1.0), 2.2)
	dernier["vapeur"] = objets


## La glace vole en éclats (la foudre sur un ennemi gelé) : des éclats qui jaillissent, une poussière de
## givre qui tournoie.
func eclats_glace(at: Vector3) -> void:
	_compte("eclats")
	var objets: Array = []
	objets.append(_eclat(at, Color(0.78, 0.9, 1.0), 0.6, 4.0, 0.18, 6.0))
	objets.append(_gerbe(at, {"n": 24, "vie": 1.0, "mesh": _eclat_glace,
		"proc": _proc("eclats_glace", {"dir": Vector3.UP, "ouverture": 110.0, "v0": 4.0, "v1": 10.0, "frein": 0.8, "poids": Vector3(0, -9.8, 0), "s0": 0.6, "s1": 1.5, "rayon": 0.3, "aligne": true, "hasard": 0.4}),
		"mat": matiere_glace()}))
	objets.append(_gerbe(at, {"n": 30, "vie": 2.0,
		"proc": _proc("eclats_paillettes", {"v0": 1.5, "v1": 6.0, "frein": 3.0, "poids": Vector3(0, -0.8, 0), "s0": 0.05, "s1": 0.15, "rayon": 0.3, "hasard": 0.5,
			"tourbillon": 3.5, "grain": 1.8, "emprise": 0.5,
			"couleurs": [Color(0.92, 0.98, 1.0, 1), Color(0.72, 0.9, 1.0, 1), Color(0.6, 0.8, 1.0, 0)]}),
		"mat": _mat_paillette()}))
	objets.append(_gerbe(at, {"n": 9, "vie": 1.0,
		"proc": _proc("eclats_brume", {"v0": 1.5, "v1": 3.5, "frein": 3.0, "poids": Vector3(0, 0.3, 0), "s0": 1.0, "s1": 1.7,
			"courbe": [[0.0, 0.4], [0.35, 1.0], [1.0, 1.8]], "rayon": 0.3,
			"couleurs": [Color(1, 1, 1, 0.8), Color(1, 1, 1, 0.6), Color(1, 1, 1, 0)]}),
		"mat": _mat_brume()}))
	dernier["eclats"] = objets


# =================================================================== la préparation

## Au chargement : chaque matière est montrée une fois, loin sous le monde, pour que la carte graphique
## prépare ses programmes d'avance (sinon le tout premier sort ferait une petite saccade).
var prechauffe: bool = false


func prechauffer() -> void:
	if prechauffe or not is_inside_tree():
		return
	prechauffe = true
	var loin := Vector3(0, -3000, 0)
	explosion(loin)
	givre(loin, Vector3.FORWARD)
	eclair(loin, loin + Vector3(3, 0, 0))
	frappe_foudre(loin)
	var bidon := Node3D.new()
	add_child(bidon)
	bidon.global_position = loin
	habiller_boule(bidon)
	embraser(bidon, 0.5, 1.0)
	saisir_glace(loin, 0.5, 1.0)
	vapeur(loin)
	eclats_glace(loin)
	_cristaux(loin, Vector3.UP, 1.0, 0.0, 0.2)
	_rampant(loin, Vector3.UP, 1.5)
	_arc_sur_corps(loin, 0.5, 1.0)
	get_tree().create_timer(2.0).timeout.connect(bidon.queue_free)
	for k in lances.keys():
		lances[k] = 0
	dernier.clear()
