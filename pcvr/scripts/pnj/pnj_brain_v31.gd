extends RefCounted
## V31 : petite IA de personnage, la même pour tous les habitants de l'île.
## Elle ne parle pas « au hasard » : chaque réplique de la fiche du personnage porte des
## conditions (humeur, amitié, visites, absence, souvenirs, ce que porte le joueur…).
## Le cerveau garde :
##  - une HUMEUR (de -1 furieux à +1 rayonnant) et une ÉNERGIE, qui reviennent doucement
##    vers le caractère de base du personnage ;
##  - une AMITIÉ (0 à 100) qui change le surnom donné au joueur et débloque des confidences ;
##  - une MÉMOIRE : rencontres, absences, cadeaux, sujets abordés, réponses du joueur,
##    coups reçus, quête, et les dernières répliques dites (pour ne pas se répéter).
## Tout est sauvegardé avec la partie.

var data: Dictionary
var rng := RandomNumberGenerator.new()
var humeur: float = 0.0
var energie: float = 0.5
var affinite: float = 0.0
var memoire: Dictionary = {}
var _pending_question: Dictionary = {}


func setup(profile: Dictionary) -> void:
	data = profile
	rng.randomize()
	reset()


func reset() -> void:
	humeur = float(data.get("humeur_base", 0.0))
	energie = float(data.get("energie_base", 0.5))
	affinite = float(data.get("affinite_depart", 10.0))
	memoire = {
		"visites": 0, "premiere": -1.0, "derniere": -1.0,
		"cadeaux": {}, "dernier_cadeau": "", "nb_cadeaux": 0,
		"sujets": {}, "faits": {}, "dites": [], "quete": "", "journal": [],
		# V33 : commerce (achats par objet, pièces dépensées et gagnées, marchandage par visite)
		"achats": {}, "depense": 0, "ventes": 0, "gain": 0, "marchande": -1, "remise": -1,
	}


# =================================================================== temps qui passe

## L'humeur et l'énergie reviennent lentement vers le caractère de base.
func tick(delta: float) -> void:
	var base_h: float = float(data.get("humeur_base", 0.0))
	var base_e: float = float(data.get("energie_base", 0.5))
	# Un caractère rancunier se remet plus lentement d'une contrariété.
	var rancune: float = float((data.get("traits", {}) as Dictionary).get("rancunier", 0.5))
	var rate: float = 0.002 * ((1.0 - 0.6 * rancune) if humeur < base_h else 1.0)
	humeur = move_toward(humeur, base_h, delta * rate)
	energie = move_toward(energie, base_e, delta * 0.003)


func _mood(dh: float, de: float = 0.0) -> void:
	humeur = clampf(humeur + dh, -1.0, 1.0)
	energie = clampf(energie + de, 0.0, 1.0)


func _bond(d: float) -> void:
	affinite = clampf(affinite + d, 0.0, 100.0)


func _remember(text: String, now: float) -> void:
	var j: Array = memoire["journal"]
	j.append([now, text])
	while j.size() > 24:
		j.pop_front()


# =================================================================== lecture de l'état

func humeur_mot() -> String:
	var mot: String = "pensif"
	for pair in data.get("humeur_mots", []):
		if humeur >= float(pair[0]):
			mot = str(pair[1])
			break
	if energie < 0.25:
		mot += ", fatigué"
	elif energie > 0.9:
		mot += ", surexcité"
	return mot


func humeur_famille() -> String:
	if humeur >= 0.35:
		return "joie"
	if humeur <= -0.45:
		return "colere"
	if humeur <= -0.1:
		return "triste"
	return "neutre"


func surnom() -> String:
	var s: String = "étranger"
	for pair in data.get("surnoms", []):
		if affinite >= float(pair[0]):
			s = str(pair[1])
	return s


func _absence_text(seconds: float) -> String:
	if seconds < 120.0:
		return "à peine deux minutes"
	if seconds < 900.0:
		return "un petit moment"
	if seconds < 3600.0:
		return "une bonne heure de marée"
	if seconds < 4.0 * 3600.0:
		return "des heures et des heures"
	return "une éternité"


# =================================================================== conditions et variables

## ctx : état du jeu fourni à chaque échange
## {now, objets: {id: nombre}, arme: String, vie: int, vie_max: int}
func _ok(cond: Dictionary, ctx: Dictionary) -> bool:
	var visits: int = int(memoire["visites"])
	var absent: float = float(ctx.get("now", 0.0)) - float(memoire.get("absence_ref", memoire["derniere"]))
	for key in cond:
		var v: Variant = cond[key]
		match key:
			"humeur_min":
				if humeur < float(v): return false
			"humeur_max":
				if humeur > float(v): return false
			"energie_min":
				if energie < float(v): return false
			"energie_max":
				if energie > float(v): return false
			"affinite_min":
				if affinite < float(v): return false
			"affinite_max":
				if affinite > float(v): return false
			"visites_min":
				if visits < int(v): return false
			"visites_max":
				if visits > int(v): return false
			"absent_min":
				if float(memoire["derniere"]) < 0.0 or absent < float(v): return false
			"absent_max":
				if float(memoire["derniere"]) < 0.0 or absent > float(v): return false
			"fait":
				if not _has_fact(str(v)): return false
			"pas_fait":
				if _has_fact(str(v)): return false
			"objet":
				if int((ctx.get("objets", {}) as Dictionary).get(str(v), 0)) <= 0: return false
			"arme":
				if (str(ctx.get("arme", "")) != "") != bool(v): return false
			"vie_basse":
				var low: bool = int(ctx.get("vie", 10)) <= int(ctx.get("vie_max", 10)) / 3
				if low != bool(v): return false
			"quete":
				if str(memoire["quete"]) != str(v): return false
			"sujet_min":
				var arr: Array = v
				if int((memoire["sujets"] as Dictionary).get(str(arr[0]), 0)) < int(arr[1]): return false
			# V32 : objets absents, cadeau précis, pêche.
			"pas_objet":
				if int((ctx.get("objets", {}) as Dictionary).get(str(v), 0)) > 0: return false
			"tient":
				if str(ctx.get("arme", "")) != str(v): return false
			"dernier_cadeau":
				if str(memoire["dernier_cadeau"]) != str(v): return false
			"peche_min":
				if int((ctx.get("peche", {}) as Dictionary).get("total", 0)) < int(v): return false
			"peche_max":
				if int((ctx.get("peche", {}) as Dictionary).get("total", 0)) > int(v): return false
			# V33 : les habitants savent qui le joueur a déjà rencontré.
			"a_rencontre":
				if int((ctx.get("rencontres", {}) as Dictionary).get(str(v), 0)) <= 0: return false
			"pas_rencontre":
				if int((ctx.get("rencontres", {}) as Dictionary).get(str(v), 0)) > 0: return false
			"achats_min":
				if int(memoire.get("depense", 0)) < int(v): return false
			"pas_achete":
				if int((memoire.get("achats", {}) as Dictionary).get(str(v), 0)) > 0: return false
			"a_achete":
				if int((memoire.get("achats", {}) as Dictionary).get(str(v), 0)) <= 0: return false
			# V34 : trésors déterrés, arbres abattus.
			"a_trouve":
				if int((ctx.get("trouvailles", {}) as Dictionary).get(str(v), 0)) <= 0: return false
			"pas_trouve":
				if int((ctx.get("trouvailles", {}) as Dictionary).get(str(v), 0)) > 0: return false
			"tresors_min":
				if int((ctx.get("trouvailles", {}) as Dictionary).get("tresors", 0)) < int(v): return false
			"monstres_min":
				if int((ctx.get("trouvailles", {}) as Dictionary).get("monstres", 0)) < int(v): return false
			"arbres_min":
				if int((ctx.get("trouvailles", {}) as Dictionary).get("arbres", 0)) < int(v): return false
			"a_attrape":
				if int(((ctx.get("peche", {}) as Dictionary).get("especes", {}) as Dictionary).get(str(v), 0)) <= 0: return false
	return true


func _has_fact(spec: String) -> bool:
	var faits: Dictionary = memoire["faits"]
	if spec.contains("="):
		var kv: PackedStringArray = spec.split("=")
		return str(faits.get(kv[0], "")) == kv[1]
	return faits.has(spec)


## Nom d'objet avec son article (« une pomme », « un caillou »), fourni par le jeu.
func _item_name(id: String, ctx: Dictionary) -> String:
	var arts: Dictionary = ctx.get("articles", {})
	if arts.has(id):
		return str(arts[id])
	var names: Dictionary = ctx.get("noms", {})
	return str(names.get(id, id)).to_lower()


func _fill(text: String, ctx: Dictionary) -> String:
	var q: Dictionary = data.get("quete", {})
	var shells: int = int((ctx.get("objets", {}) as Dictionary).get(str(q.get("objet", "")), 0))
	var objets: Dictionary = ctx.get("objets", {})
	var some: String = "tes poches vides"
	if not objets.is_empty():
		var keys: Array = objets.keys()
		some = _item_name(str(keys[rng.randi() % keys.size()]), ctx)
	var fav: String = ""
	var best: int = 0
	for s in memoire["sujets"]:
		if int(memoire["sujets"][s]) > best:
			best = int(memoire["sujets"][s])
			fav = str(s)
	var absent: float = float(ctx.get("now", 0.0)) - float(memoire.get("absence_ref", memoire["derniere"]))
	var peche: Dictionary = ctx.get("peche", {})
	var record: String = "rien du tout"
	if str(peche.get("record_id", "")) != "":
		record = _item_name(str(peche["record_id"]), ctx) + (" de %.2f kg" % float(peche.get("record_kg", 0.0))).replace(".", ",")
	var vars := {
		"{nb_poissons}": str(int(peche.get("total", 0))), "{record}": record,
		"{bouton}": "la gâchette" if bool(ctx.get("vr", false)) else "le clic",
		"{depense}": str(int(memoire.get("depense", 0))), "{objet}": _item_name(str(ctx.get("_objet", "")), ctx),
		"{prix}": str(int(ctx.get("_prix", 0))), "{pieces}": str(int((ctx.get("objets", {}) as Dictionary).get("piece", 0))),
		"{nb_tresors}": str(int((ctx.get("trouvailles", {}) as Dictionary).get("tresors", 0))),
		"{nb_arbres}": str(int((ctx.get("trouvailles", {}) as Dictionary).get("arbres", 0))),
		"{nb_especes}": str((peche.get("especes", {}) as Dictionary).size()),
		"{surnom}": surnom(), "{visites}": str(memoire["visites"]), "{absence}": _absence_text(absent),
		"{arme}": _item_name(str(ctx.get("arme", "")), ctx), "{objet_joueur}": some,
		"{dernier_cadeau}": _item_name(str(memoire["dernier_cadeau"]), ctx), "{nb_cadeaux}": str(memoire["nb_cadeaux"]),
		"{coquillages}": str(shells), "{manque}": str(int(q.get("nombre", 0))), "{humeur_mot}": humeur_mot(), "{sujet_prefere}": fav,
		"{manque_liste}": _missing_text(ctx),
	}
	for k in vars:
		text = text.replace(k, str(vars[k]))
	return text


## V41 : quête à plusieurs objets ("objets": {id: nombre}) : ce qu'il manque encore, en toutes lettres.
func _missing(ctx: Dictionary) -> Dictionary:
	var q: Dictionary = data.get("quete", {})
	var need: Dictionary = q.get("objets", {str(q.get("objet", "")): int(q.get("nombre", 1))})
	var have: Dictionary = ctx.get("objets", {})
	var out := {}
	for id in need:
		var m: int = int(need[id]) - int(have.get(id, 0))
		if m > 0:
			out[id] = m
	return out


func _missing_text(ctx: Dictionary) -> String:
	var miss: Dictionary = _missing(ctx)
	var parts: Array = []
	for id in miss:
		var art: String = str((ctx.get("articles", {}) as Dictionary).get(id, _item_name(str(id), ctx)))
		parts.append(art if int(miss[id]) == 1 else "%d × %s" % [int(miss[id]), _item_name(str(id), ctx)])
	if parts.is_empty():
		return "rien du tout"
	if parts.size() == 1:
		return str(parts[0])
	return ", ".join(parts.slice(0, parts.size() - 1)) + " et " + str(parts[-1])


# =================================================================== choix d'une réplique

## Parmi les répliques de l'intention dont les conditions sont remplies, on évite celles
## dites récemment et on favorise les plus « spécifiques » (plus de conditions = plus personnelles).
func _pick(intent: String, ctx: Dictionary) -> Dictionary:
	var pool: Array = (data.get("repliques", {}) as Dictionary).get(intent, [])
	var ok: Array = []
	for i in range(pool.size()):
		var e: Dictionary = pool[i]
		if _ok(e.get("si", {}), ctx):
			ok.append(i)
	if ok.is_empty():
		return {}
	var said: Array = memoire["dites"]
	var fresh: Array = ok.filter(func(i): return not said.has(intent + ":" + str(i)))
	var candidates: Array = fresh if not fresh.is_empty() else ok
	var total: float = 0.0
	var weights: Array = []
	for i in candidates:
		var w: float = 1.0 + float((pool[i].get("si", {}) as Dictionary).size()) * 0.8
		# Une réplique qui fait avancer l'histoire (quête…) passe en priorité.
		if (pool[i] as Dictionary).has("action"):
			w *= 5.0
		weights.append(w)
		total += w
	var r: float = rng.randf() * total
	var chosen: int = candidates[0]
	for k in range(candidates.size()):
		r -= weights[k]
		if r <= 0.0:
			chosen = candidates[k]
			break
	said.append(intent + ":" + str(chosen))
	while said.size() > 14:
		said.pop_front()
	var entry: Dictionary = pool[chosen].duplicate()
	return entry


## Habille la réplique : petit mot d'humeur devant, tic de langage, intervention du compagnon.
func _dress(core: String, intent: String) -> String:
	var traits: Dictionary = data.get("traits", {})
	var parts: Array = []
	var prefixes: Dictionary = data.get("prefixes", {})
	# Le petit mot d'humeur ne va qu'aux sujets « neutres » (pas aux cadeaux, coups, adieux…).
	if intent in ["humeur", "lui", "ile", "rumeur", "blague", "souvenir", "reponse", "peche"] and rng.randf() < 0.35 and prefixes.has(humeur_famille()):
		var list: Array = prefixes[humeur_famille()]
		parts.append(str(list[rng.randi() % list.size()]))
	parts.append(core)
	var tics: Array = data.get("tics", [])
	if not tics.is_empty() and rng.randf() < float(traits.get("bavard", 0.5)) * 0.3 and humeur > -0.4:
		parts.append(str(tics[rng.randi() % tics.size()]))
	var text: String = " ".join(parts)
	var pet: Array = data.get("compagnon_lignes", [])
	if not pet.is_empty() and rng.randf() < 0.22:
		text += "\n\n" + str(pet[rng.randi() % pet.size()])
	return text


func say(intent: String, ctx: Dictionary, dress: bool = true) -> Dictionary:
	var e: Dictionary = _pick(intent, ctx)
	if e.is_empty():
		return {"texte": "…", "geste": ""}
	_mood(float(e.get("humeur", 0.0)))
	var text: String = _fill(str(e["t"]), ctx)
	if dress:
		text = _dress(text, intent)
	var out := {"texte": text, "geste": str(e.get("geste", "parle"))}
	for k in ["action", "donne", "pose"]:
		if e.has(k):
			out[k] = e[k]
	return out


# =================================================================== conversation

## Début de conversation : salut adapté, éventuellement une question au joueur.
func start(ctx: Dictionary) -> Dictionary:
	var now: float = float(ctx.get("now", 0.0))
	memoire["absence_ref"] = memoire["derniere"]
	memoire["visites"] = int(memoire["visites"]) + 1
	if float(memoire["premiere"]) < 0.0:
		memoire["premiere"] = now
		_remember("première rencontre", now)
	# Une visite fait plaisir, surtout après une longue absence (sauf s'il est fâché).
	if humeur > -0.3:
		_mood(0.05 + (0.08 if float(memoire["derniere"]) > 0.0 and now - float(memoire["derniere"]) > 1800.0 else 0.0))
	_bond(0.8)
	var reply: Dictionary = say("accueil", ctx, false)
	memoire["derniere"] = now
	var q: Dictionary = _next_question(ctx)
	if not q.is_empty() and rng.randf() < 0.75:
		_pending_question = q
		reply["texte"] = str(reply["texte"]) + "\n\n" + str(q["texte"])
		reply["choix"] = []
		for i in range(q["reponses"].size()):
			reply["choix"].append({"id": "rep:%d" % i, "label": str(q["reponses"][i]["label"])})
		return reply
	reply["choix"] = topics(ctx)
	return reply


func _next_question(ctx: Dictionary) -> Dictionary:
	for q in data.get("questions", []):
		if (memoire["faits"] as Dictionary).has(str(q["id"])):
			continue
		if _ok(q.get("si", {}), ctx):
			return q
	return {}


## Sujets proposés au joueur, selon ce que le personnage sait et ressent.
func topics(ctx: Dictionary) -> Array:
	var t: Array = [{"id": "humeur", "label": "Comment ça va ?"}]
	t.append({"id": "lui", "label": "Qui es-tu ?" if int((memoire["sujets"] as Dictionary).get("lui", 0)) == 0 else "Raconte-moi encore ta vie."})
	t.append({"id": "ile", "label": "Parle-moi de cette île."})
	t.append({"id": "rumeur", "label": "Tu as entendu des rumeurs ?"})
	if float((data.get("traits", {}) as Dictionary).get("humour", 0.0)) > 0.5:
		t.append({"id": "blague", "label": "Raconte-moi une blague."})
	# V32 : la pêche, si le personnage a quelque chose à en dire.
	if ((data.get("repliques", {}) as Dictionary).get("peche", []) as Array).size() > 0:
		t.append({"id": "peche", "label": "Tu sais pêcher ?" if int((memoire["sujets"] as Dictionary).get("peche", 0)) == 0 else "Parlons pêche."})
	# V33 : un marchand ouvre sa boutique.
	if data.has("boutique"):
		t.insert(1, {"id": "boutique", "label": "Montre-moi ta marchandise."})
	if str(memoire["quete"]) == "demandee":
		t.append({"id": "quete", "label": str((data.get("quete", {}) as Dictionary).get("sujet", "À propos de tes coquillages…"))})
	# V41 : sujets particuliers qui n'apparaissent que dans certaines circonstances.
	for sp in data.get("sujets_speciaux", []):
		if _ok((sp as Dictionary).get("si", {}), ctx):
			t.insert(mini(2, t.size()), {"id": str(sp["id"]), "label": str(sp["label"])})
	if int(memoire["visites"]) >= 3:
		t.append({"id": "souvenir", "label": "Tu te souviens de moi ?"})
	if not (ctx.get("objets", {}) as Dictionary).is_empty():
		t.append({"id": "cadeau", "label": "Je voudrais t'offrir quelque chose."})
	t.append({"id": "au_revoir", "label": "Au revoir."})
	return t


## Réponse à un choix du joueur. Renvoie {texte, geste, choix, fin?, donner?, prendre?}.
func choose(choice: String, ctx: Dictionary) -> Dictionary:
	var now: float = float(ctx.get("now", 0.0))
	if choice.begins_with("rep:") and not _pending_question.is_empty():
		var r: Dictionary = _pending_question["reponses"][int(choice.substr(4))]
		memoire["faits"][str(_pending_question["id"])] = str(r["valeur"])
		_mood(float(r.get("humeur", 0.0)))
		_bond(float(r.get("affinite", 0.0)))
		_remember("réponse « %s » : %s" % [_pending_question["id"], r["valeur"]], now)
		_pending_question = {}
		return {"texte": _dress(_fill(str(r["t"]), ctx), "reponse"), "geste": "parle", "choix": topics(ctx)}
	if choice.begins_with("don:"):
		return _gift(choice.substr(4), ctx)
	if choice.begins_with("achat:"):
		return _buy(choice.substr(6), ctx)
	if choice.begins_with("vente:"):
		return _sell(choice.substr(6), ctx)
	var sujets: Dictionary = memoire["sujets"]
	match choice:
		"cadeau":
			var list: Array = []
			for id in (ctx.get("objets", {}) as Dictionary):
				list.append({"id": "don:" + str(id), "label": "Offrir : " + str((ctx.get("noms", {}) as Dictionary).get(id, id))})
				if list.size() >= 6:
					break
			list.append({"id": "retour", "label": "Non, rien finalement."})
			return {"texte": "Oh ? Qu'as-tu donc pour moi ?", "geste": "parle", "choix": list}
		"retour":
			return {"texte": "Bon. Une autre fois, peut-être.", "geste": "parle", "choix": topics(ctx)}
		"quete":
			return _quest_turn_in(ctx)
		"boutique":
			return _shop_open(ctx)
		"marchander":
			return _haggle(ctx)
		"vendre_tout":
			return _sell_all(ctx)
		"souvenir":
			var out: Dictionary = say("souvenir", ctx)
			out["texte"] = str(out["texte"]) + "\n" + _memories_text(ctx)
			out["choix"] = topics(ctx)
			return out
		"au_revoir":
			var bye: Dictionary = say("au_revoir", ctx)
			bye["fin"] = true
			bye["choix"] = []
			memoire["derniere"] = now
			return bye
	sujets[choice] = int(sujets.get(choice, 0))
	var reply: Dictionary = say(choice, ctx)
	sujets[choice] = int(sujets[choice]) + 1
	# Parler à quelqu'un de ce qui l'intéresse le rapproche un peu ; le harceler sur le même sujet l'agace.
	if int(sujets[choice]) > 6:
		_mood(-0.04)
	else:
		_bond(0.6)
	if str(reply.get("action", "")) == "quete_demande" and str(memoire["quete"]) == "":
		memoire["quete"] = "demandee"
		_remember(str((data.get("quete", {}) as Dictionary).get("note", "m'a demandé des coquillages")), now)
		# V41 : le personnage peut confier un objet en lançant la quête (une fiole…).
		if reply.has("donne"):
			reply["donner"] = reply.get("donne", [])
	# V32 : « donne » — le personnage offre un objet. Avec "pose", une seule fois (le fait est retenu).
	if str(reply.get("action", "")) == "donne":
		var pose: String = str(reply.get("pose", ""))
		if pose == "" or not _has_fact(pose):
			if pose != "":
				memoire["faits"][pose] = true
			reply["donner"] = reply.get("donne", [])
			_remember("m'a confié " + _item_name(str((reply.get("donne", [[""]]) as Array)[0][0]), ctx), now)
	for k in ["action", "donne", "pose"]:
		reply.erase(k)
	reply["choix"] = topics(ctx)
	return reply


func _memories_text(ctx: Dictionary) -> String:
	var lines: Array = []
	var v: int = int(memoire["visites"])
	lines.append("Tu es venu me voir %d fois." % v)
	var faits: Dictionary = memoire["faits"]
	if faits.has("origine"):
		match str(faits["origine"]):
			"village": lines.append("Tu viens du village d'en face.")
			"aventurier": lines.append("Tu te dis aventurier. Je te crois. À moitié.")
			_: lines.append("Tu n'as jamais voulu me dire d'où tu viens. Je m'en souviens, ça.")
	if int(memoire["nb_cadeaux"]) > 0:
		lines.append("Tu m'as fait %d cadeau%s, le dernier : %s." % [memoire["nb_cadeaux"], "x" if int(memoire["nb_cadeaux"]) > 1 else "", _item_name(str(memoire["dernier_cadeau"]), ctx)])
	if faits.has("frappe"):
		var n_hits: int = int(faits["frappe"])
		lines.append("Et tu m'as frappé %s. Je n'oublie pas." % ("une fois" if n_hits == 1 else "%d fois" % n_hits))
	if faits.has("coquillage_prefere"):
		lines.append("Tu préfères les coquillages %s." % ("ronds" if faits["coquillage_prefere"] == "ronds" else ("pointus" if faits["coquillage_prefere"] == "pointus" else "… aucun, hélas")))
	if str(memoire["quete"]) == "finie":
		lines.append(str((data.get("quete", {}) as Dictionary).get("souvenir", "Et grâce à toi, ma collection est complète.")))
	if int(memoire.get("depense", 0)) > 0:
		var n_items: int = 0
		for k in memoire["achats"]:
			n_items += int(memoire["achats"][k])
		lines.append("Tu m'as acheté %d objet%s, pour %d pièces." % [n_items, "s" if n_items > 1 else "", int(memoire["depense"])])
	if int(memoire.get("ventes", 0)) > 0:
		lines.append("Et tu m'as vendu %d prise%s." % [int(memoire["ventes"]), "s" if int(memoire["ventes"]) > 1 else ""])
	if faits.has("canne"):
		var total: int = int((ctx.get("peche", {}) as Dictionary).get("total", 0))
		lines.append("Je t'ai confié ma vieille canne" + (" et tu as sorti %d prise%s de l'eau." % [total, "s" if total > 1 else ""] if total > 0 else ", et tu n'as encore rien attrapé avec."))
	return " ".join(lines)


func _gift(item: String, ctx: Dictionary) -> Dictionary:
	var now: float = float(ctx.get("now", 0.0))
	if (data.get("refuse", []) as Array).has(item):
		var specific: bool = (data.get("repliques", {}) as Dictionary).has("cadeau_refus_" + item)
		var r: Dictionary = say("cadeau_refus_" + item if specific else "cadeau_refus", ctx)
		r["choix"] = topics(ctx)
		return r
	memoire["dernier_cadeau"] = item
	memoire["nb_cadeaux"] = int(memoire["nb_cadeaux"]) + 1
	var c: Dictionary = memoire["cadeaux"]
	c[item] = int(c.get(item, 0)) + 1
	_remember("cadeau : " + item, now)
	var likes: Dictionary = data.get("aime", {})
	var hates: Dictionary = data.get("deteste", {})
	var intent: String = "cadeau_neutre"
	# Le même cadeau répété fait de moins en moins d'effet.
	var fatigue: float = 1.0 / (1.0 + 0.5 * (int(c[item]) - 1))
	if likes.has(item):
		intent = "cadeau_aime"
		_mood(0.12 * float(likes[item]) * fatigue)
		_bond(3.0 * float(likes[item]) * fatigue)
	elif hates.has(item):
		intent = "cadeau_deteste"
		_mood(0.15 * float(hates[item]))
		_bond(2.0 * float(hates[item]))
	else:
		_mood(0.03)
		_bond(0.5)
	var r2: Dictionary = say(intent, ctx)
	r2["prendre"] = [[item, 1]]
	r2["choix"] = topics(ctx)
	return r2


func _quest_turn_in(ctx: Dictionary) -> Dictionary:
	var q: Dictionary = data.get("quete", {})
	if str(memoire["quete"]) != "demandee":
		if ((data.get("repliques", {}) as Dictionary).get("quete_inconnue", []) as Array).size() > 0:
			var unk: Dictionary = say("quete_inconnue", ctx)
			unk["choix"] = topics(ctx)
			return unk
		return {"texte": "Mes coquillages ? Quels coquillages ? Ah… je ne t'ai encore rien demandé, il me semble.", "geste": "parle", "choix": topics(ctx)}
	if not _missing(ctx).is_empty():
		var r: Dictionary = say("quete_manque", ctx)
		r["choix"] = topics(ctx)
		return r
	memoire["quete"] = "finie"
	_bond(float(q.get("affinite", 10.0)))
	_remember(str(q.get("note_fin", "collection complétée")), float(ctx.get("now", 0.0)))
	var out: Dictionary = say("quete_fin", ctx)
	if q.has("objets"):
		var take: Array = []
		for id in q["objets"]:
			take.append([str(id), int(q["objets"][id])])
		out["prendre"] = take
	else:
		out["prendre"] = [[str(q["objet"]), int(q["nombre"])]]
	out["donner"] = q.get("recompense", [])
	out["choix"] = topics(ctx)
	return out


## Phrase lancée à distance quand le joueur approche.
func call_out(ctx: Dictionary) -> String:
	var e: Dictionary = _pick("interpelle", ctx)
	return _fill(str(e.get("t", "")), ctx) if not e.is_empty() else ""


## Le joueur l'a frappé : il s'en souvient longtemps (selon son caractère rancunier).
func hit(ctx: Dictionary) -> String:
	var rancune: float = float((data.get("traits", {}) as Dictionary).get("rancunier", 0.5))
	var faits: Dictionary = memoire["faits"]
	var r: Dictionary = say("frappe", ctx, false)
	faits["frappe"] = int(faits.get("frappe", 0)) + 1
	_mood(-0.6 - 0.4 * rancune, 0.2)
	humeur = minf(humeur, -0.35)
	_bond(-10.0 - 10.0 * rancune)
	_remember("m'a frappé", float(ctx.get("now", 0.0)))
	return str(r["texte"])


func serialize() -> Dictionary:
	return {"humeur": humeur, "energie": energie, "affinite": affinite, "memoire": memoire.duplicate(true)}


func load_data(d: Dictionary) -> void:
	reset()
	if d.is_empty():
		return
	humeur = float(d.get("humeur", humeur))
	energie = float(d.get("energie", energie))
	affinite = float(d.get("affinite", affinite))
	var m: Variant = d.get("memoire", {})
	if m is Dictionary:
		for k in m:
			memoire[k] = m[k]


# =================================================================== V33 : boutique
## Fiche : "boutique": {"vend": {objet: prix de base}, "achete": {objet: prix de base}}.
## Les prix suivent l'amitié (jusqu'à -30 %), l'humeur (+15 % s'il est contrarié) et le
## marchandage réussi pendant la visite (-15 %). Fâché pour de bon, il ferme boutique.

func prix(id: String) -> int:
	var base: float = float(((data.get("boutique", {}) as Dictionary).get("vend", {}) as Dictionary).get(id, 0))
	var f: float = 1.25 - clampf(affinite, 0.0, 100.0) / 100.0 * 0.4
	if humeur < -0.1:
		f += 0.15
	if int(memoire.get("remise", -1)) == int(memoire["visites"]):
		f *= 0.85
	return maxi(1, int(round(base * f)))


func prix_rachat(id: String) -> int:
	var base: float = float(((data.get("boutique", {}) as Dictionary).get("achete", {}) as Dictionary).get(id, 0))
	if base <= 0.0:
		return 0
	var f: float = 0.8 + clampf(affinite, 0.0, 100.0) / 100.0 * 0.4
	if humeur < -0.1:
		f -= 0.15
	return maxi(1, int(round(base * f)))


func _shop_closed() -> bool:
	return humeur_famille() == "colere"


## Choix de la boutique, calculés sur l'inventaire (après l'échange en cours, si besoin).
func _shop_choices(ctx: Dictionary) -> Array:
	var shop: Dictionary = data.get("boutique", {})
	var objets: Dictionary = ctx.get("objets", {})
	var place: Dictionary = ctx.get("place", {})
	var noms: Dictionary = ctx.get("noms", {})
	var list: Array = []
	for id in shop.get("vend", {}):
		var p: int = prix(str(id))
		var label: String = "Acheter : %s — %d pièce%s" % [str(noms.get(id, id)), p, "s" if p > 1 else ""]
		if int(place.get(id, 1)) <= 0 and int(objets.get(id, 0)) > 0:
			label += " (déjà à toi)"
		list.append({"id": "achat:" + str(id), "label": label})
	# Ce qu'il rachète, du plus cher au moins cher (quatre lignes au plus).
	var sells: Array = []
	for id in shop.get("achete", {}):
		if int(objets.get(id, 0)) > 0:
			sells.append(str(id))
	sells.sort_custom(func(a, b): return prix_rachat(a) > prix_rachat(b))
	for i in range(mini(sells.size(), 4)):
		var id2: String = sells[i]
		var p2: int = prix_rachat(id2)
		list.append({"id": "vente:" + id2, "label": "Vendre : %s ×%d — %d pièce%s l'unité" % [str(noms.get(id2, id2)), int(objets[id2]), p2, "s" if p2 > 1 else ""]})
	if sells.size() > 1:
		var total: int = 0
		for id3 in sells:
			total += prix_rachat(id3) * int(objets[id3])
		list.append({"id": "vendre_tout", "label": "Tout vendre — %d pièces" % total})
	if int(memoire.get("marchande", -1)) != int(memoire["visites"]):
		list.append({"id": "marchander", "label": "Tu ne me ferais pas un prix ?"})
	list.append({"id": "retour", "label": "Autre chose…"})
	return list


func _shop_reply(intent: String, ctx: Dictionary, after: Dictionary) -> Dictionary:
	var r: Dictionary = say(intent, ctx)
	r["choix"] = _shop_choices(after)
	return r


func _with_change(ctx: Dictionary, delta: Dictionary) -> Dictionary:
	var c: Dictionary = ctx.duplicate(true)
	var objets: Dictionary = c.get("objets", {})
	var place: Dictionary = c.get("place", {})
	for id in delta:
		objets[id] = int(objets.get(id, 0)) + int(delta[id])
		if int(objets[id]) <= 0:
			objets.erase(id)
		if place.has(id):
			place[id] = maxi(0, int(place[id]) - int(delta[id]))
	c["objets"] = objets
	c["place"] = place
	return c


func _shop_open(ctx: Dictionary) -> Dictionary:
	var sujets: Dictionary = memoire["sujets"]
	sujets["boutique"] = int(sujets.get("boutique", 0)) + 1
	if _shop_closed():
		var r: Dictionary = say("boutique_fermee", ctx)
		r["choix"] = topics(ctx)
		return r
	return _shop_reply("boutique", ctx, ctx)


func _buy(id: String, ctx: Dictionary) -> Dictionary:
	if _shop_closed():
		var r0: Dictionary = say("boutique_fermee", ctx)
		r0["choix"] = topics(ctx)
		return r0
	var p: int = prix(id)
	var c: Dictionary = ctx.duplicate(true)
	c["_objet"] = id
	c["_prix"] = p
	var have: int = int((ctx.get("objets", {}) as Dictionary).get("piece", 0))
	if int((ctx.get("place", {}) as Dictionary).get(id, 1)) <= 0:
		var intent: String = "achat_deja" if int((ctx.get("objets", {}) as Dictionary).get(id, 0)) > 0 else "achat_plein"
		return _shop_reply(intent, c, ctx)
	if have < p:
		return _shop_reply("achat_pauvre", c, ctx)
	var achats: Dictionary = memoire["achats"]
	achats[id] = int(achats.get(id, 0)) + 1
	memoire["depense"] = int(memoire.get("depense", 0)) + p
	_mood(0.08)
	_bond(2.0 + p * 0.05)
	_remember("m'a acheté " + _item_name(id, ctx), float(ctx.get("now", 0.0)))
	# Une réplique propre à l'objet (achat_<objet>) si la fiche en a une.
	var specific: String = "achat_" + id
	var intent2: String = specific if ((data.get("repliques", {}) as Dictionary).get(specific, []) as Array).size() > 0 else "achat"
	var out: Dictionary = _shop_reply(intent2, c, _with_change(ctx, {"piece": -p, id: 1}))
	out["prendre"] = [["piece", p]]
	out["donner"] = [[id, 1]]
	return out


func _sell(id: String, ctx: Dictionary) -> Dictionary:
	var have: int = int((ctx.get("objets", {}) as Dictionary).get(id, 0))
	var p: int = prix_rachat(id)
	if have <= 0 or p <= 0 or _shop_closed():
		return _shop_open(ctx)
	var c: Dictionary = ctx.duplicate(true)
	c["_objet"] = id
	c["_prix"] = p
	memoire["ventes"] = int(memoire.get("ventes", 0)) + 1
	memoire["gain"] = int(memoire.get("gain", 0)) + p
	_bond(0.6)
	var specific: String = "vente_" + id
	var intent: String = specific if ((data.get("repliques", {}) as Dictionary).get(specific, []) as Array).size() > 0 else "vente"
	var out: Dictionary = _shop_reply(intent, c, _with_change(ctx, {"piece": p, id: -1}))
	out["prendre"] = [[id, 1]]
	out["donner"] = [["piece", p]]
	return out


func _sell_all(ctx: Dictionary) -> Dictionary:
	if _shop_closed():
		return _shop_open(ctx)
	var objets: Dictionary = ctx.get("objets", {})
	var take: Array = []
	var total: int = 0
	var n: int = 0
	var delta := {}
	for id in (data.get("boutique", {}) as Dictionary).get("achete", {}):
		var k: int = int(objets.get(id, 0))
		if k > 0:
			take.append([str(id), k])
			total += prix_rachat(str(id)) * k
			n += k
			delta[id] = -k
	if n == 0:
		return _shop_open(ctx)
	delta["piece"] = total
	memoire["ventes"] = int(memoire.get("ventes", 0)) + n
	memoire["gain"] = int(memoire.get("gain", 0)) + total
	_bond(0.4 * n)
	var c: Dictionary = ctx.duplicate(true)
	c["_prix"] = total
	var out: Dictionary = _shop_reply("vente_lot", c, _with_change(ctx, delta))
	out["prendre"] = take
	out["donner"] = [["piece", total]]
	return out


## Marchander : une fois par visite. Les chances montent avec l'amitié et la bonne humeur,
## baissent s'il est radin ; un échec le vexe un peu.
func _haggle(ctx: Dictionary) -> Dictionary:
	if _shop_closed():
		return _shop_open(ctx)
	if int(memoire.get("marchande", -1)) == int(memoire["visites"]):
		return _shop_reply("marchande_deja", ctx, ctx)
	memoire["marchande"] = int(memoire["visites"])
	var radin: float = float((data.get("traits", {}) as Dictionary).get("radin", 0.5))
	var chance: float = clampf(0.3 + affinite / 120.0 + humeur * 0.25 - radin * 0.2, 0.05, 0.9)
	if rng.randf() < chance:
		memoire["remise"] = int(memoire["visites"])
		_mood(-0.03)
		return _shop_reply("marchande_oui", ctx, ctx)
	_mood(-0.1)
	return _shop_reply("marchande_non", ctx, ctx)
