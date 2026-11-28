extends Node
## V215 : ne pas dessiner ce qu'on ne peut pas voir.
##
## Le moteur ne dessine déjà pas ce qui est hors du champ de vision ; mais ce qui est dans le champ et caché
## derrière autre chose, il le dessine quand même (et calcule ses ombres). Deux cas sûrs sont traités ici :
##
## - le Royaume des Racines des elfes, à 70 m sous terre : il n'est dessiné que si l'on est sous terre, près
##   de lui (comme le Temple englouti depuis la V207) ;
## - le dessus des cinq îles aériennes, vu d'en bas : l'île masque son propre dessus. Pour chaque objet posé
##   sur l'île, on regarde si tous les coins de sa boîte sont derrière le « disque » de roche de l'île (un
##   disque plus petit que l'île, pris dans son épaisseur) ; si oui, on ne peut pas le voir, on ne le dessine
##   pas. Ce qui dépasse au bord reste dessiné. Dès que le regard passe au-dessus du disque, ou sous l'île
##   elle-même (les puits, les tubes), tout est dessiné.
##
## On ne touche pas à « visible » (le jeu s'en sert : les lampes la nuit, la foule selon l'heure…) : l'objet
## passe sur un calque de rendu vide, et retrouve le sien ensuite.

const RACINES_SOUS := -12.0             # m : en dessous, on est (ou on tombe) sous terre
const RACINES_PRES := 700.0             # m : autour de la clairière de l'Arbre-Mère
const DISQUE_SOUS := 4.0                # m : le disque est pris à cette profondeur sous le niveau de l'île
const DISQUE_PART := 0.7                # son rayon, par rapport à celui de l'île
const DISQUE_MARGE := 5.0               # m : on le rétrécit encore (le regard bouge entre deux contrôles)
const REGARD_SOUS := 5.0                # m : le regard doit être plus bas que le disque
const AUTOUR := 15.0                    # m : et hors de l'aplomb de l'île, de cette marge
const LOIN := 3500.0                    # m : au-delà, on ne contrôle plus (rien ne s'y dessine)
const PAR_IMAGE := 150                  # objets contrôlés par image, toutes îles confondues
const SAUT := 30.0                      # m : si le regard saute (téléportation), tout est redessiné d'abord
const RECENSE_PAR_IMAGE := 400          # objets rangés par image, pendant le recensement
const RECENSE_APRES := 1.5              # s après le début de la partie (les quêtes posent encore des objets)

var main: Node
var actif: bool = true
var pret: bool = false                  # le recensement est fini
var racines: Array = []                 # les objets du Royaume des Racines
var racines_vues: bool = true
var racines_centre := Vector3.INF
var iles: Array = []                    # {nom, c (Vector2), y0, r0, yd, rd, objets: [], calques: {id: calque}, i}
var caches: int = 0                     # combien d'objets des îles ne sont pas dessinés en ce moment
var _racines_calques: Dictionary = {}   # objet (id) -> son calque de rendu
var _regard := Vector3.INF
var _tour: int = 0
var _file: Array = []                   # le recensement en cours : les objets pas encore rangés
var _attente: float = -1.0
# V218 : le contrôle suit le regard (ce qu'on voit ou non ne dépend que de la place du regard). Regard en
# marche : juste assez d'objets par image pour finir un tour avant d'avoir parcouru 3 m (la marge du disque
# est de 5 m) ; PAR_IMAGE reste le plafond (en vol rapide, comme avant). Regard immobile (à 0,75 m près) et
# tour complet fait : un petit contrôle de fond seulement (8 objets par image : ce qui bouge sur l'île — un
# habitant, une nacelle — est revu toutes les quelques secondes).
const IMMOBILE_V218 := 0.75             # m
const TOUR_SUR_V218 := 3.0              # m : un tour complet avant que le regard ait fait ce chemin
const PAR_IMAGE_MIN_V218 := 8
var a_controler_v218: int = 0           # objets des îles « actives » (celles dont on est dessous), au dernier contrôle
var par_image_v218: int = 0             # combien d'objets ont été contrôlés à la dernière image (pour les essais)
var _repere_v218 := Vector3.INF         # le regard au début du tour en cours
var _vus_v218: int = 0                  # objets vus depuis le début du tour
var _oeil_v218 := Vector3.INF
var _vitesse_v218: float = 0.0


func setup(main_node: Node) -> void:
	main = main_node
	name = "Cache_v215"


func _boite(g: GeometryInstance3D) -> AABB:
	return g.global_transform * g.get_aabb()


## Le recensement : qui est sous terre chez les elfes, qui est posé sur une île aérienne. Il se fait peu
## après le début de la partie (les quêtes posent encore des objets à ce moment-là), quelques centaines
## d'objets par image pour ne pas faire de saccade.
func recenser() -> void:
	tout_montrer()
	pret = false
	racines.clear()
	iles.clear()
	_file.clear()
	var el: Node = main.get("elfes_v41")
	if el != null and el.get("feerique") != null and el.feerique != null:
		racines_centre = el.feerique.G
		for g in (el.feerique as Node).find_children("*", "GeometryInstance3D", true, false):
			var b: AABB = _boite(g)
			if b.size.length() > 0.01 and b.end.y < RACINES_SOUS:
				racines.append(g)
	for d in [["ciel_v54", "ile"], ["astralys_v76", "ile"], ["perchee_v146", "ile"], ["hautefond_v112", "nuees_ile"], ["feerie_v58", "ile"]]:
		var m: Node = main.get(d[0])
		if m == null or m.get(d[1]) == null:
			continue
		var ile: Node = m.get(d[1])
		if ile == null or ile.get("CENTER") == null or ile.get("R0") == null or ile.get("Y0") == null:
			continue
		var ctr: Vector3 = ile.CENTER
		var r0: float = float(ile.R0)
		var y0: float = float(ile.Y0)
		iles.append({"nom": str(d[0]), "c": Vector2(ctr.x, ctr.z), "y0": y0, "r0": r0, "yd": y0 - DISQUE_SOUS,
			"rd": r0 * DISQUE_PART - DISQUE_MARGE, "objets": [], "calques": {}, "i": 0})
	if not iles.is_empty():
		_file = main.find_children("*", "GeometryInstance3D", true, false)
	if _file.is_empty():
		_fin_recensement()


func _ranger(n: int) -> void:
	var k: int = 0
	while k < n and not _file.is_empty():
		k += 1
		var g = _file.pop_back()
		if not is_instance_valid(g):
			continue
		var b2: AABB = _boite(g)
		if b2.size.length() < 0.01:
			continue
		var c2 := Vector2(b2.get_center().x, b2.get_center().z)
		for il in iles:
			if b2.position.y >= float(il["yd"]) and b2.end.y < float(il["y0"]) + 600.0 and c2.distance_to(il["c"]) < float(il["r0"]) + 40.0:
				(il["objets"] as Array).append(g)
				break
	if _file.is_empty():
		_fin_recensement()


func _fin_recensement() -> void:
	pret = true
	var n: int = 0
	for il2 in iles:
		n += (il2["objets"] as Array).size()
	print("ILE_MANGA_V215: ce qu'on ne peut pas voir n'est pas dessiné : %d objets du Royaume des Racines, %d objets sur %d îles aériennes" % [racines.size(), n, iles.size()])


func _cacher(g, calques: Dictionary) -> bool:
	if not is_instance_valid(g):
		return false
	var v: VisualInstance3D = g
	if v.layers == 0:
		return false
	calques[v.get_instance_id()] = v.layers
	v.layers = 0
	return true


func _montrer(id: int, calques: Dictionary) -> void:
	var o: Object = instance_from_id(id) if is_instance_id_valid(id) else null
	if o != null and (o as VisualInstance3D).layers == 0:
		(o as VisualInstance3D).layers = int(calques[id])
	calques.erase(id)


func _montrer_tout(calques: Dictionary) -> void:
	for id in calques.keys():
		_montrer(int(id), calques)


func racines_a_voir(p: Vector3) -> bool:
	if p.y > RACINES_SOUS or racines_centre == Vector3.INF:
		return false
	return Vector2(p.x - racines_centre.x, p.z - racines_centre.z).length() < RACINES_PRES


## Le regard e peut-il voir quelque chose de cette boîte, malgré le disque de l'île ? (non : chaque coin de la
## boîte est au-dessus du disque, et le trait qui va du regard à ce coin traverse le disque)
func masque(il: Dictionary, e: Vector3, b: AABB) -> bool:
	var yd: float = float(il["yd"])
	if b.position.y < yd or e.y > yd - REGARD_SOUS:
		return false
	var c: Vector2 = il["c"]
	var rd2: float = float(il["rd"]) * float(il["rd"])
	for k in 8:
		var p: Vector3 = b.get_endpoint(k)
		var t: float = (yd - e.y) / (p.y - e.y)
		var x: float = e.x + (p.x - e.x) * t - c.x
		var z: float = e.z + (p.z - e.z) * t - c.y
		if x * x + z * z > rd2:
			return false
	return true


## Le regard est-il placé pour que l'île masque son dessus ? (plus bas que le disque, hors de son aplomb)
func en_dessous(il: Dictionary, e: Vector3) -> bool:
	if e.y > float(il["yd"]) - REGARD_SOUS:
		return false
	var d: float = Vector2(e.x, e.z).distance_to(il["c"])
	return d > float(il["r0"]) + AUTOUR and d < LOIN


func _montrer_ile(il: Dictionary) -> void:
	var cq: Dictionary = il["calques"]
	if cq.is_empty():
		return
	caches -= cq.size()
	_montrer_tout(cq)


func tout_montrer() -> void:
	for il in iles:
		_montrer_ile(il)
	_montrer_tout(_racines_calques)
	racines_vues = true
	_regard = Vector3.INF


## Un contrôle (le jeu l'appelle à chaque image ; les tests, directement) : n objets des îles au plus.
func controler(e: Vector3, n: int) -> void:
	if not pret:
		return
	var rv: bool = racines_a_voir(e)
	if rv != racines_vues:
		racines_vues = rv
		if rv:
			_montrer_tout(_racines_calques)
		else:
			for g in racines:
				_cacher(g, _racines_calques)
	if _regard != Vector3.INF and e.distance_to(_regard) > SAUT:
		for il0 in iles:
			_montrer_ile(il0)
	_regard = e
	var actives: Array = []
	for il in iles:
		if en_dessous(il, e):
			actives.append(il)
		else:
			_montrer_ile(il)
	a_controler_v218 = 0
	for il1 in actives:
		a_controler_v218 += (il1["objets"] as Array).size()
	if actives.is_empty():
		return
	var reste: int = n
	var garde: int = 0
	while reste > 0 and garde < actives.size():
		var il2: Dictionary = actives[_tour % actives.size()]
		_tour += 1
		garde += 1
		var objets: Array = il2["objets"]
		if objets.is_empty():
			continue
		var cq: Dictionary = il2["calques"]
		var part: int = mini(maxi(reste / maxi(actives.size() - garde + 1, 1), 1), objets.size())
		for j in part:
			var i: int = int(il2["i"]) % objets.size()
			il2["i"] = i + 1
			var g2 = objets[i]            # (sans type : l'objet a pu être détruit depuis le recensement)
			if not is_instance_valid(g2):
				continue
			var id: int = g2.get_instance_id()
			var etait: bool = cq.has(id)
			var m: bool = masque(il2, e, _boite(g2))
			if m and not etait:
				if _cacher(g2, cq):
					caches += 1
			elif not m and etait:
				_montrer(id, cq)
				caches -= 1
		reste -= part


func _process(delta: float) -> void:
	if main == null:
		return
	if not pret:
		if _file.is_empty():
			# pas encore lancé : on attend le début de la partie
			if bool(main.get("game_started")):
				_attente = RECENSE_APRES if _attente < 0.0 else _attente - delta
				if _attente <= 0.0:
					recenser()
		else:
			_ranger(RECENSE_PAR_IMAGE)
		return
	if not actif:
		return
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return
	var e: Vector3 = cam.global_position
	if _oeil_v218 != Vector3.INF and delta > 0.0:
		var v: float = e.distance_to(_oeil_v218) / delta
		if v < 400.0:
			_vitesse_v218 = lerpf(_vitesse_v218, v, clampf(delta * 6.0, 0.0, 1.0))
	_oeil_v218 = e
	if _repere_v218 == Vector3.INF or e.distance_to(_repere_v218) > IMMOBILE_V218:
		_repere_v218 = e
		_vus_v218 = 0
	var n: int = PAR_IMAGE_MIN_V218
	if _vus_v218 < a_controler_v218:
		n = clampi(int(ceil(float(a_controler_v218) * maxf(_vitesse_v218, 1.0) * delta / TOUR_SUR_V218)), PAR_IMAGE_MIN_V218, PAR_IMAGE)
		_vus_v218 += n
	par_image_v218 = n
	controler(e, n)
