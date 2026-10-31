extends RefCounted
## V65 : ce que les habitants savent les uns des autres — et du joueur.
##  - Les fiches V65 (data/histoires_v65/<groupe>.json), une par habitant : son histoire en
##    chapitres, son rêve, la question qu'il pose au joueur, et ses liens (les gens qu'il connaît :
##    comment il les appelle, ce qu'il en pense, les anecdotes qu'il raconte sur eux, ce qu'ils se
##    disent quand ils se croisent).
##  - Les nouvelles qui circulent : ce que le joueur a fait à quelqu'un (un cadeau, une quête, un
##    coup, une confidence reçue, son avis sur quelqu'un). Les proches l'apprennent et réagissent.
##  - Qui a parlé de qui au joueur : la personne concernée finit par le savoir.
## Tout est partagé par les cerveaux (variables statiques) et sauvegardé avec la partie (« societe »).

const DOSSIER := "res://data/histoires_v65/"
const GROUPES := ["heros", "azur", "teuf", "carene", "tazira", "cliquetis", "ramure", "elfes", "nains", "atlantes", "fees", "arcanelle", "balafre", "soleils", "braise", "montjoie", "boucan", "astralys", "larsen"]
const MAX_EVENEMENTS := 80

static var _fiches: Dictionary = {}
static var _groupe: Dictionary = {}
static var _charge: bool = false
## Nouvelles : [{n, t, quoi, qui, ...}] (n = numéro unique, t = temps de jeu en secondes).
static var evenements: Array = []
static var serie: int = 0
## Qui a parlé de qui au joueur : sujet -> {conteur: nombre de fois}.
static var entendu: Dictionary = {}


static func charger() -> void:
	if _charge:
		return
	_charge = true
	for g in GROUPES:
		var path: String = DOSSIER + str(g) + ".json"
		if not FileAccess.file_exists(path):
			push_warning("V65 : fiches absentes : " + path)
			continue
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if d is Dictionary:
			for k in d:
				if d[k] is Dictionary:
					_fiches[str(k)] = d[k]
					_groupe[str(k)] = str(g)
	print("ILE_MANGA_V65: ", _fiches.size(), " habitants avec leur histoire")


static func nombre() -> int:
	charger()
	return _fiches.size()


static func fiche(id: String) -> Dictionary:
	charger()
	return _fiches.get(id, {})


static func ids() -> Array:
	charger()
	return _fiches.keys()


## Le groupe (village) d'un habitant : « azur », « tazira »…
static func groupe(id: String) -> String:
	charger()
	return str(_groupe.get(id, ""))


static func prenom(id: String) -> String:
	var f: Dictionary = fiche(id)
	return str(f.get("prenom", id.capitalize()))


static func feminin(id: String) -> bool:
	return str(fiche(id).get("genre", "m")) == "f"


static func lien(a: String, b: String) -> Dictionary:
	return (fiche(a).get("liens", {}) as Dictionary).get(b, {})


## « ma voisine Rose », « Fernand » : comment a désigne b dans une phrase.
static func designe(a: String, b: String) -> String:
	var l: Dictionary = lien(a, b)
	if l.is_empty():
		return prenom(b)
	return (str(l.get("qui", "")) + " " + str(l.get("nom", prenom(b)))).strip_edges()


static func nom_pour(a: String, b: String) -> String:
	var l: Dictionary = lien(a, b)
	return str(l.get("nom", prenom(b))) if not l.is_empty() else prenom(b)


static func sentiment(a: String, b: String) -> float:
	return float(lien(a, b).get("sentiment", 0.0))


# =================================================================== nouvelles

## Une nouvelle sur le joueur et quelqu'un (qui). Deux nouvelles identiques à moins de dix
## minutes d'intervalle n'en font qu'une.
static func noter(quoi: String, qui: String, now: float, extra: Dictionary = {}) -> void:
	for i in range(evenements.size() - 1, maxi(-1, evenements.size() - 12), -1):
		var e: Dictionary = evenements[i]
		if str(e.get("quoi", "")) == quoi and str(e.get("qui", "")) == qui and str(e.get("de", "")) == str(extra.get("de", "")) and now - float(e.get("t", 0.0)) < 600.0:
			return
	serie += 1
	var ev: Dictionary = {"n": serie, "t": now, "quoi": quoi, "qui": qui}
	for k in extra:
		ev[k] = extra[k]
	evenements.append(ev)
	while evenements.size() > MAX_EVENEMENTS:
		evenements.pop_front()


## Le conteur a parlé de « sujet » au joueur.
static func dire(conteur: String, sujet: String) -> void:
	var d: Dictionary = entendu.get(sujet, {})
	d[conteur] = int(d.get(conteur, 0)) + 1
	entendu[sujet] = d


static func serialize() -> Dictionary:
	return {"evenements": evenements.duplicate(true), "serie": serie, "entendu": entendu.duplicate(true)}


static func load_data(d: Dictionary) -> void:
	evenements = []
	entendu = {}
	serie = 0
	if d.is_empty():
		return
	var ev: Variant = d.get("evenements", [])
	if ev is Array:
		for e in ev:
			if e is Dictionary:
				evenements.append((e as Dictionary).duplicate(true))
	serie = int(d.get("serie", evenements.size()))
	var en: Variant = d.get("entendu", {})
	if en is Dictionary:
		entendu = (en as Dictionary).duplicate(true)
