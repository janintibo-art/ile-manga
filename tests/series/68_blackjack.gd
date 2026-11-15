## Le blackjack de Pile-ou-Face (V148) : les cartes (le sabot de quatre jeux, les valeurs, l'as souple, le
## blackjack, le règlement, la stratégie des voisins), le Tripot de la Dame de Pique (la porte, on y entre,
## la table en demi-lune, la donneuse, Gédéon et Fanchon, la Caisse), des mains jouées jusqu'au bout
## (tirer, rester, doubler), les comptes justes, se lever au milieu d'une main, l'anglais.
const NOM := "blackjack"
const BJS := preload("res://scripts/blackjack_v148.gd")
const CartesS := preload("res://scripts/cartes_v148.gd")
const Public := preload("res://scripts/public_v111.gd")
const Langue := preload("res://scripts/langue_v104.gd")


func _c(r: int, c: int = 0) -> Dictionary:
	return {"r": r, "c": c}


func _serie() -> void:
	var J: Node = jeux_v147
	_ok(J != null, "les jeux de Pile-ou-Face sont là")
	# --- la règle
	var b = BJS.new(5)
	_ok(b.sabot.size() == 208, "un sabot de quatre jeux (%d cartes)" % b.sabot.size())
	var vu: Dictionary = {}
	for c in b.sabot:
		vu["%d_%d" % [int(c["r"]), int(c["c"])]] = int(vu.get("%d_%d" % [int(c["r"]), int(c["c"])], 0)) + 1
	_ok(vu.size() == 52 and vu.values().max() == 4 and vu.values().min() == 4, "chaque carte quatre fois")
	_ok(BJS.total([_c(1), _c(13)]) == 21 and BJS.blackjack([_c(1), _c(12)]), "as + roi : blackjack")
	_ok(BJS.total([_c(1), _c(1), _c(9)]) == 21 and BJS.total([_c(1), _c(9), _c(5)]) == 15, "l'as compte 11 ou 1")
	_ok(bool(BJS.valeur([_c(1), _c(6)])[1]) and not bool(BJS.valeur([_c(10), _c(6)])[1]), "la main souple")
	_ok(BJS.saute([_c(10), _c(9), _c(5)]) and not BJS.saute([_c(10), _c(11)]), "au-dessus de 21 : on saute")
	_ok(BJS.donneuse_tire([_c(10), _c(6)]) and not BJS.donneuse_tire([_c(10), _c(7)]) and not BJS.donneuse_tire([_c(1), _c(6)]), "la donneuse tire jusqu'à 17")
	_ok(BJS.reglement([_c(1), _c(13)], [_c(10), _c(9)]) == 2.5 and BJS.reglement([_c(10), _c(9)], [_c(10), _c(8)]) == 2.0
		and BJS.reglement([_c(10), _c(8)], [_c(10), _c(8)]) == 1.0 and BJS.reglement([_c(10), _c(5), _c(9)], [_c(10), _c(5), _c(9)]) == 0.0
		and BJS.reglement([_c(10), _c(7)], [_c(10), _c(5), _c(9)]) == 2.0 and BJS.reglement([_c(1), _c(10)], [_c(1), _c(11)]) == 1.0, "le règlement (3 pour 2, 1 pour 1, égalité, sauté)")
	_ok(BJS.conseil([_c(10), _c(8)], _c(10)) == "rester" and BJS.conseil([_c(5), _c(6)], _c(6)) == "doubler" and BJS.conseil([_c(10), _c(6)], _c(10)) == "tirer", "les voisins jouent à la règle")
	for k in range(170):
		b.tirer()
	_ok(b.a_rebattre(), "le sabot presque vide : on rebat")
	var nd: Node3D = CartesS.carte(self, _c(12, 1), Vector3(0, 100, 0))
	_ok(nd.get_child_count() >= 4, "une carte : sa face, son dos, sa valeur")
	nd.queue_free()
	# --- le Tripot : la porte, on entre
	J.load_data({})
	Public.oublier()
	var tri: Dictionary = {}
	for e in preload("res://scripts/azur_kit_v56.gd").PORTES_V81:
		if str(e.get("histoire", "")) == "pp_tripot":
			tri = e
	_ok(not tri.is_empty(), "la porte du Tripot de la Dame de Pique s'ouvre")
	if tri.is_empty():
		return
	var tp: Array = teleport_v58.spot("perchee")
	place_player_v35(tp[0], tp[1])
	await _att(1.0)
	_poser((tri["door"] as Vector3) + (tri["out"] as Vector3) * 1.2, -(tri["out"] as Vector3))
	await _att(0.6)
	var mi: int = maisons_v81.nearest(tri["door"], 2.5)
	maisons_v81.enter(mi)
	for k in range(60):
		await _att(0.1)
		if maisons_v81.inside and not maisons_v81.busy:
			break
	_ok(maisons_v81.inside and str(maisons_v81.ctx.get("scenario", "")) == "pp_tripot", "on entre au Tripot")
	_ok(await _debout("dans le Tripot", 0.6), "on tient debout dans le Tripot")
	_ok(J.tables.has("blackjack") and J.tables.has("caisse"), "la table de blackjack et la Caisse (%s)" % str(J.tables.keys()))
	var t: Dictionary = J.tables.get("blackjack", {})
	_ok(t.get("croupier") != null and (t.get("adversaires", []) as Array).size() == 2 and (t.get("mains", []) as Array).size() == 4, "la Dame de Pique donne ; Gédéon et Fanchon jouent")
	# --- des mains, jusqu'au bout
	J.test_mode = true
	inventory_v28.remove("jeton", inventory_v28.count("jeton"))
	inventory_v28.add("jeton", 200)
	J.asseoir("blackjack")
	_ok(J.assis == "blackjack" and J.tapis.opened, "assis à la table de blackjack")
	var justes: bool = true
	var finies: int = 0
	var choix: Array = ["rester", "tirer", "doubler", "tirer", "rester", "doubler", "tirer", "rester", "tirer", "rester"]
	for h in range(10):
		J.mise = 4
		var av: int = inventory_v28.count("jeton")
		J._choix("distribuer", {})
		var f: int = 0
		while J.en_partie and f < 400:
			f += 1
			await _images(1)
			if J.en_partie:
				J.tapis.choisi.emit(str(choix[(h + f) % choix.size()]), {})
		if not J.en_partie:
			finies += 1
		var net: int = inventory_v28.count("jeton") - av
		var m: Array = J._bj_mains[0]
		var mult: float = BJS.reglement(m, J._bj_mains[3])
		var attendu: int = int(ceil(J._bj_mise * mult)) - J._bj_mise
		if net != attendu:
			justes = false
			print("main %d : %s contre %s, mise %d, net %d (attendu %d)" % [h, BJS.texte_main(m), BJS.texte_main(J._bj_mains[3]), J._bj_mise, net, attendu])
	_ok(finies == 10, "dix mains jouées jusqu'au bout (%d)" % finies)
	_ok(justes, "les comptes sont justes (blackjack, double, égalité)")
	_ok(int(J.etat["mains"]) >= 10, "les mains sont comptées (%d)" % int(J.etat["mains"]))
	_ok(not J._cartes.is_empty() and J._cartes.size() == (J._bj_mains[0] as Array).size() + (J._bj_mains[1] as Array).size() + (J._bj_mains[2] as Array).size() + (J._bj_mains[3] as Array).size(), "les cartes sont sur le tapis (%d)" % J._cartes.size())
	# --- se lever au milieu d'une main : on reste, puis on se lève
	# (une main où la donne finit tout de suite, un blackjack, ne demande rien : on en rejoue une)
	for essai in range(8):
		if J.assis == "":
			break
		J._choix("distribuer", {})
		var f2: int = 0
		while J.en_partie and f2 < 400:
			f2 += 1
			await _images(1)
			if J.en_partie:
				J.tapis.choisi.emit("lever", {})
	_ok(not J.en_partie and J.assis == "", "« Rester, et se lever » : la main finit, on se lève")
	# --- sortir pendant une main : elle ne reprend pas ailleurs
	J.asseoir("blackjack")
	J.test_mode = false
	J._choix("distribuer", {})
	await _images(3)
	maisons_v81._teardown()
	await _att(0.5)
	_ok(J.assis == "" and not J.en_partie, "en sortant du Tripot, on se lève (la main est abandonnée)")
	# --- l'anglais
	Langue.choisir("en", false)
	var t1: String = Langue.t("Le Blackjack de la Dame de Pique")
	var t2: String = Langue.t("Vous : A♠ R♥ (21)")
	var t3: String = Langue.t("Tirer une carte")
	Langue.choisir("fr", false)
	_ok(t1 != "Le Blackjack de la Dame de Pique" and t2.begins_with("You") and t3 == "Hit", "en anglais : %s · %s · %s" % [t1, t2, t3])
