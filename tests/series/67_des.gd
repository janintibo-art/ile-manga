## Les dés de Pile-ou-Face (V147) : les dés (les faces, le lancer), la règle du Menteur et ses adversaires,
## la Fosse aux Dés (on y entre, les trois tables, la Caisse, les habitués), les jetons du jour et les lots
## (« Tout public »), le Grand Lancer et le Sept (la mise, le gain, la perte), une partie de Menteur
## jusqu'au bout, la réputation (de pigeon à maître du jeu), le clavier assis (Échap : se lever), les
## pièces et les objets misés (« Public averti »), la sauvegarde, l'anglais.
const NOM := "des"
const Public := preload("res://scripts/public_v111.gd")
const DesS := preload("res://scripts/des_v147.gd")
const MenteurS := preload("res://scripts/menteur_v147.gd")
const JeuxS := preload("res://scripts/jeux_v147.gd")
const Langue := preload("res://scripts/langue_v104.gd")


func _attendre_libre(J: Node, max_s: float = 6.0) -> void:
	var t: float = 0.0
	while (J.occupe or J.en_partie) and t < max_s:
		await _images(2)
		t += 0.033


func _serie() -> void:
	var J: Node = jeux_v147
	_ok(J != null, "les jeux de Pile-ou-Face sont là")
	# --- les dés : chaque face se pose vers le haut
	var faces_ok: bool = true
	for v in range(1, 7):
		if DesS.face_haut(DesS.rot_face(v, randf() * TAU)) != v:
			faces_ok = false
	_ok(faces_ok, "les six faces des dés se posent comme il faut")
	var m: ArrayMesh = DesS.mesh(0.05)
	_ok(m != null and m.get_surface_count() == 1, "le dé : un maillage, sa texture")
	# --- la règle du Menteur (des parties entre adversaires seuls)
	_ok(absf(MenteurS.p_au_moins(1, 1) - 1.0 / 6.0) < 0.001 and MenteurS.p_au_moins(0, 5) == 1.0 and MenteurS.p_au_moins(4, 3) == 0.0, "les chances (au moins k dés sur n)")
	var finies: int = 0
	var tours_max: int = 0
	for g in range(20):
		var mt = MenteurS.new([{"id": "a", "nom": "A", "bluff": 0.5, "prudence": 0.3}, {"id": "b", "nom": "B", "bluff": 0.1, "prudence": 0.8}, {"id": "c", "nom": "C"}, {"id": "d", "nom": "D"}], 3, 100 + g)
		var tours: int = 0
		while not mt.fini() and tours < 400:
			mt.nouvelle_manche()
			var res: Dictionary = {}
			while res.is_empty() and tours < 400:
				tours += 1
				var d: Dictionary = mt.decider(mt.tour)
				if bool(d.get("menteur", false)):
					res = mt.menteur()
					if res.is_empty():
						mt.annoncer(1, 1)
				elif not mt.annoncer(int(d["q"]), int(d["f"])):
					res = mt.menteur()
		tours_max = maxi(tours_max, tours)
		if mt.fini() and mt.gagnant() >= 0 and mt.total_des() >= 1:
			finies += 1
	_ok(finies == 20, "vingt parties de Menteur entre adversaires vont jusqu'au bout (%d ; %d coups au plus)" % [finies, tours_max])
	var mv = MenteurS.new([{"id": "a"}, {"id": "b"}], 3, 7)
	mv.nouvelle_manche(0)
	_ok(mv.valide(1, 3) and mv.annoncer(2, 3) and not mv.valide(2, 2) and not mv.valide(1, 6) and mv.valide(2, 4) and mv.valide(3, 1), "on doit monter (plus de dés, ou une face plus haute)")
	var r: Dictionary = mv.menteur()
	_ok(int(r["compte"]) == mv.compte(3) and int(r["perdant"]) == (int(r["par"]) if not bool(r["vraie"]) else int(r["crieur"])), "« Menteur ! » : on compte, le bon perdant perd un dé")
	# --- la réputation
	_ok(JeuxS.titre_de(-60) == "Pigeon" and JeuxS.titre_de(-20) == "Bleu" and JeuxS.titre_de(0) == "Joueur" and JeuxS.titre_de(30) == "Fine lame" and JeuxS.titre_de(80) == "Maître du jeu", "les titres, de pigeon à maître du jeu")
	J.load_data({})
	Public.oublier()
	# --- la Fosse aux Dés : la porte, on entre
	var fosse: Dictionary = {}
	for e in preload("res://scripts/azur_kit_v56.gd").PORTES_V81:
		if str(e.get("histoire", "")) == "pp_fosse":
			fosse = e
	_ok(not fosse.is_empty() and str(fosse["style"]) == "perchee_lieu", "la porte de la Fosse aux Dés s'ouvre (un lieu où l'on entre)")
	if fosse.is_empty():
		return
	var tp: Array = teleport_v58.spot("perchee")
	place_player_v35(tp[0], tp[1])
	await _att(1.0)
	_poser((fosse["door"] as Vector3) + (fosse["out"] as Vector3) * 1.2, -(fosse["out"] as Vector3))
	await _att(0.6)
	var mi: int = maisons_v81.nearest(fosse["door"], 2.5)
	_ok(mi >= 0, "devant la porte de la Fosse")
	maisons_v81.enter(mi)
	for k in range(60):
		await _att(0.1)
		if maisons_v81.inside and not maisons_v81.busy:
			break
	_ok(maisons_v81.inside and str(maisons_v81.ctx.get("scenario", "")) == "pp_fosse", "on descend à la Fosse aux Dés")
	_ok(await _debout("dans la Fosse", 0.6), "on tient debout dans la Fosse")
	_ok(J.tables.has("lancer") and J.tables.has("sept") and J.tables.has("menteur") and J.tables.has("caisse"), "les trois tables et la Caisse (%s)" % str(J.tables.keys()))
	var advs: int = 0
	for a in (J.tables.get("menteur", {}) as Dictionary).get("adversaires", []):
		if a != null and is_instance_valid(a):
			advs += 1
	_ok(advs == 3, "Abélard, Hilda et la Veuve Clou à la table du Menteur (%d)" % advs)
	_ok(J.tables["lancer"].get("croupier") != null, "Grand-Dé tient le Grand Lancer")
	_ok(maisons_v81.people.size() >= 7, "du monde dans la Fosse (%d)" % maisons_v81.people.size())
	J.test_mode = true
	# --- la Caisse : les jetons du jour, une seule fois par jour ; un lot
	inventory_v28.remove("jeton", inventory_v28.count("jeton"))
	J.asseoir("caisse")
	_ok(J.assis == "caisse" and J.tapis.opened, "à la Caisse : le tapis s'ouvre")
	J._choix("jetons_jour", {})
	_ok(inventory_v28.count("jeton") == 30, "les jetons du jour : 30 (%d)" % inventory_v28.count("jeton"))
	J._choix("jetons_jour", {})
	_ok(inventory_v28.count("jeton") == 30, "pas deux fois le même jour")
	J._choix("lot_salsepareille", {})
	_ok(inventory_v28.count("jeton") == 15 and inventory_v28.count("salsepareille") >= 1, "un lot : une salsepareille pour 15 jetons")
	inventory_v28.add("jeton", 85)
	J.lever()
	_ok(J.assis == "", "on se lève")
	# --- le Grand Lancer
	J.asseoir("lancer")
	_ok(J.assis == "lancer" and _pos().distance_to(J.tables["lancer"]["siege"]) < 1.0, "assis au Grand Lancer")
	var gagne: int = 0
	var perdu: int = 0
	var juste: bool = true
	for k in range(12):
		var avant: int = inventory_v28.count("jeton")
		J.mise = 5
		J._choix("lancer", {})
		await _attendre_libre(J)
		var apres: int = inventory_v28.count("jeton")
		var net: int = apres - avant
		if not (net in [-5, 0, 5, 10]):
			juste = false
		if net > 0:
			gagne += 1
		elif net < 0:
			perdu += 1
	_ok(juste and gagne + perdu > 0, "douze lancers : %d gagnés, %d perdus, les comptes sont justes" % [gagne, perdu])
	_ok(J._des.size() == 4, "les quatre dés sont sur le tapis")
	_ok(int(J.etat["coups"]) >= 12, "les coups sont comptés (%d)" % int(J.etat["coups"]))
	# Échap : on se lève
	_appui(KEY_ESCAPE)
	await _images(4)
	_ok(J.assis == "" and not J.tapis.opened, "Échap : on se lève de table")
	# --- le Sept
	J.asseoir("sept")
	var juste7: bool = true
	for p in [1, 2, 3, 2, 1, 3, 2, 2]:
		J.pari = p
		J.mise = 2
		var av: int = inventory_v28.count("jeton")
		J._choix("lancer", {})
		await _attendre_libre(J)
		var n7: int = inventory_v28.count("jeton") - av
		if not (n7 == -2 or (p != 2 and n7 == 2) or (p == 2 and n7 == 8)):
			juste7 = false
	_ok(juste7, "le Sept : les gains sont justes (×2, ×5 sur le sept)")
	J.lever()
	# --- une partie de Menteur jusqu'au bout
	var av_m: int = inventory_v28.count("jeton")
	J.asseoir("menteur")
	J._choix("prendre_place", {})
	_ok(J.en_partie and inventory_v28.count("jeton") == av_m - 5, "on prend place (5 jetons)")
	var f: int = 0
	while J.en_partie and f < 6000:
		f += 1
		await _images(1)
		if J.menteur != null and J.menteur.tour == 0 and J.en_partie:
			if J.menteur.enchere.is_empty() or J.menteur.chance(0, int(J.menteur.enchere["q"]), int(J.menteur.enchere["f"])) > 0.5:
				J.tapis.choisi.emit("annoncer", {})
			else:
				J.tapis.choisi.emit("menteur", {})
	_ok(not J.en_partie, "la partie de Menteur va jusqu'au bout (%d images)" % f)
	var fin_m: int = inventory_v28.count("jeton") - av_m
	_ok(fin_m == -5 or fin_m == 15, "le pot : %+d jetons" % fin_m)
	J.lever()
	# --- la réputation : trois défaites d'affilée, un titre qui change ; se lever avec un gain
	J.etat["rep"] = 0.0
	J.etat["serie"] = 0
	J._apres_coup(-5, 5)
	J._apres_coup(-5, 5)
	J._apres_coup(-5, 5)
	_ok(float(J.etat["rep"]) <= -7.0, "trois coups perdus d'affilée : la réputation baisse (%.0f)" % float(J.etat["rep"]))
	J.rep(-50.0)
	_ok(J.titre() == "Pigeon", "on devient « Pigeon »")
	J.etat["rep"] = 44.0
	J.asseoir("lancer")
	J._session = {"coups": 4, "net": 12}
	J.lever()
	_ok(J.titre() == "Maître du jeu", "se lever avec un gain : « Maître du jeu » (%.0f)" % float(J.etat["rep"]))
	# --- « Public averti » : des pièces, et un objet misé
	Public.choisir("averti", false)
	_ok(J.monnaie() == "piece", "Public averti : on mise des pièces")
	inventory_v28.add("piece", 20)
	inventory_v28.add("pepite_or", 1)
	J.asseoir("lancer")
	var objs: Array = J._objets_misables()
	_ok(objs.has("pepite_or"), "on peut miser une pépite d'or")
	J.objet = objs.find("pepite_or") + 1
	var pep: int = inventory_v28.count("pepite_or")
	var pc0: int = inventory_v28.count("piece")
	J._choix("lancer", {})
	await _attendre_libre(J)
	var pep2: int = inventory_v28.count("pepite_or")
	var pc2: int = inventory_v28.count("piece")
	_ok((pep2 == pep - 1 and pc2 == pc0) or (pep2 == pep and pc2 >= pc0), "la pépite misée : perdue, rendue ou gagnée (pépites %d→%d, pièces %d→%d)" % [pep, pep2, pc0, pc2])
	J.lever()
	Public.oublier()
	# --- la sauvegarde
	var s: Dictionary = J.serialize()
	J.load_data({})
	_ok(J.titre() == "Joueur", "une nouvelle partie : « Joueur »")
	J.load_data(s)
	_ok(J.titre() == "Maître du jeu" and int(J.etat["coups"]) >= 20, "la réputation et les coups sont gardés")
	# --- sortir : on se lève tout seul
	J.asseoir("sept")
	maisons_v81._teardown()
	await _att(0.3)
	_ok(J.assis == "", "en sortant de la Fosse, on se lève de table")
	J.test_mode = false
	# --- l'anglais
	Langue.choisir("en", false)
	var t1: String = Langue.t("Le Grand Lancer")
	var t2: String = Langue.t("Votre bourse : 25 jetons")
	var t3: String = Langue.t("Vous annoncez : 3 × 5")
	Langue.choisir("fr", false)
	_ok(t1 != "Le Grand Lancer" and t2.contains("25") and not t2.contains("bourse") and not t3.contains("annoncez"), "en anglais : %s · %s · %s" % [t1, t2, t3])
