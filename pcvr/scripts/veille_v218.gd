extends Node
## V218 : le processeur. Ce qui est loin du joueur ne travaille plus à chaque image.
##
## Le casque demande 72 images par seconde : le cœur principal du processeur a 13,9 ms pour faire tous les
## calculs d'une image. Or des centaines d'objets « travaillaient » à chaque image même à un kilomètre du
## joueur : chaque habitant du monde (et son visage) était appelé 72 fois par seconde pour répondre « je
## dors » ; chaque fontaine, chaque feu, chaque fumée calculait ses particules sur une île qu'on ne voit pas.
##
## 1. Les habitants. Un habitant endormi (loin du joueur : c'est lui qui le décide, à sa distance de veille)
##    ou rentré chez lui passe « au ralenti » : le moteur ne l'appelle plus ; c'est la veille qui le visite,
##    deux fois par seconde (une fois toutes les deux secondes s'il est très loin), en lui donnant le temps
##    écoulé : son agenda continue (il rentre, il sort, il change de place), et il se réveille de lui-même.
##    Il repasse à chaque image un peu AVANT sa distance de veille : il apparaît donc exactement où et quand
##    il apparaissait avant. Rien ne change à l'écran.
## 2. Les particules calculées par le processeur (feux, fumées, fontaines, étincelles… : plus de 500 dans le
##    monde). Chacune recalculait tous ses grains 72 fois par seconde, où que soit le joueur. Maintenant :
##    près du joueur (moins de 120 m), rien ne change ; plus loin, les grains sont recalculés 36 fois par
##    seconde, puis 18 fois au-delà de 300 m, 12 fois au-delà de 600 m (à ces distances un grain tient en
##    un ou deux points de l'écran : on ne voit pas la différence) ; et au-delà de la distance où le moteur
##    ne les dessine plus du tout (leur portée d'affichage, V192), elles ne sont plus calculées. Elles
##    reprennent à l'approche.
##
## 3. Les décors animés d'une île lointaine (les créatures, les feux follets, l'horloge et l'astrolabe
##    d'Ombrelac…) : à plus d'un kilomètre, leurs animations s'arrêtent ; elles reprennent à l'approche, bien
##    avant qu'on puisse les voir. Seuls des morceaux qui ne font qu'animer leur coin sont inscrits ici (pas
##    les quêtes, pas les cours, pas les transports).
##
## Pour les habitants, on ne touche jamais à « visible » ni à set_process (le jeu s'en sert : la foule selon
## l'heure, les compagnons, l'arène…) : un habitant au ralenti a seulement son mode de calcul sur « arrêté »,
## et la veille le lui rend.

const PERIODE := 0.5                    # s : un habitant au ralenti est visité tous les 0,5 s
const PERIODE_LOIN := 2.0               # s : et tous les 2 s s'il est très loin
const TRES_LOIN := 300.0                # m au-delà de sa distance de veille
const MARGE := 6.0                      # m : il repasse à chaque image à sa distance de veille + cette marge
const MARGE_TEMPS := 0.75               # s : + ce que le joueur parcourt pendant ce temps (il peut courir, voler)
const RETOUR := 4.0                     # m : et ne repasse au ralenti que plus loin encore (pas de va-et-vient)
const SAUT := 25.0                      # m : si le joueur saute d'un coup (un voyage), on réveille tout de suite
const GRAINS_PERIODE := 0.5             # s : chaque jeu de particules est revu tous les 0,5 s
const GRAINS_DISTANCES := [120.0, 300.0, 600.0]   # m : en deçà de la première, comme avant ; puis les paliers 1, 2, 3
const GRAINS_RYTHMES := [0, 36, 18, 12]           # calculs par seconde selon le palier (0 : à chaque image)
const GRAINS_ARRET := 4                           # le palier « plus de calcul du tout » (hors de portée d'affichage)
const GRAINS_RETOUR := 0.9              # on ne redescend d'un palier qu'à 90 % de sa distance (pas de va-et-vient)
const GRAINS_HORS_PORTEE := 15.0        # m au-delà de la portée d'affichage : plus de calcul du tout

var main: Node
var actif: bool = true
var lents: Dictionary = {}              # habitant (id) -> [habitant, visage, heure de la prochaine visite, heure de la dernière]
var eveilles: Array = []                # les habitants qu'on appelle à chaque image (ceux à qui l'on peut parler)
var visites: int = 0                    # combien de visites au ralenti depuis le début (pour les essais)
var decors: Array = []                  # [racine, centre, rayon, fichiers (ceux qu'on endort), endormis ([objet, calculs, physique]), dort]
var decors_endormis: int = 0            # combien d'objets de décor ne sont plus animés en ce moment
var _decors_t: float = 0.0
var grains: Array = []                  # [particules, son rythme d'origine, palier (0 près, 1 à 3 ralenties, 4 = arrêtées)]
var grains_arretes: int = 0             # combien ne sont plus calculées en ce moment
var grains_ralentis: int = 0            # combien sont calculées moins souvent
var _g: int = 0
var _connus: int = -1
var _i: int = 0
var _t: float = 0.0
var _joueur := Vector3.INF
var _vitesse: float = 0.0


func setup(main_node: Node) -> void:
	main = main_node
	name = "Veille_v218"
	# après les habitants : dans la même image, ils décident d'abord (je dors, je suis rentré), puis la veille
	process_priority = 50
	# les particules déjà là, et celles qui viendront (un feu qu'on allume, une ville bâtie plus tard)
	for pt in main.get_tree().root.find_children("*", "CPUParticles3D", true, false):
		grains.append([pt, -1, 0])
	main.get_tree().node_added.connect(_noeud_ajoute)


func _noeud_ajoute(n: Node) -> void:
	if n is CPUParticles3D:
		grains.append([n, -1, 0])


## Inscrit des décors animés : sous « racine », les objets dont le script est l'un de ces fichiers ne sont
## plus animés quand le joueur est à plus de « rayon » mètres de « centre ».
func decor_lointain(racine: Node, centre: Vector3, rayon: float, fichiers: Array) -> void:
	if racine != null:
		decors.append([racine, centre, rayon, fichiers, [], false])


func _decor_dormir(d: Array, oui: bool) -> void:
	var endormis: Array = d[4]
	if oui:
		var racine: Node = d[0]
		var fichiers: Array = d[3]
		for n in racine.find_children("*", "", true, false):
			var sc: Script = (n as Node).get_script()
			if sc == null or not (sc.resource_path.get_file() in fichiers):
				continue
			var calculs: bool = (n as Node).is_processing()
			var physique: bool = (n as Node).is_physics_processing()
			if not calculs and not physique:
				continue
			endormis.append([n, calculs, physique])
			(n as Node).set_process(false)
			(n as Node).set_physics_process(false)
		decors_endormis += endormis.size()
	else:
		for e in endormis:
			if is_instance_valid(e[0]):
				if bool(e[1]):
					(e[0] as Node).set_process(true)
				if bool(e[2]):
					(e[0] as Node).set_physics_process(true)
		decors_endormis -= endormis.size()
		endormis.clear()
	d[5] = oui


## Tous les décors animés, comme avant (les essais, ou si l'on coupe la veille).
func decors_reveiller() -> void:
	for d in decors:
		if bool(d[5]):
			_decor_dormir(d, false)


func _decors(delta: float, p: Vector3) -> void:
	_decors_t -= delta
	if _decors_t > 0.0:
		return
	_decors_t = 0.5
	# (pas dans les premières secondes de la partie : chaque morceau s'installe d'abord)
	if _t < 6.0:
		return
	for d in decors:
		if not is_instance_valid(d[0]):
			continue
		var c: Vector3 = d[1]
		var loin: float = Vector2(p.x - c.x, p.z - c.z).length()
		var dort: bool = d[5]
		if not dort and loin > float(d[2]) + 40.0:
			_decor_dormir(d, true)
		elif dort and loin < float(d[2]):
			_decor_dormir(d, false)


## Tout le monde à plein rythme (les essais, ou si l'on coupe la veille).
func grains_plein_rythme() -> void:
	for e in grains:
		if is_instance_valid(e[0]) and int(e[2]) != 0:
			_palier(e, 0)


func _palier(e: Array, palier: int) -> void:
	var pt: CPUParticles3D = e[0]
	var avant: int = int(e[2])
	if avant == GRAINS_ARRET:
		grains_arretes -= 1
		pt.set_process_internal(true)
	elif avant > 0:
		grains_ralentis -= 1
	e[2] = palier
	if palier == GRAINS_ARRET:
		grains_arretes += 1
		pt.set_process_internal(false)
		return
	var origine: int = int(e[1])
	var rythme: int = int(GRAINS_RYTHMES[palier])
	if palier > 0:
		grains_ralentis += 1
	pt.fixed_fps = origine if rythme == 0 else (rythme if origine <= 0 else mini(origine, rythme))


func _grains(delta: float, p: Vector3) -> void:
	var n: int = grains.size()
	if n == 0:
		return
	var combien: int = clampi(int(ceil(n * delta / GRAINS_PERIODE)), 1, n)
	for k in combien:
		if grains.is_empty():
			return
		_g = (_g + 1) % grains.size()
		var e: Array = grains[_g]
		if not is_instance_valid(e[0]):
			if int(e[2]) == GRAINS_ARRET:
				grains_arretes -= 1
			elif int(e[2]) > 0:
				grains_ralentis -= 1
			grains[_g] = grains[-1]
			grains.pop_back()
			continue
		var pt: CPUParticles3D = e[0]
		if not pt.is_inside_tree():
			continue
		if int(e[1]) < 0:
			# première visite : un effet d'un instant (un éclat, une gerbe) vit sa vie sans nous
			if pt.one_shot:
				grains[_g] = grains[-1]
				grains.pop_back()
				continue
			e[1] = pt.fixed_fps
		var d: float = pt.global_position.distance_to(p)
		var avant: int = int(e[2])
		var portee: float = pt.visibility_range_end
		var palier: int = 0
		if portee > 0.0 and d > portee + pt.visibility_range_end_margin + GRAINS_HORS_PORTEE * (1.0 if avant == GRAINS_ARRET else 2.0):
			palier = GRAINS_ARRET
		else:
			for j in range(GRAINS_DISTANCES.size() - 1, -1, -1):
				if d > float(GRAINS_DISTANCES[j]) * (GRAINS_RETOUR if avant >= j + 1 else 1.0):
					palier = j + 1
					break
		if palier != avant:
			_palier(e, palier)
		elif palier == GRAINS_ARRET and pt.is_processing_internal():
			# le jeu l'a rallumée (la nuit tombe, un feu repart) : elle reste hors de portée, on la rendort
			pt.set_process_internal(false)


## L'habitant peut-il passer au ralenti ? (lui seul le sait : il dort loin du joueur, il est rentré chez lui ;
## jamais en pleine conversation, en pleine bagarre, en pleine course)
func _ralenti_ok(npc: Node) -> bool:
	return npc.has_method("ralenti_ok_v218") and bool(npc.ralenti_ok_v218())


func _marge() -> float:
	return MARGE + _vitesse * MARGE_TEMPS


## Sa distance de veille : celle où il se réveille de lui-même (ou, pour un habitant sans sommeil, celle
## au-delà de laquelle on ne le dessine plus).
func _veille_de(npc: Node) -> float:
	if npc.has_method("veille_dist_v218"):
		return float(npc.veille_dist_v218())
	return float(npc.get("sleep_far"))


func _ralentir(npc: Node3D, d: float) -> void:
	var vis: Node = npc.get_node_or_null("Visage64")
	lents[npc.get_instance_id()] = [npc, vis, _t + PERIODE, _t]
	npc.process_mode = Node.PROCESS_MODE_DISABLED
	eveilles.erase(npc)


## Il sort du ralenti : le moteur l'appelle de nouveau à chaque image (s'il a ses calculs : un compagnon de
## route, l'arène peuvent les lui avoir coupés, et la veille n'y touche pas) ; on peut de nouveau lui parler.
func _reveiller(npc: Node3D) -> void:
	lents.erase(npc.get_instance_id())
	if npc.process_mode == Node.PROCESS_MODE_DISABLED:
		npc.process_mode = Node.PROCESS_MODE_INHERIT
	if not eveilles.has(npc):
		eveilles.append(npc)


## Tout le monde à chaque image, comme avant la V218 (les essais, ou si l'on coupe la veille).
func tout_reveiller() -> void:
	for id in lents.keys():
		var e: Array = lents[id]
		if is_instance_valid(e[0]):
			_reveiller(e[0])
	lents.clear()
	_connus = -1


## Une visite : l'habitant au ralenti fait d'un coup ce qu'il aurait fait à chaque image.
func _visiter(e: Array, p: Vector3) -> void:
	var npc: Node3D = e[0]
	# quelqu'un d'autre a coupé ses calculs (un compagnon de route, l'arène…) : la veille le lui laisse
	if not npc.is_processing():
		_reveiller(npc)
		return
	# son île entière est à l'arrêt (un étage fermé, une scène), ou il n'est plus dans le monde : on ne le
	# fait pas vivre en cachette
	var parent: Node = npc.get_parent()
	if parent == null or not npc.is_inside_tree() or not parent.can_process():
		e[2] = _t + PERIODE
		e[3] = _t
		return
	var dt: float = _t - float(e[3])
	e[3] = _t
	visites += 1
	npc._process(dt)
	if e[1] != null and is_instance_valid(e[1]):
		(e[1] as Node)._process(dt)
	if not is_instance_valid(npc) or not npc.is_inside_tree():
		return
	var d: float = npc.global_position.distance_to(p)
	var veille: float = _veille_de(npc)
	if not _ralenti_ok(npc) or (not _chez_lui(npc) and d < veille + _marge()):
		_reveiller(npc)
		return
	e[2] = _t + (PERIODE_LOIN if d > veille + TRES_LOIN else PERIODE)


func _chez_lui(npc: Node) -> bool:
	return npc.get("hidden_home") == true


func _process(delta: float) -> void:
	if main == null or not actif:
		return
	var npcs: Array = main.npcs_v31
	var n: int = npcs.size()
	if n == 0:
		return
	_t += delta
	var p: Vector3 = main._player_pos_v27()
	var saut: bool = false
	if _joueur != Vector3.INF:
		var pas: float = p.distance_to(_joueur)
		saut = pas > SAUT
		if not saut:
			_vitesse = lerpf(_vitesse, pas / maxf(delta, 0.001), clampf(delta * 4.0, 0.0, 1.0))
	_joueur = p
	_grains(delta, p)
	_decors(delta, p)
	# la liste des habitants a changé (une ville vient d'être bâtie, un habitant est parti) : on refait la nôtre
	if n != _connus:
		_connus = n
		eveilles.clear()
		for npc0 in npcs:
			if is_instance_valid(npc0) and not lents.has((npc0 as Node).get_instance_id()):
				eveilles.append(npc0)
		for id0 in lents.keys():
			if not is_instance_valid((lents[id0] as Array)[0]):
				lents.erase(id0)
	# le joueur vient de sauter d'un coup (un voyage, une chute, un essai) : ceux qui sont maintenant près de
	# lui repassent à chaque image tout de suite
	if saut:
		for id1 in lents.keys():
			var e1: Array = lents[id1]
			if not is_instance_valid(e1[0]):
				lents.erase(id1)
				continue
			var n1: Node3D = e1[0]
			if not n1.is_inside_tree():
				continue
			if not _chez_lui(n1) and n1.global_position.distance_to(p) < _veille_de(n1) + _marge() + SAUT:
				_reveiller(n1)
			else:
				e1[2] = minf(float(e1[2]), _t + PERIODE)
		for eg in grains:
			if int(eg[2]) != 0 and is_instance_valid(eg[0]) and (eg[0] as Node).is_inside_tree() and (eg[0] as Node3D).global_position.distance_to(p) < float(GRAINS_DISTANCES[0]):
				_palier(eg, 0)
	# une tranche des habitants à chaque image : chacun est vu une fois par période
	var combien: int = clampi(int(ceil(n * delta / PERIODE)), 1, n)
	for k in combien:
		_i = (_i + 1) % n
		var npc = npcs[_i]
		if not is_instance_valid(npc):
			continue
		var id: int = (npc as Node).get_instance_id()
		if lents.has(id):
			var e: Array = lents[id]
			if _t >= float(e[2]):
				_visiter(e, p)
		elif (npc as Node).is_processing() and (npc as Node).process_mode == Node.PROCESS_MODE_INHERIT and (npc as Node).is_inside_tree() and _ralenti_ok(npc):
			var d: float = (npc as Node3D).global_position.distance_to(p)
			if _chez_lui(npc) or d > _veille_de(npc) + _marge() + RETOUR:
				_ralentir(npc, d)
