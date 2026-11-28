## V218 : qui coûte au processeur ? (lancé par tests/outils/audit_calculs.py, collé à la fin de main.gd
## comme une série ; le jeu tourne sans image, avec le débogueur local « -d » pour avoir le relevé des
## fonctions). Le casque veut 72 images par seconde : à chaque image, le cœur principal fait un pas de
## calculs (les _process) et un pas de physique (les _physics_process et le moteur de physique). Ici on
## impose exactement ce rythme-là (un pas de physique par image) et on mesure, à chaque endroit :
##   1. le temps d'une image (moyenne, médiane, les pires) ;
##   2. le relevé des fonctions du jeu (qui a tourné, combien de fois, combien de temps) ;
##   3. ce que coûtent les objets du moteur qui travaillent tout seuls (particules, animations, sons) :
##      on endort une sorte d'objet, on remesure, on la réveille, plusieurs fois de suite ;
##   4. le plancher : tout endormi sauf le cœur du jeu.
## Les temps sont ceux de la machine d'essai : c'est le classement et les proportions qui comptent.
## Lignes : CAL_LIEU, CAL_PROFIL_DEBUT/FIN (le relevé « ACCUMULATED » du moteur est entre les deux),
## CAL_FAM (une famille du moteur), CAL_SCRIPTS (les familles de scripts, pour mémoire), CAL_SOL.
const NOM := "audit_calculs"
var _ca8_args: Dictionary = {}
var _ca8_pas: int = 0
var _ca8_t_phys: int = -1
var _ca8_t_proc: int = -1
var _ca8_t_fin: int = -1
var _ca8_occupe: Array = []         # le temps de travail de chaque image (ms), tant qu'on le relève


## Le temps de travail d'une image = le pas de physique (du signal « physics_frame » au signal
## « process_frame ») + le pas de calculs (de « process_frame » à la fin : le dernier appel différé de
## l'image, ou la fin du dessin quand le moteur dessine). On ne compte pas l'attente entre deux images : le
## jeu tourne ici à 72 images par seconde comme dans le casque (les mêmes durées de pas), et l'on mesure ce
## qu'il lui en coûte.
func _ca8_un_pas() -> void:
	_ca8_clore()
	_ca8_pas += 1
	if _ca8_t_phys < 0:
		_ca8_t_phys = Time.get_ticks_usec()


func _ca8_debut_calculs() -> void:
	if _ca8_t_proc >= 0:
		_ca8_clore()
	_ca8_t_proc = Time.get_ticks_usec()


func _ca8_fin_image() -> void:
	_ca8_t_fin = Time.get_ticks_usec()


func _ca8_clore() -> void:
	if _ca8_t_proc < 0 or _ca8_t_fin < 0:
		return
	var t8: float = float(_ca8_t_fin - _ca8_t_proc)
	if _ca8_t_phys >= 0:
		t8 += float(_ca8_t_proc - _ca8_t_phys)
	_ca8_t_phys = -1
	_ca8_t_proc = -1
	_ca8_t_fin = -1
	_ca8_occupe.append(t8 / 1000.0)


func _ca8_famille(n: Node) -> String:
	var sc8: Script = n.get_script()
	if sc8 != null and sc8.resource_path != "":
		return sc8.resource_path.get_file()
	return "(moteur) " + n.get_class()


## Le temps de travail des images, en ms : [moyenne, médiane, neuf sur dix sous, la pire, pas de physique par image].
func _ca8_mesure(images: int) -> Array:
	await get_tree().process_frame
	await get_tree().process_frame
	_ca8_occupe.clear()
	var pas8: int = _ca8_pas
	while _ca8_occupe.size() < images:
		await get_tree().process_frame
	var temps8: Array = _ca8_occupe.slice(0, images)
	var somme8: float = 0.0
	for t8 in temps8:
		somme8 += float(t8)
	temps8.sort()
	return [somme8 / images, float(temps8[images / 2]), float(temps8[int(images * 0.9)]), float(temps8[images - 1]), float(_ca8_pas - pas8) / images]


## Les temps de travail (ms) de quelques images de suite ; les trois premières ne comptent pas (le
## changement se tasse).
func _ca8_bloc(images: int) -> Array:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_ca8_occupe.clear()
	while _ca8_occupe.size() < images:
		await get_tree().process_frame
	return _ca8_occupe.slice(0, images)


func _ca8_mediane(v: Array) -> float:
	if v.is_empty():
		return 0.0
	var w8: Array = v.duplicate()
	w8.sort()
	return float(w8[w8.size() / 2])


func _ca8_moyenne(v: Array) -> float:
	var s8: float = 0.0
	for x8 in v:
		s8 += float(x8)
	return s8 / maxf(v.size(), 1.0)


## L'étalon : un calcul toujours le même, chronométré (ms). Il dit si la machine d'essai est rapide ou lente
## à ce moment-là : on s'en sert pour comparer deux relevés faits à des moments différents.
func _ca8_etalon() -> float:
	var meilleur8: float = 1e9
	for essai8 in 5:
		var t8: int = Time.get_ticks_usec()
		var x8: float = 0.0
		for i8 in 200000:
			x8 += sin(float(i8) * 0.001) * 0.5 + float(i8 % 7)
		meilleur8 = minf(meilleur8, float(Time.get_ticks_usec() - t8) / 1000.0)
	return meilleur8


func _ca8_rien(i: int) -> float:
	return float(i & 3)


## Un second étalon, qui ressemble au travail du jeu (des appels de fonctions, des dictionnaires, des
## vecteurs, des lectures de position) : la médiane de sept essais.
func _ca8_etalon_jeu() -> float:
	var d8: Dictionary = {"a": 1.0, "b": 2.0, "c": Vector3(1, 2, 3)}
	var essais8: Array = []
	for essai8 in 7:
		var t8: int = Time.get_ticks_usec()
		var x8: float = 0.0
		for i8 in 30000:
			var v8: Vector3 = d8["c"]
			x8 += v8.distance_to(global_position) + float(d8["a"]) + _ca8_rien(i8)
			if is_inside_tree() and x8 < 0.0:
				x8 = 0.0
		essais8.append(float(Time.get_ticks_usec() - t8) / 1000.0)
	essais8.sort()
	return float(essais8[3])


func _ca8_dormir(liste: Array, oui: bool) -> void:
	for e8 in liste:
		if not is_instance_valid(e8[0]):
			continue
		var o8: Node = e8[0]
		var et8: Array = e8[1]
		o8.set_process(false if oui else bool(et8[0]))
		o8.set_physics_process(false if oui else bool(et8[1]))
		o8.set_process_internal(false if oui else bool(et8[2]))
		o8.set_physics_process_internal(false if oui else bool(et8[3]))


func _ca8_lieu(nom: String, ou: Vector3) -> void:
	_poser(ou)
	await _att(float(_ca8_args.get("attente", 12.0)))
	var images8: int = int(_ca8_args.get("images", 60))
	# 1. le temps d'une image
	var base8: Array = await _ca8_mesure(images8 * 4)
	# qui travaille à chaque image ?
	var familles8: Dictionary = {}
	var total8: int = 0
	for n8 in get_tree().root.find_children("*", "", true, false):
		var nn8: Node = n8
		if nn8 == self or nn8.name == &"Fin_des_calculs_audit" or not nn8.can_process():
			continue
		var etat8: Array = [nn8.is_processing(), nn8.is_physics_processing(), nn8.is_processing_internal(), nn8.is_physics_processing_internal()]
		if not (etat8[0] or etat8[1] or etat8[2] or etat8[3]):
			continue
		total8 += 1
		var f8: String = _ca8_famille(nn8)
		if not familles8.has(f8):
			familles8[f8] = []
		(familles8[f8] as Array).append([nn8, etat8])
	print("CAL_LIEU\t%s\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%d\t%d\t%.2f\t%.2f" % [nom, base8[0], base8[1], base8[2], base8[3], base8[4], total8, familles8.size(), _ca8_etalon(), _ca8_etalon_jeu()])
	# le recensement des objets du moteur qui travaillent : à qui ils sont, à quelle distance du joueur
	if bool(_ca8_args.get("recensement", true)):
		var ici8: Vector3 = _player_pos_v27()
		var rec8: Dictionary = {}
		for f8 in familles8:
			if not str(f8).begins_with("(moteur)"):
				continue
			for e8 in familles8[f8]:
				var o8: Node = e8[0]
				var chemin8: PackedStringArray = str(o8.get_path()).split("/")
				var maitre8: String = chemin8[3] if chemin8.size() > 3 else str(o8.name)
				var d8: float = (o8 as Node3D).global_position.distance_to(ici8) if o8 is Node3D else -1.0
				var tranche8: String = "?" if d8 < 0.0 else ("<60" if d8 < 60.0 else ("<150" if d8 < 150.0 else ("<400" if d8 < 400.0 else ("<1000" if d8 < 1000.0 else ">1000"))))
				var cle8: String = "%s\t%s\t%s" % [f8, maitre8, tranche8]
				if not rec8.has(cle8):
					rec8[cle8] = [0, 0, 0, 0.0, 0]
				var r8: Array = rec8[cle8]
				r8[0] = int(r8[0]) + 1
				if o8 is Node3D and (o8 as Node3D).is_visible_in_tree():
					r8[1] = int(r8[1]) + 1
				if o8 is CPUParticles3D:
					r8[2] = int(r8[2]) + (o8 as CPUParticles3D).amount
					r8[3] = maxf(float(r8[3]), (o8 as CPUParticles3D).visibility_range_end)
					if (o8 as CPUParticles3D).emitting:
						r8[4] = int(r8[4]) + 1
				elif o8 is GPUParticles3D:
					r8[2] = int(r8[2]) + (o8 as GPUParticles3D).amount
					r8[3] = maxf(float(r8[3]), (o8 as GPUParticles3D).visibility_range_end)
					if (o8 as GPUParticles3D).emitting:
						r8[4] = int(r8[4]) + 1
		for cle8 in rec8:
			var r8b: Array = rec8[cle8]
			print("CAL_REC\t%s\t%s\t%d\t%d\t%d\t%.0f\t%d" % [nom, cle8, r8b[0], r8b[1], r8b[2], r8b[3], r8b[4]])
	var scripts8: Array = []
	for f8 in familles8:
		if not str(f8).begins_with("(moteur)"):
			scripts8.append("%s=%d" % [f8, (familles8[f8] as Array).size()])
	print("CAL_SCRIPTS\t%s\t%s" % [nom, " ".join(scripts8)])
	# 2. le relevé des fonctions du jeu
	if EngineDebugger.is_active() and EngineDebugger.has_profiler("scripts"):
		var n_profil8: int = int(_ca8_args.get("profil", 300))
		await get_tree().process_frame
		var t_profil8: int = Time.get_ticks_usec()
		print("CAL_PROFIL_DEBUT\t%s" % nom)
		EngineDebugger.profiler_enable("scripts", true)
		for i8 in n_profil8:
			await get_tree().process_frame
		print("CAL_PROFIL_RELEVE\t%s\t%d\t%.1f" % [nom, n_profil8, float(Time.get_ticks_usec() - t_profil8) / 1000.0])
		EngineDebugger.profiler_enable("scripts", false)
		print("CAL_PROFIL_FIN\t%s" % nom)
	else:
		print("CAL_SANS_PROFIL\t%s" % nom)
	# 3. les familles qu'on peut endormir : les objets du moteur qui travaillent tout seuls, les familles de
	# scripts nombreuses (les habitants, leurs visages…), tous les habitants d'un coup, et un témoin (on
	# n'endort rien : ce qu'il « gagne » est le bruit de la mesure)
	var essais8: Array = [["(témoin) rien", []]]
	var nombreux8: Array = []
	for f8 in familles8:
		var l8: Array = familles8[f8]
		if str(f8).begins_with("(moteur)") or (l8.size() >= 5 and bool(_ca8_args.get("chaque_script", false))):
			essais8.append([str(f8), l8])
		if not str(f8).begins_with("(moteur)") and l8.size() >= 5:
			nombreux8.append_array(l8)
	essais8.append(["(ensemble) les scripts nombreux", nombreux8])
	essais8.append(["(témoin) rien, encore", []])
	# éveillé / endormi en alternance serrée (quelques images chaque fois, de nombreuses fois) : la machine
	# d'essai n'est pas régulière, et une lente dérive s'annule ainsi ; on compare les médianes
	var bloc8: int = int(_ca8_args.get("bloc", 8))
	var cycles8: int = int(_ca8_args.get("cycles", 30))
	for e8 in essais8:
		var liste8: Array = e8[1]
		var avec8: Array = []
		var sans8: Array = []
		var ecarts8: Array = []
		for cycle8 in cycles8:
			var a8: Array = await _ca8_bloc(bloc8)
			_ca8_dormir(liste8, true)
			var b8: Array = await _ca8_bloc(bloc8)
			_ca8_dormir(liste8, false)
			avec8.append_array(a8)
			sans8.append_array(b8)
			ecarts8.append(_ca8_mediane(a8) - _ca8_mediane(b8))
		var moy8: float = 0.0
		for g8 in ecarts8:
			moy8 += float(g8) / cycles8
		var ecart8: float = 0.0
		for g8 in ecarts8:
			ecart8 += pow(float(g8) - moy8, 2.0)
		ecart8 = sqrt(ecart8 / maxf(cycles8 - 1, 1.0)) / sqrt(float(cycles8))
		print("CAL_FAM\t%s\t%s\t%d\t%.3f\t%.3f\t%.3f" % [nom, e8[0], liste8.size(), _ca8_moyenne(avec8) - _ca8_moyenne(sans8), _ca8_mediane(avec8) - _ca8_mediane(sans8), ecart8])
	# 3 bis. la veille (V218) coupée, puis remise, plusieurs fois de suite dans la même partie : la mesure
	# la plus sûre de ce qu'elle rapporte (la machine d'essai n'est pas régulière d'une partie à l'autre)
	var veille8: Variant = get("veille_v218")
	if veille8 != null and bool(_ca8_args.get("veille", true)):
		var v_avec8: Array = []
		var v_sans8: Array = []
		for tour8 in int(_ca8_args.get("tours_veille", 5)):
			(veille8 as Node).set("actif", false)
			(veille8 as Node).call("tout_reveiller")
			(veille8 as Node).call("grains_plein_rythme")
			(veille8 as Node).call("decors_reveiller")
			await _images(30)
			v_sans8.append_array(await _ca8_bloc(60))
			(veille8 as Node).set("actif", true)
			await _att(3.0)
			v_avec8.append_array(await _ca8_bloc(60))
		print("CAL_VEILLE\t%s\t%.2f\t%.2f\t%.2f\t%.2f\t%d\t%d\t%d\t%d" % [nom, _ca8_moyenne(v_sans8), _ca8_mediane(v_sans8), _ca8_moyenne(v_avec8), _ca8_mediane(v_avec8),
			((veille8 as Node).get("lents") as Dictionary).size(), int((veille8 as Node).get("grains_arretes")), int((veille8 as Node).get("grains_ralentis")), int((veille8 as Node).get("decors_endormis"))])
	# 4. le plancher (tout endormi sauf le cœur du jeu), les scripts seuls endormis, le moteur seul endormi
	var tout8: Array = []
	var scr8: Array = []
	var mot8: Array = []
	for f8 in familles8:
		tout8.append_array(familles8[f8])
		if str(f8).begins_with("(moteur)"):
			mot8.append_array(familles8[f8])
		else:
			scr8.append_array(familles8[f8])
	var t_avec8: Array = []
	var t_tout8: Array = []
	var t_scr8: Array = []
	var t_mot8: Array = []
	for cycle8 in cycles8:
		t_avec8.append_array(await _ca8_bloc(bloc8))
		_ca8_dormir(tout8, true)
		t_tout8.append_array(await _ca8_bloc(bloc8))
		_ca8_dormir(tout8, false)
		_ca8_dormir(scr8, true)
		t_scr8.append_array(await _ca8_bloc(bloc8))
		_ca8_dormir(scr8, false)
		_ca8_dormir(mot8, true)
		t_mot8.append_array(await _ca8_bloc(bloc8))
		_ca8_dormir(mot8, false)
	print("CAL_SOL\t%s\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f" % [nom, _ca8_moyenne(t_avec8), _ca8_mediane(t_avec8), _ca8_moyenne(t_tout8), _ca8_mediane(t_tout8), _ca8_moyenne(t_scr8), _ca8_mediane(t_scr8), _ca8_moyenne(t_mot8), _ca8_mediane(t_mot8), _ca8_etalon()])


func _serie() -> void:
	var fa8 := FileAccess.open("res://audit_args.json", FileAccess.READ)
	if fa8 != null:
		_ca8_args = JSON.parse_string(fa8.get_as_text())
	if temps_v56 != null:
		temps_v56.hour = float(_ca8_args.get("heure", 14.0))
	var garde8: int = 0
	while get("allege_v211") != null and allege_v211 != null and not allege_v211.fini and garde8 < 900:
		await _att(0.5)
		garde8 += 1
	# le rythme du casque : 72 pas de physique par seconde, un seul par image, pas d'attente entre les images
	Engine.physics_ticks_per_second = int(_ca8_args.get("pas", 72))
	Engine.max_physics_steps_per_frame = 1
	Engine.max_fps = int(_ca8_args.get("pas", 72))
	get_tree().physics_frame.connect(_ca8_un_pas)
	get_tree().process_frame.connect(_ca8_debut_calculs)
	RenderingServer.frame_post_draw.connect(_ca8_fin_image)
	# la fin des calculs d'une image : un petit objet appelé le dernier, qui demande un appel différé (il
	# passe après tous ceux que les autres ont demandés pendant l'image)
	var code8 := GDScript.new()
	code8.source_code = "extends Node\nvar cible: Callable\nfunc _process(_d: float) -> void:\n\tcible.call_deferred()\n"
	code8.reload()
	var dernier8 := Node.new()
	dernier8.set_script(code8)
	dernier8.set("cible", _ca8_fin_image)
	dernier8.process_priority = 1000000
	dernier8.name = "Fin_des_calculs_audit"
	add_child(dernier8)
	var lieux8: Array = []
	for l8 in _ca8_args.get("lieux", []):
		lieux8.append([str(l8[0]), Vector3(float(l8[1]), float(l8[2]), float(l8[3]))])
	if bool(_ca8_args.get("neo", true)) and neo_v94 != null and neo_v94.get("tours") != null and neo_v94.tours != null:
		for t8 in neo_v94.tours.tours:
			if t8.has("sortie"):
				lieux8.append(["neopolis", (t8["sortie"] as Vector3) + Vector3.UP * 0.3])
				break
	for l8 in lieux8:
		await _ca8_lieu(l8[0], l8[1])
