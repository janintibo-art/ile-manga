extends RefCounted
## V126 : le réglage de LUMINOSITÉ (Paramètres) : sombre, normale, claire, très claire.
## Il éclaircit (ou assombrit) toute l'image, partout, et il est gardé dans user://reglages_son.cfg
## avec les volumes. Il agit sur le réglage d'image du WorldEnvironment (« adjustment_brightness »),
## que rien d'autre dans le jeu ne touche.

const FICHIER := "user://reglages_son.cfg"
const NIVEAUX := [["sombre", 0.85], ["normale", 1.0], ["claire", 1.18], ["très claire", 1.36]]


static func index() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(FICHIER) != OK:
		return 1
	return clampi(int(cfg.get_value("image", "luminosite", 1)), 0, NIVEAUX.size() - 1)


static func valeur() -> float:
	return float(NIVEAUX[index()][1])


static func libelle() -> String:
	return "Luminosité : " + str(NIVEAUX[index()][0])


static func suivante(main: Node) -> void:
	var cfg := ConfigFile.new()
	cfg.load(FICHIER)
	cfg.set_value("image", "luminosite", (index() + 1) % NIVEAUX.size())
	cfg.save(FICHIER)
	appliquer(main)


static func appliquer(main: Node) -> void:
	if main == null:
		return
	for c in main.get_children():
		if c is WorldEnvironment and (c as WorldEnvironment).environment != null:
			var env: Environment = (c as WorldEnvironment).environment
			env.adjustment_enabled = true
			env.adjustment_brightness = valeur()
			return
