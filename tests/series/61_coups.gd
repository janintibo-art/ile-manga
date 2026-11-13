## Les sensations des coups (V141) : l'ennemi touché plie puis se redresse ; le coup final d'un
## enchaînement le met à terre (il tombe, reste au sol, se relève) ; les gros ennemis titubent sans
## tomber ; un boss ne fait que plier ; une bête figée le reste ; le coup plongeant (frapper en plein
## saut) frappe tout autour avec une onde de choc ; le sol frappé (VR) ; le sang seulement en
## « Public averti » ; les textes en anglais.
const NOM := "coups"


func _vider() -> void:
	for b in faune_v132.betes.duplicate():
		if is_instance_valid(b):
			b.queue_free()
	faune_v132.betes.clear()


## Une bête juste devant le héros ; elle ne meurt pas (beaucoup de points de vie).
func _cible(kind: String = "sanglier", d: float = 1.4, actif: bool = true) -> Node3D:
	var q: Vector3 = _pos() + hero_v28.facing * d
	q.y = _height_at(q.x, q.z) + 0.1
	var b: Node3D = faune_v132.spawn(kind, q)
	b.hp = 999
	if not actif:
		b.set_physics_process(false)
	return b


func _sol() -> void:
	for k in range(60):
		if str(hero_v28.state) == "sol":
			return
		await _att(0.05)


func _cnt(k: String) -> int:
	return int(coups_v141.count.get(k, 0))


## Un enchaînement complet à la lame (trois coups, le dernier est le coup final).
func _enchainer() -> void:
	await _sol()
	var f0: int = _cnt("final")
	hero_v28.attack()
	for k in range(90):
		await _att(0.03)
		hero_v28.stamina = hero_v28.STAMINA_MAX
		if str(hero_v28.state) == "attaque":
			hero_v28.attack()
		if _cnt("final") > f0:
			break


func _penche(b: Node3D) -> float:
	return absf(b.rotation.x) + absf(b.rotation.z)


func _serie() -> void:
	testeur_v78._faune_v132("elfes")
	await _att(0.5)
	faune_v132.enabled = false
	_vider()
	testeur_v78._pick("h_tout")
	await _att(0.3)
	_close_dialogue_v31()
	await _att(0.2)
	inventory_v28.equip_item("epee")
	await _att(0.3)
	await _sol()
	_ok(str(hero_v28.weapon) == "epee", "l'épée en main (%s)" % str(hero_v28.weapon))
	testeur_v78.invincible = true
	# --- un coup simple : l'ennemi plie sous le coup, puis se redresse
	var b1: Node3D = _cible()
	await _att(0.2)
	var plie0: int = _cnt("plie") + _cnt("titube")
	hero_v28.attack()
	var max_p: float = 0.0
	for k in range(30):
		await _att(0.02)
		max_p = maxf(max_p, _penche(b1))
	# (un coup critique, de temps en temps, le fait même tituber)
	_ok(_cnt("plie") + _cnt("titube") > plie0 and max_p > 0.03, "un coup : l'ennemi plie sous le choc (%.2f rad)" % max_p)
	await _att(0.6)
	_ok(_penche(b1) < 0.01, "puis il se redresse (%.3f rad)" % _penche(b1))
	_vider()
	await _sol()
	# --- le coup final d'un enchaînement : un ennemi moyen tombe à terre, puis se relève
	var b2: Node3D = _cible("sanglier")
	await _att(0.2)
	var terre0: int = _cnt("terre")
	await _enchainer()
	await _att(0.1)
	_ok(_cnt("terre") > terre0 and coups_v141.a_terre(b2), "coup final : le sanglier tombe à terre")
	_ok(not b2.is_physics_processing(), "à terre, il ne bouge plus")
	var max_t: float = 0.0
	for k in range(40):
		await _att(0.02)
		max_t = maxf(max_t, _penche(b2))
	_ok(max_t > 1.0 and _cnt("tombe") >= 1, "il bascule à la renverse dans la poussière (%.2f rad)" % max_t)
	await _att(1.6)
	_ok(not coups_v141.a_terre(b2) and b2.is_physics_processing() and _penche(b2) < 0.02, "puis il se relève et reprend (%.3f rad)" % _penche(b2))
	_vider()
	await _sol()
	# --- un gros ennemi titube, sans tomber
	var b3: Node3D = _cible("aurochs", 1.8)
	await _att(0.2)
	var tit0: int = _cnt("titube")
	await _enchainer()
	await _att(0.1)
	_ok(_cnt("titube") > tit0 and not coups_v141.a_terre(b3), "coup final : l'aurochs titube mais ne tombe pas")
	await _att(1.0)
	_ok(b3.is_physics_processing(), "l'aurochs reprend")
	_vider()
	await _sol()
	# --- un boss ne fait que plier
	var b4: Node3D = _cible("sanglier")
	var sp: Dictionary = (b4.spec as Dictionary).duplicate()
	sp["pv"] = 80
	b4.spec = sp
	await _att(0.2)
	var t0: int = _cnt("titube") + _cnt("terre")
	var p0: int = _cnt("plie")
	await _enchainer()
	await _att(0.1)
	_ok(_cnt("titube") + _cnt("terre") == t0 and _cnt("plie") > p0, "un boss ne fait que plier, il ne tombe pas")
	_vider()
	await _sol()
	# --- une bête figée (les tests, un piège) le reste
	var b5: Node3D = _cible("sanglier", 1.4, false)
	await _att(0.2)
	await _enchainer()
	await _att(2.4)
	_ok(not b5.is_physics_processing() and _penche(b5) < 0.02, "une bête figée reste figée après le coup final")
	_vider()
	await _sol()
	# --- le coup plongeant : en plein saut, frapper ; on fond sur le sol, l'onde de choc
	var b6: Node3D = _cible("sanglier", 1.6)
	await _att(0.2)
	var dep: Vector3 = _pos()
	place_player_v35(dep + Vector3.UP * 3.0, hero_v28.facing)
	await _images(3)
	var slams0: int = int(combat_v28.slams)
	var onde0: int = _cnt("onde")
	var pl0: int = int(hero_v28.plongees)
	_ok(str(hero_v28.state) == "air", "en plein saut (%s)" % str(hero_v28.state))
	hero_v28.attack()
	await _images(1)
	_ok(str(hero_v28.state) == "plonge", "coup plongeant : il fond sur le sol (%s)" % str(hero_v28.state))
	for k in range(80):
		await _att(0.03)
		if int(hero_v28.plongees) > pl0:
			break
	_ok(int(hero_v28.plongees) > pl0 and int(combat_v28.slams) > slams0 and _cnt("onde") > onde0, "coup plongeant : le sol tremble, l'onde de choc")
	_ok(int(b6.hp) < 999 and coups_v141.a_terre(b6), "coup plongeant : le sanglier tout près est touché et tombe (%d pv)" % int(b6.hp))
	await _att(0.7)
	_ok(str(hero_v28.state) == "sol", "puis le héros se relève (%s)" % str(hero_v28.state))
	_vider()
	await _sol()
	# --- le sol frappé (en VR : frapper vers le bas jusqu'au sol) : tout près on titube, loin, rien
	var pres: Node3D = _cible("sanglier", 1.0)
	var loin: Node3D = _cible("sanglier", 4.5)
	await _att(0.3)
	var at: Vector3 = _pos() + hero_v28.facing * 0.3
	at.y = _height_at(at.x, at.z)
	var n: int = int(combat_v28.slam(at, 2.0, 5, 2))
	await _att(0.05)
	_ok(n >= 1 and int(pres.hp) < 999 and int(loin.hp) == 999, "le sol frappé : il touche tout près (%d), pas plus loin" % n)
	_vider()
	await _sol()
	# --- le sang : seulement en « Public averti »
	var Pub = load("res://scripts/public_v111.gd")
	var mode0: String = str(Pub.mode)
	var choisi0: bool = bool(Pub.choisi)
	Pub.choisir("tout", false)
	var b7: Node3D = _cible("sanglier")
	await _att(0.2)
	var s0: int = _cnt("sang")
	hero_v28.attack()
	await _att(0.6)
	_ok(_cnt("sang") == s0, "« Tout public » : pas de sang")
	Pub.choisir("averti", false)
	await _sol()
	hero_v28.attack()
	await _att(0.6)
	_ok(_cnt("sang") > s0, "« Public averti » : un peu de sang sur les bêtes de chair")
	Pub.mode = mode0
	Pub.choisi = choisi0
	_vider()
	testeur_v78.invincible = false
	inventory_v28.equip_item("")
	await _att(0.3)
	# --- en anglais
	var L = load("res://scripts/langue_v104.gd")
	L.choisir("en", false)
	var t1: String = L.t("À terre !")
	L.choisir("fr", false)
	_ok(t1 == "Down!", "anglais : « %s »" % t1)
