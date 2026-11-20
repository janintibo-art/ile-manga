extends RefCounted
## V81 : les habitants des maisons qu'on visite. Ils n'ont pas de nom fixe (chaque maison leur en
## donne un) mais un vrai corps (V64, généré comme celui des autres habitants : outils
## habitants_v64, fiches extraites par extraire_fiches.gd) à l'allure de leur ville : démons de
## Pandémonia, punks de Port-Boucan, Lumens d'Astralys, gens à oreilles de Ramure, etc.
## Chaque fiche : id « f81_<style>_<n> », rôle (homme, femme, vieux, vieille, garcon, fille),
## « classe » (la classe d'habitant qui sait les habiller : lumen, pirate ou ramure).

## [style de pièce] -> [village du générateur, classe, nombre de corps]
## V185 : 32 corps par ville (avant : de 4 à 10 ; dans un étage de tour de Néopolis, jusqu'à 14 personnes
## pour 10 corps, dont 3 hommes : les mêmes revenaient, côte à côte). Les villes qui empruntent les gens
## d'une autre (ALIAS) ont leurs 32 corps à elles, à la suite (DECALAGE).
const LOT := 32
const STYLES := {
	"montjoie": ["montjoie", "lumen", 96], "braise": ["pandemonia", "lumen", 32], "boucan": ["boucan", "lumen", 64],
	"tazira": ["tazira", "lumen", 32], "astralys": ["astralys", "lumen", 32], "azur": ["azur", "lumen", 32],
	"cliquetis": ["cliquetis", "lumen", 32], "ramure": ["ramure", "ramure", 32], "arcanelle": ["arcanelle", "lumen", 32],
	"pirate": ["balafre", "pirate", 32], "carene": ["carene", "lumen", 64], "egypte": ["egypte", "lumen", 32],
	"maya": ["maya", "lumen", 32], "azteque": ["azteque", "lumen", 32],
	"elfe": ["elfes", "lumen", 32], "atlante": ["atlantes", "lumen", 32],
	"nain": ["nains", "lumen", 32],
	"yourte_fleurs": ["larsen", "lumen", 32], "yourte_rainville": ["larsen", "lumen", 32],
	"neo": ["neo", "lumen", 96], "neo_android": ["neo", "lumen", 24],
	"pasta": ["pasta", "lumen", 32],
}
## V185 : où commencent, dans les corps de la ville prêteuse, ceux de la ville qui emprunte (et combien).
const DECALAGE := {"hautefond": [32, 32], "hautefond_lieu": [32, 32], "strates": [64, 32], "strates_lieu": [64, 32],
	"nuees": [32, 32], "nuees_lieu": [32, 32], "dome": [64, 32], "dome_lieu": [64, 32],
	"fronde": [32, 32], "fronde_lieu": [32, 32], "perchee": [32, 32], "perchee_lieu": [32, 32],
	"nuees_android": [12, 12], "neo_android": [0, 12]}
## Les autres styles de pièce empruntent les gens d'une ville.
const ALIAS := {"boucan_entrepot": "boucan", "boucan_conteneur": "boucan", "fee": "elfe", "hautefond": "montjoie", "hautefond_lieu": "montjoie",
	"nuees": "neo", "nuees_lieu": "neo", "nuees_android": "neo_android",
	"strates": "montjoie", "strates_lieu": "montjoie", "fronde": "boucan", "fronde_lieu": "boucan",
	"dome": "neo", "dome_lieu": "neo", "perchee": "carene", "perchee_lieu": "carene",
	# V175 : les bus peints de l'Île de Larsen (les gens du Camp des Fleurs)
	"larsen": "yourte_fleurs"}
## Les rôles, dans l'ordre des corps de chaque ville (les 6 premiers partout).
const ROLES := ["homme", "femme", "vieux", "vieille", "garcon", "fille", "homme", "femme", "homme", "femme",
	# V185 : les 22 suivants (surtout des adultes : ce sont eux qu'on croise le plus)
	"homme", "femme", "homme", "femme", "homme", "femme", "vieux", "vieille", "homme", "femme", "homme", "femme",
	"garcon", "fille", "homme", "femme", "homme", "femme", "vieux", "vieille", "homme", "femme"]
static var _graine_lieu: int = -1          # V185 : la graine du tirage en cours (un lieu, un étage)
static var _pris: Dictionary = {}          # les corps déjà pris dans ce lieu
static var _lieu_fixe: bool = false


## V185 : un lieu commence (ses gens seront tirés avec plusieurs graines : pas deux fois le même corps
## jusqu'à fin_lieu).
static func debut_lieu() -> void:
	_lieu_fixe = true
	_graine_lieu = -1
	_pris.clear()


static func fin_lieu() -> void:
	_lieu_fixe = false
	_graine_lieu = -1
	_pris.clear()


## V185 : le rôle du corps n° i de sa ville (les lots de 32 se suivent).
static func role_de(i: int) -> String:
	return ROLES[i % LOT]

const PRENOMS := {
	# V146 : Pile-ou-Face (les corps de Carène ; des prénoms de Far West, à la française)
	"perchee": {"h": ["Jethro", "Ézéchiel", "Bartholin", "Josué", "Wilbur", "Abélard", "Cornil", "Hiram", "Silas", "Jebediah", "Lucius", "Amos"],
		"f": ["Calamité", "Prudence", "Constance", "Clémentine", "Abigaïl", "Marguerite", "Charity", "Lilou", "Opaline", "Josépha", "Annabelle", "Félicité"]},
	# V119 : le Dôme d'Azur (les corps de Néopolis, habillés de clair ; des prénoms de la mer)
	"dome": {"h": ["Corentin", "Loïc", "Marin", "Gaël", "Yvon", "Erwan", "Pierrick", "Malo", "Tanguy", "Ronan", "Alban", "Gwenn"],
		"f": ["Marine", "Océane", "Perle", "Coralie", "Nérée", "Naïade", "Maëlle", "Azur", "Lagune", "Écume", "Rozenn", "Morgane"]},
	# V118 : les Strates (les corps de Montjoie, les prénoms d'en bas, un peu anciens, comme ceux des mineurs)
	"strates": {"h": ["Anselme", "Firmin", "Casimir", "Gaston", "Léandre", "Marius", "Octave", "Prosper", "Séverin", "Ulysse", "Basile", "Évariste"],
		"f": ["Agathe", "Blandine", "Colette", "Delphine", "Eugénie", "Flavie", "Germaine", "Honorine", "Isaure", "Juliette", "Mathilde", "Rosalie"]},
	# V118 : la Fronde (les corps de Port-Boucan ; des surnoms d'atelier, comme Rivet, Bielle ou Gamelle)
	"fronde": {"h": ["Boulon", "Clapet", "Piston", "Tuyau", "Gadget", "Vérin", "Sifflet", "Loquet", "Crampon", "Cliquet", "Pignon", "Tambour"],
		"f": ["Visse", "Étincelle", "Rondelle", "Bobine", "Paillette", "Toupie", "Fusette", "Lampe", "Pastille", "Goupille", "Mélodie", "Ficelle"]},
	# V117 : la Cité des Nuées (les corps de Néopolis, habillés de clair ; les prénoms de l'île flottante)
	"nuees": {"h": ["Aurèle", "Cyrus", "Élian", "Orion", "Sacha", "Noé", "Thélo", "Zéphyr", "Ilan", "Maël", "Nils", "Adrien"],
		"f": ["Alizée", "Célia", "Nuée", "Brume", "Iris", "Maëlys", "Azalée", "Solène", "Line", "Elsa", "Livia", "Aube"]},
	# V116 : Hautefond (les corps sont ceux de Montjoie ; les prénoms, ceux de la ville-colonne)
	"hautefond": {"h": ["Anatole", "Eugène", "Léonce", "Philémon", "Émile", "Honoré", "Achille", "Aristide", "Gustave", "Théodule", "Alphonse", "Célestin"],
		"f": ["Adélaïde", "Eulalie", "Hortense", "Philomène", "Victorine", "Joséphine", "Léontine", "Ernestine", "Clémentine", "Augustine", "Valentine", "Félicie"]},
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
	"nain": {"h": ["Brokk", "Eitri", "Alvis", "Fjalar", "Galar", "Regin", "Sindri", "Grimbald", "Hornbori", "Skirvir", "Throrin", "Nyrdan"],
		"f": ["Sigrid", "Ragna", "Thyra", "Gudrun", "Astrid", "Ingrid", "Helka", "Dagny", "Runa", "Svala", "Hjalma", "Bergdis"]},
	"yourte_fleurs": {"h": ["Pissenlit", "Tambourin", "Cerf-Volant", "Arc", "Soleil", "Ruisseau", "Colibri", "Saule", "Pinson", "Zéphyr", "Ciel", "Lotus"],
		"f": ["Marguerite", "Pâquerette", "Iris", "Libellule", "Aurore", "Bleuet", "Rosée", "Myosotis", "Églantine", "Ondine", "Camomille", "Violette"]},
	"yourte_rainville": {"h": ["Crachin", "Ondée", "Gouttière", "Larsen", "Distorsion", "Brouillard", "Torrent", "Riff", "Écho", "Novembre", "Flaque", "Ciré"],
		"f": ["Giboulée", "Pluie", "Brume", "Mélodie", "Grisaille", "Neige", "Mousson", "Saturation", "Cascade", "Rosée-Noire", "Nuée", "Gamme"]},
	"neo": {"h": ["Ren", "Kaito", "Daichi", "Jun", "Sora", "Taro", "Yuki", "Haru", "Kenta", "Shin", "Riku", "Akio"],
		"f": ["Emi", "Hana", "Rei", "Sakura", "Yume", "Nami", "Aoi", "Mika", "Saki", "Rina", "Kumi", "Nori"]},
	"neo_android": {"h": ["Unité-12", "K-40", "Delta", "Byte", "Ohm", "Volt", "Néon-3", "Pixel-9", "Rotor", "Quartz", "Servo", "Diode"],
		"f": ["Ada", "Lumi", "Iris-2", "Ondine-7", "Synthia", "Mira", "Nova-5", "Cyra", "Vega-8", "Alpha", "Echo", "Lyra-4"]},
	"pasta": {"h": ["Frère Orzo", "Rotini", "Ditalini", "Cannelloni", "Frère Vermicelle", "Capellini", "Ziti", "Paccheri", "Cavatappi", "Strozzapreti", "Frère Gemelli", "Mafaldo"],
		"f": ["Orecchiette", "Sœur Conchiglie", "Pastina", "Mafalda", "Campanelle", "Stellina", "Fettuccine", "Sœur Lumaca", "Radiatori", "Ruote", "Pappardelle", "Sœur Anelli"]},
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
	# V185 : les corps de cette ville-ci (son lot, dans ceux de la ville prêteuse)
	var i0: int = 0
	var i1: int = mini(n, LOT)
	if DECALAGE.has(style):
		i0 = int(DECALAGE[style][0])
		i1 = mini(n, i0 + int(DECALAGE[style][1]))
	var cands: Array = []
	for i in range(i0, i1):
		var ro: String = role_de(i)
		if ro == role or (role == "adulte" and ro in ["homme", "femme"]) or (role == "enfant" and ro in ["garcon", "fille"]) or (role == "ancien" and ro in ["vieux", "vieille"]):
			cands.append(i)
	# V84 : un homme aux cheveux longs sans barbe passe pour une femme (« Barnabé ») : on l'évite
	if not femme(role):
		var nets: Array = []
		for c in cands:
			var az: Dictionary = profile("f81_%s_%d" % [st, int(c)]).get("azur", {})
			if femme(role_de(int(c))) or not (str(az.get("coiffure", "")) == "long" and not az.has("barbe")):
				nets.append(c)
		if not nets.is_empty():
			cands = nets
	if cands.is_empty():
		cands = [i0]
	# V185 : dans un même lieu (la même graine de tirage), pas deux fois le même corps tant qu'il en reste
	# (un lieu qui tire ses gens avec plusieurs graines — un étage de tour — s'annonce : debut_lieu, fin_lieu)
	if not _lieu_fixe and int(rng.seed) != _graine_lieu:
		_graine_lieu = int(rng.seed)
		_pris.clear()
	var libres: Array = cands.filter(func(c): return not _pris.has(st + str(c)))
	if not libres.is_empty():
		cands = libres
	var i2: int = int(cands[rng.randi() % cands.size()])
	_pris[st + str(i2)] = true
	var p: Dictionary = profile("f81_%s_%d" % [st, i2])
	if style.begins_with("nuees"):
		p = clair(p, rng)
	return p


## V117 : un habitant de la Cité des Nuées : un corps de Néopolis, mais habillé de clair (blanc, crème,
## bleu ciel, sable, vert sauge, gris doux), sans implant ni néon, les cheveux d'ici (comme les passants
## de hautefond_v112._spawn_crowd_n).
static func clair(p0: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var p: Dictionary = p0.duplicate(true)
	var ne: Dictionary = p.get("neo", {})
	if ne.is_empty():
		return p
	if bool(ne.get("android", false)):
		# un robot des Nuées (comme Plumeau) : polymère blanc, lueurs bleu doux
		ne["c"] = [0.92, 0.93, 0.94]
		ne["c2"] = [0.55, 0.75, 0.95]
		ne["circuit"] = [0.5, 0.75, 1.0]
		ne["peau"] = [0.94, 0.94, 0.95]
		p["neo"] = ne
		var aa: Dictionary = p.get("azur", {})
		aa["yeux"] = [0.5, 0.75, 1.0]
		return p
	var clairs: Array = [[0.92, 0.92, 0.9], [0.86, 0.88, 0.9], [0.78, 0.84, 0.9], [0.86, 0.8, 0.68], [0.62, 0.72, 0.64], [0.7, 0.72, 0.76], [0.94, 0.9, 0.84]]
	var douces: Array = [[0.42, 0.62, 0.8], [0.56, 0.7, 0.58], [0.86, 0.66, 0.5], [0.7, 0.62, 0.82], [0.9, 0.8, 0.46]]
	for k in ["implant", "circuit", "props", "chapeau"]:
		ne.erase(k)
	ne["c"] = clairs[rng.randi() % clairs.size()]
	ne["c2"] = douces[rng.randi() % douces.size()]
	if str(ne.get("tenue", "")) != "enfant":
		ne["tenue"] = ["tailleur", "techwear", "sweat", "jardinier", "tailleur"][rng.randi() % 5]
	p["neo"] = ne
	var az: Dictionary = p.get("azur", {})
	if az.has("cheveux") and not bool(az.get("vieux", false)):
		az["cheveux"] = [[0.2, 0.14, 0.1], [0.5, 0.36, 0.22], [0.82, 0.7, 0.46], [0.1, 0.08, 0.07], [0.62, 0.4, 0.22]][rng.randi() % 5]
	return p


static func femme(role: String) -> bool:
	return role in ["femme", "vieille", "fille"]


static func prenom(style: String, role: String, rng: RandomNumberGenerator) -> String:
	var st: String = style_of(style)
	var l: Dictionary = PRENOMS.get(style, PRENOMS.get(style.trim_suffix("_lieu"), PRENOMS.get(st, PRENOMS["montjoie"])))
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
	var role: String = role_de(i)
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
	if i >= 10:
		# V185 : les nouveaux corps : plus de coiffures, des tailles et des carrures plus variées
		az["coiffure"] = (["long", "chignon", "tresse", "queue", "boucles", "carre", "court", "dreads"] if f else ["court", "boucles", "queue", "long", "chauve" if old or r.randf() < 0.3 else "court", "carre", "court"])[r.randi() % (8 if f else 7)]
		if not kid:
			az["taille"] = snappedf(r.randf_range(0.93, 1.07), 0.01)
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
	if vil == "nains":
		# V85 : les nains de Forgefer (leur fiche « nain », comme ceux de la Grande Halle)
		p.erase("azur")
		var tex: Array = ["nain_suie.png", "nain_braise.png", "nain_mousse.png", "nain_royal.png"]
		var poils: Array = [[0.18, 0.14, 0.12], [0.62, 0.3, 0.12], [0.85, 0.55, 0.25], [0.4, 0.38, 0.36], [0.15, 0.12, 0.12], [0.3, 0.2, 0.12], [0.75, 0.32, 0.12]]
		var coiffes: Array = ["bonnet", "capuche"] if kid else (["bonnet", "capuche", "casque"] if f else ["casque", "capuche", "bonnet", "chauve"])
		var na := {"texture": "res://assets/textures/nains/" + str(tex[r.randi() % tex.size()]),
			"barbe": _c(r, hair_old) if old else _c(r, poils), "style_barbe": ["large", "tresse", "fourche"][r.randi() % 3],
			"coiffe": str(coiffes[r.randi() % coiffes.size()]),
			"tunique": _c(r, [[0.4, 0.22, 0.12], [0.24, 0.3, 0.2], [0.3, 0.28, 0.35], [0.45, 0.15, 0.12], [0.25, 0.25, 0.3], [0.5, 0.36, 0.18]]),
			"metal": [0.6, 0.6, 0.64] if r.randf() < 0.5 else [0.72, 0.52, 0.28], "tablier": not kid and r.randf() < 0.4, "outil": "",
			"taille": r.randf_range(0.55, 0.6) if kid else r.randf_range(0.73, 0.8)}
		if old:
			na["vieux"] = true
		if kid:
			na["enfant"] = true
		p["nain"] = na
		p["teinte"] = _c(r, [[0.98, 0.74, 0.6], [1.0, 0.78, 0.64], [0.9, 0.64, 0.5]])
		return p
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
			# V186 : le désert : djellabas (unies ou rayées), chèches, caftans à motifs, gilets brodés, tons chauds.
			# Avant : une chemise et un pantalon comme à Port-Azur, un turban de temps en temps.
			var chauds: Array = [[0.93, 0.9, 0.82], [0.85, 0.72, 0.5], [0.8, 0.5, 0.22], [0.68, 0.3, 0.18], [0.16, 0.22, 0.48], [0.42, 0.45, 0.24],
				[0.55, 0.72, 0.8], [0.5, 0.33, 0.2], [0.9, 0.72, 0.2], [0.55, 0.16, 0.22]]
			var cheches: Array = [[0.14, 0.2, 0.5], [0.93, 0.9, 0.82], [0.8, 0.5, 0.22], [0.1, 0.1, 0.12], [0.7, 0.14, 0.12], [0.25, 0.5, 0.52]]
			# (pour les femmes, pas d'orangé ni de brun en haut : près du corps, ils se confondent avec la peau)
			var hauts_f: Array = [[0.93, 0.9, 0.82], [0.16, 0.22, 0.48], [0.42, 0.45, 0.24], [0.55, 0.72, 0.8], [0.9, 0.72, 0.2], [0.55, 0.16, 0.22],
				[0.12, 0.5, 0.5], [0.15, 0.4, 0.28], [0.45, 0.25, 0.5]]
			var tz := {"reserve": true}
			az["haut"] = _c(r, hauts_f if f else chauds)
			if f:
				az["robe"] = _c(r, chauds)
				az["robe_longue"] = true
				if not kid:
					if r.randf() < 0.5:
						tz["caftan"] = true
						az["robe"] = _c(r, hauts_f)
					if r.randf() < 0.45:
						tz["motif"] = [[4, 5, 3, 2][r.randi() % 4], _c(r, [[0.9, 0.72, 0.2], [0.93, 0.9, 0.82], [0.7, 0.14, 0.12], [0.14, 0.2, 0.5]])]
					if r.randf() < 0.6:
						tz["ceinture"] = _c(r, [[0.9, 0.72, 0.2], [0.7, 0.14, 0.12], [0.14, 0.2, 0.5], [0.25, 0.5, 0.52]])
					if r.randf() < 0.25:
						tz["chale"] = _c(r, chauds)
					if r.randf() < 0.65:
						tz["foulard_tete"] = _c(r, cheches + [[0.2, 0.55, 0.3], [0.95, 0.75, 0.2], [0.85, 0.3, 0.1]])
			elif not kid:
				if r.randf() < 0.55:
					az["robe"] = _c(r, chauds)
					if r.randf() < 0.4:
						tz["rayures"] = _c(r, [[0.93, 0.9, 0.82], [0.5, 0.33, 0.2], [0.14, 0.2, 0.5], [0.1, 0.1, 0.12]])
				elif r.randf() < 0.6:
					tz["gilet"] = _c(r, [[0.55, 0.16, 0.22], [0.14, 0.2, 0.5], [0.2, 0.36, 0.24], [0.1, 0.1, 0.12]])
					tz["ceinture"] = _c(r, [[0.7, 0.14, 0.12], [0.9, 0.72, 0.2], [0.93, 0.9, 0.82]])
				var ch: float = r.randf()
				if ch < 0.5:
					tz["turban"] = _c(r, cheches)
				elif ch < 0.62:
					tz["fez"] = true
			else:
				if r.randf() < 0.3:
					tz["fez"] = true
			p["tz"] = tz
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
			# V186 : Per-Hâpy : la coupe et la couleur du lin se décident dans le générateur des corps (« reserve ») ;
			# ici les parures : le grand collier pour deux adultes sur trois, hommes compris (avant : une femme sur
			# deux), la coiffe de lin rayée, les perruques noires au carré, les crânes rasés.
			p["sol"] = {"tenue": "enfant" if kid else ["peuple", "peuple", "scribe"][r.randi() % 3], "reserve": true}
			if not kid and r.randf() < 0.66:
				p["sol"]["usekh"] = _c(r, [[0.2, 0.35, 0.6], [0.85, 0.65, 0.2], [0.15, 0.6, 0.62], [0.75, 0.2, 0.15], [0.2, 0.5, 0.42]])
			if not kid and r.randf() < (0.3 if f else 0.4):
				p["sol"]["coiffe"] = [[[0.93, 0.9, 0.8], [0.2, 0.35, 0.6]], [[0.9, 0.72, 0.25], [0.2, 0.35, 0.6]], [[0.93, 0.9, 0.8], [0.75, 0.2, 0.15]], [[0.95, 0.94, 0.9], [0.9, 0.72, 0.25]]][r.randi() % 4]
			if not old:
				az["cheveux"] = _c(r, [[0.05, 0.04, 0.04], [0.08, 0.06, 0.05], [0.1, 0.08, 0.06]])
			if f:
				az["coiffure"] = ["carre", "carre", "long", "tresse", "queue"][r.randi() % 5]
			elif not kid:
				az["coiffure"] = ["chauve", "chauve", "court", "court", "carre"][r.randi() % 5]
				# (pas de longue barbe à Per-Hâpy : rasé, ou une barbe courte de temps en temps)
				if az.has("barbe"):
					if r.randf() < 0.75:
						az.erase("barbe")
					else:
						az["barbe"] = "courte"
		"maya":
			p["sol"] = {"tenue": "enfant" if kid else ["peuple", "chasseur", "peuple"][r.randi() % 3]}
			if not kid and r.randf() < 0.4:
				p["sol"]["plumes"] = _c(r, [[0.1, 0.5, 0.3], [0.75, 0.15, 0.08]])
		"larsen":
			# V92 : les gens des yourtes de l'Île de Larsen (hippies du Camp des Fleurs, grunges de Rainville)
			var hip: bool = st == "yourte_fleurs"
			var tl: Array = (["tie_dye", "poncho", "robe_fleurs", "robe_longue", "tunique", "salopette_fleurs"] if hip else ["flanelle", "cardigan", "robe_grunge", "salopette_grunge", "impermeable", "flanelle"])
			if not f:
				tl = (["tie_dye", "poncho", "tunique", "salopette_fleurs"] if hip else ["flanelle", "cardigan", "salopette_grunge", "flanelle", "impermeable"])
			p["larsen"] = {"style": "hippie" if hip else "grunge", "tenue": "enfant" if kid else str(tl[r.randi() % tl.size()])}
			if not kid and r.randf() < 0.4:
				p["larsen"]["chapeau"] = (["bandeau", "capeline", "paille"] if hip else ["bonnet", "casquette", "bonnet"])[r.randi() % 3]
			if hip and r.randf() < 0.45:
				p["larsen"]["couronne"] = ["marguerites", "coquelicots", "tournesol"][r.randi() % 3]
			if not old:
				az["coiffure"] = ((["long", "boucles", "tresse", "long", "couronne"] if f else ["long", "dreads", "boucles", "queue", "long"]) if hip else (["long", "carre", "queue", "long"] if f else ["long", "court", "long", "queue"]))[r.randi() % (5 if hip else 4)]
				if az["coiffure"] == "couronne":
					az["coiffure"] = "tresse"
		"neo":
			# V95 : les passants de Néopolis : des humains (un sur trois porte un implant) et des androïdes
			var neons: Array = [[0.25, 0.9, 1.0], [1.0, 0.3, 0.75], [0.7, 0.35, 1.0], [0.35, 1.0, 0.5], [1.0, 0.65, 0.15]]
			var sombres: Array = [[0.08, 0.08, 0.1], [0.15, 0.16, 0.2], [0.2, 0.18, 0.24], [0.1, 0.12, 0.16], [0.75, 0.75, 0.78]]
			var ne := {"c": _c(r, sombres + clothes), "c2": _c(r, neons)}
			if st == "neo_android":
				ne["android"] = true
				ne["circuit"] = _c(r, neons)
				ne["peau"] = _c(r, [[0.93, 0.92, 0.9], [0.86, 0.87, 0.9], [0.62, 0.64, 0.68], [0.95, 0.85, 0.8], [0.4, 0.42, 0.46]])
				ne["lueur_yeux"] = 0.7
				ne["tenue"] = ["service", "techwear", "service", "docker", "combinaison", "techwear"][i % 6]
				ne["props"] = ["led_tempe"] if i % 2 == 0 else ["led_tempe", "collier"]
				if old:
					ne["vieux_modele"] = true
					ne["props"] = ["led_tempe", "antenne"]
				az.erase("barbe")
				az.erase("vieux")
				az.erase("taille")
				az["coiffure"] = ["court", "carre", "chauve", "court", "court", "carre"][i % 6]
				az["cheveux"] = _c(r, [[0.85, 0.86, 0.9], [0.08, 0.08, 0.1], [0.3, 0.75, 0.95], [0.9, 0.9, 0.92]])
				az["yeux"] = ne["circuit"]
				if role in ["garcon", "fille"]:
					p["role"] = "homme" if role == "garcon" else "femme"
			else:
				ne["tenue"] = "enfant" if kid else ["techwear", "holo", "sweat", "tailleur", "techwear", "sweat"][r.randi() % 6]
				if old:
					ne["tenue"] = ["kimono", "jardinier"][r.randi() % 2]
				if not kid and not old and r.randf() < 0.35:
					ne["implant"] = true
					ne["circuit"] = ne["c2"]
				if not kid and r.randf() < 0.3:
					ne["chapeau"] = ["capuche", "casquette", "bonnet"][r.randi() % 3]
				if not old and r.randf() < 0.3:
					az["cheveux"] = _c(r, neons)
				if not kid and not old and r.randf() < 0.2:
					ne["props"] = [["visiere"], ["oreillettes"], ["casque_audio"]][r.randi() % 3]
			p["neo"] = ne
		"pasta":
			# V98 : les adeptes de l'Île Al Dente : robes couleur de pâte ou de tomate, tabliers à carreaux,
			# chemises de paysan ; une passoire sur la tête une fois sur deux (et toujours pour les enfants)
			var pates: Array = [[0.95, 0.82, 0.45], [0.94, 0.9, 0.8], [0.78, 0.12, 0.08], [0.2, 0.45, 0.18], [0.85, 0.7, 0.42], [0.6, 0.15, 0.12]]
			var pa := {"c": _c(r, pates), "c2": _c(r, [[0.78, 0.12, 0.08], [0.2, 0.45, 0.18], [0.94, 0.9, 0.8]])}
			pa["tenue"] = "enfant" if kid else ["adepte", "adepte", "paysan", "tablier", "pelerin", "adepte"][r.randi() % 6]
			if old:
				pa["tenue"] = ["adepte", "paysan"][r.randi() % 2]
			if kid or r.randf() < 0.5:
				pa["passoire"] = "grande" if kid else "simple"
			elif r.randf() < 0.5:
				pa["chapeau"] = ["paille", "foulard", "beret"][r.randi() % 3] if f else ["paille", "beret", "bandana"][r.randi() % 3]
			p["pasta"] = pa
		"azteque":
			# V186 : Aztlán : les tissages de couleur se décident dans le générateur des corps (« reserve ») ; ici
			# les parures : les coiffes de plumes (avant : aucune), le jade aux oreilles.
			p["sol"] = {"tenue": "enfant" if kid else "peuple", "reserve": true}
			if r.randf() < 0.5:
				p["sol"]["jade"] = true
			if not kid and r.randf() < 0.45:
				p["sol"]["plumes"] = _c(r, [[0.1, 0.5, 0.3], [0.75, 0.15, 0.08], [0.1, 0.55, 0.6], [0.9, 0.7, 0.15], [0.94, 0.92, 0.86]])
			if f:
				az["coiffure"] = ["tresse", "tresse", "long", "chignon", "queue"][r.randi() % 5]
			elif az.has("barbe") and not old:
				az.erase("barbe")
	return p
