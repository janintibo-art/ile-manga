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
## V65 : chacun a son HISTOIRE (des chapitres racontés au fil des visites, les derniers seulement
## à un ami), ses LIENS (les gens qu'il connaît, dont il raconte des anecdotes, et qu'il salue en
## les croisant), un rêve et une question pour le joueur. Les nouvelles circulent (societe_v65.gd) :
## les proches apprennent ce que le joueur a fait à quelqu'un, et chacun sait qui a parlé de lui.

var data: Dictionary
var rng := RandomNumberGenerator.new()
var humeur: float = 0.0
var energie: float = 0.5
var affinite: float = 0.0
var memoire: Dictionary = {}
var _pending_question: Dictionary = {}
const Societe = preload("res://scripts/pnj/societe_v65.gd")
## V65 : la fiche d'histoire de ce personnage (histoire, reve, question, liens).
var v65: Dictionary = {}
## V65 : il vouvoie le joueur (d'après sa façon de parler dans sa fiche) : les phrases du cerveau aussi.
var vous: bool = false
## V56 : réductions accordées au joueur (carnet de quêtes) : par groupe (« azur »), par
## personnage (son identifiant) et partout (« tout »).
static var remises: Dictionary = {}


func setup(profile: Dictionary) -> void:
	data = profile
	rng.randomize()
	v65 = Societe.fiche(str(profile.get("id", "")))
	vous = bool(profile.get("vouvoie", _v65_vouvoie(v65)))
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
		# V65 : chapitres racontés, anecdotes racontées (par personne), échos et nouvelles déjà
		# commentés, ce qu'il a appris du joueur par les autres, le dernier sujet de conversation.
		"chapitre": 0, "histoire_refus": -1, "racontes": {}, "echos": [], "ragots_vus": [], "appris": [],
		"dernier_sujet": "",
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
	while j.size() > 40:
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
			# V56 : l'heure du jeu et les quêtes du carnet
			"soir":
				var hs: float = float(ctx.get("heure", 12.0))
				if (hs >= 19.0 or hs < 5.0) != bool(v): return false
			"matin":
				var hm: float = float(ctx.get("heure", 12.0))
				if (hm >= 5.0 and hm < 12.0) != bool(v): return false
			"heure_min":
				if float(ctx.get("heure", 12.0)) < float(v): return false
			"heure_max":
				if float(ctx.get("heure", 12.0)) >= float(v): return false
			"q56":
				var kv: PackedStringArray = str(v).split("=")
				var cur: String = str((ctx.get("q56", {}) as Dictionary).get(kv[0], ""))
				var want: String = kv[1] if kv.size() > 1 else ""
				if want == "":
					if cur != "" and cur != "connue": return false
				elif cur != want:
					return false
			"rep_min":
				if int(ctx.get("rep", 0)) < int(v): return false
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
	# V65 : une nouvelle, un écho, un souvenir de la dernière fois.
	var hook: String = _v65_accroche(ctx)
	if hook != "":
		reply["texte"] = hook if str(reply["texte"]) == "…" else str(reply["texte"]) + "\n\n" + hook
	memoire["derniere"] = now
	var q: Dictionary = _next_question(ctx)
	var chance: float = 0.75
	if q.is_empty() and hook == "":
		q = _v65_question(ctx)
		chance = 0.5
		if q.is_empty():
			q = _v65_question_avis(ctx)
			chance = 0.35
	if not q.is_empty() and rng.randf() < chance:
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
	# V65 : son histoire, les gens qu'il connaît, son rêve.
	t.append_array(_v65_topics(ctx))
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
		if _pending_question.has("v65"):
			_v65_reponse(_pending_question, r, now)
		else:
			_remember("réponse « %s » : %s" % [_pending_question["id"], r["valeur"]], now)
		_pending_question = {}
		return {"texte": _dress(_fill(str(r["t"]), ctx), "reponse"), "geste": "parle", "choix": topics(ctx)}
	if choice.begins_with("don:"):
		return _gift(choice.substr(4), ctx)
	if choice.begins_with("cadeau_page:"):
		return _gift_page(int(choice.substr(12)), ctx)
	if choice.begins_with("achat:"):
		return _buy(choice.substr(6), ctx)
	if choice.begins_with("vente:"):
		return _sell(choice.substr(6), ctx)
	if choice.begins_with("gens:"):
		return _v65_gens(choice.substr(5), ctx)
	var sujets: Dictionary = memoire["sujets"]
	match choice:
		# V65 : son histoire, les gens qu'il connaît, son rêve
		"histoire":
			return _v65_histoire(ctx)
		"gens":
			return _v65_gens_menu(ctx, "")
		"reve":
			return _v65_reve(ctx)
		"autre":
			return {"texte": _pick_line(_tv(["Bien. De quoi d'autre veux-tu parler ?", "D'accord. Autre chose ?", "Bon. Je t'écoute."], ["Bien. De quoi d'autre voulez-vous parler ?", "D'accord. Autre chose ?", "Bon. Je vous écoute."])), "geste": "parle", "choix": topics(ctx)}
		"rumeur":
			# V65 : les nouvelles qui circulent (ce que le joueur a fait aux gens d'ici)
			if rng.randf() < 0.45:
				var news: String = _v65_ragot(ctx, true)
				if news != "":
					sujets["rumeur"] = int(sujets.get("rumeur", 0)) + 1
					return {"texte": news, "geste": "parle", "choix": topics(ctx)}
		"lui":
			# Toute son histoire racontée : de temps en temps, il en reprend un morceau.
			var hist: Array = v65.get("histoire", [])
			if not hist.is_empty() and int(memoire.get("chapitre", 0)) >= hist.size() and rng.randf() < 0.4:
				sujets["lui"] = int(sujets.get("lui", 0)) + 1
				var c: Dictionary = hist[rng.randi() % hist.size()]
				return {"texte": _tv("Tu veux l'entendre encore ? ", "Vous voulez l'entendre encore ? ") + _fill(str(c.get("t", "")), ctx), "geste": "parle", "choix": topics(ctx)}
		"cadeau":
			return _gift_page(0, ctx)
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
	lines.append(_tv("Tu es venu me voir %d fois.", "Vous êtes venu me voir %d fois.") % v)
	var faits: Dictionary = memoire["faits"]
	if faits.has("origine"):
		match str(faits["origine"]):
			"village": lines.append("Tu viens du village d'en face.")
			"aventurier": lines.append("Tu te dis aventurier. Je te crois. À moitié.")
			_: lines.append("Tu n'as jamais voulu me dire d'où tu viens. Je m'en souviens, ça.")
	if int(memoire["nb_cadeaux"]) > 0:
		lines.append(_tv("Tu m'as fait %d cadeau%s, le dernier : %s.", "Vous m'avez fait %d cadeau%s, le dernier : %s.") % [memoire["nb_cadeaux"], "x" if int(memoire["nb_cadeaux"]) > 1 else "", _item_name(str(memoire["dernier_cadeau"]), ctx)])
	if faits.has("frappe"):
		var n_hits: int = int(faits["frappe"])
		lines.append(_tv("Et tu m'as frappé %s. Je n'oublie pas.", "Et vous m'avez frappé %s. Je n'oublie pas.") % ("une fois" if n_hits == 1 else "%d fois" % n_hits))
	if faits.has("coquillage_prefere"):
		lines.append("Tu préfères les coquillages %s." % ("ronds" if faits["coquillage_prefere"] == "ronds" else ("pointus" if faits["coquillage_prefere"] == "pointus" else "… aucun, hélas")))
	if str(memoire["quete"]) == "finie":
		lines.append(str((data.get("quete", {}) as Dictionary).get("souvenir", "Et grâce à toi, ma collection est complète.")))
	if int(memoire.get("depense", 0)) > 0:
		var n_items: int = 0
		for k in memoire["achats"]:
			n_items += int(memoire["achats"][k])
		lines.append(_tv("Tu m'as acheté %d objet%s, pour %d pièces.", "Vous m'avez acheté %d objet%s, pour %d pièces.") % [n_items, "s" if n_items > 1 else "", int(memoire["depense"])])
	if int(memoire.get("ventes", 0)) > 0:
		lines.append(_tv("Et tu m'as vendu %d prise%s.", "Et vous m'avez vendu %d prise%s.") % [int(memoire["ventes"]), "s" if int(memoire["ventes"]) > 1 else ""])
	if faits.has("canne"):
		var total: int = int((ctx.get("peche", {}) as Dictionary).get("total", 0))
		lines.append("Je t'ai confié ma vieille canne" + (" et tu as sorti %d prise%s de l'eau." % [total, "s" if total > 1 else ""] if total > 0 else ", et tu n'as encore rien attrapé avec."))
	lines.append_array(_v65_souvenirs(ctx))
	return " ".join(lines)


## V72 : la liste des cadeaux, six par page (seulement ce qu'on peut offrir : pas les objets de
## quête, les outils, les armes, ni ce qu'on tient en main).
func _gift_page(page: int, ctx: Dictionary) -> Dictionary:
	var ids: Array = ctx.get("offrables", (ctx.get("objets", {}) as Dictionary).keys())
	var per: int = 6
	var n_pages: int = maxi(1, ceili(float(ids.size()) / per))
	page = clampi(page, 0, n_pages - 1)
	var list: Array = []
	for i in range(page * per, mini(ids.size(), (page + 1) * per)):
		var id: String = str(ids[i])
		list.append({"id": "don:" + id, "label": "Offrir : " + str((ctx.get("noms", {}) as Dictionary).get(id, id))})
	if page + 1 < n_pages:
		list.append({"id": "cadeau_page:%d" % (page + 1), "label": "D'autres choses… (%d/%d)" % [page + 2, n_pages]})
	list.append({"id": "retour", "label": "Non, rien finalement."})
	if ids.is_empty():
		return {"texte": "Oh ? Tu n'as rien que tu puisses offrir, on dirait. Ce n'est pas grave : ta visite me suffit.", "geste": "parle", "choix": [{"id": "retour", "label": "Une autre fois."}]}
	return {"texte": "Oh ? Qu'as-tu donc pour moi ?" if page == 0 else "Et quoi d'autre ?", "geste": "parle", "choix": list}


func _gift(item: String, ctx: Dictionary) -> Dictionary:
	var now: float = float(ctx.get("now", 0.0))
	# V72 : un objet qu'on ne peut pas offrir (objet de quête, outil…) n'est jamais pris
	if ctx.has("offrables") and not (ctx["offrables"] as Array).has(item):
		return {"texte": "Garde-le, voyons : on dirait que tu en as besoin.", "geste": "parle", "choix": topics(ctx)}
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
		Societe.noter("cadeau", _v65_id(), now, {"objet": item, "aime": true})
	elif hates.has(item):
		intent = "cadeau_deteste"
		_mood(0.15 * float(hates[item]))
		_bond(2.0 * float(hates[item]))
		Societe.noter("cadeau", _v65_id(), now, {"objet": item, "aime": false})
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
	Societe.noter("quete", _v65_id(), float(ctx.get("now", 0.0)))
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
	# V65 : s'il a appris quelque chose sur le joueur, il l'appelle pour lui en parler.
	var news: String = _v65_peek()
	if news != "" and rng.randf() < 0.6:
		return _fill(_pick_line(_tv(CALL65, CALL65_V)[news]), ctx)
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
	Societe.noter("frappe", _v65_id(), float(ctx.get("now", 0.0)))
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
	# V56 : réputation à Port-Azur, faveurs d'un commerçant, clé de la ville
	var off: float = float(remises.get(str(data.get("groupe", "")), 0.0)) + float(remises.get(str(data.get("id", "")), 0.0)) + float(remises.get("tout", 0.0))
	f *= 1.0 - clampf(off, 0.0, 0.5)
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


# =================================================================== V65 : histoire, liens, nouvelles
## Amitié nécessaire pour chaque chapitre (le dernier est une confidence).
const GATES65 := [0.0, 14.0, 22.0, 32.0, 45.0]
const GATES65_PASSANT := [0.0, 14.0, 26.0]

## Ce qu'on dit quand on apprend ce que le joueur a fait à quelqu'un. Bandes : pos (on aime cette
## personne), neg (on ne l'aime pas), neu (on la connaît à peine). {qn} : « ma voisine Rose ».
const RAGOTS65 := {
	"cadeau": {
		"pos": ["Il paraît que tu as offert {objet} à {qn}. {Il} m'en a parlé toute la journée. Merci pour {lui}.",
			"{Qn} m'a montré ce que tu lui as offert : {objet}. Tu sais faire plaisir, toi.",
			"Tu as gâté {qn}, à ce qu'on raconte. Ceux qui sont gentils avec les miens sont les bienvenus chez moi."],
		"neg": ["On m'a dit que tu avais offert {objet} à {qn}. Chacun ses fréquentations.",
			"{Qn} se pavane avec le cadeau que tu lui as fait. Je ne dis rien. Je n'en pense pas moins."],
		"neu": ["Tout le monde sait que tu as offert {objet} à {qn}. Ici, les nouvelles vont plus vite que le vent.",
			"Il paraît que tu fais des cadeaux à {qn}. C'est gentil, ça."],
	},
	"cadeau_rate": {
		"pos": ["Il paraît que tu as offert {objet} à {qn}… {Il} déteste ça ! Ne t'en fais pas, je lui ai dit que c'était l'intention qui comptait.",
			"{Qn} a reçu {objet} de ta part, à ce qu'on dit. Tu ne pouvais pas tomber plus mal ! La prochaine fois, demande-moi conseil."],
		"neg": ["Tu as offert {objet} à {qn} ? Tout le monde sait qu'{il} a ça en horreur. J'en ris encore.",
			"{Objet} pour {qn} ! Ha ! Je n'aurais pas fait mieux."],
		"neu": ["On raconte que tu as offert {objet} à {qn}. Pas de chance : c'est bien la seule chose qu'{il} ne supporte pas."],
	},
	"quete": {
		"pos": ["Tu as aidé {qn} ! {Il} me l'a raconté. Je ne l'oublierai pas, {surnom}.",
			"On dit que sans toi, {qn} y serait encore. Merci, du fond du cœur.",
			"{Qn} ne parle que de toi depuis que tu l'as aidé{e}. Tu as un ami de plus ici. Deux, même."],
		"neg": ["Alors comme ça, tu as rendu service à {qn}. Bon. Tu as bon cœur. Trop bon, peut-être.",
			"Il paraît que tu as aidé {qn}. {Il} aurait pu se débrouiller tout{e} seul{e}, mais bon."],
		"neu": ["J'ai entendu dire que tu avais aidé {qn}. C'est bien. On a besoin de gens comme toi.",
			"Tout le monde parle de ce que tu as fait pour {qn}."],
	},
	"frappe": {
		"pos": ["Tu as frappé {qn} ?! On m'a tout raconté. Tu as du culot de venir me parler.",
			"Je sais ce que tu as fait à {qn}. Je ne te le pardonnerai pas de sitôt.",
			"Alors c'est toi qui as levé la main sur {qn}… Ne recommence jamais. Jamais."],
		"neg": ["Il paraît que tu as frappé {qn}. Je ne devrais pas rire. J'ai ri quand même.",
			"Tu as frappé {qn}, à ce qu'on dit. Je ne dis pas que c'était mérité. Je ne dis pas le contraire."],
		"neu": ["On raconte que tu as frappé {qn}. Ici, on ne règle pas les choses comme ça.",
			"Tu as frappé {qn} ? Ça ne se fait pas. Tout le monde en parle."],
	},
	"confidence": {
		"pos": ["{Qn} t'a raconté toute sa vie ? Alors {il} t'a à la bonne. Ça ne m'étonne pas.",
			"Il paraît que {qn} t'a tout confié. {Il} ne fait pas ça avec n'importe qui, tu sais."],
		"neg": ["{Qn} t'a raconté sa vie, à ce qu'on dit. Tu as eu de la patience."],
		"neu": ["Il paraît que {qn} t'a raconté toute sa vie. Tu dois savoir écouter, toi."],
	},
}

## Quelqu'un a parlé de moi au joueur ({qn}/{il} : celui qui a parlé).
const ECHOS65 := {
	"pos": ["{Qn} t'a parlé de moi ? {Il} ne peut pas s'en empêcher.",
		"Alors {qn} t'a raconté mes histoires ? J'espère qu'{il} n'a pas tout dit.",
		"Il paraît que {qn} t'a parlé de moi. Tout en bien, j'espère."],
	"neg": ["Il paraît que {qn} t'a parlé de moi. Ne crois pas tout ce qu'{il} raconte.",
		"{Qn} t'a raconté des choses sur moi ? Évidemment."],
	"inconnu": ["Il paraît que {qn} t'a parlé de moi. Je ne savais pas qu'{il} me connaissait si bien.",
		"On m'a dit que {qn} t'avait parlé de moi. Le monde est petit."],
}

## Le joueur a donné son avis sur moi à quelqu'un ({qn} : celui qui me l'a répété).
const AVIS_ECHO65 := {
	"sympa": ["Il paraît que tu me trouves sympathique ? C'est {qn} qui me l'a dit. Ça me fait plaisir, tiens.",
		"{Qn} m'a répété ce que tu penses de moi. Du bien ! J'en suis tout{me} retourné{me}."],
	"bizarre": ["Alors comme ça, tu me trouves bizarre ? {Qn} me l'a répété. Bizarre toi-même.",
		"Il paraît que je suis « un peu bizarre », d'après toi. C'est {qn} qui me l'a dit. Je vais y réfléchir. Ou pas."],
}

## Il appelle le joueur qui passe : quelqu'un lui a parlé de lui, ou il a appris une nouvelle.
const CALL65 := {
	"echo": ["Hé, toi ! Il paraît qu'on t'a parlé de moi…", "Ah, te voilà ! Viens par ici, on m'a raconté des choses."],
	"nouvelle": ["Psst ! Approche, j'ai appris quelque chose sur toi.", "Hé ! Tout le monde parle de toi, tu sais ?"],
	"colere": ["Toi ! Ne crois pas que je ne sais pas ce que tu as fait.", "Tiens, tiens… Viens donc m'expliquer, toi."],
	"avis": ["Hé, toi ! Il paraît que tu as un avis sur moi ?"],
}

## Les mêmes phrases pour ceux qui vouvoient le joueur.
const RAGOTS65_V := {
	"cadeau": {
		"pos": ["Il paraît que vous avez offert {objet} à {qn}. {Il} m'en a parlé toute la journée. Merci pour {lui}.",
			"{Qn} m'a montré ce que vous lui avez offert : {objet}. Vous savez faire plaisir, vous.",
			"Vous avez gâté {qn}, à ce qu'on raconte. Ceux qui sont gentils avec les miens sont les bienvenus chez moi."],
		"neg": ["On m'a dit que vous aviez offert {objet} à {qn}. Chacun ses fréquentations.",
			"{Qn} se pavane avec le cadeau que vous lui avez fait. Je ne dis rien. Je n'en pense pas moins."],
		"neu": ["Tout le monde sait que vous avez offert {objet} à {qn}. Ici, les nouvelles vont plus vite que le vent.",
			"Il paraît que vous faites des cadeaux à {qn}. C'est gentil, ça."],
	},
	"cadeau_rate": {
		"pos": ["Il paraît que vous avez offert {objet} à {qn}… {Il} déteste ça ! Ne vous en faites pas, je lui ai dit que c'était l'intention qui comptait.",
			"{Qn} a reçu {objet} de votre part, à ce qu'on dit. Vous ne pouviez pas tomber plus mal ! La prochaine fois, demandez-moi conseil."],
		"neg": ["Vous avez offert {objet} à {qn} ? Tout le monde sait qu'{il} a ça en horreur. J'en ris encore.",
			"{Objet} pour {qn} ! Ha ! Je n'aurais pas fait mieux."],
		"neu": ["On raconte que vous avez offert {objet} à {qn}. Pas de chance : c'est bien la seule chose qu'{il} ne supporte pas."],
	},
	"quete": {
		"pos": ["Vous avez aidé {qn} ! {Il} me l'a raconté. Je ne l'oublierai pas, {surnom}.",
			"On dit que sans vous, {qn} y serait encore. Merci, du fond du cœur.",
			"{Qn} ne parle que de vous depuis que vous l'avez aidé{e}. Vous avez un ami de plus ici. Deux, même."],
		"neg": ["Alors comme ça, vous avez rendu service à {qn}. Bon. Vous avez bon cœur. Trop bon, peut-être.",
			"Il paraît que vous avez aidé {qn}. {Il} aurait pu se débrouiller tout{e} seul{e}, mais bon."],
		"neu": ["J'ai entendu dire que vous aviez aidé {qn}. C'est bien. On a besoin de gens comme vous.",
			"Tout le monde parle de ce que vous avez fait pour {qn}."],
	},
	"frappe": {
		"pos": ["Vous avez frappé {qn} ?! On m'a tout raconté. Vous avez du culot de venir me parler.",
			"Je sais ce que vous avez fait à {qn}. Je ne vous le pardonnerai pas de sitôt.",
			"Alors c'est vous qui avez levé la main sur {qn}… Ne recommencez jamais. Jamais."],
		"neg": ["Il paraît que vous avez frappé {qn}. Je ne devrais pas rire. J'ai ri quand même.",
			"Vous avez frappé {qn}, à ce qu'on dit. Je ne dis pas que c'était mérité. Je ne dis pas le contraire."],
		"neu": ["On raconte que vous avez frappé {qn}. Ici, on ne règle pas les choses comme ça.",
			"Vous avez frappé {qn} ? Ça ne se fait pas. Tout le monde en parle."],
	},
	"confidence": {
		"pos": ["{Qn} vous a raconté toute sa vie ? Alors {il} vous a à la bonne. Ça ne m'étonne pas.",
			"Il paraît que {qn} vous a tout confié. {Il} ne fait pas ça avec n'importe qui, vous savez."],
		"neg": ["{Qn} vous a raconté sa vie, à ce qu'on dit. Vous avez eu de la patience."],
		"neu": ["Il paraît que {qn} vous a raconté toute sa vie. Vous devez savoir écouter, vous."],
	},
}

const ECHOS65_V := {
	"pos": ["{Qn} vous a parlé de moi ? {Il} ne peut pas s'en empêcher.",
		"Alors {qn} vous a raconté mes histoires ? J'espère qu'{il} n'a pas tout dit.",
		"Il paraît que {qn} vous a parlé de moi. Tout en bien, j'espère."],
	"neg": ["Il paraît que {qn} vous a parlé de moi. Ne croyez pas tout ce qu'{il} raconte.",
		"{Qn} vous a raconté des choses sur moi ? Évidemment."],
	"inconnu": ["Il paraît que {qn} vous a parlé de moi. Je ne savais pas qu'{il} me connaissait si bien.",
		"On m'a dit que {qn} vous avait parlé de moi. Le monde est petit."],
}

const AVIS_ECHO65_V := {
	"sympa": ["Il paraît que vous me trouvez sympathique ? C'est {qn} qui me l'a dit. Ça me fait plaisir, tiens.",
		"{Qn} m'a répété ce que vous pensez de moi. Du bien ! J'en suis tout{me} retourné{me}."],
	"bizarre": ["Alors comme ça, vous me trouvez bizarre ? {Qn} me l'a répété. Bizarre vous-même.",
		"Il paraît que je suis « un peu bizarre », d'après vous. C'est {qn} qui me l'a dit. Je vais y réfléchir. Ou pas."],
}

const CALL65_V := {
	"echo": ["Hé, vous ! Il paraît qu'on vous a parlé de moi…", "Ah, vous voilà ! Venez par ici, on m'a raconté des choses."],
	"nouvelle": ["Psst ! Approchez, j'ai appris quelque chose sur vous.", "Hé ! Tout le monde parle de vous, vous savez ?"],
	"colere": ["Vous ! Ne croyez pas que je ne sais pas ce que vous avez fait.", "Tiens, tiens… Venez donc m'expliquer, vous."],
	"avis": ["Hé, vous ! Il paraît que vous avez un avis sur moi ?"],
}

const Q_AVIS65_V := ["Dites-moi, vous avez rencontré {qn}. Comment {le} trouvez-vous ?",
	"Au fait, vous connaissez {qn}, maintenant. Alors, votre avis ?",
	"Vous avez fait la connaissance de {qn}, il paraît. Qu'en pensez-vous ?"]

const R_AVIS65_V := {
	"sympa_pos": ["N'est-ce pas ? {Il} est comme ça, {nom}. Je le lui dirai, ça lui fera plaisir.", "Je le savais ! Vous avez bon goût."],
	"sympa_neg": ["Sympathique ? Vous ne {le} connaissez pas encore.", "Hmm. Vous êtes bien indulgent. Attendez un peu, vous verrez."],
	"sympa_neu": ["Ah ? Je le lui dirai, ça lui fera plaisir.", "Tant mieux. Ici, on aime les gens qui s'entendent bien."],
	"bizarre_pos": ["Bizarre ? Hé ! Je vous interdis. … Bon. Un peu, peut-être. Mais c'est ce qui fait son charme.", "Bizarre, {nom} ? Vous ne {le} connaissez pas comme moi."],
	"bizarre_neg": ["Ha ! Enfin quelqu'un qui le voit ! Je commençais à me poser des questions.", "Bizarre, oui. C'est le mot. Je n'aurais pas dit mieux."],
	"bizarre_neu": ["Bizarre… oui, peut-être. Mais qui ne l'est pas, ici ?", "Ah ? Je n'avais pas remarqué. Je regarderai mieux."],
	"nsp": ["Prenez votre temps. Les gens d'ici, il faut les apprivoiser.", "Vous avez raison de ne pas juger trop vite."],
}

const Q_AVIS65 := ["Dis-moi, tu as rencontré {qn}. Comment tu {le} trouves ?",
	"Au fait, tu connais {qn}, maintenant. Alors, ton avis ?",
	"Tu as fait la connaissance de {qn}, il paraît. Qu'est-ce que tu en penses ?"]

const R_AVIS65 := {
	"sympa_pos": ["N'est-ce pas ? {Il} est comme ça, {nom}. Je le lui dirai, ça lui fera plaisir.", "Je le savais ! Tu as bon goût, toi."],
	"sympa_neg": ["Sympathique ? Toi, tu ne {le} connais pas encore.", "Hmm. Tu es bien indulgent. Attends un peu, tu verras."],
	"sympa_neu": ["Ah ? Je le lui dirai, ça lui fera plaisir.", "Tant mieux. Ici, on aime les gens qui s'entendent bien."],
	"bizarre_pos": ["Bizarre ? Hé ! Je t'interdis. … Bon. Un peu, peut-être. Mais c'est ce qui fait son charme.", "Bizarre, {nom} ? Tu ne {le} connais pas comme moi."],
	"bizarre_neg": ["Ha ! Enfin quelqu'un qui le voit ! Je commençais à me poser des questions.", "Bizarre, oui. C'est le mot. Je n'aurais pas dit mieux."],
	"bizarre_neu": ["Bizarre… oui, peut-être. Mais qui ne l'est pas, ici ?", "Ah ? Je n'avais pas remarqué. Je regarderai mieux."],
	"nsp": ["Prends ton temps. Les gens d'ici, il faut les apprivoiser.", "Tu as raison de ne pas juger trop vite."],
}


## Vouvoie-t-il le joueur ? (sa fiche emploie « vous » plutôt que « tu »)
static func _v65_vouvoie(f: Dictionary) -> bool:
	if f.is_empty():
		return false
	var parts: Array = []
	for c in f.get("histoire", []):
		parts.append(str(c.get("t", "")))
	for r in f.get("reve", []):
		parts.append(str(r))
	var q: Dictionary = f.get("question", {})
	parts.append(str(q.get("texte", "")))
	for r2 in q.get("reponses", []):
		parts.append(str(r2.get("t", "")) + " " + str(r2.get("rappel", "")))
	var t: String = " ".join(parts).to_lower()
	var re := RegEx.new()
	re.compile("\\b(vous|votre|vos)\\b")
	var nv: int = re.search_all(t).size()
	re.compile("\\b(tu|toi|ton|tes)\\b")
	var nt: int = re.search_all(t).size()
	return nv > nt and nv >= 2


## « tu » ou « vous » selon le personnage.
func _tv(tu: Variant, vs: Variant) -> Variant:
	return vs if vous else tu


func _v65_id() -> String:
	return str(data.get("id", ""))


func _v65_liens() -> Dictionary:
	return v65.get("liens", {})


func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1) if s != "" else s


## « de Rose », « d'Odette ».
static func _de(name: String) -> String:
	var c: String = name.substr(0, 1).to_lower()
	return ("d'" if "aeiouyhéèêàâîïôû".contains(c) and c != "" else "de ") + name


## « Fernand, Rose et Lucas ».
static func _liste(names: Array) -> String:
	if names.size() <= 1:
		return "" if names.is_empty() else str(names[0])
	return ", ".join(names.slice(0, names.size() - 1)) + " et " + str(names[-1])


## Contractions et élisions après remplacement des noms (« à le » → « au », « de Odette » → « d'Odette »).
static func _fr(t: String) -> String:
	for pair in [[" à le ", " au "], [" à les ", " aux "], [" de le ", " du "], [" de les ", " des "], ["À le ", "Au "]]:
		t = t.replace(pair[0], pair[1])
	var re := RegEx.new()
	re.compile("\\b(d|D|qu|Qu)e ([AEIOUYÉÈÊÀÂÎÏÔÛHaeiouyéèêàâîïôûh])")
	return re.sub(t, "$1'$2", true)


func _pick_line(list: Array) -> String:
	return str(list[rng.randi() % list.size()]) if not list.is_empty() else ""


## Remplit un modèle de phrase sur « qui » : {qn} (comment je le désigne), {nom}, {il}, {e}…
func _v65_tpl(t: String, qui: String, ctx: Dictionary, extra: Dictionary = {}) -> String:
	var me: String = _v65_id()
	var qn: String = Societe.designe(me, qui)
	var fem: bool = Societe.feminin(qui)
	var vars := {"{Qn}": _cap(qn), "{qn}": qn, "{nom}": Societe.nom_pour(me, qui),
		"{Il}": "Elle" if fem else "Il", "{il}": "elle" if fem else "il", "{e}": "e" if fem else "",
		"{le}": "la" if fem else "le", "{lui}": "elle" if fem else "lui", "{me}": "e" if str(v65.get("genre", "m")) == "f" else ""}
	if extra.has("objet"):
		var o: String = _item_name(str(extra["objet"]), ctx)
		vars["{Objet}"] = _cap(o)
		vars["{objet}"] = o
	for k in vars:
		t = t.replace(k, str(vars[k]))
	return _fr(_fill(t, ctx))


## Sujets V65 proposés au joueur.
func _v65_topics(_ctx: Dictionary) -> Array:
	var t: Array = []
	var hist: Array = v65.get("histoire", [])
	var ch: int = int(memoire.get("chapitre", 0))
	if not hist.is_empty() and ch < hist.size() and int(memoire.get("histoire_refus", -1)) != int(memoire["visites"]):
		t.append({"id": "histoire", "label": "Raconte-moi ton histoire." if ch == 0 else "Et ensuite ? Raconte-moi la suite."})
	if not _v65_liens().is_empty():
		t.append({"id": "gens", "label": "Parle-moi des gens que tu connais."})
	if ch >= 2 and not (v65.get("reve", []) as Array).is_empty() and not (memoire["faits"] as Dictionary).has("reve65"):
		t.append({"id": "reve", "label": "Et toi, de quoi tu rêves ?"})
	return t


func _v65_gate(i: int) -> float:
	var hist: Array = v65.get("histoire", [])
	var g: Array = GATES65_PASSANT if hist.size() <= 3 else GATES65
	return float(g[clampi(i, 0, g.size() - 1)])


## Le chapitre suivant de son histoire — s'il est assez ami avec le joueur pour le raconter.
func _v65_histoire(ctx: Dictionary) -> Dictionary:
	var now: float = float(ctx.get("now", 0.0))
	var hist: Array = v65.get("histoire", [])
	var ch: int = int(memoire.get("chapitre", 0))
	if hist.is_empty():
		return {"texte": "Mon histoire ? Il n'y a pas grand-chose à raconter.", "geste": "parle", "choix": topics(ctx)}
	if ch >= hist.size():
		var again: Dictionary = hist[rng.randi() % hist.size()]
		return {"texte": _fill(_tv("Je t'ai déjà tout raconté, {surnom}. Mais bon, puisque tu insistes : ", "Je vous ai déjà tout raconté, {surnom}. Mais bon, puisque vous insistez : ") + str(again.get("t", "")), ctx), "geste": "parle", "choix": topics(ctx)}
	if affinite < _v65_gate(ch):
		memoire["histoire_refus"] = int(memoire["visites"])
		_remember("je ne lui ai pas encore tout raconté", now)
		var refus: Array = _tv(["La suite… on ne se connaît pas encore assez, {surnom}. Reviens me voir.",
			"Ça, je te le raconterai une autre fois. Quand on sera plus amis.",
			"Hmm. La suite, il faut la mériter. Repasse me voir, on verra.",
			"Pas aujourd'hui. Il y a des choses qu'on ne raconte pas au premier venu."],
			["La suite… on ne se connaît pas encore assez, {surnom}. Revenez me voir.",
			"Ça, je vous le raconterai une autre fois. Quand on se connaîtra mieux.",
			"Hmm. La suite, il faut la mériter. Repassez me voir, on verra.",
			"Pas aujourd'hui. Il y a des choses qu'on ne raconte pas au premier venu."])
		if ch == hist.size() - 1 and hist.size() > 3:
			refus = ["Le reste, c'est un secret. Je ne le confie qu'à un ami. Un vrai, {surnom}.",
				_tv("Il reste une chose que je n'ai jamais dite à personne. Un jour, peut-être. Quand j'aurai confiance en toi.",
				"Il reste une chose que je n'ai jamais dite à personne. Un jour, peut-être. Quand j'aurai confiance en vous.")]
		return {"texte": _fill(_pick_line(refus), ctx), "geste": "parle", "choix": topics(ctx)}
	var c: Dictionary = hist[ch]
	var text: String = _fill(str(c.get("t", "")), ctx)
	if ch > 0 and ch < hist.size() - 1 and rng.randf() < 0.4:
		text = _pick_line(["Où en étais-je ? Ah oui.", _tv("La suite ? Bon, écoute.", "La suite ? Bon, écoutez."), "Je reprends.", "Alors, la suite…"]) + " " + text
	memoire["chapitre"] = ch + 1
	memoire["dernier_sujet"] = "histoire:%d" % ch
	var sujets: Dictionary = memoire["sujets"]
	sujets["histoire"] = int(sujets.get("histoire", 0)) + 1
	_bond(1.5)
	_mood(0.03)
	_remember("je lui ai raconté " + str(c.get("titre", "un bout de ma vie")), now)
	if ch + 1 == hist.size():
		Societe.noter("confidence", _v65_id(), now)
	return {"texte": text, "geste": "parle", "choix": topics(ctx)}


## La liste des gens qu'il connaît (ceux que le joueur a déjà rencontrés d'abord).
func _v65_gens_menu(ctx: Dictionary, lead: String) -> Dictionary:
	var liens: Dictionary = _v65_liens()
	var rencontres: Dictionary = ctx.get("rencontres", {})
	var met: Array = []
	var other: Array = []
	for id in liens:
		if int(rencontres.get(str(id), 0)) > 0:
			met.append(str(id))
		else:
			other.append(str(id))
	var list: Array = []
	for id2 in met + other:
		var l: Dictionary = liens[id2]
		var nm: String = str(l.get("nom", Societe.prenom(id2)))
		var told: int = int((memoire["racontes"] as Dictionary).get(id2, 0))
		list.append({"id": "gens:" + id2, "label": ("Parle-moi %s." if told == 0 else "Parle-moi encore %s.") % _de(nm)})
	list.append({"id": "autre", "label": "Autre chose…"})
	var text: String = lead if lead != "" else _pick_line(_tv(["Les gens d'ici ? J'en connais quelques-uns. Lequel t'intéresse ?",
		"Tu veux que je te parle de qui ?", "Ah, les gens… Demande, je te dirai ce que je sais."],
		["Les gens d'ici ? J'en connais quelques-uns. Lequel vous intéresse ?",
		"Vous voulez que je vous parle de qui ?", "Ah, les gens… Demandez, je vous dirai ce que je sais."]))
	return {"texte": text, "geste": "parle", "choix": list}


## Ce qu'il pense de quelqu'un, puis ses anecdotes sur lui, une par fois.
func _v65_gens(id: String, ctx: Dictionary) -> Dictionary:
	var now: float = float(ctx.get("now", 0.0))
	var l: Dictionary = _v65_liens().get(id, {})
	if l.is_empty():
		return _v65_gens_menu(ctx, "")
	var rac: Dictionary = memoire["racontes"]
	var n: int = int(rac.get(id, 0))
	var anec: Array = l.get("anecdotes", [])
	var nm: String = str(l.get("nom", Societe.prenom(id)))
	var text: String
	if n == 0:
		text = str(l.get("avis", ""))
		if not anec.is_empty():
			text += "\n\n" + str(anec[0])
		_bond(0.8)
		_remember("je lui ai parlé " + _de(nm), now)
	elif n < anec.size():
		text = str(anec[n])
		if rng.randf() < 0.4:
			text = _pick_line([_tv("Une autre histoire sur %s ? Écoute ça.", "Une autre histoire sur %s ? Écoutez ça.") % nm, _tv("Ah, %s… Tiens, encore une :", "Ah, %s… Tenez, encore une :") % nm, "Encore %s ? D'accord." % nm]) + " " + text
	else:
		text = _tv("Je t'ai raconté tout ce que je sais sur %s. %s", "Je vous ai raconté tout ce que je sais sur %s. %s") % [nm, str(l.get("avis", ""))]
	rac[id] = n + 1
	Societe.dire(_v65_id(), id)
	memoire["dernier_sujet"] = "gens:" + id
	var sujets: Dictionary = memoire["sujets"]
	sujets["gens"] = int(sujets.get("gens", 0)) + 1
	var out: Dictionary = _v65_gens_menu(ctx, "")
	out["texte"] = _fill(text, ctx)
	out["geste"] = "rire" if float(l.get("sentiment", 0.0)) > 0.5 and rng.randf() < 0.25 else "parle"
	return out


func _v65_reve(ctx: Dictionary) -> Dictionary:
	var rv: Array = v65.get("reve", [])
	var faits: Dictionary = memoire["faits"]
	if rv.is_empty():
		return {"texte": "Mon rêve ? Je n'y ai jamais vraiment pensé.", "geste": "parle", "choix": topics(ctx)}
	faits["reve65"] = true
	memoire["dernier_sujet"] = "reve"
	_bond(0.8)
	_remember("je lui ai confié mon rêve", float(ctx.get("now", 0.0)))
	var parts: Array = []
	for s in rv:
		parts.append(_fill(str(s), ctx))
	return {"texte": " ".join(parts), "geste": "parle", "choix": topics(ctx)}


## La question de sa fiche (à partir de la deuxième visite, une seule fois).
func _v65_question(ctx: Dictionary) -> Dictionary:
	var q: Dictionary = v65.get("question", {})
	if q.is_empty() or (memoire["faits"] as Dictionary).has("q65") or int(memoire["visites"]) < 2:
		return {}
	var reps: Array = []
	for r in q.get("reponses", []):
		reps.append({"label": str(r.get("label", "")), "valeur": str(r.get("valeur", "")), "t": str(r.get("t", "")), "humeur": 0.04, "affinite": 1.5})
	if reps.is_empty():
		return {}
	return {"id": "q65", "texte": _fill(str(q.get("texte", "")), ctx), "reponses": reps, "v65": "question"}


## « Tu as rencontré ma sœur. Comment tu la trouves ? » — sur quelqu'un qu'il connaît et que le
## joueur a déjà rencontré. La réponse fera le tour : la personne concernée le saura.
func _v65_question_avis(ctx: Dictionary) -> Dictionary:
	if int(memoire["visites"]) < 3:
		return {}
	var rencontres: Dictionary = ctx.get("rencontres", {})
	var faits: Dictionary = memoire["faits"]
	var cands: Array = []
	for id in _v65_liens():
		if int(rencontres.get(str(id), 0)) > 0 and not faits.has("avis_" + str(id)):
			cands.append(str(id))
	if cands.is_empty():
		return {}
	var x: String = cands[rng.randi() % cands.size()]
	var s: float = Societe.sentiment(_v65_id(), x)
	var band: String = "pos" if s > 0.25 else ("neg" if s < -0.25 else "neu")
	var R: Dictionary = _tv(R_AVIS65, R_AVIS65_V)
	var reps: Array = [
		{"label": "Très sympathique.", "valeur": "sympa", "t": _v65_tpl(_pick_line(R["sympa_" + band]), x, ctx),
			"humeur": 0.08 if band == "pos" else 0.0, "affinite": 2.0 if band == "pos" else (-0.5 if band == "neg" else 0.5)},
		{"label": "Un peu bizarre.", "valeur": "bizarre", "t": _v65_tpl(_pick_line(R["bizarre_" + band]), x, ctx),
			"humeur": -0.06 if band == "pos" else 0.04, "affinite": -1.0 if band == "pos" else (2.0 if band == "neg" else 0.0)},
		{"label": "Je ne sais pas encore.", "valeur": "nsp", "t": _v65_tpl(_pick_line(R["nsp"]), x, ctx), "humeur": 0.0, "affinite": 0.3},
	]
	return {"id": "avis_" + x, "texte": _v65_tpl(_pick_line(_tv(Q_AVIS65, Q_AVIS65_V)), x, ctx), "reponses": reps, "v65": "avis", "sujet": x}


func _v65_reponse(q: Dictionary, r: Dictionary, now: float) -> void:
	if str(q.get("v65", "")) == "avis":
		var x: String = str(q.get("sujet", ""))
		_remember("son avis sur %s : %s" % [Societe.nom_pour(_v65_id(), x), str(r.get("label", "")).to_lower()], now)
		if str(r.get("valeur", "")) != "nsp":
			Societe.noter("avis", x, now, {"de": _v65_id(), "valeur": str(r.get("valeur", ""))})
	else:
		_remember("sa réponse à ma question : " + str(r.get("label", "")), now)


## Ajoutée au salut : quelqu'un a parlé de moi au joueur, une nouvelle sur un proche, ou un
## souvenir de la dernière fois.
func _v65_accroche(ctx: Dictionary) -> String:
	if v65.is_empty():
		return ""
	var me: String = _v65_id()
	var heard: Dictionary = Societe.entendu.get(me, {})
	var echos: Array = memoire["echos"]
	for a in heard:
		if str(a) != me and not echos.has(str(a)):
			echos.append(str(a))
			if rng.randf() < 0.85:
				return _v65_echo(str(a), ctx)
	var line: String = _v65_ragot(ctx, false)
	if line != "":
		return line
	if int(memoire["visites"]) >= 2 and rng.randf() < 0.35:
		return _v65_rappel(ctx)
	return ""


## Ce qu'il a à dire au joueur, sans rien consommer : « echo », « avis », « colere », « nouvelle » ou "".
func _v65_peek() -> String:
	if v65.is_empty():
		return ""
	var me: String = _v65_id()
	var echos: Array = memoire["echos"]
	for a in Societe.entendu.get(me, {}):
		if str(a) != me and not echos.has(str(a)):
			return "echo"
	var vus: Array = memoire["ragots_vus"]
	var evs: Array = Societe.evenements
	for i in range(evs.size() - 1, maxi(-1, evs.size() - 25), -1):
		var e: Dictionary = evs[i]
		if vus.has(int(e.get("n", 0))) or vus.has(float(int(e.get("n", 0)))):
			continue
		var qui: String = str(e.get("qui", ""))
		if str(e.get("quoi", "")) == "avis":
			if qui == me and str(e.get("de", "")) != me:
				return "avis"
			continue
		if qui == me or not _v65_liens().has(qui):
			continue
		if str(e.get("quoi", "")) == "frappe" and Societe.sentiment(me, qui) > 0.25:
			return "colere"
		return "nouvelle"
	return ""


## Retire « Fernand ? » au début d'un avis (quand on vient de nommer la personne).
func _v65_avis_court(l: Dictionary) -> String:
	var av: String = str(l.get("avis", ""))
	var words: PackedStringArray = str(l.get("nom", "")).split(" ", false)
	var i: int = av.find("?")
	if i > 0 and i < 45 and not words.is_empty() and av.substr(0, i).to_lower().contains(words[-1].to_lower()):
		return av.substr(i + 1).strip_edges()
	return av


func _v65_echo(a: String, ctx: Dictionary) -> String:
	var l: Dictionary = _v65_liens().get(a, {})
	_bond(0.5)
	_remember(Societe.prenom(a) + " lui a parlé de moi", float(ctx.get("now", 0.0)))
	if l.is_empty():
		return _v65_tpl(_pick_line(_tv(ECHOS65, ECHOS65_V)["inconnu"]), a, ctx)
	var s: float = float(l.get("sentiment", 0.0))
	var t: String = _v65_tpl(_pick_line(_tv(ECHOS65, ECHOS65_V)["neg" if s < -0.2 else "pos"]), a, ctx)
	return t + " " + _fill(_v65_avis_court(l), ctx)


## Une nouvelle qu'il n'a pas encore commentée : sur un proche (ou, rarement, sur quelqu'un du
## village), ou l'avis du joueur sur lui-même. Elle change son humeur et son amitié.
func _v65_ragot(ctx: Dictionary, rumeur: bool) -> String:
	var me: String = _v65_id()
	var vus: Array = memoire["ragots_vus"]
	var evs: Array = Societe.evenements
	for i in range(evs.size() - 1, maxi(-1, evs.size() - 25), -1):
		var e: Dictionary = evs[i]
		var n: int = int(e.get("n", 0))
		if vus.has(n) or vus.has(float(n)):
			continue
		var qui: String = str(e.get("qui", ""))
		var quoi: String = str(e.get("quoi", ""))
		if quoi == "avis":
			var de: String = str(e.get("de", ""))
			if qui == me and de != me:
				vus.append(n)
				return _v65_avis_echo(e, ctx)
			continue
		if qui == me or qui == "":
			vus.append(n)
			continue
		var known: bool = _v65_liens().has(qui)
		if not known and not (Societe.groupe(qui) == Societe.groupe(me) and rng.randf() < (0.5 if rumeur else 0.2)):
			continue
		vus.append(n)
		while vus.size() > 40:
			vus.pop_front()
		var s: float = Societe.sentiment(me, qui) if known else 0.0
		var band: String = "pos" if s > 0.25 else ("neg" if s < -0.25 else "neu")
		var key: String = quoi
		if quoi == "cadeau" and not bool(e.get("aime", true)):
			key = "cadeau_rate"
		if not RAGOTS65.has(key):
			continue
		match key:
			"cadeau":
				if band == "pos":
					_bond(1.5)
					_mood(0.04)
			"quete":
				_bond(3.0 if band == "pos" else 1.0)
				if band == "pos":
					_mood(0.08)
			"frappe":
				if band == "pos":
					_bond(-6.0)
					_mood(-0.25)
				elif band == "neu":
					_bond(-1.0)
			"confidence":
				if band == "pos":
					_bond(1.0)
		var appris: Array = memoire["appris"]
		appris.append([key, qui, str(e.get("objet", ""))])
		while appris.size() > 12:
			appris.pop_front()
		_remember("j'ai appris : %s (%s)" % [key, Societe.prenom(qui)], float(ctx.get("now", 0.0)))
		return _v65_tpl(_pick_line((_tv(RAGOTS65, RAGOTS65_V)[key] as Dictionary)[band]), qui, ctx, {"objet": str(e.get("objet", ""))})
	return ""


func _v65_avis_echo(e: Dictionary, ctx: Dictionary) -> String:
	var de: String = str(e.get("de", ""))
	var v: String = str(e.get("valeur", "sympa"))
	if not AVIS_ECHO65.has(v):
		return ""
	if v == "sympa":
		_bond(3.0)
		_mood(0.1)
	else:
		_bond(-2.0)
		_mood(-0.08 if float((data.get("traits", {}) as Dictionary).get("humour", 0.5)) < 0.6 else 0.02)
	(memoire["faits"] as Dictionary)["avis_moi"] = v
	_remember("il paraît qu'il me trouve " + ("sympathique" if v == "sympa" else "bizarre"), float(ctx.get("now", 0.0)))
	return _v65_tpl(_pick_line(_tv(AVIS_ECHO65, AVIS_ECHO65_V)[v]), de, ctx)


## « La dernière fois, je t'ai raconté… » ; ou la réponse que le joueur a faite à sa question.
func _v65_rappel(ctx: Dictionary) -> String:
	var me: String = _v65_id()
	var ds: String = str(memoire.get("dernier_sujet", ""))
	memoire["dernier_sujet"] = ""
	var hist: Array = v65.get("histoire", [])
	if ds.begins_with("histoire:"):
		var i: int = int(ds.substr(9))
		if i < hist.size():
			var t: String = _tv("La dernière fois, je t'ai raconté %s.", "La dernière fois, je vous ai raconté %s.") % str((hist[i] as Dictionary).get("titre", "un bout de ma vie"))
			var ch: int = int(memoire.get("chapitre", 0))
			if ch < hist.size() and affinite >= _v65_gate(ch):
				t += _tv(" Tu veux la suite ?", " Vous voulez la suite ?")
			return _fill(t, ctx)
	elif ds.begins_with("gens:"):
		var x: String = ds.substr(5)
		var t2: String = _tv("La dernière fois, je t'ai parlé %s.", "La dernière fois, je vous ai parlé %s.") % _de(Societe.nom_pour(me, x))
		if int((ctx.get("rencontres", {}) as Dictionary).get(x, 0)) > 0:
			t2 += _tv(" Tu as eu l'occasion de lui parler, depuis ?", " Vous avez eu l'occasion de lui parler, depuis ?")
		else:
			t2 += _tv(" Si tu {le} croises, dis-lui bonjour de ma part.", " Si vous {le} croisez, dites-lui bonjour de ma part.")
		return _v65_tpl(t2, x, ctx)
	elif ds == "reve":
		return _tv("Je repense à ce que je t'ai confié l'autre jour, mon rêve… Tu n'en as parlé à personne, j'espère ?", "Je repense à ce que je vous ai confié l'autre jour, mon rêve… Vous n'en avez parlé à personne, j'espère ?")
	var rp: String = _v65_rappel_question()
	if rp != "" and rng.randf() < 0.6:
		return _fill(rp, ctx)
	return ""


func _v65_rappel_question() -> String:
	var faits: Dictionary = memoire["faits"]
	if not faits.has("q65"):
		return ""
	for r in (v65.get("question", {}) as Dictionary).get("reponses", []):
		if str(r.get("valeur", "")) == str(faits["q65"]):
			return str(r.get("rappel", ""))
	return ""


## Ce dont il se souvient (sujet « Tu te souviens de moi ? »).
func _v65_souvenirs(ctx: Dictionary) -> Array:
	var me: String = _v65_id()
	var out: Array = []
	if v65.is_empty():
		return out
	var hist: Array = v65.get("histoire", [])
	var ch: int = int(memoire.get("chapitre", 0))
	if ch > 0:
		if ch >= hist.size():
			out.append(_tv("Je t'ai raconté toute ma vie. Ça, je ne l'oublie pas.", "Je vous ai raconté toute ma vie. Ça, je ne l'oublie pas."))
		elif ch == 1:
			out.append(_tv("Je t'ai raconté le début de mon histoire.", "Je vous ai raconté le début de mon histoire."))
		else:
			out.append(_tv("Je t'ai raconté %d chapitres de ma vie.", "Je vous ai raconté %d chapitres de ma vie.") % ch)
	var names: Array = []
	for x in memoire.get("racontes", {}):
		if names.size() < 4:
			names.append(_de(Societe.nom_pour(me, str(x))))
	if not names.is_empty():
		out.append(_tv("Je t'ai parlé %s.", "Je vous ai parlé %s.") % _liste(names))
	var rp: String = _v65_rappel_question()
	if rp != "":
		out.append(_fill(rp, ctx))
	var faits: Dictionary = memoire["faits"]
	for k in faits:
		if str(k).begins_with("avis_") and str(k) != "avis_moi" and str(faits[k]) != "nsp":
			var x2: String = str(k).substr(5)
			out.append(_tv("Tu m'as dit que tu trouvais %s %s.", "Vous m'avez dit que vous trouviez %s %s.") % [Societe.nom_pour(me, x2), "très sympathique" if str(faits[k]) == "sympa" else "un peu bizarre"])
			break
	var deeds: Array = []
	var whos: Array = []
	var appris: Array = (memoire.get("appris", []) as Array).duplicate()
	appris.reverse()
	for a in appris:
		if whos.has(str(a[1])):
			continue
		whos.append(str(a[1]))
		var who: String = Societe.designe(me, str(a[1]))
		match str(a[0]):
			"quete":
				deeds.append(_tv("que tu as aidé ", "que vous avez aidé ") + who)
			"frappe":
				deeds.append(_tv("que tu as frappé ", "que vous avez frappé ") + who)
			"cadeau":
				deeds.append(_tv("que tu as fait un cadeau à ", "que vous avez fait un cadeau à ") + who)
		if deeds.size() >= 2:
			break
	if not deeds.is_empty():
		out.append(_fr("Et je sais " + " et ".join(deeds) + "."))
	return out
