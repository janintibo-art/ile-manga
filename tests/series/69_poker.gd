## Le poker de Pile-ou-Face (V149) : les combinaisons (de la hauteur à la quinte flush, l'as en bas de la
## quinte, les départages), la meilleure main de sept cartes, des mains entières entre adversaires
## (Texas Hold'em et cinq cartes : les enchères finissent, le pot est juste), l'échange ; le Saloon du Chien
## qui Mise (la porte, la grande table, la Shérif, Zoé, le Doc) et des mains de Texas Hold'em ; le
## Coupe-Chou et son Terrier (le rideau, la petite table) et des mains à cinq cartes ; les comptes justes ;
## se coucher et se lever ; l'anglais.
const NOM := "poker"
const PokerS := preload("res://scripts/poker_v149.gd")
const Public := preload("res://scripts/public_v111.gd")
const Langue := preload("res://scripts/langue_v104.gd")


func _m(s: String) -> Array:
	# « AP KC 10D » : valeur (A, 2…10, V, D, R) et couleur (P pique, C cœur, K carreau, T trèfle)
	var out: Array = []
	for t in s.split(" "):
		var c: String = t.substr(t.length() - 1)
		var r: String = t.substr(0, t.length() - 1)
		var rv: int = {"A": 1, "V": 11, "D": 12, "R": 13}.get(r, int(r))
		out.append({"r": rv, "c": {"P": 0, "C": 1, "K": 2, "T": 3}[c]})
	return out


func _cat(s: String) -> int:
	return int(PokerS.valeur5(_m(s))[0])


func _entrer(lieu: String) -> bool:
	var e0: Dictionary = {}
	for e in preload("res://scripts/azur_kit_v56.gd").PORTES_V81:
		if str(e.get("histoire", "")) == lieu:
			e0 = e
	if e0.is_empty():
		return false
	_poser((e0["door"] as Vector3) + (e0["out"] as Vector3) * 1.2, -(e0["out"] as Vector3))
	await _att(0.6)
	maisons_v81.enter(maisons_v81.nearest(e0["door"], 2.5))
	for k in range(60):
		await _att(0.1)
		if maisons_v81.inside and not maisons_v81.busy:
			break
	return maisons_v81.inside and str(maisons_v81.ctx.get("scenario", "")) == lieu


## Joue des mains (on suit, on relance parfois, on échange deux cartes) ; rend [mains finies, comptes justes].
func _mains(J: Node, n: int) -> Array:
	var finies: int = 0
	var justes: bool = true
	for h in range(n):
		var av: int = inventory_v28.count("jeton")
		J._choix("donner", {})
		var f: int = 0
		while J.en_partie and f < 3000:
			f += 1
			await _images(1)
			if J.en_partie and J.pk != null and J.pk.tour == 0:
				if J.pk.mode == "cinq" and J.pk.etape == 0 and J.pk.tour_fini():
					J._pk_jeter = [false, false, false, true, true]
					J.tapis.choisi.emit("echanger", {})
				else:
					J.tapis.choisi.emit("relancer" if (f + h) % 7 == 0 else "suivre", {})
			elif J.en_partie and J.pk != null and J.pk.mode == "cinq" and J.pk.etape == 0 and J.pk.tour_fini():
				J._pk_jeter = [false, false, false, true, true]
				J.tapis.choisi.emit("echanger", {})
		if not J.en_partie:
			finies += 1
		var net: int = inventory_v28.count("jeton") - av
		var somme: int = 0
		for j in J.pk.joueurs:
			somme += int(j["total"])
		if somme != J.pk.pot or J._pk_paye != int(J.pk.joueurs[0]["total"]) or net > J.pk.pot or net < -J._pk_paye:
			justes = false
			print("main %d : pot %d, somme %d, payé %d, net %d" % [h, J.pk.pot, somme, J._pk_paye, net])
	return [finies, justes]


func _serie() -> void:
	var J: Node = jeux_v147
	_ok(J != null, "les jeux de Pile-ou-Face sont là")
	# --- les combinaisons
	_ok(_cat("AP 7C 9K VT 3P") == 0 and _cat("AP AC 9K VT 3P") == 1 and _cat("AP AC 9K 9T 3P") == 2 and _cat("AP AC AK 9T 3P") == 3, "hauteur, paire, deux paires, brelan")
	_ok(_cat("5P 6C 7K 8T 9P") == 4 and _cat("AP 2C 3K 4T 5P") == 4 and _cat("10P VC DK RT AP") == 4 and _cat("RP AC 2K 3T 4P") == 0, "les quintes (l'as en haut ou en bas, pas autour)")
	_ok(_cat("2C 7C 9C VC RC") == 5 and _cat("AP AC AK 9T 9P") == 6 and _cat("AP AC AK AT 9P") == 7 and _cat("5C 6C 7C 8C 9C") == 8, "couleur, full, carré, quinte flush")
	_ok(PokerS.compare(PokerS.valeur5(_m("AP AC 9K 7T 3P")), PokerS.valeur5(_m("RP RC DK VT 10P"))) > 0
		and PokerS.compare(PokerS.valeur5(_m("AP AC 9K 7T 3P")), PokerS.valeur5(_m("AK AT 9P 7C 2P"))) > 0
		and PokerS.compare(PokerS.valeur5(_m("AP 2C 3K 4T 5P")), PokerS.valeur5(_m("2P 3C 4K 5T 6P"))) < 0
		and PokerS.compare(PokerS.valeur5(_m("AP AC 9K 7T 3P")), PokerS.valeur5(_m("AK AT 9P 7C 3C"))) == 0, "les départages (les kickers, la petite quinte, l'égalité)")
	var b7: Array = PokerS.meilleure(_m("AP AC 9K 9T 3P RC AK"))
	_ok(int(b7[0][0]) == 6 and (b7[1] as Array).size() == 5, "la meilleure main de sept cartes : %s" % PokerS.nom_combinaison(b7[0]))
	# --- des mains entières entre adversaires
	var ok_h: int = 0
	var ok_c: int = 0
	for g in range(12):
		for mode in ["holdem", "cinq"]:
			var p = PokerS.new([{"id": "a", "nom": "A"}, {"id": "b", "nom": "B", "bluff": 0.4}, {"id": "c", "nom": "C", "prudence": 0.8}, {"id": "d", "nom": "D"}], mode, 300 + g)
			p.petite = 2
			p.grosse = 4
			p.nouvelle_main(1)
			var garde: int = 0
			var fin: bool = false
			while not fin and garde < 200:
				while not p.tour_fini() and garde < 200:
					garde += 1
					p.agir(str(p.decider(p.tour)[0]))
				if p.actifs().size() <= 1:
					break
				if mode == "cinq" and p.etape == 0:
					for i in p.actifs():
						p.echanger(i, p.a_jeter(i))
				fin = not p.etape_suivante()
			var somme: int = 0
			for j in p.joueurs:
				somme += int(j["total"])
			var ab: Array = p.abattage()
			var juste: bool = somme == p.pot and garde < 200 and not (ab[0] as Array).is_empty()
			if mode == "holdem" and p.actifs().size() > 1:
				juste = juste and p.communes.size() == 5
			if juste:
				if mode == "holdem":
					ok_h += 1
				else:
					ok_c += 1
	_ok(ok_h == 12 and ok_c == 12, "des mains entières entre adversaires (Hold'em %d/12, cinq cartes %d/12)" % [ok_h, ok_c])
	var pe = PokerS.new([{"id": "a"}, {"id": "b"}], "cinq", 9)
	pe.nouvelle_main(1)
	var avant: Array = (pe.joueurs[0]["cartes"] as Array).duplicate()
	pe.echanger(0, [0, 1])
	_ok((pe.joueurs[0]["cartes"] as Array).size() == 5 and pe.joueurs[0]["cartes"][4] == avant[4] and pe.max_echange(0) >= 3, "l'échange de cartes")
	# --- le Saloon
	J.load_data({})
	Public.oublier()
	var tp: Array = teleport_v58.spot("perchee")
	place_player_v35(tp[0], tp[1])
	await _att(1.0)
	_ok(await _entrer("pp_saloon"), "on pousse les portes du Saloon du Chien qui Mise")
	_ok(await _debout("dans le Saloon", 0.6), "on tient debout dans le Saloon")
	var t: Dictionary = J.tables.get("poker", {})
	var advs: int = 0
	for a in t.get("adversaires", []):
		if a != null and is_instance_valid(a):
			advs += 1
	_ok(advs == 3 and (t.get("places", []) as Array).size() == 4, "la grande table : la Shérif, Zoé et le Doc (%d)" % advs)
	J.test_mode = true
	inventory_v28.remove("jeton", inventory_v28.count("jeton"))
	inventory_v28.add("jeton", 300)
	J.pk_mode = "holdem"
	J.asseoir("poker")
	_ok(J.assis == "poker" and J.tapis.opened, "assis à la grande table")
	var r1: Array = await _mains(J, 5)
	_ok(int(r1[0]) == 5, "cinq mains de Texas Hold'em jusqu'au bout (%d)" % int(r1[0]))
	_ok(bool(r1[1]), "les comptes sont justes (le pot, les blindes, les mises)")
	_ok(int(J.etat.get("mains_poker", 0)) >= 5, "les mains sont comptées")
	# V150 : Joker, le chien qui mise ; le banjo ; le pot en jetons
	_ok(maisons_v81.room.find_child("Joker", true, false) != null, "Joker, le chien qui mise, est couché près de la table")
	_ok(maisons_v81.room.find_child("Banjo", true, false) != null, "le musicien a son banjo")
	J._apres_coup(5, 2)
	_ok(J.fete > 0.0, "on gagne : Joker est content")
	_ok(J._pot_pile.is_empty(), "le pot est ramassé à la fin de la main")
	J.lever()
	maisons_v81._teardown()
	await _att(0.4)
	# --- le Coupe-Chou et le Terrier
	place_player_v35(tp[0], tp[1])
	await _att(0.8)
	_ok(await _entrer("pp_barbier"), "on entre au Coupe-Chou")
	var t2: Dictionary = J.tables.get("poker", {})
	_ok(not t2.is_empty() and str(t2.get("titre", "")).contains("Moustaches"), "derrière le rideau : le Club des Moustaches (Tout public)")
	J.pk_mode = "cinq"
	J.asseoir("poker")
	var r2: Array = await _mains(J, 4)
	_ok(int(r2[0]) == 4 and bool(r2[1]), "quatre mains à cinq cartes, avec l'échange, les comptes justes (%d)" % int(r2[0]))
	# se coucher et se lever
	J._choix("donner", {})
	var f2: int = 0
	while J.en_partie and f2 < 2000:
		f2 += 1
		await _images(1)
		if J.en_partie and J.pk != null and J.pk.tour == 0:
			J.tapis.choisi.emit("lever", {})
	_ok(not J.en_partie and J.assis == "", "« Se coucher et se lever »")
	J.test_mode = false
	maisons_v81._teardown()
	await _att(0.3)
	# --- l'anglais
	Langue.choisir("en", false)
	var e1: String = Langue.t("Le Texas Hold'em : deux cartes cachées chacun, cinq cartes communes. Les blindes : 1 et 2. On mise 2, puis 4 au tournant et à la rivière.")
	var e2: String = Langue.t("Vos cartes : AP RC (Une paire)".replace("AP RC", "A♠ R♥"))
	var e3: String = Langue.t("Se coucher")
	Langue.choisir("fr", false)
	_ok(e1.begins_with("Texas") and e2.begins_with("Your cards") and e2.contains("pair") and e3 == "Fold", "en anglais : %s · %s" % [e2, e3])
