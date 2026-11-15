## La vie et la beauté des tours de Néopolis (V156) : les étages à part (le laboratoire, le studio de
## télévision, le jardin suspendu, la salle de sport, la piscine sous verrière) se bâtissent et l'on y
## tient debout ; on descend dans le bassin ; des gens marchent dans les couloirs ; les portes de
## l'ascenseur s'ouvrent et se referment ; la nuit, les bureaux se vident (le vigile, les robots de
## ménage) ; les matières des intérieurs ; l'anglais.
const NOM := "vie"
const Langue := preload("res://scripts/langue_v104.gd")


func _etage_de(T: Node, ty: String) -> Array:
	var best: Array = []
	for t in T.tours:
		var n: int = (t["etages"] as Array).size()
		for k in range(n):
			if T.type_etage(int(t["id"]), k) == ty:
				if best.is_empty() or n > (T.tours[int(best[0])]["etages"] as Array).size():
					best = [int(t["id"]), k]
				break
	return best


func _entrer(T: Node, id: int, k: int) -> void:
	var t: Dictionary = T.tours[id]
	place_player_v35((t["sortie"] as Vector3) + Vector3.UP * 0.3, -(t["n"] as Vector3))
	await _att(0.8)
	T.enter(id)
	await _att(1.0)
	if k > 0:
		T.aller(k)
		await _att(0.8)


func _sortir(T: Node) -> void:
	T.aller(0)
	await _att(0.5)
	T.leave()
	await _att(0.8)


func _serie() -> void:
	var T: Node = neo_v94.tours
	_ok(T != null, "les tours de Néopolis sont là")
	if T == null:
		return
	T.test_mode = true
	temps_v56.set_hour(14.0)
	# --- les étages à part
	var trouves: Array = []
	for ty in ["labo", "studio", "jardin", "sport", "piscine"]:
		var tk: Array = _etage_de(T, ty)
		if tk.is_empty():
			_ok(false, "un étage « %s »" % ty)
			continue
		trouves.append(ty)
		await _entrer(T, int(tk[0]), int(tk[1]))
		_ok(str(T.info.get("type", "")) == ty and T._gens.size() >= 1, "%s : %s, %dᵉ étage (%d personnes)" % [ty, str(T.tours[int(tk[0])]["nom"]), int(tk[1]), T._gens.size()])
		_ok(await _debout(ty, 0.8), "on tient debout : %s" % ty)
		if ty == "piscine":
			var B: Rect2 = T.info["bassin"]
			var y: float = T.info["y"]
			_ok(B.size.x >= 3.0 and not T._eaux.is_empty(), "le bassin (%.0f × %.0f m), l'eau qui ondule" % [B.size.x, B.size.y])
			place_player_v35(Vector3(B.get_center().x, y + 0.3, B.get_center().y), Vector3.FORWARD)
			await _att(1.5)
			_ok(absf(_pos().y - (y - 1.35)) < 0.5, "on descend dans le bassin (les pieds à %.2f m sous le bord)" % (y - _pos().y))
			place_player_v35((T.info["ascenseur"] as Vector3) + Vector3.UP * 0.1, T.info["regard"])
			await _att(0.5)
		await _sortir(T)
	_ok(trouves.size() >= 4, "les étages à part : %s" % str(trouves))
	# --- des gens qui marchent ; les portes de l'ascenseur
	var idb: int = -1
	for t in T.tours:
		if str(t["type"]) == "bureaux" and (idb < 0 or (t["etages"] as Array).size() > (T.tours[idb]["etages"] as Array).size()):
			idb = int(t["id"])
	await _entrer(T, idb, 0)
	_ok(T._marcheurs.size() >= 1, "des passants dans le hall (%d)" % T._marcheurs.size())
	if not T._marcheurs.is_empty():
		var f: Node = T._marcheurs[0]["f"]
		var p0: Vector3 = f.npc.global_position
		await _att(2.0)
		_ok(f.npc.global_position.distance_to(p0) > 0.6 and str(f.pose) == "marcher", "ils marchent (%.1f m en deux secondes)" % f.npc.global_position.distance_to(p0))
	await _att(2.5)
	var pa: Array = T.info["portes_asc"]
	_ok(pa.size() == 2 and (pa[0][0] as Node3D).global_position.distance_to(pa[0][1]) < 0.05, "les portes de l'ascenseur se sont refermées")
	place_player_v35((T.info["ascenseur"] as Vector3) + Vector3.UP * 0.1, T.info["regard"])
	await _att(0.4)
	T.ascenseur()
	await _att(1.0)
	_ok((pa[0][0] as Node3D).global_position.distance_to(pa[0][2]) < 0.05, "on appelle l'ascenseur : les portes s'ouvrent")
	T._choix_ascenseur("rester")
	await _att(1.4)
	_ok((pa[0][0] as Node3D).global_position.distance_to(pa[0][1]) < 0.05, "on reste : elles se referment")
	# --- la nuit, les bureaux
	var kb: int = -1
	for k in range(1, (T.tours[idb]["etages"] as Array).size()):
		if T.type_etage(idb, k) == "bureaux":
			kb = k
			break
	T.aller(kb)
	await _att(0.6)
	var jour: int = T._gens.size() - T._marcheurs.size()
	T.aller(0)
	await _att(0.5)
	temps_v56.set_hour(23.0)
	T.aller(kb)
	await _att(0.6)
	var nuit: int = T._gens.size() - T._marcheurs.size()
	_ok(T.info.get("nuit", false) and nuit < jour and T._marcheurs.size() == 2, "la nuit, les bureaux se vident (%d le jour, %d la nuit ; le vigile, le robot de ménage)" % [jour, nuit])
	_ok(await _debout("la nuit", 0.6), "on tient debout la nuit")
	temps_v56.set_hour(14.0)
	await _sortir(T)
	# --- les matières : de vraies textures, avec leur relief
	var Mats := preload("res://scripts/neo_mats_v153.gd")
	var m: StandardMaterial3D = Mats.mat("in_bois") as StandardMaterial3D
	var tex: bool = ResourceLoader.exists("res://assets/textures/neo156/bois_noyer.png")
	_ok(not tex or (m.albedo_texture != null and m.normal_enabled), "les matières des intérieurs (textures : %s)" % str(tex))
	T.test_mode = false
	# --- l'anglais
	Langue.choisir("en", false)
	var e1: String = Langue.t("12ᵉ étage — le studio de télévision")
	var e2: String = Langue.t("Ronde de nuit. Tout est calme.")
	var e3: String = Langue.t("JARDIN SUSPENDU")
	Langue.choisir("fr", false)
	_ok(e1 == "Floor 12 — the TV studio" and e2 == "Night patrol. All quiet." and e3 == "HANGING GARDEN", "en anglais : %s · %s · %s" % [e1, e2, e3])
