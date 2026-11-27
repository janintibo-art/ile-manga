extends Node3D
## V217 : de la sauce sur le personnage. Quand on tombe dans la sauce de l'Île Al Dente (le lac, les
## rivières, la Marmite), qu'on passe sous la Cascade Arrabbiata ou qu'une goutte du volcan tombe tout
## près, le personnage en ressort couvert : son corps (sur PC) et ses mains (en VR) prennent une couche de
## sauce brillante, il goutte, il laisse de petites taches derrière lui. Ça s'en va en une minute, ou tout
## de suite si on se rince dans la mer.

const SHADER := "res://shaders/sauce_heros_v217.gdshader"
const DUREE := 60.0                      # secondes pour sécher tout à fait
const RINCE := 1.6                       # secondes dans la mer pour être propre

var main: Node
var pasta: Node
var quantite: float = 0.0                # 0 propre … 1 couvert de la tête aux pieds
var bains: int = 0                       # combien de fois on a été couvert (pour les essais)
var rinces: int = 0
var taches: int = 0
var _mat: ShaderMaterial                 # sur le corps (le motif dans ses UV)
var _mat_mains: ShaderMaterial           # le modèle des mains de la VR (le motif dans le repère de la main)
var _mains: Dictionary = {}              # la main (Node3D) -> sa matière (son repère change à chaque image)
var _habilles: Array = []                # les maillages qui portent la couche
var _cherche_t: float = 0.0
var _gouttes: CPUParticles3D
var _dernier_pas := Vector3.ZERO
var _decals: Array = []
var _dit_t: float = -99.0
var _clock: float = 0.0
var _mouille: bool = false
var _hot_vu: float = 0.0


func setup(main_node: Node, pasta_node: Node) -> void:
	main = main_node
	pasta = pasta_node
	_hot_vu = float(pasta.get("_hot_t")) if pasta != null else 0.0
	_mat = ShaderMaterial.new()
	_mat.shader = load(SHADER)
	_mat.set_shader_parameter("quantite", 0.0)
	_mat.set_shader_parameter("grain", 30.0)
	_mat.set_shader_parameter("espace", 0)
	# (le corps du héros est dessiné avec les objets transparents : la sauce doit passer après lui)
	_mat.render_priority = 20
	_mat_mains = _mat.duplicate()
	_mat_mains.set_shader_parameter("grain", 15.0)
	_mat_mains.set_shader_parameter("epaisseur", 0.0015)
	_mat_mains.set_shader_parameter("espace", 1)
	_gouttes = CPUParticles3D.new()
	_gouttes.name = "Gouttes_de_sauce_v217"
	_gouttes.amount = 14
	_gouttes.lifetime = 0.9
	_gouttes.emitting = false
	_gouttes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_gouttes.emission_box_extents = Vector3(0.22, 0.35, 0.22)
	_gouttes.direction = Vector3.DOWN
	_gouttes.spread = 12.0
	_gouttes.initial_velocity_min = 0.2
	_gouttes.initial_velocity_max = 0.8
	_gouttes.gravity = Vector3(0, -9.8, 0)
	_gouttes.scale_amount_min = 0.5
	_gouttes.scale_amount_max = 1.1
	var gm := SphereMesh.new()
	gm.radius = 0.022
	gm.height = 0.07
	gm.radial_segments = 5
	gm.rings = 2
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.5, 0.05, 0.02)
	gmat.roughness = 0.2
	gm.material = gmat
	_gouttes.mesh = gm
	add_child(_gouttes)


## Le personnage reçoit de la sauce (0 à 1) ; on garde le plus fort.
func couvrir(combien: float, quoi: String = "") -> void:
	var avant: float = quantite
	quantite = clampf(maxf(quantite, combien), 0.0, 1.0)
	if avant < 0.6 and quantite >= 0.6:
		bains += 1
		if pasta != null and pasta.has_method("sfx") and main != null:
			pasta.sfx("splotch", main._player_pos_v27())
		if _clock - _dit_t > 25.0 and pasta != null and pasta.has_method("say"):
			_dit_t = _clock
			var texte: String = "SPLOTCH ! Te voilà couvert de sauce tomate de la tête aux pieds. Ça partira tout seul… ou avec un bon bain de mer."
			if quoi == "cascade":
				texte = "Sous la Cascade Arrabbiata ! Te voilà nappé comme un plat de spaghettis. Ça partira tout seul… ou avec un bon bain de mer."
			pasta.say(texte, 6.0)


func _sauce_a_cote(p: Vector3) -> bool:
	for k in range(9):
		var o: Vector3 = Vector3.ZERO if k == 0 else Vector3(cos(k * TAU / 8.0), 0, sin(k * TAU / 8.0)) * 0.9
		if pasta.in_sauce(p + o):
			return true
	return false


## Les maillages qui prennent la sauce : le corps du héros (sur PC, ce qu'il porte compris : l'arme, le
## sac) et les mains de la VR. Rend [[maillage, matière], …]. Pas les effets (une lueur, un halo, une
## ombre : ce qui ne fait pas d'ombre, ou dont la matière n'est pas opaque, sauf le corps lui-même).
func _maillages() -> Array:
	var out: Array = []
	var racines: Array = []
	var h: Variant = main.get("hero_v28")
	if h != null and (h as Node).get("hero") != null:
		racines.append([(h as Node).get("hero"), _mat])
	# (les mains de la VR, sous les deux manettes : on ne fouille pas tout le monde)
	for manette in [main.get("left_hand"), main.get("right_hand")]:
		if manette == null or not is_instance_valid(manette):
			continue
		var n: Node = (manette as Node).get_node_or_null("Manette_visible")
		if n == null:
			continue
		if not _mains.has(n):
			_mains[n] = _mat_mains.duplicate()
		racines.append([n, _mains[n]])
	for r in racines:
		if r[0] == null or not is_instance_valid(r[0]):
			continue
		var pile: Array = [r[0]]
		while not pile.is_empty():
			var c: Node = pile.pop_back()
			for e in c.get_children():
				pile.append(e)
			if c is MeshInstance3D and (c as MeshInstance3D).is_visible_in_tree() and (c as MeshInstance3D).mesh != null:
				var mi: MeshInstance3D = c
				if mi.skin != null or _solide(mi):
					out.append([mi, r[1]])
	return out


func _solide(mi: MeshInstance3D) -> bool:
	if mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and not mi.name.begins_with("Main") and not (mi.get_parent() != null and str(mi.get_parent().name).begins_with("Main")):
		# (les mains de la VR ne font pas d'ombre : on les garde)
		var ancetre: Node = mi
		var dans_mains: bool = false
		while ancetre != null:
			if str(ancetre.name) == "Manette_visible":
				dans_mains = true
				break
			ancetre = ancetre.get_parent()
		if not dans_mains:
			return false
	for si in range(mi.mesh.get_surface_count()):
		var ma: Material = mi.get_active_material(si)
		if ma is BaseMaterial3D:
			var bm: BaseMaterial3D = ma
			if bm.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA or bm.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED or bm.emission_enabled:
				return false
		elif ma is ShaderMaterial:
			return false
	return true


func _habiller(oui: bool) -> void:
	if oui:
		for mm in _maillages():
			var mi: MeshInstance3D = mm[0]
			if mi.material_overlay == null:
				mi.material_overlay = mm[1]
				_habilles.append(mi)
	else:
		for m in _habilles:
			if is_instance_valid(m) and ((m as MeshInstance3D).material_overlay == _mat or _mains.values().has((m as MeshInstance3D).material_overlay)):
				(m as MeshInstance3D).material_overlay = null
		_habilles.clear()
		_mains.clear()


func _tache(at: Vector3) -> void:
	if pasta == null or pasta.get("_splat_tex") == null:
		return
	var dcl := Decal.new()
	dcl.texture_albedo = pasta.get("_splat_tex")
	var s: float = randf_range(0.28, 0.55)
	dcl.size = Vector3(s, 1.2, s)
	dcl.upper_fade = 0.3
	dcl.lower_fade = 0.3
	dcl.cull_mask = 1
	add_child(dcl)
	dcl.global_position = at + Vector3.UP * 0.2
	dcl.rotation.y = randf() * TAU
	_decals.append({"decal": dcl, "age": 0.0})
	taches += 1
	while _decals.size() > 24:
		var vieux: Dictionary = _decals.pop_front()
		(vieux["decal"] as Decal).queue_free()


func _process(delta: float) -> void:
	if main == null:
		return
	_clock += delta
	var p: Vector3 = main._player_pos_v27()
	# les taches au sol s'effacent
	var j: int = 0
	while j < _decals.size():
		var d: Dictionary = _decals[j]
		d["age"] = float(d["age"]) + delta
		(d["decal"] as Decal).modulate.a = clampf(1.0 - (float(d["age"]) - 30.0) / 10.0, 0.0, 1.0)
		if float(d["age"]) > 40.0:
			(d["decal"] as Decal).queue_free()
			_decals.remove_at(j)
		else:
			j += 1
	# d'où vient la sauce
	if pasta != null and pasta.get("ile") != null:
		if pasta.in_sauce(p):
			couvrir(1.0, "sauce")
		else:
			# (on a mis le pied dedans, le bord nous a retenu : on en a jusqu'aux genoux ; l'île note
			# l'instant dans _hot_t, mais d'autres que le pied du héros peuvent le noter, et au tout début
			# du jeu il vaut 0 : on veut un nouvel instant, et de la sauce juste à côté du pied)
			var hot: float = float(pasta.get("_hot_t"))
			if hot > _hot_vu:
				_hot_vu = hot
				if _sauce_a_cote(p):
					couvrir(0.45, "bord")
		var chute: Array = pasta.get("chute_v217")
		var milieu: Vector3 = p + Vector3.UP * 0.9
		for c in chute:
			var cp: Vector3 = c
			if absf(cp.y - milieu.y) < 1.6 and Vector2(cp.x - milieu.x, cp.z - milieu.z).length() < 1.9:
				couvrir(1.0, "cascade")
				break
	if quantite <= 0.0:
		if not _habilles.is_empty():
			_habiller(false)
			_gouttes.emitting = false
		return
	# la mer rince ; sinon ça sèche tout seul
	var dans_mer: bool = p.y < -0.9 and main.has_method("_height_at") and float(main._height_at(p.x, p.z)) < -0.7 and not (pasta != null and pasta.get("ile") != null and pasta.in_sauce(p))
	if dans_mer:
		if not _mouille:
			_mouille = true
		quantite = maxf(quantite - delta / RINCE, 0.0)
		if quantite <= 0.0:
			rinces += 1
			if pasta != null and pasta.has_method("say"):
				pasta.say("Un bon bain de mer : te voilà propre. (La mer, elle, est un peu plus rouge.)", 4.0)
	else:
		_mouille = false
		quantite = maxf(quantite - delta / DUREE, 0.0)
	_mat.set_shader_parameter("quantite", quantite)
	for mn in _mains:
		if is_instance_valid(mn):
			var mm: ShaderMaterial = _mains[mn]
			mm.set_shader_parameter("quantite", quantite)
			mm.set_shader_parameter("repere", Projection((mn as Node3D).global_transform.affine_inverse()))
	_cherche_t -= delta
	if _cherche_t <= 0.0:
		# (le corps ou les mains peuvent arriver plus tard : on regarde de temps en temps)
		_cherche_t = 2.0
		_habiller(true)
	# il goutte, il laisse des taches en marchant
	_gouttes.emitting = quantite > 0.35
	_gouttes.global_position = p + Vector3.UP * 0.9
	if quantite > 0.4 and not dans_mer and Vector2(p.x - _dernier_pas.x, p.z - _dernier_pas.z).length() > 1.6 - quantite * 0.7:
		_dernier_pas = p
		if main.has_method("_height_at"):
			var sol: float = main._height_at(p.x, p.z)
			if absf(sol - p.y) < 1.2:
				_tache(Vector3(p.x + randf_range(-0.25, 0.25), sol, p.z + randf_range(-0.25, 0.25)))
