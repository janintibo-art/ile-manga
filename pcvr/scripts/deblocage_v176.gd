extends Node
## V176 : le héros ne reste plus jamais coincé (sur PC comme en réalité virtuelle).
##
##  - Pris dans le décor : si le corps du héros est entré dans un meuble, un rocher, le sol (une
##    armoire contre laquelle on a été poussé, la plage sous laquelle on est sorti de l'eau…), il se
##    dégage tout seul, vers la place libre la plus proche.
##  - Coincé dans un recoin : si l'on pousse dans tous les sens sans avancer (entre une armoire et
##    une chaise, entre deux rochers…), il se dégage aussi. (Pousser contre un mur dans un seul sens,
##    ce n'est pas être coincé : on ne bouge pas le héros pour si peu.)
##  - « Me débloquer », dans le menu (Échap, ou le bouton menu de la manette et du casque) : on repart
##    à coup sûr d'une place libre, un peu plus loin (ou du dernier endroit sûr).
##  - En entrant dans une maison, si l'arrivée est encombrée (une table, le tableau de bord d'un bus),
##    on se pose juste à côté.
## Le héros n'est jamais posé là où il n'a pas le droit d'être (main.pied_ok_v176 : la terre ferme,
## l'eau où l'on a pied, la mer où l'on nage, les pontons), ni dans le vide.

var main: Node
## combien de fois le héros a été dégagé (tout seul, à l'arrivée, ou à la demande)
var degages: int = 0
var dernier_motif: String = ""

var _sonde := CapsuleShape3D.new()        # le corps, un peu aminci (on ne compte pas un simple contact)
var _tick: float = 0.0
var _pris_t: float = 0.0
var _echantillons: Array = []              # [position, envie de bouger (direction au sol, ou zéro)]
var _surs: Array = []                      # les derniers endroits sûrs (on y tenait debout, libre)
var _sur_t: float = 0.0
var _repos_t: float = 0.0                  # après un dégagement, on laisse le héros repartir

const PAS: float = 0.1                     # on regarde dix fois par seconde
const PRIS_S: float = 0.5                  # pris dans le décor depuis une demi-seconde : on dégage
const RECOIN_S: float = 2.6                # on pousse en tous sens depuis 2,6 s sans avancer : on dégage
const SURS_MAX: int = 14


func setup(main_node: Node) -> void:
	main = main_node
	name = "Deblocage_v176"
	_sonde.radius = 0.26
	_sonde.height = 1.36


func corps() -> CharacterBody3D:
	if main == null:
		return null
	return main.vr_body if bool(main.xr_active) else main.pc_body


## Le héros peut-il bouger librement en ce moment (pas en menu, pas à bord, pas en train de grimper) ?
func _actif() -> bool:
	if main == null or not bool(main.game_started):
		return false
	if main.game_menu != null and main.game_menu.opened:
		return false
	if main.has_method("virus_open_v96") and main.virus_open_v96():
		return false
	if main.get("inventory_v28") != null and bool(main.inventory_v28.get("opened")):
		return false
	if main.get("dialogue_v31") != null and bool(main.dialogue_v31.get("opened")):
		return false
	var b: CharacterBody3D = corps()
	if b == null or not b.is_inside_tree():
		return false
	if main.get("aeronef_v76") != null and bool(main.aeronef_v76.get("riding")):
		return false
	if main.get("ciel_v54") != null and bool(main.ciel_v54.get("riding")):
		return false
	var az: Node = main.get("azur_v56")
	if az != null and az.get("ferry") != null and az.ferry != null and bool(az.ferry.riding):
		return false
	if main.get("grande_v59") != null and main.grande_v59.has_method("riding") and main.grande_v59.riding():
		return false
	var pe: Node = main.get("perchee_v146")
	if pe != null and pe.get("ile") != null and pe.ile != null and pe.riding():
		return false
	if main.get("boat_v29") != null and bool(main.boat_v29.get("driving")):
		return false
	if main.get("vr_ladder_v33") != null and not (main.vr_ladder_v33 as Dictionary).is_empty():
		return false
	if main.get("jeux_v147") != null and str(main.jeux_v147.get("assis")) != "":
		return false
	var dj: Node = main.get("donjon_v35")
	if dj != null and bool(dj.get("_busy")):
		return false
	var mv: Node = main.get("maisons_v81")
	if mv != null and bool(mv.get("busy")):
		return false
	if not bool(main.xr_active):
		var h: Node = main.get("hero_v28")
		if h != null and not (str(h.state) in ["sol", "air", "nage", "roulade"]):
			return false
	return true


## L'envie de bouger du joueur, en direction au sol (zéro s'il ne pousse pas le stick ni les touches).
func _envie() -> Vector3:
	if bool(main.xr_active):
		var st: Vector2 = main.left_hand.get_vector2("primary")
		if st.length() <= float(main.DEADZONE):
			return Vector3.ZERO
		var cb: Basis = main.xr_camera.global_transform.basis
		var f: Vector3 = -cb.z
		f.y = 0.0
		var r: Vector3 = cb.x
		r.y = 0.0
		return (r.normalized() * st.x + f.normalized() * st.y).normalized()
	var h: Node = main.get("hero_v28")
	if h == null:
		return Vector3.ZERO
	var ax: Vector2 = h._axis()
	if ax.length() < 0.3:
		return Vector3.ZERO
	var rb: Basis = main.pc_root.global_basis
	var d: Vector3 = rb.x * ax.x + rb.z * ax.y
	d.y = 0.0
	return d.normalized()


## Le corps (un peu aminci) est-il entré dans le décor, ici ? (les meubles, les murs, les rochers, le
## sol ; pas les habitants ni les bêtes, qui bougent et s'écartent d'eux-mêmes)
func pris(at: Vector3) -> bool:
	var b: CharacterBody3D = corps()
	if b == null or not b.is_inside_tree():
		return false
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _sonde
	q.collision_mask = b.collision_mask
	q.exclude = [b.get_rid()]
	q.margin = 0.0
	q.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * 0.95)
	for hit in b.get_world_3d().direct_space_state.intersect_shape(q, 6):
		var c: Object = hit.get("collider")
		if c is StaticBody3D and not (c is AnimatableBody3D):
			return true
	return false


## Le héros tiendrait-il là, debout et libre (le vrai corps, avec une petite marge) ?
func libre(at: Vector3) -> bool:
	var b: CharacterBody3D = corps()
	if b == null:
		return false
	var sn: CollisionShape3D = b.get_node_or_null("Capsule_joueur")
	if sn == null:
		return false
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = sn.shape
	q.collision_mask = b.collision_mask
	q.exclude = [b.get_rid()]
	q.margin = 0.03
	q.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * 0.04) * sn.transform
	return b.get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


## Le sol sous (x, z), près de la hauteur y (un plancher, une marche, le terrain) ; INF si rien.
## (« haut » : on regarde d'un peu plus haut : une pente qui monte, le sable au-dessus d'un héros
## enfoncé ; sinon, à hauteur de genou : on ne se pose pas sur une caisse ou une table)
func _sol(x: float, z: float, y: float, haut: bool = false) -> float:
	var b: CharacterBody3D = corps()
	var sp := b.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, y + (1.3 if haut else 0.5), z), Vector3(x, y - 2.2, z), b.collision_mask, [b.get_rid()])
	var hit: Dictionary = sp.intersect_ray(q)
	if hit.is_empty() or float((hit["normal"] as Vector3).y) < 0.65:
		return INF
	return float((hit["position"] as Vector3).y)


## Une place sûre : du sol dessous, le corps libre, et le droit d'y être.
func _place_ok(at: Vector3) -> bool:
	if not libre(at):
		return false
	if main.has_method("pied_ok_v176") and not main.pied_ok_v176(at):
		return false
	return true


## Cherche la place libre la plus proche (à au moins dmin, au plus dmax) autour de p ; INF si rien.
func chercher(p: Vector3, dmin: float = 0.0, dmax: float = 4.0) -> Vector3:
	var mv: Node = main.get("maisons_v81")
	var dedans: bool = mv != null and bool(mv.get("inside")) and mv.R != null
	# d'abord au même niveau (pas sur une caisse ni sur une table) ; sinon un peu plus haut (une pente
	# qui monte, le sable au-dessus d'un héros enfoncé)
	for haut in [false, true]:
		for r in [0.0, 0.3, 0.55, 0.8, 1.1, 1.45, 1.9, 2.5, 3.2, 4.0, 5.0, 6.5]:
			if r < dmin - 0.01 or r > dmax + 0.01:
				continue
			var n: int = 1 if r == 0.0 else 16
			for k in range(n):
				var a: float = TAU * float(k) / float(n)
				var x: float = p.x + cos(a) * r
				var z: float = p.z + sin(a) * r
				# dans une maison, on reste dans la pièce
				if dedans:
					var l: Vector3 = Vector3(x, 0, z) - mv.R.P(0, 0, 0)
					if absf(l.x) > mv.R.W * 0.5 - 0.35 or absf(l.z) > mv.R.D * 0.5 - 0.35:
						continue
				var y: float = _sol(x, z, p.y, haut)
				if y == INF:
					continue
				var at := Vector3(x, y + 0.02, z)
				if _place_ok(at):
					return at
	return Vector3.INF


## Dégage le héros. « force » (le menu) : on part d'une place libre un peu plus loin (le recoin où l'on
## était ne compte pas), ou du dernier endroit sûr ; sinon, la place libre la plus proche.
func liberer(force: bool = false, motif: String = "") -> bool:
	var b: CharacterBody3D = corps()
	if b == null or not b.is_inside_tree():
		return false
	var p: Vector3 = b.global_position
	var cible: Vector3 = chercher(p, 0.9 if force else 0.0, 4.0)
	if cible == Vector3.INF:
		for i in range(_surs.size() - 1, -1, -1):
			var s: Vector3 = _surs[i]
			if s.distance_to(p) < 60.0 and (not force or s.distance_to(p) > 0.9) and _place_ok(s):
				cible = s
				break
	if cible == Vector3.INF:
		cible = chercher(p, 4.5, 6.5)
	var mv: Node = main.get("maisons_v81")
	if cible == Vector3.INF and mv != null and bool(mv.get("inside")) and mv.R != null:
		# dans une maison : la porte, de l'intérieur
		cible = mv.R.P(mv.R.door_x, 0.05, mv.R.D * 0.5 - 1.1)
	if cible == Vector3.INF:
		if force:
			main._show_message_v28("Pas de place libre tout près… Essaie de sauter, ou de revenir sur tes pas.")
		return false
	var face: Vector3 = Vector3.FORWARD
	if bool(main.xr_active):
		face = -main.xr_camera.global_transform.basis.z
	elif main.get("hero_v28") != null:
		face = main.hero_v28.facing
	var etat: String = str(main.hero_v28.state) if main.get("hero_v28") != null else ""
	main.place_player_v35(cible, face)
	# à la nage, on le reste (place_player remet le héros « au sol »)
	if etat == "nage" and main.get("hero_v28") != null and main.get("mer_v55") != null and main.mer_v55.should_swim(cible):
		main.mer_v55.start_swim_pc(main.hero_v28)
	degages += 1
	dernier_motif = motif
	_pris_t = 0.0
	_echantillons.clear()
	_repos_t = 1.0
	print("ILE_MANGA_V176: héros dégagé (%s) de (%.1f %.1f %.1f) vers (%.1f %.1f %.1f)" % [motif, p.x, p.y, p.z, cible.x, cible.y, cible.z])
	return true


## Le menu « Me débloquer ».
func demande() -> void:
	if liberer(true, "menu"):
		main._show_message_v28("Te voilà débloqué !")


## En entrant dans une maison (après la pose) : si l'arrivée est encombrée, on se pose juste à côté.
func arrivee() -> void:
	oublier()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var b: CharacterBody3D = corps()
	if b == null:
		return
	if pris(b.global_position) or not libre(b.global_position):
		liberer(false, "arrivée")


## On change de lieu (une maison, un voyage) : les endroits sûrs d'avant ne comptent plus.
func oublier() -> void:
	_surs.clear()
	_echantillons.clear()
	_pris_t = 0.0


func _physics_process(delta: float) -> void:
	_tick += delta
	if _tick < PAS:
		return
	var dt: float = _tick
	_tick = 0.0
	if not _actif():
		_pris_t = 0.0
		_echantillons.clear()
		return
	if _repos_t > 0.0:
		_repos_t -= dt
		return
	var b: CharacterBody3D = corps()
	var p: Vector3 = b.global_position
	# 1) pris dans le décor
	if pris(p):
		_pris_t += dt
		if _pris_t >= PRIS_S:
			liberer(false, "pris dans le décor")
			return
	else:
		_pris_t = 0.0
	# 2) coincé dans un recoin : on pousse en tous sens, on n'avance pas
	_echantillons.append([p, _envie()])
	var n_max: int = int(RECOIN_S / PAS)
	while _echantillons.size() > n_max:
		_echantillons.pop_front()
	if _echantillons.size() >= n_max:
		var pousse: int = 0
		var somme := Vector3.ZERO
		var loin: float = 0.0
		for e in _echantillons:
			var d: Vector3 = e[1]
			if d.length() > 0.5:
				pousse += 1
				somme += d
			loin = maxf(loin, Vector2((e[0] as Vector3).x - p.x, (e[0] as Vector3).z - p.z).length())
		# (on a poussé presque tout le temps, dans des sens bien différents, sans faire 25 cm)
		if pousse >= int(n_max * 0.85) and loin < 0.25 and somme.length() < float(pousse) * 0.5:
			liberer(true, "coincé dans un recoin")
			return
	# 3) les endroits sûrs : debout sur le sol, libre, et là où l'on a le droit d'être
	_sur_t -= dt
	if _sur_t <= 0.0:
		_sur_t = 0.5
		var debout: bool = b.is_on_floor() and (bool(main.xr_active) or str(main.hero_v28.state) == "sol")
		if debout and libre(p) and (not main.has_method("pied_ok_v176") or main.pied_ok_v176(p)):
			if _surs.is_empty() or (_surs.back() as Vector3).distance_to(p) > 1.0:
				_surs.append(p)
				while _surs.size() > SURS_MAX:
					_surs.pop_front()
