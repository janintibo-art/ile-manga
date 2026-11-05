extends RefCounted
## V111 : la version du jeu, choisie au début de chaque nouvelle partie (et dans les Paramètres) :
##  - « Tout public » : pas d'alcool, personne n'est ivre. Dans les tavernes, on boit du pétillant
##    de Forgefer, du tonique noir, du miel chaud, de la pomme pétillante… (les textes viennent de
##    data/langues/public.json, dans les trois langues), et boire ne fait plus tourner la tête
##    (on gagne quand même +1 de force pendant deux minutes) ;
##  - « Public averti » : les textes tels qu'ils sont écrits (bière, rhum, grog, pirates éméchés, et
##    en anglais / espagnol la vraie boisson), les insultes des pirates plus salées et des
##    bagarres plus rudes (plus de monde s'en mêle, trois cognent en même temps).
## Tant que le joueur n'a rien choisi (les tests), le jeu reste comme avant la V111.
##
## API (statique) : Public.charger() au démarrage ; Public.choisir("tout") ; Public.mode ;
##   Public.tout() ; Public.averti() ; Public.choisi ; Public.nom("averti") -> « Public averti ».

const MODES := ["tout", "averti"]
const NOMS := {"tout": "Tout public", "averti": "Public averti"}
const FICHIER := "user://public_v111.cfg"

static var mode: String = ""
static var choisi: bool = false


## Au démarrage : la version choisie la dernière fois (rien si le joueur n'a jamais choisi).
static func charger() -> void:
	var cf := ConfigFile.new()
	if cf.load(FICHIER) == OK and cf.has_section_key("public", "mode") and MODES.has(str(cf.get_value("public", "mode", ""))):
		mode = str(cf.get_value("public", "mode", ""))
		choisi = true


static func choisir(m: String, garder: bool = true) -> void:
	if not MODES.has(m):
		m = "tout"
	mode = m
	choisi = true
	if garder:
		var cf := ConfigFile.new()
		cf.set_value("public", "mode", m)
		cf.save(FICHIER)


## Pour les tests : revenir à « rien de choisi » (le jeu d'avant la V111).
static func oublier() -> void:
	mode = ""
	choisi = false


static func tout() -> bool:
	return mode == "tout"


static func averti() -> bool:
	return mode == "averti"


static func nom(m: String) -> String:
	return str(NOMS.get(m, "Tout public"))


static func suivant() -> String:
	return "averti" if mode == "tout" else "tout"
