extends Node
## V199 : en VR, deux vues, et l'on passe de l'une à l'autre quand on veut :
##   - « dans la peau » : la vue d'avant, les yeux du héros ;
##   - « de dehors » : on voit le héros de dos, un peu au-dessus, comme dans le jeu sur PC.
## On change dans Menu > Paramètres > Vue VR.
##
## Comment : tout le jeu continue de tourner autour du « vrai » joueur VR (l'origine, la tête, les
## mains, le corps physique : rien ne change pour les portes, les habitants, les combats). Pour la vue
## de dehors, une seconde origine XR, recopiée de la vraie mais reculée derrière le héros et levée, devient
## l'origine courante : le casque voit depuis elle. Le héros (le même modèle que sur PC) est dessiné là
## où est le joueur, il marche, court, saute ; les mains restent où elles sont (devant lui).
## Quand un menu, l'inventaire, un dialogue ou le carnet est ouvert, on revient dans la peau du héros
## le temps de lire (les panneaux sont posés devant la vraie tête) ; de même à bord d'un véhicule ou à
## l'échelle.

const RECUL := 2.6               # la vue de dehors : à 2,6 m derrière la tête…
const HAUT := 0.75               # … et 75 cm au-dessus
const MARGE_MUR := 0.35          # contre un mur, la vue se rapproche du héros

var main: Node
var dehors: bool = false         # le choix du joueur
var active: bool = false         # la vue de dehors est-elle affichée en ce moment ?
var origine2: XROrigin3D
var tete2: XRCamera3D
var _recul: float = RECUL
var _cap: float = 0.0            # là où regarde le héros (radians, autour de Y)
var _neutre: bool = true
var _anim: String = ""
var crans: bool = false          # la rotation au joystick : par crans (sinon : continue)
const REGLAGES := "user://reglages_son.cfg"


func setup(main_node: Node) -> void:
	main = main_node
	name = "Vue_VR_v199"
	origine2 = XROrigin3D.new()
	origine2.name = "Joueur_VR_dehors"
	main.add_child(origine2)
	tete2 = XRCamera3D.new()
	tete2.name = "Tete_dehors"
	tete2.near = 0.05
	tete2.far = 4000.0
	origine2.add_child(tete2)
	main.add_child(self)
	var cfg := ConfigFile.new()
	if cfg.load(REGLAGES) == OK:
		crans = bool(cfg.get_value("vr", "rotation_crans", false))
		dehors = bool(cfg.get_value("vr", "vue_dehors", false))
	print("ILE_MANGA_V199: vue VR dans la peau / de dehors (Menu > Paramètres)")


func basculer() -> void:
	dehors = not dehors
	_garder("vue_dehors", dehors)
	if main.has_method("_show_message_v28"):
		main._show_message_v28("Vue de dehors : vous voyez votre héros." if dehors else "Vue dans la peau du héros.")


func libelle_rotation() -> String:
	return "Rotation VR : par crans" if crans else "Rotation VR : continue"


func basculer_rotation() -> void:
	crans = not crans
	_garder("rotation_crans", crans)


func _garder(cle: String, val: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(REGLAGES)
	cfg.set_value("vr", cle, val)
	cfg.save(REGLAGES)


func libelle() -> String:
	return "Vue VR : de dehors" if dehors else "Vue VR : dans la peau"


func _lecture() -> bool:
	# un panneau à lire est ouvert : on revient dans la peau le temps de lire
	if main.game_menu != null and main.game_menu.opened:
		return true
	for nom in ["inventory_v28", "dialogue_v31"]:
		var n: Variant = main.get(nom)
		if n != null and is_instance_valid(n) and bool(n.get("opened")):
			return true
	if main.inventory_v28 != null and main.inventory_v28.get("carnet") != null and bool(main.inventory_v28.carnet.get("opened")):
		return true
	if main.has_method("virus_open_v96") and main.virus_open_v96():
		return true
	# à bord (l'aéronef, Ventaile, les bateaux, les nacelles), à l'échelle : dans la peau aussi
	if main.aeronef_v76 != null and bool(main.aeronef_v76.get("riding")):
		return true
	if main.ciel_v54 != null and bool(main.ciel_v54.get("riding")):
		return true
	if main.azur_v56 != null and main.azur_v56.get("ferry") != null and bool(main.azur_v56.ferry.get("riding")):
		return true
	if main.grande_v59 != null and main.grande_v59.has_method("riding") and main.grande_v59.riding():
		return true
	if main.perchee_v146 != null and main.perchee_v146.get("ile") != null and main.perchee_v146.riding():
		return true
	if main.get("foraine_v209") != null and main.foraine_v209 != null and main.foraine_v209.get("ile") != null and main.foraine_v209.riding():
		return true
	if main.boat_v29 != null and bool(main.boat_v29.get("driving")):
		return true
	if not (main.vr_ladder_v33 as Dictionary).is_empty():
		return true
	return false


func _process(delta: float) -> void:
	if main == null or not main.xr_active or main.xr_origin == null:
		return
	# (on change de vue dans Menu > Paramètres seulement : au joystick, ça changeait sans le vouloir)
	var voir: bool = dehors and main.game_started and not _lecture()
	if voir != active:
		active = voir
		if active:
			origine2.current = true
			tete2.current = true
			_recul = RECUL
		else:
			main.xr_origin.current = true
			main.xr_camera.current = true
		_montrer_mains(not active)
	var heros: Node3D = main.pc_hero
	if not active:
		if heros != null and heros.visible:
			heros.visible = false
		return
	_suivre(delta)
	_heros(delta)


## De dehors, on voit les mains du héros : les mains VR (et ce qu'elles tiennent) se cachent.
func _montrer_mains(on: bool) -> void:
	for c in [main.left_hand, main.right_hand]:
		if c != null and c.get_node_or_null("Manette_visible") != null:
			(c.get_node("Manette_visible") as Node3D).visible = on


## La seconde origine : la vraie, reculée derrière la tête (dans le sens de l'origine, qui ne tourne
## qu'avec le joystick : la vue ne bouge pas quand on tourne la tête), levée ; contre un mur, plus près.
func _suivre(delta: float) -> void:
	var o: Transform3D = main.xr_origin.global_transform
	var tete: Vector3 = main.xr_camera.global_position
	var arriere: Vector3 = o.basis.z
	arriere.y = 0.0
	arriere = arriere.normalized() if arriere.length() > 0.01 else Vector3.BACK
	var voulu: Vector3 = arriere * RECUL + Vector3.UP * HAUT
	# un mur, un toit entre la tête et la vue : on se rapproche (doucement en reculant, vite en avançant)
	var libre: float = RECUL
	var space: PhysicsDirectSpaceState3D = main.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(tete, tete + voulu * 1.0)
	q.collision_mask = 1
	if main.vr_body != null:
		q.exclude = [main.vr_body.get_rid()]
	var hit: Dictionary = space.intersect_ray(q)
	if not hit.is_empty():
		libre = maxf(tete.distance_to(hit["position"]) - MARGE_MUR, 0.0) * RECUL / voulu.length()
	if libre < _recul:
		_recul = libre
	else:
		_recul = move_toward(_recul, libre, delta * 1.5)
	var k: float = _recul / RECUL
	origine2.global_transform = Transform3D(o.basis, o.origin + voulu * k)


## Le héros, là où est le joueur : tourné vers où il marche (ou vers où il regarde, à l'arrêt).
func _heros(delta: float) -> void:
	var heros: Node3D = main.pc_hero
	var corps: CharacterBody3D = main.vr_body
	if heros == null or corps == null:
		return
	if not heros.visible:
		heros.visible = true
	var v: Vector3 = corps.velocity
	var vh := Vector3(v.x, 0.0, v.z)
	var vitesse: float = vh.length()
	var cap_voulu: float = _cap
	if vitesse > 0.4:
		cap_voulu = atan2(-vh.x, -vh.z)
	else:
		var f: Vector3 = -main.xr_camera.global_basis.z
		f.y = 0.0
		if f.length() > 0.1:
			cap_voulu = atan2(-f.x, -f.z)
	_cap = lerp_angle(_cap, cap_voulu, clampf(delta * 10.0, 0.0, 1.0))
	heros.global_position = corps.global_position + Vector3.UP * float(main.hero_mesh_floor_offset_v11)
	# (le modèle regarde vers +Z : comme sur PC, on ajoute un demi-tour)
	heros.rotation.y = _cap + PI
	var h = main.get("hero_v28")
	if h == null:
		return
	var anim: String = "v28/idle"
	if not corps.is_on_floor():
		anim = "v28/fall"
	elif vitesse > 2.2:
		anim = "Running"
	elif vitesse > 0.3:
		anim = "Walking"
	if anim != _anim:
		_anim = anim
		h._play(anim, 0.2, 1.0)
