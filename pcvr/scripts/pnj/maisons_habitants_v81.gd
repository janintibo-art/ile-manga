extends RefCounted
## V81 : les habitants des maisons qu'on visite. Ils n'ont pas de nom fixe (chaque maison leur en
## donne un) mais un vrai corps (V64, généré comme celui des autres habitants : outils
## habitants_v64, fiches extraites par extraire_fiches.gd) à l'allure de leur ville : démons de
## Pandémonia, punks de Port-Boucan, Lumens d'Astralys, gens à oreilles de Ramure, etc.
## Chaque fiche : id « f81_<style>_<n> », rôle (homme, femme, vieux, vieille, garcon, fille),
## « classe » (la classe d'habitant qui sait les habiller : lumen, pirate ou ramure).

## [style de pièce] -> [village du générateur, classe, nombre de corps]
const STYLES := {
	"montjoie": ["montjoie", "lumen", 10], "braise": ["pandemonia", "lumen", 10], "boucan": ["boucan", "lumen", 10],
	"tazira": ["tazira", "lumen", 8], "astralys": ["astralys", "lumen", 8], "azur": ["azur", "lumen", 6],
	"cliquetis": ["cliquetis", "lumen", 6], "ramure": ["ramure", "ramure", 6], "arcanelle": ["arcanelle", "lumen", 6],
	"pirate": ["balafre", "pirate", 6], "carene": ["carene", "lumen", 6], "egypte": ["egypte", "lumen", 6],
	"maya": ["maya", "lumen", 6], "azteque": ["azteque", "lumen", 6],
	"elfe": ["elfes", "lumen", 6], "atlante": ["atlantes", "lumen", 4],
}
## Les autres styles de pièce empruntent les gens d'une ville.
const ALIAS := {"boucan_entrepot": "boucan", "boucan_conteneur": "boucan", "fee": "elfe"}
## Les rôles, dans l'ordre des corps de chaque ville (les 6 premiers partout).
const ROLES := ["homme", "femme", "vieux", "vieille", "garcon", "fille", "homme", "femme", "homme", "femme"]

const PRENOMS := {
	"montjoie": {"h": ["Gauvain", "Thibaut", "Enguerrand", "Bertrand", "Aymeric", "Godefroy", "Lancelin", "Perceval", "Guillaume", "Anselme", "Barnabé", "Hugues"],
		"f": ["Iseult", "Bertille", "Aliénor", "Mahaut", "Guenièvre", "Ysabeau", "Clémence", "Aude", "Brunehilde", "Mélisende", "Pernelle", "Ermengarde"]},
	"braise": {"h": ["Brasillon", "Fumerol", "Cendrin", "Sulfure", "Ardent", "Tisonnet", "Charbonnot", "Grillard", "Flambert", "Pyrrhus", "Soufflet", "Étincel"],
		"f": ["Braisette", "Flammèche", "Cendrine", "Pyrène", "Fumeline", "Incandescia", "Mèche", "Volcane", "Ardoisine", "Scorie", "Éclisse", "Tisane"]},
	"boucan": {"h": ["Clou", "Riff", "Larsen", "Bidon", "Rivet", "Ferraille", "Pogo", "Boulon", "Gros-Son", "Écrou", "Fanfare", "Rustine"],
		"f": ["Crécelle", "Paillette", "Zazou", "Mélodie", "Sirène", "Bricole", "Pétard", "Fanzine", "Basse", "Cymbale", "Bobine", "Rouille"]},
	"tazira": {"h": ["Idriss", "Karim", "Mehdi", "Yanis", "Brahim", "Saïd", "Nabil", "Hakim", "Rachid", "Sofiane", "Ilyès", "Malik"],
		"f": ["Leïla", "Nora", "Samira", "Yasmina", "Zineb", "Houda", "Amina", "Rania", "Salma", "Nadia", "Inès", "Meriem"]},
	"astralys": {"h": ["Quasar", "Zénith", "Pulsar", "Orbite", "Photon", "Neutrino", "Cosmo", "Albédo", "Parsec", "Équinoxe", "Nadir", "Spin"],
		"f": ["Nébuline", "Comète", "Aurore", "Vega", "Lyre", "Galaxie", "Céleste", "Astrée", "Andromède", "Prisme", "Opale", "Luciole"]},
	"azur": {"h": ["Marius", "Fanfan", "Titin", "Escartefigue", "Panisse", "Gaston", "Honoré", "Félix", "Toinou", "Bastien", "Raoul", "Zébulon"],
		"f": ["Fanny", "Honorine", "Mireille", "Magali", "Zoé", "Rose", "Babette", "Nine", "Lili", "Marcelle", "Paulette", "Rosalie"]},
	"cliquetis": {"h": ["Bielle", "Piston", "Ressort", "Mécano", "Engrenage", "Cardan", "Manivelle", "Volant", "Vilebrequin", "Écrou", "Soupape", "Cliquet"],
		"f": ["Turbine", "Bobinette", "Hélice", "Vapeur", "Molette", "Bougie", "Rivette", "Dynamo", "Pendule", "Clé", "Gâchette", "Sirène"]},
	"ramure": {"h": ["Noisetin", "Plumeau", "Gland", "Moustachu", "Brindille", "Touffu", "Croc", "Pomme-de-Pin", "Frisson", "Museau", "Taupinet", "Bourgeon"],
		"f": ["Noisette", "Myrtille", "Plumette", "Fougère", "Truffe", "Câline", "Mousseline", "Pâquerette", "Vanille", "Mûre", "Clochette", "Belette"]},
	"arcanelle": {"h": ["Merlinot", "Grimoald", "Sortilège", "Alambic", "Philtre", "Abracadabrus", "Runic", "Hiboux", "Chaudronnet", "Étoilin", "Balthazar", "Mandragore"],
		"f": ["Mélusine", "Morgane", "Sibylle", "Ondine", "Belladone", "Viviane", "Esméralda", "Hécate", "Luna", "Myrrhe", "Gwendoline", "Pimprenelle"]},
	"pirate": {"h": ["Jambe-de-Bois", "Barbe-Grise", "Crochet-Fin", "Bigorneau", "Tonneau", "Sabord", "Moussaillon", "Calamar", "Hareng", "Gouvernail", "Corsaire", "Rat-de-Cale"],
		"f": ["Anne-Mer", "Perle-Noire", "Sirène", "Tempête", "Bourrasque", "Marée", "Coquille", "Écume", "Vague", "Rascasse", "Mouette", "Frégate"]},
	"carene": {"h": ["Yann", "Gwenaël", "Loïc", "Erwan", "Corentin", "Tanguy", "Ronan", "Mael", "Goulven", "Jakez", "Per", "Alan"],
		"f": ["Gwen", "Maïwenn", "Nolwenn", "Rozenn", "Soazig", "Annaïg", "Enora", "Lena", "Morgane", "Tifenn", "Bleuenn", "Katell"]},
	"egypte": {"h": ["Imhotep", "Nakht", "Sennefer", "Ahmose", "Djehouti", "Khaemouaset", "Paneb", "Ramose", "Sobekhotep", "Ouni", "Kha", "Meryré"],
		"f": ["Nefertari", "Mérit", "Tiyi", "Isis", "Henoutmira", "Satamon", "Nebet", "Taouret", "Iset", "Sitré", "Néfret", "Ankhésen"]},
	"maya": {"h": ["Kinich", "Chac", "Itzam", "Yax", "Ek", "Kan", "Bacab", "Hun", "Ah-Puch", "Kukul", "Pakal", "Tohil"],
		"f": ["Ixchel", "Ixtab", "Sak-Nik", "Kanal", "Ixik", "Yaxkin", "Chel", "Nikte", "Saasil", "Kuxtal", "Ix-Balam", "Muyal"]},
	"elfe": {"h": ["Elrohir", "Faelan", "Thranduin", "Aerendil", "Calenor", "Gilthas", "Lindir", "Merethor", "Nimrodel", "Orophel", "Silvan", "Tauron"],
		"f": ["Arwenya", "Elwing", "Galadwen", "Idril", "Luthiel", "Míriel", "Nimloth", "Silmë", "Tinúviel", "Yavië", "Elanor", "Aredhel"]},
	"atlante": {"h": ["Triton", "Nérée", "Okéanos", "Glaucos", "Pontos", "Phorcys", "Égée", "Thaumas", "Palémon", "Mélicerte", "Proteus", "Ichtys"],
		"f": ["Amphitrite", "Galatée", "Thétis", "Doris", "Ondine", "Néréa", "Marinella", "Coralie", "Perle", "Salacia", "Écume", "Calypso"]},
	"azteque": {"h": ["Cuauhtli", "Itzcoatl", "Tochtli", "Mazatl", "Ocelotl", "Xolotl", "Tenoch", "Acatl", "Ehecatl", "Tlacotl", "Huemac", "Coaxoch"],
		"f": ["Xochitl", "Citlali", "Itzel", "Yoltzin", "Atzin", "Nenetl", "Quetzalli", "Metztli", "Tonantzin", "Ameyal", "Nahui", "Teyacapan"]},
}

static var _cache: Dictionary = {}


static func style_of(style: String) -> String:
	return str(ALIAS.get(style, style)) if STYLES.has(ALIAS.get(style, style)) else "montjoie"


## Toutes les fiches (pour le générateur de corps et pour le jeu).
static func all_profiles() -> Array:
	if _cache.is_empty():
		for st in STYLES:
			var n: int = int(STYLES[st][2])
			for i in range(n):
				var p: Dictionary = _make(str(st), i)
				_cache[str(p["id"])] = p
	return _cache.values()


static func profile(id: String) -> Dictionary:
	all_profiles()
	return (_cache.get(id, {}) as Dictionary).duplicate(true)


## Un habitant de ce rôle dans cette ville (le tirage dépend de la maison).
static func pick(style: String, role: String, rng: RandomNumberGenerator) -> Dictionary:
	var st: String = style_of(style)
	var n: int = int(STYLES[st][2])
	var cands: Array = []
	for i in range(n):
		if ROLES[i] == role or (role == "adulte" and ROLES[i] in ["homme", "femme"]) or (role == "enfant" and ROLES[i] in ["garcon", "fille"]) or (role == "ancien" and ROLES[i] in ["vieux", "vieille"]):
			cands.append(i)
	# V84 : un homme aux cheveux longs sans barbe passe pour une femme (« Barnabé ») : on l'évite
	if not femme(role):
		var nets: Array = []
		for c in cands:
			var az: Dictionary = profile("f81_%s_%d" % [st, int(c)]).get("azur", {})
			if femme(str(ROLES[int(c)])) or not (str(az.get("coiffure", "")) == "long" and not az.has("barbe")):
				nets.append(c)
		if not nets.is_empty():
			cands = nets
	if cands.is_empty():
		cands = [0]
	var i2: int = int(cands[rng.randi() % cands.size()])
	var p: Dictionary = profile("f81_%s_%d" % [st, i2])
	return p


static func femme(role: String) -> bool:
	return role in ["femme", "vieille", "fille"]


static func prenom(style: String, role: String, rng: RandomNumberGenerator) -> String:
	var st: String = style_of(style)
	var l: Dictionary = PRENOMS.get(st, PRENOMS["montjoie"])
	var r: String = role
	var lst: Array = l["f"] if femme(r) else l["h"]
	var nm: String = str(lst[rng.randi() % lst.size()])
	if r in ["vieux"]:
		nm = ["Papi ", "Le vieux ", "Pépé ", "Grand-père "][rng.randi() % 4] + nm
	elif r in ["vieille"]:
		nm = ["Mamie ", "La vieille ", "Mémé ", "Grand-mère "][rng.randi() % 4] + nm
	elif r in ["garcon", "fille"]:
		nm = ["Petit ", "", "", "P'tit "][rng.randi() % 4] + nm if r == "garcon" else ["Petite ", "", ""][rng.randi() % 3] + nm
	return nm.strip_edges()


# =================================================================== fabrication des fiches

static func _c(r: RandomNumberGenerator, pal: Array) -> Array:
	var c: Array = pal[r.randi() % pal.size()]
	return [clampf(float(c[0]) + r.randf_range(-0.04, 0.04), 0, 1), clampf(float(c[1]) + r.randf_range(-0.04, 0.04), 0, 1), clampf(float(c[2]) + r.randf_range(-0.04, 0.04), 0, 1)]


static func _make(st: String, i: int) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = hash("f81_" + st + str(i))
	var role: String = ROLES[i]
	var f: bool = femme(role)
	var old: bool = role in ["vieux", "vieille"]
	var kid: bool = role in ["garcon", "fille"]
	var vil: String = str(STYLES[st][0])
	var hair_dark := [[0.08, 0.06, 0.05], [0.18, 0.12, 0.08], [0.3, 0.19, 0.11], [0.12, 0.09, 0.07]]
	var hair_light := [[0.85, 0.7, 0.4], [0.62, 0.36, 0.16], [0.5, 0.3, 0.15], [0.75, 0.45, 0.2], [0.3, 0.19, 0.11]]
	var hair_old := [[0.82, 0.82, 0.8], [0.66, 0.65, 0.63], [0.92, 0.92, 0.9]]
	var clothes := [[0.6, 0.15, 0.12], [0.2, 0.3, 0.55], [0.25, 0.42, 0.25], [0.8, 0.68, 0.3], [0.45, 0.3, 0.2], [0.85, 0.82, 0.75], [0.4, 0.2, 0.45], [0.2, 0.45, 0.5]]
	var skin_eu := [[1.0, 0.86, 0.74], [0.98, 0.8, 0.66], [0.9, 0.7, 0.56], [0.74, 0.54, 0.4], [0.56, 0.38, 0.27]]
	var skin := skin_eu
	var hair := hair_light if r.randf() < 0.55 else hair_dark
	match vil:
		"tazira", "egypte":
			skin = [[0.8, 0.6, 0.45], [0.74, 0.54, 0.4], [0.62, 0.44, 0.32], [0.56, 0.38, 0.27]]
			hair = hair_dark
		"maya", "azteque":
			skin = [[0.66, 0.46, 0.33], [0.6, 0.42, 0.3], [0.74, 0.53, 0.38]]
			hair = [[0.06, 0.05, 0.045], [0.1, 0.08, 0.06]]
	var az := {
		"cheveux": _c(r, hair_old if old else hair),
		"haut": _c(r, clothes),
		"yeux": _c(r, [[0.3, 0.45, 0.6], [0.25, 0.18, 0.1], [0.3, 0.5, 0.3], [0.4, 0.3, 0.15]]),
		"coiffure": (["long", "chignon", "tresse", "queue", "boucles", "carre"] if f else ["court", "court", "boucles", "chauve" if old else "court", "long"])[r.randi() % (6 if f else 5)],
	}
	if not f and not kid and r.randf() < 0.45:
		az["barbe"] = ["courte", "longue", "moustache"][r.randi() % 3]
	if f and r.randf() < 0.6:
		az["robe"] = _c(r, clothes)
		if r.randf() < 0.4:
			az["robe_longue"] = true
	if old:
		az["vieux"] = true
		az["carrure"] = [0.85, 0.95, 1.1, 1.2][r.randi() % 4]
	elif kid:
		az["taille"] = r.randf_range(0.72, 0.8)
	else:
		az["carrure"] = [0.85, 0.95, 1.0, 1.1, 1.25][r.randi() % 5]
		if r.randf() < 0.25:
			az["lunettes"] = true
	if r.randf() < 0.18 and not kid:
		az["tablier"] = _c(r, [[0.92, 0.9, 0.85], [0.3, 0.25, 0.2], [0.6, 0.55, 0.42]])
	var p := {"id": "f81_%s_%d" % [st, i], "nom": "?", "titre": "habitant", "village": vil, "classe": str(STYLES[st][1]),
		"role": role, "femme": f, "azur": az, "teinte": _c(r, skin), "humeur_base": 0.4, "repliques": {}}
	if vil in ["elfes", "atlantes"]:
		# V82 : les elfes et les Atlantes ont leur propre fiche (« elfe »), comme ceux de leur village
		p.erase("azur")
		var at: bool = vil == "atlantes"
		var robes: Array = [[0.18, 0.55, 0.6], [0.8, 0.85, 0.88], [0.25, 0.3, 0.55], [0.3, 0.6, 0.5]] if at else [[0.2, 0.45, 0.35], [0.3, 0.38, 0.6], [0.55, 0.25, 0.3], [0.88, 0.82, 0.62], [0.4, 0.32, 0.55]]
		var el := {"cheveux": _c(r, hair_old if old else ([[0.75, 0.88, 0.92], [0.95, 0.75, 0.55], [0.2, 0.3, 0.35], [0.88, 0.88, 0.85]] if at else [[0.85, 0.75, 0.5], [0.9, 0.9, 0.85], [0.55, 0.3, 0.15], [0.2, 0.18, 0.16], [0.95, 0.8, 0.5]])),
			"coiffure": (["long", "tresse", "chignon"] if f else ["court", "long", "queue"])[r.randi() % 3], "silhouette": "robe" if f else "tunique",
			"robe": _c(r, robes), "cape": [0.9, 0.93, 0.95] if at else [0.9, 0.88, 0.8], "bijou": [0.9, 0.8, 0.55] if at else [0.85, 0.85, 0.9],
			"yeux": _c(r, [[0.3, 0.65, 0.75], [0.35, 0.5, 0.6], [0.3, 0.55, 0.4]]),
			"texture": "res://assets/textures/" + ("pnj/atlante_nacre.png" if at else "elfes/elfe_azur.png")}
		if kid:
			el["taille"] = r.randf_range(0.72, 0.8)
		if old:
			el["vieux"] = true
		p["elfe"] = el
		if at:
			p["atlante"] = {"collier": r.randf() < 0.5, "nageoires": r.randf() < 0.6}
			p["teinte"] = [0.88, 0.95, 1.0]
		else:
			p["teinte"] = _c(r, [[1.0, 0.9, 0.84], [0.95, 0.82, 0.72]])
		return p
	match vil:
		"montjoie":
			var t: Array = ["artisan", "paysan", "marchand", "cuisinier", "savant", "barde", "noble", "forgeron"]
			p["mj"] = {"tenue": "enfant" if kid else str(t[r.randi() % t.size()])}
			if r.randf() < 0.3 and not kid:
				p["mj"]["chapeau"] = ["bonnet", "chaperon", "plume", "toque"][r.randi() % 4]
		"pandemonia":
			var formes := ["belier", "courbes", "droites", "petites"]
			var lueurs := [[0.45, 0.72, 1.0], [0.45, 1.0, 0.42], [0.72, 0.42, 1.0], [1.0, 0.28, 0.12], [1.0, 0.52, 0.16], [1.0, 0.76, 0.25]]
			p["demon"] = {"cornes": {"c": _c(r, [[0.07, 0.05, 0.06], [0.2, 0.12, 0.12], [0.95, 0.9, 0.8]]), "forme": "petites" if kid else str(formes[r.randi() % 4]), "taille": 0.6 if kid else r.randf_range(0.8, 1.2)},
				"lueur": lueurs[r.randi() % lueurs.size()], "queue": {"c": _c(r, [[0.3, 0.12, 0.14], [0.25, 0.27, 0.33]]), "long": r.randf_range(0.7, 1.2), "pointe": ["fleche", "touffe"][r.randi() % 2]},
				"tenue": "enfant" if kid else ["artisan", "marchand", "cuisinier", "noble", "savant"][r.randi() % 5]}
			p["teinte"] = _c(r, [[0.84, 0.4, 0.38], [0.7, 0.3, 0.32], [0.6, 0.45, 0.65], [0.5, 0.55, 0.7], [0.92, 0.6, 0.5]])
		"boucan":
			var tb: Array = ["perfecto", "salopette", "sweat", "veste_jean", "bleu_travail", "robe_recup", "chale", "tablier"]
			p["punk"] = {"tenue": "enfant" if kid else str(tb[r.randi() % tb.size()]), "clous": r.randf() < 0.4, "patchs": r.randf() < 0.5}
			if r.randf() < 0.35:
				p["punk"]["chapeau"] = ["bandana", "bonnet", "casquette"][r.randi() % 3]
			if not old and r.randf() < 0.35:
				az["coiffure"] = ["crete", "crete_courte"][r.randi() % 2]
				az["cheveux"] = _c(r, [[0.9, 0.2, 0.5], [0.2, 0.7, 0.3], [0.2, 0.4, 0.9], [0.95, 0.6, 0.1]])
		"astralys":
			var peaux: Array = ["argent", "bleu_pale", "lavande", "or_pale", "rose_nacre", "turquoise"]
			p["lumen"] = {"antennes": r.randf() < 0.6, "bijou": ["aucun", "collier", "diademe", "halo"][r.randi() % 4], "crete": ["aucune", "cristal", "filaments"][r.randi() % 3],
				"objet": "aucun", "peau": str(peaux[r.randi() % peaux.size()]), "tenue": "enfant" if kid else ["cape", "combinaison", "robe_longue", "toge", "tunique"][r.randi() % 5]}
			az["coiffure"] = "chauve"
			p["teinte"] = [0.8, 0.86, 0.95]
		"ramure":
			var esp: Array = ["biche", "chat", "ecureuil", "lapin", "loup", "ours", "renard", "tanuki"]
			var poil: Array = _c(r, [[0.62, 0.48, 0.36], [0.86, 0.42, 0.14], [0.45, 0.45, 0.5], [0.95, 0.92, 0.88], [0.42, 0.28, 0.17], [0.12, 0.12, 0.13]])
			p["kemo"] = {"espece": str(esp[r.randi() % esp.size()]), "poil": poil, "interieur": _c(r, [[0.9, 0.84, 0.82], [0.75, 0.66, 0.55], [0.98, 0.78, 0.76]]), "queue": r.randf_range(1.0, 1.3)}
		"tazira":
			p["tz"] = {}
			if not f and r.randf() < 0.4:
				if r.randf() < 0.5:
					p["tz"]["fez"] = true
				else:
					p["tz"]["turban"] = _c(r, [[0.9, 0.85, 0.75], [0.2, 0.3, 0.6], [0.85, 0.15, 0.15]])
			elif f and r.randf() < 0.6:
				p["tz"]["foulard_tete"] = _c(r, [[0.2, 0.55, 0.3], [0.85, 0.3, 0.1], [0.95, 0.75, 0.2], [0.9, 0.85, 0.75]])
		"cliquetis":
			p["cq"] = {}
			if r.randf() < 0.4 and not kid:
				p["cq"]["lunettes_aviateur"] = true
			if r.randf() < 0.3 and not kid:
				p["cq"]["haut_de_forme"] = _c(r, [[0.08, 0.08, 0.09], [0.35, 0.25, 0.15]])
			if old and r.randf() < 0.6:
				p["cq"]["monocle"] = true
		"arcanelle":
			p["arc"] = {"robe": _c(r, [[0.16, 0.14, 0.36], [0.48, 0.12, 0.22], [0.32, 0.42, 0.26], [0.3, 0.42, 0.68]]), "cape": _c(r, [[0.2, 0.12, 0.28], [0.42, 0.36, 0.72], [0.9, 0.93, 0.98]])}
			if not kid and r.randf() < 0.4:
				p["arc"]["chapeau"] = _c(r, [[0.2, 0.18, 0.42], [0.45, 0.08, 0.05], [0.3, 0.38, 0.24]])
				p["arc"]["etoiles"] = r.randf() < 0.5
		"balafre":
			p["pirate"] = {"role": "matelot", "pacifique": true, "pv": 6, "equipage": "port"}
			p["tz"] = {}
			if not kid and r.randf() < 0.5:
				p["tz"]["bandana"] = _c(r, [[0.7, 0.1, 0.08], [0.2, 0.3, 0.55], [0.15, 0.15, 0.15]])
			elif not kid and r.randf() < 0.4:
				p["tz"]["tricorne"] = _c(r, [[0.08, 0.07, 0.07], [0.3, 0.2, 0.1]])
			if not kid and r.randf() < 0.3:
				p["tz"]["boucle"] = true
		"egypte":
			p["sol"] = {"tenue": "enfant" if kid else ["peuple", "peuple", "scribe"][r.randi() % 3]}
			if f and not kid and r.randf() < 0.5:
				p["sol"]["usekh"] = _c(r, [[0.2, 0.35, 0.6], [0.85, 0.65, 0.2]])
		"maya":
			p["sol"] = {"tenue": "enfant" if kid else ["peuple", "chasseur", "peuple"][r.randi() % 3]}
			if not kid and r.randf() < 0.4:
				p["sol"]["plumes"] = _c(r, [[0.1, 0.5, 0.3], [0.75, 0.15, 0.08]])
		"azteque":
			p["sol"] = {"tenue": "enfant" if kid else "peuple"}
			if r.randf() < 0.5:
				p["sol"]["jade"] = true
	return p
